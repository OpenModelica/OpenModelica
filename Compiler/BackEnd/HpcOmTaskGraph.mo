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

protected import BackendDAEOptimize;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
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
    array<Integer> nodeMark;  // put some additional stuff in here -> this is currently not a nodeMark, its a componentMark
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
  (graph,graphData) := getEmptyTaskGraph(1);
  ((graph,graphData)) := List.fold1(systs,createTaskGraph0,shared,(graph,graphData));  

  //printTaskGraph(graph);
  //printTaskGraphMeta(graphData);
  graphOut := graph;
  graphDataOut := graphData; 
end createTaskGraph;


public function getSystemComponents "author: marcusw
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
        //print("getSystemComponents0 number of components " +& intString(listLength(comps)) +& "\n");
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


protected function createTaskGraph0 "author: marcusw,waurich
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
  
  
protected function createTaskGraph1 "author: marcusw,waurich
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


//protected function fillCalcTimeArray "author: marcusw
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


protected function fillSccList "author: marcusw
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

  
protected function tupleToString "author: marcusw
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

protected function checkIfEquationContainsVar "author: marcusw
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
        List.isMemberOnTrue(var,eqnVars,compareIntTuple2);
  end match;
end checkIfEquationContainsVar;


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
    else then false;
 end matchcontinue;
end compareIntTuple2;

protected function getSCCByVar "author: marcusw
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


protected function createSccMapping "author: marcusw
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


protected function createSccMapping0 "author: marcusw,waurich
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
  list<Integer> cutNodeChildren;
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
  graphTmp := arrayCopy(graphIn);
  (graphTmp,cutNodes) := cutTaskGraph(graphTmp,stateNodes,whenNodes,{});
  cutNodeChildren := List.flatten(List.map1(listAppend(cutNodes,whenNodes),Util.arrayGetIndexFirst,graphIn)); // for computing new root-nodes when cutting out when-equations
  (_,cutNodeChildren,_) := List.intersection1OnTrue(cutNodeChildren,cutNodes,intEq);
  graphDataOdeOut := getOdeSystemData(graphDataIn,listAppend(cutNodes,whenNodes),cutNodeChildren);
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
  //(_,rootNodes,_) := List.intersection1OnTrue(rootNodes,cutNodes,intEq); //TODO:  this has to be updated(When cutting out When-nodes new roots arise) DONE!
  rootNodes := listAppend(rootNodes,cutNodeChildren);
  rootNodes := arrayList(removeContinuousEntries(listArray(rootNodes),cutNodes));
  rootNodes := List.removeOnTrue(-1, intEq, rootNodes);
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
  array<Integer> arrayTmp;
algorithm
  arrayTmp := Util.arrayMap1(arrayIn,invalidateEntry,deleteEntriesIn);
  deleteEntries := List.sort(deleteEntriesIn,intLt);
  arrayOut := Util.arrayMap1(arrayTmp,removeContinuousEntries1,deleteEntries); 
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

public function getLeaveNodes "function getLeaveNodes
  author: marcusw
  Get all leave-nodes of the given graph."
  input TaskGraph iTaskGraph;
  output List<Integer> oLeaveNodes;
algorithm
  oLeaveNodes := getLeaves(iTaskGraph,{},1);
end getLeaveNodes;

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
//        true = compareIntTuple2(varIdx, getVarTuple(compVarIdx));
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


public function dumpAsGraphMLSccLevel "author: marcusw, waurich
  Write out the given graph as a graphml file."
  input TaskGraph iGraph;
  input TaskGraphMeta iGraphData;
  input String fileName;
  input String criticalPathInfo; //Critical path as String
  input list<tuple<Integer,Integer>> iCriticalPath; //Critical path as list of edges
  input array<list<Integer>> sccSimEqMapping; //maps each scc to simEqSystems
  input array<tuple<Integer,Integer>> schedulerInfo; //maps each Task to <threadId, orderId>
protected
  GraphML.Graph graph;
  Integer nameAttIdx, calcTimeAttIdx, opCountAttIdx, yCoordAttIdx, taskIdAttIdx, commCostAttIdx, critPathAttIdx, simCodeEqAttIdx, threadIdAttIdx, taskNumberAttIdx;
  list<Integer> compIdc;
algorithm
  _ := match(iGraph, iGraphData, fileName, criticalPathInfo, iCriticalPath, sccSimEqMapping, schedulerInfo)
    case(_,_,_,_,_,_,_)
      equation 
        graph = GraphML.getGraph("TaskGraph", true);
        (nameAttIdx,graph) = GraphML.addAttribute("", "Name", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graph);
        (opCountAttIdx,graph) = GraphML.addAttribute("-1", "Operations", GraphML.TYPE_INTEGER(), GraphML.TARGET_NODE(), graph);
        (calcTimeAttIdx,graph) = GraphML.addAttribute("-1", "CalcTime", GraphML.TYPE_DOUBLE(), GraphML.TARGET_NODE(), graph);
        (taskIdAttIdx,graph) = GraphML.addAttribute("", "TaskID", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graph);
        (yCoordAttIdx,graph) = GraphML.addAttribute("17", "yCoord", GraphML.TYPE_INTEGER(), GraphML.TARGET_NODE(), graph);
        (simCodeEqAttIdx,graph) = GraphML.addAttribute("", "SimCodeEqs", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graph);
        (threadIdAttIdx,graph) = GraphML.addAttribute("", "ThreadId", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graph);
        (taskNumberAttIdx,graph) = GraphML.addAttribute("-1", "TaskNumber", GraphML.TYPE_INTEGER(), GraphML.TARGET_NODE(), graph);
        (commCostAttIdx,graph) = GraphML.addAttribute("-1", "CommCost", GraphML.TYPE_INTEGER(), GraphML.TARGET_EDGE(), graph);
        (critPathAttIdx,graph) = GraphML.addAttribute("", "CriticalPath", GraphML.TYPE_STRING(), GraphML.TARGET_GRAPH(), graph);
        graph = GraphML.addGraphAttributeValue((critPathAttIdx, criticalPathInfo), graph);
        compIdc = List.intRange(arrayLength(iGraph));
        graph = List.fold4(compIdc, addNodeToGraphML, (iGraph, iGraphData), (nameAttIdx,opCountAttIdx,calcTimeAttIdx,taskIdAttIdx,yCoordAttIdx,commCostAttIdx, simCodeEqAttIdx, threadIdAttIdx, taskNumberAttIdx), sccSimEqMapping, (iCriticalPath,schedulerInfo), graph);
        GraphML.dumpGraph(graph, fileName);
      then ();
  end match;
end dumpAsGraphMLSccLevel;


protected function addNodeToGraphML "author: marcusw, waurich
  Adds the given node to the given graph."
  input Integer nodeIdx;
  input tuple<TaskGraph, TaskGraphMeta> tGraphDataTuple;
  input tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> attIdc; 
  //Attribute index for <nameAttIdx,opCountAttIdx, calcTimeAttIdx, taskIdAttIdx, yCoordAttIdx, commCostAttIdx, simCodeEqAttIdx, threadIdAttIdx, taskNumberAttIdx>
  input array<list<Integer>> sccSimEqMapping;
  input tuple<list<tuple<Integer,Integer>>,array<tuple<Integer,Integer>>> iSchedulerInfoCritPath; //<criticalPath,schedulerInfo>
  input GraphML.Graph iGraph;
  output GraphML.Graph oGraph;
algorithm
  oGraph := matchcontinue(nodeIdx,tGraphDataTuple,attIdc,sccSimEqMapping,iSchedulerInfoCritPath,iGraph)
    local
      TaskGraph tGraphIn;
      TaskGraphMeta tGraphDataIn;
      GraphML.Graph tmpGraph;
      Integer opCount, nameAttIdx, calcTimeAttIdx, opCountAttIdx, taskIdAttIdx, yCoordAttIdx, commCostAttIdx, yCoord, simCodeEqAttIdx, threadIdAttIdx, taskNumberAttIdx;
      Real calcTime;
      Integer primalComp;
      list<Integer> childNodes;
      list<Integer> components;
      list<Integer> rootNodes;  
      list<Integer> simCodeEqs;
      array<Integer> varSccMapping;  
      array<Integer> eqSccMapping;  
      array<tuple<Integer,Real>> exeCosts;  
      array<Integer> nodeMark; 
      array<list<Integer>> inComps; 
      array<String> nodeNames; 
      array<String> nodeDescs;  
      array<list<tuple<Integer,Integer,Integer>>> commCosts;  
      String calcTimeString, calcTimeIntString, opCountString, yCoordString;
      String compText;
      String description;
      String nodeDesc;
      String componentsString;
      String simCodeEqString;
      String threadIdxString, taskNumberString;
      Integer schedulerThreadId, schedulerTaskNumber;
      list<GraphML.NodeLabel> additionalLabels;
      Integer calcTimeInt;
      array<tuple<Integer,Integer>> schedulerInfo;
      list<tuple<Integer,Integer>> criticalPath;
    case(_,(tGraphIn,tGraphDataIn),_,_,(criticalPath,schedulerInfo),_)
      equation
        false = nodeIdx == 0 or nodeIdx == -1;
        (nameAttIdx, opCountAttIdx, calcTimeAttIdx, taskIdAttIdx, yCoordAttIdx, commCostAttIdx, simCodeEqAttIdx, threadIdAttIdx, taskNumberAttIdx) = attIdc;
        TASKGRAPHMETA(inComps = inComps, eqSccMapping=eqSccMapping, rootNodes = rootNodes, nodeNames =nodeNames ,nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) = tGraphDataIn;
        components = arrayGet(inComps,nodeIdx);
        true = listLength(components)==1; 
        primalComp = listGet(components,1);
        //print("node in the taskGraph "+&intString(nodeIdx)+&" primalComp "+&intString(primalComp)+&"\n");
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
        simCodeEqs = arrayGet(sccSimEqMapping,primalComp);
        //print("Component " +& intString(primalComp) +& " arrayLength " +& intString(arrayLength(sccSimEqMapping)) +& "\n");
        //print("First simEq: " +& intString(List.first(simCodeEqs)) +& "\n");
        simCodeEqString = stringDelimitList(List.map(simCodeEqs,intString),", ");
        //componentsString = List.fold(components, addNodeToGraphML2, " ");
        componentsString = (" "+&intString(nodeIdx)+&" ");
        
        ((schedulerThreadId,schedulerTaskNumber)) = arrayGet(schedulerInfo,nodeIdx);
        threadIdxString = "Th " +& intString(schedulerThreadId);
        taskNumberString = intString(schedulerTaskNumber);
        
        calcTimeInt = realInt(calcTime);
        calcTimeIntString = intString(calcTimeInt);
        additionalLabels = {GraphML.NODELABEL_CORNER(calcTimeIntString, GraphML.COLOR_YELLOW, GraphML.FONTBOLD(), "se")};
        
        tmpGraph = GraphML.addNode("Node" +& intString(nodeIdx), componentsString, GraphML.COLOR_ORANGE, GraphML.RECTANGLE(), SOME(nodeDesc), {((nameAttIdx,compText)),((calcTimeAttIdx,calcTimeString)),((opCountAttIdx, opCountString)),((taskIdAttIdx,componentsString)),((yCoordAttIdx,yCoordString)),((simCodeEqAttIdx,simCodeEqString)),((threadIdAttIdx,threadIdxString)),((taskNumberAttIdx,taskNumberString))}, additionalLabels, iGraph);
        tmpGraph = List.fold4(childNodes, addDepToGraph, nodeIdx, tGraphDataIn, commCostAttIdx, criticalPath, tmpGraph);
      then 
        tmpGraph;
    case(_,(tGraphIn,tGraphDataIn),_,_,(criticalPath,schedulerInfo),_)
      equation
        // for a node that consists of contracted nodes
        false = nodeIdx == 0 or nodeIdx == -1;
        (nameAttIdx, opCountAttIdx, calcTimeAttIdx, taskIdAttIdx, yCoordAttIdx, commCostAttIdx, simCodeEqAttIdx, threadIdAttIdx, taskNumberAttIdx) = attIdc;
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
        //componentsString = List.fold(components, addNodeToGraphML2, " ");
        componentsString = (" "+&intString(nodeIdx)+&" ");
        simCodeEqs = arrayGet(sccSimEqMapping,primalComp);
        simCodeEqString = stringDelimitList(List.map(simCodeEqs,intString),", ");
        
        ((schedulerThreadId,schedulerTaskNumber)) = arrayGet(schedulerInfo,nodeIdx);
        threadIdxString = "Th " +& intString(schedulerThreadId);
        taskNumberString = intString(schedulerTaskNumber);
        
        calcTimeInt = realInt(calcTime);
        calcTimeIntString = intString(calcTimeInt);
        additionalLabels = {GraphML.NODELABEL_CORNER(calcTimeIntString, GraphML.COLOR_YELLOW, GraphML.FONTBOLD(), "se")};
        
        tmpGraph = GraphML.addNode("Node" +& intString(nodeIdx), componentsString, GraphML.COLOR_ORANGE, GraphML.RECTANGLE(), SOME(nodeDesc), {((nameAttIdx,compText)),((calcTimeAttIdx,calcTimeString)),((opCountAttIdx, opCountString)),((taskIdAttIdx,componentsString)), ((simCodeEqAttIdx,simCodeEqString)),((threadIdAttIdx,threadIdxString)),((taskNumberAttIdx,taskNumberString))}, additionalLabels, iGraph);
        tmpGraph = List.fold4(childNodes, addDepToGraph, nodeIdx, tGraphDataIn, commCostAttIdx, criticalPath, tmpGraph);
      then 
        tmpGraph;
    case(_,_,_,_,_,_)
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


protected function addDepToGraph "author: marcusw
  Adds a new edge between the component-nodes with index comp1Idx and comp2Idx to the graph."
  input Integer childIdx;
  input Integer parentIdx;
  input TaskGraphMeta tGraphDataIn;
  input Integer commCostAttIdx;
  input list<tuple<Integer,Integer>> criticalPathEdges;
  input GraphML.Graph iGraph;
  output GraphML.Graph oGraph;
protected
  array<list<tuple<Integer,Integer,Integer>>> commCosts;  
  Integer commCost, numOfCommVars, primalCompParent, primalCompChild;
  String refSccCountStr, commCostString, numOfCommVarsString;
  array<list<Integer>> inComps; 
  array<Integer> nodeMark;
  list<Integer> components;
  GraphML.Graph tmpGraph;
algorithm
  oGraph := matchcontinue(childIdx, parentIdx, tGraphDataIn, commCostAttIdx, criticalPathEdges, iGraph)
    case(_,_,TASKGRAPHMETA(commCosts=commCosts, nodeMark=nodeMark, inComps=inComps),_,_,_)
      equation
        true = List.exist1(criticalPathEdges, compareIntTuple2, (parentIdx, childIdx));
        //Edge is part of critical path
			  //components = arrayGet(inComps,childIdx);
			  //primalCompChild = List.last(components);
			  //components = arrayGet(inComps,parentIdx);
			  //primalCompParent = List.first(components);
			  //print("Try to get comm costs from " +& intString(parentIdx) +& " to " +& intString(childIdx) +& "\n");
			  //(numOfCommVars,commCost) = getCommunicationCost(primalCompParent,primalCompChild,commCosts);
			  ((_,numOfCommVars,commCost)) = getCommCostBetweenNodes(parentIdx,childIdx,tGraphDataIn);
			  numOfCommVarsString = intString(numOfCommVars);
			  commCostString = intString(commCost);
			  tmpGraph = GraphML.addEdge("Edge" +& intString(parentIdx) +& intString(childIdx), "Node" +& intString(childIdx), "Node" +& intString(parentIdx), GraphML.COLOR_BLACK, GraphML.LINE(), GraphML.LINEWIDTH_BOLD, SOME(GraphML.EDGELABEL(numOfCommVarsString,GraphML.COLOR_BLACK, GraphML.FONTSIZE_STANDARD)), (NONE(),SOME(GraphML.ARROWSTANDART())), {(commCostAttIdx, commCostString)}, iGraph);
			then tmpGraph;
    case(_,_,TASKGRAPHMETA(commCosts=commCosts, nodeMark=nodeMark, inComps=inComps),_,_,_)
      equation
        //components = arrayGet(inComps,childIdx);
        //primalCompChild = List.last(components);
        //components = arrayGet(inComps,parentIdx);
        //primalCompParent = List.first(components);
        //print("Try to get comm costs from " +& intString(parentIdx) +& " to " +& intString(childIdx) +& "\n");
        //(numOfCommVars,commCost) = getCommunicationCost(primalCompParent,primalCompChild,commCosts);
        ((_,numOfCommVars,commCost)) = getCommCostBetweenNodes(parentIdx,childIdx,tGraphDataIn);
        numOfCommVarsString = intString(numOfCommVars);
        commCostString = intString(commCost);
        tmpGraph = GraphML.addEdge("Edge" +& intString(parentIdx) +& intString(childIdx), "Node" +& intString(childIdx), "Node" +& intString(parentIdx), GraphML.COLOR_BLACK, GraphML.LINE(), GraphML.LINEWIDTH_STANDARD, SOME(GraphML.EDGELABEL(numOfCommVarsString,GraphML.COLOR_BLACK, GraphML.FONTSIZE_STANDARD)), (NONE(),SOME(GraphML.ARROWSTANDART())), {(commCostAttIdx, commCostString)}, iGraph);
      then tmpGraph;
    else
      equation
        print("HpcOmTaskGraph.addDepToGraph failed! Unsupported case\n");
      then fail();
  end matchcontinue;
end addDepToGraph;

protected function getCommunicationCost " gets the communication cost for an edge from parent node to child node.
  author: waurich TUD 2013-06."
  input Integer parentIdx;
  input Integer childIdx;
  input array<list<tuple<Integer,Integer,Integer>>> commCosts; 
  output Integer numOfVarsOut;
  output Integer costOut;
protected
  list<tuple<Integer,Integer,Integer>> commRow;
  tuple<Integer,Integer,Integer> commEntry;
algorithm
  //print("Try to get comm cost for edge from " +& intString(parentIdx) +& " to " +& intString(childIdx) +& "\n");
  commRow := arrayGet(commCosts,parentIdx);
  commEntry := getTupleByFirstEntry(commRow,childIdx);
  (_,numOfVarsOut,costOut) := commEntry;  
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
  

protected function tpl1IsMember " checks if the first entry in the tuple is a member of the list of tuples
author:Waurich TUD 2013-06"
  input list<tuple<Integer,Integer,Integer>> tplLstIn;
  input Integer valueIn;
  output Boolean isMember;
algorithm
  isMember := matchcontinue(tplLstIn,valueIn)
    local
      Integer tplValue;
      Boolean isMemberTmp;
      tuple<Integer,Integer,Integer> head;
      list<tuple<Integer,Integer,Integer>> rest;
    case(head::rest,_)
      equation
        (tplValue,_,_) = head;
        false = intEq(tplValue,valueIn);
        isMemberTmp = tpl1IsMember(rest,valueIn);
      then
        isMemberTmp;
    case(head::rest,_)
      equation
        (tplValue,_,_) = head;
        true = intEq(tplValue,valueIn);
      then
        true;
    case({},_)
      equation
      then
        false; 
  end matchcontinue;
end tpl1IsMember;


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



protected function intLstString "function to print a list<Integer>
author:Waurich TUD 2013-07"
  input list<Integer> lstIn;
  output String strOut;
algorithm
  strOut := stringDelimitList(List.map(lstIn,intString),",");  
end intLstString;


public function printLevelInfo " prints the information about the level of the nodes.
author: Waurich TUD 2013-07"
  input list<list<Integer>> parallelSetsIn;
protected Integer foldValue;
algorithm
  print("\n");
  print("--------------------------------\n");
  print("LEVEL INFO\n");
  print("--------------------------------\n");
  print(intString(listLength(parallelSetsIn))+&" levels in the graph with "+&intString(listLength(List.flatten(parallelSetsIn)))+&" components all in all\n");
  print("\n");
  print("node-level:\n");
  _ := List.fold1(List.intRange(listLength(parallelSetsIn)),printLevelInfo1,parallelSetsIn,0);
  print("\n");
end printLevelInfo;


protected function printLevelInfo1 " folding function to print the information of one level
author: Waurich TUD 2013-07"
  input Integer levelIdx; 
  input list<list<Integer>> parallelSetsIn;
  input Integer foldValueIn;
  output Integer foldValueOut;
protected
  list<Integer> levelNodes;
algorithm
  levelNodes := listGet(parallelSetsIn,levelIdx);
  print("level "+&intString(levelIdx)+&" includes nodes: ");
  print(intLstString(levelNodes)); 
  print("\n"); 
  foldValueOut := foldValueIn;
end printLevelInfo1;

public function dumpCriticalPathInfo "author:marcusw
  dump the criticalPath and the costs to a string."
  input list<list<Integer>> criticalPathsIn;
  input Real cpCosts;
  output String oString;
protected
  String tmpString;
algorithm
  oString := matchcontinue(criticalPathsIn,cpCosts)
  case({},_)
    equation
    then
      "";
  else
    equation
      tmpString = "critical path with costs of "+&realString(cpCosts)+&" cycles -- ";
      tmpString = tmpString +& dumpCriticalPathInfo1(criticalPathsIn,1);
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

// functions to merge simple nodes
//------------------------------------------
//------------------------------------------


public function mergeSimpleNodes " merges all nodes in the graph that have only one predecessor and one successor.
author: Waurich TUD 2013-07"
  input TaskGraph graphIn;
  input TaskGraphMeta graphDataIn;
  input BackendDAE.BackendDAE daeIn;
  output TaskGraph graphOut;
  output TaskGraphMeta graphDataOut;
  output Boolean oChanged;
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
  allTheNodes := List.intRange(arrayLength(graphIn));  // to traverse the node indeces
  oneChildren := findOneChildParents(allTheNodes,graphIn,{{}},0);  // paths of nodes with just one successor per node (extended: and endnodes with just one parent node)
  oneChildren := listDelete(oneChildren,listLength(oneChildren)-1); // remove the empty startValue {} 
  oneChildren := List.removeOnTrue(1,compareListLengthOnTrue,oneChildren);  // remove paths of length 1
  //oneChildren := List.fold1(List.intRange(listLength(oneChildren)),checkParentNode,graphIn,oneChildren);  // deletes the lists with just one entry that have more than one parent
  (graphOut,graphDataOut) := contractNodesInGraph(oneChildren,graphIn,graphDataIn);
  oChanged := intGt(listLength(oneChildren), 0);
end mergeSimpleNodes;


public function mergeParentNodes "author: marcusw
  Merges parent nodes into child if this produces a shorter execution time."
  input TaskGraph iGraph;
  input TaskGraphMeta iGraphData;
  output TaskGraph oGraph;
  output TaskGraphMeta oGraphData;
  output Boolean oChanged; //true if the structure has changed
protected
  TaskGraph iGraphT;
  list<list<Integer>> mergedNodes;
algorithm
  iGraphT := transposeTaskGraph(iGraph);
  mergedNodes := mergeParentNodes0(iGraph, iGraphT, iGraphData, 1, {});
  (oGraph,oGraphData) := contractNodesInGraph(mergedNodes, iGraph, iGraphData);
  oChanged := intGt(listLength(mergedNodes),0);
end mergeParentNodes;

protected function mergeParentNodes0
  input TaskGraph iGraph;
  input TaskGraph iGraphT;
  input TaskGraphMeta iGraphData;
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
  oMergedNodes := matchcontinue(iGraph, iGraphT, iGraphData, iNodeIdx, iMergedNodes)
    case(_,_,TASKGRAPHMETA(exeCosts=exeCosts, commCosts=commCosts),_,_)
      equation
        true = intLe(iNodeIdx, arrayLength(iGraphT)); //Current index is in range
        parentNodes = arrayGet(iGraphT, iNodeIdx);
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
        tmpMergedNodes = mergeParentNodes0(iGraph,iGraphT,iGraphData,iNodeIdx+1,tmpMergedNodes);
      then tmpMergedNodes;
    case(_,_,_,_,_)
      equation
        true = intLe(iNodeIdx, arrayLength(iGraphT)); //Current index is in range
        tmpMergedNodes = mergeParentNodes0(iGraph,iGraphT,iGraphData,iNodeIdx+1,iMergedNodes);
      then tmpMergedNodes;
    else then iMergedNodes;
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
    else then iHighestTuple;
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
  list<Integer> endChildren;
  list<Integer> deleteNodesParents; //all parents of deleted nodes
  TaskGraph graphTmp;
algorithm
  //This function contracts all nodes into the startNode
  graphInT := transposeTaskGraph(graphIn);
  //print("HpcOmTaskGraph.contractNodesInGraph1 startNode: " +& intString(List.last(contractNodes)) +& "\n");
  startNode := List.last(contractNodes);
  deleteEntries := List.deleteMember(contractNodes,startNode); //all nodes which should be deleted
  deleteNodesParents := List.flatten(List.map1(deleteEntries, Util.arrayGetIndexFirst, graphInT));
  deleteNodesParents := List.sortedUnique(List.sort(deleteNodesParents, intGt),intEq);
  deleteNodesParents := List.setDifferenceOnTrue(deleteNodesParents, contractNodes, intEq);
  //print("HpcOmTaskGraph.contractNodesInGraph1 deleteNodesParents: " +& stringDelimitList(List.map(deleteNodesParents,intString),",") +& "\n");
  endNode := List.first(contractNodes);
  endChildren := arrayGet(graphIn,endNode); //all child-nodes of the end node
  //print("HpcOmTaskGraph.contractNodesInGraph1 endChildren: " +& stringDelimitList(List.map(endChildren,intString),",") +& "\n");
  graphTmp := List.fold2(deleteNodesParents, contractNodesInGraph2, deleteEntries, startNode, graphIn);
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
  adjLstEntry := List.setDifferenceOnTrue(adjLstEntry, iDeletedNodes, intEq);
  adjLstEntry := iNewNodeIdx :: adjLstEntry;
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
        (startNodes,deleteNodes,mergedPaths) = mergeInfo;
        //print("updateInComps1 startNodes:" +& stringDelimitList(List.map(startNodes,intString),",") +& "\n");
        //print("updateInComps1 deleteNodes:" +& stringDelimitList(List.map(deleteNodes,intString),",") +& "\n");
        //print("updateInComps1 first mergedPath:" +& stringDelimitList(List.map(List.first(mergedPaths),intString),",") +& "\n");
        inComps = listGet(inCompLstIn,nodeIdx);
        //print("updateInComps1 inComps:" +& stringDelimitList(List.map(inComps,intString),",") +& "\n");
        //true = listLength(inComps) == 1;
        inComp = listGet(inComps,1);
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
  input list<list<Integer>> lstIn;
  input Integer inPath;  // the current nodeIndex in a path of only cildren. if no path then 0.
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
        true = listLength(nodeChildren) == 1 and List.isNotEmpty(nodeChildren) and listLength(parents) == 1;
        child = listGet(nodeChildren,1);
        pathLst = List.first(lstIn);
        pathLst = inPath::pathLst;
        lstTmp = List.replaceAt(pathLst,0,lstIn);     
        rest = List.deleteMember(allNodes,inPath); 
        lstTmp = findOneChildParents(rest,graphIn,lstTmp,child);
      then
        lstTmp;
    case(_,_,_,_)
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
        lstTmp = findOneChildParents(rest,graphIn,lstTmp,0);
      then
        lstTmp;
    case(_,_,_,_)
      // follow path and check that there are more children or a child with more parents. end path before this node
      equation
        false = intEq(inPath,0);
        nodeChildren = arrayGet(graphIn,inPath);
        parents = getParentNodes(inPath,graphIn);
        true = listLength(nodeChildren) <> 1 or listLength(parents) <> 1;
        //rest = List.deleteMember(allNodes,inPath); 
        //lstTmp = findOneChildParents(rest,graphIn,lstIn,0);
        lstTmp = findOneChildParents(allNodes,graphIn,lstIn,0);
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
public function createCosts "author: marcusw
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
  array<list<tuple<Integer, Integer, Integer>>> commCosts;

algorithm
  oTaskGraphMeta := matchcontinue(iDae,benchFileName,simEqSccMapping,iTaskGraphMeta)
    case(BackendDAE.DAE(shared=shared),_,_,TASKGRAPHMETA(inComps=inComps, commCosts=commCosts))
      equation
        (comps,compMapping) = getSystemComponents(iDae); 
        ((_,reqTimeCom)) = HpcOmBenchmark.benchSystem();
        reqTimeOpLstSimCode = HpcOmBenchmark.readCalcTimesFromXml(benchFileName);
        reqTimeOpSimCode = arrayCreate(listLength(reqTimeOpLstSimCode),(-1,-1.0));
        reqTimeOpSimCode = List.fold(reqTimeOpLstSimCode, createCosts1, reqTimeOpSimCode);
        reqTimeOp = arrayCreate(listLength(comps),-1.0);
        reqTimeOp = convertSimEqToSccCosts(reqTimeOpSimCode, simEqSccMapping, reqTimeOp);
        commCosts = createCommCosts(commCosts,1,reqTimeCom);
        ((_,tmpTaskGraphMeta)) = Util.arrayFold4(inComps,createCosts0,(comps,shared),compMapping, reqTimeOp, reqTimeCom, (1,iTaskGraphMeta));
      then tmpTaskGraphMeta;
    else
      equation
        print("Warning: Create costs failed. Maybe the _prof.xml-file is missing.\n");
      then iTaskGraphMeta;
  end matchcontinue;  
end createCosts;

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
    else then iEdgeList;
  end matchcontinue;
end convertNodeListToEdgeTuples0;

protected function convertSimEqToSccCosts
  input array<tuple<Integer,Real>> iReqTimeOpSimCode;
  input array<Integer> iSimEqSccMapping; //Map each simEq to the scc
  input array<Real> iReqTimeOp;
  output array<Real> oReqTimeOp; //calcTime for each scc
  
algorithm
  ((_,oReqTimeOp)) := Util.arrayFold1(iReqTimeOpSimCode, convertSimEqToSccCosts1, iSimEqSccMapping, (0,iReqTimeOp));  
end convertSimEqToSccCosts;

protected function convertSimEqToSccCosts1
  input tuple<Integer,Real> iReqTimeOpSimCode;
  input array<Integer> iSimEqSccMapping; //Map each simEq to the scc
  input tuple<Integer,array<Real>> iReqTimeOp;
  output tuple<Integer,array<Real>> oReqTimeOp; //calcTime for each scc
  
protected
  Integer simEqCalcCount, simEqIdx;
  Real simEqCalcTime, realSimEqCalcCount;
  array<Real> reqTime;
  
algorithm
  oReqTimeOp := matchcontinue(iReqTimeOpSimCode,iSimEqSccMapping,iReqTimeOp)
    case(_,_,_)
      equation
        (simEqCalcCount, simEqCalcTime) = iReqTimeOpSimCode;
        (simEqIdx,reqTime) = iReqTimeOp;
        realSimEqCalcCount = intReal(simEqCalcCount);
        true = realNe(realSimEqCalcCount,0.0);
        reqTime = convertSimEqToSccCosts2(reqTime, realDiv(simEqCalcTime,realSimEqCalcCount), simEqIdx, iSimEqSccMapping);
      then ((simEqIdx+1,reqTime));
    else
      equation
        (simEqCalcCount, simEqCalcTime) = iReqTimeOpSimCode;
        (simEqIdx,reqTime) = iReqTimeOp;
        realSimEqCalcCount = intReal(simEqCalcCount);
        reqTime = convertSimEqToSccCosts2(reqTime, 0.0, simEqIdx, iSimEqSccMapping); 
      then ((simEqIdx+1,reqTime));
  end matchcontinue;  
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
    else then iCosts;
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
    case(_,_)
      equation
        //Check if all StrongComponents are in the graph
        (systComps,_) = getSystemComponents(iDae);
        systCompsArray = listArray(systComps);
        graphComps = getGraphComponents(iTaskGraph,systCompsArray);
        //print("Graph components: " +& stringDelimitList(List.map(graphComps,BackendDump.printComponent), ";") +& "\n");
        true = validateComponents(graphComps,systComps);
        //Check if no component was connected twice
        true = checkForDuplicates(graphComps);
        //Check if nodeNames,nodeDescs and exeCosts-array have the right size
      then true;
    else then false;
  end matchcontinue;
  
end validateTaskGraphMeta;

protected function validateComponents "author: marcusw
  Checks if the given component-lists are equal."
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

protected function checkForDuplicates "author: marcusw
  Returns true if every component is unique in the list."
  input BackendDAE.StrongComponents iComps;
  output Boolean res;
protected
  BackendDAE.StrongComponents sortedComps;
algorithm
  sortedComps := List.sort(iComps,compareComponents);
  //print("Components: " +& stringDelimitList(List.map(sortedComps,BackendDump.printComponent), ";") +& "\n");
  ((res,_)) := List.fold(sortedComps,checkForDuplicates0,(true,NONE()));
end checkForDuplicates;

protected function checkForDuplicates0
  input BackendDAE.StrongComponent currentComp;
  input tuple<Boolean,Option<BackendDAE.StrongComponent>> iLastComp; //<result,lastComp>
  output tuple<Boolean,Option<BackendDAE.StrongComponent>> oLastComp; //<result,lastComp>
protected
  BackendDAE.StrongComponent lastComp;  
algorithm
  oLastComp := matchcontinue(currentComp,iLastComp)
    case(_,(false,_)) then ((false,SOME(currentComp)));
    case(_,(_,NONE())) then ((true,SOME(currentComp)));
    case(_,(_,SOME(lastComp)))
      equation
        false = compareComponents(currentComp,lastComp);
        print("The component " +& BackendDump.printComponent(currentComp) +& " was twice in the structure.\n");
      then ((false,SOME(currentComp)));
    else then ((true, SOME(currentComp)));
  end matchcontinue;
end checkForDuplicates0;

protected function getGraphComponents "author: marcusw
  Returns all StrongComponents of the TaskGraphMeta-structure."
  input TaskGraphMeta iTaskGraphMeta;
  input array<BackendDAE.StrongComponent> systComps;
  output BackendDAE.StrongComponents oComps;
  
protected
  BackendDAE.StrongComponents tmpComps;
  array<list<Integer>> inComps;
  array<Integer> nodeMarks;
  
algorithm
  tmpComps := {};
  TASKGRAPHMETA(inComps=inComps, nodeMark=nodeMarks) := iTaskGraphMeta;
  tmpComps := Util.arrayFold1(inComps,getGraphComponents0,systComps,tmpComps);
  ((_,tmpComps)) := Util.arrayFold1(nodeMarks,getGraphComponents2, systComps,(1,tmpComps));
  oComps := tmpComps;
end getGraphComponents;


protected function getGraphComponents0 "author: marcusw
  Helper function of getGraphComponents. Returns all components which are not marked with -1."
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

protected function getGraphComponents2 "author: marcusw
  Append all components with mark -1 to the componentlist."
  input Integer nodeMark;
  input array<BackendDAE.StrongComponent> systComps;
  input tuple<Integer,BackendDAE.StrongComponents> iComps; //<nodeIdx, components>
  output tuple<Integer,BackendDAE.StrongComponents> oComps;
  
protected
  Integer nodeIdx;
  BackendDAE.StrongComponent comp;
  BackendDAE.StrongComponents comps;
  
algorithm
  oComps := matchcontinue(nodeMark, systComps, iComps)
    case(_,_,(nodeIdx,comps))
      equation
        true = intGe(nodeMark,0);
      then ((nodeIdx+1,comps));
    case(_,_,(nodeIdx,comps))
      equation
        comp = arrayGet(systComps,nodeIdx);
        comps = comp :: comps;
      then ((nodeIdx+1,comps));
  end matchcontinue;
end getGraphComponents2;

protected function compareComponents "author: marcusw
  Compares the given components and returns false if they are equal."
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
 

public function longestPathMethod " function to assign levels to the nodes of a graph and compute the criticalPath.
for every set of rootNodes set the next minimal levelValue and the costs. Assign to their childNodes the next minimal levelValue and the highest costs and choose them as new rootNodes.
author: Waurich TUD 2013-07"
  input TaskGraph graphIn;
  input TaskGraphMeta graphDataIn;
  output list<list<Integer>> criticalPathOut;
  output Real cpCostsOut;
  output list<list<Integer>> parallelSetsOut;
algorithm
  (criticalPathOut,cpCostsOut,parallelSetsOut) := matchcontinue(graphIn,graphDataIn)
    local
      TaskGraph graphInT;
      Real cpCostsTmp;
      Integer rootParent;
      list<Integer> rootNodes;
      list<list<Integer>> parallelSets;
      list<list<Integer>> criticalPathTmp;
      array<Integer> nodeMark;
      array<list<Integer>> inComps;
      array<tuple<Integer,Real,Integer>> nodeInfo; //array[nodeIdx]--> tuple(levelValue,costValue,parentCount)
      array<tuple<Integer,Integer>> nodeCoords;
    case(_,_)
      equation    
        true = arrayLength(graphIn) <> 0;
        TASKGRAPHMETA(inComps = inComps, nodeMark=nodeMark) = graphDataIn;
        graphInT = transposeTaskGraph(graphIn);
        rootNodes = getRootNodes(graphInT);
        nodeInfo = arrayCreate(arrayLength(graphIn),(-1,-1.0,0));
        nodeInfo = List.fold1(List.intRange(arrayLength(graphIn)),setParentCount,graphIn,nodeInfo);
        nodeInfo = longestPathMethod1(graphIn,graphDataIn,rootNodes,List.fill(0,listLength(rootNodes)),nodeInfo);
        parallelSets = gatherParallelSets(nodeInfo);
        nodeCoords = getNodeCoords(parallelSets,graphIn);
        nodeMark = List.fold2(List.intRange(arrayLength(graphIn)),setLevelInNodeMark,inComps,nodeCoords,nodeMark);
        (criticalPathTmp,cpCostsTmp) = getCriticalPath(graphIn,graphDataIn,rootNodes);
        //print("the critical paths: "+&stringDelimitList(List.map(criticalPathTmp,intLstString)," ; ")+&" with the costs "+&realString(cpCostsTmp)+&"\n");
      then
        (criticalPathTmp,cpCostsTmp,parallelSets);
    case(_,_)
      equation
        true = arrayLength(graphIn) == 0;
      then
        ({{}},0.0,{});
    else
      equation
        print("longestPathMethod failed!\n");
      then
        ({{}},0.0,{});
  end matchcontinue;
end longestPathMethod;


protected function longestPathMethod1 "fills the nodeInfo-array for sets of Nodes without predecessor(i.e. rootNodes)
author: Waurich TUD 2013-07"
  input TaskGraph graphIn;
  input TaskGraphMeta graphDataIn;
  input list<Integer> rootNodesIn;
  input list<Integer> rootParentsIn;
  input array<tuple<Integer,Real,Integer>> nodeInfoIn;
  output array<tuple<Integer,Real,Integer>> nodeInfoOut;
algorithm
    nodeInfoOut := matchcontinue(graphIn,graphDataIn,rootNodesIn,rootParentsIn,nodeInfoIn)
      local
        array<tuple<Integer,Real,Integer>> nodeInfo;
        list<Integer> parentLst;
        list<Integer> rootNodes;
        list<Integer> rootIdcs;
        list<list<Integer>> childLst;
        list<Integer> childLstFlat;
    case(_,_,_,_,_)
      equation
        // check the set of rootNodes and continue with their childNodes
        false = List.isEmpty(rootNodesIn);
        rootIdcs = List.intRange(listLength(rootNodesIn));
        ((childLst,nodeInfo)) = List.fold3(rootIdcs,longestPathMethod2,graphIn,graphDataIn,(rootNodesIn,rootParentsIn),({},nodeInfoIn));
        childLst = listReverse(childLst);
        childLstFlat = List.flatten(childLst);
        parentLst = List.fold2(rootIdcs,getRootParentLst,rootNodesIn,childLst,{});
        nodeInfo = longestPathMethod1(graphIn,graphDataIn,childLstFlat,parentLst,nodeInfoIn);
     then
       nodeInfo;
    case(_,_,_,_,_)
      equation
        // all done
        true = List.isEmpty(rootNodesIn);
     then
       nodeInfoIn;
  end matchcontinue;
end longestPathMethod1;


protected function longestPathMethod2 "gets the childNodes for the analysed rootNode and updates the nodeInfoArray for the rootNodes // TODO:remove double pairs of rootnode and rootparents (see getRootParents2)
author: Waurich TUD 2013-07"
  input Integer rootIdx;
  input TaskGraph graphIn;
  input TaskGraphMeta graphDataIn;
  input tuple<list<Integer>,list<Integer>> rootNodeInfo;
  input tuple<list<list<Integer>>,array<tuple<Integer,Real,Integer>>> foldIn;  // the childNodes of all rootNodes and the array with the nodeInfos
  output tuple<list<list<Integer>>,array<tuple<Integer,Real,Integer>>> foldOut;
algorithm
  foldOut := matchcontinue(rootIdx,graphIn,graphDataIn,rootNodeInfo,foldIn)
    local
      Real costValue1;
      Real costValue2;
      Real costValueParent;
      Integer levelValue1;
      Integer levelValue2;
      Integer levelValueParent;
      Integer parentCount1;
      Integer parentCount2;
      Integer parentNode;
      Integer rootNode;
      Integer rootParent;
      list<Integer> childNodes;
      list<Integer> rootNodes;
      list<Integer> rootParents;
      list<list<Integer>> childNodesIn;
      list<list<Integer>> childNodesTmp;
      list<list<Integer>> childNodesOut;
      tuple<Integer,Real,Integer> rootInfo;
      tuple<Integer,Integer> parentInfo;
      array<list<Integer>> inComps;
      array<tuple<Integer,Real>> exeCosts;
      array<tuple<Integer,Real,Integer>> nodeInfoIn;
      array<tuple<Integer,Real,Integer>> nodeInfoOut;
      array<tuple<Integer,Real,Integer>> nodeInfoTmp;
      array<list<tuple<Integer,Integer,Integer>>> commCosts;
      tuple<list<list<Integer>>,array<tuple<Integer,Real,Integer>>> foldTmp;
    case(_,_,_,_,_)
      equation
        // check the first rootnode
        (childNodesIn,nodeInfoIn) = foldIn;
        (rootNodes,rootParents) = rootNodeInfo;
        rootNode = listGet(rootNodes,rootIdx);
        rootParent = listGet(rootParents,rootIdx);
        rootInfo = arrayGet(nodeInfoIn,rootNode);
        (levelValue1,costValue1,parentCount1) = rootInfo;
        true = rootParent == 0;
        true = parentCount1 == 0;
        true = levelValue1 == -1 and costValue1 ==. -1.0;
        //print("rootNode "+&intString(rootNode)+&" with level "+&intString(levelValue1)+&" and costs "+&realString(costValue1)+&" and parentCount "+&intString(parentCount1)+&"\n");
        TASKGRAPHMETA(inComps = inComps, exeCosts = exeCosts, commCosts = commCosts) = graphDataIn;
        costValue2 = getCostsForNode(0,rootNode,inComps,exeCosts,commCosts);
        rootInfo = (1,costValue2,parentCount1);
        nodeInfoTmp = arrayUpdate(nodeInfoIn,rootNode,rootInfo);
        childNodes = arrayGet(graphIn,rootNode);
        childNodesTmp = childNodes::childNodesIn;   
        //print(" set level "+&intString(1)+&" and costs "+&realString(costValue2)+&" and childLst: "+&stringDelimitList(List.map(childNodes,intString),",")+&"\n"); 
        foldTmp = (childNodesTmp,nodeInfoTmp);
      then
        foldTmp;
    case(_,_,_,_,_)
      equation
        // check nextlevelNode and do append the childLst
        (childNodesIn,nodeInfoIn) = foldIn;
        (rootNodes,rootParents) = rootNodeInfo;
        rootNode = listGet(rootNodes,rootIdx);
        rootParent = listGet(rootParents,rootIdx);
        rootInfo = arrayGet(nodeInfoIn,rootNode);
        (levelValue1,costValue1,parentCount1) = rootInfo;
        true = rootParent > 0;
        true = parentCount1 == 1;
        //print("next node "+&intString(rootNode)+&" with level "+&intString(levelValue1)+&" and costs "+&realString(costValue1)+&" and parentCount "+&intString(parentCount1)+&"\n");
        ((levelValueParent,costValueParent,_)) = arrayGet(nodeInfoIn,rootParent);
        TASKGRAPHMETA(inComps = inComps, exeCosts = exeCosts, commCosts = commCosts) = graphDataIn;
        costValue2 = getCostsForNode(rootParent,rootNode,inComps,exeCosts,commCosts);
        costValue2 = costValueParent +. costValue2;
        costValue2 = realMax(costValue1,costValue2);
        levelValue2 = intMax(levelValueParent+1,levelValue1);
        parentCount2 = parentCount1-1;
        rootInfo = (levelValue2,costValue2,parentCount1); 
        nodeInfoTmp = arrayUpdate(nodeInfoIn,rootNode,rootInfo);
        childNodes = arrayGet(graphIn,rootNode);  
        //print(" set level "+&intString(levelValue2)+&" and costs "+&realString(costValue2)+&" and parentCount "+&intString(parentCount2)+&" and childLst: "+&stringDelimitList(List.map(childNodes,intString),",")+&"\n");
        childNodesTmp = childNodes::childNodesIn;    
        foldTmp = (childNodesTmp,nodeInfoTmp);
      then
        foldTmp;
    case(_,_,_,_,_)
      equation
        // check nextlevelNode and do NOT append the childLst
        (childNodesIn,nodeInfoIn) = foldIn;
        (rootNodes,rootParents) = rootNodeInfo;
        rootNode = listGet(rootNodes,rootIdx);
        rootParent = listGet(rootParents,rootIdx);
        rootInfo = arrayGet(nodeInfoIn,rootNode);
        (levelValue1,costValue1,parentCount1) = rootInfo;
        true = rootParent > 0;
        true = parentCount1 > 1;
        //print("next node "+&intString(rootNode)+&" with level "+&intString(levelValue1)+&" and costs "+&realString(costValue1)+&" and parentCount "+&intString(parentCount1)+&"\n");
        ((levelValueParent,costValueParent,_)) = arrayGet(nodeInfoIn,rootParent);
        TASKGRAPHMETA(inComps = inComps, exeCosts = exeCosts, commCosts = commCosts) = graphDataIn;
        costValue2 = getCostsForNode(rootParent,rootNode,inComps,exeCosts,commCosts);
        costValue2 = costValueParent +. costValue2;
        costValue2 = realMax(costValue1,costValue2);
        levelValue2 = intMax(levelValueParent+1,levelValue1);
        parentCount2 = parentCount1-1;
        rootInfo = (levelValue2,costValue2,parentCount1-1); 
        nodeInfoTmp = arrayUpdate(nodeInfoIn,rootNode,rootInfo);
        childNodes = arrayGet(graphIn,rootNode);  
        //print(" set level "+&intString(levelValue2)+&" and costs "+&realString(costValue2)+&" and parentCount "+&intString(parentCount2)+&"\n");
        childNodesTmp = {}::childNodesIn;    
        foldTmp = (childNodesTmp,nodeInfoTmp);
      then
        foldTmp;
    else
      equation
        (childNodesIn,nodeInfoIn) = foldIn;
        (rootNodes,rootParents) = rootNodeInfo;
        rootNode = listGet(rootNodes,rootIdx);
        rootParent = listGet(rootParents,rootIdx);
        print("longestPathMethod2-failed! RootIdx: " +& intString(rootNode) +& " RootParent: " +& intString(rootParent) +& "\n");
        then
          fail();
  end matchcontinue;
end longestPathMethod2;


protected function setParentCount "sets the parentCount in the nodeinfo. i.e. the number of parentnodes of each node.
author: Waurich TUD 2013-07"
  input Integer parentIdx;
  input TaskGraph graphIn;
  input array<tuple<Integer,Real,Integer>> nodeInfoIn;
  output array<tuple<Integer,Real,Integer>> nodeInfoOut;
protected
  list<Integer> childLst;
  array<tuple<Integer,Real,Integer>> nodeInfoTmp;
algorithm
  childLst := arrayGet(graphIn,parentIdx);
  nodeInfoTmp := List.fold(childLst,setParentCount1,nodeInfoIn);
  nodeInfoOut := nodeInfoTmp;
end setParentCount;


protected function setParentCount1 " folding function for setParentCount1
author: Waurich TUD 2013-07"
  input Integer childNode;
  input array<tuple<Integer,Real,Integer>> nodeInfoIn;
  output array<tuple<Integer,Real,Integer>> nodeInfoOut;
protected
  Real costValue;
  Integer levelValue;
  Integer parentCount;
algorithm
  ((levelValue,costValue,parentCount)) := arrayGet(nodeInfoIn,childNode);
  nodeInfoOut := arrayUpdate(nodeInfoIn,childNode,(levelValue,costValue,parentCount+1));
end setParentCount1;

protected function getCriticalPath "function getCriticalPath
  author: marcusw
  Get the critical path of the graph."
  input TaskGraph iGraph;
  input TaskGraphMeta iGraphData;
  input list<Integer> iRootNodes;
  output list<list<Integer>> oCriticalPathsOut; //The list of critical paths -> has only one element
  output Real oCpCosts;
protected
  array<tuple<Real,list<Integer>>> nodeCriticalPaths; //<criticalPath,criticalPathSuccessor> for each node <%idx%>
  list<tuple<Real,list<Integer>>> criticalPaths;
  Integer criticalPathIdx;
  list<Integer> criticalPath;
algorithm
  nodeCriticalPaths := arrayCreate(arrayLength(iGraph), (-1.0,{}));
  criticalPaths := List.map3(iRootNodes, getCriticalPath1, iGraph, iGraphData, nodeCriticalPaths);
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
  list<tuple<Real,list<Integer>>> criticalPaths;
  
algorithm
  criticalPathOut := matchcontinue(iNode, iGraph, iGraphData, iNodeCriticalPaths)
    case(_,_,TASKGRAPHMETA(inComps=inComps,exeCosts=exeCosts),_)
      equation //In this case, the node was already visited
        ((cpCalcTime,criticalPath)) = arrayGet(iNodeCriticalPaths, iNode);
        true = realGe(cpCalcTime, 0.0);
      then ((cpCalcTime, criticalPath));
    case(_,_,TASKGRAPHMETA(inComps=inComps,exeCosts=exeCosts),_)
      equation //critical path of node is currently unknown -> calculate it
        childNodes = arrayGet(iGraph, iNode);
        true = intGt(listLength(childNodes),0); //has children
        criticalPaths = List.map3(childNodes, getCriticalPath1, iGraph, iGraphData, iNodeCriticalPaths);
        criticalPathIdx = getCriticalPath2(criticalPaths, 1, -1.0, -1);
        ((cpCalcTime, criticalPathChild)) = listGet(criticalPaths, criticalPathIdx);
        criticalPath = iNode :: criticalPathChild;
        commCost = getCommCostBetweenNodes(iNode, List.first(criticalPathChild), iGraphData);
        //print("Comm cost from node " +& intString(iNode) +& " to " +& intString(List.first(criticalPathChild)) +& " with costs " +& intString(Util.tuple33(commCost)) +& "\n");
        nodeComps = arrayGet(inComps, iNode);
        calcTime = addUpExeCostsForNode(nodeComps, exeCosts, 0.0); //sum up calc times of all components
        calcTime = realAdd(cpCalcTime,calcTime);
        calcTime = realAdd(calcTime, intReal(Util.tuple33(commCost)));
        _ = arrayUpdate(iNodeCriticalPaths, iNode, (calcTime, criticalPath));
      then ((calcTime, criticalPath));
    case(_,_,TASKGRAPHMETA(inComps=inComps,exeCosts=exeCosts),_)
      equation //critical path of node is currently unknown -> calculate it
        childNodes = arrayGet(iGraph, iNode);
        false = intGt(listLength(childNodes),0); //has no children
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
    else then iLongestPathIndex;
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
    else then iExeCost;
  end match;
end addUpExeCostsForNode;

//protected function getCriticalPath " computes the criticalPath
//auhtor: Waurich TUD 2013-07"
//  input TaskGraph graphIn;
//  input TaskGraphMeta graphDataIn;
//  input array<tuple<Integer,Real,Integer>> nodeInfoIn;
//  output list<list<Integer>> criticalPathsOut;
//  output Real cpCosts;
//protected
//  list<Integer> leaves;
//algorithm
//  leaves := getLeaves(graphIn,{},1);
//  print("Leaves " +& stringDelimitList(List.map(leaves, intString), " , ") +& "\n");
//  leaves := getCriticalPathEndNodes(leaves,nodeInfoIn,1,{});
//  ((_,cpCosts,_)) := arrayGet(nodeInfoIn,listGet(leaves,1));
//  criticalPathsOut := List.map4(leaves,getCriticalPath1,graphIn,graphDataIn,nodeInfoIn,{});
//end getCriticalPath;
//
//
//protected function getCriticalPath1 "finds the criticalPath based on the leave nodes with highest costs. TODO: avoid getParentLst, use transposed TG instead
//auhtor: Waurich TUD 2013 .07"
//  input Integer childNode;
//  input TaskGraph graphIn;
//  input TaskGraphMeta graphDataIn;
//  input array<tuple<Integer,Real,Integer>> nodeInfoIn;
//  input list<Integer> criticalPathIn;
//  output list<Integer> criticalPathOut;
//algorithm
//  criticalPathOut := matchcontinue(childNode,graphIn,graphDataIn,nodeInfoIn,criticalPathIn)
//    local
//      Integer parentNode;
//      Real childCosts;
//      list<Integer> parentNodes;
//      list<Integer> criticalPathTmp;
//      array<list<Integer>> inComps;
//      array<tuple<Integer,Real>> exeCosts;
//      array<list<tuple<Integer,Integer,Integer>>> commCosts;
//  case(_,_,_,_,_)
//    equation
//      criticalPathTmp = childNode::criticalPathIn;
//      parentNodes = getParentNodes(childNode,graphIn);
//      print("Parent nodes: " +& stringDelimitList(List.map(parentNodes, intString), ",") +& " of node " +& intString(childNode) +& "\n");
//      false = List.isEmpty(parentNodes);
//      ((_,childCosts,_)) = arrayGet(nodeInfoIn,childNode);
//      TASKGRAPHMETA(inComps = inComps, exeCosts=exeCosts, commCosts=commCosts) = graphDataIn;
//      parentNode = getCriticalPath2(parentNodes,childNode,(inComps,exeCosts,commCosts),nodeInfoIn,1);
//      criticalPathTmp = getCriticalPath1(parentNode,graphIn,graphDataIn,nodeInfoIn,criticalPathTmp);
//    then
//      criticalPathTmp;
//  case(_,_,_,_,_)
//    equation
//      criticalPathTmp = childNode::criticalPathIn;
//      parentNodes = getParentNodes(childNode,graphIn);
//      true = List.isEmpty(parentNodes);
//    then
//      criticalPathTmp;
//  end matchcontinue;   
//end getCriticalPath1; 
//
//
//protected function getCriticalPath2 " checks which predecessor node is the next.
//author: Waurich TUD 2013-07"
//  input list<Integer> parentNodeLst;
//  input Integer childNode;
//  input tuple<array<list<Integer>>,array<tuple<Integer,Real>>,array<list<tuple<Integer,Integer,Integer>>>> graphInfo;
//  input array<tuple<Integer,Real,Integer>> nodeInfoIn;
//  input Integer idx;
//  output Integer parentOut;
//algorithm
//  parentOut := matchcontinue(parentNodeLst,childNode,graphInfo,nodeInfoIn,idx)
//    local
//      Integer parentNode;
//      Real subCosts;
//      Real childCosts;
//      Real difference;
//      Real parentCostsExpected;
//      Real parentCostsGot;
//      array<list<Integer>> inComps;
//      array<tuple<Integer,Real>> exeCosts;
//      array<list<tuple<Integer,Integer,Integer>>> commCosts;
//    case(_,_,(inComps,exeCosts,commCosts),_,_)
//      equation
//        true = listLength(parentNodeLst) >= idx;
//        parentNode = listGet(parentNodeLst,idx);
//        ((_,parentCostsGot,_)) = arrayGet(nodeInfoIn,parentNode);
//        subCosts = getCostsForNode(parentNode,childNode,inComps,exeCosts,commCosts);
//        ((_,childCosts,_)) = arrayGet(nodeInfoIn,childNode);
//        parentCostsExpected = childCosts -. subCosts;
//        difference = parentCostsExpected -. parentCostsGot;
//        false = difference <. 0.00000000001 and difference >. -0.00000000001 ;
//        parentNode = getCriticalPath2(parentNodeLst,childNode,(inComps,exeCosts,commCosts),nodeInfoIn,idx+1);
//      then
//        parentNode;
//    case(_,_,(inComps,exeCosts,commCosts),_,_)
//      equation
//        true = listLength(parentNodeLst) >= idx;
//        parentNode = listGet(parentNodeLst,idx);
//        ((_,parentCostsGot,_)) = arrayGet(nodeInfoIn,parentNode);
//        subCosts = getCostsForNode(parentNode,childNode,inComps,exeCosts,commCosts);
//        ((_,childCosts,_)) = arrayGet(nodeInfoIn,childNode);
//        parentCostsExpected = childCosts -. subCosts;
//        difference = parentCostsExpected -. parentCostsGot;
//        true = difference <. 0.00000000001 and difference >. -0.00000000001 ;
//      then
//        parentNode;
//    case(_,_,(inComps,exeCosts,commCosts),_,_)
//      equation
//        true = List.isEmpty(parentNodeLst);
//      then
//        0;
//    case(_,_,(inComps,exeCosts,commCosts),_,_)
//      equation
//        true = listLength(parentNodeLst) < idx;
//        print("getCriticalPath2 failed! ListLength: " +& intString(listLength(parentNodeLst)) +& " idx: " +& intString(idx) +& "\n");
//      then
//        fail();        
//  end matchcontinue;     
//end getCriticalPath2;


//protected function getCriticalPathEndNodes "gets the nodes with the highest costs
//author: Waurich TUD 2013-07"
//  input list<Integer> endNodesIn;
//  input array<tuple<Integer,Real,Integer>> nodeInfoIn;
//  input Integer idx;
//  input list<Integer> maxCostNodes;
//  output list<Integer> endNodesOut; 
//protected
//  Integer endNode;
//  Integer maxEndNode;
//  Real nodeCosts;
//  Real maxCosts;
//  list<Integer> endNodesTmp;
//algorithm
//  endNodesOut := matchcontinue(endNodesIn,nodeInfoIn,idx,maxCostNodes)
//    local
//  case(_,_,_,_)
//    equation
//      true = listLength(endNodesIn) >= idx;
//      false = List.isEmpty(maxCostNodes);
//      maxEndNode = listGet(maxCostNodes,1);
//      ((_,maxCosts,_)) = arrayGet(nodeInfoIn,maxEndNode);
//      endNode = listGet(endNodesIn,idx);
//      ((_,nodeCosts,_)) = arrayGet(nodeInfoIn, endNode);
//      true = nodeCosts <. maxCosts;
//      endNodesTmp = getCriticalPathEndNodes(endNodesIn,nodeInfoIn,idx+1,maxCostNodes);
//    then
//      endNodesTmp;
//  case(_,_,_,_)
//    equation
//      true = listLength(endNodesIn) >= idx;
//      false = List.isEmpty(maxCostNodes);
//      maxEndNode = listGet(maxCostNodes,1);
//      ((_,maxCosts,_)) = arrayGet(nodeInfoIn,maxEndNode);
//      endNode = listGet(endNodesIn,idx);
//      ((_,nodeCosts,_)) = arrayGet(nodeInfoIn, endNode);
//      true = nodeCosts ==. maxCosts;
//      endNodesTmp = getCriticalPathEndNodes(endNodesIn,nodeInfoIn,idx+1,endNode::maxCostNodes);
//    then
//      endNodesTmp;
//  case(_,_,_,_)
//    equation
//      true = listLength(endNodesIn) >= idx;
//      false = List.isEmpty(maxCostNodes);
//      maxEndNode = listGet(maxCostNodes,1);
//      ((_,maxCosts,_)) = arrayGet(nodeInfoIn,maxEndNode);
//      endNode = listGet(endNodesIn,idx);
//      ((_,nodeCosts,_)) = arrayGet(nodeInfoIn, endNode);
//      true = nodeCosts >. maxCosts;
//      endNodesTmp = getCriticalPathEndNodes(endNodesIn,nodeInfoIn,idx+1,{endNode});
//    then
//      endNodesTmp;
//  case(_,_,_,_)
//    equation
//      true = listLength(endNodesIn) < idx;
//    then
//      maxCostNodes;
//  case(_,_,_,_)
//    equation
//      true = listLength(endNodesIn) >= idx;
//      true = List.isEmpty(maxCostNodes);
//      endNode = listGet(endNodesIn,idx);
//      ((_,nodeCosts,_)) = arrayGet(nodeInfoIn, endNode);
//      endNodesTmp = getCriticalPathEndNodes(endNodesIn,nodeInfoIn,idx+1,{endNode});
//    then
//      endNodesTmp;
//  end matchcontinue;  
//end getCriticalPathEndNodes;


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
        rootNode = listGet(rootsIn,rootIdx);
        childLst = listGet(childLstIn,rootIdx);
        true = List.isEmpty(childLst);
      then
        parentLstIn;
    case(_,_,_,_)
      equation
        // handle nodes that should not be analysed yet
        true = List.isEmpty(parentLstIn);
        rootNode = listGet(rootsIn,rootIdx);
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


protected function getRootParentLst2 "removes double pairs of rootNodes and childNodes
author: Waurich TUD 2013-07" 
  input Integer idx; 
  input list<Integer> rootLstIn;
  input list<Integer> parentLstIn;
  output list<Integer> rootLstOut;
  output list<Integer> parentLstOut;
algorithm
  (rootLstOut,parentLstOut) := matchcontinue(idx,rootLstIn,parentLstIn)
    local
      Integer rootValue;
      Integer parentValue;
      list<Integer> rootLstTmp;
      list<Integer> parentLstTmp;
    case(_,_,_)
      equation
        true = idx <= listLength(rootLstIn);
        rootValue = listGet(rootLstIn,idx);
        parentValue = listGet(parentLstIn,idx);
        rootLstTmp = listDelete(rootLstIn,idx-1);
        parentLstTmp = listDelete(parentLstIn,idx-1);
      then
        (rootLstTmp,parentLstTmp);
  end matchcontinue;
end getRootParentLst2;


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
        primalChild = listGet(primalChildLst,1);
        ((_,costs)) = arrayGet(exeCosts,primalChild);
        print("getCostsForNode failed!- implement cost computation for contracted rootNodes");
      then
        fail();    
    case(_,_,_,_,_)
      equation
        // the childNode is not contracted
        primalChildLst = arrayGet(inComps,childNode);
        primalParentLst = arrayGet(inComps,parentNode);
        true = listLength(primalChildLst) == 1;
        primalChild = listGet(primalChildLst,1);
        primalParent = listGet(primalParentLst,1);
        ((_,costs)) = arrayGet(exeCosts,primalChild);
        (_,commCost) = getCommunicationCost(primalParent ,primalChild ,commCosts);
        costs = costs +. intReal(commCost);
      then
        costs;
    case(_,_,_,_,_)
      equation
        // the childNode is contracted
        primalChildLst = arrayGet(inComps,childNode);
        primalParentLst = arrayGet(inComps,parentNode);
        true = listLength(primalChildLst) > 1;
        print("getCostsForNode failed! - implement cost computation for contracted childNode");
      then
        fail();
    else
      equation
        print("getCostsForNode failed! \n");
      then
        fail();
  end matchcontinue;
end getCostsForNode;


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


protected function tupleToStringRealInt "author: marcusw
  Returns the given tuple as string." 
  input tuple<Integer,Real> inTuple;
  output String result;
  
algorithm
  result := match(inTuple)
    local
      Integer int1;
      Real real1;
    case((int1,real1))
    then ("(" +& intString(int1) +& "," +& realString(real1) +& ")");
  end match;
end tupleToStringRealInt;


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
    else then iCommCosts;
  end matchcontinue;
end transposeCommCosts1;

public function getRootNodes "function getRootNodes
  author: marcusw
  Get all root nodes of the graph."
  input TaskGraph iTaskGraphT; //The transposed graph
  output list<Integer> rootsOut;
algorithm
  ((rootsOut,_)) := Util.arrayFold(iTaskGraphT, getRootNodes0, ({},1));
end getRootNodes;
 
protected function getRootNodes0 "function getRootNodes0
  author: marcusw
  Helper function of getRootNodes to handle one entry of the adjacence-list-array."
  input list<Integer> iChildren;
  input tuple<list<Integer>,Integer> iRoots; //<rootNodes, nodeIdx>
  output tuple<list<Integer>,Integer> oRoots;
protected
  list<Integer> tmpRoots;
  Integer nodeIdx;
algorithm
  oRoots := match(iChildren,iRoots)
    case({},(tmpRoots,nodeIdx))
      equation
        tmpRoots = nodeIdx::tmpRoots;
      then ((tmpRoots,nodeIdx+1));
    case(_,(tmpRoots,nodeIdx)) then ((tmpRoots,nodeIdx+1));
  end match;
end getRootNodes0;
    
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
        true = intGt(listLength(filteredCommCosts), 0);
        highestCommCost = getHighestCommCost(filteredCommCosts, (-1,-1,-1));
      then SOME(highestCommCost);
    else then NONE();
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
    else then iHighestTuple;
  end matchcontinue;
end getHighestCommCost;

// public function arrangeGraphInLevels "
// author: Waurich TUD 2013-07"
//   input TaskGraph graphIn;
//   input TaskGraphMeta graphDataIn;
// protected
//   list<list<Integer>> parallelSets;
//   array<tuple<Integer,Integer>> nodeCoords;
//   array<list<Integer>> inComps;
//   array<Integer> varSccMapping;
//   array<Integer> eqSccMapping;
//   list<Integer> rootNodes;
//   array<String> nodeNames;
//   array<String> nodeDescs;
//   array<tuple<Integer,Real>> exeCosts;
//   array<list<tuple<Integer,Integer,Integer>>> commCosts;
//   array<Integer>nodeMark;
//   TaskGraphMeta graphData;
// algorithm
//   parallelSets := getParallelSets(graphIn,graphDataIn);
//   print("parallelSets "+&stringDelimitList(List.map(parallelSets,intLstString)," ; ")+&"\n");
//   nodeCoords := getNodeCoords(parallelSets,graphIn);
//   TASKGRAPHMETA(inComps = inComps, varSccMapping=varSccMapping, eqSccMapping=eqSccMapping, rootNodes = rootNodes, nodeNames =nodeNames, nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) := graphDataIn;
//   nodeMark := List.fold2(List.intRange(arrayLength(graphIn)),setLevelInNodeMark,inComps,nodeCoords,nodeMark);
//   graphData := TASKGRAPHMETA(inComps,varSccMapping,eqSccMapping,rootNodes,nodeNames,nodeDescs,exeCosts,commCosts,nodeMark);
// end arrangeGraphInLevels;


// protected function getParallelSets  " scatters the nodes of the taskGraph into sets of nodes that can be computed in parallel.
// author:Waurich TUD 2013-07"
//   input TaskGraph graphIn;
//   input TaskGraphMeta graphDataIn;
//   output list<list<Integer>> parallelSetsOut;
// protected 
//   list<Integer> rootNodes;
//   list<Integer> allChildren;
// algorithm
//   TASKGRAPHMETA(rootNodes = rootNodes) := graphDataIn;
//   allChildren := List.flatten(arrayList(graphIn));
//   //print("allChildren "+&stringDelimitList(List.map(List.sort(allChildren,intGt),intString),",")+&"\n");
//   rootNodes := List.fold1(List.intRange(arrayLength(graphIn)),getRootNodes,allChildren,{});
//   //print("rootNodes "+&stringDelimitList(List.map(rootNodes,intString),",")+&"\n");
//   parallelSetsOut := getParallelSets1(graphIn,rootNodes,{rootNodes});
//   print("the number of parallel sets "+&intString(listLength(parallelSetsOut))+&" and the number of components "+&intString(arrayLength(graphIn))+&"\n");
// end getParallelSets;
// 
// 
// protected function getParallelSets1  " implementation of getParallelSets
// author:Waurich TUD 2013-07"
//   input TaskGraph graphIn;
//   input list<Integer> rootNodes;
//   input list<list<Integer>> parallelSetsIn;
//   output list<list<Integer>> parallelSetsOut;
// algorithm
//   parallelSetsOut := matchcontinue(graphIn,rootNodes,parallelSetsIn)
//     local
//       list<list<Integer>> parallelSetsTmp;
//       list<list<Integer>> rootChildren;
//       list<Integer> parallelSet;
//     case(_,_,_)
//       equation
//         true = listLength(List.flatten(parallelSetsIn)) < arrayLength(graphIn);
//         rootChildren = List.map1(rootNodes, Util.arrayGetIndexFirst, graphIn);
//         //print("the rootchilds: "+&stringDelimitList(List.map(List.flatten(rootChildren),intString),",")+&"\n");
//         rootChildren = List.map2(rootChildren,getAllChildNodes,List.flatten(parallelSetsIn),graphIn);
//         parallelSet = List.flatten(rootChildren);
//         parallelSet = List.unique(parallelSet);
//         //print("the next parallel set: "+&stringDelimitList(List.map(parallelSet,intString),",")+&"\n");
//         //true = listLength(parallelSet) == listLength(rootChildren);
//         parallelSetsTmp = cons(parallelSet,parallelSetsIn);
//         //print("the current parallel set: "+&stringDelimitList(List.map(List.flatten(parallelSetsTmp),intString),",")+&"\n");
//         parallelSetsTmp = getParallelSets1(graphIn,parallelSet,parallelSetsTmp);
//       then
//         parallelSetsTmp;
//     case(_,_,_)
//       equation
//          true = listLength(List.flatten(parallelSetsIn)) >= arrayLength(graphIn);
//          then
//            parallelSetsIn;
//     else
//       equation
//         print("getParallelSets1 failed \n");
//       then
//         fail();
//   end matchcontinue;        
// end getParallelSets1;
// 
// 
// protected function getAllChildNodes " map function to remove all nodes from a list that have predecessors.
// author: Waurich TUD 2013-07"
//   input list<Integer> childNodesIn;
//   input list<Integer> collectedNodes;
//   input TaskGraph graphIn;
//   output list<Integer> childNodesOut;
// protected
//   list<Integer> childNodesTmp;
// algorithm
//   //print("check childNodesIn "+&stringDelimitList(List.map(childNodesIn,intString),",")+&"\n");
//   childNodesTmp := List.map2(childNodesIn,isOrphan,collectedNodes,graphIn);
//   //print("check childNodesTmp1 "+&stringDelimitList(List.map(childNodesTmp,intString),",")+&"\n");
//   childNodesTmp := List.removeOnTrue(-1,intEq,childNodesTmp);
//   //print("check childNodesTmp2 "+&stringDelimitList(List.map(childNodesIn,intString),",")+&"\n");
//   childNodesOut := childNodesTmp;
// end getAllChildNodes;
// 
// 
// protected function isOrphan "checks if the childNode has no parentNodes. if not -1 is output otherwise the node is output.
// author: Waurich TUD 2013-07"
//   input Integer childNodeIn;
//   input list<Integer> collectedNodes;
//   input TaskGraph graphIn;
//   output Integer childNodeOut;
// algorithm
//   childNodeOut := matchcontinue(childNodeIn,collectedNodes,graphIn)
//     local
//       list<Integer> parents;
//   case(_,_,_)
//     equation
//       parents = getParentNodes(childNodeIn,graphIn);
//       //print("for "+&intString(childNodeIn)+&" the parents "+&stringDelimitList(List.map(parents,intString),",")+&"\n");
//       //print("collected Nodes "+&stringDelimitList(List.map(collectedNodes,intString),",")+&"\n");
//       (_,parents,_) = List.intersection1OnTrue(parents,childNodeIn::collectedNodes,intEq);
//       true = listLength(parents) == 0;
//     then
//       childNodeIn;
//   else
//     then
//       -1;
//   end matchcontinue;
// end isOrphan;
//      
// 
end HpcOmTaskGraph;
