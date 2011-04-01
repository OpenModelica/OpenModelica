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

encapsulated package BackendDAEOptimize
" file:         BackendDAEOptimize.mo
  package:     BackendDAEOptimize
  description: BackendDAEOPtimize contains functions that do some kind of
               optimazation on the BackendDAE datatype:
               - removing simpleEquations
               - Tearing/Relaxation
               - Linearization
               - Inline Integration
               - and so on ... 
               
  RCS: $Id$

"

public import Absyn;
public import BackendDAE;
public import DAE;

protected import BackendDump;
protected import BackendDAECreate;
protected import BackendDAETransform;
protected import BackendDAEUtil;
protected import BackendEquation;
protected import BackendVarTransform;
protected import BackendVariable;
protected import Builtin;
protected import ClassInf;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Derive;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSolve;
protected import ExpressionSimplify;
protected import Error;
protected import Inline;
protected import RTOpts;
protected import Util;
protected import VarTransform;
protected import Values;
protected import ValuesUtil;


/* 
 * inline arrayeqns stuff
 */

public function inlineArrayEqnPast
"function inlineArrayEqnPast
autor: Frenkel TUD 2011-3"
    input BackendDAE.BackendDAE inDAE;
    input DAE.FunctionTree inFunctionTree;
    input BackendDAE.IncidenceMatrix inM;
    input BackendDAE.IncidenceMatrix inMT;
    input array<Integer> inAss1;  
    input array<Integer> inAss2;  
    input list<list<Integer>> inComps;  
    output BackendDAE.BackendDAE outDAE;
    output BackendDAE.IncidenceMatrix outM;
    output BackendDAE.IncidenceMatrix outMT;
    output array<Integer> outAss1;  
    output array<Integer> outAss2;  
    output list<list<Integer>> outComps; 
    output Boolean outRunMatching;
protected
  Option<BackendDAE.IncidenceMatrix> om,omT; 
algorithm
  (outDAE,om,omT) := inlineArrayEqn(inDAE,inFunctionTree,SOME(inM),SOME(inMT));
  (outM,outMT) := BackendDAEUtil.getIncidenceMatrixfromOption(outDAE,om,omT);
  outAss1 := inAss1;
  outAss2 := inAss2;
  outComps := inComps;   
  outRunMatching := true;     
end inlineArrayEqnPast;

public function inlineArrayEqn
"function: inlineArrayEqn
autor: Frenkel TUD 2011-3"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree inFunctionTree;
  input Option<BackendDAE.IncidenceMatrix> inM;
  input Option<BackendDAE.IncidenceMatrix> inMT;
  output BackendDAE.BackendDAE outDAE;
  output Option<BackendDAE.IncidenceMatrix> outM;
  output Option<BackendDAE.IncidenceMatrix> outMT;
algorithm
  (outDAE,outM,outMT):=
  match (inDAE,inFunctionTree,inM,inMT)
    local
      DAE.FunctionTree funcs;
      BackendDAE.IncidenceMatrix m,mT,m1,mT1;
      BackendDAE.Variables vars,knvars,exobj;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,eqns1,remeqns,remeqns1,inieqns,inieqns1;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      list<DAE.Algorithm> algs;
      array<list<BackendDAE.Equation>> arraylisteqns;
      list<Integer> updateeqns;
      BackendDAE.BackendDAE dae;
      
    case (BackendDAE.DAE(vars,knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc),funcs,SOME(m),SOME(mT))
      equation      
        // get scalar array eqs list
        arraylisteqns = Util.arrayMap(arreqns,getScalarArrayEqns);
        // replace them
        (eqns1,(arraylisteqns,_,updateeqns)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(eqns,replaceScalarArrayEqns,(arraylisteqns,1,{}));
        (remeqns1,(arraylisteqns,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(remeqns,replaceScalarArrayEqns,(arraylisteqns,1,{}));
        (inieqns1,(_,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(inieqns,replaceScalarArrayEqns,(arraylisteqns,1,{}));
        // update Incidence matrix
        dae = BackendDAE.DAE(vars,knvars,exobj,av,eqns1,remeqns1,inieqns1,arreqns,algorithms,einfo,eoc); 
        (m1,mT1) = BackendDAEUtil.updateIncidenceMatrix(dae,m,mT,updateeqns);
      then
        (dae,SOME(m1),SOME(mT1));
    case (BackendDAE.DAE(vars,knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc),funcs,_,_)
      equation      
        // get scalar array eqs list
        arraylisteqns = Util.arrayMap(arreqns,getScalarArrayEqns);
        // replace them
        (eqns1,(arraylisteqns,_,updateeqns)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(eqns,replaceScalarArrayEqns,(arraylisteqns,1,{}));
        (remeqns1,(arraylisteqns,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(remeqns,replaceScalarArrayEqns,(arraylisteqns,1,{}));
        (inieqns1,(_,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(inieqns,replaceScalarArrayEqns,(arraylisteqns,1,{}));
        dae = BackendDAE.DAE(vars,knvars,exobj,av,eqns1,remeqns1,inieqns1,arreqns,algorithms,einfo,eoc); 
      then
        (dae,NONE(),NONE());        
  end match;        
end inlineArrayEqn;

protected function getScalarArrayEqns"
Author: Frenkel TUD 2011-02"
  input  BackendDAE.MultiDimEquation inAEqn;
  output list<BackendDAE.Equation> outEqsLst;
algorithm
  outEqsLst := 
  matchcontinue (inAEqn)
    local
      BackendDAE.MultiDimEquation aeqn;
      list<BackendDAE.Equation> eqns;
      DAE.ElementSource source; 
      DAE.Exp e1,e2;
      list<DAE.Exp> ea1,ea2;
      list<tuple<DAE.Exp,DAE.Exp>> ealst; 
    case BackendDAE.MULTIDIM_EQUATION(left=e1,right=e2,source=source)
      equation
        true = Expression.isArray(e1) or Expression.isMatrix(e1);
        true = Expression.isArray(e2) or Expression.isMatrix(e2);
        ea1 = Expression.flattenArrayExpToList(e1);
        ea2 = Expression.flattenArrayExpToList(e2);          
        ealst = Util.listThreadTuple(ea1,ea2);
        eqns = Util.listMap1(ealst,BackendEquation.generateEQUATION,source);
      then
        eqns;
    case aeqn then {};
  end matchcontinue;
end getScalarArrayEqns;

protected function replaceScalarArrayEqns
  "Help function to e.g. inlineArrayEqn"
  input tuple<BackendDAE.Equation,tuple<array<list<BackendDAE.Equation>>,Integer,list<Integer>>> tpl;
  output tuple<BackendDAE.Equation,tuple<array<list<BackendDAE.Equation>>,Integer,list<Integer>>> outTpl;
protected
   BackendDAE.Equation e,e1;
   tuple<BackendDAE.Variables,DAE.FunctionTree> ext_arg, ext_art1;
algorithm
  outTpl := 
  matchcontinue (tpl)
    local
      array<list<BackendDAE.Equation>> arraylisteqns,arraylisteqns1; 
      BackendDAE.Equation eqn,e;
      list<BackendDAE.Equation> eqns;
      Integer index,pos,i;
      list<Integer> updateeqns;
    case ((e as BackendDAE.ARRAY_EQUATION(index=index),(arraylisteqns,pos,updateeqns)))
      equation
        i = index+1;
        eqn::eqns = arraylisteqns[i];
        arraylisteqns1 = arrayUpdate(arraylisteqns,i,eqns);
      then
        ((eqn,(arraylisteqns1,pos+1,pos::updateeqns)));
    case ((eqn,(arraylisteqns,pos,updateeqns))) then ((eqn,(arraylisteqns,pos+1,updateeqns)));
  end matchcontinue;      
end replaceScalarArrayEqns;

/* 
 * inline functions stuff
 */

public function lateInline
"function lateInlineDAE"
    input BackendDAE.BackendDAE inDAE;
    input DAE.FunctionTree inFunctionTree;
    input BackendDAE.IncidenceMatrix inM;
    input BackendDAE.IncidenceMatrix inMT;
    input array<Integer> inAss1;  
    input array<Integer> inAss2;  
    input list<list<Integer>> inComps;  
    output BackendDAE.BackendDAE outDAE;
    output BackendDAE.IncidenceMatrix outM;
    output BackendDAE.IncidenceMatrix outMT;
    output array<Integer> outAss1;  
    output array<Integer> outAss2;  
    output list<list<Integer>> outComps; 
    output Boolean outRunMatching;
algorithm
  outDAE := Inline.inlineCalls(SOME(inFunctionTree),{DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()},inDAE);
  outM := inM;        
  outMT := inMT;
  outAss1 := inAss1;
  outAss2 := inAss2;
  outComps := inComps;   
  outRunMatching := false;     
end lateInline;

/* 
 * remove simply equations stuff
 */

public function removeSimpleEquationsPast
"function lateInlineDAE"
    input BackendDAE.BackendDAE inDAE;
    input DAE.FunctionTree inFunctionTree;
    input BackendDAE.IncidenceMatrix inM;
    input BackendDAE.IncidenceMatrix inMT;
    input array<Integer> inAss1;  
    input array<Integer> inAss2;  
    input list<list<Integer>> inComps;  
    output BackendDAE.BackendDAE outDAE;
    output BackendDAE.IncidenceMatrix outM;
    output BackendDAE.IncidenceMatrix outMT;
    output array<Integer> outAss1;  
    output array<Integer> outAss2;  
    output list<list<Integer>> outComps; 
    output Boolean outRunMatching;
protected
  Option<BackendDAE.IncidenceMatrix> om,omT;
algorithm
  (outDAE,om,omT) := removeSimpleEquations(inDAE,inFunctionTree,SOME(inM),SOME(inMT));
  (outM,outMT) := BackendDAEUtil.getIncidenceMatrixfromOption(outDAE,om,omT);
  outAss1 := inAss1;
  outAss2 := inAss2;
  outComps := inComps;   
  outRunMatching := true; // until remove simple equations does not update incidence matrix     
end removeSimpleEquationsPast;

public function removeSimpleEquations
"function: removeSimpleEquations
  This function moves simple equations on the form a=b from equations 2nd
  in BackendDAE.BackendDAE to simple equations 3rd in BackendDAE.BackendDAE to speed up assignment alg.
  inputs:  (vars: Variables,
            knownVars: Variables,
            eqns: BackendDAE.Equation list,
            simpleEqns: BackendDAE.Equation list,
            initEqns : Equatoin list,
            binTree: BinTree)
  outputs: (Variables, BackendDAE.Variables, BackendDAE.Equation list, BackendDAE.Equation list
         BackendDAE.Equation list)"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree inFunctionTree;
  input Option<BackendDAE.IncidenceMatrix> inM;
  input Option<BackendDAE.IncidenceMatrix> inMT;
  output BackendDAE.BackendDAE outDAE;
  output Option<BackendDAE.IncidenceMatrix> outM;
  output Option<BackendDAE.IncidenceMatrix> outMT;
algorithm
  (outDAE,outM,outMT):=
  match (inDAE,inFunctionTree,inM,inMT)
    local
      DAE.FunctionTree funcs;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Variables vars,vars_1,knvars,exobj,knvars_1,knvars_2,removedVars;
      BackendDAE.AliasVariables av,varsAliases;
      BackendDAE.EquationArray eqns,eqns1,remeqns,remeqns1,inieqns,inieqns1;
      array<BackendDAE.MultiDimEquation> arreqns,arreqns1;
      array<DAE.Algorithm> algorithms,algorithms1;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      VarTransform.VariableReplacements repl,replc,replc_1,vartransf,vartransf1;
      list<BackendDAE.Equation> eqns_1,seqns,eqns_2,seqns_1,ieqns_1,eqns_3,seqns_2,ieqns_2,seqns_4,seqns_3,lsteqns,reqns,reqns_1,ieqns;
      list<BackendDAE.MultiDimEquation> lstarreqns,lstarreqns1,lstarreqns2;
      BackendDAE.BinTree movedvars_1,movedvars_2,outputs;
      list<DAE.Algorithm> algs,algs_1;
      list<tuple<list<DAE.Exp>,list<DAE.Exp>>> inputsoutputs;
      
    case (BackendDAE.DAE(vars,knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc),funcs,m,mT)
      equation      
        repl = VarTransform.emptyReplacements();
        replc = VarTransform.emptyReplacements();
        removedVars = BackendDAEUtil.emptyVars();      
  
        lsteqns = BackendDAEUtil.equationList(eqns);       
        reqns = BackendDAEUtil.equationList(remeqns);       
        ieqns = BackendDAEUtil.equationList(inieqns);       
        lstarreqns = arrayList(arreqns);       
        algs = arrayList(algorithms);       
        outputs = BackendDAE.emptyBintree;
        outputs = getOutputsFromAlgorithms(lsteqns,outputs);
        (eqns_1,seqns,movedvars_1,movedvars_2,vartransf,_,replc_1,av) = removeSimpleEquations2(lsteqns, simpleEquation, vars, knvars, BackendDAE.emptyBintree, BackendDAE.emptyBintree, outputs, repl, {},replc,av);
        vartransf1 = VarTransform.addMultiDimReplacements(vartransf);
        Debug.fcall("dumprepl", VarTransform.dumpReplacements, vartransf1);
        Debug.fcall("dumpreplc", VarTransform.dumpReplacements, replc_1);
        eqns_2 = BackendVarTransform.replaceEquations(eqns_1, replc_1);
        seqns_1 = BackendVarTransform.replaceEquations(seqns, replc_1);
        ieqns_1 = BackendVarTransform.replaceEquations(ieqns, replc_1);
        lstarreqns1 = BackendVarTransform.replaceMultiDimEquations(lstarreqns, replc_1);
        eqns_3 = BackendVarTransform.replaceEquations(eqns_2, vartransf1);
        seqns_2 = BackendVarTransform.replaceEquations(seqns_1, vartransf1);
        ieqns_2 = BackendVarTransform.replaceEquations(ieqns_1, vartransf1);
        reqns_1 = BackendVarTransform.replaceEquations(reqns, vartransf1);
        lstarreqns2 = BackendVarTransform.replaceMultiDimEquations(lstarreqns1, vartransf1);
        algs_1 = BackendVarTransform.replaceAlgorithms(algs,vartransf1);
        (vars_1,knvars) = BackendVariable.moveVariables(vars, knvars, movedvars_1);
        (vars_1,removedVars) = BackendVariable.moveVariables(vars_1, removedVars, movedvars_2);
        inputsoutputs = Util.listMap1r(algs_1,BackendDAECreate.lowerAlgorithmInputsOutputs,vars_1);
        eqns_3 = Util.listMap1(eqns_3,updateAlgorithmInputsOutputs,inputsoutputs);
        seqns_3 = listAppend(seqns_2, reqns_1) "& print_vars_statistics(vars\',knvars\')" ;
        //(knvars_2,seqns_4,varsAliases) = removeConstantEqns(knvars,seqns_3,av);
        eqns1 = BackendDAEUtil.listEquation(eqns_3);
        remeqns1 = BackendDAEUtil.listEquation(seqns_3);
        inieqns1 = BackendDAEUtil.listEquation(ieqns_2);
        arreqns1 = listArray(lstarreqns2);
        algorithms1 = listArray(algs_1);
      then
        (BackendDAE.DAE(vars_1,knvars,exobj,av,eqns1,remeqns1,inieqns1,arreqns1,algorithms1,einfo,eoc),NONE(),NONE());
  end match;        
end removeSimpleEquations;

protected function removeSimpleEquations2
"Traverses all equations and puts those that are simple in
 a separate list. It builds a set of varable replacements that
 are later used to replace these variable substitutions in the
 equations that are left."
  input list<BackendDAE.Equation> eqns;
  input FuncTypeSimpleEquation funcSimpleEquation "function as argument so it can be distinguish between a=b/a=-b and a=const.";
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  input BackendDAE.BinTree mvars;
  input BackendDAE.BinTree mvars1;
  input BackendDAE.BinTree outputs;
  input VarTransform.VariableReplacements repl;
  input list<DAE.ComponentRef> inExtendLst;
  input VarTransform.VariableReplacements replc;
  input BackendDAE.AliasVariables invarsAliases;
  output list<BackendDAE.Equation> outEqns;
  output list<BackendDAE.Equation> outSimpleEqns;
  output BackendDAE.BinTree outMvars;
  output BackendDAE.BinTree outMvars1;
  output VarTransform.VariableReplacements outRepl;
  output list<DAE.ComponentRef> outExtendLst;
  output VarTransform.VariableReplacements outReplc;
  output BackendDAE.AliasVariables outvarsAliases;  
  partial function FuncTypeSimpleEquation
    input BackendDAE.Equation eqn;
    input Boolean swap;
    output DAE.Exp e1;
    output DAE.Exp e2;
    output DAE.ElementSource source;
  end FuncTypeSimpleEquation;
algorithm
  (outEqns,outSimpleEqns,outMvars,outMvars1,outRepl,outExtendLst,outReplc,outvarsAliases) := matchcontinue (eqns,funcSimpleEquation,vars,knvars,mvars,mvars1,outputs,repl,inExtendLst,replc,invarsAliases)
    local
      BackendDAE.BinTree mvars_1,mvars_2;
      VarTransform.VariableReplacements repl_1,repl_2,replc_1,replc_2;
      DAE.ComponentRef cr1;
      list<BackendDAE.Equation> eqns_1,seqns_1;
      BackendDAE.Equation e;
      DAE.ExpType t;
      DAE.Exp e1,e2;
      DAE.ElementSource source "the element source";
      list<DAE.ComponentRef> extlst,extlst1;
      BackendDAE.Equation eq1,eq2;
      BackendDAE.AliasVariables varsAliases;
      BackendDAE.Var v;
      
      
    case ({},funcSimpleEquation,vars,knvars,mvars,mvars1,outputs,repl,extlst,replc,varsAliases) then ({},{},mvars,mvars1,repl,extlst,replc,varsAliases);

     // simple equation like a = const
    case (e::eqns,funcSimpleEquation,vars,knvars,mvars,mvars1,outputs,repl,inExtendLst,replc,varsAliases) equation
      {e} = BackendVarTransform.replaceEquations({e},replc);
      {e} = BackendVarTransform.replaceEquations({e},repl);
      (e1 as DAE.CREF(cr1,t),e2,source) = funcSimpleEquation(e,false);
      true = Expression.isConst(e2);
      false = BackendVariable.isState(cr1, vars) "cr1 not state";
      BackendVariable.isVariable(cr1, vars, knvars) "cr1 not constant";
      ({v},_) = BackendVariable.getVar(cr1,vars);
      false = BackendVariable.isTopLevelInputOrOutput(cr1,vars,knvars);
      failure(_ = BackendDAEUtil.treeGet(outputs, cr1)) "cr1 not output of algorithm";
      (extlst,_,replc_1) = removeSimpleEquations3(inExtendLst,replc,cr1,NONE(),e2,t);
      Debug.fcall("debugAlias",print,"Simple Equation " +& ComponentReference.printComponentRefStr(cr1) +& " = " +& ExpressionDump.printExpStr(e2) +& " found.\n"); 
      repl_1 = VarTransform.addReplacement(repl, cr1, e2);
      mvars_1 = BackendDAEUtil.treeAdd(mvars, cr1, 0);   
      (eqns_1,seqns_1,mvars, mvars1, repl_2,extlst1,replc_2,varsAliases) = removeSimpleEquations2(eqns, funcSimpleEquation, vars, knvars, mvars_1, mvars1, outputs, repl_1, extlst,replc_1,varsAliases);
    then
      (eqns_1,(BackendDAE.SOLVED_EQUATION(cr1,e2,source) :: seqns_1),mvars,mvars1,repl_2,extlst1,replc_2,varsAliases);

     // simple equation like a = const ( Swapped args)
    case (e::eqns,funcSimpleEquation,vars,knvars,mvars,mvars1,outputs,repl,inExtendLst,replc,varsAliases) equation
      {e} = BackendVarTransform.replaceEquations({e},replc);
      {BackendDAE.EQUATION(e1,e2,source)} = BackendVarTransform.replaceEquations({e},repl);
      (e1 as DAE.CREF(cr1,t),e2,source) = simpleEquation(BackendDAE.EQUATION(e2,e1,source),true);
      true = Expression.isConst(e2);
      false = BackendVariable.isState(cr1, vars) "cr1 not state";
      BackendVariable.isVariable(cr1, vars, knvars) "cr1 not constant";
      ({v},_) = BackendVariable.getVar(cr1,vars);
      false = BackendVariable.isTopLevelInputOrOutput(cr1,vars,knvars);
      failure(_ = BackendDAEUtil.treeGet(outputs, cr1)) "cr1 not output of algorithm";
      (extlst,_,replc_1) = removeSimpleEquations3(inExtendLst,replc,cr1,NONE(),e2,t); 
      Debug.fcall("debugAlias",print,"Simple Equation " +& ComponentReference.printComponentRefStr(cr1) +& " = " +& ExpressionDump.printExpStr(e2) +& " found.\n");
      repl_1 = VarTransform.addReplacement(repl, cr1, e2);
      mvars_1 = BackendDAEUtil.treeAdd(mvars, cr1, 0);
      (eqns_1,seqns_1,mvars,mvars1,repl_2,extlst1,replc_2,varsAliases) = removeSimpleEquations2(eqns, funcSimpleEquation, vars, knvars, mvars_1, mvars1,outputs, repl_1, extlst,replc_1,varsAliases);
    then
      (eqns_1,(BackendDAE.SOLVED_EQUATION(cr1,e2,source) :: seqns_1),mvars,mvars1,repl_2,extlst1,replc_2,varsAliases);

    // alias equation like a=b
    case (e::eqns,funcSimpleEquation,vars,knvars,mvars,mvars1,outputs,repl,inExtendLst,replc,varsAliases) equation
      {e} = BackendVarTransform.replaceEquations({e},replc);
      {e} = BackendVarTransform.replaceEquations({e},repl);
      (e1 as DAE.CREF(cr1,t),e2,source) = funcSimpleEquation(e,false);
      false = Expression.isConst(e2);
      false = BackendVariable.isState(cr1, vars) "cr1 not state";
      BackendVariable.isVariable(cr1, vars, knvars) "cr1 not constant";
      false = BackendVariable.isTopLevelInputOrOutput(cr1,vars,knvars);
      ({v},_) = BackendVariable.getVar(cr1,vars);
      failure(_ = BackendVariable.varStartValueFail(v));
      failure(_ = BackendDAEUtil.treeGet(outputs, cr1)) "cr1 not output of algorithm";
      (extlst,_,replc_1) = removeSimpleEquations3(inExtendLst,replc,cr1,NONE(),e2,t);
      Debug.fcall("debugAlias",print,"Alias Equation " +& ComponentReference.printComponentRefStr(cr1) +& " = " +& ExpressionDump.printExpStr(e2) +& " found.\n"); 
      repl_1 = VarTransform.addReplacement(repl, cr1, e2);
      mvars_1 = BackendDAEUtil.treeAdd(mvars1, cr1, 0);
      varsAliases = BackendDAEUtil.updateAliasVariables(varsAliases, cr1, e2,vars);
      (eqns_1,seqns_1,mvars,mvars_1,repl_2,extlst1,replc_2,varsAliases) = removeSimpleEquations2(eqns, funcSimpleEquation, vars, knvars, mvars,mvars_1, outputs, repl_1, extlst,replc_1,varsAliases);
    then
      (eqns_1,seqns_1,mvars,mvars_1,repl_2,extlst1,replc_2,varsAliases);

    // alias equation like a=b (Swappend args)
    case (e::eqns,funcSimpleEquation,vars,knvars,mvars,mvars1,outputs,repl,inExtendLst,replc,varsAliases) equation
      {e} = BackendVarTransform.replaceEquations({e},replc);
      {BackendDAE.EQUATION(e1,e2,source)} = BackendVarTransform.replaceEquations({e},repl);
      (e1 as DAE.CREF(cr1,t),e2,source) = simpleEquation(BackendDAE.EQUATION(e2,e1,source),true);
      false = Expression.isConst(e2);
      false = BackendVariable.isState(cr1, vars) "cr1 not state";
      BackendVariable.isVariable(cr1, vars, knvars) "cr1 not constant";
      false = BackendVariable.isTopLevelInputOrOutput(cr1,vars,knvars);
      ({v},_) = BackendVariable.getVar(cr1,vars);
      failure( _ = BackendVariable.varStartValueFail(v));
      failure(_ = BackendDAEUtil.treeGet(outputs, cr1)) "cr1 not output of algorithm";
      (extlst,_,replc_1) = removeSimpleEquations3(inExtendLst,replc,cr1,NONE(),e2,t);
      Debug.fcall("debugAlias",print,"Alias Equation " +& ComponentReference.printComponentRefStr(cr1) +& " = " +& ExpressionDump.printExpStr(e2) +& " found.\n"); 
      repl_1 = VarTransform.addReplacement(repl, cr1, e2);
      mvars_1 = BackendDAEUtil.treeAdd(mvars1, cr1, 0);
      varsAliases = BackendDAEUtil.updateAliasVariables(varsAliases, cr1, e2,vars);
      (eqns_1,seqns_1,mvars,mvars_1,repl_2,extlst1,replc_2,varsAliases) = removeSimpleEquations2(eqns, funcSimpleEquation, vars, knvars, mvars,mvars_1, outputs, repl_1, extlst,replc_1,varsAliases);
    then
      (eqns_1,seqns_1,mvars,mvars_1,repl_2,extlst1,replc_2,varsAliases);

      // try next equation.
    case ((e :: eqns),funcSimpleEquation,vars,knvars,mvars,mvars1,outputs,repl,extlst,replc,varsAliases)
      equation
        {eq1} = BackendVarTransform.replaceEquations({e},replc);
        {eq2} = BackendVarTransform.replaceEquations({eq1},repl);
        //print("not removed simple ");print(equationStr(e));print("\n     -> ");print(equationStr(eq1));
        //print("\n\n");
        (eqns_1,seqns_1,mvars,mvars1,repl_1,extlst1,replc_1,varsAliases) = removeSimpleEquations2(eqns, funcSimpleEquation, vars, knvars, mvars,mvars1, outputs, repl, extlst,replc,varsAliases) "Not a simple variable, check rest" ;
      then
        ((e :: eqns_1),seqns_1,mvars,mvars1,repl_1,extlst1,replc_1,varsAliases);
  end matchcontinue;
end removeSimpleEquations2;

protected function removeSimpleEquations3"
Author: Frenkel TUD 2010-07 function removeSimpleEquations3
  helper for removeSimpleEquations2
  if a cref has to be replaced the parent types 
  have to be extended. For example x[2] has to be
  replace all crefs x should be extended to {x[1],x[2],..}
  to replace x[2]. The same for records"
  input list<DAE.ComponentRef> increflst;
  input VarTransform.VariableReplacements inrepl;
  input DAE.ComponentRef cr;
  input Option<DAE.ComponentRef> precr;
  input DAE.Exp e;
  input DAE.ExpType t;
  output list<DAE.ComponentRef> outcreflst;
  output list<DAE.ComponentRef> outcreflst1;
  output VarTransform.VariableReplacements outrepl;
algorithm
  (outcreflst,outcreflst1,outrepl) := matchcontinue (increflst,inrepl,cr,precr,e,t)
    local
      list<DAE.ComponentRef> crlst,crlst1,crlst_1;
      VarTransform.VariableReplacements repl,repl_1,repl_2;
      DAE.Exp e1;
      DAE.ComponentRef sc,sc1,cr1,pcr;
      list<DAE.Subscript> subscriptLst;
      list<DAE.ExpVar> varLst;
      list<DAE.Exp> expl;
      DAE.ExpType ty;
      DAE.Ident ident;
      Absyn.Path name;
     
     // array ?
     case (crlst,repl,cr as DAE.CREF_QUAL(ident=ident,identType=ty as DAE.ET_ARRAY(ty=_),subscriptLst={},componentRef=cr1),NONE(),e,t)
      equation
        sc = ComponentReference.makeCrefIdent(ident,ty,{});
        // check List
        failure(_ = Util.listFindWithCompareFunc(crlst,sc,ComponentReference.crefEqualNoStringCompare,false));
        // extend cr
        e1 = Expression.makeCrefExp(sc,ty);
        ((e1,_)) = BackendDAEUtil.extendArrExp((e1,NONE()));
        // add
        repl_1 = VarTransform.addReplacement(repl, sc, e1);
        (crlst1,crlst_1,repl_2) = removeSimpleEquations3(sc::crlst,repl_1,cr1,SOME(sc),e,t);
      then
        (crlst1,crlst_1,repl_2);
     case (crlst,repl,cr as DAE.CREF_QUAL(ident=ident,identType=ty as DAE.ET_ARRAY(ty=_),subscriptLst={},componentRef=cr1),SOME(pcr),e,t)
      equation
        sc1 = ComponentReference.makeCrefIdent(ident,ty,{});
        sc = ComponentReference.joinCrefs(pcr,sc1);
        // check List
        failure(_ = Util.listFindWithCompareFunc(crlst,sc,ComponentReference.crefEqualNoStringCompare,false));
        // extend cr
        e1 = Expression.makeCrefExp(sc,ty);
        ((e1,_)) = BackendDAEUtil.extendArrExp((e1,NONE()));
        // add
        repl_1 = VarTransform.addReplacement(repl, sc, e1);
        (crlst1,crlst_1,repl_2) = removeSimpleEquations3(sc::crlst,repl_1,cr1,SOME(sc),e,t);
      then
        (crlst1,crlst_1,repl_2);
     // record ?
     case (crlst,repl,cr as DAE.CREF_QUAL(ident=ident,identType=ty as DAE.ET_COMPLEX(name=name,varLst=varLst,complexClassType=ClassInf.RECORD(_)),subscriptLst=subscriptLst,componentRef=cr1),NONE(),e,t)
      equation
        sc = ComponentReference.makeCrefIdent(ident,ty,subscriptLst);
        // check List
        failure(_ = Util.listFindWithCompareFunc(crlst,sc,ComponentReference.crefEqualNoStringCompare,false));
        // extend cr
        expl = Util.listMap1(varLst,Expression.generateCrefsExpFromExpVar,sc);
        e1 = DAE.CALL(name,expl,false,false,ty,DAE.NO_INLINE());
        // add
        repl_1 = VarTransform.addReplacement(repl, sc, e1);
        (crlst1,crlst_1,repl_2) = removeSimpleEquations3(sc::crlst,repl_1,cr1,SOME(sc),e,t);
      then
        (crlst1,crlst_1,repl_2);
     case (crlst,repl,cr as DAE.CREF_QUAL(ident=ident,identType=ty as DAE.ET_COMPLEX(name=name,varLst=varLst,complexClassType=ClassInf.RECORD(_)),subscriptLst=subscriptLst,componentRef=cr1),SOME(pcr),e,t)
      equation
        sc1 = ComponentReference.makeCrefIdent(ident,ty,subscriptLst);
        sc = ComponentReference.joinCrefs(pcr,sc1);
        // check List
        failure(_ = Util.listFindWithCompareFunc(crlst,sc,ComponentReference.crefEqualNoStringCompare,false));
        // extend cr
        expl = Util.listMap1(varLst,Expression.generateCrefsExpFromExpVar,sc);
        e1 = DAE.CALL(name,expl,false,false,ty,DAE.NO_INLINE());
        // add
        repl_1 = VarTransform.addReplacement(repl, sc, e1);
        (crlst1,crlst_1,repl_2) = removeSimpleEquations3(sc::crlst,repl_1,cr1,SOME(sc),e,t);
      then
        (crlst1,crlst_1,repl_2); 
            
     case (crlst,repl,cr as DAE.CREF_IDENT(ident=ident,identType=ty as DAE.ET_COMPLEX(name=name,varLst=varLst,complexClassType=ClassInf.RECORD(_)),subscriptLst=subscriptLst),NONE(),e as DAE.CREF(componentRef=_),t)
      then
        (crlst,{cr},repl);        
     case (crlst,repl,cr as DAE.CREF_IDENT(ident=ident,identType=ty as DAE.ET_COMPLEX(name=name,varLst=varLst,complexClassType=ClassInf.RECORD(_)),subscriptLst=subscriptLst),SOME(pcr),e as DAE.CREF(componentRef=_),t)
      equation
        sc = ComponentReference.joinCrefs(pcr,cr);
      then
        (crlst,{sc},repl);     
     // other
     case (crlst,repl,cr as DAE.CREF_QUAL(ident=ident,identType=ty,subscriptLst=subscriptLst,componentRef=cr1),NONE(),e,t)
      equation
        sc = ComponentReference.makeCrefIdent(ident,ty,subscriptLst);
        (crlst1,crlst_1,repl_2) = removeSimpleEquations3(crlst,repl,cr1,SOME(sc),e,t);
      then
        (crlst1,crlst_1,repl_2);
     case (crlst,repl,cr as DAE.CREF_QUAL(ident=ident,identType=ty,subscriptLst=subscriptLst,componentRef=cr1),SOME(pcr),e,t)
      equation
        sc1 = ComponentReference.makeCrefIdent(ident,ty,subscriptLst);
        sc = ComponentReference.joinCrefs(pcr,sc1);
        (crlst1,crlst_1,repl_2) = removeSimpleEquations3(crlst,repl,cr1,SOME(sc),e,t);
      then
        (crlst1,crlst_1,repl_2);     

    case (crlst,repl,_,_,_,_) then (crlst,{},repl);
  end matchcontinue;
end removeSimpleEquations3;

protected function replaceCrefFromExp "function: replaceCrefFromExp
  author: Frenkel TUD 2010-12
  helper for removeSimpleEquations"
 input tuple<DAE.Exp, tuple<VarTransform.VariableReplacements,list<DAE.ComponentRef>>> inTpl;
 output tuple<DAE.Exp, tuple<VarTransform.VariableReplacements,list<DAE.ComponentRef>>> outTpl;  
algorithm 
  outTpl := matchcontinue(inTpl)
    local 
      VarTransform.VariableReplacements repl; 
      list<DAE.ComponentRef> recordcrefs;
      DAE.ComponentRef cr,sc;
      DAE.Exp e,e1,e2; 
      list<DAE.Subscript> subs;
    // as it is 
    case((DAE.CREF(componentRef=cr), (repl,recordcrefs)))
      equation
        (e) = VarTransform.getReplacement(repl, cr);
        ((e1,(_,_))) = Expression.traverseExp(e,replaceCrefFromExp,(repl,recordcrefs));
      then
        ((e1, (repl,recordcrefs) ));
    // array elements 
    case((DAE.CREF(componentRef=cr), (repl,recordcrefs)))
      equation
        subs = ComponentReference.crefLastSubs(cr);
        sc = ComponentReference.crefStripLastSubs(cr);
        (e) = VarTransform.getReplacement(repl, sc);
        e1 = Expression.applyExpSubscripts(e,subs);
        ((e2,(_,_))) = Expression.traverseExp(e1,replaceCrefFromExp,(repl,recordcrefs));
      then
        ((e2, (repl,recordcrefs) ));
    // record elements 
    case((DAE.CREF(componentRef=cr), (repl,recordcrefs)))
      equation
        e1 = replaceRecordCrefFromExp(cr,recordcrefs,repl);
        ((e2,(_,_))) = Expression.traverseExp(e1,replaceCrefFromExp,(repl,recordcrefs));
      then
        ((e2, (repl,recordcrefs) ));  
    case(inTpl) then inTpl;
  end matchcontinue;
end replaceCrefFromExp;

protected function replaceRecordCrefFromExp "function: replaceRecordCrefFromExp
  author: Frenkel TUD 2010-12
  helper for removeSimpleEquations"
 input DAE.ComponentRef inCref;
 input list<DAE.ComponentRef> inRecCrefs;
 input VarTransform.VariableReplacements inRepl; 
 output DAE.Exp outExp;  
algorithm 
  outExp := matchcontinue(inCref,inRecCrefs,inRepl)
    local 
      VarTransform.VariableReplacements repl; 
      list<DAE.ComponentRef> recordcrefs;
      DAE.ComponentRef cr,sc,rcr,lcr,ncr;
      DAE.Exp e,e1; 
    case(cr,rcr::recordcrefs,repl)
      equation
        true = ComponentReference.crefPrefixOf(rcr,cr);
        (e as DAE.CREF(componentRef=sc)) = VarTransform.getReplacement(repl, cr);
        lcr = ComponentReference.crefStripPrefix(cr,rcr);
        ncr = ComponentReference.joinCrefs(sc,lcr);
        e1 = Expression.crefExp(ncr);
      then
        e1;  
    case(cr,rcr::recordcrefs,repl)
      equation
        false = ComponentReference.crefPrefixOf(rcr,cr);
        e = replaceRecordCrefFromExp(cr,recordcrefs,repl);
      then
        e;  
  end matchcontinue;
end replaceRecordCrefFromExp;

protected function getOutputsFromAlgorithms"
Author: Frenkel TUD 2010-09 function getOutputsFromAlgorithms
  helper for removeSimpleEquations
  collect all outpus from algorithms to avoid replacement
  of a algorithm output"
  input list<BackendDAE.Equation> inEqns;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inEqns,inBinTree)
    local
      list<BackendDAE.Equation> es;
      BackendDAE.Equation e;
      BackendDAE.BinTree bt,bt_1,bt_2;
      list<DAE.Exp> explst;
      list<DAE.ComponentRef> crefs;
    case ({},bt) then bt;
     case (BackendDAE.ALGORITHM(out=explst)::es,bt)
      equation
        crefs = Util.listFlatten(Util.listMap(explst,Expression.extractCrefsFromExp));
        bt_1 = BackendDAEUtil.treeAddList(bt,crefs);
        bt_2 = getOutputsFromAlgorithms(es,bt_1);  
      then bt_2;
    case (e::es,bt)
      equation
        bt_1 = getOutputsFromAlgorithms(es,bt);  
      then bt_1;
  end matchcontinue;
end getOutputsFromAlgorithms;

protected function updateAlgorithmInputsOutputs"
Author: Frenkel TUD 2010-09 function updateAlgorithmInputsOutputs
  helper for removeSimpleEquations
  update inputs and outputs of algorithms after remove simple equations"
  input BackendDAE.Equation inEqn;
  input list<tuple<list<DAE.Exp>,list<DAE.Exp>>> inAlgsInputsOutputs;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := matchcontinue (inEqn,inAlgsInputsOutputs)
    local
      BackendDAE.Equation e;
      list<tuple<list<DAE.Exp>,list<DAE.Exp>>> inputsoutputs;
      Integer index;
      list<DAE.Exp> inputs,outputs;
      DAE.ElementSource source;
     case (BackendDAE.ALGORITHM(index=index,source=source),inputsoutputs)
      equation
        true = listLength(inputsoutputs) > index;
        ((inputs,outputs)) = listNth(inputsoutputs,index);
      then BackendDAE.ALGORITHM(index,inputs,outputs,source);
    case (e,_) then e;
  end matchcontinue;
end updateAlgorithmInputsOutputs;

public function countSimpleEquations
"Counts the number of trivial/simple equations
 e.g on form a=b, a=-b or a=constant"
  input BackendDAE.EquationArray eqns;
  output Integer numEqns;
protected Integer elimLevel;
algorithm
 elimLevel := RTOpts.eliminationLevel();
 RTOpts.setEliminationLevel(2) "Full elimination";
 numEqns := BackendEquation.traverseBackendDAEEqns(eqns,countSimpleEquations2,0);
 RTOpts.setEliminationLevel(elimLevel);
end countSimpleEquations;

protected function countSimpleEquations2
    input tuple<BackendDAE.Equation, Integer> inTpl;
    output tuple<BackendDAE.Equation, Integer> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local 
    BackendDAE.Equation e;
    Integer partialSum;
    case ((e,partialSum))
      equation
        (_,_,_) = simpleEquation(e,false);
      then ((e,partialSum+1));

      // Swaped args in simpleEquation
    case ((e,partialSum))
      equation
      (_,_,_) = simpleEquation(e,true);
      then ((e,partialSum+1));

      //Not simple eqn.
    case inTpl then inTpl;
  end matchcontinue;
end countSimpleEquations2;

protected function simpleEquation
"Returns the two sides of an equation as expressions if it is a
 simple equation. Simple equations are
 a+b=0, a-b=0, a=constant, a=-b, etc.
 The first expression returned, e1, is always a CREF.
 If the equation is not simple, this function will fail."
  input BackendDAE.Equation eqn;
  input Boolean swap "if true swap args.";
  output DAE.Exp e1;
  output DAE.Exp e2;
  output DAE.ElementSource source;
algorithm
  (e1,e2,source) := matchcontinue (eqn,swap)
      local
        DAE.Exp e;
        DAE.ExpType t;
        DAE.ElementSource src "the element source";
      // a = der(b);
      case (BackendDAE.EQUATION(e1 as DAE.CREF(componentRef = _),e2 as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = _)}),src),swap)
        equation
          true = RTOpts.eliminationLevel() > 0;
          true = RTOpts.eliminationLevel() <> 3;
        then (e1,e2,src);
      // a = b;
      case (BackendDAE.EQUATION(e1 as DAE.CREF(componentRef = _),e2 as  DAE.CREF(componentRef = _),src),swap)
        equation
          true = RTOpts.eliminationLevel() > 0;
          true = RTOpts.eliminationLevel() <> 3;
        then (e1,e2,src);
        // a-b = 0
    case (BackendDAE.EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e1,e2,src);
    case (BackendDAE.EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e1,e2,src);        
      // a-b = 0 swap
    case (BackendDAE.EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e2,e1,src);
    case (BackendDAE.EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e2,e1,src);        
        // 0 = a-b
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e1,e2,src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e1,e2,src);
        // 0 = a-b  swap
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e2,e1,src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e2,e1,src);
        // a + b = 0
     case (BackendDAE.EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),e,src),false) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
      true = Expression.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS(t),e2),src);
     case (BackendDAE.EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),e,src),false) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
      true = Expression.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e2),src);
        // a + b = 0 swap
     case (BackendDAE.EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),e,src),true) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
       true = Expression.isZero(e);
     then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
     case (BackendDAE.EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),e,src),true) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
       true = Expression.isZero(e);
     then (e2,DAE.UNARY(DAE.UMINUS_ARR(t),e1),src);
      // 0 = a+b
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),src),false) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Expression.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS(t),e2),src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),src),false) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Expression.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e2),src);
      // 0 = a+b swap
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),src),true) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Expression.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),src),true) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Expression.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS_ARR(t),e1),src);
     // a = -b
    case (BackendDAE.EQUATION(e1 as DAE.CREF(_,_),e2 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);
    case (BackendDAE.EQUATION(e1 as DAE.CREF(_,_),e2 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);
      // -a = b => a = -b
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS(t),e1 as DAE.CREF(_,_)),e2 as DAE.CREF(_,_),src),swap)
      equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
    then (e1,DAE.UNARY(DAE.UMINUS(t),e2),src);
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS_ARR(t),e1 as DAE.CREF(_,_)),e2 as DAE.CREF(_,_),src),swap)
      equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
    then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e2),src);
      // -b - a = 0 => a = -b
    case (BackendDAE.EQUATION(DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e1,e2,src);
    case (BackendDAE.EQUATION(DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e1,e2,src);
      // -b - a = 0 => a = -b swap
    case (BackendDAE.EQUATION(DAE.BINARY(DAE.UNARY(DAE.UMINUS(t),e2 as DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
    case (BackendDAE.EQUATION(DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(t),e2 as DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
        // 0 = -b - a => a = -b
    case (BackendDAE.EQUATION(e,DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e1,e2,src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e1,e2,src);
        // 0 = -b - a => a = -b swap
    case (BackendDAE.EQUATION(e,DAE.BINARY(DAE.UNARY(DAE.UMINUS(t),e2 as DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(t),e2 as DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS_ARR(t),e1),src);
        // -a = -b
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS(_),e1 as DAE.CREF(_,_)),DAE.UNARY(DAE.UMINUS(_),e2 as DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(_,_)),DAE.UNARY(DAE.UMINUS_ARR(_),e2 as DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);        
        // a = constant
    case (BackendDAE.EQUATION(e1 as DAE.CREF(_,_),e,src),swap) equation
      true = RTOpts.eliminationLevel() > 1;
      true = Expression.isConst(e);
      then (e1,e,src);

        // -a = constant
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS(t),e1 as DAE.CREF(_,_)),e,src),swap) equation
      true = RTOpts.eliminationLevel() > 1;
      true = Expression.isConst(e);
      then (e1,DAE.UNARY(DAE.UMINUS(t),e),src);
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS_ARR(t),e1 as DAE.CREF(_,_)),e,src),swap) equation
      true = RTOpts.eliminationLevel() > 1;
      true = Expression.isConst(e);
      then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e),src);
  end matchcontinue;
end simpleEquation;

/*
 * remove constant equations
 */

protected function removeConstantEqns
"autor: Frenkel TUD 2010-12"
 input BackendDAE.Variables inVars;
 input list<BackendDAE.Equation> inEqns;
 input BackendDAE.AliasVariables inAlias;
 output BackendDAE.Variables outVars;
 output list<BackendDAE.Equation> outEqns;
 output BackendDAE.AliasVariables outAlias;
algorithm
  (outVars,outEqns,outAlias) :=
  matchcontinue (inVars,inEqns,inAlias)
    local
      BackendDAE.Variables vars,vars1;
      BackendDAE.Var var,var2,var3;
      DAE.ComponentRef cr;
      DAE.Exp e;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> rest,eqns;
      BackendDAE.AliasVariables aliasvars,aliasvars1;
    case (inVars,{},inAlias) then (inVars,{},inAlias);
    // constant equations
    case (inVars,BackendDAE.SOLVED_EQUATION(componentRef=cr,exp=e)::rest,inAlias)
      equation
        // check exp is const
        true = Expression.isConst(e);
        ({var},_) = BackendVariable.getVar(cr,inVars);
        // set kind to PARAM
        // do not set varKind because of simulation results
        //var1 = BackendVariable.setVarKind(var,BackendDAE.PARAM);
        // add bindExp
        var2 = BackendVariable.setBindExp(var,e);
        // add bindValue if constant
        var3 = setbindValue(e,var2);
        // update vars
        vars = BackendVariable.addVar(var3,inVars);
        // next
        (vars1,eqns,aliasvars) = removeConstantEqns(vars,rest,inAlias);
      then
        (vars1,eqns,aliasvars);
    case (inVars,eqn::rest,inAlias)
      equation
         (vars,eqns,aliasvars) = removeConstantEqns(inVars,rest,inAlias);
      then
        (vars,eqn::eqns,aliasvars);
  end matchcontinue;
end removeConstantEqns;

/*
 * remove alias equations
 */
 
 public function removeAliasEquationsPast
"function lateInlineDAE"
    input BackendDAE.BackendDAE inDAE;
    input DAE.FunctionTree inFunctionTree;
    input BackendDAE.IncidenceMatrix inM;
    input BackendDAE.IncidenceMatrix inMT;
    input array<Integer> inAss1;  
    input array<Integer> inAss2;  
    input list<list<Integer>> inComps;  
    output BackendDAE.BackendDAE outDAE;
    output BackendDAE.IncidenceMatrix outM;
    output BackendDAE.IncidenceMatrix outMT;
    output array<Integer> outAss1;  
    output array<Integer> outAss2;  
    output list<list<Integer>> outComps; 
    output Boolean outRunMatching;
protected
  Option<BackendDAE.IncidenceMatrix> om,omT;
algorithm
  (outDAE,om,omT) := removeAliasEquations(inDAE,inFunctionTree,SOME(inM),SOME(inMT));
  (outM,outMT) := BackendDAEUtil.getIncidenceMatrixfromOption(outDAE,om,omT);
  outAss1 := inAss1;
  outAss2 := inAss2;
  outComps := inComps;   
  outRunMatching := false;      
end removeAliasEquationsPast;

public function removeAliasEquations
"function: removeAliasEquations"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree inFunctionTree;
  input Option<BackendDAE.IncidenceMatrix> inM;
  input Option<BackendDAE.IncidenceMatrix> inMT;
  output BackendDAE.BackendDAE outDAE;
  output Option<BackendDAE.IncidenceMatrix> outM;
  output Option<BackendDAE.IncidenceMatrix> outMT;
algorithm
  (outDAE,outM,outMT):=
  match (inDAE,inFunctionTree,inM,inMT)
    local
      DAE.FunctionTree funcs;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Variables vars,vars_1,knvars,exobj,knvars_1;
      BackendDAE.AliasVariables av,varsAliases;
      BackendDAE.EquationArray eqns,eqns1,remeqns,remeqns1,inieqns,inieqns1;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      list<BackendDAE.Equation> reqns,reqns_1;
      list<DAE.Algorithm> algs;
      
    case (BackendDAE.DAE(vars,knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc),funcs,m,mT)
      equation      
        reqns = BackendDAEUtil.equationList(remeqns);       
        (knvars_1,reqns_1,varsAliases,vars_1) = removeAliasEquations1(knvars,reqns,av,vars);
        Debug.fcall("dumpalias", BackendDump.dumpAliasVariables, varsAliases);
        remeqns1 = BackendDAEUtil.listEquation(reqns_1);
      then
        (BackendDAE.DAE(vars_1,knvars_1,exobj,varsAliases,eqns,remeqns1,inieqns,arreqns,algorithms,einfo,eoc),m,mT);
  end match;        
end removeAliasEquations;

protected function removeAliasEquations1
"autor: Frenkel TUD 2010-12"
 input BackendDAE.Variables inKnVars;
 input list<BackendDAE.Equation> inEqns;
 input BackendDAE.AliasVariables inAlias;
 input BackendDAE.Variables inVars;
 output BackendDAE.Variables outKnVars;
 output list<BackendDAE.Equation> outEqns;
 output BackendDAE.AliasVariables outAlias;
 output BackendDAE.Variables outVars;
algorithm
  (outKnVars,outEqns,outAlias,outVars) :=
  matchcontinue (inKnVars,inEqns,inAlias,inVars)
    local
      BackendDAE.Variables vars,vars1,knvars,knvars1;
      BackendDAE.Var var,var2,var3;
      DAE.ComponentRef cr,vcr;
      DAE.Exp e;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> rest,eqns;
      BackendDAE.AliasVariables aliasvars,aliasvars1;
      Boolean negate;
    case (inKnVars,{},inAlias,inVars) then (inKnVars,{},inAlias,inVars);
    // alias vars
    case (inKnVars,(eqn as BackendDAE.SOLVED_EQUATION(componentRef=cr,exp=e))::rest,inAlias,inVars)
      equation
        // test exp
        (vcr,negate) = removeAliasEquations2(e);
        // get var
        ({var},_) = BackendVariable.getVar(cr,inKnVars);
        // add bindExp
        var2 = BackendVariable.setBindExp(var,e); 
        // add
        //aliasvars = BackendDAEUtil.addAliasVariables(inAlias,var2,e);
        // set attributes
        vars = mergeAliasVarAttributes(var,vcr,inVars,negate);
        // next
        (knvars,eqns,aliasvars1,vars1) = removeAliasEquations1(inKnVars,rest,inAlias,vars);
      then
        (knvars,eqns,aliasvars1,vars1);        
    case (inKnVars,eqn::rest,inAlias,inVars)
      equation
         (knvars,eqns,aliasvars,vars) = removeAliasEquations1(inKnVars,rest,inAlias,inVars);
      then
        (knvars,eqn::eqns,aliasvars,vars);
  end matchcontinue;
end removeAliasEquations1;

protected function removeAliasEquations2
"autor: Frenkel TUD 2010-12"
 input DAE.Exp inExp;
 output DAE.ComponentRef ouCref;
 output Boolean negate;
algorithm
  (ouCref,negate) :=
  match (inExp)
    local DAE.ComponentRef cr;
    case (DAE.CREF(componentRef=cr)) then (cr,false);
    case (DAE.UNARY(exp = DAE.CREF(componentRef=cr))) then (cr,true);
  end match;
end removeAliasEquations2;

protected function mergeAliasVarAttributes
  input BackendDAE.Var inAVar;
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inVars;
  input Boolean negate;
  output BackendDAE.Variables outVars;
algorithm
  outVars :=
  matchcontinue (inAVar,inCref,inVars,negate)
    local
      DAE.ComponentRef name,cr;
      BackendDAE.Var v,var,var1,var2,var3,var4;
      BackendDAE.Variables vars;
      Boolean fixeda, fixedb;
    case (v as BackendDAE.VAR(varName=name),cr,inVars,negate)
      equation
        ((var :: _),_) = BackendVariable.getVar(cr,inVars);
        // fixed
        fixeda = BackendVariable.varFixed(v);
        fixedb = BackendVariable.varFixed(var);
        var1 = BackendVariable.setVarFixed(var,fixeda or fixedb);
        // start
        var2 = mergeStartAttribute(v,var1,negate);
        // nominal
        var3 = mergeNomnialAttribute(v,var2,negate);
        // direction
        var4 = mergeDirection(v,var3);
        // update vars
        vars = BackendVariable.addVar(var4,inVars);        
      then vars;
    case(_,_,inVars,negate) then inVars;
  end matchcontinue;
end mergeAliasVarAttributes;

protected function mergeStartAttribute
  input BackendDAE.Var inAVar;
  input BackendDAE.Var inVar;
  input Boolean negate;
  output BackendDAE.Var outVar;
algorithm
  outVar :=
  matchcontinue (inAVar,inVar,negate)
    local
      BackendDAE.Var v,var,var1;
      Option<DAE.VariableAttributes> attr,attr1;
      DAE.Exp e,e1;
    case (v as BackendDAE.VAR(values = attr),var as BackendDAE.VAR(values = attr1),negate)
      equation 
        // start
        e = BackendVariable.varStartValueFail(v);
        mergeStartAttribute1(attr1);
        e1 = Util.if_(negate,Expression.negate(e),e);
        var1 = BackendVariable.setVarStartValue(var,e1);
      then var1;
    case(_,inVar,_) then inVar;
  end matchcontinue;
end mergeStartAttribute;

protected function mergeStartAttribute1
  input Option<DAE.VariableAttributes> attr;
algorithm
  () :=
  matchcontinue (attr)
    local
      DAE.Exp e;
    case (attr)
      equation 
        false = DAEUtil.hasStartAttr(attr);
      then ();
    case (attr)
      equation 
        e = DAEUtil.getStartAttr(attr);
        true = Expression.isZero(e);
      then ();
  end matchcontinue;
end mergeStartAttribute1;

protected function mergeNomnialAttribute
  input BackendDAE.Var inAVar;
  input BackendDAE.Var inVar;
  input Boolean negate;
  output BackendDAE.Var outVar;
algorithm
  outVar :=
  matchcontinue (inAVar,inVar,negate)
    local
      BackendDAE.Var v,var,var1;
      Option<DAE.VariableAttributes> attr,attr1;
      DAE.Exp e,e_1,e1,esum,eaverage;
    case (v as BackendDAE.VAR(values = attr),var as BackendDAE.VAR(values = attr1),negate)
      equation 
        // nominal
        e = BackendVariable.varNominalValue(v);
        e1 = BackendVariable.varNominalValue(var);
        e_1 = Util.if_(negate,Expression.negate(e),e);
        esum = Expression.makeSum({e_1,e1});
        eaverage = Expression.expDiv(esum,DAE.RCONST(2.0)); // Real is lecal because only Reals have nominal attribute 
        var1 = BackendVariable.setVarNominalValue(var,ExpressionSimplify.simplify(eaverage));
      then var1;
    case (v as BackendDAE.VAR(values = attr),var as BackendDAE.VAR(values = attr1),negate)
      equation 
        // nominal
        e = BackendVariable.varNominalValue(v);
        e_1 = Util.if_(negate,Expression.negate(e),e);
        var1 = BackendVariable.setVarNominalValue(var,e_1);
      then var1;
    case(_,inVar,_) then inVar;
  end matchcontinue;
end mergeNomnialAttribute;

protected function mergeDirection
  input BackendDAE.Var inAVar;
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar :=
  matchcontinue (inAVar,inVar)
    local
      BackendDAE.Var v,var,var1;
      Option<DAE.VariableAttributes> attr,attr1;
      DAE.Exp e,e1;
    case (v as BackendDAE.VAR(varDirection = DAE.INPUT()),var as BackendDAE.VAR(varDirection = DAE.OUTPUT()))
      equation 
        var1 = BackendVariable.setVarDirection(var,DAE.INPUT());
      then var1;
    case (v as BackendDAE.VAR(varDirection = DAE.INPUT()),var as BackendDAE.VAR(varDirection = DAE.BIDIR()))
      equation 
        var1 = BackendVariable.setVarDirection(var,DAE.INPUT());
      then var1;        
    case (v as BackendDAE.VAR(varDirection = DAE.OUTPUT()),var as BackendDAE.VAR(varDirection = DAE.BIDIR()))
      equation 
        var1 = BackendVariable.setVarDirection(var,DAE.OUTPUT());
      then var1;
    case(_,inVar) then inVar;
  end matchcontinue;
end mergeDirection;

/* 
 * remove new simply equations stuff
 */

public function removeSimpleEquationsX
"function: removeSimpleEquations
  autor: Frenkel TUD 2011-04
  This function moves simple equations on the form a=b and a=const and a=f(not time)
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.BackendDAE inDlow;
  input DAE.FunctionTree inFunctionTree;
  input Option<BackendDAE.IncidenceMatrix> inM;
  input Option<BackendDAE.IncidenceMatrixT> inMT;
  output BackendDAE.BackendDAE outDlow;
  output Option<BackendDAE.IncidenceMatrix> outM;
  output Option<BackendDAE.IncidenceMatrixT> outMT;
algorithm
  (outDlow,outM,outMT):=
  match (inDlow,inFunctionTree,inM,inMT)
    local
      BackendDAE.BackendDAE dlow;
      DAE.FunctionTree funcs;
      BackendDAE.IncidenceMatrix m,m_1;
      BackendDAE.IncidenceMatrixT mT,mT_1;
      VarTransform.VariableReplacements repl,repl_1;
      BackendDAE.BinTree movedVars,movedAVars;
      list<Integer> meqns;
      BackendDAE.Variables ordvars,knvars,exobj,ordvars1,knvars1,ordvars2,knvars2,ordvars3;
      BackendDAE.AliasVariables aliasVars,aliasVars1;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1,inieqns1,remeqns1;
      array<BackendDAE.MultiDimEquation> arreqns,arreqns1,arreqns2;
      array<DAE.Algorithm> algorithms,algorithms1,algorithms2;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;      
    case (dlow,funcs,inM,inMT)
      equation
        (m,mT) = BackendDAEUtil.getIncidenceMatrixfromOption(dlow,inM,inMT);
        repl = VarTransform.emptyReplacements();
        // check equations
        (m_1,(dlow,mT_1,repl_1,movedVars,movedAVars,meqns)) = traverseIncidenceMatrixX(m,removeSimpleEquationsFinder,(dlow,mT,repl,BackendDAE.emptyBintree,BackendDAE.emptyBintree,{}));
        BackendDAE.DAE(ordvars,knvars,exobj,aliasVars,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc) = dlow;
        // delete alias variables from orderedVars
        ordvars1 = BackendVariable.deleteVars(movedAVars,ordvars);
        // move changed variables 
        (ordvars2,knvars1) = BackendVariable.moveVariables(ordvars1,knvars,movedVars);
        // remove changed eqns
        eqns1 = BackendEquation.equationDelete(eqns,meqns);
        // replace moved vars in vars,knvars,aliasVars,ineqns,remeqns
        ordvars3 = ordvars2;
        knvars2 = knvars1;
        aliasVars1 = aliasVars;
        inieqns1 = inieqns;
        arreqns1 = arreqns;
        algorithms1 = algorithms;
        remeqns1 = remeqns;
        arreqns2 = arreqns1;
        algorithms2 = algorithms1;
      then (BackendDAE.DAE(ordvars3,knvars1,exobj,aliasVars1,eqns1,remeqns1,inieqns1,arreqns2,algorithms2,einfo,eoc),NONE(),NONE());
  end match;        
end removeSimpleEquationsX;

protected function removeSimpleEquationsFinder
"autor: Frenkel TUD 2010-12"
 input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix, tuple<BackendDAE.BackendDAE,BackendDAE.IncidenceMatrixT,VarTransform.VariableReplacements,BackendDAE.BinTree,BackendDAE.BinTree,list<Integer>>> inTpl;
 output tuple<list<Integer>,BackendDAE.IncidenceMatrix, tuple<BackendDAE.BackendDAE,BackendDAE.IncidenceMatrixT,VarTransform.VariableReplacements,BackendDAE.BinTree,BackendDAE.BinTree,list<Integer>>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.IncidenceMatrixElement elem;
      Integer pos,pos_1,l,i;
      BackendDAE.IncidenceMatrix m,m1,mT,mT1;
      BackendDAE.BackendDAE dae,dae1,dae2;
      VarTransform.VariableReplacements repl,repl_1;
      BackendDAE.BinTree mvars,mvars_1,mavars,mavars_1;
      list<Integer> meqns,vareqns,meqns1,vareqns1;
      BackendDAE.Variables v,kn,v1,v2;
      BackendDAE.EquationArray eqns,eqns1;
      BackendDAE.Var var;
      DAE.ComponentRef cr;
      DAE.Exp exp;
      
    case ((elem,pos,m,(dae,mT,repl,mvars,mavars,meqns)))
      equation
        // check number of vars in eqns
        l = listLength(elem);
        true = intLt(listLength(elem),3);
        (cr,i,exp,dae1,mvars_1,mavars_1) = simpleEquationX(elem,l,pos,dae,mvars,mavars);
        // equations of var
        vareqns = mT[i];
        vareqns1 = Util.listRemoveOnTrue(pos,intEq,vareqns);
        // replace var=exp in vareqns
        // dae1 = BackendDAEUtil.replaceVarinEqns(cr,exp,vareqns1,dae);
        dae2 = dae1;
        // update IncidenceMatrix
        (m1,mT1) = BackendDAEUtil.updateIncidenceMatrix(dae2,m,mT,vareqns1);
        // update Replacements
        repl_1 = VarTransform.addReplacement(repl, cr, exp);
        pos_1 = pos-1;
      then ((vareqns1,m,(dae2,mT1,repl_1,mvars_1,mavars_1,pos_1::meqns)));
    case ((elem,pos,m,(dae,mT,repl,mvars,mavars,meqns))) then (({},m,(dae,mT,repl,mvars,mavars,meqns))); 
  end matchcontinue;
end removeSimpleEquationsFinder;

protected function simpleEquationX 
" function: simpleEquationX
  autor: Frenkel TUD 2011-04"
  input BackendDAE.IncidenceMatrixElement elem;
  input Integer length;
  input Integer pos;
  input BackendDAE.BackendDAE dae;
  input BackendDAE.BinTree mvars;
  input BackendDAE.BinTree mavars;
  output DAE.ComponentRef outCr;
  output Integer outPos;  
  output DAE.Exp outExp;
  output BackendDAE.BackendDAE outDae;
  output BackendDAE.BinTree outMvars;
  output BackendDAE.BinTree outMavars;
algorithm
  (outCr,outPos,outExp,outDae,outMvars,outMavars) := matchcontinue(elem,length,pos,dae,mvars,mavars)
    local 
      DAE.ComponentRef cr,cr2;
      Integer i,j,pos_1;
      DAE.Exp es,cre,e1,e2;
      BackendDAE.BinTree newvars; 
      BackendDAE.Variables vars,knvars;
      BackendDAE.Var var,var2,var3;
      BackendDAE.BackendDAE dae1;
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn;
    // a = const
    case({i},length,pos,dae,mvars,mavars) equation 
      vars = BackendVariable.daeVars(dae);  
      var = BackendVariable.getVarAt(vars,i);
      // no State
      false = BackendVariable.isStateVar(var); 
      // try to solve the equation
      pos_1 = pos-1;
      eqns = BackendEquation.daeEqns(dae);
      eqn = BackendDAEUtil.equationNth(eqns,pos_1);
      BackendDAE.EQUATION(exp=e1,scalar=e2) = eqn;
      // variable time not there
      knvars = BackendVariable.daeKnVars(dae);  
      ((_,(false,_,_))) = Expression.traverseExpTopDown(e1, traversingParameterEqnsFinder, (false,vars,knvars));
      ((_,(false,_,_))) = Expression.traverseExpTopDown(e2, traversingParameterEqnsFinder, (false,vars,knvars));
      cr = BackendVariable.varCref(var);
      cre = Expression.crefExp(cr);
     (es,{}) = ExpressionSolve.solve(e1,e2,cre);      
     // add bindExp
     var2 = BackendVariable.setBindExp(var,es);
     // add bindValue if constant
     var3 = setbindValue(es,var2);
     // update vars
     dae1 = BackendVariable.addVarDAE(var3,dae);
     // store changed var
     newvars = BackendDAEUtil.treeAdd(mvars, cr, 0);
   then (cr,i,es,dae,newvars,mavars);
   // a = b 
   case({i,j},length,pos,dae,mvars,mavars) equation
     pos_1 = pos-1;
     eqns = BackendEquation.daeEqns(dae);
     eqn = BackendDAEUtil.equationNth(eqns,pos_1);
     (cr,cr2,e1,e2) = aliasEquation(eqn);
     // select candidate
     (cr,es,dae1,newvars) = selectAlias(cr,i,cr2,j,e1,e2,dae,mavars);
   then (cr,pos,es,dae1,mvars,newvars);
  end matchcontinue;  
end simpleEquationX;

protected function selectAlias
"function selectAlias
  autor Frenkel TUD 2011-04
  select the alis variable. Prefer scalars
  or elements of already replaced arrays or records."
  input DAE.ComponentRef cr1;
  input Integer i;
  input DAE.ComponentRef cr2;
  input Integer j;
  input DAE.Exp e1;
  input DAE.Exp e2;
  input BackendDAE.BackendDAE dae;
  input BackendDAE.BinTree mavars;
  output DAE.ComponentRef cr;
  output DAE.Exp exp;
  output BackendDAE.BackendDAE outDae;
  output BackendDAE.BinTree newvars;
algorithm
  (cr,exp,outDae,mvars) := matchcontinue (cr1,i,cr2,j,e1,e2,dae,mavars)
    local
      DAE.ComponentRef cr;
      BackendDAE.BinTree newvars; 
      BackendDAE.Var var;
      BackendDAE.VarKind kind;
      BackendDAE.BackendDAE dae1;
      BackendDAE.Variables vars,knvars;
    case (cr1,i,cr2,j,e1,e2,dae,mavars)
      equation
        vars = BackendVariable.daeVars(dae);
        var = BackendVariable.getVarAt(vars,i);
        // no State
        false = BackendVariable.isState(cr1, vars) "cr1 not state";
        kind = BackendVariable.varKind(var);
        BackendVariable.isVarKindVariable(kind) "cr1 not constant";
        knvars = BackendVariable.daeKnVars(dae);        
        false = BackendVariable.isTopLevelInputOrOutput(cr1,vars,knvars);
        failure( _ = BackendVariable.varStartValueFail(var));
        Debug.fcall("debugAlias",print,"Alias Equation " +& ComponentReference.printComponentRefStr(cr1) +& " = " +& ExpressionDump.printExpStr(e2) +& " found.\n"); 
        // store changed var
        newvars = BackendDAEUtil.treeAdd(mavars, cr1, 0);
        dae1 = BackendDAEUtil.updateAliasVariablesDAE(cr1,e2,dae);
      then
        (cr1,e2,dae1,newvars);
    case (cr1,i,cr2,j,e1,e2,dae,mavars)
      equation
        vars = BackendVariable.daeVars(dae);
        var = BackendVariable.getVarAt(vars,j);
        // no State
        false = BackendVariable.isState(cr2, vars) "cr1 not state";
        kind = BackendVariable.varKind(var);
        BackendVariable.isVarKindVariable(kind) "cr1 not constant";
        knvars = BackendVariable.daeKnVars(dae);        
        false = BackendVariable.isTopLevelInputOrOutput(cr2,vars,knvars);
        failure( _ = BackendVariable.varStartValueFail(var));
        Debug.fcall("debugAlias",print,"Alias Equation " +& ComponentReference.printComponentRefStr(cr2) +& " = " +& ExpressionDump.printExpStr(e1) +& " found.\n"); 
        // store changed var
        newvars = BackendDAEUtil.treeAdd(mavars, cr2, 0);
        dae1 = BackendDAEUtil.updateAliasVariablesDAE(cr2,e1,dae);
      then
        (cr2,e1,dae1,newvars);        
  end matchcontinue;
end selectAlias;

protected function aliasEquation
"function aliasEquation
  autor Frenkel TUD 2011-04
  Returns the two sides of an alias equation as expressions and cref.
  If the equation is not simple, this function will fail."
  input BackendDAE.Equation eqn;
  output DAE.ComponentRef cr1;
  output DAE.ComponentRef cr2;
  output DAE.Exp e1;
  output DAE.Exp e2;
algorithm
  (cr1,cr2,e1,e2) := match (eqn)
      local
        DAE.Exp e,ne;
      // a = der(b);
      case (BackendDAE.EQUATION(exp=e1 as DAE.CREF(componentRef = cr1),scalar=e2 as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr2)})))
        then (cr1,cr2,e1,e2);
      // der(a) = b;
      case (BackendDAE.EQUATION(exp=e1 as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr1)}),scalar=e2 as DAE.CREF(componentRef = cr2)))
        then (cr1,cr2,e1,e2);
      // a = -der(b);
      case (BackendDAE.EQUATION(exp=e1 as DAE.CREF(componentRef = cr1),scalar=e2 as  DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr2)}))))
        then (cr1,cr2,e1,e2);
      case (BackendDAE.EQUATION(exp=e1 as DAE.CREF(componentRef = cr1),scalar=e2 as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr2)}))))
        then (cr1,cr2,e1,e2);
      // -der(a) = b;
      case (BackendDAE.EQUATION(exp=e1 as  DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr1)})),scalar=e2 as DAE.CREF(componentRef = cr2)))
        then (cr1,cr2,e1,e2);
      case (BackendDAE.EQUATION(exp=e1 as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr1)})),scalar=e2 as DAE.CREF(componentRef = cr2)))
        then (cr1,cr2,e1,e2);
      // -a = der(b);
      case (BackendDAE.EQUATION(exp=e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),scalar=e2 as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr2)})))
        then (cr1,cr2,e1,e2);
      case (BackendDAE.EQUATION(exp=e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),scalar=e2 as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr2)})))
        then (cr1,cr2,e1,e2);
      // der(a) = -b;
      case (BackendDAE.EQUATION(exp=e1 as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr1)}),scalar=e2 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr2))))
        then (cr1,cr2,e1,e2);
      case (BackendDAE.EQUATION(exp=e1 as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr1)}),scalar=e2 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr2))))
        then (cr1,cr2,e1,e2);
      // a = b;
      case (BackendDAE.EQUATION(exp=e1 as DAE.CREF(componentRef = cr1),scalar=e2 as  DAE.CREF(componentRef = cr2)))
        then (cr1,cr2,e1,e2);
      // a = -b;
      case (BackendDAE.EQUATION(exp=e1 as DAE.CREF(componentRef = cr1),scalar=e2 as  DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr2))))
        then (cr1,cr2,e1,e2);
      case (BackendDAE.EQUATION(exp=e1 as DAE.CREF(componentRef = cr1),scalar=e2 as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr2))))
        then (cr1,cr2,e1,e2);
      // -a = b;
      case (BackendDAE.EQUATION(exp=e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),scalar=e2 as  DAE.CREF(componentRef = cr2)))
        then (cr1,cr2,e1,e2);
      case (BackendDAE.EQUATION(exp=e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),scalar=e2 as  DAE.CREF(componentRef = cr2)))
        then (cr1,cr2,e1,e2);
      // a + b = 0
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne);
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne);
      // a - b = 0
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2);
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2);   
      // -a + b = 0
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2);
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2);
      // -a - b = 0
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne);
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne);                  
      // 0 = a + b 
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne);
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne);
      // 0 = a - b 
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2);
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2);   
      // 0 = -a + b 
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2);
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2);
      // 0 = -a - b 
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne);
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne);
  end match;
end aliasEquation;

protected function traverseIncidenceMatrixX 
" function: traverseIncidenceMatrix
  autor: Frenkel TUD 2010-12"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.IncidenceMatrix inM;
  input FuncType func;
  input Type_a inTypeA;
  output BackendDAE.IncidenceMatrix outM;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix,Type_a> inTpl;
    output tuple<list<Integer>,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;
algorithm
  (outM,outTypeA) := traverseIncidenceMatrix1X(inM,func,1,arrayLength(inM),inTypeA);
end traverseIncidenceMatrixX;

protected function traverseIncidenceMatrix1X 
" function: traverseIncidenceMatrix1
  autor: Frenkel TUD 2010-12"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.IncidenceMatrix inM;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  input Type_a inTypeA;
  output BackendDAE.IncidenceMatrix outM;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix,Type_a> inTpl;
    output tuple<list<Integer>,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;
algorithm
  (outM,outTypeA) := matchcontinue(inM,func,pos,len,inTypeA)
    local 
      BackendDAE.IncidenceMatrix m,m1,m2;
      Type_a extArg,extArg1;
      list<Integer> eqns,eqns1;
    
    case(inM,func,pos,len,inTypeA) equation 
      true = intGt(pos,len);
    then (inM,inTypeA);
    
    case(inM,func,pos,len,inTypeA) equation
      ((eqns,m,extArg)) = func((inM[pos],pos,inM,inTypeA));
      eqns1 = Util.listRemoveOnTrue(pos,intGt,eqns);
      (m,extArg) = traverseIncidenceMatrixList(eqns1,inM,func,arrayLength(inM),pos,inTypeA);
      (m2,extArg1) = traverseIncidenceMatrix1X(m,func,pos+1,len,extArg);
    then (m2,extArg1);
  end matchcontinue;
end traverseIncidenceMatrix1X;

protected function traverseIncidenceMatrixList 
" function: traverseIncidenceMatrixList
  autor: Frenkel TUD 2011-04"
  replaceable type Type_a subtypeof Any;
  input list<Integer> inLst "elements to traverse";
  input BackendDAE.IncidenceMatrix inM;
  input FuncType func;
  input Integer len "length of array";
  input Integer maxpos "do not go further than this position";
  input Type_a inTypeA;
  output BackendDAE.IncidenceMatrix outM;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix,Type_a> inTpl;
    output tuple<list<Integer>,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;
algorithm
  (outM,outTypeA) := matchcontinue(inLst,inM,func,len,maxpos,inTypeA)
    local 
      BackendDAE.IncidenceMatrix m,m1;
      Type_a extArg,extArg1;
      list<Integer> rest,eqns,eqns1,alleqns;
      Integer pos;
          
    case({},inM,_,_,_,inTypeA) then (inM,inTypeA);
    
    case(pos::rest,inM,func,len,maxpos,inTypeA) equation
      // do not leave the list
      true = intLt(pos,len+1);
      // do not more than necesary
      true = intLt(pos,maxpos);
      ((eqns,m,extArg)) = func((inM[pos],pos,inM,inTypeA));
      eqns1 = Util.listRemoveOnTrue(maxpos,intGt,eqns);
      alleqns = Util.listListUnionOnTrue({rest, eqns1},intEq);
      (m1,extArg1) = traverseIncidenceMatrixList(alleqns,m,func,len,maxpos,extArg);
    then (m1,extArg1);
  end matchcontinue;
end traverseIncidenceMatrixList;

/*
 * remove parameter equations
 */
public function removeParameterEqns
" function: removeParameterEqns
  autor: Frenkel TUD 2010-12
  Detect all equations with only one time depend variable and 
  check if it is a time independend variable. In case of time 
  independendce it change the variability from VARIABLE to Parameter
  and add a bind expression."
  input BackendDAE.BackendDAE inDlow;
  input DAE.FunctionTree inFunctionTree;
  input Option<BackendDAE.IncidenceMatrix> inM;
  input Option<BackendDAE.IncidenceMatrixT> inMT;
  output BackendDAE.BackendDAE outDlow;
  output Option<BackendDAE.IncidenceMatrix> outM;
  output Option<BackendDAE.IncidenceMatrixT> outMT;
algorithm
  (outDlow,outM,outMT):=
  match (inDlow,inFunctionTree,inM,inMT)
    local
      BackendDAE.BackendDAE dlow,dlow1;
      DAE.FunctionTree funcs;
      Option<BackendDAE.IncidenceMatrix> om,omT;
      BackendDAE.IncidenceMatrix m,m_1,m_2;
      BackendDAE.IncidenceMatrixT mT,mT_1;
      BackendDAE.Variables ordvars,knvars,exobj,ordvars1,knvars1,ordvars2,knvars2;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1,eqns2;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.BinTree movedVars;
      list<Integer> meqns;
    case (dlow as BackendDAE.DAE(ordvars,knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc),funcs,inM,inMT)
      equation
        (m,mT) = BackendDAEUtil.getIncidenceMatrixfromOption(dlow,inM,inMT);
        // for now check interactive flag to avoid errors there
        // false = RTOpts.debugFlag("");
        // check equations
        (m_1,(ordvars1,knvars1,eqns1,_,movedVars,meqns)) = traverseIncidenceMatrix(m,removeParameterEqnsFinder,(ordvars,knvars,eqns,mT,BackendDAE.emptyBintree,{}));
        // move changed variables 
        (ordvars2,knvars2) = BackendVariable.moveVariables(ordvars1,knvars1,movedVars);
        // remove changed eqns
        eqns2 = BackendEquation.equationDelete(eqns1,meqns);
        // update IncidenceMatrix
        dlow1 = BackendDAE.DAE(ordvars2,knvars2,exobj,av,eqns2,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
        m_2 = BackendDAEUtil.incidenceMatrix(dlow1, BackendDAE.NORMAL());
        // update transposed IncidenceMatrix
        mT_1 = BackendDAEUtil.transposeMatrix(m_2);
      then (dlow1,SOME(m_2),SOME(mT_1));
  end match;        
end removeParameterEqns;

protected function traverseIncidenceMatrix 
" function: traverseIncidenceMatrix
  autor: Frenkel TUD 2010-12"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.IncidenceMatrix inM;
  input FuncType func;
  input Type_a inTypeA;
  output BackendDAE.IncidenceMatrix outM;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix,Type_a> inTpl;
    output tuple<BackendDAE.IncidenceMatrixElement,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;
algorithm
  (outM,outTypeA) := traverseIncidenceMatrix1(inM,func,1,arrayLength(inM),inTypeA);
end traverseIncidenceMatrix;

protected function traverseIncidenceMatrix1 
" function: traverseIncidenceMatrix1
  autor: Frenkel TUD 2010-12"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.IncidenceMatrix inM;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  input Type_a inTypeA;
  output BackendDAE.IncidenceMatrix outM;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix,Type_a> inTpl;
    output tuple<BackendDAE.IncidenceMatrixElement,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;
algorithm
  (outM,outTypeA) := matchcontinue(inM,func,pos,len,inTypeA)
    local 
      BackendDAE.IncidenceMatrix m,m1,m2;
      BackendDAE.IncidenceMatrixElement newElt;
      Type_a extArg,extArg1;
    
    case(inM,func,pos,len,inTypeA) equation 
      true = pos > len;
    then (inM,inTypeA);
    
    case(inM,func,pos,len,inTypeA) equation
      ((newElt,m,extArg)) = func((inM[pos],pos,inM,inTypeA));
      m1 = arrayUpdate(m,pos,newElt);
      (m2,extArg1) = traverseIncidenceMatrix1(m1,func,pos+1,len,extArg);
    then (m2,extArg1);
  end matchcontinue;
end traverseIncidenceMatrix1;

protected function removeParameterEqnsFinder
"autor: Frenkel TUD 2010-12"
 input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix, tuple<BackendDAE.Variables,BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.IncidenceMatrixT,BackendDAE.BinTree,list<Integer>>> inTpl;
 output tuple<BackendDAE.IncidenceMatrixElement,BackendDAE.IncidenceMatrix, tuple<BackendDAE.Variables,BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.IncidenceMatrixT,BackendDAE.BinTree,list<Integer>>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.IncidenceMatrixElement elem;
      BackendDAE.IncidenceMatrix m,m1,m2;
      Integer pos;
      BackendDAE.Variables v,kn,v1,v2;
      BackendDAE.EquationArray eqns,eqns1;
      BackendDAE.Var var,var2,var3;
      DAE.ComponentRef cr;
      DAE.Exp e1,e2,cre,es;
      Integer i,pos_1;
      BackendDAE.Equation eqn;
      BackendDAE.IncidenceMatrixT mT,mT1;
      BackendDAE.BinTree mvars,mvars_1,mvars_2;
      list<Integer> meqns,vareqns,meqns1,vareqns1;
    case ((elem,pos,m,(v,kn,eqns,mT,mvars,meqns)))
      equation
        // check number of vars in eqns
        //true = intEq(1,listLength(elem));
        {i} = elem;
        var = BackendVariable.getVarAt(v,i);
        // no State
        false = BackendVariable.isStateVar(var);
        // no toplevel input or Output
        cr = BackendVariable.varCref(var);
        false = BackendVariable.isTopLevelInputOrOutput(cr,v,kn);
        // not already changed
        failure(_ = BackendDAEUtil.treeGet(mvars, cr));
        // try to solve the equation
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        BackendDAE.EQUATION(exp=e1,scalar=e2) = eqn;
        // variable time not there
        ((_,(false,_,_))) = Expression.traverseExpTopDown(e1, traversingParameterEqnsFinder, (false,v,kn));
        ((_,(false,_,_))) = Expression.traverseExpTopDown(e2, traversingParameterEqnsFinder, (false,v,kn));
        cre = Expression.crefExp(cr);
        (es,{}) = ExpressionSolve.solve(e1,e2,cre);
        false = Expression.isConst(es);
        // set kind to PARAM
        // do not set varKind because of simulation results
        //var1 = BackendVariable.setVarKind(var,BackendDAE.PARAM);
        // add bindExp
        var2 = BackendVariable.setBindExp(var,es);
        // add bindValue if constant
        var3 = setbindValue(es,var2);
        // update vars
        v1 = BackendVariable.addVar(var3,v);
        // store changed var
        mvars_1 = BackendDAEUtil.treeAdd(mvars, cr, 0);
        // equations of var
        vareqns = mT[i];
        // remove var from IncidenceMatrix 
        m1 = removeVarfromIncidenceMatrix(vareqns,i,m);
        // remove not yet visited equations
        vareqns1 = Util.listSelect1(vareqns,pos,intLt);
       (m2,(v2,kn,eqns1,mT1,mvars_2,meqns1)) = traverseIncidenceMatrix2(vareqns1,m1,removeParameterEqnsFinder,(v1,kn,eqns,mT,mvars_1,pos_1::meqns));
      then (({},m2,(v2,kn,eqns1,mT1,mvars_2,meqns1)));
    case ((elem,pos,m,(v,kn,eqns,mT,mvars,meqns))) then ((elem,m,(v,kn,eqns,mT,mvars,meqns))); 
  end matchcontinue;
end removeParameterEqnsFinder;

public function traversingParameterEqnsFinder "
Author: Frenkel 2010-12"
  input tuple<DAE.Exp, tuple<Boolean,BackendDAE.Variables,BackendDAE.Variables> > inExp;
  output tuple<DAE.Exp, Boolean, tuple<Boolean,BackendDAE.Variables,BackendDAE.Variables> > outExp;
algorithm 
  outExp := matchcontinue(inExp)
    local
      DAE.Exp e;      
      Boolean b,b1,b2;
      BackendDAE.Variables vars,knvars;
      DAE.ComponentRef cr;
    
    case((e as DAE.CREF(DAE.CREF_IDENT(ident = "time",subscriptLst = {}),_), (_,vars,knvars)))
      then ((e,false,(true,vars,knvars)));
    case((e as DAE.CREF(componentRef = cr),(b,vars,knvars)))
      equation
        b1 = BackendVariable.isTopLevelInputOrOutput(cr,vars,knvars);
        b2 = b or b1;
      then
        ((e,not b2,(b2,vars,knvars)));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst = {_,_}), (_,vars,knvars))) then ((e,false,(true,vars,knvars) ));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "pre"), expLst = {_}), (_,vars,knvars))) then ((e,false,(true,vars,knvars) ));
    case((e,(b,vars,knvars))) then ((e,not b,(b,vars,knvars)));
    
  end matchcontinue;
end traversingParameterEqnsFinder;

protected function setbindValue
" function: setbindValue
  autor: Frenkel TUD 2010-12"
  input DAE.Exp inExp;
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue(inExp,inVar)
    local 
     Values.Value value; 
     BackendDAE.Var var;     
    case(inExp,inVar)
      equation
        true = Expression.isConst(inExp);
        value = ValuesUtil.expValue(inExp);
        var = BackendVariable.setBindValue(inVar,value);
      then var;
    case(_,inVar) then inVar;        
  end matchcontinue;
end setbindValue;

protected function traverseIncidenceMatrix2 
" function: traverseIncidenceMatrix2
  autor: Frenkel TUD 2010-12"
  replaceable type Type_a subtypeof Any; 
  input list<Integer> inEqns;
  input BackendDAE.IncidenceMatrix inM;
  input FuncType func;  
  input Type_a inTypeA;
  output BackendDAE.IncidenceMatrix outM;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix,Type_a> inTpl;
    output tuple<BackendDAE.IncidenceMatrixElement,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;  
algorithm
  (outM,outTypeA) := match(inEqns,inM,func,inTypeA)
    local 
      Integer pos;
      list<Integer> rest;
      BackendDAE.IncidenceMatrix m,m1,m2;
      BackendDAE.IncidenceMatrixElement newElt;
      Type_a extArg,extArg1;
    
    case({},inM,_,inTypeA) then (inM,inTypeA);
    
    case(pos::rest,inM,func,inTypeA)
      equation
      ((newElt,m,extArg)) = func((inM[pos],pos,inM,inTypeA));
      m1 = arrayUpdate(m,pos,newElt);
      (m2,extArg1) = traverseIncidenceMatrix2(rest,m1,func,extArg);
    then (m2,extArg1);
  end match;
end traverseIncidenceMatrix2;

protected function removeVarfromIncidenceMatrix
" function: traverseIncidenceMatrix2
  autor: Frenkel TUD 2010-12"
  input list<Integer> inEqns;
  input Integer inVar;
  input BackendDAE.IncidenceMatrix inM;
  output BackendDAE.IncidenceMatrix outM;
algorithm
  outM := match(inEqns,inVar,inM)
    local 
      Integer pos;
      list<Integer> rest;
      BackendDAE.IncidenceMatrix m,m1;
      BackendDAE.IncidenceMatrixElement newElt;
    
    case({},_,inM) then inM;
    
    case(pos::rest,inVar,inM)
      equation
      newElt = Util.listRemoveOnTrue(inVar,intEq,inM[pos]);
      m = arrayUpdate(inM,pos,newElt);
      m1 = removeVarfromIncidenceMatrix(rest,inVar,inM);
    then m1;
  end match;
end removeVarfromIncidenceMatrix;

/*  
 * remove protected paramters stuff 
 */ 

public function removeProtectedParameters
"function: removeProtectedParameters
  autor Frenkel TUD"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree inFunctionTree;
  input Option<BackendDAE.IncidenceMatrix> inM;
  input Option<BackendDAE.IncidenceMatrix> inMT;
  output BackendDAE.BackendDAE outDAE;
  output Option<BackendDAE.IncidenceMatrix> outM;
  output Option<BackendDAE.IncidenceMatrix> outMT;
algorithm
  (outDAE,outM,outMT):=
  match (inDAE,inFunctionTree,inM,inMT)
    local
      DAE.FunctionTree funcs;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Variables vars,vars_1,knvars,exobj,knvars_1,knvars_2;
      BackendDAE.AliasVariables av,varsAliases;
      BackendDAE.EquationArray eqns,eqns1,remeqns,remeqns1,inieqns,inieqns1;
      array<BackendDAE.MultiDimEquation> arreqns,arreqns1;
      array<DAE.Algorithm> algorithms,algorithms1;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      VarTransform.VariableReplacements repl,repl1;
      list<BackendDAE.Equation> eqns_1,seqns,lsteqns,reqns,ieqns;
      list<BackendDAE.MultiDimEquation> lstarreqns,lstarreqns1;
      list<DAE.Algorithm> algs,algs_1;
      
    case (BackendDAE.DAE(vars,knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc),funcs,m,mT)
      equation      
        repl = VarTransform.emptyReplacements();
        lsteqns = BackendDAEUtil.equationList(eqns);       
        lstarreqns = arrayList(arreqns);       
        algs = arrayList(algorithms);       
        repl1 = BackendVariable.traverseBackendDAEVars(knvars,protectedParametersFinder,repl);

        Debug.fcall("dumpPPrepl", VarTransform.dumpReplacements, repl1);
        eqns_1 = BackendVarTransform.replaceEquations(lsteqns, repl1);
        lstarreqns1 = BackendVarTransform.replaceMultiDimEquations(lstarreqns, repl1);
        algs_1 = BackendVarTransform.replaceAlgorithms(algs,repl1);
        eqns1 = BackendDAEUtil.listEquation(eqns_1);
        arreqns1 = listArray(lstarreqns1);
        algorithms1 = listArray(algs_1);
      then
        (BackendDAE.DAE(vars,knvars,exobj,av,eqns1,remeqns,inieqns,arreqns1,algorithms1,einfo,eoc),NONE(),NONE());
  end match;        
end removeProtectedParameters;

protected function protectedParametersFinder
"autor: Frenkel TUD 2011-03"
 input tuple<BackendDAE.Var, VarTransform.VariableReplacements> inTpl;
 output tuple<BackendDAE.Var, VarTransform.VariableReplacements> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      VarTransform.VariableReplacements repl,repl_1;
      DAE.ComponentRef varName;
      Option< .DAE.VariableAttributes> values;
      DAE.Exp exp;
      Values.Value bindValue;
    case ((v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindExp=SOME(exp),values=values),repl))
      equation
        true = DAEUtil.getProtectedAttr(values);
        repl_1 = VarTransform.addReplacement(repl, varName, exp);
      then ((v,repl_1));
    case ((v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindValue=SOME(bindValue),values=values),repl))
      equation
        true = DAEUtil.getProtectedAttr(values);
        true = BackendVariable.varFixed(v);
        exp = ValuesUtil.valueExp(bindValue);
        repl_1 = VarTransform.addReplacement(repl, varName, exp);
      then ((v,repl_1));
    case inTpl then inTpl; 
  end matchcontinue;
end protectedParametersFinder;

/*  
 * tearing system of equations stuff 
 */ 

public function tearingSystem
" function: tearingSystem
  autor: Frenkel TUD
  Pervormes tearing method on a system.
  This is just a funktion to check the flack tearing.
  All other will be done at tearingSystem1."
  input BackendDAE.BackendDAE inDlow;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<list<Integer>> inComps;
  output BackendDAE.BackendDAE outDlow;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<list<Integer>> outComps;
  output list<list<Integer>> outResEqn;
  output list<list<Integer>> outTearVar;
algorithm
  (outDlow,outM,outMT,outV1,outV2,outComps,outResEqn,outTearVar):=
  matchcontinue (inDlow,inM,inMT,inV1,inV2,inComps)
    local
      BackendDAE.BackendDAE dlow,dlow_1,dlow1;
      BackendDAE.IncidenceMatrix m,m_1;
      BackendDAE.IncidenceMatrixT mT,mT_1;
      array<Integer> v1,v2,v1_1,v2_1;
      list<list<Integer>> comps,comps_1;
      list<list<Integer>> r,t;
    case (dlow,m,mT,v1,v2,comps)
      equation
        Debug.fcall("tearingdump", print, "Tearing\n==========\n");
        // get residual eqn and tearing var for each block
        // copy dlow
        dlow1 = copyDaeLowforTearing(dlow);
        (r,t,_,dlow_1,m_1,mT_1,v1_1,v2_1,comps_1) = tearingSystem1(dlow,dlow1,m,mT,v1,v2,comps);
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrix, m_1);
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrixT, mT_1);
        Debug.fcall("tearingdump", BackendDump.dump, dlow_1);
        Debug.fcall("tearingdump", BackendDump.dumpMatching, v1_1);
        Debug.fcall("tearingdump", BackendDump.dumpComponents, comps_1);
        Debug.fcall("tearingdump", print, "==========\n");
        Debug.fcall2("tearingdump", BackendDump.dumpTearing, r,t);
        Debug.fcall("tearingdump", print, "==========\n");
      then
        (dlow_1,m_1,mT_1,v1_1,v2_1,comps_1,r,t);
    case (dlow,m,mT,v1,v2,comps)
      equation
        Debug.fcall("tearingdump", print, "No Tearing\n==========\n");
      then
        (dlow,m,mT,v1,v2,comps,{},{});
  end matchcontinue;
end tearingSystem;

protected function copyDaeLowforTearing
" function: copyDaeLowforTearing
  autor: Frenkel TUD
  Copy the dae to avoid changes in
  vectors."
  input BackendDAE.BackendDAE inDlow;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow:=
  match (inDlow)
    local
      BackendDAE.Variables ordvars,knvars,exobj,ordvars1;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.Value n,size,n1,size1;
      array<Option<BackendDAE.Equation>> arr_1,arr;
      array<list<BackendDAE.CrefIndex>> crefIdxLstArr,crefIdxLstArr1;
      array<list<BackendDAE.StringIndex>> strIdxLstArr,strIdxLstArr1;
      BackendDAE.VariableArray varArr;
      Integer bucketSize;
      Integer numberOfVars;
      array<Option<BackendDAE.Var>> varOptArr,varOptArr1;
    case (BackendDAE.DAE(ordvars,knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc))
      equation
        BackendDAE.VARIABLES(crefIdxLstArr,strIdxLstArr,varArr,bucketSize,numberOfVars) = ordvars;
        BackendDAE.VARIABLE_ARRAY(n1,size1,varOptArr) = varArr;
        crefIdxLstArr1 = arrayCreate(size1, {});
        crefIdxLstArr1 = Util.arrayCopy(crefIdxLstArr, crefIdxLstArr1);
        strIdxLstArr1 = arrayCreate(size1, {});
        strIdxLstArr1 = Util.arrayCopy(strIdxLstArr, strIdxLstArr1);
        varOptArr1 = arrayCreate(size1, NONE());
        varOptArr1 = Util.arrayCopy(varOptArr, varOptArr1);
        ordvars1 = BackendDAE.VARIABLES(crefIdxLstArr1,strIdxLstArr1,BackendDAE.VARIABLE_ARRAY(n1,size1,varOptArr1),bucketSize,numberOfVars);
        BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr) = eqns;
        arr_1 = arrayCreate(size, NONE());
        arr_1 = Util.arrayCopy(arr, arr_1);
        eqns1 = BackendDAE.EQUATION_ARRAY(n,size,arr_1);
      then
        BackendDAE.DAE(ordvars1,knvars,exobj,av,eqns1,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
  end match;
end copyDaeLowforTearing;

protected function tearingSystem1
" function: tearingSystem1
  autor: Frenkel TUD
  Main loop. Check all Comps and start tearing if
  strong connected components there"
  input BackendDAE.BackendDAE inDlow;
  input BackendDAE.BackendDAE inDlow1;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<list<Integer>> inComps;
  output list<list<Integer>> outResEqn;
  output list<list<Integer>> outTearVar;
  output BackendDAE.BackendDAE outDlow;
  output BackendDAE.BackendDAE outDlow1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<list<Integer>> outComps;
algorithm
  (outResEqn,outTearVar,outDlow,outDlow1,outM,outMT,outV1,outV2,outComps):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComps)
    local
      BackendDAE.BackendDAE dlow,dlow_1,dlow_2,dlow1,dlow1_1,dlow1_2;
      BackendDAE.IncidenceMatrix m,m_1,m_3,m_4;
      BackendDAE.IncidenceMatrixT mT,mT_1,mT_3,mT_4;
      array<Integer> v1,v2,v1_1,v2_1,v1_2,v2_2,v1_3,v2_3;
      list<list<Integer>> comps,comps_1;
      list<Integer> tvars,comp,comp_1,tearingvars,residualeqns,tearingeqns;
      list<list<Integer>> r,t;
      Integer ll;
      list<DAE.ComponentRef> crlst;
    case (dlow,dlow1,m,mT,v1,v2,{})
      then
        ({},{},dlow,dlow1,m,mT,v1,v2,{});
    case (dlow,dlow1,m,mT,v1,v2,comp::comps)
      equation
        // block ?
        ll = listLength(comp);
        true = ll > 1;
        // get all interesting vars
        (tvars,crlst) = getTearingVars(m,v1,v2,comp,dlow);
        // try tearing
        (residualeqns,tearingvars,tearingeqns,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem2(dlow,dlow1,m,mT,v1,v2,comp,tvars,{},{},{},{},crlst);
        // clean v1,v2,m,mT
        v2_2 = arrayCreate(ll, 0);
        v2_2 = Util.arrayNCopy(v2_1, v2_2,ll);
        v1_2 = arrayCreate(ll, 0);
        v1_2 = Util.arrayNCopy(v1_1, v1_2,ll);
        m_3 = BackendDAEUtil.incidenceMatrix(dlow1_1, BackendDAE.NORMAL());
        mT_3 = BackendDAEUtil.transposeMatrix(m_3);
        (v1_3,v2_3) = correctAssignments(v1_2,v2_2,residualeqns,tearingvars);
        // next Block
        (r,t,dlow_2,dlow1_2,m_4,mT_4,v1_3,v2_3,comps_1) = tearingSystem1(dlow_1,dlow1_1,m_3,mT_3,v1_2,v2_2,comps);
      then
        (residualeqns::r,tearingvars::t,dlow_2,dlow1_2,m_4,mT_4,v1_3,v2_3,comp_1::comps_1);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps)
      equation
        // block ?
        ll = listLength(comp);
        false = ll > 1;
        // next Block
        (r,t,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comps_1) = tearingSystem1(dlow,dlow1,m,mT,v1,v2,comps);
      then
        ({0}::r,{0}::t,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp::comps_1);
  end matchcontinue;
end tearingSystem1;

protected function correctAssignments
" function: correctAssignments
  Correct the assignments"
  input array<BackendDAE.Value> inV1;
  input array<BackendDAE.Value> inV2;
  input list<Integer> inRLst;
  input list<Integer> inTLst;
  output array<BackendDAE.Value> outV1;
  output array<BackendDAE.Value> outV2;
algorithm
  (outV1,outV2):=
  match (inV1,inV2,inRLst,inTLst)
    local
      array<BackendDAE.Value> v1,v2,v1_1,v2_1,v1_2,v2_2;
      list<Integer> rlst,tlst;
      Integer r,t;
    case (v1,v2,{},{}) then (v1,v2);
    case (v1,v2,r::rlst,t::tlst)
      equation
         v1_1 = arrayUpdate(v1,t,r);
         v2_1 = arrayUpdate(v2,r,t);
         (v1_2,v2_2) = correctAssignments(v1_1,v2_1,rlst,tlst);
      then
        (v1_2,v2_2);
  end match;
end correctAssignments;

protected function getTearingVars
" function: getTearingVars
  Substracts all interesting vars for tearing"
  input BackendDAE.IncidenceMatrix inM;
  input array<BackendDAE.Value> inV1;
  input array<BackendDAE.Value> inV2;
  input list<BackendDAE.Value> inComp;
  input BackendDAE.BackendDAE inDlow;
  output list<BackendDAE.Value> outVarLst;
  output list<DAE.ComponentRef> outCrLst;
algorithm
  (outVarLst,outCrLst):=
  match (inM,inV1,inV2,inComp,inDlow)
    local
      BackendDAE.IncidenceMatrix m;
      array<BackendDAE.Value> v1,v2;
      BackendDAE.Value c,v;
      list<BackendDAE.Value> comp,varlst;
      BackendDAE.BackendDAE dlow;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      BackendDAE.Variables ordvars;
      BackendDAE.VariableArray varr;
    case (m,v1,v2,{},dlow) then ({},{});
    case (m,v1,v2,c::comp,dlow as BackendDAE.DAE(orderedVars = ordvars as BackendDAE.VARIABLES(varArr=varr)))
      equation
        v = v2[c];
        BackendDAE.VAR(varName = cr) = BackendVariable.vararrayNth(varr, v-1);
        (varlst,crlst) = getTearingVars(m,v1,v2,comp,dlow);
      then
        (v::varlst,cr::crlst);
  end match;
end getTearingVars;

protected function tearingSystem2
" function: tearingSystem2
  Residualequation loop. This function
  select a residual equation.
  The equation with most connections to
  variables will be selected."
  input BackendDAE.BackendDAE inDlow;
  input BackendDAE.BackendDAE inDlow1;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<Integer> inComp;
  input list<Integer> inTVars;
  input list<Integer> inExclude;
  input list<Integer> inResEqns;
  input list<Integer> inTearVars;
  input list<Integer> inTearEqns;
  input list<DAE.ComponentRef> inCrlst;
  output list<Integer> outResEqns;
  output list<Integer> outTearVars;
  output list<Integer> outTearEqns;
  output BackendDAE.BackendDAE outDlow;
  output BackendDAE.BackendDAE outDlow1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<Integer> outComp;
algorithm
  (outResEqns,outTearVars,outTearEqns,outDlow,outDlow1,outM,outMT,outV1,outV2,outComp):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComp,inTVars,inExclude,inResEqns,inTearVars,inTearEqns,inCrlst)
    local
      BackendDAE.BackendDAE dlow,dlow_1,dlow1,dlow1_1;
      BackendDAE.IncidenceMatrix m,m_1;
      BackendDAE.IncidenceMatrixT mT,mT_1;
      array<Integer> v1,v2,v1_1,v2_1;
      list<Integer> tvars,vars,vars_1,comp,comp_1,exclude;
      String str,str1;
      Integer residualeqn;
      list<Integer> tearingvars,residualeqns,tearingvars_1,residualeqns_1,tearingeqns,tearingeqns_1;
      list<DAE.ComponentRef> crlst;
    case (dlow,dlow1,m,mT,v1,v2,comp,tvars,exclude,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        // get from eqn equation with most variables
        (residualeqn,_) = getMaxfromListList(m,comp,tvars,0,0,exclude);
        true = residualeqn > 0;
        str = intString(residualeqn);
        str1 = stringAppend("ResidualEqn: ", str);
        Debug.fcall("tearingdump", print, str1);
         // get from mT variable with most equations
        vars = m[residualeqn];
        vars_1 = Util.listSelect1(vars,tvars,Util.listContains);
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem3(dlow,dlow1,m,mT,v1,v2,comp,vars_1,{},residualeqn,residualeqns,tearingvars,tearingeqns,crlst);
        // only succeed if tearing need less equations than system size is
//        true = listLength(tearingvars_1) < systemsize;
    then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1);
    case (dlow,dlow1,m,mT,v1,v2,comp,tvars,exclude,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        // get from eqn equation with most variables
        (residualeqn,_) = getMaxfromListList(m,comp,tvars,0,0,exclude);
        true = residualeqn > 0;
        // try next equation
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem2(dlow,dlow1,m,mT,v1,v2,comp,tvars,residualeqn::exclude,residualeqns,tearingvars,tearingeqns,crlst);
      then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1);
    case (dlow,dlow1,m,mT,v1,v2,comp,tvars,exclude,residualeqns,tearingvars,tearingeqns,_)
      equation
        // get from eqn equation with most variables
        (residualeqn,_) = getMaxfromListList(m,comp,tvars,0,0,exclude);
        false = residualeqn > 0;
        Debug.fcall("tearingdump", print, "Select Residual BackendDAE.Equation failed\n");
      then
        fail();
  end matchcontinue;
end tearingSystem2;

protected function tearingSystem3
" function: tearingSystem3
  TearingVar loop. This function select
  a tearing variable. The variable with
  most connections to equations will be
  selected."
  input BackendDAE.BackendDAE inDlow;
  input BackendDAE.BackendDAE inDlow1;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<Integer> inComp;
  input list<Integer> inTVars;
  input list<Integer> inExclude;
  input Integer inResEqn;
  input list<Integer> inResEqns;
  input list<Integer> inTearVars;
  input list<Integer> inTearEqns;
  input list<DAE.ComponentRef> inCrlst;
  output list<Integer> outResEqns;
  output list<Integer> outTearVars;
  output list<Integer> outTearEqns;
  output BackendDAE.BackendDAE outDlow;
  output BackendDAE.BackendDAE outDlow1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<Integer> outComp;
algorithm
  (outResEqns,outTearVars,outTearEqns,outDlow,outDlow1,outM,outMT,outV1,outV2,outComp):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComp,inTVars,inExclude,inResEqn,inResEqns,inTearVars,inTearEqns,inCrlst)
    local
      BackendDAE.BackendDAE dlow,dlow_1,dlow_2,dlow_3,dlow1,dlow1_1,dlow1_2,dlowc,dlowc1;
      BackendDAE.IncidenceMatrix m,m_1,m_2,m_3;
      BackendDAE.IncidenceMatrixT mT,mT_1,mT_2,mT_3;
      array<Integer> v1,v2,v1_1,v2_1,v1_2,v2_2;
      list<list<Integer>> comps,comps_1,onecomp,morecomps;
      list<Integer> vars,comp,comp_1,comp_2,exclude,cmops_flat,onecomp_flat,othereqns,resteareqns;
      String str,str1,str2;
      Integer tearingvar,residualeqn,compcount,tearingeqnid;
      list<Integer> residualeqns,residualeqns_1,tearingvars,tearingvars_1,tearingeqns,tearingeqns_1;
      DAE.ComponentRef cr,crt;
      list<DAE.ComponentRef> crlst;
      DAE.Ident ident,ident_t;
      BackendDAE.VariableArray varr;
      BackendDAE.Value nvars,neqns,memsize;
      BackendDAE.Variables ordvars,vars_1,knvars,exobj,ordvars1,vararray;
      BackendDAE.AliasVariables av;
      BackendDAE.Assignments assign1,assign2,ass1,ass2;
      BackendDAE.EquationArray eqns, eqns_1, eqns_2,remeqns,inieqns,eqns1,eqns1_1,eqns1_2;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      DAE.Exp eqn,scalar,rhs,expCref;

      DAE.ElementSource source;
      DAE.ExpType identType;
      list<DAE.Subscript> subscriptLst;
      BackendDAE.Var var;
    
    case (dlow,dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        vararray = BackendVariable.daeVars(dlow);
        (tearingvar,_) = getMaxfromListListVar(mT,vars,comp,0,0,exclude,vararray);
        // check if tearing var is found
        true = tearingvar > 0;
        str = intString(tearingvar);
        str1 = stringAppend("\nTearingVar: ", str);
        str2 = stringAppend(str1,"\n");
        Debug.fcall("tearingdump", print, str2);
        // copy dlow
        dlowc = copyDaeLowforTearing(dlow);
        BackendDAE.DAE(ordvars as BackendDAE.VARIABLES(varArr=varr),knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc) = dlowc;
        dlowc1 = copyDaeLowforTearing(dlow1);
        BackendDAE.DAE(orderedVars = ordvars1,orderedEqs = eqns1) = dlowc1;
        // add Tearing Var
        var = BackendVariable.vararrayNth(varr, tearingvar-1);
        cr = BackendVariable.varCref(var);
        crt = ComponentReference.prependStringCref("tearingresidual_",cr);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(crt, BackendDAE.VARIABLE(),DAE.BIDIR(),BackendDAE.REAL(),NONE(),NONE(),{},-1,DAE.emptyElementSource,
                            SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(true)),NONE(),NONE(),NONE(),NONE(),NONE())),
                            NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM()), ordvars);
        // replace in residual equation orgvar with Tearing Var
        BackendDAE.EQUATION(eqn,scalar,source) = BackendDAEUtil.equationNth(eqns,residualeqn-1);
        // (eqn_1,replace) =  Expression.replaceExp(eqn,Expression.crefExp(cr),Expression.crefExp(crt));
        // (scalar_1,replace1) =  Expression.replaceExp(scalar,Expression.crefExp(cr),Expression.crefExp(crt));
        // true = replace + replace1 > 0;

        // Add Residual eqn
        rhs = Expression.crefExp(crt);
        eqns_1 = BackendEquation.equationSetnth(eqns,residualeqn-1,BackendDAE.EQUATION(DAE.BINARY(eqn,DAE.SUB(DAE.ET_REAL()),scalar),rhs,source));

        eqns1_1 = BackendEquation.equationSetnth(eqns1,residualeqn-1,BackendDAE.EQUATION(DAE.BINARY(eqn,DAE.SUB(DAE.ET_REAL()),scalar),DAE.RCONST(0.0),source));
        // add equation to calc org var
        expCref = Expression.crefExp(cr);
        eqns_2 = BackendEquation.equationAdd(BackendDAE.EQUATION(DAE.CALL(Absyn.IDENT("tearing"),
                          {},false,true,DAE.ET_REAL(),DAE.NO_INLINE()),
                          expCref, DAE.emptyElementSource),eqns_1);

        tearingeqnid = BackendDAEUtil.equationSize(eqns_2);
        dlow_1 = BackendDAE.DAE(vars_1,knvars,exobj,av,eqns_2,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
        dlow1_1 = BackendDAE.DAE(ordvars1,knvars,exobj,av,eqns1_1,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
        // try causalisation
        m_1 = BackendDAEUtil.incidenceMatrix(dlow_1, BackendDAE.NORMAL());
        mT_1 = BackendDAEUtil.transposeMatrix(m_1);
        nvars = arrayLength(m_1);
        neqns = arrayLength(mT_1);
        memsize = nvars + nvars "Worst case, all eqns are differentiated once. Create nvars2 assignment elements" ;
        assign1 = BackendDAETransform.assignmentsCreate(nvars, memsize, 0);
        assign2 = BackendDAETransform.assignmentsCreate(nvars, memsize, 0);
        // try matching
        BackendDAETransform.checkMatching(dlow_1, (BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT(), BackendDAE.KEEP_SIMPLE_EQN()));
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrix, m_1);
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrixT, mT_1);
        Debug.fcall("tearingdump", BackendDump.dump, dlow_1);
        (ass1,ass2,dlow_2,m_2,mT_2,_,_) = BackendDAETransform.matchingAlgorithm2(dlow_1, m_1, mT_1, nvars, neqns, 1, assign1, assign2, (BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT(), BackendDAE.KEEP_SIMPLE_EQN()),DAEUtil.avlTreeNew(),{},{});
        v1_1 = BackendDAETransform.assignmentsVector(ass1);
        v2_1 = BackendDAETransform.assignmentsVector(ass2);
        (comps) = BackendDAETransform.strongComponents(m_2, mT_2, v1_1, v2_1);
        Debug.fcall("tearingdump", BackendDump.dumpMatching, v1_1);
        Debug.fcall("tearingdump", BackendDump.dumpComponents, comps);
        // check strongComponents and split it into two lists: len(comp)==1 and len(comp)>1
        (morecomps,onecomp) = splitComps(comps);
        // try to solve the equations
        onecomp_flat = Util.listFlatten(onecomp);
        // remove residual equations and tearing eqns
        resteareqns = listAppend(tearingeqnid::tearingeqns,residualeqn::residualeqns);
        othereqns = Util.listSelect1(onecomp_flat,resteareqns,Util.listNotContains);
        eqns1_2 = solveEquations(eqns1_1,othereqns,v2_1,vars_1,crlst);
         // if we have not make alle equations causal select next residual equation
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_3,dlow1_2,m_3,mT_3,v1_2,v2_2,comps_1,compcount) = tearingSystem4(dlow_2,dlow1_1,m_2,mT_2,v1_1,v2_1,comps,residualeqn::residualeqns,tearingvar::tearingvars,tearingeqnid::tearingeqns,comp,0,crlst);
        // check
        true = ((listLength(residualeqns_1) > listLength(residualeqns)) and
                (listLength(tearingvars_1) > listLength(tearingvars)) ) or (compcount == 0);
        // get specifig comps
        cmops_flat = Util.listFlatten(comps_1);
        comp_2 = Util.listSelect1(cmops_flat,comp,Util.listContains);
      then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_3,dlow1_2,m_3,mT_3,v1_2,v2_2,comp_2);
    case (dlow as BackendDAE.DAE(orderedVars = BackendDAE.VARIABLES(varArr=varr)),dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        (tearingvar,_) = getMaxfromListList(mT,vars,comp,0,0,exclude);
        // check if tearing var is found
        true = tearingvar > 0;
        // clear errors
        Error.clearMessages();
        // try next TearingVar
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem3(dlow,dlow1,m,mT,v1,v2,comp,vars,tearingvar::exclude,residualeqn,residualeqns,tearingvars,tearingeqns,crlst);
      then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1);
    case (dlow as BackendDAE.DAE(orderedVars = BackendDAE.VARIABLES(varArr=varr)),dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,_)
      equation
        (tearingvar,_) = getMaxfromListList(mT,vars,comp,0,0,exclude);
        // check if tearing var is found
        false = tearingvar > 0;
        // clear errors
        Error.clearMessages();
        Debug.fcall("tearingdump", print, "Select Tearing BackendDAE.Var failed\n");
      then
        fail();
  end matchcontinue;
end tearingSystem3;

protected function tearingSystem4
" function: tearingSystem4
  autor: Frenkel TUD
  Internal Main loop for additional
  tearing vars and residual eqns."
  input BackendDAE.BackendDAE inDlow;
  input BackendDAE.BackendDAE inDlow1;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<list<Integer>> inComps;
  input list<Integer> inResEqns;
  input list<Integer> inTearVars;
  input list<Integer> inTearEqns;
  input list<Integer> inComp;
  input Integer inCompCount;
  input list<DAE.ComponentRef> inCrlst;
  output list<Integer> outResEqns;
  output list<Integer> outTearVars;
  output list<Integer> outTearEqns;
  output BackendDAE.BackendDAE outDlow;
  output BackendDAE.BackendDAE outDlow1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<list<Integer>> outComp;
  output Integer outCompCount;
algorithm
  (outResEqns,outTearVars,outTearEqns,outDlow,outDlow1,outM,outMT,outV1,outV2,outComp,outCompCount):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComps,inResEqns,inTearVars,inTearEqns,inComp,inCompCount,inCrlst)
    local
      BackendDAE.BackendDAE dlow,dlow_1,dlow_2,dlow1,dlow1_1,dlow1_2;
      BackendDAE.IncidenceMatrix m,m_1,m_2;
      BackendDAE.IncidenceMatrixT mT,mT_1,mT_2;
      array<Integer> v1,v2,v1_1,v2_1,v1_2,v2_2;
      list<list<Integer>> comps,comps_1;
      list<Integer> tvars,comp,comp_1,tearingvars,residualeqns,ccomp,r,t,r_1,t_1,te,te_1,tearingeqns;
      Integer ll,compcount,compcount_1,compcount_2;
      list<Boolean> checklst;
      list<DAE.ComponentRef> crlst;
    case (dlow,dlow1,m,mT,v1,v2,{},r,t,te,ccomp,compcount,crlst)
      then
        (r,t,te,dlow,dlow1,m,mT,v1,v2,{},compcount);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps,r,t,te,ccomp,compcount,crlst)
      equation
        // block ?
        ll = listLength(comp);
        true = ll > 1;
        // check block
        checklst = Util.listMap1(comp,Util.listContains,ccomp);
        true = Util.listContains(true,checklst);
        // this is a block
        compcount_1 = compcount + 1;
        // get all interesting vars
        (tvars,_) = getTearingVars(m,v1,v2,comp,dlow);
        // try tearing
        (residualeqns,tearingvars,tearingeqns,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem2(dlow,dlow1,m,mT,v1,v2,comp,tvars,{},r,t,te,crlst);
        // next Block
        (r_1,t_1,te_1,dlow_2,dlow1_2,m_2,mT_2,v1_2,v2_2,comps_1,compcount_2) = tearingSystem4(dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comps,residualeqns,tearingvars,tearingeqns,ccomp,compcount_1,crlst);
      then
        (r_1,t_1,te_1,dlow_2,dlow1_2,m_2,mT_2,v1_2,v2_2,comp_1::comps_1,compcount_2);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps,r,t,te,ccomp,compcount,crlst)
      equation
        // block ?
        ll = listLength(comp);
        true = ll > 1;
        // check block
        checklst = Util.listMap1(comp,Util.listContains,ccomp);
        true = Util.listContains(true,checklst);
        // this is a block
        compcount_1 = compcount + 1;
        // next Block
        (r_1,t_1,tearingeqns,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comps_1,compcount_2) = tearingSystem4(dlow,dlow1,m,mT,v1,v2,comps,r,t,te,ccomp,compcount_1,crlst);
      then
        (r_1,t_1,tearingeqns,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comp::comps_1,compcount_2);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps,r,t,te,ccomp,compcount,crlst)
      equation
        // next Block
        (r_1,t_1,te_1,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comps_1,compcount_1) = tearingSystem4(dlow,dlow1,m,mT,v1,v2,comps,r,t,te,ccomp,compcount,crlst);
      then
        (r_1,t_1,te_1,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comp::comps_1,compcount_1);
  end matchcontinue;
end tearingSystem4;

protected function getMaxfromListList
" function: getMaxfromArrayList
  helper for tearingSystem2 and tearingSystem3
  This function select the equation/variable
  with most connections to variables/equations.
  If more than once is there the first will
  be selected."
  input BackendDAE.IncidenceMatrixT inM;
  input list<BackendDAE.Value> inLst;
  input list<BackendDAE.Value> inComp;
  input BackendDAE.Value inMax;
  input BackendDAE.Value inEqn;
  input list<BackendDAE.Value> inExclude;
  output BackendDAE.Value outEqn;
  output BackendDAE.Value outMax;
algorithm
  (outEqn,outMax):=
  matchcontinue (inM,inLst,inComp,inMax,inEqn,inExclude)
    local
      BackendDAE.IncidenceMatrixT m;
      list<BackendDAE.Value> rest,eqn,eqn_1,eqn_2,eqn_3,comp,exclude;
      BackendDAE.Value v,v1,v2,max,max_1,en,en_1,en_2;
    case (m,{},comp,max,en,exclude) then (en,max);
    case (m,v::rest,comp,max,en,exclude)
      equation
        (en_1,max_1) = getMaxfromListList(m,rest,comp,max,en,exclude);
        true = v > 0;
        false = Util.listContains(v,exclude);
        eqn = m[v];
        // remove negative
        eqn_1 = BackendDAEUtil.removeNegative(eqn);
        // select entries
        eqn_2 = Util.listSelect1(eqn_1,comp,Util.listContains);
        // remove multiple entries
        eqn_3 = removeMultiple(eqn_2);
        v1 = listLength(eqn_3);
        v2 = intMax(v1,max_1);
        en_2 = Util.if_(v1>max_1,v,en_1);
      then
        (en_2,v2);
    case (m,v::rest,comp,max,en,exclude)
      equation
        (en_2,v2) = getMaxfromListList(m,rest,comp,max,en,exclude);
      then
        (en_2,v2);
  end matchcontinue;
end getMaxfromListList;

protected function getMaxfromListListVar
" function: getMaxfromArrayListVar
  same as getMaxfromListList but prefers states."
  input BackendDAE.IncidenceMatrixT inM;
  input list<BackendDAE.Value> inLst;
  input list<BackendDAE.Value> inComp;
  input BackendDAE.Value inMax;
  input BackendDAE.Value inEqn;
  input list<BackendDAE.Value> inExclude;
  input BackendDAE.Variables inVars;
  output BackendDAE.Value outEqn;
  output BackendDAE.Value outMax;
algorithm
  (outEqn,outMax):=
  matchcontinue (inM,inLst,inComp,inMax,inEqn,inExclude,inVars)
    local
      BackendDAE.IncidenceMatrixT m;
      list<BackendDAE.Value> rest,eqn,eqn_1,eqn_2,eqn_3,comp,exclude;
      BackendDAE.Value v,v1,v2,max,max_1,en,en_1,en_2;
      BackendDAE.Variables vars;
      BackendDAE.Var var;
      Boolean b;
      Integer si;
    case (m,{},comp,max,en,exclude,_) then (en,max);
    case (m,v::rest,comp,max,en,exclude,vars)
      equation
        (en_1,max_1) = getMaxfromListListVar(m,rest,comp,max,en,exclude,vars);
        true = v > 0;
        false = Util.listContains(v,exclude);
        eqn = m[v];
        // remove negative
        eqn_1 = BackendDAEUtil.removeNegative(eqn);
        // select entries
        eqn_2 = Util.listSelect1(eqn_1,comp,Util.listContains);
        // remove multiple entries
        eqn_3 = removeMultiple(eqn_2);
        // check if state or state der and prefer them
        var = BackendVariable.getVarAt(vars,v);
        b = BackendVariable.isStateorStateDerVar(var);
        si = Util.if_(b,listLength(comp),0);
        v1 = listLength(eqn_3)+si;
        v2 = intMax(v1,max_1);
        en_2 = Util.if_(v1>max_1,v,en_1);
      then
        (en_2,v2);
    case (m,v::rest,comp,max,en,exclude,vars)
      equation
        (en_2,v2) = getMaxfromListListVar(m,rest,comp,max,en,exclude,vars);
      then
        (en_2,v2);
  end matchcontinue;
end getMaxfromListListVar;

protected function removeMultiple
" function: removeMultiple
  remove mulitple entries from the list"
  input list<BackendDAE.Value> inLst;
  output list<BackendDAE.Value> outLst;
algorithm
  outLst:=
  matchcontinue (inLst)
    local
      list<BackendDAE.Value> rest,lst;
      BackendDAE.Value v;
    case ({}) then {};
    case (v::{})
      then
        {v};
    case (v::rest)
      equation
        lst = removeMultiple(rest);
        false = Util.listContains(v,lst);
      then
        (v::lst);
    case (v::rest)
      equation
        lst = removeMultiple(rest);
        true = Util.listContains(v,lst);
      then
        lst;
  end matchcontinue;
end removeMultiple;

protected function splitComps
" function: splitComps
  splits the comp in two list
  1: len(comp) == 1
  2: len(comp) > 1"
  input list<list<Integer>> inComps;
  output list<list<Integer>> outComps;
  output list<list<Integer>> outComps1;
algorithm
  (outComps,outComps1):=
  matchcontinue (inComps)
    local
      list<list<Integer>> rest,comps,comps1;
      list<Integer> comp;
      Integer v;
    case ({}) then ({},{});
    case ({v}::rest)
      equation
        (comps,comps1) = splitComps(rest);
      then
        (comps,{v}::comps1);
    case (comp::rest)
      equation
        (comps,comps1) = splitComps(rest);
      then
        (comp::comps,comps1);
  end matchcontinue;
end splitComps;

protected function solveEquations
" function: solveEquations
  try to solve the equations"
  input BackendDAE.EquationArray inEqnArray;
  input list<Integer> inEqns;
  input array<Integer> inAssigments;
  input BackendDAE.Variables inVars;
  input list<DAE.ComponentRef> inCrlst;
  output BackendDAE.EquationArray outEqnArray;
algorithm
  outEqnArray:=
  match (inEqnArray,inEqns,inAssigments,inVars,inCrlst)
    local
      BackendDAE.EquationArray eqns,eqns_1,eqns_2;
      list<Integer> rest;
      Integer e,e_1,v,v_1;
      array<Integer> ass;
      BackendDAE.Variables vars;
      DAE.Exp e1,e2,varexp,expr;
      list<DAE.Exp> divexplst,constexplst,nonconstexplst,tfixedexplst,tnofixedexplst;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      list<list<DAE.ComponentRef>> crlstlst;
      DAE.ElementSource source;
      BackendDAE.VariableArray varr;
      list<Boolean> blst,blst_1;
      list<list<Boolean>> blstlst;
    case (eqns,{},ass,vars,crlst) then eqns;
    case (eqns,e::rest,ass,vars as BackendDAE.VARIABLES(varArr=varr),crlst)
      equation
        e_1 = e - 1;
        BackendDAE.EQUATION(e1,e2,source) = BackendDAEUtil.equationNth(eqns, e_1);
        v = ass[e_1 + 1];
        v_1 = v - 1;
        BackendDAE.VAR(varName=cr) = BackendVariable.vararrayNth(varr, v_1);
        varexp = Expression.crefExp(cr);

        (expr,{}) = ExpressionSolve.solve(e1, e2, varexp);
        divexplst = Expression.extractDivExpFromExp(expr);
        (constexplst,nonconstexplst) = Util.listSplitOnTrue(divexplst,Expression.isConst);
        // check constexplst if equal 0
        blst = Util.listMap(constexplst, Expression.isZero);
        false = Util.boolOrList(blst);
        // check nonconstexplst if tearing variables or variables which will be
        // changed during solving process inside
        crlstlst = Util.listMap(nonconstexplst,Expression.extractCrefsFromExp);
        // add explst with variables which will not be changed during solving prozess
        blstlst = Util.listListMap2(crlstlst,Util.listContainsWithCompareFunc,crlst,ComponentReference.crefEqualNoStringCompare);
        blst_1 = Util.listMap(blstlst,Util.boolOrList);
        (tnofixedexplst,tfixedexplst) = Util.listSplitOnBoolList(nonconstexplst,blst_1);
        true = listLength(tnofixedexplst) < 1;
/*        print("\ntfixedexplst DivExpLst:\n");
        s = Util.listMap(tfixedexplst, ExpressionDump.printExpStr);
        Util.listMap0(s,print);
        print("\n===============================\n");
        print("\ntnofixedexplst DivExpLst:\n");
        s = Util.listMap(tnofixedexplst, ExpressionDump.printExpStr);
        Util.listMap0(s,print);
        print("\n===============================\n");
*/        eqns_1 = BackendEquation.equationSetnth(eqns,e_1,BackendDAE.EQUATION(expr,varexp,source));
        eqns_2 = solveEquations(eqns_1,rest,ass,vars,crlst);
      then
        eqns_2;
  end match;
end solveEquations;

/* 
 * Linearization section
 */

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
      BackendDAE.BackendDAE dlow;
      
      list<DAE.ComponentRef> eqvars,diffvars;
      list<BackendDAE.Var> varlst;
      array<Integer> v1,v2,v4,v31;
      list<Integer> v3;
      list<list<Integer>> comps1;
      list<BackendDAE.Var> derivedVariables;
      list<BackendDAE.Var> derivedVars;
      BackendDAE.BinTree jacElements;
      list<tuple<DAE.ComponentRef,Integer>> varTuple;
      array<list<Integer>> m,mT;
      
      BackendDAE.Variables v,kv,exv,vN,kvN;
      BackendDAE.AliasVariables av,avN;
      BackendDAE.EquationArray e,re,ie,eN,reN,ieN;
      array<BackendDAE.MultiDimEquation> ae,aeN;
      array<DAE.Algorithm> al,alN;
      BackendDAE.EventInfo ev;
      BackendDAE.ExternalObjectClasses eoc;
      list<BackendDAE.Equation> e_lst,re_lst,ie_lst;
      list<DAE.Algorithm> algs;
      list<BackendDAE.MultiDimEquation> ae_lst;
      
      list<String> s;
      String str;
      
      Integer elimLevel;
      
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
        true = RTOpts.debugFlag("linearization");
        // prepare index for Matrix and variables for simpleEquations
        derivedVariables = BackendDAEUtil.varList(v);
        (varTuple) = determineIndices(eqvars, diffvars, 0, varlst);
        //BackendDump.printTuple(varTuple);
        jacElements = BackendDAE.emptyBintree;
        (derivedVariables,jacElements) = changeIndices(derivedVariables, varTuple, jacElements);
        v = BackendDAEUtil.listVar(derivedVariables);
        dlow = BackendDAE.DAE(v,kv,exv,av,e,re,ie,ae,al,ev,eoc);
        
        // Remove simple Equtaion and
        elimLevel = RTOpts.eliminationLevel();
        RTOpts.setEliminationLevel(2) "Full elimination";

        (dlow, NONE(), NONE()) = removeSimpleEquations(dlow,functionTree,NONE(),NONE());
        (dlow, NONE(), NONE()) = removeSimpleEquations(dlow,functionTree,NONE(),NONE());
        (dlow, NONE(), NONE()) = removeSimpleEquations(dlow,functionTree,NONE(),NONE());
        (dlow, NONE(), NONE()) = removeSimpleEquations(dlow,functionTree,NONE(),NONE());

        Debug.fcall("execJacstat",print, "*** analytical Jacobians -> removed simply equations: " +& realString(clock()) +& "\n" );
        // figure out new matching and the strong components  
        m = BackendDAEUtil.incidenceMatrix(dlow, BackendDAE.NORMAL());
        mT = BackendDAEUtil.transposeMatrix(m);
        (v1,v2,dlow,m,mT) = BackendDAETransform.matchingAlgorithm(dlow, m, mT, (BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT(), BackendDAE.KEEP_SIMPLE_EQN()),functionTree);
        Debug.fcall("jacdump2", BackendDump.dumpIncidenceMatrix, m);
        Debug.fcall("jacdump2", BackendDump.dumpIncidenceMatrixT, mT);
        Debug.fcall("jacdump2", BackendDump.dump, dlow);
        Debug.fcall("jacdump2", BackendDump.dumpMatching, v1);
        (comps1) = BackendDAETransform.strongComponents(m, mT, v1, v2);
        Debug.fcall("jacdump2", BackendDump.dumpComponents, comps1);
        Debug.fcall("execJacstat",print, "*** analytical Jacobians -> performed matching and sorting: " +& realString(clock()) +& "\n" );
       
         
        // figure out wich comps are needed to evaluate all derivedVariables  
        derivedVariables = BackendDAEUtil.varList(v);
        (derivedVars,_) = Util.listSplitOnTrue(derivedVariables,checkIndex);
        v3 = getVarIndex(derivedVars,derivedVariables);
        v31 = Util.arraySelect(v1,v3);
        v3 = arrayList(v31);
        s = Util.listMap(v3,intString);
        str = Util.stringDelimitList(s,",");
        Debug.fcall("markblocks",print,"Vars Indecies : " +& str +& "\n");
        v4 = arrayCreate(listLength(comps1),0);
        v4 = markArray(v3,comps1,v4);
        (comps1,_) = splitBlocks2(comps1,v4,1);
        
        Debug.fcall("jacdump2", BackendDump.dumpComponents, comps1);
        //Debug.fcall("execJacstat",print, "*** analytical Jacobians -> performed splitig the system: " +& realString(clock()) +& "\n" );
        then (dlow,v1,v2,comps1);        
          
      case(dlow as BackendDAE.DAE(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),functionTree,eqvars,diffvars,varlst)
        equation
        true = RTOpts.debugFlag("jacobian");
        // prepare index for Matrix and variables for simpleEquations
        derivedVariables = BackendDAEUtil.varList(v);
        (varTuple) = determineIndices(eqvars, diffvars, 0, varlst);
        //BackendDump.printTuple(varTuple);
        jacElements = BackendDAE.emptyBintree;
        (derivedVariables,jacElements) = changeIndices(derivedVariables, varTuple, jacElements);
        v = BackendDAEUtil.listVar(derivedVariables);
        dlow = BackendDAE.DAE(v,kv,exv,av,e,re,ie,ae,al,ev,eoc);
        
        // Remove simple Equtaion and
        elimLevel = RTOpts.eliminationLevel();
        RTOpts.setEliminationLevel(2) "Full elimination";

        (dlow, NONE(), NONE()) = removeSimpleEquations(dlow,functionTree,NONE(),NONE());
        (dlow, NONE(), NONE()) = removeSimpleEquations(dlow,functionTree,NONE(),NONE());
        (dlow, NONE(), NONE()) = removeSimpleEquations(dlow,functionTree,NONE(),NONE());
        (dlow, NONE(), NONE()) = removeSimpleEquations(dlow,functionTree,NONE(),NONE());

        Debug.fcall("execJacstat",print, "*** analytical Jacobians -> removed simply equations: " +& realString(clock()) +& "\n" );
        // figure out new matching and the strong components  
        m = BackendDAEUtil.incidenceMatrix(dlow, BackendDAE.NORMAL());
        mT = BackendDAEUtil.transposeMatrix(m);
        (v1,v2,dlow,m,mT) = BackendDAETransform.matchingAlgorithm(dlow, m, mT, (BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT(), BackendDAE.KEEP_SIMPLE_EQN()),functionTree);
        Debug.fcall("jacdump2", BackendDump.dumpIncidenceMatrix, m);
        Debug.fcall("jacdump2", BackendDump.dumpIncidenceMatrixT, mT);
        Debug.fcall("jacdump2", BackendDump.dump, dlow);
        Debug.fcall("jacdump2", BackendDump.dumpMatching, v1);
        (comps1) = BackendDAETransform.strongComponents(m, mT, v1, v2);
        Debug.fcall("jacdump2", BackendDump.dumpComponents, comps1);
        Debug.fcall("execJacstat",print, "*** analytical Jacobians -> performed matching and sorting: " +& realString(clock()) +& "\n" );
       
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
  input array<Integer> inIntegerArray;
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

protected function markArray
  // function : markArray
  // author : wbraun
  input list<Integer> inVars1;
  input list<list<Integer>> inVars2;
  input array<Integer> inInt;
  output array<Integer> outJacobian;
algorithm
  outJacobian := matchcontinue(inVars1,inVars2,inInt)
    local
      list<Integer> rest;
      list<list<Integer>> vars;
      Integer var;
      Integer i;
      array<Integer> arr,arr1;
      list<String> s;
      String str;
    case({},_,arr) then arr;      
    case(var::rest,vars,arr)
      equation
        i = Util.listlistPosition(var,vars);
        Debug.fcall("markblocks",print,"Var " +& intString(var) +& " at pos : " +& intString(i) +& "\n");
        arr1 = arrayCreate(i+1,1);
        arr = Util.arrayCopy(arr1,arr);
        arr = markArray(rest,vars,arr);
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
end markArray; 

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
  match (inVar)
    local BackendDAE.Value i;
    case (BackendDAE.VAR(index = i)) then i >= 0;
  end match;
end checkIndex;

/* 
 * Symbolic Jacobian subsection
 */ 

public function generateSymbolicJacobian
  // function: generateSymbolicJacobian
  // author: lochel
  input BackendDAE.BackendDAE inBackendDAE;
  input DAE.FunctionTree inFunctions;
  input list<DAE.ComponentRef> inVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  output BackendDAE.BackendDAE outJacobian;
algorithm
  outJacobian := matchcontinue(inBackendDAE, inFunctions, inVars, inStateVars, inInputVars, inParamVars)
    local
      BackendDAE.BackendDAE bDAE;
      DAE.FunctionTree functions;
      list<DAE.ComponentRef> vars, comref_diffvars;
      BackendDAE.Variables stateVars;
      BackendDAE.Variables inputVars;
      BackendDAE.Variables paramVars;
      BackendDAE.BackendDAE jacobian;
      
      // BackendDAE
      BackendDAE.Variables orderedVars, jacOrderedVars; // ordered Variables, only states and alg. vars
      BackendDAE.Variables knownVars, jacKnownVars, jacKnownVars1; // Known variables, i.e. constants and parameters
      BackendDAE.Variables jacExternalObjects; // External object variables
      BackendDAE.AliasVariables jacAliasVars; // mappings of alias-variables to real-variables
      BackendDAE.EquationArray orderedEqs, jacOrderedEqs; // ordered Equations
      BackendDAE.EquationArray removedEqs, jacRemovedEqs; // Removed equations a=b
      BackendDAE.EquationArray jacInitialEqs; // Initial equations
      array<BackendDAE.MultiDimEquation> jacArrayEqs; // Array equations
      array< .DAE.Algorithm> algorithms, jacAlgorithms; // Algorithms
      BackendDAE.EventInfo jacEventInfo; // eventInfo
      BackendDAE.ExternalObjectClasses jacExtObjClasses; // classes of external objects, contains constructor & destructor
      // end BackendDAE
      
      list<BackendDAE.Var> derivedVariables,jacknown,diffvars;
      list<DAE.Algorithm> derivedAlgorithms;
      list<tuple<Integer, DAE.ComponentRef>> derivedAlgorithmsLookUp;
      list<BackendDAE.Equation> derivedEquations, knownEqn;
      
    case(_, _, {}, _, _, _) equation
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
      
    case(bDAE as BackendDAE.DAE(orderedVars=orderedVars, knownVars=knownVars, orderedEqs=orderedEqs, removedEqs=removedEqs, algorithms=algorithms), functions, vars, stateVars, inputVars, paramVars) equation
      Debug.fcall("jacdump", print, "\n+++++++++++++++++++++ daeLow-dump:    input +++++++++++++++++++++\n");
      Debug.fcall("jacdump", BackendDump.dump, bDAE);
      Debug.fcall("jacdump", print, "##################### daeLow-dump:    input #####################\n\n");
      
      diffvars = BackendDAEUtil.varList(orderedVars);
      (derivedVariables,comref_diffvars) = generateJacobianVars(diffvars, vars);
      (derivedAlgorithms, derivedAlgorithmsLookUp) = deriveAllAlg(arrayList(algorithms), vars, functions, inputVars, paramVars, stateVars, knownVars, orderedVars, 0,vars);
      derivedEquations = deriveAll(BackendDAEUtil.equationList(orderedEqs), vars, functions, inputVars, paramVars, stateVars, knownVars, derivedAlgorithmsLookUp, orderedVars, comref_diffvars);
 
      Debug.fcall("exejaccstat",print, "*** analytical Jacobians -> created all derived equation: " +& realString(clock()) +& "\n" );
      // create Jacobian BackendDAE.DAE with derivied vars and equations      
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
      
    case(_, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.generateSymbolicJacobian failed"});
    then fail();
  end matchcontinue;
end generateSymbolicJacobian;

protected function generateJacobianVars
  // function: generateJacobianVars
  // author: lochel
  input list<BackendDAE.Var> inVars1;
  input list<DAE.ComponentRef> inVars2;
  output list<BackendDAE.Var> outVars;
  output list<DAE.ComponentRef> outcrefVars;
algorithm
  (outVars, outcrefVars) := matchcontinue(inVars1, inVars2)
  local
    BackendDAE.Var currVar;
    list<BackendDAE.Var> restVar, r1, r2, r;
    list<DAE.ComponentRef> vars2,res,res1,res2;
    
    case({}, _)
    then ({},{}); 
      
    case(currVar::restVar, vars2) equation
      (r1,res1) = generateJacobianVars2(currVar, vars2);
      (r2,res2) = generateJacobianVars(restVar, vars2);
      res = listAppend(res1, res2);
      r = listAppend(r1, r2);
    then (r,res);
      
    case(_, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.generateJacobianVars failed"});
    then fail();
  end matchcontinue;
end generateJacobianVars;

protected function generateJacobianVars2
  // function: generateJacobianVars2
  // author: lochel
  input BackendDAE.Var inVar1;
  input list<DAE.ComponentRef> inVars2;
  output list<BackendDAE.Var> outVars;
  output list<DAE.ComponentRef> outcrefVars;
algorithm
  (outVars,outcrefVars) := matchcontinue(inVar1, inVars2)
  local
    BackendDAE.Var var, r1;
    DAE.ComponentRef currVar, cref, derivedCref;
    list<DAE.ComponentRef> restVar,res,res1;
    list<BackendDAE.Var> r,r2;
    
    case(_, {})
    then ({},{});
 
    // skip for dicrete variable
    case(var as BackendDAE.VAR(varName=cref,varKind=BackendDAE.DISCRETE()), currVar::restVar) equation
      (r2,res) = generateJacobianVars2(var, restVar);
    then (r2,res);
    
    case(var as BackendDAE.VAR(varName=cref,varKind=BackendDAE.STATE()), currVar::restVar) equation
      cref = ComponentReference.crefPrefixDer(cref);
      derivedCref = differentiateVarWithRespectToX(cref, currVar);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), BackendDAE.REAL(), NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      (r2,res1) = generateJacobianVars2(var, restVar);
      res = listAppend({derivedCref}, res1);
      r = listAppend({r1}, r2);
    then (r,res);

    case(var as BackendDAE.VAR(varName=cref), currVar::restVar) equation
      derivedCref = differentiateVarWithRespectToX(cref, currVar);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), BackendDAE.REAL(), NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      (r2,res1) = generateJacobianVars2(var, restVar);
      res = listAppend({derivedCref}, res1);
      r = listAppend({r1}, r2);
    then (r,res);
      
    case(_, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.generateJacobianVars2 failed"});
    then fail();
  end matchcontinue;
end generateJacobianVars2;

protected function deriveAll
  // function: deriveAll
  // author: lochel
  input list<BackendDAE.Equation> inEquations;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  input BackendDAE.Variables inorderedVars;
  input list<DAE.ComponentRef> inDiffVars;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquations, inVars, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inAlgorithmsLookUp, inorderedVars, inDiffVars)
    local
      BackendDAE.Equation currEquation;
      BackendDAE.Equation eqn1;
      list<BackendDAE.Equation> restEquations;
      DAE.FunctionTree functions;
      list<DAE.ComponentRef> vars;
      list<BackendDAE.Equation> currDerivedEquations, restDerivedEquations, derivedEquations;
      BackendDAE.Variables inputVars, paramVars, stateVars, knownVars;
      list<tuple<Integer, DAE.ComponentRef>> algorithmsLookUp;
      DAE.ComponentRef dummycref;
      
    case({}, _, _, _, _, _, _, _, _, _) then {};
      
    case(currEquation::restEquations, vars, functions, inputVars, paramVars, stateVars, knownVars, algorithmsLookUp, inorderedVars, inDiffVars) equation
      Debug.fcall("jacdumpeqn", BackendDump.dumpEqns, {currEquation});
      Debug.fcall("jacdumpeqn", print, "\n");
      //dummycref = ComponentReference.makeCrefIdent("$pDERdummy", DAE.ET_REAL(), {});
      //Debug.fcall("execJacstat",print, "*** analytical Jacobians -> derive one equation: " +& realString(clock()) +& "\n" );
      currDerivedEquations = derive(currEquation, vars, functions, inputVars, paramVars, stateVars, knownVars, algorithmsLookUp, inorderedVars, inDiffVars);
      Debug.fcall("jacdumpeqn", BackendDump.dumpEqns, currDerivedEquations);
      Debug.fcall("jacdumpeqn", print, "\n");
      //Debug.fcall("execJacstat",print, "*** analytical Jacobians -> created other equations from that: " +& realString(clock()) +& "\n" );
      restDerivedEquations = deriveAll(restEquations, vars, functions, inputVars, paramVars, stateVars, knownVars, algorithmsLookUp, inorderedVars, inDiffVars);
      derivedEquations = listAppend(currDerivedEquations, restDerivedEquations);
    then derivedEquations;
 
    case(_, _, _, _, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.deriveAll failed"});
    then fail();
  end matchcontinue;
end deriveAll;

protected function derive
  // function: derive
  // author: lochel
  input BackendDAE.Equation inEquation;
  input list<DAE.ComponentRef> inVar;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  input BackendDAE.Variables inorderedVars;
  input list<DAE.ComponentRef> inDiffVars;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquation, inVar, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inAlgorithmsLookUp, inorderedVars, inDiffVars)
    local
      BackendDAE.Equation currEquation;
      list<BackendDAE.Equation> derivedEqns;
      DAE.FunctionTree functions;
      DAE.ComponentRef cref;
      DAE.Exp exp,lhs, rhs;
      list<DAE.ComponentRef> vars, crefs;
      list<DAE.Exp> lhs_, rhs_, exps;
      DAE.ElementSource source;
      BackendDAE.Variables inputVars, paramVars, stateVars, knownVars;
      Integer index;
      list<DAE.Exp> in_,out_;
      list<list<DAE.Exp>> derivedIn, derivedOut;
      list<tuple<Integer, DAE.ComponentRef>> algorithmsLookUp;
      Integer newAlgIndex;
      String s,s1;
      list<String> slst;
    
    //remove dicrete Equation  
    case(currEquation as BackendDAE.EQUATION(exp=lhs, scalar=rhs, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, _, inorderedVars, _) equation
      true = BackendDAEUtil.isDiscreteEquation(currEquation,inorderedVars,knownVars);
      Debug.fcall("jacdump",print,"BackendDAEOptimize.derive: discrete equation has been removed.\n");
    then {};
        
    case(currEquation as BackendDAE.WHEN_EQUATION(_, _), vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _) equation
      Debug.fcall("jacdump",print,"BackendDAEOptimize.derive: WHEN_EQUATION has been removed.\n");
    then {};

    case(currEquation as BackendDAE.EQUATION(exp=lhs, scalar=rhs, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, _, inorderedVars, inDiffVars) equation
      lhs_ = differentiateWithRespectToXVec(lhs, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars);
      rhs_ = differentiateWithRespectToXVec(rhs, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars);
      derivedEqns = Util.listThreadMap1(lhs_, rhs_, createEqn, source);
    then derivedEqns;
      
    case(currEquation as BackendDAE.ARRAY_EQUATION(_, _, _), vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.derive failed: ARRAY_EQUATION-case"});
    then fail();
      
    case(currEquation as BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=exp, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, _, inorderedVars, inDiffVars) equation
      crefs = Util.listMap1(vars,differentiateVarWithRespectToXR,cref);
      exps = differentiateWithRespectToXVec(exp, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars);
      derivedEqns = Util.listThreadMap1(crefs, exps, createSolvedEqn, source);
    then derivedEqns;
      
    case(currEquation as BackendDAE.RESIDUAL_EQUATION(exp=exp, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, _, inorderedVars, inDiffVars) equation
      exps = differentiateWithRespectToXVec(exp, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars);
      derivedEqns = Util.listMap1(exps, createResidualEqn, source);
    then derivedEqns;
      
    case(currEquation as BackendDAE.ALGORITHM(index=index, in_={}, out=out_, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, algorithmsLookUp, inorderedVars, inDiffVars)
    equation
      //derivedIn = Util.listMap7list(in_, differentiateWithRespectToXVec, vars, functions, inputVars, paramVars, stateVars, knownVars,inDiffVars);
      derivedOut = Util.listMap8list(out_, differentiateWithRespectToXVec, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars);
      //derivedIn = Util.listlistTranspose(derivedIn);
      //derivedIn = Util.listMap1(derivedIn,listAppend,in_);
      derivedOut = Util.listlistTranspose(derivedOut);
      //s = ExpressionDump.printListStr(derivedIn, ExpressionDump.printExpListStr, " ");
      //s1 = intString(listLength(derivedIn));
      //print("#### DerivedIns (" +& s1 +& ") : " +& s +& "\n"); //stringCharListString(slst) +& "\n");
      //s = ExpressionDump.printListStr(derivedOut, ExpressionDump.printExpListStr, " ");
      //s1 = intString(listLength(derivedOut));
      //print("#### DerivedOuts (" +& s1 +& ") : " +& s +& "\n"); //stringCharListString(slst) +& "\n");
      derivedEqns = Util.listThreadMap3(derivedOut, vars, createAlgorithmEqnEmptyIn,index,algorithmsLookUp, source);
    then derivedEqns;

    case(currEquation as BackendDAE.ALGORITHM(index=index, in_=in_, out={}, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, algorithmsLookUp, inorderedVars, inDiffVars)
    equation
      derivedIn = Util.listMap8list(in_, differentiateWithRespectToXVec, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars);
      //derivedOut = Util.listMap7list(out_, differentiateWithRespectToXVec, vars, functions, inputVars, paramVars, stateVars, knownVars,inDiffVars);
      derivedIn = Util.listlistTranspose(derivedIn);
      derivedIn = Util.listMap1(derivedIn,listAppend,in_);
      //derivedOut = Util.listlistTranspose(derivedOut);
      //s = ExpressionDump.printListStr(derivedIn, ExpressionDump.printExpListStr, " ");
      //s1 = intString(listLength(derivedIn));
      //print("#### DerivedIns (" +& s1 +& ") : " +& s +& "\n"); //stringCharListString(slst) +& "\n");
      //s = ExpressionDump.printListStr(derivedOut, ExpressionDump.printExpListStr, " ");
      //s1 = intString(listLength(derivedOut));
      //print("#### DerivedOuts (" +& s1 +& ") : " +& s +& "\n"); //stringCharListString(slst) +& "\n");
      derivedEqns = Util.listThreadMap3(derivedIn, vars, createAlgorithmEqnEmptyOut,index,algorithmsLookUp, source);
    then derivedEqns;


    case(currEquation as BackendDAE.ALGORITHM(index=index, in_=in_, out=out_, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, algorithmsLookUp, inorderedVars, inDiffVars)
    equation
      derivedIn = Util.listMap8list(in_, differentiateWithRespectToXVec, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars);
      derivedOut = Util.listMap8list(out_, differentiateWithRespectToXVec, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars);
      derivedIn = Util.transposeList(derivedIn);
      derivedIn = Util.listMap1(derivedIn,listAppend,in_);
      derivedOut = Util.transposeList(derivedOut);
      //s = ExpressionDump.printListStr(derivedIn, ExpressionDump.printExpListStr, " ");
      //s1 = intString(listLength(derivedIn));
      //print("#### DerivedIns (" +& s1 +& ") : " +& s +& "\n");
      //s = ExpressionDump.printListStr(derivedOut, ExpressionDump.printExpListStr, " ");
      //s1 = intString(listLength(derivedOut));
      //print("#### DerivedOuts (" +& s1 +& ") : " +& s +& "\n");
      derivedEqns = Util.listThread3Map3(derivedIn, derivedOut, vars, createAlgorithmEqn,index,algorithmsLookUp, source);
    then derivedEqns;

    case(currEquation as BackendDAE.COMPLEX_EQUATION(_, _, _, _), vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.derive failed: COMPLEX_EQUATION-case"});
    then fail();
      
    case(_, _, _, _, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.derive failed"});
    then fail();
  end matchcontinue;
end derive;

protected function createEqn
  input DAE.Exp inLHS;
  input DAE.Exp inRHS;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm outEqn := match(inLHS,inRHS,Source)
  local
  case (inLHS,inRHS,Source) then BackendDAE.EQUATION(inLHS,inRHS,Source);
 end match;
end createEqn;

protected function createSolvedEqn
  input DAE.ComponentRef inCref;
  input DAE.Exp inRHS;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm outEqn := match(inCref,inRHS,Source)
  local
  case (inCref,inRHS,Source) then BackendDAE.SOLVED_EQUATION(inCref,inRHS,Source);
 end match;
end createSolvedEqn;

protected function createResidualEqn
  input DAE.Exp inRHS;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm outEqn := match(inRHS,Source)
  local
  case (inRHS,Source) then BackendDAE.RESIDUAL_EQUATION(inRHS, Source);
 end match;
end createResidualEqn;

protected function createAlgorithmEqnEmptyIn
  input list<DAE.Exp> inOuts;
  input DAE.ComponentRef inCref;
  input Integer inIndex;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm outEqn := match(inOuts,inCref,inIndex,inAlgorithmsLookUp,Source)
  local
    Integer newAlgIndex;
    String s1;
  case (inOuts,inCref,inIndex,inAlgorithmsLookUp,Source) 
    equation
      s1 = ExpressionDump.printExpListStr(inOuts);
      //print("### Create Algorithm eIn: (" +& s1 +& ") = f({}) \n"); 
      newAlgIndex = Util.listPosition((inIndex, inCref), inAlgorithmsLookUp);
   then BackendDAE.ALGORITHM(newAlgIndex, {}, inOuts, Source);
 end match;
end createAlgorithmEqnEmptyIn;


protected function createAlgorithmEqnEmptyOut
  input list<DAE.Exp> inIns;
  input DAE.ComponentRef inCref;
  input Integer inIndex;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm outEqn := match(inIns,inCref,inIndex,inAlgorithmsLookUp,Source)
  local
    Integer newAlgIndex;
    String s1;
  case (inIns,inCref,inIndex,inAlgorithmsLookUp,Source) 
    equation
      s1 = ExpressionDump.printExpListStr(inIns);
      //print("### Create Algorithm eOut: ({}) = f(" +& s1 +& ") \n"); 
      newAlgIndex = Util.listPosition((inIndex, inCref), inAlgorithmsLookUp);
   then BackendDAE.ALGORITHM(newAlgIndex, inIns, {}, Source);
 end match;
end createAlgorithmEqnEmptyOut;

protected function createAlgorithmEqn
  input list<DAE.Exp> inIns;
  input list<DAE.Exp> inOuts;
  input DAE.ComponentRef inCref;
  input Integer inIndex;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm outEqn := match(inIns,inOuts,inCref,inIndex,inAlgorithmsLookUp,Source)
  local
    Integer newAlgIndex;
    String s1,s2;
  case (inIns,inOuts,inCref,inIndex,inAlgorithmsLookUp,Source) 
    equation
      s1 = ExpressionDump.printExpListStr(inIns);
      s2 = ExpressionDump.printExpListStr(inOuts);
      //print("### Create Algorithm : (" +& s2 +& ") = f(" +& s1 +& ") \n"); 
      newAlgIndex = Util.listPosition((inIndex, inCref), inAlgorithmsLookUp);
   then BackendDAE.ALGORITHM(newAlgIndex, inIns, inOuts, Source);
 end match;
end createAlgorithmEqn;

public function differentiateVarWithRespectToX
  // function: differentiateVarWithRespectToX
  // author: lochel
  input DAE.ComponentRef inCref;
  input DAE.ComponentRef inX;
  //input list<BackendDAE.Var> inStateVars;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inX)//, inStateVars)
    local
      DAE.ComponentRef cref, x;
      String id,str;
      list<BackendDAE.Var> stateVars;
      BackendDAE.Var v1;
      
    case(cref, x) equation
      id = ComponentReference.printComponentRefStr(cref) +& BackendDAE.partialDerivativeNamePrefix +& ComponentReference.printComponentRefStr(x);
      id = Util.stringReplaceChar(id, ",", "$K");
      id = Util.stringReplaceChar(id, ".", "$P");
      id = Util.stringReplaceChar(id, "[", "$lB");
      id = Util.stringReplaceChar(id, "]", "$rB");
    then ComponentReference.makeCrefIdent(id, DAE.ET_REAL(), {});
      
    case(cref, _)
      equation
        str = "BackendDAEOptimize.differentiateVarWithRespectToX failed: " +&  ComponentReference.printComponentRefStr(cref);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end differentiateVarWithRespectToX;

public function differentiateVarWithRespectToXR
"  function: differentiateVarWithRespectToXR
   author: wbraun
   This function create a differentiated ComponentReference. "
  input DAE.ComponentRef inX;
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := differentiateVarWithRespectToX(inCref, inX);
end differentiateVarWithRespectToXR;

protected function deriveExpListwrtstate
  input list<DAE.Exp> inExpList;
  input Integer inLengthExpList;
  input list<tuple<Integer,DAE.derivativeCond>> inConditios;
  input DAE.ComponentRef inState;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inAllVars;
  input list<DAE.ComponentRef> inDiffVars;
  output list<DAE.Exp> outExpList;
algorithm
  outExpList := matchcontinue(inExpList, inLengthExpList, inConditios, inState, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inAllVars, inDiffVars)
    local
      DAE.ComponentRef x;
      DAE.Exp curr,r1;
      list<DAE.Exp> rest, r2;
      DAE.FunctionTree functions;
      Integer LengthExpList,n, argnum;
      list<tuple<Integer,DAE.derivativeCond>> conditions;
      BackendDAE.Variables inputVars, paramVars, stateVars, knownVars;
      list<DAE.ComponentRef> diffVars;
    case ({},_,_,_,_,_,_,_,_,_,_) then ({});
    case (curr::rest, LengthExpList, conditions, x, functions,inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars) equation
      n = listLength(rest);
      argnum = LengthExpList - n;
      true = checkcondition(conditions,argnum); 
      {r1} = differentiateWithRespectToXVec(curr, {x}, functions, inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars); 
      r2 = deriveExpListwrtstate(rest,LengthExpList,conditions, x, functions,inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars);
    then (r1::r2);
    case (curr::rest, LengthExpList, conditions, x, functions,inputVars, paramVars, stateVars,knownVars, inAllVars, diffVars) equation
      r2 = deriveExpListwrtstate(rest,LengthExpList,conditions, x, functions,inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars);
    then r2;  
  end matchcontinue;
end deriveExpListwrtstate;

protected function deriveExpListwrtstate2
  input list<DAE.Exp> inExpList;
  input Integer inLengthExpList;
  input DAE.ComponentRef inState;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inAllVars;  
  input list<DAE.ComponentRef> inDiffVars;
  output list<DAE.Exp> outExpList;
algorithm
  outExpList := match(inExpList, inLengthExpList, inState, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inAllVars, inDiffVars)
    local
      DAE.ComponentRef x;
      DAE.Exp curr,r1;
      list<DAE.Exp> rest, r2;
      DAE.FunctionTree functions;
      Integer LengthExpList,n, argnum;
      BackendDAE.Variables inputVars, paramVars, stateVars,knownVars;
      list<DAE.ComponentRef> diffVars;    
    case ({}, _, _, _, _, _, _, _, _,_) then ({});
    case (curr::rest, LengthExpList, x, functions, inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars) equation
      n = listLength(rest);
      argnum = LengthExpList - n;
      {r1} = differentiateWithRespectToXVec(curr, {x}, functions, inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars); 
      r2 = deriveExpListwrtstate2(rest,LengthExpList, x, functions, inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars);
    then (r1::r2);
  end match;
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
  outExp := match(varExpList, derVarExpList, functionCall, derFname, nDerArgs)
    local
      DAE.Exp e, currVar, currDerVar, derFun;
      list<DAE.Exp> restVar, restDerVar, varExpList1Added, varExpListTotal;
      DAE.ExpType et;
      Boolean tuple_, builtin;
      DAE.InlineType inlineType;
      Integer nArgs1, nArgs2;
    case ( _, {}, _, _, _) then (DAE.RCONST(0.0));
    case (currVar::restVar, currDerVar::restDerVar, functionCall as DAE.CALL(expLst=varExpListTotal, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), derFname, nDerArgs)
      equation
        e = partialAnalyticalDifferentiation(restVar, restDerVar, functionCall, derFname, nDerArgs);
        nArgs1 = listLength(varExpListTotal);
        nArgs2 = listLength(restDerVar);
        varExpList1Added = Util.listReplaceAtWithFill(DAE.RCONST(0.0),nArgs1 + nDerArgs - 1, varExpListTotal ,DAE.RCONST(0.0));
        varExpList1Added = Util.listReplaceAtWithFill(DAE.RCONST(1.0),nArgs1 + nDerArgs - (nArgs2 + 1), varExpList1Added,DAE.RCONST(0.0));
        derFun = DAE.CALL(derFname, varExpList1Added, tuple_, builtin, et, inlineType);
      then DAE.BINARY(e, DAE.ADD(DAE.ET_REAL()), DAE.BINARY(derFun, DAE.MUL(DAE.ET_REAL()), currDerVar)); 
  end match;
end partialAnalyticalDifferentiation;

protected function partialNumericalDifferentiation
  input list<DAE.Exp> varExpList;
  input list<DAE.Exp> derVarExpList;
  input DAE.ComponentRef inState;
  input DAE.Exp functionCall;
  output DAE.Exp outExp;
algorithm
  outExp := match(varExpList, derVarExpList, inState, functionCall)
    local
      DAE.Exp e, currVar, currDerVar, derFun, delta, absCurr;
      list<DAE.Exp> restVar, restDerVar, varExpListHAdded, varExpListTotal;
      DAE.ExpType et;
      Absyn.Path fname;
      Boolean tuple_, builtin;
      DAE.InlineType inlineType;
      Integer nArgs1, nArgs2;
    case ({}, _, _, _) then (DAE.RCONST(0.0));
    case (currVar::restVar, currDerVar::restDerVar, inState, functionCall as DAE.CALL(path=fname, expLst=varExpListTotal, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType))
      equation
        e = partialNumericalDifferentiation(restVar, restDerVar, inState, functionCall);
        absCurr = DAE.LBINARY(DAE.RELATION(currVar,DAE.GREATER(DAE.ET_REAL()),DAE.RCONST(1e-8),-1,NONE()),DAE.OR(),DAE.RELATION(currVar,DAE.LESS(DAE.ET_REAL()),DAE.RCONST(-1e-8),-1,NONE()));
        delta = DAE.IFEXP( absCurr, DAE.BINARY(currVar,DAE.MUL(DAE.ET_REAL()),DAE.RCONST(1e-8)), DAE.RCONST(1e-8));
        nArgs1 = listLength(varExpListTotal);
        nArgs2 = listLength(restVar);
        varExpListHAdded = Util.listReplaceAtWithFill(DAE.BINARY(currVar, DAE.ADD(DAE.ET_REAL()),delta),nArgs1-(nArgs2+1), varExpListTotal,DAE.RCONST(0.0));
        derFun = DAE.BINARY(DAE.BINARY(DAE.CALL(fname, varExpListHAdded, tuple_, builtin, et, inlineType), DAE.SUB(DAE.ET_REAL()), DAE.CALL(fname, varExpListTotal, tuple_, builtin, et, inlineType)), DAE.DIV(DAE.ET_REAL()), delta);
      then DAE.BINARY(e, DAE.ADD(DAE.ET_REAL()), DAE.BINARY(derFun, DAE.MUL(DAE.ET_REAL()), currDerVar)); 
  end match;
end partialNumericalDifferentiation;


protected function deriveAllAlg
  // function: deriveAllAlg
  // author: lochel
  input list<DAE.Algorithm> inAlgorithms;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inAllVars;
  input Integer inAlgIndex; // 0
  input list<DAE.ComponentRef> inDiffVars;
  output list<DAE.Algorithm> outDerivedAlgorithms;
  output list<tuple<Integer, DAE.ComponentRef>> outDerivedAlgorithmsLookUp;
algorithm
  (outDerivedAlgorithms, outDerivedAlgorithmsLookUp) := match(inAlgorithms, inVars, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inAllVars, inAlgIndex,inDiffVars)
    local
      DAE.Algorithm currAlg;
      list<DAE.Algorithm> restAlgs;
      list<DAE.ComponentRef> vars;
      DAE.FunctionTree functions;
      BackendDAE.Variables inputVars;
      BackendDAE.Variables paramVars;
      BackendDAE.Variables stateVars;
      BackendDAE.Variables knownVars;
      BackendDAE.Variables allVars;
      list<DAE.ComponentRef> diffVars;
      Integer algIndex;
      list<DAE.Algorithm> rAlgs1, rAlgs2;
      list<tuple<Integer, DAE.ComponentRef>> rLookUp1, rLookUp2;
    case({}, _, _, _, _, _, _, _, _, _) then ({}, {});
      
    case(currAlg::restAlgs, vars, functions, inputVars, paramVars, stateVars, knownVars, allVars, algIndex, diffVars)
    equation
      (rAlgs1, rLookUp1) = deriveOneAlg(currAlg, vars, functions, inputVars, paramVars, stateVars, knownVars, allVars, algIndex, diffVars);
      (rAlgs2, rLookUp2) = deriveAllAlg(restAlgs, vars, functions, inputVars, paramVars, stateVars, knownVars, allVars, algIndex+1, diffVars);
      rAlgs1 = listAppend(rAlgs1, rAlgs2);
      rLookUp1 = listAppend(rLookUp1, rLookUp2);
    then (rAlgs1, rLookUp1);
  end match;
end deriveAllAlg;

protected function deriveOneAlg
  // function: deriveOneAlg
  // author: lochel
  input DAE.Algorithm inAlgorithm;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inAllVars;
  input Integer inAlgIndex;
  input list<DAE.ComponentRef> inDiffVars;  
  output list<DAE.Algorithm> outDerivedAlgorithms;
  output list<tuple<Integer, DAE.ComponentRef>> outDerivedAlgorithmsLookUp;
algorithm
  (outDerivedAlgorithms, outDerivedAlgorithmsLookUp) := match(inAlgorithm, inVars, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inAllVars, inAlgIndex, inDiffVars)
    local
      DAE.Algorithm currAlg;
      list<DAE.Statement> statementLst, derivedStatementLst;
      DAE.ComponentRef currVar;
      list<DAE.ComponentRef> restVars;
      DAE.FunctionTree functions;
      BackendDAE.Variables inputVars;
      BackendDAE.Variables paramVars;
      BackendDAE.Variables stateVars;
      BackendDAE.Variables knownVars;
      list<DAE.ComponentRef> diffVars;
      Integer algIndex;
      list<DAE.Algorithm> rAlgs1, rAlgs2;
      list<tuple<Integer, DAE.ComponentRef>> rLookUp1, rLookUp2;
    case(_, {}, _, _, _, _, _, _, _,_) then ({}, {});
      
    case(currAlg as DAE.ALGORITHM_STMTS(statementLst=statementLst), currVar::restVars, functions, inputVars, paramVars, stateVars, knownVars, inAllVars, algIndex,diffVars)equation
      derivedStatementLst = differentiateAlgorithmStatements(statementLst, currVar, functions, inputVars, paramVars, stateVars, {}, knownVars, inAllVars, diffVars);
      rAlgs1 = {DAE.ALGORITHM_STMTS(derivedStatementLst)};
      rLookUp1 = {(algIndex, currVar)};
      (rAlgs2, rLookUp2) = deriveOneAlg(currAlg, restVars, functions, inputVars, paramVars, stateVars, knownVars, inAllVars, algIndex, diffVars);
      rAlgs1 = listAppend(rAlgs1, rAlgs2);
      rLookUp1 = listAppend(rLookUp1, rLookUp2);
    then (rAlgs1, rLookUp1);
  end match;
end deriveOneAlg;

protected function differentiateAlgorithmStatements
  // function: differentiateAlgorithmStatements
  // author: lochel
  input list<DAE.Statement> inStatements;
  input DAE.ComponentRef inVar;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input list<BackendDAE.Var> inControlVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inAllVars;
  input list<DAE.ComponentRef> inDiffVars;
  output list<DAE.Statement> outStatements;
algorithm
  outStatements := matchcontinue(inStatements, inVar, inFunctions, inInputVars, inParamVars, inStateVars, inControlVars, inKnownVars, inAllVars, inDiffVars)
    local
      list<DAE.Statement> restStatements;
      DAE.ComponentRef var;
      DAE.FunctionTree functions;
      BackendDAE.Variables inputVars;
      BackendDAE.Variables paramVars;
      BackendDAE.Variables stateVars;
      list<BackendDAE.Var> controlVars;
      BackendDAE.Variables controlparaVars;
      BackendDAE.Variables knownVars;
      BackendDAE.Variables allVars;
      list<DAE.ComponentRef> diffVars;
      DAE.Statement currStatement;
      DAE.ElementSource source;
      list<DAE.Statement> derivedStatements1;
      list<DAE.Statement> derivedStatements2;
      DAE.Exp exp;
      DAE.ExpType type_;
      DAE.Exp lhs, rhs;
      DAE.Exp derivedLHS, derivedRHS;
      //list<DAE.Exp> derivedLHS, derivedRHS;
      DAE.Exp elseif_exp;
      list<DAE.Statement> statementLst,else_statementLst,elseif_statementLst;
      DAE.Else elseif_else_;
      Boolean iterIsArray;
      DAE.Ident ident;
      DAE.ComponentRef cref;
      BackendDAE.Var controlVar;    
    case({}, _, _, _, _, _, _, _, _,_) then {};
      
    case((currStatement as DAE.STMT_ASSIGN(type_=type_, exp1=lhs, exp=rhs))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars) 
    equation
      controlparaVars = BackendVariable.addVars(controlVars, paramVars);
      {derivedLHS} = differentiateWithRespectToXVec(lhs, {var}, functions, inputVars, controlparaVars, stateVars, knownVars, allVars, diffVars);
      {derivedRHS} = differentiateWithRespectToXVec(rhs, {var}, functions, inputVars, controlparaVars, stateVars, knownVars, allVars, diffVars);
      derivedStatements1 = {DAE.STMT_ASSIGN(type_, derivedLHS, derivedRHS, DAE.emptyElementSource), currStatement};
      //derivedStatements1 = Util.listThreadMap3(derivedLHS, derivedRHS, createDiffStatements, type_, currStatement, source);
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_TUPLE_ASSIGN(exp=rhs)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars,  diffVars)
    equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.differentiateAlgorithmStatements failed: DAE.STMT_TUPLE_ASSIGN"});
    then fail();
      
    case(DAE.STMT_ASSIGN_ARR(exp=rhs)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars)
    equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.differentiateAlgorithmStatements failed: DAE.STMT_ASSIGN_ARR"});
    then fail();
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.NOELSE(), source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars,  diffVars);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.NOELSE(), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSEIF(exp=elseif_exp, statementLst=elseif_statementLst, else_=elseif_else_), source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
      derivedStatements2 = differentiateAlgorithmStatements({DAE.STMT_IF(elseif_exp, elseif_statementLst, elseif_else_, source)}, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSE(statementLst=else_statementLst), source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
      derivedStatements2 = differentiateAlgorithmStatements(else_statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_FOR(type_=type_, iterIsArray=iterIsArray, iter=ident, range=exp, statementLst=statementLst, source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars)
    equation
      cref = ComponentReference.makeCrefIdent(ident, DAE.ET_INT(), {});
      controlVar = BackendDAE.VAR(cref, BackendDAE.VARIABLE(), DAE.BIDIR(), BackendDAE.REAL(), NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      controlVars = listAppend(controlVars, {controlVar});
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);

      derivedStatements1 = {DAE.STMT_FOR(type_, iterIsArray, ident, exp, derivedStatements1, source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;

    case(DAE.STMT_WHILE(exp=exp, statementLst=statementLst, source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
      derivedStatements1 = {DAE.STMT_WHILE(exp, derivedStatements1, source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_WHEN(exp=exp)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
    then derivedStatements1;
      
    case((currStatement as DAE.STMT_ASSERT(cond=exp))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars,  diffVars)
    equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars,  diffVars);
      derivedStatements1 = currStatement::derivedStatements2;
    then derivedStatements1;
      
    case((currStatement as DAE.STMT_TERMINATE(msg=exp))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars)
    equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
      derivedStatements1 = currStatement::derivedStatements2;
    then derivedStatements1;
      
    case(DAE.STMT_REINIT(value=exp)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
    then derivedStatements1;
      
    case(DAE.STMT_NORETCALL(exp=exp, source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars)
    equation
      // e2 = differentiateWithRespectToX(e1, var, functions, {}, {}, {});
      // derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      // derivedStatements1 = listAppend({DAE.STMT_NORETCALL(e2, elemSrc)}, derivedStatements2);
    then fail();
      
    case((currStatement as DAE.STMT_RETURN(source=source))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars)
    equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
      derivedStatements1 = currStatement::derivedStatements2;
    then derivedStatements1;
      
    case((currStatement as DAE.STMT_BREAK(source=source))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars)
    equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars);
      derivedStatements1 = currStatement::derivedStatements2;
    then derivedStatements1;
      
    case(_, _, _, _, _, _, _, _, _,_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.differentiateAlgorithmStatements failed"});
    then fail();
  end matchcontinue;
end differentiateAlgorithmStatements;

protected function createDiffStatements
  input DAE.Exp inLHS;
  input DAE.Exp inRHS;
  input DAE.ExpType inType;
  input DAE.Statement inStmt;
  input DAE.ElementSource Source;
  output list<DAE.Statement> outEqn;
algorithm outEqn := match(inLHS,inRHS,inType,inStmt,Source)
  local
  case (inLHS,inRHS,inType,inStmt,Source) then {DAE.STMT_ASSIGN(inType, inLHS, inRHS, Source), inStmt};
 end match;
end createDiffStatements;

public function determineIndices
  // function: determineIndices
  // using column major order
  input list<DAE.ComponentRef> inStates;
  input list<DAE.ComponentRef> inStates2;
  input Integer inActInd;
  input list<BackendDAE.Var> inAllVars;
  output list<tuple<DAE.ComponentRef,Integer>> outTuple;
algorithm
  outTuple := match(inStates, inStates2, inActInd,inAllVars)
    local
      list<tuple<DAE.ComponentRef,Integer>> str;
      list<tuple<DAE.ComponentRef,Integer>> erg;
      list<DAE.ComponentRef> rest, states;
      DAE.ComponentRef curr;
      Integer actInd;
      list<BackendDAE.Var> allVars;
      
    case ({}, states, _, _) then {};
    case (curr::rest, states, actInd, allVars) equation
      (str, actInd) = determineIndices2(curr, states, actInd, allVars);
      erg = determineIndices(rest, states, actInd, allVars);
      str = listAppend(str, erg);
    then str;
  end match;
end determineIndices;

protected function determineIndices2
  // function: determineIndices2
  input DAE.ComponentRef inDStates;
  input list<DAE.ComponentRef> inStates;
  input Integer actInd;
  input list<BackendDAE.Var> inAllVars;
  output list<tuple<DAE.ComponentRef,Integer>> outTuple;
  output Integer outActInd;
algorithm
  (outTuple,outActInd) := matchcontinue(inDStates, inStates, actInd, inAllVars)
    local
      tuple<DAE.ComponentRef,Integer> str;
      list<tuple<DAE.ComponentRef,Integer>> erg;
      list<DAE.ComponentRef> rest;
      DAE.ComponentRef new, curr, dState;
      list<BackendDAE.Var> allVars;
      //String debug1;Integer debug2;
    case (dState, {}, actInd, allVars) then ({}, actInd);
    case (dState,curr::rest, actInd, allVars) equation
      ({BackendDAE.VAR(varKind = BackendDAE.STATE())}, _) = BackendVariable.getVar(dState, BackendDAEUtil.listVar(allVars));
      new = ComponentReference.crefPrefixDer(dState);
      new = differentiateVarWithRespectToX(new,curr);
      str = (new ,actInd);
      //print("CRef: " +& ComponentReference.printComponentRefStr(new) +& " index: " +& intString(actInd) +& "\n");  
      actInd = actInd+1;      
      (erg, actInd) = determineIndices2(dState, rest, actInd, allVars);
    then (str::erg, actInd);
    case (dState,curr::rest, actInd, allVars) equation
      new = differentiateVarWithRespectToX(dState,curr);
      str = (new ,actInd);
      //print("CRef: " +& ComponentReference.printComponentRefStr(new) +& " index: " +& intString(actInd) +& "\n");  
      actInd = actInd+1;      
      (erg, actInd) = determineIndices2(dState, rest, actInd, allVars);
    then (str::erg, actInd);      
    case (_,_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.determineIndices2() failed"});
    then fail();
  end matchcontinue;
end determineIndices2;

public function changeIndices
  input list<BackendDAE.Var> derivedVariables;
  input list<tuple<DAE.ComponentRef,Integer>> outTuple;
  input BackendDAE.BinTree inBinTree;
  output list<BackendDAE.Var> derivedVariablesChanged;
  output BackendDAE.BinTree outBinTree;
algorithm
  (derivedVariablesChanged,outBinTree) := matchcontinue(derivedVariables,outTuple,inBinTree)
    local
      list<BackendDAE.Var> rest,changedVariables;
      BackendDAE.Var derivedVariable;
      list<tuple<DAE.ComponentRef,Integer>> restTuple;
      BackendDAE.BinTree bt;
    case ({},_,bt) then ({},bt);
    case (derivedVariable::rest,restTuple,bt) equation
      (derivedVariable,bt) = changeIndices2(derivedVariable,restTuple,bt);
      (changedVariables,bt) = changeIndices(rest,restTuple,bt);
    then (derivedVariable::changedVariables,bt);
    case (_,_,_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.changeIndices() failed"});
    then fail();      
  end matchcontinue;
end changeIndices;

protected function changeIndices2
  input BackendDAE.Var derivedVariable;
  input list<tuple<DAE.ComponentRef,Integer>> varIndex; 
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.Var derivedVariablesChanged;
  output BackendDAE.BinTree outBinTree;
algorithm
 (derivedVariablesChanged,outBinTree) := matchcontinue(derivedVariable, varIndex,inBinTree)
    local
      BackendDAE.Var curr, changedVar;
      DAE.ComponentRef currCREF;
      list<tuple<DAE.ComponentRef,Integer>> restTuple;
      DAE.ComponentRef currVar;
      Integer currInd;
      BackendDAE.BinTree bt;
    case (curr  as BackendDAE.VAR(varName=currCREF),(currVar,currInd)::restTuple,bt) equation
      true = ComponentReference.crefEqual(currCREF, currVar) ;
      changedVar = BackendVariable.setVarIndex(curr,currInd);
      Debug.fcall("varIndex2",print, ComponentReference.printComponentRefStr(currVar) +& " " +& intString(currInd)+&"\n");
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
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.changeIndices2() failed"});
    then fail();      
  end matchcontinue;
end changeIndices2;


protected function differentiateWithRespectToXVec
  // function: differentiateWithRespectToXVec
  // author: wbraun
  
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inX;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inAllVars;
  input list<DAE.ComponentRef> inDiffVars;
  output list<DAE.Exp> outExp;
algorithm
  outExp := matchcontinue(inExp, inX, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars,inAllVars,inDiffVars)
    local
      list<DAE.ComponentRef> xlist;
      list<DAE.Exp> dxlist,dxlist1,dxlist2;
      DAE.ComponentRef x, cref, cref_;
      DAE.FunctionTree functions;
      DAE.Exp e1, e1_, e2, e2_, e;
      DAE.ExpType et;
      DAE.Operator op;
      
      Absyn.Path fname,derFname;
      
      list<DAE.Exp> expList1, expList2;
      Boolean tuple_, builtin,b;
      DAE.InlineType inlineType;
      BackendDAE.Variables inputVars, paramVars, stateVars, knownVars, allVars;
      list<DAE.ComponentRef> diffVars;
      String str;
      list<tuple<Integer,DAE.derivativeCond>> conditions;
      DAE.Type tp;
      Integer nArgs;
      BackendDAE.Var v1, v2;
      DAE.Exp z1, z2, z3, z4, z5, z6, z7;
      Integer index;
      Option<tuple<DAE.Exp,Integer,Integer>> optionExpisASUB;
      
    case(e as DAE.ICONST(_), xlist,functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars)
      equation
        dxlist = createDiffListMeta(e,xlist,diffInt, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars)));
    then dxlist;
      
    case( e as DAE.RCONST(_), xlist,functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars)
      equation
        dxlist = createDiffListMeta(e,xlist,diffRealZero, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars)));
    then dxlist;
    
    // d(time)/d(x)
    case(e as DAE.CREF(componentRef=(cref as DAE.CREF_IDENT(ident = "time",subscriptLst = {}))), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars)
      equation
        dxlist = createDiffListMeta(e,xlist,diffRealZero, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars)));
    then dxlist;
      
    // dummy diff
    case(e as DAE.CREF(componentRef=cref),xlist, functions, inputVars, paramVars, stateVars, knownVars,  allVars, diffVars) equation
      dxlist = createDiffListMeta(e,xlist,diffCref, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars)));
    then dxlist;

    // known vars
    case (DAE.CREF(componentRef=cref, ty=et), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars)
      equation
      ({(v1 as BackendDAE.VAR(bindExp=SOME(e1)))}, _) = BackendVariable.getVar(cref, knownVars);
      dxlist = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars);
    then dxlist;

    // diff crefVar
    case(e as DAE.CREF(componentRef=cref),xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars) equation
      dxlist = createDiffListMeta(e,xlist,diffCrefVar, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars)));
    then dxlist;
    
    // binary
    case(DAE.BINARY(exp1=e1, operator=op, exp2=e2),xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars) equation
      dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars);
      dxlist2 = differentiateWithRespectToXVec(e2, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars);
      dxlist = Util.listThreadMap3(dxlist1,dxlist2,mergeBin,op,e1,e2);
    then dxlist;
    
    // uniary
    case(DAE.UNARY(operator=op, exp=e1), xlist, functions, inputVars, paramVars, stateVars, knownVars,  allVars, diffVars) equation
      dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars,  allVars, diffVars);
      dxlist = Util.listMap1(dxlist1,mergeUn,op);
    then dxlist;

    // der(x)
    case (e as DAE.CALL(path=fname, expLst={e1}), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars)
      equation
      Builtin.isDer(fname);
      dxlist = createDiffListMeta(e,xlist,diffDerCref, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars)));
    then dxlist;

    // function call
    case (e as DAE.CALL(path=_, expLst={e1}), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars)
      equation
        dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars);
        dxlist = Util.listMap2(dxlist1,mergeCall,e1,e);
    then dxlist; 
      
    // extern functions (analytical and numeric)
    case (e as DAE.CALL(path=fname, expLst=expList1, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars)
      equation
       dxlist = createDiffListMeta(e,xlist,diffNumCall, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars)));
    then dxlist;
    
    // cast
    case (DAE.CAST(ty=et, exp=e1), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars) equation
      dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars);
      dxlist = Util.listMap1(dxlist1,mergeCast,et);
    then dxlist;          

    // relations
    case (e as DAE.RELATION(e1, op, e2, index, optionExpisASUB), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars) equation
        dxlist = createDiffListMeta(e,xlist,diffRealZero, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars)));
    then dxlist;

      // differentiate if-expressions
    case (DAE.IFEXP(expCond=e, expThen=e1, expElse=e2), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars)
      equation
      dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars);
      dxlist2 = differentiateWithRespectToXVec(e2, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars);
      dxlist = Util.listThreadMap1(dxlist1,dxlist2,mergeIf,e);
    then dxlist;

    /*  
    case (DAE.ARRAY(ty = et,scalar = b,array = expList1), x, functions, inputVars, paramVars, stateVars, knownVars, diffVars)
      equation
        expList2 = Util.listMap7(expList1, differentiateWithRespectToX, x, functions, inputVars, paramVars, stateVars, knownVars, diffVars);
      then
        DAE.ARRAY(et,b,expList2);
    
    case (DAE.TUPLE(PR = expList1), x, functions, inputVars, paramVars, stateVars, knownVars, diffVars)
      equation
        expList2 = Util.listMap7(expList1, differentiateWithRespectToX, x, functions, inputVars, paramVars, stateVars, knownVars, diffVars);
      then
        DAE.TUPLE(expList2);
    
    case (DAE.ASUB(exp = e,sub = expList1), x, functions, inputVars, paramVars, stateVars, knownVars, diffVars)
      equation
        e1_ = differentiateWithRespectToX(e, x, functions, inputVars, paramVars, stateVars, knownVars, diffVars);
      then
       e1_;
  */         
    case(e, xlist, _, _, _, _, _, _,_)
      equation
        str = "BackendDAEOptimize.differentiateWithRespectToXVec failed: " +& ExpressionDump.printExpStr(e) +& "\n";
        Debug.fcall("failtraceJac",print,str);
        //Error.addMessage(Error.INTERNAL_ERROR, {str});
      then {};
  end matchcontinue;
end differentiateWithRespectToXVec;

protected function createDiffListMeta
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> indiffVars;
  input FuncExpType func;
  input Option<Type_a> inTypeA;
  output list<DAE.Exp> outExpList;
  partial function FuncExpType
    input tuple<DAE.Exp, DAE.ComponentRef, Option<Type_a>> inTplExpTypeA;
    output DAE.Exp outTplExpTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm 
   outExpList := matchcontinue (inExp, indiffVars, func, inTypeA)  
   local
     DAE.Exp e,e1;
     FuncExpType func;
     DAE.ComponentRef diffCref;
     list<DAE.ComponentRef> rest;
     list<DAE.Exp> res;
     Option<Type_a> typea;
     String str;
    
     case(e, {}, _, _) then {};
     
     case(e, diffCref::rest, func, typea)
       equation
         e1 = func((e, diffCref, typea));
         res = createDiffListMeta(e,rest,func,typea);
       then e1::res;

     case(e, diffCref::rest, _, _)
       equation
         str = "BackendDAEOptimize.createDiffListMeta failed: " +& ExpressionDump.printExpStr(e) +& " | " +& ComponentReference.printComponentRefStr(diffCref);
         Debug.fcall("failtraceJac",print,str);
        //Error.addMessage(Error.INTERNAL_ERROR, {str});
       then fail();
  end matchcontinue;
end createDiffListMeta;


/*
 * diff functions for differemtiatewrtX vectorize
 *
 */

protected function diffInt
  input tuple<DAE.Exp, DAE.ComponentRef, Option<Type_a>> inTplExpTypeA;
  output DAE.Exp outTplExpTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA := matchcontinue(inTplExpTypeA)
    case(_) then DAE.ICONST(0);
 end matchcontinue;
end diffInt;

protected function diffRealZero
  input tuple<DAE.Exp, DAE.ComponentRef, Option<Type_a>> inTplExpTypeA;
  output DAE.Exp outTplExpTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA := matchcontinue(inTplExpTypeA)
    case(_) then DAE.RCONST(0.0);
 end matchcontinue;
end diffRealZero;

protected function diffCrefVar
  input tuple<DAE.Exp, DAE.ComponentRef, Option<Type_a>> inTplExpTypeA;
  output DAE.Exp outTplExpTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA := matchcontinue(inTplExpTypeA)
  local
    DAE.ComponentRef cref,cref_,x;
    DAE.ExpType et;
    case((DAE.CREF(componentRef=cref, ty=et),x,_))
      equation
      cref_ = differentiateVarWithRespectToX(cref, x);
      //print(" *** Diff : " +& ComponentReference.printComponentRefStr(cref) +& " w.r.t " +& ComponentReference.printComponentRefStr(x) +& "\n");
    then DAE.CREF(cref_, et);
 end matchcontinue;
end diffCrefVar;


protected function diffCref
  input tuple<DAE.Exp, DAE.ComponentRef, Option<tuple<DAE.FunctionTree,BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, list<DAE.ComponentRef>>>> inTplExpTypeA;
  output DAE.Exp outTplExpTypeA;
algorithm
  outTplExpTypeA := matchcontinue(inTplExpTypeA)
  local
    DAE.ExpType et;
    DAE.FunctionTree functions;
    DAE.ComponentRef x, cref,cref_;
    list<DAE.ComponentRef> diffVars;
    DAE.Exp e1,e1_;
    BackendDAE.Variables inputVars, paramVars, stateVars, knownVars,allVars;
    BackendDAE.Var v1,v2;
    
    // d(x)/d(x)
    case((DAE.CREF(componentRef=cref, ty=et),x,_))
      equation
      true = ComponentReference.crefEqual(cref, x);
    then DAE.RCONST(1.0);

    // d(state1)/d(state2) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars))))
      equation
      ({v1}, _) = BackendVariable.getVar(cref, stateVars);
      ({v2}, _) = BackendVariable.getVar(x, stateVars);
    then DAE.RCONST(0.0);

    // d(state)/d(input) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars))))
      equation
      ({v1}, _) = BackendVariable.getVar(cref, stateVars);
      ({v2}, _) = BackendVariable.getVar(x, inputVars);
    then DAE.RCONST(0.0);

    // d(input)/d(state) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars))))
      equation
      ({v1}, _) = BackendVariable.getVar(cref, inputVars);
      ({v2}, _) = BackendVariable.getVar(x, stateVars);
    then DAE.RCONST(0.0);

    // d(parameter1)/d(parameter2) != 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars))))
      equation
      ({v1}, _) = BackendVariable.getVar(cref, paramVars);
      ({v2}, _) = BackendVariable.getVar(x, paramVars);
      cref_ = differentiateVarWithRespectToX(cref, x);
    then DAE.CREF(cref_, et);

    // d(parameter1)/d(parameter2) != 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars))))
      equation
      ({v1}, _) = BackendVariable.getVar(cref, paramVars);
    then DAE.RCONST(0.0);
      
   // d(discrete)/d(x) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars))))
      equation
      ({v1 as BackendDAE.VAR(varKind = BackendDAE.DISCRETE())}, _) = BackendVariable.getVar(cref, allVars);
    then fail();
      
 end matchcontinue;
end diffCref;

protected function diffDerCref
  input tuple<DAE.Exp, DAE.ComponentRef, Option<Type_a>> inTplExpTypeA;
  output DAE.Exp outTplExpTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA := matchcontinue(inTplExpTypeA)
  local
    Absyn.Path fname;
    DAE.Exp e1;
    DAE.ComponentRef x,cref;
    case((DAE.CALL(path=fname, expLst={e1}),x,_))
      equation
      cref = Expression.expCref(e1);
      cref = ComponentReference.crefPrefixDer(cref);
      cref = differentiateVarWithRespectToX(cref,x);
    then DAE.CREF(cref, DAE.ET_REAL());
 end matchcontinue;
end diffDerCref;

protected function diffNumCall
  input tuple<DAE.Exp, DAE.ComponentRef, Option<tuple<DAE.FunctionTree, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, list<DAE.ComponentRef>>>> inTplExpTypeA;
  output DAE.Exp outTplExpTypeA;
algorithm
  outTplExpTypeA := matchcontinue(inTplExpTypeA)
  local
    Absyn.Path fname,derFname;
    DAE.ComponentRef x;
    DAE.Exp e,e1;
    list<DAE.Exp> expList1,expList2;
    Boolean tuple_, builtin;
    DAE.InlineType inlineType;
    DAE.ExpType et;
    DAE.Type tp;
    Integer nArgs;
    BackendDAE.Variables inputVars, paramVars, stateVars, knownVars, allVars;
    list<DAE.ComponentRef> diffVars;
    DAE.FunctionTree functions;
    list<tuple<Integer,DAE.derivativeCond>> conditions;
    //Option<tuple<DAE.FunctionTree, list<BackendDAE.Var>, list<BackendDAE.Var>, list<BackendDAE.Var>, list<BackendDAE.Var>, list<BackendDAE.Var>>> inTpl;
    // extern functions (analytical)
    case ((e as DAE.CALL(path=fname, expLst=expList1, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), x, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars))))
      equation
        nArgs = listLength(expList1);
        (DAE.FUNCTION_DER_MAPPER(derivativeFunction=derFname,conditionRefs=conditions), tp) = Derive.getFunctionMapper(fname, functions);
        expList2 = deriveExpListwrtstate(expList1, nArgs, conditions, x, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars);
        e1 = partialAnalyticalDifferentiation(expList1, expList2, e, derFname, listLength(expList2));  
      then e1;    
    case ((e as DAE.CALL(path=fname, expLst=expList1, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), x, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars))))
      equation
        //(SOME((functions, inputVars, paramVars, stateVars, knownVars, diffVars))) = inTpl;
        nArgs = listLength(expList1);
        expList2 = deriveExpListwrtstate2(expList1, nArgs, x, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars);
        e1 = partialNumericalDifferentiation(expList1, expList2, x, e);  
      then e1;      
 end matchcontinue;
end diffNumCall;

/*
 * Merge functions for differemtiatewrtX vectorize
 *
 */

protected function mergeCall
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inOrgExp1;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp1,inExp2,inOrgExp1)
  local
    DAE.Exp e,z1,z2;
    DAE.ExpType et;
    String str;
    //sin(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("sin")))
      equation
        e = DAE.BINARY(inExp1, DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("cos"),{inExp2},false,true,DAE.ET_REAL(),DAE.NO_INLINE()));
        e = ExpressionSimplify.simplify(e); 
    then e;
    // cos(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("cos")))
      equation
        e = DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()), DAE.BINARY(inExp1,DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("sin"),{inExp2},false,true,DAE.ET_REAL(),DAE.NO_INLINE())));
        e = ExpressionSimplify.simplify(e); 
    then e;
    // ln(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("log")))
      equation
        e = DAE.BINARY(inExp1, DAE.DIV(DAE.ET_REAL()), inExp2);
        e = ExpressionSimplify.simplify(e); 
    then e;
    // log10(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("log10")))          
      equation
        e = DAE.BINARY(inExp1, DAE.DIV(DAE.ET_REAL()), DAE.BINARY(inExp2, DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("log"),{DAE.RCONST(10.0)},false,true,DAE.ET_REAL(),DAE.NO_INLINE())));
        e = ExpressionSimplify.simplify(e); 
    then e;        
    // exp(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("exp")))    
      equation
        e = DAE.BINARY(inExp1,DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("exp"),{inExp2},false,true,DAE.ET_REAL(),DAE.NO_INLINE()));
        e = ExpressionSimplify.simplify(e); 
    then e;
    // sqrt(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("sqrt")))    
      equation
        e = DAE.BINARY(
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{inExp2},false,true,DAE.ET_REAL(),DAE.NO_INLINE()))),DAE.MUL(DAE.ET_REAL()),inExp1);
        e = ExpressionSimplify.simplify(e); 
    then e;
   // abs(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("abs")))          
      equation
        e = DAE.IFEXP(DAE.RELATION(inExp2,DAE.GREATEREQ(DAE.ET_REAL()),DAE.RCONST(0.0),-1,NONE()), inExp1, DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),inExp1));
        e = ExpressionSimplify.simplify(e); 
    then e;
    
 end match;
end mergeCall;

protected function mergeBin
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Operator inOp;
  input DAE.Exp inOrgExp1;
  input DAE.Exp inOrgExp2;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp1,inExp2,inOp,inOrgExp1,inOrgExp2)
  local
    DAE.Exp e,z1,z2;
    DAE.ExpType et;
    case (inExp1,inExp2,inOp as DAE.ADD(_), _, _)
      equation
        e = DAE.BINARY(inExp1,inOp,inExp2);
        e = ExpressionSimplify.simplify(e); 
    then e;
    case (inExp1,inExp2,inOp as DAE.SUB(_), _, _)
      equation
        e = DAE.BINARY(inExp1,inOp,inExp2);
        e = ExpressionSimplify.simplify(e); 
    then e;
    case (inExp1,inExp2,DAE.MUL(et),inOrgExp1,inOrgExp2)
      equation
        e = DAE.BINARY(DAE.BINARY(inExp1, DAE.MUL(et), inOrgExp2), DAE.ADD(et), DAE.BINARY(inOrgExp1, DAE.MUL(et), inExp2));
        e = ExpressionSimplify.simplify(e); 
    then e;
    case (inExp1,inExp2,DAE.DIV(et),inOrgExp1,inOrgExp2)
      equation
        e = DAE.BINARY(DAE.BINARY(DAE.BINARY(inExp1, DAE.MUL(et), inOrgExp2), DAE.SUB(et), DAE.BINARY(inOrgExp1, DAE.MUL(et), inExp2)), DAE.DIV(et), DAE.BINARY(inOrgExp2, DAE.MUL(et), inOrgExp2));
        e = ExpressionSimplify.simplify(e); 
    then e;
    case (inExp1,inExp2,inOp as DAE.POW(et),inOrgExp1,inOrgExp2)
      equation
      true = Expression.isConst(inOrgExp2);
      e = DAE.BINARY(inExp1, DAE.MUL(et), DAE.BINARY(inOrgExp2, DAE.MUL(et), DAE.BINARY(inOrgExp1, DAE.POW(et), DAE.BINARY(inOrgExp2, DAE.SUB(et), DAE.RCONST(1.0)))));
    then e;      
    case (inExp1,inExp2,inOp as DAE.POW(et),inOrgExp1,inOrgExp2)
      equation
        z1 = DAE.BINARY(inExp1, DAE.DIV(et), inOrgExp1);
        z1 = DAE.BINARY(inOrgExp2, DAE.MUL(et), z1);
        z2 = DAE.CALL(Absyn.IDENT("log"), {inOrgExp1}, false, true, DAE.ET_REAL(), DAE.NO_INLINE());
        z2 = DAE.BINARY(inExp2, DAE.MUL(et), z2);
        z1 = DAE.BINARY(z1, DAE.ADD(et), z2);
        z2 = DAE.BINARY(inOrgExp1, DAE.POW(et), inOrgExp2);
        z1 = DAE.BINARY(z1, DAE.MUL(et), z2);
        e = ExpressionSimplify.simplify(z1);
    then e;
 end matchcontinue;
end mergeBin;

protected function mergeIf
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inOrgExp1;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp1,inExp2,inOrgExp1)
    case (inExp1,inExp2,inOrgExp1) then DAE.IFEXP(inOrgExp1, inExp1, inExp2);
 end matchcontinue;
end mergeIf;

protected function mergeUn
  input DAE.Exp inExp1;
  input DAE.Operator inOp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp1,inOp)
  local
    DAE.Exp e;
    case (inExp1,inOp)
      equation
        e = DAE.UNARY(inOp,inExp1);
        e = ExpressionSimplify.simplify(e); 
    then e;
 end matchcontinue;
end mergeUn;

protected function mergeCast
  input DAE.Exp inExp1;
  input DAE.ExpType inType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp1,inType)
  local
    DAE.Exp e;
    case (inExp1,inType)
      equation
        e = DAE.CAST(inType,inExp1);
        e = ExpressionSimplify.simplify(e); 
    then e;
 end matchcontinue;
end mergeCast;

protected function mergeRelation
  input DAE.Exp inExp0;
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Operator inOp;
  input Integer inIndex;
  input Option<tuple<DAE.Exp,Integer,Integer>> inOptionExpisASUB;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp0,inExp1,inExp2,inOp, inIndex, inOptionExpisASUB)
  local
    DAE.Exp e;
    case (inExp0,inExp1,inExp2,inOp,inIndex,inOptionExpisASUB)
      equation
        e = DAE.RELATION(inExp1,inOp,inExp2,inIndex,inOptionExpisASUB); 
    then e;
 end matchcontinue;
end mergeRelation;

end BackendDAEOptimize;
