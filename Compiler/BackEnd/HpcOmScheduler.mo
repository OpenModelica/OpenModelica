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
encapsulated package HpcOmScheduler
" file:        HpcOmScheduler.mo
  package:     HpcOmScheduler
  description: HpcOmScheduler contains the logic to create a schedule for a taskgraph.

  RCS: $Id: HpcOmScheduler.mo 15486 2013-08-07 12:46:00Z marcusw $
"

public import HpcOmTaskGraph;

protected import List;

public uniontype Schedule   // stores all scheduling-informations
  record SCHEDULE
    list<Integer> locks; //List of locks required for correct calculation
    array<list<Integer>> threadTasks; //List of tasks assigned to the thread <%idx%>
    array<list<Integer>> locksPre; //List of locks which must be set before execution
    array<list<Integer>> locksPost; //List of locks which should be unset after execution
  end SCHEDULE;
end Schedule;

protected uniontype GraphNode
  record GRAPHNODE
    Integer weighting;
    Integer index;
    Real timeFinished;
  end GRAPHNODE;
end GraphNode;

public function createListSchedule
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer iNumberOfThreads;
  output Schedule oSchedule;
protected
  HpcOmTaskGraph.TaskGraph taskGraphT;
  list<GraphNode> nodeList; //list of nodes which are ready to schedule
  list<Integer> rootNodes;
  array<Real> threadReadyTimes;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(rootNodes=rootNodes) := iTaskGraphMeta;
  taskGraphT := HpcOmTaskGraph.transposeTaskGraph(iTaskGraph);
  nodeList := List.map2(rootNodes, convertNodeToGraphNode, iTaskGraphMeta, 0.0);
  nodeList := List.sort(nodeList, compareGraphNodes);
  threadReadyTimes := arrayCreate(iNumberOfThreads,0.0);
  oSchedule := createListSchedule1(nodeList,threadReadyTimes);
end createListSchedule;

protected function createListSchedule1
  input list<GraphNode> nodeList;
  input array<Real> threadReadyTimes; //the time until the thread is ready to handle a new task
  output Schedule oSchedule;
protected
  GraphNode head;
  list<GraphNode> rest;
algorithm
  oSchedule := matchcontinue(nodeList,threadReadyTimes)
    case(head::rest,_) then fail();
    else then fail();
  end matchcontinue;
end createListSchedule1;

protected function convertNodeToGraphNode
  input Integer iNodeIdx;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta; 
  input Real iTimeOffset; 
  output GraphNode oNode;
protected
  Integer weighting, nodeMark, primalComp;
  array<Integer> nodeMarks;
  array<list<Integer>> inComps;
  list<Integer> components;
  array<tuple<Integer,Real>> exeCosts;
  Real exeCost, weighting;
algorithm
  iTaskGraphMeta := matchcontinue(iNodeIdx, iTaskGraphMeta,iTimeOffset)
    case(_,HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps, exeCosts=exeCosts, nodeMark=nodeMarks),_)
      equation
        components = arrayGet(inComps,iNodeIdx);
        primalComp = listGet(components,1);
        nodeMark = arrayGet(nodeMarks,primalComp);
        ((_,exeCost)) = arrayGet(exeCosts,iNodeIdx);
        weighting = realAdd(iTimeOffset,exeCost);
      then GRAPHNODE(nodeMark,iNodeIdx,weighting);
    else
      equation
        print("convertNodeToGraphNode failed.\n");
      then fail();
  end matchcontinue;
end convertNodeToGraphNode;

protected function compareGraphNodes
  input GraphNode iGraphNode1;
  input GraphNode iGraphNode2;
  output Boolean oResult;
protected
  Integer weightingNode1,weightingNode2;
algorithm
  GRAPHNODE(weighting=weightingNode1) := iGraphNode1;
  GRAPHNODE(weighting=weightingNode2) := iGraphNode2;
  oResult := intGt(weightingNode1,weightingNode2);
end compareGraphNodes;
end HpcOmScheduler;