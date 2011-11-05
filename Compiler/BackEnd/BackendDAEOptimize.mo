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

protected import BackendDAECreate;
protected import BackendDAETransform;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVarTransform;
protected import BackendVariable;
protected import Builtin;
protected import Ceval;
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
protected import List;
protected import RTOpts;
protected import System;
protected import Util;
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
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
protected
  Option<BackendDAE.IncidenceMatrix> om,omT;
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
algorithm
  (outDAE,outRunMatching) := BackendDAEUtil.mapEqSystemAndFold1(inDAE,inlineArrayEqn1,inFunctionTree,false);
end inlineArrayEqnPast;

public function inlineArrayEqn
"function: inlineArrayEqn
autor: Frenkel TUD 2011-3"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE,_):= BackendDAEUtil.mapEqSystemAndFold1(inDAE,inlineArrayEqn1,inFunctionTree,false);
end inlineArrayEqn;

protected function inlineArrayEqn1
"function: inlineArrayEqn1
autor: Frenkel TUD 2011-5"
  input BackendDAE.EqSystem syst;
  input DAE.FunctionTree inFunctionTree;
  input tuple<BackendDAE.Shared,Boolean> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> osharedOptimized;
algorithm
  (osyst,osharedOptimized) := match (syst,inFunctionTree,sharedOptimized)
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
      BackendDAE.BackendDAE dae,dae1;
      Boolean b1,b2,b;
      BackendDAE.Shared shared;
      
    case (syst,funcs,(shared as BackendDAE.SHARED(arrayEqs = arreqns),b1))
      equation
        (syst,_,_) = BackendDAEUtil.getIncidenceMatrixfromOption(syst,shared);
        // get scalar array eqs list
        arraylisteqns = Util.arrayMap(arreqns,getScalarArrayEqns);
        // replace them
        (syst,shared,updateeqns,b2) = doReplaceScalarArrayEqns(arraylisteqns,syst,shared);
        b = b1 or b2;
        // update Incidence matrix
        syst = BackendDAEUtil.updateIncidenceMatrix(syst,shared,updateeqns);
      then
        (syst,(shared,b));
  end match;
end inlineArrayEqn1;

public function doReplaceScalarArrayEqns
"function: doReplaceScalarArrayEqns
autor: Frenkel TUD 2011-5.
  Destroys the incidence matrix: it needs to be updated afterwards..."
  input array<list<BackendDAE.Equation>> arraylisteqns;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output list<Integer> outupdateeqns;
  output Boolean optimized;
algorithm
  (osyst,oshared,outupdateeqns,optimized):=
  matchcontinue (arraylisteqns,syst,shared)
    local
      Integer len;
      BackendDAE.Variables vars,knvars,exobj;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,eqns1,remeqns,remeqns1,inieqns,inieqns1;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      list<DAE.Algorithm> algs;
      list<Integer> updateeqns;
      BackendDAE.BackendDAE dae;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.BackendDAEType btp;
      BackendDAE.Matching matching;
    case (arraylisteqns,BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching),BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,arreqns,algorithms,einfo,eoc,btp))
      equation
        len = arrayLength(arraylisteqns);
        true = intGt(len,0);
        // replace them
        (eqns1,(arraylisteqns,_,updateeqns)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(eqns,replaceScalarArrayEqns,(arraylisteqns,1,{}));
        (remeqns1,(arraylisteqns,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(remeqns,replaceScalarArrayEqns,(arraylisteqns,1,{}));
        (inieqns1,(_,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(inieqns,replaceScalarArrayEqns,(arraylisteqns,1,{}));
        syst = BackendDAE.EQSYSTEM(vars,eqns1,m,mT,matching);
        shared = BackendDAE.SHARED(knvars,exobj,av,inieqns1,remeqns1,arreqns,algorithms,einfo,eoc,btp);
      then
        (syst,shared,updateeqns,true);
    case (arraylisteqns,syst,shared)
      equation      
        len = arrayLength(arraylisteqns);
        false = intGt(len,0);
      then
        (syst,shared,{},false);
  end matchcontinue;
end doReplaceScalarArrayEqns;

public function getScalarArrayEqns"
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
      DAE.Exp e1,e2,e1_1,e2_1;
      list<DAE.Exp> ea1,ea2;
      list<tuple<DAE.Exp,DAE.Exp>> ealst;
    case BackendDAE.MULTIDIM_EQUATION(left=e1,right=e2,source=source)
      equation
        true = Expression.isArray(e1) or Expression.isMatrix(e1);
        true = Expression.isArray(e2) or Expression.isMatrix(e2);
        eqns = generateScalarArrayEqns(e1,e2,source);
      then
        eqns;
    case BackendDAE.MULTIDIM_EQUATION(left=e1 as DAE.CREF(componentRef =_),right=e2,source=source)
      equation
        true = Expression.isArray(e2) or Expression.isMatrix(e2);
        ((e1_1,(_,_))) = BackendDAEUtil.extendArrExp((e1,(NONE(),false)));
        eqns = generateScalarArrayEqns(e1_1,e2,source);
      then
        eqns; 
    case BackendDAE.MULTIDIM_EQUATION(left=e1,right=e2 as DAE.CREF(componentRef =_),source=source)
      equation
        true = Expression.isArray(e1) or Expression.isMatrix(e1);
        ((e2_1,(_,_))) = BackendDAEUtil.extendArrExp((e2,(NONE(),false)));
        eqns = generateScalarArrayEqns(e1,e2_1,source);
      then
        eqns;     
    case BackendDAE.MULTIDIM_EQUATION(left=e1 as DAE.CREF(componentRef =_),right=e2 as DAE.CREF(componentRef =_),source=source)
      equation
        ((e1_1,(_,_))) = BackendDAEUtil.extendArrExp((e1,(NONE(),false)));
        ((e2_1,(_,_))) = BackendDAEUtil.extendArrExp((e2,(NONE(),false)));
        eqns = generateScalarArrayEqns(e1_1,e2_1,source);
      then
        eqns;             
    case aeqn then {};
  end matchcontinue;
end getScalarArrayEqns;

protected function generateScalarArrayEqns"
Author: Frenkel TUD 2011-02"
  input  DAE.Exp e1;
  input  DAE.Exp e2;
  input DAE.ElementSource source;
  output list<BackendDAE.Equation> eqns;
protected
  list<DAE.Exp> ea1,ea2;
  list<tuple<DAE.Exp,DAE.Exp>> ealst;
algorithm
  ea1 := Expression.flattenArrayExpToList(e1);
  ea2 := Expression.flattenArrayExpToList(e2);
  ealst := List.threadTuple(ea1,ea2);
  eqns := List.map1(ealst,BackendEquation.generateEQUATION,source);
end generateScalarArrayEqns;

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
    output BackendDAE.BackendDAE outDAE;
    output Boolean outRunMatching;
algorithm
  outDAE := Inline.inlineCalls(SOME(inFunctionTree),{DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()},inDAE);
  outRunMatching := false;
end lateInline;

/* 
 * remove simply equations stuff
 */

public function removeSimpleEquationsPast
"function lateInlineDAE"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
protected
  Boolean b;
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
algorithm
  (outDAE,outRunMatching) := BackendDAEUtil.mapEqSystemAndFold1(inDAE,removeSimpleEquations1,inFunctionTree,false);
  outDAE := BackendDAEUtil.mapEqSystem(outDAE,BackendDAEUtil.getIncidenceMatrixfromOptionForMapEqSystem);
  // until remove simple equations does not update assignments and comps  
end removeSimpleEquationsPast;

public function removeSimpleEquations
"function: removeSimpleEquations
  autor: Frenkel TUD 2011-04
  This function moves simple equations on the form a=b and a=const and a=f(not time)
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.BackendDAE dae;
  input DAE.FunctionTree funcs;
  output BackendDAE.BackendDAE odae;
algorithm
  odae := BackendDAEUtil.mapEqSystem1(dae,removeSimpleEquationsWork,funcs);
end removeSimpleEquations;

protected function removeSimpleEquationsWork
"function: removeSimpleEquations1
  autor: Frenkel TUD 2011-05
  This function moves simple equations on the form a=b and a=const and a=f(not time)
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.EqSystem syst;
  input DAE.FunctionTree funcs;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,(oshared,_)) := removeSimpleEquations1(syst,funcs,(shared,false));
end removeSimpleEquationsWork;

protected function removeSimpleEquations1
"function: removeSimpleEquations1
  autor: Frenkel TUD 2011-05
  This function moves simple equations on the form a=b and a=const and a=f(not time)
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.EqSystem syst;
  input DAE.FunctionTree inFunctionTree;  
  input tuple<BackendDAE.Shared,Boolean> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> osharedOptimized;
algorithm
  (osyst,osharedOptimized):=
  match (syst,inFunctionTree,sharedOptimized)
    local
      BackendDAE.BackendDAE dlow,dlow1,dlow2;
      DAE.FunctionTree funcs;
      BackendDAE.IncidenceMatrix m,m_1;
      BackendDAE.IncidenceMatrixT mT,mT_1;
      Option<BackendDAE.IncidenceMatrix> om;
      Option<BackendDAE.IncidenceMatrixT> omT;
      BackendVarTransform.VariableReplacements repl,repl_1;
      BackendDAE.BinTree movedVars,movedAVars;
      list<Integer> meqns;
      Boolean b,b1,b2;
      BackendDAE.Shared shared;
    case (syst,funcs,(shared,b1))
      equation
        (syst,m,mT) = BackendDAEUtil.getIncidenceMatrixfromOption(syst,shared);
        repl = BackendVarTransform.emptyReplacements();
        // check equations
        (m_1,(syst,shared,_,mT_1,repl_1,movedVars,movedAVars,meqns,b)) = traverseIncidenceMatrix(m,removeSimpleEquationsFinder,(syst,shared,funcs,mT,repl,BackendDAE.emptyBintree,BackendDAE.emptyBintree,{},false));
        // replace vars in arrayeqns and algorithms, move vars to knvars and aliasvars, remove eqns
        (syst,shared) = removeSimpleEquations2(b,syst,shared,repl_1,movedVars,movedAVars,meqns);
      then (syst,(shared,b or b1));
  end match;
end removeSimpleEquations1;

protected function removeSimpleEquations2
"function: removeSimpleEquations2"
  input Boolean b;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input BackendVarTransform.VariableReplacements repl;
  input BackendDAE.BinTree movedVars;
  input BackendDAE.BinTree movedAVars;
  input list<Integer> meqns;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared):=
  match (b,syst,shared,repl,movedVars,movedAVars,meqns)
    local
      BackendDAE.Variables ordvars,knvars,exobj,ordvars1,knvars1,ordvars2,knvars2,ordvars3;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1,inieqns1,remeqns1,eqns2;
      array<BackendDAE.MultiDimEquation> arreqns,arreqns1;
      array<DAE.Algorithm> algorithms,algorithms1,algorithms2;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      list<list<DAE.Exp>> crefOrDerCreflst;
      array<list<DAE.Exp>> crefOrDerCrefarray;
      list<tuple<list<DAE.Exp>,list<DAE.Exp>>> inouttpllst;
      array<tuple<list<DAE.Exp>,list<DAE.Exp>>> inouttplarray;
      list<BackendDAE.WhenClause> whenClauseLst,whenClauseLst1;
      list<BackendDAE.ZeroCrossing> zeroCrossingLst;
      Boolean b;
      BackendDAE.BackendDAEType btp;      
    case (false,syst,shared,_,_,_,_) then (syst,shared);
    case (true,BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns),BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,arreqns,algorithms,BackendDAE.EVENT_INFO(whenClauseLst,zeroCrossingLst),eoc,btp),repl,movedVars,movedAVars,meqns)
      equation
        Debug.fcall("dumprepl", BackendVarTransform.dumpReplacements, repl);
        // delete alias variables from orderedVars
        ordvars1 = BackendVariable.deleteVars(movedAVars,ordvars);
        // move changed variables 
        (ordvars2,knvars1) = BackendVariable.moveVariables(ordvars1,knvars,movedVars);
        // remove changed eqns
        eqns1 = BackendEquation.equationDelete(eqns,meqns);
        // replace moved vars in vars,knvars,aliasVars,ineqns,remeqns
        (ordvars3,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(ordvars2,replaceVarTraverser,repl);
        (knvars2,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(knvars1,replaceVarTraverser,repl);
        // update arrayeqns and algorithms, collect info for wrappers
        (arreqns1,(_,_,crefOrDerCreflst)) = Util.arrayMapNoCopy_1(arreqns,replaceArrayEquationTraverser,(repl,ordvars3,{}));
        crefOrDerCrefarray = listArray(listReverse(crefOrDerCreflst));
        (algorithms1,(_,_,inouttpllst)) = Util.arrayMapNoCopy_1(algorithms,replaceAlgorithmTraverser,(repl,ordvars3,{}));
        inouttplarray = listArray(listReverse(inouttpllst));
        (eqns2,(_,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(eqns1,replaceEquationTraverser,(repl,crefOrDerCrefarray,inouttplarray));
        (inieqns1,(_,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(inieqns,replaceEquationTraverser,(repl,crefOrDerCrefarray,inouttplarray));
        (remeqns1,(_,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(remeqns,replaceEquationTraverser,(repl,crefOrDerCrefarray,inouttplarray));
        (whenClauseLst1,_) = BackendDAETransform.traverseBackendDAEExpsWhenClauseLst(whenClauseLst,replaceWhenClauseTraverser,repl);
        // update array eqn wrapper
      then (BackendDAE.EQSYSTEM(ordvars3,eqns2,NONE(),NONE(),BackendDAE.NO_MATCHING()),BackendDAE.SHARED(knvars2,exobj,aliasVars,inieqns1,remeqns1,arreqns1,algorithms1,BackendDAE.EVENT_INFO(whenClauseLst1,zeroCrossingLst),eoc,btp));
  end match;
end removeSimpleEquations2;

protected function replaceVarTraverser
"autor: Frenkel TUD 2011-03"
 input tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> inTpl;
 output tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v,v1;
      BackendVarTransform.VariableReplacements repl;
      DAE.Exp e,e1;
    case ((v as BackendDAE.VAR(bindExp=SOME(e)),repl))
      equation
        (e1,true) = BackendVarTransform.replaceExp(e, repl, NONE());
        v1 = BackendVariable.setBindExp(v,e1);
      then ((v1,repl));
    case inTpl then inTpl;
  end matchcontinue;
end replaceVarTraverser;

protected function replaceEquationTraverser
  "Help function to e.g. removeSimpleEquations"
  input tuple<BackendDAE.Equation,tuple<BackendVarTransform.VariableReplacements,array<list<DAE.Exp>>,array<tuple<list<DAE.Exp>,list<DAE.Exp>>>>> inTpl;
  output tuple<BackendDAE.Equation,tuple<BackendVarTransform.VariableReplacements,array<list<DAE.Exp>>,array<tuple<list<DAE.Exp>,list<DAE.Exp>>>>> outTpl;
algorithm
  outTpl:=  
  matchcontinue (inTpl)
    local 
      BackendDAE.Equation e,e1;
      BackendVarTransform.VariableReplacements repl;
      array<list<DAE.Exp>> crefOrDerCrefarray;
      array<tuple<list<DAE.Exp>,list<DAE.Exp>>> inouttplarray;
      Integer index;
      list<DAE.Exp> in_,out,crefOrDerCref;
      DAE.ElementSource source;
    case ((BackendDAE.ARRAY_EQUATION(index=index,source=source),(repl,crefOrDerCrefarray,inouttplarray)))
      equation
        crefOrDerCref = crefOrDerCrefarray[index+1];
      then
        ((BackendDAE.ARRAY_EQUATION(index,crefOrDerCref,source),(repl,crefOrDerCrefarray,inouttplarray)));
    case ((BackendDAE.ALGORITHM(index=index,source=source),(repl,crefOrDerCrefarray,inouttplarray)))
      equation
        ((in_,out)) = inouttplarray[index+1];
      then
        ((BackendDAE.ALGORITHM(index,in_,out,source),(repl,crefOrDerCrefarray,inouttplarray)));
    case ((e,(repl,crefOrDerCrefarray,inouttplarray)))
      equation
        {e1} = BackendVarTransform.replaceEquations({e},repl);
      then ((e1,(repl,crefOrDerCrefarray,inouttplarray)));
  end matchcontinue;
end replaceEquationTraverser;

protected function replaceArrayEquationTraverser "function: replaceArrayEquationTraverser
  author: Frenkel TUD 2010-04
  It is possible to change the equation.
"
  input tuple<BackendDAE.MultiDimEquation,tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables,list<list<DAE.Exp>>>> inTpl;
  output tuple<BackendDAE.MultiDimEquation,tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables,list<list<DAE.Exp>>>> outTpl;
algorithm
  outTpl:=
  match (inTpl)
    local 
      DAE.Exp e1,e2,e1_1,e2_1,e1_2,e2_2;
      list<Integer> dims;
      DAE.ElementSource source;
      BackendVarTransform.VariableReplacements repl;
      list<list<DAE.Exp>> crefOrDerCreflst;
      list<DAE.Exp> expl1,expl2,expl;
      BackendDAE.Variables vars;
      Boolean b1,b2;
    case ((BackendDAE.MULTIDIM_EQUATION(dims,e1,e2,source),(repl,vars,crefOrDerCreflst)))
      equation
        (e1_1,_) = BackendVarTransform.replaceExp(e1, repl,NONE());
        (e2_1,_) = BackendVarTransform.replaceExp(e2, repl,NONE());
        (e1_2,b1) = ExpressionSimplify.simplify(e1_1);
        (e2_2,b2) = ExpressionSimplify.simplify(e2_1);
        source = DAEUtil.addSymbolicTransformationSimplify(b1,source,e1,e1_2);
        source = DAEUtil.addSymbolicTransformationSimplify(b2,source,e2,e2_2);        
        expl1 = BackendDAEUtil.statesAndVarsExp(e1_2, vars);
        expl2 = BackendDAEUtil.statesAndVarsExp(e2_2, vars);
        expl = listAppend(expl1, expl2);
      then
        ((BackendDAE.MULTIDIM_EQUATION(dims,e1_2,e2_2,source),(repl,vars,expl::crefOrDerCreflst)));
  end match;
end replaceArrayEquationTraverser;

protected function replaceWhenClauseTraverser "function: replaceWhenClauseTraverser
  author: Frenkel TUD 2010-04
  It is possible to change the when clause.
"
  input tuple<DAE.Exp,BackendVarTransform.VariableReplacements> inTpl;
  output tuple<DAE.Exp,BackendVarTransform.VariableReplacements> outTpl;
algorithm
  outTpl:=
  match (inTpl)
    local 
      DAE.Exp e,e1;
      DAE.ElementSource source;      
      BackendVarTransform.VariableReplacements repl;
    case ((e,repl))
      equation
        (e1,_) = BackendVarTransform.replaceExp(e, repl, NONE());
      then
        ((e1,repl));
    case inTpl then inTpl;
  end match;
end replaceWhenClauseTraverser;

protected function replaceAlgorithmTraverser "function: replaceAlgorithmTraverser
  author: Frenkel TUD 2010-04
  It is possible to change the algorithm.
"
  input tuple<DAE.Algorithm,tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables,list<tuple<list<DAE.Exp>,list<DAE.Exp>>>>> inTpl;
  output tuple<DAE.Algorithm,tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables,list<tuple<list<DAE.Exp>,list<DAE.Exp>>>>> outTpl;
algorithm
  outTpl:=
  match (inTpl)
    local 
      list<DAE.Statement> statementLst,statementLst_1;
      BackendVarTransform.VariableReplacements repl;
      list<tuple<list<DAE.Exp>,list<DAE.Exp>>> inouttpllst;
      tuple<list<DAE.Exp>,list<DAE.Exp>> inouttpl;
      BackendDAE.Variables vars;
      DAE.Algorithm alg;
    case ((DAE.ALGORITHM_STMTS(statementLst=statementLst),(repl,vars,inouttpllst)))
      equation
        (statementLst_1,_) = BackendVarTransform.replaceStatementLst(statementLst,repl);
        alg = DAE.ALGORITHM_STMTS(statementLst_1);
        inouttpl = BackendDAECreate.lowerAlgorithmInputsOutputs(vars,alg);
      then
        ((alg,(repl,vars,inouttpl::inouttpllst)));
  end match;
end replaceAlgorithmTraverser;

protected function updateEquationWrapper
  "Help function to e.g. removeSimpleEquations"
  input tuple<BackendDAE.Equation,tuple<array<list<DAE.Exp>>,array<tuple<list<DAE.Exp>,list<DAE.Exp>>>>> inTpl;
  output tuple<BackendDAE.Equation,tuple<array<list<DAE.Exp>>,array<tuple<list<DAE.Exp>,list<DAE.Exp>>>>> outTpl;
algorithm
  outTpl:=  
  matchcontinue (inTpl)
    local 
      array<list<DAE.Exp>> crefOrDerCrefarray;
      array<tuple<list<DAE.Exp>,list<DAE.Exp>>> inouttplarray;
      Integer index;
      list<DAE.Exp> in_,out,crefOrDerCref;
      DAE.ElementSource source;
    case ((BackendDAE.ARRAY_EQUATION(index=index,source=source),(crefOrDerCrefarray,inouttplarray)))
      equation
        crefOrDerCref = crefOrDerCrefarray[index+1];
      then
        ((BackendDAE.ARRAY_EQUATION(index,crefOrDerCref,source),(crefOrDerCrefarray,inouttplarray)));
    case ((BackendDAE.ALGORITHM(index=index,source=source),(crefOrDerCrefarray,inouttplarray)))
      equation
        ((in_,out)) = inouttplarray[index+1];
      then
        ((BackendDAE.ALGORITHM(index,in_,out,source),(crefOrDerCrefarray,inouttplarray)));
    case inTpl then inTpl;
  end matchcontinue;
end updateEquationWrapper;

protected function removeSimpleEquationsFinder
"autor: Frenkel TUD 2010-12"
 input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix, tuple<BackendDAE.EqSystem,BackendDAE.Shared,DAE.FunctionTree,BackendDAE.IncidenceMatrixT,BackendVarTransform.VariableReplacements,BackendDAE.BinTree,BackendDAE.BinTree,list<Integer>,Boolean>> inTpl;
 output tuple<list<Integer>,BackendDAE.IncidenceMatrix, tuple<BackendDAE.EqSystem,BackendDAE.Shared,DAE.FunctionTree,BackendDAE.IncidenceMatrixT,BackendVarTransform.VariableReplacements,BackendDAE.BinTree,BackendDAE.BinTree,list<Integer>,Boolean>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.IncidenceMatrixElement elem;
      Integer pos,l,i,eqnType,pos_1;
      BackendDAE.IncidenceMatrix m,m1,mT,mT1;
      BackendDAE.BackendDAE dae,dae1,dae2;
      BackendVarTransform.VariableReplacements repl,repl_1;
      BackendDAE.BinTree mvars,mvars_1,mavars,mavars_1;
      list<Integer> meqns,meqns1,vareqns;
      BackendDAE.Variables v,kn,v1,v2;
      BackendDAE.EquationArray eqns,eqns1;
      BackendDAE.Var var;
      DAE.ComponentRef cr;
      DAE.Exp exp,e1,e2;
      DAE.FunctionTree funcs;
      Boolean b;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case ((elem,pos,m,(syst as BackendDAE.EQSYSTEM(orderedEqs=eqns),shared,funcs,mT,repl,mvars,mavars,meqns,_)))
      equation
        // check number of vars in eqns
        l = listLength(elem);
        true = intEq(l,0);
        pos_1 = pos-1;
        BackendDAE.EQUATION(exp=e1,scalar=e2) = BackendDAEUtil.equationNth(eqns,pos_1);
        true = Expression.isConst(e1);
        true = Expression.expEqual(e1,e2);
      then (({},m,(syst,shared,funcs,mT,repl,mvars,mavars,pos_1::meqns,true)));      
    case ((elem,pos,m,(syst,shared,funcs,mT,repl,mvars,mavars,meqns,_)))
      equation
        // check number of vars in eqns
        l = listLength(elem);
        true = intLt(l,3);
        true = intGt(l,0);
        (cr,i,exp,syst,shared,mvars_1,mavars_1,eqnType) = simpleEquation(elem,l,pos,syst,shared,mvars,mavars);
        // replace equation if necesarry
        (vareqns,syst,shared,m1,mT1,repl_1,meqns1) = replacementsInEqns(eqnType,cr,i,exp,pos,repl,syst,shared,m,mT,meqns,funcs);
      then ((vareqns,m1,(syst,shared,funcs,mT1,repl_1,mvars_1,mavars_1,meqns1,true)));
    case ((elem,pos,m,(syst,shared,funcs,mT,repl,mvars,mavars,meqns,b)))
      then (({},m,(syst,shared,funcs,mT,repl,mvars,mavars,meqns,b))); 
  end matchcontinue;
end removeSimpleEquationsFinder;

protected function replacementsInEqns
"function: replacementsInEqns
  author: Frenkel TUD 2011-04"
  input Integer eqnType;
  input DAE.ComponentRef cr;
  input Integer i;
  input DAE.Exp exp;
  input Integer pos;
  input BackendVarTransform.VariableReplacements repl;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrix mT;
  input list<Integer> inMeqns;
  input DAE.FunctionTree inFuncs;
  output list<Integer> outVareqns;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.IncidenceMatrix om;
  output BackendDAE.IncidenceMatrix omT;
  output BackendVarTransform.VariableReplacements outRepl;
  output list<Integer> outMeqns;
algorithm
  (outVareqns,osyst,oshared,om,omT,outRepl,outMeqns):=
  match (eqnType,cr,i,exp,pos,repl,syst,shared,m,mT,inMeqns,inFuncs)
    local
      BackendDAE.BackendDAE dae;
      BackendDAE.Variables ordvars,knvars,exobj,ordvars1,knvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1,eqns2;
      array<BackendDAE.MultiDimEquation> arreqns,arreqns1;
      array<DAE.Algorithm> algorithms,algorithms1;
      BackendDAE.EventInfo einfo,einfo1;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.IncidenceMatrix m1;
      BackendDAE.IncidenceMatrixT mT1;
      Integer pos_1;
      list<Integer> vareqns,vareqns1,vareqns2,meqns;
      BackendVarTransform.VariableReplacements repl_1;
      BackendDAE.Var v;
      BackendDAE.BackendDAEType btp;   
    case (0,cr,i,exp,pos,repl,BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns),BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,arreqns,algorithms,einfo,eoc,btp),m,mT,meqns,inFuncs)
      equation
        // equations of var
        vareqns = mT[i];
        vareqns1 = List.removeOnTrue(pos,intEq,vareqns);
        // remove var from vars
        (ordvars1,v) = BackendVariable.removeVar(i,ordvars);
        knvars1 = BackendVariable.addVar(v,knvars);
        // update IncidenceMatrix
        syst = BackendDAE.EQSYSTEM(ordvars1,eqns,SOME(m),SOME(mT),BackendDAE.NO_MATCHING());
        shared = BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,arreqns,algorithms,einfo,eoc,btp);
        (syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mT))) = BackendDAEUtil.updateIncidenceMatrix(syst,shared,vareqns);
        pos_1 = pos - 1;
      then (vareqns1,syst,shared,m,mT,repl,pos_1::meqns);
    case (1,cr,i,exp,pos,repl,BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns),shared,m,mT,meqns,inFuncs)
      equation
        // equations of var
        vareqns = mT[i];
        vareqns1 = List.removeOnTrue(pos,intEq,vareqns);
        // update Replacements
        repl_1 = BackendVarTransform.addReplacement(repl, cr, exp);
        // replace var=exp in vareqns
        eqns1 = replacementsInEqns1(vareqns1,repl_1,eqns);
        // set eqn to 0=0 to avoid next call
        pos_1 = pos-1;
        eqns2 =  BackendEquation.equationSetnth(eqns1,pos_1,BackendDAE.EQUATION(DAE.RCONST(0.0),DAE.RCONST(0.0),DAE.emptyElementSource));
        // update IncidenceMatrix
        syst = BackendDAE.EQSYSTEM(ordvars,eqns2,SOME(m),SOME(mT),BackendDAE.NO_MATCHING());
        (syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mT))) = BackendDAEUtil.updateIncidenceMatrix(syst,shared,vareqns);
      then (vareqns1,syst,shared,m,mT,repl_1,pos_1::meqns);
    case (2,cr,i,exp,pos,repl,BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns),BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,arreqns,algorithms,einfo,eoc,btp),m,mT,meqns,inFuncs)
      equation
        // equations of var
        vareqns = mT[i];
        vareqns1 = List.removeOnTrue(pos,intEq,vareqns);
        vareqns2 = List.removeOnTrue(0,intGt,vareqns1);
        // replace der(a)=b in vareqns
        (eqns1,arreqns1,algorithms1,einfo1) = replacementsInEqns2(vareqns2,exp,cr,eqns,arreqns,algorithms,einfo);
        // update IncidenceMatrix
        syst = BackendDAE.EQSYSTEM(ordvars,eqns1,SOME(m),SOME(mT),BackendDAE.NO_MATCHING());
        shared = BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,arreqns1,algorithms1,einfo1,eoc,btp);
        (syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mT))) = BackendDAEUtil.updateIncidenceMatrix(syst,shared,vareqns);
      then (vareqns2,syst,shared,m,mT,repl,meqns);
  end match;
end replacementsInEqns;

protected function replacementsInEqns1
"function: replacementsInEqns1
  author: Frenkel TUD 2011-04"
  input list<Integer> inEqsLst;
  input BackendVarTransform.VariableReplacements repl;
  input BackendDAE.EquationArray inEqns;
  output BackendDAE.EquationArray outEqns;
algorithm
  outEqns:=
  match (inEqsLst,repl,inEqns)
    local
      BackendDAE.EquationArray eqns,eqns1,eqns2;
      BackendDAE.Equation eqn,eqn1;
      Integer pos,pos_1;
      list<Integer> rest;
    case ({},_,eqns) then eqns;
    case (pos::rest,repl,eqns)
      equation
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        {eqn1} = BackendVarTransform.replaceEquations({eqn},repl);
        eqns1 =  BackendEquation.equationSetnth(eqns,pos_1,eqn1);
        eqns2 = replacementsInEqns1(rest,repl,eqns1);
      then eqns2;
  end match;
end replacementsInEqns1;

protected function replacementsInEqns2
"function: replacementsInEqns1
  author: Frenkel TUD 2011-04"
  input list<Integer> inEqsLst;
  input DAE.Exp derExp;
  input DAE.ComponentRef inCr;
  input BackendDAE.EquationArray inEqns;
  input array<BackendDAE.MultiDimEquation> inArreqns;
  input array<DAE.Algorithm> inAlgs;
  input  BackendDAE.EventInfo inEinfo;
  output BackendDAE.EquationArray outEqns;
  output array<BackendDAE.MultiDimEquation> outArreqns;
  output array<DAE.Algorithm> outAlgs;
  output  BackendDAE.EventInfo outEinfo;
algorithm
  (outEqns,outArreqns,outAlgs,outEinfo):=
  match (inEqsLst,derExp,inCr,inEqns,inArreqns,inAlgs,inEinfo)
    local
      BackendDAE.EquationArray eqns,eqns1,eqns2;
      array<BackendDAE.MultiDimEquation> ae,ae1,ae2;
      array<DAE.Algorithm> al,al1,al2;
      list<BackendDAE.WhenClause> wclst,wclst1;
      list<BackendDAE.ZeroCrossing> zcl;
      BackendDAE.EventInfo einfo;
      BackendDAE.Equation eqn,eqn1;
      Integer pos,pos_1;
      list<Integer> rest;
    case ({},_,_,eqns,inArreqns,inAlgs,inEinfo) then (eqns,inArreqns,inAlgs,inEinfo);
    case (pos::rest,derExp,inCr,eqns,inArreqns,inAlgs,BackendDAE.EVENT_INFO(whenClauseLst=wclst,zeroCrossingLst=zcl))
      equation
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        (eqn1,al1,ae1,wclst1,_) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn, inAlgs, inArreqns, wclst, replaceAliasDer,(derExp,inCr));
        eqns1 =  BackendEquation.equationSetnth(eqns,pos_1,eqn1);
        (eqns2,ae2,al2,einfo) = replacementsInEqns2(rest,derExp,inCr,eqns1,ae1,al1,BackendDAE.EVENT_INFO(wclst1,zcl));
      then (eqns2,ae2,al2,einfo);
  end match;
end replacementsInEqns2;

public function replaceAliasDer
"function: replaceAliasDer
  author: Frenkel TUD"
  input tuple<DAE.Exp,tuple<DAE.Exp,DAE.ComponentRef>> inTpl;
  output tuple<DAE.Exp,tuple<DAE.Exp,DAE.ComponentRef>> outTpl;
protected
  DAE.Exp e;
  tuple<DAE.Exp,DAE.ComponentRef> dercr;
algorithm
  (e,dercr) := inTpl;
  outTpl := Expression.traverseExp(e,replaceAliasDerFinder,dercr);
end replaceAliasDer;

protected function replaceAliasDerFinder
"function: replaceAliasDerFinder
  author: Frenkel TUD
  Helper function for replaceAliasDer"
  input tuple<DAE.Exp,tuple<DAE.Exp,DAE.ComponentRef>> inExp;
  output tuple<DAE.Exp,tuple<DAE.Exp,DAE.ComponentRef>> outExp;
algorithm
  (outExp) := matchcontinue (inExp)
    local
      DAE.Exp e,de;
      DAE.ComponentRef dcr,cr;

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(de,dcr)))
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr,dcr);
      then
        ((de,(de,dcr)));
    case inExp then inExp;
  end matchcontinue;
end replaceAliasDerFinder;

protected function simpleEquation 
" function: simpleEquation
  autor: Frenkel TUD 2011-04"
  input BackendDAE.IncidenceMatrixElement elem;
  input Integer length;
  input Integer pos;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input BackendDAE.BinTree mvars;
  input BackendDAE.BinTree mavars;
  output DAE.ComponentRef outCr;
  output Integer outPos;
  output DAE.Exp outExp;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.BinTree outMvars;
  output BackendDAE.BinTree outMavars;
  output Integer eqnType;
algorithm
  (outCr,outPos,outExp,osyst,oshared,outMvars,outMavars,eqnType) := matchcontinue(elem,length,pos,syst,shared,mvars,mavars)
    local 
      DAE.ComponentRef cr,cr2;
      Integer i,j,pos_1,k,eqTy;
      DAE.Exp es,cre,e1,e2;
      BackendDAE.BinTree newvars,newvars1;
      BackendDAE.Variables vars,knvars;
      BackendDAE.Var var,var2,var3;
      BackendDAE.BackendDAE dae1;
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn;
      Boolean negate;
      DAE.ElementSource source;
    // a = const
    // wbraun:
    // speacial case for Jacobains, since there are all known variablen
    // time depending input variables
    case ({i},length,pos,syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared as BackendDAE.SHARED(backendDAEType = BackendDAE.JACOBIAN()),mvars,mavars)
      equation
        var = BackendVariable.getVarAt(vars,intAbs(i));
        // no State
        false = BackendVariable.isStateorStateDerVar(var);
        // try to solve the equation
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        BackendDAE.EQUATION(exp=e1,scalar=e2,source=source) = eqn;
        // variable time not there
        knvars = BackendVariable.daeKnVars(shared);
        ((_,(false,_,_,_))) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,knvars,true));
        ((_,(false,_,_,_))) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,knvars,true));
        cr = BackendVariable.varCref(var);
        cre = Expression.crefExp(cr);
        (es,{}) = ExpressionSolve.solve(e1,e2,cre);
        source = DAEUtil.addSymbolicTransformation(source,DAE.SOLVE(cr,e1,e2,es,{}));
        // constant or alias
        (syst,shared,newvars,newvars1,eqTy) = constOrAlias(var,cr,es,syst,shared,mvars,mavars,DAEUtil.getSymbolicTransformations(source));
      then (cr,i,es,syst,shared,newvars,newvars1,eqTy);
    // a = const
    case ({i},length,pos,syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,mvars,mavars)
      equation
        var = BackendVariable.getVarAt(vars,intAbs(i));
        // no State
        false = BackendVariable.isStateorStateDerVar(var);
        // try to solve the equation
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        BackendDAE.EQUATION(exp=e1,scalar=e2,source=source) = eqn;
        // variable time not there
        knvars = BackendVariable.daeKnVars(shared);
        ((_,(false,_,_,_))) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,knvars,false));
        ((_,(false,_,_,_))) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,knvars,false));
        cr = BackendVariable.varCref(var);
        cre = Expression.crefExp(cr);
        (es,{}) = ExpressionSolve.solve(e1,e2,cre);
        source = DAEUtil.addSymbolicTransformation(source,DAE.SOLVE(cr,e1,e2,es,{}));
        // constant or alias
        (syst,shared,newvars,newvars1,eqTy) = constOrAlias(var,cr,es,syst,shared,mvars,mavars,DAEUtil.getSymbolicTransformations(source));
      then (cr,i,es,syst,shared,newvars,newvars1,eqTy);        
    // a = der(b) 
    case ({i,j},length,pos,syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,mvars,mavars)
      equation
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        (cr,_,es,_,negate) = BackendEquation.derivativeEquation(eqn);
        // select candidate
        ((_::_),(k::_)) = BackendVariable.getVar(cr,vars);
      then (cr,k,es,syst,shared,mvars,mavars,2);
    // a = b 
    case ({i,j},length,pos,syst as BackendDAE.EQSYSTEM(orderedEqs=eqns),shared,mvars,mavars)
      equation
        pos_1 = pos-1;
        (eqn as BackendDAE.EQUATION(source=source)) = BackendDAEUtil.equationNth(eqns,pos_1);
        (cr,cr2,e1,e2,negate) = BackendEquation.aliasEquation(eqn);
        // select candidate
        (cr,es,k,syst,shared,newvars) = selectAlias(cr,cr2,e1,e2,syst,shared,mavars,negate,source);
      then (cr,k,es,syst,shared,mvars,newvars,1);
  end matchcontinue;
end simpleEquation;

protected function constOrAlias
"function constOrAlias
  autor Frenkel TUD 2011-04"
  input BackendDAE.Var var;
  input DAE.ComponentRef cr;
  input DAE.Exp exp;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input BackendDAE.BinTree mvars;
  input BackendDAE.BinTree mavars;
  input list<DAE.SymbolicOperation> ops;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.BinTree outMvars;
  output BackendDAE.BinTree outMavars;
  output Integer eqnType;
algorithm
  (osyst,oshared,outMvars,outMavars,eqnType) := matchcontinue (var,cr,exp,syst,shared,mvars,mavars,ops)
    local
      DAE.ComponentRef cr,cra;
      BackendDAE.BinTree newvars;
      BackendDAE.VarKind kind;
      BackendDAE.Var var,var2,var3,var4,v,v1;
      BackendDAE.BackendDAE dae1,dae2;
      Boolean constExp,negate;
      BackendDAE.Variables knvars;
      Integer eqTy;
    // alias a
    case (var,cr,exp,syst,shared,mvars,mavars,ops)
      equation
        (negate,cra) = aliasExp(exp);
        // no State
        false = BackendVariable.isStateorStateDerVar(var) "cr1 not state";
        kind = BackendVariable.varKind(var);
        BackendVariable.isVarKindVariable(kind) "cr1 not constant";
        //false = BackendVariable.isVarOnTopLevelAndOutput(var);
        //false = BackendVariable.isVarOnTopLevelAndInput(var);
        //failure( _ = BackendVariable.varStartValueFail(var));
        Debug.fcall("debugAlias",BackendDump.debugStrCrefStrExpStr,("Alias Equation ",cr," = ",exp," found (1).\n"));
        knvars = BackendVariable.daeKnVars(shared);
        ((v::_),_) = BackendVariable.getVar(cra,knvars);
        // merge fixed,start,nominal
        v1 = mergeAliasVars(v,var,negate);
        shared = BackendVariable.addKnVarDAE(v1,shared);
        // store changed var
        var = BackendVariable.mergeVariableOperations(var,DAE.SOLVED(cr,exp)::ops);
        newvars = BackendDAEUtil.treeAdd(mavars, cr, 0);
        shared = BackendDAEUtil.updateAliasVariablesDAE(cr,exp,var,shared);
      then
        (syst,shared,mvars,newvars,1);     
    // const
    case (var,cr,exp,syst,shared,mvars,mavars,ops)
      equation
        // add bindExp
        var2 = BackendVariable.setBindExp(var,exp);
        // add bindValue if constant
        (var3,constExp) = setbindValue(exp,var2);
        var3 = BackendVariable.mergeVariableOperations(var3,DAE.SOLVED(cr,exp)::ops);
        // update vars
        syst = BackendVariable.addVarDAE(var3,syst);
        // store changed var
        Debug.fcall("debugAlias",BackendDump.debugStrCrefStrExpStr,("Const Equation ",cr," = ",exp," found (2).\n"));
        newvars = BackendDAEUtil.treeAdd(mvars, cr, 0);
        eqTy = Util.if_(constExp,1,0);
      then
        (syst,shared,newvars,mavars,eqTy);      
  end matchcontinue;
end constOrAlias;

protected function aliasExp
"function aliasExp
  autor Frenkel TUD 2011-04"
  input DAE.Exp exp;
  output Boolean negate;
  output DAE.ComponentRef outCr;
algorithm
  (negate,outCr) := matchcontinue (exp)
    local DAE.ComponentRef cr;
    // alias a
    case (DAE.CREF(componentRef = cr)) then (false,cr);
    // alias -a
    case (DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr))) then (true,cr);
    // alias -a
    case (DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr))) then (true,cr);
  end matchcontinue;
end aliasExp;

protected function selectAlias
"function selectAlias
  autor Frenkel TUD 2011-04
  select the alias variable. Prefer scalars
  or elements of already replaced arrays or records."
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input DAE.Exp e1;
  input DAE.Exp e2;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input BackendDAE.BinTree mavars;
  input Boolean negate;
  input DAE.ElementSource source;
  output DAE.ComponentRef cr;
  output DAE.Exp exp;
  output Integer k;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.BinTree newvars;
protected
  BackendDAE.Variables vars;
  BackendDAE.Var var1,var2;
  Integer ipos1,ipos2;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars) := syst;
  ((var1::_),(ipos1::_)) := BackendVariable.getVar(cr1,vars);
  ((var2::_),(ipos2::_)) := BackendVariable.getVar(cr2,vars);
  (cr,exp,k,osyst,oshared,newvars) := selectAlias1(cr1,cr2,var1,var2,ipos1,ipos2,e1,e2,syst,shared,mavars,negate,source);
end selectAlias;

protected function replaceableAlias
"function replaceableAlias
  autor Frenkel TUD 2011-08
  check if the variable is a replaceable alias."
  input BackendDAE.Var var;
algorithm
  _ := match (var)
    local
      BackendDAE.VarKind kind;
    case (var)
      equation
        // no State
        false = BackendVariable.isStateorStateDerVar(var) "cr1 not state";
        kind = BackendVariable.varKind(var);
        BackendVariable.isVarKindVariable(kind) "cr1 not constant";
        false = BackendVariable.isVarOnTopLevelAndOutput(var);
        false = BackendVariable.isVarOnTopLevelAndInput(var);
      then
        ();
  end match;
end replaceableAlias;

protected function selectAlias1
"function selectAlias1
  autor Frenkel TUD 2011-04
  helper for selectAlias."
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input BackendDAE.Var var1;
  input BackendDAE.Var var2;
  input Integer ipos1;
  input Integer ipos2;
  input DAE.Exp e1;
  input DAE.Exp e2;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input BackendDAE.BinTree mavars;
  input Boolean negate;
  input DAE.ElementSource source;
  output DAE.ComponentRef cr;
  output DAE.Exp exp;
  output Integer k;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.BinTree newvars;
algorithm
  (cr,exp,k,osyst,oshared,newvars) := matchcontinue (cr1,cr2,var1,var2,ipos1,ipos2,e1,e2,syst,shared,mavars,negate,source)
    local
      DAE.ComponentRef acr,cr;
      BackendDAE.BinTree newvars;
      BackendDAE.Var avar,var;
      DAE.Exp ae,e;
      Integer aipos,i1,i2;
      Boolean b;
      
    case (cr1,cr2,var1,var2,ipos1,ipos2,e1,e2,syst,shared,mavars,negate,source)
      equation
        replaceableAlias(var1);
        replaceableAlias(var2);
        i1 = calcAliasKey(cr1,var1);
        i2 = calcAliasKey(cr2,var2);
        b = intGt(i2,i1);
        ((acr,avar,aipos,ae,cr,var,e)) = Util.if_(b,(cr2,var2,ipos2,e2,cr1,var1,e1),(cr1,var1,ipos1,e1,cr2,var2,e2));
        (syst,shared,newvars) = selectAlias2(acr,cr,avar,var,ae,e,syst,shared,mavars,negate,source);
      then
        (acr,e,aipos,syst,shared,newvars);
    case (cr1,cr2,var1,var2,ipos1,ipos2,e1,e2,syst,shared,mavars,negate,source)
      equation
        replaceableAlias(var1);
        (syst,shared,newvars) = selectAlias2(cr1,cr2,var1,var2,e1,e2,syst,shared,mavars,negate,source);
      then
        (cr1,e2,ipos1,syst,shared,newvars);
    case (cr1,cr2,var1,var2,ipos1,ipos2,e1,e2,syst,shared,mavars,negate,source)
      equation
        replaceableAlias(var2);
        (syst,shared,newvars) = selectAlias2(cr2,cr1,var2,var1,e2,e1,syst,shared,mavars,negate,source);
      then
        (cr2,e1,ipos2,syst,shared,newvars);        
  end matchcontinue;
end selectAlias1;

protected function calcAliasKey
"function calcAliasKey
  autor Frenkel TUD 2011-04
  helper for selectAlias."
  input DAE.ComponentRef cr;
  input BackendDAE.Var var;
  output Integer i;
protected 
  Boolean b;
algorithm
  // records
  b := ComponentReference.isRecord(cr);
  i := Util.if_(b,-1,0);
  // array elements
  b := ComponentReference.isArrayElement(cr);
  i := intAdd(i,Util.if_(b,-1,0));
  // connectors
  b := BackendVariable.isVarConnector(var);
  i := intAdd(i,Util.if_(b,1,0));
end calcAliasKey;

protected function selectAlias2
"function selectAlias2
  autor Frenkel TUD 2011-08
  helper for selectAlias."
  input DAE.ComponentRef acr;
  input DAE.ComponentRef cr;
  input BackendDAE.Var avar;
  input BackendDAE.Var var;
  input DAE.Exp ae;
  input DAE.Exp e;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input BackendDAE.BinTree mavars;
  input Boolean negate;
  input DAE.ElementSource source;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.BinTree newvars;
protected
  BackendDAE.Var v1;
  list<DAE.SymbolicOperation> ops;
algorithm
  Debug.fcall("debugAlias",BackendDump.debugStrCrefStrExpStr,("Alias Equation ",acr," = ",e," found (2).\n"));
  // merge fixed,start,nominal
  v1 := mergeAliasVars(var,avar,negate);
  osyst := BackendVariable.addVarDAE(v1,syst);
  // store changed var
  newvars := BackendDAEUtil.treeAdd(mavars, acr, 0);
  ops := DAEUtil.getSymbolicTransformations(source);
  var := BackendVariable.mergeVariableOperations(avar,DAE.SOLVED(acr,e)::ops);
  oshared := BackendDAEUtil.updateAliasVariablesDAE(acr,e,var,shared);
end selectAlias2;

protected function mergeAliasVars
"autor: Frenkel TUD 2011-04"
  input BackendDAE.Var inVar;
  input BackendDAE.Var inAVar "the alias var";
  input Boolean negate;
  output BackendDAE.Var outVar;
protected
  BackendDAE.Var v,va,v1,v2;
  Boolean fixeda, fixed,fixeda,f;
  Option<DAE.Exp> sv,sva;
  DAE.Exp start;
algorithm
  // get attributes
  // fixed
  fixed := BackendVariable.varFixed(inVar);
  fixeda := BackendVariable.varFixed(inAVar);
  // start
  sv := BackendVariable.varStartValueOption(inVar);
  sva := BackendVariable.varStartValueOption(inAVar);
  (v1) := mergeStartFixed(inVar,fixed,sv,inAVar,fixeda,sva,negate);
  // nominal
  v2 := mergeNomnialAttribute(inAVar,v1,negate);
  // minmax
  outVar := mergeMinMaxAttribute(inAVar,v2,negate);
end mergeAliasVars;

protected function mergeStartFixed
"autor: Frenkel TUD 2011-04"
  input BackendDAE.Var inVar;
  input Boolean fixed;
  input Option<DAE.Exp> sv;
  input BackendDAE.Var inAVar;
  input Boolean fixeda;
  input Option<DAE.Exp> sva;
  input Boolean negate;
  output BackendDAE.Var outVar;
algorithm
  outVar :=
  matchcontinue (inVar,fixed,sv,inAVar,fixeda,sva,negate)
    local
      BackendDAE.Var v,va,v1,v2;
      DAE.ComponentRef cr,cra;
      DAE.Exp sa,sb,e;
      Boolean b1,b2,b3;
      String s,s1,s2,s3,s4,s5;
    case (v as BackendDAE.VAR(varName=cr),true,SOME(sa),va as BackendDAE.VAR(varName=cra),true,SOME(sb),negate)
      equation
        e = getNonZeroStart(sa,sb,negate);
        v1 = BackendVariable.setVarStartValue(v,e);
      then v1;     
    case (v as BackendDAE.VAR(varName=cr),true,SOME(sa),va as BackendDAE.VAR(varName=cra),true,SOME(sb),negate)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = Util.if_(negate," = -"," = ");
        s3 = ComponentReference.printComponentRefStr(cra);
        s4 = ExpressionDump.printExpStr(sa);
        s5 = ExpressionDump.printExpStr(sb);
        s = stringAppendList({"Alias variables ",s1,s2,s3," both fixed and have start values ",s4," != ",s5,". Use value from ",s1,".\n"});
        Error.addMessage(Error.COMPILER_WARNING,{s});
      then v;
    case (v,true,SOME(sa),va,true,NONE(),negate)
      then v;
    case (v,true,SOME(sa),va,false,SOME(sb),negate)
      equation
        e = getNonZeroStart(sa,sb,negate);
        v1 = BackendVariable.setVarStartValue(v,e);
      then v1;     
    case (v as BackendDAE.VAR(varName=cr),true,SOME(sa),va as BackendDAE.VAR(varName=cra),false,SOME(sb),negate)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = Util.if_(negate," = -"," = ");
        s3 = ComponentReference.printComponentRefStr(cra);
        s4 = ExpressionDump.printExpStr(sa);
        s5 = ExpressionDump.printExpStr(sb);
        s = stringAppendList({"Alias variables ",s1,s2,s3," have start values ",s4," != ",s5,". Use value from ",s1," because this is fixed.\n"});
        Error.addMessage(Error.COMPILER_WARNING,{s});        
      then v;
    case (v,true,SOME(sa),va,false,NONE(),negate)
      then v;
    case (v,true,NONE(),va,true,SOME(sb),negate)
      equation
        v1 = BackendVariable.setVarStartValue(v,sb); 
      then v1;
    case (v,true,NONE(),va,true,NONE(),negate)
      then v;
    case (v,true,NONE(),va,false,SOME(sb),negate)
      equation
        v1 = BackendVariable.setVarStartValue(v,sb); 
      then v1;
    case (v,true,NONE(),va,false,NONE(),negate)
      then v;   
    case (v,false,SOME(sa),va,true,SOME(sb),negate)
      equation
        e = getNonZeroStart(sa,sb,negate);
        v1 = BackendVariable.setVarStartValue(v,e);
        v2 = BackendVariable.setVarFixed(v1,true);
      then v2;
    case (v,false,SOME(sa),va,true,NONE(),negate)
      equation
        v1 = BackendVariable.setVarFixed(v,true);
      then v1;
    case (v,false,SOME(sa),va,false,SOME(sb),negate)
      equation
        e = getNonZeroStart(sa,sb,negate);
        v1 = BackendVariable.setVarStartValue(v,e);
      then v1;     
    case (v as BackendDAE.VAR(varName=cr),false,SOME(sa),va as BackendDAE.VAR(varName=cra),false,SOME(sb),negate)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = Util.if_(negate," = -"," = ");
        s3 = ComponentReference.printComponentRefStr(cra);
        s4 = ExpressionDump.printExpStr(sa);
        s5 = ExpressionDump.printExpStr(sb);
        s = stringAppendList({"Alias variables ",s1,s2,s3," have start values ",s4," != ",s5,". Use value from ",s1,".\n"});
        Error.addMessage(Error.COMPILER_WARNING,{s});        
      then v;
    case (v,false,SOME(sa),va,false,NONE(),negate)
      then v;
    case (v,false,NONE(),va,true,SOME(sb),negate)
      equation
        e = negateif(negate,sb);
        v1 = BackendVariable.setVarStartValue(v,e);
        v2 = BackendVariable.setVarFixed(v1,true);
      then v2;
    case (v,false,NONE(),va,true,NONE(),negate)
      equation
        v1 = BackendVariable.setVarFixed(v,true);
      then v1;
    case (v,false,NONE(),va,false,SOME(sb),negate)
      equation
        e = negateif(negate,sb);
        v1 = BackendVariable.setVarStartValue(v,e);
      then v1;
    case (v,false,NONE(),va,false,NONE(),negate)
      then v; 
  end matchcontinue;
end mergeStartFixed;

protected function getNonZeroStart
"autor: Frenkel TUD 2011-04"
  input DAE.Exp exp1;
  input DAE.Exp exp2;
  input Boolean negate;
  output DAE.Exp outExp;
algorithm
  outExp :=
  matchcontinue (exp1,exp2,negate)
    local
      DAE.Exp ne;
    case (exp1,exp2,negate) 
      equation
        true = Expression.isZero(exp2);
      then exp1;
    case (exp1,exp2,negate) 
      equation
        true = Expression.isZero(exp1);
        ne = negateif(negate,exp2);
      then ne;      
    case (exp1,exp2,negate) 
      equation
        ne = negateif(negate,exp2);
        true = Expression.expEqual(exp1,ne);
      then ne;            
  end matchcontinue;
end getNonZeroStart;

protected function negateif
"autor: Frenkel TUD 2011-04"
  input Boolean negate;
  input DAE.Exp exp;
  output DAE.Exp outExp;
algorithm
  outExp :=
  match (negate,exp)
    local
      DAE.Exp ne;
    case (true,exp) 
      equation
        ne = Expression.negate(exp);
      then ne;
    else exp;
  end match;
end negateif;

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
      DAE.Exp e,e_1,e1,esum,eaverage;
    case (v,var,negate)
      equation 
        // nominal
        e = BackendVariable.varNominalValue(v);
        e1 = BackendVariable.varNominalValue(var);
        e_1 = negateif(negate,e);
        esum = Expression.makeSum({e_1,e1});
        eaverage = Expression.expDiv(esum,DAE.RCONST(2.0)); // Real is legal because only Reals have nominal attribute
        (eaverage,_) = ExpressionSimplify.simplify(eaverage); 
        var1 = BackendVariable.setVarNominalValue(var,eaverage);
      then var1;
    case (v,var,negate)
      equation 
        // nominal
        e = BackendVariable.varNominalValue(v);
        e_1 = negateif(negate,e);
        var1 = BackendVariable.setVarNominalValue(var,e_1);
      then var1;
    case(_,inVar,_) then inVar;
  end matchcontinue;
end mergeNomnialAttribute;

protected function mergeMinMaxAttribute
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
      list<Option<DAE.Exp>> ominmax,ominmax1;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      DAE.ComponentRef cr,cr1;
    case (v as BackendDAE.VAR(values = attr),var as BackendDAE.VAR(values = attr1),negate)
      equation 
        // minmax
        ominmax = DAEUtil.getMinMax(attr);
        ominmax1 = DAEUtil.getMinMax(attr1);
        cr = BackendVariable.varCref(v);
        cr1 = BackendVariable.varCref(var);
        minMax = mergeMinMax(negate,ominmax,ominmax1,cr,cr1);
        var1 = BackendVariable.setVarMinMax(var,minMax);
      then var1;
    case(_,inVar,_) then inVar;
  end matchcontinue;
end mergeMinMaxAttribute;

protected function mergeMinMax
  input Boolean negate;
  input list<Option<DAE.Exp>> ominmax;
  input list<Option<DAE.Exp>> ominmax1;
  input DAE.ComponentRef cr;
  input DAE.ComponentRef cr1;
  output tuple<Option<DAE.Exp>, Option<DAE.Exp>> outMinMax;
algorithm
  outMinMax :=
  match (negate,ominmax,ominmax1,cr,cr1)
    local
      Option<DAE.Exp> omin1,omax1,omin2,omax2;
      DAE.Exp min,max,min1,max1;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
    case (false,{omin1,omax1},{omin2,omax2},cr,cr1)
      equation
        minMax = mergeMinMax1({omin1,omax1},{omin2,omax2});
        checkMinMax(minMax,cr,cr1,negate);
      then
        minMax;
    // in case of a=-b, min and max have to be changed and negated
    case (true,{SOME(min),SOME(max)},{omin2,omax2},cr,cr1)
      equation
        min1 = Expression.negate(min);
        max1 = Expression.negate(max);
        minMax = mergeMinMax1({SOME(max1),SOME(min1)},{omin2,omax2});
        checkMinMax(minMax,cr,cr1,negate);
      then
        minMax;        
    case (true,{NONE(),SOME(max)},{omin2,omax2},cr,cr1)
      equation
        max1 = Expression.negate(max);
        minMax = mergeMinMax1({SOME(max1),NONE()},{omin2,omax2});
        checkMinMax(minMax,cr,cr1,negate);
      then
        minMax;        
    case (true,{SOME(min),NONE()},{omin2,omax2},cr,cr1)
      equation
        min1 = Expression.negate(min);
        minMax = mergeMinMax1({NONE(),SOME(min1)},{omin2,omax2});
        checkMinMax(minMax,cr,cr1,negate);
      then
        minMax;        
  end match;
end mergeMinMax;

protected function checkMinMax
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>> minmax;
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Boolean negate;
algorithm
  _ :=
  matchcontinue (minmax,cr1,cr2,negate)
    local
      DAE.Exp min,max;
      String s,s1,s2,s3,s4,s5;
      Real rmin,rmax;
    case ((SOME(min),SOME(max)),cr1,cr2,negate)
      equation
        rmin = Expression.expReal(min);
        rmax = Expression.expReal(max);
        true = realGt(rmin,rmax);
        s1 = ComponentReference.printComponentRefStr(cr1);
        s2 = Util.if_(negate," = -"," = ");
        s3 = ComponentReference.printComponentRefStr(cr2);
        s4 = ExpressionDump.printExpStr(min);
        s5 = ExpressionDump.printExpStr(max);
        s = stringAppendList({"Alias variables ",s1,s2,s3," with invalid limits min ",s4," > max ",s5});
        Error.addMessage(Error.COMPILER_WARNING,{s});        
      then ();
    // no error
    else
      ();
  end matchcontinue;
end checkMinMax;

protected function mergeMinMax1
  input list<Option<DAE.Exp>> ominmax;
  input list<Option<DAE.Exp>> ominmax1;
  output tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
algorithm
  minMax :=
  match (ominmax,ominmax1)
    local
      DAE.Exp min,max,min1,max1,min_2,max_2,smin,smax;
    // (min,max),()
    case ({SOME(min),SOME(max)},{})
      then ((SOME(min),SOME(max)));
    case ({SOME(min),SOME(max)},{NONE(),NONE()})
      then ((SOME(min),SOME(max)));
    // (min,),()
    case ({SOME(min),NONE()},{})
      then ((SOME(min),NONE()));
    case ({SOME(min),NONE()},{NONE(),NONE()})
      then ((SOME(min),NONE()));
    // (,max),()
    case ({NONE(),SOME(max)},{})
      then ((NONE(),SOME(max)));
    case ({NONE(),SOME(max)},{NONE(),NONE()})
      then ((NONE(),SOME(max)));
    // (min,),(min,)
    case ({SOME(min),NONE()},{SOME(min1),NONE()})
      equation
        min_2 = Expression.expMaxScalar(min,min1);
        (smin,_) = ExpressionSimplify.simplify(min_2);
      then ((SOME(smin),NONE()));
    // (,max),(,max)
    case ({NONE(),SOME(max)},{NONE(),SOME(max1)})
      equation
        max_2 = Expression.expMinScalar(max,max1);
        (smax,_) = ExpressionSimplify.simplify(max_2);
      then ((NONE(),SOME(smax)));
    // (min,),(,max)
    case ({SOME(min),NONE()},{NONE(),SOME(max1)})
      then ((SOME(min),SOME(max1))); 
    // (,max),(min,)
    case ({NONE(),SOME(max)},{SOME(min1),NONE()})
      then ((SOME(min1),SOME(max)));               
    // (,max),(min,max)
    case ({NONE(),SOME(max)},{SOME(min1),SOME(max1)})
      equation
        max_2 = Expression.expMinScalar(max,max1);
        (smax,_) = ExpressionSimplify.simplify(max_2);
      then ((SOME(min1),SOME(smax)));
    // (min,max),(,max)
    case ({SOME(min),SOME(max)},{NONE(),SOME(max1)})
      equation
        max_2 = Expression.expMinScalar(max,max1);
        (smax,_) = ExpressionSimplify.simplify(max_2);
      then ((SOME(min),SOME(smax)));
    // (min,),(min,max)
    case ({SOME(min),NONE()},{SOME(min1),SOME(max1)})
      equation
        min_2 = Expression.expMaxScalar(min,min1);
        (smin,_) = ExpressionSimplify.simplify(min_2);
      then ((SOME(smin),SOME(max1)));
    // (min,max),(min,)
    case ({SOME(min),SOME(max)},{SOME(min1),NONE()})
      equation
        min_2 = Expression.expMaxScalar(min,min1);
        (smin,_) = ExpressionSimplify.simplify(min_2);
      then ((SOME(smin),SOME(max)));
    // (min,max),(min,max)
    case ({SOME(min),SOME(max)},{SOME(min1),SOME(max1)})
      equation
        min_2 = Expression.expMaxScalar(min,min1);
        max_2 = Expression.expMinScalar(max,max1);
        (smin,_) = ExpressionSimplify.simplify(min_2);
        (smax,_) = ExpressionSimplify.simplify(max_2);
      then ((SOME(smin),SOME(smax)));
  end match;
end mergeMinMax1;

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
    output tuple<list<Integer>,BackendDAE.IncidenceMatrix,Type_a> outTpl;
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
    output tuple<list<Integer>,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;
algorithm
  (outM,outTypeA) := traverseIncidenceMatrix2(inM,func,pos,len,intGt(pos,len),inTypeA);
end traverseIncidenceMatrix1;

protected function traverseIncidenceMatrix2 
" function: traverseIncidenceMatrix1
  autor: Frenkel TUD 2010-12"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.IncidenceMatrix inM;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  input Boolean stop;
  input Type_a inTypeA;
  output BackendDAE.IncidenceMatrix outM;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix,Type_a> inTpl;
    output tuple<list<Integer>,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  (outM,outTypeA) := match (inM,func,pos,len,stop,inTypeA)
    local 
      BackendDAE.IncidenceMatrix m,m1,m2;
      Type_a extArg,extArg1,extArg2;
      list<Integer> eqns,eqns1;
    
    case(inM,func,pos,len,true,inTypeA)
    then (inM,inTypeA);
    
    case(inM,func,pos,len,false,inTypeA)
      equation
        ((eqns,m,extArg)) = func((inM[pos],pos,inM,inTypeA));
        eqns1 = List.removeOnTrue(pos,intLt,eqns);
        (m1,extArg1) = traverseIncidenceMatrixList(eqns1,m,func,arrayLength(m),pos,extArg);
        (m2,extArg2) = traverseIncidenceMatrix1(m1,func,pos+1,len,extArg1);
      then (m2,extArg2);
      
  end match;
end traverseIncidenceMatrix2;

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
      eqns1 = List.removeOnTrue(maxpos,intLt,eqns);
      alleqns = List.unionOnTrueList({rest, eqns1},intEq);
      (m1,extArg1) = traverseIncidenceMatrixList(alleqns,m,func,len,maxpos,extArg);
    then (m1,extArg1);

    case(pos::rest,inM,func,len,maxpos,inTypeA) equation
      // do not leave the list
      true = intLt(pos,len+1);
      (m,extArg) = traverseIncidenceMatrixList(rest,inM,func,len,maxpos,inTypeA);
    then (m,extArg);
      
    case (_,_,_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- BackendDAEOptimize.traverseIncidenceMatrixList failed");
      then
        fail();      
  end matchcontinue;
end traverseIncidenceMatrixList;

public function traversingTimeEqnsFinder "
Author: Frenkel 2010-12"
  input tuple<DAE.Exp, tuple<Boolean,BackendDAE.Variables,BackendDAE.Variables,Boolean> > inExp;
  output tuple<DAE.Exp, Boolean, tuple<Boolean,BackendDAE.Variables,BackendDAE.Variables,Boolean> > outExp;
algorithm 
  outExp := matchcontinue(inExp)
    local
      DAE.Exp e;
      Boolean b,b1;
      BackendDAE.Variables vars,knvars;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
    
    case((e as DAE.CREF(DAE.CREF_IDENT(ident = "time",subscriptLst = {}),_), (_,vars,knvars,b1)))
      then ((e,false,(true,vars,knvars,b1)));       
    case((e as DAE.CREF(cr,_), (_,vars,knvars,b1)))
      equation
        (var::_,_::_)= BackendVariable.getVar(cr, knvars) "input variables stored in known variables are input on top level" ;
        true = BackendVariable.isVarOnTopLevelAndInput(var);
      then ((e,false,(true,vars,knvars,b1)));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst = {_,_}), (_,vars,knvars,b1))) then ((e,false,(true,vars,knvars,b1) ));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "pre"), expLst = {_}), (_,vars,knvars,b1))) then ((e,false,(true,vars,knvars,b1) ));
    // case for finding simple equation in jacobians 
    // there are all known variables mark as input
    // and they are all time-depending  
    case((e as DAE.CREF(cr,_), (_,vars,knvars,true)))
      equation
        (var::_,_::_)= BackendVariable.getVar(cr, knvars) "input variables stored in known variables are input on top level" ;
        DAE.INPUT() = BackendVariable.getVarDirection(var);
      then ((e,false,(true,vars,knvars,true)));   
    case((e,(b,vars,knvars,b1))) then ((e,not b,(b,vars,knvars,b1)));
    
  end matchcontinue;
end traversingTimeEqnsFinder;

protected function setbindValue
" function: setbindValue
  autor: Frenkel TUD 2010-12"
  input DAE.Exp inExp;
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
  output Boolean constExp;
algorithm
  (outVar,constExp) := matchcontinue(inExp,inVar)
    local 
     Values.Value value;
     BackendDAE.Var var;
    case(inExp,inVar)
      equation
        true = Expression.isConst(inExp);
        value = ValuesUtil.expValue(inExp);
        var = BackendVariable.setBindValue(inVar,value);
        var = BackendVariable.setVarStartValue(var,inExp);
      then (var,true);
    case(_,inVar) then (inVar,false);        
  end matchcontinue;
end setbindValue;


public function countSimpleEquations
"function: countSimpleEquations
  autor: Frenkel TUD 2011-05
  This function count the simple equations on the form a=b and a=const and a=f(not time)
  in BackendDAE.BackendDAE. Note this functions does not use variable replacements, because
  of this the number of simple equations is maybe smaller than using variable replacements."
  input BackendDAE.BackendDAE inDlow;
  input BackendDAE.IncidenceMatrix inM;
  output Integer outSimpleEqns;
algorithm
  outSimpleEqns:=
  match (inDlow,inM)
    local
      BackendDAE.BackendDAE dlow;
      BackendDAE.EquationArray eqns;
      Integer n;
    case (dlow,inM)
      equation
        // check equations
       (_,(_,n)) = traverseIncidenceMatrix(inM,countSimpleEquationsFinder,(dlow,0));
      then n;
  end match;
end countSimpleEquations;

protected function countSimpleEquationsFinder
"autor: Frenkel TUD 2011-05"
 input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix, tuple<BackendDAE.BackendDAE,Integer>> inTpl;
 output tuple<list<Integer>,BackendDAE.IncidenceMatrix, tuple<BackendDAE.BackendDAE,Integer>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.IncidenceMatrixElement elem;
      Integer pos,l,i,n,n_1;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.BackendDAE dae;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case ((elem,pos,m,(dae as BackendDAE.DAE({syst},shared),n)))
      equation
        // check number of vars in eqns
        l = listLength(elem);
        true = intLt(l,3);
        true = intGt(l,0);
        countsimpleEquation(elem,l,pos,syst,shared);
        n_1 = n+1;
      then (({},m,(dae,n_1)));
    case ((elem,pos,m,(dae,n)))
      then (({},m,(dae,n))); 
  end matchcontinue;
end countSimpleEquationsFinder;

protected function countsimpleEquation 
" function: countsimpleEquation
  autor: Frenkel TUD 2011-05"
  input BackendDAE.IncidenceMatrixElement elem;
  input Integer length;
  input Integer pos;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
algorithm
  _ := matchcontinue(elem,length,pos,syst,shared)
    local 
      DAE.ComponentRef cr,cr2;
      Integer i,j,pos_1,k,eqTy;
      DAE.Exp es,cre,e1,e2;
      BackendDAE.BinTree newvars,newvars1;
      BackendDAE.Variables vars,knvars;
      BackendDAE.Var var,var2,var3;
      BackendDAE.BackendDAE dae1;
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn;
      Boolean negate;
      DAE.ElementSource source;
    // a = const
    // wbraun:
    // speacial case for Jacobains, since there are all known variablen
    // time depending input variables    
    case ({i},length,pos,syst,shared as BackendDAE.SHARED(backendDAEType = BackendDAE.JACOBIAN()))
      equation 
        vars = BackendVariable.daeVars(syst);
        var = BackendVariable.getVarAt(vars,intAbs(i));
        // no State
        false = BackendVariable.isStateorStateDerVar(var);
        // try to solve the equation
        pos_1 = pos-1;
        eqns = BackendEquation.daeEqns(syst);
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        BackendDAE.EQUATION(exp=e1,scalar=e2,source=source) = eqn;
        // variable time not there
        knvars = BackendVariable.daeKnVars(shared);
        ((_,(false,_,_,_))) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,knvars,true));
        ((_,(false,_,_,_))) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,knvars,true));
        cr = BackendVariable.varCref(var);
        cre = Expression.crefExp(cr);
        (_,{}) = ExpressionSolve.solve(e1,e2,cre);
      then ();              
    // a = const
    case ({i},length,pos,syst,shared)
      equation 
        vars = BackendVariable.daeVars(syst);
        var = BackendVariable.getVarAt(vars,intAbs(i));
        // no State
        false = BackendVariable.isStateorStateDerVar(var);
        // try to solve the equation
        pos_1 = pos-1;
        eqns = BackendEquation.daeEqns(syst);
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        BackendDAE.EQUATION(exp=e1,scalar=e2,source=source) = eqn;
        // variable time not there
        knvars = BackendVariable.daeKnVars(shared);
        ((_,(false,_,_,_))) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,knvars,false));
        ((_,(false,_,_,_))) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,knvars,false));
        cr = BackendVariable.varCref(var);
        cre = Expression.crefExp(cr);
        (_,{}) = ExpressionSolve.solve(e1,e2,cre);
      then ();
    // a = der(b) 
    case ({i,j},length,pos,syst,shared)
      equation
        pos_1 = pos-1;
        eqns = BackendEquation.daeEqns(syst);
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        (cr,_,_,_,_) = BackendEquation.derivativeEquation(eqn);
        // select candidate
        vars = BackendVariable.daeVars(syst);
        ((_::_),(_::_)) = BackendVariable.getVar(cr,vars);
      then ();
    // a = b 
    case ({i,j},length,pos,syst,shared)
      equation
        pos_1 = pos-1;
        eqns = BackendEquation.daeEqns(syst);
        (eqn as BackendDAE.EQUATION(source=source)) = BackendDAEUtil.equationNth(eqns,pos_1);
        (_,_,_,_,_) = BackendEquation.aliasEquation(eqn);
      then ();
  end matchcontinue;
end countsimpleEquation;

/*  
 * remove final paramters stuff 
 */ 

public function removeFinalParameters
"function: removeFinalParameters
  autor Frenkel TUD"
  input BackendDAE.BackendDAE dae;
  input DAE.FunctionTree funcs;
  output BackendDAE.BackendDAE odae;
algorithm
  odae := BackendDAEUtil.mapEqSystem1(dae,removeFinalParametersWork,funcs);
end removeFinalParameters;

protected function removeFinalParametersWork
"function: removeFinalParameters
  autor Frenkel TUD"
  input BackendDAE.EqSystem syst;
  input DAE.FunctionTree funcs;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared) := match (syst,funcs,shared)
    local
      DAE.FunctionTree funcs;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Variables vars,knvars,exobj,knvars1;
      BackendDAE.AliasVariables av,varsAliases;
      BackendDAE.EquationArray eqns,eqns1,remeqns,remeqns1,inieqns,inieqns1;
      array<BackendDAE.MultiDimEquation> arreqns,arreqns1;
      array<DAE.Algorithm> algorithms,algorithms1;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendVarTransform.VariableReplacements repl,repl1,repl2;
      list<BackendDAE.Equation> eqns_1,seqns,lsteqns,reqns,ieqns;
      list<BackendDAE.MultiDimEquation> lstarreqns,lstarreqns1;
      list<DAE.Algorithm> algs,algs_1;
      BackendDAE.BackendDAEType btp;
      BackendDAE.Matching matching;
    case (BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching),funcs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,arreqns,algorithms,einfo,eoc,btp))
      equation
        repl = BackendVarTransform.emptyReplacements();
        lsteqns = BackendDAEUtil.equationList(eqns);
        lstarreqns = arrayList(arreqns);
        algs = arrayList(algorithms);
        ((repl1,_)) = BackendVariable.traverseBackendDAEVars(knvars,removeFinalParametersFinder,(repl,knvars));
        (knvars1,repl2) = replaceFinalVars(1,knvars,repl1);
        Debug.fcall("dumpFPrepl", BackendVarTransform.dumpReplacements, repl2);
        eqns_1 = BackendVarTransform.replaceEquations(lsteqns, repl2);
        lstarreqns1 = BackendVarTransform.replaceMultiDimEquations(lstarreqns, repl2);
        (algs_1,_) = BackendVarTransform.replaceAlgorithms(algs,repl2);
        eqns1 = BackendDAEUtil.listEquation(eqns_1);
        arreqns1 = listArray(lstarreqns1);
        algorithms1 = listArray(algs_1);
      then
        (BackendDAE.EQSYSTEM(vars,eqns1,NONE(),NONE(),matching),BackendDAE.SHARED(knvars1,exobj,av,inieqns,remeqns,arreqns1,algorithms1,einfo,eoc,btp));
  end match;
end removeFinalParametersWork;

protected function removeFinalParametersFinder
"autor: Frenkel TUD 2011-03"
 input tuple<BackendDAE.Var, tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Variables vars;
      BackendDAE.Var v;
      BackendVarTransform.VariableReplacements repl,repl_1;
      DAE.ComponentRef varName;
      Option< .DAE.VariableAttributes> values;
      DAE.Exp exp,exp1;
      Values.Value bindValue;
    case ((v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindExp=SOME(exp),values=values),(repl,vars)))
      equation
        true = BackendVariable.isFinalVar(v);
        ((exp1, _)) = Expression.traverseExp(exp, BackendDAEUtil.replaceCrefsWithValues, vars);
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp1);
      then ((v,(repl_1,vars)));
    case ((v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindValue=SOME(bindValue),values=values),(repl,vars)))
      equation
        true = BackendVariable.isFinalVar(v);
        exp = ValuesUtil.valueExp(bindValue);
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp);
      then ((v,(repl_1,vars)));
    case inTpl then inTpl;
  end matchcontinue;
end removeFinalParametersFinder;

protected function replaceFinalVars
" function: replaceFinalVars
  autor: Frenkel TUD 2011-04"
  input Integer inNumRepl;
  input BackendDAE.Variables inVars;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendDAE.Variables outVars;
  output BackendVarTransform.VariableReplacements outRepl;
algorithm
  (outVars,outRepl) := matchcontinue(inNumRepl,inVars,inRepl)
    local 
      Integer numrepl;
      BackendDAE.Variables knvars,knvars1,knvars2;
      BackendVarTransform.VariableReplacements repl,repl1,repl2;
    
    case(numrepl,knvars,repl)
      equation
      true = intEq(0,numrepl);
    then (knvars,repl);
    
    case(numrepl,knvars,repl)
      equation
      (knvars1,(repl1,numrepl)) = BackendVariable.traverseBackendDAEVarsWithUpdate(knvars,replaceFinalVarTraverser,(repl,0));
      (knvars2,repl2) = replaceFinalVars(numrepl,knvars1,repl1);
    then (knvars2,repl2);
  end matchcontinue;
end replaceFinalVars;

protected function replaceFinalVarTraverser
"autor: Frenkel TUD 2011-04"
 input tuple<BackendDAE.Var, tuple<BackendVarTransform.VariableReplacements,Integer>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendVarTransform.VariableReplacements,Integer>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v,v1;
      BackendVarTransform.VariableReplacements repl,repl_1;
      Integer numrepl;
      DAE.Exp e,e1;
      DAE.ComponentRef cr;
    case ((v as BackendDAE.VAR(varName=cr,bindExp=SOME(e)),(repl,numrepl)))
      equation
        (e1,true) = BackendVarTransform.replaceExp(e, repl, NONE());
        v1 = BackendVariable.setBindExp(v,e1);
        true = Expression.isConst(e1);
        repl_1 = BackendVarTransform.addReplacement(repl, cr, e1);
      then ((v1,(repl_1,numrepl+1)));
    case ((v as BackendDAE.VAR(bindExp=SOME(e)),(repl,numrepl)))
      equation
        (e1,true) = BackendVarTransform.replaceExp(e, repl, NONE());
        v1 = BackendVariable.setBindExp(v,e1);
      then ((v1,(repl,numrepl)));
    case inTpl then inTpl;
  end matchcontinue;
end replaceFinalVarTraverser;


public function removeParameters
"function: removeFinalParameters
  autor wbraun"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match (inDAE,inFunctionTree)
    local
      DAE.FunctionTree funcs;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Variables vars,knvars,exobj,knvars1;
      BackendDAE.AliasVariables av,varsAliases;
      BackendDAE.EquationArray eqns,eqns1,remeqns,remeqns1,inieqns,inieqns1;
      array<BackendDAE.MultiDimEquation> arreqns,arreqns1;
      array<DAE.Algorithm> algorithms,algorithms1;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendVarTransform.VariableReplacements repl,repl1,repl2;
      list<BackendDAE.Equation> eqns_1,seqns,lsteqns,reqns,ieqns;
      list<BackendDAE.MultiDimEquation> lstarreqns,lstarreqns1;
      list<DAE.Algorithm> algs,algs_1;
      BackendDAE.BackendDAEType btp;
      BackendDAE.Matching matching;
    case (BackendDAE.DAE(BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching)::{},BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,arreqns,algorithms,einfo,eoc,btp)),funcs)
      equation      
        repl = BackendVarTransform.emptyReplacements();
        lsteqns = BackendDAEUtil.equationList(eqns);
        lstarreqns = arrayList(arreqns);
        algs = arrayList(algorithms);
        ((repl1,_)) = BackendVariable.traverseBackendDAEVars(knvars,removeParametersFinder,(repl,knvars));
        (knvars1,repl2) = replaceFinalVars(1,knvars,repl1);
        Debug.fcall("dumpParamrepl", BackendVarTransform.dumpReplacements, repl2);
        eqns_1 = BackendVarTransform.replaceEquations(lsteqns, repl2);
        lstarreqns1 = BackendVarTransform.replaceMultiDimEquations(lstarreqns, repl2);
        (algs_1,_) = BackendVarTransform.replaceAlgorithms(algs,repl2);
        eqns1 = BackendDAEUtil.listEquation(eqns_1);
        arreqns1 = listArray(lstarreqns1);
        algorithms1 = listArray(algs_1);
      then
        (BackendDAE.DAE(BackendDAE.EQSYSTEM(vars,eqns1,NONE(),NONE(),matching)::{},BackendDAE.SHARED(knvars1,exobj,av,inieqns,remeqns,arreqns1,algorithms1,einfo,eoc,btp)));
  end match;
end removeParameters;

protected function removeParametersFinder
"autor: Frenkel TUD 2011-03"
 input tuple<BackendDAE.Var, tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Variables vars;
      BackendDAE.Var v;
      BackendVarTransform.VariableReplacements repl,repl_1;
      DAE.ComponentRef varName;
      Option< .DAE.VariableAttributes> values;
      DAE.Exp exp,exp1;
      Values.Value bindValue;
    case ((v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindExp=SOME(exp),values=values),(repl,vars)))
      equation
        ((exp1, _)) = Expression.traverseExp(exp, BackendDAEUtil.replaceCrefsWithValues, vars);
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp1);
      then ((v,(repl_1,vars)));
    case ((v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindValue=SOME(bindValue),values=values),(repl,vars)))
      equation
        exp = ValuesUtil.valueExp(bindValue);
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp);
      then ((v,(repl_1,vars)));
    case inTpl then inTpl;
  end matchcontinue;
end removeParametersFinder;


/*  
 * remove protected parameters stuff 
 */ 

public function removeProtectedParameters
"function: removeProtectedParameters
  autor Frenkel TUD"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match (inDAE,inFunctionTree)
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
      BackendVarTransform.VariableReplacements repl,repl1;
      list<BackendDAE.Equation> eqns_1,seqns,lsteqns,reqns,ieqns;
      list<BackendDAE.MultiDimEquation> lstarreqns,lstarreqns1;
      list<DAE.Algorithm> algs,algs_1;
      BackendDAE.BackendDAEType btp;
      BackendDAE.Matching matching;
    case (BackendDAE.DAE(BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching)::{},BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,arreqns,algorithms,einfo,eoc,btp)),funcs)
      equation      
        repl = BackendVarTransform.emptyReplacements();
        lsteqns = BackendDAEUtil.equationList(eqns);
        lstarreqns = arrayList(arreqns);
        algs = arrayList(algorithms);
        repl1 = BackendVariable.traverseBackendDAEVars(knvars,protectedParametersFinder,repl);
        Debug.fcall("dumpPPrepl", BackendVarTransform.dumpReplacements, repl1);
        eqns_1 = BackendVarTransform.replaceEquations(lsteqns, repl1);
        lstarreqns1 = BackendVarTransform.replaceMultiDimEquations(lstarreqns, repl1);
        (algs_1,_) = BackendVarTransform.replaceAlgorithms(algs,repl1);
        eqns1 = BackendDAEUtil.listEquation(eqns_1);
        arreqns1 = listArray(lstarreqns1);
        algorithms1 = listArray(algs_1);
      then
        (BackendDAE.DAE(BackendDAE.EQSYSTEM(vars,eqns1,NONE(),NONE(),matching)::{},BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,arreqns1,algorithms1,einfo,eoc,btp)));
  end match;
end removeProtectedParameters;

protected function protectedParametersFinder
"autor: Frenkel TUD 2011-03"
 input tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> inTpl;
 output tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      BackendVarTransform.VariableReplacements repl,repl_1;
      DAE.ComponentRef varName;
      Option< .DAE.VariableAttributes> values;
      DAE.Exp exp;
      Values.Value bindValue;
    case ((v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindExp=SOME(exp),values=values),repl))
      equation
        true = DAEUtil.getProtectedAttr(values);
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp);
      then ((v,repl_1));
    case ((v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindValue=SOME(bindValue),values=values),repl))
      equation
        true = DAEUtil.getProtectedAttr(values);
        true = BackendVariable.varFixed(v);
        exp = ValuesUtil.valueExp(bindValue);
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp);
      then ((v,repl_1));
    case inTpl then inTpl;
  end matchcontinue;
end protectedParametersFinder;

/* 
 * remove equal function calls equations stuff
 */

public function removeEqualFunctionCallsPast
"function removeEqualFunctionCallsPast"
    input BackendDAE.BackendDAE inDAE;
    input DAE.FunctionTree inFunctionTree;
    output BackendDAE.BackendDAE outDAE;
    output Boolean outRunMatching;
protected
  Option<BackendDAE.IncidenceMatrix> om,omT;
  Boolean b;
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE({syst},shared) := inDAE;
  (syst,shared,b) := removeEqualFunctionCalls1(syst,shared,inFunctionTree);
  (syst,_,_) := BackendDAEUtil.getIncidenceMatrixfromOption(syst,shared);
  outRunMatching := b; // until does not update assignments and comps  
  outDAE := BackendDAE.DAE({syst},shared);
end removeEqualFunctionCallsPast;

public function removeEqualFunctionCalls
"function: removeEqualFunctionCalls
  autor: Frenkel TUD 2011-04
  This function detect equal function call on the form a=f(b) and c=f(b) 
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.BackendDAE dae;
  input DAE.FunctionTree funcs;
  output BackendDAE.BackendDAE odae;
algorithm
  odae := BackendDAEUtil.mapEqSystem1(dae,removeEqualFunctionCallsWork,funcs);
end removeEqualFunctionCalls;

protected function removeEqualFunctionCallsWork
"function: removeEqualFunctionCalls
  autor: Frenkel TUD 2011-04
  This function detect equal function call on the form a=f(b) and c=f(b) 
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.EqSystem syst;
  input DAE.FunctionTree funcs;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared,_) := removeEqualFunctionCalls1(syst,shared,funcs);
end removeEqualFunctionCallsWork;

protected function removeEqualFunctionCalls1
"function: removeEqualFunctionCalls
  autor: Frenkel TUD 2011-04
  This function detect equal function call on the form a=f(b) and c=f(b) 
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Boolean optimized;
algorithm
  (osyst,oshared,optimized) := match (syst,shared,inFunctionTree)
    local
      BackendDAE.BackendDAE dae,dae1;
      DAE.FunctionTree funcs;
      BackendDAE.IncidenceMatrix m,m_1,m_2;
      BackendDAE.IncidenceMatrixT mT,mT_1,mT_2;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1,ineq;
      array<BackendDAE.MultiDimEquation> arreqns,arreqns1;
      array<DAE.Algorithm> algorithms,algorithms1;
      BackendDAE.EventInfo einfo,einfo1;
      list<Integer> changed;
      Boolean b;
    case (syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared as BackendDAE.SHARED(arrayEqs=arreqns,algorithms=algorithms,eventInfo=einfo),funcs)
      equation
        (syst,m,mT) = BackendDAEUtil.getIncidenceMatrixfromOption(syst,shared);
        // check equations
        (m_1,(mT_1,_,eqns1,arreqns1,algorithms1,einfo1,changed)) = traverseIncidenceMatrix(m,removeEqualFunctionCallFinder,(mT,vars,eqns,arreqns,algorithms,einfo,{}));
        b = intGt(listLength(changed),0);
        // update arrayeqns and algorithms, collect info for wrappers
        syst = BackendDAE.EQSYSTEM(vars,eqns,SOME(m_1),SOME(mT_1),BackendDAE.NO_MATCHING());
        (syst,shared) = removeEqualFunctionCalls2(b,syst,shared,eqns1,arreqns1,algorithms1,einfo1);
        syst = BackendDAEUtil.updateIncidenceMatrix(syst,shared,changed);
      then (syst,shared,b);
  end match;
end removeEqualFunctionCalls1;

protected function removeEqualFunctionCalls2
"function: removeEqualFunctionCalls2
  autor: Frenkel TUD 2011-05"
  input Boolean b;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input BackendDAE.EquationArray eqns;
  input array<BackendDAE.MultiDimEquation> arreqns;
  input array<DAE.Algorithm> algorithms;
  input BackendDAE.EventInfo einfo;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared) := match (b,syst,shared,eqns,arreqns,algorithms,einfo)
    local
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.Variables vars,knvars,exobj;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray remeqns,inieqns,eqns1;
      array<BackendDAE.MultiDimEquation> arreqns1;
      array<DAE.Algorithm> algorithms1;
      BackendDAE.EventInfo einfo1;
      BackendDAE.ExternalObjectClasses eoc;
      list<list<DAE.Exp>> crefOrDerCreflst;
      array<list<DAE.Exp>> crefOrDerCrefarray;
      list<tuple<list<DAE.Exp>,list<DAE.Exp>>> inouttpllst;
      array<tuple<list<DAE.Exp>,list<DAE.Exp>>> inouttplarray;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.BackendDAEType btp;
    case (false,syst,shared,_,_,_,_) then (syst,shared);
    case (true,BackendDAE.EQSYSTEM(vars,_,m,mT,_),BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,_,_,_,eoc,btp),eqns,arreqns,algorithms,einfo)
      equation
        repl = BackendVarTransform.emptyReplacements();
        // update arrayeqns and algorithms, collect info for wrappers
        (_,(_,_,crefOrDerCreflst)) = Util.arrayMapNoCopy_1(arreqns,replaceArrayEquationTraverser,(repl,vars,{}));
        crefOrDerCrefarray = listArray(listReverse(crefOrDerCreflst));
        (_,(_,_,inouttpllst)) = Util.arrayMapNoCopy_1(algorithms,replaceAlgorithmTraverser,(repl,vars,{}));
        inouttplarray = listArray(listReverse(inouttpllst));
        (eqns1,(_,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(eqns,replaceEquationTraverser,(repl,crefOrDerCrefarray,inouttplarray));
      then (BackendDAE.EQSYSTEM(vars,eqns1,m,mT,BackendDAE.NO_MATCHING()),BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,arreqns,algorithms,einfo,eoc,btp));
  end match;
end removeEqualFunctionCalls2;

protected function removeEqualFunctionCallFinder
"autor: Frenkel TUD 2010-12"
 input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix, tuple<BackendDAE.IncidenceMatrixT,BackendDAE.Variables,BackendDAE.EquationArray,array<BackendDAE.MultiDimEquation>,array<DAE.Algorithm>,BackendDAE.EventInfo,list<Integer>>> inTpl;
 output tuple<list<Integer>,BackendDAE.IncidenceMatrix, tuple<BackendDAE.IncidenceMatrixT,BackendDAE.Variables,BackendDAE.EquationArray,array<BackendDAE.MultiDimEquation>,array<DAE.Algorithm>,BackendDAE.EventInfo,list<Integer>>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.IncidenceMatrixElement elem;
      Integer pos,l,pos_1;
      BackendDAE.IncidenceMatrix m,mT;
      list<Integer> changed,changed1,changed2;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1;
      array<BackendDAE.MultiDimEquation> arreqns,arreqns1;
      array<DAE.Algorithm> algorithms,algorithms1;
      BackendDAE.EventInfo einfo,einfo1;
      BackendDAE.Var var;
      DAE.ComponentRef cr;
      DAE.Exp exp,e1,e2,ecr;
      list<BackendDAE.Value> expvars,controleqns,expvars1;
      list<list<BackendDAE.Value>> expvarseqns;
      
    case ((elem,pos,m,(mT,vars,eqns,arreqns,algorithms,einfo,changed)))
      equation
        // check number of vars in eqns
        _::_ = elem;
        pos_1 = pos-1;
        BackendDAE.EQUATION(exp=e1,scalar=e2) = BackendDAEUtil.equationNth(eqns,pos_1);
        // BackendDump.debugStrExpStrExpStr(("Test ",e1," = ",e2,"\n"));
        (ecr,exp) = functionCallEqn(e1,e2,vars);
        // TODO: Handle this with alias-equations instead?; at least they don't replace back to the original expression...
        // failure(DAE.CREF(componentRef=_) = exp);
        // failure(DAE.UNARY(operator=DAE.UMINUS(ty=_),exp=DAE.CREF(componentRef=_)) = exp);
        // BackendDump.debugStrExpStrExpStr(("Found ",ecr," = ",exp,"\n"));
        expvars = BackendDAEUtil.incidenceRowExp(exp,vars, {});
        // print("expvars "); BackendDump.debuglst((expvars,intString)); print("\n");
        (expvars1::expvarseqns) = List.map1(expvars,varEqns,(pos,mT));
        // print("expvars1 "); BackendDump.debuglst((expvars1,intString)); print("\n");
        controleqns = getControlEqns(expvars1,expvarseqns);
        // print("controleqns "); BackendDump.debuglst((controleqns,intString)); print("\n");
        (eqns1,arreqns1,algorithms1,einfo1,changed) = removeEqualFunctionCall(controleqns,ecr,exp,eqns,arreqns,algorithms,einfo,changed);
        //print("changed1 "); BackendDump.debuglst((changed1,intString)); print("\n");
        //print("changed2 "); BackendDump.debuglst((changed2,intString)); print("\n");
        // print("Next\n");
      then (({},m,(mT,vars,eqns1,arreqns1,algorithms1,einfo1,changed)));
    case ((elem,pos,m,(mT,vars,eqns,arreqns,algorithms,einfo,changed)))
      then (({},m,(mT,vars,eqns,arreqns,algorithms,einfo,changed))); 
  end matchcontinue;
end removeEqualFunctionCallFinder;

protected function functionCallEqn
"function functionCallEqn
  autor Frenkel TUD 2011-04"
  input DAE.Exp e1;
  input DAE.Exp e2;
  input BackendDAE.Variables inVars;
  output DAE.Exp outECr;
  output DAE.Exp outExp;
algorithm
  (outECr,outExp) := match (e1,e2,inVars)
      local
        DAE.ComponentRef cr;
        DAE.Exp e;
        Integer k;
        DAE.Operator op;
      case (e1 as DAE.CREF(componentRef = cr),DAE.UNARY(operator=op as DAE.UMINUS(ty=_),exp=DAE.CREF(componentRef = _)),inVars)
        then fail();
      case (e1 as DAE.CREF(componentRef = cr),DAE.CREF(componentRef = _),inVars)
        then fail();
      case (DAE.UNARY(operator=op as DAE.UMINUS(ty=_),exp=e1 as DAE.CREF(componentRef = cr)),DAE.CREF(componentRef = _),inVars)
        then fail();
      // a = -f(...);
      case (e1 as DAE.CREF(componentRef = cr),DAE.UNARY(operator=op as DAE.UMINUS(ty=_),exp=e2),inVars)
        equation
          ((_::_),(_::_)) = BackendVariable.getVar(cr,inVars);
        then (DAE.UNARY(op,e1),e2);
      // a = f(...);
      case (e1 as DAE.CREF(componentRef = cr),e2,inVars)
        equation
          ((_::_),(_::_)) = BackendVariable.getVar(cr,inVars);
        then (e1,e2);
      // a = -f(...);
      case (DAE.UNARY(operator=op as DAE.UMINUS(ty=_),exp=e1),e2 as DAE.CREF(componentRef = cr),inVars)
        equation
          ((_::_),(_::_)) = BackendVariable.getVar(cr,inVars);
        then (DAE.UNARY(op,e2),e1);
      // f(...)=a;
      case (e1,e2 as DAE.CREF(componentRef = cr),inVars)
        equation
          ((_::_),(_::_)) = BackendVariable.getVar(cr,inVars);
        then (e2,e1);
  end match;
end functionCallEqn;

protected function varEqns
"function varEqns
  autor Frenkel TUD 2011-04"
  input Integer v;
  input tuple<Integer,BackendDAE.IncidenceMatrixT> inTpl;
  output list<BackendDAE.Value> outVarEqns;
protected
  Integer pos;
  list<BackendDAE.Value> vareqns,vareqns1;
  BackendDAE.IncidenceMatrix mT;
algorithm
  pos := Util.tuple21(inTpl);
  mT := Util.tuple22(inTpl);
  vareqns := mT[intAbs(v)];
  vareqns1 := List.map(vareqns, intAbs);
  outVarEqns := List.removeOnTrue(intAbs(pos),intEq,vareqns1);
end varEqns;

protected function getControlEqns
"function getControlEqns
  autor Frenkel TUD 2011-04"
  input list<BackendDAE.Value> inVarsEqn;
  input list<list<BackendDAE.Value>> inVarsEqns;
  output list<BackendDAE.Value> outEqns;
algorithm
  outEqns := matchcontinue(inVarsEqn,inVarsEqns)
    local  
      list<BackendDAE.Value> a,b,c,d;
      list<list<BackendDAE.Value>> rest;
    case (a,{}) then a;
    case (a,b::rest)
      equation 
       c = List.intersectionOnTrue(a,b,intEq);
       d = getControlEqns(c,rest);
      then d;  
  end matchcontinue;  
end getControlEqns;

protected function removeEqualFunctionCall
"function removeEqualFunctionCall
  author: Frenkel TUD 2011-04"
  input list<Integer> inEqsLst;
  input DAE.Exp inExp;
  input DAE.Exp inECr;
  input BackendDAE.EquationArray inEqns;
  input array<BackendDAE.MultiDimEquation> inArreqns;
  input array<DAE.Algorithm> inAlgs;
  input  BackendDAE.EventInfo inEinfo;
  input list<Integer> changed;
  output BackendDAE.EquationArray outEqns;
  output array<BackendDAE.MultiDimEquation> outArreqns;
  output array<DAE.Algorithm> outAlgs;
  output  BackendDAE.EventInfo outEinfo;
  output list<Integer> outEqsLst;
algorithm
  (outEqns,outArreqns,outAlgs,outEinfo,outEqsLst):=
  matchcontinue (inEqsLst,inExp,inECr,inEqns,inArreqns,inAlgs,inEinfo,changed)
    local
      BackendDAE.EquationArray eqns,eqns1,eqns2;
      array<BackendDAE.MultiDimEquation> ae,ae1,ae2;
      array<DAE.Algorithm> al,al1,al2;
      list<BackendDAE.WhenClause> wclst,wclst1;
      list<BackendDAE.ZeroCrossing> zcl;
      BackendDAE.EventInfo einfo;
      BackendDAE.Equation eqn,eqn1;
      Integer pos,pos_1,i;
      list<Integer> rest,changed;
      BackendDAE.EventInfo eifo;
    case ({},_,_,eqns,inArreqns,inAlgs,inEinfo,changed) then (eqns,inArreqns,inAlgs,inEinfo,changed);
    case (pos::rest,inExp,inECr,eqns,inArreqns,inAlgs,BackendDAE.EVENT_INFO(whenClauseLst=wclst,zeroCrossingLst=zcl),changed)
      equation
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        //BackendDump.dumpEqns({eqn});
        //BackendDump.debugStrExpStrExpStr(("Repalce ",inExp," with ",inECr,"\n"));
        (eqn1,al1,ae1,wclst1,(_,_,i)) = BackendDAETransform.traverseBackendDAEExpsEqnWithSymbolicOperation(eqn, inAlgs, inArreqns, wclst, replaceExp, (inECr,inExp,0));
        //BackendDump.dumpEqns({eqn1});
        //print("i="); print(intString(i)); print("\n");
        true = intGt(i,0);
        eqns1 =  BackendEquation.equationSetnth(eqns,pos_1,eqn1);
        changed = List.consOnTrue(not listMember(pos,changed),pos,changed);
        (eqns2,ae2,al2,einfo,changed) = removeEqualFunctionCall(rest,inExp,inECr,eqns1,ae1,al1,BackendDAE.EVENT_INFO(wclst1,zcl),changed);
      then (eqns2,ae2,al2,einfo,changed);
    case (pos::rest,inExp,inECr,eqns,inArreqns,inAlgs,eifo,changed)
      equation
        (eqns2,ae2,al2,einfo,changed) = removeEqualFunctionCall(rest,inExp,inECr,eqns,inArreqns,inAlgs,eifo,changed);
      then (eqns2,ae2,al2,einfo,changed);
  end matchcontinue;      
end removeEqualFunctionCall;

public function replaceExp
"function: replaceAliasDer
  author: Frenkel TUD"
  input tuple<DAE.Exp,tuple<list<DAE.SymbolicOperation>,tuple<DAE.Exp,DAE.Exp,Integer>>> inTpl;
  output tuple<DAE.Exp,tuple<list<DAE.SymbolicOperation>,tuple<DAE.Exp,DAE.Exp,Integer>>> outTpl;
protected
  DAE.Exp e,e1,se,te;
  Integer i,j;
  list<DAE.SymbolicOperation> ops;
algorithm
  (e,(ops,(se,te,i))) := inTpl;
  // BackendDump.debugStrExpStrExpStr(("Repalce ",se," with ",te,"\n"));
  ((e1,j)) := Expression.replaceExp(e,se,te);
  ops := Util.if_(j>0, DAE.SUBSTITUTION({e1},e)::ops, ops);
  // BackendDump.debugStrExpStrExpStr(("Old ",e," new ",e1,"\n"));
  outTpl := ((e1,(ops,(se,te,i+j))));
end replaceExp;

/* 
 * remove unused parameter
 */

public function removeUnusedParameterPast
"function removeUnusedParameterPast"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
protected
  Option<BackendDAE.IncidenceMatrix> om,omT;
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
algorithm
  (outDAE as BackendDAE.DAE({syst},shared)) := removeUnusedParameter(inDAE,inFunctionTree);
  (syst,_,_) := BackendDAEUtil.getIncidenceMatrixfromOption(syst,shared);
  outRunMatching := false;   
end removeUnusedParameterPast;

public function removeUnusedParameter
"function: removeUnusedParameter
  autor: Frenkel TUD 2011-04
  This function remove unused parameters  
  in BackendDAE.BackendDAE to get speed up for compilation of
  target code"
  input BackendDAE.BackendDAE inDlow;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match (inDlow,inFunctionTree)
    local
      BackendDAE.BackendDAE dae,dae1;
      DAE.FunctionTree funcs;
      BackendDAE.Variables vars,knvars,exobj,avars,knvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      list<BackendDAE.WhenClause> whenClauseLst;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.EqSystems eqs;
      BackendDAE.BackendDAEType btp;      
    case (dae as BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars,exobj,aliasVars as BackendDAE.ALIASVARS(aliasVars=avars),inieqns,remeqns,arreqns,algorithms,einfo as BackendDAE.EVENT_INFO(whenClauseLst=whenClauseLst),eoc,btp)),funcs)
      equation
        knvars1 = BackendDAEUtil.emptyVars();
        ((knvars,knvars1)) = BackendVariable.traverseBackendDAEVars(knvars,copyNonParamVariables,(knvars,knvars1));
        ((_,knvars1)) = List.fold1(eqs,BackendDAEUtil.traverseBackendDAEExpsEqSystem,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsVars(knvars,checkUnusedParameter,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsVars(avars,checkUnusedParameter,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsEqns(remeqns,checkUnusedParameter,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsEqns(inieqns,checkUnusedParameter,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEArrayNoCopy(arreqns,checkUnusedParameter,BackendDAEUtil.traverseBackendDAEExpsArrayEqn,1,arrayLength(arreqns),(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEArrayNoCopy(algorithms,checkUnusedParameter,BackendDAEUtil.traverseAlgorithmExps,1,arrayLength(algorithms),(knvars,knvars1));
        (_,(_,knvars1)) = BackendDAETransform.traverseBackendDAEExpsWhenClauseLst(whenClauseLst,checkUnusedParameter,(knvars,knvars1));
        dae1 = BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,arreqns,algorithms,einfo,eoc,btp));
      then dae;
  end match;
end removeUnusedParameter;

protected function copyNonParamVariables
"autor: Frenkel TUD 2011-05"
 input tuple<BackendDAE.Var, tuple<BackendDAE.Variables,BackendDAE.Variables>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendDAE.Variables,BackendDAE.Variables>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      BackendDAE.Variables vars,vars1;
      DAE.ComponentRef cr,dcr;
    case ((v as BackendDAE.VAR(varName = cr,varKind = BackendDAE.PARAM()),(vars,vars1)))
      then
        ((v,(vars,vars1)));
    case ((v as BackendDAE.VAR(varName = cr),(vars,vars1)))
      equation
        vars1 = BackendVariable.addVar(v,vars1);
      then
        ((v,(vars,vars1)));
  end matchcontinue;
end copyNonParamVariables;

protected function checkUnusedParameter
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> inTpl;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local  
      DAE.Exp exp;
      BackendDAE.Variables vars,vars1;
    case ((exp,(vars,vars1)))
      equation
         ((_,(_,vars1))) = Expression.traverseExp(exp,checkUnusedParameterExp,(vars,vars1));
       then
        ((exp,(vars,vars1)));
    case inTpl then inTpl;
  end matchcontinue;
end checkUnusedParameter;

protected function checkUnusedParameterExp
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> inTuple;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e,e1;
      BackendDAE.Variables vars,vars1;
      DAE.ComponentRef cr;
      list<DAE.Exp> expl;
      list<DAE.ExpVar> varLst;
      DAE.Ident ident;
      list<BackendDAE.Var> backendVars;
      BackendDAE.Var var;
      DAE.ReductionIterators riters;
    
    // special case for time, it is never part of the equation system  
    case ((e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(vars,vars1)))
      then ((e, (vars,vars1)));
    
    // Special Case for Records
    case ((e as DAE.CREF(componentRef = cr,ty= DAE.ET_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),(vars,vars1)))
      equation
        expl = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        ((_,(vars,vars1))) = Expression.traverseExpList(expl,checkUnusedParameterExp,(vars,vars1));
      then
        ((e, (vars,vars1)));

    // Special Case for Arrays
    case ((e as DAE.CREF(ty = DAE.ET_ARRAY(ty=_)),(vars,vars1)))
      equation
        ((e1,(_,true))) = BackendDAEUtil.extendArrExp((e,(NONE(),false)));
        ((_,(vars,vars1))) = Expression.traverseExp(e1,checkUnusedParameterExp,(vars,vars1));
      then
        ((e, (vars,vars1)));
    
    // case for functionpointers    
    case ((e as DAE.CREF(ty=DAE.ET_FUNCTION_REFERENCE_FUNC(builtin=_)),(vars,vars1)))
      then
        ((e, (vars,vars1)));

    // already there
    case ((e as DAE.CREF(componentRef = cr),(vars,vars1)))
      equation
         (_,_) = BackendVariable.getVar(cr, vars1);
      then
        ((e, (vars,vars1)));

    // add it
    case ((e as DAE.CREF(componentRef = cr),(vars,vars1)))
      equation
         (var::_,_) = BackendVariable.getVar(cr, vars);
         vars1 = BackendVariable.addVar(var,vars1);
      then
        ((e, (vars,vars1)));
    
    case inTuple then inTuple;
  end matchcontinue;
end checkUnusedParameterExp;

/* 
 * remove unused variables
 */

public function removeUnusedVariablesPast
"function removeUnusedVariablesPast"
    input BackendDAE.BackendDAE inDAE;
    input DAE.FunctionTree inFunctionTree;
    output BackendDAE.BackendDAE outDAE;
    output Boolean outRunMatching;
protected
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
algorithm
  (outDAE as BackendDAE.DAE({syst},shared)) := removeUnusedVariables(inDAE,inFunctionTree);
  (syst,_,_) := BackendDAEUtil.getIncidenceMatrixfromOption(syst,shared);
  outRunMatching := false;   
end removeUnusedVariablesPast;

public function removeUnusedVariables
"function: removeUnusedVariables
  autor: Frenkel TUD 2011-04
  This function remove unused variables  
  from BackendDAE.BackendDAE to get speed up for compilation of
  target code"
  input BackendDAE.BackendDAE inDlow;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match (inDlow,inFunctionTree)
    local
      BackendDAE.BackendDAE dae,dae1;
      DAE.FunctionTree funcs;
      BackendDAE.Variables vars,knvars,exobj,avars,knvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      list<BackendDAE.WhenClause> whenClauseLst;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.EqSystems eqs;    
      BackendDAE.BackendDAEType btp;
      
    case (dae as BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars,exobj,aliasVars as BackendDAE.ALIASVARS(aliasVars=avars),inieqns,remeqns,arreqns,algorithms,einfo as BackendDAE.EVENT_INFO(whenClauseLst=whenClauseLst),eoc,btp)),funcs)
      equation
        knvars1 = BackendDAEUtil.emptyVars();
        ((_,knvars1)) = List.fold1(eqs,BackendDAEUtil.traverseBackendDAEExpsEqSystem,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsVars(knvars,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsVars(avars,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsEqns(remeqns,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsEqns(inieqns,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEArrayNoCopy(arreqns,checkUnusedVariables,BackendDAEUtil.traverseBackendDAEExpsArrayEqn,1,arrayLength(arreqns),(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEArrayNoCopy(algorithms,checkUnusedVariables,BackendDAEUtil.traverseAlgorithmExps,1,arrayLength(algorithms),(knvars,knvars1));
        (_,(_,knvars1)) = BackendDAETransform.traverseBackendDAEExpsWhenClauseLst(whenClauseLst,checkUnusedVariables,(knvars,knvars1));
        dae1 = BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,arreqns,algorithms,einfo,eoc,btp));
      then dae1;
  end match;
end removeUnusedVariables;

protected function checkUnusedVariables
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> inTpl;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local  
      DAE.Exp exp;
      BackendDAE.Variables vars,vars1;
    case ((exp,(vars,vars1)))
      equation
         ((_,(_,vars1))) = Expression.traverseExp(exp,checkUnusedVariablesExp,(vars,vars1));
       then
        ((exp,(vars,vars1)));
    case inTpl then inTpl;
  end matchcontinue;
end checkUnusedVariables;

protected function checkUnusedVariablesExp
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> inTuple;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e,e1;
      BackendDAE.Variables vars,vars1;
      DAE.ComponentRef cr;
      list<DAE.Exp> expl;
      list<DAE.ExpVar> varLst;
      DAE.Ident ident;
      list<BackendDAE.Var> backendVars;
      BackendDAE.Var var;
      DAE.ReductionIterators riters;
    
    // special case for time, it is never part of the equation system  
    case ((e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(vars,vars1)))
      then ((e, (vars,vars1)));
    
    // Special Case for Records
    case ((e as DAE.CREF(componentRef = cr,ty= DAE.ET_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),(vars,vars1)))
      equation
        expl = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        ((_,(vars,vars1))) = Expression.traverseExpList(expl,checkUnusedVariablesExp,(vars,vars1));
      then
        ((e, (vars,vars1)));

    // Special Case for Arrays
    case ((e as DAE.CREF(ty = DAE.ET_ARRAY(ty=_)),(vars,vars1)))
      equation
        ((e1,(_,true))) = BackendDAEUtil.extendArrExp((e,(NONE(),false)));
        ((_,(vars,vars1))) = Expression.traverseExp(e1,checkUnusedVariablesExp,(vars,vars1));
      then
        ((e, (vars,vars1)));
    
    // case for functionpointers    
    case ((e as DAE.CREF(ty=DAE.ET_FUNCTION_REFERENCE_FUNC(builtin=_)),(vars,vars1)))
      then
        ((e, (vars,vars1)));

    // already there
    case ((e as DAE.CREF(componentRef = cr),(vars,vars1)))
      equation
         (_,_) = BackendVariable.getVar(cr, vars1);
      then
        ((e, (vars,vars1)));

    // add it
    case ((e as DAE.CREF(componentRef = cr),(vars,vars1)))
      equation
         (var::_,_) = BackendVariable.getVar(cr, vars);
         vars1 = BackendVariable.addVar(var,vars1);
      then
        ((e, (vars,vars1)));
    
    case inTuple then inTuple;
  end matchcontinue;
end checkUnusedVariablesExp;

/* 
 * constant jacobians. Linear system of equations (A x = b) where
 * A and b are constants.
 */

public function constantLinearSystem
"function constantLinearSystem"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
algorithm
  (outDAE,outRunMatching) := BackendDAEUtil.mapEqSystemAndFold1(inDAE,constantLinearSystem0,inFunctionTree,false);
end constantLinearSystem;

protected function constantLinearSystem0
"function constantLinearSystem"
  input BackendDAE.EqSystem syst;
  input DAE.FunctionTree inFunctionTree;
  input tuple<BackendDAE.Shared,Boolean> sharedChanged;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> osharedChanged;
algorithm
  (osyst,osharedChanged):= 
    matchcontinue(syst,inFunctionTree,sharedChanged)
    local
      BackendDAE.BackendDAE dae,dae1;
      DAE.FunctionTree funcs;
      BackendDAE.Variables vars,knvars,exobj,avars,vars1,knvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      list<BackendDAE.WhenClause> whenClauseLst;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrix mT;
      array<Integer> ass1,ass2;
      BackendDAE.StrongComponents comps,comps1;
      Boolean b,b1,b2;
      list<Integer> eqnlst;
      BackendDAE.BinTree movedVars;
      BackendDAE.Shared shared;
      BackendDAE.BackendDAEType btp;
      BackendDAE.Matching matching;
      
    case (syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)),inFunctionTree,(shared,b1))
      equation
        (BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,matching=matching),BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,arreqns,algorithms,einfo,eoc,btp),b2,eqnlst,movedVars) = constantLinearSystem1(syst,shared,inFunctionTree,comps,{},BackendDAE.emptyBintree);
        b = b1 or b2;
        // move changed variables
        (vars1,knvars1) = BackendVariable.moveVariables(vars,knvars,movedVars);
        // remove changed eqns
        eqnlst = List.map1(eqnlst,intSub,1);
        eqns1 = BackendEquation.equationDelete(eqns,eqnlst);
        syst = BackendDAE.EQSYSTEM(vars1,eqns1,NONE(),NONE(),matching);
        shared = BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,arreqns,algorithms,einfo,eoc,btp);
        (m,mT) = BackendDAEUtil.incidenceMatrix(syst, shared, BackendDAE.NORMAL());
        syst = BackendDAE.EQSYSTEM(vars1,eqns1,SOME(m),SOME(mT),matching);
      then
        (syst,(shared,b));
  end matchcontinue;  
end constantLinearSystem0;

protected function constantLinearSystem1
"function constantLinearSystem1"
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input DAE.FunctionTree inFunctionTree;
  input BackendDAE.StrongComponents inComps;  
  input list<Integer> inEqnlst;
  input BackendDAE.BinTree inMovedVars;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Boolean outRunMatching;
  output list<Integer> outEqnlst;
  output BackendDAE.BinTree movedVars;
algorithm
  (osyst,oshared,outRunMatching,outEqnlst,movedVars):=
  matchcontinue (syst,shared,inFunctionTree,inComps,inEqnlst,inMovedVars)
    local
      BackendDAE.BackendDAE dae,dae1,dae2;
      DAE.FunctionTree funcs;
      BackendDAE.Variables vars,knvars,exobj,avars,vars1,knvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      list<BackendDAE.WhenClause> whenClauseLst;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.StrongComponents comps;
      BackendDAE.StrongComponent comp,comp1;
      Boolean b,b1;
      list<BackendDAE.Equation> eqn_lst; 
      list<BackendDAE.Var> var_lst;
      list<Integer> eindex,vindx,remeqnlst,remeqnlst1;
      list<DAE.Exp> beqs;
      list<DAE.ElementSource> sources;
      list<Real> rhsVals,solvedVals;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      list<list<Real>> jacVals;
      Integer linInfo;
      list<DAE.ComponentRef> names;
      BackendDAE.BinTree movedVars,movedVars1;
    case (syst,shared,funcs,{},inEqnlst,inMovedVars)
      then (syst,shared,false,inEqnlst,inMovedVars);
    case (syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,funcs,(comp as BackendDAE.EQUATIONSYSTEM(eqns=eindex,vars=vindx,jac=SOME(jac),jacType=BackendDAE.JAC_CONSTANT()))::comps,inEqnlst,inMovedVars)
      equation
        eqn_lst = BackendEquation.getEqns(eindex,eqns);        
        var_lst = List.map1r(vindx, BackendVariable.getVarAt, vars);
        var_lst = listReverse(var_lst);
        (syst,shared,movedVars) = solveLinearSystem(syst,shared,eqn_lst,var_lst,jac,inMovedVars);
        remeqnlst = listAppend(eindex,inEqnlst);
        (syst,shared,b,remeqnlst1,movedVars1) = constantLinearSystem1(syst,shared,funcs,comps,remeqnlst,movedVars);
      then
        (syst,shared,true,remeqnlst1,movedVars1);
    case (syst,shared,funcs,(comp as BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp1))::comps,inEqnlst,inMovedVars)
      equation
        (syst,shared,b,remeqnlst,movedVars) = constantLinearSystem1(syst,shared,funcs,{comp1},inEqnlst,inMovedVars);
        (syst,shared,b1,remeqnlst1,movedVars1) = constantLinearSystem1(syst,shared,funcs,comps,remeqnlst,movedVars);
      then
        (syst,shared,b1 or b,remeqnlst1,movedVars1);
    case (syst,shared,funcs,comp::comps,inEqnlst,inMovedVars)
      equation
        (syst,shared,b,remeqnlst,movedVars) = constantLinearSystem1(syst,shared,funcs,comps,inEqnlst,inMovedVars);
      then
        (syst,shared,b,remeqnlst,movedVars);
  end matchcontinue;  
end constantLinearSystem1;

protected function solveLinearSystem
"function constantLinearSystem1"
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input list<BackendDAE.Equation> eqn_lst; 
  input list<BackendDAE.Var> var_lst; 
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input BackendDAE.BinTree inMovedVars;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.BinTree outMovedVars;
algorithm
  (osyst,oshared,outMovedVars):=
  match (syst,shared,eqn_lst,var_lst,jac,inMovedVars)
    local
      BackendDAE.Variables vars,knvars,exobj,avars,vars1,knvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      list<BackendDAE.WhenClause> whenClauseLst;
      BackendDAE.ExternalObjectClasses eoc;
      list<DAE.Exp> beqs;
      list<DAE.ElementSource> sources;
      list<Real> rhsVals,solvedVals;
      list<list<Real>> jacVals;
      Integer linInfo;
      list<DAE.ComponentRef> names;
      BackendDAE.BinTree movedVars;
      BackendDAE.Matching matching;
    case (BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,matching=matching),shared as BackendDAE.SHARED(arrayEqs=arreqns),eqn_lst,var_lst,jac,inMovedVars)
      equation
        eqns1 = BackendDAEUtil.listEquation(eqn_lst);
        ((_,_,_,beqs,sources)) = BackendEquation.traverseBackendDAEEqns(eqns1,BackendEquation.equationToExp,(vars,arreqns,{},{},{}));
        //beqs = listReverse(beqs);
        rhsVals = ValuesUtil.valueReals(List.map(beqs,Ceval.cevalSimple));
        jacVals = evaluateConstantJacobian(listLength(var_lst),jac);
        (solvedVals,linInfo) = System.dgesv(jacVals,rhsVals);
        names = List.map(var_lst,BackendVariable.varCref);  
        checkLinearSystem(linInfo,names,jacVals,rhsVals);
        sources = List.map1(sources, DAEUtil.addSymbolicTransformation, DAE.LINEAR_SOLVED(names,jacVals,rhsVals,solvedVals));           
        vars1 = changeconstantLinearSystemVars(var_lst,solvedVals,sources,vars);
        movedVars = BackendDAEUtil.treeAddList(inMovedVars, names);
      then
        (BackendDAE.EQSYSTEM(vars1,eqns,NONE(),NONE(),matching),shared,movedVars);
  end match;  
end solveLinearSystem;

protected function changeconstantLinearSystemVars 
  input list<BackendDAE.Var> inVarLst;
  input list<Real> inSolvedVals;
  input list<DAE.ElementSource> inSources;
  input BackendDAE.Variables inVars;
  output BackendDAE.Variables outVars;
algorithm
    outVars := matchcontinue (inVarLst,inSolvedVals,inSources,inVars)
    local
      BackendDAE.Var v,v1;
      list<BackendDAE.Var> varlst;
      DAE.ElementSource s;
      list<DAE.ElementSource> slst;
      BackendDAE.Variables vars,vars1,vars2;
      Real r;
      list<Real> rlst;
    case ({},{},{},vars) then vars;      
    case (v::varlst,r::rlst,s::slst,vars)
      equation
        v1 = BackendVariable.setBindExp(v,DAE.RCONST(r));
        v1 = BackendVariable.setVarStartValue(v1,DAE.RCONST(r));
        // ToDo: merge source of var and equation
        vars1 = BackendVariable.addVar(v1,vars);
        vars2 = changeconstantLinearSystemVars(varlst,rlst,slst,vars1);
      then vars2;
  end matchcontinue; 
end changeconstantLinearSystemVars;

public function evaluateConstantJacobian
  "Evaluate a constant jacobian so we can solve a linear system during runtime"
  input Integer size;
  input list<tuple<Integer,Integer,BackendDAE.Equation>> jac;
  output list<list<Real>> vals;
protected
  array<array<Real>> valarr;
  array<Real> tmp;
  list<array<Real>> tmp2;
  list<Real> rs;
algorithm
  rs := List.fill(0.0,size);
  tmp := listArray(rs);
  tmp2 := List.map(List.fill(tmp,size),arrayCopy);
  valarr := listArray(tmp2);
  List.map1_0(jac,evaluateConstantJacobian2,valarr);
  tmp2 := arrayList(valarr);
  vals := List.map(tmp2,arrayList);
end evaluateConstantJacobian;

protected function evaluateConstantJacobian2
  input tuple<Integer,Integer,BackendDAE.Equation> jac;
  input array<array<Real>> vals;
algorithm
  _ := match (jac,vals)
    local
      DAE.Exp exp;
      Integer i1,i2;
      Real r;
    case ((i1,i2,BackendDAE.RESIDUAL_EQUATION(exp=exp)),vals)
      equation
        Values.REAL(r) = Ceval.cevalSimple(exp);
        _ = arrayUpdate(arrayGet(vals,i1),i2,r);
      then ();
  end match;
end evaluateConstantJacobian2;

protected function checkLinearSystem
  input Integer info;
  input list<DAE.ComponentRef> vars;
  input list<list<Real>> jac;
  input list<Real> rhs;
algorithm
  _ := matchcontinue (info,vars,jac,rhs)
    local
      String infoStr,syst,varnames,varname,rhsStr,jacStr;
    case (0,_,_,_) then ();
    case (info,vars,jac,rhs)
      equation
        true = info > 0;
        varname = ComponentReference.printComponentRefStr(listGet(vars,info));
        infoStr = intString(info);
        varnames = stringDelimitList(List.map(vars,ComponentReference.printComponentRefStr)," ;\n  ");
        rhsStr = stringDelimitList(List.map(rhs, realString)," ;\n  ");
        jacStr = stringDelimitList(List.map1(List.mapList(jac,realString),stringDelimitList," , ")," ;\n  ");
        syst = stringAppendList({"\n[\n  ", jacStr, "\n]\n  *\n[\n  ",varnames,"\n]\n  =\n[\n  ",rhsStr,"\n]"});
        Error.addMessage(Error.LINEAR_SYSTEM_SINGULAR, {syst,infoStr,varname});
      then fail();
    case (info,vars,jac,rhs)
      equation
        true = info < 0;
        varnames = stringDelimitList(List.map(vars,ComponentReference.printComponentRefStr)," ;\n  ");
        rhsStr = stringDelimitList(List.map(rhs, realString)," ; ");
        jacStr = stringDelimitList(List.map1(List.mapList(jac,realString),stringDelimitList," , ")," ; ");
        syst = stringAppendList({"[", jacStr, "] * [",varnames,"] = [",rhsStr,"]"});
        Error.addMessage(Error.LINEAR_SYSTEM_INVALID, {"LAPACK/dgesv",syst});
      then fail();
  end matchcontinue;
end checkLinearSystem;

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
  input array<Integer> inV1;
  input array<Integer> inV2;
  input BackendDAE.StrongComponents inComps;
  output BackendDAE.BackendDAE outDlow;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<list<Integer>> outComps;
  output list<list<Integer>> outResEqn;
  output list<list<Integer>> outTearVar;
algorithm
  (outDlow,outV1,outV2,outComps,outResEqn,outTearVar):=
  matchcontinue (inDlow,inV1,inV2,inComps)
    local
      BackendDAE.BackendDAE dlow,dlow_1,dlow1;
      BackendDAE.IncidenceMatrix m,m_1;
      BackendDAE.IncidenceMatrixT mT,mT_1;
      array<Integer> v1,v2,v1_1,v2_1;
      BackendDAE.StrongComponents comps;
      list<list<Integer>> r,t,comps_1,comps_2;
    case (dlow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mT))::{}),v1,v2,comps)
      equation
        Debug.fcall("tearingdump", print, "Tearing\n==========\n");
        // get residual eqn and tearing var for each block
        // copy dlow
        dlow1 = copyDaeLowforTearing(dlow);
        comps_1 = List.map(comps,getEqnIndxFromComp);
        (r,t,_,dlow_1,m_1,mT_1,v1_1,v2_1,comps_2) = tearingSystem1(dlow,dlow1,m,mT,v1,v2,comps_1);
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrix, m_1);
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrixT, mT_1);
        Debug.fcall("tearingdump", BackendDump.dump, dlow_1);
        Debug.fcall("tearingdump", BackendDump.dumpMatching, v1_1);
        //Debug.fcall("tearingdump", BackendDump.dumpComponents, comps_2);
        Debug.fcall("tearingdump", print, "==========\n");
        Debug.fcall2("tearingdump", BackendDump.dumpTearing, r,t);
        Debug.fcall("tearingdump", print, "==========\n");
      then
        (dlow_1,v1_1,v2_1,comps_2,r,t);
    case (dlow,v1,v2,comps)
      equation
        Debug.fcall("tearingdump", print, "No Tearing\n==========\n");
      then
        fail();
  end matchcontinue;
end tearingSystem;

protected function getEqnIndxFromComp
"function: getEqnIndxFromComp
  author: Frenkel TUD"
  input BackendDAE.StrongComponent inComp;
  output list<Integer> outEqnIndexLst;
algorithm
  outEqnIndexLst:=
  matchcontinue (inComp)
    local
      Integer e,i;
      list<Integer> elst;
      Boolean b;
    case (BackendDAE.SINGLEEQUATION(eqn=e))
      then
        {e};
    case (BackendDAE.EQUATIONSYSTEM(eqns=elst))
      then
        elst;        
    case (BackendDAE.SINGLEARRAY(eqns=elst))
      then
        elst;
    case (BackendDAE.SINGLEALGORITHM(eqns=elst))
      then
        elst;       
  end matchcontinue;
end getEqnIndxFromComp;

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
      BackendDAE.VariableArray varArr;
      Integer bucketSize;
      Integer numberOfVars;
      array<Option<BackendDAE.Var>> varOptArr,varOptArr1;
      BackendDAE.Shared shared;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Matching matching;
    case (BackendDAE.DAE(BackendDAE.EQSYSTEM(ordvars,eqns,m,mT,matching)::{},shared))
      equation
        BackendDAE.VARIABLES(crefIdxLstArr,varArr,bucketSize,numberOfVars) = ordvars;
        BackendDAE.VARIABLE_ARRAY(n1,size1,varOptArr) = varArr;
        crefIdxLstArr1 = arrayCreate(size1, {});
        crefIdxLstArr1 = Util.arrayCopy(crefIdxLstArr, crefIdxLstArr1);
        varOptArr1 = arrayCreate(size1, NONE());
        varOptArr1 = Util.arrayCopy(varOptArr, varOptArr1);
        ordvars1 = BackendDAE.VARIABLES(crefIdxLstArr1,BackendDAE.VARIABLE_ARRAY(n1,size1,varOptArr1),bucketSize,numberOfVars);
        BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr) = eqns;
        arr_1 = arrayCreate(size, NONE());
        arr_1 = Util.arrayCopy(arr, arr_1);
        eqns1 = BackendDAE.EQUATION_ARRAY(n,size,arr_1);
      then
        BackendDAE.DAE(BackendDAE.EQSYSTEM(ordvars1,eqns1,m,mT,matching)::{},shared);
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
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
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
        BackendDAE.DAE({syst},shared) = dlow1_1;
        (m_3,mT_3) = BackendDAEUtil.incidenceMatrix(syst, shared, BackendDAE.NORMAL());
        //mT_3 = BackendDAEUtil.transposeMatrix(m_3);
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
    case (m,v1,v2,c::comp,dlow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = ordvars as BackendDAE.VARIABLES(varArr=varr))::{}))
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
        vars_1 = List.select1(vars,listMember,tvars);
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
      BackendDAE.StrongComponents comps;
      list<list<Integer>> comps_1,comps_2,onecomp,morecomps;
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
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
    
    case (dlow as BackendDAE.DAE(eqs={syst}),dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        vararray = BackendVariable.daeVars(syst);
        (tearingvar,_) = getMaxfromListListVar(mT,vars,comp,0,0,exclude,vararray);
        // check if tearing var is found
        true = tearingvar > 0;
        str = intString(tearingvar);
        str1 = stringAppend("\nTearingVar: ", str);
        str2 = stringAppend(str1,"\n");
        Debug.fcall("tearingdump", print, str2);
        // copy dlow
        dlowc = copyDaeLowforTearing(dlow);
        BackendDAE.DAE(BackendDAE.EQSYSTEM(ordvars as BackendDAE.VARIABLES(varArr=varr),eqns,_,_,_)::{},shared) = dlowc;
        dlowc1 = copyDaeLowforTearing(dlow1);
        BackendDAE.DAE(eqs = BackendDAE.EQSYSTEM(ordvars1,eqns1,_,_,_)::{}) = dlowc1;
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
                          {},DAE.callAttrBuiltinReal),
                          expCref, DAE.emptyElementSource),eqns_1);

        tearingeqnid = BackendDAEUtil.equationSize(eqns_2);
        dlow_1 = BackendDAE.DAE(BackendDAE.EQSYSTEM(vars_1,eqns_2,NONE(),NONE(),BackendDAE.NO_MATCHING())::{},shared);
        dlow1_1 = BackendDAE.DAE(BackendDAE.EQSYSTEM(ordvars1,eqns1_1,NONE(),NONE(),BackendDAE.NO_MATCHING())::{},shared);
        // try causalisation
        (dlow_2 as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(m=SOME(m_2),mT=SOME(mT_2),matching=BackendDAE.MATCHING(v1_1,v2_1,comps))::{})) = BackendDAEUtil.transformBackendDAE(dlow_1,DAEUtil.avlTreeNew(),SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())),NONE());
        comps_1 = List.map(comps,getEqnIndxFromComp);
        // check strongComponents and split it into two lists: len(comp)==1 and len(comp)>1
        (morecomps,onecomp) = splitComps(comps_1);
        // try to solve the equations
        onecomp_flat = List.flatten(onecomp);
        // remove residual equations and tearing eqns
        resteareqns = listAppend(tearingeqnid::tearingeqns,residualeqn::residualeqns);
        othereqns = List.select1(onecomp_flat,List.notMember,resteareqns);
        eqns1_2 = solveEquations(eqns1_1,othereqns,v2_1,vars_1,crlst);
         // if we have not make alle equations causal select next residual equation
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_3,dlow1_2,m_3,mT_3,v1_2,v2_2,comps_2,compcount) = tearingSystem4(dlow_2,dlow1_1,m_2,mT_2,v1_1,v2_1,comps_1,residualeqn::residualeqns,tearingvar::tearingvars,tearingeqnid::tearingeqns,comp,0,crlst);
        // check
        true = ((listLength(residualeqns_1) > listLength(residualeqns)) and
                (listLength(tearingvars_1) > listLength(tearingvars)) ) or (compcount == 0);
        // get specifig comps
        cmops_flat = List.flatten(comps_2);
        comp_2 = List.select1(cmops_flat,listMember,comp);
      then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_3,dlow1_2,m_3,mT_3,v1_2,v2_2,comp_2);
    case (dlow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = BackendDAE.VARIABLES(varArr=varr))::{}),dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,crlst)
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
    case (dlow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = BackendDAE.VARIABLES(varArr=varr))::{}),dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,_)
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
        checklst = List.map1(comp,listMember,ccomp);
        true = listMember(true,checklst);
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
        checklst = List.map1(comp,listMember,ccomp);
        true = listMember(true,checklst);
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
        false = listMember(v,exclude);
        eqn = m[v];
        // remove negative
        eqn_1 = BackendDAEUtil.removeNegative(eqn);
        // select entries
        eqn_2 = List.select1(eqn_1,listMember,comp);
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
        false = listMember(v,exclude);
        eqn = m[v];
        // remove negative
        eqn_1 = BackendDAEUtil.removeNegative(eqn);
        // select entries
        eqn_2 = List.select1(eqn_1,listMember,comp);
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
        false = listMember(v,rest);
        lst = removeMultiple(rest);
      then
        (v::lst);
    case (v::rest)
      equation
        true = listMember(v,rest);
        lst = removeMultiple(rest);
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
      Integer e,e_1,v;
      array<Integer> ass;
      BackendDAE.Variables vars;
      DAE.Exp e1,e2,varexp,expr;
      list<DAE.Exp> divexplst,constexplst,nonconstexplst,tfixedexplst,tnofixedexplst;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      list<list<DAE.ComponentRef>> crlstlst;
      DAE.ElementSource source;
      list<Boolean> blst,blst_1;
      list<list<Boolean>> blstlst;
    case (eqns,{},ass,vars,crlst) then eqns;
    case (eqns,e::rest,ass,vars,crlst)
      equation
        e_1 = e - 1;
        BackendDAE.EQUATION(e1,e2,source) = BackendDAEUtil.equationNth(eqns, e_1);
        v = ass[e_1 + 1];
        BackendDAE.VAR(varName=cr) = BackendVariable.getVarAt(vars, v);
        varexp = Expression.crefExp(cr);

        (expr,{}) = ExpressionSolve.solve(e1, e2, varexp);
        source = DAEUtil.addSymbolicTransformationSolve(true, source, cr, e1, e2, expr, {});
        divexplst = Expression.extractDivExpFromExp(expr);
        (constexplst,nonconstexplst) = List.splitOnTrue(divexplst,Expression.isConst);
        // check constexplst if equal 0
        blst = List.map(constexplst, Expression.isZero);
        false = Util.boolOrList(blst);
        // check nonconstexplst if tearing variables or variables which will be
        // changed during solving process inside
        crlstlst = List.map(nonconstexplst,Expression.extractCrefsFromExp);
        // add explst with variables which will not be changed during solving prozess
        blstlst = List.map2List(crlstlst,List.isMemberOnTrue,crlst,ComponentReference.crefEqualNoStringCompare);
        blst_1 = List.map(blstlst,Util.boolOrList);
        (tnofixedexplst,tfixedexplst) = List.splitOnBoolList(nonconstexplst,blst_1);
        true = listLength(tnofixedexplst) < 1;
/*        print("\ntfixedexplst DivExpLst:\n");
        s = List.map(tfixedexplst, ExpressionDump.printExpStr);
        List.map_0(s,print);
        print("\n===============================\n");
        print("\ntnofixedexplst DivExpLst:\n");
        s = List.map(tnofixedexplst, ExpressionDump.printExpStr);
        List.map_0(s,print);
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
  input Integer inNoColumn;
  output BackendDAE.BackendDAE outJacobian;
algorithm 
  outJacobian :=
    matchcontinue (inBackendDAE,functionTree,inComRef1,inComRef2,inAllVar,inNoColumn)
    local
      BackendDAE.BackendDAE dlow;
      
      list<DAE.ComponentRef> eqvars,diffvars;
      list<BackendDAE.Var> varlst;
      array<Integer> v1,v2,v4,v31;
      list<Integer> v3;
      BackendDAE.StrongComponents comps1;
      list<BackendDAE.Var> derivedVariables;
      list<BackendDAE.Var> derivedVars;
      BackendDAE.BinTree jacElements;
      list<tuple<DAE.ComponentRef,Integer>> varTuple;
      array<list<Integer>> m,mT;
      Option<array<list<Integer>>> om,omT;
      
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
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.Matching matching;
      array<Integer> ea;
      
      case (dlow as BackendDAE.DAE(BackendDAE.EQSYSTEM(v,e,om,omT,_)::{},shared),_,{},_,_,_)
        equation
          v = BackendDAEUtil.listVar({});
          ea = listArray({});
        then (BackendDAE.DAE(BackendDAE.EQSYSTEM(v,e,om,omT,BackendDAE.MATCHING(ea,ea,{}))::{},shared));
      case (dlow as BackendDAE.DAE(BackendDAE.EQSYSTEM(v,e,om,omT,_)::{},shared),_,_,{},_,_)
        equation
          v = BackendDAEUtil.listVar({});
          ea = listArray({});
        then (BackendDAE.DAE(BackendDAE.EQSYSTEM(v,e,om,omT,BackendDAE.MATCHING(ea,ea,{}))::{},shared));
      case (dlow,functionTree,eqvars,diffvars,varlst,inNoColumn)
        equation
          true = RTOpts.debugFlag("linearization");
        
          // Remove simple Equtaion and Parameters
          dlow = removeFinalParameters(dlow,functionTree);
          dlow = removeProtectedParameters(dlow,functionTree);
          dlow = removeParameters(dlow,functionTree);
          dlow = removeSimpleEquations(dlow,functionTree);

          Debug.fcall("execstat",print, "*** analytical Jacobians -> removed simply equations: " +& realString(clock()) +& "\n" );
          // figure out new matching and the strong components  
          (dlow as BackendDAE.DAE(eqs={BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps1))})) = BackendDAEUtil.transformBackendDAE(dlow,functionTree,SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())),NONE());
          Debug.fcall("jacdump2", BackendDump.bltdump, ("jacdump2",dlow));
          Debug.fcall("execstat",print, "*** analytical Jacobians -> performed matching and sorting: " +& realString(clock()) +& "\n" );
        
          Debug.fcall("jacdump2", BackendDump.dumpComponents, comps1);
          //Debug.fcall("execstat",print, "*** analytical Jacobians -> performed splitig the system: " +& realString(clock()) +& "\n" );
        then dlow;

          
      case (dlow,functionTree,eqvars,diffvars,varlst,inNoColumn)
        equation
          true = RTOpts.debugFlag("jacobian");
        
          // Remove simple Equtaion and Parameters
          dlow = removeFinalParameters(dlow,functionTree);
          dlow = removeProtectedParameters(dlow,functionTree);
          dlow = removeParameters(dlow,functionTree);
          dlow = removeSimpleEquations(dlow,functionTree);

          Debug.fcall("execstat",print, "*** analytical Jacobians -> removed simply equations: " +& realString(clock()) +& "\n" );
          // figure out new matching and the strong components  
          dlow = BackendDAEUtil.transformBackendDAE(dlow,functionTree,SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())),NONE());        
          Debug.fcall("jacdump2", BackendDump.bltdump, ("jacdump2",dlow));
          Debug.fcall("execstat",print, "*** analytical Jacobians -> performed matching and sorting: " +& realString(clock()) +& "\n" );
       
        then dlow;
     else
       equation
         Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.generateLinearMatrix failed"});
       then fail();
   end matchcontinue;
end generateLinearMatrix;


/* 
 * Symbolic Jacobian subsection
 */ 

public function generateSymbolicJacobian
  // function: generateSymbolicJacobian
  // author: lochel
  input BackendDAE.BackendDAE inBackendDAE;
  input DAE.FunctionTree inFunctions;
  input list<DAE.ComponentRef> inVars;
  input BackendDAE.Variables  indiffedVars;
  input BackendDAE.Variables  inseedVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  output BackendDAE.BackendDAE outJacobian;
algorithm
  outJacobian := matchcontinue(inBackendDAE, inFunctions, inVars, indiffedVars, inseedVars,inStateVars, inInputVars, inParamVars)
    local
      BackendDAE.BackendDAE bDAE;
      DAE.FunctionTree functions;
      list<DAE.ComponentRef> vars, comref_diffvars, allEqnCrefs;
      DAE.ComponentRef x;
      BackendDAE.Variables stateVars;
      BackendDAE.Variables inputVars;
      BackendDAE.Variables paramVars;
      BackendDAE.Variables diffedVars;
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
      
    case(_, _, {}, _, _, _, _, _) equation
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
      
      jacobian = BackendDAE.DAE(BackendDAE.EQSYSTEM(jacOrderedVars, jacOrderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING())::{}, BackendDAE.SHARED(jacKnownVars, jacExternalObjects, jacAliasVars, jacInitialEqs, jacRemovedEqs, jacArrayEqs, jacAlgorithms, jacEventInfo, jacExtObjClasses,BackendDAE.JACOBIAN()));
    then jacobian;
      
    case(bDAE as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedVars=orderedVars,orderedEqs=orderedEqs)::{}, BackendDAE.SHARED(knownVars=knownVars, removedEqs=removedEqs, algorithms=algorithms)), functions, vars, diffedVars, inseedVars, stateVars, inputVars, paramVars) equation
      Debug.fcall("jacdump", print, "\n+++++++++++++++++++++ daeLow-dump:    input +++++++++++++++++++++\n");
      Debug.fcall("jacdump", BackendDump.dump, bDAE);
      Debug.fcall("jacdump", print, "##################### daeLow-dump:    input #####################\n\n");
      
      // Generate tmp varibales
      diffvars = BackendDAEUtil.varList(orderedVars);
      x = DAE.CREF_IDENT("dummyVar",DAE.ET_REAL(),{});
      derivedVariables = creatallDiffedVars(diffvars,x,diffedVars,0);

      // differentiate the equation system
      (derivedAlgorithms, derivedAlgorithmsLookUp) = deriveAllAlg(arrayList(algorithms), {x}, functions, inputVars, paramVars, stateVars, knownVars, orderedVars, 0,vars);
      derivedEquations = deriveAll(BackendDAEUtil.equationList(orderedEqs), {x}, functions, inputVars, paramVars, stateVars, knownVars, derivedAlgorithmsLookUp, orderedVars, vars);
      Debug.fcall("execstat",print, "*** analytical Jacobians -> created all derived equation: " +& realString(clock()) +& "\n" );
      
      // create BackendDAE.DAE with derivied vars and equations
      
      // all variables for new equation system
      // d(ordered vars)/d(dummyVar) 
      diffvars = BackendDAEUtil.varList(orderedVars);
      diffvars = List.sort(diffvars, BackendVariable.varIndexComparer);
      x = DAE.CREF_IDENT("dummyVar",DAE.ET_REAL(),{});
      derivedVariables = creatallDiffedVars(diffvars,x,diffedVars,0);    
      jacOrderedVars = BackendDAEUtil.listVar(derivedVariables);
      
      // known vars: all variable from original system + seed
      jacKnownVars = BackendDAEUtil.emptyVars();
      jacKnownVars = BackendVariable.mergeVariables(jacKnownVars,orderedVars);
      jacKnownVars = BackendVariable.mergeVariables(jacKnownVars,knownVars);
      jacKnownVars = BackendVariable.mergeVariables(jacKnownVars,inseedVars);
      (jacKnownVars,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(jacKnownVars,setVarsDirection,(DAE.INPUT()));
      jacExternalObjects = BackendDAEUtil.emptyVars();
      jacAliasVars =  BackendDAEUtil.emptyAliasVariables();
      jacOrderedEqs = BackendDAEUtil.listEquation(derivedEquations);
      jacRemovedEqs = BackendDAEUtil.listEquation({});
      jacInitialEqs = BackendDAEUtil.listEquation({});
      jacArrayEqs = listArray({});
      jacAlgorithms = listArray(derivedAlgorithms);
      jacEventInfo = BackendDAE.EVENT_INFO({},{});
      jacExtObjClasses = {};
      
      jacobian = BackendDAE.DAE(BackendDAE.EQSYSTEM(jacOrderedVars, jacOrderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING())::{}, BackendDAE.SHARED(jacKnownVars, jacExternalObjects, jacAliasVars, jacInitialEqs, jacRemovedEqs, jacArrayEqs, jacAlgorithms, jacEventInfo, jacExtObjClasses,BackendDAE.JACOBIAN()));
      
      Debug.fcall("jacdump", print, "\n+++++++++++++++++++++ daeLow-dump: jacobian +++++++++++++++++++++\n");
      Debug.fcall("jacdump", BackendDump.dump, jacobian);
      Debug.fcall("jacdump", print, "##################### daeLow-dump: jacobian #####################\n");
    then jacobian;
      
    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.generateSymbolicJacobian failed"});
    then fail();
  end matchcontinue;
end generateSymbolicJacobian;

protected function setVarsDirection
  input tuple<BackendDAE.Var,DAE.VarDirection> inTpl;
  output tuple<BackendDAE.Var,DAE.VarDirection> outTpl;
algorithm 
  outTpl  := match(inTpl)
  local
    BackendDAE.Var var;
    DAE.VarDirection dir;
    case((var,dir))
      equation
        var = BackendVariable.setVarDirection(var, dir); 
      then 
        ((var,dir));
   end match;
 end setVarsDirection;

public function createJacVars
  // function: createJacVars
  // author: wbraun
  input DAE.ComponentRef indiffVar;
  output BackendDAE.Var outdiffedVar;
algorithm
  outdiffedVar := match(indiffVar)
    local
      BackendDAE.Var  jacvar;
      DAE.ComponentRef derivedCref;
    case (indiffVar)
      equation 
        derivedCref = differentiateVarWithRespectToX(indiffVar, indiffVar);
        jacvar = BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), BackendDAE.REAL(), NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      then jacvar;
  end match;          
end createJacVars;

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
      
    else
     equation
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
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.VARIABLE(), DAE.BIDIR(), BackendDAE.REAL(), NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      (r2,res1) = generateJacobianVars2(var, restVar);
      res = listAppend({derivedCref}, res1);
      r = listAppend({r1}, r2);
    then (r,res);
      
    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.generateJacobianVars2 failed"});
    then fail();
  end matchcontinue;
end generateJacobianVars2;

protected function creatallDiffedVars
  // function: help function for creatallDiffedVars
  // author: wbraun
  input list<BackendDAE.Var> inVars;
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inAllVars;
  input Integer inIndex;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := matchcontinue(inVars, inCref,inAllVars,inIndex)
  local
    BackendDAE.Var var, r1,v1;
    DAE.ComponentRef currVar, cref, derivedCref;
    list<BackendDAE.Var> restVar;
    list<BackendDAE.Var> r,r2;
    
    case({}, _, _, _)
    then {};
    // skip for dicrete variable
    case(BackendDAE.VAR(varName=currVar,varKind=BackendDAE.DISCRETE())::restVar,cref,inAllVars,inIndex) equation
      r = creatallDiffedVars(restVar,cref,inAllVars,inIndex);
    then r;      
 
     case(BackendDAE.VAR(varName=currVar,varKind=BackendDAE.STATE())::restVar,cref,inAllVars,inIndex) equation
      ({v1}, _) = BackendVariable.getVar(currVar, inAllVars);
      currVar = ComponentReference.crefPrefixDer(currVar);
      derivedCref = differentiateVarWithRespectToX(currVar, cref);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), BackendDAE.REAL(), NONE(), NONE(), {}, inIndex,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      r2 = creatallDiffedVars(restVar,cref,inAllVars,inIndex+1);
      r = listAppend({r1}, r2);
    then r;
      
    case(BackendDAE.VAR(varName=currVar)::restVar,cref,inAllVars,inIndex) equation
      ({v1}, _) = BackendVariable.getVar(currVar, inAllVars);
      derivedCref = differentiateVarWithRespectToX(currVar, cref);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), BackendDAE.REAL(), NONE(), NONE(), {}, inIndex,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      r2 = creatallDiffedVars(restVar,cref,inAllVars,inIndex+1);
      r = listAppend({r1}, r2);
    then r;  
 
     case(BackendDAE.VAR(varName=currVar,varKind=BackendDAE.STATE())::restVar,cref,inAllVars,inIndex) equation
      currVar = ComponentReference.crefPrefixDer(currVar);
      derivedCref = differentiateVarWithRespectToX(currVar, cref);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.VARIABLE(), DAE.BIDIR(), BackendDAE.REAL(), NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      r2 = creatallDiffedVars(restVar,cref,inAllVars,inIndex);
      r = listAppend({r1}, r2);
    then r;
      
    case(BackendDAE.VAR(varName=currVar)::restVar,cref,inAllVars,inIndex) equation
      derivedCref = differentiateVarWithRespectToX(currVar, cref);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.VARIABLE(), DAE.BIDIR(), BackendDAE.REAL(), NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      r2 = creatallDiffedVars(restVar,cref,inAllVars,inIndex);
      r = listAppend({r1}, r2);
    then r;  
 
    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.creatallDiffedVars failed"});
    then fail();
  end matchcontinue;
end creatallDiffedVars;

public function determineIndices
  // function: determineIndices
  // using column major order
  input list<DAE.ComponentRef> inStates;
  input list<DAE.ComponentRef> inStates2;
  input Integer inActInd;
  input list<BackendDAE.Var> inAllVars;
  input Integer inNoStates;
  output list<tuple<DAE.ComponentRef,Integer>> outTuple;
algorithm
  outTuple := matchcontinue(inStates, inStates2, inActInd,inAllVars,inNoStates)
    local
      list<tuple<DAE.ComponentRef,Integer>> str;
      list<tuple<DAE.ComponentRef,Integer>> erg;
      list<DAE.ComponentRef> rest, states;
      DAE.ComponentRef curr,dState;
      Integer actInd, noStates;
      list<BackendDAE.Var> allVars;
      
    case ({}, states, _, _, _) then {};
    case (curr::rest, states, actInd, allVars, noStates) equation
      ({BackendDAE.VAR(varKind = BackendDAE.STATE())}, _) = BackendVariable.getVar(curr, BackendDAEUtil.listVar(allVars));
      dState = ComponentReference.crefPrefixDer(curr);
      //actInd = actInd + (listLength(rest)+1);
      (str, actInd) = determineIndices2(dState, states, actInd, allVars,true,noStates);
      erg = determineIndices(rest, states, actInd, allVars,noStates);
      str = listAppend(str, erg);
    then str;
    case (curr::rest, states, actInd, allVars, noStates) equation
      failure(({BackendDAE.VAR(varKind = BackendDAE.STATE())}, _) = BackendVariable.getVar(curr, BackendDAEUtil.listVar(allVars)));
      //actInd = noStates - (listLength(rest)+1);
      (str, actInd) = determineIndices2(curr, states, actInd, allVars,false,noStates);
      erg = determineIndices(rest, states, actInd, allVars,noStates);
      str = listAppend(str, erg);
    then str;    
    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.determineIndices failed"});
    then fail();        
  end matchcontinue;
end determineIndices;

protected function determineIndices2
  // function: determineIndices2
  input DAE.ComponentRef inDStates;
  input list<DAE.ComponentRef> inStates;
  input Integer actInd;
  input list<BackendDAE.Var> inAllVars;
  input Boolean isDStateState;
  input Integer inNoStates;  
  output list<tuple<DAE.ComponentRef,Integer>> outTuple;
  output Integer outActInd;
algorithm
  (outTuple,outActInd) := matchcontinue(inDStates, inStates, actInd, inAllVars,isDStateState,inNoStates)
    local
      tuple<DAE.ComponentRef,Integer> str;
      list<tuple<DAE.ComponentRef,Integer>> erg;
      list<DAE.ComponentRef> rest;
      DAE.ComponentRef new, curr, dState;
      list<BackendDAE.Var> allVars;
      //String debug1;Integer debug2;
    case (dState, {}, actInd, allVars,_,_) then ({}, actInd);
    case (dState,curr::rest, actInd, allVars,true,inNoStates) equation
      new = differentiateVarWithRespectToX(dState,curr);
      str = (new ,actInd);
      //print("CRef: " +& ComponentReference.printComponentRefStr(new) +& " index: " +& intString(actInd) +& "\n");
      actInd = actInd+1;
      (erg, actInd) = determineIndices2(dState, rest, actInd, allVars,true,inNoStates);
    then (str::erg, actInd);
    case (dState,curr::rest, actInd, allVars,false,inNoStates) equation
      new = differentiateVarWithRespectToX(dState,curr);
      str = (new ,actInd);
      //print("CRef: " +& ComponentReference.printComponentRefStr(new) +& " index: " +& intString(actInd) +& "\n");
      actInd = actInd+1;
      (erg, actInd) = determineIndices2(dState, rest, actInd, allVars,false,inNoStates);
    then (str::erg, actInd);
    else
    equation
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
    else
    equation
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
      Debug.fcall("varIndex2",BackendDump.debugCrefStrIntStr,(currVar," ",currInd,"\n"));
      bt = BackendDAEUtil.treeAddList(bt,{currCREF});
    then (changedVar,bt);
    case (curr  as BackendDAE.VAR(varName=currCREF),{},bt) equation
      changedVar = BackendVariable.setVarIndex(curr,-1);
      Debug.fcall("varIndex2",BackendDump.debugCrefStr, (currCREF," -1\n"));
    then (changedVar,bt);
    case (curr  as BackendDAE.VAR(varName=currCREF),(currVar,currInd)::restTuple,bt) equation
      changedVar = BackendVariable.setVarIndex(curr,-1);
      Debug.fcall("varIndex2",BackendDump.debugCrefStr,(currCREF," -1\n"));
      (changedVar,bt) = changeIndices2(changedVar,restTuple,bt);
    then (changedVar,bt);
    else
    equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.changeIndices2() failed"});
    then fail();
  end matchcontinue;
end changeIndices2;

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
      Debug.fcall("execstat",print, "*** analytical Jacobians -> derive one equation: " +& realString(clock()) +& "\n" );
      currDerivedEquations = derive(currEquation, vars, functions, inputVars, paramVars, stateVars, knownVars, algorithmsLookUp, inorderedVars, inDiffVars);
      Debug.fcall("jacdumpeqn", BackendDump.dumpEqns, currDerivedEquations);
      Debug.fcall("jacdumpeqn", print, "\n");
      Debug.fcall("execstat",print, "*** analytical Jacobians -> created other equations from that: " +& realString(clock()) +& "\n" );
      restDerivedEquations = deriveAll(restEquations, vars, functions, inputVars, paramVars, stateVars, knownVars, algorithmsLookUp, inorderedVars, inDiffVars);
      derivedEquations = listAppend(currDerivedEquations, restDerivedEquations);
    then derivedEquations;
 
    else
     equation
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
      derivedEqns = List.threadMap1(lhs_, rhs_, createEqn, source);
    then derivedEqns;
      
    case(currEquation as BackendDAE.ARRAY_EQUATION(_, _, _), vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.derive failed: ARRAY_EQUATION-case"});
    then fail();
      
    case(currEquation as BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=exp, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, _, inorderedVars, inDiffVars) equation
      crefs = List.map1(vars,differentiateVarWithRespectToXR,cref);
      exps = differentiateWithRespectToXVec(exp, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars);
      derivedEqns = List.threadMap1(crefs, exps, createSolvedEqn, source);
    then derivedEqns;
      
    case(currEquation as BackendDAE.RESIDUAL_EQUATION(exp=exp, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, _, inorderedVars, inDiffVars) equation
      exps = differentiateWithRespectToXVec(exp, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars);
      derivedEqns = List.map1(exps, createResidualEqn, source);
    then derivedEqns;
      
    case(currEquation as BackendDAE.ALGORITHM(index=index, in_={}, out=out_, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, algorithmsLookUp, inorderedVars, inDiffVars)
    equation
      derivedOut = List.map8(out_, differentiateWithRespectToXVec, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars);
      //derivedIn = List.transposeList(derivedIn);
      //derivedIn = List.map1(derivedIn,listAppend,in_);
      derivedOut = List.transposeList(derivedOut);
      //s = ExpressionDump.printListStr(derivedIn, ExpressionDump.printExpListStr, " ");
      //s1 = intString(listLength(derivedIn));
      //print("#### DerivedIns (" +& s1 +& ") : " +& s +& "\n"); //stringCharListString(slst) +& "\n");
      //s = ExpressionDump.printListStr(derivedOut, ExpressionDump.printExpListStr, " ");
      //s1 = intString(listLength(derivedOut));
      //print("#### DerivedOuts (" +& s1 +& ") : " +& s +& "\n"); //stringCharListString(slst) +& "\n");
      derivedEqns = List.threadMap3(derivedOut, vars, createAlgorithmEqnEmptyIn,index,algorithmsLookUp, source);
    then derivedEqns;

    case(currEquation as BackendDAE.ALGORITHM(index=index, in_=in_, out={}, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, algorithmsLookUp, inorderedVars, inDiffVars)
    equation
      derivedIn = List.map8(in_, differentiateWithRespectToXVec, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars);
      derivedIn = List.transposeList(derivedIn);
      derivedIn = List.map1(derivedIn,listAppend,in_);
      //derivedOut = List.transposeList(derivedOut);
      //s = ExpressionDump.printListStr(derivedIn, ExpressionDump.printExpListStr, " ");
      //s1 = intString(listLength(derivedIn));
      //print("#### DerivedIns (" +& s1 +& ") : " +& s +& "\n"); //stringCharListString(slst) +& "\n");
      //s = ExpressionDump.printListStr(derivedOut, ExpressionDump.printExpListStr, " ");
      //s1 = intString(listLength(derivedOut));
      //print("#### DerivedOuts (" +& s1 +& ") : " +& s +& "\n"); //stringCharListString(slst) +& "\n");
      derivedEqns = List.threadMap3(derivedIn, vars, createAlgorithmEqnEmptyOut,index,algorithmsLookUp, source);
    then derivedEqns;


    case(currEquation as BackendDAE.ALGORITHM(index=index, in_=in_, out=out_, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, algorithmsLookUp, inorderedVars, inDiffVars)
    equation
      derivedIn = List.map8(in_, differentiateWithRespectToXVec, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars);
      derivedOut = List.map8(out_, differentiateWithRespectToXVec, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars);
      derivedIn = List.transposeList(derivedIn);
      derivedIn = List.map1(derivedIn,listAppend,in_);
      derivedOut = List.transposeList(derivedOut);
      //s = ExpressionDump.printListStr(derivedIn, ExpressionDump.printExpListStr, " ");
      //s1 = intString(listLength(derivedIn));
      //print("#### DerivedIns (" +& s1 +& ") : " +& s +& "\n");
      //s = ExpressionDump.printListStr(derivedOut, ExpressionDump.printExpListStr, " ");
      //s1 = intString(listLength(derivedOut));
      //print("#### DerivedOuts (" +& s1 +& ") : " +& s +& "\n");
      derivedEqns = List.thread3Map3(derivedIn, derivedOut, vars, createAlgorithmEqn,index,algorithmsLookUp, source);
    then derivedEqns;

    case(currEquation as BackendDAE.COMPLEX_EQUATION(_, _, _, _), vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.derive failed: COMPLEX_EQUATION-case"});
    then fail();
      
    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.derive failed"});
    then fail();
  end matchcontinue;
end derive;

protected function createEqn
  input DAE.Exp inLHS;
  input DAE.Exp inRHS;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm 
  outEqn := BackendDAE.EQUATION(inLHS,inRHS,Source);
end createEqn;

protected function createSolvedEqn
  input DAE.ComponentRef inCref;
  input DAE.Exp inRHS;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm 
  outEqn := BackendDAE.SOLVED_EQUATION(inCref,inRHS,Source);
end createSolvedEqn;

protected function createResidualEqn
  input DAE.Exp inRHS;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm 
  outEqn := BackendDAE.RESIDUAL_EQUATION(inRHS, Source);
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
      newAlgIndex = List.position((inIndex, inCref), inAlgorithmsLookUp);
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
      newAlgIndex = List.position((inIndex, inCref), inAlgorithmsLookUp);
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
      newAlgIndex = List.position((inIndex, inCref), inAlgorithmsLookUp);
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
      DAE.CallAttributes attr;
    case ( _, {}, _, _, _) then (DAE.RCONST(0.0));
    case (currVar::restVar, currDerVar::restDerVar, functionCall as DAE.CALL(expLst=varExpListTotal, attr=attr), derFname, nDerArgs)
      equation
        e = partialAnalyticalDifferentiation(restVar, restDerVar, functionCall, derFname, nDerArgs);
        nArgs1 = listLength(varExpListTotal);
        nArgs2 = listLength(restDerVar);
        varExpList1Added = List.replaceAtWithFill(DAE.RCONST(0.0),nArgs1 + nDerArgs - 1, varExpListTotal ,DAE.RCONST(0.0));
        varExpList1Added = List.replaceAtWithFill(DAE.RCONST(1.0),nArgs1 + nDerArgs - (nArgs2 + 1), varExpList1Added,DAE.RCONST(0.0));
        derFun = DAE.CALL(derFname, varExpList1Added, attr);
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
      DAE.CallAttributes attr;
    case ({}, _, _, _) then (DAE.RCONST(0.0));
    case (currVar::restVar, currDerVar::restDerVar, inState, functionCall as DAE.CALL(path=fname, expLst=varExpListTotal, attr=attr))
      equation
        e = partialNumericalDifferentiation(restVar, restDerVar, inState, functionCall);
        absCurr = DAE.LBINARY(DAE.RELATION(currVar,DAE.GREATER(DAE.ET_REAL()),DAE.RCONST(1e-8),-1,NONE()),DAE.OR(DAE.ET_BOOL()),DAE.RELATION(currVar,DAE.LESS(DAE.ET_REAL()),DAE.RCONST(-1e-8),-1,NONE()));
        delta = DAE.IFEXP( absCurr, DAE.BINARY(currVar,DAE.MUL(DAE.ET_REAL()),DAE.RCONST(1e-8)), DAE.RCONST(1e-8));
        nArgs1 = listLength(varExpListTotal);
        nArgs2 = listLength(restVar);
        varExpListHAdded = List.replaceAtWithFill(DAE.BINARY(currVar, DAE.ADD(DAE.ET_REAL()),delta),nArgs1-(nArgs2+1), varExpListTotal,DAE.RCONST(0.0));
        derFun = DAE.BINARY(DAE.BINARY(DAE.CALL(fname, varExpListHAdded, attr), DAE.SUB(DAE.ET_REAL()), DAE.CALL(fname, varExpListTotal, attr)), DAE.DIV(DAE.ET_REAL()), delta);
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
      //derivedStatements1 = List.threadMap3(derivedLHS, derivedRHS, createDiffStatements, type_, currStatement, source);
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
      dxlist = List.threadMap3(dxlist1,dxlist2,mergeBin,op,e1,e2);
    then dxlist;
    
    // uniary
    case(DAE.UNARY(operator=op, exp=e1), xlist, functions, inputVars, paramVars, stateVars, knownVars,  allVars, diffVars) equation
      dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars,  allVars, diffVars);
      dxlist = List.map1(dxlist1,mergeUn,op);
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
        dxlist = List.map2(dxlist1,mergeCall,e1,e);
    then dxlist;
      
    // extern functions (analytical and numeric)
    case (e as DAE.CALL(path=fname, expLst=expList1), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars)
      equation
       dxlist = createDiffListMeta(e,xlist,diffNumCall, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars)));
    then dxlist;
    
    // cast
    case (DAE.CAST(ty=et, exp=e1), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars) equation
      dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars);
      dxlist = List.map1(dxlist1,mergeCast,et);
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
      dxlist = List.threadMap1(dxlist1,dxlist2,mergeIf,e);
    then dxlist;

    /*  
    case (DAE.ARRAY(ty = et,scalar = b,array = expList1), x, functions, inputVars, paramVars, stateVars, knownVars, diffVars)
      equation
        expList2 = List.map7(expList1, differentiateWithRespectToX, x, functions, inputVars, paramVars, stateVars, knownVars, diffVars);
      then
        DAE.ARRAY(et,b,expList2);
    
    case (DAE.TUPLE(PR = expList1), x, functions, inputVars, paramVars, stateVars, knownVars, diffVars)
      equation
        expList2 = List.map7(expList1, differentiateWithRespectToX, x, functions, inputVars, paramVars, stateVars, knownVars, diffVars);
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
     DAE.ComponentRef diff_cref;
     list<DAE.ComponentRef> rest;
     list<DAE.Exp> res;
     Option<Type_a> typea;
     String str;
    
     case(e, {}, _, _) then {};
     
     case(e, diff_cref::rest, func, typea)
       equation
         e1 = func((e, diff_cref, typea));
         res = createDiffListMeta(e,rest,func,typea);
       then e1::res;

     case(e, diff_cref::rest, _, _)
       equation
         str = "BackendDAEOptimize.createDiffListMeta failed: " +& ExpressionDump.printExpStr(e) +& " | " +& ComponentReference.printComponentRefStr(diff_cref);
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
    list<Boolean> b_lst;
    Integer i;
    
    // d(discrete)/d(x) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars))))
      equation
      ({v1 as BackendDAE.VAR(varKind = BackendDAE.DISCRETE())}, _) = BackendVariable.getVar(cref, allVars);
    then DAE.RCONST(0.0);    

    // d(x)/d(x)
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars))))
      equation
      b_lst = List.map1(diffVars,ComponentReference.crefEqual,cref);
      true = Util.boolOrList(b_lst);
      cref_ = differentiateVarWithRespectToX(cref, cref);
    then DAE.CREF(cref_, et);

    // d(state)/d(x) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars))))
      equation
      ({v1}, _) = BackendVariable.getVar(cref, stateVars);
    then DAE.RCONST(0.0);

    // d(input)/d(x) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars))))
      equation
      ({v1}, _) = BackendVariable.getVar(cref, inputVars);
    then DAE.RCONST(0.0);

    // d(parameter)/d(x) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars))))
      equation
      ({v1}, _) = BackendVariable.getVar(cref, paramVars);
    then DAE.RCONST(0.0);
      
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
      //x = DAE.CREF_IDENT("pDERdummy",DAE.ET_REAL(),{});
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
    DAE.CallAttributes attr;
    //Option<tuple<DAE.FunctionTree, list<BackendDAE.Var>, list<BackendDAE.Var>, list<BackendDAE.Var>, list<BackendDAE.Var>, list<BackendDAE.Var>>> inTpl;
    // extern functions (analytical)
    case ((e as DAE.CALL(path=fname, expLst=expList1), x, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars))))
      equation
        nArgs = listLength(expList1);
        (DAE.FUNCTION_DER_MAPPER(derivativeFunction=derFname,conditionRefs=conditions), tp) = Derive.getFunctionMapper(fname, functions);
        expList2 = deriveExpListwrtstate(expList1, nArgs, conditions, x, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars);
        e1 = partialAnalyticalDifferentiation(expList1, expList2, e, derFname, listLength(expList2));
        (e1,_) = ExpressionSimplify.simplify(e1);
      then e1;
    case ((e as DAE.CALL(path=fname, expLst=expList1), x, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars))))
      equation
        //(SOME((functions, inputVars, paramVars, stateVars, knownVars, diffVars))) = inTpl;
        nArgs = listLength(expList1);
        expList2 = deriveExpListwrtstate2(expList1, nArgs, x, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars);
        e1 = partialNumericalDifferentiation(expList1, expList2, x, e);
        (e1,_) = ExpressionSimplify.simplify(e1);
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
        e = DAE.BINARY(inExp1, DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("cos"),{inExp2},DAE.callAttrBuiltinReal));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    // cos(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("cos")))
      equation
        e = DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()), DAE.BINARY(inExp1,DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("sin"),{inExp2},DAE.callAttrBuiltinReal)));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    // ln(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("log")))
      equation
        e = DAE.BINARY(inExp1, DAE.DIV(DAE.ET_REAL()), inExp2);
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    // log10(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("log10")))          
      equation
        e = DAE.BINARY(inExp1, DAE.DIV(DAE.ET_REAL()), DAE.BINARY(inExp2, DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("log"),{DAE.RCONST(10.0)},DAE.callAttrBuiltinReal)));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    // exp(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("exp")))    
      equation
        e = DAE.BINARY(inExp1,DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("exp"),{inExp2},DAE.callAttrBuiltinReal));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    // sqrt(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("sqrt")))    
      equation
        e = DAE.BINARY(
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{inExp2},DAE.callAttrBuiltinReal))),DAE.MUL(DAE.ET_REAL()),inExp1);
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
   // abs(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("abs")))          
      equation
        e = DAE.IFEXP(DAE.RELATION(inExp2,DAE.GREATEREQ(DAE.ET_REAL()),DAE.RCONST(0.0),-1,NONE()), inExp1, DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),inExp1));
        (e,_) = ExpressionSimplify.simplify(e);
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
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    case (inExp1,inExp2,inOp as DAE.SUB(_), _, _)
      equation
        e = DAE.BINARY(inExp1,inOp,inExp2);
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    case (inExp1,inExp2,DAE.MUL(et),inOrgExp1,inOrgExp2)
      equation
        e = DAE.BINARY(DAE.BINARY(inExp1, DAE.MUL(et), inOrgExp2), DAE.ADD(et), DAE.BINARY(inOrgExp1, DAE.MUL(et), inExp2));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    case (inExp1,inExp2,DAE.DIV(et),inOrgExp1,inOrgExp2)
      equation
        e = DAE.BINARY(DAE.BINARY(DAE.BINARY(inExp1, DAE.MUL(et), inOrgExp2), DAE.SUB(et), DAE.BINARY(inOrgExp1, DAE.MUL(et), inExp2)), DAE.DIV(et), DAE.BINARY(inOrgExp2, DAE.MUL(et), inOrgExp2));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    case (inExp1,inExp2,inOp as DAE.POW(et),inOrgExp1,inOrgExp2)
      equation
        true = Expression.isConst(inOrgExp2);
        e = DAE.BINARY(inExp1, DAE.MUL(et), DAE.BINARY(inOrgExp2, DAE.MUL(et), DAE.BINARY(inOrgExp1, DAE.POW(et), DAE.BINARY(inOrgExp2, DAE.SUB(et), DAE.RCONST(1.0)))));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    case (inExp1,inExp2,inOp as DAE.POW(et),inOrgExp1,inOrgExp2)
      equation
        z1 = DAE.BINARY(inExp1, DAE.DIV(et), inOrgExp1);
        z1 = DAE.BINARY(inOrgExp2, DAE.MUL(et), z1);
        z2 = DAE.CALL(Absyn.IDENT("log"), {inOrgExp1}, DAE.callAttrBuiltinReal);
        z2 = DAE.BINARY(inExp2, DAE.MUL(et), z2);
        z1 = DAE.BINARY(z1, DAE.ADD(et), z2);
        z2 = DAE.BINARY(inOrgExp1, DAE.POW(et), inOrgExp2);
        z1 = DAE.BINARY(z1, DAE.MUL(et), z2);
        (e,_) = ExpressionSimplify.simplify(z1);
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
        (e,_) = ExpressionSimplify.simplify(e);
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
        (e,_) = ExpressionSimplify.simplify(e);
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

/* Parallel backend stuff  */

public function collapseIndependentBlocks
  "Finds independent partitions of the equation system by "
  input BackendDAE.BackendDAE dlow;
  input DAE.FunctionTree ftree;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match (dlow,ftree)
    local
      BackendDAE.IncidenceMatrix m,mT;
      array<Integer> ixs,ixsT;
      list<Integer> lst,lst2;
      Boolean b;
      String str;
      list<String> strs;
      Integer i,i2;
      BackendDAE.EqSystem syst;
      list<BackendDAE.EqSystem> systs;
      BackendDAE.Shared shared;
    case (BackendDAE.DAE(systs,shared),ftree)
      equation
        // We can use listReduce as if there is no eq-system something went terribly wrong
        syst = List.reduce(systs,mergeIndependentBlocks);
      then BackendDAE.DAE({syst},shared);
  end match;
end collapseIndependentBlocks;

protected function mergeIndependentBlocks
  input BackendDAE.EqSystem syst1;
  input BackendDAE.EqSystem syst2;
  output BackendDAE.EqSystem syst;
protected
  BackendDAE.Variables vars,vars1,vars2;
  BackendDAE.EquationArray eqs,eqs1,eqs2;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars1,orderedEqs=eqs1) := syst1;
  BackendDAE.EQSYSTEM(orderedVars=vars2,orderedEqs=eqs2) := syst2;
  vars := BackendVariable.addVars(BackendDAEUtil.varList(vars2),vars1);
  eqs := BackendEquation.addEquations(BackendDAEUtil.equationList(eqs2),eqs1);
  syst := BackendDAE.EQSYSTEM(vars,eqs,NONE(),NONE(),BackendDAE.NO_MATCHING());
end mergeIndependentBlocks;

public function partitionIndependentBlocks
  "Finds independent partitions of the equation system by "
  input BackendDAE.BackendDAE dlow;
  input DAE.FunctionTree ftree;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match (dlow,ftree)
    local
      BackendDAE.IncidenceMatrix m,mT;
      array<Integer> ixs,ixsT;
      list<Integer> lst,lst2;
      Boolean b;
      String str;
      list<String> strs;
      Integer i,i2;
      BackendDAE.EqSystem syst;
      list<BackendDAE.EqSystem> systs;
      BackendDAE.Shared shared;
    case (BackendDAE.DAE({syst},shared),ftree)
      equation
        (systs,shared) = partitionIndependentBlocksHelper(syst,shared,ftree,Error.getNumErrorMessages());
      then BackendDAE.DAE(systs,shared); // TODO: Add support for partitioned systems of equations
  end match;
end partitionIndependentBlocks;

protected function partitionIndependentBlocksHelper
  "Finds independent partitions of the equation system by "
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input DAE.FunctionTree ftree;
  input Integer i;
  output list<BackendDAE.EqSystem> systs;
  output BackendDAE.Shared oshared;
algorithm
  (systs,oshared) := matchcontinue (syst,shared,ftree,i)
    local
      BackendDAE.IncidenceMatrix m,mT;
      array<Integer> ixs,ixsT;
      list<Integer> lst,lst2;
      Boolean b;
      String str;
      list<String> strs;
      Integer i,i2;
      BackendDAE.Shared shared;
    case (syst,shared,ftree,_)
      equation
        // print("partitionIndependentBlocks: TODO: Implement me\n");
        (syst,m,mT) = BackendDAEUtil.getIncidenceMatrixfromOption(syst,shared);
        ixs = arrayCreate(arrayLength(m),0);
        // ixsT = arrayCreate(arrayLength(mT),0);
        i = partitionIndependentBlocks0(arrayLength(m),0,mT,m,ixs);
        // i2 = partitionIndependentBlocks0(arrayLength(mT),0,mT,m,ixsT);
        b = i > 1;
        // Debug.bcall(b,BackendDump.dump,BackendDAE.DAE({syst},shared));
        // printPartition(b,ixs);
        systs = Debug.bcallret4(b,partitionIndependentBlocksSplitBlocks,i,syst,ixs,mT,{syst});
      then (systs,shared);
    else
      equation
        Error.assertion(not (i==Error.getNumErrorMessages()),"BackendDAEOptimize.partitionIndependentBlocks failed without good error message",Absyn.dummyInfo);
      then fail();
  end matchcontinue;
end partitionIndependentBlocksHelper;

protected function partitionIndependentBlocksSplitBlocks
  "Partitions the independent blocks into list<array<...>> by first constructing an array<list<...>> structure for the algorithm complexity"
  input Integer n;
  input BackendDAE.EqSystem syst;
  input array<Integer> ixs;
  input BackendDAE.IncidenceMatrix mT;
  output list<BackendDAE.EqSystem> systs;
algorithm
  systs := match (n,syst,ixs,mT)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray arr;
      array<list<BackendDAE.Equation>> ea;
      array<list<BackendDAE.Var>> va;
      list<list<BackendDAE.Equation>> el;
      list<list<BackendDAE.Var>> vl;
      Integer i1,i2;
      String s1,s2;
    case (n,syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=arr),ixs,mT)
      equation
        ea = arrayCreate(n,{});
        va = arrayCreate(n,{});
        i1 = BackendDAEUtil.equationSize(arr);
        i2 = BackendVariable.numVariables(vars);
        s1 = intString(i1);
        s2 = intString(i2);
        Error.assertionOrAddSourceMessage(i1 == i2, Error.OVERDET_EQN_SYSTEM, {s1,s2}, Absyn.dummyInfo);
        
        partitionEquations(BackendDAEUtil.equationSize(arr),arr,ixs,ea);
        partitionVars(BackendDAEUtil.equationSize(arr),arr,vars,ixs,mT,va);
        el = arrayList(ea);
        vl = arrayList(va);
        (systs,true) = List.threadMapFold(el,vl,createEqSystem,true);
      then systs;
  end match;
end partitionIndependentBlocksSplitBlocks;

protected function createEqSystem
  input list<BackendDAE.Equation> el;
  input list<BackendDAE.Var> vl;
  input Boolean success;
  output BackendDAE.EqSystem syst;
  output Boolean osuccess;
protected
  BackendDAE.EquationArray arr;
  BackendDAE.Variables vars;
  Integer i1,i2;
  String s1,s2,s3,s4;
  list<String> crs;
algorithm
  vars := BackendDAEUtil.listVar(vl);
  arr := BackendDAEUtil.listEquation(el);
  i1 := BackendDAEUtil.equationSize(arr);
  i2 := BackendVariable.numVariables(vars);
  s1 := intString(i1);
  s2 := intString(i2);
  crs := Debug.bcallret3(i1<>i2,List.mapMap,vl,BackendVariable.varCref,ComponentReference.printComponentRefStr,{});
  s3 := stringDelimitList(crs,"\n");
  s4 := Debug.bcallret1(i1<>i2,BackendDump.dumpEqnsStr,el,"");
  // Can this even be triggered? We check that all variables are defined somewhere, so everything should be balanced already?
  Debug.bcall3(i1<>i2,Error.addSourceMessage,Error.IMBALANCED_EQUATIONS,{s1,s2,s3,s4},Absyn.dummyInfo);
  syst := BackendDAE.EQSYSTEM(vars,arr,NONE(),NONE(),BackendDAE.NO_MATCHING());
  osuccess := success and i1==i2;
end createEqSystem;

protected function partitionEquations
  input Integer n;
  input BackendDAE.EquationArray arr;
  input array<Integer> ixs;
  input array<list<BackendDAE.Equation>> ea;
algorithm
  _ := match (n,arr,ixs,ea)
    local
      Integer ix;
      list<BackendDAE.Equation> lst;
      BackendDAE.Equation eq;
    case (0,_,_,_) then ();
    case (n,arr,ixs,ea)
      equation
        ix = ixs[n];
        lst = ea[ix];
        eq = BackendDAEUtil.equationNth(arr,n-1);
        lst = eq::lst;
        // print("adding eq " +& intString(n) +& " to group " +& intString(ix) +& "\n");
        _ = arrayUpdate(ea,ix,lst);
        partitionEquations(n-1,arr,ixs,ea);
      then ();
  end match;
end partitionEquations;

protected function partitionVars
  input Integer n;
  input BackendDAE.EquationArray arr;
  input BackendDAE.Variables vars;
  input array<Integer> ixs;
  input BackendDAE.IncidenceMatrix mT;
  input array<list<BackendDAE.Var>> va;
algorithm
  _ := match (n,arr,vars,ixs,mT,va)
    local
      Integer ix,eqix;
      list<BackendDAE.Var> lst;
      BackendDAE.Var v;
      Boolean b;
      DAE.ComponentRef cr;
      String name;
      Absyn.Info info;
    case (0,_,_,_,_,_) then ();
    case (n,arr,vars,ixs,mT,va)
      equation
        v = BackendVariable.getVarAt(vars,n);
        cr = BackendVariable.varCref(v);
        // Select any equation that could define this variable
        b = not List.isEmpty(mT[n]);
        name = Debug.bcallret1(not b,ComponentReference.printComponentRefStr,cr,"");
        info = DAEUtil.getElementSourceFileInfo(BackendVariable.getVarSource(v));
        Error.assertionOrAddSourceMessage(b,Error.EQUATIONS_VAR_NOT_DEFINED,{name},info);
        // print("adding var " +& intString(n) +& " to group ???\n");
        eqix::_ = mT[n];
        eqix = intAbs(eqix);
        // print("var " +& intString(n) +& " has eq " +& intString(eqix) +& "\n");
        // That's the index of the indep.system
        ix = ixs[eqix];
        lst = va[ix];
        lst = v::lst;
        // print("adding var " +& intString(n) +& " to group " +& intString(ix) +& " (comes from eq: "+& intString(eqix) +&")\n");
        _ = arrayUpdate(va,ix,lst);
        partitionVars(n-1,arr,vars,ixs,mT,va);
      then ();
  end match;
end partitionVars;

protected function partitionIndependentBlocks0
  input Integer n;
  input Integer n2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ixs;
  output Integer on;
algorithm
  on := match (n,n2,m,mT,ixs)
    local
      Boolean b;
    case (0,n2,_,_,_) then n2;
    case (n,n2,m,mT,ixs)
      equation
        b = partitionIndependentBlocks1(n,n2+1,m,mT,ixs);
      then partitionIndependentBlocks0(n-1,Util.if_(b,n2+1,n2),m,mT,ixs);
  end match;
end partitionIndependentBlocks0;

protected function partitionIndependentBlocks1
  input Integer ix;
  input Integer n;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ixs;
  output Boolean ochange;
algorithm
  ochange := partitionIndependentBlocks2(ixs[ix] == 0,ix,n,m,mT,ixs);
end partitionIndependentBlocks1;

protected function partitionIndependentBlocks2
  input Boolean b;
  input Integer ix;
  input Integer n;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ixs;
  output Boolean change;
algorithm
  change := match (b,ix,n,m,mT,ixs)
    local
      Integer i;
      list<Integer> lst;
      list<list<Integer>> lsts;
    case (false,ix,n,m,mT,ixs) then false;
    case (true,ix,n,m,mT,ixs)
      equation
        // i = ixs[ix];
        // print(intString(ix) +& "; update crap\n");
        // print("mark\n");
        ixs = arrayUpdate(ixs,ix,n);
        // print("mark OK\n");
        lst = List.map(mT[ix],intAbs);
        // print(stringDelimitList(List.map(lst,intString),",") +& "\n");
        // print("len:" +& intString(arrayLength(m)) +& "\n");
        lsts = List.map1r(lst,arrayGet,m);
        // print("arrayNth OK\n");
        lst = List.map(List.flatten(lsts),intAbs);
        // print(stringDelimitList(List.map(lst,intString),",") +& "\n");
        // print("lst get\n");
        _ = List.map4(lst,partitionIndependentBlocks1,n,m,mT,ixs);
      then true;
  end match;
end partitionIndependentBlocks2;

protected function arrayUpdateForPartition
  input Integer ix;
  input array<Integer> ixs;
  input Integer val;
  output array<Integer> oixs;
algorithm
  // print("arrayUpdate("+&intString(ix+1)+&","+&intString(val)+&")\n");
  oixs := arrayUpdate(ixs,ix+1,val);
end arrayUpdateForPartition;

protected function printPartition
  input Boolean b;
  input array<Integer> ixs;
algorithm
  _ := match (b,ixs)
    case (true,ixs)
      equation
        print("Got partition!\n");
        print(stringDelimitList(List.map(arrayList(ixs), intString), ","));
        print("\n");
      then ();
    else ();
  end match;
end printPartition;

public function residualForm
  "Puts equations like x=y in the form of 0=x-y"
  input BackendDAE.BackendDAE dlow;
  input DAE.FunctionTree funcs;
  output BackendDAE.BackendDAE odlow;
algorithm
  odlow := BackendDAEUtil.mapEqSystem1(dlow,residualForm1,1);
end residualForm;

protected function residualForm1
  "Puts equations like x=y in the form of 0=x-y"
  input BackendDAE.EqSystem syst;
  input Integer i;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
protected
  BackendDAE.EquationArray eqs;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs=eqs) := syst;
  (_,_) := BackendEquation.traverseBackendDAEEqnsWithUpdate(eqs, residualForm2, 1);
  osyst := syst;
  oshared := shared;
end residualForm1;

protected function residualForm2
  input tuple<BackendDAE.Equation,Integer> tpl;
  output tuple<BackendDAE.Equation,Integer> otpl;
algorithm
  otpl := matchcontinue tpl
    local
      tuple<BackendDAE.Equation,Integer> ntpl;
      Boolean keep;
      DAE.Exp e1,e2,e;
      DAE.ElementSource source;
      DAE.ExpType et;
      Integer i;
    case ((BackendDAE.EQUATION(e1,e2,source),i))
      equation
        // This is ok, because EQUATION is not an array equation :D
        DAE.ET_REAL() = Expression.typeof(e1);
        false = Expression.isZero(e1) or Expression.isZero(e2);
        e = DAE.BINARY(e1,DAE.SUB(DAE.ET_REAL()),e2);
        (e,_) = ExpressionSimplify.simplify(e);
        source = DAEUtil.addSymbolicTransformation(source, DAE.OP_RESIDUAL(e1,e2,e));
        ntpl = (BackendDAE.EQUATION(DAE.RCONST(0.0),e,source),i);
      then ntpl;
    else tpl;
  end matchcontinue;
end residualForm2;

end BackendDAEOptimize;
