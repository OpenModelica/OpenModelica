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

protected import BackendDAEUtil;
protected import Debug;
protected import HpcOmSchedulerExt;
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
  record EMPTYSCHEDULE  // a dummy schedule. used if there is no ODE-system
  end EMPTYSCHEDULE;
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

public type TaskAssignment = array<Integer>; //the information which node <idx> is assigned to which processor <value>


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
        true = List.isNotEmpty(predecessors); //in this case the node has predecessors
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
        //nodeMark = nodeMark * (-1); //switch from LLP to HLP
        //((_,exeCost)) = arrayGet(exeCosts,iNodeIdx);
        ((_,exeCost)) = HpcOmTaskGraph.getExeCost(iNodeIdx,iTaskGraphMeta);
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
    case(CALCTASK(weighting=weighting,timeFinished=timeFinished, index=index, eqIdc=eqIdc))
      then ("Calculation task with index " +& intString(index) +& " including the equations: "+&stringDelimitList(List.map(eqIdc,intString),", ")+& " is finished at  " +& realString(timeFinished) +& "\n");
    case(ASSIGNLOCKTASK(lockId=lockId))
      then ("Assign lock task with id " +& lockId +& "\n");
    case(RELEASELOCKTASK(lockId=lockId))
      then ("Release lock task with id " +& lockId +& "\n");
    case(TASKEMPTY())
      then ("empty task\n");
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

//--------------------
// External-C Scheduling
//--------------------
public function createExtCSchedule "function createExtSchedule
  author: marcusw
  Creates a scheduling by reading the required informations from a graphml-file."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer iNumberOfThreads;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  output Schedule oSchedule;
protected
  list<Integer> extInfo;
  array<Integer> extInfoArr;
  HpcOmTaskGraph.TaskGraph taskGraphT;
  Schedule tmpSchedule;
  array<list<Task>> threadTasks;
  list<Integer> rootNodes;
  array<tuple<Task, Integer>> allTasks;
  list<tuple<Task,Integer>> nodeList_refCount; //list of nodes which are ready to schedule
  list<Task> nodeList;
algorithm
  oSchedule := matchcontinue(iTaskGraph,iTaskGraphMeta,iNumberOfThreads,iSccSimEqMapping)
    case(_,_,_,_)
      equation
        extInfo = HpcOmSchedulerExt.scheduleAdjList(iTaskGraph);
      then fail();
    else
      equation
        print("HpcOmScheduler.createExtCSchedule not every node has a scheduler-info.\n");
      then fail();
  end matchcontinue;
end createExtCSchedule;

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
  output Schedule oSchedule;
protected
  list<Integer> extInfo;
  array<Integer> extInfoArr;
  HpcOmTaskGraph.TaskGraph taskGraphT;
  Schedule tmpSchedule;
  array<list<Task>> threadTasks;
  list<Integer> rootNodes;
  array<tuple<Task, Integer>> allTasks;
  list<tuple<Task,Integer>> nodeList_refCount; //list of nodes which are ready to schedule
  list<Task> nodeList;
algorithm
  oSchedule := matchcontinue(iTaskGraph,iTaskGraphMeta,iNumberOfThreads,iSccSimEqMapping,iGraphMLFile)
    case(_,_,_,_,_)
      equation
        extInfo = HpcOmSchedulerExt.readScheduleFromGraphMl(iGraphMLFile);
        extInfoArr = listArray(extInfo);
        true = intEq(arrayLength(iTaskGraph),arrayLength(extInfoArr));
        //print("External scheduling info: " +& stringDelimitList(List.map(extInfo, intString), ",") +& "\n");
        
        taskGraphT = HpcOmTaskGraph.transposeTaskGraph(iTaskGraph);
        rootNodes = HpcOmTaskGraph.getRootNodes(taskGraphT);
        allTasks = convertTaskGraphToTasks(taskGraphT,iTaskGraphMeta,convertNodeToTask);
        nodeList_refCount = List.map1(rootNodes, getTaskByIndex, allTasks);
        nodeList = List.map(nodeList_refCount, Util.tuple21);
        nodeList = List.sort(nodeList, compareTasksByWeighting);
        threadTasks = arrayCreate(iNumberOfThreads,{});
        tmpSchedule = THREADSCHEDULE(threadTasks,{});
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
  input list<Task> iNodeList; //the sorted nodes -> this method will pick the first task
  input array<Integer> iThreadAssignments; //assignment taskIdx -> threadIdx
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input array<tuple<Task,Integer>> iAllTasks; //all tasks with ref-counter
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input FuncType iLockWithPredecessorHandler; //Function which handles locks to all predecessors
  input Schedule iSchedule;
  output Schedule oSchedule;
  
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
  oSchedule := matchcontinue(iNodeList,iThreadAssignments, iTaskGraph, iTaskGraphT, iAllTasks, iSccSimEqMapping, iLockWithPredecessorHandler, iSchedule)
    case((head as CALCTASK(weighting=weighting,index=index,calcTime=calcTime,eqIdc=(eqIdc as firstEq::_)))::rest,_,_,_,_,_,_,THREADSCHEDULE(threadTasks=allThreadTasks, lockIdc=lockIdc))
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
        tmpSchedule = createExtSchedule1(tmpNodeList,iThreadAssignments,iTaskGraph, iTaskGraphT, tmpAllTasks, iSccSimEqMapping, iLockWithPredecessorHandler, THREADSCHEDULE(allThreadTasks,lockIdc));
      then tmpSchedule;
    case((head as CALCTASK(weighting=weighting,index=index,calcTime=calcTime,eqIdc=(eqIdc as firstEq::_)))::rest,_,_,_,_,_,_,THREADSCHEDULE(threadTasks=allThreadTasks,lockIdc=lockIdc))
      equation
        (successors, successorIdc) = getSuccessorsByTask(head, iTaskGraph, iAllTasks);
        //print("Handle task " +& intString(index) +& " with 0 child nodes and " +& intString(listLength(successorIdc)) +& " parent nodes.\n");
        //print("Parents: {" +& stringDelimitList(List.map(successorIdc, intString), ",") +& "}\n");

        //find thread for scheduling
        threadId = arrayGet(iThreadAssignments,index);
        threadFinishTime = -1.0;
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
        tmpSchedule = createExtSchedule1(tmpNodeList,iThreadAssignments,iTaskGraph, iTaskGraphT, tmpAllTasks, iSccSimEqMapping, iLockWithPredecessorHandler, THREADSCHEDULE(allThreadTasks,lockIdc));
      then tmpSchedule;
    case({},_,_,_,_,_,_,_) then iSchedule;
    else
      equation
        print("HpcOmScheduler.createExtSchedule1 failed. Tasks in List:\n");
        printTaskList(iNodeList);
      then fail();
  end matchcontinue;
end createExtSchedule1;

//-----------------------
// Modified Critical Path
//-----------------------

public function createMCPschedule "scheduler Modified Critical Path.
computes the ALAP i.e. latest possible start time  for every task. The task with the smallest values gets the highest priority.
author: Waurich TUD 2013-10 "
  input HpcOmTaskGraph.TaskGraph iTaskGraph;  
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer numProc;
  input array<list<Integer>> iSccSimEqMapping;
  output Schedule oSchedule;
protected
  Integer size;
  array<list<Task>> threads;
  array<list<Integer>> taskGraphT;
  array<Real> alapArray;  // this is the latest possible starting time of every node
  list<Real> alapLst, alapSorted, priorityLst;
  list<Integer> order;
  array<Integer> taskAss; //<idx>=task, <value>=processor
  array<list<Integer>> procAss; //<idx>=processor, <value>=task; 
  array<list<Task>> threadTask;
  Schedule schedule;
algorithm
  //compute the ALAP
  size := arrayLength(iTaskGraph);
  taskGraphT := BackendDAEUtil.transposeMatrix(iTaskGraph,size); 
  alapArray := computeALAP(iTaskGraph,iTaskGraphMeta);
  //printALAP(alapArray);
  alapLst := arrayList(alapArray);
  // get the order of the task, assign to processors
  (priorityLst,order) := quicksortWithOrder(alapLst);  
  (taskAss,procAss) := getTaskAssignmentMCP(order,alapArray,numProc,iTaskGraph,iTaskGraphMeta);
  // create the schedule
  threadTask := arrayCreate(numProc,{});
  schedule := THREADSCHEDULE(threadTask,{});
  schedule := createSchedulerFromAssignments(taskAss,procAss,SOME(order),iTaskGraph,taskGraphT,iTaskGraphMeta,iSccSimEqMapping,schedule);
  oSchedule := schedule;
end createMCPschedule;


protected function createSchedulerFromAssignments  
  input array<Integer> taskAss;
  input array<list<Integer>> procAss;
  input Option<list<Integer>> orderOpt;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraph taskGraphTIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  input array<list<Integer>> SccSimEqMappingIn;
  input Schedule scheduleIn;
  output Schedule scheduleOut;
algorithm
  scheduleOut := match(taskAss,procAss,orderOpt,taskGraphIn,taskGraphTIn,taskGraphMetaIn,SccSimEqMappingIn,scheduleIn)
    local
      Integer node,proc,mark;
      Real exeCost,commCost;
      list<Integer> order, rest, components, simEqIdc, parentNodes,childNodes, sameProcTasks, otherParents, otherChildren;
      list<String> assLockIdc,relLockIdc,lockIdc;
      array<Integer> nodeMark;
      array<list<Integer>> inComps;
      array<tuple<Integer,Real>> exeCosts;
      array<list<tuple<Integer,Integer,Integer>>> commCosts;
      array<list<Task>> threadTasks;
      list<Task> taskLst1,taskLst,taskLstAss,taskLstRel;
      Schedule schedule;
      Task task;
    case(_,_,SOME({}),_,_,_,_,THREADSCHEDULE(threadTasks=threadTasks, lockIdc=lockIdc))
      equation
        schedule = THREADSCHEDULE(threadTasks,lockIdc);  
      then
        schedule; 
    case(_,_,SOME(order),_,_,_,_,THREADSCHEDULE(threadTasks=threadTasks, lockIdc=lockIdc))
      equation
        (node::rest) = order;
        proc = arrayGet(taskAss,node);
        taskLst = arrayGet(threadTasks, proc);
        // get the locks
        parentNodes = arrayGet(taskGraphTIn,node);
        childNodes = arrayGet(taskGraphIn,node);
        sameProcTasks = arrayGet(procAss,proc);
        (_,otherParents,_) = List.intersection1OnTrue(parentNodes,sameProcTasks,intEq);
        (_,otherChildren,_) = List.intersection1OnTrue(childNodes,sameProcTasks,intEq);
        assLockIdc = List.map1(otherParents,getAssignLockString,node);
        taskLstAss = List.map(assLockIdc,getAssignLockTask);
        relLockIdc = List.map1(otherChildren,getReleaseLockString,node);
        taskLstRel = List.map(relLockIdc,getReleaseLockTask);
        //build the calcTask          
        HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,exeCosts=exeCosts,commCosts=commCosts,nodeMark=nodeMark) = taskGraphMetaIn;
        components = arrayGet(inComps,node);
        mark = arrayGet(nodeMark,node); 
        ((_,exeCost)) = HpcOmTaskGraph.getExeCost(node,taskGraphMetaIn);  
        simEqIdc = List.map(List.map1(components,getSccSimEqMappingByIndex,SccSimEqMappingIn), List.last);     
        simEqIdc = listReverse(simEqIdc);
        task = CALCTASK(mark,node,exeCost,-1.0,proc,simEqIdc);
        taskLst1 = task::taskLstRel;
        taskLst1 = listAppend(taskLstAss,taskLst1);
        taskLst = listAppend(taskLst,taskLst1);     
        //update schedule
        threadTasks = arrayUpdate(threadTasks,proc,taskLst);
        lockIdc = listAppend(lockIdc,assLockIdc);
        schedule = THREADSCHEDULE(threadTasks,lockIdc);  
        schedule = createSchedulerFromAssignments(taskAss,procAss,SOME(rest),taskGraphIn,taskGraphTIn,taskGraphMetaIn,SccSimEqMappingIn,schedule);
      then
        schedule;     
    case(_,_,NONE(),_,_,_,_,THREADSCHEDULE(threadTasks=threadTasks, lockIdc=lockIdc))
      equation
        print("createSchedulerFromAssignments failed.implement this!\n");
      then
        fail();       
  end match;      
end createSchedulerFromAssignments;


protected function getAssignLockTask "outputs a AssignLockTsk for the given lockId.
author:Waurich TUD 2013-11"
  input String lockId;
  output Task taskOut;
algorithm
  taskOut := ASSIGNLOCKTASK(lockId);
end getAssignLockTask;


protected function getReleaseLockTask "outputs a ReleaseLockTsk for the given lockId.
author:Waurich TUD 2013-11"
  input String lockId;
  output Task taskOut;
algorithm
  taskOut := RELEASELOCKTASK(lockId);
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


protected function quicksortWithOrder "sorts a list of Reals with the quicksort algorithm and outputs an additional list with the changed order of the original indeces.
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
        (l,lIdx,b1) = getMemberOnTrueWithIdx(p,leftLst,realLt);
        (r,rIdx,b2) = getMemberOnTrueWithIdx(p,rightLst,realGt);
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
    case(_,{e},_)
      then
        (({},0));
    case(_,e::rest,_)
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

protected function computeALAP "computes the latest possible start time (As Late As Possible) for every node in the task graph.
author:Waurich TUD 2013-10"
  input HpcOmTaskGraph.TaskGraph iTaskGraph;  
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  output array<Real> alapOut;
protected
  Integer size;
  Real cp;
  list<Integer> endNodes;
  array<Real> alap;
  array<list<Integer>> taskGraphT;
algorithm
  size := arrayLength(iTaskGraph);
  // traverse the taskGraph topdown to get the alap times
  taskGraphT := BackendDAEUtil.transposeMatrix(iTaskGraph,size); 
  endNodes := HpcOmTaskGraph.getRootNodes(iTaskGraph);
  alap := arrayCreate(size,0.0);
  alap := computeALAP1(iTaskGraph,taskGraphT,{},endNodes,iTaskGraphMeta,alap);
  cp := Util.arrayFold(alap,realMax,0.0);
  alap := Util.arrayMap1(alap,realSubr,cp);
  alapOut := alap;
end computeALAP;

protected function realSubr 
  input Real r1;
  input Real r2;
  output Real r3;
algorithm
  r3 := realSub(r2,r1);
end realSubr;

protected function computeALAP1 "traverses the taskGraph topdown starting with the end nodes of the original non-transposed graph.
author: Waurich TUD 2013-10"
  input HpcOmTaskGraph.TaskGraph iTaskGraph; 
  input HpcOmTaskGraph.TaskGraph iTaskGraphT; 
  input list<Integer> assignedNodesIn;
  input list<Integer> nextNodesIn;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Real> alapIn;
  output array<Real> alapOut;
algorithm
  alapOut := matchcontinue(iTaskGraph,iTaskGraphT,assignedNodesIn,nextNodesIn,iTaskGraphMeta,alapIn)
    local
      Boolean notChecked;
      Integer node,child;
      Real exeCost1,exeCost2;
      array<Real> alap;
      list<Integer> rest, parentLst, assignedNodes, nextNodes;
      list<Real> parentCosts;   
  case(_,_,_,_,_,_)
    equation
      (node::nextNodes) = nextNodesIn;
      exeCost1 = getALAPCost(node,alapIn,iTaskGraph,iTaskGraphMeta); // gets the higest alapTime of all childNodes
      ((_,exeCost2)) = HpcOmTaskGraph.getExeCost(node, iTaskGraphMeta);
      exeCost2 = realAdd(exeCost1,exeCost2);
      alap = arrayUpdate(alapIn,node,exeCost2);  
      parentLst = arrayGet(iTaskGraphT,node);
      parentLst = getParentsWithOneLeftChild(parentLst,assignedNodesIn,iTaskGraph);
      assignedNodes = node::assignedNodesIn;
      nextNodes = listAppend(nextNodes,parentLst);
      alap = computeALAP1(iTaskGraph,iTaskGraphT,assignedNodes,nextNodes,iTaskGraphMeta,alap);     
    then alap;
  case(_,_,_,{},_,_)
    equation
      true = listLength(assignedNodesIn) == arrayLength(iTaskGraph);
    then alapIn; 
  else
    equation
      print("computeALAP1 failed!\n");
    then fail();
  end matchcontinue;  
end computeALAP1;

protected function getParentsWithOneLeftChild "gets the nodes from the parentlst, that have jsut on child that is not in the nodeLst.
author: Waurich TUD 2013-11"
  input list<Integer> parentLstIn;
  input list<Integer> nodeLst;  // the nodes that are not concerned
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  output list<Integer> parentLstOut;
algorithm
  parentLstOut := List.fold2(parentLstIn,getParentsWithOneLeftChild1,nodeLst,taskGraphIn,{});  
end getParentsWithOneLeftChild;

protected function getParentsWithOneLeftChild1 "folding function of getParentsWithOneLeftChild.
author:Waurich TUD 2013-11"
  input Integer parent;
  input list<Integer> nodeLst;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input list<Integer> parentLstIn;
  output list<Integer> parentLstOut;
protected
  Boolean justOneChild;
  list<Integer> childNodes;
algorithm
  childNodes := arrayGet(taskGraphIn,parent);
  (_,childNodes,_) := List.intersection1OnTrue(childNodes,nodeLst,intEq);
  justOneChild := intEq(listLength(childNodes),1) and List.isNotEmpty(childNodes);
  parentLstOut := Util.if_(justOneChild,parent::parentLstIn,parentLstIn);  
end getParentsWithOneLeftChild1;

protected function getALAPCost "gets the alap time and commCost for the parentNode with the highest alapTime
author: Waurich TUD 2013-10"
  input Integer parent;
  input array<Real> allALAPTimesIn;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  output Real alapTimeOut;
algorithm
  alapTimeOut := matchcontinue(parent,allALAPTimesIn,taskGraphIn,taskGraphMetaIn)
    local
      Real alapTime, commCostR; 
      Integer node, commCostInt;
      list<Integer> allChildren;
      list<Real> allChildAlaps;
    case(_,_,_,_)
      equation
        allChildren = arrayGet(taskGraphIn,parent);
        true = List.isNotEmpty(allChildren);
        allChildAlaps = List.map3(allChildren,getALAPCost1,parent,allALAPTimesIn,taskGraphMetaIn);
        alapTime = List.fold(allChildAlaps,realMax,0.0);
      then
        alapTime;
    case(_,_,_,_)
      equation
        allChildren = arrayGet(taskGraphIn,parent);
        true = List.isEmpty(allChildren);
      then
        0.0;
    else
      equation
        print("getALAPCost failed!\n");
      then
        fail();
   end matchcontinue;        
end getALAPCost;

protected function getALAPCost1
  input Integer child;
  input Integer parent;
  input array<Real> allALAPTimesIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  output Real alapTimeOut;
protected
  Integer commCostInt;
  Real alapTime, commCostR;
algorithm
  alapTime := arrayGet(allALAPTimesIn,child);
  ((_,_,commCostInt)) := HpcOmTaskGraph.getCommCostBetweenNodes(parent,child,taskGraphMetaIn); //TODO: think about whether we need the highest commCost for contracted nodes, or just the cost from last parent to first child
  commCostR := intReal(commCostInt);
  alapTimeOut := realAdd(alapTime,commCostR);
end getALAPCost1;


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


public function predictExecutionTime  "computes the theoretically execution time for the serial simulation and the parallel. a speedup ratio is determined by su=serTime/parTime.
the max speedUp is computed via the serTime/criticalPathCosts.
author:Waurich TUD 2013-11"
  input Schedule scheduleIn;
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
      Schedule schedule;
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
        //print("the serialCosts: "+&realString(serTime)+&"\n");
        //print("the parallelCosts: "+&realString(parTime)+&"\n");
        //print("the cpCosts: "+&realString(cpCosts)+&"\n");
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
        print("The predicted SpeedUp with "+&intString(numProc)+&" processors is "+&realString(speedUp)+&".\n");
      then
        ();
    else
      equation
        isOkString = "The predicted SpeedUp with "+&intString(numProc)+&" processors is: "+&realString(speedUp)+&" With a theoretical maxmimum speedUp of: "+&realString(speedUpMax)+&"\n";
        isNotOkString = "Something is weird. The predicted SpeedUp is "+&realString(speedUp)+&" and the theoretical maximum speedUp is "+&realString(speedUpMax)+&"\n";
        Debug.bcall(realGt(speedUp,speedUpMax),print,isNotOkString);
        Debug.bcall(realLe(speedUp,speedUpMax),print,isOkString);
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
  input Schedule scheduleIn;
  input Integer numProc;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  output Schedule scheduleOut;
  output Real finishingTime;
algorithm
  (scheduleOut,finishingTime) := match(scheduleIn,numProc,taskGraphIn,taskGraphMetaIn)
    local
      Real finTime; 
      array<Integer> taskIdcs; // idcs of the current Task for every proc.
      array<Real> finTimes;
      HpcOmTaskGraph.TaskGraph taskGraphT;
      array<Task> checkedTasks, lastTasks;
      array<list<Task>> threadTasks, threadTasksNew;
      list<String> lockIdc;
      list<list<Integer>> eqsOfLevels;
      Task task;
      Schedule schedule; 
    case(THREADSCHEDULE(threadTasks=threadTasks,lockIdc=lockIdc),_,_,_)
      equation
        taskIdcs = arrayCreate(arrayLength(threadTasks),1);  // the TaskIdcs to be checked for every thread
        taskGraphT = BackendDAEUtil.transposeMatrix(taskGraphIn,arrayLength(taskGraphIn));
        checkedTasks = arrayCreate(arrayLength(taskGraphIn),TASKEMPTY());
        threadTasksNew = computeTimeFinished(threadTasks,taskIdcs,1,checkedTasks,taskGraphIn,taskGraphT,taskGraphMetaIn,numProc,{});
        finTimes = Util.arrayMap(threadTasksNew,getTimeFinishedOfLastTask);
        finTime = Util.arrayFold(finTimes,realMax,0.0);
        schedule = THREADSCHEDULE(threadTasksNew,lockIdc);
      then
        (schedule,finTime);
    case(LEVELSCHEDULE(eqsOfLevels),_,_,_)
      equation
        schedule = scheduleIn;
        finTime = 0.0;
      then
        (schedule,finTime);
    case(EMPTYSCHEDULE(),_,_,_)
      equation
        schedule = scheduleIn;
        finTime = -1.0;
      then
        (schedule,finTime);
  end match;
end getFinishingTimesForSchedule;


protected function getTimeFinishedOfLastTask "get the timeFinished of the last task of a thread. if the thread is empty its -1.0.
author:Waurich TUD 2013-11"
  input list<Task> threadTasksIn;
  output Real finTimeOut;
algorithm
  finTimeOut := matchcontinue(threadTasksIn)
    local
      Task lastTask;
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
  input array<list<Task>> threadTasksIn;
  input array<Integer> taskIdcsIn;
  input Integer threadIdxIn;
  input array<Task> checkedTasksIn;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraph taskGraphTIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  input Integer numProc;
  input list<Integer> closedThreads;
  output array<list<Task>> threadTasksOut;
algorithm
  threadTasksOut := matchcontinue(threadTasksIn,taskIdcsIn,threadIdxIn,checkedTasksIn,taskGraphIn,taskGraphTIn,taskGraphMetaIn,numProc,closedThreads)
    local
      Boolean isCalc, isComputable;
      Integer taskIdx, nextThreadIdx, nextTaskIdx;
      array<Integer> taskIdcs;
      list<Integer> closedThreads1;
      Task task;
      array<list<Task>> threadTasks;
      array<Task> checkedTasks;
      list<Task> thread;
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
  input Task taskIn;
  input Integer taskIdxIn;
  input Integer threadIdxIn;
  input array<list<Task>> threadTasksIn;
  input array<Task> checkedTasksIn;
  input HpcOmTaskGraph.TaskGraph taskGraphTIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  output array<list<Task>> threadTasksOut;
  output array<Task> checkedTasksOut;
  output Integer taskIdxOut;
algorithm
  (threadTasksOut,checkedTasksOut,taskIdxOut) := match(taskIn,taskIdxIn,threadIdxIn,threadTasksIn,checkedTasksIn,taskGraphTIn,taskGraphMetaIn)
    local
      Boolean isComputable;
      Integer taskID, taskIdxNew;
      Real finishingTime;
      list<Integer> parentLst;
      Task latestTask,startTask;
      array<Task> checkedTasks;
      array<list<Task>> threadTasks;
    case(CALCTASK(weighting=_,index=taskID,calcTime=_,timeFinished=_,threadIdx=_,eqIdc=_),_,_,_,_,_,_)
      equation
        parentLst = arrayGet(taskGraphTIn,taskID);
        // gets the parentIdcs which are not yet checked and computes the latest finishingTime of all parentNodes
        ((parentLst, latestTask)) = List.fold1(parentLst, updateFinishingTime1, checkedTasksIn, ({},TASKEMPTY()));   
        isComputable = List.isEmpty(parentLst);
        taskIdxNew = Util.if_(isComputable,taskIdxIn+1,taskIdxIn);
        //update the threadTasks and checked Tasks
        ((threadTasks,checkedTasks)) = Debug.bcallret1(isComputable, computeFinishingTimeForOneTask, (threadTasksIn,checkedTasksIn,taskIdxIn,threadIdxIn,latestTask,taskGraphMetaIn),(threadTasksIn,checkedTasksIn));
      then 
        (threadTasks,checkedTasks,taskIdxNew);
    case(ASSIGNLOCKTASK(lockId=_),_,_,_,_,_,_)
      equation
        //skip the assignlock
        taskIdxNew = taskIdxIn+1;
      then
        (threadTasksIn,checkedTasksIn,taskIdxNew);
    case(RELEASELOCKTASK(lockId=_),_,_,_,_,_,_)
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
  input array<Task> checkedTaskIn;
  input tuple<list<Integer>,Task> tplIn;
  output tuple<list<Integer>,Task> tplOut;
protected
  Boolean isCalc;
  Real finishingTime, finishingTime1, finishingTimeIn;
  list<Integer> parentLst, parentLstIn;
  Task task, taskIn;
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
  input tuple<array<list<Task>>,array<Task>,Integer,Integer,Task,HpcOmTaskGraph.TaskGraphMeta> tplIn;
  output tuple<array<list<Task>>,array<Task>> tplOut;
algorithm
  tplOut := matchcontinue(tplIn)
    local
      Boolean isEmpty; 
      array<list<Task>> threadTasks,threadTasksIn;
      array<Task> checkedTasksIn, checkedTasks;
      Integer commCost, taskIdx,taskIdxLatest, taskNum, threadIdx, threadIdxLatest;
      Real finishingTime, finishingTime1, finishingTimeComm, exeCost, commCostR;
      HpcOmTaskGraph.TaskGraphMeta taskGraphMeta;
      Task task, latestTask, preTask;
      list<Task> thread;
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
  input list<Task> threadIn; 
  input Integer indexIn;
  output Task taskOut;
algorithm
  taskOut := matchcontinue(threadIn,indexIn)
    local
      Boolean isCalc;
      Integer index;
      Task preTask;
    case(_,_)
      equation
        true = indexIn==1;
      then
        TASKEMPTY();
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
  input Task taskIn;
  input Real timeFinishedIn;
  output Task taskOut;
protected 
  Integer weighting;
  Integer index;
  Real calcTime;
  Real timeFinished;
  Integer threadIdx;
  list<Integer> eqIdc;
algorithm
  CALCTASK(weighting=weighting,index=index,calcTime=calcTime,timeFinished=timeFinished,threadIdx=threadIdx,eqIdc=eqIdc) := taskIn;
  taskOut := CALCTASK(weighting,index,calcTime,timeFinishedIn,threadIdx,eqIdc);
end updateTimeFinished;

  
protected function getTimeFinished "gets the timeFinished of a calcTask, if its not a calctask its -1.0. if its an emptyTask its 0.0
author:Waurich TUD 2013-11"
  input Task taskIn;
  output Real finishingTime;
algorithm
  finishingTime := match(taskIn)
  local
    Real fTime;
  case(CALCTASK(weighting=_,index=_,calcTime=_,timeFinished=fTime,threadIdx=_,eqIdc=_))
    then
      fTime;
  case(TASKEMPTY())
    then
      0.0;
  else
    then
      -1.0;
  end match;
end getTimeFinished;   


protected function getThreadId "gets the threadIdx of a calcTask, if its not a calctask its -1
author:Waurich TUD 2013-11"
  input Task taskIn;
  output Integer threadId;
algorithm
  threadId := match(taskIn)
  local
    Integer threadIdx;
  case(CALCTASK(weighting=_,index=_,calcTime=_,timeFinished=_,threadIdx=threadIdx,eqIdc=_))
    then
      threadIdx;
  else
    then
      -1;
  end match;
end getThreadId; 


protected function getTaskIdx "gets the idx of the calcTask.if its no calcTask, then -1.
author: Waurich TUD 2013-11"
  input Task taskIn;
  output Integer idx;
algorithm
  idx := match(taskIn)
    local
      Integer taskIdx;
    case(CALCTASK(weighting=_,index=taskIdx,calcTime=_,timeFinished=_,threadIdx=_,eqIdc=_))
      then
        taskIdx;
    else
      then
        -1;
  end match;
end getTaskIdx;


protected function isCalcTask "checks if the given task is a calcTask.
author:Waurich TUD 2013-11"
  input Task taskIn;
  output Boolean isCalc;
algorithm
  isCalc := match(taskIn)
  case(CALCTASK(weighting=_,index=_,calcTime=_,timeFinished=_,threadIdx=_,eqIdc=_))
    then
      true;
  else
    then
      false;
  end match;
end isCalcTask;    


protected function isEmptyTask "checks if the given task is an emptyTask.
author:Waurich TUD 2013-11"
  input Task taskIn;
  output Boolean isEmpty;
algorithm
  isEmpty := match(taskIn)
  case(TASKEMPTY())
    then
      true;
  else
    then
      false;
  end match;
end isEmptyTask;    
    

protected function printALAP"prints the information of the ALAP array
author:Waurich TUD 2013-11"
  input array<Real> inArray;
algorithm
  _ := Util.arrayFold(inArray,printALAP1,1);
end printALAP;


protected function printALAP1
  input Real inValue;
  input Integer idxIn;
  output Integer idxOut;
algorithm
  print("node: "+&intString(idxIn)+&" has the alap: "+&realString(inValue)+&"\n");
  idxOut := idxIn +1;
end printALAP1;

end HpcOmScheduler;
