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
protected import ComponentReference;
protected import Debug;
protected import Derive;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
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
      list<Integer> eqns_1,changedeqns,unassignedStates,discEqns;
      Integer contiEqn;
      Boolean b;
      array<Integer> ass1,ass2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_,_,_)
      equation
        true = intGt(listLength(eqns),0);        
        BackendDAEUtil.profilerstart1();
        // check by count vars of equations, if len(eqns) > len(vars) stop because of structural singular system
        // the check may should first split the equations in independent subgraphs
        (b,eqns_1,unassignedStates,discEqns) = minimalStructurallySingularSystem(eqns,isyst,inAssignments1,inAssignments2);
        (changedeqns,syst,shared,ass1,ass2,arg) =
         pantelidesIndexReduction1(b,unassignedStates,eqns,eqns_1,actualEqn,isyst,ishared,inAssignments1,inAssignments2,inArg);
        // get from eqns indexes the scalar indexes
        changedeqns = List.unionOnTrue(changedeqns, discEqns, intEq);
        changedeqns = List.sort(changedeqns,intEq);
        contiEqn = List.fold(changedeqns,intMin,listGet(eqns,1));
        BackendDAEUtil.profilerstop1();
      then
       (changedeqns,contiEqn,syst,shared,ass1,ass2,arg);
    case ({},_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.pantelidesIndexReduction called with empty list of equations!"});
      then
        fail();
    case (_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.pantelidesIndexReduction failed!"});
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
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2; 
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (changedEqns,osyst,oshared,outAssignments1,outAssignments2,outArg):=
  matchcontinue (b,unassignedStates,alleqns,eqns,actualEqn,isyst,ishared,inAssignments1,inAssignments2,inArg)
    local
      list<BackendDAE.Var> varlst;
      list<Integer> changedeqns,eqns1;
      BackendDAE.StateOrder so,so1;
      BackendDAE.ConstraintEquations orgEqnsLst,orgEqnsLst1;
      array<Integer>  ass1,ass2; 
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;
           
    case (true,_,_,_,_,_,_,_,_,(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn))
      equation
        true = intGt(listLength(eqns),0);
        // get from scalar eqns indexes the indexes in the equation array
        eqns1 = List.map1r(eqns,arrayGet,mapIncRowEqn);
        eqns1 = List.unique(eqns1);                
        Debug.fcall(Flags.BLT_DUMP, print, "Reduce Index\nmarked equations: ");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst, (eqns,intString," ","\n"));
        Debug.fcall(Flags.BLT_DUMP, print, BackendDump.dumpMarkedEqns(isyst, eqns1));
        (syst,shared,ass1,ass2,so1,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,changedeqns,eqns1) = differentiateAliasEqns(isyst,ishared,eqns1,inAssignments1,inAssignments2,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,{},{});
        (syst,shared,ass1,ass2,so1,orgEqnsLst1,mapEqnIncRow,mapIncRowEqn,changedeqns) = differentiateEqns(syst,shared,eqns1,ass1,ass2,so1,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,changedeqns);
      then
       (changedeqns,syst,shared,ass1,ass2,(so1,orgEqnsLst1,mapEqnIncRow,mapIncRowEqn));

    case (_,_,_,_,_,_,_,_,_,(_,_,_,mapIncRowEqn))
      equation
        false = intGt(listLength(eqns),0);
        Error.addMessage(Error.INTERNAL_ERROR, {"IndexReduction.pantelidesIndexReduction failed! Found empty set of continues equations. Use +d=bltdump to get more information."});
        Debug.fcall(Flags.BLT_DUMP, print, "Reduce Index failed! Found empty set of continues equations.\nmarked equations:\n");
        // get from scalar eqns indexes the indexes in the equation array
        eqns1 = List.map1r(alleqns,arrayGet,mapIncRowEqn);
        eqns1 = List.unique(eqns1);          
        Debug.fcall(Flags.BLT_DUMP, print, BackendDump.dumpMarkedEqns(isyst, eqns1));
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(inAssignments1,inAssignments2,{}));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dump, BackendDAE.DAE({syst},ishared));
      then
        fail(); 

    case (false,_,_,_,_,_,_,_,_,(_,_,_,mapIncRowEqn))
      equation
        true = intGt(listLength(eqns),0);
        Error.addMessage(Error.INTERNAL_ERROR, {"IndexReduction.pantelidesIndexReduction failed! System is structurally singulare and cannot handled because number of unassigned equations is larger than number of states. Use +d=bltdump to get more information."});
        Debug.fcall(Flags.BLT_DUMP, print, "Reduce Index failed! System is structurally singulare and cannot handled because number of unassigned equations is larger than number of states.\nmarked equations:\n");
        // get from scalar eqns indexes the indexes in the equation array
        eqns1 = List.map1r(alleqns,arrayGet,mapIncRowEqn);
        eqns1 = List.unique(eqns1);          
        Debug.fcall(Flags.BLT_DUMP, print, BackendDump.dumpMarkedEqns(isyst, eqns1));
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
  output list<Integer> discEqns;
protected
  list<Integer> unassignedEqns;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  array<Boolean> statemark;
  Integer size;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,m=SOME(m)) := syst;
  ((unassignedEqns,outEqnsLst,discEqns)) := List.fold2(inEqnsLst,unassignedContinuesEqns,vars,(inAssignments2,m),({},{},{}));
  outEqnsLst := listReverse(outEqnsLst);
  size := BackendDAEUtil.equationSize(eqns);
  statemark := arrayCreate(size,false);
  outStateIndxs := List.fold2(inEqnsLst,statesInEquations,(m,statemark),inAssignments1,{});
  b := intGe(listLength(outStateIndxs),listLength(unassignedEqns));
end minimalStructurallySingularSystem;

protected function unassignedContinuesEqns
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
      BackendDAE.Var v;
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
        unassignedEqns = List.consOnTrue(b, eindx, unassignedEqns);
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
      Integer e_1,e,e1,i,i1,i2,p1,p2;
      BackendDAE.Equation eqn,eqn_1;
      BackendDAE.EquationArray eqns_1,eqns;
      list<Integer> es,ilst,eqnslst,eqnslst1,changedEqns,eqns1;
      BackendDAE.Variables v,ev,v1;
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
    case (_,_,{},_,_,_,_,_,_,_,_) then (isyst,ishared,inAss1,inAss2,inStateOrd,inOrgEqnsLst,imapEqnIncRow,imapIncRowEqn,inchangedEqns,iEqnsAcc);
    case (BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching),shared,(e :: es),_,_,_,_,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        // is alias State
        (cr1,cr2,exp1,exp2,negate) = BackendEquation.aliasEquation(eqn);
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
        ((exp2,(so,v1))) = BackendDAETransform.replaceStateOrderExp((exp2,(inStateOrd,v1)));
        // get from scalar eqns indexes the indexes in the equation array
        eqns1 = List.map1r(eqnslst,arrayGet,imapIncRowEqn);
        eqns1 = List.unique(eqns1);        
        eqns_1 = replaceAliasState(eqns1,exp1,exp2,cr,eqns,i1,i);
        so = BackendDAETransform.addAliasStateOrder(scr,cr,so);
        (orgEqnsLst,_) = traverseOrgEqnsExp(inOrgEqnsLst,(cr,exp1,exp2),replaceAliasStateExp,{});
        e1 = inAss1[i];
        b = intGt(e1,0);    
        ass1 = Debug.bcallret3(b,arrayUpdate,inAss1,i,-1,inAss1); 
        ass2 = Debug.bcallret3(b,arrayUpdate,inAss2,e1,-1,inAss2); 
        syst = BackendDAE.EQSYSTEM(v1,eqns_1,SOME(m),SOME(mt),matching);
        changedEqns =  List.unique(List.map1r(changedEqns,arrayGet,imapIncRowEqn));
        (syst,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.updateIncidenceMatrixScalar(syst, shared,BackendDAE.SOLVABLE(), changedEqns, imapEqnIncRow, imapIncRowEqn);
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
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output array<Integer> outAss1;
  output array<Integer> outAss2; 
  output BackendDAE.StateOrder outStateOrd;
  output BackendDAE.ConstraintEquations outOrgEqnsLst;
  output array<list<Integer>> omapEqnIncRow;
  output array<Integer> omapIncRowEqn;    
  output list<Integer> outchangedEqns;
algorithm
  (osyst,oshared,outAss1,outAss2,outStateOrd,outOrgEqnsLst,omapEqnIncRow,omapIncRowEqn,outchangedEqns):=
  matchcontinue (isyst,ishared,inEqns,inAss1,inAss2,inStateOrd,inOrgEqnsLst,imapEqnIncRow,imapIncRowEqn,inchangedEqns)
    local
      Integer e_1,e,e1,i,eqnss,eqnss1,i1,i2,p1,p2;
      BackendDAE.Equation eqn,eqn_1;
      BackendDAE.EquationArray eqns_1,eqns;
      list<Integer> es,ilst,eqnslst,eqnslst1,changedEqns,ilst1;
      BackendDAE.Variables v,ev,v1;
      BackendDAE.StateOrder so,so1;
      BackendDAE.ConstraintEquations orgEqnsLst;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrix mt;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.Matching matching;
      array<Integer> ass1,ass2,mapIncRowEqn;
      DAE.ComponentRef cr,cr1,cr2,scr;
      Boolean negate,b1,b2;
      DAE.Exp exp1,exp2;
      BackendDAE.Var var1,var2;
      array<list<Integer>> mapEqnIncRow;
    case (_,_,{},_,_,_,_,_,_,_) then (isyst,ishared,inAss1,inAss2,inStateOrd,inOrgEqnsLst,imapEqnIncRow,imapIncRowEqn,inchangedEqns);
    case (syst as BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching),shared,(e :: es),_,_,_,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        // print( "differentiated equation " +& intString(e) +& " " +& BackendDump.equationStr(eqn) +& "\n");
        eqn_1 = Derive.differentiateEquationTime(eqn, v, shared);
        (eqn_1,(so,_)) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn_1, BackendDAETransform.replaceStateOrderExp,(inStateOrd,v)); 
        eqnss = BackendDAEUtil.equationArraySize(eqns);
        (eqn_1,(v1,eqns,so,ilst)) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn_1,changeDerVariablestoStates,(v,eqns,inStateOrd,{}));
        eqnss1 = BackendDAEUtil.equationArraySize(eqns);
        eqnslst = Debug.bcallret2(intGt(eqnss1,eqnss),List.intRange2,eqnss+1,eqnss1,{});
        Debug.fcall(Flags.BLT_DUMP, debugdifferentiateEqns,(eqn,eqn_1)); 
        eqns_1 = BackendEquation.equationSetnth(eqns,e_1,eqn_1);
        // set equation assigned variable assignemts zero
        ilst1 = List.map1r(ilst,arrayGet,inAss1);
        ilst1 = List.select1(ilst1,intGt,0);
        ass2 = List.fold1r(ilst1,arrayUpdate,-1,inAss2);
        // set changed variables assignments to zero
        ass1 = List.fold1r(ilst,arrayUpdate,-1,inAss1);
        eqnslst1 = BackendDAETransform.collectVarEqns(ilst,{},mt,arrayLength(mt));
        syst = BackendDAE.EQSYSTEM(v1,eqns_1,SOME(m),SOME(mt),matching);
        eqnslst1 =  List.unique(listAppend(List.map1r(eqnslst1,arrayGet,imapIncRowEqn),eqnslst));
        eqnslst1 = List.unique(e::eqnslst1);
        Debug.fcall(Flags.BLT_DUMP, print, "Update Incidence Matrix: ");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,(eqnslst1,intString," ","\n"));
        (syst,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.updateIncidenceMatrixScalar(syst, shared,BackendDAE.SOLVABLE(), eqnslst1, imapEqnIncRow, imapIncRowEqn);
        orgEqnsLst = BackendDAETransform.addOrgEqn(inOrgEqnsLst,e,eqn);
        // collect changed equations
        // and new equations and current equation
        eqnslst =  List.unique(List.flatten(List.map1r(e::eqnslst,arrayGet,mapEqnIncRow)));
        changedEqns = listAppend(inchangedEqns, eqnslst);
        // add assigned equations from variables become states       
        changedEqns = List.unionOnTrue(changedEqns, ilst1, intEq);      
        (syst,shared,ass1,ass2,so1,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,changedEqns) = differentiateEqns(syst,shared,es,ass1,ass2,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,changedEqns);
      then
        (syst,shared,ass1,ass2,so1,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,changedEqns);
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
        p1 = varStateSelectPrio(var1);
        p2 = varStateSelectPrio(var2);
        ((cra,ia,exps,vara,crs,is)) = Util.if_(intGt(p1,p2),(cr2,i2,exp1,var2,cr1,i1),(cr1,i1,exp2,var1,cr2,i2));      
        vara = BackendVariable.setVarKind(vara, BackendDAE.DUMMY_STATE());
        v = BackendVariable.addVar(vara,iv);
      then
        (cra,ia,crs,exps,is,v);
  end match;
end selectAliasState;

protected function varStateSelectPrio
"function varStateSelectPrio
  Helper function to calculateVarPriorities.
  Calculates a priority contribution bases on the stateSelect attribute."
  input BackendDAE.Var v;
  output Integer prio;
  protected
  DAE.StateSelect ss;
algorithm
  ss := BackendVariable.varStateSelect(v);
  prio := varStateSelectPrio2(ss);
end varStateSelectPrio;

protected function varStateSelectPrio2
"helper function to varStateSelectPrio"
  input DAE.StateSelect ss;
  output Integer prio;
algorithm
  prio := match(ss)
    case (DAE.NEVER()) then -1;
    case (DAE.AVOID()) then 0;
    case (DAE.DEFAULT()) then 1;
    case (DAE.PREFER()) then 2;
    case (DAE.ALWAYS()) then 3;
  end match;
end varStateSelectPrio2;

protected function replaceAliasState
"function: replaceAliasState
  author: Frenkel TUD 2012-06"
  input list<Integer> inEqsLst;
  input DAE.Exp inCrExp;
  input DAE.Exp indCrExp;
  input DAE.ComponentRef inACr;
  input BackendDAE.EquationArray inEqns;
  input Integer si;
  input Integer ai;
  output BackendDAE.EquationArray outEqns;
algorithm
  outEqns:=
  match (inEqsLst,inCrExp,indCrExp,inACr,inEqns,si,ai)
    local
      BackendDAE.EquationArray eqns,eqns1;
      BackendDAE.Equation eqn,eqn1;
      Integer pos,pos_1;
      list<Integer> rest,row;
    case (pos::rest,_,_,_,_,_,_)
      equation
        // replace in eqn
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(inEqns,pos_1);
        (eqn1,_) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn, replaceAliasStateExp,(inACr,inCrExp,indCrExp));
        eqns =  BackendEquation.equationSetnth(inEqns,pos_1,eqn1);
        //  print("Replace in Eqn:\n" +& BackendDump.equationStr(eqn) +& "\nto\n" +& BackendDump.equationStr(eqn1) +& "\n");
      then 
        replaceAliasState(rest,inCrExp,indCrExp,inACr,eqns,si,ai);
    case ({},_,_,_,_,_,_) then inEqns;
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
algorithm
  ht := HashTableCG.emptyHashTable();
  dht := HashTable3.emptyHashTable();
  so := BackendDAE.STATEORDER(ht,dht);  
  ((so,_)) := BackendEquation.traverseBackendDAEEqns(BackendEquation.daeEqns(isyst),BackendDAETransform.traverseStateOrderFinder,(so,BackendVariable.daeVars(isyst)));
  Debug.fcall(Flags.BLT_DUMP, BackendDAETransform.dumpStateOrder, so); 
  outArg := (so,{},mapEqnIncRow,mapIncRowEqn);
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
      Integer ne,nv,ne1,nv1,freestatevars,orgeqnscount;
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
      list<BackendDAE.Var> varlst;  
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;  
      array<DAE.Constraint> constrs;
      list<BackendDAE.Equation> enqnslst;
      list<Integer> changedeqns;
    // no Index Reduction performed (OrgEqnsLst is Empty)
    case (_,_,(so,{},mapEqnIncRow,mapIncRowEqn))
     then 
       (isyst,ishared);
    // Index Reduction performed
    case (syst as BackendDAE.EQSYSTEM(orderedVars=v,matching=BackendDAE.MATCHING(ass1=ass1,ass2=ass2)),BackendDAE.SHARED(functionTree=funcs),(so,orgEqnsLst,_,_))
      equation
        // do late Inline also in orgeqnslst
        orgEqnsLst = traverseOrgEqns(orgEqnsLst,(SOME(funcs),{DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()}),Inline.inlineEq,{});
        // replace all der(x) with dx
        (orgEqnsLst,_) = traverseOrgEqnsExp(orgEqnsLst,so,replaceDerStatesStates,{});
        Debug.fcall(Flags.BLT_DUMP, print, "Dynamic State Selection\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDAETransform.dumpStateOrder, so); 
        // get highest order derivatives
        ne = BackendDAEUtil.systemSize(syst);
        nv = BackendVariable.varsSize(v);
        hov = highestOrderDerivatives(v,so);
        Debug.fcall(Flags.BLT_DUMP, print, "highest Order Derivatives:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpVarsArray, hov);
        // iterate comps
        (syst,m,mt,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(syst,ishared,BackendDAE.NORMAL());
        Debug.fcall(Flags.BLT_DUMP, print, "Index Reduced System:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem,syst);
        comps = BackendDAETransform.tarjanAlgorithm(m,mt,ass1,ass2);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpComponentsOLD,comps);
        
        varlst = List.filter(BackendDAEUtil.varList(v), stateVar);
        varlst = List.filter(varlst, notVarStateSelectAlways);
        freestatevars = listLength(varlst);
        orgeqnscount = countOrgEqns(orgEqnsLst,0);
        
        (dummyStates,syst,shared) = processComps(freestatevars,varlst,orgeqnscount,comps,syst,ishared,ass2,(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn),hov,{});
        enqnslst = List.flatten(List.map(orgEqnsLst,Util.tuple22));
        syst = BackendEquation.equationsAddDAE(enqnslst, syst);
        ne1 = BackendDAEUtil.systemSize(syst);
        nv1 = BackendVariable.varsSize(BackendVariable.daeVars(syst));
        vec1 = Util.arrayExpand(ne1-ne, ass1, -1);
        vec2 = Util.arrayExpand(nv1-nv, ass2, -1);
        (syst,m,_,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(syst,shared,BackendDAE.NORMAL());
        syst = BackendVariable.expandVarsDAE(listLength(dummyStates),syst);
        (syst,shared,changedeqns) = addDummyStates(dummyStates,syst,shared,vec1,vec2,mapIncRowEqn,{});
        Debug.fcall(Flags.BLT_DUMP, print, "Full System:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem,syst);        
        (syst,_,_) = BackendDAEUtil.updateIncidenceMatrixScalar(syst,shared,BackendDAE.SOLVABLE(),changedeqns,mapEqnIncRow,mapIncRowEqn); 
        Matching.matchingExternalsetIncidenceMatrix(nv1,ne1,m);
        BackendDAEEXT.matching(ne1,nv1,5,-1,0.0,1);
        BackendDAEEXT.getAssignment(vec2,vec1);     
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(vec1,vec2,{})); 
        Debug.fcall(Flags.BLT_DUMP, print, "Final System with DummyStates:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem,syst);       
     then 
       (syst,shared);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.dynamicStateSelection failed!"});
      then
        fail();
  end matchcontinue;
end dynamicStateSelection;

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
      Integer count;
      list<BackendDAE.Equation> orgeqns;
      BackendDAE.ConstraintEquations rest;
    case ({},_) then iCount;
    case ((_,orgeqns)::rest,_)
      then
        countOrgEqns(rest,intAdd(listLength(orgeqns),iCount));
  end match;
end countOrgEqns;

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
      Type_a a;
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
  input Integer cfreeStates;
  input list<BackendDAE.Var> freeStates;
  input Integer cOrgEqns;
  input list<list<Integer>> inComps;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input array<Integer> vec2;
  input BackendDAE.DAEHandlerArg inArg;
  input BackendDAE.Variables hov; 
  input list<DAE.ComponentRef> inDummyStates; 
  output list<DAE.ComponentRef> outDummyStates; 
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (outDummyStates,osyst,oshared) := 
  matchcontinue(cfreeStates,freeStates,cOrgEqns,inComps,isyst,ishared,vec2,inArg,hov,inDummyStates)
    local 
        list<DAE.ComponentRef> dummystates; 
        BackendDAE.EqSystem syst;
        BackendDAE.Shared shared;
    case (_,_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(cfreeStates,cOrgEqns);
        dummystates = List.map(freeStates,BackendVariable.varCref);
      then (dummystates,isyst,ishared);
    else
      equation
        (dummystates,syst,shared) = processComps1(inComps,isyst,ishared,vec2,inArg,hov,inDummyStates);
      then
        (dummystates,syst,shared);
  end matchcontinue;
end processComps;

protected function processComps1
"function: processComps1
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
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;  
algorithm
  (outDummyStates,osyst,oshared) := 
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
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;      
    case ({},_,_,_,_,_,_) then (inDummyStates,isyst,ishared);
    case (comp::rest,_,_,_,(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn),_,_)
      equation
        // get vars
        cv = List.fold2(comp,getCompVars,vec2,(BackendVariable.daeVars(isyst),hov,so),BackendDAEUtil.emptyVars());
        // get equations 
        comp = List.unique(List.map1r(comp,arrayGet,mapIncRowEqn));
        comp = List.sort(comp,intGt);
        (orgEqnsLst,orgEqnLevel) = getOrgEqns(comp,orgEqnsLst,{},{},BackendEquation.daeEqns(isyst));
        // sort eqns, this is maybe not neccessary
        orgEqnLevel = List.sort(orgEqnLevel,compareOrgEqn);
        (hov1,dummyStates,syst,shared) = processComp(orgEqnLevel,isyst,ishared,so,cv,hov,hov,inDummyStates);
        //(hov1,dummyStates,_) = processCompInv(orgEqnLevel,isyst,ishared,so,cv,hov,hov,inDummyStates);
        (dummyStates,syst,shared) = processComps1(rest,syst,shared,vec2,(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn),hov1,dummyStates);
      then
        (dummyStates,syst,shared);
  end matchcontinue;
end processComps1;

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
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;    
algorithm
  (outhov,outDummyStates,osyst,oshared) := 
  matchcontinue(orgEqnsLst,isyst,ishared,so,cvars,hov,hov1,inDummyStates)
    local 
      list<BackendDAE.Equation> eqnslst;
      list<tuple<Integer, list<BackendDAE.Equation>, Integer>> orgeqns;
      BackendDAE.Variables lov,hov_1,cvars1;
      list<DAE.ComponentRef> dummyStates;
      BackendDAE.EquationArray eqns;
      list<Integer> eqnindxlst;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case ({},_,_,_,_,_,_,_) then (hov1,inDummyStates,isyst,ishared);
    case (_,_,_,_,_,_,_,_)
      equation
        (orgeqns,eqnslst,eqnindxlst) = getOrgEqn(orgEqnsLst,{},{},{});
        eqns = BackendDAEUtil.listEquation(eqnslst);
        (hov_1,dummyStates,lov,syst,shared) = selectDummyDerivatives(cvars,BackendVariable.numVariables(cvars),eqns,BackendDAEUtil.equationSize(eqns),eqnindxlst,hov1,inDummyStates,isyst,ishared,BackendDAEUtil.emptyVars());
        // get derivatives one order less
        lov = lowerOrderDerivatives(lov,BackendVariable.daeVars(isyst),so);
        // call again with original equations of derived equations 
        (hov_1,dummyStates,syst,shared) = processComp(orgeqns,syst,shared,so,lov,lov,hov_1,dummyStates);
      then
        (hov_1,dummyStates,syst,shared); 
    else
      equation
        BackendDump.dumpEqSystem(isyst);
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
  output BackendDAE.Variables outhov;   
  output list<DAE.ComponentRef> outDummyStates;  
  output BackendDAE.Variables outStates;   
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;   
algorithm
  (outhov,outDummyStates,outStates,osyst,oshared) := 
  matchcontinue(orgEqnsLst,isyst,ishared,so,cvars,hov,hov1,inDummyStates)
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
    case ({},_,_,_,_,_,_,_) then (hov1,inDummyStates,BackendDAEUtil.emptyVars(),isyst,ishared);
    case (_,_,_,_,_,_,_,_)
      equation
        (orgeqns,eqnslst,eqnindxlst) = getOrgEqn(orgEqnsLst,{},{},{});
        // get all derivatives one order less
        lov = lowerOrderDerivatives(cvars,BackendVariable.daeVars(isyst),so);
        // gall again with original equations of derived equations 
        (hov_1,dummyStates,vars,syst,shared) = processCompInv(orgeqns,isyst,ishared,so,lov,lov,hov1,inDummyStates);
        // remove dummy states from candidates    
        crlst = BackendVariable.getAllCrefFromVariables(vars);
        vars = BackendVariable.deleteCrefs(crlst,cvars);
        Debug.fcall(Flags.BLT_DUMP, print,"Vars:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpVarsArray,vars);
        // select dummy derivatives
        eqns = BackendDAEUtil.listEquation(eqnslst);
        (hov_1,dummyStates,lov,syst,shared) = selectDummyDerivatives(vars,BackendVariable.numVariables(vars),eqns,BackendDAEUtil.equationSize(eqns),eqnindxlst,hov_1,dummyStates,syst,shared,BackendDAEUtil.emptyVars());
        // get derivatives 
        (lov,dummyStates) = higerOrderDerivatives(lov,BackendVariable.daeVars(isyst),so,dummyStates);
        Debug.fcall(Flags.BLT_DUMP, print,"HigerOrderVars:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpVarsArray,lov);
      then
        (hov_1,dummyStates,lov,syst,shared); 
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
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.Variables inLov;
  output BackendDAE.Variables outhov;
  output list<DAE.ComponentRef> outDummyStates;
  output BackendDAE.Variables outlov;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (outhov,outDummyStates,outlov,osyst,oshared) := 
  matchcontinue(vars,varSize,eqns,eqnsSize,eqnindxlst,hov,inDummyStates,isyst,ishared,inLov)
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
        BackendDAE.Shared shared;  
        list<BackendDAE.Var> varlst;
        list<tuple<DAE.ComponentRef, Integer>> states;
        BackendDAE.AdjacencyMatrixEnhanced me;
        BackendDAE.AdjacencyMatrixTEnhanced meT;  
        array<list<Integer>> mapEqnIncRow;
        array<Integer> mapIncRowEqn;     
    case(_,0,_,_,_,_,_,_,_,_)
        // if no vars then there is nothing do do
      then
        (hov,inDummyStates,inLov,isyst,ishared);
    case(_,1,_,1,_,_,dummystates,_,_,_)
      equation
        // if there is only one var select it because there is no choice
        Debug.fcall(Flags.BLT_DUMP, print, "single var and eqn\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem, BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING()));
        v = BackendVariable.getVarAt(vars,1);
        cr = BackendVariable.varCref(v);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrCrefStr, ("Select ",cr," as dummyState\n"));
        hov1 = BackendVariable.deleteVar(cr,hov);
        lov = BackendVariable.addVar(v,inLov);
      then
        (hov1,cr::dummystates,lov,isyst,ishared);
    case(_,_,_,_,_,_,_,_,_,_)
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
        (hov1,dummystates,lov,isyst,ishared); 
    case(_,_,_,_,_,_,_,_,_,_)
      equation
        // try to select dummy vars
        true = intGt(varSize,1);
        false = intGt(eqnsSize,varSize);
        varlst = BackendDAEUtil.varList(vars);
        varlst = List.filter(varlst, notVarStateSelectAlways);
        true = intGt(eqnsSize,listLength(varlst));
        Debug.fcall(Flags.BLT_DUMP, print, "select dummy vars from stateselection\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem, BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING()));
        crlst = List.map(varlst,BackendVariable.varCref);
        states = List.threadTuple(crlst,List.intRange2(1,varSize));
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));
        (hov1,lov,dummystates) = selectDummyStates(states,1,eqnsSize,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov,isyst,ishared); 
    case(_,_,_,_,_,_,_,_,_,_)
      equation
        // try to select dummy vars
        true = intGt(varSize,1);
        false = intGt(eqnsSize,varSize);
        Debug.fcall(Flags.BLT_DUMP, print, "try to select dummy vars with natural matching\n");
        
        // sort vars with heuristic
        syst = BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING());
        (syst,_,_,mapEqnIncRow,mapIncRowEqn) =  BackendDAEUtil.getIncidenceMatrixScalar(syst,ishared,BackendDAE.NORMAL());
        varlst = BackendDAEUtil.varList(vars);
        crlst = List.map(varlst,BackendVariable.varCref);
        states = List.threadTuple(crlst,List.intRange2(1,varSize));
        vars1 = BackendDAETransform.sortStateCandidatesVars(syst,mapIncRowEqn);

        varlst = List.map1(BackendDAEUtil.varList(vars1),BackendVariable.setVarKind,BackendDAE.VARIABLE());   
        vars1 = BackendDAEUtil.listVar1(varlst);         
        syst = BackendDAE.EQSYSTEM(vars1,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING());
        
        (me,meT,mapEqnIncRow,mapIncRowEqn) =  BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(syst,ishared);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpAdjacencyMatrixEnhanced,me);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpAdjacencyMatrixTEnhanced,meT);       
        (hov1,dummystates,lov,syst,shared) = selectDummyDerivatives1(me,meT,vars1,varSize,eqns,eqnsSize,eqnindxlst,hov,inDummyStates,isyst,ishared,inLov,mapEqnIncRow,mapIncRowEqn);
      then
        (hov1,dummystates,lov,syst,shared);
    case(_,_,_,_,_,_,_,_,_,_)
      equation
        // try to select dummy vars heuristic based
        true = intGt(varSize,1);
        false = intGt(eqnsSize,varSize);
        Debug.fcall(Flags.BLT_DUMP, print, "try to select dummy vars heuristic based\n");
        (syst,_,_,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING()),ishared,BackendDAE.NORMAL());
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem, syst);
        varlst = BackendDAEUtil.varList(vars);
        crlst = List.map(varlst,BackendVariable.varCref);
        states = List.threadTuple(crlst,List.intRange2(1,varSize));
        states = BackendDAETransform.sortStateCandidates(states,syst);
        //states = List.sort(states,stateSortFunc);
        //states = listReverse(states);
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));
        (hov1,lov,dummystates) = selectDummyStates(states,1,eqnsSize,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov,isyst,ishared);        
    case(_,_,_,_,_,_,_,_,_,_)
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
  output BackendDAE.Variables outhov;
  output list<DAE.ComponentRef> outDummyStates;
  output BackendDAE.Variables outlov;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;   
algorithm
  (outhov,outDummyStates,outlov,osyst,oshared) := 
  matchcontinue(me,meT,vars,varSize,eqns,eqnsSize,eqnindxlst,hov,inDummyStates,isyst,ishared,inLov,iMapEqnIncRow,iMapIncRowEqn)
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
        BackendDAE.Shared shared; 
        list<BackendDAE.Var> varlst;
        list<tuple<DAE.ComponentRef, Integer>> states,dstates; 
        list<Integer> unassigned;  
    case(_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        m = incidenceMatrixfromEnhanced(me);
        mT = incidenceMatrixfromEnhanced(meT);  
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem, BackendDAE.EQSYSTEM(vars,eqns,SOME(m),SOME(mT),BackendDAE.NO_MATCHING()));
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
        
        Debug.fcall(Flags.BLT_DUMP, print, ("dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dstates,BackendDAETransform.dumpStates,"\n","\n")));     
        Debug.fcall(Flags.BLT_DUMP, print, ("States:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));        
        Debug.fcall(Flags.BLT_DUMP, print, ("Unassigned Eqns:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((unassigned,intString," ","\n")));        
        
        (hov1,dummystates,lov,syst,shared) = selectDummyDerivatives2(dstates,states,unassigned,me,meT,vars,varSize,eqns,eqnsSize,eqnindxlst,hov,inDummyStates,isyst,ishared,inLov);
      then
        (hov1,dummystates,lov,syst,shared);        
    case(_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        m = incidenceMatrixfromEnhanced1(me);
        mT = incidenceMatrixfromEnhanced1(meT);  
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqSystem, BackendDAE.EQSYSTEM(vars,eqns,SOME(m),SOME(mT),BackendDAE.NO_MATCHING()));
        Matching.matchingExternalsetIncidenceMatrix(eqnsSize,varSize,mT);
        BackendDAEEXT.matching(eqnsSize,varSize,3,-1,1.0,1);
        vec1 = arrayCreate(eqnsSize,-1);
        vec2 = arrayCreate(varSize,-1);
        BackendDAEEXT.getAssignment(vec2,vec1);   
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching,vec1);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching,vec2);
        (dstates,states) = checkAssignment(1,varSize,vec2,vars,{},{});
        unassigned = Matching.getUnassigned(eqnsSize, vec1, {});
        
        Debug.fcall(Flags.BLT_DUMP, print, ("dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dstates,BackendDAETransform.dumpStates,"\n","\n")));     
        Debug.fcall(Flags.BLT_DUMP, print, ("States:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));        
        Debug.fcall(Flags.BLT_DUMP, print, ("Unassigned Eqns:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((unassigned,intString," ","\n")));        
        
        (hov1,dummystates,lov,syst,shared) = selectDummyDerivatives2(dstates,states,unassigned,me,meT,vars,varSize,eqns,eqnsSize,eqnindxlst,hov,inDummyStates,isyst,ishared,inLov);
      then
        (hov1,dummystates,lov,syst,shared);             
  end matchcontinue;
end selectDummyDerivatives1;

protected function selectDummyDerivatives2
"function: selectDummyDerivatives2
  author: Frenkel TUD 2012-05
  select dummy derivatives from strong connected component"
  input list<tuple<DAE.ComponentRef, Integer>> dstates;
  input list<tuple<DAE.ComponentRef, Integer>> states;
  input list<Integer> unassignedEqns;
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
  output BackendDAE.Variables outhov;
  output list<DAE.ComponentRef> outDummyStates;
  output BackendDAE.Variables outlov;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;   
algorithm
  (outhov,outDummyStates,outlov,osyst,oshared) := 
  matchcontinue(dstates,states,unassignedEqns,me,meT,vars,varSize,eqns,eqnsSize,eqnindxlst,hov,inDummyStates,isyst,ishared,inLov)
      local 
        BackendDAE.Variables hov1,lov;
        list<DAE.ComponentRef> dummystates,crset,crstates;
        DAE.ComponentRef crcon;
        BackendDAE.IncidenceMatrix m;
        BackendDAE.IncidenceMatrixT mT;
        array<Integer> vec1,vec2;
        Integer rang,size,setsize;
        BackendDAE.EqSystem syst;
        BackendDAE.Shared shared; 
        list<BackendDAE.Var> varlst,statesvars;
        BackendDAE.Var vcont;
        list<tuple<DAE.ComponentRef, Integer>> dstates1,states1; 
        list<Integer> unassigned,changedeqns,stateindxs;   
        BackendDAE.Equation eqn,eqcont;
        DAE.Exp exp,contExp,crconexp,contstartExp;
        list<DAE.Exp> explst,sexplst;
        list<BackendDAE.Equation> selecteqns,dselecteqns;
        list<BackendDAE.WhenClause> wclst;
    case(_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(listLength(dstates),eqnsSize);
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dstates,BackendDAETransform.dumpStates,"\n","\n")));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrIntStrIntStr, ("Select ",varSize-eqnsSize," from ",varSize,"\n"));        
        (hov1,lov,dummystates) = selectDummyStates(dstates,1,eqnsSize,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov,isyst,ishared); 
    case(_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // for now only implemented for one scalar equation
        true = intEq(eqnsSize,1);
        rang = listLength(states)-listLength(unassignedEqns);
        // workaround to avoid state changes
        //states = List.sort(states,stateSortFunc);
        //states = listReverse(states);        
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrIntStrIntStr, ("Select ",rang," from ",listLength(states),"\n"));   
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,BackendDAETransform.dumpStates,"\n","\n")));     
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dstates,BackendDAETransform.dumpStates,"\n","\n")));        
        // generate state set and condition name 
        crstates = List.map(states,Util.tuple21);
        //crstates = List.sort(crstates,ComponentReference.crefSortFunc);
        (crset,crcon,vcont::varlst) = getStateSetNames(crstates);
        
        stateindxs = List.map(states,Util.tuple22);
        statesvars = List.map1r(stateindxs,BackendVariable.getVarAt,vars);
        //(varlst,_) = List.mapFold(varlst, setStartValue, statesvars);
        
        Debug.fcall(Flags.BLT_DUMP, print, ("StatesSet:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((crset,ComponentReference.printComponentRefStr,"\n","\n")));
        
        // get Partial derivative of system for states
        eqn = BackendDAEUtil.equationNth(eqns, 0);
        BackendDAE.RESIDUAL_EQUATION(exp=exp)::{} = BackendEquation.equationToScalarResidualForm(eqn);
        explst = List.map1(crstates,differentiateExp,exp);
        Debug.fcall(Flags.BLT_DUMP, print, ("Partial Derivaives:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((explst,ExpressionDump.printExpStr,"\n","\n")));
        
        // generate condition equation
        contExp = generateCondition(1,listLength(states),listArray(explst));
        ((contstartExp,_)) = Expression.traverseExp(contExp, changeVarToStartValue, BackendVariable.daeVars(isyst));
        (contstartExp,_) = ExpressionSimplify.simplify(contstartExp);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrExpStr,("StartExp: ",contstartExp,"\n"));
        vcont = BackendVariable.setVarStartValue(vcont, contstartExp);
        crconexp = Expression.crefExp(crcon);
        setsize = listLength(crstates);
        //eqcont = BackendDAE.EQUATION(crconexp,DAE.IFEXP(DAE.CALL(Absyn.IDENT("initial"),{},DAE.callAttrBuiltinInteger),DAE.ICONST(setsize),contExp),DAE.emptyElementSource);
        eqcont = BackendDAE.EQUATION(crconexp,contExp,DAE.emptyElementSource);
        // generate select equations and when clauses
        (selecteqns,dselecteqns,wclst,varlst) = generateSelectEquations(1,crset,crconexp,List.map(crstates,Expression.crefExp),contstartExp,varlst,List.map(statesvars,BackendVariable.varStartValue),{},{},{},{});
        selecteqns = listAppend(eqcont::selecteqns,dselecteqns);
        varlst = vcont::varlst;
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpEqns,selecteqns);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((wclst,BackendDump.dumpWcStr,"\n","\n")));
        // add Equations and vars
        size = BackendDAEUtil.systemSize(isyst);
        syst = List.fold(varlst,BackendVariable.addVarDAE,isyst);
        syst = List.fold(selecteqns,BackendEquation.equationAddDAE,syst);
        changedeqns = List.intRange2(size,size+listLength(selecteqns));
        // ToDO Fix this, thers chould be used updateIncidenceMatrixScalar
        //syst = BackendDAEUtil.updateIncidenceMatrix(syst, ishared, changedeqns);
        shared = BackendDAEUtil.whenClauseAddDAE(wclst,ishared);
        (hov1,lov,dummystates) = selectDummyStates(listAppend(states,dstates),1,varSize,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov,syst,shared);             
    // dummy derivative case - no dynamic state selection // this case will be removed as var c_runtime works well            
    case(_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        rang = listLength(states)-listLength(unassignedEqns);
        (states1,dstates1) = List.split(states, rang);
        dstates1 = listAppend(dstates1,dstates);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrIntStrIntStr, ("Select ",rang," from ",listLength(states),"\n"));   
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states1,BackendDAETransform.dumpStates,"\n","\n")));     
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dstates1,BackendDAETransform.dumpStates,"\n","\n")));  
        (hov1,lov,dummystates) = selectDummyStates(dstates1,1,eqnsSize,vars,hov,inLov,inDummyStates);
      then
        (hov1,dummystates,lov,isyst,ishared); 
  end matchcontinue;
end selectDummyDerivatives2;


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
  (oEqns,odEqns,oWc,osetvarlst) := matchcontinue(indx,crset,contexp,states,contstartExp,ivarlst,istartvalues,iEqns,idEqns,iWc,isetvarlst)
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
        con = DAE.RELATION(crconexppre,DAE.GREATER(DAE.T_REAL_DEFAULT),DAE.ICONST(indx),0,NONE());
        coni = DAE.LBINARY(DAE.CALL(Absyn.IDENT("initial"),{},DAE.callAttrBuiltinBool),DAE.OR(DAE.T_BOOL_DEFAULT),con);
        //eqn = BackendDAE.EQUATION(cre,DAE.IFEXP(coni,e1,e2),DAE.emptyElementSource);
        eqn = BackendDAE.EQUATION(cre,DAE.IFEXP(con,e1,e2),DAE.emptyElementSource);
        //deqn = BackendDAE.EQUATION(DAE.CALL(Absyn.IDENT("der"),{cre},DAE.callAttrBuiltinReal),DAE.IFEXP(coni,DAE.CALL(Absyn.IDENT("der"),{e1},DAE.callAttrBuiltinReal),DAE.CALL(Absyn.IDENT("der"),{e2},DAE.callAttrBuiltinReal)),DAE.emptyElementSource);
        deqn = BackendDAE.EQUATION(DAE.CALL(Absyn.IDENT("der"),{cre},DAE.callAttrBuiltinReal),DAE.IFEXP(con,DAE.CALL(Absyn.IDENT("der"),{e1},DAE.callAttrBuiltinReal),DAE.CALL(Absyn.IDENT("der"),{e2},DAE.callAttrBuiltinReal)),DAE.emptyElementSource);
        con = DAE.RELATION(contexp,DAE.GREATER(DAE.T_REAL_DEFAULT),DAE.ICONST(indx),0,NONE());
        wc = BackendDAE.WHEN_CLAUSE(con,{BackendDAE.REINIT(cr,e1,DAE.emptyElementSource)},NONE());
        wc1 = BackendDAE.WHEN_CLAUSE(DAE.LUNARY(DAE.NOT(DAE.T_BOOL_DEFAULT),con),{BackendDAE.REINIT(cr,e2,DAE.emptyElementSource)},NONE());
        (startcond,_) = ExpressionSimplify.simplify(DAE.IFEXP(DAE.RELATION(contstartExp,DAE.GREATER(DAE.T_REAL_DEFAULT),DAE.ICONST(indx),0,NONE()),es1,es2));
        var = BackendVariable.setVarStartValue(var,startcond);
        (eqns,deqns,wclst,varlst1) = generateSelectEquations(indx+1,crlst,contexp,e2::explst,contstartExp,varlst,es2::startvalues,eqn::iEqns,deqn::idEqns,wc1::(wc::iWc),var::isetvarlst);
      then
        (eqns,deqns,wclst,varlst1);
  end matchcontinue;
end generateSelectEquations;

protected function generateCondition
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
     then
       DAE.IFEXP(expCond, DAE.ICONST(p), DAE.ICONST(1));
                
  end matchcontinue;
end generateCondition;

protected function generateCondition1
  input Integer p1;
  input Integer p2;
  input Integer size;
  input array<DAE.Exp> inExps;
  output DAE.Exp outCont; 
algorithm
  outCont:= matchcontinue(p1,p2,size,inExps)
    local
      Integer p;
      DAE.Exp expCond,expThen,expElse,e1,e2;
    case(_,_,_,_)
      equation
        true = intLt(p2,size);
        e1 = inExps[p1];
        e2 = inExps[p2];
        expCond = DAE.RELATION(DAE.CALL(Absyn.IDENT("abs"),{e1},DAE.callAttrBuiltinReal),DAE.LESS(DAE.T_REAL_DEFAULT),DAE.CALL(Absyn.IDENT("abs"),{e2},DAE.callAttrBuiltinReal),0,NONE());
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
      then
        DAE.IFEXP(expCond, DAE.ICONST(p2), DAE.ICONST(p1));        
  end matchcontinue;
end generateCondition1;

protected function generateCondition2
  input Integer p1;
  input Integer p2;
  input Integer size;
  input array<DAE.Exp> inExps;
  output DAE.Exp outCont; 
algorithm
  outCont:= matchcontinue(p1,p2,size,inExps)
    local
      Integer p;
      DAE.Exp expCond,expThen,expElse,e1,e2;
    case(_,_,_,_)
      equation
        true = intLt(p2,size);
        e1 = inExps[p1];
        e2 = inExps[p2];
        expCond = DAE.RELATION(DAE.CALL(Absyn.IDENT("abs"),{e1},DAE.callAttrBuiltinReal),DAE.LESS(DAE.T_REAL_DEFAULT),DAE.CALL(Absyn.IDENT("abs"),{e2},DAE.callAttrBuiltinReal),0,NONE());
        expThen = generateCondition2(p2,p2+1,size,inExps);
      then
        DAE.IFEXP(expCond, expThen, DAE.ICONST(0));
    case(_,_,_,_)
      equation
        false = intLt(p2,size);
        e1 = inExps[p1];
        e2 = inExps[p2];
        expCond = DAE.RELATION(DAE.CALL(Absyn.IDENT("abs"),{e1},DAE.callAttrBuiltinReal),DAE.LESS(DAE.T_REAL_DEFAULT),DAE.CALL(Absyn.IDENT("abs"),{e2},DAE.callAttrBuiltinReal),0,NONE());
      then
        DAE.IFEXP(expCond, DAE.ICONST(p2), DAE.ICONST(p1));        
  end matchcontinue;
end generateCondition2;

protected function differentiateExp
  input DAE.ComponentRef cr;
  input DAE.Exp exp;
  output DAE.Exp dexp;
algorithm
  dexp := Derive.differentiateExp(exp, cr, true);
  (dexp,_) := ExpressionSimplify.simplify(dexp);
end differentiateExp;

protected function generateVar
  input DAE.ComponentRef cr;
  input BackendDAE.VarKind varKind;
  input DAE.Type varType;
  input Option<DAE.VariableAttributes> attr;
  output BackendDAE.Var var;
algorithm
  var := BackendDAE.VAR(cr,varKind,DAE.BIDIR(),DAE.NON_PARALLEL(),varType,NONE(),NONE(),{},0,DAE.emptyElementSource,attr,NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM_CONNECTOR());
end generateVar;

protected function getStateSetNames
  input list<DAE.ComponentRef> states;
  output list<DAE.ComponentRef> crset;
  output DAE.ComponentRef crcont;
  output list<BackendDAE.Var> ovars;
algorithm
  (crset,crcont,ovars)  := matchcontinue(states)
      local
        DAE.ComponentRef cr,cr1,set,cont;
        list<DAE.ComponentRef> crlst,crlst1;
        list<Boolean> blst;
        DAE.Type tp;
        Integer size,setsize;
        list<Integer> range;
        list<BackendDAE.Var> vars;
        BackendDAE.Var vcont;
        DAE.VariableAttributes attr;
      case(cr::cr1::{})
        equation
          cr = ComponentReference.joinCrefs(cr1, cr);
          size = listLength(states);
          setsize = size-1;
          tp = Util.if_(intEq(listLength(states),2),DAE.T_REAL_DEFAULT,DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(setsize)}, DAE.emptyTypeSource));
          set = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("set",tp,{}));
          cont = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("cont",DAE.T_INTEGER_DEFAULT,{}));
          crlst1 = {set};
          vars = List.map3(crlst1,generateVar,BackendDAE.STATE(),DAE.T_REAL_DEFAULT,NONE());
          vars = List.map1(vars,BackendVariable.setVarFixed,false);
          attr = DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),SOME(DAE.ICONST(size)),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
          vcont = generateVar(cont,BackendDAE.DISCRETE(),DAE.T_INTEGER_DEFAULT,SOME(attr));
        then
          (crlst1,cont,vcont::vars);        
      case(_)
        equation
          cr::crlst1 = List.map(states,ComponentReference.crefStripLastSubs);
          blst = List.map1(crlst1,ComponentReference.crefEqualNoStringCompare,cr);
          true = Util.boolAndList(blst);
          size = listLength(states);
          setsize = size-1;
          tp = Util.if_(intLt(listLength(states),3),DAE.T_REAL_DEFAULT,DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(setsize)}, DAE.emptyTypeSource));
          set = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("set",tp,{}));
          cont = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("cont",DAE.T_INTEGER_DEFAULT,{}));
          range = List.intRange(listLength(states)-1);
          crlst1 = List.map1r(range, ComponentReference.subscriptCrefWithInt, set);
          vars = List.map3(crlst1,generateVar,BackendDAE.STATE(),DAE.T_REAL_DEFAULT,NONE());
          vars = List.map1(vars,BackendVariable.setVarFixed,false);
          vcont = generateVar(cont,BackendDAE.DISCRETE(),DAE.T_INTEGER_DEFAULT,SOME(DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),SOME(DAE.ICONST(size)),NONE(),NONE(),NONE(),NONE(),NONE(),NONE())));
        then
          (crlst1,cont,vcont::vars);
      case(cr::crlst)
        equation
          cr = List.fold(crlst, ComponentReference.joinCrefs, cr);
          size = listLength(states);
          setsize = size-1;
          tp = Util.if_(intEq(listLength(states),2),DAE.T_REAL_DEFAULT,DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(setsize)}, DAE.emptyTypeSource));
          set = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("set",tp,{}));
          cont = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("cont",DAE.T_INTEGER_DEFAULT,{}));
          range = List.intRange(listLength(states)-1);
          crlst1 = List.map1r(range,ComponentReference.subscriptCrefWithInt,set);
          vars = List.map3(crlst1,generateVar,BackendDAE.STATE(),DAE.T_REAL_DEFAULT,NONE());
          vars = List.map1(vars,BackendVariable.setVarFixed,false);
          vcont = generateVar(cont,BackendDAE.DISCRETE(),DAE.T_INTEGER_DEFAULT,SOME(DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),SOME(DAE.ICONST(size)),NONE(),NONE(),NONE(),NONE(),NONE(),NONE())));
        then
          (crlst1,cont,vcont::vars);          
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
  fails if var is StateSelect.always"
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
      Integer r,c;
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
  input array<Integer> mapIncRowEqn;
  input list<Integer> ichangedeqns;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;  
  output list<Integer> ochangedeqns;
algorithm
  (osyst,oshared,ochangedeqns) := 
  match (dummyStates,isyst,ishared,inAss1,inAss2,mapIncRowEqn,ichangedeqns)
    local
     DAE.ComponentRef cr,dcr;
     BackendDAE.EqSystem syst;
     BackendDAE.Shared shared;
     array<Integer> vec1,vec2;
     list<DAE.ComponentRef> rest;
     Integer i,e;
     list<Integer> changedeqns;
    case ({},_,_,_,_,_,_) then (isyst,ishared,List.unique(ichangedeqns));
    case (cr::rest,_,_,_,_,_,_)
      equation
        (_,i::_) = BackendVariable.getVarDAE(cr,isyst);
        (_,syst,shared,changedeqns) = BackendDAETransform.makeDummyState(cr,i,isyst,ishared,mapIncRowEqn);
        e = inAss1[i];
        _ = Debug.bcallret3(intGt(e,0), arrayUpdate, inAss1, e, -1, inAss1);
        _ = Debug.bcallret3(intGt(i,0), arrayUpdate, inAss2, i, -1, inAss2);
        (syst,shared,changedeqns) = addDummyStates(rest,syst,shared,inAss1,inAss2,mapIncRowEqn,listAppend(ichangedeqns,changedeqns));
      then 
        (syst,shared,changedeqns);
  end match;
end addDummyStates;

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
         BackendDump.dumpEqSystem(syst);
         (m,mt) = BackendDAEUtil.incidenceMatrix(syst, shared, BackendDAE.NORMAL());
         BackendDump.dumpIncidenceMatrixT(mt);
         
         SOME(jac) = BackendDAEUtil.calculateJacobian(vars, eqns, m, mt,true);
         jac = listReverse(jac);
         print("Jac:\n" +& BackendDump.dumpJacobianStr(SOME(jac)) +& "\n");
         
         // generate Determinant
         // base is jacobian of the system
         determinant(jac,BackendDAEUtil.systemSize(syst));

      then
        (syst,(shared,false));
  end matchcontinue;  
end tryDeterminant0;


protected function determinant
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
  //print("Starte Determinantenberechnung mit 1. Node\n");
  zycles := determinantEdges(digraph[1],size,1,{1},{},1,1,digraph,{});
  //dumpzycles(zycles,size);
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
    case({},_) then iDigraph;
    case((i,j,BackendDAE.RESIDUAL_EQUATION(exp = e))::rest,_)
      equation
        ilst = iDigraph[j];
        _ = arrayUpdate(iDigraph,j,(i,e)::ilst);
      then
        getDeterminantDigraph(rest,iDigraph);
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
      Boolean nostate;

     case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})}),(vars,eqns,so,ilst)))
      equation
        dummyder = BackendDAETransform.getStateOrder(cr,so);
        (v::_,i::_) = BackendVariable.getVar(dummyder,vars);
        nostate = not BackendVariable.isStateVar(v);
        v = Debug.bcallret2(nostate,BackendVariable.setVarKind,v, BackendDAE.STATE(), v);
        vars_1 = Debug.bcallret2(nostate, BackendVariable.addVar,v, vars,vars);
        e = Expression.crefExp(dummyder);
        ilst = List.consOnTrue(nostate, i, ilst);
      then
        ((DAE.CALL(Absyn.IDENT("der"),{e},DAE.callAttrBuiltinReal), (vars,eqns,so,ilst)));

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
        ((DAE.CALL(Absyn.IDENT("der"),{e},DAE.callAttrBuiltinReal), (vars_1,eqns_1,so1,ilst)));

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
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.NO_MATCHING()),_,NONE(),_)      
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        (_,m,mt) = BackendDAEUtil.getIncidenceMatrix(isyst,ishared,BackendDAE.NORMAL());
        mapIncRowEqn = listArray(List.intRange(arrayLength(m)));
        //(_,m,mt,_,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(isyst,ishared,BackendDAE.NORMAL());
        graph = GraphML.getGraph("G",false);  
        ((_,graph)) = BackendVariable.traverseBackendDAEVars(vars,addVarGraph,(1,graph));
        neqns = BackendDAEUtil.equationArraySize(eqns);
        //neqns = BackendDAEUtil.equationSize(eqns);
        eqnsids = List.intRange(neqns);
        graph = List.fold2(eqnsids,addEqnGraph,eqns,mapIncRowEqn,graph);
        ((_,_,graph)) = List.fold(eqnsids,addEdgesGraph,(1,m,graph));
        GraphML.dumpGraph(graph,filename);
     then
       ();
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=vec1,ass2=vec2)),_,NONE(),_)      
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        //(_,m,mt) = BackendDAEUtil.getIncidenceMatrix(isyst,ishared,BackendDAE.NORMAL());
        //mapIncRowEqn = listArray(List.intRange(arrayLength(m)));
        (_,m,mt,_,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(isyst,ishared,BackendDAE.NORMAL());
        graph = GraphML.getGraph("G",false);  
        ((_,_,graph)) = BackendVariable.traverseBackendDAEVars(vars,addVarGraphMatch,(1,vec1,graph));
        //neqns = BackendDAEUtil.equationArraySize(eqns);
        neqns = BackendDAEUtil.equationSize(eqns);
        eqnsids = List.intRange(neqns);
        graph = List.fold2(eqnsids,addEqnGraphMatch,eqns,(vec2,mapIncRowEqn),graph);
        //graph = List.fold3(eqnsids,addEqnGraphMatch,eqns,vec2,mapIncRowEqn,graph);
        ((_,_,_,graph)) = List.fold(eqnsids,addDirectedEdgesGraph,(1,m,vec2,graph));
        GraphML.dumpGraph(graph,filename);
     then
       ();
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=vec1,ass2=vec2)),_,SOME(vec3),_)      
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        (_,m,mt,_,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(isyst,ishared,BackendDAE.NORMAL());
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
        //g = GraphML.addNode("v" +& intString(id),ComponentReference.printComponentRefStr(cr),GraphML.COLOR_BLUE,GraphML.ELLIPSE(),g);
        //g = GraphML.addNode("v" +& intString(id),intString(id),GraphML.COLOR_BLUE,GraphML.ELLIPSE(),g);
        g = GraphML.addNode("v" +& intString(id),intString(id) +& ": " +& ComponentReference.printComponentRefStr(cr),GraphML.COLOR_BLUE,GraphML.ELLIPSE(),g);
      then ((v,(id+1,g)));      
    case ((v as BackendDAE.VAR(varName=cr),(id,g)))
      equation
        //g = GraphML.addNode("v" +& intString(id),ComponentReference.printComponentRefStr(cr),GraphML.COLOR_RED,GraphML.ELLIPSE(),g);
        //g = GraphML.addNode("v" +& intString(id),intString(id),GraphML.COLOR_RED,GraphML.ELLIPSE(),g);
        g = GraphML.addNode("v" +& intString(id),intString(id) +& ": " +&ComponentReference.printComponentRefStr(cr),GraphML.COLOR_RED,GraphML.ELLIPSE(),g);
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
    case inTpl then inTpl;
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
  str := BackendDump.equationStr(eqn);
  //str := intString(inNode);
  str := intString(inNode) +& ": " +& BackendDump.equationStr(eqn);
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
  ((id,graph)) := List.fold1(vars,addEdgeGraph,e,(id,graph));     
  outTpl := (id,m,graph);  
end addEdgesGraph;

protected function addEqnGraphMatch
  input Integer inNode;
  input BackendDAE.EquationArray eqns;
  input tuple<array<Integer>,array<Integer>> atpl;
//  input array<Integer> vec2;
//  input array<Integer> mapIncRowEqn;
  input GraphML.Graph inGraph;
  output GraphML.Graph outGraph;
protected
  BackendDAE.Equation eqn;
  String str,color;
  Integer t;
  array<Integer> vec2,mapIncRowEqn;
algorithm
  (vec2,mapIncRowEqn) := atpl;
  eqn := BackendDAEUtil.equationNth(eqns, mapIncRowEqn[inNode]-1);
  str := BackendDump.equationStr(eqn);
  str := intString(mapIncRowEqn[inNode]) +& ": " +&  str;
  //str := intString(inNode);
  color := Util.if_(intGt(vec2[inNode],0),GraphML.COLOR_GREEN,GraphML.COLOR_PURPLE);
  outGraph := GraphML.addNode("n" +& intString(inNode),str,color,GraphML.RECTANGLE(),inGraph); 
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
