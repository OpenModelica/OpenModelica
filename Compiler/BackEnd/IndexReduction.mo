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
protected import Derive;
protected import Env;
protected import Error;
protected import ErrorExt;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import ExpressionSolve;
protected import Flags;
protected import GraphML;
protected import HashTable2;
protected import HashTable3;
protected import HashTableCG;
protected import Inline;
protected import List;
protected import Matching;
protected import SCode;
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
"function: pantelidesIndexReduction
  author: Frenkel TUD 2012-04
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
      Integer contiEqn,size,newsize,mark;
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
        (eqns_1,unassignedStates,unassignedEqns,discEqns) = minimalStructurallySingularSystem(eqns,isyst,ishared,inAssignments1,inAssignments2,inArg);
        size = BackendDAEUtil.systemSize(isyst);
        ErrorExt.setCheckpoint("Pantelites");
        Debug.fcall(Flags.BLT_DUMP, print, "Reduce Index\n");
        markarr = arrayCreate(size,-1);
        (syst,shared,ass1,ass2,arg,_) =
         pantelidesIndexReduction1(unassignedStates,unassignedEqns,eqns,eqns_1,actualEqn,isyst,ishared,inAssignments1,inAssignments2,1,markarr,inArg,{});
        ErrorExt.rollBack("Pantelites");
        // get from eqns indexes the scalar indexes
        newsize = BackendDAEUtil.systemSize(syst);
        changedeqns = Debug.bcallret2(intGt(newsize,size),List.intRange2,size+1,newsize,{});
        (changedeqns,contiEqn) = getChangedEqnsAndLowest(newsize,ass2,changedeqns,size);
      then
       (changedeqns,contiEqn,syst,shared,ass1,ass2,arg);
    case ({},_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.pantelidesIndexReduction called with empty list of equations!"});
      then
        fail();
    case (_,_,_,_,_,_,_)
      equation
        ErrorExt.delCheckpoint("Pantelites");
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
  (oAcc,oLowest) := matchcontinue(index,ass2,iAcc,iLowest)
    local
      list<Integer> acc;
      Integer l;
    case(_,_,_,_)
      equation
        true = intGt(index,0);
        true = intLt(ass2[index],1);
        (acc,l) = getChangedEqnsAndLowest(index-1,ass2,index::iAcc,index);
      then
        (acc,l);
    case(_,_,_,_)
      equation
        true = intGt(index,0);
        (acc,l) = getChangedEqnsAndLowest(index-1,ass2,iAcc,iLowest);
      then
        (acc,l);
    case(_,_,_,_)
      then
        (iAcc,iLowest);
  end matchcontinue;
end getChangedEqnsAndLowest;

protected function pantelidesIndexReduction1
"function: pantelidesIndexReduction1
  author: Frenkel TUD 2012-04
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
"function: pantelidesIndexReductionMSS
  author: Frenkel TUD 2012-04
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
      list<Integer> changedeqns,eqns1,ueqns1;
      BackendDAE.StateOrder so,so1;
      BackendDAE.ConstraintEquations orgEqnsLst,orgEqnsLst1;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn,ass1,ass2;
      Integer noofeqns,eqnssize;
      BackendDAE.EquationArray eqnsarray;
      BackendDAE.Variables vars;
      list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> eqnstpl;
      list<tuple<list<Integer>,list<Integer>,list<Integer>>> notDiffableMSS;
      String eqnstr;
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
        // diff Alias does not yet work proper
        //(syst,shared,ass1,ass2,so1,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,changedeqns,eqns1) = differentiateAliasEqns(isyst,ishared,eqns1,inAssignments1,inAssignments2,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,{},{});
        //(syst,shared,ass1,ass2,so1,orgEqnsLst1,mapEqnIncRow,mapIncRowEqn,changedeqns) = differentiateEqns(syst,shared,eqns1,ass1,ass2,so1,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,changedeqns);
        // remove allready diffed equations
        //_ = List.fold1r(ueqns1,arrayUpdate,mark,markarr);
        //eqnstpl = differentiateSetEqns(ueqns1,{},vars,eqnsarray,inAssignments1,mapIncRowEqn,mark,markarr,ishared,{});
        eqnstpl = differentiateEqnsLst(eqns1,vars,eqnsarray,ishared,{});
        (syst,shared,ass1,ass2,so1,orgEqnsLst1,mapEqnIncRow,mapIncRowEqn,notDiffableMSS) = differentiateEqns(eqnstpl,eqns1,unassignedStates,unassignedEqns,isyst,ishared,inAssignments1,inAssignments2,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,iNotDiffableMSS);
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
"function: minimalStructurallySingularSystem
  author: Frenkel TUD - 2012-04,
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
"function: minimalStructurallySingularSystemMSS
  author: Frenkel TUD - 2012-11,
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
        //  print("Eqns " +& stringDelimitList(List.map(ilst,intString),", ") +& "\n");
        ((unassignedEqns,eqnsLst,discEqns)) = List.fold2(ilst,unassignedContinuesEqns,vars,(inAssignments2,m),({},{},inDiscEqnsAcc));
        //  print("unassignedEqns " +& stringDelimitList(List.map(unassignedEqns,intString),", ") +& "\n");
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
"function: pantelidesIndexReductionMSS
  author: Frenkel TUD 2012-04
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
"function: unassignedContinuesEqns
  author: Frenkel TUD - 2012-11,
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
"function: statesInEquations
  author: Frenkel TUD 2012-04"
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
"function isMarked
  author: Frenkel TUD 2012-05"
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
"function isUnMarked
  author: Frenkel TUD 2012-05"
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
"function markElement
  author: Frenkel TUD 2012-05"
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

protected function differentiateAliasEqns
"function: differentiateAliasEqns
  author: Frenkel TUD 2011-05
  handle the constraint alias equations for 
  Pantelides index reduction method."
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> inEqns;
  input array<Integer> inAss1;
  input array<Integer> inAss2;
  input BackendDAE.StateOrder inStateOrd;
  input BackendDAE.ConstraintEquations inOrgEqnsLst; 
  input array<list<Integer>> imapEqnIncRow;
  input array<Integer> imapIncRowEqn;   
  input list<Integer> inchangedEqns;
  input list<Integer> iEqnsAcc;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output BackendDAE.StateOrder outStateOrd;
  output BackendDAE.ConstraintEquations outOrgEqnsLst;
  output array<list<Integer>> omapEqnIncRow;
  output array<Integer> omapIncRowEqn;   
  output list<Integer> outchangedEqns;
  output list<Integer> oEqnsAcc;
algorithm
  (osyst,oshared,outAss1,outAss2,outStateOrd,outOrgEqnsLst,omapEqnIncRow,omapIncRowEqn,outchangedEqns,oEqnsAcc):=
  matchcontinue (isyst,ishared,inEqns,inAss1,inAss2,inStateOrd,inOrgEqnsLst,imapEqnIncRow,imapIncRowEqn,inchangedEqns,iEqnsAcc)
    local
      Integer e_1,e,e1,i,i1,i2;
      BackendDAE.Equation eqn;
      BackendDAE.EquationArray eqns_1,eqns;
      list<Integer> es,eqnslst,changedEqns,eqns1;
      BackendDAE.Variables v,v1;
      BackendDAE.StateOrder so,so1;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrix mt;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.Matching matching;
      array<Integer> ass1,ass2,mapIncRowEqn;
      DAE.ComponentRef cr,cr1,cr2,scr;
      Boolean negate,b1,b2,b;
      DAE.Exp exp1,exp2;
      BackendDAE.Var var1,var2;
      BackendDAE.ConstraintEquations orgEqnsLst;
      array<list<Integer>> mapEqnIncRow;
      BackendDAE.StateSets stateSets;
      DAE.FunctionTree funcs;
    case (_,_,{},_,_,_,_,_,_,_,_) then (isyst,ishared,inAss1,inAss2,inStateOrd,inOrgEqnsLst,imapEqnIncRow,imapIncRowEqn,inchangedEqns,iEqnsAcc);
    case (BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching,stateSets),shared,(e :: es),_,_,_,_,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        // is alias State
        ((cr1,cr2,exp1,exp2,negate)::{}) = BackendEquation.aliasEquation(eqn);
        (var1::_,i1::_) = BackendVariable.getVar(cr1,v);
        (var2::_,i2::_) = BackendVariable.getVar(cr2,v);
        b1 = BackendVariable.isStateVar(var1);
        b2 = BackendVariable.isStateVar(var2);
        (cr,i,scr,exp1,i1,v1) = selectAliasState(b1,b2,var1,cr1,exp1,i1,var2,cr2,exp2,i2,v);
        changedEqns = List.map(mt[i], intAbs);
        eqnslst = List.fold1(imapEqnIncRow[e],List.removeOnTrue, intEq, changedEqns);
        //mt = arrayUpdate(mt,i,{e});
        //e1 = -i1;
        //m = arrayUpdate(m,e,{i,e1});  
        exp1 = Debug.bcallret1(negate, Expression.negate, exp1, exp1);
        exp2 = Derive.differentiateExpTime(exp1, (v1,ishared));
        ((exp2,so)) = replaceStateOrderExp((exp2,inStateOrd));
        // get from scalar eqns indexes the indexes in the equation array
        eqns1 = List.map1r(eqnslst,arrayGet,imapIncRowEqn);
        eqns1 = List.unique(eqns1);        
        eqns_1 = replaceAliasState(eqns1,exp1,exp2,cr,eqns);
        so = BackendDAETransform.addAliasStateOrder(scr,cr,so);
        (orgEqnsLst,_) = traverseOrgEqnsExp(inOrgEqnsLst,(cr,exp1,exp2),replaceAliasStateExp,{});
        e1 = inAss1[i];
        b = intGt(e1,0);    
        ass1 = consArrayUpdate(b, inAss1,i,-1);
        ass2 = consArrayUpdate(b, inAss2,e1,-1);
        syst = BackendDAE.EQSYSTEM(v1,eqns_1,SOME(m),SOME(mt),matching,stateSets);
        changedEqns =  List.unique(List.map1r(changedEqns,arrayGet,imapIncRowEqn));
        funcs = BackendDAEUtil.getFunctions(shared);
        (syst,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.updateIncidenceMatrixScalar(syst, BackendDAE.SOLVABLE(), SOME(funcs), changedEqns, imapEqnIncRow, imapIncRowEqn);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrCrefStrCrefStr,("Found Alias State ",cr," := ",scr,"\n Update Incidence Matrix: "));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,(changedEqns,intString," ","\n"));        
        changedEqns = List.consOnTrue(b, e1, mapEqnIncRow[e]);
        changedEqns = List.unionOnTrue(inchangedEqns, changedEqns, intEq);
        (syst,shared,ass1,ass2,so1,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,changedEqns,eqnslst) = differentiateAliasEqns(syst,shared,es,ass1,ass2,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,changedEqns,iEqnsAcc);
      then
        (syst,shared,ass1,ass2,so1,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,changedEqns,eqnslst);
    case (_,_,e::es,_,_,_,_,_,_,_,_)
      equation
        (syst,shared,ass1,ass2,so1,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,changedEqns,eqnslst) = differentiateAliasEqns(isyst,ishared,es,inAss1,inAss2,inStateOrd,inOrgEqnsLst,imapEqnIncRow,imapIncRowEqn,inchangedEqns,e::iEqnsAcc);
      then
        (syst,shared,ass1,ass2,so1,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,changedEqns,eqnslst);
  end matchcontinue;
end differentiateAliasEqns;

protected function differentiateEqns
"function: differentiateEqns
  author: Frenkel TUD 2011-05
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
      list<Integer> es,ilst,eqnslst,eqnslst1,changedEqns,ilst1;
      BackendDAE.Variables v,v1;
      BackendDAE.StateOrder so;
      BackendDAE.ConstraintEquations orgEqnsLst;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrix mt;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
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
        eqnslst1 = BackendDAETransform.collectVarEqns(ilst,{},mt,arrayLength(mt));
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

protected function searchDerivativesEqn "function searchDerivativesEqn
  author: Frenkel TUD 2012-11"
  input tuple<DAE.Exp,tuple<list<Integer>,BackendDAE.Variables>> itpl;
  output tuple<DAE.Exp,tuple<list<Integer>,BackendDAE.Variables>> outTpl;
protected
  DAE.Exp e;
  tuple<list<Integer>,BackendDAE.Variables> tpl;
algorithm
  (e,tpl) := itpl;
  outTpl := Expression.traverseExp(e,searchDerivativesExp,tpl);
end searchDerivativesEqn;

protected function searchDerivativesExp "function searchDerivativesExp
  author: Frenkel TUD 2012-11"
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
"function: differentiateSetEqns
  author: Frenkel TUD 2012-11
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
algorithm
  outEqnTpl := matchcontinue (inEqns,inNextEqns,vars,eqns,ass1,mapIncRowEqn,mark,markarr,ishared,inEqnTpl)
    local
      Integer e_1,e;
      BackendDAE.Equation eqn,eqn_1;
      list<Integer> es,elst;
      list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> eqntpl;
    case ({},{},_,_,_,_,_,_,_,_) then inEqnTpl;
    case ({},_,_,_,_,_,_,_,_,_)
      //equation
      //  Debug.fcall(Flags.BLT_DUMP, print, "marked equations: ");
      //  Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst, (inNextEqns,intString," ","\n"));
      then
        differentiateSetEqns(inNextEqns,{},vars,eqns,ass1,mapIncRowEqn,mark,markarr,ishared,inEqnTpl);
    case (e::es,_,_,_,_,_,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        true = BackendEquation.isDifferentiated(eqn);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrEqnStr,("Skipp allready differentiated equation\n",eqn,"\n"));
      then
        differentiateSetEqns(es,inNextEqns,vars,eqns,ass1,mapIncRowEqn,mark,markarr,ishared,(e,NONE(),eqn)::inEqnTpl);
    case (e::es,_,_,_,_,_,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        // print( "differentiat equation " +& intString(e) +& " " +& BackendDump.equationString(eqn) +& "\n");
        eqn_1 = Derive.differentiateEquationTime(eqn, vars, ishared);
        // print( "differentiated equation " +& intString(e) +& " " +& BackendDump.equationString(eqn_1) +& "\n");
        eqn = BackendEquation.markDifferentiated(eqn);
        // get needed der(variables) from equation
       (_,(_,_,elst)) = BackendEquation.traverseBackendDAEExpsEqn(eqn_1, getDerVars, (vars,ass1,{}));
       elst = List.map1r(elst,arrayGet,mapIncRowEqn);
       elst = List.fold2(elst, addUnMarked, mark, markarr, inNextEqns);
      then
        differentiateSetEqns(es,inNextEqns,vars,eqns,ass1,mapIncRowEqn,mark,markarr,ishared,(e,SOME(eqn_1),eqn)::inEqnTpl);
    // failcase return empty list
    case (_,_,_,_,_,_,_,_,_,_) then {};
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
"function getDerVars
  author Frenkel TUD 2013-01
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
"function: differentiateEqnsLst
  author: Frenkel TUD 2012-11
  differentiates the constraint equations for 
  Pantelides index reduction method."
  input list<Integer> inEqns;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.Shared ishared;
  input list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> inEqnTpl;
  output list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> outEqnTpl;
algorithm
  outEqnTpl := matchcontinue (inEqns,vars,eqns,ishared,inEqnTpl)
    local
      Integer e_1,e;
      BackendDAE.Equation eqn,eqn_1;
      list<Integer> es;
      list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> eqntpl;
    case ({},_,_,_,_) then inEqnTpl;
    case (e::es,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        true = BackendEquation.isDifferentiated(eqn);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrEqnStr,("Skipp allready differentiated equation\n",eqn,"\n"));
      then
        differentiateEqnsLst(es,vars,eqns,ishared,(e,NONE(),eqn)::inEqnTpl);
    case (e::es,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        // print( "differentiat equation " +& intString(e) +& " " +& BackendDump.equationString(eqn) +& "\n");
        eqn_1 = Derive.differentiateEquationTime(eqn, vars, ishared);
        // print( "differentiated equation " +& intString(e) +& " " +& BackendDump.equationString(eqn_1) +& "\n");
        eqn = BackendEquation.markDifferentiated(eqn);
      then
        differentiateEqnsLst(es,vars,eqns,ishared,(e,SOME(eqn_1),eqn)::inEqnTpl);
    case (_,_,_,_,_) then {};
  end matchcontinue;
end differentiateEqnsLst;

protected function replaceDifferentiatedEqns
"function: replaceDifferentiatedEqns
  author: Frenkel TUD 2012-11
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
        //(eqn_1,so) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn_1, BackendDAETransform.replaceStateOrderExp,inStateOrd); 
        (eqn_1,(vars1,eqns1,so,changedVars,_,_,_)) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn_1,changeDerVariablestoStates,(vars,eqns,inStateOrd,inChangedVars,e,imapIncRowEqn,mt));
        Debug.fcall(Flags.BLT_DUMP, debugdifferentiateEqns,(eqn,eqn_1));
        e_1 = e - 1;
        eqns1 = BackendEquation.equationSetnth(eqns1,e_1,eqn_1);
        orgEqnsLst = BackendDAETransform.addOrgEqn(inOrgEqnsLst,e,eqn);
        (outVars,outEqns,outStateOrd,outChangedVars,outOrgEqnsLst) = 
           replaceDifferentiatedEqns(rest,vars1,eqns1,so,mt,imapIncRowEqn,changedVars,orgEqnsLst);
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

protected function statesWithUnusedDerivative
"function statesWithUnusedDerivative
  author Frenkel TUD 2012-11
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
"function: handleundifferntiableMSSLst
  author: Frenkel TUD 2012-12
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
      list<BackendDAE.Equation> notDiffedEquations,inDiffEqns,inOrgEqns;
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
"function: handleundifferntiableMSS
  author: Frenkel TUD 2012-11
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
      Integer eqnss,eqnss1,i;
      BackendDAE.EquationArray eqns_1,eqns;
      list<Integer> es,ilst,eqnslst,eqnslst1,ilst1;
      BackendDAE.Variables v,v1;
      BackendDAE.StateOrder so;
      BackendDAE.ConstraintEquations orgEqnsLst;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrix mt;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
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
    case (true,_,_,_,_,BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching,stateSets),_,_,_,_,_,_,_)
      equation
        // change varKind
        varlst = List.map1r(statesWithUnusedDer,BackendVariable.getVarAt,v);
        Debug.fcall(Flags.BLT_DUMP, print, "Change varKind to algebraic for\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVarList, varlst);
        varlst = BackendVariable.setVarsKind(varlst,BackendDAE.VARIABLE());
        v1 = BackendVariable.addVars(varlst,v);
        // update IncidenceMatrix
        eqnslst1 = BackendDAETransform.collectVarEqns(statesWithUnusedDer,{},mt,arrayLength(mt));
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
        eqnslst1 = BackendDAETransform.collectVarEqns({i},{},mt,arrayLength(mt));
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
  eqn := BackendDAEUtil.equationNth(eqns, e1);
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

protected function selectAliasState
"function selectAliasState
  Selects the Dummy state in case of a alias state (a=b).
  Note it is possible that one var is no state but because of
  differentation this variable become a state."
  input Boolean b1;
  input Boolean b2;
  input BackendDAE.Var var1;
  input DAE.ComponentRef cr1;
  input DAE.Exp exp1;
  input Integer i1;
  input BackendDAE.Var var2;
  input DAE.ComponentRef cr2;
  input DAE.Exp exp2;
  input Integer i2;
  input BackendDAE.Variables iv;
  output DAE.ComponentRef acr "alias state";
  output Integer ai "alias state";
  output DAE.ComponentRef scr "state";
  output DAE.Exp sexp "state";
  output Integer si "state";
  output BackendDAE.Variables ov;  
algorithm
  (acr,ai,scr,sexp,si,ov) := match(b1,b2,var1,cr1,exp1,i1,var2,cr2,exp2,i2,iv)
  local
    Integer p1,p2,ia,is;
    BackendDAE.Variables v;
    DAE.ComponentRef crs,cra;
    DAE.Exp exps;
    BackendDAE.Var vara;
    case (true,false,_,_,_,_,_,_,_,_,_)
      then
        (cr2,i2,cr1,exp1,i1,iv);
    case (false,true,_,_,_,_,_,_,_,_,_)
      then
        (cr1,i1,cr2,exp2,i2,iv);
    else 
      equation
        p1 = BackendVariable.varStateSelectPrioAlias(var1);
        p2 = BackendVariable.varStateSelectPrioAlias(var2);
        ((cra,ia,exps,vara,crs,is)) = Util.if_(intGt(p1,p2),(cr2,i2,exp1,var2,cr1,i1),(cr1,i1,exp2,var1,cr2,i2));      
        vara = BackendVariable.setVarKind(vara, BackendDAE.DUMMY_STATE());
        v = BackendVariable.addVar(vara,iv);
      then
        (cra,ia,crs,exps,is,v);
  end match;
end selectAliasState;

protected function replaceAliasState
"function: replaceAliasState
  author: Frenkel TUD 2012-06"
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
        eqn = BackendDAEUtil.equationNth(inEqns,pos_1);
        (eqn1,_) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn, replaceAliasStateExp,(inACr,inCrExp,indCrExp));
        eqns =  BackendEquation.equationSetnth(inEqns,pos_1,eqn1);
        //  print("Replace in Eqn:\n" +& BackendDump.equationString(eqn) +& "\nto\n" +& BackendDump.equationString(eqn1) +& "\n");
      then 
        replaceAliasState(rest,inCrExp,indCrExp,inACr,eqns);
    case ({},_,_,_,_) then inEqns;
  end match;
end replaceAliasState;

protected function replaceAliasStateIncidence
  input Integer i;
  input Integer si;
  input Integer ai;
  input Integer nai;
  output Integer oi;
algorithm
  oi := matchcontinue(i,si,ai,nai)
    case(_,_,_,_)
      equation
        true = intEq(i,ai);
      then
        si;
    case (_,_,_,_)
      equation
        true = intEq(i,nai);
      then
        -si;
      else i;
 end matchcontinue;
end replaceAliasStateIncidence;

protected function replaceAliasStateExp
"function: replaceAliasStateExp
  author: Frenkel TUD 2012-06"
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
"function: replaceAliasStateExp1
  author: Frenkel TUD 2012-06 "
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
"function: getStructurallySingularSystemHandlerArg
  author: Frenkel TUD 2012-04
  return initial the StructurallySingularSystemHandlerArg."
  input BackendDAE.EqSystem isyst;
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
  ((so,_)) := BackendEquation.traverseBackendDAEEqns(eqns,BackendDAETransform.traverseStateOrderFinder,(so,BackendVariable.daeVars(isyst)));
  Debug.fcall(Flags.BLT_DUMP, BackendDAETransform.dumpStateOrder, so); 
  outArg := (so,{},mapEqnIncRow,mapIncRowEqn,BackendDAEUtil.equationArraySize(eqns));
end getStructurallySingularSystemHandlerArg;

/*****************************************
 No State deselection Method. 
 use the index 1/0 system as it is
 *****************************************/

public function noStateDeselection
"function: noStateDeselection
  author: Frenkel TUD 2012-04
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
  HashTable2.HashTable ht;
algorithm
  BackendDAE.DAE(systs,shared) := inDAE;
  // do state selection
  ht := HashTable2.emptyHashTable();
  (systs,shared,ht) := mapdynamicStateSelection(systs,shared,inArgs,1,{},ht);
  shared := replaceDummyDerivativesShared(shared,ht);
  outDAE := BackendDAE.DAE(systs,shared);
end dynamicStateSelection;

protected function mapdynamicStateSelection
"function mapdynamicStateSelection 
  Run the state selection Algorithm."
  input list<BackendDAE.EqSystem> isysts;
  input BackendDAE.Shared ishared;
  input list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> iargs;
  input Integer setIndex;
  input list<BackendDAE.EqSystem> acc;
  input HashTable2.HashTable iHt;
  output list<BackendDAE.EqSystem> osysts;
  output BackendDAE.Shared oshared;
  output HashTable2.HashTable oHt;
algorithm
  (osysts,oshared,oHt) := match (isysts,ishared,iargs,setIndex,acc,iHt)
    local 
      BackendDAE.EqSystem syst;
      list<BackendDAE.EqSystem> systs;
      BackendDAE.Shared shared;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> args;
      HashTable2.HashTable ht;
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
"function: dynamicStateSelectionWork
  author: Frenkel TUD 2012-04
  dynamic state deselect of the system."
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  input HashTable2.HashTable iHt;
  input Integer iSetIndex;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output HashTable2.HashTable oHt;
  output Integer oSetIndex;
algorithm
  (osyst,oshared,oHt,oSetIndex):=
  matchcontinue (isyst,ishared,inArg,iHt,iSetIndex)
    local
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      Integer ne,nv,ne1,nv1,freestatevars,orgeqnscount,ndummystates,noofeqns,setIndex;
      BackendDAE.StateOrder so;
      BackendDAE.ConstraintEquations orgEqnsLst,orgEqnsLst1;
      BackendDAE.Variables v,hov;
      array<Integer> vec1,vec2,ass1,ass2;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      list<DAE.ComponentRef> dummyStates;
      list<list<Integer>> comps;
      DAE.FunctionTree funcs;
      list<BackendDAE.Var> varlst;  
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;  
      list<BackendDAE.Equation> enqnslst;
      list<Integer> changedeqns;
      HashTable2.HashTable ht;
    // no Index Reduction performed (OrgEqnsLst is Empty)
    case (_,_,(so,{},mapEqnIncRow,mapIncRowEqn,_),_,_)
     then 
       (isyst,ishared,iHt,iSetIndex);
    // Index Reduction performed
    case (syst as BackendDAE.EQSYSTEM(orderedVars=v,matching=BackendDAE.MATCHING(ass1=ass1,ass2=ass2)),BackendDAE.SHARED(functionTree=funcs),(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,noofeqns),_,_)
      equation
        // do late Inline also in orgeqnslst
        orgEqnsLst1 = inlineOrgEqns(orgEqnsLst,(SOME(funcs),{DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()}),{});
        // replace all der(x) with dx, is not so good for initial system, so keep the original equations and add them to the system and to state selection on replaced one
        (orgEqnsLst,_) = traverseOrgEqnsExp(orgEqnsLst1,so,replaceDerStatesStates,{});
        Debug.fcall(Flags.BLT_DUMP, print, "Dynamic State Selection\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDAETransform.dumpStateOrder, so);
        Debug.fcall2(Flags.BLT_DUMP, BackendDump.dumpEqSystem, isyst, "Index Reduced System");
        ne = BackendDAEUtil.systemSize(isyst);
        nv = BackendVariable.varsSize(v);
        // geth the number of states without stateSelect.always (free states), if the number of differentiated equtaions is equal to the number of free states no selection is necessary 
        varlst = List.filter(BackendVariable.varList(v), stateVar);
        varlst = List.filter(varlst, notVarStateSelectAlways);
        freestatevars = listLength(varlst);
        orgeqnscount = countOrgEqns(orgEqnsLst,0);
        // select dummy states
        (dummyStates,syst,shared,setIndex) = processComps(freestatevars,varlst,orgeqnscount,isyst,ishared,(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,noofeqns),{},iSetIndex);
        // add the original equations to the systems
        enqnslst = List.flatten(List.map(orgEqnsLst1,Util.tuple22));
        syst = BackendEquation.equationsAddDAE(enqnslst, syst);
        // add the selected dummy states
        ne1 = BackendDAEUtil.systemSize(syst);
        ndummystates = listLength(dummyStates);
        nv1 = BackendVariable.varsSize(BackendVariable.daeVars(syst));
        nv1 = nv1+ndummystates;
        vec1 = Util.arrayExpand(ne1-ne, ass1, -1);
        vec2 = Util.arrayExpand(nv1-nv, ass2, -1);
        syst = BackendVariable.expandVarsDAE(ndummystates,syst);
        (syst,shared,ht) = addDummyStates(dummyStates,syst,shared,iHt);
        // generate matching for final system with dummy states
        (syst,m,_,_,_) = BackendDAEUtil.getIncidenceMatrixScalar(syst,BackendDAE.NORMAL(), SOME(funcs));
        Matching.matchingExternalsetIncidenceMatrix(nv1,ne1,m);
        BackendDAEEXT.matching(nv1,ne1,5,-1,0.0,1);
        BackendDAEEXT.getAssignment(vec2,vec1);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec1,vec2,{}));
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

protected function countOrgEqns
"function: countOrgEqns
  author: Frenkel TUD 2012-06
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
"function: inlineOrgEqns
  author: Frenkel TUD 2012-08
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

protected function traverseOrgEqns
"function: traverseOrgEqns
  author: Frenkel TUD 2012-06
  add an equation to the ConstrainEquations."
  input BackendDAE.ConstraintEquations inOrgEqns;
  input Type_a inA;
  input FuncEqnType func;
  input BackendDAE.ConstraintEquations inAcc;
  output BackendDAE.ConstraintEquations outOrgEqns;
  partial function FuncEqnType
    input BackendDAE.Equation inEqn;
    input Type_a type_a;
    output BackendDAE.Equation outEqn;
  end FuncEqnType;  
  replaceable type Type_a subtypeof Any;  
algorithm
  outOrgEqns :=
  match (inOrgEqns,inA,func,inAcc)
    local
      Integer e;
      list<BackendDAE.Equation> orgeqns;
      BackendDAE.ConstraintEquations rest;
    case ({},_,_,_) then listReverse(inAcc);
    case ((e,orgeqns)::rest,_,_,_)
      equation
        orgeqns = List.map1(orgeqns, func, inA);
      then
        traverseOrgEqns(rest,inA,func,(e,orgeqns)::inAcc);
  end match;
end traverseOrgEqns;

protected function traverseOrgEqnsExp
"function: traverseOrgEqnsExp
  author: Frenkel TUD 2012-06
  traverse all org eqns and call func for each expression in the equations."
  input BackendDAE.ConstraintEquations inOrgEqns;
  input Type_a inA;
  input FuncExpType func;
  input BackendDAE.ConstraintEquations inAcc;
  output BackendDAE.ConstraintEquations outOrgEqns;
  output Type_a outA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;  
  replaceable type Type_a subtypeof Any;  
algorithm
  (outOrgEqns,outA) :=
  match (inOrgEqns,inA,func,inAcc)
    local
      Integer e;
      list<BackendDAE.Equation> orgeqns;
      BackendDAE.ConstraintEquations rest,orgeqnslst;    
      Type_a a;
    case ({},_,_,_) then (listReverse(inAcc),inA);
    case ((e,orgeqns)::rest,_,_,_)
      equation
        (orgeqns,a) = BackendDAETransform.traverseBackendDAEExpsEqnList(orgeqns,func,inA);
        (orgeqnslst,a) = traverseOrgEqnsExp(rest,a,func,(e,orgeqns)::inAcc);
      then
        (orgeqnslst,a);
  end match;
end traverseOrgEqnsExp;

protected function replaceDerStatesStates
"function: replaceDerStatesStates
  author: Frenkel TUD 2012-06
  traverse an exp top down and ."
  input tuple<DAE.Exp, BackendDAE.StateOrder> inTpl;
  output tuple<DAE.Exp, BackendDAE.StateOrder> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local  
      BackendDAE.StateOrder so;
      DAE.Exp exp;
    case ((exp,so))
      equation
         ((exp,_)) = Expression.traverseExp(exp,replaceDerStatesStatesExp,so);
       then
        ((exp,so));
    case _ then inTpl;
  end matchcontinue;
end replaceDerStatesStates;

protected function replaceDerStatesStatesExp
"function: replaceDerStatesStatesExp
  author: Frenkel TUD 2012-06
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
        dcr = BackendDAETransform.getStateOrder(cr,so);
        e1 = Expression.crefExp(dcr);
      then
        ((e1,so));             
    else then inTuple;
  end matchcontinue;
end replaceDerStatesStatesExp;

protected function replaceStateOrderExp
"function: replaceStateExp
  author: Frenkel TUD 2011-05"
  input tuple<DAE.Exp,BackendDAE.StateOrder> inTpl;
  output tuple<DAE.Exp,BackendDAE.StateOrder> outTpl;
protected
  DAE.Exp e;
  BackendDAE.StateOrder so;
algorithm
  (e,so) := inTpl;
  outTpl := Expression.traverseExpTopDown(e,replaceStateOrderExpFinder,so);
end replaceStateOrderExp;

protected function replaceStateOrderExpFinder
"function: replaceStateOrderExpFinder
  author: Frenkel TUD 2011-05 "
  input tuple<DAE.Exp,BackendDAE.StateOrder> inExp;
  output tuple<DAE.Exp, Boolean, BackendDAE.StateOrder> outExp;
algorithm
  (outExp) := matchcontinue (inExp)
    local
      DAE.Exp e;
      BackendDAE.StateOrder so;
      DAE.ComponentRef dcr,cr;
      String ident;
      DAE.CallAttributes attr;
    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})},attr=attr),so))
      equation
        dcr = getStateOrder(cr,so);
        e = Expression.crefExp(dcr);
      then
        ((DAE.CALL(Absyn.IDENT("der"),{e},attr),false,so));
     case ((e,so)) then ((e,true,so));
  end matchcontinue;
end replaceStateOrderExpFinder;

protected function getStateOrder
"function: getStateOrder
  author: Frenkel TUD 2011-05
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

protected function highestOrderDerivatives
"function: highestOrderDerivatives
  author: Frenkel TUD 2012-05
  collect all highest order derivatives from ODE"
  input BackendDAE.Variables v;
  input BackendDAE.StateOrder so;
  output list<BackendDAE.Var> outVars;
algorithm
  ((_,_,outVars)) := BackendVariable.traverseBackendDAEVars(v,traversinghighestOrderDerivativesFinder,(so,v,{}));        
end highestOrderDerivatives;

protected function traversinghighestOrderDerivativesFinder
" function traversinghighestOrderDerivativesFinder
  author: Frenkel TUD 2012-05
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
    case ((v,(so,vars,varlst)))
      equation
        true = BackendVariable.isStateVar(v);
        cr = BackendVariable.varCref(v);
        failure(_ =  BackendDAETransform.getStateOrder(cr,so));
      then ((v,(so,vars,v::varlst)));
     case ((v,(so,vars,varlst)))
      equation
        true = BackendVariable.isStateVar(v);
        cr = BackendVariable.varCref(v);
        dcr =   BackendDAETransform.getStateOrder(cr,so);
        false = BackendVariable.isState(dcr,vars);
      then ((v,(so,vars,v::varlst)));   
    else then inTpl;
  end matchcontinue;
end traversinghighestOrderDerivativesFinder;

protected function lowerOrderDerivatives
"function: lowerOrderDerivatives
  author: Frenkel TUD 2012-05
  collect all derivatives one order less than derivatives from v"
  input BackendDAE.Variables derv;
  input BackendDAE.Variables v;
  input BackendDAE.StateOrder so;
  output BackendDAE.Variables outVars;
algorithm
  ((_,_,outVars)) := BackendVariable.traverseBackendDAEVars(derv,traversinglowerOrderDerivativesFinder,(so,v,BackendVariable.emptyVars()));        
end lowerOrderDerivatives;

protected function traversinglowerOrderDerivativesFinder
" function traversinglowerOrderDerivativesFinder
  author: Frenkel TUD 2012-05
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
        crlst = BackendDAETransform.getDerStateOrder(dcr,so);
        vlst = List.map1(crlst,getVar,vars);
        vars2 = List.fold(vlst,BackendVariable.addVar,vars1);
      then ((v,(so,vars,vars2)));   
    else then inTpl;
  end matchcontinue;
end traversinglowerOrderDerivativesFinder;

protected function getVar
"function: getVar
  author: Frnekel TUD 2012-05
  helper for traversinglowerOrderDerivativesFinder"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  output BackendDAE.Var v;
algorithm
  (v::{},_) := BackendVariable.getVar(cr,vars);
end getVar;

protected function higerOrderDerivatives
"function: higerOrderDerivatives
  author: Frenkel TUD 2012-06
  collect all derivatives from v"
  input BackendDAE.Variables v;
  input BackendDAE.Variables vAll;
  input BackendDAE.StateOrder so;
  input list<DAE.ComponentRef> inDummyStates;
  output BackendDAE.Variables outVars;
  output list<DAE.ComponentRef> outDummyStates;
algorithm
  ((_,_,outVars,outDummyStates)) := BackendVariable.traverseBackendDAEVars(v,traversinghigerOrderDerivativesFinder,(so,vAll,BackendVariable.emptyVars(),inDummyStates));        
end higerOrderDerivatives;

protected function traversinghigerOrderDerivativesFinder
" function traversinghigerOrderDerivativesFinder
  author: Frenkel TUD 2012-06
  helpber for higerOrderDerivatives"
 input tuple<BackendDAE.Var, tuple<BackendDAE.StateOrder,BackendDAE.Variables,BackendDAE.Variables,list<DAE.ComponentRef>>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendDAE.StateOrder,BackendDAE.Variables,BackendDAE.Variables,list<DAE.ComponentRef>>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> vlst;
      DAE.ComponentRef cr,dcr;
      BackendDAE.StateOrder so;
      BackendDAE.Variables vars,vars1,vars2;
      list<DAE.ComponentRef> dummyStates;
     case ((v,(so,vars,vars1,dummyStates)))
      equation
        cr = BackendVariable.varCref(v);
        dcr = BackendDAETransform.getStateOrder(cr,so);
        (vlst,_) = BackendVariable.getVar(dcr,vars);
        vars2 = List.fold(vlst,BackendVariable.addVar,vars1);
      then ((v,(so,vars,vars2,dcr::dummyStates)));   
    else then inTpl;
  end matchcontinue;
end traversinghigerOrderDerivativesFinder;

protected type StateSets = list<tuple<Integer,Integer,Integer,list<BackendDAE.Var>,list<BackendDAE.Equation>,list<BackendDAE.Var>,list<BackendDAE.Equation>>> "nStates,nStateCandidates,nUnassignedEquations,StateCandidates,ConstraintEqns,OtherVars,OtherEqns";

protected function processComps
"function: processComps
  author: Frenkel TUD 2012-05
  process all strong connected components of the system and collect the 
  derived equations for dummy state selection"
  input Integer cfreeStates;
  input list<BackendDAE.Var> freeStates;
  input Integer cOrgEqns;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  input list<DAE.ComponentRef> inDummyStates;
  input Integer iSetIndex;
  output list<DAE.ComponentRef> outDummyStates;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Integer oSetIndex;
algorithm
  (outDummyStates,osyst,oshared,oSetIndex) := 
  matchcontinue(cfreeStates,freeStates,cOrgEqns,isyst,ishared,inArg,inDummyStates,iSetIndex)
    local 
      BackendDAE.StateOrder so;
      list<DAE.ComponentRef> dummystates; 
      BackendDAE.EqSystem syst;
      list<BackendDAE.Var> varlst;
      Integer setIndex;
      StateSets stateSets;
    // number of free states and differentiated equations equal -> no state selection necessary
    case (_,_,_,_,_,_,_,_)
      equation
        true = intEq(cfreeStates,cOrgEqns);
        dummystates = List.map(freeStates,BackendVariable.varCref);
      then (dummystates,isyst,ishared,iSetIndex);
    // select states
    case (_,_,_,_,_,(so,_,_,_,_),_,_)
      equation
        ErrorExt.setCheckpoint("DynamicStateSelection");
        // get highest order derivatives
        varlst = highestOrderDerivatives(BackendVariable.daeVars(isyst),so);
        Debug.fcall(Flags.BLT_DUMP, print, "highest Order Derivatives:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVarList, varlst);
        (dummystates,stateSets) = processCompsWork(cfreeStates,freeStates,cOrgEqns,varlst,isyst,ishared,inArg,inDummyStates,{});
        // add the found state sets for dynamic state selection to the system
        (setIndex,syst) = addStateSets(stateSets,iSetIndex,isyst);
        ErrorExt.rollBack("DynamicStateSelection");
      then
        (dummystates,syst,ishared,setIndex);
    else
      equation
        ErrorExt.delCheckpoint("DynamicStateSelection");
      then
        fail();        
  end matchcontinue;
end processComps;

protected function processCompsWork
"function: processCompsWork
  author: Frenkel TUD 2012-05
  process all strong connected components of the system and collect the 
  derived equations for dummy state selection"
  input Integer cfreeStates;
  input list<BackendDAE.Var> freeStates;
  input Integer cOrgEqns;
  input list<BackendDAE.Var> iHigestOrderVars;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  input list<DAE.ComponentRef> inDummyStates;
  input StateSets iStateSets;
  output list<DAE.ComponentRef> outDummyStates;
  output StateSets oStateSets;
algorithm
  (outDummyStates,oStateSets) := 
  matchcontinue(cfreeStates,freeStates,cOrgEqns,iHigestOrderVars,isyst,ishared,inArg,inDummyStates,iStateSets)
    local 
        BackendDAE.Variables hov;
        list<DAE.ComponentRef> dummystates; 
        BackendDAE.EqSystem syst;
        BackendDAE.Shared shared;
        Integer setIndex;
        StateSets stateSets;
        DAE.FunctionTree funcs;
        BackendDAE.IncidenceMatrix m;
        BackendDAE.IncidenceMatrixT mt;
        array<list<Integer>> mapEqnIncRow;
        array<Integer> mapIncRowEqn;
        array<Integer> vec1,vec2;
        list<list<Integer>> comps;
    // try to select states without strong component information, this method take care on stateSelect attribute
/*    case (_,_,_,_,_,_,_,_,_)
      equation
        (dummystates,stateSets) = selectStates(isyst,ishared,vec2,inArg,iHigestOrderVars,inDummyStates,iStateSets);
      then
        (dummystates,stateSets);       
*/    // try to select states without strong component information, this method take care on stateSelect attribute
    case (_,_,_,_,_,_,_,_,_)
      equation
        (dummystates,stateSets) = processComps1New(isyst,ishared,inArg,iHigestOrderVars,inDummyStates,iStateSets);
      then
        (dummystates,stateSets);       
    // select states based on strong connected components, this method does not take care on stateSelect attribute
    case (_,_,_,_,BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=vec1,ass2=vec2)),_,_,_,_)
      equation
        hov = BackendVariable.listVar1(iHigestOrderVars);
        // generate StrongComponents for second selection method
        funcs = BackendDAEUtil.getFunctions(ishared);
        (syst,m,mt,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(isyst,BackendDAE.NORMAL(), SOME(funcs));
        comps = BackendDAETransform.tarjanAlgorithm(m,mt,vec1,vec2);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpComponentsOLD,comps);
        (dummystates,stateSets) = processComps1(comps,syst,ishared,vec2,inArg,hov,inDummyStates,iStateSets);
      then
        (dummystates,stateSets);
  end matchcontinue;
end processCompsWork;

protected function addStateSets
"function: addStateSets
  author: Frenkel TUD 2013-01
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
"function: generateStateSets
  author: Frenkel TUD 2013-01
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
        Integer rang,nStates,nStateCandidates,nUnassignedEquations,setIndex;
        BackendDAE.Variables vars;
        
        DAE.Exp expcrA,mulAstates,mulAdstates,expset,expderset;
        list<DAE.Exp> expcrstates,expcrdstates,expcrset,expcrdset;
        DAE.Operator op;
        BackendDAE.Equation eqn,deqn;
        BackendDAE.EquationArray eqns;
        list<BackendDAE.Equation> cEqnsLst,oEqnLst;
        BackendDAE.StateSets stateSets;
    case ({},_,_,_,_) then (iSetIndex,iVars,iEqns,iStateSets);
    case ((nStates,nStateCandidates,nUnassignedEquations,stateCandidates,cEqnsLst,otherVars,oEqnLst)::rest,_,_,_,_)
      equation
        rang = nStateCandidates - nUnassignedEquations;
         // generate Set Vars
        (set,crset,setVars,crA,aVars,tp,crJ,varJ) = getSetVars(iSetIndex,rang,nStateCandidates,nUnassignedEquations);
        // add set states 
        vars = BackendVariable.addVars(setVars,iVars);
        // add Equations
        // set.x = set.A*set.statecandidates
        // der(set.x) = set.A*der(set.candidates)
        crstates = List.map(stateCandidates,BackendVariable.varCref);
        expcrstates = List.map(crstates,Expression.crefExp);
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
        // set.x = set.A*set.statecandidates
        eqn  = Util.if_(intGt(rang,1),BackendDAE.ARRAY_EQUATION({rang},expset,mulAstates,DAE.emptyElementSource,false),
                                      BackendDAE.EQUATION(expset,mulAstates,DAE.emptyElementSource,false));
        // der(set.x) = set.A*der(set.candidates)
        deqn  = Util.if_(intGt(rang,1),BackendDAE.ARRAY_EQUATION({rang},expderset,mulAdstates,DAE.emptyElementSource,false),
                                      BackendDAE.EQUATION(expderset,mulAdstates,DAE.emptyElementSource,false));
        // add equations
        eqns = BackendEquation.equationAdd(eqn, iEqns);        
        eqns = BackendEquation.equationAdd(deqn, eqns);        
        // generate state set;
        (setIndex,vars,eqns,stateSets) = generateStateSets(rest,iSetIndex+1,vars,eqns,BackendDAE.STATESET(rang,crset,crA,aVars,stateCandidates,otherVars,cEqnsLst,oEqnLst,crJ,varJ)::iStateSets);
      then
        (setIndex,vars,eqns,stateSets);        
  end match;
end generateStateSets;

protected function processComps1New
"function: processComps1New
  author: Frenkel TUD 2012-11
  process all strong connected components of the system and collect the 
  derived equations for dummy state selection"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  input list<BackendDAE.Var> hov;
  input list<DAE.ComponentRef> inDummyStates;
  input StateSets iStateSets;
  output list<DAE.ComponentRef> outDummyStates;
  output StateSets oStateSets;
algorithm
  (outDummyStates,oStateSets) := 
  match(isyst,ishared,inArg,hov,inDummyStates,iStateSets)
    local 
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.StateOrder so;
      BackendDAE.ConstraintEquations orgEqnsLst;
      list<BackendDAE.Equation> eqnslst;
      list<Integer> ilst;
      list<BackendDAE.Var> varlst,dummvars,lov;
      BackendDAE.Variables lov1;
      list<DAE.ComponentRef> dummyStates;  
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;    
      Integer noofeqns,freeStates,neqns; 
      StateSets stateSets;
      DAE.FunctionTree funcs;
    case (_,_,(_,{},_,_,_),_,_,_) then (inDummyStates,iStateSets);
    case (_,_,(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,noofeqns),_,_,_)
      equation
        // get orgequations of that level
        (eqnslst,ilst,orgEqnsLst) = getFirstOrgEqns(orgEqnsLst,{},{},{});
        // replace final parameter
        (eqnslst,_) = BackendEquation.traverseBackendDAEExpsEqnList(eqnslst, replaceFinalVarsEqn,(BackendVariable.daeKnVars(ishared),false,BackendVarTransform.emptyReplacements()));
        // force inline
        funcs = BackendDAEUtil.getFunctions(ishared);
        (eqnslst,_) = BackendEquation.traverseBackendDAEExpsEqnList(eqnslst, forceInlinEqn,funcs);
        // try to make scalar
        (eqnslst,_) = BackendDAEOptimize.getScalarArrayEqns(eqnslst,{},false);
        // remove stateSelect=StateSelect.always vars
        varlst = List.filter(hov, notVarStateSelectAlways);
        neqns = BackendEquation.equationLstSize(eqnslst);
        freeStates = listLength(varlst);
        (dummvars,dummyStates,stateSets) = processComps2New(freeStates,varlst,neqns,eqnslst,ilst,isyst,ishared,so,hov,inDummyStates,iStateSets);
        // get derivatives one order less
        //  print("DummyVars:\n");
        //  BackendDump.printVarList(dummvars);
        //lov1 = lowerOrderDerivatives(BackendVariable.listVar1(dummvars),BackendVariable.daeVars(isyst),so);
        lov1 = lowerOrderDerivatives(BackendVariable.listVar1(hov),BackendVariable.daeVars(isyst),so);
        lov = BackendVariable.varList(lov1);
        // next level
        (dummyStates,stateSets) = processComps1New(isyst,ishared,(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,noofeqns),lov,dummyStates,stateSets);
      then
        (dummyStates,stateSets);
  end match;
end processComps1New;

protected function processComps2New
"function: processComps2
  author: Frenkel TUD 2012-11
  process all strong connected components of the system and collect the 
  derived equations for dummy state selection"
  input Integer freeStates;
  input list<BackendDAE.Var> varlst;
  input Integer neqns;
  input list<BackendDAE.Equation> eqnslst;
  input list<Integer> ilst;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StateOrder so;
  input list<BackendDAE.Var> hov; 
  input list<DAE.ComponentRef> inDummyStates;
  input StateSets iStateSets;
  output list<BackendDAE.Var> outDummyVars;
  output list<DAE.ComponentRef> outDummyStates;
  output StateSets oStateSets;
algorithm
  (outDummyVars,outDummyStates,oStateSets) := 
  matchcontinue(freeStates,varlst,neqns,eqnslst,ilst,isyst,ishared,so,hov,inDummyStates,iStateSets)
    local 
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;    
      Integer nv;
      list<DAE.ComponentRef> dummyStates;  
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.AdjacencyMatrixEnhanced me;
      BackendDAE.AdjacencyMatrixTEnhanced meT;
      StateSets stateSets;
      String msg;
    // number of free states equal to number of differentiated equations -> no state selection necessary, all dummy states 
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(freeStates,neqns);
        dummyStates = List.map(varlst,BackendVariable.varCref);
        dummyStates = listAppend(dummyStates,inDummyStates);
      then 
        (varlst,dummyStates,iStateSets);
    // do state selection
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        // try to select dummy vars
        true = intGt(freeStates,1);
        false = intGt(neqns,freeStates);
        Debug.fcall(Flags.BLT_DUMP, print, "try to select dummy vars with natural matching(new)\n");
        
        // sort vars with heuristic
        vars = BackendVariable.listVar1(varlst);
        vars = sortStateCandidatesVars(vars,BackendVariable.daeVars(isyst),so);
        (vars,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(vars,setVarKind,BackendDAE.VARIABLE());
        
        eqns = BackendEquation.listEquation(eqnslst);
        syst = BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING(),{});
        
        //BackendDAE.DAE(eqs={syst}) = RemoveSimpleEquations.allAcausal(BackendDAE.DAE({syst},ishared));
        
        (me,meT,mapEqnIncRow,mapIncRowEqn) =  BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(syst,ishared);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpAdjacencyMatrixEnhanced,me);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpAdjacencyMatrixTEnhanced,meT);
        
//        (outDummyVars,dummyStates,stateSets) = processComps3New(arrayLength(meT),arrayLength(me),syst,me,meT,mapEqnIncRow1,mapIncRowEqn1,ishared,hov,inDummyStates,iStateSets);
        (outDummyVars,dummyStates,stateSets) = processComps3New(freeStates,neqns,syst,me,meT,mapEqnIncRow,mapIncRowEqn,ishared,hov,inDummyStates,iStateSets);
      then
        (outDummyVars,dummyStates,stateSets);
    // to much equations this is an error
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(neqns,freeStates);
        // no chance, to much equations
        msg = "It is not possible to select continues time states becasue Number of Equations " +& intString(neqns) +& " greater than number of States " +& intString(freeStates) +& " to select from.";
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then
        fail();
    // number of differentiated equations exceeds number of free states, add StateSelect.always states and try again
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(neqns,freeStates);
        // try again and add also stateSelect.always vars.
        nv = listLength(hov);
        true = intGe(nv,neqns);
        (outDummyVars,dummyStates,stateSets) = processComps2New(nv,hov,neqns,eqnslst,ilst,isyst,ishared,so,hov,inDummyStates,iStateSets);
      then 
        (outDummyVars,dummyStates,stateSets);
  end matchcontinue;
end processComps2New;

//protected import RemoveSimpleEquations;

protected function processComps3New
"function: processComps3
  author: Frenkel TUD 2012-11
  process all strong connected components of the system and collect the 
  derived equations for dummy state selection"
  input Integer inVarSize;
  input Integer inEqnsSize;
  input BackendDAE.EqSystem inSubsyst;
  input BackendDAE.AdjacencyMatrixEnhanced inMe;
  input BackendDAE.AdjacencyMatrixTEnhanced inMeT;
  input array<list<Integer>> inMapEqnIncRow1;
  input array<Integer> inMapIncRowEqn1;
  input BackendDAE.Shared iShared;
  input list<BackendDAE.Var> inHov; 
  input list<DAE.ComponentRef> inDummyStates;
  input StateSets iStateSets;
  output list<BackendDAE.Var> outDummyVars;
  output list<DAE.ComponentRef> outDummyStates;
  output StateSets oStateSets;
algorithm
  (outDummyVars,outDummyStates,oStateSets) := 
  matchcontinue(inVarSize,inEqnsSize,inSubsyst,inMe,inMeT,inMapEqnIncRow1,inMapIncRowEqn1,iShared,inHov,inDummyStates,iStateSets)
    local 
      BackendDAE.StateOrder so;
      BackendDAE.ConstraintEquations orgEqnsLst;
      array<list<Integer>> mapEqnIncRow,mapEqnIncRow1;
      array<Integer> mapIncRowEqn,mapIncRowEqn1;    
      Integer noofeqns;
      list<DAE.ComponentRef> dummyStates;  
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;     
      BackendDAE.Variables hov1,lov;
      list<DAE.ComponentRef> dummystates;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mT;
      array<Integer> vec1,vec2;
      list<tuple<DAE.ComponentRef, Integer>> states,dstates; 
      list<Integer> unassigned,assigned,set,usedstates,unusedstates;
      list<BackendDAE.Var> vlst;
      list<list<Integer>> sets;
      StateSets stateSets;
      DAE.FunctionTree funcs;
/*
    case (_,_,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),_,_,_,_,_,_,_,_)
      equation
        // get the states with equations
        usedstates = getUsedStates(arrayLength(inMeT),inMeT,{}); 
        true = intEq(listLength(usedstates),inEqnsSize);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printEqSystem, inSubsyst);
        vlst = List.map1r(usedstates,BackendVariable.getVarAt,vars);
        dummyStates = List.map(vlst,BackendVariable.varCref);
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates(4):\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dummyStates,ComponentReference.printComponentRefStr,"\n","\n")));
        dummyStates = listAppend(dummyStates,inDummyStates);
      then 
        (vlst,dummyStates,iStateSets);
*/    
    // do matching to get the dummy states and the state candidates for dynamic state selection
    case (_,_,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),_,_,_,_,_,_,_,_)
      equation
        // get indicenceMatrix from Enhanced
        m = incidenceMatrixfromEnhanced2(inMe,vars);
        mT = BackendDAEUtil.transposeMatrix(m,inVarSize);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printEqSystem, BackendDAE.EQSYSTEM(vars,eqns,SOME(m),SOME(mT),BackendDAE.NO_MATCHING(),{}));

        // match the variables not the equations, to have prevered states unmatched
        vec1 = arrayCreate(inEqnsSize,-1);
        vec2 = arrayCreate(inVarSize,-1);
        Matching.matchingExternalsetIncidenceMatrix(inEqnsSize,inVarSize,mT);
        BackendDAEEXT.matching(inEqnsSize,inVarSize,3,-1,1.0,1);
        BackendDAEEXT.getAssignment(vec2,vec1);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching, vec1);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching, vec2);

        (dstates,states) = checkAssignment(1,inVarSize,vec2,vars,{},{});
        vlst = List.map1r(List.map(dstates,Util.tuple22),BackendVariable.getVarAt,vars);
        dummyStates = List.map(vlst,BackendVariable.varCref);
        dummyStates = listAppend(dummyStates,inDummyStates);
        
        unassigned = Matching.getUnassigned(inEqnsSize, vec1, {});
        assigned = Matching.getAssigned(inEqnsSize, vec1, {});
        
        Debug.fcall(Flags.BLT_DUMP, print, ("dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dstates,BackendDAETransform.dumpStates,"\n","\n")));     
        Debug.fcall(Flags.BLT_DUMP, print, ("States:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));        
        Debug.fcall(Flags.BLT_DUMP, print, ("Unassigned Eqns:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((unassigned,intString," ","\n")));
        
        // splitt it into sets
        syst = BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.MATCHING(vec2,vec1,{}),{});
         dumpSystemGraphML(syst,iShared,NONE(),"StateSelection" +& intString(arrayLength(m)) +& ".graphml");
        funcs = BackendDAEUtil.getFunctions(iShared);
        (syst,m,mT,mapEqnIncRow1,mapIncRowEqn1) = BackendDAEUtil.getIncidenceMatrixScalar(syst,BackendDAE.NORMAL(), SOME(funcs));
        // TODO: partition the system 
        sets = partitionSystem(m,mT);
        
        //  print("Sets:\n");
        //  BackendDump.dumpIncidenceMatrix(listArray(sets));
        //  BackendDump.printEqSystem(syst);
        (vlst,dummyStates,stateSets) = processComps4New(sets,inVarSize,inEqnsSize,vars,eqns,m,mT,mapEqnIncRow1,mapIncRowEqn1,vec1,vec2,iShared,vlst,dummyStates,iStateSets);
     then
        (vlst,dummyStates,stateSets);
  end matchcontinue;
end processComps3New;

protected function getUsedStates
  input Integer n;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input list<Integer> iVars;
  output list<Integer> oVars;
algorithm
  oVars := match(n,mt,iVars)
    local
      BackendDAE.AdjacencyMatrixElementEnhanced row;
      list<Integer> vars;
      Boolean b;
    case(0,_,_) then iVars;
    case(_,_,_)
      equation
        row = mt[n];
        b = List.isNotEmpty(row);
        vars = List.consOnTrue(b, n, iVars);
      then
        getUsedStates(n-1,mt,vars);
  end match;
end getUsedStates;

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
"function: processComps4
  author: Frenkel TUD 2012-12
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
  input BackendDAE.Shared iShared;
  input list<BackendDAE.Var> inHov; 
  input list<DAE.ComponentRef> inDummyStates;
  input StateSets iStateSets;
  output list<BackendDAE.Var> outDummyVars;
  output list<DAE.ComponentRef> outDummyStates;
  output StateSets oStateSets;
algorithm
  (outDummyVars,outDummyStates,oStateSets) := 
  matchcontinue(iSets,inVarSize,inEqnsSize,iVars,iEqns,inM,inMT,inMapEqnIncRow,inMapIncRowEqn,vec1,vec2,iShared,inHov,inDummyStates,iStateSets)
    local 
      array<list<Integer>> mapEqnIncRow,mapEqnIncRow1;
      array<Integer> mapIncRowEqn,mapIncRowEqn1,ass1arr;    
      list<DAE.ComponentRef> dummyStates;  
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1;
      BackendDAE.EqSystem syst;
      BackendDAE.Variables hov1,lov;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mT;
      list<Integer> seteqns,unassigned,assigned,set,statevars,dstatevars,ass1,ass2,ass,assigend1,range;
      list<BackendDAE.Var> varlst;
      list<list<Integer>> sets;
      array<Boolean> flag;
      list<BackendDAE.Equation> eqnlst;
      BackendDAE.AdjacencyMatrixEnhanced me;
      BackendDAE.AdjacencyMatrixTEnhanced meT;
      list<tuple<DAE.ComponentRef, Integer>> states1,dstates1;
      Integer nstatevars,nassigned,nunassigned,nass1arr,n,nv,ne;
      StateSets stateSets;
    
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        (inHov,inDummyStates,iStateSets);    
    case (assigned::sets,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // ignore sets without unassigned equations, because all assigned states already in dummy states
        {} = List.select1r(assigned,Matching.isUnAssigned,vec1);
        // next set
        (varlst,dummyStates,stateSets) = processComps4New(sets,inVarSize,inEqnsSize,iVars,iEqns,inM,inMT,inMapEqnIncRow,inMapIncRowEqn,vec1,vec2,iShared,inHov,inDummyStates,iStateSets);
     then
        (varlst,dummyStates,stateSets);
    case (seteqns::sets,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
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
        (varlst,stateSets) = selectDummyDerivatives2new(dstates1,states1,range,assigend1,vars,nv,eqns,ne,iStateSets);
        dummyStates = List.map(varlst,BackendVariable.varCref);
        dummyStates = listAppend(inDummyStates,dummyStates);
        varlst = listAppend(varlst,inHov);
        // next set
        (varlst,dummyStates,stateSets) = processComps4New(sets,inVarSize,inEqnsSize,iVars,eqns1,inM,inMT,inMapEqnIncRow,inMapIncRowEqn,vec1,vec2,iShared,varlst,dummyStates,stateSets);
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
        // print("BackendDAEUtil.equationNth " +& intString(e1) +& "\n");
        eqn = BackendDAEUtil.equationNth(iEqnsArr,e1-1);
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
      list<Integer> set;
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
"function getEqnsforDynamicStateSelectionPhase
  helper for getEqnsforDynamicStateSelection
  author: Frenkel TUD 2012-12"
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
      Integer e,v;
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
"function getEqnsforDynamicStateSelectionRows
  helper for getEqnsforDynamicStateSelection
  author: Frenkel TUD 2012-12"
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

protected function getEqnBlockMapper
  input Integer nEqns "Number of Equations";
  input  list<list<Integer>> inComps;
  output array<Integer> mapEqnBlock "mapEqnBlock[eqn]=block";
  output array<list<Integer>> mapBlockEqn "mapBlockEqn[block]=eqns";
algorithm
  mapEqnBlock := arrayCreate(nEqns,-1);
  getEqnBlockMapper1(inComps,1,mapEqnBlock);
  mapBlockEqn := listArray(inComps);
end getEqnBlockMapper;

protected function getEqnBlockMapper1
  input list<list<Integer>> inComps;
  input Integer blockId;
  input array<Integer> mapEqnBlock "mapEqnBlock[eqn]=block";
algorithm
  _ := match(inComps,blockId,mapEqnBlock)
    local
      list<Integer> comp;
      list<list<Integer>> comps;
    case({},_,_) then ();
    case(comp::comps,_,_)
      equation
        getEqnBlockMapper2(comp,blockId,mapEqnBlock);
        getEqnBlockMapper1(comps,blockId+1,mapEqnBlock);
      then
        ();
  end match;
end getEqnBlockMapper1;

protected function getEqnBlockMapper2
  input list<Integer> inComp;
  input Integer blockId;
  input array<Integer> mapEqnBlock "mapEqnBlock[eqn]=block";
algorithm
  _ := match(inComp,blockId,mapEqnBlock)
    local
      Integer c;
      list<Integer> comp;
    case({},_,_) then ();
    case(c::comp,_,_)
      equation
        _ = arrayUpdate(mapEqnBlock,c,blockId);
        getEqnBlockMapper2(comp,blockId,mapEqnBlock);
      then
        ();
  end match;
end getEqnBlockMapper2;

protected function processComps1
"function: processComps1
  author: Frenkel TUD 2012-05
  process all strong connected components of the system and collect the 
  derived equations for dummy state selection"
  input list<list<Integer>> inComps;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input array<Integer> vec2;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  input BackendDAE.Variables hov;
  input list<DAE.ComponentRef> inDummyStates;
  input StateSets iStateSets;
  output list<DAE.ComponentRef> outDummyStates;
  output StateSets oStateSets;
algorithm
  (outDummyStates,oStateSets) := 
  match(inComps,isyst,ishared,vec2,inArg,hov,inDummyStates,iStateSets)
    local 
      list<Integer> comp;
      list<list<Integer>> rest;
      BackendDAE.StateOrder so;
      BackendDAE.ConstraintEquations orgEqnsLst;
      list<tuple<Integer, list<BackendDAE.Equation>, Integer>> orgEqnLevel;
      BackendDAE.Variables hov1,cv;
      list<DAE.ComponentRef> dummyStates;  
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;    
      Integer noofeqns,setIndex;
      StateSets stateSets;
    case ({},_,_,_,_,_,_,_) then (inDummyStates,iStateSets);
    case (comp::rest,_,_,_,(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,noofeqns),_,_,_)
      equation
        // get vars
        cv = List.fold2(comp,getCompVars,vec2,(BackendVariable.daeVars(isyst),hov,so),BackendVariable.emptyVars());
        // get equations 
        comp = List.uniqueIntN(List.map1r(comp,arrayGet,mapIncRowEqn),arrayLength(mapEqnIncRow));
        comp = List.sort(comp,intGt);
        (orgEqnsLst,orgEqnLevel) = getOrgEqns(comp,orgEqnsLst,{},{},BackendEquation.daeEqns(isyst));
        // sort eqns, this is maybe not neccessary
        orgEqnLevel = List.sort(orgEqnLevel,compareOrgEqn);
        (hov1,dummyStates,stateSets) = processComp(orgEqnLevel,isyst,ishared,so,cv,hov,inDummyStates,iStateSets);
        //(hov1,dummyStates,_) = processCompInv(orgEqnLevel,isyst,ishared,so,cv,hov,hov,inDummyStates);
        (dummyStates,stateSets) = processComps1(rest,isyst,ishared,vec2,(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,noofeqns),hov1,dummyStates,stateSets);
      then
        (dummyStates,stateSets);
  end match;
end processComps1;

protected function compareOrgEqn
"function: compareOrgEqn
  author: Frenkel TUD 2011-05
  returns inA number of diverentations < inB number of diverentations"
  input tuple<Integer, list<BackendDAE.Equation>, Integer> inA;
  input tuple<Integer, list<BackendDAE.Equation>, Integer> inB;
  output Boolean lt;
algorithm
  lt := intGt(Util.tuple33(inA),Util.tuple33(inB));  
end compareOrgEqn;

protected function getFirstOrgEqns
"function: getFirstOrgEqns
  author: Frenkel TUD 2011-11
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
      list<Integer> restcomp;
      BackendDAE.ConstraintEquations rest,orgeqns;
      BackendDAE.Equation eqn;
      Integer e,l,c;
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

protected function getOrgEqns
"function: getOrgEqn
  author: Frenkel TUD 2011-05
  returns the first equation of each orgeqn list."
  input list<Integer> comp;
  input BackendDAE.ConstraintEquations inOrgEqns;
  input BackendDAE.ConstraintEquations inOrgEqns1;
  input list<tuple<Integer, list<BackendDAE.Equation>, Integer>> inOrgEqnLevel;
  input BackendDAE.EquationArray eqns;
  output BackendDAE.ConstraintEquations outOrgEqns;
  output list<tuple<Integer, list<BackendDAE.Equation>, Integer>> outOrgEqnLevel;
algorithm
  (outOrgEqns,outOrgEqnLevel) :=
  matchcontinue (comp,inOrgEqns,inOrgEqns1,inOrgEqnLevel,eqns)
    local
      list<Integer> restcomp;
      BackendDAE.ConstraintEquations rest,orgeqns;
      BackendDAE.Equation eqn;
      Integer e,l,c;
      list<tuple<Integer, list<BackendDAE.Equation>, Integer>> orgEqnLevel;
      list<BackendDAE.Equation> orgeqn;
    case (_,{},_,_,_) then (listReverse(inOrgEqns1),inOrgEqnLevel);
    case ({},_,_,_,_)
      equation
        orgeqns = listAppend(listReverse(inOrgEqns1),inOrgEqns);
      then (orgeqns,inOrgEqnLevel);
    case (c::restcomp,(e,orgeqn)::rest,_,_,_)
      equation
        true = intEq(c,e);
        l = listLength(orgeqn);
//        eqn = BackendDAEUtil.equationNth(eqns,e-1);
//der        (orgeqns,orgEqnLevel) = getOrgEqns(restcomp,rest,inOrgEqns1,(e,eqn::orgeqn,l)::inOrgEqnLevel,eqns);
        (orgeqns,orgEqnLevel) = getOrgEqns(restcomp,rest,inOrgEqns1,(e,orgeqn,l)::inOrgEqnLevel,eqns);
      then
        (orgeqns,orgEqnLevel);    
    case (c::restcomp,(e,orgeqn)::rest,_,_,_)
      equation
        true = intLt(c,e);
        (orgeqns,orgEqnLevel) = getOrgEqns(restcomp,inOrgEqns,inOrgEqns1,inOrgEqnLevel,eqns);
      then
        (orgeqns,orgEqnLevel);     
    case (c::restcomp,(e,orgeqn)::rest,_,_,_)
      equation
        (orgeqns,orgEqnLevel) = getOrgEqns(comp,rest,(e,orgeqn)::inOrgEqns1,inOrgEqnLevel,eqns);
      then
        (orgeqns,orgEqnLevel);              
  end matchcontinue;
end getOrgEqns;

protected function getCompVars
"function: getCompVars
  author: Frenkel TUD 2012-05
  return all vars of a strong connected component"
  input Integer e;
  input array<Integer> vec2;
  input tuple<BackendDAE.Variables,BackendDAE.Variables,BackendDAE.StateOrder> tpl;
  input BackendDAE.Variables iCompVars;
  output BackendDAE.Variables oCompVars;
algorithm
  oCompVars := matchcontinue(e,vec2,tpl,iCompVars)
    local 
      BackendDAE.Var v;
      BackendDAE.Variables vars,hov;
      DAE.ComponentRef cr,dcr;
      BackendDAE.StateOrder so;
    case (_,_,(vars,hov,so),_)
      equation
        v = BackendVariable.getVarAt(vars,vec2[e]);
        cr = BackendVariable.varCref(v);
        true = BackendVariable.isStateVar(v);
        (_::_,_) = BackendVariable.getVar(cr,hov);
      then
        BackendVariable.addVar(v,iCompVars);
    case (_,_,(vars,hov,so),_)
      equation
        v = BackendVariable.getVarAt(vars,vec2[e]);
        dcr = BackendVariable.varCref(v);
        false = BackendVariable.isStateVar(v);
        cr::_ = BackendDAETransform.getDerStateOrder(dcr,so);
        (v::_,_) = BackendVariable.getVar(cr, vars);        
        (_::_,_) = BackendVariable.getVar(cr,hov);
      then
        BackendVariable.addVar(v,iCompVars);
    else
      iCompVars;        
  end matchcontinue; 
end getCompVars;

protected function processComp
"function: processComp
  author: Frenkel TUD 2012-05
  process all derivation levels of a strong connected component and calls for it the dummy
  state selection"
  input list<tuple<Integer, list<BackendDAE.Equation>, Integer>> orgEqnsLst;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StateOrder so;
  input BackendDAE.Variables cvars;
  input BackendDAE.Variables hov;
  input list<DAE.ComponentRef> inDummyStates;
  input StateSets iStateSets;
  output BackendDAE.Variables outhov;
  output list<DAE.ComponentRef> outDummyStates;
  output StateSets oStateSets;
algorithm
  (outhov,outDummyStates,oStateSets) := 
  matchcontinue(orgEqnsLst,isyst,ishared,so,cvars,hov,inDummyStates,iStateSets)
    local 
      list<BackendDAE.Equation> eqnslst;
      list<tuple<Integer, list<BackendDAE.Equation>, Integer>> orgeqns;
      BackendDAE.Variables lov,hov_1;
      list<DAE.ComponentRef> dummyStates;
      BackendDAE.EquationArray eqns;
      list<Integer> eqnindxlst;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      StateSets stateSets;
    case ({},_,_,_,_,_,_,_) then (hov,inDummyStates,iStateSets);
    case (_,_,_,_,_,_,_,_)
      equation
        (orgeqns,eqnslst,eqnindxlst) = getOrgEqn(orgEqnsLst,{},{},{});
        // inline array eqns
        (eqnslst,_) = BackendDAEOptimize.getScalarArrayEqns(eqnslst,{},false);
        eqns = BackendEquation.listEquation(eqnslst);
        (hov_1,dummyStates,lov,stateSets) = selectDummyDerivatives(cvars,BackendVariable.numVariables(cvars),eqns,BackendDAEUtil.equationSize(eqns),eqnindxlst,hov,inDummyStates,isyst,ishared,so,BackendVariable.emptyVars(),iStateSets);
        // get derivatives one order less
        lov = lowerOrderDerivatives(lov,BackendVariable.daeVars(isyst),so);
        // call again with original equations of derived equations 
        (hov_1,dummyStates,stateSets) = processComp(orgeqns,isyst,ishared,so,lov,hov_1,dummyStates,iStateSets);
      then
        (hov_1,dummyStates,stateSets);
    else
      equation
        BackendDump.printEqSystem(isyst);
      then 
        fail();
  end matchcontinue;
end processComp;

protected function processCompInv
"function: getCompVars
  author: Frenkel TUD 2012-05
  process all derivation levels in reverse order of a strong connected component and calls for it the dummy
  state selection"
  input list<tuple<Integer, list<BackendDAE.Equation>, Integer>> orgEqnsLst;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StateOrder so;
  input BackendDAE.Variables cvars;
  input BackendDAE.Variables hov;
  input BackendDAE.Variables hov1;
  input list<DAE.ComponentRef> inDummyStates;
  input StateSets iStateSets;
  output BackendDAE.Variables outhov;
  output list<DAE.ComponentRef> outDummyStates;
  output BackendDAE.Variables outStates;
  output StateSets oStateSets;
algorithm
  (outhov,outDummyStates,outStates,oStateSets) := 
  matchcontinue(orgEqnsLst,isyst,ishared,so,cvars,hov,hov1,inDummyStates,iStateSets)
    local 
      list<BackendDAE.Equation> eqnslst;
      list<tuple<Integer, list<BackendDAE.Equation>, Integer>> orgeqns;
      BackendDAE.Variables vars,lov,hov_1;
      list<DAE.ComponentRef> dummyStates;
      list<DAE.ComponentRef> crlst;
      BackendDAE.EquationArray eqns;
      list<Integer> eqnindxlst;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      StateSets stateSets;
    case ({},_,_,_,_,_,_,_,_) then (hov1,inDummyStates,BackendVariable.emptyVars(),iStateSets);
    case (_,_,_,_,_,_,_,_,_)
      equation
        (orgeqns,eqnslst,eqnindxlst) = getOrgEqn(orgEqnsLst,{},{},{});
        // get all derivatives one order less
        lov = lowerOrderDerivatives(cvars,BackendVariable.daeVars(isyst),so);
        // gall again with original equations of derived equations 
        (hov_1,dummyStates,vars,stateSets) = processCompInv(orgeqns,isyst,ishared,so,lov,lov,hov1,inDummyStates,iStateSets);
        // remove dummy states from candidates    
        crlst = BackendVariable.getAllCrefFromVariables(vars);
        vars = BackendVariable.deleteCrefs(crlst,cvars);
        Debug.fcall(Flags.BLT_DUMP, print,"Vars:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVariables,vars);
        // select dummy derivatives
        eqns = BackendEquation.listEquation(eqnslst);
        (hov_1,dummyStates,lov,stateSets) = selectDummyDerivatives(vars,BackendVariable.numVariables(vars),eqns,BackendDAEUtil.equationSize(eqns),eqnindxlst,hov_1,dummyStates,isyst,ishared,so,BackendVariable.emptyVars(),stateSets);
        // get derivatives 
        (lov,dummyStates) = higerOrderDerivatives(lov,BackendVariable.daeVars(isyst),so,dummyStates);
        Debug.fcall(Flags.BLT_DUMP, print,"HigerOrderVars:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVariables,lov);
      then
        (hov_1,dummyStates,lov,stateSets); 
  end matchcontinue;
end processCompInv;

protected function getOrgEqn
"function: getOrgEqn
  author: Frenkel TUD 2012-05
  returns the first equation of each orgeqn list."
  input list<tuple<Integer, list<BackendDAE.Equation>, Integer>> inOrgEqns;
  input list<BackendDAE.Equation> inEqns;
  input list<tuple<Integer, list<BackendDAE.Equation>, Integer>> inOrgEqns1;
  input list<Integer> inEqnindxlst;
  output list<tuple<Integer, list<BackendDAE.Equation>, Integer>> outOrgEqns;
  output list<BackendDAE.Equation> outEqns;
  output list<Integer> outEqnindxlst;
algorithm
  (outOrgEqns,outEqns,outEqnindxlst) :=
  match (inOrgEqns,inEqns,inOrgEqns1,inEqnindxlst)
    local
      list<tuple<Integer, list<BackendDAE.Equation>, Integer>> rest,orgeqns;
      BackendDAE.Equation eqn;
      Integer e,l;
      list<BackendDAE.Equation> orgeqn,eqns;
      list<Integer> eqnindxlst;
    
    case ({},_,_,_) then (listReverse(inOrgEqns1),listReverse(inEqns),listReverse(inEqnindxlst));
    case ((e,eqn::{},l)::rest,_,_,_)
      equation
        (orgeqns,eqns,eqnindxlst) = getOrgEqn(rest,eqn::inEqns,inOrgEqns1,e::inEqnindxlst);
      then
        (orgeqns,eqns,eqnindxlst);  
    case ((e,eqn::orgeqn,l)::rest,_,_,_)
      equation
        l = l-1;
        (orgeqns,eqns,eqnindxlst) = getOrgEqn(rest,eqn::inEqns,(e,orgeqn,l)::inOrgEqns1,e::inEqnindxlst);
//inv   (orgeqns,eqns,eqnindxlst) = getOrgEqn(rest,inEqns,(e,orgeqn,l)::inOrgEqns1,inEqnindxlst);
      then
        (orgeqns,eqns,eqnindxlst);      
  end match;
end getOrgEqn;

protected function selectDummyDerivatives
"function: selectDummyDerivatives
  author: Frenkel TUD 2012-05
  select dummy derivatives from strong connected component"
  input BackendDAE.Variables vars;
  input Integer varSize;
  input BackendDAE.EquationArray eqns;
  input Integer eqnsSize;
  input list<Integer> eqnindxlst;
  input BackendDAE.Variables hov;
  input list<DAE.ComponentRef> inDummyStates;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StateOrder so;
  input BackendDAE.Variables inLov;
  input StateSets iStateSets;
  output BackendDAE.Variables outhov;
  output list<DAE.ComponentRef> outDummyStates;
  output BackendDAE.Variables outlov;
  output StateSets oStateSets;
algorithm
  (outhov,outDummyStates,outlov,oStateSets) := 
  matchcontinue(vars,varSize,eqns,eqnsSize,eqnindxlst,hov,inDummyStates,isyst,ishared,so,inLov,iStateSets)
      local 
        BackendDAE.Variables hov1,lov,vars1;
        list<DAE.ComponentRef> dummystates,crlst;
        BackendDAE.Var v;
        DAE.ComponentRef cr;
        BackendDAE.EqSystem syst;
        BackendDAE.Shared shared;  
        list<BackendDAE.Var> varlst;
        list<tuple<DAE.ComponentRef, Integer>> states;
        BackendDAE.AdjacencyMatrixEnhanced me;
        BackendDAE.AdjacencyMatrixTEnhanced meT;  
        array<list<Integer>> mapEqnIncRow;
        array<Integer> mapIncRowEqn;
        Integer dummyvarssize;
        StateSets stateSets;
        DAE.FunctionTree funcs;
    case(_,0,_,_,_,_,_,_,_,_,_,_)
        // if no vars then there is nothing do do
      then
        (hov,inDummyStates,inLov,iStateSets);
    case(_,1,_,1,_,_,dummystates,_,_,_,_,_)
      equation
        // if there is only one var select it because there is no choice
        Debug.fcall(Flags.BLT_DUMP, print, "single var and eqn\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVariables, vars);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printEquationArray, eqns);
        v = BackendVariable.getVarAt(vars,1);
        cr = BackendVariable.varCref(v);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrCrefStr, ("Select ",cr," as dummyState\n"));
        hov1 = BackendVariable.removeCref(cr,hov);
        lov = BackendVariable.addVar(v,inLov);
      then
        (hov1,cr::dummystates,lov,iStateSets);
    case(_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // if eqnsSize is equal to varsize all variables are dummy derivatives no choise
        true = intGt(varSize,1);
        true = intEq(eqnsSize,varSize);
        Debug.fcall(Flags.BLT_DUMP, print, "equal var and eqn size\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVariables, vars);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printEquationArray, eqns);
        varlst = BackendVariable.varList(vars);
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates(5):\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVarList,varlst);
        (hov1,lov,dummystates) = selectDummyStateVars(varlst,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov,iStateSets); 
    case(_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // try to select dummy vars
        true = intGt(varSize,1);
        false = intGt(eqnsSize,varSize);
        varlst = BackendVariable.varList(vars);
        varlst = List.filter(varlst, notVarStateSelectAlways);
        dummyvarssize = listLength(varlst);
        true = intEq(eqnsSize,dummyvarssize);
        Debug.fcall(Flags.BLT_DUMP, print, "select dummy vars from stateselection\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVariables, vars);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printEquationArray, eqns);
        crlst = List.map(varlst,BackendVariable.varCref);
        states = List.threadTuple(crlst,List.intRange2(1,dummyvarssize));
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates(6):\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVarList,varlst);
        (hov1,lov,dummystates) = selectDummyStateVars(varlst,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov,iStateSets); 
    case(_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // try to select dummy vars
        true = intGt(varSize,1);
        false = intGt(eqnsSize,varSize);
        Debug.fcall(Flags.BLT_DUMP, print, "try to select dummy vars with natural matching\n");
        
        // sort vars with heuristic
        vars1 = sortStateCandidatesVars(vars,BackendVariable.daeVars(isyst),so);

        (vars1,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(vars1,setVarKind,BackendDAE.VARIABLE());
        syst = BackendDAE.EQSYSTEM(vars1,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING(),{});
        
        (me,meT,mapEqnIncRow,mapIncRowEqn) =  BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(syst,ishared);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpAdjacencyMatrixEnhanced,me);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpAdjacencyMatrixTEnhanced,meT);
        (hov1,dummystates,lov,stateSets) = selectDummyDerivatives1(me,meT,vars1,varSize,eqns,eqnsSize,eqnindxlst,hov,inDummyStates,isyst,ishared,inLov,mapEqnIncRow,mapIncRowEqn,iStateSets);
      then
        (hov1,dummystates,lov,stateSets);
    case(_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // try to select dummy vars heuristic based
        true = intGt(varSize,1);
        false = intGt(eqnsSize,varSize);
        Debug.fcall(Flags.BLT_DUMP, print, "try to select dummy vars heuristic based\n");
        funcs = BackendDAEUtil.getFunctions(ishared);
        (syst,_,_,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING(),{}),BackendDAE.NORMAL(), SOME(funcs));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printEqSystem, syst);
        varlst = BackendVariable.varList(vars);
        crlst = List.map(varlst,BackendVariable.varCref);
        states = List.threadTuple(crlst,List.intRange2(1,varSize));
        states = BackendDAETransform.sortStateCandidates(states,syst,so);
        //states = List.sort(states,stateSortFunc);
        //states = listReverse(states);
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates(7):\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));
        (hov1,lov,dummystates) = selectDummyStates(states,1,eqnsSize,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov,iStateSets);        
    case(_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // if ther are more equations than vars, singular system
        true = intGt(varSize,1);
        true = intGt(eqnsSize,varSize);
        print("Structural singular system:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVariables, vars);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printEquationArray, eqns);
      then
        fail();
  end matchcontinue;
end selectDummyDerivatives;

protected function sortStateCandidatesVars
"function: sortStateCandidatesVars
  author: Frenkel TUD 2012-08
  sort the state candidates"
  input BackendDAE.Variables inVars;
  input BackendDAE.Variables allVars;
  input BackendDAE.StateOrder so;
  output BackendDAE.Variables outStates;
algorithm
  outStates:=
  matchcontinue (inVars,allVars,so)
    local
      Integer varsize;
      list<Integer> varIndices;
      BackendDAE.Variables vars;
      list<tuple<DAE.ComponentRef,Integer,Real>> prioTuples;
      list<BackendDAE.Var> vlst;

    case (_,_,_)
      equation
        varsize = BackendVariable.varsSize(inVars);
        prioTuples = calculateVarPriorities(1,inVars,varsize,allVars,so,{});
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
"function: sortprioTuples
  author: Frenkel TUD 2011-05
  helper for sortStateCandidates"
  input tuple<DAE.ComponentRef,Integer,Real> inTpl1;
  input tuple<DAE.ComponentRef,Integer,Real> inTpl2;
  output Boolean b;
algorithm
  b:= realGt(Util.tuple33(inTpl1),Util.tuple33(inTpl2));
end sortprioTuples;

protected function calculateVarPriorities
"function: calculateVarPriorities
  author: Frenkel TUD 2012-08"
  input Integer index;
  input BackendDAE.Variables vars;
  input Integer varsSize;
  input BackendDAE.Variables allVars;
  input BackendDAE.StateOrder so;
  input list<tuple<DAE.ComponentRef,Integer,Real>> iTuples;
  output list<tuple<DAE.ComponentRef,Integer,Real>> tuples;
algorithm
  tuples := matchcontinue(index,vars,varsSize,allVars,so,iTuples)
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
        prio2 = varStateSelectHeuristicPrio(v,allVars,so);
        prio = prio1 +. prio2;
        Debug.fcall(Flags.DUMMY_SELECT,BackendDump.debugStrCrefStrRealStrRealStrRealStr,("Calc Prio for ",varCref,"\n Prio StateSelect : ",prio1,"\n Prio Heuristik : ",prio2,"\n ### Prio Result : ",prio,"\n"));
      then
        calculateVarPriorities(index+1,vars,varsSize,allVars,so,(varCref,index,prio)::iTuples);
    case (_,_,_,_,_,_)
      equation
        false = intLe(index,varsSize);
      then
        iTuples;
  end matchcontinue;
end calculateVarPriorities;

protected function varStateSelectHeuristicPrio
"function varStateSelectHeuristicPrio
  author: Frenkel TUD 2012-08"
  input BackendDAE.Var v;
  input BackendDAE.Variables vars;
  input BackendDAE.StateOrder so;
  output Real prio;
protected
  Real prio1,prio2,prio3,prio4,prio5;
algorithm
  prio1 := varStateSelectHeuristicPrio1(v);
  prio2 := varStateSelectHeuristicPrio2(v);
  prio3 := varStateSelectHeuristicPrio3(v);
  prio4 := varStateSelectHeuristicPrio4(v,so,vars);
  prio5 := varStateSelectHeuristicPrio5(v);
  prio:= prio1 +. prio2 +. prio3 +. prio4 +. prio5;
  printVarListtateSelectHeuristicPrio(prio1,prio2,prio3,prio4,prio5);
end varStateSelectHeuristicPrio;

protected function printVarListtateSelectHeuristicPrio
  input Real Prio1;
  input Real Prio2;
  input Real Prio3;
  input Real Prio4;
  input Real Prio5;
algorithm
  _ := matchcontinue(Prio1,Prio2,Prio3,Prio4,Prio5)
    case(_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.DUMMY_SELECT);
        print("Prio 1 : " +& realString(Prio1) +& "\n");
        print("Prio 2 : " +& realString(Prio2) +& "\n");
        print("Prio 3 : " +& realString(Prio3) +& "\n");
        print("Prio 4 : " +& realString(Prio4) +& "\n");
        print("Prio 5 : " +& realString(Prio5) +& "\n");
      then
        ();
    else then ();        
  end matchcontinue;
end printVarListtateSelectHeuristicPrio;

protected function varStateSelectHeuristicPrio5
"function varStateSelectHeuristicPrio5
  author: Frenkel TUD 2012-10
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
"function varStateSelectHeuristicPrio4
  author: Frenkel TUD 2012-08
  Helper function to varStateSelectHeuristicPrio.
  added prio for states/variables wich are derivatives of deselected states"
  input BackendDAE.Var v;
  input BackendDAE.StateOrder so;
  input BackendDAE.Variables vars;
  output Real prio;
algorithm
  prio := matchcontinue(v,so,vars)
    local DAE.ComponentRef cr,pcr;
    case(BackendDAE.VAR(varName=cr),_,_)
      equation
        pcr::_ = BackendDAETransform.getDerStateOrder(cr, so);
        (BackendDAE.VAR(varKind=BackendDAE.DUMMY_STATE())::{},_) = BackendVariable.getVar(pcr, vars);
      then -1.0;
    else then 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio4;

protected function varStateSelectHeuristicPrio3
"function varStateSelectHeuristicPrio3
  author: Frenkel TUD 2012-04
  Helper function to varStateSelectHeuristicPrio.
  added prio for variables with $_DER. name. Thouse are dummy_states
  added by index reduction from normal variables"
  input BackendDAE.Var v;
  output Real prio;
algorithm
  prio := matchcontinue(v)
    local DAE.ComponentRef cr,pcr;
    case(BackendDAE.VAR(varName=cr))
      equation
        pcr = ComponentReference.crefFirstCref(cr);
        true = ComponentReference.crefEqual(pcr,ComponentReference.makeCrefIdent("$_DER",DAE.T_REAL_DEFAULT,{}));
      then -100.0;
    else then 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio3;

protected function varStateSelectHeuristicPrio2
"function varStateSelectHeuristicPrio2
  author: Frenkel TUD 2011-05
  Helper function to varStateSelectHeuristicPrio.
  added prio for variables with fixed = true "
  input BackendDAE.Var v;
  output Real prio;
algorithm
  prio := matchcontinue(v)
    case _
      equation
        true = BackendVariable.varFixed(v);
      then 1.0;
    else then 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio2;

protected function varStateSelectHeuristicPrio1
"function varStateSelectHeuristicPrio1
  author: wbraun
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
        true = Expression.isZero(e);
      then -0.1;
    else then 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio1;

protected function varStateSelectPrio
"function varStateSelectPrio
  Helper function to calculateVarPriorities.
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

protected function stateSortFunc
  input tuple<DAE.ComponentRef, Integer> inA;
  input tuple<DAE.ComponentRef, Integer> inB;
  output Boolean b;
algorithm
  b:= ComponentReference.crefSortFunc(Util.tuple21(inA),Util.tuple21(inB));
end stateSortFunc;

protected function selectDummyDerivatives1
"function: selectDummyDerivatives1
  author: Frenkel TUD 2012-05
  select dummy derivatives from strong connected component"
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixTEnhanced meT;
  input BackendDAE.Variables vars;
  input Integer varSize;
  input BackendDAE.EquationArray eqns;
  input Integer eqnsSize;
  input list<Integer> eqnindxlst;
  input BackendDAE.Variables hov;
  input list<DAE.ComponentRef> inDummyStates;
  input BackendDAE.EqSystem isyst;  
  input BackendDAE.Shared ishared;
  input BackendDAE.Variables inLov;
  input array<list<Integer>> iMapEqnIncRow;
  input array<Integer> iMapIncRowEqn;
  input StateSets iStateSets;
  output BackendDAE.Variables outhov;
  output list<DAE.ComponentRef> outDummyStates;
  output BackendDAE.Variables outlov;
  output StateSets oStateSets;
algorithm
  (outhov,outDummyStates,outlov,oStateSets) := 
  matchcontinue(me,meT,vars,varSize,eqns,eqnsSize,eqnindxlst,hov,inDummyStates,isyst,ishared,inLov,iMapEqnIncRow,iMapIncRowEqn,iStateSets)
      local 
        BackendDAE.Variables hov1,lov;
        list<DAE.ComponentRef> dummystates;
        BackendDAE.IncidenceMatrix m;
        BackendDAE.IncidenceMatrixT mT;
        array<Integer> vec1,vec2;
        BackendDAE.EqSystem syst;
        BackendDAE.Shared shared; 
        list<tuple<DAE.ComponentRef, Integer>> states,dstates; 
        list<Integer> unassigned,assigned;
        StateSets stateSets;
    case(_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        m = incidenceMatrixfromEnhanced(me);
        mT = incidenceMatrixfromEnhanced(meT);  
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printEqSystem, BackendDAE.EQSYSTEM(vars,eqns,SOME(m),SOME(mT),BackendDAE.NO_MATCHING(),{}));
        Matching.matchingExternalsetIncidenceMatrix(eqnsSize,varSize,mT);
        BackendDAEEXT.matching(eqnsSize,varSize,3,-1,1.0,1);
        vec1 = arrayCreate(eqnsSize,-1);
        vec2 = arrayCreate(varSize,-1);
        BackendDAEEXT.getAssignment(vec2,vec1);         
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching,vec1);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching,vec2);
/*        (states,_) = checkAssignment(1,varSize,vec2,vars,{},{});
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));
        rang = eqnsSize-listLength(states);
        true = intEq(rang,0);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrIntStrIntStr, ("Select ",varSize-eqnsSize," from ",varSize-rang,"\n"));        
        (hov1,lov,dummystates) = selectDummyStates(states,1,eqnsSize,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov,isyst,ishared); 
*/
        (dstates,states) = checkAssignment(1,varSize,vec2,vars,{},{});
        unassigned = Matching.getUnassigned(eqnsSize, vec1, {});
        assigned = Matching.getAssigned(eqnsSize, vec1, {});
        
        Debug.fcall(Flags.BLT_DUMP, print, ("dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dstates,BackendDAETransform.dumpStates,"\n","\n")));     
        Debug.fcall(Flags.BLT_DUMP, print, ("States:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));        
        Debug.fcall(Flags.BLT_DUMP, print, ("Unassigned Eqns:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((unassigned,intString," ","\n")));        
        
        (hov1,dummystates,lov,stateSets) = selectDummyDerivatives2(dstates,states,unassigned,assigned,vars,varSize,eqns,eqnsSize,eqnindxlst,hov,inDummyStates,inLov,iStateSets);
      then
        (hov1,dummystates,lov,stateSets);        
    case(_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        m = incidenceMatrixfromEnhanced1(me);
        mT = incidenceMatrixfromEnhanced1(meT);  
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printEqSystem, BackendDAE.EQSYSTEM(vars,eqns,SOME(m),SOME(mT),BackendDAE.NO_MATCHING(),{}));
        Matching.matchingExternalsetIncidenceMatrix(eqnsSize,varSize,mT);
        BackendDAEEXT.matching(eqnsSize,varSize,3,-1,1.0,1);
        vec1 = arrayCreate(eqnsSize,-1);
        vec2 = arrayCreate(varSize,-1);
        BackendDAEEXT.getAssignment(vec2,vec1);   
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching,vec1);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching,vec2);
        (dstates,states) = checkAssignment(1,varSize,vec2,vars,{},{});
        unassigned = Matching.getUnassigned(eqnsSize, vec1, {});
        assigned = Matching.getAssigned(eqnsSize, vec1, {});
        
        Debug.fcall(Flags.BLT_DUMP, print, ("dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dstates,BackendDAETransform.dumpStates,"\n","\n")));     
        Debug.fcall(Flags.BLT_DUMP, print, ("States:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));        
        Debug.fcall(Flags.BLT_DUMP, print, ("Unassigned Eqns:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((unassigned,intString," ","\n")));        
        
        (hov1,dummystates,lov,stateSets) = selectDummyDerivatives2(dstates,states,unassigned,assigned,vars,varSize,eqns,eqnsSize,eqnindxlst,hov,inDummyStates,inLov,iStateSets);
      then
        (hov1,dummystates,lov,stateSets);             
  end matchcontinue;
end selectDummyDerivatives1;

protected function selectDummyDerivatives2
"function: selectDummyDerivatives2
  author: Frenkel TUD 2012-05
  select dummy derivatives from strong connected component"
  input list<tuple<DAE.ComponentRef, Integer>> dstates;
  input list<tuple<DAE.ComponentRef, Integer>> states;
  input list<Integer> unassignedEqns;
  input list<Integer> assignedEqns;
  input BackendDAE.Variables vars;
  input Integer varSize;
  input BackendDAE.EquationArray eqns;
  input Integer eqnsSize;
  input list<Integer> eqnindxlst;
  input BackendDAE.Variables hov;
  input list<DAE.ComponentRef> inDummyStates;
  input BackendDAE.Variables inLov;
  input StateSets iStateSets;
  output BackendDAE.Variables outhov;
  output list<DAE.ComponentRef> outDummyStates;
  output BackendDAE.Variables outlov;
  output StateSets oStateSets;
algorithm
  (outhov,outDummyStates,outlov,oStateSets) := 
  matchcontinue(dstates,states,unassignedEqns,assignedEqns,vars,varSize,eqns,eqnsSize,eqnindxlst,hov,inDummyStates,inLov,iStateSets)
      local 
        BackendDAE.Variables hov1,lov;
        list<DAE.ComponentRef> dummystates;
        Integer rang,size,unassignedEqnsSize;
        list<BackendDAE.Var> statecandidates,ovarlst,varlst;
        list<tuple<DAE.ComponentRef, Integer>> dstates1,states1;
        list<BackendDAE.Equation> eqnlst,oeqnlst;
    case(_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(listLength(dstates),eqnsSize);
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates(8):\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dstates,BackendDAETransform.dumpStates,"\n","\n")));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrIntStrIntStr, ("Select ",varSize-eqnsSize," from ",varSize,"\n"));        
        (hov1,lov,dummystates) = selectDummyStates(dstates,1,eqnsSize,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov,iStateSets); 
    case(_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        unassignedEqnsSize = listLength(unassignedEqns);
        size = listLength(states);
        rang = size-unassignedEqnsSize; 
        true = intGt(rang,0);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrIntStrIntStr, ("Select ",rang," from ",size,"\n"));   
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));     
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates(9):\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dstates,BackendDAETransform.dumpStates,"\n","\n")));
        // collect information for stateset
        statecandidates = List.map1r(List.map(states,Util.tuple22),BackendVariable.getVarAt,vars);
        eqnlst = BackendEquation.getEqns(unassignedEqns, eqns);
        ovarlst = List.map1r(List.map(dstates,Util.tuple22),BackendVariable.getVarAt,vars);
        oeqnlst = BackendEquation.getEqns(assignedEqns, eqns);
        // add dummy states
        dstates1 = listAppend(states,dstates);
        varlst = List.map1r(List.map(dstates1,Util.tuple22),BackendVariable.getVarAt,vars);
        (hov1,lov,dummystates) = selectDummyStates(dstates1,1,varSize,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov,(rang,size,unassignedEqnsSize,statecandidates,eqnlst,ovarlst,oeqnlst)::iStateSets);
    // dummy derivative case - no dynamic state selection // this case will be removed as var c_runtime works well            
   case(_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        unassignedEqnsSize = listLength(unassignedEqns);
        size = listLength(states);
        rang = size-unassignedEqnsSize;
        true = intEq(rang,0);        
        dstates1 = listAppend(states,dstates);
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates(10):\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dstates1,BackendDAETransform.dumpStates,"\n","\n")));  
        (hov1,lov,dummystates) = selectDummyStates(dstates1,1,eqnsSize,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov,iStateSets); 
  end matchcontinue;
end selectDummyDerivatives2;

protected function selectDummyDerivatives2new
"function: selectDummyDerivatives2new
  author: Frenkel TUD 2012-05
  select dummy derivatives from strong connected component"
  input list<tuple<DAE.ComponentRef, Integer>> dstates;
  input list<tuple<DAE.ComponentRef, Integer>> states;
  input list<Integer> unassignedEqns;
  input list<Integer> assignedEqns;
  input BackendDAE.Variables vars;
  input Integer varSize;
  input BackendDAE.EquationArray eqns;
  input Integer eqnsSize;
  input StateSets iStateSets;
  output list<BackendDAE.Var> outDummyVars;
  output StateSets oStateSets;
algorithm
  (outDummyVars,oStateSets) := 
  matchcontinue(dstates,states,unassignedEqns,assignedEqns,vars,varSize,eqns,eqnsSize,iStateSets)
      local
        list<BackendDAE.Var> varlst,statecandidates,ovarlst;
        list<DAE.ComponentRef> dummystates;
        Integer unassignedEqnsSize,size,rang;
        list<BackendDAE.Equation> eqnlst,oeqnlst;
    case(_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(listLength(dstates),eqnsSize);
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as States(1):\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates(1):\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dstates,BackendDAETransform.dumpStates,"\n","\n")));
      then
        ({},iStateSets); 
    case(_,_,_,_,_,_,_,_,_)
      equation
        unassignedEqnsSize = listLength(unassignedEqns);
        size = listLength(states);
        rang = size-unassignedEqnsSize; 
        true = intGt(rang,0);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrIntStrIntStr, ("Select ",rang," from ",size," States\n"));   
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));     
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates(2):\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dstates,BackendDAETransform.dumpStates,"\n","\n")));
        // collect information for stateset
        statecandidates = List.map1r(List.map(states,Util.tuple22),BackendVariable.getVarAt,vars);
        eqnlst = BackendEquation.getEqns(unassignedEqns, eqns);
        ovarlst = List.map1r(List.map(dstates,Util.tuple22),BackendVariable.getVarAt,vars);
        oeqnlst = BackendEquation.getEqns(assignedEqns, eqns);
        // add dummy states
        varlst = List.map1r(List.map(states,Util.tuple22),BackendVariable.getVarAt,vars);
      then
        (varlst,(rang,size,unassignedEqnsSize,statecandidates,eqnlst,ovarlst,oeqnlst)::iStateSets);        
   // dummy derivative case - no dynamic state selection
   case(_,_,_,_,_,_,_,_,_)
      equation
        unassignedEqnsSize = listLength(unassignedEqns);
        size = listLength(states);
        rang = size-unassignedEqnsSize;
        true = intEq(rang,0);
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates(3):\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));
        // add dummy states
        varlst = List.map1r(List.map(states,Util.tuple22),BackendVariable.getVarAt,vars);
      then
        (varlst,iStateSets); 
  end matchcontinue;
end selectDummyDerivatives2new;

protected function transformJacToMatrix
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input Integer row;
  input Integer col;
  input Integer rowsize;
  input Integer colsize;
  input list<DAE.Exp> iAcc;
  output list<DAE.Exp> oAcc;
algorithm
 oAcc := matchcontinue(jac,row,col,rowsize,colsize,iAcc)
    local
      Integer c,r;
      DAE.Exp e;
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
    case (_,_,_,_,_,_)
      equation
        true = intGt(row,rowsize);
      then
        listReverse(iAcc);
    case (_,_,_,_,_,_)
      equation
        true = intGt(col,colsize);
      then
        transformJacToMatrix(jac,row+1,1,rowsize,colsize,iAcc);
    case ({},_,_,_,_,_)
      then 
        transformJacToMatrix(jac,row,col+1,rowsize,colsize,DAE.RCONST(0.0)::iAcc);
    case ((r,c,BackendDAE.RESIDUAL_EQUATION(exp = e))::rest,_,_,_,_,_)
      equation
        true = intEq(r,row);
        true = intEq(c,col);
      then
        transformJacToMatrix(rest,row,col+1,rowsize,colsize,e::iAcc);
    case ((r,c,_)::rest,_,_,_,_,_)
      equation
        true = intGe(r,row);
      then
        transformJacToMatrix(jac,row,col+1,rowsize,colsize,DAE.RCONST(0.0)::iAcc);
   end matchcontinue;
end transformJacToMatrix;

protected function removeZeroDetStates
  input list<tuple<DAE.Exp,list<Integer>>> iDeterminants;
  input list<tuple<DAE.ComponentRef, Integer>> iStates;
  input list<tuple<DAE.ComponentRef, Integer>> iDStates;
  input list<tuple<DAE.Exp,list<Integer>>> iDetAcc;
  output list<tuple<DAE.Exp,list<Integer>>> oDeterminants;
  output list<tuple<DAE.ComponentRef, Integer>> oStates;
  output list<tuple<DAE.ComponentRef, Integer>> oDStates;
algorithm
  (oDeterminants,oStates,oDStates) := matchcontinue(iDeterminants,iStates,iDStates,iDetAcc)
    local
      DAE.Exp det;
      list<Integer> ilst;
      list<tuple<DAE.ComponentRef, Integer>> states,dstates;
      list<tuple<DAE.Exp,list<Integer>>> determinants;
      Integer s;
    case ({},_,_,_) then (listReverse(iDetAcc),iStates,iDStates);
    case ((det,ilst)::determinants,_,_,_)
      equation
        true = Expression.isZero(det);
        ((states,dstates)) = List.fold(ilst,removeZeroDetState,(iStates,iDStates));
        (determinants,states,dstates) = removeZeroDetStates(determinants,states,dstates,iDetAcc);
      then
        (determinants,states,dstates);
    case ((det,ilst)::determinants,_,_,_)
      equation
        (determinants,states,dstates) = removeZeroDetStates(determinants,iStates,iDStates,(det,ilst)::iDetAcc);
      then
        (determinants,states,dstates);
  end matchcontinue;
end removeZeroDetStates;

protected function removeZeroDetState
  input Integer index;
  input tuple<list<tuple<DAE.ComponentRef, Integer>>,list<tuple<DAE.ComponentRef, Integer>>> iTpl;
  output tuple<list<tuple<DAE.ComponentRef, Integer>>,list<tuple<DAE.ComponentRef, Integer>>> oTpl;
protected
  list<tuple<DAE.ComponentRef, Integer>> states,dstates,dstates1;
algorithm
  (states,dstates) := iTpl;
  (dstates1,states) := List.split1OnTrue(states,isStateIndex,index);
  dstates := listAppend(dstates,dstates1);
  oTpl := (states,dstates);
end removeZeroDetState;

protected function isStateIndex
  input tuple<DAE.ComponentRef, Integer> iTpl;
  input Integer index;
  output Boolean equal;
algorithm
  equal := intEq(index,Util.tuple22(iTpl));
end isStateIndex;

protected function solveOtherEquations "function solveOtherEquations
  author: Frenkel TUD 2012-10
  try to solve the equations"
  input list<Integer> assignedEqns;
  input array<Boolean> solvedeqns; 
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.Variables inVars;
  input array<Integer> ass2;
  input array<list<Integer>> iMapEqnIncRow;
  input array<Integer> iMapIncRowEqn;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendVarTransform.VariableReplacements outRepl;
algorithm
  outRepl :=
  match (assignedEqns,solvedeqns,inEqns,inVars,ass2,iMapEqnIncRow,iMapIncRowEqn,ishared,inRepl)
    local
      list<Integer> rest;
      BackendDAE.EquationArray eqns;
      Integer v,c,e;
      DAE.Exp e1,e2,varexp,expr;
      DAE.ComponentRef cr,dcr;
      DAE.ElementSource source;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.Var var;
      list<BackendDAE.Var> otherVars,varlst;
      list<Integer> clst,ds,vlst;
      list<DAE.Exp> explst1,explst2;
      BackendDAE.Equation eqn;
      list<Option<Integer>> ad;
      list<list<DAE.Subscript>> subslst;
    case ({},_,_,_,_,_,_,_,_) then inRepl;
    case (c::rest,_,_,_,_,_,_,_,_)
      equation
        e = iMapIncRowEqn[c];
        (eqn as BackendDAE.EQUATION(exp=e1,scalar=e2,source=source)) = BackendDAEUtil.equationNth(inEqns, e-1);
        v = ass2[c];
        _ = arrayUpdate(solvedeqns,c,true);
        (var as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(inVars, v);
        varexp = Expression.crefExp(cr);
        varexp = Debug.bcallret1(BackendVariable.isStateVar(var), Expression.expDer, varexp, varexp);
        (e1,_) = BackendVarTransform.replaceExp(e1,inRepl,SOME(BackendVarTransform.skipPreOperator));
        (e2,_) = BackendVarTransform.replaceExp(e2,inRepl,SOME(BackendVarTransform.skipPreOperator));
        (expr,{}) = ExpressionSolve.solve(e1, e2, varexp);
        dcr = Debug.bcallret1(BackendVariable.isStateVar(var), ComponentReference.crefPrefixDer, cr, cr);
        repl = BackendVarTransform.addReplacement(inRepl,dcr,expr,SOME(BackendVarTransform.skipPreOperator));
        repl = Debug.bcallret3(BackendVariable.isStateVar(var), BackendVarTransform.addDerConstRepl, cr, expr, repl, repl);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrCrefStrExpStr,("",dcr," := ",expr,"\n"));
      then
        solveOtherEquations(rest,solvedeqns,inEqns,inVars,ass2,iMapEqnIncRow,iMapIncRowEqn,ishared,repl);
    case (c::rest,_,_,_,_,_,_,_,_)
      equation
        e = iMapIncRowEqn[c];       
        (eqn as BackendDAE.ARRAY_EQUATION(dimSize=ds,left=e1,right=e2,source=source)) = BackendDAEUtil.equationNth(inEqns, e-1);
        clst = iMapEqnIncRow[e];
        vlst = List.map1r(clst,arrayGet,ass2);
        varlst = List.map1r(vlst,BackendVariable.getVarAt,inVars);
        ad = List.map(ds,Util.makeOption);
        subslst = BackendDAEUtil.arrayDimensionsToRange(ad);
        subslst = BackendDAEUtil.rangesToSubscripts(subslst);
        explst1 = List.map1r(subslst,Expression.applyExpSubscripts,e1);
        explst1 = ExpressionSimplify.simplifyList(explst1, {});
        explst2 = List.map1r(subslst,Expression.applyExpSubscripts,e2);
        explst2 = ExpressionSimplify.simplifyList(explst2, {});
        repl = solveOtherEquations1(explst1,explst2,varlst,inVars,ishared,inRepl);
      then
        solveOtherEquations(rest,solvedeqns,inEqns,inVars,ass2,iMapEqnIncRow,iMapIncRowEqn,ishared,repl);

  end match;
end solveOtherEquations;

protected function solveOtherEquations1 "function solveOtherEquations
  author: Frenkel TUD 2011-05
  try to solve the equations"
  input list<DAE.Exp> iExps1;
  input list<DAE.Exp> iExps2;
  input list<BackendDAE.Var> iVars;
  input BackendDAE.Variables inVars;
  input BackendDAE.Shared ishared;  
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendVarTransform.VariableReplacements outRepl;
algorithm
  outRepl :=
  match (iExps1,iExps2,iVars,inVars,ishared,inRepl)
    local
      DAE.Exp e1,e2,varexp,expr;
      DAE.ComponentRef cr,dcr;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.Var var;
      list<BackendDAE.Var> otherVars,rest;
      list<DAE.Exp> explst1,explst2;
    case ({},_,_,_,_,_) then inRepl;
    case (e1::explst1,e2::explst2,(var as BackendDAE.VAR(varName=cr))::rest,_,_,_)
      equation
        varexp = Expression.crefExp(cr);
        varexp = Debug.bcallret1(BackendVariable.isStateVar(var), Expression.expDer, varexp, varexp);
        (e1,_) = BackendVarTransform.replaceExp(e1,inRepl,SOME(BackendVarTransform.skipPreOperator));
        (e2,_) = BackendVarTransform.replaceExp(e2,inRepl,SOME(BackendVarTransform.skipPreOperator));
        (expr,{}) = ExpressionSolve.solve(e1, e2, varexp);
        dcr = Debug.bcallret1(BackendVariable.isStateVar(var), ComponentReference.crefPrefixDer, cr, cr);
        repl = BackendVarTransform.addReplacement(inRepl,dcr,expr,SOME(BackendVarTransform.skipPreOperator));
        repl = Debug.bcallret3(BackendVariable.isStateVar(var), BackendVarTransform.addDerConstRepl, cr, expr, repl, repl);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrCrefStrExpStr,("",dcr," := ",expr,"\n"));
      then
        solveOtherEquations1(explst1,explst2,rest,inVars,ishared,repl);
  end match;
end solveOtherEquations1;



protected function generateSetTerms
  input list<DAE.ComponentRef> crlst;
  input DAE.Exp iExp;
  input DAE.ComponentRef precr;
  input BackendVarTransform.VariableReplacements iRepl;
  input list<DAE.Exp> iSetTerms;
  output list<DAE.Exp> oSetTerms;
algorithm
  oSetTerms := match(crlst,iExp,precr,iRepl,iSetTerms)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> rest;
      DAE.Exp exp;
      BackendVarTransform.VariableReplacements repl;
    case({},_,_,_,_) then iSetTerms;
    case(cr::rest,_,_,_,_)
      equation
        repl = BackendVarTransform.addReplacement(iRepl, precr, Expression.crefExp(cr), NONE());
        (exp,true) = BackendVarTransform.replaceExp(iExp,repl,NONE());
      then
        generateSetTerms(rest,exp,cr,repl,exp::iSetTerms);
  end match;
end generateSetTerms;

protected function splitTermsStateNoStates
  input list<DAE.Exp> iTerms;
  input BackendDAE.Variables vars;
  input HashTable2.HashTable iHt;
  input list<DAE.Exp> iAcc;
  output list<DAE.Exp> oStateTerms;
  output list<DAE.Exp> oOtherTerms;
algorithm
  (oStateTerms,oOtherTerms) := matchcontinue(iTerms,vars,iHt,iAcc)
    local
      DAE.Exp term;
      list<DAE.Exp> rest,stlst,otlst;
      HashTable2.HashTable ht;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
    case({},_,_,_)
      equation
        rest = BaseHashTable.hashTableValueList(iHt);
      then
        (rest,iAcc);
    case(term::rest,_,_,_)
      equation
        var::{} = BackendEquation.expressionVars(term,vars);
        cr = BackendVariable.varCref(var);
        failure( _ = BaseHashTable.get(cr, iHt));
        ht = BaseHashTable.add((cr,term),iHt);
        (stlst,otlst) = splitTermsStateNoStates(rest,vars,ht,iAcc);
      then
        (stlst,otlst);
    case(term::rest,_,_,_)
      equation
        {} = BackendEquation.expressionVars(term,vars);
        (stlst,otlst) = splitTermsStateNoStates(rest,vars,iHt,term::iAcc);
      then
        (stlst,otlst);        
  end matchcontinue;
end splitTermsStateNoStates;


protected function hackSelect
  input list<tuple<DAE.ComponentRef, Integer>> states;
  output Integer startvalue;
algorithm
  startvalue := matchcontinue(states)
    local
      DAE.ComponentRef cr;
      Integer i;
      list<tuple<DAE.ComponentRef, Integer>> rest;
    case({})
      then
        3;
    case((cr,i)::rest)
      equation
        true = intEq(i,11);
      then
        3;
    case((cr,i)::rest)
      equation
        true = intEq(i,16);
      then
        2;        
    case((cr,i)::rest)
      then
        hackSelect(rest);
  end matchcontinue;
end hackSelect;

protected function dumpDeterminants
"function: dumpDeterminants
  author: Frenkel TUD 2012-08"
  input tuple<DAE.Exp,list<Integer>> iTpl;
  output String s;
algorithm
  s := "Determinant: " +& stringDelimitList(List.map(Util.tuple22(iTpl),intString),", ") +& " \n" +& ExpressionDump.printExpStr(Util.tuple21(iTpl)) +& "\n";
end dumpDeterminants;

protected function setSelectArray
"function: setSelectArray
  author: Frenkel TUD 2012-08"
  input list<tuple<DAE.ComponentRef, Integer>> dstates;
  input array<Integer> iSelect;
  input Integer i;
  output Integer size;
algorithm
  size := match(dstates,iSelect,i)
    local
      Integer j;
      list<tuple<DAE.ComponentRef, Integer>> rest;
    case ({},_,_) then i;
    case ((_,j)::rest,_,_)
      equation
        _ = arrayUpdate(iSelect,j,i);
      then
       setSelectArray(rest,iSelect,i+1);
  end match;   
end setSelectArray;

protected function unsetSelectArray
"function: unsetSelectArray
  author: Frenkel TUD 2012-08"
  input list<tuple<DAE.ComponentRef, Integer>> dstates;
  input array<Integer> iSelect;
  output array<Integer> oSelect;
algorithm
  oSelect := match(dstates,iSelect)
    local
      Integer j;
      list<tuple<DAE.ComponentRef, Integer>> rest;
    case ({},_) then iSelect;
    case ((_,j)::rest,_)
      equation
        _ = arrayUpdate(iSelect,j,-1);
      then
       unsetSelectArray(rest,iSelect);
  end match;   
end unsetSelectArray;

protected function getDeterminants
"function: getDeterminants
  author: Frenkel TUD 2012-08"
  input list<tuple<DAE.ComponentRef, Integer>> states;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input Integer unassigned;
  input Integer size;
  input list<list<tuple<Integer,DAE.Exp>>> digraphLst;
  input array<Integer> select;
  input list<Integer> unusedStates;
  input list<tuple<DAE.Exp,list<Integer>>> iAcc;
  output list<tuple<DAE.Exp,list<Integer>>> oAcc;
algorithm
  oAcc := matchcontinue(states,jac,unassigned,size,digraphLst,select,unusedStates,iAcc)
    local
      DAE.ComponentRef cr;
      Integer i;
      list<tuple<DAE.ComponentRef, Integer>> rest;
      list<tuple<DAE.Exp,list<Integer>>> acc;
      array<list<tuple<Integer,DAE.Exp>>> digraph;
      list<tuple<list<DAE.Exp>,Integer>> zycles;
      DAE.Exp det;
      list<Integer> unused;
    case ({},_,_,_,_,_,_,_) then iAcc;
    case ((cr,i)::rest,_,0,_,_,_,_,_)
      equation
        // BackendDump.debugStrCrefStrIntStr(("getDeterminants(1) ",cr,"  ",i,"\n"));
        // print("Calculate Determinant " +& intString(size) +& "\n");
        _ = arrayUpdate(select,i,size);
        digraph = getDeterminantDigraphSelect(jac,listArray(digraphLst),select);
        // print("\n");
        // dumpDigraph(digraph);
        // print("Start Determinanten calculation with 1. Node\n");
        zycles = determinantEdges(digraph[1],size,1,{1},{},1,1,digraph,{});
        //  dumpzycles(zycles,size);
        det = determinantfromZycles(zycles,size,DAE.RCONST(0.0));
        unused = listAppend(unusedStates,List.map(rest,Util.tuple22));
        // print(dumpDeterminants((det,unused)));  
        _ = arrayUpdate(select,i,-1);
      then
       (det,unused)::iAcc;
    case ((cr,i)::rest,_,_,_,_,_,_,_)
      equation
        true = intGt(unassigned,0);
        // BackendDump.debugStrCrefStrIntStr(("getDeterminants(2) ",cr,"  ",i,"\n"));
        true = intGe(listLength(rest),unassigned);
        _ = arrayUpdate(select,i,size);
        acc = getDeterminants1(rest,jac,unassigned-1,size+1,digraphLst,select,unusedStates,iAcc);
        _ = arrayUpdate(select,i,-1);
      then
        acc;
       //getDeterminants(rest,jac,unassigned,size,digraphLst,select,i::unusedStates,acc);
    case ((cr,i)::rest,_,_,_,_,_,_,_)
      equation
        false = intGe(listLength(rest),unassigned);
      then
       iAcc;
    case (_,_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"IndexReduction.getDeterminants failed!"});
      then
       fail();
  end matchcontinue;        
end getDeterminants;

protected function getDeterminants1
"function: getDeterminants1
  author: Frenkel TUD 2012-08"
  input list<tuple<DAE.ComponentRef, Integer>> states;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input Integer unassigned;
  input Integer size;
  input list<list<tuple<Integer,DAE.Exp>>> digraphLst;
  input array<Integer> select;
  input list<Integer> unusedStates;
  input list<tuple<DAE.Exp,list<Integer>>> iAcc;
  output list<tuple<DAE.Exp,list<Integer>>> oAcc;
algorithm
  oAcc := match(states,jac,unassigned,size,digraphLst,select,unusedStates,iAcc)
    local
      DAE.ComponentRef cr;
      Integer i;
      list<tuple<DAE.ComponentRef, Integer>> rest;
      list<tuple<DAE.Exp,list<Integer>>> acc;
    case ({},_,_,_,_,_,_,_) then iAcc;
    case ((cr,i)::rest,_,_,_,_,_,_,_)
      equation
        // BackendDump.debugStrCrefStrIntStr(("getDeterminants1 ",cr,"  ",i,"\n"));
        acc = getDeterminants(states,jac,unassigned,size,digraphLst,select,unusedStates,iAcc);
      then
       getDeterminants1(rest,jac,unassigned,size,digraphLst,select,i::unusedStates,acc);
  end match;        
end getDeterminants1;

protected function getDeterminantDigraphSelect
"function: getDeterminantDigraphSelect
  author: Frenkel TUD 2012-08"
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input array<list<tuple<Integer,DAE.Exp>>> iDigraph;
  input array<Integer> select;
  output array<list<tuple<Integer,DAE.Exp>>> oDigraph;
algorithm
  oDigraph := matchcontinue(jac,iDigraph,select)
    local
      Integer i,j,k;
      DAE.Exp e;
      list<tuple<Integer,DAE.Exp>> ilst;
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
      array<list<tuple<Integer,DAE.Exp>>> digraph;
    case({},_,_) then iDigraph;
    case((i,j,BackendDAE.RESIDUAL_EQUATION(exp = e))::rest,_,_)
      equation
        k = select[j];
        true = intGt(k,0);
        ilst = iDigraph[k];
        digraph = arrayUpdate(iDigraph,k,(i,e)::ilst);
      //print(intString(j) +& ", ");        
      then
        getDeterminantDigraphSelect(rest,digraph,select);
    case(_::rest,_,_)
      then
        getDeterminantDigraphSelect(rest,iDigraph,select);        
  end matchcontinue;
end getDeterminantDigraphSelect;

protected function generateSetExpressions
"function: generateSetExpressions
  author: Frenkel TUD 2012-08"
  input list<DAE.Exp> expLst;
  input Integer index;
  input DAE.Exp crconexppre;
  output DAE.Exp ifexp;
algorithm
  ifexp := match(expLst,index,crconexppre)
    local
      DAE.Exp e,con,e1;
      list<DAE.Exp> rest;
    case (e::{},_,_) then e;
    case (e::rest,_,_)
      equation
        e1 = generateSetExpressions(rest,index-1,crconexppre);
        con = DAE.RELATION(crconexppre,DAE.EQUAL(DAE.T_INTEGER_DEFAULT),DAE.ICONST(index),-1,NONE());
      then
        DAE.IFEXP(con,e,e1);
  end match;
end generateSetExpressions;

protected function generateStartExpressions
"function: generateStartExpressions
  author: Frenkel TUD 2012-08"
  input list<list<DAE.Exp>> istartvalues;
  input Integer index;
  input DAE.Exp contstartExp;
  output list<DAE.Exp> startvalues;
algorithm
  startvalues := match(istartvalues,index,contstartExp)
    local
      DAE.Exp startcond;
      list<DAE.Exp> explst,explst1;
      list<list<DAE.Exp>> rest;
    case (explst::{},_,_) then explst;
    case (explst::rest,_,_)
      equation
        explst1 = generateStartExpressions(rest,index-1,contstartExp);
      then
        generateStartExpressions1(explst,explst1,index,contstartExp,{});
  end match;
end generateStartExpressions;

protected function generateStartExpressions1
"function: generateStartExpressions1
  author: Frenkel TUD 2012-08"
  input list<DAE.Exp> es1;
  input list<DAE.Exp> es2;
  input Integer index;
  input DAE.Exp contstartExp;
  input list<DAE.Exp> istartvalues;
  output list<DAE.Exp> startvalues;
algorithm
  startvalues := match(es1,es2,index,contstartExp,istartvalues)
    local
      DAE.Exp startcond,e1,e2;
      list<DAE.Exp> rest1,rest2;
    case ({},{},_,_,_) then listReverse(istartvalues);
    case (e1::rest1,e2::rest2,_,_,_)
      equation
        startcond = DAE.IFEXP(DAE.RELATION(contstartExp,DAE.EQUAL(DAE.T_INTEGER_DEFAULT),DAE.ICONST(index),-1,NONE()),e1,e2); 
      then
       generateStartExpressions1(rest1,rest2,index-1,contstartExp,startcond::istartvalues);
  end match;
end generateStartExpressions1;

protected function setVarLstStartValue
"function: setVarLstStartValue
  author: Frenkel TUD 2012-08"
  input list<BackendDAE.Var> isetvarlst;
  input list<DAE.Exp> istartvalues;
  input list<BackendDAE.Var> iAcc;
  output list<BackendDAE.Var> osetvarlst;
algorithm
  osetvarlst := match(isetvarlst,istartvalues,iAcc)
    local
      BackendDAE.Var var;
      DAE.Exp e;
      list<BackendDAE.Var> rest;
      list<DAE.Exp> explst;
    case({},_,_) then iAcc;
    case(var::rest,e::explst,_)
      equation
        (e,_) = ExpressionSimplify.simplify(e);
        var = BackendVariable.setVarStartValue(var,e);
      then
        setVarLstStartValue(rest,explst,var::iAcc);
  end match;
end setVarLstStartValue;

protected function generateSelectEquationsMulti
"function: generateSelectEquationsMulti
  author: Frenkel TUD 2012-08"
  input list<tuple<DAE.Exp,list<Integer>>> determinants;
  input Integer index;
  input DAE.ComponentRef crset;
  input DAE.Exp crsetexp;
  input DAE.Exp contexp;
  input DAE.Exp contstartExp;
  input BackendDAE.Variables vars;
  input Integer rang;
  input list<DAE.Exp> ifexplst;
  input list<DAE.Exp> ifdexplst;
  input list<BackendDAE.WhenClause> iWc;
  input list<BackendDAE.Var> isetvarlst;
  input list<list<DAE.Exp>> istartvalues;
  output list<BackendDAE.Equation> oEqns;
  output list<BackendDAE.Equation> odEqns;
  output list<BackendDAE.WhenClause> oWc;
  output list<BackendDAE.Var> osetvarlst;
algorithm
  (oEqns,odEqns,oWc,osetvarlst) := 
  match(determinants,index,crset,crsetexp,contexp,contstartExp,vars,rang,ifexplst,ifdexplst,iWc,isetvarlst,istartvalues)
    local
      DAE.ComponentRef cr;
      list<Integer> ilst;
      list<tuple<DAE.Exp,list<Integer>>> rest;
      list<BackendDAE.Equation> eqns,deqns;
      BackendDAE.Equation eqn,deqn;
      DAE.Exp e1,e2,con,coni,crconexppre,es1,es2,startcond;
      list<DAE.ComponentRef> crlst;
      list<DAE.Exp> explst,startvalues;
      BackendDAE.WhenClause wc,wc1;
      list<BackendDAE.WhenClause> wclst;
      list<BackendDAE.Var> varlst,varlst1;
      BackendDAE.Var var;
      DAE.Type tp;
    case({},_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        crconexppre = DAE.CALL(Absyn.IDENT("pre"), {contexp}, DAE.callAttrBuiltinReal);
        e1 = generateSetExpressions(ifexplst,index-1,crconexppre);
        e2 = generateSetExpressions(ifdexplst,index-1,crconexppre);
        eqn = Util.if_(intGt(rang,1),BackendDAE.ARRAY_EQUATION({rang},crsetexp,e1,DAE.emptyElementSource,false),BackendDAE.EQUATION(crsetexp,e1,DAE.emptyElementSource,false));
        tp = Expression.typeof(crsetexp);
        deqn = Util.if_(intGt(rang,1),BackendDAE.ARRAY_EQUATION({rang},DAE.CALL(Absyn.IDENT("der"),{crsetexp},DAE.CALL_ATTR(tp,false,true,DAE.NO_INLINE(),DAE.NO_TAIL())),e2,DAE.emptyElementSource,false),BackendDAE.EQUATION(DAE.CALL(Absyn.IDENT("der"),{crsetexp},DAE.callAttrBuiltinReal),e2,DAE.emptyElementSource,false));
        startvalues = generateStartExpressions(istartvalues,index-1,contstartExp);
        varlst = setVarLstStartValue(isetvarlst,startvalues,{});
      then 
        ({eqn},{deqn},iWc,varlst);        
    case((_,ilst)::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        varlst = List.map1r(ilst,BackendVariable.getVarAt,vars);
        crlst = List.map(varlst,BackendVariable.varCref);
        explst = List.map(crlst,Expression.crefExp);
        e2 = listGet(explst,1);
        e1 = Debug.bcallret2(intGt(rang,1), Expression.makeScalarArray, explst, DAE.T_REAL_DEFAULT, e2);
        explst = List.map(explst,makeder);
        e2 = Debug.bcallret2(intGt(rang,1), Expression.makeScalarArray, explst, DAE.T_REAL_DEFAULT, DAE.CALL(Absyn.IDENT("der"),{e2},DAE.callAttrBuiltinReal));
        con = DAE.RELATION(contexp,DAE.EQUAL(DAE.T_INTEGER_DEFAULT),DAE.ICONST(index),-1,NONE());
        wc = BackendDAE.WHEN_CLAUSE(con,{BackendDAE.REINIT(crset,e1,DAE.emptyElementSource)},NONE());
        startvalues = List.map(varlst,BackendVariable.varStartValue);
        (eqns,deqns,wclst,varlst1) = generateSelectEquationsMulti(rest,index+1,crset,crsetexp,contexp,contstartExp,vars,rang,e1::ifexplst,e2::ifdexplst,wc::iWc,isetvarlst,startvalues::istartvalues);
      then
        (eqns,deqns,wclst,varlst1);
  end match;
end generateSelectEquationsMulti;

protected function makeder
"function makeder
Author: Frenkel TUD 2012-09"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
protected
  DAE.Type tp;
algorithm
  tp := Expression.typeof(inExp);
  outExp := DAE.CALL(Absyn.IDENT("der"),{inExp},DAE.CALL_ATTR(tp,false,true,DAE.NO_INLINE(),DAE.NO_TAIL()));
end makeder;

protected function changeVarToStartValue "
function changeVarToStartValue
Author: Frenkel TUD 2012-06
  replace the variable with there start value"
  input tuple<DAE.Exp, BackendDAE.Variables > inExp;
  output tuple<DAE.Exp, BackendDAE.Variables > outExp;
algorithm 
  outExp := matchcontinue(inExp)
    local
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      BackendDAE.Var var;
      DAE.Exp e,es;
    
    case((e as DAE.CREF(componentRef=cr),vars))
      equation
        (var::_,_) = BackendVariable.getVar(cr, vars);
        es = BackendVariable.varStartValue(var);
      then
        ((es, vars ));
    
    else then inExp;
    
  end matchcontinue;
end changeVarToStartValue;

protected function generateSelectEquations
"function: generateSelectEquations
  author: Frenkel TUD 2012-08"
  input Integer indx;
  input list<DAE.ComponentRef> crset;
  input DAE.Exp contexp;
  input list<DAE.Exp> states;
  input DAE.Exp contstartExp;
  input list<BackendDAE.Var> ivarlst;
  input list<DAE.Exp> istartvalues;
  input list<BackendDAE.Equation> iEqns;
  input list<BackendDAE.Equation> idEqns;
  input list<BackendDAE.WhenClause> iWc;
  input list<BackendDAE.Var> isetvarlst;
  output list<BackendDAE.Equation> oEqns;
  output list<BackendDAE.Equation> odEqns;
  output list<BackendDAE.WhenClause> oWc;
  output list<BackendDAE.Var> osetvarlst;
algorithm
  (oEqns,odEqns,oWc,osetvarlst) := match(indx,crset,contexp,states,contstartExp,ivarlst,istartvalues,iEqns,idEqns,iWc,isetvarlst)
    local
      list<BackendDAE.Equation> eqns,deqns;
      BackendDAE.Equation eqn,deqn;
      DAE.Exp cre,e1,e2,con,coni,crconexppre,es1,es2,startcond;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      list<DAE.Exp> explst,startvalues;
      BackendDAE.WhenClause wc,wc1;
      list<BackendDAE.WhenClause> wclst;
      list<BackendDAE.Var> varlst,varlst1;
      BackendDAE.Var var;
    case(_,{},_,_,_,_,_,_,_,_,_) then (listReverse(iEqns),listReverse(idEqns),listReverse(iWc),listReverse(isetvarlst));        
    case(_,cr::crlst,_,e1::(e2::explst),_,var::varlst,es1::(es2::startvalues),_,_,_,_)
      equation
        cre = Expression.crefExp(cr);
        crconexppre = DAE.CALL(Absyn.IDENT("pre"), {contexp}, DAE.callAttrBuiltinReal);
        con = DAE.RELATION(crconexppre,DAE.GREATER(DAE.T_INTEGER_DEFAULT),DAE.ICONST(indx),-1,NONE());
        //coni = DAE.LBINARY(DAE.CALL(Absyn.IDENT("initial"),{},DAE.callAttrBuiltinBool),DAE.OR(DAE.T_BOOL_DEFAULT),con);
        //eqn = BackendDAE.EQUATION(cre,DAE.IFEXP(coni,e1,e2),DAE.emptyElementSource);
        eqn = BackendDAE.EQUATION(cre,DAE.IFEXP(con,e1,e2),DAE.emptyElementSource,false);
        //deqn = BackendDAE.EQUATION(DAE.CALL(Absyn.IDENT("der"),{cre},DAE.callAttrBuiltinReal),DAE.IFEXP(coni,DAE.CALL(Absyn.IDENT("der"),{e1},DAE.callAttrBuiltinReal),DAE.CALL(Absyn.IDENT("der"),{e2},DAE.callAttrBuiltinReal)),DAE.emptyElementSource);
        deqn = BackendDAE.EQUATION(DAE.CALL(Absyn.IDENT("der"),{cre},DAE.callAttrBuiltinReal),DAE.IFEXP(con,DAE.CALL(Absyn.IDENT("der"),{e1},DAE.callAttrBuiltinReal),DAE.CALL(Absyn.IDENT("der"),{e2},DAE.callAttrBuiltinReal)),DAE.emptyElementSource,false);
        con = DAE.RELATION(contexp,DAE.GREATER(DAE.T_INTEGER_DEFAULT),DAE.ICONST(indx),-1,NONE());
        wc = BackendDAE.WHEN_CLAUSE(con,{BackendDAE.REINIT(cr,e1,DAE.emptyElementSource)},NONE());
        wc1 = BackendDAE.WHEN_CLAUSE(DAE.LUNARY(DAE.NOT(DAE.T_BOOL_DEFAULT),con),{BackendDAE.REINIT(cr,e2,DAE.emptyElementSource)},NONE());
        (startcond,_) = ExpressionSimplify.simplify(DAE.IFEXP(DAE.RELATION(contstartExp,DAE.GREATER(DAE.T_INTEGER_DEFAULT),DAE.ICONST(indx),-1,NONE()),es1,es2));
        var = BackendVariable.setVarStartValue(var,startcond);
        (eqns,deqns,wclst,varlst1) = generateSelectEquations(indx+1,crlst,contexp,e2::explst,contstartExp,varlst,es2::startvalues,eqn::iEqns,deqn::idEqns,wc1::(wc::iWc),var::isetvarlst);
      then
        (eqns,deqns,wclst,varlst1);
  end match;
end generateSelectEquations;

protected function generateCondition
"function: generateCondition
  author: Frenkel TUD 2012-08"
  input Integer indx;
  input Integer size;
  input array<DAE.Exp> inExps;
  output DAE.Exp outCont; 
algorithm
  outCont:= matchcontinue(indx,size,inExps)
    local
      Integer p;
      DAE.Exp expCond,expThen,expElse,e1,e2;
    case(_,_,_)
      equation
        p = indx + 1;
        true = intLt(p,size);
        e1 = inExps[1];
        e2 = inExps[p];        
        expCond = DAE.RELATION(DAE.CALL(Absyn.IDENT("abs"),{e1},DAE.callAttrBuiltinReal),DAE.LESS(DAE.T_REAL_DEFAULT),DAE.CALL(Absyn.IDENT("abs"),{e2},DAE.callAttrBuiltinReal),0,NONE());
        //expCond = DAE.CALL(Absyn.IDENT("noEvent"),{expCond},DAE.callAttrBuiltinBool);
        expThen = generateCondition1(p,p+1,size,inExps);
        expElse = generateCondition(p,size,inExps);
      then
        DAE.IFEXP(expCond, expThen, expElse);  
   else
     equation
       p = indx + 1;
       e1 = inExps[1];
       e2 = inExps[p];       
       expCond = DAE.RELATION(DAE.CALL(Absyn.IDENT("abs"),{e1},DAE.callAttrBuiltinReal),DAE.LESS(DAE.T_REAL_DEFAULT),DAE.CALL(Absyn.IDENT("abs"),{e2},DAE.callAttrBuiltinReal),0,NONE());
       //expCond = DAE.CALL(Absyn.IDENT("noEvent"),{expCond},DAE.callAttrBuiltinBool);
     then
       DAE.IFEXP(expCond, DAE.ICONST(p), DAE.ICONST(1));
                
  end matchcontinue;
end generateCondition;

protected function generateCondition1
"function: generateCondition1
  author: Frenkel TUD 2012-08"
  input Integer p1;
  input Integer p2;
  input Integer size;
  input array<DAE.Exp> inExps;
  output DAE.Exp outCont; 
algorithm
  outCont:= matchcontinue(p1,p2,size,inExps)
    local
      DAE.Exp expCond,expThen,expElse,e1,e2;
    case(_,_,_,_)
      equation
        true = intLt(p2,size);
        e1 = inExps[p1];
        e2 = inExps[p2];
        expCond = DAE.RELATION(DAE.CALL(Absyn.IDENT("abs"),{e1},DAE.callAttrBuiltinReal),DAE.LESS(DAE.T_REAL_DEFAULT),DAE.CALL(Absyn.IDENT("abs"),{e2},DAE.callAttrBuiltinReal),0,NONE());
        //expCond = DAE.CALL(Absyn.IDENT("noEvent"),{expCond},DAE.callAttrBuiltinBool);
        expThen = generateCondition2(p2,p2+1,size,inExps);
        expElse = generateCondition1(p1,p2+1,size,inExps);
      then
        DAE.IFEXP(expCond, expThen, expElse);
    case(_,_,_,_)
      equation
        false = intLt(p2,size);
        e1 = inExps[p1];
        e2 = inExps[p2];
        expCond = DAE.RELATION(DAE.CALL(Absyn.IDENT("abs"),{e1},DAE.callAttrBuiltinReal),DAE.LESS(DAE.T_REAL_DEFAULT),DAE.CALL(Absyn.IDENT("abs"),{e2},DAE.callAttrBuiltinReal),0,NONE());
        //expCond = DAE.CALL(Absyn.IDENT("noEvent"),{expCond},DAE.callAttrBuiltinBool);
      then
        DAE.IFEXP(expCond, DAE.ICONST(p2), DAE.ICONST(p1));        
  end matchcontinue;
end generateCondition1;

protected function generateCondition2
"function: generateCondition2
  author: Frenkel TUD 2012-08"
  input Integer p1;
  input Integer p2;
  input Integer size;
  input array<DAE.Exp> inExps;
  output DAE.Exp outCont; 
algorithm
  outCont:= matchcontinue(p1,p2,size,inExps)
    local
      DAE.Exp expCond,expThen,e1,e2;
    case(_,_,_,_)
      equation
        true = intLt(p2,size);
        e1 = inExps[p1];
        e2 = inExps[p2];
        expCond = DAE.RELATION(DAE.CALL(Absyn.IDENT("abs"),{e1},DAE.callAttrBuiltinReal),DAE.LESS(DAE.T_REAL_DEFAULT),DAE.CALL(Absyn.IDENT("abs"),{e2},DAE.callAttrBuiltinReal),0,NONE());
        //expCond = DAE.CALL(Absyn.IDENT("noEvent"),{expCond},DAE.callAttrBuiltinBool);
        expThen = generateCondition2(p2,p2+1,size,inExps);
      then
        DAE.IFEXP(expCond, expThen, DAE.ICONST(0));
    case(_,_,_,_)
      equation
        false = intLt(p2,size);
        e1 = inExps[p1];
        e2 = inExps[p2];
        expCond = DAE.RELATION(DAE.CALL(Absyn.IDENT("abs"),{e1},DAE.callAttrBuiltinReal),DAE.LESS(DAE.T_REAL_DEFAULT),DAE.CALL(Absyn.IDENT("abs"),{e2},DAE.callAttrBuiltinReal),0,NONE());
        //expCond = DAE.CALL(Absyn.IDENT("noEvent"),{expCond},DAE.callAttrBuiltinBool);
      then
        DAE.IFEXP(expCond, DAE.ICONST(p2), DAE.ICONST(p1));        
  end matchcontinue;
end generateCondition2;

protected function differentiateExp
"function: differentiateExp
  author: Frenkel TUD 2012-08"
  input DAE.ComponentRef cr;
  input DAE.Exp exp;
  input DAE.FunctionTree ft;
  output DAE.Exp dexp;
algorithm
  dexp := Derive.differentiateExp(exp, cr, true, SOME(ft));
  (dexp,_) := ExpressionSimplify.simplify(dexp);
end differentiateExp;

protected function generateVar
"function: generateVar
  author: Frenkel TUD 2012-08"
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
"function: generateArrayVar
  author: Frenkel TUD 2012-08"
  input DAE.ComponentRef name;
  input BackendDAE.VarKind varKind;
  input DAE.Type varType;
  input Option<DAE.VariableAttributes> attr;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := match(name,varKind,varType,attr)
    local
      DAE.ComponentRef cr;
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
"function: getStateSetNames
  author: Frenkel TUD 2012-08"
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
          vars = List.map4(crlst1,generateVar,BackendDAE.STATE(),DAE.T_REAL_DEFAULT,{},NONE());
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
          vars = List.map4(crlst1,generateVar,BackendDAE.STATE(),DAE.T_REAL_DEFAULT,{},NONE());
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

protected function setStartValue
"function: stateVar
  author: Frenkel TUD 2012-06
  fails if var is not a state"
  input BackendDAE.Var iv;
  input list<BackendDAE.Var> ivarlst;
  output BackendDAE.Var ov;
  output list<BackendDAE.Var> ovarlst;
protected
  BackendDAE.Var v1;
algorithm
  v1::ovarlst := ivarlst;
  ov := BackendVariable.setVarStartValue(iv,BackendVariable.varStartValue(v1));
end setStartValue;

protected function stateVar
"function: stateVar
  author: Frenkel TUD 2012-06
  fails if var is not a state"
  input BackendDAE.Var v;
algorithm
  true := BackendVariable.isStateVar(v);
end stateVar;

protected function notVarStateSelectAlways
"function: notVarStateSelectAlways
  author: Frenkel TUD 2012-06
  fails if var is StateSelect.always"
  input BackendDAE.Var v;
algorithm
  false := varStateSelectAlways(v);
end notVarStateSelectAlways;

protected function varStateSelectAlways
"function: varStateSelectAlways
  author: Frenkel TUD 2012-06
  return true if var is StateSelect.always else false"
  input BackendDAE.Var v;
  output Boolean b;
algorithm
  b := match(v)
    case BackendDAE.VAR(varKind=BackendDAE.STATE(),values = SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.ALWAYS())))) then true;
    else then false;
  end match;        
end varStateSelectAlways;

protected function incidenceMatrixfromEnhanced
"function: incidenceMatrixfromEnhanced
  author: Frenkel TUD 2012-05
  converts an AdjacencyMatrixEnhanced into a IncidenceMatrix"
  input BackendDAE.AdjacencyMatrixEnhanced me;
  output BackendDAE.IncidenceMatrix m;
algorithm
  m := Util.arrayMap(me,incidenceMatrixElementfromEnhanced);
end incidenceMatrixfromEnhanced;

protected function incidenceMatrixElementfromEnhanced
"function: incidenceMatrixElementfromEnhanced
  author: Frenkel TUD 2012-05
  helper for incidenceMatrixfromEnhanced"
  input BackendDAE.AdjacencyMatrixElementEnhanced iRow;
  output BackendDAE.IncidenceMatrixElement oRow;
algorithm
//  oRow := List.map(List.sort(iRow,AdjacencyMatrixElementEnhancedCMP), incidenceMatrixElementElementfromEnhanced);
  oRow := List.fold(iRow, incidenceMatrixElementElementfromEnhanced, {});
  oRow := listReverse(oRow);
end incidenceMatrixElementfromEnhanced;

protected function AdjacencyMatrixElementEnhancedCMP
"function: AdjacencyMatrixElementEnhancedCMP
  author: Frenkel TUD 2012-05
  helper for incidenceMatrixElementfromEnhanced"
  input tuple<Integer, BackendDAE.Solvability> inTplA;
  input tuple<Integer, BackendDAE.Solvability> inTplB;
  output Boolean b;
algorithm
  b := BackendDAEUtil.solvabilityCMP(Util.tuple22(inTplA),Util.tuple22(inTplB));
end AdjacencyMatrixElementEnhancedCMP;

protected function incidenceMatrixElementElementfromEnhanced
"function: incidenceMatrixElementElementfromEnhanced
  author: Frenkel TUD 2012-05
  converts an AdjacencyMatrix entry into a IncidenceMatrix entry"
  input tuple<Integer, BackendDAE.Solvability> inTpl;
  input list<Integer> iRow;
  output list<Integer> oRow;
algorithm
  oRow := match(inTpl,iRow)
    local Integer i;
    case ((i,BackendDAE.SOLVABILITY_SOLVED()),_) then i::iRow;
    case ((i,BackendDAE.SOLVABILITY_CONSTONE()),_) then i::iRow;
    case ((i,BackendDAE.SOLVABILITY_CONST()),_) then i::iRow;
    case ((i,BackendDAE.SOLVABILITY_PARAMETER(b=true)),_) then i::iRow;
    else then iRow;
  end match;
end incidenceMatrixElementElementfromEnhanced;

protected function incidenceMatrixfromEnhanced1
"function: incidenceMatrixfromEnhanced1
  author: Frenkel TUD 2012-05
  converts an AdjacencyMatrixEnhanced into a IncidenceMatrix"
  input BackendDAE.AdjacencyMatrixEnhanced me;
  output BackendDAE.IncidenceMatrix m;
algorithm
  m := Util.arrayMap(me,incidenceMatrixElementfromEnhanced1);
end incidenceMatrixfromEnhanced1;

protected function incidenceMatrixElementfromEnhanced1
"function: incidenceMatrixElementfromEnhanced1
  author: Frenkel TUD 2012-05
  helper for incidenceMatrixfromEnhanced1"
  input BackendDAE.AdjacencyMatrixElementEnhanced iRow;
  output BackendDAE.IncidenceMatrixElement oRow;
algorithm
//  oRow := List.map(List.sort(iRow,AdjacencyMatrixElementEnhancedCMP), incidenceMatrixElementElementfromEnhanced);
  oRow := List.fold(iRow, incidenceMatrixElementElementfromEnhanced1, {});
  oRow := listReverse(oRow);
end incidenceMatrixElementfromEnhanced1;

protected function incidenceMatrixElementElementfromEnhanced1
"function: incidenceMatrixElementElementfromEnhanced1
  author: Frenkel TUD 2012-05
  converts an AdjacencyMatrix entry into a IncidenceMatrix entry"
  input tuple<Integer, BackendDAE.Solvability> inTpl;
  input list<Integer> iRow;
  output list<Integer> oRow;
algorithm
  oRow := match(inTpl,iRow)
    local Integer i;
    case ((i,BackendDAE.SOLVABILITY_SOLVED()),_) then i::iRow;
    case ((i,BackendDAE.SOLVABILITY_CONSTONE()),_) then i::iRow;
    case ((i,BackendDAE.SOLVABILITY_CONST()),_) then i::iRow;
    case ((i,BackendDAE.SOLVABILITY_PARAMETER(b=true)),_) then i::iRow;
    case ((i,BackendDAE.SOLVABILITY_TIMEVARYING(b=true)),_) then i::iRow;
    else then iRow;
  end match;
end incidenceMatrixElementElementfromEnhanced1;

protected function incidenceMatrixfromEnhanced2
"function: incidenceMatrixfromEnhanced2
  author: Frenkel TUD 2012-11
  converts an AdjacencyMatrixEnhanced into a IncidenceMatrix"
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.Variables vars;
  output BackendDAE.IncidenceMatrix m;
algorithm
  m := Util.arrayMap1(me,incidenceMatrixElementfromEnhanced2,vars);
end incidenceMatrixfromEnhanced2;

protected function incidenceMatrixElementfromEnhanced2
"function: incidenceMatrixElementfromEnhanced2
  author: Frenkel TUD 2012-11
  helper for incidenceMatrixfromEnhanced2"
  input BackendDAE.AdjacencyMatrixElementEnhanced iRow;
  input BackendDAE.Variables vars;
  output BackendDAE.IncidenceMatrixElement oRow;
algorithm
  oRow := List.fold1(iRow, incidenceMatrixElementElementfromEnhanced2, vars, {});
  oRow := listReverse(oRow);
end incidenceMatrixElementfromEnhanced2;

protected function incidenceMatrixElementElementfromEnhanced2
"function: incidenceMatrixElementElementfromEnhanced2
  author: Frenkel TUD 2012-11
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
    case ((i,BackendDAE.SOLVABILITY_PARAMETER(b=false)),_,_) then incidenceMatrixElementElementfromEnhanced2_1(i,vars,iRow);
    case ((i,BackendDAE.SOLVABILITY_TIMEVARYING(b=_)),_,_) then incidenceMatrixElementElementfromEnhanced2_1(i,vars,iRow);
    case ((i,BackendDAE.SOLVABILITY_NONLINEAR()),_,_) then incidenceMatrixElementElementfromEnhanced2_1(i,vars,iRow);
    else then iRow;
  end match;
end incidenceMatrixElementElementfromEnhanced2;

protected function incidenceMatrixElementElementfromEnhanced2_1
  input Integer i;
  input BackendDAE.Variables vars;
  input list<Integer> iRow;
  output list<Integer> oRow;
protected
  BackendDAE.Var v;
  DAE.StateSelect s;
  Integer si;
algorithm
  v := BackendVariable.getVarAt(vars,i);
  s := BackendVariable.varStateSelect(v);
  si := BackendVariable.stateSelectToInteger(s);
  oRow := List.consOnTrue(intLt(si,0),i,iRow);
end incidenceMatrixElementElementfromEnhanced2_1;

protected function checkAssignment
"function: checkAssignment
  author: Frenkel TUD 2012-05
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
"function: selectDummyStates
  author: Frenkel TUD 2012-05
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
"function: selectDummyStateVars
  author: Frenkel TUD 2012-09
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

protected function addDummyStates
"function: addDummyStates
  author: Frenkel TUD 2012-05
  add the dummy states to the system"
  input list<DAE.ComponentRef> dummyStates;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input HashTable2.HashTable iHt;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output HashTable2.HashTable oHt;  
algorithm
  (osyst,oshared,oHt) := 
  match (dummyStates,isyst,ishared,iHt)
    local
      BackendDAE.EqSystem syst;
      HashTable2.HashTable ht;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      Option<BackendDAE.IncidenceMatrix> om,omT;
      BackendDAE.Matching matching;
      BackendDAE.StateSets stateSets;
      array<Integer> newIndexArr;
    case ({},_,_,_) then (isyst,ishared,iHt);
    case (_,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,m=om,mT=omT,matching=matching,stateSets=stateSets),_,_)
      equation
        newIndexArr = arrayCreate(BackendVariable.varsSize(vars),-1);
        // create dummy_der vars and change deselected states to dummy states
        ((vars,ht,newIndexArr,_)) = List.fold(dummyStates,makeDummyVarandDummyDerivative,(vars,iHt,newIndexArr,{})); 
        (vars,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(vars,replaceDummyDerivativesVar,ht);
        _ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(eqns,replaceDummyDerivatives,ht);
        syst = BackendDAE.EQSYSTEM(vars,eqns,om,omT,matching,stateSets);
      then
        (syst,ishared,ht);
  end match;
end addDummyStates;

protected function replaceDummyDerivatives "function replaceDummyDerivatives
  author: Frenkel TUD 2012-08"
  input tuple<DAE.Exp,HashTable2.HashTable> itpl;
  output tuple<DAE.Exp,HashTable2.HashTable> outTpl;
protected
  DAE.Exp e;
  HashTable2.HashTable ht;
algorithm
  (e,ht) := itpl;
  outTpl := Expression.traverseExp(e,replaceDummyDerivativesExp,ht);
end replaceDummyDerivatives;

protected function replaceDummyDerivativesExp "function replaceDummyDerivativesExp
  author: Frenkel TUD 2012-08"
  input tuple<DAE.Exp,HashTable2.HashTable> tpl;
  output tuple<DAE.Exp,HashTable2.HashTable> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
    local
      HashTable2.HashTable ht;
      DAE.Exp e;
      DAE.ComponentRef cr;
    case((DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr)}),ht))
      equation
        e = BaseHashTable.get(cr,ht);
      then 
        ((e,ht));
    case _ then tpl;
  end matchcontinue;
end replaceDummyDerivativesExp;

protected function replaceDummyDerivativesShared
"function: replaceDummyDerivativesShared
  author Frenkel TUD 2012-08"
  input BackendDAE.Shared ishared;
  input HashTable2.HashTable ht;
  output BackendDAE.Shared oshared;
algorithm
  oshared:= match (ishared,ht)
    local
      BackendDAE.Variables knvars,exobj,knvars1;
      BackendDAE.Variables aliasVars;      
      BackendDAE.EquationArray remeqns,inieqns;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcTree;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      list<BackendDAE.WhenClause> whenClauseLst,whenClauseLst1;
      list<BackendDAE.ZeroCrossing> zeroCrossingLst, relationsLst, sampleLst;
      Integer numberOfRelations, numberOfMathEventFunctions;
      BackendDAE.BackendDAEType btp;  
    case (BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcTree,BackendDAE.EVENT_INFO(whenClauseLst,zeroCrossingLst,sampleLst,relationsLst,numberOfRelations,numberOfMathEventFunctions),eoc,btp,symjacs),_)
      equation
        // replace dummy_derivatives in knvars,aliases,ineqns,remeqns
        (aliasVars,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(aliasVars,replaceDummyDerivativesVar,ht);
        (knvars1,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(knvars,replaceDummyDerivativesVar,ht);
        _ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(inieqns,replaceDummyDerivatives,ht);
        _ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(remeqns,replaceDummyDerivatives,ht);
        (whenClauseLst1,_) = BackendDAETransform.traverseBackendDAEExpsWhenClauseLst(whenClauseLst,replaceDummyDerivatives,ht);
      then 
        BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcTree,BackendDAE.EVENT_INFO(whenClauseLst1,zeroCrossingLst,sampleLst,relationsLst,numberOfRelations,numberOfMathEventFunctions),eoc,btp,symjacs);
  end match;
end replaceDummyDerivativesShared;

protected function replaceDummyDerivativesVar
"author: Frenkel TUD 2012-08"
 input tuple<BackendDAE.Var, HashTable2.HashTable> inTpl;
 output tuple<BackendDAE.Var, HashTable2.HashTable> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v,v1;
      HashTable2.HashTable ht;
      DAE.Exp e,e1;
      DAE.ComponentRef cr;
      Option<DAE.VariableAttributes> attr,new_attr;
      
    case ((v as BackendDAE.VAR(bindExp=SOME(e),values=attr),ht))
      equation
        ((e1, _)) = Expression.traverseExp(e, replaceDummyDerivatives, ht);
        v1 = BackendVariable.setBindExp(v,e1);
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


protected function makeDummyVarandDummyDerivative
"function: makeDummyVarandDummyDerivative
  author: Frenkel TUD
  This function creates a new variable named
  der+<varname> and adds it to the dae. The kind of the
  var with varname is changed to dummy_state"
  input DAE.ComponentRef inComponentRef;
  input tuple<BackendDAE.Variables,HashTable2.HashTable,array<Integer>,list<Integer>> inTpl;
  output tuple<BackendDAE.Variables,HashTable2.HashTable,array<Integer>,list<Integer>> oTpl;
algorithm
  oTpl := matchcontinue (inComponentRef,inTpl)
    local
      HashTable2.HashTable ht;
      BackendDAE.Variables vars;
      DAE.ComponentRef name,dummyvar_cr;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      DAE.Type tp;
      Option<DAE.Exp> bind;
      Option<Values.Value> value;
      DAE.InstDims dim;
      .DAE.ElementSource source,source1;
      Option<DAE.VariableAttributes> attr,odattr;
      DAE.VariableAttributes dattr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var dummy_derstate,dummy_state;
      Integer i;
      array<Integer> newIndexArr;
      list<Integer> ilst;
    case (name,(vars,ht,newIndexArr,ilst))
      equation
        ({BackendDAE.VAR(name,_,dir,prl,tp,bind,value,dim,source,attr,comment,ct)},{i}) = BackendVariable.getVar(name, vars);
        dummyvar_cr = ComponentReference.crefPrefixDer(name);
        source1 = DAEUtil.addSymbolicTransformation(source,DAE.NEW_DUMMY_DER(name,{}));
        /* Dummy variables are algebraic variables, hence fixed = false */
        dattr = BackendVariable.getVariableAttributefromType(tp);
        odattr = DAEUtil.setFixedAttr(SOME(dattr), SOME(DAE.BCONST(false)));
        dummy_derstate = BackendDAE.VAR(dummyvar_cr,BackendDAE.DUMMY_DER(),dir,prl,tp,NONE(),NONE(),dim,source,odattr,comment,ct);
        dummy_state = BackendDAE.VAR(name,BackendDAE.DUMMY_STATE(),dir,prl,tp,bind,value,dim,source1,attr,comment,ct);
        vars = BackendVariable.addNewVar(dummy_derstate, vars);
        vars = BackendVariable.addVar(dummy_state, vars);
        ht = BaseHashTable.add((name,Expression.crefExp(dummyvar_cr)),ht);
        newIndexArr = arrayUpdate(newIndexArr,i,BackendVariable.varsSize(vars));
      then
        ((vars,ht,newIndexArr,i::ilst));

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"IndexReduction.makeDummyVarandDummyDerivative failed!"});
      then
        fail();
  end matchcontinue;
end makeDummyVarandDummyDerivative;

protected function consArrayUpdate
  input Boolean cond;
  input array<Type_a> arr;
  input Integer index;
  input Type_a newValue;
  output array<Type_a> oarr;
  replaceable type Type_a subtypeof Any;
algorithm
  oarr := match(cond,arr,index,newValue)
    case(true,_,_,_)
      then
        arrayUpdate(arr,index,newValue);
    case(false,_,_,_) then arr;
  end match;
end consArrayUpdate;

/*****************************************
 calculation of the determinant of a square matrix . 
 *****************************************/

public function tryDeterminant
"function tryDeterminant
  author: Frenkel TUD 2012-06"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE,_) := BackendDAEUtil.mapEqSystemAndFold(inDAE,tryDeterminant0,false);
end tryDeterminant;

protected function tryDeterminant0
"function tryDeterminant0
  author: Frenkel TUD 2012-06"
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


public function determinant
"function determinant
  author: Frenkel TUD 2012-06"
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
"function determinantfromZycles
  author: Frenkel TUD 2012-06"
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
"function: dumpDigraph
  author: Frenkel TUD"
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
"function: dumpDigraph1
  author: Frenkel TUD 2012-06"
  input list<list<tuple<Integer,DAE.Exp>>> inIntegerLstLst;
  input Integer rowIndex;
algorithm
  _ := match (inIntegerLstLst,rowIndex)
    local
      list<tuple<Integer,DAE.Exp>> row;
      list<list<tuple<Integer,DAE.Exp>>> rows;
    case ({},_) then ();
    case ((row :: rows),rowIndex)
      equation
        print(intString(rowIndex));print(":");
        dumpDigraph2(row);
        dumpDigraph1(rows,rowIndex+1);
      then
        ();
  end match;
end dumpDigraph1;

public function dumpDigraph2
"function: dumpDigraph2
  author: Frenkel TUD 2012-06"
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
"function getUnvisitedNode
  author: Frenkel TUD 2012-06
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
"function determinantEdges
  author: Frenkel TUD 2012-06
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


protected function dumpZycle
  input tuple<Integer,DAE.Exp> inTpl;
  output String s;
algorithm
  s := intString(Util.tuple21(inTpl)) +& ":" +& ExpressionDump.printExpStr(Util.tuple22(inTpl));
end dumpZycle;

protected function getDeterminantDigraph
"function determinant
  author: Frenkel TUD 2012-06
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
"function dumpzycles
  author: Frenkel TUD 2012-06"
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
"function: changeDerVariablestoStates
  author: Frenkel TUD 2011-05
  change the kind of all variables in a der to state"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrixT>> inTpl;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrixT>> outTpl;
protected
  DAE.Exp e;
  tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrixT> vars;
algorithm
  (e,vars) := inTpl;
  outTpl := Expression.traverseExp(e,changeDerVariablestoStatesFinder,vars);
end changeDerVariablestoStates;

protected function changeDerVariablestoStatesFinder
"function: changeDerVariablestoStatesFinder
  author: Frenkel TUD 2011-05
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
      Option<Values.Value> d;
      Integer g,si1,si2;
      DAE.ComponentRef dummyder,cr;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      list<DAE.Subscript> lstSubs;
      Integer i,eindx;
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
        dummyder = BackendDAETransform.getStateOrder(cr,so);
        (v::{},i::_) = BackendVariable.getVar(dummyder,vars);
        nostate = not BackendVariable.isStateVar(v);
        v = Debug.bcallret2(nostate,BackendVariable.setVarKind,v, BackendDAE.STATE(), v);
        vars_1 = Debug.bcallret2(nostate, BackendVariable.addVar,v, vars,vars);
        e = Expression.crefExp(dummyder);
        ilst = List.consOnTrue(nostate, i, ilst);
      then
        ((DAE.CALL(Absyn.IDENT("der"),{e},DAE.callAttrBuiltinReal), (vars,eqns,so,ilst,eindx,mapIncRowEqn,mt)));
*/
    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})}),(vars,eqns,so,ilst,eindx,mapIncRowEqn,mt)))
      equation
        ((BackendDAE.VAR(cr,BackendDAE.STATE(),a,prl,b,c,d,lstSubs,source,dae_var_attr,comment,ct) :: {}),i::_) = BackendVariable.getVar(cr, vars) "der(der(s)) s is state => der_der_s" ;
        // do not use the normal derivative prefix for the name
        //dummyder = ComponentReference.crefPrefixDer(cr);
        dummyder = ComponentReference.makeCrefQual("$_DER",DAE.T_REAL_DEFAULT,{},cr);
        (eqns_1,so1) = addDummyStateEqn(vars,eqns,cr,dummyder,so,i,eindx,mapIncRowEqn,mt);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.STATE(), a, prl, b, NONE(), NONE(), lstSubs, source, NONE(), comment, ct), vars);
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
        v = BackendVariable.setVarKind(v,BackendDAE.STATE());
        vars = BackendVariable.addVar(v,inVars);
        (outVars,outChangedVars) = changeDerVariablestoStates1(rest,ilst,vars,i::inChangedVars);
      then
        (outVars,outChangedVars);
    case ((v as BackendDAE.VAR(varKind=BackendDAE.DUMMY_STATE()))::rest,i::ilst,_,_)
      equation
        v = BackendVariable.setVarKind(v,BackendDAE.STATE());
        vars = BackendVariable.addVar(v,inVars);
        (outVars,outChangedVars) = changeDerVariablestoStates1(rest,ilst,vars,i::inChangedVars);
      then
        (outVars,outChangedVars);
    case ((v as BackendDAE.VAR(varKind=BackendDAE.DUMMY_DER()))::rest,i::ilst,_,_)
      equation
        v = BackendVariable.setVarKind(v,BackendDAE.STATE());
        vars = BackendVariable.addVar(v,inVars);
        (outVars,outChangedVars) = changeDerVariablestoStates1(rest,ilst,vars,i::inChangedVars);
      then
        (outVars,outChangedVars);
    case (BackendDAE.VAR(varKind=BackendDAE.STATE())::rest,i::ilst,_,_)
      equation
        (outVars,outChangedVars) = changeDerVariablestoStates1(rest,ilst,inVars,inChangedVars);
      then
        (outVars,outChangedVars);
  end matchcontinue;
end changeDerVariablestoStates1;

protected function addDummyStateEqn 
"function: addDummyStateEqn
  author: Frenkel TUD 2011-05
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
        so = BackendDAETransform.addStateOrder(inCr,inDCr,inSo);
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
"function: getSetVars
  author: Frenkel TUD 2012-12"
  input Integer index;
  input Integer setsize;
  input Integer nStates;
  input Integer nCEqns;
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
  list<Integer> range;
algorithm
//  set := ComponentReference.makeCrefIdent("$STATESET",DAE.T_COMPLEX_DEFAULT,{DAE.INDEX(DAE.ICONST(index))});
  set := ComponentReference.makeCrefIdent("$STATESET" +& intString(index),DAE.T_COMPLEX_DEFAULT,{});
  tp := Util.if_(intGt(setsize,1),DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(setsize)}, DAE.emptyTypeSource),DAE.T_REAL_DEFAULT);
  crstates := ComponentReference.joinCrefs(set,ComponentReference.makeCrefIdent("x",tp,{}));
  range := List.intRange(setsize);
  crset := Debug.bcallret3(intGt(setsize,1),List.map1r,range, ComponentReference.subscriptCrefWithInt, crstates,{crstates});
  oSetVars := List.map4(crset,generateVar,BackendDAE.STATE(),DAE.T_REAL_DEFAULT,{},NONE());
  oSetVars := List.map1(oSetVars,BackendVariable.setVarFixed,false);
  tp := Util.if_(intGt(setsize,1),DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_INTEGER(nStates),DAE.DIM_INTEGER(setsize)}, DAE.emptyTypeSource),
                                 DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_INTEGER(nStates)}, DAE.emptyTypeSource));
  realtp := Util.if_(intGt(setsize,1),DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(nStates),DAE.DIM_INTEGER(setsize)}, DAE.emptyTypeSource),
                                 DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(nStates)}, DAE.emptyTypeSource));
  ocrA := ComponentReference.joinCrefs(set,ComponentReference.makeCrefIdent("A",tp,{}));
  oAVars := generateArrayVar(ocrA,BackendDAE.VARIABLE(),tp,NONE());
  oAVars := List.map1(oAVars,BackendVariable.setVarFixed,true);
  // add start value A[i,j] = if i==j then 1 else 0 via initial equations
  oAVars := List.map1(oAVars,BackendVariable.setVarStartValue,DAE.ICONST(0));
  oAVars := setSetAStart(oAVars,1,1,nStates,{});
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
      Integer n1,r1;
      DAE.Exp start;
    case({},_,_,_,_) then listReverse(iAcc);
    case(v::rest,_,_,_,_)
      equation
        start = Util.if_(intEq(n,r),DAE.ICONST(1),DAE.ICONST(0));
        v = BackendVariable.setVarStartValue(v,start);
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
algorithm
  _ := match(isyst,ishared,inids,filename)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      GraphML.Graph graph;
      list<Integer> eqnsids;
      Integer neqns;
      array<Integer> vec1,vec2,vec3,mapIncRowEqn;
      array<Boolean> eqnsflag;
      BackendDAE.EqSystem syst;
      DAE.FunctionTree funcs;
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.NO_MATCHING()),_,NONE(),_)      
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        funcs = BackendDAEUtil.getFunctions(ishared);
        (_,m,mt) = BackendDAEUtil.getIncidenceMatrix(isyst,BackendDAE.NORMAL(),SOME(funcs));
        mapIncRowEqn = listArray(List.intRange(arrayLength(m)));
        graph = GraphML.getGraph("G",false);  
        ((_,graph)) = BackendVariable.traverseBackendDAEVars(vars,addVarGraph,(1,graph));
        //neqns = BackendDAEUtil.equationArraySize(eqns);
        neqns = BackendDAEUtil.equationSize(eqns);
        eqnsids = List.intRange(neqns);
        graph = List.fold2(eqnsids,addEqnGraph,eqns,mapIncRowEqn,graph);
        ((_,_,graph)) = List.fold(eqnsids,addEdgesGraph,(1,m,graph));
        GraphML.dumpGraph(graph,filename);
     then
       ();
    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt),matching=BackendDAE.NO_MATCHING()),_,NONE(),_)      
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        graph = GraphML.getGraph("G",false);  
        ((_,graph)) = BackendVariable.traverseBackendDAEVars(vars,addVarGraph,(1,graph));
        //neqns = BackendDAEUtil.equationArraySize(eqns);
        neqns = BackendDAEUtil.equationSize(eqns);
        eqnsids = List.intRange(neqns);
        mapIncRowEqn = listArray(List.intRange(arrayLength(m)));
        graph = List.fold2(eqnsids,addEqnGraph,eqns,mapIncRowEqn,graph);
        ((_,_,graph)) = List.fold(eqnsids,addEdgesGraph,(1,m,graph));
        GraphML.dumpGraph(graph,filename);
     then
       ();
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=vec1,ass2=vec2)),_,NONE(),_)      
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        funcs = BackendDAEUtil.getFunctions(ishared);
        //(_,m,mt) = BackendDAEUtil.getIncidenceMatrix(isyst, BackendDAE.NORMAL(), SOME(funcs));
        //mapIncRowEqn = listArray(List.intRange(arrayLength(m)));
        //(_,m,mt,_,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(isyst,BackendDAE.SOLVABLE(), SOME(funcs)));
        (syst,m,mt,_,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(isyst,BackendDAE.NORMAL(), SOME(funcs));
        graph = GraphML.getGraph("G",false);  
        ((_,_,graph)) = BackendVariable.traverseBackendDAEVars(vars,addVarGraphMatch,(1,vec1,graph));
        //neqns = BackendDAEUtil.equationArraySize(eqns);
        neqns = BackendDAEUtil.equationSize(eqns);
        eqnsids = List.intRange(neqns);
        eqnsflag = arrayCreate(neqns,false);
        graph = List.fold2(eqnsids,addEqnGraphMatch,eqns,(vec2,mapIncRowEqn,eqnsflag),graph);
        //graph = List.fold3(eqnsids,addEqnGraphMatch,eqns,vec2,mapIncRowEqn,graph);
        ((_,_,_,_,graph)) = List.fold(eqnsids,addDirectedEdgesGraph,(1,m,vec2,mapIncRowEqn,graph));
        GraphML.dumpGraph(graph,filename);
     then
       ();
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=vec1,ass2=vec2)),_,SOME(vec3),_)      
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        funcs = BackendDAEUtil.getFunctions(ishared);
        (_,m,mt,_,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(isyst,BackendDAE.NORMAL(), SOME(funcs));
        graph = GraphML.getGraph("G",false);  
        ((_,graph)) = BackendVariable.traverseBackendDAEVars(vars,addVarGraph,(1,graph));
        neqns = BackendDAEUtil.equationSize(eqns);
        eqnsids = List.intRange(neqns);
        graph = List.fold2(eqnsids,addEqnGraph,eqns,mapIncRowEqn,graph);
        ((_,_,_,_,graph)) = List.fold(eqnsids,addDirectedNumEdgesGraph,(1,m,vec2,vec3,graph));
        GraphML.dumpGraph(graph,filename);
     then
       ();
  end match;
end dumpSystemGraphML;

protected function addVarGraph
"author: Frenkel TUD 2012-05"
 input tuple<BackendDAE.Var, tuple<Integer,GraphML.Graph>> inTpl;
 output tuple<BackendDAE.Var, tuple<Integer,GraphML.Graph>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      GraphML.Graph g;
      DAE.ComponentRef cr;
      Integer id;
      Boolean b;
      String color;
    case ((v as BackendDAE.VAR(varName=cr),(id,g)))
      equation
        true = BackendVariable.isStateVar(v);
        //g = GraphML.addNode("v" +& intString(id),ComponentReference.printComponentRefStr(cr),GraphML.COLOR_BLUE,GraphML.ELLIPSE(),g);
        //g = GraphML.addNode("v" +& intString(id),intString(id),GraphML.COLOR_BLUE,GraphML.ELLIPSE(),g);
        g = GraphML.addNode("v" +& intString(id),intString(id) +& ": " +& ComponentReference.printComponentRefStr(cr),GraphML.COLOR_BLUE,GraphML.ELLIPSE(),g);
      then ((v,(id+1,g)));      
    case ((v as BackendDAE.VAR(varName=cr),(id,g)))
      equation
        b = BackendVariable.isVarDiscrete(v);
        color = Util.if_(b,GraphML.COLOR_PURPLE,GraphML.COLOR_RED);
        //g = GraphML.addNode("v" +& intString(id),ComponentReference.printComponentRefStr(cr),GraphML.COLOR_RED,GraphML.ELLIPSE(),g);
        //g = GraphML.addNode("v" +& intString(id),intString(id),GraphML.COLOR_RED,GraphML.ELLIPSE(),g);
        g = GraphML.addNode("v" +& intString(id),intString(id) +& ": " +&ComponentReference.printComponentRefStr(cr),color,GraphML.ELLIPSE(),g);
      then ((v,(id+1,g)));
    case _ then inTpl;
  end matchcontinue;
end addVarGraph;

protected function addVarGraphMatch
"author: Frenkel TUD 2012-05"
 input tuple<BackendDAE.Var, tuple<Integer,array<Integer>,GraphML.Graph>> inTpl;
 output tuple<BackendDAE.Var, tuple<Integer,array<Integer>,GraphML.Graph>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      GraphML.Graph g;
      DAE.ComponentRef cr;
      Integer id;
      array<Integer> vec1;
      String color;
    case ((v as BackendDAE.VAR(varName=cr),(id,vec1,g)))
      equation
        true = BackendVariable.isStateVar(v);
        color = Util.if_(intGt(vec1[id],0),GraphML.COLOR_BLUE,GraphML.COLOR_YELLOW);
        //g = GraphML.addNode("v" +& intString(id),ComponentReference.printComponentRefStr(cr),color,GraphML.ELLIPSE(),g);
        //g = GraphML.addNode("v" +& intString(id),intString(id),color,GraphML.ELLIPSE(),g);
        g = GraphML.addNode("v" +& intString(id),intString(id) +& ":" +& ComponentReference.printComponentRefStr(cr),color,GraphML.ELLIPSE(),g);
      then ((v,(id+1,vec1,g)));      
    case ((v as BackendDAE.VAR(varName=cr),(id,vec1,g)))
      equation
        color = Util.if_(intGt(vec1[id],0),GraphML.COLOR_RED,GraphML.COLOR_YELLOW);
        //g = GraphML.addNode("v" +& intString(id),ComponentReference.printComponentRefStr(cr),color,GraphML.ELLIPSE(),g);
        //g = GraphML.addNode("v" +& intString(id),intString(id),color,GraphML.ELLIPSE(),g);
        g = GraphML.addNode("v" +& intString(id),intString(id) +& ":" +& ComponentReference.printComponentRefStr(cr),color,GraphML.ELLIPSE(),g);
      then ((v,(id+1,vec1,g)));
    case _ then inTpl;
  end matchcontinue;
end addVarGraphMatch;

protected function addEqnGraph
  input Integer inNode;
  input BackendDAE.EquationArray eqns;
  input array<Integer> mapIncRowEqn;
  input GraphML.Graph inGraph;
  output GraphML.Graph outGraph;
protected
  BackendDAE.Equation eqn;
  String str;
algorithm
  eqn := BackendDAEUtil.equationNth(eqns, mapIncRowEqn[inNode]-1);
  str := BackendDump.equationString(eqn);
  //str := intString(inNode);
  str := intString(inNode) +& ": " +& BackendDump.equationString(eqn);
  str := Util.xmlEscape(str);
  outGraph := GraphML.addNode("n" +& intString(inNode),str,GraphML.COLOR_GREEN,GraphML.RECTANGLE(),inGraph); 
end addEqnGraph;

protected function addEdgesGraph
  input Integer e;
  input tuple<Integer,BackendDAE.IncidenceMatrix,GraphML.Graph> inTpl;
  output tuple<Integer,BackendDAE.IncidenceMatrix,GraphML.Graph> outTpl;
protected
  Integer id;
  GraphML.Graph graph;
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
  input GraphML.Graph inGraph;
  output GraphML.Graph outGraph;
algorithm
  outGraph := matchcontinue(inNode,eqns,atpl,inGraph)
    local
      BackendDAE.Equation eqn;
      String str,color;
      Integer e;
      array<Integer> vec2,mapIncRowEqn;
      array<Boolean> eqnsflag;
    case(_,_,(vec2,mapIncRowEqn,eqnsflag),_)
      equation
        e = mapIncRowEqn[inNode];
        false = eqnsflag[e];
       eqn = BackendDAEUtil.equationNth(eqns, mapIncRowEqn[inNode]-1);
       str = BackendDump.equationString(eqn);
       str = intString(e) +& ": " +&  str;
       //str = intString(inNode);
       str = Util.xmlEscape(str);
       color = Util.if_(intGt(vec2[inNode],0),GraphML.COLOR_GREEN,GraphML.COLOR_PURPLE);
     then
        GraphML.addNode("n" +& intString(e),str,color,GraphML.RECTANGLE(),inGraph);
    case(_,_,(vec2,mapIncRowEqn,eqnsflag),_)
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
  input tuple<Integer,GraphML.Graph> inTpl;
  output tuple<Integer,GraphML.Graph> outTpl;
protected
  Integer id,v;
  GraphML.Graph graph;
  GraphML.LineType ln;
algorithm
  (id,graph) := inTpl;
  v := intAbs(V);
  ln := Util.if_(intGt(V,0),GraphML.LINE(),GraphML.DASHED());
  graph := GraphML.addEgde("e" +& intString(id),"n" +& intString(e),"v" +& intString(v),GraphML.COLOR_BLACK,ln,NONE(),(NONE(),NONE()),graph);
  outTpl := ((id+1,graph));
end addEdgeGraph;

protected function addDirectedEdgesGraph
  input Integer e;
  input tuple<Integer,BackendDAE.IncidenceMatrix,array<Integer>,array<Integer>,GraphML.Graph> inTpl;
  output tuple<Integer,BackendDAE.IncidenceMatrix,array<Integer>,array<Integer>,GraphML.Graph> outTpl;
protected
  Integer id,v,n;
  GraphML.Graph graph;
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
  input tuple<Integer,Integer,GraphML.Graph> inTpl;
  output tuple<Integer,Integer,GraphML.Graph> outTpl;
protected
  Integer id,r,absv;
  GraphML.Graph graph;
  tuple<Option<GraphML.ArrowType>,Option<GraphML.ArrowType>> arrow;
  GraphML.LineType lt;
algorithm
  (id,r,graph) := inTpl;
  absv := intAbs(v);
  arrow := Util.if_(intEq(r,absv),(SOME(GraphML.ARROWSTANDART()),NONE()),(NONE(),SOME(GraphML.ARROWSTANDART())));
  lt := Util.if_(intGt(v,0),GraphML.LINE(),GraphML.DASHED());
  graph := GraphML.addEgde("e" +& intString(id),"n" +& intString(e),"v" +& intString(absv),GraphML.COLOR_BLACK,lt,NONE(),arrow,graph);
  outTpl := ((id+1,r,graph));
end addDirectedEdgeGraph;


protected function addDirectedNumEdgesGraph
  input Integer e;
  input tuple<Integer,BackendDAE.IncidenceMatrix,array<Integer>,array<Integer>,GraphML.Graph> inTpl;
  output tuple<Integer,BackendDAE.IncidenceMatrix,array<Integer>,array<Integer>,GraphML.Graph> outTpl;
protected
  Integer id,v;
  GraphML.Graph graph;
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
  input tuple<Integer,Integer,String,GraphML.Graph> inTpl;
  output tuple<Integer,Integer,String,GraphML.Graph> outTpl;
protected
  Integer id,r,n;
  GraphML.Graph graph;
  tuple<Option<GraphML.ArrowType>,Option<GraphML.ArrowType>> arrow;
  String text;
  Option<GraphML.EdgeLabel> label;
algorithm
  (id,r,text,graph) := inTpl;
  arrow := Util.if_(intEq(r,v),(SOME(GraphML.ARROWSTANDART()),NONE()),(NONE(),SOME(GraphML.ARROWSTANDART())));
  label := Util.if_(intEq(r,v),SOME(GraphML.EDGELABEL(text,"#0000FF")),NONE());
  graph := GraphML.addEgde("e" +& intString(id),"n" +& intString(e),"v" +& intString(v),GraphML.COLOR_BLACK,GraphML.LINE(),label,arrow,graph);
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
  GraphML.Graph graph;
  Integer id;
  BackendDAE.Variables varsarray;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=varsarray,m=SOME(m)) := isyst;
  (states,vars) := statesandVarsInEqns(inEqnsLst,m,{},{});
  graph := GraphML.getGraph("G",false);
  graph := List.fold1(inEqnsLst,addEqnNodes,ass2,graph);
  graph := List.fold1(states,addVarNodes,("s",varsarray,ass1,GraphML.COLOR_RED,GraphML.COLOR_DARKRED),graph);
  graph := List.fold1(vars,addVarNodes,("v",varsarray,ass1,GraphML.COLOR_YELLOW,GraphML.COLOR_GRAY),graph);
  ((graph,_)) := List.fold2(inEqnsLst,addEdges,m,ass2,(graph,1));
  GraphML.dumpGraph(graph,fileName);
end dumpUnmatched;

protected function addEdges
  input Integer e;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> ass2;
  input tuple<GraphML.Graph,Integer> inGraph;
  output tuple<GraphML.Graph,Integer> outGraph;
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
  input tuple<GraphML.Graph,Integer> inGraph;
  output tuple<GraphML.Graph,Integer> outGraph;
protected
  GraphML.Graph graph;
  Integer id,e,evar;
  String prefix;
  array<Integer> ass2;
  Option<GraphML.ArrowType> arrow;
algorithm
  (e,prefix,ass2) := inTpl;
  (graph,id) := inGraph;
  evar :=ass2[e];
  arrow := Util.if_(intGt(evar,0) and intEq(evar,v) ,SOME(GraphML.ARROWSTANDART()),NONE());
  graph := GraphML.addEgde("e" +& intString(id),"n" +& intString(e),prefix +& intString(v),GraphML.COLOR_BLACK,GraphML.LINE(),NONE(),(NONE(),arrow),graph);
  outGraph := (graph,id+1);  
end addEdge;

protected function addEqnNodes
  input Integer inNode;
  input array<Integer> ass2;
  input GraphML.Graph inGraph;
  output GraphML.Graph outGraph;
protected
  String color;
algorithm
  color := Util.if_(intGt(ass2[inNode],0),GraphML.COLOR_GREEN,GraphML.COLOR_BLUE);
  outGraph := GraphML.addNode("n" +& intString(inNode),intString(inNode),color,GraphML.RECTANGLE(),inGraph); 
end addEqnNodes;

protected function addVarNodes
  input Integer inNode;
  input tuple<String,BackendDAE.Variables,array<Integer>,String,String> inTpl;
  input GraphML.Graph inGraph;
  output GraphML.Graph outGraph;
protected
 String prefix,color,color1,c;
 BackendDAE.Variables vars;
 BackendDAE.Var var;
 DAE.ComponentRef cr;
 array<Integer> ass1;
algorithm
  (prefix,vars,ass1,color,color1) := inTpl;
  var := BackendVariable.getVarAt(vars,inNode); 
  cr := BackendVariable.varCref(var);
  c := Util.if_(intGt(ass1[inNode],0),color1,color);
  outGraph := GraphML.addNode(prefix +& intString(inNode),ComponentReference.printComponentRefStr(cr),c,GraphML.ELLIPSE(),inGraph); 
end addVarNodes;

protected function statesandVarsInEqns
"function: statesandVarsInEqns
  author: Frenkel TUD - 2012-04"
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
      GraphML.Graph graph;
      list<Integer> eqnsids;
      Integer neqns;
    case (_,_,_,_)      
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        graph = GraphML.getGraph("G",false);  
        ((_,graph)) = BackendVariable.traverseBackendDAEVars(vars,addVarGraph,(1,graph));
        neqns = BackendDAEUtil.systemSize(isyst);
        eqnsids = List.intRange(neqns);
        graph = List.fold2(eqnsids,addEqnGraph,eqns,listArray(eqnsids),graph);
        ((_,_,graph)) = List.fold(eqnsids,addDirectedNumEdgesGraphEnhanced,(1,m,graph));
        GraphML.dumpGraph(graph,"");
     then
       ();
  end match;
end dumpSystemGraphMLEnhanced;

protected function addDirectedNumEdgesGraphEnhanced
  input Integer e;
  input tuple<Integer,BackendDAE.AdjacencyMatrixEnhanced,GraphML.Graph> inTpl;
  output tuple<Integer,BackendDAE.AdjacencyMatrixEnhanced,GraphML.Graph> outTpl;
protected
  Integer id;
  GraphML.Graph graph;
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
  input tuple<Integer,GraphML.Graph> inTpl;
  output tuple<Integer,GraphML.Graph> outTpl;
algorithm
  outTpl := matchcontinue(vs,e,inTpl)
    local
      BackendDAE.Solvability s;
      Integer id,v;
      GraphML.Graph graph;
      String text;
      Option<GraphML.EdgeLabel> label;
    case((v,s),_,(id,graph))
      equation
        true = intGt(v,0);
        text = intString(BackendDAEOptimize.solvabilityWights(s));
        label = SOME(GraphML.EDGELABEL(text,"#0000FF"));
        graph = GraphML.addEgde("e" +& intString(id),"n" +& intString(e),"v" +& intString(v),GraphML.COLOR_BLACK,GraphML.LINE(),label,(NONE(),NONE()),graph);
      then
        ((id+1,graph));
    else then inTpl;            
  end matchcontinue;
end addDirectedNumEdgeGraphEnhanced;

end IndexReduction;
