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

encapsulated package HpcOmSimCodeMain
" file:        HpcOmSimCodeMain.mo
  package:     HpcOmSimCodeMain
  description: HpcOmSimCodeMain contains the logic to create a parallelized simcode.

  RCS: $Id: HpcOmSimCodeMain.mo 15486 2013-05-24 11:12:35Z marcusw $
"
// public imports
public import Absyn;
public import BackendDAE;
public import DAE;
public import HashTableExpToIndex;
public import HpcOmSimCode;
public import HpcOmTaskGraph;
public import HpcOmEqSystems;
public import SimCode;

// protected imports
protected import Array;
protected import BackendDAEUtil;
protected import BackendDAEOptimize;
protected import BackendDump;
protected import ClockIndexes;
protected import Debug;
protected import Error;
protected import Flags;
protected import HpcOmMemory;
protected import HpcOmScheduler;
protected import Initialization;
protected import List;
protected import SimCodeUtil;
protected import SimCodeFunctionUtil;
protected import System;
protected import Util;

public function createSimCode "function createSimCode
  entry point to create SimCode from BackendDAE."
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.BackendDAE inInitDAE;
  input Boolean inUseHomotopy "true if homotopy(...) is used during initialization";
  input Option<BackendDAE.BackendDAE> inInitDAE_lambda0;
  input list<BackendDAE.Equation> inRemovedInitialEquationLst;
  input list<BackendDAE.Var> inPrimaryParameters "already sorted";
  input list<BackendDAE.Var> inAllPrimaryParameters "already sorted";
  input Absyn.Path inClassName;
  input String filenamePrefix;
  input String inString11;
  input list<SimCode.Function> functions;
  input list<String> externalFunctionIncludes;
  input list<String> includeDirs;
  input list<String> libs;
  input list<String> libPaths;
  input Option<SimCode.SimulationSettings> simSettingsOpt;
  input list<SimCode.RecordDeclaration> recordDecls;
  input tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> literals;
  input Absyn.FunctionArgs args;
  output SimCode.SimCode simCode;
algorithm
  simCode := matchcontinue (inBackendDAE, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs, libPaths,simSettingsOpt, recordDecls, literals, args)
    local
      String fileDir, cname;
      Integer lastEqMappingIdx, maxDelayedExpIndex, uniqueEqIndex, numberofEqns, numberOfInitialEquations, numberOfInitialAlgorithms, numStateSets;
      Integer numberofLinearSys, numberofNonLinearSys, numberofMixedSys;
      BackendDAE.BackendDAE dlow, dlow2;
      BackendDAE.BackendDAE initDAE;
      BackendDAE.IncidenceMatrix incidenceMatrix;
      DAE.FunctionTree functionTree;
      BackendDAE.SymbolicJacobians symJacs;
      Absyn.Path class_;

      // new variables
      list<SimCode.SimEqSystem> residuals;                  // --> initial_residual
      Boolean useHomotopy;                                  // true if homotopy(...) is used during initialization
      list<SimCode.SimEqSystem> initialEquations;           // --> initial_equations
      list<SimCode.SimEqSystem> removedInitialEquations;    // --> functionRemovedInitialEquations
      list<SimCode.SimEqSystem> startValueEquations;        // --> updateBoundStartValues
      list<SimCode.SimEqSystem> nominalValueEquations;      // --> updateBoundNominalValues
      list<SimCode.SimEqSystem> minValueEquations;          // --> updateBoundMinValues
      list<SimCode.SimEqSystem> maxValueEquations;          // --> updateBoundMaxValues
      list<SimCode.SimEqSystem> parameterEquations;         // --> updateBoundParameters
      list<SimCode.SimEqSystem> removedEquations;
      list<SimCode.SimEqSystem> algorithmAndEquationAsserts;
      list<SimCode.SimEqSystem> jacobianEquations;
      list<SimCode.SimEqSystem> zeroCrossingsEquations;
      //list<DAE.Statement> algorithmAndEquationAsserts;
      list<DAE.Constraint> constraints;
      list<DAE.ClassAttributes> classAttributes;
      list<BackendDAE.ZeroCrossing> zeroCrossings, sampleZC, relations;
      list<DAE.ComponentRef> discreteModelVars;
      SimCode.ExtObjInfo extObjInfo;
      SimCode.MakefileParams makefileParams;
      SimCode.DelayedExpression delayedExps;
      BackendDAE.Variables knownVars;
      list<BackendDAE.Var> varlst;
      list<BackendDAE.BaseClockPartitionKind> partitionsKind;
      list<DAE.ClockKind> baseClocks;

      list<SimCode.JacobianMatrix> LinearMatrices, SymbolicJacs, SymbolicJacsTemp, SymbolicJacsStateSelect;
      SimCode.HashTableCrefToSimVar crefToSimVarHT;
      Boolean ifcpp;
      BackendDAE.EqSystems eqs;
      BackendDAE.Shared shared;
      BackendDAE.EquationArray removedEqs;
      list<DAE.Constraint> constrsarr;
      list<DAE.ClassAttributes> clsattrsarra;

      list<DAE.Exp> lits;
      list<SimCodeVar.SimVar> tempvars;

      SimCode.JacobianMatrix jacG;
      Integer highestSccIdx, compCountPlusDummy;
      Option<BackendDAE.BackendDAE> inlineDAE;
      list<SimCode.StateSet> stateSets;
      array<Integer> systemIndexMap;
      list<tuple<Integer,Integer>> equationSccMapping, equationSccMapping1; //Maps each simEq to the scc
      array<list<Integer>> sccSimEqMapping, daeSccSimEqMapping; //Maps each scc to a list of simEqs
      array<Integer> simeqCompMapping; //Maps each simEq to the scc
      list<BackendDAE.TimeEvent> timeEvents;
      BackendDAE.StrongComponents allComps, initComps;

      HpcOmTaskGraph.TaskGraph taskGraph, taskGraphDae, taskGraphOde, taskGraphZeroFuncs, taskGraphOdeSimplified, taskGraphDaeSimplified, taskGraphZeroFuncSimplified, taskGraphOdeScheduled, taskGraphDaeScheduled, taskGraphZeroFuncScheduled, taskGraphInit;
      HpcOmTaskGraph.TaskGraphMeta taskGraphData, taskGraphDataDae, taskGraphDataOde, taskGraphDataZeroFuncs, taskGraphDataOdeSimplified, taskGraphDataDaeSimplified, taskGraphDataZeroFuncSimplified, taskGraphDataOdeScheduled, taskGraphDataDaeScheduled, taskGraphDataZeroFuncScheduled, taskGraphDataInit;
      String fileName, fileNamePrefix;
      Integer numProc;
      list<list<Integer>> parallelSets;
      list<list<Integer>> criticalPaths, criticalPathsWoC;
      Real cpCosts, cpCostsWoC, serTime, parTime, speedUp, speedUpMax;
      list<HpcOmSimCode.Task> scheduledTasksOde, scheduledTasksDae, scheduledTasksZeroFunc;
      list<Integer> scheduledDAENodes;
      list<Integer> zeroFuncsSimEqIdc;

      //Additional informations to append SimCode
      list<DAE.Exp> simCodeLiterals;
      list<SimCode.JacobianMatrix> jacobianMatrixes;
      Option<SimCode.SimulationSettings> simulationSettingsOpt;
      list<SimCode.RecordDeclaration> simCodeRecordDecls;
      list<String> simCodeExternalFunctionIncludes;

      Boolean taskGraphMetaValid, numFixed;
      String criticalPathInfo;
      array<tuple<Integer,Integer,Real>> schedulerInfo; //maps each Task to <threadId, orderId, startCalcTime>
      HpcOmSimCode.Schedule scheduleOde, scheduleDae, scheduleZeroFunc;
      array<tuple<Integer,Integer,Integer>> eqCompMapping, varCompMapping;
      Real graphCosts;
      Integer graphOps;
      Option<SimCode.BackendMapping> backendMapping;
      Option<HpcOmSimCode.MemoryMap> optTmpMemoryMap;
      list<SimCode.SimEqSystem> equationsForConditions;
      array<Option<SimCode.SimEqSystem>> simEqIdxSimEqMapping;

      array<list<SimCodeVar.SimVar>> simVarMapping; //maps each backend variable to a list of simVars
      Option<SimCode.FmiModelStructure> modelStruct;
      list<SimCodeVar.SimVar> mixedArrayVars;
      HpcOmSimCode.HpcOmData hpcomData;
      HashTableCrIListArray.HashTable varToArrayIndexMapping;
      HashTableCrILst.HashTable varToIndexMapping;
    case (BackendDAE.DAE(eqs=eqs), _, _, _, _,_, _, _, _, _, _, _, _) equation
      //Initial System
      //--------------
      //createAndExportInitialSystemTaskGraph(inInitDAE, filenamePrefix);

      //Setup
      //-----
      System.realtimeTick(ClockIndexes.RT_CLOCK_EXECSTAT_HPCOM_MODULES);
      (simCode,(lastEqMappingIdx,equationSccMapping)) =
          SimCodeUtil.createSimCode( inBackendDAE, inInitDAE, inUseHomotopy, inInitDAE_lambda0, inRemovedInitialEquationLst, inPrimaryParameters, inAllPrimaryParameters, inClassName, filenamePrefix, inString11, functions,
                                     externalFunctionIncludes, includeDirs, libs,libPaths, simSettingsOpt, recordDecls, literals, args );

      simVarMapping = SimCodeUtil.getSimVarMappingOfBackendMapping(simCode.backendMapping);
      //get SCC to simEqSys-mappping
      //----------------------------
      (allComps,_) = HpcOmTaskGraph.getSystemComponents(inBackendDAE);
      //print("All components size: " + intString(listLength(allComps)) + "\n");
      highestSccIdx = findHighestSccIdxInMapping(equationSccMapping,-1);
      compCountPlusDummy = listLength(allComps)+1;
      equationSccMapping1 = removeDummyStateFromMapping(equationSccMapping);
      //the mapping can contain a dummy state as first scc
      equationSccMapping = if intEq(highestSccIdx, compCountPlusDummy) then equationSccMapping1 else equationSccMapping;
      sccSimEqMapping = convertToSccSimEqMapping(equationSccMapping, listLength(allComps));

      simeqCompMapping = convertToSimeqCompMapping(equationSccMapping, lastEqMappingIdx);
      _ = getSimEqIdxSimEqMapping(simCode.allEquations, arrayLength(simeqCompMapping));

      //dumpSimEqSCCMapping(simeqCompMapping);
      //dumpSccSimEqMapping(sccSimEqMapping);
      SimCodeFunctionUtil.execStat("hpcom setup");

      //Get small DAE System (without removed equations)
      //------------------------------------------------
      (taskGraph,taskGraphData) = HpcOmTaskGraph.createTaskGraph(inBackendDAE);

      //Get complete DAE System
      //-----------------------
      //HpcOmTaskGraph.printTaskGraph(taskGraph);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphData);

      taskGraphDae = arrayCopy(taskGraph);
      taskGraphDataDae = HpcOmTaskGraph.copyTaskGraphMeta(taskGraphData);
      (taskGraphDae,taskGraphDataDae) = HpcOmTaskGraph.appendRemovedEquations(inBackendDAE,taskGraphDae,taskGraphDataDae);

      daeSccSimEqMapping = listArray(List.map(SimCodeUtil.getRemovedEquationSimEqSysIdxes(simCode),List.create));
      daeSccSimEqMapping = arrayAppend(sccSimEqMapping,daeSccSimEqMapping);
      schedulerInfo = arrayCreate(arrayLength(taskGraphDae), (-1,-1,-1.0));
      SimCodeUtil.execStat("hpcom create DAE TaskGraph");

      _ = checkTaskGraphMetaConsistency(taskGraphDae, taskGraphDataDae, "DAE system");
      SimCodeUtil.execStat("hpcom validate DAE TaskGraph");

      //Create Costs
      //------------
      taskGraphDataDae = HpcOmTaskGraph.createCosts(inBackendDAE, filenamePrefix + "_eqs_prof" , simeqCompMapping, taskGraphDataDae);
      taskGraphData = HpcOmTaskGraph.copyCosts(taskGraphDataDae, taskGraphData);
      SimCodeUtil.execStat("hpcom create costs");
      //print cost estimation infos
      //outputTimeBenchmark(taskGraphData,inBackendDAE);

      //Get ODE System
      //--------------
      taskGraphOde = arrayCopy(taskGraph);
      taskGraphDataOde = HpcOmTaskGraph.copyTaskGraphMeta(taskGraphData);
      (taskGraphOde,taskGraphDataOde) = HpcOmTaskGraph.getOdeSystem(taskGraphOde,taskGraphDataOde,inBackendDAE);
      SimCodeFunctionUtil.execStat("hpcom create ODE TaskGraph");

      taskGraphMetaValid = HpcOmTaskGraph.validateTaskGraphMeta(taskGraphDataOde, inBackendDAE);
      if boolNot(taskGraphMetaValid) then
        print("TaskgraphMeta ODE invalid\n");
      end if;
      SimCodeUtil.execStat("hpcom validate ODE TaskGraph");

      //print("ODE Task Graph Informations\n");
      //HpcOmTaskGraph.printTaskGraph(taskGraphOde);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphDataOde);

      //Mark all ODE nodes in the DAE Task Graph
      taskGraphDataDae = HpcOmTaskGraph.markSystemComponents(taskGraphOde, taskGraphDataOde, (false, true, false), taskGraphDataDae);

      //Get Zero Funcs System
      //---------------------
      taskGraphZeroFuncs = arrayCopy(taskGraphDae);
      taskGraphDataZeroFuncs = HpcOmTaskGraph.copyTaskGraphMeta(taskGraphDataDae);
      zeroFuncsSimEqIdc = List.map(simCode.equationsForZeroCrossings, SimCodeUtil.simEqSystemIndex);
      (taskGraphZeroFuncs,taskGraphDataZeroFuncs) = HpcOmTaskGraph.getZeroFuncsSystem(taskGraphZeroFuncs,taskGraphDataZeroFuncs, inBackendDAE, arrayLength(daeSccSimEqMapping), zeroFuncsSimEqIdc, simeqCompMapping);

      fileName = ("taskGraph"+filenamePrefix+"_ZeroFuncs.graphml");
      schedulerInfo = arrayCreate(arrayLength(taskGraphZeroFuncs), (-1,-1,-1.0));
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraphZeroFuncs, taskGraphDataZeroFuncs, fileName, "", {}, {}, daeSccSimEqMapping, schedulerInfo, HpcOmTaskGraph.GRAPHDUMPOPTIONS(false,false,true,true));
      SimCodeUtil.execStat("hpcom create and dump zeroFuncs TaskGraph");

      //Mark all event nodes in the DAE Task Graph
      taskGraphDataDae = HpcOmTaskGraph.markSystemComponents(taskGraphZeroFuncs, taskGraphDataZeroFuncs, (true, false, false), taskGraphDataDae);

      _ = checkTaskGraphMetaConsistency(taskGraphZeroFuncs, taskGraphDataZeroFuncs, "ZeroFunc system");
      _ = checkEquationCount(taskGraphDataZeroFuncs, "ZeroFunc system", listLength(zeroFuncsSimEqIdc), sccSimEqMapping);

      //Dump DAE Task Graph
      //-------------------
      //print("DAE\n");
      //HpcOmTaskGraph.printTaskGraph(taskGraphDae);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphDataDae);

      fileName = ("taskGraph"+filenamePrefix+"DAE.graphml");
      schedulerInfo = arrayCreate(arrayLength(taskGraphDae), (-1,-1,-1.0));
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraphDae, taskGraphDataDae, fileName, "", {}, {}, daeSccSimEqMapping, schedulerInfo, HpcOmTaskGraph.GRAPHDUMPOPTIONS(false,false,true,true));
      SimCodeUtil.execStat("hpcom dump DAE TaskGraph");

      //Get critical path
      //----------------------------------
      ((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC)) = HpcOmTaskGraph.getCriticalPaths(taskGraphOde,taskGraphDataOde);
      criticalPathInfo = HpcOmTaskGraph.dumpCriticalPathInfo((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC));
      ((graphOps,graphCosts)) = HpcOmTaskGraph.sumUpExeCosts(taskGraphOde,taskGraphDataOde);
      graphCosts = HpcOmTaskGraph.roundReal(graphCosts,2);
      criticalPathInfo = criticalPathInfo + " sum: (" + realString(graphCosts) + " ; " + intString(graphOps) + ")";
      fileName = ("taskGraph"+filenamePrefix+"ODE.graphml");
      schedulerInfo = arrayCreate(arrayLength(taskGraphOde), (-1,-1,-1.0));
      SimCodeUtil.execStat("hpcom assign levels / get crit. path");
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraphOde, taskGraphDataOde, fileName, criticalPathInfo, HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(criticalPaths)), HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(criticalPathsWoC)), sccSimEqMapping, schedulerInfo, HpcOmTaskGraph.GRAPHDUMPOPTIONS(true,false,true,true));
      SimCodeUtil.execStat("hpcom dump ODE TaskGraph");

      if Flags.isSet(Flags.HPCOM_DUMP) then
        print("Critical Path successfully calculated\n");
      end if;

      // Analyse Systems of Equations
      //-----------------------------
      scheduledTasksDae = {};
      (scheduledTasksOde,_) = HpcOmEqSystems.parallelizeTornSystems(taskGraphOde,taskGraphDataOde,sccSimEqMapping,simVarMapping,inBackendDAE);
      scheduledTasksZeroFunc = {};

      //Apply filters
      //-------------
      (taskGraphDaeSimplified,taskGraphDataDaeSimplified) = applyGRS(taskGraphDae,taskGraphDataDae);
      (taskGraphOdeSimplified,taskGraphDataOdeSimplified) = applyGRS(taskGraphOde,taskGraphDataOde);
      (taskGraphZeroFuncSimplified,taskGraphDataZeroFuncSimplified) = applyGRS(taskGraphZeroFuncs,taskGraphDataZeroFuncs);
      SimCodeUtil.execStat("hpcom GRS");

      fileName = ("taskGraph"+filenamePrefix+"ODE_merged.graphml");
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraphOdeSimplified, taskGraphDataOdeSimplified, fileName, criticalPathInfo, HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(criticalPaths)), HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(criticalPathsWoC)), sccSimEqMapping, schedulerInfo, HpcOmTaskGraph.GRAPHDUMPOPTIONS(true,false,true,true));
      SimCodeUtil.execStat("hpcom dump simplified TaskGraph");

      if Flags.isSet(Flags.HPCOM_DUMP) then
        print("Filter successfully applied. Merged "+intString(intSub(arrayLength(taskGraphOde),arrayLength(taskGraphOdeSimplified)))+" tasks.\n");
      end if;

      //Create schedule
      //---------------
      numProc = Flags.getConfigInt(Flags.NUM_PROC);
      (numProc,_) = setNumProc(numProc,cpCostsWoC,taskGraphDataOde);//in case n-flag is not set

      (scheduleDae,simCode,taskGraphDaeScheduled,taskGraphDataDaeScheduled,sccSimEqMapping) = createSchedule(taskGraphDaeSimplified,taskGraphDataDaeSimplified,daeSccSimEqMapping,simVarMapping,filenamePrefix,numProc,numProc,simCode,scheduledTasksDae,"DAE system",Flags.getConfigString(Flags.HPCOM_SCHEDULER));
           //HpcOmScheduler.printSchedule(scheduleDae);
           //schedulerInfo = HpcOmScheduler.convertScheduleStrucToInfo(scheduleDae,arrayLength(taskGraphDaeScheduled));
           //HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraphDaeScheduled, taskGraphDataDaeScheduled, "taskGraph"+filenamePrefix+"DAE_scheduled.graphml", "", HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(criticalPaths)), HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(criticalPathsWoC)), sccSimEqMapping, schedulerInfo, HpcOmTaskGraph.GRAPHDUMPOPTIONS(false,false,false,false));

      (scheduleOde,simCode,taskGraphOdeScheduled,taskGraphDataOdeScheduled,sccSimEqMapping) = createSchedule(taskGraphOdeSimplified,taskGraphDataOdeSimplified,sccSimEqMapping,simVarMapping,filenamePrefix,numProc,numProc,simCode,scheduledTasksOde,"ODE system",Flags.getConfigString(Flags.HPCOM_SCHEDULER));
           //HpcOmScheduler.printSchedule(scheduleOde);
           //schedulerInfo = HpcOmScheduler.convertScheduleStrucToInfo(scheduleOde,arrayLength(taskGraphOdeScheduled));
           //HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraphOdeScheduled, taskGraphDataOdeScheduled, "taskGraph"+filenamePrefix+"ODE_scheduled.graphml", "", HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(criticalPaths)), HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(criticalPathsWoC)), sccSimEqMapping, schedulerInfo, HpcOmTaskGraph.GRAPHDUMPOPTIONS(false,false,false,false));

      (scheduleZeroFunc,simCode,taskGraphZeroFuncScheduled,taskGraphDataZeroFuncScheduled,sccSimEqMapping) = createSchedule(taskGraphZeroFuncSimplified,taskGraphDataZeroFuncSimplified,daeSccSimEqMapping,simVarMapping,filenamePrefix,numProc,numProc,simCode,scheduledTasksZeroFunc,"ZeroFunc system",Flags.getConfigString(Flags.HPCOM_SCHEDULER));
           //HpcOmScheduler.printSchedule(scheduleZeroFunc);
           //schedulerInfo = HpcOmScheduler.convertScheduleStrucToInfo(scheduleZeroFunc,arrayLength(taskGraphZeroFuncScheduled));
           //HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraphZeroFuncScheduled, taskGraphDataZeroFuncScheduled, "taskGraph"+filenamePrefix+"ZF_scheduled.graphml", "", HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(criticalPaths)), HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(criticalPathsWoC)), sccSimEqMapping, schedulerInfo, HpcOmTaskGraph.GRAPHDUMPOPTIONS(false,false,false,false));

      //(schedule,numProc) = repeatScheduleWithOtherNumProc(taskGraphSimplified,taskGraphDataSimplified,sccSimEqMapping,filenamePrefix,cpCostsWoC,schedule,numProc,numFixed);
      numProc = Flags.getConfigInt(Flags.NUM_PROC);
      criticalPathInfo = HpcOmScheduler.analyseScheduledTaskGraph(scheduleOde,numProc,taskGraphOdeScheduled,taskGraphDataOdeScheduled,"ODE system");
      schedulerInfo = HpcOmScheduler.convertScheduleStrucToInfo(scheduleOde,arrayLength(taskGraphOdeScheduled));
      SimCodeFunctionUtil.execStat("hpcom create schedule");

      fileName = ("taskGraph"+filenamePrefix+"ODE_schedule.graphml");
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraphOdeScheduled, taskGraphDataOdeScheduled, fileName, criticalPathInfo, HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(criticalPaths)), HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(criticalPathsWoC)), sccSimEqMapping, schedulerInfo, HpcOmTaskGraph.GRAPHDUMPOPTIONS(true,false,true,true));
      //HpcOmScheduler.printSchedule(scheduleOde);
      SimCodeUtil.execStat("hpcom dump schedule TaskGraph");

      if Flags.isSet(Flags.HPCOM_DUMP) then
        print("Schedule created\n");
      end if;

      //Check ODE-System size
      //---------------------
      System.realtimeTick(ClockIndexes.RT_CLOCK_EXECSTAT_HPCOM_MODULES);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphDataScheduled);

      checkOdeSystemSize(taskGraphDataOdeScheduled, simCode.odeEquations, sccSimEqMapping);
      SimCodeFunctionUtil.execStat("hpcom check ODE system size");

      //Create Memory-Map and Sim-Code
      //------------------------------
      (optTmpMemoryMap, varToArrayIndexMapping, varToIndexMapping) = HpcOmMemory.createMemoryMap(simCode.modelInfo, simCode.varToArrayIndexMapping, simCode.varToIndexMapping, taskGraphOdeSimplified, BackendDAEUtil.transposeMatrix(taskGraphOdeSimplified,arrayLength(taskGraphOdeSimplified)), taskGraphDataOdeSimplified, eqs, filenamePrefix, schedulerInfo, scheduleOde, sccSimEqMapping, criticalPaths, criticalPathsWoC, criticalPathInfo, numProc, allComps);

      //BaseHashTable.dumpHashTable(varToArrayIndexMapping);

      SimCodeFunctionUtil.execStat("hpcom create memory map");
      simCode.varToArrayIndexMapping = varToArrayIndexMapping;
      simCode.varToIndexMapping = varToIndexMapping;

      simCode.hpcomData = HpcOmSimCode.HPCOMDATA(SOME((scheduleOde, scheduleDae, scheduleZeroFunc)), optTmpMemoryMap);

      //print("Number of literals post: " + intString(listLength(simCodeLiterals)) + "\n");

      SimCodeFunctionUtil.execStat("hpcom other");
      print("HpcOm is still under construction.\n");
      then simCode;
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"function createSimCode failed."});
    then fail();
  end matchcontinue;
end createSimCode;

protected function createAndExportInitialSystemTaskGraph "author: marcusw
  Create the task graph for the initial system and write it to graphML."
  input Option<BackendDAE.BackendDAE> iInitDae;
  input String iFileNamePrefix;
protected
  BackendDAE.BackendDAE initDAE;
  HpcOmTaskGraph.TaskGraph tmpTaskGraph;
  HpcOmTaskGraph.TaskGraphMeta tmpTaskGraphMeta;
  String fileName;
  array<list<Integer>> sccSimEqMapping;
  array<tuple<Integer,Integer,Real>> schedulerInfo;
algorithm
  _ := match(iInitDae, iFileNamePrefix)
    case(SOME(initDAE), _)
      equation
        (tmpTaskGraph, tmpTaskGraphMeta) = HpcOmTaskGraph.createTaskGraph(initDAE);
        fileName = ("taskGraph"+iFileNamePrefix+"_init.graphml");
        schedulerInfo = arrayCreate(arrayLength(tmpTaskGraph), (-1,-1,-1.0));
        sccSimEqMapping = arrayCreate(arrayLength(tmpTaskGraph), {});
        HpcOmTaskGraph.dumpAsGraphMLSccLevel(tmpTaskGraph, tmpTaskGraphMeta, fileName, "", {}, {}, sccSimEqMapping ,schedulerInfo, HpcOmTaskGraph.GRAPHDUMPOPTIONS(false,false,true,true));
      then ();
    else ();
  end match;
end createAndExportInitialSystemTaskGraph;

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
        if realNe(serCosts,0.0) then
          maxSpeedUp = realDiv(serCosts,cpCosts);
          numProcSched = realInt(realAdd(maxSpeedUp,1.0));
          numProcSys = System.numProcessors();
          numProc = intMin(numProcSched,numProcSys);
          string1 = "Your system provides only "+intString(numProcSys)+" processors!\n";
          string2 = intString(numProcSched)+" processors might be a reasonable number of processors.\n";
          string1 = if intGt(numProcSched,numProcSys) then string1 else string2;
          print("Please set the number of processors you want to use!\n");
          print(string1);
        else
          numProc = 1;
          print("You did not choose a number of cores. Since there is no ODE-System, the number of cores is set to 1!\n");
        end if;
        Flags.setConfigInt(Flags.NUM_PROC,numProc);
      then
        (numProc,true);
    else
      equation
        numProcSys = System.numProcessors();
        if intGt(numProcFlag,numProcSys) and Flags.isSet(Flags.HPCOM_DUMP) then
          print("Warning: Your system provides only "+intString(numProcSys)+" processors!\n");
        end if;
      then
        (numProcFlag,true);
  end match;
end setNumProc;


public function applyGRS"applies several task graph rewriting rules to merge tasks. builds a new incidence matrix for the task graph after finishing their merging
author:Waurich 2014-11"
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  output HpcOmTaskGraph.TaskGraph oTaskGraph;
  output HpcOmTaskGraph.TaskGraphMeta oTaskGraphMeta;
protected
    HpcOmTaskGraph.TaskGraph taskGraph1,taskGraphT;
    HpcOmTaskGraph.TaskGraphMeta taskGraphMeta1;
    array<Integer> contractedTasks;
    array<tuple<Integer,Integer,Real>> schedulerInfo;
    String fileName;
 algorithm
   taskGraph1 := arrayCopy(iTaskGraph);
   taskGraphT := BackendDAEUtil.transposeMatrix(taskGraph1,arrayLength(taskGraph1));
   taskGraphMeta1 := HpcOmTaskGraph.copyTaskGraphMeta(iTaskGraphMeta);
   contractedTasks := arrayCreate(arrayLength(taskGraph1),0);
   // contract nodes in the graph
   (taskGraph1,taskGraphT,taskGraphMeta1) := applyGRS1(taskGraph1,taskGraphT,taskGraphMeta1,contractedTasks,true);

/*
   //DEBUG
   (taskGraph1,taskGraphMeta1) := GRS_newGraph(taskGraph1,taskGraphMeta1,contractedTasks);
   taskGraphT := BackendDAEUtil.transposeMatrix(taskGraph1,arrayLength(taskGraph1));
   fileName := ("taskGraphMergeDebug.graphml");
   schedulerInfo := arrayCreate(arrayLength(taskGraph1), (-1,-1,-1.0));
   HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraph1, taskGraphMeta1, fileName, "", {}, {}, iSccSimEqMapping, schedulerInfo, HpcOmTaskGraph.GRAPHDUMPOPTIONS(false,false,true,true));
   contractedTasks := arrayCreate(arrayLength(taskGraph1),0);
*/

   // contract nodes schedule specific
   //(taskGraph1,taskGraphT,taskGraphMeta1) := applyGRSForScheduler(taskGraph1, taskGraphT, taskGraphMeta1, contractedTasks); //not working at the moment
   // build new taskGraph
   (oTaskGraph,oTaskGraphMeta) := GRS_newGraph(taskGraph1,taskGraphMeta1,contractedTasks);
   //(oTaskGraph,oTaskGraphMeta) := (taskGraph1,taskGraphMeta1);
end applyGRS;


public function applyGRS1"applies several task graph rewriting rules to merge tasks.
author:Waurich 2014-11"
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Integer> contractedTasksIn; // is updated on the fly
  input Boolean again;
  output HpcOmTaskGraph.TaskGraph oTaskGraph;
  output HpcOmTaskGraph.TaskGraph oTaskGraphT;
  output HpcOmTaskGraph.TaskGraphMeta oTaskGraphMeta;
algorithm
  (oTaskGraph,oTaskGraphT,oTaskGraphMeta) := match(iTaskGraph,iTaskGraphT,iTaskGraphMeta,contractedTasksIn,again)
    local
      Boolean changed,changed2;
      HpcOmTaskGraph.TaskGraph tmpTaskGraph, tmpTaskGraphT;
      HpcOmTaskGraph.TaskGraphMeta tmpTaskGraphMeta;
      array<Integer> tmpContractedTasks;
    case(_,_,_,_,true)
      equation
        //Merge nodes
        (tmpTaskGraph,tmpTaskGraphT,tmpTaskGraphMeta,tmpContractedTasks,changed) = HpcOmTaskGraph.mergeSimpleNodes(iTaskGraph, iTaskGraphT, iTaskGraphMeta, contractedTasksIn);
        (tmpTaskGraph,tmpTaskGraphT,tmpTaskGraphMeta,tmpContractedTasks,changed2) = HpcOmTaskGraph.mergeParentNodes(tmpTaskGraph, tmpTaskGraphT, tmpTaskGraphMeta, tmpContractedTasks);
        changed = changed or changed2;
        //Repeat if something has changed
      then applyGRS1(tmpTaskGraph,tmpTaskGraphT,tmpTaskGraphMeta,tmpContractedTasks,changed);
    else (iTaskGraph, iTaskGraphT, iTaskGraphMeta);
  end match;
end applyGRS1;

public function applyGRSForScheduler "applies graph rewriting rules that are specific for the scheduler.
author:mwalther 2014-12"
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Integer> iContractedTasks; // is updated on the fly
  output HpcOmTaskGraph.TaskGraph oTaskGraph;
  output HpcOmTaskGraph.TaskGraph oTaskGraphT;
  output HpcOmTaskGraph.TaskGraphMeta oTaskGraphMeta;
protected
  String flagValue;
  list<list<Integer>> levelNodes, contractedNodes;
  HpcOmTaskGraph.TaskGraph tmpTaskGraph, tmpTaskGraphT;
  HpcOmTaskGraph.TaskGraphMeta tmpTaskGraphMeta;
algorithm
  (oTaskGraph,oTaskGraphT,oTaskGraphMeta) := matchcontinue(iTaskGraph,iTaskGraphT,iTaskGraphMeta,iContractedTasks)
    case(_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "levelfix");
        levelNodes = HpcOmTaskGraph.getLevelNodes(iTaskGraph);
        contractedNodes = applyGRSForLevelFixScheduler(iTaskGraphMeta, iContractedTasks, levelNodes, {});
        //print("applyGRSForScheduler: number of merged-node groups=" + intString(listLength(contractedNodes)) + "\n");
        (tmpTaskGraph,tmpTaskGraphT,tmpTaskGraphMeta,_) = HpcOmTaskGraph.contractNodesInGraph(contractedNodes,iTaskGraph,iTaskGraphT,iTaskGraphMeta,iContractedTasks);
      then (tmpTaskGraph,tmpTaskGraphT,tmpTaskGraphMeta);
    else (iTaskGraph, iTaskGraphT, iTaskGraphMeta);
  end matchcontinue;
end applyGRSForScheduler;

public function applyGRSForLevelFixScheduler "merges all tasks of one and the same level together, if the execution costs are below 2000 cycles
author:mwalther 2014-12"
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Integer> iContractedTasks; //previously contracted nodes
  input list<list<Integer>> iLevelNodes; //all nodes of all levels
  input list<list<Integer>> iContractedLevelfixTasks;
  output list<list<Integer>> oContractedLevelfixTasks;
protected
  list<list<Integer>> rest;
  list<Integer> head, sortedHead;
  array<Integer> sortedHeadArray;
  list<list<Integer>> tmpContractedLevelfixTasks;
  array<tuple<Integer, Real>> exeCosts;
  Real bigTaskExecTime;
  array<list<Integer>> inComps;
  HpcOmTaskGraph.TaskGraph tmpTaskGraph, tmpTaskGraphT;
  HpcOmTaskGraph.TaskGraphMeta tmpTaskGraphMeta;
algorithm
  oContractedLevelfixTasks := match(iTaskGraphMeta, iContractedTasks, iLevelNodes, iContractedLevelfixTasks)
    case(HpcOmTaskGraph.TASKGRAPHMETA(exeCosts=exeCosts,inComps=inComps),_,head::rest,_)
      equation
        sortedHead = List.sort(head, function HpcOmTaskGraph.compareTasksByExecTime(iExeCosts=exeCosts,iTaskComps=inComps));
        //print("applyGRSForLevelFixScheduler - Handling level with sorted nodes: " + stringDelimitList(List.map(sortedHead, intString), ",") + "\n");
        sortedHeadArray = listArray(sortedHead);

        if(intGt(arrayLength(sortedHeadArray), 0)) then
          bigTaskExecTime = HpcOmTaskGraph.getExeCostReqCycles(arrayGet(sortedHeadArray, arrayLength(sortedHeadArray)), iTaskGraphMeta);
        else
          bigTaskExecTime = 0.0;
        end if;

        tmpContractedLevelfixTasks = applyGRSForLevelFixSchedulerLevel(iTaskGraphMeta, iContractedTasks, 500, sortedHeadArray, 1, (arrayLength(sortedHeadArray), {}, bigTaskExecTime), iContractedLevelfixTasks);
        tmpContractedLevelfixTasks = applyGRSForLevelFixScheduler(iTaskGraphMeta, iContractedTasks, rest, tmpContractedLevelfixTasks);
      then tmpContractedLevelfixTasks;
    else iContractedLevelfixTasks;
  end match;
end applyGRSForLevelFixScheduler;

public function applyGRSForLevelFixSchedulerLevel "merges small and big nodes of the same level into one, until they reach a critical size
author:mwalther 2014-12"
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Integer> iContractedTasks;
  input Integer iCriticalSize;
  input array<Integer> iSortedLevelTasks; //tasks of the current level
  input Integer iCurrentSmallTask; //array-idx of iSortedLevelTasks pointing to the smallest task that is not already merged
  input tuple<Integer, list<Integer>, Real> iCurrentBigTask;  //<array-idx of iSortedLevelTasks pointing to the biggest task that is not already merged, list of tasks that should be merged with the big task, executionCostSum>
  input list<list<Integer>> iContractedLevelfixTasks;
  output list<list<Integer>> oContractedLevelfixTasks;
protected
  array<tuple<Integer, Real>> exeCosts;
  list<list<Integer>> tmpContractedTasks;
  list<Integer> head, bigTaskChilds;
  Real mergedGroupExecTime;
  Integer bigTaskIdx;
  HpcOmTaskGraph.TaskGraph tmpTaskGraph, tmpTaskGraphT;
  HpcOmTaskGraph.TaskGraphMeta tmpTaskGraphMeta;
algorithm
  oContractedLevelfixTasks := matchcontinue(iTaskGraphMeta, iContractedTasks, iCriticalSize, iSortedLevelTasks, iCurrentSmallTask, iCurrentBigTask, iContractedLevelfixTasks)
    case(_,_,_,_,_,(bigTaskIdx, bigTaskChilds, mergedGroupExecTime),tmpContractedTasks)
      equation
        true = intLe(bigTaskIdx, iCurrentSmallTask); // the index of the big task is smaller or equal to the small task index
        //print("applyGRSForLevelFixSchedulerLevel: terminating recursion with list " + stringDelimitList(List.map(bigTaskChilds, intString), ",") + "\n");
        if(intGt(listLength(bigTaskChilds), 0)) then
          //print("applyGRSForLevelFixSchedulerLevel: appending node to merged group\n");
          tmpContractedTasks = (arrayGet(iSortedLevelTasks,bigTaskIdx)::bigTaskChilds)::tmpContractedTasks; //append the merged tasks list to result list
        end if;
      then tmpContractedTasks;
    case(_,_,_,_,_,(bigTaskIdx, bigTaskChilds, mergedGroupExecTime),_)
      equation
        true = HpcOmTaskGraph.isNodeContracted(bigTaskIdx, iContractedTasks);
        //print("applyGRSForLevelFixSchedulerLevel: skipping big node " + intString(arrayGet(iSortedLevelTasks ,bigTaskIdx)) + " because it is already contracted\n");
        if(intGt(bigTaskIdx, 1)) then
          mergedGroupExecTime = HpcOmTaskGraph.getExeCostReqCycles(arrayGet(iSortedLevelTasks, bigTaskIdx-1), iTaskGraphMeta);
        else
          mergedGroupExecTime = 0.0;
        end if;
        //Big node is already contracted - skip it
        tmpContractedTasks = applyGRSForLevelFixSchedulerLevel(iTaskGraphMeta, iContractedTasks, iCriticalSize, iSortedLevelTasks, iCurrentSmallTask, (bigTaskIdx-1, {}, mergedGroupExecTime), iContractedLevelfixTasks);
      then tmpContractedTasks;
    case(_,_,_,_,_,(bigTaskIdx, bigTaskChilds, mergedGroupExecTime),_)
      equation
        true = HpcOmTaskGraph.isNodeContracted(iCurrentSmallTask, iContractedTasks);
        //Small node is already contracted - skip it
        //print("applyGRSForLevelFixSchedulerLevel: skipping small node " + intString(arrayGet(iSortedLevelTasks ,iCurrentSmallTask)) + " because it is already contracted\n");
        tmpContractedTasks = applyGRSForLevelFixSchedulerLevel(iTaskGraphMeta, iContractedTasks, iCriticalSize, iSortedLevelTasks, iCurrentSmallTask+1, (bigTaskIdx, bigTaskChilds, mergedGroupExecTime), iContractedLevelfixTasks);
      then tmpContractedTasks;
    case(_,_,_,_,_,(bigTaskIdx, bigTaskChilds, mergedGroupExecTime),tmpContractedTasks)
      equation
        //print("applyGRSForLevelFixSchedulerLevel:In with current group size: " + realString(mergedGroupExecTime) + " \n");
        mergedGroupExecTime = mergedGroupExecTime + HpcOmTaskGraph.getExeCostReqCycles(arrayGet(iSortedLevelTasks, iCurrentSmallTask), iTaskGraphMeta);
        if(realGe(mergedGroupExecTime, iCriticalSize)) then
          if(intGt(listLength(bigTaskChilds), 0)) then
            //print("appending node to merged group\n");
            tmpContractedTasks = (arrayGet(iSortedLevelTasks, bigTaskIdx)::bigTaskChilds)::tmpContractedTasks; //append the merged tasks list to result list
          end if;

          if(intGt(bigTaskIdx, 1)) then
            mergedGroupExecTime = HpcOmTaskGraph.getExeCostReqCycles(arrayGet(iSortedLevelTasks, bigTaskIdx-1), iTaskGraphMeta);
          else
            mergedGroupExecTime = 0.0;
          end if;
          // big task is already large enough, no merging required
          tmpContractedTasks = applyGRSForLevelFixSchedulerLevel(iTaskGraphMeta, iContractedTasks, iCriticalSize, iSortedLevelTasks, iCurrentSmallTask, (bigTaskIdx-1, {}, mergedGroupExecTime), tmpContractedTasks);
        else
          //print("applyGRSForLevelFixSchedulerLevel: merging small node " + intString(arrayGet(iSortedLevelTasks ,iCurrentSmallTask)) + " with big task " + intString(arrayGet(iSortedLevelTasks ,bigTaskIdx)) + "\n");
          //print("applyGRSForLevelFixSchedulerLevel: current group size: " + realString(mergedGroupExecTime) + " \n");
          //merge small and big task into one
          tmpContractedTasks = applyGRSForLevelFixSchedulerLevel(iTaskGraphMeta, iContractedTasks, iCriticalSize, iSortedLevelTasks, iCurrentSmallTask+1, (bigTaskIdx, arrayGet(iSortedLevelTasks, iCurrentSmallTask)::bigTaskChilds, mergedGroupExecTime), tmpContractedTasks);
        end if;
      then tmpContractedTasks;
    else iContractedLevelfixTasks;
  end matchcontinue;
end applyGRSForLevelFixSchedulerLevel;

protected function GRS_newGraph"build a new task graph and update the inComps for the merged nodes.
author:Waurich TUD 2014-11"
  input HpcOmTaskGraph.TaskGraph graphIn;
  input HpcOmTaskGraph.TaskGraphMeta metaIn;
  input array<Integer> contrTasks;
  output HpcOmTaskGraph.TaskGraph graphOut;
  output HpcOmTaskGraph.TaskGraphMeta metaOut;
protected
  Integer newSize;
  list<Integer> notRemovedNodes,removedNodes;
  array<list<Integer>> inComps,inCompsNew;
algorithm
  //print("GRS_newGraph: " + stringDelimitList(List.map(arrayList(contrTasks), intString), ",") + "\n");
  HpcOmTaskGraph.TASKGRAPHMETA(inComps = inComps) := metaIn;
  notRemovedNodes := HpcOmTaskGraph.filterContractedNodes(List.intRange(arrayLength(graphIn)),contrTasks);
  removedNodes := HpcOmTaskGraph.filterNonContractedNodes(List.intRange(arrayLength(graphIn)),contrTasks);
  newSize := listLength(notRemovedNodes);
  graphOut := arrayCreate(newSize,{});
  inCompsNew := arrayCreate(newSize,{});
  (graphOut,inCompsNew) := GRS_newGraph2(notRemovedNodes,removedNodes,contrTasks,graphIn,inComps,graphOut,inCompsNew,1);
  metaOut := HpcOmTaskGraph.setInCompsInMeta(inCompsNew,metaIn);
end GRS_newGraph;

protected function GRS_newGraph2"build a new task graph and update the inComps for the merged nodes.
author: Waurich TUD 2014-11"
  input list<Integer> origNodes;
  input list<Integer> removedNodes;
  input array<Integer> contrTasks;
  input HpcOmTaskGraph.TaskGraph origGraph;
  input array<list<Integer>> origInComps;
  input HpcOmTaskGraph.TaskGraph newGraph;
  input array<list<Integer>> newInComps;
  input Integer newNode;
  output HpcOmTaskGraph.TaskGraph graphOut;
  output array<list<Integer>> inCompsOut;
algorithm
  (graphOut,inCompsOut) := match(origNodes,removedNodes,contrTasks,origGraph,origInComps,newGraph,newInComps,newNode)
    local
      Integer node;
      list<Integer> rest,row,comps;
    case({},_,_,_,_,_,_,_)
      equation
      then (newGraph,newInComps);
    case(node::rest,_,_,_,_,_,_,_)
      equation
      //print("origNode "+intString(node)+" and newNode "+intString(newNode)+"\n");
      row = arrayGet(origGraph,node);
      row = HpcOmTaskGraph.filterContractedNodes(row,contrTasks);
      row = HpcOmTaskGraph.updateContinuousEntriesInList(row,removedNodes);

      comps = arrayGet(origInComps,node);
      //print("comps1 "+stringDelimitList(List.map(comps,intString),", ")+"\n");
      arrayUpdate(newGraph,newNode,row);
      //comps = List.sort(comps,intGt);
      arrayUpdate(newInComps,newNode,comps);
    then GRS_newGraph2(rest,removedNodes,contrTasks,origGraph,origInComps,newGraph,newInComps,newNode+1);
  end match;
end GRS_newGraph2;


protected function createSchedule "create a schedule for the given task graph and the given number of processors.
author: mwalther, Waurich TUD"
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<list<Integer>> iSccSimEqMapping;
  input array<list<SimCodeVar.SimVar>> iSimVarMapping;
  input String iFilenamePrefix;
  input Integer iNumProc; //the max. number of processors
  input Integer iNumProcToUse; //the number of processors that should be used to calculate the given task graph (iNumProcToUse <= iNumProc)
  input SimCode.SimCode iSimCode;
  input list<HpcOmSimCode.Task> iScheduledTasks;
  input String iSystemName; //e.g. "ODE system" or "DAE system"
  input String iSchedulerName;
  output HpcOmSimCode.Schedule oSchedule;
  output SimCode.SimCode oSimCode;
  output HpcOmTaskGraph.TaskGraph oTaskGraph;
  output HpcOmTaskGraph.TaskGraphMeta oTaskGraphMeta;
  output array<list<Integer>> oSccSimEqMapping;
protected
  list<String> knownScheduler = {"none","level","levelfix","ext","metis","hmet","listr","rand","list","mcp","part","taskdep","tds","bls","sbs","sts"};
  String schedulerName = iSchedulerName;
  HpcOmSimCode.Schedule tmpSchedule;
  Integer numProcToUse = iNumProcToUse;
algorithm
  if(boolNot(List.exist1(knownScheduler,stringEq,schedulerName))) then
    print("HpcOmScheduler.createSchedule warning: The scheduler '" + iSchedulerName + "' is unknown. The list-scheduling algorithm is used instead for the " + iSystemName + ".\n");
    schedulerName := "list";
  end if;
  if(intGt(iNumProcToUse, iNumProc)) then
    print("HpcOmScheduler.createSchedule warning: Cannot schedule the the task graph to " + intString(iNumProcToUse) + " processors, because the number is larger than the available processors (" + intString(iNumProc) + ").\n");
    numProcToUse := iNumProc;
  end if;
  (tmpSchedule,oSimCode,oTaskGraph,oTaskGraphMeta,oSccSimEqMapping) := createSchedule1(iTaskGraph, iTaskGraphMeta, iSccSimEqMapping, iSimVarMapping, iFilenamePrefix, numProcToUse, iSimCode, iScheduledTasks, iSystemName, schedulerName);
  oSchedule := HpcOmScheduler.expandSchedule(iNumProc, numProcToUse, tmpSchedule);
end createSchedule;

protected function createSchedule1 "check if the given scheduler is known and create it, otherwise fail
author: mwalther, Waurich TUD"
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<list<Integer>> iSccSimEqMapping;
  input array<list<SimCodeVar.SimVar>> iSimVarMapping;
  input String iFilenamePrefix;
  input Integer iNumProc;
  input SimCode.SimCode iSimCode;
  input list<HpcOmSimCode.Task> iScheduledTasks;
  input String iSystemName; //e.g. "ODE system" or "DAE system"
  input String iSchedulerName;
  output HpcOmSimCode.Schedule oSchedule;
  output SimCode.SimCode oSimCode;
  output HpcOmTaskGraph.TaskGraph oTaskGraph;
  output HpcOmTaskGraph.TaskGraphMeta oTaskGraphMeta;
  output array<list<Integer>> oSccSimEqMapping;
protected
  list<Integer> lst;
  array<list<Integer>> sccSimEqMap;
  HpcOmSimCode.Schedule schedule;
  HpcOmTaskGraph.TaskGraph taskGraph1;
  HpcOmTaskGraph.TaskGraphMeta taskGraphMeta1;
  SimCode.SimCode simCode;
algorithm
  (oSchedule,oSimCode,oTaskGraph,oTaskGraphMeta,oSccSimEqMapping) := matchcontinue(iTaskGraph,iTaskGraphMeta,iSccSimEqMapping,iSimVarMapping,iFilenamePrefix,iNumProc,iSimCode,iScheduledTasks,iSystemName,iSchedulerName)
    case(_,_,_,_,_,_,_,_,_,"none")
      equation
        print("Using serial code for the " + iSystemName + "\n");
        schedule = HpcOmScheduler.createEmptySchedule(iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
      then
        (schedule,iSimCode,iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_,_,_,_,_,_,_,"level")
      equation
        print("Using level Scheduler for the " + iSystemName + "\n");
        (schedule,taskGraphMeta1) = HpcOmScheduler.createLevelSchedule(iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
      then (schedule,iSimCode,iTaskGraph,taskGraphMeta1,iSccSimEqMapping);
    case(_,_,_,_,_,_,_,_,_,"levelfix")
      equation
        print("Using fixed level Scheduler (experimental) for the " + iSystemName + "\n");
        (schedule,taskGraphMeta1) = HpcOmScheduler.createFixedLevelSchedule(iTaskGraph,iTaskGraphMeta,iNumProc,iSccSimEqMapping);
      then (schedule,iSimCode,iTaskGraph,taskGraphMeta1,iSccSimEqMapping);
    case(_,_,_,_,_,_,_,_,_,"ext")
      equation
        print("Using external Scheduler for the " + iSystemName + "\n");
        schedule = HpcOmScheduler.createExtSchedule(iTaskGraph, iTaskGraphMeta, iNumProc, iSccSimEqMapping, iSimVarMapping, "taskGraph" + iFilenamePrefix + "_ext.graphml");
      then (schedule,iSimCode,iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_,_,_,_,_,_,_,"metis")
      equation
        print("Using METIS Scheduler for the " + iSystemName + "\n");
        schedule = HpcOmScheduler.createMetisSchedule(iTaskGraph, iTaskGraphMeta, iNumProc, iSccSimEqMapping, iSimVarMapping);
      then (schedule,iSimCode,iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_,_,_,_,_,_,_,"hmet")
      equation
        print("Using hMETIS Scheduler for the " + iSystemName + "\n");
        schedule = HpcOmScheduler.createHMetisSchedule(iTaskGraph, iTaskGraphMeta, iNumProc, iSccSimEqMapping,iSimVarMapping);
      then (schedule,iSimCode,iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_,_,_,_,_,_,_,"listr")
      equation
        print("Using list reverse Scheduler for the " + iSystemName + "\n");
        schedule = HpcOmScheduler.createListScheduleReverse(iTaskGraph,iTaskGraphMeta,iNumProc,iSccSimEqMapping, iSimVarMapping);
      then (schedule,iSimCode,iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_,_,_,_,_,_,_,"rand")
      equation
        print("Using Random Scheduler for the " + iSystemName + "\n");
        schedule = HpcOmScheduler.createRandomSchedule(iTaskGraph, iTaskGraphMeta, iNumProc, iSccSimEqMapping, iSimVarMapping);
      then (schedule,iSimCode,iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_,_,_,_,_,_,_,"list")
      equation
        print("Using list Scheduler for the " + iSystemName + "\n");
        schedule = HpcOmScheduler.createListSchedule(iTaskGraph,iTaskGraphMeta,iNumProc,iSccSimEqMapping, iSimVarMapping);
      then (schedule,iSimCode,iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_,_,_,_,_,_,_,"mcp")
      equation
        print("Using Modified Critical Path Scheduler for the " + iSystemName + "\n");
        schedule = HpcOmScheduler.createMCPschedule(iTaskGraph,iTaskGraphMeta,iNumProc,iSccSimEqMapping,iSimVarMapping);
      then (schedule,iSimCode,iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_,_,_,_,_,_,_,"part")
      equation
        print("Using partition Scheduler for the " + iSystemName + "\n");
        schedule = HpcOmScheduler.createPartSchedule(iTaskGraph,iTaskGraphMeta,iNumProc,iSccSimEqMapping,iSimVarMapping);
      then (schedule,iSimCode,iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_,_,_,_,_,_,_,"taskdep")
      equation
        print("Using dynamic task dependencies for the " + iSystemName + "\n");
        schedule = HpcOmScheduler.createTaskDepSchedule(iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
      then (schedule,iSimCode,iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_,_,_,_,_,_,_,"tds")
      equation
        print("Using Task Duplication-based Scheduling for the " + iSystemName + "\n");
        (schedule,simCode,taskGraph1,taskGraphMeta1,sccSimEqMap) = HpcOmScheduler.TDS_schedule(iTaskGraph,iTaskGraphMeta,iNumProc,iSccSimEqMapping,iSimVarMapping,iSimCode);
      then (schedule,simCode,taskGraph1,taskGraphMeta1,sccSimEqMap);
    case(_,_,_,_,_,_,_,_,_,"bls")
      equation
        print("Using Balanced Level Scheduling for the " + iSystemName + "\n");
        (schedule,taskGraphMeta1) = HpcOmScheduler.createBalancedLevelScheduling(iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
      then (schedule,iSimCode,iTaskGraph,taskGraphMeta1,iSccSimEqMapping);
    case(_,_,_,_,_,_,_,_,_,"sbs")
      equation
        print("Using Single Block Scheduling for the " + iSystemName + "\n");
        schedule = HpcOmEqSystems.createSingleBlockSchedule(iTaskGraph,iTaskGraphMeta,iScheduledTasks,iSccSimEqMapping);
      then (schedule,iSimCode,iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_,_,_,_,_,_,_,"sts")
      equation
        print("Using Single Thread Scheduling for the " + iSystemName + "\n");
        schedule = HpcOmScheduler.createSingleThreadSchedule(iTaskGraph,iTaskGraphMeta,iSccSimEqMapping,iNumProc);
      then (schedule,iSimCode,iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
    else
      equation
        print("HpcOmSimCode.createSchedule failed!\n");
        schedule = HpcOmScheduler.createEmptySchedule(iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
      then (schedule,iSimCode,iTaskGraph,iTaskGraphMeta,iSccSimEqMapping);
  end matchcontinue;
end createSchedule1;


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
  //print("convertToSccSimEqMapping with " + intString(numOfSccs) + " sccs.\n");
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
  //print("convertToSccSimEqMapping1 accessing index " + intString(i2) + ".\n");
  tmpList := arrayGet(iSccMapping,i2);
  tmpList := i1 :: tmpList;
  oSccMapping := arrayUpdate(iSccMapping,i2,tmpList);

end convertToSccSimEqMapping1;

protected function convertToSimeqCompMapping "function convertToSimeqCompMapping
  author: marcusw
  Converts the given mapping (simEqIndex -> sccIndex) bases on tuples to an array mapping."
  input list<tuple<Integer,Integer>> iMapping; //<simEqIdx,sccIdx>
  input Integer numOfSimEqs;
  output array<Integer> oMapping; //maps each simEq to the scc

protected
  array<Integer> tmpMapping;

algorithm
  tmpMapping := arrayCreate(numOfSimEqs, -1);
  oMapping := List.fold(iMapping, convertToSimeqCompMapping1, tmpMapping);
end convertToSimeqCompMapping;

protected function convertToSimeqCompMapping1 "function convertToSimeqCompMapping1
  author: marcusw
  Helper function for convertToSimeqCompMapping. It will update the array at the given index."
  input tuple<Integer,Integer> iSimEqTuple; //<simEqIdx,sccIdx>
  input array<Integer> iMapping;
  output array<Integer> oMapping;

protected
  Integer simEqIdx,sccIdx;

algorithm
  (simEqIdx,sccIdx) := iSimEqTuple;
  //print("convertToSimeqCompMapping1 " + intString(simEqIdx) + " .. " + intString(sccIdx) + " iMapping_len: " + intString(arrayLength(iMapping)) + "\n");
  oMapping := arrayUpdate(iMapping,simEqIdx,sccIdx);
end convertToSimeqCompMapping1;

protected function getSimEqIdxSimEqMapping "author: marcusw
  Get a mapping from simEqIdx -> option(simEq)."
  input list<SimCode.SimEqSystem> iAllEquations;
  input Integer iSimEqSystemHighestIdx;
  output array<Option<SimCode.SimEqSystem>> oMapping;
protected
  array<Option<SimCode.SimEqSystem>> tmpMapping;
algorithm
  tmpMapping := arrayCreate(iSimEqSystemHighestIdx, NONE());
  oMapping := List.fold(iAllEquations, getSimEqIdxSimEqMapping1, tmpMapping);
end getSimEqIdxSimEqMapping;

protected function getSimEqIdxSimEqMapping1 "author: marcusw
  Helper function that adds the index of the given equation to the mapping."
  input SimCode.SimEqSystem iEquation;
  input array<Option<SimCode.SimEqSystem>> iMapping;
  output array<Option<SimCode.SimEqSystem>> oMapping;
protected
  Integer simEqIdx;
  array<Option<SimCode.SimEqSystem>> tmpMapping;
algorithm
  oMapping := matchcontinue(iEquation, iMapping)
    case(_,_)
      equation
        (simEqIdx,_) = getIndexBySimCodeEq(iEquation);
        tmpMapping = arrayUpdate(iMapping, simEqIdx, SOME(iEquation));
      then tmpMapping;
    else
      equation
        (simEqIdx,_) = getIndexBySimCodeEq(iEquation);
        //print("getSimEqIdxSimEqMapping1: Can't access idx " + intString(simEqIdx) + "\n");
      then iMapping;
  end matchcontinue;
end getSimEqIdxSimEqMapping1;

public function dumpSimEqSCCMapping "author: marcusw
  Prints the given mapping out to the console."
  input array<Integer> iSccMapping;
protected
  String text;
algorithm
  text := "SimEqToSCCMapping";
  ((_,text)) := Array.fold(iSccMapping, dumpSimEqSCCMapping1, (1,text));
  print(text + "\n");
end dumpSimEqSCCMapping;

protected function dumpSimEqSCCMapping1 "author: marcusw
  Helper function of dumpSimEqSCCMapping to print one mapping entry."
  input Integer iMapping;
  input tuple<Integer,String> iIndexText;
  output tuple<Integer,String> oIndexText;
protected
  Integer iIndex;
  String text, iText;
algorithm
  (iIndex,iText) := iIndexText;
  text := intString(iMapping);
  text := iText + "\nSimEq " + intString(iIndex) + ": {" + text + "}";
  oIndexText := (iIndex+1,text);
end dumpSimEqSCCMapping1;

public function dumpSccSimEqMapping "function dumpSccSimEqMapping
  author: marcusw
  Prints the given mapping out to the console."
  input array<list<Integer>> iSccMapping;
protected
  String text;
algorithm
  text := "SccToSimEqMapping";
  ((_,text)) := Array.fold(iSccMapping, dumpSccSimEqMapping1, (1,text));
  print(text + "\n");
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
  text := iText + "\nSCC " + intString(iIndex) + ": {" + text + "}";
  oIndexText := (iIndex+1,text);
end dumpSccSimEqMapping1;

protected function dumpSccSimEqMapping2 "function dumpSccSimEqMapping2
  author: marcusw
  Helper function of dumpSccSimEqMapping1 to print one mapping element."
  input Integer iIndex;
  input String iText;
  output String oText;

algorithm
  oText := iText + intString(iIndex) + " ";

end dumpSccSimEqMapping2;

protected function getSimCodeEqsByTaskList "author: marcusw
  Get the simCode.SimEqSystem - objects references by the given tasks."
  input list<HpcOmSimCode.Task> iTaskList;
  input array<Option<SimCode.SimEqSystem>> iSimEqIdxSimEqMapping;
  output list<SimCode.SimEqSystem> oSimEqs;
protected
  list<list<SimCode.SimEqSystem>> tmpSimEqs;
algorithm
  tmpSimEqs := List.map1(iTaskList, getSimCodeEqsByTaskList0, iSimEqIdxSimEqMapping);
  oSimEqs := List.flatten(tmpSimEqs);
end getSimCodeEqsByTaskList;

protected function getSimCodeEqsByTaskList0 "author: marcusw
  Get the simCode.SimEqSystem - objects references by the given task."
  input HpcOmSimCode.Task iTask;
  input array<Option<SimCode.SimEqSystem>> iSimEqIdxSimEqMapping;
  output list<SimCode.SimEqSystem> oSimEqs;
protected
  list<Integer> eqIdc;
  list<SimCode.SimEqSystem> tmpSimEqs;
algorithm
  oSimEqs := match(iTask, iSimEqIdxSimEqMapping)
    case(HpcOmSimCode.CALCTASK(eqIdc=eqIdc),_)
      equation
        tmpSimEqs = List.map1r(eqIdc, getSimCodeEqByIndexAndMapping, iSimEqIdxSimEqMapping);
      then tmpSimEqs;
    case(HpcOmSimCode.CALCTASK_LEVEL(eqIdc=eqIdc),_)
      equation
        tmpSimEqs = List.map1r(eqIdc, getSimCodeEqByIndexAndMapping, iSimEqIdxSimEqMapping);
      then tmpSimEqs;
    else {};
  end match;
end getSimCodeEqsByTaskList0;

public function getSimCodeEqByIndexAndMapping "author: marcusw
  Returns the SimEqSystem which has the given Index."
  input array<Option<SimCode.SimEqSystem>> iSimEqIdxSimEqMapping; //All SimEqSystems
  input Integer iIdx; //The index of the required system
  output SimCode.SimEqSystem oSimEqSystem;
protected
  Option<SimCode.SimEqSystem> tmpSimEqSystem;
algorithm
  tmpSimEqSystem := arrayGet(iSimEqIdxSimEqMapping, iIdx);
  oSimEqSystem := getSimCodeEqByIndexAndMapping1(tmpSimEqSystem, iIdx);
end getSimCodeEqByIndexAndMapping;

protected function getSimCodeEqByIndexAndMapping1 "author: marcusw
  Returns the SimEqSystem if it's not NONE()."
  input Option<SimCode.SimEqSystem> iSimEqSystem;
  input Integer iIdx;
  output SimCode.SimEqSystem oSimEqSystem;
protected
  SimCode.SimEqSystem tmpSys;
algorithm
  oSimEqSystem := match(iSimEqSystem,iIdx)
    case(SOME(tmpSys),_)
      then tmpSys;
    else
      equation
        print("getSimCodeEqByIndexAndMapping1 failed. Looking for Index " + intString(iIdx) + "\n");
        //print(" -- available indices: " + stringDelimitList(List.map(List.map(iEqs,getIndexBySimCodeEq), intString), ",") + "\n");
      then fail();
  end match;
end getSimCodeEqByIndexAndMapping1;

public function getSimCodeEqByIndex "function getSimCodeEqByIndex
  author: marcusw
  Returns the SimEqSystem which has the given Index. This method is called from susan."
  input list<SimCode.SimEqSystem> iEqs; //All SimEqSystems
  input Integer iIdx; //The index of the required system
  output SimCode.SimEqSystem oEq;

protected
  list<SimCode.SimEqSystem> rest;
  SimCode.SimEqSystem head;
  Integer headIdx,headIdx2;

algorithm
  oEq := matchcontinue(iEqs,iIdx)
    case(head::rest,_)
      equation
        (headIdx,headIdx2) = getIndexBySimCodeEq(head);
        //print("getSimCodeEqByIndex listLength: " + intString(listLength(iEqs)) + " head idx: " + intString(headIdx) + "\n");
        true = intEq(headIdx,iIdx) or intEq(headIdx2,iIdx);
      then head;
    case(head::rest,_) then getSimCodeEqByIndex(rest,iIdx);
    else
      equation
        print("getSimCodeEqByIndex failed. Looking for Index " + intString(iIdx) + "\n");
        //print(" -- available indices: " + stringDelimitList(List.map(List.map(iEqs,getIndexBySimCodeEq), intString), ",") + "\n");
      then fail();
  end matchcontinue;
end getSimCodeEqByIndex;

protected function getIndexBySimCodeEq "function getIndexBySimCodeEq
  author: marcusw
  Just a small helper function to get the index of a SimEqSystem."
  input SimCode.SimEqSystem iEq;
  output Integer oIdx;
  output Integer oIdx2;

protected
  Integer index,index2;

algorithm
  (oIdx,oIdx2) := match(iEq)
    case(SimCode.SES_RESIDUAL(index=index)) then (index,0);
    case(SimCode.SES_SIMPLE_ASSIGN(index=index)) then (index,0);
    case(SimCode.SES_ARRAY_CALL_ASSIGN(index=index)) then (index,0);
    case(SimCode.SES_IFEQUATION(index=index)) then (index,0);
    case(SimCode.SES_ALGORITHM(index=index)) then (index,0);
    // no dynamic tearing
    case(SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(index=index), NONE())) then (index,0);
    case(SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(index=index), NONE())) then (index,0);
    // dynamic tearing
    case(SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(index=index), SOME(SimCode.LINEARSYSTEM(index=index2)))) then (index,index2);
    case(SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(index=index), SOME(SimCode.NONLINEARSYSTEM(index=index2)))) then (index,index2);
    case(SimCode.SES_MIXED(index=index)) then (index,0);
    case(SimCode.SES_WHEN(index=index)) then (index,0);
    else fail();
  end match;
end getIndexBySimCodeEq;

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
    else iHighestIndex;
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

// test functions
//------------------------------------------
//------------------------------------------

protected function checkOdeSystemSize "Compares the number of components in the graph with the number of ode-equations in the simCode-structure.
Remark: this can occur when asserts are added to the ode-system.
author:marcusw"
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input list<list<SimCode.SimEqSystem>> iOdeEqs;
  input array<list<Integer>> iSccSimEqMapping;
  output Boolean oIsCorrect;
protected
  Integer scc;
  list<Integer> sccs;
  Integer actualSizePre, actualSize;
  Integer targetSize;
algorithm
  sccs := List.sort(HpcOmTaskGraph.getAllSCCsOfGraph(iTaskGraphMeta), intGt);
  actualSizePre := listLength(sccs);
  actualSize := listLength(List.sortedUnique(sccs, intEq));
  if(intNe(actualSizePre, actualSize)) then
    print("There are simCode-equations multiple times in the graph structure.\n");
  end if;
  actualSize := 0;
  for scc in sccs loop
    actualSize := actualSize + listLength(arrayGet(iSccSimEqMapping, scc));
  end for;

  targetSize := listLength(List.flatten(iOdeEqs));
  oIsCorrect := intEq(targetSize,actualSize);
  if(oIsCorrect) then
    //print("the ODE-system size is correct("+intString(actualSize)+")\n");
  else
    print("the size of the ODE-system should be "+intString(targetSize)+" but it is "+intString(actualSize)+"!\n");
    print("expected the following sim code equations: " + stringDelimitList(List.map(List.map(List.flatten(iOdeEqs), SimCodeUtil.simEqSystemIndex), intString), ",") + "\n");
    print("the ODE-system is NOT correct\n");
  end if;
end checkOdeSystemSize;

protected function checkTaskGraphMetaConsistency "Check if the number of nodes in task graph meta is equal to the number of nodes in the task graph.
author:marcusw"
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input String iSystemName;
  output Boolean oIsCorrect;
protected
  Integer numberOfNodes;
  array<list<Integer>> inComps;
algorithm
  numberOfNodes := arrayLength(iTaskGraph);
  HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps) := iTaskGraphMeta;
  if(boolNot(intEq(numberOfNodes, arrayLength(inComps)))) then
    print("the number of nodes in the " + iSystemName + " task graph ("+intString(numberOfNodes)+") is distinguished from the number of nodes in task graph meta (" + intString(arrayLength(inComps)) + ")\n");
    oIsCorrect := false;
  else
    oIsCorrect := true;
  end if;
end checkTaskGraphMetaConsistency;

protected function checkEquationCount "Check if the number of equations in the nodes of the task graph is equal to the given expected number.
author:marcusw"
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input String iSystemName;
  input Integer iExpectedNumberOfEqs;
  input array<list<Integer>> iSccSimEqMapping;
  output Boolean oIsCorrect;
protected
  Integer inCompsIdx, eqCount;
  array<list<Integer>> inComps;
  list<Integer> comps;
  list<Integer> compEqs;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps) := iTaskGraphMeta;
  inCompsIdx := arrayLength(inComps);
  eqCount := 0;
  while intGt(inCompsIdx, 0) loop
    comps := arrayGet(inComps, inCompsIdx);
    for comp in comps loop
      compEqs := arrayGet(iSccSimEqMapping, comp);
      eqCount := eqCount + listLength(compEqs);
    end for;
    inCompsIdx := inCompsIdx - 1;
  end while;

  oIsCorrect := intEq(iExpectedNumberOfEqs, eqCount);
  if(boolNot(oIsCorrect)) then
    print("the number of equations in the " + iSystemName + " task graph ("+intString(eqCount)+") is distinguished from the expected number of equations (" + intString(iExpectedNumberOfEqs) + ")\n");
  end if;
end checkEquationCount;

/*
protected function repeatScheduleWithOtherNumProc"checks if the scheduling with the given numProc is fine.
 if n=auto, more cores are available and more speedup could be achieved repeat schedule with increased num of procs.
 author:Waurich TUD 2013-011"
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  input array<list<Integer>> sccSimEqMappingIn;
  input String fileNamePrefix;
  input Real cpCostsWoC;
  input HpcOmSimCode.Schedule scheduleIn;
  input Integer numProcIn;
  input Boolean numFixed;
  output HpcOmSimCode.Schedule scheduleOut;
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
  input BackendDAE.BackendDAE inDAE;
  input array<list<Integer>> sccSimEqMappingIn;
  input String fileNamePrefix;
  input Real cpCostsWoC;
  input HpcOmSimCode.Schedule scheduleIn;
  input Integer numProcIn;
  input Boolean numFixed;
  input Integer maxNumProc;
  input Real maxDiff;
  input Integer numIterIn;
  output HpcOmSimCode.Schedule scheduleOut;
  output Integer numProcOut;
  output Integer numIterOut;
algorithm
  (scheduleOut,numProcOut,numIterOut) := matchcontinue(taskGraphIn,taskGraphMetaIn,inDAE,sccSimEqMappingIn,fileNamePrefix,cpCostsWoC,scheduleIn,numProcIn,numFixed,maxNumProc,maxDiff,numIterIn)
    local
      Boolean scheduleAgain;
      Integer numProc, numIt;
      Real serTime,parTime,speedup,speedUp,speedUpMax,diff;
      HpcOmSimCode.Schedule schedule;
    case(_,_,_,_,_,_,_,_,true,_,_,_)
      equation // do not schedule again because the number of procs was given
        then
          (scheduleIn,numProcIn,0);
    case(_,_,_,_,_,_,_,_,false,_,_,_)
      equation
        true = numIterIn == 0; // the max number of schedules with increased num of procs
        then
          (scheduleIn,numProcIn,0);
    case(_,_,_,_,_,_,_,_,false,_,_,_)
      equation
        (_,_,speedUp,speedUpMax) = HpcOmScheduler.predictExecutionTime(scheduleIn,SOME(cpCostsWoC),numProcIn,taskGraphIn,taskGraphMetaIn);
        diff = speedUpMax -. speedUp;
        //print("the new speedUp with "+intString(numProcIn)+" processors: "+realString(speedUp)+"\n");
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
        numProc = if_(scheduleAgain,numProc,numProcIn);
        numIt = if_(scheduleAgain,numIt,0);
        schedule= Debug.bcallret6(scheduleAgain,createSchedule,taskGraphIn,taskGraphMetaIn,sccSimEqMappingIn,fileNamePrefix,numProc,scheduleIn);
        (schedule,numProc,numIt) = repeatScheduleWithOtherNumProc1(taskGraphIn,taskGraphMetaIn,sccSimEqMappingIn,fileNamePrefix,cpCostsWoC,schedule,numProc,numFixed,maxNumProc,maxDiff,numIt);
      then
        (schedule,numProc,numIt);
  end matchcontinue;
end repeatScheduleWithOtherNumProc1;
*/

//----------------------------
// output data about operations in equations and composition of systems of equations
//----------------------------

public function outputTimeBenchmark"outputs infos about all equations and equationsystems of the strongComponents.
author:Waurich TUD "
  input HpcOmTaskGraph.TaskGraphMeta graphData;
  input BackendDAE.BackendDAE dae;
protected
  list<BackendDAE.EqSystem> eqSystems;
  array<tuple<Integer,Real>> exeCosts;
  list<Real> numCycles;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(eqs=eqSystems, shared=shared) := dae;
  HpcOmTaskGraph.TASKGRAPHMETA(exeCosts=exeCosts) := graphData;
  numCycles := List.map(arrayList(exeCosts),Util.tuple22);
    print("start cost benchmark\n");
  outputTimeBenchmark2(BackendDAEUtil.getStrongComponents(listHead(eqSystems)),numCycles,eqSystems,shared,1);
    print("finish cost benchmark\n");
end outputTimeBenchmark;

protected function outputTimeBenchmark2"traverses all comps and compares measured and estimated execosts.
author:Waurich TUD 2014-12"
  input list<BackendDAE.StrongComponent> compsIn;
  input list<Real> numCycles;
  input list<BackendDAE.EqSystem> eqSystemsIn;
  input BackendDAE.Shared shared;
  input Integer compIdx;
algorithm
  _ := matchcontinue(compsIn,numCycles,eqSystemsIn,shared,compIdx)
    local
      Real exeCost, estimate;
      list<Real> restCosts;
      BackendDAE.CompInfo compInfo;
      BackendDAE.EqSystem eqSys;
      BackendDAE.StrongComponent comp;
      list<BackendDAE.EqSystem> eqSysRest;
      list<BackendDAE.StrongComponent> comps;
   case({},_,{_},_,_)
     equation
     then();
   case({},_,_::eqSysRest,_,_)
     equation
        comps = BackendDAEUtil.getStrongComponents(listHead(eqSysRest));
       outputTimeBenchmark2(comps,numCycles,eqSysRest,shared,compIdx);
     then ();
   case(comp::comps,exeCost::restCosts,eqSys::_,_,_)
     equation
       {compInfo} = BackendDAEOptimize.countOperationstraverseComps({comp}, eqSys, shared,{});
       (_,estimate) = HpcOmTaskGraph.calculateCosts(compInfo);
         BackendDump.dumpCompInfo(compInfo);
         print("task"+intString(compIdx)+"-> measured: "+intString(realInt(exeCost))+" and estimated: "+intString(realInt(estimate))+"\n\n");
       outputTimeBenchmark2(comps,restCosts,eqSystemsIn,shared,compIdx+1);
     then ();
     else ();
  end matchcontinue;
end outputTimeBenchmark2;

annotation(__OpenModelica_Interface="backend");
end HpcOmSimCodeMain;
