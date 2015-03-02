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
encapsulated package HpcOmMemory

  public import BackendDAE;
  public import DAE;
  public import HashTableCrILst;
  public import HpcOmSimCode;
  public import HpcOmTaskGraph;
  public import SimCode;
  public import SimCodeVar;

  protected import Array;
  protected import BackendDAEUtil;
  protected import BackendDump;
  protected import BackendEquation;
  protected import BackendVariable;
  protected import BaseHashTable;
  protected import ComponentReference;
  protected import Config;
  protected import Debug;
  protected import Expression;
  protected import Flags;
  protected import GraphML;
  protected import HpcOmScheduler;
  protected import List;
  protected import SimCodeUtil;
  protected import Util;

  // -------------------------------------------
  // STRUCTURES
  // -------------------------------------------

  public constant Integer VARTYPE_FLOAT        = 1;
  public constant Integer VARTYPE_INTEGER      = 2;
  public constant Integer VARTYPE_BOOLEAN      = 3;

  protected uniontype CacheMap
    //CacheMap that stores variables of same type in the same array (different arrays for bool, float and int vars)
    record CACHEMAP
      Integer cacheLineSize; //cache line size in bytes
      list<SimCodeVar.SimVar> cacheVariables; //all variables that are stored in the cache
      list<CacheLineMap> cacheLinesFloat;
      list<CacheLineMap> cacheLinesInt;
      list<CacheLineMap> cacheLinesBool;
    end CACHEMAP;
    //CacheMap that stores variables of different types in the same array -- just used for default cache map
    record UNIFORM_CACHEMAP
      Integer cacheLineSize; //cache line size in bytes
      list<SimCodeVar.SimVar> cacheVariables; //all variables that are stored in the cache
      list<CacheLineMap> cacheLines;
    end UNIFORM_CACHEMAP;
  end CacheMap;

  protected uniontype CacheLineMap
    record CACHELINEMAP
      Integer idx;
      Integer numBytesFree;
      list<CacheLineEntry> entries;
    end CACHELINEMAP;
  end CacheLineMap;

  protected uniontype CacheLineEntry
    record CACHELINEENTRY
      Integer start; //starting with 0
      Integer dataType; //1 = float, 2 = int, 3 = bool
      Integer size;
      Integer scVarIdx; //see CacheMap.cacheVariables
      Integer threadOwner;
    end CACHELINEENTRY;
  end CacheLineEntry;

  protected uniontype CacheMapMeta
    record CACHEMAPMETA
      array<Option<SimCodeVar.SimVar>> allSCVarsMapping;
      array<tuple<Integer, Integer>> simCodeVarTypes; //<type, numberOfBytesRequired>
      array<tuple<Integer, Integer>> scVarCLMapping; //mapping for each scVar -> <CLIdx,varType>
    end CACHEMAPMETA;
  end CacheMapMeta;

 protected uniontype PartlyFilledCacheLine
    record PARTLYFILLEDCACHELINE
      CacheLineMap cacheLineMap;
      list<Integer> prefetchLevel;
      list<tuple<Integer,Integer>> writeLevel; //(LevelIdx, ThreadIdx)
    end PARTLYFILLEDCACHELINE;
 end PartlyFilledCacheLine;

  // -------------------------------------------
  // FUNCTIONS
  // -------------------------------------------

  public function createMemoryMap
    "author: marcusw
     Creates a MemoryMap which contains informations about an optimized memory alignment and append the informations to the given TaskGraph."
    input SimCode.ModelInfo iModelInfo;
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraph iTaskGraphT;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input BackendDAE.EqSystems iEqSystems;
    input String iFileNamePrefix;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input HpcOmSimCode.Schedule iSchedule;
    input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
    input list<list<Integer>> iCriticalPaths;
    input list<list<Integer>> iCriticalPathsWoC;
    input String iCriticalPathInfo;
    input Integer iNumberOfThreads;
    input BackendDAE.StrongComponents iAllComponents;
    output Option<HpcOmSimCode.MemoryMap> oMemoryMap;
  protected
    SimCodeVar.SimVars simCodeVars;
    list<SimCodeVar.SimVar> stateVars, derivativeVars, algVars, discreteAlgVars, intAlgVars, boolAlgVars, inputVars, outputVars, aliasVars, paramVars, intAliasVars, boolAliasVars;
    list<SimCodeVar.SimVar> notOptimizedVars;
    array<Option<SimCodeVar.SimVar>> allVarsMapping;
    HashTableCrILst.HashTable hashTable;
    Integer numScVars, numCL, threadAttIdx;
    array<list<Integer>> clTaskMapping;
    array<Integer> scVarTaskMapping, sccNodeMapping;
    array<String> annotInfo;
    array<tuple<Integer,Integer>> scVarCLMapping, memoryPositionMapping;
    CacheMap cacheMap;
    Integer graphIdx;
    GraphML.GraphInfo graphInfo;
    String fileName;
    array<array<list<Integer>>> eqSimCodeVarMapping; //eqSystem -> eqIdx -> varIdx
    array<tuple<Integer,Integer,Integer>> eqCompMapping, varCompMapping;
    BackendDAE.IncidenceMatrix incidenceMatrix;
    array<list<Integer>> nodeSimCodeVarMapping;
    HpcOmSimCode.MemoryMap tmpMemoryMap;
    Integer varCount;
    Integer VARSIZE_FLOAT, VARSIZE_INT, VARSIZE_BOOL, CACHELINE_SIZE;
    array<tuple<Integer,Integer>> simCodeVarTypes; //<varType, varSize>
  algorithm
    oMemoryMap := matchcontinue(iModelInfo, iTaskGraph, iTaskGraphMeta, iEqSystems, iFileNamePrefix, iSchedulerInfo, iSchedule, iSccSimEqMapping, iCriticalPaths, iCriticalPathsWoC, iCriticalPathInfo, iNumberOfThreads, iAllComponents)
      case(_,_,_,_,_,_,_,_,_,_,_,_,_)
        equation
          VARSIZE_FLOAT = 8;
          VARSIZE_INT = 4;
          VARSIZE_BOOL = 1;
          CACHELINE_SIZE = 64;
          //HpcOmTaskGraph.printTaskGraphMeta(iTaskGraphMeta);
          //Create var hash table
          SimCode.MODELINFO(vars=simCodeVars) = iModelInfo;
          SimCodeVar.SIMVARS(stateVars=stateVars, derivativeVars=derivativeVars, algVars=algVars, discreteAlgVars=discreteAlgVars, intAlgVars=intAlgVars, boolAlgVars=boolAlgVars, inputVars=inputVars,
                             outputVars=outputVars, aliasVars=aliasVars, intAliasVars=intAliasVars, boolAliasVars=boolAliasVars, paramVars=paramVars) = simCodeVars;
          allVarsMapping = SimCodeUtil.createIdxSCVarMapping(simCodeVars);
          //SimCodeUtil.dumpIdxScVarMapping(allVarsMapping);

          //print("--------------------------------\n");
          hashTable = HashTableCrILst.emptyHashTableSized(BaseHashTable.biggerBucketSize);
          varCount = 0;
          hashTable = fillSimVarHashTable(stateVars,varCount,VARTYPE_FLOAT,hashTable);
          varCount = varCount + listLength(stateVars);
          hashTable = fillSimVarHashTable(derivativeVars,varCount,VARTYPE_FLOAT,hashTable);
          varCount = varCount + listLength(derivativeVars);
          hashTable = fillSimVarHashTable(algVars,varCount,VARTYPE_FLOAT,hashTable);
          varCount = varCount + listLength(algVars);
          hashTable = fillSimVarHashTable(discreteAlgVars,varCount,VARTYPE_FLOAT,hashTable);
          varCount = varCount + listLength(discreteAlgVars);
          hashTable = fillSimVarHashTable(intAlgVars,varCount,VARTYPE_INTEGER,hashTable);
          varCount = varCount + listLength(intAlgVars);
          hashTable = fillSimVarHashTable(boolAlgVars,varCount,VARTYPE_BOOLEAN,hashTable);
          varCount = varCount + listLength(boolAlgVars);
          hashTable = fillSimVarHashTable(inputVars,varCount,VARTYPE_BOOLEAN,hashTable);
          varCount = varCount + listLength(inputVars);
          hashTable = fillSimVarHashTable(outputVars,varCount,VARTYPE_BOOLEAN,hashTable);
          varCount = varCount + listLength(outputVars);
          hashTable = fillSimVarHashTable(aliasVars,varCount,VARTYPE_BOOLEAN,hashTable);
          varCount = varCount + listLength(aliasVars);
          hashTable = fillSimVarHashTable(intAliasVars,varCount,VARTYPE_BOOLEAN,hashTable);
          varCount = varCount + listLength(intAliasVars);
          hashTable = fillSimVarHashTable(boolAliasVars,varCount,VARTYPE_BOOLEAN,hashTable);
          varCount = varCount + listLength(boolAliasVars);
          hashTable = fillSimVarHashTable(paramVars,varCount,VARTYPE_BOOLEAN,hashTable);
          varCount = varCount + listLength(paramVars);

          simCodeVarTypes = arrayCreate(varCount, (-1,-1));
          varCount = 0;

          if(intGt(listLength(stateVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(stateVars)), function Array.updateIndexFirst(inValue = (VARTYPE_FLOAT,VARSIZE_FLOAT), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(stateVars);
          if(intGt(listLength(derivativeVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(derivativeVars)), function Array.updateIndexFirst(inValue = (VARTYPE_FLOAT,VARSIZE_FLOAT), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(derivativeVars);
          if(intGt(listLength(algVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(algVars)), function Array.updateIndexFirst(inValue = (VARTYPE_FLOAT,VARSIZE_FLOAT), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(algVars);
          if(intGt(listLength(discreteAlgVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(discreteAlgVars)), function Array.updateIndexFirst(inValue = (VARTYPE_FLOAT,VARSIZE_FLOAT), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(discreteAlgVars);
          if(intGt(listLength(intAlgVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(intAlgVars)), function Array.updateIndexFirst(inValue = (VARTYPE_INTEGER,VARSIZE_INT), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(intAlgVars);
          if(intGt(listLength(boolAlgVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(boolAlgVars)), function Array.updateIndexFirst(inValue = (VARTYPE_BOOLEAN,VARSIZE_BOOL), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(boolAlgVars);
          if(intGt(listLength(inputVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(inputVars)), function Array.updateIndexFirst(inValue = (VARTYPE_FLOAT,VARSIZE_FLOAT), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(inputVars);
          if(intGt(listLength(outputVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(outputVars)), function Array.updateIndexFirst(inValue = (VARTYPE_FLOAT,VARSIZE_FLOAT), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(outputVars);
          if(intGt(listLength(aliasVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(aliasVars)), function Array.updateIndexFirst(inValue = (VARTYPE_FLOAT,VARSIZE_FLOAT), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(aliasVars);
          if(intGt(listLength(intAliasVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(intAliasVars)), function Array.updateIndexFirst(inValue = (VARTYPE_INTEGER,VARSIZE_INT), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(intAliasVars);
          if(intGt(listLength(boolAliasVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(boolAliasVars)), function Array.updateIndexFirst(inValue = (VARTYPE_BOOLEAN,VARSIZE_BOOL), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(boolAliasVars);
          if(intGt(listLength(paramVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(paramVars)), function Array.updateIndexFirst(inValue = (VARTYPE_FLOAT,VARSIZE_FLOAT), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(paramVars);

          //print("-------------------------------------\n");
          //BaseHashTable.dumpHashTable(hashTable);
          //Create CacheMap
          sccNodeMapping = HpcOmTaskGraph.getSccNodeMapping(arrayLength(iSccSimEqMapping), iTaskGraphMeta);
          //printSccNodeMapping(sccNodeMapping);
          scVarTaskMapping = getSimCodeVarNodeMapping(iTaskGraphMeta,iEqSystems,listLength(stateVars)*2+listLength(algVars),sccNodeMapping,hashTable);
          //printScVarTaskMapping(scVarTaskMapping);
          //print("-------------------------------------\n");
          nodeSimCodeVarMapping = transposeScVarTaskMapping(scVarTaskMapping, iTaskGraph);

          //printNodeSimCodeVarMapping(nodeSimCodeVarMapping);
          //print("-------------------------------------\n");

          eqSimCodeVarMapping = getEqSCVarMapping(iEqSystems,hashTable);
          //printEqSimCodeVarMapping(eqSimCodeVarMapping);
          if(Flags.isSet(Flags.HPCOM_MEMORY_OPT)) then
            (cacheMap,scVarCLMapping,numCL) = createCacheMapOptimized(iTaskGraph, iTaskGraphMeta, simCodeVars, allVarsMapping,simCodeVarTypes,scVarTaskMapping,CACHELINE_SIZE,iAllComponents,iSchedule,iSchedulerInfo,iNumberOfThreads,nodeSimCodeVarMapping);
          else
            (cacheMap,scVarCLMapping,numCL) = createCacheMapDefault(allVarsMapping, CACHELINE_SIZE, simCodeVars, scVarTaskMapping, iSchedulerInfo, simCodeVarTypes);
          end if;

          (clTaskMapping,scVarTaskMapping) = getCacheLineTaskMapping(iTaskGraphMeta,iEqSystems,hashTable,numCL,scVarCLMapping);

          //Get not optimized variables
          //---------------------------
          notOptimizedVars = getNotOptimizedVarsByCacheLineMapping(scVarCLMapping, allVarsMapping);

          //Append cache line nodes to graph
          //--------------------------------
          graphInfo = GraphML.createGraphInfo();
          (graphInfo, (_,graphIdx)) = GraphML.addGraph("TasksGroupGraph", true, graphInfo);
          (graphInfo, (_,_),(_,graphIdx)) = GraphML.addGroupNode("TasksGroup", graphIdx, false, "TG", graphInfo);
          annotInfo = arrayCreate(arrayLength(iTaskGraph),"nothing");
          graphInfo = HpcOmTaskGraph.convertToGraphMLSccLevelSubgraph(iTaskGraph, iTaskGraphMeta, iCriticalPathInfo, HpcOmTaskGraph.convertNodeListToEdgeTuples(List.first(iCriticalPaths)), HpcOmTaskGraph.convertNodeListToEdgeTuples(List.first(iCriticalPathsWoC)), iSccSimEqMapping, iSchedulerInfo, annotInfo, graphIdx, HpcOmTaskGraph.GRAPHDUMPOPTIONS(false,false,true,true), graphInfo);
          HpcOmTaskGraph.TASKGRAPHMETA(eqCompMapping=eqCompMapping,varCompMapping=varCompMapping) = iTaskGraphMeta;
          SOME((_,threadAttIdx)) = GraphML.getAttributeByNameAndTarget("ThreadId", GraphML.TARGET_NODE(), graphInfo);
          (_,incidenceMatrix,_) = BackendDAEUtil.getIncidenceMatrix(List.first(iEqSystems), BackendDAE.ABSOLUTE(), NONE());
          graphInfo = appendCacheLinesToGraph(cacheMap, arrayLength(iTaskGraph), nodeSimCodeVarMapping, eqSimCodeVarMapping, iEqSystems, hashTable, eqCompMapping, scVarTaskMapping, iSchedulerInfo, threadAttIdx, sccNodeMapping, graphInfo);
          fileName = ("taskGraph"+iFileNamePrefix+"ODE_schedule_CL.graphml");
          GraphML.dumpGraph(graphInfo, fileName);
          if(Flags.isSet(Flags.HPCOM_MEMORY_OPT)) then
            tmpMemoryMap = convertCacheMapToMemoryMap(cacheMap,(VARSIZE_FLOAT,VARSIZE_INT,VARSIZE_BOOL),hashTable,notOptimizedVars);
          else
            tmpMemoryMap = HpcOmSimCode.MEMORYMAP_UNIFORM();
          end if;
          //print cache map
          if Flags.isSet(Flags.HPCOM_DUMP) then
            //printCacheMap(cacheMap);
            //print("\n");
            //evaluateCacheBehaviour(cacheMap, iTaskGraphT, nodeSimCodeVarMapping, scVarCLMapping, iNumberOfThreads, numCL, iSchedulerInfo);
          end if;
        then SOME(tmpMemoryMap);
      else
        equation
          print("CreateMemoryMap failed!\n");
        then NONE();
    end matchcontinue;
  end createMemoryMap;

  protected function createCacheMapOptimized "author: marcusw
     Creates a CacheMap optimized for the selected scheduler. All variables that are part of the created cache map are marked with 1 in the iVarMark-array."
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input SimCodeVar.SimVars iSimCodeVars;
    input array<Option<SimCodeVar.SimVar>> iAllSCVarsMapping;
    input array<tuple<Integer,Integer>> iSimCodeVarTypes; //<varType, varSize>
    input array<Integer> iScVarTaskMapping;
    input Integer iCacheLineSize;
    input BackendDAE.StrongComponents iAllComponents;
    input HpcOmSimCode.Schedule iSchedule;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input Integer iNumberOfThreads;
    input array<list<Integer>> iNodeSimCodeVarMapping;
    output CacheMap oCacheMap;
    output array<tuple<Integer,Integer>> oScVarCLMapping; //mapping for each scVar -> CLIdx
    output Integer oNumCL;
  protected
    CacheMap cacheMap;
    array<tuple<Integer,Integer>> scVarCLMapping;
    Integer numCL;
    list<HpcOmSimCode.TaskList> tasksOfLevels;
    array<tuple<Integer,Integer,Real>> scheduleInfo;
    array<list<HpcOmSimCode.Task>> threadTasks;
    array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
  algorithm
    (oCacheMap,oScVarCLMapping,oNumCL) := match(iTaskGraph,iTaskGraphMeta,iAllSCVarsMapping,iSimCodeVarTypes,iScVarTaskMapping,iCacheLineSize,iAllComponents,iSchedule, iNumberOfThreads, iNodeSimCodeVarMapping)
      /* case(_,_,_,_,_,_,_,HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevels, useFixedAssignments=false),_,_)
        equation
          (cacheMap,scVarCLMapping,numCL) = createCacheMapLevelOptimized(iAllSCVarsMapping,iSimCodeVarTypes,iScVarTaskMapping,iCacheLineSize,iAllComponents,tasksOfLevels,iNodeSimCodeVarMapping);
        then (cacheMap,scVarCLMapping,numCL); */
      case(_,_,_,_,_,_,_,HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevels, useFixedAssignments=true),_,_)
        equation
          print("Creating optimized cache map for fixed level scheduler\n");
          scheduleInfo = HpcOmScheduler.convertScheduleStrucToInfo(iSchedule, arrayLength(iTaskGraph));
          (cacheMap,scVarCLMapping,numCL) = createCacheMapLevelFixedOptimized(iTaskGraph,iTaskGraphMeta,iAllSCVarsMapping,iSimCodeVarTypes,iScVarTaskMapping,iCacheLineSize,iAllComponents,tasksOfLevels,iNumberOfThreads,scheduleInfo,iNodeSimCodeVarMapping);
        then (cacheMap,scVarCLMapping,numCL);
      case(_,_,_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks, allCalcTasks=allCalcTasks),_,_)
        equation
          print("Creating optimized cache map for thread scheduler\n");
          scheduleInfo = HpcOmScheduler.convertScheduleStrucToInfo(iSchedule, arrayLength(iTaskGraph));
          (cacheMap,scVarCLMapping,numCL) = createCacheMapThreadOptimized(iTaskGraph,iTaskGraphMeta,iAllSCVarsMapping,iSimCodeVarTypes,iScVarTaskMapping,iCacheLineSize,iAllComponents,threadTasks,allCalcTasks,iNumberOfThreads,scheduleInfo,iNodeSimCodeVarMapping);
        then (cacheMap,scVarCLMapping,numCL);
      else
        equation
          print("No optimized cache map for the selected scheduler avaiable. Using default cacheMap!\n");
          (cacheMap,scVarCLMapping,numCL) = createCacheMapDefault(iAllSCVarsMapping, iCacheLineSize, iSimCodeVars, iScVarTaskMapping, iSchedulerInfo, iSimCodeVarTypes);
        then (cacheMap,scVarCLMapping,numCL);
     end match;
  end createCacheMapOptimized;

  protected function createCacheMapLevelOptimized "author: marcusw
    Create the optimized cache map for the level-scheduler."
    input array<Option<SimCodeVar.SimVar>> iAllSCVarsMapping;
    input array<tuple<Integer,Integer>> iSimCodeVarTypes; //<type, numberOfBytesRequired>
    input array<Integer> iScVarTaskMapping;
    input Integer iCacheLineSize;
    input BackendDAE.StrongComponents iAllComponents;
    input list<HpcOmSimCode.TaskList> iTasksOfLevels; //Schedule
    input array<list<Integer>> iNodeSimCodeVarMapping;
    output CacheMap oCacheMap;
    output array<tuple<Integer,Integer>> oScVarCLMapping; //mapping for each scVar -> <CLIdx,varType>
    output Integer oNumCL;
  protected
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    Integer numCL;
    array<tuple<Integer,Integer>> scVarCLMapping;
    array<list<CacheLineMap>> threadCacheLines; //cache lines of the threads (arrayIdx)
  algorithm
    cacheMap := CACHEMAP(iCacheLineSize,{},{},{},{});
    scVarCLMapping := arrayCreate(arrayLength(iAllSCVarsMapping),(-1,-1));
    numCL := 0;
    cacheMapMeta := CACHEMAPMETA(iAllSCVarsMapping, iSimCodeVarTypes, scVarCLMapping);
    //Iterate over levels
    ((_,cacheMap,cacheMapMeta,numCL)) := List.fold1(iTasksOfLevels, createCacheMapLevelOptimized0, iNodeSimCodeVarMapping, ({},cacheMap,cacheMapMeta,numCL));
    oCacheMap := cacheMap;
    CACHEMAPMETA(scVarCLMapping=oScVarCLMapping) := cacheMapMeta;
    oNumCL := numCL;
  end createCacheMapLevelOptimized;

  protected function createCacheMapLevelOptimized0 "author: marcusw
    Appends the variables which are written by the task list (iLevelTasks) to the info-structure. Only cachelines are used that
    are not written by the previous layer."
    input HpcOmSimCode.TaskList iLevelTasks;
    input array<list<Integer>> iNodeSimCodeVarMapping;
    input tuple<list<Integer>,CacheMap,CacheMapMeta,Integer> iInfo; //<cacheLinesUsedByPreviousLayer,CacheMap,numCL>
    output tuple<list<Integer>,CacheMap,CacheMapMeta,Integer> oInfo;
  protected
    Integer createdCL, numCL, cacheLineSize; //number of CL created for this level
    list<Integer> allCL;
    list<Integer> availableCL, availableCLold, writtenCL; //all cacheLines that can be used for writing
    list<Integer> cacheLinesPrevLevel; //all cache lines written in previous level
    list<tuple<Integer,Integer>> detailedCacheLineInfo;
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    list<CacheLineMap> cacheLinesFloat;
  algorithm
    (cacheLinesPrevLevel, cacheMap, cacheMapMeta, numCL) := iInfo;
    allCL := List.intRange(numCL);
    CACHEMAP(cacheLinesFloat=cacheLinesFloat,cacheLineSize=cacheLineSize) := cacheMap;
    //print("createCacheMapLevelOptimized0: Handling new level. CL used by previous layer: " + stringDelimitList(List.map(cacheLinesPrevLevel,intString), ",") + " Number of CL: " + intString(numCL) + "\n");
    availableCLold := List.setDifferenceIntN(allCL,cacheLinesPrevLevel,numCL);
    //append free space to available cache lines and remove full cache lines
    detailedCacheLineInfo := createDetailedCacheMapInformations(availableCLold, cacheLinesFloat, cacheLineSize);
    detailedCacheLineInfo := listReverse(detailedCacheLineInfo);
    //print("createCacheMapLevelOptimized0: clCandidates: " + stringDelimitList(List.map(List.map(detailedCacheLineInfo,Util.tuple21),intString), ",") + "\n");
    ((cacheMap,cacheMapMeta,createdCL,detailedCacheLineInfo)) := List.fold1(getTaskListTasks(iLevelTasks), createCacheMapLevelOptimizedForTask, iNodeSimCodeVarMapping, (cacheMap,cacheMapMeta, 0,detailedCacheLineInfo));
    availableCL := List.map(detailedCacheLineInfo, Util.tuple21);
    //append the used cachelines to the writtenCL-list
    //print("createCacheMapLevelOptimized0: New cacheLines created: " + intString(createdCL) + "\n");
    writtenCL := List.setDifferenceIntN(availableCLold,availableCL,numCL);
    //print("createCacheMapLevelOptimized0: Written CL_0: " + stringDelimitList(List.map(writtenCL,intString), ",") + " -- numCL: " + intString(numCL) + "\n");
    writtenCL := listAppend(writtenCL, if intLe(numCL+1, numCL+createdCL) then List.intRange2(numCL+1, numCL+createdCL) else {});
    //print("createCacheMapLevelOptimized0: Written CL_1: " + stringDelimitList(List.map(writtenCL,intString), ",") + "\n");
    //print("======================================\n");
    //printCacheMap(cacheMap);
    //print("======================================\n");
    oInfo := (writtenCL,cacheMap,cacheMapMeta,numCL+createdCL);
  end createCacheMapLevelOptimized0;

  protected function createCacheMapLevelOptimizedForTask "author: marcusw
    Append the variables that are solved by the given task to the cachelines."
    input HpcOmSimCode.Task iTask;
    input array<list<Integer>> iNodeSimCodeVarMapping;
    input tuple<CacheMap,CacheMapMeta,Integer,list<tuple<Integer,Integer>>> iInfo; //<CacheMap,CacheMapMeta,numNewCL,clCandidates>
    output tuple<CacheMap,CacheMapMeta,Integer,list<tuple<Integer,Integer>>> oInfo;
  protected
    list<Integer> nodeIdc;
    tuple<CacheMap,CacheMapMeta,Integer,list<tuple<Integer,Integer>>> tmpInfo;
  algorithm
    oInfo := match(iTask ,iNodeSimCodeVarMapping, iInfo)
      case(HpcOmSimCode.CALCTASK_LEVEL(nodeIdc=nodeIdc),_,_)
        equation
          tmpInfo = List.fold(nodeIdc, function appendNodeVarsToCacheMap(iNodeSimCodeVarMapping=iNodeSimCodeVarMapping,iOwnerThread=-1), iInfo);
        then tmpInfo;
      else
        equation
          print("createCacheMapLevelOptimized1: Unsupported task type\n");
        then fail();
    end match;
  end createCacheMapLevelOptimizedForTask;

  protected function createCacheMapLevelFixedOptimized "author: marcusw
    Create the optimized cache map for the levelfixed-scheduler."
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input array<Option<SimCodeVar.SimVar>> iAllSCVarsMapping;
    input array<tuple<Integer,Integer>> iSimCodeVarTypes; //<type, numberOfBytesRequired>
    input array<Integer> iScVarTaskMapping;
    input Integer iCacheLineSize;
    input BackendDAE.StrongComponents iAllComponents;
    input list<HpcOmSimCode.TaskList> iTasksOfLevels; //Schedule
    input Integer iNumberOfThreads;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input array<list<Integer>> iNodeSimCodeVarMapping;
    output CacheMap oCacheMap;
    output array<tuple<Integer,Integer>> oScVarCLMapping; //mapping for each scVar -> <CLIdx,varType>
    output Integer oNumCL;
  protected
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    Integer numCL;
    array<tuple<Integer,Integer>> scVarCLMapping;
    list<CacheLineMap> cacheLinesFloat, cacheLinesInt, cacheLinesBool, threadCacheLinesFloat, threadCacheLinesInt, threadCacheLinesBool;
    list<SimCodeVar.SimVar> cacheVariables;
    array<tuple<list<CacheLineMap>, list<CacheLineMap>, list<CacheLineMap>>> threadCacheLines; //cache lines of the threads (arrayIdx) -- CALC_ONLY and THREAD_ONLY variables
    tuple<list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>> partlyFilledCacheLines; //cache lines that are shared between all threads -- SHARED variables -- but not fully filled
  algorithm
    cacheMap := CACHEMAP(iCacheLineSize,{},{},{},{});
    scVarCLMapping := arrayCreate(arrayLength(iAllSCVarsMapping),(-1,-1));
    numCL := 0;
    threadCacheLines := arrayCreate(iNumberOfThreads, ({},{},{}));
    partlyFilledCacheLines := ({},{},{});
    cacheMapMeta := CACHEMAPMETA(iAllSCVarsMapping, iSimCodeVarTypes, scVarCLMapping);
    //Iterate over levels
    ((partlyFilledCacheLines,
       cacheMap as CACHEMAP(cacheVariables=cacheVariables, cacheLinesFloat=cacheLinesFloat, cacheLinesInt=cacheLinesInt, cacheLinesBool=cacheLinesBool),
       cacheMapMeta,numCL,_)) := List.fold(iTasksOfLevels, function createCacheMapLevelFixedOptimizedForLevel(iTaskGraph=iTaskGraph, iTaskGraphMeta=iTaskGraphMeta,
                                           iNumberOfThreads=iNumberOfThreads, iSchedulerInfo=iSchedulerInfo, iNodeSimCodeVarMapping=iNodeSimCodeVarMapping,
                                           iThreadCacheLines=threadCacheLines), (partlyFilledCacheLines,cacheMap,cacheMapMeta,numCL,1));
    cacheLinesFloat := listAppend(cacheLinesFloat, List.map(Util.tuple31(partlyFilledCacheLines), getCacheLineMapOfPartlyFilledCacheLine));
    cacheLinesInt := listAppend(cacheLinesInt, List.map(Util.tuple32(partlyFilledCacheLines), getCacheLineMapOfPartlyFilledCacheLine));
    //print("Number of partly filled CL bool: " + intString(listLength(Util.tuple33(partlyFilledCacheLines))) + "\n");
    cacheLinesBool := listAppend(cacheLinesBool, List.map(Util.tuple33(partlyFilledCacheLines), getCacheLineMapOfPartlyFilledCacheLine));
    //print("createCacheMapLevelFixedOptimized: Number of bool cache lines = " + intString(listLength(cacheLinesBool)) + "\n");
    oCacheMap := CACHEMAP(iCacheLineSize, cacheVariables,
                          Array.fold(Array.map(threadCacheLines, Util.tuple31), listAppend, cacheLinesFloat),
                          Array.fold(Array.map(threadCacheLines, Util.tuple32), listAppend, cacheLinesInt),
                          Array.fold(Array.map(threadCacheLines, Util.tuple33), listAppend, cacheLinesBool));
    CACHEMAPMETA(scVarCLMapping=oScVarCLMapping) := cacheMapMeta;
    numCL := numCL + listLength(cacheLinesFloat) + listLength(cacheLinesInt) + listLength(cacheLinesBool);
    //print("Number of CLs=" + intString(numCL) + "\n");
    oNumCL := numCL;
  end createCacheMapLevelFixedOptimized;

  protected function createCacheMapLevelFixedOptimizedForLevel "author: marcusw
    Appends the variables which are written by the task list (iLevelTasks) to the info-structure."
    input HpcOmSimCode.TaskList iLevelTasks;
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input Integer iNumberOfThreads;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input array<list<Integer>> iNodeSimCodeVarMapping;
    input array<tuple<list<CacheLineMap>, list<CacheLineMap>, list<CacheLineMap>>> iThreadCacheLines; //Thread CacheLines for float, int and bool -- is updated!
    input tuple<tuple<list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>>,CacheMap,CacheMapMeta,Integer,Integer> iInfo; //<partlyFilledCacheLines,CacheMap,CacheMapMeta,numCL,level>
    output tuple<tuple<list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>>,CacheMap,CacheMapMeta,Integer,Integer> oInfo;
  protected
    Integer createdCL, numCL, cacheLineSize, level; //number of CL created for this level
    list<Integer> allCL;
    list<Integer> availableCL, availableCLold, writtenCL; //all cacheLines that can be used for writing
    list<Integer> cacheLinesPrevLevel; //all cache lines written in previous level
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    list<CacheLineMap> cacheLinesFloat;
    list<CacheLineMap> sharedCacheLines;
    array<list<Integer>> cacheLinesAvailableForLevel;
    tuple<list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>> partlyFilledCacheLines;
  algorithm
    (partlyFilledCacheLines, cacheMap, cacheMapMeta, numCL, level) := iInfo;
    //print("\tcreateCacheMapLevelFixedOptimized0: handling level " + intString(level) + "\n");
    allCL := List.intRange(numCL);
    CACHEMAP(cacheLinesFloat=cacheLinesFloat,cacheLineSize=cacheLineSize) := cacheMap;
    ((cacheMap,cacheMapMeta,createdCL,partlyFilledCacheLines)) := List.fold(getTaskListTasks(iLevelTasks), function createCacheMapLevelFixedOptimizedForTask(iTaskGraph=iTaskGraph, iTaskGraphMeta=iTaskGraphMeta, iSchedulerInfo=iSchedulerInfo, iNumberOfThreads=iNumberOfThreads, iLevel=level, iNodeSimCodeVarMapping = iNodeSimCodeVarMapping, iThreadCacheLines = iThreadCacheLines), (cacheMap,cacheMapMeta,numCL,partlyFilledCacheLines));
    //printCacheMap(cacheMap);
    //print("===================================================\n===================================================\n===================================================\n");
    oInfo := (partlyFilledCacheLines,cacheMap,cacheMapMeta,createdCL,level+1);
  end createCacheMapLevelFixedOptimizedForLevel;

  protected function createCacheMapLevelFixedOptimizedForTask "author: marcusw
    Append the variables that are solved by the given task to the cachelines."
    input HpcOmSimCode.Task iTask;
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input Integer iNumberOfThreads;
    input Integer iLevel;
    input array<list<Integer>> iNodeSimCodeVarMapping;
    input array<tuple<list<CacheLineMap>, list<CacheLineMap>, list<CacheLineMap>>> iThreadCacheLines; //Thread CacheLines for float, int and bool
    input tuple<CacheMap,CacheMapMeta,Integer,tuple<list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>>> iInfo; //<CacheMap,CacheMapMeta,numNewCL,partlyFilledCacheLines (shared-CLs)>
    output tuple<CacheMap,CacheMapMeta,Integer,tuple<list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>>> oInfo;
  protected
    list<Integer> nodeIdc, successorTasks, nodeVars;
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    tuple<CacheMap,CacheMapMeta,Integer,tuple<list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>>> tmpInfo;
    Integer threadIdx, varType, numNewCL;
    array<Option<SimCodeVar.SimVar>> allSCVarsMapping;
    tuple<list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>> partlyFilledCacheLines; //map each non full Cachline (float, int, bool) to: PrefetchLevel, WriteLevel (LevelIdx, ThreadIdx)
  algorithm
    oInfo := match(iTask, iTaskGraph, iTaskGraphMeta, iSchedulerInfo, iNumberOfThreads, iNodeSimCodeVarMapping, iInfo)
      case(HpcOmSimCode.CALCTASK_LEVEL(nodeIdc=nodeIdc,threadIdx=SOME(threadIdx)),_,_,_,_,_,(cacheMap,cacheMapMeta as CACHEMAPMETA(allSCVarsMapping=allSCVarsMapping),numNewCL,partlyFilledCacheLines))
        equation
          //print("\t\tcreateCacheMapLevelFixedOptimizedForTask: handling task with node-indices: " + stringDelimitList(List.map(nodeIdc, intString), ",") + "\n");
          //Get successor tasks
          successorTasks = List.flatten(List.map(nodeIdc, function arrayGet(arr=iTaskGraph)));
          nodeVars = List.flatten(List.map(nodeIdc, function arrayGet(arr=iNodeSimCodeVarMapping)));
          nodeVars = List.sortedUnique(nodeVars,intEq);
          varType = getCacheLineVarTypeBySuccessorList(successorTasks, iSchedulerInfo, iNumberOfThreads, threadIdx);
          if(intEq(varType,1)) then
            //print("\t\t\tcreateCacheMapLevelFixedOptimizedForTask: Handling variables " + stringDelimitList(List.map(nodeVars, intString), ",") + " as THREAD_ONLY by Thread " + intString(threadIdx) + "\n");
            //print("\t\t\t " + stringDelimitList(List.map(nodeVars, function dumpScVarsByIdx(iAllSCVarsMapping=allSCVarsMapping)), "\n\t\t\t ") + "\n");
            ((cacheMap,cacheMapMeta,numNewCL)) = addVarToThreadCL(nodeVars,threadIdx,iThreadCacheLines,(cacheMap,cacheMapMeta,numNewCL));
            //print("\n");
          else
            //print("\t\t\tcreateCacheMapLevelFixedOptimizedForTask: Handling variables " + stringDelimitList(List.map(nodeVars, intString), ",") + " as SHARED by Thread " + intString(threadIdx) + "\n");
            //print("\t\t\t " + stringDelimitList(List.map(nodeVars, function dumpScVarsByIdx(iAllSCVarsMapping=allSCVarsMapping)), "\n\t\t\t ") + "\n");
            ((cacheMap,cacheMapMeta,numNewCL,partlyFilledCacheLines)) = addFixedLevelVarToSharedCL(nodeVars,threadIdx,iLevel,(cacheMap,cacheMapMeta,numNewCL,partlyFilledCacheLines));
            //print("\t\t\tcreateCacheMapLevelFixedOptimizedForTask: Number of partly filled CLs: " + intString(listLength(partlyFilledCacheLines)) + "\n");
            //print("\n");
          end if;
          tmpInfo = (cacheMap, cacheMapMeta, numNewCL, partlyFilledCacheLines);
        then tmpInfo;
      case(HpcOmSimCode.CALCTASK_LEVEL(nodeIdc=nodeIdc,threadIdx=NONE()),_,_,_,_,_,_)
        equation
          print("createCacheMapLevelOptimized1: Calctask without threadIdx given\n");
        then fail();
      else
        equation
          print("createCacheMapLevelOptimized1: Unsupported task type\n");
        then fail();
    end match;
  end createCacheMapLevelFixedOptimizedForTask;

  protected function createCacheMapThreadOptimized "author: marcusw
    Create the optimized cache map for the thread-scheduler."
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input array<Option<SimCodeVar.SimVar>> iAllSCVarsMapping;
    input array<tuple<Integer,Integer>> iSimCodeVarTypes; //<type, numberOfBytesRequired>
    input array<Integer> iScVarTaskMapping;
    input Integer iCacheLineSize;
    input BackendDAE.StrongComponents iAllComponents;
    input array<list<HpcOmSimCode.Task>> iThreadTasks;  //Schedule
    input array<tuple<HpcOmSimCode.Task,Integer>> iAllCalcTasks; //mapping task idx -> (calc task, reference counter)
    input Integer iNumberOfThreads;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input array<list<Integer>> iNodeSimCodeVarMapping;
    output CacheMap oCacheMap;
    output array<tuple<Integer,Integer>> oScVarCLMapping; //mapping for each scVar -> <CLIdx,varType>
    output Integer oNumCL;
  protected
    array<tuple<list<CacheLineMap>, list<CacheLineMap>, list<CacheLineMap>>> threadCacheLines;
    array<tuple<list<CacheLineMap>, list<CacheLineMap>, list<CacheLineMap>>> sharedCacheLines;
    tuple<CacheMap,CacheMapMeta,Integer> tmpCacheInfo;
    list<HpcOmSimCode.Task> threadTasks;
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    Integer numCL;
    array<tuple<Integer,Integer>> scVarCLMapping;
    list<CacheLineMap> cacheLinesFloat, cacheLinesInt, cacheLinesBool;
    list<SimCodeVar.SimVar> cacheVariables;
    tuple<list<CacheLineMap>, list<CacheLineMap>, list<CacheLineMap>> threadIdxCacheLines, sharedIdxCacheLines;
  algorithm
    //Initialize variables
    threadCacheLines := arrayCreate(iNumberOfThreads, ({},{},{}));
    sharedCacheLines := arrayCreate(iNumberOfThreads, ({},{},{}));
    cacheMap := CACHEMAP(iCacheLineSize,{},{},{},{});
    scVarCLMapping := arrayCreate(arrayLength(iAllSCVarsMapping),(-1,-1));
    numCL := 0;
    cacheMapMeta := CACHEMAPMETA(iAllSCVarsMapping, iSimCodeVarTypes, scVarCLMapping);
    tmpCacheInfo := (cacheMap, cacheMapMeta, numCL);
    cacheLinesFloat := {};
    cacheLinesInt := {};
    cacheLinesBool := {};

    for threadIdx in 1:iNumberOfThreads loop
      threadTasks := arrayGet(iThreadTasks, threadIdx);
      tmpCacheInfo := List.fold(threadTasks, function createCacheMapThreadOptimizedForTask(
                        iTaskGraph=iTaskGraph, iTaskGraphMeta=iTaskGraphMeta, iSchedulerInfo=iSchedulerInfo,
                        iNumberOfThreads=iNumberOfThreads, iAllCalcTasks=iAllCalcTasks, iNodeSimCodeVarMapping=iNodeSimCodeVarMapping,
                        iThreadCacheLines=threadCacheLines, iSharedCacheLines=sharedCacheLines), tmpCacheInfo);

      threadIdxCacheLines := arrayGet(threadCacheLines, threadIdx);
      sharedIdxCacheLines := arrayGet(sharedCacheLines, threadIdx);
      cacheLinesFloat := listAppend(cacheLinesFloat, listAppend(Util.tuple31(threadIdxCacheLines), Util.tuple31(sharedIdxCacheLines)));
      cacheLinesInt := listAppend(cacheLinesInt, listAppend(Util.tuple32(threadIdxCacheLines), Util.tuple32(sharedIdxCacheLines)));
      cacheLinesBool := listAppend(cacheLinesBool, listAppend(Util.tuple33(threadIdxCacheLines), Util.tuple33(sharedIdxCacheLines)));
    end for;

    (cacheMap as CACHEMAP(cacheVariables=cacheVariables), cacheMapMeta, oNumCL) := tmpCacheInfo;

    oCacheMap := CACHEMAP(iCacheLineSize, cacheVariables, cacheLinesFloat, cacheLinesInt, cacheLinesBool);
    CACHEMAPMETA(scVarCLMapping=oScVarCLMapping) := cacheMapMeta;
  end createCacheMapThreadOptimized;

  protected function createCacheMapThreadOptimizedForTask "author: marcusw
    Append the variables that are solved by the given task to the cachelines."
    input HpcOmSimCode.Task iTask;
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input Integer iNumberOfThreads;
    input array<tuple<HpcOmSimCode.Task,Integer>> iAllCalcTasks; //mapping task idx -> (calc task, reference counter)
    input array<list<Integer>> iNodeSimCodeVarMapping; //All solved simCode-Variables for the tasks
    input array<tuple<list<CacheLineMap>, list<CacheLineMap>, list<CacheLineMap>>> iThreadCacheLines; //Thread exclusive CacheLines for float, int and bool
    input array<tuple<list<CacheLineMap>, list<CacheLineMap>, list<CacheLineMap>>> iSharedCacheLines; //Thread shared CacheLines for float, int and bool
    input tuple<CacheMap,CacheMapMeta,Integer> iInfo; //<CacheMap,CacheMapMeta,numNewCL>
    output tuple<CacheMap,CacheMapMeta,Integer> oInfo;
  protected
    Integer threadIdx;
    Integer taskIdx;
    Integer taskVarType;
    list<Integer> successorTasks, nodeVars;
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    Integer numNewCL;
    tuple<CacheMap,CacheMapMeta,Integer> tmpInfo;
    array<Option<SimCodeVar.SimVar>> allSCVarsMapping;
  algorithm
    oInfo := match(iTask, iTaskGraph, iTaskGraphMeta, iSchedulerInfo, iNumberOfThreads, iAllCalcTasks, iNodeSimCodeVarMapping, iThreadCacheLines, iSharedCacheLines, iInfo)
      case(HpcOmSimCode.CALCTASK(index=taskIdx, threadIdx=threadIdx),_,_,_,_,_,_,_,_,(cacheMap, cacheMapMeta as CACHEMAPMETA(allSCVarsMapping=allSCVarsMapping), numNewCL))
        equation
          ((_,successorTasks)) = HpcOmScheduler.getSuccessorsByTask(iTask, iTaskGraph, iAllCalcTasks);
          taskVarType = getCacheLineVarTypeBySuccessorList(successorTasks, iSchedulerInfo, iNumberOfThreads, threadIdx);
          nodeVars = arrayGet(iNodeSimCodeVarMapping, taskIdx);
          nodeVars = List.sortedUnique(nodeVars,intEq);
          if(intEq(taskVarType,1)) then
            //print("\t\t\tcreateCacheMapThreadOptimizedForTask: Handling variables " + stringDelimitList(List.map(nodeVars, intString), ",") + " as THREAD_ONLY by Thread " + intString(threadIdx) + "\n");
            //print("\t\t\t " + stringDelimitList(List.map(nodeVars, function dumpScVarsByIdx(iAllSCVarsMapping=allSCVarsMapping)), "\n\t\t\t ") + "\n");
            ((cacheMap,cacheMapMeta,numNewCL)) = addVarToThreadCL(nodeVars,threadIdx,iThreadCacheLines,(cacheMap,cacheMapMeta,numNewCL));
            //print("\n");
          else
            //print("\t\t\tcreateCacheMapThreadOptimizedForTask: Handling variables " + stringDelimitList(List.map(nodeVars, intString), ",") + " as SHARED by Thread " + intString(threadIdx) + "\n");
            //print("\t\t\t " + stringDelimitList(List.map(nodeVars, function dumpScVarsByIdx(iAllSCVarsMapping=allSCVarsMapping)), "\n\t\t\t ") + "\n");
            ((cacheMap,cacheMapMeta,numNewCL)) = addVarToThreadCL(nodeVars,threadIdx,iSharedCacheLines,(cacheMap,cacheMapMeta,numNewCL));
            //print("\n");
          end if;
          tmpInfo = (cacheMap, cacheMapMeta, numNewCL);
        then tmpInfo;
      case(HpcOmSimCode.DEPTASK(_),_,_,_,_,_,_,_,_,(cacheMap, cacheMapMeta as CACHEMAPMETA(allSCVarsMapping=allSCVarsMapping), numNewCL))
        then iInfo;
      else
        equation
          print("createCacheMapThreadOptimizedForTask failed!\n");
        then iInfo;
    end match;
  end createCacheMapThreadOptimizedForTask;

  protected function getCacheLineVarTypeBySuccessorList "author: marcusw
    Get the type of the variable by analyzing the successor tasks
    Type 1: Variable(s) are only used by tasks of Thread <%iThreadIdx%>.
    Type 2: Variable(s) are used by different Threads."
    input list<Integer> iSuccessorTasks;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input Integer iNumberOfThreads;
    input Integer iThreadIdx;
    output Integer oVarType;
  protected
    array<Boolean> usedThreads;
  algorithm
    usedThreads := arrayCreate(iNumberOfThreads, false);
    usedThreads := List.fold(iSuccessorTasks,function getCacheLineVarTypeBySuccessorTask(iSchedulerInfo=iSchedulerInfo), usedThreads);
    usedThreads := arrayUpdate(usedThreads, iThreadIdx, false);
    if(Array.reduce(usedThreads, boolOr)) then
      oVarType := 2;
    else
      oVarType := 1;
    end if;
  end getCacheLineVarTypeBySuccessorList;

  protected function getCacheLineVarTypeBySuccessorTask "author: marcusw
    Set usedThreads[threadIdx] to true, for schedule(iSuccessorTask) = threadIdx."
    input Integer iSuccessorTask;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input array<Boolean> iUsedThreads;
    output array<Boolean> oUsedThreads;
  protected
    Integer successorThreadIdx;
  algorithm
    successorThreadIdx := Util.tuple31(arrayGet(iSchedulerInfo, iSuccessorTask));
    oUsedThreads := arrayUpdate(iUsedThreads, successorThreadIdx, true);
  end getCacheLineVarTypeBySuccessorTask;

  protected function addVarToThreadCL "author: marcusw
    Add the given variables as thread-only variable to the cache lines."
    input list<Integer> iNodeVars;
    input Integer iThreadIdx;
    input array<tuple<list<CacheLineMap>,list<CacheLineMap>,list<CacheLineMap>>> iThreadCacheLines; //Thread CacheLines for float, int and bool
    input tuple<CacheMap,CacheMapMeta,Integer> iInfo; //<CacheMap,CacheMapMeta,numNewCL>
    output tuple<CacheMap,CacheMapMeta,Integer> oInfo;
  protected
    CacheLineMap lastCL;
    SimCodeVar.SimVar cacheVariable;
    array<Option<SimCodeVar.SimVar>> allSCVarsMapping;
    Integer varIdx, varDataType, varNumBytesRequired, numNewCL, cacheLineSize;
    array<tuple<Integer,Integer>> simCodeVarTypes; //<type, numberOfBytesRequired>
    array<tuple<Integer, Integer>> scVarCLMapping;
    list<CacheLineMap> fullCLs, threadCacheLines;
    list<SimCodeVar.SimVar> cacheVariables;
    list<CacheLineMap> cacheLinesFloat, cacheLinesInt, cacheLinesBool;

    Integer lastCLidx;
    Integer lastCLnumBytesFree;
    list<CacheLineEntry> lastCLentries;
    CacheLineEntry varEntry;
    DAE.ComponentRef cacheVarName;

    list<CacheLineMap> threadCacheLinesFloat, threadCacheLinesInt, threadCacheLinesBool;
  algorithm
    (CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat, cacheLinesInt=cacheLinesInt, cacheLinesBool=cacheLinesBool),CACHEMAPMETA(allSCVarsMapping=allSCVarsMapping,simCodeVarTypes=simCodeVarTypes,scVarCLMapping=scVarCLMapping),numNewCL) := iInfo;

    //only the first CL has enough space to store another variable
    for varIdx in iNodeVars loop
      ((varDataType,varNumBytesRequired)) := arrayGet(simCodeVarTypes, varIdx);
      if(intEq(varDataType, VARTYPE_FLOAT)) then
        //print("addVarToThreadCL: Found REAL-VARIABLE!\n");
        ((threadCacheLines,threadCacheLinesInt,threadCacheLinesBool)) := arrayGet(iThreadCacheLines, iThreadIdx);
      else
        if(intEq(varDataType, VARTYPE_INTEGER)) then
          //print("addVarToThreadCL: Found INT-VARIABLE!\n");
          ((threadCacheLinesFloat,threadCacheLines,threadCacheLinesBool)) := arrayGet(iThreadCacheLines, iThreadIdx);
        else
          if(intEq(varDataType, VARTYPE_BOOLEAN)) then
            //print("addVarToThreadCL: Found BOOL-VARIABLE!\n");
            ((threadCacheLinesFloat,threadCacheLinesInt,threadCacheLines)) := arrayGet(iThreadCacheLines, iThreadIdx);
          else
            print("addVarToThreadCL: Found Variable with unknown type!\n");
            break;
          end if;
        end if;
      end if;

      if(intGt(listLength(threadCacheLines), 0)) then
        lastCL::fullCLs := threadCacheLines;
      else
        lastCLidx := listLength(cacheLinesFloat)+ listLength(cacheLinesInt) + listLength(cacheLinesBool) + numNewCL + 1;
        lastCLnumBytesFree := cacheLineSize;
        lastCLentries := {};
        lastCL := CACHELINEMAP(idx=lastCLidx, numBytesFree=lastCLnumBytesFree, entries=lastCLentries);
        numNewCL := numNewCL + 1;
        fullCLs := {};
      end if;

      CACHELINEMAP(idx=lastCLidx,numBytesFree=lastCLnumBytesFree,entries=lastCLentries) := lastCL;
      if(intLt(lastCLnumBytesFree,varNumBytesRequired)) then //variable does not fit into CL --> create a new CL
        //print("\t\t\t\taddVarToThreadCL: variable " + intString(varIdx) + " does not fit into lastCL.\n");
        fullCLs := lastCL::fullCLs;
        lastCLidx := listLength(cacheLinesFloat) + listLength(cacheLinesInt) + listLength(cacheLinesBool) + numNewCL + 1;
        //print("\t\t\t\taddVarToThreadCL: lastCLidx " + intString(listLength(cacheLinesFloat)) + " + " + intString(numNewCL) + " + 1\n");
        lastCLnumBytesFree := cacheLineSize;
        lastCLentries := {};
        lastCL := CACHELINEMAP(idx=lastCLidx, numBytesFree=lastCLnumBytesFree, entries=lastCLentries);
        numNewCL := numNewCL + 1;
      end if;
      SOME(cacheVariable as SimCodeVar.SIMVAR(name=cacheVarName)) := arrayGet(allSCVarsMapping, varIdx);
      //print("addVarToThreadCL: Variable " + ComponentReference.printComponentRefStr(cacheVarName) + " has type " + intString(varDataType) + "\n");

      //print("\t\t\t\taddVarToThreadCL: cacheVariable found.\n");
      cacheVariables := cacheVariable::cacheVariables;
      scVarCLMapping := arrayUpdate(scVarCLMapping, varIdx, (lastCLidx,varDataType));
      //print("\t\t\tCache variables: " + intString(listLength(cacheVariables)) + " to thread " + intString(iThreadIdx) + "\n");
      varEntry := CACHELINEENTRY(start=cacheLineSize-lastCLnumBytesFree,dataType=varDataType,size=varNumBytesRequired,scVarIdx=listLength(cacheVariables),threadOwner=iThreadIdx);
      lastCL := CACHELINEMAP(idx=lastCLidx,numBytesFree=lastCLnumBytesFree-varNumBytesRequired,entries=varEntry::lastCLentries);

      if(intEq(varDataType, VARTYPE_FLOAT)) then
        _ := arrayUpdate(iThreadCacheLines, iThreadIdx, (lastCL::fullCLs, threadCacheLinesInt, threadCacheLinesBool));
      else
        if(intEq(varDataType, VARTYPE_INTEGER)) then
          _ := arrayUpdate(iThreadCacheLines, iThreadIdx, (threadCacheLinesFloat, lastCL::fullCLs, threadCacheLinesBool));
        else
          if(intEq(varDataType, VARTYPE_BOOLEAN)) then
            _ := arrayUpdate(iThreadCacheLines, iThreadIdx, (threadCacheLinesFloat, threadCacheLinesInt, lastCL::fullCLs));
          end if;
        end if;
      end if;
    end for;

    oInfo := (CACHEMAP(cacheLineSize,cacheVariables,cacheLinesFloat,cacheLinesInt,cacheLinesBool),CACHEMAPMETA(allSCVarsMapping,simCodeVarTypes,scVarCLMapping),numNewCL);
  end addVarToThreadCL;

  protected function addFixedLevelVarToSharedCL "author: marcusw
    Append the given variables to shared cache lines. If a matching partly filled cache line is found,
    the partly filled cache line object is updates. Otherwise a new cache line object is created. If a cacheline
    is filled completely, it is appended to the CacheMap and CacheMapMeta."
    input list<Integer> iNodeVars;
    input Integer iThreadIdx;
    input Integer iLevelIdx;
    input tuple<CacheMap,CacheMapMeta,Integer,tuple<list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>>> iInfo; //<CacheMap,CacheMapMeta,numNewCL,partlyFilledCL>
    output tuple<CacheMap,CacheMapMeta,Integer,tuple<list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>>> oInfo;
  protected
    CacheLineMap lastCL;
    SimCodeVar.SimVar cacheVariable;
    array<Option<SimCodeVar.SimVar>> allSCVarsMapping;
    Integer varIdx, varDataType, varNumBytesRequired, numNewCL, cacheLineSize, varSize;
    array<tuple<Integer,Integer>> simCodeVarTypes; //<type, numberOfBytesRequired>
    array<tuple<Integer, Integer>> scVarCLMapping;
    list<CacheLineMap> fullCLs, threadCacheLines;
    list<SimCodeVar.SimVar> cacheVariables;
    list<CacheLineMap> cacheLinesFloat;
    tuple<list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>> partlyFilledCacheLines;

    PartlyFilledCacheLine matchedCacheLine;
    Integer matchedCacheLineIdx;

    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
  algorithm
    (cacheMap as CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat),cacheMapMeta as CACHEMAPMETA(allSCVarsMapping=allSCVarsMapping,simCodeVarTypes=simCodeVarTypes,scVarCLMapping=scVarCLMapping),numNewCL,partlyFilledCacheLines) := iInfo;
    for varIdx in iNodeVars loop
      ((varDataType,varSize)) := arrayGet(simCodeVarTypes, varIdx);
      //print("\t\t\t\taddFixedLevelVarToSharedCL: varIdx=" + intString(varIdx) + " varType=" + intString(varDataType) + "\n");
      ((cacheMap,cacheMapMeta,numNewCL,partlyFilledCacheLines)) := addFixedLevelVarToSharedCL0(findMatchingSharedCL(varIdx, varSize, varDataType, iLevelIdx, iThreadIdx, partlyFilledCacheLines), iThreadIdx, varIdx, iLevelIdx, (cacheMap,cacheMapMeta,numNewCL,partlyFilledCacheLines));
    end for;
    oInfo := (cacheMap,cacheMapMeta,numNewCL,partlyFilledCacheLines);
  end addFixedLevelVarToSharedCL;

  protected function addFixedLevelVarToSharedCL0 "author: marcusw
    Add the given variable to the iMatchedCacheLine if the object is not NONE() and if there is enough space.
    Otherwise add a new CL."
    input Option<tuple<PartlyFilledCacheLine,Integer>> iMatchedCacheLine; //<CL, listIndex>
    input Integer iThreadIdx;
    input Integer iVarIdx;
    input Integer iLevelIdx;
    input tuple<CacheMap,CacheMapMeta,Integer,tuple<list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>>> iInfo;
    output tuple<CacheMap,CacheMapMeta,Integer,tuple<list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>>> oInfo;
  protected
    PartlyFilledCacheLine partlyFilledCacheLine;

    CacheLineMap cacheLineMap;
    list<Integer> prefetchLevel;
    list<tuple<Integer, Integer>> writeLevel;
    CacheLineEntry entry;

    Integer idx, listIndex;
    Integer numBytesFree;
    list<CacheLineEntry> entries;

    Integer cacheLineSize;
    list<SimCodeVar.SimVar> cacheVariables;
    list<CacheLineMap> cacheLinesFloat, cacheLinesInt, cacheLinesBool;

    SimCodeVar.SimVar cacheVariable;
    array<Option<SimCodeVar.SimVar>> allSCVarsMapping;
    array<tuple<Integer,Integer>> simCodeVarTypes; //<type, numberOfBytesRequired>
    array<tuple<Integer, Integer>> scVarCLMapping; //mapping for each scVar -> <CLIdx,varType>

    Integer varSize, varType, numNewCL;
    list<PartlyFilledCacheLine> partlyFilledClFloat, partlyFilledClInt, partlyFilledClBool;
  algorithm
    oInfo := match(iMatchedCacheLine, iThreadIdx, iVarIdx, iLevelIdx, iInfo)
      case(SOME((partlyFilledCacheLine as PARTLYFILLEDCACHELINE(cacheLineMap, prefetchLevel, writeLevel),listIndex)),_,_,_,(CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat,cacheLinesInt=cacheLinesInt,cacheLinesBool=cacheLinesBool),CACHEMAPMETA(allSCVarsMapping=allSCVarsMapping,simCodeVarTypes=simCodeVarTypes,scVarCLMapping=scVarCLMapping),numNewCL,(partlyFilledClFloat, partlyFilledClInt, partlyFilledClBool)))
        equation //this case is used if the partly filled cache line has enough space to store the variable
          CACHELINEMAP(idx,numBytesFree,entries) = cacheLineMap;
          ((varType,varSize)) = arrayGet(simCodeVarTypes, iVarIdx);
          numBytesFree = numBytesFree - varSize;
          true = intGe(numBytesFree,0);
          SOME(cacheVariable) = arrayGet(allSCVarsMapping, iVarIdx);
          cacheVariables = cacheVariable::cacheVariables;
          entry = CACHELINEENTRY(cacheLineSize - numBytesFree - varSize, varType, varSize, listLength(cacheVariables),iThreadIdx);
          cacheLineMap = CACHELINEMAP(idx,numBytesFree,entry::entries);

          if(intGt(iLevelIdx - 1, 0)) then
            prefetchLevel = (iLevelIdx-1)::prefetchLevel;
          end if;

          writeLevel = (iLevelIdx, iThreadIdx)::writeLevel;
          partlyFilledCacheLine = PARTLYFILLEDCACHELINE(cacheLineMap, prefetchLevel, writeLevel);

          scVarCLMapping = arrayUpdate(scVarCLMapping, iVarIdx, (idx,varType));

          if(intEq(numBytesFree, 0)) then //CL is now full - remove it from partly filled CL list and add it to cachemap
            //print("\t\t\t\taddFixedLevelVarToSharedCL0: Cache line with index " + intString(idx) + " is now fully filled\n");
            if(intEq(varType, VARTYPE_FLOAT)) then
              partlyFilledClFloat = listDelete(partlyFilledClFloat, listIndex);
              cacheLinesFloat = cacheLineMap::cacheLinesFloat;
            else
              if(intEq(varType, VARTYPE_INTEGER)) then
                partlyFilledClInt = listDelete(partlyFilledClInt, listIndex);
                cacheLinesInt = cacheLineMap::cacheLinesInt;
              else
                partlyFilledClBool = listDelete(partlyFilledClBool, listIndex);
                cacheLinesBool = cacheLineMap::cacheLinesBool;
              end if;
            end if;
            numNewCL = numNewCL - 1;
          else
            if(intEq(varType, VARTYPE_FLOAT)) then
              partlyFilledClFloat = List.set(partlyFilledClFloat, listIndex, partlyFilledCacheLine);
            else
              if(intEq(varType, VARTYPE_INTEGER)) then
                partlyFilledClInt = List.set(partlyFilledClInt, listIndex, partlyFilledCacheLine);
              else
                partlyFilledClBool = List.set(partlyFilledClBool, listIndex, partlyFilledCacheLine);
              end if;
            end if;
          end if;
          //print("\t\t\t\taddFixedLevelVarToSharedCL0: Used existing cache line with index " + intString(idx) + " to store the variable\n");
        then ((CACHEMAP(cacheLineSize,cacheVariables,cacheLinesFloat,cacheLinesInt,cacheLinesBool),CACHEMAPMETA(allSCVarsMapping,simCodeVarTypes,scVarCLMapping),numNewCL,(partlyFilledClFloat, partlyFilledClInt, partlyFilledClBool)));
      case(NONE(),_,_,_,(CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat,cacheLinesInt=cacheLinesInt,cacheLinesBool=cacheLinesBool),CACHEMAPMETA(allSCVarsMapping=allSCVarsMapping,simCodeVarTypes=simCodeVarTypes,scVarCLMapping=scVarCLMapping),numNewCL,(partlyFilledClFloat, partlyFilledClInt, partlyFilledClBool)))
        equation
          ((varType,varSize)) = arrayGet(simCodeVarTypes, iVarIdx);
          numNewCL = numNewCL + 1;
          idx = listLength(cacheLinesFloat) + listLength(cacheLinesInt) + listLength(cacheLinesBool) + numNewCL;
          numBytesFree = cacheLineSize - varSize;
          entries = {};
          prefetchLevel = {};
          writeLevel = {};

          SOME(cacheVariable) = arrayGet(allSCVarsMapping, iVarIdx);
          cacheVariables = cacheVariable::cacheVariables;
          entry = CACHELINEENTRY(0, varType, varSize, listLength(cacheVariables), iThreadIdx);
          cacheLineMap = CACHELINEMAP(idx,numBytesFree,entry::entries);

          if(intGt(iLevelIdx - 1, 0)) then
            prefetchLevel = (iLevelIdx-1)::prefetchLevel;
          end if;

          writeLevel = (iLevelIdx, iThreadIdx)::writeLevel;
          partlyFilledCacheLine = PARTLYFILLEDCACHELINE(cacheLineMap, prefetchLevel, writeLevel);

          scVarCLMapping = arrayUpdate(scVarCLMapping, iVarIdx, (idx,varType));

          if(intEq(numBytesFree - varSize, 0)) then //CL is now full - add CL to cachemap
            if(intEq(varType, VARTYPE_FLOAT)) then
              cacheLinesFloat = cacheLineMap::cacheLinesFloat;
            else
              if(intEq(varType, VARTYPE_INTEGER)) then
                cacheLinesInt = cacheLineMap::cacheLinesInt;
              else
                cacheLinesBool = cacheLineMap::cacheLinesBool;
              end if;
            end if;
            numNewCL = numNewCL - 1;
          else //Add new CL as partly filled CL
            if(intEq(varType, VARTYPE_FLOAT)) then
              partlyFilledClFloat = partlyFilledCacheLine::partlyFilledClFloat;
            else
              if(intEq(varType, VARTYPE_INTEGER)) then
                partlyFilledClInt = partlyFilledCacheLine::partlyFilledClInt;
              else
                partlyFilledClBool = partlyFilledCacheLine::partlyFilledClBool;
              end if;
            end if;
          end if;
          //print("\t\t\t\taddFixedLevelVarToSharedCL0: Created a new cache line with index " + intString(idx) + " to store the variable\n");
        then ((CACHEMAP(cacheLineSize,cacheVariables,cacheLinesFloat,cacheLinesInt,cacheLinesBool),CACHEMAPMETA(allSCVarsMapping,simCodeVarTypes,scVarCLMapping),numNewCL,(partlyFilledClFloat, partlyFilledClInt, partlyFilledClBool)));
      else
        equation
          print("addFixedLevelVarToSharedCL0: failed\n");
        then iInfo;
    end match;
  end addFixedLevelVarToSharedCL0;

  protected function findMatchingSharedCL "author: marcusw
    Iterate over the given shared cache line list and return the first entry that can be used to store the shared variable iNodeVar."
    input Integer iNodeVar;
    input Integer iVarSize; //number of required bytes
    input Integer iVarType;
    input Integer iLevelIdx;
    input Integer iThreadIdx;
    input tuple<list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>,list<PartlyFilledCacheLine>> iSharedCacheLines;
    output Option<tuple<PartlyFilledCacheLine,Integer>> oMatchedCacheLine; //<CL, listIndex>
  protected
    list<PartlyFilledCacheLine> partlyFilledCacheLines;
  algorithm
    oMatchedCacheLine := NONE();
    if(intEq(iVarType, VARTYPE_FLOAT)) then
      partlyFilledCacheLines := Util.tuple31(iSharedCacheLines);
    else
      if(intEq(iVarType, VARTYPE_INTEGER)) then
        partlyFilledCacheLines := Util.tuple32(iSharedCacheLines);
      else
        partlyFilledCacheLines := Util.tuple33(iSharedCacheLines);
      end if;
    end if;
    oMatchedCacheLine := findMatchingSharedCL0(iNodeVar, iVarSize, iLevelIdx, iThreadIdx, 1, partlyFilledCacheLines);
  end findMatchingSharedCL;

  protected function findMatchingSharedCL0 "author: marcusw
    Iterate over the given shared cache line list and return the first entry that can be used to store the shared variable iNodeVar."
    input Integer iNodeVar;
    input Integer iVarSize; //number of required bytes
    input Integer iLevelIdx;
    input Integer iThreadIdx;
    input Integer iCurrentListIdx;
    input list<PartlyFilledCacheLine> iSharedCacheLines;
    output Option<tuple<PartlyFilledCacheLine,Integer>> oMatchedCacheLine; //<CL, listIndex>
  protected
    PartlyFilledCacheLine head;
    list<PartlyFilledCacheLine> rest;
    Option<tuple<PartlyFilledCacheLine,Integer>> tmpMatchedCacheLine;

    CacheLineMap cacheLineMap;
    Integer numBytesFree;
    list<Integer> prefetchLevel;
    list<tuple<Integer,Integer>> writeLevel; //(LevelIdx, ThreadIdx)
  algorithm
    oMatchedCacheLine := match(iNodeVar, iVarSize, iLevelIdx, iThreadIdx, iCurrentListIdx, iSharedCacheLines)
      case(_,_,_,_,_,(head as PARTLYFILLEDCACHELINE(cacheLineMap=(cacheLineMap as CACHELINEMAP(numBytesFree=numBytesFree)),prefetchLevel=prefetchLevel,writeLevel=writeLevel))::rest)
        equation
          if(boolOr(intLt(numBytesFree, iVarSize), List.exist1(prefetchLevel,intEq, iLevelIdx))) then //The CL has not enough space or is used for prefetching -- can not be used for writing
            tmpMatchedCacheLine = findMatchingSharedCL0(iNodeVar, iVarSize, iLevelIdx, iThreadIdx, iCurrentListIdx+1, rest);
          else
            if(List.exist(writeLevel, function isCLWrittenByOtherThread(iLevelIdx=iLevelIdx, iThreadIdx=iThreadIdx))) then //The CL is written by another thread in the same level -- can not be used for writing
              tmpMatchedCacheLine = findMatchingSharedCL0(iNodeVar, iVarSize, iLevelIdx, iThreadIdx, iCurrentListIdx+1, rest);
            else
              if(List.exist(writeLevel, function isCLWrittenByOtherThread(iLevelIdx=iLevelIdx-1, iThreadIdx=iThreadIdx))) then //The CL is written by another thread in the previous level -- can not be used for writing
                tmpMatchedCacheLine = findMatchingSharedCL0(iNodeVar, iVarSize, iLevelIdx, iThreadIdx, iCurrentListIdx+1, rest);
              else //CL matches
                tmpMatchedCacheLine = SOME((head, iCurrentListIdx));
              end if;
            end if;
          end if;
        then tmpMatchedCacheLine;
      else NONE();
    end match;
  end findMatchingSharedCL0;

  protected function isCLWrittenByOtherThread "author: marcusw
    Return 'true' if the given entry has levelidx == iLevelIdx and is handled by a thread != iThreadIdx."
    input tuple<Integer,Integer> iLevelInfo; //(LevelIdx, ThreadIdx)
    input Integer iLevelIdx;
    input Integer iThreadIdx;
    output Boolean oWrittenByOtherThread;
  protected
    Integer levelIdx, threadIdx;
    Boolean ret;
  algorithm
    (levelIdx, threadIdx) := iLevelInfo;
    ret := boolAnd(intEq(levelIdx, iLevelIdx), intNe(threadIdx, iThreadIdx));
    oWrittenByOtherThread := ret;
  end isCLWrittenByOtherThread;

  protected function createCacheMapDefault "author: marcusw
    Create a default cacheMap without optimization."
    input array<Option<SimCodeVar.SimVar>> iAllSCVars;
    input Integer iCacheLineSize;
    input SimCodeVar.SimVars iSimCodeVars;
    input array<Integer> iScVarTaskMapping;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input array<tuple<Integer,Integer>> iSimCodeVarTypes; //<varType, varSize>
    output CacheMap oCacheMap;
    output array<tuple<Integer,Integer>> oScVarCLMapping; //mapping for each scVar -> CLIdx
    output Integer oNumCL;
  protected
    list<SimCodeVar.SimVar> iAllFloatVars;
    list<CacheLineMap> cacheLineFloatMaps;
    array<tuple<Integer,Integer>> tmpScVarCLMapping;
  algorithm
    if(stringEqual(Config.simCodeTarget(), "Cpp")) then
      (oCacheMap, oScVarCLMapping, oNumCL) := createCacheMapDefaultCppRuntime(iAllSCVars, iCacheLineSize, iSimCodeVars, iScVarTaskMapping, iSchedulerInfo, iSimCodeVarTypes);
    else
      oCacheMap := UNIFORM_CACHEMAP(iCacheLineSize,{},{});
      oNumCL := 0;
      oScVarCLMapping := arrayCreate(0, (-1,-1));
    end if;
  end createCacheMapDefault;

  protected function createCacheMapDefaultCppRuntime "author: marcusw
    Create a default cacheMap without optimization."
    input array<Option<SimCodeVar.SimVar>> iAllSCVars;
    input Integer iCacheLineSize;
    input SimCodeVar.SimVars iSimCodeVars;
    input array<Integer> iScVarTaskMapping;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input array<tuple<Integer,Integer>> iSimCodeVarTypes; //<varType, varSize>
    output CacheMap oCacheMap;
    output array<tuple<Integer,Integer>> oScVarCLMapping; //mapping for each scVar -> CLIdx
    output Integer oNumCL;
  protected
    list<SimCodeVar.SimVar> stateVars, derivativeVars, algVars, discreteAlgVars, paramVars, aliasVars, intAlgVars, intParamVars, intAliasVars, boolAlgVars, boolParamVars, boolAliasVars;
    list<SimCodeVar.SimVar> inputVars, outputVars;
    CacheMap cacheMap;
    CacheLineMap lastCacheLine, lastCacheLineNew;
    array<tuple<Integer,Integer>> scVarCLMapping; //mapping for each scVar -> CLIdx
    Integer tmpNumCL, currentScVarIdx;
    Integer paramVarsStart, aliasVarsStart, stateDerVarsStart, algVarsStart, discreteAlgVarsStart, intAlgVarsStart, intParamVarsStart;
    list<CacheLineMap> filledCacheLines;
    list<SimCodeVar.SimVar> allVars;
  algorithm
    (oCacheMap, oScVarCLMapping, oNumCL) := match(iAllSCVars, iCacheLineSize, iSimCodeVars, iScVarTaskMapping, iSchedulerInfo, iSimCodeVarTypes)
      case(_,_,SimCodeVar.SIMVARS(stateVars=stateVars, derivativeVars=derivativeVars, algVars=algVars, discreteAlgVars=discreteAlgVars,
                                  paramVars=paramVars, aliasVars=aliasVars, intAlgVars=intAlgVars, intParamVars=intParamVars, intAliasVars=intAliasVars,
                                  boolAlgVars=boolAlgVars, boolParamVars=boolParamVars, boolAliasVars=boolAliasVars,  inputVars=inputVars, outputVars=outputVars),_,_,_)
        equation
          //add stateDer - variables to seperate cache lines
          currentScVarIdx = 1;
          stateDerVarsStart = listLength(stateVars) + 1;
          scVarCLMapping = arrayCreate(arrayLength(iAllSCVars),(-1,-1));
          filledCacheLines = {};
          lastCacheLine = CACHELINEMAP(1, iCacheLineSize, {});
          (filledCacheLines, lastCacheLine, currentScVarIdx) = createCacheMapDefaultCppRuntime0(derivativeVars, currentScVarIdx, stateDerVarsStart, scVarCLMapping, filledCacheLines, iScVarTaskMapping, iSchedulerInfo, lastCacheLine, iCacheLineSize, iSimCodeVarTypes);
          filledCacheLines = lastCacheLine::filledCacheLines;
          lastCacheLine = CACHELINEMAP(listLength(filledCacheLines) + 1, iCacheLineSize, {});
          allVars = listReverse(derivativeVars);
          //print("StateDer-Vars finished\n");

          //add all other variables to uniform cache map
          algVarsStart = stateDerVarsStart + listLength(derivativeVars);
          discreteAlgVarsStart = algVarsStart + listLength(algVars);
          intAlgVarsStart = discreteAlgVarsStart + listLength(discreteAlgVars);
          aliasVarsStart = intAlgVarsStart + listLength(boolAlgVars) + listLength(inputVars) + listLength(outputVars);
          paramVarsStart = aliasVarsStart + listLength(aliasVars) + listLength(intAliasVars) + listLength(boolAliasVars);
          intParamVarsStart = paramVarsStart + listLength(paramVars);

          (filledCacheLines, lastCacheLine, currentScVarIdx) = createCacheMapDefaultCppRuntime0(algVars, currentScVarIdx, algVarsStart, scVarCLMapping, filledCacheLines, iScVarTaskMapping, iSchedulerInfo, lastCacheLine, iCacheLineSize, iSimCodeVarTypes);
          allVars = listAppend(listReverse(algVars), allVars);
          //print("algVars finished\n");

          (filledCacheLines, lastCacheLine, currentScVarIdx) = createCacheMapDefaultCppRuntime0(discreteAlgVars, currentScVarIdx, discreteAlgVarsStart, scVarCLMapping, filledCacheLines, iScVarTaskMapping, iSchedulerInfo, lastCacheLine, iCacheLineSize, iSimCodeVarTypes);
          allVars = listAppend(listReverse(discreteAlgVars), allVars);
          //print("discreteAlgVars finished\n");

          //print("\n\nParamVarsStart: " + intString(paramVarsStart) + "\n");
          (filledCacheLines, lastCacheLine, currentScVarIdx) = createCacheMapDefaultCppRuntime0(paramVars, currentScVarIdx, paramVarsStart, scVarCLMapping, filledCacheLines, iScVarTaskMapping, iSchedulerInfo, lastCacheLine, iCacheLineSize, iSimCodeVarTypes);
          allVars = listAppend(listReverse(paramVars), allVars);
          //print("paramVars finished\n");

          (filledCacheLines, lastCacheLine, currentScVarIdx) = createCacheMapDefaultCppRuntime0(aliasVars, currentScVarIdx, aliasVarsStart, scVarCLMapping, filledCacheLines, iScVarTaskMapping, iSchedulerInfo, lastCacheLine, iCacheLineSize, iSimCodeVarTypes);
          allVars = listAppend(listReverse(aliasVars), allVars);

          //print("\n\nIntAlgVarsStart: " + intString(intAlgVarsStart) + "\n");
          (filledCacheLines, lastCacheLine, currentScVarIdx) = createCacheMapDefaultCppRuntime0(intAlgVars, currentScVarIdx, intAlgVarsStart, scVarCLMapping, filledCacheLines, iScVarTaskMapping, iSchedulerInfo, lastCacheLine, iCacheLineSize, iSimCodeVarTypes);
          allVars = listAppend(listReverse(intAlgVars), allVars);
          //print("intAlgVars finished\n");

          //print("\n\nIntParamVarsStart: " + intString(intParamVarsStart) + "\n");
          (filledCacheLines, lastCacheLine, currentScVarIdx) = createCacheMapDefaultCppRuntime0(intParamVars, currentScVarIdx, intAlgVarsStart, scVarCLMapping, filledCacheLines, iScVarTaskMapping, iSchedulerInfo, lastCacheLine, iCacheLineSize, iSimCodeVarTypes);
          allVars = listAppend(listReverse(intParamVars), allVars);
          //print("intAlgVars finished\n");

          cacheMap = UNIFORM_CACHEMAP(iCacheLineSize, allVars, lastCacheLine::filledCacheLines);
        then (cacheMap, scVarCLMapping, listLength(filledCacheLines) + 1);
    end match;
  end createCacheMapDefaultCppRuntime;

  protected function createCacheMapDefaultCppRuntime0 "author: marcusw
    Add the given variables to cache lines."
    input list<SimCodeVar.SimVar> iVariables; //all variables that should be added to cache lines
    input Integer iScVarIdxStart; //index of the first variable of the iVariable-list
    input Integer iRealScVarIdxStart;
    input array<tuple<Integer,Integer>> iScVarCLMapping; //updated
    input list<CacheLineMap> iFilledCacheLines; //all cache lines that are already filled
    input array<Integer> iScVarTaskMapping;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input CacheLineMap iLastCacheLine;
    input Integer iCacheLineSize;
    input array<tuple<Integer,Integer>> iSimCodeVarTypes;
    output list<CacheLineMap> oFilledCacheLines;
    output CacheLineMap oLastCacheLine;
    output Integer oScVarIdx;
  protected
    Integer currentScVarIdx, varSize, varType, varTask, threadIdx, varCLIdx;
    SimCodeVar.SimVar var;
    CacheLineEntry entry;
    Boolean newCacheLineCreated;
    CacheLineMap lastCacheLine, lastCacheLineNew;
    list<CacheLineMap> filledCacheLines;
    list<CacheLineEntry> cachelineEntries;
    DAE.ComponentRef name;
    String nameStr;
  algorithm
    currentScVarIdx := 0;
    lastCacheLine := iLastCacheLine;
    filledCacheLines := iFilledCacheLines;
    for var in iVariables loop
      SimCodeVar.SIMVAR(name=name) := var;
      nameStr := ComponentReference.printComponentRefStr(name);
      if(boolAnd(intLt(currentScVarIdx, arrayLength(iSimCodeVarTypes)), intLt(currentScVarIdx, arrayLength(iScVarCLMapping)))) then
        ((varType, varSize)) := arrayGet(iSimCodeVarTypes, currentScVarIdx + iRealScVarIdxStart);

        //print("createCacheMapDefaultCppRuntime0: iScVarIdxStart=" + intString(iScVarIdxStart) + " iRealScVarIdxStart=" + intString(iRealScVarIdxStart) + "\n");
        //print("Try to get variable: " + intString(currentScVarIdx + iRealScVarIdxStart) + " out of array with length: " + intString(arrayLength(iScVarTaskMapping)) + "\n");
        //print("Try to get variable: " + intString(currentScVarIdx + iRealScVarIdxStart) + " out of array with length: " + intString(arrayLength(iSimCodeVarTypes)) + "\n");
        //print("iScVarCLMapping-length: " + intString(arrayLength(iScVarCLMapping)) + "\n");

        if(intLe(currentScVarIdx + iRealScVarIdxStart, arrayLength(iScVarTaskMapping))) then
         varTask := arrayGet(iScVarTaskMapping, currentScVarIdx + iRealScVarIdxStart);
        else
          varTask := -1;
        end if;
        //print("createCacheMapDefaultCppRuntime0: Handling SC-Var '" + intString(currentScVarIdx + iScVarIdxStart) + "' [" + nameStr + "] by task '" + intString(varTask) + "'\n");
        if(boolAnd(intGe(varTask, 1), intGe(arrayLength(iSchedulerInfo), varTask))) then
          threadIdx := Util.tuple31(arrayGet(iSchedulerInfo, varTask));
        else
          threadIdx := -1;
        end if;
        //print("threadIdx: " + intString(threadIdx) + "\n");
        entry := CACHELINEENTRY(-1, varType, varSize, currentScVarIdx + iScVarIdxStart, threadIdx);

        (entry, lastCacheLineNew, newCacheLineCreated) := createCacheMapDefaultCppRuntime1(entry, iCacheLineSize, lastCacheLine);
        CACHELINEMAP(idx=varCLIdx, entries=cachelineEntries) := lastCacheLineNew;
        //print("Number of elements in cacheline: " + intString(listLength(cachelineEntries)) + "\n");
        _ := arrayUpdate(iScVarCLMapping, currentScVarIdx + iRealScVarIdxStart, (varCLIdx, varType));

        if(newCacheLineCreated) then
          filledCacheLines := lastCacheLine::filledCacheLines;
        end if;
        lastCacheLine := lastCacheLineNew;
      end if;
      currentScVarIdx := currentScVarIdx + 1;
    end for;
    oFilledCacheLines := filledCacheLines;
    oLastCacheLine := lastCacheLine;
    oScVarIdx := currentScVarIdx + iScVarIdxStart;
  end createCacheMapDefaultCppRuntime0;

  protected function createCacheMapDefaultCppRuntime1 "author: marcusw
    Add the given variable to the given cache line. If the variable does not fit into the cache line, create a new one."
    input CacheLineEntry iCacheLineEntry;
    input Integer iCacheLineSize;
    input CacheLineMap iLastCacheLine; //check if the variable fits into this cache line
    output CacheLineEntry oCacheLineEntry; //start is modified
    output CacheLineMap oLastCacheLine; //either the given iLastCacheLine with the new entry or a new cache line.
    output Boolean oNewOneCreated; //true if a new cache line was created
  protected
    Integer numberOfFreeBytesLastCacheLine;
    list<CacheLineEntry> lastCacheLineEntries;
    CacheLineMap cacheLine;
    CacheLineEntry cacheLineEntry;
    Integer entrySize, entryStart, entryType, entryVarIdx, entryThreadOwner, lastCacheLineIdx;
  algorithm
    CACHELINEENTRY(entryStart, entryType, entrySize, entryVarIdx, entryThreadOwner) := iCacheLineEntry;
    CACHELINEMAP(lastCacheLineIdx, numberOfFreeBytesLastCacheLine, lastCacheLineEntries) := iLastCacheLine;
    if(intGt(entrySize, numberOfFreeBytesLastCacheLine)) then
      //create a new cache line
      cacheLineEntry := CACHELINEENTRY(0, entryType, entrySize, entryVarIdx, entryThreadOwner);
      cacheLine := CACHELINEMAP(lastCacheLineIdx + 1, iCacheLineSize - entrySize, {cacheLineEntry});
      oNewOneCreated := true;
    else
      //add the entry to the last cache line
      cacheLineEntry := CACHELINEENTRY(iCacheLineSize - numberOfFreeBytesLastCacheLine, entryType, entrySize, entryVarIdx, entryThreadOwner);
      cacheLine := CACHELINEMAP(lastCacheLineIdx, numberOfFreeBytesLastCacheLine - entrySize, cacheLineEntry::lastCacheLineEntries);
      oNewOneCreated := false;
    end if;
    oCacheLineEntry := cacheLineEntry;
    oLastCacheLine := cacheLine;
  end createCacheMapDefaultCppRuntime1;

  protected function appendNodeVarsToCacheMap "author: marcusw
    Append the variables that are solved by the given node to the cachelines. The used CL are removed from the candidate list."
    input Integer iNodeIdx;
    input Integer iOwnerThread; //-1 if none
    input array<list<Integer>> iNodeSimCodeVarMapping;
    input tuple<CacheMap, CacheMapMeta, Integer, list<tuple<Integer,Integer>>> iInfo; //<CacheMap,numNewCL, clCandidates <ClIdx,freeBytes>>
    output tuple<CacheMap, CacheMapMeta, Integer, list<tuple<Integer,Integer>>> oInfo;
  protected
    list<Integer> simCodeVars, writtenCL;
    CacheMap iCacheMap;
    CacheMapMeta iCacheMapMeta;
    Integer iNumNewCL;
    String varsString;
    list<tuple<Integer,Integer>> clCandidates;
  algorithm
    simCodeVars := arrayGet(iNodeSimCodeVarMapping, iNodeIdx);
    (iCacheMap,iCacheMapMeta,iNumNewCL,clCandidates) := iInfo;
    varsString := stringDelimitList(List.map(simCodeVars, intString), ",");
    //print("appendNodeVarsToCacheMap: Handling node " + intString(iNodeIdx) + " clCandidates: " + intString(listLength(clCandidates)) + " simCodeVars: " + varsString + "\n");
    ((iCacheMap, iCacheMapMeta, iNumNewCL,clCandidates,writtenCL,_)) := List.fold(simCodeVars, function appendSCVarToCacheMap(iOwnerThread=iOwnerThread), (iCacheMap, iCacheMapMeta, iNumNewCL,clCandidates,{},1));
    clCandidates := List.removeOnTrue(writtenCL, appendNodeVarsToCacheMap0, clCandidates);
    oInfo := (iCacheMap,iCacheMapMeta,iNumNewCL,clCandidates);
  end appendNodeVarsToCacheMap;

  protected function appendNodeVarsToCacheMap0 "author: marcusw
    Mark the cachelines with 'false' that are already full or part of the iWrittenCLs-list."
    input list<Integer> iWrittenCLs;
    input tuple<Integer,Integer> iDetailedCLInfo; //<ClIdx,freeBytes>
    output Boolean oRemove;
  protected
    Integer clIdx, freeBytes;
    Boolean res;
  algorithm
    oRemove := matchcontinue(iWrittenCLs, iDetailedCLInfo)
      case(_,(clIdx,freeBytes))
        equation //CacheLine is full
          true = intEq(freeBytes,0);
        then true;
      case(_,(clIdx,freeBytes))
        equation
          res = List.isMemberOnTrue(clIdx,iWrittenCLs, intEq);
        then res;
      else
        equation
          print("appendNodeVarsToCacheMap0 failed!\n");
        then fail();
    end matchcontinue;
  end appendNodeVarsToCacheMap0;

  protected function appendSCVarToCacheMap "author: marcusw
    Add the given sc-var to the cacheMap and update the information of cacheMapMeta. If the currentCLCandidate-index is not in range [1,len(cacheLineCandidates)], a new cacheline is added."
    input Integer iSCVarIdx;
    input Integer iOwnerThread;
    input tuple<CacheMap, CacheMapMeta, Integer, list<tuple<Integer,Integer>>, list<Integer>, Integer> iInfo; //<CacheMap, CacheMapMeta, numNewCL, cacheLineCandidates <ClIdx,freeBytes>, writtenCL, currentCLCandidate>
    output tuple<CacheMap, CacheMapMeta, Integer, list<tuple<Integer,Integer>>, list<Integer>, Integer> oInfo;
  protected
    array<Option<SimCodeVar.SimVar>> iAllSCVarsMapping;
    array<tuple<Integer,Integer>> iSimCodeVarTypes; //<type, numberOfBytesRequired>
    array<tuple<Integer,Integer>> iScVarCLMapping; //will be updated: mapping scVar (arrayIdx) -> <clIdx,varType>
    Integer currentCLCandidateIdx, currentCLCandidateCLIdx, clIdx, currentCLCandidateFreeBytes, cacheLineSize, numNewCL, varType, numBytesRequired, entryStart;
    tuple<Integer,Integer> currentCLCandidate;
    list<tuple<Integer,Integer>> cacheLineCandidates;
    list<CacheLineMap> cacheLinesFloat, cacheLinesInt, cacheLinesBool;
    list<SimCodeVar.SimVar> cacheVariables;
    CacheLineMap cacheLine;
    list<CacheLineEntry> CLentries;
    SimCodeVar.SimVar scVar;
    Integer numCacheVars, freeSpace, numBytesFree;
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    list<Integer> writtenCL;
    String varText;
    tuple<CacheMap, CacheMapMeta, Integer, list<tuple<Integer,Integer>>, list<Integer>, Integer> tmpInfo;
  algorithm
    oInfo := matchcontinue(iSCVarIdx, iOwnerThread, iInfo)
      case(_,_,(cacheMap as CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat, cacheLinesInt=cacheLinesInt, cacheLinesBool=cacheLinesBool), cacheMapMeta as CACHEMAPMETA(iAllSCVarsMapping, iSimCodeVarTypes, iScVarCLMapping), numNewCL, cacheLineCandidates, writtenCL, currentCLCandidateIdx))
        equation //case 1: current CL-candidate has enough space to store variable
          true = intGe(listLength(cacheLineCandidates), currentCLCandidateIdx);
          currentCLCandidate = listGet(cacheLineCandidates, currentCLCandidateIdx);
          ((varType,numBytesRequired)) = arrayGet(iSimCodeVarTypes,iSCVarIdx);
          true = doesSCVarFitIntoCL(currentCLCandidate, numBytesRequired);
          //print("  -- candidateCL has enough space\n");
          (currentCLCandidateCLIdx,currentCLCandidateFreeBytes) = currentCLCandidate;
          //print("appendSCVarToCacheMap scVarIdx: " + intString(iSCVarIdx) + "\n");
          //print("  -- CachelineCandidates: " + intString(listLength(cacheLineCandidates)) + " currentCLCandidateidx: " + intString(currentCLCandidateIdx) + " with " + intString(currentCLCandidateFreeBytes) + "free bytes\n");
          cacheLine = listGet(cacheLinesFloat, listLength(cacheLinesFloat) - currentCLCandidateCLIdx + 1);
          CACHELINEMAP(idx=clIdx,numBytesFree=numBytesFree,entries=CLentries) = cacheLine;
          //print("  -- writing to CL " + intString(clIdx) + " (free bytes: " + intString(currentCLCandidateFreeBytes) + ")\n");
          //write new cache lines
          entryStart = cacheLineSize-currentCLCandidateFreeBytes;
          numCacheVars = listLength(cacheVariables)+1;
          CLentries = CACHELINEENTRY(entryStart,varType, numBytesRequired, numCacheVars, iOwnerThread)::CLentries;
          cacheLine = CACHELINEMAP(clIdx,numBytesFree+numBytesRequired,CLentries);
          cacheLinesFloat = List.set(cacheLinesFloat, listLength(cacheLinesFloat) - currentCLCandidateCLIdx + 1, cacheLine);
          //update scVarCL-Mapping
          iScVarCLMapping = arrayUpdate(iScVarCLMapping,iSCVarIdx,(clIdx,varType));
          //append variable
          SOME(scVar) = arrayGet(iAllSCVarsMapping,iSCVarIdx);

          //varText = Tpl.textString(SimCodeDump.dumpVars(Tpl.emptyTxt, {scVar}, false));
          //print("  appendSCVarToCacheMap: Handling variable " + intString(iSCVarIdx) + " | " + varText + "\n");

          cacheVariables = scVar::cacheVariables;
          writtenCL = clIdx::writtenCL;
          //write candidate list
          currentCLCandidate = (currentCLCandidateCLIdx,currentCLCandidateFreeBytes-numBytesRequired);
          cacheLineCandidates = List.set(cacheLineCandidates, currentCLCandidateIdx, currentCLCandidate);
          cacheMap = CACHEMAP(cacheLineSize,cacheVariables,cacheLinesFloat, cacheLinesInt, cacheLinesBool);
          cacheMapMeta = CACHEMAPMETA(iAllSCVarsMapping, iSimCodeVarTypes, iScVarCLMapping);
          //printCacheMap(cacheMap);
          //print("  appendSCVarToCacheMap: Done\n");
        then ((cacheMap, cacheMapMeta, numNewCL, cacheLineCandidates, writtenCL, currentCLCandidateIdx));
      case(_,_,(cacheMap as CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat, cacheLinesInt=cacheLinesInt, cacheLinesBool=cacheLinesBool), cacheMapMeta as CACHEMAPMETA(iAllSCVarsMapping, iSimCodeVarTypes, iScVarCLMapping), numNewCL, cacheLineCandidates, writtenCL, currentCLCandidateIdx))
        equation //case 2: current CL-candidate has not enough space to store variable
          true = intGe(listLength(cacheLineCandidates), currentCLCandidateIdx);
          ((varType,numBytesRequired)) = arrayGet(iSimCodeVarTypes,iSCVarIdx);
          tmpInfo = appendSCVarToCacheMap(iSCVarIdx, iOwnerThread, (cacheMap, cacheMapMeta, numNewCL,cacheLineCandidates,writtenCL,currentCLCandidateIdx+1));
        then tmpInfo;
      case(_,_,(cacheMap as CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat, cacheLinesInt=cacheLinesInt, cacheLinesBool=cacheLinesBool), CACHEMAPMETA(iAllSCVarsMapping, iSimCodeVarTypes, iScVarCLMapping), numNewCL, cacheLineCandidates, writtenCL, currentCLCandidateIdx))
        equation //case 3: no CL-candidates available
          //print("--appendSCVarToCacheMap: Handling variable " + intString(iSCVarIdx) + "\n");

          ((varType,numBytesRequired)) = arrayGet(iSimCodeVarTypes,iSCVarIdx);
          entryStart = 0;
          numCacheVars = listLength(cacheVariables)+1;
          CLentries = {CACHELINEENTRY(entryStart,varType, numBytesRequired, numCacheVars, iOwnerThread)};
          clIdx = listLength(cacheLinesFloat) + 1;
          cacheLine = CACHELINEMAP(clIdx,numBytesRequired,CLentries);
          cacheLinesFloat = cacheLine::cacheLinesFloat;
          //update scVarCL-Mapping
          iScVarCLMapping = arrayUpdate(iScVarCLMapping,iSCVarIdx,(clIdx,varType));
          //append variable
          SOME(scVar) = arrayGet(iAllSCVarsMapping,iSCVarIdx);
          cacheVariables = scVar::cacheVariables;
          writtenCL = clIdx::writtenCL;
          freeSpace = cacheLineSize-numBytesRequired;
          //print("  -- writing new CL (idx: " + intString(clIdx) + "; freeSpace: " + intString(freeSpace) + ")\n");
          cacheLineCandidates = listAppend(cacheLineCandidates,{(clIdx,freeSpace)});
          cacheMap = CACHEMAP(cacheLineSize,cacheVariables,cacheLinesFloat, cacheLinesInt, cacheLinesBool);
          cacheMapMeta = CACHEMAPMETA(iAllSCVarsMapping, iSimCodeVarTypes, iScVarCLMapping);
          //printCacheMap(cacheMap);
        then ((cacheMap, cacheMapMeta, numNewCL+1, cacheLineCandidates, writtenCL, currentCLCandidateIdx));
      else
        equation
          print("appendSCVarToCacheMap failed! Variable skipped.\n");
        then iInfo;
    end matchcontinue;
  end appendSCVarToCacheMap;

  protected function doesSCVarFitIntoCL "author: marcusw
    Check that at least the iNumBytes are free in the given cacheline candidate."
    input tuple<Integer,Integer> iCacheLineCandidate;
    input Integer iNumBytes;
    output Boolean oResult;
  protected
    Integer freeSpace;
  algorithm
    (_,freeSpace) := iCacheLineCandidate;
    oResult := intGe(freeSpace, iNumBytes);
  end doesSCVarFitIntoCL;

  protected function createDetailedCacheMapInformations "author: marcusw
    This method will create more detailed informations about the given cachelines. It will return a list
    of tuples, containing the cacheLineIndex and the number of bytes that are free in the cache line."
    input list<Integer> iCacheLinesIdc; //cache line indices
    input list<CacheLineMap> iCacheLines; //input cache lines
    input Integer iCacheLineSize;
    output list<tuple<Integer,Integer>> oCacheLines; //list of cache lines <CLIdx,NumBytesFree>
  protected
    array<CacheLineMap> iCacheLinesArray;
  algorithm
    iCacheLinesArray := listArray(iCacheLines);
    oCacheLines := List.fold2(iCacheLinesIdc, createDetailedCacheMapInformations0, iCacheLinesArray, iCacheLineSize, {});
  end createDetailedCacheMapInformations;

  protected function createDetailedCacheMapInformations0 "author: marcusw
    Append more detailed informations about the cacheline with index 'iCacheLineIdx' to the iCacheLines-list."
    input Integer iCacheLineIdx;
    input array<CacheLineMap> iCacheLinesArray;
    input Integer iCacheLineSize;
    input list<tuple<Integer,Integer>> iCacheLines; //list of cache lines <CLIdx,NumBytesFree>
    output list<tuple<Integer,Integer>> oCacheLines;
  protected
    CacheLineMap cacheLineEntry;
    Integer numBytesFree;
    list<tuple<Integer,Integer>> cacheLines;
  algorithm
    oCacheLines := matchcontinue(iCacheLineIdx, iCacheLinesArray, iCacheLineSize, iCacheLines)
      case(_,_,_,_)
        equation
          //print("createDetailedCacheMapInformations0: CacheLineIdx: " + intString(iCacheLineIdx) + "\n");
          cacheLineEntry = arrayGet(iCacheLinesArray, arrayLength(iCacheLinesArray) - iCacheLineIdx + 1);
          numBytesFree = iCacheLineSize-getNumOfUsedBytesByCacheLine(cacheLineEntry);
          //print("\tNumber of free bytes: " + intString(numBytesFree) + "\n");
          true = intGt(numBytesFree,0);
          cacheLines = (iCacheLineIdx,numBytesFree)::iCacheLines;
        then cacheLines;
      else iCacheLines;
    end matchcontinue;
  end createDetailedCacheMapInformations0;

  protected function getNumOfUsedBytesByCacheLine "author: marcusw
    Get the number of bytes that are already blocked in the cacheline."
    input CacheLineMap iCacheLineMap;
    output Integer oNumBytes;
  protected
    list<CacheLineEntry> entries;
    Integer firstEntryStart, firstEntrySize;
  algorithm
    CACHELINEMAP(entries=entries) := iCacheLineMap;
    entries := List.sort(entries, sortCacheLineEntriesByPos);
    //print("getNumOfUsedBytesByCacheLine:\n");
    //printCacheLineMapClean(iCacheLineMap);
    CACHELINEENTRY(start=firstEntryStart,size=firstEntrySize) := List.last(entries);
    oNumBytes := firstEntryStart + firstEntrySize;
  end getNumOfUsedBytesByCacheLine;

  protected function sortCacheLineEntriesByPos "author: marcusw
    Helper function to sort various cachelines by their memory position."
    input CacheLineEntry iCacheLineEntry1;
    input CacheLineEntry iCacheLineEntry2;
    output Boolean oIsGreater;
  protected
    Integer start1, start2;
  algorithm
    CACHELINEENTRY(start=start1) := iCacheLineEntry1;
    CACHELINEENTRY(start=start2) := iCacheLineEntry2;
    oIsGreater := intGt(start1,start2);
  end sortCacheLineEntriesByPos;

  protected function reverseCacheLineMapEntries "author: marcusw
    Reverse the entry-list of the given cacheline-map."
    input CacheLineMap iCacheLineMap;
    output CacheLineMap oCacheLineMap;
  protected
    Integer idx,numBytesFree;
    list<CacheLineEntry> entries;
  algorithm
    CACHELINEMAP(idx=idx,numBytesFree=numBytesFree,entries=entries) := iCacheLineMap;
    entries := listReverse(entries);
    oCacheLineMap := CACHELINEMAP(idx,numBytesFree,entries);
  end reverseCacheLineMapEntries;

  protected function compareCacheLineMapByIdx "author: marcusw
    Reverse the entry-list of the given cacheline-map."
    input CacheLineMap iCacheLineMap;
    input CacheLineMap iCacheLineMap2;
    output Boolean oIsGreater;
  protected
    Integer idx1, idx2;
  algorithm
    CACHELINEMAP(idx=idx1) := iCacheLineMap;
    CACHELINEMAP(idx=idx2) := iCacheLineMap2;
    oIsGreater := intGt(idx1, idx2);
  end compareCacheLineMapByIdx;

  protected function convertCacheMapToMemoryMap "author: marcusw
    Convert the informations of the given cache-map to a memory-map that can be used by susan."
    input CacheMap iCacheMap;
    input tuple<Integer,Integer,Integer> iVarSizes; //size of float, int and bool variables (in bytes)
    input HashTableCrILst.HashTable iScVarNameIdxMapping;
    input list<SimCodeVar.SimVar> iNotOptimizedVars;
    output HpcOmSimCode.MemoryMap oMemoryMap;
  protected
    Integer cacheLineSize, highestIdx, floatArraySize, intArraySize, boolArraySize;
    list<SimCodeVar.SimVar> cacheVariables;
    array<SimCodeVar.SimVar> cacheVariablesArray;
    list<CacheLineMap> cacheLinesFloat, cacheLinesInt, cacheLinesBool, allCacheLines;
    HpcOmSimCode.MemoryMap tmpMemoryMap;
    array<tuple<Integer,Integer>> positionMappingArray;
    Integer varSizeFloat, varSizeInt, varSizeBool;
    list<tuple<Integer, Integer, Integer>> positionMappingList; //<scVarIdx, arrayPosition, arrayIdx>
    array<Integer> varIdxOffsets;
  algorithm
    oMemoryMap := match(iCacheMap, iVarSizes, iScVarNameIdxMapping, iNotOptimizedVars)
      case(CACHEMAP(cacheLineSize=cacheLineSize, cacheVariables=cacheVariables, cacheLinesFloat=cacheLinesFloat, cacheLinesInt=cacheLinesInt, cacheLinesBool=cacheLinesBool), (varSizeFloat, varSizeInt, varSizeBool), _, _)
        equation
          cacheVariablesArray = listArray(cacheVariables);
          varIdxOffsets = arrayCreate(3,0);
          allCacheLines = List.sort(getAllCacheLinesOfCacheMap(iCacheMap), compareCacheLineMapByIdx);
          ((positionMappingList,highestIdx)) = List.fold(allCacheLines, function convertCacheMapToMemoryMap1(iScVarNameIdxMapping=iScVarNameIdxMapping, iCacheLineSize=cacheLineSize, iVarIdxOffsets=varIdxOffsets, iCacheVariables=cacheVariablesArray), ({},-1));
          //((positionMappingList,highestIdx)) = List.fold(cacheLinesInt, function convertCacheMapToMemoryMap1(iScVarNameIdxMapping=iScVarNameIdxMapping, iArrayIdx=VARTYPE_FLOAT, iCacheLineSize=cacheLineSize, iVarIdxOffsets=varIdxOffsets, iCacheVariables=cacheVariables), (positionMappingList,highestIdx));
          //((positionMappingList,highestIdx)) = List.fold(cacheLinesBool,function convertCacheMapToMemoryMap1(iScVarNameIdxMapping=iScVarNameIdxMapping, iArrayIdx=VARTYPE_FLOAT, iCacheLineSize=cacheLineSize, iVarIdxOffsets=varIdxOffsets, iCacheVariables=cacheVariables), (positionMappingList,highestIdx));
          positionMappingArray = arrayCreate(intMax(0, highestIdx),(-1,-1));

          List.map1_0(positionMappingList, convertCacheMapToMemoryMap3, positionMappingArray);
          floatArraySize = listLength(cacheLinesFloat)*intDiv(cacheLineSize, varSizeFloat);
          intArraySize = listLength(cacheLinesInt)*intDiv(cacheLineSize, varSizeInt);
          boolArraySize = listLength(cacheLinesBool)*intDiv(cacheLineSize, varSizeBool);
          tmpMemoryMap = HpcOmSimCode.MEMORYMAP_ARRAY(positionMappingArray, floatArraySize, intArraySize, boolArraySize, iScVarNameIdxMapping, {});
        then tmpMemoryMap;
      case(UNIFORM_CACHEMAP(),_,_,_)
        then HpcOmSimCode.MEMORYMAP_UNIFORM();
      else
        equation
          print("convertCacheMapToMemoryMap: CacheMap-Type not supported!\n");
        then fail();
     end match;
  end convertCacheMapToMemoryMap;

  protected function convertCacheMapToMemoryMap1 "author: marcusw
    Append the informations of the given cachline-map to the position-mapping-structure."
    input CacheLineMap iCacheLineMap;
    input HashTableCrILst.HashTable iScVarNameIdxMapping;
    input Integer iCacheLineSize;
    input array<Integer> iVarIdxOffsets; //an offset that is substracted from the arrayPosition (for float, int and bool variables -> taken from iArrayIdx)
    input array<SimCodeVar.SimVar> iCacheVariables;
    input tuple<list<tuple<Integer, Integer, Integer>>, Integer> iPositionMappingListIdx; //<<scVarIdx, arrayPosition, arrayIdx>, highestIdx>
    output tuple<list<tuple<Integer, Integer, Integer>>, Integer> oPositionMappingListIdx; //<<scVarIdx, arrayPosition, arrayIdx>, highestIdx>
  protected
    Integer idx, highestIdx, arrayIdx; //the arrayIdx is derived from the variable type of the first cacheline entry
    list<CacheLineEntry> entries;
    CacheLineEntry head;
    Integer dataType, size;
    list<tuple<Integer, Integer, Integer>> iPositionMappingList;
  algorithm
    oPositionMappingListIdx := match(iCacheLineMap, iScVarNameIdxMapping, iCacheLineSize, iVarIdxOffsets, iCacheVariables, iPositionMappingListIdx)
       case(CACHELINEMAP(idx=idx,entries=entries),_,_,_,_,(iPositionMappingList, highestIdx))
        equation
          CACHELINEENTRY(dataType=dataType, size=size)::_ = entries;
          ((iPositionMappingList,highestIdx)) = List.fold(entries, function convertCacheMapToMemoryMap2(iScVarNameIdxMapping=iScVarNameIdxMapping, iArrayIdx=dataType, iClIdxSize=(idx, iCacheLineSize), iVarIdxOffsets=iVarIdxOffsets, iCacheVariables=iCacheVariables), iPositionMappingListIdx);
          _ = convertCacheMapToMemoryMap2Helper(iVarIdxOffsets, 1, dataType);
        then ((iPositionMappingList,highestIdx));
       else
        equation
          print("convertCacheMapToMemoryMap1: CacheLineMap-Type not supported!\n");
        then fail();
     end match;
  end convertCacheMapToMemoryMap1;

  protected function convertCacheMapToMemoryMap2 "author: marcusw
    Append the informations of the given cachline-entry to the position-mapping-structure."
    input CacheLineEntry iCacheLineEntry;
    input HashTableCrILst.HashTable iScVarNameIdxMapping;
    input Integer iArrayIdx;
    input tuple<Integer,Integer> iClIdxSize; //<CLIdx, CLSize>>
    input array<Integer> iVarIdxOffsets; //an offset that is substracted from the arrayPosition (for float, int and bool variables -> taken from iArrayIdx)
    input array<SimCodeVar.SimVar> iCacheVariables;
    input tuple<list<tuple<Integer, Integer, Integer>>, Integer> iPositionMappingListIdx; //<<scVarIdx, arrayPosition, arrayIdx>, highestIdx>
    output tuple<list<tuple<Integer, Integer, Integer>>, Integer> oPositionMappingListIdx; //<<scVarIdx, arrayPosition, arrayIdx>, highestIdx>
  protected
    Integer clIdx, clSize;
    list<Integer> realSimVarIdxLst;
    list<tuple<Integer, Integer, Integer>> iPositionMappingList;
    Integer scVarIdx, realScVarIdx, start, size, arrayPosition, highestIdx, offset, arridx;
    DAE.ComponentRef name;
  algorithm
    oPositionMappingListIdx := match(iCacheLineEntry, iScVarNameIdxMapping, iArrayIdx, iClIdxSize, iVarIdxOffsets, iCacheVariables, iPositionMappingListIdx)
      case(CACHELINEENTRY(scVarIdx=scVarIdx, start=start, size=size),_,_,(clIdx, clSize),_,_,(iPositionMappingList,highestIdx))
        equation
          offset = arrayGet(iVarIdxOffsets, iArrayIdx);
          arrayPosition = intDiv(start, size) + (clIdx - offset - 1)*intDiv(clSize, size);
          SimCodeVar.SIMVAR(name=name) = arrayGet(iCacheVariables, arrayLength(iCacheVariables) - scVarIdx + 1);
          realSimVarIdxLst = BaseHashTable.get(name, iScVarNameIdxMapping);
          realScVarIdx = listGet(realSimVarIdxLst, 1) + listGet(realSimVarIdxLst, 2);
          iPositionMappingList = (realScVarIdx,arrayPosition,iArrayIdx)::iPositionMappingList;
          highestIdx = intMax(highestIdx, realScVarIdx);
          //for arridx in listRange(arrayLength(iVarIdxOffsets)) loop
          //  _ = arrayUpdate(iVarIdxOffset, intDiv(clSize, size));
          //end for;
          //print("convertCacheMapToMemoryMap2: " + ComponentReference.debugPrintComponentRefTypeStr(name) + " [" + intString(arrayPosition) + "] with array-pos: " + intString(arrayPosition) + " | array-index: " + intString(iArrayIdx) + " | start: " + intString(start) + "\n");
        then ((iPositionMappingList,highestIdx));
      else
        equation
          print("convertCacheMapToMemoryMap2 failed! Unsupported entry-type\n");
        then fail();
    end match;
  end convertCacheMapToMemoryMap2;

  protected function convertCacheMapToMemoryMap2Helper "author: marcusw
    Add the given offset to all array-positions with a index != iIndex."
    input array<Integer> iArray;
    input Integer iOffset;
    input Integer iIndex;
    output array<Integer> oArray;
  protected
    array<Integer> tmpArray;
    Integer i;
  algorithm
    tmpArray := iArray;
    for i in List.intRange(arrayLength(tmpArray)) loop
      if(intNe(i, iIndex)) then
        tmpArray := arrayUpdate(tmpArray, i, arrayGet(tmpArray, i) + iOffset);
      end if;
    end for;
    oArray := tmpArray;
  end convertCacheMapToMemoryMap2Helper;

  protected function convertCacheMapToMemoryMap3 "author: marcusw
    Transfer the informations of the positionMappingEntry into the position mapping array."
    input tuple<Integer, Integer, Integer> positionMappingEntry; //<scVarIdx, arrayPosition, arrayIdx>
    input array<tuple<Integer,Integer>> iPositionMappingArray;
  protected
    Integer scVarIdx, arrayPos, arrayIdx;
  algorithm
    (scVarIdx,arrayPos,arrayIdx) := positionMappingEntry;
    _ := arrayUpdate(iPositionMappingArray, scVarIdx, (arrayPos,arrayIdx));
  end convertCacheMapToMemoryMap3;


  protected function getNotOptimizedVarsByCacheLineMapping "author: marcusw
    Get all sim code variables that have no valid cl-mapping."
    input array<tuple<Integer,Integer>> iScVarCLMapping;
    input array<Option<SimCodeVar.SimVar>> iAllVarsMapping;
    output list<SimCodeVar.SimVar> oNotOptimizedVars;
  algorithm
    ((oNotOptimizedVars,_)) := Array.fold1(iScVarCLMapping, getNotOptimizedVarsByCacheLineMapping0, iAllVarsMapping, ({},1));
  end getNotOptimizedVarsByCacheLineMapping;

  protected function getNotOptimizedVarsByCacheLineMapping0 "author: marcusw
    Add the sc-variable to the output list if it has no valid mapping."
    input tuple<Integer,Integer> iScVarCLMapping;
    input array<Option<SimCodeVar.SimVar>> iAllVarsMapping;
    input tuple<list<SimCodeVar.SimVar>, Integer> iEntries; //<input-list,scVarindex>
    output tuple<list<SimCodeVar.SimVar>, Integer> oEntries; //<input-list,scVarindex>
  protected
    SimCodeVar.SimVar var;
    list<SimCodeVar.SimVar> tmpSimVars;
    Integer scVarIdx;
  algorithm
    oEntries := matchcontinue(iScVarCLMapping, iAllVarsMapping, iEntries)
      case((-1,_),_,(tmpSimVars, scVarIdx))
        equation
          SOME(var) = arrayGet(iAllVarsMapping, scVarIdx);
          tmpSimVars = var::tmpSimVars;
        then ((tmpSimVars, scVarIdx+1));
      case(_,_,(tmpSimVars, scVarIdx))
        then ((tmpSimVars, scVarIdx+1));
    end matchcontinue;
  end getNotOptimizedVarsByCacheLineMapping0;

  // -------------------------------------------
  // ANALYSIS
  // -------------------------------------------

  protected function evaluateCacheBehaviour
    input CacheMap iCacheMap;
    input HpcOmTaskGraph.TaskGraph iTaskGraphT;
    input array<list<Integer>> iNodeSimCodeVarMapping;
    input array<tuple<Integer,Integer>> iScVarCLMapping;
    input Integer iNumberOfThreads;
    input Integer iNumberOfCLs;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
  protected
    array<array<Real>> cacheLineThreadProperties;
    Integer clIdx;
    CacheLineMap cacheLine;
    Integer cacheLineSize;
    list<CacheLineMap> cacheLines;
    Real locCoWrite, locCoRead, locCo;
  algorithm
    cacheLineSize := getCacheLineSizeOfCacheMap(iCacheMap);
    cacheLines := getAllCacheLinesOfCacheMap(iCacheMap);
    cacheLineThreadProperties := arrayCreate(iNumberOfCLs, arrayCreate(iNumberOfThreads, 0.0));
    for cacheLine in cacheLines loop
      createCacheLineThreadProperties(cacheLine, iNumberOfThreads, cacheLineSize, cacheLineThreadProperties);
    end for;
    locCoWrite := calculateLocCoWrite(iNodeSimCodeVarMapping, iScVarCLMapping, cacheLineThreadProperties, iSchedulerInfo);
    locCoRead := calculateLocCoRead(iTaskGraphT, iNodeSimCodeVarMapping, iScVarCLMapping, cacheLineThreadProperties, iSchedulerInfo);
    locCo := locCoWrite * 0.6 + locCoRead * 0.4;
    print("LocCo-Write for Graph is " + realString(locCoWrite) + "\n");
    print("LocCo-Read for Graph is " + realString(locCoRead) + "\n");
    print("LocCo for Graph is " + realString(locCo) + "\n");
  end evaluateCacheBehaviour;

  protected function createCacheLineThreadProperties
    input CacheLineMap iCacheLine;
    input Integer iNumberOfThreads;
    input Integer iCacheLineSize;
    input array<array<Real>> iCacheLineThreadProperties; //updated
  protected
    array<Integer> bytesPerThread;
    array<Real> threadProperties;
    Integer cacheLineIdx, threadOwner, size, threadIdx, numBytesFree, numBytesUnassigned;
    list<CacheLineEntry> entries;
    CacheLineEntry entry;
    Real sizeReal;
  algorithm
    CACHELINEMAP(idx=cacheLineIdx,entries=entries,numBytesFree=numBytesFree) := iCacheLine;
    numBytesUnassigned := 0;
    //print("createCacheLineThreadProperties: Handling CL " + intString(cacheLineIdx) + "\n");
    threadProperties := arrayCreate(iNumberOfThreads, 0.0);
    bytesPerThread := arrayCreate(iNumberOfThreads, 0);
    for entry in entries loop
      CACHELINEENTRY(threadOwner=threadOwner,size=size) := entry;
      if(intLt(threadOwner, 0)) then
        numBytesUnassigned := numBytesUnassigned + size;
      else
        bytesPerThread := arrayUpdate(bytesPerThread, threadOwner, arrayGet(bytesPerThread, threadOwner) + size);
      end if;
    end for;
    sizeReal := intReal(iCacheLineSize - numBytesFree - numBytesUnassigned);
    if(realGt(sizeReal, 0)) then
      for threadIdx in 1:iNumberOfThreads loop
        //print("createCacheLineThreadProperties: Thread " + intString(threadIdx) + " has " + intString(arrayGet(bytesPerThread, threadIdx)) + " bytes \n");
        //print("createCacheLineThreadProperties: ThreadProperties-length=" + intString(arrayLength(threadProperties)) + " index=" + intString(threadIdx) + "\n");
        arrayUpdate(threadProperties, threadIdx, realDiv(intReal(arrayGet(bytesPerThread, threadIdx)),sizeReal));
      end for;
    end if;
    //print("createCacheLineThreadProperties: iCacheLineThreadProperties-length=" + intString(arrayLength(iCacheLineThreadProperties)) + " index=" + intString(cacheLineIdx) + "\n");
    arrayUpdate(iCacheLineThreadProperties, cacheLineIdx, threadProperties);
  end createCacheLineThreadProperties;

  protected function calculateLocCoRead
    input HpcOmTaskGraph.TaskGraph iTaskGraphT;
    input array<list<Integer>> iNodeSimCodeVarMapping;
    input array<tuple<Integer,Integer>> iScVarCLMapping;
    input array<array<Real>> cacheLineThreadProperties;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    output Real oLocCoRead;
  protected
    Integer nodeIdx, numberOfNodes, threadIdx;
    Real sum, locCoRead;
  algorithm
    numberOfNodes := arrayLength(iNodeSimCodeVarMapping);
    sum := 0.0;
    for nodeIdx in 1:numberOfNodes loop
      threadIdx := Util.tuple31(arrayGet(iSchedulerInfo, nodeIdx));
      locCoRead := calculateLocCoReadForTask(nodeIdx, threadIdx, iTaskGraphT, iNodeSimCodeVarMapping, iScVarCLMapping, cacheLineThreadProperties);
      sum := sum + locCoRead;
      //print("LocCo-Read for Calc-Task " + intString(nodeIdx) + " handled by thread " + intString(threadIdx) + " is " + realString(locCoRead) + "\n");
    end for;
    if(intGt(numberOfNodes, 0)) then
      oLocCoRead := realDiv(sum, numberOfNodes);
    else
      oLocCoRead := 1.0;
    end if;
  end calculateLocCoRead;

  protected function calculateLocCoReadForTask
    input Integer iNodeIdx;
    input Integer iThreadIdx;
    input HpcOmTaskGraph.TaskGraph iTaskGraphT;
    input array<list<Integer>> iNodeSimCodeVarMapping;
    input array<tuple<Integer,Integer>> iScVarCLMapping;
    input array<array<Real>> iCacheLineThreadProperties;
    output Real oLocCoRead;
  protected
    Integer predecessor, threadIdx, numberOfPredecessors;
    list<Integer> predecessors;
    Real sum;
  algorithm
    sum := 0.0;
    predecessors := arrayGet(iTaskGraphT, iNodeIdx);
    numberOfPredecessors := listLength(predecessors);
    for predecessor in predecessors loop
      sum := sum + calculateLocCoForTask(predecessor, iThreadIdx, arrayGet(iNodeSimCodeVarMapping, predecessor), iScVarCLMapping, iCacheLineThreadProperties);
    end for;
    if(intGt(numberOfPredecessors, 0)) then
      oLocCoRead := realDiv(sum, numberOfPredecessors);
    else
      oLocCoRead := 1.0;
    end if;
  end calculateLocCoReadForTask;

  protected function calculateLocCoWrite
    input array<list<Integer>> iNodeSimCodeVarMapping;
    input array<tuple<Integer,Integer>> iScVarCLMapping;
    input array<array<Real>> cacheLineThreadProperties;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    output Real oLocCoWrite;
  protected
    Integer nodeIdx, numberOfNodes, threadIdx;
    Real sum, locCoWrite;
  algorithm
    numberOfNodes := arrayLength(iNodeSimCodeVarMapping);
    sum := 0.0;
    for nodeIdx in 1:numberOfNodes loop
      threadIdx := Util.tuple31(arrayGet(iSchedulerInfo, nodeIdx));
      //print("calculateLocCoWrite: nodeIdx='" + intString(nodeIdx) + "' threadIdx='" + intString(threadIdx) + "'\n");
      locCoWrite := calculateLocCoForTask(nodeIdx, threadIdx, arrayGet(iNodeSimCodeVarMapping, nodeIdx), iScVarCLMapping, cacheLineThreadProperties);
      sum := sum + locCoWrite;
      //print("LocCo-Write for Calc-Task " + intString(nodeIdx) + " handled by thread " + intString(threadIdx) + " is " + realString(locCoWrite) + "\n");
    end for;
    if(intGt(numberOfNodes, 0)) then
      oLocCoWrite := realDiv(sum, numberOfNodes);
    else
      oLocCoWrite := 1.0;
    end if;
  end calculateLocCoWrite;

  protected function calculateLocCoForTask
    input Integer iTaskIdx;
    input Integer iThreadIdx;
    input list<Integer> iNodeSimCodeVarMapping;
    input array<tuple<Integer,Integer>> iScVarCLMapping;
    input array<array<Real>> iCacheLineThreadProperties;
    output Real oLocCo;
  protected
    Integer simCodeVar, index, clIdx;
    Real sum;
  algorithm
    sum := 0.0;
    for simCodeVar in iNodeSimCodeVarMapping loop
      //print("calculateLocCoForTask: handling simCodeVar" + intString(simCodeVar) + "\n");
      clIdx := Util.tuple21(arrayGet(iScVarCLMapping, simCodeVar));
      //print("calculateLocCoForTask: clIdx=" + intString(clIdx) + "\n");
      sum := sum + arrayGet(arrayGet(iCacheLineThreadProperties,clIdx), iThreadIdx);
    end for;
    oLocCo := realDiv(sum, intReal(listLength(iNodeSimCodeVarMapping)));
  end calculateLocCoForTask;

  // -------------------------------------------
  // MAPPINGS
  // -------------------------------------------

  protected function fillSimVarHashTable "author: marcusw
    Function to create a mapping for each simVar-name to the simVar-Index+Offset."
    input list<SimCodeVar.SimVar> iSimVars;
    input Integer iOffset;
    input Integer iType; //1 = real; 2 = int; 3 = bool
    input HashTableCrILst.HashTable iHt; //contains a list of type Integer for each simVar. List.First: Index, List.Secons: Offset, List.Third: Type
    output HashTableCrILst.HashTable oHt;
  protected
    HashTableCrILst.HashTable tmpHashTable;
    SimCodeVar.SimVar simVar;
    Integer index;
    DAE.ComponentRef name;
  algorithm
    tmpHashTable := iHt;
    for simVar in iSimVars loop
      SimCodeVar.SIMVAR(name=name,index=index) := simVar;
      index := index + 1;
      //print("fillSimVarHashTableTraverse: " + ComponentReference.debugPrintComponentRefTypeStr(name) + " with index: " + intString(index+ iOffset) + "\n");
      tmpHashTable := BaseHashTable.add((name,{index,iOffset,iType}),tmpHashTable);
    end for;
    oHt := tmpHashTable;
  end fillSimVarHashTable;

  protected function transposeScVarTaskMapping
    input array<Integer> iScVarTaskMapping;
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    output array<list<Integer>> oNodeSimCodeVarMapping;
  protected
    array<list<Integer>> tmpNodeSimCodeVarMapping;
    Integer scVarIdx, taskIdx;
    list<Integer> oldList;
  algorithm
    tmpNodeSimCodeVarMapping := arrayCreate(arrayLength(iTaskGraph), {});
    for scVarIdx in 1:arrayLength(iScVarTaskMapping) loop
      taskIdx := arrayGet(iScVarTaskMapping, scVarIdx);
      //print("Handling sc-var with index: " + intString(scVarIdx) + "\n");
      if(intGt(taskIdx, 0)) then
        //print("Has task index " + intString(taskIdx) + "\n");
        oldList := arrayGet(tmpNodeSimCodeVarMapping, taskIdx);
        oldList := scVarIdx::oldList;
        _ := arrayUpdate(tmpNodeSimCodeVarMapping, taskIdx, oldList);
      end if;
    end for;
    oNodeSimCodeVarMapping := tmpNodeSimCodeVarMapping;
  end transposeScVarTaskMapping;

  protected function getEqSCVarMapping "author: marcusw
    Create a mapping for all eqSystems to the solved equations to a list of variables that are part of the equation."
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

  protected function getEqSCVarMapping0 "author: marcusw
    Create a list of simcode-variables that are part of the given equation."
    input BackendDAE.Equation iEquation;
    input HashTableCrILst.HashTable iHt; //Mapping varName -> varIdx
    output list<Integer> oMapping;
  protected
    list<Integer> varIdcList;
  algorithm
    //print("getEqSCVarMapping0: Handling equation:\n" + BackendDump.equationString(iEquation) + "\n");
    (_,(_,(_,oMapping))) := BackendEquation.traverseExpsOfEquation(iEquation,Expression.traverseSubexpressionsHelper, (createMemoryMapTraverse0, (iHt,{})));
    //((_,(_,oMapping))) := Expression.traverseExp(exp,createMemoryMapTraverse, (iHt,{}));
  end getEqSCVarMapping0;

  protected function createMemoryMapTraverse0 "author: marcusw
    Extend the variable list if the given expression is a cref."
    input DAE.Exp inExp;
    input tuple<HashTableCrILst.HashTable, list<Integer>> inTpl; // <expression, <hashTable, variableList>>
    output DAE.Exp outExp;
    output tuple<HashTableCrILst.HashTable, list<Integer>> oTpl;
  protected
    list<Integer> iVarList, oVarList, varInfo;
    Integer varIdx;
    HashTableCrILst.HashTable iHashTable;
    DAE.Exp iExp;
    DAE.ComponentRef componentRef;
  algorithm
    (outExp,oTpl) := matchcontinue(inExp,inTpl)
      case(iExp as DAE.CREF(componentRef=componentRef), (iHashTable,iVarList))
        equation
          //print("HpcOmSimCode.createMemoryMapTraverse: try to find componentRef\n");
          varInfo = BaseHashTable.get(componentRef, iHashTable);
          varIdx = List.first(varInfo) + List.second(varInfo);
          //print("createMemoryMapTraverse0 " + intString(varIdx) + "\n");
          //print("HpcOmSimCode.createMemoryMapTraverse: Found ref " + ComponentReference.printComponentRefStr(componentRef) + " with Index: " + intString(varIdx) + "\n");
          //ExpressionDump.dumpExp(iExp);
          oVarList = varIdx :: iVarList;
        then (iExp,(iHashTable,oVarList));
      else (inExp,inTpl);
    end matchcontinue;
  end createMemoryMapTraverse0;

  protected function getSimCodeVarNodeMapping "author: marcusw
    Create a mapping for all simcode-variables to the task that calculates it."
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input BackendDAE.EqSystems iEqSystems;
    input Integer iNumScVars;
    input array<Integer> iCompNodeMapping;
    input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
    output array<Integer> oScVarTaskMapping; //mapping scVarIdx (arrayIdx) to the taskIdx
  protected
    array<tuple<Integer,Integer,Integer>> varCompMapping;
    array<Integer> scVarTaskMapping;
  algorithm
    scVarTaskMapping := arrayCreate(iNumScVars,-1);
    HpcOmTaskGraph.TASKGRAPHMETA(varCompMapping=varCompMapping) := iTaskGraphMeta;
    //iterate over all variables
    ((oScVarTaskMapping,_)) := Array.fold3(varCompMapping, getSimCodeVarNodeMapping0, iEqSystems, iVarNameSCVarIdxMapping, iCompNodeMapping, (scVarTaskMapping,1));
  end getSimCodeVarNodeMapping;

  protected function getSimCodeVarNodeMapping0 "author: marcusw
    Add the given mapping between varIdx and nodeIdx to the mapping-array."
    input tuple<Integer,Integer,Integer> iCompIdx; //<compIdx,eqSysIdx,varOffset>
    input BackendDAE.EqSystems iEqSystems;
    input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
    input array<Integer> iCompNodeMapping;
    input tuple<array<Integer>, Integer> iScVarTaskMappingVarIdx; //<mapping scVarIdx -> task, varIdx>
    output tuple<array<Integer>, Integer> oScVarTaskMappingVarIdx;
  protected
    array<Integer> iScVarTaskMapping;
    Integer varIdx,eqSysIdx,varOffset,scVarIdx, compIdx, nodeIdx, scVarOffset;
    BackendDAE.EqSystem eqSystem;
    BackendDAE.Variables orderedVars;
    BackendDAE.VariableArray varArr;
    array<Option<BackendDAE.Var>> varOptArr;
    BackendDAE.Var var;
    DAE.ComponentRef varName;
    list<Integer> scVarValues;
    String varNameString;
  algorithm
    oScVarTaskMappingVarIdx := matchcontinue(iCompIdx,iEqSystems,iVarNameSCVarIdxMapping,iCompNodeMapping,iScVarTaskMappingVarIdx)
      case((compIdx,eqSysIdx,varOffset),_,_,_,(iScVarTaskMapping,varIdx))
        equation
          true = intGt(compIdx,0);
          eqSystem = listGet(iEqSystems,eqSysIdx);
          BackendDAE.EQSYSTEM(orderedVars=orderedVars) = eqSystem;
          var = BackendVariable.getVarAt(orderedVars, varIdx - varOffset);
          BackendDAE.VAR(varName=varName) = var;
          varName = getModifiedVarName(var);
          scVarValues = BaseHashTable.get(varName,iVarNameSCVarIdxMapping);
          varNameString = ComponentReference.printComponentRefStr(varName);
          //print("getSimCodeVarNodeMapping0: SCC-Idx: " + intString(compIdx) + " name: " + varNameString + "\n");
          scVarIdx = List.first(scVarValues);
          scVarOffset = List.second(scVarValues);
          scVarIdx = scVarIdx + scVarOffset;
          nodeIdx = arrayGet(iCompNodeMapping, compIdx);
          //oldVal = arrayGet(iClTaskMapping,clIdx);
          //print("getCacheLineTaskMadumpComponentReferencepping0 scVarIdx: " + intString(scVarIdx) + "\n");
          iScVarTaskMapping = arrayUpdate(iScVarTaskMapping,scVarIdx,nodeIdx);
          //print("Variable " + intString(varIdx) + " (" + ComponentReference.printComponentRefStr(varName) + ") [SC-Var " + intString(scVarIdx) + "]: Node " + intString(nodeIdx) + "\n---------------------\n");
          //print("Part of CL " + intString(clIdx) + " solved by node " + intString(nodeIdx) + "\n\n");
        then ((iScVarTaskMapping,varIdx+1));
      case(_,_,_,_,(iScVarTaskMapping,varIdx))
        then ((iScVarTaskMapping,varIdx+1));
    end matchcontinue;
  end getSimCodeVarNodeMapping0;

  protected function getModifiedVarName "author: marcusw
    Get the correct varName (if the variable is derived, the $DER-Prefix is added."
    input BackendDAE.Var iVar;
    output DAE.ComponentRef oVarName;
  protected
    DAE.ComponentRef iVarName, tmpVarName;
    BackendDAE.VarKind varKind;
  algorithm
    oVarName := match(iVar)
      case(BackendDAE.VAR(varName=iVarName, varKind=BackendDAE.STATE(index=1)))
        equation
          tmpVarName = DAE.CREF_QUAL(DAE.derivativeNamePrefix,DAE.T_REAL({},{}),{},iVarName);
        then tmpVarName;
      case(BackendDAE.VAR(varName=iVarName,varKind=varKind))
        equation
          //BackendDump.dumpKind(varKind);
          tmpVarName = iVarName;
        then tmpVarName;
    end match;
  end getModifiedVarName;

  protected function getCacheLineTaskMapping "author: marcusw
    This method will create an array, which contains all tasks that are writing to the cacheline (arrayIndex)."
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input BackendDAE.EqSystems iEqSystems;
    input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
    input Integer iNumCacheLines; //number of cache lines
    input array<tuple<Integer,Integer>> iSCVarCLMapping; //mapping for each SimCode.Var (arrayIndex) to the cache line index and cache line type
    output array<list<Integer>> oCLTaskMapping;
    output array<Integer> oScVarTaskMapping;
  protected
    array<tuple<Integer,Integer,Integer>> varCompMapping;
    array<list<Integer>> tmpCLTaskMapping;
    array<Integer> scVarTaskMapping;
  algorithm
    tmpCLTaskMapping := arrayCreate(iNumCacheLines,{});
    scVarTaskMapping := arrayCreate(arrayLength(iSCVarCLMapping),-1);
    HpcOmTaskGraph.TASKGRAPHMETA(varCompMapping=varCompMapping) := iTaskGraphMeta;
    //iterate over all variables
    ((tmpCLTaskMapping,oScVarTaskMapping,_)) := Array.fold3(varCompMapping, getCacheLineTaskMapping0, iEqSystems, iVarNameSCVarIdxMapping, iSCVarCLMapping, (tmpCLTaskMapping,scVarTaskMapping,1));
    tmpCLTaskMapping := Array.map1(tmpCLTaskMapping, List.sort, intLt);
    oCLTaskMapping := Array.map1(tmpCLTaskMapping, List.sortedUnique, intEq);
  end getCacheLineTaskMapping;

  protected function getCacheLineTaskMapping0 "author: marcusw
    This method will extend the mapping with the informations of the given node."
    input tuple<Integer,Integer,Integer> iNodeIdx; //<nodeIdx,eqSysIdx,varOffset>
    input BackendDAE.EqSystems iEqSystems;
    input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
    input array<tuple<Integer,Integer>> iSCVarCLMapping; //mapping for each SimCode.Var (arrayIndex) to the cache line index
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
          var = BackendVariable.getVarAt(orderedVars, varIdx - varOffset);
          BackendDAE.VAR(varName=varName) = var;
          varName = getModifiedVarName(var);
          scVarValues = BaseHashTable.get(varName,iVarNameSCVarIdxMapping);
          scVarIdx = List.first(scVarValues);
          scVarOffset = List.second(scVarValues);
          scVarIdx = scVarIdx + scVarOffset;
          ((clIdx,_)) = arrayGet(iSCVarCLMapping,scVarIdx);
          oldVal = arrayGet(iClTaskMapping,clIdx);
          iClTaskMapping = arrayUpdate(iClTaskMapping,clIdx,nodeIdx::oldVal);
          //print("getCacheLineTaskMapping0 scVarIdx: " + intString(scVarIdx) + "\n");
          iScVarTaskMapping = arrayUpdate(iScVarTaskMapping,scVarIdx,nodeIdx);
          //print("Variable " + intString(varIdx) + " (" + ComponentReference.printComponentRefStr(varName) + ") [SC-Var " + intString(scVarIdx) + "]\n---------------------\n");
          //print("Part of CL " + intString(clIdx) + " solved by node " + intString(nodeIdx) + "\n\n");
        then ((iClTaskMapping,iScVarTaskMapping,varIdx+1));
      case(_,_,_,_,(iClTaskMapping,iScVarTaskMapping,varIdx))
        then ((iClTaskMapping,iScVarTaskMapping,varIdx+1));
    end matchcontinue;
  end getCacheLineTaskMapping0;


  // -------------------------------------------
  // GRAPH
  // -------------------------------------------

  protected function appendCacheLinesToGraph "author: marcusw
    This method will extend the given graph-info with a new subgraph containing all cache lines.
    Dependencies between the tasks and the cache lines will be inserted as edges."
    input CacheMap iCacheMap;
    input Integer iNumberOfNodes; //number of nodes in the task graph
    input array<list<Integer>> iNodeSimCodeVarMapping;
    input array<array<list<Integer>>> iEqSimCodeVarMapping;
    input BackendDAE.EqSystems iEqSystems; //the eqSystem of the incidence matrix
    input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
    input array<tuple<Integer,Integer,Integer>> ieqCompMapping; //a mapping from eqIdx (arrayIdx) to the scc idx
    input array<Integer> iScVarTaskMapping; //maps each scVar (arrayIdx) to the task that solves it
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input Integer iAttributeIdc; //indices for attributes threadId
    input array<Integer> iCompNodeMapping;
    input GraphML.GraphInfo iGraphInfo;
    output GraphML.GraphInfo oGraphInfo;
  protected
    Integer clGroupNodeIdx, graphCount;
    GraphML.GraphInfo tmpGraphInfo;
    array<list<Integer>> knownEdges; //edges from task to variables
    array<Boolean> addedVariables;
    array<SimCodeVar.SimVar> cacheVariables;
    list<CacheLineMap> cacheLines;
  algorithm
    oGraphInfo := matchcontinue(iCacheMap,iNumberOfNodes,iNodeSimCodeVarMapping,iEqSimCodeVarMapping,iEqSystems,iVarNameSCVarIdxMapping,ieqCompMapping,iScVarTaskMapping,iSchedulerInfo,iAttributeIdc,iCompNodeMapping,iGraphInfo)
      case(_,_,_,_,_,_,_,_,_,_,_,GraphML.GRAPHINFO(graphCount=graphCount))
        equation
          true = intLe(1, graphCount);
          knownEdges = arrayCreate(iNumberOfNodes,{});
          addedVariables = arrayCreate(arrayLength(iScVarTaskMapping), false);
          (tmpGraphInfo,(_,_),(_,clGroupNodeIdx)) = GraphML.addGroupNode("CL_GoupNode", 1, false, "CL", iGraphInfo);
          cacheLines = getAllCacheLinesOfCacheMap(iCacheMap);
          cacheVariables = listArray(getCacheVariablesOfCacheMap(iCacheMap));
          tmpGraphInfo = List.fold(cacheLines, function appendCacheLineMapToGraph(iCacheVariables=cacheVariables, iAddedVariables=addedVariables, iSchedulerInfo=iSchedulerInfo, iTopGraphAttThreadIdIdx=(clGroupNodeIdx,iAttributeIdc), iScVarTaskMapping=iScVarTaskMapping, iVarNameSCVarIdxMapping=iVarNameSCVarIdxMapping), tmpGraphInfo);
          //((_,knownEdges,tmpGraphInfo)) = Array.fold3(arrayGet(iEqSimCodeVarMapping,1), appendCacheLineEdgesToGraphTraverse, ieqCompMapping, iCompNodeMapping, iScVarTaskMapping, (1,knownEdges,tmpGraphInfo));
          ((_,tmpGraphInfo)) = Array.fold(iNodeSimCodeVarMapping, function appendCacheLineEdgeToGraphSolvedVar(iAddedVariables=addedVariables), (1,tmpGraphInfo));
        then tmpGraphInfo;
      case(_,_,_,_,_,_,_,_,_,_,_,GraphML.GRAPHINFO(graphCount=graphCount))
        equation
          true = intEq(graphCount,0);
        then iGraphInfo;
      else
        equation
          print("HpcOmSimCode.appendCacheLinesToGraph failed!\n");
        then fail();
     end matchcontinue;
  end appendCacheLinesToGraph;

  protected function appendCacheLineEdgeToGraphSolvedVar
    input list<Integer> iNodeSCVars;
    input array<Boolean> iAddedVariables;
    input tuple<Integer,GraphML.GraphInfo> iIdxGraphInfo;
    output tuple<Integer,GraphML.GraphInfo> oIdxGraphInfo;
  protected
    Integer nodeIdx;
    GraphML.GraphInfo graphInfo;
    String edgeId, targetId, sourceId;
  algorithm
    (nodeIdx,graphInfo) := iIdxGraphInfo;
    ((_,graphInfo)) := List.fold(iNodeSCVars, function appendCacheLineEdgeToGraphSolvedVar0(iAddedVariables=iAddedVariables), (nodeIdx,graphInfo));
    oIdxGraphInfo := (nodeIdx+1,graphInfo);
  end appendCacheLineEdgeToGraphSolvedVar;

  protected function appendCacheLineEdgeToGraphSolvedVar0
    input Integer iVarIdx;
    input array<Boolean> iAddedVariables;
    input tuple<Integer,GraphML.GraphInfo> iNodeIdxGraphInfo;
    output tuple<Integer,GraphML.GraphInfo> oNodeIdxGraphInfo;
  protected
    GraphML.GraphInfo graphInfo;
    Integer nodeIdx;
    String edgeId, targetId, sourceId;
  algorithm
    oNodeIdxGraphInfo := matchcontinue(iVarIdx, iAddedVariables, iNodeIdxGraphInfo)
      case(_,_,(nodeIdx, graphInfo))
        equation
          true = intGt(iVarIdx,0);
          //print("appendCacheLineEdgeToGraphSolvedVar0: NodeIdx=" + intString(nodeIdx) + " varIdx=" + intString(iVarIdx) + "\n");
          true = arrayGet(iAddedVariables, iVarIdx);
          sourceId = "Node" + intString(nodeIdx);
          targetId = "CL_Var" + intString(iVarIdx);
          edgeId = "edge_CL_" + sourceId + "_" + targetId;
          (graphInfo,(_,_)) = GraphML.addEdge(edgeId, targetId, sourceId, GraphML.COLOR_GRAY, GraphML.DASHED(), GraphML.LINEWIDTH_STANDARD, true, {}, (GraphML.ARROWNONE(),GraphML.ARROWNONE()), {}, graphInfo);
        then ((nodeIdx,graphInfo));
      else iNodeIdxGraphInfo;
    end matchcontinue;
  end appendCacheLineEdgeToGraphSolvedVar0;

  protected function appendCacheLineMapToGraph "author: marcusw
    This method will extend the given graph-info with a new subgraph containing the entry of the given cache line."
    input CacheLineMap iCacheLineMap;
    input array<SimCodeVar.SimVar> iCacheVariables;
    input array<Boolean> iAddedVariables;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input tuple<Integer,Integer> iTopGraphAttThreadIdIdx; //<topGraphIdx,threadIdAttIdx>
    input array<Integer> iScVarTaskMapping; //maps each scVar (arrayIdx) to the task that solves her
    input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
    input GraphML.GraphInfo iGraphInfo;
    output GraphML.GraphInfo oGraphInfo;
  protected
    Integer idx, graphIdx, iTopGraphIdx, iAttThreadIdIdx;
    list<CacheLineEntry> entries;
    CacheLineEntry entry;
    GraphML.GraphInfo tmpGraphInfo;
    Integer entryThreadOwner;
    Boolean notOnlyParamters;
  algorithm
    CACHELINEMAP(idx=idx,entries=entries) := iCacheLineMap;
    //check if the cache line contains only parameters
    notOnlyParamters := false;
    for entry in entries loop
      CACHELINEENTRY(threadOwner=entryThreadOwner) := entry;
      notOnlyParamters := boolOr(notOnlyParamters, intNe(entryThreadOwner, -1));
    end for;
    if(notOnlyParamters) then
      (iTopGraphIdx, iAttThreadIdIdx) := iTopGraphAttThreadIdIdx;
      (tmpGraphInfo, (_,_),(_,graphIdx)) := GraphML.addGroupNode("CL_Meta_" + intString(idx), iTopGraphIdx, true, "CL" + intString(idx), iGraphInfo);
      oGraphInfo := List.fold(entries, function appendCacheLineEntryToGraph(iCacheVariables=iCacheVariables, iAddedVariables=iAddedVariables, iSchedulerInfo=iSchedulerInfo, iTopGraphAttThreadIdIdx=(graphIdx,iAttThreadIdIdx), iScVarTaskMapping=iScVarTaskMapping, iVarNameSCVarIdxMapping=iVarNameSCVarIdxMapping), tmpGraphInfo);
    else
      oGraphInfo := iGraphInfo;
    end if;
  end appendCacheLineMapToGraph;

  protected function appendCacheLineEntryToGraph
    input CacheLineEntry iCacheLineEntry;
    input array<SimCodeVar.SimVar> iCacheVariables;
    input array<Boolean> iAddedVariables;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input tuple<Integer,Integer> iTopGraphAttThreadIdIdx; //<topGraphIdx,threadIdAttIdx>
    input array<Integer> iScVarTaskMapping; //maps each scVar (arrayIdx) to the task that solves her
    input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
    input GraphML.GraphInfo iGraphInfo;
    output GraphML.GraphInfo oGraphInfo;
  protected
    list<Integer> realScVarIdxOffset;
    Integer scVarIdx, realScVarIdx, realScVarOffset, taskIdx, iTopGraphIdx, iAttThreadIdIdx, threadOwner;
    String varString, threadText, nodeLabelText, nodeId;
    GraphML.NodeLabel nodeLabel;
    SimCodeVar.SimVar iVar;
    DAE.ComponentRef name;
  algorithm
    CACHELINEENTRY(scVarIdx=scVarIdx,threadOwner=threadOwner) := iCacheLineEntry;
    (iTopGraphIdx, iAttThreadIdIdx) := iTopGraphAttThreadIdIdx;
    //print("HpcOmSimCode.appendCacheLineNodesToGraphTraverse scVarIdx: " + intString(scVarIdx) + " list position: " + intString(listLength(iCacheVariables) - scVarIdx + 1) + "\n");
    if(intGt(arrayLength(iCacheVariables) - scVarIdx + 1, 1)) then
      iVar := arrayGet(iCacheVariables, arrayLength(iCacheVariables) - scVarIdx + 1);
      SimCodeVar.SIMVAR(name=name) := iVar;
      //print("Var with name " + ComponentReference.printComponentRefStr(name) + " found. ScVar-Idx: " + intString(scVarIdx) + "\n");
      realScVarIdxOffset := BaseHashTable.get(name, iVarNameSCVarIdxMapping);
      realScVarIdx := listGet(realScVarIdxOffset,1);
      realScVarOffset := listGet(realScVarIdxOffset,2);
      realScVarIdx := realScVarIdx + realScVarOffset;
      varString := ComponentReference.printComponentRefStr(name);
      taskIdx := arrayGet(iScVarTaskMapping,realScVarIdx);
      //print("HpcOmSimCode.appendCacheLineNodesToGraphTraverse SCVarNode: " + intString(realScVarIdx) + " [" + varString + "] sccIdx: " + intString(taskIdx) + "\n");
      //print("HpcOmSimCode.appendCacheLineNodesToGraphTraverse ThreadOwner: " + intString(threadOwner) + "\n");
      nodeId := "CL_Var" + intString(realScVarIdx);

      arrayUpdate(iAddedVariables, realScVarIdx, true);
      threadText := "Th " + intString(threadOwner);
      nodeLabelText := intString(realScVarIdx);
      nodeLabel := GraphML.NODELABEL_INTERNAL(nodeLabelText, NONE(), GraphML.FONTPLAIN());
      (oGraphInfo,_) := GraphML.addNode(nodeId, GraphML.COLOR_GREEN, {nodeLabel}, GraphML.ELLIPSE(), SOME(varString), {(iAttThreadIdIdx,threadText)}, iTopGraphIdx, iGraphInfo);
    else
      oGraphInfo := iGraphInfo;
    end if;
  end appendCacheLineEntryToGraph;


  // -------------------------------------------
  // PRINT
  // -------------------------------------------

  protected function printCacheMap
    input CacheMap iCacheMap;
  protected
    Integer cacheLineSize;
    list<CacheLineMap> cacheLinesFloat;
    list<CacheLineMap> cacheLinesInt;
    list<CacheLineMap> cacheLinesBool;
    list<CacheLineMap> cacheLines;
    list<SimCodeVar.SimVar> cacheVariables;
  algorithm
    _ := match(iCacheMap)
      case(CACHEMAP(cacheLineSize=cacheLineSize, cacheVariables=cacheVariables, cacheLinesFloat=cacheLinesFloat, cacheLinesInt=cacheLinesInt, cacheLinesBool=cacheLinesBool))
        equation
          print("\n\nCacheMap\n---------------\n");
          print("  Float Variables.\n");
          List.map1_0(cacheLinesFloat, printCacheLineMap, cacheVariables);
          print("  Int Variables.\n");
          List.map1_0(cacheLinesInt, printCacheLineMap, cacheVariables);
          print("  Bool Variables.\n");
          List.map1_0(cacheLinesBool, printCacheLineMap, cacheVariables);
        then ();
      case(UNIFORM_CACHEMAP(cacheLineSize=cacheLineSize, cacheVariables=cacheVariables, cacheLines=cacheLines))
        equation
          print("\n\nUniform CacheMap\n---------------\n");
          print("  Variables.\n");
          List.map1_0(cacheLines, printCacheLineMap, cacheVariables);
        then ();
      else
        equation
          print("printCacheMap: Unsupported cache map type!\n");
        then ();
    end match;
  end printCacheMap;

  protected function printCacheLineMap
    input CacheLineMap iCacheLineMap;
    input list<SimCodeVar.SimVar> iCacheVariables;
  protected
    Integer idx;
    list<CacheLineEntry> entries;
    String iVarsString, iBytesString;
  algorithm
    CACHELINEMAP(idx=idx, entries=entries) := iCacheLineMap;
    print("  CacheLineMap " + intString(idx) + " (" + intString(listLength(entries)) + " entries)\n");
    ((iVarsString, iBytesString)) := List.fold1(entries, cacheLineEntryToString, iCacheVariables, ("",""));
    print("    " + iVarsString + "\n");
    print("    " + iBytesString + "\n");
    print("\n");
  end printCacheLineMap;

  protected function printCacheLineMapClean
    input CacheLineMap iCacheLineMap;
  protected
    Integer idx;
    list<CacheLineEntry> entries;
    String iVarsString, iBytesString;
  algorithm
    CACHELINEMAP(idx=idx, entries=entries) := iCacheLineMap;
    print("  CacheLineMap " + intString(idx) + " (" + intString(listLength(entries)) + " entries)\n");
    ((iVarsString, iBytesString)) := List.fold(entries, cacheLineEntryToStringClean, ("",""));
    print("    " + iVarsString + "\n");
    print("    " + iBytesString + "\n");
    print("\n");
  end printCacheLineMapClean;

  protected function cacheLineEntryToString
    input CacheLineEntry iCacheLineEntry;
    input list<SimCodeVar.SimVar> iCacheVariables;
    input tuple<String,String> iString; //<variable names seperated by |, byte positions string>
    output tuple<String,String> oString;
  protected
    Integer start;
    Integer dataType;
    Integer size;
    Integer scVarIdx;
    String scVarStr;
    SimCodeVar.SimVar iVar;
    String iVarsString, iBytesString, iBytesStringNew, byteStartString;
  algorithm
    (iVarsString, iBytesString) := iString;
    CACHELINEENTRY(start=start,dataType=dataType,size=size,scVarIdx=scVarIdx) := iCacheLineEntry;
    //print("cacheLineEntryToString: try to create entry for variable '" + intString(scVarIdx) + "' out of cache-variable list with '" + intString(listLength(iCacheVariables)) + "' entries \n");
    iVar := listGet(iCacheVariables, listLength(iCacheVariables) - scVarIdx + 1);
    scVarStr := dumpSimCodeVar(iVar);
    iVarsString := iVarsString + "| " + scVarStr + " ";
    iBytesStringNew := intString(start);
    iBytesStringNew := Util.stringPadRight(iBytesStringNew, 3 + stringLength(scVarStr), " ");
    iBytesString := iBytesString + iBytesStringNew;
    oString := (iVarsString,iBytesString);
  end cacheLineEntryToString;

  protected function cacheLineEntryToStringClean
    input CacheLineEntry iCacheLineEntry;
    input tuple<String,String> iString; //<variable names seperated by |, byte positions string>
    output tuple<String,String> oString;
  protected
    Integer start;
    Integer dataType;
    Integer size;
    Integer scVarIdx;
    String scVarStr;
    String iVarsString, iBytesString, iBytesStringNew, byteStartString;
  algorithm
    (iVarsString, iBytesString) := iString;
    CACHELINEENTRY(start=start,dataType=dataType,size=size,scVarIdx=scVarIdx) := iCacheLineEntry;
    scVarStr := intString(scVarIdx);
    iVarsString := iVarsString + "| " + scVarStr + " ";
    iBytesStringNew := intString(start);
    iBytesStringNew := Util.stringPadRight(iBytesStringNew, 3 + stringLength(scVarStr), " ");
    iBytesString := iBytesString + iBytesStringNew;
    oString := (iVarsString,iBytesString);
  end cacheLineEntryToStringClean;

  protected function dumpSimCodeVar
    input SimCodeVar.SimVar iVar;
    output String oString;
  protected
    DAE.ComponentRef name;
  algorithm
    SimCodeVar.SIMVAR(name=name) := iVar;
    oString := ComponentReference.printComponentRefStr(name);
  end dumpSimCodeVar;

  protected function printNodeSimCodeVarMapping
    input array<list<Integer>> iMapping;
  algorithm
    print("Node - SimCodeVar - Mapping\n------------------\n");
    _ := Array.fold(iMapping, printNodeSimCodeVarMapping0,1);
    print("\n");
  end printNodeSimCodeVarMapping;

  protected function printNodeSimCodeVarMapping0
    input list<Integer> iMappingEntry;
    input Integer iNodeIdx;
    output Integer oNodeIdx;
  algorithm
    print("Node " + intString(iNodeIdx) + " solves sc-vars: " + stringDelimitList(List.map(iMappingEntry, intString), ",") + "\n");
    oNodeIdx := iNodeIdx + 1;
  end printNodeSimCodeVarMapping0;

  protected function printScVarTaskMapping
    input array<Integer> iMapping;
  algorithm
    print("----------------------\nSCVar - Task - Mapping\n----------------------\n");
    _ := Array.fold(iMapping, printScVarTaskMapping0, 1);
    print("\n");
  end printScVarTaskMapping;

  protected function printScVarTaskMapping0
    input Integer iMappingEntry;
    input Integer iScVarIdx;
    output Integer oScVarIdx;
  algorithm
    print("SCVar " + intString(iScVarIdx) + " is solved in task: " + intString(iMappingEntry) + "\n");
    oScVarIdx := iScVarIdx + 1;
  end printScVarTaskMapping0;

  protected function printCacheLineTaskMapping
    input array<list<Integer>> iCacheLineTaskMapping;
  algorithm
    _ := Array.fold(iCacheLineTaskMapping, printCacheLineTaskMapping0, 1);
  end printCacheLineTaskMapping;

  protected function printCacheLineTaskMapping0
    input list<Integer> iTasks;
    input Integer iCacheLineIdx;
    output Integer oCacheLineIdx;
  algorithm
    print("Tasks that are writing to cacheline " + intString(iCacheLineIdx) + ": " + stringDelimitList(List.map(iTasks, intString), ",") + "\n");
    oCacheLineIdx := iCacheLineIdx + 1;
  end printCacheLineTaskMapping0;

  protected function printEqSimCodeVarMapping
    input array<array<list<Integer>>> iMapping; //eqSysIdx -> eqIdx -> list<scVarIdx>
  protected
    array<list<Integer>> sysInformations;
    Integer sysIdx;
    list<Integer> vars;
  algorithm
    for sysIdx in 1:arrayLength(iMapping) loop
      print("System " + intString(sysIdx) + "\n");
      sysInformations := arrayGet(iMapping, sysIdx);
      for eqIdx in 1:arrayLength(sysInformations) loop
        vars := arrayGet(sysInformations, eqIdx);
        print(" Equation " + intString(eqIdx) + " needs variables " + stringDelimitList(List.map(vars, intString), ",") + "\n");
      end for;
    end for;
  end printEqSimCodeVarMapping;

  protected function printSccNodeMapping
    input array<Integer> iMapping;
  algorithm
    print("--------------------\nScc - Node - Mapping\n--------------------\n");
    _ := Array.fold(iMapping, printSccNodeMapping0, 1);
  end printSccNodeMapping;

  protected function printSccNodeMapping0
    input Integer iMappingEntry;
    input Integer iIdx;
    output Integer oIdx;
  algorithm
    print("Scc " + intString(iIdx) + " is solved by node " + intString(iMappingEntry) + "\n");
    oIdx := iIdx + 1;
  end printSccNodeMapping0;

  protected function dumpScVarsByIdx
    input Integer iSimCodeVarIdx;
    input array<Option<SimCodeVar.SimVar>> iAllSCVarsMapping;
    output String oString;
  protected
    String tmpString;
    SimCodeVar.SimVar simVar;
  algorithm
    oString := matchcontinue(iSimCodeVarIdx, iAllSCVarsMapping)
      case(_,_)
        equation
          SOME(simVar) = arrayGet(iAllSCVarsMapping, iSimCodeVarIdx);
          tmpString = dumpSimCodeVar(simVar);
        then tmpString;
      else
        equation
          print("dumpScVarsByIdx: Failed to find simcode-variable with index " + intString(iSimCodeVarIdx) + "\n");
        then "NONE";
    end matchcontinue;
  end dumpScVarsByIdx;

  // -------------------------------------------
  // SUSAN
  // -------------------------------------------

  public function useHpcomMemoryOptimization
    input Option<HpcOmSimCode.MemoryMap> iMemoryMapOpt;
    output Boolean oUseMemoryOptimization;
  algorithm
    oUseMemoryOptimization := match(iMemoryMapOpt)
      case(SOME(HpcOmSimCode.MEMORYMAP_UNIFORM()))
        then false;
      case(SOME(_))
        then true;
      else false;
    end match;
  end useHpcomMemoryOptimization;

  public function getPositionMappingByArrayName
    "author: marcusw
     Function used by Susan - gets the position informations (arrayIdx, arrayPos) of the given variable (iVarName)."
    input HpcOmSimCode.MemoryMap iMemoryMap;
    input DAE.ComponentRef iVarName;
    output Option<tuple<Integer,Integer>> oResult;
  protected
    List<Integer> idxList;
    Integer idx, elem1, elem2;
    array<tuple<Integer,Integer>> positionMapping;
    HashTableCrILst.HashTable scVarNameIdxMapping;
  algorithm
    oResult := matchcontinue(iMemoryMap, iVarName)
      case(HpcOmSimCode.MEMORYMAP_ARRAY(positionMapping=positionMapping, scVarNameIdxMapping=scVarNameIdxMapping),_)
        equation
          true = BaseHashTable.hasKey(iVarName, scVarNameIdxMapping);
          idxList = BaseHashTable.get(iVarName , scVarNameIdxMapping);
          idx = listGet(idxList, 1) + listGet(idxList, 2);
          ((elem1,elem2)) = arrayGet(positionMapping, idx);
          true = intGe(elem1,0);
          true = intGe(elem2,0);
        then SOME((elem1,elem2));
      else NONE();
    end matchcontinue;
  end getPositionMappingByArrayName;

  public function getSubscriptListOfArrayCref
    input DAE.ComponentRef iCref;
    input list<String> iNumArrayElems;
    output list<list<DAE.Subscript>> oSubscriptList;
  protected
    list<DAE.ComponentRef> tmpCrefs;
    DAE.ComponentRef cref;
  algorithm
    //print("getSubscriptListOfArrayCref: iNumArrayElems=" + stringDelimitList(iNumArrayElems, ",") + "\n");
    //print("============================================\n");
    tmpCrefs := expandCref(iCref, iNumArrayElems);
    //for cref in tmpCrefs loop
    //  print(ComponentReference.printComponentRefStr(cref) + "\n");
    //end for;
    oSubscriptList := List.map(tmpCrefs, ComponentReference.crefLastSubs);
  end getSubscriptListOfArrayCref;

  public function expandCref
    input DAE.ComponentRef iCref;
    input list<String> iNumArrayElems;
    output list<DAE.ComponentRef> oCrefs;
  protected
    Integer elems, dims;
    list<Integer> dimElemCount;
    DAE.ComponentRef cref;
  algorithm
    cref := removeSubscripts(iCref);
    //print("expandCref: " + ComponentReference.printComponentRefStr(cref) + "\n");
    dims := getCrefDims(iCref);
    //print("expandCref: iNumArrayElems=" + stringDelimitList(iNumArrayElems, ",") + "\n");
    dimElemCount := getDimElemCount(listReverse(iNumArrayElems),dims);
    //print("expandCref: numArrayElems " + intString(getNumArrayElems(iNumArrayElems, getCrefDims(iCref))) + "\n");
    elems := List.reduce(dimElemCount, intMul);
    //print("expandCref: " + ComponentReference.printComponentRefStr(iCref) + " dims: " + intString(dims) + " elems: " + intString(elems) + "\n");
    dims := listLength(iNumArrayElems);
    //print("expandCref: " + ComponentReference.printComponentRefStr(iCref) + " dims: " + intString(dims) + "[" + intString(getCrefDims(iCref)) + "] elems: " + intString(elems) + "\n");
    oCrefs := expandCref1(cref, elems, dimElemCount);
  end expandCref;

  public function expandCrefWithDims
    input DAE.ComponentRef iCref;
    input DAE.Dimensions iDims;
    output list<DAE.ComponentRef> oCrefs;
  protected
    Integer elems, dims;
    list<Integer> dimElemCount;
    DAE.ComponentRef cref;
    DAE.Dimension dim;
    list<String> numArrayElems;
  algorithm
    numArrayElems := {};
    for dim in iDims loop
      numArrayElems := getDimStringOfDimElement(dim)::numArrayElems;
    end for;
    oCrefs := expandCref(iCref, numArrayElems);
  end expandCrefWithDims;

  protected function getDimStringOfDimElement
    input DAE.Dimension iDim;
    output String oDimString;
  protected
    Integer integer;
  algorithm
    oDimString := match(iDim)
      case(DAE.DIM_INTEGER(integer))
        then intString(integer);
      else
       equation
         print("getDimStringOfDimElement: unsupported Dimension-type given!\n");
       then "";
    end match;
  end getDimStringOfDimElement;

  protected function removeSubscripts
    input DAE.ComponentRef iCref;
    output DAE.ComponentRef oCref;
  protected
    DAE.Ident ident;
    DAE.Type identType "type of the identifier, without considering the subscripts";
    list<DAE.Subscript> subscriptLst;
    DAE.ComponentRef componentRef;
    Integer index;
  algorithm
    oCref := match(iCref)
      case(DAE.CREF_QUAL(ident,identType,subscriptLst,componentRef))
        equation
          componentRef = removeSubscripts(componentRef);
        then DAE.CREF_QUAL(ident,identType,subscriptLst,componentRef);
      case(DAE.CREF_IDENT(ident,identType,subscriptLst))
        then DAE.CREF_IDENT(ident,identType,{});
      case(DAE.CREF_ITER(ident,index,identType,subscriptLst))
        then DAE.CREF_ITER(ident,index,identType,{});
      else iCref;
    end match;
  end removeSubscripts;

  protected function getDimElemCount
    input list<String> iNumArrayElems;
    input Integer iDims;
    output list<Integer> oNumArrayElems;
  protected
    list<Integer> dimList, intNumArrayElems;
    Integer dims;
  algorithm
    dims := if intLe(iDims,0) then listLength(iNumArrayElems) else iDims;
    dimList := List.intRange(dims);
    intNumArrayElems := List.map(iNumArrayElems,stringInt);
    //print("getDimElemCount: dims=" + intString(dims) + " elems=" + intString(listLength(iNumArrayElems)) + "\n");
    oNumArrayElems := List.map1(dimList, List.getIndexFirst, intNumArrayElems);
  end getDimElemCount;

  protected function getCrefDims
    input DAE.ComponentRef iCref;
    output Integer oDims;
  protected
    DAE.ComponentRef componentRef;
    list<DAE.Subscript> subscriptLst;
    Integer tmpDims;
  algorithm
    oDims := match(iCref)
      case(DAE.CREF_QUAL(componentRef=componentRef))
        then getCrefDims(componentRef);
      case(DAE.CREF_IDENT(subscriptLst=subscriptLst))
        equation
          tmpDims = listLength(subscriptLst);
        then tmpDims;
      else
        equation
          print("HpcOmMemory.getCrefDims failed!\n");
        then 0;
    end match;
  end getCrefDims;

  protected function expandCref1
    input DAE.ComponentRef iCref;
    input Integer iElems;
    input list<Integer> iDimElemCount;
    output list<DAE.ComponentRef> oCrefs;
  protected
    list<DAE.ComponentRef> tmpCrefs;
    list<Integer> idxList;
  algorithm
    oCrefs := matchcontinue(iCref, iElems, iDimElemCount)
      case(_,_,_)
        equation
          tmpCrefs = ComponentReference.expandCref(iCref, false);
          true = intEq(listLength(tmpCrefs), iElems);
        then tmpCrefs;
      else
        equation
          //print("expandCref1: " + ComponentReference.printComponentRefStr(iCref) + " elems: " + intString(iElems) + " dims: " + intString(listLength(iDimElemCount)) + "\n");
          idxList = List.intRange(List.reduce(iDimElemCount, intMul));
          //print("expandCref1 idxList-count: " + intString(listLength(idxList)) + "\n");
          //ComponentReference.printComponentRefList(List.map2(idxList, createArrayIndexCref, iDimElemCount, iCref));
          tmpCrefs = List.map2(idxList, createArrayIndexCref, iDimElemCount, iCref);
          //ComponentReference.printComponentRefList(tmpCrefs);
        then tmpCrefs;
    end matchcontinue;
  end expandCref1;

  protected function createArrayIndexCref
    input Integer iIdx;
    input list<Integer> iDimElemCount;
    input DAE.ComponentRef iCref;
    output DAE.ComponentRef oCref;
  algorithm
    ((oCref,_)) := createArrayIndexCref_impl(iIdx, iDimElemCount, (iCref,1));
  end createArrayIndexCref;

  protected function createArrayIndexCref_impl
    input Integer iIdx;
    input list<Integer> iDimElemCount;
    input tuple<DAE.ComponentRef, Integer> iRefCurrentDim; //<ref, currentDim>
    output tuple<DAE.ComponentRef, Integer> oRefCurrentDim;
  protected
    DAE.Ident ident;
    DAE.Type identType;
    list<DAE.Subscript> subscriptLst;
    DAE.ComponentRef componentRef;
    Integer currentDim, idxValue, dimElemsPre, dimElems;
  algorithm
    oRefCurrentDim := matchcontinue(iIdx, iDimElemCount, iRefCurrentDim)
      case(_,_,(DAE.CREF_QUAL(ident,identType,subscriptLst,componentRef),1)) //the first dimension represents the last c-array-index
        equation
          true = intLe(1, listLength(iDimElemCount));
          //print("createArrayIndexCref_impl case1 " + ComponentReference.printComponentRefStr(Util.tuple21(iRefCurrentDim)) + " currentDim " + intString(1) + "\n");
          ((componentRef,_)) = createArrayIndexCref_impl(iIdx, iDimElemCount, (componentRef,1));
        then ((DAE.CREF_QUAL(ident,identType,subscriptLst,componentRef),2));

      case(_,_,(DAE.CREF_QUAL(ident,identType,subscriptLst,componentRef),currentDim))
        equation
          true = intLe(currentDim, listLength(iDimElemCount));
          //print("createArrayIndexCref_impl case2 " + ComponentReference.printComponentRefStr(Util.tuple21(iRefCurrentDim)) + " currentDim " + intString(currentDim) + "\n");
          ((componentRef,_)) = createArrayIndexCref_impl(iIdx, iDimElemCount, (componentRef,currentDim));
        then ((DAE.CREF_QUAL(ident,identType,subscriptLst,componentRef),currentDim+1));

      case(_,_,(DAE.CREF_IDENT(ident,identType,subscriptLst),1))
        equation
          true = intLe(1, listLength(iDimElemCount));
          //print("createArrayIndexCref_impl case3 | len(subscriptList)= " + intString(listLength(subscriptLst)) + " " + ComponentReference.printComponentRefStr(Util.tuple21(iRefCurrentDim)) + " currentDim " + intString(1) + "\n");
          idxValue = intMod(iIdx-1,List.first(iDimElemCount)) + 1;
          subscriptLst = DAE.INDEX(DAE.ICONST(idxValue))::subscriptLst;
        then createArrayIndexCref_impl(iIdx, iDimElemCount, (DAE.CREF_IDENT(ident,identType,subscriptLst),2));

      case(_,_,(DAE.CREF_IDENT(ident,identType,subscriptLst),currentDim))
        equation
          true = intLe(currentDim, listLength(iDimElemCount));
          //dimElemsPre = List.reduce(List.sublist(iDimElemCount, listLength(iDimElemCount) - currentDim + 2, currentDim - 1), intMul);
          //print("createArrayIndexCref_impl case4: listLen=" + intString(listLength(iDimElemCount)) + " currentDim= " + intString(currentDim) + "\n");
          dimElemsPre = List.reduce(List.sublist(iDimElemCount, 1, listLength(iDimElemCount) - currentDim + 1), intMul);
          //print("createArrayIndexCref_impl case4 | len(subscriptList)= " + intString(listLength(subscriptLst)) + " " + ComponentReference.printComponentRefStr(Util.tuple21(iRefCurrentDim)) + " currentDim " + intString(currentDim) + " dimElemsPre: " + intString(dimElemsPre) + "\n");
          dimElems = listGet(iDimElemCount, currentDim);
          idxValue = intMod(intDiv(iIdx - 1, dimElemsPre),dimElems) + 1;
          //print("createArrayIndexCref_impl case4 idxValue=" + intString(idxValue) + "\n");
          subscriptLst = DAE.INDEX(DAE.ICONST(idxValue))::subscriptLst;
        then createArrayIndexCref_impl(iIdx, iDimElemCount, (DAE.CREF_IDENT(ident,identType,subscriptLst),currentDim+1));
      case(_,_,(DAE.CREF_IDENT(ident,identType,subscriptLst),currentDim))
        equation
          false = intLe(currentDim, listLength(iDimElemCount));
          //print("createArrayIndexCref_impl case5: listLen=" + intString(listLength(iDimElemCount)) + " currentDim= " + intString(currentDim) + "\n");
        then iRefCurrentDim;
      else
        equation
          print("createArrayIndexCref_impl failed!\n");
        then iRefCurrentDim;
    end matchcontinue;
  end createArrayIndexCref_impl;

  // -------------------------------------------
  // UTIL
  // -------------------------------------------

  protected function getTaskListTasks
    input HpcOmSimCode.TaskList iTaskList;
    output list<HpcOmSimCode.Task> oTasks;
  protected
    list<HpcOmSimCode.Task> tasks;
  algorithm
    oTasks := match(iTaskList)
      case(HpcOmSimCode.PARALLELTASKLIST(tasks=tasks))
      then tasks;
      case(HpcOmSimCode.PARALLELTASKLIST(tasks=tasks))
      then tasks;
      else
       equation
         print("getTaskListTasks failed!\n");
      then {};
    end match;
  end getTaskListTasks;

  protected function getCacheLineMapOfPartlyFilledCacheLine
    input PartlyFilledCacheLine iPartlyFilledCacheLine;
    output CacheLineMap oCacheLineMap;
  algorithm
    PARTLYFILLEDCACHELINE(cacheLineMap=oCacheLineMap) := iPartlyFilledCacheLine;
  end getCacheLineMapOfPartlyFilledCacheLine;

  protected function getAllCacheLinesOfCacheMap "author: marcusw
    Get all cache lines that are stored in the given cache map."
    input CacheMap iCacheMap;
    output list<CacheLineMap> oCacheLines;
  protected
    list<CacheLineMap> cacheLinesFloat, cacheLinesInt, cacheLinesBool, allCacheLines;
  algorithm
    oCacheLines := match(iCacheMap)
      case(CACHEMAP(cacheLinesFloat=cacheLinesFloat, cacheLinesInt=cacheLinesInt, cacheLinesBool=cacheLinesBool))
        equation
          allCacheLines = listAppend(cacheLinesFloat, listAppend(cacheLinesInt, cacheLinesBool));
        then allCacheLines;
      case(UNIFORM_CACHEMAP(cacheLines=allCacheLines))
        then allCacheLines;
    end match;
  end getAllCacheLinesOfCacheMap;

  protected function getCacheVariablesOfCacheMap "author: marcusw
    Get all cache variables that are stored in the given cache map."
    input CacheMap iCacheMap;
    output list<SimCodeVar.SimVar> oCacheVariables;
  protected
    list<SimCodeVar.SimVar> cacheVariables;
  algorithm
    oCacheVariables := match(iCacheMap)
      case(CACHEMAP(cacheVariables=cacheVariables))
        then cacheVariables;
      case(UNIFORM_CACHEMAP(cacheVariables=cacheVariables))
        then cacheVariables;
    end match;
  end getCacheVariablesOfCacheMap;

  protected function getCacheLineSizeOfCacheMap "author: marcusw
    Get the cache line size of the given cache map."
    input CacheMap iCacheMap;
    output Integer oCacheLineSize;
  protected
    Integer cacheLineSize;
  algorithm
    oCacheLineSize := match(iCacheMap)
      case(CACHEMAP(cacheLineSize=cacheLineSize))
        then cacheLineSize;
      case(UNIFORM_CACHEMAP(cacheLineSize=cacheLineSize))
        then cacheLineSize;
    end match;
  end getCacheLineSizeOfCacheMap;

annotation(__OpenModelica_Interface="backend");
end HpcOmMemory;
