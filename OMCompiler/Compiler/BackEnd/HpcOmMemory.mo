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

import BackendDAE;
import DAE;
import HashTableCrILst;
import HpcOmSimCode;
import HpcOmTaskGraph;
import SimCode;
import SimCodeVar;

protected

import Array;
import BackendDAEUtil;
import BackendDump;
import BackendEquation;
import BackendVariable;
import BaseHashTable;
import ComponentReference;
import Config;
import Error;
import ExpandableArray;
import Expression;
import Flags;
import GraphML;
import HpcOmScheduler;
import List;
import SimCodeUtil;
import SimCodeFunctionUtil;
import Util;

  // -------------------------------------------
  // STRUCTURES
  // -------------------------------------------

  public constant Integer VARDATATYPE_FLOAT        = 1;
  public constant Integer VARDATATYPE_INTEGER      = 2;
  public constant Integer VARDATATYPE_BOOLEAN      = 3;
  public constant Integer VARDATATYPE_STRING       = 4;

  public constant Integer VARTYPE_STATE        = 1;
  public constant Integer VARTYPE_STATEDER     = 2;
  public constant Integer VARTYPE_PARAM        = 3;
  public constant Integer VARTYPE_ALIAS        = 4;
  public constant Integer VARTYPE_OTHER        = 5;

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
      Integer threadOwner; //TODO: check if necessary
    end CACHELINEENTRY;
  end CacheLineEntry;

  protected uniontype CacheMapMeta
    record CACHEMAPMETA
      array<Option<SimCodeVar.SimVar>> allSCVarsMapping;
      array<tuple<Integer, Integer, Integer>> simCodeVarTypes; //<dataType, numberOfBytesRequired, varType>
      array<tuple<Integer, Integer>> scVarCLMapping; //mapping for each scVar -> <CLIdx,varType>
    end CACHEMAPMETA;
  end CacheMapMeta;

 protected uniontype PartlyFilledCacheLine
    record PARTLYFILLEDCACHELINE_LEVEL
      CacheLineMap cacheLineMap;
      list<Integer> prefetchLevel;
      list<tuple<Integer,Integer>> writeLevel; //(LevelIdx, ThreadIdx)
    end PARTLYFILLEDCACHELINE_LEVEL;
    record PARTLYFILLEDCACHELINE_THREAD
      CacheLineMap cacheLineMap;
    end PARTLYFILLEDCACHELINE_THREAD;
 end PartlyFilledCacheLine;

 protected uniontype ScVarInfo
    record SCVARINFO //an onwer of -1 and isShared = true indicates that the variable is unused
      Integer ownerThread; //the thread that writes the variable or the only thread that reads the variable
      Boolean isShared;
    end SCVARINFO;
 end ScVarInfo;

 protected type PartlyFilledCacheLines = tuple<list<PartlyFilledCacheLine>, list<PartlyFilledCacheLine>, list<PartlyFilledCacheLine>>;
 protected type CacheLines = tuple<list<CacheLineMap>, list<CacheLineMap>, list<CacheLineMap>>;

  // -------------------------------------------
  // FUNCTIONS
  // -------------------------------------------

  public function createMemoryMap
    "author: marcusw
     Creates a MemoryMap which contains informations about an optimized memory alignment and append the informations to the given TaskGraph."
    input SimCode.ModelInfo iModelInfo;
    input HashTableCrIListArray.HashTable iVarToArrayIndexMapping;
    input HashTableCrILst.HashTable iVarToIndexMapping;
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraph iTaskGraphT;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input BackendDAE.EqSystems iEqSystems;
    input String iFileNamePrefix;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo; //maps each Task to <threadId, orderId, startCalcTime>
    input HpcOmSimCode.Schedule iSchedule;
    input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
    input list<list<Integer>> iCriticalPaths;
    input list<list<Integer>> iCriticalPathsWoC;
    input String iCriticalPathInfo;
    input Integer iNumberOfThreads;
    input BackendDAE.StrongComponents iAllComponents;
    output Option<HpcOmSimCode.MemoryMap> oMemoryMap;
    output HashTableCrIListArray.HashTable oVarToArrayIndexMapping;
    output HashTableCrILst.HashTable oVarToIndexMapping;
  protected
    SimCodeVar.SimVars simCodeVars;
    list<SimCodeVar.SimVar> stateVars, derivativeVars, algVars, discreteAlgVars, intAlgVars, boolAlgVars, stringAlgVars, inputVars, outputVars, aliasVars, paramVars, intParamVars, boolParamVars, stringParamVars, intAliasVars, boolAliasVars, stringAliasVars;
    list<Option<SimCodeVar.SimVar>> notOptimizedVarsFloatOpt, notOptimizedVarsIntOpt, notOptimizedVarsBoolOpt, notOptimizedVarsStringOpt;
    list<SimCodeVar.SimVar> notOptimizedVarsFloat, notOptimizedVarsInt, notOptimizedVarsBool, notOptimizedVarsString;
    tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>> notOptimizedVars;
    array<Option<SimCodeVar.SimVar>> allVarsMapping;
    HashTableCrILst.HashTable simVarIdxMappingHashTable;
    Integer numScVars, numCL, threadAttIdx;
    array<list<Integer>> clTaskMapping;
    array<Integer> scVarSolvedTaskMapping, sccNodeMapping;
    array<list<Integer>> scVarUnsolvedTaskMapping;
    array<String> annotInfo;
    array<tuple<Integer,Integer>> scVarCLMapping, memoryPositionMapping;
    CacheMap cacheMap;
    Integer graphIdx;
    GraphML.GraphInfo graphInfo;
    String fileName;
    array<array<list<Integer>>> eqSimCodeVarMapping; //eqSystem -> eqIdx -> varIdx
    array<tuple<Integer,Integer,Integer>> eqCompMapping, varCompMapping;
    BackendDAE.IncidenceMatrix incidenceMatrix;
    Option<HpcOmSimCode.MemoryMap> tmpMemoryMapOpt;
    Integer varCount;
    Integer VARSIZE_FLOAT, VARSIZE_INTEGER, VARSIZE_BOOLEAN, VARSIZE_STRING, CACHELINE_SIZE;
    array<tuple<Integer,Integer, Integer>> simCodeVarTypes; //<varDataType, varSize, varType>

    array<list<Integer>> taskSolvedVarsMapping;
    array<list<Integer>> taskUnsolvedVarsMapping;
    array<list<Integer>> nodeSccMapping;
    array<tuple<Integer,list<Integer>>> flatEqSimCodeVarMapping; //eqIdx -> (eqSysIdx, list of simVars)
    array<list<tuple<Integer,Integer,Integer>>> sccEqMapping; //maps each scc to a list of <equationIdx, eqSystemIdx, offset>
    array<ScVarInfo> scVarInfos;
    HashTableCrIListArray.HashTable varToArrayIndexMapping;
    HashTableCrILst.HashTable varToIndexMapping;
  algorithm
    (oMemoryMap, oVarToArrayIndexMapping, oVarToIndexMapping) := matchcontinue(iModelInfo, iVarToArrayIndexMapping, iVarToIndexMapping, iTaskGraph, iTaskGraphMeta, iEqSystems, iFileNamePrefix, iSchedulerInfo, iSchedule, iSccSimEqMapping, iCriticalPaths, iCriticalPathsWoC, iCriticalPathInfo, iNumberOfThreads, iAllComponents)
      case(_,varToArrayIndexMapping,varToIndexMapping,_,HpcOmTaskGraph.TASKGRAPHMETA(eqCompMapping=eqCompMapping,varCompMapping=varCompMapping),_,_,_,_,_,_,_,_,_,_)
        equation
          VARSIZE_FLOAT = 8;
          VARSIZE_INTEGER = 4;
          VARSIZE_BOOLEAN = 1;
          VARSIZE_STRING = 4; //32 bit pointer
          CACHELINE_SIZE = 64;
          //HpcOmTaskGraph.printTaskGraphMeta(iTaskGraphMeta);
          //Create var hash table
          SimCode.MODELINFO(vars=simCodeVars) = iModelInfo;
          SimCodeVar.SIMVARS(stateVars=stateVars, derivativeVars=derivativeVars, algVars=algVars, discreteAlgVars=discreteAlgVars, intAlgVars=intAlgVars, boolAlgVars=boolAlgVars, stringAlgVars=stringAlgVars, inputVars=inputVars,
                             outputVars=outputVars, aliasVars=aliasVars, intAliasVars=intAliasVars, boolAliasVars=boolAliasVars, stringAliasVars=stringAliasVars, paramVars=paramVars, intParamVars=intParamVars, boolParamVars=boolParamVars, stringParamVars=stringParamVars) = simCodeVars;
          allVarsMapping = SimCodeUtil.createIdxSCVarMapping(simCodeVars);
          //SimCodeUtil.dumpIdxScVarMapping(allVarsMapping);

          //print("--------------------------------\n");
          simVarIdxMappingHashTable = HashTableCrILst.emptyHashTableSized(BaseHashTable.biggerBucketSize);
          varCount = 0;
          //simVarIdxMappingHashTable = fillSimVarHashTable(stateVars,varCount,VARDATATYPE_FLOAT,simVarIdxMappingHashTable);
          varCount = varCount + listLength(stateVars);
          //simVarIdxMappingHashTable = fillSimVarHashTable(derivativeVars,varCount,VARDATATYPE_FLOAT,simVarIdxMappingHashTable);
          varCount = varCount + listLength(derivativeVars);
          simVarIdxMappingHashTable = fillSimVarHashTable(algVars,varCount,VARDATATYPE_FLOAT,simVarIdxMappingHashTable);
          varCount = varCount + listLength(algVars);
          simVarIdxMappingHashTable = fillSimVarHashTable(discreteAlgVars,varCount,VARDATATYPE_FLOAT,simVarIdxMappingHashTable);
          varCount = varCount + listLength(discreteAlgVars);
          simVarIdxMappingHashTable = fillSimVarHashTable(intAlgVars,varCount,VARDATATYPE_INTEGER,simVarIdxMappingHashTable);
          varCount = varCount + listLength(intAlgVars);
          simVarIdxMappingHashTable = fillSimVarHashTable(boolAlgVars,varCount,VARDATATYPE_BOOLEAN,simVarIdxMappingHashTable);
          varCount = varCount + listLength(boolAlgVars);
          simVarIdxMappingHashTable = fillSimVarHashTable(stringAlgVars,varCount,VARDATATYPE_STRING,simVarIdxMappingHashTable);
          varCount = varCount + listLength(stringAlgVars);
          simVarIdxMappingHashTable = fillSimVarHashTable(inputVars,varCount,VARDATATYPE_FLOAT,simVarIdxMappingHashTable);
          varCount = varCount + listLength(inputVars);
          simVarIdxMappingHashTable = fillSimVarHashTable(outputVars,varCount,VARDATATYPE_FLOAT,simVarIdxMappingHashTable);
          varCount = varCount + listLength(outputVars);
          //simVarIdxMappingHashTable = fillSimVarHashTable(aliasVars,varCount,VARDATATYPE_FLOAT,simVarIdxMappingHashTable);
          varCount = varCount + listLength(aliasVars);
          //simVarIdxMappingHashTable = fillSimVarHashTable(intAliasVars,varCount,VARDATATYPE_INTEGER,simVarIdxMappingHashTable);
          varCount = varCount + listLength(intAliasVars);
          //simVarIdxMappingHashTable = fillSimVarHashTable(boolAliasVars,varCount,VARDATATYPE_BOOLEAN,simVarIdxMappingHashTable);
          varCount = varCount + listLength(boolAliasVars);
          simVarIdxMappingHashTable = fillSimVarHashTable(stringAliasVars,varCount,VARDATATYPE_STRING,simVarIdxMappingHashTable);
          varCount = varCount + listLength(stringAliasVars);
          simVarIdxMappingHashTable = fillSimVarHashTable(paramVars,varCount,VARDATATYPE_FLOAT,simVarIdxMappingHashTable);
          varCount = varCount + listLength(paramVars);
          simVarIdxMappingHashTable = fillSimVarHashTable(intParamVars,varCount,VARDATATYPE_INTEGER,simVarIdxMappingHashTable);
          varCount = varCount + listLength(intParamVars);
          simVarIdxMappingHashTable = fillSimVarHashTable(boolParamVars,varCount,VARDATATYPE_BOOLEAN,simVarIdxMappingHashTable);
          varCount = varCount + listLength(boolParamVars);
          simVarIdxMappingHashTable = fillSimVarHashTable(stringParamVars,varCount,VARDATATYPE_STRING,simVarIdxMappingHashTable);
          varCount = varCount + listLength(stringParamVars);

          simCodeVarTypes = arrayCreate(varCount, (-1,-1,-1));
          varCount = 0;

          /* if(intGt(listLength(stateVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(stateVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_FLOAT,VARSIZE_FLOAT,VARTYPE_STATE), inArray=simCodeVarTypes));
          end if; */
          varCount = varCount + listLength(stateVars);
          /* if(intGt(listLength(derivativeVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(derivativeVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_FLOAT,VARSIZE_FLOAT,VARTYPE_STATEDER), inArray=simCodeVarTypes));
          end if; */
          varCount = varCount + listLength(derivativeVars);
          if(intGt(listLength(algVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(algVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_FLOAT,VARSIZE_FLOAT,VARTYPE_OTHER), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(algVars);
          if(intGt(listLength(discreteAlgVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(discreteAlgVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_FLOAT,VARSIZE_FLOAT,VARTYPE_OTHER), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(discreteAlgVars);
          if(intGt(listLength(intAlgVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(intAlgVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_INTEGER,VARSIZE_INTEGER,VARTYPE_OTHER), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(intAlgVars);
          if(intGt(listLength(boolAlgVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(boolAlgVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_BOOLEAN,VARSIZE_BOOLEAN,VARTYPE_OTHER), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(boolAlgVars);
          if(intGt(listLength(stringAlgVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(stringAlgVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_STRING,VARSIZE_STRING,VARTYPE_OTHER), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(stringAlgVars);
          if(intGt(listLength(inputVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(inputVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_FLOAT,VARSIZE_FLOAT,VARTYPE_OTHER), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(inputVars);
          if(intGt(listLength(outputVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(outputVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_FLOAT,VARSIZE_FLOAT,VARTYPE_OTHER), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(outputVars);
          /*if(intGt(listLength(aliasVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(aliasVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_FLOAT,VARSIZE_FLOAT,VARTYPE_ALIAS), inArray=simCodeVarTypes));
          end if;*/
          varCount = varCount + listLength(aliasVars);
          /*if(intGt(listLength(intAliasVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(intAliasVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_INTEGER,VARSIZE_INTEGER,VARTYPE_ALIAS), inArray=simCodeVarTypes));
          end if;*/
          varCount = varCount + listLength(intAliasVars);
          /*if(intGt(listLength(boolAliasVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(boolAliasVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_BOOLEAN,VARSIZE_BOOLEAN,VARTYPE_ALIAS), inArray=simCodeVarTypes));
          end if;*/
          varCount = varCount + listLength(boolAliasVars);
          varCount = varCount + listLength(stringAliasVars);
          if(intGt(listLength(paramVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(paramVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_FLOAT,VARSIZE_FLOAT,VARTYPE_PARAM), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(paramVars);
          if(intGt(listLength(intParamVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(intParamVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_INTEGER,VARSIZE_INTEGER,VARTYPE_PARAM), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(intParamVars);
          if(intGt(listLength(boolParamVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(boolParamVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_BOOLEAN,VARSIZE_BOOLEAN,VARTYPE_PARAM), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(boolParamVars);
          if(intGt(listLength(stringParamVars), 0)) then
            List.map_0(List.intRange2(varCount+1, varCount+listLength(stringParamVars)), function Array.updateIndexFirst(inValue = (VARDATATYPE_STRING,VARSIZE_STRING,VARTYPE_PARAM), inArray=simCodeVarTypes));
          end if;
          varCount = varCount + listLength(stringParamVars);
          //printSimCodeVarTypes(simCodeVarTypes);

          //print("-------------------------------------\n");
          //BaseHashTable.dumpHashTable(simVarIdxMappingHashTable);
          //Create CacheMap
          sccNodeMapping = HpcOmTaskGraph.getSccNodeMapping(arrayLength(iSccSimEqMapping), iTaskGraphMeta);
          //printSccNodeMapping(sccNodeMapping);
          scVarSolvedTaskMapping = getSimCodeVarNodeMapping(iTaskGraphMeta,iEqSystems,varCount,sccNodeMapping,simVarIdxMappingHashTable);
          //printScVarTaskMapping(scVarSolvedTaskMapping);
          //print("-------------------------------------\n");

          eqSimCodeVarMapping = getEqSCVarMapping(iEqSystems,simVarIdxMappingHashTable);
          //printEqSimCodeVarMapping(eqSimCodeVarMapping);

          sccEqMapping = invertEqCompMapping(eqCompMapping, arrayLength(sccNodeMapping));
          nodeSccMapping = invertSccNodeMapping(sccNodeMapping, arrayLength(iTaskGraph));
          flatEqSimCodeVarMapping = flattenEqSimCodeVarMapping(eqSimCodeVarMapping);
          (taskSolvedVarsMapping, taskUnsolvedVarsMapping) = getTaskSimVarMapping(sccEqMapping, nodeSccMapping, flatEqSimCodeVarMapping, scVarSolvedTaskMapping, simCodeVarTypes);
          scVarUnsolvedTaskMapping = transposeTasksScVarsMapping(taskUnsolvedVarsMapping, varCount);
          scVarInfos = createVarInfos(scVarSolvedTaskMapping, scVarUnsolvedTaskMapping, iSchedulerInfo);
          //printScVarInfos(scVarInfos);

          //print("\nSolved variables\n==============\n");
          //printNodeSimCodeVarMapping(taskSolvedVarsMapping);
          //print("Unsolved variables\n==============\n");
          //printNodeSimCodeVarMapping(taskUnsolvedVarsMapping);

          if(Flags.isSet(Flags.HPCOM_MEMORY_OPT)) then
            (cacheMap,scVarCLMapping,numCL) = createCacheMapOptimized(iTaskGraph, iTaskGraphMeta, simCodeVars, allVarsMapping,simCodeVarTypes,scVarSolvedTaskMapping,scVarUnsolvedTaskMapping,CACHELINE_SIZE,iAllComponents,iSchedule,iSchedulerInfo,iNumberOfThreads,taskSolvedVarsMapping, taskUnsolvedVarsMapping, scVarInfos);
          else
            (cacheMap,scVarCLMapping,numCL) = createCacheMapDefault(allVarsMapping, CACHELINE_SIZE, simCodeVars, scVarSolvedTaskMapping, iSchedulerInfo, simCodeVarTypes);
          end if;

          (clTaskMapping,_) = getCacheLineTaskMapping(iTaskGraphMeta,iEqSystems,simVarIdxMappingHashTable,numCL,scVarCLMapping);

          //Get not optimized variables (e.g. paramters that are not part of the task graph)
          //--------------------------------------------------------------------------------
          notOptimizedVars = getNotOptimizedVarsByCacheLineMapping(scVarCLMapping, allVarsMapping, simCodeVarTypes);
          notOptimizedVarsFloatOpt = List.map(Util.tuple41(notOptimizedVars), function arrayGet(arr = allVarsMapping));
          notOptimizedVarsIntOpt = List.map(Util.tuple42(notOptimizedVars), function arrayGet(arr = allVarsMapping));
          notOptimizedVarsBoolOpt = List.map(Util.tuple43(notOptimizedVars), function arrayGet(arr = allVarsMapping));
          notOptimizedVarsStringOpt = List.map(Util.tuple44(notOptimizedVars), function arrayGet(arr = allVarsMapping));

          notOptimizedVarsFloat = List.map(notOptimizedVarsFloatOpt, Util.getOption);
          notOptimizedVarsInt = List.map(notOptimizedVarsIntOpt, Util.getOption);
          notOptimizedVarsBool = List.map(notOptimizedVarsBoolOpt, Util.getOption);
          notOptimizedVarsString = List.map(notOptimizedVarsStringOpt, Util.getOption);
          //Append cache line nodes to graph
          //--------------------------------
          graphInfo = GraphML.createGraphInfo();
          (graphInfo, (_,graphIdx)) = GraphML.addGraph("TasksGroupGraph", true, graphInfo);
          (graphInfo, (_,_),(_,graphIdx)) = GraphML.addGroupNode("TasksGroup", graphIdx, false, "TG", graphInfo);
          annotInfo = arrayCreate(arrayLength(iTaskGraph),"nothing");
          graphInfo = HpcOmTaskGraph.convertToGraphMLSccLevelSubgraph(iTaskGraph, iTaskGraphMeta, iCriticalPathInfo, HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(iCriticalPaths)), HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(iCriticalPathsWoC)), iSccSimEqMapping, iSchedulerInfo, annotInfo, graphIdx, HpcOmTaskGraph.GRAPHDUMPOPTIONS(false,false,true,true), graphInfo);
          SOME((_,threadAttIdx)) = GraphML.getAttributeByNameAndTarget("ThreadId", GraphML.TARGET_NODE(), graphInfo);
          (_,incidenceMatrix,_) = BackendDAEUtil.getIncidenceMatrix(listHead(iEqSystems), BackendDAE.ABSOLUTE(), NONE());
          graphInfo = appendCacheLinesToGraph(cacheMap, arrayLength(iTaskGraph), eqSimCodeVarMapping, iEqSystems, simVarIdxMappingHashTable, eqCompMapping, scVarSolvedTaskMapping, iSchedulerInfo, threadAttIdx, sccNodeMapping, taskSolvedVarsMapping, taskUnsolvedVarsMapping, scVarCLMapping, scVarInfos, graphInfo);
          fileName = ("taskGraph"+iFileNamePrefix+"ODE_schedule_CL.graphml");
          GraphML.dumpGraph(graphInfo, fileName);
          //printCacheMap(cacheMap);
          if(Flags.isSet(Flags.HPCOM_MEMORY_OPT)) then
            (varToArrayIndexMapping, varToIndexMapping, tmpMemoryMapOpt) = convertCacheToVarArrayMapping(cacheMap,CACHELINE_SIZE,stateVars,derivativeVars,aliasVars,intAliasVars,boolAliasVars,stringAliasVars,(VARSIZE_FLOAT,VARSIZE_INTEGER,VARSIZE_BOOLEAN),(notOptimizedVarsFloat,notOptimizedVarsInt,notOptimizedVarsBool,notOptimizedVarsString));
          else
            tmpMemoryMapOpt = NONE();
          end if;

          //print cache map
          //printCacheMap(cacheMap);
          evaluateCacheBehaviour(varToIndexMapping, simVarIdxMappingHashTable, taskSolvedVarsMapping, taskUnsolvedVarsMapping, iTaskGraph, iTaskGraphT, iNumberOfThreads, CACHELINE_SIZE, simCodeVarTypes, iSchedulerInfo);

          //Create bipartite graph
          //----------------------
          graphInfo = GraphML.createGraphInfo();
          (graphInfo, (_,graphIdx)) = GraphML.addGraph("TasksGroupGraph", true, graphInfo);
          annotInfo = arrayCreate(arrayLength(iTaskGraph),"nothing");
          graphInfo = HpcOmTaskGraph.convertToGraphMLSccLevelSubgraph(iTaskGraph, iTaskGraphMeta, iCriticalPathInfo, HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(iCriticalPaths)), HpcOmTaskGraph.convertNodeListToEdgeTuples(listHead(iCriticalPathsWoC)), iSccSimEqMapping, iSchedulerInfo, annotInfo, graphIdx, HpcOmTaskGraph.GRAPHDUMPOPTIONS(false,false,true,true), graphInfo);
          SOME((_,threadAttIdx)) = GraphML.getAttributeByNameAndTarget("ThreadId", GraphML.TARGET_NODE(), graphInfo);
          graphInfo = appendVariablesToGraph(taskSolvedVarsMapping, taskUnsolvedVarsMapping, arrayLength(scVarSolvedTaskMapping), graphIdx, threadAttIdx, simVarIdxMappingHashTable, allVarsMapping, scVarInfos, graphInfo);
          fileName = ("taskGraph"+iFileNamePrefix+"ODE_schedule_vars.graphml");
          GraphML.dumpGraph(graphInfo, fileName);
        then(tmpMemoryMapOpt, varToArrayIndexMapping, varToIndexMapping);
      else
        equation
          Error.addInternalError("CreateMemoryMap failed!", sourceInfo());
        then (NONE(), iVarToArrayIndexMapping, iVarToIndexMapping);
    end matchcontinue;
  end createMemoryMap;

  protected function createCacheMapOptimized "author: marcusw
     Creates a CacheMap optimized for the selected scheduler. All variables that are part of the created cache map are marked with 1 in the iVarMark-array."
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input SimCodeVar.SimVars iSimCodeVars;
    input array<Option<SimCodeVar.SimVar>> iAllSCVarsMapping;
    input array<tuple<Integer,Integer,Integer>> iSimCodeVarTypes; //<varDataType, varSize, varType>
    input array<Integer> iScVarSolvedTaskMapping;
    input array<list<Integer>> iScVarUnsolvedTaskMapping;
    input Integer iCacheLineSize;
    input BackendDAE.StrongComponents iAllComponents;
    input HpcOmSimCode.Schedule iSchedule;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input Integer iNumberOfThreads;
    input array<list<Integer>> iTaskSolvedVarsMapping;
    input array<list<Integer>> iTaskUnsolvedVarsMapping;
    input array<ScVarInfo> iScVarInfos;
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
    list<HpcOmSimCode.Task> allTasks;
  algorithm
    (oCacheMap,oScVarCLMapping,oNumCL) := match(iTaskGraph,iTaskGraphMeta,iAllSCVarsMapping,iSimCodeVarTypes,iScVarSolvedTaskMapping,iScVarUnsolvedTaskMapping,iCacheLineSize,iAllComponents,iSchedule, iNumberOfThreads, iTaskSolvedVarsMapping, iTaskUnsolvedVarsMapping)
      /* case(_,_,_,_,_,_,_,HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevels, useFixedAssignments=false),_,_)
        equation
          (cacheMap,scVarCLMapping,numCL) = createCacheMapLevelOptimized(iAllSCVarsMapping,iSimCodeVarTypes,iScVarTaskMapping,iCacheLineSize,iAllComponents,tasksOfLevels,iNodeSimCodeVarMapping);
        then (cacheMap,scVarCLMapping,numCL); */
      case(_,_,_,_,_,_,_,_,HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevels, useFixedAssignments=true),_,_,_)
        equation
          print("Creating optimized cache map for fixed level scheduler\n");
          scheduleInfo = HpcOmScheduler.convertScheduleStrucToInfo(iSchedule, arrayLength(iTaskGraph));
          (cacheMap,scVarCLMapping,numCL) = createCacheMapLevelFixedOptimized(iTaskGraph,iTaskGraphMeta,iAllSCVarsMapping,iSimCodeVarTypes,iScVarSolvedTaskMapping,
                                                                              iScVarUnsolvedTaskMapping,iCacheLineSize,iAllComponents,tasksOfLevels,iNumberOfThreads,
                                                                              scheduleInfo,iTaskSolvedVarsMapping,iTaskUnsolvedVarsMapping,iScVarInfos);
        then (cacheMap,scVarCLMapping,numCL);
      case(_,_,_,_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks),_,_,_)
        equation
          print("Creating optimized cache map for thread scheduler\n");
          scheduleInfo = HpcOmScheduler.convertScheduleStrucToInfo(iSchedule, arrayLength(iTaskGraph));
          (cacheMap,scVarCLMapping,numCL) = createCacheMapThreadOptimized(iTaskGraph,iTaskGraphMeta,iAllSCVarsMapping,iSimCodeVarTypes,iScVarSolvedTaskMapping,
                                                                          iScVarUnsolvedTaskMapping,iCacheLineSize,iAllComponents,threadTasks,iNumberOfThreads,
                                                                          scheduleInfo,iTaskSolvedVarsMapping,iTaskUnsolvedVarsMapping,iScVarInfos);
        then (cacheMap,scVarCLMapping,numCL);
      case(_,_,_,_,_,_,_,_,HpcOmSimCode.EMPTYSCHEDULE(tasks=HpcOmSimCode.SERIALTASKLIST(tasks=allTasks)),_,_,_)
        equation
          print("Creating optimized cache map for empty scheduler\n");
          threadTasks=arrayCreate(1, allTasks);
          scheduleInfo = HpcOmScheduler.convertScheduleStrucToInfo(iSchedule, arrayLength(iTaskGraph));
          (cacheMap,scVarCLMapping,numCL) = createCacheMapThreadOptimized(iTaskGraph,iTaskGraphMeta,iAllSCVarsMapping,iSimCodeVarTypes,iScVarSolvedTaskMapping,
                                                                          iScVarUnsolvedTaskMapping,iCacheLineSize,iAllComponents,threadTasks,1,
                                                                          scheduleInfo,iTaskSolvedVarsMapping,iTaskUnsolvedVarsMapping,iScVarInfos);
        then (cacheMap,scVarCLMapping,numCL);
      else
        equation
          print("No optimized cache map for the selected scheduler avaiable. Using default cacheMap!\n");
          (cacheMap,scVarCLMapping,numCL) = createCacheMapDefault(iAllSCVarsMapping, iCacheLineSize, iSimCodeVars, iScVarSolvedTaskMapping, iSchedulerInfo, iSimCodeVarTypes);
        then (cacheMap,scVarCLMapping,numCL);
     end match;
  end createCacheMapOptimized;

  protected function createCacheMapLevelOptimized "author: marcusw
    Create the optimized cache map for the level-scheduler."
    input array<Option<SimCodeVar.SimVar>> iAllSCVarsMapping;
    input array<tuple<Integer,Integer,Integer>> iSimCodeVarTypes; //<varDataType, numberOfBytesRequired, varType>
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
    input array<tuple<Integer,Integer,Integer>> iSimCodeVarTypes; //<varDataType, numberOfBytesRequired, varType>
    input array<Integer> iScVarSolvedTaskMapping;
    input array<list<Integer>> iScVarUnsolvedTaskMapping;
    input Integer iCacheLineSize;
    input BackendDAE.StrongComponents iAllComponents;
    input list<HpcOmSimCode.TaskList> iTasksOfLevels; //Schedule
    input Integer iNumberOfThreads;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input array<list<Integer>> iTaskSolvedVarsMapping;
    input array<list<Integer>> iTaskUnsolvedVarsMapping;
    input array<ScVarInfo> iScVarInfos;
    output CacheMap oCacheMap;
    output array<tuple<Integer,Integer>> oScVarCLMapping; //mapping for each scVar -> <CLIdx,varType>
    output Integer oNumCL;
  protected
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    array<Boolean> handledVariables;
    array<tuple<Integer,Integer>> scVarCLMapping;
    array<CacheLines> threadCacheLines; //cache lines of the threads (arrayIdx) -- CALC_ONLY and THREAD_ONLY variables
    array<tuple<PartlyFilledCacheLines, CacheLines>> sharedCacheLines;
  algorithm
    cacheMap := CACHEMAP(iCacheLineSize,{},{},{},{});
    scVarCLMapping := arrayCreate(arrayLength(iAllSCVarsMapping),(-1,-1));
    handledVariables := arrayCreate(arrayLength(iSimCodeVarTypes), false);
    oNumCL := 0;
    threadCacheLines := arrayCreate(iNumberOfThreads, ({},{},{}));
    sharedCacheLines := arrayCreate(iNumberOfThreads, (({},{},{}), ({},{},{})));
    cacheMapMeta := CACHEMAPMETA(iAllSCVarsMapping, iSimCodeVarTypes, scVarCLMapping);
    //Iterate over levels
    ((cacheMap,cacheMapMeta,oNumCL,_)) := List.fold(iTasksOfLevels, function createCacheMapLevelFixedOptimizedForLevel(iTaskGraph=iTaskGraph, iTaskGraphMeta=iTaskGraphMeta,
                                           iNumberOfThreads=iNumberOfThreads, iScVarInfos=iScVarInfos, iTaskSolvedVarsMapping=iTaskSolvedVarsMapping,
                                           iTaskUnsolvedVarsMapping=iTaskUnsolvedVarsMapping, iHandledVariables=handledVariables, iSchedulerInfo=iSchedulerInfo,
                                           iThreadCacheLines=threadCacheLines, iSharedCacheLines=sharedCacheLines), (cacheMap,cacheMapMeta,oNumCL,1));

    for threadIdx in 1:iNumberOfThreads loop
      cacheMap := createCacheMapFromThreadAndSharedCLs(arrayGet(threadCacheLines, threadIdx), arrayGet(sharedCacheLines, threadIdx), cacheMap);
    end for;

    oCacheMap := cacheMap;
    CACHEMAPMETA(scVarCLMapping=oScVarCLMapping) := cacheMapMeta;
  end createCacheMapLevelFixedOptimized;

  protected function createCacheMapLevelFixedOptimizedForLevel "author: marcusw
    Appends the variables which are written by the task list (iLevelTasks) to the info-structure."
    input HpcOmSimCode.TaskList iLevelTasks;
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input Integer iNumberOfThreads;
    input array<ScVarInfo> iScVarInfos;
    input array<list<Integer>> iTaskSolvedVarsMapping;
    input array<list<Integer>> iTaskUnsolvedVarsMapping;
    input array<Boolean> iHandledVariables; //true if the variable was already added to a cache line
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input array<CacheLines> iThreadCacheLines; //Thread CacheLines for float, int and bool -- is updated!
    input array<tuple<PartlyFilledCacheLines, CacheLines>> iSharedCacheLines;
    input tuple<CacheMap,CacheMapMeta,Integer,Integer> iInfo; //<CacheMap,CacheMapMeta,numCL,level>
    output tuple<CacheMap,CacheMapMeta,Integer,Integer> oInfo;
  protected
    Integer createdCL, numCL, cacheLineSize, level; //number of CL created for this level
    list<Integer> allCL;
    list<Integer> availableCL, availableCLold, writtenCL; //all cacheLines that can be used for writing
    list<Integer> cacheLinesPrevLevel; //all cache lines written in previous level
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    list<CacheLineMap> cacheLinesFloat;
    list<CacheLineMap> sharedCacheLines;
    list<SimCodeVar.SimVar> cacheVariables;
    array<list<Integer>> cacheLinesAvailableForLevel;
  algorithm
    (cacheMap, cacheMapMeta, numCL, level) := iInfo;
    CACHEMAP(cacheVariables=cacheVariables) := cacheMap;
    //print("\tcreateCacheMapLevelFixedOptimized0: handling level " + intString(level) + "\n");
    allCL := List.intRange(numCL);
    CACHEMAP(cacheLinesFloat=cacheLinesFloat,cacheLineSize=cacheLineSize) := cacheMap;
    ((cacheMap,cacheMapMeta,createdCL)) := List.fold(getTaskListTasks(iLevelTasks),
          function createCacheMapLevelFixedOptimizedForTask(iTaskGraph=iTaskGraph, iTaskGraphMeta=iTaskGraphMeta, iSchedulerInfo=iSchedulerInfo,
                                                            iNumberOfThreads=iNumberOfThreads, iLevel=level, iScVarInfos=iScVarInfos, iTaskSolvedVarsMapping=iTaskSolvedVarsMapping,
                                                            iTaskUnsolvedVarsMapping=iTaskUnsolvedVarsMapping, iHandledVariables=iHandledVariables,
                                                            iThreadCacheLines=iThreadCacheLines, iSharedCacheLines=iSharedCacheLines), (cacheMap,cacheMapMeta,numCL));
    //printCacheMap(cacheMap);
    //print("===================================================\n===================================================\n===================================================\n");
    CACHEMAP(cacheVariables=cacheVariables) := cacheMap;
    oInfo := (cacheMap,cacheMapMeta,createdCL,level+1);
  end createCacheMapLevelFixedOptimizedForLevel;

  protected function createCacheMapLevelFixedOptimizedForTask "author: marcusw
    Append the variables that are solved by the given task to the cachelines."
    input HpcOmSimCode.Task iTask;
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input Integer iNumberOfThreads;
    input Integer iLevel;
    input array<ScVarInfo> iScVarInfos;
    input array<list<Integer>> iTaskSolvedVarsMapping;
    input array<list<Integer>> iTaskUnsolvedVarsMapping;
    input array<Boolean> iHandledVariables; //true if the variable was already added to a cache line
    input array<CacheLines> iThreadCacheLines; //Thread CacheLines for float, int and bool
    input array<tuple<PartlyFilledCacheLines, CacheLines>> iSharedCacheLines;
    input tuple<CacheMap,CacheMapMeta,Integer> iInfo; //<CacheMap,CacheMapMeta,numNewCL>
    output tuple<CacheMap,CacheMapMeta,Integer> oInfo;
  protected
    list<Integer> nodeIdc, solvedVars, unsolvedVars;
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    tuple<CacheMap,CacheMapMeta,Integer> tmpInfo;
    Integer threadIdx, numNewCL;
    array<Option<SimCodeVar.SimVar>> allSCVarsMapping;

    list<SimCodeVar.SimVar> cacheVariables;
  algorithm
    oInfo := match(iTask, iTaskGraph, iTaskGraphMeta, iSchedulerInfo, iNumberOfThreads, iLevel, iScVarInfos, iTaskSolvedVarsMapping, iTaskUnsolvedVarsMapping, iHandledVariables, iThreadCacheLines, iSharedCacheLines, iInfo)
      case(HpcOmSimCode.CALCTASK_LEVEL(nodeIdc=nodeIdc,threadIdx=SOME(threadIdx)),_,_,_,_,_,_,_,_,_,_,_,(cacheMap,cacheMapMeta as CACHEMAPMETA(allSCVarsMapping=allSCVarsMapping),numNewCL))
        equation
          solvedVars = List.flatten(List.map(nodeIdc, function arrayGet(arr=iTaskSolvedVarsMapping))); //there should be no duplicates
          unsolvedVars = getUnsolvedVarsByNodeList(nodeIdc, arrayLength(iScVarInfos), iTaskUnsolvedVarsMapping);
          tmpInfo = List.fold(listAppend(solvedVars,unsolvedVars), function createCacheMapOptimizedForTask1(iThreadIdx=threadIdx,iScVarInfos=iScVarInfos,
                                                    iHandledVariables=iHandledVariables,iSharedClSelectFunction=findMatchingSharedCLLevelfix,iCompareFuncArgument=(iLevel,threadIdx),
                                                    iFactoryMethod=createSharedClLevelFix,iThreadCacheLines=iThreadCacheLines,iSharedCacheLines=iSharedCacheLines),
                                                    (cacheMap, cacheMapMeta, numNewCL));
          CACHEMAP(cacheVariables=cacheVariables) = Util.tuple31(tmpInfo);
        then tmpInfo;
      case(HpcOmSimCode.CALCTASK_LEVEL(nodeIdc=nodeIdc,threadIdx=NONE()),_,_,_,_,_,_,_,_,_,_,_,_)
        equation
          print("createCacheMapLevelOptimized1: Calctask without threadIdx given\n");
        then fail();
      else
        equation
          print("createCacheMapLevelOptimized1: Unsupported task type\n");
        then fail();
    end match;
  end createCacheMapLevelFixedOptimizedForTask;

  protected function getUnsolvedVarsByNodeList
    input list<Integer> iNodeList;
    input Integer iVarCount;
    input array<list<Integer>> iTaskUnsolvedVarsMapping;
    output list<Integer> oUnsolvedVars;
  protected
    array<Boolean> varMarks;
    Integer nodeIdx, varIdx;
    list<Integer> nodeUnsolvedVars;
    list<Integer> tmpUnsolvedVars = {};
  algorithm
    varMarks := arrayCreate(iVarCount, false);
    for nodeIdx in iNodeList loop
      nodeUnsolvedVars := arrayGet(iTaskUnsolvedVarsMapping, nodeIdx);
      for varIdx in nodeUnsolvedVars loop
        if(boolNot(arrayGet(varMarks, varIdx))) then
          tmpUnsolvedVars := varIdx::tmpUnsolvedVars;
          varMarks := arrayUpdate(varMarks, varIdx, true);
        end if;
      end for;
    end for;
    oUnsolvedVars := tmpUnsolvedVars;
  end getUnsolvedVarsByNodeList;

  protected function createCacheMapThreadOptimized "author: marcusw
    Create the optimized cache map for the thread-scheduler."
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input array<Option<SimCodeVar.SimVar>> iAllSCVarsMapping;
    input array<tuple<Integer,Integer,Integer>> iSimCodeVarTypes; //<type, numberOfBytesRequired>
    input array<Integer> iScVarSolvedTaskMapping;
    input array<list<Integer>> iScVarUnsolvedTaskMapping;
    input Integer iCacheLineSize;
    input BackendDAE.StrongComponents iAllComponents;
    input array<list<HpcOmSimCode.Task>> iThreadTasks;  //Schedule
    input Integer iNumberOfThreads;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input array<list<Integer>> iTaskSolvedVarsMapping;
    input array<list<Integer>> iTaskUnsolvedVarsMapping;
    input array<ScVarInfo> iScVarInfos;
    output CacheMap oCacheMap;
    output array<tuple<Integer,Integer>> oScVarCLMapping; //mapping for each scVar -> <CLIdx,varType>
    output Integer oNumCL;
  protected
    array<CacheLines> threadCacheLines;
    array<tuple<PartlyFilledCacheLines, CacheLines>> sharedCacheLines;
    tuple<CacheMap,CacheMapMeta,Integer> tmpCacheInfo;
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    array<tuple<Integer,Integer>> scVarCLMapping;
    array<Boolean> handledVariables;
  algorithm
    //Initialize variables
    threadCacheLines := arrayCreate(iNumberOfThreads, ({},{},{}));
    sharedCacheLines := arrayCreate(iNumberOfThreads, (({},{},{}), ({},{},{})));
    handledVariables := arrayCreate(arrayLength(iSimCodeVarTypes), false);

    cacheMap := CACHEMAP(iCacheLineSize,{},{},{},{});
    scVarCLMapping := arrayCreate(arrayLength(iAllSCVarsMapping),(-1,-1));
    oNumCL := 0;
    cacheMapMeta := CACHEMAPMETA(iAllSCVarsMapping, iSimCodeVarTypes, scVarCLMapping);
    tmpCacheInfo := (cacheMap, cacheMapMeta, oNumCL);

    for threadIdx in 1:iNumberOfThreads loop
      //print("======================================================================\n");
      //print("createCacheMapThreadOptimized: Handling thread " + intString(threadIdx) + " with " + intString(oNumCL) + " cache lines\n");
      //print("======================================================================\n");
      ((cacheMap, cacheMapMeta, oNumCL)) := List.fold(arrayGet(iThreadTasks, threadIdx), function createCacheMapOptimizedForTask(
                        iTaskGraph=iTaskGraph, iTaskGraphMeta=iTaskGraphMeta, iSchedulerInfo=iSchedulerInfo, iTaskSolvedVarsMapping=iTaskSolvedVarsMapping,
                        iTaskUnsolvedVarsMapping=iTaskUnsolvedVarsMapping, iHandledVariables=handledVariables, iNumberOfThreads=iNumberOfThreads,
                        iSharedClSelectFunction=findMatchingSharedCLThread, iCompareFuncArgument=0, iFactoryMethod=createSharedClThread, iScVarInfos=iScVarInfos,
                        iThreadCacheLines=threadCacheLines, iSharedCacheLines=sharedCacheLines), tmpCacheInfo);

      cacheMap := createCacheMapFromThreadAndSharedCLs(arrayGet(threadCacheLines, threadIdx), arrayGet(sharedCacheLines, threadIdx), cacheMap);

      tmpCacheInfo := (cacheMap, cacheMapMeta, oNumCL);
    end for;

    oCacheMap := Util.tuple31(tmpCacheInfo);
    CACHEMAPMETA(scVarCLMapping=oScVarCLMapping) := cacheMapMeta;
  end createCacheMapThreadOptimized;

  protected function createCacheMapOptimizedForTask<T> "author: marcusw
    Append the variables that are solved by the given task to the cachelines."
    input HpcOmSimCode.Task iTask;
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input array<list<Integer>> iTaskSolvedVarsMapping;
    input array<list<Integer>> iTaskUnsolvedVarsMapping;
    input array<Boolean> iHandledVariables; //true if the variable was already added to a cache line
    input Integer iNumberOfThreads;
    input HeuristicFunction iSharedClSelectFunction; //the function that will search for the ideal cache line to store a given variable
    input T iCompareFuncArgument;
    input FactoryMethod iFactoryMethod; //function to create a partly filled cache line object
    input array<CacheLines> iThreadCacheLines; //Thread exclusive CacheLines for float, int and bool
    input array<tuple<PartlyFilledCacheLines, CacheLines> > iSharedCacheLines; //Thread shared CacheLines for float, int and bool
    input array<ScVarInfo> iScVarInfos;
    input tuple<CacheMap,CacheMapMeta,Integer> iInfo; //<CacheMap,CacheMapMeta,numOfCLs>
    output tuple<CacheMap,CacheMapMeta,Integer> oInfo;

    partial function HeuristicFunction
      input Integer iNodeVar;
      input Integer iVarSize; //number of required bytes
      input Integer iVarType;
      input Integer iThreadIdx;
      input T inElement;
      input array<tuple<PartlyFilledCacheLines, CacheLines> > iSharedCacheLines;
      output Option<tuple<PartlyFilledCacheLine, Integer>> oMatchedCacheLine; //<CL, listIndex>
    end HeuristicFunction;

    partial function FactoryMethod
      input Option<PartlyFilledCacheLine> iOldPartlyFilledCacheLine;
      input CacheLineMap iCacheLineMap;
      input T iAdditionalArguments;
      output PartlyFilledCacheLine oCreatedCacheLine;
    end FactoryMethod;
  protected
    Integer threadIdx, taskIdx;
    list<Integer> solvedVars, unsolvedVars, vars;
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    Integer numOfCLs;
    tuple<CacheMap,CacheMapMeta,Integer> tmpInfo;
    array<Option<SimCodeVar.SimVar>> allSCVarsMapping;
    ScVarInfo varInfo;
  algorithm
    oInfo := match(iTask, iTaskGraph, iTaskGraphMeta, iSchedulerInfo, iTaskSolvedVarsMapping, iTaskUnsolvedVarsMapping, iHandledVariables, iNumberOfThreads, iSharedClSelectFunction, iCompareFuncArgument, iFactoryMethod, iThreadCacheLines, iSharedCacheLines, iScVarInfos, iInfo)
      case(HpcOmSimCode.CALCTASK(index=taskIdx, threadIdx=threadIdx),_,_,_,_,_,_,_,_,_,_,_,_,_,(cacheMap, cacheMapMeta as CACHEMAPMETA(allSCVarsMapping=allSCVarsMapping), numOfCLs))
        equation
          solvedVars = arrayGet(iTaskSolvedVarsMapping, taskIdx);
          unsolvedVars = arrayGet(iTaskUnsolvedVarsMapping, taskIdx);
          vars = List.sort(listAppend(solvedVars,unsolvedVars), intGt);
          //print("createCacheMapOptimizedForTask: Vars for task " + stringDelimitList(List.map(vars, intString), ",") + "\n");
          tmpInfo = List.fold(vars, function createCacheMapOptimizedForTask1(iThreadIdx=threadIdx, iScVarInfos=iScVarInfos, iHandledVariables=iHandledVariables,
                            iSharedClSelectFunction=iSharedClSelectFunction, iCompareFuncArgument=iCompareFuncArgument, iFactoryMethod=iFactoryMethod, iThreadCacheLines=iThreadCacheLines,
                            iSharedCacheLines=iSharedCacheLines), (cacheMap, cacheMapMeta, numOfCLs));
        then tmpInfo;
      case(HpcOmSimCode.DEPTASK(_),_,_,_,_,_,_,_,_,_,_,_,_,_,(cacheMap, cacheMapMeta as CACHEMAPMETA(allSCVarsMapping=allSCVarsMapping), numOfCLs))
        then iInfo;
      else
        equation
          print("createCacheMapThreadOptimizedForTask failed!\n");
        then iInfo;
    end match;
  end createCacheMapOptimizedForTask;

  protected function createCacheMapOptimizedForTask1<T>
    input Integer iScVar;
    input Integer iThreadIdx;
    input array<ScVarInfo> iScVarInfos;
    input array<Boolean> iHandledVariables;
    input HeuristicFunction iSharedClSelectFunction; //the function that will search for the ideal cache line to store a given variable
    input T iCompareFuncArgument;
    input FactoryMethod iFactoryMethod; //function to create a partly filled cache line object
    input array<CacheLines> iThreadCacheLines; //Thread exclusive CacheLines for float, int and bool
    input array<tuple<PartlyFilledCacheLines, CacheLines> > iSharedCacheLines; //Thread shared CacheLines for float, int and bool (partly and fully filled)
    input tuple<CacheMap,CacheMapMeta,Integer> iInfo; //<CacheMap,CacheMapMeta,numOfCLs>
    output tuple<CacheMap,CacheMapMeta,Integer> oInfo;

    partial function HeuristicFunction
      input Integer iNodeVar;
      input Integer iVarSize; //number of required bytes
      input Integer iVarType;
      input Integer iThreadIdx;
      input T inElement;
      input array<tuple<PartlyFilledCacheLines, CacheLines> > iSharedCacheLines;
      output Option<tuple<PartlyFilledCacheLine, Integer>> oMatchedCacheLine; //<CL, listIndex>
    end HeuristicFunction;

    partial function FactoryMethod
      input Option<PartlyFilledCacheLine> iOldPartlyFilledCacheLine;
      input CacheLineMap iCacheLineMap;
      input T iAdditionalArguments;
      output PartlyFilledCacheLine oCreatedCacheLine;
    end FactoryMethod;
  protected
    Boolean isShared;
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    Integer numOfCLs;
    Integer ownerThread;
  algorithm
    ((cacheMap, cacheMapMeta, numOfCLs)) := iInfo;
    SCVARINFO(ownerThread,isShared) := arrayGet(iScVarInfos, iScVar);
    //print("createCacheMapThreadOptimizedForTask1: Handling sc-var " + intString(iScVar) + ". Owner thread is " + intString(ownerThread) + " Number of cache lines is " + intString(numOfCLs) + "\n");
    if(boolAnd(boolNot(boolAnd(intEq(ownerThread,-1), isShared)), boolNot(arrayGet(iHandledVariables, iScVar)))) then
      //print("Variable " + intString(iScVar) + " was not already handled\n");
      if(isShared) then
        //print("--> Handling as shared variable\n");
        ((cacheMap,cacheMapMeta,numOfCLs)) := addVarsToSharedCL({iScVar}, iSharedClSelectFunction, iFactoryMethod, iThreadIdx, iCompareFuncArgument, iSharedCacheLines, (cacheMap,cacheMapMeta,numOfCLs));
      else
        //print("--> Handling as thread variable\n");
        ((cacheMap,cacheMapMeta,numOfCLs)) := addVarsToThreadCL({iScVar},iThreadIdx,iThreadCacheLines,(cacheMap,cacheMapMeta,numOfCLs));
      end if;
    else
      //print("createCacheMapOptimizedForTask1: Skipping variable '" + intString(iScVar) + "'\n");
    end if;
    _ := arrayUpdate(iHandledVariables, iScVar, true);
    oInfo := (cacheMap,cacheMapMeta,numOfCLs);
  end createCacheMapOptimizedForTask1;

  protected function createVarInfos
    input array<Integer> iScVarSolvedTaskMapping;
    input array<list<Integer>> iScVarUnsolvedTaskMapping;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo; //maps each Task to <threadId, orderId, startCalcTime>
    output array<ScVarInfo> oVarInfos;
  protected
    array<ScVarInfo> tmpVarInfos;
    Integer scVarIdx, numberOfScVars;
  algorithm
    numberOfScVars := arrayLength(iScVarSolvedTaskMapping);
    tmpVarInfos := arrayCreate(numberOfScVars, SCVARINFO(-1,false));
    for scVarIdx in 1:numberOfScVars loop
      tmpVarInfos := arrayUpdate(tmpVarInfos, scVarIdx, getVarInfoByScVarIdx(scVarIdx, iScVarSolvedTaskMapping, iScVarUnsolvedTaskMapping, iSchedulerInfo));
    end for;
    oVarInfos := tmpVarInfos;
  end createVarInfos;

  protected function getVarInfoByScVarIdx
    input Integer iScVarIdx;
    input array<Integer> iScVarSolvedTaskMapping;
    input array<list<Integer>> iScVarUnsolvedTaskMapping;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo; //maps each Task to <threadId, orderId, startCalcTime>
    output ScVarInfo oVarInfo;
  protected
    Integer solvingThreadIdx, solvingTaskIdx, listLen;
    Integer owner = -1;
    Boolean isShared = false;
    list<Integer> threads = {};
    list<Integer> unsolvingThreadIdc, unsolvingTaskIdc;
  algorithm
    solvingTaskIdx := arrayGet(iScVarSolvedTaskMapping, iScVarIdx);
    unsolvingTaskIdc := arrayGet(iScVarUnsolvedTaskMapping, iScVarIdx);
    //print("getVarInfoByScVarIdx: Handling variable '" + intString(iScVarIdx) + "' with unsolving tasks " + stringDelimitList(List.map(unsolvingTaskIdc, intString), ",") + "\n");
    if(intGt(solvingTaskIdx, 0)) then
      solvingThreadIdx := Util.tuple31(arrayGet(iSchedulerInfo, solvingTaskIdx));
      owner := solvingThreadIdx;
      threads := owner::threads;
    end if;
    listLen := listLength(unsolvingTaskIdc);
    unsolvingThreadIdc := List.map(List.map(unsolvingTaskIdc, function arrayGet(arr=iSchedulerInfo)), Util.tuple31);
    //print("getVarInfoByScVarIdx: --> unsolving threads are " + stringDelimitList(List.map(unsolvingThreadIdc, intString), ",") + "\n");
    if(intEq(listLen, 1)) then
      if(intLt(owner, 0)) then
        owner := listHead(unsolvingThreadIdc);
        threads := owner::threads;
      else
        isShared := true;
      end if;
    end if;
    if(intGt(listLen, 1)) then
      threads := List.unique(listAppend(unsolvingThreadIdc, threads));
      isShared := true;
    end if;
    oVarInfo := SCVARINFO(owner, isShared);
  end getVarInfoByScVarIdx;

  protected function addVarsToThreadCL "author: marcusw
    Add the given variables as thread-only variable to the cache lines."
    input list<Integer> iNodeVars;
    input Integer iThreadIdx;
    input array<CacheLines> iThreadCacheLines; //Thread CacheLines for float, int and bool
    input tuple<CacheMap,CacheMapMeta,Integer> iInfo; //<CacheMap,CacheMapMeta,numCLs>
    output tuple<CacheMap,CacheMapMeta,Integer> oInfo;
  protected
    CacheLineMap lastCL;
    SimCodeVar.SimVar cacheVariable;
    array<Option<SimCodeVar.SimVar>> allSCVarsMapping;
    Integer varIdx, varDataType, varNumBytesRequired, numCLs, cacheLineSize;
    array<tuple<Integer,Integer,Integer>> simCodeVarTypes; //<varDataType, numberOfBytesRequired, varType>
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
    (CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat, cacheLinesInt=cacheLinesInt, cacheLinesBool=cacheLinesBool),CACHEMAPMETA(allSCVarsMapping=allSCVarsMapping,simCodeVarTypes=simCodeVarTypes,scVarCLMapping=scVarCLMapping),numCLs) := iInfo;

    //only the first CL has enough space to store another variable
    for varIdx in iNodeVars loop
      ((varDataType,varNumBytesRequired,_)) := arrayGet(simCodeVarTypes, varIdx);
      (threadCacheLinesFloat,threadCacheLinesInt,threadCacheLinesBool,threadCacheLines) := getCacheLineForVarType(varDataType, arrayGet(iThreadCacheLines, iThreadIdx));

      if(intGt(listLength(threadCacheLines), 0)) then
        lastCL::fullCLs := threadCacheLines;
      else
        lastCLidx := numCLs + 1;
        lastCLnumBytesFree := cacheLineSize;
        lastCLentries := {};
        lastCL := CACHELINEMAP(idx=lastCLidx, numBytesFree=lastCLnumBytesFree, entries=lastCLentries);
        numCLs := numCLs + 1;
        fullCLs := {};
      end if;

      CACHELINEMAP(idx=lastCLidx,numBytesFree=lastCLnumBytesFree,entries=lastCLentries) := lastCL;
      if(intLt(lastCLnumBytesFree,varNumBytesRequired)) then //variable does not fit into CL --> create a new CL
        //print("\t\t\t\taddVarsToThreadCL: variable " + intString(varIdx) + " does not fit into lastCL.\n");
        fullCLs := lastCL::fullCLs;
        lastCLidx := numCLs + 1;
        //print("\t\t\t\taddVarsToThreadCL: lastCLidx " + intString(listLength(cacheLinesFloat)) + " + " + intString(numCLs) + " + 1\n");
        lastCLnumBytesFree := cacheLineSize;
        lastCLentries := {};
        lastCL := CACHELINEMAP(idx=lastCLidx, numBytesFree=lastCLnumBytesFree, entries=lastCLentries);
        numCLs := numCLs + 1;
      end if;
      //  print("addVarsToThreadCL: adding variable '" + intString(listLength(cacheVariables)) + "'\n");
      SOME(cacheVariable as SimCodeVar.SIMVAR(name=cacheVarName)) := arrayGet(allSCVarsMapping, varIdx);
      //print("addVarsToThreadCL: Variable " + ComponentReference.printComponentRefStr(cacheVarName) + " has type " + intString(varDataType) + "\n");

      //print("addVarsToThreadCL: adding variable '" + intString(listLength(cacheVariables)) + "' [" + dumpSimCodeVar(cacheVariable) + "] to cache line map '" + intString(lastCLidx) + "'\n");
      //print("\t\t\t\taddVarsToThreadCL: cacheVariable found.\n");
      cacheVariables := cacheVariable::cacheVariables;
      scVarCLMapping := arrayUpdate(scVarCLMapping, varIdx, (lastCLidx,varDataType));
      //print("\t\t\tCache variables: " + intString(listLength(cacheVariables)) + " to thread " + intString(iThreadIdx) + "\n");
      varEntry := CACHELINEENTRY(start=cacheLineSize-lastCLnumBytesFree,dataType=varDataType,size=varNumBytesRequired,scVarIdx=listLength(cacheVariables),threadOwner=iThreadIdx);
      lastCL := CACHELINEMAP(idx=lastCLidx,numBytesFree=lastCLnumBytesFree-varNumBytesRequired,entries=varEntry::lastCLentries);

      _ := arrayUpdate(iThreadCacheLines, iThreadIdx, contractCacheLineForVarType(varDataType, threadCacheLinesFloat, threadCacheLinesInt, threadCacheLinesBool, lastCL::fullCLs));
    end for;

    oInfo := (CACHEMAP(cacheLineSize,cacheVariables,cacheLinesFloat,cacheLinesInt,cacheLinesBool),CACHEMAPMETA(allSCVarsMapping,simCodeVarTypes,scVarCLMapping),numCLs);
  end addVarsToThreadCL;

  protected function getCacheLineForVarType "author: marcusw
    Get all cache lines of the given array, separated by their types. The cache lines that should be used to store the given data type, are
    additionally returned as last argument."
    input Integer iVarDataType;
    input CacheLines iCacheLinesForTypes;
    output list<CacheLineMap> oCacheLinesFloat;
    output list<CacheLineMap> oCacheLinesInt;
    output list<CacheLineMap> oCacheLinesBool;
    output list<CacheLineMap> oVarCacheLines; //one of the 3 types above
  algorithm
    ((oCacheLinesFloat,oCacheLinesInt,oCacheLinesBool)) := iCacheLinesForTypes;
    if(intEq(iVarDataType, VARDATATYPE_FLOAT)) then
      //print("addVarsToThreadCL: Found REAL-VARIABLE!\n");
      ((oVarCacheLines,_,_)) := iCacheLinesForTypes;
    else
      if(intEq(iVarDataType, VARDATATYPE_INTEGER)) then
        //print("addVarsToThreadCL: Found INT-VARIABLE!\n");
        ((_,oVarCacheLines,_)) := iCacheLinesForTypes;
      else
        if(intEq(iVarDataType, VARDATATYPE_BOOLEAN)) then
          //print("addVarsToThreadCL: Found BOOL-VARIABLE!\n");
          ((_,_,oVarCacheLines)) := iCacheLinesForTypes;
        else
          print("getCacheLineForVarType: Found Variable with unknown type ( " + intString(iVarDataType) + ")!\n");
        end if;
      end if;
    end if;
  end getCacheLineForVarType;

  protected function contractCacheLineForVarType "author: marcusw
    Get all cache lines of the given array, separated by their types. The cache lines that should be used to store the given data type, are
    additionally returned as last argument."
    input Integer iVarDataType;
    input list<CacheLineMap> iCacheLinesFloat;
    input list<CacheLineMap> iCacheLinesInt;
    input list<CacheLineMap> iCacheLinesBool;
    input list<CacheLineMap> iVarCacheLines;
    output CacheLines oContractedCacheLines;
  algorithm
    if(intEq(iVarDataType, VARDATATYPE_FLOAT)) then
      oContractedCacheLines := (iVarCacheLines, iCacheLinesInt, iCacheLinesBool);
    else
      if(intEq(iVarDataType, VARDATATYPE_INTEGER)) then
        oContractedCacheLines := (iCacheLinesFloat, iVarCacheLines, iCacheLinesBool);
      else
        if(intEq(iVarDataType, VARDATATYPE_BOOLEAN)) then
          oContractedCacheLines := (iCacheLinesFloat, iCacheLinesInt, iVarCacheLines);
        end if;
      end if;
    end if;
  end contractCacheLineForVarType;

  protected function addVarsToSharedCL<T> "author: marcusw
    Append the given variables to shared cache lines. If a matching partly filled cache line is found,
    the partly filled cache line object is updates. Otherwise a new cache line object is created. If a cacheline
    is filled completely, it is appended to the CacheLines-structure of iSharedCacheLines."
    input list<Integer> iNodeVars;
    input HeuristicFunction iSharedClSelectFunction; //the function that will search for the ideal cache line to store a given variable
    input FactoryMethod iFactoryMethod; //function to create a partly filled cache line object
    input Integer iThreadIdx;
    input T iCompareFuncArgument;
    input array<tuple<PartlyFilledCacheLines, CacheLines> > iSharedCacheLines; //partly filled cache lines and fully shared cache lines
    input tuple<CacheMap,CacheMapMeta,Integer> iInfo; //<CacheMapMeta,NumOfCLs>
    output tuple<CacheMap,CacheMapMeta,Integer> oInfo;

    partial function HeuristicFunction
      input Integer iNodeVar;
      input Integer iVarSize; //number of required bytes
      input Integer iVarType;
      input Integer iThreadIdx;
      input T inElement;
      input array<tuple<PartlyFilledCacheLines, CacheLines> > iSharedCacheLines;
      output Option<tuple<PartlyFilledCacheLine, Integer>> oMatchedCacheLine; //<CL, listIndex>
    end HeuristicFunction;

    partial function FactoryMethod
      input Option<PartlyFilledCacheLine> iOldPartlyFilledCacheLine;
      input CacheLineMap iCacheLineMap;
      input T iAdditionalArguments;
      output PartlyFilledCacheLine oCreatedCacheLine;
    end FactoryMethod;

  protected
    CacheLineMap lastCL;
    SimCodeVar.SimVar cacheVariable;
    array<Option<SimCodeVar.SimVar>> allSCVarsMapping;
    Integer varIdx, varDataType, varNumBytesRequired, numOfCLs, cacheLineSize, varSize;
    array<tuple<Integer,Integer,Integer>> simCodeVarTypes; //<varDataType, numberOfBytesRequired,varType>
    array<tuple<Integer, Integer>> scVarCLMapping;
    list<CacheLineMap> fullCLs, threadCacheLines;
    list<SimCodeVar.SimVar> cacheVariables;
    list<CacheLineMap> cacheLinesFloat;
    Integer matchedCacheLineIdx;
    CacheMap cacheMap;
    CacheMapMeta cacheMapMeta;
    Option<tuple<PartlyFilledCacheLine,Integer>> matchedCacheLine;
  algorithm
    (cacheMap as CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat),cacheMapMeta as CACHEMAPMETA(allSCVarsMapping=allSCVarsMapping,simCodeVarTypes=simCodeVarTypes,scVarCLMapping=scVarCLMapping),numOfCLs) := iInfo;
    for varIdx in iNodeVars loop
      ((varDataType,varSize,_)) := arrayGet(simCodeVarTypes, varIdx);
      //print("addVarsToSharedCL: varIdx=" + intString(varIdx) + " varType=" + intString(varDataType) + "\n");
      matchedCacheLine := iSharedClSelectFunction(varIdx, varSize, varDataType, iThreadIdx, iCompareFuncArgument, iSharedCacheLines);
      ((cacheMap,cacheMapMeta,numOfCLs)) := addVarsToSharedCL0(matchedCacheLine, varIdx, iFactoryMethod, iCompareFuncArgument, iThreadIdx, iSharedCacheLines, (cacheMap,cacheMapMeta,numOfCLs));
    end for;
    oInfo := (cacheMap,cacheMapMeta,numOfCLs);
  end addVarsToSharedCL;

  protected function addVarsToSharedCL0<T> "author: marcusw
    Add the given variable to the iMatchedCacheLine if the object is not NONE() and if there is enough space.
    Otherwise add a new CL."
    input Option<tuple<PartlyFilledCacheLine,Integer>> iMatchedCacheLine; //<CL, listIndex>
    input Integer iVarIdx;
    input FactoryMethod iFactoryMethod; //method to create a new shared cache line object
    input T iAdditionalArgument;
    input Integer iThreadIdx;
    input array<tuple<PartlyFilledCacheLines, CacheLines> > iSharedCacheLines; //partly filled cache lines and fully shared cache lines
    input tuple<CacheMap,CacheMapMeta,Integer> iInfo; //<CacheMapMeta,NumOfCLs>
    output tuple<CacheMap,CacheMapMeta,Integer> oInfo;

    partial function FactoryMethod
      input Option<PartlyFilledCacheLine> iOldPartlyFilledCacheLine;
      input CacheLineMap iCacheLineMap;
      input T iAdditionalArguments;
      output PartlyFilledCacheLine oCreatedCacheLine;
    end FactoryMethod;

  protected
    PartlyFilledCacheLines threadPartlyFilledCacheLines;
    list<PartlyFilledCacheLine> partlyFilledClFloat, partlyFilledClInt, partlyFilledClBool;
    CacheLines threadFullyFilledCacheLines;
    list<CacheLineMap> fullyFilledClFloat, fullyFilledClInt, fullyFilledClBool;
    array<Option<SimCodeVar.SimVar>> allSCVarsMapping;
    array<tuple<Integer,Integer,Integer>> simCodeVarTypes; //<varDataType, numberOfBytesRequired, varType>
    array<tuple<Integer, Integer>> scVarCLMapping; //mapping for each scVar -> <CLIdx,varType>
    PartlyFilledCacheLine partlyFilledCacheLine;
    Option<PartlyFilledCacheLine> partlyFilledCacheLineOption;
    Integer matchedClIndex, numOfCLs, clMapIdx, clMapNumBytesFree, varDataType, varSize, cacheLineSize;
    list<SimCodeVar.SimVar> cacheVariables;
    list<CacheLineMap> cacheLinesFloat, cacheLinesInt, cacheLinesBool;
    list<CacheLineEntry> clMapEntries;
    CacheLineEntry entry;
    CacheLineMap cacheLineMap;
    SimCodeVar.SimVar cacheVariable;
  algorithm
    (CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat,cacheLinesInt=cacheLinesInt,cacheLinesBool=cacheLinesBool),CACHEMAPMETA(allSCVarsMapping=allSCVarsMapping,simCodeVarTypes=simCodeVarTypes,scVarCLMapping=scVarCLMapping),numOfCLs) := iInfo;
    ((varDataType,varSize,_)) := arrayGet(simCodeVarTypes, iVarIdx);
    ((threadPartlyFilledCacheLines,threadFullyFilledCacheLines)) := arrayGet(iSharedCacheLines, iThreadIdx);
    (partlyFilledClFloat, partlyFilledClInt, partlyFilledClBool) := threadPartlyFilledCacheLines;
    (fullyFilledClFloat, fullyFilledClInt, fullyFilledClBool) := threadFullyFilledCacheLines;

    if(isSome(iMatchedCacheLine)) then //advice was given, to which CL the variable should be added
      clMapIdx := numOfCLs;
      SOME((partlyFilledCacheLine, matchedClIndex)) := iMatchedCacheLine;
      partlyFilledCacheLineOption := SOME(partlyFilledCacheLine);
      CACHELINEMAP(clMapIdx,clMapNumBytesFree,clMapEntries) := getCacheLineMapOfPartlyFilledCacheLine(partlyFilledCacheLine);
    else
      //print("addVarsToSharedCL0: no advice was given\n");
      numOfCLs := numOfCLs + 1;
      partlyFilledCacheLineOption := NONE();
      clMapIdx := numOfCLs;
      clMapNumBytesFree := cacheLineSize;
      clMapEntries := {};
      matchedClIndex := -1;
    end if;
    clMapNumBytesFree := clMapNumBytesFree - varSize;
    SOME(cacheVariable) := arrayGet(allSCVarsMapping, iVarIdx);
    cacheVariables := cacheVariable::cacheVariables;
    entry := CACHELINEENTRY(cacheLineSize - clMapNumBytesFree - varSize, varDataType, varSize, listLength(cacheVariables), iThreadIdx);

    //print("addVarsToSharedCL0: adding variable '" + intString(listLength(cacheVariables) - 1) + "' [" + dumpSimCodeVar(cacheVariable) + "] to cache line map '" + intString(clMapIdx) + "'\n");
    cacheLineMap := CACHELINEMAP(clMapIdx,clMapNumBytesFree,entry::clMapEntries);

    partlyFilledCacheLine := iFactoryMethod(partlyFilledCacheLineOption, cacheLineMap, iAdditionalArgument);
    scVarCLMapping := arrayUpdate(scVarCLMapping, iVarIdx, (clMapIdx,varDataType));

    if(intEq(clMapNumBytesFree, 0)) then //CL is now full - remove it from partly filled CL list and add it to cachemap
      if(intEq(varDataType, VARDATATYPE_FLOAT)) then
        partlyFilledClFloat := listDelete(partlyFilledClFloat, matchedClIndex);
        fullyFilledClFloat := cacheLineMap::fullyFilledClFloat;
      else
        if(intEq(varDataType, VARDATATYPE_INTEGER)) then
          partlyFilledClInt := listDelete(partlyFilledClInt, matchedClIndex);
          fullyFilledClInt := cacheLineMap::fullyFilledClInt;
        else
          partlyFilledClBool := listDelete(partlyFilledClBool, matchedClIndex);
          fullyFilledClBool := cacheLineMap::fullyFilledClBool;
        end if;
      end if;
    else
      if(intNe(matchedClIndex, -1)) then
        if(intEq(varDataType, VARDATATYPE_FLOAT)) then
          partlyFilledClFloat := List.set(partlyFilledClFloat, matchedClIndex, partlyFilledCacheLine);
        else
          if(intEq(varDataType, VARDATATYPE_INTEGER)) then
            partlyFilledClInt := List.set(partlyFilledClInt, matchedClIndex, partlyFilledCacheLine);
          else
            partlyFilledClBool := List.set(partlyFilledClBool, matchedClIndex, partlyFilledCacheLine);
          end if;
        end if;
      else
        if(intEq(varDataType, VARDATATYPE_FLOAT)) then
          partlyFilledClFloat := partlyFilledCacheLine::partlyFilledClFloat;
        else
          if(intEq(varDataType, VARDATATYPE_INTEGER)) then
            partlyFilledClInt := partlyFilledCacheLine::partlyFilledClInt;
          else
            partlyFilledClBool := partlyFilledCacheLine::partlyFilledClBool;
          end if;
        end if;
      end if;
    end if;

    _ := arrayUpdate(iSharedCacheLines, iThreadIdx, ((partlyFilledClFloat, partlyFilledClInt, partlyFilledClBool), (fullyFilledClFloat, fullyFilledClInt, fullyFilledClBool)));
    oInfo := (CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat,cacheLinesInt=cacheLinesInt,cacheLinesBool=cacheLinesBool),CACHEMAPMETA(allSCVarsMapping=allSCVarsMapping,simCodeVarTypes=simCodeVarTypes,scVarCLMapping=scVarCLMapping),numOfCLs);
  end addVarsToSharedCL0;

  protected function getPartlyFilledCLByVarType
    input Integer iVarType;
    input PartlyFilledCacheLines iSharedCacheLines;
    output list<PartlyFilledCacheLine> oSharedCacheLinesForType;
  algorithm
    if(intEq(iVarType, VARDATATYPE_FLOAT)) then
      oSharedCacheLinesForType := Util.tuple31(iSharedCacheLines);
    else
      if(intEq(iVarType, VARDATATYPE_INTEGER)) then
        oSharedCacheLinesForType := Util.tuple32(iSharedCacheLines);
      else
        oSharedCacheLinesForType := Util.tuple33(iSharedCacheLines);
      end if;
    end if;
  end getPartlyFilledCLByVarType;

  protected function findMatchingSharedCLLevelfix "author: marcusw
    Iterate over the given shared cache line list and return the first entry that can be used to store the shared variable iNodeVar."
    input Integer iNodeVar;
    input Integer iVarSize; //number of required bytes
    input Integer iVarType;
    input Integer iThreadIdx;
    input tuple<Integer,Integer> iLevelThreadIdx;
    input array<tuple<PartlyFilledCacheLines, CacheLines>> iSharedCacheLines;
    output Option<tuple<PartlyFilledCacheLine,Integer>> oMatchedCacheLine; //<CL, listIndex>
  protected
    list<PartlyFilledCacheLine> partlyFilledCacheLines;
    PartlyFilledCacheLines sharedCacheLines;
    Integer levelIdx;
  algorithm
    ((levelIdx,_)) := iLevelThreadIdx;
    sharedCacheLines := Util.tuple21(arrayGet(iSharedCacheLines, iThreadIdx));
    oMatchedCacheLine := NONE();
    partlyFilledCacheLines := getPartlyFilledCLByVarType(iVarType, sharedCacheLines);
    oMatchedCacheLine := findMatchingSharedCLLevelfix0(iNodeVar, iVarSize, levelIdx, iThreadIdx, 1, partlyFilledCacheLines);
  end findMatchingSharedCLLevelfix;

  protected function findMatchingSharedCLLevelfix0 "author: marcusw
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
      case(_,_,_,_,_,(head as PARTLYFILLEDCACHELINE_LEVEL(cacheLineMap=(cacheLineMap as CACHELINEMAP(numBytesFree=numBytesFree)),prefetchLevel=prefetchLevel,writeLevel=writeLevel))::rest)
        equation
          if(boolOr(intLt(numBytesFree, iVarSize), List.exist1(prefetchLevel,intEq, iLevelIdx))) then //The CL has not enough space or is used for prefetching -- can not be used for writing
            tmpMatchedCacheLine = findMatchingSharedCLLevelfix0(iNodeVar, iVarSize, iLevelIdx, iThreadIdx, iCurrentListIdx+1, rest);
          else
            if(List.exist(writeLevel, function isCLWrittenByOtherThread(iLevelIdx=iLevelIdx, iThreadIdx=iThreadIdx))) then //The CL is written by another thread in the same level -- can not be used for writing
              tmpMatchedCacheLine = findMatchingSharedCLLevelfix0(iNodeVar, iVarSize, iLevelIdx, iThreadIdx, iCurrentListIdx+1, rest);
            else
              if(List.exist(writeLevel, function isCLWrittenByOtherThread(iLevelIdx=iLevelIdx-1, iThreadIdx=iThreadIdx))) then //The CL is written by another thread in the previous level -- can not be used for writing
                tmpMatchedCacheLine = findMatchingSharedCLLevelfix0(iNodeVar, iVarSize, iLevelIdx, iThreadIdx, iCurrentListIdx+1, rest);
              else //CL matches
                tmpMatchedCacheLine = SOME((head, iCurrentListIdx));
              end if;
            end if;
          end if;
        then tmpMatchedCacheLine;
      case(_,_,_,_,_,{})
        then NONE();
      else
        equation
          print("findMatchingSharedCLLevelfix0: Unknown partly filled cache line type given.\n");
        then NONE();
    end match;
  end findMatchingSharedCLLevelfix0;

  protected function findMatchingSharedCLThread "author: marcusw
    Iterate over the given shared cache line list and return the first entry that can be used to store the shared variable iNodeVar."
    input Integer iNodeVar;
    input Integer iVarSize; //number of required bytes
    input Integer iVarType;
    input Integer iThreadIdx;
    input Integer iAdditionalArgument; //unused
    input array<tuple<PartlyFilledCacheLines, CacheLines>> iSharedCacheLines;
    output Option<tuple<PartlyFilledCacheLine,Integer>> oMatchedCacheLine; //<CL, listIndex>
  protected
    list<PartlyFilledCacheLine> partlyFilledCacheLines;
    PartlyFilledCacheLine partlyFilledCL;
    Integer numBytesFree, listIdx;
  algorithm
    oMatchedCacheLine := NONE();
    partlyFilledCacheLines := getPartlyFilledCLByVarType(iVarType, Util.tuple21(arrayGet(iSharedCacheLines, iThreadIdx)));
    listIdx := 1;
    for partlyFilledCL in partlyFilledCacheLines loop
      CACHELINEMAP(numBytesFree=numBytesFree) := getCacheLineMapOfPartlyFilledCacheLine(partlyFilledCL);
      if(intGe(numBytesFree, iVarSize)) then
        oMatchedCacheLine := (SOME((partlyFilledCL, listIdx)));
        break;
      end if;
      listIdx := listIdx + 1;
    end for;
  end findMatchingSharedCLThread;

  protected function createSharedClThread
    input Option<PartlyFilledCacheLine> iOldPartlyFilledCacheLine;
    input CacheLineMap iCacheLineMap;
    input Integer iAdditionalArgument; //unused
    output PartlyFilledCacheLine oCreatedCacheLine;
  algorithm
    oCreatedCacheLine := PARTLYFILLEDCACHELINE_THREAD(iCacheLineMap);
  end createSharedClThread;

  protected function createSharedClLevelFix
    input Option<PartlyFilledCacheLine> iOldPartlyFilledCacheLine;
    input CacheLineMap iCacheLineMap;
    input tuple<Integer,Integer> iLevelThreadIdx;
    output PartlyFilledCacheLine oCreatedCacheLine;
  protected
    list<Integer> prefetchLevel;
    list<tuple<Integer, Integer>> writeLevel;
    Integer levelIdx, threadIdx;
  algorithm
    (levelIdx, threadIdx) := iLevelThreadIdx;
    if(isSome(iOldPartlyFilledCacheLine)) then
      SOME(PARTLYFILLEDCACHELINE_LEVEL(prefetchLevel=prefetchLevel,writeLevel=writeLevel)) := iOldPartlyFilledCacheLine;
    else
      prefetchLevel := {};
      writeLevel := {};
    end if;

    if(intGt(levelIdx - 1, 0)) then
      prefetchLevel := (levelIdx-1)::prefetchLevel;
    end if;
    writeLevel := (levelIdx, threadIdx)::writeLevel;

    oCreatedCacheLine := PARTLYFILLEDCACHELINE_LEVEL(iCacheLineMap,prefetchLevel,writeLevel);
  end createSharedClLevelFix;

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

  protected function createCacheMapFromThreadAndSharedCLs "author: marcusw
    Create a cachemap-object out of the given thread and shared cache lines by appending them to the cache lines of the iCacheMap-object."
    input CacheLines iThreadCacheLines;
    input tuple<PartlyFilledCacheLines, CacheLines> iSharedCacheLines;
    input CacheMap iCacheMap;
    output CacheMap oCacheMap;
  protected
    Integer cacheLineSize;
    list<CacheLineMap> cacheLinesFloat, cacheLinesInt, cacheLinesBool, threadCacheLinesFloat, threadCacheLinesInt, threadCacheLinesBool;
    CacheLines fullyFilledSharedCacheLines;
    PartlyFilledCacheLines partlyFilledCacheLines;
    list<SimCodeVar.SimVar> cacheVariables;
  algorithm
    CACHEMAP(cacheLineSize, cacheVariables, cacheLinesFloat, cacheLinesInt, cacheLinesBool) := iCacheMap;

    ((partlyFilledCacheLines,fullyFilledSharedCacheLines)) := iSharedCacheLines;
    cacheLinesFloat := listAppend(cacheLinesFloat, listAppend(Util.tuple31(iThreadCacheLines), Util.tuple31(fullyFilledSharedCacheLines)));
    //print("HpcOmMemory.createCacheMapFromThreadAndSharedCLs: Thread float cache lines\n");
    //List.map_0(cacheLinesFloat, function printCacheLineMap(iCacheVariables = cacheVariables));
    //print("\n");
    cacheLinesInt := listAppend(cacheLinesInt, listAppend(Util.tuple32(iThreadCacheLines), Util.tuple32(fullyFilledSharedCacheLines)));
    //print("HpcOmMemory.createCacheMapFromThreadAndSharedCLs: Thread int cache lines\n");
    //List.map_0(cacheLinesInt, function printCacheLineMap(iCacheVariables = cacheVariables));
    //print("\n");
    cacheLinesBool := listAppend(cacheLinesBool, listAppend(Util.tuple33(iThreadCacheLines), Util.tuple33(fullyFilledSharedCacheLines)));
    //print("HpcOmMemory.createCacheMapFromThreadAndSharedCLs: Thread bool cache lines\n");
    //List.map_0(cacheLinesBool, function printCacheLineMap(iCacheVariables = cacheVariables));
    //print("\n");

    cacheLinesFloat := listAppend(cacheLinesFloat, List.map(Util.tuple31(partlyFilledCacheLines), getCacheLineMapOfPartlyFilledCacheLine));
    //print("HpcOmMemory.createCacheMapFromThreadAndSharedCLs: Partly float cache lines\n");
    //List.map_0(List.map(Util.tuple31(partlyFilledCacheLines), getCacheLineMapOfPartlyFilledCacheLine), function printCacheLineMap(iCacheVariables = cacheVariables));
    //print("\n");
    cacheLinesInt := listAppend(cacheLinesInt, List.map(Util.tuple32(partlyFilledCacheLines), getCacheLineMapOfPartlyFilledCacheLine));
    cacheLinesBool := listAppend(cacheLinesBool, List.map(Util.tuple33(partlyFilledCacheLines), getCacheLineMapOfPartlyFilledCacheLine));

    oCacheMap := CACHEMAP(cacheLineSize, cacheVariables, cacheLinesFloat, cacheLinesInt, cacheLinesBool);
  end createCacheMapFromThreadAndSharedCLs;

  protected function createCacheMapDefault "author: marcusw
    Create a default cacheMap without optimization."
    input array<Option<SimCodeVar.SimVar>> iAllSCVars;
    input Integer iCacheLineSize;
    input SimCodeVar.SimVars iSimCodeVars;
    input array<Integer> iScVarTaskMapping;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input array<tuple<Integer,Integer,Integer>> iSimCodeVarTypes; //<varDataType, varSize, varType>
    output CacheMap oCacheMap;
    output array<tuple<Integer,Integer>> oScVarCLMapping; //mapping for each scVar -> CLIdx
    output Integer oNumCL;
  protected
    list<SimCodeVar.SimVar> iAllFloatVars;
    list<CacheLineMap> cacheLineFloatMaps;
    array<tuple<Integer,Integer>> tmpScVarCLMapping;
  algorithm
    if((stringEqual(Config.simCodeTarget(), "Cpp") or stringEqual(Config.simCodeTarget(), "omsicpp"))) then
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
    input array<tuple<Integer,Integer,Integer>> iSimCodeVarTypes; //<varDataType, varSize, varType>
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
          allVars = List.append_reverse(algVars, allVars);
          //print("algVars finished\n");

          (filledCacheLines, lastCacheLine, currentScVarIdx) = createCacheMapDefaultCppRuntime0(discreteAlgVars, currentScVarIdx, discreteAlgVarsStart, scVarCLMapping, filledCacheLines, iScVarTaskMapping, iSchedulerInfo, lastCacheLine, iCacheLineSize, iSimCodeVarTypes);
          allVars = List.append_reverse(discreteAlgVars, allVars);
          //print("discreteAlgVars finished\n");

          //print("\n\nParamVarsStart: " + intString(paramVarsStart) + "\n");
          (filledCacheLines, lastCacheLine, currentScVarIdx) = createCacheMapDefaultCppRuntime0(paramVars, currentScVarIdx, paramVarsStart, scVarCLMapping, filledCacheLines, iScVarTaskMapping, iSchedulerInfo, lastCacheLine, iCacheLineSize, iSimCodeVarTypes);
          allVars = List.append_reverse(paramVars, allVars);
          //print("paramVars finished\n");

          (filledCacheLines, lastCacheLine, currentScVarIdx) = createCacheMapDefaultCppRuntime0(aliasVars, currentScVarIdx, aliasVarsStart, scVarCLMapping, filledCacheLines, iScVarTaskMapping, iSchedulerInfo, lastCacheLine, iCacheLineSize, iSimCodeVarTypes);
          allVars = List.append_reverse(aliasVars, allVars);

          //print("\n\nIntAlgVarsStart: " + intString(intAlgVarsStart) + "\n");
          (filledCacheLines, lastCacheLine, currentScVarIdx) = createCacheMapDefaultCppRuntime0(intAlgVars, currentScVarIdx, intAlgVarsStart, scVarCLMapping, filledCacheLines, iScVarTaskMapping, iSchedulerInfo, lastCacheLine, iCacheLineSize, iSimCodeVarTypes);
          allVars = List.append_reverse(intAlgVars, allVars);
          //print("intAlgVars finished\n");

          //print("\n\nIntParamVarsStart: " + intString(intParamVarsStart) + "\n");
          (filledCacheLines, lastCacheLine, currentScVarIdx) = createCacheMapDefaultCppRuntime0(intParamVars, currentScVarIdx, intAlgVarsStart, scVarCLMapping, filledCacheLines, iScVarTaskMapping, iSchedulerInfo, lastCacheLine, iCacheLineSize, iSimCodeVarTypes);
          allVars = List.append_reverse(intParamVars, allVars);
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
    input array<tuple<Integer,Integer,Integer>> iSimCodeVarTypes;
    output list<CacheLineMap> oFilledCacheLines;
    output CacheLineMap oLastCacheLine;
    output Integer oScVarIdx;
  protected
    Integer currentScVarIdx, varSize, varDataType, varTask, threadIdx, varCLIdx;
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
        ((varDataType, varSize, _)) := arrayGet(iSimCodeVarTypes, currentScVarIdx + iRealScVarIdxStart);

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
        entry := CACHELINEENTRY(-1, varDataType, varSize, currentScVarIdx + iScVarIdxStart, threadIdx);

        (entry, lastCacheLineNew, newCacheLineCreated) := createCacheMapDefaultCppRuntime1(entry, iCacheLineSize, lastCacheLine);
        CACHELINEMAP(idx=varCLIdx, entries=cachelineEntries) := lastCacheLineNew;
        //print("Number of elements in cacheline: " + intString(listLength(cachelineEntries)) + "\n");
        _ := arrayUpdate(iScVarCLMapping, currentScVarIdx + iRealScVarIdxStart, (varCLIdx, varDataType));

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
    array<tuple<Integer,Integer,Integer>> iSimCodeVarTypes; //<type, numberOfBytesRequired>
    array<tuple<Integer,Integer>> iScVarCLMapping; //will be updated: mapping scVar (arrayIdx) -> <clIdx,varType>
    Integer currentCLCandidateIdx, currentCLCandidateCLIdx, clIdx, currentCLCandidateFreeBytes, cacheLineSize, numNewCL, varDataType, numBytesRequired, entryStart;
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
          ((varDataType,numBytesRequired,_)) = arrayGet(iSimCodeVarTypes,iSCVarIdx);
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
          CLentries = CACHELINEENTRY(entryStart,varDataType, numBytesRequired, numCacheVars, iOwnerThread)::CLentries;
          cacheLine = CACHELINEMAP(clIdx,numBytesFree+numBytesRequired,CLentries);
          cacheLinesFloat = List.set(cacheLinesFloat, listLength(cacheLinesFloat) - currentCLCandidateCLIdx + 1, cacheLine);
          //update scVarCL-Mapping
          iScVarCLMapping = arrayUpdate(iScVarCLMapping,iSCVarIdx,(clIdx,varDataType));
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
          ((varDataType,numBytesRequired,_)) = arrayGet(iSimCodeVarTypes,iSCVarIdx);
          tmpInfo = appendSCVarToCacheMap(iSCVarIdx, iOwnerThread, (cacheMap, cacheMapMeta, numNewCL,cacheLineCandidates,writtenCL,currentCLCandidateIdx+1));
        then tmpInfo;
      case(_,_,(cacheMap as CACHEMAP(cacheLineSize=cacheLineSize,cacheVariables=cacheVariables,cacheLinesFloat=cacheLinesFloat, cacheLinesInt=cacheLinesInt, cacheLinesBool=cacheLinesBool), CACHEMAPMETA(iAllSCVarsMapping, iSimCodeVarTypes, iScVarCLMapping), numNewCL, cacheLineCandidates, writtenCL, currentCLCandidateIdx))
        equation //case 3: no CL-candidates available
          //print("--appendSCVarToCacheMap: Handling variable " + intString(iSCVarIdx) + "\n");

          ((varDataType,numBytesRequired,_)) = arrayGet(iSimCodeVarTypes,iSCVarIdx);
          entryStart = 0;
          numCacheVars = listLength(cacheVariables)+1;
          CLentries = {CACHELINEENTRY(entryStart,varDataType, numBytesRequired, numCacheVars, iOwnerThread)};
          clIdx = listLength(cacheLinesFloat) + 1;
          cacheLine = CACHELINEMAP(clIdx,numBytesRequired,CLentries);
          cacheLinesFloat = cacheLine::cacheLinesFloat;
          //update scVarCL-Mapping
          iScVarCLMapping = arrayUpdate(iScVarCLMapping,iSCVarIdx,(clIdx,varDataType));
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

  protected function convertCacheToVarArrayMapping "author: marcusw
    Convert the informations of the given cache-map to variable-array mapping used for the code generation."
    input CacheMap iCacheMap;
    input Integer iCacheLineSize;
    input list<SimCodeVar.SimVar> iStateVars;
    input list<SimCodeVar.SimVar> iDerivativeVars;
    input list<SimCodeVar.SimVar> iAliasVars;
    input list<SimCodeVar.SimVar> iIntAliasVars;
    input list<SimCodeVar.SimVar> iBoolAliasVars;
    input list<SimCodeVar.SimVar> iStringAliasVars;
    input tuple<Integer,Integer,Integer> iVarSizes; //size of float, int and bool variables (in bytes)
    input tuple<list<SimCodeVar.SimVar>, list<SimCodeVar.SimVar>, list<SimCodeVar.SimVar>, list<SimCodeVar.SimVar>> iNotOptimizedVars;
    output HashTableCrIListArray.HashTable oVarToArrayIndexMapping;
    output HashTableCrILst.HashTable oVarToIndexMapping;
    output Option<HpcOmSimCode.MemoryMap> oMemoryMap;
  protected
    Integer cacheLineSize, highestIdx, maxNumElemsFloat, maxNumElemsInt, maxNumElemsBool, stateAndStateDerSize;
    list<SimCodeVar.SimVar> cacheVariables, unusedRealVars;
    array<SimCodeVar.SimVar> cacheVariablesArray;
    list<CacheLineMap> cacheLinesFloat, cacheLinesInt, cacheLinesBool, allCacheLines;
    HashTableCrIListArray.HashTable varArrayIndexMappingHashTable;
    HashTableCrILst.HashTable varIndexMappingHashTable; //maps each variable to a memory "slot"
    array<tuple<Integer,Integer>> positionMappingArray;
    Integer varSizeFloat, varSizeInt, varSizeBool, varSizeString;
    list<tuple<Integer, Integer, Integer>> positionMappingList; //<scVarIdx, arrayPosition, arrayIdx>
    array<Integer> varIdxOffsets;
    list<SimCodeVar.SimVar> notOptimizedVarsFloat, notOptimizedVarsInt, notOptimizedVarsBool, notOptimizedVarsString;
    array<Integer> currentVarIndices;
  algorithm
    (oVarToArrayIndexMapping,oVarToIndexMapping,oMemoryMap) := match(iCacheMap, iCacheLineSize, iStateVars, iDerivativeVars, iAliasVars, iIntAliasVars, iBoolAliasVars, iStringAliasVars, iVarSizes, iNotOptimizedVars)
      case(CACHEMAP(cacheLineSize=cacheLineSize, cacheVariables=cacheVariables, cacheLinesFloat=cacheLinesFloat, cacheLinesInt=cacheLinesInt, cacheLinesBool=cacheLinesBool),_,_,_,_,_,_,_,(varSizeFloat, varSizeInt, varSizeBool),(notOptimizedVarsFloat,notOptimizedVarsInt,notOptimizedVarsBool,notOptimizedVarsString))
        equation
          maxNumElemsFloat = intDiv(iCacheLineSize, varSizeFloat);
          maxNumElemsInt = intDiv(iCacheLineSize, varSizeInt);
          maxNumElemsBool = intDiv(iCacheLineSize, varSizeBool);

          cacheVariablesArray = listArray(cacheVariables);
          varArrayIndexMappingHashTable = HashTableCrIListArray.emptyHashTable();
          varIndexMappingHashTable = HashTableCrILst.emptyHashTable();

          currentVarIndices = arrayCreate(4,1);
          //The first array elements are reserved for state and state derivative variables
          ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(iStateVars, function SimCodeUtil.addVarToArrayIndexMapping(iVarType=VARDATATYPE_FLOAT), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
          ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(iDerivativeVars, function SimCodeUtil.addVarToArrayIndexMapping(iVarType=VARDATATYPE_FLOAT), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));

          stateAndStateDerSize = intAdd(listLength(iStateVars), listLength(iDerivativeVars));
          if(intEq(intMod(stateAndStateDerSize, maxNumElemsFloat), 0)) then
            arrayUpdate(currentVarIndices,1,(stateAndStateDerSize + 1));
            arrayUpdate(currentVarIndices,2,1);
            arrayUpdate(currentVarIndices,3,1);
            arrayUpdate(currentVarIndices,4,1);
          else
            arrayUpdate(currentVarIndices,1,stateAndStateDerSize + (maxNumElemsFloat - intMod(stateAndStateDerSize, maxNumElemsFloat)) + 1);
            arrayUpdate(currentVarIndices,2,1);
            arrayUpdate(currentVarIndices,3,1);
            arrayUpdate(currentVarIndices,4,1);
          end if;

          //print("convertCacheToVarArrayMapping: The first " + intString(arrayGet(currentVarIndices,1)) + " elements are reserved for states and state derivatives\n");
          varSizeFloat = arrayGet(currentVarIndices,1);

          varIdxOffsets = arrayCreate(3,1);
          varIdxOffsets = arrayUpdate(varIdxOffsets, 1, arrayGet(currentVarIndices,1) + 1);
          allCacheLines = List.sort(getAllCacheLinesOfCacheMap(iCacheMap), compareCacheLineMapByIdx);
          ((varArrayIndexMappingHashTable,varIndexMappingHashTable)) = List.fold(allCacheLines, function addCacheLineMapToVarArrayMapping(iCacheLineSize=cacheLineSize, iVarIdxOffsets=varIdxOffsets, iCacheVariables=cacheVariablesArray), (varArrayIndexMappingHashTable,varIndexMappingHashTable));

          arrayUpdate(currentVarIndices, 1, arrayGet(currentVarIndices,1) + intMul(listLength(cacheLinesFloat), maxNumElemsFloat));
          arrayUpdate(currentVarIndices, 2, intMul(listLength(cacheLinesInt), maxNumElemsInt) + 1);
          arrayUpdate(currentVarIndices, 3, intMul(listLength(cacheLinesBool), maxNumElemsBool) + 1);
          arrayUpdate(currentVarIndices, 4, 1);

          ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(listReverse(notOptimizedVarsFloat), function SimCodeUtil.addVarToArrayIndexMapping(iVarType=VARDATATYPE_FLOAT), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
          ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(listReverse(notOptimizedVarsInt), function SimCodeUtil.addVarToArrayIndexMapping(iVarType=VARDATATYPE_INTEGER), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
          ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(listReverse(notOptimizedVarsBool), function SimCodeUtil.addVarToArrayIndexMapping(iVarType=VARDATATYPE_BOOLEAN), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
          ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(listReverse(notOptimizedVarsString), function SimCodeUtil.addVarToArrayIndexMapping(iVarType=VARDATATYPE_STRING), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));

          //BaseHashTable.dumpHashTable(varArrayIndexMappingHashTable);
          ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(iAliasVars, function SimCodeUtil.addVarToArrayIndexMapping(iVarType=VARDATATYPE_FLOAT), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
          ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(iIntAliasVars, function SimCodeUtil.addVarToArrayIndexMapping(iVarType=VARDATATYPE_INTEGER), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
          ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(iBoolAliasVars, function SimCodeUtil.addVarToArrayIndexMapping(iVarType=VARDATATYPE_BOOLEAN), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
          ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(iStringAliasVars, function SimCodeUtil.addVarToArrayIndexMapping(iVarType=VARDATATYPE_STRING), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));

          varSizeFloat = varSizeFloat + intMul(listLength(cacheLinesFloat), maxNumElemsFloat) + listLength(notOptimizedVarsFloat);
          //SimCodeUtil.dumpVarLst(notOptimizedVarsFloat, "convertCacheToVarArrayMapping: Not optimized float vars");
          //print("\n");
          //SimCodeUtil.dumpVarLst(notOptimizedVarsInt, "convertCacheToVarArrayMapping: Not optimized int vars");
          //print("\n");
          //SimCodeUtil.dumpVarLst(notOptimizedVarsBool, "convertCacheToVarArrayMapping: Not optimized bool vars");
          //print("\n");
          //print("convertCacheToVarArrayMapping: " + intString(intMul(listLength(cacheLinesFloat), maxNumElemsFloat)) + " elements are reserved optimized variables. " + intString(varSizeFloat) + " variables at all.\n");
          varSizeInt = intMul(listLength(cacheLinesInt), maxNumElemsInt) + listLength(notOptimizedVarsInt);
          //print("convertCacheToVarArrayMapping: " + intString(intMul(listLength(cacheLinesBool), maxNumElemsBool)) + " elements are reserved for optimized variables [bool]\n");
          varSizeBool = intMul(listLength(cacheLinesBool), maxNumElemsBool) + listLength(notOptimizedVarsBool);
          varSizeString = listLength(notOptimizedVarsString);

        then (varArrayIndexMappingHashTable, varIndexMappingHashTable, SOME(HpcOmSimCode.MEMORYMAP_ARRAY(varSizeFloat,varSizeInt,varSizeBool,varSizeString)));
      case(UNIFORM_CACHEMAP(),_,_,_,_,_,_,_,_,_)
        equation
          Error.addMessage(Error.INTERNAL_ERROR, {"ConvertCacheToVarArrayMapping: Uniform-CacheMap not supported!"});
        then fail();
      else
        equation
          Error.addMessage(Error.INTERNAL_ERROR, {"ConvertCacheToVarArrayMapping: CacheMap-Type not supported!"});
        then fail();
     end match;
  end convertCacheToVarArrayMapping;

  protected function addCacheLineMapToVarArrayMapping "author: marcusw
    Append the informations of the given cachline-map to the position-mapping-structure."
    input CacheLineMap iCacheLineMap;
    input Integer iCacheLineSize;
    input array<Integer> iVarIdxOffsets; //an offset that is substracted from the arrayPosition (for float, int and bool variables -> taken from iArrayIdx)
    input array<SimCodeVar.SimVar> iCacheVariables;
    input tuple<HashTableCrIListArray.HashTable, HashTableCrILst.HashTable> iPositionMapping; //<varArrayIndexMappingHashTable, varIndexMappingHashTable, currentVarIndices>
    output tuple<HashTableCrIListArray.HashTable, HashTableCrILst.HashTable> oPositionMapping; //<varArrayIndexMappingHashTable, varIndexMappingHashTable, currentVarIndices>
  protected
    HashTableCrIListArray.HashTable varArrayIndexMappingHashTable;
    HashTableCrILst.HashTable varIndexMappingHashTable;

    Integer idx, arrayIdx; //the arrayIdx is derived from the variable type of the first cacheline entry
    list<CacheLineEntry> entries;
    CacheLineEntry head;
    Integer dataType, size;
    list<tuple<Integer, Integer, Integer>> iPositionMappingList;
  algorithm
    oPositionMapping := match(iCacheLineMap, iCacheLineSize, iVarIdxOffsets, iCacheVariables, iPositionMapping)
       case(CACHELINEMAP(idx=idx,entries=entries),_,_,_,(varArrayIndexMappingHashTable, varIndexMappingHashTable))
        equation
          CACHELINEENTRY(dataType=dataType, size=size)::_ = entries;
          //print("addCacheLineMapToVarArrayMapping: Adding cache line '" + intString(idx) + "' with '" + intString(listLength(entries)) + "' entries\n");
          (varArrayIndexMappingHashTable, varIndexMappingHashTable) = List.fold(entries, function addCacheLineEntryToVarArrayMapping(iArrayIdx=dataType, iClIdxSize=(idx, iCacheLineSize), iVarIdxOffsets=iVarIdxOffsets, iCacheVariables=iCacheVariables), iPositionMapping);
          _ = arrayUpdate(iVarIdxOffsets, dataType, intAdd(arrayGet(iVarIdxOffsets, dataType), intDiv(iCacheLineSize, size)));
          //_ = convertCacheToVarArrayMapping2Helper(iVarIdxOffsets, 1, dataType);
        then ((varArrayIndexMappingHashTable, varIndexMappingHashTable));
       else
        equation
          Error.addMessage(Error.INTERNAL_ERROR, {"addCacheLineMapToVarArrayMapping failed! CacheLineMap-Type not supported!"});
        then fail();
     end match;
  end addCacheLineMapToVarArrayMapping;

  protected function addCacheLineEntryToVarArrayMapping "author: marcusw
    Append the informations of the given cachline-entry to the position-mapping-structure."
    input CacheLineEntry iCacheLineEntry;
    input Integer iArrayIdx;
    input tuple<Integer,Integer> iClIdxSize; //<CLIdx, CLSize>>
    input array<Integer> iVarIdxOffsets; //an offset that is substracted from the arrayPosition (for float, int and bool variables -> taken from iArrayIdx)
    input array<SimCodeVar.SimVar> iCacheVariables;
    input tuple<HashTableCrIListArray.HashTable, HashTableCrILst.HashTable> iPositionMapping; //<varArrayIndexMappingHashTable, varIndexMappingHashTable, currentVarIndices>
    output tuple<HashTableCrIListArray.HashTable, HashTableCrILst.HashTable> oPositionMapping; //<varArrayIndexMappingHashTable, varIndexMappingHashTable, currentVarIndices>
  protected
    HashTableCrIListArray.HashTable varArrayIndexMappingHashTable;
    HashTableCrILst.HashTable varIndexMappingHashTable;

    Integer clIdx, clSize;
    list<tuple<Integer, Integer, Integer>> iPositionMappingList;
    Integer scVarIdx, start, size, arrayPosition, highestIdx, offset, arridx;
    array<Integer> currentVarIndices;
  algorithm
    oPositionMapping := match(iCacheLineEntry, iArrayIdx, iClIdxSize, iVarIdxOffsets, iCacheVariables, iPositionMapping)
      case(CACHELINEENTRY(scVarIdx=scVarIdx, start=start, size=size),_,(clIdx, clSize),_,_,(varArrayIndexMappingHashTable, varIndexMappingHashTable))
        equation
          offset = arrayGet(iVarIdxOffsets, iArrayIdx);
          //arrayPosition = intDiv(start, size) + (clIdx - 1)*intDiv(clSize, size) + offset;
          arrayPosition = intDiv(start, size) + offset;
          //print("convertCacheMapToMemoryMap2: offset=" + intString(offset) + " array-index=" + intString(iArrayIdx) + " array-position=" + intString(arrayPosition) + "\n");
          currentVarIndices = arrayCreate(4,arrayPosition);
          //print("convertCacheMapToMemoryMap2: number of variables=" + intString(arrayLength(iCacheVariables)) + " arrayPosition=" + intString(arrayPosition) + "\n");
          (_, varArrayIndexMappingHashTable, varIndexMappingHashTable) = SimCodeUtil.addVarToArrayIndexMapping(arrayGet(iCacheVariables, arrayLength(iCacheVariables) - scVarIdx + 1), iArrayIdx, (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
          //iPositionMappingList = (realScVarIdx,arrayPosition,iArrayIdx)::iPositionMappingList;
          //for arridx in listRange(arrayLength(iVarIdxOffsets)) loop
          //  _ = arrayUpdate(iVarIdxOffset, intDiv(clSize, size));
          //end for;
          //print("convertCacheMapToMemoryMap2: " + ComponentReference.debugPrintComponentRefTypeStr(name) + " [" + intString(arrayPosition) + "] with array-pos: " + intString(arrayPosition) + " | array-index: " + intString(iArrayIdx) + " | start: " + intString(start) + "\n");
        then ((varArrayIndexMappingHashTable, varIndexMappingHashTable));
      else
        equation
          Error.addMessage(Error.INTERNAL_ERROR, {"addCacheLineEntryToVarArrayMapping failed! Unsupported entry-type\n"});
        then fail();
    end match;
  end addCacheLineEntryToVarArrayMapping;

  protected function convertCacheToVarArrayMapping2Helper "author: marcusw
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
    for i in 1:arrayLength(tmpArray) loop
      if(intNe(i, iIndex)) then
        tmpArray := arrayUpdate(tmpArray, i, arrayGet(tmpArray, i) + iOffset);
      end if;
    end for;
    oArray := tmpArray;
  end convertCacheToVarArrayMapping2Helper;

  protected function getNotOptimizedVarsByCacheLineMapping "author: marcusw
    Get all sim code variables that have no valid cl-mapping."
    input array<tuple<Integer,Integer>> iScVarCLMapping;
    input array<Option<SimCodeVar.SimVar>> iAllVarsMapping;
    input array<tuple<Integer,Integer, Integer>> iSimCodeVarTypes; //<varDataType, varSize, varType>
    output tuple<list<Integer>, list<Integer>, list<Integer>, list<Integer>> oNotOptimizedVars;
  algorithm
    ((oNotOptimizedVars,_)) := Array.fold(iScVarCLMapping, function getNotOptimizedVarsByCacheLineMapping0(iAllVarsMapping=iAllVarsMapping,iSimCodeVarTypes=iSimCodeVarTypes), (({},{},{},{}),1));
  end getNotOptimizedVarsByCacheLineMapping;

  protected function getNotOptimizedVarsByCacheLineMapping0 "author: marcusw
    Add the sc-variable to the output list if it has no valid mapping."
    input tuple<Integer,Integer> iScVarCLMapping;
    input array<Option<SimCodeVar.SimVar>> iAllVarsMapping;
    input array<tuple<Integer,Integer, Integer>> iSimCodeVarTypes; //<varDataType, varSize, varType>
    input tuple<tuple<list<Integer>, list<Integer>, list<Integer>, list<Integer>>, Integer> iEntries; //<input-list,scVarindex>
    output tuple<tuple<list<Integer>, list<Integer>, list<Integer>, list<Integer>>, Integer> oEntries; //<input-list,scVarindex>
  protected
    list<Integer> tmpSimVarsFloat, tmpSimVarsInt, tmpSimVarsBool, tmpSimVarsString;
    Integer scVarIdx, dataType;
  algorithm
    oEntries := matchcontinue(iScVarCLMapping, iAllVarsMapping, iSimCodeVarTypes, iEntries)
      case((-1,_),_,_,((tmpSimVarsFloat, tmpSimVarsInt, tmpSimVarsBool, tmpSimVarsString), scVarIdx))
        equation
          dataType = Util.tuple31(arrayGet(iSimCodeVarTypes, scVarIdx));
          if(intEq(dataType, VARDATATYPE_FLOAT)) then
            tmpSimVarsFloat = scVarIdx::tmpSimVarsFloat;
          else
            if(intEq(dataType, VARDATATYPE_INTEGER)) then
              tmpSimVarsInt = scVarIdx::tmpSimVarsInt;
            else
              if(intEq(dataType, VARDATATYPE_BOOLEAN)) then
                tmpSimVarsBool = scVarIdx::tmpSimVarsBool;
              else
                if(intEq(dataType, VARDATATYPE_STRING)) then
                  tmpSimVarsString = scVarIdx::tmpSimVarsString;
                end if;
              end if;
            end if;
          end if;
        then (((tmpSimVarsFloat, tmpSimVarsInt, tmpSimVarsBool, tmpSimVarsString), scVarIdx+1));
      case(_,_,_,((tmpSimVarsFloat, tmpSimVarsInt, tmpSimVarsBool, tmpSimVarsString), scVarIdx))
        then (((tmpSimVarsFloat, tmpSimVarsInt, tmpSimVarsBool, tmpSimVarsString), scVarIdx+1));
    end matchcontinue;
  end getNotOptimizedVarsByCacheLineMapping0;

  // -------------------------------------------
  // ANALYSIS
  // -------------------------------------------

  protected function evaluateCacheBehaviour
    input HashTableCrILst.HashTable iVarToIndexMappingHashTable; //maps each sim var to a memory slot
    input HashTableCrILst.HashTable iSimVarIdxMappingHashTable;  //maps each sim var to an ID
    input array<list<Integer>> taskSolvedVarsMapping;
    input array<list<Integer>> taskUnsolvedVarsMapping;
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraph iTaskGraphT;
    input Integer iNumberOfThreads;
    input Integer iCacheLineSize;
    input array<tuple<Integer,Integer, Integer>> iSimCodeVarTypes; //<varDataType, varSize, varType>
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
  protected
    array<Integer> varToCLMapping; //bool, int and float cache lines are starting with index 1 each
    array<Integer> varTypeCLOffset; //offset of cache lines (e.g. int-offset = number of float cache lines)
  algorithm
    //(varTypeCLOffset, varToCLMapping) := createVarCLMappingFromVarArrayIndexHashTable(iVarToIndexMappingHashTable, iSimVarIdxMappingHashTable, iSimCodeVarTypes);
    /*
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
    */
  end evaluateCacheBehaviour;

  protected function createVarCLMappingFromVarArrayIndexHashTable
    input HashTableCrILst.HashTable iVarToIndexMappingHashTable;
    input HashTableCrILst.HashTable iSimVarIdxMappingHashTable;
    input Integer iCacheLineSize;
    input array<tuple<Integer,Integer, Integer>> iSimCodeVarTypes; //<varDataType, varSize, varType>
    output array<Integer> oNumberOfVars; //number of variables stored in flaot, bool and int array
    output array<Integer> oVarToCLMapping;
  protected
    list<tuple<DAE.ComponentRef, list<Integer>>> hashTableElements;
    tuple<DAE.ComponentRef, list<Integer>> hashTableElement;
    array<Integer> varToCLMapping;
    array<Integer> numberOfVars, maxNumberOfVarsInCL;
    Integer pos, id;
    DAE.ComponentRef cref;
  algorithm

    varToCLMapping := arrayCreate(arrayLength(iSimCodeVarTypes), -1);
    numberOfVars := arrayCreate(3, 0);
    hashTableElements := BaseHashTable.hashTableList(iVarToIndexMappingHashTable);
    for hashTableElement in hashTableElements loop
      (cref, pos::_) := hashTableElement;
      //(id::_) := BaseHashTable.get(iSimVarIdxMappingHashTable, cref);
      //arrayUpdate(varToCLMapping, id, pos);
    end for;
    oNumberOfVars := numberOfVars;
    oVarToCLMapping := varToCLMapping;
  end createVarCLMappingFromVarArrayIndexHashTable;

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

  protected function transposeTasksScVarsMapping
    input array<list<Integer>> iTasksScVarMapping;
    input Integer iNumberOfScVars;
    output array<list<Integer>> oScVarTasksMapping;
  protected
    array<list<Integer>> tmpScVarTasksMapping;
    Integer scVarIdx, taskIdx;
    list<Integer> oldList, scVarIdc;
  algorithm
    tmpScVarTasksMapping := arrayCreate(iNumberOfScVars, {});
    for taskIdx in 1:arrayLength(iTasksScVarMapping) loop
      scVarIdc := arrayGet(iTasksScVarMapping, taskIdx);
      for scVarIdx in scVarIdc loop
        if(intGt(scVarIdx, 0)) then
          oldList := arrayGet(tmpScVarTasksMapping, scVarIdx);
          oldList := taskIdx::oldList;
          _ := arrayUpdate(tmpScVarTasksMapping, scVarIdx, oldList);
        end if;
      end for;
    end for;
    oScVarTasksMapping := tmpScVarTasksMapping;
  end transposeTasksScVarsMapping;

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
    list<Option<BackendDAE.Equation>> equOptList;
  algorithm
    BackendDAE.EQSYSTEM(orderedEqs=orderedEqs) := iEqSystem;
    equOptList := arrayList(ExpandableArray.getData(orderedEqs));
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
    //((_,(_,oMapping))) := Expression.traverseExpBottomUp(exp,createMemoryMapTraverse, (iHt,{}));
  end getEqSCVarMapping0;

  protected function createMemoryMapTraverse0 "author: marcusw
    Extend the variable list if the given expression is a cref."
    input DAE.Exp inExp;
    input tuple<HashTableCrILst.HashTable, list<Integer>> inTpl; // <hashTable, variableList, nextVarIsDerived>
    output DAE.Exp outExp;
    output tuple<HashTableCrILst.HashTable, list<Integer>> oTpl;
  protected
    list<Integer> iVarList, oVarList, varInfo;
    Integer varIdx, varHead;
    HashTableCrILst.HashTable iHashTable;
    DAE.Exp iExp;
    DAE.ComponentRef componentRef;
  algorithm
    (outExp,oTpl) := matchcontinue(inExp,inTpl)
      case (iExp as DAE.CALL(path = Absyn.IDENT("der"), expLst = {DAE.CREF(componentRef = componentRef)}), (iHashTable,iVarList))
        equation
          //print("HpcOmSimCode.createMemoryMapTraverse: found der-call\n");
          varInfo = BaseHashTable.get(componentRef, iHashTable);
          varIdx = listHead(varInfo) + List.second(varInfo);
          //Delete state variable first
          if(boolNot(listEmpty(iVarList))) then
            varHead = listHead(iVarList);
            if(intEq(varHead, varIdx)) then
              iVarList = List.rest(iVarList);
              //print("createMemoryMapTraverse0: Removed variable " + intString(varIdx) + "\n");
            end if;
          end if;
          //Add der state variable
          varInfo = BaseHashTable.get(ComponentReference.crefPrefixDer(componentRef), iHashTable);
          varIdx = listHead(varInfo) + List.second(varInfo);
          //print("createMemoryMapTraverse0: Added variable " + intString(varIdx) + "\n");
          oVarList = varIdx :: iVarList;
        then (iExp,(iHashTable,oVarList));
      case(iExp as DAE.CREF(componentRef=componentRef), (iHashTable,iVarList))
        equation
          //print("HpcOmSimCode.createMemoryMapTraverse: try to find componentRef '" + ComponentReference.crefStr(componentRef) + "\n");
          varInfo = BaseHashTable.get(componentRef, iHashTable);
          varIdx = listHead(varInfo) + List.second(varInfo);
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
          scVarIdx = listHead(scVarValues);
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

  protected function invertEqCompMapping "author: marcusw
    Convert a equation-component-mapping to a component-equation-mapping."
    input array<tuple<Integer,Integer,Integer>> iEqCompMapping; // maps each equation to <compIdx, eqSystemIdx, offset>
    input Integer iNumOfComps;
    output array<list<tuple<Integer,Integer,Integer>>> oCompEqMapping; //maps each scc to a list of <equationIdx, eqSystemIdx, offset>
  protected
    array<list<tuple<Integer,Integer,Integer>>> tmpCompEqMapping;
    Integer eqIdx, compIdx, eqSystemIdx, offset;
    tuple<Integer,Integer,Integer> eqCompEntry;
    list<tuple<Integer,Integer,Integer>> compEqEntry;
  algorithm
    tmpCompEqMapping := arrayCreate(iNumOfComps, {});
    for eqIdx in 1:arrayLength(iEqCompMapping) loop
      ((compIdx, eqSystemIdx, offset)) := arrayGet(iEqCompMapping, eqIdx);
      compEqEntry := arrayGet(tmpCompEqMapping, compIdx);
      tmpCompEqMapping := arrayUpdate(tmpCompEqMapping, compIdx, (eqIdx, eqSystemIdx, offset)::compEqEntry);
    end for;
    oCompEqMapping := tmpCompEqMapping;
  end invertEqCompMapping;

  protected function invertSccNodeMapping
    input array<Integer> iSccNodeMapping;
    input Integer iNumberOfNodes;
    output array<list<Integer>> oNodeSccMapping;
  protected
    array<list<Integer>> tmpNodeSccMapping;
    Integer sccIdx, nodeIdx;
    list<Integer> nodeSccEntry;
  algorithm
    tmpNodeSccMapping := arrayCreate(iNumberOfNodes, {});
    //print("invertSccNodeMapping: Creating scc node mapping with " + intString(iNumberOfNodes) + " nodes\n");
    for sccIdx in 1:arrayLength(iSccNodeMapping) loop
      nodeIdx := arrayGet(iSccNodeMapping, sccIdx);
      if intGt(nodeIdx, 0) then
        //print("invertSccNodeMapping: Adding node " + intString(nodeIdx) + " with scc " + intString(sccIdx) + " to mapping\n");
        nodeSccEntry := arrayGet(tmpNodeSccMapping, nodeIdx);
        tmpNodeSccMapping := arrayUpdate(tmpNodeSccMapping, nodeIdx, sccIdx::nodeSccEntry);
      end if;
    end for;
    oNodeSccMapping := tmpNodeSccMapping;
  end invertSccNodeMapping;

  protected function flattenEqSimCodeVarMapping
    input array<array<list<Integer>>> iEqSimCodeVarMapping; //eqSystem -> eqIdx -> varIdx
    output array<tuple<Integer,list<Integer>>> oFlatEqSimCodeVarMapping; //maps each equation to the eqSystem and a list of varIdc
  protected
    list<Integer> simCodeVarList;
    array<tuple<Integer,list<Integer>>> tmpFlatEqSimCodeVarMapping;
    Integer eqCount, eqIdx, eqSysIdx, eqSimCodeVarIdx;
    array<list<Integer>> eqSimCodeVarMappingEntry;
  algorithm
    //Calculate the number of equations first
    eqCount := 0;
    for eqSysIdx in 1:arrayLength(iEqSimCodeVarMapping) loop
      eqSimCodeVarMappingEntry := arrayGet(iEqSimCodeVarMapping, eqSysIdx);
      eqCount := eqCount + arrayLength(eqSimCodeVarMappingEntry);
    end for;

    eqIdx := 1;
    tmpFlatEqSimCodeVarMapping := arrayCreate(eqCount, (-1, {}));
    for eqSysIdx in 1:arrayLength(iEqSimCodeVarMapping) loop
      eqSimCodeVarMappingEntry := arrayGet(iEqSimCodeVarMapping, eqSysIdx);
      for eqSimCodeVarIdx in 1:arrayLength(eqSimCodeVarMappingEntry) loop
        simCodeVarList := arrayGet(eqSimCodeVarMappingEntry, eqSimCodeVarIdx);
        tmpFlatEqSimCodeVarMapping := arrayUpdate(tmpFlatEqSimCodeVarMapping, eqIdx, (eqSysIdx,simCodeVarList));
        eqIdx := eqIdx + 1;
      end for;
    end for;

    oFlatEqSimCodeVarMapping := tmpFlatEqSimCodeVarMapping;
  end flattenEqSimCodeVarMapping;

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
          tmpVarName = DAE.CREF_QUAL(DAE.derivativeNamePrefix,DAE.T_REAL({}),{},iVarName);
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
          scVarIdx = listHead(scVarValues);
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

  protected function getTaskSimVarMapping "author: marcusw
    Get a mapping for each task to all solved and all required variables."
    input array<list<tuple<Integer,Integer,Integer>>> iSccEqMapping; //maps each scc to a list of <equationIdx, eqSystemIdx, offset>
    input array<list<Integer>> iNodeSccMapping; //maps each node to a list of sccs that are solved in the node
    input array<tuple<Integer,list<Integer>>> iEqSimCodeVarMapping; //maps each equation to the eqSystem and a list of varIdc
    input array<Integer> iScVarTaskMapping; //maps each sc-var to the task that solves it
    input array<tuple<Integer,Integer, Integer>> iSimCodeVarTypes; //if the var-type is -1, than the variable is skipped
    output array<list<Integer>> oSolvedVars; //mapping for each task to a list of solved variables
    output array<list<Integer>> oNotSolvedVars; //mapping for each task to a list of required variables that are not solved
  protected
    array<list<Integer>> tmpSolvedVars, tmpNotSolvedVars;
    array<Integer> scVarMarks, scSolvedVarMarks; //mark the last task that read this variable to detect duplications
    list<Integer> nodeSccs, eqVars;
    Integer nodeIdx, sccIdx, eqIdx, var, varTask, varMark, varType, nvar, var;
    list<tuple<Integer,Integer,Integer>> sccEqs;
    tuple<Integer,Integer,Integer> sccEq;
  algorithm
    try
    tmpSolvedVars := arrayCreate(arrayLength(iNodeSccMapping), {});
    tmpNotSolvedVars := arrayCreate(arrayLength(iNodeSccMapping), {});
    scVarMarks := arrayCreate(arrayLength(iScVarTaskMapping), -1);
    scSolvedVarMarks := arrayCreate(arrayLength(iScVarTaskMapping), -1);
    nvar := arrayLength(iScVarTaskMapping);

    for nodeIdx in 1:arrayLength(iNodeSccMapping) loop
      nodeSccs := arrayGet(iNodeSccMapping, nodeIdx);
      //print("getTaskSimVarMapping: Node '" + intString(nodeIdx) + "' has sccs {" + stringDelimitList(List.map(nodeSccs, intString), ",") + "}\n");
      for sccIdx in nodeSccs loop
        sccEqs := arrayGet(iSccEqMapping, sccIdx);
        //print(" - Scc '" + intString(sccIdx) + "' has equations {" + stringDelimitList(List.map(List.map(sccEqs, Util.tuple31), intString), ",") + "}\n");
        for sccEq in sccEqs loop
          (eqIdx,_,_) := sccEq;
          ((_,eqVars)) := arrayGet(iEqSimCodeVarMapping, eqIdx);
          //print("   - Equation '" + intString(eqIdx) + "' has variables {" + stringDelimitList(List.map(eqVars, intString), ",") + "}\n");
          for v2 in eqVars loop
            var := if v2>nvar then v2-nvar /* states */ else v2;
            varTask := arrayGet(iScVarTaskMapping, var);
            //print("     - Variable  '" + intString(var) + "' is solved by task " + intString(varTask) + "\n");
            varType := Util.tuple31(arrayGet(iSimCodeVarTypes, var));
            if(intGt(varType, 0)) then
              if(intEq(nodeIdx, varTask)) then
                //variable is solved by the task
                varMark := arrayGet(scSolvedVarMarks, var);
                if(intNe(varMark, nodeIdx)) then
                  tmpSolvedVars := arrayUpdate(tmpSolvedVars, nodeIdx, var::arrayGet(tmpSolvedVars, nodeIdx));
                  scSolvedVarMarks := arrayUpdate(scSolvedVarMarks, var, nodeIdx);
                end if;
              else
                varMark := arrayGet(scVarMarks, var);
                //print("       - Variable  '" + intString(var) + "' has mark " + intString(varMark) + "\n");
                if(intNe(varMark, nodeIdx)) then
                  //variable is read by the task and was not already handled
                  tmpNotSolvedVars := arrayUpdate(tmpNotSolvedVars, nodeIdx, var::arrayGet(tmpNotSolvedVars, nodeIdx));
                  scVarMarks := arrayUpdate(scVarMarks, var, nodeIdx);
                end if;
              end if;
            else
              //print("     - Variable  '" + intString(var) + "' skipped because of negative type\n");
            end if;
          end for;
        end for;
      end for;
    end for;

    oSolvedVars := tmpSolvedVars;
    oNotSolvedVars := tmpNotSolvedVars;
    else
      Error.addInternalError(getInstanceName() + " failed", sourceInfo());
      fail();
    end try;
  end getTaskSimVarMapping;


  // -------------------------------------------
  // GRAPH
  // -------------------------------------------

  protected function appendCacheLinesToGraph "author: marcusw
    This method will extend the given graph-info with a new subgraph containing all cache lines.
    Dependencies between the tasks and the cache lines will be inserted as edges."
    input CacheMap iCacheMap;
    input Integer iNumberOfNodes; //number of nodes in the task graph
    input array<array<list<Integer>>> iEqSimCodeVarMapping;
    input BackendDAE.EqSystems iEqSystems; //the eqSystem of the incidence matrix
    input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
    input array<tuple<Integer,Integer,Integer>> ieqCompMapping; //a mapping from eqIdx (arrayIdx) to the scc idx
    input array<Integer> iScVarTaskMapping; //maps each scVar (arrayIdx) to the task that solves it
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input Integer iThreadIdAttributeIdx; //index for attribute "threadId"
    input array<Integer> iCompNodeMapping;
    input array<list<Integer>> iTaskSolvedVarsMapping;
    input array<list<Integer>> iTaskUnsolvedVarsMapping;
    input array<tuple<Integer,Integer>> iScVarCLMapping;
    input array<ScVarInfo> iScVarInfos;
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
    oGraphInfo := matchcontinue(iCacheMap,iNumberOfNodes,iEqSimCodeVarMapping,iEqSystems,iVarNameSCVarIdxMapping,ieqCompMapping,iScVarTaskMapping,iSchedulerInfo,iThreadIdAttributeIdx,iCompNodeMapping,iTaskSolvedVarsMapping,iTaskUnsolvedVarsMapping,iScVarCLMapping,iScVarInfos,iGraphInfo)
      case(_,_,_,_,_,_,_,_,_,_,_,_,_,_,GraphML.GRAPHINFO(graphCount=graphCount))
        equation
          true = intLe(1, graphCount);
          knownEdges = arrayCreate(iNumberOfNodes,{});
          addedVariables = arrayCreate(arrayLength(iScVarTaskMapping), false);
          (tmpGraphInfo,(_,_),(_,clGroupNodeIdx)) = GraphML.addGroupNode("CL_GoupNode", 1, false, "CL", iGraphInfo);
          cacheLines = getAllCacheLinesOfCacheMap(iCacheMap);
          cacheVariables = listArray(getCacheVariablesOfCacheMap(iCacheMap));
          tmpGraphInfo = List.fold(cacheLines, function appendCacheLineMapToGraph(iCacheVariables=cacheVariables, iAddedVariables=addedVariables, iSchedulerInfo=iSchedulerInfo, iTopGraphAttThreadIdIdx=(clGroupNodeIdx,iThreadIdAttributeIdx), iScVarTaskMapping=iScVarTaskMapping, iVarNameSCVarIdxMapping=iVarNameSCVarIdxMapping, iScVarInfos=iScVarInfos), tmpGraphInfo);
          //tmpGraphInfo = appendUnmappedVariablesToGraph(iScVarCLMapping, tmpGraphInfo);
          tmpGraphInfo = appendTaskVarEdgesToGraph(iTaskSolvedVarsMapping, iTaskUnsolvedVarsMapping, tmpGraphInfo);
        then tmpGraphInfo;
      case(_,_,_,_,_,_,_,_,_,_,_,_,_,_,GraphML.GRAPHINFO(graphCount=graphCount))
        equation
          true = intEq(graphCount,0);
        then iGraphInfo;
      else
        equation
          print("HpcOmSimCode.appendCacheLinesToGraph failed!\n");
        then fail();
     end matchcontinue;
  end appendCacheLinesToGraph;

  protected function appendVariablesToGraph "author: marcusw
    Add all variables to the task graph as nodes with a round shape."
    input array<list<Integer>> iTaskSolvedVarsMapping;
    input array<list<Integer>> iTaskUnsolvedVarsMapping;
    input Integer iNumberOfScVars;
    input Integer iGraphIdx;
    input Integer iThreadIdAttributeIdx; //index for attribute "threadId"
    input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
    input array<Option<SimCodeVar.SimVar>> iAllVarsMapping;
    input array<ScVarInfo> iScVarInfos;
    input GraphML.GraphInfo iGraphInfo;
    output GraphML.GraphInfo oGraphInfo;
  protected
    GraphML.GraphInfo tmpGraphInfo = iGraphInfo;
    String description, threadText;
    Option<SimCodeVar.SimVar> simVarOpt;
    SimCodeVar.SimVar simVar;
    DAE.ComponentRef varCompRef;
    GraphML.NodeLabel nodeLabel;
    Boolean isValidVar;
    list<Integer> realScVarIdxOffset;
    Integer realScVarIdx, realScVarOffset, threadOwner;
  algorithm
    //add all variables as a node first
    for varIdx in 1:iNumberOfScVars loop
      isValidVar := true;
      //print("Handling variable " + intString(varIdx) + " out of var-mapping with size " + intString(arrayLength(iAllVarsMapping)) + "\n");
      simVarOpt := arrayGet(iAllVarsMapping, varIdx);
      description := "unknown";
      threadText := "Th -1";
      if(isSome(simVarOpt)) then
        simVar := Util.getOption(simVarOpt);
        varCompRef := SimCodeFunctionUtil.varName(simVar);
        description :=  ComponentReference.printComponentRefStr(varCompRef);
        isValidVar := BaseHashTable.hasKey(varCompRef, iVarNameSCVarIdxMapping);

        if(BaseHashTable.hasKey(varCompRef, iVarNameSCVarIdxMapping)) then
          realScVarIdxOffset := BaseHashTable.get(varCompRef, iVarNameSCVarIdxMapping);
          realScVarIdx := listGet(realScVarIdxOffset,1);
          realScVarOffset := listGet(realScVarIdxOffset,2);
          realScVarIdx := realScVarIdx + realScVarOffset;
          SCVARINFO(ownerThread=threadOwner) := arrayGet(iScVarInfos, realScVarIdx);
          threadText := "Th " + intString(threadOwner);
        end if;
      end if;
      //print("appendVariablesToGraph: Appending variable " + description + " to graph with index " + intString(iGraphIdx) + "\n");
      if(isValidVar) then
        nodeLabel := GraphML.NODELABEL_INTERNAL(intString(varIdx), NONE(), GraphML.FONTPLAIN());
        tmpGraphInfo := GraphML.addNode("var" + intString(varIdx), GraphML.COLOR_GREEN2,GraphML.BORDERWIDTH_STANDARD, {nodeLabel}, GraphML.ELLIPSE(), SOME(description), {(iThreadIdAttributeIdx,threadText)}, iGraphIdx, tmpGraphInfo);
      end if;
    end for;
    tmpGraphInfo := appendTaskVarEdgesToGraph(iTaskSolvedVarsMapping, iTaskUnsolvedVarsMapping, tmpGraphInfo);
    oGraphInfo := tmpGraphInfo;
  end appendVariablesToGraph;

  protected function appendTaskVarEdgesToGraph
    input array<list<Integer>> iTaskSolvedVarsMapping;
    input array<list<Integer>> iTaskUnsolvedVarsMapping;
    input GraphML.GraphInfo iGraphInfo;
    output GraphML.GraphInfo oGraphInfo;
  protected
    GraphML.GraphInfo tmpGraphInfo = iGraphInfo;
    Integer taskIdx, varIdx;
    list<Integer> taskVarList;
  algorithm
    //add edges to solved variables
    for taskIdx in 1:arrayLength(iTaskSolvedVarsMapping) loop
      taskVarList := arrayGet(iTaskSolvedVarsMapping, taskIdx);
      for varIdx in taskVarList loop
        tmpGraphInfo := GraphML.addEdge("varEdge_" + intString(taskIdx) + "_" + intString(varIdx), "var" + intString(varIdx), "Node" + intString(taskIdx), GraphML.COLOR_BLACK, GraphML.LINE(), GraphML.LINEWIDTH_STANDARD, false, {}, (GraphML.ARROWNONE(), GraphML.ARROWSTANDART()), {}, tmpGraphInfo);
      end for;
    end for;
    //add edges to unsolved variables
    for taskIdx in 1:arrayLength(iTaskUnsolvedVarsMapping) loop
      taskVarList := arrayGet(iTaskUnsolvedVarsMapping, taskIdx);
      for varIdx in taskVarList loop
        tmpGraphInfo := GraphML.addEdge("varEdge_" + intString(taskIdx) + "_" + intString(varIdx), "Node" + intString(taskIdx), "var" + intString(varIdx), GraphML.COLOR_BLACK, GraphML.LINE(), GraphML.LINEWIDTH_STANDARD, false, {}, (GraphML.ARROWNONE(), GraphML.ARROWSTANDART()), {}, tmpGraphInfo);
      end for;
    end for;
    oGraphInfo := tmpGraphInfo;
  end appendTaskVarEdgesToGraph;

  protected function appendUnmappedVariablesToGraph
    input array<tuple<Integer,Integer>> iScVarCLMapping;
    input GraphML.GraphInfo iGraphInfo;
    output GraphML.GraphInfo oGraphInfo;
  protected
    GraphML.GraphInfo tmpGraphInfo = iGraphInfo;
    Integer scVarIdx, clIdx;
  algorithm
    for scVarIdx in 1:arrayLength(iScVarCLMapping) loop
      ((clIdx,_)) := arrayGet(iScVarCLMapping, scVarIdx);
      if(intLt(clIdx, 1)) then
        //print("appendUnmappedVariablesToGraph: Found unmapped sc-var with index '" + intString(scVarIdx) + "'\n");
        //tmpGraphInfo := GraphML.addNode("var" + intString(varIdx), GraphML.COLOR_GREEN2, {nodeLabel}, GraphML.ELLIPSE(), SOME(description), {}, iGraphIdx, tmpGraphInfo);
      end if;
    end for;
    oGraphInfo := tmpGraphInfo;
  end appendUnmappedVariablesToGraph;

  protected function appendCacheLineMapToGraph "author: marcusw
    This method will extend the given graph-info with a new subgraph containing the entry of the given cache line."
    input CacheLineMap iCacheLineMap;
    input array<SimCodeVar.SimVar> iCacheVariables;
    input array<Boolean> iAddedVariables;
    input array<tuple<Integer,Integer,Real>> iSchedulerInfo;
    input tuple<Integer,Integer> iTopGraphAttThreadIdIdx; //<topGraphIdx,threadIdAttIdx>
    input array<Integer> iScVarTaskMapping; //maps each scVar (arrayIdx) to the task that solves her
    input HashTableCrILst.HashTable iVarNameSCVarIdxMapping;
    input array<ScVarInfo> iScVarInfos;
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
    //print("appendCacheLineMapToGraph: handling cache line map '" + intString(idx) + "' with " + intString(listLength(entries)) + " entries\n");
    //printCacheLineMap(iCacheLineMap, arrayList(iCacheVariables));
    //check if the cache line contains only parameters
    notOnlyParamters := false;
    for entry in entries loop
      CACHELINEENTRY(threadOwner=entryThreadOwner) := entry;
      notOnlyParamters := boolOr(notOnlyParamters, intNe(entryThreadOwner, -1));
    end for;
    if(notOnlyParamters) then
      (iTopGraphIdx, iAttThreadIdIdx) := iTopGraphAttThreadIdIdx;
      (tmpGraphInfo, (_,_),(_,graphIdx)) := GraphML.addGroupNode("CL_Meta_" + intString(idx), iTopGraphIdx, true, "CL" + intString(idx), iGraphInfo);
      oGraphInfo := List.fold(entries, function appendCacheLineEntryToGraph(iCacheVariables=iCacheVariables, iAddedVariables=iAddedVariables, iSchedulerInfo=iSchedulerInfo, iTopGraphAttThreadIdIdx=(graphIdx,iAttThreadIdIdx), iScVarTaskMapping=iScVarTaskMapping, iVarNameSCVarIdxMapping=iVarNameSCVarIdxMapping, iScVarInfos=iScVarInfos), tmpGraphInfo);
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
    input array<ScVarInfo> iScVarInfos;
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
    //print("HpcOmSimCode.appendCacheLineNodesToGraphTraverse scVarIdx: " + intString(scVarIdx) + " list length of iCacheVariables: " + intString(arrayLength(iCacheVariables)) + "\n");
    if(intGe(arrayLength(iCacheVariables) - scVarIdx + 1, 1)) then
      iVar := arrayGet(iCacheVariables, arrayLength(iCacheVariables) - scVarIdx + 1);
      SimCodeVar.SIMVAR(name=name) := iVar;
      //print("Var with name " + ComponentReference.printComponentRefStr(name) + " found. ScVar-Idx: " + intString(scVarIdx) + "\n");
      if(BaseHashTable.hasKey(name, iVarNameSCVarIdxMapping)) then
        realScVarIdxOffset := BaseHashTable.get(name, iVarNameSCVarIdxMapping);
        realScVarIdx := listGet(realScVarIdxOffset,1);
        realScVarOffset := listGet(realScVarIdxOffset,2);
        realScVarIdx := realScVarIdx + realScVarOffset;
        varString := ComponentReference.printComponentRefStr(name);
        taskIdx := arrayGet(iScVarTaskMapping,realScVarIdx);
        //print("HpcOmSimCode.appendCacheLineNodesToGraphTraverse SCVarNode: " + intString(realScVarIdx) + " [" + varString + "] sccIdx: " + intString(taskIdx) + "\n");
        //print("HpcOmSimCode.appendCacheLineNodesToGraphTraverse ThreadOwner: " + intString(threadOwner) + "\n");
        SCVARINFO(ownerThread=threadOwner) := arrayGet(iScVarInfos, realScVarIdx);
        //print("HpcOmSimCode.appendCacheLineNodesToGraphTraverse ThreadOwner: " + intString(threadOwner) + "\n");
        nodeId := "var" + intString(realScVarIdx);

        arrayUpdate(iAddedVariables, realScVarIdx, true);
        threadText := "Th " + intString(threadOwner);
        nodeLabelText := intString(realScVarIdx);
        nodeLabel := GraphML.NODELABEL_INTERNAL(nodeLabelText, NONE(), GraphML.FONTPLAIN());
        (oGraphInfo,_) := GraphML.addNode(nodeId, GraphML.COLOR_GREEN2,GraphML.BORDERWIDTH_STANDARD, {nodeLabel}, GraphML.ELLIPSE(), SOME(varString), {(iAttThreadIdIdx,threadText)}, iTopGraphIdx, iGraphInfo);
        //print("--handled with realScVarIdx '" + intString(realScVarIdx) + "'\n");
       else
         oGraphInfo := iGraphInfo;
       end if;
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
          print("  Variables\n");
          _ = List.fold(cacheVariables, printCacheVariable, listLength(cacheVariables));
          print("  Float Cache Lines\n");
          List.map1_0(cacheLinesFloat, printCacheLineMap, cacheVariables);
          print("  Int Cache Lines\n");
          List.map1_0(cacheLinesInt, printCacheLineMap, cacheVariables);
          print("  Bool Cache Lines\n");
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

  protected function printCacheVariable
    input SimCodeVar.SimVar iCacheVariable;
    input Integer iIdx;
    output Integer oIdx;
  algorithm
    print("    " + intString(iIdx) + ": " + dumpSimCodeVar(iCacheVariable) + "\n");
    oIdx := iIdx - 1;
  end printCacheVariable;

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
    scVarStr := dumpSimCodeVar(iVar) + " [" + intString(scVarIdx) + "]";
    iVarsString := iVarsString + " " + scVarStr;
    if(intGt(start, 0)) then
      iVarsString := iVarsString + " | ";
      iBytesStringNew := intString(start);
    else
      iBytesStringNew := "";
    end if;
    iBytesStringNew := Util.stringPadLeft(iBytesStringNew, 2 + stringLength(scVarStr) + stringLength(iBytesStringNew), " ");
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
    print("Node " + intString(iNodeIdx) + " uses sc-vars: " + stringDelimitList(List.map(iMappingEntry, intString), ",") + "\n");
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
        //print(" Equation " + intString(eqIdx) + " needs variables " + stringDelimitList(List.map(vars, intString), ",") + "\n");
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

  protected function printScVarInfos
    input array<ScVarInfo> iScVarInfos;
  protected
    Integer scVarIdx;
    Integer ownerThread;
    Boolean isShared;
  algorithm
    print("--------------------\nScVar - Infos\n--------------------\n");
    for scVarIdx in 1:arrayLength(iScVarInfos) loop
      SCVARINFO(ownerThread=ownerThread, isShared=isShared) := arrayGet(iScVarInfos, scVarIdx);
      print("ScVar " + intString(scVarIdx) + " has thread owner " + intString(ownerThread) + " and shared state " + boolString(isShared) + "\n");
    end for;
  end printScVarInfos;

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

  protected function printSimCodeVarTypes
    input array<tuple<Integer,Integer, Integer>> iSimCodeVarTypes;
  protected
    Integer varIdx, varDataType, varSize, varType;
  algorithm
    for varIdx in 1:arrayLength(iSimCodeVarTypes) loop
      ((varDataType, varSize, varType)) := arrayGet(iSimCodeVarTypes, varIdx);
      print("Variable " + intString(varIdx) + " has data type " + intString(varDataType) + " and size " + intString(varSize) + " and type " + intString(varType) + "\n");
    end for;
  end printSimCodeVarTypes;

  // -------------------------------------------
  // SUSAN
  // -------------------------------------------

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
          idxValue = intMod(iIdx-1,listHead(iDimElemCount)) + 1;
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
  protected
    CacheLineMap cacheLineMap;
  algorithm
    oCacheLineMap := match(iPartlyFilledCacheLine)
      case(PARTLYFILLEDCACHELINE_LEVEL(cacheLineMap=cacheLineMap))
        then cacheLineMap;
      case(PARTLYFILLEDCACHELINE_THREAD(cacheLineMap=cacheLineMap))
        then cacheLineMap;
    end match;
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
