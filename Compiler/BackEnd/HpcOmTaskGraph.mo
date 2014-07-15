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

encapsulated package HpcOmTaskGraph
" file:        HpcOmTaskGraph.mo
  package:     HpcOmTaskGraph
  description: HpcOmTaskGraph contains the whole logic to create a TaskGraph on BLT-Level

  RCS: $Id: HpcOmTaskGraph.mo 2013-05-24 11:12:35Z marcusw $
"
public import BackendDAE;
public import DAE;
public import GraphML;

protected import BackendDAEOptimize;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import DAEDump;
protected import Debug;
protected import Expression;
protected import ExpressionSolve;
protected import Flags;
protected import HpcOmBenchmark;
protected import HpcOmScheduler;
protected import List;
protected import SCode;
protected import System;
protected import Util;

//----------------------------
//  Graph Structure
//----------------------------
public
type TaskGraph = array<list<Integer>>;

public uniontype TaskGraphMeta   // stores all the metadata for the TaskGraph
  record TASKGRAPHMETA
    array<list<Integer>> inComps; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
    array<tuple<Integer,Integer,Integer>> varCompMapping;  // maps each variable to <compIdx, eqSystemIdx, offset>. The offset is the sum of the varNumber of all eqSystems with a minor index.
    array<tuple<Integer,Integer,Integer>> eqCompMapping;  // maps each equation to <compIdx, eqSystemIdx, offset>. The offset is the sum of the eqNumber of all eqSystems with a minor index.
    list<Integer> rootNodes;  // all Nodes without predecessor
    array<String> nodeNames; // the name of the nodes for the graphml generation
    array<String> nodeDescs;  // a description of the nodes for the graphml generation - this is a component-description
    array<tuple<Integer,Real>> exeCosts;  // the execution cost for the nodes <numberOfOperations, requiredCycles
    array<list<tuple<Integer,Integer,Integer>>> commCosts;  // the communication cost tuple(_,numberOfVars,requiredCycles) for an edge from array[parentNode] to tuple(childNode,_)
    array<Integer> nodeMark;  // used for level informations -> this is currently not a nodeMark, its a componentMark
  end TASKGRAPHMETA;
end TaskGraphMeta; //TODO: Remove rootNodes from structure

//functions to build the task graph from the BLT structure
//------------------------------------------
//------------------------------------------

public function createTaskGraph "author: marcusw,waurich
  Creates a task graph on scc-level."
  input BackendDAE.BackendDAE inDAE;
  input String filenamePrefix;
  output TaskGraph graphOut;
  output TaskGraphMeta graphDataOut;
protected
  list<BackendDAE.EqSystem> systs;
  BackendDAE.EqSystem head;
  BackendDAE.Shared shared;
  TaskGraph graph;
  TaskGraphMeta graphData;
  String fileName;
algorithm
  //Iterate over each system
  BackendDAE.DAE(systs,shared) := inDAE;
  (graph,graphData) := getEmptyTaskGraph(0,0,0);
  ((graph,graphData,_)) := List.fold1(systs,createTaskGraph0,shared,(graph,graphData,1));
  //printTaskGraph(graph);
  //printTaskGraphMeta(graphData);
  graphOut := graph;
  graphDataOut := graphData;
end createTaskGraph;

public function getSystemComponents "author: marcusw
  Returns all components of the given BackendDAE."
  input BackendDAE.BackendDAE iDae;
  output BackendDAE.StrongComponents oComps;
  output array<tuple<BackendDAE.EqSystem, Integer>> oMapping; //Map each component to <eqSystem, eqSystemIdx>
protected
  BackendDAE.EqSystems systs;
  List<tuple<BackendDAE.EqSystem,Integer>> tmpSystems;
  BackendDAE.StrongComponents tmpComps;

algorithm
  (oComps,oMapping) := match(iDae)
    case(BackendDAE.DAE(eqs=systs))
      equation
        ((tmpComps, tmpSystems,_)) = List.fold(systs,getSystemComponents0,({},{},1));
      then (tmpComps,listArray(tmpSystems));
    else
      then fail();
  end match;
end getSystemComponents;

protected function getSystemComponents0 "author: marcusw
  Adds the information for the given EqSystem to the system mapping structure."
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.StrongComponents, list<tuple<BackendDAE.EqSystem,Integer>>, Integer> iSystMapping; //last Integer is idx of isyst
  output tuple<BackendDAE.StrongComponents, list<tuple<BackendDAE.EqSystem,Integer>>, Integer> oSystMapping; //Map each component to <eqSystem, eqSystemIdx>

protected
  BackendDAE.StrongComponents tmpComps, comps;
  list<tuple<BackendDAE.EqSystem,Integer>> tmpSystMapping;
  Integer currentIdx;
algorithm
  oSystMapping := match(isyst, iSystMapping)
    case(BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)), (tmpComps,tmpSystMapping,currentIdx))
      equation
        //print("--getSystemComponents0 begin\n");
        tmpSystMapping = List.fold2(comps, getSystemComponents1, isyst, currentIdx, tmpSystMapping);
        //print(stringDelimitList(List.map(comps, BackendDump.printComponent),","));
        tmpComps = listAppend(tmpComps,comps);
        //print("--getSystemComponents0 end\n");
      then ((tmpComps, tmpSystMapping, currentIdx+1));
    else
      equation
        print("getSystemComponents0 failed");
      then fail();
  end match;
end getSystemComponents0;

protected function getSystemComponents1 "author: marcusw
  Extends the mapping information for the given component and equation system."
  input BackendDAE.StrongComponent icomp;
  input BackendDAE.EqSystem isyst;
  input Integer isystIdx;
  input list<tuple<BackendDAE.EqSystem,Integer>> iMapping; //Map each component to the EqSystem
  output list<tuple<BackendDAE.EqSystem,Integer>> oMapping; //Map each component to the EqSystem
algorithm
  oMapping := listAppend(iMapping,{(isyst,isystIdx)});
end getSystemComponents1;

public function getNumberOfSystemComponents "author: marcusw
  Returns the number of components stored in the BackendDAE."
  input BackendDAE.BackendDAE iDae;
  output Integer oNumOfComps;
protected
  BackendDAE.EqSystems eqs;
algorithm
  BackendDAE.DAE(eqs=eqs) := iDae;
  oNumOfComps := List.fold(eqs, getNumberOfEqSystemComponents, 0);
end getNumberOfSystemComponents;

public function getNumberOfEqSystemComponents "author: marcusw
  Adds the number of components in the given eqSystem to the iNumOfComps."
  input BackendDAE.EqSystem iEqSystem;
  input Integer iNumOfComps;
  output Integer oNumOfComps;
protected
  BackendDAE.StrongComponents comps;
algorithm
  BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)) := iEqSystem;
  oNumOfComps := iNumOfComps + listLength(comps);
end getNumberOfEqSystemComponents;

public function getEmptyTaskGraph "generates an empty TaskGraph and empty TaskGraphMeta for a graph with numComps nodes.
author: Waurich TUD 2013-06"
  input Integer numComps;
  input Integer numVars;
  input Integer numEqs;
  output TaskGraph graph;
  output TaskGraphMeta graphData;
protected
  array<list<Integer>> inComps;
  array<tuple<Integer,Integer,Integer>> varCompMapping;
  array<tuple<Integer,Integer,Integer>> eqCompMapping;
  list<Integer> rootNodes;
  array<String> nodeNames;
  array<String> nodeDescs;
  array<tuple<Integer,Real>> exeCosts;
  array<list<tuple<Integer,Integer,Integer>>> commCosts;
  array<Integer> nodeMark;
algorithm
  graph := arrayCreate(numComps,{});
  inComps := arrayCreate(numComps,{});
  varCompMapping := arrayCreate(numVars,(0,0,0));
  eqCompMapping := arrayCreate(numEqs,(0,0,0));
  rootNodes := {};
  nodeNames := arrayCreate(numComps,"");
  nodeDescs :=  arrayCreate(numComps,"");
  exeCosts := arrayCreate(numComps,(-1,-1.0));
  commCosts :=  arrayCreate(numComps,{});
  nodeMark := arrayCreate(numComps,0);
  graphData := TASKGRAPHMETA(inComps,varCompMapping,eqCompMapping,rootNodes,nodeNames,nodeDescs,exeCosts,commCosts,nodeMark);
end getEmptyTaskGraph;


protected function createTaskGraph0 "author: marcusw,waurich
  Creates a task graph out of the given system."
  input BackendDAE.EqSystem isyst; //The input system which should be analysed
  input BackendDAE.Shared ishared; //second argument of tuple is an extra argument
  input tuple<TaskGraph,TaskGraphMeta,Integer> graphInfoIn; //<_,_,eqSysIdx>
  output tuple<TaskGraph,TaskGraphMeta,Integer> grapInfoOut;
  //output BackendDAE.EqSystem osyst; //no change here -> this is always isyst
  //output tuple<BackendDAE.Shared,Boolean> oshared; //no change here -> this is always ishared
algorithm
  grapInfoOut := matchcontinue(isyst,ishared,graphInfoIn)
    local
      Integer eqSysIdx;
      tuple<TaskGraph,TaskGraphMeta,Integer> tplOut;
      BackendDAE.StrongComponents comps;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.IncidenceMatrix incidenceMatrix;
      DAE.FunctionTree sharedFuncs;
      TaskGraph graphIn;
      TaskGraph graphTmp;
      TaskGraphMeta graphDataIn;
      TaskGraphMeta graphDataTmp;
      array<list<tuple<Integer,Integer,Integer>>> commCosts;
      array<list<Integer>> inComps;
      array<tuple<Integer,Real>> exeCosts;
      array<Integer> nodeMark;
      array<tuple<Integer,Integer,Integer>> varCompMapping, eqCompMapping; //Map each variable to the scc that solves her
      array<String> nodeNames;
      array<String> nodeDescs;
      list<Integer> eventEqLst, eventVarLst, rootNodes, rootVars;
      Integer numberOfVars, numberOfEqs;
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps), orderedVars=BackendDAE.VARIABLES(numberOfVars=numberOfVars), orderedEqs=BackendDAE.EQUATION_ARRAY(numberOfElement=numberOfEqs)),(shared as BackendDAE.SHARED(functionTree=sharedFuncs)),(_,_,eqSysIdx))
      equation
        //Create Taskgraph for the first EqSystem
        //TASKGRAPHMETA(varCompMapping=varCompMapping,eqCompMapping=eqCompMapping) = graphDataIn;
        true = intEq(eqSysIdx,1);
        (_,incidenceMatrix,_) = BackendDAEUtil.getIncidenceMatrix(isyst, BackendDAE.NORMAL(), SOME(sharedFuncs));
        //print("createTaskGraph0 with " +& intString(listLength(comps)) +& " components, " +& intString(arrayLength(ass1)) +& " variables and " +& intString(arrayLength(ass2)) +& " equations\n");
        (graphTmp,graphDataTmp) = getEmptyTaskGraph(listLength(comps), numberOfVars, numberOfEqs);
        TASKGRAPHMETA(inComps = inComps, rootNodes = rootNodes, nodeNames =nodeNames, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark, varCompMapping=varCompMapping,eqCompMapping=eqCompMapping) = graphDataTmp;
        //print("createTaskGraph0 try to get varCompMapping\n");
        (varCompMapping,eqCompMapping) = getVarEqCompMapping(comps, eqSysIdx, 0, 0, varCompMapping, eqCompMapping);
        //print("createTaskGraph0 varCompMapping created\n");
        nodeDescs = getEquationStrings(comps,isyst);  //gets the description i.e. the whole equation, for every component
        ((graphTmp,inComps,commCosts,nodeNames,rootNodes,nodeMark,_)) = List.fold2(comps,createTaskGraph1,(incidenceMatrix,isyst,shared,listLength(comps)),(varCompMapping,eqCompMapping,{}),(graphTmp,inComps,commCosts,nodeNames,rootNodes,nodeMark,1));
        // gather the metadata
        graphDataTmp = TASKGRAPHMETA(inComps, varCompMapping, eqCompMapping, rootNodes, nodeNames, nodeDescs, exeCosts, commCosts, nodeMark);
        tplOut = ((graphTmp,graphDataTmp,eqSysIdx+1));
      then
        tplOut;
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps), orderedVars=BackendDAE.VARIABLES(numberOfVars=numberOfVars), orderedEqs=BackendDAE.EQUATION_ARRAY(numberOfElement=numberOfEqs)),(shared as BackendDAE.SHARED(functionTree=sharedFuncs)),(graphIn,graphDataIn,eqSysIdx))
      equation
        //append the remaining equationsystems to the taskgraph
        //TASKGRAPHMETA(varCompMapping=varCompMapping,eqCompMapping=eqCompMapping) = graphDataIn;
        false = intEq(eqSysIdx,1);
        (_,incidenceMatrix,_) = BackendDAEUtil.getIncidenceMatrix(isyst, BackendDAE.NORMAL(), SOME(sharedFuncs));
        //print("createTaskGraph0_case2 with " +& intString(listLength(comps)) +& " components, " +& intString(arrayLength(ass1)) +& " variables and " +& intString(arrayLength(ass2)) +& " equations\n");
        (graphTmp,graphDataTmp) = getEmptyTaskGraph(listLength(comps), numberOfVars, numberOfEqs);
        TASKGRAPHMETA(inComps = inComps, rootNodes = rootNodes, nodeNames =nodeNames, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark, varCompMapping=varCompMapping,eqCompMapping=eqCompMapping) = graphDataTmp;
        //print("createTaskGraph0 try to get varCompMapping\n");
        (varCompMapping,eqCompMapping) = getVarEqCompMapping(comps, eqSysIdx, 0, 0, varCompMapping, eqCompMapping);
        //print("createTaskGraph0 varCompMapping created\n");
        nodeDescs = getEquationStrings(comps,isyst);  //gets the description i.e. the whole equation, for every component
        ((graphTmp,inComps,commCosts,nodeNames,rootNodes,nodeMark,_)) = List.fold2(comps,createTaskGraph1,(incidenceMatrix,isyst,shared,listLength(comps)),(varCompMapping,eqCompMapping,{}),(graphTmp,inComps,commCosts,nodeNames,rootNodes,nodeMark,1));
        // gather the metadata
        graphDataTmp = TASKGRAPHMETA(inComps, varCompMapping, eqCompMapping, rootNodes, nodeNames, nodeDescs, exeCosts, commCosts, nodeMark);
        (graphTmp,graphDataTmp) = taskGraphAppend(graphIn,graphDataIn,graphTmp,graphDataTmp);
        tplOut = ((graphTmp,graphDataTmp,eqSysIdx+1));
      then
        tplOut;
    else
      equation
      print("createTaskGraph0 failed \n");
      then
        fail();
  end matchcontinue;
end createTaskGraph0;


protected function taskGraphAppend "appends a taskGraph system to an other taskGraph system.all indices will be numbered continuously.
author:Waurich TUD 2013-06"
  input TaskGraph graph1In;
  input TaskGraphMeta graphData1In;
  input TaskGraph graph2In;
  input TaskGraphMeta graphData2In;
  output TaskGraph graphOut;
  output TaskGraphMeta graphDataOut;
protected
  Integer eqOffset;
  Integer idxOffset;
  Integer varOffset;
  array<list<tuple<Integer,Integer,Integer>>> commCosts1, commCosts2;
  array<list<Integer>> inComps1, inComps2;
  array<tuple<Integer,Integer,Integer>> eqCompMapping1, eqCompMapping2;
  array<tuple<Integer,Real>> exeCosts1, exeCosts2;
  array<Integer> nodeMark1, nodeMark2;
  array<tuple<Integer,Integer,Integer>> varCompMapping1, varCompMapping2; //Map each variable to the scc which solves her
  array<String> nodeNames1, nodeNames2;
  array<String> nodeDescs1, nodeDescs2;
  list<Integer> rootNodes1, rootNodes2;
  TaskGraph graph2;
algorithm
  TASKGRAPHMETA(inComps = inComps1 ,varCompMapping=varCompMapping1, eqCompMapping=eqCompMapping1, rootNodes = rootNodes1, nodeNames =nodeNames1, nodeDescs= nodeDescs1, exeCosts = exeCosts1, commCosts=commCosts1, nodeMark=nodeMark1) := graphData1In;
  TASKGRAPHMETA(inComps = inComps2 ,varCompMapping=varCompMapping2, eqCompMapping=eqCompMapping2, rootNodes = rootNodes2, nodeNames =nodeNames2, nodeDescs= nodeDescs2, exeCosts = exeCosts2, commCosts=commCosts2, nodeMark=nodeMark2) := graphData2In;
  eqOffset := arrayLength(eqCompMapping1);
  idxOffset := arrayLength(graph1In);
  varOffset := arrayLength(varCompMapping1);
  eqOffset := arrayLength(eqCompMapping1);
  graph2 := Util.arrayMap1(graph2In,updateTaskGraphSystem,idxOffset);
  graphOut := Util.arrayAppend(graph1In,graph2);
  inComps2 := Util.arrayMap1(inComps2,updateTaskGraphSystem,idxOffset);
  inComps2 := Util.arrayAppend(inComps1,inComps2);
  //varCompMapping2 := Util.arrayMap1(varCompMapping2,modifyMapping,varOffset);
  varCompMapping2 := Util.arrayMap1(varCompMapping2,modifyMapping,idxOffset);
  varCompMapping2 := Util.arrayAppend(varCompMapping1,varCompMapping2);
  //eqCompMapping2 := Util.arrayMap1(eqCompMapping2,modifyMapping,eqOffset);
  eqCompMapping2 := Util.arrayMap1(eqCompMapping2,modifyMapping,idxOffset);
  eqCompMapping2 := Util.arrayAppend(eqCompMapping1,eqCompMapping2);
  rootNodes2 := List.map1(rootNodes2,intAdd,idxOffset);
  rootNodes2 := listAppend(rootNodes1,rootNodes2);
  nodeNames2 := Util.arrayMap1(nodeNames2,stringAppend," subsys");  //TODO: change this
  nodeNames2 := Util.arrayAppend(nodeNames1,nodeNames2);
  nodeDescs2 := Util.arrayAppend(nodeDescs1,nodeDescs2);
  exeCosts2 := Util.arrayAppend(exeCosts1,exeCosts2);
  commCosts2 := Util.arrayMap1(commCosts2,updateCommCosts,idxOffset);
  commCosts2 := Util.arrayAppend(commCosts1,commCosts2);
  nodeMark2 := Util.arrayAppend(nodeMark1,nodeMark2);
  graphDataOut := TASKGRAPHMETA(inComps2,varCompMapping2,eqCompMapping2,rootNodes2,nodeNames2,nodeDescs2,exeCosts2,commCosts2,nodeMark2);
end taskGraphAppend;

protected function modifyMapping
  input tuple<Integer,Integer,Integer> iMappingTuple;
  input Integer iOffset;
  output tuple<Integer,Integer,Integer> oMappingTuple;
protected
  Integer i1,i2,i3; //i1 = offset
algorithm
  (i1,i2,i3) := iMappingTuple;
  oMappingTuple := (i1+iOffset,i2,iOffset);
end modifyMapping;

protected function updateCommCosts " updates the CommCosts to the enumerated indeces.
author: Waurich TUD 2013-07"
  input list<tuple<Integer,Integer,Integer>> commCostsIn;
  input Integer idxOffset;
  output list<tuple<Integer,Integer,Integer>> commCostsOut;
algorithm
  commCostsOut := List.map1(commCostsIn,updateCommCosts1,idxOffset);
end updateCommCosts;


protected function updateCommCosts1
  input tuple<Integer,Integer,Integer> commCostsIn;
  input Integer idxOffset;
  output tuple<Integer,Integer,Integer> commCostsOut;
protected
  Integer childNode,numberOfVars,reqCycles;
algorithm
  (childNode,numberOfVars,reqCycles) := commCostsIn;
  commCostsOut := (childNode+idxOffset,numberOfVars,reqCycles);
end updateCommCosts1;


protected function updateTaskGraphSystem "map function to add the indices in the taskGraph system to the number of nodes of the previous system.
author:Waurich TUD 2013-07"
  input list<Integer> graphRowIn;
  input Integer idxOffset;
  output list<Integer> graphRowOut;
algorithm
  graphRowOut := List.map1(graphRowIn,intAdd,idxOffset);
end updateTaskGraphSystem;


protected function createTaskGraph1 "author: marcusw,waurich
  Appends the task-graph information for the given StrongComponent to the given graph."
  input BackendDAE.StrongComponent component;
  input tuple<BackendDAE.IncidenceMatrix,BackendDAE.EqSystem,BackendDAE.Shared,Integer> isystInfo; //<incidenceMatrix,isyst,ishared,numberOfComponents> in very compact form
  input tuple<array<tuple<Integer,Integer,Integer>>,array<tuple<Integer,Integer,Integer>>,list<Integer>> varInfo; //<varCompMapping,eqCompMapping,eventVarLst
  input tuple<TaskGraph,array<list<Integer>>,array<list<tuple<Integer,Integer,Integer>>>,array<String>,list<Integer>,array<Integer>,Integer> graphInfoIn;
  //<taskGraph,inComps,commCosts,nodeNames,rootNodes,componentIndex>
  output tuple<TaskGraph,array<list<Integer>>,array<list<tuple<Integer,Integer,Integer>>>,array<String>,list<Integer>,array<Integer>,Integer> graphInfoOut;
protected
  BackendDAE.IncidenceMatrix incidenceMatrix;
  BackendDAE.EqSystem isyst;
  BackendDAE.Shared ishared;
  TaskGraph graphIn;
  TaskGraph graphTmp;
  array<list<Integer>> inComps;
  array<tuple<Integer,Integer,Integer>>  varCompMapping;
  array<tuple<Integer,Integer,Integer>> eqCompMapping;
  list<Integer> rootNodes;
  array<String> nodeNames;
  array<String> nodeDescs;
  array<list<tuple<Integer,Integer,Integer>>> commCosts;
  array<Integer> nodeMark;
  list<tuple<Integer,Integer>> unsolvedVars;
  list<Integer> eventVarLst;
  array<Integer> requiredSccs;
  Integer componentIndex, numberOfComps;
  list<tuple<Integer,Integer>> requiredSccs_RefCount;
  String nodeName;
algorithm
  (incidenceMatrix,isyst,ishared,numberOfComps) := isystInfo;
  (varCompMapping,eqCompMapping,eventVarLst) := varInfo;
  (graphIn,inComps,commCosts,nodeNames,rootNodes,nodeMark,componentIndex) := graphInfoIn;
  inComps := arrayUpdate(inComps,componentIndex,{componentIndex});
  nodeName := BackendDump.strongComponentString(component);
  nodeNames := arrayUpdate(nodeNames,componentIndex,nodeName);
  _ := HpcOmBenchmark.benchSystem();
  //nodeMark := arrayUpdate(nodeMark,componentIndex,getNodeMark(componentIndex,incidenceMatrix,varCompMapping,eqCompMapping));
  unsolvedVars := getUnsolvedVarsBySCC(component,incidenceMatrix,eventVarLst);
  requiredSccs := arrayCreate(numberOfComps,0); //create a ref-counter for each component
  requiredSccs := List.fold1(unsolvedVars,fillSccList,varCompMapping,requiredSccs);
  ((_,requiredSccs_RefCount)) := Util.arrayFold(requiredSccs, convertRefArrayToList, (1,{}));
  commCosts := updateCommCostBySccRef(requiredSccs_RefCount, componentIndex, commCosts);
  (graphTmp,rootNodes) := fillAdjacencyList(graphIn,rootNodes,componentIndex,requiredSccs_RefCount,1);
  graphTmp := Util.arrayMap1(graphTmp,List.sort,intGt);
  graphInfoOut := (graphTmp,inComps,commCosts,nodeNames,rootNodes,nodeMark,componentIndex+1);
end createTaskGraph1;


protected function updateCommCostBySccRef "author: marcusw
  Updates the given commCosts-array with the values of the refCount-list."
  input list<tuple<Integer,Integer>> requiredSccs_RefCount; //<sccIdx,refCount>
  input Integer nodeIdx;
  input array<list<tuple<Integer,Integer,Integer>>> iCommCosts; //<sccIdx,numberOfVars,requiredCycles>
  output array<list<tuple<Integer,Integer,Integer>>> oCommCosts;

protected
  list<tuple<Integer,Integer,Integer>> tmpList;

algorithm
  tmpList := List.map(requiredSccs_RefCount, updateCommCostBySccRef0);
  //oCommCosts := arrayUpdate(iCommCosts, nodeIdx,tmpList);
  oCommCosts := List.fold1(tmpList,updateCommCostBySccRef1,nodeIdx,iCommCosts);
end updateCommCostBySccRef;

protected function updateCommCostBySccRef0 "author: marcusw
  Helper function which converts a tuple<Integer,Integer> to a tuple<Integer,Integer,-1>."
  input tuple<Integer,Integer> iTuple;
  output tuple<Integer,Integer,Integer> oTuple;
protected
  Integer i1,i2;
algorithm
  (i1,i2) := iTuple;
  oTuple := ((i1,i2,-1));

end updateCommCostBySccRef0;

protected function updateCommCostBySccRef1 "author: marcusw
  Helper function which appends an edge from source to target with the given parameters."
  input tuple<Integer,Integer,Integer> iEdgeSource; //<sccIdx,numberOfVars,requiredCycles>
  input Integer iEdgeTarget; //sccIdx
  input array<list<tuple<Integer,Integer,Integer>>> iCommCosts; //<sccIdx,numberOfVars,requiredCycles>
  output array<list<tuple<Integer,Integer,Integer>>> oCommCosts;

protected
  list<tuple<Integer,Integer,Integer>> oldList;
  Integer sourceSccIdx, edgeNumOfVars, edgeReqCycles;

algorithm
  (sourceSccIdx,edgeNumOfVars,edgeReqCycles) := iEdgeSource;
  oldList := arrayGet(iCommCosts, sourceSccIdx);
  //print("updateCommCostBySccRef1 added edge from " +& intString(sourceSccIdx) +& " to " +& intString(iEdgeTarget) +& "\n");
  oCommCosts := arrayUpdate(iCommCosts, sourceSccIdx, (iEdgeTarget,edgeNumOfVars,edgeReqCycles)::oldList);

end updateCommCostBySccRef1;

protected function fillAdjacencyList "sets the child index in the rows indexed by the parent list.
author: waurich TUD 2013-06"
  input array<list<Integer>> adjLstIn;
  input list<Integer> rootNodesIn;
  input Integer childNode;
  input list<tuple<Integer,Integer>> parentLst;
  input Integer Idx;
  output array<list<Integer>> adjLstOut;
  output list<Integer> rootNodesOut;
algorithm
  (adjLstOut, rootNodesOut) := matchcontinue(adjLstIn,rootNodesIn,childNode,parentLst,Idx)
    local
      Integer parentNode;
      list<Integer> parentRow;
      list<Integer> rootNodes;
      array<list<Integer>> adjLst;
    case(_,_,_,_,_)
      equation
        true = listLength(parentLst) >= Idx;
        ((parentNode,_)) = listGet(parentLst,Idx);
        parentRow = arrayGet(adjLstIn,parentNode);
        parentRow = childNode::parentRow;
        parentRow = List.removeOnTrue(parentNode,intEq,parentRow);  // deletes the self-loops
        adjLst = arrayUpdate(adjLstIn,parentNode,parentRow);
        (adjLst,rootNodes) = fillAdjacencyList(adjLst,rootNodesIn,childNode,parentLst,Idx+1);
      then
        (adjLst,rootNodes);
    case(_,_,_,_,_)
      equation
        true = List.isEmpty(parentLst);
        rootNodes = childNode::rootNodesIn;
      then
        (adjLstIn,rootNodes);
    else
      then
        (adjLstIn,rootNodesIn);
  end matchcontinue;
end fillAdjacencyList;


protected function printReqScc
  input Integer refSccIdx;
  input array<Integer> requiredSccs;

protected
  Integer refCount;
  String refIdxStr,refCountStr;
algorithm
  _ := matchcontinue(refSccIdx,requiredSccs)
    case(_,_)
      equation
        true = intLe(refSccIdx,arrayLength(requiredSccs));
        true = intGt(refSccIdx,-1);
        refCount = requiredSccs[refSccIdx];
        refIdxStr = intString(refSccIdx);
        refCountStr = intString(refCount);
        print(refIdxStr +& ":" +& refCountStr +& " ");
        printReqScc(refSccIdx+1,requiredSccs);
      then ();
    else ();
  end matchcontinue;
end printReqScc;

protected function getEquationStrings " gets the equation and the variable its solved for for every StrongComponent. index = component. entry = description
author:Waurich TUD 2013-06"
  input BackendDAE.StrongComponents iComps;
  input BackendDAE.EqSystem iEqSystem;
  output array<String> eqDescsOut;
protected
  list<String> eqDescs;
algorithm
  eqDescs := List.fold1(iComps,getEquationStrings2,iEqSystem,{});
  eqDescs := listReverse(eqDescs);
  eqDescsOut := listArray(eqDescs);
end getEquationStrings;


protected function getEquationStrings2 "implementation for getEquationStrings
author:Waurich TUD 2013-06"
  input BackendDAE.StrongComponent comp;
  input BackendDAE.EqSystem iEqSystem;
  input List<String> iEqDesc;
  output List<String> oEqDesc;
algorithm
  oEqDesc := matchcontinue(comp,iEqSystem,iEqDesc)
    local
      Integer i;
      Integer v;
      List<BackendDAE.Equation> eqnLst;
      List<BackendDAE.Var> varLst;
      array<Integer> ass2;
      List<Integer> es;
      List<Integer> vs;
      List<String> descLst;
      List<String> eqDescLst;
      List<String> varDescLst;
      String eqString;
      String varString;
      String desc;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      BackendDAE.JacobianType jacT;
      BackendDAE.EquationArray orderedEqs;
      BackendDAE.Variables orderedVars;
      BackendDAE.Equation eqn;
      BackendDAE.Var var;
    case(BackendDAE.SINGLEEQUATION(eqn = i, var = v), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars),_)
      equation
       //get the equation string
       eqnLst = BackendEquation.equationList(orderedEqs);
       eqn = listGet(eqnLst,i);
       eqString = BackendDump.equationString(eqn);
       eqString = prepareXML(eqString);
       //get the variable string
       varLst = BackendVariable.varList(orderedVars);
       var = listGet(varLst,v);
       varString = getVarString(var);
       desc = (eqString +& " FOR " +& varString);
       descLst = desc::iEqDesc;
     then
       descLst;
  case(BackendDAE.EQUATIONSYSTEM(jac = BackendDAE.FULL_JACOBIAN(_)), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs),_)
     equation
       _ = BackendEquation.equationList(orderedEqs);
       desc = ("Equation System");
       descLst = desc::iEqDesc;
     then
       descLst;
  case(BackendDAE.MIXEDEQUATIONSYSTEM(disc_eqns = _), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs),_)
     equation
       _ = BackendEquation.equationList(orderedEqs);
       desc = ("MixedEquation System");
       descLst = desc::iEqDesc;
     then
       descLst;
   case(BackendDAE.SINGLEARRAY(eqn = i, vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2=_)),_)
     equation
      //get the equation string
      eqnLst = BackendEquation.equationList(orderedEqs);
      eqn = listGet(eqnLst,i);
      eqString = BackendDump.equationString(eqn);
      eqString = prepareXML(eqString);
      //get the variable string
      varLst = BackendVariable.varList(orderedVars);
      //var = listGet(varLst,arrayGet(ass2,i));
      //varString = getVarString(var);
      //desc = ("ARRAY:"+&eqString +& " FOR " +& varString);
      desc = ("ARRAY:"+&eqString +& " FOR THE VARS: " +& stringDelimitList(List.map1(vs,List.getIndexFirst,List.map(varLst,getVarString))," AND "));
      descLst = desc::iEqDesc;
    then
      descLst;
   case(BackendDAE.SINGLEALGORITHM(eqn = i, vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2=_)),_)
     equation
      //get the equation string
      eqnLst = BackendEquation.equationList(orderedEqs);
      eqn = listGet(eqnLst,i);
      eqString = BackendDump.equationString(eqn);
      eqString = prepareXML(eqString);
      //get the variable string
      varLst = BackendVariable.varList(orderedVars);
      //var = listGet(varLst,arrayGet(ass2,i));
      //varString = getVarString(var);
      //desc = ("ALGO:"+&eqString +& " FOR " +& varString);
      desc = ("ALGO: "+&eqString +& " FOR THE VARS: " +& stringDelimitList(List.map1(vs,List.getIndexFirst,List.map(varLst,getVarString))," AND "));
      descLst = desc::iEqDesc;
    then
      descLst;
   case(BackendDAE.SINGLECOMPLEXEQUATION(eqn = i, vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2=_)),_)
     equation
      //get the equation string
      eqnLst = BackendEquation.equationList(orderedEqs);
      eqn = listGet(eqnLst,i);
      eqString = BackendDump.equationString(eqn);
      eqString = prepareXML(eqString);
      //get the variable string
      varLst = BackendVariable.varList(orderedVars);
      //var = listGet(varLst,arrayGet(ass2,i));
      //varString = getVarString(var);
      //desc = ("COMPLEX:"+&eqString +& " FOR " +& varString);
      desc = ("COMPLEX: "+&eqString +& " FOR THE VARS: " +& stringDelimitList(List.map1(vs,List.getIndexFirst,List.map(varLst,getVarString))," AND "));
      descLst = desc::iEqDesc;
    then
      descLst;
   case(BackendDAE.SINGLEWHENEQUATION(eqn = i, vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2=_)),_)
     equation
      //get the equation string
      eqnLst = BackendEquation.equationList(orderedEqs);
      eqn = listGet(eqnLst,i);
      eqString = BackendDump.equationString(eqn);
      eqString = prepareXML(eqString);
      //get the variable string
      varLst = BackendVariable.varList(orderedVars);
      //var = listGet(varLst,arrayGet(ass2,i));
      //varString = getVarString(var);
      //desc = ("WHEN:"+&eqString +& " FOR " +& varString);
      desc = ("WHEN:"+&eqString +& " FOR THE VARS: " +& stringDelimitList(List.map1(vs,List.getIndexFirst,List.map(varLst,getVarString))," AND "));
      descLst = desc::iEqDesc;
    then
      descLst;
   case(BackendDAE.SINGLEIFEQUATION(eqn = i, vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2=_)),_)
     equation
      //get the equation string
      eqnLst = BackendEquation.equationList(orderedEqs);
      eqn = listGet(eqnLst,i);
      eqString = BackendDump.equationString(eqn);
      eqString = prepareXML(eqString);
      //get the variable string
      varLst = BackendVariable.varList(orderedVars);
      //var = listGet(varLst,arrayGet(ass2,i));
      //varString = getVarString(var);
      //desc = ("IFEQ:"+&eqString +& " FOR " +& varString);
      desc = ("IFEQ:"+&eqString +& " FOR THE VARS: " +& stringDelimitList(List.map1(vs,List.getIndexFirst,List.map(varLst,getVarString))," AND "));
      descLst = desc::iEqDesc;
    then
      descLst;
  case(BackendDAE.TORNSYSTEM(residualequations = _, tearingvars = _, linear=true), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs,  matching= BackendDAE.MATCHING(ass2=_)),_)
     equation
      //get the equation string
       _ = BackendEquation.equationList(orderedEqs);
       desc = ("Torn linear System");
       descLst = desc::iEqDesc;
    then
      descLst;
  case(BackendDAE.TORNSYSTEM(residualequations = _, tearingvars = _, linear=false), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs,  matching= BackendDAE.MATCHING(ass2=_)),_)
     equation
      //get the equation string
       _ = BackendEquation.equationList(orderedEqs);
       desc = ("Torn nonlinear System");
       descLst = desc::iEqDesc;
    then
      descLst;
  else
    equation
      desc = ("no singleEquation");
      descLst = desc::iEqDesc;
    then
      descLst;
  end matchcontinue;
end getEquationStrings2;


public function getVarString "get the var string for a given variable. shortens the String. if necessary insert der operator
author:waurich TUD 2013-06"
  input BackendDAE.Var inVar;
  output String varString;
algorithm
  varString := matchcontinue(inVar)
  local
    BackendDAE.VarKind kind;
    list<String> varDescLst;
  case(_)
    equation
    true = BackendVariable.isNonStateVar(inVar);
    varString = BackendDump.varString(inVar);
    varDescLst = stringListStringChar(varString);
    varDescLst = shortenVarString(varDescLst);
    varString = stringCharListString(varDescLst);
  then
    varString;
  case(_)
    equation
    false = BackendVariable.isNonStateVar(inVar);
    varString = BackendDump.varString(inVar);
    varDescLst = stringListStringChar(varString);
    varDescLst = shortenVarString(varDescLst);
    varString = stringCharListString(varDescLst);
    varString = (" der(" +& varString +& ")");
    then
      varString;
  end matchcontinue;
end getVarString;

public function prepareXML " map-function for deletion of forbidden chars from given string
author:Waurich TUD 2013-06"
  input String iString;
  output String oString;
protected
  list<String> lst;
algorithm
  lst := stringListStringChar(iString);
  lst := List.map(lst,prepareXML1);
  oString := stringCharListString(lst);
end prepareXML;

//TODO: Replace with CDATA, Check if this can be removed
protected function prepareXML1 " map-function for deletion of forbidden chars from given string
author:Waurich TUD 2013-06"
  input String iString;
  output String oString;
algorithm
  oString := matchcontinue(iString)
    local
      String string;
    case(_)
      equation
      true = stringEq(iString, ">");
      then " greater ";
    case(_)
      equation
      true = stringEq(iString, "<");
      then " less ";
    else
    then iString;
  end matchcontinue;
end prepareXML1;

public function shortenVarString " terminates var string at :
author:Waurich TUD 2013-06"
  input List<String> iString;
  output List<String> oString;
protected
  Integer pos;
algorithm
  pos := List.position(":",iString);
  (oString,_) := List.split(iString,pos);
end shortenVarString;


protected function getEventNodes " gets the taskgraph nodes that are when-equations
author:Waurich TUD 2013-06"
  input BackendDAE.BackendDAE systIn;
  input array<tuple<Integer,Integer,Integer>> eqCompMapping;
  output list<Integer> eventNodes;
protected
  list<Integer> eqLst;
  list<tuple<Integer,Integer,Integer>> tplLst;
  BackendDAE.EqSystems systemsIn;
algorithm
  BackendDAE.DAE(eqs=systemsIn) := systIn;
  ((eqLst,_)) := List.fold(systemsIn, getEventNodeEqs,({},0));
  eventNodes := getArrayTuple31(eqLst,eqCompMapping);
end getEventNodes;


protected function getEventNodeEqs "gets the equation for the When-nodes.
author: Waurich TUD 2013-06"
  input BackendDAE.EqSystem systIn;
  input tuple<list<Integer>,Integer> eventInfoIn;
  output tuple<list<Integer>,Integer> eventInfoOut;
protected
  BackendDAE.StrongComponents comps;
  list<Integer> eventEqs;
  list<Integer> eventEqsIn;
  Integer numOfEqs;
  Integer offset;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs = BackendDAE.EQUATION_ARRAY(numberOfElement=numOfEqs),matching=BackendDAE.MATCHING(comps = comps)) := systIn;
  (eventEqsIn,offset) := eventInfoIn;
  eventEqs := getEventNodeEqs1(comps,offset,{});
  offset := offset+numOfEqs;
  eventEqs := listAppend(eventEqs,eventEqsIn);
  eventInfoOut := (eventEqs,offset);
end getEventNodeEqs;


protected function getEventNodeEqs1 "fold-function for getEventNodeEqs to compute the when equation in an eqSystem
author: Waurich TUD 2013-06"
  input BackendDAE.StrongComponents comps;
  input Integer offset;
  input list<Integer> eventEqsIn;
  output list<Integer> eventEqsOut;
algorithm
  eventEqsOut := matchcontinue(comps,offset,eventEqsIn)
    local
      Integer eqn;
      Integer sysCount;
      list<Integer> eventEqs;
      list<Integer> condVars;
      BackendDAE.StrongComponents rest;
      BackendDAE.StrongComponent head;
    case((head::rest),_,_)
      equation
        true = isWhenEquation(head);
        BackendDAE.SINGLEWHENEQUATION(eqn = eqn) = head;
        eqn = eqn+offset;
        eventEqs = getEventNodeEqs1(rest,offset,eqn::eventEqsIn);
      then
        eventEqs;
    case((head::rest),_,_)
      equation
        false = isWhenEquation(head);
        eventEqs = getEventNodeEqs1(rest,offset,eventEqsIn);
      then
        eventEqs;
    case({},_,_)
      then
        eventEqsIn;
  end matchcontinue;
end getEventNodeEqs1;

protected function getArrayTuple31 " matches entries of list1 with the assigned values of assign to obtain the values
author:Waurich TUD 2013-06"
  input list<Integer> list1;
  input array<tuple<Integer,Integer,Integer>> assign;
  output list<Integer> list2Out;
protected
  list<tuple<Integer,Integer,Integer>> tplLst;
algorithm
   tplLst := List.map1(list1,Util.arrayGetIndexFirst,assign);
   list2Out := List.map(tplLst,Util.tuple31);
end getArrayTuple31;


protected function isWhenEquation " checks if the comp is of type SINGLEWHENEQUATION.
author:Waurich TUD 2013-06"
  input BackendDAE.StrongComponent inComp;
  output Boolean isWhenEq;
algorithm
  isWhenEq := matchcontinue(inComp)
  local Integer eqn;
    case(BackendDAE.SINGLEWHENEQUATION(eqn=_))
    then
      true;
  else
    then
      false;
  end matchcontinue;
end isWhenEquation;

protected function fillSccList "author: marcusw
  This function appends the scc, which solves the given variable, to the requiredsccs-list."
  input tuple<Integer,Integer> variable;
  input array<tuple<Integer,Integer,Integer>> varCompMapping;
  input array<Integer> iRequiredSccs;
  output array<Integer> oRequiredSccs;

algorithm
  oRequiredSccs := matchcontinue(variable,varCompMapping,iRequiredSccs)
    local
      Integer varIdx,varState, sccIdx, oldCount;
      array<Integer> tmpRequiredSccs;
    case ((varIdx,varState),_,_)
      equation
        true = intEq(varState,1);
        tmpRequiredSccs = iRequiredSccs;
        ((sccIdx,_,_)) = arrayGet(varCompMapping,varIdx);
        oldCount = iRequiredSccs[sccIdx];
        tmpRequiredSccs = arrayUpdate(tmpRequiredSccs,sccIdx,oldCount+1);
      then tmpRequiredSccs;
   else iRequiredSccs;
  end matchcontinue;
end fillSccList;


protected function convertRefArrayToList
  input Integer refCountValue;
  input tuple<Integer,list<tuple<Integer,Integer>>> iList; //the current index and the current ref-list
  output tuple<Integer,list<tuple<Integer,Integer>>> oList;

protected
  Integer curIdx;
  tuple<Integer,Integer> tmpTuple;
  list<tuple<Integer,Integer>> curList;

algorithm
  oList := match(refCountValue,iList)
    case(0,(curIdx,curList))
      then ((curIdx+1,curList));
    case(_,(curIdx,curList))
      equation
        tmpTuple = (curIdx,refCountValue);
        curList = tmpTuple::curList;
      then ((curIdx+1,curList));
   end match;
end convertRefArrayToList;


//TODO: Remove prints if not required
protected function getUnsolvedVarsBySCC "author: marcusw,waurich
  Returns all required variables which are not solved inside the given component."
  input BackendDAE.StrongComponent component;
  input BackendDAE.IncidenceMatrix incidenceMatrix;
  input list<Integer> eventVarLst;
  output List<tuple<Integer,Integer>> unsolvedVars;

algorithm
  unsolvedVars := matchcontinue(component, incidenceMatrix,eventVarLst)
    local
      Integer varIdx;
      List<Integer> varIdc;
      List<tuple<Integer,Integer>> tmpVars;
    case(BackendDAE.SINGLEEQUATION(var=varIdx),_,_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_pre", "{", ";", "}", true) +& "\n");
        tmpVars = List.removeOnTrue(varIdx, compareTupleByVarIdx, tmpVars);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_post", "{", ";", "}", true) +& "\n");
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_noEvent", "{", ";", "}", true) +& "\n");
      then
        tmpVars;
    case(BackendDAE.MIXEDEQUATIONSYSTEM(disc_vars=varIdc),_,_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then
        tmpVars;
    case(BackendDAE.EQUATIONSYSTEM(vars=varIdc),_,_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then
        tmpVars;
    case(BackendDAE.SINGLEARRAY(vars=varIdc),_,_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then
        tmpVars;
    case(BackendDAE.SINGLEALGORITHM(vars=varIdc),_,_)
      equation
        tmpVars = getVarsBySCC(component,incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then
        tmpVars;
    case(BackendDAE.SINGLECOMPLEXEQUATION(vars=varIdc),_,_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then tmpVars;
    case(BackendDAE.SINGLEWHENEQUATION(vars=varIdc),_,_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then tmpVars;
    case(BackendDAE.SINGLEIFEQUATION(vars=varIdc),_,_)
      equation
        tmpVars = getVarsBySCC(component,incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then
        tmpVars;
    case(BackendDAE.TORNSYSTEM(tearingvars=varIdc),_,_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then
        tmpVars;
    else
      equation
        print("getUnsolvedVarsBySCC failed\n");
        then fail();
   end matchcontinue;
end getUnsolvedVarsBySCC;


protected function removeEventVars "removes EventVars from the varList.
author:Waurich TUD 2013-06"
  input list<Integer> eventVarLst;
  input list<tuple<Integer,Integer>> varLstIn;
  input Integer varIdx;
  output list<tuple<Integer,Integer>> varLstOut;
algorithm
  varLstOut := matchcontinue(eventVarLst,varLstIn,varIdx)
    local
      tuple<Integer,Integer> varTpl;
      list<tuple<Integer,Integer>> rest;
      list<tuple<Integer,Integer>> varLst;
      Integer var;
    case(_,_,_)
      equation
        true = intLe(varIdx,listLength(varLstIn));
        varTpl = listGet(varLstIn,varIdx);
        (var,_) = varTpl;
        true = List.isMemberOnTrue(var,eventVarLst,intEq);
        varLst = listDelete(varLstIn,varIdx-1);
        varLst = removeEventVars(eventVarLst,varLst,varIdx);
      then
        varLst;
    case(_,_,_)
      equation
        true = intLe(varIdx,listLength(varLstIn));
        varTpl = listGet(varLstIn,varIdx);
        (var,_) = varTpl;
        false = List.isMemberOnTrue(var,eventVarLst,intEq);
        varLst = removeEventVars(eventVarLst,varLstIn,varIdx+1);
      then
        varLst;
    else
      then
        varLstIn;
  end matchcontinue;
end removeEventVars;


protected function isTupleMember "author: marcusw
  Checks if the given variable (stored as tuple <id,state>) is part of the variable-list. This is only possible if the
  second tuple-argument is one - this means that the variable is not derived."
  input tuple<Integer,Integer> inTuple;
  input List<Integer> varIdc;
  output Boolean isNotMember;

protected
  Integer varIdx, varState;
  Boolean returnValue;

algorithm
  isNotMember := matchcontinue(inTuple, varIdc)
    case((varIdx,varState), _)
      equation
        true = intGt(varIdx,0);
        true = intEq(varState,1);
        returnValue = List.isMemberOnTrue(varIdx, varIdc, intEq);
      then not returnValue;
    else
      then true;
  end matchcontinue;
end isTupleMember;

//TODO: Maybe we can easily replace the tuple-notation with negativ and positiv integers.
protected function compareTupleByVarIdx "author: marcusw
  Checks if the given varIdx is the same as the first tuple-argument."
  input Integer varIdx;
  input tuple<Integer,Integer> var2Idx;
  output Boolean equal;

algorithm
  equal := match(varIdx,var2Idx)
    local
      Integer int1;
      Boolean result;
    case(_,(int1,_))
    then intEq(int1,varIdx);
  end match;
end compareTupleByVarIdx;


protected function getVarsBySCC "author: marcusw,waurich
  Returns all variables of all equations which are part of the component."
  input BackendDAE.StrongComponent component;
  input BackendDAE.IncidenceMatrix incidenceMatrix;
  output List<tuple<Integer,Integer>> vars;

algorithm
  vars := match(component, incidenceMatrix)
    local
      Integer eqnIdx; //For SINGLEEQUATION
      List<Integer> eqns; //For EQUATIONSYSTEM
      List<Integer> resEqns;
      List<tuple<Integer,Integer>> eqnVars;
      List<tuple<Integer,Integer>> eqnVarsCond;
      list<tuple<Integer,list<Integer>>> otherEqVars;
      String dumpStr;
      BackendDAE.StrongComponent condSys;
    case (BackendDAE.SINGLEEQUATION(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        _ = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then
        eqnVars;
    case (BackendDAE.EQUATIONSYSTEM(eqns=eqns),_)
      equation
        eqnVars = List.flatten(List.map1(eqns, getVarsByEqn, incidenceMatrix));
      then
        eqnVars;
    case (BackendDAE.MIXEDEQUATIONSYSTEM(disc_eqns=eqns, condSystem = condSys),_)
      equation
        //the when condition is a predecessor of the equation system. the affected equation is in the condSys
        eqnVars = List.flatten(List.map1(eqns, getVarsByEqn, incidenceMatrix));
        eqnVarsCond = getVarsBySCC(condSys,incidenceMatrix);
        eqnVars = listAppend(eqnVars,eqnVarsCond);
        eqnVars = List.unique(eqnVars);
      then
        eqnVars;
    case (BackendDAE.SINGLEARRAY(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        _ = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then
        eqnVars;
    case (BackendDAE.SINGLEALGORITHM(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        _ = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then
        eqnVars;
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        _ = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then
        eqnVars;
    case (BackendDAE.SINGLEWHENEQUATION(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        _ = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then
        eqnVars;
    case (BackendDAE.SINGLEIFEQUATION(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        _ = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then
        eqnVars;
    case (BackendDAE.TORNSYSTEM(residualequations=resEqns,otherEqnVarTpl = otherEqVars),_)
      equation
        eqns = List.map(otherEqVars,getTupleFirst);
        eqnVars = List.flatten(List.map1(listAppend(resEqns,eqns), getVarsByEqn, incidenceMatrix));
      then
        eqnVars;
    else
      equation
        print("Error in createTaskGraph1! Unsupported component-type \n");
      then fail();
  end match;
end getVarsBySCC;


protected function getTupleFirst "gets the first entry in tuple.
author: Waurich TUD 2013-06"
  input tuple<Integer,list<Integer>> tupleIn;
  output Integer tupOne;
algorithm
  (tupOne,_) := tupleIn;
end getTupleFirst;


public function tupleToString "author: marcusw
  Returns the given tuple as string."
  input tuple<Integer,Integer> inTuple;
  output String result;

algorithm
  result := match(inTuple)
    local
      Integer int1,int2;
    case((int1,int2))
    then ("(" +& intString(int1) +& "," +& intString(int2) +& ")");
  end match;
end tupleToString;

protected function tuple3ToString "author: marcusw
  Returns the given tuple as string."
  input tuple<Integer,Integer,Integer> inTuple;
  output String result;

algorithm
  result := match(inTuple)
    local
      Integer int1,int2,int3;
    case((int1,int2,int3))
    then ("(" +& intString(int1) +& "," +& intString(int2) +& "," +& intString(int3) +& ")");
  end match;
end tuple3ToString;

protected function getVarsByEqn "author: marcusw
  Returns all variables of the given equation."
  input Integer eqnIdx;
  input BackendDAE.IncidenceMatrix incidenceMatrix;
  output list<tuple<Integer,Integer>> vars_out;

protected
  list<Integer> equationVars;

algorithm
  equationVars := incidenceMatrix[eqnIdx];
  vars_out := List.map(equationVars, getVarTuple);
end getVarsByEqn;


protected function getVarTuple "author: marcusw
  Converts the given variable to tuple-notation.
  Example:  varIdx = -4 --> (4,0)
            varIdx = 5  --> (5,1)"
  input Integer varIdx;
  output tuple<Integer,Integer> outIdx; //variable index and variable state

algorithm
  outIdx := matchcontinue(varIdx)
    case(_)
      equation
        true = intLe(0,varIdx);
      then ((varIdx, 1));
    else
      then ((-varIdx,0));
   end matchcontinue;
end getVarTuple;

protected function compareIntTuple2 "author: marcusw
  Compares the two given tuples. The result is true if the first and second elements are equal."
  input tuple<Integer,Integer> tuple1;
  input tuple<Integer,Integer> tuple2;
  output Boolean equals;

algorithm
  equals := matchcontinue(tuple1,tuple2)
    local
      Integer int1,int2,int3,int4;
    case((int1,int2),(int3,int4))
      equation
        equality(int1 = int3);
        equality(int2 = int4);
      then true;
    else false;
 end matchcontinue;
end compareIntTuple2;

protected function getVarEqCompMapping "author: marcusw
  Create a mapping between variables / equations and strong-components. The returned array (one element for each variable) contains the
  scc-index which solves the variable."
  input BackendDAE.StrongComponents components;
  input Integer iEqSysIdx;
  input Integer iVarIdxOffset;
  input Integer iEqIdxOffset;
  input array<tuple<Integer,Integer,Integer>> ivarCompMapping;
  input array<tuple<Integer,Integer,Integer>> ieqCompMapping;
  output array<tuple<Integer,Integer,Integer>> ovarCompMapping;
  output array<tuple<Integer,Integer,Integer>> oeqCompMapping;
algorithm
  _ := List.fold4(components, getVarEqCompMapping0, ivarCompMapping, ieqCompMapping, iEqSysIdx, (iVarIdxOffset,iEqIdxOffset), 1);
  ovarCompMapping := ivarCompMapping;
  oeqCompMapping := ieqCompMapping;
end getVarEqCompMapping;


protected function getVarEqCompMapping0 "author: marcusw,waurich
  Updates all array elements which are solved in the given component. The array-elements will be set to iSccIdx."
  input BackendDAE.StrongComponent component;
  input array<tuple<Integer,Integer,Integer>> varCompMapping;
  input array<tuple<Integer,Integer,Integer>> eqCompMapping;
  input Integer iEqSysIdx;
  input tuple<Integer,Integer> iVarEqOffset; //a offset that should be added to the <varIdx,eqIdx>
  input Integer iSccIdx;
  output Integer oSccIdx;
algorithm
  oSccIdx := matchcontinue(component, varCompMapping, eqCompMapping, iEqSysIdx, iVarEqOffset, iSccIdx)
    local
      Integer compVarIdx, iVarOffset, iEqOffset, eq;
      list<Integer> compVarIdc,eqns,residuals,othereqs,othervars;
      array<tuple<Integer,Integer,Integer>> tmpvarCompMapping,tmpeqCompMapping;
      list<tuple<Integer,list<Integer>>> tearEqVarTpl;
      BackendDAE.StrongComponent condSys;
      String helperStr;
    case(BackendDAE.SINGLEEQUATION(var = compVarIdx, eqn = eq),_,_,_,(iVarOffset,iEqOffset),_)
      equation
        //print("HpcOmTaskGraph.getvarCompMapping0 for singleEquation varCompMapping-length:" +& intString(arrayLength(varCompMapping)) +& " varIdx: " +& intString(compVarIdx) +& " varOffset: " +& intString(iVarOffset) +& "\n");
        //print("HpcOmTaskGraph.getvarCompMapping0 for singleEquation eqCompMapping-length:" +& intString(arrayLength(eqCompMapping)) +& " eqIdx: " +& intString(eq) +& " eqOffset: " +& intString(iEqOffset) +& "\n");
        tmpvarCompMapping = arrayUpdate(varCompMapping,compVarIdx + iVarOffset,(iSccIdx,iEqSysIdx,iVarOffset));
        tmpeqCompMapping = arrayUpdate(eqCompMapping,eq + iEqOffset,(iSccIdx,iEqSysIdx,iEqOffset));
      then iSccIdx+1;
    case(BackendDAE.EQUATIONSYSTEM(vars = compVarIdc, eqns=eqns),_,_,_,(iVarOffset,iEqOffset),_)
      equation
        tmpvarCompMapping = List.fold3(compVarIdc,updateMappingTuple,iSccIdx,iEqSysIdx,iVarOffset,varCompMapping);
        tmpeqCompMapping = List.fold3(eqns,updateMappingTuple,iSccIdx,iEqSysIdx,iEqOffset,eqCompMapping);
      then
        iSccIdx+1;
    case(BackendDAE.MIXEDEQUATIONSYSTEM(condSystem = condSys, disc_vars = compVarIdc, disc_eqns = eqns),_,_,_,(iVarOffset,iEqOffset),_)
      equation
        tmpvarCompMapping = List.fold3(compVarIdc,updateMappingTuple,iSccIdx,iEqSysIdx,iVarOffset,varCompMapping);
        tmpeqCompMapping = List.fold3(eqns,updateMappingTuple,iSccIdx,iEqSysIdx,iEqOffset,eqCompMapping);
        //gets the whole equationsystem (necessary for the adjacencyList)
        _ = List.fold4({condSys}, getVarEqCompMapping0, tmpvarCompMapping,tmpeqCompMapping, iEqSysIdx, iVarEqOffset, iSccIdx);
      then
        iSccIdx+1;
    case(BackendDAE.SINGLEWHENEQUATION(vars = compVarIdc,eqn = eq),_,_,_,(iVarOffset,iEqOffset),_)
      equation
        tmpvarCompMapping = List.fold3(compVarIdc,updateMappingTuple,iSccIdx,iEqSysIdx,iVarOffset,varCompMapping);
        tmpeqCompMapping = arrayUpdate(eqCompMapping,eq + iEqOffset,(iSccIdx,iEqSysIdx,iEqOffset));
      then
        iSccIdx+1;
    case(BackendDAE.SINGLEARRAY(vars = compVarIdc, eqn = eq),_,_,_,(iVarOffset,iEqOffset),_)
      equation
        tmpvarCompMapping = List.fold3(compVarIdc,updateMappingTuple,iSccIdx,iEqSysIdx,iVarOffset,varCompMapping);
        tmpeqCompMapping = arrayUpdate(eqCompMapping,eq + iEqOffset,(iSccIdx,iEqSysIdx,iEqOffset));
      then
        iSccIdx+1;
    case(BackendDAE.SINGLEALGORITHM(vars = compVarIdc,eqn = eq),_,_,_,(iVarOffset,iEqOffset),_)
      equation
        tmpvarCompMapping = List.fold3(compVarIdc,updateMappingTuple,iSccIdx,iEqSysIdx,iVarOffset,varCompMapping);
        tmpeqCompMapping =arrayUpdate(eqCompMapping,eq + iEqOffset,(iSccIdx,iEqSysIdx,iEqOffset));
        then
          iSccIdx+1;
    case(BackendDAE.SINGLECOMPLEXEQUATION(vars = compVarIdc, eqn = eq),_,_,_,(iVarOffset,iEqOffset),_)
      equation
        tmpvarCompMapping = List.fold3(compVarIdc,updateMappingTuple,iSccIdx,iEqSysIdx,iVarOffset,varCompMapping);
        tmpeqCompMapping = arrayUpdate(eqCompMapping,eq + iEqOffset,(iSccIdx,iEqSysIdx,iEqOffset));
        then
          iSccIdx+1;
    case(BackendDAE.TORNSYSTEM(tearingvars = compVarIdc,residualequations = residuals, otherEqnVarTpl = tearEqVarTpl),_,_,_,(iVarOffset,iEqOffset),_)
      equation
      //print("test1\n");
      ((othereqs,othervars)) = List.fold(tearEqVarTpl,othersInTearComp,(({},{})));
      //print("test2\n");
      compVarIdc = listAppend(othervars,compVarIdc);
      //print("test3\n");
      eqns = listAppend(othereqs,residuals);
      //print("test4\n");
      tmpvarCompMapping = List.fold3(compVarIdc,updateMappingTuple,iSccIdx,iEqSysIdx,iVarOffset,varCompMapping);
      //print("test5\n");
      tmpeqCompMapping = List.fold3(eqns,updateMappingTuple,iSccIdx,iEqSysIdx,iEqOffset,eqCompMapping);
      then
        iSccIdx+1;
    case(BackendDAE.SINGLEIFEQUATION(vars = compVarIdc, eqn = eq),_,_,_,(iVarOffset,iEqOffset),_)
      equation
        tmpvarCompMapping = List.fold3(compVarIdc,updateMappingTuple,iSccIdx,iEqSysIdx,iVarOffset,varCompMapping);
        tmpeqCompMapping = arrayUpdate(eqCompMapping,eq + iEqOffset,(iSccIdx,iEqSysIdx,iEqOffset));
        then
          iSccIdx+1;
    else
      equation
        helperStr = BackendDump.strongComponentString(component);
        print("getVarEqCompMapping0 - Unsupported component-type:\n" +& helperStr +& "\n");
      then fail();
  end matchcontinue;
end getVarEqCompMapping0;

public function getSccNodeMapping "author: marcusw
  Create a mapping between the strong components and the graph nodes"
  input Integer iNumberOfSccs;
  input TaskGraphMeta iTaskGraphMeta;
  output array<Integer> oMapping; //each scc (arrayIdx) is mapped to exactly one node (value)
protected
  array<Integer> tmpMappingArray;
  array<list<Integer>> inComps;
  array<Integer> nodeMark;
algorithm
  tmpMappingArray := arrayCreate(iNumberOfSccs,-1);
  TASKGRAPHMETA(inComps=inComps,nodeMark=nodeMark) := iTaskGraphMeta;
  ((oMapping,_)) := Util.arrayFold1(inComps, getSccNodeMapping0, nodeMark, (tmpMappingArray,1));
end getSccNodeMapping;

protected function getSccNodeMapping0 "author: marcusw
  Set all array entries of the given scc-list to the node-idx"
  input list<Integer> iCompsOfNode;
  input array<Integer> iNodeMarks;
  input tuple<array<Integer>, Integer> iArrayNodeIdx;
  output tuple<array<Integer>, Integer> oArrayNodeIdx;
protected
  array<Integer> tmpMappingArray;
  Integer nodeIdx;
algorithm
  ((tmpMappingArray,nodeIdx)) := List.fold1(iCompsOfNode, getSccNodeMapping1, iNodeMarks, iArrayNodeIdx);
  oArrayNodeIdx := (tmpMappingArray,nodeIdx+1);
end getSccNodeMapping0;

protected function getSccNodeMapping1 "author: marcusw
  Set all array entries of the given scc-list to the node-idx"
  input Integer iCompIdx;
  input array<Integer> iNodeMark;
  input tuple<array<Integer>, Integer> iArrayNodeIdx;
  output tuple<array<Integer>, Integer> oArrayNodeIdx;
protected
  Integer iNodeIdx;
  Integer offset;
  Integer nodeMark;
  array<Integer> iMappingArray;
algorithm
  oArrayNodeIdx := matchcontinue(iCompIdx,iNodeMark,iArrayNodeIdx)
    case(_,_,(iMappingArray,iNodeIdx))
      equation
        nodeMark = arrayGet(iNodeMark,iCompIdx);
        true = intNe(-1,nodeMark);
        iMappingArray = arrayUpdate(iMappingArray, iCompIdx, iNodeIdx);
      then ((iMappingArray,iNodeIdx));
    case(_,_,(iMappingArray,iNodeIdx))
      then ((iMappingArray,iNodeIdx));
  end matchcontinue;
end getSccNodeMapping1;

protected function othersInTearComp " gets the remaining algebraic vars and equations from the torn block.
Remark: there can be more than 1 var per equation.
author:Waurich TUD 2013-06"
  input tuple<Integer,list<Integer>> otherEqnVarTpl;
  input tuple<list<Integer>,list<Integer>> othersIn;
  output tuple<list<Integer>,list<Integer>> othersOut;
algorithm
  othersOut := matchcontinue(otherEqnVarTpl,othersIn)
    local
      Integer eq;
      Integer var;
      list<Integer> eqLst;
      list<Integer> varTplLst;
      list<Integer> varLst;
    case(_,_)
      equation
      (eq,varTplLst)=otherEqnVarTpl;
      _ = listGet(varTplLst,1);
      (eqLst,varLst) = othersIn;
      varLst = listAppend(varTplLst,varLst);
      eqLst = eq::eqLst;
      then
        ((eqLst,varLst));
    else
      equation
      print("check number of vars in relation to number of eqs in otherEqnVarTpl in the torn system\n");
      then
        fail();
  end matchcontinue;
end othersInTearComp;


protected function updateMapping
  input Integer varIdx;
  input Integer sccIdx;
  input array<Integer> iMapping;
  output array<Integer> oMapping;
algorithm
  oMapping := arrayUpdate(iMapping,varIdx,sccIdx);
end updateMapping;

protected function updateMappingTuple
  input Integer varIdx;
  input Integer sccIdx;
  input Integer iEqSysIdx;
  input Integer iVarOffset; //a offset that should be added to the varIdx
  input array<tuple<Integer,Integer,Integer>> iMapping;
  output array<tuple<Integer,Integer,Integer>> oMapping;
algorithm
  oMapping := arrayUpdate(iMapping,varIdx+iVarOffset,(sccIdx,iEqSysIdx,iVarOffset));
end updateMappingTuple;


//functions to get the ODEsystem graph and adjacencyList
//------------------------------------------
//------------------------------------------

public function getOdeSystem "gets the graph and the adjacencyLst only for the ODEsystem. the der(states) and nodes that evaluate zerocrossings are the only branches of the task graph
attention: This function will overwrite the values of graphIn and graphDataIn with new values. If you want to hold the values of graphIn and graphDataIn, you have to duplicate them first!
author: Waurich TUD 2013-06"
  input TaskGraph graphIn;
  input TaskGraphMeta graphDataIn;
  input BackendDAE.BackendDAE systIn;
  output TaskGraph graphOdeOut;
  output TaskGraphMeta graphDataOdeOut;
protected
  list<BackendDAE.Var> varLst;
  list<Integer> statevarindx_lst, stateVars, stateNodes, whenNodes, whenChildren, cutNodes, cutNodeChildren;
  array<tuple<Integer, Integer, Integer>> varCompMapping, eqCompMapping;
  array<list<Integer>> inComps;
  String fileName;
  BackendDAE.Variables orderedVars;
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
  TaskGraph graphTmp;
  TaskGraphMeta graphDataTmp;
algorithm
  TASKGRAPHMETA(varCompMapping=varCompMapping, eqCompMapping=eqCompMapping, inComps=inComps) := graphDataIn;
  BackendDAE.DAE(systs,shared) := systIn;
  ((stateNodes,_)) := List.fold2(systs,getAllStateNodes,varCompMapping,inComps,({},0));
  whenNodes := getEventNodes(systIn,eqCompMapping);
  graphTmp := graphIn; //arrayCopy(graphIn);
  (graphTmp,cutNodes) := cutTaskGraph(graphTmp,stateNodes,whenNodes,{});
  cutNodeChildren := List.flatten(List.map1(listAppend(cutNodes,whenNodes),Util.arrayGetIndexFirst,graphIn)); // for computing new root-nodes when cutting out when-equations
  (_,cutNodeChildren,_) := List.intersection1OnTrue(cutNodeChildren,cutNodes,intEq);
  graphDataOdeOut := getOdeSystemData(graphDataIn,listAppend(cutNodes,whenNodes),cutNodeChildren);
  graphOdeOut := graphTmp;
end getOdeSystem;


protected function getAllStateNodes "folding function for getOdeSystem to traverse the equationsystems in the BackendDAE.
author: Waurich TUD 2013-07"
  input BackendDAE.EqSystem systIn;
  input array<tuple<Integer, Integer, Integer>> varCompMapping;
  input array<list<Integer>> inComps;
  input tuple<list<Integer>,Integer> stateInfoIn;
  output tuple<list<Integer>,Integer> stateInfoOut;
algorithm
  stateInfoOut := matchcontinue(systIn,varCompMapping,inComps,stateInfoIn)
    local
      list<Integer> stateNodes, stateNodesIn, stateVars;
      Integer varOffset, varOffsetNew;
      BackendDAE.Variables orderedVars;
      list<BackendDAE.Var> varLst;
  case(_,_,_,((stateNodesIn,varOffset)))
    equation
      BackendDAE.EQSYSTEM(orderedVars=orderedVars) = systIn;
      varLst = BackendVariable.varList(orderedVars);
      stateVars = getStates(varLst,{},1);
      //print("stateVars: " +& stringDelimitList(List.map(stateVars,intString),",") +& " varOffset: " +& intString(varOffset) +& "\n");
      //print("varCompMapping: " +& stringDelimitList(arrayList(Util.arrayMap(varCompMapping,tuple3ToString)),",") +& "\n");
      true = List.isNotEmpty(stateVars);
      stateVars = List.map1(stateVars,intAdd,varOffset);
      stateNodes = getArrayTuple31(stateVars,varCompMapping);
      //print("stateNodes: " +& stringDelimitList(List.map(stateNodes,intString),",") +& "\n");
      stateNodes = List.map3(stateNodes,getCompInComps,1,inComps,arrayCreate(arrayLength(inComps),0));
      stateNodes = listAppend(stateNodesIn,stateNodes);
      varOffsetNew = listLength(varLst)+varOffset;
    then
      ((stateNodes,varOffsetNew));
  case(_,_,_,(stateNodesIn,varOffset))
    equation
      BackendDAE.EQSYSTEM(orderedVars=orderedVars) = systIn;
      varLst = BackendVariable.varList(orderedVars);
      stateVars = getStates(varLst,{},1);
      true = List.isEmpty(stateVars);
      varOffsetNew = listLength(varLst)+varOffset;
      then
        ((stateNodesIn,varOffsetNew));
  case(_,_,_,(_,_))
    equation
      BackendDAE.EQSYSTEM(orderedVars=orderedVars) = systIn;
      varLst = BackendVariable.varList(orderedVars);
      stateVars = getStates(varLst,{},1);
      print("getAllStateNodes failed! StateVars-Count: " +& intString(listLength(stateVars)) +& "\n");
     then fail();
  end matchcontinue;
end getAllStateNodes;


protected function getStates "gets the stateVars from the list of vars.
author:Waurich TUD 2013-06"
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> stateVarsIn;
  input Integer Idx;
  output list<Integer> stateVarsOut;
algorithm
  stateVarsOut := matchcontinue(inVarLst,stateVarsIn,Idx)
    local
      BackendDAE.Var head;
      list<BackendDAE.Var> rest;
      list<Integer> stateVars;
    case((head::rest),_,_)
      equation
        false = BackendVariable.isStateVar(head);
        stateVars = getStates(rest,stateVarsIn,Idx+1);
      then
        stateVars;
    case((head::rest),_,_)
      equation
        true = BackendVariable.isStateVar(head);
        stateVars = getStates(rest,Idx::stateVarsIn,Idx+1);
      then
        stateVars;
    case({},_,_)
      then
        stateVarsIn;
   end matchcontinue;
 end getStates;


protected function cutTaskGraph "cuts every branch of the taskgraph that leads not to exceptNode.
author:Waurich TUD 2013-06"
  input TaskGraph graphIn;
  input list<Integer> stateNodes;
  input list<Integer> eventNodes;
  input list<Integer> deleteNodes;
  output TaskGraph graphOut;
  output list<Integer> cutNodesOut;
algorithm
  (graphOut,cutNodesOut) := matchcontinue(graphIn,stateNodes,eventNodes,deleteNodes)
    local
      list<Integer> cutNodes;
      list<Integer> deleteNodesTmp;
      list<Integer> noChildren;
      array<list<Integer>> graphTmp;
      list<list<Integer>> graphTmpLst;
    case(_,_,_,_)
      equation
        // remove the algebraic branches
        noChildren = getLeaves(graphIn,{},1);
        (_,cutNodes,_) = List.intersection1OnTrue(noChildren,listAppend(stateNodes,deleteNodes),intEq);
        deleteNodesTmp = listAppend(cutNodes,deleteNodes);
        false = List.isEmpty(cutNodes);
        //print("pre cut\n");
        //printTaskGraph(graphIn);
        graphTmp = removeEntriesInGraph(graphIn,cutNodes);
        (graphTmp,deleteNodesTmp) = cutTaskGraph(graphTmp,stateNodes,eventNodes,deleteNodesTmp);
        //print("post cut\n");
        //printTaskGraph(graphTmp);
         then
           (graphTmp,deleteNodesTmp);
    case(_,_,_,_)
      equation
        noChildren = getLeaves(graphIn,{},1);
        (_,cutNodes,_) = List.intersection1OnTrue(noChildren,listAppend(stateNodes,deleteNodes),intEq);
        true = List.isEmpty(cutNodes);
        //print("pre cut\n");
        //print("cutting nodes: " +& stringDelimitList(List.map(eventNodes,intString),",") +& "\n");
        //printTaskGraph(graphIn);
        graphTmp = removeEntriesInGraph(graphIn,eventNodes);
        graphTmpLst = arrayList(graphIn);
        graphTmpLst = List.map1(graphTmpLst,updateContinuousEntriesInList,List.unique(listAppend(deleteNodes,eventNodes)));
        graphTmp = listArray(graphTmpLst);
        (graphTmp,_) = deleteRowInAdjLst(graphTmp,List.unique(listAppend(deleteNodes,eventNodes)));
        //print("post cut\n");
        //printTaskGraph(graphTmp);
         then
           (graphTmp,deleteNodes);
  end matchcontinue;
end cutTaskGraph;


protected function getOdeSystemData "updates the taskGraphMetaData for the ode system.
author:Waurich TUD 2013-07"
  input TaskGraphMeta graphDataIn;
  input list<Integer> cutNodes;
  input list<Integer> cutNodeChildren;
  output TaskGraphMeta graphDataOut;
protected
  array<list<Integer>> inComps;
  array<tuple<Integer, Integer, Integer>> varCompMapping;
  array<tuple<Integer, Integer, Integer>> eqCompMapping;
  list<Integer> rootNodes;
  array<String> nodeNames;
  array<String> nodeDescs;
  array<tuple<Integer,Real>> exeCosts;
  array<list<tuple<Integer,Integer,Integer>>> commCosts;
  array<Integer>nodeMark;
  list<Integer> rangeLst;
algorithm
  TASKGRAPHMETA(inComps = inComps, varCompMapping=varCompMapping, eqCompMapping=eqCompMapping, rootNodes = rootNodes, nodeNames =nodeNames, nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) := graphDataIn;
  inComps := listArray(List.deletePositions(arrayList(inComps),List.map1(cutNodes,intSub,1)));
  //varCompMapping := removeContinuousEntriesTuple(varCompMapping,cutNodes);
  //eqCompMapping := removeContinuousEntriesTuple(eqCompMapping,cutNodes);
  //(_,rootNodes,_) := List.intersection1OnTrue(rootNodes,cutNodes,intEq); //TODO:  this has to be updated(When cutting out When-nodes new roots arise) DONE!
  rootNodes := listAppend(rootNodes,cutNodeChildren);
  rootNodes := arrayList(removeContinuousEntries(listArray(rootNodes),cutNodes));
  rootNodes := List.removeOnTrue(-1, intEq, rootNodes);
  rangeLst := List.intRange(arrayLength(nodeMark));
  nodeMark := List.fold1(rangeLst, markRemovedNodes,cutNodes,nodeMark);
  graphDataOut :=TASKGRAPHMETA(inComps,varCompMapping,eqCompMapping,rootNodes,nodeNames,nodeDescs,exeCosts,commCosts,nodeMark);
end getOdeSystemData;


protected function markRemovedNodes " folding function to set the entries in nodeMark to -1 for a removed component
author:Waurich TUD 2013-07"
  input Integer nodeMarkIdx;
  input list<Integer> removedNodes;
  input array<Integer> nodeMarkIn;
  output array<Integer> nodeMarkOut;
algorithm
  nodeMarkOut := matchcontinue(nodeMarkIdx,removedNodes,nodeMarkIn)
    local
      array<Integer> nodeMarkTmp;
  case(_,_,_)
    equation
      false = List.isMemberOnTrue(nodeMarkIdx,removedNodes,intEq);
    then
      nodeMarkIn;
  case(_,_,_)
    equation
      true = List.isMemberOnTrue(nodeMarkIdx,removedNodes,intEq);
      nodeMarkTmp = Util.arrayReplaceAtWithFill(nodeMarkIdx,-1,999,nodeMarkIn);
    then
      nodeMarkTmp;
  end matchcontinue;
end markRemovedNodes;


public function getCompInComps "finds the node in the current task graph which contains that component(index from the original task graph). nodeMark is needed to check for deleted components
author: Waurich TUD 2013-07"
  input Integer compIn;
  input Integer compIdx;  // start idx for iteration
  input array<list<Integer>> inComps;
  input array<Integer> nodeMark;
  output Integer compOut;
algorithm
  compOut := matchcontinue(compIn,compIdx,inComps, nodeMark)
    local
      list<Integer> mergedComp;
      Integer compTmp;
      Integer nodeMarkEntry;
    case(_,_,_,_)
      equation
        true = arrayLength(inComps) >= compIdx;
        mergedComp = arrayGet(inComps,compIdx);
        //print("get comp for compIn "+&intString(compIn)+&" in the merged Comp "+& stringDelimitList(List.map(mergedComp,intString),",")+&"\n");
        false = List.isMemberOnTrue(compIn,mergedComp,intEq);
        compTmp = getCompInComps(compIn,compIdx+1,inComps,nodeMark);
      then
        compTmp;
    case(_,_,_,_)
      equation
        true = arrayLength(inComps) >= compIdx;
        mergedComp = arrayGet(inComps,compIdx);
        //print("get comp for compIn "+&intString(compIn)+&" in the merged Comp "+& stringDelimitList(List.map(mergedComp,intString),",")+&"\n");
        true = List.isMemberOnTrue(compIn,mergedComp,intEq);
      then
        compIdx;
    case(_,_,_,_)
      equation
        nodeMarkEntry = arrayGet(nodeMark,compIn);
        true = intEq(nodeMarkEntry,-1);
      then
        -1;
    else
      equation
        print("getCompInComps failed! CompIn idx: " +& intString(compIn) +& " | Component array-size: " +& intString(arrayLength(inComps)) +& "\n");
      then
        fail();
  end matchcontinue;
end getCompInComps;


public function getChildNodes "gets the successor nodes for a list of parent nodes.
author: waurich TUD 2013-06"
  input array<list<Integer>> adjacencyLstIn;
  input list<Integer> parents;
  input list<Integer> childLstTmp;
  input Integer Idx;
  output list<Integer> childLsts;
algorithm
  childLsts := matchcontinue(adjacencyLstIn,parents,childLstTmp,Idx)
    local
      Integer parent;
      list<Integer> row;
      list<Integer> childLst;
    case(_,_,_,_)
      equation
        true = listLength(parents) >= Idx;
        parent = listGet(parents,Idx);
        row = arrayGet(adjacencyLstIn,parent);
        childLst = listAppend(childLstTmp,row);
        childLst = getChildNodes(adjacencyLstIn,parents,childLst,Idx+1);
      then
        childLst;
    else
      then
        childLstTmp;
  end matchcontinue;
end getChildNodes;


protected function updateContinuousEntriesInList" updates the entries in a list
the entries in the list belong to a continuous series.
the deleteEntries have been previously removed from the array and the indices are adapted so that the new array consists again of continuous series of numbers.therefore the indices have to be smallen
e.g. updateContinuousEntriesInList({4,2,1,7,9},{3,6}) = {3,2,1,5,7};
author: Waurich TUD 2013-07"
  input list<Integer> lstIn;
  input list<Integer> deleteEntriesIn;
  output list<Integer> lstOut;
protected
  list<Integer> deleteEntries;
  array<Integer> lstArray;
  array<Integer> lstArrayTmp;
  list<Integer> lstTmp;
algorithm
  deleteEntries := List.sort(deleteEntriesIn,intLt);
  lstArray := listArray(lstIn);
  lstArrayTmp := Util.arrayMap1(lstArray,removeContinuousEntries1,deleteEntries);
  lstOut := arrayList(lstArrayTmp);
end updateContinuousEntriesInList;

protected function removeContinuousEntries " updates the entries.
the entries in the array belong to a continuous series. (all numbers from 1 to max(array) belong to the array).
the deleteEntries are removed from the array and the indices are adapted so that the new array consists againn of continuous series of numbers.
e.g. removeContinuousEntries([4,6,2,3,1,7,5],{3,6}) = [3,-1,2,-1,1,5,4];
REMARK : does not shorten the array, but sets deleted entries to -1 TODO: change this
author: Waurich TUD 2013-07"
  input array<Integer> arrayIn;
  input list<Integer> deleteEntriesIn;
  output array<Integer> arrayOut;
protected
  list<Integer> deleteEntries;
  array<Integer> arrayTmp;
algorithm
  arrayTmp := Util.arrayMap1(arrayIn,invalidateEntry,deleteEntriesIn);
  deleteEntries := List.sort(deleteEntriesIn,intLt);
  arrayOut := Util.arrayMap1(arrayTmp,removeContinuousEntries1,deleteEntries);
end removeContinuousEntries;

protected function removeContinuousEntriesTuple " updates the entries.
the entries in the array belong to a continuous series. (all numbers from 1 to max(array) belong to the array).
the deleteEntries are removed from the array and the indices are adapted so that the new array consists againn of continuous series of numbers.
e.g. removeContinuousEntries([4,6,2,3,1,7,5],{3,6}) = [3,-1,2,-1,1,5,4];
REMARK : does not shorten the array, but sets deleted entries to -1 TODO: change this
author: Waurich TUD 2013-07"
  input array<tuple<Integer, Integer, Integer>> arrayIn;
  input list<Integer> deleteEntriesIn;
  output array<tuple<Integer, Integer, Integer>> arrayOut;
protected
  list<Integer> deleteEntries;
  array<tuple<Integer, Integer, Integer>> arrayTmp;
algorithm
  arrayTmp := Util.arrayMap1(arrayIn,invalidateEntryTuple,deleteEntriesIn);
  deleteEntries := List.sort(deleteEntriesIn,intLt);
  arrayOut := Util.arrayMap1(arrayTmp,removeContinuousEntriesTuple1,deleteEntries);
end removeContinuousEntriesTuple;

protected function invalidateEntry " map function that sets the entryOut -1 if entryIn is member of lstIn.
author: Waurich TUD 2013-07"
  input Integer entryIn;
  input list<Integer> lstIn;
  output Integer entryOut;
algorithm
  entryOut := matchcontinue(entryIn,lstIn)
    local
    case(_,_)
      equation
        false = List.isMemberOnTrue(entryIn,lstIn,intEq);
      then
        entryIn;
    case(_,_)
      equation
        //true = List.isMemberOnTrue(entryIn,lstIn,intEq);
      then
        -1;
  end matchcontinue;
end invalidateEntry;

protected function invalidateEntryTuple " map function that sets the entryOut -1 if entryIn is member of lstIn.
author: Waurich TUD 2013-07"
  input tuple<Integer,Integer,Integer> entryTplIn;
  input list<Integer> lstIn;
  output tuple<Integer,Integer,Integer> entryTplOut;
protected
  Integer entryIn, eqSysIdx, entryOffset;
algorithm
  entryTplOut := matchcontinue(entryTplIn,lstIn)
    local
    case((entryIn,_,_),_)
      equation
        false = List.isMemberOnTrue(entryIn,lstIn,intEq);
      then
        entryTplIn;
    case((_,eqSysIdx,entryOffset),_)
      equation
        //true = List.isMemberOnTrue(entryIn,lstIn,intEq);
      then
        ((-1,eqSysIdx,entryOffset));
  end matchcontinue;
end invalidateEntryTuple;


protected function removeContinuousEntries1" map function for removeContinuousEntries to update the indices.
author:Waurich TUD 2013-07."
  input Integer entryIn;
  input list<Integer> deleteEntriesIn;
  output Integer entryOut;
protected
  Integer eqSysIdx, entryOffset;
algorithm
  entryOut := matchcontinue(entryIn,deleteEntriesIn)
  local
    Integer offset;
    Integer entry;
  case(_,_)
    equation
      entry = List.getMemberOnTrue(entryIn,deleteEntriesIn,intGe);
      offset = listLength(deleteEntriesIn)-List.position(entry,deleteEntriesIn);
      entry = entryIn-offset;
    then entry;
  else
    equation
    then entryIn;
  end matchcontinue;
end removeContinuousEntries1;

protected function removeContinuousEntriesTuple1" map function for removeContinuousEntries to update the indices.
author:Waurich TUD 2013-07."
  input tuple<Integer,Integer,Integer> entryTplIn;
  input list<Integer> deleteEntriesIn;
  output tuple<Integer,Integer,Integer> entryTplOut;
protected
  Integer entryIn, eqSysIdx, entryOffset;
algorithm
  entryTplOut := matchcontinue(entryTplIn,deleteEntriesIn)
  local
    Integer offset;
    Integer entry;
  case((entryIn,eqSysIdx,entryOffset),_)
    equation
      entry = List.getMemberOnTrue(entryIn,deleteEntriesIn,intGe);
      offset = listLength(deleteEntriesIn)-List.position(entry,deleteEntriesIn);
      entry = entryIn-offset;
    then
      ((entry,eqSysIdx,entryOffset));
  else
    equation
    then
      entryTplIn;
  end matchcontinue;
end removeContinuousEntriesTuple1;


public function removeEntriesInGraph "deletes given entries from adjacencyLst.
  author: Waurich TUD 2013-06"
  input array<list<Integer>> inArray;
  input list<Integer> noStates;
  output array<list<Integer>> outArray;
algorithm
  outArray := match(inArray,noStates)
  local
    Integer head;
    list<Integer> rest;
    array<list<Integer>> ArrayTmp;
  case(_,{})
    equation
    then
      inArray;
  case(_,(head::rest))
    equation
      ArrayTmp = removeEntryFromArray(inArray,head,1);
      ArrayTmp = removeEntriesInGraph(ArrayTmp,rest);
    then
      ArrayTmp;
  end match;
end removeEntriesInGraph;


protected function removeEntryFromArray " removes a single entry in the list<Integer> from an array<list<Integer>>. starts with indexed row.
  author: Waurich 2013-06"
  input array<list<Integer>> inArray;
  input Integer entry;
  input Integer indx;
  output array<list<Integer>> outArray;
algorithm
  outArray := matchcontinue(inArray,entry,indx)
  local
    Integer size;
    list<Integer> row;
    array<list<Integer>> ArrayTmp;
  case(_,_,_)
  equation
    size = arrayLength(inArray);
    true = indx>size;
  then inArray;
  case(_,_,_)
    equation
      size = arrayLength(inArray);
      true = indx <= size;
      row = arrayGet(inArray,indx);
      row = List.deleteMember(row,entry);
      ArrayTmp = Util.arrayReplaceAtWithFill(indx,row,row,inArray);
    then removeEntryFromArray(ArrayTmp,entry,indx+1);
  end matchcontinue;
end removeEntryFromArray;


protected function deleteRowInAdjLst "deletes rows indexed by the rowDel from the adjacencyLst.
author:waurich TUD 2013 - 06"
  input array<list<Integer>> adjacencyLstIn;
  input list<Integer> rowsDel;
  output array<list<Integer>> adjacencyLstOut;
  output list<Integer> odeMapping;
protected
  array<list<Integer>> adjLst;
  list<Integer> copiedRows;
  list<Integer> rowsDel1;
  Integer size;
algorithm
  size := arrayLength(adjacencyLstIn)-listLength(rowsDel);
  adjLst := arrayCreate(size,{});
  copiedRows := List.intRange(arrayLength(adjacencyLstIn));
  rowsDel1 := List.map1(rowsDel,intSub,1);
  copiedRows := List.deletePositions(copiedRows,rowsDel1);
  adjacencyLstOut := arrayCopyRows(adjacencyLstIn,adjLst,copiedRows,1);
  odeMapping := copiedRows;
end deleteRowInAdjLst;


protected function arrayCopyRows "copies entries given by copiedRows from inArray to newArray"
  input array<list<Integer>> inArray;
  input array<list<Integer>> newArray;
  input list<Integer> copiedRows;
  input Integer Idx;
  output array<list<Integer>> outArray;
algorithm
  outArray := matchcontinue(inArray,newArray,copiedRows,Idx)
    local
      Integer head;
      Integer copyRow;
      list<Integer> rest;
      list<Integer> row;
      array<list<Integer>> arrayTmp;
    case(_,_,_,_)
      equation
        true = listLength(copiedRows) >= Idx;
        copyRow = listGet(copiedRows,Idx);
        row = arrayGet(inArray,copyRow);
        arrayTmp = Util.arrayReplaceAtWithFill(Idx, row, {111,222}, newArray);
        arrayTmp = arrayCopyRows(inArray,arrayTmp,copiedRows,Idx+1);
      then
        arrayTmp;
    else
      equation
      then
        newArray;
  end matchcontinue;
end arrayCopyRows;

public function getLeafNodes "function getLeafNodes
  author: marcusw
  Get all leave-nodes of the given graph."
  input TaskGraph iTaskGraph;
  output List<Integer> oLeaveNodes;
algorithm
  oLeaveNodes := getLeaves(iTaskGraph,{},1);
end getLeafNodes;

protected function getLeaves "gets the end of the branches i.e. a node with no successors(no entries in the adjacencyList)
author:Waurich TUD 2013-06"
  input array<list<Integer>> adjacencyLstIn;
  input list<Integer> noChildrenIn;
  input Integer rowIdx;
  output list<Integer> noChildrenOut;
algorithm
  noChildrenOut := matchcontinue(adjacencyLstIn,noChildrenIn,rowIdx)
    local
      list<Integer> row;
      list<Integer> noChildren;
    case(_,_,_)
      equation
        true = arrayLength(adjacencyLstIn) >= rowIdx;
        row = arrayGet(adjacencyLstIn,rowIdx);
        true = List.isEmpty(row);
        noChildren = getLeaves(adjacencyLstIn,rowIdx::noChildrenIn,rowIdx+1);
        then
          noChildren;
    case(_,_,_)
      equation
        // check for tornsystems (self-loops)

        true = arrayLength(adjacencyLstIn) >= rowIdx;
        row = arrayGet(adjacencyLstIn,rowIdx);
        true = listLength(row) == 1;
        true = listGet(row,1) == rowIdx;
        noChildren = getLeaves(adjacencyLstIn,rowIdx::noChildrenIn,rowIdx+1);
        then
          noChildren;
    case(_,_,_)
      equation
        true = arrayLength(adjacencyLstIn) >= rowIdx;
        row = arrayGet(adjacencyLstIn,rowIdx);
        false = List.isEmpty(row);
        noChildren = getLeaves(adjacencyLstIn,noChildrenIn,rowIdx+1);
        then
          noChildren;
    case(_,_,_)
      equation
        true = arrayLength(adjacencyLstIn) < rowIdx;
      then
        noChildrenIn;
  end matchcontinue;
end getLeaves;

//Functions to get the event-graph
//------------------------------------------
//------------------------------------------
public function getEventSystem "gets the graph and the adjacencyLst only for the EventSystem. This means that all branches which leads to a node solving
a whencondition or another boolean condition will remain.
author: marcusw"
  input TaskGraph iTaskGraph;
  input TaskGraphMeta iTaskGraphMeta;
  input BackendDAE.BackendDAE iSyst;
  input list<BackendDAE.ZeroCrossing> iZeroCrossings;
  input array<Integer> iSimCodeEqCompMapping;
  output TaskGraph oTaskGraph;
  output TaskGraphMeta oTaskGraphMeta;
protected
  array<tuple<Integer, Integer, Integer>> varCompMapping, eqCompMapping;
  array<list<Integer>> inComps;
  list<Integer> discreteNodes, cutNodes, cutNodeChildren, zeroCrossingNodes;
  list<Integer> sccsContainingTime;
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
  TaskGraph graphTmp;
  TaskGraphMeta graphDataTmp;
algorithm
  TASKGRAPHMETA(varCompMapping=varCompMapping, eqCompMapping=eqCompMapping, inComps=inComps) := iTaskGraphMeta;
  BackendDAE.DAE(systs,shared) := iSyst;
  discreteNodes := getDiscreteNodes(iSyst,eqCompMapping);
  zeroCrossingNodes := List.flatten(List.map1(iZeroCrossings, getComponentsOfZeroCrossing, iSimCodeEqCompMapping));
  ((_,sccsContainingTime)) := List.fold1(systs, getComponentsIncludingTime, eqCompMapping, (0,{}));
  //print("Nodes containing time as variable: " +& stringDelimitList(List.map(sccsContainingTime, intString), ",") +& " (len: " +& intString(listLength(sccsContainingTime)) +& ")\n");
  discreteNodes := listAppend(discreteNodes, sccsContainingTime);
  discreteNodes := listAppend(discreteNodes, zeroCrossingNodes);
  discreteNodes := List.unique(discreteNodes);
  //print("Discrete nodes: " +& stringDelimitList(List.map(discreteNodes, intString), ",") +& " (len: " +& intString(listLength(discreteNodes)) +& ")\n");
  graphTmp := iTaskGraph; //arrayCopy(graphIn);
  (graphTmp,cutNodes) := cutTaskGraph(graphTmp,discreteNodes,{},{});
  cutNodeChildren := List.flatten(List.map1(cutNodes,Util.arrayGetIndexFirst,iTaskGraph)); // for computing new root-nodes when cutting out nodes
  (_,cutNodeChildren,_) := List.intersection1OnTrue(cutNodeChildren,cutNodes,intEq);
  oTaskGraphMeta := getOdeSystemData(iTaskGraphMeta,cutNodes,cutNodeChildren);
  oTaskGraph := graphTmp;
end getEventSystem;

protected function getComponentsOfZeroCrossing
  input BackendDAE.ZeroCrossing iZeroCrossing;
  input array<Integer> iSimCodeEqCompMapping;
  output list<Integer> oCompIdc;
protected
  list<Integer> occurEquLst, tmpCompIdc;
  Integer sccIdx;
algorithm
  oCompIdc := match(iZeroCrossing, iSimCodeEqCompMapping)
    case(BackendDAE.ZERO_CROSSING(occurEquLst=occurEquLst), _)
      equation
        sccIdx = arrayGet(iSimCodeEqCompMapping, List.first(occurEquLst));
        //print("Equations of zero crossing: " +& stringDelimitList(List.map(occurEquLst, intString), ",") +& "\n");
        //print("SCCs of zero crossing: " +& intString(sccIdx) +& "\n");
        tmpCompIdc = List.map1(occurEquLst, Util.arrayGetIndexFirst, iSimCodeEqCompMapping);
      then tmpCompIdc;
    else then {};
  end match;
end getComponentsOfZeroCrossing;


protected function getComponentsIncludingTime "get the scc-idc that have an equation containing 'time' as variable
author: marcusw"
  input BackendDAE.EqSystem iSystem;
  input array<tuple<Integer,Integer,Integer>> iEqCompMapping;
  input tuple<Integer,list<Integer>> iOffsetResList; //<offset, resultList>
  output tuple<Integer,list<Integer>> oOffsetResList;
protected
  BackendDAE.EquationArray orderedEqs;
  Integer offset;
  list<Integer> resultList;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs=orderedEqs) := iSystem;
  (offset, resultList) := iOffsetResList;
  ((offset, resultList, _, _)) := BackendEquation.traverseBackendDAEEqns(orderedEqs, getComponentsIncludingTime0, (offset, resultList, iEqCompMapping, 1));
  oOffsetResList := (offset, resultList);
end getComponentsIncludingTime;

protected function getComponentsIncludingTime0 "get the scc-idc that have an equation containing 'time' as variable
author: marcusw"
  input tuple<BackendDAE.Equation,tuple<Integer, list<Integer>, array<tuple<Integer,Integer,Integer>>, Integer>> iOffsetResList; //<equation, <offset, resultList, eqCompMapping, eqIdx>>
  output tuple<BackendDAE.Equation,tuple<Integer, list<Integer>, array<tuple<Integer,Integer,Integer>>, Integer>> oOffsetResList;
protected
  BackendDAE.Equation eq;
  Integer offset, eqIdx, sccIdx;
  list<Integer> resultList;
  array<tuple<Integer, Integer, Integer>> eqCompMapping;
  Boolean timeIsPartOfEquation;
algorithm
  oOffsetResList := matchcontinue(iOffsetResList)
    case((eq, (offset,resultList,eqCompMapping,eqIdx)))
      equation
        ((sccIdx,_,_)) = arrayGet(eqCompMapping, eqIdx+offset);
        //print("Component " +& intString(sccIdx) +& "\n");
        true = BackendDAEUtil.traverseBackendDAEExpsOptEqn(SOME(eq), getComponentsIncludingTime1, false);
        resultList = sccIdx::resultList;
      then ((eq, (offset,resultList,eqCompMapping,eqIdx+1)));
    case((eq, (offset,resultList,eqCompMapping,eqIdx)))
      then ((eq, (offset,resultList,eqCompMapping,eqIdx+1)));
  end matchcontinue;
end getComponentsIncludingTime0;

protected function getComponentsIncludingTime1
  input tuple<DAE.Exp, Boolean> inTpl;
  output tuple<DAE.Exp, Boolean> outTpl;
protected
  DAE.Exp e;
  String expStr;
  Boolean res;
algorithm
  outTpl := match(inTpl)
    case((e,false))
      equation
        res = Expression.traverseCrefsFromExp(e, getComponentsIncludingTime2, false);
      then ((e,res));
    else then inTpl;
  end match;
end getComponentsIncludingTime1;

protected function getComponentsIncludingTime2
  input DAE.ComponentRef iRef;
  input Boolean iIncludingTime;
  output Boolean oIncludingTime;
algorithm
  oIncludingTime := match(iRef, iIncludingTime)
    case (DAE.CREF_IDENT(ident="time"),_)
      equation
        //BackendDump.debugCrefStr((iRef, "\n"));
      then true;
    else
      equation
        //BackendDump.debugCrefStr((iRef, "\n"));
      then (false or iIncludingTime);
  end match;
end getComponentsIncludingTime2;

protected function getDiscreteNodes " get the taskgraph nodes that solves discrete values
author: marcusw"
  input BackendDAE.BackendDAE systIn;
  input array<tuple<Integer,Integer,Integer>> eqCompMapping;
  output list<Integer> eventNodes;
protected
  list<Integer> eqLst;
  list<tuple<Integer,Integer,Integer>> tplLst;
  BackendDAE.EqSystems systemsIn;
algorithm
  BackendDAE.DAE(eqs=systemsIn) := systIn;
  ((eqLst,_)) := List.fold(systemsIn, getDiscreteNodesEqs,({},0));
  eventNodes := getArrayTuple31(eqLst,eqCompMapping);
end getDiscreteNodes;


protected function getDiscreteNodesEqs
  input BackendDAE.EqSystem systIn;
  input tuple<list<Integer>,Integer> eventInfoIn;
  output tuple<list<Integer>,Integer> eventInfoOut;
protected
  BackendDAE.StrongComponents comps;
  BackendDAE.Variables orderedVars;
  list<Integer> eventEqs;
  list<Integer> eventEqsIn;
  Integer numOfEqs;
  Integer offset;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs = BackendDAE.EQUATION_ARRAY(numberOfElement=numOfEqs),orderedVars=orderedVars,matching=BackendDAE.MATCHING(comps = comps)) := systIn;
  (eventEqsIn,offset) := eventInfoIn;
  eventEqs := getDiscreteNodesEqs1(comps,offset,orderedVars,{});
  offset := offset+numOfEqs;
  eventEqs := listAppend(eventEqs,eventEqsIn);
  eventInfoOut := (eventEqs,offset);
end getDiscreteNodesEqs;


protected function getDiscreteNodesEqs1
  input BackendDAE.StrongComponents comps;
  input Integer offset;
  input BackendDAE.Variables iOrderedVars;
  input list<Integer> discreteEqsIn;
  output list<Integer> discreteEqsOut;
algorithm
  discreteEqsOut := matchcontinue(comps,offset,iOrderedVars,discreteEqsIn)
    local
      Integer eqn;
      Integer sysCount;
      list<Integer> eventEqs;
      list<Integer> condVars;
      BackendDAE.StrongComponents rest;
      BackendDAE.StrongComponent head;
    case((head::rest),_,_,_)
      equation
        (true,eqn) = solvesDiscreteValue(head, iOrderedVars);
        eqn = eqn+offset;
        eventEqs = getDiscreteNodesEqs1(rest,offset,iOrderedVars,eqn::discreteEqsIn);
      then
        eventEqs;
    case((head::rest),_,_,_)
      equation
        eventEqs = getDiscreteNodesEqs1(rest,offset,iOrderedVars,discreteEqsIn);
      then
        eventEqs;
    case({},_,_,_)
      then
        discreteEqsIn;
  end matchcontinue;
end getDiscreteNodesEqs1;


protected function solvesDiscreteValue
  input BackendDAE.StrongComponent inComp;
  input BackendDAE.Variables iOrderedVars;
  output Boolean oSolvesDiscreteValue;
  output Integer oFirstEqIdx;
algorithm
  (oSolvesDiscreteValue,oFirstEqIdx) := matchcontinue(inComp,iOrderedVars)
    local
      Integer eqn, var;
      list<Integer> vars, eqns;
      list<BackendDAE.Var> backendVars;
      BackendDAE.Var backendVar;
      Boolean solvesDiscreteValue;
    case(BackendDAE.SINGLEEQUATION(var=var,eqn=eqn),_)
      equation
        //print("Var of single equation: " +& intString(var) +& "\n");
        backendVar = BackendVariable.getVarAt(iOrderedVars, var);
        solvesDiscreteValue = BackendVariable.isVarDiscrete(backendVar);
      then (solvesDiscreteValue,eqn);
    case(BackendDAE.EQUATIONSYSTEM(vars=vars,eqns=eqns),_)
      equation
        //print("Vars of single equation system: " +& stringDelimitList(List.map(vars, intString), ",") +& "\n");
        backendVars = List.map1r(vars, BackendVariable.getVarAt, iOrderedVars);
        solvesDiscreteValue = BackendVariable.hasDiscreteVar(backendVars);
        eqn = List.first(eqns);
      then (solvesDiscreteValue,eqn);
    case(BackendDAE.MIXEDEQUATIONSYSTEM(disc_vars=vars,disc_eqns=eqns),_)
      equation
        //print("Vars of mixed equation system: " +& stringDelimitList(List.map(vars, intString), ",") +& "\n");
        backendVars = List.map1r(vars, BackendVariable.getVarAt, iOrderedVars);
        solvesDiscreteValue = BackendVariable.hasDiscreteVar(backendVars);
        eqn = List.first(eqns);
      then (solvesDiscreteValue,eqn);
    case(BackendDAE.SINGLEARRAY(vars=vars,eqn=eqn),_)
      equation
        //print("Vars of single array: " +& stringDelimitList(List.map(vars, intString), ",") +& "\n");
        backendVars = List.map1r(vars, BackendVariable.getVarAt, iOrderedVars);
        solvesDiscreteValue = BackendVariable.hasDiscreteVar(backendVars);
      then (solvesDiscreteValue,eqn);
    case(BackendDAE.SINGLEWHENEQUATION(vars=vars,eqn=eqn),_)
      equation
        //print("Vars of single when equation: " +& stringDelimitList(List.map(vars, intString), ",") +& "\n");
        backendVars = List.map1r(vars, BackendVariable.getVarAt, iOrderedVars);
        solvesDiscreteValue = BackendVariable.hasDiscreteVar(backendVars);
      then (solvesDiscreteValue,eqn);
    case(BackendDAE.SINGLECOMPLEXEQUATION(vars=vars,eqn=eqn),_)
      equation
        //print("Vars of single complex equation: " +& stringDelimitList(List.map(vars, intString), ",") +& "\n");
        backendVars = List.map1r(vars, BackendVariable.getVarAt, iOrderedVars);
        solvesDiscreteValue = BackendVariable.hasDiscreteVar(backendVars);
      then (solvesDiscreteValue,eqn);
    case(BackendDAE.SINGLEALGORITHM(vars=vars,eqn=eqn),_)
      equation
        //print("Vars of single algorithm: " +& stringDelimitList(List.map(vars, intString), ",") +& "\n");
        backendVars = List.map1r(vars, BackendVariable.getVarAt, iOrderedVars);
        solvesDiscreteValue = BackendVariable.hasDiscreteVar(backendVars);
      then (solvesDiscreteValue,eqn);
    case(BackendDAE.SINGLEIFEQUATION(vars=vars,eqn=eqn),_)
      equation
        //print("Vars of single if equation: " +& stringDelimitList(List.map(vars, intString), ",") +& "\n");
        backendVars = List.map1r(vars, BackendVariable.getVarAt, iOrderedVars);
        solvesDiscreteValue = BackendVariable.hasDiscreteVar(backendVars);
      then (solvesDiscreteValue,eqn);
  else
    then
      (false,-1);
  end matchcontinue;
end solvesDiscreteValue;


//Methods to write blt-structure as xml-file
//------------------------------------------
//------------------------------------------
public function dumpAsGraphMLSccLevel "author: marcusw, waurich
  Write out the given graph as a graphml file."
  input TaskGraph iGraph;
  input TaskGraphMeta iGraphData;
  input BackendDAE.BackendDAE backendDAE;
  input String fileName;
  input String criticalPathInfo; //Critical path as String
  input list<tuple<Integer,Integer>> iCriticalPath; //Critical path as list of edges
  input list<tuple<Integer,Integer>> iCriticalPathWoC; //Critical path without communciation as list of edges
  input array<list<Integer>> sccSimEqMapping; //maps each scc to simEqSystems
  input array<tuple<Integer,Integer,Real>> schedulerInfo; //maps each Task to <threadId, orderId, startCalcTime>
protected
  GraphML.GraphInfo graphInfo;
algorithm
  graphInfo := convertToGraphMLSccLevel(iGraph,iGraphData,backendDAE,criticalPathInfo,iCriticalPath,iCriticalPathWoC,sccSimEqMapping,schedulerInfo);
  GraphML.dumpGraph(graphInfo, fileName);
end dumpAsGraphMLSccLevel;

public function convertToGraphMLSccLevel "author: marcusw, waurich
  Convert the given graph into a graphml-structure."
  input TaskGraph iGraph;
  input TaskGraphMeta iGraphData;
  input BackendDAE.BackendDAE backendDAE;
  input String criticalPathInfo; //Critical path as String
  input list<tuple<Integer,Integer>> iCriticalPath; //Critical path as list of edges
  input list<tuple<Integer,Integer>> iCriticalPathWoC; //Critical path without communciation as list of edges
  input array<list<Integer>> sccSimEqMapping; //maps each scc to simEqSystems
  input array<tuple<Integer,Integer,Real>> schedulerInfo; //maps each Task to <threadId, orderId, startCalcTime>
  output GraphML.GraphInfo oGraphInfo;
protected
  Integer graphIdx;
  array<String> annotationInfo;
  GraphML.GraphInfo graphInfo;
algorithm
  graphInfo := GraphML.createGraphInfo();
  (graphInfo, (_,graphIdx)) := GraphML.addGraph("TaskGraph", true, graphInfo);
  annotationInfo := arrayCreate(arrayLength(iGraph),"uncomment in HpcOmTaskGraph and +showAnnotations");
  //annotationInfo := setAnnotationsForTasks(iGraphData,backendDAE,annotationInfo);
  oGraphInfo := convertToGraphMLSccLevelSubgraph(iGraph,iGraphData,criticalPathInfo,iCriticalPath,iCriticalPathWoC,sccSimEqMapping,schedulerInfo,annotationInfo,graphIdx,graphInfo);
end convertToGraphMLSccLevel;

public function convertToGraphMLSccLevelSubgraph "author: marcusw, waurich
  Convert the given graph into a subgraph of the graphml-structure."
  input TaskGraph iGraph;
  input TaskGraphMeta iGraphData;
  input String criticalPathInfo; //Critical path as String
  input list<tuple<Integer,Integer>> iCriticalPath; //Critical path as list of edges
  input list<tuple<Integer,Integer>> iCriticalPathWoC; //Critical path without communciation as list of edges
  input array<list<Integer>> sccSimEqMapping; //maps each scc to simEqSystems
  input array<tuple<Integer,Integer,Real>> schedulerInfo; //maps each Task to <threadId, orderId, startCalcTime>
  input array<String> annotationInfo;  //annotations for the variables in a task
  input Integer iGraphIdx;
  input GraphML.GraphInfo iGraphInfo;
  output GraphML.GraphInfo oGraphInfo;
protected
  GraphML.GraphInfo graphInfo;
  Integer nameAttIdx, calcTimeAttIdx, opCountAttIdx, yCoordAttIdx, taskIdAttIdx, commCostAttIdx, commVarsAttIdx, critPathAttIdx, simCodeEqAttIdx, threadIdAttIdx, taskNumberAttIdx, annotAttIdx;
  list<Integer> nodeIdc;
algorithm
  oGraphInfo := match(iGraph, iGraphData, criticalPathInfo, iCriticalPath, iCriticalPathWoC, sccSimEqMapping, schedulerInfo, annotationInfo, iGraphIdx, iGraphInfo)
    case(_,_,_,_,_,_,_,_,_,_)
      equation
        (graphInfo,(_,nameAttIdx)) = GraphML.addAttribute("", "Name", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), iGraphInfo);
        (graphInfo,(_,opCountAttIdx)) = GraphML.addAttribute("-1", "Operations", GraphML.TYPE_INTEGER(), GraphML.TARGET_NODE(), graphInfo);
        (graphInfo,(_,calcTimeAttIdx)) = GraphML.addAttribute("-1", "CalcTime", GraphML.TYPE_DOUBLE(), GraphML.TARGET_NODE(), graphInfo);
        (graphInfo,(_,taskIdAttIdx)) = GraphML.addAttribute("", "TaskID", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graphInfo);
        (graphInfo,(_,yCoordAttIdx)) = GraphML.addAttribute("17", "yCoord", GraphML.TYPE_INTEGER(), GraphML.TARGET_NODE(), graphInfo);
        (graphInfo,(_,simCodeEqAttIdx)) = GraphML.addAttribute("", "SimCodeEqs", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graphInfo);
        (graphInfo,(_,threadIdAttIdx)) = GraphML.addAttribute("", "ThreadId", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graphInfo);
        (graphInfo,(_,taskNumberAttIdx)) = GraphML.addAttribute("-1", "TaskNumber", GraphML.TYPE_INTEGER(), GraphML.TARGET_NODE(), graphInfo);
        (graphInfo,(_,commCostAttIdx)) = GraphML.addAttribute("-1", "CommCost", GraphML.TYPE_INTEGER(), GraphML.TARGET_EDGE(), graphInfo);
        (graphInfo,(_,commVarsAttIdx)) = GraphML.addAttribute("-1", "CommVars", GraphML.TYPE_INTEGER(), GraphML.TARGET_EDGE(), graphInfo);
        (graphInfo,(_,annotAttIdx)) = GraphML.addAttribute("annotation", "annotations", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graphInfo);
        (graphInfo,(_,critPathAttIdx)) = GraphML.addAttribute("", "CriticalPath", GraphML.TYPE_STRING(), GraphML.TARGET_GRAPH(), graphInfo);
        graphInfo = GraphML.addGraphAttributeValue((critPathAttIdx, criticalPathInfo), iGraphIdx, graphInfo);
        nodeIdc = List.intRange(arrayLength(iGraph));
        ((graphInfo,_)) = List.fold4(nodeIdc, addNodeToGraphML, (iGraph, iGraphData), (nameAttIdx,opCountAttIdx,calcTimeAttIdx,taskIdAttIdx,yCoordAttIdx,commCostAttIdx, commVarsAttIdx, simCodeEqAttIdx, threadIdAttIdx, taskNumberAttIdx,annotAttIdx), sccSimEqMapping, (iCriticalPath,iCriticalPathWoC,schedulerInfo, annotationInfo), (graphInfo,iGraphIdx));
      then graphInfo;
  end match;
end convertToGraphMLSccLevelSubgraph;


protected function addNodeToGraphML "author: marcusw, waurich
  Adds the given node to the given graph."
  input Integer nodeIdx;
  input tuple<TaskGraph, TaskGraphMeta> tGraphDataTuple;
  input tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> attIdc;
  //Attribute index for <nameAttIdx,opCountAttIdx, calcTimeAttIdx, taskIdAttIdx, yCoordAttIdx, commCostAttIdx, commVarsAttIdx, simCodeEqAttIdx, threadIdAttIdx, taskNumberAttIdx, annotationAttIdx>
  input array<list<Integer>> sccSimEqMapping;
  input tuple<list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,array<tuple<Integer,Integer,Real>>,array<String>> iSchedulerInfoCritPath; //<criticalPath,criticalPathWoC,schedulerInfo,annotationInfo>
  input tuple<GraphML.GraphInfo,Integer> iGraph;
  output tuple<GraphML.GraphInfo,Integer> oGraph; //<GraphInfo, GraphIdx>
algorithm
  oGraph := matchcontinue(nodeIdx,tGraphDataTuple,attIdc,sccSimEqMapping,iSchedulerInfoCritPath,iGraph)
    local
      TaskGraph tGraphIn;
      TaskGraphMeta tGraphDataIn;
      GraphML.GraphInfo tmpGraph;
      Integer graphIdx;
      Integer opCount, nameAttIdx, calcTimeAttIdx, opCountAttIdx, taskIdAttIdx, yCoordAttIdx, commCostAttIdx, commVarsAttIdx, yCoord, simCodeEqAttIdx, threadIdAttIdx, taskNumberAttIdx, annotationAttIdx;
      Real calcTime, taskFinishTime, taskStartTime;
      Integer primalComp;
      list<Integer> childNodes;
      list<Integer> components;
      list<Integer> rootNodes;
      list<Integer> simCodeEqs;
      array<tuple<Integer,Integer,Integer>>  eqCompMapping;
      array<tuple<Integer,Real>> exeCosts;
      array<Integer> nodeMark;
      array<list<Integer>> inComps;
      array<String> nodeNames;
      array<String> nodeDescs;
      array<String> annotationInfo;
      array<list<tuple<Integer,Integer,Integer>>> commCosts;
      String calcTimeString, opCountString, yCoordString, taskFinishTimeString, taskStartTimeString;
      String compText;
      String description;
      String nodeDesc;
      String componentsString;
      String simCodeEqString;
      String threadIdxString, taskNumberString;
      String annotationString;
      Integer schedulerThreadId, schedulerTaskNumber;
      list<GraphML.NodeLabel> nodeLabels;
      array<tuple<Integer,Integer,Real>> schedulerInfo;
      list<tuple<Integer,Integer>> criticalPath, criticalPathWoC;
    case(_,(tGraphIn,tGraphDataIn),_,_,(criticalPath,criticalPathWoC,schedulerInfo,annotationInfo),(tmpGraph,graphIdx))
      equation
        false = nodeIdx == 0 or nodeIdx == -1;
        (nameAttIdx, opCountAttIdx, calcTimeAttIdx, taskIdAttIdx, yCoordAttIdx, commCostAttIdx, commVarsAttIdx, simCodeEqAttIdx, threadIdAttIdx, taskNumberAttIdx,annotationAttIdx) = attIdc;
        TASKGRAPHMETA(inComps = inComps, eqCompMapping=eqCompMapping, rootNodes = rootNodes, nodeNames =nodeNames ,nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) = tGraphDataIn;
        components = arrayGet(inComps,nodeIdx);
        true = listLength(components)==1;
        primalComp = listGet(components,1);
        //print("node in the taskGraph "+&intString(nodeIdx)+&" primalComp "+&intString(primalComp)+&"\n");
        compText = arrayGet(nodeNames,primalComp);
        nodeDesc = arrayGet(nodeDescs,primalComp);
        annotationString = arrayGet(annotationInfo,nodeIdx);
        ((_,calcTime)) = arrayGet(exeCosts,primalComp);
        ((opCount,calcTime)) = arrayGet(exeCosts,primalComp);
        calcTimeString = realString(calcTime);
        yCoord = arrayGet(nodeMark,nodeIdx)*100;
        calcTimeString = realString(calcTime);
        opCountString = intString(opCount);
        yCoordString = intString(yCoord);
        childNodes = arrayGet(tGraphIn,nodeIdx);
        simCodeEqs = arrayGet(sccSimEqMapping,primalComp);
        //print("Component " +& intString(primalComp) +& " arrayLength " +& intString(arrayLength(sccSimEqMapping)) +& "\n");
        //print("First simEq: " +& intString(List.first(simCodeEqs)) +& "\n");
        simCodeEqString = stringDelimitList(List.map(simCodeEqs,intString),", ");
        //componentsString = List.fold(components, addNodeToGraphML2, " ");
        componentsString = (" "+&intString(nodeIdx)+&" ");
        ((schedulerThreadId,schedulerTaskNumber,taskFinishTime)) = arrayGet(schedulerInfo,nodeIdx);
        taskStartTime = realSub(taskFinishTime,calcTime);
        threadIdxString = "Th " +& intString(schedulerThreadId);
        taskNumberString = intString(schedulerTaskNumber);
        calcTimeString = System.snprintff("%.0f", 25, calcTime);
        taskFinishTimeString = System.snprintff("%.0f", 25, taskFinishTime);
        taskStartTimeString = System.snprintff("%.0f", 25, taskStartTime);
        nodeLabels = {GraphML.NODELABEL_INTERNAL(componentsString, NONE(), GraphML.FONTPLAIN()), GraphML.NODELABEL_CORNER(calcTimeString, SOME(GraphML.COLOR_YELLOW), GraphML.FONTBOLD(), "se"), GraphML.NODELABEL_CORNER(taskStartTimeString, SOME(GraphML.COLOR_CYAN), GraphML.FONTBOLD(), "nw"), GraphML.NODELABEL_CORNER(taskFinishTimeString, SOME(GraphML.COLOR_PINK), GraphML.FONTBOLD(), "sw")};
        //print("Node " +& intString(nodeIdx) +& " has child nodes " +& stringDelimitList(List.map(childNodes,intString),", ") +& "\n");
        (tmpGraph,(_,_)) = GraphML.addNode("Node" +& intString(nodeIdx),
                                              GraphML.COLOR_ORANGE,
                                              nodeLabels,
                                              GraphML.RECTANGLE(),
                                              SOME(nodeDesc),
                                              {((nameAttIdx,compText)),((calcTimeAttIdx,calcTimeString)),((opCountAttIdx, opCountString)),((taskIdAttIdx,componentsString)),((yCoordAttIdx,yCoordString)),((simCodeEqAttIdx,simCodeEqString)),((threadIdAttIdx,threadIdxString)),((taskNumberAttIdx,taskNumberString)),((annotationAttIdx,annotationString))},
                                              graphIdx,
                                              tmpGraph);
        tmpGraph = List.fold4(childNodes, addDepToGraph, nodeIdx, tGraphDataIn, (commCostAttIdx, commVarsAttIdx), (criticalPath,criticalPathWoC), tmpGraph);
      then
        ((tmpGraph,graphIdx));
    case(_,(tGraphIn,tGraphDataIn),_,_,(criticalPath,criticalPathWoC,schedulerInfo,annotationInfo),(tmpGraph,graphIdx))
      equation
        // for a node that consists of contracted nodes
        false = nodeIdx == 0 or nodeIdx == -1;
        (nameAttIdx, opCountAttIdx, calcTimeAttIdx, taskIdAttIdx, yCoordAttIdx, commCostAttIdx, commVarsAttIdx, simCodeEqAttIdx, threadIdAttIdx, taskNumberAttIdx, annotationAttIdx) = attIdc;
        TASKGRAPHMETA(inComps = inComps, eqCompMapping=eqCompMapping, rootNodes = rootNodes, nodeNames =nodeNames ,nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) = tGraphDataIn;
        components = arrayGet(inComps,nodeIdx);
        false = listLength(components)==1;
        primalComp = List.last(components);
        //print("node in the taskGraph (case 2) "+&intString(nodeIdx)+&" primalComp "+&intString(primalComp)+&"\n");
        compText = arrayGet(nodeNames,primalComp);
        nodeDesc = stringDelimitList(List.map1(components, Util.arrayGetIndexFirst, nodeDescs), "\n");// arrayGet(nodeDescs,primalComp);
        yCoord = arrayGet(nodeMark,nodeIdx)*100;
        yCoordString = intString(yCoord);
        annotationString = arrayGet(annotationInfo,nodeIdx);
        ((opCount,calcTime)) = List.fold1(components, addNodeToGraphML1, exeCosts, (0,0.0));
        calcTimeString = realString(calcTime);
        opCountString = intString(opCount);
        childNodes = arrayGet(tGraphIn,nodeIdx);
        //componentsString = List.fold(components, addNodeToGraphML2, " ");
        componentsString = (" "+&intString(nodeIdx)+&" ");
        simCodeEqs = List.flatten(List.map1(components, Util.arrayGetIndexFirst, sccSimEqMapping));
        simCodeEqString = stringDelimitList(List.map(simCodeEqs,intString),", ");

        ((schedulerThreadId,schedulerTaskNumber,taskFinishTime)) = arrayGet(schedulerInfo,nodeIdx);
        taskStartTime = realSub(taskFinishTime,calcTime);
        threadIdxString = "Th " +& intString(schedulerThreadId);
        taskNumberString = intString(schedulerTaskNumber);

        calcTimeString = System.snprintff("%.0f", 25, calcTime);
        taskFinishTimeString = System.snprintff("%.0f", 25, taskFinishTime);
        taskStartTimeString = System.snprintff("%.0f", 25, taskStartTime);
        nodeLabels = {GraphML.NODELABEL_INTERNAL(componentsString, NONE(), GraphML.FONTPLAIN()), GraphML.NODELABEL_CORNER(calcTimeString, SOME(GraphML.COLOR_YELLOW), GraphML.FONTBOLD(), "se"), GraphML.NODELABEL_CORNER(taskStartTimeString, SOME(GraphML.COLOR_CYAN), GraphML.FONTBOLD(), "nw"), GraphML.NODELABEL_CORNER(taskFinishTimeString, SOME(GraphML.COLOR_PINK), GraphML.FONTBOLD(), "sw")};
        //print("Node " +& intString(nodeIdx) +& " has child nodes " +& stringDelimitList(List.map(childNodes,intString),", ") +& "\n");
        (tmpGraph,(_,_)) = GraphML.addNode("Node" +& intString(nodeIdx),
                                      GraphML.COLOR_ORANGE,
                                      nodeLabels,
                                      GraphML.RECTANGLE(),
                                      SOME(nodeDesc),
                                      {((nameAttIdx,compText)),((calcTimeAttIdx,calcTimeString)),((opCountAttIdx, opCountString)),((yCoordAttIdx,yCoordString)),((taskIdAttIdx,componentsString)), ((simCodeEqAttIdx,simCodeEqString)),((threadIdAttIdx,threadIdxString)),((taskNumberAttIdx,taskNumberString)),((annotationAttIdx,annotationString))},
                                      graphIdx,
                                      tmpGraph);
        tmpGraph = List.fold4(childNodes, addDepToGraph, nodeIdx, tGraphDataIn, (commCostAttIdx, commVarsAttIdx), (criticalPath,criticalPathWoC), tmpGraph);
      then
        ((tmpGraph,graphIdx));
    else
      equation
        //true = nodeIdx == 0 or nodeIdx == -1;
        print("addSccToGraphML failed \n");
      then
          fail();
   end matchcontinue;
end addNodeToGraphML;

protected function addNodeToGraphML1
  input Integer compIdx;
  input array<tuple<Integer,Real>> exeCosts;
  input tuple<Integer,Real> exeCostsIn;
  output tuple<Integer,Real> exeCostsOut;
protected
  Integer opCount, opCountIn;
  Real exeTimeIn, exeTime;
algorithm
  (opCountIn,exeTimeIn) := exeCostsIn;
  ((opCount,exeTime)) := arrayGet(exeCosts,compIdx);
  exeCostsOut := ((opCountIn+opCount,realAdd(exeTimeIn,exeTime)));
end addNodeToGraphML1;

protected function addDepToGraph "author: marcusw
  Adds a new edge between the component-nodes with index comp1Idx and comp2Idx to the graph."
  input Integer childIdx;
  input Integer parentIdx;
  input TaskGraphMeta tGraphDataIn;
  input tuple<Integer,Integer> iCommAttIdc; //<%(commCostAttIdx, commVarsAttIdx)%>
  input tuple<list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>> iCriticalPathEdges; //<%criticalPathEdges, criticalPathEdgesWoC%>
  input GraphML.GraphInfo iGraph;
  output GraphML.GraphInfo oGraph;
protected
  array<list<tuple<Integer,Integer,Integer>>> commCosts;
  Integer commCostAttIdx, commVarsAttIdx;
  Integer commCost, numOfCommVars, primalCompParent, primalCompChild;
  String refSccCountStr, commCostString, numOfCommVarsString;
  array<list<Integer>> inComps;
  array<Integer> nodeMark;
  list<Integer> components;
  GraphML.GraphInfo tmpGraph;
  list<tuple<Integer,Integer>> criticalPathEdges, criticalPathEdgesWoC;
  String edgeColor;
algorithm
  oGraph := matchcontinue(childIdx, parentIdx, tGraphDataIn, iCommAttIdc, iCriticalPathEdges, iGraph)
    case(_,_,TASKGRAPHMETA(commCosts=commCosts, nodeMark=nodeMark, inComps=inComps),(commCostAttIdx, commVarsAttIdx),(criticalPathEdges, criticalPathEdgesWoC),_)
      equation
        true = List.exist1(criticalPathEdges, compareIntTuple2, (parentIdx, childIdx));
        //Edge is part of critical path
        ((_,numOfCommVars,commCost)) = getCommCostBetweenNodes(parentIdx,childIdx,tGraphDataIn);
        numOfCommVarsString = intString(numOfCommVars);
        commCostString = intString(commCost);
        edgeColor = Util.if_(List.exist1(criticalPathEdgesWoC, compareIntTuple2, (parentIdx, childIdx)), GraphML.COLOR_GRAY, GraphML.COLOR_BLACK);
        (tmpGraph,(_,_)) = GraphML.addEdge("Edge" +& intString(parentIdx) +& intString(childIdx),
                                              "Node" +& intString(childIdx), "Node" +& intString(parentIdx),
                                              edgeColor,
                                              GraphML.LINE(),
                                              GraphML.LINEWIDTH_BOLD,
                                              false,
                                              {GraphML.EDGELABEL(commCostString, SOME(edgeColor), GraphML.FONTSIZE_STANDARD)},
                                              (GraphML.ARROWNONE(),GraphML.ARROWSTANDART()),
                                              {(commCostAttIdx, commCostString),(commVarsAttIdx, numOfCommVarsString)},
                                              iGraph);
      then tmpGraph;
    case(_,_,TASKGRAPHMETA(commCosts=commCosts, nodeMark=nodeMark, inComps=inComps),(commCostAttIdx, commVarsAttIdx),(criticalPathEdges, criticalPathEdgesWoC),_)
      equation
        //Edge is not part of critical path
        ((_,numOfCommVars,commCost)) = getCommCostBetweenNodes(parentIdx,childIdx,tGraphDataIn);
        numOfCommVarsString = intString(numOfCommVars);
        commCostString = intString(commCost);
        edgeColor = Util.if_(List.exist1(criticalPathEdgesWoC, compareIntTuple2, (parentIdx, childIdx)), GraphML.COLOR_GRAY, GraphML.COLOR_BLACK);
        (tmpGraph,(_,_)) = GraphML.addEdge( "Edge" +& intString(parentIdx) +& intString(childIdx),
                                            "Node" +& intString(childIdx),
                                            "Node" +& intString(parentIdx),
                                            edgeColor,
                                            GraphML.LINE(),
                                            GraphML.LINEWIDTH_STANDARD,
                                            false,
                                            {GraphML.EDGELABEL(commCostString, SOME(edgeColor), GraphML.FONTSIZE_STANDARD)},
                                            (GraphML.ARROWNONE(),GraphML.ARROWSTANDART()),
                                            {(commCostAttIdx, commCostString),(commVarsAttIdx, numOfCommVarsString)},
                                            iGraph);
      then tmpGraph;
    else
      equation
        print("HpcOmTaskGraph.addDepToGraph failed! Unsupported case\n");
      then fail();
  end matchcontinue;
end addDepToGraph;

public function getCommunicationCost " gets the communication cost for an edge from parent node to child node.
 REMARK: use the primal indeces!!!!!!
  author: waurich TUD 2013-06."
  input Integer childIdx;
  input Integer parentIdx;
  input array<list<tuple<Integer,Integer,Integer>>> commCosts;
  output tuple<Integer,Integer,Integer> tplOut;
protected
  list<tuple<Integer,Integer,Integer>> commRow;
  tuple<Integer,Integer,Integer> commEntry;
  Integer cost, numOfVars;
algorithm
  //print("Try to get comm cost for edge from " +& intString(parentIdx) +& " to " +& intString(childIdx) +& "\n");
  commRow := arrayGet(commCosts,parentIdx);
  commEntry := getTupleByFirstEntry(commRow,childIdx);
  //(_,numOfVars,cost) := commEntry;
  tplOut := commEntry;
end getCommunicationCost;


protected function getTupleByFirstEntry " gets the tuple of a list<tuple> whose first entry corresponds to valueIn.
author:Waurich TUD 2013-06"
  input list<tuple<Integer,Integer,Integer>> tplLstIn;
  input Integer valueIn;
  output tuple<Integer,Integer,Integer> tpleOut;
algorithm
  tpleOut := matchcontinue(tplLstIn,valueIn)
    local
      Integer tplValue;
      tuple<Integer,Integer,Integer> tplTmp;
      tuple<Integer,Integer,Integer> head;
      list<tuple<Integer,Integer,Integer>> rest;
    case(head::rest,_)
      equation
        (tplValue,_,_) = head;
        false = intEq(tplValue,valueIn);
        tplTmp = getTupleByFirstEntry(rest,valueIn);
      then
        tplTmp;
    case(head::_,_)
      equation
        (tplValue,_,_) = head;
        true = intEq(tplValue,valueIn);
      then
        head;
    case({},_)
      equation
        print("getTupleByFirstEntry (possibly in getCommunicationCosts) failed! - the value "+&intString(valueIn)+&" can not be found in the list of edges\n");
      then
        fail();
  end matchcontinue;
end getTupleByFirstEntry;

// print functions
//------------------------------------------
//------------------------------------------

public function printTaskGraph " prints the adjacencylist of the TaskGraph.
author:Waurich TUD 2013-07"
  input TaskGraph graphIn;
protected
  list<list<Integer>> graphLst;
algorithm
  print("\n");
  print("--------------------------------\n");
  print("TASKGRAPH\n");
  print("--------------------------------\n");
  graphLst := arrayList(graphIn);
  dumpAdjacencyLst(graphLst,1);
  print("\n");
end printTaskGraph;


public function dumpAdjacencyLst " prints the adjacencyLst.
author:Waurich TUD 2013-07"
  input list<list<Integer>> inIntegerLstLst;
  input Integer rowIndex;
algorithm
  _ := match (inIntegerLstLst,rowIndex)
    local
      list<Integer> row;
      list<list<Integer>> rows;
    case ({},_) then ();
    case ((row :: rows),_)
      equation
        print(intString(rowIndex));print(":");
        dumpAdjacencyRow(row);
        dumpAdjacencyLst(rows,rowIndex+1);
      then
        ();
  end match;
end dumpAdjacencyLst;

public function dumpAdjacencyRow
"author: PA
  Helper function to dumpIncidenceMatrix2."
  input list<Integer> inIntegerLst;
algorithm
  _ := match (inIntegerLst)
    local
      String s;
      Integer x;
      list<Integer> xs;
    case ({})
      equation
        print("\n");
      then
        ();
    case ((x :: xs))
      equation
        s = intString(x);
        print(s);
        print(" ");
        dumpAdjacencyRow(xs);
      then
        ();
  end match;
end dumpAdjacencyRow;


public function printTaskGraphMeta " prints all data from TaskGraphMeta.
author: Waurich TUD 2013-06"
  input TaskGraphMeta metaDataIn;
protected
  array<list<Integer>> inComps;
  array<tuple<Integer, Integer, Integer>>  varCompMapping;
  array<tuple<Integer,Integer,Integer>>  eqCompMapping;
  list<Integer> rootNodes;
  array<String> nodeNames;
  array<String> nodeDescs;
  array<tuple<Integer,Real>> exeCosts;
  array<list<tuple<Integer,Integer,Integer>>> commCosts;
  array<Integer> nodeMark;
algorithm
  TASKGRAPHMETA(inComps = inComps, varCompMapping = varCompMapping, eqCompMapping=eqCompMapping, rootNodes=rootNodes, nodeNames=nodeNames, nodeDescs=nodeDescs, exeCosts=exeCosts, commCosts=commCosts, nodeMark=nodeMark) := metaDataIn;
  print("\n");
  print("--------------------------------\n");
  print("TASKGRAPH METADATA\n");
  print("--------------------------------\n");
  print(intString(arrayLength(inComps))+&" nodes include components:\n");
  printInComps(inComps,1);
  print(intString(arrayLength(varCompMapping))+&" vars are solved in the nodes \n");
  printVarCompMapping(varCompMapping,1);
  print(intString(arrayLength(eqCompMapping))+&" equations are computed in the nodes \n");
  printeqCompMapping(eqCompMapping,1);
  print("the names of the components \n");
  printNodeNames(nodeNames,1);
  print("the description of the node\n");
  printNodeDescs(nodeDescs,1);
  print(intString(listLength(rootNodes))+&" rootNodes in the taskGraph\n");
  printRootNodes(rootNodes);
  print("the execution costs of the nodes\n");
  printExeCosts(exeCosts,1);
  print("the communication costs of the nodes\n");
  printCommCosts(commCosts,1);
  print("the nodeMark of the nodes\n");
  printNodeMark(nodeMark,1);
  print("\n");
end printTaskGraphMeta;


public function printInComps " prints the information about the assigned components to a taskgraph node.
author:Waurich TUD 2013-06"
  input array<list<Integer>> inComps;
  input Integer compIdx;
algorithm
  _ := matchcontinue(inComps,compIdx)
  local
    list<Integer> compRow;
  case(_,_)
    equation
      true = arrayLength(inComps)>= compIdx;
      compRow = arrayGet(inComps,compIdx);
      print("node "+&intString(compIdx)+&" includes: "+&stringDelimitList(List.map(compRow,intString),", ")+&"\n");
      printInComps(inComps,compIdx+1);
      then
        ();
  else
    equation
      print("--------------------------------\n");
      then
        ();
  end matchcontinue;
end printInComps;


public function printVarCompMapping " prints the information about how the vars are assigned to the graph nodes
author: Waurich TUD 2013-07"
  input array<tuple<Integer, Integer, Integer>> varCompMapping;
  input Integer varIdx;
algorithm
  _ := matchcontinue(varCompMapping,varIdx)
  local
    Integer comp, eqSysIdx, varOffset;
  case(_,_)
    equation
      true = arrayLength(varCompMapping)>= varIdx;
      ((comp,eqSysIdx,varOffset)) = arrayGet(varCompMapping,varIdx);
      print("variable "+&intString(varIdx-varOffset)+&" (offset: " +& intString(varOffset) +& ") of equation system " +& intString(eqSysIdx) +& " is solved in the node: "+&intString(comp)+&"\n");
      printVarCompMapping(varCompMapping,varIdx+1);
      then
        ();
  else
    equation
      print("--------------------------------\n");
      then
        ();
  end matchcontinue;
end printVarCompMapping;

public function printeqCompMapping " prints the information about which equations are assigned to the graph nodes
author: Waurich TUD 2013-07"
  input array<tuple<Integer,Integer,Integer>> eqCompMapping;
  input Integer eqIdx;
algorithm
  _ := matchcontinue(eqCompMapping,eqIdx)
  local
    Integer comp, eqSysIdx, eqOffset;
  case(_,_)
    equation
      true = arrayLength(eqCompMapping)>= eqIdx;
      ((comp,eqSysIdx,eqOffset)) = arrayGet(eqCompMapping,eqIdx);
      print("equation "+&intString(eqIdx)+& " (offset: " +& intString(eqOffset) +& ") of equation system " +& intString(eqSysIdx) +& " is computed in node: "+&intString(comp)+&"\n");
      printeqCompMapping(eqCompMapping,eqIdx+1);
      then
        ();
  else
    equation
      print("--------------------------------\n");
      then
        ();
  end matchcontinue;
end printeqCompMapping;

protected function printNodeNames " prints the information about the node names of the taskgraph nodes
author: Waurich TUD 2013-07"
  input array<String> nodeNames;
  input Integer compIdx;
algorithm
  _ := matchcontinue(nodeNames,compIdx)
  local
    String  compName;
  case(_,_)
    equation
      true = arrayLength(nodeNames)>= compIdx;
      compName = arrayGet(nodeNames,compIdx);
      print("component "+&intString(compIdx)+&" is named "+&compName+&"\n");
      printNodeNames(nodeNames,compIdx+1);
      then
        ();
  else
    equation
      print("--------------------------------\n");
      then
        ();
  end matchcontinue;
end printNodeNames;


protected function printNodeDescs " prints the information about the description of the taskgraph nodes for the .graphml file.
author: Waurich TUD 2013-07"
  input array<String> nodeDescs;
  input Integer compIdx;
algorithm
  _ := matchcontinue(nodeDescs,compIdx)
  local
    String  compDesc;
  case(_,_)
    equation
      true = arrayLength(nodeDescs)>= compIdx;
      compDesc = arrayGet(nodeDescs,compIdx);
      print("component "+&intString(compIdx)+&" is described : "+&compDesc+&"\n");
      printNodeDescs(nodeDescs,compIdx+1);
      then
        ();
  else
    equation
      print("--------------------------------\n");
      then
        ();
  end matchcontinue;
end printNodeDescs;


protected function printRootNodes " print the information about the rootNodes (nodes without predecessor)in the task graph.
author. Waurich TUD 2013-07"
  input list<Integer> rootNodes;
algorithm
  print(" the rootNodes are: "+& stringDelimitList(List.map(rootNodes,intString),", ")+&"\n");
  print("--------------------------------\n");
end printRootNodes;


protected function printExeCosts " prints the information about the execution costs of every task graph
author: Waurich TUD 2013-07"
  input array<tuple<Integer,Real>> exeCosts;
  input Integer compIdx;
algorithm
  _ := matchcontinue(exeCosts,compIdx)
  local
    tuple<Integer,Real> exeCost;
    Integer opCount;
    Real execTime;
  case(_,_)
    equation
      true = arrayLength(exeCosts)>= compIdx;
      exeCost = arrayGet(exeCosts,compIdx);
      (opCount,execTime) = exeCost;
      print("component "+&intString(compIdx)+&" has an execution cost of : (" +& intString(opCount) +& "," +& realString(execTime) +& ")\n");
      printExeCosts(exeCosts,compIdx+1);
      then
        ();
  else
    equation
      print("--------------------------------\n");
      then
        ();
  end matchcontinue;
end printExeCosts;


protected function printCommCosts " prints the information about the the communication costs of every edge.
author:Waurich TUD 2013-06"
  input array<list<tuple<Integer,Integer,Integer>>> commCosts;
  input Integer compIdx;
algorithm
  _ := matchcontinue(commCosts,compIdx)
  local
    list<tuple<Integer,Integer,Integer>> compRow;
  case(_,_)
    equation
      true = arrayLength(commCosts)>= compIdx;
      compRow = arrayGet(commCosts,compIdx);
      print("edges from component "+&intString(compIdx)+&" with the communication costs "+&stringDelimitList(List.map(compRow,tuple3ToString),", ")+&"\n");
      printCommCosts(commCosts,compIdx+1);
      then
        ();
  else
    equation
      print("--------------------------------\n");
      then
        ();
  end matchcontinue;
end printCommCosts;


public function printNodeMark " prints the information about additional NodeMark
author: Waurich TUD 2013-07"
  input array<Integer> nodeMark;
  input Integer compIdx;
algorithm
  _ := matchcontinue(nodeMark,compIdx)
  local
    Integer mark;
  case(_,_)
    equation
      true = arrayLength(nodeMark)>= compIdx;
      mark = arrayGet(nodeMark,compIdx);
      print("component "+&intString(compIdx)+&" has the nodeMark : "+&intString(mark)+&"\n");
      printNodeMark(nodeMark,compIdx+1);
      then
        ();
  else
    equation
      print("--------------------------------\n");
      then
        ();
  end matchcontinue;
end printNodeMark;

public function intLstString "function to print a list<Integer>
author:Waurich TUD 2013-07"
  input list<Integer> lstIn;
  output String strOut;
protected
  String str;
algorithm
  str := stringDelimitList(List.map(lstIn,intString),",");
  strOut := Util.if_(List.isEmpty(lstIn),"---",str);
end intLstString;

public function dumpCriticalPathInfo "author:marcusw
  dump the criticalPath and the costs to a string."
  input tuple<list<list<Integer>>,Real> iCriticalPaths; //<%criticalPath, criticalPathOpCost%>
  input tuple<list<list<Integer>>,Real> iCriticalPathsWoC; //<%criticalPath, criticalPathOpCost%>
  output String oString;
protected
  String tmpString;
  list<list<Integer>> critPath, critPathWoC;
  Real costPath, costPathWoC;
algorithm
  oString := matchcontinue(iCriticalPaths,iCriticalPathsWoC)
  case(({},_),_)
    equation
    then
      "";
  case((critPath,costPath),(critPathWoC,costPathWoC))
    equation
      tmpString = "critical path with costs of "+&realString(costPath)+&" cycles -- ";
      tmpString = tmpString +& dumpCriticalPathInfo1(critPath,1);
      tmpString = " ;; " +& tmpString +& "critical path' with costs of "+&realString(costPathWoC)+&" cycles -- ";
      tmpString = tmpString +& dumpCriticalPathInfo1(critPathWoC,1);
  then
    tmpString;
  end matchcontinue;
end dumpCriticalPathInfo;

protected function dumpCriticalPathInfo1 "author:marcusw
  Helper function of dumpCriticalPathInfo. Dump one critical path."
  input list<list<Integer>> criticalPathsIn;
  input Integer cpIdx;
  output String oString;
algorithm
  oString := intLstString(listGet(criticalPathsIn,cpIdx))+&"";
end dumpCriticalPathInfo1;

public function printCriticalPathInfo "prints the criticalPath and the costs.
author:Waurich TUD 2013-07"
  input list<list<Integer>> criticalPathsIn;
  input Real cpCosts;
algorithm
  _ := matchcontinue(criticalPathsIn,cpCosts)
  case({},_)
    equation
    then
      ();
  else
    equation
    print("--------------------------------\n");
    print(" CRITICAL PATH INFO\n");
    print("--------------------------------\n");
    print("found "+&intString(listLength(criticalPathsIn))+&" critical paths with costs of "+&realString(cpCosts)+&" sec\n");
    printCriticalPathInfo1(criticalPathsIn,1);
  then
    ();
  end matchcontinue;
end printCriticalPathInfo;


protected function printCriticalPathInfo1"prints one criticalPath.
author: Waurich TUD 2013-07"
  input list<list<Integer>> criticalPathsIn;
  input Integer cpIdx;
algorithm
  print(intString(cpIdx)+&". path: "+&intLstString(listGet(criticalPathsIn,cpIdx))+&"\n");
end printCriticalPathInfo1;


// functions to merge single nodes
//------------------------------------------
//------------------------------------------

public function mergeSingleNodes"merges all single nodes. the max number of remaining single ndoes is numProc."
  input TaskGraph iTaskGraph;
  input TaskGraphMeta iTaskGraphMeta;
  input list<Integer> doNotMergeIn;
  output TaskGraph oTaskGraph;
  output TaskGraphMeta oTaskGraphMeta;
  output Boolean changed;
algorithm
  (oTaskGraph,oTaskGraphMeta,changed) := matchcontinue(iTaskGraph,iTaskGraphMeta,doNotMergeIn)
    local
      Integer numProc;
      list<Integer> singleNodes,singleNodes1,pos,doNotMerge;
      list<list<Integer>> clusterLst;
      list<Real> exeCosts;
      array<Real> costs;
      array<list<Integer>> cluster;
      TaskGraph taskGraphT;
    case(_,_,_)
      equation
        numProc = Flags.getConfigInt(Flags.NUM_PROC);
        taskGraphT = BackendDAEUtil.transposeMatrix(iTaskGraph,arrayLength(iTaskGraph));
        //get the single nodes, sort them according to their exeCosts in decreasing order
        (_,singleNodes) = List.filterOnTrueSync(arrayList(iTaskGraph),List.isEmpty,List.intRange(arrayLength(iTaskGraph)));  //nodes without successor
        (_,singleNodes1) = List.filterOnTrueSync(arrayList(taskGraphT),List.isEmpty,List.intRange(arrayLength(taskGraphT))); //nodes without predecessor
        (singleNodes,_,_) = List.intersection1OnTrue(singleNodes,singleNodes1,intEq);
        (_,singleNodes,_) = List.intersection1OnTrue(singleNodes,doNotMergeIn,intEq);
        exeCosts = List.map1(singleNodes,getExeCostReqCycles,iTaskGraphMeta);
        (exeCosts,pos) = HpcOmScheduler.quicksortWithOrder(exeCosts);
        singleNodes = List.map1(pos,List.getIndexFirst,singleNodes);
        singleNodes = listReverse(singleNodes);
        //print("singleNodes "+&stringDelimitList(List.map(singleNodes,intString),"\n")+&"\n");
        exeCosts = listReverse(exeCosts);
        // cluster these singleNodes
        (cluster,costs) = distributeToClusters(singleNodes,exeCosts,numProc);
        //print("cluster "+&stringDelimitList(List.map(arrayList(cluster),intLstString),"\n")+&"\n");
        //update taskgraph and taskgraphMeta
        clusterLst = arrayList(cluster);
        (oTaskGraph,oTaskGraphMeta) = contractNodesInGraph(clusterLst,iTaskGraph,iTaskGraphMeta);
        changed = intGt(listLength(singleNodes),numProc);
  then (oTaskGraph,oTaskGraphMeta,changed);
  else
    then (iTaskGraph,iTaskGraphMeta,false);
  end matchcontinue;
end mergeSingleNodes;

public function distributeToClusters"takes a list of items and corresponding values and clusters the items. The cluster are supposed to have an most equal distribution of accumulated values.
if the items list is shorter than the numProc, a cluster list containing empty lists is output
author:Waurich TUD 2014-06"
  input list<Integer> items;
  input list<Real> values;
  input Integer numClusters;
  output array<list<Integer>> clustersOut;
  output array<Real> clusterValuesOut;
protected
  Boolean b;
  array<Integer> itemArr;
  array<list<Integer>> itemsCopy, clusters;
  array<Real> clusterValues;
algorithm
  b := intGt(listLength(items),numClusters);
  clusters := listArray(List.map(List.intRange(listLength(items)),List.create));
  clusterValues := listArray(values);
  itemArr := listArray(items);
  itemsCopy := Util.arrayMap(itemArr,List.create);
  clusters := Debug.bcallret2(true,Util.arrayCopy,itemsCopy,clusters,clusters);
  clusterValues := Debug.bcallret2(not b,Util.arrayCopy,listArray(values),clusterValues,clusterValues);
  (clustersOut,clusterValuesOut) := Debug.bcallret3_2(b,distributeToClusters1,(items,values),(clusters,clusterValues),numClusters,clusters,clusterValues);
end distributeToClusters;

protected function distributeToClusters1
  input tuple<list<Integer>,list<Real>> tplIn;  //<items,values>
  input tuple<array<list<Integer>>,array<Real>> tplFold;  // <<a item mapping :item-> included items>, <item: added costs of all included items>>
  input Integer numClusters;
  output array<list<Integer>> clustersOut;
  output array<Real> clusterValuesOut;
algorithm
  (clustersOut,clusterValuesOut) := matchcontinue(tplIn,tplFold,numClusters)
    local
      Integer numCl, diff;
      list<Integer> itemsIn,lst1,lst1_1,lst1_2,idcsLst1_2,idcsLst2,idcsLst1;
      list<list<Integer>> entries,entries2;
      list<Real> valuesIn,values,addValues;
      array<list<Integer>> clusters, clustersFinal;
      array<Real> clusterValues, clusterValuesFinal;
  case((itemsIn,valuesIn),(clusters,clusterValues),_)
    equation
      true = listLength(itemsIn) <= numClusters;
      idcsLst1 = List.intRange(numClusters);
      clustersFinal = Util.arraySelect(clusters,idcsLst1);
      clusterValuesFinal = Util.arraySelect(clusterValues,idcsLst1);
    then (clustersFinal,clusterValuesFinal);
  case((itemsIn,valuesIn),(clusters,clusterValues),_)
    equation
      true = listLength(itemsIn) > numClusters;
      true = listLength(itemsIn)/2 < numClusters;
      (lst1,_) = List.split(itemsIn,numClusters);  // split the list of items+dummies in the middle
      diff = listLength(itemsIn) - numClusters;
      idcsLst1 = List.intRange2(numClusters-diff+1,numClusters);
      idcsLst2 = List.intRange2(numClusters+1,listLength(itemsIn));
      // update the clusters array
      entries = List.map1(idcsLst2,Util.arrayGetIndexFirst,clusters);
      entries = listReverse(entries);
      entries2 = List.map1(idcsLst1,Util.arrayGetIndexFirst,clusters);
      entries = List.threadMap(entries,entries2,listAppend);
      List.threadMap1_0(idcsLst1,entries,Util.arrayUpdateIndexFirst,clusters);
      // update the clusterValues array
      values = List.map1(idcsLst1,Util.arrayGetIndexFirst,clusterValues);
      addValues = List.map1(idcsLst2,Util.arrayGetIndexFirst,clusterValues);
      values = List.threadMap(values,addValues,realAdd);
      List.threadMap1_0(idcsLst1,values,Util.arrayUpdateIndexFirst,clusterValues);
      // finish
      (clusters,clusterValues) = distributeToClusters1((lst1,valuesIn),(clusters,clusterValues),numClusters);
    then (clusters,clusterValues);
  case((itemsIn,valuesIn),(clusters,clusterValues),_)
    equation
      true = listLength(itemsIn) > numClusters;
      true = listLength(itemsIn)/2 >= numClusters;
      numCl = nextGreaterPowerOf2(intReal(listLength(itemsIn)));
      (lst1,_) = List.split(itemsIn,intDiv(numCl,2));  // split the list of items+dummies in the middle
      // update the clusters array
      idcsLst2 = List.intRange2(intDiv(numCl,2)+1,listLength(itemsIn));
      idcsLst1_2 = List.intRange2(intDiv(numCl,2)-listLength(idcsLst2)+1, intDiv(numCl,2));
      entries = List.map1(idcsLst2,Util.arrayGetIndexFirst,clusters);  // the clustered task from  the second list
      entries = listReverse(entries);
      entries2 = List.map1(idcsLst1_2,Util.arrayGetIndexFirst,clusters);
      entries = List.threadMap(entries,entries2,listAppend);
      List.threadMap1_0(idcsLst1_2,entries,Util.arrayUpdateIndexFirst,clusters);
      // update the clusterValues array
      values = List.map1(idcsLst1_2,Util.arrayGetIndexFirst,clusterValues);
      addValues = List.map1(idcsLst2,Util.arrayGetIndexFirst,clusterValues);
      values = List.threadMap(values,addValues,realAdd);
      List.threadMap1_0(idcsLst1_2,values,Util.arrayUpdateIndexFirst,clusterValues);
      // again
      (clusters,clusterValues) = distributeToClusters1((lst1,valuesIn),(clusters,clusterValues),numClusters);
    then (clusters,clusterValues);
  else
    equation
      print("distributeToClusters failed!\n");
    then fail();
  end matchcontinue;
end distributeToClusters1;

protected function nextGreaterPowerOf2"finds the next greater power of 2.
author :Waurich TUD 2014-06"
  input Real n;
  output Integer powOf2;
algorithm
  powOf2 := nextGreaterPowerOf2_impl(n,1);
end nextGreaterPowerOf2;

protected function nextGreaterPowerOf2_impl
  input Real n;
  input Integer pow;
  output Integer powOf2;
algorithm
  powOf2 := matchcontinue(n,pow)
  local
    Integer n2;
  case(_,_)
    equation
      true = n <=. realPow(2.0,intReal(pow));
    then realInt(realPow(2.0,intReal(pow)));
  case(_,_)
    equation
      true = n >. realPow(2.0,intReal(pow));
      n2 = nextGreaterPowerOf2_impl(n,pow+1);
    then n2;
  end matchcontinue;
end nextGreaterPowerOf2_impl;


// functions to merge simple nodes
//------------------------------------------
//------------------------------------------


public function mergeSimpleNodes " merges all nodes in the graph that have only one predecessor and one successor.
author: Waurich TUD 2013-07"
  input TaskGraph graphIn;
  input TaskGraphMeta graphDataIn;
  input list<Integer> doNotMerge;
  output TaskGraph graphOut;
  output TaskGraphMeta graphDataOut;
  output Boolean oChanged;
protected
  array<list<Integer>> inComps;
  array<tuple<Integer, Integer, Integer>> varCompMapping;
  array<tuple<Integer,Integer,Integer>> eqCompMapping;
  list<Integer> rootNodes;
  array<String> nodeNames;
  array<String> nodeDescs;
  array<tuple<Integer,Real>> exeCosts;
  array<list<tuple<Integer,Integer,Integer>>> commCosts;
  array<Integer> nodeMark;
  TaskGraph graphTmp;
  TaskGraphMeta graphDataTmp;
  list<Integer> noMerging;
  list<list<Integer>> oneChildren;
  list<Integer> allTheNodes;
  String fileName;
algorithm
  TASKGRAPHMETA(inComps = inComps, varCompMapping=varCompMapping, eqCompMapping=eqCompMapping, rootNodes = rootNodes, nodeNames =nodeNames,nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) := graphDataIn;
  allTheNodes := List.intRange(arrayLength(graphIn));  // to traverse the node indeces
  oneChildren := findOneChildParents(allTheNodes,graphIn,doNotMerge,{{}},0);  // paths of nodes with just one successor per node (extended: and endnodes with just one parent node)
  oneChildren := listDelete(oneChildren,listLength(oneChildren)-1); // remove the empty startValue {}
  oneChildren := List.removeOnTrue(1,compareListLengthOnTrue,oneChildren);  // remove paths of length 1
  //print("oneChildren "+&stringDelimitList(List.map(oneChildren,intLstString),"\n")+&"\n");
  (graphOut,graphDataOut) := contractNodesInGraph(oneChildren,graphIn,graphDataIn);
  oChanged := List.isNotEmpty(oneChildren);
end mergeSimpleNodes;

public function mergeParentNodes "author: marcusw
  Merges parent nodes into child if this produces a shorter execution time. Only one merge set is determined. you have to repeat this function"
  input TaskGraph iGraph;
  input TaskGraphMeta iGraphData;
  input list<Integer> doNotMerge;
  output TaskGraph oGraph;
  output TaskGraphMeta oGraphData;
  output Boolean oChanged; //true if the structure has changed
protected
  TaskGraph iGraphT;
  list<list<Integer>> mergedNodes;
algorithm
  iGraphT := transposeTaskGraph(iGraph);
  mergedNodes := mergeParentNodes0(iGraph, iGraphT, iGraphData, doNotMerge, 1, {});
  (oGraph,oGraphData) := contractNodesInGraph(mergedNodes, iGraph, iGraphData);
  oChanged := List.isNotEmpty(mergedNodes);
end mergeParentNodes;

protected function mergeParentNodes0
  input TaskGraph iGraph;
  input TaskGraph iGraphT;
  input TaskGraphMeta iGraphData;
  input list<Integer> doNotMerge;
  input Integer iNodeIdx;
  input list<list<Integer>> iMergedNodes;
  output list<list<Integer>> oMergedNodes;
protected
  TaskGraph tmpGraph;
  TaskGraphMeta tmpGraphData;
  Boolean tmpChanged;
  Real exeCost, highestParentExeCost, sumParentExeCosts;
  list<Integer> parentNodes, mergeNodeList;
  Integer highestCommCost;
  array<tuple<Integer, Real>> exeCosts;
  list<tuple<Integer, Real>> parentExeCosts;
  array<list<tuple<Integer, Integer, Integer>>> commCosts;
  list<tuple<Integer, Integer, Integer>> parentCommCosts;
  list<list<Integer>> parentChilds;
  list<list<Integer>> tmpMergedNodes;
algorithm
  oMergedNodes := matchcontinue(iGraph, iGraphT, iGraphData, doNotMerge,  iNodeIdx, iMergedNodes)
    case(_,_,TASKGRAPHMETA(exeCosts=exeCosts, commCosts=commCosts),_,_,_)
      equation
        true = intLe(iNodeIdx, arrayLength(iGraphT)); //Current index is in range
        true = List.notMember(iNodeIdx,doNotMerge);
        parentNodes = arrayGet(iGraphT, iNodeIdx);
        false = List.exist1(parentNodes,listMember,doNotMerge);
        //print("HpcOmTaskGraph.mergeParentNodes0: looking at node " +& intString(iNodeIdx) +& "\n");
        parentCommCosts = List.map2(parentNodes, getCommCostBetweenNodes, iNodeIdx, iGraphData);
        ((_,_,highestCommCost)) = getHighestCommCost(parentCommCosts, (-1,-1,-1));
        parentExeCosts = List.map1(parentNodes, getExeCost, iGraphData);
        ((_,sumParentExeCosts)) = List.fold(parentExeCosts, addUpExeCosts, (0,0.0));
        ((_,highestParentExeCost)) = getHighestExecCost(parentExeCosts, (0,0.0));
        true = realGt(realAdd(intReal(highestCommCost), highestParentExeCost), sumParentExeCosts);
        //We can only merge the parents if they have no other child-nodes -> check this
        parentChilds = List.map1(parentNodes, Util.arrayGetIndexFirst, iGraph);
        true = intEq(listLength(List.removeOnTrue(1, intEq, List.map(parentChilds, listLength))), 0);
        mergeNodeList = iNodeIdx :: parentNodes;
        //print("HpcOmTaskGraph.mergeParentNodes0: mergeNodeList " +& stringDelimitList(List.map(mergeNodeList,intString), ", ") +& "\n");
        //print("HpcOmTaskGraph.mergeParentNodes0: Merging " +& intString(iNodeIdx) +& " with " +& stringDelimitList(List.map(parentNodes,intString), ", ") +& "\n");
        //(tmpGraph,tmpGraphData) = contractNodesInGraph({mergeNodeList}, iGraph, iGraphData);
        //(tmpGraph,tmpGraphData) = (iGraph, iGraphData);
        tmpMergedNodes = mergeNodeList :: iMergedNodes;
        //tmpMergedNodes = mergeParentNodes0(iGraph,iGraphT,iGraphData,iNodeIdx+1,tmpMergedNodes);
      then tmpMergedNodes;
    case(_,_,_,_,_,_)
      equation
        true = intLe(iNodeIdx, arrayLength(iGraphT)); //Current index is in range
        tmpMergedNodes = mergeParentNodes0(iGraph,iGraphT,iGraphData,doNotMerge,iNodeIdx+1,iMergedNodes);
      then tmpMergedNodes;
    else iMergedNodes;
  end matchcontinue;
end mergeParentNodes0;

protected function addUpExeCosts
  input tuple<Integer,Real> iExeCost1;
  input tuple<Integer,Real> iExeCost2;
  output tuple<Integer,Real> oExeCost;
protected
  Real ex1,ex2;
  Integer op1,op2;
algorithm
  (op1,ex1) := iExeCost1;
  (op2,ex2) := iExeCost2;
  oExeCost := ((op1+op2,realAdd(ex1,ex2)));
end addUpExeCosts;

public function getExeCostReqCycles"author: waurich
  gets the execution cost of the node in cycles."
  input Integer iNodeIdx;
  input TaskGraphMeta iGraphData;
  output Real oExeCost;
protected
  array<list<Integer>> inComps;
  list<Integer> comps;
  array<tuple<Integer, Real>> exeCosts;
  tuple<Integer,Real> tmpExeCost;
algorithm
  TASKGRAPHMETA(inComps=inComps, exeCosts=exeCosts) := iGraphData;
  tmpExeCost := (0,0.0);
  comps := arrayGet(inComps, iNodeIdx);
  ((_,oExeCost)) := List.fold1(comps, getExeCost0, exeCosts, tmpExeCost);
end getExeCostReqCycles;

public function getExeCost "author: marcusw
  gets the execution cost of the node."
  input Integer iNodeIdx;
  input TaskGraphMeta iGraphData;
  output tuple<Integer,Real> oExeCost;
protected
  array<list<Integer>> inComps;
  list<Integer> comps;
  array<tuple<Integer, Real>> exeCosts;
  tuple<Integer,Real> tmpExeCost;
algorithm
  TASKGRAPHMETA(inComps=inComps, exeCosts=exeCosts) := iGraphData;
  tmpExeCost := (0,0.0);
  comps := arrayGet(inComps, iNodeIdx);
  oExeCost := List.fold1(comps, getExeCost0, exeCosts, tmpExeCost);
end getExeCost;

protected function getExeCost0 "author: marcusw
  Helper function of getExeCost."
  input Integer iCompIdx;
  input array<tuple<Integer, Real>> iExeCosts;
  input tuple<Integer,Real> iExeCost;
  output tuple<Integer,Real> oExeCost;
protected
  Real exeCost, exeCost1;
  Integer opCount, opCount1;
algorithm
  ((opCount,exeCost)) := arrayGet(iExeCosts, iCompIdx);
  (opCount1,exeCost1) := iExeCost;
  oExeCost := ((opCount+opCount1,realAdd(exeCost,exeCost1)));
end getExeCost0;

protected function getHighestExecCost "function getHighestExecCost
  author: marcusw
  Get the communication with highest costs out of the given list."
  input list<tuple<Integer, Real>> iExecCosts;
  input tuple<Integer, Real> iHighestTuple;
  output tuple<Integer, Real> oHighestTuple;
protected
  Real highestCost, currentCost;
  tuple<Integer, Real> head;
  list<tuple<Integer, Real>> rest;
algorithm
  oHighestTuple := matchcontinue(iExecCosts, iHighestTuple)
    case((head as (_,currentCost))::rest, (_,highestCost))
      equation
        true = realGt(currentCost, highestCost);
      then getHighestExecCost(rest, head);
    case((head as (_,currentCost))::rest, (_,highestCost))
      equation
        true = realGt(currentCost, highestCost);
      then getHighestExecCost(rest, iHighestTuple);
    else iHighestTuple;
  end matchcontinue;
end getHighestExecCost;

protected function contractNodesInGraph " function to contract the nodes given in the list to one node.
author: Waurich TUD 2013-07"
  input list<list<Integer>> contractNodes; //a list containing a list with nodes you want to merge
  input TaskGraph graphIn;
  input TaskGraphMeta graphDataIn;
  output TaskGraph graphOut;
  output TaskGraphMeta graphDataOut;
protected
  TaskGraph graphTmp;
  list<Integer> deleteNodes;
  list<list<Integer>> graphTmpLst;
algorithm
  deleteNodes := List.fold1(contractNodes,getMergeSet,graphIn,{}); //removes the last node in the path for every list of contracted paths
  graphTmp := List.fold(contractNodes,contractNodesInGraph1,graphIn);
  //graphTmp = removeEntriesInGraph(graphIn,deleteNodes);
  graphTmpLst := arrayList(graphIn);
  graphTmpLst := List.map1(graphTmpLst,updateContinuousEntriesInList,List.unique(deleteNodes));
  graphTmp := listArray(graphTmpLst);
  (graphTmp,_) := deleteRowInAdjLst(graphTmp,deleteNodes);
  graphDataOut := getMergedSystemData(graphDataIn,contractNodes);
  graphOut := graphTmp;
end contractNodesInGraph;

protected function contractNodesInGraph1 " function to contract the nodes given in the list to one node, without deleting the rows in the adjacencyLst.
author: Waurich TUD 2013-07"
  input list<Integer> contractNodes;
  input TaskGraph graphIn;
  output TaskGraph graphOut;
protected
  TaskGraph graphInT;
  Integer endNode;
  Integer startNode;
  list<Integer> deleteEntries;
  list<Integer> startNodeChildren;
  list<Integer> endChildren;
  list<Integer> deleteNodesParents; //all parents of deleted nodes
  TaskGraph graphTmp;
algorithm
  //This function contracts all nodes into the startNode
  graphInT := transposeTaskGraph(graphIn);
  //print("HpcOmTaskGraph.contractNodesInGraph1 contractNodes: " +& stringDelimitList(List.map(contractNodes,intString),",") +& "\n");
  //print("HpcOmTaskGraph.contractNodesInGraph1 startNode: " +& intString(List.last(contractNodes)) +& "\n");
  startNode := List.last(contractNodes);
  deleteEntries := List.deleteMember(contractNodes,startNode); //all nodes which should be deleted
  //print("HpcOmTaskGraph.contractNodesInGraph1 deleteEntries: " +& stringDelimitList(List.map(deleteEntries,intString),",") +& "\n");
  deleteNodesParents := List.flatten(List.map1(deleteEntries, Util.arrayGetIndexFirst, graphInT));
  //print("HpcOmTaskGraph.contractNodesInGraph1 deleteNodesParents: " +& stringDelimitList(List.map(deleteNodesParents,intString),",") +& "\n");
  deleteNodesParents := List.sortedUnique(List.sort(deleteNodesParents, intGt),intEq);
  deleteNodesParents := List.setDifferenceOnTrue(deleteNodesParents, contractNodes, intEq);
  //print("HpcOmTaskGraph.contractNodesInGraph1 deleteNodesParents: " +& stringDelimitList(List.map(deleteNodesParents,intString),",") +& "\n");
  endNode := List.first(contractNodes);
  endChildren := arrayGet(graphIn,endNode); //all child-nodes of the end node
  //print("HpcOmTaskGraph.contractNodesInGraph1 endChildren: " +& stringDelimitList(List.map(endChildren,intString),",") +& "\n");
  startNodeChildren := arrayGet(graphIn, startNode);
  //print("HpcOmTaskGraph.contractNodesInGraph1 startNodeChildren_pre: " +& stringDelimitList(List.map(startNodeChildren,intString),",") +& "\n");
  startNodeChildren := List.setDifferenceOnTrue(startNodeChildren, deleteEntries, intEq);
  graphTmp := arrayUpdate(graphIn, startNode, startNodeChildren);
  //print("HpcOmTaskGraph.contractNodesInGraph1 startNodeChildren_post: " +& stringDelimitList(List.map(startNodeChildren,intString),",") +& "\n");
  graphTmp := List.fold2(deleteNodesParents, contractNodesInGraph2, deleteEntries, startNode, graphTmp);
  //print("HpcOmTaskGraph.contractNodesInGraph1 startnode: " +& intString(startNode) +& " endChildren: " +& stringDelimitList(List.map(endChildren,intString),",") +& "\n");
  graphTmp := arrayUpdate(graphIn,startNode,endChildren);
  graphOut := graphTmp;
end contractNodesInGraph1;

protected function contractNodesInGraph2
  input Integer iParentNode;
  input list<Integer> iDeletedNodes;
  input Integer iNewNodeIdx;
  input TaskGraph iGraph;
  output TaskGraph oGraph;
protected
  list<Integer> adjLstEntry;
algorithm
  adjLstEntry := arrayGet(iGraph,iParentNode);
  //print("contractNodesInGraph2 ParentNode: " +& intString(iParentNode) +& " adjLstEntry_Pre: " +& stringDelimitList(List.map(adjLstEntry,intString),",") +& "\n");
  adjLstEntry := List.setDifferenceOnTrue(adjLstEntry, iDeletedNodes, intEq);
  adjLstEntry := iNewNodeIdx :: adjLstEntry;
  adjLstEntry := List.sortedUnique(List.sort(adjLstEntry, intGt),intEq);
  //print("contractNodesInGraph2 ParentNode: " +& intString(iParentNode) +& " adjLstEntry_Post: " +& stringDelimitList(List.map(adjLstEntry,intString),",") +& "\n");
  oGraph := arrayUpdate(iGraph, iParentNode, adjLstEntry);
end contractNodesInGraph2;

protected function compareListLengthOnTrue " is true if given list has a length of inValue, otherwise false.
author: Waurich TUD 2013-07"
  input Integer inValue;
  input list<Integer> inLst;
  output Boolean equalLength;
algorithm
  equalLength := matchcontinue(inValue,inLst)
    case(_,_)
      equation
        true = intEq(inValue,listLength(inLst));
      then
        true;
    else
      then
        false;
  end matchcontinue;
end compareListLengthOnTrue;

protected function getMergeSet "get the nodes that have to be deletedfrom the adjacencyLst because they are merged i.e.  all nodes of a path except the first
author: Waurich TUD 2013-07"
  input list<Integer> contractNodes;
  input TaskGraph graphIn;
  input list<Integer> nodesIn;
  output list<Integer> nodesOut;
protected
  Integer startNode;
  list<Integer> deleteEntries;
algorithm
  startNode := List.last(contractNodes);
  deleteEntries := List.deleteMember(contractNodes,startNode);
  nodesOut := listAppend(deleteEntries,nodesIn);
end getMergeSet;

protected function getMergedSystemData " udpates the taskgraphmetadata for the merged system.
author:Waurich TUD 2013-07"
  input TaskGraphMeta graphDataIn;
  input list<list<Integer>> contractNodes;
  output TaskGraphMeta graphDataOut;
protected
  array<list<Integer>> inComps;
  array<tuple<Integer, Integer, Integer>> varCompMapping;
  array<tuple<Integer,Integer,Integer>> eqCompMapping;
  list<Integer> rootNodes;
  array<String> nodeNames;
  array<String> nodeDescs;
  array<tuple<Integer,Real>> exeCosts;
  array<list<tuple<Integer,Integer,Integer>>> commCosts;
  array<Integer>nodeMark;
  list<list<Integer>> inCompsLst;
algorithm
  TASKGRAPHMETA(inComps = inComps, varCompMapping=varCompMapping, eqCompMapping=eqCompMapping, rootNodes = rootNodes, nodeNames =nodeNames, nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) := graphDataIn;
  inComps := updateInCompsForMerging(inComps,contractNodes);
  rootNodes := rootNodes;
  nodeNames := List.fold2(List.intRange(arrayLength(nodeNames)),updateNodeNamesForMerging,inComps,nodeMark,nodeNames);
  nodeDescs := nodeDescs;
  exeCosts := exeCosts;
  commCosts := commCosts;
  nodeMark := nodeMark;
  graphDataOut := TASKGRAPHMETA(inComps,varCompMapping,eqCompMapping,rootNodes,nodeNames,nodeDescs,exeCosts,commCosts,nodeMark);
end getMergedSystemData;

public function updateNodeNamesForMerging " updates the nodeNames with the merging information.
author:Waurich TUD 2013-07"
  input Integer compIdx;
  input array<list<Integer>> inComps;
  input array<Integer> nodeMark;
  input array<String> nodeNamesIn;
  output array<String> nodeNamesOut;
algorithm
  nodeNamesOut := matchcontinue(compIdx,inComps,nodeMark,nodeNamesIn)
    local
      Integer unionNode;
      list<Integer> mergedComps;
      array<String> nodeNamesTmp;
      String nodeName;
    case(_,_,_,_)
      equation
        true = compIdx <= arrayLength(nodeNamesIn);
        unionNode = getCompInComps(compIdx,1,inComps,nodeMark); //TODO: that seems to be expensive, can we iterate over the nodes instead of the components?
        true = unionNode <> -1;
        mergedComps = arrayGet(inComps,unionNode);
        true = listLength(mergedComps) == 1;
      then
        nodeNamesIn;
    case(_,_,_,_)
      equation
       true = compIdx <= arrayLength(nodeNamesIn);
       unionNode = getCompInComps(compIdx,1,inComps,nodeMark);
       true = unionNode <> -1;
       mergedComps = arrayGet(inComps,unionNode);
       false = listLength(mergedComps) == 1;
       nodeName = "contracted comps "+&stringDelimitList(List.map(mergedComps,intString),",");
       nodeNamesTmp = arrayUpdate(nodeNamesIn,compIdx,nodeName);
     then
       nodeNamesTmp;
     case(_,_,_,_)
      equation
       true = compIdx <= arrayLength(nodeNamesIn);
       unionNode = getCompInComps(compIdx,1,inComps,nodeMark);
       true = unionNode == -1;
     then
       nodeNamesIn;
     else
      equation
        print("updateNodeNamesForMerging failed!\n");
      then fail();
   end matchcontinue;
end updateNodeNamesForMerging;


protected function updateInCompsForMerging " updates the inComps with the merging information.
author:waurich TUD 2013-07"
  input array<list<Integer>> inCompsIn;
  input list<list<Integer>> mergedPaths; //nodes to contract
  output array<list<Integer>> inCompsOut;
protected
  array<list<Integer>> inCompsTmp;
  list<list<Integer>> inCompsLst;
  list<Integer> deleteNodes;
  list<Integer> startNodes;
algorithm
  //mergedPaths := List.map1(mergedPaths,List.sort,intGt);
  startNodes := List.map(mergedPaths,List.last);
  //startNodes := List.map(mergedPaths,List.first);
  (_,deleteNodes,_) := List.intersection1OnTrue(List.flatten(mergedPaths),startNodes,intEq);
  //deleteNodes := List.map(mergedPaths,List.rest);
  inCompsLst := arrayList(inCompsIn);
  inCompsLst := List.fold2(List.intRange(arrayLength(inCompsIn)),updateInComps1,(startNodes,deleteNodes,mergedPaths),inCompsIn,inCompsLst);
  inCompsLst := List.removeOnTrue({},equalLists,inCompsLst);
  //inCompsLst := List.map3(inCompsLst,getCompInComps,1,inComps,arrayCreate(arrayLength(inComps),0));
  inCompsOut := listArray(inCompsLst);
end updateInCompsForMerging;


protected function updateInComps1 " folding function for updateInComps.
author:waurich TUD 2013-07"
  input Integer nodeIdx;
  input tuple<list<Integer>,list<Integer>,list<list<Integer>>> mergeInfo; //<%startNodes,deleteNodes,mergedPaths%>
  input array<list<Integer>> primInComps;
  input list<list<Integer>> inCompLstIn;
  output list<list<Integer>> inCompLstOut;
algorithm
  inCompLstOut := matchcontinue(nodeIdx,mergeInfo,primInComps,inCompLstIn)
    local
      Integer mergeGroupIdx;
      list<Integer> inComps;
      Integer inComp;
      list<Integer> mergedSet, mergedNodes;
      list<Integer> startNodes;
      list<Integer> deleteNodes;
      list<list<Integer>> mergedPaths;
      list<list<Integer>> inCompLstTmp;
    case(_,_,_,_)
      // the given node is a startNode
      equation
        (startNodes,_,mergedPaths) = mergeInfo;
        //print("updateInComps1 startNodes:" +& stringDelimitList(List.map(startNodes,intString),",") +& "\n");
        //print("updateInComps1 deleteNodes:" +& stringDelimitList(List.map(deleteNodes,intString),",") +& "\n");
        //print("updateInComps1 first mergedPath:" +& stringDelimitList(List.map(List.first(mergedPaths),intString),",") +& "\n");
        inComps = listGet(inCompLstIn,nodeIdx);
        //print("updateInComps1 inComps:" +& stringDelimitList(List.map(inComps,intString),",") +& "\n");
        //true = listLength(inComps) == 1;
        _ = listGet(inComps,1);
        //print("updateInComps1 inComp:" +& intString(inComp) +& "\n");
        true = List.isMemberOnTrue(nodeIdx,startNodes,intEq);
        mergeGroupIdx = List.position(nodeIdx,startNodes)+1;
        mergedNodes = listGet(mergedPaths,mergeGroupIdx);
        //print("updateInComps1 mergedNodes:" +& stringDelimitList(List.map(mergedNodes,intString),",") +& "\n");
        mergedSet = List.flatten(List.map1(mergedNodes,Util.arrayGetIndexFirst,primInComps));
        //print("updateInComps1 mergedSet:" +& stringDelimitList(List.map(mergedSet,intString),",") +& "\n");
        inCompLstTmp = List.fold(mergedNodes, updateInComps2, inCompLstIn);
        inCompLstTmp = List.replaceAt(mergedSet,nodeIdx-1,inCompLstTmp);
      then
        inCompLstTmp;
    else
      then
        inCompLstIn;
  end matchcontinue;
end updateInComps1;

protected function updateInComps2 "Replaces the entry <%iNodeIdx - 1%> in inCompListIn with an empty set"
  input Integer iNodeIdx;
  input list<list<Integer>> inCompLstIn;
  output list<list<Integer>> inCompLstOut;
algorithm
  inCompLstOut := List.replaceAt({},iNodeIdx-1,inCompLstIn);
end updateInComps2;

protected function equalLists " compares two lists and sets true if they are equal.
author:Waurich TUD 2013-07"
  input list<Integer> inList1;
  input list<Integer> inList2;
  output Boolean outIsEqual;
algorithm
  outIsEqual := matchcontinue(inList1, inList2)
    local
      Integer e1, e2;
      list<Integer> rest1, rest2;

    case ({}, {}) then true;
    case ({}, _) then false;
    case (_, {}) then false;
    case (e1 :: rest1, e2 :: rest2)
      equation
        true = intEq(e1,e2);
      then
        equalLists(rest1, rest2);
    else false;
  end matchcontinue;
end equalLists;


protected function findOneChildParents " fold function to find nodes or paths in the taskGraph with just one successor per node.
extended: adds endnodes without successor as well
author: Waurich TUD 2013-07"
  input list<Integer> allNodes;
  input TaskGraph graphIn;
  input list<Integer> doNotMerge;  // these nodes cannot be chosen
  input list<list<Integer>> lstIn;
  input Integer inPath;  // the current nodeIndex in a path of only cildren. if no path then 0.
  output list<list<Integer>> lstOut;
algorithm
  lstOut := matchcontinue(allNodes,graphIn,doNotMerge,lstIn,inPath)
    local
      Integer child;
      Integer head;
      list<Integer> nodeChildren;
      list<Integer> parents;
      list<Integer> pathLst;
      list<Integer> rest;
      list<list<Integer>> lstTmp;
    case({},_,_,_,_)
      //checked all nodes
      equation
        then
          lstIn;
    case((head::rest),_,_,_,_)
      //check new node that has several children
      equation
        true = intEq(inPath,0);
        nodeChildren = arrayGet(graphIn,head);
        false = listLength(nodeChildren) == 1;
        lstTmp = findOneChildParents(rest,graphIn,doNotMerge,lstIn,0);
      then
        lstTmp;
    case((head::rest),_,_,_,_)
      //check new node that is excluded
      equation
        true = intEq(inPath,0);
        true = listMember(head,doNotMerge);
        lstTmp = findOneChildParents(rest,graphIn,doNotMerge,lstIn,0);
      then
        lstTmp;
    case((head::rest),_,_,_,_)
      // check new node that has only one child but this is excluded
      equation
        true = intEq(inPath,0);
        nodeChildren = arrayGet(graphIn,head);
        true = listLength(nodeChildren) == 1;
        child = listGet(nodeChildren,1);
        true = listMember(child,doNotMerge);
        lstTmp = findOneChildParents(rest,graphIn,doNotMerge,lstIn,child);
      then
        lstTmp;
    case((head::rest),_,_,_,_)
      // check new node that has only one child , follow the path
      equation
        true = intEq(inPath,0);
        nodeChildren = arrayGet(graphIn,head);
        true = listLength(nodeChildren) == 1;
        child = listGet(nodeChildren,1);
        lstTmp = {head}::lstIn;
        lstTmp = findOneChildParents(rest,graphIn,doNotMerge,lstTmp,child);
      then
        lstTmp;
    case(_,_,_,_,_)
      // dont follow because the path contains excluded nodes
      equation
        false = intEq(inPath,0);
        true = listMember(inPath,doNotMerge);
        lstTmp = findOneChildParents(allNodes,graphIn,doNotMerge,lstIn,0);
      then
        lstTmp;
    case(_,_,_,_,_)
      // follow path and check that there is still only one child with just one parent
      equation
        false = intEq(inPath,0);
        nodeChildren = arrayGet(graphIn,inPath);
        parents = getParentNodes(inPath,graphIn);
        true = listLength(nodeChildren) == 1 and List.isNotEmpty(nodeChildren) and listLength(parents) == 1;
        child = listGet(nodeChildren,1);
        pathLst = List.first(lstIn);
        pathLst = inPath::pathLst;
        lstTmp = List.replaceAt(pathLst,0,lstIn);
        rest = List.deleteMember(allNodes,inPath);
        lstTmp = findOneChildParents(rest,graphIn,doNotMerge,lstTmp,child);
      then
        lstTmp;
    case(_,_,_,_,_)
      // follow path and check that there is an endnode without successor that will be added to the path
      equation
        false = intEq(inPath,0);
        nodeChildren = arrayGet(graphIn,inPath);
        parents = getParentNodes(inPath,graphIn);
        true = List.isEmpty(nodeChildren) and listLength(parents) == 1;
        pathLst = List.first(lstIn);
        pathLst = inPath::pathLst;
        lstTmp = List.replaceAt(pathLst,0,lstIn);
        rest = List.deleteMember(allNodes,inPath);
        lstTmp = findOneChildParents(rest,graphIn,doNotMerge,lstTmp,0);
      then
        lstTmp;
    case(_,_,_,_,_)
      // follow path and check that there are more children or a child with more parents. end path before this node
      equation
        false = intEq(inPath,0);
        nodeChildren = arrayGet(graphIn,inPath);
        parents = getParentNodes(inPath,graphIn);
        lstTmp = findOneChildParents(allNodes,graphIn,doNotMerge,lstIn,0);
      then
        lstTmp;
    else
      equation
        print("findOneChildParents failed\n");
      then
        fail();
  end matchcontinue;
end findOneChildParents;


protected function getParentNodes " function to get the parent nodes of a node.
author:Waurich TUD 2013-07"
  input Integer nodeIdx;
  input TaskGraph graphIn;
  output list<Integer> parentNodes;
protected
algorithm
  parentNodes := List.fold2(List.intRange(arrayLength(graphIn)),getParentNodes1,nodeIdx,graphIn,{});
end getParentNodes;


protected function getParentNodes1 " fold funtion to parse the graph for getParentNodes.
author:Waurich TUD 2013-07"
  input Integer nodeIdx;
  input Integer childNode;
  input TaskGraph graphIn;
  input list<Integer> parentLstIn;
  output list<Integer> parentLstOut;
algorithm
  parentLstOut := matchcontinue(nodeIdx,childNode,graphIn,parentLstIn)
    local
      list<Integer> parentLstTmp;
      list<Integer> graphRow;
    case(_,_,_,_)
      equation
        graphRow = arrayGet(graphIn,nodeIdx);
        false = List.isMemberOnTrue(childNode,graphRow,intEq);
      then
        parentLstIn;
    case(_,_,_,_)
      equation
        graphRow = arrayGet(graphIn,nodeIdx);
        true = List.isMemberOnTrue(childNode,graphRow,intEq);
        parentLstTmp = nodeIdx::parentLstIn;
      then
        parentLstTmp;
  end matchcontinue;
end getParentNodes1;


protected function checkParentNode "fold function to check the first element in the child path for the number of parent nodes.if the number is 1 the parent will be added.
author:Waurich TUD 2013-06"
  input Integer lstIdx;
  input TaskGraph graphIn;
  input list<list<Integer>> lstIn;
  output list<list<Integer>> lstOut;
algorithm
  lstOut := matchcontinue(lstIdx,graphIn,lstIn)
    local
      list<Integer> childLst;
      Integer child;
      Integer parent;
      list<Integer> parents;
      list<list<Integer>> lstTmp;
  case(_,_,_)
    equation
      childLst = listGet(lstIn,lstIdx);
      child = List.last(childLst);
      parents = getParentNodes(child,graphIn);
      true = intEq(listLength(parents),1);
      parent = listGet(parents,1);
      childLst = listReverse(childLst);
      childLst = parent :: childLst;
      childLst = listReverse(childLst);
      lstTmp = List.replaceAt(childLst, lstIdx-1, lstIn);
      then
        lstTmp;
  case(_,_,_)
    equation
      childLst = listGet(lstIn,lstIdx);
      child = List.last(childLst);
      parents = getParentNodes(child,graphIn);
      false = intEq(listLength(parents),1);
      then
        lstIn;
  end matchcontinue;
end checkParentNode;


//other public functions
//------------------------------------------
//------------------------------------------


public function copyTaskGraphMeta "copies the metadata to avoid overwriting the arrays.
author: Waurich TUD 2013-07"
  input TaskGraphMeta graphDataIn;
  output TaskGraphMeta graphDataOut;
protected
  array<list<Integer>> inComps, inComps1;
  array<tuple<Integer, Integer, Integer>> varCompMapping, varCompMapping1;
  array<tuple<Integer,Integer,Integer>>  eqCompMapping, eqCompMapping1;
  list<Integer> rootNodes, rootNodes1;
  array<String> nodeNames, nodeNames1;
  array<String> nodeDescs, nodeDescs1;
  array<tuple<Integer,Real>> exeCosts, exeCosts1;
  array<list<tuple<Integer,Integer,Integer>>> commCosts, commCosts1;
  array<Integer>nodeMark, nodeMark1;
algorithm
  TASKGRAPHMETA(inComps = inComps, varCompMapping=varCompMapping, eqCompMapping=eqCompMapping, rootNodes = rootNodes, nodeNames =nodeNames, nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) := graphDataIn;
  inComps1 := arrayCopy(inComps);
  varCompMapping1 := arrayCopy(varCompMapping);
  eqCompMapping1 := arrayCopy(eqCompMapping);
  rootNodes1 := rootNodes;
  nodeNames1 := arrayCopy(nodeNames);
  nodeDescs1 :=  arrayCopy(nodeDescs);
  exeCosts1 := arrayCopy(exeCosts);
  commCosts1 :=  arrayCopy(commCosts);
  nodeMark1 := arrayCopy(nodeMark);
  graphDataOut := TASKGRAPHMETA(inComps1,varCompMapping1,eqCompMapping1,rootNodes1,nodeNames1,nodeDescs1,exeCosts1,commCosts1,nodeMark1);
end copyTaskGraphMeta;

//------------------------------------------
//  Logic - filter task graph informations
//------------------------------------------
public function createCosts "author: marcusw
  Updates the given TaskGraphMeta-Structure with the calculated exec und communication costs."
  input BackendDAE.BackendDAE iDae;
  input String benchFilePrefix; //The prefix of the xml or json profiling-file
  input array<Integer> simeqCompMapping; //Map each simEq to the scc
  input TaskGraphMeta iTaskGraphMeta;
  output TaskGraphMeta oTaskGraphMeta;

protected
  array<BackendDAE.EqSystem> compMapping;
  array<tuple<BackendDAE.EqSystem,Integer>> compMapping_withIdx;
  BackendDAE.Shared shared;
  BackendDAE.StrongComponents comps;
  tuple<Integer,Integer> reqTimeCom;
  //These mappings are for simEqSystems
  list<tuple<Integer,Integer,Real>> reqTimeOpLstSimCode; //<simEqIdx,numberOfCalcs,calcTimeSum>
  array<tuple<Integer,Real>> reqTimeOpSimCode;
  TaskGraphMeta tmpTaskGraphMeta;
  array<Real> reqTimeOp; //Calculation time for each scc
  array<list<Integer>> inComps;
  array<list<tuple<Integer, Integer, Integer>>> commCosts;

algorithm
  oTaskGraphMeta := matchcontinue(iDae,benchFilePrefix,simeqCompMapping,iTaskGraphMeta)
    case(BackendDAE.DAE(shared=shared),_,_,TASKGRAPHMETA(inComps=inComps, commCosts=commCosts))
      equation
        (comps,compMapping_withIdx) = getSystemComponents(iDae);
        compMapping = Util.arrayMap(compMapping_withIdx, Util.tuple21);
        ((_,reqTimeCom)) = HpcOmBenchmark.benchSystem();
        reqTimeOpLstSimCode = HpcOmBenchmark.readCalcTimesFromFile(benchFilePrefix);
        reqTimeOpSimCode = arrayCreate(listLength(reqTimeOpLstSimCode),(-1,-1.0));
        reqTimeOpSimCode = List.fold(reqTimeOpLstSimCode, createCosts1, reqTimeOpSimCode);
        reqTimeOp = arrayCreate(listLength(comps),-1.0);
        reqTimeOp = convertSimEqToSccCosts(reqTimeOpSimCode, simeqCompMapping, reqTimeOp);
        commCosts = createCommCosts(commCosts,1,reqTimeCom);
        ((_,tmpTaskGraphMeta)) = Util.arrayFold4(inComps,createCosts0,(comps,shared),compMapping, reqTimeOp, reqTimeCom, (1,iTaskGraphMeta));
      then tmpTaskGraphMeta;
    else
      equation
        tmpTaskGraphMeta = estimateCosts(iDae,iTaskGraphMeta);
        print("Warning: The costs have been estimated. Maybe " +& benchFilePrefix +& "-file is missing.\n");
      then tmpTaskGraphMeta;
  end matchcontinue;
end createCosts;

// functions to generate dummy costs
//----------------------------------

protected function estimateCosts "estimates the communication and execution costs very roughly so hpcom can work with something when there is no prof_xml
author: Waurich TUD 09-2013"
  input BackendDAE.BackendDAE daeIn;
  input TaskGraphMeta taskGraphMetaIn;
  output TaskGraphMeta taskGraphMetaOut;
protected
  array<list<Integer>> inComps;
  array<tuple<Integer, Integer, Integer>> varCompMapping;
  array<tuple<Integer,Integer,Integer>>  eqCompMapping;
  list<Integer> rootNodes;
  array<String> nodeNames;
  array<String> nodeDescs;
  array<tuple<Integer,Real>> exeCosts;
  array<list<tuple<Integer,Integer,Integer>>> commCosts;
  array<Integer> nodeMark;
  list<Integer> comNumLst;
  list<tuple<Integer,Real>> exeCostsLst;
  BackendDAE.EqSystems eqSystems;
  BackendDAE.Shared shared;
  list<BackendDAE.StrongComponents> compsLst;
algorithm
  BackendDAE.DAE(eqs=eqSystems, shared=shared) := daeIn;
  compsLst := List.map(eqSystems,BackendDAEUtil.getStrongComponents);
  comNumLst := List.map(compsLst,listLength);
  TASKGRAPHMETA(inComps=inComps,varCompMapping=varCompMapping,eqCompMapping=eqCompMapping,rootNodes=rootNodes,nodeNames = nodeNames,nodeDescs=nodeDescs,exeCosts=exeCosts, commCosts=commCosts,nodeMark=nodeMark) := taskGraphMetaIn;
  // get the communication costs
  commCosts := getCommCostsOnly(commCosts);
  // estimate the executionCosts
  exeCostsLst := List.flatten(List.map3(List.intRange(listLength(compsLst)),estimateCosts0,compsLst,eqSystems,shared));
  exeCosts := listArray(exeCostsLst);
  taskGraphMetaOut := TASKGRAPHMETA(inComps,varCompMapping,eqCompMapping,rootNodes,nodeNames,nodeDescs,exeCosts,commCosts,nodeMark);
end estimateCosts;


protected function estimateCosts0 "estimates the exeCosts for StrongComponents
author: Waurich TUD 2013-09"
  input Integer systIdx;
  input list<BackendDAE.StrongComponents> compsLstIn;
  input BackendDAE.EqSystems eqSystemsIn;
  input BackendDAE.Shared sharedIn;
  output list<tuple<Integer,Real>> exeCostsOut;
protected
  BackendDAE.StrongComponents comps;
  BackendDAE.EqSystem eqSys;
algorithm
  comps := listGet(compsLstIn,systIdx);
  eqSys := listGet(eqSystemsIn,systIdx);
  exeCostsOut := List.map2(comps,estimateCosts1,eqSys,sharedIn);
end estimateCosts0;


protected function estimateCosts1 " estimates the exeCost for one StrongComponent
author: Waurich TUD 2013-09"
  input BackendDAE.StrongComponent compIn;
  input BackendDAE.EqSystem eqSysIn;
  input BackendDAE.Shared sharedIn;
  output tuple<Integer,Real> exeCostOut;
algorithm
  exeCostOut := matchcontinue(compIn,eqSysIn,sharedIn)
    local
      Integer costAdd, costMul, costTrig, numOps;
      Real costs;
    case(_,_,_)
      equation
        ((costAdd,costMul,costTrig)) = countOperations(compIn, eqSysIn, sharedIn);
        numOps = costAdd+costMul+costTrig;
        costs = realAdd(realMul(intReal(numOps),25.0),70.0); // feel free to change this
      then
        ((numOps,costs));
    else
      equation
        print("estimateCosts1 failed1\n");
      then
        fail();
  end matchcontinue;
end estimateCosts1;


protected function getCommCostsOnly "function to compute the communicationCosts
author: Waurich TUD 2013-09"
  input array<list<tuple<Integer,Integer,Integer>>> commCostsIn;
  output array<list<tuple<Integer,Integer,Integer>>> commCostsOut;
protected
  tuple<Integer,Integer> reqTimeCom;
algorithm
  ((_,reqTimeCom)) := HpcOmBenchmark.benchSystem();
  commCostsOut := createCommCosts(commCostsIn,1,reqTimeCom);
end getCommCostsOnly;


protected function checkForExecutionCosts "checks if every entry in exeCosts is > 0.0"
  input TaskGraphMeta dataIn;
  output Boolean isFine;
protected
  array<list<Integer>> inComps;
  array<tuple<Integer,Real>> exeCosts;
algorithm
  TASKGRAPHMETA(inComps=inComps, exeCosts=exeCosts) := dataIn;
  isFine := checkForExecutionCosts1(exeCosts,inComps,1);
  Debug.bcall(not isFine,print,"There are execution costs with value 0.0!\n ");
end checkForExecutionCosts;


protected function checkForExecutionCosts1 "checks if the comp for the given node has an executionCost > 0.0
author: Waurich TUD 2013-09"
  input array<tuple<Integer,Real>> exeCosts;
  input array<list<Integer>> inComps;
  input Integer nodeIdx;
  output Boolean bOut;
algorithm
  bOut := matchcontinue(exeCosts,inComps,nodeIdx)
    local
      Boolean b, isZero;
      list<Integer> comps;
      Real value;
      tuple<Integer,Real> tpl;
    case(_,_,_)
      equation
        true = arrayLength(inComps) >= nodeIdx;
        comps = arrayGet(inComps,nodeIdx);
        isZero = List.fold1(comps,checkTpl2ForZero,exeCosts,false);
        false = isZero;
        b = checkForExecutionCosts1(exeCosts,inComps,nodeIdx+1);
      then
        b;
    case(_,_,_)
      equation
        true = arrayLength(inComps) < nodeIdx;
        then
          true;
    else
      equation
      then
        false;
  end matchcontinue;
end checkForExecutionCosts1;


protected function checkTpl2ForZero "folding function for checkForExecutionCosts1
author:Waurich TUD 2013-09"
  input Integer comp;
  input array<tuple<Integer,Real>> exeCosts;
  input Boolean bIn;
  output Boolean bOut;
protected
  Boolean b;
  Real value;
  tuple<Integer,Real> tpl;
algorithm
  tpl := arrayGet(exeCosts,comp);
  (_,value) := tpl;
  b := realEq(value,0.0);
  bOut := b or bIn;
end checkTpl2ForZero;


public function convertNodeListToEdgeTuples "author: marcusw
  Convert a list of nodes to a list of edged. E.g. {1,2,5} -> {(1,2),(2,5)}"
  input list<Integer> iNodeList;
  output list<tuple<Integer,Integer>> oEdgeList;
algorithm
  oEdgeList := convertNodeListToEdgeTuples0(iNodeList, listLength(iNodeList), {});
end convertNodeListToEdgeTuples;


protected function convertNodeListToEdgeTuples0 "author: marcusw
  Helper function of convertNodeListToEdgeTuples"
  input list<Integer> iNodeList;
  input Integer iNodeIdx;
  input list<tuple<Integer,Integer>> iEdgeList;
  output list<tuple<Integer,Integer>> oEdgeList;
protected
  list<tuple<Integer,Integer>> tmpEdgeList;
  Integer elem, preElem;
algorithm
  oEdgeList := matchcontinue(iNodeList,iNodeIdx,iEdgeList)
    case(_,_,tmpEdgeList)
      equation
        true = intGt(iNodeIdx, 1);
        elem = listGet(iNodeList, iNodeIdx);
        preElem = listGet(iNodeList, iNodeIdx-1);
        tmpEdgeList = (preElem,elem)::tmpEdgeList;
        tmpEdgeList = convertNodeListToEdgeTuples0(iNodeList, iNodeIdx-1,tmpEdgeList);
      then tmpEdgeList;
    else iEdgeList;
  end matchcontinue;
end convertNodeListToEdgeTuples0;

protected function convertSimEqToSccCosts
  input array<tuple<Integer,Real>> iReqTimeOpSimCode;
  input array<Integer> iSimeqCompMapping; //Map each simEq to the scc
  input array<Real> iReqTimeOp;
  output array<Real> oReqTimeOp; //calcTime for each scc

algorithm
  ((_,oReqTimeOp)) := Util.arrayFold1(iReqTimeOpSimCode, convertSimEqToSccCosts1, iSimeqCompMapping, (0,iReqTimeOp));
end convertSimEqToSccCosts;

protected function convertSimEqToSccCosts1
  input tuple<Integer,Real> iReqTimeOpSimCode;
  input array<Integer> iSimeqCompMapping; //Map each simEq to the scc
  input tuple<Integer,array<Real>> iReqTimeOp;
  output tuple<Integer,array<Real>> oReqTimeOp; //calcTime for each scc

protected
  Integer simEqCalcCount, simEqIdx;
  Real simEqCalcTime, realSimEqCalcCount;
  array<Real> reqTime;

algorithm
  oReqTimeOp := matchcontinue(iReqTimeOpSimCode,iSimeqCompMapping,iReqTimeOp)
    case(_,_,_)
      equation
        (simEqCalcCount, simEqCalcTime) = iReqTimeOpSimCode;
        (simEqIdx,reqTime) = iReqTimeOp;
        realSimEqCalcCount = intReal(simEqCalcCount);
        true = realNe(realSimEqCalcCount,0.0);
        reqTime = convertSimEqToSccCosts2(reqTime, realDiv(simEqCalcTime,realSimEqCalcCount), simEqIdx, iSimeqCompMapping);
      then ((simEqIdx+1,reqTime));
    else
      equation
        (simEqCalcCount, simEqCalcTime) = iReqTimeOpSimCode;
        (simEqIdx,reqTime) = iReqTimeOp;
        realSimEqCalcCount = intReal(simEqCalcCount);
        reqTime = convertSimEqToSccCosts2(reqTime, 0.0, simEqIdx, iSimeqCompMapping);
      then ((simEqIdx+1,reqTime));
  end matchcontinue;
end convertSimEqToSccCosts1;

protected function convertSimEqToSccCosts2
  input array<Real> iReqTime;
  input Real iSimEqCalcTime;
  input Integer iSimEqIdx;
  input array<Integer> iSimeqCompMapping; //Map each simEq to the scc
  output array<Real> oReqTime;

protected
  array<Real> reqTime;
  Integer sccIdx;

algorithm
  oReqTime := matchcontinue(iReqTime,iSimEqCalcTime, iSimEqIdx, iSimeqCompMapping)
    case(reqTime,_,_,_)
      equation
        true = intGe(arrayLength(iSimeqCompMapping),iSimEqIdx);
        sccIdx = arrayGet(iSimeqCompMapping, iSimEqIdx);
        true = intGt(sccIdx,0);
        reqTime = arrayUpdate(reqTime,sccIdx, iSimEqCalcTime);
        //print("convertSimEqToSccCosts2 sccIdx: " +& intString(sccIdx) +& " reqTime: " +& realString(iSimEqCalcTime) +& "\n");
      then
        reqTime;
    else
      then iReqTime;
  end matchcontinue;
end convertSimEqToSccCosts2;

protected function createCosts0 "author: marcusw
  Updates the given TaskGraphMeta-Structure with the calculated exec und communication costs."
  input list<Integer> iNode; //Node to sccs mapping
  input tuple<BackendDAE.StrongComponents,BackendDAE.Shared> iComps_shared;
  input array<BackendDAE.EqSystem> iCompMapping;
  input array<Real> reqTimeOp;
  input tuple<Integer,Integer> reqTimeCom;
  input tuple<Integer,TaskGraphMeta> iTaskGraphMeta; //Node number and task graph meta
  output tuple<Integer,TaskGraphMeta> oTaskGraphMeta;

protected
  array<tuple<Integer, Integer, Integer>> varCompMapping;
  array<tuple<Integer,Integer,Integer>>  eqCompMapping;
  array<Integer> nodeRefCount;
  array<tuple<Integer,Real>> execCosts;
  BackendDAE.EqSystem comp;
  list<Integer> rootNodes;
  array<String> nodeNames, nodeDescs;
  array<list<Integer>> inComps;
  array<list<tuple<Integer, Integer, Integer>>> commCosts;
  Integer nodeNumber;
  TaskGraphMeta taskGraphMeta;

algorithm
  (nodeNumber,taskGraphMeta) := iTaskGraphMeta;
  TASKGRAPHMETA(inComps=inComps,varCompMapping=varCompMapping,eqCompMapping=eqCompMapping,nodeNames=nodeNames,nodeDescs=nodeDescs,rootNodes=rootNodes,exeCosts=execCosts,commCosts=commCosts,nodeMark=nodeRefCount) := taskGraphMeta;
  createExecCost(iNode, iComps_shared, reqTimeOp, execCosts, iCompMapping, nodeNumber);
  oTaskGraphMeta := ((nodeNumber+1, TASKGRAPHMETA(inComps,varCompMapping,eqCompMapping,rootNodes,nodeNames,nodeDescs,execCosts,commCosts,nodeRefCount)));
end createCosts0;

function createCosts1
  input tuple<Integer,Integer,Real> iTuple; //<simEqIdx,numberOfCalcs,calcTimeSum>
  input array<tuple<Integer,Real>> iReqTime;
  output array<tuple<Integer,Real>> oReqTime;

protected
  array<tuple<Integer,Real>> tmpArray;
  Integer simEqIdx,calcTimeCount;
  Real calcTime;

algorithm
  tmpArray := iReqTime;
  (simEqIdx,calcTimeCount,calcTime) := iTuple;
  tmpArray := arrayUpdate(iReqTime, simEqIdx+1,(calcTimeCount,calcTime));
  oReqTime := tmpArray;
end createCosts1;

protected function createExecCost "author: marcusw
  This method fills the iExecCosts array with the execution cost of each scc."
  input list<Integer> iNodeSccs; //Sccs of the current node
  input tuple<BackendDAE.StrongComponents, BackendDAE.Shared> icomps_shared; //input components and shared
  input array<Real> iRequiredTime; //required time for op
  input array<tuple<Integer,Real>> iExecCosts; //<numberOfOperations, requiredCycles>
  input array<BackendDAE.EqSystem> compMapping;
  input Integer iNodeIdx;

protected
  tuple<Integer,Real> execCost;

algorithm
  execCost := List.fold3(iNodeSccs, createExecCost0, icomps_shared, compMapping, iRequiredTime, (0,0.0));
  _ := arrayUpdate(iExecCosts,iNodeIdx,execCost);

end createExecCost;


protected function createExecCost0 "author: marcusw
  Helper function for createExecCosts. It calculates the execution costs for the given scc and adds it to the iCosts parameter."
  input Integer sccIndex;
  input tuple<BackendDAE.StrongComponents, BackendDAE.Shared> icomps_shared; //input system and shared
  input array<BackendDAE.EqSystem> compMapping;
  input array<Real> iRequiredTime; //required time for op
  input tuple<Integer,Real> iCosts; //<numberOfOperations, requiredCycles>
  output tuple<Integer,Real> oCosts; //<numberOfOperations, requiredCycles>

protected
  Integer costAdd,costMul,costTrig;
  Integer iCosts_op;
  Real iCosts_cyc;
  BackendDAE.StrongComponent comp;
  BackendDAE.StrongComponents comps;
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
  Real reqTime;

algorithm
  (comps,shared) := icomps_shared;
  (iCosts_op, iCosts_cyc) := iCosts;
  comp := listGet(comps,sccIndex);
  syst := arrayGet(compMapping,sccIndex);
  reqTime := arrayGet(iRequiredTime, sccIndex);
  //(reqTimeOpM,reqTimeOpN) := iRequiredTime;
  ((costAdd,costMul,costTrig)) := countOperations(comp, syst, shared);

  //print("Component: ");
  //BackendDump.dumpComponent(comp);
  //print("Cost: " +& realString(iCosts_cyc) +& "\n");
  //print(tuple3ToString((costAdd,costMul,costTrig)));
  //print("\n");
  oCosts := (costAdd+costMul+costTrig + iCosts_op, realAdd(iCosts_cyc,reqTime));
end createExecCost0;


protected function createCommCosts "author: marcusw
  Extend the given commCost values with a concrete cycle-count."
  input array<list<tuple<Integer, Integer, Integer>>> iCosts;
  input Integer iCurrentIndex;
  input tuple<Integer,Integer> iReqTimeCom; //the required cycles to share x-values between two cores. The number of cycles is described as linear function y=m*x+1 (first value is m, second n).
  output array<list<tuple<Integer, Integer, Integer>>> oCosts;

protected
  array<list<tuple<Integer, Integer, Integer>>> tmpCosts;
  list<tuple<Integer, Integer, Integer>> currentList;

algorithm
  oCosts := matchcontinue(iCosts, iCurrentIndex, iReqTimeCom)
    case(tmpCosts,_,_)
      equation
        true = intLe(iCurrentIndex, arrayLength(iCosts));
        currentList = arrayGet(tmpCosts,iCurrentIndex);
        currentList = List.map1(currentList,createCommCosts0,iReqTimeCom);
        tmpCosts = arrayUpdate(tmpCosts,iCurrentIndex,currentList);
        tmpCosts = createCommCosts(tmpCosts, iCurrentIndex+1,iReqTimeCom);
      then tmpCosts;
    else iCosts;
  end matchcontinue;
end createCommCosts;

protected function createCommCosts0 "author: marcusw
  Helper function for createCommCosts to add the concrete cycle-count to the given tuple."
  input tuple<Integer, Integer, Integer> iCommTuple;
  input tuple<Integer,Integer> iReqTimeCom;
  output tuple<Integer, Integer, Integer> oCommTuple;

protected
  Integer targetNodeIdx,numOfVars,reqTimeM,reqTimeN;

algorithm
  (targetNodeIdx,numOfVars,_) := iCommTuple;
  (reqTimeM,reqTimeN) := iReqTimeCom;
  oCommTuple := (targetNodeIdx,numOfVars,reqTimeN + numOfVars*reqTimeM);

end createCommCosts0;

protected function countOperations "author: marcusw
  Count the operations of the given component."

  input BackendDAE.StrongComponent icomp;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  output tuple<Integer,Integer,Integer> operations; //<add,mul,trig>

protected
  DAE.ComponentRef  cr;
  Integer eqnIdx,varIdx;
  Integer op1,op2,op3;
  BackendDAE.Variables vars;
  BackendDAE.Var v;
  BackendDAE.EquationArray eqns;
  DAE.ElementSource source;
  DAE.Exp e1, e2, varexp, exp_;
  String s;

algorithm
  operations := matchcontinue(icomp,isyst,ishared)
    case(BackendDAE.SINGLEEQUATION(eqn=eqnIdx,var=varIdx), BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), _)
      equation
        BackendDAE.EQUATION(exp=e1, scalar=e2, source=source) = BackendEquation.equationNth0(eqns, eqnIdx-1);

        (v as BackendDAE.VAR(varName = cr)) = BackendVariable.getVarAt(vars, varIdx);
        varexp = Expression.crefExp(cr);
        varexp = Debug.bcallret1(BackendVariable.isStateVar(v), Expression.expDer, varexp, varexp);
        (exp_, _) = ExpressionSolve.solveLin(e1, e2, varexp);

        //print("Equation = ");
        //s = ExpressionDump.printExpStr(varexp);
        //print(s +& " = ");
        //s = ExpressionDump.printExpStr(exp_);
        //print(s +& "\n");
        ((_,(op1,op2,_,op3))) = BackendDAEOptimize.countOperationsExp((exp_,(0,0,0,0)));
        //print("");
      then ((op1,op2,op3));
    else
      equation
        ((op1,op2,_,op3)) = BackendDAEOptimize.countOperationstraverseComps({icomp},isyst,ishared,(0,0,0,0));
      then ((op1,op2,op3));
  end matchcontinue;
end countOperations;

public function validateTaskGraphMeta "author: marcusw
  Check if the given TaskGraphMeta-object has a valid structure."
  input TaskGraphMeta iTaskGraph;
  input BackendDAE.BackendDAE iDae;
  output Boolean valid;

algorithm
  valid := matchcontinue(iTaskGraph, iDae)
    local
      BackendDAE.StrongComponents systComps, graphComps;
      array<BackendDAE.StrongComponent> systCompsArray;
      array<tuple<BackendDAE.EqSystem,Integer>> systCompEqSysMapping, graphCompEqSysMapping; //Map each component to the EqSystem
      list<tuple<BackendDAE.StrongComponent,Integer>> systCompEqSysMappingIdx, graphCompEqSysMappingIdx;
    case(_,_)
      equation
        //Check if all StrongComponents are in the graph
        (systComps,systCompEqSysMapping) = getSystemComponents(iDae);

        //print("validateTaskGraphMeta_pre\n");
        //BackendDump.dumpComponents(systComps);
        //print("validateTaskGraphMeta_post\n");

        systCompsArray = listArray(systComps);
        (graphComps,graphCompEqSysMapping) = getGraphComponents(iTaskGraph,systCompsArray,systCompEqSysMapping);

        ((_,_,systCompEqSysMappingIdx)) = validateTaskGraphMeta0(systCompEqSysMapping,(1,systComps,{}));
        ((_,_,graphCompEqSysMappingIdx)) = validateTaskGraphMeta0(graphCompEqSysMapping,(1,graphComps,{}));
        //print("Graph components: " +& stringDelimitList(List.map(graphComps,BackendDump.printComponent), ";") +& "\n");
        true = validateComponents(graphCompEqSysMappingIdx,systCompEqSysMappingIdx);
        //Check if no component was connected twice
        true = checkForDuplicates(graphCompEqSysMappingIdx);
        //Check if nodeNames,nodeDescs and exeCosts-array have the right size
        true = checkForExecutionCosts(iTaskGraph);
        // Check if every node has an execution cost > 0.
      then true;
    else false;
  end matchcontinue;

end validateTaskGraphMeta;

public function validateTaskGraphMeta0
  input array<tuple<BackendDAE.EqSystem,Integer>> iEqSysMapping;
  input tuple<Integer,BackendDAE.StrongComponents,list<tuple<BackendDAE.StrongComponent,Integer>>> iCompsTpl; //<current Index, list of remaining strong components, result>
  output tuple<Integer,BackendDAE.StrongComponents,list<tuple<BackendDAE.StrongComponent,Integer>>> oCompsTpl;
protected
  Integer currentIdx, eqSysIdx;
  BackendDAE.StrongComponents iComps, rest;
  BackendDAE.StrongComponent head;
  list<tuple<BackendDAE.StrongComponent,Integer>> iCompEqSysMapping, oCompEqSysMapping;
  tuple<Integer,BackendDAE.StrongComponents,list<tuple<BackendDAE.StrongComponent,Integer>>> tmpCompsTpl;
algorithm
  oCompsTpl := match(iEqSysMapping,iCompsTpl)
    case(_,(currentIdx,(head::rest),iCompEqSysMapping))
      equation
        ((_,eqSysIdx)) = arrayGet(iEqSysMapping,currentIdx);
        oCompEqSysMapping = (head,eqSysIdx)::iCompEqSysMapping;
        tmpCompsTpl = validateTaskGraphMeta0(iEqSysMapping,(currentIdx+1,rest,oCompEqSysMapping));
      then tmpCompsTpl;
    else iCompsTpl;
  end match;
end validateTaskGraphMeta0;

protected function validateComponents "author: marcusw
  Checks if the given component-lists are equal."
  input list<tuple<BackendDAE.StrongComponent,Integer>> graphComps; //<component, eqSysIdx>
  input list<tuple<BackendDAE.StrongComponent,Integer>> systComps;
  output Boolean res;

protected
  list<tuple<BackendDAE.StrongComponent,Integer>> sortedGraphComps, sortedSystComps;

algorithm
  res := matchcontinue(graphComps,systComps)
    case(_,_)
      equation
        sortedGraphComps = List.sort(graphComps,compareComponents);
        sortedSystComps = List.sort(systComps,compareComponents);
        true = List.isEqual(sortedGraphComps, sortedSystComps, true);
      then true;
    else
      equation
        print("Different components in graph and system");
      then false;
  end matchcontinue;
end validateComponents;

protected function checkForDuplicates "author: marcusw
  Returns true if every component is unique in the list."
  input list<tuple<BackendDAE.StrongComponent,Integer>> iComps; //<component, eqSysIdx>
  output Boolean res;
protected
  list<tuple<BackendDAE.StrongComponent,Integer>> sortedComps;
algorithm
  sortedComps := List.sort(iComps,compareComponents);
  //print("checkForDuplicates Components: " +& stringDelimitList(List.map(sortedComps,BackendDump.printComponent), ";") +& "\n");
  ((res,_)) := List.fold(sortedComps,checkForDuplicates0,(true,NONE()));
end checkForDuplicates;

protected function checkForDuplicates0
  input tuple<BackendDAE.StrongComponent,Integer> currentComp_idx;
  input tuple<Boolean,Option<tuple<BackendDAE.StrongComponent,Integer>>> iLastComp; //<result,lastComp>
  output tuple<Boolean,Option<tuple<BackendDAE.StrongComponent,Integer>>> oLastComp; //<result,lastComp>
protected
  BackendDAE.StrongComponent lastComp,currentComp;
  tuple<BackendDAE.StrongComponent,Integer> lastComp_idx;
  Integer idxLast, idxCurrent;
algorithm
  oLastComp := matchcontinue(currentComp_idx,iLastComp)
    case(_,(false,_)) then ((false,SOME(currentComp_idx)));
    case(_,(_,NONE())) then ((true,SOME(currentComp_idx)));
    case((currentComp,idxCurrent),(_,SOME(lastComp_idx as (lastComp, idxLast))))
      equation
        false = compareComponents(currentComp_idx,lastComp_idx);
        print("Component duplicate detected in eqSystem " +& intString(idxCurrent) +& ": current: " +& BackendDump.printComponent(currentComp) +& " last " +& BackendDump.printComponent(lastComp) +& ".\n");
      then ((false,SOME(currentComp_idx)));
    else ((true, SOME(currentComp_idx)));
  end matchcontinue;
end checkForDuplicates0;

protected function getGraphComponents "author: marcusw
  Returns all StrongComponents of the TaskGraphMeta-structure."
  input TaskGraphMeta iTaskGraphMeta;
  input array<BackendDAE.StrongComponent> iSystComps;
  input array<tuple<BackendDAE.EqSystem,Integer>> iCompEqSysMapping; //maps each iSystComps to <eqsystem,eqSystemIdx>
  output BackendDAE.StrongComponents oComps;
  output array<tuple<BackendDAE.EqSystem,Integer>> oCompEqGraphMapping;
protected
  BackendDAE.StrongComponents tmpComps;
  list<tuple<BackendDAE.EqSystem,Integer>> tmpMapping;
  array<list<Integer>> inComps;
  array<Integer> nodeMarks;

algorithm
  tmpComps := {};
  tmpMapping := {};
  TASKGRAPHMETA(inComps=inComps, nodeMark=nodeMarks) := iTaskGraphMeta;
  ((tmpComps,tmpMapping)) := Util.arrayFold2(inComps,getGraphComponents0,iSystComps,iCompEqSysMapping,(tmpComps,tmpMapping));
  ((_,(tmpComps,tmpMapping))) := Util.arrayFold2(nodeMarks,getGraphComponents2, iSystComps, iCompEqSysMapping, (1,(tmpComps,tmpMapping)));
  oComps := tmpComps;
  oCompEqGraphMapping := listArray(tmpMapping);
end getGraphComponents;

protected function getGraphComponents0 "author: marcusw
  Helper function of getGraphComponents. Returns all components which are not marked with -1 (all components that are part of the graph)."
  input list<Integer> inComp;
  input array<BackendDAE.StrongComponent> systComps;
  input array<tuple<BackendDAE.EqSystem,Integer>> iCompEqSysMapping;
  input tuple<BackendDAE.StrongComponents, list<tuple<BackendDAE.EqSystem,Integer>>> iNodeComps_Mapping; //list of components and list of mapping
  output tuple<BackendDAE.StrongComponents, list<tuple<BackendDAE.EqSystem,Integer>>> oNodeComps_Mapping;

protected
  BackendDAE.StrongComponents iNodeComps, tmpNodeComps;
  list<tuple<BackendDAE.EqSystem,Integer>> iCompsMapping, tmpCompsMapping;
algorithm
  (iNodeComps,iCompsMapping) := iNodeComps_Mapping;
  ((tmpNodeComps,tmpCompsMapping)) := List.fold2(inComp, getGraphComponents1, systComps, iCompEqSysMapping, ({},{}));
  tmpNodeComps := listAppend(iNodeComps,tmpNodeComps);
  tmpCompsMapping := listAppend(iCompsMapping,tmpCompsMapping);
  oNodeComps_Mapping := (tmpNodeComps,tmpCompsMapping);
end getGraphComponents0;

protected function getGraphComponents1
  input Integer compIdx;
  input array<BackendDAE.StrongComponent> systComps;
  input array<tuple<BackendDAE.EqSystem,Integer>> iCompEqSysMapping;
  input tuple<BackendDAE.StrongComponents, list<tuple<BackendDAE.EqSystem,Integer>>> iNodeComps_Mapping;
  output tuple<BackendDAE.StrongComponents, list<tuple<BackendDAE.EqSystem,Integer>>> oNodeComps_Mapping;

protected
  BackendDAE.StrongComponent comp;
  tuple<BackendDAE.EqSystem,Integer> eqSyst;
  BackendDAE.StrongComponents tmpComps;
  list<tuple<BackendDAE.EqSystem,Integer>> tmpSysts;
algorithm
  (tmpComps,tmpSysts) := iNodeComps_Mapping;
  comp := arrayGet(systComps,compIdx);
  eqSyst := arrayGet(iCompEqSysMapping,compIdx);
  tmpComps := comp::tmpComps;
  tmpSysts := eqSyst::tmpSysts;
  oNodeComps_Mapping := (tmpComps,tmpSysts);
end getGraphComponents1;

protected function getGraphComponents2 "author: marcusw
  Append all components with mark -1 to the componentlist."
  input Integer nodeMark;
  input array<BackendDAE.StrongComponent> systComps;
  input array<tuple<BackendDAE.EqSystem,Integer>> iCompEqSysMapping;
  input tuple<Integer,tuple<BackendDAE.StrongComponents, list<tuple<BackendDAE.EqSystem,Integer>>>> iNodeComps_Mapping; //<nodeIdx, <components,eqSystems>>
  output tuple<Integer,tuple<BackendDAE.StrongComponents, list<tuple<BackendDAE.EqSystem,Integer>>>> oNodeComps_Mapping;

protected
  Integer nodeIdx;
  BackendDAE.StrongComponent comp;
  tuple<BackendDAE.EqSystem,Integer> eqSyst;
  BackendDAE.StrongComponents comps;
  list<tuple<BackendDAE.EqSystem,Integer>> eqSysts;

algorithm
  oNodeComps_Mapping := matchcontinue(nodeMark, systComps, iCompEqSysMapping, iNodeComps_Mapping)
    case(_,_,_,(nodeIdx,(comps,eqSysts)))
      equation
        true = intGe(nodeMark,0);
      then ((nodeIdx+1,(comps,eqSysts)));
    case(_,_,_,(nodeIdx,(comps,eqSysts)))
      equation
        comp = arrayGet(systComps,nodeIdx);
        eqSyst = arrayGet(iCompEqSysMapping,nodeIdx);
        comps = comp :: comps;
        eqSysts = eqSyst :: eqSysts;
      then ((nodeIdx+1,(comps,eqSysts)));
  end matchcontinue;
end getGraphComponents2;

protected function compareComponents "author: marcusw
  Compares the given components and returns false if they are equal."
  input tuple<BackendDAE.StrongComponent,Integer> iComp1;
  input tuple<BackendDAE.StrongComponent,Integer> iComp2; //<component, eqSystIdx>
  output Boolean res;

protected
  String comp1Str,comp2Str;
  Integer minLength, comp1Idx, comp2Idx;
  BackendDAE.StrongComponent comp1, comp2;
algorithm
  (comp1, comp1Idx) := iComp1;
  (comp2, comp2Idx) := iComp2;
  comp1Str := BackendDump.printComponent(comp1) +& "_" +& intString(comp1Idx);
  comp2Str := BackendDump.printComponent(comp2) +& "_" +& intString(comp2Idx);
  minLength := intMin(stringLength(comp1Str),stringLength(comp2Str));
  res := intGt(System.strncmp(comp1Str, comp2Str, minLength), 0);
end compareComponents;


//evaluation and analysing functions
//------------------------------------------
//------------------------------------------

public function getCriticalPaths " function to assign levels to the nodes of a graph and compute the criticalPath.
author: Waurich TUD 2013-07"
  input TaskGraph graphIn;
  input TaskGraphMeta graphDataIn;
  output tuple<list<list<Integer>>,Real> criticalPathOut; //criticalPath with communication costs <%paths, opCost%>
  output tuple<list<list<Integer>>,Real> criticalPathOutWoC; //criticalPath without communication costs <%paths, opCost%>
  output list<list<Integer>> parallelSetsOut;
algorithm
  (criticalPathOut,criticalPathOutWoC,parallelSetsOut) := matchcontinue(graphIn,graphDataIn)
    local
      TaskGraph graphT;
      list<Integer> rootNodes;
      list<list<Integer>> cpWCpaths,CpWoCpaths, level;
      Real cpWCcosts,cpWoCcosts;
    case(_,_)
      equation
        true = arrayLength(graphIn) <> 0;
        graphT = BackendDAEUtil.transposeMatrix(graphIn,arrayLength(graphIn));
        (_,rootNodes) = List.filterOnTrueSync(arrayList(graphT),List.isEmpty,List.intRange(arrayLength(graphT)));
        level = HpcOmScheduler.getGraphLevel(graphIn,{rootNodes});
        (cpWCpaths,cpWCcosts) = getCriticalPath(graphIn,graphDataIn,rootNodes,true);
        (CpWoCpaths,cpWoCcosts) = getCriticalPath(graphIn,graphDataIn,rootNodes,false);
        cpWCcosts = roundReal(cpWCcosts,2);
        cpWoCcosts = roundReal(cpWoCcosts,2);
      then
        ((cpWCpaths,cpWCcosts),(CpWoCpaths,cpWoCcosts),level);
    case(_,_)
      equation
        true = arrayLength(graphIn) == 0;
      then
        (({{}},0.0),({{}},0.0),{});
    else
      equation
        print("getCriticalPaths failed!\n");
      then
        (({{}},0.0),({{}},0.0),{});
  end matchcontinue;
end getCriticalPaths;

protected function getCriticalPath "function getCriticalPath
  author: marcusw
  Get the critical path of the graph."
  input TaskGraph iGraph;
  input TaskGraphMeta iGraphData;
  input list<Integer> iRootNodes;
  input Boolean iHandleCommCosts; //true if the communication costs should be handled
  output list<list<Integer>> oCriticalPathsOut; //The list of critical paths -> has only one element
  output Real oCpCosts;
protected
  array<tuple<Real,list<Integer>>> nodeCriticalPaths; //<criticalPath,criticalPathSuccessor> for each node <%idx%>
  list<tuple<Real,list<Integer>>> criticalPaths;
  Integer criticalPathIdx;
  list<Integer> criticalPath;
algorithm
  nodeCriticalPaths := arrayCreate(arrayLength(iGraph), (-1.0,{}));
  criticalPaths := List.map4(iRootNodes, getCriticalPath1, iGraph, iGraphData, iHandleCommCosts, nodeCriticalPaths);
  criticalPathIdx := getCriticalPath2(criticalPaths, 1, -1.0, -1);
  ((oCpCosts, criticalPath)) := listGet(criticalPaths, criticalPathIdx);
  oCriticalPathsOut := {criticalPath};
end getCriticalPath;

protected function getCriticalPath1 "function getCriticalPath1
  author: marcusw
  Get the critical path of the given node (iNode). If the node was already visited, the result will be read from the iNodeCriticalPaths.
  If the node is visited the first time, then the critical path is calculated and stored into the iNodeCriticalPaths-array."
  input Integer iNode;
  input TaskGraph iGraph;
  input TaskGraphMeta iGraphData;
  input Boolean iHandleCommCosts; //true if the communication costs should be handled
  input array<tuple<Real,list<Integer>>> iNodeCriticalPaths;
  output tuple<Real,list<Integer>> criticalPathOut;
protected
  Real cpCalcTime, calcTime;
  Integer criticalPathIdx;
  tuple<Integer,Integer,Integer> commCost;
  list<Integer> childNodes, criticalPathChild, criticalPath, nodeComps;
  list<tuple<Real,list<Integer>>> criticalPaths;
  array<tuple<Integer,Real>> exeCosts;
  array<list<Integer>> inComps;
algorithm
  criticalPathOut := matchcontinue(iNode, iGraph, iGraphData, iHandleCommCosts, iNodeCriticalPaths)
    case(_,_,TASKGRAPHMETA(inComps=inComps,exeCosts=exeCosts),_,_)
      equation //In this case, the node was already visited
        ((cpCalcTime,criticalPath)) = arrayGet(iNodeCriticalPaths, iNode);
        true = realGe(cpCalcTime, 0.0);
      then ((cpCalcTime, criticalPath));
    case(_,_,TASKGRAPHMETA(inComps=inComps,exeCosts=exeCosts),_,_)
      equation //critical path of node is currently unknown -> calculate it
        childNodes = arrayGet(iGraph, iNode);
        true = List.isNotEmpty(childNodes); //has children
        criticalPaths = List.map4(childNodes, getCriticalPath1, iGraph, iGraphData, iHandleCommCosts, iNodeCriticalPaths);
        criticalPathIdx = getCriticalPath2(criticalPaths, 1, -1.0, -1);
        ((cpCalcTime, criticalPathChild)) = listGet(criticalPaths, criticalPathIdx);
        criticalPath = iNode :: criticalPathChild;
        commCost = Util.if_(iHandleCommCosts, getCommCostBetweenNodes(iNode, List.first(criticalPathChild), iGraphData), (0,0,0));
        //print("Comm cost from node " +& intString(iNode) +& " to " +& intString(List.first(criticalPathChild)) +& " with costs " +& intString(Util.tuple33(commCost)) +& "\n");
        nodeComps = arrayGet(inComps, iNode);
        calcTime = addUpExeCostsForNode(nodeComps, exeCosts, 0.0); //sum up calc times of all components
        calcTime = realAdd(cpCalcTime,calcTime);
        calcTime = realAdd(calcTime, intReal(Util.tuple33(commCost)));
        _ = arrayUpdate(iNodeCriticalPaths, iNode, (calcTime, criticalPath));
      then ((calcTime, criticalPath));
    case(_,_,TASKGRAPHMETA(inComps=inComps,exeCosts=exeCosts),_,_)
      equation //critical path of node is currently unknown -> calculate it
        childNodes = arrayGet(iGraph, iNode);
        false = List.isNotEmpty(childNodes); //has no children
        criticalPath = iNode :: {};
        nodeComps = arrayGet(inComps, iNode);
        calcTime = addUpExeCostsForNode(nodeComps, exeCosts, 0.0); //sum up calc times of all components
        _ = arrayUpdate(iNodeCriticalPaths, iNode, (calcTime, criticalPath));
      then ((calcTime, criticalPath));
    else
      equation
        print("HpcOmTaskGraph.getCriticalPath_1 failed\n");
      then fail();
  end matchcontinue;
end getCriticalPath1;

protected function getCriticalPath2 "function getCriticalPath2
  author: marcusw
  Find the list-index of the longest path. The paths which should be compared have to be stored in the iCriticalPaths-list."
  input list<tuple<Real,list<Integer>>> iCriticalPaths;
  input Integer iListIdx;
  input Real iLongestPath;
  input Integer iLongestPathIndex;
  output Integer oLongestPathIndex;
protected
  Real cpCost;
  list<Integer> criticalPath;
  list<tuple<Real,list<Integer>>> rest;
algorithm
  oLongestPathIndex := matchcontinue(iCriticalPaths, iListIdx, iLongestPath, iLongestPathIndex)
    case((cpCost, criticalPath)::rest,_,_,_)
      equation
        true = realGt(cpCost, iLongestPath);
      then getCriticalPath2(rest, iListIdx+1, cpCost, iListIdx);
    case((cpCost, criticalPath)::rest,_,_,_)
      then getCriticalPath2(rest, iListIdx+1, iLongestPath, iLongestPathIndex);
    else iLongestPathIndex;
  end matchcontinue;
end getCriticalPath2;

protected function addUpExeCostsForNode "function addUpExeCostsForNode
  author: marcusw
  This function adds up all execution costs of the given component list (iNodeComps)."
  input list<Integer> iNodeComps;
  input array<tuple<Integer,Real>> iExeCosts;
  input Real iExeCost;
  output Real oExeCost;
protected
  Integer head;
  list<Integer> rest;
  Real cost;
algorithm
  oExeCost := match(iNodeComps, iExeCosts, iExeCost)
    case(head::rest,_,_)
      equation
        ((_,cost)) = arrayGet(iExeCosts, head);
        cost = realAdd(cost, iExeCost);
        cost = addUpExeCostsForNode(rest, iExeCosts, cost);
      then cost;
    else iExeCost;
  end match;
end addUpExeCostsForNode;

protected function gatherParallelSets " gathers all nodes of the same level in a list
author: Waurich TUD 2013-07"
  input array<tuple<Integer,Real,Integer>> nodeInfo;
  output list<list<Integer>> parallelSetsOut;
protected
  Integer numLevels;
algorithm
  numLevels := Util.arrayFold(nodeInfo,numberOfLevels,0);
  parallelSetsOut := List.fold1(List.intRange(arrayLength(nodeInfo)),gatherParallelSets1,nodeInfo,List.fill({},numLevels));
end gatherParallelSets;


protected function numberOfLevels " gets the number of values
author: Waurich TUD 2013-07"
  input tuple<Integer,Real,Integer> nodeInfoEntry;
  input Integer numLevelsIn;
  output Integer numLevelsOut;
protected
  Integer levelIn;
algorithm
  (levelIn,_,_) := nodeInfoEntry;
  numLevelsOut := intMax(levelIn,numLevelsIn);
end numberOfLevels;


protected function gatherParallelSets1 " folding function for gatherParallelSets
author: Waurich TUD 2013-07"
  input Integer idx;
  input array<tuple<Integer,Real,Integer>> nodeInfo;
  input list<list<Integer>> parallelSetIn;
  output list<list<Integer>> parallelSetOut;
protected
  Integer level;
  list<Integer> pSet;
algorithm
  ((level,_,_)) := arrayGet(nodeInfo,idx);
  pSet := listGet(parallelSetIn,level);
  pSet := idx :: pSet;
  parallelSetOut := List.replaceAt(pSet,level-1,parallelSetIn);
end gatherParallelSets1;


protected function getRootParentLst
  input Integer rootIdx;
  input list<Integer> rootsIn;
  input list<list<Integer>> childLstIn;
  input list<Integer> parentLstIn;
  output list<Integer> parentLstOut;
algorithm
  parentLstOut := matchcontinue(rootIdx,rootsIn,childLstIn,parentLstIn)
    local
      Integer rootNode;
      list<Integer> childLst;
      list<Integer> parentLst;
    case(_,_,_,_)
      equation
        // get the parentList for rootNodes
        true = List.isEmpty(parentLstIn);
        rootNode = listGet(rootsIn,rootIdx);
        childLst = listGet(childLstIn,rootIdx);
        false = List.isEmpty(childLst);
        parentLst = List.fill(rootNode,listLength(childLst));
      then
        parentLst;
    case(_,_,_,_)
      equation
        // append the parentList for successorNodes
        false = List.isEmpty(parentLstIn);
        rootNode = listGet(rootsIn,rootIdx);
        childLst = listGet(childLstIn,rootIdx);
        false = List.isEmpty(childLst);
        parentLst = List.fill(rootNode,listLength(childLst));
        parentLst = listAppend(parentLstIn,parentLst);
      then
        parentLst;
    case(_,_,_,_)
      equation
        // handle nodes that should not be analysed yet
        false = List.isEmpty(parentLstIn);
        _ = listGet(rootsIn,rootIdx);
        childLst = listGet(childLstIn,rootIdx);
        true = List.isEmpty(childLst);
      then
        parentLstIn;
    case(_,_,_,_)
      equation
        // handle nodes that should not be analysed yet
        true = List.isEmpty(parentLstIn);
        _ = listGet(rootsIn,rootIdx);
        childLst = listGet(childLstIn,rootIdx);
        true = List.isEmpty(childLst);
      then
        parentLstIn;
      else
        equation
          print("getRootParentLst failed! \n");
        then
          fail();
  end matchcontinue;
end getRootParentLst;

protected function getCostsForNode " function to compute the costs for the next node (including the execution costs and the communication costs).
the given nodeIndeces are from the current graph and will be transformed to original indeces via inComps by this function
author:Waurich TUD 2013-07"
  input Integer parentNode;
  input Integer childNode;
  input array<list<Integer>> inComps;
  input array<tuple<Integer,Real>> exeCosts;
  input array<list<tuple<Integer,Integer,Integer>>> commCosts;
  output Real costsOut;
algorithm
  costsOut := matchcontinue(parentNode,childNode,inComps,exeCosts,commCosts)
    local
      Real costs;
      Integer commCost;
      Integer primalChild;
      Integer primalParent;
      list<Integer> primalChildLst;
      list<Integer> primalParentLst;
      list<tuple<Integer,Integer,Integer>> edgeCostLst;
    case(0,_,_,_,_)
      equation
        // the root node is not contracted
        primalChildLst = arrayGet(inComps,childNode);
        true = listLength(primalChildLst) == 1;
        primalChild = listGet(primalChildLst,1);
        ((_,costs)) = arrayGet(exeCosts,primalChild);
      then
        costs;
    case(0,_,_,_,_)
      equation
        // the root node is contracted
        primalChildLst = arrayGet(inComps,childNode);
        true = listLength(primalChildLst) > 1;
        _ = listGet(primalChildLst,1);
        costs = getCostsForContractedNodes(primalChildLst,exeCosts);
      then
        costs;
    case(_,_,_,_,_)
      equation
        // the childNode is not contracted
        primalChildLst = arrayGet(inComps,childNode);
        primalParentLst = arrayGet(inComps,parentNode);
        true = listLength(primalChildLst) == 1;
        primalChild = listGet(primalChildLst,1);
        primalParent = listGet(primalParentLst,1);
        ((_,costs)) = arrayGet(exeCosts,primalChild);
        ((_,_,commCost)) = getCommunicationCost(primalChild, primalParent ,commCosts);
        costs = costs +. intReal(commCost);
      then
        costs;
    case(_,_,_,_,_)
      equation
        // the childNode is contracted
        primalChildLst = arrayGet(inComps,childNode);
        _ = arrayGet(inComps,parentNode);
        true = listLength(primalChildLst) > 1;
        costs = getCostsForContractedNodes(primalChildLst,exeCosts);
      then
        costs;
    else
      equation
        print("getCostsForNode failed! \n");
      then
        fail();
  end matchcontinue;
end getCostsForNode;

protected function getCostsForContractedNodes "sums up alle execution costs for a contracted node.
authro:Waurich TUD 2013-10"
  input list<Integer> nodeList;
  input array<tuple<Integer,Real>> exeCosts;
  output Real costsOut;
algorithm
  costsOut := List.fold1(nodeList,getCostsForContractedNodes1,exeCosts,0.0);
end getCostsForContractedNodes;

protected function getCostsForContractedNodes1 "gets exeCosts for one node and add it to the foldType.
author:Waurich TUD 2013-10"
  input Integer node;
  input array<tuple<Integer,Real>> exeCosts;
  input Real costsIn;
  output Real costsOut;
protected
  Real exeCost;
algorithm
  ((_,exeCost)) := arrayGet(exeCosts,node);
  costsOut := realAdd(costsIn,exeCost);
end getCostsForContractedNodes1;

protected function getNodeCoords " computes the location of the nodes in the .graphml  with regard to the parallel sets
author:Waurich TUD 2013-07"
  input list<list<Integer>> parallelSets;
  input TaskGraph graphIn;
  output array<tuple<Integer,Integer>> nodeCoordsOut;
protected
  array<tuple<Integer,Integer>> nodeCoords;
  Integer size;
algorithm
  size := arrayLength(graphIn);
  nodeCoords := arrayCreate(size,((0,0)));
  nodeCoords := List.fold1(List.intRange(size),getYCoordForNode,parallelSets,nodeCoords);
  nodeCoordsOut := nodeCoords;
  //print("nodeCoords"+&stringDelimitList(List.map(arrayList(nodeCoords),tupleToString),",")+&"\n");
end getNodeCoords;

protected function getYCoordForNode "fold function to compute the y-coordinate for the graph.author: Waurich TUD 2013-07"
  input Integer compIdx;
  input list<list<Integer>> parallelSets;
  input array<tuple<Integer,Integer>> nodeCoordsIn;
  output array<tuple<Integer,Integer>> nodeCoordsOut;
protected
  Integer parallelSetIdx;
  Integer xCoord;
  Integer yCoord;
  Integer levelInterval;
  tuple<Integer,Integer> coords;
algorithm
  //levelInterval := 80;
  parallelSetIdx := getParallelSetForComp(compIdx,1,parallelSets);
  ((xCoord,yCoord)) := arrayGet(nodeCoordsIn,compIdx);
  //coords := ((xCoord,parallelSetIdx*levelInterval));
  coords := ((xCoord,parallelSetIdx));
  nodeCoordsOut := arrayUpdate(nodeCoordsIn,compIdx,coords);
end getYCoordForNode;

protected function getParallelSetForComp " find the parallelSet the inComp belongs to.
author: Waurich TUD 2013-07"
  input Integer compIn;
  input Integer setIdx;
  input list<list<Integer>> parallelSets;
  output Integer parallelSetOut;
algorithm
  parallelSetOut := matchcontinue(compIn,setIdx,parallelSets)
    local
      list<Integer> parallelSet;
      Integer parallelSetTmp;
    case(_,_,_)
      equation
        true = setIdx <= listLength(parallelSets);
        parallelSet = listGet(parallelSets,setIdx);
        //print("is "+&intString(compIn)+&" member of set "+&intString(setIdx)+&" with the nodes "+&stringDelimitList(List.map(parallelSet,intString),",")+&"\n");
        true = List.isMemberOnTrue(compIn,parallelSet,intEq);
        //print("true \n");
      then
        setIdx;
    case(_,_,_)
      equation
        true = setIdx <= listLength(parallelSets);
        parallelSet = listGet(parallelSets,setIdx);
        //print("is "+&intString(compIn)+&" member of set "+&intString(setIdx)+&" with the nodes "+&stringDelimitList(List.map(parallelSet,intString),",")+&"\n");
        false = List.isMemberOnTrue(compIn,parallelSet,intEq);
        //print("false \n");
        parallelSetTmp = getParallelSetForComp(compIn,setIdx+1,parallelSets);
      then
        parallelSetTmp;
    else
      equation
        print("getParallelSetForComp failed!\n");
      then
        fail();
  end matchcontinue;
end getParallelSetForComp;


protected function setLevelInNodeMark " sets the parallelSetIndex as a nodeMark.
author:wauricht TUD 2013-07"
  input Integer nodeIdx;
  input array<list<Integer>> inComps;
  input array<tuple<Integer,Integer>> nodeCoords;
  input array<Integer> nodeMarkIn;
  output array<Integer> nodeMarkOut;
algorithm
  nodeMarkOut := matchcontinue(nodeIdx,inComps,nodeCoords,nodeMarkIn)
    local
      array<Integer> nodeMarkTmp;
      list<Integer> components;
      Integer primalComp;
      Integer nodeMarkEntry;
      Integer yCoord;
    case(_,_,_,_)
      equation
        nodeMarkEntry = arrayGet(nodeMarkIn,nodeIdx);
        components = arrayGet(inComps,nodeIdx);
        primalComp = List.last(components);
        nodeMarkEntry = arrayGet(nodeMarkIn,primalComp);
        true = intEq(-1,nodeMarkEntry);
      then
        nodeMarkIn;
    case(_,_,_,_)
      equation
        nodeMarkEntry = arrayGet(nodeMarkIn,nodeIdx);
        components = arrayGet(inComps,nodeIdx);
        primalComp = List.last(components);
        nodeMarkEntry = arrayGet(nodeMarkIn,primalComp);
        false = intEq(-1,nodeMarkEntry);
        ((_,yCoord)) = arrayGet(nodeCoords,nodeIdx);
        nodeMarkTmp = arrayUpdate(nodeMarkIn,primalComp,yCoord);
      then
        nodeMarkTmp;
  end matchcontinue;
end setLevelInNodeMark;

protected function tupleToStringIntRealInt "author: Waurich TUD 2013-07
  Returns the given tuple as string."
  input tuple<Integer,Real,Integer> inTuple;
  output String result;

algorithm
  result := match(inTuple)
    local
      Integer int1,int2;
      Real real1;
    case((int1,real1,int2))
    then ("(" +& intString(int1) +& "," +& realString(real1) +&" , "+& intString(int2) +& ")");
  end match;
end tupleToStringIntRealInt;

public function transposeTaskGraph "author: marcusw
  Returns the given task graph as transposed version."
  input TaskGraph iTaskGraph;
  output TaskGraph oTaskGraphT;
protected
  TaskGraph transposedGraph;
algorithm
  transposedGraph := arrayCreate(arrayLength(iTaskGraph), {});
  ((transposedGraph,_)) := Util.arrayFold(iTaskGraph, transposeTaskGraph0, (transposedGraph,1));
  oTaskGraphT := transposedGraph;
end transposeTaskGraph;

protected function transposeTaskGraph0 "author: marcusw
  Helper function of transposeTaskGraph. Handles the parentlist of a child node."
  input list<Integer> iParentNodes;
  input tuple<TaskGraph,Integer> iGraph; //current graph and childIdx
  output tuple<TaskGraph,Integer> oGraph;
protected
  TaskGraph tmpGraph;
  Integer index;
algorithm
  (tmpGraph,index) := iGraph;
  tmpGraph := List.fold1(iParentNodes, transposeTaskGraph1, index, tmpGraph);
  oGraph := (tmpGraph,index+1);
end transposeTaskGraph0;

protected function transposeTaskGraph1 "author: marcusw
  Helper function of transposeTaskGraph0. Adds the childIdx to the parent-array-entry."
  input Integer iParentIdx;
  input Integer iChildIdx;
  input TaskGraph iTaskGraph;
  output TaskGraph oTaskGraph;
protected
  TaskGraph tmpGraph;
  list<Integer> tmpList;
algorithm
  tmpList := arrayGet(iTaskGraph,iParentIdx);
  tmpList := iChildIdx::tmpList;
  oTaskGraph := arrayUpdate(iTaskGraph,iParentIdx,tmpList);
end transposeTaskGraph1;

public function transposeCommCosts "author: marcusw
  Returns the given communication costs as transposed version."
  input array<list<tuple<Integer, Integer, Integer>>> iCommCosts;
  output array<list<tuple<Integer, Integer, Integer>>> oCommCosts;
protected
  array<list<tuple<Integer, Integer, Integer>>> tmpCommCosts;
algorithm
  tmpCommCosts := arrayCreate(arrayLength(iCommCosts), {});
  ((_,tmpCommCosts)) := Util.arrayFold(iCommCosts, transposeCommCosts0, (1,tmpCommCosts));
  oCommCosts := tmpCommCosts;
end transposeCommCosts;

protected function transposeCommCosts0 "author: marcusw
  Helper function for transposeCommCosts."
  input list<tuple<Integer, Integer, Integer>> iCosts; //costs for all edges from <%parentComp%> to children
  input tuple<Integer,array<list<tuple<Integer, Integer, Integer>>>> iCommCosts; //<parentCompIdx, commCosts>
  output tuple<Integer,array<list<tuple<Integer, Integer, Integer>>>> oCommCosts;
protected
  Integer iParentCompIdx;
  array<list<tuple<Integer, Integer, Integer>>> tmpCommCosts;
algorithm
  (iParentCompIdx, tmpCommCosts) := iCommCosts;
  tmpCommCosts := List.fold1(iCosts, transposeCommCosts1, iParentCompIdx, tmpCommCosts);
  oCommCosts := (iParentCompIdx+1, tmpCommCosts);
end transposeCommCosts0;

protected function transposeCommCosts1 "author: marcusw
  Helper function for transposeCommCosts0."
  input tuple<Integer, Integer, Integer> iCost;
  input Integer iParentCompIdx;
  input array<list<tuple<Integer, Integer, Integer>>> iCommCosts;
  output array<list<tuple<Integer, Integer, Integer>>> oCommCosts;
protected
  array<list<tuple<Integer, Integer, Integer>>> tmpCommCosts;
  list<tuple<Integer, Integer, Integer>> costs;
  Integer nodeIdx, numOfVars, reqCycles;
algorithm
  oCommCosts := matchcontinue(iCost, iParentCompIdx, iCommCosts)
    case((nodeIdx, numOfVars, reqCycles),_,_)
      equation
        true = intLe(nodeIdx, arrayLength(iCommCosts));
        costs = arrayGet(iCommCosts, nodeIdx);
        costs = (iParentCompIdx, numOfVars, reqCycles) :: costs;
        tmpCommCosts = arrayUpdate(iCommCosts, nodeIdx, costs);
      then tmpCommCosts;
    else iCommCosts;
  end matchcontinue;
end transposeCommCosts1;

public function getRootNodes "function getRootNodes
  author: marcusw,waurich
  Get all root nodes of the graph."
  input TaskGraph iTaskGraph; //the original graph
  output list<Integer> rootsOut;
protected
  Integer size;
  TaskGraph taskGraphT;
algorithm
  size := arrayLength(iTaskGraph);
  taskGraphT := BackendDAEUtil.transposeMatrix(iTaskGraph,size);
  rootsOut := getLeafNodes(taskGraphT);  // gets the exit nodes of the transposed graph
end getRootNodes;

public function getCommCostBetweenNodesInCycles"author: waurich TUD 2014-05
  Get the highest communication costs between the given nodes."
  input Integer iParentNodeIdx;
  input Integer iChildNodeIdx;
  input TaskGraphMeta iTaskGraphMeta;
  output Real oCommCost;
protected
  Integer commCost;
algorithm
  ((_,_,commCost)) := getCommCostBetweenNodes(iParentNodeIdx,iChildNodeIdx,iTaskGraphMeta);
  oCommCost := intReal(commCost);
end getCommCostBetweenNodesInCycles;

public function getCommCostBetweenNodes "author: marcusw
  Get the edge with highest communication costs between the given nodes."
  input Integer iParentNodeIdx;
  input Integer iChildNodeIdx;
  input TaskGraphMeta iTaskGraphMeta;
  output tuple<Integer,Integer,Integer> oCommCost;
protected
  list<Integer> childComps, parentComps;
  array<list<Integer>> inComps;
  array<list<tuple<Integer, Integer, Integer>>> commCosts;
  list<Option<tuple<Integer,Integer,Integer>>> concreteCommCostsOpt;
  list<tuple<Integer, Integer, Integer>> concreteCommCosts;
algorithm
  TASKGRAPHMETA(inComps=inComps,commCosts=commCosts) := iTaskGraphMeta;
  parentComps := arrayGet(inComps, iParentNodeIdx);
  childComps := arrayGet(inComps, iChildNodeIdx);
  concreteCommCostsOpt := List.map2(parentComps, getCommCostBetweenNodes0, childComps, commCosts);
  concreteCommCosts := List.flatten(List.map(concreteCommCostsOpt, List.fromOption));
  oCommCost := getHighestCommCost(concreteCommCosts, (-1,-1,-1));
end getCommCostBetweenNodes;

protected function getCommCostBetweenNodes0
  input Integer iParentComp;
  input list<Integer> iChildComps;
  input array<list<tuple<Integer, Integer, Integer>>> iCommCosts;
  output Option<tuple<Integer,Integer,Integer>> oHighestComm; //the communication with the highest costs
protected
  list<tuple<Integer, Integer, Integer>> commCosts, filteredCommCosts;
  tuple<Integer, Integer, Integer> highestCommCost;
algorithm
  oHighestComm := matchcontinue(iParentComp, iChildComps, iCommCosts)
    case(_,_,_)
      equation
        commCosts = arrayGet(iCommCosts, iParentComp);
        filteredCommCosts = List.filter1OnTrue(commCosts, getCommCostBetweenNodes1, iChildComps);
        true = List.isNotEmpty(filteredCommCosts);
        highestCommCost = getHighestCommCost(filteredCommCosts, (-1,-1,-1));
      then SOME(highestCommCost);
    else NONE();
  end matchcontinue;
end getCommCostBetweenNodes0;

protected function getCommCostBetweenNodes1
  input tuple<Integer, Integer, Integer> iCommCost;
  input list<Integer> iChildComps;
  output Boolean oResult;
protected
  Integer compIdx;
algorithm
  (compIdx,_,_) := iCommCost;
  oResult := List.exist1(iChildComps, intEq, compIdx);
end getCommCostBetweenNodes1;

protected function getHighestCommCost "function getHighestCommCost
  author: marcusw
  Get the communication with highest costs out of the given list."
  input list<tuple<Integer, Integer, Integer>> iCommCosts;
  input tuple<Integer,Integer,Integer> iHighestTuple;
  output tuple<Integer,Integer,Integer> oHighestTuple;
protected
  Integer highestCost, currentCost;
  tuple<Integer, Integer, Integer> head;
  list<tuple<Integer, Integer, Integer>> rest;
algorithm
  oHighestTuple := matchcontinue(iCommCosts, iHighestTuple)
    case((head as (_,_,currentCost))::rest, (_,_,highestCost))
      equation
        true = intGt(currentCost, highestCost);
      then getHighestCommCost(rest, head);
    case((head as (_,_,currentCost))::rest, (_,_,highestCost))
      equation
        true = intGt(currentCost, highestCost);
      then getHighestCommCost(rest, iHighestTuple);
    else iHighestTuple;
  end matchcontinue;
end getHighestCommCost;

public function sumUpExecCosts
  input TaskGraphMeta iMeta;
  output tuple<Integer,Real> execCosts;
protected
  tuple<Integer,Real> costs;
  array<tuple<Integer,Real>> exeCosts;
algorithm
  execCosts := match(iMeta)
    case(TASKGRAPHMETA(exeCosts=exeCosts))
      equation
        costs = Util.arrayFold(exeCosts, sumUpExecCosts1, (0,0.0));
      then costs;
    else ((0,0.0));
  end match;
end sumUpExecCosts;

protected function sumUpExecCosts1
  input tuple<Integer,Real> iEntry;
  input tuple<Integer,Real> iCostsOps;
  output tuple<Integer,Real> oCostsOps;
protected
  Real tmpCosts, iCosts;
  Integer tmpOps, iOps;
algorithm
  (tmpOps,tmpCosts) := iEntry;
  (iOps,iCosts) := iCostsOps;
  tmpCosts := realAdd(iCosts,tmpCosts);
  tmpOps := tmpOps + iOps;
  oCostsOps := (tmpOps,tmpCosts);
end sumUpExecCosts1;

//TODO: Remove
public function roundReal "rounds a real to the nth decimal
author: Waurich TUD 2014-01"
  input Real inReal;
  input Integer nIn;
  output Real outReal;
protected
  Integer int;
  Real real;
algorithm
  real := realMul(inReal,realPow(10.0,intReal(nIn)));
  real := realFloor(real);
  outReal := realDiv(real,realPow(10.0,intReal(nIn)));
end roundReal;

protected function sumEdge
  input list<Integer> edges;
  input Integer innumedge;
  output Integer outnumedge;
algorithm
  outnumedge := innumedge+listLength(edges);
 end sumEdge;

protected function getSingleRelations
  input Integer edge;
  input Integer n;
  input TaskGraphMeta iTaskGraphMeta;
  input list<tuple<Integer,Integer,Integer>> irelations;
  output list<tuple<Integer,Integer,Integer>> orelations;
protected
  tuple<Integer,Integer,Integer> data;
  Integer costs;
algorithm
  data := getCommCostBetweenNodes(n,edge,iTaskGraphMeta);
  (_,_,costs) := data;
  orelations := listAppend(irelations,{(edge,n,costs)});
  orelations := listAppend(orelations,{(n,edge,costs)});
end getSingleRelations;

protected function getRelations
  input list<Integer> edges;
  input TaskGraphMeta iTaskGraphMeta;
  input tuple<list<tuple<Integer,Integer,Integer>>,Integer> irelations;
  output tuple<list<tuple<Integer,Integer,Integer>>,Integer> orelations;
protected
  Integer n;
  list<tuple<Integer,Integer,Integer>> relations;
  list<tuple<Integer,Integer,Integer>> orel;
algorithm
  (relations,n) := irelations;
  orel := List.fold2(edges,getSingleRelations,n,iTaskGraphMeta,relations);
  orelations := (orel, n+1);
end getRelations;

protected function sortEdgeHelp
  input tuple<Integer,Integer,Integer> edge;
  input Integer actnode;
  input array<Integer> adjncy;
  input array<Integer> adjwgt;
  input Integer imarker;
  output Integer omarker;
algorithm
  omarker := matchcontinue (edge,actnode,adjncy,adjwgt,imarker)
    local
      Integer tonode;
      Integer fromnode;
      Integer cost;
    case ((fromnode,tonode,cost),_,_,_,_)
      equation
        true = intEq(fromnode,actnode);
        _ = arrayUpdate(adjwgt,imarker,cost);
        _ = arrayUpdate(adjncy,imarker,tonode-1);
      then
        imarker+1;
    case (_,_,_,_,_)
      then imarker;
  end matchcontinue;
end sortEdgeHelp;

protected function sortEdge
  input Integer actnode;
  input array<Integer> xadj;
  input array<Integer> adjncy;
  input array<Integer> adjwgt;
  input list<tuple<Integer,Integer,Integer>> help;
  input Integer imarker;
  output Integer omarker;
protected
  Integer position;
algorithm
  omarker := List.fold3(help,sortEdgeHelp,actnode,adjncy,adjwgt,imarker);
  _ := arrayUpdate(xadj,actnode+1,omarker-1);
end sortEdge;


protected function setVwgt
  input Integer node;
  input array<Integer> vwgt;
  input TaskGraphMeta iTaskGraphMeta;
protected
  tuple<Integer,Real> value;
  Real rv;
algorithm
  value:=getExeCost(node,iTaskGraphMeta);
  (_,rv):=value;
  _:=arrayUpdate(vwgt,node,realInt(rv));
end setVwgt;

public function prepareMetis
  input TaskGraph iTaskGraph;
  input TaskGraphMeta iTaskGraphMeta;
  output array<Integer> xadj;
  output array<Integer> adjncy;
  output array<Integer> vwgt;
  output array<Integer> adjwgt;
protected
  Integer n;
  Integer m;
  tuple<list<tuple<Integer,Integer,Integer>>,Integer> adjundirected;
  list<tuple<Integer,Integer,Integer>> help;
  list<Integer> allTheNodes;
  array<list<Integer>> inComps;

algorithm
  help := {};
  n := arrayLength(iTaskGraph);
  xadj := arrayCreate(n+1,0);
  m := List.fold(arrayList(iTaskGraph),sumEdge,0);
  adjwgt := arrayCreate(2*m,0);
  adjundirected := List.fold1(arrayList(iTaskGraph),getRelations,iTaskGraphMeta,({},1));
  (help,_) := adjundirected;
  allTheNodes := List.intRange(n);
  adjncy := arrayCreate(2*m,0);

  xadj := arrayUpdate(xadj,1,0);
  _ := List.fold4(allTheNodes,sortEdge,xadj,adjncy,adjwgt,help,1);
  vwgt := arrayCreate(n,0);
  List.map2_0(allTheNodes,setVwgt,vwgt,iTaskGraphMeta);
end prepareMetis;


protected function listNodes
  input Integer node;
  input list<Integer> l_eint;
  output list<Integer> l_eint_out;
protected
  Integer actnode;
algorithm
  actnode := node-1;
  l_eint_out := listAppend(l_eint, {actnode});
  print("l_eint length:" +& intString(listLength(l_eint_out))+&"\n");
end listNodes;

protected function getHedge
  input list<Integer> childnodes;
  //input TaskGraphMeta iTaskGraphMeta;
  input tuple<Integer,Integer,list<Integer>,list<Integer>,list<Integer>> actnode;
  output tuple<Integer,Integer,list<Integer>,list<Integer>,list<Integer>> actnode_out;
algorithm
    actnode_out := match (childnodes,actnode)
    local
        Integer n;
        Integer node;
        Integer position;
        list<Integer> l_eptr;
        list<Integer> l_eint;
        list<Integer> l_hewgts;
        tuple<Integer,Integer,list<Integer>,list<Integer>,list<Integer>> help;
    case ({},(node,position,l_eptr,l_eint,l_hewgts))
        equation
            help=(node+1,position,l_eptr,l_eint,l_hewgts);
        then help;
    case (_,(node,position,l_eptr,l_eint,l_hewgts))
        equation
            n=node-1;
            l_eint = listAppend(l_eint,{n});
            l_eint = List.fold(childnodes,listNodes,l_eint);
            n=position+listLength(childnodes)+1;
            l_eptr = listAppend(l_eptr,{n});
            help = (node+1,n,l_eptr,l_eint,l_hewgts);
        then help;
    end match;
end getHedge;

public function preparehMetis
  input TaskGraph iTaskGraph;
  input TaskGraphMeta iTaskGraphMeta;
  output array<Integer> vwgts;
  output array<Integer> eptr;
  output array<Integer> eint;
  output array<Integer> hewgts;
protected
  Integer n;
  Integer m;
  list<Integer> l_eptr;
  list<Integer> l_eint;
  list<Integer> l_hewgts;
  list<Integer> allTheNodes;
  tuple<Integer,Integer,list<Integer>,list<Integer>,list<Integer>> result;
algorithm
  n := arrayLength(iTaskGraph);
  result := List.fold(arrayList(iTaskGraph),getHedge,(1,0,{0},{},{}));
  (_,_,l_eptr,l_eint,l_hewgts) := result;
  print("Diagnostic length: " +& intString(listLength(l_eptr)) +& " " +& intString(listLength(l_eint)) +& "\n");
  allTheNodes := List.intRange(n);
  vwgts := arrayCreate(n,0);
  List.map2_0(allTheNodes,setVwgt,vwgts,iTaskGraphMeta);
  eptr := listArray(l_eptr);
  eint := listArray(l_eint);
  hewgts := listArray(l_hewgts);
end preparehMetis;

//-----------------------------------------------------
// get annotations from backendDAE and display in graphML
//-----------------------------------------------------
protected function setAnnotationsForTasks"sets annotations of variables and equations for every task in the array (index: task idx)
author:Waurich TUD 2014-05 "
  input TaskGraphMeta taskGraphInfo;
  input BackendDAE.BackendDAE backendDAE;
  input array<String> annotInfoIn;
  output array<String> annotInfoOut;
protected
  BackendDAE.EqSystems systs;
algorithm
  BackendDAE.DAE(eqs=systs) := backendDAE;
  ((_,annotInfoOut)) := List.fold1(systs,setAnnotationsForTasks1,taskGraphInfo,(0,annotInfoIn));
end setAnnotationsForTasks;

protected function setAnnotationsForTasks1"sets annotations for a task of vars and equations of an equationsystem
author: Waurich TUD 2014-05"
  input BackendDAE.EqSystem syst;
  input TaskGraphMeta taskGraphInfo;
  input tuple<Integer,array<String>> infoIn;
  output tuple<Integer,array<String>> infoOut;
protected
  Integer idx;
  array<String> annots;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqs;
algorithm
  (idx,annots) := infoIn;
  BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqs) := syst;
  //set annotations of variables
  annots := List.fold3(List.intRange(BackendVariable.numVariables(vars)),setAnnotationsForVar,vars,taskGraphInfo,idx,annots);
  infoOut := (BackendVariable.numVariables(vars)+idx,annots);
end setAnnotationsForTasks1;

protected function setAnnotationsForVar"sets the annotations of a variable in the annotArray"
  input Integer backendVarIdx;
  input BackendDAE.Variables vars;
  input TaskGraphMeta taskGraphInfo;
  input Integer eqSysOffset;
  input array<String> annotInfoIn;
  output array<String> annotInfoOut;
algorithm
  annotInfoOut := matchcontinue(backendVarIdx,vars,taskGraphInfo,eqSysOffset,annotInfoIn)
    local
      Integer compIdx, taskIdx;
      String annotString;
      BackendDAE.Var var;
      DAE.ComponentRef cr;
      Option<SCode.Comment> annot;
      array<list<Integer>> inComps;
      array<tuple<Integer,Integer,Integer>> varCompMapping;
      array<tuple<Integer,Integer,Integer>> eqCompMapping;
      array<Integer> nodeMark;
    case(_,_,TASKGRAPHMETA(inComps = inComps,varCompMapping=varCompMapping, eqCompMapping=eqCompMapping, nodeMark=nodeMark),_,_)
      equation
        var = BackendVariable.getVarAt(vars,backendVarIdx);
        BackendDump.printVar(var);
        true = BackendVariable.hasAnnotation(var);
        ((compIdx,_,_)) = arrayGet(varCompMapping,backendVarIdx+eqSysOffset);
        taskIdx = getCompInComps(compIdx,1,inComps,nodeMark);
        annot = BackendVariable.getAnnotationComment(var);
        annotString = arrayGet(annotInfoIn,taskIdx);
        cr = BackendVariable.varCref(var);
        annotString = annotString +& "("+&ComponentReference.printComponentRefStr(cr)+&": "+&DAEDump.dumpCommentAnnotationStr(annot)+&") ";
        _ = arrayUpdate(annotInfoIn,taskIdx,annotString);
      then
        annotInfoIn;
    else
      then
        annotInfoIn;
  end matchcontinue;
end setAnnotationsForVar;

end HpcOmTaskGraph;
