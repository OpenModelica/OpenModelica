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
public import HpcOmScheduler;
public import SimCode;

// protected imports
protected import BackendEquation;
protected import BaseHashTable;
protected import BackendDAEUtil;
protected import ComponentReference;
protected import Debug;
protected import Error;
protected import Expression;
protected import Flags;
protected import GlobalScript;
protected import GraphML;
protected import HashTableCrILst;
protected import HpcOmTaskGraph;
protected import List;
protected import SimCodeUtil;
protected import System;
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
      BackendDAE.IncidenceMatrix incidenceMatrix;
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
      list<SimCode.SimEqSystem> nominalValueEquations;      // --> updateBoundNominalValues
      list<SimCode.SimEqSystem> minValueEquations;          // --> updateBoundMinValues
      list<SimCode.SimEqSystem> maxValueEquations;          // --> updateBoundMaxValues
      list<SimCode.SimEqSystem> parameterEquations;         // --> updateBoundParameters
      list<SimCode.SimEqSystem> inlineEquations;            // --> inline solver
      list<SimCode.SimEqSystem> removedEquations;
      list<SimCode.SimEqSystem> algorithmAndEquationAsserts;
      list<SimCode.SimEqSystem> jacobianEquations;
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
      BackendDAE.EqSystems eqs;
      BackendDAE.Shared shared;
      BackendDAE.EquationArray removedEqs;
      list<DAE.Constraint> constrsarr;
      list<DAE.ClassAttributes> clsattrsarra;

      list<DAE.Exp> lits;
      list<SimCode.SimVar> tempvars;
      
      SimCode.JacobianMatrix jacG;
      Integer highestSccIdx, compCountPlusDummy;
      Option<BackendDAE.BackendDAE> inlineDAE;
      list<SimCode.StateSet> stateSets;
      array<Integer> systemIndexMap;
      list<tuple<Integer,Integer>> equationSccMapping, equationSccMapping1; //Maps each simEq to the scc
      array<list<Integer>> sccSimEqMapping; //Maps each scc to a list of simEqs
      array<Integer> simeqNodeMapping; //Maps each simEq to the scc
      list<BackendDAE.TimeEvent> timeEvents;
      BackendDAE.StrongComponents allComps;
      
      HpcOmTaskGraph.TaskGraph taskGraph;  
      HpcOmTaskGraph.TaskGraph taskGraphOde;
      HpcOmTaskGraph.TaskGraph taskGraph1;  
      HpcOmTaskGraph.TaskGraphMeta taskGraphData;
      HpcOmTaskGraph.TaskGraphMeta taskGraphDataOde;
      String fileName, fileNamePrefix;
      Integer numProc;
      HpcOmTaskGraph.TaskGraphMeta taskGraphData1;
      list<list<Integer>> parallelSets;
      list<list<Integer>> criticalPaths, criticalPathsWoC;
      Real cpCosts, cpCostsWoC, serTime, parTime, speedUp, speedUpMax;
      
      //Additional informations to append SimCode
      list<DAE.Exp> simCodeLiterals;
      list<SimCode.JacobianMatrix> jacobianMatrixes;
      list<SimCode.SimEqSystem> residualEquations;
      Option<SimCode.SimulationSettings> simulationSettingsOpt;
      list<SimCode.RecordDeclaration> simCodeRecordDecls;
      list<String> simCodeExternalFunctionIncludes;
      
      Boolean taskGraphMetaValid, numFixed;
      String taskGraphMetaMessage, criticalPathInfo;
      array<tuple<Integer,Integer,Real>> schedulerInfo;
      HpcOmScheduler.Schedule schedule;
      HpcOmScheduler.ScheduleSimCode taskScheduleSimCode;
      array<tuple<Integer,Integer,Integer>> eqNodeMapping, varNodeMapping;
      Real graphCosts;
      Integer graphOps;
    case (BackendDAE.DAE(eqs=eqs), _, _, _, _, _, _, _, _, _, _, _) equation
      uniqueEqIndex = 1;
    
      //Setup
      //-----
      System.realtimeTick(GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);  
      (simCode,(lastEqMappingIdx,equationSccMapping)) = SimCodeUtil.createSimCode(inBackendDAE, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs, simSettingsOpt, recordDecls, literals, args);
      (allComps,_) = HpcOmTaskGraph.getSystemComponents(inBackendDAE);
      highestSccIdx = findHighestSccIdxInMapping(equationSccMapping,-1);
      compCountPlusDummy = listLength(allComps)+1;
      equationSccMapping1 = removeDummyStateFromMapping(equationSccMapping);
      //the mapping can contain a dummy state as first scc
      equationSccMapping = Util.if_(intEq(highestSccIdx, compCountPlusDummy), equationSccMapping1, equationSccMapping);
      
      sccSimEqMapping = convertToSccSimEqMapping(equationSccMapping, listLength(allComps));
      simeqNodeMapping = convertToSimeqNodeMapping(equationSccMapping, lastEqMappingIdx);
      Debug.execStat("hpcom setup", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);      
      
      //dumpSccSimEqMapping(sccSimEqMapping);

      //Create TaskGraph
      //----------------
      (taskGraph,taskGraphData) = HpcOmTaskGraph.createTaskGraph(inBackendDAE,filenamePrefix);
      
      Debug.execStat("hpcom createTaskGraph", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);  
      fileName = ("taskGraph"+&filenamePrefix+&".graphml"); 
      schedulerInfo = arrayCreate(arrayLength(taskGraph), (-1,-1,-1.0));   
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraph, taskGraphData, fileName, "", {}, {}, sccSimEqMapping ,schedulerInfo);
      Debug.execStat("hpcom dump TaskGraph", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES); 

      HpcOmTaskGraph.TASKGRAPHMETA(varNodeMapping=varNodeMapping,eqNodeMapping=eqNodeMapping) = taskGraphData;
      //HpcOmTaskGraph.printvarNodeMapping(varNodeMapping,1);
      //HpcOmTaskGraph.printeqNodeMapping(eqNodeMapping,1);
      
      //Create Costs
      //------------
      taskGraphData = HpcOmTaskGraph.createCosts(inBackendDAE, filenamePrefix +& "_eqs_prof.xml" , simeqNodeMapping, taskGraphData); 
      Debug.execStat("hpcom create costs", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);
      
      //Get ODE System
      //--------------
      taskGraphOde = arrayCopy(taskGraph);
      taskGraphDataOde = HpcOmTaskGraph.copyTaskGraphMeta(taskGraphData);
      (taskGraphOde,taskGraphDataOde) = HpcOmTaskGraph.getOdeSystem(taskGraphOde,taskGraphDataOde,inBackendDAE,filenamePrefix);
      Debug.execStat("hpcom get ODE system", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);
      
      taskGraphMetaValid = HpcOmTaskGraph.validateTaskGraphMeta(taskGraphDataOde, inBackendDAE);
      taskGraphMetaMessage = Util.if_(taskGraphMetaValid, "TaskgraphMeta valid\n", "TaskgraphMeta invalid\n");
      print(taskGraphMetaMessage);
      
      //HpcOmTaskGraph.printTaskGraph(taskGraphOde);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphDataOde); 
      
      //Assign levels and get critcal path
      //----------------------------------
      ((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC),parallelSets) = HpcOmTaskGraph.longestPathMethod(taskGraphOde,taskGraphDataOde);
      cpCosts = HpcOmTaskGraph.roundReal(cpCosts,2);
      cpCostsWoC = HpcOmTaskGraph.roundReal(cpCostsWoC,2);
      criticalPathInfo = HpcOmTaskGraph.dumpCriticalPathInfo((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC));
      ((graphOps,graphCosts)) = HpcOmTaskGraph.sumUpExecCosts(taskGraphDataOde);
      graphCosts = HpcOmTaskGraph.roundReal(graphCosts,2);
      criticalPathInfo = criticalPathInfo +& " sum: (" +& realString(graphCosts) +& " ; " +& intString(graphOps) +& ")";
      fileName = ("taskGraph"+&filenamePrefix+&"ODE.graphml");  
      schedulerInfo = arrayCreate(arrayLength(taskGraphOde), (-1,-1,-1.0));
      Debug.execStat("hpcom assign levels / get crit. path", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraphOde, taskGraphDataOde, fileName, criticalPathInfo, HpcOmTaskGraph.convertNodeListToEdgeTuples(List.first(criticalPaths)), HpcOmTaskGraph.convertNodeListToEdgeTuples(List.first(criticalPathsWoC)), sccSimEqMapping, schedulerInfo);  
      Debug.execStat("hpcom dump ODE TaskGraph", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);

      //Apply filters
      //-------------
      taskGraphData1 = taskGraphDataOde;
      taskGraph1 = taskGraphOde;
      (taskGraph1,taskGraphData1) = applyFiltersToGraph(taskGraphOde,taskGraphDataOde,inBackendDAE,true); //TODO: Rename this to applyGRS or someting like that
      Debug.execStat("hpcom GRS", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);
      //Debug.fcall(Flags.HPCOM_DUMP,HpcOmTaskGraph.printTaskGraph,taskGraph1);
      //Debug.fcall(Flags.HPCOM_DUMP,HpcOmTaskGraph.printTaskGraphMeta,taskGraphData1);
      
      //Create schedule
      //---------------
      numProc = Flags.getConfigInt(Flags.NUM_PROC);
      (numProc,numFixed) = setNumProc(numProc,cpCostsWoC,taskGraphDataOde);
      schedule = createSchedule(taskGraph1,taskGraphData1,sccSimEqMapping,filenamePrefix,numProc);
      (schedule,numProc) = repeatScheduleWithOtherNumProc(taskGraph1,taskGraphData1,sccSimEqMapping,filenamePrefix,cpCostsWoC,schedule,numProc,numFixed);
      criticalPathInfo = HpcOmScheduler.analyseScheduledTaskGraph(schedule,numProc,taskGraph1,taskGraphData1);
      taskScheduleSimCode = HpcOmScheduler.convertScheduleToSimCodeSchedule(schedule);
      schedulerInfo = HpcOmScheduler.convertScheduleStrucToInfo(schedule,arrayLength(taskGraph));
      Debug.execStat("hpcom create schedule", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);
      fileName = ("taskGraph"+&filenamePrefix+&"ODE_schedule.graphml");  
      
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraph1, taskGraphData1, fileName, criticalPathInfo, HpcOmTaskGraph.convertNodeListToEdgeTuples(List.first(criticalPaths)), HpcOmTaskGraph.convertNodeListToEdgeTuples(List.first(criticalPathsWoC)), sccSimEqMapping, schedulerInfo);
      //HpcOmScheduler.printSchedule(schedule);
      
      Debug.execStat("hpcom dump schedule TaskGraph", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);
      SimCode.SIMCODE(modelInfo, simCodeLiterals, simCodeRecordDecls, simCodeExternalFunctionIncludes, allEquations, odeEquations, algebraicEquations, residualEquations, useSymbolicInitialization, useHomotopy, initialEquations, startValueEquations, nominalValueEquations, minValueEquations, maxValueEquations, 
                 parameterEquations, inlineEquations, removedEquations, algorithmAndEquationAsserts, jacobianEquations, stateSets, constraints, classAttributes, zeroCrossings, relations, timeEvents, whenClauses, 
                 discreteModelVars, extObjInfo, makefileParams, delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, crefToSimVarHT, _) = simCode;

      checkOdeSystemSize(taskGraphOde,odeEquations);
      Debug.execStat("hpcom check ODE system size", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);

      simCode = SimCode.SIMCODE(modelInfo, simCodeLiterals, simCodeRecordDecls, simCodeExternalFunctionIncludes, allEquations, odeEquations, algebraicEquations, residualEquations, useSymbolicInitialization, useHomotopy, initialEquations, startValueEquations, nominalValueEquations, minValueEquations, maxValueEquations, 
                 parameterEquations, inlineEquations, removedEquations, algorithmAndEquationAsserts, jacobianEquations, stateSets, constraints, classAttributes, zeroCrossings, relations, timeEvents, whenClauses, 
                 discreteModelVars, extObjInfo, makefileParams, delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, crefToSimVarHT, SOME(taskScheduleSimCode));
      
      
      analyzeCacheBehaviour(modelInfo, taskGraph1, taskGraphData1, eqs, filenamePrefix, schedulerInfo, schedule, sccSimEqMapping, criticalPaths, criticalPathsWoC, criticalPathInfo, allComps);
      //evaluateCacheBehaviour(schedulerInfo,taskGraphData1,clTaskMapping, transposeCacheLineTaskMapping(clTaskMapping, arrayLength(taskGraph1)));
      
      
      
      
      //printCacheMap(cacheMap);
      
      print("HpcOm is still under construction.\n");
      then simCode;
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/HpcOmSimCode.mo: function createSimCode failed."});
    then fail();
  end matchcontinue;
end createSimCode;


protected function repeatScheduleWithOtherNumProc"checks if the scheduling with the given numProc is fine.
 if n=auto, more cores are available and more speedup could be achieved repeat schedule with increased num of procs.
 author:Waurich TUD 2013-011"
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  input array<list<Integer>> sccSimEqMappingIn;
  input String fileNamePrefix;
  input Real cpCostsWoC;
  input HpcOmScheduler.Schedule scheduleIn;
  input Integer numProcIn;
  input Boolean numFixed;
  output HpcOmScheduler.Schedule scheduleOut;
  output Integer numProcOut;
protected
  Integer maxNumProc, maxIter;
  Real maxDiff;
algorithm
  maxNumProc := System.numProcessors();
  maxIter := 3;
  maxDiff := 0.5;
  (scheduleOut,numProcOut,_) := repeatScheduleWithOtherNumProc1(taskGraphIn,taskGraphMetaIn,sccSimEqMappingIn,fileNamePrefix,cpCostsWoC,scheduleIn,numProcIn,numFixed,maxNumProc,maxDiff,maxIter);
end repeatScheduleWithOtherNumProc;


protected function repeatScheduleWithOtherNumProc1"checks if the scheduling with the given numProc is fine.
 if n=auto, more cores are available and more speedup could be achieved repeat schedule with increased num of procs.
 author:Waurich TUD 2013-011"
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  input array<list<Integer>> sccSimEqMappingIn;
  input String fileNamePrefix;
  input Real cpCostsWoC;
  input HpcOmScheduler.Schedule scheduleIn;
  input Integer numProcIn;
  input Boolean numFixed;
  input Integer maxNumProc;
  input Real maxDiff;
  input Integer numIterIn;
  output HpcOmScheduler.Schedule scheduleOut;
  output Integer numProcOut;
  output Integer numIterOut;
algorithm
  (scheduleOut,numProcOut,numIterOut) := matchcontinue(taskGraphIn,taskGraphMetaIn,sccSimEqMappingIn,fileNamePrefix,cpCostsWoC,scheduleIn,numProcIn,numFixed,maxNumProc,maxDiff,numIterIn)
    local
      Boolean scheduleAgain;
      Integer numProc, numIt;
      Real serTime,parTime,speedup,speedUp,speedUpMax,diff;
      HpcOmScheduler.Schedule schedule;
    case(_,_,_,_,_,_,_,true,_,_,_)
      equation // do not schedule again because the number of procs was given
        then
          (scheduleIn,numProcIn,0);
    case(_,_,_,_,_,_,_,false,_,_,_)
      equation
        true = numIterIn == 0; // the max number of schedules with increased num of procs
        then
          (scheduleIn,numProcIn,0);
    case(_,_,_,_,_,_,_,false,_,_,_)
      equation
        (serTime,parTime,speedUp,speedUpMax) = HpcOmScheduler.predictExecutionTime(scheduleIn,SOME(cpCostsWoC),numProcIn,taskGraphIn,taskGraphMetaIn);
        diff = speedUpMax -. speedUp;
        //print("the new speedUp with "+&intString(numProcIn)+&" processors: "+&realString(speedUp)+&"\n");
        true = diff <. maxDiff;
        //print("the schedule is fine\n");
      then
        (scheduleIn,numProcIn,numIterIn);
    else
      equation
        numProc = numProcIn+1; // increase the number of procs
        numIt = numIterIn-1; // lower the counter of scheduling runs
        scheduleAgain = intLe(numProc,maxNumProc);
        //print("schedule again\n");
        numProc = Util.if_(scheduleAgain,numProc,numProcIn);
        numIt = Util.if_(scheduleAgain,numIt,0);
        schedule= Debug.bcallret5(scheduleAgain,createSchedule,taskGraphIn,taskGraphMetaIn,sccSimEqMappingIn,fileNamePrefix,numProc,scheduleIn);
        (schedule,numProc,numIt) = repeatScheduleWithOtherNumProc1(taskGraphIn,taskGraphMetaIn,sccSimEqMappingIn,fileNamePrefix,cpCostsWoC,schedule,numProc,numFixed,maxNumProc,maxDiff,numIt);
      then
        (schedule,numProc,numIt);
  end matchcontinue;
end repeatScheduleWithOtherNumProc1;


protected function setNumProc "sets the number of processors. its upper limit is the number of processsors provided by the system.
if no n-flag is set, a ideal number is suggested but the simulation fails.
author: Waurich TUD 2013-11"
  input Integer numProcFlag;
  input Real cpCosts;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  output Integer numProcOut;
  output Boolean numFixed;
algorithm
  (numProcOut,numFixed) := match(numProcFlag,cpCosts,taskGraphMetaIn)
    local
      Boolean isFixed;
      Integer numProcSys, numProc, numProcSched;
      Real serCosts, maxSpeedUp;
      String string1, string2;
    case(0,_,_)
      equation
        serCosts = HpcOmScheduler.getSerialExecutionTime(taskGraphMetaIn);
        maxSpeedUp = realDiv(serCosts,cpCosts);
        numProcSched = realInt(realAdd(maxSpeedUp,1.0));
        numProcSys = System.numProcessors();
        numProc = intMin(numProcSched,numProcSys);
        string1 = "Your system provides only "+&intString(numProcSys)+&" processors!\n";
        string2 = intString(numProcSched)+&" processors might be a reasonable number of processors.\n";
        string1 = Util.if_(intGt(numProcSched,numProcSys),string1,string2);          
        isFixed =  Util.if_(intGt(numProcSched,numProcSys),true,false);  
        print("Please set the number of processors you want to use!\n");
        print(string1);
      then
        fail();
    else
      equation
        numProcSys = System.numProcessors();
        numProc = Util.if_(intGt(numProcFlag,numProcSys),numProcSys,numProcFlag); // the system does not provide so many cores
        Debug.bcall(intGt(numProcFlag,numProcSys),print,"Warning: Your system provides only "+&intString(numProcSys)+&" processors!\n");
      then
        (numProc,true);
  end match;
end setNumProc;


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
  
  array<list<Integer>> sccSimEqMapping;
  BackendDAE.StrongComponents allComps;
  array<tuple<Integer,Integer>> schedulerInfo;
algorithm
  (oTaskGraph,oTaskGraphMeta) := matchcontinue(iTaskGraph,iTaskGraphMeta,inBackendDAE,iApplyFilters)
    case(_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "level");
      then (iTaskGraph, iTaskGraphMeta);
    case(_,_,_,true)
      equation
        //print("Start merging\n");
        //Merge simple and parent nodes
        taskGraph1 = arrayCopy(iTaskGraph);
        taskGraphMeta1 = HpcOmTaskGraph.copyTaskGraphMeta(iTaskGraphMeta);
        (taskGraph1,taskGraphMeta1,changed1) = HpcOmTaskGraph.mergeSimpleNodes(taskGraph1,taskGraphMeta1,inBackendDAE);
        
        //(allComps,_) = HpcOmTaskGraph.getSystemComponents(inBackendDAE);
        //sccSimEqMapping = arrayCreate(listLength(allComps), {});
        //schedulerInfo = arrayCreate(arrayLength(taskGraph1), (-1,-1));
        //print("MergeParentNodes\n");
        //HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraph1, taskGraphMeta1, "testgraph.graphml", "", {}, {}, sccSimEqMapping, schedulerInfo);
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
  input String iFilenamePrefix;
  input Integer numProc;
  output HpcOmScheduler.Schedule oSchedule;
protected
  String flagValue;
  list<Integer> lst;
  HpcOmTaskGraph.TaskGraph taskGraph1;
  HpcOmTaskGraph.TaskGraphMeta taskGraphMeta1;
algorithm
  oSchedule := matchcontinue(iTaskGraph,iTaskGraphMeta,iSccSimEqMapping,iFilenamePrefix,numProc)
    case(_,_,_,_,_)
      equation
        true = arrayLength(iTaskGraph) == 0;
        print("There is no ODE system that can be parallelized!\n");
        // just did this because this works fine. TODO: make something reasonable here and do not use a scheduler.
      then
        HpcOmScheduler.createLevelSchedule(iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "level");
        print("Using level Scheduler\n");
      then HpcOmScheduler.createLevelSchedule(iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "ext");
        print("Using external Scheduler\n");
      then HpcOmScheduler.createExtSchedule(iTaskGraph, iTaskGraphMeta, numProc, iSccSimEqMapping, "taskGraph" +& iFilenamePrefix +& "_ext.graphml");
    case(_,_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "extc");
        print("Using external-c Scheduler\n");
      then HpcOmScheduler.createExtCSchedule(iTaskGraph, iTaskGraphMeta, numProc, iSccSimEqMapping);
    case(_,_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "listr");
      then HpcOmScheduler.createListScheduleReverse(iTaskGraph,iTaskGraphMeta,numProc,iSccSimEqMapping);
    case(_,_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "list");
      then HpcOmScheduler.createListSchedule(iTaskGraph,iTaskGraphMeta,numProc,iSccSimEqMapping);
    case(_,_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "mcp");
        print("Using Modified Critical Path Scheduler\n");
      then HpcOmScheduler.createMCPschedule(iTaskGraph,iTaskGraphMeta,numProc,iSccSimEqMapping);
    case(_,_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "taskdep");
        print("Using OpenMP task dependencies\n");
      then HpcOmScheduler.createTaskDepSchedule(iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        print("HpcOmScheduler.createSchedule warning: The scheduler '" +& flagValue +& "' is unknown. The list-scheduling algorithm is used instead.\n");
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

protected function convertToSimeqNodeMapping "function convertToSimeqNodeMapping
  author: marcusw
  Converts the given mapping (simEqIndex -> sccIndex) bases on tuples to an array mapping."
  input list<tuple<Integer,Integer>> iMapping; //<simEqIdx,sccIdx>
  input Integer numOfSimEqs;
  output array<Integer> oMapping; //maps each simEq to the scc
  
protected
  array<Integer> tmpMapping;
  
algorithm
  tmpMapping := arrayCreate(numOfSimEqs, -1);
  oMapping := List.fold(iMapping, convertToSimeqNodeMapping1, tmpMapping);
end convertToSimeqNodeMapping;

protected function convertToSimeqNodeMapping1 "function convertToSimeqNodeMapping1
  author: marcusw
  Helper function for convertToSimeqNodeMapping. It will update the array at the given index."
  input tuple<Integer,Integer> iSimEqTuple; //<simEqIdx,sccIdx>
  input array<Integer> iMapping;
  output array<Integer> oMapping;
 
protected
  Integer simEqIdx,sccIdx;
  
algorithm
  (simEqIdx,sccIdx) := iSimEqTuple;
  //print("convertToSimeqNodeMapping1 " +& intString(simEqIdx) +& " .. " +& intString(sccIdx) +& " iMapping_len: " +& intString(arrayLength(iMapping)) +& "\n");
  oMapping := arrayUpdate(iMapping,simEqIdx,sccIdx);
end convertToSimeqNodeMapping1;

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


// ----------------------------------
// Section to analyze cache behaviour
// ----------------------------------

//Available Mappings:
// - varName -> SimVarIdx (fillSimVarHashTable)
// - nodeIdx -> list<SimVarIdx> (getNodeSimCodeVarMapping)
// - simEqIdx -> list<SimVarIdx> (getSimEqVarMapping)
// - cacheLineIdx -> list<TaskIdx> (getCacheLineTaskMapping)
// - taskIdx -> list<CacheLineIdx> (transposeCacheLineTaskMapping)
// - scVarIdx -> ClIdx (getSCVarCacheLineMapping)
// - eqIdx -> list<SCVarIdx> (getEqSCVarMapping)

protected uniontype CacheMap
  //CacheMap that stores variables of same type in the same array (different arrays for bool, float and int vars)
  record CACHEMAP
    Integer cacheLineSize; //cache line size in bytes
    list<SimCode.SimVar> cacheVariables; //all variables that are stored in the cache
    list<CacheLineMap> cacheLinesFloat;
    //list<CacheLineMap> cacheLinesBool;
    //list<CacheLineMap> cacheLinesInt;
  end CACHEMAP;
  //CacheMap that stores variables of different types in the same array
  record UNIFORM_CACHEMAP
    Integer cacheLineSize; //cache line size in bytes
    list<SimCode.SimVar> cacheVariables; //all variables that are stored in the cache
    list<CacheLineMap> cacheLines;
  end UNIFORM_CACHEMAP;
end CacheMap;

protected uniontype CacheLineMap
  record CACHELINEMAP
    Integer idx;
    list<CacheLineEntry> entries;
  end CACHELINEMAP;
end CacheLineMap;

protected uniontype CacheLineEntry
  record CACHELINEENTRY
    Integer start; //starting with 0
    Integer dataType; //1 = float, 2 = int
    Integer size;
    Integer scVarIdx; //see CacheMap.cacheVariables
  end CACHELINEENTRY;
end CacheLineEntry;

protected uniontype MemoryMap
  record MEMORYMAP_ARRAY
    array<Integer> positionMapping; //map each simCodeVar to a memory (array) position
    Integer floatArraySize;
  end MEMORYMAP_ARRAY;
end MemoryMap;

protected function analyzeCacheBehaviour
  input SimCode.ModelInfo iModelInfo;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input BackendDAE.EqSystems iEqSystems;
  input String iFileNamePrefix;
  input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
  input HpcOmScheduler.Schedule iSchedule;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input list<list<Integer>> iCriticalPaths;
  input list<list<Integer>> iCriticalPathsWoC;
  input String iCriticalPathInfo;
  input BackendDAE.StrongComponents iAllComponents;
protected
  SimCode.SimVars simCodeVars;
  list<SimCode.SimVar> stateVars, derivativeVars, algVars, paramVars;
  HashTableCrILst.HashTable hashTable;
  Integer numScVars, numCL, threadAttIdx;
  array<list<Integer>> clTaskMapping;
  array<Integer> scVarCLMapping, scVarTaskMapping, sccNodeMapping;
  CacheMap cacheMap;
  Integer graphIdx;
  GraphML.GraphInfo graphInfo;
  String fileName;
  array<array<list<Integer>>> eqSimCodeVarMapping; //eqSystem -> eqIdx -> varIdx
  array<tuple<Integer,Integer,Integer>> eqNodeMapping, varNodeMapping;
  BackendDAE.IncidenceMatrix incidenceMatrix;
algorithm
  _ := matchcontinue(iModelInfo, iTaskGraph, iTaskGraphMeta, iEqSystems, iFileNamePrefix, iSchedulerInfo, iSchedule, iSccSimEqMapping, iCriticalPaths, iCriticalPathsWoC, iCriticalPathInfo, iAllComponents)
    case(_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.HPCOM_ANALYZATION_MODE);
			  //Create var hash table
			  SimCode.MODELINFO(vars=simCodeVars) = iModelInfo;
			  SimCode.SIMVARS(stateVars=stateVars, derivativeVars=derivativeVars, algVars=algVars, paramVars=paramVars) = simCodeVars;
			  hashTable = HashTableCrILst.emptyHashTableSized(BaseHashTable.biggerBucketSize);
			  hashTable = fillSimVarHashTable(stateVars,0,0,hashTable);
			  //hashTable = fillSimVarHashTable(derivativeVars,listLength(stateVars),0,hashTable);
			  hashTable = fillSimVarHashTable(algVars,listLength(stateVars)*2,0,hashTable);
			  //hashTable = fillSimVarHashTable(paramVars,listLength(stateVars)*2 + listLength(algVars),0,hashTable);
			
			  //Create CacheMap
			  scVarTaskMapping = getScVarTaskMapping(iTaskGraphMeta,iEqSystems,listLength(stateVars)*2+listLength(algVars),hashTable);
			  (cacheMap,scVarCLMapping,numCL) = createCacheMapOptimized(stateVars,derivativeVars,algVars,paramVars,scVarTaskMapping,64,iAllComponents,iSchedule);
			
			  //Create required mappings
			  sccNodeMapping = HpcOmTaskGraph.getSccNodeMapping(arrayLength(iSccSimEqMapping), iTaskGraphMeta);
        eqSimCodeVarMapping = getEqSCVarMapping(iEqSystems,hashTable);
      
        (clTaskMapping,scVarTaskMapping) = getCacheLineTaskMapping(iTaskGraphMeta,iEqSystems,hashTable,numCL,scVarCLMapping);

	      //Append cache line nodes to graph
	      graphInfo = GraphML.createGraphInfo();
	      (graphInfo, (_,graphIdx)) = GraphML.addGraph("TasksGroupGraph", true, graphInfo);
	      (graphInfo, (_,_),(_,graphIdx)) = GraphML.addGroupNode("TasksGroup", graphIdx, false, "TG", graphInfo);
	      graphInfo = HpcOmTaskGraph.convertToGraphMLSccLevelSubgraph(iTaskGraph, iTaskGraphMeta, iCriticalPathInfo, HpcOmTaskGraph.convertNodeListToEdgeTuples(List.first(iCriticalPaths)), HpcOmTaskGraph.convertNodeListToEdgeTuples(List.first(iCriticalPathsWoC)), iSccSimEqMapping, iSchedulerInfo, graphIdx, graphInfo);
	      HpcOmTaskGraph.TASKGRAPHMETA(eqNodeMapping=eqNodeMapping,varNodeMapping=varNodeMapping) = iTaskGraphMeta;
	      SOME((_,threadAttIdx)) = GraphML.getAttributeByNameAndTarget("ThreadId", GraphML.TARGET_NODE(), graphInfo);
	      (_,incidenceMatrix,_) = BackendDAEUtil.getIncidenceMatrix(List.first(iEqSystems), BackendDAE.ABSOLUTE(), NONE());
	      graphInfo = appendCacheLinesToGraph(cacheMap, arrayLength(iTaskGraph), eqSimCodeVarMapping, iEqSystems, hashTable, eqNodeMapping, scVarTaskMapping, iSchedulerInfo, threadAttIdx, graphInfo);
	      fileName = ("taskGraph"+&iFileNamePrefix+&"ODE_schedule_CL.graphml"); 
	      GraphML.dumpGraph(graphInfo, fileName);
      then ();
    else then ();
  end matchcontinue;
end analyzeCacheBehaviour;

protected function createCacheMapOptimized
  input list<SimCode.SimVar> iStateVars; //float
  input list<SimCode.SimVar> iDerivativeVars; //float
  input list<SimCode.SimVar> iAlgVars; //float
  input list<SimCode.SimVar> iParamVars; //float
  input array<Integer> iScVarTaskMapping;
  input Integer iCacheLineSize;
  input BackendDAE.StrongComponents iAllComponents;
  input HpcOmScheduler.Schedule iSchedule;
  output CacheMap oCacheMap;
  output array<Integer> oScVarCLMapping; //mapping for each scVar -> CLIdx
  output Integer oNumCL;
protected
  CacheMap cacheMap;
  array<Integer> scVarCLMapping;
  Integer numCL;
  list<list<HpcOmScheduler.Task>> tasksOfLevels;
algorithm
  (oCacheMap,oScVarCLMapping,oNumCL) := match(iStateVars,iDerivativeVars,iAlgVars,iParamVars,iScVarTaskMapping,iCacheLineSize,iAllComponents,iSchedule)
    case(_,_,_,_,_,_,_,HpcOmScheduler.LEVELSCHEDULE(tasksOfLevels=tasksOfLevels))
      equation
        (cacheMap,scVarCLMapping,numCL) = createCacheMapLevelOptimized(iStateVars,iDerivativeVars,iAlgVars,iParamVars,iScVarTaskMapping,iCacheLineSize,iAllComponents,tasksOfLevels);
      then (cacheMap,scVarCLMapping,numCL);
    else
      equation
        print("No optimized cache map for the selected scheduler avaiable\n");
        (cacheMap,scVarCLMapping,numCL) = createCacheMapDefault(iStateVars,iDerivativeVars,iAlgVars,iCacheLineSize);
      then (cacheMap,scVarCLMapping,numCL);
   end match;
end createCacheMapOptimized;

protected function createCacheMapLevelOptimized "author: marcusw
  Create the optimized cache map for the given level-schedule."
  input list<SimCode.SimVar> iStateVars; //float
  input list<SimCode.SimVar> iDerivativeVars; //float
  input list<SimCode.SimVar> iAlgVars; //float
  input list<SimCode.SimVar> iParamVars; //float
  input array<Integer> iScVarTaskMapping;
  input Integer iCacheLineSize;
  input BackendDAE.StrongComponents iAllComponents;
  input list<list<HpcOmScheduler.Task>> iTasksOfLevels; //Schedule
  output CacheMap oCacheMap;
  output array<Integer> oScVarCLMapping; //mapping for each scVar -> CLIdx
  output Integer oNumCL;
protected
  CacheMap cacheMap;
  Integer numCL;
  array<Integer> scVarCLMapping;
  array<list<CacheLineMap>> threadCacheLines; //cache lines of the threads (arrayIdx)
algorithm
  cacheMap := CACHEMAP(iCacheLineSize,{},{});
  scVarCLMapping := arrayCreate(1,-1);
  numCL := 0;
  //Iterate over levels
  
  (oCacheMap,oNumCL,_) := appendParamsToCacheMap(cacheMap, numCL, iParamVars,0);
  oScVarCLMapping := scVarCLMapping;
end createCacheMapLevelOptimized;

protected function createCacheMapLevelOptimized0
  input list<HpcOmScheduler.Task> iLevelTasks;
  input array<list<Integer>> iNodeSimCodeVarMapping;
  input tuple<list<Integer>,CacheMap,Integer> iInfo; //<cacheLinesUsedByPreviousLayer,CacheMap,numCL>
  output tuple<list<Integer>,CacheMap,Integer> oInfo;
protected
  Integer createdCL, numCL; //number of CL created for this level
  list<Integer> allCL;
  list<Integer> availableCL, availableCLold, writtenCL; //all cacheLines that can be used for writing
  list<Integer> cacheLinesPrevLevel; //all cache lines written in previous level
  CacheMap cacheMap;
algorithm
  (cacheLinesPrevLevel, cacheMap, numCL) := iInfo;
  allCL := List.intRange(numCL);
  //availableCLold := List.setDifferenceIntN(allCL,cacheLinesPrevLevel,numCL,intEq);
  //((cacheMap,createdCL,availableCL)) := List.fold(iLevelTasks, createCacheMapLevelOptimized1, (cacheMap,0,availableCLold));
  //append the used cachelines to the writtenCL-list
  //writtenCL := List.setDifferenceIntN(availableCLold,availableCL,numCL,intEq);
  //writtenCL := List.append(writtenCL, List.intRange2(numCL+1, numCL+createCL));
  //oInfo := (writtenCL,cacheMap,cacheMap+createdCL);
  oInfo := iInfo;
end createCacheMapLevelOptimized0;

protected function createCacheMapLevelOptimized1
  input Task iTask;
  input tuple<CacheMap,Integer,list<Integer>> iInfo; //<CacheMap,numNewCL, availableCL>
  output tuple<CacheMap,Integer,list<Integer>> oInfo;  
end createCacheMapLevelOptimized1;

protected function appendParamsToCacheMap
  input CacheMap iCacheMap;
  input Integer iNumCL;
  input list<SimCode.SimVar> iParamVars; //float
  input Integer iNumBytesUsedLastCL;
  output CacheMap oCacheMap;
  output Integer oNumCL;
  output Integer oNumBytesUsedLastCL;
protected
  
algorithm
  ((oCacheMap,oNumCL,oNumBytesUsedLastCL)) := List.fold(iParamVars, appendFloatVarToCacheMap, (iCacheMap,iNumCL,iNumBytesUsedLastCL));
end appendParamsToCacheMap;

protected function appendFloatVarToCacheMap
  input SimCode.SimVar iFloatVar;
  input tuple<CacheMap,Integer,Integer> iCacheInfo;
  output tuple<CacheMap,Integer,Integer> oCacheInfo; //<cacheMap,numCL,numBytesUsedLastCL>
protected
  Integer cacheLineSize, numCL, numBytesUsedLastCL;
  list<SimCode.SimVar> cacheVariables;
  list<CacheLineMap> tail;
  CacheLineMap head;
  Integer cacheLineIdx, cacheVarIdx, newCacheLineIdx;
  list<CacheLineEntry> cacheLineEntries;
  CacheLineEntry newEntry;
  CacheMap newCacheMap;
algorithm
  oCacheInfo := matchcontinue(iFloatVar,iCacheInfo)
    case(_,(CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=(head as CACHELINEMAP(idx=cacheLineIdx,entries=cacheLineEntries))::tail),numCL,numBytesUsedLastCL))
      //case1: CacheMap has at least one entry and there is enough space available to add the variable to the first cacheline
      equation
        true = intGt(cacheLineSize,numBytesUsedLastCL+8);
        cacheVariables = iFloatVar::cacheVariables;
        cacheVarIdx = listLength(cacheVariables);
        newEntry = CACHELINEENTRY(numBytesUsedLastCL,1,8,cacheVarIdx);
        cacheLineEntries = newEntry::cacheLineEntries;
        head = CACHELINEMAP(cacheLineIdx,cacheLineEntries);
        newCacheMap = CACHEMAP(cacheLineSize,cacheVariables,head::tail);
      then ((newCacheMap,numCL,numBytesUsedLastCL+8));
    case(_,(CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=tail),numCL,numBytesUsedLastCL))
      equation
        cacheVariables = iFloatVar::cacheVariables;
        cacheVarIdx = listLength(cacheVariables);
        newEntry = CACHELINEENTRY(numBytesUsedLastCL,1,8,cacheVarIdx);
        newCacheLineIdx = listLength(tail)+1;
        head = CACHELINEMAP(newCacheLineIdx,{newEntry});
        newCacheMap = CACHEMAP(cacheLineSize,cacheVariables,head::tail);
      then ((newCacheMap,numCL,8));
    else
      equation
        print("appendFloatVarToCacheMap failed\n");
      then fail();
  end matchcontinue;
end appendFloatVarToCacheMap;



protected function createCacheMapDefault "author: marcusw
  Create the cache map for the default c-runtime."
  input list<SimCode.SimVar> iStateVars; //float
  input list<SimCode.SimVar> iDerivativeVars; //float
  input list<SimCode.SimVar> iAlgVars; //float
  //input list<SimCode.SimVar> iParamVars; //float
  input Integer iCacheLineSize;
  output CacheMap oCacheMap;
  output array<Integer> oScVarCLMapping; //mapping for each scVar -> CLIdx
  output Integer oNumCL;
protected
  list<SimCode.SimVar> iAllFloatVars;
  list<CacheLineMap> cacheLineFloatMaps;
  array<Integer> tmpScVarCLMapping;
algorithm
  iAllFloatVars := listAppend(listAppend(iStateVars,iDerivativeVars),iAlgVars);
  tmpScVarCLMapping := arrayCreate(listLength(iAllFloatVars),-1);
  (cacheLineFloatMaps,oScVarCLMapping) := getSCVarCacheLineMappingFloat(iAllFloatVars, iCacheLineSize, 0, tmpScVarCLMapping);
  oCacheMap := CACHEMAP(iCacheLineSize,iAllFloatVars,cacheLineFloatMaps);
  oNumCL := listLength(cacheLineFloatMaps);
end createCacheMapDefault;

protected function getSCVarCacheLineMappingFloat
  input list<SimCode.SimVar> iFloatVars;
  input Integer iNumBytes; //number of bytes per cache line
  input Integer iStartCL; //the cache line index of the first variable
  input array<Integer> iSVarCLMapping;
  output list<CacheLineMap> oCacheLines;
  output array<Integer> oScVarCLMapping;
protected
  list<CacheLineMap> tmpCacheLines;
algorithm
  ((tmpCacheLines,_,_,_,oScVarCLMapping)) := List.fold1(iFloatVars, getSCVarCacheLineMappingFloat0, iNumBytes, ({},iStartCL-1,0,1,iSVarCLMapping));
  tmpCacheLines := List.map(tmpCacheLines, reverseCacheLineMapEntries);
  oCacheLines := listReverse(tmpCacheLines);
end getSCVarCacheLineMappingFloat;

protected function getSCVarCacheLineMappingFloat0
  input SimCode.SimVar iSimVar;
  input Integer iNumBytes;
  input tuple<list<CacheLineMap>,Integer,Integer,Integer,array<Integer>> iCacheLineMappingSimVarIdx; //<filledCacheLines,CacheLineIdx,BytesCLAlreadyUsed,SimVarIdx,scVarCLMapping>
  output tuple<list<CacheLineMap>,Integer,Integer,Integer,array<Integer>> oCacheLineMappingSimVarIdx; 
protected
  CacheLineMap iCacheLineHead;
  list<CacheLineMap> iCacheLines;
  Integer iCacheLineIdx, iSimVarIdx, iBytesUsed;
  CacheLineEntry entry;
  array<Integer> iSVarCLMapping;
  Integer oldCLIdx;
  list<CacheLineEntry> oldCLEntries;
algorithm
  oCacheLineMappingSimVarIdx := matchcontinue(iSimVar,iNumBytes,iCacheLineMappingSimVarIdx)
    case(_,_,(iCacheLines,iCacheLineIdx,0,iSimVarIdx,iSVarCLMapping))
      equation
        entry = CACHELINEENTRY(0,1,8,iSimVarIdx);
        iCacheLineIdx = iCacheLineIdx+1;
        iCacheLineHead = CACHELINEMAP(iCacheLineIdx, {entry});
        iCacheLines = iCacheLineHead :: iCacheLines;
        iSVarCLMapping = arrayUpdate(iSVarCLMapping,iSimVarIdx,iCacheLineIdx+1);
      then ((iCacheLines, iCacheLineIdx, intMod(8,iNumBytes), iSimVarIdx+1, iSVarCLMapping));
    case(_,_,(iCacheLineHead::iCacheLines,iCacheLineIdx,iBytesUsed,iSimVarIdx,iSVarCLMapping))
      equation
        true = intLe(iBytesUsed+8, iNumBytes);
        entry = CACHELINEENTRY(iBytesUsed,1,8,iSimVarIdx);
        CACHELINEMAP(oldCLIdx,oldCLEntries) = iCacheLineHead;
        oldCLEntries = entry :: oldCLEntries;
        iCacheLineHead = CACHELINEMAP(oldCLIdx,oldCLEntries);
        iCacheLines = iCacheLineHead :: iCacheLines;
        iSVarCLMapping = arrayUpdate(iSVarCLMapping,iSimVarIdx,iCacheLineIdx+1);
      then ((iCacheLines, iCacheLineIdx, intMod(iBytesUsed+8,iNumBytes), iSimVarIdx+1, iSVarCLMapping));
    else
      equation 
        print("getSCVarCacheLineMappingFloat0 failed\n");
      then iCacheLineMappingSimVarIdx;
  end matchcontinue;
end getSCVarCacheLineMappingFloat0;

protected function reverseCacheLineMapEntries
  input CacheLineMap iCacheLineMap;
  output CacheLineMap oCacheLineMap;
protected
  Integer idx;
  list<CacheLineEntry> entries;
algorithm 
  CACHELINEMAP(idx=idx,entries=entries) := iCacheLineMap;
  entries := listReverse(entries);
  oCacheLineMap := CACHELINEMAP(idx,entries);
end reverseCacheLineMapEntries;

protected function printCacheMap
  input CacheMap iCacheMap;
protected
  Integer cacheLineSize;
  list<CacheLineMap> cacheLinesFloat;
  list<SimCode.SimVar> cacheVariables;
algorithm
  print("\n\nCacheMap\n---------------\n");
  CACHEMAP(cacheLineSize=cacheLineSize, cacheVariables=cacheVariables, cacheLinesFloat=cacheLinesFloat) := iCacheMap;
  List.map1_0(cacheLinesFloat, printCacheLineMap, cacheVariables);
end printCacheMap;

protected function printCacheLineMap
  input CacheLineMap iCacheLineMap;
  input list<SimCode.SimVar> iCacheVariables;
protected
  Integer idx;
  list<CacheLineEntry> entries;
  String iVarsString, iBytesString;
algorithm
  CACHELINEMAP(idx=idx, entries=entries) := iCacheLineMap;
  print("  CacheLineMap " +& intString(idx) +& " (" +& intString(listLength(entries)) +& " entries)\n");
  ((iVarsString, iBytesString)) := List.fold1(entries, cacheLineEntryToString, iCacheVariables, ("",""));
  print("    " +& iVarsString +& "\n");
  print("    " +& iBytesString +& "\n");
  print("\n");
end printCacheLineMap;

protected function cacheLineEntryToString
  input CacheLineEntry iCacheLineEntry;
  input list<SimCode.SimVar> iCacheVariables;
  input tuple<String,String> iString; //<variable names seperated by |, byte positions string>
  output tuple<String,String> oString;
protected
  Integer start;
  Integer dataType;
  Integer size;
  Integer scVarIdx;
  String scVarStr;
  SimCode.SimVar iVar;
  DAE.ComponentRef name;
  String iVarsString, iBytesString, iBytesStringNew, byteStartString;
algorithm
  (iVarsString, iBytesString) := iString;
  CACHELINEENTRY(start=start,dataType=dataType,size=size,scVarIdx=scVarIdx) := iCacheLineEntry;
  iVar := listGet(iCacheVariables, scVarIdx);
  SimCode.SIMVAR(name=name) := iVar;
  scVarStr := ComponentReference.printComponentRefStr(name);
  iVarsString := iVarsString +& "| " +& scVarStr +& " ";
  iBytesStringNew := intString(start);
  iBytesStringNew := Util.stringPadRight(iBytesStringNew, 3 + stringLength(scVarStr), " ");
  iBytesString := iBytesString +& iBytesStringNew;
  oString := (iVarsString,iBytesString);
end cacheLineEntryToString;

protected function fillSimVarHashTable "author: marcusw
  Function to create a mapping for each simVar-name to the simVar-Index+Offset."
  input list<SimCode.SimVar> iSimVars;
  input Integer iOffset;
  input Integer iType; //1 = real ; 2 = int
  input HashTableCrILst.HashTable iHt; //contains a list of type Integer for each simVar. List.First: Index, List.Secons: Offset, List.Third: Type
  output HashTableCrILst.HashTable oHt;
algorithm
  oHt := List.fold2(iSimVars, fillSimVarHashTableTraverse, iOffset, iType, iHt);
end fillSimVarHashTable;

protected function fillSimVarHashTableTraverse "author: marcusw
  Helper function to extend the given mapping for the iSimVar."
  input SimCode.SimVar iSimVar;
  input Integer iOffset;
  input Integer iType;
  input HashTableCrILst.HashTable iHt;
  output HashTableCrILst.HashTable oHt;
protected
  Integer index;
  DAE.ComponentRef name;
algorithm
  SimCode.SIMVAR(name=name,index=index) := iSimVar;
  //print("fillSimVarHashTableTraverse: " +& ComponentReference.debugPrintComponentRefTypeStr(name) +& " with index: " +& intString(index+ iOffset) +& "\n");
  index := index + 1;
  oHt := BaseHashTable.add((name,{index,iOffset,iType}),iHt);
end fillSimVarHashTableTraverse;

protected function getVarsBySimEqSystem "function getVarsBySimEqSystem
  author: marcusw
  Function extract all variables of the given equation system."
  input SimCode.SimEqSystem iEqSystem;
  input HashTableCrILst.HashTable iHt;
  output list<Integer> oVars;
protected
  list<Integer> varIdcList;
  DAE.ComponentRef cref;
  DAE.Exp exp;
  Integer index, hTableIdx;
algorithm
  oVars := match(iEqSystem, iHt)
    case(SimCode.SES_SIMPLE_ASSIGN(cref=cref,exp=exp,index=index),_)
      equation
        //BackendDump.debugExpStr((exp,"\n"));
        //print("end Expression\n");
        ((_,(_,varIdcList))) = Expression.traverseExp(exp,createMemoryMapTraverse, (iHt,{}));
        //print("Var List for simEquation " +& intString(index) +& ":");
        //print(stringDelimitList(List.map(varIdcList, intString), ","));
        //print("\n");
      then varIdcList;
    else 
      then {};
  end match;
end getVarsBySimEqSystem;

protected function createMemoryMapTraverse
  input tuple<DAE.Exp,tuple<HashTableCrILst.HashTable, list<Integer>>> iExpVars;
  output tuple<DAE.Exp,tuple<HashTableCrILst.HashTable, list<Integer>>> oExpVars;
protected
  DAE.Exp iExp;
  tuple<HashTableCrILst.HashTable, list<Integer>> iVarInfo;
algorithm
  (iExp,iVarInfo) := iExpVars;
  oExpVars := Expression.traverseExp(iExp,createMemoryMapTraverse0,iVarInfo);  
end createMemoryMapTraverse;

protected function createMemoryMapTraverse0
  input tuple<DAE.Exp,tuple<HashTableCrILst.HashTable, list<Integer>>> iExpVars;
  output tuple<DAE.Exp,tuple<HashTableCrILst.HashTable, list<Integer>>> oExpVars;
protected
  list<Integer> iVarList, oVarList, varInfo;
  Integer varIdx;
  HashTableCrILst.HashTable iHashTable;
  DAE.Exp iExp;
  DAE.ComponentRef componentRef;
algorithm
  oExpVars := matchcontinue(iExpVars)
    case((iExp as DAE.CREF(componentRef=componentRef), (iHashTable,iVarList)))
      equation
        //print("HpcOmSimCode.createMemoryMapTraverse: try to find componentRef\n");
        varInfo = BaseHashTable.get(componentRef, iHashTable);
        varIdx = List.first(varInfo) + List.second(varInfo);
        //print("createMemoryMapTraverse0 " +& intString(varIdx) +& "\n");
        //print("HpcOmSimCode.createMemoryMapTraverse: Found ref " +& ComponentReference.printComponentRefStr(componentRef) +& " with Index: " +& intString(varIdx) +& "\n");
        //ExpressionDump.dumpExp(iExp);
        oVarList = varIdx :: iVarList;
      then ((iExp,(iHashTable,oVarList)));
    case((iExp as DAE.CREF(componentRef=componentRef), (iHashTable,iVarList))) 
      equation
        //print("HpcOmSimCode.createMemoryMapTraverse: Variable not found ( " +& ComponentReference.printComponentRefStr(componentRef) +& ")\n");
      then iExpVars;
    case((iExp, _))
      equation
        //BackendDump.debugExpStr((iExp, "\n"));
      then iExpVars;
    else
      then iExpVars;
  end matchcontinue;
end createMemoryMapTraverse0;




protected function getVarSCVarMapping
  input BackendDAE.EqSystem iEqSystem;
  input HashTableCrILst.HashTable iHt; //Mapping scVarName -> varIdx
  output array<Integer> oMapping;
protected
  array<Integer> tmpMapping;
  BackendDAE.Variables orderedVars;
  BackendDAE.VariableArray varArr;
  array<Option<BackendDAE.Var>> varOptArr;
  Integer numberOfVars;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars) := iEqSystem;
  BackendDAE.VARIABLES(varArr=varArr,numberOfVars=numberOfVars) := orderedVars;
  BackendDAE.VARIABLE_ARRAY(varOptArr=varOptArr) := varArr;
  tmpMapping := arrayCreate(numberOfVars,-1);
  ((oMapping,_)) := Util.arrayFold1(varOptArr,getVarSCVarMapping0,iHt,(tmpMapping,1));
end getVarSCVarMapping;

protected function getVarSCVarMapping0
  input Option<BackendDAE.Var> iVarOpt;
  input HashTableCrILst.HashTable iHt;
  input tuple<array<Integer>,Integer> iMappingIdxTpl;
  output tuple<array<Integer>,Integer> oMappingIdxTpl;
protected
  BackendDAE.Var iVar;
  DAE.ComponentRef varName;
  Integer scVarIdx, scVarOffset, varIdx;
  array<Integer> tmpMapping;
  list<Integer> scVarValues;
algorithm
  oMappingIdxTpl := match(iVarOpt,iHt,iMappingIdxTpl)
    case(SOME(iVar),_,_)
      equation
        (tmpMapping,varIdx) = iMappingIdxTpl;
        BackendDAE.VAR(varName=varName) = iVar;
        scVarValues = BaseHashTable.get(varName,iHt);
        scVarIdx = List.first(scVarValues);
        scVarOffset = List.second(scVarValues);
        scVarIdx = scVarIdx + scVarOffset + 1;
        tmpMapping = arrayUpdate(tmpMapping,varIdx,scVarIdx);
      then ((tmpMapping,varIdx+1));
    else
      then iMappingIdxTpl;
  end match;
end getVarSCVarMapping0;

protected function getSCVarVarMapping
  input Integer iNumScVars;
  input array<Integer> iVarSCVarMapping;
  output array<Integer> oSCVarVarMapping;
protected
  array<Integer> tmpMapping;
algorithm
  tmpMapping := arrayCreate(iNumScVars, -1);
  ((oSCVarVarMapping,_)) := Util.arrayFold(iVarSCVarMapping, getSCVarVarMapping0, (tmpMapping,1));
end getSCVarVarMapping;

protected function getSCVarVarMapping0
  input Integer iScVarIdx;
  input tuple<array<Integer>,Integer> iSCVarVarMappingIdx;
  output tuple<array<Integer>,Integer> oSCVarVarMappingIdx;  
protected
  Integer iVarIdx;
  array<Integer> iMapping;
algorithm
  (iMapping,iVarIdx) := iSCVarVarMappingIdx;
  iMapping := arrayUpdate(iMapping, iScVarIdx, iVarIdx);
  oSCVarVarMappingIdx := (iMapping, iVarIdx+1);
end getSCVarVarMapping0;

protected function getNodeSimCodeVarMapping "author: marcusw
  Function to create a mapping for each node to a list of simCode-Variables that are solved in the task."
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input BackendDAE.EqSystems iEqSystems;
  input HashTableCrILst.HashTable iSCVarNameHashTable;
  output array<list<Integer>> oMapping;
protected
  array<tuple<Integer,Integer,Integer>> varNodeMapping;
  array<list<Integer>> inComps;
  array<list<Integer>> tmpMapping;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,varNodeMapping=varNodeMapping) := iTaskGraphMeta;
  tmpMapping := arrayCreate(arrayLength(inComps),{});
  ((oMapping,_)) := Util.arrayFold2(varNodeMapping, getNodeSimCodeVarMapping0, iEqSystems, iSCVarNameHashTable, (tmpMapping,1));
end getNodeSimCodeVarMapping;

protected function getNodeSimCodeVarMapping0
  input tuple<Integer,Integer,Integer> iVarNodeMapping; //<nodeIdx,eqSysIdx,offset>
  input BackendDAE.EqSystems iEqSystems;
  input HashTableCrILst.HashTable iSCVarNameHashTable;
  input tuple<array<list<Integer>>,Integer> iMappingVarIdxTpl; //<mapping,varIdx>
  output tuple<array<list<Integer>>,Integer> oMappingVarIdxTpl;
protected
  Integer nodeIdx,eqSysIdx,varIdx,scVarOffset,scVarIdx;
  BackendDAE.EqSystem eqSystem;
  DAE.ComponentRef varName;
  BackendDAE.Var var; 
  BackendDAE.Variables orderedVars;
  BackendDAE.VariableArray varArr;
  array<Option<BackendDAE.Var>> varOptArr;
  array<list<Integer>> iMapping;
  list<Integer> scVarValues,tmpMapping;
algorithm
  oMappingVarIdxTpl := matchcontinue(iVarNodeMapping,iEqSystems,iSCVarNameHashTable,iMappingVarIdxTpl)
    case((nodeIdx,eqSysIdx,_),_,_,(iMapping,varIdx))
      equation
        eqSystem = listGet(iEqSystems,eqSysIdx);
        BackendDAE.EQSYSTEM(orderedVars=orderedVars) = eqSystem;
        BackendDAE.VARIABLES(varArr=varArr) = orderedVars;
        BackendDAE.VARIABLE_ARRAY(varOptArr=varOptArr) = varArr;
        SOME(var) = arrayGet(varOptArr,varIdx);
        BackendDAE.VAR(varName=varName) = var;
        scVarValues = BaseHashTable.get(varName,iSCVarNameHashTable);
        scVarIdx = List.first(scVarValues);
        scVarOffset = List.second(scVarValues);
        scVarIdx = scVarIdx + scVarOffset + 1;
        tmpMapping = arrayGet(iMapping,nodeIdx);
        tmpMapping = scVarIdx :: tmpMapping;
        iMapping = arrayUpdate(iMapping,nodeIdx,tmpMapping);
      then ((iMapping,varIdx+1));
    case((nodeIdx,eqSysIdx,_),_,_,(iMapping,varIdx))
      equation
        print("getNodeSimCodeVarMapping0: Failed to find scVar for varIdx " +& intString(varIdx) +& "\n");
      then ((iMapping,varIdx+1));
  end matchcontinue;
end getNodeSimCodeVarMapping0;


protected function getEqSCVarMapping
  input BackendDAE.EqSystems iEqSystems;
  input HashTableCrILst.HashTable iHt; //Mapping varName -> varIdx
  output array<array<list<Integer>>> oMapping; //eqSysIdx -> eqIdx -> list<scVarIdx>
protected
  list<array<list<Integer>>> tmpMapping;
algorithm
  tmpMapping := List.map1(iEqSystems, getEqSCVarMappingByEqSystem, iHt);
  oMapping := listArray(tmpMapping);
end getEqSCVarMapping;

protected function getEqSCVarMappingByEqSystem "author: marcusw
  Function to create a mapping for each equation in the equationSystem to a list of simCode-Variables that are part of the equation-expressions."
  input BackendDAE.EqSystem iEqSystem;
  input HashTableCrILst.HashTable iHt; //Mapping varName -> varIdx
  output array<list<Integer>> oMapping; //eqIdx -> list<scVarIdx>
protected
  BackendDAE.EquationArray orderedEqs;
  array<Option<BackendDAE.Equation>> equOptArr;
  list<Option<BackendDAE.Equation>> equOptList;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs=orderedEqs) := iEqSystem;
  BackendDAE.EQUATION_ARRAY(equOptArr=equOptArr) := orderedEqs;
  equOptList := arrayList(equOptArr);
  oMapping := listArray(List.map1Option(equOptList, getEqSCVarMapping0, iHt));
end getEqSCVarMappingByEqSystem;

protected function getEqSCVarMapping0
  input BackendDAE.Equation iEquation;
  input HashTableCrILst.HashTable iHt; //Mapping varName -> varIdx
  output list<Integer> oMapping;
protected
  list<Integer> varIdcList;
algorithm
  //print("getEqSCVarMapping0: Handling equation:\n" +& BackendDump.equationString(iEquation) +& "\n");
  (_,(_,oMapping)) := BackendEquation.traverseBackendDAEExpsEqn(iEquation,createMemoryMapTraverse, (iHt,{}));
  //((_,(_,oMapping))) := Expression.traverseExp(exp,createMemoryMapTraverse, (iHt,{}));
end getEqSCVarMapping0;

protected function getSimEqVarMapping
  input list<SimCode.SimEqSystem> iEqSystems;
  input HashTableCrILst.HashTable iHt; //Mapping varName -> varIdx
  output list<list<Integer>> oEqVarMapping; //Mapping eq -> list of varIdx
algorithm
  oEqVarMapping := List.map1(iEqSystems, getVarsBySimEqSystem, iHt);
end getSimEqVarMapping;

protected function transposeCacheLineTaskMapping
  input array<list<Integer>> iCLTaskMapping;
  input Integer iNumberOfTasks; //number of tasks
  output array<list<Integer>> oCLTaskMappingT; //taskCLMapping
protected
  array<list<Integer>> taskCLMapping;
algorithm
  //print("transposeCacheLineTaskMapping with nodeCount: " +& intString(iNumberOfTasks) +& "\n");
  taskCLMapping := arrayCreate(iNumberOfTasks,{});
  ((oCLTaskMappingT,_)) := Util.arrayFold(iCLTaskMapping,transposeCacheLineTaskMapping0,(taskCLMapping,1));
  //print("transposeCacheLineTaskMapping finished\n");
end transposeCacheLineTaskMapping;

protected function transposeCacheLineTaskMapping0
  input list<Integer> iMappingEntry; //mapping clIdx -> list<NodeIdx>
  input tuple<array<list<Integer>>,Integer> iMappingTClIdx; //<oMapping,iClIdx>
  output tuple<array<list<Integer>>,Integer> oMappingTClIdx; //<oMapping,iClIdx>
protected
  array<list<Integer>> taskCLMapping;
  Integer iCLIdx;
algorithm
  (taskCLMapping,iCLIdx) := iMappingTClIdx;
  taskCLMapping := List.fold1(iMappingEntry, transposeCacheLineTaskMapping1, iCLIdx, taskCLMapping);
  oMappingTClIdx := (taskCLMapping,iCLIdx+1);
end transposeCacheLineTaskMapping0;

protected function transposeCacheLineTaskMapping1
  input Integer iTaskIdx;
  input Integer iCLIdx;
  input array<list<Integer>> iTaskCLMapping;
  output array<list<Integer>> oTaskCLMapping;
protected
  list<Integer> oldValue;
  array<list<Integer>> tmpCLTaskMapping;
algorithm
  oTaskCLMapping := matchcontinue(iTaskIdx,iCLIdx,iTaskCLMapping)
    case(_,_,_)
      equation
        //print("transposeCacheLineTaskMapping1 TaskIdx: " +& intString(iTaskIdx) +& " CacheLineIdx: " +& intString(iCLIdx) +& "\n");
        oldValue = arrayGet(iTaskCLMapping,iTaskIdx);
        oldValue = iCLIdx :: oldValue;
        tmpCLTaskMapping = arrayUpdate(iTaskCLMapping,iTaskIdx,oldValue);
      then tmpCLTaskMapping;
    else then iTaskCLMapping;
  end matchcontinue;
end transposeCacheLineTaskMapping1;

protected function getScVarTaskMapping
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input BackendDAE.EqSystems iEqSystems;
  input Integer iNumScVars;
  input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
  output array<Integer> oScVarTaskMapping;
protected
  array<tuple<Integer,Integer,Integer>> varNodeMapping;
  array<Integer> scVarTaskMapping;
algorithm
  scVarTaskMapping := arrayCreate(iNumScVars,-1);
  HpcOmTaskGraph.TASKGRAPHMETA(varNodeMapping=varNodeMapping) := iTaskGraphMeta;
  //iterate over all variables
  ((oScVarTaskMapping,_)) := Util.arrayFold2(varNodeMapping, getScVarTaskMapping0, iEqSystems, iVarNameSCVarIdxMapping, (scVarTaskMapping,1));
end getScVarTaskMapping;

protected function getScVarTaskMapping0
  input tuple<Integer,Integer,Integer> iNodeIdx; //<nodeIdx,eqSysIdx,varOffset>
  input BackendDAE.EqSystems iEqSystems;
  input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
  input tuple<array<Integer>, Integer> iScVarTaskMappingVarIdx; //<mapping scVarIdx -> task, varIdx>
  output tuple<array<Integer>, Integer> oScVarTaskMappingVarIdx;
protected
  array<Integer> iScVarTaskMapping;
  Integer varIdx,eqSysIdx,varOffset,scVarIdx,nodeIdx, nodeIdx, scVarOffset;
  BackendDAE.EqSystem eqSystem;
  BackendDAE.Variables orderedVars;
  BackendDAE.VariableArray varArr;
  array<Option<BackendDAE.Var>> varOptArr;
  BackendDAE.Var var;
  DAE.ComponentRef varName;
  list<Integer> scVarValues;
algorithm
  oScVarTaskMappingVarIdx := matchcontinue(iNodeIdx,iEqSystems,iVarNameSCVarIdxMapping,iScVarTaskMappingVarIdx)
    case((nodeIdx,eqSysIdx,varOffset),_,_,(iScVarTaskMapping,varIdx))
      equation
        true = intGt(nodeIdx,0);
        eqSystem = listGet(iEqSystems,eqSysIdx);
        BackendDAE.EQSYSTEM(orderedVars=orderedVars) = eqSystem;
        BackendDAE.VARIABLES(varArr=varArr) = orderedVars;
        BackendDAE.VARIABLE_ARRAY(varOptArr=varOptArr) = varArr;
        SOME(var) = arrayGet(varOptArr,varIdx-varOffset);
        BackendDAE.VAR(varName=varName) = var;
        scVarValues = BaseHashTable.get(varName,iVarNameSCVarIdxMapping);
        scVarIdx = List.first(scVarValues);
        scVarOffset = List.second(scVarValues);
        scVarIdx = scVarIdx + scVarOffset;
        //oldVal = arrayGet(iClTaskMapping,clIdx);
        //print("getCacheLineTaskMapping0 scVarIdx: " +& intString(scVarIdx) +& "\n");
        iScVarTaskMapping = arrayUpdate(iScVarTaskMapping,scVarIdx,nodeIdx);
        //print("Variable " +& intString(varIdx) +& " (" +& ComponentReference.printComponentRefStr(varName) +& ") [SC-Var " +& intString(scVarIdx) +& "]\n---------------------\n");
        //print("Part of CL " +& intString(clIdx) +& " solved by node " +& intString(nodeIdx) +& "\n\n");
      then ((iScVarTaskMapping,varIdx+1));
    case(_,_,_,(iScVarTaskMapping,varIdx))
      then ((iScVarTaskMapping,varIdx+1));
  end matchcontinue;
end getScVarTaskMapping0;

protected function getCacheLineTaskMapping "author: marcusw
  This method will create an array, which contains all tasks that are writing to the cacheline (arrayIndex)."
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input BackendDAE.EqSystems iEqSystems;
  input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
  input Integer iNumCacheLines; //number of cache lines
  input array<Integer> iSCVarCLMapping; //mapping for each SimCode.Var (arrayIndex) to the cache line index
  output array<list<Integer>> oCLTaskMapping;
  output array<Integer> oScVarTaskMapping;
protected
  array<tuple<Integer,Integer,Integer>> varNodeMapping;
  array<list<Integer>> tmpCLTaskMapping;
  array<Integer> scVarTaskMapping;
algorithm
  tmpCLTaskMapping := arrayCreate(iNumCacheLines,{});
  scVarTaskMapping := arrayCreate(arrayLength(iSCVarCLMapping),-1);
  HpcOmTaskGraph.TASKGRAPHMETA(varNodeMapping=varNodeMapping) := iTaskGraphMeta;
  //iterate over all variables
  ((tmpCLTaskMapping,oScVarTaskMapping,_)) := Util.arrayFold3(varNodeMapping, getCacheLineTaskMapping0, iEqSystems, iVarNameSCVarIdxMapping, iSCVarCLMapping, (tmpCLTaskMapping,scVarTaskMapping,1));
  tmpCLTaskMapping := Util.arrayMap1(tmpCLTaskMapping, List.sort, intLt);
  oCLTaskMapping := Util.arrayMap1(tmpCLTaskMapping, List.sortedUnique, intEq);
end getCacheLineTaskMapping;

protected function getCacheLineTaskMapping0
  input tuple<Integer,Integer,Integer> iNodeIdx; //<nodeIdx,eqSysIdx,varOffset>
  input BackendDAE.EqSystems iEqSystems;
  input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
  input array<Integer> iSCVarCLMapping; //mapping for each SimCode.Var (arrayIndex) to the cache line index
  input tuple<array<list<Integer>>, array<Integer>, Integer> iCLTaskMappingVarIdx; //<mapping clIdx -> task, mapping scVarIdx -> task, varIdx>
  output tuple<array<list<Integer>>, array<Integer>, Integer> oCLTaskMappingVarIdx;
protected
  array<list<Integer>> iClTaskMapping;
  array<Integer> iScVarTaskMapping;
  Integer varIdx,eqSysIdx,varOffset,scVarIdx,clIdx,nodeIdx, nodeIdx, scVarOffset;
  BackendDAE.EqSystem eqSystem;
  BackendDAE.Variables orderedVars;
  BackendDAE.VariableArray varArr;
  array<Option<BackendDAE.Var>> varOptArr;
  BackendDAE.Var var;
  DAE.ComponentRef varName;
  list<Integer> oldVal, scVarValues;
algorithm
  oCLTaskMappingVarIdx := matchcontinue(iNodeIdx,iEqSystems,iVarNameSCVarIdxMapping,iSCVarCLMapping,iCLTaskMappingVarIdx)
    case((nodeIdx,eqSysIdx,varOffset),_,_,_,(iClTaskMapping,iScVarTaskMapping,varIdx))
      equation
        true = intGt(nodeIdx,0);
        eqSystem = listGet(iEqSystems,eqSysIdx);
        BackendDAE.EQSYSTEM(orderedVars=orderedVars) = eqSystem;
        BackendDAE.VARIABLES(varArr=varArr) = orderedVars;
        BackendDAE.VARIABLE_ARRAY(varOptArr=varOptArr) = varArr;
        SOME(var) = arrayGet(varOptArr,varIdx-varOffset);
        BackendDAE.VAR(varName=varName) = var;
        scVarValues = BaseHashTable.get(varName,iVarNameSCVarIdxMapping);
        scVarIdx = List.first(scVarValues);
        scVarOffset = List.second(scVarValues);
        scVarIdx = scVarIdx + scVarOffset;
        clIdx = arrayGet(iSCVarCLMapping,scVarIdx);
        oldVal = arrayGet(iClTaskMapping,clIdx);
        iClTaskMapping = arrayUpdate(iClTaskMapping,clIdx,nodeIdx::oldVal);
        //print("getCacheLineTaskMapping0 scVarIdx: " +& intString(scVarIdx) +& "\n");
        iScVarTaskMapping = arrayUpdate(iScVarTaskMapping,scVarIdx,nodeIdx);
        //print("Variable " +& intString(varIdx) +& " (" +& ComponentReference.printComponentRefStr(varName) +& ") [SC-Var " +& intString(scVarIdx) +& "]\n---------------------\n");
        //print("Part of CL " +& intString(clIdx) +& " solved by node " +& intString(nodeIdx) +& "\n\n");
      then ((iClTaskMapping,iScVarTaskMapping,varIdx+1));
    case(_,_,_,_,(iClTaskMapping,iScVarTaskMapping,varIdx))
      then ((iClTaskMapping,iScVarTaskMapping,varIdx+1));
  end matchcontinue;
end getCacheLineTaskMapping0;

protected function printCacheLineTaskMapping
  input array<list<Integer>> iCacheLineTaskMapping;
algorithm
  _ := Util.arrayFold(iCacheLineTaskMapping, printCacheLineTaskMapping0, 1);
end printCacheLineTaskMapping;

protected function printCacheLineTaskMapping0
  input list<Integer> iTasks;
  input Integer iCacheLineIdx;
  output Integer oCacheLineIdx;
algorithm
  print("Tasks that are writing to cacheline " +& intString(iCacheLineIdx) +& ": " +& stringDelimitList(List.map(iTasks, intString), ",") +& "\n");
  oCacheLineIdx := iCacheLineIdx + 1;
end printCacheLineTaskMapping0;

protected function getSCVarCacheLineMapping
  input list<SimCode.SimVar> iSimVars;
  input Integer iNumVarsCL; //number of bytes per cache line
  output array<Integer> oCacheLineMapping;
protected
  array<Integer> tmpCacheLineMapping;
algorithm
  tmpCacheLineMapping := arrayCreate(listLength(iSimVars), -1);
  ((oCacheLineMapping,_)) := List.fold1(iSimVars, getSCVarCacheLineMapping0, iNumVarsCL, (tmpCacheLineMapping,1));
end getSCVarCacheLineMapping;

protected function getSCVarCacheLineMapping0
  input SimCode.SimVar iSimVar;
  input Integer iNumCL;
  input tuple<array<Integer>,Integer> iCacheLineMappingSimVarIdx;
  output tuple<array<Integer>,Integer> oCacheLineMappingSimVarIdx;
protected
  Integer iSimVarIdx, clIdx;
  array<Integer> iCacheLineMapping;
  DAE.ComponentRef name;
algorithm
  SimCode.SIMVAR(name=name) := iSimVar;
  (iCacheLineMapping,iSimVarIdx) := iCacheLineMappingSimVarIdx;
  clIdx := intDiv(iSimVarIdx-1,iNumCL)+1;
  //print("Sc-Var" +& intString(iSimVarIdx) +& ":" +& ComponentReference.debugPrintComponentRefTypeStr(name) +& " is part of cl: " +& intString(clIdx) +& "\n");
  iCacheLineMapping := arrayUpdate(iCacheLineMapping,iSimVarIdx,clIdx);
  oCacheLineMappingSimVarIdx := (iCacheLineMapping,iSimVarIdx+1);
end getSCVarCacheLineMapping0;


protected function evaluateCacheBehaviour
  input array<tuple<Integer,Integer,Real>> iSchedulerInfo; //<threadId,taskNumber,finishTime> for node (array-index)
  input HpcOmTaskGraph.TaskGraphMeta iGraphData;
  input array<list<Integer>> iCLTaskMapping;
  input array<list<Integer>> iTaskCLMapping;
algorithm
  //Iterate over all tasks (nodes in graph)
  _ := Util.arrayFold4(iSchedulerInfo, evaluateCacheBehaviour0, iSchedulerInfo, iGraphData, iCLTaskMapping, iTaskCLMapping, 1);
end evaluateCacheBehaviour;

protected function evaluateCacheBehaviour0
  input tuple<Integer,Integer,Real> iSchedulerInfo; //<threadId,taskNumber,finishTime>
  input array<tuple<Integer,Integer,Real>> iSchedulerInfoFull;
  input HpcOmTaskGraph.TaskGraphMeta iGraphData;
  input array<list<Integer>> iCLTaskMapping;
  input array<list<Integer>> iTaskCLMapping;
  input Integer iNodeIdx;
  output Integer oNodeIdx;
protected
  list<Integer> taskCacheLines;
algorithm
  oNodeIdx := matchcontinue(iSchedulerInfo,iSchedulerInfoFull,iGraphData,iCLTaskMapping,iTaskCLMapping,iNodeIdx)
    case(_,_,_,_,_,_)
      equation
        print("evaluateCacheBehaviour0 for node " +& intString(iNodeIdx) +& "\n");
        taskCacheLines = arrayGet(iTaskCLMapping,iNodeIdx);
        //print("evaluateCacheBehaviour0 writing to cache lines: " +& stringDelimitList(List.map(taskCacheLines, intString), ",") +& "\n");
        List.map4_0(taskCacheLines, evaluateCacheBehaviour1, (iGraphData,iNodeIdx), iSchedulerInfoFull, iSchedulerInfo, iCLTaskMapping);
      then iNodeIdx + 1;
    else then iNodeIdx + 1;
  end matchcontinue;
end evaluateCacheBehaviour0;

protected function evaluateCacheBehaviour1
  input Integer iCacheLineIdx;
  input tuple<HpcOmTaskGraph.TaskGraphMeta,Integer> iGraphDataNodeIdxTpl; //<graphdata,NodeIdx>
  input array<tuple<Integer,Integer,Real>> iSchedulerInfoFull;
  input tuple<Integer,Integer,Real> iSchedulerInfo;
  input array<list<Integer>> iCLTaskMapping;
protected
  Integer threadIdx, iNodeIdx;
  HpcOmTaskGraph.TaskGraphMeta iGraphData;
  list<Integer> otherTasksCL;
algorithm
  _ := matchcontinue(iCacheLineIdx,iGraphDataNodeIdxTpl,iSchedulerInfoFull,iSchedulerInfo,iCLTaskMapping)
    case(_,(iGraphData, iNodeIdx),_,_,_)
      equation
        //get threadIdx of task
        (threadIdx,_,_) = iSchedulerInfo;
        //find all tasks that are writing to the same cache line
        otherTasksCL = arrayGet(iCLTaskMapping,iCacheLineIdx);
        otherTasksCL = List.removeOnTrue(iNodeIdx, intEq, otherTasksCL);
        //filter out tasks that belong to the same thread
        otherTasksCL = List.fold3(otherTasksCL, evaluateCacheBehaviour1Filter, iGraphData, iSchedulerInfoFull, (iNodeIdx,threadIdx),  {});
        print("Conflicting tasks: " +& stringDelimitList(List.map(otherTasksCL, intString), ",") +& "\n");
      then ();
    else then ();
  end matchcontinue;
end evaluateCacheBehaviour1;

protected function evaluateCacheBehaviour1Filter
  input Integer iOtherNodeIdx;
  input HpcOmTaskGraph.TaskGraphMeta iGraphData;
  input array<tuple<Integer,Integer,Real>> iSchedulerInfoFull;
  input tuple<Integer,Integer> iNodeIdxThreadIdx;
  input list<Integer> iTaskList;
  output list<Integer> oTaskList; 
protected
  Integer head, otherThreadIdx, iNodeIdx, iThreadIdx;
  Real nodeExecTime, otherNodeExecTime, nodeFinishTime, nodeStartTime, otherNodeFinishTime, otherNodeStartTime;
  list<Integer> tail;
  list<Integer> tmpTaskList;
algorithm
  oTaskList := matchcontinue(iOtherNodeIdx, iGraphData, iSchedulerInfoFull, iNodeIdxThreadIdx, iTaskList)
    case(_,_,_,(iNodeIdx,iThreadIdx),_)
      equation
        ((otherThreadIdx,_,_)) = arrayGet(iSchedulerInfoFull,iOtherNodeIdx);
        true = intNe(iThreadIdx,otherThreadIdx); // the nodes are handled by different threads
        ((_,nodeExecTime)) = HpcOmTaskGraph.getExeCost(iNodeIdx,iGraphData);
        ((_,otherNodeExecTime)) = HpcOmTaskGraph.getExeCost(iOtherNodeIdx,iGraphData);
        ((_,_,nodeFinishTime)) = arrayGet(iSchedulerInfoFull, iNodeIdx);
        ((_,_,otherNodeFinishTime)) = arrayGet(iSchedulerInfoFull, iOtherNodeIdx);
        nodeStartTime = realSub(nodeFinishTime, nodeExecTime);
        otherNodeStartTime = realSub(otherNodeFinishTime, otherNodeExecTime);
        true = realLt(otherNodeFinishTime, nodeFinishTime);
        true = realGt(otherNodeFinishTime, nodeStartTime);//other thread has written to cache line during calculation
        tmpTaskList = iOtherNodeIdx :: iTaskList;
      then tmpTaskList;
    else    
      then iTaskList;
  end matchcontinue;
end evaluateCacheBehaviour1Filter;


protected function appendCacheLinesToGraph "author: marcusw
  This method will extend the given graph-info with a new subgraph containing all cache lines.
  Dependencies between the tasks and the cache lines will be inserted as edges."
  input CacheMap iCacheMap;
  input Integer iNumberOfNodes; //number of nodes in the task graph
  input array<array<list<Integer>>> iEqSimCodeVarMapping;
  input BackendDAE.EqSystems iEqSystems; //the eqSystem of the incidence matrix
  input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
  input array<tuple<Integer,Integer,Integer>> ieqNodeMapping; //a mapping from eqIdx (arrayIdx) to the node idx
  input array<Integer> iScVarTaskMapping; //maps each scVar (arrayIdx) to the task that solves it
  input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
  input Integer iAttributeIdc; //indices for attributes threadId
  input GraphML.GraphInfo iGraphInfo;
  output GraphML.GraphInfo oGraphInfo;
protected
  Integer clGroupNodeIdx, graphCount;
  GraphML.GraphInfo tmpGraphInfo;
  array<list<Integer>> knownEdges; //edges from task to variables    
  list<SimCode.SimVar> cacheVariables;
  list<CacheLineMap> cacheLinesFloat;
algorithm
  oGraphInfo := matchcontinue(iCacheMap,iNumberOfNodes,iEqSimCodeVarMapping,iEqSystems,iVarNameSCVarIdxMapping,ieqNodeMapping,iScVarTaskMapping,iSchedulerInfo,iAttributeIdc,iGraphInfo)
    case(CACHEMAP(cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat),_,_,_,_,_,_,_,_,GraphML.GRAPHINFO(graphCount=graphCount))
      equation
        true = intLe(1, graphCount);
        knownEdges = arrayCreate(iNumberOfNodes,{});
        (tmpGraphInfo,(_,_),(_,clGroupNodeIdx)) = GraphML.addGroupNode("CL_GoupNode", 1, false, "CL", iGraphInfo);
        tmpGraphInfo = List.fold4(cacheLinesFloat, appendCacheLineMapToGraph, cacheVariables, iSchedulerInfo, (clGroupNodeIdx,iAttributeIdc), iScVarTaskMapping, tmpGraphInfo);
        ((_,knownEdges,tmpGraphInfo)) = Util.arrayFold1(arrayGet(iEqSimCodeVarMapping,1), appendCacheLineEdgesToGraphTraverse, ieqNodeMapping, (1,knownEdges,tmpGraphInfo));
      then tmpGraphInfo;
    case(_,_,_,_,_,_,_,_,_,GraphML.GRAPHINFO(graphCount=graphCount))
      equation
        true = intEq(graphCount,0);
      then iGraphInfo;
    else
      equation
        print("HpcOmSimCode.appendCacheLinesToGraph failed!\n");
      then fail();
   end matchcontinue;
end appendCacheLinesToGraph;

protected function appendCacheLineMapToGraph
  input CacheLineMap iCacheLineMap;
  input list<SimCode.SimVar> iCacheVariables;
  input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
  input tuple<Integer,Integer> iTopGraphAttThreadIdIdx; //<topGraphIdx,threadIdAttIdx>
  input array<Integer> iScVarTaskMapping; //maps each scVar (arrayIdx) to the task that solves her
  input GraphML.GraphInfo iGraphInfo;
  output GraphML.GraphInfo oGraphInfo;
protected
  Integer idx, graphIdx, iTopGraphIdx, iAttThreadIdIdx;
  list<CacheLineEntry> entries;
  GraphML.GraphInfo tmpGraphInfo;
algorithm
  CACHELINEMAP(idx=idx,entries=entries) := iCacheLineMap;
  (iTopGraphIdx, iAttThreadIdIdx) := iTopGraphAttThreadIdIdx;
  (tmpGraphInfo, (_,_),(_,graphIdx)) := GraphML.addGroupNode("CL_Meta_" +& intString(idx), iTopGraphIdx, true, "CL" +& intString(idx), iGraphInfo);
  oGraphInfo := List.fold4(entries, appendCacheLineEntryToGraph, iCacheVariables, iSchedulerInfo, (graphIdx,iAttThreadIdIdx), iScVarTaskMapping, tmpGraphInfo);
end appendCacheLineMapToGraph;

protected function appendCacheLineEntryToGraph
  input CacheLineEntry iCacheLineEntry;
  input list<SimCode.SimVar> iCacheVariables;
  input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
  input tuple<Integer,Integer> iTopGraphAttThreadIdIdx; //<topGraphIdx,threadIdAttIdx>
  input array<Integer> iScVarTaskMapping; //maps each scVar (arrayIdx) to the task that solves her
  input GraphML.GraphInfo iGraphInfo;
  output GraphML.GraphInfo oGraphInfo;
protected
  Integer scVarIdx, taskIdx, iTopGraphIdx, iAttThreadIdIdx;
  String varString, threadText, nodeLabelText, nodeId;
  GraphML.NodeLabel nodeLabel;
  SimCode.SimVar iVar;
  DAE.ComponentRef name;
algorithm
  CACHELINEENTRY(scVarIdx=scVarIdx) := iCacheLineEntry;
  (iTopGraphIdx, iAttThreadIdIdx) := iTopGraphAttThreadIdIdx;
  nodeId := "CL_Var" +& intString(scVarIdx);
  taskIdx := arrayGet(iScVarTaskMapping,scVarIdx);
  iVar := listGet(iCacheVariables, scVarIdx);
  SimCode.SIMVAR(name=name) := iVar;
  //print("HpcOmSimCode.appendCacheLineNodesToGraphTraverse VarNode-Name: " +& intString(scVarIdx) +& " taskIdx: " +& intString(taskIdx) +& "\n");
  varString := ComponentReference.printComponentRefStr(name);
  threadText := appendCacheLineNodesToGraphTraverse0(taskIdx,iSchedulerInfo);
  nodeLabelText := intString(scVarIdx);
  nodeLabel := GraphML.NODELABEL_INTERNAL(nodeLabelText, NONE(), GraphML.FONTPLAIN());
  (oGraphInfo,_) := GraphML.addNode(nodeId, GraphML.COLOR_GREEN, {nodeLabel}, GraphML.ELLIPSE(), SOME(varString), {(iAttThreadIdIdx,threadText)}, iTopGraphIdx, iGraphInfo); 
end appendCacheLineEntryToGraph;

protected function appendCacheLineNodesToGraphTraverse0
  input Integer iTaskIdx;
  input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
  output String oTaskDepString;
protected
  Integer threadIdx;
  String tmpString;
algorithm
  oTaskDepString := matchcontinue(iTaskIdx,iSchedulerInfo)
    case(_,_)
      equation
        ((threadIdx,_,_)) = arrayGet(iSchedulerInfo,iTaskIdx);
        //print("Task " +& intString(iTaskIdx) +& " is solved by thread " +& intString(threadIdx) +& "\n");
        tmpString = "Th " +& intString(threadIdx);
      then tmpString;
    else
      then "";
  end matchcontinue;  
end appendCacheLineNodesToGraphTraverse0;

protected function appendCacheLineEdgesToGraphTraverse
  input list<Integer> iEqSCVars;
  //input array<Integer> iScVarNodeMapping; //maps each scVar (arrayIdx) to the task that solves it
  input array<tuple<Integer,Integer,Integer>> ieqNodeMapping; //a mapping from eqIdx (arrayIdx) to the scc idx
  input tuple<Integer,array<list<Integer>>,GraphML.GraphInfo> iGraphInfoIdx;
  output tuple<Integer,array<list<Integer>>,GraphML.GraphInfo> oGraphInfoIdx;
protected
  Integer eqIdx, nodeIdx;
  GraphML.GraphInfo graphInfo;
  array<list<Integer>> knownEdges;
algorithm
  (eqIdx,knownEdges,graphInfo) := iGraphInfoIdx;
  //print("appendCacheLineEdgesToGraphTraverse: Equation with Vars: " +& stringDelimitList(List.map(iEqVars, intString), ",") +& "\n");
  //print("appendCacheLineEdgesToGraphTraverse " +& intString(eqIdx) +& " arrayLength: " +& intString(arrayLength(ieqNodeMapping)) +& "\n");
  ((nodeIdx,_,_)) := arrayGet(ieqNodeMapping,eqIdx);
  graphInfo := List.fold3(iEqSCVars, appendCacheLineEdgeToGraph, eqIdx, nodeIdx, knownEdges, graphInfo);
  oGraphInfoIdx := ((eqIdx+1,knownEdges,graphInfo));
end appendCacheLineEdgesToGraphTraverse;

protected function appendCacheLineEdgeToGraph
  input Integer iSCVarIdx;
  input Integer iEqIdx;
  input Integer iNodeIdx;
  input array<list<Integer>> iKnownEdges;
  input GraphML.GraphInfo iGraphInfo;
  output GraphML.GraphInfo oGraphInfo;
protected
  String edgeId, sourceId, targetId;
  GraphML.GraphInfo tmpGraphInfo;
algorithm
  oGraphInfo := matchcontinue(iSCVarIdx,iEqIdx,iNodeIdx,iKnownEdges,iGraphInfo)
    case(_,_,_,_,_)
      equation
        //print("appendCacheLineEdgeToGraph: scVarFound " +& intString(iVarIdx) +& " [SC-Var " +& intString(scVarIdx) +& "]\n");
        //knownEdgesOfNode = arrayGet(knownEdges,nodeIdx);
        //false = List.exist1(knownEdgesOfNode, intEq, clIdx);
        true = intGt(iNodeIdx,0);
        //knownEdges = arrayUpdate(knownEdges, nodeIdx, clIdx::knownEdgesOfNode);
        edgeId = "CL_Edge" +& intString(iNodeIdx) +& intString(iSCVarIdx);
        sourceId = "Node" +& intString(iNodeIdx);
        //targetId = "CL_Meta_" +& intString(clIdx);
        //print("appendCacheLineEdgeToGraph: Equation " +& intString(iEqIdx) +& " reads/writes SC-Var-idx: " +& intString(iSCVarIdx) +& " solved in node " +& intString(iNodeIdx) +& "\n");
        targetId = "CL_Var" +& intString(iSCVarIdx);
        (tmpGraphInfo,(_,_)) = GraphML.addEdge(edgeId, targetId, sourceId, GraphML.COLOR_GRAY, GraphML.DASHED(), GraphML.LINEWIDTH_STANDARD, true, {}, (GraphML.ARROWNONE(),GraphML.ARROWNONE()), {}, iGraphInfo);
      then tmpGraphInfo;
     case(_,_,_,_,_)
      equation
        //((nodeIdx,_,_)) = arrayGet(ieqNodeMapping,iEqIdx);
        //print("HpcOmSimCode.appendCacheLineEdgeToGraph: No node for scc " +& intString(sccIdx) +& " found\n");
      then iGraphInfo;
     else
      equation
        //Valid if there is no state in the model and a dummy state was added
        //print("HpcOmSimCode.appendCacheLineEdgeToGraph: Equation " +& intString(iEqIdx) +& " is not part of a scc.\n");
        //print("HpcOmSimCode.appendCacheLineEdgeToGraph failed!\n");
      then iGraphInfo;
  end matchcontinue;
end appendCacheLineEdgeToGraph;

// testfunctions
//------------------------------------------
//------------------------------------------

protected function checkOdeSystemSize " compares the size of the ode-taskgraph with the number of ode-equations in the simCode.
Remark: this can occure when asserts are added to the ode-system.
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
        print("the ODE-system size is correct("+&intString(actualSize)+&")\n");
        then
          ();
    case(_,_)
      equation
        targetSize = listLength(List.flatten(odeEqsIn));
        actualSize = arrayLength(taskGraphOdeIn);
        true = intEq(targetSize,1) and intEq(actualSize,0);
        // there is a dummyDER in the simcode
        print("the ODE-system size is correct(0)\n");
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