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
  description: EvaluateParameter contains functions to evaluate the bindexp of parameters with
               annotation(Evaluate=true) and parameters which depent only on evaluated parameters.
               Additionally, parameters with final=true or protected=true can be evaluated, as well.

               Concept:

               - Traverse all parameter and get the parameters which must be evaluated O(N).

               - Traverse the list and evaluate each parameter with a DFS  O(N).
                 -> Replacements for evaluated parameter.

               - Sort the parameters with tarjans algorithm O(N).

               - Traverse the sorted parameters and replace in the bindexp the evaluated parameters.
                 If a parameter has a nonconstant bindexp before and now a constant one add it to the replacements.

               - Replace the parameters in the variables and the DAE."


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


protected constant String BORDER    = "********************************************************************************";
protected constant String UNDERLINE = "================================================================================";


partial function selectParameterFunc
  input BackendDAE.Var inVar;
  output Boolean select;
end selectParameterFunc;


public function evaluateParameters "author Frenkel TUD
  Evaluate and replace parameters with annotation(Evaluate=true) in variables and parameters."
  input output BackendDAE.BackendDAE DAE;
protected
  selectParameterFunc selectParameterfunc;
  BackendDAE.Variables globalKnownVars, aliasVars;
  BackendDAE.EquationArray initialEqs;
  FCore.Cache cache;
  FCore.Graph graph;
  BackendVarTransform.VariableReplacements repl;
  BackendVarTransform.VariableReplacements oRepl;
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
  list<list<Integer>> comps;
  array<Integer> ass2, markarr;
  Integer size, mark, nselect;
  BackendDAE.AdjacencyMatrixT m;
  BackendDAE.AdjacencyMatrixT mt;
  list<Integer> selectedParameters;
  AvlSetCR.Tree ht;
  Boolean isInitial;
algorithm
  isInitial := BackendDAEUtil.isInitializationDAE(DAE.shared);
  if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
    print("\nBEGINNING of preOptModule 'evaluateParameters'\n" + BORDER + "\n\n");
    BackendDump.dumpBackendDAE(DAE,"DAE before evaluating parameters");
  end if;

  // Check if the parameters are not already evaluated
  if not Flags.isSet(Flags.EVAL_PARAM) then

    // Choose the parameters to evaluate
    selectParameterfunc := match(Flags.getConfigBool(Flags.EVALUATE_FINAL_PARAMS), Flags.getConfigBool(Flags.EVALUATE_PROTECTED_PARAMS))
      case(false, false)
        equation
          if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
            print("\nStructural parameters and parameters with annotation(Evaluate=true) will be evaluated.\n");
          end if;
         then BackendVariable.hasVarEvaluateAnnotation;
      case(true, false)
        equation
          if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
            print("\nStructural parameters, final parameters and parameters with annotation(Evaluate=true) will be evaluated.\n");
          end if;
         then BackendVariable.hasVarEvaluateAnnotationOrFinal;
      case(false, true)
        equation
          if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
            print("\nStructural parameters, protected parameters and parameters with annotation(Evaluate=true) will be evaluated.\n");
          end if;
         then BackendVariable.hasVarEvaluateAnnotationOrProtected;
      case(true, true)
        equation
          if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
            print("\nStructural parameters, final parameters, protected parameters and parameters with annotation(Evaluate=true) will be evaluated.\n");
          end if;
         then BackendVariable.hasVarEvaluateAnnotationOrFinalOrProtected;
    end match;

    BackendDAE.DAE(systs, shared as BackendDAE.SHARED(globalKnownVars=globalKnownVars, aliasVars=aliasVars, initialEqs=initialEqs, cache=cache, graph=graph)) := DAE;


    // Get the adjacency matrix and the selected parameters
    size := BackendVariable.varsSize(globalKnownVars);
    m := arrayCreate(size, {});
    mt := arrayCreate(size, {});
    ass2 := Array.createIntRange(size);
    ht := FCore.getEvaluatedParams(cache); // get structural parameters
    ((_, _, _, selectedParameters, m, mt, _, _)) := BackendVariable.traverseBackendDAEVars(globalKnownVars, getParameterAdjacencyMatrix, (globalKnownVars, 1, selectParameterfunc, {}, m, mt, ht, isInitial));
    nselect := listLength(selectedParameters);

    if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
      print("\nSTART evaluating parameters:\n" + UNDERLINE + "\n");
      print("Number of parameters: " + intString(size) + "\n");
      print("Number of parameters selected for evaluation: " + intString(nselect) + "\n");
      print("Selected parameters for evaluation:\n" + stringDelimitList(List.map(selectedParameters, intString), ",") + "\n");
      BackendDump.dumpAdjacencyMatrix(m);
      BackendDump.dumpAdjacencyMatrixT(mt);
    end if;


    // Evaluate the selected parameters and the ones you need for the calculation and save them in replacements
    markarr := arrayCreate(size, -1);
    size := intMax(BaseHashTable.defaultBucketSize, realInt(realMul(intReal(size), 0.7)));
    nselect := intMax(BaseHashTable.defaultBucketSize, nselect*2);
    repl := BackendVarTransform.emptyReplacementsSized(size);
    oRepl := BackendVarTransform.emptyReplacementsSized(nselect);
    (globalKnownVars, cache, repl, oRepl, mark) := evaluateSelectedParameters(selectedParameters, globalKnownVars, m, initialEqs, cache, graph, markarr, isInitial, repl, oRepl, 1);

    if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
      print("\n\nAfter evaluating the selected parameters:\n" + UNDERLINE + "\n");
      print("\nAll replacements:");
      BackendVarTransform.dumpReplacements(repl);
      print("\nReplacements that will be replaced in the DAE:");
      BackendVarTransform.dumpReplacements(oRepl);
      BackendDump.dumpVariables(globalKnownVars, "globalKnownVars");
      print("\nmark: " + intString(mark) + "\n");
      print("markarr: " + stringDelimitList(List.map(arrayList(markarr), intString), ",") + "\n");
    end if;


    // Sort the parameters
    comps := Sorting.TarjanTransposed(mt, ass2);

    if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
      print("\n\nAfter sorting parameters:\n" + UNDERLINE + "\nOrder:\n");
      for comp in comps loop
        print(stringDelimitList(List.map(comp, intString), ",") + "\n");
      end for;
    end if;


    // Replace the evaluated parameters in parameter bindings
    (globalKnownVars, repl, oRepl, cache, mark) := traverseParameterSorted(comps, globalKnownVars, m, initialEqs, cache, graph, mark, markarr, repl, oRepl, isInitial);

    if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
      print("\n\nAfter replacing the evaluated parameters in parameter bindings:\n" + UNDERLINE);
      print("\nAll replacements:");
      BackendVarTransform.dumpReplacements(repl);
      print("\nReplacements that will be replaced in the DAE:");
      BackendVarTransform.dumpReplacements(oRepl);
      BackendDump.dumpVariables(globalKnownVars, "globalKnownVars");
      print("\nmark: " + intString(mark) + "\n");
      print("markarr: " + stringDelimitList(List.map(arrayList(markarr), intString), ",") + "\n");
    end if;


    // Replace the evaluated parameters in variable bindings and start attributes
    (systs, (globalKnownVars, m, initialEqs, cache, graph, mark, markarr,_ , repl, oRepl)) := List.mapFold(systs, replaceEvaluatedParametersSystem, (globalKnownVars, m, initialEqs, cache, graph, mark, markarr, isInitial, repl, oRepl));
    (aliasVars, _) := BackendVariable.traverseBackendDAEVarsWithUpdate(aliasVars, replaceEvaluatedParameterTraverser, (globalKnownVars, m, initialEqs, cache, graph, mark, markarr, isInitial, repl, oRepl));

    if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
      print("\n\nAfter replacing the evaluated parameters in variable bindings and start attributes:\n" + UNDERLINE);
      print("\nAll replacements:");
      BackendVarTransform.dumpReplacements(repl);
      print("\nReplacements that will be replaced in the DAE:");
      BackendVarTransform.dumpReplacements(oRepl);
      BackendDump.dumpVariables(globalKnownVars, "globalKnownVars");
      print("\nmark: " + intString(mark) + "\n");
      print("markarr: " + stringDelimitList(List.map(arrayList(markarr), intString), ",") + "\n\n");
    end if;


    // Replace evaluated parameters in external objects if flag is set
    if Flags.getConfigBool(Flags.REPLACE_EVALUATED_PARAMS) then
      shared.externalObjects := BackendVariable.listVar1(List.map1(BackendVariable.varList(shared.externalObjects),BackendVarTransform.replaceBindingExp,oRepl));
    end if;

    shared.globalKnownVars := globalKnownVars;
    shared.aliasVars := aliasVars;
    shared.initialEqs := initialEqs;
    shared.graph := graph;
    shared.cache := cache;

    DAE := BackendDAE.DAE(systs, shared);

    // Replace the evaluated parameters in the DAE if flag is set
    if Flags.getConfigBool(Flags.REPLACE_EVALUATED_PARAMS) then
      if not BackendVarTransform.isReplacementEmpty(oRepl) then
        DAE := replaceEvaluatedParametersEqns(DAE, oRepl);
        if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
          BackendDump.dumpBackendDAE(DAE,"DAE after replacing the evaluated parameters");
        end if;
      else
        if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
          print("\nThere is no evaluated parameter.\n");
        end if;
      end if;
    else
      if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
        Error.addCompilerNotification("Evaluated parameters are not replaced in the DAE. Use --replaceEvaluatedParameters=true to replace them in the DAE.");
      end if;
    end if;


  else
    if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
      print("\n" + UNDERLINE + "\nThere is nothing to do. All parameters are already evaluated.\n" + UNDERLINE + "\n\n");
    end if;
  end if;

  if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
    print("\nEND of preOptModule 'evaluateParameters'\n" + BORDER +"\n\n");
  end if;
end evaluateParameters;


protected function getParameterAdjacencyMatrix
" This function calculates the adjacency matrix for parameters and determines which parameters should be calculated
  with the input function 'selectParameter'. Structural parameters are also marked to be calculated.
  ptaeuber: Evaluating structural parameters (again) in this module is just a workaround since structural parameters
  are already calculated in the Frontend but the value is lost."
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.Variables,Integer,selectParameterFunc,list<Integer>,BackendDAE.AdjacencyMatrix,BackendDAE.AdjacencyMatrixT,AvlSetCR.Tree,Boolean> inTpl;
  output BackendDAE.Var outVar;
  output tuple<BackendDAE.Variables,Integer,selectParameterFunc,list<Integer>,BackendDAE.AdjacencyMatrix,BackendDAE.AdjacencyMatrixT,AvlSetCR.Tree,Boolean> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Variables globalKnownVars;
      BackendDAE.Var v;
      DAE.Exp e;
      DAE.ComponentRef cref;
      Option<DAE.VariableAttributes> attr;
      AvlSetInt.Tree tree;
      list<Integer> ilst,selectedParameters;
      Integer index;
      BackendDAE.AdjacencyMatrix m;
      BackendDAE.AdjacencyMatrixT mt;
      selectParameterFunc selectParameter;
      Boolean select, isInitial;
      AvlSetCR.Tree ht;

    case (v as BackendDAE.VAR(varKind=BackendDAE.PARAM(),bindExp=SOME(e)),(globalKnownVars,index,selectParameter,selectedParameters,m,mt,ht,isInitial))
      equation
        (_,(_,tree,_)) = Expression.traverseExpTopDown(e, BackendDAEUtil.traversingadjacencyRowExpFinder, (globalKnownVars,AvlSetInt.EMPTY(),isInitial));
        ilst = AvlSetInt.listKeys(tree);
        cref = BackendVariable.varCref(v);
        select = selectParameter(v) or AvlSetCR.hasKey(ht, cref);
        selectedParameters = List.consOnTrue(select, index, selectedParameters);
        m = arrayUpdate(m,index,ilst);
        mt = List.fold1(index::ilst,Array.consToElement,index,mt);
      then (v,(globalKnownVars,index+1,selectParameter,selectedParameters,m,mt,ht,isInitial));

    case (v as BackendDAE.VAR(varKind=BackendDAE.PARAM(),values=attr),(globalKnownVars,index,selectParameter,selectedParameters,m,mt,ht,isInitial))
      equation
        e = DAEUtil.getStartAttrFail(attr);
        (_,(_,tree,_)) = Expression.traverseExpTopDown(e, BackendDAEUtil.traversingadjacencyRowExpFinder, (globalKnownVars,AvlSetInt.EMPTY(),isInitial));
        ilst = AvlSetInt.listKeys(tree);
        cref = BackendVariable.varCref(v);
        select = selectParameter(v) or AvlSetCR.hasKey(ht, cref);
        selectedParameters = List.consOnTrue(select, index, selectedParameters);
        m = arrayUpdate(m,index,ilst);
        mt = List.fold1(index::ilst,Array.consToElement,index,mt);
      then (v,(globalKnownVars,index+1,selectParameter,selectedParameters,m,mt,ht,isInitial));

    case (v,(globalKnownVars,index,selectParameter,selectedParameters,m,mt,ht,isInitial))
      equation
        cref = BackendVariable.varCref(v);
        select = selectParameter(v) or AvlSetCR.hasKey(ht, cref);
        selectedParameters = List.consOnTrue(select, index, selectedParameters);
        ilst = {index};
        mt = arrayUpdate(mt,index,ilst);
      then (v,(globalKnownVars,index+1,selectParameter,selectedParameters,m,mt,ht,isInitial));
  end matchcontinue;
end getParameterAdjacencyMatrix;


protected function evaluateSelectedParameters
"author Frenkel TUD"
  input list<Integer> iSelected;
  input output BackendDAE.Variables globalKnownVars;
  input BackendDAE.AdjacencyMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input output FCore.Cache cache;
  input FCore.Graph graph;
  input array<Integer> markarr;
  input Boolean isInitial;
  input output BackendVarTransform.VariableReplacements repl;
  input output BackendVarTransform.VariableReplacements replEvaluate;
  input output Integer mark;
algorithm
  for i in iSelected loop
    (globalKnownVars,cache,repl,replEvaluate,mark) := evaluateSelectedParameters0(i,globalKnownVars,m,inIEqns,cache,graph,markarr,isInitial,repl,replEvaluate,mark);
  end for;
end evaluateSelectedParameters;


protected function evaluateSelectedParameters0
"author Frenkel TUD"
  input Integer i;
  input output BackendDAE.Variables globalKnownVars;
  input BackendDAE.AdjacencyMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input output FCore.Cache cache;
  input FCore.Graph graph;
  input array<Integer> markarr;
  input Boolean isInitial;
  input output BackendVarTransform.VariableReplacements repl;
  input output BackendVarTransform.VariableReplacements replEvaluate;
  input output Integer mark;
protected
  BackendDAE.Var v;
algorithm
  try
    false := intGt(markarr[i],0) "not yet evaluated";
    arrayUpdate(markarr,i,mark);
    // evaluate needed parameters
    (globalKnownVars,cache,mark,repl,replEvaluate) := evaluateSelectedParameters1(m[i],globalKnownVars,m,inIEqns,cache,graph,mark,markarr,isInitial,repl,replEvaluate);
    // evaluate parameter
    v := BackendVariable.getVarAt(globalKnownVars,i);
    (v,globalKnownVars,cache,mark,repl) := evaluateFixedAttribute(v,true,globalKnownVars,m,inIEqns,cache,graph,mark,markarr,isInitial,repl);
    (globalKnownVars,repl,replEvaluate,cache) := evaluateSelectedParameter(v,i,globalKnownVars,inIEqns,repl,replEvaluate,cache,graph);
  else
    // evaluate parameter
    v := BackendVariable.getVarAt(globalKnownVars,i);
    (globalKnownVars,repl,replEvaluate,cache) := evaluateSelectedParameter(v,i,globalKnownVars,inIEqns,repl,replEvaluate,cache,graph);
  end try;
end evaluateSelectedParameters0;


protected function evaluateSelectedParameters1
"author Frenkel TUD"
  input list<Integer> iUsed;
  input output BackendDAE.Variables globalKnownVars;
  input BackendDAE.AdjacencyMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input output FCore.Cache cache;
  input FCore.Graph graph;
  input output Integer mark;
  input array<Integer> markarr;
  input Boolean isInitial;
  input output BackendVarTransform.VariableReplacements repl;
  input output BackendVarTransform.VariableReplacements replEvaluate = BackendVarTransform.emptyReplacements();
algorithm
  (globalKnownVars, cache, mark, repl, replEvaluate) := matchcontinue(iUsed)
    local
      Integer i;
      list<Integer> rest;
      BackendDAE.Var v;

    case {}
    then (globalKnownVars, cache, mark, repl, replEvaluate);

    case i::rest equation
      false = intGt(markarr[i], 0) "not yet evaluated";
      arrayUpdate(markarr, i, mark);
      (globalKnownVars, cache, mark, repl, replEvaluate) = evaluateSelectedParameters1(m[i], globalKnownVars, m, inIEqns, cache, graph, mark, markarr, isInitial, repl, replEvaluate);
      v = BackendVariable.getVarAt(globalKnownVars, i);
      (v, globalKnownVars, cache, mark, repl) = evaluateFixedAttribute(v, true, globalKnownVars, m, inIEqns, cache, graph, mark, markarr, isInitial, repl);
      (globalKnownVars, cache, repl, replEvaluate) = evaluateParameter(v, i, globalKnownVars, inIEqns, cache, graph, repl, replEvaluate);
      (globalKnownVars, cache, mark, repl, replEvaluate) = evaluateSelectedParameters1(rest, globalKnownVars, m, inIEqns, cache, graph, mark, markarr, isInitial, repl, replEvaluate);
    then (globalKnownVars, cache, mark, repl, replEvaluate);

    case _::rest equation
      (globalKnownVars, cache, mark, repl, replEvaluate) = evaluateSelectedParameters1(rest, globalKnownVars, m, inIEqns, cache, graph, mark, markarr, isInitial, repl, replEvaluate);
    then (globalKnownVars, cache, mark, repl, replEvaluate);
  end matchcontinue;
end evaluateSelectedParameters1;


protected function evaluateSelectedParameter
"author Frenkel TUD"
  input BackendDAE.Var var;
  input Integer index;
  input output BackendDAE.Variables globalKnownVars;
  input BackendDAE.EquationArray inIEqns;
  input output BackendVarTransform.VariableReplacements repl;
  input output BackendVarTransform.VariableReplacements replEvaluate;
  input output FCore.Cache cache;
  input FCore.Graph graph;
algorithm
  _ := matchcontinue(var)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      DAE.Exp e, e1;
      Option<DAE.VariableAttributes> attr;
      Values.Value value;
      SourceInfo info;

    // Constant with constant bindExp
    case BackendDAE.VAR(varName = cr, varKind=BackendDAE.CONST(), bindExp=SOME(e))
      equation
        true = Expression.isConst(e);
        // save replacement
        repl = BackendVarTransform.addReplacement(repl, cr, e, NONE());
        replEvaluate = BackendVarTransform.addReplacement(replEvaluate, cr, e , NONE());
        //  print("Evaluate Selected " + BackendDump.varString(var) + "\n->    " + BackendDump.varString(v) + "\n");
     then ();

    // Constant with bindExp
    case BackendDAE.VAR(varName = cr, varKind=BackendDAE.CONST(), bindExp=SOME(e))
      equation
        // apply replacements
        (e1, _) = BackendVarTransform.replaceExp(e, repl, NONE());
        // evaluate expression
        (cache, value) = Ceval.ceval(cache, graph, e1, false, Absyn.NO_MSG(), 0);
        e1 = ValuesUtil.valueExp(value);
        // set bind value
        v = BackendVariable.setBindExp(var, SOME(e1));
        // update Vararray
        globalKnownVars = BackendVariable.setVarAt(globalKnownVars, index, v);
        // save replacement
        repl = BackendVarTransform.addReplacement(repl, cr, e1, NONE());
        replEvaluate = BackendVarTransform.addReplacement(replEvaluate, cr, e1 , NONE());
        //  print("Evaluate Selected " + BackendDump.varString(var) + "\n->    " + BackendDump.varString(v) + "\n");
     then ();

    // Parameter with constant bindExp
    case BackendDAE.VAR(varName = cr, varKind=BackendDAE.PARAM(), bindExp=SOME(e))
      equation
        true = Expression.isConst(e);
        v = BackendVariable.setVarFinal(var, true);
        // update Vararray
        globalKnownVars = BackendVariable.setVarAt(globalKnownVars, index, v);
        // save replacement
        if BackendVariable.varFixed(v) then
          repl = BackendVarTransform.addReplacement(repl, cr, e, NONE());
          replEvaluate = BackendVarTransform.addReplacement(replEvaluate, cr, e , NONE());
        end if;
        //  print("Evaluate Selected " + BackendDump.varString(var) + "\n->    " + BackendDump.varString(v) + "\n");
     then ();

    // Parameter with bindExp
    case BackendDAE.VAR(varName = cr, varKind=BackendDAE.PARAM(), bindExp=SOME(e))
      equation
        // apply replacements
        (e1, _) = BackendVarTransform.replaceExp(e, repl, NONE());
        // evaluate expression
        (cache, value) = Ceval.ceval(cache, graph, e1, false, Absyn.NO_MSG(), 0);
        e1 = ValuesUtil.valueExp(value);
        // set bind value
        v = BackendVariable.setBindExp(var, SOME(e1));
        v = BackendVariable.setVarFinal(v, true);
        // update Vararray
        globalKnownVars = BackendVariable.setVarAt(globalKnownVars, index, v);
        // save replacement
        repl = BackendVarTransform.addReplacement(repl, cr, e1, NONE());
        replEvaluate = BackendVarTransform.addReplacement(replEvaluate, cr, e1 , NONE());
        //  print("Evaluate Selected " + BackendDump.varString(var) + "\n->    " + BackendDump.varString(v) + "\n");
     then ();

    // Parameter without bindExp but with start attribute and fixed
    //waurich: if there is unevaluated binding, dont take the start value as a binding replacement. compute the unevaluated binding!
    case BackendDAE.VAR(varName = cr, varKind=BackendDAE.PARAM(), values=attr)
      equation
        true = BackendVariable.varFixed(var);
        false = BackendVariable.varHasBindExp(var);
        e = DAEUtil.getStartAttrFail(attr);
        // apply replacements
        (e1, _) = BackendVarTransform.replaceExp(e, repl, NONE());
        // evaluate expression
        (cache, value) = Ceval.ceval(cache, graph, e1, false, Absyn.NO_MSG(), 0);
        e1 = ValuesUtil.valueExp(value);
        // set bind value
        v = BackendVariable.setVarStartValue(var, e1);
        v = BackendVariable.setVarFinal(v, true);
        // update Vararray
        globalKnownVars = BackendVariable.setVarAt(globalKnownVars, index, v);
        // save replacement
        repl = BackendVarTransform.addReplacement(repl, cr, e1, NONE());
        replEvaluate = BackendVarTransform.addReplacement(replEvaluate, cr, e1, NONE());
        //  print("Evaluate Selected " + BackendDump.varString(var) + "\n->    " + BackendDump.varString(v) + "\n");
     then ();

    // report warning
    else algorithm
      if Flags.isSet(Flags.EVAL_PARAM_DUMP) then
        info := ElementSource.getElementSourceFileInfo(BackendVariable.getVarSource(var));
        Error.addSourceMessage(Error.COMPILER_WARNING, {"Cannot evaluate Variable \"" + BackendDump.varString(var) + "\""}, info);
      end if;
    then ();

  end matchcontinue;
end evaluateSelectedParameter;


protected function evaluateParameter
"author Frenkel TUD"
  input BackendDAE.Var var;
  input Integer index;
  input output BackendDAE.Variables globalKnownVars;
  input BackendDAE.EquationArray inIEqns;
  input output FCore.Cache cache;
  input FCore.Graph graph;
  input output BackendVarTransform.VariableReplacements repl;
  input output BackendVarTransform.VariableReplacements replEvaluate;
algorithm
  _ := match var
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      DAE.Exp e,e1;
      Option<DAE.VariableAttributes> attr;
      Values.Value value;

    case BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),bindExp=SOME(e))
      equation
        // applay replacements
        (e,_) = BackendVarTransform.replaceExp(e, repl, NONE());
        // evaluate expression
        (cache, value) = Ceval.ceval(cache, graph, e, false, Absyn.NO_MSG(), 0);
        e1 = ValuesUtil.valueExp(value);
        // also set this var final because it is used for the calculation of another variable
        v = BackendVariable.setVarFinal(var, true);
        // update Vararray
        globalKnownVars = BackendVariable.setVarAt(globalKnownVars, index, v);
        // save replacement
        repl = BackendVarTransform.addReplacement(repl, cr, e1, NONE());
        replEvaluate = BackendVarTransform.addReplacement(replEvaluate, cr, e1, NONE());
        //  print("Evaluate " + BackendDump.varString(var) + "\n->    " + ExpressionDump.printExpStr(e1) + "\n");
      then ();

    case BackendDAE.VAR(varName = cr,varKind=BackendDAE.PARAM(),values=attr)
      guard
        BackendVariable.varFixed(var)
      equation
        e = DAEUtil.getStartAttrFail(attr);
        // apply replacements
        (e,_) = BackendVarTransform.replaceExp(e, repl, NONE());
        // evaluate expression
        (cache, value) = Ceval.ceval(cache, graph, e, false, Absyn.NO_MSG(),0);
        e1 = ValuesUtil.valueExp(value);
        // also set this var final because it is used for the calculation of another variable
        v = BackendVariable.setVarFinal(var, true);
        // update vararray
        globalKnownVars = BackendVariable.setVarAt(globalKnownVars, index, v);
        // save replacement
        repl = BackendVarTransform.addReplacement(repl, cr, e1, NONE());
        replEvaluate = BackendVarTransform.addReplacement(replEvaluate, cr, e1, NONE());
        //  print("Evaluate " + BackendDump.varString(var) + "\n->    " + ExpressionDump.printExpStr(e1) + "\n");
      then ();

  end match;
end evaluateParameter;


protected function evaluateFixedAttribute
  input output BackendDAE.Var var;
  input Boolean addVar;
  input output BackendDAE.Variables globalKnownVars;
  input BackendDAE.AdjacencyMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input output FCore.Cache cache;
  input FCore.Graph graph;
  input output Integer mark;
  input array<Integer> markarr;
  input Boolean isInitial;
  input output BackendVarTransform.VariableReplacements repl;
algorithm
  (var,globalKnownVars,cache,mark,repl) := match(var)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
      Option<DAE.VariableAttributes> attr;
      BackendDAE.Var v;
      DAE.ElementSource source;
    case BackendDAE.VAR(values= NONE())
      then
        (var,globalKnownVars,cache,mark,repl);
    case BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_REAL(fixed=SOME(DAE.BCONST(_)))))
      then
        (var,globalKnownVars,cache,mark,repl);
    case BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_INT(fixed=SOME(DAE.BCONST(_)))))
      then
        (var,globalKnownVars,cache,mark,repl);
    case BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_BOOL(fixed=SOME(DAE.BCONST(_)))))
      then
        (var,globalKnownVars,cache,mark,repl);
    case BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_ENUMERATION(fixed=SOME(DAE.BCONST(_)))))
      then
        (var,globalKnownVars,cache,mark,repl);
    case BackendDAE.VAR(varName=cr,values=attr as SOME(DAE.VAR_ATTR_REAL(fixed=SOME(e))),source=source)
      equation
        (var,globalKnownVars,cache,mark,repl) = evaluateFixedAttribute1(cr,e,attr,source,var,addVar,globalKnownVars,m,inIEqns,cache,graph,mark,markarr,isInitial,repl);
      then
        (var,globalKnownVars,cache,mark,repl);
    case BackendDAE.VAR(varName=cr,values=attr as SOME(DAE.VAR_ATTR_INT(fixed=SOME(e))),source=source)
      equation
        (var,globalKnownVars,cache,mark,repl) = evaluateFixedAttribute1(cr,e,attr,source,var,addVar,globalKnownVars,m,inIEqns,cache,graph,mark,markarr,isInitial,repl);
      then
        (var,globalKnownVars,cache,mark,repl);
    case BackendDAE.VAR(varName=cr,values=attr as SOME(DAE.VAR_ATTR_BOOL(fixed=SOME(e))),source=source)
      equation
        (var,globalKnownVars,cache,mark,repl) = evaluateFixedAttribute1(cr,e,attr,source,var,addVar,globalKnownVars,m,inIEqns,cache,graph,mark,markarr,isInitial,repl);
      then
        (var,globalKnownVars,cache,mark,repl);
    case BackendDAE.VAR(varName=cr,values=attr as SOME(DAE.VAR_ATTR_ENUMERATION(fixed=SOME(e))),source=source)
      equation
        (var,globalKnownVars,cache,mark,repl) = evaluateFixedAttribute1(cr,e,attr,source,var,addVar,globalKnownVars,m,inIEqns,cache,graph,mark,markarr,isInitial,repl);
      then
        (var,globalKnownVars,cache,mark,repl);
    else (var,globalKnownVars,cache,mark,repl);
  end match;
end evaluateFixedAttribute;


protected function evaluateFixedAttribute1
  input DAE.ComponentRef cr;
  input DAE.Exp e;
  input Option<DAE.VariableAttributes> attr;
  input DAE.ElementSource source;
  input output BackendDAE.Var var;
  input Boolean addVar;
  input output BackendDAE.Variables globalKnownVars;
  input BackendDAE.AdjacencyMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input output FCore.Cache cache;
  input FCore.Graph graph;
  input output Integer mark;
  input array<Integer> markarr;
  input Boolean isInitial;
  input output BackendVarTransform.VariableReplacements repl;
protected
  DAE.Exp e1;
  Boolean b;
  AvlSetInt.Tree ilst;
  Option<DAE.VariableAttributes> attr1;
algorithm
   // apply replacements
  (e1,_) := BackendVarTransform.replaceExp(e, repl, NONE());
  (_,(_,ilst,_)) := Expression.traverseExpTopDown(e1, BackendDAEUtil.traversingadjacencyRowExpFinder, (globalKnownVars,AvlSetInt.EMPTY(), isInitial));
  (globalKnownVars,cache,mark,repl) := evaluateSelectedParameters1(AvlSetInt.listKeys(ilst),globalKnownVars,m,inIEqns,cache,graph,mark,markarr,isInitial,repl);
  (e1,_) := BackendVarTransform.replaceExp(e1, repl, NONE());
  (e1,_) := ExpressionSimplify.simplify(e1);
   b := Expression.isConst(e1);
   e1 := evaluateFixedAttributeReportWarning(b,cr,e,e1,source,globalKnownVars);
   attr1 := DAEUtil.setFixedAttr(attr,SOME(e1));
   var := BackendVariable.setVarAttributes(var,attr1);
   globalKnownVars := if addVar then BackendVariable.addVar(var, globalKnownVars) else globalKnownVars;
end evaluateFixedAttribute1;


protected function evaluateFixedAttributeReportWarning
  input Boolean b;
  input DAE.ComponentRef cr;
  input DAE.Exp e;
  input DAE.Exp e1;
  input DAE.ElementSource source;
  input BackendDAE.Variables globalKnownVars;
  output DAE.Exp outExp;
protected
  String msg;
  SourceInfo info;
algorithm
  if b then
    outExp := e1;
  else
    info := ElementSource.getElementSourceFileInfo(source);
    (outExp, _) := Expression.traverseExpBottomUp(e1, replaceCrefWithBindStartExp, (globalKnownVars,false,HashSet.emptyHashSet()));
    msg := ComponentReference.printComponentRefStr(cr) + " has unevaluateable fixed attribute value \"" + ExpressionDump.printExpStr(e) + "\" use values from start attribute(s) \"" + ExpressionDump.printExpStr(outExp) + "\"";
    Error.addSourceMessage(Error.COMPILER_WARNING, {msg}, info);
  end if;
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
  input BackendDAE.Variables inGlobalKnownVars;
  input BackendDAE.AdjacencyMatrix m;
  input BackendDAE.EquationArray inIEqns;
  input FCore.Cache iCache;
  input FCore.Graph graph;
  input Integer iMark;
  input array<Integer> markarr;
  input BackendVarTransform.VariableReplacements repl;
  input BackendVarTransform.VariableReplacements replEvaluate;
  input Boolean isInitial;
  output BackendDAE.Variables oKnVars;
  output BackendVarTransform.VariableReplacements oRepl;
  output BackendVarTransform.VariableReplacements oReplEvaluate;
  output FCore.Cache oCache;
  output Integer oMark;
algorithm
  (oKnVars,oRepl,oReplEvaluate,oCache,oMark) := match (inComps)
    local
      BackendDAE.Variables globalKnownVars;
      BackendDAE.Var v;
      BackendVarTransform.VariableReplacements repl1,evrepl;
      Integer i,mark;
      list<list<Integer>> rest;
      FCore.Cache cache;
      list<Integer> ilst;

    case {}
    then (inGlobalKnownVars,repl,replEvaluate,iCache,iMark);

    case {i}::rest equation
      v = BackendVariable.getVarAt(inGlobalKnownVars,i);
      (v,globalKnownVars,cache,mark,repl1) = evaluateFixedAttribute(v,true,inGlobalKnownVars,m,inIEqns,iCache,graph,iMark,markarr,isInitial,repl);
      (globalKnownVars,repl1,evrepl) = evaluateParameterBindings(v,i,globalKnownVars,cache,graph,repl1,replEvaluate);
      (globalKnownVars,repl1,evrepl,cache,mark) = traverseParameterSorted(rest,globalKnownVars,m,inIEqns,cache,graph,mark,markarr,repl1,evrepl,isInitial);
    then (globalKnownVars,repl1,evrepl,cache,mark);

    case ilst::rest equation
      // vlst = List.map1r(ilst,BackendVariable.getVarAt,inGlobalKnownVars);
      // str = stringDelimitList(List.map(vlst,BackendDump.varString),"\n");
      // print(stringAppendList({"EvaluateParameter.traverseParameterSorted faild because of strong connected Block in Parameters!\n",str,"\n"}));
      (globalKnownVars,repl1,evrepl,cache,mark) = traverseParameterSorted(List.map(ilst,List.create),inGlobalKnownVars,m,inIEqns,iCache,graph,iMark,markarr,repl,replEvaluate,isInitial);
      (globalKnownVars,repl1,evrepl,cache,mark) = traverseParameterSorted(rest,globalKnownVars,m,inIEqns,cache,graph,mark,markarr,repl1,evrepl,isInitial);
    then (globalKnownVars,repl1,evrepl,cache,mark);
  end match;
end traverseParameterSorted;


protected function evaluateParameterBindings
  input BackendDAE.Var var;
  input Integer index;
  input output BackendDAE.Variables globalKnownVars;
  input FCore.Cache cache;
  input FCore.Graph graph;
  input output BackendVarTransform.VariableReplacements repl;
  input output BackendVarTransform.VariableReplacements replEvaluate;
algorithm
  _ := matchcontinue(var)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      DAE.Exp e;
      list<DAE.Exp> exps;
      Option<DAE.VariableAttributes> attr;
      Values.Value value;
      DAE.Exp hideResultExp;
      Boolean b;

    // Parameter with bind expression
    case v as BackendDAE.VAR(varName = cr, varKind=BackendDAE.PARAM(), bindExp=SOME(e), hideResult=hideResultExp) equation
      // save constant bindings of parameters if parameters are final and fixed
      if Expression.isConst(e) and BackendVariable.isFinalVar(v) and BackendVariable.varFixed(v) then
        // Save all constant bindings of final parameters in replacements
        (repl, replEvaluate) = addConstExpReplacement(e, cr, repl, replEvaluate);
      else
        // apply replacements
        (e, b) = BackendVarTransform.replaceExp(e, replEvaluate, NONE());
        if b then
          (e, _) = ExpressionSimplify.simplify(e);
          // If call with constant arguments then evaluate
          e = match(e)
            local DAE.Exp e1;
            case(DAE.CALL(expLst=exps)) guard Expression.isConstWorkList(exps)
              equation
               (_,value) = Ceval.ceval(cache, graph, e, false, Absyn.NO_MSG(),0);
               e1 = ValuesUtil.valueExp(value);
             then e1;
            case(DAE.ASUB(DAE.CALL(expLst=exps),_)) guard Expression.isConstWorkList(exps)
              equation
               (_,value) = Ceval.ceval(cache, graph, e, false, Absyn.NO_MSG(),0);
               e1 = ValuesUtil.valueExp(value);
             then e1;
            else e;
          end match;
          v = BackendVariable.setBindExp(v, SOME(e));

          // Add evaluated expression if constant to the replacements
          // unless the user suggests not to evaluate the variable with annotation(Evaluate=false)
          if not BackendVariable.hasVarEvaluateAnnotationFalse(v) then
            (repl, replEvaluate) = addConstExpReplacement(e, cr, repl, replEvaluate);
            v = if Expression.isConst(e) then BackendVariable.setVarFinal(v, true) else v;
          end if;
        end if;
      end if;
      // apply replacements in variable attributes
      (attr, (replEvaluate, _)) = BackendDAEUtil.traverseBackendDAEVarAttr(v.values, traverseExpVisitorWrapper, (replEvaluate, false));
      v = BackendVariable.setVarAttributes(v, attr);
      // apply replacements in hideResult attribute
      (hideResultExp, b) = BackendVarTransform.replaceExp(hideResultExp, replEvaluate, NONE());
      if b then
        (hideResultExp, _) = ExpressionSimplify.simplify(hideResultExp);
        v.hideResult = hideResultExp;
      end if;
      globalKnownVars = BackendVariable.setVarAt(globalKnownVars, index, v);
     then ();

    // Parameter without bind expression but with start attribute
    case v as BackendDAE.VAR(varName = cr, varKind=BackendDAE.PARAM(), values=attr, hideResult=hideResultExp) equation
      true = BackendVariable.varFixed(var);
      e = DAEUtil.getStartAttrFail(attr);
      // apply replacements
      (e, b) = BackendVarTransform.replaceExp(e, replEvaluate, NONE());
      if b then
        (e, _) = ExpressionSimplify.simplify(e);
        // If call with constant arguments then evaluate
        e = match(e)
          local DAE.Exp e1;
          case(DAE.CALL(expLst=exps)) guard Expression.isConstWorkList(exps)
            equation
             (_,value) = Ceval.ceval(cache, graph, e, false, Absyn.NO_MSG(),0);
             e1 = ValuesUtil.valueExp(value);
           then e1;
          case(DAE.ASUB(DAE.CALL(expLst=exps),_)) guard Expression.isConstWorkList(exps)
            equation
             (_,value) = Ceval.ceval(cache, graph, e, false, Absyn.NO_MSG(),0);
             e1 = ValuesUtil.valueExp(value);
           then e1;
          else e;
        end match;
        v = BackendVariable.setVarStartValue(var, e);
        (repl, replEvaluate) = addConstExpReplacement(e, cr, repl, replEvaluate);
        v = if Expression.isConst(e) then BackendVariable.setVarFinal(v, true) else v;
      end if;
      // apply replacements in variable attributes
      (attr, (replEvaluate, _)) = BackendDAEUtil.traverseBackendDAEVarAttr(attr, traverseExpVisitorWrapper, (replEvaluate, false));
      v = BackendVariable.setVarAttributes(v, attr);
      // apply replacements in hideResult attribute
      (hideResultExp, b) = BackendVarTransform.replaceExp(hideResultExp, replEvaluate, NONE());
      if b then
        (hideResultExp, _) = ExpressionSimplify.simplify(hideResultExp);
        v.hideResult = hideResultExp;
      end if;
      globalKnownVars = BackendVariable.setVarAt(globalKnownVars, index, v);
     then ();

    // other vars
    case v as BackendDAE.VAR(bindExp=SOME(e), hideResult=hideResultExp) equation
      // apply replacements
      (e, b) = BackendVarTransform.replaceExp(e, replEvaluate, NONE());
      if b then
        (e, _) = ExpressionSimplify.simplify(e);
        // If call with constant arguments then evaluate
        e = match(e)
          local DAE.Exp e1;
          case(DAE.CALL(expLst=exps)) guard Expression.isConstWorkList(exps)
            equation
             (_,value) = Ceval.ceval(cache, graph, e, false, Absyn.NO_MSG(),0);
             e1 = ValuesUtil.valueExp(value);
           then e1;
          case(DAE.ASUB(DAE.CALL(expLst=exps),_)) guard Expression.isConstWorkList(exps)
            equation
             (_,value) = Ceval.ceval(cache, graph, e, false, Absyn.NO_MSG(),0);
             e1 = ValuesUtil.valueExp(value);
           then e1;
          else e;
        end match;
        v = BackendVariable.setBindExp(var, SOME(e));
      end if;
      // apply replacements in variable attributes
      (attr, (replEvaluate, _)) = BackendDAEUtil.traverseBackendDAEVarAttr(v.values, traverseExpVisitorWrapper, (replEvaluate, false));
      v = BackendVariable.setVarAttributes(v, attr);
      // apply replacements in hideResult attribute
      (hideResultExp, b) = BackendVarTransform.replaceExp(hideResultExp, replEvaluate, NONE());
      if b then
        (hideResultExp, _) = ExpressionSimplify.simplify(hideResultExp);
        v.hideResult = hideResultExp;
      end if;
      globalKnownVars = BackendVariable.setVarAt(globalKnownVars, index, v);
     then ();

    case BackendDAE.VAR(values=attr, hideResult=hideResultExp) equation
      // apply replacements
      (attr, (replEvaluate, true)) = BackendDAEUtil.traverseBackendDAEVarAttr(attr, traverseExpVisitorWrapper, (replEvaluate, false));
      v = BackendVariable.setVarAttributes(var, attr);
      // apply replacements in hideResult attribute
      (hideResultExp, b) = BackendVarTransform.replaceExp(hideResultExp, replEvaluate, NONE());
      if b then
        (hideResultExp, _) = ExpressionSimplify.simplify(hideResultExp);
        v.hideResult = hideResultExp;
      end if;
      globalKnownVars = BackendVariable.setVarAt(globalKnownVars, index, v);
     then ();

    else ();

  end matchcontinue;
end evaluateParameterBindings;


protected function addConstExpReplacement
  input DAE.Exp inExp;
  input DAE.ComponentRef cr;
  input output BackendVarTransform.VariableReplacements repl;
  input output BackendVarTransform.VariableReplacements replEvaluate;
algorithm
  if Expression.isConst(inExp) then
    repl := BackendVarTransform.addReplacement(repl, cr, inExp, NONE());
    replEvaluate := BackendVarTransform.addReplacement(replEvaluate, cr, inExp, NONE());
  end if;
end addConstExpReplacement;


protected function traverseExpVisitorWrapper "help function to replaceFinalVarTraverser"
  input DAE.Exp inExp;
  input tuple<BackendVarTransform.VariableReplacements, Boolean> inTpl;
  output DAE.Exp outExp;
  output tuple<BackendVarTransform.VariableReplacements, Boolean> outTpl;
algorithm
  (outExp, outTpl) := match(inExp, inTpl)
    local
      DAE.Exp exp;
      BackendVarTransform.VariableReplacements repl;
      Boolean b, b1;

    case (exp as DAE.CREF(), (repl, b)) equation
      (exp, b1) = BackendVarTransform.replaceExp(exp, repl, NONE());
    then (exp, (repl, b or b1));

    else (inExp, inTpl);
  end match;
end traverseExpVisitorWrapper;


protected function replaceEvaluatedParametersSystem
"author Frenkel TUD"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Variables,BackendDAE.AdjacencyMatrix,BackendDAE.EquationArray,FCore.Cache,FCore.Graph,Integer,array<Integer>,Boolean,BackendVarTransform.VariableReplacements,BackendVarTransform.VariableReplacements> inTypeA;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Variables,BackendDAE.AdjacencyMatrix,BackendDAE.EquationArray,FCore.Cache,FCore.Graph,Integer,array<Integer>,Boolean,BackendVarTransform.VariableReplacements,BackendVarTransform.VariableReplacements> outTypeA;
protected
  BackendDAE.Variables vars;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars) := isyst;
  (vars, outTypeA) := BackendVariable.traverseBackendDAEVarsWithUpdate(vars, replaceEvaluatedParameterTraverser, inTypeA);
  osyst := BackendDAEUtil.setEqSystVars(isyst, vars);
end replaceEvaluatedParametersSystem;

protected function replaceEvaluatedParameterTraverser
"author: Frenkel TUD 2011-04"
 input BackendDAE.Var inVar;
 input tuple<BackendDAE.Variables,BackendDAE.AdjacencyMatrix,BackendDAE.EquationArray,FCore.Cache,FCore.Graph,Integer,array<Integer>,Boolean,BackendVarTransform.VariableReplacements,BackendVarTransform.VariableReplacements> inTpl;
 output BackendDAE.Var outVar;
 output tuple<BackendDAE.Variables,BackendDAE.AdjacencyMatrix,BackendDAE.EquationArray,FCore.Cache,FCore.Graph,Integer,array<Integer>,Boolean,BackendVarTransform.VariableReplacements,BackendVarTransform.VariableReplacements> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Variables globalKnownVars;
      BackendDAE.AdjacencyMatrix m;
      BackendDAE.EquationArray ieqns;
      FCore.Cache cache;
      FCore.Graph graph;
      Integer mark;
      array<Integer> markarr;
      BackendVarTransform.VariableReplacements repl;
      BackendVarTransform.VariableReplacements replEvaluate;
      BackendDAE.Var v;
      DAE.Exp e,e1;
      Option<DAE.VariableAttributes> attr;
      Boolean b, isInitial;
    case (v as BackendDAE.VAR(bindExp=SOME(e),values=attr),(globalKnownVars,m,ieqns,cache,graph,mark,markarr,isInitial,repl,replEvaluate))
      equation
        // apply replacements
        (e1,true) = BackendVarTransform.replaceExp(e, replEvaluate, NONE());
        (e1,_) = ExpressionSimplify.simplify(e1);
        v = BackendVariable.setBindExp(v, SOME(e1));
        (attr,(replEvaluate,b)) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,(replEvaluate,false));
        v = if b then BackendVariable.setVarAttributes(v,attr) else v;
        (v,globalKnownVars,cache,mark,repl) = evaluateFixedAttribute(v,false,globalKnownVars,m,ieqns,cache,graph,mark,markarr,isInitial,repl);
      then (v,(globalKnownVars,m,ieqns,cache,graph,mark,markarr,isInitial,repl,replEvaluate));

    case  (v as BackendDAE.VAR(values=attr),(globalKnownVars,m,ieqns,cache,graph,mark,markarr,isInitial,repl,replEvaluate))
      equation
        // apply replacements
        (attr,(replEvaluate,true)) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,(replEvaluate,false));
        v = BackendVariable.setVarAttributes(v,attr);
        (v,globalKnownVars,cache,mark,repl) = evaluateFixedAttribute(v,false,globalKnownVars,m,ieqns,cache,graph,mark,markarr,isInitial,repl);
      then (v,(globalKnownVars,m,ieqns,cache,graph,mark,markarr,isInitial,repl,replEvaluate));

    case (v,(globalKnownVars,m,ieqns,cache,graph,mark,markarr,isInitial,repl,replEvaluate))
      equation
        (v,globalKnownVars,cache,mark,repl) = evaluateFixedAttribute(v,false,globalKnownVars,m,ieqns,cache,graph,mark,markarr,isInitial,repl);
      then (v,(globalKnownVars,m,ieqns,cache,graph,mark,markarr,isInitial,repl,replEvaluate));
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
    shared.removedEqs :=  BackendEquation.listEquation(lsteqns);
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


annotation(__OpenModelica_Interface="backend");
end EvaluateParameter;
