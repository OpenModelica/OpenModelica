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

encapsulated package Tearing
" file:        Tearing.mo
  package:     Tearing
  description: Tearing contains functions used for tear strong connected components.
               Implemented Methods are:
               - omc tearing developed by TU Dresden: Frenkel,Schubert
               - Cellier tearing

         RCS: $Id: Tearing.mo 13560 2012-10-22 23:00:33Z jfrenkel $"

public import BackendDAE;
public import DAE;

protected import BackendDAEEXT;
protected import BackendDAEUtil;
protected import BackendDAETransform;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import Config;
protected import Debug;
protected import Error;
protected import Flags;
protected import List;
protected import Matching;
protected import Util;

// =============================================================================
// section for type definitions
//
// 
// =============================================================================

protected constant String BORDER    = "****************************************";
protected constant String UNDERLINE = "================================================================================";

uniontype TearingMethod
  record OMC_TEARING end OMC_TEARING;
  record CELLIER_TEARING end CELLIER_TEARING;
end TearingMethod;

// =============================================================================
// section for all public functions
//
// main function to divide to the selected tearing method
// =============================================================================

public function tearingSystem "author: Frenkel TUD 2012-05"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := matchcontinue(inDAE)
    local
      String methodString;
      TearingMethod method;
      BackendDAE.BackendDAEType DAEtype;
      BackendDAE.Shared shared;
      
    // if noTearing is selected, do nothing.
    case(_) equation
      methodString = Config.getTearingMethod();
      true = stringEqual(methodString, "noTearing");
    then inDAE;
    
    // get method function and traveres systems
    case(_) equation
      //Debug.fcall2(Flags.TEARING_DUMPVERBOSE, BackendDump.dumpBackendDAE, inDAE, "DAE");
      methodString = Config.getTearingMethod();
      method = getTearingMethod(methodString);
      BackendDAE.DAE(shared=shared) = inDAE;
      BackendDAE.SHARED(backendDAEType=DAEtype) = shared;
      Debug.fcall(Flags.TEARING_DUMP, print, "\n\n\n\n" +& UNDERLINE +& "\nCalling Tearing for ");
      Debug.fcall(Flags.TEARING_DUMP, BackendDump.printBackendDAEType, DAEtype);
      Debug.fcall(Flags.TEARING_DUMP, print, "!\n" +& UNDERLINE +& "\n");
      (outDAE, _) = BackendDAEUtil.mapEqSystemAndFold(inDAE, tearingSystemWork, method);
    then outDAE;
    
    else equation
      Error.addInternalError("./Compiler/BackEnd/Tearing.mo: function tearingSystem failed");
    then fail();
  end matchcontinue;
end tearingSystem;

// =============================================================================
// protected
//
//
// =============================================================================

protected function getTearingMethod
  input String inTearingMethod;
  output TearingMethod outTearingMethod;
algorithm
  outTearingMethod := matchcontinue(inTearingMethod)
    case (_) equation
      true = stringEqual(inTearingMethod, "omcTearing");
    then OMC_TEARING();
    
    case (_) equation
      true = stringEqual(inTearingMethod, "cellier");
    then CELLIER_TEARING();
  
    else equation
      Error.addInternalError("./Compiler/BackEnd/Tearing.mo: function getTearingMethod failed");
    then fail();
  end matchcontinue;
end getTearingMethod;

protected function callTearingMethod
  input TearingMethod inTearingMethod;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> eindex;
  input list<Integer> vindx;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> ojac;
  input BackendDAE.JacobianType jacType;
  output BackendDAE.StrongComponent ocomp;
  output Boolean outRunMatching;
algorithm
  (ocomp, outRunMatching) := match(inTearingMethod, isyst, ishared, eindex, vindx, ojac, jacType)
    case(OMC_TEARING(), _, _, _, _, _, _) 
   equation
         (ocomp,outRunMatching)=omcTearing(isyst, ishared, eindex, vindx, ojac, jacType);
      then (ocomp,outRunMatching);
    
    case(CELLIER_TEARING(), _, _, _, _, _, _) 
   equation
      (ocomp,outRunMatching)=CellierTearing(isyst, ishared, eindex, vindx, ojac, jacType);
      then (ocomp,outRunMatching);
  
  end match;
end callTearingMethod;

protected function tearingSystemWork "author: Frenkel TUD 2012-05"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared, TearingMethod> sharedChanged;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared, TearingMethod> osharedChanged;
protected
  BackendDAE.StrongComponents comps;
  TearingMethod method;
  Boolean b;
  BackendDAE.Shared shared;
  array<Integer> ass1, ass2;
algorithm
  BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=ass1, ass2=ass2, comps=comps)):=isyst;
  (shared, method) := sharedChanged;
  Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, "\n" +& BORDER +& "\nBEGINNING of traverseComponents\n\n");
  (comps, b) := traverseComponents(comps, isyst, shared, method, {}, false);
  Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, "\nEND of traverseComponents\n" +& BORDER +& "\n\n");
  osyst := Debug.bcallret2(b, BackendDAEUtil.setEqSystemMatching, isyst, BackendDAE.MATCHING(ass1, ass2, comps), isyst);
  osharedChanged := sharedChanged;
end tearingSystemWork;

protected function traverseComponents "author: Frenkel TUD 2012-05"
  input BackendDAE.StrongComponents inComps;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input TearingMethod inMethod;
  input BackendDAE.StrongComponents iAcc;
  input Boolean iRunMatching;
  output BackendDAE.StrongComponents oComps;
  output Boolean outRunMatching;
algorithm
  (oComps, outRunMatching) := matchcontinue (inComps, isyst, ishared, inMethod, iAcc, iRunMatching)
    local
      list<Integer> eindex, vindx;
      Boolean b, b1;
      BackendDAE.StrongComponents comps, acc;
      BackendDAE.StrongComponent comp, comp1;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> ojac;
      BackendDAE.JacobianType jacType;
      
    case ({}, _, _, _, _, _)
    then (listReverse(iAcc), iRunMatching);
    
    // don't tear linear system as long as we do not handle them
    // as linear system while the runtime
    case ((comp as BackendDAE.EQUATIONSYSTEM(eqns=eindex, vars=vindx, jac=BackendDAE.FULL_JACOBIAN(ojac), jacType=jacType))::comps, _, _, _, _, _) equation
      equality(jacType = BackendDAE.JAC_TIME_VARYING());
      Debug.fcall(Flags.TEARING_DUMP, print, "\nCase linear in traverseComponents\nUse Flag '+d=tearingdumpV' for more details\n\n");
      true = Flags.isSet(Flags.LINEAR_TEARING);
      Debug.fcall(Flags.TEARING_DUMP, print, "Flag 'doLinearTearing' is set\n\n");
      Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, "Jacobian:\n" +& BackendDump.dumpJacobianStr(ojac) +& "\n\n");
      (comp1, true) = callTearingMethod(inMethod, isyst, ishared, eindex, vindx, ojac, jacType);
      (acc, b1) = traverseComponents(comps, isyst, ishared, inMethod, comp1::iAcc, true);
    then (acc, b1);
        
    // tearing of non-linear systems
    case ((comp as BackendDAE.EQUATIONSYSTEM(eqns=eindex, vars=vindx, jac=BackendDAE.FULL_JACOBIAN(ojac), jacType=jacType))::comps, _, _, _, _, _) equation
      failure(equality(jacType = BackendDAE.JAC_TIME_VARYING()));
      Debug.fcall(Flags.TEARING_DUMP, print, "\nCase non-linear in traverseComponents\nUse Flag '+d=tearingdumpV' for more details\n\n");
      Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, "Jacobian:\n" +& BackendDump.dumpJacobianStr(ojac) +& "\n\n");
      (comp1, true) = callTearingMethod(inMethod, isyst, ishared, eindex, vindx, ojac, jacType);
      (acc, b1) = traverseComponents(comps, isyst, ishared, inMethod, comp1::iAcc, true);
    then (acc, b1);
        
    // only continues part of a mixed system
    case ((comp as BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp1, disc_eqns=eindex, disc_vars=vindx))::comps, _, _, _, _, _) equation
      Debug.fcall(Flags.TEARING_DUMP, print, "\nCase mixed in traverseComponents\nUse '+d=tearingdumpV' for more details\n\n");
      false = Flags.isSet(Flags.MIXED_TEARING);
      Debug.fcall(Flags.TEARING_DUMP, print, "Flag 'MixedTearing' is not set\n(disabled by user)\n\n");
      (comp1::{}, true) = traverseComponents({comp1}, isyst, ishared, inMethod, {}, false);
      (acc, b1) = traverseComponents(comps, isyst, ishared, inMethod, BackendDAE.MIXEDEQUATIONSYSTEM(comp1, eindex, vindx)::iAcc, true);
    then (acc, b1);
    
    // mixed and continues part
    case ((comp as BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp1, disc_eqns=eindex, disc_vars=vindx))::comps, _, _, _, _, _) equation
      true = Flags.isSet(Flags.MIXED_TEARING);
      Debug.fcall(Flags.TEARING_DUMP, print, "Flag 'MixedTearing' is set\n(enabled by default)\n\n");
      (eindex, vindx) = BackendDAETransform.getEquationAndSolvedVarIndxes(comp);
      (comp1, true) = callTearingMethod(inMethod, isyst, ishared, eindex, vindx, NONE(), BackendDAE.JAC_NO_ANALYTIC());
      (acc, b1) = traverseComponents(comps, isyst, ishared, inMethod, comp1::iAcc, true);
    then (acc, b1);
        
    // no component for tearing
    case (comp::comps, _, _, _, _, _) equation
      (acc, b) = traverseComponents(comps, isyst, ishared, inMethod, comp::iAcc, iRunMatching);
    then (acc, b);
  end matchcontinue;
end traverseComponents;







// =============================================================================
//
// method: omc tearing
//
// =============================================================================

protected function omcTearing "  author: Frenkel TUD 2012-05"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> eindex;
  input list<Integer> vindx;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> ojac;
  input BackendDAE.JacobianType jacType;
  output BackendDAE.StrongComponent ocomp;
  output Boolean outRunMatching;
protected
  list<Integer> tvars,residual,unsolvables;
  list<list<Integer>> othercomps;
  BackendDAE.EqSystem syst,subsyst;
  BackendDAE.Shared shared;
  array<Integer> ass1,ass2,columark,number,lowlink;
  Integer size,tornsize,mark;
  list<BackendDAE.Equation> eqn_lst;
  list<BackendDAE.Var> var_lst;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.IncidenceMatrix m,m1;
  BackendDAE.IncidenceMatrix mt,mt1;
  BackendDAE.AdjacencyMatrixEnhanced me;
  BackendDAE.AdjacencyMatrixTEnhanced meT;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  DAE.FunctionTree funcs;
  array<Boolean> stackflag;
  list<Integer> asslst1, asslst2;
algorithm
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n" +& BORDER +& "\nBEGINNING of omcTearing\n\n");
  // generate Subsystem to get the incidence matrix
  size := listLength(vindx);
  eqn_lst := BackendEquation.getEqns(eindex,BackendEquation.daeEqns(isyst));
  eqns := BackendEquation.listEquation(eqn_lst);
  var_lst := List.map1r(vindx, BackendVariable.getVarAt, BackendVariable.daeVars(isyst));
  vars := BackendVariable.listVar1(var_lst);
  subsyst := BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING(),{});
  funcs := BackendDAEUtil.getFunctions(ishared);
  (subsyst,m,mt,_,_) := BackendDAEUtil.getIncidenceMatrixScalar(subsyst, BackendDAE.NORMAL(), SOME(funcs));
     //  IndexReduction.dumpSystemGraphML(subsyst,ishared,NONE(),"System" +& intString(size) +& ".graphml");
     Debug.fcall(Flags.TEARING_DUMP, print, "\n\n###BEGIN print Strong Component#####################\n(Function:omcTearing)\n");
     Debug.fcall(Flags.TEARING_DUMP, BackendDump.printEqSystem, subsyst);
     Debug.fcall(Flags.TEARING_DUMP, print, "\n###END print Strong Component#######################\n(Function:omcTearing)\n\n\n");
  (me,meT,mapEqnIncRow,mapIncRowEqn) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(subsyst,ishared);
     Debug.fcall(Flags.TEARING_DUMP, print, "\n\nAdjacencyMatrixEnhanced:\n");
     Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpAdjacencyMatrixEnhanced,me);
     Debug.fcall(Flags.TEARING_DUMP, print,"\nAdjacencyMatrixTransposedEnhanced:\n");
     Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpAdjacencyMatrixTEnhanced,meT);
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nmapEqnIncRow:"); //+& stringDelimitList(List.map(List.flatten(arrayList(mapEqnIncRow)),intString),",") +& "\n\n");
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, BackendDump.dumpIncidenceMatrix, mapEqnIncRow);
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nmapIncRowEqn:\n" +& stringDelimitList(List.map(arrayList(mapIncRowEqn),intString),",") +& "\n\n");
  
  ass1 := arrayCreate(size,-1);
  ass2 := arrayCreate(size,-1);
  // get all unsolvable variables
  unsolvables := getUnsolvableVars(1,size,meT,{});
     Debug.fcall(Flags.TEARING_DUMP, print,"\n\nUnsolvable Vars:\n");
     Debug.fcall(Flags.TEARING_DUMP, BackendDump.debuglst,(unsolvables,intString,", ","\n"));
  columark := arrayCreate(size,-1);
  
  // determine tvars and do cheap matching until a maximum matching is there
  // if cheap matching stucks select additional tearing variable and continue
  // (mark+1 for every call of omcTearing3)
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n" +& BORDER +& "\nBEGINNING of omcTearing2\n\n");
  (tvars,mark) := omcTearing2(unsolvables,me,meT,mapEqnIncRow,mapIncRowEqn,size,vars,ishared,ass1,ass2,columark,1,{});
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nEND of omcTearing2\n" +& BORDER +& "\n\n");
 
  // unassign tvars  
  ass1 := List.fold(tvars,unassignTVars,ass1);
     Debug.fcall(Flags.TEARING_DUMP, print,"\nBFS RESULTS:\nass1: "+& stringDelimitList(List.map(arrayList(ass1),intString),",") +&"\n");
     Debug.fcall(Flags.TEARING_DUMP, print,"ass2: "+& stringDelimitList(List.map(arrayList(ass2),intString),",") +&"\n\n");

  // unmatched equations are residual equations
  residual := Matching.getUnassigned(size,ass2,{});
     //  subsyst := BackendDAEUtil.setEqSystemMatching(subsyst,BackendDAE.MATCHING(ass1,ass2,{}));
     //  IndexReduction.dumpSystemGraphML(subsyst,ishared,NONE(),"TornSystem" +& intString(size) +& ".graphml");
  
  // check if tearing makes sense
  tornsize := listLength(tvars);
  true := intLt(tornsize,size-1);
  
  // create incidence matrices w/o tvar and residual
  m1 := arrayCreate(size,{});
  mt1 := arrayCreate(size,{});
  m1 := getOtherEqSysIncidenceMatrix(m,size,1,ass2,ass1,m1);
  mt1 := getOtherEqSysIncidenceMatrix(mt,size,1,ass1,ass2,mt1);
  // run tarjan to get order of other equations
  number := arrayCreate(size,0);
  lowlink := arrayCreate(size,0);
  stackflag := arrayCreate(size,false);
  number := setIntArray(residual,number,size);
  (_,othercomps) := BackendDAETransform.strongConnectMain(mt1, ass2, number, lowlink, stackflag, size, 1, {}, {});
     Debug.fcall(Flags.TEARING_DUMP, print, "\nOtherEquationsOrder:\n");
     Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpComponentsOLD,othercomps);
     Debug.fcall(Flags.TEARING_DUMP, print, "\n");
  
  // calculate influence of tearing vars in residual equations
  // mt1: row=variable, columns: tvars, that influence the result of the variable
  mt1 := arrayCreate(size, {});
  mark := getDependenciesOfVars(othercomps, ass1, ass2, m, mt1, columark, mark);
    
  (residual, mark) := sortResidualDepentOnTVars(residual, tvars, ass1, m, mt1, columark, mark);
  (ocomp,outRunMatching) := omcTearing4(jacType,isyst,ishared,subsyst,tvars,residual,ass1,ass2,othercomps,eindex,vindx,mapEqnIncRow,mapIncRowEqn,columark,mark);
    
     Debug.fcall(Flags.TEARING_DUMP, print,Util.if_(outRunMatching,"\nStatus:\nOk system torn\n\n","\nStatus:\nSystem not torn\n\n"));
     Debug.fcall(Flags.TEARING_DUMP, print, "\n" +& BORDER +& "\n* TEARING RESULTS:\n*\n* No of equations in strong Component: "+&intString(size)+&"\n");
     Debug.fcall(Flags.TEARING_DUMP, print, "* No of tVars: "+&intString(tornsize)+&"\n");
     Debug.fcall(Flags.TEARING_DUMP, print, "*\n* tVars: "+& stringDelimitList(List.map(tvars,intString),",") +& "\n");
     Debug.fcall(Flags.TEARING_DUMP, print, "*\n* resEq: "+& stringDelimitList(List.map(residual,intString),",") +& "\n*\n*");
  BackendDAE.TORNSYSTEM(tearingvars=tvars,residualequations=residual) := ocomp;
     Debug.fcall(Flags.TEARING_DUMP, print, "\n* Related to entire Equationsystem:\n* =====\n* tVars: "+& stringDelimitList(List.map(tvars,intString),",") +& "\n* =====\n");
     Debug.fcall(Flags.TEARING_DUMP, print, "*\n* =====\n* resEq: "+& stringDelimitList(List.map(residual,intString),",") +& "\n* =====\n" +& BORDER +& "\n");
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n\nStrongComponents:\n");
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, BackendDump.dumpComponent,ocomp);
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n\nEND of omcTearing\n" +& BORDER +& "\n\n");
end omcTearing;


protected function getUnsolvableVars
"  author: Frenkel TUD 2012-08"
  input Integer index;
  input Integer size;
  input BackendDAE.AdjacencyMatrixTEnhanced meT;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := matchcontinue(index,size,meT,iAcc)
    local
      BackendDAE.AdjacencyMatrixElementEnhanced elem;
      list<Integer> acc;
      Boolean b;
    case(_,_,_,_)
      equation
        true = intLe(index,size);
        elem = meT[index];
        b = unsolvable(elem);
        acc = List.consOnTrue(b, index, iAcc);
      then
       getUnsolvableVars(index+1,size,meT,acc);
    case(_,_,_,_)
      then
       iAcc;
  end matchcontinue;
end getUnsolvableVars;


protected function unsolvable
"  author: Frenkel TUD 2012-08"
  input BackendDAE.AdjacencyMatrixElementEnhanced elem;
  output Boolean b;
algorithm
  b := match(elem)
    local
      Integer e;
      BackendDAE.AdjacencyMatrixElementEnhanced rest;
      Boolean b1;
    case ({}) then true;
    case ((e,BackendDAE.SOLVABILITY_SOLVED())::rest)
      equation
        b1 = intLe(e,0);
        b1 = Debug.bcallret1(b1, unsolvable, rest, false);
      then
        b1;
    case ((e,BackendDAE.SOLVABILITY_CONSTONE())::rest)
      equation
        b1 = intLe(e,0);
        b1 = Debug.bcallret1(b1, unsolvable, rest, false);
      then
        b1;
    case ((e,BackendDAE.SOLVABILITY_CONST())::rest)
      equation
        b1 = intLe(e,0);
        b1 = Debug.bcallret1(b1, unsolvable, rest, false);
      then
        b1;
    case ((e,BackendDAE.SOLVABILITY_PARAMETER(b=false))::rest)
      then
        unsolvable(rest);
    case ((e,BackendDAE.SOLVABILITY_PARAMETER(b=true))::rest)
      equation
        b1 = intLe(e,0);
        b1 = Debug.bcallret1(b1, unsolvable, rest, false);
      then
        b1;
    case ((e,BackendDAE.SOLVABILITY_TIMEVARYING(b=false))::rest)
      then
        unsolvable(rest);
    case ((e,BackendDAE.SOLVABILITY_TIMEVARYING(b=true))::rest)
      then
        unsolvable(rest);
    case ((e,BackendDAE.SOLVABILITY_NONLINEAR())::rest)
      then
        unsolvable(rest);
    case ((e,BackendDAE.SOLVABILITY_UNSOLVABLE())::rest)
      then
        unsolvable(rest);
  end match;
end unsolvable;


protected function unassignTVars "  author: Frenkel TUD 2012-05"
  input Integer v;
  input array<Integer> inAss;
  output array<Integer> outAss;
algorithm
  outAss := arrayUpdate(inAss,v,-1);
end unassignTVars;


protected function isAssigned "  author: Frenkel TUD 2012-05"
  input array<Integer> ass;
  input Integer i;
  output Boolean b;
algorithm
  b := intGt(ass[i],0);
end isAssigned;


protected function getOtherEqSysIncidenceMatrix " function to remove tvar and res from incidence matrix
  author: Frenkel TUD 2012-05"
  input BackendDAE.IncidenceMatrix m;
  input Integer size;
  input Integer index;
  input array<Integer> skip;
  input array<Integer> rowskip;
  input BackendDAE.IncidenceMatrix mnew;
  output BackendDAE.IncidenceMatrix outMNew;
algorithm
  outMNew := matchcontinue(m,size,index,skip,rowskip,mnew)
    local
      list<Integer> row;
    case (_,_,_,_,_,_)
      equation
        true = intGt(index,size);
      then
        mnew;
    case (_,_,_,_,_,_)
      equation
        true = intGt(skip[index],0);
        row = List.select(m[index], Util.intPositive);
        row = List.select1r(row,isAssigned,rowskip);
        _ = arrayUpdate(mnew,index,row);
      then
        getOtherEqSysIncidenceMatrix(m,size,index+1,skip,rowskip,mnew);
    case (_,_,_,_,_,_)
      equation
        _ = arrayUpdate(mnew,index,{});
      then
        getOtherEqSysIncidenceMatrix(m,size,index+1,skip,rowskip,mnew);
  end matchcontinue;
end getOtherEqSysIncidenceMatrix;


protected function setIntArray
"  author: Frenkel TUD 2012-08"
  input list<Integer> inLst;
  input array<Integer> arr;
  input Integer value;
  output array<Integer> oarr;
algorithm
  oarr := match(inLst,arr,value)
    local
      Integer indx;
      list<Integer> rest;
    case(indx::rest,_,_)
      equation
        _= arrayUpdate(arr,indx,value);
      then
        setIntArray(rest,arr,value);
    case({},_,_) then arr;
  end match;
end setIntArray;


protected function getDependenciesOfVars " function to determine which variables are influenced by the tvars"
  input list<list<Integer>> iComps;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.IncidenceMatrix m;
  input array<list<Integer>> mT;
  input array<Integer> visited;
  input Integer iMark;
  output Integer oMark;
algorithm
  oMark := match(iComps, ass1, ass2, m, mT, visited, iMark)
    local
      Integer c, v;
      list<Integer> comp, tvars, vars;
      list<list<Integer>> comps;

    case ({}, _, _, _, _, _, _)
    then iMark;

    case ({c}::comps, _, _, _, _, _, _) equation
      // get var of eqn
      v = ass2[c];
      // get TVars of Eqn
      vars = List.select(m[c], Util.intPositive);
      tvars = tVarsofEqn(vars, ass1, mT, visited, iMark, {});
      // update map
      _ = arrayUpdate(mT, v, tvars);
    then getDependenciesOfVars(comps, ass1, ass2, m, mT, visited, iMark+1);

    case (comp::comps, _, _, _, _, _, _) equation
      // get var of eqns
      vars = List.map1r(comp,arrayGet,ass2);
      // get TVars of Eqns
      tvars = tVarsofEqns(comp, m, ass1, mT, visited, iMark, {});
      // update map
      _ = List.fold1r(vars, arrayUpdate, tvars, mT);
    then getDependenciesOfVars(comps, ass1, ass2, m, mT, visited, iMark+1);
  end match;
end getDependenciesOfVars;


protected function tVarsofEqns "determines tvars that influence this equations"
  input list<Integer> iEqns;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> ass1;
  input array<list<Integer>> mT;
  input array<Integer> visited;
  input Integer iMark;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := match(iEqns, m, ass1, mT, visited, iMark, iAcc)
    local
      Integer e;
      list<Integer> eqns, vars, tvars;

    case ({}, _, _, _, _, _, _)
    then iAcc;

    case (e::eqns, _, _, _, _, _, _) equation
      vars = List.select(m[e], Util.intPositive);
      tvars = tVarsofEqn(vars, ass1, mT, visited, iMark, iAcc);
    then tVarsofEqns(eqns, m, ass1, mT, visited, iMark, tvars);
  end match;
end tVarsofEqns;


protected function tVarsofEqn "determines tvars that influence this equation"
  input list<Integer> iVars;
  input array<Integer> ass1;
  input array<list<Integer>> mT;
  input array<Integer> visited;
  input Integer iMark;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := matchcontinue(iVars,ass1,mT,visited,iMark,iAcc)
    local
      Integer v;
      list<Integer> vars,tvars;
    case ({},_,_,_,_,_) then iAcc;
    case (v::vars,_,_,_,_,_)
      equation
        true = intLt(ass1[v],0);
        tvars = uniqueIntLst(v,iMark,visited,iAcc);
      then
        tVarsofEqn(vars,ass1,mT,visited,iMark,tvars);
    case (v::vars,_,_,_,_,_) equation
      tvars = List.fold2(mT[v],uniqueIntLst,iMark,visited,iAcc);
    then tVarsofEqn(vars, ass1, mT, visited, iMark, tvars);
  end matchcontinue;
end tVarsofEqn;


protected function uniqueIntLst
  input Integer c;
  input Integer mark;
  input array<Integer> markarray;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := matchcontinue(c,mark,markarray,iAcc)
    case(_,_,_,_)
      equation
        false = intEq(mark,markarray[c]);
        _ = arrayUpdate(markarray,c,mark);
      then
        c::iAcc;
    else
      then
        iAcc;
  end matchcontinue;
end uniqueIntLst;


protected function sortResidualDepentOnTVars
  input list<Integer> iResiduals;
  input list<Integer> iTVars;
  input array<Integer> ass1;
  input BackendDAE.IncidenceMatrix m;
  input array<list<Integer>> mT;
  input array<Integer> visited;
  input Integer iMark;
  output list<Integer> oResiduals;
  output Integer oMark;
protected
  Integer size;
  list<list<Integer>> maplst;
  array<list<Integer>> map;
  array<Integer> eqnLocalGlobal,varGlobalLocal,v1,v2;
algorithm
  // eqn - local - Global indices
  eqnLocalGlobal := listArray(iResiduals);
  // var - global local indices
  varGlobalLocal := arrayCreate(arrayLength(m),-1);
  varGlobalLocal := getGlobalLocal(iTVars,1,varGlobalLocal);
  // generate list of map[residual]=tvars
  // change indices in map to local
  (oMark,maplst) := tVarsofResidualEqns(iResiduals,m,ass1,mT,varGlobalLocal,visited,iMark,{});
  map := listArray(maplst);
  // get for each residual a tvar
  size := arrayLength(map);
  Matching.matchingExternalsetIncidenceMatrix(size,size,map);
  BackendDAEEXT.matching(size,size,5,-1,1.0,1);
  v1 := arrayCreate(size,-1);
  v2 := arrayCreate(size,-1);
  BackendDAEEXT.getAssignment(v2,v1);
  //  BackendDump.dumpIncidenceMatrix(map);
  //  BackendDump.dumpMatching(v1);
  //  BackendDump.dumpMatching(v2);
  // sort residuals depent on matching to tvars
  oResiduals := getTVarResiduals(size,v1,eqnLocalGlobal,{});
     //print("iResiduals " +& stringDelimitList(List.map(iResiduals,intString),",") +& "\n");
     //print("oResiduals " +& stringDelimitList(List.map(oResiduals,intString),",") +& "\n");
end sortResidualDepentOnTVars;


protected function getGlobalLocal
  input list<Integer> iTVars;
  input Integer index;
  input array<Integer> iVarGlobalLocal;
  output array<Integer> oVarGlobalLocal;
algorithm
oVarGlobalLocal :=
  match(iTVars,index,iVarGlobalLocal)
    local
      Integer i;
      list<Integer> tvars;
    case ({},_,_) then iVarGlobalLocal;
    case (i::tvars,_,_)
      equation
        _= arrayUpdate(iVarGlobalLocal,i,index);
      then
        getGlobalLocal(tvars,index+1,iVarGlobalLocal);
  end match;
end getGlobalLocal;


protected function tVarsofResidualEqns
  input list<Integer> iEqns;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> ass1;
  input array<list<Integer>> mT;
  input array<Integer> varGlobalLocal;
  input array<Integer> visited;
  input Integer iMark;
  input list<list<Integer>> iAcc;
  output Integer oMark;
  output list<list<Integer>> oAcc;
algorithm
  (oMark,oAcc) := match(iEqns,m,ass1,mT,varGlobalLocal,visited,iMark,iAcc)
    local
      Integer e;
      list<Integer> eqns,vars,tvars;
    case ({},_,_,_,_,_,_,_) then (iMark,listReverse(iAcc));
    case (e::eqns,_,_,_,_,_,_,_)
      equation
        vars = List.select(m[e], Util.intPositive);
        tvars = tVarsofEqn(vars,ass1,mT,visited,iMark,{});        
        // change indices to local
        tvars = List.map1r(tvars,arrayGet,varGlobalLocal);
        (oMark,oAcc) = tVarsofResidualEqns(eqns,m,ass1,mT,varGlobalLocal,visited,iMark+1,tvars::iAcc);
      then
        (oMark,oAcc);
  end match;
end tVarsofResidualEqns;


protected function getTVarResiduals
  input Integer index;
  input array<Integer> v1;
  input array<Integer> eqnLocalGlobal;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := match(index,v1,eqnLocalGlobal,iAcc)
    local
      Integer e;
    case (0,_,_,_) then iAcc;
    case (_,_,_,_)
      equation
        e = v1[index];
        e = eqnLocalGlobal[e];
      then
        getTVarResiduals(index-1,v1,eqnLocalGlobal,e::iAcc);
  end match;
end getTVarResiduals;


protected function omcTearing2 " function to determine tvars and do cheap matching
  author: Frenkel TUD 2012-05"
  input list<Integer> unsolvables;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input Integer size;
  input BackendDAE.Variables vars;
  input BackendDAE.Shared ishared;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> columark;
  input Integer mark;
  input list<Integer> inTVars;
  output list<Integer> outTVars;
  output Integer oMark;
algorithm
  (outTVars,oMark) := matchcontinue(unsolvables,m,mt,mapEqnIncRow,mapIncRowEqn,size,vars,ishared,ass1,ass2,columark,mark,inTVars)
    local
      Integer tvar;
      list<Integer> unassigned,rest;
      BackendDAE.AdjacencyMatrixElementEnhanced vareqns;
    // if there are no unsolvables choose tvar by heuristic
    case ({},_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // select tearing var
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n" +& BORDER +& "\nBEGINNING of omcTearingSelectTearingVar\n\n\n");
        tvar = omcTearingSelectTearingVar(vars,ass1,ass2,m,mt);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nEND of omcTearingSelectTearingVar\n" +& BORDER +& "\n\n");
        // mark tearing var
        _ = arrayUpdate(ass1,tvar,size*2);
        // equations not yet assigned containing the tvar
        vareqns = List.removeOnTrue(ass2, isAssignedSaveEnhanced, mt[tvar]);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE,print,"Assignable equations containing tvar:\n");
           Debug.fcall(Flags.TEARING_DUMPVERBOSE,BackendDump.dumpAdjacencyRowEnhanced,vareqns);Debug.fcall(Flags.TEARING_DUMPVERBOSE,print,"\n");
        // cheap matching
        tearingBFS(vareqns,m,mt,mapEqnIncRow,mapIncRowEqn,size,ass1,ass2,columark,mark,{});
        // check for unassigned vars, if there some rerun
        unassigned = Matching.getUnassigned(size,ass1,{});
        (outTVars,oMark) = omcTearing3(unassigned,{},m,mt,mapEqnIncRow,mapIncRowEqn,size,vars,ishared,ass1,ass2,columark,mark+1,tvar::inTVars);
      then
        (outTVars,oMark);
    // if there are unsolvables choose unsolvables as tvars
    case (tvar::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
           Debug.fcall(Flags.TEARING_DUMP,print,"\ntVar: " +& intString(tvar) +& " (unsolvable in omcTearing2)\n\n");
        // mark tearing var
        _ = arrayUpdate(ass1,tvar,size*2);
        // equations not yet assigned containing the tvar
        vareqns = List.removeOnTrue(ass2, isAssignedSaveEnhanced, mt[tvar]);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE,print,"Assignable equations containing tvar:\n");
           Debug.fcall(Flags.TEARING_DUMPVERBOSE,BackendDump.dumpAdjacencyRowEnhanced,vareqns);Debug.fcall(Flags.TEARING_DUMPVERBOSE,print,"\n");
        // cheap matching
        tearingBFS(vareqns,m,mt,mapEqnIncRow,mapIncRowEqn,size,ass1,ass2,columark,mark,{});
        // check for unassigned vars, if there some rerun
        unassigned = Matching.getUnassigned(size,ass1,{});
        (outTVars,oMark) = omcTearing3(unassigned,rest,m,mt,mapEqnIncRow,mapIncRowEqn,size,vars,ishared,ass1,ass2,columark,mark+1,tvar::inTVars);
      then
        (outTVars,oMark);
    else
      equation
        print("BackendDAEOptimize.omcTearing2 failed!");
      then
        fail();
  end matchcontinue;
end omcTearing2;


protected function omcTearingSelectTearingVar "  author: Frenkel TUD 2012-05"
  input BackendDAE.Variables vars;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  output Integer tearingVar;
algorithm
  tearingVar := matchcontinue(vars,ass1,ass2,m,mt)
    local
      list<Integer> freeVars,eqns,unsolvables;
      Integer tvar;
      Integer size,varsize;
      array<Integer> points;
    // if vars there with no liniear occurence in any equation use all of them
/*    case(_,_,_,_)
      equation
      then

    // if states there use them as tearing variables
    case(_,_,_,_)
      equation
        (_,states) = BackendVariable.getAllStateVarIndexFromVariables(vars);
        states = List.removeOnTrue(ass1, isAssigned, states);
        true = List.isNotEmpty(states);
        tvar = selectVarWithMostEqns(states,ass2,mt,-1,-1);
      then
        tvar;
*/

    // if there is a variable unsolvable select it 
    case(_,_,_,_,_)
      equation
        unsolvables = getUnsolvableVarsConsiderMatching(1,BackendVariable.varsSize(vars),mt,ass1,ass2,{});
    false = List.isEmpty(unsolvables);
    tvar = listGet(unsolvables,1);
           Debug.fcall(Flags.TEARING_DUMP,print,"tVar: " +& intString(tvar) +& " (unsolvable in omcTearingSelectTearingVar)\n\n");
      then
        tvar;

    case(_,_,_,_,_)
      equation
        varsize = BackendVariable.varsSize(vars);
        // variables not assigned yet:
        freeVars = Matching.getUnassigned(varsize,ass1,{});
           Debug.fcall(Flags.TEARING_DUMPVERBOSE,  print,"omcTearingSelectTearingVar Candidates(unassigned vars):\n");
           Debug.fcall(Flags.TEARING_DUMPVERBOSE,  BackendDump.debuglst,(freeVars,intString,", ","\n"));
        size = listLength(freeVars);
        true = intGt(size,0);
        
        // CALCULATE TEARING-VARIABLE WEIGHTS
        points = arrayCreate(varsize,0);
        // 1st: Points for solvability (see function solvabilityWeights)
        points = List.fold2(freeVars, calcVarWeights,mt,ass2,points);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE,print,"\nPoints after 'calcVarWeights':\n" +& stringDelimitList(List.map(arrayList(points),intString),",") +& "\n\n");
        eqns = Matching.getUnassigned(arrayLength(m),ass2,{});
        // 2nd: 5 points for each equation this variable would causalize
        points = List.fold2(eqns,addEqnWeights,m,ass1,points);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE,print,"Points after 'addEqnWeights':\n" +& stringDelimitList(List.map(arrayList(points),intString),",") +& "\n\n");
        // 3rd: only one-tenth of points for each discrete variable
        points = List.fold1(freeVars,discriminateDiscrete,vars,points);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE,print,"Points after 'discriminateDiscrete':\n" +& stringDelimitList(List.map(arrayList(points),intString),",") +& "\n\n");
        tvar = selectVarWithMostPoints(freeVars,points,-1,-1);
          // Debug.fcall(Flags.TEARING_DUMPVERBOSE,print,"VarsWithMostEqns:\n");
          // Debug.fcall(Flags.TEARING_DUMPVERBOSE,BackendDump.debuglst,(freeVars,intString,", ","\n"));
           Debug.fcall(Flags.TEARING_DUMP,print,"tVar: " +& intString(tvar) +& " (" +& intString(points[tvar]) +& " points)\n\n");
      then
        tvar;
      else
    equation
        print("omcTearingSelectTearingVar failed because no unmatched var!\n");
      then
        fail();
  end matchcontinue;
end omcTearingSelectTearingVar;


protected function getUnsolvableVarsConsiderMatching 
" returns one unsolvable var with respect to the current matching 
  author: Frenkel TUD 2012-08"
  input Integer index;
  input Integer size;
  input BackendDAE.AdjacencyMatrixTEnhanced meT;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> inUnsolvables;
  output list<Integer> outUnsolvable;
algorithm
  outUnsolvable := matchcontinue(index,size,meT,ass1,ass2,inUnsolvables)
    local
      BackendDAE.AdjacencyMatrixElementEnhanced elem;
  case(_,_,_,_,_,_)
      equation
        true = intEq(index,size);
        /* unmatched var */
        true = intLt(ass1[index],0);
        elem = meT[index];
        /* consider only unmatched eqns */
        elem = removeMatched(elem,ass2,{});
        true = unsolvable(elem);
      then
       index::inUnsolvables;
    case(_,_,_,_,_,_)
      equation
        true = intLt(index,size);
        /* unmatched var */
        true = intLt(ass1[index],0);
        elem = meT[index];
        /* consider only unmatched eqns */
        elem = removeMatched(elem,ass2,{});
        true = unsolvable(elem);
      then
       getUnsolvableVarsConsiderMatching(index+1,size,meT,ass1,ass2,index::inUnsolvables);
    case(_,_,_,_,_,_)
      equation
        true = intLe(index,size);
      then
       getUnsolvableVarsConsiderMatching(index+1,size,meT,ass1,ass2,inUnsolvables);
  else
    then {};
  end matchcontinue;
end getUnsolvableVarsConsiderMatching;


protected function removeMatched 
" helper function for getUnsolvableVarsConsiderMatching, 
  returns only unmatched equations 
  author: Frenkel TUD 2012-08"
  input BackendDAE.AdjacencyMatrixElementEnhanced elem;
  input array<Integer> ass2;
  input BackendDAE.AdjacencyMatrixElementEnhanced iAcc;
  output BackendDAE.AdjacencyMatrixElementEnhanced oAcc;
algorithm
  oAcc := matchcontinue(elem,ass2,iAcc)
    local
      Integer e;
      BackendDAE.AdjacencyMatrixElementEnhanced rest;
      BackendDAE.Solvability s;
    case ({},_,_) then iAcc;
    case ((e,s)::rest,_,_)
      equation
        true = intLt(ass2[e],0);
      then
        removeMatched(rest,ass2,(e,s)::iAcc);
    case ((e,s)::rest,_,_)
      then
        removeMatched(rest,ass2,iAcc);
  end matchcontinue;
end removeMatched;


protected function calcVarWeights "function giving points for solvability" 
 input Integer v;
 input BackendDAE.AdjacencyMatrixTEnhanced mt;
 input array<Integer> ass2;
 input array<Integer> iPoints;
 output array<Integer> oPoints;
protected
 Integer p;
algorithm
  p := calcSolvabilityWeight(mt[v],ass2);
  oPoints := arrayUpdate(iPoints,v,p);
end calcVarWeights;


protected function calcSolvabilityWeight 
"helper function for calcVarWeights, giving points for solvability"
  input BackendDAE.AdjacencyMatrixElementEnhanced inRow;
  input array<Integer> ass2;
  output Integer w;
algorithm
  w := List.fold1(inRow,solvabilityWeightsnoStates,ass2,0);
end calcSolvabilityWeight;


protected function solvabilityWeightsnoStates 
"helper function for calcSolvabilityWeight, giving points for solvability
  author: Frenkel TUD 2012-05"
  input tuple<Integer,BackendDAE.Solvability> inTpl;
  input array<Integer> ass;
  input Integer iW;
  output Integer oW;
algorithm
  oW := matchcontinue(inTpl,ass,iW)
    local
      BackendDAE.Solvability s;
      Integer eq,w;
    case((eq,s),_,_)
      equation
        true = intGt(eq,0);
        false = intGt(ass[eq], 0);
        w = solvabilityWeights(s);
      then
        intAdd(w,iW);
    else then iW;
  end matchcontinue;
end solvabilityWeightsnoStates;


protected function solvabilityWeights 
" helper function for solvabilityWeightsnoStates 
  author: Frenkel TUD 2012-05,
  return a integer for the solvability, this function is used
  to calculade weights for variables to select the tearing variable."
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
end solvabilityWeights;


protected function addEqnWeights 
"function adds five points to variables for each equation it would causalize as tvar"
 input Integer e;
 input BackendDAE.AdjacencyMatrixEnhanced m;
 input array<Integer> ass1;
 input array<Integer> iPoints;
 output array<Integer> oPoints;
algorithm
 oPoints := matchcontinue(e,m,ass1,iPoints)
   local
       Integer v1,v2;
       array<Integer> points;
     case (_,_,_,_)
       equation
         // finds equations with exact two variables (v1,v2)
         ((v1,_)::(v2,_)::{}) = List.removeOnTrue(ass1, isAssignedSaveEnhanced, m[e]);
         points = arrayUpdate(iPoints,v1,iPoints[v1]+5);
         points = arrayUpdate(iPoints,v2,points[v2]+5);
       then
         points;
     else
       iPoints;
 end matchcontinue;
end addEqnWeights;


protected function isAssignedSaveEnhanced " returns true if var/eqn is already assigned
  author: Frenkel TUD 2012-05"
  input array<Integer> ass;
  input tuple<Integer,BackendDAE.Solvability> inTpl;
  output Boolean outB;
algorithm
  outB := matchcontinue(ass,inTpl)
    local
      Integer i;
    case (_,(i,_))
      equation
        true = intGt(i,0);
      then
        intGt(ass[i],0);
    else
      true;
  end matchcontinue;
end isAssignedSaveEnhanced;


protected function discriminateDiscrete " leaves only one-tenth of points for each discrete variable 
 author: Frenkel TUD 2012-08"
 input Integer v;
 input BackendDAE.Variables vars;
 input array<Integer> iPoints;
 output array<Integer> oPoints;
protected
 Integer p;
 Boolean b;
 BackendDAE.Var var;
algorithm
  var := BackendVariable.getVarAt(vars, v);
  b := BackendVariable.isVarDiscrete(var);
  p := iPoints[v];
  p := Util.if_(b,intDiv(p,10),p);
  oPoints := arrayUpdate(iPoints,v,p);
end discriminateDiscrete;


protected function selectVarWithMostPoints " returns one var with most points
  author: Frenkel TUD 2012-05"
  input list<Integer> vars;
  input array<Integer> points;
  input Integer iVar;
  input Integer defp;
  output Integer oVar;
algorithm
  oVar := matchcontinue(vars,points,iVar,defp)
    local
      list<Integer> rest;
      Integer p,v;
    case ({},_,_,_) then iVar;
    case (v::rest,_,_,_)
      equation
          // Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Var " +& intString(v));
        p = points[v];
          // Debug.fcall(Flags.TEARING_DUMPVERBOSE, print," has " +& intString(p) +& " Points\n");
        true = intGt(p,defp);
          // Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"max is  " +& intString(p) +& "\n");
      then
        selectVarWithMostPoints(rest,points,v,p);
    case (_::rest,_,_,_)
      then
        selectVarWithMostPoints(rest,points,iVar,defp);
  end matchcontinue;
end selectVarWithMostPoints;


protected function tearingBFS " function to find maximum matching
  author: Frenkel TUD 2012-05"
  input BackendDAE.AdjacencyMatrixElementEnhanced queue;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input Integer size;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> columark;
  input Integer mark;
  input BackendDAE.AdjacencyMatrixElementEnhanced nextQueue;
algorithm
  _ := match(queue,m,mt,mapEqnIncRow,mapIncRowEqn,size,ass1,ass2,columark,mark,nextQueue)
    local
      Integer c,eqnsize,cnonscalar;
      BackendDAE.AdjacencyMatrixElementEnhanced rest,newqueue,rows;
    // if there are no more equations in queue maximum matching is found
    case ({},_,_,_,_,_,_,_,_,_,{}) then ();
      
    // if queue is empty, use next queue
    case ({},_,_,_,_,_,_,_,_,_,_)
      equation
        // use only equations from next queue which are not assigned yet
        newqueue = List.removeOnTrue(ass2, isAssignedSaveEnhanced, nextQueue);
        // use linear equations first
        newqueue = sortEqnsSolvable(newqueue,m);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Use next Queue!\n");
        tearingBFS(newqueue,m,mt,mapEqnIncRow,mapIncRowEqn,size,ass1,ass2,columark,mark,{});
      then
        ();
    case((c,_)::rest,_,_,_,_,_,_,_,_,_,_)
      equation
           Debug.fcall(Flags.TEARING_DUMPVERBOSE,print,"Queue:\n");
           Debug.fcall(Flags.TEARING_DUMPVERBOSE,BackendDump.dumpAdjacencyRowEnhanced,queue);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Process Eqn: " +& intString(c) +& "\n");
        // not assigned variables in equation c:
        rows = List.removeOnTrue(ass1, isAssignedSaveEnhanced, m[c]);
          //_ = arrayUpdate(columark,c,mark);
        // For Equationarrays
        cnonscalar = mapIncRowEqn[c];
        eqnsize = listLength(mapEqnIncRow[cnonscalar]);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Eqn Size: " +& intString(eqnsize) +& "\n");
          // Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Rows(not assigned variables in eqn " +& intString(c) +& ":\n" +& stringDelimitList(List.map(List.map(rows,Util.tuple21),intString),", ") +& "\n");
           Debug.fcall(Flags.TEARING_DUMPVERBOSE,print,"Rows (not assigned variables in eqn " +& intString(c) +& "):\n");
           Debug.fcall(Flags.TEARING_DUMPVERBOSE,BackendDump.dumpAdjacencyRowEnhanced,rows);Debug.fcall(Flags.TEARING_DUMPVERBOSE,print,"\n");
        // make assignment and find next equations to get causalized
        newqueue = tearingBFS1(rows,eqnsize,mapEqnIncRow[cnonscalar],mt,ass1,ass2,columark,mark,nextQueue);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE,print,"Next Queue:\n");
           Debug.fcall(Flags.TEARING_DUMPVERBOSE,BackendDump.dumpAdjacencyRowEnhanced,newqueue);Debug.fcall(Flags.TEARING_DUMPVERBOSE,print,"\n\n");
        tearingBFS(rest,m,mt,mapEqnIncRow,mapIncRowEqn,size,ass1,ass2,columark,mark,newqueue);
      then
        ();
  end match;
end tearingBFS;


protected function sortEqnsSolvable
"  author: Frenkel TUD 2012-10
  moves equations with nonlinear or unsolvable parts to the end"
  input BackendDAE.AdjacencyMatrixElementEnhanced queue;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  output BackendDAE.AdjacencyMatrixElementEnhanced nextQueue;
protected
  BackendDAE.AdjacencyMatrixElementEnhanced qnon,qsolv;
algorithm
  (qnon,qsolv) := List.split1OnTrue(queue,hasnonlinearVars,m);
  nextQueue := listAppend(qsolv,qnon);
end sortEqnsSolvable;


protected function hasnonlinearVars
  input BackendDAE.AdjacencyMatrixElementEnhancedEntry entry;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  output Boolean hasnonlinear;
protected
  Integer r;
  BackendDAE.AdjacencyMatrixElementEnhanced row;
algorithm
  (r,_) := entry;
  row := m[r];
  hasnonlinear := hasnonlinearVars1(row);
end hasnonlinearVars;


protected function hasnonlinearVars1
  input BackendDAE.AdjacencyMatrixElementEnhanced row;
  output Boolean hasnonlinear;
algorithm
  hasnonlinear := match(row)
    local
      BackendDAE.AdjacencyMatrixElementEnhanced rest;
    case ( {}) then false;
    case ((_,BackendDAE.SOLVABILITY_NONLINEAR())::_)
      then
        true;
    case (_::rest)
      then
        hasnonlinearVars1(rest);
  end match;
end hasnonlinearVars1;


protected function tearingBFS1 " function checks for possible assignments and calls tearingBFS2
  author: Frenkel TUD 2012-05"
  input BackendDAE.AdjacencyMatrixElementEnhanced rows;
  input Integer size;
  input list<Integer> c;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> columark;
  input Integer mark;
  input BackendDAE.AdjacencyMatrixElementEnhanced inNextQueue;
  output BackendDAE.AdjacencyMatrixElementEnhanced outNextQueue;
algorithm
  outNextQueue := matchcontinue(rows,size,c,mt,ass1,ass2,columark,mark,inNextQueue)
    local
    // there is only one variable assignable from this equation and the equation is solvable for this variable
    case (_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(listLength(rows),size);
        true = solvableLst(rows);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Assign Eqns: " +& stringDelimitList(List.map(c,intString),", ") +& "\n");
      then
        // make assignment and get next equations
        tearingBFS2(rows,c,mt,ass1,ass2,columark,mark,inNextQueue);
/*    case (_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(listLength(rows),size);
        false = solvableLst(rows);
          //Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"cannot Assign Var" +& intString(r) +& " with Eqn " +& intString(c) +& "\n");
      then
        inNextQueue;
*/
    else then inNextQueue;
  end matchcontinue;
end tearingBFS1;


protected function solvableLst
" returns true if all variables are solvable"
  input BackendDAE.AdjacencyMatrixElementEnhanced rows;
  output Boolean solvable;
algorithm
  solvable := matchcontinue(rows)
    local
      Integer r;
      BackendDAE.Solvability s;
      BackendDAE.AdjacencyMatrixElementEnhanced rest;
    case ((r,s)::{}) then solvable(s);
    case ((r,s)::rest)
      equation
        true = solvable(s);
      then
        solvableLst(rest);
  case ((r,s)::rest)
      equation
        false = solvable(s);
      then
        false;
  end matchcontinue;
end solvableLst;


protected function solvable
  input BackendDAE.Solvability s;
  output Boolean b;
algorithm
  b := match(s)
    case BackendDAE.SOLVABILITY_SOLVED() then true;
    case BackendDAE.SOLVABILITY_CONSTONE() then true;
    case BackendDAE.SOLVABILITY_CONST() then true;
    case BackendDAE.SOLVABILITY_PARAMETER(b=b) then b;
    case BackendDAE.SOLVABILITY_TIMEVARYING(b=b) then false;
    case BackendDAE.SOLVABILITY_NONLINEAR() then false;
    case BackendDAE.SOLVABILITY_UNSOLVABLE() then false;
  end match;
end solvable;


protected function tearingBFS2 " function to make an assignment and determine the next equations for queue
  author: Frenkel TUD 2012-05"
  input BackendDAE.AdjacencyMatrixElementEnhanced rows;
  input list<Integer> clst;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> columark;
  input Integer mark;
  input BackendDAE.AdjacencyMatrixElementEnhanced inNextQueue;
  output BackendDAE.AdjacencyMatrixElementEnhanced outNextQueue;
algorithm
  outNextQueue := match(rows,clst,mt,ass1,ass2,columark,mark,inNextQueue)
    local
      Integer r,c;
      list<Integer> ilst;
      BackendDAE.Solvability s;
      BackendDAE.AdjacencyMatrixElementEnhanced rest,vareqns,newqueue;
    case ({},_,_,_,_,_,_,_) then inNextQueue;
    case ((r,s)::rest,c::ilst,_,_,_,_,_,_)
      equation
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Assignment: Eq " +& intString(c) +& " - Var " +& intString(r) +& "\n");
        // assign
        _ = arrayUpdate(ass1,r,c);
        _ = arrayUpdate(ass2,c,r);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"ass1: " +& stringDelimitList(List.map(arrayList(ass1),intString),",")+&"\n");
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"ass2: " +& stringDelimitList(List.map(arrayList(ass2),intString),",")+&"\n");
        // not yet assigned equations containing var r
        vareqns = List.removeOnTrue(ass2, isAssignedSaveEnhanced, mt[r]);
        newqueue = listAppend(inNextQueue,vareqns);
      then
        tearingBFS2(rest,ilst,mt,ass1,ass2,columark,mark,newqueue);
  end match;
end tearingBFS2;


protected function omcTearing3 " function to rerun omcTearing2 if there are still unassigned vars
  author: Frenkel TUD 2012-05"
  input list<Integer> unassigend;
  input list<Integer> unsolvables;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input Integer size;
  input BackendDAE.Variables vars;
  input BackendDAE.Shared ishared;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> columark;
  input Integer mark;
  input list<Integer> inTVars;
  output list<Integer> outTVars;
  output Integer oMark;
algorithm
  (outTVars,oMark) := match(unassigend,unsolvables,m,mt,mapEqnIncRow,mapIncRowEqn,size,vars,ishared,ass1,ass2,columark,mark,inTVars)
    local
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_) then (inTVars,mark);
    else
      equation
        (outTVars,oMark) = omcTearing2(unsolvables,m,mt,mapEqnIncRow,mapIncRowEqn,size,vars,ishared,ass1,ass2,columark,mark,inTVars);
      then
        (outTVars,oMark);
  end match;
end omcTearing3;


protected function omcTearing4 
" maps indexes back to entire system and creates strong component from tearing information 
  author: Frenkel TUD 2012-09"
  input BackendDAE.JacobianType jacType;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.EqSystem subsyst;
  input list<Integer> tvars;
  input list<Integer> residual;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<list<Integer>> othercomps;
  input list<Integer> eindex;
  input list<Integer> vindx;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input array<Integer> columark;
  input Integer mark;
  output BackendDAE.StrongComponent ocomp;
  output Boolean outRunMatching;
algorithm
  (ocomp,outRunMatching):=
    matchcontinue (jacType,isyst,ishared,subsyst,tvars,residual,ass1,ass2,othercomps,eindex,vindx,mapEqnIncRow,mapIncRowEqn,columark,mark)
    local
      list<Integer> ores,residual1,ovars;
      list<tuple<Integer,list<Integer>>> eqnvartpllst;
      array<Integer> eindxarr,varindxarr;
      Boolean linear;
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"handle torn System\n");
        residual1 = List.map1r(residual,arrayGet,mapIncRowEqn);
        residual1 = List.fold2(residual1,uniqueIntLst,mark,columark,{});
        // map indexes back
        eindxarr = listArray(eindex);
        ores = List.map1r(residual1,arrayGet,eindxarr);
        varindxarr = listArray(vindx);
        ovars = List.map1r(tvars,arrayGet,varindxarr);
        eqnvartpllst = omcTearing4_1(othercomps,ass2,mapIncRowEqn,eindxarr,varindxarr,columark,mark,{});
        linear = getLinearfromJacType(jacType);
      then
        (BackendDAE.TORNSYSTEM(ovars, ores, eqnvartpllst, linear,BackendDAE.EMPTY_JACOBIAN()),true);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        (BackendDAE.TORNSYSTEM({}, {}, {}, false, BackendDAE.EMPTY_JACOBIAN()),false);
  end matchcontinue;
end omcTearing4;


protected function omcTearing4_1 
" creates otherEqnVarTpl for TORNSYSTEM
  author: Frenkel TUD 2012-09"
  input list<list<Integer>> othercomps;
  input array<Integer> ass2;
  input array<Integer> mapIncRowEqn;
  input array<Integer> eindxarr;
  input array<Integer> varindxarr;
  input array<Integer> columark;
  input Integer mark;
  input list<tuple<Integer,list<Integer>>> iAcc;
  output list<tuple<Integer,list<Integer>>> oEqnVarTplLst;
algorithm
  oEqnVarTplLst :=
  match (othercomps,ass2,mapIncRowEqn,eindxarr,varindxarr,columark,mark,iAcc)
    local
      list<list<Integer>> rest;
      Integer e,v,c;
      list<Integer> vlst,clst,elst;
    case ({},_,_,_,_,_,_,_) then listReverse(iAcc);
    case ({c}::rest,_,_,_,_,_,_,_)
      equation
        e = mapIncRowEqn[c];
        e = eindxarr[e];
        v = ass2[c];
        v = varindxarr[v];
      then
        omcTearing4_1(rest,ass2,mapIncRowEqn,eindxarr,varindxarr,columark,mark,(e,{v})::iAcc);
    case (clst::rest,_,_,_,_,_,_,_)
      equation
        elst = List.map1r(clst,arrayGet,mapIncRowEqn);
        elst = List.fold2(elst,uniqueIntLst,mark,columark,{});
        {e} = elst;
        e = eindxarr[e];
        vlst = List.map1r(clst,arrayGet,ass2);
        vlst = List.map1r(vlst,arrayGet,varindxarr);
      then
        omcTearing4_1(rest,ass2,mapIncRowEqn,eindxarr,varindxarr,columark,mark,(e,vlst)::iAcc);
  end match;
end omcTearing4_1;


protected function getLinearfromJacType "  author: Frenkel TUD 2012-09"
  input BackendDAE.JacobianType jacType;
  output Boolean linear;
algorithm
  linear := match(jacType)
    case (BackendDAE.JAC_CONSTANT()) then true;
    case (BackendDAE.JAC_TIME_VARYING()) then true;
    case (BackendDAE.JAC_NONLINEAR()) then false;
    case (BackendDAE.JAC_NO_ANALYTIC()) then false;
  end match;
end getLinearfromJacType;







// =============================================================================
//
// Tearing from Book of Cellier
//
// =============================================================================

protected function CellierTearing "  
author: Waurich TUD 2012-10, enhanced: ptaeuber FHB 2013/2014"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> eindex;
  input list<Integer> vindx;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> ojac;
  input BackendDAE.JacobianType jacType;
  output BackendDAE.StrongComponent ocomp;
  output Boolean outRunMatching;
protected
  list<Integer> tvars,residual,residual_coll,unsolvables,unassigned,potentials,discreteVars;
  list<list<Integer>> othercomps,order;
  BackendDAE.EqSystem syst,subsyst;
  BackendDAE.Shared shared;
  array<Integer> columark,number,lowlink;
  list<Integer> ass1,ass2;
  list<Integer> assignables,OutTVars;
  Integer size,tornsize,tvar,mark;
  list<BackendDAE.Equation> eqn_lst;
  list<BackendDAE.Var> var_lst;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.IncidenceMatrix m,m1;
  BackendDAE.IncidenceMatrix mt,mt1;
  BackendDAE.AdjacencyMatrixEnhanced me;
  BackendDAE.AdjacencyMatrixTEnhanced meT;
  BackendDAE.AdjacencyMatrixElementEnhanced vareqns;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  list<list<Integer>> orderIn;
  Boolean causal;
  list<tuple<Integer,BackendDAE.Solvability>> row;
  list<tuple<Integer,list<Integer>>> otherEqnVarTpl;
  Boolean linear,alternative;
algorithm
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n" +& BORDER +& "\nBEGINNING of CellierTearing\n\n");
  // generate Subsystem to get the incidence matrix
  size := listLength(vindx);
  eqn_lst := BackendEquation.getEqns(eindex,BackendEquation.daeEqns(isyst));
  eqns := BackendEquation.listEquation(eqn_lst);
  var_lst := List.map1r(vindx, BackendVariable.getVarAt, BackendVariable.daeVars(isyst));
  vars := BackendVariable.listVar1(var_lst);
  subsyst := BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING(),{});
  (subsyst,m,mt,_,_) := BackendDAEUtil.getIncidenceMatrixScalar(subsyst, BackendDAE.NORMAL(),NONE());
  // delete negative entries from incidence matrix
  m := Util.arrayMap1(m,deleteNegativeEntries,1);
  mt := Util.arrayMap1(mt,deleteNegativeEntries,1);
     Debug.fcall(Flags.TEARING_DUMP, print, "\n\n###BEGIN print Strong Component#####################\n(Function:tearingsSystem1_1)\n");
     Debug.fcall(Flags.TEARING_DUMP, BackendDump.printEqSystem, subsyst);
     Debug.fcall(Flags.TEARING_DUMP, print, "\n###END print Strong Component#######################\n(Function:tearingsSystem1_1)\n\n\n");
  //get advanced incidence matrix
  (me,meT,mapEqnIncRow,mapIncRowEqn) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(subsyst,ishared);
     Debug.fcall(Flags.TEARING_DUMP, print, "\n\nAdjacencyMatrixEnhanced:\n");
     Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpAdjacencyMatrixEnhanced,me);
     Debug.fcall(Flags.TEARING_DUMP, print,"\nAdjacencyMatrixTransposedEnhanced:\n");
     Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpAdjacencyMatrixTEnhanced,meT);
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n\nmapEqnIncRow:"); //+& stringDelimitList(List.map(List.flatten(arrayList(mapEqnIncRow)),intString),",") +& "\n\n");
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, BackendDump.dumpIncidenceMatrix, mapEqnIncRow);
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nmapIncRowEqn:\n" +& stringDelimitList(List.map(arrayList(mapIncRowEqn),intString),",") +& "\n\n");
  //determine unsolvable vars to consider solvability
  unsolvables := getUnsolvableVars(1,size,meT,{});
     Debug.fcall(Flags.TEARING_DUMP, print, "\nUNSOLVABLES:\n" +& stringDelimitList(List.map(unsolvables,intString),",") +& "\n\n");
  //determine discrete vars
  discreteVars := findDiscrete(var_lst,{},1);  
     Debug.fcall(Flags.TEARING_DUMP, print, "\nDiscrete Vars:\n" +& stringDelimitList(List.map(discreteVars,intString),",") +& "\n\n");
  ass1 := List.fill(-1,size);
  ass2 := List.fill(-1,size);
  orderIn := {{},{}};
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n" +& BORDER +& "\nBEGINNING of TearingSystemCellier\n\n");
  (OutTVars, ass1, ass2, order) := TearingSystemCellier(false,m,mt,me,meT,ass1,ass2,unsolvables,{},discreteVars,orderIn,mapEqnIncRow,mapIncRowEqn);
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nEND of TearingSystemCellier\n" +& BORDER +& "\n\n");
  // check if tearing makes sense
  tornsize := listLength(OutTVars);
  true := intLt(tornsize,size-1);
  // unassigned equations are residual equations
  ((_,residual)) := List.fold(ass2,getUnassigned,(1,{}));
  residual_coll := List.map1r(residual,arrayGet,mapIncRowEqn);
  residual_coll := List.unique(residual_coll);
     Debug.fcall(Flags.TEARING_DUMP, print, "\n" +& BORDER +& "\n* TEARING RESULTS:\n*\n* No of equations in strong Component: "+&intString(size)+&"\n");
     Debug.fcall(Flags.TEARING_DUMP, print, "* No of tVars: "+&intString(listLength(OutTVars))+&"\n");
     Debug.fcall(Flags.TEARING_DUMP, print, "*\n* tVars: "+& stringDelimitList(List.map(OutTVars,intString),",") +& "\n");
     Debug.fcall(Flags.TEARING_DUMP, print, "*\n* resEq: "+& stringDelimitList(List.map(residual_coll,intString),",") +& "\n*\n*");
  // Convert indexes
  OutTVars := listReverse(selectFromList(vindx, OutTVars));
  residual := listReverse(selectFromList(eindex, residual_coll));
     Debug.fcall(Flags.TEARING_DUMP, print, "\n* Related to entire Equationsystem:\n* =====\n* tVars: "+& stringDelimitList(List.map(OutTVars,intString),",") +& "\n* =====\n");
     Debug.fcall(Flags.TEARING_DUMP, print, "*\n* =====\n* resEq: "+& stringDelimitList(List.map(residual,intString),",") +& "\n* =====\n" +& BORDER +& "\n");
  // assign otherEqnVarTpl:
  otherEqnVarTpl := assignOtherEqnVarTpl(List.flatten(order),eindex,vindx,ass2,mapEqnIncRow,{});
  linear := getLinearfromJacType(jacType);
  ocomp := BackendDAE.TORNSYSTEM(OutTVars,residual,otherEqnVarTpl,linear,BackendDAE.EMPTY_JACOBIAN());
  outRunMatching := true;
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nEND of CellierTearing\n" +& BORDER +& "\n\n");
end CellierTearing;


protected function deleteNegativeEntries 
 "deletes all negative entries from incidence matrix, works with Util.arrayMap1, needed for proper Cellier-Tearing
  author:ptaeuber FHB 2014-01"
  input list<Integer> rowIn;
  input Integer index;
  output list<Integer> rowOut;
algorithm
 rowOut := matchcontinue(rowIn,index)
  local
    Integer indx;
    list<Integer> newLst;
  Boolean b;   
  case(_,indx)
   equation
     true = intLe(indx, listLength(rowIn));
   b = intLe(listGet(rowIn,indx),0);
     indx = Util.if_(b,indx-1,indx);
   newLst = Debug.bcallret2(b,listDelete,rowIn,indx,rowIn);
  then
    deleteNegativeEntries(newLst,indx+1);
  case(_,_)
   equation
     true = intGt(index,listLength(rowIn));
  then
    rowIn; 
 end matchcontinue;
end deleteNegativeEntries;


protected function findDiscrete "takes a list of BackendDAE.Var and returns the indexes of the discrete Variables
  author:ptaeuber FHB 2014-01"
  input list<BackendDAE.Var> inVars;
  input list<Integer> discreteVarsIn;
  input Integer index;
  output list<Integer> discreteVarsOut;
algorithm
  discreteVarsOut := matchcontinue(inVars,discreteVarsIn,index)
  local
  BackendDAE.Var head;
  list<BackendDAE.Var> rest;
  case({},_,_)
   then discreteVarsIn;
  case(head::rest,_,_)
    equation
    true = BackendVariable.isVarDiscrete(head);
     then findDiscrete(rest,index::discreteVarsIn,index+1);
  case(head::rest,_,_)
     then findDiscrete(rest,discreteVarsIn,index+1);
  else
    equation
      print("findDiscrete in Tearing.mo failed");
   then {};
  end matchcontinue;
end findDiscrete;


protected function TearingSystemCellier " selects Tearing Set and assigns Vars
  author:Waurich TUD 2012-11, enhanced: ptaeuber FHB 2013-2014"
  input Boolean inCausal;
  input BackendDAE.IncidenceMatrix mIn;
  input BackendDAE.IncidenceMatrixT mtIn;
  input BackendDAE.AdjacencyMatrixEnhanced meIn;
  input BackendDAE.AdjacencyMatrixTEnhanced meTIn;
  input list<Integer> ass1In,ass2In,Unsolvables,tvarsIn,discreteVars;
  input list<list<Integer>> orderIn;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  output list<Integer> OutTVars, ass1Out, ass2Out;
  output list<list<Integer>> orderOut;
algorithm
  (OutTVars,ass1Out, ass2Out, orderOut) := matchcontinue(inCausal,mIn,mtIn,meIn,meTIn,ass1In,ass2In,Unsolvables,tvarsIn,discreteVars,orderIn,mapEqnIncRow,mapIncRowEqn)
  local
    Integer tvar,unsolvable;
    list<Integer> ass1,ass2,tvars,unassigned,unsolvables;
    list<list<Integer>>order;
    BackendDAE.IncidenceMatrix m;
    BackendDAE.IncidenceMatrixT mt;
    Boolean causal;
  case(true,_,_,_,_,_,_,_,_,_,_,_,_)
    equation
     then 
       (tvarsIn,ass1In,ass2In,orderIn);
  case(false,_,_,_,_,_,_,{},_,_,_,_,_)
    equation
      // select tearing Var
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n" +& BORDER +& "\nBEGINNING of selectTearingVar\n\n");
      tvar = selectTearingVar(meIn,meTIn,mIn,mtIn,ass1In,ass2In,discreteVars,mapEqnIncRow,mapIncRowEqn);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nEND of selectTearingVar\n" +& BORDER +& "\n\n");
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n###Function: TearingSystemCellier###################\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"tearingVar: "+&intString(tvar)+&"\n");
    // mark tvar in ass1
    ass1 = List.set(ass1In,tvar,listLength(ass1In)*2);
      // remove tearing var from incidence matrix and transposed inc matrix
      m = updateIncidence(mIn,tvar,1);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n\n###BEGIN print Incidence Matrix w/o tvar############\n(Function: TearingSystemCellier)\n");
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, BackendDump.dumpIncidenceMatrix, m);
      mt = Util.arrayReplaceAtWithFill(tvar,{},{},mtIn);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, BackendDump.dumpIncidenceMatrixT, mt);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n###END print Incidence Matrix w/o tvar##############\n(Function: TearingSystemCellier)\n\n\n");
      tvars = tvar::tvarsIn;
    // assign vars to eqs until complete or partially causalisation(and restart algorithm)
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n" +& BORDER +& "\nBEGINNING of Tarjan\n\n");
      (ass1,ass2,m,mt,order,causal) = Tarjan(m,mt,meIn,meTIn,ass1,ass2In,orderIn,mapEqnIncRow,mapIncRowEqn,true);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nEND of Tarjan\n" +& BORDER +& "\n\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"\nTARJAN RESULTS:\nass1: "+&stringDelimitList(List.map(ass1,intString),",")+&"\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"ass2: "+&stringDelimitList(List.map(ass2,intString),",")+&"\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"order: "+&stringDelimitList(List.map(listReverse(List.flatten(order)),intString),",")+&"\n");
    // find out if there are new unsolvables now
    unsolvables = getUnsolvableVarsConsiderMatching(1,arrayLength(meTIn),meTIn,listArray(ass1),listArray(ass2),{});
    (_,unsolvables,_) = List.intersection1OnTrue(unsolvables,tvars,intEq);
        // ((_,unassigned)) = List.fold(ass2,getUnassigned,(1,{}));
        // ((_,unassigned)) = List.fold(ass1,getUnassigned,(1,{}));
      (tvars, ass1, ass2, order) = TearingSystemCellier(causal,m,mt,meIn,meTIn,ass1,ass2,unsolvables,tvars,discreteVars,order,mapEqnIncRow,mapIncRowEqn);
     then 
       (tvars,ass1,ass2,order);
  case(false,_,_,_,_,_,_,unsolvables,_,_,_,_,_) 
    equation
        // First choose unsolvables as tVars
      tvars = unsolvables;
         Debug.fcall(Flags.TEARING_DUMP, print,"\nUnsolvables as tVars: "+& stringDelimitList(List.map(tvars,intString),",")+&"\n");
      // mark tvars in ass1
    ass1 = markTVars(tvars,ass1In);
    // remove tearing var from incidence matrix and transposed inc matrix
    m = updateIncidence2(mIn,tvars,1);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n\n###BEGIN print Incidence Matrix w/o tvar############\n(Function: TearingSystemCellier)\n");
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, BackendDump.dumpIncidenceMatrix, m);
      mt = updateIncidenceT2(mtIn,tvars,1);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, BackendDump.dumpIncidenceMatrixT, mt);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n###END print Incidence Matrix w/o tvar##############\n(Function: TearingSystemCellier)\n\n\n");
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n" +& BORDER +& "\nBEGINNING of Tarjan\n\n");
      tvars = listAppend(tvars,tvarsIn);
    (ass1,ass2,m,mt,order,causal) = Tarjan(m,mt,meIn,meTIn,ass1,ass2In,orderIn,mapEqnIncRow,mapIncRowEqn,true);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nEND of Tarjan\n" +& BORDER +& "\n\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"\nTARJAN RESULTS:\nass1: "+&stringDelimitList(List.map(ass1,intString),",")+&"\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"ass2: "+&stringDelimitList(List.map(ass2,intString),",")+&"\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"order: "+&stringDelimitList(List.map(List.flatten(order),intString),",")+&"\n");
      // find out if there are new unsolvables now
      unsolvables = getUnsolvableVarsConsiderMatching(1,arrayLength(meTIn),meTIn,listArray(ass1),listArray(ass2),{});
      (_,unsolvables,_) = List.intersection1OnTrue(unsolvables,tvars,intEq);
    (tvars, ass1, ass2, order) = TearingSystemCellier(causal,m,mt,meIn,meTIn,ass1,ass2,unsolvables,tvars,discreteVars,order,mapEqnIncRow,mapIncRowEqn);    
     then
       (tvars, ass1, ass2, order);
  end matchcontinue;
end TearingSystemCellier;


protected function selectTearingVar
  "Selects set of TearingVars referred to one of the following heuristics.
author: ptaeuber FHB 2014-04"
input BackendDAE.AdjacencyMatrixEnhanced me;
input BackendDAE.AdjacencyMatrixTEnhanced meT;
input BackendDAE.IncidenceMatrix m;
input BackendDAE.IncidenceMatrixT mt;
input list<Integer> ass1In,ass2In,discreteVars;
input array<list<Integer>> mapEqnIncRow;
input array<Integer> mapIncRowEqn;
output Integer OutTVars;
algorithm
  OutTVars :=
  matchcontinue(me,meT,m,mt,ass1In,ass2In,discreteVars,mapEqnIncRow,mapIncRowEqn)
    local
      list<Integer> potentials;
      String heuristic;
    case(_,_,_,_,_,_,_,_,_)
      equation
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n" +& BORDER +& "\nBEGINNING of potentialsCellier\n\n");  
        heuristic = Config.getTearingHeuristic();
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Chosen Heuristic: " +& heuristic +& "\n\n\n");
        potentials = Debug.bcallret6(stringEqual(heuristic,"MC1"),potentialsCellier,m,mt,me,meT,(ass1In,ass2In,discreteVars),(mapEqnIncRow,mapIncRowEqn),{});
        potentials = Debug.bcallret6(stringEqual(heuristic,"MC2"),potentialsCellier2,m,mt,me,meT,(ass1In,ass2In,discreteVars),(mapEqnIncRow,mapIncRowEqn),potentials);
        potentials = Debug.bcallret6(stringEqual(heuristic,"MC11"),potentialsCellier3,m,mt,me,meT,(ass1In,ass2In,discreteVars),(mapEqnIncRow,mapIncRowEqn),potentials);
        potentials = Debug.bcallret6(stringEqual(heuristic,"MC21"),potentialsCellier4,m,mt,me,meT,(ass1In,ass2In,discreteVars),(mapEqnIncRow,mapIncRowEqn),potentials);
        potentials = Debug.bcallret6(stringEqual(heuristic,"MC12"),potentialsCellier5,m,mt,me,meT,(ass1In,ass2In,discreteVars),(mapEqnIncRow,mapIncRowEqn),potentials);
        potentials = Debug.bcallret6(stringEqual(heuristic,"MC22"),potentialsCellier6,m,mt,me,meT,(ass1In,ass2In,discreteVars),(mapEqnIncRow,mapIncRowEqn),potentials);
        potentials = Debug.bcallret6(stringEqual(heuristic,"MC13"),potentialsCellier7,m,mt,me,meT,(ass1In,ass2In,discreteVars),(mapEqnIncRow,mapIncRowEqn),potentials);
        potentials = Debug.bcallret6(stringEqual(heuristic,"MC23"),potentialsCellier8,m,mt,me,meT,(ass1In,ass2In,discreteVars),(mapEqnIncRow,mapIncRowEqn),potentials);
        potentials = Debug.bcallret6(stringEqual(heuristic,"MC231"),potentialsCellier9,m,mt,me,meT,(ass1In,ass2In,discreteVars),(mapEqnIncRow,mapIncRowEqn),potentials);
        potentials = Debug.bcallret6(stringEqual(heuristic,"MC3"),potentialsCellier10,m,mt,me,meT,(ass1In,ass2In,discreteVars),(mapEqnIncRow,mapIncRowEqn),potentials);
        potentials = Debug.bcallret6(stringEqual(heuristic,"MC4"),potentialsCellier11,m,mt,me,meT,(ass1In,ass2In,discreteVars),(mapEqnIncRow,mapIncRowEqn),potentials);
        true = intGe(listLength(potentials),1);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nEND of potentialsCellier\n" +& BORDER +& "\n\n");
      then 
        listGet(potentials,1);
    else
      equation
        print("selecting tearing variable failed");
    then fail();
  end matchcontinue;
end selectTearingVar;


protected function potentialsCellier" gets the potentials for the next tearing variable [MC1].
author: Waurich TUD 2012-11, enhanced: ptaeuber FHB 2013-10"
  input BackendDAE.IncidenceMatrix m,mt;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixTEnhanced met;
  input tuple<list<Integer>,list<Integer>,list<Integer>> assIn;
  input tuple<array<list<Integer>>,array<Integer>> mapInfo;
  output list<Integer> potentials;
protected
  Integer edges;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  list<list<Integer>> selectedcolsLst;
  list<Integer> ass1In,ass2In,selectedcols1,selectedcols2,selectedrows,assEq,assEq_multi,assEq_single,discreteVars;
  BackendDAE.IncidenceMatrix mtsel,msel2,msel2t;
  list<BackendDAE.IncidenceMatrixElement> mLst;
algorithm
    (mapEqnIncRow,mapIncRowEqn) := mapInfo;
    (ass1In,ass2In,discreteVars) := assIn;
      // Cellier heuristic [MC1]
      // 1. choose rows(eqs) with most nonzero entries and write the column indexes(vars) for nonzeros in a list
      ((_,selectedcolsLst)) := Util.arrayFold(m,findMostEntries,(0,{}));
      selectedcols1 := List.unique(List.flatten(selectedcolsLst));
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"1st: " +& stringDelimitList(List.map(selectedcols1,intString),",") +& "\n");
      // Without discrete:
      (_,selectedcols1,_) := List.intersection1OnTrue(selectedcols1,discreteVars,intEq);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Without Discrete: " +& stringDelimitList(List.map(selectedcols1,intString),",") +& "\n(Variables in the equation(s) with most Variables)\n\n");    
      // 2. gather these columns in a new array (reduced mt)
      mtsel := Util.arraySelect(mt,selectedcols1);
      // 3. choose rows (vars) with most nonzero entries and write the indexes in a list
      ((edges,_,selectedcols2)) := Util.arrayFold(mtsel,findMostEntries2,(0,1,{}));
      selectedcols2 := List.unique(selectedcols2);
      // 4. convert indexes from mtsel to indexes from mt
      selectedcols1 := selectFromList(selectedcols1,selectedcols2);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"2nd: "+& stringDelimitList(List.map(selectedcols1,intString),",")+&"\n(Variables from (1st) with most occurrence in equations (" +& intString(edges) +&" times))\n\n");
      // 5. select the rows(eqs) from m which could be causalized by knowing one more Var
      ((_,assEq)) := List.fold(ass2In,getUnassigned,(1,{}));
      (assEq_multi,assEq_single) := traverseEqnsforAssignable(assEq,m,mapEqnIncRow,mapIncRowEqn,1,{},{});
      selectedrows := listAppend(assEq_multi,assEq_single);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, stringDelimitList(List.map(selectedrows,intString),",")+&"\n(Equations which could be causalized by knowing one more Var)\n\n");
      // 6. determine which possible Vars causalize most equations considering impossible assignments and write them into potentials
      msel2t := Util.arraySelect(mt,selectedcols1);
      ((_,_,_,_,potentials,_,_,_)) := Util.arrayFold(msel2t,selectCausalVars,(me,ass1In,selectedrows,selectedcols1,{},0,1,{}));
      // 7. convert indexes from msel2t to indexes from mt
      potentials := selectFromList(selectedcols1,potentials);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n3rd: "+& stringDelimitList(List.map(potentials,intString),",")+&"\n(Variables from (2nd) causalizing most equations - potentials)\n\n");
end potentialsCellier;


protected function potentialsCellier2" gets the potentials for the next tearing variable [MC2].
author: ptaeuber FHB 2014-02"
  input BackendDAE.IncidenceMatrix m,mt;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixTEnhanced met;
  input tuple<list<Integer>,list<Integer>,list<Integer>> assIn;
  input tuple<array<list<Integer>>,array<Integer>> mapInfo;
  output list<Integer> potentials;
protected
  Integer edges;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  list<list<Integer>> selectedcolsLst;
  list<Integer> varlst, ass1In,ass2In,selectedcols0,selectedcols1,selectedcols2,selectedrows,assEq,assEq_multi,assEq_single,discreteVars;
  BackendDAE.IncidenceMatrix mtsel,msel2,msel2t;
  list<BackendDAE.IncidenceMatrixElement> mLst;
algorithm
   (mapEqnIncRow,mapIncRowEqn) := mapInfo;
   (ass1In,ass2In,discreteVars) := assIn;
    // modified Cellier heuristic [MC2]
    // 0. Consider only non-discrete Vars
    varlst := List.intRange(arrayLength(mt));
    (_,selectedcols0,_) := List.intersection1OnTrue(varlst,discreteVars,intEq);
    mtsel := Util.arraySelect(mt,selectedcols0);
    // 1. choose rows (vars) with most nonzero entries and write the indexes in a list
    ((edges,_,selectedcols1)) := Util.arrayFold(mtsel,findMostEntries2,(0,1,{}));
    selectedcols1 := List.unique(selectedcols1);
    // convert indexes from mtsel to indexes from mt
    selectedcols1 := selectFromList(selectedcols0,selectedcols1);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"1st: "+& stringDelimitList(List.map(selectedcols1,intString),",")+&"\n(Non-discrete variables with most occurrence in equations (" +& intString(edges) +&" times))\n\n");
    // 2. select the rows(eqs) from m which could be causalized by knowing one more Var
    ((_,assEq)) := List.fold(ass2In,getUnassigned,(1,{}));
    (assEq_multi,assEq_single) := traverseEqnsforAssignable(assEq,m,mapEqnIncRow,mapIncRowEqn,1,{},{});
    selectedrows := listAppend(assEq_multi,assEq_single);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, stringDelimitList(List.map(selectedrows,intString),",")+&"\n(Equations which could be causalized by knowing one more Var)\n\n");
    // 3. determine which possible Vars causalize most equations considering impossible assignments and write them into potentials
    msel2t := Util.arraySelect(mt,selectedcols1);
    ((_,_,_,_,potentials,_,_,_)) := Util.arrayFold(msel2t,selectCausalVars,(me,ass1In,selectedrows,selectedcols1,{},0,1,{}));
    // 4. convert indexes from msel2t to indexes from mt
    potentials := selectFromList(selectedcols1,potentials);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n2nd: "+& stringDelimitList(List.map(potentials,intString),",")+&"\n(Variables from (1st) causalizing most equations - potentials)\n\n");
end potentialsCellier2;


protected function potentialsCellier3" gets the potentials for the next tearing variable [MC11].
author: ptaeuber FHB 2014-02"
  input BackendDAE.IncidenceMatrix m,mt;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixTEnhanced met;
  input tuple<list<Integer>,list<Integer>,list<Integer>> assIn;
  input tuple<array<list<Integer>>,array<Integer>> mapInfo;
  output list<Integer> potentials;
protected
  Integer edges;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  list<list<Integer>> selectedcolsLst;
  list<Integer> ass1In,ass2In,selectedcols1,selectedcols2,selectedrows,assEq,assEq_multi,assEq_single,discreteVars;
  BackendDAE.IncidenceMatrix mtsel,msel2,msel2t;
  list<BackendDAE.IncidenceMatrixElement> mLst;
algorithm
     (mapEqnIncRow,mapIncRowEqn) := mapInfo;
     (ass1In,ass2In,discreteVars) := assIn;
      // modified Cellier heuristic [MC11]
      // 1. choose rows(eqs) with most nonzero entries and write the column indexes(vars) for nonzeros in a list
      ((_,selectedcolsLst)) := Util.arrayFold(m,findMostEntries,(0,{}));
      selectedcols1 := List.unique(List.flatten(selectedcolsLst));
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"1st: " +& stringDelimitList(List.map(selectedcols1,intString),",") +& "\n");
      // Without discrete:
      (_,selectedcols1,_) := List.intersection1OnTrue(selectedcols1,discreteVars,intEq);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Without Discrete: " +& stringDelimitList(List.map(selectedcols1,intString),",") +& "\n(Variables in the equation(s) with most Variables)\n\n");    
      // 2. gather these columns in a new array (reduced mt)
      mtsel := Util.arraySelect(mt,selectedcols1);
      // 3. choose rows (vars) with most nonzero entries and write the indexes in a list
      ((edges,_,selectedcols2)) := Util.arrayFold(mtsel,findMostEntries2,(0,1,{}));
      selectedcols2 := List.unique(selectedcols2);
      // 4. convert indexes from mtsel to indexes from mt
      selectedcols1 := selectFromList(selectedcols1,selectedcols2);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"2nd: "+& stringDelimitList(List.map(selectedcols1,intString),",")+&"\n(Variables from (1st) with most occurrence in equations (" +& intString(edges) +&" times))\n\n");
      // 5. select the rows(eqs) from m which could be causalized by knowing one more Var
      ((_,assEq)) := List.fold(ass2In,getUnassigned,(1,{}));
      (assEq_multi,assEq_single) := traverseEqnsforAssignable(assEq,m,mapEqnIncRow,mapIncRowEqn,1,{},{});
      selectedrows := listAppend(assEq_multi,assEq_single);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, stringDelimitList(List.map(selectedrows,intString),",")+&"\n(Equations which could be causalized by knowing one more Var)\n\n");
      // 6. determine which possible Vars causalize most equations considering impossible assignments and write them into potentials
      msel2t := Util.arraySelect(mt,selectedcols1);
      ((_,_,_,_,potentials,_,_,_)) := Util.arrayFold(msel2t,selectCausalVars,(me,ass1In,selectedrows,selectedcols1,{},0,1,{}));
      // 7. convert indexes from msel2t to indexes from mt
      potentials := selectFromList(selectedcols1,potentials);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n3rd: "+& stringDelimitList(List.map(potentials,intString),",")+&"\n(Variables from (2nd) causalizing most equations)\n\n");
      // 8. choose vars with the most impossible assignments
      (potentials,_,_) := countImpossibleAss(potentials,ass2In,met,{},{},0);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n4th: "+& stringDelimitList(List.map(potentials,intString),",")+&"\n(Variables from (3rd) with most incident impossible assignments - potentials)\n\n");
end potentialsCellier3;


protected function potentialsCellier4" gets the potentials for the next tearing variable [MC21].
author: ptaeuber FHB 2014-02"
  input BackendDAE.IncidenceMatrix m,mt;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixTEnhanced met;
  input tuple<list<Integer>,list<Integer>,list<Integer>> assIn;
  input tuple<array<list<Integer>>,array<Integer>> mapInfo;
  output list<Integer> potentials;
protected
  Integer edges;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  list<list<Integer>> selectedcolsLst;
  list<Integer> varlst,ass1In,ass2In,selectedcols0,selectedcols1,selectedcols2,selectedrows,assEq,assEq_multi,assEq_single,discreteVars;
  BackendDAE.IncidenceMatrix mtsel,msel2,msel2t;
  list<BackendDAE.IncidenceMatrixElement> mLst;
algorithm
   (mapEqnIncRow,mapIncRowEqn) := mapInfo;
   (ass1In,ass2In,discreteVars) := assIn;
    // modified Cellier heuristic [MC21]
    // 0. Consider only non-discrete Vars
    varlst := List.intRange(arrayLength(mt));
    (_,selectedcols0,_) := List.intersection1OnTrue(varlst,discreteVars,intEq);
    mtsel := Util.arraySelect(mt,selectedcols0);
    // 1. choose rows (vars) with most nonzero entries and write the indexes in a list
    ((edges,_,selectedcols1)) := Util.arrayFold(mtsel,findMostEntries2,(0,1,{}));
    selectedcols1 := List.unique(selectedcols1);
    // convert indexes from mtsel to indexes from mt
    selectedcols1 := selectFromList(selectedcols0,selectedcols1);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"1st: "+& stringDelimitList(List.map(selectedcols1,intString),",")+&"\n(Non-discrete variables with most occurrence in equations (" +& intString(edges) +&" times))\n\n");
    // 2. select the rows(eqs) from m which could be causalized by knowing one more Var
    ((_,assEq)) := List.fold(ass2In,getUnassigned,(1,{}));
    (assEq_multi,assEq_single) := traverseEqnsforAssignable(assEq,m,mapEqnIncRow,mapIncRowEqn,1,{},{});
    selectedrows := listAppend(assEq_multi,assEq_single);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, stringDelimitList(List.map(selectedrows,intString),",")+&"\n(Equations which could be causalized by knowing one more Var)\n\n");
    // 3. determine which possible Vars causalize most equations considering impossible assignments and write them into potentials
    msel2t := Util.arraySelect(mt,selectedcols1);
    ((_,_,_,_,potentials,_,_,_)) := Util.arrayFold(msel2t,selectCausalVars,(me,ass1In,selectedrows,selectedcols1,{},0,1,{}));
    // 4. convert indexes from msel2t to indexes from mt
    potentials := selectFromList(selectedcols1,potentials);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n2nd: "+& stringDelimitList(List.map(potentials,intString),",")+&"\n(Variables from (1st) causalizing most equations)\n\n");
    // 5. choose vars with the most impossible assignments
    (potentials,_,_) := countImpossibleAss(potentials,ass2In,met,{},{},0);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n3rd: "+& stringDelimitList(List.map(potentials,intString),",")+&"\n(Variables from (2nd) with most incident impossible assignments - potentials)\n\n");
end potentialsCellier4;


protected function potentialsCellier5" gets the potentials for the next tearing variable [MC12].
author: ptaeuber FHB 2014-02"
  input BackendDAE.IncidenceMatrix m,mt;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixTEnhanced met;
  input tuple<list<Integer>,list<Integer>,list<Integer>> assIn;
  input tuple<array<list<Integer>>,array<Integer>> mapInfo;
  output list<Integer> potentials;
protected
  Integer edges;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  list<list<Integer>> selectedcolsLst;
  list<Integer> ass1In,ass2In,selectedcols1,selectedcols2,selectedrows,assEq,assEq_multi,assEq_single,discreteVars;
  BackendDAE.IncidenceMatrix mtsel,msel2,msel2t;
  list<BackendDAE.IncidenceMatrixElement> mLst;
algorithm
     (mapEqnIncRow,mapIncRowEqn) := mapInfo;
     (ass1In,ass2In,discreteVars) := assIn;
      // modified Cellier heuristic [MC12]
      // 1. choose rows(eqs) with most nonzero entries and write the column indexes(vars) for nonzeros in a list
      ((_,selectedcolsLst)) := Util.arrayFold(m,findMostEntries,(0,{}));
      selectedcols1 := List.unique(List.flatten(selectedcolsLst));
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"1st: " +& stringDelimitList(List.map(selectedcols1,intString),",") +& "\n");
      // Without discrete:
      (_,selectedcols1,_) := List.intersection1OnTrue(selectedcols1,discreteVars,intEq);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Without Discrete: " +& stringDelimitList(List.map(selectedcols1,intString),",") +& "\n(Variables in the equation(s) with most Variables)\n\n");    
      // 2. gather these columns in a new array (reduced mt)
      mtsel := Util.arraySelect(mt,selectedcols1);
      // 3. choose rows (vars) with most nonzero entries and write the indexes in a list
      ((edges,_,selectedcols2)) := Util.arrayFold(mtsel,findMostEntries2,(0,1,{}));
      selectedcols2 := List.unique(selectedcols2);
      // 4. convert indexes from mtsel to indexes from mt
      selectedcols1 := selectFromList(selectedcols1,selectedcols2);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"2nd: "+& stringDelimitList(List.map(selectedcols1,intString),",")+&"\n(Variables from (1st) with most occurrence in equations (" +& intString(edges) +&" times))\n\n");
      // 5. choose vars with the most impossible assignments
      (selectedcols1,_,_) := countImpossibleAss(selectedcols1,ass2In,met,{},{},0);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n3rd: "+& stringDelimitList(List.map(selectedcols1,intString),",")+&"\n(Variables from (2nd) with most incident impossible assignments)\n\n");   
      // 6. select the rows(eqs) from m which could be causalized by knowing one more Var
      ((_,assEq)) := List.fold(ass2In,getUnassigned,(1,{}));
      (assEq_multi,assEq_single) := traverseEqnsforAssignable(assEq,m,mapEqnIncRow,mapIncRowEqn,1,{},{});
      selectedrows := listAppend(assEq_multi,assEq_single);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, stringDelimitList(List.map(selectedrows,intString),",")+&"\n(Equations which could be causalized by knowing one more Var)\n\n");
      // 7. determine which possible Vars causalize most equations considering impossible assignments and write them into potentials
      msel2t := Util.arraySelect(mt,selectedcols1);
      ((_,_,_,_,potentials,_,_,_)) := Util.arrayFold(msel2t,selectCausalVars,(me,ass1In,selectedrows,selectedcols1,{},0,1,{}));
      // 8. convert indexes from msel2t to indexes from mt
      potentials := selectFromList(selectedcols1,potentials);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n4th: "+& stringDelimitList(List.map(potentials,intString),",")+&"\n(Variables from (3rd) causalizing most equations - potentials)\n\n");
end potentialsCellier5;


protected function potentialsCellier6" gets the potentials for the next tearing variable [MC22].
author: ptaeuber FHB 2014-02"
  input BackendDAE.IncidenceMatrix m,mt;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixTEnhanced met;
  input tuple<list<Integer>,list<Integer>,list<Integer>> assIn;
  input tuple<array<list<Integer>>,array<Integer>> mapInfo;
  output list<Integer> potentials;
protected
  Integer edges;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  list<list<Integer>> selectedcolsLst;
  list<Integer> varlst,ass1In,ass2In,selectedcols0,selectedcols1,selectedcols2,selectedrows,assEq,assEq_multi,assEq_single,discreteVars;
  BackendDAE.IncidenceMatrix mtsel,msel2,msel2t;
  list<BackendDAE.IncidenceMatrixElement> mLst;
algorithm
   (mapEqnIncRow,mapIncRowEqn) := mapInfo;
   (ass1In,ass2In,discreteVars) := assIn;
    // modified Cellier heuristic [MC22]
    // 0. Consider only non-discrete Vars
    varlst := List.intRange(arrayLength(mt));
    (_,selectedcols0,_) := List.intersection1OnTrue(varlst,discreteVars,intEq);
    mtsel := Util.arraySelect(mt,selectedcols0);
    // 1. choose rows (vars) with most nonzero entries and write the indexes in a list
    ((edges,_,selectedcols1)) := Util.arrayFold(mtsel,findMostEntries2,(0,1,{}));
    selectedcols1 := List.unique(selectedcols1);
    // convert indexes from mtsel to indexes from mt
    selectedcols1 := selectFromList(selectedcols0,selectedcols1);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"1st: "+& stringDelimitList(List.map(selectedcols1,intString),",")+&"\n(Non-discrete variables with most occurrence in equations (" +& intString(edges) +&" times))\n\n");
    // 2. choose vars with the most impossible assignments
    (selectedcols1,_,_) := countImpossibleAss(selectedcols1,ass2In,met,{},{},0);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n2nd: "+& stringDelimitList(List.map(selectedcols1,intString),",")+&"\n(Variables from (1st) with most incident impossible assignments)\n\n");
    // 3. select the rows(eqs) from m which could be causalized by knowing one more Var
    ((_,assEq)) := List.fold(ass2In,getUnassigned,(1,{}));
    (assEq_multi,assEq_single) := traverseEqnsforAssignable(assEq,m,mapEqnIncRow,mapIncRowEqn,1,{},{});
    selectedrows := listAppend(assEq_multi,assEq_single);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, stringDelimitList(List.map(selectedrows,intString),",")+&"\n(Equations which could be causalized by knowing one more Var)\n\n");
    // 4. determine which possible Vars causalize most equations considering impossible assignments and write them into potentials
    msel2t := Util.arraySelect(mt,selectedcols1);
    ((_,_,_,_,potentials,_,_,_)) := Util.arrayFold(msel2t,selectCausalVars,(me,ass1In,selectedrows,selectedcols1,{},0,1,{}));
    // 5. convert indexes from msel2t to indexes from mt
    potentials := selectFromList(selectedcols1,potentials);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n3rd: "+& stringDelimitList(List.map(potentials,intString),",")+&"\n(Variables from (2nd) causalizing most equations - potentials)\n\n");
end potentialsCellier6;


protected function potentialsCellier7" gets the potentials for the next tearing variable [MC13].
author: ptaeuber FHB 2014-02"
  input BackendDAE.IncidenceMatrix m,mt;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixTEnhanced met;
  input tuple<list<Integer>,list<Integer>,list<Integer>> assIn;
  input tuple<array<list<Integer>>,array<Integer>> mapInfo;
  output list<Integer> potentials;
protected
  Integer edges;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  list<list<Integer>> selectedcolsLst;
  list<Integer> ass1In,ass2In,selectedcols1,selectedcols2,selectedrows,assEq,assEq_multi,assEq_single,discreteVars,potentials1,points,counts1,counts2;
  BackendDAE.IncidenceMatrix mtsel,msel2,msel2t;
  list<BackendDAE.IncidenceMatrixElement> mLst;
algorithm
    (mapEqnIncRow,mapIncRowEqn) := mapInfo;
    (ass1In,ass2In,discreteVars) := assIn;
      // Cellier heuristic [MC13]
      // 1. choose rows(eqs) with most nonzero entries and write the column indexes(vars) for nonzeros in a list
      ((_,selectedcolsLst)) := Util.arrayFold(m,findMostEntries,(0,{}));
      selectedcols1 := List.unique(List.flatten(selectedcolsLst));
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"1st: " +& stringDelimitList(List.map(selectedcols1,intString),",") +& "\n");
      // Without discrete:
      (_,selectedcols1,_) := List.intersection1OnTrue(selectedcols1,discreteVars,intEq);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Without Discrete: " +& stringDelimitList(List.map(selectedcols1,intString),",") +& "\n(Variables in the equation(s) with most Variables)\n\n");    
      // 2. gather these columns in a new array (reduced mt)
      mtsel := Util.arraySelect(mt,selectedcols1);
      // 3. choose rows (vars) with most nonzero entries and write the indexes in a list
      ((edges,_,selectedcols2)) := Util.arrayFold(mtsel,findMostEntries2,(0,1,{}));
      selectedcols2 := List.unique(selectedcols2);
      // 4. convert indexes from mtsel to indexes from mt
      selectedcols1 := selectFromList(selectedcols1,selectedcols2);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"2nd: "+& stringDelimitList(List.map(selectedcols1,intString),",")+&"\n(Variables from (1st) with most occurrence in equations (" +& intString(edges) +&" times))\n\n");
      // 5. select the rows(eqs) from m which could be causalized by knowing one more Var
      ((_,assEq)) := List.fold(ass2In,getUnassigned,(1,{}));
      (assEq_multi,assEq_single) := traverseEqnsforAssignable(assEq,m,mapEqnIncRow,mapIncRowEqn,1,{},{});
      selectedrows := listAppend(assEq_multi,assEq_single);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, stringDelimitList(List.map(selectedrows,intString),",")+&"\n(Equations which could be causalized by knowing one more Var)\n\n");
      // 6. determine for each variable the number of equations it could causalize considering impossible assignments and save them in counts1
      msel2t := Util.arraySelect(mt,selectedcols1);
      ((_,_,_,_,_,_,_,counts1)) := Util.arrayFold(msel2t,selectCausalVars,(me,ass1In,selectedrows,selectedcols1,{},0,1,{}));
      counts1 := listReverse(counts1);
      // 8. determine for each variable the number of impossible assignments and save them in counts2
      (_,counts2,_) := countImpossibleAss(selectedcols1,ass2In,met,{},{},0);
      counts2 := listReverse(counts2);
      // 9. Calculate the sum of number of impossible assignments and causalizable equations for each variable and save them in points
      points := List.threadMap(counts1,counts2,intAdd);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nPoints: "+& stringDelimitList(List.map(points,intString),",")+&"\n(Sum of impossible assignments and causalizable equations)\n");
      // 10. Choose vars with most points as potentials and convert indexes
      potentials := maxListInt(points);
      potentials := selectFromList(selectedcols1,potentials);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n3rd: "+& stringDelimitList(List.map(potentials,intString),",")+&"\n(Variables from (2nd) with most points - potentials)\n\n");
end potentialsCellier7;


protected function potentialsCellier8" gets the potentials for the next tearing variable [MC23].
author: ptaeuber FHB 2014-02"
  input BackendDAE.IncidenceMatrix m,mt;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixTEnhanced met;
  input tuple<list<Integer>,list<Integer>,list<Integer>> assIn;
  input tuple<array<list<Integer>>,array<Integer>> mapInfo;
  output list<Integer> potentials;
protected
  Integer edges;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  list<list<Integer>> selectedcolsLst;
  list<Integer> varlst,ass1In,ass2In,selectedcols0,selectedcols1,selectedcols2,selectedrows,assEq,assEq_multi,assEq_single,discreteVars,potentials1,points,counts1,counts2;
  BackendDAE.IncidenceMatrix mtsel,msel2,msel2t;
  list<BackendDAE.IncidenceMatrixElement> mLst;
algorithm
      (mapEqnIncRow,mapIncRowEqn) := mapInfo;
      (ass1In,ass2In,discreteVars) := assIn;
      // Cellier heuristic [MC23]
      // 0. Consider only non-discrete Vars
      varlst := List.intRange(arrayLength(mt));
      (_,selectedcols0,_) := List.intersection1OnTrue(varlst,discreteVars,intEq);
      mtsel := Util.arraySelect(mt,selectedcols0);
      // 1. choose rows (vars) with most nonzero entries and write the indexes in a list
      ((edges,_,selectedcols1)) := Util.arrayFold(mtsel,findMostEntries2,(0,1,{}));
      selectedcols1 := List.unique(selectedcols1);
      // 2. convert indexes from mtsel to indexes from mt
      selectedcols1 := selectFromList(selectedcols0,selectedcols1);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"1st: "+& stringDelimitList(List.map(selectedcols1,intString),",")+&"\n(Non-discrete variables with most occurrence in equations (" +& intString(edges) +&" times))\n\n");
       // 3. select the rows(eqs) from m which could be causalized by knowing one more Var
      ((_,assEq)) := List.fold(ass2In,getUnassigned,(1,{}));
      (assEq_multi,assEq_single) := traverseEqnsforAssignable(assEq,m,mapEqnIncRow,mapIncRowEqn,1,{},{});
      selectedrows := listAppend(assEq_multi,assEq_single);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, stringDelimitList(List.map(selectedrows,intString),",")+&"\n(Equations which could be causalized by knowing one more Var)\n\n");
      // 4. determine for each variable the number of equations it could causalize considering impossible assignments and save them in counts1
      msel2t := Util.arraySelect(mt,selectedcols1);
      ((_,_,_,_,_,_,_,counts1)) := Util.arrayFold(msel2t,selectCausalVars,(me,ass1In,selectedrows,selectedcols1,{},0,1,{}));
      counts1 := listReverse(counts1);
      // 5. determine for each variable the number of impossible assignments and save them in counts2
      (_,counts2,_) := countImpossibleAss(selectedcols1,ass2In,met,{},{},0);
      counts2 := listReverse(counts2);
      // 6. Calculate the sum of number of impossible assignments and causalizable equations for each variable and save them in points
      points := List.threadMap(counts1,counts2,intAdd);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nPoints: "+& stringDelimitList(List.map(points,intString),",")+&"\n(Sum of impossible assignments and causalizable equations)\n");
      // 7. Choose vars with most points as potentials and convert indexes
      potentials := maxListInt(points);
      potentials := selectFromList(selectedcols1,potentials);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n2nd: "+& stringDelimitList(List.map(potentials,intString),",")+&"\n(Variables from (1st) with most points - potentials)\n\n");
end potentialsCellier8;


protected function potentialsCellier9" gets the potentials for the next tearing variable [MC231].
author: ptaeuber FHB 2014-02"
  input BackendDAE.IncidenceMatrix m,mt;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixTEnhanced met;
  input tuple<list<Integer>,list<Integer>,list<Integer>> assIn;
  input tuple<array<list<Integer>>,array<Integer>> mapInfo;
  output list<Integer> potentials;
protected
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  Integer edges,potpoints1,potpoints2;
  list<list<Integer>> selectedcolsLst;
  list<Integer> varlst,ass1In,ass2In,selectedcols0,selectedcols1,selectedcols2,selectedrows,potentials1,potentials2,assEq,assEq_multi,assEq_single,discreteVars,counts1,counts2,points1,points2;
  BackendDAE.IncidenceMatrix mtsel,msel2,msel2t;
  list<BackendDAE.IncidenceMatrixElement> mLst;
  Boolean b;
algorithm
    (mapEqnIncRow,mapIncRowEqn) := mapInfo;
    (ass1In,ass2In,discreteVars) := assIn;
    // modified Cellier heuristic [MC231]
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Start round 1:\n==============\n\n");
    // 0. Consider only non-discrete Vars
    varlst := List.intRange(arrayLength(mt));
    (_,selectedcols0,_) := List.intersection1OnTrue(varlst,discreteVars,intEq);
    mtsel := Util.arraySelect(mt,selectedcols0);
    // 1. choose rows (vars) with most nonzero entries and write the indexes in a list
    ((edges,_,selectedcols1)) := Util.arrayFold(mtsel,findMostEntries2,(0,1,{}));
    selectedcols1 := List.unique(selectedcols1);
    // 2. convert indexes from mtsel to indexes from mt
    selectedcols1 := selectFromList(selectedcols0,selectedcols1);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"1st: "+& stringDelimitList(List.map(selectedcols1,intString),",")+&"\n(Non-discrete variables with most occurrence in equations (" +& intString(edges) +&" times))\n\n");
    // 3. select the rows(eqs) from m which could be causalized by knowing one more Var
    ((_,assEq)) := List.fold(ass2In,getUnassigned,(1,{}));
    (assEq_multi,assEq_single) := traverseEqnsforAssignable(assEq,m,mapEqnIncRow,mapIncRowEqn,1,{},{});
    selectedrows := listAppend(assEq_multi,assEq_single);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, stringDelimitList(List.map(selectedrows,intString),",")+&"\n(Equations which could be causalized by knowing one more Var)\n\n");
    // 4. determine for each variable the number of equations it could causalize considering impossible assignments and save them in counts1
    msel2t := Util.arraySelect(mt,selectedcols1);
    ((_,_,_,_,_,_,_,counts1)) := Util.arrayFold(msel2t,selectCausalVars,(me,ass1In,selectedrows,selectedcols1,{},0,1,{}));
    counts1 := listReverse(counts1);
    // 5. determine for each variable the number of impossible assignments and save them in counts2
    (_,counts2,_) := countImpossibleAss(selectedcols1,ass2In,met,{},{},0);
    counts2 := listReverse(counts2);
    // 6. Calculate the sum of number of impossible assignments and causalizable equations for each variable and save them in points1
    points1 := List.threadMap(counts1,counts2,intAdd);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nPoints: "+& stringDelimitList(List.map(points1,intString),",")+&"\n(Sum of impossible assignments and causalizable equations)\n");
    // 7. Choose vars with most points as potentials and convert indexes
    potentials1 := maxListInt(points1);
    potpoints1 := listGet(points1,listGet(potentials1,1));
    potentials1 := selectFromList(selectedcols1,potentials1);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n2nd: "+& stringDelimitList(List.map(potentials1,intString),",")+&"\n(Variables from (1st) with most points (" +& intString(potpoints1) +& " points) - potentials1)\n\n");
    // 8. choose non-discrete vars with edges-1 edges and write the indexes in a list
    ((_,_,selectedcols1)) := Util.arrayFold(mtsel,findNEntries,(edges-1,1,{}));
    selectedcols1 := List.unique(selectedcols1);
    // 9. convert indexes from mtsel to indexes from mt
    selectedcols1 := selectFromList(selectedcols0,selectedcols1);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nStart round 2:\n==============\n\n1st: "+& stringDelimitList(List.map(selectedcols1,intString),",")+&"\n(Variables with occurrence in " +& intString(edges-1) +& " equations)\n\n" +& stringDelimitList(List.map(selectedrows,intString),",")+&"\n(Equations which could be causalized by knowing one more Var)\n\n");
    // 10. determine for each variable the number of equations it could causalize considering impossible assignments and save them in counts1
    msel2t := Util.arraySelect(mt,selectedcols1);
    ((_,_,_,_,_,_,_,counts1)) := Util.arrayFold(msel2t,selectCausalVars,(me,ass1In,selectedrows,selectedcols1,{},0,1,{}));
    counts1 := listReverse(counts1);
    // 11. determine for each variable the number of impossible assignments and save them in counts2
    (_,counts2,_) := countImpossibleAss(selectedcols1,ass2In,met,{},{},0);
    counts2 := listReverse(counts2);
    // 12. Calculate the sum of number of impossible assignments and causalizable equations for each variable and save them in points2
    points2 := List.threadMap(counts1,counts2,intAdd);
    points2 := Util.if_(listLength(points2)==0,{0},points2);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nPoints: "+& stringDelimitList(List.map(points2,intString),",")+&"\n(Sum of impossible assignments and causalizable equations)\n");
    // 13. Choose vars with most points as potentials and convert indexes
    potentials2 := maxListInt(points2);
    potpoints2 := listGet(points2,listGet(potentials2,1));
    potentials2 := selectFromList(selectedcols1,potentials2);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n2nd: "+& stringDelimitList(List.map(potentials2,intString),",")+&"\n(Variables from (1st) with most points (" +& intString(potpoints2) +& " points) - potentials2)\n\n");
    // 14. choose potentials-set with most points
    b := intGe(potpoints1,potpoints2);
    potentials := Util.if_(b,potentials1,potentials2);
       Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n=====================\nChosen potential-set: " +& stringDelimitList(List.map(potentials,intString),",") +& "\n=====================\n(from round 1: " +& boolString(b) +& ")\n\n");
end potentialsCellier9;


protected function potentialsCellier10" gets the potentials for the next tearing variable [MC3].
author: ptaeuber FHB 2014-02"
  input BackendDAE.IncidenceMatrix m,mt;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixTEnhanced met;
  input tuple<list<Integer>,list<Integer>,list<Integer>> assIn;
  input tuple<array<list<Integer>>,array<Integer>> mapInfo;
  output list<Integer> potentials;
protected
  Integer edges;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  list<list<Integer>> selectedcolsLst;
  list<Integer> varlst,ass1In,ass2In,selectedcols0,selectedcols1,selectedcols2,selectedrows,assEq,assEq_multi,assEq_single,discreteVars,potentials1,points,counts1,counts2;
  BackendDAE.IncidenceMatrix mtsel,msel2,msel2t;
  list<BackendDAE.IncidenceMatrixElement> mLst;
algorithm
      (mapEqnIncRow,mapIncRowEqn) := mapInfo;
      (ass1In,ass2In,discreteVars) := assIn;
      // Cellier heuristic [MC3]
      // 0. Consider only non-discrete Vars
      varlst := List.intRange(arrayLength(mt));
      ((_,_,selectedcols0)) := Util.arrayFold(mt,findNEntries,(0,1,{}));
      (_,selectedcols0,_) := List.intersection1OnTrue(varlst,selectedcols0,intEq);
      (_,selectedcols0,_) := List.intersection1OnTrue(selectedcols0,discreteVars,intEq);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"1st: "+& stringDelimitList(List.map(selectedcols0,intString),",")+&"\n(All non-discrete left variables)\n\n");
       // 1. select the rows(eqs) from m which could be causalized by knowing one more Var
      ((_,assEq)) := List.fold(ass2In,getUnassigned,(1,{}));
      (assEq_multi,assEq_single) := traverseEqnsforAssignable(assEq,m,mapEqnIncRow,mapIncRowEqn,1,{},{});
      selectedrows := listAppend(assEq_multi,assEq_single);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, stringDelimitList(List.map(selectedrows,intString),",")+&"\n(Equations which could be causalized by knowing one more Var)\n\n");
       // 2. determine for each variable the number of equations it could causalize considering impossible assignments and save them in counts1
      mtsel := Util.arraySelect(mt,selectedcols0);
      ((_,_,_,_,_,_,_,counts1)) := Util.arrayFold(mtsel,selectCausalVars,(me,ass1In,selectedrows,selectedcols0,{},0,1,{}));
      counts1 := listReverse(counts1);
      // 3. determine for each variable the number of impossible assignments and save them in counts2
      (_,counts2,_) := countImpossibleAss(selectedcols0,ass2In,met,{},{},0);
      counts2 := listReverse(counts2);
      // 4. Calculate the sum of number of impossible assignments and causalizable equations for each variable and save them in points
      points := List.threadMap(counts1,counts2,intAdd);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nPoints: "+& stringDelimitList(List.map(points,intString),",")+&"\n(Sum of impossible assignments and causalizable equations)\n");
      // 5. Choose vars with most points and save them in selectedcols1
      selectedcols1 := maxListInt(points);
      selectedcols1 := selectFromList(selectedcols0,selectedcols1);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n2nd: "+& stringDelimitList(List.map(selectedcols1,intString),",")+&"\n(Variables from (1st) with most points)\n\n");
      // 6. Choose vars with most occurrence in equations as potentials
      mtsel := Util.arraySelect(mt,selectedcols1);
      ((edges,_,potentials)) := Util.arrayFold(mtsel,findMostEntries2,(0,1,{}));
      potentials := List.unique(potentials);
      // 7. convert indexes from mtsel to indexes from mt
      potentials := selectFromList(selectedcols1,potentials);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"3rd: "+& stringDelimitList(List.map(potentials,intString),",")+&"\n(Variables from (2nd) with most occurrence in equations (" +& intString(edges) +&" times) - potentials)\n\n");
end potentialsCellier10;


protected function potentialsCellier11" gets the potentials for the next tearing variable [MC4].
author: ptaeuber FHB 2014-02"
  input BackendDAE.IncidenceMatrix m,mt;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixTEnhanced met;
  input tuple<list<Integer>,list<Integer>,list<Integer>> assIn;
  input tuple<array<list<Integer>>,array<Integer>> mapInfo;
  output list<Integer> potentials;
protected
  Integer edges;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  list<Integer> ass1In,ass2In,discreteVars,potentials1,potentials2,potentials3,potentials4,potentials5,potentials6,potentials7,potentials8,potentials9,potentials10,selectedvars,count;
  BackendDAE.IncidenceMatrix mtsel;
algorithm
      (mapEqnIncRow,mapIncRowEqn) := mapInfo;
      (ass1In,ass2In,discreteVars) := assIn;
      // Cellier heuristic [MC4]
      // 1. Use heuristics MC1, MC2, MC11, MC21, MC12, MC22, MC13, MC23, MC231, MC3 to determine their potential sets
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Heuristic uses all modified Cellier-Heuristics\n\nHeuristic [MC1]\n"+& BORDER +&"\n");
      potentials1 := potentialsCellier(m,mt,me,met,assIn,mapInfo);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n\nHeuristic [MC2]\n"+& BORDER +&"\n");
      potentials2 := potentialsCellier2(m,mt,me,met,assIn,mapInfo);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n\nHeuristic [MC11]\n"+& BORDER +&"\n");
      potentials3 := potentialsCellier3(m,mt,me,met,assIn,mapInfo);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n\nHeuristic [MC21]\n"+& BORDER +&"\n");
      potentials4 := potentialsCellier4(m,mt,me,met,assIn,mapInfo);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n\nHeuristic [MC12]\n"+& BORDER +&"\n");
      potentials5 := potentialsCellier5(m,mt,me,met,assIn,mapInfo);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n\nHeuristic [MC22]\n"+& BORDER +&"\n");
      potentials6 := potentialsCellier6(m,mt,me,met,assIn,mapInfo);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n\nHeuristic [MC13]\n"+& BORDER +&"\n");
      potentials7 := potentialsCellier7(m,mt,me,met,assIn,mapInfo);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n\nHeuristic [MC23]\n"+& BORDER +&"\n");
      potentials8 := potentialsCellier8(m,mt,me,met,assIn,mapInfo);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n\nHeuristic [MC231]\n"+& BORDER +&"\n");
      potentials9 := potentialsCellier9(m,mt,me,met,assIn,mapInfo);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\n\nHeuristic [MC3]\n"+& BORDER +&"\n");
      potentials10 := potentialsCellier10(m,mt,me,met,assIn,mapInfo);
         Debug.fcall(Flags.TEARING_DUMP, print, BORDER +& "\n\nSynopsis:\n=========\n[MC1]: " +& stringDelimitList(List.map(potentials1,intString),",")+&"\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"[MC2]: " +& stringDelimitList(List.map(potentials2,intString),",")+&"\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"[MC11]: " +& stringDelimitList(List.map(potentials3,intString),",")+&"\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"[MC21]: " +& stringDelimitList(List.map(potentials4,intString),",")+&"\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"[MC12]: " +& stringDelimitList(List.map(potentials5,intString),",")+&"\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"[MC22]: " +& stringDelimitList(List.map(potentials6,intString),",")+&"\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"[MC13]: " +& stringDelimitList(List.map(potentials7,intString),",")+&"\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"[MC23]: " +& stringDelimitList(List.map(potentials8,intString),",")+&"\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"[MC231]: " +& stringDelimitList(List.map(potentials9,intString),",")+&"\n");
         Debug.fcall(Flags.TEARING_DUMP, print,"[MC3]: " +& stringDelimitList(List.map(potentials10,intString),",")+&"\n\n");
      // 2. Collect all variables from different potential-sets in one list
      selectedvars := listAppend(listAppend(listAppend(listAppend(listAppend(listAppend(listAppend(listAppend(listAppend(potentials1,potentials2),potentials3),potentials4),potentials5),potentials6),potentials7),potentials8),potentials9),potentials10);
         Debug.fcall(Flags.TEARING_DUMP, print, "1st: "+& stringDelimitList(List.map(selectedvars,intString),",")+&"\n(All potentials)\n\n");
      // 3. determine potentials with most occurrence in potential sets
     (count,selectedvars,_) := countMultiples(arrayCreate(1,selectedvars));
         Debug.fcall(Flags.TEARING_DUMP, print, "2nd: "+& stringDelimitList(List.map(selectedvars,intString),",")+&"\n(Variables from (1st) occurring in most potential-sets (" +& stringDelimitList(List.map(count,intString),",") +& " sets))\n\n");
      // 4. Choose vars with most occurrence in equations as potentials
      mtsel := Util.arraySelect(mt,selectedvars);
      ((edges,_,potentials)) := Util.arrayFold(mtsel,findMostEntries2,(0,1,{}));
      potentials := List.unique(potentials);
      // 7. convert indexes from mtsel to indexes from mt
      potentials := selectFromList(selectedvars,potentials);
         Debug.fcall(Flags.TEARING_DUMP, print,"3rd: "+& stringDelimitList(List.map(potentials,intString),",")+&"\n(Variables from (2nd) with most occurrence in equations (" +& intString(edges) +&" times) - potentials)\n\n\n");
end potentialsCellier11;


protected function selectCausalVars
" matches causalizable equations with selected variables.
  author: Waurich TUD 2012-11, enhanced: ptaeuber FHB 2013-10"
    input list<Integer> row;
    input tuple<BackendDAE.AdjacencyMatrixEnhanced,list<Integer>,list<Integer>,list<Integer>,list<Integer>,Integer,Integer,list<Integer>> inValue;
    output tuple<BackendDAE.AdjacencyMatrixEnhanced,list<Integer>,list<Integer>,list<Integer>,list<Integer>,Integer,Integer,list<Integer>> OutValue;
  algorithm
    OutValue := matchcontinue(row,inValue)
  local
    BackendDAE.AdjacencyMatrixEnhanced me;
    list<Integer> selEqs,selVars,cVars,interEqs,ass1In,counts;
    Integer size,num,indx;
    case(_,(me,ass1In,selEqs,selVars,cVars,num,indx,counts))
      equation
        interEqs = List.intersectionOnTrue(row,selEqs,intEq);
        size = List.fold4(interEqs,sizeOfAssignable,me,ass1In,selVars,indx,0);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Var " +& intString(listGet(selVars,indx)) +& " would causalize " +& intString(size) +& " Eqns\n");
        true = size < num;
      then ((me,ass1In,selEqs,selVars,cVars,num,indx+1,size::counts));
    case(_,(me,ass1In,selEqs,selVars,cVars,num,indx,counts))
      equation
        interEqs = List.intersectionOnTrue(row,selEqs,intEq);
        size = List.fold4(interEqs,sizeOfAssignable,me,ass1In,selVars,indx,0);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Var " +& intString(listGet(selVars,indx)) +& " would causalize " +& intString(size) +& " Eqns\n");
        true = size == num;
      then ((me,ass1In,selEqs,selVars,indx::cVars,num,indx+1,size::counts));
    case(_,(me,ass1In,selEqs,selVars,cVars,num,indx,counts))
      equation
        interEqs = List.intersectionOnTrue(row,selEqs,intEq);
        size = List.fold4(interEqs,sizeOfAssignable,me,ass1In,selVars,indx,0);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Var " +& intString(listGet(selVars,indx)) +& " would causalize " +& intString(size) +& " Eqns\n");
        true = size > num;
      then ((me,ass1In,selEqs,selVars,{indx},size,indx+1,size::counts));
    end matchcontinue;
  end selectCausalVars;
  
  
protected function sizeOfAssignable 
" calculates the number of equations a potential tvar would 
  causalize considering the impossible assignments
  author: ptaeuber FHB 2013-10"
  input Integer Eqn;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input list<Integer> ass1In,selVars;
  input Integer index;
  input Integer inSize;
  output Integer outSize;
protected
  Integer Var;
  list<Integer> ass1;
  BackendDAE.AdjacencyMatrixElementEnhanced Vars;
  Boolean b;
algorithm
  Var := listGet(selVars,index);
  ass1 := List.set(ass1In,Var,1);
  Vars := List.removeOnTrue(listArray(ass1), isAssignedSaveEnhanced,me[Eqn]);
  b := solvableLst(Vars);
  outSize := Util.if_(b,inSize+1,inSize);
end sizeOfAssignable;  


protected function countImpossibleAss
" function to return the variables with the highest number of impossible assignments
  considering the current matching
  author: ptaeuber FHB 2013-10"
  input list<Integer> inPotentials,ass2;
  input BackendDAE.AdjacencyMatrixEnhanced meT;
  input list<Integer> newPotentials,inCounts;
  input Integer max;
  output list<Integer> outPotentials,outCounts;
  output Integer outMax;
algorithm
 (outPotentials,outCounts,outMax) := match(inPotentials,ass2,meT,newPotentials,inCounts,max)
   local
     Integer v,count,maxi;
     list<Integer> rest,newPotentials1,counts;
   BackendDAE.AdjacencyMatrixElementEnhanced elem;
   case({},_,_,_,_,_)
     then (newPotentials,inCounts,max);
   case(v::rest,_,_,_,_,_)
    equation
    elem = List.removeOnTrue(listArray(ass2),isAssignedSaveEnhanced,meT[v]);
      count = countImpossibleAss2(elem,0);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"Var " +& intString(v) +& " has " +& intString(count) +& " incident impossible assignments\n");
      (newPotentials1,maxi) = countImpossibleAss3(count,max,v,newPotentials);
    (newPotentials1,counts,maxi) = countImpossibleAss(rest,ass2,meT,newPotentials1,count::inCounts,maxi);
     then (newPotentials1,counts,maxi);
  end match;
end countImpossibleAss;


protected function countImpossibleAss2
" helper function for countImpossibleAss,
  traverses AdjacencyMatrixElementEnhanced and counts the number of impossible assignments of one var
  author: ptaeuber FHB 2013-10"
  input BackendDAE.AdjacencyMatrixElementEnhanced elem;
  input Integer inCount;
  output Integer outCount;
algorithm
  outCount := matchcontinue(elem,inCount)
    local
    BackendDAE.AdjacencyMatrixElementEnhanced rest;
    BackendDAE.Solvability s;
  case({},_)
    then inCount;
  case((_,s)::rest,_)
   equation
     false = solvable(s);
    then countImpossibleAss2(rest,inCount+1);
  case((_,s)::rest,_)
    then countImpossibleAss2(rest,inCount);
 end matchcontinue;
end countImpossibleAss2;


protected function countImpossibleAss3
" helper function for countImpossibleAss,
  determines if there is a new maximum, returns updated list of potentials and new max
  author: ptaeuber FHB 2013-10"
  input Integer inCount;
  input Integer max;
  input Integer v;
  input list<Integer> inPotentials;
  output list<Integer> outPotentials;
  output Integer outCount;
algorithm
  (outPotentials,outCount) := matchcontinue(inCount,max,v,inPotentials)
  case(_,_,_,_)
   equation
   true = inCount == max;
    then (v::inPotentials,inCount);
  case(_,_,_,_)
   equation
     true = inCount > max;
  then ({v},inCount);
  else
    then (inPotentials,max);
  end matchcontinue;
end countImpossibleAss3;


protected function Tarjan"Tarjan assignment.
author:Waurich TUD 2012-11, enhanced: ptaeuber 2013-10"
  input BackendDAE.IncidenceMatrix mIn;
  input BackendDAE.IncidenceMatrixT mtIn;
  input BackendDAE.AdjacencyMatrixEnhanced meIn;
  input BackendDAE.AdjacencyMatrixTEnhanced metIn;
  input list<Integer> ass1In,ass2In;
  input list<list<Integer>> orderIn;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input Boolean assignable;
  output list<Integer> ass1Out,ass2Out;
  output BackendDAE.IncidenceMatrix mOut;
  output BackendDAE.IncidenceMatrixT mtOut;
  output list<list<Integer>> orderOut;
  output Boolean causal;
algorithm
   (ass1Out,ass2Out,mOut,mtOut,orderOut,causal):= matchcontinue(mIn,mtIn,meIn,metIn,ass1In,ass2In,orderIn,mapEqnIncRow,mapIncRowEqn,assignable)
   local
     list<Integer> ass1,ass2,subOrder,unassigned;
     list<list<Integer>> order;
     BackendDAE.IncidenceMatrix m;
     BackendDAE.IncidenceMatrixT mt;
     Boolean ass;
   case(_,_,_,_,_,_,_,_,_,false)
     equation
     ((_,unassigned)) = List.fold(ass1In,getUnassigned,(1,{}));
       false = List.isEmpty(unassigned);
          Debug.fcall(Flags.TEARING_DUMP, print,"\nnoncausal\n");
     then (ass1In,ass2In,mIn,mtIn,orderIn,false);
   case(_,_,_,_,_,_,_,_,_,false)
     equation
       ((_,unassigned)) = List.fold(ass1In,getUnassigned,(1,{}));
       true = List.isEmpty(unassigned);
          Debug.fcall(Flags.TEARING_DUMP, print,"\ncausal\n");
       subOrder = listGet(orderIn,1);
       subOrder = listReverse(subOrder);
       order = List.deletePositions(orderIn,{0});
       orderOut = subOrder::order;
     then (ass1In,ass2In,mIn,mtIn,orderOut,true);
   case(_,_,_,_,_,_,_,_,_,true)
     equation
          Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nTarjanAssignment:\n");
       (ass1,ass2,m,mt,order,ass) = TarjanAssignment(mIn,mtIn,meIn,metIn,ass1In,ass2In,orderIn,mapEqnIncRow,mapIncRowEqn);
         //print("ass1 "+&stringDelimitList(List.map(ass1,intString),",")+&"\n");
         //print("ass2 "+&stringDelimitList(List.map(ass2,intString),",")+&"\n");
       (ass1Out,ass2Out,mOut,mtOut,orderOut,causal)= Tarjan(m,mt,meIn,metIn,ass1,ass2,order,mapEqnIncRow,mapIncRowEqn,ass);
       then (ass1Out,ass2Out,mOut,mtOut,orderOut,causal);
   end matchcontinue;
end Tarjan;


protected function TarjanAssignment"
author:Waurich TUD 2012-11, enhanced: ptaeuber FHB 2013-10"
  input BackendDAE.IncidenceMatrix mIn;
  input BackendDAE.IncidenceMatrixT mtIn;
  input BackendDAE.AdjacencyMatrixEnhanced meIn;
  input BackendDAE.AdjacencyMatrixTEnhanced metIn;
  input list<Integer> ass1In,ass2In;
  input list<list<Integer>> orderIn;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  output list<Integer> ass1Out,ass2Out;
  output BackendDAE.IncidenceMatrix mOut;
  output BackendDAE.IncidenceMatrixT mtOut;
  output list<list<Integer>> orderOut;
  output Boolean assignable;
protected
  list<Integer> assEq,assEq_multi,assEq_single,assEq_coll,assVar,tvars,eqns,vars;
  Integer indx;
  list<Integer> markVar,markEq;
algorithm
  // select equations not assigned yet
  ((_,assEq)) := List.fold(ass2In,getUnassigned,(1,{}));
  (assEq_multi,assEq_single) := traverseEqnsforAssignable(assEq,mIn,mapEqnIncRow,mapIncRowEqn,0,{},{});
  assEq := listAppend(assEq_multi,assEq_single);
  // transform equationlist to equationlist with collective equations
  assEq_coll := List.map1r(assEq,arrayGet,mapIncRowEqn);
  assEq_coll := List.unique(assEq_coll);
  ((_,_,assVar)) := Util.arrayFold(mtIn,findNEntries,(1,1,{}));
  markVar := List.unique(ass2In);
  (_,assVar,_) := List.intersection1OnTrue(assVar,markVar,intEq);
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"assEq: "+&stringDelimitList(List.map(assEq,intString),",")+&"\n");
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"assEq_coll: "+&stringDelimitList(List.map(assEq_coll,intString),",")+&"\n");
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"assVar: "+&stringDelimitList(List.map(assVar,intString),",")+&"\n");
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"\nTarjanGetAssignable:\n");
  (eqns,vars,orderOut,assignable) := TarjanGetAssignable(mIn,mtIn,meIn,metIn,assEq_coll,assVar,ass1In,ass2In,mapEqnIncRow,mapIncRowEqn,orderIn);
  ((ass1Out,ass2Out,mOut,mtOut)) := makeAssignment(eqns,vars,ass1In,ass2In,mIn,mtIn);
     Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"order: "+&stringDelimitList(List.map(listReverse(listGet(orderOut,1)),intString),",")+&"\n\n");
     // Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, "\n\n###BEGIN print updated Incidence Matrix#############\n(Function: TarjanAssignment)\n");
     // Debug.fcall(Flags.TEARING_DUMPVERBOSE, BackendDump.dumpIncidenceMatrix, mOut);
     // Debug.fcall(Flags.TEARING_DUMPVERBOSE, BackendDump.dumpIncidenceMatrixT, mtOut);
     // Debug.fcall(Flags.TEARING_DUMPVERBOSE, print, "\n###END print updated Incidence Matrix###############\n(Function: TarjanAssignment)\n\n\n");
end TarjanAssignment;


protected function TarjanGetAssignable " selects assignable Var and Equation.
  author: Waurich TUD 2012-11, enhanced: ptaeuber FHB 2013-10"
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixTEnhanced met;
  input list<Integer> assEq_coll,assVar,ass1,ass2;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input list<list<Integer>> orderIn;
  output list<Integer> eqnsOut,varsOut;
  output list<list<Integer>> orderOut;
  output Boolean assignable;
algorithm
  (eqnsOut,varsOut,orderOut,assignable) := matchcontinue(m,mt,me,met,assEq_coll,assVar,ass1,ass2,mapEqnIncRow,mapIncRowEqn,orderIn)
  local
    Integer eq_coll,eq;
  list<Integer> eqns,vars;
    list<Integer> order;
    case(_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = List.isNotEmpty(assEq_coll);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"assign from m\n");
        ((eq_coll,eqns,vars)) = getpossibleEqnorVar((assEq_coll,m,me,listArray(ass1),listArray(ass2),mapEqnIncRow,1));
        order = listGet(orderIn,1);
        order = eq_coll::order;
        orderOut = List.replaceAt(order,0,orderIn);
      then (eqns,vars,orderOut,true);
    case(_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = List.isEmpty(assEq_coll);
        true = List.isNotEmpty(assVar);
           Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"assign from mt\n");
        ((_,vars,eqns)) = getpossibleEqnorVar((assVar,mt,met,listArray(ass1),listArray(ass2),mapEqnIncRow,2));
        eq = listGet(eqns,1);
        eq_coll = mapIncRowEqn[eq];
        order = listGet(orderIn,2);
        order = eq_coll::order;
        orderOut = List.replaceAt(order,1,orderIn);
      then (eqns,vars,orderOut,true);
    else
   equation
      then ({},{},orderIn,false);
  end matchcontinue;
end TarjanGetAssignable;


protected function getUnassigned " finds the unassigned vars or eqs.combine with List.fold"
  input Integer assEntry;
  input tuple<Integer,list<Integer>> InValue;
  output tuple<Integer,list<Integer>> OutValue;
algorithm
OutValue := matchcontinue(assEntry,InValue)
  local
    Integer indx;
    list<Integer> lst;
  case(_,(indx,lst))
    equation
    true = intEq(assEntry,-1);
    then
      ((indx+1,indx::lst));
  case(_,(indx,lst))
    equation
    false = intEq(assEntry,-1);
    then
      ((indx+1,lst));
  end matchcontinue;
end getUnassigned;


protected function traverseEqnsforAssignable
" selects next equations that can be causalized
  author: ptaeuber FHB 2013-10"
  input list<Integer> inAssEq;
  input BackendDAE.IncidenceMatrix m;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input Integer prescient;
  input list<Integer> inAcc1;
  input list<Integer> inAcc2;
  output list<Integer> outAssEq_multi;
  output list<Integer> outAssEq_single;
algorithm
 (outAssEq_multi,outAssEq_single) := matchcontinue(inAssEq,m,mapEqnIncRow,mapIncRowEqn,prescient,inAcc1,inAcc2)
   local
     Integer e,enonscalar,length;
   list<Integer> rest,acc1,acc2;
   case({},_,_,_,_,_,_)
     then (inAcc1,inAcc2);
   case(e::rest,_,_,_,_,_,_)
    equation
     length = listLength(m[e]);
     enonscalar = mapIncRowEqn[e];
     true = length == listLength(mapEqnIncRow[enonscalar]) + prescient;
     true = length == 1 + prescient;
     (acc1,acc2) = traverseEqnsforAssignable(rest,m,mapEqnIncRow,mapIncRowEqn,prescient,inAcc1,e::inAcc2);
  then (acc1,acc2);
   case(e::rest,_,_,_,_,_,_)
    equation
     enonscalar = mapIncRowEqn[e];
     true = listLength(m[e]) == listLength(mapEqnIncRow[enonscalar]) + prescient;
     (acc1,acc2) = traverseEqnsforAssignable(rest,m,mapEqnIncRow,mapIncRowEqn,prescient,e::inAcc1,inAcc2);
  then (acc1,acc2);  
   case(e::rest,_,_,_,_,_,_)
    equation
     (acc1,acc2) = traverseEqnsforAssignable(rest,m,mapEqnIncRow,mapIncRowEqn,prescient,inAcc1,inAcc2);
    then (acc1,acc2);
 end matchcontinue;
end traverseEqnsforAssignable;


protected function makeAssignment
" function to assign equations with variables
  author: ptaeuber FHB 2013-10"
  input list<Integer> eqns,vars,ass1In,ass2In;
  input BackendDAE.IncidenceMatrix mIn;
  input BackendDAE.IncidenceMatrixT mtIn;
  output tuple<list<Integer>,list<Integer>,BackendDAE.IncidenceMatrix,BackendDAE.IncidenceMatrixT> outTpl;
algorithm
 (outTpl) := matchcontinue(eqns,vars,ass1In,ass2In,mIn,mtIn)
   local
     Integer eq,var;
   list<Integer> rest1,rest2,ass1,ass2;
   BackendDAE.IncidenceMatrix m;
     BackendDAE.IncidenceMatrixT mt;
   case({},{},_,_,_,_)
     then ((ass1In,ass2In,mIn,mtIn));
   case(eq::rest1,var::rest2,_,_,_,_)
    equation
      ass1 = replaceAt(eq,var-1,ass1In);
      ass2 = replaceAt(var,eq-1,ass2In);
         Debug.fcall(Flags.TEARING_DUMPVERBOSE, print,"assignment: Eq"+&intString(eq)+&" - Var"+&intString(var)+&"\n");
      m = Util.arrayReplaceAtWithFill(eq,{},{},mIn);
      m = updateIncidence(m,var,1);
      mt = Util.arrayReplaceAtWithFill(var,{},{},mtIn);
      mt = updateIncidence(mt,eq,1);
   then makeAssignment(rest1,rest2,ass1,ass2,m,mt);
   else
    equation
      print("\n\nAssignment failed in Tearing.makeAssignment\n\n");
     then fail();
 end matchcontinue;
end makeAssignment;


protected function assignOtherEqnVarTpl " assigns otherEqnVarTpl for TORNSYSTEM 
  author: ptaeuber FHB 2013-08"
  input list<Integer> inEqns,eindex,vindx,ass2;
  input array<list<Integer>> mapEqnIncRow;
  input list<tuple<Integer,list<Integer>>> inOtherEqnVarTpl;
  output list<tuple<Integer,list<Integer>>> outOtherEqnVarTpl;  
algorithm
 outOtherEqnVarTpl := matchcontinue(inEqns,eindex,vindx,ass2,mapEqnIncRow,inOtherEqnVarTpl)
   local
     Integer eq,otherEqn;
     list<Integer> eqns,vars,otherVars,rest;
   case({},_,_,_,_,_)
     then listReverse(inOtherEqnVarTpl);
   case(eq::rest,_,_,_,_,_)
    equation
    eqns = mapEqnIncRow[eq];
    vars = List.map1r(eqns,listGet,ass2);
    otherEqn = listGet(eindex,eq);
    otherVars = listReverse(selectFromList(vindx,vars));
     then assignOtherEqnVarTpl(rest,eindex,vindx,ass2,mapEqnIncRow,(otherEqn,otherVars)::inOtherEqnVarTpl);   
 end matchcontinue;
end assignOtherEqnVarTpl;


protected function getpossibleEqnorVar " finds equation (findEqorVar=1) or 
varibale (findEqorVar=2) that can be matched
  author: ptaeuber FHB 2013-08"
  input tuple<list<Integer>,BackendDAE.IncidenceMatrix,BackendDAE.AdjacencyMatrixEnhanced,array<Integer>,array<Integer>,array<list<Integer>>,Integer> inTpl;
  output tuple<Integer,list<Integer>,list<Integer>> EqnsAndVars;
algorithm
  EqnsAndVars := matchcontinue(inTpl)
    local
      Integer eqn,eqn_coll,var;
      list<Integer> eqns,vars,rest;
      BackendDAE.IncidenceMatrix m_mt;
    BackendDAE.AdjacencyMatrixElementEnhanced vars_enh,eqn_enh;
      BackendDAE.AdjacencyMatrixEnhanced me_met;
      array<Integer> ass1,ass2;
      array<list<Integer>> mapEqnIncRow;
      Boolean b;
    case(({},_,_,_,_,_,_))
      then fail();
    case((eqn_coll::rest,m_mt,me_met,ass1,ass2,mapEqnIncRow,1))
      equation
      eqns = mapEqnIncRow[eqn_coll];
    eqn = listGet(eqns,1);
        vars = arrayGet(m_mt,eqn);
    vars_enh = List.removeOnTrue(ass1, isAssignedSaveEnhanced,me_met[eqn]);
        b = solvableLst(vars_enh);
       then Debug.bcallret1(boolNot(b),getpossibleEqnorVar,(rest,m_mt,me_met,ass1,ass2,mapEqnIncRow,1),(eqn_coll,eqns,vars));
    case((var::rest,m_mt,me_met,ass1,ass2,mapEqnIncRow,2))
      equation
        eqn = listGet(arrayGet(m_mt,var),1);
    eqn_enh = List.removeOnTrue(ass2, isAssignedSaveEnhanced,me_met[var]);
    b = solvableLst(eqn_enh);
       then Debug.bcallret1(boolNot(b),getpossibleEqnorVar,(rest,m_mt,me_met,ass1,ass2,mapEqnIncRow,2),(eqn,{var},{eqn}));
    else then fail();
   end matchcontinue;
end getpossibleEqnorVar;
        

protected function markTVars
" marks several tVars in ass1
  author: ptaeuber FHB 2013-10"
  input list<Integer> tVars, ass1In;
  output list<Integer> ass1Out;
algorithm
 ass1Out := matchcontinue(tVars,ass1In)
  local
    Integer tVar;
  list<Integer> rest,ass1;
  case({},_) then ass1In;
  case(tVar::rest,_)
   equation
     ass1 = List.set(ass1In,tVar,listLength(ass1In)*2);
  then markTVars(rest,ass1);
 end matchcontinue;
end markTVars;
  

protected function countMultiples "counts multiple entries in array<list<Integer row(list)-wise.
counter gives the maximum amount of same entries and value gives the corresponding entry.
if only 0s appear in the row, then (0,0).
author: Waurich TUD 2013-01"
  input array<list<Integer>> inArr;
  output list<Integer> counter,numbers,values;
algorithm
  ((counter,numbers,values,_)) := Util.arrayFold(inArr,countMultiples2,({},{},{},1));
end countMultiples;


protected function countMultiples2 " FoldFunc for countMultiples.if entries appear equaly often,
just one is taken.
author: Waurich TUD 2013-01"
  input list<Integer> rowIn;
  input tuple<list<Integer>,list<Integer>,list<Integer>,Integer> valIn;
  output tuple<list<Integer>,list<Integer>,list<Integer>,Integer> valOut;
protected
  list<Integer> counter,values,row,set,num,val,positions,numbers;
  Integer indx,value,number,position;
algorithm
  (counter,_,values,indx) := valIn;
  row := List.removeOnTrue(0,intEq,rowIn);
  set := List.unique(row);
  (val,num) := countMultiples3(row,set,1,{},{});
  positions := maxListInt(num);
  position := listGet(positions,1);
  number := listGet(num,position);
  numbers := selectFromList(val,positions);
  value := listGet(val,position);
  counter := List.set(counter,indx,number);
  values := List.set(values,indx,value);
  valOut := (counter,numbers,values,indx+1);
end countMultiples2;


protected function countMultiples3 " helper function for countMultiples2.
author:Waurich TUD 2013-01"
  input list<Integer> lstIn;
  input list<Integer> set;
  input Integer indx;
  input list<Integer> valIn;
  input list<Integer> numIn;
  output list<Integer> valOut;
  output list<Integer> numOut;
algorithm
  (valOut,numOut) := matchcontinue(lstIn,set,indx,valIn,numIn)
    local
      Integer value,number;
      list<Integer> val,num;
    case(_,{},_,_,_) then ({0},{0});
    case(_,_,_,_,_)
      equation
        true = indx <= listLength(set);
        value = listGet(set,indx);
        number = listLength(lstIn)-listLength(List.removeOnTrue(value,intEq,lstIn));
        (val,num) = countMultiples3(lstIn,set,indx+1,value::valIn,number::numIn);
      then
        (val,num);
    case(_,_,_,_,_)
      equation
        true = indx > listLength(set);
      then
        (valIn,numIn);
  end matchcontinue;
end countMultiples3;


protected function maxListInt
  "function to find maximum Integers in inList and output a list with the indexes.
  author: Waurich TUD 2012-11"
    input list<Integer> inList;
    output list<Integer> outList;
  algorithm
    ((_,_,outList)):= List.fold(inList,maxListInthelp,(1,0,{}));
end maxListInt;


protected function maxListInthelp  "helper function to maxListInt.
author: Waurich TUD 2012-10"
  input Integer value;
  input tuple<Integer,Integer,list<Integer>> inValue;
  output tuple<Integer,Integer,list<Integer>> outValue;
algorithm
  outValue :=
    matchcontinue(value,inValue)
      local
        Integer indx;
        Integer maxValue;
        list<Integer> ilst;
      case(_,(indx,maxValue,ilst))
        equation
          true = value < maxValue;
          then ((indx+1,maxValue,ilst));
      case(_,(indx,maxValue,ilst))
        equation
          true = intEq(value,maxValue);
          then ((indx+1,maxValue,indx::ilst));
      case(_,(indx,maxValue,ilst))
        equation
          true = intGt(value,maxValue);
          then ((indx+1,value,{indx}));
    end matchcontinue;
  end maxListInthelp;


protected function selectFromList" selects Ints from inList by indexes given in selList
author: Waurich TUD 2012-11"
  input List<Integer> inList,selList;
  output List<Integer> outList;
algorithm
  outList := selectFromList_help(1,inList,selList,{});
end selectFromList;


protected function selectFromList_help " implementation for selectFromList.
auhtor: Waurich TUD 2012-11"
  input Integer indx;
  input List<Integer> inList,selList,lst;
  output List<Integer> outList;
algorithm
  outList :=
  matchcontinue(indx,inList,selList,lst)
    local
      Integer actual,length,num;
    case(_,_,_,_)
      equation
        length = listLength(selList);
        num = listGet(selList,indx);
        actual = listGet(inList,num);
        true = indx <= length;
      then
        selectFromList_help(indx+1,inList,selList,actual::lst);
    else then lst;
  end matchcontinue;
end selectFromList_help;


protected function replaceAt "replaces entry at position in given list by given value
  author:Waurich TUD 2012-11"
  input Integer inElement;
  input Integer inPosition;
  input list<Integer> inList;
  output list<Integer> outList;
algorithm
  outList := match(inElement, inPosition, inList)
    local
      Integer e;
      list<Integer> rest;
    case (_,-1, e :: rest) then inList;
    case (_, 0, e :: rest) then inElement :: rest;
    case (_, _, e :: rest)
      equation
        (inPosition >= 1) = true;
        rest = replaceAt(inElement, inPosition - 1, rest);
      then
        e :: rest;
  end match;
end replaceAt;


protected function updateIncidence "deletes given entry from Matrix, starts with row indx.
  applicable on Incidence and on transposed Incidence.
  author: Waurich 2012-11"
  input BackendDAE.IncidenceMatrix mIn;
  input Integer entry;
  input Integer indx;
  output BackendDAE.IncidenceMatrix mOut;
algorithm
  mOut := matchcontinue(mIn,entry,indx)
  local
    Integer size;
    list<Integer> row;
    BackendDAE.IncidenceMatrix m;
  case(_,_,_)
  equation
    size = arrayLength(mIn);
    true = indx>size;
  then mIn;
  case(_,_,_)
    equation
      size = arrayLength(mIn);
      true = indx <= size;
      row = arrayGet(mIn,indx);
      row = List.deleteMember(row,entry);
      m = Util.arrayReplaceAtWithFill(indx,row,row,mIn);
    then updateIncidence(m,entry,indx+1);
  end matchcontinue;
end updateIncidence;


protected function updateIncidence2 "deletes several entries from incidence matrix
  author: ptaeuber 2013-08"
  input BackendDAE.IncidenceMatrix mIn;
  input list<Integer> entries;
  input Integer indx;
  output BackendDAE.IncidenceMatrix mOut;
algorithm
  mOut :=
  matchcontinue(mIn,entries,indx)
    case(_,_,_)
      equation
        true = intLe(indx,listLength(entries));
        mOut = updateIncidence(mIn,listGet(entries,indx),1);
       then
         updateIncidence2(mOut,entries,indx+1);
    else
       then mIn;
   end matchcontinue;
 end updateIncidence2;
 
 
protected function updateIncidenceT2 "deletes several rows from transposed incidence matrix
  author: ptaeuber 2013-08"
  input BackendDAE.IncidenceMatrixT mtIn;
  input list<Integer> rows;
  input Integer indx;
  output BackendDAE.IncidenceMatrixT mtOut;
algorithm
  mtOut :=
  matchcontinue(mtIn,rows,indx)
    case(_,_,_)
      equation
        true = intLe(indx,listLength(rows));
        mtOut = Util.arrayReplaceAtWithFill(listGet(rows,indx),{},{},mtIn);
       then
         updateIncidenceT2(mtOut,rows,indx+1);
    else
       then mtIn;
   end matchcontinue;
 end updateIncidenceT2;


protected function findMostEntries "find rows with most nonzero
elements and put the indexes of the columns with nonzeros in a list.
the first integer gives the max number of nonzero elements found.
author: Waurich TUD 2012-10"
  input list<Integer> row;
  input tuple<Integer,list<list<Integer>>> inValue;
  output tuple<Integer,list<list<Integer>>> outValue;
algorithm
  outValue:=
  matchcontinue(row,inValue)
    local
      Integer length,length1;
      list<list<Integer>> ilst;
    case(_,(length,ilst))
      equation
        length1 = listLength(row);
        true = length1 > length;
      then
        ((length1,{row}));
    case(_,(length,ilst))
      equation
        length1 = listLength(row);
        true = intEq(length1,length);
      then
        ((length1,row::ilst));
    else then inValue;
  end matchcontinue;
end findMostEntries;


protected function findMostEntries2 "find rows with most nonzero
elements and put the indexes of these rows in a list.
author: Waurich TUD 2012-10"
 input list<Integer> row;
 input tuple<Integer,Integer,list<Integer>> inValue;
 output tuple<Integer,Integer,list<Integer>> outValue;
algorithm
  outValue :=
  matchcontinue(row,inValue)
    local
      Integer length,length1,indx;
      list<Integer> ilst;
    case(_,(length,indx,ilst))
      equation
        length1 = listLength(row);
        true = length1 > length;
      then
        ((length1,indx+1,{indx}));
    case(_,(length,indx,ilst))
      equation
        length1 = listLength(row);
        true = intEq(length1,length);
      then
        ((length,indx+1,indx::ilst));
    case(_,(length,indx,ilst))
      equation
        length1 = listLength(row);
        true = length1 < length;
      then
        ((length,indx+1,ilst));
  end matchcontinue;
end findMostEntries2;


protected function findNEntries " find rows with n nonzero elements and
put the indexes of these rows in a list.
author: Waurich TUD 2012-10"
  input list<Integer> row;
  input tuple<Integer,Integer,list<Integer>> inValue;
  output tuple<Integer,Integer,list<Integer>> outValue;
algorithm
  outValue :=
  matchcontinue(row,inValue)
    local
      Integer num,indx,length;
      list<Integer> ilst;
    case(_,(num,indx,ilst))
      equation
      length = listLength(row);
      true = intEq(num,length);
      then ((num,indx+1,indx::ilst));
    case(_,(num,indx,ilst))
      equation
      length = listLength(row);
      true = num <> length;
      then ((num,indx+1,ilst));
  end matchcontinue;
end findNEntries;


end Tearing;
