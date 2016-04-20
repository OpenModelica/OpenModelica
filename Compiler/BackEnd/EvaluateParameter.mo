/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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
              - evaluate and replace parameters with final=true or annotation(Evaluate=true) in equations, variables and parameters"



public import Absyn;
public import BackendDAE;
public import DAE;
public import FCore;

protected import Array;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import BackendVarTransform;
protected import BaseHashTable;
protected import BaseHashSet;
protected import Ceval;
protected import ComponentReference;
protected import ElementSource;
protected import Error;
protected import EvaluateFunctions;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import HashSet;
protected import List;
protected import Sorting;
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
  (outDAE,_ ) := evaluateParameters(inDAE,BackendVariable.isFinalOrProtectedVar);
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
  (outDAE,repl) := evaluateParameters(inDAE,BackendVariable.isFinalOrProtectedVar);

  if not BackendVarTransform.isReplacementEmpty(repl) then
    outDAE := replaceEvaluatedParametersEqns(outDAE, repl);
  end if;
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

  if not BackendVarTransform.isReplacementEmpty(repl) then
    outDAE := replaceEvaluatedParametersEqns(outDAE, repl);
  end if;
end evaluateReplaceEvaluateParameters;

public function evaluateReplaceFinalEvaluateParameters "author: Frenkel TUD
  Evaluates and replaces parameters with final=true in variables and parameters."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendVarTransform.VariableReplacements repl;
algorithm
  (outDAE,repl) := evaluateParameters(inDAE,BackendVariable.hasVarEvaluateAnnotationOrFinal);

  if not BackendVarTransform.isReplacementEmpty(repl) then
    outDAE := replaceEvaluatedParametersEqns(outDAE, repl);
  end if;
end evaluateReplaceFinalEvaluateParameters;

public function evaluateReplaceProtectedFinalEvaluateParameters "author: Frenkel TUD
  Evaluates and replaces parameters with final=true in variables and parameters."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendVarTransform.VariableReplacements repl;
algorithm
  (outDAE,repl) := evaluateParameters(inDAE,BackendVariable.hasVarEvaluateAnnotationOrFinalOrProtected);

  if not BackendVarTransform.isReplacementEmpty(repl) then
    outDAE := replaceEvaluatedParametersEqns(outDAE, repl);
  end if;
end evaluateReplaceProtectedFinalEvaluateParameters;

public function evaluateAllParameters "author: waurich
Evaluates all parameters and replaces them with their value, if possible."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendVarTransform.VariableReplacements repl;
algorithm
  (outDAE, repl) := evaluateParameters(inDAE, BackendVariable.isParam);
  if not BackendVarTransform.isReplacementEmpty(repl) then
    //BackendVarTransform.dumpReplacements(repl);
    outDAE := replaceEvaluatedParametersEqns(outDAE, repl);
  end if;
end evaluateAllParameters;

/*
 * protected section
 *
 */

protected function evaluateParameters "author Frenkel TUD
  Evaluate and replace parameters with annotation(Evaluate=true) in variables and parameters."
  input BackendDAE.BackendDAE inDAE;
  input selectParameterFunc selectParameterfunc;
  output BackendDAE.BackendDAE outDAE;
  output BackendVarTransform.VariableReplacements oRepl;
protected
  BackendDAE.Variables knvars, av;
  BackendDAE.EquationArray inieqns;
  FCore.Cache cache;
  FCore.Graph graph;
  BackendVarTransform.VariableReplacements repl, repleval;
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
  list<list<Integer>> comps;
  array<Integer> ass2, markarr;
  Integer size,mark,nselect;
  BackendDAE.IncidenceMatrixT m;
  BackendDAE.IncidenceMatrixT mt;
  list<Integer> selectedParameter;
algorithm
  (outDAE, oRepl) := match inDAE
    case BackendDAE.DAE ( systs,
                          shared as BackendDAE.SHARED(knownVars=knvars, aliasVars=av, initialEqs=inieqns, cache=cache, graph=graph) )
      algorithm
        // get parameters with annotation(Evaluate=true)
        size := BackendVariable.varsSize(knvars);
        m := arrayCreate(size, {});
        mt := arrayCreate(size, {});
        ass2 := arrayCreate(size, -1);
        ((_, _, _, selectedParameter, nselect, ass2, m, mt)) :=
            BackendVariable.traverseBackendDAEVars( knvars, getParameterIncidenceMatrix,
                                                    (knvars, 1, selectParameterfunc, {}, 0, ass2, m, mt) );

        // evaluate selected parameters
        size := intMax(BaseHashTable.defaultBucketSize, realInt(realMul(intReal(size), 0.7)));
        nselect := intMax(BaseHashTable.defaultBucketSize, nselect*2);
        repl := BackendVarTransform.emptyReplacementsSized(size);
        repleval := BackendVarTransform.emptyReplacementsSized(nselect);
        markarr := arrayCreate(size, -1);
        (knvars, cache, repl, repleval, mark) :=
            evaluateSelectedParameters(selectedParameter, knvars, m, inieqns, cache, graph, markarr, repl, repleval, 1);

        // replace evaluated parameter in parameters
        comps := Sorting.TarjanTransposed(mt, ass2);

        // evaluate vars with bind expression consists of evaluated vars
        (knvars, repl, repleval, cache, mark) :=
            traverseParameterSorted(comps, knvars, m, inieqns, cache, graph, mark, markarr, repl, repleval);
        if Flags.isSet(Flags.DUMP_EA_REPL) then
          BackendVarTransform.dumpReplacements(repleval);
        end if;

        // replace evaluated parameter in variables
        (systs, (knvars, m, inieqns, cache, graph, mark, markarr, repl, repleval)) :=
            List.mapFold( systs, replaceEvaluatedParametersSystem, ( knvars, m, inieqns, cache, graph, mark,
                                                                     markarr, repl, repleval ) );
        (av, _) := BackendVariable.traverseBackendDAEVarsWithUpdate (
            av, replaceEvaluatedParameterTraverser, (knvars, m, inieqns, cache, graph, mark, markarr, repl, repleval) );

        shared.knownVars := knvars;
        shared.aliasVars := av;
        shared.initialEqs := inieqns;
        shared.graph := graph;
        shared.cache := cache;
      then (BackendDAE.DAE(systs, shared), repleval);
  end match;
end evaluateParameters;


protected function getParameterIncidenceMatrix
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.Variables,Integer,selectParameterFunc,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrix,BackendDAE.IncidenceMatrixT> inTpl;
  output BackendDAE.Var outVar;
  output tuple<BackendDAE.Variables,Integer,selectParameterFunc,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrix,BackendDAE.IncidenceMatrixT> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
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

    case (v as BackendDAE.VAR(varKind=BackendDAE.PARAM(),bindExp=SOME(e)),(knvars,index,selectParameter,selectedParameter,nselect,ass,m,mt))
      equation
        (_,(_,ilst)) = Expression.traverseExpTopDown(e, BackendDAEUtil.traversingincidenceRowExpFinder, (knvars,{}));
        select = selectParameter(v);
        selectedParameter = List.consOnTrue(select, index, selectedParameter);
        ass = arrayUpdate(ass,index,index);
        m = arrayUpdate(m,index,ilst);
        mt = List.fold1(index::ilst,Array.consToElement,index,mt);
      then (v,(knvars,index+1,selectParameter,selectedParameter,nselect,ass,m,mt));

    case (v as BackendDAE.VAR(varKind=BackendDAE.PARAM(),values=attr),(knvars,index,selectParameter,selectedParameter,nselect,ass,m,mt))
      equation
        e = DAEUtil.getStartAttrFail(attr);
        (_,(_,ilst)) = Expression.traverseExpTopDown(e, BackendDAEUtil.traversingincidenceRowExpFinder, (knvars,{}));
        select = selectParameter(v);
        selectedParameter = List.consOnTrue(select, index, selectedParameter);
        ass = arrayUpdate(ass,index,index);
        m = arrayUpdate(m,index,ilst);
        mt = List.fold1(index::ilst,Array.consToElement,index,mt);
      then (v,(knvars,index+1,selectParameter,selectedParameter,nselect,ass,m,mt));

    case (v,(knvars,index,selectParameter,selectedParameter,nselect,ass,m,mt))
      equation
        select = selectParameter(v);
        selectedParameter = List.consOnTrue(select, index, selectedParameter);
        ass = arrayUpdate(ass,index,index);
        ilst = {index};
        mt = arrayUpdate(mt,index,ilst);
      then (v,(knvars,index+1,selectParameter,selectedParameter,nselect,ass,m,mt));
  end matchcontinue;
end getParameterIncidenceMatrix;


protected function evaluateSelectedParameters
"author Frenkel TUD"
  input list<Integer> iSelected;
  input output BackendDAE.Variables knVars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input output FCore.Cache cache;
  input FCore.Graph graph;
  input array<Integer> markarr;
  input output BackendVarTransform.VariableReplacements repl;
  input output BackendVarTransform.VariableReplacements replEvaluate;
  input output Integer mark;
algorithm
  for i in iSelected loop
    (knVars,cache,repl,replEvaluate,mark) := evaluateSelectedParameters0(i,knVars,m,inIEqns,cache,graph,markarr,repl,replEvaluate,mark);
   end for;
end evaluateSelectedParameters;

protected function evaluateSelectedParameters0
"author Frenkel TUD"
  input Integer i;
  input output BackendDAE.Variables knVars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input output FCore.Cache cache;
  input FCore.Graph graph;
  input array<Integer> markarr;
  input output BackendVarTransform.VariableReplacements repl;
  input output BackendVarTransform.VariableReplacements replEvaluate;
  input output Integer mark;
protected
  BackendDAE.Var v;
algorithm
  try
    false := intGt(markarr[i],0) "not allready evaluated";
    arrayUpdate(markarr,i,mark);
    // evaluate needed parameters
    (knVars,cache,mark,repl) := evaluateSelectedParameters1(m[i],knVars,m,inIEqns,cache,graph,mark,markarr,repl);
    // evaluate parameter
    v := BackendVariable.getVarAt(knVars,i);
    (v,knVars,cache,mark,repl) := evaluateFixedAttribute(v,true,knVars,m,inIEqns,cache,graph,mark,markarr,repl);
    (knVars,cache,repl,replEvaluate) := evaluateSelectedParameter(v,i,knVars,inIEqns,repl,replEvaluate,cache,graph);
  else
    // evaluate parameter
    v := BackendVariable.getVarAt(knVars,i);
    (knVars,cache,repl,replEvaluate) := evaluateSelectedParameter(v,i,knVars,inIEqns,repl,replEvaluate,cache,graph);
  end try;
end evaluateSelectedParameters0;

protected function evaluateSelectedParameters1
"author Frenkel TUD"
  input list<Integer> iUsed;
  input output BackendDAE.Variables knVars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input output FCore.Cache cache;
  input FCore.Graph graph;
  input output Integer mark;
  input array<Integer> markarr;
  input output BackendVarTransform.VariableReplacements repl;
algorithm
  (knVars,cache,mark,repl) := matchcontinue(iUsed,knVars,m,inIEqns,cache,graph,mark,markarr,repl)
    local
      Integer i;
      list<Integer> rest;
      BackendDAE.Var v;
    case ({},_,_,_,_,_,_,_,_)
      then (knVars,cache,mark,repl);
    case (i::rest,_,_,_,_,_,_,_,_)
      equation
        false = intGt(markarr[i],0) "not allready evaluated";
        arrayUpdate(markarr,i,mark);
        (knVars,cache,mark,repl) = evaluateSelectedParameters1(m[i],knVars,m,inIEqns,cache,graph,mark,markarr,repl);
        v = BackendVariable.getVarAt(knVars,i);
        (v,knVars,cache,mark,repl) = evaluateFixedAttribute(v,true,knVars,m,inIEqns,cache,graph,mark,markarr,repl);
        (knVars,cache,repl) = evaluateParameter(v,knVars,inIEqns,cache,graph,repl);
        (knVars,cache,mark,repl) = evaluateSelectedParameters1(rest,knVars,m,inIEqns,cache,graph,mark,markarr,repl);
      then
        (knVars,cache,mark,repl);
    case (_::rest,_,_,_,_,_,_,_,_)
      equation
        (knVars,cache,mark,repl) = evaluateSelectedParameters1(rest,knVars,m,inIEqns,cache,graph,mark,markarr,repl);
      then
        (knVars,cache,mark,repl);
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
  input FCore.Cache iCache;
  input FCore.Graph graph;
  output BackendDAE.Variables oKnVars;
  output FCore.Cache oCache;
  output BackendVarTransform.VariableReplacements oRepl;
  output BackendVarTransform.VariableReplacements oReplEvaluate;
algorithm
  (oKnVars,oCache,oRepl,oReplEvaluate) := matchcontinue(var,index,inKnVars,inIEqns,iRepl,iReplEvaluate,iCache,graph)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      DAE.Exp e,e1;
      Option<DAE.VariableAttributes> attr;
      BackendVarTransform.VariableReplacements repl,repleval;
      FCore.Cache cache;
      Values.Value value;
      BackendDAE.Variables knvars;
      SourceInfo info;
      String msg;
    // Parameter with evaluate=true
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.CONST(),bindExp=SOME(e)),_,_,_,_,_,_,_)
      equation
        true = Expression.isConst(e);
        // save replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr, e, NONE());
        repleval = BackendVarTransform.addReplacement(iReplEvaluate, cr, e ,NONE());
        //  print("Evaluate Selected " + BackendDump.varString(var) + "\n->    " + BackendDump.varString(v) + "\n");
      then
        (inKnVars,iCache,repl,repleval);
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.CONST(),bindExp=SOME(e)),_,_,_,_,_,_,_)
      equation
        // apply replacements
        (e1,_) = BackendVarTransform.replaceExp(e, iRepl, NONE());
        // evaluate expression
        (cache, value,_) = Ceval.ceval(iCache, graph, e1, false, NONE(), Absyn.NO_MSG(),0);
        e1 = ValuesUtil.valueExp(value);
        // set bind value
        v = BackendVariable.setBindExp(var, SOME(e1));
        // update Vararray
        knvars = BackendVariable.setVarAt(inKnVars, index, v);
        // save replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr, e1, NONE());
        repleval = BackendVarTransform.addReplacement(iReplEvaluate, cr, e1 ,NONE());
        //  print("Evaluate Selected " + BackendDump.varString(var) + "\n->    " + BackendDump.varString(v) + "\n");
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
        //  print("Evaluate Selected " + BackendDump.varString(var) + "\n->    " + BackendDump.varString(v) + "\n");
      then
        (knvars,iCache,repl,repleval);
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),bindExp=SOME(e)),_,_,_,_,_,_,_)
      equation
        // apply replacements
        (e1,_) = BackendVarTransform.replaceExp(e, iRepl, NONE());
        // evaluate expression
        (cache, value,_) = Ceval.ceval(iCache, graph, e1, false, NONE(), Absyn.NO_MSG(),0);
        e1 = ValuesUtil.valueExp(value);
        // set bind value
        v = BackendVariable.setBindExp(var, SOME(e1));
        v = BackendVariable.setVarFinal(v, true);
        // update Vararray
        knvars = BackendVariable.setVarAt(inKnVars, index, v);
        // save replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr, e1, NONE());
        repleval = BackendVarTransform.addReplacement(iReplEvaluate, cr, e1 ,NONE());
        //  print("Evaluate Selected " + BackendDump.varString(var) + "\n->    " + BackendDump.varString(v) + "\n");
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
        //  print("Evaluate Selected " + BackendDump.varString(var) + "\n->    " + BackendDump.varString(v) + "\n");
      then
        (knvars,iCache,repl,repleval);

    //waurich: if there is unevaluated binding, dont take the start value as a binding replacement. compute the unevaluated binding!
    case (BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),values=attr),_,_,_,_,_,_,_)
      equation
        true = BackendVariable.varFixed(var);
        false = BackendVariable.varHasBindExp(var);
        e = DAEUtil.getStartAttrFail(attr);
        // apply replacements
        (e1,_) = BackendVarTransform.replaceExp(e, iRepl, NONE());
        // evaluate expression
        (cache, value,_) = Ceval.ceval(iCache, graph, e1, false, NONE(), Absyn.NO_MSG(),0);
        e1 = ValuesUtil.valueExp(value);
        // set bind value
        v = BackendVariable.setVarStartValue(var,e1);
        v = BackendVariable.setVarFinal(v, true);
        // update Vararray
        knvars = BackendVariable.setVarAt(inKnVars, index, v);
        // save replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr, e1, NONE());
        repleval = BackendVarTransform.addReplacement(iReplEvaluate, cr, e1, NONE());
        //  print("Evaluate Selected " + BackendDump.varString(var) + "\n->    " + BackendDump.varString(v) + "\n");
      then
        (knvars,cache,repl,repleval);
    // try to evaluate with initial equations

    // report warning
    case(_,_,_,_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.PEDANTIC);
        info = ElementSource.getElementSourceFileInfo(BackendVariable.getVarSource(var));
        msg = "Cannot evaluate Variable \"" + BackendDump.varString(var);
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
  input output BackendDAE.Variables knVars;
  input BackendDAE.EquationArray inIEqns;
  input output FCore.Cache cache;
  input FCore.Graph graph;
  input output BackendVarTransform.VariableReplacements repl;
algorithm
  (knVars,cache,repl) := matchcontinue var
    local
      DAE.ComponentRef cr;
      DAE.Exp e,e1;
      Option<DAE.VariableAttributes> attr;
      Values.Value value;
    case BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),bindExp=SOME(e))
      equation
        // applay replacements
        (e,_) = BackendVarTransform.replaceExp(e, repl, NONE());
        // evaluate expression
        (cache, value,_) = Ceval.ceval(cache, graph, e, false, NONE(), Absyn.NO_MSG(), 0);
        e1 = ValuesUtil.valueExp(value);
        // save replacement
        repl = BackendVarTransform.addReplacement(repl, cr, e1, NONE());
        //  print("Evaluate " + BackendDump.varString(var) + "\n->    " + ExpressionDump.printExpStr(e1) + "\n");
      then
        (knVars,cache,repl);
    case BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),bindValue=SOME(value))
      equation
        true = BackendVariable.varFixed(var);
        e = ValuesUtil.valueExp(value);
        // save replacement
        repl = BackendVarTransform.addReplacement(repl, cr, e, NONE());
        //  print("Evaluate " + BackendDump.varString(var) + "\n->    " + ExpressionDump.printExpStr(e) + "\n");
      then
        (knVars,cache,repl);
    case BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),values=attr)
      equation
        true = BackendVariable.varFixed(var);
        e = DAEUtil.getStartAttrFail(attr);
        // applay replacements
        (e,_) = BackendVarTransform.replaceExp(e, repl, NONE());
        // evaluate expression
        (cache, value,_) = Ceval.ceval(cache, graph, e, false, NONE(), Absyn.NO_MSG(),0);
        e1 = ValuesUtil.valueExp(value);
        // save replacement
        repl = BackendVarTransform.addReplacement(repl, cr, e1, NONE());
        //  print("Evaluate " + BackendDump.varString(var) + "\n->    " + ExpressionDump.printExpStr(e1) + "\n");
      then
        (knVars,cache,repl);
    // try to evaluate with initial equations

    // not evaluated
    else (knVars,cache,repl);
  end matchcontinue;
end evaluateParameter;


protected function evaluateFixedAttribute
  input output BackendDAE.Var var;
  input Boolean addVar;
  input output BackendDAE.Variables knVars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input output FCore.Cache cache;
  input FCore.Graph graph;
  input output Integer mark;
  input array<Integer> markarr;
  input output BackendVarTransform.VariableReplacements repl;
algorithm
  (var,knVars,cache,mark,repl) := match(var,addVar,knVars,m,inIEqns,cache,graph,mark,markarr,repl)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
      Option<DAE.VariableAttributes> attr;
      BackendDAE.Var v;
      DAE.ElementSource source;
    case (BackendDAE.VAR(values= NONE()),_,_,_,_,_,_,_,_,_)
      then
        (var,knVars,cache,mark,repl);
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_REAL(fixed=SOME(DAE.BCONST(_))))),_,_,_,_,_,_,_,_,_)
      then
        (var,knVars,cache,mark,repl);
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_INT(fixed=SOME(DAE.BCONST(_))))),_,_,_,_,_,_,_,_,_)
      then
        (var,knVars,cache,mark,repl);
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_BOOL(fixed=SOME(DAE.BCONST(_))))),_,_,_,_,_,_,_,_,_)
      then
        (var,knVars,cache,mark,repl);
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_ENUMERATION(fixed=SOME(DAE.BCONST(_))))),_,_,_,_,_,_,_,_,_)
      then
        (var,knVars,cache,mark,repl);
    case (BackendDAE.VAR(varName=cr,values=attr as SOME(DAE.VAR_ATTR_REAL(fixed=SOME(e))),source=source),_,_,_,_,_,_,_,_,_)
      equation
        (var,knVars,cache,mark,repl) = evaluateFixedAttribute1(cr,e,attr,source,var,addVar,knVars,m,inIEqns,cache,graph,mark,markarr,repl);
      then
        (var,knVars,cache,mark,repl);
    case (BackendDAE.VAR(varName=cr,values=attr as SOME(DAE.VAR_ATTR_INT(fixed=SOME(e))),source=source),_,_,_,_,_,_,_,_,_)
      equation
        (var,knVars,cache,mark,repl) = evaluateFixedAttribute1(cr,e,attr,source,var,addVar,knVars,m,inIEqns,cache,graph,mark,markarr,repl);
      then
        (var,knVars,cache,mark,repl);
    case (BackendDAE.VAR(varName=cr,values=attr as SOME(DAE.VAR_ATTR_BOOL(fixed=SOME(e))),source=source),_,_,_,_,_,_,_,_,_)
      equation
        (var,knVars,cache,mark,repl) = evaluateFixedAttribute1(cr,e,attr,source,var,addVar,knVars,m,inIEqns,cache,graph,mark,markarr,repl);
      then
        (var,knVars,cache,mark,repl);
    case (BackendDAE.VAR(varName=cr,values=attr as SOME(DAE.VAR_ATTR_ENUMERATION(fixed=SOME(e))),source=source),_,_,_,_,_,_,_,_,_)
      equation
        (var,knVars,cache,mark,repl) = evaluateFixedAttribute1(cr,e,attr,source,var,addVar,knVars,m,inIEqns,cache,graph,mark,markarr,repl);
      then
        (var,knVars,cache,mark,repl);
    else (var,knVars,cache,mark,repl);
  end match;
end evaluateFixedAttribute;

protected function evaluateFixedAttribute1
  input DAE.ComponentRef cr;
  input DAE.Exp e;
  input Option<DAE.VariableAttributes> attr;
  input DAE.ElementSource source;
  input output BackendDAE.Var var;
  input Boolean addVar;
  input output BackendDAE.Variables knVars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input output FCore.Cache cache;
  input FCore.Graph graph;
  input output Integer mark;
  input array<Integer> markarr;
  input output BackendVarTransform.VariableReplacements repl;
protected
  DAE.Exp e1;
  Boolean b;
  list<Integer> ilst;
  Option<DAE.VariableAttributes> attr1;
algorithm
   // apply replacements
  (e1,_) := BackendVarTransform.replaceExp(e, repl, NONE());
  (_,(_,ilst)) := Expression.traverseExpTopDown(e1, BackendDAEUtil.traversingincidenceRowExpFinder, (knVars,{}));
  (knVars,cache,mark,repl) := evaluateSelectedParameters1(ilst,knVars,m,inIEqns,cache,graph,mark,markarr,repl);
  (e1,_) := BackendVarTransform.replaceExp(e1, repl, NONE());
  (e1,_) := ExpressionSimplify.simplify(e1);
   b := Expression.isConst(e1);
   e1 := evaluateFixedAttributeReportWarning(b,cr,e,e1,source,knVars);
   attr1 := DAEUtil.setFixedAttr(attr,SOME(e1));
   var := BackendVariable.setVarAttributes(var,attr1);
   knVars := if addVar then BackendVariable.addVar(var, knVars) else knVars;
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
      SourceInfo info;
      String msg;
      DAE.Exp e2;
    case (true,_,_,_,_,_) then e1;
    case (false,_,_,_,_,_)
      equation
        info = ElementSource.getElementSourceFileInfo(source);
        (e2, (_,_,_)) = Expression.traverseExpBottomUp(e1, replaceCrefWithBindStartExp, (knvars,false,HashSet.emptyHashSet()));
        msg = ComponentReference.printComponentRefStr(cr) + " has unevaluateable fixed attribute value \"" + ExpressionDump.printExpStr(e) + "\" use values from start attribute(s) \"" + ExpressionDump.printExpStr(e2) + "\"";
        Error.addSourceMessage(Error.COMPILER_WARNING, {msg}, info);
      then
        e2;
  end match;
end evaluateFixedAttributeReportWarning;

protected function replaceCrefWithBindStartExp
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,Boolean,HashSet.HashSet> inTuple;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables,Boolean,HashSet.HashSet> outTuple;
algorithm
  (outExp,outTuple) := matchcontinue (inExp,inTuple)
    local
      DAE.Exp e;
      BackendDAE.Var v;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      Boolean b;
      HashSet.HashSet hs;
    // true if crefs replaced in expression
    case (DAE.CREF(componentRef=cr), (vars,b,hs))
      equation
        // check for cyclic bindings in start value
        false = BaseHashSet.has(cr, hs);
        (v, _) = BackendVariable.getVarSingle(cr, vars);
        e = BackendVariable.varStartValueType(v);
        hs = BaseHashSet.add(cr,hs);
        (e, (_,b,hs)) = Expression.traverseExpBottomUp(e, replaceCrefWithBindStartExp, (vars,b,hs));
      then (e, (vars,b,hs));
    // true if crefs in expression
    case (e as DAE.CREF(), (vars,_,hs))
      then (e, (vars,true,hs));
    else (inExp,inTuple);
  end matchcontinue;
end replaceCrefWithBindStartExp;

protected function traverseParameterSorted
  input list<list<Integer>> inComps;
  input BackendDAE.Variables inKnVars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input FCore.Cache iCache;
  input FCore.Graph graph;
  input Integer iMark;
  input array<Integer> markarr;
  input BackendVarTransform.VariableReplacements repl;
  input BackendVarTransform.VariableReplacements replEvaluate;
  output BackendDAE.Variables oKnVars;
  output BackendVarTransform.VariableReplacements oRepl;
  output BackendVarTransform.VariableReplacements oReplEvaluate;
  output FCore.Cache oCache;
  output Integer oMark;
algorithm
  (oKnVars,oRepl,oReplEvaluate,oCache,oMark) := match (inComps,inKnVars,m,inIEqns,iCache,graph,iMark,markarr,repl,replEvaluate)
    local
      BackendDAE.Variables knvars;
      BackendDAE.Var v;
      BackendVarTransform.VariableReplacements repl1,evrepl;
      Integer i,mark;
      list<list<Integer>> rest;
      FCore.Cache cache;
      list<Integer> ilst;

    case({},_,_,_,_,_,_,_,_,_)
      then
        (inKnVars,repl,replEvaluate,iCache,iMark);
    case({i}::rest,_,_,_,_,_,_,_,_,_)
      equation
        v = BackendVariable.getVarAt(inKnVars,i);
        (v,knvars,cache,mark,repl1) = evaluateFixedAttribute(v,true,inKnVars,m,inIEqns,iCache,graph,iMark,markarr,repl);
        (knvars,repl1,evrepl,cache,mark) = evaluateParameterBindings(v,i,knvars,m,inIEqns,cache,graph,mark,markarr,repl1,replEvaluate);
        (knvars,repl1,evrepl,cache,mark) = traverseParameterSorted(rest,knvars,m,inIEqns,cache,graph,mark,markarr,repl1,evrepl);
      then
        (knvars,repl1,evrepl,cache,mark);
    case (ilst::rest,_,_,_,_,_,_,_,_,_)
      equation
        // vlst = List.map1r(ilst,BackendVariable.getVarAt,inKnVars);
        // str = stringDelimitList(List.map(vlst,BackendDump.varString),"\n");
        // print(stringAppendList({"EvaluateParameter.traverseParameterSorted faild because of strong connected Block in Parameters!\n",str,"\n"}));
        (knvars,repl1,evrepl,cache,mark) = traverseParameterSorted(List.map(ilst,List.create),inKnVars,m,inIEqns,iCache,graph,iMark,markarr,repl,replEvaluate);
        (knvars,repl1,evrepl,cache,mark) = traverseParameterSorted(rest,knvars,m,inIEqns,cache,graph,mark,markarr,repl1,evrepl);
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
  input FCore.Cache iCache;
  input FCore.Graph graph;
  input Integer iMark;
  input array<Integer> markarr;
  input BackendVarTransform.VariableReplacements iRepl;
  input BackendVarTransform.VariableReplacements iReplEvaluate;
  output BackendDAE.Variables oKnVars;
  output BackendVarTransform.VariableReplacements oRepl;
  output BackendVarTransform.VariableReplacements oReplEvaluate;
  output FCore.Cache oCache;
  output Integer oMark;
algorithm
  (oKnVars,oRepl,oReplEvaluate,oCache,oMark) :=
  matchcontinue(var,index,inKnVars,m,inIEqns,iCache,graph,iMark,markarr,iRepl,iReplEvaluate)
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
         e = EvaluateFunctions.evaluateConstantFunctionCallExp(e,FCore.getFunctionTree(iCache));
        v = BackendVariable.setBindExp(var, SOME(e));
        (repl,repleval) = addConstExpReplacement(e,cr,iRepl,iReplEvaluate);
        (attr,(repleval,_)) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,(repleval,false));
        v = BackendVariable.setVarAttributes(v,attr);
        //false = Expression.expHasCrefs(e);
        // evaluate expression
        //(cache, value,_) = Ceval.ceval(iCache, graph, e, false,NONE(),Absyn.NO_MSG());
        //e1 = ValuesUtil.valueExp(value);
        // set bind value
        //v = BackendVariable.setBindExp(var, SOME(e1));
        v = if Expression.isConst(e) then BackendVariable.setVarFinal(v, true) else v;
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
        e = EvaluateFunctions.evaluateConstantFunctionCallExp(e,FCore.getFunctionTree(iCache));
        v = BackendVariable.setVarStartValue(var,e);
        (repl,repleval) = addConstExpReplacement(e,cr,iRepl,iReplEvaluate);
        (attr,(repleval,_)) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,(repleval,false));
        v = BackendVariable.setVarAttributes(v,attr);
        //false = Expression.expHasCrefs(e);
        // evaluate expression
        //(cache, value,_) = Ceval.ceval(iCache, graph, e, false,NONE(),Absyn.NO_MSG());
        //e1 = ValuesUtil.valueExp(value);
        // set bind value
        //v = BackendVariable.setBindExp(var, SOME(e1));
        v = if Expression.isConst(e) then BackendVariable.setVarFinal(v, true) else v;
        knVars = BackendVariable.setVarAt(inKnVars,index,v);
      then
        (knVars,repl,repleval,iCache,iMark);
    // other vars
    case (BackendDAE.VAR(bindExp=SOME(e),values=attr),_,_,_,_,_,_,_,_,_,_)
      equation
        // apply replacements
        (e,true) = BackendVarTransform.replaceExp(e, iReplEvaluate, NONE());
        (e,_) = ExpressionSimplify.simplify(e);
        e = EvaluateFunctions.evaluateConstantFunctionCallExp(e,FCore.getFunctionTree(iCache));
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
  input DAE.Exp inExp;
  input tuple<BackendVarTransform.VariableReplacements,Boolean> inTpl;
  output DAE.Exp outExp;
  output tuple<BackendVarTransform.VariableReplacements,Boolean> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue(inExp,inTpl)
    local
      DAE.Exp exp;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cr;
      Boolean b,b1;
    case (exp as DAE.CREF(),(repl,b))
      equation
        (exp,b1) = BackendVarTransform.replaceExp(exp,repl,NONE());
      then (exp,(repl,b or b1));
    else (inExp,inTpl);
  end matchcontinue;
end traverseExpVisitorWrapper;


protected function replaceEvaluatedParametersSystem
"author Frenkel TUD"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Variables,BackendDAE.IncidenceMatrix,BackendDAE.EquationArray,FCore.Cache,FCore.Graph,Integer,array<Integer>,BackendVarTransform.VariableReplacements,BackendVarTransform.VariableReplacements> inTypeA;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Variables,BackendDAE.IncidenceMatrix,BackendDAE.EquationArray,FCore.Cache,FCore.Graph,Integer,array<Integer>,BackendVarTransform.VariableReplacements,BackendVarTransform.VariableReplacements> outTypeA;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrixT> mT;
  BackendDAE.Matching matching;
  BackendDAE.StateSets stateSets;
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars) := isyst;
  (vars,outTypeA) := BackendVariable.traverseBackendDAEVarsWithUpdate(vars, replaceEvaluatedParameterTraverser, inTypeA);
  osyst := BackendDAEUtil.setEqSystVars(isyst, vars);
end replaceEvaluatedParametersSystem;

protected function replaceEvaluatedParameterTraverser
"author: Frenkel TUD 2011-04"
 input BackendDAE.Var inVar;
 input tuple<BackendDAE.Variables,BackendDAE.IncidenceMatrix,BackendDAE.EquationArray,FCore.Cache,FCore.Graph,Integer,array<Integer>,BackendVarTransform.VariableReplacements,BackendVarTransform.VariableReplacements> inTpl;
 output BackendDAE.Var outVar;
 output tuple<BackendDAE.Variables,BackendDAE.IncidenceMatrix,BackendDAE.EquationArray,FCore.Cache,FCore.Graph,Integer,array<Integer>,BackendVarTransform.VariableReplacements,BackendVarTransform.VariableReplacements> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Variables knVars;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.EquationArray ieqns;
      FCore.Cache cache;
      FCore.Graph graph;
      Integer mark;
      array<Integer> markarr;
      BackendVarTransform.VariableReplacements repl;
      BackendVarTransform.VariableReplacements replEvaluate;
      BackendDAE.Var v;
      DAE.Exp e,e1;
      DAE.ComponentRef cr;
      Option<DAE.VariableAttributes> attr;
      Boolean b;
    case (v as BackendDAE.VAR(bindExp=SOME(e),values=attr),(knVars,m,ieqns,cache,graph,mark,markarr,repl,replEvaluate))
      equation
        // apply replacements
        (e1,true) = BackendVarTransform.replaceExp(e, replEvaluate, NONE());
        (e1,_) = ExpressionSimplify.simplify(e1);
        v = BackendVariable.setBindExp(v, SOME(e1));
        (attr,(replEvaluate,b)) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,(replEvaluate,false));
        v = if b then BackendVariable.setVarAttributes(v,attr) else v;
        (v,knVars,cache,mark,repl) = evaluateFixedAttribute(v,false,knVars,m,ieqns,cache,graph,mark,markarr,repl);
      then (v,(knVars,m,ieqns,cache,graph,mark,markarr,repl,replEvaluate));

    case  (v as BackendDAE.VAR(values=attr),(knVars,m,ieqns,cache,graph,mark,markarr,repl,replEvaluate))
      equation
        // apply replacements
        (attr,(replEvaluate,true)) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,(replEvaluate,false));
        v = BackendVariable.setVarAttributes(v,attr);
        (v,knVars,cache,mark,repl) = evaluateFixedAttribute(v,false,knVars,m,ieqns,cache,graph,mark,markarr,repl);
      then (v,(knVars,m,ieqns,cache,graph,mark,markarr,repl,replEvaluate));

    case (v,(knVars,m,ieqns,cache,graph,mark,markarr,repl,replEvaluate))
      equation
        (v,knVars,cache,mark,repl) = evaluateFixedAttribute(v,false,knVars,m,ieqns,cache,graph,mark,markarr,repl);
      then (v,(knVars,m,ieqns,cache,graph,mark,markarr,repl,replEvaluate));
  end matchcontinue;
end replaceEvaluatedParameterTraverser;

protected function replaceEvaluatedParametersEqns "author Frenkel TUD"
  input BackendDAE.BackendDAE inDAE;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendDAE.BackendDAE outDAE;
protected
  list<BackendDAE.Equation> lsteqns;
  BackendDAE.EqSystems systs;
  Boolean b;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;

  // do replacements in initial equations
  lsteqns := BackendEquation.equationList(shared.initialEqs);
  (lsteqns, b) := BackendVarTransform.replaceEquations(lsteqns, inRepl, NONE());
  if b then
    shared.initialEqs :=  BackendEquation.listEquation(lsteqns);
  end if;

  lsteqns := BackendEquation.equationList(shared.removedEqs);
  (lsteqns, b) := BackendVarTransform.replaceEquations(lsteqns, inRepl, NONE());
  if b then
    shared.initialEqs :=  BackendEquation.listEquation(lsteqns);
  end if;

  // do replacements in systems
  systs := List.map1(systs, replaceEvaluatedParametersSystemEqns, inRepl);

  outDAE := BackendDAE.DAE(systs, shared);
end replaceEvaluatedParametersEqns;

protected function replaceEvaluatedParametersSystemEqns
"author Frenkel TUD
  replace the evaluated parameters in the equationsystems"
  input BackendDAE.EqSystem isyst;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendDAE.EqSystem osyst = isyst;
protected
  list<BackendDAE.Equation> lsteqns;
  Boolean b;
algorithm
  lsteqns := BackendEquation.equationList(osyst.orderedEqs);
  (lsteqns, b) := BackendVarTransform.replaceEquations(lsteqns, inRepl, NONE());
  if b then
    osyst.orderedEqs := BackendEquation.listEquation(lsteqns);
    osyst := BackendDAEUtil.clearEqSyst(osyst);
  end if;

  // do replacements in simple equations
  lsteqns := BackendEquation.equationList(osyst.removedEqs);
  (lsteqns, b) := BackendVarTransform.replaceEquations(lsteqns, inRepl, NONE());
  if b then
    osyst.removedEqs := BackendEquation.listEquation(lsteqns);
  end if;

end replaceEvaluatedParametersSystemEqns;



/*
//------------------------------------------
// evaluate all parameters
//------------------------------------------

public function evaluateAllParameters_obsolete
"author Waurich TUD
  evaluates and replaces all parameters"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  Boolean evaluatedSomething;
  Integer nVars,nEqs;
  BackendDAE.Variables knvars, vars, extVars, aliasVars;
  BackendDAE.EquationArray eqArr,initEqs,remEqs, remEqsSys;
  BackendDAE.EqSystem sys;
  BackendDAE.EqSystems systs, systs2;
  BackendDAE.IncidenceMatrix m,mT;
  BackendDAE.Shared shared;
  BackendDAE.EventInfo eventInfo;
  DAE.FunctionTree functionTree;
  list<DAE.Exp> bindExps;
  list<BackendDAE.Equation> eqs, initEqLst, initEqLst2;
  list<BackendDAE.Var> knVarsLst, unknownVars, varLst;
  BackendVarTransform.VariableReplacements repl;
  array<Integer> ass1, ass2;
  list<Integer> order;
  list<list<Integer>> comps;
algorithm
  if Flags.isSet(Flags.EVAL_ALL_PARAMS) then
    print("the old evalAllParams\n");
    BackendDAE.DAE (systs, shared as BackendDAE.SHARED(knownVars=knvars, initialEqs=initEqs, functionTree=functionTree)) := inDAE;
    knVarsLst := BackendVariable.varList(knvars);
      //BackendDump.dumpVarList(knVarsLst,"knVarsLst");
    initEqLst := BackendEquation.equationList(initEqs);
    initEqLst := List.filter1OnTrue(initEqLst, isParameterEquation, knvars);
    repl := BackendVarTransform.emptyReplacements();
    (repl,unknownVars, evaluatedSomething) := getParameterBindingReplacements(knVarsLst, functionTree, repl);

    while evaluatedSomething and not listEmpty(unknownVars) loop
      //use the evaluated parameters to evaluate more
      (repl,unknownVars, evaluatedSomething) := getParameterBindingReplacements(unknownVars, functionTree, repl);
            //BackendDump.dumpVarList(unknownVars,"UNKNOWNS2");
    end while;

    //Continue work from here...
    repl := BackendVarTransform.getConstantReplacements(repl);
    (initEqLst,_) := BackendVarTransform.replaceEquations(initEqLst,repl,NONE());
    unknownVars := List.filter1OnTrue(knVarsLst,BackendVarTransform.varHasNoReplacement,repl);
    unknownVars := List.map1(unknownVars,BackendVarTransform.replaceBindingExp,repl);
      //BackendDump.dumpEquationList(initEqLst,"initEqLst");
      if not listEmpty(unknownVars) then BackendDump.dumpVarList(unknownVars,"Could not evaluate following parameters. Ask a Developer for further support."); end if;
      //BackendVarTransform.dumpReplacements(repl);
    //...to here and extend the function evaluation (in simplifyReplacements) and evaluation of parameters (e.g. Modelica.Blocks.Examples.Filter.mo)

    systs2 := {};
    // replace all equations and all bindExps of the vars
    for sys in systs loop
      vars := sys.orderedVars;
      varLst := BackendVariable.varList(vars);
      varLst := List.map1(varLst,BackendVarTransform.replaceBindingExp,repl);
      varLst := List.map1(varLst,BackendVarTransform.replaceVariableAttributesInVar,repl);
      sys.orderedVars := BackendVariable.listVar1(varLst);
      eqArr := sys.orderedEqs;
      remEqsSys := sys.removedEqs;
      (eqArr,_) := BackendVarTransform.replaceEquationsArr(eqArr,repl,NONE());
      (remEqsSys,_) := BackendVarTransform.replaceEquationsArr(remEqsSys,repl,NONE());
      sys.orderedEqs := eqArr;
      sys.removedEqs := remEqsSys;
      systs2 := sys::systs2;
    end for;
    systs2 := MetaModelica.Dangerous.listReverseInPlace(systs2);

    // replace all init eqs, removed eqs, external var-bindings and alias var bindings, event-infos
    initEqs := shared.initialEqs;
    remEqs := shared.removedEqs;
    extVars := shared.externalObjects;
    aliasVars := shared.aliasVars;
    eventInfo := shared.eventInfo;
    (initEqs,_) := BackendVarTransform.replaceEquationsArr(initEqs,repl,NONE());
    (remEqs,_) := BackendVarTransform.replaceEquationsArr(remEqs,repl,NONE());
    extVars := BackendVariable.listVar1(List.map1(BackendVariable.varList(extVars),BackendVarTransform.replaceBindingExp,repl));
    aliasVars := BackendVariable.listVar1(List.map1(BackendVariable.varList(aliasVars),BackendVarTransform.replaceBindingExp,repl));
    eventInfo := BackendVarTransform.replaceEventInfo(eventInfo,repl,NONE());
    shared.initialEqs := initEqs;
    shared.removedEqs := remEqs;
    shared.externalObjects := extVars;
    shared.aliasVars := aliasVars;
    shared.eventInfo := eventInfo;
    // set remaining, not evaluated params
    shared.knownVars := BackendVariable.listVar(unknownVars);
    outDAE := BackendDAE.DAE(systs2,shared);
  else
    outDAE := inDAE;
  end if;
end evaluateAllParameters_obsolete;


protected function getParameterBindingReplacements "gathers replacements for the vars with binding"
  input list<BackendDAE.Var> varsIn;
  input DAE.FunctionTree functionTree;
  input BackendVarTransform.VariableReplacements replIn;
  output BackendVarTransform.VariableReplacements replOut;
  output list<BackendDAE.Var> unKnowns = {};
  output Boolean evaluatedSomething = false;
protected
  BackendVarTransform.VariableReplacements repl;
  DAE.ComponentRef cref;
  BackendDAE.Var var;
  DAE.Exp bindExp;
algorithm
  repl := replIn;
  for var in varsIn loop
    if BackendVariable.varHasBindExp(var) then
      bindExp := BackendVariable.varBindExp(var);
      (bindExp,_) := BackendVarTransform.replaceExp(bindExp,repl,NONE());
      bindExp := EvaluateFunctions.evaluateConstantFunctionCallExp(bindExp,functionTree);
      bindExp := ExpressionSimplify.simplify(bindExp);
      if Expression.isEvaluatedConst(bindExp) and not ComponentReference.isArrayElement(var.varName) then
        //print("BIND "+ExpressionDump.printExpStr(bindExp)+"\n");
        //print("BIND "+ExpressionDump.dumpExpStr(bindExp,1)+"\n");
        cref := BackendVariable.varCref(var);
        repl := BackendVarTransform.addReplacement(repl,cref,bindExp,NONE());
        evaluatedSomething := true;
      else
        unKnowns := var::unKnowns;
      end if;
    else
      unKnowns := var::unKnowns;
    end if;
  end for;
  replOut := BackendVarTransform.simplifyReplacements(repl,functionTree);
end getParameterBindingReplacements;

protected function getParameterBindingEquations "gathers equations for the vars with binding"
  input list<BackendDAE.Var> varsIn;
  input DAE.FunctionTree functionTree;
  output list<BackendDAE.Equation> eqs;
  output list<BackendDAE.Var> unKnowns = {};
protected
  DAE.ComponentRef cref;
  BackendDAE.Var var;
  DAE.Exp bindExp;
algorithm
  eqs := {};
  for var in varsIn loop
    if BackendVariable.varHasBindExp(var) then
      bindExp := BackendVariable.varBindExp(var);
      bindExp := EvaluateFunctions.evaluateConstantFunctionCallExp(bindExp,functionTree);
      bindExp := ExpressionSimplify.simplify(bindExp);
      //print("BIND "+ExpressionDump.dumpExpStr(bindExp,1)+"\n");
      cref := BackendVariable.varCref(var);
      eqs := BackendEquation.generateEquation(Expression.crefExp(cref), bindExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC)::eqs;
    else
      unKnowns := var::unKnowns;
    end if;
  end for;
end getParameterBindingEquations;

protected function isParameterEquation"outputs true if the equation is only dependent on parameters"
  input BackendDAE.Equation eq;
  input BackendDAE.Variables knownVars;
  output Boolean b;
protected
  list<DAE.ComponentRef> crefs;
algorithm
  crefs := BackendEquation.equationCrefs(eq);
  b := List.fold(List.map2(crefs,BackendVariable.existsVar,knownVars,false),boolAnd,true);
end isParameterEquation;
*/

annotation(__OpenModelica_Interface="backend");
end EvaluateParameter;
