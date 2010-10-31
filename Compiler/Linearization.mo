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

package Linearization 
" file:	       Linearization.mo
  package:     Linearization
  description: Linearization contains functions to calculate
               
"

public import Absyn;
public import DAE;
public import BackendDAE;

protected import BackendDAEUtil;
protected import BackendDAEOptimize;
protected import BackendDAETransform;
protected import BackendDump;
protected import BackendVariable;
protected import Builtin;
protected import ComponentReference;
protected import Derive;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Debug;
protected import Error;
protected import Util;

public constant String derivativeNamePrefix="$DER";
public constant String partialDerivativeNamePrefix="$pDER";


public function generateLinearMatrix
  // function: generateLinearMatrix
  // author: wbraun
  input BackendDAE.BackendDAE inBackendDAE;
  input DAE.FunctionTree functionTree;
  input list<DAE.ComponentRef> inComRef1; // eqnvars
  input list<DAE.ComponentRef> inComRef2; // vars to differentiate 
  input list<BackendDAE.Var> inAllVar;
  output BackendDAE.BackendDAE outJacobian;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<list<Integer>> outComps1;
algorithm 
  (outJacobian,outV1,outV2,outComps1) :=
    matchcontinue (inBackendDAE,functionTree,inComRef1,inComRef2,inAllVar)
    local
      DAE.DAElist dae;
      BackendDAE.BackendDAE dlow;
      
      list<DAE.ComponentRef> eqvars,diffvars;
      list<BackendDAE.Var> varlst;
      array<Integer> v1,v2,v4,v31;
      list<Integer> v3;
      list<list<Integer>> comps1,comps2;
      list<BackendDAE.Var> derivedVariables;
      list<BackendDAE.Var> derivedVars;
      BackendDAE.BinTree jacElements;
      list<tuple<String,Integer>> varTuple;
      array<list<Integer>> m,mT;
      
      BackendDAE.Variables v,kv,exv;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray e,re,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ev;
      BackendDAE.ExternalObjectClasses eoc;
      list<BackendDAE.Equation> e_lst,re_lst,ie_lst;
      list<DAE.Algorithm> algs;
      list<BackendDAE.MultiDimEquation> ae_lst;
      
      list<String> s;
      String str;
      
      case(dlow as BackendDAE.DAE(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),_,{},_,_)
        equation
      v = BackendDAEUtil.listVar({});    
      then (BackendDAE.DAE(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),listArray({}),listArray({}),{});
      case(dlow as BackendDAE.DAE(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),_,_,{},_)
        equation
      v = BackendDAEUtil.listVar({});    
      then (BackendDAE.DAE(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),listArray({}),listArray({}),{});
      case(dlow as BackendDAE.DAE(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),functionTree,eqvars,diffvars,varlst)
        equation

        // prepare index for Matrix and variables for simpleEquations
        derivedVariables = BackendDAEUtil.varList(v);
        (varTuple) = determineIndices(eqvars, diffvars, 0, varlst);
        BackendDump.printTuple(varTuple);
        jacElements = BackendDAE.emptyBintree;
        (derivedVariables,jacElements) = changeIndices(derivedVariables, varTuple, jacElements);
        v = BackendDAEUtil.listVar(derivedVariables);
        
        // Remove simple Equtaion and 
        e_lst = BackendDAEUtil.equationList(e);
        re_lst = BackendDAEUtil.equationList(re);
        ie_lst = BackendDAEUtil.equationList(ie);
        ae_lst = arrayList(ae);
        algs = arrayList(al);
        (v,kv,e_lst,re_lst,ie_lst,ae_lst,algs,av) = BackendDAEOptimize.removeSimpleEquations(v,kv, e_lst, re_lst, ie_lst, ae_lst, algs, jacElements); 
        e = BackendDAEUtil.listEquation(e_lst);
        re = BackendDAEUtil.listEquation(re_lst);
        ie = BackendDAEUtil.listEquation(ie_lst);
        ae = listArray(ae_lst);
        al = listArray(algs);
        dlow = BackendDAE.DAE(v,kv,exv,av,e,re,ie,ae,al,ev,eoc);
     
        // figure out new matching and the strong components  
        m = BackendDAEUtil.incidenceMatrix(dlow);
        mT = BackendDAEUtil.transposeMatrix(m);
        (v1,v2,dlow,m,mT) = BackendDAETransform.matchingAlgorithm(dlow, m, mT, (BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT(), BackendDAE.KEEP_SIMPLE_EQN()),functionTree);
        Debug.fcall("jacdump2", BackendDump.dumpIncidenceMatrix, m);
        Debug.fcall("jacdump2", BackendDump.dumpIncidenceMatrixT, mT);
        Debug.fcall("jacdump2", BackendDump.dump, dlow);
        Debug.fcall("jacdump2", BackendDump.dumpMatching, v1);
        (comps1) = BackendDAETransform.strongComponents(m, mT, v1, v2);
        Debug.fcall("jacdump2", BackendDump.dumpComponents, comps1);

        // figure out wich comps are needed to evaluate all derivedVariables  
        derivedVariables = BackendDAEUtil.varList(v);
        (derivedVars,_) = Util.listSplitOnTrue(derivedVariables,checkIndex);
        v3 = getVarIndex(derivedVars,derivedVariables);
        v31 = Util.arraySelect(v1,v3);
        v3 = arrayList(v31);
        s = Util.listMap(v3,intString);
        str = Util.stringDelimitList(s,",");
        Debug.fcall("markblocks",print,"Vars Indecies : " +& str +& "\n");
        v4 = fill(0,listLength(comps1));
        v4 = MarkArray(v3,comps1,v4);
        (comps1,_) = splitBlocks2(comps1,v4,1);
        
        Debug.fcall("jacdump2", BackendDump.dumpComponents, comps1);
        
        then (dlow,v1,v2,comps1);
    case(_, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.generateLinearMatrix failed"});
    then fail();          
   end matchcontinue;
end generateLinearMatrix;         

protected function splitBlocks2 
//function: splitBlocks2
//author: wbraun 
  input list<list<Integer>> inIntegerLstLst;
  input Integer[:] inIntegerArray;
  input Integer inPos;
  output list<list<Integer>> outIntegerLstLst1;
  output list<list<Integer>> outIntegerLstLst2;
algorithm
  (outIntegerLstLst1,outIntegerLstLst2):=
  matchcontinue (inIntegerLstLst,inIntegerArray,inPos)
    local
      list<list<BackendDAE.Value>> states,output_,blocks;
      list<BackendDAE.Value> block_;
      array<BackendDAE.Value> arr;
      BackendDAE.Value i;
    case ({},_,_) then ({},{});
    case ((block_ :: blocks),arr,i)
      equation
        1 = arr[i];
        (states,output_) = splitBlocks2(blocks, arr,i+1);
      then
        ((block_ :: states),output_);
    case ((block_ :: blocks),arr,i)
      equation
        (states,output_) = splitBlocks2(blocks, arr,i+1);
      then
        (states,(block_ :: output_));
    case ((block_ :: blocks),arr,i)
      equation
        (states,output_) = splitBlocks2(blocks, arr,i+1);
      then
        (states,(block_ :: output_));        
  end matchcontinue;
end splitBlocks2;

protected function MarkArray
  // function : MarkArray
  // author : wbraun
  input list<Integer> inVars1;
  input list<list<Integer>> inVars2;
  input Integer[:] inInt;
  output Integer[:] outJacobian;
algorithm
  outJacobian := matchcontinue(inVars1,inVars2,inInt)
    local
      list<Integer> rest;
      list<list<Integer>> vars;
      Integer var;
      list<Integer> intlst,ilst2;
      Integer i;
      Integer[:] arr,arr1;
      list<String> s,s1;
      String str;
    case({},_,arr) then arr;      
    case(var::rest,vars,arr)
      equation
        i = Util.listlistPosition(var,vars);
        Debug.fcall("markblocks",print,"Var " +& intString(var) +& " at pos : " +& intString(i) +& "\n");
        arr1 = fill(1,i+1);
        arr = Util.arrayCopy(arr1,arr);
        arr = MarkArray(rest,vars,arr);
        s = Util.listMap(arrayList(arr),intString);
        str = stringAppendList(s);
        Debug.fcall("markblocks",print,str);
        Debug.fcall("markblocks",print,"\n");
      then arr;        
     case(_,_,_)
       equation
        Debug.fcall("failtrace",print,"Linearization.MarkArray failed\n");
       then fail();
  end matchcontinue;
end MarkArray; 

protected function getVarIndex
  // function : getVarIndex
  // author : wbraun
  input list<BackendDAE.Var> inVars1;
  input list<BackendDAE.Var> inVars2;
  output list<Integer> outJacobian;
algorithm
  outJacobian := matchcontinue(inVars1, inVars2)
    local
      list<BackendDAE.Var> vars,rest;
      BackendDAE.Var var;
      list<Integer> intlst;
      Integer i;
    case({},_) then {};      
    case(var::rest,vars)
      equation
        i = Util.listPosition(var,vars)+1;
        intlst = getVarIndex(rest,vars);
      then (i::intlst);
    case(var::rest,_)
      equation
        Debug.fcall("failtrace",print,"Linearization.getVarIndex failed\n");
      then fail();
  end matchcontinue;
end getVarIndex;  

protected function checkIndex "function: checkIndex
  author: wbraun

  check if the index is greater 0
"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local BackendDAE.Value i;
    case (BackendDAE.VAR(index = i)) then i >= 0;
  end matchcontinue;
end checkIndex;

public function generateSymbolicJacobian
  // function: generateSymbolicJacobian
  // author: lochel
  input BackendDAE.BackendDAE inBackendDAE;
  input DAE.FunctionTree functions;
  input list<DAE.ComponentRef> inVars;
  input list<BackendDAE.Var> stateVars;
  input list<BackendDAE.Var> inputVars;
  input list<BackendDAE.Var> paramVars;
  output BackendDAE.BackendDAE outJacobian;
algorithm
  outJacobian := matchcontinue(inBackendDAE, functions, inVars, stateVars, inputVars, paramVars)
    local
      BackendDAE.BackendDAE daeLow;
      DAE.DAElist daeList;
      list<DAE.ComponentRef> vars;
      BackendDAE.BackendDAE jacobian;
      
      // DAE
      BackendDAE.Variables orderedVars, jacOrderedVars;
      BackendDAE.Variables knownVars, jacKnownVars;
      BackendDAE.Variables externalObjects, jacExternalObjects;
      BackendDAE.AliasVariables aliasVars, jacAliasVars;
      BackendDAE.EquationArray orderedEqs, jacOrderedEqs;
      BackendDAE.EquationArray removedEqs, jacRemovedEqs;
      BackendDAE.EquationArray initialEqs, jacInitialEqs;
      array<BackendDAE.MultiDimEquation> arrayEqs, jacArrayEqs;
      array<DAE.Algorithm> algorithms, jacAlgorithms;
      BackendDAE.EventInfo eventInfo, jacEventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses, jacExtObjClasses;
      // end DAE
      
      list<BackendDAE.Var> allVars, inputVars, paramVars, stateVars, derivedVariables;
      list<BackendDAE.Equation> solvedEquations, derivedEquations, derivedEquations2;
      list<DAE.Algorithm> derivedAlgorithms;
      list<tuple<Integer, DAE.ComponentRef>> derivedAlgorithmsLookUp;
      
    case(_, _, {}, _, _,_) equation
      jacOrderedVars = BackendDAEUtil.emptyVars();
      jacKnownVars = BackendDAEUtil.emptyVars();
      jacExternalObjects = BackendDAEUtil.emptyVars();
      jacAliasVars =  BackendDAEUtil.emptyAliasVariables();
      jacOrderedEqs = BackendDAEUtil.listEquation({});
      jacRemovedEqs = BackendDAEUtil.listEquation({});
      jacInitialEqs = BackendDAEUtil.listEquation({});
      jacArrayEqs = listArray({});
      jacAlgorithms = listArray({});
      jacEventInfo = BackendDAE.EVENT_INFO({},{});
      jacExtObjClasses = {};
      
      jacobian = BackendDAE.DAE(jacOrderedVars, jacKnownVars, jacExternalObjects, jacAliasVars, jacOrderedEqs, jacRemovedEqs, jacInitialEqs, jacArrayEqs, jacAlgorithms, jacEventInfo, jacExtObjClasses);
    then jacobian;
      
    case(daeLow as BackendDAE.DAE(orderedVars=orderedVars, knownVars=knownVars, externalObjects=externalObjects, aliasVars=aliasVars, orderedEqs=orderedEqs, removedEqs=removedEqs, initialEqs=initialEqs, arrayEqs=arrayEqs, algorithms=algorithms, eventInfo=eventInfo, extObjClasses=extObjClasses), functions, vars, stateVars, inputVars, paramVars) equation
      Debug.fcall("jacdump", print, "\n+++++++++++++++++++++ daeLow-dump:    input +++++++++++++++++++++\n");
      Debug.fcall("jacdump", BackendDump.dump, daeLow);
      Debug.fcall("jacdump", print, "##################### daeLow-dump:    input #####################\n\n");
      
      allVars = listAppend(listAppend(stateVars, inputVars), paramVars);
      
      derivedVariables = generateJacobianVars(BackendDAEUtil.varList(orderedVars), vars, stateVars);
      (derivedAlgorithms, derivedAlgorithmsLookUp) = deriveAllAlg(arrayList(algorithms), vars, functions, 0);
      derivedEquations = deriveAll(BackendDAEUtil.equationList(orderedEqs), vars, functions, inputVars, paramVars, stateVars, derivedAlgorithmsLookUp);
      
      jacOrderedVars = BackendDAEUtil.listVar(derivedVariables);
      jacKnownVars = BackendDAEUtil.emptyVars();
      jacExternalObjects = BackendDAEUtil.emptyVars();
      jacAliasVars =  BackendDAEUtil.emptyAliasVariables();
      jacOrderedEqs = BackendDAEUtil.listEquation(derivedEquations);
      jacRemovedEqs = BackendDAEUtil.listEquation({});
      jacInitialEqs = BackendDAEUtil.listEquation({});
      jacArrayEqs = listArray({});
      jacAlgorithms = listArray(derivedAlgorithms);
      jacEventInfo = BackendDAE.EVENT_INFO({},{});
      jacExtObjClasses = {};
      
      jacobian = BackendDAE.DAE(jacOrderedVars, jacKnownVars, jacExternalObjects, jacAliasVars, jacOrderedEqs, jacRemovedEqs, jacInitialEqs, jacArrayEqs, jacAlgorithms, jacEventInfo, jacExtObjClasses);
      
      Debug.fcall("jacdump", print, "\n+++++++++++++++++++++ daeLow-dump: jacobian +++++++++++++++++++++\n");
      Debug.fcall("jacdump", BackendDump.dump, jacobian);
      Debug.fcall("jacdump", print, "##################### daeLow-dump: jacobian #####################\n");
    then jacobian;  
      
    case(_, _, _, _, _,_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAE.generateSymbolicJacobian failed"});
    then fail();
  end matchcontinue;
end generateSymbolicJacobian;

protected function deriveAllAlg
  // function: deriveAllAlg
  // author: lochel
  input list<DAE.Algorithm> inAlgorithms;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input Integer inAlgIndex; // 0
  output list<DAE.Algorithm> outDerivedAlgorithms;
  output list<tuple<Integer, DAE.ComponentRef>> outDerivedAlgorithmsLookUp;
algorithm
  (outDerivedAlgorithms, outDerivedAlgorithmsLookUp) := matchcontinue(inAlgorithms, inVars, inFunctions, inAlgIndex)
    local
      DAE.Algorithm currAlg;
      list<DAE.Algorithm> restAlgs;
      list<DAE.ComponentRef> vars;
      DAE.FunctionTree functions;
      Integer algIndex;
      list<DAE.Algorithm> rAlgs1, rAlgs2;
      list<tuple<Integer, DAE.ComponentRef>> rLookUp1, rLookUp2;
    case({}, _, _, _) then ({}, {});
      
    case(currAlg::restAlgs, vars, functions, algIndex)
    equation
      (rAlgs1, rLookUp1) = deriveOneAlg(currAlg, vars, functions, algIndex);
      (rAlgs2, rLookUp2) = deriveAllAlg(restAlgs, vars, functions, algIndex+1);
      rAlgs1 = listAppend(rAlgs1, rAlgs2);
      rLookUp1 = listAppend(rLookUp1, rLookUp2);
    then (rAlgs1, rLookUp1);
  end matchcontinue;
end deriveAllAlg;

protected function deriveOneAlg
  // function: deriveOneAlg
  // author: lochel
  input DAE.Algorithm inAlgorithm;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input Integer inAlgIndex;
  output list<DAE.Algorithm> outDerivedAlgorithms;
  output list<tuple<Integer, DAE.ComponentRef>> outDerivedAlgorithmsLookUp;
algorithm
  (outDerivedAlgorithms, outDerivedAlgorithmsLookUp) := matchcontinue(inAlgorithm, inVars, inFunctions, inAlgIndex)
    local
      DAE.Algorithm currAlg;
      list<DAE.Statement> statementLst, derivedStatementLst;
      DAE.ComponentRef currVar;
      list<DAE.ComponentRef> restVars;
      DAE.FunctionTree functions;
      Integer algIndex;
      list<DAE.Algorithm> rAlgs1, rAlgs2;
      list<tuple<Integer, DAE.ComponentRef>> rLookUp1, rLookUp2;
    case(_, {}, _, _) then ({}, {});
      
    case(currAlg as DAE.ALGORITHM_STMTS(statementLst=statementLst), currVar::restVars, functions, algIndex)equation
      derivedStatementLst = differentiateAlgorithmStatements(statementLst, currVar, functions);
      rAlgs1 = {DAE.ALGORITHM_STMTS(derivedStatementLst)};
      rLookUp1 = {(algIndex, currVar)};
      (rAlgs2, rLookUp2) = deriveOneAlg(currAlg, restVars, functions, algIndex);
      rAlgs1 = listAppend(rAlgs1, rAlgs2);
      rLookUp1 = listAppend(rLookUp1, rLookUp2);
    then (rAlgs1, rLookUp1);
  end matchcontinue;
end deriveOneAlg;

protected function generateJacobianVars
  // function: generateJacobianVars
  // author: lochel
  input list<BackendDAE.Var> inVars1;
  input list<DAE.ComponentRef> inVars2;
  input list<BackendDAE.Var> inStateVars;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := matchcontinue(inVars1, inVars2, inStateVars)
  local
    BackendDAE.Var currVar;
    list<BackendDAE.Var> restVar, r1, r2, r, stateVars;
    list<DAE.ComponentRef> vars2;
    
    case({}, _, _)
    then {}; 
      
    case(currVar::restVar, vars2, stateVars) equation
      r1 = generateJacobianVars2(currVar, vars2, stateVars);
      r2 = generateJacobianVars(restVar, vars2, stateVars);
      r = listAppend(r1, r2);
    then r;
      
    case(_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.generateJacobianVars failed"});
    then fail();
  end matchcontinue;
end generateJacobianVars;

protected function generateJacobianVars2
  // function: generateJacobianVars2
  // author: lochel
  input BackendDAE.Var inVar1;
  input list<DAE.ComponentRef> inVars2;
  input list<BackendDAE.Var> inStateVars;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := matchcontinue(inVar1, inVars2, inStateVars)
  local
    BackendDAE.Var var, r1;
    DAE.ComponentRef currVar, cref, derivedCref;
    list<DAE.ComponentRef> restVar;
    list<BackendDAE.Var> r2;
    list<BackendDAE.Var> stateVars;
    
    case(_, {}, _)
    then {};
    
    case(var as BackendDAE.VAR(varName=cref), currVar::restVar, stateVars) equation
      derivedCref = differentiateVarWithRespectToX(cref, currVar, stateVars);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.VARIABLE(), DAE.BIDIR(), BackendDAE.REAL(), NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      r2 = generateJacobianVars2(var, restVar, stateVars);
    then r1::r2;
      
    case(_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.generateJacobianVars2 failed"});
    then fail();
  end matchcontinue;
end generateJacobianVars2;

protected function deriveAll
  // function: deriveAll
  // author: lochel
  input list<BackendDAE.Equation> inEquations;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquations, inVars, inFunctions, inInputVars, inParamVars, inStateVars, inAlgorithmsLookUp)
    local
      BackendDAE.Equation currEquation;
      list<BackendDAE.Equation> restEquations;
      DAE.FunctionTree functions;
      list<DAE.ComponentRef> vars;
      list<BackendDAE.Equation> currDerivedEquations, restDerivedEquations, derivedEquations;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      list<tuple<Integer, DAE.ComponentRef>> algorithmsLookUp;
    case({}, _, _, _, _, _, _) then {};
      
    case(currEquation::restEquations, vars, functions, inputVars, paramVars, stateVars, algorithmsLookUp) equation
      Debug.fcall("jacdumptime", BackendDump.dumpEqns, {currEquation});
      currDerivedEquations = deriveOne(currEquation, vars, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      restDerivedEquations = deriveAll(restEquations, vars, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      derivedEquations = listAppend(currDerivedEquations, restDerivedEquations);
    then derivedEquations;
      
    case(_, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.deriveAll failed"});
    then fail();
  end matchcontinue;
end deriveAll;

protected function deriveOne
  // function: deriveOne
  // author: lochel
  input BackendDAE.Equation inEquation;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquation, inVars, inFunctions, inInputVars, inParamVars, inStateVars, inAlgorithmsLookUp)
    local
      BackendDAE.Equation currEquation;
      list<DAE.Algorithm> algorithms;
      DAE.FunctionTree functions;
      DAE.ComponentRef currVar;
      list<DAE.ComponentRef> restVars;
      Integer algNum;
      
      list<BackendDAE.Var> currDerivedVariables, restDerivedVariables, derivedVariables;
      list<BackendDAE.Equation> currDerivedEquations, restDerivedEquations, derivedEquations;
      list<DAE.Algorithm> currDerivedAlgorithms, restDerivedAlgorithms, derivedAlgorithms;
      
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      list<tuple<Integer, DAE.ComponentRef>> algorithmsLookUp;
      Integer i; 
    case(_, {}, _, _, _, _, _) then {};
      
    case(currEquation, currVar::restVars, functions, inputVars, paramVars, stateVars, algorithmsLookUp) equation
      currDerivedEquations = derive(currEquation, currVar, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      restDerivedEquations = deriveOne(currEquation, restVars, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      
      derivedEquations = listAppend(currDerivedEquations, restDerivedEquations);
    then derivedEquations;
      
    case(_, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.deriveOne failed"});
    then fail();
  end matchcontinue;
end deriveOne;

protected function derive
  // function: derive
  // author: lochel
  input BackendDAE.Equation inEquation;
  input DAE.ComponentRef inVar;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquation, inVar, inFunctions, inInputVars, inParamVars, inStateVars, inAlgorithmsLookUp)
    local
      BackendDAE.Equation currEquation;
      list<DAE.Algorithm> algorithms;
      DAE.FunctionTree functions;
      DAE.ComponentRef var, cref, cref_;
      
      BackendDAE.Var currDerivedVariable;
      BackendDAE.Equation currDerivedEquation;
      DAE.Algorithm currDerivedAlgorithm;
      
      DAE.Exp lhs, rhs, lhs_, rhs_, exp, exp_;
      DAE.ElementSource source;
      
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      Integer index;
      list<DAE.Exp> in_, derivedIn_,out, derivedOut;
      DAE.Algorithm singleAlgorithm, derivedAlgorithm;
      list<tuple<Integer, DAE.ComponentRef>> algorithmsLookUp;
      Integer newAlgIndex;
    case(currEquation as BackendDAE.EQUATION(exp=lhs, scalar=rhs, source=source), var, functions, inputVars, paramVars, stateVars, _) equation
      lhs_ = differentiateWithRespectToX(lhs, var, functions, inputVars, paramVars, stateVars);
      rhs_ = differentiateWithRespectToX(rhs, var, functions, inputVars, paramVars, stateVars);
    then {BackendDAE.EQUATION(lhs_, rhs_, source)};
      
    case(currEquation as BackendDAE.ARRAY_EQUATION(_, _, _), var, functions, inputVars, paramVars, stateVars, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.derive failed: ARRAY_EQUATION-case"});
    then fail();
      
    case(currEquation as BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=exp, source=source), var, functions, inputVars, paramVars, stateVars, _) equation
      cref_ = differentiateVarWithRespectToX(cref, var, stateVars);
      exp_ = differentiateWithRespectToX(exp, var, functions, inputVars, paramVars, stateVars);
    then {BackendDAE.SOLVED_EQUATION(cref_, exp_, source)};
      
    case(currEquation as BackendDAE.RESIDUAL_EQUATION(exp=exp, source=source), var, functions, inputVars, paramVars, stateVars, _) equation
      exp_ = differentiateWithRespectToX(exp, var, functions, inputVars, paramVars, stateVars);
    then {BackendDAE.RESIDUAL_EQUATION(exp_, source)};
      
    case(currEquation as BackendDAE.ALGORITHM(index=index, in_=in_, out=out, source=source), var, functions, inputVars, paramVars, stateVars, algorithmsLookUp)
    equation
      derivedIn_ = Util.listMap5(in_, differentiateWithRespectToX, var, functions, {}, {}, {});
      derivedIn_ = listAppend(in_, derivedIn_);
      derivedOut = Util.listMap5(out, differentiateWithRespectToX, var, functions, {}, {}, {});
        
      newAlgIndex = Util.listPosition((index, var), algorithmsLookUp);
    then {BackendDAE.ALGORITHM(newAlgIndex, derivedIn_, derivedOut, source)};
        
    case(currEquation as BackendDAE.WHEN_EQUATION(_, _), var, functions, inputVars, paramVars, stateVars, _) equation
      Debug.fcall("jacdump",print,"Linearization.derive: WHEN_EQUATION has been removed");
    then {};
      
    case(currEquation as BackendDAE.COMPLEX_EQUATION(_, _, _, _), var, functions, inputVars, paramVars, stateVars, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.derive failed: COMPLEX_EQUATION-case"});
    then fail();
      
    case(_, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.derive failed"});
    then fail();
  end matchcontinue;
end derive;

protected function differentiateVarWithRespectToX
  // function: differentiateVarWithRespectToX
  // author: lochel
  input DAE.ComponentRef inCref;
  input DAE.ComponentRef inX;
  input list<BackendDAE.Var> inStateVars;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inX, inStateVars)
    local
      DAE.ComponentRef cref, x;
      String id,str;
      DAE.ExpType idType;
      list<DAE.Subscript> sLst;
      list<BackendDAE.Var> stateVars;
      BackendDAE.Var v1;
    
    // d(state)/d(x)
    case(cref, x, stateVars) equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(stateVars));
      true = BackendVariable.isStateVar(v1);
      cref = ComponentReference.crefPrefixDer(cref);
      id = ComponentReference.printComponentRefStr(cref) +& BackendDAE.partialDerivativeNamePrefix +& ComponentReference.printComponentRefStr(x);
      id = Util.stringReplaceChar(id, ".", "$P");
      id = Util.stringReplaceChar(id, "[", "$pL");
      id = Util.stringReplaceChar(id, "]", "$pR");
    then ComponentReference.makeCrefIdent(id, DAE.ET_REAL(), {});
    
    // d(no state)/d(x)
    case(cref, x, _) equation
      id = ComponentReference.printComponentRefStr(cref) +& BackendDAE.partialDerivativeNamePrefix +& ComponentReference.printComponentRefStr(x);
      id = Util.stringReplaceChar(id, ".", "$P");
      id = Util.stringReplaceChar(id, "[", "$pL");
      id = Util.stringReplaceChar(id, "]", "$pR");
    then ComponentReference.makeCrefIdent(id, DAE.ET_REAL(), {});
      
    case(cref, _, _) local
      equation
        str = "Linearization.differentiateVarWithRespectToX failed: " +&  ComponentReference.printComponentRefStr(cref);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end differentiateVarWithRespectToX;

protected function differentiateWithRespectToX
  // function: differentiateWithRespectToX
  // author: lochel
  
  input DAE.Exp inExp;
  input DAE.ComponentRef inX;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp, inX, inFunctions, inInputVars, inParamVars, inStateVars)
    local
      DAE.ComponentRef x, cref, cref_;
      DAE.FunctionTree functions;
      DAE.Exp e1, e1_, e2, e2_, e;
      DAE.ExpType et;
      DAE.Operator op;
      
      
      list<DAE.ComponentRef> diff_crefs;
      Absyn.Path fname,derFname;
      
      list<DAE.Exp> expList1, expList2;
      Boolean tuple_, builtin;
      DAE.InlineType inlineType;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      String str;
      list<tuple<Integer,DAE.derivativeCond>> conditions;
      DAE.Type tp;
      Integer nArgs;
      BackendDAE.Var v1, v2;
    case(DAE.ICONST(_), _, _, _, _, _)
    then DAE.ICONST(0);
      
    case(DAE.RCONST(_), _, _, _, _, _)
    then DAE.RCONST(0.0);
      
    case (DAE.CAST(ty=et, exp=e1), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.CAST(et, e1_);
      
    // d(x)/d(x)
    case(DAE.CREF(componentRef=cref), x, functions, inputVars, paramVars, stateVars) equation
      true = ComponentReference.crefEqual(cref, x);
    then DAE.RCONST(1.0);
      
    // d(time)/d(x)
    case(DAE.CREF(componentRef=(cref as DAE.CREF_IDENT(ident = "time",subscriptLst = {}))), x, functions, inputVars, paramVars, stateVars)
    then DAE.RCONST(0.0);
    
    // d(state1)/d(state2) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars)
    equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(stateVars));
      ({v2}, _) = BackendVariable.getVar(x, BackendDAEUtil.listVar(stateVars));
    then DAE.RCONST(0.0);
      
    // d(state)/d(input) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars)
    equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(stateVars));
      ({v2}, _) = BackendVariable.getVar(x, BackendDAEUtil.listVar(inputVars));
    then DAE.RCONST(0.0);
      
    // d(input)/d(state) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars)
    equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(inputVars));
      ({v2}, _) = BackendVariable.getVar(x, BackendDAEUtil.listVar(stateVars));
    then DAE.RCONST(0.0);
      
    // d(parameter1)/d(parameter2) != 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars)
    equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(paramVars));
      ({v2}, _) = BackendVariable.getVar(x, BackendDAEUtil.listVar(paramVars));
      cref_ = differentiateVarWithRespectToX(cref, x, stateVars);
    then DAE.CREF(cref_, et);
      
    // d(parameter)/d(no parameter) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars)
    equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(paramVars));
    then DAE.RCONST(0.0);
      
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars) equation
      cref_ = differentiateVarWithRespectToX(cref, x, stateVars);
    then DAE.CREF(cref_, et);
      
    // a + b
    case(DAE.BINARY(exp1=e1, operator=DAE.ADD(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.ADD(et), e2_);
      
    // a - b
    case(DAE.BINARY(exp1=e1, operator=DAE.SUB(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.SUB(et), e2_);
      
    // a * b
    case(DAE.BINARY(exp1=e1, operator=DAE.MUL(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
      e = DAE.BINARY(DAE.BINARY(e1_, DAE.MUL(et), e2), DAE.ADD(et), DAE.BINARY(e1, DAE.MUL(et), e2_));
      e = ExpressionSimplify.simplify(e);
    then e;
      
    // a / b
    case(DAE.BINARY(exp1=e1, operator=DAE.DIV(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
      e = DAE.BINARY(DAE.BINARY(DAE.BINARY(e1_, DAE.MUL(et), e2), DAE.SUB(et), DAE.BINARY(e1, DAE.MUL(et), e2_)), DAE.DIV(et), DAE.BINARY(e2, DAE.MUL(et), e2));
      e = ExpressionSimplify.simplify(e);
    then e;
    
    // a(x)^b
    case(e as DAE.BINARY(exp1=e1, operator=DAE.POW(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      true = Expression.isConst(e2);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e = DAE.BINARY(e1_, DAE.MUL(et), DAE.BINARY(e2, DAE.MUL(et), DAE.BINARY(e1, DAE.POW(et), DAE.BINARY(e2, DAE.SUB(et), DAE.RCONST(1.0)))));
    then e;
    
    // der(x)
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars)
      equation
      Builtin.isDer(fname);
      cref = Expression.expCref(e1);
      cref = ComponentReference.crefPrefixDer(cref);
      //str = derivativeNamePrefix +& ExpressionDump.printExpStr(e1);
      //cref = ComponentReference.makeCrefIdent(str, DAE.ET_REAL(),{});
      e1_ = differentiateWithRespectToX(Expression.crefExp(cref), x, functions, inputVars, paramVars, stateVars);
    then e1_;
    
    // -exp
    case(DAE.UNARY(operator=op, exp=e1), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.UNARY(op, e1_);
      
    // sin(x)
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isSin(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("cos"),{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE()));

    // cos(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isCos(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()), DAE.BINARY(e1_,DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("sin"),{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE())));

    // ln(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isLog(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.DIV(DAE.ET_REAL()), e1);

    // log10(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isLog10(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.DIV(DAE.ET_REAL()), DAE.BINARY(e1, DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("log"),{DAE.RCONST(10.0)},false,true,DAE.ET_REAL(),DAE.NO_INLINE())));

    // exp(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isExp(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_,DAE.MUL(DAE.ET_REAL()), DAE.CALL(fname,{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE()));
  
    // sqrt(x)
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars)
      equation
        Builtin.isSqrt(fname) "sqrt(x) => 1(2  sqrt(x))  der(x)" ;
        e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE()))),DAE.MUL(DAE.ET_REAL()),e1_);
        
    // abs(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isAbs(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.IFEXP(DAE.RELATION(e1_,DAE.GREATER(DAE.ET_REAL()),DAE.RCONST(0.0)), e1_, DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),e1_));
      
      // differentiate if-expressions
    case (DAE.IFEXP(expCond=e, expThen=e1, expElse=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
    then DAE.IFEXP(e, e1_, e2_);

    // extern functions (analytical)
    case (e as DAE.CALL(path=fname, expLst=expList1, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), x, functions, inputVars, paramVars, stateVars)
    equation
        nArgs = listLength(expList1);
        (DAE.FUNCTION_DER_MAPPER(derivativeFunction=derFname,conditionRefs=conditions), tp) = Derive.getFunctionMapper(fname, functions);
        expList2 = deriveExpListwrtstate(expList1, nArgs, conditions, x, functions, inputVars, paramVars, stateVars);
        e1 = partialAnalyticalDifferentiation(expList1, expList2, e, derFname, listLength(expList2));  
    then e1;

    // extern functions (numeric)
    case (e as DAE.CALL(path=fname, expLst=expList1, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), x, functions, inputVars, paramVars, stateVars)
    equation
        nArgs = listLength(expList1);
        expList2 = deriveExpListwrtstate2(expList1, nArgs, x, functions, inputVars, paramVars, stateVars);
        e1 = partialNumericalDifferentiation(expList1, expList2, x, e);  
    then e1;
           
    case(e, x, _, _, _, _)
      equation
        str = "differentiateWithRespectToX failed: " +& ExpressionDump.printExpStr(e) +& " | " +& ComponentReference.printComponentRefStr(x);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end matchcontinue;
end differentiateWithRespectToX;

protected function deriveExpListwrtstate
  input list<DAE.Exp> inExpList;
  input Integer inLengthExpList;
  input list<tuple<Integer,DAE.derivativeCond>> inConditios;
  input DAE.ComponentRef inState;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  output list<DAE.Exp> outExpList;
algorithm
  outExpList := matchcontinue(inExpList, inLengthExpList, inConditios, inState, inFunctions, inInputVars, inParamVars, inStateVars)
    local
      DAE.ComponentRef x;
      DAE.Exp curr,r1;
      list<DAE.Exp> rest, r2;
      DAE.FunctionTree functions;
      Integer LengthExpList,n, argnum;
      list<tuple<Integer,DAE.derivativeCond>> conditions;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
    case ({},_,_,_,_,_,_,_) then ({});
    case (curr::rest, LengthExpList, conditions, x, functions,inputVars, paramVars, stateVars) equation
      n = listLength(rest);
      argnum = LengthExpList - n;
      true = checkcondition(conditions,argnum); 
      r1 = differentiateWithRespectToX(curr, x, functions, inputVars, paramVars, stateVars); 
      r2 = deriveExpListwrtstate(rest,LengthExpList,conditions, x, functions,inputVars, paramVars, stateVars);
    then (r1::r2);
    case (curr::rest, LengthExpList, conditions, x, functions,inputVars, paramVars, stateVars) equation
      r2 = deriveExpListwrtstate(rest,LengthExpList,conditions, x, functions,inputVars, paramVars, stateVars);
    then r2;  
  end matchcontinue;
end deriveExpListwrtstate;

protected function deriveExpListwrtstate2
  input list<DAE.Exp> inExpList;
  input Integer inLengthExpList;
  input DAE.ComponentRef inState;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  output list<DAE.Exp> outExpList;
algorithm
  outExpList := matchcontinue(inExpList, inLengthExpList, inState, inFunctions, inInputVars, inParamVars, inStateVars)
    local
      DAE.ComponentRef x;
      DAE.Exp curr,r1;
      list<DAE.Exp> rest, r2;
      DAE.FunctionTree functions;
      Integer LengthExpList,n, argnum;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;    
    case ({}, _, _, _, _, _, _) then ({});
    case (curr::rest, LengthExpList, x, functions, inputVars, paramVars, stateVars) equation
      n = listLength(rest);
      argnum = LengthExpList - n;
      r1 = differentiateWithRespectToX(curr, x, functions, inputVars, paramVars, stateVars); 
      r2 = deriveExpListwrtstate2(rest,LengthExpList, x, functions, inputVars, paramVars, stateVars);
    then (r1::r2);
  end matchcontinue;
end deriveExpListwrtstate2;

protected function checkcondition
  input list<tuple<Integer,DAE.derivativeCond>> inConditions;
  input Integer inArgs;
  output Boolean outBool;
algorithm
  outBool := matchcontinue(inConditions, inArgs)
    local
      list<tuple<Integer,DAE.derivativeCond>> rest;
      Integer i,nArgs;
      DAE.derivativeCond cond;
      Boolean res;
      DAE.Exp e1;
    case ({},_) then true;
    case((i,cond)::rest,nArgs) 
      equation
        equality(i = nArgs);
        cond = DAE.ZERO_DERIVATIVE();
      then false;
      case((i,cond)::rest,nArgs) 
       equation
         equality(i = nArgs);
         DAE.NO_DERIVATIVE(_) = cond;
       then false;
    case((i,cond)::rest,nArgs) 
      equation
        res = checkcondition(rest,nArgs);
      then res;           
  end matchcontinue;
end checkcondition;

protected function partialAnalyticalDifferentiation
  input list<DAE.Exp> varExpList;
  input list<DAE.Exp> derVarExpList;
  input DAE.Exp functionCall;
  input Absyn.Path derFname;
  input Integer nDerArgs;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(varExpList, derVarExpList, functionCall, derFname, nDerArgs)
    local
      DAE.Exp e, currVar, currDerVar, derFun, delta, absCurr;
      list<DAE.Exp> restVar, restDerVar, varExpList1Added, varExpListTotal;
      DAE.ExpType et;
      Boolean tuple_, builtin;
      DAE.InlineType inlineType;
      DAE.FunctionTree functions;
      Integer nArgs1, nArgs2;
    case ( _, {}, _, _, _) then (DAE.RCONST(0.0));
    case (currVar::restVar, currDerVar::restDerVar, functionCall as DAE.CALL(expLst=varExpListTotal, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), derFname, nDerArgs)
      equation
        e = partialAnalyticalDifferentiation(restVar, restDerVar, functionCall, derFname, nDerArgs);
        nArgs1 = listLength(varExpListTotal);
        nArgs2 = listLength(restDerVar);
        varExpList1Added = Util.listReplaceAtWithFill(DAE.RCONST(0.0),nArgs1 + nDerArgs - 1, varExpListTotal ,DAE.RCONST(0.0));
        varExpList1Added = Util.listReplaceAtWithFill(DAE.RCONST(1.0),nArgs1 + nDerArgs - nArgs2 + 1, varExpList1Added,DAE.RCONST(0.0));
        derFun = DAE.CALL(derFname, varExpList1Added, tuple_, builtin, et, inlineType);
      then DAE.BINARY(e, DAE.ADD(DAE.ET_REAL()), DAE.BINARY(derFun, DAE.MUL(DAE.ET_REAL()), currDerVar)); 
  end matchcontinue;
end partialAnalyticalDifferentiation;

protected function partialNumericalDifferentiation
  input list<DAE.Exp> varExpList;
  input list<DAE.Exp> derVarExpList;
  input DAE.ComponentRef inState;
  input DAE.Exp functionCall;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(varExpList, derVarExpList, inState, functionCall)
    local
      DAE.Exp e, currVar, currDerVar, derFun, delta, absCurr;
      list<DAE.Exp> restVar, restDerVar, varExpListHAdded, varExpListTotal;
      DAE.ExpType et;
      Absyn.Path fname;
      Boolean tuple_, builtin;
      DAE.InlineType inlineType;
      DAE.FunctionTree functions;
      Integer nArgs1, nArgs2;
    case ({}, _, _, _) then (DAE.RCONST(0.0));
    case (currVar::restVar, currDerVar::restDerVar, inState, functionCall as DAE.CALL(path=fname, expLst=varExpListTotal, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType))
      equation
        e = partialNumericalDifferentiation(restVar, restDerVar, inState, functionCall);
        absCurr = DAE.LBINARY(DAE.RELATION(currVar,DAE.GREATER(DAE.ET_REAL()),DAE.RCONST(1e-8)),DAE.OR(),DAE.RELATION(currVar,DAE.LESS(DAE.ET_REAL()),DAE.RCONST(-1e-8)));
        delta = DAE.IFEXP( absCurr, DAE.BINARY(currVar,DAE.MUL(DAE.ET_REAL()),DAE.RCONST(1e-8)), DAE.RCONST(1e-8));
        nArgs1 = listLength(varExpListTotal);
        nArgs2 = listLength(restVar);
        varExpListHAdded = Util.listReplaceAtWithFill(DAE.BINARY(currVar, DAE.ADD(DAE.ET_REAL()),delta),nArgs1-nArgs2+1, varExpListTotal,DAE.RCONST(0.0));
        derFun = DAE.BINARY(DAE.BINARY(DAE.CALL(fname, varExpListHAdded, tuple_, builtin, et, inlineType), DAE.SUB(DAE.ET_REAL()), DAE.CALL(fname, varExpListTotal, tuple_, builtin, et, inlineType)), DAE.DIV(DAE.ET_REAL()), delta);
      then DAE.BINARY(e, DAE.ADD(DAE.ET_REAL()), DAE.BINARY(derFun, DAE.MUL(DAE.ET_REAL()), currDerVar)); 
  end matchcontinue;
end partialNumericalDifferentiation;

protected function differentiateAlgorithmStatements
  // function: differentiateAlgorithmStatements
  // author: lochel
  input list<DAE.Statement> inStatements;
  input DAE.ComponentRef inVar;
  input DAE.FunctionTree inFunctions;
  output list<DAE.Statement> outStatements;
algorithm
  outStatements := matchcontinue(inStatements, inVar, inFunctions)
    local
      list<DAE.Statement> restStatements,statementLst,elseif_statementLst,else_statementLst;
      DAE.ComponentRef var,cref;
      list<DAE.ComponentRef> dependentVars;
      DAE.FunctionTree functions;
      
      DAE.Exp e1,e2,lhsExps,rhsExps,exp,exp2,elseif_exp;
      DAE.ExpType type_;
      
      DAE.Statement currStmt;
      list<DAE.Statement> derivedStatements1;
      list<DAE.Statement> derivedStatements2;
      
      list<DAE.Exp> eLst, exps1, exps2;
      
      list<DAE.ComponentRef> vars1, vars2;
      list<DAE.Algorithm> algorithms;
      DAE.ElementSource elemSrc,source;
      DAE.Else elseif_else_;
      Boolean iterIsArray;
      DAE.Ident ident;
      
    case({}, _, _) then {};
      
    case((currStmt as DAE.STMT_ASSIGN(type_=type_, exp1=e1, exp=e2))::restStatements, var, functions) equation
      lhsExps = differentiateWithRespectToX(e1, var, functions, {}, {}, {});
      rhsExps = differentiateWithRespectToX(e2, var, functions, {}, {}, {});
      derivedStatements1 = {DAE.STMT_ASSIGN(type_, lhsExps, rhsExps, DAE.emptyElementSource), currStmt};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_TUPLE_ASSIGN(exp=e2)::restStatements, var, functions) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.differentiateAlgorithmStatements failed: DAE.STMT_TUPLE_ASSIGN"});
    then fail();
      
    case(DAE.STMT_ASSIGN_ARR(exp=e2)::restStatements, var, functions) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.differentiateAlgorithmStatements failed: DAE.STMT_ASSIGN_ARR"});
    then fail();
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.NOELSE(), source=source)::restStatements, var, functions)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.NOELSE, source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSEIF(exp=elseif_exp, statementLst=elseif_statementLst, else_=elseif_else_), source=source)::restStatements, var, functions)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements2 = differentiateAlgorithmStatements({DAE.STMT_IF(elseif_exp, elseif_statementLst, elseif_else_, source)}, var, functions);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSE(statementLst=else_statementLst), source=source)::restStatements, var, functions)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements2 = differentiateAlgorithmStatements(else_statementLst, var, functions);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_FOR(type_=type_, iterIsArray=iterIsArray, iter=ident, range=exp, statementLst=statementLst, source=elemSrc)::restStatements, var, functions)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      
      /*cref = ComponentReference.makeCrefIdent(ident, DAE.ET_INT(), {});
      cref = differentiateVarWithRespectToX(cref, var, {});
      exp2 = DAE.CREF(cref, DAE.ET_INT());
      
      derivedStatements2 = {DAE.STMT_ASSIGN(DAE.ET_INT(), exp2, DAE.ICONST(StateVar);0), DAE.emptyElementSource)};
      derivedStatements1 = listAppend(derivedStatements2, derivedStatements1);*/
      
      derivedStatements1 = {DAE.STMT_FOR(type_, iterIsArray, ident, exp, derivedStatements1, elemSrc)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
        
    case(DAE.STMT_WHILE(exp=e1, statementLst=statementLst, source=elemSrc)::restStatements, var, functions)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements1 = {DAE.STMT_WHILE(e1, derivedStatements1, elemSrc)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_WHEN(exp=e2)::restStatements, var, functions) equation
      derivedStatements1 = differentiateAlgorithmStatements(restStatements, var, functions);
    then derivedStatements1;
      
    case((currStmt as DAE.STMT_ASSERT(cond=e2))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case((currStmt as DAE.STMT_TERMINATE(msg=e2))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case(DAE.STMT_REINIT(value=e2)::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
    then derivedStatements2;
      
    case(DAE.STMT_NORETCALL(exp=e1, source=elemSrc)::restStatements, var, functions) equation
      e2 = differentiateWithRespectToX(e1, var, functions, {}, {}, {});
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend({DAE.STMT_NORETCALL(e2, elemSrc)}, derivedStatements2);
    then fail();
      
    case((currStmt as DAE.STMT_RETURN(source=elemSrc))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case((currStmt as DAE.STMT_BREAK(source=elemSrc))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case(_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.differentiateAlgorithmStatements failed"});
    then fail();
  end matchcontinue;
end differentiateAlgorithmStatements;

public function determineIndices
  // function: determineIndices
  // using column major order
  input list<DAE.ComponentRef> inStates;
  input list<DAE.ComponentRef> inStates2;
  input Integer inActInd;
  input list<BackendDAE.Var> inAllVars;
  output list<tuple<String,Integer>> outTuple;
algorithm
  outTuple := matchcontinue(inStates, inStates2, inActInd,inAllVars)
    local
      list<tuple<String,Integer>> str;
      list<tuple<String,Integer>> erg;
      list<DAE.ComponentRef> rest, states;
      DAE.ComponentRef curr;
      Boolean searchForStates;
      Integer actInd;
      list<BackendDAE.Var> allVars;
      
    case ({}, states, _, _) then {};
    case (curr::rest, states, actInd, allVars) equation
      (str, actInd) = determineIndices2(curr, states, actInd, allVars);
      erg = determineIndices(rest, states, actInd, allVars);
      str = listAppend(str, erg);
    then str;
  end matchcontinue;
end determineIndices;

protected function determineIndices2
  // function: determineIndices2
  input DAE.ComponentRef inDStates;
  input list<DAE.ComponentRef> inStates;
  input Integer actInd;
  input list<BackendDAE.Var> inAllVars;
  output list<tuple<String,Integer>> outTuple;
  output Integer outActInd;
algorithm
  (outTuple,outActInd) := matchcontinue(inDStates, inStates, actInd, inAllVars)
    local
      tuple<String,Integer> str;
      list<tuple<String,Integer>> erg;
      list<DAE.ComponentRef> rest;
      DAE.ComponentRef new, curr, dState;
      list<BackendDAE.Var> allVars;
      //String debug1;Integer debug2;
    case (dState, {}, actInd, allVars) then ({}, actInd);
    case (dState,curr::rest, actInd, allVars) equation
      new = differentiateVarWithRespectToX(dState,curr,allVars);
      str = (ComponentReference.printComponentRefStr(new) ,actInd);
      actInd = actInd+1;      
      (erg, actInd) = determineIndices2(dState, rest, actInd, allVars);
    then (str::erg, actInd);
    case (_,_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.determineIndices2() failed"});
    then fail();
  end matchcontinue;
end determineIndices2;

public function changeIndices
  input list<BackendDAE.Var> derivedVariables;
  input list<tuple<String,Integer>> outTuple;
  input BackendDAE.BinTree inBinTree;
  output list<BackendDAE.Var> derivedVariablesChanged;
  output BackendDAE.BinTree outBinTree;
algorithm
  (derivedVariablesChanged,outBinTree) := matchcontinue(derivedVariables,outTuple,inBinTree)
    local
      list<BackendDAE.Var> rest,changedVariables;
      BackendDAE.Var derivedVariable;
      list<tuple<String,Integer>> restTuple;
      BackendDAE.BinTree bt;
    case ({},_,bt) then ({},bt);
    case (derivedVariable::rest,restTuple,bt) equation
      (derivedVariable,bt) = changeIndices2(derivedVariable,restTuple,bt);
      (changedVariables,bt) = changeIndices(rest,restTuple,bt);
    then (derivedVariable::changedVariables,bt);
    case (_,_,_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.changeIndices() failed"});
    then fail();      
  end matchcontinue;
end changeIndices;

protected function changeIndices2
  input BackendDAE.Var derivedVariable;
  input list<tuple<String,Integer>> varIndex; 
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.Var derivedVariablesChanged;
  output BackendDAE.BinTree outBinTree;
algorithm
 (derivedVariablesChanged,outBinTree) := matchcontinue(derivedVariable, varIndex,inBinTree)
    local
      BackendDAE.Var curr, changedVar;
      DAE.ComponentRef currCREF;
      list<tuple<String,Integer>> restTuple;
      String currVar;
      Integer currInd;
      BackendDAE.BinTree bt;
      list<Integer> varInt;
    case (curr  as BackendDAE.VAR(varName=currCREF),(currVar,currInd)::restTuple,bt) equation
      true = stringEqual(currVar,ComponentReference.printComponentRefStr(currCREF));
      changedVar = BackendVariable.setVarIndex(curr,currInd);
      Debug.fcall("varIndex2",print, currVar +& " " +& intString(currInd)+&"\n");
      bt = BackendDAEUtil.treeAddList(bt,{currCREF});
    then (changedVar,bt);
    case (curr  as BackendDAE.VAR(varName=currCREF),{},bt) equation
      changedVar = BackendVariable.setVarIndex(curr,-1);
      Debug.fcall("varIndex2",print, ComponentReference.printComponentRefStr(currCREF) +& " -1\n");
    then (changedVar,bt);      
    case (curr  as BackendDAE.VAR(varName=currCREF),(currVar,currInd)::restTuple,bt) equation
      changedVar = BackendVariable.setVarIndex(curr,-1);
      Debug.fcall("varIndex2",print, ComponentReference.printComponentRefStr(currCREF) +& " -1\n");
      (changedVar,bt) = changeIndices2(changedVar,restTuple,bt);
    then (changedVar,bt);
    case (_,_,_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.changeIndices2() failed"});
    then fail();      
  end matchcontinue;
end changeIndices2;


 
end Linearization;
