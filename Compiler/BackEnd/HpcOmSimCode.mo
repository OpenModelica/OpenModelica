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

encapsulated package HpcOmSimCode
" file:        HpcOmSimCode.mo
  package:     HpcOmSimCode
  description: HpcOmSimCode contains the logic to create a parallelized simcode.

  RCS: $Id: HpcOmSimCode.mo 15486 2013-05-24 11:12:35Z marcusw $
"
// public imports
public import Absyn;
public import BackendDAE;
public import DAE;
public import HashTableExpToIndex;
public import SimCode;

// protected imports
protected import BackendDAEOptimize;
protected import BackendDAEUtil;
protected import BackendDump;
protected import Error;
//protected import HpcOmScheduler;
protected import HpcOmTaskGraph;
protected import Initialization;
protected import InlineSolver;
protected import List;
protected import SimCodeUtil;
protected import Util;

public function createSimCode "entry point to create SimCode from BackendDAE."
  input BackendDAE.BackendDAE inBackendDAE;
  input Absyn.Path inClassName;
  input String filenamePrefix;
  input String inString11;
  input list<SimCode.Function> functions;
  input list<String> externalFunctionIncludes;
  input list<String> includeDirs;
  input list<String> libs;
  input Option<SimCode.SimulationSettings> simSettingsOpt;
  input list<SimCode.RecordDeclaration> recordDecls;
  input tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> literals;
  input Absyn.FunctionArgs args;
  output SimCode.SimCode simCode;
algorithm
  simCode := matchcontinue (inBackendDAE, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs, simSettingsOpt, recordDecls, literals, args)
    local
      String fileDir, cname;
      Integer lastEqMappingIdx, maxDelayedExpIndex, uniqueEqIndex, numberofEqns, numberOfInitialEquations, numberOfInitialAlgorithms, numStateSets;
      Integer numberofLinearSys, numberofNonLinearSys, numberofMixedSys;
      BackendDAE.BackendDAE dlow, dlow2;
      Option<BackendDAE.BackendDAE> initDAE;
      DAE.FunctionTree functionTree;
      BackendDAE.SymbolicJacobians symJacs;
      Absyn.Path class_;
      
      // new variables
      SimCode.ModelInfo modelInfo;
      list<SimCode.SimEqSystem> allEquations;
      list<list<SimCode.SimEqSystem>> odeEquations;         // --> functionODE
      list<list<SimCode.SimEqSystem>> algebraicEquations;   // --> functionAlgebraics
      list<SimCode.SimEqSystem> residuals;                  // --> initial_residual
      Boolean useSymbolicInitialization;                    // true if a system to solve the initial problem symbolically is generated, otherwise false
      Boolean useHomotopy;                                  // true if homotopy(...) is used during initialization
      list<SimCode.SimEqSystem> initialEquations;           // --> initial_equations
      list<SimCode.SimEqSystem> startValueEquations;        // --> updateBoundStartValues
      list<SimCode.SimEqSystem> parameterEquations;         // --> updateBoundParameters
      list<SimCode.SimEqSystem> inlineEquations;            // --> inline solver
      list<SimCode.SimEqSystem> removedEquations;
      list<SimCode.SimEqSystem> algorithmAndEquationAsserts;
      //list<DAE.Statement> algorithmAndEquationAsserts;
      list<DAE.Constraint> constraints;
      list<DAE.ClassAttributes> classAttributes;
      list<BackendDAE.ZeroCrossing> zeroCrossings, sampleZC, relations;
      list<SimCode.SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
      SimCode.ExtObjInfo extObjInfo;
      SimCode.MakefileParams makefileParams;
      SimCode.DelayedExpression delayedExps;
      BackendDAE.Variables knownVars;
      list<BackendDAE.Var> varlst;

      list<SimCode.JacobianMatrix> LinearMatrices, SymbolicJacs, SymbolicJacsTemp, SymbolicJacsStateSelect;
      SimCode.HashTableCrefToSimVar crefToSimVarHT;
      Boolean ifcpp;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      BackendDAE.EquationArray removedEqs;
      array<DAE.Constraint> constrsarr;
      array<DAE.ClassAttributes> clsattrsarra;

      list<DAE.Exp> lits;
      list<SimCode.SimVar> tempvars;
      
      SimCode.JacobianMatrix jacG;
      Integer highestSccIdx, compCountPlusDummy;
      Option<BackendDAE.BackendDAE> inlineDAE;
      list<SimCode.StateSet> stateSets;
      array<Integer> systemIndexMap;
      list<tuple<Integer,Integer>> equationSccMapping, equationSccMapping1; //Maps each simEq to the scc
      array<list<Integer>> sccSimEqMapping; //Maps each scc to a list of simEqs
      array<Integer> simEqSccMapping; //Maps each simEq to the scc
      BackendDAE.SampleLookup sampleLookup;
      BackendDAE.StrongComponents allComps;
      
      HpcOmTaskGraph.TaskGraph taskGraph;  
      HpcOmTaskGraph.TaskGraph taskGraphOde;
      HpcOmTaskGraph.TaskGraph taskGraph1;  
      HpcOmTaskGraph.TaskGraphMeta taskGraphData;
      HpcOmTaskGraph.TaskGraphMeta taskGraphDataOde;
      String fileName, fileNamePrefix;
      HpcOmTaskGraph.TaskGraphMeta taskGraphData1;
      list<list<Integer>> parallelSets;
      list<list<Integer>> criticalPaths;
      Real cpCosts;
      SimCode.HpcOmParInformation hpcOmParInformation; 
      
      //Additional informations to append SimCode
      list<DAE.Exp> simCodeLiterals;
      list<SimCode.JacobianMatrix> jacobianMatrixes;
      list<SimCode.SimEqSystem> residualEquations;
      Option<SimCode.SimulationSettings> simulationSettingsOpt;
      list<SimCode.RecordDeclaration> simCodeRecordDecls;
      list<String> simCodeExternalFunctionIncludes;
      
      Boolean taskGraphMetaValid;
      String taskGraphMetaMessage, criticalPathInfo;
      
    case (_, _, _, _, _, _, _, _, _, _, _, _) equation
      uniqueEqIndex = 1;

      (simCode,(lastEqMappingIdx,equationSccMapping)) = SimCodeUtil.createSimCode(inBackendDAE, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs, simSettingsOpt, recordDecls, literals, args);
      (allComps,_) = HpcOmTaskGraph.getSystemComponents(inBackendDAE);
      //print("createSimCode with " +& intString(listLength(allComps)) +& " Components\n");
      highestSccIdx = findHighestSccIdxInMapping(equationSccMapping,-1);
      compCountPlusDummy = listLength(allComps)+1;
      equationSccMapping1 = removeDummyStateFromMapping(equationSccMapping);
      //the mapping can contain a dummy state as first scc
      equationSccMapping = Util.if_(intEq(highestSccIdx, compCountPlusDummy), equationSccMapping1, equationSccMapping);
      
      sccSimEqMapping = convertToSccSimEqMapping(equationSccMapping, listLength(allComps));
      simEqSccMapping = convertToSimEqSccMapping(equationSccMapping, lastEqMappingIdx);

      //dumpSccSimEqMapping(sccSimEqMapping);
      
      //Create TaskGraph
      (taskGraph,taskGraphData) = HpcOmTaskGraph.createTaskGraph(inBackendDAE,filenamePrefix);
      //Append the costs to the taskGraphMeta
      taskGraphData = HpcOmTaskGraph.createCosts(inBackendDAE, filenamePrefix +& "_prof.xml" , simEqSccMapping, taskGraphData);
      //HpcOmTaskGraph.printTaskGraph(taskGraph);
      //taskGraph1 = HpcOmTaskGraph.transposeTaskGraph(taskGraph);
      //HpcOmTaskGraph.printTaskGraph(taskGraph1);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphData);  
                 
      //compute critical path on cost-level and determine the level of the node
      (criticalPaths,cpCosts,parallelSets) = HpcOmTaskGraph.longestPathMethod(taskGraph,taskGraphData);
      criticalPathInfo = HpcOmTaskGraph.dumpCriticalPathInfo(criticalPaths,cpCosts);
                 
      fileName = ("taskGraph"+&filenamePrefix+&".graphml");    
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraph, taskGraphData, fileName, criticalPathInfo, sccSimEqMapping);
      
      // get the task graph for the ODEsystem
      taskGraphOde = arrayCopy(taskGraph);
      taskGraphDataOde = HpcOmTaskGraph.copyTaskGraphMeta(taskGraphData);
      (taskGraphOde,taskGraphDataOde) = HpcOmTaskGraph.getOdeSystem(taskGraphOde,taskGraphDataOde,inBackendDAE,filenamePrefix);
      
      taskGraphMetaValid = HpcOmTaskGraph.validateTaskGraphMeta(taskGraphDataOde, inBackendDAE);
      taskGraphMetaMessage = Util.if_(taskGraphMetaValid, "TaskgraphMeta valid\n", "TaskgraphMeta invalid\n");
      print(taskGraphMetaMessage);
      //print("ODE-TASKGRAPH\n");
 
      //HpcOmTaskGraph.printTaskGraph(taskGraphOde);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphDataOde); 
      
      (criticalPaths,cpCosts,parallelSets) = HpcOmTaskGraph.longestPathMethod(taskGraphOde,taskGraphDataOde);
      criticalPathInfo = HpcOmTaskGraph.dumpCriticalPathInfo(criticalPaths,cpCosts);
      
      fileName = ("taskGraph"+&filenamePrefix+&"ODE.graphml");       
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraphOde, taskGraphDataOde, fileName, criticalPathInfo, sccSimEqMapping);  
            
      // filter to merge simple nodes (i.e. nodes with only 1 predecessor and 1 successor)
      //taskGraph1 = arrayCopy(taskGraphOde);
      //taskGraphData1 = HpcOmTaskGraph.copyTaskGraphMeta(taskGraphDataOde);
      //(taskGraph,taskGraphData) = HpcOmTaskGraph.mergeSimpleNodes(taskGraph1,taskGraphData1,inBackendDAE,filenamePrefix);
      //print("MERGED GRAPH\n");
      //HpcOmTaskGraph.printTaskGraph(taskGraph);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphData);  
      //HpcOmTaskGraph.printTaskGraph(taskGraphOde);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphDataOde);  
      //fileName = ("taskGraph"+&filenamePrefix+&"ODE.graphml");       
      //HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraphOde, taskGraphDataOde, fileName);

      hpcOmParInformation = createParInformation(taskGraphDataOde, sccSimEqMapping);
      
      //print("Parallel informations:\n");
      //printParInformation(hpcOmParInformation);
      
      SimCode.SIMCODE(modelInfo, simCodeLiterals, simCodeRecordDecls, simCodeExternalFunctionIncludes, allEquations, odeEquations, algebraicEquations, residualEquations, useSymbolicInitialization, useHomotopy, initialEquations, startValueEquations, 
                 parameterEquations, inlineEquations, removedEquations, algorithmAndEquationAsserts, stateSets, constraints, classAttributes, zeroCrossings, relations, sampleLookup, whenClauses, 
                 discreteModelVars, extObjInfo, makefileParams, delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, crefToSimVarHT, _) = simCode;

      HpcOmTaskGraph.checkOdeSystemSize(taskGraphOde,odeEquations);

      simCode = SimCode.SIMCODE(modelInfo, simCodeLiterals, simCodeRecordDecls, simCodeExternalFunctionIncludes, allEquations, odeEquations, algebraicEquations, residualEquations, useSymbolicInitialization, useHomotopy, initialEquations, startValueEquations, 
                 parameterEquations, inlineEquations, removedEquations, algorithmAndEquationAsserts, stateSets, constraints, classAttributes, zeroCrossings, relations, sampleLookup, whenClauses, 
                 discreteModelVars, extObjInfo, makefileParams, delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, crefToSimVarHT, SOME(hpcOmParInformation));
      
      print("HpcOm is still under construction.\n");
      then simCode;
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/HpcSimCode.mo: function createSimCode failed."});
    then fail();
  end matchcontinue;
end createSimCode;


protected function createSimEqToSccMapping "author: marcusw
  This methods is the same as the first part of the createSimCode-Method. 
  It returns a mapping between the scc-indices and the created simEq-Indices."
  input BackendDAE.BackendDAE inBackendDAE;
  output list<tuple<Integer,Integer>> oMapping; //The mapping simEq-Index -> scc-Index
  output Integer lastIndex; //The highest simEqIndex in the mapping
algorithm
  (oMapping,lastIndex) := matchcontinue (inBackendDAE)
    local
      Integer  maxDelayedExpIndex, uniqueEqIndex, numberofEqns, numberOfInitialEquations, numberOfInitialAlgorithms, numStateSets;

      DAE.FunctionTree functionTree;
      BackendDAE.SymbolicJacobians symJacs;
      
      // new variables
      list<SimCode.SimEqSystem> initialEquations;           // --> initial_equations
      list<SimCode.SimEqSystem> startValueEquations;        // --> updateBoundStartValues
      list<SimCode.SimEqSystem> parameterEquations;         // --> updateBoundParameters
      list<SimCode.SimEqSystem> inlineEquations;            // --> inline solver
      list<SimCode.SimEqSystem> removedEquations;
      list<SimCode.SimEqSystem> algorithmAndEquationAsserts;
      //list<DAE.Statement> algorithmAndEquationAsserts;
      list<DAE.ClassAttributes> classAttributes;
      list<SimCode.SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
      SimCode.ExtObjInfo extObjInfo;
      SimCode.MakefileParams makefileParams;
      BackendDAE.Variables knownVars;
      list<BackendDAE.Var> varlst;

      BackendDAE.BackendDAE dlow;
      Option<BackendDAE.BackendDAE> initDAE;
      Option<BackendDAE.BackendDAE> inlineDAE;
      BackendDAE.EquationArray removedEqs;    
      list<DAE.Constraint> constraints;
      list<SimCode.SimVar> tempvars;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      list<tuple<Integer,Integer>> equationSccMapping;
      array<DAE.Constraint> constrsarr;
      array<DAE.ClassAttributes> clsattrsarra;
      SimCode.JacobianMatrix jacG;
      
    case (dlow) equation
      uniqueEqIndex = 1;
      
      // generate initDAE before replacing pre(alias)!
      (initDAE, _) = Initialization.solveInitialSystem(dlow);

      // replace pre(alias) in time-equations
      dlow = BackendDAEOptimize.simplifyTimeIndepFuncCalls(dlow);

      // generate system for inline solver
      (inlineDAE, _) = InlineSolver.generateDAE(dlow);

      // check if the Sytems has states
      dlow = BackendDAEUtil.addDummyStateIfNeeded(dlow);

      BackendDAE.DAE(systs, shared as BackendDAE.SHARED(removedEqs=removedEqs, 
                                                        constraints=constrsarr, 
                                                        classAttrs=clsattrsarra, 
                                                        functionTree=functionTree, 
                                                        symjacs=symJacs)) = dlow;
      
      //extObjInfo = createExtObjInfo(shared);

      //whenClauses = createSimWhenClauses(dlow);
      //zeroCrossings = Util.if_(ifcpp, getRelations(dlow), getZeroCrossings(dlow));
      //relations = getRelations(dlow);
      //sampleZC = getSamples(dlow);
      //zeroCrossings = Util.if_(ifcpp, listAppend(zeroCrossings, sampleZC), zeroCrossings);

      // state set stuff
      tempvars = {};
      (dlow, _, uniqueEqIndex, tempvars, numStateSets) = SimCodeUtil.createStateSets(dlow, {}, uniqueEqIndex, tempvars);

      // inline solver stuff
      (inlineEquations, uniqueEqIndex, tempvars) = SimCodeUtil.createInlineSolverEqns(inlineDAE, uniqueEqIndex, tempvars);

      // initialization stuff
      (_, initialEquations, numberOfInitialEquations, numberOfInitialAlgorithms, uniqueEqIndex, tempvars, _) = SimCodeUtil.createInitialResiduals(dlow, initDAE, uniqueEqIndex, tempvars);
      (jacG, uniqueEqIndex) = SimCodeUtil.createInitialMatrices(dlow, uniqueEqIndex);

      // addInitialStmtsToAlgorithms
      dlow = BackendDAEOptimize.addInitialStmtsToAlgorithms(dlow);
      
      BackendDAE.DAE(systs, shared as BackendDAE.SHARED(removedEqs=removedEqs, 
                                                        constraints=constrsarr, 
                                                        classAttrs=clsattrsarra, 
                                                        functionTree=functionTree, 
                                                        symjacs=symJacs)) = inBackendDAE; //dlow

      // equation generation for euler, dassl2, rungekutta
      (uniqueEqIndex, _, _, _, tempvars, equationSccMapping) = SimCodeUtil.createEquationsForSystems(systs, shared, uniqueEqIndex, {}, {}, {}, tempvars, 1, {});    
      then (equationSccMapping,uniqueEqIndex);
    else then fail();
  end matchcontinue;

end createSimEqToSccMapping;

protected function convertToSccSimEqMapping "author: marcusw
  Converts the given mapping (simEqIndex -> sccIndex) to the inverse mapping (sccIndex->simEqIndex)."
  input list<tuple<Integer,Integer>> iMapping; //the mapping (simEqIndex -> sccIndex)
  input Integer numOfSccs; //important for arrayCreate
  output array<list<Integer>> oMapping; //the created mapping (sccIndex->simEqIndex)
  
protected
  array<list<Integer>> tmpMapping;

algorithm
  tmpMapping := arrayCreate(numOfSccs,{});
  //print("convertToSccSimEqMapping with " +& intString(numOfSccs) +& " sccs.\n");
  _ := List.fold(iMapping, convertToSccSimEqMapping1, tmpMapping);
  oMapping := tmpMapping;
  
end convertToSccSimEqMapping;

protected function convertToSccSimEqMapping1 "author: marcusw
  Helper function for convertToSccSimEqMapping. It will update the arrayIndex of the given mapping value."
  input tuple<Integer,Integer> iMapping; //<simEqIdx,sccIdx>
  input array<list<Integer>> iSccMapping;
  output array<list<Integer>> oSccMapping;
  
protected
  Integer i1,i2;
  List<Integer> tmpList;
  
algorithm
  (i1,i2) := iMapping;
  //print("convertToSccSimEqMapping1 accessing index " +& intString(i2) +& ".\n");
  tmpList := arrayGet(iSccMapping,i2);
  tmpList := i1 :: tmpList;
  oSccMapping := arrayUpdate(iSccMapping,i2,tmpList);
  
end convertToSccSimEqMapping1;

protected function convertToSimEqSccMapping "author: marcusw
  Converts the given mapping (simEqIndex -> sccIndex) bases on tuples to an array mapping."
  input list<tuple<Integer,Integer>> iMapping; //<simEqIdx,sccIdx>
  input Integer numOfSimEqs;
  output array<Integer> oMapping; //maps each simEq to the scc
  
protected
  array<Integer> tmpMapping;
  
algorithm
  tmpMapping := arrayCreate(numOfSimEqs, -1);
  oMapping := List.fold(iMapping, convertToSimEqSccMapping1, tmpMapping);
end convertToSimEqSccMapping;

protected function convertToSimEqSccMapping1 "author: marcusw
  Helper function for convertToSimEqSccMapping. It will update the array at the given index."
  input tuple<Integer,Integer> iSimEqTuple; //<simEqIdx,sccIdx>
  input array<Integer> iMapping;
  output array<Integer> oMapping;
 
protected
  Integer simEqIdx,sccIdx;
  
algorithm
  (simEqIdx,sccIdx) := iSimEqTuple;
  //print("convertToSimEqSccMapping1 " +& intString(simEqIdx) +& " .. " +& intString(sccIdx) +& " iMapping_len: " +& intString(arrayLength(iMapping)) +& "\n");
  oMapping := arrayUpdate(iMapping,simEqIdx,sccIdx);
end convertToSimEqSccMapping1;

protected function dumpSccSimEqMapping "author: marcusw
  Prints the given mapping out to the console."
  input array<list<Integer>> iSccMapping;
 
protected
  String text;
  
algorithm
  text := "SccToSimEqMapping";
  ((_,text)) := Util.arrayFold(iSccMapping, dumpSccSimEqMapping1, (1,text));
  print(text +& "\n");
end dumpSccSimEqMapping;

protected function dumpSccSimEqMapping1 "author: marcusw
  Helper function of dumpSccSimEqMapping to print one mapping list."
  input list<Integer> iMapping;
  input tuple<Integer,String> iIndexText;
  output tuple<Integer,String> oIndexText;

protected
  Integer iIndex;
  String text, iText;
  
algorithm
  (iIndex,iText) := iIndexText;
  text := List.fold(iMapping, dumpSccSimEqMapping2, " ");
  text := iText +& "\nSCC " +& intString(iIndex) +& ": {" +& text +& "}";
  oIndexText := (iIndex+1,text);
end dumpSccSimEqMapping1;

protected function dumpSccSimEqMapping2 "author: marcusw
  Helper function of dumpSccSimEqMapping1 to print one mapping element."
  input Integer iIndex;
  input String iText;
  output String oText;
  
algorithm
  oText := iText +& intString(iIndex) +& " ";
   
end dumpSccSimEqMapping2;

public function getSimCodeEqByIndex "author: marcusw
  Returns the SimEqSystem which has the given Index. This method is called from susan."
  input list<SimCode.SimEqSystem> iEqs; //All SimEqSystems
  input Integer iIdx; //The index of the wanted system
  output SimCode.SimEqSystem oEq;

protected
  list<SimCode.SimEqSystem> rest;
  SimCode.SimEqSystem head;
  Integer headIdx;

algorithm
  oEq := matchcontinue(iEqs,iIdx)
    case(head::rest,_)
      equation
        headIdx = getIndexBySimCodeEq(head);
        //print("getSimCodeEqByIndex listLength: " +& intString(listLength(iEqs)) +& " head idx: " +& intString(headIdx) +& "\n");
        true = intEq(headIdx,iIdx);
      then head;
    case(head::rest,_) then getSimCodeEqByIndex(rest,iIdx);
    else
      equation
        print("getSimCodeEqByIndex failed. Looking for Index " +& intString(iIdx) +& "\n");
      then fail();
  end matchcontinue;
end getSimCodeEqByIndex;

protected function getIndexBySimCodeEq "author: marcusw
  Just a small helper function to get the index of a SimEqSystem."
  input SimCode.SimEqSystem iEq;
  output Integer oIdx;

protected
  Integer index;

algorithm
  oIdx := match(iEq)
    case(SimCode.SES_RESIDUAL(index=index)) then index;
    case(SimCode.SES_SIMPLE_ASSIGN(index=index)) then index;
    case(SimCode.SES_ARRAY_CALL_ASSIGN(index=index)) then index;
    case(SimCode.SES_IFEQUATION(index=index)) then index;
    case(SimCode.SES_ALGORITHM(index=index)) then index;
    case(SimCode.SES_LINEAR(index=index)) then index;
    case(SimCode.SES_NONLINEAR(index=index)) then index;
    case(SimCode.SES_MIXED(index=index)) then index;
    case(SimCode.SES_WHEN(index=index)) then index;
    else then fail();
  end match;
end getIndexBySimCodeEq;

public function analyzeOdeEquations
  input list<list<SimCode.SimEqSystem>> systems;
algorithm
  _ := List.fold(systems, analyzeOdeEquations1, 1);
end analyzeOdeEquations;

protected function analyzeOdeEquations1
  input list<SimCode.SimEqSystem> iEqs;
  input Integer iLevel;
  output Integer oLevel;
algorithm
  print("Equation level " +& intString(iLevel) +& "\n");
  _ := List.fold(iEqs,analyzeOdeEquations2,1);
  oLevel := iLevel + 1;
end analyzeOdeEquations1;

protected function analyzeOdeEquations2
  input SimCode.SimEqSystem iEq;
  input Integer iEqIndex;
  output Integer oEqIndex;
protected
  Integer simEqIdx;
algorithm
  simEqIdx := getIndexBySimCodeEq(iEq);
  print("Equation " +& intString(simEqIdx) +& "\n");
  oEqIndex := iEqIndex + 1;
end analyzeOdeEquations2;

protected function printParInformation "author: marcusw
  Prints the given parallel informations out to the console."
  input SimCode.HpcOmParInformation iParInfo;

protected
  list<list<Integer>> eqsOfLevels;

algorithm
  _ := match(iParInfo)
    case(SimCode.HPCOMPARINFORMATION(eqsOfLevels=eqsOfLevels))
     equation
       _ = List.fold(eqsOfLevels,printParInformationLevel,1);
     then ();
     else
      equation
        print("PrintParInformation failed\n");
      then fail();
  end match;
end printParInformation;

protected function printParInformationLevel "author: marcusw
  Helper function of printParInformation to print one level."
  input list<Integer> iLevelInfo;
  input Integer iLevel;
  output Integer oLevel;
  
algorithm
  print("Level " +& intString(iLevel) +& ":\n");
  _ := List.fold(iLevelInfo,printParInformationLevel1,1);
  oLevel := iLevel + 1;
end printParInformationLevel;

protected function printParInformationLevel1 "author: marcusw
  Helper function of printParInformationLevel1 to print one equation."
  input Integer iEquation;
  input Integer iLevel;
  output Integer oLevel;
  
algorithm
  print("\t Equation " +& intString(iEquation) +& "\n");
  oLevel := iLevel + 1;
end printParInformationLevel1;

protected function createParInformation "author: marcusw
  Creates the hpcomParInformation-structure."
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  output SimCode.HpcOmParInformation oParInfo;
 
protected
  array<list<Integer>> inComps;
  array<Integer> nodeMark;
  list<tuple<Integer,list<Integer>>> tmpSimEqLevelMapping; //maps the level-index to the equations
  list<list<Integer>> flatSimEqLevelMapping;
algorithm
  oParInfo := match(iMeta,iSccSimEqMapping)
    case(HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,nodeMark=nodeMark),_)
      equation
        tmpSimEqLevelMapping = createParInformation0(1,inComps,iSccSimEqMapping,nodeMark,{});
        //sorting
        tmpSimEqLevelMapping = List.sort(tmpSimEqLevelMapping, sortParInfo);
        //flattening
        flatSimEqLevelMapping = List.map(tmpSimEqLevelMapping, Util.tuple22);
      then SimCode.HPCOMPARINFORMATION(flatSimEqLevelMapping);
    else 
      equation
        print("CreateParInformation failed.");
    then fail();
  end match;
end createParInformation;

protected function createParInformation0 "author: marcusw
  Helper function of createParInformation. It extends the levelMapping-structure with the informations of the given node (iNodeIdx)."
  input Integer iNodeIdx;
  input array<list<Integer>> iComps;
  input array<list<Integer>> iSccSimEqMapping;
  input array<Integer> iNodeMarks;
  input list<tuple<Integer,list<Integer>>> iSimEqLevelMapping;
  output list<tuple<Integer,list<Integer>>> oSimEqLevelMapping;
  
protected
  list<Integer> sccSimEqMapping, nodeComps;
  Integer nodeMark;
  Integer mapListIndex;
  Integer firstNodeComp;
  list<Integer> eqList;
  list<tuple<Integer,list<Integer>>> tmpSimEqLevelMapping;
algorithm
  oSimEqLevelMapping := matchcontinue(iNodeIdx,iComps,iSccSimEqMapping,iNodeMarks,iSimEqLevelMapping)
    case(_,_,_,_,_)
      equation
        true = intGe(arrayLength(iComps),iNodeIdx);
        nodeComps = arrayGet(iComps,iNodeIdx);
        true = intEq(listLength(nodeComps), 1);
        firstNodeComp = List.first(nodeComps);
        true = intGe(arrayLength(iSccSimEqMapping), firstNodeComp);
        //sccSimEqMapping = arrayGet(iSccSimEqMapping,firstNodeComp);
        nodeMark = arrayGet(iNodeMarks,firstNodeComp);
        //print("createParInformation0 with nodeIdx " +& intString(iNodeIdx) +& " representing component " +& intString(firstNodeComp) +& " and nodeMark " +& intString(nodeMark) +& "\n");
        true = intGe(nodeMark,0);
        (tmpSimEqLevelMapping,eqList,mapListIndex) = getLevelListByLevel(nodeMark,1,iSimEqLevelMapping,iSimEqLevelMapping);
        eqList = List.fold1(nodeComps, createParInformation1, iSccSimEqMapping, eqList);
        tmpSimEqLevelMapping = List.replaceAt((nodeMark, eqList),mapListIndex-1,tmpSimEqLevelMapping);
      then createParInformation0(iNodeIdx+1,iComps,iSccSimEqMapping,iNodeMarks,tmpSimEqLevelMapping);
    case(_,_,_,_,_)
      equation
        true = intGe(arrayLength(iComps),iNodeIdx);
        nodeComps = arrayGet(iComps,iNodeIdx);
        true = intEq(listLength(nodeComps), 1);
        true = intGe(arrayLength(iSccSimEqMapping), iNodeIdx); 
      then createParInformation0(iNodeIdx+1,iComps,iSccSimEqMapping,iNodeMarks,iSimEqLevelMapping);
    case(_,_,_,_,_)
      equation
        true = intGe(arrayLength(iComps),iNodeIdx);
        nodeComps = arrayGet(iComps,iNodeIdx);
        false = intEq(listLength(nodeComps), 1);
        true = intGe(arrayLength(iSccSimEqMapping), iNodeIdx); 
        print("CreateParInformation0: contracted nodes are currently not supported\n");
      then fail();
    else 
      then iSimEqLevelMapping;
  end matchcontinue;
end createParInformation0;

protected function createParInformation1 "author: marcusw
  Helper function of createParInformation. This method will grab the simEqIndex of the given component and extend the iList."
  input Integer iCompIdx;
  input array<list<Integer>> iSccSimEqMapping;
  input list<Integer> iList;
  output list<Integer> oList;
  
protected 
  list<Integer> simEqIdc;
  Integer lastSimEqIdx;
  
algorithm
  simEqIdc := arrayGet(iSccSimEqMapping,iCompIdx);
  lastSimEqIdx := List.last(simEqIdc);
  oList := lastSimEqIdx::iList;
  //oList := listAppend(iList,simEqIdc);
end createParInformation1;

protected function getLevelListByLevel "author: marcusw
  Returns the level list of the searched index. If no level with the given index was found, a new list is appended to the mapping."
  input Integer iLevel;
  input Integer iCurrentListIndex;
  input list<tuple<Integer,list<Integer>>> restList;
  input list<tuple<Integer,list<Integer>>> iSimEqLevelMapping; //list<<levelIndex,levelList>>
  output list<tuple<Integer,list<Integer>>> oSimEqLevelMapping;
  output list<Integer> oEqList;
  output Integer oMapListIndex; 
  
protected
  Integer curLevel, headIdx;
  list<Integer> curLevelEqs, headList;
  list<tuple<Integer,list<Integer>>> rest;
  tuple<Integer,list<Integer>> newElem;
  
  list<tuple<Integer,list<Integer>>> tmpSimEqLevelMapping;
  list<Integer> tmpEqList;
  Integer tmpMapListIndex;
algorithm
  (oSimEqLevelMapping,oEqList,oMapListIndex) := matchcontinue(iLevel,iCurrentListIndex,restList,iSimEqLevelMapping)
    case(_,_,(headIdx,headList)::rest,_)
      equation
        true = intEq(headIdx,iLevel);
      then (iSimEqLevelMapping,headList,iCurrentListIndex);
    case(_,_,(headIdx,headList)::rest,_)
      equation 
         (tmpSimEqLevelMapping,tmpEqList,tmpMapListIndex) = getLevelListByLevel(iLevel,iCurrentListIndex+1,rest,iSimEqLevelMapping);
      then (tmpSimEqLevelMapping,tmpEqList,tmpMapListIndex);
    else
      equation
        newElem = (iLevel,{});
      then (newElem::iSimEqLevelMapping,{},1);
   end matchcontinue;
end getLevelListByLevel;

protected function sortParInfo "author: marcusw
  Use this function to sort a level list. The result is true if index1 > index2."
  input tuple<Integer,list<Integer>> iTuple1; //<index1,_>
  input tuple<Integer,list<Integer>> iTuple2; //<index2,_>
  output Boolean oResult;
  
protected
  Integer index1,index2;
  
algorithm
  (index1,_) := iTuple1;
  (index2,_) := iTuple2;
  oResult := intGt(index1,index2);
end sortParInfo;

protected function findHighestSccIdxInMapping "author: marcusw
  Find the highest scc-index in the mapping list."
  input list<tuple<Integer,Integer>> iEquationSccMapping; //<simEqIdx,sccIdx>
  input Integer iHighestIndex;
  output Integer oIndex;

protected
  Integer eqIdx, sccIdx;
  list<tuple<Integer,Integer>> rest;
algorithm
  oIndex := matchcontinue(iEquationSccMapping,iHighestIndex)
    case((eqIdx,sccIdx)::rest,_)
      equation
        true = intGt(sccIdx,iHighestIndex);
      then findHighestSccIdxInMapping(rest,sccIdx);
    case((eqIdx,sccIdx)::rest,_)
      then findHighestSccIdxInMapping(rest,iHighestIndex);
    else
      then iHighestIndex;
  end matchcontinue;
end findHighestSccIdxInMapping;

protected function removeDummyStateFromMapping "author: marcusw
  Removes all mappings with sccIdx=1 from the list and decrements all other scc-indices by 1."
  input list<tuple<Integer,Integer>> iEquationSccMapping;
  output list<tuple<Integer,Integer>> oEquationSccMapping;
algorithm
  oEquationSccMapping := List.fold(iEquationSccMapping, removeDummyStateFromMapping1, {});
end removeDummyStateFromMapping;

protected function removeDummyStateFromMapping1 "author: marcusw
  Helper function of removeDummyStateFromMapping. Handles one list-element."
  input tuple<Integer,Integer> iTuple; //<eqIdx,sccIdx>
  input list<tuple<Integer,Integer>> iNewList;
  output list<tuple<Integer,Integer>> oNewList;
protected
  Integer eqIdx,sccIdx;
  tuple<Integer,Integer> newElem;
algorithm
  oNewList := matchcontinue(iTuple,iNewList)
    case((eqIdx,sccIdx),_)
      equation
        true = intEq(sccIdx,1);
      then iNewList;
    case((eqIdx,sccIdx),_)
      equation
        newElem = (eqIdx,sccIdx-1);
      then newElem::iNewList;
    else
      equation
        print("removeDummyStateFromMapping1 failed\n");
    then iNewList;
  end matchcontinue;
end removeDummyStateFromMapping1;

end HpcOmSimCode;