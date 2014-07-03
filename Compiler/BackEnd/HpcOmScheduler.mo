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
encapsulated package HpcOmScheduler
" file:        HpcOmScheduler.mo
  package:     HpcOmScheduler
  description: HpcOmScheduler contains the logic to create a schedule for a taskgraph.

  RCS: $Id: HpcOmScheduler.mo 15486 2013-08-07 12:46:00Z marcusw $
"

public import BackendDAE;
public import HpcOmTaskGraph;
public import HpcOmSimCode;
public import SimCode;

protected import Absyn;
protected import BackendDAEUtil;
protected import BackendVarTransform;
protected import ComponentReference;
protected import DAE;
protected import Debug;
protected import Expression;
protected import Flags;
protected import HpcOmSchedulerExt;
protected import HpcOmSimCodeMain;
protected import List;
protected import SimCodeUtil;
protected import System;
protected import Util;

public type TaskAssignment = array<Integer>; //the information which node <idx> is assigned to which processor <value>

//--------------
// No Scheduling
//--------------
public function createEmptySchedule "function createListSchedule
  author: marcusw
  Create a empty-schedule to produce the serial code."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  output HpcOmSimCode.Schedule oSchedule;
algorithm
  oSchedule := HpcOmSimCode.EMPTYSCHEDULE();
end createEmptySchedule;

//----------------
// List Scheduling
//----------------
public function createListSchedule "function createListSchedule
  author: marcusw
  Create a list-schedule out of the given informations."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer iNumberOfThreads;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  output HpcOmSimCode.Schedule oSchedule;
protected
  HpcOmTaskGraph.TaskGraph taskGraphT;
  list<tuple<HpcOmSimCode.Task,Integer>> nodeList_refCount; //list of nodes which are ready to schedule
  list<HpcOmSimCode.Task> nodeList;
  list<Integer> rootNodes;
  array<Real> threadReadyTimes;
  array<tuple<HpcOmSimCode.Task,Integer>> allTasks;
  array<list<HpcOmSimCode.Task>> threadTasks;
  array<list<tuple<Integer, Integer, Integer>>> commCosts;
  HpcOmSimCode.Schedule tmpSchedule;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(commCosts=commCosts) := iTaskGraphMeta;
  taskGraphT := HpcOmTaskGraph.transposeTaskGraph(iTaskGraph);
  rootNodes := HpcOmTaskGraph.getRootNodes(iTaskGraph);
  allTasks := convertTaskGraphToTasks(taskGraphT,iTaskGraphMeta,convertNodeToTask);
  nodeList_refCount := List.map1(rootNodes, getTaskByIndex, allTasks);
  nodeList := List.map(nodeList_refCount, Util.tuple21);
  nodeList := List.sort(nodeList, compareTasksByWeighting);
  threadReadyTimes := arrayCreate(iNumberOfThreads,0.0);
  threadTasks := arrayCreate(iNumberOfThreads,{});
  tmpSchedule := HpcOmSimCode.THREADSCHEDULE(threadTasks,{});
  (tmpSchedule,_) := createListSchedule1(nodeList,threadReadyTimes, iTaskGraph, taskGraphT, allTasks, commCosts, iSccSimEqMapping, getLocksByPredecessorList, tmpSchedule);
  tmpSchedule := addSuccessorLocksToSchedule(iTaskGraph,allTasks,addReleaseLocksToSchedule,tmpSchedule);
  //() := printSchedule(tmpSchedule);
  oSchedule := tmpSchedule;
end createListSchedule;

protected function createListSchedule1 "function createListSchedule1
  author: marcusw
  Create a list schedule, starting with the given nodeList and ready times. This method will add calcTasks and assignLockTasks, but no releaseLockTasks!"
  input list<HpcOmSimCode.Task> iNodeList; //the sorted nodes -> this method will pick the first task
  input array<Real> iThreadReadyTimes; //the time until the thread is ready to handle a new task
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllTasks; //all tasks with ref-counter
  input array<list<tuple<Integer, Integer, Integer>>> iCommCosts;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input FuncType iLockWithPredecessorHandler; //Function which handles locks to all predecessors
  input HpcOmSimCode.Schedule iSchedule;
  output HpcOmSimCode.Schedule oSchedule;
  output array<Real> oThreadReadyTimes;

  partial function FuncType
    input Integer iNodeIdx;
    input Integer iThreadIdx;
    input list<tuple<HpcOmSimCode.Task,Integer>> iPredecessors;
    output list<HpcOmSimCode.Task> oTasks; //lock tasks
    output list<String> oLockNames; //lock names
  end FuncType;
protected
  HpcOmSimCode.Task head, newTask;
  Integer newTaskRefCount;
  list<HpcOmSimCode.Task> rest;
  Real lastChildFinishTime; //The time when the last child has finished calculation
  HpcOmSimCode.Task lastChild;
  list<tuple<HpcOmSimCode.Task,Integer>> predecessors, successors;
  list<Integer> successorIdc;
  list<String> lockIdc, newLockIdc;
  array<Real> threadFinishTimes;
  Integer firstEq;
  array<list<HpcOmSimCode.Task>> allThreadTasks;
  list<HpcOmSimCode.Task> threadTasks, lockTasks;
  Integer threadId;
  Real threadFinishTime;
  array<Real> tmpThreadReadyTimes;
  list<HpcOmSimCode.Task> tmpNodeList;
  Integer weighting;
  Integer index;
  Real calcTime;
  list<Integer> eqIdc, simEqIdc;
  array<tuple<HpcOmSimCode.Task,Integer>> tmpAllTasks;
  HpcOmSimCode.Schedule tmpSchedule;
algorithm
  (oSchedule,oThreadReadyTimes) := matchcontinue(iNodeList,iThreadReadyTimes, iTaskGraph, iTaskGraphT, iAllTasks, iCommCosts, iSccSimEqMapping, iLockWithPredecessorHandler, iSchedule)
    case((head as HpcOmSimCode.CALCTASK(weighting=weighting,index=index,calcTime=calcTime,eqIdc=(eqIdc as firstEq::_)))::rest,_,_,_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE(threadTasks=allThreadTasks, lockIdc=lockIdc))
      equation
        //get all predecessors (childs)
        (predecessors, _) = getSuccessorsByTask(head, iTaskGraphT, iAllTasks);
        (successors, successorIdc) = getSuccessorsByTask(head, iTaskGraph, iAllTasks);
        true = List.isNotEmpty(predecessors); //in this case the node has predecessors
        //print("Handle task " +& intString(index) +& " with " +& intString(listLength(predecessors)) +& " child nodes and " +& intString(listLength(successorIdc)) +& " parent nodes.\n");

        //get last child finished time
        lastChild = getTaskWithHighestFinishTime(predecessors, NONE());
        HpcOmSimCode.CALCTASK(timeFinished=lastChildFinishTime) = lastChild;
        //find the best thread for scheduling
        threadFinishTimes = calculateFinishTimes(lastChildFinishTime, head, predecessors, iCommCosts, iThreadReadyTimes);
        ((threadId, threadFinishTime)) = getThreadFinishTimesMin(1,threadFinishTimes,-1,0.0);
        tmpThreadReadyTimes = arrayUpdate(iThreadReadyTimes, threadId, threadFinishTime);
        threadTasks = arrayGet(allThreadTasks,threadId);
        //find all predecessors which are scheduled to another thread and thus require a lock

        (lockTasks,newLockIdc) = iLockWithPredecessorHandler(index,threadId,predecessors);
        lockIdc = listAppend(lockIdc,newLockIdc);
        //threadTasks = listAppend(List.map(newLockIdc,convertLockIdToAssignTask), threadTasks);
        threadTasks = listAppend(lockTasks, threadTasks);

        //print("Eq idc: " +& stringDelimitList(List.map(eqIdc, intString), ",") +& "\n");
        simEqIdc = List.map(List.map1(eqIdc,getSimEqSysIdxForComp,iSccSimEqMapping), List.last);
        //print("Simcodeeq idc: " +& stringDelimitList(List.map(simEqIdc, intString), ",") +& "\n");
        //simEqIdc has the wrong order -> reverse list
        simEqIdc = listReverse(simEqIdc);
        newTask = HpcOmSimCode.CALCTASK(weighting,index,calcTime,threadFinishTime,threadId,simEqIdc);
        threadTasks = newTask::threadTasks;
        allThreadTasks = arrayUpdate(allThreadTasks,threadId,threadTasks);
        //print("Successors: " +& stringDelimitList(List.map(successorIdc, intString), ",") +& "\n");
        //add all successors with refcounter = 1
        (tmpAllTasks,tmpNodeList) = updateRefCounterBySuccessorIdc(iAllTasks,successorIdc,{});
        tmpNodeList = listAppend(tmpNodeList, rest);
        tmpNodeList = List.sort(tmpNodeList, compareTasksByWeighting);
        ((_,newTaskRefCount)) = arrayGet(iAllTasks,index);
        _ = arrayUpdate(iAllTasks,index,(newTask,newTaskRefCount));
        (tmpSchedule,tmpThreadReadyTimes) = createListSchedule1(tmpNodeList,tmpThreadReadyTimes,iTaskGraph, iTaskGraphT, tmpAllTasks, iCommCosts, iSccSimEqMapping, iLockWithPredecessorHandler, HpcOmSimCode.THREADSCHEDULE(allThreadTasks,lockIdc));
      then (tmpSchedule,tmpThreadReadyTimes);
    case((head as HpcOmSimCode.CALCTASK(weighting=weighting,index=index,calcTime=calcTime,eqIdc=(eqIdc as firstEq::_)))::rest,_,_,_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE(threadTasks=allThreadTasks,lockIdc=lockIdc))
      equation
        (successors, successorIdc) = getSuccessorsByTask(head, iTaskGraph, iAllTasks);
        //print("Handle task " +& intString(index) +& " with 0 child nodes and " +& intString(listLength(successorIdc)) +& " parent nodes.\n");
        //print("Parents: {" +& stringDelimitList(List.map(successorIdc, intString), ",") +& "}\n");

        //find the best thread for scheduling
        threadFinishTimes = calculateFinishTimes(0.0, head, {}, iCommCosts, iThreadReadyTimes);
        ((threadId, threadFinishTime)) = getThreadFinishTimesMin(1,threadFinishTimes,-1,0.0);
        //print("Scheduling to thread " +& intString(threadId) +& "\n");
        tmpThreadReadyTimes = arrayUpdate(iThreadReadyTimes, threadId, threadFinishTime);
        threadTasks = arrayGet(allThreadTasks,threadId);
        simEqIdc = List.flatten(List.map1(eqIdc,getSimEqSysIdxForComp,iSccSimEqMapping));
        //simEqIdc has the wrong order -> reverse list
        simEqIdc = listReverse(simEqIdc);
        newTask = HpcOmSimCode.CALCTASK(weighting,index,calcTime,threadFinishTime,threadId,simEqIdc);
        allThreadTasks = arrayUpdate(allThreadTasks,threadId,newTask::threadTasks);
        //print("Successors: " +& stringDelimitList(List.map(successorIdc, intString), ",") +& "\n");
        //add all successors with refcounter = 1
        (tmpAllTasks,tmpNodeList) = updateRefCounterBySuccessorIdc(iAllTasks,successorIdc,{});
        tmpNodeList = listAppend(tmpNodeList, rest);
        tmpNodeList = List.sort(tmpNodeList, compareTasksByWeighting);
        ((_,newTaskRefCount)) = arrayGet(iAllTasks,index);
        _ = arrayUpdate(iAllTasks,index,(newTask,newTaskRefCount));
        (tmpSchedule,tmpThreadReadyTimes) = createListSchedule1(tmpNodeList,tmpThreadReadyTimes,iTaskGraph, iTaskGraphT, tmpAllTasks, iCommCosts, iSccSimEqMapping, iLockWithPredecessorHandler, HpcOmSimCode.THREADSCHEDULE(allThreadTasks,lockIdc));
      then (tmpSchedule,tmpThreadReadyTimes);
    case({},_,_,_,_,_,_,_,_) then (iSchedule,iThreadReadyTimes);
    else
      equation
        print("HpcOmScheduler.createListSchedule1 failed\n");
      then fail();
  end matchcontinue;
end createListSchedule1;

//------------------------
// List Scheduling reverse
//------------------------
public function createListScheduleReverse "function createListScheduleReverse
  author: marcusw
  Create a list-schedule out of the given informations, starting with all leaves."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer iNumberOfThreads;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  output HpcOmSimCode.Schedule oSchedule;
protected
  HpcOmTaskGraph.TaskGraph taskGraphT;
  list<tuple<HpcOmSimCode.Task,Integer>> nodeList_refCount; //list of nodes which are ready to schedule
  list<HpcOmSimCode.Task> nodeList;
  list<Integer> leaveNodes;
  array<Real> threadReadyTimes;
  array<tuple<HpcOmSimCode.Task,Integer>> allTasks;
  array<list<HpcOmSimCode.Task>> threadTasks;
  array<list<tuple<Integer, Integer, Integer>>> commCosts, commCostsT;
  HpcOmSimCode.Schedule tmpSchedule;
  list<String> lockIdc;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(commCosts=commCosts) := iTaskGraphMeta;
  taskGraphT := HpcOmTaskGraph.transposeTaskGraph(iTaskGraph);
  //() := HpcOmTaskGraph.printTaskGraph(taskGraphT);
  commCostsT := HpcOmTaskGraph.transposeCommCosts(commCosts);
  leaveNodes := HpcOmTaskGraph.getLeafNodes(iTaskGraph);
  //print("Leave nodes: " +& stringDelimitList(List.map(leaveNodes,intString),", ") +& "\n");
  allTasks := convertTaskGraphToTasks(iTaskGraph,iTaskGraphMeta,convertNodeToTaskReverse);
  nodeList_refCount := List.map1(leaveNodes, getTaskByIndex, allTasks);
  nodeList := List.map(nodeList_refCount, Util.tuple21);
  nodeList := List.sort(nodeList, compareTasksByWeighting);
  threadReadyTimes := arrayCreate(iNumberOfThreads,0.0);
  threadTasks := arrayCreate(iNumberOfThreads,{});
  tmpSchedule := HpcOmSimCode.THREADSCHEDULE(threadTasks,{});
  (tmpSchedule,_) := createListSchedule1(nodeList,threadReadyTimes, taskGraphT, iTaskGraph, allTasks, commCostsT, iSccSimEqMapping, getLocksByPredecessorListReverse, tmpSchedule);

  tmpSchedule := addSuccessorLocksToSchedule(taskGraphT,allTasks,addAssignLocksToSchedule,tmpSchedule);
  HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,lockIdc=lockIdc) := tmpSchedule;
  threadTasks := Util.arrayMap(threadTasks, listReverse);
  tmpSchedule := HpcOmSimCode.THREADSCHEDULE(threadTasks,lockIdc);
  //() := printSchedule(tmpSchedule);
  oSchedule := tmpSchedule;
end createListScheduleReverse;

protected function addSuccessorLocksToSchedule
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllTasks;
  input FuncType iCreateLockFunction;
  input HpcOmSimCode.Schedule iSchedule;
  output HpcOmSimCode.Schedule oSchedule;

  partial function FuncType
    input tuple<HpcOmSimCode.Task,Integer> iSuccessorTask;
    input Integer iTaskIdx;
    input list<HpcOmSimCode.Task> iReleaseTasks;
    output list<HpcOmSimCode.Task> oReleaseTasks;
  end FuncType;
protected
  array<list<HpcOmSimCode.Task>> allThreadTasks;
  HpcOmSimCode.Schedule tmpSchedule;
  list<String> lockIdc;
algorithm
  oSchedule := match(iTaskGraph,iAllTasks,iCreateLockFunction,iSchedule)
    case(_,_,_,HpcOmSimCode.THREADSCHEDULE(threadTasks=allThreadTasks,lockIdc=lockIdc))
      equation
        ((allThreadTasks,_)) = Util.arrayFold3(allThreadTasks, addSuccessorLocksToSchedule0, iTaskGraph, iAllTasks, iCreateLockFunction, (allThreadTasks,1));
        tmpSchedule = HpcOmSimCode.THREADSCHEDULE(allThreadTasks,lockIdc);
    then tmpSchedule;
    else
      equation
        print("HpcOmScheduler.addReleaseLocksToSchedule failed\n");
      then fail();
  end match;
end addSuccessorLocksToSchedule;

protected function addSuccessorLocksToSchedule0
  input list<HpcOmSimCode.Task> iThreadTaskList;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllTasks;
  input FuncType iCreateLockFunction;
  input tuple<array<list<HpcOmSimCode.Task>>, Integer> iThreadTasks; //<schedulerTasks, threadId>
  output tuple<array<list<HpcOmSimCode.Task>>, Integer> oThreadTasks;

  partial function FuncType
    input tuple<HpcOmSimCode.Task,Integer> iSuccessorTask;
    input Integer iTaskIdx;
    input list<HpcOmSimCode.Task> iReleaseTasks;
    output list<HpcOmSimCode.Task> oReleaseTasks;
  end FuncType;
protected
  Integer threadId;
  array<list<HpcOmSimCode.Task>> allThreadTasks;
  list<HpcOmSimCode.Task> threadTasks;
algorithm
  (allThreadTasks,threadId) := iThreadTasks;
  threadTasks := List.fold4(iThreadTaskList, addSuccessorLocksToSchedule1, iTaskGraph, iAllTasks, threadId, iCreateLockFunction, {});
  allThreadTasks := arrayUpdate(allThreadTasks,threadId,threadTasks);
  oThreadTasks := ((allThreadTasks,threadId+1));
end addSuccessorLocksToSchedule0;

protected function addSuccessorLocksToSchedule1
  input HpcOmSimCode.Task iTask;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllTasks;
  input Integer iThreadId;
  input FuncType iCreateLockFunction;
  input list<HpcOmSimCode.Task> iThreadTasks; //schedulerTasks
  output list<HpcOmSimCode.Task> oThreadTasks;

  partial function FuncType
    input tuple<HpcOmSimCode.Task,Integer> iSuccessorTask;
    input Integer iTaskIdx;
    input list<HpcOmSimCode.Task> iReleaseTasks;
    output list<HpcOmSimCode.Task> oReleaseTasks;
  end FuncType;
protected
  Integer threadIdx,index,listIndex;
  list<tuple<HpcOmSimCode.Task,Integer>> successors;
  list<HpcOmSimCode.Task> tmpThreadTasks, releaseTasks;
algorithm
  oThreadTasks := match(iTask, iTaskGraph, iAllTasks, iThreadId, iCreateLockFunction, iThreadTasks)
    case(HpcOmSimCode.CALCTASK(threadIdx=threadIdx,index=index),_,_,_,_,tmpThreadTasks)
      equation
        (successors,_) = getSuccessorsByTask(iTask, iTaskGraph, iAllTasks);
        successors = List.removeOnTrue(threadIdx, compareTaskWithThreadIdx, successors);
        releaseTasks = List.fold1(successors, iCreateLockFunction, index, {});
        tmpThreadTasks = listAppend(releaseTasks,tmpThreadTasks);
        tmpThreadTasks = iTask :: tmpThreadTasks;
      then tmpThreadTasks;
    case(_,_,_,_,_,tmpThreadTasks)
      equation
        tmpThreadTasks = iTask :: tmpThreadTasks;
      then tmpThreadTasks;
    else
      equation
        print("HpcOmScheduler.addReleaseLocksToSchedule0 failed\n");
      then fail();
  end match;
end addSuccessorLocksToSchedule1;

protected function addReleaseLocksToSchedule
  input tuple<HpcOmSimCode.Task,Integer> iSuccessorTask;
  input Integer iTaskIdx;
  input list<HpcOmSimCode.Task> iReleaseTasks;
  output list<HpcOmSimCode.Task> oReleaseTasks;
protected
  HpcOmSimCode.Task tmpTask, successorTask;
  String lockString;
  Integer lockId, successorTaskId;
algorithm
  (successorTask,_) := iSuccessorTask;
  HpcOmSimCode.CALCTASK(index=successorTaskId) := successorTask;
  lockString := intString(successorTaskId) +& "_" +& intString(iTaskIdx);
  tmpTask := convertLockIdToReleaseTask(lockString);
  oReleaseTasks := tmpTask :: iReleaseTasks;
end addReleaseLocksToSchedule;

protected function addAssignLocksToSchedule
  input tuple<HpcOmSimCode.Task,Integer> iSuccessorTask;
  input Integer iTaskIdx;
  input list<HpcOmSimCode.Task> iReleaseTasks;
  output list<HpcOmSimCode.Task> oReleaseTasks;
protected
  HpcOmSimCode.Task tmpTask, successorTask;
  String lockString;
  Integer lockId, successorTaskId;
algorithm
  (successorTask,_) := iSuccessorTask;
  HpcOmSimCode.CALCTASK(index=successorTaskId) := successorTask;
  lockString := intString(iTaskIdx) +& "_" +& intString(successorTaskId);
  tmpTask := convertLockIdToAssignTask(lockString);
  oReleaseTasks := tmpTask :: iReleaseTasks;
end addAssignLocksToSchedule;

protected function getSimEqSysIdxForComp"gets the simeqSys indexes for the given SCC index"
  input Integer compIdx;
  input array<list<Integer>> iSccSimEqMapping;
  output list<Integer> simEqSysIdcs;
algorithm
  simEqSysIdcs := arrayGet(iSccSimEqMapping,compIdx);
end getSimEqSysIdxForComp;

protected function getSimEqSysIdcsForCompLst"gets a list of simeqSys indexes for the given list of SCC indexes"
  input list<Integer> compIdcs;
  input array<list<Integer>> iSccSimEqMapping;
  output list<Integer> simEqSysIdcs;
algorithm
  //print("compIdcs: \n"+&stringDelimitList(List.map(compIdcs,intString),"\n")+&"\n");
  simEqSysIdcs := List.flatten(List.map1(compIdcs,Util.arrayGetIndexFirst,iSccSimEqMapping));
  //print("simEqSysIdcs: \n"+&stringDelimitList(List.map(simEqSysIdcs,intString),"\n")+&"\n");
end getSimEqSysIdcsForCompLst;

protected function getSimEqSysIdcsForNodeLst"gets a list of simeqSys indexes for the given nodes (node = list of comps)"
  input list<list<Integer>> nodeIdcs;
  input array<list<Integer>> iSccSimEqMapping;
  output list<list<Integer>> simEqSysIdcsLst;
algorithm
  simEqSysIdcsLst := List.map1(nodeIdcs,getSimEqSysIdcsForCompLst,iSccSimEqMapping);
end getSimEqSysIdcsForNodeLst;

protected function getLocksByPredecessorList
  input Integer iTaskIdx; //The parent task
  input Integer iThreadIdx; //Thread handling task <%iTaskIdx%>
  input list<tuple<HpcOmSimCode.Task,Integer>> iPredecessorList;
  output list<HpcOmSimCode.Task> oLockTasks;
  output list<String> oLockIdc;
protected
  list<String> tmpLockIdc;
algorithm
  tmpLockIdc := List.fold2(iPredecessorList, getLockIdcByPredecessorList, iTaskIdx, iThreadIdx, {});
  oLockTasks := List.map(tmpLockIdc,convertLockIdToAssignTask);
  oLockIdc := tmpLockIdc;
end getLocksByPredecessorList;

protected function getLockIdcByPredecessorList
  input tuple<HpcOmSimCode.Task,Integer> iPredecessorTask;
  input Integer iTaskIdx; //The parent task
  input Integer iThreadIdx; //Thread handling task <%iTaskIdx%>
  input list<String> iLockIdc;
  output list<String> oLockIdc;
protected
  Integer index,threadIdx;
  String tmpLockString;
  list<String> tmpLockIdc;
algorithm
  oLockIdc := matchcontinue(iPredecessorTask,iTaskIdx,iThreadIdx,iLockIdc)
    case((HpcOmSimCode.CALCTASK(threadIdx=threadIdx,index=index),_),_,_,_)
      equation
        true = intNe(iThreadIdx,threadIdx);
        //print("Adding a new lock for the tasks " +& intString(iTaskIdx) +& " " +& intString(index) +& "\n");
        //print("Because task " +& intString(index) +& " is scheduled to " +& intString(threadIdx) +& "\n");
        tmpLockString = intString(iTaskIdx) +& "_" +& intString(index);
        tmpLockIdc = tmpLockString :: iLockIdc;
      then tmpLockIdc;
    else iLockIdc;
  end matchcontinue;
end getLockIdcByPredecessorList;

protected function getLocksByPredecessorListReverse
  input Integer iTaskIdx; //The parent task
  input Integer iThreadIdx; //Thread handling task <%iTaskIdx%>
  input list<tuple<HpcOmSimCode.Task,Integer>> iPredecessorList;
  output list<HpcOmSimCode.Task> oLockTasks;
  output list<String> oLockIdc;
protected
  list<String> tmpLockIdc;
algorithm
  tmpLockIdc := List.fold2(iPredecessorList, getLockIdcByPredecessorListReverse, iTaskIdx, iThreadIdx, {});
  oLockTasks := List.map(tmpLockIdc,convertLockIdToReleaseTask);
  oLockIdc := tmpLockIdc;
end getLocksByPredecessorListReverse;

protected function getLockIdcByPredecessorListReverse
  input tuple<HpcOmSimCode.Task,Integer> iPredecessorTask;
  input Integer iTaskIdx; //The parent task
  input Integer iThreadIdx; //Thread handling task <%iTaskIdx%>
  input list<String> iLockIdc;
  output list<String> oLockIdc;
protected
  Integer index,threadIdx;
  String tmpLockString;
  list<String> tmpLockIdc;
algorithm
  oLockIdc := matchcontinue(iPredecessorTask,iTaskIdx,iThreadIdx,iLockIdc)
    case((HpcOmSimCode.CALCTASK(threadIdx=threadIdx,index=index),_),_,_,_)
      equation
        true = intNe(iThreadIdx,threadIdx);
        //print("Adding a new lock for the tasks " +& intString(iTaskIdx) +& " " +& intString(index) +& "\n");
        //print("Because task " +& intString(index) +& " is scheduled to " +& intString(threadIdx) +& "\n");
        tmpLockString = intString(index) +& "_" +& intString(iTaskIdx);
        tmpLockIdc = tmpLockString :: iLockIdc;
      then tmpLockIdc;
    else iLockIdc;
  end matchcontinue;
end getLockIdcByPredecessorListReverse;

protected function convertLockIdToAssignTask
  input String iLockId;
  output HpcOmSimCode.Task oAssignTask;
algorithm
  oAssignTask := HpcOmSimCode.ASSIGNLOCKTASK(iLockId);
end convertLockIdToAssignTask;

protected function convertLockIdToReleaseTask
  input String iLockId;
  output HpcOmSimCode.Task oReleaseTask;
algorithm
  oReleaseTask := HpcOmSimCode.RELEASELOCKTASK(iLockId);
end convertLockIdToReleaseTask;

protected function updateRefCounterBySuccessorIdc "function updateRefCounterBySuccessorIdc
  author: marcusw
  Decrement the ref-counter off all tasks in the successor-list. If the new ref-counter is 0, the task
  will be append to the second return argument."
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllTasks; //all tasks with ref-counter
  input list<Integer> iSuccessorIdc;
  input list<HpcOmSimCode.Task> iRefZeroTasks;
  output array<tuple<HpcOmSimCode.Task,Integer>> oAllTasks;
  output list<HpcOmSimCode.Task> oRefZeroTasks; //Tasks with new ref-counter = 0
protected
  Integer head, currentRefCount;
  list<Integer> rest;
  list<HpcOmSimCode.Task> tmpRefZeroTasks;
  HpcOmSimCode.Task currentTask;
  array<tuple<HpcOmSimCode.Task,Integer>> tmpAllTasks;

algorithm
  (oAllTasks,oRefZeroTasks) := matchcontinue(iAllTasks,iSuccessorIdc,iRefZeroTasks)
    case(_,head::rest,_)
      equation
        ((currentTask,currentRefCount)) = arrayGet(iAllTasks,head);
        //print("\tTask " +& intString(head) +& " has ref-counter of " +& intString(currentRefCount) +& "\n");
        true = intEq(currentRefCount,1); //Task-refcounter = 0
        tmpAllTasks = arrayUpdate(iAllTasks,head,(currentTask,0));
        tmpRefZeroTasks = currentTask :: iRefZeroTasks;
        (tmpAllTasks,tmpRefZeroTasks) = updateRefCounterBySuccessorIdc(tmpAllTasks,rest,tmpRefZeroTasks);
      then (tmpAllTasks,tmpRefZeroTasks);
    case(_,head::rest,_)
      equation
        ((currentTask,currentRefCount)) = arrayGet(iAllTasks,head); //Task-refcounter != 0
        tmpAllTasks = arrayUpdate(iAllTasks,head,(currentTask,currentRefCount-1));
        (tmpAllTasks,tmpRefZeroTasks) = updateRefCounterBySuccessorIdc(tmpAllTasks,rest,iRefZeroTasks);
      then (tmpAllTasks,tmpRefZeroTasks);
    else (iAllTasks,iRefZeroTasks);
  end matchcontinue;
end updateRefCounterBySuccessorIdc;

protected function getThreadFinishTimesMin
  input Integer iThreadIdx;
  input array<Real> iThreadFinishTimes;
  input Integer iCurrentMinThreadIdx;
  input Real iCurrentMinFinishTime;
  output tuple<Integer,Real> minThreadTime_Idx;
protected
  Real threadFinishTime;
algorithm
  minThreadTime_Idx := matchcontinue(iThreadIdx,iThreadFinishTimes,iCurrentMinThreadIdx,iCurrentMinFinishTime)
    case(_,_,_,_)
      equation
        true = intGt(iThreadIdx,arrayLength(iThreadFinishTimes));
      then ((iCurrentMinThreadIdx, iCurrentMinFinishTime));
    case(_,_,_,_)
      equation
        threadFinishTime = arrayGet(iThreadFinishTimes, iThreadIdx);
        true = realLt(threadFinishTime,iCurrentMinFinishTime) or intEq(iCurrentMinThreadIdx,-1);
      then getThreadFinishTimesMin(iThreadIdx+1,iThreadFinishTimes, iThreadIdx, threadFinishTime);
    else getThreadFinishTimesMin(iThreadIdx+1,iThreadFinishTimes, iCurrentMinThreadIdx, iCurrentMinFinishTime);
  end matchcontinue;
end getThreadFinishTimesMin;

protected function getTaskWithHighestFinishTime "function getTaskWithHighestFinishTime
  author: marcusw
  Pick the task with the highest finish time out of the given task list."
  input list<tuple<HpcOmSimCode.Task,Integer>> iTasks; //Tasks with ref-counter
  input Option<HpcOmSimCode.Task> iCurrentTask;
  output HpcOmSimCode.Task oTask; //The task with the highest finish time
protected
  HpcOmSimCode.Task head;
  HpcOmSimCode.Task tmpTask;
  list<tuple<HpcOmSimCode.Task,Integer>> tail;
  Real timeFinishedHead, timeFinishedCurrent;
algorithm
  oTask := matchcontinue(iTasks, iCurrentTask)
    case((head,_)::tail, NONE()) then getTaskWithHighestFinishTime(tail, SOME(head));
    case(((head as HpcOmSimCode.CALCTASK(timeFinished=timeFinishedHead)),_)::tail, SOME(HpcOmSimCode.CALCTASK(timeFinished=timeFinishedCurrent)))
      equation
        true = realGt(timeFinishedHead, timeFinishedCurrent);
      then getTaskWithHighestFinishTime(tail, SOME(head));
    case((head,_)::tail, SOME(_)) then getTaskWithHighestFinishTime(tail, iCurrentTask);
    case({},SOME(tmpTask)) then tmpTask;
    else
      equation
        print("HpcOmScheduler.getTaskWithHighestFinishTime failed!\n");
      then fail();
  end matchcontinue;
end getTaskWithHighestFinishTime;

protected function convertTaskGraphToTasks "function convertTaskGraphToTasks
  author: marcusw
  Convert all tasks of the taskGraph-Structure to HpcOmScheduler.Tasks"
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input FuncType iConverterFunc; //Pointer to function which converts one Task
  output array<tuple<HpcOmSimCode.Task,Integer>> oTasks; //all Tasks with ref_Counter
  partial function FuncType
    input Integer iNodeIdx;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    output HpcOmSimCode.Task oTask;
  end FuncType;
protected
  array<tuple<HpcOmSimCode.Task,Integer>> tmpTaskArray;
  array<list<Integer>> inComps;
algorithm
  //HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps) := iTaskGraphMeta;
  tmpTaskArray := arrayCreate(arrayLength(iTaskGraphT), ((HpcOmSimCode.TASKEMPTY(),0)));
  oTasks := convertTaskGraphToTasks1(iTaskGraphMeta,iTaskGraphT,1,iConverterFunc,tmpTaskArray);
end convertTaskGraphToTasks;

protected function convertTaskGraphToTasks1 "function convertTaskGraphToTasks1
  author: marcusw
  Convert one TaskGraph-Task to a Scheduler-Task with ref-counter."
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input Integer iIndex; //Index of current node
  input FuncType iConverterFunc; //Pointer to function which converts one Task
  input array<tuple<HpcOmSimCode.Task,Integer>> iTasks;
  output array<tuple<HpcOmSimCode.Task,Integer>> oTasks;
  partial function FuncType
    input Integer iNodeIdx;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    output HpcOmSimCode.Task oTask;
  end FuncType;
protected
  array<list<Integer>> inComps;
  array<Integer> nodeMarks;
  array<tuple<HpcOmSimCode.Task,Integer>> tmpTasks;
  Integer refCount;
  array<tuple<Integer,Real>> exeCosts;
  HpcOmSimCode.Task newTask;
algorithm
  oTasks := matchcontinue(iTaskGraphMeta, iTaskGraphT, iIndex, iConverterFunc, iTasks)
    case(_,_,_,_,_)
      equation
        true = intLe(iIndex, arrayLength(iTaskGraphT));
        refCount = listLength(arrayGet(iTaskGraphT, iIndex));
        //newTask := convertNodeToTask(iIndex, iTaskGraphMeta);
        newTask = iConverterFunc(iIndex, iTaskGraphMeta);
        tmpTasks = arrayUpdate(iTasks, iIndex, (newTask,refCount));
        tmpTasks = convertTaskGraphToTasks1(iTaskGraphMeta,iTaskGraphT,iIndex+1,iConverterFunc,tmpTasks);
      then tmpTasks;
    else iTasks;
  end matchcontinue;
end convertTaskGraphToTasks1;

protected function convertNodeToTask "function convertNodeToTask
  author: marcusw
  Convert one TaskGraph-Node to a Scheduler-Task and set weighting = nodeMark."
  input Integer iNodeIdx;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  output HpcOmSimCode.Task oTask;
protected
  Integer nodeMark, primalComp;
  list<Integer> components;
  Real exeCost;
  array<Integer> nodeMarks;
  array<tuple<Integer,Real>> exeCosts;
  array<list<Integer>> inComps;
algorithm
  oTask := match(iNodeIdx,iTaskGraphMeta)
    case(_,HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,nodeMark=nodeMarks, exeCosts=exeCosts))
      equation
        components = arrayGet(inComps,iNodeIdx);
        primalComp = listGet(components,1);
        nodeMark = arrayGet(nodeMarks,primalComp);
        //nodeMark = nodeMark * (-1); //switch from LLP to HLP
        //((_,exeCost)) = arrayGet(exeCosts,iNodeIdx);
        ((_,exeCost)) = HpcOmTaskGraph.getExeCost(iNodeIdx,iTaskGraphMeta);
      then HpcOmSimCode.CALCTASK(nodeMark,iNodeIdx,exeCost,-1.0,-1, components);
    else
      equation
        print("HpcOmScheduler.convertNodeToTask failed!\n");
      then fail();
  end match;
end convertNodeToTask;

protected function convertNodeToTaskReverse "function convertNodeToTaskReverse
  author: marcusw
  Convert one TaskGraph-Node to a Scheduler-Task and set weighting = -nodeMark."
  input Integer iNodeIdx;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  output HpcOmSimCode.Task oTask;
protected
  Integer nodeMark, primalComp;
  list<Integer> components;
  Real exeCost;
  array<Integer> nodeMarks;
  array<tuple<Integer,Real>> exeCosts;
  array<list<Integer>> inComps;
algorithm
  oTask := match(iNodeIdx,iTaskGraphMeta)
    case(_,HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,nodeMark=nodeMarks, exeCosts=exeCosts))
      equation
        components = arrayGet(inComps,iNodeIdx);
        primalComp = listGet(components,1);
        nodeMark = arrayGet(nodeMarks,primalComp);
        ((_,exeCost)) = arrayGet(exeCosts,iNodeIdx);
        nodeMark = nodeMark * (-1);
      then HpcOmSimCode.CALCTASK(nodeMark,iNodeIdx,exeCost,-1.0,-1, components);
    else
      equation
        print("HpcOmScheduler.convertNodeToTask failed!\n");
      then fail();
  end match;
end convertNodeToTaskReverse;

protected function calculateFinishTimes
  input Real iPredecessorTaskLastFinished; //time when the last predecessor has finished
  input HpcOmSimCode.Task iTask;
  input list<tuple<HpcOmSimCode.Task,Integer>> iPredecessorTasks; //all child tasks with ref-counter
  input array<list<tuple<Integer, Integer, Integer>>> iCommCosts;
  input array<Real> iThreadReadyTimes;
  output array<Real> oFinishTimes;
protected
  array<Real> tmpFinishTimes;
algorithm
  tmpFinishTimes := arrayCreate(arrayLength(iThreadReadyTimes), 0.0);
  tmpFinishTimes := calculateFinishTimes1(iPredecessorTaskLastFinished, iTask, iPredecessorTasks, iCommCosts, iThreadReadyTimes, 1, tmpFinishTimes);
  oFinishTimes := tmpFinishTimes;
end calculateFinishTimes;

protected function calculateFinishTimes1
  input Real iPredecessorTaskLastFinished; //time when the last successor has finished
  input HpcOmSimCode.Task iTask;
  input list<tuple<HpcOmSimCode.Task,Integer>> iPredecessorTasks; //all child tasks
  input array<list<tuple<Integer, Integer, Integer>>> iCommCosts;
  input array<Real> iThreadReadyTimes;
  input Integer iThreadIdx;
  input array<Real> iFinishTimes;
  output array<Real> oFinishTimes;
protected
  Real thFinishTime, thReadyTime;
  array<Real> tmpFinishTimes;
algorithm
  oFinishTimes := matchcontinue(iPredecessorTaskLastFinished, iTask, iPredecessorTasks, iCommCosts, iThreadReadyTimes, iThreadIdx, iFinishTimes)
    case(_,_,_,_,_,_,_)
      equation
        true = intLe(iThreadIdx,arrayLength(iThreadReadyTimes));
        thReadyTime = arrayGet(iThreadReadyTimes, iThreadIdx);
        thFinishTime = calculateFinishTimeByThreadId(thReadyTime, iPredecessorTaskLastFinished, iThreadIdx, iTask, iPredecessorTasks, iCommCosts);
        tmpFinishTimes = arrayUpdate(iFinishTimes,iThreadIdx,thFinishTime);
      then calculateFinishTimes1(iPredecessorTaskLastFinished, iTask, iPredecessorTasks, iCommCosts, iThreadReadyTimes, iThreadIdx+1, tmpFinishTimes);
    else iFinishTimes;
  end matchcontinue;
end calculateFinishTimes1;

protected function calculateFinishTimeByThreadId
  input Real iThreadReadyTime; //time when the thread has finished his last task
  input Real iPredecessorTaskLastFinished; //time when the last predecessor has finished
  input Integer iThreadId;
  input HpcOmSimCode.Task iTask;
  input list<tuple<HpcOmSimCode.Task,Integer>> iPredecessorTasks; //all child tasks
  input array<list<tuple<Integer, Integer, Integer>>> iCommCosts;
  output Real oFinishTime;
protected
  list<tuple<HpcOmSimCode.Task,Integer>> predecessorTasksOtherTh; //all predecessor scheduled to another thread
  Real commCost, calcTime;
  Real startTime;
algorithm
  oFinishTime := match(iThreadReadyTime, iPredecessorTaskLastFinished, iThreadId, iTask, iPredecessorTasks, iCommCosts)
    case(_,_,_,HpcOmSimCode.CALCTASK(calcTime=calcTime),_,_)
      equation
        predecessorTasksOtherTh = List.removeOnTrue(iThreadId, compareTaskWithThreadIdx, iPredecessorTasks);
        startTime = realMax(iThreadReadyTime, iPredecessorTaskLastFinished);
        commCost = getMaxCommCostsByTaskList(iTask,predecessorTasksOtherTh, iCommCosts);
      then realAdd(realAdd(startTime, commCost), calcTime);
    else
      equation
        print("HpcOmScheduler.calculateFinishTimeByThreadId can only handle CALCTASKs\n");
      then fail();
  end match;
end calculateFinishTimeByThreadId;

protected function getMaxCommCostsByTaskList
  input HpcOmSimCode.Task iParentTask;
  input list<tuple<HpcOmSimCode.Task,Integer>> iTaskList;
  input array<list<tuple<Integer, Integer, Integer>>> iCommCosts;
  output Real oCommCost;
algorithm
  oCommCost := List.fold2(iTaskList, getMaxCommCostsByTaskList1, iParentTask, iCommCosts, 0.0);
end getMaxCommCostsByTaskList;

protected function getMaxCommCostsByTaskList1
  input tuple<HpcOmSimCode.Task,Integer> iTask;
  input HpcOmSimCode.Task iParentTask;
  input array<list<tuple<Integer, Integer, Integer>>> iCommCosts;
  input Real iCurrentMax;
  output Real oCommCost;
protected
  Integer taskIdx;
  Integer reqCycles;
  Real reqCyclesReal;
  list<Integer> eqIdc, parentEqIdc;
  list<tuple<Integer, Integer, Integer>> childCommCosts;
algorithm
  oCommCost := matchcontinue(iTask, iParentTask, iCommCosts, iCurrentMax)
    case((HpcOmSimCode.CALCTASK(index=taskIdx,eqIdc=eqIdc),_),HpcOmSimCode.CALCTASK(eqIdc=parentEqIdc),_,_)
      equation
        //print("Try to find edge cost from scc " +& intString(List.first(eqIdc)) +& " to scc " +& intString(List.first(parentEqIdc)) +& "\n");
        childCommCosts = arrayGet(iCommCosts,List.first(eqIdc));
        ((_,_,reqCycles)) = getMaxCommCostsByTaskList2(childCommCosts, List.first(parentEqIdc));
        reqCyclesReal = intReal(reqCycles);
        true = realGt(reqCyclesReal, iCurrentMax);
      then reqCyclesReal;
    else iCurrentMax;
  end matchcontinue;
end getMaxCommCostsByTaskList1;

protected function getMaxCommCostsByTaskList2
  input list<tuple<Integer, Integer, Integer>> iCommCosts;
  input Integer iIdx; //Scc idx
  output tuple<Integer, Integer, Integer> oTuple;
protected
  Integer childIdxHead, childNumberOfVarsHead, childReqCyclesHead;
  list<tuple<Integer, Integer, Integer>> tail;
algorithm
  oTuple := matchcontinue(iCommCosts, iIdx)
    case((childIdxHead,childNumberOfVarsHead,childReqCyclesHead)::tail, _)
      equation
        true = intEq(childIdxHead,iIdx);
      then ((childIdxHead,childNumberOfVarsHead,childReqCyclesHead));
    case(_::tail, _) then getMaxCommCostsByTaskList2(tail, iIdx);
    else
      equation
        print("HpcOmScheduler.getMaxCommCostsByTaskList2 failed\n");
      then fail();
  end matchcontinue;
end getMaxCommCostsByTaskList2;

protected function getTaskByIndex
  input Integer iTaskIdx;
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllTasks;
  output tuple<HpcOmSimCode.Task,Integer> oTask;
algorithm
  oTask := arrayGet(iAllTasks,iTaskIdx);
end getTaskByIndex;

protected function getSuccessorsByTask
  input HpcOmSimCode.Task iTask;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllTasks;
  output list<tuple<HpcOmSimCode.Task,Integer>> oTasks;
  output list<Integer> oTaskIdc;
protected
  Integer taskIdx;
  list<Integer> successors;
  list<tuple<HpcOmSimCode.Task,Integer>> tmpTasks;
algorithm
  (oTasks, oTaskIdc) := matchcontinue(iTask,iTaskGraph,iAllTasks)
    case(HpcOmSimCode.CALCTASK(index=taskIdx),_,_)
      equation
        successors = arrayGet(iTaskGraph,taskIdx);
        tmpTasks = List.map1(successors, getTaskByIndex, iAllTasks);
      then (tmpTasks, successors);
    else
      equation
        print("HpcOmScheduler.getSuccessorsByTask can only handle CALCTASKs.");
      then fail();
  end matchcontinue;
end getSuccessorsByTask;

protected function compareTasksByWeighting
  input HpcOmSimCode.Task iTask1;
  input HpcOmSimCode.Task iTask2;
  output Boolean oResult;
protected
  Integer weightingTask1,weightingTask2;
algorithm
  oResult := match(iTask1,iTask2)
    case(HpcOmSimCode.CALCTASK(weighting=weightingTask1), HpcOmSimCode.CALCTASK(weighting=weightingTask2))
      then intGt(weightingTask1,weightingTask2);
    else
      equation
        print("HpcOmScheduler.compareTasksByWeighting can only compare CALCTASKs!\n");
      then fail();
  end match;
end compareTasksByWeighting;

protected function compareTaskWithThreadIdx
  input Integer iThreadIdx;
  input tuple<HpcOmSimCode.Task,Integer> iTask1;
  output Boolean oMatch; //True if the task has the same threadIdx as iThreadIdx
protected
  Integer threadIdx;
algorithm
  oMatch := match(iThreadIdx,iTask1)
    case(_,(HpcOmSimCode.CALCTASK(threadIdx=threadIdx),_))
      then intEq(threadIdx,iThreadIdx);
    else
      equation
        print("HpcOmScheduler.compareTaskWithThreadIdx can only compare CALCTASKs!\n");
      then fail();
  end match;
end compareTaskWithThreadIdx;

protected function printThreadSchedule
  input list<HpcOmSimCode.Task> iTaskList;
  input Integer iThreadIdx;
  output Integer oThreadIdx;
algorithm
  print("--------------\n");
  print("Thread " +& intString(iThreadIdx) +& "\n");
  print("--------------\n");
  printTaskList(iTaskList);
  oThreadIdx := iThreadIdx+1;
end printThreadSchedule;

protected function printTaskDepSchedule
  input tuple<HpcOmSimCode.Task,list<Integer>> iTaskInfo;
protected
  HpcOmSimCode.Task iTask;
  list<Integer> iDependencies;
algorithm
  (iTask,iDependencies) := iTaskInfo;
  print("Task: \n");
  print(dumpTask(iTask) +& "\n");
  print("-> Parents: " +& stringDelimitList(List.map(iDependencies,intString),",") +& "\n");
  print("---------------------\n");
end printTaskDepSchedule;

protected function printTaskList
  input list<HpcOmSimCode.Task> iTaskList;
protected
  HpcOmSimCode.Task head;
  list<HpcOmSimCode.Task> rest;
algorithm
  _ := match(iTaskList)
    case(head::rest)
      equation
        print(dumpTask(head));
        printTaskList(rest);
      then ();
    else
      then ();
  end match;
end printTaskList;

protected function dumpTask
  input HpcOmSimCode.Task iTask;
  output String oString;
protected
  Integer weighting, index;
  Real calcTime, timeFinished;
  Integer threadIdx;
  list<Integer> eqIdc, nodeIdc;
  String lockId;
algorithm
  oString := match(iTask)
    case(HpcOmSimCode.CALCTASK(weighting=weighting,timeFinished=timeFinished, index=index, eqIdc=eqIdc))
      then ("Calculation task with index " +& intString(index) +& " including the equations: "+&stringDelimitList(List.map(eqIdc,intString),", ")+& " is finished at  " +& realString(timeFinished) +& "\n");
    case(HpcOmSimCode.CALCTASK_LEVEL(eqIdc=eqIdc, nodeIdc=nodeIdc))
      then ("Calculation task ("+&stringDelimitList(List.map(nodeIdc,intString),", ")+&") including the equations: "+&stringDelimitList(List.map(eqIdc,intString),", ")+&"\n");
    case(HpcOmSimCode.ASSIGNLOCKTASK(lockId=lockId))
      then ("Assign lock task with id " +& lockId +& "\n");
    case(HpcOmSimCode.RELEASELOCKTASK(lockId=lockId))
      then ("Release lock task with id " +& lockId +& "\n");
    case(HpcOmSimCode.TASKEMPTY())
      then ("empty task\n");
    else
      equation
        print("HpcOmScheduler.dumpTask failed\n");
      then fail();
  end match;
end dumpTask;


public function convertScheduleStrucToInfo "author: marcusw
  Convert the given schedule-information into an node-array of informations."
  input HpcOmSimCode.Schedule iSchedule;
  input Integer iTaskCount;
  output array<tuple<Integer,Integer,Real>> oScheduleInfo; //array which contains <threadId,taskNumber,finishTime> for each node (index)
protected
  array<tuple<Integer,Integer,Real>> tmpScheduleInfo;
  array<list<HpcOmSimCode.Task>> threadTasks;
algorithm
  oScheduleInfo := match(iSchedule,iTaskCount)
    case(HpcOmSimCode.EMPTYSCHEDULE(),_)
      equation
        tmpScheduleInfo = arrayCreate(iTaskCount,(-1,-1,-1.0));
      then tmpScheduleInfo;
    case(HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks),_)
      equation
        tmpScheduleInfo = arrayCreate(iTaskCount,(-1,-1,-1.0));
        tmpScheduleInfo = Util.arrayFold(threadTasks,convertScheduleStrucToInfo0,tmpScheduleInfo);
      then tmpScheduleInfo;
    case(HpcOmSimCode.LEVELSCHEDULE(_),_)
      equation
        tmpScheduleInfo = arrayCreate(iTaskCount,(-1,-1,-1.0));
      then tmpScheduleInfo;
    case(HpcOmSimCode.TASKDEPSCHEDULE(_),_)
      equation
        tmpScheduleInfo = arrayCreate(iTaskCount,(-1,-1,-1.0));
      then tmpScheduleInfo;
    else
      equation
        print("HpcOmScheduler.convertScheduleStrucToInfo unknown Schedule-Type.\n");
      then fail();
  end match;
end convertScheduleStrucToInfo;

protected function convertScheduleStrucToInfo0 "author: marcusw
  Convert the given task list into an node-array of informations."
  input list<HpcOmSimCode.Task> iTaskList;
  input array<tuple<Integer,Integer,Real>> iScheduleInfo;
  output array<tuple<Integer,Integer,Real>> oScheduleInfo;
algorithm
  ((oScheduleInfo,_)) := List.fold(iTaskList, convertScheduleStrucToInfo1, (iScheduleInfo,1));
end convertScheduleStrucToInfo0;

protected function convertScheduleStrucToInfo1 "author: marcusw
  Convert the given task into a tuple of informations, if it is a CalcTask."
  input HpcOmSimCode.Task iTask;
  input tuple<array<tuple<Integer,Integer,Real>>,Integer> iScheduleInfo; //ScheduleInfo and task number
  output tuple<array<tuple<Integer,Integer,Real>>,Integer> oScheduleInfo;
protected
  Integer taskIdx, taskNumber;
  Integer threadIdx;
  array<tuple<Integer,Integer,Real>> tmpScheduleInfo;
  Real timeFinished;
algorithm
  oScheduleInfo := match(iTask,iScheduleInfo)
    case(HpcOmSimCode.CALCTASK(index=taskIdx,threadIdx=threadIdx,timeFinished=timeFinished),(tmpScheduleInfo,taskNumber))
      equation
        tmpScheduleInfo = arrayUpdate(tmpScheduleInfo,taskIdx,(threadIdx,taskNumber,timeFinished));
      then ((tmpScheduleInfo,taskNumber+1));
    case (HpcOmSimCode.ASSIGNLOCKTASK(_),_) then iScheduleInfo;
    case (HpcOmSimCode.RELEASELOCKTASK(_),_) then iScheduleInfo;
    else
      equation
        print("HpcOmScheduler.convertScheduleStrucToInfo1 failed. Unknown Task-Type.\n");
      then fail();
  end match;
end convertScheduleStrucToInfo1;


//-----------------
// Balanced Level Scheduling
//-----------------

public function createBalancedLevelScheduling "function createBalancedLevelScheduling
  author: waurich TUD
  Creates a balanced level scheduling for the given graph"
  input HpcOmTaskGraph.TaskGraph iGraph;
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  output HpcOmSimCode.Schedule oSchedule;
  output HpcOmTaskGraph.TaskGraphMeta oMeta;
protected
  Real cpCostsWoC, targetCost;
  array<Integer> levelAss, nodeMark;
  list<Integer> startNodes, critPathNodes;
  list<Real> critPathCosts;
  list<list<Integer>> level, critPathSections;
  list<list<list<Integer>>> allSections;
  list<list<list<Integer>>> levelComps,SCCs;  //level<node<tasks<components or simEqSys>>>
  array<list<Integer>> inComps;
  HpcOmTaskGraph.TaskGraph graphT;
  list<HpcOmSimCode.TaskList> levelTasks;
  array<tuple<Integer,Integer,Integer>> varCompMapping, eqCompMapping;
  list<Integer> rootNodes;
  array<String> nodeNames, nodeDescs;
  array<tuple<Integer,Real>> exeCosts;
  array<list<tuple<Integer,Integer,Integer>>> commCosts;
algorithm
  targetCost := 1000.0;
  HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps) := iMeta;
  graphT := BackendDAEUtil.transposeMatrix(iGraph,arrayLength(iGraph));

  // assign initial level
  (_,startNodes) := List.filterOnTrueSync(arrayList(graphT),List.isEmpty,List.intRange(arrayLength(graphT)));
  level := getGraphLevel(iGraph,{startNodes});
  levelAss := arrayCreate(arrayLength(inComps),-1);
  ((_,levelAss)) := List.fold(level,getLevelAssignment,(1,levelAss));
    print("level: \n"+&stringDelimitList(List.map(level,intListString),"\n")+&"\n");

  // get critical path and merge the criPathNodes to target size tasks
  (_,(critPathNodes::_,_),_) := HpcOmTaskGraph.getCriticalPaths(iGraph,iMeta);  // without communication costs
  critPathCosts := List.map1(critPathNodes,HpcOmTaskGraph.getExeCostReqCycles,iMeta);
    print("critPathNodes: \n"+&stringDelimitList(List.map(critPathNodes,intString)," \n ")+&"\n");

  //try to fill the parallel sections
  allSections := BLS_fillParallelSections(level,levelAss,critPathNodes,1,targetCost,iGraph,graphT,iMeta,{},{});
    print("allSections1: \n"+&stringDelimitList(List.map(allSections,intListListString)," \n ")+&"\n");
  allSections := List.map2(allSections,BLS_mergeSmallSections,iMeta,targetCost);
    print("allSections2: \n"+&stringDelimitList(List.map(allSections,intListListString)," \n ")+&"\n");

  //generate schedule
  levelTasks := List.map2(allSections,BLS_generateSchedule,iMeta,iSccSimEqMapping);
  oSchedule := HpcOmSimCode.LEVELSCHEDULE(levelTasks);

  //update nodeMark for graphml representation
  HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,varCompMapping=varCompMapping,eqCompMapping=eqCompMapping,rootNodes=rootNodes,nodeNames=nodeNames,nodeDescs=nodeDescs,exeCosts=exeCosts, commCosts=commCosts) := iMeta;
  nodeMark := arrayCreate(arrayLength(inComps),-1);
  level := List.map(allSections,List.flatten);
  ((_,nodeMark)) := List.fold(level,getLevelAssignment,(1,nodeMark));
  oMeta := HpcOmTaskGraph.TASKGRAPHMETA(inComps,varCompMapping,eqCompMapping,rootNodes,nodeNames,nodeDescs,exeCosts,commCosts,nodeMark);
end createBalancedLevelScheduling;

protected function BLS_mergeSmallSections"traverses the sections in a level and merges them if they are to small
author: Waurich TUD 2014-07"
  input list<list<Integer>> sectionsIn;
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  input Real targetCosts;
  output list<list<Integer>> sectionsOut;
algorithm
sectionsOut := matchcontinue(sectionsIn,iMeta,targetCosts)
  local
    list<list<Real>> costs;
    list<list<Integer>> mergedSectionIdcs, sectionsNew;
    list<list<list<Integer>>> sectionsNewUnflattened;
    list<Real> sectionCosts;
  case(_,_,_)
    equation
      costs = List.mapList1_1(sectionsIn,HpcOmTaskGraph.getExeCostReqCycles,iMeta);
      sectionCosts = List.map(costs,realSum);
      (mergedSectionIdcs,_) = BLS_mergeToTargetSize(List.intRange(listLength(sectionsIn)),sectionCosts,targetCosts,{});
      sectionsNewUnflattened = List.mapList1_1(mergedSectionIdcs,List.getIndexFirst,sectionsIn);
      sectionsNew = List.map(sectionsNewUnflattened,List.flatten);
      sectionsNew = List.map1(sectionsNew,List.sort,intGt);  // restore the calculation order
  then sectionsNew;
  end matchcontinue;
end BLS_mergeSmallSections;

protected function BLS_generateSchedule"generates a level schedule for the given levels. if a level contains only one section build a serial task
author: Waurich TUD 2014-07"
  input list<list<Integer>> level;
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  input array<list<Integer>> iSccSimEqMapping;
  output HpcOmSimCode.TaskList taskLstOut;
algorithm
  taskLstOut := matchcontinue(level,iMeta,iSccSimEqMapping)
    local
      list<Integer> section,simEqSysIdcs, compLst;
      list<list<Integer>> sections, sectionSimEqSysIdcs;
      list<list<list<Integer>>> sectionComps, sectionSimEqSys;
      array<list<Integer>> inComps;
      HpcOmSimCode.Task task;
      HpcOmSimCode.TaskList taskLst;
    case({section},HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps),_)
      equation
        // generate a serial section
        compLst = List.flatten(List.map1(section,Util.arrayGetIndexFirst,inComps));
        compLst = List.sort(compLst,intGt);
        simEqSysIdcs = getSimEqSysIdcsForCompLst(compLst,iSccSimEqMapping);
        task = HpcOmSimCode.CALCTASK_LEVEL(simEqSysIdcs,section);
        taskLst = HpcOmSimCode.SERIALTASKLIST({task});
    then taskLst;
    case(section::_,HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps),_)
      equation
        // generate parallel sections
        sectionComps = List.mapList1_1(level,Util.arrayGetIndexFirst,inComps);
        sectionComps = List.mapList1_1(sectionComps,List.sort,intGt);
        sectionSimEqSys = List.map1(sectionComps,getSimEqSysIdcsForNodeLst,iSccSimEqMapping);
        sectionSimEqSysIdcs = List.map(sectionSimEqSys,List.flatten);
        taskLst = makeCalcLevelParTaskLst(sectionSimEqSysIdcs,level);
    then taskLst;
  end matchcontinue;
end BLS_generateSchedule;

protected function BLS_fillParallelSections"cluster the tasks from the level, beginning with the critical path node. if this node is to small,
merge only necessary nodes to compute the next level critical path node. if the node is big enough gather all level nodes and unassigned nodes in this level.
author: Waurich TUD 2014-07"
  input list<list<Integer>> levelIn;
  input array<Integer> levelAssIn;
  input list<Integer> critPathNodes;
  input Integer levelIdx;
  input Real targetCosts;
  input HpcOmTaskGraph.TaskGraph iGraph;
  input HpcOmTaskGraph.TaskGraph iGraphT;
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  input list<Integer> unassNodesIn;
  input list<list<list<Integer>>> sectionsIn;  //level:section::tasks
  output list<list<list<Integer>>> sectionsOut;
algorithm
  sectionsOut := matchcontinue(levelIn,levelAssIn,critPathNodes,levelIdx,targetCosts,iGraph,iGraphT,iMeta,unassNodesIn,sectionsIn)
    local
      Real critPathCost;
      Integer numProc, critPathNode, critNodeLevel;
      array<Integer> levelAss;
      array<list<Integer>> levelNodeClusterArr;
      array<Real> levelNodeClusterCostsArr;
      list<Integer> section,restCritNodes,levelNodes,unassNodes               ,pos,necessaryPredecessors;
      list<list<Integer>> level, levelNodeCluster, levelNodeChildren;
      list<list<list<Integer>>> sectionLst;
      list<Real> necPredCosts,levelNodeClusterCosts,                       levelNodeCosts;
    case(_,_,{},_,_,_,_,_,_,_)
      equation
    then listReverse(sectionsIn);
    case(_,_,critPathNode::{},_,_,_,_,_,_,_)
      equation
        critPathCost = HpcOmTaskGraph.getExeCostReqCycles(critPathNode,iMeta);
        critNodeLevel = arrayGet(levelAssIn,critPathNode);

        // the last level: build the section, collect unassigned nodes and level nodes and put everything in this section
        levelNodes = List.flatten(List.map1(List.intRange2(levelIdx,critNodeLevel),List.getIndexFirst,levelIn));
          print("levelNodes: \n"+&stringDelimitList(List.map(levelNodes,intString)," ; ")+&" of level: "+&intString(critNodeLevel)+&"\n");
        unassNodes = listAppend(levelNodes,unassNodesIn);
        levelNodeCluster = BLS_mergeDependentLevelTask(unassNodes,iGraph,iGraphT,{});
          print("section: \n"+&stringDelimitList(List.map(levelNodeCluster,intListString),"  |  ")+&"\n");
        sectionLst = levelNodeCluster::sectionsIn;
        sectionLst = BLS_fillParallelSections(levelIn,levelAssIn,{},critNodeLevel+1,targetCosts,iGraph,iGraphT,iMeta,unassNodes,sectionLst);
      then sectionLst;
    case(_,_,critPathNode::restCritNodes,_,_,_,_,_,_,_)
      equation
        critPathCost = HpcOmTaskGraph.getExeCostReqCycles(critPathNode,iMeta);
        critNodeLevel = arrayGet(levelAssIn,critPathNode);

        // the critical path node in this section is to SMALL, gather as few as possible nodes in this level (onyl the necessary ones)
        true = critPathCost <. targetCosts;
          print("critPathNode (small): \n"+&intString(critPathNode)+&" of level: "+&intString(critNodeLevel)+&"\n");

        // get the nodes that are necessary to compute the next critical path node, collect unassigned
        levelNodes = List.flatten(List.map1(List.intRange2(levelIdx,critNodeLevel),List.getIndexFirst,levelIn));
        levelNodes = List.deleteMember(levelNodes,critPathNode);
          print("levelNodes: \n"+&stringDelimitList(List.map(levelNodes,intString)," ; ")+&"\n");
        necessaryPredecessors = arrayGet(iGraphT,List.first(restCritNodes));
          print("necessaryPredecessors: "+&stringDelimitList(List.map(necessaryPredecessors,intString)," ; ")+&"\n");
        unassNodes = listAppend(levelNodes,unassNodesIn);  // to check for unassNodesIn
          print("unassNodes: \n"+&stringDelimitList(List.map(unassNodes,intString)," ; ")+&"\n");
        necessaryPredecessors = List.flatten(List.map4(List.map(necessaryPredecessors,List.create),BLS_getDependentGroups,iGraph,iGraphT,unassNodes,{}));  // get all unassigned dependents for the necessary predecessors
        necessaryPredecessors = List.unique(necessaryPredecessors);
        (necessaryPredecessors,_,unassNodes) = List.intersection1OnTrue(necessaryPredecessors,unassNodes,intEq);

        // build the section
        section = critPathNode::necessaryPredecessors;
        section = List.unique(section);
        sectionLst = {section}::sectionsIn;
          print("section: \n"+&stringDelimitList(List.map(section,intString),"  ,  ")+&"\n");

        // update levelAss and levelIn
        List.map2_0(section,Util.arrayUpdateIndexFirst,critNodeLevel,levelAssIn);
        level = List.map1(levelIn,deleteIntListMembers,section);
        level = List.set(level,critNodeLevel,section);
          print("level: \n"+&stringDelimitList(List.map(level,intListString),"\n")+&"\n");

        sectionLst = BLS_fillParallelSections(level,levelAssIn,restCritNodes,critNodeLevel+1,targetCosts,iGraph,iGraphT,iMeta,unassNodes,sectionLst);
      then sectionLst;
    case(_,_,critPathNode::restCritNodes,_,_,_,_,_,_,_)
      equation
        critPathCost = HpcOmTaskGraph.getExeCostReqCycles(critPathNode,iMeta);
        critNodeLevel = arrayGet(levelAssIn,critPathNode);

        // the critical path node in this section is BIG enough, gather as much as possible nodes in this level
        true = critPathCost >=. targetCosts;
        numProc = Flags.getConfigInt(Flags.NUM_PROC);
          print("critPathNode (big): \n"+&intString(critPathNode)+&" of level: "+&intString(critNodeLevel)+&"\n");

        // get the nodes that are necessary to compute the next critical path node
        levelNodes = List.flatten(List.map1(List.intRange2(levelIdx,critNodeLevel),List.getIndexFirst,levelIn));
        (levelNodes,_) = List.deleteMemberOnTrue(critPathNode,levelNodes,intEq);
        necessaryPredecessors = arrayGet(iGraphT,List.first(restCritNodes));
          print("necessaryPredecessors: \n"+&stringDelimitList(List.map(necessaryPredecessors,intString)," ; ")+&"\n");

        // use the unassigned nodes first to fill the sections
        unassNodes = listAppend(unassNodesIn,levelNodes);
          print("unassNodes: \n"+&stringDelimitList(List.map(unassNodes,intString)," ; ")+&"\n");
        unassNodes = critPathNode::unassNodes;
        unassNodes = List.unique(unassNodes);
        levelNodeCluster = BLS_mergeDependentLevelTask(unassNodes,iGraph,iGraphT,{});
        (_,unassNodes,_) = List.intersection1OnTrue(unassNodes,List.flatten(levelNodeCluster),intEq);
        sectionLst = levelNodeCluster::sectionsIn;
          print("section: \n"+&stringDelimitList(List.map(levelNodeCluster,intListString),"  |  ")+&"\n");

        // update levelAss and levelIn
        List.map2_0(List.flatten(levelNodeCluster),Util.arrayUpdateIndexFirst,critNodeLevel,levelAssIn);
        level = List.map1(levelIn,deleteIntListMembers,List.flatten(levelNodeCluster));
        level = List.set(level,critNodeLevel,List.flatten(levelNodeCluster));
          print("level: \n"+&stringDelimitList(List.map(level,intListString),"\n")+&"\n");

        sectionLst = BLS_fillParallelSections(level,levelAssIn,restCritNodes,critNodeLevel+1,targetCosts,iGraph,iGraphT,iMeta,{},sectionLst);
      then sectionLst;
  end matchcontinue;
end BLS_fillParallelSections;

protected function BLS_mergeDependentLevelTask"gathers nodes in merged level according to their dependencies. successors and predecessors have to be collected in one section.
author:Waurich TUD 2014-07"
  input list<Integer> nodesIn;
  input HpcOmTaskGraph.TaskGraph iGraph;
  input HpcOmTaskGraph.TaskGraph iGraphT;
  input list<list<Integer>> sectionsIn;
  output list<list<Integer>> sectionsOut;
algorithm
  sectionsOut := matchcontinue(nodesIn,iGraph,iGraphT,sectionsIn)
    local
      Integer node;
      list<Integer> rest,dependentNodes,section;
      list<list<Integer>> sections;
  case({},_,_,_)
    equation
    then listReverse(sectionsIn);
  case(node::rest,_,_,_)
    equation
      //print("node: "+&intString(node)+&"\n");
      dependentNodes = BLS_getDependentGroups({node},iGraph,iGraphT,nodesIn,{});
      section = node::dependentNodes;
      section = List.unique(section);
      (_,rest,_) = List.intersection1OnTrue(rest,dependentNodes,intEq);
      section = listReverse(section);
      //print("section: \n"+&stringDelimitList(List.map(section,intString)," ; ")+&"\n");
      sections = BLS_mergeDependentLevelTask(rest,iGraph,iGraphT,section::sectionsIn);
    then sections;
  end matchcontinue;
end BLS_mergeDependentLevelTask;

protected function BLS_getDependentGroups"gathers the dependent successors and predecessors among all referenceNodes for the given task.
author:Waurich TUD 2014-07"
  input list<Integer> nodes;  //as first input, take a single node: {node}
  input HpcOmTaskGraph.TaskGraph iGraph;
  input HpcOmTaskGraph.TaskGraph iGraphT;
  input list<Integer> referenceNodesIn;
  input list<Integer> dependentsIn;
  output list<Integer> dependentsOut;
algorithm
  dependentsOut := matchcontinue(nodes,iGraph,iGraphT,referenceNodesIn,dependentsIn)
    local
      Integer node;
      list<Integer> successors, predecessors, rest, dependentNodes, referenceNodes, allNodes;
  case({},_,_,_,_)
    then List.unique(dependentsIn);
  case(node::rest,_,_,_,_)
    equation
      //print("node: "+&intString(node)+&"\n");
      successors = arrayGet(iGraph,node);
      predecessors = arrayGet(iGraphT,node);
      //print("successors: \n"+&stringDelimitList(List.map(successors,intString)," ; ")+&"\n");
      //print("predecessors: \n"+&stringDelimitList(List.map(predecessors,intString)," ; ")+&"\n");
      (successors,_,referenceNodes) = List.intersection1OnTrue(successors,referenceNodesIn,intEq);
      (predecessors,_,referenceNodes) = List.intersection1OnTrue(predecessors,referenceNodes,intEq);
      //print("successors: \n"+&stringDelimitList(List.map(successors,intString)," ; ")+&"\n");
      //print("predecessors: \n"+&stringDelimitList(List.map(predecessors,intString)," ; ")+&"\n");
      dependentNodes = listAppend(predecessors,successors);
      allNodes = node::dependentNodes;
      dependentNodes = BLS_getDependentGroups(listAppend(rest,dependentNodes),iGraph,iGraphT,referenceNodes,listAppend(allNodes,dependentsIn));
   then dependentNodes;
  else
    equation
      print("BLS_getDependentGroups failed!\n");
    then fail();
  end matchcontinue;
end BLS_getDependentGroups;

protected function BLS_mergeToTargetSize"collect the largest groups of nodes that are smaller than the targetSize"
  input list<Integer> nodesIn;
  input list<Real> costsIn;
  input Real targetSize;
  input list<tuple<list<Integer>,Real>> mergedNodesIn;
  output list<list<Integer>> clustersOut;
  output list<Real> clusterCostsOut;
algorithm
  (clustersOut,clusterCostsOut) := matchcontinue(nodesIn,costsIn,targetSize,mergedNodesIn)
    local
      Integer node;
      Real cost, clusterCost;
      list<Integer> nodeRest, cluster;
      list<list<Integer>> clusterTmp;
      list<Real> costRest, clusterCostsTmp;
      tuple<list<Integer>,Real> group;
      list<tuple<list<Integer>,Real>> mergedNodes,restGroups;
  case({},{},_,{})
    then ({},{});
  case({},{},_,_)
    equation
      // finished
      clusterCostsTmp = List.map(mergedNodesIn,Util.tuple22);
      clusterTmp = listReverse(List.map(mergedNodesIn,Util.tuple21));
      cluster::clusterTmp = clusterTmp;  // reverse the first cluster if there is only one cluster
      cluster = Util.if_(List.isEmpty(clusterTmp),listReverse(cluster),cluster);
      clusterTmp = cluster::clusterTmp;
    then (clusterTmp,clusterCostsTmp);
   case(node::nodeRest,cost::costRest,_, {})
    equation
      // first cluster
      (clusterTmp,clusterCostsTmp) = BLS_mergeToTargetSize(nodeRest,costRest,targetSize,{({node},cost)});
    then (clusterTmp,clusterCostsTmp);
  case(node::nodeRest,cost::costRest,_, group::restGroups)
    equation
      // add to previous Cluster
      (cluster,clusterCost) = group;
      true = clusterCost +. cost <. targetSize;
      group = (node::cluster,cost +. clusterCost);
      (clusterTmp,clusterCostsTmp) = BLS_mergeToTargetSize(nodeRest,costRest,targetSize,group::restGroups);
    then (clusterTmp,clusterCostsTmp);
  case(node::nodeRest,cost::costRest,_,group::restGroups)
    equation
      // start a new cluster
      (cluster,clusterCost) = group;
      true = clusterCost +. cost >=. targetSize;
      cluster = listReverse(cluster);
      restGroups = (cluster,clusterCost)::restGroups;  // reverse the cluster
      group = ({node},cost);
      (clusterTmp,clusterCostsTmp) = BLS_mergeToTargetSize(nodeRest,costRest,targetSize,group::restGroups);
    then (clusterTmp,clusterCostsTmp);
  else
    equation
      print("BLS_mergeToTargetSize failed!");
    then fail();
  end matchcontinue;
end BLS_mergeToTargetSize;

protected function realSum"accumulates the real values in the list.
author:Waurich TUD 2014-07"
  input list<Real> reals;
  output Real sum;
algorithm
 sum := List.fold(reals,realAdd,0.0);
end realSum;

protected function deleteIntListMembers"deletes all entries of lst2 in lst2.
author: Waurich TUD 2014-07"
  input list<Integer> lst1;
  input list<Integer> lst2;
  output list<Integer> lstOut;
algorithm
  (_,lstOut,_):= List.intersection1OnTrue(lst1,lst2,intEq);
end deleteIntListMembers;

//-----------------
// Level Scheduling
//-----------------
public function createLevelSchedule "function createLevelSchedule
  author: waurich TUD
  Creates a level scheduling for the given graph"
  input HpcOmTaskGraph.TaskGraph iGraph;
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  output HpcOmSimCode.Schedule oSchedule;
  output HpcOmTaskGraph.TaskGraphMeta oMeta;
protected
  list<Integer> startNodes, levelAss;
  list<list<Integer>> level;
  list<list<list<Integer>>> levelComps,SCCs;  //level<node<tasks<components or simEqSys>>>
  array<list<Integer>> inComps;
  list<HpcOmSimCode.TaskList> levelTasks;
  HpcOmTaskGraph.TaskGraph graphT;
  array<tuple<Integer,Real>> exeCosts;
  array<Integer> nodeMark;
  list<Integer> rootNodes;
  array<list<tuple<Integer,Integer,Integer>>> commCosts;
  array<tuple<Integer,Integer,Integer>> varCompMapping, eqCompMapping; //Map each variable to the scc that solves her
  array<String> nodeNames, nodeDescs;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,varCompMapping=varCompMapping,eqCompMapping=eqCompMapping,rootNodes=rootNodes,nodeNames=nodeNames,nodeDescs=nodeDescs,exeCosts=exeCosts, commCosts=commCosts) := iMeta;

  graphT := BackendDAEUtil.transposeMatrix(iGraph,arrayLength(iGraph));
  (_,startNodes) := List.filterOnTrueSync(arrayList(graphT),List.isEmpty,List.intRange(arrayLength(graphT)));
    //print("startnodes "+&stringDelimitList(List.map(startNodes,intString),",")+&"\n");
  level := getGraphLevel(iGraph,{startNodes});
  Debug.fcall(Flags.HPCOM_DUMP,print,"number of level: "+&intString(listLength(level))+&"\nnumber of processors :"+&intString(Flags.getConfigInt(Flags.NUM_PROC))+&"\n");
    //print("level: \n"+&stringDelimitList(List.map(level,intListString),"\n")+&"\n");
  levelComps := List.mapList1_1(level,Util.arrayGetIndexFirst,inComps);
  levelComps := List.mapList1_1(levelComps,List.sort,intGt);
  SCCs := List.map1(levelComps,getSimEqSysIdcsForNodeLst,iSccSimEqMapping);
  levelTasks := List.threadMap(SCCs,List.mapList(level,List.create),makeCalcLevelParTaskLst);
  oSchedule := HpcOmSimCode.LEVELSCHEDULE(levelTasks);

  //update nodeMark for graphml representation
  nodeMark := arrayCreate(arrayLength(inComps),-1);
  ((_,nodeMark)) := List.fold(level,getLevelAssignment,(1,nodeMark));
  oMeta := HpcOmTaskGraph.TASKGRAPHMETA(inComps,varCompMapping,eqCompMapping,rootNodes,nodeNames,nodeDescs,exeCosts,commCosts,nodeMark);
end createLevelSchedule;

protected function getLevelAssignment"folding function to get a levelassignment for each node"
  input list<Integer> level;
  input tuple<Integer,array<Integer>> tplIn; //<levelIndex,assignmentArrayIn>
  output tuple<Integer,array<Integer>> tplOut;
protected
  Integer idx;
  array<Integer> ass;
algorithm
  (idx,ass) := tplIn;
  List.map2_0(level,Util.arrayUpdateIndexFirst,idx,ass);
  tplOut := (idx+1,ass);
end getLevelAssignment;

protected function makeCalcLevelParTaskLst "makes a parallel list of CALCTASK_LEVEL-Tasks out of the given lists of simEqSyslst and corresponding node list"
  input list<list<Integer>> simEqsForNodes;
  input list<list<Integer>> nodeIdcs;
  output HpcOmSimCode.TaskList tasksOut;
protected
  list<HpcOmSimCode.Task> tmpList;
algorithm
  tmpList := List.threadMap(simEqsForNodes,nodeIdcs, makeCalcLevelTask);
  tasksOut := HpcOmSimCode.PARALLELTASKLIST(tmpList);
end makeCalcLevelParTaskLst;

protected function makeCalcLevelTask" makes a CALCTASK_LEVEL for the given list of SimEqSys and a nodeIdx"
  input list<Integer> simEqs;
  input list<Integer> nodeIdx;
  output HpcOmSimCode.Task taskOut;
algorithm
  taskOut := HpcOmSimCode.CALCTASK_LEVEL(simEqs,nodeIdx);
end makeCalcLevelTask;

public function getGraphLevel"gets the level for the graph
author:Waurich TUD 2014-06"
  input HpcOmTaskGraph.TaskGraph iGraph;
  input list<list<Integer>> levelIn;  // inlcuding rootNodes as startvalues
  output list<list<Integer>> levelOut;
algorithm
  levelOut := matchcontinue(iGraph,levelIn)
    local
      Boolean notFinished;
      list<Integer> prevLevel, nextLevel;
      list<list<Integer>> nodeSuccs,level;
    case(_,prevLevel::_)
      equation
        // one assign successors to next level
        nodeSuccs = List.map1(prevLevel,Util.arrayGetIndexFirst,iGraph);
        nextLevel = List.flatten(nodeSuccs);
        true  = List.isNotEmpty(nextLevel);
        level = getGraphLevel(iGraph,nextLevel::levelIn);
    then level;
    case(_,prevLevel::_)
      equation
        // done, remove doubles, revert order, filter empty levels
        nodeSuccs = List.map1(prevLevel,Util.arrayGetIndexFirst,iGraph);
        nextLevel = List.flatten(nodeSuccs);
        true  = List.isEmpty(nextLevel);
        level = List.map(levelIn,List.unique);
        (level,_) = List.mapFold(level,getGraphLevel_removeDoubles,{});
        level = List.filterOnTrue(level,List.isNotEmpty);
        level = listReverse(level);
    then level;
    else
      equation
        print("getGraphLevel failed!\n");
      then fail();
   end matchcontinue;
end getGraphLevel;

protected function getGraphLevel_removeDoubles"removes the entries in the levels that are various times in different levels. Only the tasks in the latest levels remain.
author:Waurich TUD 2014-06"
  input list<Integer> levelIn;
  input list<Integer> assignedIn;
  output list<Integer> levelOut;
  output list<Integer> assignedOut;
protected
  list<Integer> doubles,uniques;
algorithm
  (doubles,uniques,_) := List.intersection1OnTrue(levelIn,assignedIn,intEq);
  assignedOut := listAppend(uniques,assignedIn);
  levelOut := uniques;
end getGraphLevel_removeDoubles;

protected function printLevelSchedule "function printLevelSchedule
  author: marcusw
  Helper function to print one level."
  input HpcOmSimCode.TaskList iLevelInfo;
  input Integer iLevel;
  output Integer oLevel;
protected
  list<HpcOmSimCode.Task> tasks;
algorithm
  oLevel := match(iLevelInfo, iLevel)
    case(HpcOmSimCode.PARALLELTASKLIST(tasks=tasks),_)
      equation
        print("Parallel Level " +& intString(iLevel) +& ":\n");
        printTaskList(tasks);
      then iLevel + 1;
    case(HpcOmSimCode.SERIALTASKLIST(tasks=tasks),_)
      equation
        print("Serial Level " +& intString(iLevel) +& ":\n");
        printTaskList(tasks);
      then iLevel + 1;
    else
      equation
        print("printLevelSchedule failed!\n");
      then iLevel + 1;
   end match;
end printLevelSchedule;

//---------------------------
// Task dependency Scheduling
//---------------------------
public function createTaskDepSchedule "function createTaskDepSchedule
  author: marcusw
  Creates a dynamic scheduling for OpenMP 4.0 task dependencies or Intel TBB graphs."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  output HpcOmSimCode.Schedule oSchedule;
protected
  HpcOmSimCode.Schedule tmpSchedule;
  array<list<Integer>> inComps;
  array<Integer> nodeMark;
  HpcOmTaskGraph.TaskGraph taskGraphT;
  list<tuple<HpcOmSimCode.Task,Integer,list<Integer>>> nodeLevelMap; //<task, levelIdx, parentTaskIdc>
  list<tuple<HpcOmSimCode.Task,list<Integer>>> filteredNodeLevelMap;
algorithm
  oSchedule := matchcontinue(iTaskGraph,iTaskGraphMeta,iSccSimEqMapping)
    case(_,HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,nodeMark=nodeMark),_)
      equation
        taskGraphT = HpcOmTaskGraph.transposeTaskGraph(iTaskGraph);
        ((_,nodeLevelMap)) = Util.arrayFold3(taskGraphT, createNodeLevelMapping, nodeMark, inComps, iSccSimEqMapping, (1,{}));
        nodeLevelMap = List.sort(nodeLevelMap, sortNodeLevelMapping);
        filteredNodeLevelMap = List.map(nodeLevelMap, filterNodeLevelMapping);
        tmpSchedule = HpcOmSimCode.TASKDEPSCHEDULE(filteredNodeLevelMap);
      then tmpSchedule;
    else
      equation
        print("HpcOmScheduler.createTaskDepSchedule failed.\n");
      then fail();
  end matchcontinue;
end createTaskDepSchedule;

protected function createNodeLevelMapping
  input list<Integer> iNodeDependenciesT; //dependencies of node
  input array<Integer> nodeMarks;
  input array<list<Integer>> inComps;
  input array<list<Integer>> iSccSimEqMapping;
  input tuple<Integer,list<tuple<HpcOmSimCode.Task,Integer,list<Integer>>>> iNodeInfo; //<taskIdx, list<task, levelIdx, parentTaskIdc>>
  output tuple<Integer,list<tuple<HpcOmSimCode.Task,Integer,list<Integer>>>> oNodeInfo;
protected
  HpcOmSimCode.Task task;
  Integer nodeIdx;
  Integer nodeMark;
  list<Integer> components;
  list<Integer> simEqIdc;
  list<tuple<HpcOmSimCode.Task,Integer,list<Integer>>> nodeLevelMap;
algorithm
  (nodeIdx,nodeLevelMap) := iNodeInfo;
  //print("createNodeLevelMapping NodeIdx: " +& intString(nodeIdx) +& "\n");
  components := arrayGet(inComps,nodeIdx);
  nodeMark := arrayGet(nodeMarks,List.last(components));
  //print("-> Components: " +& stringDelimitList(List.map(components,intString),", ") +& "\n");
  //print("-> NodeMark: " +& intString(nodeMark) +& "\n");
  //print("ISccSimEqMapping-Length: " +& intString(arrayLength(iSccSimEqMapping)) +& "\n");
  simEqIdc := List.map(List.map1(components,getSimEqSysIdxForComp,iSccSimEqMapping), List.last);
  simEqIdc := listReverse(simEqIdc);
  task := HpcOmSimCode.CALCTASK(-1,nodeIdx,-1.0,-1.0,-1,simEqIdc);
  nodeLevelMap := (task,nodeMark,iNodeDependenciesT)::nodeLevelMap;
  oNodeInfo := ((nodeIdx+1,nodeLevelMap));
end createNodeLevelMapping;

protected function sortNodeLevelMapping
  input tuple<HpcOmSimCode.Task,Integer,list<Integer>> iElem1;
  input tuple<HpcOmSimCode.Task,Integer,list<Integer>> iElem2;
  output Boolean oResult;
protected
  Integer elemLvl1, elemLvl2;
  Integer task1Idx;
algorithm
  (HpcOmSimCode.CALCTASK(index=task1Idx),elemLvl1,_) := iElem1;
  (_,elemLvl2,_) := iElem2;
  //print("sortNodeLevelMapping: TaskIdx: " +& intString(task1Idx) +& " level: " +& intString(elemLvl1) +& "\n");
  oResult := intGe(elemLvl1,elemLvl2);
end sortNodeLevelMapping;

protected function filterNodeLevelMapping
  input tuple<HpcOmSimCode.Task,Integer,list<Integer>> iElem;
  output tuple<HpcOmSimCode.Task,list<Integer>> oElem;
protected
  HpcOmSimCode.Task task;
  list<Integer> childTasks;
algorithm
  (task,_,childTasks) := iElem;
  oElem := ((task,childTasks));
end filterNodeLevelMapping;

//----------------------
// External-C Scheduling
//----------------------
public function createExtCSchedule "function createExtSchedule
  author: marcusw
  Creates a scheduling by passing the arguments to metis."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer iNumberOfThreads;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  output HpcOmSimCode.Schedule oSchedule;
protected
  list<Integer> extInfo;
  array<Integer> xadj, adjncy, vwgt, adjwgt;
  HpcOmSimCode.Schedule tmpSchedule;
  array<Integer> extInfoArr;
  HpcOmTaskGraph.TaskGraph taskGraphT;
  array<list<HpcOmSimCode.Task>> threadTasks;
  list<Integer> rootNodes;
  array<tuple<HpcOmSimCode.Task, Integer>> allTasks;
  list<tuple<HpcOmSimCode.Task,Integer>> nodeList_refCount; //list of nodes which are ready to schedule
  list<HpcOmSimCode.Task> nodeList;
algorithm
  oSchedule := matchcontinue(iTaskGraph,iTaskGraphMeta,iNumberOfThreads,iSccSimEqMapping)
    case(_,_,_,_)
      equation
        print("Funktionsaufruf!");
        (xadj,adjncy,vwgt,adjwgt) = HpcOmTaskGraph.prepareMetis(iTaskGraph,iTaskGraphMeta);
        extInfo = HpcOmSchedulerExt.scheduleMetis(xadj, adjncy, vwgt, adjwgt, iNumberOfThreads);
        extInfoArr = listArray(extInfo);
        print("Hier geht MetaModelica los!\n");
        print("External scheduling info: " +& stringDelimitList(List.map(extInfo, intString), ",") +& "\n");
        true = intEq(arrayLength(iTaskGraph),arrayLength(extInfoArr));

        taskGraphT = HpcOmTaskGraph.transposeTaskGraph(iTaskGraph);
        rootNodes = HpcOmTaskGraph.getRootNodes(iTaskGraph);
        allTasks = convertTaskGraphToTasks(taskGraphT,iTaskGraphMeta,convertNodeToTask);
        nodeList_refCount = List.map1(rootNodes, getTaskByIndex, allTasks);
        nodeList = List.map(nodeList_refCount, Util.tuple21);
        nodeList = List.sort(nodeList, compareTasksByWeighting);
        threadTasks = arrayCreate(iNumberOfThreads,{});
        tmpSchedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,{});
        tmpSchedule = createExtSchedule1(nodeList,extInfoArr, iTaskGraph, taskGraphT, allTasks, iSccSimEqMapping, getLocksByPredecessorList, tmpSchedule);
        tmpSchedule = addSuccessorLocksToSchedule(iTaskGraph,allTasks,addReleaseLocksToSchedule,tmpSchedule);
        //printSchedule(tmpSchedule);
      then tmpSchedule;
    else
      equation
        print("HpcOmScheduler.createExtCSchedule not every node has a scheduler-info.\n");
      then fail();
  end matchcontinue;
end createExtCSchedule;

public function createhmetSchedule "function createExtSchedule
  author: marcusw
  Creates a scheduling by passing the arguments to hmetis."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer iNumberOfThreads;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  output HpcOmSimCode.Schedule oSchedule;
protected
  list<Integer> extInfo;
  array<Integer> xadj, adjncy, vwgt, adjwgt;
  HpcOmSimCode.Schedule tmpSchedule;
  array<Integer> extInfoArr;
  HpcOmTaskGraph.TaskGraph taskGraphT;
  array<list<HpcOmSimCode.Task>> threadTasks;
  list<Integer> rootNodes;
  array<tuple<HpcOmSimCode.Task, Integer>> allTasks;
  list<tuple<HpcOmSimCode.Task,Integer>> nodeList_refCount; //list of nodes which are ready to schedule
  list<HpcOmSimCode.Task> nodeList;
algorithm
  oSchedule := matchcontinue(iTaskGraph,iTaskGraphMeta,iNumberOfThreads,iSccSimEqMapping)
    case(_,_,_,_)
      equation
        print("Funktionsaufruf!");
        (xadj,adjncy,vwgt,adjwgt) = HpcOmTaskGraph.preparehMetis(iTaskGraph,iTaskGraphMeta);
        extInfo = HpcOmSchedulerExt.schedulehMetis(xadj, adjncy, vwgt, adjwgt, iNumberOfThreads);
        extInfoArr = listArray(extInfo);
        print("Hier geht MetaModelica los!\n");
        print("External scheduling info: " +& stringDelimitList(List.map(extInfo, intString), ",") +& "\n");
        true = intEq(arrayLength(iTaskGraph),arrayLength(extInfoArr));

        taskGraphT = HpcOmTaskGraph.transposeTaskGraph(iTaskGraph);
        rootNodes = HpcOmTaskGraph.getRootNodes(iTaskGraph);
        allTasks = convertTaskGraphToTasks(taskGraphT,iTaskGraphMeta,convertNodeToTask);
        nodeList_refCount = List.map1(rootNodes, getTaskByIndex, allTasks);
        nodeList = List.map(nodeList_refCount, Util.tuple21);
        nodeList = List.sort(nodeList, compareTasksByWeighting);
        threadTasks = arrayCreate(iNumberOfThreads,{});
        tmpSchedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,{});
        tmpSchedule = createExtSchedule1(nodeList,extInfoArr, iTaskGraph, taskGraphT, allTasks, iSccSimEqMapping, getLocksByPredecessorList, tmpSchedule);
        tmpSchedule = addSuccessorLocksToSchedule(iTaskGraph,allTasks,addReleaseLocksToSchedule,tmpSchedule);
        //printSchedule(tmpSchedule);
      then tmpSchedule;
    else
      equation
        print("HpcOmScheduler.createExtCSchedule not every node has a scheduler-info.\n");
      then fail();
  end matchcontinue;
end createhmetSchedule;

//--------------------
// External Scheduling //TODO: Rename to Yed Scheduling
//--------------------
public function createExtSchedule "function createExtSchedule
  author: marcusw
  Creates a scheduling by reading the required informations from a graphml-file."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer iNumberOfThreads;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input String iGraphMLFile; //the file containing schedule-informations
  output HpcOmSimCode.Schedule oSchedule;
protected
  list<Integer> extInfo;
  array<Integer> extInfoArr;
  HpcOmTaskGraph.TaskGraph taskGraphT;
  HpcOmSimCode.Schedule tmpSchedule;
  array<list<HpcOmSimCode.Task>> threadTasks;
  list<Integer> rootNodes;
  array<tuple<HpcOmSimCode.Task, Integer>> allTasks;
  list<tuple<HpcOmSimCode.Task,Integer>> nodeList_refCount; //list of nodes which are ready to schedule
  list<HpcOmSimCode.Task> nodeList;
algorithm
  oSchedule := matchcontinue(iTaskGraph,iTaskGraphMeta,iNumberOfThreads,iSccSimEqMapping,iGraphMLFile)
    case(_,_,_,_,_)
      equation
        extInfo = HpcOmSchedulerExt.readScheduleFromGraphMl(iGraphMLFile);
        extInfoArr = listArray(extInfo);
        true = intEq(arrayLength(iTaskGraph),arrayLength(extInfoArr));
        //print("External scheduling info: " +& stringDelimitList(List.map(extInfo, intString), ",") +& "\n");
        taskGraphT = HpcOmTaskGraph.transposeTaskGraph(iTaskGraph);
        rootNodes = HpcOmTaskGraph.getRootNodes(iTaskGraph);
        allTasks = convertTaskGraphToTasks(taskGraphT,iTaskGraphMeta,convertNodeToTask);
        nodeList_refCount = List.map1(rootNodes, getTaskByIndex, allTasks);
        nodeList = List.map(nodeList_refCount, Util.tuple21);
        nodeList = List.sort(nodeList, compareTasksByWeighting);
        threadTasks = arrayCreate(iNumberOfThreads,{});
        tmpSchedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,{});
        tmpSchedule = createExtSchedule1(nodeList,extInfoArr, iTaskGraph, taskGraphT, allTasks, iSccSimEqMapping, getLocksByPredecessorList, tmpSchedule);
        tmpSchedule = addSuccessorLocksToSchedule(iTaskGraph,allTasks,addReleaseLocksToSchedule,tmpSchedule);
        //printSchedule(tmpSchedule);
      then tmpSchedule;
    else
      equation
        print("HpcOmScheduler.createExtSchedule not every node has a scheduler-info.\n");
      then fail();
  end matchcontinue;
end createExtSchedule;

protected function createExtSchedule1
  input list<HpcOmSimCode.Task> iNodeList; //the sorted nodes -> this method will pick the first task
  input array<Integer> iThreadAssignments; //assignment taskIdx -> threadIdx
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllTasks; //all tasks with ref-counter
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input FuncType iLockWithPredecessorHandler; //Function which handles locks to all predecessors
  input HpcOmSimCode.Schedule iSchedule;
  output HpcOmSimCode.Schedule oSchedule;

  partial function FuncType
    input Integer iNodeIdx;
    input Integer iThreadIdx;
    input list<tuple<HpcOmSimCode.Task,Integer>> iPredecessors;
    output list<HpcOmSimCode.Task> oTasks; //lock tasks
    output list<String> oLockNames; //lock names
  end FuncType;
protected
  HpcOmSimCode.Task head, newTask;
  Integer newTaskRefCount;
  list<HpcOmSimCode.Task> rest;
  Real lastChildFinishTime; //The time when the last child has finished calculation
  HpcOmSimCode.Task lastChild;
  list<tuple<HpcOmSimCode.Task,Integer>> predecessors, successors;
  list<Integer> successorIdc;
  list<String> lockIdc, newLockIdc;
  array<Real> threadFinishTimes;
  Integer firstEq;
  array<list<HpcOmSimCode.Task>> allThreadTasks;
  list<HpcOmSimCode.Task> threadTasks, lockTasks;
  Integer threadId;
  Real threadFinishTime;
  array<Real> tmpThreadReadyTimes;
  list<HpcOmSimCode.Task> tmpNodeList;
  Integer weighting;
  Integer index;
  Real calcTime;
  list<Integer> eqIdc, simEqIdc;
  array<tuple<HpcOmSimCode.Task,Integer>> tmpAllTasks;
  HpcOmSimCode.Schedule tmpSchedule;
algorithm
  oSchedule := matchcontinue(iNodeList,iThreadAssignments, iTaskGraph, iTaskGraphT, iAllTasks, iSccSimEqMapping, iLockWithPredecessorHandler, iSchedule)
    case((head as HpcOmSimCode.CALCTASK(weighting=weighting,index=index,calcTime=calcTime,eqIdc=(eqIdc as firstEq::_)))::rest,_,_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE(threadTasks=allThreadTasks, lockIdc=lockIdc))
      equation
        //get all predecessors (childs)
        (predecessors, _) = getSuccessorsByTask(head, iTaskGraphT, iAllTasks);
        (successors, successorIdc) = getSuccessorsByTask(head, iTaskGraph, iAllTasks);
        true = List.isNotEmpty(predecessors); //in this case the node has predecessors
        //print("Handle task " +& intString(index) +& " with " +& intString(listLength(predecessors)) +& " child nodes and " +& intString(listLength(successorIdc)) +& " parent nodes.\n");

        //find thread for scheduling
        threadId = arrayGet(iThreadAssignments,index);
        threadFinishTime = -1.0;
        threadTasks = arrayGet(allThreadTasks,threadId);

        //find all predecessors which are scheduled to another thread and thus require a lock
        (lockTasks,newLockIdc) = iLockWithPredecessorHandler(index,threadId,predecessors);
        lockIdc = listAppend(lockIdc,newLockIdc);
        //threadTasks = listAppend(List.map(newLockIdc,convertLockIdToAssignTask), threadTasks);
        threadTasks = listAppend(lockTasks, threadTasks);

        //print("Eq idc: " +& stringDelimitList(List.map(eqIdc, intString), ",") +& "\n");
        simEqIdc = List.map(List.map1(eqIdc,getSimEqSysIdxForComp,iSccSimEqMapping), List.last);
        //print("Simcodeeq idc: " +& stringDelimitList(List.map(simEqIdc, intString), ",") +& "\n");
        //simEqIdc has the wrong order -> reverse list
        simEqIdc = listReverse(simEqIdc);
        newTask = HpcOmSimCode.CALCTASK(weighting,index,calcTime,threadFinishTime,threadId,simEqIdc);
        threadTasks = newTask::threadTasks;
        allThreadTasks = arrayUpdate(allThreadTasks,threadId,threadTasks);
        //print("Successors: " +& stringDelimitList(List.map(successorIdc, intString), ",") +& "\n");
        //add all successors with refcounter = 1
        (tmpAllTasks,tmpNodeList) = updateRefCounterBySuccessorIdc(iAllTasks,successorIdc,{});
        tmpNodeList = listAppend(tmpNodeList, rest);
        tmpNodeList = List.sort(tmpNodeList, compareTasksByWeighting);
        ((_,newTaskRefCount)) = arrayGet(iAllTasks,index);
        _ = arrayUpdate(iAllTasks,index,(newTask,newTaskRefCount));
        tmpSchedule = createExtSchedule1(tmpNodeList,iThreadAssignments,iTaskGraph, iTaskGraphT, tmpAllTasks, iSccSimEqMapping, iLockWithPredecessorHandler, HpcOmSimCode.THREADSCHEDULE(allThreadTasks,lockIdc));
      then tmpSchedule;
    case((head as HpcOmSimCode.CALCTASK(weighting=weighting,index=index,calcTime=calcTime,eqIdc=(eqIdc as firstEq::_)))::rest,_,_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE(threadTasks=allThreadTasks,lockIdc=lockIdc))
      equation
        (successors, successorIdc) = getSuccessorsByTask(head, iTaskGraph, iAllTasks);
        //print("Handle task " +& intString(index) +& " with 0 child nodes and " +& intString(listLength(successorIdc)) +& " parent nodes.\n");
        //print("Parents: {" +& stringDelimitList(List.map(successorIdc, intString), ",") +& "}\n");

        //find thread for scheduling
        threadId = arrayGet(iThreadAssignments,index);
        threadFinishTime = -1.0;
        threadTasks = arrayGet(allThreadTasks,threadId);

        simEqIdc = List.flatten(List.map1(eqIdc,getSimEqSysIdxForComp,iSccSimEqMapping));
        //simEqIdc has the wrong order -> reverse list
        simEqIdc = listReverse(simEqIdc);
        newTask = HpcOmSimCode.CALCTASK(weighting,index,calcTime,threadFinishTime,threadId,simEqIdc);
        allThreadTasks = arrayUpdate(allThreadTasks,threadId,newTask::threadTasks);
        //print("Successors: " +& stringDelimitList(List.map(successorIdc, intString), ",") +& "\n");
        //add all successors with refcounter = 1
        (tmpAllTasks,tmpNodeList) = updateRefCounterBySuccessorIdc(iAllTasks,successorIdc,{});
        tmpNodeList = listAppend(tmpNodeList, rest);
        tmpNodeList = List.sort(tmpNodeList, compareTasksByWeighting);
        ((_,newTaskRefCount)) = arrayGet(iAllTasks,index);
        _ = arrayUpdate(iAllTasks,index,(newTask,newTaskRefCount));
        tmpSchedule = createExtSchedule1(tmpNodeList,iThreadAssignments,iTaskGraph, iTaskGraphT, tmpAllTasks, iSccSimEqMapping, iLockWithPredecessorHandler, HpcOmSimCode.THREADSCHEDULE(allThreadTasks,lockIdc));
      then tmpSchedule;
    case({},_,_,_,_,_,_,_) then iSchedule;
    else
      equation
        print("HpcOmScheduler.createExtSchedule1 failed. Tasks in List:\n");
        printTaskList(iNodeList);
      then fail();
  end matchcontinue;
end createExtSchedule1;

//---------------------------------
// Task Duplication-based Scheduler
//---------------------------------

public function createTDSschedule"task duplication schedule by Samantha Ranaweera and Dharma P. Agrawal,
see:
'A Task Duplication Based Scheduling Algorithm for Heterogeneous Systems'
or
'A Scalable Task Duplication Based Scheduling Algorithm for Heterogeneous Systems'
including slight adaptations from my side, since in reality, nothing is exactly the same like the smart guys thought of.
notation: est:earliest starting time, ect: earliest completion time, last:latest allowable starting time, lact: latest allowable completion time, fpred:favourite predecessor
author: Waurich TUD 2015-05"
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer numProc;
  input array<list<Integer>> iSccSimEqMapping;
  input SimCode.SimCode iSimCode;
  output HpcOmSimCode.Schedule oSchedule;
  output SimCode.SimCode oSimCode;
  output HpcOmTaskGraph.TaskGraph oTaskGraph;
  output HpcOmTaskGraph.TaskGraphMeta oTaskGraphMeta;
  output array<list<Integer>> oSccSimEqMapping;
protected
  Integer size;
  list<Integer> queue;
  list<Real> levels;
  array<Real> ectArray,tdsLevelArray,lastArray,lactArray;
  array<Integer> fpredArray;
  list<list<Integer>> initClusters;
  HpcOmTaskGraph.TaskGraph taskGraphT;
algorithm
  //compute the necessary node parameters
  size := arrayLength(iTaskGraph);
  taskGraphT := BackendDAEUtil.transposeMatrix(iTaskGraph,size);
  (_,_,ectArray) := computeGraphValuesBottomUp(iTaskGraph,iTaskGraphMeta);
  (_,lastArray,lactArray,tdsLevelArray) := computeGraphValuesTopDown(iTaskGraph,iTaskGraphMeta);
  fpredArray := computeFavouritePred(iTaskGraph,iTaskGraphMeta,ectArray); //the favourite predecessor of each node
  (levels,queue) := quicksortWithOrder(arrayList(tdsLevelArray));
  initClusters := createTDSInitialCluster(iTaskGraph,taskGraphT,iTaskGraphMeta,lastArray,lactArray,fpredArray,queue);
  //print("initClusters:\n"+&stringDelimitList(List.map(initClusters,intListString),"\n")+&"\n");
  (oSchedule,oSimCode,oTaskGraph,oTaskGraphMeta,oSccSimEqMapping) := createTDSschedule1(initClusters,iTaskGraph,taskGraphT,iTaskGraphMeta,tdsLevelArray,numProc,iSccSimEqMapping,iSimCode);
end createTDSschedule;

protected function insertLocksInSchedule
  input HpcOmSimCode.Schedule iSchedule;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input array<Integer> taskAss;
  input array<list<Integer>> procAss;
  output HpcOmSimCode.Schedule oSchedule;
protected
  array<list<HpcOmSimCode.Task>> threadTasks;
  list<list<HpcOmSimCode.Task>> threads;
  list<String> lockIdc;
algorithm
  HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks) := iSchedule;
  threads := arrayList(threadTasks);
  ((threads,lockIdc)) := List.fold4(threads,insertLocksInSchedule1,iTaskGraph,iTaskGraphT,taskAss,procAss,({},{}));
  threads := List.filterOnTrue(threads,List.isNotEmpty);
  threads := List.map(threads,listReverse);
  threads := listReverse(threads);
  threadTasks := listArray(threads);
  lockIdc := List.unique(lockIdc);
  oSchedule := HpcOmSimCode.THREADSCHEDULE(threadTasks, lockIdc);
end insertLocksInSchedule;

protected function insertLocksInSchedule1
  input list<HpcOmSimCode.Task> threadsIn;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input array<Integer> taskAss;
  input array<list<Integer>> procAss;
  input tuple<list<list<HpcOmSimCode.Task>>,list<String>> foldIn;
  output tuple<list<list<HpcOmSimCode.Task>>,list<String>> foldOut;
algorithm
  foldOut := matchcontinue(threadsIn,iTaskGraph,iTaskGraphT,taskAss,procAss,foldIn)
    local
      Integer idx,thr;
      list<Integer> preds,succs,predThr,succThr;
      list<HpcOmSimCode.Task> thread,rest,relLocks,assLocks,tasks;
      list<list<HpcOmSimCode.Task>> threads;
      HpcOmSimCode.Task task;
      list<String> lockIdc,assLockStrs,relLockStrs;
    case({},_,_,_,_,(threads,lockIdc))
      equation
        threads = {}::threads;
      then ((threads,lockIdc));
    case(HpcOmSimCode.CALCTASK(index=idx,threadIdx=thr)::rest,_,_,_,_,(threads,lockIdc))
      equation
        task = List.first(threadsIn);
        //print("node "+&intString(idx)+&"\n");
        preds = arrayGet(iTaskGraphT,idx);
        succs = arrayGet(iTaskGraph,idx);
        //print("all preds "+&intListString(preds)+&"\n");
        //print("all succs "+&intListString(succs)+&"\n");
        predThr = List.map1(preds,Util.arrayGetIndexFirst,taskAss);
        succThr = List.map1(succs,Util.arrayGetIndexFirst,taskAss);
        (_,preds) = List.filter1OnTrueSync(predThr,intNe,thr,preds);
        (_,succs) = List.filter1OnTrueSync(succThr,intNe,thr,succs);
        //print("other preds "+&intListString(preds)+&"\n");
        //print("other succs "+&intListString(succs)+&"\n");
        relLockStrs = List.map(succs,intString);
        relLockStrs = List.map1r(relLockStrs,stringAppend,intString(idx)+&"_");
        assLockStrs = List.map(preds,intString);
        assLockStrs = List.map1(assLockStrs,stringAppend,"_"+&intString(idx));
        //print("assLockStrs "+&stringDelimitList(assLockStrs,"  ;  ")+&"\n");
        //print("relLockStrs "+&stringDelimitList(relLockStrs,"  ;  ")+&"\n");
        assLocks = List.map(assLockStrs,convertLockIdToAssignTask);
        relLocks = List.map(relLockStrs,convertLockIdToReleaseTask);
        //tasks = task::assLocks;
        tasks = listAppend(relLocks,{task});
        tasks = listAppend(tasks,assLocks);
        thread = Debug.bcallret1(List.isNotEmpty(threads),List.first,threads,{});
        thread = listAppend(tasks,thread);
        threads = Debug.bcallret3(List.isNotEmpty(threads),List.replaceAt,thread,0,threads,{thread});
        //_ = printThreadSchedule(thread,thr);
        lockIdc = listAppend(relLockStrs,lockIdc);
        lockIdc = listAppend(assLockStrs,lockIdc);
        ((threads,lockIdc)) = insertLocksInSchedule1(rest,iTaskGraph,iTaskGraphT,taskAss,procAss,(threads,lockIdc));
      then ((threads,lockIdc));
  end matchcontinue;
end insertLocksInSchedule1;

protected function createTDSschedule1"takes the initial Cluster and compactes or duplicates them to the given number of threads.
author:Waurich TUD 2014-05"
  input list<list<Integer>> clustersIn;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Real> TDSLevel;
  input Integer numProc;
  input array<list<Integer>> iSccSimEqMapping;
  input SimCode.SimCode iSimCode;
  output HpcOmSimCode.Schedule oSchedule;
  output SimCode.SimCode oSimCode;
  output HpcOmTaskGraph.TaskGraph oTaskGraph;
  output HpcOmTaskGraph.TaskGraphMeta oTaskGraphMeta;
  output array<list<Integer>> oSccSimEqMapping;
algorithm
  (oSchedule,oSimCode,oTaskGraph,oTaskGraphMeta,oSccSimEqMapping) := matchcontinue(clustersIn,iTaskGraph,iTaskGraphT,iTaskGraphMeta,TDSLevel,numProc,iSccSimEqMapping,iSimCode)
    local
      Integer sizeTasks, numDupl, threadIdx, compIdx, simVarIdx, simEqSysIdx, taskIdx, lsIdx, nlsIdx, mIdx;
      array<Integer> taskAss,taskDuplAss,nodeMark;
      array<list<Integer>> procAss, sccSimEqMap, inComps, comps;
      array<tuple<Integer,Real>> exeCosts;
      array<list<tuple<Integer,Integer,Integer>>> commCosts;
      array<tuple<Integer,Integer,Integer>> varCompMapping,eqCompMapping,mapDupl;
      tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> idcs;
      list<Integer> order, rootNodes;
      array<String> nodeNames, nodeDescs;
      list<list<Integer>> clusters, duplSccSimEqMap, duplComps;
      HpcOmSimCode.Schedule schedule;
      SimCode.ModelInfo modelInfo;
      HpcOmTaskGraph.TaskGraph taskGraph, taskGraphT;
      HpcOmTaskGraph.TaskGraphMeta meta;
      SimCode.SimCode simCode;
      SimCode.SimVars simVars;
      list<SimCode.SimVar> algVars;
      array<list<HpcOmSimCode.Task>> threadTask;
      list<HpcOmSimCode.Task> removeLocks;
      list<list<SimCode.SimEqSystem>> odes;
      list<SimCode.SimEqSystem> jacobianEquations;
    case(_,_,_,_,_,_,_,_)
      equation
        // we need cluster duplication, repeat until numProc=num(clusters)
        true = listLength(clustersIn) < numProc;
        print("There are less initial clusters than processors. we need duplication, but since this is a rare case, it is not done. Less processors are used.\n");
        clusters = List.map(clustersIn,listReverse);
        Flags.setConfigInt(Flags.NUM_PROC,listLength(clustersIn));
        (schedule,simCode,taskGraph,meta,sccSimEqMap) = createTDSschedule1(clusters,iTaskGraph,iTaskGraphT,iTaskGraphMeta,TDSLevel,listLength(clustersIn),iSccSimEqMapping,iSimCode);
      then
        (schedule,simCode,taskGraph,meta,sccSimEqMap);
    case(_,_,_,_,_,_,_,_)
      equation
        // we need cluster compaction, repeat until numProc=num(clusters)
        true = listLength(clustersIn) > numProc;
        clusters = createTDSCompactClusters(clustersIn,iTaskGraph,iTaskGraphMeta,TDSLevel,numProc);
        (schedule,simCode,taskGraph,meta,sccSimEqMap) = createTDSschedule1(clusters,iTaskGraph,iTaskGraphT,iTaskGraphMeta,TDSLevel,numProc,iSccSimEqMapping,iSimCode);
      then
        (schedule,simCode,taskGraph,meta,sccSimEqMap);
    case(_,_,_,_,_,_,_,_)
      equation
        // the clusters can be scheduled,
        true = listLength(clustersIn) == numProc;
        // order the tasks in the clusters
        clusters = List.map1(clustersIn,createTDSSortCompactClusters,TDSLevel);
        print("clusters:\n"+&stringDelimitList(List.map(clusters,intListString),"\n")+&"\n");

        // extract object stuff
        SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(vars=simVars), odeEquations=odes, jacobianEquations=jacobianEquations) = iSimCode;
        SimCode.SIMVARS(algVars=algVars) = simVars;
        HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,varCompMapping=varCompMapping,eqCompMapping=eqCompMapping,rootNodes=rootNodes,nodeNames=nodeNames,nodeDescs=nodeDescs,exeCosts=exeCosts,commCosts=commCosts,nodeMark=nodeMark) = iTaskGraphMeta;

        //dumping stuff-------------------------
        print("simCode1 \n");
        SimCodeUtil.dumpSimCode(iSimCode);
        print("sccSimEqMap1\n");
        HpcOmSimCodeMain.dumpSccSimEqMapping(iSccSimEqMapping);
        print("inComps1\n");
        HpcOmSimCodeMain.dumpSccSimEqMapping(inComps);
        //--------------------------------------

        // prepare everything  in order to create new variables and equations for the duplicated tasks
        sizeTasks = List.fold(List.map(clusters,listLength),intAdd,0);
        taskAss = arrayCreate(sizeTasks,-1);
        procAss = arrayCreate(listLength(clusters),{});
        taskGraph = arrayCreate(sizeTasks,{});
        //taskGraph = Util.arrayCopy(iTaskGraph,taskGraph);// the new taskGraph
        taskDuplAss = arrayCreate(sizeTasks,-1); // the original task for every task (for not duplicated tasks, its itself)
        threadTask = arrayCreate(numProc,{});
        schedule = HpcOmSimCode.THREADSCHEDULE(threadTask,{});
        duplSccSimEqMap = {};  // a list that is later appended to the sccSimEqMapping
        duplComps = {}; // a list that is later appended to the inComps
        threadIdx = 1;
        compIdx = arrayLength(iSccSimEqMapping)+1;  // the next available component index
        taskIdx = arrayLength(iTaskGraph)+1;
        simVarIdx = List.fold(List.map(algVars,SimCodeUtil.varIndex),intMax,0)+1;// the next available simVar index
        simEqSysIdx = SimCodeUtil.getMaxSimEqSystemIndex(iSimCode)+1;// the next available simEqSys index
        print("highest simEqSysIdx: "+&intString(simEqSysIdx)+&"\n");
        lsIdx = List.fold(List.map(List.flatten(odes),SimCodeUtil.getLSindex),intMax,0)+1;// the next available linear system index
        nlsIdx = List.fold(List.map(List.flatten(odes),SimCodeUtil.getNLSindex),intMax,0)+1;// the next available nonlinear system index
        mIdx = List.fold(List.map(List.flatten(odes),SimCodeUtil.getMixedindex),intMax,0)+1;// the next available mixed system  index

        //traverse the clusters and duplicate tasks if needed
        (taskAss,procAss,taskGraph,taskDuplAss,idcs,simCode,schedule,duplSccSimEqMap,duplComps) = createTDSduplicateTasks(clusters,taskAss,procAss,(threadIdx,taskIdx,compIdx,simVarIdx,simEqSysIdx,lsIdx,nlsIdx,mIdx),iTaskGraph,iTaskGraphT,taskGraph,taskDuplAss,iTaskGraphMeta,iSimCode,schedule,iSccSimEqMapping,duplSccSimEqMap,duplComps);

        //update stuff
        simCode = createTDSupdateModelInfo(simCode,idcs);
        numDupl = List.fold(List.map(duplComps,listLength),intAdd,0);
        procAss = Util.arrayMap(procAss,listReverse);
        sccSimEqMap = Util.arrayAppend(iSccSimEqMapping,listArray(listReverse(duplSccSimEqMap)));
        comps = Util.arrayAppend(inComps,listArray(listReverse(duplComps)));
        varCompMapping = Util.arrayAppend(varCompMapping,arrayCreate(numDupl,(0,0,0)));
        eqCompMapping = Util.arrayAppend(eqCompMapping,arrayCreate(numDupl,(0,0,0)));
        nodeNames = Util.arrayAppend(nodeNames,arrayCreate(numDupl,"duplicated"));
        nodeDescs = Util.arrayAppend(nodeDescs,arrayCreate(numDupl,"duplicated"));
        exeCosts = Util.arrayAppend(exeCosts,arrayCreate(numDupl,(1,1.0)));
        nodeMark = Util.arrayAppend(nodeMark,arrayCreate(numDupl,-1));
        meta = HpcOmTaskGraph.TASKGRAPHMETA(comps,varCompMapping,eqCompMapping,rootNodes,nodeNames,nodeDescs,exeCosts,commCosts,nodeMark);

        // insert Locks
        taskGraphT = BackendDAEUtil.transposeMatrix(taskGraph,arrayLength(taskGraph));
        schedule = insertLocksInSchedule(schedule,taskGraph,taskGraphT,taskAss,procAss);

        //dumping stuff-------------------------
        print("simCode 2\n");
        SimCodeUtil.dumpSimCode(simCode);
        print("sccSimEqMap2\n");
        HpcOmSimCodeMain.dumpSccSimEqMapping(sccSimEqMap);
        print("inComps2\n");
        HpcOmSimCodeMain.dumpSccSimEqMapping(comps);
        print("the taskAss2: "+&stringDelimitList(List.map(arrayList(taskAss),intString),"\n")+&"\n");
        print("the procAss2: "+&stringDelimitList(List.map(arrayList(procAss),intListString),"\n")+&"\n");
        printSchedule(schedule);
        //HpcOmTaskGraph.printTaskGraph(taskGraph);
        //--------------------------------------

      then
        (schedule,simCode,taskGraph,meta,sccSimEqMap);
    else
      equation
        print("createTDSschedule1 failed!\n");
      then fail();
  end matchcontinue;
end createTDSschedule1;

protected function createTDSupdateModelInfo"updated information in the SimCode.ModelInfo e.g.the number of variables,numLS, numNLS,"
  input SimCode.SimCode simCodeIn;
  input tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> idcs;
  output SimCode.SimCode simCodeOut;
protected
  Integer numZeroCrossings,numTimeEvents,numRelations,numMathEventFunctions,numStateVars,numAlgVars,numDiscreteReal,numIntAlgVars,numBoolAlgVars,numAlgAliasVars,numIntAliasVars,
  numBoolAliasVars,numParams,numIntParams,numBoolParams,numOutVars,numInVars,numInitialEquations,numInitialAlgorithms,numInitialResiduals,numExternalObjects,numStringAlgVars,
  numStringParamVars,numStringAliasVars,numEquations,numLinearSystems,numNonLinearSystems,numMixedSystems,numStateSets,numOptimizeConstraints;
  Integer threadIdx,taskIdx,compIdx,simVarIdx,simEqSysIdx,lsIdx,nlsIdx,mIdx;
  SimCode.ModelInfo modelInfo;
  Absyn.Path name;
  String description;
  String directory;
  SimCode.VarInfo varInfo;
  SimCode.SimVars vars;
  list<SimCode.Function> functions;
  list<SimCode.SimVar> algVars,stateVars;
  list<String> labels;
algorithm
  // get the data
  (threadIdx,taskIdx,compIdx,simVarIdx,simEqSysIdx,lsIdx,nlsIdx,mIdx) := idcs;
  SimCode.SIMCODE(modelInfo = modelInfo) := simCodeIn;
  SimCode.MODELINFO(name,description,directory,varInfo,vars,functions,labels) := modelInfo;
  SimCode.SIMVARS(stateVars=stateVars, algVars = algVars) := vars;
  SimCode.VARINFO(numZeroCrossings,numTimeEvents,numRelations,numMathEventFunctions,numStateVars,numAlgVars,numDiscreteReal,numIntAlgVars,numBoolAlgVars,numAlgAliasVars,numIntAliasVars,
  numBoolAliasVars,numParams,numIntParams,numBoolParams,numOutVars,numInVars,numInitialEquations,numInitialAlgorithms,numInitialResiduals,numExternalObjects,numStringAlgVars,numStringParamVars,
  numStringAliasVars,numEquations,numLinearSystems,numNonLinearSystems,numMixedSystems,numStateSets,numOptimizeConstraints) := varInfo;
  // get new values
  numStateVars := listLength(stateVars);
  numAlgVars := listLength(algVars);
  numLinearSystems := Util.if_(intEq(numLinearSystems,0),0,lsIdx);
  numNonLinearSystems := Util.if_(intEq(numNonLinearSystems,0),0,nlsIdx);
  //numMixedSystems := mIdx;
  //update objects
  varInfo := SimCode.VARINFO(numZeroCrossings,numTimeEvents,numRelations,numMathEventFunctions,numStateVars,numAlgVars,numDiscreteReal,numIntAlgVars,numBoolAlgVars,numAlgAliasVars,numIntAliasVars,
  numBoolAliasVars,numParams,numIntParams,numBoolParams,numOutVars,numInVars,numInitialEquations,numInitialAlgorithms,numInitialResiduals,numExternalObjects,numStringAlgVars,numStringParamVars,
  numStringAliasVars,numEquations,numLinearSystems,numNonLinearSystems,numMixedSystems,numStateSets,numOptimizeConstraints);
  modelInfo := SimCode.MODELINFO(name,description,directory,varInfo,vars,functions,labels);
  simCodeOut := SimCodeUtil.replaceModelInfo(modelInfo,simCodeIn);
end createTDSupdateModelInfo;

protected function createTDSduplicateTasks"traverses the clusters, duplicate the tasks that have been assigned to another thread before.
author: Waurich TUD 2014-05"
  input list<list<Integer>> clustersIn;
  input array<Integer> taskAssIn;
  input array<list<Integer>> procAssIn;
  input tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> idcsIn;
  input HpcOmTaskGraph.TaskGraph taskGraphOrig;
  input HpcOmTaskGraph.TaskGraph taskGraphTOrig;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input array<Integer> taskDuplAssIn;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input SimCode.SimCode simCodeIn;
  input HpcOmSimCode.Schedule scheduleIn;
  input array<list<Integer>> sccSimEqMappingIn;
  input list<list<Integer>> duplSccSimEqMapIn;
  input list<list<Integer>> duplCompsIn;
  output array<Integer> taskAssOut;
  output array<list<Integer>> procAssOut;
  output HpcOmTaskGraph.TaskGraph taskGraphOut;
  output array<Integer> taskDuplAssOut;
  output tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> idcsOut;
  output SimCode.SimCode simCodeOut;
  output HpcOmSimCode.Schedule scheduleOut;
  output list<list<Integer>> duplSccSimEqMapOut;
  output list<list<Integer>> duplCompsOut;
algorithm
  (taskAssOut,procAssOut,taskGraphOut,taskDuplAssOut,idcsOut,simCodeOut,scheduleOut,duplSccSimEqMapOut,duplCompsOut) := matchcontinue(clustersIn,taskAssIn,procAssIn,idcsIn,taskGraphOrig,taskGraphTOrig,taskGraphIn,taskDuplAssIn,iTaskGraphMeta,simCodeIn,scheduleIn,sccSimEqMappingIn,duplSccSimEqMapIn,duplCompsIn)
    local
      Integer threadIdx,compIdx,simVarIdx,simEqSysIdx,taskIdx,lsIdx,nlsIdx,mIdx;
      list<Integer> cluster;
      list<String> lockIdc;
      list<list<Integer>> rest, duplSccSimEqMap, duplComps;
      array<Integer> taskAss, taskDuplAss;
      array<list<Integer>> sccSimEqMap ,procAss;
      tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> idcs;
      BackendDAE.BackendDAE dae;
      BackendVarTransform.VariableReplacements repl;
      SimCode.SimCode simCode;
      HpcOmSimCode.Schedule schedule;
      HpcOmTaskGraph.TaskGraph taskGraph;
      list<HpcOmSimCode.Task> thread;
      array<list<HpcOmSimCode.Task>> threadTasks;
      list<list<SimCode.SimEqSystem>> odes;
    case({},_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
      then
        (taskAssIn,procAssIn,taskGraphIn,taskDuplAssIn,idcsIn,simCodeIn,scheduleIn,duplSccSimEqMapIn,duplCompsIn);
    case(cluster::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        repl = BackendVarTransform.emptyReplacements();
        //traverse the cluster and build schedule
        (taskAss,procAss,taskGraph,taskDuplAss,thread,(threadIdx,taskIdx,compIdx,simVarIdx,simEqSysIdx,lsIdx,nlsIdx,mIdx),simCode,duplSccSimEqMap,duplComps) = createTDSduplicateTasks1(cluster,clustersIn,repl,taskAssIn,procAssIn,{},idcsIn,taskGraphOrig,taskGraphTOrig,taskGraphIn,taskDuplAssIn,iTaskGraphMeta,simCodeIn,sccSimEqMappingIn,duplSccSimEqMapIn,duplCompsIn);
        SimCode.SIMCODE(odeEquations=odes) = simCode;
        print("the simEqSysts after cluster: "+&intString(threadIdx)+&" \n"+&stringDelimitList(List.map(odes,SimCodeUtil.dumpSimEqSystemLst),"\n")+&"\n");


        HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,lockIdc=lockIdc) = scheduleIn;
        threadTasks = arrayUpdate(threadTasks,threadIdx,listReverse(thread));
        schedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,lockIdc);
        threadIdx = threadIdx+1;
        (taskAss,procAss,taskGraph,taskDuplAss,idcs,simCode,schedule,duplSccSimEqMap,duplComps) = createTDSduplicateTasks(rest,taskAss,procAss,(threadIdx,taskIdx,compIdx,simVarIdx,simEqSysIdx,lsIdx,nlsIdx,mIdx),taskGraphOrig,taskGraphTOrig,taskGraph,taskDuplAss,iTaskGraphMeta,simCode,schedule,sccSimEqMappingIn,duplSccSimEqMap,duplComps);
      then
        (taskAssIn,procAssIn,taskGraph,taskDuplAss,idcs,simCode,schedule,duplSccSimEqMap,duplComps);
  end matchcontinue;
end createTDSduplicateTasks;

protected function createTDSduplicateTasks1"traverses one cluster.No locks are added.
author: Waurich TUD 2014-05"
  input list<Integer> clusterIn;
  input list<list<Integer>> allCluster;
  input BackendVarTransform.VariableReplacements replIn;
  input array<Integer> taskAssIn;
  input array<list<Integer>> procAssIn;
  input list<HpcOmSimCode.Task> threadIn;
  input tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> idcsIn; // threadIdx,taskIdx,compIdx,simVarIdx,simEqSysIdx,lsIdx,nlsIdx,mIdx
  input HpcOmTaskGraph.TaskGraph taskGraphOrig;
  input HpcOmTaskGraph.TaskGraph taskGraphTOrig;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input array<Integer> taskDuplAssIn;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input SimCode.SimCode simCodeIn;
  input array<list<Integer>> sccSimEqMappingIn;
  input list<list<Integer>> duplSccSimEqMapIn;
  input list<list<Integer>> duplCompsIn;
  output array<Integer> taskAssOut;
  output array<list<Integer>> procAssOut;
  output HpcOmTaskGraph.TaskGraph taskGraphOut;
  output array<Integer> taskDuplAssOut;
  output list<HpcOmSimCode.Task> threadOut;
  output tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> idcsOut; // threadIdx,taskIdx,compIdx,simVarIdx,simEqSysIdx,lsIdx,nlsIdx,mIdx
  output SimCode.SimCode simCodeOut;
  output list<list<Integer>> duplSccSimEqMapOut;
  output list<list<Integer>> duplCompsOut;
algorithm
  (taskAssOut,procAssOut,taskGraphOut,taskDuplAssOut,threadOut,idcsOut,simCodeOut,duplSccSimEqMapOut,duplCompsOut) := matchcontinue(clusterIn,allCluster,replIn,taskAssIn,procAssIn,threadIn,idcsIn,taskGraphOrig,taskGraphTOrig,taskGraphIn,taskDuplAssIn,iTaskGraphMeta,simCodeIn,sccSimEqMappingIn,duplSccSimEqMapIn,duplCompsIn)
    local
      Integer node,ass,simEqIdx,threadIdx,compIdx,simVarIdx,simEqSysIdx,taskIdx,lsIdx,nlsIdx,mIdx;
      list<Integer> rest,comps, simEqs, sameProcTasks, taskLst, origPredTasks, clPredTasks, duplPredTasks, clTasks, pos;
      list<list<Integer>> duplSccSimEqMap,duplComps, simEqsLst;
      array<Integer> taskAss,taskDuplAss;
      array<list<Integer>> procAss, sccSimEqMapping, inComps;
      tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> idcs;
      BackendDAE.BackendDAE dae;
      BackendVarTransform.VariableReplacements repl;
      HpcOmSimCode.Task task;
      HpcOmTaskGraph.TaskGraph taskGraph;
      SimCode.SimCode simCode;
      list<HpcOmSimCode.Task> thread;
      list<list<SimCode.SimEqSystem>> odes;
      list<SimCode.SimEqSystem> simEqSysts,allEqs;
    case({},_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then (taskAssIn,procAssIn,taskGraphIn,taskDuplAssIn,threadIn,idcsIn,simCodeIn,duplSccSimEqMapIn,duplCompsIn);
    case(node::rest,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // the task is already assigned, duplicate it
        ass = arrayGet(taskAssIn,node);
        true = intNe(ass,-1);
        //duplicate it
        (repl,taskAss,procAss,taskGraph,taskDuplAss,thread,idcs,simCode,duplSccSimEqMap,duplComps) = createTDSduplicateTasks2(node,allCluster,replIn,taskAssIn,procAssIn,threadIn,idcsIn,taskGraphOrig,taskGraphTOrig,taskGraphIn,taskDuplAssIn,iTaskGraphMeta,simCodeIn,sccSimEqMappingIn,duplSccSimEqMapIn,duplCompsIn);
        (taskAss,procAss,taskGraph,taskDuplAss,thread,idcs,simCode,duplSccSimEqMap,duplComps) = createTDSduplicateTasks1(rest,allCluster,repl,taskAss,procAss,thread,idcs,taskGraphOrig,taskGraphTOrig,taskGraph,taskDuplAss,iTaskGraphMeta,simCode,sccSimEqMappingIn,duplSccSimEqMap,duplComps);
      then (taskAss,procAss,taskGraph,taskDuplAss,thread,idcs,simCode,duplSccSimEqMap,duplComps);
    case(node::rest,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // the task is not yet assigned
        ass = arrayGet(taskAssIn,node);
        true = intEq(ass,-1);
        // assign task
        (threadIdx,taskIdx,compIdx,simVarIdx,simEqSysIdx,lsIdx,nlsIdx,mIdx) = idcsIn;
        HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps) = iTaskGraphMeta;
        //print("node "+&intString(node)+&"\n" );
        taskAss = arrayUpdate(taskAssIn,node,threadIdx);
        taskLst = arrayGet(procAssIn,threadIdx);
        procAss = arrayUpdate(procAssIn,threadIdx,node::taskLst);
        comps = arrayGet(inComps,node);
        //print("comps :"+&intListString(comps)+&"\n");
        simEqsLst = List.map1(comps,Util.arrayGetIndexFirst,sccSimEqMappingIn);
        simEqs = List.flatten(simEqsLst);
        simEqs = listReverse(simEqs);
        //print("simEqs :"+&intListString(simEqs)+&"\n");

        //change the simEqSystems in odes and allEqs if there is a duplicated predecessor
        SimCode.SIMCODE(odeEquations=odes, allEquations=allEqs) = simCodeIn;
        simEqSysts = List.map1(simEqs,SimCodeUtil.getSimEqSysForIndex,List.flatten(odes));
        (simEqSysts,_) = replaceInSimEqSystemLst(simEqSysts,replIn);
        allEqs = replaceSimEqSystemLstWithSameIndex(simEqSysts,allEqs);
        odes = List.map1r(odes,replaceSimEqSystemLstWithSameIndex,simEqSysts);
        simCode = SimCodeUtil.replaceODEandALLequations(allEqs,odes,simCodeIn);

        //update taskGraph
        clTasks = List.first(allCluster);// the current cluster
        //print("clTasks :"+&intListString(clTasks)+&"\n");
        origPredTasks = arrayGet(taskGraphTOrig,node);
        (clPredTasks,origPredTasks,_) = List.intersection1OnTrue(origPredTasks,clTasks,intEq);
        //print("origPredTasks :"+&intListString(origPredTasks)+&"\n");
        pos = List.map1(clPredTasks,List.position,clTasks);
        pos = List.map1(pos,intAdd,1);
        clTasks = arrayGet(procAssIn,threadIdx);
        clTasks = listReverse(clTasks);  // the current cluster with duplicated taskIdcs
        //print("clTasks :"+&intListString(clTasks)+&"\n");
        clPredTasks = List.map1(pos,List.getIndexFirst,clTasks);
        //print("clPredTasks :"+&intListString(clPredTasks)+&"\n");
        (duplPredTasks,_,_) = List.intersection1OnTrue(clPredTasks,clTasks,intEq);
        //print("duplPredTasks :"+&intListString(duplPredTasks)+&"\n");
        taskGraph = List.fold1(duplPredTasks,Util.arrayListAppend,{node},taskGraphIn); // add edges from duplicated predecessors to task
        taskGraphOut = List.fold1(origPredTasks,Util.arrayListAppend,{node},taskGraph); // add edges from non duplicated predecessors to task

        task = HpcOmSimCode.CALCTASK(1,node,0.0,-1.0,threadIdx,simEqs);
        thread = task::threadIn;
        taskDuplAss = arrayUpdate(taskDuplAssIn,node,node);
        (taskAss,procAss,taskGraph,taskDuplAss,thread,idcs,simCode,duplSccSimEqMap,duplComps) = createTDSduplicateTasks1(rest,allCluster,replIn,taskAss,procAss,thread,idcsIn,taskGraphOrig,taskGraphTOrig,taskGraph,taskDuplAss,iTaskGraphMeta,simCode,sccSimEqMappingIn,duplSccSimEqMapIn,duplCompsIn);
      then (taskAss,procAss,taskGraph,taskDuplAss,thread,idcs,simCode,duplSccSimEqMap,duplComps);
  end matchcontinue;
end createTDSduplicateTasks1;

protected function createTDSduplicateTasks2"sets the information about the new task in simCode,dae,sccMapping ect."
  input Integer node;
  input list<list<Integer>> allCluster;
  input BackendVarTransform.VariableReplacements replIn;
  input array<Integer> taskAssIn;
  input array<list<Integer>> procAssIn;
  input list<HpcOmSimCode.Task> threadIn;
  input tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> idcsIn; // threadIdx,taskIdx,compIdx,simVarIdx,simEqSysIdx,lsIdx,nlsIdx,mIdx
  input HpcOmTaskGraph.TaskGraph taskGraphOrig;
  input HpcOmTaskGraph.TaskGraph taskGraphTOrig;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input array<Integer> taskDuplAssIn;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input SimCode.SimCode simCodeIn;
  input array<list<Integer>> sccSimEqMappingIn;
  input list<list<Integer>> duplSccSimEqMapIn;
  input list<list<Integer>> duplCompsIn;
  output BackendVarTransform.VariableReplacements replOut;
  output array<Integer> taskAssOut;
  output array<list<Integer>> procAssOut;
  output HpcOmTaskGraph.TaskGraph taskGraphOut;
  output array<Integer> taskDuplAssOut;
  output list<HpcOmSimCode.Task> threadOut;
  output tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> idcsOut; // threadIdx,taskIdx,compIdx,simVarIdx,simEqSysIdx,lsIdx,nlsIdx,mIdx
  output SimCode.SimCode simCodeOut;
  output list<list<Integer>> duplSccSimEqMapOut;
  output list<list<Integer>> duplCompsOut;
protected
  String crefAppend;
  Integer threadIdx,compIdx,simVarIdx,simVarIdx2,simEqSysIdx,simEqSysIdx2,simEqSysIdx3,numVars,numEqs,numInitEqs,taskIdx,lsIdx,nlsIdx,mIdx;
  list<Integer> comps,simVarSysIdcs,simVarSysIdcs2,simEqSysIdcs,simEqSysIdcs2,simEqSysIdcsInit,thread,clTasks,origPredTasks,clPredTasks,duplPredTasks,pos;
  list<list<Integer>> simEqIdxLst,simVarIdxLst;
  array<list<Integer>> inComps;
  BackendVarTransform.VariableReplacements repl;
  HpcOmTaskGraph.TaskGraph taskGraph;
  SimCode.HashTableCrefToSimVar ht;
  SimCode.ModelInfo modelinfo;
  SimCode.SimVars simVars;
  SimCode.SimCode simCode;
  list<BackendDAE.Equation> eqs;
  list<BackendDAE.Var> vars;
  list<DAE.ComponentRef> crefs,crefsDupl;
  list<list<DAE.ComponentRef>> crefLst;
  list<DAE.Exp> crefsDuplExp;
  list<SimCode.SimVar> simVarLst,simVarDupl,algVars;
  list<SimCode.SimEqSystem> simEqSysts,simEqSystsDupl,initEqs;
  list<list<SimCode.SimEqSystem>> odes;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps) := iTaskGraphMeta;
  SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(vars=simVars),odeEquations=odes,crefToSimVarHT=ht) := simCodeIn;
  (threadIdx,taskIdx,compIdx,simVarIdx,simEqSysIdx,lsIdx,nlsIdx,mIdx) := idcsIn;

  // get the vars(crefs) and equations of the node
  //print("node to duplicate "+&intString(node)+&"\n");
  comps := arrayGet(inComps,node);
  comps := listReverse(comps);
  //print("comps :"+&intListString(comps)+&"\n");
  //print("task :"+&intString(taskIdx)+&"\n");
  simEqIdxLst := List.map1(comps,Util.arrayGetIndexFirst,sccSimEqMappingIn);
  simEqSysIdcs := List.flatten(simEqIdxLst);
  //print("simEqSysIdcs :"+&intListString(simEqSysIdcs)+&"\n");

  crefLst := List.map1(simEqSysIdcs,SimCodeUtil.getAssignedCrefsOfSimEq,simCodeIn);
  crefs := List.flatten(crefLst);
  //print("crefs :\n"+&stringDelimitList(List.map(crefs,ComponentReference.debugPrintComponentRefTypeStr),"\n")+&"\n");

  simVarLst := List.map1(crefs,SimCodeUtil.get,ht);
  simEqSysts := List.map1(simEqSysIdcs,SimCodeUtil.getSimEqSysForIndex,List.flatten(odes));

  // build the new crefs, new simVars
  numVars := listLength(simVarLst);
  simVarSysIdcs2 := List.intRange2(simVarIdx,simVarIdx+numVars-1);
  crefAppend := "_thr"+&intString(threadIdx);
  //crefsDupl := List.map1(crefs,ComponentReference.joinArrayCrefs,DAE.CREF_IDENT(crefAppend,DAE.T_UNKNOWN_DEFAULT,{}));
  crefsDupl := List.map1r(crefs,ComponentReference.appendStringLastIdent,crefAppend);
  //print("crefs new :\n"+&stringDelimitList(List.map(crefsDupl,ComponentReference.debugPrintComponentRefTypeStr),"\n")+&"\n");
  crefsDuplExp := List.map(crefsDupl,Expression.crefExp);
  simVarDupl := List.threadMap(crefsDupl,simVarLst,SimCodeUtil.replaceSimVarName);
  simVarDupl := List.threadMap(simVarSysIdcs2,simVarDupl,SimCodeUtil.replaceSimVarIndex);
  simCode := List.fold(simVarDupl,SimCodeUtil.addSimVarToAlgVars,simCodeIn);
  simVarIdx2 := simVarIdx + numVars;

  //update hashtable, create replacement rules and build new simEqSystems
  ht := List.fold(simVarDupl,SimCodeUtil.addSimVarToHashTable,ht);
  repl := BackendVarTransform.addReplacements(replIn,crefs,crefsDuplExp,NONE());
  //BackendVarTransform.dumpReplacements(repl);
  numEqs := listLength(simEqSysts);
  simEqSysIdcs2 := List.intRange2(simEqSysIdx,simEqSysIdx+numEqs-1);
  //print("simEqSysIdcs2 :"+&intListString(simEqSysIdcs2)+&"\n");
  (simEqSystsDupl,_) := List.map1_2(simEqSysts,replaceExpsInSimEqSystem,repl);// replace the exps and crefs
  (simEqSystsDupl,(lsIdx,nlsIdx,mIdx)) := List.mapFold(simEqSystsDupl,replaceSystemIndex,(lsIdx,nlsIdx,mIdx));// udpate the indeces of th systems
  simEqSystsDupl := List.threadMap(simEqSystsDupl,simEqSysIdcs2,SimCodeUtil.replaceSimEqSysIndex);
  //print("the simEqSystsDupl "+&SimCodeUtil.dumpSimEqSystemLst(simEqSystsDupl)+&"\n");
  simEqSysIdx2 := simEqSysIdx + numEqs;
  // update sccSimEqmapping for the duplicated
  duplSccSimEqMapOut := listAppend(List.map(simEqSysIdcs2,List.create),duplSccSimEqMapIn);
  simCode := List.fold1(simEqSystsDupl,SimCodeUtil.addSimEqSysToODEquations,1,simCode);
  // set task in thread
  threadOut := HpcOmSimCode.CALCTASK(1,taskIdx,0.0,-1.0,threadIdx,simEqSysIdcs2)::threadIn;
  // add init eqs to simCode
  numInitEqs := listLength(crefs);
  simEqSysIdcsInit := List.intRange2(simEqSysIdx2,simEqSysIdx2+numInitEqs-1);
  initEqs := List.thread3Map(crefsDupl,crefs,simEqSysIdcsInit,makeSEScrefAssignment);
  //print("the initEqs "+&SimCodeUtil.dumpSimEqSystemLst(initEqs)+&"\n");
  simCode := List.fold(initEqs,SimCodeUtil.addSimEqSysToInitialEquations,simCode);
  simEqSysIdx3 := simEqSysIdx2 + numInitEqs;

  SimCode.SIMCODE(odeEquations=odes) := simCode;
  //print("the simEqSysts after cluster: "+&intString(threadIdx)+&"_"+&intString(node)+&" \n"+&stringDelimitList(List.map(odes,SimCodeUtil.dumpSimEqSystemLst),"\n")+&"\n");

  //update duplSccSimEqMap, duplComps, taskAss, procAss for the new duplicates
  taskAssOut := arrayUpdate(taskAssIn,taskIdx,threadIdx);
  thread := arrayGet(procAssIn,threadIdx);
  thread := taskIdx::thread;
  procAssOut := arrayUpdate(procAssIn,threadIdx,thread);
  comps := List.intRange2(compIdx,compIdx+listLength(comps)-1);
  //print("compsNew :"+&intListString(comps)+&"\n");
  compIdx := compIdx+listLength(comps);
  duplCompsOut := comps::duplCompsIn;

  // update taskDuplAss
  taskDuplAssOut := arrayUpdate(taskDuplAssIn,taskIdx,node);

  //update taskGraph
  clTasks := List.first(allCluster);// the current cluster
  //print("clTasks :"+&intListString(clTasks)+&"\n");
  origPredTasks := arrayGet(taskGraphTOrig,node);
  (clPredTasks,origPredTasks,_) := List.intersection1OnTrue(origPredTasks,clTasks,intEq);
  //print("origPredTasks :"+&intListString(origPredTasks)+&"\n");
  pos := List.map1(clPredTasks,List.position,clTasks);
  pos := List.map1(pos,intAdd,1);
  clTasks := arrayGet(procAssOut,threadIdx);
  clTasks := listReverse(clTasks);  // the current cluster with duplicated taskIdcs
  //print("clTasks :"+&intListString(clTasks)+&"\n");
  clPredTasks := List.map1(pos,List.getIndexFirst,clTasks);
  //print("clPredTasks :"+&intListString(clPredTasks)+&"\n");
  (duplPredTasks,_,_) := List.intersection1OnTrue(clPredTasks,clTasks,intEq);
  //print("duplPredTasks :"+&intListString(duplPredTasks)+&"\n");
  taskGraph := List.fold1(duplPredTasks,Util.arrayListAppend,{taskIdx},taskGraphIn); // add edges from duplicated predecessors to task
  taskGraphOut := List.fold1(origPredTasks,Util.arrayListAppend,{taskIdx},taskGraph); // add edges from non duplicated predecessors to task

  idcsOut := (threadIdx,taskIdx+1,compIdx,simVarIdx2,simEqSysIdx3,lsIdx,nlsIdx,mIdx);
  simCodeOut := simCode;
  replOut := repl;
end createTDSduplicateTasks2;

protected function makeSEScrefAssignment
  input DAE.ComponentRef lhs;
  input DAE.ComponentRef rhs;
  input Integer idx;
  output SimCode.SimEqSystem sesOut;
protected
  DAE.Type ty;
algorithm
  ty := ComponentReference.crefType(rhs);
  sesOut := SimCode.SES_SIMPLE_ASSIGN(idx,lhs,DAE.CREF(rhs,ty),DAE.emptyElementSource);
end makeSEScrefAssignment;

protected function replaceSimEqSystemLstWithSameIndex
  input list<SimCode.SimEqSystem> eqSystsIn;
  input list<SimCode.SimEqSystem> eqSysLstIn;
  output list<SimCode.SimEqSystem> eqSysLstOut;
algorithm
  eqSysLstOut := List.fold(eqSystsIn,replaceSimEqSystemWithSameIndex,eqSysLstIn);
end replaceSimEqSystemLstWithSameIndex;

protected function replaceSimEqSystemWithSameIndex"replaces the simEqSystem with the same index in the eqSysLstIn.
author.Waurich TUD 2014-06"
  input SimCode.SimEqSystem eqSysIn;
  input list<SimCode.SimEqSystem> eqSysLstIn;
  output list<SimCode.SimEqSystem> eqSysLstOut;
algorithm
  eqSysLstOut := matchcontinue(eqSysIn,eqSysLstIn)
    local
      Integer idx, pos;
      list<SimCode.SimEqSystem> eqSysLst;
    case(_,_)
      equation
      idx = SimCodeUtil.eqIndex(eqSysIn);
      pos = List.positionOnTrue(eqSysIn,eqSysLstIn,SimCodeUtil.equationIndexEqual);
      eqSysLst = List.replaceAt(eqSysIn,pos,eqSysLstIn);
    then eqSysLst;
    else
    then eqSysLstIn;
  end matchcontinue;
end replaceSimEqSystemWithSameIndex;

protected function replaceSystemIndex"replaces the index of the linear system, the index of the non-linear system or the index of the mixed systems with the given values.
author: Waurich TUD 2014-04"
  input SimCode.SimEqSystem simEqSysIn;
  input tuple<Integer,Integer,Integer> idcsIn;// lsIdx,nlsIdx,mIdx
  output SimCode.SimEqSystem simEqSysOut;
  output tuple<Integer,Integer,Integer> idcsOut;// lsIdx,nlsIdx,mIdx
algorithm
  (simEqSysOut,idcsOut) := match(simEqSysIn,idcsIn)
    local
      Boolean pom,lt;
      Integer idx,lsIdx,nlsIdx,mIdx;
      SimCode.SimEqSystem simEqSys,cont;
      list<SimCode.SimVar> simVars;
      list<SimCode.SimEqSystem> simEqSysLst;
      list<DAE.ComponentRef> crefs;
      list<DAE.Exp> expLst;
      list<DAE.ElementSource> sources;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
      Option<SimCode.JacobianMatrix> jac;
    case(SimCode.SES_LINEAR(index=idx,partOfMixed=pom,vars=simVars,beqs=expLst,sources=sources,simJac=simJac),_)
      equation
        (lsIdx,nlsIdx,mIdx) = idcsIn;
        simEqSys = SimCode.SES_LINEAR(idx,pom,simVars,expLst,sources,simJac,lsIdx);
      then (simEqSys,(lsIdx+1,nlsIdx,mIdx));
    case(SimCode.SES_NONLINEAR(index=idx,eqs=simEqSysLst,crefs=crefs,jacobianMatrix=jac,linearTearing=lt),_)
      equation
        (lsIdx,nlsIdx,mIdx) = idcsIn;
        simEqSys = SimCode.SES_NONLINEAR(idx,simEqSysLst,crefs,nlsIdx,jac,lt);
      then (simEqSys,(lsIdx,nlsIdx+1,mIdx));
    case(SimCode.SES_MIXED(index=idx,cont=cont,discVars=simVars,discEqs=simEqSysLst),_)
      equation
        (lsIdx,nlsIdx,mIdx) = idcsIn;
        simEqSys = SimCode.SES_MIXED(idx,cont,simVars,simEqSysLst,mIdx);
      then (simEqSys,(lsIdx,nlsIdx,mIdx+1));
    else
      then (simEqSysIn,idcsIn);
  end match;
end replaceSystemIndex;

protected function replaceInSimEqSystemLst"performs replacements on a list of SimCode.SimEqSystems
author:Waurich TUD 2014-06"
  input list<SimCode.SimEqSystem> simEqSysLstIn;
  input BackendVarTransform.VariableReplacements replIn;
  output list<SimCode.SimEqSystem> simEqSysLstOut;
  output list<Boolean> changedOut;
algorithm
  (simEqSysLstOut,changedOut) := List.map1_2(simEqSysLstIn,replaceExpsInSimEqSystem,replIn);
end replaceInSimEqSystemLst;

protected function replaceExpsInSimEqSystem"performs replacements on a simEqSystem structure
author:Waurich TUD 2014-06"
  input SimCode.SimEqSystem simEqSysIn;
  input BackendVarTransform.VariableReplacements replIn;
  output SimCode.SimEqSystem simEqSysOut;
  output Boolean changedOut;
algorithm
    (simEqSysOut,changedOut) := matchcontinue(simEqSysIn,replIn)
    local
      Boolean pom,lt,changed,changed1,hasRepl,ic;
      Integer idx,idxLS,idxNLS,idxMS;
      list<Boolean> bLst;
      DAE.ComponentRef cref;
      DAE.ElementSource source;
      DAE.Exp exp;
      SimCode.SimEqSystem simEqSys;
      list<DAE.Exp> expLst;
      list<DAE.ComponentRef> crefs;
      list<DAE.ElementSource> sources;
      list<DAE.Statement> stmts;
      list<SimCode.SimEqSystem> simEqSysLst;
      list<SimCode.SimVar> simVars;
      list<list<SimCode.SimEqSystem>> simEqSysLstLst;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
      list<tuple<DAE.Exp,list<SimCode.SimEqSystem>>> ifs;
      list<SimCode.SimEqSystem> elsebranch;
      Option<SimCode.JacobianMatrix> jac;
    case(SimCode.SES_RESIDUAL(index=idx,exp=exp,source=source),_)
      equation
        (exp,changed) = BackendVarTransform.replaceExp(exp,replIn,NONE());
        simEqSys = SimCode.SES_RESIDUAL(idx,exp,source);
    then (simEqSys,changed);
    case(SimCode.SES_SIMPLE_ASSIGN(index=idx,cref=cref,exp=exp,source=source),_)
      equation
        hasRepl = BackendVarTransform.hasReplacement(replIn,cref);
        DAE.CREF(componentRef=cref) = Debug.bcallret2(hasRepl,BackendVarTransform.getReplacement,replIn,cref,DAE.CREF(cref,DAE.T_UNKNOWN_DEFAULT));
        (exp,changed) = BackendVarTransform.replaceExp(exp,replIn,NONE());
        simEqSys = SimCode.SES_SIMPLE_ASSIGN(idx,cref,exp,source);
    then (simEqSys,changed or hasRepl);
    case(SimCode.SES_ARRAY_CALL_ASSIGN(index=idx,componentRef=cref,exp=exp,source=source),_)
      equation
        hasRepl = BackendVarTransform.hasReplacement(replIn,cref);
        DAE.CREF(componentRef=cref) = Debug.bcallret2(hasRepl,BackendVarTransform.getReplacement,replIn,cref,DAE.CREF(cref,DAE.T_UNKNOWN_DEFAULT));
        (exp,changed) = BackendVarTransform.replaceExp(exp,replIn,NONE());
        simEqSys = SimCode.SES_ARRAY_CALL_ASSIGN(idx,cref,exp,source);
    then (simEqSys,changed or hasRepl);
    case(SimCode.SES_IFEQUATION(index=idx,ifbranches=ifs,elsebranch=elsebranch,source=source),_)
      equation
        expLst = List.map(ifs,Util.tuple21);
        (expLst,changed) = BackendVarTransform.replaceExpList(expLst,replIn,NONE(),{},false);
        simEqSysLstLst = List.map(ifs,Util.tuple22);
        (simEqSysLstLst,_) = List.map1_2(simEqSysLstLst,replaceInSimEqSystemLst,replIn);
        ifs = List.threadMap(expLst,simEqSysLstLst,Util.makeTuple);
        (elsebranch,bLst) = List.map1_2(elsebranch,replaceExpsInSimEqSystem,replIn);
        changed = List.fold(bLst,boolOr,changed);
        simEqSys = SimCode.SES_IFEQUATION(idx,ifs,elsebranch,source);
    then (simEqSys,changed);
    case(SimCode.SES_ALGORITHM(index=idx,statements=stmts),_)
      equation
        (stmts,changed) = BackendVarTransform.replaceStatementLst(stmts,replIn,NONE(),{},false);
        simEqSys = SimCode.SES_ALGORITHM(idx,stmts);
    then (simEqSys,changed);
    case(SimCode.SES_LINEAR(index=idx,partOfMixed=pom,vars=simVars,beqs=expLst,sources=sources,simJac=simJac,indexLinearSystem=idxLS),_)
      equation
        (simVars,bLst) = List.map1_2(simVars,replaceCrefInSimVar,replIn);
        (expLst,changed) = BackendVarTransform.replaceExpList(expLst,replIn,NONE(),{},false);
        changed = List.fold(bLst,boolOr,changed);
        simJac = List.map1(simJac,replaceInSimJac,replIn);
        simEqSys = SimCode.SES_LINEAR(idx,pom,simVars,expLst,sources,simJac,idxLS);
    then (simEqSys,changed);
    case(SimCode.SES_NONLINEAR(index=idx,eqs=simEqSysLst,crefs=crefs,indexNonLinearSystem=idxNLS,jacobianMatrix=jac,linearTearing=lt),_)
      equation
        print("TODO:replace crefs\n");
        (simEqSysLst,bLst) = List.map1_2(simEqSysLst,replaceExpsInSimEqSystem,replIn);
        changed = List.fold(bLst,boolOr,false);
        print("implement Jacobian replacement for SES_NONLINEAR in HpcOmScheduler.replaceExpsInSimEqSystems!\n");
        simEqSys = SimCode.SES_NONLINEAR(idx,simEqSysLst,crefs,idxNLS,NONE(),lt);
    then (simEqSys,changed);
    case(SimCode.SES_MIXED(index=idx,cont=simEqSys,discVars=simVars,discEqs=simEqSysLst,indexMixedSystem=idxMS),_)
      equation
        (simEqSys,changed) = replaceExpsInSimEqSystem(simEqSys,replIn);
        (simVars,bLst) = List.map1_2(simVars,replaceCrefInSimVar,replIn);
        changed = List.fold(bLst,boolOr,changed);
        (simEqSysLst,bLst) = List.map1_2(simEqSysLst,replaceExpsInSimEqSystem,replIn);
        changed = List.fold(bLst,boolOr,changed);
        simEqSys = SimCode.SES_MIXED(idx,simEqSys,simVars,simEqSysLst,idxMS);
    then (simEqSys,changed);
    case(SimCode.SES_WHEN(index=idx,conditions=crefs,initialCall=ic,left=cref,right=exp,elseWhen=NONE(),source=source),_)
      equation
        (crefs,bLst) = List.map1_2(crefs,BackendVarTransform.replaceCref,replIn);
        (cref,changed) = BackendVarTransform.replaceCref(cref,replIn);
        changed = List.fold(bLst,boolOr,changed);
        (exp,changed1) = BackendVarTransform.replaceExp(exp,replIn,NONE());
        changed = boolOr(changed,changed1);
        simEqSys = SimCode.SES_WHEN(idx,crefs,ic,cref,exp,NONE(),source);
    then (simEqSys,changed);
    case(SimCode.SES_WHEN(index=idx,conditions=crefs,initialCall=ic,left=cref,right=exp,elseWhen=SOME(simEqSys),source=source),_)
      equation
        (crefs,bLst) = List.map1_2(crefs,BackendVarTransform.replaceCref,replIn);
        (cref,changed) = BackendVarTransform.replaceCref(cref,replIn);
        changed = List.fold(bLst,boolOr,changed);
        (exp,changed1) = BackendVarTransform.replaceExp(exp,replIn,NONE());
        changed = boolOr(changed,changed1);
        (simEqSys,changed1) = replaceExpsInSimEqSystem(simEqSys,replIn);
        changed = boolOr(changed,changed1);
        simEqSys = SimCode.SES_WHEN(idx,crefs,ic,cref,exp,SOME(simEqSys),source);
    then (simEqSys,changed);
  else
    equation
      print("replaceExpsInSimEqSystem failed\n");
    then fail();
  end matchcontinue;
end replaceExpsInSimEqSystem;

protected function replaceCrefInSimVar"performs replacements on a simVar structure.
author: Waurich TUD 2014-06"
  input SimCode.SimVar simVarIn;
  input BackendVarTransform.VariableReplacements replIn;
  output SimCode.SimVar simVarOut;
  output Boolean changedOut;
algorithm
    (simVarOut,changedOut) := matchcontinue(simVarIn,replIn)
      local
        Boolean isFixed,isDiscrete,isValueChangeable,isProtected;
        Integer index;
        String comment, unit, displayUnit;
        list<String> numArrayElement;
        BackendDAE.VarKind varKind;
        DAE.ComponentRef name;
        DAE.Type type_;
        DAE.ElementSource source;
        SimCode.AliasVariable aliasvar;
        SimCode.Causality causality;
        SimCode.SimVar simVar;
        Option<Integer> variable_index;
        Option<DAE.ComponentRef> arrayCref;
        Option<DAE.Exp> minValue,maxValue,initialValue,nominalValue;
    case(SimCode.SIMVAR(name=name,varKind=varKind,comment=comment,unit=unit,displayUnit=displayUnit,index=index,minValue=minValue,maxValue=maxValue,initialValue=initialValue,
         nominalValue=nominalValue,isFixed=isFixed,type_=type_,isDiscrete=isDiscrete,arrayCref=arrayCref,aliasvar=aliasvar,source=source,causality=causality,variable_index=variable_index,
         numArrayElement=numArrayElement,isValueChangeable=isValueChangeable,isProtected=isProtected),_)
      equation
        true = BackendVarTransform.hasReplacement(replIn,name);
        DAE.CREF(componentRef=name) = BackendVarTransform.getReplacement(replIn,name);
        simVar = SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,index,minValue,maxValue,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement,isValueChangeable,isProtected);
      then (simVar,true);
    else
      then (simVarIn,false);
  end matchcontinue;
end replaceCrefInSimVar;

protected function replaceInSimJac"replaces the row of a simJac.
author:Waurich TUD 2014-04"
  input tuple<Integer, Integer, SimCode.SimEqSystem> simJacRowIn;
  input BackendVarTransform.VariableReplacements replIn;
  output  tuple<Integer, Integer, SimCode.SimEqSystem> simJacRowOut;
protected
  Integer int1,int2;
  SimCode.SimEqSystem simEqSys;
algorithm
  (int1,int2,simEqSys) := simJacRowIn;
  (simEqSys,_) := replaceExpsInSimEqSystem(simEqSys,replIn);
  simJacRowOut :=(int1,int2,simEqSys);
end replaceInSimJac;

protected function getTaskAssignmentTDS"sets the assigned processor for each task.
author:Waurich TUD 2014-05"
  input Integer procIdx;
  input array<list<Integer>> clusterArrayIn;
  input array<Integer> taskAssIn;
protected
  array<Integer> taskAss;
  list<Integer> procTasks;
algorithm
  procTasks := arrayGet(clusterArrayIn,procIdx);
  List.map2_0(procTasks,Util.arrayUpdateIndexFirst,procIdx,taskAssIn);
end getTaskAssignmentTDS;

protected function createTDSCompactClusters"performs compaction to the cluster set. the least crowded (lowest exe costs) cluster is marged with the crowded cluster and so on.
it is possible that several tasks are assigned to multiple threads. thats because duplication is needed.
author:Waurich TUD 2015-05"
  input list<list<Integer>> clustersIn;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Real> TDSLevel;
  input Integer numProc;
  output list<list<Integer>> clustersOut;
protected
  Integer numMergeClusters;
  list<Real> clusterExeCosts;
  list<Integer> clusterOrder;
  list<list<Integer>> firstClusters,lastClusters, middleCluster,clusters, mergedClusters;
algorithm
  clusterExeCosts := List.map1(clustersIn,createTDScomputeClusterCosts,iTaskGraphMeta);
  (_,clusterOrder) := quicksortWithOrder(clusterExeCosts);
  clusterOrder := listReverse(clusterOrder);
  clusters := List.map1(clusterOrder,List.getIndexFirst,clustersIn);  // the clusters, sorted in descending order of their accumulated execution costs
  numMergeClusters := intMin(intDiv(listLength(clustersIn),2),intSub(listLength(clustersIn),numProc));
  (firstClusters,lastClusters) := List.split(clusters,numMergeClusters);
  (middleCluster,lastClusters) := List.split(lastClusters,intSub(listLength(lastClusters),numMergeClusters));
  lastClusters := listReverse(lastClusters);
  mergedClusters := List.threadMap(firstClusters,lastClusters,listAppend);
  clustersOut := listAppend(mergedClusters,middleCluster);
  //print("mergedClustersOut:\n"+&stringDelimitList(List.map(clustersOut,intListString),"\n")+&"\n");
end createTDSCompactClusters;

protected function createTDSSortCompactClusters"sorts the tasks in the cluster to descending order of their tds level value.
author:Waurich TUD 2014-05"
  input list<Integer> clusterIn;
  input array<Real> tdsLevelIn;
  output list<Integer> clusterOut;
protected
  list<Integer> order, cluster;
  list<Real> tdsLevels;
algorithm
  cluster := List.unique(clusterIn);
  tdsLevels := List.map1(cluster,Util.arrayGetIndexFirst,tdsLevelIn);
  (_,order) := quicksortWithOrder(tdsLevels);
  order := listReverse(order);
  clusterOut :=List.map1(order,List.getIndexFirst,cluster);
end createTDSSortCompactClusters;

protected function createTDScomputeClusterCosts"accumulates the execution costs of all tasks in one cluster.
author:Waurich TUD 2014-05"
  input list<Integer> clusters;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  output Real costs;
protected
  list<Real> nodeCosts;
algorithm
  nodeCosts := List.map1(clusters,HpcOmTaskGraph.getExeCostReqCycles,iTaskGraphMeta);
  costs := List.fold(nodeCosts,realAdd,0.0);
end createTDScomputeClusterCosts;

protected function createTDSInitialCluster"creates the initial Clusters for the task duplication scheduler.
author: waurich TUD 2014-05"
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Real> lastArrayIn;
  input array<Real> lactArrayIn;
  input array<Integer> fpredArrayIn;
  input list<Integer> queue;
  output list<list<Integer>> clustersOut;
protected
  array<Integer> taskAssignments;
  list<Integer> rootNodes;
algorithm
  taskAssignments := arrayCreate(arrayLength(iTaskGraph),-1);
  rootNodes := HpcOmTaskGraph.getRootNodes(iTaskGraph);
  clustersOut := createTDSInitialCluster1(iTaskGraph,iTaskGraphT,iTaskGraphMeta,lastArrayIn,lactArrayIn,fpredArrayIn,rootNodes,taskAssignments,1,queue,{{}});
end createTDSInitialCluster;

protected function createTDSInitialCluster1"implementation of function createTDSInitialCluster.
author: waurich TUD 2014-05"
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Real> lastArrayIn;
  input array<Real> lactArrayIn;
  input array<Integer> fpredArrayIn;
  input list<Integer> rootNodes;
  input array<Integer> taskAssIn; // rootNodes are not assigned
  input Integer currThread;
  input list<Integer> queue;
  input list<list<Integer>> clustersIn;
  output list<list<Integer>> clustersOut;
algorithm
  clustersOut := matchcontinue(iTaskGraph,iTaskGraphT,iTaskGraphMeta,lastArrayIn,lactArrayIn,fpredArrayIn,rootNodes,taskAssIn,currThread,queue,clustersIn)
    local
      Boolean isCritical;
      Integer front, fpred,pos;
      Real maxExeCost;
      list<Real> parentExeCost;
      list<Integer> rest, parents, parentsNofpred, parentAssgmnts, unAssParents, thread;
      list<list<Integer>> clusters;
    case(_,_,_,_,_,_,_,_,_,{},_)
      equation
        clusters = List.filterOnTrue(clustersIn,List.isNotEmpty);
        clusters = List.map(clusters,listReverse);
      then clusters;
    case(_,_,_,_,_,_,_,_,_,front::rest,_)
      equation
        // the node is an rootNode
        true = List.isMemberOnTrue(front,rootNodes,intEq);
        //print("node (root): "+&intString(front)+&"\n");
        //assign rootNode to current thread and start a new thread(cluster)
        thread = listGet(clustersIn,currThread);
        thread = front::thread;
        clusters = List.replaceAt(thread,currThread-1,clustersIn);
        //print("cluster: "+&intListString(thread)+&"\n");
        clusters = listAppend(clusters,{{}});
        clusters = createTDSInitialCluster1(iTaskGraph,iTaskGraphT,iTaskGraphMeta,lastArrayIn,lactArrayIn,fpredArrayIn,rootNodes,taskAssIn,currThread+1,rest,clusters);
      then clusters;
    case(_,_,_,_,_,_,_,_,_,front::rest,_)
      equation
        // assign node, fpred is critical --> choose the fpred as next node
        fpred = arrayGet(fpredArrayIn,front);
        isCritical = TDSpredIsCritical(front,fpred,iTaskGraphMeta,lastArrayIn,lactArrayIn);
        true = isCritical;
        //print("node (new pred): "+&intString(front)+&"\n");
        //assign node from queue to a thread (in reversed order)
        thread = listGet(clustersIn,currThread);
        thread = front::thread;
        clusters = List.replaceAt(thread,currThread-1,clustersIn);
        //print("cluster: "+&intListString(thread)+&"\n");
        _ = arrayUpdate(taskAssIn,front,currThread);
        // go to predecessor
        rest = List.removeOnTrue(fpred,intEq,rest);
        rest = fpred::rest;
        clusters = createTDSInitialCluster1(iTaskGraph,iTaskGraphT,iTaskGraphMeta,lastArrayIn,lactArrayIn,fpredArrayIn,rootNodes,taskAssIn,currThread,rest,clusters);
      then clusters;
    case(_,_,_,_,_,_,_,_,_,front::rest,_)
      equation
        // assign node, pred is not critical, look for another pred to assign
        fpred = arrayGet(fpredArrayIn,front);
        isCritical = TDSpredIsCritical(front,fpred,iTaskGraphMeta,lastArrayIn,lactArrayIn);
        true  = not isCritical;
        //assign node from queue to a thread (in reversed order)
        thread = listGet(clustersIn,currThread);
        thread = front::thread;
        clusters = List.replaceAt(thread,currThread-1,clustersIn);
        //print("cluster: "+&intListString(thread)+&"\n");
        _ = arrayUpdate(taskAssIn,front,currThread);
        // check for other parents to get the next fpred
        parents = arrayGet(iTaskGraphT,front);
        parentsNofpred = List.removeOnTrue(fpred,intEq,parents);// choose not the fpred
        parentAssgmnts = List.map1(parentsNofpred,Util.arrayGetIndexFirst,taskAssIn);
        (_,unAssParents) = List.filter1OnTrueSync(parentAssgmnts,intEq,-1,parentsNofpred); // not yet assigned parents
        // if there are unassigned parents, use them, otherwise all parents including fpred. take the one with the least execution cost
        parents = Util.if_(List.isEmpty(unAssParents),parents,unAssParents);
        parentExeCost = List.map1(parents,HpcOmTaskGraph.getExeCostReqCycles,iTaskGraphMeta);
        maxExeCost = List.fold(parentExeCost,realMax,0.0);
        pos = List.position(maxExeCost,parentExeCost) + 1;
        fpred = listGet(parents,pos);
        // go to predecessor
        rest = List.removeOnTrue(fpred,intEq,rest);
        rest = fpred::rest;
        clusters = createTDSInitialCluster1(iTaskGraph,iTaskGraphT,iTaskGraphMeta,lastArrayIn,lactArrayIn,fpredArrayIn,rootNodes,taskAssIn,currThread,rest,clusters);
      then clusters;
    else
     equation
       print("createTDSInitialCluster1 failed\n");
     then
       fail();
  end matchcontinue;
end createTDSInitialCluster1;

protected function TDSpredIsCritical"calculates the criteria if the predecessor is critical"
  input Integer node;
  input Integer pred;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Real> lastArrayIn;
  input array<Real> lactArrayIn;
  output Boolean isCritical;
protected
  Real lastNode,lactPred,commCosts;
algorithm
  lastNode := arrayGet(lastArrayIn,node);// latest allowable starting time of the node
  lactPred := arrayGet(lactArrayIn,pred);
  commCosts := HpcOmTaskGraph.getCommCostBetweenNodesInCycles(pred,node,iTaskGraphMeta);
  isCritical := realSub(lastNode,lactPred) <=. commCosts;
end TDSpredIsCritical;

protected function computeFavouritePred"gets the favourite Predecessors of each task. needed for the task duplication scheduler
author:Waurich TUD 2014-05"
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Real> ect;
  output array<Integer> fpredOut;
protected
  Integer size;
  array<Integer> fpred;
  HpcOmTaskGraph.TaskGraph taskGraphT;
algorithm
  size := arrayLength(iTaskGraph);
  taskGraphT := BackendDAEUtil.transposeMatrix(iTaskGraph,size);
  fpred := arrayCreate(size,-1);
  fpredOut := List.fold3(List.intRange(size),computeFavouritePred1,taskGraphT,iTaskGraphMeta,ect,fpred);
end computeFavouritePred;

protected function computeFavouritePred1"folding function for computeFavouritePred to traverse all nodes and get their favourite predecessors
author:Waurich TUD 2014-05"
  input Integer nodeIdx;
  input HpcOmTaskGraph.TaskGraph graphT;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Real> ect;
  input array<Integer> fpredIn;
  output array<Integer> fpredOut;
algorithm
  fpredOut := matchcontinue(nodeIdx,graphT,iTaskGraphMeta,ect,fpredIn)
    local
      Integer fpredPos,fpred;
      Real maxCost;
      list<Integer> parents;
      list<Real> parentECTs,commCosts,costs;
    case(_,_,_,_,_)
      equation
        parents = arrayGet(graphT,nodeIdx);
        true = List.isNotEmpty(parents);
        parentECTs = List.map1(parents,Util.arrayGetIndexFirst,ect);
        commCosts = List.map2(parents,HpcOmTaskGraph.getCommCostBetweenNodesInCycles,nodeIdx,iTaskGraphMeta);
        costs = List.threadMap(parentECTs,commCosts,realAdd);
        maxCost = List.fold(costs,realMax,0.0);
        fpredPos = List.position(maxCost,costs)+1;
        fpred = listGet(parents,fpredPos); // if there is no predecessor, the fpred value is 0
        fpredOut = arrayUpdate(fpredIn,nodeIdx,fpred);
      then fpredOut;
    case(_,_,_,_,_)
      equation
        parents = arrayGet(graphT,nodeIdx);
        true = List.isEmpty(parents);
        fpredOut = arrayUpdate(fpredIn,nodeIdx,0);
      then fpredOut;
  end matchcontinue;
end computeFavouritePred1;

//---------------------------------
// Modified Critical Path scheduler
//---------------------------------

public function createMCPschedule "scheduler Modified Critical Path.
computes the ALAP i.e. latest possible start time  for every task. The task with the smallest values gets the highest priority.
author: Waurich TUD 2013-10 "
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer numProc;
  input array<list<Integer>> iSccSimEqMapping;
  output HpcOmSimCode.Schedule oSchedule;
protected
  Integer size, numSfLocks;
  array<list<HpcOmSimCode.Task>> threads;
  array<list<Integer>> taskGraphT;
  array<Real> alapArray;  // this is the latest possible starting time of every node
  list<Real> alapLst, alapSorted, priorityLst;
  list<Integer> order;
  list<HpcOmSimCode.Task> removeLocks;
  array<Integer> taskAss; //<idx>=task, <value>=processor
  array<list<Integer>> procAss; //<idx>=processor, <value>=task;
  array<list<HpcOmSimCode.Task>> threadTask;
  HpcOmSimCode.Schedule schedule;
algorithm
  //compute the ALAP
  size := arrayLength(iTaskGraph);
  taskGraphT := BackendDAEUtil.transposeMatrix(iTaskGraph,size);
  (alapArray,_,_,_) := computeGraphValuesTopDown(iTaskGraph,iTaskGraphMeta);
  //printRealArray(alapArray,"alap");
  alapLst := arrayList(alapArray);
  // get the order of the task, assign to processors
  (priorityLst,order) := quicksortWithOrder(alapLst);
  (taskAss,procAss) := getTaskAssignmentMCP(order,alapArray,numProc,iTaskGraph,iTaskGraphMeta);
  // create the schedule
  threadTask := arrayCreate(numProc,{});
  schedule := HpcOmSimCode.THREADSCHEDULE(threadTask,{});
  removeLocks := {};
  (schedule,removeLocks) := createScheduleFromAssignments(taskAss,procAss,SOME(order),iTaskGraph,taskGraphT,iTaskGraphMeta,iSccSimEqMapping,removeLocks,order,schedule);
  // remove superfluous locks
  numSfLocks := intDiv(listLength(removeLocks),2);
  Debug.fcall(Flags.HPCOM_DUMP,print,"number of removed superfluous locks: "+&intString(numSfLocks)+&"\n");
  schedule := traverseAndUpdateThreadsInSchedule(schedule,removeLocksFromThread,removeLocks);
  schedule := updateLockIdcsInThreadschedule(schedule,removeLocksFromLockIds,removeLocks);
  oSchedule := schedule;
end createMCPschedule;

protected function updateLockIdcsInThreadschedule "executes the given function on the lockIdc in THREADSCHEDULE.
author:Waurich TUD 2013-12"
  input HpcOmSimCode.Schedule scheduleIn;
  input FuncType inFunc;
  input ArgType extraArg;
  output HpcOmSimCode.Schedule scheduleOut;
partial function FuncType
  input list<String> locksIn;
  input ArgType inArg;
  output list<String> locksOut;
end FuncType;
replaceable type ArgType subtypeof Any;
algorithm
  scheduleOut := match(scheduleIn,inFunc,extraArg)
    local
      HpcOmSimCode.Schedule schedule;
      array<list<HpcOmSimCode.Task>> threadTasks;
      list<String> lockIdc;
    case(HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,lockIdc=lockIdc),_,_)
      equation
        lockIdc = inFunc(lockIdc,extraArg);
        schedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,lockIdc);
      then
        schedule;
    else
      equation
        print("this is not a thread schedule!\n");
      then
        scheduleIn;
  end match;
end updateLockIdcsInThreadschedule;

protected function traverseAndUpdateThreadsInSchedule "traverses all Threads in a schedule.
author: Waurich TUD 2013-12"
  input HpcOmSimCode.Schedule scheduleIn;
  input FuncType funcIn;
  input ArgType extraArg;
  output HpcOmSimCode.Schedule scheduleOut;
partial function FuncType
  input list<HpcOmSimCode.Task> taskIn;
  input ArgType argIn;
  output list<HpcOmSimCode.Task> outArg;
end FuncType;
replaceable type ArgType subtypeof Any;
algorithm
  scheduleOut := match(scheduleIn,funcIn,extraArg)
    local
      array<list<HpcOmSimCode.Task>> threadTasks;
      list<String> lockIdc;
      list<list<HpcOmSimCode.Task>> tasksOfLevels;
      HpcOmSimCode.Schedule schedule;
    case(HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=_),_,_)
      then
        scheduleIn;
    case(HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,lockIdc=lockIdc),_,_)
      equation
        threadTasks = Util.arrayMap1(threadTasks,funcIn,extraArg);
        schedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,lockIdc);
      then
        schedule;
    case(HpcOmSimCode.EMPTYSCHEDULE(),_,_)
      then
        scheduleIn;
  end match;
end traverseAndUpdateThreadsInSchedule;

protected function createScheduleFromAssignments"creates the ThreadSchedule from the taskAssignment i.e. which task is computed in which thread.
author:Waurich TUD 2013-12"
  input array<Integer> taskAss;
  input array<list<Integer>> procAss;
  input Option<list<Integer>> orderOpt;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraph taskGraphTIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  input array<list<Integer>> SccSimEqMappingIn;
  input list<HpcOmSimCode.Task> removeLocksIn;
  input list<Integer> orderIn;  // need the complete order for removeSuperfluousLocks
  input HpcOmSimCode.Schedule scheduleIn;
  output HpcOmSimCode.Schedule scheduleOut;
  output list<HpcOmSimCode.Task> removeLocksOut;
algorithm
  (scheduleOut,removeLocksOut) := match(taskAss,procAss,orderOpt,taskGraphIn,taskGraphTIn,taskGraphMetaIn,SccSimEqMappingIn,removeLocksIn,orderIn,scheduleIn)
    local
      Integer node,proc,mark,numProc;
      Real exeCost,commCost;
      list<Integer> order, rest, components, simEqIdc, parentNodes,childNodes, sameProcTasks, otherParents, otherChildren;
      list<String> assLockIdc,relLockIdc,lockIdc;
      array<Integer> nodeMark;
      array<list<Integer>> inComps;
      array<tuple<Integer,Real>> exeCosts;
      array<list<tuple<Integer,Integer,Integer>>> commCosts;
      array<list<HpcOmSimCode.Task>> threadTasks;
      list<HpcOmSimCode.Task> taskLst1,taskLst,taskLstAss,taskLstRel, removeLocks;
      HpcOmSimCode.Schedule schedule;
      HpcOmSimCode.Task task;
    case(_,_,SOME({}),_,_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE(lockIdc=_))
      equation
      then
        (scheduleIn,removeLocksIn);
    case(_,_,SOME(order),_,_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks, lockIdc=lockIdc))
      equation
        numProc = arrayLength(procAss);
        (node::rest) = order;
        proc = arrayGet(taskAss,node);
        taskLst = arrayGet(threadTasks, proc);
        // get the locks
        parentNodes = arrayGet(taskGraphTIn,node);
        childNodes = arrayGet(taskGraphIn,node);
        sameProcTasks = arrayGet(procAss,proc);
        (_,otherParents,_) = List.intersection1OnTrue(parentNodes,sameProcTasks,intEq);
        (_,otherChildren,_) = List.intersection1OnTrue(childNodes,sameProcTasks,intEq);
        // keep the locks that are superfluous, remove them later
        removeLocks = getSuperfluousLocks(otherParents,node,taskAss,orderIn,numProc,removeLocksIn);

        assLockIdc = List.map1(otherParents,getAssignLockString,node);
        taskLstAss = List.map(assLockIdc,getAssignLockTask);
        relLockIdc = List.map1(otherChildren,getReleaseLockString,node);
        taskLstRel = List.map(relLockIdc,getReleaseLockTask);
        //build the calcTask
        HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,nodeMark=nodeMark) = taskGraphMetaIn;
        components = arrayGet(inComps,node);
        mark = arrayGet(nodeMark,node);
        ((_,exeCost)) = HpcOmTaskGraph.getExeCost(node,taskGraphMetaIn);
        simEqIdc = List.map(List.map1(components,getSimEqSysIdxForComp,SccSimEqMappingIn), List.last);
        simEqIdc = listReverse(simEqIdc);
        task = HpcOmSimCode.CALCTASK(mark,node,exeCost,-1.0,proc,simEqIdc);
        taskLst1 = task::taskLstRel;
        taskLst1 = listAppend(taskLstAss,taskLst1);
        taskLst = listAppend(taskLst,taskLst1);
        //update schedule
        threadTasks = arrayUpdate(threadTasks,proc,taskLst);
        lockIdc = listAppend(lockIdc,assLockIdc);
        schedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,lockIdc);
        (schedule,removeLocks) = createScheduleFromAssignments(taskAss,procAss,SOME(rest),taskGraphIn,taskGraphTIn,taskGraphMetaIn,SccSimEqMappingIn,removeLocks,orderIn,schedule);
      then
        (schedule,removeLocks);
    case(_,_,NONE(),_,_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE(lockIdc=_))
      equation
        print("createSchedulerFromAssignments failed.implement this!\n");
      then
        fail();
  end match;
end createScheduleFromAssignments;

protected function isEqualTaskId"checks if the lockId or the calcTaskIdx is the same. emptyTasks are not handled as equal.
author:Waurich TUD 2013-12"
  input HpcOmSimCode.Task task1;
  input HpcOmSimCode.Task task2;
  output Boolean isEqOut;
algorithm
  isEqOut := match(task1,task2)
    local
      Boolean isEq;
      Integer id1,id2;
      String lockId1,lockId2;
    case(HpcOmSimCode.ASSIGNLOCKTASK(lockId=lockId1),HpcOmSimCode.ASSIGNLOCKTASK(lockId=lockId2))
      equation
        isEq = stringEq(lockId1,lockId2);
      then
        isEq;
    case(HpcOmSimCode.RELEASELOCKTASK(lockId=lockId1),HpcOmSimCode.RELEASELOCKTASK(lockId=lockId2))
      equation
        isEq = stringEq(lockId1,lockId2);
      then
        isEq;
    case(HpcOmSimCode.CALCTASK(weighting=_,index=id1,calcTime=_,timeFinished=_,threadIdx=_,eqIdc=_),HpcOmSimCode.CALCTASK(weighting=_,index=id2,calcTime=_,timeFinished=_,threadIdx=_,eqIdc=_))
      equation
        isEq = intEq(id1,id2);
      then
        isEq;
    case(HpcOmSimCode.TASKEMPTY(),HpcOmSimCode.TASKEMPTY())
      equation
      then
        false;
    else
      then
        false;
  end match;
end isEqualTaskId;

protected function removeLocksFromLockIds "removes all locks from the list of locks.
author:Waurich TUD 2013-12"
  input list<String> lockIdsIn;
  input list<HpcOmSimCode.Task> lockTasks;
  output list<String> lockIdsOut;
protected
  list<String> lockIdStrings;
algorithm
  lockIdStrings := List.map(lockTasks,getLockIdString);
  (_,lockIdsOut,_) := List.intersection1OnTrue(lockIdsIn,lockIdStrings,stringEq);
end removeLocksFromLockIds;

protected function removeLocksFromThread "removes all lockTasks that are given in the locksLst from the thread.
author:Waurich TUD 2013-12"
  input list<HpcOmSimCode.Task> threadIn;
  input list<HpcOmSimCode.Task> lockLst;
  output list<HpcOmSimCode.Task> threadOut;
algorithm
  (_,threadOut,_) := List.intersection1OnTrue(threadIn,lockLst,isEqualTaskId);
end removeLocksFromThread;

protected function getLockIdString "gets the lockId string.
author:Waurich TUD 2013-12"
  input HpcOmSimCode.Task taskIn;
  output String idStringOut;
algorithm
  idStringOut := match(taskIn)
    local
      String lockId;
    case(HpcOmSimCode.ASSIGNLOCKTASK(lockId=lockId))
      then
        lockId;
    case(HpcOmSimCode.RELEASELOCKTASK(lockId=lockId))
      then
        lockId;
    else
      then
        "";
  end match;
end getLockIdString;

protected function getSuperfluousLocks "gets the locks that are unnecessary. e.g. if a task has multiple parentTasks from one thread, we just need the lock from the last executed task.
author:Waurich TUD 2013-12"
  input list<Integer> otherParentsIn;
  input Integer nodeIn;
  input array<Integer> taskAssIn;
  input list<Integer> orderIn;
  input Integer numProc;
  input list<HpcOmSimCode.Task> removeLocksIn;
  output list<HpcOmSimCode.Task> removeLocksOut;
protected
  array<list<Integer>> parentsOnThreads, arr;
  array<String> s;
  list<Integer> otherParentsProcs, lockCandidatesFlat;
  list<String> assLockIdc, relLockIdc;
  list<list<Integer>> lockCandidates;
  list<HpcOmSimCode.Task> removeLocks, taskLstAss, taskLstRel;
algorithm
  otherParentsProcs := List.map1(otherParentsIn,Util.arrayGetIndexFirst,taskAssIn);
  parentsOnThreads := arrayCreate(numProc,{});
  parentsOnThreads := List.fold1(List.intRange(listLength(otherParentsProcs)),listIndecesForValues,otherParentsProcs,parentsOnThreads);
  parentsOnThreads := Util.arrayMap1(parentsOnThreads,mapListGet,otherParentsIn);
  lockCandidates := List.filterOnTrue(arrayList(parentsOnThreads),lengthNotOne);
  lockCandidates := List.map1(lockCandidates,removeLatestTaskFromList,orderIn);
  lockCandidatesFlat := List.flatten(lockCandidates);
  assLockIdc := List.map1(lockCandidatesFlat,getAssignLockString,nodeIn);
  taskLstAss := List.map(assLockIdc,getAssignLockTask);
  relLockIdc := List.map1(lockCandidatesFlat,getReleaseLockStringR,nodeIn);
  taskLstRel := List.map(relLockIdc,getReleaseLockTask);
  removeLocks := listAppend(removeLocksIn,taskLstAss);
  removeLocksOut := listAppend(removeLocks,taskLstRel);
end getSuperfluousLocks;

protected function removeLatestTaskFromList
  input list<Integer> taskLstIn;
  input list<Integer> taskOrderIn;
  output list<Integer> taskLstOut;
algorithm
  taskLstOut := match(taskLstIn,taskOrderIn)
    local
     list<Integer> posInOrder, taskLst;
     Integer latestTask;
    case({},_)
      equation
        then
          taskLstIn;
    case(_,_)
      equation
        posInOrder = List.map1(taskLstIn,List.position,taskOrderIn);  //just to remember, index starts at one
        latestTask = List.fold(posInOrder,intMax,-1);
        latestTask = listGet(taskOrderIn,latestTask+1);
        taskLst = List.removeOnTrue(latestTask,intEq,taskLstIn);
     then
       taskLst;
  end match;
end removeLatestTaskFromList;

protected function lengthNotOne
  input list<Integer> lstIn;
  output Boolean b;
algorithm
  b := intNe(listLength(lstIn),1);
end lengthNotOne;

protected function mapListGet
  input list<Integer> mapLstIn;
  input list<Integer> argLst;
  output list<Integer> mapLstOut;
algorithm
  mapLstOut := List.map1(mapLstIn,List.getIndexFirst,argLst);
end mapListGet;

protected function listIndecesForValues "folding function: write the index in array[i] whereas i is inLst(i) "
  input Integer idx;
  input list<Integer> lstIn;
  input array<list<Integer>> arrayIn;
  output array<list<Integer>> arrayOut;
protected
  Integer value;
  list<Integer> valueLst;
algorithm
  value := listGet(lstIn,idx);
  valueLst := arrayGet(arrayIn,value);
  valueLst := idx::valueLst;
  arrayOut := arrayUpdate(arrayIn,value,valueLst);
end listIndecesForValues;

protected function getAssignLockTask "outputs a AssignLockTsk for the given lockId.
author:Waurich TUD 2013-11"
  input String lockId;
  output HpcOmSimCode.Task taskOut;
algorithm
  taskOut := HpcOmSimCode.ASSIGNLOCKTASK(lockId);
end getAssignLockTask;

protected function getReleaseLockTask "outputs a ReleaseLockTsk for the given lockId.
author:Waurich TUD 2013-11"
  input String lockId;
  output HpcOmSimCode.Task taskOut;
algorithm
  taskOut := HpcOmSimCode.RELEASELOCKTASK(lockId);
end getReleaseLockTask;

protected function getAssignLockString
  input Integer predecessor;
  input Integer taskIdx;
  output String lockId;
algorithm
  lockId := intString(taskIdx)+&"_"+&intString(predecessor);
end getAssignLockString;

protected function getReleaseLockString
  input Integer successor;
  input Integer taskIdx;
  output String lockId;
algorithm
  lockId := intString(successor)+&"_"+&intString(taskIdx);
end getReleaseLockString;

protected function getReleaseLockStringR
  input Integer successor;
  input Integer taskIdx;
  output String lockId;
algorithm
  lockId := intString(taskIdx)+&"_"+&intString(successor);
end getReleaseLockStringR;

protected function getTaskAssignmentMCP "gets the assignment which nodes is computed of which processor for the MCP algorithm.
author:Waurich TUD 2013-10"
  input list<Integer> orderIn;
  input array<Real> alapIn;
  input Integer numProc;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  output array<Integer> taskAssOut;
  output array<list<Integer>> procAssOut;
protected
  list<Real> processorTime;
  array<Integer> taskAss;
  array<list<Integer>> procAss;
algorithm
  processorTime := List.fill(0.0,numProc);
  taskAss := arrayCreate(listLength(orderIn),0);
  procAss := arrayCreate(numProc,{});
  (taskAssOut,procAssOut) := getTaskAssignmentMCP1(orderIn,taskAss,procAss,processorTime,taskGraphIn,taskGraphMetaIn);
end getTaskAssignmentMCP;

protected function getTaskAssignmentMCP1
  input list<Integer> orderIn;
  input array<Integer> taskAssIn;
  input array<list<Integer>> procAssIn;
  input list<Real> processorTimeIn;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  output array<Integer> taskAssOut;
  output array<list<Integer>> procAssOut;
algorithm
  (taskAssOut,procAssOut) := matchcontinue(orderIn,taskAssIn,procAssIn,processorTimeIn,taskGraphIn,taskGraphMetaIn)
    local
      Integer node,processor;
      Real eft,exeCost, newTime;  //eft: earliest finishing time
      list<Integer>rest,taskLst;
      list<Real> processorTime;
      array<Integer> taskAss;
      array<list<Integer>> procAss;
    case({},_,_,_,_,_)
      equation
      then
        (taskAssIn,procAssIn);
    case(node::rest,_,_,_,_,_)
      equation
        eft = List.fold(processorTimeIn,realMin,listGet(processorTimeIn,1));
        processor = List.position(eft,processorTimeIn)+1;
        taskAss = arrayUpdate(taskAssIn,node,processor);
        taskLst = arrayGet(procAssIn,processor);
        taskLst = node::taskLst;
        procAss = arrayUpdate(procAssIn,processor,taskLst);
        // update the processorTimes
        ((_,exeCost)) = HpcOmTaskGraph.getExeCost(node,taskGraphMetaIn);
        newTime = eft +. exeCost;
        processorTime = List.replaceAt(newTime,processor-1,processorTimeIn);
        // next node
        (taskAss,procAss) = getTaskAssignmentMCP1(rest,taskAss,procAss,processorTime,taskGraphIn,taskGraphMetaIn);
      then
        (taskAss,procAss);
    else
      equation
        print("getTaskAssignmentMCP1 failed!\n");
      then
        fail();
  end matchcontinue;
end getTaskAssignmentMCP1;

//---------------------------
// quicksort with order
//---------------------------

public function quicksortWithOrder "sorts a list of Reals with the quicksort algorithm and outputs an additional list with the changed order of the original indeces.
author: Waurich TUD 2013-11"
  input list<Real> lstIn;
  output list<Real> lstOut;
  output list<Integer> orderOut;
algorithm
  (lstOut,orderOut) := matchcontinue(lstIn)
    local
      Integer length, pivotIdx;
      Real r1, r2, r3, pivotValue;
      list<Integer> orderTmp;
      list<Real> lstTmp;
    case(_)
      equation
        length = listLength(lstIn);
        orderTmp = List.intRange(length);
        r1 = List.first(lstIn);
        r2 = List.last(lstIn);
        r3 = listGet(lstIn,intDiv(length,2));
        (pivotValue,_) = getMedian3(r1,r2,r3);  // the pivot element.
        pivotIdx = List.position(pivotValue,lstIn)+1;
        (lstTmp,orderTmp) = quicksortWithOrder1(lstIn,orderTmp,pivotIdx,lstIn,length);
      then
        (lstTmp,orderTmp);
    case({r1})
      equation
      then
        ({r1},{1});
    case({})
      equation
      then
        ({},{});
  end matchcontinue;
end quicksortWithOrder;

protected function quicksortWithOrder1
  input list<Real> lstIn;
  input list<Integer> orderIn;
  input Integer pivotIdx;
  input list<Real> markedIn;
  input Integer size;
  output list<Real> lstOut;
  output list<Integer> orderOut;
algorithm
  (lstOut,orderOut) := match(lstIn,orderIn,pivotIdx,markedIn,size)
    local
      Boolean b1,b2,b3;
      Integer lIdx,rIdx,pivot;
      Real e,p,l,r,b;
      list<Integer> orderTmp;
      list<Real> marked;
      list<Real> lstTmp,leftLst,rightLst;
    case({},_,_,_,_)
      equation
      then ({},{});
    case({e},_,_,_,_)
      equation
      then ({e},{1});
    case(_,_,_,{},_)
      equation
      then (lstIn,orderIn);
    else
      equation
        p = listGet(lstIn,pivotIdx);
        (leftLst,rightLst)= List.split(lstIn,pivotIdx);
        rightLst = listReverse(rightLst);
        (_,lIdx,b1) = getMemberOnTrueWithIdx(p,leftLst,realLt);
        (_,rIdx,b2) = getMemberOnTrueWithIdx(p,rightLst,realGt);
        rIdx = size+1-rIdx;
        lstTmp = Debug.bcallret3(b1,swapEntriesInList,pivotIdx,lIdx,lstIn,lstIn);
        lstTmp = Debug.bcallret3(b2,swapEntriesInList,pivotIdx,rIdx,lstTmp,lstTmp);
        orderTmp = Debug.bcallret3(b1,swapEntriesInList,pivotIdx,lIdx,orderIn,orderIn);
        orderTmp = Debug.bcallret3(b2,swapEntriesInList,pivotIdx,rIdx,orderTmp,orderTmp);
        b3 = boolAnd(boolNot(b1),boolNot(b2)); // if both are false(no member left or rigth found) than the pivot has the right place
        ((marked,pivot)) = Debug.bcallret3(b3,getNextPivot,lstTmp,markedIn,pivotIdx,((markedIn,pivotIdx)));

        (lstTmp,orderTmp) = quicksortWithOrder1(lstTmp,orderTmp,pivot,marked,size);
      then
        (lstTmp,orderTmp);
  end match;
end quicksortWithOrder1;

protected function getNextPivot "removes the pivot from the markedLst and computes a new one.
author:Waurich TUD 2013-11"
  input list<Real> lstIn;
  input list<Real> markedLstIn;
  input Integer pivotIdx;
  output tuple<list<Real>,Integer> tplOut;
algorithm
  tplOut := match(lstIn,markedLstIn,pivotIdx)
    local
      Integer newIdx,midIdx;
      Real pivotElement,r1,r2,r3,e;
      list<Real> marked,rest;
    case(_,{_},_)
      then
        (({},0));
    case(_,_::_,_)
      equation
        pivotElement = listGet(lstIn,pivotIdx);
        marked = List.deleteMember(markedLstIn,pivotElement);
        r1 = List.first(marked);
        r2 = List.last(marked);
        midIdx = intDiv(listLength(marked),2);
        midIdx = Util.if_(intEq(midIdx,0),1,midIdx);
        r3 = listGet(marked,midIdx);
        (pivotElement,_) = getMedian3(r1,r2,r3);
        newIdx = List.position(pivotElement,lstIn)+1;
      then
        ((marked,newIdx));
  end match;
end getNextPivot;

protected function getMemberOnTrueWithIdx "same as getMemberOnTrue, but with index of the found element and a Boolean, if the element was found.!function does not fail!
author:Waurich TUD 2013-11"
  input Real inValue;
  input list<Real> inList;
  input CompFunc inCompFunc;
  output Real outElement;
  output Integer outIdx;
  output Boolean found;
  partial function CompFunc
    input Real inValue;
    input Real inElement;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  (outElement,outIdx,found) := getMemberOnTrueWithIdx1(1,inValue,inList,inCompFunc);
end getMemberOnTrueWithIdx;

public function getMemberOnTrueWithIdx1 "implementation of getMemberOnTrueWithIdx.
author:Waurich TUD 2013-11"
  input Integer inIdx;
  input Real inValue;
  input list<Real> inList;
  input CompFunc inCompFunc;
  output Real outElement;
  output Integer outIdx;
  output Boolean found;
  partial function CompFunc
    input Real inValue;
    input Real inElement;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  (outElement,outIdx,found) := matchcontinue(inIdx,inValue,inList,inCompFunc)
    local
      Real e,value;
      list<Real> rest,lst;
      Integer idx;
      Boolean b;
    case(_,_,{},_)
      equation
      then
        (0.0,0,false);
    case (_,_, e :: _, _)
      equation
        b = inCompFunc(inValue, e);
        true = b;
      then
        (e,inIdx,b);
    case (_,_, _ :: rest, _)
      equation
        (value,idx,b) = getMemberOnTrueWithIdx1(inIdx+1,inValue, rest, inCompFunc);
      then (value,idx,b);
  end matchcontinue;
end getMemberOnTrueWithIdx1;

protected function swapEntriesInList"swaps the entries given by the indeces.
author:Waurich TUD 2013-11"
  replaceable type ElementType subtypeof Any;
  input Integer idx1;
  input Integer idx2;
  input list<ElementType> lstIn;
  output list<ElementType> lstOut;
protected
  ElementType r1,r2;
  list<ElementType> lstTmp;
algorithm
  r1 := listGet(lstIn,idx1);
  r2 := listGet(lstIn,idx2);
  lstTmp := List.replaceAt(r1,idx2-1,lstIn);
  lstOut := List.replaceAt(r2,idx1-1,lstTmp);
end swapEntriesInList;

protected function getMedian3 "gets the median of the 3 reals and the info which of the inputs is the median"
  input Real r1;
  input Real r2;
  input Real r3;
  output Real rOut;
  output Integer which;
protected
  list<Real> r;
algorithm
  r := List.sort({r1,r2,r3},realGt);
  rOut := listGet(r,2);
  which := List.position(rOut,{r1,r2,r3})+1;
end getMedian3;

//----------------------------
// traverse the task graph bottoms up (beginning at the root nodes)
//----------------------------

protected function computeGraphValuesBottomUp "the graph is traversed bottom up
computes the earliest possible start time (As Soon As Possible) and the earliest completion time for every node in the task graph.
author:Waurich TUD 2014-05"
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  output array<Real> asapOut;  //as-soon-as-possible times, taking communication costs into accout
  output array<Real> estOut; // earliest start time, does not consider communication costs (all tasks on one processor)
  output array<Real> ectOut;  // earliest completion time, does not consider communication costs (all tasks on one processor)
protected
  Integer size;
  list<Integer> rootNodes;
  array<Real> asap, ect, est;
  HpcOmTaskGraph.TaskGraph taskGraphT;
algorithm
  size := arrayLength(iTaskGraph);
  rootNodes := HpcOmTaskGraph.getRootNodes(iTaskGraph);
  taskGraphT := BackendDAEUtil.transposeMatrix(iTaskGraph,size);
  asap := arrayCreate(size,-1.0);
  est := arrayCreate(size,-1.0);
  ect := arrayCreate(size,-1.0);
  (asapOut,estOut,ectOut) := computeGraphValuesBottomUp1(rootNodes,iTaskGraph,taskGraphT,iTaskGraphMeta,asap,est,ect);
end computeGraphValuesBottomUp;

protected function computeGraphValuesBottomUp1"implementation of computeGraphValuesBottomUp"
  input list<Integer> parentsIn;
  input HpcOmTaskGraph.TaskGraph graph;
  input HpcOmTaskGraph.TaskGraph graphT;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Real> asapIn;
  input array<Real> estIn;
  input array<Real> ectIn;
  output array<Real> asapOut;
  output array<Real> estOut;
  output array<Real> ectOut;
algorithm
  (asapOut,estOut,ectOut) := matchcontinue(parentsIn,graph,graphT,iTaskGraphMeta,asapIn,estIn,ectIn)
    local
      Integer node;
      Real maxASAP, maxEct, exeCost;
      array<Real> asap, ect, est;
      list<Integer> rest, parents, children;
      list<Real> parentEcts, parentAsaps, parentAsaps2, parentsExeCosts, commCosts, ectsWithComm; //ect: earliestCompletionTime
  case(node::rest,_,_,_,_,_,_)
    equation
      // all parents have been investigated, update this node
      parents = arrayGet(graphT,node);
      parentAsaps = List.map1(parents,Util.arrayGetIndexFirst,asapIn); // the parent asaps
      false = List.isMemberOnTrue(-1.0,parentAsaps,realEq);
      exeCost = HpcOmTaskGraph.getExeCostReqCycles(node,iTaskGraphMeta);
      parentsExeCosts = List.map1(parents,HpcOmTaskGraph.getExeCostReqCycles,iTaskGraphMeta);
      commCosts = List.map2(parents,HpcOmTaskGraph.getCommCostBetweenNodesInCycles,node,iTaskGraphMeta);
      parentAsaps2 = List.threadMap(parentAsaps,parentsExeCosts,realAdd); // add the exeCosts
      parentAsaps2 = List.threadMap(parentAsaps2,commCosts,realAdd); // add commCosts
      maxASAP = List.fold(parentAsaps2,realMax,0.0);
      asap = arrayUpdate(asapIn,node,maxASAP);
      parentEcts = List.map1(parents,Util.arrayGetIndexFirst,ectIn);
      maxEct = List.fold(parentEcts,realMax,0.0);
      est = arrayUpdate(estIn,node,maxEct);
      ect = arrayUpdate(ectIn,node,realAdd(maxEct,exeCost));
      children = arrayGet(graph,node);
      rest = listAppend(rest,children);
      (asap,est,ect) = computeGraphValuesBottomUp1(rest,graph,graphT,iTaskGraphMeta,asap,est,ect);
    then (asap,est,ect);
  case(node::rest,_,_,_,_,_,_)
    equation
      // some parents have not been investigated, skip this node
      parents = arrayGet(graphT,node);
      parentAsaps = List.map1(parents,Util.arrayGetIndexFirst,asapIn);
      true = List.isMemberOnTrue(-1.0,parentAsaps,realEq);
      rest = listAppend(rest,{node});
      (asap,est,ect) = computeGraphValuesBottomUp1(rest,graph,graphT,iTaskGraphMeta,asapIn,estIn,ectIn);
    then
      (asap,est,ect);
  case({},_,_,_,_,_,_)
    then (asapIn,estIn,ectIn);
  else
    equation
      print("computeGraphValuesBottomUp1 failed!\n");
    then fail();
  end matchcontinue;
end computeGraphValuesBottomUp1;

//----------------------------
// traverse the task graph top down (beginning at the leaf nodes)
//----------------------------

protected function computeGraphValuesTopDown "traverse the graph top down (the transposed graph bottom up)
computes the latest allowable start time (As Late As Possible) and the latest allowable compeltino time for every node in the task graph.
author:Waurich TUD 2013-10"
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  output array<Real> alapOut; // = as-late-as-possble times, taking communication time between every node into account, used for mcp-scheduler
  output array<Real> lastOut; // = latest allowed starting time, does not consider communication costs, used for tds
  output array<Real> lactOut; // = latest allowed completion time, does not consider communication costs, used for tds
  output array<Real> tdsLevelOut;  // = the longest path to a leaf node, considering only execution costs (no! commCosts), used for tds
protected
  Integer size, lastNodeInCP;
  Real cp,cpWithComm, lastExeCost;
  list<Integer> endNodes;
  array<Real> alap, lact, last, tdsLevel;
  array<list<Integer>> taskGraphT;
algorithm
  size := arrayLength(iTaskGraph);
  // traverse the taskGraph topdown to get the alap times
  taskGraphT := BackendDAEUtil.transposeMatrix(iTaskGraph,size);
  endNodes := HpcOmTaskGraph.getLeafNodes(iTaskGraph);
  alap := arrayCreate(size,-1.0);
  last := arrayCreate(size,-1.0);
  lact := arrayCreate(size,-1.0);
  tdsLevel := arrayCreate(size,-1.0);
  (alap,last,lact,tdsLevelOut) := computeGraphValuesTopDown1(endNodes,iTaskGraph,taskGraphT,iTaskGraphMeta,alap,last,lact,tdsLevel);
  cpWithComm := Util.arrayFold(alap,realMax,0.0);
  lastNodeInCP := Util.arrayMemberNoOpt(alap,size,cpWithComm);
  lastExeCost := HpcOmTaskGraph.getExeCostReqCycles(lastNodeInCP,iTaskGraphMeta);
  cp := Util.arrayFold(last,realMax,0.0);
  alapOut := Util.arrayMap1(alap,realSubr,cpWithComm);
  lactOut := Util.arrayMap1(lact,realSubr,cp);
  lastOut := Util.arrayMap1(last,realSubr,cp);
end computeGraphValuesTopDown;

protected function computeGraphValuesTopDown1 "traverses the taskGraph topdown starting with the end nodes of the original non-transposed graph.
author: Waurich TUD 2013-10"
  input list<Integer> nodesIn;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Real> alapIn;
  input array<Real> lastIn;
  input array<Real> lactIn;
  input array<Real> tdsLevelIn;
  output array<Real> alapOut;
  output array<Real> lastOut;
  output array<Real> lactOut;
  output array<Real> tdsLevelOut;
algorithm
  (alapOut,lastOut,lactOut,tdsLevelOut) := matchcontinue(nodesIn,iTaskGraph,iTaskGraphT,iTaskGraphMeta,alapIn,lastIn,lactIn,tdsLevelIn)
    local
      Boolean computeValues;
      Integer nodeIdx, pos;
      Real nodeExeCost, maxLevel, maxAlap, maxLast, maxLact;
      list<Integer> rest, parentNodes, childNodes;
      list<Real> childTDSLevels, childAlaps, childLasts, childLacts, commCostsToChilds;
      array<Real> alap,last,lact,tdsLevel;
  case({},_,_,_,_,_,_,_)
    then (alapIn,lastIn,lactIn,tdsLevelIn);
  case(nodeIdx::rest,_,_,_,_,_,_,_)
    equation
      // the current Node is a leaf node
      childNodes = arrayGet(iTaskGraph,nodeIdx);
      true = List.isEmpty(childNodes);
      nodeExeCost = HpcOmTaskGraph.getExeCostReqCycles(nodeIdx,iTaskGraphMeta);
      alap = arrayUpdate(alapIn,nodeIdx,nodeExeCost);
      last = arrayUpdate(lastIn,nodeIdx,nodeExeCost);
      lact = arrayUpdate(lactIn,nodeIdx,0.0);
      tdsLevel = arrayUpdate(tdsLevelIn,nodeIdx,nodeExeCost);
      parentNodes = arrayGet(iTaskGraphT,nodeIdx);
      rest = listAppend(rest,parentNodes);
      (alap,last,lact,tdsLevel) = computeGraphValuesTopDown1(rest,iTaskGraph,iTaskGraphT,iTaskGraphMeta,alap,last,lact,tdsLevel);
    then (alap,last,lact,tdsLevel);
  case(nodeIdx::rest,_,_,_,_,_,_,_)
    equation
      // all of the childNodes of the current Node have been investigated
      childNodes = arrayGet(iTaskGraph,nodeIdx);
      childTDSLevels = List.map1(childNodes,Util.arrayGetIndexFirst,tdsLevelIn);
      false = List.isMemberOnTrue(-1.0,childTDSLevels,realEq);
      nodeExeCost = HpcOmTaskGraph.getExeCostReqCycles(nodeIdx,iTaskGraphMeta);
      commCostsToChilds = List.map2rm(childNodes,HpcOmTaskGraph.getCommCostBetweenNodesInCycles,nodeIdx,iTaskGraphMeta);  // only for alap
      childAlaps = List.map1(childNodes,Util.arrayGetIndexFirst,alapIn);
      childAlaps = List.threadMap(childAlaps,commCostsToChilds,realAdd);
      childLasts = List.map1(childNodes,Util.arrayGetIndexFirst,lastIn);
      childLacts = List.map1(childNodes,Util.arrayGetIndexFirst,lactIn);
      maxLevel = List.fold(childTDSLevels,realMax,0.0);
      maxAlap = List.fold(childAlaps,realMax,0.0);
      maxLast = List.fold(childLasts,realMax,0.0);
      maxLact = List.fold(childLacts,realMax,0.0);
      tdsLevel = arrayUpdate(tdsLevelIn,nodeIdx,nodeExeCost +. maxLevel);
      alap = arrayUpdate(alapIn,nodeIdx,nodeExeCost +. maxAlap);
      last = arrayUpdate(lastIn,nodeIdx,nodeExeCost +. maxLast);
      lact = arrayUpdate(lactIn,nodeIdx,maxLast);
      parentNodes = arrayGet(iTaskGraphT,nodeIdx);
      rest = listAppend(rest,parentNodes);
      (alap,last,lact,tdsLevel) = computeGraphValuesTopDown1(rest,iTaskGraph,iTaskGraphT,iTaskGraphMeta,alap,last,lact,tdsLevel);
    then (alap,last,lact,tdsLevel);
  case(nodeIdx::rest,_,_,_,_,_,_,_)
    equation
      // not all of the childNodes of the current Node have been investigated
      childNodes = arrayGet(iTaskGraph,nodeIdx);
      childTDSLevels = List.map1(childNodes,Util.arrayGetIndexFirst,tdsLevelIn);
      true = List.isMemberOnTrue(-1.0,childTDSLevels,realEq);
      rest = listAppend(rest,{nodeIdx});
      (alap,last,lact,tdsLevel) = computeGraphValuesTopDown1(rest,iTaskGraph,iTaskGraphT,iTaskGraphMeta,alapIn,lastIn,lactIn,tdsLevelIn);
    then (alap,last,lact,tdsLevel);
  else
    equation
      print("computeGraphValuesTopDown1 failed!\n");
    then fail();
  end matchcontinue;
end computeGraphValuesTopDown1;

protected function realSubr
  input Real r1;
  input Real r2;
  output Real r3;
algorithm
  r3 := realSub(r2,r1);
end realSubr;

//-----
// Util
//-----

public function printSchedule
  input HpcOmSimCode.Schedule iSchedule;
protected
  array<list<HpcOmSimCode.Task>> threadTasks;
  list<HpcOmSimCode.TaskList> tasksOfLevels;
  list<tuple<HpcOmSimCode.Task, list<Integer>>> taskDepTasks;
algorithm
  _ := match(iSchedule)
    case(HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks))
      equation
        _ = Util.arrayFold(threadTasks, printThreadSchedule, 1);
      then ();
    case(HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevels))
      equation
        _ = List.fold(tasksOfLevels,printLevelSchedule,1);
      then ();
    case(HpcOmSimCode.TASKDEPSCHEDULE(tasks=taskDepTasks))
      equation
        List.map_0(taskDepTasks,printTaskDepSchedule);
      then ();
    else fail();
  end match;
end printSchedule;

public function analyseScheduledTaskGraph"functions to analyse the scheduled task graph can be applied in here.
author:Waurich TUD 2013-12"
  input HpcOmSimCode.Schedule scheduleIn;
  input Integer numProcIn;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  output String criticalPathInfoOut;
algorithm
  criticalPathInfoOut := match(scheduleIn,numProcIn,taskGraphIn,taskGraphMetaIn)
    local
      list<String> lockIdc;
      list<Real> levelCosts;
      list<HpcOmSimCode.TaskList> levels;
      list<list<Integer>> parallelSets;
      list<list<Integer>> criticalPaths, criticalPathsWoC;
      list<list<Real>> levelSectionCosts;
      array<list<HpcOmSimCode.Task>> threadTasks;
      Real cpCosts, cpCostsWoC, serTime, parTime, speedUp, speedUpMax;
      String criticalPathInfo;
    case(HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=levels),_,_,_)
      equation
        //get the criticalPath
        ((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC),_) = HpcOmTaskGraph.getCriticalPaths(taskGraphIn,taskGraphMetaIn);
        // predict speedUp
        levelSectionCosts = List.map1(levels, getLevelListTaskCosts, taskGraphMetaIn);
        serTime = realSum(List.map(levelSectionCosts,realSum));
        serTime = HpcOmTaskGraph.roundReal(serTime,2);
        levelCosts = List.map1(levelSectionCosts,getLevelParallelTime,numProcIn);
        parTime = List.fold(levelCosts,realAdd,0.0);
        parTime = HpcOmTaskGraph.roundReal(parTime,2);
        criticalPathInfo = HpcOmTaskGraph.dumpCriticalPathInfo((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC));
        Debug.fcall(Flags.HPCOM_DUMP,print,"the serialCosts: "+&realString(serTime)+&"\n");
        Debug.fcall(Flags.HPCOM_DUMP,print,"the parallelCosts: "+&realString(parTime)+&"\n");
        printPredictedExeTimeInfo(serTime,parTime,realDiv(serTime,parTime),realDiv(serTime,cpCostsWoC),numProcIn);
      then
        criticalPathInfo;
    case(HpcOmSimCode.THREADSCHEDULE(lockIdc=lockIdc),_,_,_)
      equation
        Debug.fcall(Flags.HPCOM_DUMP,print,"the number of locks: "+&intString(listLength(lockIdc))+&"\n");
        //get the criticalPath
        ((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC),_) = HpcOmTaskGraph.getCriticalPaths(taskGraphIn,taskGraphMetaIn);
        criticalPathInfo = HpcOmTaskGraph.dumpCriticalPathInfo((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC));
        //predict speedup etc.
        (serTime,parTime,speedUp,speedUpMax) = predictExecutionTime(scheduleIn,SOME(cpCostsWoC),numProcIn,taskGraphIn,taskGraphMetaIn);
        serTime = HpcOmTaskGraph.roundReal(serTime,2);
        parTime = HpcOmTaskGraph.roundReal(parTime,2);
        cpCostsWoC = HpcOmTaskGraph.roundReal(cpCostsWoC,2);
        Debug.fcall(Flags.HPCOM_DUMP,print,"the serialCosts: "+&realString(serTime)+&"\n");
        Debug.fcall(Flags.HPCOM_DUMP,print,"the parallelCosts: "+&realString(parTime)+&"\n");
        Debug.fcall(Flags.HPCOM_DUMP,print,"the cpCosts: "+&realString(cpCostsWoC)+&"\n");
        printPredictedExeTimeInfo(serTime,parTime,speedUp,speedUpMax,numProcIn);
      then
        criticalPathInfo;
    else
      equation
      then
        "";
  end match;
end analyseScheduledTaskGraph;

protected function getLevelParallelTime"computes the the time for the parallel computation of a parallel section
author:Waurich TUD 2014-06"
  input list<Real> sectionCosts;
  input Integer numProc;
  output Real levelCost;
protected
  array<Real> workload;
algorithm
  workload := arrayCreate(numProc,0.0);
  workload := List.fold(sectionCosts,getLevelParallelTime1,workload);
  levelCost := Util.arrayFold(workload,realMax,0.0);
end getLevelParallelTime;

protected function getLevelParallelTime1"helper function for getLevelParallelTime. distributes the current section to the thread with the least workload
author:Waurich TUD 2014-06"
  input Real sectionCost;
  input array<Real> threadWorkLoadIn;
  output array<Real> threadWorkLoadOut;
protected
  Real minWorkLoad;
  Integer minWLThread;
algorithm
  minWorkLoad := Util.arrayFold(threadWorkLoadIn,realMin,arrayGet(threadWorkLoadIn,1));
  minWLThread := List.position(minWorkLoad,arrayList(threadWorkLoadIn))+1;
  threadWorkLoadOut := arrayUpdate(threadWorkLoadIn,minWLThread,minWorkLoad +. sectionCost);
end getLevelParallelTime1;

protected function getLevelListTaskCosts
  input HpcOmSimCode.TaskList iTaskList;
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  output list<Real> costsOut;
protected
  list<HpcOmSimCode.Task> tasks;
  list<Real> costs;
algorithm
  costsOut := match(iTaskList, iMeta)
    case(HpcOmSimCode.PARALLELTASKLIST(tasks=tasks),_)
      equation
        costs = List.map1(tasks,getLevelTaskCosts,iMeta);
      then costs;
    case(HpcOmSimCode.SERIALTASKLIST(tasks=tasks),_)
      equation
        costs = List.map1(tasks,getLevelTaskCosts,iMeta);
      then costs;
    else
      equation
        print("getLevelTaskCosts failed!\n");
      then {};
  end match;
end getLevelListTaskCosts;

protected function getLevelTaskCosts
  input HpcOmSimCode.Task levelTask;
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  output Real costsOut;
algorithm
  costsOut := match(levelTask,iMeta)
    local
      list<Integer> nodeIdc;
      list<Real> nodeCosts;
      Real costs;
    case(HpcOmSimCode.CALCTASK_LEVEL(nodeIdc=nodeIdc),_)
      equation
        nodeCosts = List.map1(nodeIdc,HpcOmTaskGraph.getExeCostReqCycles,iMeta);
        costs = List.fold(nodeCosts,realAdd,0.0);
      then costs;
    else
      equation
        print("getLevelTaskCosts failed!\n");
      then
        fail();
  end match;
end getLevelTaskCosts;

public function predictExecutionTime  "computes the theoretically execution time for the serial simulation and the parallel. a speedup ratio is determined by su=serTime/parTime.
the max speedUp is computed via the serTime/criticalPathCosts.
author:Waurich TUD 2013-11"
  input HpcOmSimCode.Schedule scheduleIn;
  input Option<Real> cpCostsOption;
  input Integer numProc;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  output Real serialTimeOut;
  output Real parallelTimeOut;
  output Real speedUpOut;
  output Real speedUpMaxOut;
algorithm
  (serialTimeOut,parallelTimeOut,speedUpOut,speedUpMaxOut) := matchcontinue(scheduleIn,cpCostsOption,numProc,taskGraphIn,taskGraphMetaIn)
    local
      Real parTime, serTime, speedUp, speedUpMax, cpCosts;
      HpcOmSimCode.Schedule schedule;
    case(_,NONE(),_,_,_)
      equation
        true = intNe(arrayLength(taskGraphIn),0); //is an ODE system
        (_,parTime) = getFinishingTimesForSchedule(scheduleIn,numProc,taskGraphIn,taskGraphMetaIn);
        serTime = getSerialExecutionTime(taskGraphMetaIn);
        speedUp = serTime /. parTime;
      then
        (serTime,parTime,speedUp,-1.0);
    case(_,SOME(cpCosts),_,_,_)
      equation
        true = intNe(arrayLength(taskGraphIn),0);  //is an ODE system
        (_,parTime) = getFinishingTimesForSchedule(scheduleIn,numProc,taskGraphIn,taskGraphMetaIn);
        serTime = getSerialExecutionTime(taskGraphMetaIn);
        speedUp = serTime /. parTime;
        speedUpMax = serTime /. cpCosts;
      then
        (serTime,parTime,speedUp,speedUpMax);
    else
      equation
      then
        (0.0,0.0,0.0,0.0);
  end matchcontinue;
end predictExecutionTime;

public function printPredictedExeTimeInfo "function to print the information about the predicted execution times.
author:Waurich TUD 2013-11"
  input Real serTime;
  input Real parTime;
  input Real speedUp;
  input Real speedUpMax;
  input Integer numProc;
algorithm
  _ := matchcontinue(serTime,parTime,speedUp,speedUpMax,numProc)
    local
      String isOkString, isNotOkString;
    case(_,_,_,0.0,_)// possibly there is no ode-system that can be parallelized
      equation
      then
        ();
    case(_,_,_,_,_)
      equation
        true = speedUpMax ==. -1.0;
        Debug.bcall(Flags.isSet(Flags.HPCOM_DUMP),print,"The predicted SpeedUp with "+&intString(numProc)+&" processors is " +& System.snprintff("%.2f", 25, speedUp) +& ".\n");
      then
        ();
    else
      equation
        isOkString = "The predicted SpeedUp with "+&intString(numProc)+&" processors is: "+& System.snprintff("%.2f", 25, speedUp)+&" With a theoretical maxmimum speedUp of: "+& System.snprintff("%.2f", 25, speedUpMax)+&"\n";
        isNotOkString = "Something is weird. The predicted SpeedUp is "+& System.snprintff("%.2f", 25, speedUp)+&" and the theoretical maximum speedUp is "+& System.snprintff("%.2f", 25, speedUpMax)+&"\n";
        Debug.bcall(realGt(speedUp,speedUpMax) and Flags.isSet(Flags.HPCOM_DUMP),print,isNotOkString);
        Debug.bcall(realLe(speedUp,speedUpMax) and Flags.isSet(Flags.HPCOM_DUMP),print,isOkString);
      then
        ();
  end matchcontinue;
end printPredictedExeTimeInfo;

public function getSerialExecutionTime  "computes thes serial execution time by summing up all exeCosts of all tasks.
author:Waurich TUD 2013-11"
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  output Real serialTimeOut;
protected
  list<Integer> odeComps;
  list<Real> exeCostsReal;
  array<Real> exeCosts1;
  array<list<Integer>> inComps;
  array<tuple<Integer, Real>> exeCosts;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(exeCosts=exeCosts, inComps=inComps) := taskGraphMetaIn;
  odeComps := Util.arrayFold(inComps,listAppend,{});
  exeCosts1 := Util.arrayMap(exeCosts,Util.tuple22);
  exeCostsReal := List.map1(odeComps,Util.arrayGetIndexFirst,exeCosts1);
  serialTimeOut := List.fold(exeCostsReal,realAdd,0.0);
end getSerialExecutionTime;

protected function getFinishingTimesForSchedule"computes the finishing times for the schedule. Works not for empty systems!!!
author:Waurich TUD 2013-11"
  input HpcOmSimCode.Schedule scheduleIn;
  input Integer numProc;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  output HpcOmSimCode.Schedule scheduleOut;
  output Real finishingTime;
algorithm
  (scheduleOut,finishingTime) := match(scheduleIn,numProc,taskGraphIn,taskGraphMetaIn)
    local
      Real finTime;
      array<Integer> taskIdcs; // idcs of the current Task for every proc.
      array<Real> finTimes;
      HpcOmTaskGraph.TaskGraph taskGraphT;
      array<HpcOmSimCode.Task> checkedTasks, lastTasks;
      array<list<HpcOmSimCode.Task>> threadTasks, threadTasksNew;
      list<String> lockIdc;
      list<list<HpcOmSimCode.Task>> tasksOfLevels;
      HpcOmSimCode.Task task;
      HpcOmSimCode.Schedule schedule;
    case(HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,lockIdc=lockIdc),_,_,_)
      equation
        taskIdcs = arrayCreate(arrayLength(threadTasks),1);  // the TaskIdcs to be checked for every thread
        taskGraphT = BackendDAEUtil.transposeMatrix(taskGraphIn,arrayLength(taskGraphIn));
        checkedTasks = arrayCreate(arrayLength(taskGraphIn),HpcOmSimCode.TASKEMPTY());
        threadTasksNew = computeTimeFinished(threadTasks,taskIdcs,1,checkedTasks,taskGraphIn,taskGraphT,taskGraphMetaIn,numProc,{});
        finTimes = Util.arrayMap(threadTasksNew,getTimeFinishedOfLastTask);
        finTime = Util.arrayFold(finTimes,realMax,0.0);
        schedule = HpcOmSimCode.THREADSCHEDULE(threadTasksNew,lockIdc);
      then
        (schedule,finTime);
    case(HpcOmSimCode.LEVELSCHEDULE(_),_,_,_)
      equation
        schedule = scheduleIn;
        finTime = 0.0;
      then
        (schedule,finTime);
    case(HpcOmSimCode.EMPTYSCHEDULE(),_,_,_)
      equation
        schedule = scheduleIn;
        finTime = -1.0;
      then
        (schedule,finTime);
  end match;
end getFinishingTimesForSchedule;

protected function getTimeFinishedOfLastTask "get the timeFinished of the last task of a thread. if the thread is empty its -1.0.
author:Waurich TUD 2013-11"
  input list<HpcOmSimCode.Task> threadTasksIn;
  output Real finTimeOut;
algorithm
  finTimeOut := matchcontinue(threadTasksIn)
    local
      HpcOmSimCode.Task lastTask;
      Real finTime;
    case(_)
      equation
        lastTask = List.last(threadTasksIn);
        finTime = getTimeFinished(lastTask);
      then
        finTime;
    case({})
      equation
      then
        -1.0;
  end matchcontinue;
end getTimeFinishedOfLastTask;

protected function computeTimeFinished  "traverses all threads bottoms up.
author:Waurich TUD 2013-11"
  input array<list<HpcOmSimCode.Task>> threadTasksIn;
  input array<Integer> taskIdcsIn;
  input Integer threadIdxIn;
  input array<HpcOmSimCode.Task> checkedTasksIn;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraph taskGraphTIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  input Integer numProc;
  input list<Integer> closedThreads;
  output array<list<HpcOmSimCode.Task>> threadTasksOut;
algorithm
  threadTasksOut := matchcontinue(threadTasksIn,taskIdcsIn,threadIdxIn,checkedTasksIn,taskGraphIn,taskGraphTIn,taskGraphMetaIn,numProc,closedThreads)
    local
      Boolean isCalc, isComputable;
      Integer taskIdx, nextThreadIdx, nextTaskIdx;
      array<Integer> taskIdcs;
      list<Integer> closedThreads1;
      HpcOmSimCode.Task task;
      array<list<HpcOmSimCode.Task>> threadTasks;
      array<HpcOmSimCode.Task> checkedTasks;
      list<HpcOmSimCode.Task> thread;
    case(_,_,_,_,_,_,_,_,_)
      equation
        // get the task
        true = threadIdxIn <= arrayLength(taskIdcsIn);
        taskIdx = arrayGet(taskIdcsIn,threadIdxIn);
        thread = arrayGet(threadTasksIn,threadIdxIn);
        true = taskIdx <= listLength(thread);
        task = listGet(thread,taskIdx);
        //compute timeFinished for the task
        (threadTasks,checkedTasks,nextTaskIdx) = updateFinishingTime(task,taskIdx,threadIdxIn,threadTasksIn,checkedTasksIn,taskGraphTIn,taskGraphMetaIn);
        taskIdcs = arrayUpdate(taskIdcsIn,threadIdxIn,nextTaskIdx);
        nextThreadIdx = getNextThreadIdx(threadIdxIn,closedThreads,numProc);
        threadTasks = computeTimeFinished(threadTasks,taskIdcs,nextThreadIdx,checkedTasks,taskGraphIn,taskGraphTIn,taskGraphMetaIn,numProc,closedThreads);
      then
        threadTasks;
    case(_,_,_,_,_,_,_,_,_)
      equation
        // next thread
        true = threadIdxIn > arrayLength(taskIdcsIn);
        nextThreadIdx = Util.if_(intGe(threadIdxIn,numProc),1,threadIdxIn+1);
        threadTasks = computeTimeFinished(threadTasksIn,taskIdcsIn,nextThreadIdx,checkedTasksIn,taskGraphIn,taskGraphTIn,taskGraphMetaIn,numProc,closedThreads);
      then
        threadTasks;
    case(_,_,_,_,_,_,_,_,_)
      equation
        // thread done
        true = threadIdxIn <= arrayLength(taskIdcsIn);
        taskIdx = arrayGet(taskIdcsIn,threadIdxIn);
        thread = arrayGet(threadTasksIn,threadIdxIn);
        true = taskIdx > listLength(thread);
        false = listLength(closedThreads) == numProc;
        nextThreadIdx = Util.if_(intGe(threadIdxIn,numProc),1,threadIdxIn+1);
        closedThreads1 = threadIdxIn::closedThreads;
        closedThreads1 = List.unique(closedThreads1);
        threadTasks = computeTimeFinished(threadTasksIn,taskIdcsIn,nextThreadIdx,checkedTasksIn,taskGraphIn,taskGraphTIn,taskGraphMetaIn,numProc,closedThreads1);
      then
        threadTasks;
    case(_,_,_,_,_,_,_,_,_)
      equation
        // done with all threads
        true = listLength(closedThreads) == numProc;
      then
        threadTasksIn;
    else
      equation
        print("computeTimeFinished failed!\n");
      then
        fail();
  end matchcontinue;
end computeTimeFinished;

protected function getNextThreadIdx "computes the index of the next thread that should be analysed.
The closed threads are not possible and if the last thread is input, the first is chosen.
author:Waurich TUD 2013-11"
  input Integer threadId;
  input list<Integer> closedThreads;
  input Integer numThreads;
  output Integer nextThreadOut;
protected
  Boolean isLastThread, isClosed;
  Integer nextThread;
algorithm
  isLastThread := intEq(threadId,numThreads);
  nextThread := Util.if_(isLastThread,1,threadId+1);
  isClosed := List.isMemberOnTrue(nextThread,closedThreads,intEq);
  nextThreadOut := Debug.bcallret3(isClosed, getNextThreadIdx, nextThread, closedThreads, numThreads, nextThread);
end getNextThreadIdx;

protected function updateFinishingTime "updates the finishing times.
author:Waurich TUD 2013-11"
  input HpcOmSimCode.Task taskIn;
  input Integer taskIdxIn;
  input Integer threadIdxIn;
  input array<list<HpcOmSimCode.Task>> threadTasksIn;
  input array<HpcOmSimCode.Task> checkedTasksIn;
  input HpcOmTaskGraph.TaskGraph taskGraphTIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  output array<list<HpcOmSimCode.Task>> threadTasksOut;
  output array<HpcOmSimCode.Task> checkedTasksOut;
  output Integer taskIdxOut;
algorithm
  (threadTasksOut,checkedTasksOut,taskIdxOut) := match(taskIn,taskIdxIn,threadIdxIn,threadTasksIn,checkedTasksIn,taskGraphTIn,taskGraphMetaIn)
    local
      Boolean isComputable;
      Integer taskID, taskIdxNew;
      Real finishingTime;
      list<Integer> parentLst;
      HpcOmSimCode.Task latestTask,startTask;
      array<HpcOmSimCode.Task> checkedTasks;
      array<list<HpcOmSimCode.Task>> threadTasks;
    case(HpcOmSimCode.CALCTASK(weighting=_,index=taskID,calcTime=_,timeFinished=_,threadIdx=_,eqIdc=_),_,_,_,_,_,_)
      equation
        parentLst = arrayGet(taskGraphTIn,taskID);
        // gets the parentIdcs which are not yet checked and computes the latest finishingTime of all parentNodes
        ((parentLst, latestTask)) = List.fold1(parentLst, updateFinishingTime1, checkedTasksIn, ({},HpcOmSimCode.TASKEMPTY()));
        isComputable = List.isEmpty(parentLst);
        taskIdxNew = Util.if_(isComputable,taskIdxIn+1,taskIdxIn);
        //update the threadTasks and checked Tasks
        ((threadTasks,checkedTasks)) = Debug.bcallret1(isComputable, computeFinishingTimeForOneTask, (threadTasksIn,checkedTasksIn,taskIdxIn,threadIdxIn,latestTask,taskGraphMetaIn),(threadTasksIn,checkedTasksIn));
      then
        (threadTasks,checkedTasks,taskIdxNew);
    case(HpcOmSimCode.ASSIGNLOCKTASK(lockId=_),_,_,_,_,_,_)
      equation
        //skip the assignlock
        taskIdxNew = taskIdxIn+1;
      then
        (threadTasksIn,checkedTasksIn,taskIdxNew);
    case(HpcOmSimCode.RELEASELOCKTASK(lockId=_),_,_,_,_,_,_)
      equation
        //skip the releaselock
        taskIdxNew = taskIdxIn+1;
      then
        (threadTasksIn,checkedTasksIn,taskIdxNew);
  end match;
end updateFinishingTime;

protected function updateFinishingTime1  "folding function that checks whether the parentNode is in the checkedNodes and looks for the task with the latest finishingTime.
author:Waurich TUD 2013-11"
  input Integer parentIdx;
  input array<HpcOmSimCode.Task> checkedTaskIn;
  input tuple<list<Integer>,HpcOmSimCode.Task> tplIn;
  output tuple<list<Integer>,HpcOmSimCode.Task> tplOut;
protected
  Boolean isCalc;
  Real finishingTime, finishingTime1, finishingTimeIn;
  list<Integer> parentLst, parentLstIn;
  HpcOmSimCode.Task task, taskIn;
algorithm
  (parentLstIn,taskIn) := tplIn;
  finishingTimeIn := getTimeFinished(taskIn);
  task := arrayGet(checkedTaskIn,parentIdx);
  isCalc := isCalcTask(task);
  finishingTime := Debug.bcallret1(isCalc,getTimeFinished,task,-1.0);
  task := Util.if_(realGt(finishingTime,finishingTimeIn),task,taskIn);
  parentLst := Util.if_(isCalc,parentLstIn,parentIdx::parentLstIn);
  tplOut := (parentLst,task);
end updateFinishingTime1;

protected function computeFinishingTimeForOneTask  "updated the timeFinished in the calcTask and adds the task to the checkedTasks.
author: Waurich TUD 2013-11"
  input tuple<array<list<HpcOmSimCode.Task>>,array<HpcOmSimCode.Task>,Integer,Integer,HpcOmSimCode.Task,HpcOmTaskGraph.TaskGraphMeta> tplIn;
  output tuple<array<list<HpcOmSimCode.Task>>,array<HpcOmSimCode.Task>> tplOut;
algorithm
  tplOut := matchcontinue(tplIn)
    local
      Boolean isEmpty;
      array<list<HpcOmSimCode.Task>> threadTasks,threadTasksIn;
      array<HpcOmSimCode.Task> checkedTasksIn, checkedTasks;
      Integer commCost, taskIdx,taskIdxLatest, taskNum, threadIdx, threadIdxLatest;
      Real finishingTime, finishingTime1, finishingTimeComm, exeCost, commCostR;
      HpcOmTaskGraph.TaskGraphMeta taskGraphMeta;
      HpcOmSimCode.Task task, latestTask, preTask;
      list<HpcOmSimCode.Task> thread;
    case((threadTasksIn,checkedTasksIn,taskNum,threadIdx,latestTask,taskGraphMeta))
      // a rootNode
      equation
        true = isEmptyTask(latestTask);
        thread = arrayGet(threadTasksIn,threadIdx);
        task = listGet(thread,taskNum);
        threadIdx = getThreadId(task);
        preTask = getPredecessorCalcTask(thread,taskNum);
        finishingTime = getTimeFinished(preTask);
        taskIdx = getTaskIdx(task);
        ((_,exeCost)) = HpcOmTaskGraph.getExeCost(taskIdx,taskGraphMeta);
        finishingTime = finishingTime +. exeCost;
        task = updateTimeFinished(task, finishingTime);
        thread = List.replaceAt(task,taskNum-1,thread);
        threadTasks = arrayUpdate(threadTasksIn,threadIdx,thread);
        checkedTasks = arrayUpdate(checkedTasksIn,taskIdx,task);
      then
        ((threadTasks,checkedTasks));
    case((threadTasksIn,checkedTasksIn,taskNum,threadIdx,latestTask,taskGraphMeta))
      // not a rootNode
      equation
        false = isEmptyTask(latestTask);
        finishingTime = getTimeFinished(latestTask);
        threadIdxLatest = getThreadId(latestTask);
        taskIdxLatest = getTaskIdx(latestTask);
        thread = arrayGet(threadTasksIn,threadIdx);
        task = listGet(thread,taskNum);
        taskIdx = getTaskIdx(task);
        // get the costs for the node which is computed after the latest parent and decide whether to take commCost into account or not
        ((_,_,commCost)) = HpcOmTaskGraph.getCommCostBetweenNodes(taskIdxLatest,taskIdx,taskGraphMeta);
        commCostR = intReal(commCost);
        ((_,exeCost)) = HpcOmTaskGraph.getExeCost(taskIdx,taskGraphMeta);
        finishingTime = finishingTime +. exeCost;
        finishingTimeComm = finishingTime +. commCostR;
        finishingTime = Util.if_(intEq(threadIdxLatest,threadIdx),finishingTime,finishingTimeComm);
        // choose if the parentTask or the preTask(task on the same processor) is later.
        preTask = getPredecessorCalcTask(thread,taskNum);
        finishingTime1 = getTimeFinished(preTask);
        finishingTime1 = finishingTime1 +. exeCost;
        finishingTime = realMax(finishingTime,finishingTime1);
        // update
        task = updateTimeFinished(task, finishingTime);
        thread = List.replaceAt(task,taskNum-1,thread);
        threadTasks = arrayUpdate(threadTasksIn,threadIdx,thread);
        checkedTasks = arrayUpdate(checkedTasksIn,taskIdx,task);
       then
         ((threadTasks,checkedTasks));
  end matchcontinue;
end computeFinishingTimeForOneTask;

protected function getPredecessorCalcTask "gets the calctask before task at position <index> in the thread.
author:Waurich TUD 2013-11"
  input list<HpcOmSimCode.Task> threadIn;
  input Integer indexIn;
  output HpcOmSimCode.Task taskOut;
algorithm
  taskOut := matchcontinue(threadIn,indexIn)
    local
      Boolean isCalc;
      Integer index;
      HpcOmSimCode.Task preTask;
    case(_,_)
      equation
        true = indexIn==1;
      then
        HpcOmSimCode.TASKEMPTY();
    case(_,_)
      equation
        true = indexIn >= 2;
        index = indexIn-1;
        preTask = listGet(threadIn,index);
        isCalc = isCalcTask(preTask);
        preTask = Debug.bcallret2(boolNot(isCalc),getPredecessorCalcTask,threadIn,index,preTask);
      then
        preTask;
  end matchcontinue;
end getPredecessorCalcTask;

protected function updateTimeFinished "replaces the timeFinished in the calcTask.
author:Waurich TUD 2013-11"
  input HpcOmSimCode.Task taskIn;
  input Real timeFinishedIn;
  output HpcOmSimCode.Task taskOut;
protected
  Integer weighting;
  Integer index;
  Real calcTime;
  Real timeFinished;
  Integer threadIdx;
  list<Integer> eqIdc;
algorithm
  HpcOmSimCode.CALCTASK(weighting=weighting,index=index,calcTime=calcTime,timeFinished=timeFinished,threadIdx=threadIdx,eqIdc=eqIdc) := taskIn;
  taskOut := HpcOmSimCode.CALCTASK(weighting,index,calcTime,timeFinishedIn,threadIdx,eqIdc);
end updateTimeFinished;

protected function getTimeFinished "gets the timeFinished of a calcTask, if its not a calctask its -1.0. if its an emptyTask its 0.0
author:Waurich TUD 2013-11"
  input HpcOmSimCode.Task taskIn;
  output Real finishingTime;
algorithm
  finishingTime := match(taskIn)
  local
    Real fTime;
  case(HpcOmSimCode.CALCTASK(weighting=_,index=_,calcTime=_,timeFinished=fTime,threadIdx=_,eqIdc=_))
    then
      fTime;
  case(HpcOmSimCode.TASKEMPTY())
    then
      0.0;
  else
    then
      -1.0;
  end match;
end getTimeFinished;

protected function getThreadId "gets the threadIdx of a calcTask, if its not a calctask its -1
author:Waurich TUD 2013-11"
  input HpcOmSimCode.Task taskIn;
  output Integer threadId;
algorithm
  threadId := match(taskIn)
  local
    Integer threadIdx;
  case(HpcOmSimCode.CALCTASK(weighting=_,index=_,calcTime=_,timeFinished=_,threadIdx=threadIdx,eqIdc=_))
    then
      threadIdx;
  else
    then
      -1;
  end match;
end getThreadId;

protected function getTaskIdx "gets the idx of the calcTask.if its no calcTask, then -1.
author: Waurich TUD 2013-11"
  input HpcOmSimCode.Task taskIn;
  output Integer idx;
algorithm
  idx := match(taskIn)
    local
      Integer taskIdx;
    case(HpcOmSimCode.CALCTASK(weighting=_,index=taskIdx,calcTime=_,timeFinished=_,threadIdx=_,eqIdc=_))
      then
        taskIdx;
    else
      then
        -1;
  end match;
end getTaskIdx;

protected function isCalcTask "checks if the given task is a calcTask.
author:Waurich TUD 2013-11"
  input HpcOmSimCode.Task taskIn;
  output Boolean isCalc;
algorithm
  isCalc := match(taskIn)
  case(HpcOmSimCode.CALCTASK(weighting=_,index=_,calcTime=_,timeFinished=_,threadIdx=_,eqIdc=_))
    then
      true;
  else
    then
      false;
  end match;
end isCalcTask;

protected function isEmptyTask "checks if the given task is an emptyTask.
author:Waurich TUD 2013-11"
  input HpcOmSimCode.Task taskIn;
  output Boolean isEmpty;
algorithm
  isEmpty := match(taskIn)
  case(HpcOmSimCode.TASKEMPTY())
    then
      true;
  else
    then
      false;
  end match;
end isEmptyTask;

protected function printRealArray"prints the information of the ALAP array
author:Waurich TUD 2013-11"
  input array<Real> inArray;
  input String header;
algorithm
  print("The "+&header+&"\n");
  print("-----------------------------------------\n");
  _ := Util.arrayFold1(inArray,printRealArray1,header,1);
  print("\n");
end printRealArray;

protected function printRealArray1
  input Real inValue;
  input String header;
  input Integer idxIn;
  output Integer idxOut;
algorithm
  print("node: "+&intString(idxIn)+&" has the "+&header+&": "+&realString(inValue)+&"\n");
  idxOut := idxIn +1;
end printRealArray1;

protected function intListString
  input list<Integer> lstIn;
  output String s;
algorithm
  s := stringDelimitList(List.map(lstIn,intString)," , ");
  s := Util.if_(List.isEmpty(lstIn),"{}",s);
end intListString;

protected function intListListString
  input list<list<Integer>> lstIn;
  output String s;
algorithm
  s := stringDelimitList(List.map(lstIn,intListString)," | ");
end intListListString;

end HpcOmScheduler;
