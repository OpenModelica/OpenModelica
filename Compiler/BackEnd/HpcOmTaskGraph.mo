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

protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import Debug;
protected import ExpressionDump;
protected import GraphML;
protected import HpcOmBenchmark;
protected import List;
protected import Util;


//type definition
//------------------------------------------
//------------------------------------------

public uniontype Equation //TODO: remove
  record EQUATION
    String text;
    Integer eqIdx;
  end EQUATION;
end Equation;

public uniontype StrongConnectedComponent //TODO: remove
  record STRONGCONNECTEDCOMPONENT 
    String text;
    Integer compIdx;
    Integer calcTime;
    list<Integer> equations;
    list<tuple<Integer,Integer>> dependencySCCs; //The tuple holds the following values: <SccIdx,NumberOfDepVars>
    String description;
  end STRONGCONNECTEDCOMPONENT;
end StrongConnectedComponent;

public uniontype Variable //TODO: remove
  record VARIABLE
    String text;
    Integer varIdx;
    Integer state;
  end VARIABLE;
end Variable;

public uniontype Graph //TODO: remove
  record GRAPH
    String name;
    list<StrongConnectedComponent> components;
    list<Variable> variables;
  end GRAPH;
end Graph;


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
    array<Integer> exeCosts;  // the execution cost for the nodes
    array<list<tuple<Integer,Integer>>> commCosts;  // the communication cost tuple(_,cost) for an edge from array[parentNode] to tuple(childNode,_) 
    array<Integer> nodeMark;  // put some additional stuff in here
  end TASKGRAPHMETA;
end TaskGraphMeta;  
  
  
//functions to build the task graph from the BLT structure
//------------------------------------------
//------------------------------------------
  
public function createTaskGraph "function createTaskGraph
  author: marcusw,waurich
  Creates a task graph on blt-level and stores it as a graphml-file."
  input BackendDAE.BackendDAE inDAE;
  input String filenamePrefix;
  output TaskGraph graphOut;
  output TaskGraphMeta graphDataOut;
protected
  list<BackendDAE.EqSystem> systs;
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
  //dumpAsGraphMLSccLevel(graph,graphData,fileName);
  graphOut := graph;
  graphDataOut := graphData; 
end createTaskGraph;


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
  array<Integer> exeCosts;  
  array<list<tuple<Integer,Integer>>> commCosts; 
  array<Integer> nodeMark;
algorithm
  graph := arrayCreate(numComps,{});
  inComps := arrayCreate(numComps,{});  
  varSccMapping := arrayCreate(1,0);   
  eqSccMapping := arrayCreate(1,0);   
  rootNodes := {}; 
  nodeNames := arrayCreate(numComps,"");
  nodeDescs :=  arrayCreate(numComps,""); 
  exeCosts := arrayCreate(numComps,-1); 
  commCosts :=  arrayCreate(numComps,{(-1,-1)});
  nodeMark := arrayCreate(numComps,-1); 
  graphData := TASKGRAPHMETA(inComps,varSccMapping,eqSccMapping,rootNodes,nodeNames,nodeDescs,exeCosts,commCosts,nodeMark);
end getEmptyTaskGraph;


protected function createTaskGraph0 "function createTaskGraph0
  author: marcusw,waurich
  Creates a task graph out of the given system and stores it as a graphml-file."
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
      Graph graph;
      Graph graphOde;
      BackendDAE.IncidenceMatrix incidenceMatrix;
      DAE.FunctionTree sharedFuncs;
      TaskGraph graphIn;
      TaskGraph graphTmp;
      TaskGraphMeta graphDataIn;
      TaskGraphMeta graphDataTmp;
      array<list<tuple<Integer,Integer>>> commCosts; 
      array<list<Integer>> adjLst;
      array<list<Integer>> adjLstOde;
      array<list<Integer>> inComps;
      array<Integer> ass1;
      array<Integer> ass2;
      array<Integer> eqSccMapping;
      array<Integer> exeCosts;
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
        (varSccMapping,eqSccMapping) = createVarSccMapping(comps, numberOfVars, numberOfEqs); 
        nodeDescs = getEquationStrings(comps,isyst);  //gets the description i.e. the whole equation, for every component
        ((graphTmp,inComps,exeCosts,nodeNames,rootNodes,_)) = List.fold2(comps,createTaskGraph1,(incidenceMatrix,isyst,shared,listLength(comps)),(varSccMapping,{}),(graphTmp,inComps,exeCosts,nodeNames,rootNodes,1));
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
        (varSccMapping,eqSccMapping) = createVarSccMapping(comps, numberOfVars, numberOfEqs); 
        nodeDescs = getEquationStrings(comps,isyst);  //gets the description i.e. the whole equation, for every component
        ((graphTmp,inComps,exeCosts,nodeNames,rootNodes,_)) = List.fold2(comps,createTaskGraph1,(incidenceMatrix,isyst,shared,listLength(comps)),(varSccMapping,{}),(graphTmp,inComps,exeCosts,nodeNames,rootNodes,1));
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
  array<list<tuple<Integer,Integer>>> commCosts1, commCosts2; 
  array<list<Integer>> inComps1, inComps2;
  array<Integer> eqSccMapping1, eqSccMapping2;
  array<Integer> exeCosts1, exeCosts2;
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
  commCosts2 := Util.arrayAppend(commCosts1,commCosts2);  //TODO: update commCosts2 for the new variable indices
  nodeMark2 := Util.arrayAppend(nodeMark1,nodeMark2);
  graphDataOut := TASKGRAPHMETA(inComps2,varSccMapping2,eqSccMapping2,rootNodes2,nodeNames2,nodeDescs2,exeCosts2,commCosts2,nodeMark2);  
end taskGraphAppend;


protected function updateTaskGraphSystem "map function to add the indices in the taskGraph system the number of vars of the previous system.
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
  input tuple<array<Integer>,list<Integer>> varInfo;
  input tuple<TaskGraph,array<list<Integer>>,array<Integer>,array<String>,list<Integer>,Integer> graphInfoIn;
  output tuple<TaskGraph,array<list<Integer>>,array<Integer>,array<String>,list<Integer>,Integer> graphInfoOut;
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
  array<Integer> exeCosts; 
  array<list<tuple<Integer,Integer>>> commCosts;
  array<Integer> nodeMark;
  list<tuple<Integer,Integer>> unsolvedVars; 
  list<Integer> eventVarLst;
  array<Integer> requiredSccs;
  Integer componentIndex, numberOfComps, calculationTime;
  list<tuple<Integer,Integer>> requiredSccs_RefCount;
  String nodeName;
algorithm
  (incidenceMatrix,isyst,ishared,numberOfComps) := isystInfo;
  (varSccMapping,eventVarLst) := varInfo;
  (graphIn,inComps,exeCosts,nodeNames,rootNodes,componentIndex) := graphInfoIn;
  inComps := arrayUpdate(inComps,componentIndex,{componentIndex});
  nodeName := BackendDump.strongComponentString(component);
  nodeNames := arrayUpdate(nodeNames,componentIndex,nodeName);
  calculationTime := HpcOmBenchmark.timeForCalculation(component, isyst, ishared);
  exeCosts := arrayUpdate(exeCosts,componentIndex,calculationTime);
  unsolvedVars := getUnsolvedVarsBySCC(component,incidenceMatrix,eventVarLst);
  requiredSccs := arrayCreate(numberOfComps,0); //create a ref-counter for each component
  requiredSccs := List.fold1(unsolvedVars,fillSccList,varSccMapping,requiredSccs); 
  ((_,requiredSccs_RefCount)) := Util.arrayFold(requiredSccs, convertRefArrayToList, (1,{}));
  (graphTmp,rootNodes) := fillAdjacencyList(graphIn,rootNodes,componentIndex,requiredSccs_RefCount,1);
  graphTmp := Util.arrayMap1(graphTmp,List.sort,intGt);
  graphInfoOut := (graphTmp,inComps,exeCosts,nodeNames,rootNodes,componentIndex+1);
end createTaskGraph1;   


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
      var = listGet(varLst,arrayGet(ass2,i));
      varString = getVarString(var);
      desc = ("ARRAY:"+&eqString +& " FOR " +& varString);
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
      var = listGet(varLst,arrayGet(ass2,i));
      varString = getVarString(var);
      desc = ("ALGO:"+&eqString +& " FOR " +& varString);
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
      var = listGet(varLst,arrayGet(ass2,i));
      varString = getVarString(var);
      desc = ("COMPLEX:"+&eqString +& " FOR " +& varString);
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
      var = listGet(varLst,arrayGet(ass2,i));
      varString = getVarString(var);
      desc = ("WHEN:"+&eqString +& " FOR " +& varString);
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
      var = listGet(varLst,arrayGet(ass2,i));
      varString = getVarString(var);
      desc = ("IFEQ:"+&eqString +& " FOR " +& varString);
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


protected function createVarSccMapping "function createVarSccMapping
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
  _ := List.fold2(components, createVarSccMapping0, varSccMapping, eqSccMapping, 1);
  //print("Variables in SCCs " +& stringDelimitList(List.map(arrayList(varSccMapping),intString),"  ;  ")+&"\n");
  oVarSccMapping := varSccMapping;
  oEqSccMapping := eqSccMapping;
  
end createVarSccMapping;


protected function createVarSccMapping0 "function createVarSccMapping
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
        //print("Var from eqSystem " +& stringDelimitList(List.map(compVarIdc,intString),",") +& " solved in scc " +& BackendDump.strongComponentString(component) +& "\n");
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
        tmpEqSccMapping = List.fold1(eqns,updateMapping,iSccIdx,eqSccMapping);
      then 
        iSccIdx+1;
    case(BackendDAE.MIXEDEQUATIONSYSTEM(condSystem = condSys, disc_vars = compVarIdc, disc_eqns = eqns),_,_,_)
      equation
        //print("discrete var from MixedeqSystem " +& stringDelimitList(List.map(compVarIdc,intString),",") +& " solved in scc " +& BackendDump.strongComponentString(component) +& "\n");
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
        tmpEqSccMapping = List.fold1(eqns,updateMapping,iSccIdx,eqSccMapping);
        //gets the whole equationsystem (necessary for the adjacencyList)
        _ = List.fold2({condSys}, createVarSccMapping0, tmpVarSccMapping,tmpEqSccMapping, iSccIdx);
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
        //print("complex component "+&intString(iSccIdx)+&"solves the vars "+&stringDelimitList(List.map(compVarIdc,intString),",")+&"\n");
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
        //print("Var from ifEq" +& stringDelimitList(List.map(compVarIdc,intString),",") +& " solved in scc " +& BackendDump.strongComponentString(component) +& "\n");
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
        tmpEqSccMapping = arrayUpdate(eqSccMapping,eq,iSccIdx);
        then 
          iSccIdx+1;
    else
      equation
        print("createVarSccMapping0 - Unsupported component-type.");
      then fail();
  end matchcontinue;
end createVarSccMapping0;


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
  (graphOdeOut,cutNodes) := cutTaskGraph(graphIn,stateNodes,whenNodes,{});
  graphDataOdeOut := getOdeSystemData(graphDataIn,listAppend(cutNodes,whenNodes));
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
      stateNodes = List.map2(stateNodes,getCompInComps,1,inComps);
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


protected function getCompInComps "finds the node which consists that component.
author: Waurich TUD 2013-07"
  input Integer compIn;
  input Integer compIdx;
  input array<list<Integer>> inComps;
  output Integer compOut;
algorithm
  compOut := matchcontinue(compIn,compIdx,inComps)
    local
      list<Integer> mergedComp;
      Integer compTmp;
    case(_,_,_)
      equation
        true = arrayLength(inComps) >= compIdx;
        mergedComp = arrayGet(inComps,compIdx);
        false = List.isMemberOnTrue(compIn,mergedComp,intEq);
        compTmp = getCompInComps(compIn,compIdx+1,inComps);
      then
        compTmp;
    case(_,_,_)
      equation
        true = arrayLength(inComps) >= compIdx;
        mergedComp = arrayGet(inComps,compIdx);
        true = List.isMemberOnTrue(compIdx,mergedComp,intEq);
      then
        compIdx;
    else
      equation
        print("getCompInComps failed!\n");
      then
        fail();
  end matchcontinue;             
end getCompInComps;


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
    case(_,_,_,_)
      equation
        // remove the algebraic branches
        noChildren = getBranchEnds(graphIn,{},1);
        //print("free branches"+&stringDelimitList(List.map(noChildren,intString),",")+&"\n");
        (_,cutNodes,_) = List.intersection1OnTrue(noChildren,listAppend(stateNodes,deleteNodes),intEq);
        deleteNodesTmp = listAppend(cutNodes,deleteNodes);
        //print("cutNodes "+&stringDelimitList(List.map(cutNodes,intString),",")+&"\n");
        false = List.isEmpty(cutNodes);
        graphTmp = removeEntries(graphIn,cutNodes);
        (graphTmp,deleteNodesTmp) = cutTaskGraph(graphTmp,stateNodes,eventNodes,deleteNodesTmp);
         then
           (graphTmp,deleteNodesTmp);
    case(_,_,_,_)
      equation       
        noChildren = getBranchEnds(graphIn,{},1);
        (_,cutNodes,_) = List.intersection1OnTrue(noChildren,listAppend(stateNodes,deleteNodes),intEq);
        true = List.isEmpty(cutNodes);
        graphTmp = removeEntries(graphIn,eventNodes);
        (graphTmp,_) = deleteRowInAdjLst(graphIn,List.unique(listAppend(deleteNodes,eventNodes)));
        //print("found the ODE graph\n");
         then
           (graphTmp,deleteNodes);
  end matchcontinue;
end cutTaskGraph;


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
  array<Integer> exeCosts;
  array<list<tuple<Integer,Integer>>> commCosts;
  array<Integer>nodeMark;
algorithm
  TASKGRAPHMETA(inComps = inComps, varSccMapping=varSccMapping, eqSccMapping=eqSccMapping, rootNodes = rootNodes, nodeNames =nodeNames, nodeDescs=nodeDescs, exeCosts = exeCosts, commCosts=commCosts, nodeMark=nodeMark) := graphDataIn;
  inComps := listArray(List.deletePositions(arrayList(inComps),List.map1(cutNodes,intSub,1)));
  varSccMapping := removeContinuousEntries(varSccMapping,cutNodes);
  eqSccMapping := removeContinuousEntries(eqSccMapping,cutNodes);
  (_,rootNodes,_) := List.intersection1OnTrue(rootNodes,cutNodes,intEq); //TODO:  by cutting out when-equations can arise new roots
  nodeNames := listArray(List.deletePositions(arrayList(nodeNames),List.map1(cutNodes,intSub,1)));
  nodeDescs := listArray(List.deletePositions(arrayList(nodeDescs),List.map1(cutNodes,intSub,1)));
  exeCosts := listArray(List.deletePositions(arrayList(exeCosts),List.map1(cutNodes,intSub,1)));
  commCosts := listArray(List.deletePositions(arrayList(commCosts),List.map1(cutNodes,intSub,1)));
  commCosts := commCosts;  //delete Entries in rows;
  nodeMark := listArray(List.deletePositions(arrayList(nodeMark),List.map1(cutNodes,intSub,1)));
  graphDataOut :=TASKGRAPHMETA(inComps,varSccMapping,eqSccMapping,rootNodes,nodeNames,nodeDescs,exeCosts,commCosts,nodeMark);
end getOdeSystemData; 


protected function removeContinuousEntries " removes entries in an array and updates the rest.
the entries in the array belong to a continuous series. (all numbers from 1 to max(array) belong to the array).
the deleteEntries are removed from the array and the indices are adapted so that the new array consists againn of continuous series of numbers.
e.g. removeContinuousEntries([4,6,2,3,1,7,5],{3,6}) = [3,2,1,5,4]; 
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
  deleteEntries := List.sort(deleteEntriesIn,intGt);
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
      entry = List.getMemberOnTrue(entryIn,deleteEntriesIn,intGt);
      offset = List.position(entry,deleteEntriesIn)+1;
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
      

protected function removeEntries "deletes given entries from adjacencyLst.
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
      ArrayTmp = removeEntries(ArrayTmp,rest);
    then
      ArrayTmp;
  end matchcontinue;
end removeEntries;


protected function removeEntryFromArray " removes a singel entry from an array<list<Integer>>. starts with indexed row.
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




// print and dump functions
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
  array<Integer> exeCosts; 
  array<list<tuple<Integer,Integer>>> commCosts;
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
  input array<Integer> exeCosts;
  input Integer compIdx;
algorithm
  _ := matchcontinue(exeCosts,compIdx)
  local
    Integer exeCost;
  case(_,_)
    equation
      true = arrayLength(exeCosts)>= compIdx;
      exeCost = arrayGet(exeCosts,compIdx);
      print("component "+&intString(compIdx)+&" has an execution cost of : "+&intString(exeCost)+&"\n");
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
  input array<list<tuple<Integer,Integer>>> commCosts;
  input Integer compIdx;
algorithm
  _ := matchcontinue(commCosts,compIdx)
  local
    list<tuple<Integer,Integer>> compRow;
  case(_,_)
    equation
      true = arrayLength(commCosts)>= compIdx;
      compRow = arrayGet(commCosts,compIdx);
      print("edges from component "+&intString(compIdx)+&" with the communication costs "+&stringDelimitList(List.map(compRow,tupleToString),", ")+&"\n");
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
        //varSCCMapping = createVarSccMapping(comps, numberOfVars);
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


end HpcOmTaskGraph;
