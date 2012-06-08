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
public import HashTable;
public import HashTable3;
public import HashTableCG;

protected import Absyn;
protected import BackendDAEEXT;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendDAEOptimize;
protected import BackendDAETransform;
protected import BackendVariable;
protected import BaseHashTable;
protected import ComponentReference;
protected import Debug;
protected import Derive;
protected import Error;
protected import Expression;
protected import Flags;
protected import GraphML;
protected import Inline;
protected import List;
protected import Matching;
protected import SCode;
protected import Util;
protected import Values;

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
  input list<Integer> eqns;
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
      list<Integer> eqns_1,changedeqns,unassignedStates;
      Integer contiEqn;
      Boolean b;
      array<Integer> ass1,ass2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_,_,_)
      equation
        true = intGt(listLength(eqns),0);
        // check by count vars of equations, if len(eqns) > len(vars) stop because of structural singular system
        // the check may should first split the equations in independent subgraphs
        (b,eqns_1,unassignedStates) = minimalStructurallySingularSystem(eqns,isyst,inAssignments1,inAssignments2);
        (changedeqns,contiEqn,syst,shared,ass1,ass2,arg) =
         pantelidesIndexReduction1(b,unassignedStates,eqns,eqns_1,actualEqn,isyst,ishared,inAssignments1,inAssignments2,inArg);
      then
       (changedeqns,contiEqn,syst,shared,ass1,ass2,arg);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.pantelidesIndexReduction called with empty list of equations!"});
      then
        fail();
  end matchcontinue;
end pantelidesIndexReduction;

public function pantelidesIndexReduction1
"function: pantelidesIndexReduction1
  author: Frenkel TUD 2012-04
  Index Reduction algorithm to get a index 1 or 0 system."
  input Boolean b;
  input list<Integer> unassignedStates;
  input list<Integer> alleqns;
  input list<Integer> eqns;
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
  matchcontinue (b,unassignedStates,alleqns,eqns,actualEqn,isyst,ishared,inAssignments1,inAssignments2,inArg)
    local
      list<BackendDAE.Var> varlst;
      list<Integer> changedeqns;
      Integer contiEqn;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1,derivedMultiEqn,derivedMultiEqn1;
      BackendDAE.StateOrder so,so1;
      BackendDAE.ConstraintEquations orgEqnsLst,orgEqnsLst1;
      array<Integer>  ass1,ass2; 
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
           
    case (true,_,_,_,_,_,_,_,_,(so,orgEqnsLst,derivedAlgs,derivedMultiEqn))
      equation
        true = intGt(listLength(eqns),0);
        Debug.fcall(Flags.BLT_DUMP, print, "Reduce Index\nmarked equations: ");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst, (eqns,intString," ","\n"));
        Debug.fcall(Flags.BLT_DUMP, print, BackendDump.dumpMarkedEqns(isyst, eqns));
        (syst,shared,ass1,ass2,derivedAlgs1,derivedMultiEqn1,so1,orgEqnsLst1,changedeqns) = differentiateEqns(isyst,ishared,eqns,inAssignments1,inAssignments2,derivedAlgs,derivedMultiEqn,so,orgEqnsLst,{});
        contiEqn = List.fold(changedeqns,intMin,actualEqn);
      then
       (changedeqns,contiEqn,syst,shared,ass1,ass2,(so1,orgEqnsLst1,derivedAlgs1,derivedMultiEqn1));

    case (_,_,_,_,_,_,_,_,_,_)
      equation
        false = intGt(listLength(eqns),0);
        Error.addMessage(Error.INTERNAL_ERROR, {"IndexReduction.pantelidesIndexReduction failed! Found empty set of continues equations. Use +d=bltdump to get more information."});
        Debug.fcall(Flags.BLT_DUMP, print, "Reduce Index failed!\nmarked equations:\n");
        Debug.fcall(Flags.BLT_DUMP, print, BackendDump.dumpMarkedEqns(isyst, alleqns));
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(inAssignments1,inAssignments2,{}));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dump, BackendDAE.DAE({syst},ishared));
      then
        fail(); 

    case (false,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(listLength(eqns),0);
        Error.addMessage(Error.INTERNAL_ERROR, {"IndexReduction.pantelidesIndexReduction failed! System is structurally singulare and cannot handled because number of unassigned equations is larger than number of states. Use +d=bltdump to get more information."});
        Debug.fcall(Flags.BLT_DUMP, print, "Reduce Index failed!\nmarked equations:\n");
        Debug.fcall(Flags.BLT_DUMP, print, BackendDump.dumpMarkedEqns(isyst, eqns));
        Debug.fcall(Flags.BLT_DUMP, print, "unassgined states:\n");
        varlst = List.map1r(unassignedStates,BackendVariable.getVarAt,BackendVariable.daeVars(isyst));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpVars,varlst);
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(inAssignments1,inAssignments2,{}));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dump, BackendDAE.DAE({syst},ishared));
      then
        fail(); 
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.pantelidesIndexReduction failed! Use +d=bltdump to get more information."});
      then
        fail();
  end matchcontinue;
end pantelidesIndexReduction1;

protected function minimalStructurallySingularSystem
"function: minimalStructurallySingularSystem
  author: Frenkel TUD - 2012-04,
  checks if the subset of equations is minimal structurally singular.
  The number of states must be larger or equal to the number of unmatched
  equations."
  input list<Integer> inEqnsLst;
  input BackendDAE.EqSystem syst;
  input array<Integer> inAssignments1;
  input array<Integer> inAssignments2;
  output Boolean b;
  output list<Integer> outEqnsLst;
  output list<Integer> outStateIndxs;
protected
  list<Integer> unassignedEqns;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  array<Boolean> statemark;
  Integer size;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,m=SOME(m)) := syst;
  ((unassignedEqns,outEqnsLst)) := List.fold2(inEqnsLst,unassignedContinuesEqns,vars,inAssignments2,({},{}));
  outEqnsLst := listReverse(outEqnsLst);
  size := BackendDAEUtil.equationSize(eqns);
  statemark := arrayCreate(size,false);
  outStateIndxs := List.fold2(inEqnsLst,statesInEquations,(m,statemark),inAssignments1,{});
  b := intGe(listLength(outStateIndxs),listLength(unassignedEqns));
end minimalStructurallySingularSystem;

protected function unassignedContinuesEqns
  input Integer eindx;
  input BackendDAE.Variables vars;
  input array<Integer> ass2;
  input tuple<list<Integer>,list<Integer>> inFold;
  output tuple<list<Integer>,list<Integer>> outFold;
algorithm
  outFold := matchcontinue(eindx,vars,ass2,inFold)
    local
      Integer vindx;
      list<Integer> unassignedEqns,eqnsLst;
      BackendDAE.Var v;
      Boolean b;
    case(_,_,_,(unassignedEqns,eqnsLst))
      equation
        vindx = ass2[eindx];
        true = intGt(vindx,0);
        v = BackendVariable.getVarAt(vars, vindx);
        b = BackendVariable.isVarDiscrete(v);
        eqnsLst = List.consOnTrue(not b, eindx, eqnsLst);
      then
       ((unassignedEqns,eqnsLst));
    case(_,_,_,(unassignedEqns,eqnsLst))
      equation
        vindx = ass2[eindx];
        false = intGt(vindx,0);
      then
       ((eindx::unassignedEqns,eindx::eqnsLst));
  end matchcontinue;  
end unassignedContinuesEqns;

protected function statesInEquations
"function: statesInEquations
  author: Frenkel TUD 2012-04"
  input Integer eindx;
  input tuple<BackendDAE.IncidenceMatrix,array<Boolean>> inTpl;
  input array<Integer> ass1;
  input list<Integer> inStateLst;
  output list<Integer> outStateLst;
protected
  list<Integer> vars;
  BackendDAE.IncidenceMatrix m;
  array<Boolean> statemark;
algorithm
  (m,statemark) := inTpl;
  // get States;
  vars := List.removeOnTrue(0, intLt, m[eindx]);
  // get unassigned
//  vars := List.removeOnTrue(ass1, Matching.isUnAssigned, vars);
  vars := List.map(vars,intAbs);
  vars := List.removeOnTrue(statemark, isMarked, vars);
  _ := List.fold(vars, markTrue, statemark);
  // add states to list
  outStateLst := listAppend(inStateLst,vars);        
end statesInEquations;

public function isMarked
"function isMarked
  author: Frenkel TUD 2012-05"
  input array<Boolean> ass;
  input Integer indx;
  output Boolean b;
algorithm
  b := ass[intAbs(indx)];
end isMarked;

public function isUnMarked
"function isUnMarked
  author: Frenkel TUD 2012-05"
  input array<Boolean> ass;
  input Integer indx;
  output Boolean b;
algorithm
  b := not ass[intAbs(indx)];
end isUnMarked;

public function markTrue
"function markElement
  author: Frenkel TUD 2012-05"
  input Integer indx;
  input array<Boolean> iMark;
  output array<Boolean> oMark;
algorithm
  oMark := arrayUpdate(iMark,intAbs(indx),true);
end markTrue;

protected function differentiateEqns
"function: differentiateEqns
  author: Frenkel TUD 2011-05
  differentiates the constraint equations for 
  Pantelides index reduction method."
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> inEqns;
  input array<Integer> inAss1;
  input array<Integer> inAss2;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
  input BackendDAE.StateOrder inStateOrd;
  input BackendDAE.ConstraintEquations inOrgEqnsLst;
  input list<Integer> inchangedEqns;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output array<Integer> outAss1;
  output array<Integer> outAss2;  
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
  output BackendDAE.StateOrder outStateOrd;
  output BackendDAE.ConstraintEquations outOrgEqnsLst;
  output list<Integer> outchangedEqns;
algorithm
  (osyst,oshared,outAss1,outAss2,outDerivedAlgs,outDerivedMultiEqn,outStateOrd,outOrgEqnsLst,outchangedEqns):=
  matchcontinue (isyst,ishared,inEqns,inAss1,inAss2,inDerivedAlgs,inDerivedMultiEqn,inStateOrd,inOrgEqnsLst,inchangedEqns)
    local
      Integer e_1,e,e1,i,eqnss,eqnss1;
      BackendDAE.Equation eqn,eqn_1;
      BackendDAE.EquationArray eqns_1,eqns,seqns,ie;
      list<BackendDAE.Value> es,ilst,eqnslst,eqnslst1,changedEqns;
      BackendDAE.Variables v,kv,ev,v1;
      BackendDAE.AliasVariables av;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      array<DAE.Algorithm> al,al1;
      array<DAE.Constraint> constrs;
      array<BackendDAE.ComplexEquation> complEqs;
      BackendDAE.EventInfo einfo;
      list<BackendDAE.WhenClause> wclst,wclst1;
      list<BackendDAE.ZeroCrossing> zc;
      BackendDAE.ExternalObjectClasses eoc;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1,derivedMultiEqn,derivedMultiEqn1;
      BackendDAE.StateOrder so,so1;
      BackendDAE.ConstraintEquations orgEqnsLst;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrix mt;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.BackendDAEType btp;
      BackendDAE.Matching matching;
      array<Integer> ass1,ass2;
      DAE.FunctionTree functionTree;
      BackendDAE.SymbolicJacobians symjacs;
    case (_,_,{},_,_,_,_,_,_,_) then (isyst,ishared,inAss1,inAss2,inDerivedAlgs,inDerivedMultiEqn,inStateOrd,inOrgEqnsLst,inchangedEqns);
    case (syst as BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching),shared as BackendDAE.SHARED(kv,ev,av,ie,seqns,ae,al,constrs,complEqs,functionTree,BackendDAE.EVENT_INFO(wclst,zc),eoc,btp,symjacs),(e :: es),_,_,_,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        // print( "differentiated equation " +& intString(e) +& " " +& BackendDump.equationStr(eqn) +& "\n");
        (eqn_1,al1,derivedAlgs,ae1,derivedMultiEqn,_) = Derive.differentiateEquationTime(eqn, v, shared, al,inDerivedAlgs,ae,inDerivedMultiEqn);
        (eqn_1,al1,ae1,complEqs,wclst,(so,_)) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn_1, al1, ae1, complEqs, wclst, BackendDAETransform.replaceStateOrderExp,(inStateOrd,v)); 
        eqnss = BackendDAEUtil.equationSize(eqns);
        (eqn_1,al1,ae1, complEqs,wclst1,(v1,eqns,so,ilst)) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn_1,al1,ae1, complEqs,wclst,changeDerVariablestoStates,(v,eqns,inStateOrd,{}));
        eqnss1 = BackendDAEUtil.equationSize(eqns);
        eqnslst = Debug.bcallret2(intGt(eqnss1,eqnss),List.intRange2,eqnss+1,eqnss1,{});
        Debug.fcall(Flags.BLT_DUMP, debugdifferentiateEqns,(eqn,eqn_1)); 
        eqns_1 = BackendEquation.equationSetnth(eqns,e_1,eqn_1);
        i = inAss2[e];
        ass2 = arrayUpdate(inAss2,e,-1);
        ass1 = Debug.bcallret3(intGt(i,0),arrayUpdate,inAss1,i,-1,inAss1);
        eqnslst1 = BackendDAETransform.collectVarEqns(ilst,e::eqnslst,mt,arrayLength(mt));
        Debug.fcall(Flags.BLT_DUMP, print, "Update Incidence Matrix: ");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,(eqnslst1,intString," ","\n"));
        syst = BackendDAE.EQSYSTEM(v1,eqns_1,SOME(m),SOME(mt),matching);
        shared = BackendDAE.SHARED(kv,ev,av,ie,seqns,ae1,al1,constrs,complEqs,functionTree,BackendDAE.EVENT_INFO(wclst1,zc),eoc,btp,symjacs);
        syst = BackendDAEUtil.updateIncidenceMatrix(syst, shared, eqnslst1);
        orgEqnsLst = BackendDAETransform.addOrgEqn(inOrgEqnsLst,e,eqn);
        changedEqns = listAppend(inchangedEqns,eqnslst);
        changedEqns = e::changedEqns;        
        (syst,shared,ass1,ass2,derivedAlgs1,derivedMultiEqn1,so1,orgEqnsLst,changedEqns) = differentiateEqns(syst,shared,es,ass1,ass2,derivedAlgs,derivedMultiEqn,so,orgEqnsLst,changedEqns);
      then
        (syst,shared,ass1,ass2,derivedAlgs1,derivedMultiEqn1,so1,orgEqnsLst,changedEqns);
    case (syst as BackendDAE.EQSYSTEM(orderedEqs=eqns),_,(e :: _),_,_,_,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        print("IndexReduction.differentiateEqns failed for eqn " +& intString(e) +& ":\n");
        print(BackendDump.equationStr(eqn)); print("\n");
        BackendDump.dumpEqSystem(syst);
        BackendDump.dumpShared(ishared);
      then
        fail();        
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"IndexReduction.differentiateEqns failed!"}); 
      then
        fail();
  end matchcontinue;
end differentiateEqns;

public function getStructurallySingularSystemHandlerArg
"function: getStructurallySingularSystemHandlerArg
  author: Frenkel TUD 2012-04
  return initial the StructurallySingularSystemHandlerArg."
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
protected
  HashTableCG.HashTable ht;
  HashTable3.HashTable dht; 
  BackendDAE.StateOrder so;
algorithm
  ht := HashTableCG.emptyHashTable();
  dht := HashTable3.emptyHashTable();
  so := BackendDAE.STATEORDER(ht,dht);  
  ((so,_)) := BackendEquation.traverseBackendDAEEqns(BackendEquation.daeEqns(isyst),BackendDAETransform.traverseStateOrderFinder,(so,BackendVariable.daeVars(isyst)));
  outArg := (so,{},{},{});
end getStructurallySingularSystemHandlerArg;

/*****************************************
 No State deselection Method. 
 use the index 1/0 system as it is
 *****************************************/

public function noStateDeselection
"function: noStateDeselection
  author: Frenkel TUD 2012-04
  use the index 1/0 system as it is"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.DAEHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared) := (isyst,ishared);
end noStateDeselection;


/*****************************************
 dynamic state selection method .
 see 
 - Mattsson, S.E.; Söderlind, G.: A new technique for solving high-index differential-algebraic equations using dummy derivatives, Computer-Aided Control System Design, 1992. (CACSD),1992 IEEE Symposium on , pp.218-224, 17-19 Mar 1992
 - Mattsson, S.E.; Olsson, H; Elmqviste, H. Dynamic Selection of States in Dymola. In: Proceedings of the Modelica Workshop 2000, Lund, Sweden, Modelica Association, 23-24 Oct. 2000.
 - Mattsson, S.; Söderlind, G.: Index reduction in differential-Algebraic equations using dummy derivatives, SIAM J. Sci. Comput. 14, 677-692, 1993.
 *****************************************/

public function dynamicStateSelection
"function: dynamicStateSelection
  author: Frenkel TUD 2012-04
  dynamic state deselect of the system."
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.DAEHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared):=
  matchcontinue (isyst,ishared,inArg)
    local
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      Integer ne,ne1,nv1,newvars;
      BackendDAE.StateOrder so,so1;
      BackendDAE.ConstraintEquations orgEqnsLst,orgEqnsLst1,orgEqnsLst2;
      list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> orgEqnsLst_1;
      BackendDAE.Variables v,hov;
      array<Integer> vec1,vec2,ass1,ass2;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      list<DAE.ComponentRef> dummyStates;
      list<list<Integer>> comps;
      array<list<BackendDAE.Equation>> arraylisteqns;
      DAE.FunctionTree funcs;
           
    case (syst as BackendDAE.EQSYSTEM(orderedVars=v,matching=BackendDAE.MATCHING(ass1=ass1,ass2=ass2)),_,(so,orgEqnsLst))
      equation
        // do late Inline also in orgeqnslst
        funcs = BackendDAEUtil.getFunctions(ishared);
        (orgEqnsLst,_) = traverseOrgEqns(orgEqnsLst,(SOME(funcs),{DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()}),inlineEqn,{});
        // replace all der(x) with dx
        (orgEqnsLst,_) = traverseOrgEqnsExp(orgEqnsLst,so,replaceDerStatesStates,{});
        Debug.fcall(Flags.BLT_DUMP, print, "Dynamic State Selection\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDAETransform.dumpStateOrder, so); 
        // get highest order derivatives
        ne = BackendDAEUtil.systemSize(syst);
        hov = highestOrderDerivatives(v,so);
        Debug.fcall(Flags.BLT_DUMP, print, "highest Order Derivatives:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpVarsArray, hov);
        // iterate comps
        (syst,m,_) = BackendDAEUtil.getIncidenceMatrix(syst,ishared,BackendDAE.NORMAL());
        Debug.fcall(Flags.BLT_DUMP, print, "Index Reduced System:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem,syst);
        comps = BackendDAETransform.tarjanAlgorithm(syst);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpComponentsOLD,comps);
        dummyStates = processComps(comps,syst,ishared,ass2,(so,orgEqnsLst),hov,{});
        (syst,shared,_) = BackendDAETransform.addOrgEqntoDAE(orgEqnsLst,syst,ishared,so);
        newvars = listLength(dummyStates);
        vec1 = Util.arrayExpand(newvars, ass1, -1);
        vec2 = Util.arrayExpand(newvars, ass2, -1);
        (syst,shared) = addDummyStates(dummyStates,syst,shared,vec1,vec2);
        Debug.fcall(Flags.BLT_DUMP, print, "Full System:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem,syst);        
        ne1 = BackendDAEUtil.systemSize(syst);
        (syst,m,_) = BackendDAEUtil.getIncidenceMatrix(syst,shared,BackendDAE.NORMAL()); 
        Debug.fcall(Flags.BLT_DUMP, print, "hier!!!\n");
        Matching.matchingExternalsetIncidenceMatrix(ne1,ne1,m);
        BackendDAEEXT.matching(ne1,ne1,5,-1,0.0,1);
        BackendDAEEXT.getAssignment(vec2,vec1);      
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec1,vec2,{})); 
        Debug.fcall(Flags.BLT_DUMP, print, "DummyStates:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem,syst);       
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpShared,shared);       
     then 
       (syst,shared);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.dummyderivative failed!"});
      then
        fail();
  end matchcontinue;
end dynamicStateSelection;

protected function inlineEqn
  input tuple<BackendDAE.Equation, Inline.Functiontuple> inTpl;
  output tuple<BackendDAE.Equation, Inline.Functiontuple> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local  
      Inline.Functiontuple fnt;
      BackendDAE.Equation e;
    case ((e,fnt))
      equation
         e = Inline.inlineEq(e,fnt);
       then
        ((e,fnt));
    case inTpl then inTpl;
  end matchcontinue;
end inlineEqn;

protected function traverseOrgEqns
"function: traverseOrgEqns
  author: Frenkel TUD 2012-06
  add an equation to the ConstrainEquations."
  input BackendDAE.ConstraintEquations inOrgEqns;
  input Type_a inA;
  input FuncEqnType func;
  input BackendDAE.ConstraintEquations inAcc;
  output BackendDAE.ConstraintEquations outOrgEqns;
  output Type_a outA;
  partial function FuncEqnType
    input tuple<BackendDAE.Equation, Type_a> inTpl;
    output tuple<BackendDAE.Equation, Type_a> outTpl;
  end FuncEqnType;  
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
        (orgeqns,a) = BackendEquation.traverseBackendDAEEqnList(orgeqns,func,inA);
        (orgeqnslst,a) = traverseOrgEqns(rest,a,func,(e,orgeqns)::inAcc);
      then
        (orgeqnslst,a);
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
        (orgeqns,a) = BackendEquation.traverseBackendDAEExpsEqnList(orgeqns,func,inA);
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
    case inTpl then inTpl;
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

protected function highestOrderDerivatives
"function: highestOrderDerivatives
  author: Frenkel TUD 2012-05
  collect all highest order derivatives from ODE"
  input BackendDAE.Variables v;
  input BackendDAE.StateOrder so;
  output BackendDAE.Variables outVars;
algorithm
  ((_,_,outVars)) := BackendVariable.traverseBackendDAEVars(v,traversinghighestOrderDerivativesFinder,(so,v,BackendDAEUtil.emptyVars()));        
end highestOrderDerivatives;

protected function traversinghighestOrderDerivativesFinder
" function traversinghighestOrderDerivativesFinder
  autor: Frenkel TUD 2012-05
  helpber for highestOrderDerivatives"
 input tuple<BackendDAE.Var, tuple<BackendDAE.StateOrder,BackendDAE.Variables,BackendDAE.Variables>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendDAE.StateOrder,BackendDAE.Variables,BackendDAE.Variables>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr,dcr;
      BackendDAE.StateOrder so;
      BackendDAE.Variables vars,vars1,vars2;
    case ((v,(so,vars,vars1)))
      equation
        true = BackendVariable.isStateVar(v);
        cr = BackendVariable.varCref(v);
        failure(_ =  BackendDAETransform.getStateOrder(cr,so));
        vars2 = BackendVariable.addVar(v,vars1);
      then ((v,(so,vars,vars2)));
     case ((v,(so,vars,vars1)))
      equation
        true = BackendVariable.isStateVar(v);
        cr = BackendVariable.varCref(v);
        dcr =   BackendDAETransform.getStateOrder(cr,so);
        false = BackendVariable.isState(dcr,vars);
        vars2 = BackendVariable.addVar(v,vars1);
      then ((v,(so,vars,vars2)));   
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
  ((_,_,outVars)) := BackendVariable.traverseBackendDAEVars(derv,traversinglowerOrderDerivativesFinder,(so,v,BackendDAEUtil.emptyVars()));        
end lowerOrderDerivatives;

protected function traversinglowerOrderDerivativesFinder
" function traversinglowerOrderDerivativesFinder
  autor: Frenkel TUD 2012-05
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
  ((_,_,outVars,outDummyStates)) := BackendVariable.traverseBackendDAEVars(v,traversinghigerOrderDerivativesFinder,(so,vAll,BackendDAEUtil.emptyVars(),inDummyStates));        
end higerOrderDerivatives;

protected function traversinghigerOrderDerivativesFinder
" function traversinghigerOrderDerivativesFinder
  autor: Frenkel TUD 2012-06
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

protected function processComps
"function: processComps
  author: Frenkel TUD 2012-05
  process all strong connected components of the system and collect the 
  derived equations for dummy state selection"
  input list<list<Integer>> inComps;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input array<Integer> vec2;
  input BackendDAE.DAEHandlerArg inArg;
  input BackendDAE.Variables hov; 
  input list<DAE.ComponentRef> inDummyStates; 
  output list<DAE.ComponentRef> outDummyStates; 
algorithm
  outDummyStates := 
  matchcontinue(inComps,isyst,ishared,vec2,inArg,hov,inDummyStates)
    local 
      list<Integer> comp;
      list<list<Integer>> rest;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.StateOrder so;
      BackendDAE.ConstraintEquations orgEqnsLst;
      list<tuple<Integer, list<BackendDAE.Equation>, Integer>> orgEqnLevel;
      BackendDAE.Variables hov1,cv;
      list<DAE.ComponentRef> dummyStates;  
    case ({},_,_,_,_,_,_) then inDummyStates;
    case (comp::rest,_,_,_,(so,orgEqnsLst),_,_)
      equation
        comp = List.sort(comp,intGt);
        (orgEqnsLst,orgEqnLevel) = getOrgEqns(comp,orgEqnsLst,{},{},BackendEquation.daeEqns(isyst));
        orgEqnLevel = List.sort(orgEqnLevel,compareOrgEqn);
        cv = List.fold2(comp,getCompVars,vec2,(BackendVariable.daeVars(isyst),hov,so),BackendDAEUtil.emptyVars());
        (hov1,dummyStates) = processComp(orgEqnLevel,isyst,ishared,so,cv,hov,hov,inDummyStates);
        //(hov1,dummyStates,_) = processCompInv(orgEqnLevel,isyst,ishared,so,cv,hov,hov,inDummyStates);
        dummyStates = processComps(rest,isyst,ishared,vec2,(so,orgEqnsLst),hov1,dummyStates);
      then
        dummyStates; 
  end matchcontinue;
end processComps;

protected function compareOrgEqn
"function: compareOrgEqn
  author: Frenkel TUD 2011-05
  returns inA number of diverentations < inB number of diverentations"
  input tuple<Integer, list<BackendDAE.Equation>, Integer> inA;
  input tuple<Integer, list<BackendDAE.Equation>, Integer> inB;
  output Boolean lt;
algorithm
  lt := intLt(Util.tuple33(inA),Util.tuple33(inB));  
end compareOrgEqn;

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
        eqn = BackendDAEUtil.equationNth(eqns,e-1);
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
        (_,_) = BackendVariable.getVar(cr,hov);
      then
        BackendVariable.addVar(v,iCompVars);
    case (_,_,(vars,hov,so),_)
      equation
        v = BackendVariable.getVarAt(vars,vec2[e]);
        dcr = BackendVariable.varCref(v);
        false = BackendVariable.isStateVar(v);
        cr::_ = BackendDAETransform.getDerStateOrder(dcr,so);
        (v::_,_) = BackendVariable.getVar(cr, vars);        
        (_,_) = BackendVariable.getVar(cr,hov);
      then
        BackendVariable.addVar(v,iCompVars);
    else
      iCompVars;        
  end matchcontinue; 
end getCompVars;

protected function processComp
"function: getCompVars
  author: Frenkel TUD 2012-05
  process all derivation levels of a strong connected component and calls for it the dummy
  state selection"
  input list<tuple<Integer, list<BackendDAE.Equation>, Integer>> orgEqnsLst;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StateOrder so; 
  input BackendDAE.Variables cvars;  
  input BackendDAE.Variables hov;  
  input BackendDAE.Variables hov1;  
  input list<DAE.ComponentRef> inDummyStates;  
  output BackendDAE.Variables outhov;   
  output list<DAE.ComponentRef> outDummyStates;   
algorithm
  (outhov,outDummyStates) := 
  matchcontinue(orgEqnsLst,isyst,ishared,so,cvars,hov,hov1,inDummyStates)
    local 
      list<BackendDAE.Equation> eqnslst;
      list<tuple<Integer, list<BackendDAE.Equation>, Integer>> orgeqns;
      BackendDAE.Variables lov,hov_1;
      list<DAE.ComponentRef> dummyStates;
      BackendDAE.EquationArray eqns;
      list<Integer> eqnindxlst;
    case ({},_,_,_,_,_,_,_) then (hov1,inDummyStates);
    case (_,_,_,_,_,_,_,_)
      equation
        (orgeqns,eqnslst,eqnindxlst) = getOrgEqn(orgEqnsLst,{},{},{});
        eqns = BackendDAEUtil.listEquation(eqnslst);
        (hov_1,dummyStates,lov) = selectDummyDerivatives(cvars,BackendVariable.numVariables(cvars),eqns,BackendDAEUtil.equationSize(eqns),eqnindxlst,hov1,inDummyStates,ishared,BackendDAEUtil.emptyVars());
        // get derivatives one order less
        lov = lowerOrderDerivatives(lov,BackendVariable.daeVars(isyst),so);
        // call again with original equations of derived equations 
        (hov_1,dummyStates) = processComp(orgeqns,isyst,ishared,so,lov,lov,hov_1,dummyStates);
      then
        (hov_1,dummyStates); 
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
  output BackendDAE.Variables outhov;   
  output list<DAE.ComponentRef> outDummyStates;  
  output BackendDAE.Variables outStates;   
algorithm
  (outhov,outDummyStates,outStates) := 
  matchcontinue(orgEqnsLst,isyst,ishared,so,cvars,hov,hov1,inDummyStates)
    local 
      list<BackendDAE.Equation> eqnslst;
      list<tuple<Integer, list<BackendDAE.Equation>, Integer>> orgeqns;
      BackendDAE.Variables vars,lov,hov_1;
      list<DAE.ComponentRef> dummyStates;
      list<DAE.ComponentRef> crlst;
      BackendDAE.EquationArray eqns;
      list<Integer> eqnindxlst;
    case ({},_,_,_,_,_,_,_) then (hov1,inDummyStates,BackendDAEUtil.emptyVars());
    case (_,_,_,_,_,_,_,_)
      equation
        (orgeqns,eqnslst,eqnindxlst) = getOrgEqn(orgEqnsLst,{},{},{});
        // get all derivatives one order less
        lov = lowerOrderDerivatives(cvars,BackendVariable.daeVars(isyst),so);
        // gall again with original equations of derived equations 
        (hov_1,dummyStates,vars) = processCompInv(orgeqns,isyst,ishared,so,lov,lov,hov1,inDummyStates);
        // remove dummy states from candidates    
        crlst = BackendVariable.getAllCrefFromVariables(vars);
        vars = BackendVariable.deleteCrefs(crlst,cvars);
        Debug.fcall(Flags.BLT_DUMP, print,"Vars:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpVarsArray,vars);
        // select dummy derivatives
        eqns = BackendDAEUtil.listEquation(eqnslst);
        (hov_1,dummyStates,lov) = selectDummyDerivatives(vars,BackendVariable.numVariables(vars),eqns,BackendDAEUtil.equationSize(eqns),eqnindxlst,hov_1,dummyStates,ishared,BackendDAEUtil.emptyVars());
        // get derivatives 
        (lov,dummyStates) = higerOrderDerivatives(lov,BackendVariable.daeVars(isyst),so,dummyStates);
        Debug.fcall(Flags.BLT_DUMP, print,"HigerOrderVars:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpVarsArray,lov);
      then
        (hov_1,dummyStates,lov); 
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
    
    case ({},inEqns,_,_) then (listReverse(inOrgEqns1),listReverse(inEqns),listReverse(inEqnindxlst));
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
  input BackendDAE.Shared ishared;
  input BackendDAE.Variables inLov;
  output BackendDAE.Variables outhov;
  output list<DAE.ComponentRef> outDummyStates;
  output BackendDAE.Variables outlov;
algorithm
  (outhov,outDummyStates,outlov) := 
  matchcontinue(vars,varSize,eqns,eqnsSize,eqnindxlst,hov,inDummyStates,ishared,inLov)
      local 
        BackendDAE.Variables hov1,lov,vars1;
        list<DAE.ComponentRef> dummystates,crlst;
        BackendDAE.Var v;
        DAE.ComponentRef cr,dcr;
        BackendDAE.IncidenceMatrix m;
        BackendDAE.IncidenceMatrixT mT;
        array<Integer> vec1,vec2;
        Integer rang,nv,nvd,ned;
        BackendDAE.EqSystem syst;
        list<BackendDAE.Var> varlst;
        list<tuple<DAE.ComponentRef, Integer>> states;
        BackendDAE.AdjacencyMatrixEnhanced me;
        BackendDAE.AdjacencyMatrixTEnhanced meT;  
        array<BackendDAE.MultiDimEquation> ae;     
    case(_,_,_,_,_,_,_,_,_)
      equation
        // if no vars then there is nothing do do
        true = intEq(varSize,0);
      then
        (hov,inDummyStates,inLov);
    case(_,_,_,_,_,_,dummystates,_,_)
      equation
        // if there is only one var select it because there is no choice
        true = intEq(varSize,1);
        true = intEq(eqnsSize,1);
        Debug.fcall(Flags.BLT_DUMP, print, "single var and eqn\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem, BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING()));
        v = BackendVariable.getVarAt(vars,1);
        cr = BackendVariable.varCref(v);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrCrefStr, ("Select ",cr," as dummyState\n"));
        hov1 = BackendVariable.deleteVar(cr,hov);
        lov = BackendVariable.addVar(v,inLov);
      then
        (hov1,cr::dummystates,lov);
    case(_,_,_,_,_,_,_,_,_)
      equation
        // if eqnsSize is equal to varsize all variables are dummy derivatives no choise
        true = intGt(varSize,1);
        true = intEq(eqnsSize,varSize);
        Debug.fcall(Flags.BLT_DUMP, print, "equal var and eqn size\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem, BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING()));
        varlst = BackendDAEUtil.varList(vars);
        crlst = List.map(varlst,BackendVariable.varCref);
        states = List.threadTuple(crlst,List.intRange2(1,varSize));
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));
        (hov1,lov,dummystates) = selectDummyStates(states,1,eqnsSize,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov); 
    case(_,_,_,_,_,_,_,_,_)
      equation
        // try to select dummy vars
        true = intGt(varSize,1);
        false = intGt(eqnsSize,varSize);
        varlst = BackendDAEUtil.varList(vars);
        varlst = List.filter(varlst, varStateSelectAlways);
        true = intGt(eqnsSize,listLength(varlst));
        Debug.fcall(Flags.BLT_DUMP, print, "select dummy vars from stateselection\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem, BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING()));
        crlst = List.map(varlst,BackendVariable.varCref);
        states = List.threadTuple(crlst,List.intRange2(1,varSize));
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));
        (hov1,lov,dummystates) = selectDummyStates(states,1,eqnsSize,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov); 
    case(_,_,_,_,_,_,_,BackendDAE.SHARED(arrayEqs=ae),_)
      equation
        // try to select dummy vars
        true = intGt(varSize,1);
        false = intGt(eqnsSize,varSize);
        Debug.fcall(Flags.BLT_DUMP, print, "try to select dummy vars with natural matching\n");
        
        // sort vars with heuristic
        syst = BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING());
        (syst,_,_) =  BackendDAEUtil.getIncidenceMatrix(syst,ishared,BackendDAE.NORMAL());
        varlst = BackendDAEUtil.varList(vars);
        crlst = List.map(varlst,BackendVariable.varCref);
        states = List.threadTuple(crlst,List.intRange2(1,varSize));
        vars1 = BackendDAETransform.sortStateCandidatesVars(syst);
               
        varlst = List.map1(BackendDAEUtil.varList(vars1),BackendVariable.setVarKind,BackendDAE.VARIABLE());   
        vars1 = BackendDAEUtil.listVar1(varlst);         
        syst = BackendDAE.EQSYSTEM(vars1,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING());
        (me,meT) =  BackendDAEUtil.getAdjacencyMatrixEnhanced(syst,ishared);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpAdjacencyMatrixEnhanced,me);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpAdjacencyMatrixTEnhanced,meT);       
        (hov1,dummystates,lov) = selectDummyDerivatives1(me,meT,vars1,varSize,eqns,eqnsSize,eqnindxlst,hov,inDummyStates,ishared,inLov);
      then
        (hov1,dummystates,lov); 
    case(_,_,_,_,_,_,_,_,_)
      equation
        // try to select dummy vars heuristic based
        true = intGt(varSize,1);
        false = intGt(eqnsSize,varSize);
        Debug.fcall(Flags.BLT_DUMP, print, "try to select dummy vars heuristic based\n");
        (syst,_,_) = BackendDAEUtil.getIncidenceMatrix(BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING()),ishared,BackendDAE.NORMAL());
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem, syst);
        varlst = BackendDAEUtil.varList(vars);
        crlst = List.map(varlst,BackendVariable.varCref);
        states = List.threadTuple(crlst,List.intRange2(1,varSize));
        states = BackendDAETransform.sortStateCandidates(states,syst);
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));
        (hov1,lov,dummystates) = selectDummyStates(states,1,eqnsSize,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov);        
    case(_,_,_,_,_,_,_,_,_)
      equation
        // if ther are more equations than vars, singular system
        true = intGt(varSize,1);
        true = intGt(eqnsSize,varSize);
        print("Structural singular system:\n");
        BackendDump.dumpEqSystem(BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING()));
      then
        fail();
  end matchcontinue;
end selectDummyDerivatives;

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
  input BackendDAE.Shared ishared;
  input BackendDAE.Variables inLov;
  output BackendDAE.Variables outhov;
  output list<DAE.ComponentRef> outDummyStates;
  output BackendDAE.Variables outlov;
algorithm
  (outhov,outDummyStates,outlov) := 
  matchcontinue(me,meT,vars,varSize,eqns,eqnsSize,eqnindxlst,hov,inDummyStates,ishared,inLov)
      local 
        BackendDAE.Variables hov1,lov;
        list<DAE.ComponentRef> dummystates,crlst;
        BackendDAE.Var v;
        DAE.ComponentRef cr,dcr;
        BackendDAE.IncidenceMatrix m;
        BackendDAE.IncidenceMatrixT mT;
        array<Integer> vec1,vec2;
        Integer rang,nv,nvd,ned;
        BackendDAE.EqSystem syst;
        list<BackendDAE.Var> varlst;
        list<tuple<DAE.ComponentRef, Integer>> states; 
        array<BackendDAE.MultiDimEquation> ae;     
    case(_,_,_,_,_,_,_,_,_,BackendDAE.SHARED(arrayEqs=ae),_)
      equation
        m = incidenceMatrixfromEnhanced(me);
        mT = incidenceMatrixfromEnhanced(meT);  
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem, BackendDAE.EQSYSTEM(vars,eqns,SOME(m),SOME(mT),BackendDAE.NO_MATCHING()));
        // BackendDump.dumpArrayEqns(arrayList(ae), 1);
        Matching.matchingExternalsetIncidenceMatrix(eqnsSize,varSize,mT);
        BackendDAEEXT.matching(eqnsSize,varSize,3,-1,1.0,1);
        vec1 = arrayCreate(eqnsSize,-1);
        vec2 = arrayCreate(varSize,-1);
        BackendDAEEXT.getAssignment(vec2,vec1);         
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching,vec1);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching,vec2);
        states = checkAssignment(1,varSize,vec2,vars,{});
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));
        rang = eqnsSize-listLength(states);
        true = intEq(rang,0);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrIntStrIntStr, ("Select ",varSize-eqnsSize," from ",varSize-rang,"\n"));        
        (hov1,lov,dummystates) = selectDummyStates(states,1,eqnsSize,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov); 
    case(_,_,_,_,_,_,_,_,_,BackendDAE.SHARED(arrayEqs=ae),_)
      equation
        m = incidenceMatrixfromEnhanced1(me);
        mT = incidenceMatrixfromEnhanced1(meT);  
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem, BackendDAE.EQSYSTEM(vars,eqns,SOME(m),SOME(mT),BackendDAE.NO_MATCHING()));
        // BackendDump.dumpArrayEqns(arrayList(ae), 1);
        Matching.matchingExternalsetIncidenceMatrix(eqnsSize,varSize,mT);
        BackendDAEEXT.matching(eqnsSize,varSize,3,-1,1.0,1);
        vec1 = arrayCreate(eqnsSize,-1);
        vec2 = arrayCreate(varSize,-1);
        BackendDAEEXT.getAssignment(vec2,vec1);         
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching,vec1);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching,vec2);
        states = checkAssignment(1,varSize,vec2,vars,{});
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));
        rang = eqnsSize-listLength(states);
        true = intEq(rang,0);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrIntStrIntStr, ("Select ",varSize-eqnsSize," from ",varSize-rang,"\n"));        
        (hov1,lov,dummystates) = selectDummyStates(states,1,eqnsSize,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov);             
  end matchcontinue;
end selectDummyDerivatives1;

protected function varStateSelectAlways
"function: varStateSelectAlways
  author: Frenkel TUD 2012-06
  fails if var is StateSelect.always"
  input BackendDAE.Var v;
algorithm
  _ := match(v)
    case BackendDAE.VAR(values = NONE()) then ();
    case BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.NEVER())))) then ();
    case BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.AVOID())))) then ();
    case BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.DEFAULT())))) then ();
    case BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.PREFER())))) then ();
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

protected function checkAssignment
"function: checkAssignment
  author: Frenkel TUD 2012-05
  selects the assigned vars"
  input Integer indx;
  input Integer len;
  input array<Integer> ass;
  input BackendDAE.Variables vars;
  input list<tuple<DAE.ComponentRef, Integer>> inUnassigned;
  output list<tuple<DAE.ComponentRef, Integer>> outUnassigned;
algorithm
  outUnassigned := matchcontinue(indx,len,ass,vars,inUnassigned)
    local 
      Integer r,c;
      DAE.ComponentRef cr;
    case (_,_,_,_,_)
      equation
        true = intGt(indx,len);
      then
        inUnassigned;
    case (_,_,_,_,_)
      equation
        r = ass[indx];
        true = intGt(r,0);
        BackendDAE.VAR(varName=cr) = BackendVariable.getVarAt(vars,indx);
      then
        checkAssignment(indx+1,len,ass,vars,(cr,indx)::inUnassigned);
    case (_,_,_,_,_)
      then
        checkAssignment(indx+1,len,ass,vars,inUnassigned);
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
          hov1 = BackendVariable.deleteVar(cr,hov);
          lov = BackendVariable.addVar(v,inLov);
         (hov1,lov, dummystates) = selectDummyStates(rest,i+1,nstates,vars,hov1,lov,cr::inDummyStates);
        then
          (hov1,lov, dummystates);
  end matchcontinue;    
end selectDummyStates;

protected function addDummyStates
"function: addDummyStates
  author: Frenkel TUD 2012-05
  add the dummy states to the system"
  input list<DAE.ComponentRef> dummyStates;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input array<Integer> inAss1;
  input array<Integer> inAss2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;  
algorithm
  (osyst,oshared) := 
  match (dummyStates,isyst,ishared,inAss1,inAss2)
    local
     DAE.ComponentRef cr,dcr;
     BackendDAE.EqSystem syst;
     BackendDAE.Shared shared;
     array<Integer> vec1,vec2;
     list<DAE.ComponentRef> rest;
     Integer i,e;
    case ({},_,_,_,_) then (isyst,ishared);
    case (cr::rest,_,_,_,_)
      equation
        (_,i::_) = BackendVariable.getVarDAE(cr,isyst);
        (dcr,syst,shared) = BackendDAETransform.makeDummyState(cr,i,isyst,ishared);
        e = inAss1[i];
        _ = Debug.bcallret3(intGt(e,0), arrayUpdate, inAss1, e, -1, inAss1);
        _ = Debug.bcallret3(intGt(i,0), arrayUpdate, inAss2, i, -1, inAss2);
        (syst,shared) = addDummyStates(rest,syst,shared,inAss1,inAss2);
      then 
        (syst,shared);
  end match;
end addDummyStates;

/*****************************************
 dummy derivative index reduction method . 
 *****************************************/

public function dummyderivative
"function: dummyderivative
  author: Frenkel TUD 2012-04
  dummy derivative deselect on heurisitics states
  of the system to get at least a index 1 system ."
  input list<Integer> eqns;
  input Integer actualEqn;
  input BackendDAE.DAEHandlerJop inJop;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.Assignments inAssignments1;
  input BackendDAE.Assignments inAssignments2;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
  input BackendDAE.DAEHandlerArg inArg;
  output list<Integer> changedEqns;
  output Integer continueEqn;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2; 
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
  output BackendDAE.DAEHandlerArg outArg;
algorithm
  (changedEqns,continueEqn,osyst,oshared,outAssignments1,outAssignments2,outDerivedAlgs,outDerivedMultiEqn,outArg):=
  matchcontinue (eqns,actualEqn,inJop,isyst,ishared,inAssignments1,inAssignments2,inDerivedAlgs,inDerivedMultiEqn,inArg)
    local
      list<Integer> diff_eqns,eqns_1,deqns,reqns,changedeqns,eqnsindxs,stateindx;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.Value nv,nf,stateno,newDummyVar,delta,ne,ne1,nv1;
      DAE.ComponentRef state,dummy_der;
      list<String> es;
      String es_1;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1;
      BackendDAE.StateOrder so,so1;
      BackendDAE.ConstraintEquations orgEqnsLst,orgEqnsLst1,orgEqnsLst2;
      list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> orgEqnsLst_1;
      BackendDAE.EquationArray eqnsarr_1,eqnsarr,seqns,ie;
      BackendDAE.Variables v,kv,ev,hov;
      BackendDAE.AliasVariables av;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      array<DAE.Algorithm> al,al1;
      list<BackendDAE.WhenClause> wclst,wclst1;
      list<BackendDAE.ZeroCrossing> zc;
      BackendDAE.ExternalObjectClasses eoc;    
      BackendDAE.Assignments ass1,ass2,ass1_1,ass2_1; 
      array<Integer> vec1,vec2;
      String smeqs;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      list<DAE.ComponentRef> states;
      array<Boolean> aediff;
      list<DAE.ComponentRef> dummyStates;
      list<list<Integer>> comps;
      Integer newvars;
      array<list<BackendDAE.Equation>> arraylisteqns;
      DAE.FunctionTree funcs;
           
    case (eqns,_,BackendDAE.REDUCE_INDEX(),syst,shared  as BackendDAE.SHARED(arrayEqs=ae),_,_,derivedAlgs,derivedMultiEqn,(so,orgEqnsLst))
      equation
        // BackendDAEUtil.profilerstart1();
        // check by count vars of equations, if len(eqns) > len(vars) stop because of structural singular system
        // the check musst fist split the equations in independent subgraphs
        // unnecessary
        diff_eqns = BackendDAEEXT.getDifferentiatedEqns();
        eqns_1 = List.setDifferenceOnTrue(eqns, diff_eqns, intEq);
        true = intGt(listLength(eqns_1),0);
        //eqns_1 = List.sort(eqns_1,intGt);
        //dumpUnmatched(List.intRange(BackendDAEUtil.systemSize(syst)),syst,inAssignments1,inAssignments2,"test_" +& intString(listNth(eqns,0)) +& ".grahpml");
        //dumpUnmatched(eqns,syst,inAssignments1,inAssignments2,"test_" +& intString(listNth(eqns,0)) +& ".grahpml");
        // 
        // BackendDump.dumpEqSystem(syst);
        // BackendDump.dumpShared(shared);
        // print("Before Index Reduction\n");
        // BackendDump.dumpMatching(BackendDAETransform.assignmentsVector(inAssignments1));        
        // BackendDump.dumpMatching(BackendDAETransform.assignmentsVector(inAssignments2));        
         //print("Reduce Index\nmarked equations(" +& intString(listLength(eqns_1)) +& "): ");
         //BackendDump.debuglst((eqns_1,intString," ","\n"));

        (states,stateindx,delta) = statesInEqns(eqns_1,syst,inAssignments2,{},{},0);
        // print("States (" +& intString(listLength(states)) +& ", " +& intString(delta) +&  "): ");
        // print(stringDelimitList(List.map(states,ComponentReference.printComponentRefStr),", "));print("\n");
        
        Debug.fcall(Flags.BLT_DUMP, print, "Reduce Index\nmarked equations: ");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst, (eqns_1,intString," ","\ndiff equations: "));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst, (diff_eqns,intString," ","\n"));
        Debug.fcall(Flags.BLT_DUMP, print, BackendDump.dumpMarkedEqns(syst, eqns_1));
        true = intGt(listLength(eqns),0);
        (syst,shared,ass1_1,ass2_1,derivedAlgs1,derivedMultiEqn1,so1,orgEqnsLst2,changedeqns) = simpleIndexReductiondifferentiateEqns(syst,shared,eqns_1,inAssignments1,inAssignments2,derivedAlgs,derivedMultiEqn,so,orgEqnsLst,{});
        delta = List.fold(changedeqns,intMin,actualEqn);
        //BackendDump.dumpEqSystem(syst);
        //BackendDump.dumpShared(shared);
        // BackendDAEUtil.profilerstop1();
      then
       (changedeqns,delta,syst,shared,ass1_1,ass2_1,derivedAlgs1,derivedMultiEqn1,(so1,orgEqnsLst2));

    case (eqns,_,BackendDAE.REDUCE_INDEX(),syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),shared as BackendDAE.SHARED(arrayEqs=ae),ass1,ass2,derivedAlgs,derivedMultiEqn,(so,orgEqnsLst))
      equation
        diff_eqns = BackendDAEEXT.getDifferentiatedEqns();
        eqns_1 = List.setDifferenceOnTrue(eqns, diff_eqns, intEq);
        true = intEq(listLength(eqns_1),0);
        Debug.fcall(Flags.BLT_DUMP, print, "Reduce Index\ndiff equations: ");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst, (diff_eqns,intString," ","\nmarked equations: "));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst, (eqns,intString," ","\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dump, BackendDAE.DAE({syst},shared));
        vec1 = BackendDAETransform.assignmentsVector(ass1);
        vec2 = BackendDAETransform.assignmentsVector(ass2);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching, vec1);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching, vec2);   
        BackendDump.dumpIncidenceMatrix(m);
        BackendDump.dumpIncidenceMatrixT(mt);
        //Debug.fcall(Flags.BLT_DUMP, dumpEqnsX, (orgEqnsLst,ae));
      then
        fail(); 

    case (eqns,_,BackendDAE.STARTSTEP(),syst,shared,ass1,ass2,derivedAlgs,derivedMultiEqn,(so,orgEqnsLst))
      equation
        // BackendDAEUtil.profilerstart1();
        Debug.fcall(Flags.BLT_DUMP, print, "Reduce Index Startstep\n");
        ((so,_)) = BackendEquation.traverseBackendDAEEqns(BackendEquation.daeEqns(syst),BackendDAETransform.traverseStateOrderFinder,(so,BackendVariable.daeVars(syst)));
        Debug.fcall(Flags.BLT_DUMP, BackendDAETransform.dumpStateOrder, so); 
        // BackendDump.dumpEqSystem(syst);
        // BackendDump.dumpMatching( BackendDAETransform.assignmentsVector(ass1));
        // BackendDump.dumpMatching( BackendDAETransform.assignmentsVector(ass2));         
        // BackendDAEUtil.profilerstop1();      
      then
         ({},actualEqn,syst,shared,ass1,ass2,derivedAlgs,derivedMultiEqn,(so,orgEqnsLst));
    case (eqns,_,BackendDAE.ENDSTEP(),syst as BackendDAE.EQSYSTEM(orderedVars=v),_,BackendDAE.ASSIGNMENTS(arrOfIndices=vec1),BackendDAE.ASSIGNMENTS(arrOfIndices=vec2),derivedAlgs,derivedMultiEqn,(so,orgEqnsLst))
     equation
       //BackendDAEUtil.profilerstart2();
        // inline functions
        BackendDAE.DAE({syst},shared) = Inline.inlineCalls({DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()},BackendDAE.DAE({isyst},ishared));

        //BackendDAE.DAE({syst},shared as BackendDAE.SHARED(arrayEqs=ae)) = BackendDAEOptimize.inlineArrayEqn(BackendDAE.DAE({syst},shared));
        //arraylisteqns = Util.arrayMap(ae,BackendDAEOptimize.getScalarArrayEqns);
        //(orgEqnsLst,_) = BackendDAETransform.traverseOrgEqns(orgEqnsLst,(arraylisteqns,1,{}),BackendDAEOptimize.replaceScalarArrayEqns,{});

        funcs = BackendDAEUtil.getFunctions(ishared);
        (orgEqnsLst,_) = traverseOrgEqns(orgEqnsLst,(SOME(funcs),{DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()}),inlineEqn,{});
        (orgEqnsLst,_) = traverseOrgEqnsExp(orgEqnsLst,so,replaceDerStatesStates,{});
        
        Debug.fcall(Flags.BLT_DUMP, BackendDAETransform.dumpStateOrder, so); 
        Debug.fcall(Flags.BLT_DUMP, print, "Reduce Index Endstep\n");
        ne = BackendDAEUtil.systemSize(syst);
        hov = highestOrderDerivatives(v,so);
        Debug.fcall(Flags.BLT_DUMP, print, "highest Order Derivatives:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpVarsArray, hov);
        // iterate comps
        (syst,m,_) = BackendDAEUtil.getIncidenceMatrix(syst,shared,BackendDAE.NORMAL());

        //Matching.matchingExternalsetIncidenceMatrix(ne,ne,m);
        //BackendDAEEXT.matching(ne,ne,5,-1,1.0,1);
        //vec1 = arrayCreate(ne,-1);
        //vec2 = arrayCreate(ne,-1);
        //BackendDAEEXT.getAssignment(vec2,vec1); 

        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec1,vec2,{})); 
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem,syst);
        comps = BackendDAETransform.tarjanAlgorithm(syst);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpComponentsOLD,comps);
        dummyStates = processComps(comps,syst,shared,vec2,(so,orgEqnsLst),hov,{});
        (syst,shared,_) = BackendDAETransform.addOrgEqntoDAE(orgEqnsLst,syst,shared,so);
        newvars = listLength(dummyStates);
        vec1 = Util.arrayExpand(newvars, vec1, -1);
        vec2 = Util.arrayExpand(newvars, vec2, -1);
        (syst,shared) = addDummyStates(dummyStates,syst,shared,vec1,vec2);
        ne1 = BackendDAEUtil.systemSize(syst);
        eqns_1 = Util.if_(intGt(ne1,ne),List.intRange2(ne+1,ne1),{}); 
        (syst,m,_) = BackendDAEUtil.getIncidenceMatrix(syst,shared,BackendDAE.NORMAL()); 
        Matching.matchingExternalsetIncidenceMatrix(ne1,ne1,m);
        BackendDAEEXT.matching(ne1,ne1,5,-1,0.0,1);
        BackendDAEEXT.getAssignment(vec2,vec1);      
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec1,vec2,{})); 
        Debug.fcall(Flags.BLT_DUMP, print, "DummyStates:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem,syst);       
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpShared,shared);       
     then 
       (eqns_1,actualEqn,syst,shared,BackendDAE.ASSIGNMENTS(ne1,ne1,vec1),BackendDAE.ASSIGNMENTS(ne1,ne1,vec2),derivedAlgs,derivedMultiEqn,(so,orgEqnsLst));

    case (eqns,_,BackendDAE.REDUCE_INDEX(),syst,shared,_,_,_,_,_)
      equation
        diff_eqns = BackendDAEEXT.getDifferentiatedEqns();
        eqns_1 = List.setDifferenceOnTrue(eqns, diff_eqns, intEq);
        es = List.map(eqns_1, intString);
        es_1 = stringDelimitList(es, ", ");
        print("eqns =");print(es_1);print("\n");
        //({},_) = statesInEqns(eqns_1, syst);
        print("no states found in equations:");
        BackendDump.printEquations(eqns_1, syst);
        print("differentiated equations:");
        BackendDump.printEquations(diff_eqns,syst);
        print("Variables :");
        print(stringDelimitList(List.map(BackendDAEEXT.getMarkedVariables(),intString),", "));
        print("\n");
      then
        fail();
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.dummyderivative failed!"});
      then
        fail();
  end matchcontinue;
end dummyderivative;

protected function getIncidencefromJac
  input list<tuple<Integer, Integer, BackendDAE.Equation>> sysjac;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input BackendDAE.Variables vars;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
algorithm
  (outM,outMT) := matchcontinue(sysjac,inM,inMT,vars)
    local
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mT;
      Integer row,col,fcol,frow;
      Boolean b;
      DAE.Exp e;
    case({},_,_,_) then (inM,inMT);
    case((row,col,BackendDAE.RESIDUAL_EQUATION(exp = e))::rest,_,_,_)
      equation
        false = Expression.isZero(e);
        ((_,(b,_))) = Expression.traverseExpTopDown(e, traversingVarsFinder,(false,vars));
        ((fcol,frow)) = Util.if_(b,(-col,-row),(col,row));
        m = arrayUpdate(inM,row,listAppend(inM[row],{fcol}));
        mT = arrayUpdate(inMT,col,listAppend(inMT[col],{frow}));
        (m,mT) = getIncidencefromJac(rest,m,mT,vars);
      then
        (m,mT);   
    case(_::rest,_,_,_)
      equation
        (m,mT) = getIncidencefromJac(rest,inM,inMT,vars);
      then
        (m,mT); 
  end matchcontinue;     
end getIncidencefromJac;

protected function traversingVarsFinder "
Author: Frenkel 2012-05"
  input tuple<DAE.Exp, tuple<Boolean,BackendDAE.Variables> > inExp;
  output tuple<DAE.Exp, Boolean, tuple<Boolean,BackendDAE.Variables> > outExp;
algorithm 
  outExp := matchcontinue(inExp)
    local
      DAE.Exp e;
      Boolean b;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
    case((e as DAE.CALL(path = Absyn.IDENT(name = "der")), (b,vars)))
      then ((e,false,(b,vars))); 
    // unkown var
    case((e as DAE.CREF(componentRef=cr), (_,vars)))
      equation
        (var::_,_::_)= BackendVariable.getVar(cr, vars);
      then ((e,false,(true,vars)));          
    case((e,(b,vars))) then ((e,not b,(b,vars)));    
  end matchcontinue;
end traversingVarsFinder;

protected function statesInEqns
"function: statesInEqns
  author: Frenkel TUD - 2012-04"
  input list<Integer> inEqnsLst;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Assignments ass2;
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input list<Integer> inIntegerLst;  
  input Integer inCount;
  output list<DAE.ComponentRef> outExpComponentRefLst;
  output list<Integer> outIntegerLst;
  output Integer outcount;
algorithm
  (outExpComponentRefLst,outIntegerLst,outcount):=
  matchcontinue (inEqnsLst,syst,ass2,inExpComponentRefLst,inIntegerLst,inCount)
    local
      list<DAE.ComponentRef> res1,res1_1;
      list<BackendDAE.Value> res2,res2_1,rest;
      Integer e,c,c_1;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Equation eqn;
      array<Integer> vec2;
      
    case ({},_,_,_,_,_) then (inExpComponentRefLst,inIntegerLst,inCount);
    case ((e :: rest),syst as BackendDAE.EQSYSTEM(orderedVars = vars,orderedEqs = eqns,m=SOME(m)),BackendDAE.ASSIGNMENTS(arrOfIndices=vec2),_,_,_)
      equation
        // (res1,res2) = statesInVars(m[e],vars,{},{});
        c_1 = Util.if_(intLt(BackendDAETransform.getAssigned(e,ass2),1),1,0);
        // print("States in Eqn " +& intString(e) +& " , " +& intString(BackendDAETransform.getAssigned(e,ass2)) +&  ": ");
        // print(stringDelimitList(List.map(res1,ComponentReference.printComponentRefStr),", "));print("\n");
        // eqn = BackendDAEUtil.equationNth(eqns, e-1);        
        // print(BackendDump.equationStr(eqn)); print("\n");         
        (res1,res2) = statesInVars(m[e],vars,inExpComponentRefLst,inIntegerLst);
        (res1_1,res2_1,c) = statesInEqns(rest,syst,ass2,res1,res2,inCount+c_1);
      then
        (res1_1,res2_1,c);
    case ((e :: rest),BackendDAE.EQSYSTEM(orderedEqs = eqns),_,_,_,_)
      equation
       print("IndexReduction.statesInEqns failed!");     
      then
        fail();
  end matchcontinue;
end statesInEqns;

protected function statesInVars 
"function: statesInVars
  author: Frenkel TUD 2012-04"
  input list<Integer> inVarsLst;
  input BackendDAE.Variables vars;
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input list<Integer> inIntegerLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
  output list<Integer> outIntegerLst;
algorithm
  (outExpComponentRefLst,outIntegerLst):=  
  matchcontinue (inVarsLst,vars,inExpComponentRefLst,inIntegerLst)
    local
      Integer v;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> res1;
      list<BackendDAE.Value> res2,rest;
    case ({},vars,_,_) then (inExpComponentRefLst,inIntegerLst);
    case ((v :: rest),vars,_,_)
      equation
        true = intLt(v,0);
        true = List.notMember(v,inIntegerLst);
        BackendDAE.VAR(varName = cr) = BackendVariable.getVarAt(vars,intAbs(v));
        (res1,res2) = statesInVars(rest,vars,(cr :: inExpComponentRefLst),(v :: inIntegerLst));
      then
        (res1,res2);
    case (_ :: rest,vars,_,_)
      equation
        (res1,res2) = statesInVars(rest,vars,inExpComponentRefLst,inIntegerLst);
      then
        (res1,res2);
  end matchcontinue;
end statesInVars;

protected function simpleIndexReductiondifferentiateEqns
"function: simpleIndexReductiondifferentiateEqns
  author: Frenkel TUD 2011-05
  differentiates the constraint equations for 
  simple Index Reduction method."
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> inIntegerLst6;
  input BackendDAE.Assignments inAss1;
  input BackendDAE.Assignments inAss2;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
  input BackendDAE.StateOrder inStateOrd;
  input BackendDAE.ConstraintEquations inOrgEqnsLst;
  input list<Integer> inchangedEqns;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.Assignments outAss1;
  output BackendDAE.Assignments outAss2;  
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
  output BackendDAE.StateOrder outStateOrd;
  output BackendDAE.ConstraintEquations outOrgEqnsLst;
  output list<Integer> outchangedEqns;
algorithm
  (osyst,oshared,outAss1,outAss2,outDerivedAlgs,outDerivedMultiEqn,outStateOrd,outOrgEqnsLst,outchangedEqns):=
  matchcontinue (isyst,ishared,inIntegerLst6,inAss1,inAss2,inDerivedAlgs,inDerivedMultiEqn,inStateOrd,inOrgEqnsLst,inchangedEqns)
    local
      BackendDAE.Value e_1,e,e1,i,l,newvar,assarg,i1,sl,eqnss,eqnss1;
      BackendDAE.Equation eqn,eqn_1;
      BackendDAE.EquationArray eqns_1,eqns,seqns,ie;
      list<BackendDAE.Value> es,lst,slst,ilst,eqnslst,eqnslst1,changedEqns;
      BackendDAE.Variables v,kv,ev,v1;
      BackendDAE.AliasVariables av;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      array<DAE.Algorithm> al,al1;
      array<DAE.Constraint> constrs;
      array<BackendDAE.ComplexEquation> complEqs;
      BackendDAE.EventInfo einfo;
      list<BackendDAE.WhenClause> wclst,wclst1;
      list<BackendDAE.ZeroCrossing> zc;
      BackendDAE.ExternalObjectClasses eoc;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1;
      BackendDAE.StateOrder so,so1;
      DAE.ComponentRef cr,dcr,cr1;
      BackendDAE.ConstraintEquations orgEqnsLst;
      list<BackendDAE.Var> vlst;
      list<DAE.ComponentRef> crlst;
      list<tuple<DAE.ComponentRef,Integer>> states;
      list<DAE.Exp> jac,jac1;
      DAE.Exp exp1,exp2;
      Boolean negate;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrix mt;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.BackendDAEType btp;
      BackendDAE.Matching matching;
      BackendDAE.Assignments ass1,ass2;
      DAE.FunctionTree functionTree;
      BackendDAE.SymbolicJacobians symjacs;
    case (_,_,{},_,_,_,_,_,_,_) then (isyst,ishared,inAss1,inAss2,inDerivedAlgs,inDerivedMultiEqn,inStateOrd,inOrgEqnsLst,inchangedEqns);
    case (syst as BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching),shared,(e :: es),_,_,_,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        ev = BackendEquation.equationsLstVarsWithoutRelations({eqn},v,BackendDAEUtil.emptyVars());
        false = BackendVariable.hasContinousVar(BackendDAEUtil.varList(ev));
        BackendDAEEXT.markDifferentiated(e);
        (syst,shared,ass1,ass2,derivedAlgs1,derivedMultiEqn1,so1,orgEqnsLst,changedEqns) = simpleIndexReductiondifferentiateEqns(syst,shared,es,inAss1,inAss2,inDerivedAlgs,inDerivedMultiEqn,inStateOrd,inOrgEqnsLst,inchangedEqns);
      then
        (syst,shared,ass1,ass2,derivedAlgs1,derivedMultiEqn1,so1,orgEqnsLst,changedEqns);
    case (syst as BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching),shared as BackendDAE.SHARED(kv,ev,av,ie,seqns,ae,al,constrs,complEqs,functionTree,BackendDAE.EVENT_INFO(wclst,zc),eoc,btp,symjacs),(e :: es),_,_,_,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        // print( "differentiated equation " +& intString(e) +& " " +& BackendDump.equationStr(eqn) +& "\n");
        (eqn_1,al1,derivedAlgs,ae1,derivedMultiEqn,_) = Derive.differentiateEquationTime(eqn, v, shared, al,inDerivedAlgs,ae,inDerivedMultiEqn);
        (eqn_1,al1,ae1,complEqs,wclst,(so,_)) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn_1, al1, ae1, complEqs, wclst, BackendDAETransform.replaceStateOrderExp,(inStateOrd,v)); 
        eqnss = BackendDAEUtil.equationSize(eqns);
        (eqn_1,al1,ae1, complEqs,wclst1,(v1,eqns,so,ilst)) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn_1,al1,ae1, complEqs,wclst,changeDerVariablestoStates,(v,eqns,inStateOrd,{}));
        eqnss1 = BackendDAEUtil.equationSize(eqns);
        eqnslst = Debug.bcallret2(intGt(eqnss1,eqnss),List.intRange2,eqnss+1,eqnss1,{});
        Debug.fcall(Flags.BLT_DUMP, debugdifferentiateEqns,(eqn,eqn_1)); 
        eqns_1 = BackendEquation.equationSetnth(eqns,e_1,eqn_1);
        i = BackendDAETransform.getAssigned(e,inAss2);
        ass2 = BackendDAETransform.assignmentsSetnth(inAss2,e,-1);
        ass1 = Debug.bcallret3(intGt(i,-1),BackendDAETransform.assignmentsSetnth,inAss1,i,-1,inAss1);
        eqnslst1 = BackendDAETransform.collectVarEqns(ilst,e::eqnslst,mt,arrayLength(mt));
        Debug.fcall(Flags.BLT_DUMP, print, "Update Incidence Matrix: ");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,(eqnslst1,intString," ","\n"));
        syst = BackendDAE.EQSYSTEM(v1,eqns_1,SOME(m),SOME(mt),matching);
        shared = BackendDAE.SHARED(kv,ev,av,ie,seqns,ae1,al1,constrs,complEqs,functionTree,BackendDAE.EVENT_INFO(wclst1,zc),eoc,btp,symjacs);
        syst = BackendDAEUtil.updateIncidenceMatrix(syst, shared, eqnslst1);
        orgEqnsLst = BackendDAETransform.addOrgEqn(inOrgEqnsLst,e,eqn);
        changedEqns = listAppend(inchangedEqns,eqnslst);
        changedEqns = e::changedEqns;        
        (syst,shared,ass1,ass2,derivedAlgs1,derivedMultiEqn1,so1,orgEqnsLst,changedEqns) = simpleIndexReductiondifferentiateEqns(syst,shared,es,ass1,ass2,derivedAlgs,derivedMultiEqn,so,orgEqnsLst,changedEqns);
      then
        (syst,shared,ass1,ass2,derivedAlgs1,derivedMultiEqn1,so1,orgEqnsLst,changedEqns);
    case (syst as BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching),shared,(e :: es),_,_,_,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        print("IndexReduction.simpleIndexReductiondifferentiateEqns failed for eqn " +& intString(e) +& ":\n");
        print(BackendDump.equationStr(eqn)); print("\n");
        BackendDump.dumpEqSystem(syst);
        BackendDump.dumpShared(shared);
      then
        fail();        
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"IndexReduction.simpleIndexReductiondifferentiateEqns failed!"}); 
      then
        fail();
  end matchcontinue;
end simpleIndexReductiondifferentiateEqns;

protected function addAliasStatesStateOrder
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  input BackendDAE.StateOrder iSO;
  output BackendDAE.StateOrder oSO;
algorithm
  oSO := matchcontinue(eqn,vars,iSO)
    local
      DAE.ComponentRef cr1,cr2;
      BackendDAE.StateOrder so;
    case (BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cr1), scalar=DAE.CREF(componentRef=cr2)),_,_)
      equation
        true = BackendVariable.isState(cr1, vars);
        true = BackendVariable.isState(cr2, vars);
        so = iSO;
      then
        so;
    else
      iSO;
  end matchcontinue; 
end addAliasStatesStateOrder;

protected function changeDerVariablestoStates
"function: changeDerVariablestoStates
  author: Frenkel TUD 2011-05
  change the kind of all variables in a der to state"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>>> inTpl;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>>> outTpl;
protected
  DAE.Exp e;
  tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>> vars;
algorithm
  (e,vars) := inTpl;
  outTpl := Expression.traverseExp(e,changeDerVariablestoStatesFinder,vars);
end changeDerVariablestoStates;

protected function changeDerVariablestoStatesFinder
"function: changeDerVariablestoStatesFinder
  author: Frenkel TUD 2011-05
  helper for changeDerVariablestoStates"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>>> inExp;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>>> outExp;
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
      BackendDAE.Value g;
      DAE.ComponentRef dummyder,cr;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAE.Subscript> lstSubs;
      Integer i;
      list<Integer> ilst;
      Option<DAE.Exp> quantity,unit,displayUnit;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> min;
      Option<DAE.Exp> initial_,fixed,nominal,equationBound;
      Option<Boolean> isProtected;
      Option<Boolean> finalPrefix;    
      BackendDAE.EquationArray eqns,eqns_1;  
      BackendDAE.StateOrder so,so1;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distribution;
      BackendDAE.Var v;

/*    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})}),(vars,eqns,so,ilst)))
      equation
        dummyder = BackendDAETransform.getStateOrder(cr,so);
        (v::_,i::_) = BackendVariable.getVar(dummyder,vars);
        v = BackendVariable.setVarKind(v, BackendDAE.STATE());
        vars_1 = BackendVariable.addVar(v, vars);
        e = Expression.crefExp(dummyder);
      then
        ((DAE.CALL(Absyn.IDENT("der"),{e},DAE.callAttrBuiltinReal), (vars,eqns,so,i::ilst)));
*/
    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})}),(vars,eqns,so,ilst)))
      equation
        ((BackendDAE.VAR(_,BackendDAE.STATE(),a,prl,b,c,d,lstSubs,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_::_) = BackendVariable.getVar(cr, vars) "der(der(s)) s is state => der_der_s" ;
        // do not use the normal derivative prefix for the name
        //dummyder = ComponentReference.crefPrefixDer(cr);
        dummyder = ComponentReference.makeCrefQual("$_DER",DAE.T_REAL_DEFAULT,{},cr);
        (eqns_1,so1) = addDummyStateEqn(vars,eqns,cr,dummyder,so);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.STATE(), a, prl, b, NONE(), NONE(), lstSubs, 0, source, SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),SOME(DAE.NEVER()),NONE(),NONE(),NONE(),NONE(),NONE())), comment, flowPrefix, streamPrefix), vars);
        e = Expression.makeCrefExp(dummyder,DAE.T_REAL_DEFAULT);
        i = BackendVariable.varsSize(vars_1);
      then
        ((DAE.CALL(Absyn.IDENT("der"),{e},DAE.callAttrBuiltinReal), (vars_1,eqns_1,so1,i::ilst)));

    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,eqns,so,ilst)))
      equation
        ((BackendDAE.VAR(_,BackendDAE.DUMMY_DER(),a,prl,b,c,d,lstSubs,g,source,SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,min,initial_,fixed,nominal,_,unc,distribution,equationBound,isProtected,finalPrefix)),comment,flowPrefix,streamPrefix) :: _),i::_) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(cr,BackendDAE.STATE(),a,prl,b,c,d,lstSubs,g,source,SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,min,initial_,fixed,nominal,SOME(DAE.NEVER()),unc,distribution,equationBound,isProtected,finalPrefix)),comment,flowPrefix,streamPrefix), vars);
      then
        ((e, (vars_1,eqns,so,i::ilst)));
    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,eqns,so,ilst)))
      equation
        ((BackendDAE.VAR(_,BackendDAE.DUMMY_DER(),a,prl,b,c,d,lstSubs,g,source,NONE(),comment,flowPrefix,streamPrefix) :: _),i::_) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(cr,BackendDAE.STATE(),a,prl,b,c,d,lstSubs,g,source,SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),SOME(DAE.NEVER()),NONE(),NONE(),NONE(),NONE(),NONE())),comment,flowPrefix,streamPrefix), vars);
      then
        ((e, (vars_1,eqns,so,i::ilst)));        

    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,eqns,so,ilst)))
      equation
        ((BackendDAE.VAR(_,BackendDAE.VARIABLE(),a,prl,b,c,d,lstSubs,g,source,SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,min,initial_,fixed,nominal,_,unc,distribution,equationBound,isProtected,finalPrefix)),comment,flowPrefix,streamPrefix) :: _),i::_) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(cr,BackendDAE.STATE(),a,prl,b,c,d,lstSubs,g,source,SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,min,initial_,fixed,nominal,SOME(DAE.NEVER()),unc,distribution,equationBound,isProtected,finalPrefix)),comment,flowPrefix,streamPrefix), vars);
      then
        ((e, (vars_1,eqns,so,i::ilst)));

    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,eqns,so,ilst)))
      equation
        ((BackendDAE.VAR(_,BackendDAE.VARIABLE(),a,prl,b,c,d,lstSubs,g,source,NONE(),comment,flowPrefix,streamPrefix) :: _),i::_) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(cr,BackendDAE.STATE(),a,prl,b,c,d,lstSubs,g,source,SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),SOME(DAE.NEVER()),NONE(),NONE(),NONE(),NONE(),NONE())),comment,flowPrefix,streamPrefix), vars);
      then
        ((e, (vars_1,eqns,so,i::ilst)));

    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,eqns,so,ilst)))
      equation
        ((BackendDAE.VAR(varKind=BackendDAE.STATE()) :: _),i::_) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
      then
        ((e, (vars,eqns,so,ilst)));

    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,eqns,so,ilst)))
      equation
        (v::_,i::_) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
        print("wrong Variable in der: \n");
        BackendDump.debugExpStr((e,"\n"));
      then
        ((e, (vars,eqns,so,ilst)));

    case inExp then inExp;

  end matchcontinue;
end changeDerVariablestoStatesFinder;

protected function addDummyStateEqn 
"function: addDummyStateEqn
  author: Frenkel TUD 2011-05
  helper for changeDerVariablestoStatesFinder"
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input DAE.ComponentRef inCr;
  input DAE.ComponentRef inDCr;
  input BackendDAE.StateOrder inSo;
  output BackendDAE.EquationArray outEqns;
  output BackendDAE.StateOrder outSo;
algorithm
  (outEqns,outSo) := matchcontinue (inVars,inEqns,inCr,inDCr,inSo)
    local
      BackendDAE.EquationArray eqns1;
      DAE.Exp ecr,edcr,c;
      BackendDAE.StateOrder so;
      Integer leqns;
    case (_,_,_,_,_)
      equation
        (_::_,_::_) = BackendVariable.getVar(inDCr, inVars);
      then 
        (inEqns,inSo);
    case (_,_,_,_,_)
      equation
        ecr = Expression.makeCrefExp(inCr,DAE.T_REAL_DEFAULT);
        edcr = Expression.makeCrefExp(inDCr,DAE.T_REAL_DEFAULT);
        c = DAE.CALL(Absyn.IDENT("der"),{ecr},DAE.callAttrBuiltinReal);
        eqns1 = BackendEquation.equationAdd(BackendDAE.EQUATION(edcr,c,DAE.emptyElementSource),inEqns);
        so = BackendDAETransform.addStateOrder(inCr,inDCr,inSo);
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
  print("High index problem, differentiated equation:\n" +& BackendDump.equationStr(a) +& "\nto\n" +& BackendDump.equationStr(b) +& "\n");
end debugdifferentiateEqns;

/* 
 * dump GraphML stuff
 *
 */

public function dumpSystemGraphML
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Option<array<Integer>> inids;
algorithm
  _ := match(isyst,ishared,inids)
    local
		  BackendDAE.Variables vars;
		  BackendDAE.EquationArray eqns;
		  BackendDAE.IncidenceMatrix m;
		  BackendDAE.IncidenceMatrixT mt;
		  GraphML.Graph graph;
		  list<Integer> eqnsids;
		  Integer neqns;
		  array<Integer> vec1,vec2,vec3;
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.NO_MATCHING()),_,NONE())      
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        (_,m,mt) = BackendDAEUtil.getIncidenceMatrix(isyst,ishared,BackendDAE.NORMAL());
        graph = GraphML.getGraph("G",false);  
        ((_,graph)) = BackendVariable.traverseBackendDAEVars(vars,addVarGraph,(1,graph));
        neqns = BackendDAEUtil.systemSize(isyst);
        eqnsids = List.intRange(neqns);
        graph = List.fold1(eqnsids,addEqnGraph,eqns,graph);
        ((_,_,graph)) = List.fold(eqnsids,addEdgesGraph,(1,m,graph));
        GraphML.dumpGraph(graph,"");
     then
       ();
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=vec1,ass2=vec2)),_,NONE())      
      equation
			  vars = BackendVariable.daeVars(isyst);
			  eqns = BackendEquation.daeEqns(isyst);
			  (_,m,mt) = BackendDAEUtil.getIncidenceMatrix(isyst,ishared,BackendDAE.NORMAL());
			  graph = GraphML.getGraph("G",false);  
			  ((_,_,graph)) = BackendVariable.traverseBackendDAEVars(vars,addVarGraphMatch,(1,vec1,graph));
			  neqns = BackendDAEUtil.systemSize(isyst);
			  eqnsids = List.intRange(neqns);
			  graph = List.fold2(eqnsids,addEqnGraphMatch,eqns,vec2,graph);
			  ((_,_,_,graph)) = List.fold(eqnsids,addDirectedEdgesGraph,(1,m,vec2,graph));
			  GraphML.dumpGraph(graph,"");
		 then
		   ();
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=vec1,ass2=vec2)),_,SOME(vec3))      
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        (_,m,mt) = BackendDAEUtil.getIncidenceMatrix(isyst,ishared,BackendDAE.NORMAL());
        graph = GraphML.getGraph("G",false);  
        ((_,graph)) = BackendVariable.traverseBackendDAEVars(vars,addVarGraph,(1,graph));
        neqns = BackendDAEUtil.systemSize(isyst);
        eqnsids = List.intRange(neqns);
        graph = List.fold1(eqnsids,addEqnGraph,eqns,graph);
        ((_,_,_,_,graph)) = List.fold(eqnsids,addDirectedNumEdgesGraph,(1,m,vec2,vec3,graph));
        GraphML.dumpGraph(graph,"");
     then
       ();
  end match;
end dumpSystemGraphML;

protected function addVarGraph
"autor: Frenkel TUD 2012-05"
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
    case ((v as BackendDAE.VAR(varName=cr),(id,g)))
      equation
        true = BackendVariable.isStateVar(v);
        g = GraphML.addNode("v" +& intString(id),ComponentReference.printComponentRefStr(cr),GraphML.COLOR_BLUE,GraphML.RECTANGLE(),g);
        //g = GraphML.addNode("v" +& intString(id),intString(id),GraphML.COLOR_BLUE,GraphML.RECTANGLE(),g);
      then ((v,(id+1,g)));      
    case ((v as BackendDAE.VAR(varName=cr),(id,g)))
      equation
        g = GraphML.addNode("v" +& intString(id),ComponentReference.printComponentRefStr(cr),GraphML.COLOR_RED,GraphML.RECTANGLE(),g);
        //g = GraphML.addNode("v" +& intString(id),intString(id),GraphML.COLOR_RED,GraphML.RECTANGLE(),g);
      then ((v,(id+1,g)));
    case inTpl then inTpl;
  end matchcontinue;
end addVarGraph;

protected function addVarGraphMatch
"autor: Frenkel TUD 2012-05"
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
        //g = GraphML.addNode("v" +& intString(id),ComponentReference.printComponentRefStr(cr),color,GraphML.RECTANGLE(),g);
        g = GraphML.addNode("v" +& intString(id),intString(id),color,GraphML.RECTANGLE(),g);
      then ((v,(id+1,vec1,g)));      
    case ((v as BackendDAE.VAR(varName=cr),(id,vec1,g)))
      equation
        color = Util.if_(intGt(vec1[id],0),GraphML.COLOR_RED,GraphML.COLOR_YELLOW);
        //g = GraphML.addNode("v" +& intString(id),ComponentReference.printComponentRefStr(cr),color,GraphML.RECTANGLE(),g);
        g = GraphML.addNode("v" +& intString(id),intString(id),color,GraphML.RECTANGLE(),g);
      then ((v,(id+1,vec1,g)));
    case inTpl then inTpl;
  end matchcontinue;
end addVarGraphMatch;

protected function addEqnGraph
  input Integer inNode;
  input BackendDAE.EquationArray eqns;
  input GraphML.Graph inGraph;
  output GraphML.Graph outGraph;
protected
  BackendDAE.Equation eqn;
  String str;
algorithm
  eqn := BackendDAEUtil.equationNth(eqns, inNode-1);
  str := BackendDump.equationStr(eqn);
  //str := intString(inNode);
  outGraph := GraphML.addNode("n" +& intString(inNode),str,GraphML.COLOR_GREEN,GraphML.ELLIPSE(),inGraph); 
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
  ((id,graph)) := List.fold1(vars,addEdgeGraph,e,(id,graph));     
  outTpl := (id,m,graph);  
end addEdgesGraph;

protected function addEqnGraphMatch
  input Integer inNode;
  input BackendDAE.EquationArray eqns;
  input array<Integer> vec2;
  input GraphML.Graph inGraph;
  output GraphML.Graph outGraph;
protected
  BackendDAE.Equation eqn;
  String str,color;
algorithm
  eqn := BackendDAEUtil.equationNth(eqns, inNode-1);
  str := BackendDump.equationStr(eqn);
  //str := intString(inNode);
  color := Util.if_(intGt(vec2[inNode],0),GraphML.COLOR_GREEN,GraphML.COLOR_PURPLE);
  outGraph := GraphML.addNode("n" +& intString(inNode),str,color,GraphML.ELLIPSE(),inGraph); 
end addEqnGraphMatch;

protected function addEdgeGraph
  input Integer v;
  input Integer e;
  input tuple<Integer,GraphML.Graph> inTpl;
  output tuple<Integer,GraphML.Graph> outTpl;
protected
  Integer id;
  GraphML.Graph graph;
algorithm
  (id,graph) := inTpl;
  graph := GraphML.addEgde("e" +& intString(id),"n" +& intString(e),"v" +& intString(v),GraphML.COLOR_BLACK,GraphML.LINE(),NONE(),(NONE(),NONE()),graph);
  outTpl := ((id+1,graph));
end addEdgeGraph;

protected function addDirectedEdgesGraph
  input Integer e;
  input tuple<Integer,BackendDAE.IncidenceMatrix,array<Integer>,GraphML.Graph> inTpl;
  output tuple<Integer,BackendDAE.IncidenceMatrix,array<Integer>,GraphML.Graph> outTpl;
protected
  Integer id,v;
  GraphML.Graph graph;
  BackendDAE.IncidenceMatrix m;
  list<Integer> vars;
  array<Integer> vec2;
algorithm
  (id,m,vec2,graph) := inTpl;
  vars := List.select(m[e], Util.intPositive);
  v := vec2[e];
  ((id,_,graph)) := List.fold1(vars,addDirectedEdgeGraph,e,(id,v,graph));     
  outTpl := (id,m,vec2,graph);  
end addDirectedEdgesGraph;

protected function addDirectedEdgeGraph
  input Integer v;
  input Integer e;
  input tuple<Integer,Integer,GraphML.Graph> inTpl;
  output tuple<Integer,Integer,GraphML.Graph> outTpl;
protected
  Integer id,r;
  GraphML.Graph graph;
  tuple<Option<GraphML.ArrowType>,Option<GraphML.ArrowType>> arrow;
algorithm
  (id,r,graph) := inTpl;
  arrow := Util.if_(intEq(r,v),(SOME(GraphML.ARROWSTANDART()),NONE()),(NONE(),SOME(GraphML.ARROWSTANDART())));
  graph := GraphML.addEgde("e" +& intString(id),"n" +& intString(e),"v" +& intString(v),GraphML.COLOR_BLACK,GraphML.LINE(),NONE(),arrow,graph);
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
  array<Integer> vec2,vec3;
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
  outGraph := GraphML.addNode(prefix +& intString(inNode),ComponentReference.printComponentRefStr(cr),c,GraphML.RECTANGLE(),inGraph); 
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
        graph = List.fold1(eqnsids,addEqnGraph,eqns,graph);
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
