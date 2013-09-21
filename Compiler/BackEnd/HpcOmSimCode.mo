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
protected import Error;
protected import Flags;
protected import HpcOmScheduler;
protected import HpcOmTaskGraph;
protected import List;
protected import SimCodeUtil;
protected import Util;

public function createSimCode "function createSimCode
  entry point to create SimCode from BackendDAE."
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
      
      //Additional informations to append SimCode
      list<DAE.Exp> simCodeLiterals;
      list<SimCode.JacobianMatrix> jacobianMatrixes;
      list<SimCode.SimEqSystem> residualEquations;
      Option<SimCode.SimulationSettings> simulationSettingsOpt;
      list<SimCode.RecordDeclaration> simCodeRecordDecls;
      list<String> simCodeExternalFunctionIncludes;
      
      Boolean taskGraphMetaValid;
      String taskGraphMetaMessage, criticalPathInfo;
      array<tuple<Integer,Integer>> schedulerInfo;
      HpcOmScheduler.Schedule schedule;
      HpcOmScheduler.ScheduleSimCode taskScheduleSimCode;
      
    case (_, _, _, _, _, _, _, _, _, _, _, _) equation
      uniqueEqIndex = 1;

      //Setup
      //-----
      (simCode,(lastEqMappingIdx,equationSccMapping)) = SimCodeUtil.createSimCode(inBackendDAE, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs, simSettingsOpt, recordDecls, literals, args);
      (allComps,_) = HpcOmTaskGraph.getSystemComponents(inBackendDAE);
      highestSccIdx = findHighestSccIdxInMapping(equationSccMapping,-1);
      compCountPlusDummy = listLength(allComps)+1;
      equationSccMapping1 = removeDummyStateFromMapping(equationSccMapping);
      //the mapping can contain a dummy state as first scc
      equationSccMapping = Util.if_(intEq(highestSccIdx, compCountPlusDummy), equationSccMapping1, equationSccMapping);
      
      sccSimEqMapping = convertToSccSimEqMapping(equationSccMapping, listLength(allComps));
      simEqSccMapping = convertToSimEqSccMapping(equationSccMapping, lastEqMappingIdx);

      //Create TaskGraph
      //----------------
      (taskGraph,taskGraphData) = HpcOmTaskGraph.createTaskGraph(inBackendDAE,filenamePrefix);
      
      fileName = ("taskGraph"+&filenamePrefix+&".graphml"); 
      schedulerInfo = arrayCreate(arrayLength(taskGraph), (-1,-1));   
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraph, taskGraphData, fileName, "", {}, sccSimEqMapping ,schedulerInfo);

      //Create Costs
      //------------
      taskGraphData = HpcOmTaskGraph.createCosts(inBackendDAE, filenamePrefix +& "_prof.xml" , simEqSccMapping, taskGraphData); 
      
      //Get ODE System
      //--------------
      taskGraphOde = arrayCopy(taskGraph);
      taskGraphDataOde = HpcOmTaskGraph.copyTaskGraphMeta(taskGraphData);
      (taskGraphOde,taskGraphDataOde) = HpcOmTaskGraph.getOdeSystem(taskGraphOde,taskGraphDataOde,inBackendDAE,filenamePrefix);
      
      taskGraphMetaValid = HpcOmTaskGraph.validateTaskGraphMeta(taskGraphDataOde, inBackendDAE);
      taskGraphMetaMessage = Util.if_(taskGraphMetaValid, "TaskgraphMeta valid\n", "TaskgraphMeta invalid\n");
      print(taskGraphMetaMessage);
      
      //HpcOmTaskGraph.printTaskGraph(taskGraphOde);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphDataOde); 
      
      //Assign levels and get critcal path
      //----------------------------------
      (criticalPaths,cpCosts,parallelSets) = HpcOmTaskGraph.longestPathMethod(taskGraphOde,taskGraphDataOde);
      criticalPathInfo = HpcOmTaskGraph.dumpCriticalPathInfo(criticalPaths,cpCosts);
      fileName = ("taskGraph"+&filenamePrefix+&"ODE.graphml");  
      schedulerInfo = arrayCreate(arrayLength(taskGraphOde), (-1,-1));
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraphOde, taskGraphDataOde, fileName, criticalPathInfo, HpcOmTaskGraph.convertNodeListToEdgeTuples(List.first(criticalPaths)), sccSimEqMapping, schedulerInfo);  

      //Apply filters
      //-------------
      (taskGraph1,taskGraphData1) = applyFiltersToGraph(taskGraphOde,taskGraphDataOde,inBackendDAE,true);
      //HpcOmTaskGraph.printTaskGraph(taskGraph1);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphData1); 
      
      //Create schedule
      //---------------
      schedule = createSchedule(taskGraph1,taskGraphData1,sccSimEqMapping);
      taskScheduleSimCode = HpcOmScheduler.convertScheduleToSimCodeSchedule(schedule);
      
      fileName = ("taskGraph"+&filenamePrefix+&"ODE_schedule.graphml");  
      schedulerInfo = HpcOmScheduler.convertScheduleStrucToInfo(schedule,arrayLength(taskGraph));      
      // That's failing
      //(criticalPaths,cpCosts,parallelSets) = HpcOmTaskGraph.longestPathMethod(taskGraph1,taskGraphData1);
      //criticalPathInfo = HpcOmTaskGraph.dumpCriticalPathInfo(criticalPaths,cpCosts);
      criticalPathInfo = "";
      criticalPaths = {{}};
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraph1, taskGraphData1, fileName, criticalPathInfo, HpcOmTaskGraph.convertNodeListToEdgeTuples(List.first(criticalPaths)), sccSimEqMapping, schedulerInfo);
      //HpcOmScheduler.printSchedule(taskSchedule);
      
      //print("Parallel informations:\n");
      //printParInformation(hpcOmParInformation);
      
      SimCode.SIMCODE(modelInfo, simCodeLiterals, simCodeRecordDecls, simCodeExternalFunctionIncludes, allEquations, odeEquations, algebraicEquations, residualEquations, useSymbolicInitialization, useHomotopy, initialEquations, startValueEquations, 
                 parameterEquations, inlineEquations, removedEquations, algorithmAndEquationAsserts, stateSets, constraints, classAttributes, zeroCrossings, relations, sampleLookup, whenClauses, 
                 discreteModelVars, extObjInfo, makefileParams, delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, crefToSimVarHT, _) = simCode;

      checkOdeSystemSize(taskGraphOde,odeEquations);

      simCode = SimCode.SIMCODE(modelInfo, simCodeLiterals, simCodeRecordDecls, simCodeExternalFunctionIncludes, allEquations, odeEquations, algebraicEquations, residualEquations, useSymbolicInitialization, useHomotopy, initialEquations, startValueEquations, 
                 parameterEquations, inlineEquations, removedEquations, algorithmAndEquationAsserts, stateSets, constraints, classAttributes, zeroCrossings, relations, sampleLookup, whenClauses, 
                 discreteModelVars, extObjInfo, makefileParams, delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, crefToSimVarHT, SOME(taskScheduleSimCode));
      
      print("HpcOm is still under construction.\n");
      then simCode;
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/HpcSimCode.mo: function createSimCode failed."});
    then fail();
  end matchcontinue;
end createSimCode;

protected function applyFiltersToGraph
  input HpcOmTaskGraph.TaskGraph iTaskGraph;  
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input BackendDAE.BackendDAE inBackendDAE;
  input Boolean iApplyFilters;
  output HpcOmTaskGraph.TaskGraph oTaskGraph;  
  output HpcOmTaskGraph.TaskGraphMeta oTaskGraphMeta;
protected
  String flagValue;
  Boolean changed1,changed2;
  HpcOmTaskGraph.TaskGraph taskGraph1;
  HpcOmTaskGraph.TaskGraphMeta taskGraphMeta1;
algorithm
  (oTaskGraph,oTaskGraphMeta) := matchcontinue(iTaskGraph,iTaskGraphMeta,inBackendDAE,iApplyFilters)
    case(_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "level");
      then (iTaskGraph, iTaskGraphMeta);
    case(_,_,_,true)
      equation
        //Merge simple Nodes
        taskGraph1 = arrayCopy(iTaskGraph);
        taskGraphMeta1 = HpcOmTaskGraph.copyTaskGraphMeta(iTaskGraphMeta);
        (taskGraph1,taskGraphMeta1,changed1) = HpcOmTaskGraph.mergeSimpleNodes(taskGraph1,taskGraphMeta1,inBackendDAE);
        (taskGraph1,taskGraphMeta1,changed2) = HpcOmTaskGraph.mergeParentNodes(taskGraph1, taskGraphMeta1);
        (taskGraph1,taskGraphMeta1) = applyFiltersToGraph(taskGraph1,taskGraphMeta1,inBackendDAE,changed1 or changed2);
      then (taskGraph1,taskGraphMeta1);
    else then (iTaskGraph, iTaskGraphMeta);
  end matchcontinue;
end applyFiltersToGraph;

protected function createSchedule
  input HpcOmTaskGraph.TaskGraph iTaskGraph;  
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<list<Integer>> iSccSimEqMapping;
  output HpcOmScheduler.Schedule oSchedule;
protected
  String flagValue;
  Integer numProc;
  HpcOmTaskGraph.TaskGraph taskGraph1;
  HpcOmTaskGraph.TaskGraphMeta taskGraphMeta1;
algorithm
  oSchedule := matchcontinue(iTaskGraph,iTaskGraphMeta,iSccSimEqMapping)
    case(_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "level");
      then HpcOmScheduler.createLevelSchedule(iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "listr");
        numProc = Flags.getConfigInt(Flags.NUM_PROC);
        print("Using list scheduling reverse\n");
      then HpcOmScheduler.createListScheduleReverse(iTaskGraph,iTaskGraphMeta,numProc,iSccSimEqMapping);
    case(_,_,_)
      equation
        numProc = Flags.getConfigInt(Flags.NUM_PROC);
      then HpcOmScheduler.createListSchedule(iTaskGraph,iTaskGraphMeta,numProc,iSccSimEqMapping);
    else
      equation
        print("HpcOmSimCode.createSchedule failed. Maybe the n-Flag was not set correctly\n");
      then fail();
  end matchcontinue;
end createSchedule;

protected function convertToSccSimEqMapping "function convertToSccSimEqMapping
  author: marcusw
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

protected function convertToSccSimEqMapping1 "function convertToSccSimEqMapping1
  author: marcusw
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

protected function convertToSimEqSccMapping "function convertToSimEqSccMapping
  author: marcusw
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

protected function convertToSimEqSccMapping1 "function convertToSimEqSccMapping1
  author: marcusw
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

protected function dumpSccSimEqMapping "function dumpSccSimEqMapping
  author: marcusw
  Prints the given mapping out to the console."
  input array<list<Integer>> iSccMapping;
 
protected
  String text;
  
algorithm
  text := "SccToSimEqMapping";
  ((_,text)) := Util.arrayFold(iSccMapping, dumpSccSimEqMapping1, (1,text));
  print(text +& "\n");
end dumpSccSimEqMapping;

protected function dumpSccSimEqMapping1 "function dumpSccSimEqMapping1
  author: marcusw
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

protected function dumpSccSimEqMapping2 "function dumpSccSimEqMapping2
  author: marcusw
  Helper function of dumpSccSimEqMapping1 to print one mapping element."
  input Integer iIndex;
  input String iText;
  output String oText;
  
algorithm
  oText := iText +& intString(iIndex) +& " ";
   
end dumpSccSimEqMapping2;

public function getSimCodeEqByIndex "function getSimCodeEqByIndex
  author: marcusw
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

protected function getIndexBySimCodeEq "function getIndexBySimCodeEq
  author: marcusw
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

protected function findHighestSccIdxInMapping "function findHighestSccIdxInMapping
  author: marcusw
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

protected function removeDummyStateFromMapping "function removeDummyStateFromMapping
  author: marcusw
  Removes all mappings with sccIdx=1 from the list and decrements all other scc-indices by 1."
  input list<tuple<Integer,Integer>> iEquationSccMapping;
  output list<tuple<Integer,Integer>> oEquationSccMapping;
algorithm
  oEquationSccMapping := List.fold(iEquationSccMapping, removeDummyStateFromMapping1, {});
end removeDummyStateFromMapping;

protected function removeDummyStateFromMapping1 "function removeDummyStateFromMapping1
  author: marcusw
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

// testfunctions
//------------------------------------------
//------------------------------------------

protected function checkOdeSystemSize " compares the size of the ode-taskgraph with the number of ode-equations in the simCode.
author:Waurich TUD 2013-07"
  input HpcOmTaskGraph.TaskGraph taskGraphOdeIn;
  input list<list<SimCode.SimEqSystem>> odeEqsIn;
algorithm
  _ := matchcontinue(taskGraphOdeIn,odeEqsIn)
    local
      Integer actualSize;
      Integer targetSize;
    case(_,_)
      equation
        targetSize = listLength(List.flatten(odeEqsIn));
        actualSize = arrayLength(taskGraphOdeIn);
        true = intEq(targetSize,actualSize);
        print("the ODE-system size is correct\n");
        then
          ();
    case(_,_)
      equation
        targetSize = listLength(List.flatten(odeEqsIn));
        actualSize = arrayLength(taskGraphOdeIn);
        true = intEq(targetSize,1) and intEq(actualSize,0);
        // there is a dummyDER in the simcode
        print("the ODE-system size is correct\n");
        then
          ();
    else
      equation
        targetSize = listLength(List.flatten(odeEqsIn));
        actualSize = arrayLength(taskGraphOdeIn);
        print("the size should be "+&intString(targetSize)+&" but it is "+&intString(actualSize)+&" !\n");
        print("the ODE-system is NOT correct\n");
      then
        ();
  end matchcontinue;    
end checkOdeSystemSize;

end HpcOmSimCode;