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
" file:        BackendDAEOptimize.mo
  package:     BackendDAEOptimize
  description: BackendDAEOPtimize contains functions that do some kind of
               optimazation on the BackendDAE datatype:
               - removing simpleEquations
               - Tearing/Relaxation
               - Linearization
               - Inline Integration
               - and so on ... 
               
  RCS: $Id$"

public import Absyn;
public import BackendDAE;
public import DAE;
public import Env;
public import HashTable2;
//public import IndexReduction;

protected import BackendDAETransform;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVarTransform;
protected import BackendVariable;
protected import BaseHashTable;
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
protected import Flags;
protected import Graph;
protected import Inline;
protected import List;
protected import Matching;
protected import SCode;
protected import System;
protected import Util;
protected import Values;
protected import ValuesUtil;




/*
 * inline arrayeqns stuff
 *
 */
public function inlineArrayEqnPast "function inlineArrayEqnPast
  autor: Frenkel TUD 2011-3"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
protected
  Option<BackendDAE.IncidenceMatrix> om,omT;
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
algorithm
  (outDAE,outRunMatching) := BackendDAEUtil.mapEqSystemAndFold(inDAE,inlineArrayEqn1,false);
end inlineArrayEqnPast;

public function inlineArrayEqn "function inlineArrayEqn
  autor: Frenkel TUD 2011-3"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE,_) := BackendDAEUtil.mapEqSystemAndFold(inDAE,inlineArrayEqn1,false);
end inlineArrayEqn;

public function inlineArrayEqnShared "function inlineArrayEqnShared"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match(inDAE)
    local
      BackendDAE.Variables ordvars,knvars,exobj,knvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray remeqns,inieqns,eqns1,inieqns1,remeqns1,eqns2;
      array<DAE.Constraint> constrs;
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcTree;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      list<BackendDAE.WhenClause> whenClauseLst,whenClauseLst1;
      list<BackendDAE.ZeroCrossing> zeroCrossingLst;
      BackendDAE.BackendDAEType btp;
      BackendDAE.EqSystems systs,systs1;
      BackendDAE.Shared shared;
      list<BackendDAE.Var> ordvarslst;
      list<BackendDAE.Equation> eqnslst;
    case (_) then inDAE;
    case (BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,cache,env,funcTree,BackendDAE.EVENT_INFO(whenClauseLst,zeroCrossingLst),eoc,btp,symjacs)))
      equation
        eqnslst = BackendDAEUtil.equationList(inieqns);
        eqnslst = getScalarArrayEqns(eqnslst,{});
        inieqns = BackendDAEUtil.listEquation(eqnslst);
        eqnslst = BackendDAEUtil.equationList(remeqns);
        eqnslst = getScalarArrayEqns(eqnslst,{});
        remeqns = BackendDAEUtil.listEquation(eqnslst);
      then 
        BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,cache,env,funcTree,BackendDAE.EVENT_INFO(whenClauseLst,zeroCrossingLst),eoc,btp,symjacs));
  end match;
end inlineArrayEqnShared;

protected function inlineArrayEqn1 "function: inlineArrayEqn1
  autor: Frenkel TUD 2011-5"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared,Boolean> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> osharedOptimized;
algorithm
  (osyst,osharedOptimized) := matchcontinue (isyst,sharedOptimized)
    local
      Boolean b1,b2,b;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.Equation> eqnslst;
      Integer oldsize,newsize;
      BackendDAE.Matching matching;
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
    case (syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,m=m,mT=mT,matching=matching),(shared,_))
      equation
        eqnslst = BackendDAEUtil.equationList(eqns);
        oldsize = listLength(eqnslst);
        eqnslst = getScalarArrayEqns(eqnslst,{});
        newsize = listLength(eqnslst);
        true = intGt(newsize,oldsize);
        eqns = BackendDAEUtil.listEquation(eqnslst);
      then
        (BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING()),(shared,true));
    else
      then
        (isyst,sharedOptimized);
  end matchcontinue;
end inlineArrayEqn1;

protected function getScalarArrayEqns
  input list<BackendDAE.Equation> iEqsLst;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> oEqsLst;
algorithm
  oEqsLst := match(iEqsLst,iAcc)
    local
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns,eqns1;
    case ({},_) then listReverse(iAcc);
    case (eqn::eqns,_)
     equation
       eqns1 = getScalarArrayEqns1(eqn,iAcc);
     then
       getScalarArrayEqns(eqns,eqns1);
  end match;
end getScalarArrayEqns;

public function getScalarArrayEqns1"
  author: Frenkel TUD 2012-06"
  input  BackendDAE.Equation iEqn;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> outEqsLst;
algorithm
  outEqsLst := matchcontinue (iEqn,iAcc)
    local
      DAE.ElementSource source;
      DAE.Exp e1,e2,e1_1,e2_1;
      list<DAE.Exp> ea1,ea2;
    case (BackendDAE.ARRAY_EQUATION(left=e1,right=e2,source=source),_)
      equation
        true = Expression.isArray(e1) or Expression.isMatrix(e1);
        true = Expression.isArray(e2) or Expression.isMatrix(e2);
        ea1 = Expression.flattenArrayExpToList(e1);
        ea2 = Expression.flattenArrayExpToList(e2);
      then
        generateScalarArrayEqns2(ea1,ea2,source,iAcc);
    case (BackendDAE.ARRAY_EQUATION(left=e1 as DAE.CREF(componentRef =_),right=e2,source=source),_)
      equation
        true = Expression.isArray(e2) or Expression.isMatrix(e2);
        ((e1_1,(_,_))) = BackendDAEUtil.extendArrExp((e1,(NONE(),false)));
        ea1 = Expression.flattenArrayExpToList(e1_1);
        ea2 = Expression.flattenArrayExpToList(e2);
      then
        generateScalarArrayEqns2(ea1,ea2,source,iAcc);
    case (BackendDAE.ARRAY_EQUATION(left=e1,right=e2 as DAE.CREF(componentRef =_),source=source),_)
      equation
        true = Expression.isArray(e1) or Expression.isMatrix(e1);
        ((e2_1,(_,_))) = BackendDAEUtil.extendArrExp((e2,(NONE(),false)));
        ea1 = Expression.flattenArrayExpToList(e1);
        ea2 = Expression.flattenArrayExpToList(e2_1);
      then
        generateScalarArrayEqns2(ea1,ea2,source,iAcc);
    case (BackendDAE.ARRAY_EQUATION(left=e1 as DAE.CREF(componentRef =_),right=e2 as DAE.CREF(componentRef =_),source=source),_)
      equation
        ((e1_1,(_,_))) = BackendDAEUtil.extendArrExp((e1,(NONE(),false)));
        ((e2_1,(_,_))) = BackendDAEUtil.extendArrExp((e2,(NONE(),false)));
        ea1 = Expression.flattenArrayExpToList(e1_1);
        ea2 = Expression.flattenArrayExpToList(e2_1);
      then
        generateScalarArrayEqns2(ea1,ea2,source,iAcc);
    case (_,_) then iEqn::iAcc;
  end matchcontinue;
end getScalarArrayEqns1;

protected function generateScalarArrayEqns2 "function generateScalarArrayEqns2
  author: Frenkel TUD 2012-06"
  input list<DAE.Exp> iE1lst;
  input list<DAE.Exp> iE2lst;
  input DAE.ElementSource source;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> oEqns;
algorithm
  oEqns := match(iE1lst,iE2lst,source,iAcc)
    local
      DAE.Exp e1,e2;
      list<DAE.Exp> e1lst,e2lst;
    case ({},{},_,_) then iAcc;
    case (e1::e1lst,e2::e2lst,_,_)
      then
        generateScalarArrayEqns2(e1lst,e2lst,source,BackendDAE.EQUATION(e1,e2,source)::iAcc);
  end match;
end generateScalarArrayEqns2;




/*
 * inline functions stuff
 *
 */
public function lateInlineFunction "function lateInlineFunction"
    input BackendDAE.BackendDAE inDAE;
    output BackendDAE.BackendDAE outDAE;
    output Boolean outRunMatching;
algorithm
  outDAE := Inline.inlineCalls({DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()},inDAE);
  outRunMatching := true;
end lateInlineFunction;




/*
 * remove simply equations stuff
 *
 */
/*
public function removeSimpleEquationsFastPastNew
"function removeSimpleEquationsFastPast"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
protected
  BackendVarTransform.VariableReplacements repl,repl1;
algorithm
  repl := BackendVarTransform.emptyReplacements();
  (outDAE,(repl1,outRunMatching)) := BackendDAEUtil.mapEqSystemAndFold(inDAE,removeSimpleEquationsFast1New,(repl,false));
  outDAE := removeSimpleEquationsShared(outRunMatching,outDAE,repl1);
  outDAE := BackendDAEUtil.mapEqSystem(outDAE,BackendDAEUtil.getIncidenceMatrixfromOptionForMapEqSystem);
  // until remove simple equations does not update assignments and comps  
end removeSimpleEquationsFastPastNew;

public function removeSimpleEquationsFastNew
"function: removeSimpleEquationsFast
  autor: Frenkel TUD 2012-03
  This function moves simple equations on the form a=b and a=const and a=f(not time)
  in BackendDAE.BackendDAE to get speed up. The functions traverses the equation system
  only once and does not jump back if a simple equation is found, hence not alle simple
  equations will be detected."
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE odae;
protected
  BackendVarTransform.VariableReplacements repl,repl1;
  Boolean b;
algorithm
  repl := BackendVarTransform.emptyReplacements();
  (odae,(repl1,b)) := BackendDAEUtil.mapEqSystemAndFold(dae,removeSimpleEquationsFast1New,(repl,false));
  odae := removeSimpleEquationsShared(b,odae,repl1);
end removeSimpleEquationsFastNew;

protected function removeSimpleEquationsFast1New
"function: removeSimpleEquationsFast1
  autor: Frenkel TUD 2012-03
  This function moves simple equations on the form a=b and a=const and a=f(not time)
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.EqSystem isyst; 
  input tuple<BackendDAE.Shared,tuple<BackendVarTransform.VariableReplacements,Boolean>> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,tuple<BackendVarTransform.VariableReplacements,Boolean>> osharedOptimized;
algorithm
  (osyst,osharedOptimized):=
  match (isyst,sharedOptimized)
    local
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.BinTree movedVars,movedAVars;
      list<Integer> meqns,deqns;
      Boolean b,b1;
      BackendDAE.Shared shared;
      HashTable2.HashTable derrepl,derrepl1;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.Equation> eqnslst;
      
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns),(shared,(repl,b1)))
      equation
        derrepl = HashTable2.emptyHashTable();
        // check equations
       (eqnslst,shared,repl,derrepl,   = BackendEquation.traverseBackendDAEEqns(eqns, removeSimpleEquationsFastFinderNew, ())
       eqn = BackendDAEUtil.
       

        ((syst,shared,repl_1,derrepl1,deqns,movedVars,movedAVars,meqns,b)) = 
          traverseEquations(1,n,removeSimpleEquationsFastFinder,
            (syst,shared,repl,derrepl,{},BackendDAE.emptyBintree,BackendDAE.emptyBintree,{},false));       
        // replace der(x)=dx 
        // replace vars in arrayeqns and algorithms, move vars to knvars and aliasvars, remove eqns
      then (BackendDAE.EQSYSTEM(vars,eqns,NONE,NONE,BackendDAE.NO_MATCHING()),(shared,(repl,b or b1)));
  end match;
end removeSimpleEquationsFast1New;
*/

public function removeSimpleEquationsFastPast "function removeSimpleEquationsFastPast"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
protected
  BackendVarTransform.VariableReplacements repl,repl1;
algorithm
  repl := BackendVarTransform.emptyReplacements();
  (outDAE,(repl1,outRunMatching)) := BackendDAEUtil.mapEqSystemAndFold(inDAE,removeSimpleEquationsFast1,(repl,false));
  outDAE := removeSimpleEquationsShared(outRunMatching,outDAE,repl1);
  outDAE := BackendDAEUtil.mapEqSystem(outDAE,BackendDAEUtil.getIncidenceMatrixfromOptionForMapEqSystem);
  // until remove simple equations does not update assignments and comps  
end removeSimpleEquationsFastPast;

public function removeSimpleEquationsFast
"function: removeSimpleEquationsFast
  autor: Frenkel TUD 2012-03
  This function moves simple equations on the form a=b and a=const and a=f(not time)
  in BackendDAE.BackendDAE to get speed up. The functions traverses the equation system
  only once and does not jump back if a simple equation is found, hence not alle simple
  equations will be detected."
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE odae;
protected
  BackendVarTransform.VariableReplacements repl,repl1;
  Boolean b;
algorithm
  repl := BackendVarTransform.emptyReplacements();
  (odae,(repl1,b)) := BackendDAEUtil.mapEqSystemAndFold(dae,removeSimpleEquationsFast1,(repl,false));
  odae := removeSimpleEquationsShared(b,odae,repl1);
end removeSimpleEquationsFast;

protected function removeSimpleEquationsFast1
"function: removeSimpleEquationsFast1
  autor: Frenkel TUD 2012-03
  This function moves simple equations on the form a=b and a=const and a=f(not time)
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.EqSystem isyst; 
  input tuple<BackendDAE.Shared,tuple<BackendVarTransform.VariableReplacements,Boolean>> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,tuple<BackendVarTransform.VariableReplacements,Boolean>> osharedOptimized;
algorithm
  (osyst,osharedOptimized):=
  match (isyst,sharedOptimized)
    local
      DAE.FunctionTree funcs;
      BackendVarTransform.VariableReplacements repl,repl_1;
      BackendDAE.BinTree movedVars,movedAVars;
      list<Integer> meqns,deqns;
      Boolean b,b1;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      HashTable2.HashTable derrepl,derrepl1;
      Integer n;
      
    case (syst,(shared,(repl,b1)))
      equation
        derrepl = HashTable2.emptyHashTable();
        // check equations
        n = BackendDAEUtil.equationArraySizeDAE(syst);
        ((syst,shared,repl_1,derrepl1,deqns,movedVars,movedAVars,meqns,b)) = 
          traverseEquations(1,n,removeSimpleEquationsFastFinder,
            (syst,shared,repl,derrepl,{},BackendDAE.emptyBintree,BackendDAE.emptyBintree,{},false));
        // replace der(x)=dx 
        (syst,shared) = replaceDerEquations(deqns,syst,shared,derrepl1);
        // replace vars in arrayeqns and algorithms, move vars to knvars and aliasvars, remove eqns
        (syst,shared) = removeSimpleEquations2(b,syst,shared,repl_1,movedVars,movedAVars,meqns);
      then (syst,(shared,(repl_1,b or b1)));
  end match;
end removeSimpleEquationsFast1;

protected function removeSimpleEquationsFastFinder
"autor: Frenkel TUD 2012-03"
 input tuple<Integer,tuple<BackendDAE.EqSystem,BackendDAE.Shared,BackendVarTransform.VariableReplacements,HashTable2.HashTable,list<Integer>,BackendDAE.BinTree,BackendDAE.BinTree,list<Integer>,Boolean>> inTpl;
 output tuple<BackendDAE.EqSystem,BackendDAE.Shared,BackendVarTransform.VariableReplacements,HashTable2.HashTable,list<Integer>,BackendDAE.BinTree,BackendDAE.BinTree,list<Integer>,Boolean> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      Integer pos,l,eqnType,pos_1;
      BackendVarTransform.VariableReplacements repl,repl_1;
      BackendDAE.BinTree mvars,mvars_1,mavars,mavars_1;
      list<Integer> meqns,meqns1,deeqns,deeqns_1;
      BackendDAE.Variables vars,vars1;
      BackendDAE.EquationArray eqns,eqns1;
      DAE.FunctionTree funcs;
      Boolean b;
      BackendDAE.EqSystem syst,syst1;
      BackendDAE.Shared shared,shared1; 
      HashTable2.HashTable derrepl,derrepl_1;
      list<BackendDAE.Var> varlst;
      BackendDAE.Equation eqn;
           
    case ((pos,(syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,repl,derrepl,deeqns,mvars,mavars,meqns,b)))
      equation
        // get Vars in Eqn
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        {eqn} = BackendVarTransform.replaceEquations({eqn}, repl);
        vars1 = BackendEquation.equationVars(eqn,vars);
        varlst = BackendDAEUtil.varList(vars1);
        l = listLength(varlst);
        ((syst1,shared1,repl_1,derrepl_1,deeqns_1,mvars_1,mavars_1,meqns1,b)) = removeSimpleEquationsFastFinder1((l,pos,varlst,eqn,(syst,shared,repl,derrepl,deeqns,mvars,mavars,meqns,b)));
      then ((syst1,shared1,repl_1,derrepl_1,deeqns_1,mvars_1,mavars_1,meqns1,b));
    case ((_,(syst,shared,repl,derrepl,deeqns,mvars,mavars,meqns,b)))
      then ((syst,shared,repl,derrepl,deeqns,mvars,mavars,meqns,b));
   end matchcontinue;
end removeSimpleEquationsFastFinder;

protected function removeSimpleEquationsFastFinder1
"autor: Frenkel TUD 2012-03"
 input tuple<Integer,Integer,list<BackendDAE.Var>,BackendDAE.Equation,tuple<BackendDAE.EqSystem,BackendDAE.Shared,BackendVarTransform.VariableReplacements,HashTable2.HashTable,list<Integer>,BackendDAE.BinTree,BackendDAE.BinTree,list<Integer>,Boolean>> inTpl;
 output tuple<BackendDAE.EqSystem,BackendDAE.Shared,BackendVarTransform.VariableReplacements,HashTable2.HashTable,list<Integer>,BackendDAE.BinTree,BackendDAE.BinTree,list<Integer>,Boolean> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      Integer pos,l,i,eqnType,pos_1;
      BackendVarTransform.VariableReplacements repl,repl_1;
      BackendDAE.BinTree mvars,mvars_1,mavars,mavars_1;
      list<Integer> meqns,meqns1,vareqns,deeqns;
      DAE.ComponentRef cr;
      DAE.Exp exp,e1,e2;
      Boolean b;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared; 
      HashTable2.HashTable derrepl;
      list<BackendDAE.Var> varlst;
      BackendDAE.Equation eqn;

    case ((l,pos,_,BackendDAE.EQUATION(exp=e1,scalar=e2),(syst,shared,repl,derrepl,deeqns,mvars,mavars,meqns,b)))
      equation
        true = intEq(l,0);  
        pos_1 = pos-1;     
        true = Expression.isConst(e1);
        true = Expression.expEqual(e1,e2);
      then ((syst,shared,repl,derrepl,deeqns,mvars,mavars,pos_1::meqns,b));
    case ((l,pos,varlst,eqn,(syst,shared,repl,derrepl,deeqns,mvars,mavars,meqns,_)))
      equation
        true = intLt(l,3);
        true = intGt(l,0);
        (cr,i,exp,syst,shared,mvars_1,mavars_1,eqnType) = simpleEquationPast(varlst,pos,eqn,syst,shared,mvars,mavars);
        // replace equation if necesarry
        (syst,shared,repl_1,derrepl,deeqns,meqns1) = replacementsInEqnsFast(eqnType,cr,i,exp,pos,repl,derrepl,deeqns,syst,shared,meqns);
      then ((syst,shared,repl_1,derrepl,deeqns,mvars_1,mavars_1,meqns1,true));
    case ((_,_,_,_,(syst,shared,repl,derrepl,deeqns,mvars,mavars,meqns,b)))
      then ((syst,shared,repl,derrepl,deeqns,mvars,mavars,meqns,b));
   end matchcontinue;
end removeSimpleEquationsFastFinder1;

protected function replacementsInEqnsFast
"function: replacementsInEqnsFast
  author: Frenkel TUD 2012-03"
  input Integer eqnType;
  input DAE.ComponentRef cr;
  input Integer i;
  input DAE.Exp exp;
  input Integer pos;
  input BackendVarTransform.VariableReplacements repl;
  input HashTable2.HashTable inDerrepl;
  input list<Integer> inDeeqn;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> inMeqns;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendVarTransform.VariableReplacements outRepl;
  output HashTable2.HashTable outDerrepl;
  output list<Integer> outDeeqn;
  output list<Integer> outMeqns;
algorithm
  (osyst,oshared,outRepl,outDerrepl,outDeeqn,outMeqns):=
  match (eqnType,cr,i,exp,pos,repl,inDerrepl,inDeeqn,isyst,ishared,inMeqns)
    local
      BackendDAE.Variables ordvars,ordvars1;
      BackendDAE.EquationArray eqns;
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
      Integer pos_1;
      list<Integer> meqns,deeqns;
      BackendVarTransform.VariableReplacements repl_1;
      BackendDAE.Var v;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared,shared1;
      BackendDAE.Matching matching;
      HashTable2.HashTable derrepl;
      
    case (0,cr,i,exp,pos,repl,derrepl,deeqns,syst as BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns,m=m,mT=mT,matching=matching),shared,meqns)
      equation
        // remove var from vars
        (ordvars1,v) = BackendVariable.removeVar(i,ordvars);
        shared1 = BackendVariable.addKnVarDAE(v, shared);
        pos_1 = pos - 1;
      then (BackendDAE.EQSYSTEM(ordvars1,eqns,m,mT,matching),shared1,repl,derrepl,deeqns,pos_1::meqns);
    case (1,cr,i,exp,pos,repl,derrepl,deeqns,syst as BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns,m=m,mT=mT,matching=matching),shared,meqns)
      equation
        // remove var from vars
        (ordvars1,v) = BackendVariable.removeVar(i,ordvars);
        // update Replacements
        repl_1 = BackendVarTransform.addReplacement(repl, cr, exp);
        pos_1 = pos - 1;
      then (BackendDAE.EQSYSTEM(ordvars1,eqns,m,mT,matching),shared,repl_1,derrepl,deeqns,pos_1::meqns);
    case (2,cr,i,exp,pos,repl,derrepl,deeqns,syst as BackendDAE.EQSYSTEM(mT=mT),shared,meqns)
      equation
        derrepl = BaseHashTable.add((cr,exp),derrepl);
        pos_1 = pos - 1;
      then (syst,shared,repl,derrepl,pos_1::deeqns,meqns);
  end match;
end replacementsInEqnsFast;

protected function traverseEquations 
" function: traverseEquations
  autor: Frenkel TUD 2012-13"
  replaceable type Type_a subtypeof Any;
  input Integer inIndx;
  input Integer inSysSize;
  input FuncType inFunc;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<Integer,Type_a> inTpl;
    output Type_a outTpl;
  end FuncType;
algorithm
  outTypeA := 
  matchcontinue (inIndx,inSysSize,inFunc,inTypeA)
    local
      Integer e;
      Type_a arg,arg1;
    case (_,_,_,_)
      equation
        false = intGt(inIndx,inSysSize);
        arg1 = inFunc((inIndx,inTypeA));
      then traverseEquations(inIndx+1,inSysSize,inFunc,arg1); 
    case (_,_,_,_)
      equation
        true = intGt(inIndx,inSysSize);
      then inTypeA; 
  end matchcontinue;  
end traverseEquations;

public function removeSimpleEquationsPast
"function removeSimpleEquationsPast
 autor: Frenkel TUD 2012-13"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
protected
  BackendVarTransform.VariableReplacements repl,repl1;
algorithm
  repl := BackendVarTransform.emptyReplacements();
  (outDAE,(repl1,outRunMatching)) := BackendDAEUtil.mapEqSystemAndFold(inDAE,removeSimpleEquationsPast1,(repl,false));
  outDAE := removeSimpleEquationsShared(outRunMatching,outDAE,repl1);
  outDAE := BackendDAEUtil.mapEqSystem(outDAE,BackendDAEUtil.getIncidenceMatrixfromOptionForMapEqSystem);
  // until remove simple equations does not update assignments and comps  
end removeSimpleEquationsPast;

protected function removeSimpleEquationsPast1
"function: removeSimpleEquationsPast1
  autor: Frenkel TUD 2012-03
  This function moves simple equations on the form a=b and a=const and a=f(not time)
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared,tuple<BackendVarTransform.VariableReplacements,Boolean>> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,tuple<BackendVarTransform.VariableReplacements,Boolean>> osharedOptimized;
algorithm
  (osyst,osharedOptimized):=
  match (isyst,sharedOptimized)
    local
      BackendVarTransform.VariableReplacements repl,repl_1;
      BackendDAE.BinTree movedVars,movedAVars;
      list<Integer> meqns,deqns;
      Boolean b,b1;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      BackendDAE.StrongComponents comps;
      HashTable2.HashTable derrepl,derrepl1;
      
    case (syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)),(shared,(repl,b1)))
      equation
        derrepl = HashTable2.emptyHashTable();
        // check equations
        ((syst,shared,repl_1,derrepl1,deqns,movedVars,movedAVars,meqns,b)) = 
          traverseComponents(comps,removeSimpleEquationsPastFinder,
            (syst,shared,repl,derrepl,{},BackendDAE.emptyBintree,BackendDAE.emptyBintree,{},false));
        // replace der(x)=dx 
        (syst,shared) = replaceDerEquations(deqns,syst,shared,derrepl1);
        // replace vars in arrayeqns and algorithms, move vars to knvars and aliasvars, remove eqns
        (syst,shared) = removeSimpleEquations2(b,syst,shared,repl_1,movedVars,movedAVars,meqns);
      then (syst,(shared,(repl_1,b or b1)));
  end match;
end removeSimpleEquationsPast1;

protected function replaceDerEquations
  input list<Integer> inDeEqns;
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared inShared;
  input HashTable2.HashTable inDerrepl;
  output BackendDAE.EqSystem outSyst;
  output BackendDAE.Shared outShared;
algorithm
  (outSyst,outShared) :=
    match (inDeEqns,inSyst,inShared,inDerrepl)
     local
      list<Integer> deeqns;
      HashTable2.HashTable derrepl;
      BackendDAE.EquationArray eqns,eqns1;
      BackendDAE.Variables vars,knvars;
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
      BackendDAE.Matching matching;  
      Integer n;
    case ({},_,_,_) then (inSyst,inShared); 
    case (deeqns,BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching),_,derrepl)
      equation
       Debug.fcall(Flags.DUMP_DERREPL, BaseHashTable.dumpHashTable, derrepl);
       n = BackendDAEUtil.equationSize(eqns);
       deeqns = List.sort(deeqns,intGt);
       eqns1 = replaceDerEquations1(deeqns,0,n,derrepl,eqns);
     then 
       (BackendDAE.EQSYSTEM(vars,eqns1,m,mT,matching),inShared);
   end match;     
end replaceDerEquations;

protected function replaceDerEquations1
  input list<Integer> inSortDeEqns;
  input Integer inIndx;
  input Integer EqnSize;
  input HashTable2.HashTable inDerrepl; 
  input BackendDAE.EquationArray inEqns;
  output BackendDAE.EquationArray outEqns;
algorithm
  outEqns :=
    matchcontinue (inSortDeEqns,inIndx,EqnSize,inDerrepl,inEqns)
     local
      list<Integer> deeqns;
      HashTable2.HashTable derrepl;
      Integer n,i,de;
      BackendDAE.Equation eqn,eqn1;
      BackendDAE.EquationArray eqns,eqns1,eqns2;
     case ({},_,_,_,eqns) then eqns; 
     case (de::deeqns,i,n,derrepl,eqns)
      equation
       true = intLt(i,de);
       eqn = BackendDAEUtil.equationNth(eqns,i);
       (eqn1,_) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn, replaceDerEquationsFinder,derrepl);
       eqns1 = BackendEquation.equationSetnth(eqns,i,eqn1);
     then 
       replaceDerEquations1(de::deeqns,i+1,n,derrepl,eqns1);
     case (de::deeqns,i,n,derrepl,eqns)
      equation
       false = intLt(i,de);
     then 
       replaceDerEquations1(deeqns,i+1,n,derrepl,eqns);       
   end matchcontinue;     
end replaceDerEquations1;

protected function replaceDerEquationsFinder "function: replaceDerEquationsFinder
  author: Frenkel TUD 2012-03
  helper for replaceDerEquationsFinder"
 input tuple<DAE.Exp, HashTable2.HashTable> inTpl;
 output tuple<DAE.Exp, HashTable2.HashTable> outTpl;
algorithm 
  outTpl := match(inTpl)
    local 
      HashTable2.HashTable r;
      DAE.Exp e,e1;
    case((e,r))
      equation
        ((e1,_)) = Expression.traverseExp(e, replaceDerEquationsFinder1, r);
      then
        ((e1,r));
  end match;
end replaceDerEquationsFinder;

public function replaceDerEquationsFinder1 "
Author: Frenkel TUD 2012-3
helper for replaceDerEquationsFinder"
  input tuple<DAE.Exp, HashTable2.HashTable> inExp;
  output tuple<DAE.Exp, HashTable2.HashTable> outExp;
algorithm 
  outExp := matchcontinue(inExp)
    local
      HashTable2.HashTable r;
      DAE.Exp e,de;
      DAE.ComponentRef dcr,cr;

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),r))
      equation
        de = BaseHashTable.get(cr,r);
      then
        ((de,r));
    
    case(inExp) then inExp;
    
  end matchcontinue;
end replaceDerEquationsFinder1;


protected function removeSimpleEquationsPastFinder
"autor: Frenkel TUD 2012-03"
 input tuple<Integer,list<Integer>,tuple<BackendDAE.EqSystem,BackendDAE.Shared,BackendVarTransform.VariableReplacements,HashTable2.HashTable,list<Integer>,BackendDAE.BinTree,BackendDAE.BinTree,list<Integer>,Boolean>> inTpl;
 output tuple<list<Integer>,tuple<BackendDAE.EqSystem,BackendDAE.Shared,BackendVarTransform.VariableReplacements,HashTable2.HashTable,list<Integer>,BackendDAE.BinTree,BackendDAE.BinTree,list<Integer>,Boolean>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      Integer pos,l,eqnType,pos_1;
      BackendVarTransform.VariableReplacements repl,repl_1;
      BackendDAE.BinTree mvars,mvars_1,mavars,mavars_1;
      list<Integer> meqns,meqns1,vareqns,deeqns,deeqns_1,comp;
      BackendDAE.Variables vars,vars1;
      BackendDAE.EquationArray eqns,eqns1;
      DAE.FunctionTree funcs;
      Boolean b;
      BackendDAE.EqSystem syst,syst1;
      BackendDAE.Shared shared,shared1; 
      HashTable2.HashTable derrepl,derrepl_1;
      list<BackendDAE.Var> varlst;
      BackendDAE.Equation eqn;
           
    case ((pos,comp,(syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,repl,derrepl,deeqns,mvars,mavars,meqns,b)))
      equation
        // get Vars in Eqn
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        {eqn} = BackendVarTransform.replaceEquations({eqn}, repl);
        vars1 = BackendEquation.equationVars(eqn,vars);
        varlst = BackendDAEUtil.varList(vars1);
        l = listLength(varlst);
        ((vareqns,(syst1,shared1,repl_1,derrepl_1,deeqns_1,mvars_1,mavars_1,meqns1,b))) = removeSimpleEquationsPastFinder1((l,pos,varlst,comp,eqn,(syst,shared,repl,derrepl,deeqns,mvars,mavars,meqns,b)));
      then ((vareqns,(syst1,shared1,repl_1,derrepl_1,deeqns_1,mvars_1,mavars_1,meqns1,b)));
    case ((_,_,(syst,shared,repl,derrepl,deeqns,mvars,mavars,meqns,b)))
      then (({},(syst,shared,repl,derrepl,deeqns,mvars,mavars,meqns,b)));
   end matchcontinue;
end removeSimpleEquationsPastFinder;


protected function removeSimpleEquationsPastFinder1
"autor: Frenkel TUD 2012-03"
 input tuple<Integer,Integer,list<BackendDAE.Var>,list<Integer>,BackendDAE.Equation,tuple<BackendDAE.EqSystem,BackendDAE.Shared,BackendVarTransform.VariableReplacements,HashTable2.HashTable,list<Integer>,BackendDAE.BinTree,BackendDAE.BinTree,list<Integer>,Boolean>> inTpl;
 output tuple<list<Integer>,tuple<BackendDAE.EqSystem,BackendDAE.Shared,BackendVarTransform.VariableReplacements,HashTable2.HashTable,list<Integer>,BackendDAE.BinTree,BackendDAE.BinTree,list<Integer>,Boolean>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      Integer pos,l,i,eqnType,pos_1;
      BackendVarTransform.VariableReplacements repl,repl_1;
      BackendDAE.BinTree mvars,mvars_1,mavars,mavars_1;
      list<Integer> meqns,meqns1,vareqns,deeqns,comp;
      DAE.ComponentRef cr;
      DAE.Exp exp,e1,e2;
      DAE.FunctionTree funcs;
      Boolean b;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared; 
      HashTable2.HashTable derrepl;
      list<BackendDAE.Var> varlst;
      BackendDAE.Equation eqn;

    case ((l,pos,_,_,BackendDAE.EQUATION(exp=e1,scalar=e2),(syst,shared,repl,derrepl,deeqns,mvars,mavars,meqns,b)))
      equation
        true = intEq(l,0);  
        pos_1 = pos-1;     
        true = Expression.isConst(e1);
        true = Expression.expEqual(e1,e2);
      then (({},(syst,shared,repl,derrepl,deeqns,mvars,mavars,pos_1::meqns,b)));
    case ((l,pos,varlst,comp,eqn,(syst,shared,repl,derrepl,deeqns,mvars,mavars,meqns,_)))
      equation
        true = intLt(l,3);
        true = intGt(l,0);
        (cr,i,exp,syst,shared,mvars_1,mavars_1,eqnType) = simpleEquationPast(varlst,pos,eqn,syst,shared,mvars,mavars);
        // replace equation if necesarry
        (vareqns,syst,shared,repl_1,derrepl,deeqns,meqns1) = replacementsInEqnsPast(eqnType,cr,i,exp,pos,comp,repl,derrepl,deeqns,syst,shared,meqns);
      then ((vareqns,(syst,shared,repl_1,derrepl,deeqns,mvars_1,mavars_1,meqns1,true)));
    case ((_,_,_,_,_,(syst,shared,repl,derrepl,deeqns,mvars,mavars,meqns,b)))
      then (({},(syst,shared,repl,derrepl,deeqns,mvars,mavars,meqns,b)));
   end matchcontinue;
end removeSimpleEquationsPastFinder1;

protected function simpleEquationPast 
" function: simpleEquationPast
  autor: Frenkel TUD 2012-03"
  input list<BackendDAE.Var> elem;
  input Integer inPos;
  input BackendDAE.Equation inEqn;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
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
  (outCr,outPos,outExp,osyst,oshared,outMvars,outMavars,eqnType) := 
  matchcontinue(elem,inPos,inEqn,isyst,ishared,mvars,mavars)
    local 
      DAE.ComponentRef cr,cr2;
      Integer i,j,pos,pos_1,k,eqTy;
      DAE.Exp es,cre,e1,e2;
      BackendDAE.BinTree newvars,newvars1;
      BackendDAE.Variables vars,knvars;
      BackendDAE.Var var,var2,var3;
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn;
      Boolean negate;
      DAE.ElementSource source;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      
    // a = const
    // wbraun:
    // speacial case for Jacobains, since there are all known variablen
    // time depending input variables
    case ({var},pos,BackendDAE.EQUATION(exp=e1,scalar=e2,source=source),syst as BackendDAE.EQSYSTEM(orderedVars=vars),shared as BackendDAE.SHARED(backendDAEType = BackendDAE.JACOBIAN()),mvars,mavars)
      equation
        // no State
        false = BackendVariable.isStateorStateDerVar(var);
        false = BackendVariable.varHasUncertainValueRefine(var);
        // variable time not there
        knvars = BackendVariable.daeKnVars(shared);
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,knvars,true,false));
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,knvars,true,false));
        // try to solve the equation
        cr = BackendVariable.varCref(var);
        cre = Expression.crefExp(cr);
        (es,{}) = ExpressionSolve.solve(e1,e2,cre);
        source = DAEUtil.addSymbolicTransformation(source,DAE.SOLVE(cr,e1,e2,es,{}));
        // constant or alias
        (syst,shared,newvars,newvars1,eqTy) = constOrAlias(var,cr,es,syst,shared,mvars,mavars,DAEUtil.getSymbolicTransformations(source));
        (_,i::_) = BackendVariable.getVar(cr, vars);
      then (cr,i,es,syst,shared,newvars,newvars1,eqTy);
    // a = const
    case ({var},pos,BackendDAE.EQUATION(exp=e1,scalar=e2,source=source),syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,mvars,mavars)
      equation
        // no State
        false = BackendVariable.isStateorStateDerVar(var);
        false = BackendVariable.varHasUncertainValueRefine(var);
        // variable time not there
        knvars = BackendVariable.daeKnVars(shared);
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,knvars,false,false));
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,knvars,false,false));
        // try to solve the equation
        cr = BackendVariable.varCref(var);
        cre = Expression.crefExp(cr);
        (es,{}) = ExpressionSolve.solve(e1,e2,cre);
        source = DAEUtil.addSymbolicTransformation(source,DAE.SOLVE(cr,e1,e2,es,{}));
        // constant or alias
        (syst,shared,newvars,newvars1,eqTy) = constOrAlias(var,cr,es,syst,shared,mvars,mavars,DAEUtil.getSymbolicTransformations(source));
        (_,i::_) = BackendVariable.getVar(cr, vars);
      then (cr,i,es,syst,shared,newvars,newvars1,eqTy);        
    // a = der(b) 
    // a is a dummy_der_state
    case ({var,var2},pos,eqn,syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,mvars,mavars)
      equation
        (cr2,cr,e2,es,negate) = BackendEquation.derivativeEquation(eqn);
        // select candidate
        ((var::_),(k::_)) = BackendVariable.getVar(cr,vars);
        ((var2::_),(j::_)) = BackendVariable.getVar(cr2,vars);
        true = BackendVariable.isDummyDerVar(var);
        // because this is a self genererated var we need not check for uncertainities
        //false = BackendVariable.varHasUncertainValueRefine(var);
        (syst,shared,newvars) = selectAlias2(cr,cr2,var,var2,e2,es,syst,shared,mavars,negate,BackendEquation.equationSource(eqn));
      then (cr,k,es,syst,shared,mvars,newvars,1);
    // a = der(b) 
    // a is not a state
    /* Frenkel TUD: -because we have no way to store the min,max,nominval,start attribute for der(state) variables we cannot replace 
                     this simple equations. */   
    /*case ({var,var2},pos,eqn,syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,mvars,mavars)
      equation
        (cr2,cr,e2,es,negate) = BackendEquation.derivativeEquation(eqn);
        // select candidate
        ((var::_),(k::_)) = BackendVariable.getVar(cr,vars);
        ((var2::_),(j::_)) = BackendVariable.getVar(cr2,vars);
        false = BackendVariable.varHasUncertainValueRefine(var);
        replaceableAlias(var);
        (syst,shared,newvars) = selectAlias2(cr,cr2,var,var2,e2,es,syst,shared,mavars,negate,,BackendEquation.equationSource(eqn));
      then (cr,k,es,syst,shared,mvars,newvars,1);
    */    
    // a = der(b) 
    case ({var,var2},pos,eqn,syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,mvars,mavars)
      equation
        (cr,_,es,_,negate) = BackendEquation.derivativeEquation(eqn);
        // select candidate
        ((var::_),(k::_)) = BackendVariable.getVar(cr,vars);
        false = BackendVariable.varHasUncertainValueRefine(var);
      then (cr,k,es,syst,shared,mvars,mavars,2);
    // a = b 
    case ({var,var2},pos,eqn as BackendDAE.EQUATION(source=source),syst as BackendDAE.EQSYSTEM(orderedEqs=eqns),shared,mvars,mavars)
      equation
        (cr,cr2,e1,e2,negate) = BackendEquation.aliasEquation(eqn);
        // select candidate
        (cr,es,k,syst,shared,newvars) = selectAlias(cr,cr2,e1,e2,syst,shared,mavars,negate,source);
      then (cr,k,es,syst,shared,mvars,newvars,1);
    case ({var,var2},pos,BackendDAE.EQUATION(exp=e1,scalar=e2,source=source),syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,mvars,mavars)
      equation
        cr = BackendVariable.varCref(var);
        cre = Expression.crefExp(cr);
        (es,{}) = ExpressionSolve.solve(e1,e2,cre); 
        (_,i::_) = BackendVariable.getVar(cr, vars);
        (cr,k,es,syst,shared,newvars,newvars1,eqTy)= simpleEquation1(BackendDAE.EQUATION(cre,es,source),var,i,cr,es,source,syst,shared,mvars,mavars);      
      then (cr,k,es,syst,shared,newvars,newvars1,eqTy);        
    case ({var2,var},pos,BackendDAE.EQUATION(exp=e1,scalar=e2,source=source),syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,mvars,mavars)
      equation
        cr = BackendVariable.varCref(var);
        cre = Expression.crefExp(cr);
        (es,{}) = ExpressionSolve.solve(e1,e2,cre); 
        (_,j::_) = BackendVariable.getVar(cr, vars);       
        (cr,k,es,syst,shared,newvars,newvars1,eqTy)= simpleEquation1(BackendDAE.EQUATION(cre,es,source),var,j,cr,es,source,syst,shared,mvars,mavars);      
      then (cr,k,es,syst,shared,newvars,newvars1,eqTy);         
  end matchcontinue;
end simpleEquationPast;

protected function replacementsInEqnsPast
"function: replacementsInEqnsPast
  author: Frenkel TUD 2012-03"
  input Integer eqnType;
  input DAE.ComponentRef cr;
  input Integer i;
  input DAE.Exp exp;
  input Integer pos;
  input list<Integer> inComp;
  input BackendVarTransform.VariableReplacements repl;
  input HashTable2.HashTable inDerrepl;
  input list<Integer> inDeeqn;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> inMeqns;
  output list<Integer> outVareqns;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendVarTransform.VariableReplacements outRepl;
  output HashTable2.HashTable outDerrepl;
  output list<Integer> outDeeqn;
  output list<Integer> outMeqns;
algorithm
  (outVareqns,osyst,oshared,outRepl,outDerrepl,outDeeqn,outMeqns):=
  match (eqnType,cr,i,exp,pos,inComp,repl,inDerrepl,inDeeqn,isyst,ishared,inMeqns)
    local
      BackendDAE.Variables ordvars,ordvars1;
      BackendDAE.EquationArray eqns;
      Option<BackendDAE.IncidenceMatrix> m;
      BackendDAE.IncidenceMatrixT mT;
      Integer pos_1;
      list<Integer> vareqns,vareqns1,vareqns2,meqns,deeqns,comp;
      BackendVarTransform.VariableReplacements repl_1;
      BackendDAE.Var v;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared,shared1;
      BackendDAE.Matching matching;
      HashTable2.HashTable derrepl;
      
    case (0,cr,i,exp,pos,_,repl,derrepl,deeqns,syst as BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns,m=m,mT=SOME(mT),matching=matching),shared,meqns)
      equation
        // equations of var
        vareqns = mT[i];
        // remove var from vars
        (ordvars1,v) = BackendVariable.removeVar(i,ordvars);
        shared1 = BackendVariable.addKnVarDAE(v, shared);
        pos_1 = pos - 1;
      then (vareqns,BackendDAE.EQSYSTEM(ordvars1,eqns,m,SOME(mT),matching),shared1,repl,derrepl,deeqns,pos_1::meqns);
    case (1,cr,i,exp,pos,_,repl,derrepl,deeqns,syst as BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns,m=m,mT=SOME(mT),matching=matching),shared,meqns)
      equation
        // equations of var
        vareqns = mT[i];
        // remove var from vars
        (ordvars1,v) = BackendVariable.removeVar(i,ordvars);
        // update Replacements
        repl_1 = BackendVarTransform.addReplacement(repl, cr, exp);
        pos_1 = pos - 1;
      then (vareqns,BackendDAE.EQSYSTEM(ordvars1,eqns,m,SOME(mT),matching),shared,repl_1,derrepl,deeqns,pos_1::meqns);
    case (2,cr,i,exp,pos,comp,repl,derrepl,deeqns,syst as BackendDAE.EQSYSTEM(mT=SOME(mT)),shared,meqns)
      equation
        // equations of var
        vareqns = mT[i];
        vareqns1 = List.removeOnTrue(0, intGt, vareqns);
        pos_1 = pos - 1;
        vareqns1 = List.removeOnTrue(pos, intEq, vareqns1);
        derrepl = BaseHashTable.add((cr,exp),derrepl);
        vareqns2 = List.intersectionOnTrue(vareqns1, comp, intEq);
        // replace der(a)=b in vareqns
        (syst,shared) = replacementsInEqns2(vareqns1,exp,cr,syst,shared);
        // update IncidenceMatrix
        syst= BackendDAEUtil.updateIncidenceMatrix(syst,shared,vareqns2);
      then (vareqns1,syst,shared,repl,derrepl,pos_1::deeqns,meqns);
  end match;
end replacementsInEqnsPast;

protected function traverseComponents 
" function: traverseComponents
  autor: Frenkel TUD 2010-12"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.StrongComponents inComps;
  input FuncType inFunc;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<Integer,list<Integer>,Type_a> inTpl;
    output tuple<list<Integer>,Type_a> outTpl;
  end FuncType;
algorithm
  outTypeA := 
  matchcontinue (inComps,inFunc,inTypeA)
    local
      Integer e;
      list<Integer> elst,elst1;
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents rest;
      Type_a arg;
      FuncType func;
    case ({},_,_) then inTypeA; 
    case (BackendDAE.SINGLEEQUATION(eqn=e)::rest,_,_) 
      equation
        ((_,arg)) = inFunc((e,{e},inTypeA));
      then 
         traverseComponents(rest,inFunc,arg);
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp,disc_eqns=elst)::rest,_,_) 
      equation
        (elst1,_) = BackendDAETransform.getEquationAndSolvedVarIndxes(comp);
        elst = listAppend(elst,elst1);
        elst = List.sort(elst,intGt);
        arg = traverseComponents1(elst,elst,inFunc,inTypeA);
      then
        traverseComponents(rest,inFunc,arg);
    case (BackendDAE.EQUATIONSYSTEM(eqns=elst)::rest,_,_) 
      equation
        elst = List.sort(elst,intGt);
        arg = traverseComponents1(elst,elst,inFunc,inTypeA);
      then 
         traverseComponents(rest,inFunc,arg);
    case (BackendDAE.SINGLEARRAY(eqns=elst)::rest,_,_) 
        // ToDo: check also this one     
      then 
         traverseComponents(rest,inFunc,inTypeA);   
    case (BackendDAE.SINGLEALGORITHM(eqns=elst)::rest,_,_) 
        // ToDo: check also this one     
      then 
         traverseComponents(rest,inFunc,inTypeA);   
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqns=elst)::rest,_,_) 
        // ToDo: check also this one     
      then 
         traverseComponents(rest,inFunc,inTypeA);   
    case (_::rest,_,_) 
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("BackendDAEOptimize.traverseComponents failed!");
      then
         traverseComponents(rest,inFunc,inTypeA);
    case (_::rest,func,arg) 
      then
        traverseComponents(rest,inFunc,inTypeA);
  end matchcontinue;  
end traverseComponents;

protected function traverseComponents1 
" function: traverseComponents
  autor: Frenkel TUD 2010-12"
  replaceable type Type_a subtypeof Any;
  input list<Integer> inEqns;
  input list<Integer> inEqns1;
  input FuncType inFunc;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<Integer,list<Integer>,Type_a> inTpl;
    output tuple<list<Integer>,Type_a> outTpl;
  end FuncType;
algorithm
  outTypeA := 
  match (inEqns,inEqns1,inFunc,inTypeA)
    local
      Integer e;
      list<Integer> elst,elst1,elst2,rest;
      Type_a arg,arg1,arg2;
      FuncType func;
    case ({},_,_,_) then inTypeA;
    case (e::rest,_,_,_) 
      equation
        ((elst,arg1)) = inFunc((e,inEqns1,inTypeA));
        elst1 = List.removeOnTrue(e-1, intLt, elst);
        elst2 = List.intersectionOnTrue(elst1,inEqns1,intEq);
        elst2 = List.sort(elst2,intGt);
        arg2 = traverseComponents1(elst2,inEqns1,inFunc,arg1);
      then
         traverseComponents1(rest,inEqns1,inFunc,arg2);
  end match;  
end traverseComponents1;

public function removeSimpleEquations
"function: removeSimpleEquations
  autor: Frenkel TUD 2011-04
  This function moves simple equations on the form a=b and a=const and a=f(not time)
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE odae;
protected
  BackendVarTransform.VariableReplacements repl,repl1;
  Boolean b;
algorithm
  repl := BackendVarTransform.emptyReplacements();
  (odae,(repl1,b)) := BackendDAEUtil.mapEqSystemAndFold(dae,removeSimpleEquations1,(repl,false));
  odae := removeSimpleEquationsShared(b,odae,repl1);
end removeSimpleEquations;

protected function removeSimpleEquations1
"function: removeSimpleEquations1
  autor: Frenkel TUD 2011-05
  This function moves simple equations on the form a=b and a=const and a=f(not time)
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared,tuple<BackendVarTransform.VariableReplacements,Boolean>> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,tuple<BackendVarTransform.VariableReplacements,Boolean>> osharedOptimized;
algorithm
  (osyst,osharedOptimized):=
  match (isyst,sharedOptimized)
    local
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mT;
      BackendVarTransform.VariableReplacements repl,repl_1;
      BackendDAE.BinTree movedVars,movedAVars;
      list<Integer> meqns;
      Boolean b,b1,b2;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      
    case (syst,(shared,(repl,b1)))
      equation
        (syst,m,mT) = BackendDAEUtil.getIncidenceMatrixfromOption(syst,shared,BackendDAE.NORMAL());
        // check equations
        (_,(syst,shared,_,repl_1,movedVars,movedAVars,meqns,b)) = 
          traverseIncidenceMatrix(
            m,removeSimpleEquationsFinder,
            (syst,shared,mT,repl,
             BackendDAE.emptyBintree,
             BackendDAE.emptyBintree,{},false));
        // replace vars in arrayeqns and algorithms, move vars to knvars and aliasvars, remove eqns
        (syst,shared) = removeSimpleEquations2(b,syst,shared,repl_1,movedVars,movedAVars,meqns);
      then (syst,(shared,(repl_1,b or b1)));
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
      array<DAE.Constraint> constrs;
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcTree;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      list<BackendDAE.WhenClause> whenClauseLst,whenClauseLst1;
      list<BackendDAE.ZeroCrossing> zeroCrossingLst;
      Boolean b;
      BackendDAE.BackendDAEType btp;   
    case (false,syst,shared,_,_,_,_) then (syst,shared);
    case (true,BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns),BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,cache,env,funcTree,einfo,eoc,btp,symjacs),repl,movedVars,movedAVars,meqns)
      equation
        Debug.fcall(Flags.DUMP_REPL, BackendVarTransform.dumpReplacements, repl);
        Debug.fcall(Flags.DUMP_REPL, BackendVarTransform.dumpExtendReplacements, repl);
        // delete alias variables from orderedVars
        ordvars1 = BackendVariable.deleteVars(movedAVars,ordvars);
        // move changed variables 
        (ordvars2,knvars1) = BackendVariable.moveVariables(ordvars1,knvars,movedVars);
        // remove changed eqns
        eqns1 = BackendEquation.equationDelete(eqns,meqns);
        // replace moved vars in vars,knvars,aliasVars,ineqns,remeqns
        (ordvars3,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(ordvars2,replaceVarTraverser,repl);
        // update array eqn wrapper
      then 
        (BackendDAE.EQSYSTEM(ordvars3,eqns1,NONE(),NONE(),BackendDAE.NO_MATCHING()),BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,constrs,cache,env,funcTree,einfo,eoc,btp,symjacs));
  end match;
end removeSimpleEquations2;

protected function removeSimpleEquationsShared
"function: removeSimpleEquationsShared"
  input Boolean b;
  input BackendDAE.BackendDAE inDAE;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE:=
  match (b,inDAE,repl)
    local
      BackendDAE.Variables ordvars,knvars,exobj,knvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray remeqns,inieqns,eqns1,inieqns1,remeqns1,eqns2;
      array<DAE.Constraint> constrs;
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcTree;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      list<BackendDAE.WhenClause> whenClauseLst,whenClauseLst1;
      list<BackendDAE.ZeroCrossing> zeroCrossingLst;
      Boolean b;
      BackendDAE.BackendDAEType btp; 
      BackendDAE.EqSystems systs,systs1;  
      BackendDAE.Shared shared;
      list<BackendDAE.Var> ordvarslst;
    case (false,_,_) then inDAE;
    case (true,BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,cache,env,funcTree,BackendDAE.EVENT_INFO(whenClauseLst,zeroCrossingLst),eoc,btp,symjacs)),repl)
      equation
        ordvarslst = BackendVariable.equationSystemsVarsLst(systs,{});
        ordvars = BackendDAEUtil.listVar(ordvarslst);
        // replace moved vars in knvars,ineqns,remeqns
        (knvars1,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(knvars,replaceVarTraverser,repl);
        (inieqns1,_) = BackendEquation.traverseBackendDAEEqnsWithUpdate(inieqns,replaceEquationTraverser,repl);
        (remeqns1,_) = BackendEquation.traverseBackendDAEEqnsWithUpdate(remeqns,replaceEquationTraverser,repl);
        (whenClauseLst1,_) = BackendDAETransform.traverseBackendDAEExpsWhenClauseLst(whenClauseLst,replaceWhenClauseTraverser,repl);
        systs1 = removeSimpleEquationsUpdateWrapper(systs,{},repl);
        // update array eqn wrapper
      then 
        BackendDAE.DAE(systs1,BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns1,remeqns1,constrs,cache,env,funcTree,BackendDAE.EVENT_INFO(whenClauseLst1,zeroCrossingLst),eoc,btp,symjacs));
  end match;
end removeSimpleEquationsShared;

protected function removeSimpleEquationsUpdateWrapper
  input BackendDAE.EqSystems inSysts;
  input BackendDAE.EqSystems inSysts1;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.EqSystems outSysts;
algorithm
  outSysts := match (inSysts,inSysts1,repl)
    local
      BackendDAE.EqSystems rest,systs;
      BackendDAE.Variables v;
      BackendDAE.EquationArray eqns,eqns1;
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
      BackendDAE.Matching matching;      
      case ({},_,_) then inSysts1;
      case (BackendDAE.EQSYSTEM(v,eqns,m,mT,matching)::rest,_,_)
        equation
        (eqns1,_) = BackendEquation.traverseBackendDAEEqnsWithUpdate(eqns,replaceEquationTraverser,repl);
        systs = BackendDAE.EQSYSTEM(v,eqns1,m,mT,matching)::inSysts1;
        then
          removeSimpleEquationsUpdateWrapper(rest,systs,repl);
    end match;
end removeSimpleEquationsUpdateWrapper;

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
  input tuple<BackendDAE.Equation,BackendVarTransform.VariableReplacements> inTpl;
  output tuple<BackendDAE.Equation,BackendVarTransform.VariableReplacements> outTpl;
algorithm
  outTpl:=  
  matchcontinue (inTpl)
    local 
      BackendDAE.Equation e,e1;
      BackendVarTransform.VariableReplacements repl;
    case ((e,repl))
      equation
        {e1} = BackendVarTransform.replaceEquations({e},repl);
      then ((e1,repl));
  end matchcontinue;
end replaceEquationTraverser;


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
  input tuple<DAE.Algorithm,tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables,list<Option<tuple<list<DAE.Exp>,list<DAE.Exp>>>>>> inTpl;
  output tuple<DAE.Algorithm,tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables,list<Option<tuple<list<DAE.Exp>,list<DAE.Exp>>>>>> outTpl;
algorithm
  outTpl:=
  match (inTpl)
    local 
      list<DAE.Statement> statementLst,statementLst_1;
      BackendVarTransform.VariableReplacements repl;
      list<Option<tuple<list<DAE.Exp>,list<DAE.Exp>>>> inouttpllst;
      BackendDAE.Variables vars;
      DAE.Algorithm alg;
      Boolean b;
    case ((DAE.ALGORITHM_STMTS(statementLst=statementLst),(repl,vars,inouttpllst)))
      equation
        (statementLst_1,b) = BackendVarTransform.replaceStatementLst(statementLst,repl,{},false);
        (alg,(repl,vars,inouttpllst)) =  replaceAlgorithmTraverser1(b,statementLst_1,(repl,vars,inouttpllst));
      then
        ((alg,(repl,vars,inouttpllst)));
  end match;
end replaceAlgorithmTraverser;

protected function replaceAlgorithmTraverser1 "function: replaceAlgorithmTraverser1
  author: Frenkel TUD 2010-04
  It is possible to change the algorithm.
"
  input Boolean b;
  input list<DAE.Statement> inStms;
  input tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables,list<Option<tuple<list<DAE.Exp>,list<DAE.Exp>>>>> inTpl;
  output DAE.Algorithm outAlg;
  output tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables,list<Option<tuple<list<DAE.Exp>,list<DAE.Exp>>>>> outTpl;
algorithm
  (outAlg,outTpl):=
  match (b,inStms,inTpl)
    local 
      list<DAE.Statement> statementLst;
      BackendVarTransform.VariableReplacements repl;
      list<Option<tuple<list<DAE.Exp>,list<DAE.Exp>>>> inouttpllst;
      tuple<list<DAE.Exp>,list<DAE.Exp>> inouttpl;
      BackendDAE.Variables vars;
      DAE.Algorithm alg;
      case (false,statementLst,(repl,vars,inouttpllst))
        then (DAE.ALGORITHM_STMTS(statementLst),(repl,vars,NONE()::inouttpllst));
    case (true,statementLst,(repl,vars,inouttpllst))
      equation
        alg = DAE.ALGORITHM_STMTS(statementLst);
        inouttpl = ({},{}); // BackendDAECreate.lowerAlgorithmInputsOutputs(vars,alg);
      then
        (alg,(repl,vars,SOME(inouttpl)::inouttpllst));
  end match;
end replaceAlgorithmTraverser1;

protected function removeSimpleEquationsFinder
"autor: Frenkel TUD 2010-12"
 input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix, tuple<BackendDAE.EqSystem,BackendDAE.Shared,BackendDAE.IncidenceMatrixT,BackendVarTransform.VariableReplacements,BackendDAE.BinTree,BackendDAE.BinTree,list<Integer>,Boolean>> inTpl;
 output tuple<list<Integer>,BackendDAE.IncidenceMatrix, tuple<BackendDAE.EqSystem,BackendDAE.Shared,BackendDAE.IncidenceMatrixT,BackendVarTransform.VariableReplacements,BackendDAE.BinTree,BackendDAE.BinTree,list<Integer>,Boolean>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.IncidenceMatrixElement elem;
      Integer pos,l,i,eqnType,pos_1;
      BackendDAE.IncidenceMatrix m,m1,mT,mT1;
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
    case ((elem,pos,m,(syst as BackendDAE.EQSYSTEM(orderedEqs=eqns),shared,mT,repl,mvars,mavars,meqns,_)))
      equation
        // check number of vars in eqns
        l = listLength(elem);
        true = intEq(l,0);
        pos_1 = pos-1;
        BackendDAE.EQUATION(exp=e1,scalar=e2) = BackendDAEUtil.equationNth(eqns,pos_1);
        true = Expression.isConst(e1);
        true = Expression.expEqual(e1,e2);
      then (({},m,(syst,shared,mT,repl,mvars,mavars,pos_1::meqns,true)));      
    case ((elem,pos,m,(syst,shared,mT,repl,mvars,mavars,meqns,_)))
      equation
        // check number of vars in eqns
        l = listLength(elem);
        true = intLt(l,3);
        true = intGt(l,0);
        (cr,i,exp,syst,shared,mvars_1,mavars_1,eqnType) = simpleEquation(elem,l,pos,syst,shared,mvars,mavars);
        // replace equation if necesarry
        (vareqns,syst,shared,m1,mT1,repl_1,meqns1) = replacementsInEqns(eqnType,cr,i,exp,pos,repl,syst,shared,m,mT,meqns);
      then ((vareqns,m1,(syst,shared,mT1,repl_1,mvars_1,mavars_1,meqns1,true)));
    case ((elem,pos,m,(syst,shared,mT,repl,mvars,mavars,meqns,b)))
      then (({},m,(syst,shared,mT,repl,mvars,mavars,meqns,b))); 
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
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.IncidenceMatrix im;
  input BackendDAE.IncidenceMatrix imT;
  input list<Integer> inMeqns;
  output list<Integer> outVareqns;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.IncidenceMatrix om;
  output BackendDAE.IncidenceMatrix omT;
  output BackendVarTransform.VariableReplacements outRepl;
  output list<Integer> outMeqns;
algorithm
  (outVareqns,osyst,oshared,om,omT,outRepl,outMeqns):=
  match (eqnType,cr,i,exp,pos,repl,isyst,ishared,im,imT,inMeqns)
    local
      BackendDAE.Variables ordvars,knvars,exobj,ordvars1,knvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1,eqns2;
      array<DAE.Constraint> constrs;
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcTree;
      BackendDAE.EventInfo einfo,einfo1;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.IncidenceMatrix m1,m;
      BackendDAE.IncidenceMatrixT mT1,mT;
      Integer pos_1;
      list<Integer> vareqns,vareqns1,vareqns2,meqns;
      BackendVarTransform.VariableReplacements repl_1;
      BackendDAE.Var v;
      BackendDAE.BackendDAEType btp;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      
    case (0,cr,i,exp,pos,repl,BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns),BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,cache,env,funcTree,einfo,eoc,btp,symjacs),m,mT,meqns)
      equation
        // equations of var
        vareqns = mT[i];
        vareqns1 = List.removeOnTrue(pos,intEq,vareqns);
        // remove var from vars
        (ordvars1,v) = BackendVariable.removeVar(i,ordvars);
        knvars1 = BackendVariable.addVar(v,knvars);
        // update IncidenceMatrix
        syst = BackendDAE.EQSYSTEM(ordvars1,eqns,SOME(m),SOME(mT),BackendDAE.NO_MATCHING());
        shared = BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,constrs,cache,env,funcTree,einfo,eoc,btp,symjacs);
        (syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mT))) = BackendDAEUtil.updateIncidenceMatrix(syst,shared,vareqns);
        pos_1 = pos - 1;
      then (vareqns1,syst,shared,m,mT,repl,pos_1::meqns);
    case (1,cr,i,exp,pos,repl,BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns),shared,m,mT,meqns)
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
    case (2,cr,i,exp,pos,repl,syst,shared,m,mT,meqns)
      equation
        // equations of var
        vareqns = mT[i];
        vareqns1 = List.removeOnTrue(pos,intEq,vareqns);
        vareqns2 = List.removeOnTrue(0,intGt,vareqns1);
        // replace der(a)=b in vareqns
        (syst,shared) = replacementsInEqns2(vareqns2,exp,cr,syst,shared);
        // update IncidenceMatrix
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
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared inShared;
  output BackendDAE.EqSystem outSyst;
  output BackendDAE.Shared outShared;
algorithm
  (outSyst,outShared):=
  match (inEqsLst,derExp,inCr,inSyst,inShared)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1;
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
      BackendDAE.Matching matching;
    case ({},_,_,_,_) then (inSyst,inShared);
    case (inEqsLst,derExp,inCr,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,m=m,mT=mT,matching=matching),_)
      equation
        eqns1 = replacementsInEqns3(inEqsLst,derExp,inCr,eqns);
      then (BackendDAE.EQSYSTEM(vars,eqns1,m,mT,matching),inShared);
  end match;
end replacementsInEqns2;

protected function replacementsInEqns3
"function: replacementsInEqns1
  author: Frenkel TUD 2011-04"
  input list<Integer> inEqsLst;
  input DAE.Exp derExp;
  input DAE.ComponentRef inCr;
  input BackendDAE.EquationArray inEqns;
  output BackendDAE.EquationArray outEqns;
algorithm
  outEqns:=
  match (inEqsLst,derExp,inCr,inEqns)
    local
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn,eqn1;
      Integer pos,pos_1;
      list<Integer> rest;
    case ({},_,_,_) then inEqns;
    case (pos::rest,derExp,inCr,_)
      equation
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(inEqns,pos_1);
        (eqn1,_) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn, replaceAliasDer,(derExp,inCr));
        eqns =  BackendEquation.equationSetnth(inEqns,pos_1,eqn1);
      then 
        replacementsInEqns3(rest,derExp,inCr,eqns);
  end match;
end replacementsInEqns3;

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
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
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
  (outCr,outPos,outExp,osyst,oshared,outMvars,outMavars,eqnType) := 
  matchcontinue(elem,length,pos,isyst,ishared,mvars,mavars)
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
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      
    // a = const
    // wbraun:
    // speacial case for Jacobains, since there are all known variablen
    // time depending input variables
    case ({i},length,pos,syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared as BackendDAE.SHARED(backendDAEType = BackendDAE.JACOBIAN()),mvars,mavars)
      equation
        var = BackendVariable.getVarAt(vars,intAbs(i));
        // no State
        false = BackendVariable.isStateorStateDerVar(var);
        false = BackendVariable.varHasUncertainValueRefine(var);
        // try to solve the equation
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        BackendDAE.EQUATION(exp=e1,scalar=e2,source=source) = eqn;
        // variable time not there
        knvars = BackendVariable.daeKnVars(shared);
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,knvars,true,false));
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,knvars,true,false));
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
        false = BackendVariable.varHasUncertainValueRefine(var);
        // try to solve the equation
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        BackendDAE.EQUATION(exp=e1,scalar=e2,source=source) = eqn;
        // variable time not there
        knvars = BackendVariable.daeKnVars(shared);
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,knvars,false,false));
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,knvars,false,false));
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
        ((var::_),(k::_)) = BackendVariable.getVar(cr,vars);
        false = BackendVariable.varHasUncertainValueRefine(var);
      then (cr,k,es,syst,shared,mvars,mavars,2);
    // a = b 
    case ({i,j},length,pos,syst as BackendDAE.EQSYSTEM(orderedEqs=eqns),shared,mvars,mavars)
      equation
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        (cr,cr2,e1,e2,negate) = BackendEquation.aliasEquation(eqn);
        // select candidate
        source = BackendEquation.equationSource(eqn);
        (cr,es,k,syst,shared,newvars) = selectAlias(cr,cr2,e1,e2,syst,shared,mavars,negate,source);
      then (cr,k,es,syst,shared,mvars,newvars,1);
    case ({i,j},length,pos,syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,mvars,mavars)
      equation
        pos_1 = pos-1;
        (BackendDAE.EQUATION(exp=e1,scalar=e2,source=source)) = BackendDAEUtil.equationNth(eqns,pos_1);
        var = BackendVariable.getVarAt(vars,intAbs(i));
        cr = BackendVariable.varCref(var);
        cre = Expression.crefExp(cr);
        (es,{}) = ExpressionSolve.solve(e1,e2,cre); 
        (cr,k,es,syst,shared,newvars,newvars1,eqTy)= simpleEquation1(BackendDAE.EQUATION(cre,es,source),var,i,cr,es,source,syst,shared,mvars,mavars);      
      then (cr,k,es,syst,shared,newvars,newvars1,eqTy);        
    case ({i,j},length,pos,syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,mvars,mavars)
      equation
        pos_1 = pos-1;
        (BackendDAE.EQUATION(exp=e1,scalar=e2,source=source)) = BackendDAEUtil.equationNth(eqns,pos_1);
        var = BackendVariable.getVarAt(vars,intAbs(j));
        cr = BackendVariable.varCref(var);
        cre = Expression.crefExp(cr);
        (es,{}) = ExpressionSolve.solve(e1,e2,cre);        
        (cr,k,es,syst,shared,newvars,newvars1,eqTy)= simpleEquation1(BackendDAE.EQUATION(cre,es,source),var,j,cr,es,source,syst,shared,mvars,mavars);      
      then (cr,k,es,syst,shared,newvars,newvars1,eqTy);         
  end matchcontinue;
end simpleEquation;

protected function simpleEquation1
" function: simpleEquation1
  autor: Frenkel TUD 2012-03"
  input BackendDAE.Equation inEqn;
  input BackendDAE.Var inVar;
  input Integer inPos;
  input DAE.ComponentRef inCref;
  input DAE.Exp inExp;
  input DAE.ElementSource inSource;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
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
  (outCr,outPos,outExp,osyst,oshared,outMvars,outMavars,eqnType) := 
  matchcontinue(inEqn,inVar,inPos,inCref,inExp,inSource,isyst,ishared,mvars,mavars)
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
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      
    // a = const
    case (eqn,var,i,cr,es,source,syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,mvars,mavars)
      equation
        // no State
        false = BackendVariable.isStateorStateDerVar(var);
        false = BackendVariable.varHasUncertainValueRefine(var);
        // variable time not there
        knvars = BackendVariable.daeKnVars(shared);
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(es, traversingTimeEqnsFinder, (false,vars,knvars,false,true));
        // constant or alias
        (syst,shared,newvars,newvars1,eqTy) = constOrAlias(var,cr,es,syst,shared,mvars,mavars,DAEUtil.getSymbolicTransformations(source));
      then (cr,i,es,syst,shared,newvars,newvars1,eqTy);        
    // a = der(b) 
    case (eqn,var,i,cr,es,source,syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,mvars,mavars)
      equation
        (cr,_,es,_,negate) = BackendEquation.derivativeEquation(eqn);
        // select candidate
        ((var::_),(k::_)) = BackendVariable.getVar(cr,vars);
        false = BackendVariable.varHasUncertainValueRefine(var);
      then (cr,k,es,syst,shared,mvars,mavars,2);
    // a = b 
    case (eqn,var,i,cr,es,source,syst as BackendDAE.EQSYSTEM(orderedEqs=eqns),shared,mvars,mavars)
      equation
        (cr,cr2,e1,e2,negate) = BackendEquation.aliasEquation(eqn);
        // select candidate
        (cr,es,k,syst,shared,newvars) = selectAlias(cr,cr2,e1,e2,syst,shared,mavars,negate,source);
      then (cr,k,es,syst,shared,mvars,newvars,1);
  end matchcontinue;
end simpleEquation1;

protected function constOrAlias
"function constOrAlias
  autor Frenkel TUD 2011-04"
  input BackendDAE.Var var;
  input DAE.ComponentRef cr;
  input DAE.Exp exp;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.BinTree mvars;
  input BackendDAE.BinTree mavars;
  input list<DAE.SymbolicOperation> ops;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.BinTree outMvars;
  output BackendDAE.BinTree outMavars;
  output Integer eqnType;
algorithm
  (osyst,oshared,outMvars,outMavars,eqnType) := matchcontinue (var,cr,exp,isyst,ishared,mvars,mavars,ops)
    local
      DAE.ComponentRef cr,cra;
      BackendDAE.BinTree newvars;
      BackendDAE.VarKind kind;
      BackendDAE.Var var,var2,var3,var4,v,v1;
      BackendDAE.BackendDAE dae1,dae2;
      Boolean constExp,negate;
      BackendDAE.Variables knvars;
      Integer eqTy;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
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
        Debug.fcall(Flags.DEBUG_ALIAS,BackendDump.debugStrCrefStrExpStr,("Alias Equation ",cr," = ",exp," found (1).\n"));
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
        shared = BackendVariable.addKnVarDAE(var3,shared);
        // store changed var
        Debug.fcall(Flags.DEBUG_ALIAS,BackendDump.debugStrCrefStrExpStr,("Const Equation ",cr," = ",exp," found (2).\n"));
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
        false = BackendVariable.varHasUncertainValueRefine(var);
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
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
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
  (cr,exp,k,osyst,oshared,newvars) := 
  matchcontinue (cr1,cr2,var1,var2,ipos1,ipos2,e1,e2,isyst,ishared,mavars,negate,source)
    local
      DAE.ComponentRef acr,cr;
      BackendDAE.BinTree newvars;
      BackendDAE.Var avar,var;
      DAE.Exp ae,e;
      Integer aipos,i1,i2;
      Boolean b;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      
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
  // self generated var
  b := BackendVariable.isDummyDerVar(var);
  i := intAdd(i,Util.if_(b,1,0));
end calcAliasKey;

protected function selectAlias2
"function selectAlias2
  autor Frenkel TUD 2011-08
  helper for selectAlias."
  input DAE.ComponentRef acr;
  input DAE.ComponentRef cr;
  input BackendDAE.Var avar;
  input BackendDAE.Var ivar;
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
  BackendDAE.Var var;
algorithm
  Debug.fcall(Flags.DEBUG_ALIAS,BackendDump.debugStrCrefStrExpStr,("Alias Equation ",acr," = ",e," found (2).\n"));
  // merge fixed,start,nominal
  v1 := mergeAliasVars(ivar,avar,negate);
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
    
    // adrpo: TODO! FIXME! maybe we should use another heuristic here such as:
    //        use the value from the variable that is closer to the top of the 
    //        hierarchy i.e. A.B value has priority over X.Y.Z value!
    case (v as BackendDAE.VAR(varName=cr),false,SOME(sa),va as BackendDAE.VAR(varName=cra),false,SOME(sb),negate)
      equation
        true = intGt(ComponentReference.crefDepth(cr), ComponentReference.crefDepth(cra));
        // invert arguments
        v = mergeStartFixed(inAVar,fixeda,sva,inVar,fixed,sv,negate);
      then v;

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
        Debug.fprintln(Flags.FAILTRACE, "- BackendDAEOptimize.traverseIncidenceMatrixList failed");
      then
        fail();      
  end matchcontinue;
end traverseIncidenceMatrixList;

protected function traversingTimeEqnsFinder "
Author: Frenkel 2010-12"
  input tuple<DAE.Exp, tuple<Boolean,BackendDAE.Variables,BackendDAE.Variables,Boolean,Boolean> > inExp;
  output tuple<DAE.Exp, Boolean, tuple<Boolean,BackendDAE.Variables,BackendDAE.Variables,Boolean,Boolean> > outExp;
algorithm 
  outExp := matchcontinue(inExp)
    local
      DAE.Exp e;
      Boolean b,b1,b2;
      BackendDAE.Variables vars,knvars;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
    
    case((e as DAE.CREF(DAE.CREF_IDENT(ident = "time",subscriptLst = {}),_), (_,vars,knvars,b1,b2)))
      then ((e,false,(true,vars,knvars,b1,b2)));       
    case((e as DAE.CREF(cr,_), (_,vars,knvars,b1,b2)))
      equation
        (var::_,_::_)= BackendVariable.getVar(cr, knvars) "input variables stored in known variables are input on top level" ;
        true = BackendVariable.isVarOnTopLevelAndInput(var);
      then ((e,false,(true,vars,knvars,b1,b2)));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst = {_,_}), (_,vars,knvars,b1,b2))) then ((e,false,(true,vars,knvars,b1,b2) ));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "pre"), expLst = {_}), (_,vars,knvars,b1,b2))) then ((e,false,(true,vars,knvars,b1,b2) ));
    // case for finding simple equation in jacobians 
    // there are all known variables mark as input
    // and they are all time-depending  
    case((e as DAE.CREF(cr,_), (_,vars,knvars,true,b2)))
      equation
        (var::_,_::_)= BackendVariable.getVar(cr, knvars) "input variables stored in known variables are input on top level" ;
        DAE.INPUT() = BackendVariable.getVarDirection(var);
      then ((e,false,(true,vars,knvars,true,b2)));  
    // unkown var
    case((e as DAE.CREF(cr,_), (_,vars,knvars,b1,true)))
      equation
        (var::_,_::_)= BackendVariable.getVar(cr, vars);
      then ((e,false,(true,vars,knvars,b1,true)));          
    case((e,(b,vars,knvars,b1,b2))) then ((e,not b,(b,vars,knvars,b1,b2)));
    
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
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,knvars,true,false));
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,knvars,true,false));
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
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,knvars,false,false));
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,knvars,false,false));
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
 *
 */ 
public function removeFinalParametersPast
"function removeFinalParametersPast"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
protected
  BackendVarTransform.VariableReplacements repl,repl1;
algorithm
  outDAE := removeFinalParameters(inDAE);
  outRunMatching := true;
  // until remove simple equations does not update assignments and comps  
end removeFinalParametersPast;

public function removeFinalParameters
"function: removeFinalParameters
  autor Frenkel TUD"
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE odae;
algorithm
  odae := match (dae)
    local
      DAE.FunctionTree funcs;
      BackendDAE.Variables knvars,exobj,knvars1;
      BackendDAE.AliasVariables av,varsAliases;
      BackendDAE.EquationArray remeqns,remeqns1,inieqns,inieqns1;
      array<DAE.Constraint> constrs;
      Env.Cache cache;
      Env.Env env;      
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendVarTransform.VariableReplacements repl,repl1,repl2;
      BackendDAE.BackendDAEType btp;
      BackendDAE.EqSystems systs;
    case (BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,cache,env,funcs,einfo,eoc,btp,symjacs)))
      equation
        repl = BackendVarTransform.emptyReplacements();
        ((repl1,_)) = BackendVariable.traverseBackendDAEVars(knvars,removeFinalParametersFinder,(repl,knvars));
        (knvars1,repl2) = replaceFinalVars(1,knvars,repl1);
        Debug.fcall(Flags.DUMP_FP_REPL, BackendVarTransform.dumpReplacements, repl2);
        systs = List.map1(systs,removeFinalParametersWork,repl2);
      then
        BackendDAE.DAE(systs,BackendDAE.SHARED(knvars1,exobj,av,inieqns,remeqns,constrs,cache,env,funcs,einfo,eoc,btp,symjacs));
  end match;
end removeFinalParameters;

protected function removeFinalParametersWork
"function: removeFinalParametersWork
  autor Frenkel TUD"
  input BackendDAE.EqSystem syst;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match (syst,repl)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1;
      list<BackendDAE.Equation> eqns_1,lsteqns;
      BackendDAE.Matching matching;
    case (BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,matching=matching),_)
      equation
        lsteqns = BackendDAEUtil.equationList(eqns);
        eqns_1 = BackendVarTransform.replaceEquations(lsteqns, repl);
        eqns1 = BackendDAEUtil.listEquation(eqns_1);
      then
        BackendDAE.EQSYSTEM(vars,eqns1,NONE(),NONE(),matching);
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
        ((exp1, _)) = Expression.traverseExp(exp, BackendDAEUtil.replaceCrefsWithValues, (vars, varName));
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
      Option<DAE.VariableAttributes> attr,new_attr;
      
    case ((v as BackendDAE.VAR(varName=cr,bindExp=SOME(e),values=attr),(repl,numrepl)))
      equation
        (e1,true) = BackendVarTransform.replaceExp(e, repl, NONE());
        v1 = BackendVariable.setBindExp(v,e1);
        true = Expression.isConst(e1);
        repl_1 = BackendVarTransform.addReplacement(repl, cr, e1);
        (attr,repl_1) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,repl_1);
        v1 = BackendVariable.setVarAttributes(v1,attr);
      then ((v1,(repl_1,numrepl+1)));
    case ((v as BackendDAE.VAR(bindExp=SOME(e),values=attr),(repl,numrepl)))
      equation
        (e1,true) = BackendVarTransform.replaceExp(e, repl, NONE());
        v1 = BackendVariable.setBindExp(v,e1);
        (new_attr,repl) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,repl);
        v1 = BackendVariable.setVarAttributes(v1,new_attr);
      then ((v1,(repl,numrepl)));
    
    case  ((v as BackendDAE.VAR(values=attr),(repl,numrepl))) equation 
      (new_attr,repl) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,repl);
      v1 = BackendVariable.setVarAttributes(v,new_attr);      
      then ((v1,(repl,numrepl)));
  end matchcontinue;
end replaceFinalVarTraverser;

protected function traverseExpVisitorWrapper "help function to replaceFinalVarTraverser"
  input tuple<DAE.Exp,BackendVarTransform.VariableReplacements> inTpl;
  output tuple<DAE.Exp,BackendVarTransform.VariableReplacements> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local 
    DAE.Exp exp;
    BackendVarTransform.VariableReplacements repl;
    DAE.ComponentRef cr;
    
    case((exp as DAE.CREF(cr,_),repl)) equation
      (exp,_) = BackendVarTransform.replaceExp(exp,repl,NONE());      
    then ((exp,repl));
    
    case(inTpl) then inTpl;
  end matchcontinue;
end traverseExpVisitorWrapper;




/*  
 * remove paramters stuff
 *
 */
public function removeParameters
"function: removeParameters
  autor wbraun"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match (inDAE)
    local
      BackendDAE.Variables knvars,exobj,knvars1;
      BackendDAE.AliasVariables av,varsAliases;
      BackendDAE.EquationArray remeqns,remeqns1,inieqns,inieqns1;
      array<DAE.Constraint> constrs;
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendVarTransform.VariableReplacements repl,repl1,repl2;
      BackendDAE.BackendDAEType btp;
      BackendDAE.EqSystems systs;
    case (BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,cache,env,funcs,einfo,eoc,btp,symjacs)))
      equation      
        repl = BackendVarTransform.emptyReplacements();
        ((repl1,_)) = BackendVariable.traverseBackendDAEVars(knvars,removeParametersFinder,(repl,knvars));
        (knvars1,repl2) = replaceFinalVars(1,knvars,repl1);
        (knvars1,repl2) = replaceFinalVars(1,knvars1,repl2);
        Debug.fcall(Flags.DUMP_PARAM_REPL, BackendVarTransform.dumpReplacements, repl2);
        systs= List.map1(systs,removeParameterswork,repl2);
      then
        BackendDAE.DAE(systs,BackendDAE.SHARED(knvars1,exobj,av,inieqns,remeqns,constrs,cache,env,funcs,einfo,eoc,btp,symjacs));
  end match;
end removeParameters;

protected function removeParameterswork
"function: removeParameterswork
  autor wbraun"
  input BackendDAE.EqSystem isyst;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match (isyst,repl)
    local
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1;
      list<BackendDAE.Equation> eqns_1,lsteqns;
      BackendDAE.Matching matching;
    case (BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching),_)
      equation      
        lsteqns = BackendDAEUtil.equationList(eqns);
        (vars,_) = replaceFinalVars(1,vars,repl); // replacing variable attributes (e.g start) in unknown vars 
        eqns_1 = BackendVarTransform.replaceEquations(lsteqns, repl);
        eqns1 = BackendDAEUtil.listEquation(eqns_1);
      then
        BackendDAE.EQSYSTEM(vars,eqns1,NONE(),NONE(),matching);
  end match;
end removeParameterswork;

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
        ((exp1, _)) = Expression.traverseExp(exp, BackendDAEUtil.replaceCrefsWithValues, (vars, varName));
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
 *
 */
public function removeProtectedParameters
"function: removeProtectedParameters
  autor Frenkel TUD"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match (inDAE)
    local
      DAE.FunctionTree funcs;
      BackendDAE.Variables knvars,exobj,knvars_1,knvars_2;
      BackendDAE.AliasVariables av,varsAliases;
      BackendDAE.EquationArray remeqns,remeqns1,inieqns,inieqns1;
      array<DAE.Constraint> constrs;
      Env.Cache cache;
      Env.Env env;      
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendVarTransform.VariableReplacements repl,repl1;
      BackendDAE.BackendDAEType btp;
      BackendDAE.EqSystems systs;
    case (BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,cache,env,funcs,einfo,eoc,btp,symjacs)))
      equation      
        repl = BackendVarTransform.emptyReplacements();
        repl1 = BackendVariable.traverseBackendDAEVars(knvars,protectedParametersFinder,repl);
        Debug.fcall(Flags.DUMP_PP_REPL, BackendVarTransform.dumpReplacements, repl1);
        systs = List.map1(systs,removeProtectedParameterswork,repl1);
      then
        (BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,cache,env,funcs,einfo,eoc,btp,symjacs)));
  end match;
end removeProtectedParameters;

protected function removeProtectedParameterswork
"function: removeProtectedParameterswork
  autor Frenkel TUD"
  input BackendDAE.EqSystem isyst;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match (isyst,repl)
    local
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Variables vars,vars_1;
      BackendDAE.EquationArray eqns,eqns1;
      list<BackendDAE.Equation> eqns_1,lsteqns;
      BackendDAE.Matching matching;
    case (BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching),_)
      equation      
        lsteqns = BackendDAEUtil.equationList(eqns);
        eqns_1 = BackendVarTransform.replaceEquations(lsteqns, repl);
        eqns1 = BackendDAEUtil.listEquation(eqns_1);
      then
        BackendDAE.EQSYSTEM(vars,eqns1,NONE(),NONE(),matching);
  end match;
end removeProtectedParameterswork;

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
 * evaluate parameters stuff 
 * evaluate all parameter with evaluate=true Annotation
 */
public function evaluateParametersPast
"function evaluateParametersPast"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
protected
  BackendVarTransform.VariableReplacements repl,repl1;
algorithm
  outDAE := evaluateParameters(inDAE);
  outRunMatching := true;
  // until remove simple equations does not update assignments and comps  
end evaluateParametersPast;

public function evaluateParameters
"function: evaluateParameters
  autor Frenkel TUD"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match (inDAE)
    local
      DAE.FunctionTree funcs;
      BackendDAE.Variables knvars,exobj,knvars_1,knvars_2;
      BackendDAE.AliasVariables av,varsAliases;
      BackendDAE.EquationArray remeqns,remeqns1,inieqns,inieqns1;
      array<DAE.Constraint> constrs;
      Env.Cache cache;
      Env.Env env;      
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.BackendDAEType btp;
      list<BackendDAE.Var> vlst;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      list<list<Integer>> comps,mlst;
      array<Integer> v;
      Integer size;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
    case (BackendDAE.DAE(systs,shared as BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,cache,env,funcs,einfo,eoc,btp,symjacs)))
      equation     
        // sort parameters
        size = BackendVariable.varsSize(knvars);
        ((_,_,mlst,mt)) = BackendVariable.traverseBackendDAEVars(knvars,getParameterIncidenceMatrix,(knvars,1,{},arrayCreate(size,{})));
        v = listArray(List.intRange(size));
        m = listArray(listReverse(mlst));
        comps = BackendDAETransform.tarjanAlgorithm(m, mt, v, v);        
        // evaluate vars with bind expression consists of evaluated vars
        (knvars,repl,cache) = traverseVariablesSorted(comps,knvars,BackendVarTransform.emptyReplacements(),BackendVarTransform.emptyReplacements(),cache,env);
        Debug.fcall(Flags.DUMP_EA_REPL, BackendVarTransform.dumpReplacements, repl);
        // do replacements in initial equations
        eqnslst = BackendDAEUtil.equationList(inieqns);
        eqnslst = BackendVarTransform.replaceEquations(eqnslst, repl);
        inieqns = BackendDAEUtil.listEquation(eqnslst);
        // do replacements in simple equations
        eqnslst = BackendDAEUtil.equationList(remeqns);
        eqnslst = BackendVarTransform.replaceEquations(eqnslst, repl);
        remeqns = BackendDAEUtil.listEquation(eqnslst);
        // do replacements in systems        
        systs = List.map1(systs,removeProtectedParameterswork,repl);
      then
        BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,cache,env,funcs,einfo,eoc,btp,symjacs));
  end match;
end evaluateParameters;

protected function traverseVariablesSorted
  input list<list<Integer>> inComps;
  input BackendDAE.Variables inKnVars;
  input BackendVarTransform.VariableReplacements repl;
  input BackendVarTransform.VariableReplacements replEvaluate;
  input Env.Cache iCache;
  input Env.Env env; 
  output BackendDAE.Variables oKnVars;
  output BackendVarTransform.VariableReplacements oReplEvaluate;
  output Env.Cache oCache;
algorithm
  (oKnVars,oReplEvaluate,oCache) := matchcontinue(inComps,inKnVars,repl,replEvaluate,iCache,env)
    local
      BackendDAE.Variables knvars;
      BackendDAE.Var v;
      BackendVarTransform.VariableReplacements repl1,evrepl;
      String str;  
      Integer c;
      list<list<Integer>> rest;
      Env.Cache cache;
      list<DAE.ComponentRef> crlst;
      list<Integer> ilst;
      list<BackendDAE.Var> vlst;
      
    case({},_,_,_,_,_)
      then
        (inKnVars,replEvaluate,iCache);
    case({c}::rest,_,_,_,_,_)
      equation
        v = BackendVariable.getVarAt(inKnVars,c);
        (knvars,cache,repl1,evrepl) = evaluateParameterBindings(v,c,inKnVars,repl,replEvaluate,iCache,env);
        (knvars,repl1,cache) =  traverseVariablesSorted(rest,knvars,repl1,evrepl,cache,env);
      then
        (knvars,repl1,cache);
    case (ilst::rest,_,_,_,_,_)
      equation
        vlst = List.map1r(ilst,BackendVariable.getVarAt,inKnVars);
        crlst = List.map(vlst,BackendVariable.varCref); 
        str = stringDelimitList(List.map(crlst,ComponentReference.printComponentRefStr),"\n");  
        str = stringAppendList({"BackendDAEOptimize.traverseVariablesSorted faild because of strong connected Block in Parameters!\n",str,"\n"});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end matchcontinue;
end traverseVariablesSorted;


protected function evaluateParameterBindings
  input BackendDAE.Var var;
  input Integer index;
  input BackendDAE.Variables inKnVars;
  input BackendVarTransform.VariableReplacements irepl;
  input BackendVarTransform.VariableReplacements ireplEvaluate;
  input Env.Cache iCache;
  input Env.Env env; 
  output BackendDAE.Variables oKnVars;
  output Env.Cache oCache;  
  output BackendVarTransform.VariableReplacements orepl;
  output BackendVarTransform.VariableReplacements oreplEvaluate;
algorithm
  (oKnVars,oCache,orepl,oreplEvaluate) := matchcontinue(var,index,inKnVars,irepl,ireplEvaluate,iCache,env)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      DAE.Exp e,e1;
      Option<DAE.VariableAttributes> dae_var_attr;
      BackendVarTransform.VariableReplacements repl,repl1;
      list<BackendDAE.Var> vlst;
      SCode.Comment comment;
      Env.Cache cache;
      Values.Value value;
      BackendDAE.Variables knvars;
      Boolean b;
    // Parameter with evaluate=true
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),bindExp=SOME(e),comment=SOME(comment)),_,_,_,_,_,_)
      equation
        true = hasEvaluateAnnotation(comment);  
        // applay replacements
        (e,_) = BackendVarTransform.replaceExp(e, irepl, NONE());
        // evaluate expression
        (cache, value,_) = Ceval.ceval(iCache, env, e, false,NONE(),Ceval.NO_MSG());
        e1 = ValuesUtil.valueExp(value);
        // set bind value
        v = BackendVariable.setBindExp(var,e1);
        v = BackendVariable.setVarFinal(v, true);
        // update Vararray
        knvars = BackendVariable.addVar(v, inKnVars);
        // save replacement
        repl = BackendVarTransform.addReplacement(irepl, cr, e);
        repl1 = BackendVarTransform.addReplacement(ireplEvaluate, cr, e1);
      then 
        (knvars,cache,repl,repl1);
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),values=dae_var_attr,comment=SOME(comment)),_,_,_,_,_,_)
      equation
        true = hasEvaluateAnnotation(comment);
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        // applay replacements
        (e,_) = BackendVarTransform.replaceExp(e, irepl, NONE());
        // evaluate expression
        (cache, value,_) = Ceval.ceval(iCache, env, e, false,NONE(),Ceval.NO_MSG());
        e1 = ValuesUtil.valueExp(value);
        // set bind value
        v = BackendVariable.setVarStartValue(var,e1);
        v = BackendVariable.setVarFinal(v, true);
        // update Vararray
        knvars = BackendVariable.addVar(v, inKnVars);
        // save replacement
        repl = BackendVarTransform.addReplacement(irepl, cr, e);
        repl1 = BackendVarTransform.addReplacement(ireplEvaluate, cr, e1);         
      then 
        (knvars,cache,repl,repl1);
    // Parameter with bind expression uses only paramter with evaluate=true
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),bindExp=SOME(e)),_,_,_,_,_,_)
      equation
        // applay replacements
        (e,true) = BackendVarTransform.replaceExp(e, ireplEvaluate, NONE());
        false = Expression.expHasCrefs(e);
        // evaluate expression
        (cache, value,_) = Ceval.ceval(iCache, env, e, false,NONE(),Ceval.NO_MSG());
        e1 = ValuesUtil.valueExp(value);
        // set bind value
        v = BackendVariable.setBindExp(var,e1);
        v = BackendVariable.setVarFinal(v, true);
        // update Vararray
        knvars = BackendVariable.addVar(v, inKnVars);
        // save replacement
        repl = BackendVarTransform.addReplacement(irepl, cr, e);
        repl1 = BackendVarTransform.addReplacement(ireplEvaluate, cr, e1);         
      then 
        (knvars,cache,repl,repl1);
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),values=dae_var_attr),_,_,_,_,_,_)
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        // applay replacements
        (e,true) = BackendVarTransform.replaceExp(e, ireplEvaluate, NONE());
        false = Expression.expHasCrefs(e);
        // evaluate expression
        (cache, value,_) = Ceval.ceval(iCache, env, e, false,NONE(),Ceval.NO_MSG());
        e1 = ValuesUtil.valueExp(value);
        // set bind value
        v = BackendVariable.setVarStartValue(var,e1);
        v = BackendVariable.setVarFinal(v, true);
        // update Vararray
        knvars = BackendVariable.addVar(v, inKnVars);
        // save replacement
        repl = BackendVarTransform.addReplacement(irepl, cr, e);
        repl1 = BackendVarTransform.addReplacement(ireplEvaluate, cr, e1);         
      then 
        (knvars,cache,repl,repl1);      
    // all other paramter
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),bindExp=SOME(e)),_,_,_,_,_,_)
      equation
        // applay replacements
        (e,b) = BackendVarTransform.replaceExp(e, ireplEvaluate, NONE());   
        (e,_) = ExpressionSimplify.condsimplify(b, e);
        // set bind value
        v = Debug.bcallret2(b, BackendVariable.setVarStartValue, var,e, var);
        // update Vararray
        knvars = Debug.bcallret2(b, BackendVariable.addVar, v, inKnVars, inKnVars);
        // save replacement
        repl = BackendVarTransform.addReplacement(irepl, cr, e);
      then 
        (knvars,iCache,repl,ireplEvaluate);
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),values=dae_var_attr),_,_,_,_,_,_)
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        // applay replacements
        (e,b) = BackendVarTransform.replaceExp(e, ireplEvaluate, NONE());   
        (e,_) = ExpressionSimplify.condsimplify(b, e);
        // set bind value
        v = Debug.bcallret2(b, BackendVariable.setVarStartValue, var,e, var);
        // update Vararray
        knvars = Debug.bcallret2(b, BackendVariable.addVar, v, inKnVars, inKnVars);
        // save replacement
        repl = BackendVarTransform.addReplacement(irepl, cr, e);
      then 
        (knvars,iCache,repl,ireplEvaluate);
    // other vars
    else 
      (inKnVars,iCache,irepl,ireplEvaluate);
  end matchcontinue;
end evaluateParameterBindings;

protected function getParameterIncidenceMatrix
  input tuple<BackendDAE.Var,tuple<BackendDAE.Variables,Integer,list<list<Integer>>,BackendDAE.IncidenceMatrixT>> inTp;
  output tuple<BackendDAE.Var,tuple<BackendDAE.Variables,Integer,list<list<Integer>>,BackendDAE.IncidenceMatrixT>> outTpl;
algorithm
  outTpl := matchcontinue (inTp)
    local
      BackendDAE.Variables knvars;
      BackendDAE.Var v;
      DAE.Exp e;
      Option<DAE.VariableAttributes> dae_var_attr;
      list<Integer> ilst;
      Integer index;
      list<list<Integer>> m;
      BackendDAE.IncidenceMatrixT mt;

    case ((v as BackendDAE.VAR(varKind=BackendDAE.PARAM(),bindExp=SOME(e)),(knvars,index,m,mt)))
      equation
         ((_,(_,ilst))) = Expression.traverseExpTopDown(e, BackendDAEUtil.traversingincidenceRowExpFinder, (knvars,{}));
         ilst = index::ilst;
         mt = List.fold1(ilst,Util.arrayCons,index,mt);
      then 
        ((v,(knvars,index+1,ilst::m,mt)));

    case ((v as BackendDAE.VAR(varKind=BackendDAE.PARAM(),values=dae_var_attr),(knvars,index,m,mt)))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        ((_,(_,ilst))) = Expression.traverseExpTopDown(e, BackendDAEUtil.traversingincidenceRowExpFinder, (knvars,{}));
        ilst = index::ilst;
        mt = List.fold1(ilst,Util.arrayCons,index,mt);
      then 
        ((v,(knvars,index+1,ilst::m,mt)));

    case ((v,(knvars,index,m,mt)))
      equation
        ilst = {index};
        mt = arrayUpdate(mt,index,ilst);
      then 
        ((v,(knvars,index+1,ilst::m,mt)));
  end matchcontinue;
end getParameterIncidenceMatrix;

protected function hasEvaluateAnnotation
  input SCode.Comment comment;
  output Boolean b;
algorithm
  b := match(comment)
    local
      SCode.Annotation anno;
      list<SCode.Annotation> annos;
    case (SCode.COMMENT(annotation_=SOME(anno)))
      then
        SCode.hasBooleanNamedAnnotation({anno},"Evaluate");
    case(SCode.CLASS_COMMENT(annotations=annos))
      then 
        SCode.hasBooleanNamedAnnotation(annos,"Evaluate");
    else then false;
  end match;
end hasEvaluateAnnotation;



/* 
 * remove equal function calls equations stuff
 *
 */
public function removeEqualFunctionCallsPast
"function removeEqualFunctionCallsPast"
    input BackendDAE.BackendDAE inDAE;
    output BackendDAE.BackendDAE outDAE;
    output Boolean outRunMatching;
protected
  Option<BackendDAE.IncidenceMatrix> om,omT;
  Boolean b;
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE({syst},shared) := inDAE;
  (syst,shared,b) := removeEqualFunctionCalls1(syst,shared);
  (syst,_,_) := BackendDAEUtil.getIncidenceMatrixfromOption(syst,shared,BackendDAE.NORMAL());
  outRunMatching := b; // until does not update assignments and comps  
  outDAE := BackendDAE.DAE({syst},shared);
end removeEqualFunctionCallsPast;

public function removeEqualFunctionCalls
"function: removeEqualFunctionCalls
  autor: Frenkel TUD 2011-04
  This function detect equal function call on the form a=f(b) and c=f(b) 
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE odae;
algorithm
  odae := BackendDAEUtil.mapEqSystem(dae,removeEqualFunctionCallsWork);
end removeEqualFunctionCalls;

protected function removeEqualFunctionCallsWork
"function: removeEqualFunctionCalls
  autor: Frenkel TUD 2011-04
  This function detect equal function call on the form a=f(b) and c=f(b) 
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared,_) := removeEqualFunctionCalls1(syst,shared);
end removeEqualFunctionCallsWork;

protected function removeEqualFunctionCalls1
"function: removeEqualFunctionCalls
  autor: Frenkel TUD 2011-04
  This function detect equal function call on the form a=f(b) and c=f(b) 
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Boolean optimized;
algorithm
  (osyst,oshared,optimized) := match (isyst,ishared)
    local
      BackendDAE.IncidenceMatrix m,m_1,m_2;
      BackendDAE.IncidenceMatrixT mT,mT_1,mT_2;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1,ineq;
      list<Integer> changed;
      Boolean b;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;

    case (syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared)
      equation
        (syst,m,mT) = BackendDAEUtil.getIncidenceMatrixfromOption(syst,shared,BackendDAE.NORMAL());
        // check equations
        (m_1,(mT_1,_,eqns1,changed)) = traverseIncidenceMatrix(m,removeEqualFunctionCallFinder,(mT,vars,eqns,{}));
        b = intGt(listLength(changed),0);
        // update arrayeqns and algorithms, collect info for wrappers
        syst = BackendDAE.EQSYSTEM(vars,eqns,SOME(m_1),SOME(mT_1),BackendDAE.NO_MATCHING());
        syst = BackendDAEUtil.updateIncidenceMatrix(syst,shared,changed);
      then (syst,shared,b);
  end match;
end removeEqualFunctionCalls1;

protected function removeEqualFunctionCallFinder
"autor: Frenkel TUD 2010-12"
 input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix, tuple<BackendDAE.IncidenceMatrixT,BackendDAE.Variables,BackendDAE.EquationArray,list<Integer>>> inTpl;
 output tuple<list<Integer>,BackendDAE.IncidenceMatrix, tuple<BackendDAE.IncidenceMatrixT,BackendDAE.Variables,BackendDAE.EquationArray,list<Integer>>> outTpl;
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
      BackendDAE.Var var;
      DAE.ComponentRef cr;
      DAE.Exp exp,e1,e2,ecr;
      list<BackendDAE.Value> expvars,controleqns,expvars1;
      list<list<BackendDAE.Value>> expvarseqns;
      
    case ((elem,pos,m,(mT,vars,eqns,changed)))
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
        expvars = BackendDAEUtil.incidenceRowExp(exp,vars, {},BackendDAE.NORMAL());
        // print("expvars "); BackendDump.debuglst((expvars,intString," ","\n"));
        (expvars1::expvarseqns) = List.map1(expvars,varEqns,(pos,mT));
        // print("expvars1 "); BackendDump.debuglst((expvars1,intString," ","\n"));;
        controleqns = getControlEqns(expvars1,expvarseqns);
        // print("controleqns "); BackendDump.debuglst((controleqns,intString," ","\n"));
        (eqns1,changed) = removeEqualFunctionCall(controleqns,ecr,exp,eqns,changed);
        //print("changed1 "); BackendDump.debuglst((changed1,intString," ","\n"));
        //print("changed2 "); BackendDump.debuglst((changed2,intString," ","\n"));
        // print("Next\n");
      then (({},m,(mT,vars,eqns1,changed)));
    case ((elem,pos,m,(mT,vars,eqns,changed)))
      then (({},m,(mT,vars,eqns,changed))); 
  end matchcontinue;
end removeEqualFunctionCallFinder;

protected function functionCallEqn
"function functionCallEqn
  autor Frenkel TUD 2011-04"
  input DAE.Exp ie1;
  input DAE.Exp ie2;
  input BackendDAE.Variables inVars;
  output DAE.Exp outECr;
  output DAE.Exp outExp;
algorithm
  (outECr,outExp) := match (ie1,ie2,inVars)
      local
        DAE.ComponentRef cr;
        DAE.Exp e,e1,e2;
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
  input list<Integer> ichanged;
  output BackendDAE.EquationArray outEqns;
  output list<Integer> outEqsLst;
algorithm
  (outEqns,outEqsLst):=
  matchcontinue (inEqsLst,inExp,inECr,inEqns,ichanged)
    local
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn,eqn1;
      Integer pos,pos_1,i;
      list<Integer> rest,changed;
    case ({},_,_,_,_) then (inEqns,ichanged);
    case (pos::rest,_,_,_,_)
      equation
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(inEqns,pos_1);
        //BackendDump.dumpEqns({eqn});
        //BackendDump.debugStrExpStrExpStr(("Repalce ",inExp," with ",inECr,"\n"));
        (eqn1,(_,_,i)) = BackendDAETransform.traverseBackendDAEExpsEqnWithSymbolicOperation(eqn, replaceExp, (inECr,inExp,0));
        //BackendDump.dumpEqns({eqn1});
        //print("i="); print(intString(i)); print("\n");
        true = intGt(i,0);
        eqns =  BackendEquation.equationSetnth(inEqns,pos_1,eqn1);
        changed = List.consOnTrue(not listMember(pos,ichanged),pos,ichanged);
        (eqns,changed) = removeEqualFunctionCall(rest,inExp,inECr,eqns,changed);
      then (eqns,changed);
    case (pos::rest,_,_,_,_)
      equation
        (eqns,changed) = removeEqualFunctionCall(rest,inExp,inECr,inEqns,ichanged);
      then (eqns,changed);
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
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
protected
  Option<BackendDAE.IncidenceMatrix> om,omT;
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
algorithm
  (outDAE as BackendDAE.DAE({syst},shared)) := removeUnusedParameter(inDAE);
  (syst,_,_) := BackendDAEUtil.getIncidenceMatrixfromOption(syst,shared,BackendDAE.NORMAL());
  outRunMatching := false;   
end removeUnusedParameterPast;

public function removeUnusedParameter
"function: removeUnusedParameter
  autor: Frenkel TUD 2011-04
  This function remove unused parameters  
  in BackendDAE.BackendDAE to get speed up for compilation of
  target code"
  input BackendDAE.BackendDAE inDlow;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match (inDlow)
    local
      BackendDAE.Variables vars,knvars,exobj,avars,knvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns;
      array<DAE.Constraint> constrs;
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.SymbolicJacobians symjacs;
      list<BackendDAE.WhenClause> whenClauseLst;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.EqSystems eqs;
      BackendDAE.BackendDAEType btp;      
    case (BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars,exobj,aliasVars as BackendDAE.ALIASVARS(aliasVars=avars),inieqns,remeqns,constrs,cache,env,funcs,einfo as BackendDAE.EVENT_INFO(whenClauseLst=whenClauseLst),eoc,btp,symjacs)))
      equation
        knvars1 = BackendDAEUtil.emptyVars();
        ((knvars,knvars1)) = BackendVariable.traverseBackendDAEVars(knvars,copyNonParamVariables,(knvars,knvars1));
        ((_,knvars1)) = List.fold1(eqs,BackendDAEUtil.traverseBackendDAEExpsEqSystem,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsVars(knvars,checkUnusedParameter,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsVars(avars,checkUnusedParameter,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsEqns(remeqns,checkUnusedParameter,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsEqns(inieqns,checkUnusedParameter,(knvars,knvars1));
        (_,(_,knvars1)) = BackendDAETransform.traverseBackendDAEExpsWhenClauseLst(whenClauseLst,checkUnusedParameter,(knvars,knvars1));
      then 
        BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,constrs,cache,env,funcs,einfo,eoc,btp,symjacs));
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
      list<DAE.Var> varLst;
      DAE.Ident ident;
      list<BackendDAE.Var> backendVars;
      BackendDAE.Var var;
      DAE.ReductionIterators riters;
    
    // special case for time, it is never part of the equation system  
    case ((e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(vars,vars1)))
      then ((e, (vars,vars1)));
    
    // Special Case for Records
    case ((e as DAE.CREF(componentRef = cr,ty= DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),(vars,vars1)))
      equation
        expl = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        ((_,(vars,vars1))) = Expression.traverseExpList(expl,checkUnusedParameterExp,(vars,vars1));
      then
        ((e, (vars,vars1)));

    // Special Case for Arrays
    case ((e as DAE.CREF(ty = DAE.T_ARRAY(ty=_)),(vars,vars1)))
      equation
        ((e1,(_,true))) = BackendDAEUtil.extendArrExp((e,(NONE(),false)));
        ((_,(vars,vars1))) = Expression.traverseExp(e1,checkUnusedParameterExp,(vars,vars1));
      then
        ((e, (vars,vars1)));
    
    // case for functionpointers    
    case ((e as DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC(builtin=_)),(vars,vars1)))
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
    output BackendDAE.BackendDAE outDAE;
    output Boolean outRunMatching;
protected
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
algorithm
  (outDAE as BackendDAE.DAE({syst},shared)) := removeUnusedVariables(inDAE);
  (syst,_,_) := BackendDAEUtil.getIncidenceMatrixfromOption(syst,shared,BackendDAE.NORMAL());
  outRunMatching := false;   
end removeUnusedVariablesPast;

public function removeUnusedVariables
"function: removeUnusedVariables
  autor: Frenkel TUD 2011-04
  This function remove unused variables  
  from BackendDAE.BackendDAE to get speed up for compilation of
  target code"
  input BackendDAE.BackendDAE inDlow;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match (inDlow)
    local
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcs;
      BackendDAE.Variables vars,knvars,exobj,avars,knvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns;
      array<DAE.Constraint> constrs;
      BackendDAE.EventInfo einfo;
      list<BackendDAE.WhenClause> whenClauseLst;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.EqSystems eqs;    
      BackendDAE.BackendDAEType btp;
      
    case (BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars,exobj,aliasVars as BackendDAE.ALIASVARS(aliasVars=avars),inieqns,remeqns,constrs,cache,env,funcs,einfo as BackendDAE.EVENT_INFO(whenClauseLst=whenClauseLst),eoc,btp,symjacs)))
      equation
        knvars1 = BackendDAEUtil.emptyVars();
        ((_,knvars1)) = List.fold1(eqs,BackendDAEUtil.traverseBackendDAEExpsEqSystem,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsVars(knvars,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsVars(avars,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsEqns(remeqns,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsEqns(inieqns,checkUnusedVariables,(knvars,knvars1));
        (_,(_,knvars1)) = BackendDAETransform.traverseBackendDAEExpsWhenClauseLst(whenClauseLst,checkUnusedVariables,(knvars,knvars1));
      then 
        BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,constrs,cache,env,funcs,einfo,eoc,btp,symjacs));
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
      list<DAE.Var> varLst;
      DAE.Ident ident;
      list<BackendDAE.Var> backendVars;
      BackendDAE.Var var;
      DAE.ReductionIterators riters;
    
    // special case for time, it is never part of the equation system  
    case ((e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(vars,vars1)))
      then ((e, (vars,vars1)));
    
    // Special Case for Records
    case ((e as DAE.CREF(componentRef = cr,ty= DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),(vars,vars1)))
      equation
        expl = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        ((_,(vars,vars1))) = Expression.traverseExpList(expl,checkUnusedVariablesExp,(vars,vars1));
      then
        ((e, (vars,vars1)));

    // Special Case for Arrays
    case ((e as DAE.CREF(ty = DAE.T_ARRAY(ty=_)),(vars,vars1)))
      equation
        ((e1,(_,true))) = BackendDAEUtil.extendArrExp((e,(NONE(),false)));
        ((_,(vars,vars1))) = Expression.traverseExp(e1,checkUnusedVariablesExp,(vars,vars1));
      then
        ((e, (vars,vars1)));
    
    // case for functionpointers    
    case ((e as DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC(builtin=_)),(vars,vars1)))
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
 * remove unused functions
 */

public function removeUnusedFunctionsPast
"function removeUnusedFunctionsPast"
    input BackendDAE.BackendDAE inDAE;
    output BackendDAE.BackendDAE outDAE;
    output Boolean outRunMatching;
protected
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
algorithm
  outDAE := removeUnusedFunctions(inDAE);
  outRunMatching := false;   
end removeUnusedFunctionsPast;

public function removeUnusedFunctions
"function: removeUnusedFunctions
  autor: Frenkel TUD 2012-03
  This function remove unused functions  
  from DAE.FunctionTree to get speed up for compilation of
  target code"
  input BackendDAE.BackendDAE inDlow;
  output BackendDAE.BackendDAE outDlow;   
algorithm
  outDlow := match (inDlow)
    local
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcs,usedfuncs;
      BackendDAE.Variables vars,knvars,exobj,avars,knvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns;
      array<DAE.Constraint> constrs;
      BackendDAE.EventInfo einfo;
      list<BackendDAE.WhenClause> whenClauseLst;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.EqSystems eqs;    
      BackendDAE.BackendDAEType btp;
      
    case (BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars,exobj,aliasVars as BackendDAE.ALIASVARS(aliasVars=avars),inieqns,remeqns,constrs,cache,env,funcs,einfo as BackendDAE.EVENT_INFO(whenClauseLst=whenClauseLst),eoc,btp,symjacs)))
      equation
        usedfuncs = copyRecordConstructorAndExternalObjConstructorDestructor(funcs);
        ((_,usedfuncs)) = List.fold1(eqs,BackendDAEUtil.traverseBackendDAEExpsEqSystem,checkUnusedFunctions,(funcs,usedfuncs));
        ((_,usedfuncs)) = BackendDAEUtil.traverseBackendDAEExpsVars(knvars,checkUnusedFunctions,(funcs,usedfuncs));
        ((_,usedfuncs)) = BackendDAEUtil.traverseBackendDAEExpsVars(exobj,checkUnusedFunctions,(funcs,usedfuncs));        
        ((_,usedfuncs)) = BackendDAEUtil.traverseBackendDAEExpsVars(avars,checkUnusedFunctions,(funcs,usedfuncs));
        ((_,usedfuncs)) = BackendDAEUtil.traverseBackendDAEExpsEqns(remeqns,checkUnusedFunctions,(funcs,usedfuncs));
        ((_,usedfuncs)) = BackendDAEUtil.traverseBackendDAEExpsEqns(inieqns,checkUnusedFunctions,(funcs,usedfuncs));
        (_,(_,usedfuncs)) = BackendDAETransform.traverseBackendDAEExpsWhenClauseLst(whenClauseLst,checkUnusedFunctions,(funcs,usedfuncs));
        //traverse Symbolic jacobians
        ((funcs,usedfuncs)) = removeUnusedFunctionsSymJacs(symjacs,(funcs,usedfuncs));
      then 
        BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,cache,env,usedfuncs,einfo,eoc,btp,symjacs));
  end match;
end removeUnusedFunctions;

protected function copyRecordConstructorAndExternalObjConstructorDestructor
  input DAE.FunctionTree inFunctions;
  output DAE.FunctionTree outFunctions;
protected
  list<DAE.Function> funcelems;
algorithm
  funcelems := DAEUtil.getFunctionList(inFunctions);
  outFunctions := List.fold(funcelems,copyRecordConstructorAndExternalObjConstructorDestructorFold,DAEUtil.emptyFuncTree);
end copyRecordConstructorAndExternalObjConstructorDestructor;

protected function copyRecordConstructorAndExternalObjConstructorDestructorFold
  input DAE.Function inFunction;
  input DAE.FunctionTree inFunctions;
  output DAE.FunctionTree outFunctions;
algorithm
  outFunctions :=     
  matchcontinue (inFunction,inFunctions)
    local  
      DAE.Function f;
      DAE.FunctionTree funcs,funcs1;
      Absyn.Path path;
    // copy record constructors
    case (f as DAE.RECORD_CONSTRUCTOR(path=path),funcs)
      equation
         funcs1 = DAEUtil.avlTreeAdd(funcs, path, SOME(f));
       then
        funcs1;
    // copy external objects constructors/destructors
    case (f as DAE.FUNCTION(path = path),funcs)
      equation
         true = boolOr(
                  stringEq(Absyn.pathLastIdent(path), "constructor"), 
                  stringEq(Absyn.pathLastIdent(path), "destructor"));
         funcs1 = DAEUtil.avlTreeAdd(funcs, path, SOME(f));
       then
        funcs1;
    case (f,funcs) then funcs;
  end matchcontinue;
end copyRecordConstructorAndExternalObjConstructorDestructorFold;

protected function removeUnusedFunctionsSymJacs
  input BackendDAE.SymbolicJacobians inSymJacs;
  input tuple<DAE.FunctionTree,DAE.FunctionTree> inFuncsTpl;
  output tuple<DAE.FunctionTree,DAE.FunctionTree> outFuncsTpl;
algorithm
  outFuncsTpl := matchcontinue(inSymJacs,inFuncsTpl)
  local
    BackendDAE.BackendDAE bdae;
    BackendDAE.SymbolicJacobian oneJac;
    BackendDAE.SymbolicJacobians rest;
    DAE.FunctionTree funcs, usedfuncs, usedfuncs2;
    list<tuple<DAE.AvlKey, DAE.AvlValue>> treelst;
    case ({},(funcs,usedfuncs)) then ((funcs,usedfuncs));
    case ((bdae,_,_,_,_)::rest,(funcs,usedfuncs))
      equation
         bdae = BackendDAEUtil.addBackendDAEFunctionTree(funcs,bdae);
         BackendDAE.DAE(shared=BackendDAE.SHARED(functionTree=usedfuncs2)) = removeUnusedFunctions(bdae);
         treelst = DAEUtil.avlTreeToList(usedfuncs2);
         usedfuncs = DAEUtil.avlTreeAddLst(treelst, usedfuncs);
      then removeUnusedFunctionsSymJacs(rest,(funcs,usedfuncs));
      //else then inFuncsTpl;
  end matchcontinue;
end removeUnusedFunctionsSymJacs;

protected function checkUnusedFunctions
  input tuple<DAE.Exp, tuple<DAE.FunctionTree,DAE.FunctionTree>> inTpl;
  output tuple<DAE.Exp, tuple<DAE.FunctionTree,DAE.FunctionTree>> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local  
      DAE.Exp exp;
      DAE.FunctionTree func,usefuncs,usefuncs1;
    case ((exp,(func,usefuncs)))
      equation
         ((_,(_,usefuncs1))) = Expression.traverseExp(exp,checkUnusedFunctionsExp,(func,usefuncs));
       then
        ((exp,(func,usefuncs1)));
    case inTpl then inTpl;
  end matchcontinue;
end checkUnusedFunctions;

protected function checkUnusedFunctionsExp
  input tuple<DAE.Exp, tuple<DAE.FunctionTree,DAE.FunctionTree>> inTuple;
  output tuple<DAE.Exp, tuple<DAE.FunctionTree,DAE.FunctionTree>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      DAE.FunctionTree func,usefuncs,usefuncs1,usefuncs2;
      Absyn.Path path;
      Option<DAE.Function> f;    
      list<DAE.Element> body;  
    
    // already there
    case ((e as DAE.CALL(path = path),(func,usefuncs)))
      equation
         _ = DAEUtil.avlTreeGet(usefuncs, path);
      then
        ((e, (func,usefuncs)));

    // add it
    case ((e as DAE.CALL(path = path),(func,usefuncs)))
      equation
         (f,body) = getFunctionAndBody(path,func);
         usefuncs1 = DAEUtil.avlTreeAdd(usefuncs, path, f);
         // print("add function " +& Absyn.pathStringNoQual(path) +& "\n");
         (_,(_,usefuncs2)) = DAEUtil.traverseDAE2(body,checkUnusedFunctions,(func,usefuncs1));
      then
        ((e, (func,usefuncs2)));
        
    // already there
    case ((e as DAE.PARTEVALFUNCTION(path = path),(func,usefuncs)))
      equation
         _ = DAEUtil.avlTreeGet(usefuncs, path);
      then
        ((e, (func,usefuncs)));
        
    // add it
    case ((e as DAE.PARTEVALFUNCTION(path = path),(func,usefuncs)))
      equation
         (f as SOME(_)) = DAEUtil.avlTreeGet(func, path);
         usefuncs1 = DAEUtil.avlTreeAdd(usefuncs, path, f);
      then
        ((e, (func,usefuncs1)));
            
    case inTuple then inTuple;
  end matchcontinue;
end checkUnusedFunctionsExp;

protected function getFunctionAndBody
"function: getFunctionBody
  returns the body of a function"
  input Absyn.Path inPath;
  input DAE.FunctionTree fns;
  output Option<DAE.Function> outFn;
  output list<DAE.Element> outFnBody;
algorithm
  (outFn,outFnBody) := matchcontinue(inPath,fns)
    local
      Absyn.Path p;
      Option<DAE.Function> fn;
      list<DAE.Element> body;
      DAE.FunctionTree ftree;
      String msg;
    // handle normal functions
    case(p,ftree)
      equation
        (fn as SOME(DAE.FUNCTION(functions = DAE.FUNCTION_DEF(body = body)::_))) = DAEUtil.avlTreeGet(ftree,p);
      then (fn,body);
    // adrpo: also the external functions!
    case(p,ftree)
      equation
        (fn as SOME(DAE.FUNCTION(functions = DAE.FUNCTION_EXT(body = body)::_))) = DAEUtil.avlTreeGet(ftree,p);
      then (fn,body);
    
    case(p,_)
      equation
        msg = "BackendDAEOptimize.getFunctionBody failed for function " +& Absyn.pathStringNoQual(p);
        // print(msg +& "\n");
        Debug.fprintln(Flags.FAILTRACE, msg);
        // Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then
        fail();
  end matchcontinue;
end getFunctionAndBody;

/* 
 * constant jacobians. Linear system of equations (A x = b) where
 * A and b are constants.
 */

public function constantLinearSystem
"function constantLinearSystem"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
algorithm
  (outDAE,outRunMatching) := BackendDAEUtil.mapEqSystemAndFold(inDAE,constantLinearSystem0,false);
end constantLinearSystem;

protected function constantLinearSystem0
"function constantLinearSystem"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared,Boolean> sharedChanged;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> osharedChanged;
algorithm
  (osyst,osharedChanged) := 
    matchcontinue(isyst,sharedChanged)
    local
      DAE.FunctionTree funcs;
      BackendDAE.Variables vars,knvars,exobj,avars,vars1,knvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1;
      array<DAE.Constraint> constrs;
      Env.Cache cache;
      Env.Env env;      
      BackendDAE.EventInfo einfo;
      list<BackendDAE.WhenClause> whenClauseLst;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
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
      BackendDAE.EqSystem syst;
      
    case (syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)),(shared, b1))
      equation
        (BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,matching=matching),BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,cache,env,funcs,einfo,eoc,btp,symjacs),b2,eqnlst,movedVars) = constantLinearSystem1(syst,shared,comps,{},BackendDAE.emptyBintree);
        b = b1 or b2;
        // move changed variables
        (vars1,knvars1) = BackendVariable.moveVariables(vars,knvars,movedVars);
        // remove changed eqns
        eqnlst = List.map1(eqnlst,intSub,1);
        eqns1 = BackendEquation.equationDelete(eqns,eqnlst);
        syst = BackendDAE.EQSYSTEM(vars1,eqns1,NONE(),NONE(),matching);
        shared = BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,constrs,cache,env,funcs,einfo,eoc,btp,symjacs);
        (m,mT) = BackendDAEUtil.incidenceMatrix(syst, shared, BackendDAE.NORMAL());
        syst = BackendDAE.EQSYSTEM(vars1,eqns1,SOME(m),SOME(mT),matching);
      then
        (syst,(shared,b));
  end matchcontinue;  
end constantLinearSystem0;

protected function constantLinearSystem1
"function constantLinearSystem1"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
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
  matchcontinue (isyst,ishared,inComps,inEqnlst,inMovedVars)
    local
      BackendDAE.BackendDAE dae,dae1,dae2;
      DAE.FunctionTree funcs;
      BackendDAE.Variables vars,knvars,exobj,avars,vars1,knvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1;
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
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      
    case (syst,shared,{},inEqnlst,inMovedVars)
      then (syst,shared,false,inEqnlst,inMovedVars);
    case (syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,(comp as BackendDAE.EQUATIONSYSTEM(eqns=eindex,vars=vindx,jac=SOME(jac),jacType=BackendDAE.JAC_CONSTANT()))::comps,inEqnlst,inMovedVars)
      equation
        eqn_lst = BackendEquation.getEqns(eindex,eqns);        
        var_lst = List.map1r(vindx, BackendVariable.getVarAt, vars);
        (syst,shared,movedVars) = solveLinearSystem(syst,shared,eqn_lst,var_lst,jac,inMovedVars);
        remeqnlst = listAppend(eindex,inEqnlst);
        (syst,shared,b,remeqnlst1,movedVars1) = constantLinearSystem1(syst,shared,comps,remeqnlst,movedVars);
      then
        (syst,shared,true,remeqnlst1,movedVars1);
    case (syst,shared,(comp as BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp1))::comps,inEqnlst,inMovedVars)
      equation
        (syst,shared,b,remeqnlst,movedVars) = constantLinearSystem1(syst,shared,{comp1},inEqnlst,inMovedVars);
        (syst,shared,b1,remeqnlst1,movedVars1) = constantLinearSystem1(syst,shared,comps,remeqnlst,movedVars);
      then
        (syst,shared,b1 or b,remeqnlst1,movedVars1);
    case (syst,shared,comp::comps,inEqnlst,inMovedVars)
      equation
        (syst,shared,b,remeqnlst,movedVars) = constantLinearSystem1(syst,shared,comps,inEqnlst,inMovedVars);
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
      BackendDAE.Variables vars,knvars,exobj,avars,vars1,knvars1,v;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1;
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
    case (BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,matching=matching),shared,eqn_lst,var_lst,jac,inMovedVars)
      equation
        eqns1 = BackendDAEUtil.listEquation(eqn_lst);
        v = BackendDAEUtil.listVar1(var_lst);
        ((_,beqs,sources)) = BackendEquation.traverseBackendDAEEqns(eqns1,BackendEquation.equationToExp,(v,{},{}));
        beqs = listReverse(beqs);
        rhsVals = ValuesUtil.valueReals(List.map(beqs,Ceval.cevalSimple));
        jacVals = evaluateConstantJacobian(listLength(var_lst),jac);
        (solvedVals,linInfo) = System.dgesv(jacVals,rhsVals);
        names = List.map(var_lst,BackendVariable.varCref);  
        checkLinearSystem(linInfo,names,jacVals,rhsVals,eqn_lst);
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
  input list<BackendDAE.Equation> eqnlst;
algorithm
  _ := matchcontinue (info,vars,jac,rhs,eqnlst)
    local
      String infoStr,syst,varnames,varname,rhsStr,jacStr,eqnstr;
    case (0,_,_,_,_) then ();
    case (info,vars,jac,rhs,_)
      equation
        true = info > 0;
        varname = ComponentReference.printComponentRefStr(listGet(vars,info));
        infoStr = intString(info);
        varnames = stringDelimitList(List.map(vars,ComponentReference.printComponentRefStr)," ;\n  ");
        rhsStr = stringDelimitList(List.map(rhs, realString)," ;\n  ");
        jacStr = stringDelimitList(List.map1(List.mapList(jac,realString),stringDelimitList," , ")," ;\n  ");
        eqnstr = BackendDump.dumpEqnsStr(eqnlst);
        syst = stringAppendList({"\n",eqnstr,"\n[\n  ", jacStr, "\n]\n  *\n[\n  ",varnames,"\n]\n  =\n[\n  ",rhsStr,"\n]"});
        Error.addMessage(Error.LINEAR_SYSTEM_SINGULAR, {syst,infoStr,varname});
      then fail();
    case (info,vars,jac,rhs,_)
      equation
        true = info < 0;
        varnames = stringDelimitList(List.map(vars,ComponentReference.printComponentRefStr)," ;\n  ");
        rhsStr = stringDelimitList(List.map(rhs, realString)," ; ");
        jacStr = stringDelimitList(List.map1(List.mapList(jac,realString),stringDelimitList," , ")," ; ");
        eqnstr = BackendDump.dumpEqnsStr(eqnlst);
        syst = stringAppendList({eqnstr,"\n[", jacStr, "] * [",varnames,"] = [",rhsStr,"]"});
        Error.addMessage(Error.LINEAR_SYSTEM_INVALID, {"LAPACK/dgesv",syst});
      then fail();
  end matchcontinue;
end checkLinearSystem;




/*  
 * tearing system of equations stuff
 *
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
        Debug.fcall(Flags.TEARING_DUMP, print, "Tearing\n==========\n");
        // get residual eqn and tearing var for each block
        // copy dlow
        dlow1 = BackendDAEUtil.copyBackendDAE(dlow);
        comps_1 = List.map(comps,getEqnIndxFromComp);
        (r,t,_,dlow_1,m_1,mT_1,v1_1,v2_1,comps_2) = tearingSystem1(dlow,dlow1,m,mT,v1,v2,comps_1);
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpIncidenceMatrix, m_1);
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpIncidenceMatrixT, mT_1);
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.dump, dlow_1);
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpMatching, v1_1);
        //Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpComponents, comps_2);
        Debug.fcall(Flags.TEARING_DUMP, print, "==========\n");
        Debug.fcall2(Flags.TEARING_DUMP, BackendDump.dumpTearing, r,t);
        Debug.fcall(Flags.TEARING_DUMP, print, "==========\n");
      then
        (dlow_1,v1_1,v2_1,comps_2,r,t);
    case (dlow,v1,v2,comps)
      equation
        Debug.fcall(Flags.TEARING_DUMP, print, "No Tearing\n==========\n");
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
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqns=elst))
      then
        elst;               
  end matchcontinue;
end getEqnIndxFromComp;

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
      BackendDAE.BackendDAE dlow,dlow_1,dlow_2,dlow1,dlow1_1,dlow1_2,dlow1_3;
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
        (syst,m_3,mT_3) = BackendDAEUtil.getIncidenceMatrix(syst,shared,BackendDAE.NORMAL());
        dlow1_2 = BackendDAE.DAE({syst},shared);
        (v1_3,v2_3) = correctAssignments(v1_2,v2_2,residualeqns,tearingvars);
        // next Block
        (r,t,dlow_2,dlow1_3,m_4,mT_4,v1_3,v2_3,comps_1) = tearingSystem1(dlow_1,dlow1_2,m_3,mT_3,v1_2,v2_2,comps);
      then
        (residualeqns::r,tearingvars::t,dlow_2,dlow1_3,m_4,mT_4,v1_3,v2_3,comp_1::comps_1);
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
        Debug.fcall(Flags.TEARING_DUMP, print, str1);
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
        Debug.fcall(Flags.TEARING_DUMP, print, "Select Residual BackendDAE.Equation failed\n");
      then
        fail();
    case (dlow,dlow1,m,mT,v1,v2,comp,tvars,exclude,residualeqns,tearingvars,tearingeqns,_)
      equation
        Debug.fcall(Flags.TEARING_DUMP, print, "Select Residual BackendDAE.Equation failed!\n");
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
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      DAE.Exp eqn,scalar,rhs,expCref;

      DAE.ElementSource source;
      DAE.Type identType;
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
        Debug.fcall(Flags.TEARING_DUMP, print, str2);
        // copy dlow
        dlowc = BackendDAEUtil.copyBackendDAE(dlow);
        BackendDAE.DAE(BackendDAE.EQSYSTEM(ordvars as BackendDAE.VARIABLES(varArr=varr),eqns,_,_,_)::{},shared) = dlowc;
        dlowc1 = BackendDAEUtil.copyBackendDAE(dlow1);
        BackendDAE.DAE(eqs = BackendDAE.EQSYSTEM(ordvars1,eqns1,_,_,_)::{}) = dlowc1;
        // add Tearing Var
        var = BackendVariable.vararrayNth(varr, tearingvar-1);
        cr = BackendVariable.varCref(var);
        crt = ComponentReference.prependStringCref("tearingresidual_",cr);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(crt, BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),DAE.T_REAL_DEFAULT,NONE(),NONE(),{},-1,DAE.emptyElementSource,
                            SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(true)),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE())),
                            NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM()), ordvars);
        // replace in residual equation orgvar with Tearing Var
        BackendDAE.EQUATION(eqn,scalar,source) = BackendDAEUtil.equationNth(eqns,residualeqn-1);
        // (eqn_1,replace) =  Expression.replaceExp(eqn,Expression.crefExp(cr),Expression.crefExp(crt));
        // (scalar_1,replace1) =  Expression.replaceExp(scalar,Expression.crefExp(cr),Expression.crefExp(crt));
        // true = replace + replace1 > 0;

        // Add Residual eqn
        rhs = Expression.crefExp(crt);
        eqns_1 = BackendEquation.equationSetnth(eqns,residualeqn-1,BackendDAE.EQUATION(DAE.BINARY(eqn,DAE.SUB(DAE.T_REAL_DEFAULT),scalar),rhs,source));

        eqns1_1 = BackendEquation.equationSetnth(eqns1,residualeqn-1,BackendDAE.EQUATION(DAE.BINARY(eqn,DAE.SUB(DAE.T_REAL_DEFAULT),scalar),DAE.RCONST(0.0),source));
        // add equation to calc org var
        expCref = Expression.crefExp(cr);
        eqns_2 = BackendEquation.equationAdd(BackendDAE.EQUATION(DAE.CALL(Absyn.IDENT("tearing"),
                          {},DAE.callAttrBuiltinReal),
                          expCref, DAE.emptyElementSource),eqns_1);

        tearingeqnid = BackendDAEUtil.equationSize(eqns_2);
        dlow_1 = BackendDAE.DAE(BackendDAE.EQSYSTEM(vars_1,eqns_2,NONE(),NONE(),BackendDAE.NO_MATCHING())::{},shared);
        dlow1_1 = BackendDAE.DAE(BackendDAE.EQSYSTEM(ordvars1,eqns1_1,NONE(),NONE(),BackendDAE.NO_MATCHING())::{},shared);
        // try causalisation
        (dlow_2 as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(m=SOME(m_2),mT=SOME(mT_2),matching=BackendDAE.MATCHING(v1_1,v2_1,comps))::{})) = BackendDAEUtil.transformBackendDAE(dlow_1,SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())),NONE(),NONE());
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
        Debug.fcall(Flags.TEARING_DUMP, print, "Select Tearing BackendDAE.Var failed\n");
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
protected function createDirectedGraph
  input Integer inNode;
  input tuple<BackendDAE.IncidenceMatrix,BackendDAE.Matching> intupleArgs;
  output list<Integer> outEdges; 
algorithm
  outEdges := matchcontinue(inNode,intupleArgs)
  local
    BackendDAE.IncidenceMatrix incidenceMat;
    BackendDAE.IncidenceMatrixElement oneElement;
    array<Integer> ass1,ass2;
    Integer assignment;
    list<Integer> outEdges;
    list<String> oneEleStr;
    case(inNode, (incidenceMat,BackendDAE.MATCHING(ass1 = ass1)))
      equation
        //Debug.fcall(Flags.JAC_DUMP2, print,"In Node : " +& intString(inNode) +& " ");
        assignment = arrayGet(ass1,inNode);
        oneElement = arrayGet(incidenceMat,assignment);
        //Debug.fcall(Flags.JAC_DUMP2, print,"assignt to : " +& intString(assignment) +& "\n");
        //Debug.fcall(Flags.JAC_DUMP2, print,"elements on node : ");
        //Debug.fcall(Flags.JAC_DUMP2, BackendDump.dumpIncidenceRow,oneElement);
        ( outEdges,_) = List.deleteMemberOnTrue(inNode,oneElement,intEq);
    then outEdges;
    case(inNode, (_,_))
      then {};        
  end matchcontinue;
end createDirectedGraph;

protected function createBipartiteGraph
  input Integer inNode;
  input array<list<Integer>> inSparsePattern;
  output list<Integer> outEdges; 
algorithm
  outEdges := matchcontinue(inNode,inSparsePattern)
    case(inNode, inSparsePattern)
      equation
        outEdges = arrayGet(inSparsePattern,inNode);
    then outEdges;
    case(inNode, _)
      then {};        
  end matchcontinue;
end createBipartiteGraph;

protected function getSparsePatternGraph
  input list<Integer> inNodes1; //nodesEqnsIndex
  input Integer inMaxGraphIndex; //nodesVarsIndex
  input Integer inMaxNodeIndex; //nodesVarsIndex
  input array<tuple<Integer, list<Integer>>> inGraph;
  output list<list<Integer>> outSparsePattern;
algorithm 
  outSparsePattern :=match(inNodes1,inMaxGraphIndex,inMaxNodeIndex,inGraph)
  local
    list<Integer> rest;
    Integer node;
    list<Integer> reachableNodes;
    list<list<Integer>> result;
    case(node::{},inMaxGraphIndex,inMaxNodeIndex,inGraph)
      equation
        reachableNodes = Graph.allReachableNodesInt(({node},{}), inGraph, inMaxGraphIndex, inMaxNodeIndex);
        reachableNodes = List.select1(reachableNodes, intGe, inMaxGraphIndex);
      then {reachableNodes};        
    case(node::rest,inMaxGraphIndex,inMaxNodeIndex,inGraph)
      equation
        reachableNodes = Graph.allReachableNodesInt(({node},{}), inGraph, inMaxGraphIndex, inMaxNodeIndex);
        reachableNodes = List.select1(reachableNodes, intGe, inMaxGraphIndex);
        result = getSparsePatternGraph(rest,inMaxGraphIndex,inMaxNodeIndex,inGraph);
        result = listAppend({reachableNodes},result);
      then result;      
    else
       equation
       Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.getSparsePattern failed"});
       then fail();
  end match;
end getSparsePatternGraph;


protected function prepareSparsePatternT 
  input array<list<Integer>> inSparseT;
  input Integer inStartNode;
  input Integer inEndNode;
  input BackendDAE.IncidenceMatrix inMatrixT;
  output array<list<Integer>> outSparseT;
algorithm
  outSparseT := matchcontinue(inSparseT,inStartNode,inEndNode,inMatrixT)
  local
    list<Integer> rowElements;
    case (inSparseT,inStartNode,inEndNode,inMatrixT)
      equation
        true = (inStartNode <= inEndNode);
        rowElements = arrayGet(inMatrixT,inStartNode);
        List.map2_0(rowElements, Util.arrayUpdateElementListUnion, {inStartNode}, inSparseT);
        outSparseT = prepareSparsePatternT(inSparseT, inStartNode+1, inEndNode, inMatrixT);
      then outSparseT;     
    case (inSparseT,_,_,_) then inSparseT;
  end matchcontinue;
end prepareSparsePatternT;

protected function getSparsePattern
  input BackendDAE.StrongComponents inComponents;
  input array<list<Integer>> inResults; //
  input BackendDAE.IncidenceMatrix inMatrix;
  input BackendDAE.IncidenceMatrix inMatrixT;
  output array<list<Integer>> outSparsePattern;
algorithm 
  outSparsePattern :=matchcontinue(inComponents,inResults,inMatrix,inMatrixT)
  local
    list<Integer> vars, eqns, eqnlst, rowElements;
    Integer var, eqn, indx;
    array<list<Integer>> result;
    BackendDAE.StrongComponents rest;
    list<list<Integer>>  rowElementsList, eqnlstList;
    list<String> lststr;
    list<list<String>> lstlststr;
    case ({},inResults,_,_) then inResults;
    case(BackendDAE.SINGLEEQUATION(eqn=eqn,var=var)::rest,result,inMatrix,inMatrixT)
      equation
        // get incedece row for curent equation set
        //print("find for dependecies for  eqn:" +& intString(eqn) +& " \n");
        rowElements = arrayGet(inMatrixT, var);
        eqnlst = arrayGet(result, eqn);
        List.map2_0(rowElements, Util.arrayUpdateElementListUnion, eqnlst, result);    
        result = getSparsePattern(rest,result,inMatrix,inMatrixT);
      then result;        
    case(BackendDAE.EQUATIONSYSTEM(eqns=eqns,vars=vars)::rest,result,inMatrix,inMatrixT)
      equation
        rowElementsList = List.map1(vars, Util.arrayGetIndexFirst, inMatrixT);
        rowElements = List.unionList(rowElementsList);
        eqnlstList = List.map1(eqns, Util.arrayGetIndexFirst, result);
        eqnlst = List.unionList(eqnlstList);
        List.map2_0(rowElements, Util.arrayUpdateElementListUnion, eqnlst, result);
        result = getSparsePattern(rest,result,inMatrix,inMatrixT);
      then result;
    case(BackendDAE.MIXEDEQUATIONSYSTEM(disc_eqns=eqns,disc_vars=vars)::rest,result,inMatrix,inMatrixT)
      equation
        rowElementsList = List.map1(vars, Util.arrayGetIndexFirst, inMatrixT);
        rowElements = List.unionList(rowElementsList);
        eqnlstList = List.map1(eqns, Util.arrayGetIndexFirst, result);
        eqnlst = List.unionList(eqnlstList);
        List.map2_0(rowElements, Util.arrayUpdateElementListUnion, eqnlst, result);
        result = getSparsePattern(rest,result,inMatrix,inMatrixT);
      then result;
    case(BackendDAE.SINGLEARRAY(eqns=eqns,vars=vars)::rest,result,inMatrix,inMatrixT)
      equation
        rowElementsList = List.map1(vars, Util.arrayGetIndexFirst, inMatrixT);
        rowElements = List.unionList(rowElementsList);
        eqnlstList = List.map1(eqns, Util.arrayGetIndexFirst, result);
        eqnlst = List.unionList(eqnlstList);
        List.map2_0(rowElements, Util.arrayUpdateElementListUnion, eqnlst, result);
        result = getSparsePattern(rest,result,inMatrix,inMatrixT);
      then result;
    case(BackendDAE.SINGLEALGORITHM(eqns=eqns,vars=vars)::rest,result,inMatrix,inMatrixT)
      equation
        rowElementsList = List.map1(vars, Util.arrayGetIndexFirst, inMatrixT);
        rowElements = List.unionList(rowElementsList);
        eqnlstList = List.map1(eqns, Util.arrayGetIndexFirst, result);
        eqnlst = List.unionList(eqnlstList);
        List.map2_0(rowElements, Util.arrayUpdateElementListUnion, eqnlst, result);
        result = getSparsePattern(rest,result,inMatrix,inMatrixT);
      then result;          
    case(BackendDAE.SINGLECOMPLEXEQUATION(eqns=eqns,vars=vars)::rest,result,inMatrix,inMatrixT)
      equation
        rowElementsList = List.map1(vars, Util.arrayGetIndexFirst, inMatrixT);
        rowElements = List.unionList(rowElementsList);
        eqnlstList = List.map1(eqns, Util.arrayGetIndexFirst, result);
        eqnlst = List.unionList(eqnlstList);
        List.map2_0(rowElements, Util.arrayUpdateElementListUnion, eqnlst, result);
        result = getSparsePattern(rest,result,inMatrix,inMatrixT);  
      then result;          
    else
       equation
       Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.getSparsePatternNew failed"});
       then fail();
  end matchcontinue;
end getSparsePattern;

public function generateSparsePattern
 input BackendDAE.BackendDAE inBackendDAE;
 input list<BackendDAE.Var> inDiffVars;
 input list<BackendDAE.Var> inDiffedVars;
 output list<list<Integer>> outSparsePattern;
 output list<Integer> outColoredCols;
 algorithm
   (outSparsePattern,outColoredCols) := matchcontinue(inBackendDAE,inDiffVars,inDiffedVars)
   local
      BackendDAE.IncidenceMatrix adjMatrix,adjMatrixT;
      BackendDAE.Matching bdaeMatching;
      list<tuple<Integer, list<Integer>>> bdaeDirectedGraph, sparseGraph, sparseGraphT;
      array<tuple<Integer, list<Integer>>> arraysparseGraph,arraysparseGraphT;
      Integer sizeofGraph, njacs, nonZeroElements, nodesEqnsLength, sparseLength, maxdegree;
      list<Integer> nodesList,nodesVarsList,nodesVarsIndex,nodesEqnsIndex;
      list<list<Integer>> sparsepattern,sparsepatternT,sparsepatternT2;
      list<String> sparsepatternStr;
      list<BackendDAE.Var> JacDiffVars,states,derstates,vars;
      list<DAE.ComponentRef> state_comref;
      BackendDAE.Variables diffedVars,varswithDiffs,orderedVars;
      BackendDAE.EquationArray orderedEqns;
      array<Option<list<Integer>>> forbiddenColor;
      array<Integer> colored, colored1, ass1;
      list<Integer> coloredlist, alldegrees;
      
      BackendDAE.BackendDAE modBDAE;
      
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst,syst1;
      
      BackendDAE.StrongComponents comps, comps2;
      array<BackendDAE.StrongComponent> arraycomps;
      array<list<Integer>> eqnSparse,eqnSparseT,sparseArray,sparseArrayT,sparseArrayT2;
      list<String> lststr;
      
     case (_,{},_) then ({{}},{});
     case (_,_,{}) then ({{}},{});
     case(inBackendDAE as BackendDAE.DAE(eqs = (syst as BackendDAE.EQSYSTEM(matching=bdaeMatching as BackendDAE.MATCHING(comps=comps, ass1=ass1)))::{}, shared=shared),inDiffVars,inDiffedVars)
       equation
        // Generate Graph for determine sparse structure
        Debug.fcall(Flags.JAC_DUMP,print," start getting sparsity pattern diff Vars : " +& intString(listLength(inDiffedVars))  +& " diffed vars: " +& intString(listLength(inDiffVars)) +&"\n");
        JacDiffVars =  List.map(inDiffVars,BackendVariable.createpDerVar);
        njacs = listLength(JacDiffVars);
        /*
        states = BackendVariable.getAllStateVarFromVariables(orderedVars);
        derstates =  List.map(states,BackendVariable.createDerVar);
        state_comref = List.map(states,BackendVariable.varCref);
        //state_comref = listReverse(state_comref);
        orderedVars = BackendVariable.deleteCrefs(state_comref,orderedVars);
        orderedVars = BackendVariable.addVars(derstates,orderedVars);
        syst = BackendDAE.EQSYSTEM(orderedVars,orderedEqns,NONE(),NONE(),bdaeMatching);*/
        
        (syst1 as BackendDAE.EQSYSTEM(orderedVars=varswithDiffs,orderedEqs=orderedEqns)) = BackendDAEUtil.addVarsToEqSystem(syst,JacDiffVars);
        (adjMatrix, adjMatrixT) = BackendDAEUtil.incidenceMatrix(syst1,shared,BackendDAE.SPARSE());
        Debug.fcall(Flags.JAC_DUMP2, BackendDump.dumpFullMatching, bdaeMatching);
        Debug.fcall(Flags.JAC_DUMP2,BackendDump.dumpVars,BackendDAEUtil.varList(varswithDiffs));
        Debug.fcall(Flags.JAC_DUMP2,BackendDump.dumpEqns,BackendDAEUtil.equationList(orderedEqns));
        Debug.fcall(Flags.JAC_DUMP2,BackendDump.dumpIncidenceMatrix,adjMatrix);
        Debug.fcall(Flags.JAC_DUMP2,BackendDump.dumpIncidenceMatrixT,adjMatrixT);
        Debug.fcall(Flags.JAC_DUMP2,BackendDump.dumpComponents, comps);
        JacDiffVars = listReverse(inDiffedVars);
        diffedVars = BackendDAEUtil.listVar(JacDiffVars);  
        Debug.fcall(Flags.JAC_DUMP,print," diff Vars : " +& intString(njacs) +& "listLength comps: " +& intString(listLength(comps)) +&"\n");
        nodesEqnsIndex = BackendVariable.getVarIndexFromVariables(diffedVars,varswithDiffs);
        
        nodesEqnsIndex = List.map1(nodesEqnsIndex, Util.arrayGetIndexFirst, ass1);
        nodesEqnsLength = listLength(nodesEqnsIndex);
        sparseLength = Util.if_(nodesEqnsLength > njacs, nodesEqnsLength, njacs);
        
        Debug.fcall(Flags.JAC_DUMP,print,"analytical Jacobians[SPARSE] -> build sparse graph: " +& realString(clock()) +& "\n"); 
        eqnSparse = arrayCreate(arrayLength(adjMatrix),{});
        eqnSparse = prepareSparsePatternT(eqnSparse, arrayLength(adjMatrix)+1, arrayLength(adjMatrix)+njacs, adjMatrixT);
        sparsepattern = arrayList(eqnSparse);
        Debug.fcall(Flags.JAC_DUMP2,BackendDump.dumpSparsePattern,sparsepattern);
        Debug.fcall(Flags.JAC_DUMP,print, "analytical Jacobians[SPARSE] -> prepared arrayList for transpose list: " +& realString(clock()) +& "\n");
        eqnSparse = getSparsePattern(comps, eqnSparse, adjMatrix, adjMatrixT);
        sparseArray = Util.arraySelect(eqnSparse, nodesEqnsIndex);
        sparsepattern = arrayList(sparseArray);
        sparsepattern = List.map1List(sparsepattern, intSub, arrayLength(adjMatrix));
        sparseArray = listArray(sparsepattern);

        nonZeroElements = List.lengthListElements(sparsepattern);
        (alldegrees, maxdegree) = List.mapFold(sparsepattern, findDegrees, 1);
        Debug.fcall(Flags.JAC_DUMP,print,"analytical Jacobians[SPARSE] -> got sparse pattern nonZeroElements: "+& intString(nonZeroElements) +& " maxNodeDegree: " +& intString(maxdegree) +& " time : " +& realString(clock()) +& "\n");
        Debug.fcall(Flags.JAC_DUMP2,BackendDump.dumpSparsePattern,sparsepattern);
                
        sparseArrayT = arrayCreate(sparseLength,{});
        sparseArrayT = transposeSparsePattern(sparsepattern, sparseArrayT, 1);
        sparsepatternT = arrayList(sparseArrayT);
        Debug.fcall(Flags.JAC_DUMP,print,"analytical Jacobians[SPARSE] -> transposedGraph: "+& intString(nonZeroElements));
        Debug.fcall(Flags.JAC_DUMP2,BackendDump.dumpSparsePattern,sparsepatternT);        
        
        Debug.fcall(Flags.JAC_DUMP,print,"analytical Jacobians[SPARSE] -> build sparse  graph.");
        // build up a graph of pattern
        nodesList = List.intRange2(1,sparseLength);
        sparseGraph = Graph.buildGraph(nodesList,createBipartiteGraph,sparseArray);
        sparseGraphT = Graph.buildGraph(nodesList,createBipartiteGraph,sparseArrayT);
        Debug.fcall(Flags.JAC_DUMP2,print,"sparse graph: \n");
        Debug.fcall(Flags.JAC_DUMP2,Graph.printGraphInt,sparseGraph);
        Debug.fcall(Flags.JAC_DUMP2,print,"transposed sparse graph: \n");
        Debug.fcall(Flags.JAC_DUMP2,Graph.printGraphInt,sparseGraphT);
        
        
        Debug.fcall(Flags.JAC_DUMP,print,"analytical Jacobians[SPARSE] -> builded graph for coloring.");
        // color sparse bipartite graph
        forbiddenColor = arrayCreate(sparseLength,NONE());
        colored = arrayCreate(sparseLength,0);
        arraysparseGraph = listArray(sparseGraph);        
        colored1 = Graph.partialDistance2colorInt(sparseGraphT, forbiddenColor, nodesList, arraysparseGraph, colored);
        coloredlist = arrayList(colored1);
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians[SPARSE] -> colored graph time : " +& realString(clock()) +& "\n");
        
        Debug.fcall(Flags.JAC_DUMP2, print, "Print Coloring Cols: \n");
        Debug.fcall(Flags.JAC_DUMP2, BackendDump.dumpIncidenceRow, coloredlist);
        
      then (sparsepatternT,coloredlist);
       else
       equation
       Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.generateSparsePattern failed"});
       then fail();
    end matchcontinue;
end generateSparsePattern;

public function findDegrees
  input list<Integer> inList;
  input Integer inValue;
  output Integer outDegree;
  output Integer outMaxDegree;
algorithm
  outDegree := listLength(inList);
  outMaxDegree := intMax(inValue,outDegree);
end findDegrees;

protected function transposeSparsePattern
  input list<list<Integer>> inSparsePattern; 
  input array<list<Integer>> inAccumList;
  input Integer inValue;
  output array<list<Integer>> outSparsePattern;
algorithm
  outSparsePattern := matchcontinue(inSparsePattern, inAccumList, inValue)
  local 
    list<Integer> oneElem;
    list<list<Integer>> rest;
    array<list<Integer>> result, accumList;
    case ({}, inAccumList, _) then inAccumList;
    case (oneElem::rest, inAccumList, inValue)
      equation
        accumList = transposeSparsePattern2(oneElem, inAccumList, inValue);
       then transposeSparsePattern(rest, accumList, inValue+1); 
  end matchcontinue;
end transposeSparsePattern;

protected function transposeSparsePattern2
  input list<Integer> inSparsePatternElem; 
  input array<list<Integer>> inAccumList;
  input Integer inValue;
  output array<list<Integer>> outSparsePattern;
algorithm
  outSparsePattern := matchcontinue(inSparsePatternElem, inAccumList, inValue)
  local 
    Integer oneElem;
    list<Integer> rest, tmplist;
    array<list<Integer>> result, accumList;
    case ({},inAccumList, _) then inAccumList;
    case (oneElem::rest,inAccumList, inValue)
      equation
        tmplist = arrayGet(inAccumList,oneElem);
        tmplist = listAppend(tmplist,{inValue});
        accumList = arrayUpdate(inAccumList, oneElem, tmplist);
       then transposeSparsePattern2(rest, accumList, inValue); 
  end matchcontinue;
end transposeSparsePattern2;




/*
 * initialization stuff
 *
 */
public function collectInitialResiduals "function collectInitialResiduals
  author: lochel
  This function collects all initial equations and convert it into residuals."
  input BackendDAE.BackendDAE inDAE;
  output list<BackendDAE.Equation> outEquations;
  output Integer outNumberOfInitialEquations;
  output Integer outNumberOfInitialAlgorithms;
algorithm
  (outEquations, outNumberOfInitialEquations, outNumberOfInitialAlgorithms) := matchcontinue(inDAE)
    local
      BackendDAE.EqSystems eqs;
      BackendDAE.EquationArray initialEqs;
      
      Integer numberOfInitialEquations, numberOfInitialAlgorithms;
      list<BackendDAE.Equation> initialEqs_lst, initialEqs_lst1, initialEqs_lst2, initialEqs_lst3;
      
    case(BackendDAE.DAE(eqs=eqs, shared=BackendDAE.SHARED(initialEqs=initialEqs))) equation
      // [initial equations]
      // initial_equation
      initialEqs_lst1 = BackendEquation.traverseBackendDAEEqns(initialEqs, BackendDAEUtil.traverseequationToScalarResidualForm, {});
      initialEqs_lst1 = listReverse(initialEqs_lst1);

      // [orderedVars] with start-values and fixed=true
      // v - start(v); fixed(v) = true
      initialEqs_lst2 = generateFixedStartValueResiduals(List.flatten(List.mapMap(eqs, BackendVariable.daeVars, BackendDAEUtil.varList)));
      initialEqs_lst = listAppend(initialEqs_lst1, initialEqs_lst2);
      numberOfInitialEquations = listLength(initialEqs_lst);

      // [initial algorithms]
      // is still missing but algorithms from initial equations are generate in parameter eqns.
      initialEqs_lst3 = {};
      initialEqs_lst = listAppend(initialEqs_lst, initialEqs_lst3);
      numberOfInitialAlgorithms = listLength(initialEqs_lst3);
    then(initialEqs_lst, numberOfInitialEquations, numberOfInitialAlgorithms);
        
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function collectInitialResiduals failed"});
    then fail();
  end matchcontinue;
end collectInitialResiduals;

public function generateFixedStartValueResiduals "function generateFixedStartValueResiduals
  author: lochel
  Helper for collectInitialResiduals.
  This function generates initial residuals for fixed variables."
  input list<BackendDAE.Var> inVars;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := matchcontinue(inVars)
  local
    BackendDAE.Var var;
    list<BackendDAE.Var> vars;
    BackendDAE.Equation eqn;
    list<BackendDAE.Equation> eqns;
    DAE.Exp e, e1, e2, lambda, crefExp, startExp;
    DAE.ComponentRef cref;
    DAE.Type tp;
    case({}) then {};
      
    case(var::vars) equation
      SOME(startExp) = BackendVariable.varStartValueOption(var);
      true = BackendVariable.varFixed(var);
      false = BackendVariable.isStateVar(var);
      false = BackendVariable.isParam(var);
      false = BackendVariable.isVarDiscrete(var);
      
      cref = BackendVariable.varCref(var);
      crefExp = DAE.CREF(cref, DAE.T_REAL_DEFAULT);
      
      e = Expression.crefExp(cref);
      tp = Expression.typeof(e);
      startExp = Expression.makeBuiltinCall("$_start", {e}, tp);
      e1 = DAE.BINARY(crefExp, DAE.SUB(DAE.T_REAL_DEFAULT), startExp);
      
      eqn = BackendDAE.RESIDUAL_EQUATION(e1, DAE.emptyElementSource);
      eqns = generateFixedStartValueResiduals(vars);
    then eqn::eqns;
      
    case(var::vars) equation
      eqns = generateFixedStartValueResiduals(vars);
    then eqns;
      
    case(_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function generateFixedStartValueResiduals failed"});
    then fail();
  end matchcontinue;
end generateFixedStartValueResiduals;

protected function convertInitialResidualsIntoInitialEquations "function convertInitialResidualsIntoInitialEquations
  author: lochel
  This function converts initial residuals into initial equations.
  e.g.: 0 = a+b -> $res1 = a+b"
  input list<BackendDAE.Equation> inResidualList;
  output list<BackendDAE.Equation> outEquationList;
  output list<BackendDAE.Var> outVariableList;
algorithm
  (outEquationList, outVariableList) := convertInitialResidualsIntoInitialEquations2(inResidualList, 1);
end convertInitialResidualsIntoInitialEquations;

protected function convertInitialResidualsIntoInitialEquations2 "function generateInitialResidualEquations2
  author: lochel
  This is a helper function of convertInitialResidualsIntoInitialEquations."
  input list<BackendDAE.Equation> inEquationList;
  input Integer inIndex;
  output list<BackendDAE.Equation> outEquationList;
  output list<BackendDAE.Var> outVariableList;
algorithm
  (outEquationList, outVariableList) := matchcontinue(inEquationList, inIndex)
    local
      Integer index;
      list<BackendDAE.Equation> restEquationList;
      list<BackendDAE.Equation> equationList;
      list<BackendDAE.Var> variableList;
      
      DAE.Exp expVarName;
      DAE.Exp exp;
      DAE.ElementSource source "origin of equation";
      
      String varName;
      DAE.ComponentRef componentRef;
      BackendDAE.Equation currEquation;
      BackendDAE.Var currVariable;
    
    case({}, _)
    then ({}, {});
    
    case((BackendDAE.RESIDUAL_EQUATION(exp, source))::restEquationList, index) equation
      (equationList, variableList) = convertInitialResidualsIntoInitialEquations2(restEquationList, index+1);
      
      varName = "$res" +& intString(index);
      componentRef = DAE.CREF_IDENT(varName, DAE.T_REAL_DEFAULT, {});
      expVarName = DAE.CREF(componentRef, DAE.T_REAL_DEFAULT);
      currEquation = BackendDAE.EQUATION(expVarName, exp, source);
      
      currVariable = BackendDAE.VAR(componentRef, BackendDAE.VARIABLE(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      
      equationList = currEquation::equationList;
      variableList = currVariable::variableList;
    then (equationList, variableList);
    
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function convertInitialResidualsIntoInitialEquations2 failed"});
    then fail();
  end matchcontinue;
end convertInitialResidualsIntoInitialEquations2;

protected function redirectOutputToBidir "function redirectOutputToBidir
  author: lochel
  This is a helper function of generateInitialMatrices."
  input list<BackendDAE.Var> inVariableList;
  output list<BackendDAE.Var> outVariableList;
algorithm
  outVariableList := matchcontinue(inVariableList)
    local
      list<BackendDAE.Var> variableList;
      BackendDAE.Var variable;
      
      list<BackendDAE.Var> resVariableList;
      BackendDAE.Var resVariable;
    
    case ({})
    then ({});
    
    case (variable::variableList) equation
      true = BackendVariable.isOutputVar(variable);
      //true = BackendVariable.isVarOnTopLevelAndOutput(variable);
      resVariable = BackendVariable.setVarDirection(variable, DAE.BIDIR());
      resVariableList = redirectOutputToBidir(variableList);
    then (resVariable::resVariableList);
      
    case (variable::variableList) equation
      resVariableList = redirectOutputToBidir(variableList);
    then (variable::resVariableList);
    
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function redirectOutputToBidir failed"});
    then fail();
  end matchcontinue;
end redirectOutputToBidir;

public function generateInitialMatrices "function generateInitialMatrices
  author: lochel
  This function generates symbolic matrices for initialization."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.SymbolicJacobian outJacG;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outJacG, outDAE) := matchcontinue(inDAE)
    local
      BackendDAE.BackendDAE DAE, DAE2;
      
      list<BackendDAE.Equation> initialEqs_lst, initialEquationList;
      list<BackendDAE.Var> state_lst, initialVariableList;
      BackendDAE.Variables initialVars;
      BackendDAE.EquationArray initialEqs;
      BackendDAE.EqSystem initEqSystem, syst;
      BackendDAE.SymbolicJacobian jacobian;
      
      BackendDAE.Variables orderedVars, knownVars;
      BackendDAE.EquationArray orderedEqs;
      
      list<BackendDAE.Var>  orderedVarList, knownVarList, states, inputs, outputs, parameters;
      list<DAE.ComponentRef> orderedVarCrefList, knownVarCrefList;
      
      BackendDAE.Shared shared;
    
    case(DAE) equation
      (initialEqs_lst, _, _) = collectInitialResiduals(DAE);
      //BackendDump.dumpBackendDAEEqnList(initialEqs_lst, "initial residuals", false);
      (initialEquationList, initialVariableList) = convertInitialResidualsIntoInitialEquations(initialEqs_lst);
      initialEqs = BackendDAEUtil.listEquation(initialEquationList);
      initialVars = BackendDAEUtil.listVar(initialVariableList);
      //BackendDump.dumpBackendDAEEqnList(initialEquationList, "initial equations", false);
      //BackendDump.dumpBackendDAEVarList(initialVariableList, "initial vars");
      
      initEqSystem = BackendDAE.EQSYSTEM(initialVars, initialEqs, NONE(), NONE(), BackendDAE.NO_MATCHING());
      
      // redirect output to bidir
      DAE = BackendDAEUtil.copyBackendDAE(DAE);                         // to avoid side effects from arrays
      DAE = collapseIndependentBlocks(DAE);
      BackendDAE.DAE(eqs={BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs)}, shared=shared) = DAE;
      orderedVarList = BackendDAEUtil.varList(orderedVars);
      //BackendDump.dumpBackendDAEVarList(orderedVarList, "initial vars 1");
      orderedVarList = redirectOutputToBidir(orderedVarList);
      //BackendDump.dumpBackendDAEVarList(orderedVarList, "initial vars 2");
      orderedVars = BackendDAEUtil.listVar(orderedVarList);
      DAE = BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars, orderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING())}, shared);
      
      DAE = BackendDAEUtil.copyBackendDAE(DAE);                         // to avoid side effects from arrays
      DAE = BackendDAEUtil.addBackendDAEEqSystem(DAE, initEqSystem);    // add initial equations and $res-variables
      DAE = collapseIndependentBlocks(DAE);                             // merge everything together
      DAE = BackendDAEUtil.transformBackendDAE(DAE, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), SOME("dummyDerivative"));  // calculate matching
      
      // preparing all needed variables
      BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs)}, BackendDAE.SHARED(knownVars=knownVars)) = DAE;

      orderedVarList = BackendDAEUtil.varList(orderedVars);
      orderedVarCrefList = List.map(orderedVarList, BackendVariable.varCref);
      knownVarList = BackendDAEUtil.varList(knownVars);
      knownVarCrefList = List.map(knownVarList, BackendVariable.varCref);
      states = BackendVariable.getAllStateVarFromVariables(orderedVars);
      states = List.sort(states, BackendVariable.varIndexComparer);
      inputs = List.select(knownVarList, BackendVariable.isInput);
      inputs = List.sort(inputs, BackendVariable.varIndexComparer);
      parameters = List.select(knownVarList, BackendVariable.isParam);
      parameters = List.sort(parameters,  BackendVariable.varIndexComparer);
      outputs = List.select(orderedVarList, BackendVariable.isVarOnTopLevelAndOutput);
      outputs = List.sort(outputs, BackendVariable.varIndexComparer);
      
      jacobian = createJacobian(DAE,                                      // DAE
		                            states,                                   // 
		                            BackendDAEUtil.listVar(states),           // 
		                            BackendDAEUtil.listVar(inputs),           // 
		                            BackendDAEUtil.listVar(parameters),       // 
		                            BackendDAEUtil.listVar(outputs),          // 
		                            orderedVarList,                           // 
		                            (orderedVarCrefList, knownVarCrefList),   // 
		                            "G");                                     // name
      
      //(DAE2, _, _, _, _) = jacobian;
      //BackendDump.bltdump(("bltdump: jacobian G", DAE2));
    then (jacobian, DAE);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function generateInitialMatrices failed"});
    then fail();
  end matchcontinue;
end generateInitialMatrices;




/*
 * Symbolic Jacobian subsection
 *
 */ 
public function generateSymbolicJacobianPast
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
  output Boolean outRunMatching;
protected 
  BackendDAE.EqSystems eqs;
  BackendDAE.Shared shared;
  BackendDAE.SymbolicJacobian symJacA;
algorithm
  System.realtimeTick(BackendDAE.RT_CLOCK_EXECSTAT_JACOBIANS);
  BackendDAE.DAE(eqs=eqs,shared=shared) := inBackendDAE;
  symJacA := createSymbolicJacobianforStates(inBackendDAE);
  shared := BackendDAEUtil.addBackendDAESharedJacobian(symJacA, shared);
  outBackendDAE := BackendDAE.DAE(eqs,shared);
  _ := Flags.enableDebug(Flags.JACOBIAN);
  outRunMatching := false;
  _ := System.realtimeTock(BackendDAE.RT_CLOCK_EXECSTAT_JACOBIANS);
end generateSymbolicJacobianPast;

public function generateSymbolicLinearizationPast
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
  output Boolean outRunMatching;
protected 
  BackendDAE.EqSystems eqs;
  BackendDAE.Shared shared;
  BackendDAE.SymbolicJacobians linearModelMatrixes;
algorithm
  System.realtimeTick(BackendDAE.RT_CLOCK_EXECSTAT_JACOBIANS);
  BackendDAE.DAE(eqs=eqs,shared=shared) := inBackendDAE;
  linearModelMatrixes := createLinearModelMatrixes(inBackendDAE);
  shared := BackendDAEUtil.addBackendDAESharedJacobians(linearModelMatrixes, shared);
  outBackendDAE := BackendDAE.DAE(eqs,shared);
  _ := Flags.enableDebug(Flags.JACOBIAN);
  outRunMatching := false;
  _ := System.realtimeTock(BackendDAE.RT_CLOCK_EXECSTAT_JACOBIANS);
end generateSymbolicLinearizationPast;

protected function createSymbolicJacobianforStates
" fuction creates symbolic jacobian
  all functionODE equation are differentiated 
  with respect to the states.
  
  author: wbraun"
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.SymbolicJacobian outJacobian;
algorithm
  outJacobian :=
  matchcontinue (inBackendDAE)
    local
      BackendDAE.BackendDAE backendDAE, backendDAE2;
      BackendDAE.StrongComponents blt_states;
      
      list<BackendDAE.Var>  varlst, knvarlst, varlst_tmp, states, inputvars, paramvars;
      list<DAE.ComponentRef> comref_states,comref_vars,comref_knvars;
      
      BackendDAE.Variables v,kv,newVars;
      BackendDAE.EquationArray e,newEqns;

      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;

    case (backendDAE)      
      equation
        
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> start generate system for matrix A time : " +& realString(clock()) +& "\n");
        
        backendDAE2 = BackendDAEUtil.copyBackendDAE(backendDAE);
        backendDAE2 = collapseIndependentBlocks(backendDAE2);
        //backendDAE2 = BackendDAEUtil.transformBackendDAE(backendDAE2,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),SOME("dummyDerivative"));
        BackendDAE.DAE({syst as BackendDAE.EQSYSTEM(orderedVars = v,orderedEqs = e)},shared as BackendDAE.SHARED(knownVars = kv)) = backendDAE2;
        
        /*
        (blt_states, _) = BackendDAEUtil.generateStatePartition(syst);
        
        newEqns = BackendDAEUtil.listEquation({});
        newVars = BackendDAEUtil.emptyVars();
        (newEqns, newVars) = BackendDAEUtil.splitoutEquationAndVars(blt_states,e,v,newEqns,newVars);
        backendDAE2 = BackendDAE.DAE(BackendDAE.EQSYSTEM(newVars,newEqns,NONE(),NONE(),BackendDAE.NO_MATCHING())::{},shared);
        backendDAE2 = BackendDAEUtil.transformBackendDAE(backendDAE2,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),SOME("dummyDerivative"));
        */ 
        // Prepare all needed variables
        varlst = BackendDAEUtil.varList(v);
        comref_vars = List.map(varlst,BackendVariable.varCref);
        knvarlst = BackendDAEUtil.varList(kv);
        comref_knvars = List.map(knvarlst,BackendVariable.varCref);
        states = BackendVariable.getAllStateVarFromVariables(v);
        states = List.sort(states, BackendVariable.varIndexComparer);
        inputvars = List.select(knvarlst,BackendVariable.isInput);
        inputvars = List.sort(inputvars, BackendVariable.varIndexComparer);
        paramvars = List.select(knvarlst, BackendVariable.isParam);
        paramvars = List.sort(paramvars,  BackendVariable.varIndexComparer);

        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> prepared vars for symbolic matrix A time: " +& realString(clock()) +& "\n");
        outJacobian = createJacobian(backendDAE2,states,BackendDAEUtil.listVar(states),BackendDAEUtil.listVar(inputvars),BackendDAEUtil.listVar(paramvars),BackendDAEUtil.listVar(states),varlst,(comref_vars,comref_knvars),"A");
        
      then
        outJacobian;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Generation of symbolic Jacobian Matrix code failed. Function: BackendDAEOpimize.createSymcolicaJacobianforStates"});
      then
        fail();
  end matchcontinue;
end createSymbolicJacobianforStates;

protected function createLinearModelMatrixes
"fuction creates the linear model matrices column-wise
 author: wbraun"
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.SymbolicJacobians outJacobianMatrixes;
algorithm
  outJacobianMatrixes :=
  matchcontinue (inBackendDAE)
    local
      BackendDAE.BackendDAE backendDAE,backendDAE2;
      
      list<BackendDAE.Var>  varlst, knvarlst, varlst_tmp, states, inputvars, inputvars2, outputvars, paramvars;
      list<DAE.ComponentRef> comref_states, comref_inputvars, comref_outputvars, comref_vars, comref_knvars;
      
      BackendDAE.Variables v,kv;
      BackendDAE.EquationArray e;
      
      BackendDAE.SymbolicJacobians linearModelMatrices;
      BackendDAE.SymbolicJacobian linearModelMatrix;
      
    case (backendDAE)
      equation
        backendDAE2 = BackendDAEUtil.copyBackendDAE(backendDAE);
        backendDAE2 = collapseIndependentBlocks(backendDAE2);
        BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars = v,orderedEqs = e)},BackendDAE.SHARED(knownVars = kv)) = backendDAE2;
        
        
        // Prepare all needed variables
        varlst = BackendDAEUtil.varList(v);
        comref_vars = List.map(varlst,BackendVariable.varCref);
        knvarlst = BackendDAEUtil.varList(kv);
        comref_knvars = List.map(knvarlst,BackendVariable.varCref);
        states = BackendVariable.getAllStateVarFromVariables(v);
        states = List.sort(states, BackendVariable.varIndexComparer);
        inputvars = List.select(knvarlst,BackendVariable.isInput);
        inputvars = List.sort(inputvars, BackendVariable.varIndexComparer);
        paramvars = List.select(knvarlst, BackendVariable.isParam);
        paramvars = List.sort(paramvars,  BackendVariable.varIndexComparer);
        inputvars2 = List.select(knvarlst,BackendVariable.isVarOnTopLevelAndInput);
        inputvars2 = List.sort(inputvars2, BackendVariable.varIndexComparer);
        outputvars = List.select(varlst,BackendVariable.isVarOnTopLevelAndOutput);
        outputvars = List.sort(outputvars, BackendVariable.varIndexComparer);
        
        comref_states = List.map(states,BackendVariable.varCref);
        comref_inputvars = List.map(inputvars2,BackendVariable.varCref);
        comref_outputvars = List.map(outputvars,BackendVariable.varCref);
        
        // Differentiate the System w.r.t states for matrices A
        linearModelMatrix = createJacobian(backendDAE2,states,BackendDAEUtil.listVar(states),BackendDAEUtil.listVar(inputvars),BackendDAEUtil.listVar(paramvars), BackendDAEUtil.listVar(states),varlst,(comref_vars,comref_knvars),"A");
        linearModelMatrices = {linearModelMatrix};
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> generated system for matrix A time: " +& realString(clock()) +& "\n");
  
        
        // Differentiate the System w.r.t inputs for matrices B
        linearModelMatrix = createJacobian(backendDAE2,inputvars2,BackendDAEUtil.listVar(states),BackendDAEUtil.listVar(inputvars),BackendDAEUtil.listVar(paramvars), BackendDAEUtil.listVar(states),varlst,(comref_vars,comref_knvars),"B");
        linearModelMatrices = listAppend(linearModelMatrices,{linearModelMatrix});
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> generated system for matrix B time: " +& realString(clock()) +& "\n");


        // Differentiate the System w.r.t states for matrices C
        linearModelMatrix = createJacobian(backendDAE2,states,BackendDAEUtil.listVar(states),BackendDAEUtil.listVar(inputvars),BackendDAEUtil.listVar(paramvars),BackendDAEUtil.listVar(outputvars),varlst,(comref_vars,comref_knvars),"C");
        linearModelMatrices = listAppend(linearModelMatrices,{linearModelMatrix});
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> generated system for matrix C time: " +& realString(clock()) +& "\n");

        
        // Differentiate the System w.r.t inputs for matrices D
        linearModelMatrix = createJacobian(backendDAE2,inputvars2,BackendDAEUtil.listVar(states),BackendDAEUtil.listVar(inputvars),BackendDAEUtil.listVar(paramvars),BackendDAEUtil.listVar(outputvars),varlst,(comref_vars,comref_knvars),"D");
        linearModelMatrices = listAppend(linearModelMatrices,{linearModelMatrix});
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> generated system for matrix D time: " +& realString(clock()) +& "\n");

      then
        linearModelMatrices;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Generation of LinearModel Matrices failed. Function: BackendDAEOpimize.createLinearModelMatrixes"});
      then
        fail();
  end matchcontinue;
end createLinearModelMatrixes;

public function createJacobian "function createJacobian
  author: wbraun
  helper fuction of createSymbolicJacobian*"
  input BackendDAE.BackendDAE inBackendDAE;
  input list<BackendDAE.Var> inDiffVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParameterVars;
  input BackendDAE.Variables inDifferentiatedVars;
  input list<BackendDAE.Var> inVars;
  input tuple<list<DAE.ComponentRef>,list<DAE.ComponentRef>> inOrigTuple;
  input String inName;
  output BackendDAE.SymbolicJacobian outJacobian;
algorithm
  outJacobian :=
  matchcontinue (inBackendDAE,inDiffVars,inStateVars,inInputVars,inParameterVars,inDifferentiatedVars,inVars,inOrigTuple,inName)
    local
      BackendDAE.BackendDAE backendDAE;
      array<Integer> ass1,ass2;
      BackendDAE.StrongComponents comps;
      
      list<DAE.ComponentRef> inOrigVars, inOrigKnVars, comref_vars, comref_seedVars, comref_differentiatedVars, varsToRemove;
      
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst,syst1;
      BackendDAE.Variables vars, knvars, knvars1, empty, orderedVars, diffVars, varswithDiffs;
      list<BackendDAE.Var> diffedVars, diffVarsTmp, varswithDiffsLst,seedlst, knvarsTmp, knvarsTmp1;
      String s,s1;
      
      list<list<Integer>> sparsepattern;
      list<Integer> colsColors;
      Integer maxColor,nonZeroElements;
      
    case (_,_,_,_,_,_,_,(inOrigVars,inOrigKnVars),_)
      equation
        
        diffedVars = BackendDAEUtil.varList(inDifferentiatedVars);
        s =  intString(listLength(diffedVars));
        comref_differentiatedVars = List.map(diffedVars, BackendVariable.varCref);
        
        comref_vars = List.map(inDiffVars, BackendVariable.varCref);
        seedlst = List.map1(comref_vars, createSeedVars, (inName,false));
        comref_seedVars = List.map(seedlst, BackendVariable.varCref);
        s1 =  intString(listLength(inVars));
 
        Debug.execStat("analytical Jacobians -> starting to generate the jacobian. DiffVars:"
                       +& s +& " diffed equations: " +&  s1 +& "\n", BackendDAE.RT_CLOCK_EXECSTAT_JACOBIANS);
                       
        // Differentiate the ODE system w.r.t states for jacobian
        (backendDAE as BackendDAE.DAE(shared=shared)) = generateSymbolicJacobian(inBackendDAE, comref_vars, inDifferentiatedVars, BackendDAEUtil.listVar(seedlst), inStateVars, inInputVars, inParameterVars, inName);
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> generated equations for Jacobian " +& inName +& " time: " +& realString(clock()) +& "\n");
        
        knvars1 = BackendVariable.daeKnVars(shared);
        knvarsTmp = BackendDAEUtil.varList(knvars1);
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> sorted know temp vars(" +& intString(listLength(knvarsTmp)) +& ") for Jacobian DAE time: " +& realString(clock()) +& "\n");
        
        (backendDAE as BackendDAE.DAE(shared=shared)) = optimizeJacobianMatrix(backendDAE,comref_differentiatedVars,comref_vars);
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> generated Jacobian DAE time: " +& realString(clock()) +& "\n");
        
        knvars = BackendVariable.daeKnVars(shared);
        diffVarsTmp = BackendDAEUtil.varList(knvars);
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> sorted know diff vars(" +& intString(listLength(diffVarsTmp)) +& ") for Jacobian DAE time: " +& realString(clock()) +& "\n");
        (_,knvarsTmp,_) = List.intersection1OnTrue(diffVarsTmp, knvarsTmp, BackendVariable.varEqual);
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> sorted know vars(" +& intString(listLength(knvarsTmp)) +& ") for Jacobian DAE time: " +& realString(clock()) +& "\n");
        knvars = BackendDAEUtil.listVar(knvarsTmp);
        backendDAE = BackendDAEUtil.addBackendDAEKnVars(knvars,backendDAE);
        Debug.execStat("analytical Jacobians -> generated optimized jacobians", BackendDAE.RT_CLOCK_EXECSTAT_JACOBIANS);
     then
        ((backendDAE, inName, inDiffVars, diffedVars, inVars));
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.createJacobian failed"});
      then
        fail();
  end matchcontinue;
end createJacobian;

public function optimizeJacobianMatrix
  // function: optimizeJacobianMatrix
  // author: wbraun
  input BackendDAE.BackendDAE inBackendDAE;
  input list<DAE.ComponentRef> inComRef1; // eqnvars
  input list<DAE.ComponentRef> inComRef2; // vars to differentiate 
  output BackendDAE.BackendDAE outJacobian;
algorithm 
  outJacobian :=
    matchcontinue (inBackendDAE,inComRef1,inComRef2)
    local
      BackendDAE.BackendDAE backendDAE, backendDAE2;
      BackendDAE.Variables v;
      BackendDAE.EquationArray e;
      
      BackendDAE.Shared shared;
      BackendDAE.Matching matching;
      array<Integer> ea;
      
      Option<BackendDAE.IncidenceMatrix> om,omT;
      Boolean b;
      
      case (backendDAE as BackendDAE.DAE(BackendDAE.EQSYSTEM(v,e,om,omT,_)::{},shared),{},_)
        equation
          v = BackendDAEUtil.listVar({});
          ea = listArray({});
        then (BackendDAE.DAE(BackendDAE.EQSYSTEM(v,e,om,omT,BackendDAE.MATCHING(ea,ea,{}))::{},shared));
      case (backendDAE as BackendDAE.DAE(BackendDAE.EQSYSTEM(v,e,om,omT,_)::{},shared),_,{})
        equation
          v = BackendDAEUtil.listVar({});
          ea = listArray({});
        then (BackendDAE.DAE(BackendDAE.EQSYSTEM(v,e,om,omT,BackendDAE.MATCHING(ea,ea,{}))::{},shared));
      case (backendDAE,_,_)
        equation
          Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> optimize jacobians time: " +& realString(clock()) +& "\n");
          
          b = Flags.disableDebug(Flags.EXEC_STAT);
          backendDAE2 = BackendDAEUtil.getSolvedSystemforJacobians(backendDAE,
                                                                   SOME({"removeSimpleEquationsFast"}),
                                                                   NONE(),
                                                                   NONE(),
                                                                   SOME({"inlineArrayEqn",
                                                                         "constantLinearSystem",
                                                                         "removeSimpleEquations",
                                                                         "collapseIndependentBlocks"}));
          _ = Flags.set(Flags.EXEC_STAT, b);
          Debug.fcall(Flags.JAC_DUMP2, BackendDump.bltdump, ("jacdump2",backendDAE));
        then backendDAE2;
     else
       equation
         Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.optimizeJacobianMatrix failed"});
       then fail();
   end matchcontinue;
end optimizeJacobianMatrix;

public function generateSymbolicJacobian "function generateSymbolicJacobian
  author: lochel"
  input BackendDAE.BackendDAE inBackendDAE;
  input list<DAE.ComponentRef> inVars;      // wrt
  input BackendDAE.Variables indiffedVars;  // unknowns?
  input BackendDAE.Variables inseedVars;    //
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input String inMatrixName;
  output BackendDAE.BackendDAE outJacobian;
algorithm
  outJacobian := matchcontinue(inBackendDAE, inVars, indiffedVars, inseedVars, inStateVars, inInputVars, inParamVars, inMatrixName)
    local
      BackendDAE.BackendDAE bDAE;
      DAE.FunctionTree functions;
      list<DAE.ComponentRef> vars, comref_diffvars, allEqnCrefs;
      DAE.ComponentRef x;
      String dummyVarName;
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
      array< .DAE.Constraint> constrs;
      BackendDAE.EventInfo jacEventInfo; // eventInfo
      BackendDAE.ExternalObjectClasses jacExtObjClasses; // classes of external objects, contains constructor & destructor
      // end BackendDAE
      
      list<BackendDAE.Var> derivedVariables,jacknown,diffvars;
      list<BackendDAE.Equation> derivedEquations, knownEqn;
      list<list<BackendDAE.Equation>> derivedEquationslst;
      
      BackendDAE.EqSystem eqns;
      BackendDAE.Shared shared;
      
      Env.Cache cache;
      Env.Env env;      
      
      String matrixName;

    case(BackendDAE.DAE(shared=BackendDAE.SHARED(cache=cache,env=env)), {}, _, _, _, _, _, _) equation
      jacOrderedVars = BackendDAEUtil.emptyVars();
      jacKnownVars = BackendDAEUtil.emptyVars();
      jacExternalObjects = BackendDAEUtil.emptyVars();
      jacAliasVars =  BackendDAEUtil.emptyAliasVariables();
      jacOrderedEqs = BackendDAEUtil.listEquation({});
      jacRemovedEqs = BackendDAEUtil.listEquation({});
      jacInitialEqs = BackendDAEUtil.listEquation({});
      constrs = listArray({});
      functions = DAEUtil.avlTreeNew();
      jacEventInfo = BackendDAE.EVENT_INFO({},{});
      jacExtObjClasses = {};
      
      jacobian = BackendDAE.DAE({BackendDAE.EQSYSTEM(jacOrderedVars, jacOrderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING())}, BackendDAE.SHARED(jacKnownVars, jacExternalObjects, jacAliasVars, jacInitialEqs, jacRemovedEqs, constrs, cache, env, functions, jacEventInfo, jacExtObjClasses,BackendDAE.JACOBIAN(),{}));
    then jacobian;
     
    case(bDAE as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedVars=orderedVars,orderedEqs=orderedEqs)::{}, BackendDAE.SHARED(knownVars=knownVars, removedEqs=removedEqs ,cache=cache,env=env,  functionTree=functions)), vars, diffedVars, inseedVars, stateVars, inputVars, paramVars, matrixName) equation
      
      // Generate tmp varibales
      diffvars = BackendDAEUtil.varList(orderedVars);
      dummyVarName = ("dummyVar" +& matrixName);
      x = DAE.CREF_IDENT(dummyVarName,DAE.T_REAL_DEFAULT,{});

      // differentiate the equation system
      Debug.fcall(Flags.JAC_DUMP, print, "*** analytical Jacobians -> derived all algorithms time: " +& realString(clock()) +& "\n");
      derivedEquationslst = deriveAll(BackendDAEUtil.equationList(orderedEqs), {x}, functions, inputVars, paramVars, stateVars, knownVars, orderedVars, vars, (matrixName,false), {});
      derivedEquations = List.flatten(derivedEquationslst);
      Debug.fcall(Flags.JAC_DUMP, print, "*** analytical Jacobians -> created all derived equation time: " +& realString(clock()) +& "\n");
      
      // create BackendDAE.DAE with derivied vars and equations
      
      // all variables for new equation system
      // d(ordered vars)/d(dummyVar) 
      diffvars = BackendDAEUtil.varList(orderedVars);
      diffvars = List.sort(diffvars, BackendVariable.varIndexComparer);
      derivedVariables = creatallDiffedVars(diffvars, x, diffedVars, 0, (matrixName, false));

      jacOrderedVars = BackendDAEUtil.listVar(derivedVariables);
      // known vars: all variable from original system + seed
      jacKnownVars = BackendDAEUtil.emptyVars();
      jacKnownVars = BackendVariable.mergeVariables(jacKnownVars, orderedVars);
      jacKnownVars = BackendVariable.mergeVariables(jacKnownVars, knownVars);
      jacKnownVars = BackendVariable.mergeVariables(jacKnownVars, inseedVars);
      (jacKnownVars,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(jacKnownVars, BackendVariable.setVarDirectionTpl, (DAE.INPUT()));
      jacExternalObjects = BackendDAEUtil.emptyVars();
      jacAliasVars =  BackendDAEUtil.emptyAliasVariables();
      jacOrderedEqs = BackendDAEUtil.listEquation(derivedEquations);
      jacRemovedEqs = BackendDAEUtil.listEquation({});
      jacInitialEqs = BackendDAEUtil.listEquation({});
      constrs = listArray({});
      functions = DAEUtil.avlTreeNew();
      jacEventInfo = BackendDAE.EVENT_INFO({}, {});
      jacExtObjClasses = {};
      
      jacobian = BackendDAE.DAE(BackendDAE.EQSYSTEM(jacOrderedVars, jacOrderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING())::{}, BackendDAE.SHARED(jacKnownVars, jacExternalObjects, jacAliasVars, jacInitialEqs, jacRemovedEqs, constrs, cache, env, functions, jacEventInfo, jacExtObjClasses, BackendDAE.JACOBIAN(),{}));
      
    then jacobian;
 
    case(bDAE as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedVars=orderedVars,orderedEqs=orderedEqs)::{}, BackendDAE.SHARED(knownVars=knownVars, removedEqs=removedEqs, functionTree=functions)), vars, diffedVars, inseedVars, stateVars, inputVars, paramVars, _) equation
      
      diffvars = BackendDAEUtil.varList(orderedVars);
      (derivedVariables,comref_diffvars) = generateJacobianVars(diffvars, vars, (inMatrixName,false));
      Debug.fcall(Flags.JAC_DUMP, print, "*** analytical Jacobians -> created all derived vars: " +& "No. :" +& intString(listLength(comref_diffvars)) +& "time: " +& realString(clock()) +& "\n");
      derivedEquationslst = deriveAll(BackendDAEUtil.equationList(orderedEqs), vars, functions, inputVars, paramVars, stateVars, knownVars, orderedVars, comref_diffvars, (inMatrixName,false), {});
      derivedEquations = List.flatten(derivedEquationslst);
      false = (listLength(derivedVariables) == listLength(derivedEquations));
      Debug.fcall(Flags.JAC_DUMP, print, "*** analytical Jacobians -> failed vars are not equal to equations: " +& intString(listLength(derivedEquations)) +& " time: " +& realString(clock()) +& "\n");
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.generateSymbolicJacobian failed"});
    then fail();  
      
    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.generateSymbolicJacobian failed"});
    then fail();
  end matchcontinue;
end generateSymbolicJacobian;

public function createSeedVars
  // function: createSeedVars
  // author: wbraun
  input DAE.ComponentRef indiffVar;
  input tuple<String,Boolean> inMatrixName;
  output BackendDAE.Var outseedVar;
algorithm
  outseedVar := match(indiffVar,inMatrixName)
    local
      BackendDAE.Var  jacvar;
      DAE.ComponentRef derivedCref;
    case (_, _)
      equation 
        derivedCref = differentiateVarWithRespectToX(indiffVar, indiffVar, inMatrixName);
        jacvar = BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      then jacvar;
  end match;
end createSeedVars;

protected function generateJacobianVars "function generateJacobianVars
  author: lochel"
  input list<BackendDAE.Var> inVars1;
  input list<DAE.ComponentRef> inVars2;
  input tuple<String,Boolean> inMatrixName;
  output list<BackendDAE.Var> outVars;
  output list<DAE.ComponentRef> outcrefVars;
algorithm
  (outVars, outcrefVars) := matchcontinue(inVars1, inVars2, inMatrixName)
  local
    BackendDAE.Var currVar;
    list<BackendDAE.Var> restVar, r1, r2, r;
    list<DAE.ComponentRef> vars2,res,res1,res2;
    
    case({}, _, _)
    then ({},{});
      
    case(currVar::restVar, vars2, inMatrixName) equation
      (r1,res1) = generateJacobianVars2(currVar, vars2, inMatrixName);
      (r2,res2) = generateJacobianVars(restVar, vars2, inMatrixName);
      res = listAppend(res1, res2);
      r = listAppend(r1, r2);
    then (r,res);
      
    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function generateJacobianVars failed"});
    then fail();
  end matchcontinue;
end generateJacobianVars;

protected function generateJacobianVars2 "function generateJacobianVars2
  author: lochel"
  input BackendDAE.Var inVar1;
  input list<DAE.ComponentRef> inVars2;
  input tuple<String,Boolean> inMatrixName;
  output list<BackendDAE.Var> outVars;
  output list<DAE.ComponentRef> outcrefVars;
algorithm
  (outVars,outcrefVars) := matchcontinue(inVar1, inVars2, inMatrixName)
  local
    BackendDAE.Var var, r1;
    DAE.ComponentRef currVar, cref, derivedCref;
    list<DAE.ComponentRef> restVar,res,res1;
    list<BackendDAE.Var> r,r2;
    
    case(_, {}, _)
    then ({},{});
 
    // skip for dicrete variable
    case(var as BackendDAE.VAR(varName=cref,varKind=BackendDAE.DISCRETE()), currVar::restVar, _ ) equation
      (r2,res) = generateJacobianVars2(var, restVar, inMatrixName);
    then (r2,res);
    
    case(var as BackendDAE.VAR(varName=cref,varKind=BackendDAE.STATE()), currVar::restVar, _) equation
      cref = ComponentReference.crefPrefixDer(cref);
      derivedCref = differentiateVarWithRespectToX(cref, currVar, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      (r2,res1) = generateJacobianVars2(var, restVar, inMatrixName);
      res = listAppend({derivedCref}, res1);
      r = listAppend({r1}, r2);
    then (r,res);

    case(var as BackendDAE.VAR(varName=cref), currVar::restVar, _) equation
      derivedCref = differentiateVarWithRespectToX(cref, currVar, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      (r2,res1) = generateJacobianVars2(var, restVar, inMatrixName);
      res = listAppend({derivedCref}, res1);
      r = listAppend({r1}, r2);
    then (r,res);
      
    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function generateJacobianVars2 failed"});
    then fail();
  end matchcontinue;
end generateJacobianVars2;

public function creatallDiffedVars
  // function: help function for creatallDiffedVars
  // author: wbraun
  input list<BackendDAE.Var> inVars;
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inAllVars;
  input Integer inIndex;
  input tuple<String,Boolean> inMatrixName;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := matchcontinue(inVars, inCref,inAllVars,inIndex,inMatrixName)
  local
    BackendDAE.Var var, r1,v1;
    DAE.ComponentRef currVar, cref, derivedCref;
    list<BackendDAE.Var> restVar;
    list<BackendDAE.Var> r,r2;
    
    case({}, _, _, _, _)
    then {};
    // skip for dicrete variable
    case(BackendDAE.VAR(varName=currVar,varKind=BackendDAE.DISCRETE())::restVar,cref,inAllVars,inIndex, _) equation
      r = creatallDiffedVars(restVar,cref,inAllVars,inIndex, inMatrixName);
    then r;      
 
     case(BackendDAE.VAR(varName=currVar,varKind=BackendDAE.STATE())::restVar,cref,inAllVars,inIndex, _) equation
      ({v1}, _) = BackendVariable.getVar(currVar, inAllVars);
      currVar = ComponentReference.crefPrefixDer(currVar);
      derivedCref = differentiateVarWithRespectToX(currVar, cref, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, inIndex,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      r2 = creatallDiffedVars(restVar, cref, inAllVars, inIndex+1, inMatrixName);
      r = listAppend({r1}, r2);
    then r;
      
    case(BackendDAE.VAR(varName=currVar)::restVar,cref,inAllVars,inIndex, _) equation
      ({v1}, _) = BackendVariable.getVar(currVar, inAllVars);
      derivedCref = differentiateVarWithRespectToX(currVar, cref, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, inIndex,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      r2 = creatallDiffedVars(restVar, cref, inAllVars, inIndex+1, inMatrixName);
      r = listAppend({r1}, r2);
    then r;  
 
     case(BackendDAE.VAR(varName=currVar,varKind=BackendDAE.STATE())::restVar,cref,inAllVars,inIndex, _) equation
      currVar = ComponentReference.crefPrefixDer(currVar);
      derivedCref = differentiateVarWithRespectToX(currVar, cref, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      r2 = creatallDiffedVars(restVar, cref, inAllVars, inIndex, inMatrixName);
      r = listAppend({r1}, r2);
    then r;
      
    case(BackendDAE.VAR(varName=currVar)::restVar,cref,inAllVars,inIndex, _) equation
      derivedCref = differentiateVarWithRespectToX(currVar, cref, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      r2 = creatallDiffedVars(restVar, cref, inAllVars, inIndex, inMatrixName);
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
  input tuple<String,Boolean> inMatrixName; 
  output list<tuple<DAE.ComponentRef,Integer>> outTuple;
algorithm
  outTuple := matchcontinue(inStates, inStates2, inActInd,inAllVars,inNoStates, inMatrixName)
    local
      list<tuple<DAE.ComponentRef,Integer>> str;
      list<tuple<DAE.ComponentRef,Integer>> erg;
      list<DAE.ComponentRef> rest, states;
      DAE.ComponentRef curr,dState;
      Integer actInd, noStates;
      list<BackendDAE.Var> allVars;
      
    case ({}, states, _, _, _, _) then {};
    case (curr::rest, states, actInd, allVars, noStates, inMatrixName) equation
      ({BackendDAE.VAR(varKind = BackendDAE.STATE())}, _) = BackendVariable.getVar(curr, BackendDAEUtil.listVar(allVars));
      dState = ComponentReference.crefPrefixDer(curr);
      //actInd = actInd + (listLength(rest)+1);
      (str, actInd) = determineIndices2(dState, states, actInd, allVars,true,noStates, inMatrixName);
      erg = determineIndices(rest, states, actInd, allVars,noStates, inMatrixName);
      str = listAppend(str, erg);
    then str;
    case (curr::rest, states, actInd, allVars, noStates, inMatrixName) equation
      failure(({BackendDAE.VAR(varKind = BackendDAE.STATE())}, _) = BackendVariable.getVar(curr, BackendDAEUtil.listVar(allVars)));
      //actInd = noStates - (listLength(rest)+1);
      (str, actInd) = determineIndices2(curr, states, actInd, allVars,false,noStates, inMatrixName);
      erg = determineIndices(rest, states, actInd, allVars,noStates, inMatrixName);
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
  input tuple<String,Boolean> inMatrixName; 
  output list<tuple<DAE.ComponentRef,Integer>> outTuple;
  output Integer outActInd;
algorithm
  (outTuple,outActInd) := matchcontinue(inDStates, inStates, actInd, inAllVars,isDStateState,inNoStates, inMatrixName)
    local
      tuple<DAE.ComponentRef,Integer> str;
      list<tuple<DAE.ComponentRef,Integer>> erg;
      list<DAE.ComponentRef> rest;
      DAE.ComponentRef new, curr, dState;
      list<BackendDAE.Var> allVars;
      //String debug1;Integer debug2;
    case (dState, {}, actInd, allVars, _ , _, _ ) then ({}, actInd);
    case (dState,curr::rest, actInd, allVars, true, _, _ ) equation
      new = differentiateVarWithRespectToX(dState, curr, inMatrixName);
      str = (new ,actInd);
      //print("CRef: " +& ComponentReference.printComponentRefStr(new) +& " index: " +& intString(actInd) +& "\n");
      actInd = actInd+1;
      (erg, actInd) = determineIndices2(dState, rest, actInd, allVars, true, inNoStates, inMatrixName);
    then (str::erg, actInd);
    case (dState,curr::rest, actInd, allVars,false, _, _) equation
      new = differentiateVarWithRespectToX(dState, curr, inMatrixName);
      str = (new ,actInd);
      //print("CRef: " +& ComponentReference.printComponentRefStr(new) +& " index: " +& intString(actInd) +& "\n");
      actInd = actInd+1;
      (erg, actInd) = determineIndices2(dState, rest, actInd, allVars,false,inNoStates, inMatrixName);
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
      Debug.fcall(Flags.VAR_INDEX2,BackendDump.debugCrefStrIntStr,(currVar," ",currInd,"\n"));
      bt = BackendDAEUtil.treeAddList(bt,{currCREF});
    then (changedVar,bt);
    case (curr  as BackendDAE.VAR(varName=currCREF),{},bt) equation
      changedVar = BackendVariable.setVarIndex(curr,-1);
      Debug.fcall(Flags.VAR_INDEX2,BackendDump.debugCrefStr, (currCREF," -1\n"));
    then (changedVar,bt);
    case (curr  as BackendDAE.VAR(varName=currCREF),(currVar,currInd)::restTuple,bt) equation
      changedVar = BackendVariable.setVarIndex(curr,-1);
      Debug.fcall(Flags.VAR_INDEX2,BackendDump.debugCrefStr,(currCREF," -1\n"));
      (changedVar,bt) = changeIndices2(changedVar,restTuple,bt);
    then (changedVar,bt);
    else
    equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.changeIndices2() failed"});
    then fail();
  end matchcontinue;
end changeIndices2;

protected function deriveAll "function deriveAll
  author: lochel"
  input list<BackendDAE.Equation> inEquations;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inorderedVars;
  input list<DAE.ComponentRef> inDiffVars;
  input tuple<String,Boolean> inMatrixName;
  input list<list<BackendDAE.Equation>> inDerivedEquations;
  output list<list<BackendDAE.Equation>> outDerivedEquations;
algorithm
  outDerivedEquations := 
  matchcontinue(inEquations, inVars, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inorderedVars, inDiffVars, inMatrixName, inDerivedEquations)
    local
      BackendDAE.Equation currEquation, eqn1;
      DAE.FunctionTree functions;
      list<DAE.ComponentRef> vars;
      list<BackendDAE.Equation> restEquations, currDerivedEquations, restDerivedEquations, derivedEquations;
      BackendDAE.Variables inputVars, paramVars, stateVars, knownVars;
      DAE.ComponentRef dummycref;
      
    case({}, _, _, _, _, _, _, _, _, _, _) then listReverse(inDerivedEquations);
      
    case(currEquation::restEquations, vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _, _)
      equation
      //Debug.fcall(Flags.JAC_DUMP_EQN, print, "Derive Equation! Left on Stack: " +& intString(listLength(restEquations)) +& "\n");
      //Debug.fcall(Flags.JAC_DUMP_EQN, BackendDump.dumpEqns, {currEquation});
      //Debug.fcall(Flags.JAC_DUMP_EQN, print, "\n");
      //dummycref = ComponentReference.makeCrefIdent("$pDERdummy", DAE.T_REAL_DEFAULT, {});
      //Debug.fcall(Flags.JAC_DUMP_EQN,print, "*** analytical Jacobians -> derive one equation: " +& realString(clock()) +& "\n" );
      currDerivedEquations = derive(currEquation, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars, inMatrixName);
      //Debug.fcall(Flags.JAC_DUMP_EQN, BackendDump.dumpEqns, currDerivedEquations);
      //Debug.fcall(Flags.JAC_DUMP_EQN, print, "\n");
      //Debug.fcall(Flags.JAC_DUMP_EQN,print, "*** analytical Jacobians -> created other equations from that: " +& realString(clock()) +& "\n" );
     then
       deriveAll(restEquations, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars, inMatrixName, currDerivedEquations::inDerivedEquations);

    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.deriveAll failed"});
    then fail();
  end matchcontinue;
end deriveAll;

protected function derive "function derive
  author: lochel"
  input BackendDAE.Equation inEquation;
  input list<DAE.ComponentRef> inVar;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inorderedVars;
  input list<DAE.ComponentRef> inDiffVars;
  input tuple<String,Boolean> inMatrixName;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquation, inVar, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inorderedVars, inDiffVars, inMatrixName)
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
      Integer index,size;
      list<list<DAE.Exp>> derivedIn, derivedOut;
      Integer newAlgIndex;
      String s,s1;
      list<String> slst;
      DAE.Algorithm alg;
      list<DAE.Algorithm> algs;
    
    //remove dicrete Equation  
    case(currEquation, vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _) equation
      true = BackendDAEUtil.isDiscreteEquation(currEquation,inorderedVars,knownVars);
      Debug.fcall(Flags.JAC_DUMP, print,"BackendDAEOptimize.derive: discrete equation has been removed.\n");
    then {};
        
    case(currEquation as BackendDAE.WHEN_EQUATION(size=_), vars, functions, inputVars, paramVars, stateVars, knownVars,  _, _, _) equation
      Debug.fcall(Flags.JAC_DUMP, print,"BackendDAEOptimize.derive: WHEN_EQUATION has been removed.\n");
    then {};

    case(currEquation as BackendDAE.EQUATION(exp=lhs, scalar=rhs, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, _,  _, _) equation
      lhs_ = differentiateWithRespectToXVec(lhs, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars, inMatrixName);
      rhs_ = differentiateWithRespectToXVec(rhs, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars, inMatrixName);
      derivedEqns = List.threadMap1(lhs_, rhs_, createEqn, source);
    then derivedEqns;
      
    case(currEquation as BackendDAE.ARRAY_EQUATION(source=_), vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: derive failed [case: ARRAY_EQUATION]"});
    then fail();
      
    case(currEquation as BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=exp, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _) equation
      crefs = List.map2(vars,differentiateVarWithRespectToXR,cref, inMatrixName);
      exps = differentiateWithRespectToXVec(exp, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars, inMatrixName);
      derivedEqns = List.threadMap1(crefs, exps, createSolvedEqn, source);
    then derivedEqns;
      
    case(currEquation as BackendDAE.RESIDUAL_EQUATION(exp=exp, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _) equation
      exps = differentiateWithRespectToXVec(exp, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars, inMatrixName);
      derivedEqns = List.map1(exps, createResidualEqn, source);
    then derivedEqns;
      
    case(currEquation as BackendDAE.ALGORITHM(size=size,alg=alg, source=source), vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _)
    equation
      algs = deriveOneAlg(alg,vars,functions,inputVars,paramVars,stateVars,knownVars,inorderedVars,0,inDiffVars,inMatrixName);
      derivedEqns = List.map2(algs, createAlgorithmEqn, size, source);
    then derivedEqns;

    case(currEquation as BackendDAE.COMPLEX_EQUATION(source=_), vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _) equation
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

protected function createAlgorithmEqn
  input DAE.Algorithm Alg;
  input Integer Size;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm 
  outEqn := BackendDAE.ALGORITHM(Size, Alg, Source);
end createAlgorithmEqn;

public function differentiateVarWithRespectToX "function differentiateVarWithRespectToX
  author: lochel"
  input DAE.ComponentRef inCref;
  input DAE.ComponentRef inX;
  input tuple<String,Boolean> inMatrixName;
  //input list<BackendDAE.Var> inStateVars;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inX, inMatrixName)//, inStateVars)
    local
      DAE.ComponentRef cref, x;
      String id,str;
      list<BackendDAE.Var> stateVars;
      BackendDAE.Var v1;
      String matrixName;
     case(cref, x, (matrixName,true)) 
      equation
        cref = ComponentReference.joinCrefs(ComponentReference.makeCrefIdent(BackendDAE.partialDerivativeNamePrefix, ComponentReference.crefType(cref), {}),cref);
        cref = ComponentReference.appendStringCref(matrixName, cref);
      then 
        ComponentReference.joinCrefs(cref, x);
    case(cref, x, (matrixName,false))
      equation
        id = ComponentReference.printComponentRefStr(cref) +& BackendDAE.partialDerivativeNamePrefix +& matrixName +& ComponentReference.printComponentRefStr(x);
        id = Util.stringReplaceChar(id, ",", "$K");
        id = Util.stringReplaceChar(id, ".", "$P");
        id = Util.stringReplaceChar(id, "[", "$lB");
        id = Util.stringReplaceChar(id, "]", "$rB");
      then ComponentReference.makeCrefIdent(id, DAE.T_REAL_DEFAULT, {});
      
    case(cref, _, _)
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
  input tuple<String,Boolean> inMatrixName;
  output DAE.ComponentRef outCref;
algorithm
  outCref := differentiateVarWithRespectToX(inCref, inX, inMatrixName);
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
  input tuple<String,Boolean> inMatrixName;
  output list<DAE.Exp> outExpList;
algorithm
  outExpList := matchcontinue(inExpList, inLengthExpList, inConditios, inState, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inAllVars, inDiffVars, inMatrixName)
    local
      DAE.ComponentRef x;
      DAE.Exp curr,r1;
      list<DAE.Exp> rest, r2;
      DAE.FunctionTree functions;
      Integer LengthExpList,n, argnum;
      list<tuple<Integer,DAE.derivativeCond>> conditions;
      BackendDAE.Variables inputVars, paramVars, stateVars, knownVars;
      list<DAE.ComponentRef> diffVars;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then ({});
    case (curr::rest, LengthExpList, conditions, x, functions,inputVars, paramVars, stateVars, knownVars, _, diffVars,_) equation
      n = listLength(rest);
      argnum = LengthExpList - n;
      true = checkcondition(conditions,argnum);
      {r1} = differentiateWithRespectToXVec(curr, {x}, functions, inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars,inMatrixName);
      r2 = deriveExpListwrtstate(rest,LengthExpList,conditions, x, functions,inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars,inMatrixName);
    then (r1::r2);
    case (curr::rest, LengthExpList, conditions, x, functions,inputVars, paramVars, stateVars,knownVars, _, diffVars, _) equation
      r2 = deriveExpListwrtstate(rest,LengthExpList,conditions, x, functions,inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars, inMatrixName);
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
  input tuple<String,Boolean> inMatrixName;
  output list<DAE.Exp> outExpList;
algorithm
  outExpList := match(inExpList, inLengthExpList, inState, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inAllVars, inDiffVars, inMatrixName)
    local
      DAE.ComponentRef x;
      DAE.Exp curr,r1;
      list<DAE.Exp> rest, r2;
      DAE.FunctionTree functions;
      Integer LengthExpList,n, argnum;
      BackendDAE.Variables inputVars, paramVars, stateVars,knownVars;
      list<DAE.ComponentRef> diffVars;
    case ({}, _, _, _, _, _, _, _, _,_, _) then ({});
    case (curr::rest, LengthExpList, x, functions, inputVars, paramVars, stateVars, knownVars, _, diffVars, _) equation
      n = listLength(rest);
      argnum = LengthExpList - n;
      {r1} = differentiateWithRespectToXVec(curr, {x}, functions, inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars, inMatrixName);
      r2 = deriveExpListwrtstate2(rest,LengthExpList, x, functions, inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars, inMatrixName);
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
      DAE.Type et;
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
      then DAE.BINARY(e, DAE.ADD(DAE.T_REAL_DEFAULT), DAE.BINARY(derFun, DAE.MUL(DAE.T_REAL_DEFAULT), currDerVar));
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
      DAE.Type et;
      Absyn.Path fname;
      Boolean tuple_, builtin;
      DAE.InlineType inlineType;
      Integer nArgs1, nArgs2;
      DAE.CallAttributes attr;
    case ({}, _, _, _) then (DAE.RCONST(0.0));
    case (currVar::restVar, currDerVar::restDerVar, inState, functionCall as DAE.CALL(path=fname, expLst=varExpListTotal, attr=attr))
      equation
        e = partialNumericalDifferentiation(restVar, restDerVar, inState, functionCall);
        absCurr = DAE.LBINARY(DAE.RELATION(currVar,DAE.GREATER(DAE.T_REAL_DEFAULT),DAE.RCONST(1e-8),-1,NONE()),DAE.OR(DAE.T_BOOL_DEFAULT),DAE.RELATION(currVar,DAE.LESS(DAE.T_REAL_DEFAULT),DAE.RCONST(-1e-8),-1,NONE()));
        delta = DAE.IFEXP( absCurr, DAE.BINARY(currVar,DAE.MUL(DAE.T_REAL_DEFAULT),DAE.RCONST(1e-8)), DAE.RCONST(1e-8));
        nArgs1 = listLength(varExpListTotal);
        nArgs2 = listLength(restVar);
        varExpListHAdded = List.replaceAtWithFill(DAE.BINARY(currVar, DAE.ADD(DAE.T_REAL_DEFAULT),delta),nArgs1-(nArgs2+1), varExpListTotal,DAE.RCONST(0.0));
        derFun = DAE.BINARY(DAE.BINARY(DAE.CALL(fname, varExpListHAdded, attr), DAE.SUB(DAE.T_REAL_DEFAULT), DAE.CALL(fname, varExpListTotal, attr)), DAE.DIV(DAE.T_REAL_DEFAULT), delta);
      then DAE.BINARY(e, DAE.ADD(DAE.T_REAL_DEFAULT), DAE.BINARY(derFun, DAE.MUL(DAE.T_REAL_DEFAULT), currDerVar));
  end match;
end partialNumericalDifferentiation;

protected function deriveOneAlg "function deriveOneAlg
  author: lochel"
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
  input tuple<String,Boolean> inMatrixName;
  output list<DAE.Algorithm> outDerivedAlgorithms;
algorithm
  outDerivedAlgorithms := match(inAlgorithm, inVars, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inAllVars, inAlgIndex, inDiffVars, inMatrixName)
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
    case(_, {}, _, _, _, _, _, _, _,_, _) then {};
      
    case(currAlg as DAE.ALGORITHM_STMTS(statementLst=statementLst), currVar::restVars, functions, inputVars, paramVars, stateVars, knownVars, _, algIndex, diffVars, _)equation
      derivedStatementLst = differentiateAlgorithmStatements(statementLst, currVar, functions, inputVars, paramVars, stateVars, {}, knownVars, inAllVars, diffVars, inMatrixName);
      rAlgs1 = {DAE.ALGORITHM_STMTS(derivedStatementLst)};
      rAlgs2 = deriveOneAlg(currAlg, restVars, functions, inputVars, paramVars, stateVars, knownVars, inAllVars, algIndex, diffVars, inMatrixName);
      rAlgs1 = listAppend(rAlgs1, rAlgs2);
    then rAlgs1;
  end match;
end deriveOneAlg;

protected function differentiateAlgorithmStatements "function differentiateAlgorithmStatements
  author: lochel"
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
  input tuple<String,Boolean> inMatrixName;
  output list<DAE.Statement> outStatements;
algorithm
  outStatements := matchcontinue(inStatements, inVar, inFunctions, inInputVars, inParamVars, inStateVars, inControlVars, inKnownVars, inAllVars, inDiffVars, inMatrixName)
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
      DAE.Type type_;
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
      list<DAE.Exp> lhsTuple;
      list<DAE.Exp> derivedLHSTuple;
      DAE.ElementSource source_;
      Integer index;
    case({}, _, _, _, _, _, _, _, _,_, _) then {};
      
    //remove dicrete Equation
    case ((currStatement as DAE.STMT_ASSIGN(type_=type_, exp1=lhs, exp=rhs,source=source_))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      true = BackendDAEUtil.isDiscreteExp(lhs,allVars,knownVars);
      true = BackendDAEUtil.isDiscreteExp(rhs,allVars,knownVars);
      Debug.fcall(Flags.JAC_DUMP,print,"BackendDAEOptimize.differentiateAlgorithmStatements: discrete equation has been removed.\n");
    then {};
      
    case((currStatement as DAE.STMT_ASSIGN(type_=type_, exp1=lhs, exp=rhs,source=source_))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _) 
    equation
      controlparaVars = BackendVariable.addVars(controlVars, paramVars);
      {derivedLHS} = differentiateWithRespectToXVec(lhs, {var}, functions, inputVars, controlparaVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
      {derivedRHS} = differentiateWithRespectToXVec(rhs, {var}, functions, inputVars, controlparaVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = {DAE.STMT_ASSIGN(type_, derivedLHS, derivedRHS, source_), currStatement};
      //derivedStatements1 = List.threadMap3(derivedLHS, derivedRHS, createDiffStatements, type_, currStatement, source);
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case ((currStatement as DAE.STMT_TUPLE_ASSIGN(type_=type_,exp=rhs,expExpLst=lhsTuple,source=source_))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars,  diffVars, _)
    equation
      controlparaVars = BackendVariable.addVars(controlVars, paramVars);
      {derivedLHSTuple} = List.map9(lhsTuple,differentiateWithRespectToXVec, {var}, functions, inputVars, controlparaVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
      {derivedRHS} = differentiateWithRespectToXVec(rhs, {var}, functions, inputVars, controlparaVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = {DAE.STMT_TUPLE_ASSIGN(type_, derivedLHSTuple, derivedRHS, source_), currStatement};
      //Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.differentiateAlgorithmStatements failed: DAE.STMT_TUPLE_ASSIGN"});
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_ASSIGN_ARR(exp=rhs)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.differentiateAlgorithmStatements failed: DAE.STMT_ASSIGN_ARR"});
    then fail();
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.NOELSE(), source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars,  diffVars, inMatrixName);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.NOELSE(), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSEIF(exp=elseif_exp, statementLst=elseif_statementLst, else_=elseif_else_), source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements2 = differentiateAlgorithmStatements({DAE.STMT_IF(elseif_exp, elseif_statementLst, elseif_else_, source)}, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSE(statementLst=else_statementLst), source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements2 = differentiateAlgorithmStatements(else_statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_FOR(type_=type_, iterIsArray=iterIsArray, iter=ident, index=index, range=exp, statementLst=statementLst, source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      cref = ComponentReference.makeCrefIdent(ident, DAE.T_INTEGER_DEFAULT, {});
      controlVar = BackendDAE.VAR(cref, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      controlVars = listAppend(controlVars, {controlVar});
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);

      derivedStatements1 = {DAE.STMT_FOR(type_, iterIsArray, ident, index, exp, derivedStatements1, source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;

    case(DAE.STMT_WHILE(exp=exp, statementLst=statementLst, source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = {DAE.STMT_WHILE(exp, derivedStatements1, source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_WHEN(exp=exp)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName)
    equation
      //derivedStatements1 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      Debug.fcall(Flags.JAC_DUMP,print,"BackendDAEOptimize.differentiateAlgorithmStatements: WHEN has been removed.\n");
    then {};
      
    case((currStatement as DAE.STMT_ASSERT(cond=exp))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars,  diffVars, _)
    equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars,  diffVars, inMatrixName);
      derivedStatements1 = currStatement::derivedStatements2;
    then derivedStatements1;
      
    case((currStatement as DAE.STMT_TERMINATE(msg=exp))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = currStatement::derivedStatements2;
    then derivedStatements1;
      
    case(DAE.STMT_REINIT(value=exp)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
    then derivedStatements1;
      
    case(DAE.STMT_NORETCALL(exp=exp, source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      // e2 = differentiateWithRespectToX(e1, var, functions, {}, {}, {});
      // derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      // derivedStatements1 = listAppend({DAE.STMT_NORETCALL(e2, elemSrc)}, derivedStatements2);
    then fail();
      
    case((currStatement as DAE.STMT_RETURN(source=source))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = currStatement::derivedStatements2;
    then derivedStatements1;
      
    case((currStatement as DAE.STMT_BREAK(source=source))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = currStatement::derivedStatements2;
    then derivedStatements1;
      
    case(_, _, _, _, _, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.differentiateAlgorithmStatements failed"});
    then fail();
  end matchcontinue;
end differentiateAlgorithmStatements;

protected function createDiffStatements
  input DAE.Exp inLHS;
  input DAE.Exp inRHS;
  input DAE.Type inType;
  input DAE.Statement inStmt;
  input DAE.ElementSource Source;
  output list<DAE.Statement> outEqn;
algorithm outEqn := match(inLHS,inRHS,inType,inStmt,Source)
  local
  case (inLHS,inRHS,inType,inStmt,Source) then {DAE.STMT_ASSIGN(inType, inLHS, inRHS, Source), inStmt};
 end match;
end createDiffStatements;

protected function differentiateWithRespectToXVec "function differentiateWithRespectToXVec
  author: wbraun"
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inX;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inAllVars;
  input list<DAE.ComponentRef> inDiffVars;
  input tuple<String,Boolean> inMatrixName;
  output list<DAE.Exp> outExp;
algorithm
  outExp := matchcontinue(inExp, inX, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inAllVars, inDiffVars, inMatrixName)
    local
      list<DAE.ComponentRef> xlist;
      list<DAE.Exp> dxlist,dxlist1,dxlist2;
      DAE.ComponentRef x, cref, cref_;
      DAE.FunctionTree functions;
      DAE.Exp e1, e1_, e2, e2_, e;
      DAE.Type et;
      DAE.Operator op;
      
      Absyn.Path fname,derFname;
      
      list<DAE.Exp> expList1, expList2;
      list<list<DAE.Exp>> expListLst;
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
      
    case(e as DAE.ICONST(_), xlist,functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
        dxlist = createDiffListMeta(e,xlist,diffInt, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName)));
    then dxlist;
      
    case( e as DAE.RCONST(_), xlist,functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName)
      equation
        dxlist = createDiffListMeta(e,xlist,diffRealZero, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName)));
    then dxlist;
    
    // d(time)/d(x)
    case(e as DAE.CREF(componentRef=(cref as DAE.CREF_IDENT(ident = "time",subscriptLst = {}))), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, _)
      equation
        dxlist = createDiffListMeta(e,xlist,diffRealZero, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName)));
    then dxlist;
      
    // dummy diff
    case(e as DAE.CREF(componentRef=cref),xlist, functions, inputVars, paramVars, stateVars, knownVars,  allVars, diffVars, _) equation
      dxlist = createDiffListMeta(e,xlist,diffCref, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName)));
    then dxlist;

    // known vars
    case (DAE.CREF(componentRef=cref, ty=et), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
      ({(v1 as BackendDAE.VAR(bindExp=SOME(e1)))}, _) = BackendVariable.getVar(cref, knownVars);
      dxlist = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
    then dxlist;

    // diff crefVar
    case(e as DAE.CREF(componentRef=cref),xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, _) equation
      dxlist = createDiffListMeta(e,xlist,diffCrefVar, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName)));
    then dxlist;
    
    // binary
    case(DAE.BINARY(exp1=e1, operator=op, exp2=e2),xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, _) equation
      dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName);
      dxlist2 = differentiateWithRespectToXVec(e2, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName);
      dxlist = List.threadMap3(dxlist1,dxlist2,mergeBin,op,e1,e2);
    then dxlist;
    
    // uniary
    case(DAE.UNARY(operator=op, exp=e1), xlist, functions, inputVars, paramVars, stateVars, knownVars,  allVars, diffVars, _) equation
      dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars,  allVars, diffVars, inMatrixName);
      dxlist = List.map1(dxlist1,mergeUn,op);
    then dxlist;

    // der(x)
    case (e as DAE.CALL(path=fname, expLst={e1}), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, _)
      equation
      Builtin.isDer(fname);
      dxlist = createDiffListMeta(e,xlist,diffDerCref, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName)));
    then dxlist;

    // function call
    case (e as DAE.CALL(path=_, expLst={e1}), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
        dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
        dxlist = List.map2(dxlist1,mergeCall,e1,e);
    then dxlist;

    // function call more than one argument
    case (e as DAE.CALL(path=_, expLst=expList1), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
        expListLst = List.map9( expList1, differentiateWithRespectToXVec, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
        expListLst = List.transposeList(expListLst);
        dxlist = List.map1(expListLst,mergeCallExpList,e);
    then dxlist;      
      
    // extern functions (analytical and numeric)
    case (e as DAE.CALL(path=fname, expLst=expList1), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
       dxlist = createDiffListMeta(e,xlist,diffNumCall, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName)));
    then dxlist;
    
    // cast
    case (DAE.CAST(ty=et, exp=e1), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _) equation
      dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
      dxlist = List.map1(dxlist1,mergeCast,et);
    then dxlist;

    // relations
    case (e as DAE.RELATION(e1, op, e2, index, optionExpisASUB), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _) equation
        dxlist = createDiffListMeta(e,xlist,diffRealZero, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName)));
    then dxlist;

      // differentiate if-expressions
    case (DAE.IFEXP(expCond=e, expThen=e1, expElse=e2), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
      dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
      dxlist2 = differentiateWithRespectToXVec(e2, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
      dxlist = List.threadMap1(dxlist1,dxlist2,mergeIf,e);
    then dxlist;

      
    case (e as DAE.ARRAY(ty = et,scalar = b,array = expList1), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
        expListLst = List.map9(expList1, differentiateWithRespectToXVec, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
        expListLst = List.transposeList(expListLst);
        dxlist = List.map2(expListLst, mergeArray, et, b);
      then
        dxlist;
    
    case (DAE.TUPLE(PR = expList1), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,diffVars, _)
      equation
        expListLst = List.map9(expList1, differentiateWithRespectToXVec, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
        expListLst = List.transposeList(expListLst);
        dxlist = List.map(expListLst, mergeTuple);
      then
        dxlist;
    /*
    case (DAE.ASUB(exp = e,sub = expList1), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
        e1_ = differentiateWithRespectToXVec(e, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
      then
       e1_;
    */       
    case(e, xlist, _, _, _, _, _, _,_, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE_JAC);
        str = "BackendDAEOptimize.differentiateWithRespectToXVec failed: " +& ExpressionDump.printExpStr(e) +& "\n";
        print(str);
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
        true = Flags.isSet(Flags.FAILTRACE_JAC);
         str = "BackendDAEOptimize.createDiffListMeta failed: " +& ExpressionDump.printExpStr(e) +& " | " +& ComponentReference.printComponentRefStr(diff_cref);
         print(str);
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
  input tuple<DAE.Exp, DAE.ComponentRef, Option<tuple<DAE.FunctionTree,BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, list<DAE.ComponentRef>, tuple<String,Boolean>>>> inTplExpTypeA;
  output DAE.Exp outTplExpTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA := matchcontinue(inTplExpTypeA)
  local
    DAE.ComponentRef cref,cref_,x;
    DAE.Type et;
    tuple<String,Boolean> matrixName;
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, _, _, _, _, _, _, matrixName))))
      equation
      cref_ = differentiateVarWithRespectToX(cref, x, matrixName);
      //print(" *** diffCrefVar : " +& ComponentReference.printComponentRefStr(cref) +& " w.r.t " +& ComponentReference.printComponentRefStr(x) +& "\n");
    then DAE.CREF(cref_, et);
 end matchcontinue;
end diffCrefVar;

protected function diffCref
  input tuple<DAE.Exp, DAE.ComponentRef, Option<tuple<DAE.FunctionTree,BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, list<DAE.ComponentRef>, tuple<String,Boolean>>>> inTplExpTypeA;
  output DAE.Exp outTplExpTypeA;
algorithm
  outTplExpTypeA := matchcontinue(inTplExpTypeA)
  local
    DAE.Type et;
    DAE.FunctionTree functions;
    DAE.ComponentRef x, cref,cref_;
    list<DAE.ComponentRef> diffVars;
    DAE.Exp e1,e1_;
    BackendDAE.Variables inputVars, paramVars, stateVars, knownVars,allVars;
    BackendDAE.Var v1,v2;
    list<Boolean> b_lst;
    Integer i;
    String matrixName;
    
    // d(discrete)/d(x) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, _, _, _, _, allVars, _, _))))
      equation
      ({v1 as BackendDAE.VAR(varKind = BackendDAE.DISCRETE())}, _) = BackendVariable.getVar(cref, allVars);
    then DAE.RCONST(0.0);    

    //tearing
    // d(x)/d(x)
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, _, _, _, _, _, _, (_,true)))))
      equation
        true = ComponentReference.crefEqualNoStringCompare(cref, x);
        e1 = Expression.makeConstOne(et);
      then
        e1;
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, _, _, _, _, _, diffVars, (_,true)))))
      equation
      b_lst = List.map1(diffVars,ComponentReference.crefEqual,cref);
      true = Util.boolOrList(b_lst);
      (e1,_) = Expression.makeZeroExpression(Expression.arrayDimension(et));
    then
      e1;
            
    // d(x)/d(x)
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, _, _, _, _, _, diffVars, (matrixName,false)))))
      equation
      b_lst = List.map1(diffVars,ComponentReference.crefEqual,cref);
      true = Util.boolOrList(b_lst);
      cref_ = differentiateVarWithRespectToX(cref, cref, (matrixName,false));
      //print(" *** diffCref : " +& ComponentReference.printComponentRefStr(cref) +& " w.r.t " +& ComponentReference.printComponentRefStr(x) +& "\n");
    then
      DAE.CREF(cref_, et);
    
    // d(state)/d(x) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, _, _, stateVars, _, _, _, _))))
      equation
      ({v1}, _) = BackendVariable.getVar(cref, stateVars);
    then DAE.RCONST(0.0);

    // d(input)/d(x) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, inputVars, _, _, _, _, _, _))))
      equation
      ({v1}, _) = BackendVariable.getVar(cref, inputVars);
    then DAE.RCONST(0.0);

    // d(parameter)/d(x) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, _, paramVars, _, _, _, _, _))))
      equation
      ({v1}, _) = BackendVariable.getVar(cref, paramVars);
    then DAE.RCONST(0.0);
      
 end matchcontinue;
end diffCref;

protected function diffDerCref
  input tuple<DAE.Exp, DAE.ComponentRef, Option<tuple<DAE.FunctionTree,BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, list<DAE.ComponentRef>, tuple<String,Boolean>>>> inTplExpTypeA;
  output DAE.Exp outTplExpTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA := matchcontinue(inTplExpTypeA)
  local
    Absyn.Path fname;
    DAE.Exp e1;
    DAE.ComponentRef x,cref;
    tuple<String,Boolean> matrixName;
    Option<tuple<DAE.FunctionTree,BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, list<DAE.ComponentRef>, tuple<String,Boolean>>> tpl;
    
    case((DAE.CALL(path=fname, expLst={e1}),x,tpl as SOME((_, _, _, _, _, _, _, matrixName as (_,true)))))
      equation
        e1 = diffCref((e1,x,tpl));
    then e1; 
    
    case((DAE.CALL(path=fname, expLst={e1}),x,SOME((_, _, _, _, _, _, _, matrixName))))
      equation
      cref = Expression.expCref(e1);
      cref = ComponentReference.crefPrefixDer(cref);
      //x = DAE.CREF_IDENT("pDERdummy",DAE.T_REAL_DEFAULT,{});
      cref = differentiateVarWithRespectToX(cref, x, matrixName);
    then DAE.CREF(cref, DAE.T_REAL_DEFAULT);
 end matchcontinue;
end diffDerCref;

protected function diffNumCall
  input tuple<DAE.Exp, DAE.ComponentRef, Option<tuple<DAE.FunctionTree, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, list<DAE.ComponentRef>, tuple<String,Boolean>>>> inTplExpTypeA;
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
    DAE.Type et;
    DAE.Type tp;
    Integer nArgs;
    BackendDAE.Variables inputVars, paramVars, stateVars, knownVars, allVars;
    list<DAE.ComponentRef> diffVars;
    DAE.FunctionTree functions;
    list<tuple<Integer,DAE.derivativeCond>> conditions;
    DAE.CallAttributes attr;
    tuple<String,Boolean> inMatrixName;
    //Option<tuple<DAE.FunctionTree, list<BackendDAE.Var>, list<BackendDAE.Var>, list<BackendDAE.Var>, list<BackendDAE.Var>, list<BackendDAE.Var>>> inTpl;
    // extern functions (analytical)
    case ((e as DAE.CALL(path=fname, expLst=expList1), x, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName))))
      equation
        nArgs = listLength(expList1);
        (DAE.FUNCTION_DER_MAPPER(derivativeFunction=derFname,conditionRefs=conditions), tp) = Derive.getFunctionMapper(fname, functions);
        expList2 = deriveExpListwrtstate(expList1, nArgs, conditions, x, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
        e1 = partialAnalyticalDifferentiation(expList1, expList2, e, derFname, listLength(expList2));
        (e1,_) = ExpressionSimplify.simplify(e1);
      then e1;
    case ((e as DAE.CALL(path=fname, expLst=expList1), x, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName))))
      equation
        //(SOME((functions, inputVars, paramVars, stateVars, knownVars, diffVars))) = inTpl;
        Debug.fcall(Flags.JAC_DUMP,print,"differentiate function call " +& Absyn.pathString(fname) +& "(" +& ExpressionDump.printExpListStr(expList1) +& ") numerical.\n");
        nArgs = listLength(expList1);
        expList2 = deriveExpListwrtstate2(expList1, nArgs, x, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
        Debug.fcall(Flags.JAC_DUMP,print,"derived ExpList args: (" +& ExpressionDump.printExpListStr(expList2) +& "\n");
        e1 = partialNumericalDifferentiation(expList1, expList2, x, e);
        Debug.fcall(Flags.JAC_DUMP,print,"derived exp : (" +& ExpressionDump.printExpStr(e1) +& "\n");
        (e1,_) = ExpressionSimplify.simplify(e1);
        Debug.fcall(Flags.JAC_DUMP,print,"derived exp simplify: (" +& ExpressionDump.printExpStr(e1) +& "\n");
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
    DAE.Type et;
    String str;
    //sin(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("sin")))
      equation
        e = DAE.BINARY(inExp1, DAE.MUL(DAE.T_REAL_DEFAULT), DAE.CALL(Absyn.IDENT("cos"),{inExp2},DAE.callAttrBuiltinReal));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    // cos(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("cos")))
      equation
        e = DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT), DAE.BINARY(inExp1,DAE.MUL(DAE.T_REAL_DEFAULT), DAE.CALL(Absyn.IDENT("sin"),{inExp2},DAE.callAttrBuiltinReal)));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    // ln(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("log")))
      equation
        e = DAE.BINARY(inExp1, DAE.DIV(DAE.T_REAL_DEFAULT), inExp2);
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    // log10(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("log10")))
      equation
        e = DAE.BINARY(inExp1, DAE.DIV(DAE.T_REAL_DEFAULT), DAE.BINARY(inExp2, DAE.MUL(DAE.T_REAL_DEFAULT), DAE.CALL(Absyn.IDENT("log"),{DAE.RCONST(10.0)},DAE.callAttrBuiltinReal)));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    // exp(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("exp")))
      equation
        e = DAE.BINARY(inExp1,DAE.MUL(DAE.T_REAL_DEFAULT), DAE.CALL(Absyn.IDENT("exp"),{inExp2},DAE.callAttrBuiltinReal));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    // sqrt(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("sqrt")))
      equation
        e = DAE.BINARY(
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.T_REAL_DEFAULT),
          DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.T_REAL_DEFAULT),
          DAE.CALL(Absyn.IDENT("sqrt"),{inExp2},DAE.callAttrBuiltinReal))),DAE.MUL(DAE.T_REAL_DEFAULT),inExp1);
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
   // abs(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("abs")))
      equation
        e = DAE.IFEXP(DAE.RELATION(inExp2,DAE.GREATEREQ(DAE.T_REAL_DEFAULT),DAE.RCONST(0.0),-1,NONE()), inExp1, DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),inExp1));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;

    // openmodelica build call $_start(x)
    case (inExp1,inExp2,inOrgExp1 as DAE.CALL(path=Absyn.IDENT("$_start")))
      equation
        e = DAE.RCONST(0.0);
      then e;
  end match;
end mergeCall;


protected function mergeCallExpList
  input list<DAE.Exp> inExp1Lst;
  input DAE.Exp inOrgExp1;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp1Lst,inOrgExp1)
  local
    DAE.Exp e,z1,z2;
    DAE.Exp dz1,dz2;
    DAE.Type et;
    //max(x,y)
    case ({dz1,dz2},inOrgExp1 as DAE.CALL(path=Absyn.IDENT("max"),expLst={z1,z2}))
      equation
        e = DAE.IFEXP(DAE.RELATION(z1, DAE.GREATER(DAE.T_REAL_DEFAULT), z2, -1, NONE()),
                      dz1, dz2);
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
  end match;
end mergeCallExpList;

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
    DAE.Type et;
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
  input DAE.Type inType;
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

protected function mergeArray
  input list<DAE.Exp> inExplst;
  input DAE.Type inType;
  input Boolean inScalar;
  output DAE.Exp outExp;
algorithm
  outExp :=  DAE.ARRAY(inType, inScalar, inExplst);
end mergeArray;

protected function mergeTuple
  input list<DAE.Exp> inExplst;
  output DAE.Exp outExp;
algorithm
  outExp :=  DAE.TUPLE(inExplst);
end mergeTuple;




/*
 * parallel backend stuff
 *
 */
public function collapseIndependentBlocksPast
  "Finds independent partitions of the equation system by "
  input BackendDAE.BackendDAE dlow;
  output BackendDAE.BackendDAE outDlow;
  output Boolean outRunMatching;
algorithm
  outDlow := collapseIndependentBlocks(dlow);
  outRunMatching := true;
end collapseIndependentBlocksPast;

public function collapseIndependentBlocks
  "Finds independent partitions of the equation system by "
  input BackendDAE.BackendDAE dlow;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match (dlow)
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
    case (BackendDAE.DAE(systs,shared))
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
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match (dlow)
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
    case (BackendDAE.DAE({syst},shared))
      equation
        (systs,shared) = partitionIndependentBlocksHelper(syst,shared,Error.getNumErrorMessages());
      then BackendDAE.DAE(systs,shared); // TODO: Add support for partitioned systems of equations
  end match;
end partitionIndependentBlocks;

protected function partitionIndependentBlocksHelper
  "Finds independent partitions of the equation system by "
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer i;
  output list<BackendDAE.EqSystem> systs;
  output BackendDAE.Shared oshared;
algorithm
  (systs,oshared) := matchcontinue (isyst,ishared,i)
    local
      BackendDAE.IncidenceMatrix m,mT;
      array<Integer> ixs,ixsT;
      list<Integer> lst,lst2;
      Boolean b;
      String str;
      list<String> strs;
      Integer i,i2;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      
    case (syst,shared,_)
      equation
        // print("partitionIndependentBlocks: TODO: Implement me\n");
        (syst,m,mT) = BackendDAEUtil.getIncidenceMatrixfromOption(syst,shared,BackendDAE.NORMAL());
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
        Error.assertionOrAddSourceMessage(i1 == i2,
          Util.if_(i1 > i2, Error.OVERDET_EQN_SYSTEM, Error.UNDERDET_EQN_SYSTEM), 
          {s1,s2}, Absyn.dummyInfo);
        
        partitionEquations(BackendDAEUtil.equationArraySize(arr),arr,ixs,ea);
        partitionVars(i2,arr,vars,ixs,mT,va);
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
  input array<Integer> inIxs;
  output Boolean change;
algorithm
  change := match (b,ix,n,m,mT,inIxs)
    local
      Integer i;
      list<Integer> lst;
      list<list<Integer>> lsts;
      array<Integer> ixs;
      
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
      DAE.Type et;
      Integer i;
    case ((BackendDAE.EQUATION(e1,e2,source),i))
      equation
        // This is ok, because EQUATION is not an array equation :D
        DAE.T_REAL(source = _) = Expression.typeof(e1);
        false = Expression.isZero(e1) or Expression.isZero(e2);
        e = DAE.BINARY(e1,DAE.SUB(DAE.T_REAL_DEFAULT),e2);
        (e,_) = ExpressionSimplify.simplify(e);
        source = DAEUtil.addSymbolicTransformation(source, DAE.OP_RESIDUAL(e1,e2,e));
        ntpl = (BackendDAE.EQUATION(DAE.RCONST(0.0),e,source),i);
      then ntpl;
    else tpl;
  end matchcontinue;
end residualForm2;




/*
 * simplify time independent function calls
 *
 */
public function simplifyTimeIndepFuncCalls "function simplifyTimeIndepFuncCalls
  simplifies time independent built in function calls like
  pre(param) -> param
  der(param) -> 0.0
  change(param) -> false
  edge(param) -> false
  author: Frenkel TUD 2012-06"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
algorithm
  (outDAE,outRunMatching) := BackendDAEUtil.mapEqSystemAndFold(inDAE,simplifyTimeIndepFuncCalls0,false);
  outDAE := simplifyTimeIndepFuncCallsShared(outDAE);
end simplifyTimeIndepFuncCalls;

protected function simplifyTimeIndepFuncCalls0 "function simplifyTimeIndepFuncCalls0
  author: Frenkel TUD 2012-06"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared,Boolean> sharedChanged;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> osharedChanged;
algorithm
  (osyst,osharedChanged) := 
    matchcontinue(isyst,sharedChanged)
    local
      BackendDAE.Variables orderedVars "orderedVars ; ordered Variables, only states and alg. vars" ;
      BackendDAE.EquationArray orderedEqs "orderedEqs ; ordered Equations" ;
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
      BackendDAE.Matching matching;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching),(shared, _))
      equation
        ((_,true)) = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(orderedEqs,traversersimplifyTimeIndepFuncCalls,(BackendVariable.daeKnVars(shared),false));
      then
        (BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching),(shared,true));
    else
      (isyst,sharedChanged);
  end matchcontinue;
end simplifyTimeIndepFuncCalls0;

protected function traversersimplifyTimeIndepFuncCalls "function traversersimplifyTimeIndepFuncCalls
  author: Frenkel TUD 2012-06"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,Boolean>> itpl;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,Boolean>> outTpl;
protected
  DAE.Exp e;
  tuple<BackendDAE.Variables,Boolean> tpl;
algorithm
  (e,tpl) := itpl;
  outTpl := Expression.traverseExp(e,traverserExpsimplifyTimeIndepFuncCalls,tpl);
end traversersimplifyTimeIndepFuncCalls;

protected function traverserExpsimplifyTimeIndepFuncCalls "function traverserExpsimplifyTimeIndepFuncCalls
  author: Frenkel TUD 2012-06"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,Boolean>> tpl;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,Boolean>> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
    local
      BackendDAE.Variables vars;
      DAE.Type tp;
      DAE.Exp e,zero;
      DAE.ComponentRef cr;
    case((DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr,ty=tp)}),(vars,_)))
      equation
        (_,_) = BackendVariable.getVar(cr, vars);
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then 
        ((zero,(vars,true)));
    case((DAE.CALL(path=Absyn.IDENT(name = "pre"),expLst={e as DAE.CREF(componentRef=cr,ty=tp)}),(vars,_)))
      equation
        (_,_) = BackendVariable.getVar(cr, vars);
      then
        ((e,(vars,true)));
    case((DAE.CALL(path=Absyn.IDENT(name = "change"),expLst={e as DAE.CREF(componentRef=cr,ty=tp)}),(vars,_)))
      equation
        (_,_) = BackendVariable.getVar(cr, vars);
      then 
        ((DAE.BCONST(false),(vars,true)));
    case((DAE.CALL(path=Absyn.IDENT(name = "edge"),expLst={e as DAE.CREF(componentRef=cr,ty=tp)}),(vars,_)))
      equation
        (_,_) = BackendVariable.getVar(cr, vars);
      then
        ((DAE.BCONST(false),(vars,true)));
    case tpl then tpl;
  end matchcontinue;
end traverserExpsimplifyTimeIndepFuncCalls;

protected function simplifyTimeIndepFuncCallsShared "function simplifyTimeIndepFuncCallsShared
  simplifies time independent built in function calls like
  pre(param) -> param
  der(param) -> 0.0 
  change(param) -> false
  edge(param) -> false
  author: Frenkel TUD 2012-06"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE:= match (inDAE)
    local
      BackendDAE.Variables knvars,exobj;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray remeqns,inieqns;
      array<DAE.Constraint> constrs;
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcTree;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.BackendDAEType btp; 
      BackendDAE.EqSystems systs;  
      BackendDAE.Shared shared;
    case (BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,cache,env,funcTree,eventInfo,eoc,btp,symjacs)))
      equation
        _ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(inieqns,traversersimplifyTimeIndepFuncCalls,(knvars,false));
        _ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(remeqns,traversersimplifyTimeIndepFuncCalls,(knvars,false));
      then 
        BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,cache,env,funcTree,eventInfo,eoc,btp,symjacs));
  end match;
end simplifyTimeIndepFuncCallsShared;




/*
 * tearing
 *
 */
public function tearingSystemNew "function tearingSystem
  author: Frenkel TUD 2012-05"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
algorithm
  (outDAE,outRunMatching) := BackendDAEUtil.mapEqSystemAndFold(inDAE,tearingSystemNew0,false);
end tearingSystemNew;

protected function tearingSystemNew0 "function tearingSystem0
  author: Frenkel TUD 2012-05"
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
      
    case (syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)),(shared, b1))
      equation
        (syst,shared,b2) = tearingSystemNew1(syst,shared,comps);
        b = b1 or b2;
      then
        (syst,(shared,b));
  end matchcontinue;  
end tearingSystemNew0;

protected function tearingSystemNew1 "function tearingSystemNew1
  author: Frenkel TUD 2012-05"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StrongComponents inComps;  
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Boolean outRunMatching;
algorithm
  (osyst,oshared,outRunMatching):=
  matchcontinue (isyst,ishared,inComps)
    local
      list<Integer> eindex,vindx,tvars,residual;
      list<list<Integer>> othercomps;
      Boolean b,b1;
      BackendDAE.EqSystem syst,subsyst;
      BackendDAE.Shared shared;
      BackendDAE.StrongComponents comps;
      BackendDAE.StrongComponent comp,comp1;   
      array<Integer> ass1,ass2,columark,number,lowlink;
      Integer size,tornsize;
      list<BackendDAE.Equation> eqn_lst; 
      list<BackendDAE.Var> var_lst;    
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.IncidenceMatrix m,m1;
      BackendDAE.IncidenceMatrix mt,mt1; 
      array<DAE.Constraint> constrs;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> ojac;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      BackendDAE.JacobianType jacType;
      BackendDAE.AdjacencyMatrixEnhanced me;
      BackendDAE.AdjacencyMatrixTEnhanced meT;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;      
      
    case (_,_,{})
      then (isyst,ishared,false);
    case (_,shared as BackendDAE.SHARED(constraints=constrs),
      (comp as BackendDAE.EQUATIONSYSTEM(eqns=eindex,vars=vindx,jac=ojac,jacType=jacType))::comps)
      equation
        // generate Subsystem to get the incidence matrix
        size = listLength(vindx);
        eqn_lst = BackendEquation.getEqns(eindex,BackendEquation.daeEqns(isyst));  
        eqns = BackendDAEUtil.listEquation(eqn_lst);      
        var_lst = List.map1r(vindx, BackendVariable.getVarAt, BackendVariable.daeVars(isyst));
        vars = BackendDAEUtil.listVar1(var_lst);
        subsyst = BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING());
        (subsyst,m,mt,_,_) = BackendDAEUtil.getIncidenceMatrixScalar(subsyst, shared, BackendDAE.NORMAL());
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpEqSystem,subsyst);
          
        (me,meT,mapEqnIncRow,mapIncRowEqn) =  BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(subsyst,shared);
          Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpAdjacencyMatrixEnhanced,me);
          Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpAdjacencyMatrixTEnhanced,meT);
        //  IndexReduction.dumpSystemGraphMLEnhanced(subsyst,shared,me,meT);
          
       /*   m1 = incidenceMatrixfromEnhanced(me);
          Matching.matchingExternalsetIncidenceMatrix(size,size,m1);
          BackendDAEEXT.matching(size,size,5,-1,1.0,1);
          ass1 = arrayCreate(size,-1);
          ass2 = arrayCreate(size,-1);
          BackendDAEEXT.getAssignment(ass1,ass2);         
          Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpMatching,ass1);
          Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpMatching,ass2);          
        */  
        // do cheap matching until a maximum matching is there if
        // cheap matching stucks select additional tearing variable and continue
        ass1 = arrayCreate(size,-1);
        ass2 = arrayCreate(size,-1);
        
        columark = arrayCreate(size,-1);
        tvars = tearingSystemNew2(me,meT,size,vars,shared,ass1,ass2,columark,1,{});
        ass1 = List.fold(tvars,unassignTVars,ass1);
        // unmatched equations are residual equations
        residual = Matching.getUnassigned(size,ass2,{});
        //  BackendDump.dumpMatching(ass1);
          Debug.fcall(Flags.TEARING_DUMP, print,"TearingVars:\n"); 
          Debug.fcall(Flags.TEARING_DUMP, BackendDump.debuglst,(tvars,intString,", ","\nResidualEquations:\n"));
          Debug.fcall(Flags.TEARING_DUMP, BackendDump.debuglst,(residual,intString,", ","\n")); 
        //  subsyst = BackendDAEUtil.setEqSystemMatching(subsyst,BackendDAE.MATCHING(ass1,ass2,{}));
        //  IndexReduction.dumpSystemGraphML(subsyst,shared,NONE(),"System.graphml");
        // check if tearing make sense
        tornsize = listLength(tvars);
        true = intLt(tornsize,size);
        // run tarjan to get order of other equations
        m1 = arrayCreate(size,{});
        mt1 = arrayCreate(size,{});
        m1 = getOtherEqSysIncidenceMatrix(m,size,1,residual,tvars,m1);
        mt1 = getOtherEqSysIncidenceMatrix(mt,size,1,tvars,residual,mt1);
        //  subsyst = BackendDAE.EQSYSTEM(vars,eqns,SOME(m1),SOME(mt1),BackendDAE.MATCHING(ass1,ass2,{}));
        //  BackendDump.dumpEqSystem(subsyst);
        number = arrayCreate(size,0);
        lowlink = arrayCreate(size,0);        
        number = setIntArray(residual,number,size);
        (_,_,othercomps) = BackendDAETransform.strongConnectMain(m1, mt1, ass1, ass2, number, lowlink, size, 0, 1, {}, {});        
        //  print("OtherEquationsOrder:\n"); 
        //  BackendDump.dumpComponentsOLD(othercomps); print("\n");
        // handle system in case of liniear and other cases 
        (syst,shared,b) = tearingSystemNew4(jacType,isyst,ishared,subsyst,tvars,residual,ass1,ass2,othercomps,eindex,vindx,mapEqnIncRow,mapIncRowEqn);
        Debug.fcall(Flags.TEARING_DUMP, print,Util.if_(b,"Ok system torn\n","System not torn\n"));
        (syst,shared,b1) = tearingSystemNew1(syst,shared,comps);
      then
        (syst,shared,b or b1);
    case (_,_,(comp as BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp1))::comps)
      equation
        (syst,shared,b) = tearingSystemNew1(isyst,ishared,{comp1});
        (syst,shared,b1) = tearingSystemNew1(syst,shared,comps);
      then
        (syst,shared,b1 or b);
    case (_,_,comp::comps)
      equation
        (syst,shared,b) = tearingSystemNew1(isyst,ishared,comps);
      then
        (syst,shared,b);
  end matchcontinue;  
end tearingSystemNew1;

protected function setIntArray
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

protected function incidenceMatrixfromEnhanced
  input BackendDAE.AdjacencyMatrixEnhanced me;
  output BackendDAE.IncidenceMatrix m;
algorithm
  m := Util.arrayMap(me,incidenceMatrixElementfromEnhanced);
end incidenceMatrixfromEnhanced;

protected function incidenceMatrixElementfromEnhanced
  input BackendDAE.AdjacencyMatrixElementEnhanced iRow;
  output BackendDAE.IncidenceMatrixElement oRow;
algorithm
  oRow := List.map(List.sort(iRow,AdjacencyMatrixElementEnhancedCMP), incidenceMatrixElementElementfromEnhanced);
end incidenceMatrixElementfromEnhanced;

protected function AdjacencyMatrixElementEnhancedCMP
  input tuple<Integer, BackendDAE.Solvability> inTplA;
  input tuple<Integer, BackendDAE.Solvability> inTplB;
  output Boolean b;
algorithm
  b := BackendDAEUtil.solvabilityCMP(Util.tuple22(inTplA),Util.tuple22(inTplB));
end AdjacencyMatrixElementEnhancedCMP;

protected function incidenceMatrixElementElementfromEnhanced
  input tuple<Integer, BackendDAE.Solvability> inTpl;
  output Integer oI;
algorithm
  oI := match(inTpl)
    local 
      Integer i;
      Boolean b;
    case ((i,BackendDAE.SOLVABILITY_SOLVED())) then i;
    case ((i,BackendDAE.SOLVABILITY_CONSTONE())) then i;
    case ((i,BackendDAE.SOLVABILITY_CONST())) then i;
    case ((i,BackendDAE.SOLVABILITY_PARAMETER(b=_)))
      equation
        i = Util.if_(intLt(i,0),i,-i);
      then i;
    case ((i,BackendDAE.SOLVABILITY_TIMEVARYING(b=_)))
      equation
        i = Util.if_(intLt(i,0),i,-i);
      then i;
    case ((i,BackendDAE.SOLVABILITY_NONLINEAR()))
      equation
        i = Util.if_(intLt(i,0),i,-i);
       then i;
    case ((i,BackendDAE.SOLVABILITY_UNSOLVABLE()))
      equation
        i = Util.if_(intLt(i,0),i,-i);
      then i;
  end match;
end incidenceMatrixElementElementfromEnhanced;

protected function getOtherEqSysIncidenceMatrix "function getOtherEqSysIncidenceMatrix
  author: Frenkel TUD 2012-05"
  input BackendDAE.IncidenceMatrix m;
  input Integer size;
  input Integer index;
  input list<Integer> skip;
  input list<Integer> rowskip;
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
        false = listMember(index,skip);
        row = List.select(m[index], Util.intPositive);
        row = List.setDifferenceIntN(row, rowskip, size);
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

protected function unassignTVars "function unassignTVars
  author: Frenkel TUD 2012-05"
  input Integer v;
  input array<Integer> inAss;
  output array<Integer> outAss;
algorithm
  outAss := arrayUpdate(inAss,v,-1);
end unassignTVars;

protected function isAssigned "function isAssigned
  author: Frenkel TUD 2012-05"
  input array<Integer> ass;
  input Integer i;
  output Boolean b;
algorithm
  b := intGt(ass[i],0);
end isAssigned;

protected function isUnAssigned "function isUnAssigned
  author: Frenkel TUD 2012-05"
  input array<Integer> ass;
  input Integer i;
  output Boolean b;
algorithm
  b := intLt(ass[i],1);
end isUnAssigned;

protected function isMarked "function isMarked
  author: Frenkel TUD 2012-05"
  input tuple<array<Integer>,Integer> inTpl;
  input Integer v;
  output Boolean b;
protected
  array<Integer> markarray;
  Integer mark;
algorithm
  (markarray,mark) := inTpl;
  b := intEq(markarray[v],mark);
end isMarked;

protected function selectVarsWithMostEqns "function selectVarWithMostEqns
  author: Frenkel TUD 2012-05"
  input list<Integer> vars;
  input array<Integer> ass2;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input list<Integer> iVars;
  input Integer eqns;
  output list<Integer> oVars;
algorithm
  oVars := matchcontinue(vars,ass2,mt,iVars,eqns)
    local
      list<Integer> rest,vlst;
      Integer e,v;
    case ({},_,_,_,_) then iVars;
    case (v::rest,_,_,_,_)
      equation
        e = calcSolvabilityWight(mt[v],ass2);
        //  print("Var " +& intString(v) +& "has w= " +& intString(e) +& "\n");
        true = intGe(e,eqns);
        vlst = List.consOnTrue(intEq(e,eqns),v,iVars);
        ((vlst,e)) = Util.if_(intGt(e,eqns),({v},e),(vlst,eqns));
        //  print("max is  " +& intString(eqns) +& "\n");
        //  BackendDump.debuglst((vlst,intString,", ","\n"));
      then
        selectVarsWithMostEqns(rest,ass2,mt,vlst,e);
    case (_::rest,_,_,_,_)
      then
        selectVarsWithMostEqns(rest,ass2,mt,iVars,eqns);
  end matchcontinue;
end selectVarsWithMostEqns;

protected function selectVarWithMostPoints "function selectVarWithMostPoints
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
        //  print("Var " +& intString(v));
        p = points[v];
        //  print(" has " +& intString(p) +& " Points\n");
        true = intGt(p,defp);
        //  print("max is  " +& intString(defp) +& "\n");
      then
        selectVarWithMostPoints(rest,points,v,p);
    case (_::rest,_,_,_)
      then
        selectVarWithMostPoints(rest,points,iVar,defp);
  end matchcontinue;
end selectVarWithMostPoints;

protected function addEqnWights
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
         ((v1,_)::(v2,_)::{}) = List.removeOnTrue(ass1, isAssignedSaveEnhanced, m[e]); 
          points = arrayUpdate(iPoints,v1,iPoints[v1]+5);
          points = arrayUpdate(iPoints,v2,points[v2]+5);
       then
         points;
     else
       iPoints;
 end matchcontinue;
end addEqnWights;

protected function addOneEdgeEqnWights
 input Integer v;
 input tuple<BackendDAE.AdjacencyMatrixEnhanced,BackendDAE.AdjacencyMatrixTEnhanced> mmt;
 input array<Integer> ass1;
 input array<Integer> iPoints;
 output array<Integer> oPoints;
algorithm
 oPoints := matchcontinue(v,mmt,ass1,iPoints)
   local
       BackendDAE.AdjacencyMatrixEnhanced m;
       BackendDAE.AdjacencyMatrixTEnhanced mt;
       list<Integer> elst;
       Integer e;
       array<Integer> points;
     case (_,(m,mt),_,_)
       equation
         elst = List.fold2(mt[v],eqnsWithOneUnassignedVar,m,ass1,{});
          e = listLength(elst);
          points = arrayUpdate(iPoints,v,iPoints[v]+e);
       then
         points;
     else
       iPoints;
 end matchcontinue;
end addOneEdgeEqnWights;

protected function calcVarWights
 input Integer v;
 input BackendDAE.AdjacencyMatrixTEnhanced mt;
 input array<Integer> ass2;
 input array<Integer> iPoints;
 output array<Integer> oPoints;
protected
 Integer p;
algorithm
  p := calcSolvabilityWight(mt[v],ass2);
  oPoints := arrayUpdate(iPoints,v,p);
end calcVarWights;

protected function calcSolvabilityWight
  input BackendDAE.AdjacencyMatrixElementEnhanced inRow;
  input array<Integer> ass2;
  output Integer w;
algorithm
  w := List.fold1(inRow,solvabilityWightsnoStates,ass2,0);
end calcSolvabilityWight;

public function solvabilityWightsnoStates "function: solvabilityWights
  author: Frenkel TUD 2012-05"
  input tuple<Integer,BackendDAE.Solvability> inTpl;
  input array<Integer> ass;
  input Integer iW;
  output Integer oW;
algorithm
  oW := matchcontinue(inTpl,ass,iW)
    local
      BackendDAE.Solvability s;
      Integer v,w;
    case((v,s),_,_)
      equation
        true = intGt(v,0);
        false = intGt(ass[v], 0);
        w = solvabilityWights(s);
      then
        intAdd(w,iW);
    else then iW;
  end matchcontinue;
end solvabilityWightsnoStates;

public function solvabilityWights "function: solvabilityWights
  author: Frenkel TUD 2012-05,
  return a integer for the solvability, this function is used
  to calculade wights for variables to select the tearing variable."
  input BackendDAE.Solvability solva;
  output Integer i;
algorithm
  i := match(solva)
    case BackendDAE.SOLVABILITY_SOLVED() then 1;
    case BackendDAE.SOLVABILITY_CONSTONE() then 2;
    case BackendDAE.SOLVABILITY_CONST() then 5;
    case BackendDAE.SOLVABILITY_PARAMETER(b=false) then 0;
    case BackendDAE.SOLVABILITY_PARAMETER(b=true) then 50;
    case BackendDAE.SOLVABILITY_TIMEVARYING(b=false) then 0;
    case BackendDAE.SOLVABILITY_TIMEVARYING(b=true) then 100;
    case BackendDAE.SOLVABILITY_NONLINEAR() then 500;
    case BackendDAE.SOLVABILITY_UNSOLVABLE() then 1000;
  end match;
end solvabilityWights;

protected function selectTearingVar "function selectTearingVar
  author: Frenkel TUD 2012-05"
  input BackendDAE.Variables vars;
  input array<Integer> ass1; 
  input array<Integer> ass2;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  output Integer tearingVar;
algorithm
  tearingVar := matchcontinue(vars,ass1,ass2,m,mt)
    local
      list<Integer> states,eqns;
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
        true = intGt(listLength(states),0);
        tvar = selectVarWithMostEqns(states,ass2,mt,-1,-1);
      then
        tvar;
*/
    case(_,_,_,_,_)
      equation
        varsize = BackendVariable.varsSize(vars);
        states = Matching.getUnassigned(varsize,ass1,{});
        Debug.fcall(Flags.TEARING_DUMP,  print,"selectTearingVar Candidates:\n"); 
        Debug.fcall(Flags.TEARING_DUMP,  BackendDump.debuglst,(states,intString,", ","\n"));  
        size = listLength(states);
        true = intGt(size,0);
        points = arrayCreate(varsize,0);
        points = List.fold2(states, calcVarWights,mt,ass2,points);
        eqns = Matching.getUnassigned(arrayLength(m),ass2,{});
        points = List.fold2(eqns,addEqnWights,m,ass1,points);
        //points = List.fold2(states,addOneEdgeEqnWights,(m,mt),ass1,points);
         Debug.fcall(Flags.TEARING_DUMP,  BackendDump.dumpMatching,points);
        tvar = selectVarWithMostPoints(states,points,-1,-1);
        
        //states = selectVarsWithMostEqns(states,ass2,mt,{},-1);
        //  print("VarsWithMostEqns:\n"); 
        //  BackendDump.debuglst((states,intString,", ","\n"));        
        //tvar = selectVarWithMostEqnsOneEdge(states,ass1,m,mt,-1,-1);
      then
        tvar;        
      else
    equation
        print("selectTearingVar failed because no unmatched var!\n");
      then
        fail();
  end matchcontinue;  
end selectTearingVar;

protected function selectVarWithMostEqnsOneEdge
  input list<Integer> vars;
  input array<Integer> ass1;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input Integer defaultVar;
  input Integer eqns;
  output Integer var;
algorithm
  var := matchcontinue(vars,ass1,m,mt,defaultVar,eqns)
    local
      list<Integer> rest,elst;
      Integer e,v;
    case ({},_,_,_,_,_) then defaultVar;
    case (v::rest,_,_,_,_,_)
      equation
        elst = List.fold2(mt[v],eqnsWithOneUnassignedVar,m,ass1,{});
        e = listLength(elst);
        //  print("Var " +& intString(v) +& " has " +& intString(e) +& " one eqns\n");
        true = intGt(e,eqns);
      then
        selectVarWithMostEqnsOneEdge(rest,ass1,m,mt,v,e);
    case (_::rest,_,_,_,_,_)
      then
        selectVarWithMostEqnsOneEdge(rest,ass1,m,mt,defaultVar,eqns);
  end matchcontinue;
end selectVarWithMostEqnsOneEdge;

protected function eqnsWithOneUnassignedVar "function: eqnsWithOneUnassignedVar
  author: Frenkel TUD 2012-05"
  input tuple<Integer,BackendDAE.Solvability> inTpl;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input array<Integer> ass;
  input list<Integer> iLst;
  output list<Integer> oLst;
algorithm
  oLst := matchcontinue(inTpl,m,ass,iLst)
    local
      BackendDAE.Solvability s;
      Integer e;
      BackendDAE.AdjacencyMatrixElementEnhanced vars;
    case((e,s),_,_,_)
      equation
        true = intGt(e,0);
        vars = List.removeOnTrue(ass, isAssignedSaveEnhanced, m[e]);
        //  print("Eqn " +& intString(e) +& " has " +& intString(listLength(vars)) +& " vars\n");
        true = intEq(listLength(vars), 2);
      then
        e::iLst;
    else then iLst;            
  end matchcontinue; 
end eqnsWithOneUnassignedVar;

protected function markEqns "function markEqns
  author: Frenkel TUD 2012-05"
  input list<Integer> eqns;
  input array<Integer> columark;
  input Integer mark;
algorithm
  _ := match(eqns,columark,mark)
    local
      Integer e;
      list<Integer> rest;
    case({},_,_) then ();
    case(e::rest,_,_)
      equation
        _ = arrayUpdate(columark,e,mark);
        markEqns(rest,columark,mark);
      then
        ();
  end match; 
end markEqns;

protected function tearingSystemNew2 "function tearingSystemNew2
  author: Frenkel TUD 2012-05"
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input Integer size;
  input BackendDAE.Variables vars;
  input BackendDAE.Shared ishared;
  input array<Integer> ass1; 
  input array<Integer> ass2;
  input array<Integer> columark;
  input Integer mark;
  input list<Integer> inTVars;
  output list<Integer> outTVars;
algorithm
  outTVars := matchcontinue(m,mt,size,vars,ishared,ass1,ass2,columark,mark,inTVars)
    local 
      Integer tvar;
      list<Integer> unassigned;
      BackendDAE.AdjacencyMatrixElementEnhanced vareqns;
      BackendDAE.EqSystem subsyst;
      list<BackendDAE.Var> vlst;
      list<BackendDAE.Equation> elst;
      BackendDAE.Variables vars1;
      BackendDAE.EquationArray eqns1;      
    case (_,_,_,_,_,_,_,_,_,_)
      equation
        // select tearing var
        tvar = selectTearingVar(vars,ass1,ass2,m,mt);
        //  print("Selected Var " +& intString(tvar) +& " as TearingVar\n");
        // mark tearing var
        _ = arrayUpdate(ass1,tvar,size*2);
        vareqns = List.removeOnTrue(ass2, isAssignedSaveEnhanced, mt[tvar]); 
        //vareqns = List.removeOnTrue((columark,mark), isMarked, vareqns); 
        //markEqns(vareqns,columark,mark);
        // cheap matching
        tearingBFS(vareqns,m,mt,size,ass1,ass2,columark,mark,{});

        /*  vlst = getUnnassignedFromArray(1,arrayLength(mt),ass1,vars,BackendVariable.getVarAt,0,{});
          elst = getUnnassignedFromArray(1,arrayLength(m),ass2,eqns,BackendDAEUtil.equationNth,-1,{});
          vars1 = BackendDAEUtil.listVar1(vlst);
          eqns1 = BackendDAEUtil.listEquation(elst);
          subsyst = BackendDAE.EQSYSTEM(vars1,eqns1,NONE(),NONE(),BackendDAE.NO_MATCHING());
          IndexReduction.dumpSystemGraphML(subsyst,ishared,NONE(),"System.graphml");
        */

        // check for unassigned vars, if there some rerun 
        unassigned = Matching.getUnassigned(size,ass1,{});
      then
        tearingSystemNew3(unassigned,m,mt,size,vars,ishared,ass1,ass2,columark,mark+1,tvar::inTVars);
    else
      equation
        print("BackendDAEOptimize.tearingSystemNew2 failed!");
      then
        fail();  
  end matchcontinue; 
end tearingSystemNew2;

protected function getUnnassignedFromArray
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  input Integer indx;
  input Integer size;
  input array<Integer> ass;
  input Type_b inTypeAArray;
  input FuncTypeType_aFromArray func;
  input Integer off;
  input list<Type_a> iALst;
  output list<Type_a> oALst;
  partial function FuncTypeType_aFromArray
    input Type_b inTypeB;
    input Integer indx;
    output Type_a outTypeA;
  end FuncTypeType_aFromArray;
algorithm
  oALst := matchcontinue(indx,size,ass,inTypeAArray,func,off,iALst)
    local
      Type_a a;
    case (_,_,_,_,_,_,_)
      equation
        true = intLe(indx,size);
        true = intLt(ass[indx],1);
        a = func(inTypeAArray,indx+off);
      then
        getUnnassignedFromArray(indx+1,size,ass,inTypeAArray,func,off,a::iALst);
    case (_,_,_,_,_,_,_)
      equation
        true = intLe(indx,size);
      then
        getUnnassignedFromArray(indx+1,size,ass,inTypeAArray,func,off,iALst);
    else
      listReverse(iALst); 
  end matchcontinue;
end getUnnassignedFromArray;

protected function tearingSystemNew3 "function tearingSystemNew3
  author: Frenkel TUD 2012-05"
  input list<Integer> unassigend;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input Integer size;
  input BackendDAE.Variables vars;
  input BackendDAE.Shared ishared;
  input array<Integer> ass1; 
  input array<Integer> ass2;
  input array<Integer> columark;
  input Integer mark;
  input list<Integer> inTVars;
  output list<Integer> outTVars;
algorithm
  outTVars := match(unassigend,m,mt,size,vars,ishared,ass1,ass2,columark,mark,inTVars)
    local 
      Integer tvar;
      list<Integer> vareqns,unassigned;
    case ({},_,_,_,_,_,_,_,_,_,_) then inTVars;
    else then tearingSystemNew2(m,mt,size,vars,ishared,ass1,ass2,columark,mark,inTVars);
  end match; 
end tearingSystemNew3;

protected function tearingBFS "function tearingBFS
  author: Frenkel TUD 2012-05"
  input BackendDAE.AdjacencyMatrixElementEnhanced queue;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input Integer size;
  input array<Integer> ass1; 
  input array<Integer> ass2;
  input array<Integer> columark;
  input Integer mark;
  input BackendDAE.AdjacencyMatrixElementEnhanced nextQeue;
algorithm
  _ := match(queue,m,mt,size,ass1,ass2,columark,mark,nextQeue)
    local 
      Integer c;
      BackendDAE.AdjacencyMatrixElementEnhanced rest,newqueue,rows;
    case ({},_,_,_,_,_,_,_,{}) then ();
    case ({},_,_,_,_,_,_,_,_)
      equation
        //  print("NextQeue\n");
        tearingBFS(nextQeue,m,mt,size,ass1,ass2,columark,mark,{});
      then 
        ();
    case((c,_)::rest,_,_,_,_,_,_,_,_)
      equation
        //  print("Process Eqn " +& intString(c) +& "\n");
        rows = List.removeOnTrue(ass1, isAssignedSaveEnhanced, m[c]); 
        //_ = arrayUpdate(columark,c,mark);
        newqueue = tearingBFS1(rows,c,mt,ass1,ass2,columark,mark,nextQeue);
        tearingBFS(rest,m,mt,size,ass1,ass2,columark,mark,newqueue);
      then 
        ();
  end match; 
end tearingBFS;

protected function isAssignedSaveEnhanced
"function isAssigned
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

protected function solvable
  input BackendDAE.Solvability s;
  output Boolean b;
algorithm
  b := match(s)
    local Boolean b;
    case BackendDAE.SOLVABILITY_SOLVED() then true;
    case BackendDAE.SOLVABILITY_CONSTONE() then true;
    case BackendDAE.SOLVABILITY_CONST() then true;
    case BackendDAE.SOLVABILITY_PARAMETER(b=b) then b;
    case BackendDAE.SOLVABILITY_TIMEVARYING(b=b) then false;
    case BackendDAE.SOLVABILITY_NONLINEAR() then false;
    case BackendDAE.SOLVABILITY_UNSOLVABLE() then false;
  end match; 
end solvable;

protected function tearingBFS1 "function tearingBFS1
  author: Frenkel TUD 2012-05"
  input BackendDAE.AdjacencyMatrixElementEnhanced rows;
  input Integer c;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input array<Integer> ass1; 
  input array<Integer> ass2;
  input array<Integer> columark;
  input Integer mark;
  input BackendDAE.AdjacencyMatrixElementEnhanced inNextQeue;
  output BackendDAE.AdjacencyMatrixElementEnhanced outNextQeue;
algorithm
  outNextQeue := matchcontinue(rows,c,mt,ass1,ass2,columark,mark,inNextQeue)
    local 
      Integer r;
      BackendDAE.Solvability s;
      BackendDAE.AdjacencyMatrixElementEnhanced vareqns,newqueue;
    case ((r,s)::{},_,_,_,_,_,_,_)
      equation
        true = solvable(s);
        //  print("Assign Var" +& intString(r) +& " with Eqn " +& intString(c) +& "\n");
        // assigen 
        _ = arrayUpdate(ass1,r,c);
        _ = arrayUpdate(ass2,c,r);
        vareqns = List.removeOnTrue(ass2, isAssignedSaveEnhanced, mt[r]);  
        //vareqns = List.removeOnTrue((columark,mark), isMarked, vareqns);   
        //markEqns(vareqns,columark,mark);     
      then 
        listAppend(inNextQeue,vareqns);
    case ((r,s)::{},_,_,_,_,_,_,_)
      equation
        false = solvable(s);
        //  print("cannot Assign Var" +& intString(r) +& " with Eqn " +& intString(c) +& "\n");
      then 
        inNextQeue;
    else then inNextQeue;
  end matchcontinue; 
end tearingBFS1;

protected function tearingSystemNew4 "function tearingSystemNew4
  author: Frenkel TUD 2012-05"
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
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Boolean outRunMatching;
algorithm
  (osyst,oshared,outRunMatching):=
    matchcontinue (jacType,isyst,ishared,subsyst,tvars,residual,ass1,ass2,othercomps,eindex,vindx,mapEqnIncRow,mapIncRowEqn)
    local
      list<Integer> tvars,residual,ores,residual1,othercomps1,eindex1;
      list<list<Integer>> othercomps;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      Integer size,tornsize,numvars;
      list<BackendDAE.Equation> h0,g0,h,g,eqnslst;
      list<list<BackendDAE.Equation>> derivedEquations,hlst,glst; 
      array<list<BackendDAE.Equation>> derivedEquationsArr;
      list<BackendDAE.Var> k0,pdvarlst;    
      BackendDAE.Variables vars,kvars,sysvars,sysvars1,kvars1,varst1;
      BackendDAE.EquationArray eqns,syseqns;
      BackendVarTransform.VariableReplacements repl;
      list<DAE.ComponentRef> tvarcrefs,varcrefs;
      DAE.FunctionTree functionTree;
      list<DAE.ComponentRef> pdcr_lst;
      list<DAE.Exp> tvarexps;
      list<BackendDAE.Var> vlst,states;
      BackendDAE.BinTree bt;
      array<Boolean> eqnmark;

    case (BackendDAE.JAC_TIME_VARYING(),_,BackendDAE.SHARED(knownVars=kvars,functionTree=functionTree),_,_,_,_,_,_,_,_,_,_)
    //case (_,_,BackendDAE.SHARED(knownVars=kvars,functionTree=functionTree),_,_,_,_,_,_,_,_)
      equation
        Debug.fcall(Flags.TEARING_DUMP, print,"handle linear torn System\n");
        size = listLength(vindx);
        eqns = BackendEquation.daeEqns(subsyst);
        vars = BackendVariable.daeVars(subsyst);
        // add temp variables for other vars at point zero (k0)
        // replace tearing vars with zero and other wars with temp variables to get equations for point zero (g(z0,k0)=g0)
        repl = List.fold1(tvars,getZeroTVarReplacements,vars,BackendVarTransform.emptyReplacementsSized(size));
        (k0,repl) = getZeroVarReplacements(othercomps,vars,ass2,repl,{});
        eqnmark = arrayCreate(arrayLength(ass2),false);
        (g0,othercomps1) = getOtherEquationsPointZero(othercomps,vars,eqns,repl,eqnmark,mapIncRowEqn,{},{});
        Debug.fcall(Flags.TEARING_DUMP, print,"k0:\n");
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpVars,k0);
        Debug.fcall(Flags.TEARING_DUMP, print,"g0:\n");
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpEqns,g0);
        // replace tearing vars with zero and other wars with temp variables to get residual equations for point zero (h(z0,k0)=h0)
        residual1 = List.map1r(residual,arrayGet,mapIncRowEqn);
        residual1 = List.unique(residual1);       
        h0 = List.map3(residual1,getEquationsPointZero,eqns,repl,vars);
        Debug.fcall(Flags.TEARING_DUMP, print,"h0:\n");
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpEqns,h0);
        // calculate dh/dz = derivedEquations 
        tvarcrefs = List.map1(tvars,getTVarCrefs,vars);
        // Prepare all needed variables
        sysvars = BackendVariable.daeVars(isyst);
        sysvars1 = BackendVariable.copyVariables(sysvars);
        kvars1 = BackendVariable.copyVariables(kvars);
        states = BackendVariable.getAllStateVarFromVariables(vars);
        varcrefs = BackendVariable.getAllCrefFromVariables(vars);
        bt = BackendDAEUtil.treeAddList(BackendDAE.emptyBintree,varcrefs);
        sysvars1 = BackendVariable.deleteVars(bt,sysvars1);
        kvars1 = BackendVariable.mergeVariables(sysvars1, kvars1);
        eqnslst = BackendDAEUtil.equationList(eqns);
        (eqnslst,_) = BackendEquation.traverseBackendDAEExpsEqnList(eqnslst, replaceDerCalls, vars);
        derivedEquations = deriveAll(eqnslst,tvarcrefs,functionTree,BackendDAEUtil.listVar({}),kvars1,BackendDAEUtil.listVar(states),BackendDAEUtil.listVar({}),vars,tvarcrefs,("$WRT",true),{});
        derivedEquationsArr = listArray(derivedEquations);
        glst = List.map1r(othercomps1,arrayGet,derivedEquationsArr);
        hlst = List.map1r(residual1,arrayGet,derivedEquationsArr);
        g = List.flatten(glst);
        g = BackendVarTransform.replaceEquations(g, repl);
        //pdcr_lst = BackendEquation.equationUnknownCrefs(g,BackendDAEUtil.listVar(listAppend(BackendDAEUtil.varList(sysvars),knvarlst)));
        pdcr_lst = BackendEquation.equationUnknownCrefs(g,BackendVariable.daeVars(isyst),kvars);
        pdvarlst = List.map(pdcr_lst,makePardialDerVar);
        Debug.fcall(Flags.TEARING_DUMP, print,"PartialDerivatives:\n");
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpVars,pdvarlst);
        Debug.fcall(Flags.TEARING_DUMP, print,"dh/dz extra:\n");
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpEqns,g);
        tvarexps = List.map2(tvars,getTVarCrefExps,vars,ishared);
        Debug.fcall(Flags.TEARING_DUMP, print,"TVars: ");
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.debuglst,(tvarexps,ExpressionDump.printExpStr,", ","\n")); 
        //  print("dh/dz:\n");
        //  BackendDump.dumpEqns(List.flatten(hlst));
        h = generateHEquations(hlst,tvarexps,h0,{});
        Debug.fcall(Flags.TEARING_DUMP, print,"dh/dz*z=-h:\n");
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.dumpEqns,h);
        // check if all tearing vars part of the system
        vlst = List.map1r(tvars,BackendVariable.getVarAt,vars);
        varst1 = BackendEquation.equationsLstVars(h, BackendDAEUtil.listVar1(vlst), BackendDAEUtil.emptyVars());
        numvars = BackendVariable.numVariables(varst1);
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.debugStrIntStr,("Found ",numvars," Tearing Vars in the Residual Equations\n"));
        true = intEq(listLength(tvars),numvars);
        // replace new residual equations in original system
        syseqns = BackendEquation.daeEqns(isyst);
        // all additional vars and equations
        sysvars = BackendVariable.addVars(k0,sysvars);
        sysvars = BackendVariable.addVars(pdvarlst,sysvars);
        syseqns = BackendEquation.addEquations(g0, syseqns);
        syseqns = BackendEquation.addEquations(g, syseqns);
        // replace new residual equations in original system
        ores = List.map1r(residual1,arrayGet,listArray(eindex));
        syseqns = replaceHEquationsinSystem(ores,h,syseqns);
        syst = BackendDAE.EQSYSTEM(sysvars,syseqns,NONE(),NONE(),BackendDAE.NO_MATCHING());
        //  BackendDump.dumpEqSystem(syst);
      then
        (syst,ishared,true);
  
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        Debug.fcall(Flags.TEARING_DUMP, print,"handle torn System\n");
        // solve other equations for other vars
        size = listLength(eindex);
        eqns = BackendEquation.daeEqns(subsyst);
        vars = BackendVariable.daeVars(subsyst);
        tvarexps = List.map2(tvars,getTVarCrefExps,vars,ishared);
        Debug.fcall(Flags.TEARING_DUMP, print,"TVars: ");
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.debuglst,(tvarexps,ExpressionDump.printExpStr,", ","\nOther Equations:\n"));        
        (eqns,repl,k0) = solveOtherEquations(othercomps,eqns,vars,ass2,ishared,BackendVarTransform.emptyReplacementsSized(size),{});
        // replace other vars in residual equations with there expression, use reverse order from othercomps
        Debug.fcall(Flags.TEARING_DUMP, print,"Residual Equations:\n");
        residual1 = List.map1r(residual,arrayGet,mapIncRowEqn);
        residual1 = List.unique(residual1);         
        eqns = List.fold2(residual1,replaceOtherVarinResidualEqns,repl,BackendDAEUtil.listVar1(k0),eqns);
        // check if all tearing vars part of the system
        vlst = List.map1r(tvars,BackendVariable.getVarAt,vars);
        eqnslst = BackendEquation.getEqns(residual1,eqns);
        varst1 = BackendEquation.equationsLstVars(eqnslst, BackendDAEUtil.listVar1(vlst), BackendDAEUtil.emptyVars());
        numvars = BackendVariable.numVariables(varst1);
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.debugStrIntStr,("Found ",numvars," Tearing Vars in the Residual Equations\n"));
        true = intEq(listLength(tvars),numvars);       
        // replace new residual equations in original system
        syst = replaceTornEquationsinSystem(residual1,listArray(eindex),eqns,isyst);
      then
        (syst,ishared,true);           
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        (isyst,ishared,false);        
  end matchcontinue;  
end tearingSystemNew4;

protected function replaceHEquationsinSystem
  input list<Integer> eindx;
  input list<BackendDAE.Equation> HEqns;
  input BackendDAE.EquationArray iEqns;
  output BackendDAE.EquationArray oEqns;
algorithm
  oEqns := match(eindx,HEqns,iEqns)
    local
      Integer e;
      list<Integer> rest;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqnlst;
      BackendDAE.EquationArray eqns;
    case ({},_,_) then iEqns;
    case (e::rest,eqn::eqnlst,_)
      equation
        eqns = BackendEquation.equationSetnth(iEqns, e-1, eqn);
      then
        replaceHEquationsinSystem(rest,eqnlst,eqns);
  end match;
end replaceHEquationsinSystem;

protected function equationToExp
  input BackendDAE.Equation Eqn;
  output DAE.Exp outExp;
algorithm
  outExp := match(Eqn)
    local
      DAE.Exp e1,e2;
      DAE.ComponentRef cr;
    case BackendDAE.EQUATION(exp = e1,scalar = e2) then Expression.expSub(e1,e2);    
    case BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2) then Expression.expSub(Expression.crefExp(cr),e2);    
    case BackendDAE.RESIDUAL_EQUATION(exp = e1) then e1;   
    else
      equation
       BackendDump.debugStrEqnStr(("Cannot Handle Eqn",Eqn,"\n"));
      then
        fail(); 
  end match;
end equationToExp;

protected function generateHEquations
  input list<list<BackendDAE.Equation>> HEqns;
  input list<DAE.Exp> tvarcrefs;
  input list<BackendDAE.Equation> HZeroEqns;
  input list<BackendDAE.Equation> iEqns;
  output list<BackendDAE.Equation> oEqns;
algorithm
  oEqns := match(HEqns,tvarcrefs,HZeroEqns,iEqns)
    local
     list<list<BackendDAE.Equation>> heqns;
     list<BackendDAE.Equation> eqns,hzeroeqns;
     BackendDAE.Equation eqn;
     list<DAE.Exp> explst;
     DAE.Exp e1,e2;
     DAE.ElementSource source;
    case ({},_,_,_) then listReverse(iEqns);
    case (eqns::heqns,_,eqn::hzeroeqns,_)
      equation
        explst = List.map(eqns,equationToExp);
        explst = List.threadMap(explst,tvarcrefs,Expression.expMul);
        e1 = Expression.makeSum(explst);
        e2 = equationToExp(eqn);
        e2 = Expression.negate(e2);
        source = BackendEquation.equationSource(eqn);
      then
        generateHEquations(heqns,tvarcrefs,hzeroeqns,BackendDAE.EQUATION(e1,e2,source)::iEqns);
  end match;
end generateHEquations;

protected function getOtherDerivedEquations
  input list<list<Integer>> othercomps; 
  input array<list<BackendDAE.Equation>> derivedEquations;
  input list<list<BackendDAE.Equation>> iOtherEqns;
  output list<list<BackendDAE.Equation>> oOtherEqns;
algorithm
  oOtherEqns :=
  matchcontinue (othercomps,derivedEquations,iOtherEqns)
    local
      Integer c;
      list<list<Integer>> rest;
      list<BackendDAE.Equation> g;
    case ({},_,_) then listReverse(iOtherEqns);
    case ({c}::rest,_,_)
      equation
        g = derivedEquations[c];
      then
        getOtherDerivedEquations(rest,derivedEquations,g::iOtherEqns); 
  end matchcontinue;  
end getOtherDerivedEquations;

protected function makePardialDerVar
  input DAE.ComponentRef cr;
  output BackendDAE.Var v;
algorithm
  v := BackendDAE.VAR(cr,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),DAE.T_REAL_DEFAULT,NONE(),NONE(),{},-1,DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM_CONNECTOR());
end makePardialDerVar;

protected function getTVarCrefs "function getTVarCrefs
  author: Frenkel TUD 2011-05
  return cref of var v from vararray"
  input Integer v;
  input BackendDAE.Variables inVars;
  output DAE.ComponentRef cr;
protected
  BackendDAE.Var var;
algorithm
  var := BackendVariable.getVarAt(inVars, v);
  cr := BackendVariable.varCref(var);
  cr := Debug.bcallret1(BackendVariable.isStateVar(var), ComponentReference.crefPrefixDer, cr, cr);
end getTVarCrefs;

protected function getTVarCrefExps "function getTVarCrefExps
  author: Frenkel TUD 2011-05
  return cref exp of var v from vararray"
  input Integer v;
  input BackendDAE.Variables inVars;
  input BackendDAE.Shared ishared;
  output DAE.Exp exp;
protected
  BackendDAE.Var var;
  DAE.ComponentRef cr;
algorithm
  var := BackendVariable.getVarAt(inVars, v);
  cr := BackendVariable.varCref(var);
  exp := Expression.crefExp(cr);
  exp := Debug.bcallret2(BackendVariable.isStateVar(var), Derive.differentiateExpTime, exp, (inVars,ishared), exp);
end getTVarCrefExps;

protected function getZeroTVarReplacements "function getZeroTVarReplacements
  author: Frenkel TUD 2011-05
  try to solve the equations"
  input Integer v;
  input BackendDAE.Variables inVars;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendVarTransform.VariableReplacements outRepl;
protected
  DAE.ComponentRef cr;
  BackendDAE.Var var;
algorithm
  var := BackendVariable.getVarAt(inVars, v);
  cr := BackendVariable.varCref(var);
  cr := Debug.bcallret1(BackendVariable.isStateVar(var), ComponentReference.crefPrefixDer, cr, cr);
  outRepl := BackendVarTransform.addReplacement(inRepl,cr,DAE.RCONST(0.0));
end getZeroTVarReplacements;

protected function getEquationsPointZero "function getEquationsPointZero
  author: Frenkel TUD 2011-05
  try to solve the equations"
  input Integer index;
  input BackendDAE.EquationArray inEqns;
  input BackendVarTransform.VariableReplacements inRepl;
  input BackendDAE.Variables inVars;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := BackendDAEUtil.equationNth(inEqns, index-1);
  (outEqn,_) := BackendEquation.traverseBackendDAEExpsEqn(outEqn,replaceDerCalls,inVars);
  outEqn::_ := BackendVarTransform.replaceEquations({outEqn}, inRepl);
end getEquationsPointZero;

protected function getZeroVarReplacements "function getZeroVarReplacements
  author: Frenkel TUD 2012-07
  add for the other variables the zero var replacement cr->$ZERO.cr."
  input list<list<Integer>> othercomps;
  input BackendDAE.Variables inVars;
  input array<Integer> ass2;
  input BackendVarTransform.VariableReplacements inRepl;
  input list<BackendDAE.Var> inVarLst;
  output list<BackendDAE.Var> outVarLst;
  output BackendVarTransform.VariableReplacements outRepl;
algorithm
  (outVarLst,outRepl) :=
  match (othercomps,inVars,ass2,inRepl,inVarLst)
    local
      list<list<Integer>> rest;
      BackendDAE.EquationArray eqns;
      Integer v,c;
      DAE.Exp varexp;
      BackendDAE.Equation eqn;
      DAE.ComponentRef cr,cr1;
      BackendVarTransform.VariableReplacements repl;
      list<BackendDAE.Equation> eqsLst;
      list<BackendDAE.Var> varLst;
      BackendDAE.Var var;      
    case ({},_,_,_,_) then (inVarLst,inRepl);
    case ({c}::rest,_,_,_,_)
      equation
        v = ass2[c];
        var = BackendVariable.getVarAt(inVars, v);
        cr = BackendVariable.varCref(var);
        cr = Debug.bcallret1(BackendVariable.isStateVar(var), ComponentReference.crefPrefixDer, cr, cr);
        cr1 = ComponentReference.makeCrefQual("$ZERO",DAE.T_REAL_DEFAULT,{},cr);
        varexp = Expression.crefExp(cr1);
        repl = BackendVarTransform.addReplacement(inRepl,cr,varexp);
        var = BackendVariable.copyVarNewName(cr1,var);
        var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
        var = BackendVariable.setVarAttributes(var, NONE());
        (varLst,repl) = getZeroVarReplacements(rest,inVars,ass2,repl,var::inVarLst);
      then
        (varLst,repl);
  end match;
end getZeroVarReplacements;

protected function getOtherEquationsPointZero "function getOtherEquationsPointZero
  author: Frenkel TUD 2011-05
  try to solve the equations"
  input list<list<Integer>> othercomps;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input BackendVarTransform.VariableReplacements inRepl;
  input array<Boolean> eqnmark;
  input array<Integer> mapIncRowEqn;  
  input list<BackendDAE.Equation> inEqsLst;
  input list<Integer> inComps;
  output list<BackendDAE.Equation> outEqsLst;
  output list<Integer> outComps;
algorithm
  (outEqsLst,outComps) :=
  matchcontinue (othercomps,inVars,inEqns,inRepl,eqnmark,mapIncRowEqn,inEqsLst,inComps)
    local
      list<list<Integer>> rest;
      BackendDAE.EquationArray eqns;
      Integer e,c;
      DAE.Exp varexp;
      BackendDAE.Equation eqn;
      DAE.ComponentRef cr,cr1;
      BackendVarTransform.VariableReplacements repl;
      list<BackendDAE.Equation> eqsLst;
      list<BackendDAE.Var> varLst;
      BackendDAE.Var var;      
    case ({},_,_,_,_,_,_,_) then (listReverse(inEqsLst),listReverse(inComps));
    case ({c}::rest,_,_,_,_,_,_,_)
      equation
        false = eqnmark[c];
        _ = arrayUpdate(eqnmark,c,true);
        e = mapIncRowEqn[c];
        eqn = BackendDAEUtil.equationNth(inEqns, e-1);
        (eqn,_) = BackendEquation.traverseBackendDAEExpsEqn(eqn,replaceDerCalls,inVars);
        eqn::_ = BackendVarTransform.replaceEquations({eqn}, inRepl);
       (outEqsLst,outComps) = getOtherEquationsPointZero(rest,inVars,inEqns,inRepl,eqnmark,mapIncRowEqn,eqn::inEqsLst,e::inComps);
      then
        (outEqsLst,outComps);
    case ({c}::rest,_,_,_,_,_,_,_)
      equation
        true = eqnmark[c];
        (outEqsLst,outComps) = getOtherEquationsPointZero(rest,inVars,inEqns,inRepl,eqnmark,mapIncRowEqn,inEqsLst,inComps);
      then
        (outEqsLst,outComps);        
  end matchcontinue;
end getOtherEquationsPointZero;


protected function replaceDerCalls
  input tuple<DAE.Exp, BackendDAE.Variables> inTpl;
  output tuple<DAE.Exp, BackendDAE.Variables> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local  
      DAE.Exp exp;
      BackendDAE.Variables vars;
    case ((exp,vars))
      equation
         ((exp,_)) = Expression.traverseExp(exp,replaceDerCallsExp,vars);
       then
        ((exp,vars));
    case inTpl then inTpl;
  end matchcontinue;
end replaceDerCalls;

protected function replaceDerCallsExp
  input tuple<DAE.Exp, BackendDAE.Variables> inTuple;
  output tuple<DAE.Exp, BackendDAE.Variables> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
   
     case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars))
      equation
        (_,_) = BackendVariable.getVar(cr,vars);
        cr = ComponentReference.crefPrefixDer(cr);
        e = Expression.crefExp(cr);
      then
        ((e, vars));
    
    case inTuple then inTuple;
  end matchcontinue;
end replaceDerCallsExp;

protected function solveOtherEquations "function solveOtherEquations
  author: Frenkel TUD 2011-05
  try to solve the equations"
  input list<list<Integer>> othercomps;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.Variables inVars;
  input array<Integer> ass2;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements inRepl;
  input list<BackendDAE.Var> iOtherVars;
  output BackendDAE.EquationArray outEqns;
  output BackendVarTransform.VariableReplacements outRepl;
  output list<BackendDAE.Var> oOtherVars;
algorithm
  (outEqns,outRepl,oOtherVars) :=
  matchcontinue (othercomps,inEqns,inVars,ass2,ishared,inRepl,iOtherVars)
    local
      list<list<Integer>> rest;
      BackendDAE.EquationArray eqns;
      Integer v,c;
      DAE.Exp e1,e2,varexp,expr,expr1;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.Var var;
      list<BackendDAE.Var> otherVars;
    case ({},_,_,_,_,_,_) then (inEqns,inRepl,iOtherVars);
    case ({c}::rest,_,_,_,_,_,_)
      equation
        BackendDAE.EQUATION(e1,e2,source) = BackendDAEUtil.equationNth(inEqns, c-1);
        v = ass2[c];
        (var as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(inVars, v);
        varexp = Expression.crefExp(cr);
        varexp = Debug.bcallret2(BackendVariable.isStateVar(var), Derive.differentiateExpTime, varexp, (inVars,ishared), varexp);
        (expr,{}) = ExpressionSolve.solve(e1, e2, varexp);
        (expr1,_) = BackendVarTransform.replaceExp(expr, inRepl, NONE());
        eqns = BackendEquation.equationSetnth(inEqns,c-1,BackendDAE.EQUATION(expr,varexp,source));
        cr = Debug.bcallret1(BackendVariable.isStateVar(var), ComponentReference.crefPrefixDer, cr, cr);
        repl = BackendVarTransform.addReplacement(inRepl,cr,expr1);
        Debug.fcall(Flags.TEARING_DUMP, BackendDump.debugStrCrefStrExpStr,("",cr," := ",expr1,"\n"));
        (eqns,repl,otherVars) = solveOtherEquations(rest,eqns,inVars,ass2,ishared,repl,var::iOtherVars);
      then
        (eqns,repl,otherVars);
  end matchcontinue;
end solveOtherEquations;

protected function replaceOtherVarinResidualEqns "function replaceOtherVarinResidualEqns
  author: Frenkel TUD 2011-05
  try to solve the equations"
  input Integer c;
  input BackendVarTransform.VariableReplacements inRepl;
  input BackendDAE.Variables inOtherVars;
  input BackendDAE.EquationArray inEqns;
  output BackendDAE.EquationArray outEqns;
protected
  BackendDAE.Equation eqn;
algorithm
  eqn := BackendDAEUtil.equationNth(inEqns, c-1);
  (eqn,_) := BackendEquation.traverseBackendDAEExpsEqn(eqn,replaceDerCalls,inOtherVars);
  eqn::_ := BackendVarTransform.replaceEquations({eqn}, inRepl);
  outEqns := BackendEquation.equationSetnth(inEqns,c-1,eqn);
  Debug.fcall(Flags.TEARING_DUMP, BackendDump.printEquation,eqn);
end replaceOtherVarinResidualEqns;

protected function replaceTornEquationsinSystem "function setTornEquationsinSystem
  author: Frenkel TUD 2011-05
  try to solve the equations"
  input list<Integer> residual;
  input array<Integer> eindxarray;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.EqSystem isyst;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match (residual,eindxarray,inEqns,isyst)
    local
      Integer c,index;
      list<Integer> rest;
      BackendDAE.Equation eqn;
      BackendDAE.EqSystem syst;
    case ({},_,_,_) then isyst;
    case (c::rest,_,_,_)
      equation
        index = eindxarray[c];
        eqn = BackendDAEUtil.equationNth(inEqns, c-1);
        syst = BackendEquation.equationSetnthDAE(index-1,eqn,isyst);
      then
        replaceTornEquationsinSystem(rest,eindxarray,inEqns,syst);
  end match;
end replaceTornEquationsinSystem;




/*
 * countOperations
 *
 */
public function countOperations "function countOperations
  author: Frenkel TUD 2011-05"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
algorithm
  (outDAE,outRunMatching) := BackendDAEUtil.mapEqSystemAndFold(inDAE,countOperations0,false);
end countOperations;

protected function countOperations0 "function countOperations0
  author: Frenkel TUD 2011-05"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared,Boolean> sharedChanged;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> osharedChanged;
algorithm
  (osyst,osharedChanged) :=
    matchcontinue(isyst,sharedChanged)
    local
      BackendDAE.Shared shared;
      Boolean b;
      Integer i1,i2,i3;
      BackendDAE.StrongComponents comps;
      
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)),(shared, b))
      equation
        ((i1,i2,i3)) = countOperationstraverseComps(comps,isyst,shared,(0,0,0));
        print("Add Operations: " +& intString(i1) +& "\n");
        print("Mul Operations: " +& intString(i2) +& "\n");
        print("Oth Operations: " +& intString(i3) +& "\n");
      then
        (isyst,(shared,b));
  end matchcontinue;
end countOperations0;

protected function countOperations1 "function countOperations1
  author: Frenkel TUD 2011-05
  count the mathematical operations ((+,-),(*,/),(other))"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input tuple<Integer,Integer,Integer> inTpl;
  output tuple<Integer,Integer,Integer> outTpl;
algorithm
  outTpl:=
  matchcontinue (isyst,ishared,inTpl)
    local
      BackendDAE.Shared shared;
      array<DAE.Constraint> constrs;
      BackendDAE.EquationArray eqns;
     
    case (BackendDAE.EQSYSTEM(orderedEqs = eqns),shared as BackendDAE.SHARED(constraints=constrs),_)
      then
        BackendDAEUtil.traverseBackendDAEExpsEqns(eqns,countOperationsExp,inTpl);
  end matchcontinue;
end countOperations1;

protected function countOperationstraverseComps "function countOperationstraverseComps
  autor: Frenkel TUD 2012-05"
  input BackendDAE.StrongComponents inComps;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input tuple<Integer,Integer,Integer> inTpl;
  output tuple<Integer,Integer,Integer> outTpl;
algorithm
  outTpl := 
  matchcontinue (inComps,isyst,ishared,inTpl)
    local
      Integer e;
      BackendDAE.StrongComponent comp,comp1;
      BackendDAE.StrongComponents rest;
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn;
      tuple<Integer,Integer,Integer> tpl;
      list<BackendDAE.Equation> eqnlst;
      array<DAE.Constraint> constrs;
      BackendDAE.JacobianType jacType;   
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      list<BackendDAE.Var> varlst;
      list<DAE.Exp> explst;
    case ({},_,_,_) then inTpl; 
    case (BackendDAE.SINGLEEQUATION(eqn=e)::rest,_,_,_) 
      equation
        eqns = BackendEquation.daeEqns(isyst);
        eqn = BackendDAEUtil.equationNth(eqns, e-1);
        (_,tpl) = BackendEquation.traverseBackendDAEExpsEqn(eqn,countOperationsExp,inTpl);
      then 
         countOperationstraverseComps(rest,isyst,ishared,tpl);
    case ((comp as BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp1))::rest,_,_,_) 
      equation
        tpl = countOperationstraverseComps({comp1},isyst,ishared,inTpl);
        (eqnlst,_,_) = BackendDAETransform.getEquationAndSolvedVar(comp, BackendEquation.daeEqns(isyst), BackendVariable.daeVars(isyst));
        tpl = BackendDAEUtil.traverseBackendDAEExpsEqns(BackendDAEUtil.listEquation(eqnlst),countOperationsExp,tpl);
      then
        countOperationstraverseComps(rest,isyst,ishared,tpl);
    case ((comp as BackendDAE.EQUATIONSYSTEM(jac=jac,jacType=BackendDAE.JAC_TIME_VARYING()))::rest,_,_,_) 
      equation
        (eqnlst,varlst,_) = BackendDAETransform.getEquationAndSolvedVar(comp, BackendEquation.daeEqns(isyst), BackendVariable.daeVars(isyst));
        tpl = addJacSpecificOperations(listLength(eqnlst),inTpl);
        tpl = countOperationsJac(jac,tpl);        
        ((_,explst,_)) = BackendEquation.traverseBackendDAEEqns(BackendDAEUtil.listEquation(eqnlst),BackendEquation.equationToExp,(BackendDAEUtil.listVar1(varlst),{},{}));
        ((_,tpl)) = Expression.traverseExpList(explst,countOperationsExp,tpl);
      then 
         countOperationstraverseComps(rest,isyst,ishared,tpl);
    case ((comp as BackendDAE.EQUATIONSYSTEM(jac=_))::rest,_,_,_) 
      equation
        (eqnlst,_,_) = BackendDAETransform.getEquationAndSolvedVar(comp, BackendEquation.daeEqns(isyst), BackendVariable.daeVars(isyst));
        tpl = BackendDAEUtil.traverseBackendDAEExpsEqns(BackendDAEUtil.listEquation(eqnlst),countOperationsExp,inTpl);
      then
        countOperationstraverseComps(rest,isyst,ishared,tpl);
    case (BackendDAE.SINGLEARRAY(eqns=e::_)::rest,_,_,_)
      equation 
         eqn = BackendDAEUtil.equationNth(BackendEquation.daeEqns(isyst), e-1);
         (_,tpl) = BackendEquation.traverseBackendDAEExpsEqn(eqn,countOperationsExp,inTpl);
      then 
         countOperationstraverseComps(rest,isyst,ishared,tpl); 
    case (BackendDAE.SINGLEALGORITHM(eqns=e::_)::rest,_,_,_)
      equation
         eqn = BackendDAEUtil.equationNth(BackendEquation.daeEqns(isyst), e-1);
         (_,tpl) = BackendEquation.traverseBackendDAEExpsEqn(eqn,countOperationsExp,inTpl);
      then 
         countOperationstraverseComps(rest,isyst,ishared,tpl);
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqns=e::_)::rest,_,_,_)
      equation 
         eqn = BackendDAEUtil.equationNth(BackendEquation.daeEqns(isyst), e-1);
         (_,tpl) = BackendEquation.traverseBackendDAEExpsEqn(eqn,countOperationsExp,inTpl);
      then 
         countOperationstraverseComps(rest,isyst,ishared,tpl); 
    case (_::rest,_,_,_) 
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("BackendDAEOptimize.countOperationstraverseComps failed!");
      then
         countOperationstraverseComps(rest,isyst,ishared,inTpl);
    case (_::rest,_,_,_) 
      then
        countOperationstraverseComps(rest,isyst,ishared,inTpl);
  end matchcontinue;
end countOperationstraverseComps;

protected function countOperationsJac
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> inJac;
  input tuple<Integer,Integer,Integer> inTpl;
  output tuple<Integer,Integer,Integer> outTpl;
algorithm
  outTpl := match(inJac,inTpl)
    local
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      case (NONE(),_) then inTpl;
      case (SOME(jac),_)
        then List.fold(jac,countOperationsJac1,inTpl);
  end match;
end countOperationsJac;

protected function countOperationsJac1
  input tuple<Integer, Integer, BackendDAE.Equation> inJac;
  input tuple<Integer,Integer,Integer> inTpl;
  output tuple<Integer,Integer,Integer> outTpl;
algorithm
  (_,outTpl) := BackendEquation.traverseBackendDAEExpsEqn(Util.tuple33(inJac),countOperationsExp,inTpl);
end countOperationsJac1;

protected function addJacSpecificOperations
  input Integer n;
  input tuple<Integer,Integer,Integer> inTpl;
  output tuple<Integer,Integer,Integer> outTpl;
protected
  Integer i1,i2,i3,i1_1,i2_1,n2,n3;
algorithm
  (i1,i2,i3) := inTpl;
  n2 := n*n;
  n3 := n*n*n;
  i1_1 := intDiv(2*n3+3*n2-5*n,6) + i1;
  i2_1 := intDiv(2*n3+6*n2-2*n,6) + i2;
  outTpl := (i1_1,i2_1,i3);
end addJacSpecificOperations;

protected function countOperationsExp
  input tuple<DAE.Exp, tuple<Integer,Integer,Integer>> inTpl;
  output tuple<DAE.Exp, tuple<Integer,Integer,Integer>> outTpl;
algorithm
  outTpl := matchcontinue inTpl
    local
      DAE.Exp exp;
      Integer i1,i2,i3,i1_1,i2_1,i3_1;
    case ((exp,(i1,i2,i3))) equation
      ((_,(i1_1,i2_1,i3_1))) = Expression.traverseExp(exp,traversecountOperationsExp,(i1,i2,i3));
    then ((exp,(i1_1,i2_1,i3_1)));
    case inTpl then inTpl;
  end matchcontinue;
end countOperationsExp;

protected function traversecountOperationsExp
  input tuple<DAE.Exp, tuple<Integer,Integer,Integer>> inTuple;
  output tuple<DAE.Exp, tuple<Integer,Integer,Integer>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      Integer i1,i2,i3,i1_1,i2_1,i3_1,iexp2;
      Real rexp2;
      DAE.Operator op;
    case ((e as DAE.BINARY(operator=DAE.POW(ty=_),exp2=DAE.RCONST(rexp2)),(i1,i2,i3))) equation
      iexp2 = realInt(rexp2);
      true = realEq(rexp2, intReal(iexp2));
      i2_1 = i2+intAbs(iexp2)-1;
      then ((e, (i1,i2_1,i3)));
    case ((e as DAE.BINARY(operator=op),(i1,i2,i3))) equation
      (i1_1,i2_1,i3_1) = countOperator(op,i1,i2,i3);
      then ((e, (i1_1,i2_1,i3_1)));
    case inTuple then inTuple;
  end matchcontinue;
end traversecountOperationsExp;

protected function countOperator
  input DAE.Operator op;
  input Integer inInt1;
  input Integer inInt2;
  input Integer inInt3;
  output Integer outInt1;
  output Integer outInt2;
  output Integer outInt3;
algorithm
  (outInt1,outInt2,outInt3) := match(op, inInt1, inInt2, inInt3)
    local
      DAE.Type tp;
      Integer i;
    case (DAE.ADD(ty=_),_,_,_)
      then (inInt1+1,inInt2,inInt3);
    case (DAE.SUB(ty=_),_,_,_)
      then (inInt1+1,inInt2,inInt3);
    case (DAE.MUL(ty=_),_,_,_)
      then (inInt1,inInt2+1,inInt3);
    case (DAE.DIV(ty=_),_,_,_)
      then (inInt1,inInt2+1,inInt3);
    case (DAE.POW(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.UMINUS(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.UMINUS_ARR(ty=tp),_,_,_) equation
      i = Expression.sizeOf(tp);
      then (inInt1,inInt2,inInt3+i);
    case (DAE.ADD_ARR(ty=tp),_,_,_) equation
      i = Expression.sizeOf(tp);
      then (inInt1+i,inInt2,inInt3);
    case (DAE.SUB_ARR(ty=tp),_,_,_) equation
      i = Expression.sizeOf(tp);
      then (inInt1+i,inInt2,inInt3);
    case (DAE.MUL_ARR(ty=tp),_,_,_) equation
      i = Expression.sizeOf(tp);
      then (inInt1,inInt2+i,inInt3);
    case (DAE.DIV_ARR(ty=tp),_,_,_) equation
      i = Expression.sizeOf(tp);
      then (inInt1,inInt2+i,inInt3);
    case (DAE.MUL_ARRAY_SCALAR(ty=tp),_,_,_) equation
      i = Expression.sizeOf(tp);
      then (inInt1,inInt2+i,inInt3);
    case (DAE.ADD_ARRAY_SCALAR(ty=_),_,_,_)
      then (inInt1+1,inInt2,inInt3);
    case (DAE.SUB_SCALAR_ARRAY(ty=_),_,_,_)
      then (inInt1+1,inInt2,inInt3);
    case (DAE.MUL_SCALAR_PRODUCT(ty=_),_,_,_)
      then (inInt1,inInt2+1,inInt3);
    case (DAE.MUL_MATRIX_PRODUCT(ty=_),_,_,_)
      then (inInt1,inInt2+1,inInt3);
    case (DAE.DIV_ARRAY_SCALAR(ty=_),_,_,_)
      then (inInt1,inInt2+1,inInt3);
    case (DAE.DIV_SCALAR_ARRAY(ty=_),_,_,_)
      then (inInt1,inInt2+1,inInt3);
    case (DAE.POW_ARRAY_SCALAR(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.POW_SCALAR_ARRAY(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.POW_ARR(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.POW_ARR2(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.AND(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.OR(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.NOT(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.NOT(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.LESS(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.LESSEQ(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.GREATER(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.GREATEREQ(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.EQUAL(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.NEQUAL(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.USERDEFINED(fqName=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    else
      then(inInt1,inInt2,inInt3+1);
  end match;
end countOperator;

end BackendDAEOptimize;
