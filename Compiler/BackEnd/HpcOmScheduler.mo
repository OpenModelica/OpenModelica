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
protected import Util;

public uniontype Task
  record CALCTASK //Task which calculates something
    Integer weighting;
    Integer index;
    Real calcTime;
    Real timeFinished;
    Integer threadIdx;
    list<Integer> eqIdc;
  end CALCTASK;
  record ASSIGNLOCKTASK //Task which assignes a lock
    String lockId;
  end ASSIGNLOCKTASK;
  record RELEASELOCKTASK //Task which releases a lock
    String lockId;
  end RELEASELOCKTASK;
  record TASKEMPTY //Dummy Task
  end TASKEMPTY;
end Task;

public uniontype Schedule   // stores all scheduling-informations
  record LEVELSCHEDULE
    list<list<Integer>> eqsOfLevels; //List of tasks assigned to the thread <%idx%>
  end LEVELSCHEDULE;
  record THREADSCHEDULE
    array<list<Task>> threadTasks; //List of tasks assigned to the thread <%idx%>
    list<String> lockIdc;
  end THREADSCHEDULE;
end Schedule;

public uniontype ScheduleSimCode //Schedule-structure for sim code
  record LEVELSCHEDULESC
    list<list<Integer>> eqsOfLevels;
  end LEVELSCHEDULESC;
  record THREADSCHEDULESC
    list<list<Task>> threadTasks;
    list<String> lockIdc;
  end THREADSCHEDULESC;
end ScheduleSimCode;

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
  output Schedule oSchedule;
protected
  HpcOmTaskGraph.TaskGraph taskGraphT;
  list<tuple<Task,Integer>> nodeList_refCount; //list of nodes which are ready to schedule
  list<Task> nodeList;
  list<Integer> rootNodes;
  array<Real> threadReadyTimes;
  array<tuple<Task,Integer>> allTasks;
  array<list<Task>> threadTasks;
  array<list<tuple<Integer, Integer, Integer>>> commCosts;
  Schedule tmpSchedule;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(commCosts=commCosts) := iTaskGraphMeta;
  taskGraphT := HpcOmTaskGraph.transposeTaskGraph(iTaskGraph);
  rootNodes := HpcOmTaskGraph.getRootNodes(taskGraphT);
  allTasks := convertTaskGraphToTasks(taskGraphT,iTaskGraphMeta,convertNodeToTask);
  nodeList_refCount := List.map1(rootNodes, getTaskByIndex, allTasks);
  nodeList := List.map(nodeList_refCount, Util.tuple21);
  nodeList := List.sort(nodeList, compareTasksByWeighting);
  threadReadyTimes := arrayCreate(iNumberOfThreads,0.0);
  threadTasks := arrayCreate(iNumberOfThreads,{});
  tmpSchedule := THREADSCHEDULE(threadTasks,{});
  (tmpSchedule,_) := createListSchedule1(nodeList,threadReadyTimes, iTaskGraph, taskGraphT, allTasks, commCosts, iSccSimEqMapping, getLocksByPredecessorList, tmpSchedule);
  tmpSchedule := addSuccessorLocksToSchedule(iTaskGraph,allTasks,addReleaseLocksToSchedule,tmpSchedule);
  //() := printSchedule(tmpSchedule);
  oSchedule := tmpSchedule;
end createListSchedule;

protected function createListSchedule1 "function createListSchedule1
  author: marcusw
  Create a list schedule, starting with the given nodeList and ready times. This method will add calcTasks and assignLockTasks, but no releaseLockTasks!"
  input list<Task> iNodeList; //the sorted nodes -> this method will pick the first task
  input array<Real> iThreadReadyTimes; //the time until the thread is ready to handle a new task
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input array<tuple<Task,Integer>> iAllTasks; //all tasks with ref-counter
  input array<list<tuple<Integer, Integer, Integer>>> iCommCosts;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input FuncType iLockWithPredecessorHandler; //Function which handles locks to all predecessors
  input Schedule iSchedule;
  output Schedule oSchedule;
  output array<Real> oThreadReadyTimes;
  
  partial function FuncType
    input Integer iNodeIdx;
    input Integer iThreadIdx;
    input list<tuple<Task,Integer>> iPredecessors;
    output list<Task> oTasks; //lock tasks
    output list<String> oLockNames; //lock names
  end FuncType;
protected
  Task head, newTask;
  Integer newTaskRefCount;
  list<Task> rest;
  Real lastChildFinishTime; //The time when the last child has finished calculation
  Task lastChild;
  list<tuple<Task,Integer>> predecessors, successors;
  list<Integer> successorIdc;
  list<String> lockIdc, newLockIdc;
  array<Real> threadFinishTimes;
  Integer firstEq;
  array<list<Task>> allThreadTasks;
  list<Task> threadTasks, lockTasks;
  Integer threadId;
  Real threadFinishTime;
  array<Real> tmpThreadReadyTimes;
  list<Task> tmpNodeList;
  Integer weighting;
  Integer index;
  Real calcTime;
  list<Integer> eqIdc, simEqIdc;
  array<tuple<Task,Integer>> tmpAllTasks;
  Schedule tmpSchedule;
algorithm
  (oSchedule,oThreadReadyTimes) := matchcontinue(iNodeList,iThreadReadyTimes, iTaskGraph, iTaskGraphT, iAllTasks, iCommCosts, iSccSimEqMapping, iLockWithPredecessorHandler, iSchedule)
    case((head as CALCTASK(weighting=weighting,index=index,calcTime=calcTime,eqIdc=(eqIdc as firstEq::_)))::rest,_,_,_,_,_,_,_,THREADSCHEDULE(threadTasks=allThreadTasks, lockIdc=lockIdc))
      equation
        //get all predecessors (childs)
        (predecessors, _) = getSuccessorsByTask(head, iTaskGraphT, iAllTasks);
        (successors, successorIdc) = getSuccessorsByTask(head, iTaskGraph, iAllTasks);
        true = intGt(listLength(predecessors), 0); //in this case the node has predecessors
        //print("Handle task " +& intString(index) +& " with " +& intString(listLength(predecessors)) +& " child nodes and " +& intString(listLength(successorIdc)) +& " parent nodes.\n");
        
        //get last child finished time
        lastChild = getTaskWithHighestFinishTime(predecessors, NONE());
        CALCTASK(timeFinished=lastChildFinishTime) = lastChild;
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
        simEqIdc = List.map(List.map1(eqIdc,getSccSimEqMappingByIndex,iSccSimEqMapping), List.last);
        //print("Simcodeeq idc: " +& stringDelimitList(List.map(simEqIdc, intString), ",") +& "\n");
        //simEqIdc has the wrong order -> reverse list
        simEqIdc = listReverse(simEqIdc);
        newTask = CALCTASK(weighting,index,calcTime,threadFinishTime,threadId,simEqIdc);
        threadTasks = newTask::threadTasks;
        allThreadTasks = arrayUpdate(allThreadTasks,threadId,threadTasks);
        //print("Successors: " +& stringDelimitList(List.map(successorIdc, intString), ",") +& "\n");
        //add all successors with refcounter = 1
        (tmpAllTasks,tmpNodeList) = updateRefCounterBySuccessorIdc(iAllTasks,successorIdc,{});
        tmpNodeList = listAppend(tmpNodeList, rest);
        tmpNodeList = List.sort(tmpNodeList, compareTasksByWeighting);
        ((_,newTaskRefCount)) = arrayGet(iAllTasks,index);
        _ = arrayUpdate(iAllTasks,index,(newTask,newTaskRefCount));
        (tmpSchedule,tmpThreadReadyTimes) = createListSchedule1(tmpNodeList,tmpThreadReadyTimes,iTaskGraph, iTaskGraphT, tmpAllTasks, iCommCosts, iSccSimEqMapping, iLockWithPredecessorHandler, THREADSCHEDULE(allThreadTasks,lockIdc));
      then (tmpSchedule,tmpThreadReadyTimes);
    case((head as CALCTASK(weighting=weighting,index=index,calcTime=calcTime,eqIdc=(eqIdc as firstEq::_)))::rest,_,_,_,_,_,_,_,THREADSCHEDULE(threadTasks=allThreadTasks,lockIdc=lockIdc))
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
        simEqIdc = List.flatten(List.map1(eqIdc,getSccSimEqMappingByIndex,iSccSimEqMapping));
        //simEqIdc has the wrong order -> reverse list
        simEqIdc = listReverse(simEqIdc);
        newTask = CALCTASK(weighting,index,calcTime,threadFinishTime,threadId,simEqIdc);
        allThreadTasks = arrayUpdate(allThreadTasks,threadId,newTask::threadTasks);
        //print("Successors: " +& stringDelimitList(List.map(successorIdc, intString), ",") +& "\n");
        //add all successors with refcounter = 1
        (tmpAllTasks,tmpNodeList) = updateRefCounterBySuccessorIdc(iAllTasks,successorIdc,{});
        tmpNodeList = listAppend(tmpNodeList, rest);
        tmpNodeList = List.sort(tmpNodeList, compareTasksByWeighting);
        ((_,newTaskRefCount)) = arrayGet(iAllTasks,index);
        _ = arrayUpdate(iAllTasks,index,(newTask,newTaskRefCount));
        (tmpSchedule,tmpThreadReadyTimes) = createListSchedule1(tmpNodeList,tmpThreadReadyTimes,iTaskGraph, iTaskGraphT, tmpAllTasks, iCommCosts, iSccSimEqMapping, iLockWithPredecessorHandler, THREADSCHEDULE(allThreadTasks,lockIdc));
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
  output Schedule oSchedule;
protected
  HpcOmTaskGraph.TaskGraph taskGraphT;
  list<tuple<Task,Integer>> nodeList_refCount; //list of nodes which are ready to schedule
  list<Task> nodeList;
  list<Integer> leaveNodes;
  array<Real> threadReadyTimes;
  array<tuple<Task,Integer>> allTasks;
  array<list<Task>> threadTasks;
  array<list<tuple<Integer, Integer, Integer>>> commCosts, commCostsT;
  Schedule tmpSchedule;
  list<String> lockIdc;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(commCosts=commCosts) := iTaskGraphMeta;
  taskGraphT := HpcOmTaskGraph.transposeTaskGraph(iTaskGraph);
  //() := HpcOmTaskGraph.printTaskGraph(taskGraphT);
  commCostsT := HpcOmTaskGraph.transposeCommCosts(commCosts);
  leaveNodes := HpcOmTaskGraph.getLeaveNodes(iTaskGraph);
  //print("Leave nodes: " +& stringDelimitList(List.map(leaveNodes,intString),", ") +& "\n");
  allTasks := convertTaskGraphToTasks(iTaskGraph,iTaskGraphMeta,convertNodeToTaskReverse);
  nodeList_refCount := List.map1(leaveNodes, getTaskByIndex, allTasks);
  nodeList := List.map(nodeList_refCount, Util.tuple21);
  nodeList := List.sort(nodeList, compareTasksByWeighting);
  threadReadyTimes := arrayCreate(iNumberOfThreads,0.0);
  threadTasks := arrayCreate(iNumberOfThreads,{});
  tmpSchedule := THREADSCHEDULE(threadTasks,{});
  (tmpSchedule,_) := createListSchedule1(nodeList,threadReadyTimes, taskGraphT, iTaskGraph, allTasks, commCostsT, iSccSimEqMapping, getLocksByPredecessorListReverse, tmpSchedule);
  
  tmpSchedule := addSuccessorLocksToSchedule(taskGraphT,allTasks,addAssignLocksToSchedule,tmpSchedule);
  THREADSCHEDULE(threadTasks=threadTasks,lockIdc=lockIdc) := tmpSchedule;
  threadTasks := Util.arrayMap(threadTasks, listReverse);
  tmpSchedule := THREADSCHEDULE(threadTasks,lockIdc);
  //() := printSchedule(tmpSchedule);
  oSchedule := tmpSchedule;
end createListScheduleReverse;

protected function addSuccessorLocksToSchedule
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input array<tuple<Task,Integer>> iAllTasks;
  input FuncType iCreateLockFunction;
  input Schedule iSchedule;
  output Schedule oSchedule;
  
  partial function FuncType
    input tuple<Task,Integer> iSuccessorTask;
    input Integer iTaskIdx;
    input list<Task> iReleaseTasks;
    output list<Task> oReleaseTasks;
  end FuncType;
protected
  array<list<Task>> allThreadTasks;
  Schedule tmpSchedule;
  list<String> lockIdc;
algorithm
  oSchedule := match(iTaskGraph,iAllTasks,iCreateLockFunction,iSchedule)
    case(_,_,_,THREADSCHEDULE(threadTasks=allThreadTasks,lockIdc=lockIdc))
      equation
        ((allThreadTasks,_)) = Util.arrayFold3(allThreadTasks, addSuccessorLocksToSchedule0, iTaskGraph, iAllTasks, iCreateLockFunction, (allThreadTasks,1));
        tmpSchedule = THREADSCHEDULE(allThreadTasks,lockIdc);
    then tmpSchedule;
    else
      equation
        print("HpcOmScheduler.addReleaseLocksToSchedule failed\n");
      then fail();
  end match;
end addSuccessorLocksToSchedule;

protected function addSuccessorLocksToSchedule0
  input list<Task> iThreadTaskList;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input array<tuple<Task,Integer>> iAllTasks;
  input FuncType iCreateLockFunction;
  input tuple<array<list<Task>>, Integer> iThreadTasks; //<schedulerTasks, threadId>
  output tuple<array<list<Task>>, Integer> oThreadTasks;
  
  partial function FuncType
    input tuple<Task,Integer> iSuccessorTask;
    input Integer iTaskIdx;
    input list<Task> iReleaseTasks;
    output list<Task> oReleaseTasks;
  end FuncType;
protected
  Integer threadId;
  array<list<Task>> allThreadTasks;
  list<Task> threadTasks;
algorithm
  (allThreadTasks,threadId) := iThreadTasks;
  threadTasks := List.fold4(iThreadTaskList, addSuccessorLocksToSchedule1, iTaskGraph, iAllTasks, threadId, iCreateLockFunction, {});
  allThreadTasks := arrayUpdate(allThreadTasks,threadId,threadTasks);
  oThreadTasks := ((allThreadTasks,threadId+1));
end addSuccessorLocksToSchedule0;

protected function addSuccessorLocksToSchedule1
  input Task iTask;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input array<tuple<Task,Integer>> iAllTasks;
  input Integer iThreadId;
  input FuncType iCreateLockFunction;
  input list<Task> iThreadTasks; //schedulerTasks
  output list<Task> oThreadTasks;
  
  partial function FuncType
    input tuple<Task,Integer> iSuccessorTask;
    input Integer iTaskIdx;
    input list<Task> iReleaseTasks;
    output list<Task> oReleaseTasks;
  end FuncType;
protected
  Integer threadIdx,index,listIndex;
  list<tuple<Task,Integer>> successors;
  list<Task> tmpThreadTasks, releaseTasks;
algorithm
  oThreadTasks := match(iTask, iTaskGraph, iAllTasks, iThreadId, iCreateLockFunction, iThreadTasks)
    case(CALCTASK(threadIdx=threadIdx,index=index),_,_,_,_,tmpThreadTasks)
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
  input tuple<Task,Integer> iSuccessorTask;
  input Integer iTaskIdx;
  input list<Task> iReleaseTasks;
  output list<Task> oReleaseTasks;
protected
  Task tmpTask, successorTask;
  String lockString;
  Integer lockId, successorTaskId;
algorithm
  (successorTask,_) := iSuccessorTask;
  CALCTASK(index=successorTaskId) := successorTask;
  lockString := intString(successorTaskId) +& "_" +& intString(iTaskIdx);
  tmpTask := convertLockIdToReleaseTask(lockString);
  oReleaseTasks := tmpTask :: iReleaseTasks;
end addReleaseLocksToSchedule;

protected function addAssignLocksToSchedule
  input tuple<Task,Integer> iSuccessorTask;
  input Integer iTaskIdx;
  input list<Task> iReleaseTasks;
  output list<Task> oReleaseTasks;
protected
  Task tmpTask, successorTask;
  String lockString;
  Integer lockId, successorTaskId;
algorithm
  (successorTask,_) := iSuccessorTask;
  CALCTASK(index=successorTaskId) := successorTask;
  lockString := intString(iTaskIdx) +& "_" +& intString(successorTaskId);
  tmpTask := convertLockIdToAssignTask(lockString);
  oReleaseTasks := tmpTask :: iReleaseTasks;
end addAssignLocksToSchedule;

protected function getSccSimEqMappingByIndex
  input Integer iIndex;
  input array<list<Integer>> iSccSimEqMapping;
  output list<Integer> oMapping;
algorithm
  oMapping := arrayGet(iSccSimEqMapping,iIndex);
end getSccSimEqMappingByIndex;

protected function getLocksByPredecessorList
  input Integer iTaskIdx; //The parent task
  input Integer iThreadIdx; //Thread handling task <%iTaskIdx%>
  input list<tuple<Task,Integer>> iPredecessorList;
  output list<Task> oLockTasks;
  output list<String> oLockIdc;
protected
  list<String> tmpLockIdc;
algorithm
  tmpLockIdc := List.fold2(iPredecessorList, getLockIdcByPredecessorList, iTaskIdx, iThreadIdx, {});
  oLockTasks := List.map(tmpLockIdc,convertLockIdToAssignTask);
  oLockIdc := tmpLockIdc;
end getLocksByPredecessorList;

protected function getLockIdcByPredecessorList
  input tuple<Task,Integer> iPredecessorTask;
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
    case((CALCTASK(threadIdx=threadIdx,index=index),_),_,_,_)
      equation
        true = intNe(iThreadIdx,threadIdx);
        //print("Adding a new lock for the tasks " +& intString(iTaskIdx) +& " " +& intString(index) +& "\n");
        //print("Because task " +& intString(index) +& " is scheduled to " +& intString(threadIdx) +& "\n");
        tmpLockString = intString(iTaskIdx) +& "_" +& intString(index);
        tmpLockIdc = tmpLockString :: iLockIdc;
      then tmpLockIdc;
    else then iLockIdc;
  end matchcontinue;
end getLockIdcByPredecessorList;

protected function getLocksByPredecessorListReverse
  input Integer iTaskIdx; //The parent task
  input Integer iThreadIdx; //Thread handling task <%iTaskIdx%>
  input list<tuple<Task,Integer>> iPredecessorList;
  output list<Task> oLockTasks;
  output list<String> oLockIdc;
protected
  list<String> tmpLockIdc;
algorithm
  tmpLockIdc := List.fold2(iPredecessorList, getLockIdcByPredecessorListReverse, iTaskIdx, iThreadIdx, {});
  oLockTasks := List.map(tmpLockIdc,convertLockIdToReleaseTask);
  oLockIdc := tmpLockIdc;
end getLocksByPredecessorListReverse;

protected function getLockIdcByPredecessorListReverse
  input tuple<Task,Integer> iPredecessorTask;
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
    case((CALCTASK(threadIdx=threadIdx,index=index),_),_,_,_)
      equation
        true = intNe(iThreadIdx,threadIdx);
        //print("Adding a new lock for the tasks " +& intString(iTaskIdx) +& " " +& intString(index) +& "\n");
        //print("Because task " +& intString(index) +& " is scheduled to " +& intString(threadIdx) +& "\n");
        tmpLockString = intString(index) +& "_" +& intString(iTaskIdx);
        tmpLockIdc = tmpLockString :: iLockIdc;
      then tmpLockIdc;
    else then iLockIdc;
  end matchcontinue;
end getLockIdcByPredecessorListReverse;

protected function convertLockIdToAssignTask
  input String iLockId;
  output Task oAssignTask;
algorithm
  oAssignTask := ASSIGNLOCKTASK(iLockId);
end convertLockIdToAssignTask;

protected function convertLockIdToReleaseTask
  input String iLockId;
  output Task oReleaseTask;
algorithm
  oReleaseTask := RELEASELOCKTASK(iLockId);
end convertLockIdToReleaseTask;

protected function updateRefCounterBySuccessorIdc "function updateRefCounterBySuccessorIdc
  author: marcusw
  Decrement the ref-counter off all tasks in the successor-list. If the new ref-counter is 0, the task 
  will be append to the second return argument."
  input array<tuple<Task,Integer>> iAllTasks; //all tasks with ref-counter
  input list<Integer> iSuccessorIdc;
  input list<Task> iRefZeroTasks;
  output array<tuple<Task,Integer>> oAllTasks;
  output list<Task> oRefZeroTasks; //Tasks with new ref-counter = 0
protected
  Integer head, currentRefCount;
  list<Integer> rest;
  list<Task> tmpRefZeroTasks;
  Task currentTask;
  array<tuple<Task,Integer>> tmpAllTasks;
  
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
    else then (iAllTasks,iRefZeroTasks);
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
    else then getThreadFinishTimesMin(iThreadIdx+1,iThreadFinishTimes, iCurrentMinThreadIdx, iCurrentMinFinishTime);
  end matchcontinue;
end getThreadFinishTimesMin;

protected function getTaskWithHighestFinishTime "function getTaskWithHighestFinishTime
  author: marcusw
  Pick the task with the highest finish time out of the given task list."
  input list<tuple<Task,Integer>> iTasks; //Tasks with ref-counter
  input Option<Task> iCurrentTask;
  output Task oTask; //The task with the highest finish time
protected
  Task head;
  Task tmpTask;
  list<tuple<Task,Integer>> tail;
  Real timeFinishedHead, timeFinishedCurrent;
algorithm
  oTask := matchcontinue(iTasks, iCurrentTask)
    case((head,_)::tail, NONE()) then getTaskWithHighestFinishTime(tail, SOME(head));
    case(((head as CALCTASK(timeFinished=timeFinishedHead)),_)::tail, SOME(CALCTASK(timeFinished=timeFinishedCurrent)))
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
  output array<tuple<Task,Integer>> oTasks; //all Tasks with ref_Counter
  partial function FuncType
    input Integer iNodeIdx;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    output Task oTask;
  end FuncType;
protected
  array<tuple<Task,Integer>> tmpTaskArray;
  array<list<Integer>> inComps;
algorithm
  //HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps) := iTaskGraphMeta;
  tmpTaskArray := arrayCreate(arrayLength(iTaskGraphT), ((TASKEMPTY(),0)));
  oTasks := convertTaskGraphToTasks1(iTaskGraphMeta,iTaskGraphT,1,iConverterFunc,tmpTaskArray);
end convertTaskGraphToTasks;

protected function convertTaskGraphToTasks1 "function convertTaskGraphToTasks1
  author: marcusw
  Convert one TaskGraph-Task to a Scheduler-Task with ref-counter."
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input Integer iIndex; //Index of current node
  input FuncType iConverterFunc; //Pointer to function which converts one Task 
  input array<tuple<Task,Integer>> iTasks; 
  output array<tuple<Task,Integer>> oTasks;
  partial function FuncType
    input Integer iNodeIdx;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    output Task oTask;
  end FuncType;
protected
  array<list<Integer>> inComps;
  array<Integer> nodeMarks;
  array<tuple<Task,Integer>> tmpTasks;
  Integer refCount;
  array<tuple<Integer,Real>> exeCosts;
  Task newTask;
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
    else then iTasks;
  end matchcontinue;
end convertTaskGraphToTasks1;

protected function convertNodeToTask "function convertNodeToTask
  author: marcusw
  Convert one TaskGraph-Node to a Scheduler-Task and set weighting = nodeMark."
  input Integer iNodeIdx;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  output Task oTask;
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
      then CALCTASK(nodeMark,iNodeIdx,exeCost,-1.0,-1, components);
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
  output Task oTask;
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
      then CALCTASK(nodeMark,iNodeIdx,exeCost,-1.0,-1, components);
    else
      equation
        print("HpcOmScheduler.convertNodeToTask failed!\n");
      then fail();
  end match;
end convertNodeToTaskReverse;

protected function calculateFinishTimes
  input Real iPredecessorTaskLastFinished; //time when the last predecessor has finished 
  input Task iTask;
  input list<tuple<Task,Integer>> iPredecessorTasks; //all child tasks with ref-counter
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
  input Task iTask;
  input list<tuple<Task,Integer>> iPredecessorTasks; //all child tasks
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
    else then iFinishTimes;
  end matchcontinue;
end calculateFinishTimes1;
  
protected function calculateFinishTimeByThreadId
  input Real iThreadReadyTime; //time when the thread has finished his last task
  input Real iPredecessorTaskLastFinished; //time when the last predecessor has finished
  input Integer iThreadId;
  input Task iTask;
  input list<tuple<Task,Integer>> iPredecessorTasks; //all child tasks
  input array<list<tuple<Integer, Integer, Integer>>> iCommCosts;
  output Real oFinishTime;
protected
  list<tuple<Task,Integer>> predecessorTasksOtherTh; //all predecessor scheduled to another thread
  Real commCost, calcTime;
  Real startTime;
algorithm
  oFinishTime := match(iThreadReadyTime, iPredecessorTaskLastFinished, iThreadId, iTask, iPredecessorTasks, iCommCosts)
    case(_,_,_,CALCTASK(calcTime=calcTime),_,_)
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
  input Task iParentTask;
  input list<tuple<Task,Integer>> iTaskList;
  input array<list<tuple<Integer, Integer, Integer>>> iCommCosts;
  output Real oCommCost;
algorithm
  oCommCost := List.fold2(iTaskList, getMaxCommCostsByTaskList1, iParentTask, iCommCosts, 0.0);
end getMaxCommCostsByTaskList;

protected function getMaxCommCostsByTaskList1
  input tuple<Task,Integer> iTask;
  input Task iParentTask;
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
    case((CALCTASK(index=taskIdx,eqIdc=eqIdc),_),CALCTASK(eqIdc=parentEqIdc),_,_)
      equation
        //print("Try to find edge cost from scc " +& intString(List.first(eqIdc)) +& " to scc " +& intString(List.first(parentEqIdc)) +& "\n");
        childCommCosts = arrayGet(iCommCosts,List.first(eqIdc));
        ((_,_,reqCycles)) = getMaxCommCostsByTaskList2(childCommCosts, List.first(parentEqIdc));
        reqCyclesReal = intReal(reqCycles);
        true = realGt(reqCyclesReal, iCurrentMax);
      then reqCyclesReal;
    else then iCurrentMax;
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
  input array<tuple<Task,Integer>> iAllTasks;
  output tuple<Task,Integer> oTask;
algorithm
  oTask := arrayGet(iAllTasks,iTaskIdx);
end getTaskByIndex;
  
protected function getSuccessorsByTask
  input Task iTask;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input array<tuple<Task,Integer>> iAllTasks;
  output list<tuple<Task,Integer>> oTasks;
  output list<Integer> oTaskIdc;
protected
  Integer taskIdx;
  list<Integer> successors;
  list<tuple<Task,Integer>> tmpTasks;
algorithm
  (oTasks, oTaskIdc) := matchcontinue(iTask,iTaskGraph,iAllTasks)
    case(CALCTASK(index=taskIdx),_,_)
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
  input Task iTask1;
  input Task iTask2;
  output Boolean oResult;
protected
  Integer weightingTask1,weightingTask2;
algorithm
  oResult := match(iTask1,iTask2)
    case(CALCTASK(weighting=weightingTask1), CALCTASK(weighting=weightingTask2))
      then intGt(weightingTask1,weightingTask2);
    else
      equation
        print("HpcOmScheduler.compareTasksByWeighting can only compare CALCTASKs!\n");
      then fail();
  end match;
end compareTasksByWeighting;

protected function compareTaskWithThreadIdx
  input Integer iThreadIdx;
  input tuple<Task,Integer> iTask1;
  output Boolean oMatch; //True if the task has the same threadIdx as iThreadIdx
protected
  Integer threadIdx;
algorithm
  oMatch := match(iThreadIdx,iTask1)
    case(_,(CALCTASK(threadIdx=threadIdx),_))
      then intEq(threadIdx,iThreadIdx);
    else
      equation
        print("HpcOmScheduler.compareTaskWithThreadIdx can only compare CALCTASKs!\n");
      then fail();
  end match;
end compareTaskWithThreadIdx;

protected function printSchedule1
  input list<Task> iTaskList;
  input Integer iThreadIdx;
  output Integer oThreadIdx;
algorithm
  print("Thread " +& intString(iThreadIdx) +& "\n");
  print("--------------\n");
  printTaskList(iTaskList);
  oThreadIdx := iThreadIdx+1;
end printSchedule1;
 
protected function printTaskList
  input list<Task> iTaskList;
protected
  Task head;
  list<Task> rest;
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
  input Task iTask;
  output String oString;
protected
  Integer weighting;
  Integer index;
  Real calcTime;
  Real timeFinished;
  Integer threadIdx;
  list<Integer> eqIdc;
  String lockId;
algorithm
  oString := match(iTask)
    case(CALCTASK(weighting=weighting, index=index))
      then ("Calculation task with index " +& intString(index) +& " and weighting " +& intString(weighting) +& "\n");
    case(ASSIGNLOCKTASK(lockId=lockId))
      then ("Assign lock task with id " +& lockId +& "\n");
    case(RELEASELOCKTASK(lockId=lockId))
      then ("Release lock task with id " +& lockId +& "\n");
    else
      equation
        print("HpcOmScheduler.dumpTask failed\n");
      then fail();
  end match;
end dumpTask;

protected function printTaskRefList
  input list<tuple<Task,Integer>> iTaskList;
protected
  list<tuple<Task,Integer>> rest;
  Integer weighting;
  Integer index;
  Real calcTime;
  Real timeFinished;
  Integer threadIdx, refCount;
  list<Integer> eqIdc;
algorithm
  _ := match(iTaskList)
    case(((CALCTASK(weighting=weighting, index=index),refCount))::rest)
      equation
        print("Calculation task with index " +& intString(index) +& " and weighting " +& intString(weighting) +& " and ref count: " +& intString(refCount) +& "\n");
        printTaskRefList(rest);
      then ();
    else
      then ();
  end match;
end printTaskRefList;

public function convertScheduleStrucToInfo
  input Schedule iSchedule;
  input Integer iTaskCount;
  output array<tuple<Integer,Integer>> oScheduleInfo;
protected
  array<tuple<Integer,Integer>> tmpScheduleInfo;
  array<list<Task>> threadTasks;
algorithm
  oScheduleInfo := match(iSchedule,iTaskCount)
    case(THREADSCHEDULE(threadTasks=threadTasks),_)
      equation
        tmpScheduleInfo = arrayCreate(iTaskCount,(-1,-1));
        tmpScheduleInfo = Util.arrayFold(threadTasks,convertScheduleStrucToInfo0,tmpScheduleInfo);
      then tmpScheduleInfo;
    case(LEVELSCHEDULE(_),_)
      equation
        tmpScheduleInfo = arrayCreate(iTaskCount,(-1,-1));
      then tmpScheduleInfo;
    else
      equation
        print("HpcOmScheduler.convertScheduleStrucToInfo unknown Schedule-Type.\n");
      then fail();
  end match;
end convertScheduleStrucToInfo;

protected function convertScheduleStrucToInfo0
  input list<Task> iTaskList;
  input array<tuple<Integer,Integer>> iScheduleInfo;
  output array<tuple<Integer,Integer>> oScheduleInfo;
algorithm
  ((oScheduleInfo,_)) := List.fold(iTaskList, convertScheduleStrucToInfo1, (iScheduleInfo,1));
end convertScheduleStrucToInfo0;

protected function convertScheduleStrucToInfo1
  input Task iTask;
  input tuple<array<tuple<Integer,Integer>>,Integer> iScheduleInfo; //ScheduleInfo and task number
  output tuple<array<tuple<Integer,Integer>>,Integer> oScheduleInfo;
protected
  Integer taskIdx, taskNumber;
  Integer threadIdx;
  array<tuple<Integer,Integer>> tmpScheduleInfo;
algorithm
  oScheduleInfo := match(iTask,iScheduleInfo)
    case(CALCTASK(index=taskIdx,threadIdx=threadIdx),(tmpScheduleInfo,taskNumber))
      equation
        tmpScheduleInfo = arrayUpdate(tmpScheduleInfo,taskIdx,(threadIdx,taskNumber));
      then ((tmpScheduleInfo,taskNumber+1));
    case (ASSIGNLOCKTASK(_),_) then iScheduleInfo;
    case (RELEASELOCKTASK(_),_) then iScheduleInfo;
    else
      equation
        print("HpcOmScheduler.convertScheduleStrucToInfo1 failed. Unknown Task-Type.\n");
      then fail();
  end match; 
end convertScheduleStrucToInfo1;

//-----------------
// Level Scheduling
//-----------------
public function createLevelSchedule "function createLevelSchedule
  author: marcusw
  Creates a level scheduling for the given graph"
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  output Schedule oSchedule;
 
protected
  array<list<Integer>> inComps;
  array<Integer> nodeMark;
  list<tuple<Integer,list<Integer>>> tmpSimEqLevelMapping; //maps the level-index to the equations
  list<list<Integer>> flatSimEqLevelMapping;
algorithm
  oSchedule := match(iMeta,iSccSimEqMapping)
    case(HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,nodeMark=nodeMark),_)
      equation
        tmpSimEqLevelMapping = createLevelSchedule0(1,inComps,iSccSimEqMapping,nodeMark,{});
        //sorting
        tmpSimEqLevelMapping = List.sort(tmpSimEqLevelMapping, sortLevelInfo);
        //flattening
        flatSimEqLevelMapping = List.map(tmpSimEqLevelMapping, Util.tuple22);
      then LEVELSCHEDULE(flatSimEqLevelMapping);
    else 
      equation
        print("CreateLevelSchedule failed.");
    then fail();
  end match;
end createLevelSchedule;

protected function createLevelSchedule0 "function createLevelSchedule0
  author: marcusw
  Helper function of createLevelSchedule. It extends the levelMapping-structure with the informations of the given node (iNodeIdx)."
  input Integer iNodeIdx;
  input array<list<Integer>> iComps;
  input array<list<Integer>> iSccSimEqMapping;
  input array<Integer> iNodeMarks;
  input list<tuple<Integer,list<Integer>>> iSimEqLevelMapping;
  output list<tuple<Integer,list<Integer>>> oSimEqLevelMapping;
  
protected
  list<Integer> sccSimEqMapping, nodeComps;
  Integer nodeMark;
  Integer mapListIndex;
  Integer firstNodeComp;
  list<Integer> eqList;
  list<tuple<Integer,list<Integer>>> tmpSimEqLevelMapping;
algorithm
  oSimEqLevelMapping := matchcontinue(iNodeIdx,iComps,iSccSimEqMapping,iNodeMarks,iSimEqLevelMapping)
    case(_,_,_,_,_)
      equation
        true = intGe(arrayLength(iComps),iNodeIdx);
        nodeComps = arrayGet(iComps,iNodeIdx);
        true = intEq(listLength(nodeComps), 1);
        firstNodeComp = List.first(nodeComps);
        true = intGe(arrayLength(iSccSimEqMapping), firstNodeComp);
        //sccSimEqMapping = arrayGet(iSccSimEqMapping,firstNodeComp);
        nodeMark = arrayGet(iNodeMarks,firstNodeComp);
        //print("createParInformation0 with nodeIdx " +& intString(iNodeIdx) +& " representing component " +& intString(firstNodeComp) +& " and nodeMark " +& intString(nodeMark) +& "\n");
        true = intGe(nodeMark,0);
        (tmpSimEqLevelMapping,eqList,mapListIndex) = getLevelListByLevel(nodeMark,1,iSimEqLevelMapping,iSimEqLevelMapping);
        eqList = List.fold1(nodeComps, createLevelSchedule1, iSccSimEqMapping, eqList);
        tmpSimEqLevelMapping = List.replaceAt((nodeMark, eqList),mapListIndex-1,tmpSimEqLevelMapping);
      then createLevelSchedule0(iNodeIdx+1,iComps,iSccSimEqMapping,iNodeMarks,tmpSimEqLevelMapping);
    case(_,_,_,_,_)
      equation
        true = intGe(arrayLength(iComps),iNodeIdx);
        nodeComps = arrayGet(iComps,iNodeIdx);
        true = intEq(listLength(nodeComps), 1);
        true = intGe(arrayLength(iSccSimEqMapping), iNodeIdx); 
      then createLevelSchedule0(iNodeIdx+1,iComps,iSccSimEqMapping,iNodeMarks,iSimEqLevelMapping);
    case(_,_,_,_,_)
      equation
        true = intGe(arrayLength(iComps),iNodeIdx);
        nodeComps = arrayGet(iComps,iNodeIdx);
        false = intEq(listLength(nodeComps), 1);
        true = intGe(arrayLength(iSccSimEqMapping), iNodeIdx); 
        print("createLevelSchedule0: contracted nodes are currently not supported\n");
      then fail();
    else 
      then iSimEqLevelMapping;
  end matchcontinue;
end createLevelSchedule0;

protected function createLevelSchedule1 "function createLevelSchedule1
  author: marcusw
  Helper function of createLevelSchedule. This method will grab the simEqIndex of the given component and extend the iList."
  input Integer iCompIdx;
  input array<list<Integer>> iSccSimEqMapping;
  input list<Integer> iList;
  output list<Integer> oList;
  
protected 
  list<Integer> simEqIdc;
  Integer lastSimEqIdx;
  
algorithm
  simEqIdc := arrayGet(iSccSimEqMapping,iCompIdx);
  lastSimEqIdx := List.last(simEqIdc);
  oList := lastSimEqIdx::iList;
end createLevelSchedule1;

protected function getLevelListByLevel "function getLevelListByLevel
  author: marcusw
  Returns the level list of the searched index. If no level with the given index was found, a new list is appended to the mapping."
  input Integer iLevel;
  input Integer iCurrentListIndex;
  input list<tuple<Integer,list<Integer>>> restList;
  input list<tuple<Integer,list<Integer>>> iSimEqLevelMapping; //list<<levelIndex,levelList>>
  output list<tuple<Integer,list<Integer>>> oSimEqLevelMapping;
  output list<Integer> oEqList;
  output Integer oMapListIndex; 
  
protected
  Integer curLevel, headIdx;
  list<Integer> curLevelEqs, headList;
  list<tuple<Integer,list<Integer>>> rest;
  tuple<Integer,list<Integer>> newElem;
  
  list<tuple<Integer,list<Integer>>> tmpSimEqLevelMapping;
  list<Integer> tmpEqList;
  Integer tmpMapListIndex;
algorithm
  (oSimEqLevelMapping,oEqList,oMapListIndex) := matchcontinue(iLevel,iCurrentListIndex,restList,iSimEqLevelMapping)
    case(_,_,(headIdx,headList)::rest,_)
      equation
        true = intEq(headIdx,iLevel);
      then (iSimEqLevelMapping,headList,iCurrentListIndex);
    case(_,_,(headIdx,headList)::rest,_)
      equation 
         (tmpSimEqLevelMapping,tmpEqList,tmpMapListIndex) = getLevelListByLevel(iLevel,iCurrentListIndex+1,rest,iSimEqLevelMapping);
      then (tmpSimEqLevelMapping,tmpEqList,tmpMapListIndex);
    else
      equation
        newElem = (iLevel,{});
      then (newElem::iSimEqLevelMapping,{},1);
   end matchcontinue;
end getLevelListByLevel;

protected function sortLevelInfo "function sortLevelInfo
  author: marcusw
  Use this function to sort a level list. The result is true if index1 > index2."
  input tuple<Integer,list<Integer>> iTuple1; //<index1,_>
  input tuple<Integer,list<Integer>> iTuple2; //<index2,_>
  output Boolean oResult;
protected
  Integer index1,index2;
algorithm
  (index1,_) := iTuple1;
  (index2,_) := iTuple2;
  oResult := intGt(index1,index2);
end sortLevelInfo;

protected function printLevelSchedule "function printLevelSchedule
  author: marcusw
  Helper function to print one level."
  input list<Integer> iLevelInfo;
  input Integer iLevel;
  output Integer oLevel;
  
algorithm
  print("Level " +& intString(iLevel) +& ":\n");
  _ := List.fold(iLevelInfo,printLevelSchedule1,1);
  oLevel := iLevel + 1;
end printLevelSchedule;

protected function printLevelSchedule1 "function printLevelSchedule1
  author: marcusw
  Helper function of printLevelSchedule to print one equation."
  input Integer iEquation;
  input Integer iLevel;
  output Integer oLevel;
  
algorithm
  print("\t Equation " +& intString(iEquation) +& "\n");
  oLevel := iLevel + 1;
end printLevelSchedule1;

//-----
// Util
//-----
public function convertScheduleToSimCodeSchedule
  input Schedule iSchedule;
  output ScheduleSimCode oSchedule;
protected
  list<list<Integer>> eqsOfLevels;
  array<list<Task>> threadTasks;
  list<list<Task>> tmpThreadTasks;
  list<String> lockIdc;
  ScheduleSimCode tmpSchedule;
algorithm
  oSchedule := match(iSchedule)
    case(LEVELSCHEDULE(eqsOfLevels=eqsOfLevels))
      equation
        tmpSchedule = LEVELSCHEDULESC(eqsOfLevels);
      then tmpSchedule;
    case(THREADSCHEDULE(threadTasks=threadTasks, lockIdc=lockIdc)) 
      equation
        tmpThreadTasks = arrayList(threadTasks);
        tmpSchedule = THREADSCHEDULESC(tmpThreadTasks,lockIdc);
      then tmpSchedule;
    else
      equation
        print("ConvertScheduleToSimCodeSchedule failed.\n");
      then fail();
  end match;
end convertScheduleToSimCodeSchedule;

public function printSchedule
  input Schedule iSchedule;
protected
  array<list<Task>> threadTasks;
  list<list<Integer>> eqsOfLevels;
algorithm
  _ := match(iSchedule)
    case(THREADSCHEDULE(threadTasks=threadTasks))
      equation
        _ = Util.arrayFold(threadTasks, printSchedule1, 1);
      then ();
    case(LEVELSCHEDULE(eqsOfLevels=eqsOfLevels))
      equation
        _ = List.fold(eqsOfLevels,printLevelSchedule,1);
      then ();
    else then fail();
  end match;
end printSchedule;

end HpcOmScheduler;
