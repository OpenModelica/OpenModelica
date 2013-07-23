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

encapsulated package HpcOmTaskGraph
" file:        HpcOmTaskGraph.mo
  package:     HpcOmTaskGraph
  description: HpcOmTaskGraph contains the whole logic to create a TaskGraph on BLT-Level

  RCS: $Id: HpcOmTaskGraph.mo 2013-05-24 11:12:35Z marcusw $
"
public import BackendDAE;
public import DAE;
public import SimCode;

protected import BackendDAEOptimize;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import Debug;
protected import Expression;
protected import ExpressionSolve;
protected import GraphML;
protected import HpcOmBenchmark;
protected import List;
protected import System;
protected import Util;

//----------------------------
//  Graph Structure
//----------------------------
public
type TaskGraph = array<list<Integer>>;
  
public uniontype TaskGraphMeta   // stores all the metadata for the TaskGraph
  record TASKGRAPHMETA
    array<list<Integer>> inComps; //all StrongComponents from the BLT that belong to the Nodes
    array<Integer> varSccMapping;  // maps each variable to a comp with compIdx
    array<Integer> eqSccMapping;  // maps each equation to a comp with compIdx
    list<Integer> rootNodes;  // all Nodes without predecessor
    array<String> nodeNames; // the name of the nodes for the graphml generation
    array<String> nodeDescs;  // a description of the nodes for the graphml generation
    array<tuple<Integer,Real>> exeCosts;  // the execution cost for the nodes <numberOfOperations, requiredCycles
    array<list<tuple<Integer,Integer,Integer>>> commCosts;  // the communication cost tuple(_,numberOfVars,requiredCycles) for an edge from array[parentNode] to tuple(childNode,_) 
    array<Integer> nodeMark;  // put some additional stuff in here
  end TASKGRAPHMETA;
end TaskGraphMeta;  
  
  
//functions to build the task graph from the BLT structure
//------------------------------------------
//------------------------------------------
  
public function createTaskGraph "function createTaskGraph
  author: marcusw,waurich
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
  (graph,graphData) := getEmptyTaskGraph(1);
  ((graph,graphData)) := List.fold1(systs,createTaskGraph0,shared,(graph,graphData));  
  fileName := ("taskGraph"+&filenamePrefix+&".graphml"); 
  dumpAsGraphMLSccLevel(graph,graphData,fileName);
  //printTaskGraph(graph);
  //printTaskGraphMeta(graphData);
  graphOut := graph;
  graphDataOut := graphData; 
end createTaskGraph;


public function getSystemComponents "function getSystemComponents
  author: marcusw
  Returns all components of the given BackendDAE.
  "
  input BackendDAE.BackendDAE iDae;
  output BackendDAE.StrongComponents oComps;
  output array<BackendDAE.EqSystem> oMapping; //Map each component to the EqSystem

protected
  BackendDAE.EqSystems systs;
  List<BackendDAE.EqSystem> tmpSystems;
  BackendDAE.StrongComponents tmpComps;
  
algorithm
  (oComps,oMapping) := match(iDae)
    case(BackendDAE.DAE(eqs=systs))
      equation
        ((tmpComps, tmpSystems)) = List.fold(systs,getSystemComponents0,({},{}));
      then (tmpComps,listArray(tmpSystems));
    else
      then fail();
  end match;
end getSystemComponents;


protected function getGraphComponents
  input TaskGraphMeta iTaskGraphMeta;
  input array<BackendDAE.StrongComponent> systComps;
  output BackendDAE.StrongComponents oComps;
  
protected
  BackendDAE.StrongComponents tmpComps;
  array<list<Integer>> inComps;
  
algorithm
  tmpComps := {};
  TASKGRAPHMETA(inComps=inComps) := iTaskGraphMeta;
  oComps := Util.arrayFold1(inComps,getGraphComponents0,systComps,{});
end getGraphComponents;


protected function getGraphComponents0
  input list<Integer> inComp;
  input array<BackendDAE.StrongComponent> systComps;
  input BackendDAE.StrongComponents iNodeComps;
  output BackendDAE.StrongComponents oNodeComps;
  
protected
  BackendDAE.StrongComponents tmpNodeComps;
  
algorithm
  tmpNodeComps := List.fold1(inComp, getGraphComponents1, systComps, {});
  oNodeComps := listAppend(iNodeComps,tmpNodeComps);
end getGraphComponents0;


protected function getGraphComponents1
  input Integer compIdx;
  input array<BackendDAE.StrongComponent> systComps;
  input BackendDAE.StrongComponents iComps;
  output BackendDAE.StrongComponents oComps;
  
protected
  BackendDAE.StrongComponent comp;
  
algorithm
  comp := arrayGet(systComps,compIdx);
  oComps := comp::iComps;
  
end getGraphComponents1;

  
protected function getSystemComponents0
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.StrongComponents, list<BackendDAE.EqSystem>> iSystMapping;
  output tuple<BackendDAE.StrongComponents, list<BackendDAE.EqSystem>> oSystMapping; //Map each component to the EqSystem
  
protected
  BackendDAE.StrongComponents tmpComps, comps;
  list<BackendDAE.EqSystem> tmpSystMapping;
  
algorithm
  oSystMapping := match(isyst, iSystMapping)
    case(BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)), (tmpComps,tmpSystMapping))
      equation
        tmpSystMapping = List.fold1(comps, getSystemComponents1, isyst, tmpSystMapping);
        tmpComps = listAppend(tmpComps,comps);
        print("getSystemComponents0 number of components " +& intString(listLength(comps)) +& "\n");
      then ((tmpComps, tmpSystMapping));
    else
      equation
        print("getSystemComponents0 failed");
      then fail();
  end match;
end getSystemComponents0;


protected function getSystemComponents1
  input BackendDAE.StrongComponent icomp;
  input BackendDAE.EqSystem isyst;
  input list<BackendDAE.EqSystem> iMapping; //Map each component to the EqSystem
  output list<BackendDAE.EqSystem> oMapping; //Map each component to the EqSystem
  
algorithm
  oMapping := listAppend(iMapping,{isyst});
end getSystemComponents1;

protected function getEmptyTaskGraph "generates an empty TaskGraph and empty TaskGraphMeta for a graph with numComps nodes.
author: Waurich TUD 2013-06"
  input Integer numComps;
  output TaskGraph graph;
  output TaskGraphMeta graphData;
protected
  array<list<Integer>> inComps; 
  array<Integer> varSccMapping;  
  array<Integer> eqSccMapping; 
  list<Integer> rootNodes;  
  array<String> nodeNames; 
  array<String> nodeDescs;  
  array<tuple<Integer,Real>> exeCosts;  
  array<list<tuple<Integer,Integer,Integer>>> commCosts; 
  array<Integer> nodeMark;
algorithm
  graph := arrayCreate(numComps,{});
  inComps := arrayCreate(numComps,{});  
  varSccMapping := arrayCreate(1,0);   
  eqSccMapping := arrayCreate(1,0);   
  rootNodes := {}; 
  nodeNames := arrayCreate(numComps,"");
  nodeDescs :=  arrayCreate(numComps,""); 
  exeCosts := arrayCreate(numComps,(-1,-1.0)); 
  commCosts :=  arrayCreate(numComps,{});
  nodeMark := arrayCreate(numComps,0); 
  graphData := TASKGRAPHMETA(inComps,varSccMapping,eqSccMapping,rootNodes,nodeNames,nodeDescs,exeCosts,commCosts,nodeMark);
end getEmptyTaskGraph;


protected function createTaskGraph0 "function createTaskGraph0
  author: marcusw,waurich
  Creates a task graph out of the given system."
  input BackendDAE.EqSystem isyst; //The input system which should be analysed
  input BackendDAE.Shared ishared; //second argument of tuple is an extra argument
  input tuple<TaskGraph,TaskGraphMeta> graphInfoIn;
  output tuple<TaskGraph,TaskGraphMeta> grapInfoOut;
  //output BackendDAE.EqSystem osyst; //no change here -> this is always isyst
  //output tuple<BackendDAE.Shared,Boolean> oshared; //no change here -> this is always ishared
algorithm
  grapInfoOut := matchcontinue(isyst,ishared,graphInfoIn)
    local
      tuple<TaskGraph,TaskGraphMeta> tplOut;
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
      array<list<Integer>> adjLst;
      array<list<Integer>> adjLstOde;
      array<list<Integer>> inComps;
      array<Integer> ass1;
      array<Integer> ass2;
      array<Integer> eqSccMapping;
      array<tuple<Integer,Real>> exeCosts;
      array<Integer> nodeMark;
      array<Integer> varSccMapping; //Map each variable to the scc which solves her
      array<String> nodeNames;
      array<String> nodeDescs; 
      list<Integer> eventEqLst;
      list<Integer> eventVarLst;
      list<Integer> rootNodes; 
      list<Integer> rootVars;
      String fileName;
      String fileNameOde;
      Integer numberOfVars;
      Integer numberOfEqs;
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=ass1, ass2=ass2, comps=comps), orderedVars=BackendDAE.VARIABLES(numberOfVars=numberOfVars), orderedEqs=BackendDAE.EQUATION_ARRAY(numberOfElement=numberOfEqs)),(shared as BackendDAE.SHARED(functionTree=sharedFuncs)),(graphIn,graphDataIn))
      equation
        //Create Taskgraph for the first EqSystem
        TASKGRAPHMETA(varSccMapping=varSccMapping) = graphDataIn;
        true = arrayGet(varSccMapping,1)== 0;
        (_,incidenceMatrix,_) = BackendDAEUtil.getIncidenceMatrix(isyst, BackendDAE.NORMAL(), SOME(sharedFuncs));
        (graphTmp,graphDataTmp) = getEmptyTaskGraph(listLength(comps));
        TASKGRAPHMETA(inComps = inComps, rootNodes = rootNodes, nodeNames =nodeNames, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) = graphDataTmp;
        (varSccMapping,eqSccMapping) = createSccMapping(comps, numberOfVars, numberOfEqs); 
        nodeDescs = getEquationStrings(comps,isyst);  //gets the description i.e. the whole equation, for every component
        ((graphTmp,inComps,commCosts,nodeNames,rootNodes,nodeMark,_)) = List.fold2(comps,createTaskGraph1,(incidenceMatrix,isyst,shared,listLength(comps)),(varSccMapping,eqSccMapping,{}),(graphTmp,inComps,commCosts,nodeNames,rootNodes,nodeMark,1));
        // gather the metadata
        graphDataTmp = TASKGRAPHMETA(inComps, varSccMapping, eqSccMapping, rootNodes, nodeNames, nodeDescs, exeCosts, commCosts, nodeMark);
        tplOut = ((graphTmp,graphDataTmp));
      then
        tplOut;
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=ass1, ass2=ass2, comps=comps), orderedVars=BackendDAE.VARIABLES(numberOfVars=numberOfVars), orderedEqs=BackendDAE.EQUATION_ARRAY(numberOfElement=numberOfEqs)),(shared as BackendDAE.SHARED(functionTree=sharedFuncs)),(graphIn,graphDataIn))
      equation
        //append the remaining equationsystems to the taskgraph
        TASKGRAPHMETA(varSccMapping=varSccMapping) = graphDataIn;
        false = arrayGet(varSccMapping,1)== 0;
        (_,incidenceMatrix,_) = BackendDAEUtil.getIncidenceMatrix(isyst, BackendDAE.NORMAL(), SOME(sharedFuncs));
        (graphTmp,graphDataTmp) = getEmptyTaskGraph(listLength(comps));
        TASKGRAPHMETA(inComps = inComps, rootNodes = rootNodes, nodeNames =nodeNames, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) = graphDataTmp;
        (varSccMapping,eqSccMapping) = createSccMapping(comps, numberOfVars, numberOfEqs); 
        nodeDescs = getEquationStrings(comps,isyst);  //gets the description i.e. the whole equation, for every component
        ((graphTmp,inComps,commCosts,nodeNames,rootNodes,nodeMark,_)) = List.fold2(comps,createTaskGraph1,(incidenceMatrix,isyst,shared,listLength(comps)),(varSccMapping,eqSccMapping,{}),(graphTmp,inComps,commCosts,nodeNames,rootNodes,nodeMark,1));
        // gather the metadata
        graphDataTmp = TASKGRAPHMETA(inComps, varSccMapping, eqSccMapping, rootNodes, nodeNames, nodeDescs, exeCosts, commCosts, nodeMark);
        (graphTmp,graphDataTmp) = taskGraphAppend(graphIn,graphDataIn,graphTmp,graphDataTmp); 
        tplOut = ((graphTmp,graphDataTmp));
      then
        tplOut;
    else
      equation
      print("createTaskGraph00 failed \n");
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
  array<Integer> eqSccMapping1, eqSccMapping2;
  array<tuple<Integer,Real>> exeCosts1, exeCosts2;
  array<Integer> nodeMark1, nodeMark2;
  array<Integer> varSccMapping1, varSccMapping2; //Map each variable to the scc which solves her
  array<String> nodeNames1, nodeNames2;
  array<String> nodeDescs1, nodeDescs2; 
  list<Integer> rootNodes1, rootNodes2;   
  TaskGraph graph2;
algorithm
  TASKGRAPHMETA(inComps = inComps1 ,varSccMapping=varSccMapping1, eqSccMapping=eqSccMapping1, rootNodes = rootNodes1, nodeNames =nodeNames1, nodeDescs= nodeDescs1, exeCosts = exeCosts1, commCosts=commCosts1, nodeMark=nodeMark1) := graphData1In;
  TASKGRAPHMETA(inComps = inComps2 ,varSccMapping=varSccMapping2, eqSccMapping=eqSccMapping2, rootNodes = rootNodes2, nodeNames =nodeNames2, nodeDescs= nodeDescs2, exeCosts = exeCosts2, commCosts=commCosts2, nodeMark=nodeMark2) := graphData2In;
  eqOffset := arrayLength(eqSccMapping1);
  idxOffset := arrayLength(graph1In);
  varOffset := arrayLength(varSccMapping1);
  graph2 := Util.arrayMap1(graph2In,updateTaskGraphSystem,idxOffset);
  graphOut := Util.arrayAppend(graph1In,graph2);
  inComps2 := Util.arrayMap1(inComps2,updateTaskGraphSystem,idxOffset);
  inComps2 := Util.arrayAppend(inComps1,inComps2);
  varSccMapping2 := Util.arrayMap1(varSccMapping2,intAdd,idxOffset);
  varSccMapping2 := Util.arrayAppend(varSccMapping1,varSccMapping2);
  eqSccMapping2 := Util.arrayMap1(eqSccMapping2,intAdd,idxOffset);
  eqSccMapping2 := Util.arrayAppend(eqSccMapping1,eqSccMapping2);
  rootNodes2 := List.map1(rootNodes2,intAdd,idxOffset);
  rootNodes2 := listAppend(rootNodes1,rootNodes2);
  nodeNames2 := Util.arrayMap1(nodeNames2,stringAppend," subsys");  //TODO: change this
  nodeNames2 := Util.arrayAppend(nodeNames1,nodeNames2); 
  nodeDescs2 := Util.arrayAppend(nodeDescs1,nodeDescs2);
  exeCosts2 := Util.arrayAppend(exeCosts1,exeCosts2);
  commCosts2 := Util.arrayMap1(commCosts2,updateCommCosts,idxOffset);
  commCosts2 := Util.arrayAppend(commCosts1,commCosts2);
  nodeMark2 := Util.arrayAppend(nodeMark1,nodeMark2);
  graphDataOut := TASKGRAPHMETA(inComps2,varSccMapping2,eqSccMapping2,rootNodes2,nodeNames2,nodeDescs2,exeCosts2,commCosts2,nodeMark2);  
end taskGraphAppend;


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
  
  
protected function createTaskGraph1 "function createTaskGraph10
  author: marcusw,waurich
  Appends the task-graph information for the given StrongComponent to the given graph."
  input BackendDAE.StrongComponent component;
  input tuple<BackendDAE.IncidenceMatrix,BackendDAE.EqSystem,BackendDAE.Shared,Integer> isystInfo; //<incidenceMatrix,isyst,ishared,numberOfComponents> in very compact form
  input tuple<array<Integer>,array<Integer>,list<Integer>> varInfo;
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
  array<Integer>  varSccMapping;
  array<Integer> eqSccMapping;
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
  (varSccMapping,eqSccMapping,eventVarLst) := varInfo;
  (graphIn,inComps,commCosts,nodeNames,rootNodes,nodeMark,componentIndex) := graphInfoIn;
  inComps := arrayUpdate(inComps,componentIndex,{componentIndex});
  nodeName := BackendDump.strongComponentString(component);
  nodeNames := arrayUpdate(nodeNames,componentIndex,nodeName);
  _ := HpcOmBenchmark.benchSystem();
  //nodeMark := arrayUpdate(nodeMark,componentIndex,getNodeMark(componentIndex,incidenceMatrix,varSccMapping,eqSccMapping));
  unsolvedVars := getUnsolvedVarsBySCC(component,incidenceMatrix,eventVarLst);
  requiredSccs := arrayCreate(numberOfComps,0); //create a ref-counter for each component
  requiredSccs := List.fold1(unsolvedVars,fillSccList,varSccMapping,requiredSccs); 
  ((_,requiredSccs_RefCount)) := Util.arrayFold(requiredSccs, convertRefArrayToList, (1,{}));
  commCosts := updateCommCostBySccRef(requiredSccs_RefCount, componentIndex, commCosts);
  (graphTmp,rootNodes) := fillAdjacencyList(graphIn,rootNodes,componentIndex,requiredSccs_RefCount,1);
  graphTmp := Util.arrayMap1(graphTmp,List.sort,intGt);
  graphInfoOut := (graphTmp,inComps,commCosts,nodeNames,rootNodes,nodeMark,componentIndex+1);
end createTaskGraph1;   


protected function updateCommCostBySccRef "function updateCommCostBySccRef
  author: marcusw
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

protected function updateCommCostBySccRef0 "function updateCommCostBySccRef0
  author: marcusw
  Helper function which converts a tuple<Integer,Integer> to a tuple<Integer,Integer,-1>."
  input tuple<Integer,Integer> iTuple;
  output tuple<Integer,Integer,Integer> oTuple;
protected
  Integer i1,i2;
algorithm
  (i1,i2) := iTuple;
  oTuple := ((i1,i2,-1));

end updateCommCostBySccRef0;

protected function updateCommCostBySccRef1 "function updateCommCostBySccRef1
  author: marcusw
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
  print("updateCommCostBySccRef1 added edge from " +& intString(sourceSccIdx) +& " to " +& intString(iEdgeTarget) +& "\n");
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
        true = listLength(parentLst) == 0;
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
    else then ();
  end matchcontinue;
end printReqScc;


protected function getNodeMark "sets the nodeMark for an component given by compIdxIn.
author: Waurich TUD 2013-07"
  input Integer compIdxIn;
  input BackendDAE.IncidenceMatrix incidenceMatrix;
  input array<Integer> varSccMapping;
  input array<Integer> eqSccMapping;
  output Integer numberOut;
protected 
  list<list<Integer>> allVars;
  list<Integer> allEqs;
  list<Integer> allMatchedVars;
  list<Integer> assignedVars;
  list<Integer> neededVars;
algorithm
  allEqs := getMappingForComp(compIdxIn,eqSccMapping,1,{});
  allVars := List.map1(allEqs,getVarsForEqs,incidenceMatrix);
  allMatchedVars := getMappingForComp(compIdxIn,varSccMapping,1,{});
  (_,neededVars,_) := List.intersection1OnTrue(List.unique(List.flatten(allVars)),allMatchedVars,intEq);
  numberOut := listLength(neededVars);
end getNodeMark;


protected function getVarsForEqs " gets all variables of an equation
author:Waurich TUD 2013-07"
  input Integer eqIn;
  input BackendDAE.IncidenceMatrix incidenceMatrix;
  output list<Integer> varLst;
algorithm
  varLst := arrayGet(incidenceMatrix,eqIn);
end getVarsForEqs;


protected function getMappingForComp " gets the mapping info for a comp i.e. either alle eqs in a component for eqSccMapping or all solved vars in a component for varSccMapping.
author:Waurich TUD 201307"
  input Integer compIdxIn;
  input array<Integer> SccMapping;
  input Integer mapIdx;
  input list<Integer> LstIn;
  output list<Integer> LstOut;
algorithm
  LstOut := matchcontinue(compIdxIn,SccMapping,mapIdx,LstIn)
    local
      Integer entry;
      list<Integer> lstTmp;
    case(_,_,_,_)
      equation
        true = arrayLength(SccMapping) >= mapIdx;
        entry = arrayGet(SccMapping,mapIdx);
        true = intEq(entry,compIdxIn);
        lstTmp = mapIdx::LstIn;
        lstTmp = getMappingForComp(compIdxIn,SccMapping,mapIdx+1,lstTmp);
      then
        lstTmp;
    case(_,_,_,_)
      equation
        true = arrayLength(SccMapping) >= mapIdx;
        entry = arrayGet(SccMapping,mapIdx);
        false = intEq(entry,compIdxIn);
        lstTmp = getMappingForComp(compIdxIn,SccMapping,mapIdx+1,LstIn);
      then
        lstTmp;
    case(_,_,_,_)
      equation
        false = arrayLength(SccMapping) >= mapIdx;
      then
        LstIn;
  end matchcontinue;
end getMappingForComp;


//protected function fillCalcTimeArray "function fillCalcTimeArray
//  author: marcusw
//  Fills the calculation-time-array."
//  input Graph igraph;
//  input array<Integer> calcTimes;
//  
//algorithm
//  _ := match(igraph,calcTimes)
//    local
//      list<StrongConnectedComponent> components;
//    case(GRAPH(components=components),_)
//      equation 
//        fillCalcTimeArrayTail(components,calcTimes);
//      then ();
//    else
//      then fail();
//  end match;
//  
//end fillCalcTimeArray;
//
//
//protected function fillCalcTimeArrayTail 
//  input list<StrongConnectedComponent> iComps;
//  input array<Integer> calcTimes; //The calculation time of each component
//  
//algorithm
//  _ := match(iComps,calcTimes)
//    local
//      Integer calcTime, compIdx;
//      list<StrongConnectedComponent> rest;
//      String description;
//    case(STRONGCONNECTEDCOMPONENT(calcTime=calcTime,compIdx=compIdx,description=description)::rest,_)
//      equation
//        //print("fillCalcTimeArrayTail -- Idx:" +& compIdx +& " calcTime:" +& calcTime +& " desc:" +& description +& "\n");
//        _ = arrayUpdate(calcTimes, compIdx, calcTime);
//        fillCalcTimeArrayTail(rest,calcTimes);
//      then ();
//    else
//      then ();
//  end match;  
//end fillCalcTimeArrayTail;


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
       eqDescLst = stringListStringChar(eqString);
       eqDescLst = List.map(eqDescLst,prepareXML);
       eqString =stringCharListString(eqDescLst);
       //get the variable string
       varLst = BackendVariable.varList(orderedVars);   
       var = listGet(varLst,v);
       varString = getVarString(var);
       desc = (eqString +& " FOR " +& varString);
       descLst = desc::iEqDesc;
     then 
       descLst;
  case(BackendDAE.EQUATIONSYSTEM(eqns = es, vars = vs, jac = jac, jacType = jacT), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars),_)
     equation
       eqnLst = BackendEquation.equationList(orderedEqs);
       desc = ("Equation System");
       descLst = desc::iEqDesc;
     then 
       descLst;
  case(BackendDAE.MIXEDEQUATIONSYSTEM(disc_eqns = es, disc_vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars),_)
     equation
       eqnLst = BackendEquation.equationList(orderedEqs);
       desc = ("MixedEquation System");
       descLst = desc::iEqDesc;
     then 
       descLst;
   case(BackendDAE.SINGLEARRAY(eqn = i, vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2 = ass2)),_)
     equation
      //get the equation string
      eqnLst = BackendEquation.equationList(orderedEqs);
      eqn = listGet(eqnLst,i);
      eqString = BackendDump.equationString(eqn);
      eqDescLst = stringListStringChar(eqString);
      eqDescLst = List.map(eqDescLst,prepareXML);
      eqString =stringCharListString(eqDescLst);
      //get the variable string
      varLst = BackendVariable.varList(orderedVars);   
      //var = listGet(varLst,arrayGet(ass2,i));
      //varString = getVarString(var);
      //desc = ("ARRAY:"+&eqString +& " FOR " +& varString);
      desc = ("ARRAY:"+&eqString +& " FOR THE VARS: " +& stringDelimitList(List.map1(vs,List.getIndexFirst,List.map(varLst,getVarString))," AND "));
      descLst = desc::iEqDesc;
    then 
      descLst;
   case(BackendDAE.SINGLEALGORITHM(eqn = i, vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2 = ass2)),_)
     equation
      //get the equation string
      eqnLst = BackendEquation.equationList(orderedEqs);
      eqn = listGet(eqnLst,i);
      eqString = BackendDump.equationString(eqn);
      eqDescLst = stringListStringChar(eqString);
      eqDescLst = List.map(eqDescLst,prepareXML);
      eqString = stringCharListString(eqDescLst);
      descLst = eqString::iEqDesc;
      //get the variable string
      varLst = BackendVariable.varList(orderedVars);   
      //var = listGet(varLst,arrayGet(ass2,i));
      //varString = getVarString(var);
      //desc = ("ALGO:"+&eqString +& " FOR " +& varString);
      desc = ("ALGO: "+&eqString +& " FOR THE VARS: " +& stringDelimitList(List.map1(vs,List.getIndexFirst,List.map(varLst,getVarString))," AND "));
      descLst = desc::iEqDesc;
    then 
      descLst;
   case(BackendDAE.SINGLECOMPLEXEQUATION(eqn = i, vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2 = ass2)),_)
     equation
      //get the equation string
      eqnLst = BackendEquation.equationList(orderedEqs);
      eqn = listGet(eqnLst,i);
      eqString = BackendDump.equationString(eqn);
      eqDescLst = stringListStringChar(eqString);
      eqDescLst = List.map(eqDescLst,prepareXML);
      eqString = stringCharListString(eqDescLst);
      descLst = eqString::iEqDesc;
      //get the variable string
      varLst = BackendVariable.varList(orderedVars);   
      //var = listGet(varLst,arrayGet(ass2,i));
      //varString = getVarString(var);
      //desc = ("COMPLEX:"+&eqString +& " FOR " +& varString);
      desc = ("COMPLEX: "+&eqString +& " FOR THE VARS: " +& stringDelimitList(List.map1(vs,List.getIndexFirst,List.map(varLst,getVarString))," AND "));
      descLst = desc::iEqDesc;
    then 
      descLst;
   case(BackendDAE.SINGLEWHENEQUATION(eqn = i, vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2 = ass2)),_)
     equation
      //get the equation string
      eqnLst = BackendEquation.equationList(orderedEqs);
      eqn = listGet(eqnLst,i);
      eqString = BackendDump.equationString(eqn);
      eqDescLst = stringListStringChar(eqString);
      eqDescLst = List.map(eqDescLst,prepareXML);
      eqString =stringCharListString(eqDescLst);
      //get the variable string
      varLst = BackendVariable.varList(orderedVars);   
      //var = listGet(varLst,arrayGet(ass2,i));
      //varString = getVarString(var);
      //desc = ("WHEN:"+&eqString +& " FOR " +& varString);
      desc = ("WHEN:"+&eqString +& " FOR THE VARS: " +& stringDelimitList(List.map1(vs,List.getIndexFirst,List.map(varLst,getVarString))," AND "));
      descLst = desc::iEqDesc;
    then 
      descLst;
   case(BackendDAE.SINGLEIFEQUATION(eqn = i, vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2 = ass2)),_)
     equation
      //get the equation string
      eqnLst = BackendEquation.equationList(orderedEqs);
      eqn = listGet(eqnLst,i);
      eqString = BackendDump.equationString(eqn);
      eqDescLst = stringListStringChar(eqString);
      eqDescLst = List.map(eqDescLst,prepareXML);
      eqString = stringCharListString(eqDescLst);
      descLst = eqString::iEqDesc;
      //get the variable string
      varLst = BackendVariable.varList(orderedVars);   
      //var = listGet(varLst,arrayGet(ass2,i));
      //varString = getVarString(var);
      //desc = ("IFEQ:"+&eqString +& " FOR " +& varString);
      desc = ("IFEQ:"+&eqString +& " FOR THE VARS: " +& stringDelimitList(List.map1(vs,List.getIndexFirst,List.map(varLst,getVarString))," AND "));
      descLst = desc::iEqDesc;
    then 
      descLst;
  case(BackendDAE.TORNSYSTEM(residualequations = es, tearingvars = vs, linear=true), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2 = ass2)),_)
     equation
      //get the equation string
       eqnLst = BackendEquation.equationList(orderedEqs);
       desc = ("Torn linear System");
       descLst = desc::iEqDesc;
    then 
      descLst;  
  case(BackendDAE.TORNSYSTEM(residualequations = es, tearingvars = vs, linear=false), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2 = ass2)),_)
     equation
      //get the equation string
       eqnLst = BackendEquation.equationList(orderedEqs);
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


protected function getVarString "get the var string for a given variable. shortens the String. if necessary insert der operator 
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
   
//TODO: Replace with CDATA
protected function prepareXML " map-function for deletion of forbidden chars from given string
author:Waurich TUD 2013-06"
  input String iString;
  output String oString;
algorithm
  oString := matchcontinue(iString)
    local
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
end prepareXML;

protected function shortenVarString " terminates var string at :
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
  input array<Integer> eqSccMapping;
  output list<Integer> eventNodes;
protected
  list<Integer> eqLst;
  BackendDAE.EqSystems systemsIn;
algorithm
  BackendDAE.DAE(eqs=systemsIn) := systIn;
  ((eqLst,_)) := List.fold(systemsIn, getEventNodeEqs,({},0));
  eventNodes := matchWithAssignments(eqLst,eqSccMapping); 
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

  
//TODO: remove the matchcontinue if sure that the complex equations make no problems any more or if ass2 is fixed.
protected function getMatchedVars "matches the equation to the solved var by using ass1
author:Waurich TUD 2013-06"
  input Integer eq;
  input array<Integer> ass1;
  output Integer varOut;
algorithm
  varOut := matchcontinue(eq,ass1)
    local
      Integer var;
    case(_,_)
      equation
      true = intEq(listLength(List.select1(arrayList(ass1),intEq,eq)),1);
      var = List.position(eq,arrayList(ass1))+1;
      then
        var;
    else
      equation
      print("getMatchedVars failed because the equation solves multiple vars (probably complex equation)\n");
      then
        fail();
  end matchcontinue;
end getMatchedVars;
  
  
protected function matchWithAssignments " matches entries of list1 with the assigned values of assign to obtain the values 
author:Waurich TUD 2013-06" 
  input list<Integer> list1;
  input array<Integer> assign;
  output list<Integer> list2Out;
algorithm
  list2Out := matchWithAssignments1(list1,assign,{});
  list2Out := listReverse(list2Out);
end matchWithAssignments;


protected function matchWithAssignments1" implementation of matchWithAssigments.
author:Waurich TUD 2013-06"
  input list<Integer> list1;
  input array<Integer> assign;
  input list<Integer> list2In;
  output list<Integer> list2Out;
algorithm
  list2Out := matchcontinue(list1, assign, list2In)
    local
      Integer head;
      Integer entry2;
      list<Integer> rest;
      list<Integer> entries2;
    case(head::rest,_,_)
      equation
        entry2 = arrayGet(assign,head);
        entries2 = matchWithAssignments1(rest,assign,entry2::list2In);
      then
        entries2;
    case({},_,_)
      equation
        then
          list2In;
  end matchcontinue;
end matchWithAssignments1;         


protected function isWhenEquation " checks if the comp is of type SINGLEWHENEQUATION.
author:Waurich TUD 2013-06"
  input BackendDAE.StrongComponent inComp;
  output Boolean isWhenEq;
algorithm
  isWhenEq := matchcontinue(inComp)
  local Integer eqn;
    case(BackendDAE.SINGLEWHENEQUATION(eqn=eqn))
    then
      true;
  else
    then
      false;
  end matchcontinue;
end isWhenEquation;


protected function fillSccList "function fillSccList
  author: marcusw
  This function appends the scc, which solves the given variable, to the requiredsccs-list."
  input tuple<Integer,Integer> variable;
  input array<Integer> varSccMapping;
  input array<Integer> iRequiredSccs;
  output array<Integer> oRequiredSccs;

algorithm
  oRequiredSccs := matchcontinue(variable,varSccMapping,iRequiredSccs)
    local
      Integer varIdx,varState, sccIdx, oldCount;
      array<Integer> tmpRequiredSccs;
    case ((varIdx,varState),_,_)
      equation
        true = intEq(varState,1);
        tmpRequiredSccs = iRequiredSccs;
        sccIdx = varSccMapping[varIdx];
        oldCount = iRequiredSccs[sccIdx];
        tmpRequiredSccs = arrayUpdate(tmpRequiredSccs,sccIdx,oldCount+1);
      then tmpRequiredSccs;
   else then iRequiredSccs;
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
protected function getUnsolvedVarsBySCC "function getUnsolvedVarsBySCC
  author: marcusw,waurich
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


protected function isTupleMember "function isTupleMember
  author: marcusw
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
protected function compareTupleByVarIdx "function compareTupleByVarIdx
  author: marcusw
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


protected function getVarsBySCC "function getVarsBySCC
  author: marcusw,waurich
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
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
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
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then 
        eqnVars;
    case (BackendDAE.SINGLEALGORITHM(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then 
        eqnVars;
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then 
        eqnVars;
    case (BackendDAE.SINGLEWHENEQUATION(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then 
        eqnVars;
    case (BackendDAE.SINGLEIFEQUATION(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
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

  
protected function tupleToString "function tupleToString
  author: marcusw
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

protected function tuple3ToString "function tupleToString
  author: marcusw
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

protected function checkIfEquationContainsVar "function checkIfEquationContainsVar
  author: marcusw
  Returns true if given variable is part of the given equation." 
  input tuple<Integer,Integer> var;
  input Integer eqnIdx;
  input BackendDAE.IncidenceMatrix incidenceMatrix;
  output Boolean contains;
  
algorithm
  contains := match(var, eqnIdx, incidenceMatrix)
    local
      Integer varIdx,varState;
      List<tuple<Integer,Integer>> eqnVars;
    case((varIdx,varState),_,_)
      equation
        eqnVars = getVarsByEqn(eqnIdx, incidenceMatrix);
      then
        List.isMemberOnTrue(var,eqnVars,compareVarTuple);
  end match;
end checkIfEquationContainsVar;


protected function getVarsByEqn "function getVarsByEqn
  author: marcusw
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


protected function getVarTuple "function getVarTuple
  author: marcusw
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

protected function compareVarTuple "function compareVarTuple
  author: marcusw
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
    else then false;
 end matchcontinue;
end compareVarTuple;

protected function getSCCByVar "function getSCCByVar
  author: marcusw
  Gets the scc which solves the given variable."
  input tuple<Integer,Integer> varIdx; //variable index and variable state
  input BackendDAE.StrongComponents components;
  input BackendDAE.IncidenceMatrix incidenceMatrix;
  input Integer sccIdx;
  input array<Integer> varSccMapping;
  output Option<Integer> componentIdx;
  
algorithm
  componentIdx := matchcontinue(varIdx, components, incidenceMatrix, sccIdx, varSccMapping)
    local
      Integer returnIdx, rawVarIdx, rawVarState;
    case((rawVarIdx,rawVarState),_,_,_,_)
      equation
        true = intGt(rawVarIdx,0);
        true = intEq(rawVarState,1);
        true = intGt(varSccMapping[rawVarIdx],0);
        returnIdx = varSccMapping[rawVarIdx];
      then
        SOME(returnIdx);
    else
      then NONE();
  end matchcontinue;
end getSCCByVar;


protected function createSccMapping "function createSccMapping
  author: marcusw
  Create a mapping between variables and strong-components. The returned array (one element for each variable) contains the 
  scc-index which solves the variable."
  input BackendDAE.StrongComponents components;
  input Integer varCount;
  input Integer eqCount;
  output array<Integer> oVarSccMapping;
  output array<Integer> oEqSccMapping;
  
protected
  array<Integer> varSccMapping;
  array<Integer> eqSccMapping;
  
algorithm
  varSccMapping := arrayCreate(varCount,-1);
  eqSccMapping := arrayCreate(eqCount,-1);
  _ := List.fold2(components, createSccMapping0, varSccMapping, eqSccMapping, 1);
  oVarSccMapping := varSccMapping;
  oEqSccMapping := eqSccMapping;
  
end createSccMapping;


protected function createSccMapping0 "function createSccMapping
  author: marcusw,waurich
  Updates all array elements which are solved in the given component. The array-elements will be set to iSccIdx."
  input BackendDAE.StrongComponent component;
  input array<Integer> varSccMapping;
  input array<Integer> eqSccMapping;
  input Integer iSccIdx;
  output Integer oSccIdx;
  
algorithm
  oSccIdx := matchcontinue(component, varSccMapping, eqSccMapping, iSccIdx)
    local
      Integer compVarIdx;
      Integer eq;
      List<Integer> compVarIdc;
      List<Integer> eqns;
      List<Integer> residuals;
      List<Integer> othereqs;
      List<Integer> othervars;
      array<Integer> tmpVarSccMapping;
      array<Integer> tmpEqSccMapping;
      list<tuple<Integer,list<Integer>>> tearEqVarTpl;
      BackendDAE.StrongComponent condSys;
    case(BackendDAE.SINGLEEQUATION(var = compVarIdx, eqn = eq),_,_,_)
      equation
        tmpVarSccMapping = arrayUpdate(varSccMapping,compVarIdx,iSccIdx);
        tmpEqSccMapping = arrayUpdate(eqSccMapping,eq,iSccIdx);
      then iSccIdx+1;
    case(BackendDAE.EQUATIONSYSTEM(vars = compVarIdc, eqns=eqns),_,_,_)
      equation
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
        tmpEqSccMapping = List.fold1(eqns,updateMapping,iSccIdx,eqSccMapping);
      then 
        iSccIdx+1;
    case(BackendDAE.MIXEDEQUATIONSYSTEM(condSystem = condSys, disc_vars = compVarIdc, disc_eqns = eqns),_,_,_)
      equation
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
        tmpEqSccMapping = List.fold1(eqns,updateMapping,iSccIdx,eqSccMapping);
        //gets the whole equationsystem (necessary for the adjacencyList)
        _ = List.fold2({condSys}, createSccMapping0, tmpVarSccMapping,tmpEqSccMapping, iSccIdx);
      then 
        iSccIdx+1;
    case(BackendDAE.SINGLEWHENEQUATION(vars = compVarIdc,eqn = eq),_,_,_)
      equation
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
        tmpEqSccMapping = arrayUpdate(eqSccMapping,eq,iSccIdx);
      then 
        iSccIdx+1;
    case(BackendDAE.SINGLEARRAY(vars = compVarIdc, eqn = eq),_,_,_)
      equation
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
        tmpEqSccMapping = arrayUpdate(eqSccMapping,eq,iSccIdx);
      then 
        iSccIdx+1;        
    case(BackendDAE.SINGLEALGORITHM(vars = compVarIdc,eqn = eq),_,_,_)
      equation
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
        tmpEqSccMapping = arrayUpdate(eqSccMapping,eq,iSccIdx);
        then 
          iSccIdx+1;
    case(BackendDAE.SINGLECOMPLEXEQUATION(vars = compVarIdc, eqn = eq),_,_,_)
      equation
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
        tmpEqSccMapping = arrayUpdate(eqSccMapping,eq,iSccIdx);
        then 
          iSccIdx+1;
    case(BackendDAE.TORNSYSTEM(tearingvars = compVarIdc,residualequations = residuals, otherEqnVarTpl = tearEqVarTpl),_,_,_)
      equation
      ((othereqs,othervars)) = List.fold(tearEqVarTpl,othersInTearComp,(({},{})));
      compVarIdc = listAppend(othervars,compVarIdc);
      eqns = listAppend(othereqs,residuals);
      tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
      tmpEqSccMapping = List.fold1(eqns,updateMapping,iSccIdx,eqSccMapping);
      then 
        iSccIdx+1;   
    case(BackendDAE.SINGLEIFEQUATION(vars = compVarIdc, eqn = eq),_,_,_)
      equation
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
        tmpEqSccMapping = arrayUpdate(eqSccMapping,eq,iSccIdx);
        then 
          iSccIdx+1;
    else
      equation
        print("createSccMapping0 - Unsupported component-type.");
      then fail();
  end matchcontinue;
end createSccMapping0;


protected function othersInTearComp " gets the remaining algebraic vars and equations from the torn block.
this function is just for checking if there exists an equation with more than one var(because i dont know why theres a list of vars)
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
      true = intEq(listLength(varTplLst),1);
      var = listGet(varTplLst,1);
      (eqLst,varLst) = othersIn;
      varLst = var::varLst;
      eqLst = eq::eqLst;
      then
        ((eqLst,varLst));
    else
      equation
      print("check number of vars in relation to number of eqs in otherEqnVarTpl int the torn system\n");
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



//functions to get the ODEsystem graph and adjacencyList
//------------------------------------------
//------------------------------------------

public function getOdeSystem " gets the graph and the adjacencyLst only for the ODEsystem. the der(states) and nodes that evaluate zerocrossings are the only branches of the task graph
author: Waurich TUD 2013-06"
  input TaskGraph graphIn;
  input TaskGraphMeta graphDataIn;
  input BackendDAE.BackendDAE systIn;
  input String filenamePrefix;
  output TaskGraph graphOdeOut;
  output TaskGraphMeta graphDataOdeOut;
protected
  list<BackendDAE.Var> varLst;
  list<Integer> statevarindx_lst;
  list<Integer> stateVars;
  list<Integer> stateNodes;
  list<Integer> whenNodes;
  list<Integer> whenChildren;
  list<Integer> cutNodes;
  array<Integer> varSccMapping;
  array<Integer> eqSccMapping;
  array<list<Integer>> inComps;
  String fileName;
  BackendDAE.Variables orderedVars;
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
  TaskGraph graphTmp;
  TaskGraphMeta graphDataTmp;
algorithm
  TASKGRAPHMETA(varSccMapping=varSccMapping, eqSccMapping=eqSccMapping, inComps=inComps) := graphDataIn;
  BackendDAE.DAE(systs,shared) := systIn;
  ((stateNodes,_)) := List.fold2(systs,getAllStateNodes,varSccMapping,inComps,({},0));  
  whenNodes := getEventNodes(systIn,eqSccMapping); 
  (graphTmp,cutNodes) := cutTaskGraph(graphIn,stateNodes,whenNodes,{});
  graphDataOdeOut := getOdeSystemData(graphDataIn,listAppend(cutNodes,whenNodes));
  graphOdeOut := graphTmp;
end getOdeSystem;
  
  
protected function getAllStateNodes "folding function for getOdeSystem to traverse the equationsystems in the BackendDAE.
author: Waurich TUD 2013-07"
  input BackendDAE.EqSystem systIn;
  input array<Integer> varSccMapping;
  input array<list<Integer>> inComps;
  input tuple<list<Integer>,Integer> stateInfoIn;
  output tuple<list<Integer>,Integer> stateInfoOut;
algorithm
  stateInfoOut := matchcontinue(systIn,varSccMapping,inComps,stateInfoIn)
    local
      list<Integer> stateNodes;
      list<Integer> stateNodesIn;
      list<Integer> stateVars;
      Integer varOffset;
      Integer varOffsetNew;
      BackendDAE.Variables orderedVars;
      list<BackendDAE.Var> varLst;
  case(_,_,_,((stateNodesIn,varOffset)))
    equation
      BackendDAE.EQSYSTEM(orderedVars=orderedVars) = systIn;
      varLst = BackendVariable.varList(orderedVars);
      stateVars = getStates(varLst,{},1);    
      true = listLength(stateVars) >= 1;
      stateVars = List.map1(stateVars,intAdd,varOffset);
      stateNodes = matchWithAssignments(stateVars,varSccMapping);
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
      true = listLength(stateVars) == 0;
      varOffsetNew = listLength(varLst)+varOffset;      
      then
        ((stateNodesIn,varOffsetNew));
    else
    equation
      print("getAllStateNodes failed!\n");
      then
        fail();
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
        noChildren = getBranchEnds(graphIn,{},1);
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
        noChildren = getBranchEnds(graphIn,{},1);
        (_,cutNodes,_) = List.intersection1OnTrue(noChildren,listAppend(stateNodes,deleteNodes),intEq);
        true = List.isEmpty(cutNodes);
        //print("pre cut\n");
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
  output TaskGraphMeta graphDataOut;
protected
  array<list<Integer>> inComps;
  array<Integer> varSccMapping;
  array<Integer> eqSccMapping;
  list<Integer> rootNodes;
  array<String> nodeNames;
  array<String> nodeDescs;
  array<tuple<Integer,Real>> exeCosts;
  array<list<tuple<Integer,Integer,Integer>>> commCosts;
  array<Integer>nodeMark;
  list<Integer> rangeLst;
algorithm
  TASKGRAPHMETA(inComps = inComps, varSccMapping=varSccMapping, eqSccMapping=eqSccMapping, rootNodes = rootNodes, nodeNames =nodeNames, nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) := graphDataIn;
  inComps := listArray(List.deletePositions(arrayList(inComps),List.map1(cutNodes,intSub,1)));
  varSccMapping := removeContinuousEntries(varSccMapping,cutNodes);
  eqSccMapping := removeContinuousEntries(eqSccMapping,cutNodes);
  (_,rootNodes,_) := List.intersection1OnTrue(rootNodes,cutNodes,intEq); //TODO:  this has to be updated(When cutting out When-nodes new roots arise)
  rangeLst := List.intRange(arrayLength(nodeMark));
  nodeMark := List.fold1(rangeLst, markRemovedNodes,cutNodes,nodeMark);
  graphDataOut :=TASKGRAPHMETA(inComps,varSccMapping,eqSccMapping,rootNodes,nodeNames,nodeDescs,exeCosts,commCosts,nodeMark);
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
    

protected function getCompInComps "finds the node in the current task graph which contains that component(index from the original task graph). nodeMark is needed to check for deleted components
author: Waurich TUD 2013-07"
  input Integer compIn;
  input Integer compIdx;
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
        print("getCompInComps failed!\n");
      then
        fail();
  end matchcontinue;             
end getCompInComps;


protected function getChildNodes "gets the successor nodes for a list of parent nodes.
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
  list<Integer> arrayLst;
  array<Integer> arrayTmp;
algorithm
  arrayTmp := Util.arrayMap1(arrayIn,invalidateEntry,deleteEntriesIn);
  arrayLst := arrayList(arrayIn);
  deleteEntries := List.sort(deleteEntriesIn,intLt);
  arrayOut := Util.arrayMap1(arrayTmp,removeContinuousEntries1,deleteEntriesIn); 
end removeContinuousEntries;


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
        true = List.isMemberOnTrue(entryIn,lstIn,intEq);
      then
        -1;
  end matchcontinue;
end invalidateEntry;
  
  
protected function removeContinuousEntries1" map function for removeContinuousEntries to update the indices.
author:Waurich TUD 2013-07."
  input Integer entryIn;
  input list<Integer> deleteEntriesIn;
  output Integer entryOut;
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
    then
      entry;
  else
    equation
    then
      entryIn;
  end matchcontinue;
end removeContinuousEntries1; 

 
//protected function getConditionVars "gets the vars that are necessary to compute the when-conditions
//author: Waurich TUD 2013-06"
//  input list<Integer> eventEqs;
//  input list<Integer> eventVars;
//  input BackendDAE.IncidenceMatrix mIn;
//  input list<Integer> condVarsIn;
//  input Integer Idx;
//  output list<Integer> condVarsOut;
//algorithm
//  condVarsOut := matchcontinue(eventEqs,eventVars,mIn,condVarsIn,Idx)
//    local
//      Integer var;
//      list<Integer> condVars;
//      list<Integer> row;
//    case(_,_,_,_,_)
//      equation
//        true = listLength(eventEqs) >= Idx;
//        row = arrayGet(mIn,listGet(eventEqs,Idx));
//        row = deleteMembersList(row,eventVars);
//        condVars = listAppend(row,condVarsIn);
//        condVars = getConditionVars(eventEqs,eventVars,mIn,condVars,Idx+1);
//      then
//        condVars;
//    else
//      equation
//        condVars = List.unique(condVarsIn);
//      then
//        condVars;     
//    end matchcontinue;
//end getConditionVars;        

protected function deleteMembersList "deletes all members in list1 given by list2
author:waurich TUD 2013-06"
  input list<Integer> list1In;
  input list<Integer> list2;
  output list<Integer> list1Out;
algorithm
  list1Out := matchcontinue(list1In,list2)
    local
      Integer entry;
      Integer head;
      list<Integer> newLst;
      list<Integer> rest;
    case(_,(head::rest))
      equation
        newLst = List.deleteMember(list1In,head);
        newLst = deleteMembersList(newLst,rest);
      then
        newLst;
    case(_,{})
      then
        list1In;
  end matchcontinue;
end deleteMembersList;     
      

protected function removeEntriesInGraph "deletes given entries from adjacencyLst.
  author: Waurich TUD 2013-06"
  input array<list<Integer>> inArray;
  input list<Integer> noStates;
  output array<list<Integer>> outArray;
algorithm
  outArray := matchcontinue(inArray,noStates)
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
  end matchcontinue;
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


protected function subOne
  input Integer minuend1;
  output Integer diffOut;
algorithm
  diffOut := intSub(minuend1,1);
end subOne;


protected function getBranchEnds "gets the end of the branches i.e. a node with no successors(no entries in the adjacencyList)
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
        noChildren = getBranchEnds(adjacencyLstIn,rowIdx::noChildrenIn,rowIdx+1);
        then
          noChildren;
    case(_,_,_)
      equation
        // check for tornsystems (self-loops)
        
        true = arrayLength(adjacencyLstIn) >= rowIdx;
        row = arrayGet(adjacencyLstIn,rowIdx);
        true = listLength(row) == 1;  
        true = listGet(row,1) == rowIdx;
        noChildren = getBranchEnds(adjacencyLstIn,rowIdx::noChildrenIn,rowIdx+1);
        then
          noChildren;    
    case(_,_,_)
      equation
        true = arrayLength(adjacencyLstIn) >= rowIdx;
        row = arrayGet(adjacencyLstIn,rowIdx);
        false = List.isEmpty(row);
        noChildren = getBranchEnds(adjacencyLstIn,noChildrenIn,rowIdx+1);
        then
          noChildren;          
    case(_,_,_)
      equation
        true = arrayLength(adjacencyLstIn) < rowIdx;
      then
        noChildrenIn;
  end matchcontinue;
end getBranchEnds;                 
 

//protected function getSCCByVar0
//  input tuple<Integer,Integer> varIdx; //variable index and variable state
//  input BackendDAE.StrongComponents components;
//  input BackendDAE.IncidenceMatrix incidenceMatrix;
//  input Integer sccIdx;
//  input array<Integer> varSccMapping;
//  output Option<Integer> componentIdx;
//
//algorithm
//  componentIdx := matchcontinue(varIdx, components, incidenceMatrix, sccIdx, varSccMapping)
//    local
//      BackendDAE.StrongComponent head;
//      BackendDAE.StrongComponents tail;
//      Integer varRawIdx,varRawState;
//      Boolean constTrue, contains;
//      Integer compVarIdx, const1, listLen;
//      list<tuple<Integer, list<Integer>>> tornCompEqns;
//      list<Integer> compVarIdc;
//    case((varRawIdx,varRawState),(head as BackendDAE.SINGLEEQUATION(var = compVarIdx))::tail,_,_,_)
//      equation
//        true = compareVarTuple(varIdx, getVarTuple(compVarIdx));
//        varSccMapping = arrayUpdate(varSccMapping,varRawIdx,sccIdx);
//    then SOME(sccIdx);
//    case(_,(head as BackendDAE.EQUATIONSYSTEM(vars = compVarIdc))::tail,_,_,_)
//      equation
//        print("getSCCByVar - Equationsystem not supported\n");
//        //compVarIdc = List.removeOnTrue(varIdx, intNe, compVarIdc);
//        //const1 = 1;
//        //listLen = listLength(compVarIdc);
//        //equality(const1 = listLen);
//      then getSCCByVar(varIdx,tail,incidenceMatrix,sccIdx+1,varSccMapping);
//    case(_,(head as BackendDAE.MIXEDEQUATIONSYSTEM(disc_vars = compVarIdc))::tail,_,_,_)
//      equation
//        print("getSCCByVar - Mixedequationsystem not supported\n");
//      then getSCCByVar(varIdx,tail,incidenceMatrix,sccIdx+1,varSccMapping);
//    case (_,(head as BackendDAE.SINGLEARRAY(vars=compVarIdc))::tail,_,_,_)
//      equation
//        print("getSCCByVar - SingleArray not supported\n");
//      then getSCCByVar(varIdx,tail,incidenceMatrix,sccIdx+1,varSccMapping); 
//    case (_,(head as BackendDAE.SINGLEALGORITHM(vars=compVarIdc))::tail,_,_,_)
//      equation
//        print("getSCCByVar - SingleAlgorithm not supported\n");
//      then getSCCByVar(varIdx,tail,incidenceMatrix,sccIdx+1,varSccMapping);       
//    case (_,(head as BackendDAE.TORNSYSTEM(tearingvars=compVarIdc, otherEqnVarTpl=tornCompEqns))::tail,_,_,_)
//      equation
//        //constTrue = true;
//        //contains = checkIfTornCompContainsEqn(compVarIdc, tornCompEqns, varIdx);
//        //equality(constTrue = contains);
//        print("getSCCByVar - TornSystem not supported\n");
//      then getSCCByVar(varIdx,tail,incidenceMatrix,sccIdx+1);
//    case(_,_::tail,_,_,_)
//      then getSCCByVar(varIdx,tail,incidenceMatrix,sccIdx+1);
//    else NONE();
//  end matchcontinue;
//end getSCCByVar0;

//protected function checkIfTornCompContainsEqn
//  input list<Integer> tearingEqns;
//  input list<tuple<Integer, list<Integer>>> otherEqnVarTpl;
//  input Integer eqnIdx;
//  output Boolean contains;
//
//algorithm
//  contains := checkIfTornCompContainsEqn1(listLength(List.removeOnTrue(eqnIdx, intNe, tearingEqns)), checkIfTornCompContainsEqn0(otherEqnVarTpl,eqnIdx));
//end checkIfTornCompContainsEqn;
//
//protected function checkIfTornCompContainsEqn0
//  input list<tuple<Integer, list<Integer>>> otherEqnVarTpl;
//  input Integer eqnIdx;
//  output Boolean contains;
//
//protected
//  Integer eqn;
//  list<tuple<Integer, list<Integer>>> tail;
//  
//algorithm
//  contains := matchcontinue(otherEqnVarTpl, eqnIdx)
//    case((eqn,_)::tail,_) 
//      equation
//        equality(eqn = eqnIdx);
//      then true;
//    case(_::tail,_) then checkIfTornCompContainsEqn0(tail,eqnIdx);
//    else then false;
//  end matchcontinue;
//end checkIfTornCompContainsEqn0;
//
//protected function checkIfTornCompContainsEqn1
//  input Integer listLen;
//  input Boolean partOfOtherEqn;
//  output Boolean contains;
//
//algorithm
//  contains := match(listLen, partOfOtherEqn)
//    case(1,_)
//      then true;
//    case(_,_)
//      then partOfOtherEqn;
//  end match;  
//end checkIfTornCompContainsEqn1; 


//Methods to write blt-structure as xml-file
//------------------------------------------
//------------------------------------------


public function dumpAsGraphMLSccLevel "function dumpAsGraphMLSccLevel
  author: marcusw, waurich
  Write out the given graph as a graphml file."
  input TaskGraph iGraph;
  input TaskGraphMeta iGraphData;
  input String fileName;
protected
  GraphML.Graph graph;
  Integer calcTimeAttIdx, opCountAttIdx, yCoordAttIdx, compIdcAttIdx;
  list<Integer> compIdc;
algorithm
  _ := match(iGraph, iGraphData, fileName)
    case(_,_,_)
      equation 
        graph = GraphML.getGraph("TaskGraph", true);
        (opCountAttIdx,graph) = GraphML.addAttribute("-1", "Operations", GraphML.TYPE_INTEGER(), GraphML.TARGET_NODE(), graph);
        (calcTimeAttIdx,graph) = GraphML.addAttribute("-1", "CalcTime", GraphML.TYPE_DOUBLE(), GraphML.TARGET_NODE(), graph);
        (compIdcAttIdx,graph) = GraphML.addAttribute("", "Components", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graph);
        (yCoordAttIdx,graph) = GraphML.addAttribute("17", "yCoord", GraphML.TYPE_INTEGER(), GraphML.TARGET_NODE(), graph);
        compIdc = List.intRange(arrayLength(iGraph));
        graph = List.fold3(compIdc, addNodeToGraphML, iGraph, iGraphData, (opCountAttIdx,calcTimeAttIdx, compIdcAttIdx,yCoordAttIdx), graph);
        GraphML.dumpGraph(graph, fileName);
      then ();
  end match;
end dumpAsGraphMLSccLevel;


protected function addNodeToGraphML "function addNodeToGraphML
  author: marcusw, waurich
  Adds the given node to the given graph."
  input Integer nodeIdx;
  input TaskGraph tGraphIn;
  input TaskGraphMeta tGraphDataIn;
  input tuple<Integer,Integer,Integer,Integer> attIdc; //Attribute index for <opCountAttIdx, calcTimeAttIdx, compIdcAttIdx, yCoordAttIdx>
  input GraphML.Graph iGraph;
  output GraphML.Graph oGraph;
algorithm
  oGraph := matchcontinue(nodeIdx,tGraphIn,tGraphDataIn,attIdc,iGraph)
    local
      GraphML.Graph tmpGraph;
      Integer opCount, calcTimeAttIdx, opCountAttIdx, compIdcAttIdx, yCoordAttIdx, yCoord;
      Real calcTime;
      Integer primalComp;
      list<Integer> childNodes;
      list<Integer> components;
      list<Integer> rootNodes;  
      array<Integer> varSccMapping;  
      array<Integer> eqSccMapping;  
      array<tuple<Integer,Real>> exeCosts;  
      array<Integer> nodeMark; 
      array<list<Integer>> inComps; 
      array<String> nodeNames; 
      array<String> nodeDescs;  
      array<list<tuple<Integer,Integer,Integer>>> commCosts;  
      String calcTimeString, opCountString, yCoordString;
      String compText;
      String description;
      String nodeDesc;
      String componentsString;
    case(_,_,_,_,_)
      equation
        false = nodeIdx == 0 or nodeIdx == -1;
        (opCountAttIdx, calcTimeAttIdx, compIdcAttIdx, yCoordAttIdx) = attIdc;
        TASKGRAPHMETA(inComps = inComps, eqSccMapping=eqSccMapping, rootNodes = rootNodes, nodeNames =nodeNames ,nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) = tGraphDataIn;
        components = arrayGet(inComps,nodeIdx);
        true = listLength(components)==1; 
        primalComp = listGet(components,1);
        compText = arrayGet(nodeNames,primalComp);        
        nodeDesc = arrayGet(nodeDescs,primalComp);
        ((_,calcTime)) = arrayGet(exeCosts,primalComp);
        ((opCount,calcTime)) = arrayGet(exeCosts,primalComp);
        calcTimeString = realString(calcTime);
        yCoord = arrayGet(nodeMark,primalComp);
        calcTimeString = realString(calcTime);
        opCountString = intString(opCount);
        yCoordString = intString(yCoord);
        childNodes = arrayGet(tGraphIn,nodeIdx);
        componentsString = List.fold(components, addNodeToGraphML2, " ");
        tmpGraph = GraphML.addNode("Node" +& intString(nodeIdx), compText, GraphML.COLOR_GREEN, GraphML.RECTANGLE(), SOME(nodeDesc), {((calcTimeAttIdx,calcTimeString)),((opCountAttIdx, opCountString)),((compIdcAttIdx,componentsString)),((yCoordAttIdx,yCoordString))}, iGraph);
        tmpGraph = List.fold2(childNodes, addDepToGraph, nodeIdx, tGraphDataIn, tmpGraph);
      then 
        tmpGraph;
    case(_,_,_,_,_)
      equation
        // for a node that consists of contracted nodes
        false = nodeIdx == 0 or nodeIdx == -1;
        (opCountAttIdx, calcTimeAttIdx, compIdcAttIdx, yCoordAttIdx) = attIdc;
        TASKGRAPHMETA(inComps = inComps, eqSccMapping=eqSccMapping, rootNodes = rootNodes, nodeNames =nodeNames ,nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) = tGraphDataIn;
        components = arrayGet(inComps,nodeIdx);
        false = listLength(components)==1;
        primalComp = List.last(components);
        compText = arrayGet(nodeNames,primalComp);        
        nodeDesc = arrayGet(nodeDescs,primalComp);
        ((opCount,calcTime)) = List.fold1(components, addNodeToGraphML1, exeCosts, (0,0.0));
        calcTimeString = realString(calcTime);
        opCountString = intString(opCount);
        childNodes = arrayGet(tGraphIn,nodeIdx);
        componentsString = List.fold(components, addNodeToGraphML2, " ");
        tmpGraph = GraphML.addNode("Node" +& intString(nodeIdx), compText, GraphML.COLOR_GREEN, GraphML.RECTANGLE(), SOME(nodeDesc), {((calcTimeAttIdx,calcTimeString)),((opCountAttIdx, opCountString)),((compIdcAttIdx,componentsString))}, iGraph);
        tmpGraph = List.fold2(childNodes, addDepToGraph, nodeIdx, tGraphDataIn, tmpGraph);
      then 
        tmpGraph;
    case(_,_,_,_,_)
      equation
        true = nodeIdx == 0 or nodeIdx == -1;
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

protected function addNodeToGraphML2
  input Integer compIdx;
  input String iString;
  output String oString;
  
algorithm
  oString := iString +& intString(compIdx) +& " ";
  
end addNodeToGraphML2;


protected function addDepToGraph "function addSccDepToGraph
  author: marcusw
  Adds a new edge between the component-nodes with index comp1Idx and comp2Idx to the graph."
  input Integer childIdx;
  input Integer parentIdx;
  input TaskGraphMeta tGraphDataIn;
  input GraphML.Graph iGraph;
  output GraphML.Graph oGraph;
protected
  array<list<tuple<Integer,Integer,Integer>>> commCosts;  
  Integer commCost;
  String refSccCountStr;
  array<Integer> nodeMark;
algorithm
  TASKGRAPHMETA(commCosts=commCosts, nodeMark=nodeMark) := tGraphDataIn;
  oGraph := GraphML.addEgde("Edge" +& intString(childIdx) +& intString(parentIdx), "Node" +& intString(parentIdx), "Node" +& intString(childIdx), GraphML.COLOR_BLACK, GraphML.LINE(), SOME(GraphML.EDGELABEL("NS",GraphML.COLOR_BLACK)), (SOME(GraphML.ARROWSTANDART()),NONE()), iGraph);
end addDepToGraph;

protected function getCommunicationCost " gets the communication cost for an edge from parent node to child node.
  author: waurich TUD 2013-06."
  input Integer parentIdx;
  input Integer childIdx;
  input array<list<tuple<Integer,Integer,Integer>>> commCosts; 
  output Integer costOut;
protected
  list<tuple<Integer,Integer,Integer>> commRow;
  tuple<Integer,Integer,Integer> commEntry;
algorithm
  commRow := arrayGet(commCosts,childIdx);
  commEntry := getTupleByFirstEntry(commRow,parentIdx);
  (_,costOut,_) := commEntry;  
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
    case(head::rest,_)
      equation
        (tplValue,_,_) = head;
        true = intEq(tplValue,valueIn);
      then
        head;
    case({},_)
      equation
        print("getCommunicationCosts failed! - the value "+&intString(valueIn)+&" can not be found in the list of edges\n");
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
"function: dumpIncidenceRow
  author: PA
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
  array<Integer>  varSccMapping;
  array<Integer> eqSccMapping;
  list<Integer> rootNodes;
  array<String> nodeNames; 
  array<String> nodeDescs; 
  array<tuple<Integer,Real>> exeCosts; 
  array<list<tuple<Integer,Integer,Integer>>> commCosts;
  array<Integer> nodeMark;
algorithm
  TASKGRAPHMETA(inComps = inComps, varSccMapping = varSccMapping, eqSccMapping=eqSccMapping, rootNodes=rootNodes, nodeNames=nodeNames, nodeDescs=nodeDescs, exeCosts=exeCosts, commCosts=commCosts, nodeMark=nodeMark) := metaDataIn;
  print("\n");
  print("--------------------------------\n");
  print("TASKGRAPH METADATA\n");
  print("--------------------------------\n");
  print(intString(arrayLength(inComps))+&" nodes include components:\n");
  printInComps(inComps,1);
  print(intString(arrayLength(varSccMapping))+&" vars are solved in the nodes \n");
  printVarSccMapping(varSccMapping,1);
  print(intString(arrayLength(eqSccMapping))+&" equations are computed in the nodes \n");
  printEqSccMapping(eqSccMapping,1);
  print("the names of the nodes \n");
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


protected function printInComps " prints the information about the assigned components to a taskgraph node.
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
      print("component "+&intString(compIdx)+&" includes: "+&stringDelimitList(List.map(compRow,intString),", ")+&"\n");
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


protected function printVarSccMapping " prints the information about how the vars are assigned to the graph nodes
author: Waurich TUD 2013-07"
  input array<Integer> varSccMapping;
  input Integer varIdx;
algorithm
  _ := matchcontinue(varSccMapping,varIdx)
  local
    Integer comp;
  case(_,_)
    equation
      true = arrayLength(varSccMapping)>= varIdx;
      comp = arrayGet(varSccMapping,varIdx);
      print("variable "+&intString(varIdx)+&" is solved in component: "+&intString(comp)+&"\n");
      printVarSccMapping(varSccMapping,varIdx+1);
      then
        ();
  else
    equation
      print("--------------------------------\n");
      then
        ();
  end matchcontinue;
end printVarSccMapping;  
  
protected function printEqSccMapping " prints the information about which equations are assigned to the graph nodes
author: Waurich TUD 2013-07"
  input array<Integer> eqSccMapping;
  input Integer eqIdx;
algorithm
  _ := matchcontinue(eqSccMapping,eqIdx)
  local
    Integer comp;
  case(_,_)
    equation
      true = arrayLength(eqSccMapping)>= eqIdx;
      comp = arrayGet(eqSccMapping,eqIdx);
      print("equation "+&intString(eqIdx)+&" is computed in component: "+&intString(comp)+&"\n");
      printEqSccMapping(eqSccMapping,eqIdx+1);
      then
        ();
  else
    equation
      print("--------------------------------\n");
      then
        ();
  end matchcontinue;
end printEqSccMapping;  


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


protected function printNodeMark " prints the information about additional NodeMark
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



protected function printIntLst "function to print a list<Integer>
author:Waurich TUD 2013-07"
  input list<Integer> lstIn;
  output String strOut;
algorithm
  strOut := stringDelimitList(List.map(lstIn,intString),",");  
end printIntLst;


//some unused functions (with old type definition)
//------------------------------------------
//------------------------------------------
public function createTaskGraphODE" creates the task Graph only for the ODE equations.
author: waurich TUD 2013-06"
  input list<list<SimCode.SimEqSystem>> odeEquationsIn;
  input BackendDAE.BackendDAE dlowIn;
  input String fileNamePrefix;
algorithm
  _ := matchcontinue(odeEquationsIn, dlowIn, fileNamePrefix)
    local
      BackendDAE.EqSystems eqSysts;
      BackendDAE.EqSystem eqSys;
      BackendDAE.StrongComponents comps;
      BackendDAE.Shared shared;
      BackendDAE.Variables orderedVars;
      Integer numberOfVars;
      Integer sizeODE;
      array<Integer> varSCCMapping;
      list<DAE.ComponentRef> cRefsODE;
      array<Integer> odeScc;
      list<SimCode.SimEqSystem> odeEqLst;
      list<Integer> odeSCCMapping;
      list<Integer> odeVarMatching;
      list<DAE.ComponentRef> varCRefMapping;
      list<BackendDAE.Var> varLst;      
    case(_,BackendDAE.DAE(eqs=eqSysts, shared=shared),_)
      equation
        //true = intEq(listLength(odeEquationsIn), 1);
        odeEqLst = listGet(odeEquationsIn,1);
        print(intString(listLength(odeEqLst))+&"ODEs\n");
        sizeODE =  listLength(odeEqLst);
        cRefsODE = List.map(odeEqLst,getODEcRef);
        print("all the ODEs "+&stringDelimitList(List.map(cRefsODE,ComponentReference.crefStr),",")+&"\n");
        //eqSys = listGet(eqSysts,1);
        //BackendDAE.EQSYSTEM(matching = BackendDAE.MATCHING(comps=comps),orderedVars=orderedVars) = eqSys;
        //BackendDAE.VARIABLES(numberOfVars=numberOfVars) = orderedVars;
        //// map the SCCs to the vars
        //varSCCMapping = createSccMapping(comps, numberOfVars);
        //// map vars to cRefs of vars        
        //varLst = BackendVariable.varList(orderedVars);
        //varCRefMapping = List.map(varLst,BackendVariable.varCref);
        //print("map vars to cRefs of vars "+&stringDelimitList(List.map(varCRefMapping,ComponentReference.crefStr),",")+&"\n");
        //// map SCC to cRefs
        //odeScc = arrayCreate(listLength(cRefsODE),-1);
        //_ = List.fold3(cRefsODE, getSccForCRef, odeScc, varSCCMapping, varCRefMapping, 1);
        ////print("ode-SCC-mapping "+&stringDelimitList(List.map(arrayList(odeScc),intString),",")+&"\n");
      then
        ();
    else
      equation
      print("createTaskGraphODE failed! - check the ODEs \n");  
      then
        ();
  end matchcontinue;
end createTaskGraphODE;

protected function getODEcRef "gets the cRef for a SimEqSystem.
  author: Waurich TUD 2013-06"
  input SimCode.SimEqSystem odeEqIn;
  output DAE.ComponentRef cRefOut;
algorithm
  cRefOut := matchcontinue(odeEqIn)
  local
    Integer eqIdx;
    DAE.ComponentRef compRef;
    list<DAE.ComponentRef> conditions;
    DAE.Exp exp;
    list<DAE.Exp> exps;
    DAE.ElementSource source;
    list<DAE.Statement> statements;
    String compRefStr;
  case(SimCode.SES_RESIDUAL(index=eqIdx, exp=exp, source=source))
    equation  
    //print("equation "+&intString(eqIdx)+&"is a Residual"+&"\n");
    then
      fail();
  case(SimCode.SES_SIMPLE_ASSIGN(index=eqIdx, cref=compRef, exp=exp, source=source))
    equation
    compRefStr = ComponentReference.crefStr(compRef);    
    //print("equation "+&intString(eqIdx)+&"is a SimpleAssignment from component"+&compRefStr+&"\n");
    then
      compRef; 
  case(SimCode.SES_ALGORITHM(index=eqIdx, statements=statements))
    equation
    //print("equation "+&intString(eqIdx)+&"is a ALGORITHM from component"+&"\n");
    then
      fail();
  case(SimCode.SES_WHEN(index=eqIdx, left=compRef, right=exp, source=source))
    equation
    //print("equation "+&intString(eqIdx)+&"is a When from component"+&"\n");
    then
      compRef;
  else
    equation
    //print("createTaskGraphODE0 failed! - Unsupported SimEqSystem-type! ");
    then
      fail();    
  end matchcontinue;      
end getODEcRef;


// testfunctions
//------------------------------------------
//------------------------------------------

public function checkOdeSystemSize " compares the size of the ode-taskgraph with the number of ode-equations in the simCode.
author:Waurich TUD 2013-07"
  input TaskGraph taskGraphOdeIn;
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


// functions to merge simple nodes
//------------------------------------------
//------------------------------------------


public function mergeSimpleNodes " merges all nodes in the graph that have only one predecessor and one successor.
author:Waurich TUD 2013-07"
  input TaskGraph graphIn;
  input TaskGraphMeta graphDataIn;
  input BackendDAE.BackendDAE daeIn;
  input String filenamePrefix;
  output TaskGraph graphOut;
  output TaskGraphMeta graphDataOut;
protected 
  array<list<Integer>> inComps; 
  array<Integer> varSccMapping;  
  array<Integer> eqSccMapping;  
  list<Integer> rootNodes;  
  array<String> nodeNames; 
  array<String> nodeDescs;  
  array<tuple<Integer,Real>> exeCosts;  
  array<list<tuple<Integer,Integer,Integer>>> commCosts;  
  array<Integer> nodeMark;
  BackendDAE.EqSystems systs;
  TaskGraph graphTmp;
  TaskGraphMeta graphDataTmp;
  list<Integer> noMerging;
  list<list<Integer>> oneChildren;
  list<Integer> allTheNodes;
  String fileName;
algorithm
  TASKGRAPHMETA(inComps = inComps, varSccMapping=varSccMapping, eqSccMapping=eqSccMapping, rootNodes = rootNodes, nodeNames =nodeNames,nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) := graphDataIn;
  BackendDAE.DAE(eqs = systs) := daeIn;
  allTheNodes := List.intRange(arrayLength(graphIn));  // to parse the node indeces
  oneChildren := findOneChildParents(allTheNodes,graphIn,{{}},0);
  oneChildren := listDelete(oneChildren,listLength(oneChildren)-1); // remove the empty startValue
  oneChildren := List.removeOnTrue(1,compareListLengthOnTrue,oneChildren);  // remove paths of length 1
  //oneChildren := List.fold1(List.intRange(listLength(oneChildren)),checkParentNode,graphIn,oneChildren);  // deletes the lists with just one entry that have more than one parent
  (graphOut,graphDataOut) := contractNodesInGraph(oneChildren,graphIn,graphDataIn);
  fileName := "taskgraph_1_"+&filenamePrefix+&".graphml";
  dumpAsGraphMLSccLevel(graphOut,graphDataOut,fileName);
end mergeSimpleNodes;


protected function contractNodesInGraph " function to contract the nodes given in the list to one node.
author: Waurich TUD 2013-07"
  input list<list<Integer>> contractNodes;
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
  Integer endNode;
  Integer startNode;
  list<Integer> deleteEntries;
  list<Integer> endChildren;
  TaskGraph graphTmp;
algorithm
  startNode := List.last(contractNodes);
  deleteEntries := List.deleteMember(contractNodes,startNode);
  endNode := List.first(contractNodes);
  endChildren := arrayGet(graphIn,endNode);
  graphTmp := arrayUpdate(graphIn,startNode,endChildren);
  graphOut := graphTmp;  
end contractNodesInGraph1;


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
  array<Integer> varSccMapping;
  array<Integer> eqSccMapping;
  list<Integer> rootNodes;
  array<String> nodeNames;
  array<String> nodeDescs;
  array<tuple<Integer,Real>> exeCosts;
  array<list<tuple<Integer,Integer,Integer>>> commCosts;
  array<Integer>nodeMark;
  list<list<Integer>> inCompsLst;
algorithm
  TASKGRAPHMETA(inComps = inComps, varSccMapping=varSccMapping, eqSccMapping=eqSccMapping, rootNodes = rootNodes, nodeNames =nodeNames, nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) := graphDataIn;
  inComps := updateInCompsForMerging(inComps,contractNodes);
  eqSccMapping := eqSccMapping;
  rootNodes := rootNodes;
  nodeNames := List.fold2(List.intRange(arrayLength(nodeNames)),updateNodeNamesForMerging,inComps,nodeMark,nodeNames);
  nodeDescs := nodeDescs;
  exeCosts := exeCosts;
  commCosts := commCosts;
  nodeMark := nodeMark;
  graphDataOut := TASKGRAPHMETA(inComps,varSccMapping,eqSccMapping,rootNodes,nodeNames,nodeDescs,exeCosts,commCosts,nodeMark);
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
        unionNode = getCompInComps(compIdx,1,inComps,nodeMark);
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
   end matchcontinue;
end updateNodeNamesForMerging;
      

protected function updateInCompsForMerging " updates the inComps with the merging information.
author:waurich TUD 2013-07"
  input array<list<Integer>> inCompsIn;
  input list<list<Integer>> mergedPaths;
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
  input Integer compIdx;
  input tuple<list<Integer>,list<Integer>,list<list<Integer>>> mergeInfo;
  input array<list<Integer>> primInComps;
  input list<list<Integer>> inCompLstIn;
  output list<list<Integer>> inCompLstOut;
algorithm
  inCompLstOut := matchcontinue(compIdx,mergeInfo,primInComps,inCompLstIn)
    local
      Integer mergeGroupIdx;
      list<Integer> inComps;
      Integer inComp;
      list<Integer> mergedSet;
      list<Integer> startNodes;
      list<Integer> deleteNodes;
      list<list<Integer>> mergedPaths;
      list<list<Integer>> inCompLstTmp;
    case(_,_,_,_)
      // the given inComp is a startNode
      equation
        (startNodes,deleteNodes,mergedPaths) = mergeInfo;
        inComps = listGet(inCompLstIn,compIdx);
        true = listLength(inComps) == 1;
        inComp = listGet(inComps,1);
        true = List.isMemberOnTrue(compIdx,startNodes,intEq);
        mergeGroupIdx = List.position(compIdx,startNodes)+1;
        mergedSet = listGet(mergedPaths,mergeGroupIdx);
        mergedSet = List.flatten(List.map1(mergedSet,Util.arrayGetIndexFirst,primInComps));
        inCompLstTmp = List.replaceAt(mergedSet,compIdx-1,inCompLstIn);
      then
        inCompLstTmp;
    case(_,_,_,_)
      // the given inComps is a merged node
      equation
        (startNodes,deleteNodes,mergedPaths) = mergeInfo;
        true = listLength(listGet(inCompLstIn,compIdx)) == 1;
        true = List.isMemberOnTrue(compIdx,deleteNodes,intEq);
        inCompLstTmp = List.replaceAt({},compIdx-1,inCompLstIn);
      then
        inCompLstTmp;
    case(_,_,_,_)
      // the given inComp is just a node which is not contracted
      equation
        true = listLength(listGet(inCompLstIn,compIdx)) == 1;
      then
        inCompLstIn;        
    else
      equation
        print("updateInComps1 failed for compIdx\n");
      then
        fail();
  end matchcontinue;
end updateInComps1;


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
author:Waurich TUD 2013-07"
  input list<Integer> allNodes;
  input TaskGraph graphIn;
  input list<list<Integer>> lstIn;
  input Integer inPath;  // the current nodeINdex in a path of only cildren. if no path then 0.
  output list<list<Integer>> lstOut;
algorithm
  lstOut := matchcontinue(allNodes,graphIn,lstIn,inPath)
    local
      Integer child;
      Integer head;
      list<Integer> nodeChildren;
      list<Integer> parents;
      list<Integer> pathLst;
      list<Integer> rest;
      list<list<Integer>> lstTmp;
    case({},_,_,_)
      //checked all nodes
      equation
        then
          lstIn;
    case((head::rest),_,_,_)
      //check new node that has more children
      equation
        true = intEq(inPath,0);
        nodeChildren = arrayGet(graphIn,head);
        false = listLength(nodeChildren) == 1;
        lstTmp = findOneChildParents(rest,graphIn,lstIn,0);
      then
        lstTmp;
    case((head::rest),_,_,_)
      // check new node that has only one child , follow the path
      equation
        true = intEq(inPath,0);
        nodeChildren = arrayGet(graphIn,head);
        true = listLength(nodeChildren) == 1;
        child = listGet(nodeChildren,1);
        lstTmp = {head}::lstIn;
        lstTmp = findOneChildParents(rest,graphIn,lstTmp,child);
      then
        lstTmp;
    case(_,_,_,_)
      // follow path and check that there is still only one child with just one parent
      equation
        false = intEq(inPath,0);
        nodeChildren = arrayGet(graphIn,inPath);
        parents = getParentNodes(inPath,graphIn);
        true = listLength(nodeChildren) == 1 and listLength(parents) == 1;
        child = listGet(nodeChildren,1);
        pathLst = List.first(lstIn);
        pathLst = inPath::pathLst;
        lstTmp = List.replaceAt(pathLst,0,lstIn);     
        rest = List.deleteMember(allNodes,inPath); 
        lstTmp = findOneChildParents(rest,graphIn,lstTmp,child);
      then
        lstTmp;
    case(_,_,_,_)
      // follow path and check that there are more children or a child with more parents
      equation
        false = intEq(inPath,0);
        nodeChildren = arrayGet(graphIn,inPath);
        parents = getParentNodes(inPath,graphIn);
        true = listLength(nodeChildren) <> 1 or listLength(parents) <> 1;
        rest = List.deleteMember(allNodes,inPath); 
        lstTmp = findOneChildParents(rest,graphIn,lstIn,0);
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
  array<Integer> varSccMapping, varSccMapping1;
  array<Integer> eqSccMapping, eqSccMapping1;
  list<Integer> rootNodes, rootNodes1;
  array<String> nodeNames, nodeNames1;
  array<String> nodeDescs, nodeDescs1;
  array<tuple<Integer,Real>> exeCosts, exeCosts1;
  array<list<tuple<Integer,Integer,Integer>>> commCosts, commCosts1;
  array<Integer>nodeMark, nodeMark1;
algorithm
  TASKGRAPHMETA(inComps = inComps, varSccMapping=varSccMapping, eqSccMapping=eqSccMapping, rootNodes = rootNodes, nodeNames =nodeNames, nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) := graphDataIn;
  inComps1 := arrayCopy(inComps);  
  varSccMapping1 := arrayCopy(varSccMapping);   
  eqSccMapping1 := arrayCopy(eqSccMapping);   
  rootNodes1 := rootNodes; 
  nodeNames1 := arrayCopy(nodeNames);
  nodeDescs1 :=  arrayCopy(nodeDescs); 
  exeCosts1 := arrayCopy(exeCosts); 
  commCosts1 :=  arrayCopy(commCosts);
  nodeMark1 := arrayCopy(nodeMark);
  graphDataOut := TASKGRAPHMETA(inComps1,varSccMapping1,eqSccMapping1,rootNodes1,nodeNames1,nodeDescs1,exeCosts1,commCosts1,nodeMark1);
end copyTaskGraphMeta;

//------------------------------------------
//  Logic - filter task graph informations
//------------------------------------------
public function createCosts "function createCosts
  author: marcusw
  Updates the given TaskGraphMeta-Structure with the calculated exec und communication costs."
  input BackendDAE.BackendDAE iDae;
  input String benchFileName; //The name of the xml-file
  input array<Integer> simEqSccMapping; //Map each simEq to the scc
  input TaskGraphMeta iTaskGraphMeta;
  output TaskGraphMeta oTaskGraphMeta;

protected
  array<BackendDAE.EqSystem> compMapping;
  BackendDAE.Shared shared;
  BackendDAE.StrongComponents comps;
  tuple<Integer,Integer> reqTimeCom;
  //These mappings are for simEqSystems
  list<tuple<Integer,Integer,Real>> reqTimeOpLstSimCode; //<simEqIdx,numberOfCalcs,calcTimeSum>
  array<tuple<Integer,Real>> reqTimeOpSimCode;
  TaskGraphMeta tmpTaskGraphMeta;
  array<Real> reqTimeOp; //Calculation time for each scc
  array<list<Integer>> inComps;

algorithm
  oTaskGraphMeta := matchcontinue(iDae,benchFileName,simEqSccMapping,iTaskGraphMeta)
    case(BackendDAE.DAE(shared=shared),_,_,TASKGRAPHMETA(inComps=inComps))
      equation
        (comps,compMapping) = getSystemComponents(iDae); 
        ((_,reqTimeCom)) = HpcOmBenchmark.benchSystem();
        reqTimeOpLstSimCode = HpcOmBenchmark.readCalcTimesFromXml(benchFileName);
        reqTimeOpSimCode = arrayCreate(listLength(reqTimeOpLstSimCode),(-1,-1.0));
        reqTimeOpSimCode = List.fold(reqTimeOpLstSimCode, createCosts1, reqTimeOpSimCode);
        reqTimeOp = arrayCreate(listLength(comps),-1.0);
        reqTimeOp = convertSimEqToSccCosts(reqTimeOpSimCode, simEqSccMapping, reqTimeOp);
        ((_,tmpTaskGraphMeta)) = Util.arrayFold4(inComps,createCosts0,(comps,shared),compMapping, reqTimeOp, reqTimeCom, (1,iTaskGraphMeta));
      then tmpTaskGraphMeta;
    else
      equation
        print("Warning: Create execution costs failed. Maybe the _prof.xml-file is missing.\n");
      then iTaskGraphMeta;
  end matchcontinue;  
end createCosts;

protected function convertSimEqToSccCosts
  input array<tuple<Integer,Real>> iReqTimeOpSimCode;
  input array<Integer> iSimEqSccMapping; //Map each simEq to the scc
  input array<Real> iReqTimeOp;
  output array<Real> oReqTimeOp; //calcTime for each scc
  
algorithm
  print("convertSimEqToSccCosts\n");
  ((_,oReqTimeOp)) := Util.arrayFold1(iReqTimeOpSimCode, convertSimEqToSccCosts1, iSimEqSccMapping, (0,iReqTimeOp));  
end convertSimEqToSccCosts;

protected function convertSimEqToSccCosts1
  input tuple<Integer,Real> iReqTimeOpSimCode;
  input array<Integer> iSimEqSccMapping; //Map each simEq to the scc
  input tuple<Integer,array<Real>> iReqTimeOp;
  output tuple<Integer,array<Real>> oReqTimeOp; //calcTime for each scc
  
protected
  Integer simEqCalcCount, simEqIdx;
  Real simEqCalcTime;
  array<Real> reqTime;
  
algorithm
  (simEqCalcCount, simEqCalcTime) := iReqTimeOpSimCode;
  (simEqIdx,reqTime) := iReqTimeOp;
  reqTime := convertSimEqToSccCosts2(reqTime, simEqCalcTime, simEqIdx, iSimEqSccMapping);
  oReqTimeOp := (simEqIdx+1,reqTime);
end convertSimEqToSccCosts1;

protected function convertSimEqToSccCosts2
  input array<Real> iReqTime;
  input Real iSimEqCalcTime;
  input Integer iSimEqIdx;
  input array<Integer> iSimEqSccMapping; //Map each simEq to the scc
  output array<Real> oReqTime;
  
protected
  array<Real> reqTime;
  Integer sccIdx;
  
algorithm
  oReqTime := matchcontinue(iReqTime,iSimEqCalcTime, iSimEqIdx, iSimEqSccMapping)
    case(reqTime,_,_,_)
      equation
        true = intGe(arrayLength(iSimEqSccMapping),iSimEqIdx);
        sccIdx = arrayGet(iSimEqSccMapping, iSimEqIdx);
        true = intGt(sccIdx,0);
        reqTime = arrayUpdate(reqTime,sccIdx, iSimEqCalcTime);
        print("convertSimEqToSccCosts2 sccIdx: " +& intString(sccIdx) +& " reqTime: " +& realString(iSimEqCalcTime) +& "\n");
      then
        reqTime;
    else
      then iReqTime;
  end matchcontinue;
end convertSimEqToSccCosts2;

protected function createCosts0 "function createCosts0
  author: marcusw
  Updates the given TaskGraphMeta-Structure with the calculated exec und communication costs."
  input list<Integer> iNode; //Node to sccs mapping
  input tuple<BackendDAE.StrongComponents,BackendDAE.Shared> iComps_shared;
  input array<BackendDAE.EqSystem> iCompMapping;
  input array<Real> reqTimeOp;
  input tuple<Integer,Integer> reqTimeCom;
  input tuple<Integer,TaskGraphMeta> iTaskGraphMeta; //Node number and task graph meta
  output tuple<Integer,TaskGraphMeta> oTaskGraphMeta;

protected
  array<Integer> varSccMapping, eqSccMapping, nodeRefCount;
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
  TASKGRAPHMETA(inComps=inComps,varSccMapping=varSccMapping,eqSccMapping=eqSccMapping,nodeNames=nodeNames,nodeDescs=nodeDescs,rootNodes=rootNodes,exeCosts=execCosts,commCosts=commCosts,nodeMark=nodeRefCount) := taskGraphMeta;
  createExecCost(iNode, iComps_shared, reqTimeOp, execCosts, iCompMapping, nodeNumber);
  oTaskGraphMeta := ((nodeNumber+1, TASKGRAPHMETA(inComps,varSccMapping,eqSccMapping,rootNodes,nodeNames,nodeDescs,execCosts,commCosts,nodeRefCount)));
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

protected function createExecCost "function createExecCosts
  author: marcusw
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


protected function createExecCost0 "function createExecCosts0
  author: marcusw
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
  //print("Operations: ");
  //print(tuple3ToString((costAdd,costMul,costTrig)));
  //print("\n");
  oCosts := (costAdd+costMul+costTrig + iCosts_op, realAdd(iCosts_cyc,reqTime));
end createExecCost0;


protected function countOperations "function countOperations
  author: marcusw
  Count the operations of the given component."

  input BackendDAE.StrongComponent icomp;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  output tuple<Integer,Integer,Integer> operations; //<add,mul,trig>
  
protected
  Expression.ComponentRef cr;
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
        BackendDAE.EQUATION(exp=e1, scalar=e2, source=source) = BackendDAEUtil.equationNth(eqns, eqnIdx-1);
       
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


protected function createCommCosts "function createCommCosts
  author: marcusw
  Calculates the communication costs for the given edge-list."
  input list<tuple<Integer,Integer,Integer>> iCommCosts; //<child,numOfVars,cost>
  input tuple<Integer,Integer> reqTimeCom;
  output list<tuple<Integer,Integer,Integer>> oCommCosts;

algorithm
  oCommCosts := List.map1(iCommCosts, createCommCosts0, reqTimeCom);

end createCommCosts;


protected function createCommCosts0 "function createCommCosts0
  author: marcusw
  Helper function to create the communcation costs for an edge-list."
  input tuple<Integer,Integer,Integer> iCommCost;
  input tuple<Integer,Integer> reqTimeCom;
  output tuple<Integer,Integer,Integer> oCommCost;
  
protected
  Integer reqTimeComM, reqTimeComN, sccIdx, sccNumOfVars;
  
algorithm
  (reqTimeComM,reqTimeComN) := reqTimeCom;
  (sccIdx,sccNumOfVars,_) := iCommCost;
  oCommCost := ((sccIdx,sccNumOfVars,reqTimeComM*sccNumOfVars + reqTimeComN));
  
end createCommCosts0;


public function validateTaskGraphMeta "function validateTaskGraphMeta
  author: marcusw
  Check if the given TaskGraphMeta-object has a valid structure."
  input TaskGraphMeta iTaskGraph;
  input BackendDAE.BackendDAE iDae;
  output Boolean valid;

algorithm
  valid := matchcontinue(iTaskGraph, iDae)
    local
      BackendDAE.StrongComponents systComps, graphComps;
      array<BackendDAE.StrongComponent> systCompsArray;
    case(_,_)
      equation
        //Check if all StrongComponents are in the graph
        (systComps,_) = getSystemComponents(iDae);
        systCompsArray = listArray(systComps);
        graphComps = getGraphComponents(iTaskGraph,systCompsArray);
        true = validateComponents(graphComps,systComps);
        //Check if no component was connected twice
        //Check if all Nodes with mark 0 are in the root-node-list
        //Check if all marks correct
        //Check if nodeNames,nodeDescs and exeCosts-array have the right size
      then true;
    else then false;
  end matchcontinue;
  
end validateTaskGraphMeta;

protected function validateComponents "function validateComponents
  author: marcusw
  Checks if the given component-lists are eual."
  input BackendDAE.StrongComponents graphComps;
  input BackendDAE.StrongComponents systComps;
  output Boolean res;
  
protected
  BackendDAE.StrongComponents sortedGraphComps, sortedSystComps;
  
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

protected function compareComponents "function compareComponents
  author: marcusw
  Compares the given components and returns true if they are equal."
  input BackendDAE.StrongComponent comp1;
  input BackendDAE.StrongComponent comp2;
  output Boolean res;
  
protected 
  String comp1Str,comp2Str;
  Integer minLength;

algorithm
  comp1Str := BackendDump.printComponent(comp1);
  comp2Str := BackendDump.printComponent(comp2);
  minLength := intMin(stringLength(comp1Str),stringLength(comp2Str));
  res := intGt(System.strncmp(comp1Str, comp2Str, minLength), 0);
end compareComponents;


//evaluation and analysing functions
//------------------------------------------
//------------------------------------------

public function arrangeGraphInLevels "
author: Waurich TUD 2013-07"
  input TaskGraph graphIn;
  input TaskGraphMeta graphDataIn;
protected
  list<list<Integer>> parallelSets;
  array<tuple<Integer,Integer>> nodeCoords;
  array<list<Integer>> inComps;
  array<Integer> varSccMapping;
  array<Integer> eqSccMapping;
  list<Integer> rootNodes;
  array<String> nodeNames;
  array<String> nodeDescs;
  array<tuple<Integer,Real>> exeCosts;
  array<list<tuple<Integer,Integer,Integer>>> commCosts;
  array<Integer>nodeMark;
  TaskGraphMeta graphData;
algorithm
  parallelSets := getParallelSets(graphIn,graphDataIn);
  nodeCoords := getNodeCoords(parallelSets,graphIn);
  TASKGRAPHMETA(inComps = inComps, varSccMapping=varSccMapping, eqSccMapping=eqSccMapping, rootNodes = rootNodes, nodeNames =nodeNames, nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) := graphDataIn;
  nodeMark := List.fold2(List.intRange(arrayLength(graphIn)),setLevelInNodeMark,inComps,nodeCoords,nodeMark);
  graphData := TASKGRAPHMETA(inComps,varSccMapping,eqSccMapping,rootNodes,nodeNames,nodeDescs,exeCosts,commCosts,nodeMark);
  dumpAsGraphMLSccLevel(graphIn,graphData,"taskGraph.graphml");
end arrangeGraphInLevels;


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


protected function getParallelSets  " scatters the nodes of the taskGraph into sets of nodes that can be computed in parallel.
author:Waurich TUD 2013-07"
  input TaskGraph graphIn;
  input TaskGraphMeta graphDataIn;
  output list<list<Integer>> parallelSetsOut;
protected 
  list<Integer> rootNodes;
  list<Integer> allChildren;
algorithm
  TASKGRAPHMETA(rootNodes = rootNodes) := graphDataIn;
  allChildren := List.flatten(arrayList(graphIn));
  //print("allChildren "+&stringDelimitList(List.map(List.sort(allChildren,intGt),intString),",")+&"\n");
  rootNodes := List.fold1(List.intRange(arrayLength(graphIn)),getRootNodes,allChildren,{});
  //print("rootNodes "+&stringDelimitList(List.map(rootNodes,intString),",")+&"\n");
  parallelSetsOut := getParallelSets1(graphIn,rootNodes,{rootNodes});
  print("the number of parallel sets "+&intString(listLength(parallelSetsOut))+&" and the number of components "+&intString(arrayLength(graphIn))+&"\n");
end getParallelSets;


protected function getParallelSets1  " implementation of getParallelSets
author:Waurich TUD 2013-07"
  input TaskGraph graphIn;
  input list<Integer> rootNodes;
  input list<list<Integer>> parallelSetsIn;
  output list<list<Integer>> parallelSetsOut;
algorithm
  parallelSetsOut := matchcontinue(graphIn,rootNodes,parallelSetsIn)
    local
      list<list<Integer>> parallelSetsTmp;
      list<list<Integer>> rootChildren;
      list<Integer> parallelSet;
    case(_,_,_)
      equation
        true = listLength(List.flatten(parallelSetsIn)) < arrayLength(graphIn);
        rootChildren = List.map1(rootNodes, Util.arrayGetIndexFirst, graphIn);
        //print("the rootchilds: "+&stringDelimitList(List.map(List.flatten(rootChildren),intString),",")+&"\n");
        rootChildren = List.map2(rootChildren,getAllChildNodes,List.flatten(parallelSetsIn),graphIn);
        parallelSet = List.flatten(rootChildren);
        parallelSet = List.unique(parallelSet);
        //print("the next parallel set: "+&stringDelimitList(List.map(parallelSet,intString),",")+&"\n");
        //true = listLength(parallelSet) == listLength(rootChildren);
        parallelSetsTmp = cons(parallelSet,parallelSetsIn);
        //print("the current parallel set: "+&stringDelimitList(List.map(List.flatten(parallelSetsTmp),intString),",")+&"\n");
        parallelSetsTmp = getParallelSets1(graphIn,parallelSet,parallelSetsTmp);
      then
        parallelSetsTmp;
    case(_,_,_)
      equation
         true = listLength(List.flatten(parallelSetsIn)) >= arrayLength(graphIn);
         then
           parallelSetsIn;
    else
      equation
        print("getParallelSets1 failed \n");
      then
        fail();
  end matchcontinue;        
end getParallelSets1;


protected function getAllChildNodes " map function to remove all nodes from a list that have predecessors.
author: Waurich TUD 2013-07"
  input list<Integer> childNodesIn;
  input list<Integer> collectedNodes;
  input TaskGraph graphIn;
  output list<Integer> childNodesOut;
protected
  list<Integer> childNodesTmp;
algorithm
  //print("check childNodesIn "+&stringDelimitList(List.map(childNodesIn,intString),",")+&"\n");
  childNodesTmp := List.map2(childNodesIn,isOrphan,collectedNodes,graphIn);
  //print("check childNodesTmp1 "+&stringDelimitList(List.map(childNodesTmp,intString),",")+&"\n");
  childNodesTmp := List.removeOnTrue(-1,intEq,childNodesTmp);
  //print("check childNodesTmp2 "+&stringDelimitList(List.map(childNodesIn,intString),",")+&"\n");
  childNodesOut := childNodesTmp;
end getAllChildNodes;


protected function isOrphan "checks if the childNode has no parentNodes. if not -1 is output otherwise the node is output.
author: Waurich TUD 2013-07"
  input Integer childNodeIn;
  input list<Integer> collectedNodes;
  input TaskGraph graphIn;
  output Integer childNodeOut;
algorithm
  childNodeOut := matchcontinue(childNodeIn,collectedNodes,graphIn)
    local
      list<Integer> parents;
  case(_,_,_)
    equation
      parents = getParentNodes(childNodeIn,graphIn);
      //print("for "+&intString(childNodeIn)+&" the parents "+&stringDelimitList(List.map(parents,intString),",")+&"\n");
      //print("collected Nodes "+&stringDelimitList(List.map(collectedNodes,intString),",")+&"\n");
      (_,parents,_) = List.intersection1OnTrue(parents,childNodeIn::collectedNodes,intEq);
      true = listLength(parents) == 0;
    then
      childNodeIn;
  else
    then
      -1;
  end matchcontinue;
end isOrphan;      

protected function getRootNodes "fold function to compute the rootNodes of a taskGraph. //TODO: revise this brute function
  author:Waurich TUD 2013-07."
  input Integer nodeIdx;
  input list<Integer> allChildren;
  input list<Integer> rootsIn;
  output list<Integer> rootsOut;
algorithm
  rootsOut := matchcontinue(nodeIdx,allChildren,rootsIn)
    local
      list<Integer> rootsTmp;
    case(_,_,_)
      equation
        true = List.isMemberOnTrue(nodeIdx,allChildren,intEq);
      then
        rootsIn; 
    else
      equation
        rootsTmp = nodeIdx::rootsIn;
      then
        rootsTmp;
  end matchcontinue;
end getRootNodes;


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


protected function getYCoordForNode "fold function to compute the y-coordinate fpr the .graphml.
author: Waurich TUD 2013-07"
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
  levelInterval := 80;
  parallelSetIdx := getParallelSetForComp(compIdx,1,parallelSets);
  ((xCoord,yCoord)) := arrayGet(nodeCoordsIn,compIdx);
  coords := ((xCoord,parallelSetIdx*levelInterval));
  nodeCoordsOut := arrayUpdate(nodeCoordsIn,compIdx,coords);
end getYCoordForNode;
  
  

end HpcOmTaskGraph;
