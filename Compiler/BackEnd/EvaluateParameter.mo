/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

encapsulated package EvaluateParameter
" file:        EvaluateParameter.mo
  package:     EvaluateParameter
  description: EvaluateParameter contains functions to evaluated the bindexp of parameters with final=true or
               annotation(Evaluate=true) and parameters which depent only on evaluated parameters

               Concept:

               traverse all parameter and get the parameters which must be evaluated O(N)

               traverse the list and evaluate each parameter with a DFS  O(N)
               -> replacements for evaluated parameter

               sort the parameters with tarjans algorithm O(N)

               traverse the sorted parameters and replace in the bindexp the evaluated parameters
               if a parameter have before a nonconstant bindexp and now a constant add it to the replacements

              there are  main function

              - evaluate and replace parameters with final=true in variables and parameters
              - evaluate and replace parameters with annotation(Evaluate=true) in variables and parameters
              - evaluate and replace parameters with final=true or annotation(Evaluate=true) in variables and parameters

              - evaluate and replace parameters with final=true in equations, variables and parameters
              - evaluate and replace parameters with annotation(Evaluate=true) in equations, variables and parameters
              - evaluate and replace parameters with final=true or annotation(Evaluate=true) in equations, variables and parameters


  RCS: $Id: EvaluateParameter.mo 15281 2013-02-22 17:30:41Z jfrenkel $"

public import Absyn;
public import BackendDAE;
public import DAE;
public import Env;

protected import BackendDAETransform;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import BackendVarTransform;
protected import BaseHashTable;
protected import BaseHashSet;
protected import Ceval;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import HashSet;
protected import List;
protected import Util;
protected import Values;
protected import ValuesUtil;

/*
 * type section
 *
 */

partial function selectParameterFunc
  input BackendDAE.Var inVar;
  output Boolean select;
end selectParameterFunc;

/*
 * public section
 *
 */

public function evaluateFinalParameters
"author Frenkel TUD
  evaluate and replace parameters with final=true in variables and parameters"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE,_ ) := evaluateParameters(inDAE,BackendVariable.isFinalVar);
end evaluateFinalParameters;

public function evaluateEvaluateParameters
"author Frenkel TUD
  evaluate and replace parameters with annotation(Evaluate=true) in variables and parameters"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE,_ ) := evaluateParameters(inDAE,BackendVariable.hasVarEvaluateAnnotation);
end evaluateEvaluateParameters;

public function evaluateFinalEvaluateParameters
"author Frenkel TUD
  evaluate and replace parameters with final=true in variables and parameters"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE,_ ) := evaluateParameters(inDAE,BackendVariable.hasVarEvaluateAnnotationOrFinal);
end evaluateFinalEvaluateParameters;

public function evaluateReplaceFinalParameters
"author Frenkel TUD
  evaluate and replace parameters with final=true in variables and parameters"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendVarTransform.VariableReplacements repl;
algorithm
  (outDAE,repl) := evaluateParameters(inDAE,BackendVariable.isFinalVar);
  outDAE := replaceEvaluatedParametersEqns(BackendVarTransform.replacementEmpty(repl),outDAE,repl);
end evaluateReplaceFinalParameters;

public function evaluateReplaceEvaluateParameters
"author Frenkel TUD
  evaluate and replace parameters with annotation(Evaluate=true) in variables and parameters"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendVarTransform.VariableReplacements repl;
algorithm
  (outDAE,repl) := evaluateParameters(inDAE,BackendVariable.hasVarEvaluateAnnotation);
  outDAE := replaceEvaluatedParametersEqns(BackendVarTransform.replacementEmpty(repl),outDAE,repl);
end evaluateReplaceEvaluateParameters;

public function evaluateReplaceFinalEvaluateParameters "author: Frenkel TUD
  Evaluates and replaces parameters with final=true in variables and parameters."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendVarTransform.VariableReplacements repl;
algorithm
  (outDAE,repl) := evaluateParameters(inDAE,BackendVariable.hasVarEvaluateAnnotationOrFinal);
  outDAE := replaceEvaluatedParametersEqns(BackendVarTransform.replacementEmpty(repl),outDAE,repl);
end evaluateReplaceFinalEvaluateParameters;

/*
 * protected section
 *
 */

protected function evaluateParameters
"author Frenkel TUD
  evaluate and replace parameters with annotation(Evaluate=true) in variables and parameters"
  input BackendDAE.BackendDAE inDAE;
  input selectParameterFunc selectParameterfunc;
  output BackendDAE.BackendDAE outDAE;
  output BackendVarTransform.VariableReplacements oRepl;
algorithm
  (outDAE,oRepl) := match (inDAE,selectParameterfunc)
    local
      DAE.FunctionTree funcs;
      BackendDAE.Variables knvars,exobj,av;
      BackendDAE.EquationArray remeqns,inieqns;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendVarTransform.VariableReplacements repl,repleval;
      BackendDAE.BackendDAEType btp;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      list<list<Integer>> comps;
      array<Integer> ass,markarr;
      Integer size,mark,nselect;
      BackendDAE.IncidenceMatrixT m;
      BackendDAE.IncidenceMatrixT mt;
      list<Integer> selectedParameter;
      BackendDAE.ExtraInfo ei;
      
    case (BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs,ei)),_)
      equation
        // get parameters with annotation(Evaluate=true)
        size = BackendVariable.varsSize(knvars);
        m = arrayCreate(size,{});
        mt = arrayCreate(size,{});
        ass = arrayCreate(size,-1);
        ((_,_,_,selectedParameter,nselect,ass,m,mt)) = BackendVariable.traverseBackendDAEVars(knvars,getParameterIncidenceMatrix,(knvars,1,selectParameterfunc,{},0,ass,m,mt));
        // evaluate selected parameters
        size = intMax(BaseHashTable.defaultBucketSize,realInt(realMul(intReal(size),0.7)));
        nselect = intMax(BaseHashTable.defaultBucketSize,nselect*2);
        repl = BackendVarTransform.emptyReplacementsSized(size);
        repleval = BackendVarTransform.emptyReplacementsSized(nselect);
        markarr = arrayCreate(size,-1);
        (knvars,cache,repl,repleval,mark) = evaluateSelectedParameters(selectedParameter,knvars,m,inieqns,cache,env,1,markarr,repl,repleval);
        // replace evaluated parameter in parameters
        comps = BackendDAETransform.tarjanAlgorithm(mt, ass);
         // evaluate vars with bind expression consists of evaluated vars
        (knvars,repl,repleval,cache,mark) = traverseParameterSorted(comps,knvars,m,inieqns,cache,env,mark,markarr,repl,repleval);
        Debug.fcall(Flags.DUMP_EA_REPL, BackendVarTransform.dumpReplacements, repleval);
        // replace evaluated parameter in variables
        (systs,(knvars,m,inieqns,cache,env,mark,markarr,repl,repleval)) = List.mapFold(systs,replaceEvaluatedParametersSystem,(knvars,m,inieqns,cache,env,mark,markarr,repl,repleval));
        (av,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(av,replaceEvaluatedParameterTraverser,(knvars,m,inieqns,cache,env,mark,markarr,repl,repleval));
      then
        (BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs,ei)),repleval);
  end match;
end evaluateParameters;


protected function getParameterIncidenceMatrix
  input tuple<BackendDAE.Var,tuple<BackendDAE.Variables,Integer,selectParameterFunc,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrix,BackendDAE.IncidenceMatrixT>> inTp;
  output tuple<BackendDAE.Var,tuple<BackendDAE.Variables,Integer,selectParameterFunc,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrix,BackendDAE.IncidenceMatrixT>> outTpl;
algorithm
  outTpl := matchcontinue (inTp)
    local
      BackendDAE.Variables knvars;
      BackendDAE.Var v;
      DAE.Exp e;
      Option<DAE.VariableAttributes> attr;
      list<Integer> ilst,selectedParameter;
      Integer index,nselect;
      array<Integer> ass;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      selectParameterFunc selectParameter;
      Boolean select;

    case ((v as BackendDAE.VAR(varKind=BackendDAE.PARAM(),bindExp=SOME(e)),(knvars,index,selectParameter,selectedParameter,nselect,ass,m,mt)))
      equation
        ((_,(_,ilst))) = Expression.traverseExpTopDown(e, BackendDAEUtil.traversingincidenceRowExpFinder, (knvars,{}));
        select = selectParameter(v);
        selectedParameter = List.consOnTrue(select, index, selectedParameter);
        ass = arrayUpdate(ass,index,index);
        m = arrayUpdate(m,index,ilst);
        mt = List.fold1(index::ilst,Util.arrayCons,index,mt);
      then
        ((v,(knvars,index+1,selectParameter,selectedParameter,nselect,ass,m,mt)));

    case ((v as BackendDAE.VAR(varKind=BackendDAE.PARAM(),values=attr),(knvars,index,selectParameter,selectedParameter,nselect,ass,m,mt)))
      equation
        e = DAEUtil.getStartAttrFail(attr);
        ((_,(_,ilst))) = Expression.traverseExpTopDown(e, BackendDAEUtil.traversingincidenceRowExpFinder, (knvars,{}));
        select = selectParameter(v);
        selectedParameter = List.consOnTrue(select, index, selectedParameter);
        ass = arrayUpdate(ass,index,index);
        m = arrayUpdate(m,index,ilst);
        mt = List.fold1(index::ilst,Util.arrayCons,index,mt);
      then
        ((v,(knvars,index+1,selectParameter,selectedParameter,nselect,ass,m,mt)));

    case ((v,(knvars,index,selectParameter,selectedParameter,nselect,ass,m,mt)))
      equation
        select = selectParameter(v);
        selectedParameter = List.consOnTrue(select, index, selectedParameter);
        ass = arrayUpdate(ass,index,index);
        ilst = {index};
        mt = arrayUpdate(mt,index,ilst);
      then
        ((v,(knvars,index+1,selectParameter,selectedParameter,nselect,ass,m,mt)));
  end matchcontinue;
end getParameterIncidenceMatrix;


protected function evaluateSelectedParameters
"author Frenkel TUD"
  input list<Integer> iSelected;
  input BackendDAE.Variables iKnVars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input Env.Cache iCache;
  input Env.Env env;
  input Integer iMark;
  input array<Integer> markarr;
  input BackendVarTransform.VariableReplacements iRepl;
  input BackendVarTransform.VariableReplacements iReplEvaluate;
  output BackendDAE.Variables oKnVars;
  output Env.Cache oCache;
  output BackendVarTransform.VariableReplacements oRepl;
  output BackendVarTransform.VariableReplacements oReplEvaluate;
  output Integer oMark;
algorithm
  (oKnVars,oCache,oRepl,oReplEvaluate,oMark) := match (iSelected,iKnVars,m,inIEqns,iCache,env,iMark,markarr,iRepl,iReplEvaluate)
    local
      Integer i,mark;
      list<Integer> rest;
      BackendDAE.Variables knVars;
      BackendVarTransform.VariableReplacements repl,repleval;
      BackendDAE.Var v;
      Env.Cache cache;
    case ({},_,_,_,_,_,_,_,_,_) then (iKnVars,iCache,iRepl,iReplEvaluate,iMark);
    case (i::rest,_,_,_,_,_,_,_,_,_)
      equation
        (knVars,cache,repl,repleval,mark) = evaluateSelectedParameters0(i,iKnVars,m,inIEqns,iCache,env,iMark,markarr,iRepl,iReplEvaluate);
        (knVars,cache,repl,repleval,mark) = evaluateSelectedParameters(rest,knVars,m,inIEqns,cache,env,mark,markarr,repl,repleval);
      then (knVars,cache,repl,repleval,mark);
  end match;
end evaluateSelectedParameters;

protected function evaluateSelectedParameters0
"author Frenkel TUD"
  input Integer i;
  input BackendDAE.Variables iKnVars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input Env.Cache iCache;
  input Env.Env env;
  input Integer iMark;
  input array<Integer> markarr;
  input BackendVarTransform.VariableReplacements iRepl;
  input BackendVarTransform.VariableReplacements iReplEvaluate;
  output BackendDAE.Variables oKnVars;
  output Env.Cache oCache;
  output BackendVarTransform.VariableReplacements oRepl;
  output BackendVarTransform.VariableReplacements oReplEvaluate;
  output Integer oMark;
algorithm
  (oKnVars,oCache,oRepl,oReplEvaluate,oMark) := matchcontinue(i,iKnVars,m,inIEqns,iCache,env,iMark,markarr,iRepl,iReplEvaluate)
    local
      Integer mark;
      list<Integer> rest;
      BackendDAE.Variables knVars;
      BackendVarTransform.VariableReplacements repl,repleval;
      BackendDAE.Var v;
      Env.Cache cache;
    case (_,_,_,_,_,_,_,_,_,_)
      equation
        false = intGt(markarr[i],0) "not allready evaluated";
        _ = arrayUpdate(markarr,i,iMark);
        // evaluate needed parameters
        (knVars,cache,repl,mark) = evaluateSelectedParameters1(m[i],iKnVars,m,inIEqns,iCache,env,iMark,markarr,iRepl);
        // evaluate parameter
        v = BackendVariable.getVarAt(knVars,i);
        (v,knVars,cache,repl,mark) = evaluateFixedAttribute(v,true,knVars,m,inIEqns,cache,env,mark,markarr,repl);
        (knVars,cache,repl,repleval) = evaluateSelectedParameter(v,i,knVars,inIEqns,repl,iReplEvaluate,cache,env);
      then
        (knVars,cache,repl,repleval,mark);
    case (_,_,_,_,_,_,_,_,_,_)
      equation
        // evaluate parameter
        v = BackendVariable.getVarAt(iKnVars,i);
        (knVars,cache,repl,repleval) = evaluateSelectedParameter(v,i,iKnVars,inIEqns,iRepl,iReplEvaluate,iCache,env);
      then (knVars,cache,repl,repleval,iMark);
  end matchcontinue;
end evaluateSelectedParameters0;

protected function evaluateSelectedParameters1
"author Frenkel TUD"
  input list<Integer> iUsed;
  input BackendDAE.Variables iKnVars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input Env.Cache iCache;
  input Env.Env env;
  input Integer iMark;
  input array<Integer> markarr;
  input BackendVarTransform.VariableReplacements iRepl;
  output BackendDAE.Variables oKnVars;
  output Env.Cache oCache;
  output BackendVarTransform.VariableReplacements oRepl;
  output Integer oMark;
algorithm
  (oKnVars,oCache,oRepl,oMark) := matchcontinue(iUsed,iKnVars,m,inIEqns,iCache,env,iMark,markarr,iRepl)
    local
      Integer i,mark;
      list<Integer> rest;
      BackendDAE.Variables knVars;
      BackendVarTransform.VariableReplacements repl;
      Env.Cache cache;
      BackendDAE.Var v;
    case ({},_,_,_,_,_,_,_,_)
      then (iKnVars,iCache,iRepl,iMark);
    case (i::rest,_,_,_,_,_,_,_,_)
      equation
        false = intGt(markarr[i],0) "not allready evaluated";
        _ = arrayUpdate(markarr,i,iMark);
        (knVars,cache,repl,mark) = evaluateSelectedParameters1(m[i],iKnVars,m,inIEqns,iCache,env,iMark,markarr,iRepl);
        v = BackendVariable.getVarAt(knVars,i);
        (v,knVars,cache,repl,mark) = evaluateFixedAttribute(v,true,knVars,m,inIEqns,cache,env,mark,markarr,repl);
        (knVars,cache,repl) = evaluateParameter(v,knVars,inIEqns,repl,cache,env);
        (knVars,cache,repl,mark) = evaluateSelectedParameters1(rest,knVars,m,inIEqns,cache,env,mark,markarr,repl);
      then
        (knVars,cache,repl,mark);
    case (_::rest,_,_,_,_,_,_,_,_)
      equation
        (knVars,cache,repl,mark) = evaluateSelectedParameters1(rest,iKnVars,m,inIEqns,iCache,env,iMark,markarr,iRepl);
      then
        (knVars,cache,repl,mark);
  end matchcontinue;
end evaluateSelectedParameters1;


protected function evaluateSelectedParameter
"author Frenkel TUD"
  input BackendDAE.Var var;
  input Integer index;
  input BackendDAE.Variables inKnVars;
  input BackendDAE.EquationArray inIEqns;
  input BackendVarTransform.VariableReplacements iRepl;
  input BackendVarTransform.VariableReplacements iReplEvaluate;
  input Env.Cache iCache;
  input Env.Env env;
  output BackendDAE.Variables oKnVars;
  output Env.Cache oCache;
  output BackendVarTransform.VariableReplacements oRepl;
  output BackendVarTransform.VariableReplacements oReplEvaluate;
algorithm
  (oKnVars,oCache,oRepl,oReplEvaluate) := matchcontinue(var,index,inKnVars,inIEqns,iRepl,iReplEvaluate,iCache,env)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      DAE.Exp e,e1;
      Option<DAE.VariableAttributes> attr;
      BackendVarTransform.VariableReplacements repl,repleval;
      Env.Cache cache;
      Values.Value value;
      BackendDAE.Variables knvars;
      Absyn.Info info;
      String msg;
    // Parameter with evaluate=true
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.CONST(),bindExp=SOME(e)),_,_,_,_,_,_,_)
      equation
        true = Expression.isConst(e);
        // save replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr, e, NONE());
        repleval = BackendVarTransform.addReplacement(iReplEvaluate, cr, e ,NONE());
        //  print("Evaluate Selected " +& BackendDump.varString(var) +& "\n->    " +& BackendDump.varString(v) +& "\n");
      then
        (inKnVars,iCache,repl,repleval);
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.CONST(),bindExp=SOME(e)),_,_,_,_,_,_,_)
      equation
        // apply replacements
        (e1,_) = BackendVarTransform.replaceExp(e, iRepl, NONE());
        // evaluate expression
        (cache, value,_) = Ceval.ceval(iCache, env, e1, false, NONE(), Absyn.NO_MSG(),0);
        e1 = ValuesUtil.valueExp(value);
        // set bind value
        v = BackendVariable.setBindExp(var, SOME(e1));
        // update Vararray
        knvars = BackendVariable.setVarAt(inKnVars, index, v);
        // save replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr, e1, NONE());
        repleval = BackendVarTransform.addReplacement(iReplEvaluate, cr, e1 ,NONE());
        //  print("Evaluate Selected " +& BackendDump.varString(var) +& "\n->    " +& BackendDump.varString(v) +& "\n");
      then
        (knvars,cache,repl,repleval);
    // Parameter with evaluate=true
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),bindExp=SOME(e)),_,_,_,_,_,_,_)
      equation
        true = Expression.isConst(e);
        v = BackendVariable.setVarFinal(var, true);
        // update Vararray
        knvars = BackendVariable.setVarAt(inKnVars, index, v);
        // save replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr, e, NONE());
        repleval = BackendVarTransform.addReplacement(iReplEvaluate, cr, e ,NONE());
        //  print("Evaluate Selected " +& BackendDump.varString(var) +& "\n->    " +& BackendDump.varString(v) +& "\n");
      then
        (knvars,iCache,repl,repleval);
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),bindExp=SOME(e)),_,_,_,_,_,_,_)
      equation
        // apply replacements
        (e1,_) = BackendVarTransform.replaceExp(e, iRepl, NONE());
        // evaluate expression
        (cache, value,_) = Ceval.ceval(iCache, env, e1, false, NONE(), Absyn.NO_MSG(),0);
        e1 = ValuesUtil.valueExp(value);
        // set bind value
        v = BackendVariable.setBindExp(var, SOME(e1));
        v = BackendVariable.setVarFinal(v, true);
        // update Vararray
        knvars = BackendVariable.setVarAt(inKnVars, index, v);
        // save replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr, e1, NONE());
        repleval = BackendVarTransform.addReplacement(iReplEvaluate, cr, e1 ,NONE());
        //  print("Evaluate Selected " +& BackendDump.varString(var) +& "\n->    " +& BackendDump.varString(v) +& "\n");
      then
        (knvars,cache,repl,repleval);
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),bindValue=SOME(value)),_,_,_,_,_,_,_)
      equation
        true = BackendVariable.varFixed(var);
        e = ValuesUtil.valueExp(value);
        v = BackendVariable.setVarFinal(var, true);
        // update Vararray
        knvars = BackendVariable.setVarAt(inKnVars, index, v);
        // save replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr, e, NONE());
        repleval = BackendVarTransform.addReplacement(iReplEvaluate, cr, e, NONE());
        //  print("Evaluate Selected " +& BackendDump.varString(var) +& "\n->    " +& BackendDump.varString(v) +& "\n");
      then
        (knvars,iCache,repl,repleval);
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),values=attr),_,_,_,_,_,_,_)
      equation
        true = BackendVariable.varFixed(var);
        e = DAEUtil.getStartAttrFail(attr);
        // apply replacements
        (e1,_) = BackendVarTransform.replaceExp(e, iRepl, NONE());
        // evaluate expression
        (cache, value,_) = Ceval.ceval(iCache, env, e1, false, NONE(), Absyn.NO_MSG(),0);
        e1 = ValuesUtil.valueExp(value);
        // set bind value
        v = BackendVariable.setVarStartValue(var,e1);
        v = BackendVariable.setVarFinal(v, true);
        // update Vararray
        knvars = BackendVariable.setVarAt(inKnVars, index, v);
        // save replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr, e1, NONE());
        repleval = BackendVarTransform.addReplacement(iReplEvaluate, cr, e1, NONE());
        //  print("Evaluate Selected " +& BackendDump.varString(var) +& "\n->    " +& BackendDump.varString(v) +& "\n");
      then
        (knvars,cache,repl,repleval);
    // try to evaluate with initial equations

    // report warning
    case(_,_,_,_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.PEDANTIC);
        info = DAEUtil.getElementSourceFileInfo(BackendVariable.getVarSource(var));
        msg = "Cannot evaluate Variable \"" +& BackendDump.varString(var);
        Error.addSourceMessage(Error.COMPILER_WARNING, {msg}, info);
      then
        (inKnVars,iCache,iRepl,iReplEvaluate);
    else
      then
        (inKnVars,iCache,iRepl,iReplEvaluate);
  end matchcontinue;
end evaluateSelectedParameter;

protected function evaluateParameter
"author Frenkel TUD"
  input BackendDAE.Var var;
  input BackendDAE.Variables inKnVars;
  input BackendDAE.EquationArray inIEqns;
  input BackendVarTransform.VariableReplacements iRepl;
  input Env.Cache iCache;
  input Env.Env env;
  output BackendDAE.Variables oKnVars;
  output Env.Cache oCache;
  output BackendVarTransform.VariableReplacements oRepl;
algorithm
  (oKnVars,oCache,oRepl) := matchcontinue(var,inKnVars,inIEqns,iRepl,iCache,env)
    local
      DAE.ComponentRef cr;
      DAE.Exp e,e1;
      Option<DAE.VariableAttributes> attr;
      BackendVarTransform.VariableReplacements repl;
      Env.Cache cache;
      Values.Value value;
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),bindExp=SOME(e)),_,_,_,_,_)
      equation
        // applay replacements
        (e,_) = BackendVarTransform.replaceExp(e, iRepl, NONE());
        // evaluate expression
        (cache, value,_) = Ceval.ceval(iCache, env, e, false, NONE(), Absyn.NO_MSG(), 0);
        e1 = ValuesUtil.valueExp(value);
        // save replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr, e1, NONE());
        //  print("Evaluate " +& BackendDump.varString(var) +& "\n->    " +& ExpressionDump.printExpStr(e1) +& "\n");
      then
        (inKnVars,cache,repl);
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),bindValue=SOME(value)),_,_,_,_,_)
      equation
        true = BackendVariable.varFixed(var);
        e = ValuesUtil.valueExp(value);
        // save replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr, e, NONE());
        //  print("Evaluate " +& BackendDump.varString(var) +& "\n->    " +& ExpressionDump.printExpStr(e) +& "\n");
      then
        (inKnVars,iCache,repl);
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),values=attr),_,_,_,_,_)
      equation
        true = BackendVariable.varFixed(var);
        e = DAEUtil.getStartAttrFail(attr);
        // applay replacements
        (e,_) = BackendVarTransform.replaceExp(e, iRepl, NONE());
        // evaluate expression
        (cache, value,_) = Ceval.ceval(iCache, env, e, false, NONE(), Absyn.NO_MSG(),0);
        e1 = ValuesUtil.valueExp(value);
        // save replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr, e1, NONE());
        //  print("Evaluate " +& BackendDump.varString(var) +& "\n->    " +& ExpressionDump.printExpStr(e1) +& "\n");
      then
        (inKnVars,cache,repl);
    // try to evaluate with initial equations

    // not evaluated
    else then (inKnVars,iCache,iRepl);
  end matchcontinue;
end evaluateParameter;


protected function evaluateFixedAttribute
  input BackendDAE.Var var;
  input Boolean addVar;
  input BackendDAE.Variables iKnVars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input Env.Cache iCache;
  input Env.Env env;
  input Integer iMark;
  input array<Integer> markarr;
  input BackendVarTransform.VariableReplacements iRepl;
  output BackendDAE.Var oVar;
  output BackendDAE.Variables oKnVars;
  output Env.Cache oCache;
  output BackendVarTransform.VariableReplacements oRepl;
  output Integer oMark;
algorithm
  (oVar,oKnVars,oCache,oRepl,oMark) := match(var,addVar,iKnVars,m,inIEqns,iCache,env,iMark,markarr,iRepl)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
      Option<DAE.VariableAttributes> attr;
      BackendDAE.Var v;
      DAE.ElementSource source;
      BackendDAE.Variables knVars;
      Integer mark;
      Env.Cache cache;
      BackendVarTransform.VariableReplacements repl;
    case (BackendDAE.VAR(values= NONE()),_,_,_,_,_,_,_,_,_)
      then
        (var,iKnVars,iCache,iRepl,iMark);
    case (BackendDAE.VAR(varName=_,values=SOME(DAE.VAR_ATTR_REAL(fixed=SOME(DAE.BCONST(_))))),_,_,_,_,_,_,_,_,_)
      then
        (var,iKnVars,iCache,iRepl,iMark);
    case (BackendDAE.VAR(varName=_,values=SOME(DAE.VAR_ATTR_INT(fixed=SOME(DAE.BCONST(_))))),_,_,_,_,_,_,_,_,_)
      then
        (var,iKnVars,iCache,iRepl,iMark);
    case (BackendDAE.VAR(varName=_,values=SOME(DAE.VAR_ATTR_BOOL(fixed=SOME(DAE.BCONST(_))))),_,_,_,_,_,_,_,_,_)
      then
        (var,iKnVars,iCache,iRepl,iMark);
    case (BackendDAE.VAR(varName=_,values=SOME(DAE.VAR_ATTR_ENUMERATION(fixed=SOME(DAE.BCONST(_))))),_,_,_,_,_,_,_,_,_)
      then
        (var,iKnVars,iCache,iRepl,iMark);
    case (BackendDAE.VAR(varName=cr,values=attr as SOME(DAE.VAR_ATTR_REAL(fixed=SOME(e))),source=source),_,_,_,_,_,_,_,_,_)
      equation
        (v,knVars,cache,repl,mark) = evaluateFixedAttribute1(cr,e,attr,source,var,addVar,iKnVars,m,inIEqns,iCache,env,iMark,markarr,iRepl);
      then
        (v,knVars,cache,repl,mark);
    case (BackendDAE.VAR(varName=cr,values=attr as SOME(DAE.VAR_ATTR_INT(fixed=SOME(e))),source=source),_,_,_,_,_,_,_,_,_)
      equation
        (v,knVars,cache,repl,mark) = evaluateFixedAttribute1(cr,e,attr,source,var,addVar,iKnVars,m,inIEqns,iCache,env,iMark,markarr,iRepl);
      then
        (v,knVars,cache,repl,mark);
    case (BackendDAE.VAR(varName=cr,values=attr as SOME(DAE.VAR_ATTR_BOOL(fixed=SOME(e))),source=source),_,_,_,_,_,_,_,_,_)
      equation
        (v,knVars,cache,repl,mark) = evaluateFixedAttribute1(cr,e,attr,source,var,addVar,iKnVars,m,inIEqns,iCache,env,iMark,markarr,iRepl);
      then
        (v,knVars,cache,repl,mark);
    case (BackendDAE.VAR(varName=cr,values=attr as SOME(DAE.VAR_ATTR_ENUMERATION(fixed=SOME(e))),source=source),_,_,_,_,_,_,_,_,_)
      equation
        (v,knVars,cache,repl,mark) = evaluateFixedAttribute1(cr,e,attr,source,var,addVar,iKnVars,m,inIEqns,iCache,env,iMark,markarr,iRepl);
      then
        (v,knVars,cache,repl,mark);
    else then (var,iKnVars,iCache,iRepl,iMark);
  end match;
end evaluateFixedAttribute;

protected function evaluateFixedAttribute1
  input DAE.ComponentRef cr;
  input DAE.Exp e;
  input Option<DAE.VariableAttributes> attr;
  input DAE.ElementSource source;
  input BackendDAE.Var var;
  input Boolean addVar;
  input BackendDAE.Variables iKnVars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input Env.Cache iCache;
  input Env.Env env;
  input Integer iMark;
  input array<Integer> markarr;
  input BackendVarTransform.VariableReplacements iRepl;
  output BackendDAE.Var oVar;
  output BackendDAE.Variables oKnVars;
  output Env.Cache oCache;
  output BackendVarTransform.VariableReplacements oRepl;
  output Integer oMark;
protected
  DAE.Exp e1;
  Boolean b;
  list<Integer> ilst;
  Option<DAE.VariableAttributes> attr1;
algorithm
   // apply replacements
  (e1,_) := BackendVarTransform.replaceExp(e, iRepl, NONE());
  ((_,(_,ilst))) := Expression.traverseExpTopDown(e1, BackendDAEUtil.traversingincidenceRowExpFinder, (iKnVars,{}));
  (oKnVars,oCache,oRepl,oMark) := evaluateSelectedParameters1(ilst,iKnVars,m,inIEqns,iCache,env,iMark,markarr,iRepl);
  (e1,_) := BackendVarTransform.replaceExp(e1, oRepl, NONE());
  (e1,_) := ExpressionSimplify.simplify(e1);
   b := Expression.isConst(e1);
   e1 := evaluateFixedAttributeReportWarning(b,cr,e,e1,source,oKnVars);
   attr1 := DAEUtil.setFixedAttr(attr,SOME(e1));
   oVar := BackendVariable.setVarAttributes(var,attr1);
   oKnVars := Debug.bcallret2(addVar,BackendVariable.addVar,oVar, oKnVars, oKnVars);
end evaluateFixedAttribute1;

protected function evaluateFixedAttributeReportWarning
  input Boolean b;
  input DAE.ComponentRef cr;
  input DAE.Exp e;
  input DAE.Exp e1;
  input DAE.ElementSource source;
  input BackendDAE.Variables knvars;
  output DAE.Exp outE;
algorithm
  outE := match(b,cr,e,e1,source,knvars)
    local
      Absyn.Info info;
      String msg;
      DAE.Exp e2;
    case (true,_,_,_,_,_) then e1;
    case (false,_,_,_,_,_)
      equation
        info = DAEUtil.getElementSourceFileInfo(source);
        ((e2, (_,_,_))) = Expression.traverseExp(e1, replaceCrefWithBindStartExp, (knvars,false,HashSet.emptyHashSet()));
        msg = ComponentReference.printComponentRefStr(cr) +& " has unevaluateable fixed attribute value \"" +& ExpressionDump.printExpStr(e) +& "\" use values from start attribute(s) \"" +& ExpressionDump.printExpStr(e2) +& "\"";
        Error.addSourceMessage(Error.COMPILER_WARNING, {msg}, info);
      then
        e2;
  end match;
end evaluateFixedAttributeReportWarning;

protected function replaceCrefWithBindStartExp
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,Boolean,HashSet.HashSet>> inTuple;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,Boolean,HashSet.HashSet>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      BackendDAE.Var v;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      Boolean b;
      HashSet.HashSet hs;
    // true if crefs replaced in expression
    case ((DAE.CREF(componentRef=cr), (vars,b,hs)))
      equation
        // check for cyclic bindings in start value
        false = BaseHashSet.has(cr, hs);
        ({v}, _) = BackendVariable.getVar(cr, vars);
        e = BackendVariable.varStartValueType(v);
        hs = BaseHashSet.add(cr,hs);
        ((e, (_,b,hs))) = Expression.traverseExp(e, replaceCrefWithBindStartExp, (vars,b,hs));
      then
        ((e, (vars,b,hs)));
    // true if crefs in expression
    case ((e as DAE.CREF(componentRef=_), (vars,_,hs)))
      then
        ((e, (vars,true,hs)));
    else then inTuple;
  end matchcontinue;
end replaceCrefWithBindStartExp;

protected function traverseParameterSorted
  input list<list<Integer>> inComps;
  input BackendDAE.Variables inKnVars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input Env.Cache iCache;
  input Env.Env env;
  input Integer iMark;
  input array<Integer> markarr;
  input BackendVarTransform.VariableReplacements repl;
  input BackendVarTransform.VariableReplacements replEvaluate;
  output BackendDAE.Variables oKnVars;
  output BackendVarTransform.VariableReplacements oRepl;
  output BackendVarTransform.VariableReplacements oReplEvaluate;
  output Env.Cache oCache;
  output Integer oMark;
algorithm
  (oKnVars,oRepl,oReplEvaluate,oCache,oMark) := match (inComps,inKnVars,m,inIEqns,iCache,env,iMark,markarr,repl,replEvaluate)
    local
      BackendDAE.Variables knvars;
      BackendDAE.Var v;
      BackendVarTransform.VariableReplacements repl1,evrepl;
      Integer i,mark;
      list<list<Integer>> rest;
      Env.Cache cache;
      list<Integer> ilst;

    case({},_,_,_,_,_,_,_,_,_)
      then
        (inKnVars,repl,replEvaluate,iCache,iMark);
    case({i}::rest,_,_,_,_,_,_,_,_,_)
      equation
        v = BackendVariable.getVarAt(inKnVars,i);
        (v,knvars,cache,repl1,mark) = evaluateFixedAttribute(v,true,inKnVars,m,inIEqns,iCache,env,iMark,markarr,repl);
        (knvars,repl1,evrepl,cache,mark) = evaluateParameterBindings(v,i,knvars,m,inIEqns,cache,env,mark,markarr,repl1,replEvaluate);
        (knvars,repl1,evrepl,cache,mark) = traverseParameterSorted(rest,knvars,m,inIEqns,cache,env,mark,markarr,repl1,evrepl);
      then
        (knvars,repl1,evrepl,cache,mark);
    case (ilst::rest,_,_,_,_,_,_,_,_,_)
      equation
        // vlst = List.map1r(ilst,BackendVariable.getVarAt,inKnVars);
        // str = stringDelimitList(List.map(vlst,BackendDump.varString),"\n");
        // print(stringAppendList({"EvaluateParameter.traverseParameterSorted faild because of strong connected Block in Parameters!\n",str,"\n"}));
        (knvars,repl1,evrepl,cache,mark) = traverseParameterSorted(List.map(ilst,List.create),inKnVars,m,inIEqns,iCache,env,iMark,markarr,repl,replEvaluate);
        (knvars,repl1,evrepl,cache,mark) = traverseParameterSorted(rest,knvars,m,inIEqns,cache,env,mark,markarr,repl1,evrepl);
      then
        (knvars,repl1,evrepl,cache,mark);
  end match;
end traverseParameterSorted;

protected function evaluateParameterBindings
  input BackendDAE.Var var;
  input Integer index;
  input BackendDAE.Variables inKnVars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input Env.Cache iCache;
  input Env.Env env;
  input Integer iMark;
  input array<Integer> markarr;
  input BackendVarTransform.VariableReplacements iRepl;
  input BackendVarTransform.VariableReplacements iReplEvaluate;
  output BackendDAE.Variables oKnVars;
  output BackendVarTransform.VariableReplacements oRepl;
  output BackendVarTransform.VariableReplacements oReplEvaluate;
  output Env.Cache oCache;
  output Integer oMark;
algorithm
  (oKnVars,oRepl,oReplEvaluate,oCache,oMark) :=
  matchcontinue(var,index,inKnVars,m,inIEqns,iCache,env,iMark,markarr,iRepl,iReplEvaluate)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      DAE.Exp e;
      Option<DAE.VariableAttributes> attr;
      BackendVarTransform.VariableReplacements repl,repleval;
      BackendDAE.Variables knVars;
    // Parameter with bind expression
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),bindExp=SOME(e),values=attr),_,_,_,_,_,_,_,_,_,_)
      equation
        // apply replacements
        (e,true) = BackendVarTransform.replaceExp(e, iReplEvaluate, NONE());
        (e,_) = ExpressionSimplify.simplify(e);
        v = BackendVariable.setBindExp(var, SOME(e));
        (repl,repleval) = addConstExpReplacement(e,cr,iRepl,iReplEvaluate);
        (attr,(repleval,_)) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,(repleval,false));
        v = BackendVariable.setVarAttributes(v,attr);
        //false = Expression.expHasCrefs(e);
        // evaluate expression
        //(cache, value,_) = Ceval.ceval(iCache, env, e, false,NONE(),Absyn.NO_MSG());
        //e1 = ValuesUtil.valueExp(value);
        // set bind value
        //v = BackendVariable.setBindExp(var, SOME(e1));
        v = Debug.bcallret2(Expression.isConst(e),BackendVariable.setVarFinal,v, true, v);
        knVars = BackendVariable.setVarAt(inKnVars,index,v);
      then
        (knVars,repl,repleval,iCache,iMark);
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),bindValue=NONE(),values=attr),_,_,_,_,_,_,_,_,_,_)
      equation
        true = BackendVariable.varFixed(var);
        e = DAEUtil.getStartAttrFail(attr);
        // apply replacements
        (e,true) = BackendVarTransform.replaceExp(e, iReplEvaluate, NONE());
        (e,_) = ExpressionSimplify.simplify(e);
        v = BackendVariable.setVarStartValue(var,e);
        (repl,repleval) = addConstExpReplacement(e,cr,iRepl,iReplEvaluate);
        (attr,(repleval,_)) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,(repleval,false));
        v = BackendVariable.setVarAttributes(v,attr);
        //false = Expression.expHasCrefs(e);
        // evaluate expression
        //(cache, value,_) = Ceval.ceval(iCache, env, e, false,NONE(),Absyn.NO_MSG());
        //e1 = ValuesUtil.valueExp(value);
        // set bind value
        //v = BackendVariable.setBindExp(var, SOME(e1));
        v = Debug.bcallret2(Expression.isConst(e),BackendVariable.setVarFinal,v, true, v);
        knVars = BackendVariable.setVarAt(inKnVars,index,v);
      then
        (knVars,repl,repleval,iCache,iMark);
    // other vars
    case (BackendDAE.VAR(bindExp=SOME(e),values=attr),_,_,_,_,_,_,_,_,_,_)
      equation
        // apply replacements
        (e,true) = BackendVarTransform.replaceExp(e, iReplEvaluate, NONE());
        (e,_) = ExpressionSimplify.simplify(e);
        v = BackendVariable.setBindExp(var, SOME(e));
        (attr,(repleval,_)) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,(iReplEvaluate,false));
        v = BackendVariable.setVarAttributes(v,attr);
        knVars = BackendVariable.setVarAt(inKnVars,index,v);
      then
        (knVars,iRepl,repleval,iCache,iMark);
    case (BackendDAE.VAR(values=attr),_,_,_,_,_,_,_,_,_,_)
      equation
        // apply replacements
        (attr,(repleval,true)) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,(iReplEvaluate,false));
        v = BackendVariable.setVarAttributes(var,attr);
        knVars = BackendVariable.setVarAt(inKnVars,index,v);
      then
        (knVars,iRepl,repleval,iCache,iMark);
    else
      then (inKnVars,iRepl,iReplEvaluate,iCache,iMark);
  end matchcontinue;
end evaluateParameterBindings;

protected function addConstExpReplacement
  input DAE.Exp inExp;
  input DAE.ComponentRef cr;
  input BackendVarTransform.VariableReplacements inRepl;
  input BackendVarTransform.VariableReplacements iReplEvaluate;
  output BackendVarTransform.VariableReplacements outRepl;
  output BackendVarTransform.VariableReplacements oReplEvaluate;
algorithm
  (outRepl,oReplEvaluate) := matchcontinue(inExp,cr,inRepl,iReplEvaluate)
    case (_,_,_,_)
      equation
        true = Expression.isConst(inExp);
        outRepl = BackendVarTransform.addReplacement(inRepl, cr, inExp,NONE());
        oReplEvaluate = BackendVarTransform.addReplacement(iReplEvaluate, cr, inExp,NONE());
      then
        (outRepl,oReplEvaluate);
    else
      (inRepl,iReplEvaluate);
  end matchcontinue;
end addConstExpReplacement;

protected function traverseExpVisitorWrapper "help function to replaceFinalVarTraverser"
  input tuple<DAE.Exp,tuple<BackendVarTransform.VariableReplacements,Boolean>> inTpl;
  output tuple<DAE.Exp,tuple<BackendVarTransform.VariableReplacements,Boolean>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local
    DAE.Exp exp;
    BackendVarTransform.VariableReplacements repl;
    DAE.ComponentRef cr;
    Boolean b,b1;
    case((exp as DAE.CREF(componentRef=_),(repl,b))) equation
      (exp,b1) = BackendVarTransform.replaceExp(exp,repl,NONE());
    then ((exp,(repl,b or b1)));
    else then inTpl;
  end matchcontinue;
end traverseExpVisitorWrapper;


protected function replaceEvaluatedParametersSystem
"author Frenkel TUD"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Variables,BackendDAE.IncidenceMatrix,BackendDAE.EquationArray,Env.Cache,Env.Env,Integer,array<Integer>,BackendVarTransform.VariableReplacements,BackendVarTransform.VariableReplacements> inTypeA;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Variables,BackendDAE.IncidenceMatrix,BackendDAE.EquationArray,Env.Cache,Env.Env,Integer,array<Integer>,BackendVarTransform.VariableReplacements,BackendVarTransform.VariableReplacements> outTypeA;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrixT> mT;
  BackendDAE.Matching matching;
  BackendDAE.StateSets stateSets;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,m=m,mT=mT,matching=matching,stateSets=stateSets) := isyst;
  (vars,outTypeA) := BackendVariable.traverseBackendDAEVarsWithUpdate(vars,replaceEvaluatedParameterTraverser,inTypeA);
  osyst := BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching,stateSets);
end replaceEvaluatedParametersSystem;

protected function replaceEvaluatedParameterTraverser
"author: Frenkel TUD 2011-04"
 input tuple<BackendDAE.Var, tuple<BackendDAE.Variables,BackendDAE.IncidenceMatrix,BackendDAE.EquationArray,Env.Cache,Env.Env,Integer,array<Integer>,BackendVarTransform.VariableReplacements,BackendVarTransform.VariableReplacements>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendDAE.Variables,BackendDAE.IncidenceMatrix,BackendDAE.EquationArray,Env.Cache,Env.Env,Integer,array<Integer>,BackendVarTransform.VariableReplacements,BackendVarTransform.VariableReplacements>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Variables knVars;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.EquationArray ieqns;
      Env.Cache cache;
      Env.Env env;
      Integer mark;
      array<Integer> markarr;
      BackendVarTransform.VariableReplacements repl;
      BackendVarTransform.VariableReplacements replEvaluate;
      BackendDAE.Var v;
      DAE.Exp e,e1;
      DAE.ComponentRef cr;
      Option<DAE.VariableAttributes> attr;
      Boolean b;
    case ((v as BackendDAE.VAR(varName=_,bindExp=SOME(e),values=attr),(knVars,m,ieqns,cache,env,mark,markarr,repl,replEvaluate)))
      equation
        // apply replacements
        (e1,true) = BackendVarTransform.replaceExp(e, replEvaluate, NONE());
        (e1,_) = ExpressionSimplify.simplify(e1);
        v = BackendVariable.setBindExp(v, SOME(e1));
        (attr,(replEvaluate,b)) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,(replEvaluate,false));
        v = Debug.bcallret2(b,BackendVariable.setVarAttributes,v,attr,v);
        (v,knVars,cache,repl,mark) = evaluateFixedAttribute(v,false,knVars,m,ieqns,cache,env,mark,markarr,repl);
      then ((v,(knVars,m,ieqns,cache,env,mark,markarr,repl,replEvaluate)));

    case  ((v as BackendDAE.VAR(values=attr),(knVars,m,ieqns,cache,env,mark,markarr,repl,replEvaluate)))
      equation
        // apply replacements
        (attr,(replEvaluate,true)) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,(replEvaluate,false));
        v = BackendVariable.setVarAttributes(v,attr);
        (v,knVars,cache,repl,mark) = evaluateFixedAttribute(v,false,knVars,m,ieqns,cache,env,mark,markarr,repl);
      then ((v,(knVars,m,ieqns,cache,env,mark,markarr,repl,replEvaluate)));

    case  ((v,(knVars,m,ieqns,cache,env,mark,markarr,repl,replEvaluate)))
      equation
        (v,knVars,cache,repl,mark) = evaluateFixedAttribute(v,false,knVars,m,ieqns,cache,env,mark,markarr,repl);
      then ((v,(knVars,m,ieqns,cache,env,mark,markarr,repl,replEvaluate)));
  end matchcontinue;
end replaceEvaluatedParameterTraverser;

protected function replaceEvaluatedParametersEqns
"author Frenkel TUD"
  input Boolean replacementsEmpty;
  input BackendDAE.BackendDAE inDAE;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match (replacementsEmpty,inDAE,repl)
    local
      DAE.FunctionTree funcs;
      BackendDAE.Variables knvars,exobj,av;
      BackendDAE.EquationArray remeqns,inieqns;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.BackendDAEType btp;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      Boolean b;
      BackendDAE.ExtraInfo ei;
    
    // do nothing if there are no replacements
    case (true,_,_) then inDAE;
    
    case (false,BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs,ei)),_)
      equation
        // do replacements in initial equations
        eqnslst = BackendEquation.equationList(inieqns);
        (eqnslst,b) = BackendVarTransform.replaceEquations(eqnslst, repl,NONE());
        inieqns = Debug.bcallret1(b,BackendEquation.listEquation,eqnslst,inieqns);
        // do replacements in simple equations
        eqnslst = BackendEquation.equationList(remeqns);
        (eqnslst,b) = BackendVarTransform.replaceEquations(eqnslst, repl,NONE());
        remeqns = Debug.bcallret1(b,BackendEquation.listEquation,eqnslst,remeqns);
        // do replacements in systems
        systs = List.map1(systs,replaceEvaluatedParametersSystemEqns,repl);
      then
        BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs,ei));
  
  end match;
end replaceEvaluatedParametersEqns;

protected function replaceEvaluatedParametersSystemEqns
"author Frenkel TUD
  replace the evaluated parameters in the equationsystems"
  input BackendDAE.EqSystem isyst;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.EqSystem osyst;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns,eqns1;
  list<BackendDAE.Equation> eqns_1,lsteqns;
  Boolean b;
  BackendDAE.StateSets stateSets;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,stateSets=stateSets) := isyst;
  lsteqns := BackendEquation.equationList(eqns);
  (eqns_1,b) := BackendVarTransform.replaceEquations(lsteqns, repl,NONE());
  eqns1 := Debug.bcallret1(b, BackendEquation.listEquation,eqns_1,eqns);
  osyst := Util.if_(b,BackendDAE.EQSYSTEM(vars,eqns1,NONE(),NONE(),BackendDAE.NO_MATCHING(),stateSets),isyst);
end replaceEvaluatedParametersSystemEqns;

end EvaluateParameter;
