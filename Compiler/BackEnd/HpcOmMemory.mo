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
  protected import BaseHashTable;
  protected import ComponentReference;
  protected import Debug;
  protected import Expression;
  protected import Flags;
  protected import GraphML;
  protected import List;
  protected import SimCodeUtil;
  protected import Util;

  // -------------------------------------------
  // STRUCTURES
  // -------------------------------------------

  protected uniontype CacheMap
    //CacheMap that stores variables of same type in the same array (different arrays for bool, float and int vars)
    record CACHEMAP
      Integer cacheLineSize; //cache line size in bytes
      list<SimCodeVar.SimVar> cacheVariables; //all variables that are stored in the cache
      list<CacheLineMap> cacheLinesFloat;
      //list<CacheLineMap> cacheLinesBool;
      //list<CacheLineMap> cacheLinesInt;
    end CACHEMAP;
    //CacheMap that stores variables of different types in the same array
    record UNIFORM_CACHEMAP
      Integer cacheLineSize; //cache line size in bytes
      list<SimCodeVar.SimVar> cacheVariables; //all variables that are stored in the cache
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
      Integer dataType; //1 = float, 2 = int, 3 = bool
      Integer size;
      Integer scVarIdx; //see CacheMap.cacheVariables
    end CACHELINEENTRY;
  end CacheLineEntry;

  protected uniontype CacheMapMeta
    record CACHEMAPMETA
      array<Option<SimCodeVar.SimVar>> allSCVarsMapping;
      array<tuple<Integer, Integer>> simCodeVarTypes; //<type, numberOfBytesRequired>
      array<tuple<Integer, Integer>> scVarCLMapping; //mapping for each scVar -> <CLIdx,varType>
    end CACHEMAPMETA;
  end CacheMapMeta;

  // -------------------------------------------
  // FUNCTIONS
  // -------------------------------------------

  public function createMemoryMap
    "author: marcusw
     Creates a MemoryMap which contains informations about an optimized memory alignment and append the informations to the given TaskGraph."
    input SimCode.ModelInfo iModelInfo;
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input BackendDAE.EqSystems iEqSystems;
    input String iFileNamePrefix;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input HpcOmSimCode.Schedule iSchedule;
    input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
    input list<list<Integer>> iCriticalPaths;
    input list<list<Integer>> iCriticalPathsWoC;
    input String iCriticalPathInfo;
    input BackendDAE.StrongComponents iAllComponents;
    output Option<HpcOmSimCode.MemoryMap> oMemoryMap;
  protected
    SimCodeVar.SimVars simCodeVars;
    list<SimCodeVar.SimVar> stateVars, derivativeVars, algVars, paramVars, aliasVars;
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
  algorithm
    oMemoryMap := matchcontinue(iModelInfo, iTaskGraph, iTaskGraphMeta, iEqSystems, iFileNamePrefix, iSchedulerInfo, iSchedule, iSccSimEqMapping, iCriticalPaths, iCriticalPathsWoC, iCriticalPathInfo, iAllComponents)
      case(_,_,_,_,_,_,_,_,_,_,_,_)
        equation
          true = Flags.isSet(Flags.HPCOM_MEMORY_OPT);
          //HpcOmTaskGraph.printTaskGraphMeta(iTaskGraphMeta);
          //Create var hash table
          SimCode.MODELINFO(vars=simCodeVars) = iModelInfo;
          SimCodeVar.SIMVARS(stateVars=stateVars, derivativeVars=derivativeVars, algVars=algVars, paramVars=paramVars, aliasVars=aliasVars) = simCodeVars;
          allVarsMapping = SimCodeUtil.createIdxSCVarMapping(simCodeVars);
          //SimCodeUtil.dumpIdxScVarMapping(allVarsMapping);
          //print("--------------------------------\n");
          hashTable = HashTableCrILst.emptyHashTableSized(BaseHashTable.biggerBucketSize);
          hashTable = fillSimVarHashTable(stateVars,0,0,hashTable);
          hashTable = fillSimVarHashTable(derivativeVars,listLength(stateVars),0,hashTable);
          hashTable = fillSimVarHashTable(algVars,listLength(stateVars) + listLength(stateVars),0,hashTable);
          //hashTable = fillSimVarHashTable(paramVars,listLength(stateVars)*2 + listLength(algVars),0,hashTable);
          //print("-------------------------------------\n");
          //BaseHashTable.dumpHashTable(hashTable);
          //Create CacheMap
          sccNodeMapping = HpcOmTaskGraph.getSccNodeMapping(arrayLength(iSccSimEqMapping), iTaskGraphMeta);
          //printSccNodeMapping(sccNodeMapping);
          scVarTaskMapping = getSimCodeVarNodeMapping(iTaskGraphMeta,iEqSystems,listLength(stateVars)*2+listLength(algVars),sccNodeMapping,hashTable);
          //printScVarTaskMapping(scVarTaskMapping);
          //print("-------------------------------------\n");
          nodeSimCodeVarMapping = getNodeSimCodeVarMapping(iTaskGraphMeta, iEqSystems, hashTable);
          //printNodeSimCodeVarMapping(nodeSimCodeVarMapping);
          //print("-------------------------------------\n");
          (cacheMap,scVarCLMapping,numCL) = createCacheMapOptimized(allVarsMapping,stateVars,derivativeVars,algVars,paramVars,scVarTaskMapping,64,iAllComponents,iSchedule, nodeSimCodeVarMapping);
          eqSimCodeVarMapping = getEqSCVarMapping(iEqSystems,hashTable);
          (clTaskMapping,scVarTaskMapping) = getCacheLineTaskMapping(iTaskGraphMeta,iEqSystems,hashTable,numCL,scVarCLMapping);

          //Get not optimized variables
          //---------------------------
          notOptimizedVars = getNotOptimizedVarsByCacheLineMapping(scVarCLMapping, allVarsMapping);
          //notOptimizedVars = listAppend(notOptimizedVars, aliasVars);
          Debug.bcall(Flags.isSet(Flags.HPCOM_DUMP), print, "Not optimized vars:\n\t");
          Debug.bcall(Flags.isSet(Flags.HPCOM_DUMP), print, stringDelimitList(List.map(notOptimizedVars, dumpSimCodeVar), ",") +& "\n");

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
          fileName = ("taskGraph"+&iFileNamePrefix+&"ODE_schedule_CL.graphml");
          GraphML.dumpGraph(graphInfo, fileName);
          tmpMemoryMap = convertCacheMapToMemoryMap(cacheMap,hashTable,notOptimizedVars);
          //print cache map
          Debug.bcall(Flags.isSet(Flags.HPCOM_DUMP), printCacheMap, cacheMap);
        then SOME(tmpMemoryMap);
      case(_,_,_,_,_,_,_,_,_,_,_,_)
        equation
          true = Flags.isSet(Flags.HPCOM_MEMORY_OPT);
          print("CreateMemoryMap failed!\n");
        then NONE();
      else
        then NONE();
    end matchcontinue;
  end createMemoryMap;

  protected function createCacheMapOptimized "author: marcusw
     Creates a CacheMap optimized for the selected scheduler. All variables that are part of the created cache map are marked with 1 in the iVarMark-array."
    input array<Option<SimCodeVar.SimVar>> iAllSCVarsMapping;
    input list<SimCodeVar.SimVar> iStateVars; //float
    input list<SimCodeVar.SimVar> iDerivativeVars; //float
    input list<SimCodeVar.SimVar> iAlgVars; //float
    input list<SimCodeVar.SimVar> iParamVars; //float
    input array<Integer> iScVarTaskMapping;
    input Integer iCacheLineSize;
    input BackendDAE.StrongComponents iAllComponents;
    input HpcOmSimCode.Schedule iSchedule;
    input array<list<Integer>> iNodeSimCodeVarMapping;
    output CacheMap oCacheMap;
    output array<tuple<Integer,Integer>> oScVarCLMapping; //mapping for each scVar -> CLIdx
    output Integer oNumCL;
  protected
    CacheMap cacheMap;
    array<tuple<Integer,Integer>> scVarCLMapping;
    Integer numCL;
    list<HpcOmSimCode.TaskList> tasksOfLevels;
    array<tuple<Integer,Integer>> simCodeVarTypes;
  algorithm
    (oCacheMap,oScVarCLMapping,oNumCL) := match(iAllSCVarsMapping,iStateVars,iDerivativeVars,iAlgVars,iParamVars,iScVarTaskMapping,iCacheLineSize,iAllComponents,iSchedule, iNodeSimCodeVarMapping)
      case(_,_,_,_,_,_,_,_,HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevels),_)
        equation
          simCodeVarTypes = arrayCreate(listLength(iStateVars) + listLength(iDerivativeVars) + listLength(iAlgVars) + listLength(iParamVars), (1,8));
          (cacheMap,scVarCLMapping,numCL) = createCacheMapLevelOptimized(iAllSCVarsMapping,simCodeVarTypes,iScVarTaskMapping,iCacheLineSize,iAllComponents,tasksOfLevels,iNodeSimCodeVarMapping);
        then (cacheMap,scVarCLMapping,numCL);
      else
        equation
          print("No optimized cache map for the selected scheduler avaiable. Using default cacheMap!\n");
          (cacheMap,scVarCLMapping,numCL) = createCacheMapDefault(iAllSCVarsMapping,iCacheLineSize);
        then (cacheMap,scVarCLMapping,numCL);
     end match;
  end createCacheMapOptimized;

  protected function appendParamsToCacheMap "author: marcusw
    Append all parameters to new cachelines (dense) at the end of the cachemap."
    input CacheMap iCacheMap;
    input Integer iNumCL;
    input list<SimCodeVar.SimVar> iParamVars;
    input CacheMapMeta iCacheMapMeta;
    output CacheMap oCacheMap;
    output CacheMapMeta oCacheMapMeta;
    output Integer oNumCL;
  algorithm
    ((oCacheMap,oCacheMapMeta,oNumCL,_)) := List.fold(iParamVars, appendParamToCacheMap, (iCacheMap, iCacheMapMeta, iNumCL, {}));
  end appendParamsToCacheMap;

  protected function appendParamToCacheMap "author: marcusw
    Append all parameters to new cachelines at the end of the cachemap."
    input SimCodeVar.SimVar iParamVar;
    input tuple<CacheMap, CacheMapMeta, Integer, list<tuple<Integer, Integer>>> iCacheInfoTpl; //<CacheMap, CacheMapMeta, numCL, cacheLineCandidates
    output tuple<CacheMap, CacheMapMeta, Integer, list<tuple<Integer, Integer>>> oCacheInfoTpl;
  protected
    Integer index, tmpNumNewCL;
    CacheMap tmpCacheMap;
    CacheMapMeta tmpCacheMapMeta;
    list<tuple<Integer, Integer>> tmpCacheLineCandidates, detailedWrittenCacheLines;
    list<Integer> tmpWrittenCLs;
    Integer cacheLineSize;
    list<CacheLineMap> cacheLinesFloat;
  algorithm
    oCacheInfoTpl := match(iParamVar, iCacheInfoTpl)
      case(SimCodeVar.SIMVAR(index=index),(tmpCacheMap, tmpCacheMapMeta, tmpNumNewCL, tmpCacheLineCandidates))
        equation
          ((tmpCacheMap as CACHEMAP(cacheLinesFloat=cacheLinesFloat,cacheLineSize=cacheLineSize),tmpCacheMapMeta,tmpNumNewCL,tmpCacheLineCandidates,tmpWrittenCLs,_)) = appendSCVarToCacheMap(index,(tmpCacheMap,tmpCacheMapMeta,0,{},{},1));
          detailedWrittenCacheLines = createDetailedCacheMapInformations(tmpWrittenCLs,cacheLinesFloat,cacheLineSize);
          tmpCacheLineCandidates = listAppend(tmpCacheLineCandidates, detailedWrittenCacheLines);
        then ((tmpCacheMap,tmpCacheMapMeta,tmpNumNewCL,tmpCacheLineCandidates));
      else
        equation
          print("HpcOmMemory.appendParamToCacheMap failed!\n");
      then iCacheInfoTpl;
    end match;
  end appendParamToCacheMap;

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
    cacheMap := CACHEMAP(iCacheLineSize,{},{});
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
    //print("createCacheMapLevelOptimized0: Handling new level. CL used by previous layer: " +& stringDelimitList(List.map(cacheLinesPrevLevel,intString), ",") +& " Number of CL: " +& intString(numCL) +& "\n");
    availableCLold := List.setDifferenceIntN(allCL,cacheLinesPrevLevel,numCL);
    //append free space to available cache lines and remove full cache lines
    detailedCacheLineInfo := createDetailedCacheMapInformations(availableCLold, cacheLinesFloat, cacheLineSize);
    detailedCacheLineInfo := listReverse(detailedCacheLineInfo);
    //print("createCacheMapLevelOptimized0: clCandidates: " +& stringDelimitList(List.map(List.map(detailedCacheLineInfo,Util.tuple21),intString), ",") +& "\n");
    ((cacheMap,cacheMapMeta,createdCL,detailedCacheLineInfo)) := List.fold1(getTaskListTasks(iLevelTasks), createCacheMapLevelOptimizedForTask, iNodeSimCodeVarMapping, (cacheMap,cacheMapMeta, 0,detailedCacheLineInfo));
    availableCL := List.map(detailedCacheLineInfo, Util.tuple21);
    //append the used cachelines to the writtenCL-list
    //print("createCacheMapLevelOptimized0: New cacheLines created: " +& intString(createdCL) +& "\n");
    writtenCL := List.setDifferenceIntN(availableCLold,availableCL,numCL);
    //print("createCacheMapLevelOptimized0: Written CL_0: " +& stringDelimitList(List.map(writtenCL,intString), ",") +& " -- numCL: " +& intString(numCL) +& "\n");
    writtenCL := listAppend(writtenCL, Util.if_(intLe(numCL+1, numCL+createdCL), List.intRange2(numCL+1, numCL+createdCL), {}));
    //print("createCacheMapLevelOptimized0: Written CL_1: " +& stringDelimitList(List.map(writtenCL,intString), ",") +& "\n");
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
          tmpInfo = List.fold1(nodeIdc, appendNodeVarsToCacheMap, iNodeSimCodeVarMapping, iInfo);
        then tmpInfo;
      else
        equation
          print("createCacheMapLevelOptimized1: Unsupported task type\n");
        then fail();
    end match;
  end createCacheMapLevelOptimizedForTask;

  protected function createCacheMapDefault "author: marcusw
    Create a default cacheMap without optimization."
    input array<Option<SimCodeVar.SimVar>> iAllSCVars;
    input Integer iCacheLineSize;
    output CacheMap oCacheMap;
    output array<tuple<Integer,Integer>> oScVarCLMapping; //mapping for each scVar -> CLIdx
    output Integer oNumCL;
  protected
    list<SimCodeVar.SimVar> iAllFloatVars;
    list<CacheLineMap> cacheLineFloatMaps;
    array<tuple<Integer,Integer>> tmpScVarCLMapping;
  algorithm
    oCacheMap := CACHEMAP(iCacheLineSize,{},{});
    oNumCL := 0;
    oScVarCLMapping := arrayCreate(0, (-1,-1));
  end createCacheMapDefault;

  protected function appendNodeVarsToCacheMap "author: marcusw
    Append the variables that are solved by the given node to the cachelines. The used CL are removed from the candidate list."
    input Integer iNodeIdx;
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
    //print("appendNodeVarsToCacheMap: Handling node " +& intString(iNodeIdx) +& " clCandidates: " +& intString(listLength(clCandidates)) +& " simCodeVars: " +& varsString +& "\n");
    ((iCacheMap, iCacheMapMeta, iNumNewCL,clCandidates,writtenCL,_)) := List.fold(simCodeVars, appendSCVarToCacheMap, (iCacheMap, iCacheMapMeta, iNumNewCL,clCandidates,{},1));
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
    input tuple<CacheMap, CacheMapMeta, Integer, list<tuple<Integer,Integer>>, list<Integer>, Integer> iInfo; //<CacheMap, CacheMapMeta, numNewCL, cacheLineCandidates <ClIdx,freeBytes>, writtenCL, currentCLCandidate>
    output tuple<CacheMap, CacheMapMeta, Integer, list<tuple<Integer,Integer>>, list<Integer>, Integer> oInfo;
  protected
    array<Option<SimCodeVar.SimVar>> iAllSCVarsMapping;
    array<tuple<Integer,Integer>> iSimCodeVarTypes; //<type, numberOfBytesRequired>
    array<tuple<Integer,Integer>> iScVarCLMapping; //will be updated: mapping scVar (arrayIdx) -> <clIdx,varType>
    Integer currentCLCandidateIdx, currentCLCandidateCLIdx, clIdx, currentCLCandidateFreeBytes, cacheLineSize, numNewCL, varType, numBytesRequired, entryStart;
    tuple<Integer,Integer> currentCLCandidate;
    list<tuple<Integer,Integer>> cacheLineCandidates;
    list<CacheLineMap> cacheLinesFloat;
    list<SimCodeVar.SimVar> cacheVariables;
    CacheLineMap cacheLine;
    list<CacheLineEntry> CLentries;
    SimCodeVar.SimVar scVar;
    Integer numCacheVars, freeSpace;
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    list<Integer> writtenCL;
    String varText;
    tuple<CacheMap, CacheMapMeta, Integer, list<tuple<Integer,Integer>>, list<Integer>, Integer> tmpInfo;
  algorithm
    oInfo := matchcontinue(iSCVarIdx, iInfo)
      case(_,(cacheMap as CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat), cacheMapMeta as CACHEMAPMETA(iAllSCVarsMapping, iSimCodeVarTypes, iScVarCLMapping), numNewCL, cacheLineCandidates, writtenCL, currentCLCandidateIdx))
        equation //case 1: current CL-candidate has enough space to store variable
          true = intGe(listLength(cacheLineCandidates), currentCLCandidateIdx);
          currentCLCandidate = listGet(cacheLineCandidates, currentCLCandidateIdx);
          ((varType,numBytesRequired)) = arrayGet(iSimCodeVarTypes,iSCVarIdx);
          true = doesSCVarFitIntoCL(currentCLCandidate, numBytesRequired);
          //print("  -- candidateCL has enough space\n");
          (currentCLCandidateCLIdx,currentCLCandidateFreeBytes) = currentCLCandidate;
          //print("appendSCVarToCacheMap scVarIdx: " +& intString(iSCVarIdx) +& "\n");
          //print("  -- CachelineCandidates: " +& intString(listLength(cacheLineCandidates)) +& " currentCLCandidateidx: " +& intString(currentCLCandidateIdx) +& " with " +& intString(currentCLCandidateFreeBytes) +& "free bytes\n");
          cacheLine = listGet(cacheLinesFloat, listLength(cacheLinesFloat) - currentCLCandidateCLIdx + 1);
          CACHELINEMAP(idx=clIdx,entries=CLentries) = cacheLine;
          //print("  -- writing to CL " +& intString(clIdx) +& " (free bytes: " +& intString(currentCLCandidateFreeBytes) +& ")\n");
          //write new cache lines
          entryStart = cacheLineSize-currentCLCandidateFreeBytes;
          numCacheVars = listLength(cacheVariables)+1;
          CLentries = CACHELINEENTRY(entryStart,varType, numBytesRequired, numCacheVars)::CLentries;
          cacheLine = CACHELINEMAP(clIdx,CLentries);
          cacheLinesFloat = List.set(cacheLinesFloat, listLength(cacheLinesFloat) - currentCLCandidateCLIdx + 1, cacheLine);
          //update scVarCL-Mapping
          iScVarCLMapping = arrayUpdate(iScVarCLMapping,iSCVarIdx,(clIdx,varType));
          //append variable
          SOME(scVar) = arrayGet(iAllSCVarsMapping,iSCVarIdx);

          //varText = Tpl.textString(SimCodeDump.dumpVars(Tpl.emptyTxt, {scVar}, false));
          //print("  appendSCVarToCacheMap: Handling variable " +& intString(iSCVarIdx) +& " | " +& varText +& "\n");

          cacheVariables = scVar::cacheVariables;
          writtenCL = clIdx::writtenCL;
          //write candidate list
          currentCLCandidate = (currentCLCandidateCLIdx,currentCLCandidateFreeBytes-numBytesRequired);
          cacheLineCandidates = List.set(cacheLineCandidates, currentCLCandidateIdx, currentCLCandidate);
          cacheMap = CACHEMAP(cacheLineSize,cacheVariables,cacheLinesFloat);
          cacheMapMeta = CACHEMAPMETA(iAllSCVarsMapping, iSimCodeVarTypes, iScVarCLMapping);
          //printCacheMap(cacheMap);
          //print("  appendSCVarToCacheMap: Done\n");
        then ((cacheMap, cacheMapMeta, numNewCL, cacheLineCandidates, writtenCL, currentCLCandidateIdx));
      case(_,(cacheMap as CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat), cacheMapMeta as CACHEMAPMETA(iAllSCVarsMapping, iSimCodeVarTypes, iScVarCLMapping), numNewCL, cacheLineCandidates, writtenCL, currentCLCandidateIdx))
        equation //case 2: current CL-candidate has not enough space to store variable
          true = intGe(listLength(cacheLineCandidates), currentCLCandidateIdx);
          ((varType,numBytesRequired)) = arrayGet(iSimCodeVarTypes,iSCVarIdx);
          tmpInfo = appendSCVarToCacheMap(iSCVarIdx, (cacheMap, cacheMapMeta, numNewCL,cacheLineCandidates,writtenCL,currentCLCandidateIdx+1));
        then tmpInfo;
      case(_,(cacheMap as CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat), CACHEMAPMETA(iAllSCVarsMapping, iSimCodeVarTypes, iScVarCLMapping), numNewCL, cacheLineCandidates, writtenCL, currentCLCandidateIdx))
        equation //case 3: no CL-candidates available
          //print("--appendSCVarToCacheMap: Handling variable " +& intString(iSCVarIdx) +& "\n");

          ((varType,numBytesRequired)) = arrayGet(iSimCodeVarTypes,iSCVarIdx);
          entryStart = 0;
          numCacheVars = listLength(cacheVariables)+1;
          CLentries = {CACHELINEENTRY(entryStart,varType, numBytesRequired, numCacheVars)};
          clIdx = listLength(cacheLinesFloat) + 1;
          cacheLine = CACHELINEMAP(clIdx,CLentries);
          cacheLinesFloat = cacheLine::cacheLinesFloat;
          //update scVarCL-Mapping
          iScVarCLMapping = arrayUpdate(iScVarCLMapping,iSCVarIdx,(clIdx,varType));
          //append variable
          SOME(scVar) = arrayGet(iAllSCVarsMapping,iSCVarIdx);
          cacheVariables = scVar::cacheVariables;
          writtenCL = clIdx::writtenCL;
          freeSpace = cacheLineSize-numBytesRequired;
          //print("  -- writing new CL (idx: " +& intString(clIdx) +& "; freeSpace: " +& intString(freeSpace) +& ")\n");
          cacheLineCandidates = listAppend(cacheLineCandidates,{(clIdx,freeSpace)});
          cacheMap = CACHEMAP(cacheLineSize,cacheVariables,cacheLinesFloat);
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
          //print("createDetailedCacheMapInformations0: CacheLineIdx: " +& intString(iCacheLineIdx) +& "\n");
          cacheLineEntry = arrayGet(iCacheLinesArray, arrayLength(iCacheLinesArray) - iCacheLineIdx + 1);
          numBytesFree = iCacheLineSize-getNumOfUsedBytesByCacheLine(cacheLineEntry);
          //print("\tNumber of free bytes: " +& intString(numBytesFree) +& "\n");
          true = intGt(numBytesFree,0);
          cacheLines = (iCacheLineIdx,numBytesFree)::iCacheLines;
        then cacheLines;
      else
        then iCacheLines;
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
    Integer idx;
    list<CacheLineEntry> entries;
  algorithm
    CACHELINEMAP(idx=idx,entries=entries) := iCacheLineMap;
    entries := listReverse(entries);
    oCacheLineMap := CACHELINEMAP(idx,entries);
  end reverseCacheLineMapEntries;

  protected function convertCacheMapToMemoryMap "author: marcusw
    Convert the informations of the given cache-map to a memory-map that can be used by susan."
    input CacheMap iCacheMap;
    input HashTableCrILst.HashTable iScVarNameIdxMapping;
    input list<SimCodeVar.SimVar> iNotOptimizedVars;
    output HpcOmSimCode.MemoryMap oMemoryMap;
  protected
    Integer cacheLineSize, highestIdx, floatArraySize;
    list<SimCodeVar.SimVar> cacheVariables;
    list<CacheLineMap> cacheLinesFloat;
    HpcOmSimCode.MemoryMap tmpMemoryMap;
    array<tuple<Integer,Integer>> positionMappingArray;
    list<tuple<Integer, Integer, Integer>> positionMappingList; //<scVarIdx, arrayPosition, arrayIdx>
  algorithm
    oMemoryMap := match(iCacheMap, iScVarNameIdxMapping, iNotOptimizedVars)
      case(CACHEMAP(cacheLineSize=cacheLineSize, cacheVariables=cacheVariables, cacheLinesFloat=cacheLinesFloat), _, _)
        equation
          ((positionMappingList,highestIdx)) = List.fold4(cacheLinesFloat, convertCacheMapToMemoryMap1, iScVarNameIdxMapping, 1, cacheLineSize, cacheVariables, ({},-1));
          positionMappingArray = arrayCreate(intMax(0, highestIdx),(-1,-1));
          List.map1_0(positionMappingList, convertCacheMapToMemoryMap3, positionMappingArray);
          floatArraySize = listLength(cacheLinesFloat)*8;
          tmpMemoryMap = HpcOmSimCode.MEMORYMAP_ARRAY(positionMappingArray, floatArraySize, iScVarNameIdxMapping, {});
        then tmpMemoryMap;
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
    input Integer iArrayIdx;
    input Integer iCacheLineSize;
    input list<SimCodeVar.SimVar> iCacheVariables;
    input tuple<list<tuple<Integer, Integer, Integer>>, Integer> iPositionMappingListIdx; //<<scVarIdx, arrayPosition, arrayIdx>, highestIdx>
    output tuple<list<tuple<Integer, Integer, Integer>>, Integer> oPositionMappingListIdx; //<<scVarIdx, arrayPosition, arrayIdx>, highestIdx>
  protected
    Integer idx, highestIdx;
    list<CacheLineEntry> entries;
    list<tuple<Integer, Integer, Integer>> iPositionMappingList;
  algorithm
    oPositionMappingListIdx := match(iCacheLineMap, iScVarNameIdxMapping, iArrayIdx, iCacheLineSize, iCacheVariables, iPositionMappingListIdx)
       case(CACHELINEMAP(idx=idx,entries=entries),_,_,_,_,(iPositionMappingList, highestIdx))
        equation
          ((iPositionMappingList,highestIdx)) = List.fold4(entries, convertCacheMapToMemoryMap2, iScVarNameIdxMapping, iArrayIdx, (idx, iCacheLineSize), iCacheVariables, iPositionMappingListIdx);
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
    input list<SimCodeVar.SimVar> iCacheVariables;
    input tuple<list<tuple<Integer, Integer, Integer>>, Integer> iPositionMappingListIdx; //<<scVarIdx, arrayPosition, arrayIdx>, highestIdx>
    output tuple<list<tuple<Integer, Integer, Integer>>, Integer> oPositionMappingListIdx; //<<scVarIdx, arrayPosition, arrayIdx>, highestIdx>
  protected
    Integer clIdx, clSize;
    list<Integer> realSimVarIdxLst;
    list<tuple<Integer, Integer, Integer>> iPositionMappingList;
    Integer scVarIdx, realScVarIdx, start, size, arrayPosition, highestIdx;
    DAE.ComponentRef name;
  algorithm
    oPositionMappingListIdx := match(iCacheLineEntry, iScVarNameIdxMapping, iArrayIdx, iClIdxSize, iCacheVariables, iPositionMappingListIdx)
      case(CACHELINEENTRY(scVarIdx=scVarIdx, start=start, size=size),_,_,(clIdx, clSize),_,(iPositionMappingList,highestIdx))
        equation
          arrayPosition = intDiv(start, size);
          arrayPosition = arrayPosition + (clIdx - 1) * intDiv(clSize, size);
          SimCodeVar.SIMVAR(name=name) = listGet(iCacheVariables, listLength(iCacheVariables) - scVarIdx + 1);
          realSimVarIdxLst = BaseHashTable.get(name, iScVarNameIdxMapping);
          realScVarIdx = listGet(realSimVarIdxLst, 1) + listGet(realSimVarIdxLst, 2);
          iPositionMappingList = (realScVarIdx,arrayPosition,iArrayIdx)::iPositionMappingList;
          highestIdx = intMax(highestIdx, realScVarIdx);
          //print("convertCacheMapToMemoryMap2: " +& ComponentReference.debugPrintComponentRefTypeStr(name) +& " [" +& intString(realScVarIdx) +& "] with array-pos: " +& intString(arrayPosition) +& " | start: " +& intString(start) +& "\n");
        then ((iPositionMappingList,highestIdx));
      else
        equation
          print("convertCacheMapToMemoryMap2 failed! Unsupported entry-type\n");
        then fail();
    end match;
  end convertCacheMapToMemoryMap2;

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
  // MAPPINGS
  // -------------------------------------------

  protected function fillSimVarHashTable "author: marcusw
    Function to create a mapping for each simVar-name to the simVar-Index+Offset."
    input list<SimCodeVar.SimVar> iSimVars;
    input Integer iOffset;
    input Integer iType; //1 = real ; 2 = int
    input HashTableCrILst.HashTable iHt; //contains a list of type Integer for each simVar. List.First: Index, List.Secons: Offset, List.Third: Type
    output HashTableCrILst.HashTable oHt;
  algorithm
    oHt := List.fold2(iSimVars, fillSimVarHashTableTraverse, iOffset, iType, iHt);
  end fillSimVarHashTable;

  protected function fillSimVarHashTableTraverse "author: marcusw
    Helper function to extend the given mapping for the iSimVar."
    input SimCodeVar.SimVar iSimVar;
    input Integer iOffset;
    input Integer iType;
    input HashTableCrILst.HashTable iHt;
    output HashTableCrILst.HashTable oHt;
  protected
    Integer index;
    HashTableCrILst.HashTable tmpHt;
    DAE.ComponentRef name;
  algorithm
    SimCodeVar.SIMVAR(name=name,index=index) := iSimVar;
    index := index + 1;
    //print("fillSimVarHashTableTraverse: " +& ComponentReference.debugPrintComponentRefTypeStr(name) +& " with index: " +& intString(index+ iOffset) +& "\n");
    oHt := BaseHashTable.add((name,{index,iOffset,iType}),iHt);
  end fillSimVarHashTableTraverse;

  protected function getNodeSimCodeVarMapping "author: marcusw
    Function to create a mapping for each node to a list of simCode-variables that are solved in the task."
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input BackendDAE.EqSystems iEqSystems;
    input HashTableCrILst.HashTable iSCVarNameHashTable;
    output array<list<Integer>> oMapping;
  protected
    Integer numOfSysComps;
    array<tuple<Integer,Integer,Integer>> varCompMapping;
    array<list<Integer>> inComps;
    array<list<Integer>> tmpMapping;
    array<Integer> iCompNodeMapping;
  algorithm
    HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,varCompMapping=varCompMapping) := iTaskGraphMeta;
    numOfSysComps := List.fold(iEqSystems, HpcOmTaskGraph.getNumberOfEqSystemComponents, 0);
    iCompNodeMapping := HpcOmTaskGraph.getSccNodeMapping(numOfSysComps, iTaskGraphMeta);
    tmpMapping := arrayCreate(arrayLength(inComps),{});
    ((oMapping,_)) := Array.fold3(varCompMapping, getNodeSimCodeVarMapping0, iCompNodeMapping, iEqSystems, iSCVarNameHashTable, (tmpMapping,1));
  end getNodeSimCodeVarMapping;

  protected function getNodeSimCodeVarMapping0 "author: marcusw
    Append the mapping with the node that solves the simcode-variable that corresponds to the varIdx."
    input tuple<Integer,Integer,Integer> iVarCompMapping; //<compIdx,eqSysIdx,offset>
    input array<Integer> iCompNodeMapping; //Mapping Component -> Node
    input BackendDAE.EqSystems iEqSystems;
    input HashTableCrILst.HashTable iSCVarNameHashTable;
    input tuple<array<list<Integer>>,Integer> iMappingVarIdxTpl; //<mapping,varIdx>
    output tuple<array<list<Integer>>,Integer> oMappingVarIdxTpl;
  protected
    Integer nodeIdx,compIdx,eqSysIdx,varIdx,scVarOffset,scVarIdx;
    BackendDAE.EqSystem eqSystem;
    DAE.ComponentRef varName;
    BackendDAE.Var var;
    BackendDAE.Variables orderedVars;
    BackendDAE.VariableArray varArr;
    array<Option<BackendDAE.Var>> varOptArr;
    array<list<Integer>> iMapping;
    list<Integer> scVarValues,tmpMapping;
  algorithm
    oMappingVarIdxTpl := matchcontinue(iVarCompMapping,iCompNodeMapping,iEqSystems,iSCVarNameHashTable,iMappingVarIdxTpl)
      case((compIdx,eqSysIdx,_),_,_,_,(iMapping,varIdx))
        equation
          nodeIdx = arrayGet(iCompNodeMapping, compIdx);
          true = intGe(nodeIdx,0);
          //print("getNodeSimCodeVarMapping0: compIdx: " +& intString(compIdx) +& " -> nodeIdx: " +& intString(nodeIdx) +& "\n");
          eqSystem = listGet(iEqSystems,eqSysIdx);
          BackendDAE.EQSYSTEM(orderedVars=orderedVars) = eqSystem;
          BackendDAE.VARIABLES(varArr=varArr) = orderedVars;
          BackendDAE.VARIABLE_ARRAY(varOptArr=varOptArr) = varArr;
          SOME(var) = arrayGet(varOptArr,varIdx);
          BackendDAE.VAR(varName=varName) = var;
          varName = getModifiedVarName(var);
          //print("  getNodeSimCodeVarMapping0: varIdx: " +& intString(varIdx) +& " (" +& ComponentReference.printComponentRefStr(varName) +& ")\n");
          scVarValues = BaseHashTable.get(varName,iSCVarNameHashTable);
          scVarIdx = List.first(scVarValues);
          scVarOffset = List.second(scVarValues);
          scVarIdx = scVarIdx + scVarOffset;
          //print("  getNodeSimCodeVarMapping0: scVarIdx: " +& intString(scVarIdx) +& " (including scVarOffset: " +& intString(scVarOffset) +& ")\n");
          //print("getNodeSimCodeVarMapping0: NodeIdx = " +& intString(nodeIdx) +& " mappingLength: " +& intString(arrayLength(iMapping)) +& "\n");
          tmpMapping = arrayGet(iMapping,nodeIdx);
          tmpMapping = scVarIdx :: tmpMapping;
          iMapping = arrayUpdate(iMapping,nodeIdx,tmpMapping);
        then ((iMapping,varIdx+1));
      case((compIdx,eqSysIdx,_),_,_,_,(iMapping,varIdx))
        equation
          nodeIdx = arrayGet(iCompNodeMapping, compIdx);
          false = intGe(nodeIdx,0);
        then ((iMapping,varIdx+1));
      case(_,_,_,_,(iMapping,varIdx))
        equation
          print("getNodeSimCodeVarMapping0: Failed to find scVar for varIdx " +& intString(varIdx) +& "\n");
        then ((iMapping,varIdx+1));
    end matchcontinue;
  end getNodeSimCodeVarMapping0;

  protected function getEqSCVarMapping "author: marcusw
    Create a mapping for all eqSystems to the solved equations to a list of variables that are solved inside the equation."
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
    //print("getEqSCVarMapping0: Handling equation:\n" +& BackendDump.equationString(iEquation) +& "\n");
    (_,(_,(_,oMapping))) := BackendEquation.traverseBackendDAEExpsEqn(iEquation,Expression.traverseSubexpressionsHelper, (createMemoryMapTraverse0, (iHt,{})));
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
          //print("createMemoryMapTraverse0 " +& intString(varIdx) +& "\n");
          //print("HpcOmSimCode.createMemoryMapTraverse: Found ref " +& ComponentReference.printComponentRefStr(componentRef) +& " with Index: " +& intString(varIdx) +& "\n");
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
          BackendDAE.VARIABLES(varArr=varArr) = orderedVars;
          BackendDAE.VARIABLE_ARRAY(varOptArr=varOptArr) = varArr;
          SOME(var) = arrayGet(varOptArr,varIdx-varOffset);
          BackendDAE.VAR(varName=varName) = var;
          varName = getModifiedVarName(var);
          scVarValues = BaseHashTable.get(varName,iVarNameSCVarIdxMapping);
          varNameString = ComponentReference.printComponentRefStr(varName);
          //print("getSimCodeVarNodeMapping0: SCC-Idx: " +& intString(compIdx) +& " name: " +& varNameString +& "\n");
          scVarIdx = List.first(scVarValues);
          scVarOffset = List.second(scVarValues);
          scVarIdx = scVarIdx + scVarOffset;
          nodeIdx = arrayGet(iCompNodeMapping, compIdx);
          //oldVal = arrayGet(iClTaskMapping,clIdx);
          //print("getCacheLineTaskMadumpComponentReferencepping0 scVarIdx: " +& intString(scVarIdx) +& "\n");
          iScVarTaskMapping = arrayUpdate(iScVarTaskMapping,scVarIdx,nodeIdx);
          //print("Variable " +& intString(varIdx) +& " (" +& ComponentReference.printComponentRefStr(varName) +& ") [SC-Var " +& intString(scVarIdx) +& "]: Node " +& intString(nodeIdx) +& "\n---------------------\n");
          //print("Part of CL " +& intString(clIdx) +& " solved by node " +& intString(nodeIdx) +& "\n\n");
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
          BackendDAE.VARIABLES(varArr=varArr) = orderedVars;
          BackendDAE.VARIABLE_ARRAY(varOptArr=varOptArr) = varArr;
          SOME(var) = arrayGet(varOptArr,varIdx-varOffset);
          BackendDAE.VAR(varName=varName) = var;
          varName = getModifiedVarName(var);
          scVarValues = BaseHashTable.get(varName,iVarNameSCVarIdxMapping);
          scVarIdx = List.first(scVarValues);
          scVarOffset = List.second(scVarValues);
          scVarIdx = scVarIdx + scVarOffset;
          ((clIdx,_)) = arrayGet(iSCVarCLMapping,scVarIdx);
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
    list<SimCodeVar.SimVar> cacheVariables;
    list<CacheLineMap> cacheLinesFloat;
    CacheMap cacheMap;
  algorithm
    oGraphInfo := matchcontinue(iCacheMap,iNumberOfNodes,iNodeSimCodeVarMapping,iEqSimCodeVarMapping,iEqSystems,iVarNameSCVarIdxMapping,ieqCompMapping,iScVarTaskMapping,iSchedulerInfo,iAttributeIdc,iCompNodeMapping,iGraphInfo)
      case(cacheMap as CACHEMAP(cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat),_,_,_,_,_,_,_,_,_,_,GraphML.GRAPHINFO(graphCount=graphCount))
        equation
          true = intLe(1, graphCount);
          knownEdges = arrayCreate(iNumberOfNodes,{});
          (tmpGraphInfo,(_,_),(_,clGroupNodeIdx)) = GraphML.addGroupNode("CL_GoupNode", 1, false, "CL", iGraphInfo);
          tmpGraphInfo = List.fold5(cacheLinesFloat, appendCacheLineMapToGraph, cacheVariables, iSchedulerInfo, (clGroupNodeIdx,iAttributeIdc), iScVarTaskMapping, iVarNameSCVarIdxMapping, tmpGraphInfo);
          //((_,knownEdges,tmpGraphInfo)) = Array.fold3(arrayGet(iEqSimCodeVarMapping,1), appendCacheLineEdgesToGraphTraverse, ieqCompMapping, iCompNodeMapping, iScVarTaskMapping, (1,knownEdges,tmpGraphInfo));
          ((_,tmpGraphInfo)) = Array.fold(iNodeSimCodeVarMapping, appendCacheLineEdgeToGraphSolvedVar, (1,tmpGraphInfo));
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
    input tuple<Integer,GraphML.GraphInfo> iIdxGraphInfo;
    output tuple<Integer,GraphML.GraphInfo> oIdxGraphInfo;
  protected
    Integer nodeIdx;
    GraphML.GraphInfo graphInfo;
    String edgeId, targetId, sourceId;
  algorithm
    (nodeIdx,graphInfo) := iIdxGraphInfo;
    ((_,graphInfo)) := List.fold(iNodeSCVars, appendCacheLineEdgeToGraphSolvedVar0, (nodeIdx,graphInfo));
    oIdxGraphInfo := (nodeIdx+1,graphInfo);
  end appendCacheLineEdgeToGraphSolvedVar;

  protected function appendCacheLineEdgeToGraphSolvedVar0
    input Integer iVarIdx;
    input tuple<Integer,GraphML.GraphInfo> iNodeIdxGraphInfo;
    output tuple<Integer,GraphML.GraphInfo> oNodeIdxGraphInfo;
  protected
    GraphML.GraphInfo graphInfo;
    Integer nodeIdx;
    String edgeId, targetId, sourceId;
  algorithm
    oNodeIdxGraphInfo := matchcontinue(iVarIdx, iNodeIdxGraphInfo)
      case(_,(nodeIdx, graphInfo))
        equation
          true = intGt(iVarIdx,0);
          //print("appendCacheLineEdgeToGraphSolvedVar0: NodeIdx=" +& intString(nodeIdx) +& " varIdx=" +& intString(iVarIdx) +& "\n");
          sourceId = "Node" +& intString(nodeIdx);
          targetId = "CL_Var" +& intString(iVarIdx);
          edgeId = "edge_CL_" +& sourceId +& "_" +& targetId;
          (graphInfo,(_,_)) = GraphML.addEdge(edgeId, targetId, sourceId, GraphML.COLOR_GRAY, GraphML.DASHED(), GraphML.LINEWIDTH_STANDARD, true, {}, (GraphML.ARROWNONE(),GraphML.ARROWNONE()), {}, graphInfo);
        then ((nodeIdx,graphInfo));
      else iNodeIdxGraphInfo;
    end matchcontinue;
  end appendCacheLineEdgeToGraphSolvedVar0;

  protected function appendCacheLineMapToGraph
    input CacheLineMap iCacheLineMap;
    input list<SimCodeVar.SimVar> iCacheVariables;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input tuple<Integer,Integer> iTopGraphAttThreadIdIdx; //<topGraphIdx,threadIdAttIdx>
    input array<Integer> iScVarTaskMapping; //maps each scVar (arrayIdx) to the task that solves her
    input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
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
    oGraphInfo := List.fold5(entries, appendCacheLineEntryToGraph, iCacheVariables, iSchedulerInfo, (graphIdx,iAttThreadIdIdx), iScVarTaskMapping, iVarNameSCVarIdxMapping, tmpGraphInfo);
  end appendCacheLineMapToGraph;

  protected function appendCacheLineEntryToGraph
    input CacheLineEntry iCacheLineEntry;
    input list<SimCodeVar.SimVar> iCacheVariables;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input tuple<Integer,Integer> iTopGraphAttThreadIdIdx; //<topGraphIdx,threadIdAttIdx>
    input array<Integer> iScVarTaskMapping; //maps each scVar (arrayIdx) to the task that solves her
    input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
    input GraphML.GraphInfo iGraphInfo;
    output GraphML.GraphInfo oGraphInfo;
  protected
    list<Integer> realScVarIdxOffset;
    Integer scVarIdx, realScVarIdx, realScVarOffset, taskIdx, iTopGraphIdx, iAttThreadIdIdx;
    String varString, threadText, nodeLabelText, nodeId;
    GraphML.NodeLabel nodeLabel;
    SimCodeVar.SimVar iVar;
    DAE.ComponentRef name;
  algorithm
    CACHELINEENTRY(scVarIdx=scVarIdx) := iCacheLineEntry;
    (iTopGraphIdx, iAttThreadIdIdx) := iTopGraphAttThreadIdIdx;
    iVar := listGet(iCacheVariables, listLength(iCacheVariables) - scVarIdx + 1);
    SimCodeVar.SIMVAR(name=name) := iVar;
    realScVarIdxOffset := BaseHashTable.get(name, iVarNameSCVarIdxMapping);
    realScVarIdx := listGet(realScVarIdxOffset,1);
    realScVarOffset := listGet(realScVarIdxOffset,2);
    realScVarIdx := realScVarIdx + realScVarOffset;
    varString := ComponentReference.printComponentRefStr(name);
    taskIdx := arrayGet(iScVarTaskMapping,realScVarIdx);
    //print("HpcOmSimCode.appendCacheLineNodesToGraphTraverse SCVarNode: " +& intString(realScVarIdx) +& " [" +& varString +& "] taskIdx: " +& intString(taskIdx) +& "\n");
    nodeId := "CL_Var" +& intString(realScVarIdx);
    threadText := appendCacheLineNodesToGraphTraverse0(taskIdx,iSchedulerInfo);
    nodeLabelText := intString(realScVarIdx);
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


  // -------------------------------------------
  // PRINT
  // -------------------------------------------

  protected function printCacheMap
    input CacheMap iCacheMap;
  protected
    Integer cacheLineSize;
    list<CacheLineMap> cacheLinesFloat;
    list<SimCodeVar.SimVar> cacheVariables;
  algorithm
    print("\n\nCacheMap\n---------------\n");
    CACHEMAP(cacheLineSize=cacheLineSize, cacheVariables=cacheVariables, cacheLinesFloat=cacheLinesFloat) := iCacheMap;
    List.map1_0(cacheLinesFloat, printCacheLineMap, cacheVariables);
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
    print("  CacheLineMap " +& intString(idx) +& " (" +& intString(listLength(entries)) +& " entries)\n");
    ((iVarsString, iBytesString)) := List.fold1(entries, cacheLineEntryToString, iCacheVariables, ("",""));
    print("    " +& iVarsString +& "\n");
    print("    " +& iBytesString +& "\n");
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
    print("  CacheLineMap " +& intString(idx) +& " (" +& intString(listLength(entries)) +& " entries)\n");
    ((iVarsString, iBytesString)) := List.fold(entries, cacheLineEntryToStringClean, ("",""));
    print("    " +& iVarsString +& "\n");
    print("    " +& iBytesString +& "\n");
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
    iVar := listGet(iCacheVariables, listLength(iCacheVariables) - scVarIdx + 1);
    scVarStr := dumpSimCodeVar(iVar);
    iVarsString := iVarsString +& "| " +& scVarStr +& " ";
    iBytesStringNew := intString(start);
    iBytesStringNew := Util.stringPadRight(iBytesStringNew, 3 + stringLength(scVarStr), " ");
    iBytesString := iBytesString +& iBytesStringNew;
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
    iVarsString := iVarsString +& "| " +& scVarStr +& " ";
    iBytesStringNew := intString(start);
    iBytesStringNew := Util.stringPadRight(iBytesStringNew, 3 + stringLength(scVarStr), " ");
    iBytesString := iBytesString +& iBytesStringNew;
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
    print("Node " +& intString(iNodeIdx) +& " solves sc-vars: " +& stringDelimitList(List.map(iMappingEntry, intString), ",") +& "\n");
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
    print("SCVar " +& intString(iScVarIdx) +& " is solved in task: " +& intString(iMappingEntry) +& "\n");
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
    print("Tasks that are writing to cacheline " +& intString(iCacheLineIdx) +& ": " +& stringDelimitList(List.map(iTasks, intString), ",") +& "\n");
    oCacheLineIdx := iCacheLineIdx + 1;
  end printCacheLineTaskMapping0;

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
    print("Scc " +& intString(iIdx) +& " is solved by node " +& intString(iMappingEntry) +& "\n");
    oIdx := iIdx + 1;
  end printSccNodeMapping0;

  // -------------------------------------------
  // SUSAN
  // -------------------------------------------

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
  algorithm
    tmpCrefs := expandCref(iCref, iNumArrayElems);
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
    print("expandCref: " +& ComponentReference.printComponentRefStr(cref) +& "\n");
    dims := getCrefDims(iCref);
    dimElemCount := getDimElemCount(listReverse(iNumArrayElems),dims);
    //print("expandCref: numArrayElems " +& intString(getNumArrayElems(iNumArrayElems, getCrefDims(iCref))) +& "\n");
    elems := List.reduce(dimElemCount, intMul);
    print("expandCref: " +& ComponentReference.printComponentRefStr(iCref) +& " dims: " +& intString(dims) +& " elems: " +& intString(elems) +& "\n");
    //dims := listLength(iNumArrayElems);
    print("expandCref: " +& ComponentReference.printComponentRefStr(iCref) +& " dims: " +& intString(dims) +& "[" +& intString(getCrefDims(iCref)) +& "] elems: " +& intString(elems) +& "\n");
    oCrefs := expandCref1(cref, elems, dimElemCount);
  end expandCref;

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
      else then iCref;
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
    dims := Util.if_(intLe(iDims,0), listLength(iNumArrayElems), iDims);
    dimList := List.intRange(dims);
    intNumArrayElems := List.map(iNumArrayElems,stringInt);
    print("getDimElemCount: dims=" +& intString(dims) +& " elems=" +& intString(listLength(iNumArrayElems)) +& "\n");
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
          //print("expandCref: " +& ComponentReference.printComponentRefStr(iCref) +& " elems: " +& intString(iElems) +& " dims: " +& intString(listLength(iDimElemCount)) +& "\n");
          idxList = List.intRange(List.reduce(iDimElemCount, intMul));
          print("expandCref1 idxList-count: " +& intString(listLength(idxList)) +& "\n");
          //ComponentReference.printComponentRefList(List.map2(idxList, createArrayIndexCref, iDimElemCount, iCref));
          tmpCrefs = List.map2(idxList, createArrayIndexCref, iDimElemCount, iCref);
          ComponentReference.printComponentRefList(tmpCrefs);
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
          print("createArrayIndexCref_impl case1 " +& ComponentReference.printComponentRefStr(Util.tuple21(iRefCurrentDim)) +& " currentDim " +& intString(1) +& "\n");
          ((componentRef,_)) = createArrayIndexCref_impl(iIdx, iDimElemCount, (componentRef,1));
        then ((DAE.CREF_QUAL(ident,identType,subscriptLst,componentRef),2));

      case(_,_,(DAE.CREF_QUAL(ident,identType,subscriptLst,componentRef),currentDim))
        equation
          true = intLe(currentDim, listLength(iDimElemCount));
          print("createArrayIndexCref_impl case2 " +& ComponentReference.printComponentRefStr(Util.tuple21(iRefCurrentDim)) +& " currentDim " +& intString(currentDim) +& "\n");
          ((componentRef,_)) = createArrayIndexCref_impl(iIdx, iDimElemCount, (componentRef,currentDim));
        then ((DAE.CREF_QUAL(ident,identType,subscriptLst,componentRef),currentDim+1));

      case(_,_,(DAE.CREF_IDENT(ident,identType,subscriptLst),1))
        equation
          true = intLe(1, listLength(iDimElemCount));
          print("createArrayIndexCref_impl case3 | len(subscriptList)= " +& intString(listLength(subscriptLst)) +& " " +& ComponentReference.printComponentRefStr(Util.tuple21(iRefCurrentDim)) +& " currentDim " +& intString(1) +& "\n");
          idxValue = intMod(iIdx-1,List.first(iDimElemCount)) + 1;
          subscriptLst = DAE.INDEX(DAE.ICONST(idxValue))::subscriptLst;
        then createArrayIndexCref_impl(iIdx, iDimElemCount, (DAE.CREF_IDENT(ident,identType,subscriptLst),2));

       case(_,_,(DAE.CREF_IDENT(ident,identType,subscriptLst),currentDim))
        equation
          true = intLe(currentDim, listLength(iDimElemCount));
          //dimElemsPre = List.reduce(List.sublist(iDimElemCount, listLength(iDimElemCount) - currentDim + 2, currentDim - 1), intMul);
          print("createArrayIndexCref_impl case4: listLen=" +& intString(listLength(iDimElemCount)) +& " currentDim= " +& intString(currentDim) +& "\n");
          dimElemsPre = List.reduce(List.sublist(iDimElemCount, 0, listLength(iDimElemCount) - currentDim + 1), intMul);
          print("createArrayIndexCref_impl case4 | len(subscriptList)= " +& intString(listLength(subscriptLst)) +& " " +& ComponentReference.printComponentRefStr(Util.tuple21(iRefCurrentDim)) +& " currentDim " +& intString(currentDim) +& " dimElemsPre: " +& intString(dimElemsPre) +& "\n");
          dimElems = listGet(iDimElemCount, currentDim);
          idxValue = intMod(intDiv(iIdx - 1, dimElemsPre),dimElems) + 1;
          subscriptLst = DAE.INDEX(DAE.ICONST(idxValue))::subscriptLst;
        then createArrayIndexCref_impl(iIdx, iDimElemCount, (DAE.CREF_IDENT(ident,identType,subscriptLst),currentDim+1));
      else then iRefCurrentDim;
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

  // -------------------------------------------
  // UNUSED
  // -------------------------------------------

  protected function appendFloatVarToCacheMap
    input SimCodeVar.SimVar iFloatVar;
    input tuple<CacheMap,Integer,Integer> iCacheInfo;
    output tuple<CacheMap,Integer,Integer> oCacheInfo; //<cacheMap,numCL,numBytesUsedLastCL>
  protected
    Integer cacheLineSize, numCL, numBytesUsedLastCL;
    list<SimCodeVar.SimVar> cacheVariables;
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

  protected function getSCVarCacheLineMapping
    input list<SimCodeVar.SimVar> iSimVars;
    input Integer iNumVarsCL; //number of bytes per cache line
    output array<Integer> oCacheLineMapping;
  protected
    array<Integer> tmpCacheLineMapping;
  algorithm
    tmpCacheLineMapping := arrayCreate(listLength(iSimVars), -1);
    ((oCacheLineMapping,_)) := List.fold1(iSimVars, getSCVarCacheLineMapping0, iNumVarsCL, (tmpCacheLineMapping,1));
  end getSCVarCacheLineMapping;

  protected function getSCVarCacheLineMapping0
    input SimCodeVar.SimVar iSimVar;
    input Integer iNumCL;
    input tuple<array<Integer>,Integer> iCacheLineMappingSimVarIdx;
    output tuple<array<Integer>,Integer> oCacheLineMappingSimVarIdx;
  protected
    Integer iSimVarIdx, clIdx;
    array<Integer> iCacheLineMapping;
    DAE.ComponentRef name;
  algorithm
    SimCodeVar.SIMVAR(name=name) := iSimVar;
    (iCacheLineMapping,iSimVarIdx) := iCacheLineMappingSimVarIdx;
    clIdx := intDiv(iSimVarIdx-1,iNumCL)+1;
    //print("Sc-Var" +& intString(iSimVarIdx) +& ":" +& ComponentReference.debugPrintComponentRefTypeStr(name) +& " is part of cl: " +& intString(clIdx) +& "\n");
    iCacheLineMapping := arrayUpdate(iCacheLineMapping,iSimVarIdx,clIdx);
    oCacheLineMappingSimVarIdx := (iCacheLineMapping,iSimVarIdx+1);
  end getSCVarCacheLineMapping0;

  protected function getSCVarCacheLineMappingFloat
    input list<SimCodeVar.SimVar> iFloatVars;
    input Integer iNumBytes; //number of bytes per cache line
    input Integer iStartCL; //the cache line index of the first variable
    input array<tuple<Integer,Integer>> iSVarCLMapping;
    output list<CacheLineMap> oCacheLines;
    output array<tuple<Integer,Integer>> oScVarCLMapping;
  protected
    list<CacheLineMap> tmpCacheLines;
  algorithm
    ((tmpCacheLines,_,_,_,oScVarCLMapping)) := List.fold1(iFloatVars, getSCVarCacheLineMappingFloat0, iNumBytes, ({},iStartCL-1,0,1,iSVarCLMapping));
    tmpCacheLines := List.map(tmpCacheLines, reverseCacheLineMapEntries);
    oCacheLines := listReverse(tmpCacheLines);
  end getSCVarCacheLineMappingFloat;

  protected function getSCVarCacheLineMappingFloat0
    input SimCodeVar.SimVar iSimVar;
    input Integer iNumBytes;
    input tuple<list<CacheLineMap>,Integer,Integer,Integer,array<tuple<Integer,Integer>>> iCacheLineMappingSimVarIdx; //<filledCacheLines,CacheLineIdx,BytesCLAlreadyUsed,SimVarIdx,scVarCLMapping>
    output tuple<list<CacheLineMap>,Integer,Integer,Integer,array<tuple<Integer,Integer>>> oCacheLineMappingSimVarIdx;
  protected
    CacheLineMap iCacheLineHead;
    list<CacheLineMap> iCacheLines;
    Integer iCacheLineIdx, iSimVarIdx, iBytesUsed;
    CacheLineEntry entry;
    array<tuple<Integer,Integer>> iSVarCLMapping;
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
          iSVarCLMapping = arrayUpdate(iSVarCLMapping,iSimVarIdx,(iCacheLineIdx+1,1));
        then ((iCacheLines, iCacheLineIdx, intMod(8,iNumBytes), iSimVarIdx+1, iSVarCLMapping));
      case(_,_,(iCacheLineHead::iCacheLines,iCacheLineIdx,iBytesUsed,iSimVarIdx,iSVarCLMapping))
        equation
          true = intLe(iBytesUsed+8, iNumBytes);
          entry = CACHELINEENTRY(iBytesUsed,1,8,iSimVarIdx);
          CACHELINEMAP(oldCLIdx,oldCLEntries) = iCacheLineHead;
          oldCLEntries = entry :: oldCLEntries;
          iCacheLineHead = CACHELINEMAP(oldCLIdx,oldCLEntries);
          iCacheLines = iCacheLineHead :: iCacheLines;
          iSVarCLMapping = arrayUpdate(iSVarCLMapping,iSimVarIdx,(iCacheLineIdx+1,1));
        then ((iCacheLines, iCacheLineIdx, intMod(iBytesUsed+8,iNumBytes), iSimVarIdx+1, iSVarCLMapping));
      else
        equation
          print("getSCVarCacheLineMappingFloat0 failed\n");
        then iCacheLineMappingSimVarIdx;
    end matchcontinue;
  end getSCVarCacheLineMappingFloat0;

  protected function getSimEqVarMapping
    input list<SimCode.SimEqSystem> iEqSystems;
    input HashTableCrILst.HashTable iHt; //Mapping varName -> varIdx
    output list<list<Integer>> oEqVarMapping; //Mapping eq -> list of varIdx
  algorithm
    oEqVarMapping := List.map1(iEqSystems, getVarsBySimEqSystem, iHt);
  end getSimEqVarMapping;

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
          (_,(_,varIdcList)) = Expression.traverseExp(exp,createMemoryMapTraverse0, (iHt,{}));
          //print("Var List for simEquation " +& intString(index) +& ":");
          //print(stringDelimitList, ","));
          //print("\n");
        then varIdcList;
      else
        then {};
    end match;
  end getVarsBySimEqSystem;

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
    ((oMapping,_)) := Array.fold1(varOptArr,getVarSCVarMapping0,iHt,(tmpMapping,1));
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
    ((oSCVarVarMapping,_)) := Array.fold(iVarSCVarMapping, getSCVarVarMapping0, (tmpMapping,1));
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

  protected function transposeCacheLineTaskMapping
    input array<list<Integer>> iCLTaskMapping;
    input Integer iNumberOfTasks; //number of tasks
    output array<list<Integer>> oCLTaskMappingT; //taskCLMapping
  protected
    array<list<Integer>> taskCLMapping;
  algorithm
    //print("transposeCacheLineTaskMapping with nodeCount: " +& intString(iNumberOfTasks) +& "\n");
    taskCLMapping := arrayCreate(iNumberOfTasks,{});
    ((oCLTaskMappingT,_)) := Array.fold(iCLTaskMapping,transposeCacheLineTaskMapping0,(taskCLMapping,1));
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
      else iTaskCLMapping;
    end matchcontinue;
  end transposeCacheLineTaskMapping1;

  protected function evaluateCacheBehaviour
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo; //<threadId,taskNumber,finishTime> for node (array-index)
    input HpcOmTaskGraph.TaskGraphMeta iGraphData;
    input array<list<Integer>> iCLTaskMapping;
    input array<list<Integer>> iTaskCLMapping;
  algorithm
    //Iterate over all tasks (nodes in graph)
    _ := Array.fold4(iSchedulerInfo, evaluateCacheBehaviour0, iSchedulerInfo, iGraphData, iCLTaskMapping, iTaskCLMapping, 1);
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
      else iNodeIdx + 1;
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
      else ();
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

  //protected function appendCacheLineEdgesToGraphTraverse
  //  input list<Integer> iEqSCVars;
  //  //input array<Integer> iScvarCompMapping; //maps each scVar (arrayIdx) to the task that solves it
  //  input array<tuple<Integer,Integer,Integer>> ieqCompMapping; //a mapping from eqIdx (arrayIdx) to the scc idx
  //  input array<Integer> iCompNodeMapping;
  //  input array<Integer> iScVarTaskMapping;
  //  input tuple<Integer,array<list<Integer>>,GraphML.GraphInfo> iGraphInfoIdx;
  //  output tuple<Integer,array<list<Integer>>,GraphML.GraphInfo> oGraphInfoIdx;
  //protected
  //  Integer eqIdx, compIdx, nodeIdx;
  //  GraphML.GraphInfo graphInfo;
  //  array<list<Integer>> knownEdges;
  //algorithm
  //  (eqIdx,knownEdges,graphInfo) := iGraphInfoIdx;
  //  //print("appendCacheLineEdgesToGraphTraverse: Equation with Vars: " +& stringDelimitList(List.map(iEqVars, intString), ",") +& "\n");
  //  //print("appendCacheLineEdgesToGraphTraverse " +& intString(eqIdx) +& " arrayLength: " +& intString(arrayLength(ieqCompMapping)) +& "\n");
  //  ((compIdx,_,_)) := arrayGet(ieqCompMapping,eqIdx);
  //  nodeIdx := arrayGet(iCompNodeMapping, compIdx);
  //  graphInfo := List.fold4(iEqSCVars, appendCacheLineEdgeToGraph, eqIdx, nodeIdx, knownEdges, iScVarTaskMapping, graphInfo);
  //  oGraphInfoIdx := ((eqIdx+1,knownEdges,graphInfo));
  //end appendCacheLineEdgesToGraphTraverse;

  //protected function appendCacheLineEdgeToGraph
  //  input Integer iSCVarIdx;
  //  input Integer iEqIdx;
  //  input Integer iNodeIdx;
  //  input array<list<Integer>> iKnownEdges;
  //  input array<Integer> iScVarTaskMapping;
  //  input GraphML.GraphInfo iGraphInfo;
  //  output GraphML.GraphInfo oGraphInfo;
  //protected
  //  String edgeId, sourceId, targetId;
  //  GraphML.GraphInfo tmpGraphInfo;
  //algorithm
  //  oGraphInfo := matchcontinue(iSCVarIdx,iEqIdx,iNodeIdx,iKnownEdges,iScVarTaskMapping,iGraphInfo)
  //    case(_,_,_,_,_,_)
  //      equation
  //        //print("appendCacheLineEdgeToGraph: scVarFound " +& intString(iVarIdx) +& " [SC-Var " +& intString(scVarIdx) +& "]\n");
  //        //knownEdgesOfNode = arrayGet(knownEdges,nodeIdx);
  //        //false = List.exist1(knownEdgesOfNode, intEq, clIdx);
  //        true = intGt(iNodeIdx,0);
  //        // Node solves scvar
  //        true = intEq(arrayGet(iScVarTaskMapping, iSCVarIdx), iNodeIdx);
  //        //knownEdges = arrayUpdate(knownEdges, nodeIdx, clIdx::knownEdgesOfNode);
  //        edgeId = "CL_Edge" +& intString(iNodeIdx) +& intString(iSCVarIdx);
  //        sourceId = "Node" +& intString(iNodeIdx);
  //        //targetId = "CL_Meta_" +& intString(clIdx);
  //        //print("appendCacheLineEdgeToGraph: Equation " +& intString(iEqIdx) +& " reads/writes SC-Var-idx: " +& intString(iSCVarIdx) +& " solved in node " +& intString(iNodeIdx) +& "\n");
  //        targetId = "CL_Var" +& intString(iSCVarIdx);
  //        (tmpGraphInfo,(_,_)) = GraphML.addEdge(edgeId, targetId, sourceId, GraphML.COLOR_GRAY, GraphML.DASHED(), GraphML.LINEWIDTH_STANDARD, true, {}, (GraphML.ARROWNONE(),GraphML.ARROWNONE()), {}, iGraphInfo);
  //      then tmpGraphInfo;
  //     case(_,_,_,_,_,_)
  //      equation
  //        //((nodeIdx,_,_)) = arrayGet(ieqCompMapping,iEqIdx);
  //        //print("HpcOmSimCode.appendCacheLineEdgeToGraph: No node for scc " +& intString(sccIdx) +& " found\n");
  //      then iGraphInfo;
  //     else
  //      equation
  //        //Valid if there is no state in the model and a dummy state was added
  //        //print("HpcOmSimCode.appendCacheLineEdgeToGraph: Equation " +& intString(iEqIdx) +& " is not part of a scc.\n");
  //        //print("HpcOmSimCode.appendCacheLineEdgeToGraph failed!\n");
  //      then iGraphInfo;
  //  end matchcontinue;
  //end appendCacheLineEdgeToGraph;

annotation(__OpenModelica_Interface="backend");
end HpcOmMemory;
