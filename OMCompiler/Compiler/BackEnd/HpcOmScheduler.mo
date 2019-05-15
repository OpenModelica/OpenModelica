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

"

public import BackendDAE;
public import HpcOmTaskGraph;
public import HpcOmSimCode;
public import SimCode;
public import SimCodeVar;

protected
import AdjacencyMatrix;
import Array;
import BackendDAEUtil;
import BackendVarTransform;
import ComponentReference;
import DAE;
import Error;
import Expression;
import Flags;
import HashTableCrefSimVar;
import HpcOmSchedulerExt;
import HpcOmSimCodeMain;
import List;
import SimCodeFunctionUtil;
import SimCodeUtil;
import System;
import Util;

public type TaskAssignment = array<Integer>; //the information which node <idx> is assigned to which processor <value>


//--------------
// No Scheduling
//--------------
public function createEmptySchedule "author: marcusw
  Create a empty-schedule to produce serial code. The produces task list represents the computation order of the serial code."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  output HpcOmSimCode.Schedule oSchedule;
protected
  list<HpcOmSimCode.Task> sortedTasks;
  HpcOmTaskGraph.TaskGraph taskGraphT;
  list<HpcOmSimCode.Task> allTasks = {};
  array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks; //tasks with ref counter
  Integer taskIdx;

  Integer weighting, index, threadIdx;
  Real calcTime, timeFinished;
  list<Integer> eqIdc;
algorithm
  taskGraphT := AdjacencyMatrix.transposeAdjacencyMatrix(iTaskGraph,arrayLength(iTaskGraph));
  allCalcTasks := convertTaskGraphToTasks(taskGraphT,iTaskGraphMeta,convertNodeToTask);
  for taskIdx in listReverse(List.intRange(arrayLength(allCalcTasks))) loop
    ((HpcOmSimCode.CALCTASK(weighting, index, calcTime, timeFinished, threadIdx, eqIdc),_)) := arrayGet(allCalcTasks, taskIdx);
    eqIdc := List.map(List.map1(eqIdc,getSimEqSysIdxForComp,iSccSimEqMapping), List.last);
    allTasks := HpcOmSimCode.CALCTASK(weighting, index, calcTime, timeFinished, threadIdx, eqIdc)::allTasks;
  end for;
  allTasks := List.sort(allTasks, compareTasksByEqIdc);
  oSchedule := HpcOmSimCode.EMPTYSCHEDULE(HpcOmSimCode.SERIALTASKLIST(allTasks, true));
end createEmptySchedule;


//----------------
// List Scheduling
//----------------
public function createListSchedule "author: marcusw
  Create a list-schedule out of the given informations."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer iNumberOfThreads;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  output HpcOmSimCode.Schedule oSchedule;
protected
  HpcOmTaskGraph.TaskGraph taskGraphT;
  array<list<Integer>> inComps;
  list<tuple<HpcOmSimCode.Task,Integer>> nodeList_refCount; //list of nodes which are ready to schedule
  list<HpcOmSimCode.Task> nodeList;
  list<Integer> rootNodes;
  array<Real> threadReadyTimes;
  array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
  array<list<HpcOmSimCode.Task>> threadTasks;
  array<HpcOmTaskGraph.Communications> commCosts;
  HpcOmSimCode.Schedule tmpSchedule;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(commCosts=commCosts,inComps=inComps) := iTaskGraphMeta;
  taskGraphT := AdjacencyMatrix.transposeAdjacencyMatrix(iTaskGraph,arrayLength(iTaskGraph));
  rootNodes := HpcOmTaskGraph.getRootNodes(iTaskGraph);
  allCalcTasks := convertTaskGraphToTasks(taskGraphT,iTaskGraphMeta,convertNodeToTask);
  nodeList_refCount := List.map1(rootNodes, getTaskByIndex, allCalcTasks);
  nodeList := List.map(nodeList_refCount, Util.tuple21);
  nodeList := List.sort(nodeList, compareTasksByWeighting); //MF level
  threadReadyTimes := arrayCreate(iNumberOfThreads,0.0);
  threadTasks := arrayCreate(iNumberOfThreads,{});
  tmpSchedule := HpcOmSimCode.THREADSCHEDULE(threadTasks,{},{},allCalcTasks);
  (tmpSchedule,_) := createListSchedule1(nodeList,threadReadyTimes, iTaskGraph, taskGraphT, commCosts, inComps, iSccSimEqMapping, iSimVarMapping, getLocksByPredecessorList, tmpSchedule);
  tmpSchedule := addSuccessorLocksToSchedule(iTaskGraph,addReleaseLocksToSchedule,commCosts,inComps,iSimVarMapping,tmpSchedule);
  //printSchedule(tmpSchedule);
  oSchedule := setScheduleLockIds(tmpSchedule);
end createListSchedule;

protected function createListSchedule1 "author: marcusw
  Create a list schedule, starting with the given nodeList and ready times. This method will add calcTasks and
  assignLockTasks, but no releaseLockTasks!"
  input list<HpcOmSimCode.Task> iNodeList; //the sorted nodes -> this method will pick the first task
  input array<Real> iThreadReadyTimes; //the time until the thread is ready to handle a new task
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  input FuncType iLockWithPredecessorHandler; //Function which handles locks to all predecessors
  input HpcOmSimCode.Schedule iSchedule;
  output HpcOmSimCode.Schedule oSchedule;
  output array<Real> oThreadReadyTimes;

  partial function FuncType
    input HpcOmSimCode.Task iTask;
    input list<tuple<HpcOmSimCode.Task,Integer>> iPredecessors;
    input Integer iThreadIdx;
    input array<HpcOmTaskGraph.Communications> iCommCosts;
    input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
    input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
    output list<HpcOmSimCode.Task> oTasks; //lock tasks
    output list<HpcOmSimCode.Task> oOutgoingDepTasks;
  end FuncType;
protected
  HpcOmSimCode.Task head, newTask;
  Integer newTaskRefCount;
  list<HpcOmSimCode.Task> rest;
  Real lastChildFinishTime; //The time when the last child has finished calculation
  HpcOmSimCode.Task lastChild;
  list<tuple<HpcOmSimCode.Task, Integer>> predecessors, successors;
  list<Integer> successorIdc;
  list<HpcOmSimCode.Task> outgoingDepTasks, newOutgoingDepTasks;
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
  HpcOmSimCode.Schedule tmpSchedule;
  array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
algorithm
  (oSchedule,oThreadReadyTimes) := match(iNodeList,iThreadReadyTimes, iTaskGraph, iTaskGraphT, iCommCosts, iCompTaskMapping,
                                                 iSccSimEqMapping, iSimVarMapping, iLockWithPredecessorHandler, iSchedule)
    case((head as HpcOmSimCode.CALCTASK(weighting=weighting,index=index,calcTime=calcTime,eqIdc=(eqIdc as firstEq::_)))
      ::rest,_,_,_,_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE(threadTasks=allThreadTasks, outgoingDepTasks=outgoingDepTasks,allCalcTasks=allCalcTasks))
      equation
        //get all predecessors (childs)
        (predecessors, _) = getSuccessorsByTask(head, iTaskGraphT, allCalcTasks);
        (successors, successorIdc) = getSuccessorsByTask(head, iTaskGraph, allCalcTasks);

        if(boolNot(listEmpty(predecessors))) then //in this case the node has predecessors
          lastChild = getTaskWithHighestFinishTime(predecessors, NONE());
          HpcOmSimCode.CALCTASK(timeFinished=lastChildFinishTime) = lastChild;
        else
          lastChildFinishTime = 0.0;
        end if;

        threadFinishTimes = calculateFinishTimes(lastChildFinishTime, head, predecessors, iCommCosts, iThreadReadyTimes);
        ((threadId, threadFinishTime)) = getThreadFinishTimesMin(1,threadFinishTimes,-1,0.0);
        tmpThreadReadyTimes = arrayUpdate(iThreadReadyTimes, threadId, threadFinishTime);
        threadTasks = arrayGet(allThreadTasks,threadId);

        //print("Scheduling task " + intString(index) + " to thread " + intString(threadId) + "\n");
        if(boolNot(listEmpty(predecessors))) then //in this case the node has predecessors
          //find all predecessors which are scheduled to another thread and thus require a lock
          (lockTasks,newOutgoingDepTasks) = iLockWithPredecessorHandler(head,predecessors,threadId,iCommCosts,iCompTaskMapping,iSimVarMapping);
          outgoingDepTasks = listAppend(outgoingDepTasks,newOutgoingDepTasks);
          //threadTasks = listAppend(List.map(newLockIdc,convertLockIdToAssignTask), threadTasks);
          threadTasks = listAppend(lockTasks, threadTasks);

          //print("Eq idc: " + stringDelimitList(List.map(eqIdc, intString), ",") + "\n");
          simEqIdc = List.map(List.map1(eqIdc,getSimEqSysIdxForComp,iSccSimEqMapping), List.last);
          //simEqIdc = List.sort(simEqIdc,intGt);
        else
          simEqIdc = List.flatten(List.map1(eqIdc,getSimEqSysIdxForComp,iSccSimEqMapping));
        end if;

        newTask = HpcOmSimCode.CALCTASK(weighting,index,calcTime,threadFinishTime,threadId,simEqIdc);
        threadTasks = newTask::threadTasks;
        allThreadTasks = arrayUpdate(allThreadTasks,threadId,threadTasks);

        //add all successors with refcounter = 1
        (allCalcTasks,tmpNodeList) = updateRefCounterBySuccessorIdc(allCalcTasks,successorIdc,{});
        tmpNodeList = listAppend(tmpNodeList, rest);
        tmpNodeList = List.sort(tmpNodeList, compareTasksByWeighting);
        ((_,newTaskRefCount)) = arrayGet(allCalcTasks,index);
        arrayUpdate(allCalcTasks,index,(newTask,newTaskRefCount));
        (tmpSchedule,tmpThreadReadyTimes) = createListSchedule1(tmpNodeList,tmpThreadReadyTimes,iTaskGraph, iTaskGraphT, iCommCosts, iCompTaskMapping, iSccSimEqMapping, iSimVarMapping, iLockWithPredecessorHandler, HpcOmSimCode.THREADSCHEDULE(allThreadTasks,outgoingDepTasks,{},allCalcTasks));
      then (tmpSchedule,tmpThreadReadyTimes);
    case({},_,_,_,_,_,_,_,_,_) then (iSchedule,iThreadReadyTimes);
    else
      equation
        print("HpcOmScheduler.createListSchedule1 failed\n");
      then (iSchedule,iThreadReadyTimes);
  end match;
end createListSchedule1;


//----------------
// Random Scheduling
//----------------
public function createRandomSchedule "author: mflehmig
  Create a schedule out of the given informations by randomly chose a thread for each task.
  This implementation is very close to list scheduling algorithm but we do not need to calculate a 'best schedule'."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer iNumberOfThreads;
  input array<list<Integer>> iSccSimEqMapping;              //Maps each scc to a list of simEqs
  input array<list<SimCodeVar.SimVar>> iSimVarMapping;      //Maps each backend var to a list of simVars
  output HpcOmSimCode.Schedule oSchedule;
protected
  HpcOmTaskGraph.TaskGraph taskGraphT;
  array<list<Integer>> inComps;
  list<tuple<HpcOmSimCode.Task, Integer>> nodeList_refCount; //List of nodes which are ready to schedule
  list<HpcOmSimCode.Task> nodeList;
  list<Integer> rootNodes;
  array<Real> threadReadyTimes;
  array<tuple<HpcOmSimCode.Task, Integer>> allCalcTasks;
  array<list<HpcOmSimCode.Task>> threadTasks;
  array<HpcOmTaskGraph.Communications> commCosts;
  HpcOmSimCode.Schedule tmpSchedule;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(commCosts=commCosts, inComps=inComps) := iTaskGraphMeta;
  taskGraphT := AdjacencyMatrix.transposeAdjacencyMatrix(iTaskGraph, arrayLength(iTaskGraph));
  rootNodes := HpcOmTaskGraph.getRootNodes(iTaskGraph);
  allCalcTasks := convertTaskGraphToTasks(taskGraphT, iTaskGraphMeta, convertNodeToTask);
  nodeList_refCount := List.map1(rootNodes, getTaskByIndex, allCalcTasks);
  nodeList := List.map(nodeList_refCount, Util.tuple21);
  nodeList := List.sort(nodeList, compareTasksByWeighting); //MF level
  threadReadyTimes := arrayCreate(iNumberOfThreads ,0.0);
  threadTasks := arrayCreate(iNumberOfThreads, {});
  tmpSchedule := HpcOmSimCode.THREADSCHEDULE(threadTasks, {}, {}, allCalcTasks);
  (tmpSchedule,_) := createRandomSchedule1(nodeList, threadReadyTimes, iTaskGraph, taskGraphT, commCosts, inComps,
                                           iSccSimEqMapping, iSimVarMapping, getLocksByPredecessorList, iNumberOfThreads,
                                           tmpSchedule);
  tmpSchedule := addSuccessorLocksToSchedule(iTaskGraph, addReleaseLocksToSchedule, commCosts, inComps, iSimVarMapping,
                                             tmpSchedule);
  //printSchedule(tmpSchedule);
  oSchedule := setScheduleLockIds(tmpSchedule);
end createRandomSchedule;

protected function createRandomSchedule1 "author: mflehmig
  Create a random schedule starting with the given nodeList. This method will add calcTasks and assignLockTasks,
  but no releaseLockTasks!"
  input list<HpcOmSimCode.Task> iNodeList;              //The sorted nodes -> this method will pick the first task
  input array<Real> iThreadReadyTimes;                  //The time until the thread is ready to handle a new task
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping;          //All StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<Integer>> iSccSimEqMapping;          //Maps each scc to a list of simEqs
  input array<list<SimCodeVar.SimVar>> iSimVarMapping;  //Maps each backend var to a list of simVars
  input FuncType iLockWithPredecessorHandler;           //Function which handles locks to all predecessors
  input Integer iNumberOfThreads;
  input HpcOmSimCode.Schedule iSchedule;
  output HpcOmSimCode.Schedule oSchedule;
  output array<Real> oThreadReadyTimes;

  partial function FuncType
    input HpcOmSimCode.Task iTask;
    input list<tuple<HpcOmSimCode.Task,Integer>> iPredecessors;
    input Integer iThreadIdx;
    input array<HpcOmTaskGraph.Communications> iCommCosts;
    input array<list<Integer>> iCompTaskMapping;         //All StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
    input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
    output list<HpcOmSimCode.Task> oTasks;               //Lock tasks
    output list<HpcOmSimCode.Task> oOutgoingDepTasks;
  end FuncType;
protected
  HpcOmSimCode.Task head, newTask;
  Integer newTaskRefCount;
  list<HpcOmSimCode.Task> rest;
  Real lastChildFinishTime;                       //The time when the last child has finished calculation
  HpcOmSimCode.Task lastChild;
  list<tuple<HpcOmSimCode.Task, Integer>> predecessors, successors;
  list<Integer> successorIdc;
  list<HpcOmSimCode.Task> outgoingDepTasks, newOutgoingDepTasks;
  array<Real> threadFinishTimes;
  Integer firstEq;
  array<list<HpcOmSimCode.Task>> allThreadTasks;  //All tasks of all threads, i.e., allThreadTasks[i] = {all tasks of thread i}
  list<HpcOmSimCode.Task> threadTasks;            //All tasks of a particular thread (used as temp. var.), i.e., threadTasks = allThreadTasks[threadId]
  list<HpcOmSimCode.Task> lockTasks;
  Integer threadId;
  Real threadFinishTime;
  array<Real> tmpThreadReadyTimes;
  list<HpcOmSimCode.Task> tmpNodeList;
  Integer weighting;
  Integer index;
  Real calcTime;
  list<Integer> eqIdc, simEqIdc;
  HpcOmSimCode.Schedule tmpSchedule;
  array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
algorithm
  (oSchedule,oThreadReadyTimes) := matchcontinue(iNodeList,iThreadReadyTimes, iTaskGraph, iTaskGraphT, iCommCosts, iCompTaskMapping,
                                                 iSccSimEqMapping, iSimVarMapping, iLockWithPredecessorHandler, iNumberOfThreads, iSchedule)
    case((head as HpcOmSimCode.CALCTASK(weighting=weighting,index=index,calcTime=calcTime,eqIdc=(eqIdc as firstEq::_)))::rest
         ,_,_,_,_,_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE(threadTasks=allThreadTasks, outgoingDepTasks=outgoingDepTasks, allCalcTasks=allCalcTasks))
      equation
        //Get all predecessors (childs)
        (predecessors, _) = getSuccessorsByTask(head, iTaskGraphT, allCalcTasks);
        (successors, successorIdc) = getSuccessorsByTask(head, iTaskGraph, allCalcTasks);
        false = listEmpty(predecessors); //in this case the node has predecessors
        //!print("Handle1 task " + intString(index) + "\n");// + " with " + intString(listLength(predecessors)) + " child nodes and "
              //+ intString(listLength(successorIdc)) + " parent nodes.\n");
        //!print("\tZeile 367\t" + stringDelimitList(List.map(arrayList(iThreadReadyTimes),realString), "\t\t") + "\n");

        //! Randomly chose thread for scheduling.
        threadId = System.intRandom(iNumberOfThreads) + 1;

        threadFinishTimes = calculateFinishTimes(0.0, head, {}, iCommCosts, iThreadReadyTimes);
        threadFinishTime = arrayGet(threadFinishTimes, threadId);
        tmpThreadReadyTimes = arrayUpdate(iThreadReadyTimes, threadId, threadFinishTime);
        threadTasks = arrayGet(allThreadTasks,threadId);

        //Find all predecessors which are scheduled to another thread and thus require a lock
        (lockTasks,newOutgoingDepTasks) = iLockWithPredecessorHandler(head, predecessors, threadId, iCommCosts, iCompTaskMapping,
                                                                      iSimVarMapping);
        outgoingDepTasks = listAppend(outgoingDepTasks, newOutgoingDepTasks);
        threadTasks = listAppend(lockTasks, threadTasks);

        simEqIdc = List.map(List.map1(eqIdc, getSimEqSysIdxForComp, iSccSimEqMapping), List.last);
        //simEqIdc = List.sort(simEqIdc,intGt);

        //! Add task to thread
        newTask = HpcOmSimCode.CALCTASK(weighting, index, calcTime, threadFinishTime, threadId, simEqIdc);
        threadTasks = newTask::threadTasks;
        allThreadTasks = arrayUpdate(allThreadTasks, threadId, threadTasks);

        //add all successors with refcounter = 1
        (allCalcTasks, tmpNodeList) = updateRefCounterBySuccessorIdc(allCalcTasks, successorIdc, {});
        tmpNodeList = listAppend(tmpNodeList, rest);
        tmpNodeList = List.sort(tmpNodeList, compareTasksByWeighting);
        (_, newTaskRefCount) = arrayGet(allCalcTasks, index);
        _ = arrayUpdate(allCalcTasks, index, (newTask, newTaskRefCount));
        (tmpSchedule, tmpThreadReadyTimes) = createRandomSchedule1(tmpNodeList,tmpThreadReadyTimes, iTaskGraph, iTaskGraphT,
                                                                   iCommCosts, iCompTaskMapping, iSccSimEqMapping, iSimVarMapping,
                                                                   iLockWithPredecessorHandler, iNumberOfThreads,
                                                                   HpcOmSimCode.THREADSCHEDULE(allThreadTasks, outgoingDepTasks,
                                                                   {}, allCalcTasks));
      then (tmpSchedule,tmpThreadReadyTimes);
    case((head as HpcOmSimCode.CALCTASK(weighting=weighting,index=index,calcTime=calcTime,eqIdc=(eqIdc as firstEq::_)))::rest
          ,_,_,_,_,_,_,_,_,_,
          HpcOmSimCode.THREADSCHEDULE(threadTasks=allThreadTasks,outgoingDepTasks=outgoingDepTasks, allCalcTasks=allCalcTasks))
      equation
        (successors, successorIdc) = getSuccessorsByTask(head, iTaskGraph, allCalcTasks);

        //Randomly chose thread for scheduling
        threadId = System.intRandom(iNumberOfThreads)+1;
        //print("ThreadId= " + intString(threadId) + "\n");

        threadFinishTimes = calculateFinishTimes(0.0, head, {}, iCommCosts, iThreadReadyTimes);
        threadFinishTime = arrayGet(threadFinishTimes, threadId);

        // Update array containg thread finish times.
        tmpThreadReadyTimes = arrayUpdate(iThreadReadyTimes, threadId, threadFinishTime);
        threadTasks = arrayGet(allThreadTasks, threadId);

        simEqIdc = List.flatten(List.map1(eqIdc, getSimEqSysIdxForComp, iSccSimEqMapping));
        //simEqIdc = List.sort(simEqIdc,intGt);

        newTask = HpcOmSimCode.CALCTASK(weighting, index, calcTime, threadFinishTime, threadId, simEqIdc);
        allThreadTasks = arrayUpdate(allThreadTasks, threadId, newTask::threadTasks);

        //Add all successors with refcounter = 1
        (allCalcTasks, tmpNodeList) = updateRefCounterBySuccessorIdc(allCalcTasks, successorIdc, {});
        tmpNodeList = listAppend(tmpNodeList, rest);
        tmpNodeList = List.sort(tmpNodeList, compareTasksByWeighting);
        (_, newTaskRefCount) = arrayGet(allCalcTasks, index);
        _ = arrayUpdate(allCalcTasks, index, (newTask, newTaskRefCount));
        (tmpSchedule,tmpThreadReadyTimes) = createRandomSchedule1(tmpNodeList, tmpThreadReadyTimes, iTaskGraph, iTaskGraphT,
                                                                  iCommCosts, iCompTaskMapping, iSccSimEqMapping, iSimVarMapping,
                                                                  iLockWithPredecessorHandler, iNumberOfThreads,
                                                                  HpcOmSimCode.THREADSCHEDULE(allThreadTasks, outgoingDepTasks,
                                                                  {}, allCalcTasks));
      then (tmpSchedule,tmpThreadReadyTimes);
    case({},_,_,_,_,_,_,_,_,_,_) then (iSchedule, iThreadReadyTimes);
    else
      equation
        print("HpcOmScheduler.createRandomSchedule1 failed\n");
      then fail();
  end matchcontinue;
end createRandomSchedule1;


//------------------------
// List Scheduling reverse
//------------------------
public function createListScheduleReverse "author: marcusw
  Create a list-schedule out of the given information, starting with all leaves."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer iNumberOfThreads;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  output HpcOmSimCode.Schedule oSchedule;
protected
  HpcOmTaskGraph.TaskGraph taskGraphT;
  list<tuple<HpcOmSimCode.Task,Integer>> nodeList_refCount; //list of nodes which are ready to schedule
  list<HpcOmSimCode.Task> nodeList;
  list<Integer> leaveNodes;
  array<Real> threadReadyTimes;
  array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
  array<list<HpcOmSimCode.Task>> threadTasks;
  array<HpcOmTaskGraph.Communications> commCosts, commCostsT;
  HpcOmSimCode.Schedule tmpSchedule;
  list<HpcOmSimCode.Task> outgoingDepTasks;
  array<list<Integer>> inComps;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(commCosts=commCosts,inComps=inComps) := iTaskGraphMeta;
  taskGraphT := AdjacencyMatrix.transposeAdjacencyMatrix(iTaskGraph,arrayLength(iTaskGraph));
  commCostsT := HpcOmTaskGraph.transposeCommCosts(commCosts);
  leaveNodes := HpcOmTaskGraph.getLeafNodes(iTaskGraph);
  //print("Leave nodes: " + stringDelimitList(List.map(leaveNodes,intString),", ") + "\n");
  allCalcTasks := convertTaskGraphToTasks(iTaskGraph,iTaskGraphMeta,convertNodeToTaskReverse);
  nodeList_refCount := List.map1(leaveNodes, getTaskByIndex, allCalcTasks);
  nodeList := List.map(nodeList_refCount, Util.tuple21);
  nodeList := List.sort(nodeList, compareTasksByWeighting);
  threadReadyTimes := arrayCreate(iNumberOfThreads,0.0);
  threadTasks := arrayCreate(iNumberOfThreads,{});
  tmpSchedule := HpcOmSimCode.THREADSCHEDULE(threadTasks,{},{},allCalcTasks);
  (tmpSchedule,_) := createListSchedule1(nodeList,threadReadyTimes, taskGraphT, iTaskGraph, commCostsT, inComps, iSccSimEqMapping, iSimVarMapping, getLockTasksByPredecessorListReverse, tmpSchedule);
  tmpSchedule := addSuccessorLocksToSchedule(taskGraphT,addAssignLocksToSchedule,commCosts,inComps,iSimVarMapping,tmpSchedule);
  HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,outgoingDepTasks=outgoingDepTasks) := tmpSchedule;
  threadTasks := Array.map(threadTasks, listReverse);
  tmpSchedule := HpcOmSimCode.THREADSCHEDULE(threadTasks,outgoingDepTasks,{},allCalcTasks);
  //printSchedule(tmpSchedule);
  oSchedule := setScheduleLockIds(tmpSchedule); // set unique lock ids
end createListScheduleReverse;

protected function addSuccessorLocksToSchedule
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input FuncType iCreateLockFunction;
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping;            //All StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<SimCodeVar.SimVar>> iSimVarMapping;    //Maps each backend var to a list of simVars
  input HpcOmSimCode.Schedule iSchedule;
  output HpcOmSimCode.Schedule oSchedule;

  partial function FuncType
    input tuple<HpcOmSimCode.Task,Integer> iSuccessorTask;
    input HpcOmSimCode.Task iTask;
    input array<HpcOmTaskGraph.Communications> iCommCosts;
    input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
    input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
    input list<HpcOmSimCode.Task> iReleaseTasks;
    output list<HpcOmSimCode.Task> oReleaseTasks;
  end FuncType;
protected
  array<list<HpcOmSimCode.Task>> allThreadTasks;
  HpcOmSimCode.Schedule tmpSchedule;
  list<HpcOmSimCode.Task> outgoingDepTasks;
  array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
algorithm
  oSchedule := match(iTaskGraph,iCreateLockFunction,iCommCosts,iCompTaskMapping,iSimVarMapping,iSchedule)
    case(_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE(threadTasks=allThreadTasks,outgoingDepTasks=outgoingDepTasks,allCalcTasks=allCalcTasks))
      equation
        ((allThreadTasks,_)) = Array.fold6(allThreadTasks, addSuccessorLocksToSchedule0, iTaskGraph, allCalcTasks,  iSimVarMapping, iCommCosts, iCompTaskMapping, iCreateLockFunction, (allThreadTasks,1));
        tmpSchedule = HpcOmSimCode.THREADSCHEDULE(allThreadTasks,outgoingDepTasks,{},allCalcTasks);
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
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllCalcTasks;
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input FuncType iCreateLockFunction;
  input tuple<array<list<HpcOmSimCode.Task>>, Integer> iThreadTasks; //<schedulerTasks, threadId>
  output tuple<array<list<HpcOmSimCode.Task>>, Integer> oThreadTasks;

  partial function FuncType
    input tuple<HpcOmSimCode.Task,Integer> iSuccessorTask;
    input HpcOmSimCode.Task iTask;
    input array<HpcOmTaskGraph.Communications> iCommCosts;
    input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
    input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
    input list<HpcOmSimCode.Task> iReleaseTasks;
    output list<HpcOmSimCode.Task> oReleaseTasks;
  end FuncType;
protected
  Integer threadId;
  array<list<HpcOmSimCode.Task>> allThreadTasks;
  list<HpcOmSimCode.Task> threadTasks;
algorithm
  (allThreadTasks,threadId) := iThreadTasks;
  threadTasks := List.fold(iThreadTaskList, function addSuccessorLocksToSchedule1(iTaskGraph=iTaskGraph, iAllCalcTasks=iAllCalcTasks, iSimVarMapping=iSimVarMapping, iCommCosts=iCommCosts, iCompTaskMapping=iCompTaskMapping, iThreadIdLockFunction=(threadId, iCreateLockFunction)), {});
  allThreadTasks := arrayUpdate(allThreadTasks,threadId,threadTasks);
  oThreadTasks := ((allThreadTasks,threadId+1));
end addSuccessorLocksToSchedule0;

protected function addSuccessorLocksToSchedule1
  input HpcOmSimCode.Task iTask;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllCalcTasks;
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input tuple<Integer,FuncType> iThreadIdLockFunction; //<threadId, createLockFunction>
  input list<HpcOmSimCode.Task> iThreadTasks; //schedulerTasks
  output list<HpcOmSimCode.Task> oThreadTasks;

  partial function FuncType
    input tuple<HpcOmSimCode.Task,Integer> iSuccessorTask;
    input HpcOmSimCode.Task iTask;
    input array<HpcOmTaskGraph.Communications> iCommCosts;
    input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
    input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
    input list<HpcOmSimCode.Task> iReleaseTasks;
    output list<HpcOmSimCode.Task> oReleaseTasks;
  end FuncType;
protected
  Integer threadIdx,index,listIndex;
  list<tuple<HpcOmSimCode.Task,Integer>> successors;
  list<HpcOmSimCode.Task> tmpThreadTasks, releaseTasks;
  Integer iThreadId;
  FuncType iCreateLockFunction;
algorithm
  oThreadTasks := match(iTask, iTaskGraph, iAllCalcTasks, iSimVarMapping, iCommCosts, iCompTaskMapping, iThreadIdLockFunction, iThreadTasks)
    case(HpcOmSimCode.CALCTASK(threadIdx=threadIdx,index=index),_,_,_,_,_,(iThreadId,iCreateLockFunction),tmpThreadTasks)
      equation
        (successors,_) = getSuccessorsByTask(iTask, iTaskGraph, iAllCalcTasks);
        successors = List.removeOnTrue(threadIdx, compareTaskWithThreadIdx, successors);
        releaseTasks = List.fold4(successors, iCreateLockFunction, iTask, iCommCosts, iCompTaskMapping, iSimVarMapping, {});
        tmpThreadTasks = listAppend(releaseTasks,tmpThreadTasks);
        tmpThreadTasks = iTask :: tmpThreadTasks;
      then tmpThreadTasks;
    case(_,_,_,_,_,_,_,tmpThreadTasks)
      equation
        tmpThreadTasks = iTask :: tmpThreadTasks;
      then tmpThreadTasks;
    else
      equation
        print("HpcOmScheduler.addReleaseLocksToSchedule0 failed\n");
      then fail();
  end match;
end addSuccessorLocksToSchedule1;

protected function addReleaseLocksToSchedule "author: marcusw
  Add a release lock to the schedule, releasing a lock from iTask to successor."
  input tuple<HpcOmSimCode.Task,Integer> iSuccessorTask;
  input HpcOmSimCode.Task iTask;
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  input list<HpcOmSimCode.Task> iReleaseTasks;
  output list<HpcOmSimCode.Task> oReleaseTasks;
protected
  HpcOmSimCode.Task tmpTask, successorTask;
  String lockString;
  Integer lockId, successorTaskId;
algorithm
  (successorTask,_) := iSuccessorTask;
  tmpTask := createDepTaskAndCommunicationInfo(iTask,successorTask,true,iCommCosts,iCompTaskMapping,iSimVarMapping);
  oReleaseTasks := tmpTask :: iReleaseTasks;
end addReleaseLocksToSchedule;

protected function addAssignLocksToSchedule "author: marcusw
  Add a assign lock to the schedule, assinging a lock from successor to iTask."
  input tuple<HpcOmSimCode.Task,Integer> iSuccessorTask;
  input HpcOmSimCode.Task iTask;
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  input list<HpcOmSimCode.Task> iReleaseTasks;
  output list<HpcOmSimCode.Task> oReleaseTasks;
protected
  HpcOmSimCode.Task tmpTask, successorTask;
algorithm
  (successorTask,_) := iSuccessorTask;
  tmpTask := createDepTaskAndCommunicationInfo(successorTask,iTask,false,iCommCosts,iCompTaskMapping,iSimVarMapping);
  oReleaseTasks := tmpTask :: iReleaseTasks;
end addAssignLocksToSchedule;

protected function getSimEqSysIdxForComp "
  Gets the simeqSys indexes for the given SCC index."
  input Integer compIdx;
  input array<list<Integer>> iSccSimEqMapping;
  output list<Integer> simEqSysIdcs;
algorithm
  simEqSysIdcs := arrayGet(iSccSimEqMapping,compIdx);
end getSimEqSysIdxForComp;

protected function getSimEqSysIdcsForCompLst "
  Gets a list of simeqSys indexes for the given list of SCC indexes."
  input list<Integer> compIdcs;
  input array<list<Integer>> iSccSimEqMapping;
  output list<Integer> simEqSysIdcs;
algorithm
  //print("compIdcs: \n"+stringDelimitList(List.map(compIdcs,intString),"\n")+"\n");
  simEqSysIdcs := List.flatten(List.map1(compIdcs,Array.getIndexFirst,iSccSimEqMapping));
  //print("simEqSysIdcs: \n"+stringDelimitList(List.map(simEqSysIdcs,intString),"\n")+"\n");
end getSimEqSysIdcsForCompLst;

public function getSimEqSysIdcsForNodeLst "
  Gets a list of simeqSys indexes for the given nodes (node = list of comps)."
  input list<list<Integer>> nodeIdcs;
  input array<list<Integer>> iSccSimEqMapping;
  output list<list<Integer>> simEqSysIdcsLst;
algorithm
  simEqSysIdcsLst := List.map1(nodeIdcs,getSimEqSysIdcsForCompLst,iSccSimEqMapping);
end getSimEqSysIdcsForNodeLst;

protected function getLocksByPredecessorList "author: marcusw
  Creates incoming dependencies between the given task (iTask) and all predecessor tasks."
  input HpcOmSimCode.Task iTask;                                 //The parent task
  input list<tuple<HpcOmSimCode.Task,Integer>> iPredecessorList; //All tasks with reference counter
  input Integer iThreadIdx;                                      //Thread handling task <%iTaskIdx%>
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  output list<HpcOmSimCode.Task> oLockTasks;
  output list<HpcOmSimCode.Task> oOutgoingDepTasks;
protected
  list<HpcOmSimCode.Task> tmpTaskList;
algorithm
  oLockTasks := List.fold(iPredecessorList, function getLockTasksByPredecessorList(iTask=iTask, iThreadIdx=iThreadIdx, iCommCosts=iCommCosts, iCompTaskMapping=iCompTaskMapping, iSimVarMapping=iSimVarMapping), {});
  oOutgoingDepTasks := oLockTasks;
end getLocksByPredecessorList;

protected function getLockTasksByPredecessorList "author: marcusw
  Append a incoming dependency between the given iTask and the predecessor task to the output-list if they are
  not handled by the same thread."
  input tuple<HpcOmSimCode.Task,Integer> iPredecessorTask;
  input HpcOmSimCode.Task iTask; //The parent task
  input Integer iThreadIdx; //Thread handling task <%iTaskIdx%>
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  input list<HpcOmSimCode.Task> iLockTasks;
  output list<HpcOmSimCode.Task> oLockTasks;
protected
  Integer threadIdx, predIndex, taskIndex;
  list<HpcOmSimCode.Task> tmpLockTasks;
  HpcOmSimCode.Task tmpTask, predTask;
algorithm
  oLockTasks := matchcontinue(iPredecessorTask,iTask,iThreadIdx,iCommCosts,iCompTaskMapping,iSimVarMapping,iLockTasks)
    case((predTask as HpcOmSimCode.CALCTASK(threadIdx=threadIdx,index=predIndex),_),HpcOmSimCode.CALCTASK(index=taskIndex),_,_,_,_,tmpLockTasks)
      equation
        true = intNe(iThreadIdx,threadIdx);
        //print("Adding a new lock for the tasks " + intString(iTaskIdx) + " " + intString(predIndex) + "\n");
        tmpTask = createDepTaskAndCommunicationInfo(predTask, iTask, false, iCommCosts, iCompTaskMapping, iSimVarMapping);
        //print("Because task " + intString(predIndex) + " is scheduled to " + intString(threadIdx) + "\n");
        tmpLockTasks = tmpTask::tmpLockTasks;
      then tmpLockTasks;
    else iLockTasks;
  end matchcontinue;
end getLockTasksByPredecessorList;

protected function getLockTasksByPredecessorListReverse
  input HpcOmSimCode.Task iTask; //The parent task
  input list<tuple<HpcOmSimCode.Task,Integer>> iPredecessorList;
  input Integer iThreadIdx; //Thread handling task <%iTaskIdx%>
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  output list<HpcOmSimCode.Task> oLockTasks;
  output list<HpcOmSimCode.Task> oOutgoingDepTasks;
algorithm
  oLockTasks := List.fold(iPredecessorList, function getLockTasksByPredecessorListReverse0(iTask=iTask, iThreadIdx=iThreadIdx, iCommCosts=iCommCosts, iCompTaskMapping=iCompTaskMapping, iSimVarMapping=iSimVarMapping), {});
  oOutgoingDepTasks := oLockTasks;
end getLockTasksByPredecessorListReverse;

protected function getLockTasksByPredecessorListReverse0
  input tuple<HpcOmSimCode.Task,Integer> iPredecessorTask;
  input HpcOmSimCode.Task iTask; //The parent task
  input Integer iThreadIdx; //Thread handling task <%iTaskIdx%>
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  input list<HpcOmSimCode.Task> iLockTasks;
  output list<HpcOmSimCode.Task> oLockTasks;
protected
  Integer index,threadIdx;
  HpcOmSimCode.Task predTask, tmpTask;
  list<HpcOmSimCode.Task> tmpLockTasks;
algorithm
  oLockTasks := matchcontinue(iPredecessorTask,iTask,iThreadIdx,iCommCosts,iCompTaskMapping,iSimVarMapping,iLockTasks)
    case((predTask as HpcOmSimCode.CALCTASK(threadIdx=threadIdx,index=index),_),_,_,_,_,_,_)
      equation
        true = intNe(iThreadIdx,threadIdx);
        //print("Adding a new lock for the tasks " + intString(iTaskIdx) + " " + intString(index) + "\n");
        //print("Because task " + intString(index) + " is scheduled to " + intString(threadIdx) + "\n");
        tmpTask = createDepTaskAndCommunicationInfo(iTask,predTask,true,iCommCosts,iCompTaskMapping,iSimVarMapping);
        tmpLockTasks = tmpTask :: iLockTasks;
      then tmpLockTasks;
    else iLockTasks;
  end matchcontinue;
end getLockTasksByPredecessorListReverse0;

protected function getCommunicationObjBetweenMergedTasks "author: Waurich TUD 2014-11
  Gets the communicationCosts between 2 merged tasks. This is the sum of all edges between the 2 nodes."
  input Integer parentNode;
  input Integer node;
  input array<list<Integer>> inComps;
  input array<HpcOmTaskGraph.Communications> inCommCosts;
  output HpcOmTaskGraph.Communication oCommunication;
protected
  list<Integer> nodeTasks, parentTasks;
  HpcOmTaskGraph.Communication commFold;
  HpcOmTaskGraph.Communications edgesFromParents;
algorithm
  nodeTasks := arrayGet(inComps,node);
  parentTasks := arrayGet(inComps,parentNode);
  commFold := HpcOmTaskGraph.COMMUNICATION(0,{},{},{},{},node,-1.0);
  edgesFromParents := List.flatten(List.map1(parentTasks,Array.getIndexFirst,inCommCosts));
  oCommunication := List.fold(edgesFromParents,function getCommunicationObjBetweenMergedTasks1(tasks=nodeTasks),commFold);
end getCommunicationObjBetweenMergedTasks;

protected function getCommunicationObjBetweenMergedTasks1 "author: Waurich TUD 2014-11
  Sums up the commCosts, for the edges between parent node and the tasks."
  input HpcOmTaskGraph.Communication  parentCommCost;
  input list<Integer> tasks;
  input HpcOmTaskGraph.Communication iCommunication;
  output HpcOmTaskGraph.Communication oCommunication;
algorithm
 oCommunication := matchcontinue(parentCommCost,tasks,iCommunication)
   local
    Integer nV1,nV2,childNode; //sum of {numOfIntegers,numOfFloats,numOfBoolean, numOfStrings}
    list<Integer> ints1,ints2,fl1,fl2,b1,b2,s1,s2;
    Real reqT1,reqT2;
   case(HpcOmTaskGraph.COMMUNICATION(nV1,ints1,fl1,b1,s1,childNode,reqT1),_,HpcOmTaskGraph.COMMUNICATION(nV2,ints2,fl2,b2,s2,_,reqT2))
     equation
       true = listMember(childNode,tasks);
     then HpcOmTaskGraph.COMMUNICATION(nV1+nV2,listAppend(ints1,ints2),listAppend(fl1,fl2),listAppend(b1,b2),listAppend(s1,s2),childNode,reqT1+reqT2);
   else iCommunication;
 end matchcontinue;
end getCommunicationObjBetweenMergedTasks1;

protected function convertCommunicationToCommInfo "author: marcusw
  Convert the given communication object of hpcomTaskGraph into a simcode-communicationinfo."
  input HpcOmTaskGraph.Communication iCommunication;
  input array<list<SimCodeVar.SimVar>> iSimVarMapping;
  output HpcOmSimCode.CommunicationInfo oCommInfo;
protected
  list<Integer> integerVars;
  list<Integer> floatVars;
  list<Integer> booleanVars;
  list<SimCodeVar.SimVar> intSimVars, floatSimVars, boolSimVars;
algorithm
  oCommInfo := match(iCommunication,iSimVarMapping)
    case(HpcOmTaskGraph.COMMUNICATION(integerVars=integerVars,floatVars=floatVars,booleanVars=booleanVars),_)
      equation
        intSimVars = List.fold1(integerVars, convertVarIdxToSimVar, iSimVarMapping, {});
        floatSimVars = List.fold1(floatVars, convertVarIdxToSimVar, iSimVarMapping, {});
        boolSimVars = List.fold1(booleanVars, convertVarIdxToSimVar, iSimVarMapping, {});
      then HpcOmSimCode.COMMUNICATION_INFO(floatSimVars,intSimVars,boolSimVars);
  end match;
end convertCommunicationToCommInfo;

protected function convertVarIdxToSimVar
  input Integer iVarIdx;
  input array<list<SimCodeVar.SimVar>> iSimVarMapping;
  input list<SimCodeVar.SimVar> iSimVar;
  output list<SimCodeVar.SimVar> oSimVar;
protected
  list<SimCodeVar.SimVar> tmpSimVars;
algorithm
  tmpSimVars := arrayGet(iSimVarMapping, iVarIdx);
  oSimVar := listAppend(iSimVar, tmpSimVars);
end convertVarIdxToSimVar;

protected function createDepTask "author: marcusw
  Create a dependency task that indicates that variables of another task are required."
  input HpcOmSimCode.Task iSourceTask;
  input HpcOmSimCode.Task iTargetTask;
  input Boolean iOutgoing; //true if lock should released, false if lock should assigned
  input HpcOmSimCode.CommunicationInfo commInfo;
  output HpcOmSimCode.Task oAssignTask;
algorithm
  oAssignTask := HpcOmSimCode.DEPTASK(iSourceTask,iTargetTask,iOutgoing,0,commInfo);
end createDepTask;

protected function createDepTaskAndCommunicationInfo "author: marcusw
  Create a dependency task that indicates that variables of another task are required.
  The communication info is created out of the given communication array and the simvar-mapping."
  input HpcOmSimCode.Task iSourceTask;
  input HpcOmSimCode.Task iTargetTask;
  input Boolean iOutgoing; //true if lock should released, false if lock should assigned
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  output HpcOmSimCode.Task oAssignTask;
protected
  Integer predIndex, taskIndex;
  HpcOmSimCode.Task tmpTask;
  HpcOmTaskGraph.Communication commBetweenTasks;
  HpcOmSimCode.CommunicationInfo commInfo;
algorithm
  oAssignTask := matchcontinue(iSourceTask,iTargetTask,iOutgoing,iCommCosts,iCompTaskMapping,iSimVarMapping)
    case(HpcOmSimCode.CALCTASK(index=predIndex),HpcOmSimCode.CALCTASK(index=taskIndex),_,_,_,_)
      equation
        //print("createDepTaskAndCommunicationInfo: Creating dependency (outgoing=" + boolString(iOutgoing) + ") between " + intString(predIndex) + " and " + intString(taskIndex) + "\n");
        commBetweenTasks = getCommunicationObjBetweenMergedTasks(predIndex,taskIndex,iCompTaskMapping,iCommCosts);
        commInfo = convertCommunicationToCommInfo(commBetweenTasks, iSimVarMapping);
        tmpTask = createDepTask(iSourceTask, iTargetTask, iOutgoing, commInfo);
      then tmpTask;
    /*case(HpcOmSimCode.CALCTASK(index=predIndex),HpcOmSimCode.CALCTASK(index=taskIndex),false,_,_,_)
      equation
        //print("predIndex"+intString(predIndex)+"\n");
        //print("taskIndex"+intString(taskIndex)+"\n");
        commBetweenTasks = getCommunicationObjBetweenMergedTasks(predIndex,taskIndex,iCompTaskMapping,iCommCosts);
        commInfo = convertCommunicationToCommInfo(commBetweenTasks, iSimVarMapping);
        tmpTask = createDepTask(iSourceTask, iTargetTask, false, commInfo);
      then tmpTask; */
    else
      equation
        print("CreateDepTaskAndCommunicationInfo failed!\n");
      then fail();
  end matchcontinue;
end createDepTaskAndCommunicationInfo;

protected function createDepTaskByTaskIdc "author: marcusw
  Create a dependency task that indicates that variables of another task are required or calculated. The
  source and target tasks are taken from the all-tasks-array."
  input Integer iSourceTaskIdx;
  input Integer iTargetTaskIdx;
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllCalcTasks; //all tasks with ref counter
  input Boolean iOutgoing; //true if lock should released, false if lock should assigned
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  output HpcOmSimCode.Task oAssignTask;
protected
  HpcOmSimCode.Task sourceTask, targetTask;
algorithm
  sourceTask := Util.tuple21(arrayGet(iAllCalcTasks, iSourceTaskIdx));
  targetTask := Util.tuple21(arrayGet(iAllCalcTasks, iTargetTaskIdx));
  oAssignTask := createDepTaskAndCommunicationInfo(sourceTask, targetTask, iOutgoing, iCommCosts, iCompTaskMapping, iSimVarMapping);
end createDepTaskByTaskIdc;

protected function createDepTaskByTaskIdcR "author: marcusw
  Create a dependency task that indicates that variables of another task are required or calculated. The
  source and target tasks are taken from the all-tasks-array. Additionally, this
  is the revered edition of createOutgoingDummyDepTask, which means that the dependency is
  leading from target to source."
  input Integer iSourceTaskIdx;
  input Integer iTargetTaskIdx;
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllCalcTasks; //all tasks with ref counter
  input Boolean iOutgoing; //true if lock should released, false if lock should assigned
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  output HpcOmSimCode.Task oAssignTask;
algorithm
  oAssignTask := createDepTaskByTaskIdc(iTargetTaskIdx,iSourceTaskIdx,iAllCalcTasks,iOutgoing,iCommCosts,iCompTaskMapping,iSimVarMapping);
end createDepTaskByTaskIdcR;

protected function updateRefCounterBySuccessorIdc "author: marcusw
  Decrement the ref-counter off all tasks in the successor-list. If the new ref-counter is 0, the task
  will be appended to the second return argument."
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllCalcTasks; //all tasks with ref-counter
  input list<Integer> iSuccessorIdc;
  input list<HpcOmSimCode.Task> iRefZeroTasks;
  output array<tuple<HpcOmSimCode.Task,Integer>> oAllCalcTasks;
  output list<HpcOmSimCode.Task> oRefZeroTasks; //Tasks with new ref-counter = 0
protected
  Integer head, currentRefCount;
  list<Integer> rest;
  list<HpcOmSimCode.Task> tmpRefZeroTasks;
  HpcOmSimCode.Task currentTask;
  array<tuple<HpcOmSimCode.Task,Integer>> tmpAllCalcTasks;

algorithm
  (oAllCalcTasks,oRefZeroTasks) := matchcontinue(iAllCalcTasks,iSuccessorIdc,iRefZeroTasks)
    case(_,head::rest,_)
      equation
        ((currentTask,currentRefCount)) = arrayGet(iAllCalcTasks,head);
        //print("\tTask " + intString(head) + " has ref-counter of " + intString(currentRefCount) + "\n");
        true = intEq(currentRefCount,1); //Task-refcounter = 0
        tmpAllCalcTasks = arrayUpdate(iAllCalcTasks,head,(currentTask,0));
        tmpRefZeroTasks = currentTask :: iRefZeroTasks;
        (tmpAllCalcTasks,tmpRefZeroTasks) = updateRefCounterBySuccessorIdc(tmpAllCalcTasks,rest,tmpRefZeroTasks);
      then (tmpAllCalcTasks,tmpRefZeroTasks);
    case(_,head::rest,_)
      equation
        ((currentTask,currentRefCount)) = arrayGet(iAllCalcTasks,head); //Task-refcounter != 0
        tmpAllCalcTasks = arrayUpdate(iAllCalcTasks,head,(currentTask,currentRefCount-1));
        (tmpAllCalcTasks,tmpRefZeroTasks) = updateRefCounterBySuccessorIdc(tmpAllCalcTasks,rest,iRefZeroTasks);
      then (tmpAllCalcTasks,tmpRefZeroTasks);
    else (iAllCalcTasks,iRefZeroTasks);
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

protected function getTaskWithHighestFinishTime "author: marcusw
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

protected function convertTaskGraphToTasks "author: marcusw
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

protected function convertTaskGraphToTasks1 "author: marcusw
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
        newTask = iConverterFunc(iIndex, iTaskGraphMeta);
        tmpTasks = arrayUpdate(iTasks, iIndex, (newTask,refCount));
        tmpTasks = convertTaskGraphToTasks1(iTaskGraphMeta,iTaskGraphT,iIndex+1,iConverterFunc,tmpTasks);
      then tmpTasks;
    else iTasks;
  end matchcontinue;
end convertTaskGraphToTasks1;

protected function convertNodeToTask "author: marcusw
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

protected function convertNodeToTaskReverse "author: marcusw
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
  input array<HpcOmTaskGraph.Communications> iCommCosts;
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
  input array<HpcOmTaskGraph.Communications> iCommCosts;
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
  input array<HpcOmTaskGraph.Communications> iCommCosts;
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

protected function getMaxCommCostsByTaskList "author: marcusw
  Get the required time of the highest communication from parent to the childs referenced in iTaskList."
  input HpcOmSimCode.Task iParentTask;
  input list<tuple<HpcOmSimCode.Task,Integer>> iTaskList;
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  output Real oCommCost;
algorithm
  oCommCost := List.fold2(iTaskList, getMaxCommCostsByTaskList1, iParentTask, iCommCosts, 0.0);
end getMaxCommCostsByTaskList;

protected function getMaxCommCostsByTaskList1 "author: marcusw
  Check if the communication from parent to the given task (iTask) is higher than the current maximum.
  If there is an edge between the nodes and it has an higher required time, then the output
  value is updated. Otherwise the function returns the current maximum."
  input tuple<HpcOmSimCode.Task,Integer> iTask;
  input HpcOmSimCode.Task iParentTask;
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input Real iCurrentMax;
  output Real oCommCost;
protected
  Integer taskIdx;
  Real reqCycles;
  list<Integer> eqIdc, parentEqIdc;
  HpcOmTaskGraph.Communications childCommCosts;
algorithm
  oCommCost := matchcontinue(iTask, iParentTask, iCommCosts, iCurrentMax)
    case((HpcOmSimCode.CALCTASK(index=taskIdx,eqIdc=eqIdc),_),HpcOmSimCode.CALCTASK(eqIdc=parentEqIdc),_,_)
      equation
        //print("Try to find edge cost from scc " + intString(listHead(eqIdc)) + " to scc " + intString(listHead(parentEqIdc)) + "\n");
        childCommCosts = arrayGet(iCommCosts,listHead(eqIdc));
        HpcOmTaskGraph.COMMUNICATION(requiredTime=reqCycles) = getMaxCommCostsByTaskList2(childCommCosts, listHead(parentEqIdc));
        true = realGt(reqCycles, iCurrentMax);
      then reqCycles;
    else iCurrentMax;
  end matchcontinue;
end getMaxCommCostsByTaskList1;

protected function getMaxCommCostsByTaskList2 "author: marcusw"
  input HpcOmTaskGraph.Communications iCommCosts;
  input Integer iIdx; //Scc idx
  output HpcOmTaskGraph.Communication oComm;
protected
  Integer childIdxHead;
  HpcOmTaskGraph.Communications tail;
  HpcOmTaskGraph.Communication head;
algorithm
  oComm := matchcontinue(iCommCosts, iIdx)
    case((head as HpcOmTaskGraph.COMMUNICATION(childNode=childIdxHead))::tail, _)
      equation
        true = intEq(childIdxHead,iIdx);
      then head;
    case(_::tail, _) then getMaxCommCostsByTaskList2(tail, iIdx);
    else
      equation
        print("HpcOmScheduler.getMaxCommCostsByTaskList2 failed\n");
      then fail();
  end matchcontinue;
end getMaxCommCostsByTaskList2;

protected function getTaskByIndex
  input Integer iTaskIdx;
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllCalcTasks;
  output tuple<HpcOmSimCode.Task,Integer> oTask;
algorithm
  oTask := arrayGet(iAllCalcTasks,iTaskIdx);
end getTaskByIndex;

public function getSuccessorsByTask "author: marcusw
  Get all successor tasks of the given calc-task."
  input HpcOmSimCode.Task iTask; //the task of type CALCTASK
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllCalcTasks; //all calc tasks of the scheduler (with reference counter)
  output list<tuple<HpcOmSimCode.Task,Integer>> oTasks; //all successor tasks (with reference counter)
  output list<Integer> oTaskIdc; // all successor tasks as indices
protected
  Integer taskIdx;
  list<Integer> successors;
  list<tuple<HpcOmSimCode.Task,Integer>> tmpTasks;
algorithm
  (oTasks, oTaskIdc) := matchcontinue(iTask,iTaskGraph,iAllCalcTasks)
    case(HpcOmSimCode.CALCTASK(index=taskIdx),_,_)
      equation
        successors = arrayGet(iTaskGraph,taskIdx);
        tmpTasks = List.map1(successors, getTaskByIndex, iAllCalcTasks);
      then (tmpTasks, successors);
    else
      equation
        print("HpcOmScheduler.getSuccessorsByTask can only handle CALCTASKs.");
      then fail();
  end matchcontinue;
end getSuccessorsByTask;

protected function compareTasksByWeighting "author: marcusw
  Compare the given tasks by their weighting. Return true if task1 has a higher weighting than task2."
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
        Error.addMessage(Error.INTERNAL_ERROR, {"HpcOmScheduler.compareTasksByWeighting can only compare CALCTASKs! Task 1 has type " + getTaskTypeString(iTask1) + " and task 2 has type " + getTaskTypeString(iTask2)});
      then fail();
  end match;
end compareTasksByWeighting;

protected function compareTasksByEqIdc "author: marcusw
  Compare the given tasks by their equation indices. If the last equation of task1 has a higher index than the last equation of task 2, true is returned."
  input HpcOmSimCode.Task iTask1;
  input HpcOmSimCode.Task iTask2;
  output Boolean oResult;
protected
  list<Integer> eqIdcTask1, eqIdcTask2;
algorithm
  oResult := match(iTask1,iTask2)
    case(HpcOmSimCode.CALCTASK(eqIdc=eqIdcTask1), HpcOmSimCode.CALCTASK(eqIdc=eqIdcTask2))
      then intGt(List.last(eqIdcTask1),List.last(eqIdcTask2));
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"HpcOmScheduler.compareTasksByEqIdc can only compare CALCTASKs with at least one equation index! Task 1 has type " + getTaskTypeString(iTask1) + " and task 2 has type " + getTaskTypeString(iTask2)});
      then fail();
  end match;
end compareTasksByEqIdc;

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

protected function dumpThreadSchedule
  input list<HpcOmSimCode.Task> iTaskList;
  input Integer iThreadIdx;
  output String str;
  output Integer oThreadIdx;
algorithm
  str := "--------------\n";
  str := str + "Thread " + intString(iThreadIdx) + "\n";
  str := str +"--------------\n";
  str := str + dumpTaskList(iTaskList);
  oThreadIdx := iThreadIdx+1;
end dumpThreadSchedule;

protected function dumpTaskDepSchedule
  input tuple<HpcOmSimCode.Task,list<Integer>> iTaskInfo;
  output String str;
protected
  String s;
  HpcOmSimCode.Task iTask;
  list<Integer> iDependencies;
algorithm
  (iTask,iDependencies) := iTaskInfo;
  s := "Task: \n";
  s := s + dumpTask(iTask) + "\n";
  s := s + "-> Parents: " + stringDelimitList(List.map(iDependencies,intString),",") + "\n";
  str := s + "---------------------\n";
end dumpTaskDepSchedule;

protected function printTaskList "
  Printing the given list of tasks using the dumpTaskList function."
  input list<HpcOmSimCode.Task> iTaskList;
algorithm
  print(dumpTaskList(iTaskList));
end printTaskList;

protected function dumpTaskList
  input list<HpcOmSimCode.Task> iTaskList;
  output String str;
algorithm
  str := stringDelimitList(List.map(iTaskList,dumpTask),"");
end dumpTaskList;

protected function dumpTask
  input HpcOmSimCode.Task iTask;
  output String oString;
protected
  Integer weighting, index, threadIdx, compIdx, numThreads, sourceIndex, targetIndex;
  list<Integer> eqIdc, nodeIdc;
  Real calcTime, timeFinished;
  String lockId, s;
  HpcOmSimCode.Schedule taskSchedule;
  Boolean outgoing;
  Integer threadIdx;
algorithm
  oString := match(iTask)
    case(HpcOmSimCode.SCHEDULED_TASK(compIdx=compIdx,numThreads=numThreads,taskSchedule=taskSchedule))
      equation
      s = "Scheduled Task (comp: "+intString(compIdx)+", numThreads: "+intString(numThreads)+"):\n------------------------------------------------------\n";
      s = s +"\t"+ System.stringReplace(dumpSchedule(taskSchedule),"\n","\n\t");
      s = s + "------------------------------------------------------\n";
      then s;
    case(HpcOmSimCode.CALCTASK(weighting=weighting,timeFinished=timeFinished, index=index, eqIdc=eqIdc))
      then ("Calculation task with index " + intString(index) + " including the equations: "+stringDelimitList(List.map(eqIdc,intString),", ")+ " is finished at  " + realString(timeFinished) + "\n");
    case(HpcOmSimCode.CALCTASK_LEVEL(eqIdc=eqIdc, nodeIdc=nodeIdc, threadIdx=NONE()))
      then ("Calculation task ("+stringDelimitList(List.map(nodeIdc,intString),", ")+") including the equations: "+stringDelimitList(List.map(eqIdc,intString),", ")+"\n");
    case(HpcOmSimCode.CALCTASK_LEVEL(eqIdc=eqIdc, nodeIdc=nodeIdc, threadIdx=SOME(threadIdx)))
      then ("Calculation task ("+stringDelimitList(List.map(nodeIdc,intString),", ")+") including the equations: "+stringDelimitList(List.map(eqIdc,intString),", ")+" by thread " + intString(threadIdx) + "\n");
    case(HpcOmSimCode.DEPTASK(sourceTask=HpcOmSimCode.CALCTASK(index=sourceIndex), targetTask=HpcOmSimCode.CALCTASK(index=targetIndex),outgoing=outgoing))
      equation
        s = "Dependency task ";
        s = s + (if outgoing then "(outgoing)" else "(incoming)");
        s = s + " between " + intString(sourceIndex) + " and " + intString(targetIndex) + "\n";
      then s;
    case(HpcOmSimCode.TASKEMPTY())
      then "empty task\n";
    else
      equation
        print("HpcOmScheduler.dumpTask failed\n");
      then fail();
  end match;
end dumpTask;

public function printTask
  input HpcOmSimCode.Task iTask;
algorithm
  print(dumpTask(iTask));
end printTask;

public function convertScheduleStrucToInfo "author: marcusw
  Convert the given schedule-information into an node-array of information."
  input HpcOmSimCode.Schedule iSchedule;
  input Integer iTaskCount;
  output array<tuple<Integer,Integer,Real>> oScheduleInfo; //for threadScheduling: array which contains <threadId,taskNumber,finishTime> for each node (index)
                                                           //for levelScheduling: array which contains <sectionIdx.,sectionsNumber,finishTime> for each node (index)
protected
  array<tuple<Integer,Integer,Real>> tmpScheduleInfo;
  array<list<HpcOmSimCode.Task>> threadTasks;
  list<HpcOmSimCode.TaskList> tasksOfLevels;
  list<HpcOmSimCode.Task> allTasks;
algorithm
  oScheduleInfo := match(iSchedule,iTaskCount)
    case(HpcOmSimCode.EMPTYSCHEDULE(tasks=HpcOmSimCode.SERIALTASKLIST(tasks=allTasks)),_)
      equation
        tmpScheduleInfo = arrayCreate(iTaskCount,(-1,-1,-1.0));
        threadTasks=arrayCreate(1, allTasks);
        tmpScheduleInfo = Array.fold(threadTasks,convertScheduleStrucToInfo0,tmpScheduleInfo);
      then tmpScheduleInfo;
    case(HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks),_)
      equation
        tmpScheduleInfo = arrayCreate(iTaskCount,(-1,-1,-1.0));
        tmpScheduleInfo = Array.fold(threadTasks,convertScheduleStrucToInfo0,tmpScheduleInfo);
      then tmpScheduleInfo;
    case(HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevels),_)
      equation
        tmpScheduleInfo = arrayCreate(iTaskCount,(-1,-1,-1.0));
        tmpScheduleInfo = convertScheduleStrucToInfoLevel(tasksOfLevels,1,tmpScheduleInfo);
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
  Convert the given task list into an node-array of information."
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
    case (HpcOmSimCode.DEPTASK(),_) then iScheduleInfo;
    else
      equation
        print("HpcOmScheduler.convertScheduleStrucToInfo1 failed. Unknown Task-Type.\n");
      then fail();
  end match;
end convertScheduleStrucToInfo1;

protected function convertScheduleStrucToInfoLevel "author: marcusw
  Convert the given task list, representing a level of the level-scheduler, to a scheduler info."
  input list<HpcOmSimCode.TaskList> taskLst;
  input Integer sectionsNumber;
  input array<tuple<Integer,Integer,Real>> iScheduleInfo; //maps each Task to <threadId, orderId, startCalcTime>
  output array<tuple<Integer,Integer,Real>> oScheduleInfo;
algorithm
  oScheduleInfo := matchcontinue(taskLst,sectionsNumber,iScheduleInfo)
    local
      array<tuple<Integer,Integer,Real>> scheduleInfo;
      list<HpcOmSimCode.Task> tasks;
      list<HpcOmSimCode.TaskList> rest;
    case({},_,_)
      then iScheduleInfo;
    case(HpcOmSimCode.PARALLELTASKLIST(tasks=tasks)::rest,_,_)
      equation
        scheduleInfo = convertScheduleStrucToInfoLevel1(tasks,sectionsNumber,1,iScheduleInfo);
      then convertScheduleStrucToInfoLevel(rest,sectionsNumber+1,scheduleInfo);
    case(HpcOmSimCode.SERIALTASKLIST(tasks=tasks)::rest,_,_)
      equation
        scheduleInfo = convertScheduleStrucToInfoLevel1(tasks,sectionsNumber,1,iScheduleInfo);
      then convertScheduleStrucToInfoLevel(rest,sectionsNumber+1,scheduleInfo);
    else
    equation
      print("convertScheduleStrucToInfoLevel failed\n");
    then fail();
  end matchcontinue;
end convertScheduleStrucToInfoLevel;

protected function convertScheduleStrucToInfoLevel1
  input list<HpcOmSimCode.Task> tasks;
  input Integer sectionsNumber;
  input Integer sectionIdx;
  input array<tuple<Integer,Integer,Real>> iScheduleInfo; //maps each Task to <threadId, orderId, startCalcTime>
  output array<tuple<Integer,Integer,Real>> oScheduleInfo;
algorithm
  oScheduleInfo := match(tasks,sectionsNumber,sectionIdx,iScheduleInfo)
    local
      Integer numNodes, threadIdx;
      list<Integer> nodeIdc;
      array<tuple<Integer,Integer,Real>> scheduleInfo;
      list<tuple<Integer,Integer,Real>> tuplLst;
      list<HpcOmSimCode.Task> rest;
      Option<Integer> threadIdxOpt;
    case({},_,_,_)
      then iScheduleInfo;
    case(HpcOmSimCode.CALCTASK_LEVEL(nodeIdc=nodeIdc,threadIdx=threadIdxOpt)::rest,_,_,_)
      equation
        numNodes = listLength(nodeIdc);
        threadIdx = Util.getOptionOrDefault(threadIdxOpt,-1);
        tuplLst = List.threadMap1(List.fill(threadIdx,numNodes),List.fill(-1,numNodes),Util.make3Tuple,0.0);
        List.threadMap1_0(nodeIdc,tuplLst,Array.updateIndexFirst,iScheduleInfo);
      then convertScheduleStrucToInfoLevel1(rest,sectionsNumber,sectionIdx+1,iScheduleInfo);
  end match;
end convertScheduleStrucToInfoLevel1;


//-----------------
// Balanced Level Scheduling
//-----------------
public function createBalancedLevelScheduling "author: waurich TUD
  Creates a balanced level scheduling for the given graph."
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
  array<String> compNames, compDescs;
  array<tuple<Integer,Real>> exeCosts;
  array<HpcOmTaskGraph.Communications> commCosts;
  array<list<Integer>> compParamMapping;
  array<HpcOmTaskGraph.ComponentInfo> compInformations;
algorithm
  targetCost := 1000.0;
  HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps) := iMeta;
  graphT := AdjacencyMatrix.transposeAdjacencyMatrix(iGraph,arrayLength(iGraph));

  // assign initial level
  //(_,startNodes) := List.filterOnTrueSync(arrayList(graphT),listEmpty,List.intRange(arrayLength(graphT)));
  //level := getGraphLevel(iGraph,{startNodes});
  level := HpcOmTaskGraph.getLevelNodes(iGraph);
  levelAss := arrayCreate(arrayLength(inComps),-1);
  ((_,levelAss)) := List.fold(level,getLevelAssignment,(1,levelAss));
    //print("level: \n"+stringDelimitList(List.map(level,intListString),"\n")+"\n");

  // get critical path and merge the criPathNodes to target size tasks
  (_,(critPathNodes::_,_)) := HpcOmTaskGraph.getCriticalPaths(iGraph,iMeta);  // without communication costs
  critPathCosts := List.map1(critPathNodes,HpcOmTaskGraph.getExeCostReqCycles,iMeta);
    //print("critPathNodes: \n"+stringDelimitList(List.map(critPathNodes,intString)," \n ")+"\n");

  //try to fill the parallel sections
  allSections := BLS_fillParallelSections(level,levelAss,critPathNodes,1,targetCost,iGraph,graphT,iMeta,{},{});
    //print("allSections1: \n"+stringDelimitList(List.map(allSections,intListListString)," \n ")+"\n");
  allSections := List.map2(allSections,BLS_mergeSmallSections,iMeta,targetCost);
    //print("allSections2: \n"+stringDelimitList(List.map(allSections,intListListString)," \n ")+"\n");

  //generate schedule
  levelTasks := List.map2(allSections,BLS_generateSchedule,iMeta,iSccSimEqMapping);
  oSchedule := HpcOmSimCode.LEVELSCHEDULE(levelTasks, false);

  //update nodeMark for graphml representation
  HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps, varCompMapping=varCompMapping, eqCompMapping=eqCompMapping, compParamMapping=compParamMapping, compNames=compNames, compDescs=compDescs, exeCosts=exeCosts, commCosts=commCosts, compInformations=compInformations) := iMeta;
  nodeMark := arrayCreate(arrayLength(inComps),-1);
  level := List.map(allSections,List.flatten);
  ((_,nodeMark)) := List.fold(level,getLevelAssignment,(1,nodeMark));
  oMeta := HpcOmTaskGraph.TASKGRAPHMETA(inComps,varCompMapping,eqCompMapping,compParamMapping,compNames,compDescs,exeCosts,commCosts,nodeMark, compInformations);
end createBalancedLevelScheduling;

protected function BLS_mergeSmallSections "author: Waurich TUD 2014-07
  Traverses the sections in a level and merges them if they are to small."
  input list<list<Integer>> sectionsIn;
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  input Real targetCosts;
  output list<list<Integer>> sectionsOut;
algorithm
sectionsOut := match(sectionsIn,iMeta,targetCosts)
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
  end match;
end BLS_mergeSmallSections;

protected function BLS_generateSchedule "author: Waurich TUD 2014-07
  Generates a level schedule for the given levels. if a level contains only one section build a serial task.
  All simEqSys indexes are sorted according to their idx."
  input list<list<Integer>> level;
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  input array<list<Integer>> iSccSimEqMapping;
  output HpcOmSimCode.TaskList taskLstOut;
algorithm
  taskLstOut := matchcontinue(level,iMeta,iSccSimEqMapping)
    local
      list<Integer> section, compLst;
      list<list<Integer>> sections;
      array<list<Integer>> inComps;
      HpcOmSimCode.Task task;
      HpcOmSimCode.TaskList taskLst;
    case({section},HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps),_)
      equation
        // generate a serial section
        _ = List.flatten(List.map1(section,Array.getIndexFirst,inComps));
        //simEqSysIdcs = List.sort(simEqSysIdcs,intGt);
        task = makeCalcTaskLevel(section,inComps,iSccSimEqMapping);
        taskLst = HpcOmSimCode.SERIALTASKLIST({task}, true);
    then taskLst;
    case(_::_,HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps),_)
      equation
        // generate parallel sections
        //sectionSimEqSysIdcs = List.map1(sectionSimEqSysIdcs,List.sort,intGt);
        taskLst = makeCalcLevelParTaskLstForMergedNodes(level,iSccSimEqMapping,inComps);
    then taskLst;
  end matchcontinue;
end BLS_generateSchedule;

protected function BLS_fillParallelSections "author: Waurich TUD 2014-07
  Cluster the tasks from the level, beginning with the critical path node. If this node is to small, merge only necessary
  nodes to compute the next level critical path node. if the node is big enough gather all level nodes and unassigned nodes
  in this level."
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
      list<list<Integer>> level, levelNodeCluster, levelNodeChildren, followingLevel;
      list<list<list<Integer>>> sectionLst;
      list<Real> necPredCosts,levelNodeClusterCosts,                       levelNodeCosts;
    case(_,_,{},_,_,_,_,_,_,_)
      equation
        //print("done\n");
    then listReverse(sectionsIn);
    case(_,_,critPathNode::{},_,_,_,_,_,_,_)
      equation
        _ = HpcOmTaskGraph.getExeCostReqCycles(critPathNode,iMeta);
        critNodeLevel = arrayGet(levelAssIn,critPathNode);
        //print("critPathNode (last): \n"+intString(critPathNode)+" of level: "+intString(critNodeLevel)+"\n");

        // the last level: build the section, collect unassigned nodes and level nodes and put everything in this section
        //levelNodes = List.flatten(List.map1(List.intRange2(levelIdx,critNodeLevel),List.getIndexFirst,levelIn));
        critNodeLevel = intMin(levelIdx,critNodeLevel);
        (_,followingLevel) =  List.split(levelIn,critNodeLevel-1);
        levelNodes = List.flatten(followingLevel);
          //print("levelNodes: \n"+stringDelimitList(List.map(levelNodes,intString)," ; ")+"\n");

        unassNodes = listAppend(levelNodes,unassNodesIn);
        levelNodeCluster = BLS_mergeDependentLevelTask(unassNodes,iGraph,iGraphT,{});
          //print("section: \n"+stringDelimitList(List.map(levelNodeCluster,intListString),"  |  ")+"\n");
        sectionLst = levelNodeCluster::sectionsIn;
        sectionLst = BLS_fillParallelSections(levelIn,levelAssIn,{},critNodeLevel+1,targetCosts,iGraph,iGraphT,iMeta,unassNodes,sectionLst);
      then sectionLst;
    case(_,_,critPathNode::restCritNodes,_,_,_,_,_,_,_)
      equation
        critPathCost = HpcOmTaskGraph.getExeCostReqCycles(critPathNode,iMeta);
        critNodeLevel = arrayGet(levelAssIn,critPathNode);

        // the critical path node in this section is to SMALL, gather as few as possible nodes in this level (onyl the necessary ones)
        true = critPathCost < targetCosts;
          //print("critPathNode (small): \n"+intString(critPathNode)+" of level: "+intString(critNodeLevel)+"\n");

        // get the nodes that are necessary to compute the next critical path node, collect unassigned
        levelNodes = List.flatten(List.map1(List.intRange2(levelIdx,critNodeLevel),List.getIndexFirst,levelIn));
        levelNodes = List.deleteMember(levelNodes,critPathNode);
          //print("levelNodes: \n"+stringDelimitList(List.map(levelNodes,intString)," ; ")+"\n");
        necessaryPredecessors = arrayGet(iGraphT,listHead(restCritNodes));
          //print("necessaryPredecessors: "+stringDelimitList(List.map(necessaryPredecessors,intString)," ; ")+"\n");
        unassNodes = listAppend(levelNodes,unassNodesIn);  // to check for unassNodesIn
          //print("unassNodes: \n"+stringDelimitList(List.map(unassNodes,intString)," ; ")+"\n");
        necessaryPredecessors = List.flatten(List.map4(List.map(necessaryPredecessors,List.create),BLS_getDependentGroups,iGraph,iGraphT,unassNodes,{}));  // get all unassigned dependents for the necessary predecessors
        necessaryPredecessors = List.unique(necessaryPredecessors);
        (necessaryPredecessors,_,unassNodes) = List.intersection1OnTrue(necessaryPredecessors,unassNodes,intEq);

        // build the section
        section = critPathNode::necessaryPredecessors;
        section = List.unique(section);
        sectionLst = {section}::sectionsIn;
          //print("section: \n"+stringDelimitList(List.map(section,intString),"  ,  ")+"\n");

        // update levelAss and levelIn
        List.map2_0(section,Array.updateIndexFirst,critNodeLevel,levelAssIn);
        level = List.map1(levelIn,deleteIntListMembers,section);
        level = List.set(level,critNodeLevel,section);
          //print("level: \n"+stringDelimitList(List.map(level,intListString),"\n")+"\n");

        sectionLst = BLS_fillParallelSections(level,levelAssIn,restCritNodes,critNodeLevel+1,targetCosts,iGraph,iGraphT,iMeta,unassNodes,sectionLst);
      then sectionLst;
    case(_,_,critPathNode::restCritNodes,_,_,_,_,_,_,_)
      equation
        critPathCost = HpcOmTaskGraph.getExeCostReqCycles(critPathNode,iMeta);
        critNodeLevel = arrayGet(levelAssIn,critPathNode);

        // the critical path node in this section is BIG enough, gather as much as possible nodes in this level
        true = critPathCost >= targetCosts;
        _ = Flags.getConfigInt(Flags.NUM_PROC);
          //print("critPathNode (big): \n"+intString(critPathNode)+" of level: "+intString(critNodeLevel)+"\n");

        // get the nodes that are necessary to compute the next critical path node
        levelNodes = List.flatten(List.map1(List.intRange2(levelIdx,critNodeLevel),List.getIndexFirst,levelIn));
        (levelNodes,_) = List.deleteMemberOnTrue(critPathNode,levelNodes,intEq);
        _ = arrayGet(iGraphT,listHead(restCritNodes));
          //print("necessaryPredecessors: \n"+stringDelimitList(List.map(necessaryPredecessors,intString)," ; ")+"\n");

        // use the unassigned nodes first to fill the sections
        unassNodes = listAppend(unassNodesIn,levelNodes);
          //print("unassNodes: \n"+stringDelimitList(List.map(unassNodes,intString)," ; ")+"\n");
        unassNodes = critPathNode::unassNodes;
        unassNodes = List.unique(unassNodes);
        levelNodeCluster = BLS_mergeDependentLevelTask(unassNodes,iGraph,iGraphT,{});
        (_,unassNodes,_) = List.intersection1OnTrue(unassNodes,List.flatten(levelNodeCluster),intEq);
        sectionLst = levelNodeCluster::sectionsIn;
          //print("section: \n"+stringDelimitList(List.map(levelNodeCluster,intListString),"  |  ")+"\n");

        // update levelAss and levelIn
        List.map2_0(List.flatten(levelNodeCluster),Array.updateIndexFirst,critNodeLevel,levelAssIn);
        level = List.map1(levelIn,deleteIntListMembers,List.flatten(levelNodeCluster));
        level = List.set(level,critNodeLevel,List.flatten(levelNodeCluster));
          //print("level: \n"+stringDelimitList(List.map(level,intListString),"\n")+"\n");

        sectionLst = BLS_fillParallelSections(level,levelAssIn,restCritNodes,critNodeLevel+1,targetCosts,iGraph,iGraphT,iMeta,{},sectionLst);
      then sectionLst;
  end matchcontinue;
end BLS_fillParallelSections;

protected function BLS_mergeDependentLevelTask "author:Waurich TUD 2014-07
  Gathers nodes in merged level according to their dependencies. Successors and predecessors have to be collected
  in one section."
  input list<Integer> nodesIn;
  input HpcOmTaskGraph.TaskGraph iGraph;
  input HpcOmTaskGraph.TaskGraph iGraphT;
  input list<list<Integer>> sectionsIn;
  output list<list<Integer>> sectionsOut;
algorithm
  sectionsOut := match(nodesIn,iGraph,iGraphT,sectionsIn)
    local
      Integer node;
      list<Integer> rest,dependentNodes,section;
      list<list<Integer>> sections;
  case({},_,_,_)
    equation
    then listReverse(sectionsIn);
  case(node::rest,_,_,_)
    equation
      //print("node: "+intString(node)+"\n");
      dependentNodes = BLS_getDependentGroups({node},iGraph,iGraphT,nodesIn,{});
      section = node::dependentNodes;
      section = List.unique(section);
      (_,rest,_) = List.intersection1OnTrue(rest,dependentNodes,intEq);
      section = listReverse(section);
      //print("section: \n"+stringDelimitList(List.map(section,intString)," ; ")+"\n");
      sections = BLS_mergeDependentLevelTask(rest,iGraph,iGraphT,section::sectionsIn);
    then sections;
  end match;
end BLS_mergeDependentLevelTask;

protected function BLS_getDependentGroups "author: Waurich TUD 2014-07
  Gathers the dependent successors and predecessors among all referenceNodes for the given task."
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
      //print("node: "+intString(node)+"\n");
      successors = arrayGet(iGraph,node);
      predecessors = arrayGet(iGraphT,node);
      //print("successors: \n"+stringDelimitList(List.map(successors,intString)," ; ")+"\n");
      //print("predecessors: \n"+stringDelimitList(List.map(predecessors,intString)," ; ")+"\n");
      (successors,_,referenceNodes) = List.intersection1OnTrue(successors,referenceNodesIn,intEq);
      (predecessors,_,referenceNodes) = List.intersection1OnTrue(predecessors,referenceNodes,intEq);
      //print("successors: \n"+stringDelimitList(List.map(successors,intString)," ; ")+"\n");
      //print("predecessors: \n"+stringDelimitList(List.map(predecessors,intString)," ; ")+"\n");
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

protected function BLS_mergeToTargetSize "
  Collect the largest groups of nodes that are smaller than the targetSize."
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
      cluster = if listEmpty(clusterTmp) then listReverse(cluster) else cluster;
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
      true = clusterCost + cost < targetSize;
      group = (node::cluster,cost + clusterCost);
      (clusterTmp,clusterCostsTmp) = BLS_mergeToTargetSize(nodeRest,costRest,targetSize,group::restGroups);
    then (clusterTmp,clusterCostsTmp);
  case(node::nodeRest,cost::costRest,_,group::restGroups)
    equation
      // start a new cluster
      (cluster,clusterCost) = group;
      true = clusterCost + cost >= targetSize;
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

protected function realSum "author: Waurich TUD 2014-07
  Accumulates the real values in the list."
  input list<Real> reals;
  output Real sum;
algorithm
 sum := List.fold(reals,realAdd,0.0);
end realSum;

protected function deleteIntListMembers "author: Waurich TUD 2014-07
  Deletes all entries of lst2 in lst1."
  input list<Integer> lst1;
  input list<Integer> lst2;
  output list<Integer> lstOut;
algorithm
  (_,lstOut,_):= List.intersection1OnTrue(lst1,lst2,intEq);
end deleteIntListMembers;


//-----------------
// Level Scheduling
//-----------------
public function createLevelSchedule "author: marcusw
  Creates a level scheduling for the given graph."
  input HpcOmTaskGraph.TaskGraph iGraph;
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  output HpcOmSimCode.Schedule oSchedule;
  output HpcOmTaskGraph.TaskGraphMeta oMeta;
protected
  list<list<Integer>> levelTasks;
  HpcOmSimCode.Schedule tmpSchedule;
  list<HpcOmSimCode.TaskList> levelTaskLists;
algorithm
  levelTasks := HpcOmTaskGraph.getLevelNodes(iGraph);
  levelTaskLists := List.fold(levelTasks, function createLevelScheduleForLevel(iGraph=iGraph, iMeta=iMeta, iSccSimEqMapping=iSccSimEqMapping), {});
  levelTaskLists := listReverse(levelTaskLists);
  oSchedule := HpcOmSimCode.LEVELSCHEDULE(levelTaskLists,false);
  oMeta := iMeta;
end createLevelSchedule;

protected function createLevelScheduleForLevel "author: marcusw
  Handles all tasks of one level."
  input list<Integer> iTasksOfLevel;
  input HpcOmTaskGraph.TaskGraph iGraph;
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input list<HpcOmSimCode.TaskList> iLevelTaskLists;
  output list<HpcOmSimCode.TaskList> oLevelTaskLists;
protected
  array<tuple<Integer, Real>> exeCosts;
  HpcOmSimCode.TaskList taskList;
  array<list<Integer>> inComps;
  list<Integer> sortedTasksOfLevel;
  list<HpcOmSimCode.Task> tasksOfLevel;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(exeCosts=exeCosts,inComps=inComps) := iMeta;
  //we should not sort the tasks regarding their size, because it seems that the first N tasks are scheduled to thread 1 and the next N tasks are scheduled
  //to thread 2 and so on
  //sortedTasksOfLevel := List.sort(iTasksOfLevel, function HpcOmTaskGraph.compareTasksByExecTime(iExeCosts=exeCosts, iTaskComps=inComps, iDescending=true));
  sortedTasksOfLevel := iTasksOfLevel;
  taskList := makeCalcLevelParTaskLst(sortedTasksOfLevel, iSccSimEqMapping, inComps);
  oLevelTaskLists := taskList :: iLevelTaskLists;
end createLevelScheduleForLevel;

protected function getLevelAssignment "
  Folding function to get a levelassignment for each node."
  input list<Integer> level;
  input tuple<Integer,array<Integer>> tplIn; //<levelIndex,assignmentArrayIn>
  output tuple<Integer,array<Integer>> tplOut;
protected
  Integer idx;
  array<Integer> ass;
algorithm
  (idx,ass) := tplIn;
  List.map2_0(level,Array.updateIndexFirst,idx,ass);
  tplOut := (idx+1,ass);
end getLevelAssignment;

protected function makeCalcLevelParTaskLst "
  Makes a parallel list of CALCTASK_LEVEL-Tasks out of the given lists of simEqSyslst and corresponding node list."
  input list<Integer> iNodeIdc;
  input array<list<Integer>> iSccSimEqMapping; // Maps each scc to a list of simEqs
  input array<list<Integer>> iNodeSccMapping;  // Maps nodeIdx to a list of SCCs
  output HpcOmSimCode.TaskList oTasks;
protected
  list<list<Integer>> tmpList = {};
  Integer nodeIdx;
algorithm
  for nodeIdx in listReverse(iNodeIdc) loop
    tmpList := {nodeIdx}::tmpList;
  end for;
  oTasks := makeCalcLevelParTaskLstForMergedNodes(tmpList, iSccSimEqMapping, iNodeSccMapping);
end makeCalcLevelParTaskLst;

protected function makeCalcLevelParTaskLstForMergedNodes "
  Makes a parallel list of CALCTASK_LEVEL-Tasks out of the given lists of simEqSyslst and corresponding node list."
  input list<list<Integer>> iNodeIdc;
  input array<list<Integer>> iSccSimEqMapping; // Maps each scc to a list of simEqs
  input array<list<Integer>> iNodeSccMapping;  // Maps nodeIdx to a list of SCCs
  output HpcOmSimCode.TaskList oTasks;
protected
  list<HpcOmSimCode.Task> tmpList;
algorithm
  tmpList := List.map(iNodeIdc, function makeCalcTaskLevel(iNodeSccMapping=iNodeSccMapping, iSccSimEqMapping=iSccSimEqMapping));
  oTasks := HpcOmSimCode.PARALLELTASKLIST(tmpList);
end makeCalcLevelParTaskLstForMergedNodes;

protected function makeCalcTaskLevel "
  Makes a CALCTASK_LEVEL for the given list of SimEqSys and a nodeIdx."
  input list<Integer> iNodeIdc;
  input array<list<Integer>> iNodeSccMapping;  // Maps nodeIdx to a list of SCCs
  input array<list<Integer>> iSccSimEqMapping; // Maps SCC-index to a list of sim-equations
  output HpcOmSimCode.Task oTask;
protected
  list<Integer> simEqs = {};
  list<Integer> sccs;
  Integer sccIdx;
algorithm
  for nodeIdx in iNodeIdc loop
    sccs := arrayGet(iNodeSccMapping, nodeIdx);
    for sccIdx in sccs loop
      simEqs := listAppend(simEqs, arrayGet(iSccSimEqMapping, sccIdx));
    end for;
  end for;
  oTask := HpcOmSimCode.CALCTASK_LEVEL(simEqs,iNodeIdc,NONE());
end makeCalcTaskLevel;

public function makeCalcTask "
  Makes a CALCTASK for the given list of SimEqSys and a nodeIdx."
  input list<Integer> simEqs;
  input Integer node;
  input Integer threadIdx;
  output HpcOmSimCode.Task taskOut;
algorithm
  taskOut := HpcOmSimCode.CALCTASK(0,node,1.0,1.0,threadIdx,simEqs);
end makeCalcTask;

protected function arrayIntIsNegative "author: Waurich TUD 2014-07
  Outputs true if the indexed value in the array is lower than 0."
  input Integer node;
  input array<Integer> ass;
  output Boolean isAss;
algorithm
  isAss := intLt(arrayGet(ass,node),0);
end arrayIntIsNegative;

protected function dumpLevelSchedule "author: marcusw
  Helper function to print one level."
  input HpcOmSimCode.TaskList iLevelInfo;
  input Integer iLevel;
  output String levelStr;
  output Integer oLevel;
protected
  String s;
  list<HpcOmSimCode.Task> tasks;
algorithm
  (levelStr,oLevel) := match(iLevelInfo, iLevel)
    case(HpcOmSimCode.PARALLELTASKLIST(tasks=tasks),_)
      equation
        s = "Parallel Level " + intString(iLevel) + ":\n";
        s = s + dumpTaskList(tasks);
      then (s,iLevel + 1);
    case(HpcOmSimCode.SERIALTASKLIST(tasks=tasks),_)
      equation
        s = "Serial Level " + intString(iLevel) + ":\n";
        s = s + dumpTaskList(tasks);
      then (s,iLevel + 1);
    else
      equation
        print("printLevelSchedule failed!\n");
      then fail();
   end match;
end dumpLevelSchedule;


//-----------------------
// Fixed level Scheduling
//-----------------------
public function createFixedLevelSchedule "author: marcusw
  Creates a level scheduling for the given graph, but assign the tasks to the threads."
  input HpcOmTaskGraph.TaskGraph iGraph;
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  input Integer iNumberOfThreads;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  output HpcOmSimCode.Schedule oSchedule;
  output HpcOmTaskGraph.TaskGraphMeta oMeta;
protected
  list<list<Integer>> levelTasks;
  //for each node (arrayIdx): list of threads that handle predecessor tasks. If a node has multiple
  //predecessors handled by the same thread, the thread-index occurs multiple times in the list.
  array<list<Integer>> adviceLists;
  HpcOmSimCode.Schedule tmpSchedule;
  list<HpcOmSimCode.TaskList> levelTaskLists;
algorithm
  // 1. Create a task list for each thread and a advice list for each task which is empty at beginning
  // 2. Iterate over all levels
  //  2.1. Create an thread-ready-list and set all values to 0
  //  2.2. Iterate over all tasks of the current level
  //    2.2.1. Find the thread that should calulcate the task
  //        2.2.1. (1) This could be the thread with the lowest value in the ready list if no thread is in the advice list
  //        2.2.1. (2) This could be the first thread in the advice list, if the thread has not already an execution time > (sum(exec(levelTasks)) / numThreads)
  //        2.2.1. (3) Otherwise case (1)
  //    2.2.2. Append the task to the thread and add the execution cost the the ready list
  //    2.2.3. Add the thread to the advice-list of all successor tasks
  levelTasks := HpcOmTaskGraph.getLevelNodes(iGraph);
  adviceLists := arrayCreate(arrayLength(iGraph), {});
  levelTaskLists := List.fold(levelTasks, function createFixedLevelScheduleForLevel(iAdviceList=adviceLists, iGraph=iGraph, iMeta=iMeta, iNumberOfThreads=iNumberOfThreads, iSccSimEqMapping=iSccSimEqMapping), {});
  levelTaskLists := listReverse(levelTaskLists);
  oSchedule := HpcOmSimCode.LEVELSCHEDULE(levelTaskLists,true);
  oMeta := iMeta;
end createFixedLevelSchedule;

protected function createFixedLevelScheduleForLevel "author: marcusw
  Handles all tasks of one level. The advice-list is updated during calculation."
  input list<Integer> iTasksOfLevel;
  input array<list<Integer>> iAdviceList;
  input HpcOmTaskGraph.TaskGraph iGraph;
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  input Integer iNumberOfThreads;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input list<HpcOmSimCode.TaskList> iLevelTaskLists;
  output list<HpcOmSimCode.TaskList> oLevelTaskLists;
protected
  Real levelExecCosts;
  array<Real> threadReadyList;
  array<list<Integer>> threadTaskList;
  array<tuple<Integer, Real>> exeCosts;
  HpcOmSimCode.TaskList taskList;
  list<HpcOmSimCode.Task> tasksOfLevel;
  array<list<Integer>> inComps;
  list<Integer> sortedTasksOfLevel;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(exeCosts=exeCosts,inComps=inComps) := iMeta;
  levelExecCosts := HpcOmTaskGraph.getCostsForContractedNodes(iTasksOfLevel, exeCosts);
  threadReadyList := arrayCreate(iNumberOfThreads, 0.0);
  threadTaskList := arrayCreate(iNumberOfThreads, {});
  sortedTasksOfLevel := List.sort(iTasksOfLevel, function HpcOmTaskGraph.compareTasksByExecTime(iExeCosts=exeCosts, iTaskComps=inComps, iDescending=true));
  _ := List.fold(sortedTasksOfLevel, function createFixedLevelScheduleForTask(iLevelExecCosts=levelExecCosts, iAdviceList=iAdviceList, iThreadReadyList=threadReadyList, iGraph=iGraph, iMeta=iMeta), threadTaskList);
  threadTaskList := Array.map(threadTaskList, listReverse);
  ((_,tasksOfLevel)) := Array.fold2(threadTaskList, createFixedLevelScheduleForLevel0, inComps, iSccSimEqMapping, (1,{}));
  taskList := HpcOmSimCode.PARALLELTASKLIST(tasksOfLevel);
  oLevelTaskLists := taskList :: iLevelTaskLists;
end createFixedLevelScheduleForLevel;

protected function createFixedLevelScheduleForLevel0
  input list<Integer> iTaskList;
  input array<list<Integer>> iComps;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input tuple<Integer, list<HpcOmSimCode.Task>> iIdxTaskList; //<threadIdx, taskList>
  output tuple<Integer, list<HpcOmSimCode.Task>> oIdxTaskList; //<threadIdx, taskList>
protected
  Integer threadIdx;
  list<HpcOmSimCode.Task> taskList;
  HpcOmSimCode.Task newTask;
  list<Integer> components, simEqs;
  Integer taskIdx;
algorithm
  (threadIdx, taskList) := iIdxTaskList;
  for taskIdx in iTaskList loop
    components := arrayGet(iComps, taskIdx); //Components of the task
    simEqs := List.flatten(List.map(List.map1(components,Array.getIndexFirst,iSccSimEqMapping), listReverse));
    if(intGt(listLength(simEqs), 0)) then
      simEqs := simEqs;
      newTask := HpcOmSimCode.CALCTASK_LEVEL(simEqs, {taskIdx}, SOME(threadIdx));
      taskList := newTask :: taskList;
    end if;
  end for;

  //This code merges all tasks handled by the same thread -- makes efficient memory management more complicated
  //components := List.flatten(List.map1(iTaskList, Array.getIndexFirst, iComps)); //Components of each task
  //simEqs := List.flatten(List.map(List.map1(components,Array.getIndexFirst,iSccSimEqMapping), listReverse));
  //if(intGt(listLength(simEqs), 0)) then
  //  simEqs := listReverse(simEqs);
  //  newTask := HpcOmSimCode.CALCTASK_LEVEL(simEqs, iTaskList, SOME(threadIdx));
  //  taskList := newTask :: taskList;
  //end if;
  oIdxTaskList := (threadIdx+1,taskList);
end createFixedLevelScheduleForLevel0;

protected function createFixedLevelScheduleForTask
  input Integer iTaskIdx;
  input Real iLevelExecCosts; //sum of all execcosts
  input array<list<Integer>> iAdviceList; //is updated with arrayUpdate
  input array<Real> iThreadReadyList; //is updated with arrayUpdate
  input HpcOmTaskGraph.TaskGraph iGraph;
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  input array<list<Integer>> iThreadTasks;
  output array<list<Integer>> oThreadTasks; //list of tasks for each thread
protected
  list<Integer> adviceElem, threadTasks, successorList;
  Integer threadIdx;
  Real threadReadyTime, exeCost;
algorithm
  //print("\tcreateFixedLevelScheduleForTask: handling task: " + intString(iTaskIdx) + "\n");
  adviceElem := arrayGet(iAdviceList, iTaskIdx);
  //print("\t\tAdvice-list: " + stringDelimitList(List.map(adviceElem, intString), ",") + "\n");
  adviceElem := flattenAdviceList(adviceElem, arrayLength(iThreadReadyList));
  //print("\t\tAdvice-list-flattened: " + stringDelimitList(List.map(adviceElem, intString), ",") + "\n");
  threadIdx := getBestFittingThread(adviceElem, iLevelExecCosts, iThreadReadyList);
  //print("\t\tBest-thread: " + intString(threadIdx) + "\n");
  threadTasks := arrayGet(iThreadTasks, threadIdx);
  successorList := arrayGet(iGraph, iTaskIdx);
  //print("\t\tSuccessors: " + stringDelimitList(List.map(successorList, intString), ",") + "\n");
  //update the advice list
  _ := List.fold1(successorList, createFixedLevelScheduleForTask0, threadIdx, iAdviceList);
  threadReadyTime := arrayGet(iThreadReadyList, threadIdx);
  ((_,exeCost)) := HpcOmTaskGraph.getExeCost(iTaskIdx, iMeta);
  threadReadyTime := realAdd(threadReadyTime, exeCost);
  //update the thread ready list
  _ := arrayUpdate(iThreadReadyList, threadIdx, threadReadyTime);
  //update the thread tasks
  threadTasks := iTaskIdx :: threadTasks;
  oThreadTasks := arrayUpdate(iThreadTasks, threadIdx, threadTasks);
end createFixedLevelScheduleForTask;

protected function createFixedLevelScheduleForTask0 "author: marcusw
   Update the given advice list, by adding the iThreadAdvice to the successor-task-entry."
  input Integer iSuccessor;
  input Integer iThreadAdvice;
  input array<list<Integer>> iAdviceList;
  output array<list<Integer>> oAdviceList;
protected
  list<Integer> adviceElem;
algorithm
  adviceElem := arrayGet(iAdviceList, iSuccessor);
  adviceElem := iThreadAdvice::adviceElem;
  oAdviceList := arrayUpdate(iAdviceList, iSuccessor, adviceElem);
end createFixedLevelScheduleForTask0;

protected function flattenAdviceList "author: marcusw
   Flatten the given advice list and order the entries regarding their occurrence count.
   For example: {2,3,1,1,2,2} -> {2,1,3}"
  input list<Integer> iAdviceList;
  input Integer iNumOfThreads;
  output list<Integer> oAdviceList;
protected
  array<Integer> counterArray;
  list<tuple<Integer,Integer>> tupleList;
algorithm
  counterArray := arrayCreate(iNumOfThreads,0);
  counterArray := List.fold(iAdviceList, flattenAdviceListElem, counterArray);
  tupleList := arrayToTupleListZeroRemoved(counterArray, 1, {});
  oAdviceList := List.map(List.sort(tupleList, intTpl22Gt),Util.tuple21);
end flattenAdviceList;

protected function flattenAdviceListElem "author: marcusw
   Increment the value in the counter array of the given thread (iAdviceElem)."
  input Integer iAdviceElem;
  input array<Integer> iCounterArray;
  output array<Integer> oCounterArray;
protected
  Integer counter;
algorithm
  counter := arrayGet(iCounterArray, iAdviceElem);
  counter := counter + 1;
  oCounterArray := arrayUpdate(iCounterArray, iAdviceElem, counter);
end flattenAdviceListElem;

protected function arrayToTupleListZeroRemoved "author: marcusw
   Convert a integer array, to list of tuples <arrayIndex, value> if the value is != 0.
   For example: [1,4,2] -> {<1,1>,<2,4>,<3,2>}"
  input array<Integer> iArray;
  input Integer iCurrentIdx;
  input list<tuple<Integer,Integer>> iTupleList;
  output list<tuple<Integer,Integer>> oTupleList;
protected
  list<tuple<Integer,Integer>> tmpTupleList;
  Integer currentValue;
algorithm
  oTupleList := matchcontinue(iArray, iCurrentIdx, iTupleList)
    case(_,_,_)
      equation
        true = intLe(iCurrentIdx, arrayLength(iArray));
        currentValue = arrayGet(iArray, iCurrentIdx);
        true = intNe(currentValue, 0);
        tmpTupleList = (iCurrentIdx, currentValue)::iTupleList;
        tmpTupleList = arrayToTupleListZeroRemoved(iArray, iCurrentIdx+1, tmpTupleList);
      then tmpTupleList;
    case(_,_,_)
      equation
        true = intLe(iCurrentIdx, arrayLength(iArray));
        tmpTupleList = arrayToTupleListZeroRemoved(iArray, iCurrentIdx+1, iTupleList);
      then tmpTupleList;
    else iTupleList;
  end matchcontinue;
end arrayToTupleListZeroRemoved;

protected function intTpl22Gt
  input tuple<Integer,Integer> iTpl1;
  input tuple<Integer,Integer> iTpl2;
  output Boolean oRes;
protected
  Integer val1, val2;
algorithm
  (_,val1) := iTpl1;
  (_,val2) := iTpl2;
  oRes := intGt(val1, val2);
end intTpl22Gt;

protected function getBestFittingThread "author: marcusw
  Get the optimal thread for the task, regarding the given advice list."
  input list<Integer> iAdviceList; //advice list of the task - the list is traversed from front to back, until a suitable thread is found
  input Real iLevelExecCosts; //sum of all execosts
  input array<Real> iThreadReadyList;
  output Integer oThreadIdx;
protected
  Real averageThreadTime, readyTime; //levelExecCost / numberOfThreads
  Integer numOfThreads, threadIdx, head;
  list<Integer> tail;
algorithm
  oThreadIdx := matchcontinue(iAdviceList, iLevelExecCosts, iThreadReadyList)
    case({},_,_)
      equation
        threadIdx = getFirstReadyThread(iThreadReadyList);
      then threadIdx;
    case(head::tail,_,_)
      equation
        readyTime = arrayGet(iThreadReadyList, head);
        numOfThreads = arrayLength(iThreadReadyList);
        averageThreadTime = realDiv(iLevelExecCosts, intReal(numOfThreads));
        true = realLt(readyTime, averageThreadTime);
      then head;
    case(head::tail,_,_)
      then getBestFittingThread(tail,iLevelExecCosts, iThreadReadyList);
  end matchcontinue;
end getBestFittingThread;

protected function getFirstReadyThread
  input array<Real> iThreadReadyList;
  output Integer oFirstReadyThreadIdx;
algorithm
  ((oFirstReadyThreadIdx,_,_)) := Array.fold(iThreadReadyList, getFirstReadyThread0, (-1,-1.0,1));
end getFirstReadyThread;

protected function getFirstReadyThread0
  input Real iThreadReadyTime;
  input tuple<Integer,Real,Integer> iFirstReadyThread; //<firstThreadIdx, readyTime, currentThreadIdx>
  output tuple<Integer,Real,Integer> oFirstReadyThread;
protected
  Integer firstThreadIdx, currentThreadIdx;
  Real readyTime;
  Boolean isLower;
algorithm
  oFirstReadyThread := match(iThreadReadyTime, iFirstReadyThread)
    case(_,(-1,_,currentThreadIdx)) //no thread set as firstThread
      then ((currentThreadIdx, iThreadReadyTime, currentThreadIdx+1));
    case(_,(firstThreadIdx,readyTime,currentThreadIdx))
      equation
        isLower = realLt(iThreadReadyTime, readyTime);
        firstThreadIdx = if isLower then currentThreadIdx else firstThreadIdx;
        readyTime = if isLower then iThreadReadyTime else readyTime;
      then ((firstThreadIdx, readyTime, currentThreadIdx+1));
    else
      equation
        print("getFirstReadyThread0 failed\n");
    then iFirstReadyThread;
  end match;
end getFirstReadyThread0;


//---------------------------
// Task Dependency Scheduling
//---------------------------
public function createTaskDepSchedule "author: marcusw
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
        taskGraphT = AdjacencyMatrix.transposeAdjacencyMatrix(iTaskGraph,arrayLength(iTaskGraph));
        ((_,nodeLevelMap)) = Array.fold3(taskGraphT, createNodeLevelMapping, nodeMark, inComps, iSccSimEqMapping, (1,{}));
        nodeLevelMap = List.sort(nodeLevelMap, sortNodeLevelMapping);
        filteredNodeLevelMap = List.map(nodeLevelMap, filterNodeLevelMapping);
        filteredNodeLevelMap = listReverse(filteredNodeLevelMap);
        tmpSchedule = HpcOmSimCode.TASKDEPSCHEDULE(filteredNodeLevelMap);
      then tmpSchedule;
    else
      equation
        print("HpcOmScheduler.createTaskDepSchedule failed.\n");
      then fail();
  end matchcontinue;
end createTaskDepSchedule;

protected function createNodeLevelMapping "author: marcusw
  Create a mapping for each node, which stores the task, the level-index and a list of all parents."
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
  //print("createNodeLevelMapping NodeIdx: " + intString(nodeIdx) + "\n");
  components := arrayGet(inComps,nodeIdx);
  nodeMark := arrayGet(nodeMarks,List.last(components));
  //print("-> Components: " + stringDelimitList(List.map(components,intString),", ") + "\n");
  //print("-> NodeMark: " + intString(nodeMark) + "\n");
  //print("ISccSimEqMapping-Length: " + intString(arrayLength(iSccSimEqMapping)) + "\n");
  simEqIdc := List.map(List.map1(components,getSimEqSysIdxForComp,iSccSimEqMapping), List.last);
  task := HpcOmSimCode.CALCTASK(-1,nodeIdx,-1.0,-1.0,-1,simEqIdc);
  nodeLevelMap := (task,nodeMark,iNodeDependenciesT)::nodeLevelMap;
  oNodeInfo := ((nodeIdx+1,nodeLevelMap));
end createNodeLevelMapping;

protected function sortNodeLevelMapping "author: marcusw
  Sort the tuple elements regarding their level (second tuple-argument)."
  input tuple<HpcOmSimCode.Task,Integer,list<Integer>> iElem1;
  input tuple<HpcOmSimCode.Task,Integer,list<Integer>> iElem2;
  output Boolean oResult;
protected
  Integer elemLvl1, elemLvl2;
  Integer task1Idx;
algorithm
  (HpcOmSimCode.CALCTASK(index=task1Idx),elemLvl1,_) := iElem1;
  (_,elemLvl2,_) := iElem2;
  //print("sortNodeLevelMapping: TaskIdx: " + intString(task1Idx) + " level: " + intString(elemLvl1) + "\n");
  oResult := intGe(elemLvl1,elemLvl2);
end sortNodeLevelMapping;

protected function filterNodeLevelMapping "author: marcusw
  Remove the second tuple argument (level number)."
  input tuple<HpcOmSimCode.Task,Integer,list<Integer>> iElem;
  output tuple<HpcOmSimCode.Task,list<Integer>> oElem;
protected
  HpcOmSimCode.Task task;
  list<Integer> childTasks;
algorithm
  (task,_,childTasks) := iElem;
  oElem := ((task,childTasks));
end filterNodeLevelMapping;


//-----------------
// Metis Scheduling
//-----------------
public function createMetisSchedule "author: marcusw
  Creates a scheduling by passing the arguments to metis."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer iNumberOfThreads;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  output HpcOmSimCode.Schedule oSchedule;
protected
  list<Integer> extInfo;
  array<Integer> xadj, adjncy, vwgt, adjwgt;
  HpcOmSimCode.Schedule tmpSchedule;
  array<Integer> extInfoArr;
  HpcOmTaskGraph.TaskGraph taskGraphT;
  array<list<HpcOmSimCode.Task>> threadTasks;
  list<Integer> rootNodes;
  array<tuple<HpcOmSimCode.Task, Integer>> allCalcTasks;
  list<tuple<HpcOmSimCode.Task,Integer>> nodeList_refCount; //list of nodes which are ready to schedule
  list<HpcOmSimCode.Task> nodeList;
  array<HpcOmTaskGraph.Communications> commCosts;
  array<list<Integer>> inComps;

  array<Integer> priorityArr;
  list<list<Integer>> levelNodes;
  array<list<Integer>> procAss;
  list<Integer> priorityTasks,otherTasks;
  list<Integer> order;
  list<HpcOmSimCode.Task> removeLocks;
algorithm
  oSchedule := matchcontinue(iTaskGraph,iTaskGraphMeta,iNumberOfThreads,iSccSimEqMapping,iSimVarMapping)
    case(_,HpcOmTaskGraph.TASKGRAPHMETA(commCosts=commCosts,inComps=inComps),_,_,_)
      equation
        (xadj,adjncy,vwgt,adjwgt) = prepareMetis(iTaskGraph,iTaskGraphMeta);

        //print("createMetisSchedule: Weights of nodes = " + stringDelimitList(List.map(arrayList(vwgt), intString), ",") + "\n");

        if(intGt(iNumberOfThreads, 1)) then //check if more then one thread is given -- otherwise a division through zero will occur
          extInfo = HpcOmSchedulerExt.scheduleMetis(xadj, adjncy, vwgt, adjwgt, iNumberOfThreads);
          extInfoArr = listArray(extInfo);
        else
          extInfoArr = arrayCreate(arrayLength(iTaskGraph), 1);
          extInfo = arrayList(extInfoArr);
        end if;

        //print("Metis scheduling info: " + stringDelimitList(List.map(extInfo, intString), ",") + "\n");
        true = intEq(arrayLength(iTaskGraph),arrayLength(extInfoArr));
        taskGraphT = AdjacencyMatrix.transposeAdjacencyMatrix(iTaskGraph,arrayLength(iTaskGraph));
        rootNodes = HpcOmTaskGraph.getRootNodes(iTaskGraph);

        //sort the tasks in the partitions, always the tasks that are predecessors of other partitions first.
        priorityArr = arrayCreate(arrayLength(iTaskGraph),0);
        createMetisSchedule1(List.intRange(arrayLength(iTaskGraph)),extInfoArr,iTaskGraph,taskGraphT,priorityArr);
        levelNodes = HpcOmTaskGraph.getLevelNodes(iTaskGraph);
        allCalcTasks = convertTaskGraphToTasks(taskGraphT,iTaskGraphMeta,convertNodeToTask);
        (priorityTasks,otherTasks) = createMetisSchedule2(levelNodes,priorityArr,{},{});
        order = listAppend(priorityTasks,otherTasks);

        //create schedule
        procAss = arrayCreate(iNumberOfThreads,{});
        List.map2_0(List.intRange(arrayLength(iTaskGraph)),getProcAss,extInfoArr,procAss);
        threadTasks = arrayCreate(iNumberOfThreads,{});
        removeLocks = {};
        tmpSchedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,{},{},allCalcTasks);

        (tmpSchedule,removeLocks) = createScheduleFromAssignments(extInfoArr,procAss,SOME(order),iTaskGraph,taskGraphT,iTaskGraphMeta,iSccSimEqMapping,removeLocks,order,iSimVarMapping,tmpSchedule);
        // remove superfluous locks
        if Flags.isSet(Flags.HPCOM_DUMP) then
          print("number of removed superfluous locks: "+intString(intDiv(listLength(removeLocks),2))+"\n");
        end if;
        tmpSchedule = traverseAndUpdateThreadsInSchedule(tmpSchedule,removeLocksFromThread,removeLocks);
        tmpSchedule = updateLockIdcsInThreadschedule(tmpSchedule,removeLocksFromLockList,removeLocks);

        //nodeList_refCount = List.map1(rootNodes, getTaskByIndex, allCalcTasks);
        //nodeList = List.map(nodeList_refCount, Util.tuple21);
        //nodeList = List.sort(nodeList, compareTasksByWeighting);
        //tmpSchedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,{},{},allCalcTasks);
        //tmpSchedule = createExtSchedule1(nodeList,extInfoArr, iTaskGraph, taskGraphT, commCosts, inComps, iSccSimEqMapping, iSimVarMapping, getLocksByPredecessorList, tmpSchedule);
        //tmpSchedule = addSuccessorLocksToSchedule(iTaskGraph,addReleaseLocksToSchedule,commCosts,inComps,iSimVarMapping,tmpSchedule);
      then setScheduleLockIds(tmpSchedule); // set unique lock ids
    else
      equation
        print("HpcOmScheduler.createMetisSchedule not every node has a scheduler-info.\n");
      then fail();
  end matchcontinue;
end createMetisSchedule;

protected function getProcAss
  input Integer idx;
  input array<Integer> taskAss;
  input array<list<Integer>> procAss;
protected
  Integer thread;
algorithm
  thread := arrayGet(taskAss,idx);
  Array.updateElementListAppend(thread,{idx},procAss);
end getProcAss;

protected function createMetisSchedule2 "author: Waurich TUD 03-2015
  Sorts the tasks in 2 causal lists. one prioritylist and another one that is appended to this one."
  input list<list<Integer>> levelNodes;
  input array<Integer> priorityArr;
  input list<Integer> prioLstIn;
  input list<Integer> otherLstIn;
  output list<Integer> prioLstOut;
  output list<Integer> otherLstOut;
algorithm
  (prioLstOut,otherLstOut) := match(levelNodes,priorityArr,prioLstIn,otherLstIn)
    local
      list<Integer> level, prioLst, otherLst;
      list<list<Integer>> rest;
    case({},_,_,_)
      algorithm
    then (prioLstIn,otherLstIn);
    case(level::rest,_,_,_)
      algorithm
        (prioLst,otherLst) := List.split1OnTrue(level,isPrioNode,priorityArr);
        //prioTaskLst := List.map(List.map1(prioLst,Array.getIndexFirst,allCalcTasks),Util.tuple21);
        //otherTaskLst := List.map(List.map1(otherLst,Array.getIndexFirst,allCalcTasks),Util.tuple21);
        prioLst := listAppend(prioLstIn,prioLst);
        otherLst := listAppend(otherLstIn,otherLst);
        (prioLst,otherLst) := createMetisSchedule2(rest,priorityArr,prioLst,otherLst);
    then (prioLst,otherLst);
  end match;
end createMetisSchedule2;

protected function isPrioNode "author: Waurich TUD 03-2015"
  input Integer idx;
  input array<Integer> prioArr;
  output Boolean isPrio;
algorithm
  isPrio := intEq(1,arrayGet(prioArr,idx));
end isPrioNode;

protected function createMetisSchedule1 "author: Waurich TUD 03-2015
  Builds a priority array to mark tasks that have to be solved as early as possible."
  input list<Integer> taskIdcs;
  input array<Integer> threadIds; // the assigned thread for each task
  input array<list<Integer>> taskGraph;
  input array<list<Integer>> taskGraphT;
  input array<Integer> priorityArr;
algorithm
  _ := matchcontinue(taskIdcs,threadIds,taskGraph,taskGraphT,priorityArr)
  local
    Integer threadId, taskIdx;
    list<Integer> preds, predThreads, rest;
  case({},_,_,_,_)
    then ();
  case(taskIdx::rest,_,_,_,_)
    algorithm // this task is already prioritized, add the predecessors as well
      true := intEq(1,arrayGet(priorityArr,taskIdx));
      preds := arrayGet(taskGraphT,taskIdx);
      preds := List.filter1OnTrue(preds,arrayIntIsNotOne,priorityArr);// are not prioritized
      List.map2_0(preds,Array.updateIndexFirst,1,priorityArr);
      //print("priority: "+stringDelimitList(List.map(preds,intString),", ")+"\n");
      rest := listAppend(preds,rest);
      createMetisSchedule1(rest,threadIds,taskGraph,taskGraphT,priorityArr);
   then ();
  case(taskIdx::rest,_,_,_,_)
    algorithm// check if this task is a successor of a differently threaded task
      //true := intLe(0,arrayGet(priorityArr,taskIdx));
      threadId := arrayGet(threadIds,taskIdx);
      preds := arrayGet(taskGraphT,taskIdx);
      predThreads := List.map1(preds,Array.getIndexFirst,threadIds);
      (predThreads,preds) := List.filter1OnTrueSync(predThreads,intNe,threadId,preds);
      if not listEmpty(predThreads) then
        //print("priority: "+stringDelimitList(List.map(preds,intString),", ")+"\n");
        List.map2_0(preds,Array.updateIndexFirst,1,priorityArr);
        rest := listAppend(preds,rest);
      else
        arrayUpdate(priorityArr,taskIdx,0);
      end if;
      createMetisSchedule1(rest,threadIds,taskGraph,taskGraphT,priorityArr);
   then ();
  end matchcontinue;
end createMetisSchedule1;

protected function arrayIntIsNotOne "author: Waurich TUD 03-2015"
  input Integer idx;
  input array<Integer> arr;
  output Boolean isOne;
algorithm
  isOne := intNe(1,arrayGet(arr,idx));
end arrayIntIsNotOne;

public function createHMetisSchedule "author: marcusw
  Creates a scheduling by passing the arguments to hmetis."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer iNumberOfThreads;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  output HpcOmSimCode.Schedule oSchedule;
protected
  list<Integer> extInfo;
  array<Integer> xadj, adjncy, vwgt, adjwgt;
  HpcOmSimCode.Schedule tmpSchedule;
  array<Integer> extInfoArr;
  HpcOmTaskGraph.TaskGraph taskGraphT;
  array<list<HpcOmSimCode.Task>> threadTasks;
  list<Integer> rootNodes;
  array<tuple<HpcOmSimCode.Task, Integer>> allCalcTasks;
  list<tuple<HpcOmSimCode.Task,Integer>> nodeList_refCount; //list of nodes which are ready to schedule
  list<HpcOmSimCode.Task> nodeList;
  array<HpcOmTaskGraph.Communications> commCosts;
  array<list<Integer>> inComps;
algorithm
  oSchedule := matchcontinue(iTaskGraph,iTaskGraphMeta,iNumberOfThreads,iSccSimEqMapping,iSimVarMapping)
    case(_,HpcOmTaskGraph.TASKGRAPHMETA(commCosts=commCosts,inComps=inComps),_,_,_)
      equation
        print("Funktionsaufruf!");
        (xadj,adjncy,vwgt,adjwgt) = preparehMetis(iTaskGraph,iTaskGraphMeta);
        extInfo = HpcOmSchedulerExt.schedulehMetis(xadj, adjncy, vwgt, adjwgt, iNumberOfThreads);
        extInfoArr = listArray(extInfo);
        print("Hier geht MetaModelica los!\n");
        print("External scheduling info: " + stringDelimitList(List.map(extInfo, intString), ",") + "\n");
        true = intEq(arrayLength(iTaskGraph),arrayLength(extInfoArr));

        taskGraphT = AdjacencyMatrix.transposeAdjacencyMatrix(iTaskGraph,arrayLength(iTaskGraph));
        rootNodes = HpcOmTaskGraph.getRootNodes(iTaskGraph);
        allCalcTasks = convertTaskGraphToTasks(taskGraphT,iTaskGraphMeta,convertNodeToTask);
        nodeList_refCount = List.map1(rootNodes, getTaskByIndex, allCalcTasks);
        nodeList = List.map(nodeList_refCount, Util.tuple21);
        nodeList = List.sort(nodeList, compareTasksByWeighting);
        threadTasks = arrayCreate(iNumberOfThreads,{});
        tmpSchedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,{},{},allCalcTasks);
        tmpSchedule = createExtSchedule1(nodeList,extInfoArr, iTaskGraph, taskGraphT, commCosts, inComps, iSccSimEqMapping, iSimVarMapping, getLocksByPredecessorList, tmpSchedule);
        tmpSchedule = addSuccessorLocksToSchedule(iTaskGraph,addReleaseLocksToSchedule,commCosts,inComps,iSimVarMapping,tmpSchedule);
        //printSchedule(tmpSchedule);
      then setScheduleLockIds(tmpSchedule); // set unique lock ids
    else
      equation
        print("HpcOmScheduler.createHMetisSchedule not every node has a scheduler-info.\n");
      then fail();
  end matchcontinue;
end createHMetisSchedule;

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
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input list<tuple<Integer,Integer,Integer>> irelations;
  output list<tuple<Integer,Integer,Integer>> orelations;
protected
  Real costs;
  Integer costsInt;
algorithm
  costs := HpcOmTaskGraph.getCommCostTimeBetweenNodes(n,edge,iTaskGraphMeta);
  costsInt := realInt(costs);
  orelations := listAppend(irelations,{(edge,n,costsInt)});
  orelations := listAppend(orelations,{(n,edge,costsInt)});
end getSingleRelations;

protected function getRelations
  input list<Integer> edges;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
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
        arrayUpdate(adjwgt,imarker,cost);
        arrayUpdate(adjncy,imarker,tonode-1);
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
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
protected
  tuple<Integer,Real> value;
  Real rv;
algorithm
  value:=HpcOmTaskGraph.getExeCost(node,iTaskGraphMeta);
  (_,rv):=value;
  _:=arrayUpdate(vwgt,node,realInt(rv));
end setVwgt;

protected function prepareMetis "author: mkloeppel
  Create all arrays that are necessary to perform a clustering with metis."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  output array<Integer> xadj; //The adjacency structure of the graph
  output array<Integer> adjncy; //The adjacency structure of the graph - see metis CSR-format
  output array<Integer> vwgt; //The weights of the nodes
  output array<Integer> adjwgt; //The weights of the edges
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
  print("l_eint length:" + intString(listLength(l_eint_out))+"\n");
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

protected function preparehMetis
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
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
  print("Diagnostic length: " + intString(listLength(l_eptr)) + " " + intString(listLength(l_eint)) + "\n");
  allTheNodes := List.intRange(n);
  vwgts := arrayCreate(n,0);
  List.map2_0(allTheNodes,setVwgt,vwgts,iTaskGraphMeta);
  eptr := listArray(l_eptr);
  eint := listArray(l_eint);
  hewgts := listArray(l_hewgts);
end preparehMetis;


//--------------------
// External Scheduling //TODO: Rename to Yed Scheduling
//--------------------
public function createExtSchedule "author: marcusw
  Creates a scheduling by reading the required informations from a graphml-file."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer iNumberOfThreads;
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  input String iGraphMLFile; //the file containing schedule-informations
  output HpcOmSimCode.Schedule oSchedule;
protected
  list<Integer> extInfo;
  array<Integer> extInfoArr;
  HpcOmTaskGraph.TaskGraph taskGraphT;
  HpcOmSimCode.Schedule tmpSchedule;
  array<list<HpcOmSimCode.Task>> threadTasks;
  array<HpcOmTaskGraph.Communications> commCosts;
  HpcOmSimCode.Schedule tmpSchedule;
  list<Integer> rootNodes;
  array<tuple<HpcOmSimCode.Task, Integer>> allCalcTasks;
  list<tuple<HpcOmSimCode.Task,Integer>> nodeList_refCount; //list of nodes which are ready to schedule
  list<HpcOmSimCode.Task> nodeList;
  array<list<Integer>> inComps;
algorithm
  oSchedule := matchcontinue(iTaskGraph,iTaskGraphMeta,iNumberOfThreads,iSccSimEqMapping,iSimVarMapping,iGraphMLFile)
    case(_,HpcOmTaskGraph.TASKGRAPHMETA(commCosts=commCosts,inComps=inComps),_,_,_,_)
      equation
        extInfo = HpcOmSchedulerExt.readScheduleFromGraphMl(iGraphMLFile);
        extInfoArr = listArray(extInfo);
        true = intEq(arrayLength(iTaskGraph),arrayLength(extInfoArr));
        //print("External scheduling info: " + stringDelimitList(List.map(extInfo, intString), ",") + "\n");
        taskGraphT = AdjacencyMatrix.transposeAdjacencyMatrix(iTaskGraph,arrayLength(iTaskGraph));
        rootNodes = HpcOmTaskGraph.getRootNodes(iTaskGraph);
        allCalcTasks = convertTaskGraphToTasks(taskGraphT,iTaskGraphMeta,convertNodeToTask);
        nodeList_refCount = List.map1(rootNodes, getTaskByIndex, allCalcTasks);
        nodeList = List.map(nodeList_refCount, Util.tuple21);
        nodeList = List.sort(nodeList, compareTasksByWeighting);
        threadTasks = arrayCreate(iNumberOfThreads,{});
        tmpSchedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,{},{},allCalcTasks);
        tmpSchedule = createExtSchedule1(nodeList,extInfoArr, iTaskGraph, taskGraphT, commCosts, inComps, iSccSimEqMapping, iSimVarMapping, getLocksByPredecessorList, tmpSchedule);
        tmpSchedule = addSuccessorLocksToSchedule(iTaskGraph,addReleaseLocksToSchedule,commCosts,inComps,iSimVarMapping,tmpSchedule);
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
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<Integer>> iSccSimEqMapping; //Maps each scc to a list of simEqs
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  input FuncType iLockWithPredecessorHandler; //Function which handles locks to all predecessors
  input HpcOmSimCode.Schedule iSchedule;
  output HpcOmSimCode.Schedule oSchedule;

  partial function FuncType
    input HpcOmSimCode.Task iTask;
    input list<tuple<HpcOmSimCode.Task,Integer>> iPredecessors;
    input Integer iThreadIdx;
    input array<HpcOmTaskGraph.Communications> iCommCosts;
    input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
    input array<list<SimCodeVar.SimVar>> iSimVarMapping;
    output list<HpcOmSimCode.Task> oTasks; //lock tasks
    output list<HpcOmSimCode.Task> oOutgoingDepTasks; //new outgoing dependency tasks
  end FuncType;
protected
  HpcOmSimCode.Task head, newTask;
  Integer newTaskRefCount;
  list<HpcOmSimCode.Task> rest;
  Real lastChildFinishTime; //The time when the last child has finished calculation
  HpcOmSimCode.Task lastChild;
  list<tuple<HpcOmSimCode.Task,Integer>> predecessors, successors;
  list<Integer> successorIdc;
  list<HpcOmSimCode.Task> outgoingDepTasks, newOutgoingDepTasks;
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
  array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
  HpcOmSimCode.Schedule tmpSchedule;
algorithm
  oSchedule := matchcontinue(iNodeList,iThreadAssignments, iTaskGraph, iTaskGraphT, iCommCosts, iCompTaskMapping, iSccSimEqMapping, iSimVarMapping, iLockWithPredecessorHandler, iSchedule)
    case((head as HpcOmSimCode.CALCTASK(weighting=weighting,index=index,calcTime=calcTime,eqIdc=(eqIdc as firstEq::_)))::rest,_,_,_,_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE(threadTasks=allThreadTasks, outgoingDepTasks=outgoingDepTasks, allCalcTasks=allCalcTasks))
      equation
        //get all predecessors (childs)
        (predecessors, _) = getSuccessorsByTask(head, iTaskGraphT, allCalcTasks);
        (successors, successorIdc) = getSuccessorsByTask(head, iTaskGraph, allCalcTasks);
        false = listEmpty(predecessors); //in this case the node has predecessors
        //print("Handle task " + intString(index) + " with " + intString(listLength(predecessors)) + " child nodes and " + intString(listLength(successorIdc)) + " parent nodes.\n");

        //find thread for scheduling
        threadId = arrayGet(iThreadAssignments,index);
        threadFinishTime = -1.0;
        threadTasks = arrayGet(allThreadTasks,threadId);

        //find all predecessors which are scheduled to another thread and thus require a lock
        (lockTasks,newOutgoingDepTasks) = iLockWithPredecessorHandler(head,predecessors,threadId,iCommCosts,iCompTaskMapping,iSimVarMapping);
        outgoingDepTasks = listAppend(outgoingDepTasks,newOutgoingDepTasks);
        //threadTasks = listAppend(List.map(newLockIdc,convertLockIdToAssignTask), threadTasks);
        threadTasks = listAppend(lockTasks, threadTasks);

        //print("Eq idc: " + stringDelimitList(List.map(eqIdc, intString), ",") + "\n");
        simEqIdc = List.map(List.map1(eqIdc,getSimEqSysIdxForComp,iSccSimEqMapping), List.last);
        //print("Simcodeeq idc: " + stringDelimitList(List.map(simEqIdc, intString), ",") + "\n");
        //simEqIdc = List.sort(simEqIdc,intGt);

        newTask = HpcOmSimCode.CALCTASK(weighting,index,calcTime,threadFinishTime,threadId,simEqIdc);
        threadTasks = newTask::threadTasks;
        allThreadTasks = arrayUpdate(allThreadTasks,threadId,threadTasks);
        //print("Successors: " + stringDelimitList(List.map(successorIdc, intString), ",") + "\n");
        //add all successors with refcounter = 1
        (allCalcTasks,tmpNodeList) = updateRefCounterBySuccessorIdc(allCalcTasks,successorIdc,{});
        tmpNodeList = listAppend(tmpNodeList, rest);
        tmpNodeList = List.sort(tmpNodeList, compareTasksByWeighting);
        ((_,newTaskRefCount)) = arrayGet(allCalcTasks,index);
        arrayUpdate(allCalcTasks,index,(newTask,newTaskRefCount));
        tmpSchedule = createExtSchedule1(tmpNodeList,iThreadAssignments,iTaskGraph, iTaskGraphT, iCommCosts, iCompTaskMapping, iSccSimEqMapping, iSimVarMapping, iLockWithPredecessorHandler, HpcOmSimCode.THREADSCHEDULE(allThreadTasks,outgoingDepTasks,{},allCalcTasks));
      then tmpSchedule;
    case((head as HpcOmSimCode.CALCTASK(weighting=weighting,index=index,calcTime=calcTime,eqIdc=(eqIdc as firstEq::_)))::rest,_,_,_,_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE(threadTasks=allThreadTasks,outgoingDepTasks=outgoingDepTasks,allCalcTasks=allCalcTasks))
      equation
        (successors, successorIdc) = getSuccessorsByTask(head, iTaskGraph, allCalcTasks);
        //print("Handle task " + intString(index) + " with 0 child nodes and " + intString(listLength(successorIdc)) + " parent nodes.\n");
        //print("Parents: {" + stringDelimitList(List.map(successorIdc, intString), ",") + "}\n");

        //find thread for scheduling
        threadId = arrayGet(iThreadAssignments,index);
        threadFinishTime = -1.0;
        threadTasks = arrayGet(allThreadTasks,threadId);

        simEqIdc = List.flatten(List.map1(eqIdc,getSimEqSysIdxForComp,iSccSimEqMapping));
        //simEqIdc = List.sort(simEqIdc,intGt);

        newTask = HpcOmSimCode.CALCTASK(weighting,index,calcTime,threadFinishTime,threadId,simEqIdc);
        allThreadTasks = arrayUpdate(allThreadTasks,threadId,newTask::threadTasks);
        //print("Successors: " + stringDelimitList(List.map(successorIdc, intString), ",") + "\n");
        //add all successors with refcounter = 1
        (allCalcTasks,tmpNodeList) = updateRefCounterBySuccessorIdc(allCalcTasks,successorIdc,{});
        tmpNodeList = listAppend(tmpNodeList, rest);
        tmpNodeList = List.sort(tmpNodeList, compareTasksByWeighting);
        ((_,newTaskRefCount)) = arrayGet(allCalcTasks,index);
        arrayUpdate(allCalcTasks,index,(newTask,newTaskRefCount));
        tmpSchedule = createExtSchedule1(tmpNodeList,iThreadAssignments,iTaskGraph, iTaskGraphT, iCommCosts, iCompTaskMapping, iSccSimEqMapping, iSimVarMapping, iLockWithPredecessorHandler, HpcOmSimCode.THREADSCHEDULE(allThreadTasks,outgoingDepTasks,{},allCalcTasks));
      then tmpSchedule;
    case({},_,_,_,_,_,_,_,_,_) then iSchedule;
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
public function TDS_schedule "author: Waurich TUD 2015-05
  task duplication schedule by Samantha Ranaweera and Dharma P. Agrawal,
  see: 'A Task Duplication Based Scheduling Algorithm for Heterogeneous Systems'
  or 'A Scalable Task Duplication Based Scheduling Algorithm for Heterogeneous Systems'
  including slight adaptations from my side, since in reality, nothing is exactly the same like the smart guys thought of.
  notation: est:earliest starting time, ect: earliest completion time, last:latest allowable starting time, lact: latest allowable completion time, fpred:favourite predecessor"
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer numProc;
  input array<list<Integer>> iSccSimEqMapping;
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
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
  array<HpcOmTaskGraph.Communications> commCosts;
  array<list<Integer>> inComps;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(commCosts=commCosts,inComps=inComps) := iTaskGraphMeta;
  //compute the necessary node parameters
  size := arrayLength(iTaskGraph);
  taskGraphT := AdjacencyMatrix.transposeAdjacencyMatrix(iTaskGraph,size);
  (_,_,ectArray) := computeGraphValuesBottomUp(iTaskGraph,iTaskGraphMeta);
  (_,lastArray,lactArray,tdsLevelArray) := computeGraphValuesTopDown(iTaskGraph,iTaskGraphMeta);
  fpredArray := computeFavouritePred(iTaskGraph,iTaskGraphMeta,ectArray); //the favourite predecessor of each node
  (levels,queue) := quicksortWithOrder(arrayList(tdsLevelArray));
  initClusters := TDS_InitialCluster(iTaskGraph,taskGraphT,iTaskGraphMeta,lastArray,lactArray,fpredArray,queue);
  //print("initClusters:\n"+stringDelimitList(List.map(initClusters,intListString),"\n")+"\n");
  (oSchedule,oSimCode,oTaskGraph,oTaskGraphMeta,oSccSimEqMapping) := TDS_schedule1(initClusters,iTaskGraph,taskGraphT,iTaskGraphMeta,tdsLevelArray,numProc,iSccSimEqMapping,iSimCode,commCosts,inComps,iSimVarMapping);
end TDS_schedule;

protected function insertLocksInSchedule
  input HpcOmSimCode.Schedule iSchedule;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input array<Integer> taskAss;
  input array<list<Integer>> procAss;
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  output HpcOmSimCode.Schedule oSchedule;
protected
  array<list<HpcOmSimCode.Task>> threadTasks;
  list<list<HpcOmSimCode.Task>> threads;
  list<HpcOmSimCode.Task> outgoingDepTasks;
  array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
algorithm
  HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,allCalcTasks=allCalcTasks) := iSchedule;
  threads := arrayList(threadTasks);
  ((threads,outgoingDepTasks)) := List.fold(threads,function insertLocksInSchedule1(
    iTaskGraphTransposed=(iTaskGraph,iTaskGraphT),
    taskProcAss=(taskAss,procAss),
    iAllCalcTasks=allCalcTasks,
    iCommCosts=iCommCosts,
    iCompTaskMapping=iCompTaskMapping,
    iSimVarMapping=iSimVarMapping),
    ({},{}));
  threads := List.filterOnFalse(threads,listEmpty);
  threads := List.map(threads,listReverse);
  threads := listReverse(threads);
  threadTasks := listArray(threads);
  outgoingDepTasks := List.unique(outgoingDepTasks);
  oSchedule := HpcOmSimCode.THREADSCHEDULE(threadTasks, outgoingDepTasks,{},allCalcTasks);
end insertLocksInSchedule;

protected function insertLocksInSchedule1
  input list<HpcOmSimCode.Task> threadsIn;
  input tuple<HpcOmTaskGraph.TaskGraph, HpcOmTaskGraph.TaskGraph> iTaskGraphTransposed; //<iTaskGraph, iTaskGraphT>
  input tuple<array<Integer>, array<list<Integer>>> taskProcAss; //<taskAss, procAss>
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllCalcTasks;
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  input tuple<list<list<HpcOmSimCode.Task>>,list<HpcOmSimCode.Task>> foldIn; //<threads, outgoingDepTasks>
  output tuple<list<list<HpcOmSimCode.Task>>,list<HpcOmSimCode.Task>> foldOut;
algorithm
  foldOut := match(threadsIn,iTaskGraphTransposed,taskProcAss,iAllCalcTasks,iCommCosts,iCompTaskMapping,iSimVarMapping,foldIn)
    local
      HpcOmTaskGraph.TaskGraph iTaskGraph, iTaskGraphT;
      Integer idx,thr;
      list<Integer> preds,succs,predThr,succThr;
      list<HpcOmSimCode.Task> thread,rest,relLocks,assLocks,tasks;
      list<list<HpcOmSimCode.Task>> threads;
      HpcOmSimCode.Task task;
      list<HpcOmSimCode.Task> outgoingDepTasks;
      array<Integer> taskAss;
      array<list<Integer>> procAss;
    case({},_,_,_,_,_,_,(threads,outgoingDepTasks))
      equation
        threads = {}::threads;
      then ((threads,outgoingDepTasks));
    case(HpcOmSimCode.CALCTASK(index=idx,threadIdx=thr)::rest,(iTaskGraph,iTaskGraphT),(taskAss,_),_,_,_,_,(threads,outgoingDepTasks))
      equation
        task = listHead(threadsIn);
        //print("node "+intString(idx)+"\n");
        preds = arrayGet(iTaskGraphT,idx);
        succs = arrayGet(iTaskGraph,idx);
        //print("all preds "+intListString(preds)+"\n");
        //print("all succs "+intListString(succs)+"\n");
        predThr = List.map1(preds,Array.getIndexFirst,taskAss);
        succThr = List.map1(succs,Array.getIndexFirst,taskAss);
        (_,preds) = List.filter1OnTrueSync(predThr,intNe,thr,preds);
        (_,succs) = List.filter1OnTrueSync(succThr,intNe,thr,succs);
        //print("other preds "+intListString(preds)+"\n");
        //print("other succs "+intListString(succs)+"\n");
        //print("assLockStrs "+stringDelimitList(assLockStrs,"  ;  ")+"\n");
        //print("relLockStrs "+stringDelimitList(relLockStrs,"  ;  ")+"\n");
        assLocks = List.map6(preds,createDepTaskByTaskIdc,idx,iAllCalcTasks,false,iCommCosts,iCompTaskMapping,iSimVarMapping);
        relLocks = List.map6(succs,createDepTaskByTaskIdc,idx,iAllCalcTasks,true,iCommCosts,iCompTaskMapping,iSimVarMapping);
        //tasks = task::assLocks;
        tasks = listAppend(relLocks,{task});
        tasks = listAppend(tasks,assLocks);
        thread = if not listEmpty(threads) then listHead(threads) else {};
        thread = listAppend(tasks,thread);
        threads = if not listEmpty(threads) then List.replaceAt(thread,1,threads) else {thread};
        //_ = printThreadSchedule(thread,thr);
        outgoingDepTasks = listAppend(relLocks,outgoingDepTasks);
        outgoingDepTasks = listAppend(assLocks,outgoingDepTasks);
        ((threads,outgoingDepTasks)) = insertLocksInSchedule1(rest,iTaskGraphTransposed,taskProcAss,iAllCalcTasks,iCommCosts,iCompTaskMapping,iSimVarMapping,(threads,outgoingDepTasks));
      then ((threads,outgoingDepTasks));
  end match;
end insertLocksInSchedule1;

protected function TDS_schedule1 "author: Waurich TUD 2014-05
  Takes the initial Cluster and compactes or duplicates them to the given number of threads."
  input list<list<Integer>> clustersIn;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Real> TDSLevel;
  input Integer numProc;
  input array<list<Integer>> iSccSimEqMapping;
  input SimCode.SimCode iSimCode;
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  output HpcOmSimCode.Schedule oSchedule;
  output SimCode.SimCode oSimCode;
  output HpcOmTaskGraph.TaskGraph oTaskGraph;
  output HpcOmTaskGraph.TaskGraphMeta oTaskGraphMeta;
  output array<list<Integer>> oSccSimEqMapping;
algorithm
  (oSchedule,oSimCode,oTaskGraph,oTaskGraphMeta,oSccSimEqMapping) := matchcontinue(clustersIn,iTaskGraph,iTaskGraphT,iTaskGraphMeta,TDSLevel,numProc,iSccSimEqMapping,iSimCode,iCommCosts,iCompTaskMapping,iSimVarMapping)
    local
      Integer sizeTasks, numDupl, threadIdx, compIdx, simVarIdx, simEqSysIdx, taskIdx, lsIdx, nlsIdx, mIdx;
      array<Integer> taskAss,taskDuplAss,nodeMark,newIdxAss;
      array<list<Integer>> procAss, sccSimEqMap, inComps, comps;
      array<tuple<Integer,Real>> exeCosts;
      array<HpcOmTaskGraph.Communications> commCosts;
      array<tuple<Integer,Integer,Integer>> varCompMapping,eqCompMapping,mapDupl;
      tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> idcs;
      list<Integer> order;
      array<String> compNames, compDescs;
      list<list<Integer>> clusters, duplSccSimEqMap, duplComps;
      HpcOmSimCode.Schedule schedule;
      SimCode.ModelInfo modelInfo;
      HpcOmTaskGraph.TaskGraph taskGraph, taskGraphT;
      HpcOmTaskGraph.TaskGraphMeta meta;
      SimCode.SimCode simCode;
      SimCodeVar.SimVars simVars;
      list<SimCodeVar.SimVar> algVars;
      array<list<HpcOmSimCode.Task>> threadTask;
      list<HpcOmSimCode.Task> removeLocks;
      list<list<SimCode.SimEqSystem>> odes;
      list<SimCode.SimEqSystem> jacobianEquations;
      array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
      array<list<Integer>> compParamMapping;
      array<HpcOmTaskGraph.ComponentInfo> compInformations;
    case(_,_,_,_,_,_,_,_,_,_,_)
      equation
        // we need cluster duplication, repeat until numProc=num(clusters)
        true = listLength(clustersIn) < numProc;
        print("There are less initial clusters than processors. we need duplication, but since this is a rare case, it is not done. Less processors are used.\n");
        clusters = List.map(clustersIn,listReverse);
        Flags.setConfigInt(Flags.NUM_PROC,listLength(clustersIn));
        (schedule,simCode,taskGraph,meta,sccSimEqMap) = TDS_schedule1(clusters,iTaskGraph,iTaskGraphT,iTaskGraphMeta,TDSLevel,listLength(clustersIn),iSccSimEqMapping,iSimCode,iCommCosts,iCompTaskMapping,iSimVarMapping);
      then
        (schedule,simCode,taskGraph,meta,sccSimEqMap);
    case(_,_,_,_,_,_,_,_,_,_,_)
      equation
        // we need cluster compaction, repeat until numProc=num(clusters)
        true = listLength(clustersIn) > numProc;
        clusters = TDS_CompactClusters(clustersIn,iTaskGraph,iTaskGraphMeta,TDSLevel,numProc);
        (schedule,simCode,taskGraph,meta,sccSimEqMap) = TDS_schedule1(clusters,iTaskGraph,iTaskGraphT,iTaskGraphMeta,TDSLevel,numProc,iSccSimEqMapping,iSimCode,iCommCosts,iCompTaskMapping,iSimVarMapping);
      then
        (schedule,simCode,taskGraph,meta,sccSimEqMap);
    case(_,_,_,_,_,_,_,_,_,_,_)
      equation
        // the clusters can be scheduled,
        true = listLength(clustersIn) == numProc;
        // order the tasks in the clusters
        clusters = List.map1(clustersIn,TDS_SortCompactClusters,TDSLevel);
        //print("clusters:\n"+stringDelimitList(List.map(clusters,intListString),"\n")+"\n");

        // extract object stuff
        SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(vars=simVars), odeEquations=odes) = iSimCode;
        SimCodeVar.SIMVARS(algVars=algVars) = simVars;
        HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,varCompMapping=varCompMapping,eqCompMapping=eqCompMapping,compParamMapping=compParamMapping,compNames=compNames,compDescs=compDescs,exeCosts=exeCosts,commCosts=commCosts,nodeMark=nodeMark,compInformations=compInformations) = iTaskGraphMeta;
        /*
        //dumping stuff-------------------------
        print("simCode1 \n");
        SimCodeUtil.dumpSimCode(iSimCode);
        print("sccSimEqMap1\n");
        HpcOmSimCodeMain.dumpSccSimEqMapping(iSccSimEqMapping);
        print("inComps1\n");
        HpcOmSimCodeMain.dumpSccSimEqMapping(inComps);
        //--------------------------------------
*/
        // prepare everything  in order to create new variables and equations for the duplicated tasks
        sizeTasks = List.fold(List.map(clusters,listLength),intAdd,0);
        taskAss = arrayCreate(sizeTasks,-1);
        procAss = arrayCreate(listLength(clusters),{});
        taskGraph = arrayCreate(sizeTasks,{});
        taskDuplAss = arrayCreate(sizeTasks,-1); // the original task for every task (for not duplicated tasks, its itself)
        threadTask = arrayCreate(numProc,{});
        allCalcTasks = arrayCreate(sizeTasks, (HpcOmSimCode.TASKEMPTY(),0));
        schedule = HpcOmSimCode.THREADSCHEDULE(threadTask,{},{},allCalcTasks);
        duplSccSimEqMap = {};  // a list that is later appended to the sccSimEqMapping
        duplComps = {}; // a list that is later appended to the inComps
        threadIdx = 1;
        compIdx = arrayLength(iSccSimEqMapping)+1;  // the next available component index
        taskIdx = arrayLength(iTaskGraph)+1;
        simVarIdx = List.fold(List.map(algVars,SimCodeFunctionUtil.varIndex),intMax,0)+1;// the next available simVar index
        simEqSysIdx = SimCodeUtil.getMaxSimEqSystemIndex(iSimCode)+1;// the next available simEqSys index
        lsIdx = List.fold(List.map(List.flatten(odes),SimCodeUtil.getLSindex),intMax,0)+1;// the next available linear system index
        nlsIdx = List.fold(List.map(List.flatten(odes),SimCodeUtil.getNLSindex),intMax,0)+1;// the next available nonlinear system index
        mIdx = List.fold(List.map(List.flatten(odes),SimCodeUtil.getMixedindex),intMax,0)+1;// the next available mixed system  index

        //traverse the clusters and duplicate tasks if needed
        (taskAss,procAss,taskGraph,taskDuplAss,idcs,simCode,schedule,duplSccSimEqMap,duplComps) = TDS_duplicateTasks(clusters,taskAss,procAss,(threadIdx,taskIdx,compIdx,simVarIdx,simEqSysIdx,lsIdx,nlsIdx,mIdx),iTaskGraph,iTaskGraphT,taskGraph,taskDuplAss,iTaskGraphMeta,iSimCode,schedule,iSccSimEqMapping,duplSccSimEqMap,duplComps);

        //update stuff
        simCode = TDS_updateModelInfo(simCode,idcs);
        numDupl = List.fold(List.map(duplComps,listLength),intAdd,0);
        procAss = Array.map(procAss,listReverse);
        sccSimEqMap = arrayAppend(iSccSimEqMapping,listArray(listReverse(duplSccSimEqMap)));
        comps = arrayAppend(inComps,listArray(listReverse(duplComps)));
        varCompMapping = arrayAppend(varCompMapping,arrayCreate(numDupl,(0,0,0)));
        eqCompMapping = arrayAppend(eqCompMapping,arrayCreate(numDupl,(0,0,0)));
        compParamMapping = arrayAppend(compParamMapping,arrayCreate(numDupl,{}));
        compNames = arrayAppend(compNames,arrayCreate(numDupl,"duplicated"));
        compDescs = arrayAppend(compDescs,arrayCreate(numDupl,"duplicated"));
        exeCosts = arrayAppend(exeCosts,arrayCreate(numDupl,(1,1.0)));
        nodeMark = arrayAppend(nodeMark,arrayCreate(numDupl,-1));
        meta = HpcOmTaskGraph.TASKGRAPHMETA(comps,varCompMapping,eqCompMapping,compParamMapping,compNames,compDescs,exeCosts,commCosts,nodeMark,compInformations);
        //assign new simEqSysIndexes
        newIdxAss = arrayCreate(SimCodeUtil.getMaxSimEqSystemIndex(simCode),-1);
        (simCode,newIdxAss) = TDS_assignNewSimEqSysIdxs(simCode,newIdxAss);

        // insert Locks
        taskGraphT = AdjacencyMatrix.transposeAdjacencyMatrix(taskGraph,arrayLength(taskGraph));
        schedule = insertLocksInSchedule(schedule,taskGraph,taskGraphT,taskAss,procAss,iCommCosts,iCompTaskMapping,iSimVarMapping);
        schedule = TDS_replaceSimEqSysIdxsInSchedule(schedule,newIdxAss);
/*
        //dumping stuff-------------------------
        print("simCode 2\n");
        SimCodeUtil.dumpSimCode(simCode);
        print("sccSimEqMap2\n");
        HpcOmSimCodeMain.dumpSccSimEqMapping(sccSimEqMap);
        print("inComps2\n");
        HpcOmSimCodeMain.dumpSccSimEqMapping(comps);
        print("the taskAss2: "+stringDelimitList(List.map(arrayList(taskAss),intString),"\n")+"\n");
        print("the procAss2: "+stringDelimitList(List.map(arrayList(procAss),intListString),"\n")+"\n");
        printSchedule(schedule);
        //HpcOmTaskGraph.printTaskGraph(taskGraph);
        //--------------------------------------
*/
      then
        (schedule,simCode,taskGraph,meta,sccSimEqMap);
    else
      equation
        print("TDS_schedule1 failed!\n");
      then fail();
  end matchcontinue;
end TDS_schedule1;

protected function TDS_replaceSimEqSysIdxsInSchedule "author: Waurich TUD 2014-07
  Replaces the simEqSys indexes with the assigned ones in a schedule."
  input HpcOmSimCode.Schedule scheduleIn;
  input array<Integer> assIn;
  output HpcOmSimCode.Schedule scheduleOut;
algorithm
  scheduleOut := match(scheduleIn,assIn)
    local
      array<list<HpcOmSimCode.Task>> threadTasks;
      list<HpcOmSimCode.Task> outgoingDepTasks;
      list<HpcOmSimCode.Task> scheduledTasks;
      array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
  case(HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,outgoingDepTasks=outgoingDepTasks,scheduledTasks=scheduledTasks,allCalcTasks=allCalcTasks),_)
    equation
      scheduledTasks = List.map1(scheduledTasks,TDS_replaceSimEqSysIdxsInTask,assIn);
      threadTasks = Array.map1(threadTasks,TDS_replaceSimEqSysIdxsInTaskLst,assIn);
    then HpcOmSimCode.THREADSCHEDULE(threadTasks,outgoingDepTasks,scheduledTasks,allCalcTasks);
  end match;
end TDS_replaceSimEqSysIdxsInSchedule;

protected function TDS_replaceSimEqSysIdxsInTask "author: Waurich TUD 2014-07
  Replaces the simEqSys indexes with the assigned ones in a tasks."
  input HpcOmSimCode.Task taskIn;
  input array<Integer> assIn;
  output HpcOmSimCode.Task taskOut;
algorithm
  taskOut := matchcontinue(taskIn,assIn)
    local
      Integer weighting,index,threadIdx;
      Real calcTime,timeFinished;
      list<Integer> eqIdc;
  case(HpcOmSimCode.CALCTASK(weighting=weighting,index=index,calcTime=calcTime,timeFinished=timeFinished,threadIdx=threadIdx,eqIdc=eqIdc),_)
    equation
      eqIdc = List.map1(eqIdc,Array.getIndexFirst,assIn);
    then HpcOmSimCode.CALCTASK(weighting,index,calcTime,timeFinished,threadIdx,eqIdc);
  else taskIn;
  end matchcontinue;
end TDS_replaceSimEqSysIdxsInTask;

protected function TDS_replaceSimEqSysIdxsInTaskLst "author: Waurich TUD 2014-07
  Replaces the simEqSys indexes with the assigned ones in a list of tasks."
  input list<HpcOmSimCode.Task> taskLstIn;
  input array<Integer> assIn;
  output list<HpcOmSimCode.Task> taskLstOut;
algorithm
  taskLstOut := List.map1(taskLstIn,TDS_replaceSimEqSysIdxsInTask,assIn);
end TDS_replaceSimEqSysIdxsInTaskLst;

protected function TDS_assignNewSimEqSysIdxs "author: Waurich TUD 2014-07
  Replaces the simEqSys indexes with new ones and built an assignemnt in the simCode."
  input SimCode.SimCode simCodeIn;
  input array<Integer> idxAssIn;
  output SimCode.SimCode simCodeOut = simCodeIn;
  output array<Integer> idxAssOut;
protected
  SimCode.ModelInfo modelInfo;
  SimCode.VarInfo varInfo;
  list<Option<SimCode.JacobianMatrix>> jacObts;
  list<SimCode.SimEqSystem> eqs;
  Integer idx;
  array<Integer> ass;
algorithm
  modelInfo := simCodeOut.modelInfo;
  varInfo := modelInfo.varInfo;

  //reassign new indexes
  (eqs, (idx, ass)) := List.mapFold(simCodeOut.initialEquations, TDS_replaceSimEqSysIndexWithUpdate, (1, idxAssIn));
  simCodeOut.initialEquations := eqs;
  (eqs, (idx, ass)) := List.mapFold(simCodeOut.allEquations, TDS_replaceSimEqSysIndexWithUpdate, (idx, ass));
  simCodeOut.allEquations := eqs;
  (eqs, (idx, ass)) := List.mapFold(simCodeOut.startValueEquations, TDS_replaceSimEqSysIndexWithUpdate, (idx, ass));
  simCodeOut.startValueEquations := eqs;
  (eqs, (idx, ass)) := List.mapFold(simCodeOut.nominalValueEquations, TDS_replaceSimEqSysIndexWithUpdate, (idx, ass));
  simCodeOut.nominalValueEquations := eqs;
  (eqs, (idx, ass)) := List.mapFold(simCodeOut.minValueEquations, TDS_replaceSimEqSysIndexWithUpdate, (idx, ass));
  simCodeOut.minValueEquations := eqs;
  (eqs, (idx, ass)) := List.mapFold(simCodeOut.maxValueEquations, TDS_replaceSimEqSysIndexWithUpdate, (idx, ass));
  simCodeOut.maxValueEquations := eqs;
  (eqs, (idx, ass)) := List.mapFold(simCodeOut.parameterEquations, TDS_replaceSimEqSysIndexWithUpdate, (idx, ass));
  simCodeOut.parameterEquations := eqs;
  (eqs, (idx, ass)) := List.mapFold(simCodeOut.algorithmAndEquationAsserts, TDS_replaceSimEqSysIndexWithUpdate, (idx, ass));
  simCodeOut.algorithmAndEquationAsserts := eqs;

  //for collected groups
  simCodeOut.odeEquations := List.mapList1_1(simCodeOut.odeEquations, TDS_replaceSimEqSysIndex, ass);
  simCodeOut.algebraicEquations := List.mapList1_1(simCodeOut.algebraicEquations, TDS_replaceSimEqSysIndex, ass);
  simCodeOut.equationsForZeroCrossings := List.map1(simCodeOut.equationsForZeroCrossings, TDS_replaceSimEqSysIndex, ass);

  jacObts := List.map(simCodeOut.jacobianMatrixes, Util.makeOption);
  jacObts := List.map1(jacObts, TDS_replaceSimEqSysIdxInJacobianMatrix, ass);
  simCodeOut.jacobianMatrixes := List.map(jacObts, Util.getOption);

  varInfo.numEquations := idx;
  modelInfo.varInfo := varInfo;
  simCodeOut.modelInfo := modelInfo;
  idxAssOut := ass;
end TDS_assignNewSimEqSysIdxs;

protected function TDS_replaceSimEqSysIndex "author: Waurich TUD 2014-07
  Replaces the index with the assigned index  in a simEqSystem."
  input SimCode.SimEqSystem simEqIn;
  input array<Integer> assIn;
  output SimCode.SimEqSystem simEqOut;
algorithm
  simEqOut := matchcontinue(simEqIn)
    local
      Integer newIdx, oldIdx;
      list<SimCode.SimEqSystem> eqs;
      Option<SimCode.JacobianMatrix> jacobianMatrix;
      SimCode.SimEqSystem simEqSys;
      SimCode.NonlinearSystem nlSystem;
      SimCode.LinearSystem lSystem;
    case (simEqSys as SimCode.SES_NONLINEAR(nlSystem=nlSystem as SimCode.NONLINEARSYSTEM(eqs=eqs,jacobianMatrix=jacobianMatrix)))
      equation
        eqs = List.map1(eqs,TDS_replaceSimEqSysIndex,assIn);
        oldIdx = SimCodeUtil.simEqSystemIndex(simEqIn);
        newIdx = arrayGet(assIn,oldIdx);
        jacobianMatrix = TDS_replaceSimEqSysIdxInJacobianMatrix(jacobianMatrix,assIn);
        nlSystem.jacobianMatrix = jacobianMatrix;
        nlSystem.index = newIdx;
        nlSystem.eqs = eqs;
        simEqSys.nlSystem = nlSystem;
    then simEqSys;
    case (simEqSys as SimCode.SES_LINEAR(lSystem=lSystem as SimCode.LINEARSYSTEM(residual=eqs,jacobianMatrix=jacobianMatrix)))
      equation
        eqs = List.map1(eqs,TDS_replaceSimEqSysIndex,assIn);
        oldIdx = SimCodeUtil.simEqSystemIndex(simEqIn);
        newIdx = arrayGet(assIn,oldIdx);
        jacobianMatrix = TDS_replaceSimEqSysIdxInJacobianMatrix(jacobianMatrix,assIn);
        lSystem.jacobianMatrix = jacobianMatrix;
        lSystem.index = newIdx;
        lSystem.residual = eqs;
        simEqSys.lSystem = lSystem;
   then simEqSys;
    case(_)
      equation
        oldIdx = SimCodeUtil.simEqSystemIndex(simEqIn);
        newIdx = arrayGet(assIn,oldIdx);
        simEqSys = SimCodeUtil.replaceSimEqSysIndex(simEqIn,newIdx);
   then simEqSys;
  end matchcontinue;
end TDS_replaceSimEqSysIndex;

protected function TDS_replaceSimEqSysIndexWithUpdate "author: Waurich TUD 2014-07
  Replaces the index with the new index and updates the assignment in a simEqSystem."
  input SimCode.SimEqSystem simEqIn;
  input tuple<Integer,array<Integer>> tplIn;
  output SimCode.SimEqSystem simEqOut;
  output tuple<Integer,array<Integer>> tplOut;
algorithm
  (simEqOut,tplOut) := matchcontinue(simEqIn,tplIn)
    local
      Integer newIdx, oldIdx;
      array<Integer> ass;
      SimCode.SimEqSystem simEqSys,cont;
      list<SimCode.SimEqSystem> eqs;
      list<DAE.ComponentRef> crefs;
      Option<SimCode.JacobianMatrix> jacobianMatrix;
      SimCode.NonlinearSystem nlSystem;
      SimCode.LinearSystem lSystem;
    case (simEqSys as SimCode.SES_NONLINEAR(nlSystem=nlSystem as SimCode.NONLINEARSYSTEM(index=oldIdx,eqs=eqs,crefs=crefs,jacobianMatrix=jacobianMatrix)),(newIdx,ass))
      equation
        (eqs,(newIdx,ass)) = List.mapFold(eqs,TDS_replaceSimEqSysIndexWithUpdate,(newIdx,ass));
        (jacobianMatrix,(newIdx,ass)) = TDS_replaceSimEqSysIdxInJacobianMatrixWithUpdate(jacobianMatrix,(newIdx,ass));
        ass = arrayUpdate(ass,oldIdx,newIdx);
        nlSystem.jacobianMatrix = jacobianMatrix;
        nlSystem.index = newIdx; nlSystem.eqs = eqs;
        simEqSys.nlSystem = nlSystem;
    then (simEqSys,(newIdx+1,ass));
    case (simEqSys as SimCode.SES_LINEAR(lSystem=lSystem as SimCode.LINEARSYSTEM(index=oldIdx,residual=eqs,jacobianMatrix=jacobianMatrix)),(newIdx,ass))
      equation
        (eqs,(newIdx,ass)) = List.mapFold(eqs,TDS_replaceSimEqSysIndexWithUpdate,(newIdx,ass));
        (jacobianMatrix,(newIdx,ass)) = TDS_replaceSimEqSysIdxInJacobianMatrixWithUpdate(jacobianMatrix,(newIdx,ass));
        ass = arrayUpdate(ass,oldIdx,newIdx);
        lSystem.jacobianMatrix = jacobianMatrix;
        lSystem.index = newIdx; lSystem.residual = eqs;
        simEqSys.lSystem = lSystem;
    then (simEqSys,(newIdx+1,ass));
    case (simEqSys as SimCode.SES_MIXED(index=oldIdx,cont=cont,discEqs=eqs),(newIdx,ass))
      equation
        (cont,(newIdx,ass)) = TDS_replaceSimEqSysIndexWithUpdate(cont,(newIdx,ass));
        (eqs,(newIdx,ass)) = List.mapFold(eqs,TDS_replaceSimEqSysIndexWithUpdate,(newIdx,ass));
        ass = arrayUpdate(ass,oldIdx,newIdx);
        simEqSys.cont = cont; simEqSys.discEqs = eqs;
   then (simEqSys,(newIdx+1,ass));
    case(_,(newIdx,ass))
      equation
        oldIdx = SimCodeUtil.simEqSystemIndex(simEqIn);
        ass = arrayUpdate(ass,oldIdx,newIdx);
        simEqSys = SimCodeUtil.replaceSimEqSysIndex(simEqIn,newIdx);
   then (simEqSys,(newIdx+1,ass));
  end matchcontinue;
end TDS_replaceSimEqSysIndexWithUpdate;

protected function TDS_replaceSimEqSysIdxInJacobianMatrixWithUpdate "author: Waurich TUD 2014-07
  Replaces the index with the new index and updates the assignment one in a jacobian matrix."
  input Option<SimCode.JacobianMatrix> jacIn;
  input tuple<Integer,array<Integer>> tplIn;
  output Option<SimCode.JacobianMatrix> jacOut;
  output tuple<Integer,array<Integer>> tplOut;
algorithm
  (jacOut,tplOut) := matchcontinue(jacIn,tplIn)
    local
      Integer maxCol,jacIdx,partIdx;
      list<SimCode.JacobianColumn> jacCols;
      list<SimCodeVar.SimVar> vars;
      String name;
      SimCode.SparsityPattern sparsity,sparsityT;
      list<list<Integer>> colCols;
      array<Integer> ass;
      Integer newIdx;
      Option<HashTableCrefSimVar.HashTable> crefToSimVarHTJacobian;
    case(SOME(SimCode.JAC_MATRIX(jacCols,vars,name,sparsity,sparsityT,colCols,maxCol,jacIdx,partIdx,crefToSimVarHTJacobian)),(newIdx,ass))
      equation
        (jacCols,(newIdx,ass)) = List.mapFold(jacCols,TDS_replaceSimEqSysIdxInJacobianColumnWithUpdate,(newIdx,ass));
   then (SOME(SimCode.JAC_MATRIX(jacCols,vars,name,sparsity,sparsityT,colCols,maxCol,jacIdx,partIdx,crefToSimVarHTJacobian)),(newIdx,ass));
   else (jacIn,tplIn);
  end matchcontinue;
end TDS_replaceSimEqSysIdxInJacobianMatrixWithUpdate;

protected function TDS_replaceSimEqSysIdxInJacobianColumnWithUpdate "author: Waurich TUD 2014-07
  Replaces the index with the new index and updates the assignment one in a jacobian column."
  input SimCode.JacobianColumn jacIn;
  input tuple<Integer,array<Integer>> tplIn;
  output SimCode.JacobianColumn jacOut;
  output tuple<Integer,array<Integer>> tplOut;
algorithm
  (jacOut,tplOut) := matchcontinue(jacIn,tplIn)
    local
      list<SimCode.SimEqSystem> simEqs;
      list<SimCodeVar.SimVar> simVars;
      Integer rowLen;
      array<Integer> ass;
      Integer newIdx;
    case (SimCode.JAC_COLUMN(simEqs,simVars,rowLen),(newIdx,ass))
      equation
        (simEqs,(newIdx,ass)) = List.mapFold(simEqs,TDS_replaceSimEqSysIndexWithUpdate,(newIdx,ass));
   then (SimCode.JAC_COLUMN(simEqs,simVars,rowLen),(newIdx,ass));
   else (jacIn,tplIn);
  end matchcontinue;
end TDS_replaceSimEqSysIdxInJacobianColumnWithUpdate;

protected function TDS_replaceSimEqSysIdxInJacobianMatrix "author: Waurich TUD 2014-07
  Replaces the index with the assigned one in a jacobian matrix."
  input Option<SimCode.JacobianMatrix> jacIn;
  input array<Integer> assIn;
  output Option<SimCode.JacobianMatrix> jacOut = jacIn;
algorithm
  jacOut := matchcontinue(jacIn)
    local
      SimCode.JacobianMatrix jacMatrix;
    case SOME(jacMatrix as SimCode.JAC_MATRIX())
      equation
        jacMatrix.columns = List.map1(jacMatrix.columns, TDS_replaceSimEqSysIdxInJacobianColumn, assIn);
   then SOME(jacMatrix);
   else jacIn;
  end matchcontinue;
end TDS_replaceSimEqSysIdxInJacobianMatrix;

protected function TDS_replaceSimEqSysIdxInJacobianColumn "author: Waurich TUD 2014-07
  Replaces the index with the assigned one in a jacobian column."
  input SimCode.JacobianColumn jacIn;
  input array<Integer> assIn;
  output SimCode.JacobianColumn jacOut = jacIn;
algorithm
  jacOut.columnEqns := List.map1(jacOut.columnEqns, TDS_replaceSimEqSysIndex, assIn);
end TDS_replaceSimEqSysIdxInJacobianColumn;

protected function TDS_updateModelInfo "
  updated information in the SimCode.ModelInfo e.g.the number of variables,numLS, numNLS,"
  input SimCode.SimCode simCodeIn;
  input tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> idcs;
  output SimCode.SimCode simCodeOut = simCodeIn;
protected
  Integer lsIdx, nlsIdx, mIdx;
  SimCode.ModelInfo modelInfo;
  SimCode.VarInfo varInfo;
algorithm
  // get the data
  (_, _, _, _, _, lsIdx, nlsIdx, mIdx) := idcs;
  modelInfo := simCodeIn.modelInfo;
  varInfo := modelInfo.varInfo;

  // get new values
  varInfo.numStateVars := listLength(modelInfo.vars.stateVars);
  varInfo.numAlgVars := listLength(modelInfo.vars.algVars);
  varInfo.numLinearSystems := if intEq(varInfo.numLinearSystems, 0) then 0 else lsIdx;
  varInfo.numNonLinearSystems := if intEq(varInfo.numNonLinearSystems, 0) then 0 else nlsIdx;
  //numMixedSystems := mIdx;
  //update objects

  modelInfo.varInfo := varInfo;
  simCodeOut.modelInfo := modelInfo;
end TDS_updateModelInfo;

protected function TDS_duplicateTasks "author: Waurich TUD 2014-05
  Traverses the clusters, duplicate the tasks that have been assigned to another thread before."
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
  (taskAssOut,procAssOut,taskGraphOut,taskDuplAssOut,idcsOut,simCodeOut,scheduleOut,duplSccSimEqMapOut,duplCompsOut) := match(clustersIn,taskAssIn,procAssIn,idcsIn,taskGraphOrig,taskGraphTOrig,taskGraphIn,taskDuplAssIn,iTaskGraphMeta,simCodeIn,scheduleIn,sccSimEqMappingIn,duplSccSimEqMapIn,duplCompsIn)
    local
      Integer threadIdx,compIdx,simVarIdx,simEqSysIdx,taskIdx,lsIdx,nlsIdx,mIdx;
      list<Integer> cluster;
      list<list<Integer>> rest, duplSccSimEqMap, duplComps;
      array<Integer> taskAss, taskDuplAss;
      array<list<Integer>> sccSimEqMap ,procAss;
      tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> idcs;
      BackendDAE.BackendDAE dae;
      BackendVarTransform.VariableReplacements repl;
      SimCode.SimCode simCode;
      HpcOmSimCode.Schedule schedule;
      HpcOmTaskGraph.TaskGraph taskGraph;
      list<HpcOmSimCode.Task> thread, outgoingDepTasks;
      array<list<HpcOmSimCode.Task>> threadTasks;
      list<list<SimCode.SimEqSystem>> odes;
      array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
    case({},_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
      then
        (taskAssIn,procAssIn,taskGraphIn,taskDuplAssIn,idcsIn,simCodeIn,scheduleIn,duplSccSimEqMapIn,duplCompsIn);
    case(cluster::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        repl = BackendVarTransform.emptyReplacements();
        //traverse the cluster and build schedule
        (taskAss,procAss,taskGraph,taskDuplAss,thread,(threadIdx,taskIdx,compIdx,simVarIdx,simEqSysIdx,lsIdx,nlsIdx,mIdx),simCode,duplSccSimEqMap,duplComps) = TDS_duplicateTasks1(cluster,clustersIn,repl,taskAssIn,procAssIn,{},idcsIn,taskGraphOrig,taskGraphTOrig,taskGraphIn,taskDuplAssIn,iTaskGraphMeta,simCodeIn,sccSimEqMappingIn,duplSccSimEqMapIn,duplCompsIn);
        SimCode.SIMCODE() = simCode;
        //print("the simEqSysts after cluster: "+intString(threadIdx)+" \n"+stringDelimitList(List.map(odes,SimCodeUtil.dumpSimEqSystemLst),"\n")+"\n");

        HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,outgoingDepTasks=outgoingDepTasks,allCalcTasks=allCalcTasks) = scheduleIn;
        threadTasks = arrayUpdate(threadTasks,threadIdx,listReverse(thread));
        schedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,outgoingDepTasks,{},allCalcTasks);
        threadIdx = threadIdx+1;
        (taskAss,procAss,taskGraph,taskDuplAss,idcs,simCode,schedule,duplSccSimEqMap,duplComps) = TDS_duplicateTasks(rest,taskAss,procAss,(threadIdx,taskIdx,compIdx,simVarIdx,simEqSysIdx,lsIdx,nlsIdx,mIdx),taskGraphOrig,taskGraphTOrig,taskGraph,taskDuplAss,iTaskGraphMeta,simCode,schedule,sccSimEqMappingIn,duplSccSimEqMap,duplComps);
      then
        (taskAssIn,procAssIn,taskGraph,taskDuplAss,idcs,simCode,schedule,duplSccSimEqMap,duplComps);
  end match;
end TDS_duplicateTasks;

protected function TDS_duplicateTasks1 "author: Waurich TUD 2014-05
  Traverses one cluster. No locks are added."
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
        (repl,taskAss,procAss,taskGraph,taskDuplAss,thread,idcs,simCode,duplSccSimEqMap,duplComps) = TDS_duplicateTasks2(node,allCluster,replIn,taskAssIn,procAssIn,threadIn,idcsIn,taskGraphOrig,taskGraphTOrig,taskGraphIn,taskDuplAssIn,iTaskGraphMeta,simCodeIn,sccSimEqMappingIn,duplSccSimEqMapIn,duplCompsIn);
        (taskAss,procAss,taskGraph,taskDuplAss,thread,idcs,simCode,duplSccSimEqMap,duplComps) = TDS_duplicateTasks1(rest,allCluster,repl,taskAss,procAss,thread,idcs,taskGraphOrig,taskGraphTOrig,taskGraph,taskDuplAss,iTaskGraphMeta,simCode,sccSimEqMappingIn,duplSccSimEqMap,duplComps);
      then (taskAss,procAss,taskGraph,taskDuplAss,thread,idcs,simCode,duplSccSimEqMap,duplComps);
    case(node::rest,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // the task is not yet assigned
        ass = arrayGet(taskAssIn,node);
        true = intEq(ass,-1);
        // assign task
        (threadIdx,_,_,_,_,_,_,_) = idcsIn;
        HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps) = iTaskGraphMeta;
        //print("node "+intString(node)+"\n" );
        taskAss = arrayUpdate(taskAssIn,node,threadIdx);
        taskLst = arrayGet(procAssIn,threadIdx);
        procAss = arrayUpdate(procAssIn,threadIdx,node::taskLst);
        comps = arrayGet(inComps,node);
        //print("comps :"+intListString(comps)+"\n");
        simEqsLst = List.map1(comps,Array.getIndexFirst,sccSimEqMappingIn);
        simEqs = List.flatten(simEqsLst);
        simEqs = listReverse(simEqs);
        //print("simEqs :"+intListString(simEqs)+"\n");

        //change the simEqSystems in odes and allEqs if there is a duplicated predecessor
        SimCode.SIMCODE(odeEquations=odes, allEquations=allEqs) = simCodeIn;
        simEqSysts = List.map1(simEqs,SimCodeUtil.getSimEqSysForIndex,List.flatten(odes));
        (simEqSysts,_) = replaceInSimEqSystemLst(simEqSysts,replIn);
        allEqs = replaceSimEqSystemLstWithSameIndex(simEqSysts,allEqs);
        odes = List.map1r(odes,replaceSimEqSystemLstWithSameIndex,simEqSysts);
        simCode = SimCodeUtil.replaceODEandALLequations(allEqs,odes,simCodeIn);

        //update taskGraph
        clTasks = listHead(allCluster);// the current cluster
        //print("clTasks :"+intListString(clTasks)+"\n");
        origPredTasks = arrayGet(taskGraphTOrig,node);
        (clPredTasks,origPredTasks,_) = List.intersection1OnTrue(origPredTasks,clTasks,intEq);
        //print("origPredTasks :"+intListString(origPredTasks)+"\n");
        pos = List.map1(clPredTasks,List.position,clTasks);
        clTasks = arrayGet(procAssIn,threadIdx);
        clTasks = listReverse(clTasks);  // the current cluster with duplicated taskIdcs
        //print("clTasks :"+intListString(clTasks)+"\n");
        clPredTasks = List.map1(pos,List.getIndexFirst,clTasks);
        //print("clPredTasks :"+intListString(clPredTasks)+"\n");
        (duplPredTasks,_,_) = List.intersection1OnTrue(clPredTasks,clTasks,intEq);
        //print("duplPredTasks :"+intListString(duplPredTasks)+"\n");
        taskGraph = List.fold1(duplPredTasks,Array.appendToElement,{node},taskGraphIn); // add edges from duplicated predecessors to task
        taskGraphOut = List.fold1(origPredTasks,Array.appendToElement,{node},taskGraph); // add edges from non duplicated predecessors to task

        task = HpcOmSimCode.CALCTASK(1,node,0.0,-1.0,threadIdx,simEqs);
        thread = task::threadIn;
        taskDuplAss = arrayUpdate(taskDuplAssIn,node,node);
        (taskAss,procAss,taskGraph,taskDuplAss,thread,idcs,simCode,duplSccSimEqMap,duplComps) = TDS_duplicateTasks1(rest,allCluster,replIn,taskAss,procAss,thread,idcsIn,taskGraphOrig,taskGraphTOrig,taskGraph,taskDuplAss,iTaskGraphMeta,simCode,sccSimEqMappingIn,duplSccSimEqMapIn,duplCompsIn);
      then (taskAss,procAss,taskGraph,taskDuplAss,thread,idcs,simCode,duplSccSimEqMap,duplComps);
  end matchcontinue;
end TDS_duplicateTasks1;

protected function TDS_duplicateTasks2 "
  Sets the information about the new task in simCode, dae, sccMapping, ect."
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
  list<Integer> comps,simVarSysIdcs,simVarSysIdcs2,simEqSysIdcs,simEqSysIdcs2,systSimEqSysIdcs2,simEqSysIdcsInit,thread,clTasks,origPredTasks,clPredTasks,duplPredTasks,pos;
  list<list<Integer>> simEqIdxLst,simVarIdxLst;
  array<list<Integer>> inComps;
  BackendVarTransform.VariableReplacements repl;
  HpcOmTaskGraph.TaskGraph taskGraph;
  SimCode.HashTableCrefToSimVar ht;
  SimCode.ModelInfo modelinfo;
  SimCodeVar.SimVars simVars;
  SimCode.SimCode simCode;
  list<BackendDAE.Equation> eqs;
  list<BackendDAE.Var> vars;
  list<DAE.ComponentRef> crefs,crefsDupl;
  list<list<DAE.ComponentRef>> crefLst;
  list<DAE.Exp> crefsDuplExp;
  list<SimCodeVar.SimVar> simVarLst,simVarDupl,algVars;
  list<SimCode.SimEqSystem> simEqSysts,simEqSystsDupl,systemSimEqSys,systemSimEqSysDupl,initEqs;
  list<list<SimCode.SimEqSystem>> odes;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps) := iTaskGraphMeta;
  SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(vars=simVars),odeEquations=odes,crefToSimVarHT=ht) := simCodeIn;
  (threadIdx,taskIdx,compIdx,simVarIdx,simEqSysIdx,lsIdx,nlsIdx,mIdx) := idcsIn;

  // get the vars(crefs) and equations of the node
  //print("node to duplicate "+intString(node)+"\n");
  comps := arrayGet(inComps,node);
  comps := listReverse(comps);
  //print("comps :"+intListString(comps)+"\n");
  //print("task :"+intString(taskIdx)+"\n");
  simEqIdxLst := List.map1(comps,Array.getIndexFirst,sccSimEqMappingIn);
  simEqSysIdcs := List.flatten(simEqIdxLst);
  //print("simEqSysIdcs :"+intListString(simEqSysIdcs)+"\n");

  crefLst := List.map1(simEqSysIdcs,SimCodeUtil.getAssignedCrefsOfSimEq,simCodeIn);
  crefs := List.flatten(crefLst);
  //print("crefs :\n"+stringDelimitList(List.map(crefs,ComponentReference.debugPrintComponentRefTypeStr),"\n")+"\n");
  simVarLst := List.map1(crefs,BaseHashTable.get,ht);

  // build the new crefs, new simVars
  numVars := listLength(simVarLst);
  simVarSysIdcs2 := List.intRange2(simVarIdx,simVarIdx+numVars-1);
  crefAppend := "_thr"+intString(threadIdx);
  crefsDupl := List.map1r(crefs,ComponentReference.appendStringLastIdent,crefAppend);
  //print("crefs new :\n"+stringDelimitList(List.map(crefsDupl,ComponentReference.debugPrintComponentRefTypeStr),"\n")+"\n");
  crefsDuplExp := List.map(crefsDupl,Expression.crefExp);
  simVarDupl := List.threadMap(crefsDupl,simVarLst,SimCodeUtil.replaceSimVarName);
  simVarDupl := List.threadMap(simVarSysIdcs2,simVarDupl,SimCodeUtil.replaceSimVarIndex);
  simCode := List.fold(simVarDupl,SimCodeUtil.addSimVarToAlgVars,simCodeIn);
  simVarIdx2 := simVarIdx + numVars;

  //update hashtable, create replacement rules and build new simEqSystems
  ht := List.fold(simVarDupl,HashTableCrefSimVar.addSimVarToHashTable,ht);
  repl := BackendVarTransform.addReplacements(replIn,crefs,crefsDuplExp,NONE());
  //BackendVarTransform.dumpReplacements(repl);
  simEqSysts := List.map1(simEqSysIdcs,SimCodeUtil.getSimEqSysForIndex,List.flatten(odes));
  //print("the simEqSysts to be duplicated "+SimCodeUtil.dumpSimEqSystemLst(simEqSysts)+"\n");

  numEqs := listLength(simEqSysts);
  simEqSysIdcs2 := List.intRange2(simEqSysIdx,simEqSysIdx+numEqs-1);
  //print("simEqSysIdcs2 :"+intListString(simEqSysIdcs2)+"\n");
  (simEqSystsDupl,_) := List.map1_2(simEqSysts,replaceExpsInSimEqSystem,repl);// replace the exps and crefs
  (simEqSystsDupl,(lsIdx,nlsIdx,mIdx)) := List.mapFold(simEqSystsDupl,replaceSystemIndex,(lsIdx,nlsIdx,mIdx));// udpate the indeces of th systems
  simEqSystsDupl := List.threadMap(simEqSystsDupl,simEqSysIdcs2,SimCodeUtil.replaceSimEqSysIndex);
  //print("the simEqSystsDupl "+SimCodeUtil.dumpSimEqSystemLst(simEqSystsDupl)+"\n");
  simEqSysIdx2 := simEqSysIdx + numEqs;

  //duplicate the equations inside a system of equations
  (simEqSystsDupl,simEqSysIdx2) := TDS_duplicateSystemOfEquations(simEqSystsDupl,simEqSysIdx2,repl,{});
  //print("the simEqSystsDupl after EqSys "+SimCodeUtil.dumpSimEqSystemLst(simEqSystsDupl)+"\n");

  // update sccSimEqmapping for the duplicated
  duplSccSimEqMapOut := listAppend(List.map(simEqSysIdcs2,List.create),duplSccSimEqMapIn);
  simCode := List.fold1(simEqSystsDupl,SimCodeUtil.addSimEqSysToODEquations,1,simCode);
  // set task in thread
  threadOut := HpcOmSimCode.CALCTASK(1,taskIdx,0.0,-1.0,threadIdx,simEqSysIdcs2)::threadIn;
  // add init eqs to simCode
  numInitEqs := listLength(crefs);
  simEqSysIdcsInit := List.intRange2(simEqSysIdx2,simEqSysIdx2+numInitEqs-1);
  initEqs := List.thread3Map(crefsDupl,crefs,simEqSysIdcsInit,makeSEScrefAssignment);
  //print("the initEqs "+SimCodeUtil.dumpSimEqSystemLst(initEqs)+"\n");
  simCode := List.fold(initEqs,SimCodeUtil.addSimEqSysToInitialEquations,simCode);
  simEqSysIdx3 := simEqSysIdx2 + numInitEqs;

  SimCode.SIMCODE(odeEquations=odes) := simCode;
  //print("the simEqSysts after cluster: "+intString(threadIdx)+"_"+intString(node)+" \n"+stringDelimitList(List.map(odes,SimCodeUtil.dumpSimEqSystemLst),"\n")+"\n");

  //update duplSccSimEqMap, duplComps, taskAss, procAss for the new duplicates
  taskAssOut := arrayUpdate(taskAssIn,taskIdx,threadIdx);
  thread := arrayGet(procAssIn,threadIdx);
  thread := taskIdx::thread;
  procAssOut := arrayUpdate(procAssIn,threadIdx,thread);
  comps := List.intRange2(compIdx,compIdx+listLength(comps)-1);
  //print("compsNew :"+intListString(comps)+"\n");
  compIdx := compIdx+listLength(comps);
  duplCompsOut := comps::duplCompsIn;

  // update taskDuplAss
  taskDuplAssOut := arrayUpdate(taskDuplAssIn,taskIdx,node);

  //update taskGraph
  clTasks := listHead(allCluster);// the current cluster
  //print("clTasks :"+intListString(clTasks)+"\n");
  origPredTasks := arrayGet(taskGraphTOrig,node);
  (clPredTasks,origPredTasks,_) := List.intersection1OnTrue(origPredTasks,clTasks,intEq);
  //print("origPredTasks :"+intListString(origPredTasks)+"\n");
  pos := List.map1(clPredTasks,List.position,clTasks);
  clTasks := arrayGet(procAssOut,threadIdx);
  clTasks := listReverse(clTasks);  // the current cluster with duplicated taskIdcs
  //print("clTasks :"+intListString(clTasks)+"\n");
  clPredTasks := List.map1(pos,List.getIndexFirst,clTasks);
  //print("clPredTasks :"+intListString(clPredTasks)+"\n");
  (duplPredTasks,_,_) := List.intersection1OnTrue(clPredTasks,clTasks,intEq);
  //print("duplPredTasks :"+intListString(duplPredTasks)+"\n");
  taskGraph := List.fold1(duplPredTasks,Array.appendToElement,{taskIdx},taskGraphIn); // add edges from duplicated predecessors to task
  taskGraphOut := List.fold1(origPredTasks,Array.appendToElement,{taskIdx},taskGraph); // add edges from non duplicated predecessors to task

  idcsOut := (threadIdx,taskIdx+1,compIdx,simVarIdx2,simEqSysIdx3,lsIdx,nlsIdx,mIdx);
  simCodeOut := simCode;
  replOut := repl;
end TDS_duplicateTasks2;

protected function TDS_duplicateSystemOfEquations
  input list<SimCode.SimEqSystem> simEqsIn;
  input Integer simEqSysIdxIn;
  input BackendVarTransform.VariableReplacements repl;
  input list<SimCode.SimEqSystem> simEqsFold;
  output list<SimCode.SimEqSystem> simEqsOut;
  output Integer simEqSysIdxOut;
algorithm
  (simEqsOut,simEqSysIdxOut) := matchcontinue(simEqsIn,simEqSysIdxIn,repl,simEqsFold)
    local
      Integer simEqSysIdx, numEqs;
      list<Integer> systSimEqSysIdcs2;
      SimCode.SimEqSystem simEqSys;
      list<SimCode.SimEqSystem> rest,duplicated,residual;
      SimCode.LinearSystem lSystem;
   case({},_,_,_)
     then (listReverse(simEqsFold),simEqSysIdxIn);
   case((simEqSys as SimCode.SES_LINEAR(lSystem=lSystem as SimCode.LINEARSYSTEM(residual=residual)))::rest,_,_,_)
     equation
       //print("the systemSimEqSys "+SimCodeUtil.dumpSimEqSystemLst(residual)+"\n");
       numEqs = listLength(residual);
       systSimEqSysIdcs2 = if intEq(numEqs,0) then {} else List.intRange2(simEqSysIdxIn,simEqSysIdxIn+numEqs-1);
       //print("systSimEqSysIdcs2 :"+intListString(systSimEqSysIdcs2)+"\n");
       (duplicated,_) = List.map1_2(residual,replaceExpsInSimEqSystem,repl);// replace the exps and crefs
       duplicated = List.threadMap(duplicated,systSimEqSysIdcs2,SimCodeUtil.replaceSimEqSysIndex);
       lSystem.residual = duplicated;
       simEqSys.lSystem = lSystem;
       //print("the systemSimEqSysDupl "+SimCodeUtil.dumpSimEqSystemLst(duplicated)+"\n");
       simEqSysIdx = simEqSysIdxIn + numEqs;
       (duplicated,simEqSysIdx)  = TDS_duplicateSystemOfEquations(rest,simEqSysIdx,repl,simEqSys::simEqsFold);
     then (duplicated,simEqSysIdx);
   else
     equation
       simEqSys::rest = simEqsIn;
       (duplicated,simEqSysIdx)  = TDS_duplicateSystemOfEquations(rest,simEqSysIdxIn,repl,simEqSys::simEqsFold);
     then (duplicated,simEqSysIdx);
  end matchcontinue;
end TDS_duplicateSystemOfEquations;

protected function makeSEScrefAssignment
  input DAE.ComponentRef lhs;
  input DAE.ComponentRef rhs;
  input Integer idx;
  output SimCode.SimEqSystem sesOut;
protected
  DAE.Type ty;
algorithm
  ty := ComponentReference.crefType(rhs);
  sesOut := SimCode.SES_SIMPLE_ASSIGN(idx,lhs,DAE.CREF(rhs,ty),DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
end makeSEScrefAssignment;

protected function replaceSimEqSystemLstWithSameIndex
  input list<SimCode.SimEqSystem> eqSystsIn;
  input list<SimCode.SimEqSystem> eqSysLstIn;
  output list<SimCode.SimEqSystem> eqSysLstOut;
algorithm
  eqSysLstOut := List.fold(eqSystsIn,replaceSimEqSystemWithSameIndex,eqSysLstIn);
end replaceSimEqSystemLstWithSameIndex;

protected function replaceSimEqSystemWithSameIndex "author: Waurich TUD 2014-06
  Replaces the simEqSystem with the same index in the eqSysLstIn."
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
      _ = SimCodeUtil.simEqSystemIndex(eqSysIn);
      pos = List.position1OnTrue(eqSysLstIn,SimCodeUtil.equationIndexEqual,eqSysIn);
      eqSysLst = List.replaceAt(eqSysIn,pos,eqSysLstIn);
    then eqSysLst;
    else eqSysLstIn;
  end matchcontinue;
end replaceSimEqSystemWithSameIndex;

protected function replaceSystemIndex "author: Waurich TUD 2014-04
  Replaces the index of the linear system, the index of the non-linear system or the index of the mixed systems with the given values."
  input SimCode.SimEqSystem simEqSysIn;
  input tuple<Integer,Integer,Integer> idcsIn;// lsIdx,nlsIdx,mIdx
  output SimCode.SimEqSystem simEqSysOut;
  output tuple<Integer,Integer,Integer> idcsOut;// lsIdx,nlsIdx,mIdx
algorithm
  (simEqSysOut,idcsOut) := match(simEqSysIn)
    local
      Integer lsIdx,nlsIdx,mIdx;
      SimCode.SimEqSystem simEqSys;
      SimCode.LinearSystem lSystem;
      SimCode.NonlinearSystem nlSystem;
    case (simEqSys as SimCode.SES_LINEAR(lSystem=lSystem))
      equation
        (lsIdx,nlsIdx,mIdx) = idcsIn;
        lSystem.indexLinearSystem = lsIdx;
        simEqSys.lSystem = lSystem;
      then (simEqSys,(lsIdx+1,nlsIdx,mIdx));

    case (simEqSys as SimCode.SES_NONLINEAR(nlSystem=nlSystem))
      equation
        (lsIdx,nlsIdx,mIdx) = idcsIn;
        nlSystem.indexNonLinearSystem = nlsIdx;
        simEqSys.nlSystem = nlSystem;
      then (simEqSys,(lsIdx,nlsIdx+1,mIdx));

    case (simEqSys as SimCode.SES_MIXED())
      equation
        (lsIdx,nlsIdx,mIdx) = idcsIn;
        simEqSys.indexMixedSystem = mIdx;
      then (simEqSys,(lsIdx,nlsIdx,mIdx+1));
    else (simEqSysIn,idcsIn);
  end match;
end replaceSystemIndex;

protected function replaceInSimEqSystemLst "author: Waurich TUD 2014-06
  Performs replacements on a list of SimCode.SimEqSystems."
  input list<SimCode.SimEqSystem> simEqSysLstIn;
  input BackendVarTransform.VariableReplacements replIn;
  output list<SimCode.SimEqSystem> simEqSysLstOut;
  output list<Boolean> changedOut;
algorithm
  (simEqSysLstOut,changedOut) := List.map1_2(simEqSysLstIn,replaceExpsInSimEqSystem,replIn);
end replaceInSimEqSystemLst;

protected function replaceExpsInSimEqSystem "author: Waurich TUD 2014-06
  Performs replacements on a simEqSystem structure."
  input SimCode.SimEqSystem simEqSysIn;
  input BackendVarTransform.VariableReplacements replIn;
  output SimCode.SimEqSystem simEqSysOut;
  output Boolean changedOut;
algorithm
    (simEqSysOut,changedOut) := matchcontinue(simEqSysIn)
    local
      Boolean changed,changed1,hasRepl;
      list<Boolean> bLst;
      DAE.ComponentRef cref;
      DAE.ElementSource source;
      DAE.Exp exp,lhs;
      SimCode.SimEqSystem simEqSys;
      SimCode.SimEqSystem cont;
      list<DAE.Exp> expLst, crefExps;
      list<DAE.ComponentRef> crefs;
      list<DAE.Statement> stmts;
      list<SimCode.SimEqSystem> simEqSysLst;
      list<SimCodeVar.SimVar> simVars;
      list<list<SimCode.SimEqSystem>> simEqSysLstLst;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
      list<tuple<DAE.Exp,list<SimCode.SimEqSystem>>> ifs;
      list<SimCode.SimEqSystem> elsebranch;
      SimCode.LinearSystem lSystem;
      SimCode.NonlinearSystem nlSystem;
      SimCode.SimEqSystem elseWhen;
    case (simEqSys as SimCode.SES_RESIDUAL())
      equation
        (exp,changed) = BackendVarTransform.replaceExp(simEqSys.exp,replIn,NONE());
        simEqSys.exp = exp;
    then (simEqSys,changed);
    case (simEqSys as SimCode.SES_SIMPLE_ASSIGN(cref=cref,exp=exp))
      equation
        hasRepl = BackendVarTransform.hasReplacement(replIn,cref);
        DAE.CREF(componentRef=cref) = if hasRepl then BackendVarTransform.getReplacement(replIn,cref) else DAE.CREF(cref,DAE.T_UNKNOWN_DEFAULT);
        (exp,changed) = BackendVarTransform.replaceExp(exp,replIn,NONE());
        simEqSys.cref = cref; simEqSys.exp = exp;
    then (simEqSys,changed or hasRepl);
    case (simEqSys as SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS(cref=cref,exp=exp))
      equation
        hasRepl = BackendVarTransform.hasReplacement(replIn,cref);
        DAE.CREF(componentRef=cref) = if hasRepl then BackendVarTransform.getReplacement(replIn,cref) else DAE.CREF(cref,DAE.T_UNKNOWN_DEFAULT);
        (exp,changed) = BackendVarTransform.replaceExp(exp,replIn,NONE());
        simEqSys.cref = cref; simEqSys.exp = exp;
    then (simEqSys,changed or hasRepl);
    case (simEqSys as SimCode.SES_ARRAY_CALL_ASSIGN(lhs=lhs,exp=exp))
      equation
        cref = Expression.expCref(lhs);
        hasRepl = BackendVarTransform.hasReplacement(replIn,cref);
        lhs = if hasRepl then BackendVarTransform.getReplacement(replIn,cref) else DAE.CREF(cref,DAE.T_UNKNOWN_DEFAULT);
        (exp,changed) = BackendVarTransform.replaceExp(exp,replIn,NONE());
        simEqSys.lhs = lhs; simEqSys.exp = exp;
    then (simEqSys,changed or hasRepl);
    case (simEqSys as SimCode.SES_IFEQUATION(ifbranches=ifs,elsebranch=elsebranch))
      equation
        expLst = List.map(ifs,Util.tuple21);
        (expLst,changed) = BackendVarTransform.replaceExpList(expLst,replIn,NONE());
        simEqSysLstLst = List.map(ifs,Util.tuple22);
        (simEqSysLstLst,_) = List.map1_2(simEqSysLstLst,replaceInSimEqSystemLst,replIn);
        ifs = List.threadMap(expLst,simEqSysLstLst,Util.makeTuple);
        (elsebranch,bLst) = List.map1_2(elsebranch,replaceExpsInSimEqSystem,replIn);
        changed = List.fold(bLst,boolOr,changed);
        simEqSys.ifbranches = ifs; simEqSys.elsebranch = elsebranch;
    then (simEqSys,changed);
    case (simEqSys as SimCode.SES_ALGORITHM(statements=stmts))
      equation
        (stmts,changed) = BackendVarTransform.replaceStatementLst(stmts,replIn,NONE(),{},false);
        simEqSys.statements = stmts;
    then (simEqSys,changed);
    case (simEqSys as SimCode.SES_LINEAR(lSystem=lSystem))
      equation
        (simVars,bLst) = List.map1_2(lSystem.vars,replaceCrefInSimVar,replIn);
        (expLst,changed) = BackendVarTransform.replaceExpList(lSystem.beqs,replIn,NONE());
        changed = List.fold(bLst,boolOr,changed);
        simJac = List.map1(lSystem.simJac,replaceInSimJac,replIn);
        lSystem.vars = simVars; lSystem.beqs = expLst; lSystem.simJac = simJac;
        simEqSys.lSystem = lSystem;
    then (simEqSys,changed);
    case (simEqSys as SimCode.SES_NONLINEAR(nlSystem=nlSystem))
      equation
        expLst = List.map(nlSystem.crefs,Expression.crefExp);
        (expLst,changed) = BackendVarTransform.replaceExpList(expLst,replIn,NONE());
        crefs = List.map(expLst,Expression.expCref);
        (simEqSysLst,bLst) = List.map1_2(nlSystem.eqs,replaceExpsInSimEqSystem,replIn);
        changed = changed or List.fold(bLst,boolOr,false);
        print("implement Jacobian replacement for SES_NONLINEAR in HpcOmScheduler.replaceExpsInSimEqSystems!\n");
        nlSystem.crefs = crefs; nlSystem.eqs = simEqSysLst;
        simEqSys.nlSystem = nlSystem;
    then (simEqSys,changed);
    case (simEqSys as SimCode.SES_MIXED(cont=cont,discVars=simVars,discEqs=simEqSysLst))
      equation
        (cont,changed) = replaceExpsInSimEqSystem(cont,replIn);
        (simVars,bLst) = List.map1_2(simVars,replaceCrefInSimVar,replIn);
        changed = List.fold(bLst,boolOr,changed);
        (simEqSysLst,bLst) = List.map1_2(simEqSysLst,replaceExpsInSimEqSystem,replIn);
        changed = List.fold(bLst,boolOr,changed);
        simEqSys.discVars = simVars; simEqSys.discEqs=simEqSysLst; simEqSys.cont = cont;
    then (simEqSys,changed);
    case (simEqSys as SimCode.SES_WHEN(conditions=crefs,whenStmtLst={BackendDAE.ASSIGN(left=lhs,right=exp,source=source)},elseWhen=NONE()))
      equation
        (crefExps,bLst) = List.map1_2(crefs,BackendVarTransform.replaceCref,replIn);
        crefs = List.map(crefExps,Expression.expCref);
        (lhs,changed) = BackendVarTransform.replaceExp(lhs,replIn, NONE());
        changed = List.fold(bLst,boolOr,changed);
        (exp,changed1) = BackendVarTransform.replaceExp(exp,replIn,NONE());
        changed = boolOr(changed,changed1);
        simEqSys.conditions = crefs; simEqSys.whenStmtLst = {BackendDAE.ASSIGN(lhs, exp, source)};
    then (simEqSys,changed);
    case (simEqSys as SimCode.SES_WHEN(conditions=crefs,whenStmtLst={BackendDAE.ASSIGN(left=lhs,right=exp,source=source)},elseWhen=SOME(elseWhen)))
      equation
        (crefExps,bLst) = List.map1_2(crefs,BackendVarTransform.replaceCref,replIn);
        crefs = List.map(crefExps,Expression.expCref);
        (lhs,changed) = BackendVarTransform.replaceExp(lhs,replIn, NONE());
        changed = List.fold(bLst,boolOr,changed);
        (exp,changed1) = BackendVarTransform.replaceExp(exp,replIn,NONE());
        changed = boolOr(changed,changed1);
        (simEqSys,changed1) = replaceExpsInSimEqSystem(simEqSys,replIn);
        changed = boolOr(changed,changed1);
        simEqSys.conditions = crefs; simEqSys.whenStmtLst = {BackendDAE.ASSIGN(lhs, exp, source)};
        simEqSys.elseWhen = SOME(elseWhen);
    then (simEqSys,changed);
  else
    equation
      print("replaceExpsInSimEqSystem failed\n");
    then fail();
  end matchcontinue;
end replaceExpsInSimEqSystem;

protected function replaceCrefInSimVar "author: Waurich TUD 2014-06
  Performs replacements on a simVar structure."
  input SimCodeVar.SimVar simVarIn;
  input BackendVarTransform.VariableReplacements replIn;
  output SimCodeVar.SimVar simVarOut = simVarIn;
  output Boolean changedOut;
protected
  DAE.ComponentRef name;
algorithm
  try
    if BackendVarTransform.hasReplacement(replIn, simVarIn.name) then
      DAE.CREF(componentRef=name) := BackendVarTransform.getReplacement(replIn, simVarIn.name);
      simVarOut.name := name;
      changedOut := true;
    else
      changedOut := false;
    end if;
  else
    changedOut := false;
  end try;
end replaceCrefInSimVar;

protected function replaceInSimJac "author: Waurich TUD 2014-04
  Replaces the row of a simJac."
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

protected function TDS_getTaskAssignment "author:Waurich TUD 2014-05
  Sets the assigned processor for each task."
  input Integer procIdx;
  input array<list<Integer>> clusterArrayIn;
  input array<Integer> taskAssIn;
protected
  array<Integer> taskAss;
  list<Integer> procTasks;
algorithm
  procTasks := arrayGet(clusterArrayIn,procIdx);
  List.map2_0(procTasks,Array.updateIndexFirst,procIdx,taskAssIn);
end TDS_getTaskAssignment;

protected function TDS_CompactClusters "author: Waurich TUD 2015-05
  Performs compaction to the cluster set. The least crowded (lowest exe costs) cluster is merged with the crowded cluster
  and so on. It is possible that several tasks are assigned to multiple threads. Thats because duplication is needed."
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
  clusterExeCosts := List.map1(clustersIn,TDS_computeClusterCosts,iTaskGraphMeta);
  (_,clusterOrder) := quicksortWithOrder(clusterExeCosts);
  clusterOrder := listReverse(clusterOrder);
  clusters := List.map1(clusterOrder,List.getIndexFirst,clustersIn);  // the clusters, sorted in descending order of their accumulated execution costs
  numMergeClusters := intMin(intDiv(listLength(clustersIn),2),intSub(listLength(clustersIn),numProc));
  (firstClusters,lastClusters) := List.split(clusters,numMergeClusters);
  (middleCluster,lastClusters) := List.split(lastClusters,intSub(listLength(lastClusters),numMergeClusters));
  lastClusters := listReverse(lastClusters);
  mergedClusters := List.threadMap(firstClusters,lastClusters,listAppend);
  clustersOut := listAppend(mergedClusters,middleCluster);
  //print("mergedClustersOut:\n"+stringDelimitList(List.map(clustersOut,intListString),"\n")+"\n");
end TDS_CompactClusters;

protected function TDS_SortCompactClusters "author: Waurich TUD 2014-05
  Sorts the tasks in the cluster to descending order of their tds level value."
  input list<Integer> clusterIn;
  input array<Real> tdsLevelIn;
  output list<Integer> clusterOut;
protected
  list<Integer> order, cluster;
  list<Real> tdsLevels;
algorithm
  cluster := List.unique(clusterIn);
  tdsLevels := List.map1(cluster,Array.getIndexFirst,tdsLevelIn);
  (_,order) := quicksortWithOrder(tdsLevels);
  order := listReverse(order);
  clusterOut :=List.map1(order,List.getIndexFirst,cluster);
end TDS_SortCompactClusters;

protected function TDS_computeClusterCosts "author: Waurich TUD 2014-05
  Accumulates the execution costs of all tasks in one cluster."
  input list<Integer> clusters;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  output Real costs;
protected
  list<Real> nodeCosts;
algorithm
  nodeCosts := List.map1(clusters,HpcOmTaskGraph.getExeCostReqCycles,iTaskGraphMeta);
  costs := List.fold(nodeCosts,realAdd,0.0);
end TDS_computeClusterCosts;

protected function TDS_InitialCluster "author: waurich TUD 2014-05
  Creates the initial Clusters for the task duplication scheduler."
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
  clustersOut := TDS_InitialCluster1(iTaskGraph,iTaskGraphT,iTaskGraphMeta,lastArrayIn,lactArrayIn,fpredArrayIn,rootNodes,taskAssignments,1,queue,{{}});
end TDS_InitialCluster;

protected function TDS_InitialCluster1 "author: waurich TUD 2014-05
  Implementation of function TDS_InitialCluster."
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
        clusters = List.filterOnFalse(clustersIn,listEmpty);
        clusters = List.map(clusters,listReverse);
      then clusters;
    case(_,_,_,_,_,_,_,_,_,front::rest,_)
      equation
        // the node is an rootNode
        true = List.isMemberOnTrue(front,rootNodes,intEq);
        //print("node (root): "+intString(front)+"\n");
        //assign rootNode to current thread and start a new thread(cluster)
        thread = listGet(clustersIn,currThread);
        thread = front::thread;
        clusters = List.replaceAt(thread,currThread,clustersIn);
        //print("cluster: "+intListString(thread)+"\n");
        clusters = listAppend(clusters,{{}});
        clusters = TDS_InitialCluster1(iTaskGraph,iTaskGraphT,iTaskGraphMeta,lastArrayIn,lactArrayIn,fpredArrayIn,rootNodes,taskAssIn,currThread+1,rest,clusters);
      then clusters;
    case(_,_,_,_,_,_,_,_,_,front::rest,_)
      equation
        // assign node, fpred is critical --> choose the fpred as next node
        fpred = arrayGet(fpredArrayIn,front);
        isCritical = TDSpredIsCritical(front,fpred,iTaskGraphMeta,lastArrayIn,lactArrayIn);
        true = isCritical;
        //print("node (new pred): "+intString(front)+"\n");
        //assign node from queue to a thread (in reversed order)
        thread = listGet(clustersIn,currThread);
        thread = front::thread;
        clusters = List.replaceAt(thread,currThread,clustersIn);
        //print("cluster: "+intListString(thread)+"\n");
        arrayUpdate(taskAssIn,front,currThread);
        // go to predecessor
        rest = List.removeOnTrue(fpred,intEq,rest);
        rest = fpred::rest;
        clusters = TDS_InitialCluster1(iTaskGraph,iTaskGraphT,iTaskGraphMeta,lastArrayIn,lactArrayIn,fpredArrayIn,rootNodes,taskAssIn,currThread,rest,clusters);
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
        clusters = List.replaceAt(thread,currThread,clustersIn);
        //print("cluster: "+intListString(thread)+"\n");
        arrayUpdate(taskAssIn,front,currThread);
        // check for other parents to get the next fpred
        parents = arrayGet(iTaskGraphT,front);
        parentsNofpred = List.removeOnTrue(fpred,intEq,parents);// choose not the fpred
        parentAssgmnts = List.map1(parentsNofpred,Array.getIndexFirst,taskAssIn);
        (_,unAssParents) = List.filter1OnTrueSync(parentAssgmnts,intEq,-1,parentsNofpred); // not yet assigned parents
        // if there are unassigned parents, use them, otherwise all parents including fpred. take the one with the least execution cost
        parents = if listEmpty(unAssParents) then parents else unAssParents;
        parentExeCost = List.map1(parents,HpcOmTaskGraph.getExeCostReqCycles,iTaskGraphMeta);
        maxExeCost = List.fold(parentExeCost,realMax,0.0);
        pos = List.position(maxExeCost,parentExeCost);
        fpred = listGet(parents,pos);
        // go to predecessor
        rest = List.removeOnTrue(fpred,intEq,rest);
        rest = fpred::rest;
        clusters = TDS_InitialCluster1(iTaskGraph,iTaskGraphT,iTaskGraphMeta,lastArrayIn,lactArrayIn,fpredArrayIn,rootNodes,taskAssIn,currThread,rest,clusters);
      then clusters;
    else
     equation
       print("TDS_InitialCluster1 failed\n");
     then
       fail();
  end matchcontinue;
end TDS_InitialCluster1;

protected function TDSpredIsCritical "
  Calculates the criteria if the predecessor is critical."
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
  commCosts := HpcOmTaskGraph.getCommCostTimeBetweenNodes(pred,node,iTaskGraphMeta);
  isCritical := realSub(lastNode,lactPred) <= commCosts;
end TDSpredIsCritical;

protected function computeFavouritePred "author: Waurich TUD 2014-05
  Gets the favourite Predecessors of each task. Needed for the task duplication scheduler."
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
  taskGraphT := AdjacencyMatrix.transposeAdjacencyMatrix(iTaskGraph,size);
  fpred := arrayCreate(size,-1);
  fpredOut := List.fold3(List.intRange(size),computeFavouritePred1,taskGraphT,iTaskGraphMeta,ect,fpred);
end computeFavouritePred;

protected function computeFavouritePred1 "author: Waurich TUD 2014-05
  Folding function for computeFavouritePred to traverse all nodes and get their favourite predecessors."
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
        false = listEmpty(parents);
        parentECTs = List.map1(parents,Array.getIndexFirst,ect);
        commCosts = List.map2(parents,HpcOmTaskGraph.getCommCostTimeBetweenNodes,nodeIdx,iTaskGraphMeta);
        costs = List.threadMap(parentECTs,commCosts,realAdd);
        maxCost = List.fold(costs,realMax,0.0);
        fpredPos = List.position(maxCost,costs);
        fpred = listGet(parents,fpredPos); // if there is no predecessor, the fpred value is 0
        fpredOut = arrayUpdate(fpredIn,nodeIdx,fpred);
      then fpredOut;
    case(_,_,_,_,_)
      equation
        parents = arrayGet(graphT,nodeIdx);
        true = listEmpty(parents);
        fpredOut = arrayUpdate(fpredIn,nodeIdx,0);
      then fpredOut;
  end matchcontinue;
end computeFavouritePred1;


//---------------------------------
// Partition Scheduler
//---------------------------------
public function createPartSchedule "author: Waurich TUD 2015-02
  Puts every independent partition into one thread with respect to the number of available processors."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer numProc;
  input array<list<Integer>> iSccSimEqMapping;
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  output HpcOmSimCode.Schedule oSchedule;
algorithm
  oSchedule := matchcontinue(iTaskGraph,iTaskGraphMeta,numProc,iSccSimEqMapping,iSimVarMapping)
    local
      Integer nTasks;
      list<Integer> rootNodes;
      array<Integer>  taskMap;
      array<Real> partitionCosts;
      array<list<Integer>> partitions, partMap;
      HpcOmTaskGraph.TaskGraph graphT;

      array<HpcOmTaskGraph.Communications> commCosts;
      array<list<Integer>> inComps;
      array<list<HpcOmSimCode.Task>> threadTask;
      array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
      HpcOmSimCode.Schedule schedule;
      list<Integer> order;
    case(_,HpcOmTaskGraph.TASKGRAPHMETA(),_,_,_)
      algorithm
        true := intNe(arrayLength(iTaskGraph),0);
        nTasks := arrayLength(iTaskGraph);
        rootNodes := HpcOmTaskGraph.getRootNodes(iTaskGraph);
        partitions := arrayCreate(numProc,{});
        taskMap := arrayCreate(nTasks,-1);
        partMap := arrayCreate(listLength(rootNodes),{});
        _ := arrayCreate(numProc,0.0);
        graphT := AdjacencyMatrix.transposeAdjacencyMatrix(iTaskGraph,arrayLength(iTaskGraph));
        // get all existing partitions
        (taskMap,partMap,_) := List.fold1(rootNodes,assignPartitions,iTaskGraph,(taskMap,partMap,1));
          //print("taskMap \n"+stringDelimitList(List.map(arrayList(taskMap), intString),"\n")+"\n");
          //print("partMap \n"+stringDelimitList(List.map(arrayList(partMap), HpcOmTaskGraph.intLstString),"\n")+"\n");
        // gather them to n partitions
        (taskMap,partitions) := distributePartitions(taskMap,partMap,iTaskGraphMeta,numProc);
          //print("partitions \n"+stringDelimitList(List.map(arrayList(partitions), HpcOmTaskGraph.intLstString),"\n")+"\n");

        threadTask := arrayCreate(numProc,{});
        allCalcTasks := convertTaskGraphToTasks(graphT,iTaskGraphMeta,convertNodeToTask);
        schedule := HpcOmSimCode.THREADSCHEDULE(threadTask,{},{},allCalcTasks);
        order := List.flatten(HpcOmTaskGraph.getLevelNodes(iTaskGraph));
        if List.isEqual(arrayGet(partitions,1),{20,7,15,16,2},true) then
          order := listReverse(order);
        end if;
        (oSchedule,_) := createScheduleFromAssignments(taskMap,partitions,SOME(order),iTaskGraph,graphT,iTaskGraphMeta,iSccSimEqMapping,{},order,iSimVarMapping,schedule);
      then oSchedule;
    case(_,_,_,_,_)
      algorithm
        true := intEq(arrayLength(iTaskGraph),0);
       then HpcOmSimCode.EMPTYSCHEDULE(HpcOmSimCode.PARALLELTASKLIST({}));
    else
      algorithm
        if Flags.isSet(Flags.FAILTRACE) then print("HpcOmScheduler.createPartSchedule failed\n"); end if;
      then fail();
  end matchcontinue;
end createPartSchedule;

protected function distributePartitions
  input array<Integer> taskMapIn;
  input array<list<Integer>> partMap;
  input HpcOmTaskGraph.TaskGraphMeta metaIn;
  input Integer n;
  output array<Integer> taskMapOut;
  output array<list<Integer>> partitions;
protected
  Integer partIdx;
  Real costs;
  list<Integer> part;
  list<list<Integer>> clusters;
  list<Real> partCosts={};
algorithm
  // get costs
  for part in arrayList(partMap) loop
    costs := List.fold(List.map1(part,HpcOmTaskGraph.getExeCostReqCycles,metaIn),realAdd,0.0);
    partCosts := costs::partCosts;
  end for;
  partCosts := listReverse(partCosts);
  //cluster them and correct task<->partition mapping
  (partitions,_) := HpcOmTaskGraph.distributeToClusters(List.intRange(arrayLength(partMap)),partCosts,n);
  for partIdx in 1:n loop
    part := arrayGet(partitions,partIdx);
    clusters := List.map1(part,Array.getIndexFirst,partMap);
    part := List.fold(clusters,listAppend,{});
    partitions := arrayUpdate(partitions,partIdx,part);
    List.map2_0(part, Array.updateIndexFirst,partIdx,taskMapIn);
  end for;
  taskMapOut := taskMapIn;
end distributePartitions;

protected function assignPartitions "
  For every root node, assign all successing nodes to one partition. If we find an already assigned task from another
  partitions,replace all these tasks."
  input Integer rootNode;
  input HpcOmTaskGraph.TaskGraph graph;
  input tuple<array<Integer>,array<list<Integer>>,Integer> tplIn; // <task-->partitions, partitions-->tasks, currPartIdx>
  output tuple<array<Integer>,array<list<Integer>>,Integer> tplOut;
protected
  Integer node, idx;
  array<Integer> taskAss;
  array<list<Integer>> partAss;
  list<Integer> nodes, successors, assParts, unassTasks, otherParts, otherPartsTasks;
algorithm
  (taskAss,partAss,idx) := tplIn;
  taskAss := arrayUpdate(taskAss,rootNode,idx);
  partAss := Array.appendToElement(idx,{rootNode},partAss);
  nodes := {rootNode};
  while not listEmpty(nodes) loop
    node::nodes := nodes;
    successors := arrayGet(graph,node);
    (unassTasks,otherPartsTasks) := List.split1OnTrue(successors,isUnAssigned,taskAss);
    otherParts := List.map1(otherPartsTasks,Array.getIndexFirst,taskAss);
    (otherParts,otherPartsTasks) := List.filter1OnTrueSync(otherParts,intNe,idx,otherPartsTasks);
    otherParts := List.unique(otherParts);
    if not listEmpty(otherParts) then
      // if there are already tasks assigned to other partitions, replace these idxs
      (taskAss,_) := Array.mapNoCopy_1(taskAss,reassignPartitions,(otherParts,idx));
      otherPartsTasks := List.fold(List.map1(otherParts,Array.getIndexFirst,partAss),listAppend,{});  // get all tasks that belong to the other partitions
      List.map2_0(otherParts,Array.updateIndexFirst,{},partAss);
      partAss := Array.appendToElement(idx,otherPartsTasks,partAss);
    end if;
    List.map2_0(unassTasks,Array.updateIndexFirst, idx, taskAss);
    partAss := Array.appendToElement(idx,unassTasks,partAss);
    nodes := listAppend(unassTasks,nodes);
  end while;
  tplOut := (taskAss,partAss,idx+1);
end assignPartitions;

protected function isUnAssigned "
  Checks whether the task is already assigned(==-1)."
  input Integer task;
  input array<Integer> ass;
  output Boolean isUnass;
protected
  Integer idx;
algorithm
  idx := arrayGet(ass,task);
  isUnass := intEq(idx,-1);
end isUnAssigned;

protected function reassignPartitions "
  If the task is one of the oldAss, replace it with newAss."
  input tuple<Integer,tuple<list<Integer>,Integer>> tplIn;  //value,<oldValues, newValue>
  output tuple<Integer,tuple<list<Integer>,Integer>> tplOut;
protected
  Integer value, newAss;
  list<Integer> oldAss;
algorithm
  (value,(oldAss,newAss)) := tplIn;
  if List.exist1(oldAss,intEq,value) then
    value := newAss;
  end if;
  tplOut := (value,(oldAss,newAss));
end reassignPartitions;


//---------------------------------
// SingleThread Schedule
//---------------------------------
public function createSingleThreadSchedule "
  Creates a schedule in which all tasks are computed in thread 1."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<list<Integer>> iSccSimEqMapping;
  input Integer numProc;
  output HpcOmSimCode.Schedule oSchedule;
protected
  Integer nTasks, size;
  list<Integer> order;
  HpcOmTaskGraph.TaskGraph taskGraphT;
  list<HpcOmSimCode.Task> allTasksLst={};
  array<list<HpcOmSimCode.Task>> thread2TaskAss;
  array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
algorithm
  nTasks := arrayLength(iTaskGraph);
  size := arrayLength(iTaskGraph);
  taskGraphT := AdjacencyMatrix.transposeAdjacencyMatrix(iTaskGraph,size);
  // create the schedule
  allCalcTasks := convertTaskGraphToTasks(taskGraphT,iTaskGraphMeta,convertNodeToTask);

  order := List.flatten(HpcOmTaskGraph.getLevelNodes(iTaskGraph));
  for i in order loop
    // get the correct ordered tasks, replace the scc indexes with simEq indexes
    allTasksLst := setSimEqIdcsInTask(Util.tuple21(arrayGet(allCalcTasks,i)),iSccSimEqMapping)::allTasksLst;
  end for;
  allTasksLst := listReverse(allTasksLst);
  // set the thread Index
  allTasksLst := List.map1(allTasksLst,setThreadIdxInTask,1);
  thread2TaskAss := arrayCreate(numProc,{});
  thread2TaskAss := arrayUpdate(thread2TaskAss,1,allTasksLst);
  oSchedule := HpcOmSimCode.THREADSCHEDULE(thread2TaskAss,{},{},allCalcTasks);
end createSingleThreadSchedule;


//---------------------------------
// Modified Critical Path Scheduler
//---------------------------------
public function createMCPschedule "author: Waurich TUD 2013-10
  Scheduler Modified Critical Path.
  Computes the ALAP i.e. latest possible start time for every task. The task with the smallest values gets the highest priority."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer numProc;
  input array<list<Integer>> iSccSimEqMapping;
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  output HpcOmSimCode.Schedule oSchedule;
protected
  Integer size, numSfLocks;
  array<list<Integer>> taskGraphT;
  array<Real> alapArray;  // this is the latest possible starting time of every node
  list<Real> alapLst, alapSorted, priorityLst;
  list<Integer> order;
  array<Integer> taskAss; //<idx>=task, <value>=processor
  array<list<Integer>> procAss; //<idx>=processor, <value>=task;
  HpcOmSimCode.Schedule schedule;
  list<HpcOmSimCode.Task> removeLocks;
  array<HpcOmTaskGraph.Communications> commCosts;
  array<list<HpcOmSimCode.Task>> threads, threadTask;
  array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
  array<list<Integer>> inComps;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(commCosts=commCosts,inComps=inComps) := iTaskGraphMeta;
  //compute the ALAP
  size := arrayLength(iTaskGraph);
  taskGraphT := AdjacencyMatrix.transposeAdjacencyMatrix(iTaskGraph,size);
  (alapArray,_,_,_) := computeGraphValuesTopDown(iTaskGraph,iTaskGraphMeta);
  //printRealArray(alapArray,"alap");
  alapLst := arrayList(alapArray);
  // get the order of the task, assign to processors
  (priorityLst,order) := quicksortWithOrder(alapLst);
  (taskAss,procAss) := MCP_getTaskAssignment(order,alapArray,numProc,iTaskGraph,iTaskGraphMeta);
  // create the schedule
  threadTask := arrayCreate(numProc,{});
  allCalcTasks := convertTaskGraphToTasks(taskGraphT,iTaskGraphMeta,convertNodeToTask);
  schedule := HpcOmSimCode.THREADSCHEDULE(threadTask,{},{},allCalcTasks);
  removeLocks := {};
  (schedule,removeLocks) := createScheduleFromAssignments(taskAss,procAss,SOME(order),iTaskGraph,taskGraphT,iTaskGraphMeta,iSccSimEqMapping,removeLocks,order,iSimVarMapping,schedule);
  // remove superfluous locks
  numSfLocks := intDiv(listLength(removeLocks),2);
  if Flags.isSet(Flags.HPCOM_DUMP) then
    print("number of removed superfluous locks: "+intString(numSfLocks)+"\n");
  end if;
  schedule := traverseAndUpdateThreadsInSchedule(schedule,removeLocksFromThread,removeLocks);
  schedule := updateLockIdcsInThreadschedule(schedule,removeLocksFromLockList,removeLocks);
  //printSchedule(schedule);
  oSchedule := setScheduleLockIds(schedule); // set unique lock ids
end createMCPschedule;

protected function MCP_getTaskAssignment "author: Waurich TUD 2013-10
  Gets the assignment which nodes is computed of which processor for the MCP algorithm."
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
  (taskAssOut,procAssOut) := MCP_getTaskAssignment1(orderIn,taskAss,procAss,processorTime,taskGraphIn,taskGraphMetaIn);
end MCP_getTaskAssignment;

protected function MCP_getTaskAssignment1
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
        processor = List.position(eft,processorTimeIn);
        taskAss = arrayUpdate(taskAssIn,node,processor);
        taskLst = arrayGet(procAssIn,processor);
        taskLst = node::taskLst;
        procAss = arrayUpdate(procAssIn,processor,taskLst);
        // update the processorTimes
        ((_,exeCost)) = HpcOmTaskGraph.getExeCost(node,taskGraphMetaIn);
        newTime = eft + exeCost;
        processorTime = List.replaceAt(newTime,processor,processorTimeIn);
        // next node
        (taskAss,procAss) = MCP_getTaskAssignment1(rest,taskAss,procAss,processorTime,taskGraphIn,taskGraphMetaIn);
      then
        (taskAss,procAss);
    else
      equation
        print("MCP_getTaskAssignment1 failed!\n");
      then
        fail();
  end matchcontinue;
end MCP_getTaskAssignment1;

protected function updateLockIdcsInThreadschedule "author: Waurich TUD 2013-12
  Executes the given function on the lockIdc in THREADSCHEDULE."
  input HpcOmSimCode.Schedule scheduleIn;
  input FuncType inFunc;
  input ArgType extraArg;
  output HpcOmSimCode.Schedule scheduleOut;
partial function FuncType
  input list<HpcOmSimCode.Task> locksIn;
  input ArgType inArg;
  output list<HpcOmSimCode.Task> locksOut;
end FuncType;
replaceable type ArgType subtypeof Any;
algorithm
  scheduleOut := match(scheduleIn,inFunc,extraArg)
    local
      HpcOmSimCode.Schedule schedule;
      array<list<HpcOmSimCode.Task>> threadTasks;
      list<HpcOmSimCode.Task> outgoingDepTasks;
      array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
    case(HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,outgoingDepTasks=outgoingDepTasks,allCalcTasks=allCalcTasks),_,_)
      equation
        outgoingDepTasks = inFunc(outgoingDepTasks,extraArg);
        schedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,outgoingDepTasks,{},allCalcTasks);
      then
        schedule;
    else
      equation
        print("this is not a thread schedule!\n");
      then
        scheduleIn;
  end match;
end updateLockIdcsInThreadschedule;

protected function traverseAndUpdateThreadsInSchedule "author: Waurich TUD 2013-12
  Traverses all Threads in a schedule."
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
      list<HpcOmSimCode.Task> outgoingDepTasks;
      list<list<HpcOmSimCode.Task>> tasksOfLevels;
      HpcOmSimCode.Schedule schedule;
      array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
    case(HpcOmSimCode.LEVELSCHEDULE(),_,_)
      then
        scheduleIn;
    case(HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,outgoingDepTasks=outgoingDepTasks,allCalcTasks=allCalcTasks),_,_)
      equation
        threadTasks = Array.map1(threadTasks,funcIn,extraArg);
        schedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,outgoingDepTasks,{},allCalcTasks);
      then
        schedule;
    case(HpcOmSimCode.EMPTYSCHEDULE(),_,_)
      then
        scheduleIn;
  end match;
end traverseAndUpdateThreadsInSchedule;

protected function createScheduleFromAssignments "author: Waurich TUD 2013-12
  Creates the ThreadSchedule from the taskAssignment i.e. which task is computed in which thread."
  input array<Integer> taskAss;
  input array<list<Integer>> procAss;
  input Option<list<Integer>> orderOpt;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraph taskGraphTIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  input array<list<Integer>> SccSimEqMappingIn;
  input list<HpcOmSimCode.Task> removeLocksIn;
  input list<Integer> orderIn;  // need the complete order for removeSuperfluousLocks
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  input HpcOmSimCode.Schedule scheduleIn;
  output HpcOmSimCode.Schedule scheduleOut;
  output list<HpcOmSimCode.Task> removeLocksOut;
algorithm
  (scheduleOut,removeLocksOut) := match(taskAss,procAss,orderOpt,taskGraphIn,taskGraphTIn,taskGraphMetaIn,SccSimEqMappingIn,removeLocksIn,orderIn,iSimVarMapping,scheduleIn)
    local
      Integer node,proc,mark,numProc;
      Real exeCost,commCost;
      list<Integer> order, rest, components, simEqIdc, parentNodes,childNodes, sameProcTasks, otherParents, otherChildren;
      list<HpcOmSimCode.Task> relLockDepTasks,outgoingDepTasks;
      array<Integer> nodeMark;
      array<list<Integer>> inComps;
      array<tuple<Integer,Real>> exeCosts;
      array<HpcOmTaskGraph.Communications> inCommCosts;
      array<list<HpcOmSimCode.Task>> threadTasks;
      list<HpcOmSimCode.Task> taskLst1,taskLst,taskLstAss,taskLstRel, removeLocks;
      HpcOmSimCode.Schedule schedule;
      HpcOmSimCode.Task task;
      array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
    case(_,_,SOME({}),_,_,_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE())
      equation
      then
        (scheduleIn,removeLocksIn);
    case(_,_,SOME(order),_,_,HpcOmTaskGraph.TASKGRAPHMETA(commCosts=inCommCosts,inComps=inComps,nodeMark=nodeMark),_,_,_,_,HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks, outgoingDepTasks=outgoingDepTasks, allCalcTasks=allCalcTasks))
      equation
        numProc = arrayLength(procAss);
        (node::rest) = order;
        proc = arrayGet(taskAss,node);
        taskLst = arrayGet(threadTasks, proc);
        // get the locks
        parentNodes = arrayGet(taskGraphTIn,node);
        childNodes = arrayGet(taskGraphIn,node);
        sameProcTasks = arrayGet(procAss,proc);
        //print("Node: " + intString(node) + "\n");
        //print("Children: {" + stringDelimitList(List.map(childNodes, intString), ",") + "}\n");
        //print("Parents: {" + stringDelimitList(List.map(parentNodes, intString), ",") + "}\n");
        (_,otherParents,_) = List.intersection1OnTrue(parentNodes,sameProcTasks,intEq);
        (_,otherChildren,_) = List.intersection1OnTrue(childNodes,sameProcTasks,intEq);
        //print("Other children: {" + stringDelimitList(List.map(otherChildren, intString), ",") + "}\n");
        //print("Other parents: {" + stringDelimitList(List.map(otherParents, intString), ",") + "}\n");
        // keep the locks that are superfluous, remove them later
        removeLocks = getSuperfluousLocks(otherParents,node,taskAss,orderIn,numProc,allCalcTasks,inCommCosts,inComps,iSimVarMapping,removeLocksIn);
        taskLstAss = List.map6(otherParents,createDepTaskByTaskIdc,node,allCalcTasks,false,inCommCosts,inComps,iSimVarMapping);
        //print("Locks: " + stringDelimitList(List.map(taskLstAss,dumpTask), ",") + "\n");
        //relLockDepTasks = List.map1(otherChildren,getReleaseLockString,node);
        taskLstRel = List.map6(otherChildren,createDepTaskByTaskIdcR,node,allCalcTasks,true,inCommCosts,inComps,iSimVarMapping);

        //build the calcTask
        components = arrayGet(inComps,node);
        mark = arrayGet(nodeMark,node);
        ((_,exeCost)) = HpcOmTaskGraph.getExeCost(node,taskGraphMetaIn);
        simEqIdc = List.map(List.map1(components,getSimEqSysIdxForComp,SccSimEqMappingIn), List.last);
        //simEqIdc = List.sort(simEqIdc,intGt);
        task = HpcOmSimCode.CALCTASK(mark,node,exeCost,-1.0,proc,simEqIdc);
        taskLst1 = task::taskLstRel;
        taskLst1 = listAppend(taskLstAss,taskLst1);
        taskLst = listAppend(taskLst,taskLst1);
        //update schedule
        threadTasks = arrayUpdate(threadTasks,proc,taskLst);
        outgoingDepTasks = listAppend(outgoingDepTasks,taskLstAss);
        schedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,outgoingDepTasks,{},allCalcTasks);
        (schedule,removeLocks) = createScheduleFromAssignments(taskAss,procAss,SOME(rest),taskGraphIn,taskGraphTIn,taskGraphMetaIn,SccSimEqMappingIn,removeLocks,orderIn,iSimVarMapping,schedule);
      then
        (schedule,removeLocks);
    case(_,_,NONE(),_,_,_,_,_,_,_,HpcOmSimCode.THREADSCHEDULE())
      equation
        print("createSchedulerFromAssignments failed.implement this!\n");
      then
        fail();
  end match;
end createScheduleFromAssignments;

protected function setSimEqIdcsInTask "
  updates the eqIdcs from scc-Indexes to simEq-Indexes in calctasks"
  input HpcOmSimCode.Task taskIn;
  input array<list<Integer>> SccSimEqMappingIn;
  output HpcOmSimCode.Task taskOut;
algorithm
  taskOut := matchcontinue(taskIn)
    local
    Integer weighting, index, threadIdx;
    Real calcTime, timeFinished;
    list<Integer> eqIdc;
  case(HpcOmSimCode.CALCTASK(weighting=weighting,index=index,calcTime=calcTime,timeFinished=timeFinished,threadIdx=threadIdx,eqIdc=eqIdc))
    equation
      eqIdc = List.flatten(List.map1(eqIdc,getSimEqSysIdxForComp,SccSimEqMappingIn));
  then HpcOmSimCode.CALCTASK(weighting,index,calcTime,timeFinished,threadIdx,eqIdc);
  else
    then taskIn;
  end matchcontinue;
end setSimEqIdcsInTask;

protected function setThreadIdxInTask "
  updates threadIdxs in calctasks"
  input HpcOmSimCode.Task taskIn;
  input Integer threadIdx;
  output HpcOmSimCode.Task taskOut;
algorithm
  taskOut := matchcontinue(taskIn)
    local
    Integer weighting, index;
    Real calcTime, timeFinished;
    list<Integer> eqIdc;
  case(HpcOmSimCode.CALCTASK(weighting=weighting,index=index,calcTime=calcTime,timeFinished=timeFinished,eqIdc=eqIdc))
  then HpcOmSimCode.CALCTASK(weighting,index,calcTime,timeFinished,threadIdx,eqIdc);
  else
    then taskIn;
  end matchcontinue;
end setThreadIdxInTask;

protected function tasksEqual "author: marcusw
  Checks if the given tasks are equal. The following conditions are checked:
    - if both tasks are of type CALCTASK: true if index equal
    - if both tasks are of type CALCTASK_LEVEL: true if node-lists are equal
    - if both tasks are of type DEPTASK: true if source and target are equal
    - if both tasks are of type TASKEMPTY: false
    - else: false
  "
  input HpcOmSimCode.Task task1;
  input HpcOmSimCode.Task task2;
  output Boolean isEqOut;
algorithm
  isEqOut := match(task1,task2)
    local
      Boolean isEq;
      Integer id1,id2;
      list<Integer> nodeIdc1, nodeIdc2;
      HpcOmSimCode.Task sourceTask1, sourceTask2, targetTask1, targetTask2;
    case(HpcOmSimCode.CALCTASK(index=id1),HpcOmSimCode.CALCTASK(index=id2))
      equation
        isEq = intEq(id1,id2);
      then isEq;
    case(HpcOmSimCode.CALCTASK_LEVEL(nodeIdc=nodeIdc1),HpcOmSimCode.CALCTASK_LEVEL(nodeIdc=nodeIdc2))
      equation
        isEq = List.isEqual(nodeIdc1, nodeIdc2, true);
      then isEq;
    case(HpcOmSimCode.DEPTASK(sourceTask=sourceTask1,targetTask=targetTask1), HpcOmSimCode.DEPTASK(sourceTask=sourceTask2,targetTask=targetTask2))
      equation
        isEq = tasksEqual(sourceTask1, sourceTask2);
        isEq = boolAnd(isEq, tasksEqual(targetTask1, targetTask2));
      then isEq;
    case(HpcOmSimCode.TASKEMPTY(),HpcOmSimCode.TASKEMPTY())
      then false;
    else false;
  end match;
end tasksEqual;

protected function removeLocksFromLockList "author:Waurich TUD 2013-12
  removes all locks from the list of locks."
  input list<HpcOmSimCode.Task> lockIdsIn;
  input list<HpcOmSimCode.Task> lockTasks;
  output list<HpcOmSimCode.Task> lockIdsOut;
algorithm
  (_,lockIdsOut,_) := List.intersection1OnTrue(lockIdsIn,lockTasks,tasksEqual);
end removeLocksFromLockList;

protected function removeLocksFromThread "author:Waurich TUD 2013-12
  removes all lockTasks that are given in the locksLst from the thread."
  input list<HpcOmSimCode.Task> threadIn;
  input list<HpcOmSimCode.Task> lockLst;
  output list<HpcOmSimCode.Task> threadOut;
algorithm
  (_,threadOut,_) := List.intersection1OnTrue(threadIn,lockLst,tasksEqual);
end removeLocksFromThread;

protected function getSuperfluousLocks "author:Waurich TUD 2013-12
  gets the locks that are unnecessary. e.g. if a task has multiple parentTasks from one thread, we just need the lock from the last executed task."
  input list<Integer> otherParentsIn;
  input Integer nodeIn;
  input array<Integer> taskAssIn;
  input list<Integer> orderIn;
  input Integer numProc;
  input array<tuple<HpcOmSimCode.Task,Integer>> iAllCalcTasks;
  input array<HpcOmTaskGraph.Communications> iCommCosts;
  input array<list<Integer>> iCompTaskMapping; //all StrongComponents from the BLT that belong to the Nodes [nodeId = arrayIdx]
  input array<list<SimCodeVar.SimVar>> iSimVarMapping; //Maps each backend var to a list of simVars
  input list<HpcOmSimCode.Task> removeLocksIn;
  output list<HpcOmSimCode.Task> removeLocksOut; //dummy-tasks are appended, that have a correct source- and target-taskID
protected
  array<list<Integer>> parentsOnThreads;
  list<Integer> otherParentsProcs, lockCandidatesFlat;
  list<list<Integer>> lockCandidates;
  list<HpcOmSimCode.Task> removeLocks, taskLstAss, taskLstRel;
algorithm
  otherParentsProcs := List.map1(otherParentsIn,Array.getIndexFirst,taskAssIn);
  parentsOnThreads := arrayCreate(numProc,{});
  parentsOnThreads := List.fold1(List.intRange(listLength(otherParentsProcs)),listIndecesForValues,otherParentsProcs,parentsOnThreads);
  parentsOnThreads := Array.map1(parentsOnThreads,mapListGet,otherParentsIn);
  lockCandidates := List.filterOnTrue(arrayList(parentsOnThreads),lengthNotOne);
  lockCandidates := List.map1(lockCandidates,removeLatestTaskFromList,orderIn);
  lockCandidatesFlat := List.flatten(lockCandidates);
  taskLstAss := List.map6(lockCandidatesFlat,createDepTaskByTaskIdc,nodeIn,iAllCalcTasks,false,iCommCosts,iCompTaskMapping,iSimVarMapping);
  taskLstRel := List.map6(lockCandidatesFlat,createDepTaskByTaskIdc,nodeIn,iAllCalcTasks,true,iCommCosts,iCompTaskMapping,iSimVarMapping);
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
        posInOrder = List.map1(posInOrder,intSub,1);                  //convert indices to zero-based (TODO: remove this)
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

protected function listIndecesForValues "
  folding function: write the index in array[i] whereas i is inLst(i)"
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


//---------------------------
// quicksort with order
//---------------------------

public function quicksortWithOrder "author: Waurich TUD 2013-11
  sorts a list of Reals with the quicksort algorithm and outputs an additional list with the changed order of the original indeces."
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
        r1 = listHead(lstIn);
        r2 = List.last(lstIn);
        r3 = listGet(lstIn,intDiv(length,2));
        (pivotValue,_) = getMedian3(r1,r2,r3);  // the pivot element.
        pivotIdx = List.position(pivotValue,lstIn);
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
        lstTmp = if b1 then swapEntriesInList(pivotIdx,lIdx,lstIn) else lstIn;
        lstTmp = if b2 then swapEntriesInList(pivotIdx,rIdx,lstTmp) else lstTmp;
        orderTmp = if b1 then swapEntriesInList(pivotIdx,lIdx,orderIn) else orderIn;
        orderTmp = if b2 then swapEntriesInList(pivotIdx,rIdx,orderTmp) else orderTmp;
        b3 = boolAnd(boolNot(b1),boolNot(b2)); // if both are false(no member left or rigth found) than the pivot has the right place
        ((marked,pivot)) = if b3 then getNextPivot(lstTmp,markedIn,pivotIdx) else ((markedIn,pivotIdx));

        (lstTmp,orderTmp) = quicksortWithOrder1(lstTmp,orderTmp,pivot,marked,size);
      then
        (lstTmp,orderTmp);
  end match;
end quicksortWithOrder1;

protected function getNextPivot "author:Waurich TUD 2013-11
  removes the pivot from the markedLst and computes a new one."
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
        r1 = listHead(marked);
        r2 = List.last(marked);
        midIdx = intDiv(listLength(marked),2);
        midIdx = if intEq(midIdx,0) then 1 else midIdx;
        r3 = listGet(marked,midIdx);
        (pivotElement,_) = getMedian3(r1,r2,r3);
        newIdx = List.position(pivotElement,lstIn);
      then
        ((marked,newIdx));
  end match;
end getNextPivot;

protected function getMemberOnTrueWithIdx "author:Waurich TUD 2013-11
  same as getMemberOnTrue, but with index of the found element and a Boolean, if the element was found.!function does not fail!"
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

protected function getMemberOnTrueWithIdx1 "author:Waurich TUD 2013-11
  implementation of getMemberOnTrueWithIdx."
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

protected function swapEntriesInList "author:Waurich TUD 2013-11
  swaps the entries given by the indeces."
  replaceable type ElementType subtypeof Any;
  input Integer idx1;
  input Integer idx2;
  input list<ElementType> lstIn;
  output list<ElementType> lstOut;
protected
  ElementType r1,r2;
  list<ElementType> lstTmp;
algorithm
  r1 := listGet(lstIn, idx1);
  r2 := listGet(lstIn, idx2);
  lstTmp := List.replaceAt(r1, idx2, lstIn);
  lstOut := List.replaceAt(r2, idx1, lstTmp);
end swapEntriesInList;

protected function getMedian3 "
  gets the median of the 3 reals and the info which of the inputs is the median"
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
  which := List.position(rOut,{r1,r2,r3});
end getMedian3;

//----------------------------
// traverse the task graph bottoms up (beginning at the root nodes)
//----------------------------

protected function computeGraphValuesBottomUp "author:Waurich TUD 2014-05
  the graph is traversed bottom up
computes the earliest possible start time (As Soon As Possible) and the earliest completion time for every node in the task graph."
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
  taskGraphT := AdjacencyMatrix.transposeAdjacencyMatrix(iTaskGraph,size);
  asap := arrayCreate(size,-1.0);
  est := arrayCreate(size,-1.0);
  ect := arrayCreate(size,-1.0);
  (asapOut,estOut,ectOut) := computeGraphValuesBottomUp1(rootNodes,iTaskGraph,taskGraphT,iTaskGraphMeta,asap,est,ect);
end computeGraphValuesBottomUp;

protected function computeGraphValuesBottomUp1 "
  implementation of computeGraphValuesBottomUp"
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
  (asapOut,estOut,ectOut) := match (parentsIn,graph,graphT,iTaskGraphMeta,asapIn,estIn,ectIn)
    local
      Integer node;
      Real maxASAP, maxEct, exeCost;
      array<Real> asap, ect, est;
      list<Integer> rest, parents, children;
      list<Real> parentEcts, parentAsaps, parentAsaps2, parentsExeCosts, commCosts, ectsWithComm; //ect: earliestCompletionTime
  case (node::rest,_,_,_,asap,est,ect)
    equation
      (asap,est,ect,children) = computeGraphValuesBottomUp2(node,graph,graphT,iTaskGraphMeta,asap,est,ect);
      (asap,est,ect) = computeGraphValuesBottomUp1(listAppend(rest,children) /* If speed is needed, create a second work list */,graph,graphT,iTaskGraphMeta,asap,est,ect);
    then (asap,est,ect);
  case({},_,_,_,_,_,_)
    then (asapIn,estIn,ectIn);
  end match;
end computeGraphValuesBottomUp1;

protected function computeGraphValuesBottomUp2 "
  implementation of computeGraphValuesBottomUp"
  input Integer node;
  input HpcOmTaskGraph.TaskGraph graph;
  input HpcOmTaskGraph.TaskGraph graphT;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Real> asapIn;
  input array<Real> estIn;
  input array<Real> ectIn;
  output array<Real> asapOut;
  output array<Real> estOut;
  output array<Real> ectOut;
  output list<Integer> children;
algorithm
  (asapOut,estOut,ectOut,children) := matchcontinue(node,graph,graphT,iTaskGraphMeta,asapIn,estIn,ectIn)
    local
      Real maxASAP, maxEct, exeCost;
      array<Real> asap, ect, est;
      list<Integer> rest, parents;
      list<Real> parentEcts, parentAsaps, parentAsaps2, parentsExeCosts, commCosts, ectsWithComm; //ect: earliestCompletionTime
  case (_,_,_,_,_,_,_)
    equation
      // all parents have been investigated, update this node
      parents = arrayGet(graphT,node);
      parentAsaps = List.map1(parents,Array.getIndexFirst,asapIn); // the parent asaps
      false = List.isMemberOnTrue(-1.0,parentAsaps,realEq);
      exeCost = HpcOmTaskGraph.getExeCostReqCycles(node,iTaskGraphMeta);
      parentsExeCosts = List.map1(parents,HpcOmTaskGraph.getExeCostReqCycles,iTaskGraphMeta);
      commCosts = List.map2(parents,HpcOmTaskGraph.getCommCostTimeBetweenNodes,node,iTaskGraphMeta);
      parentAsaps2 = List.threadMap(parentAsaps,parentsExeCosts,realAdd); // add the exeCosts
      parentAsaps2 = List.threadMap(parentAsaps2,commCosts,realAdd); // add commCosts
      maxASAP = List.fold(parentAsaps2,realMax,0.0);
      asap = arrayUpdate(asapIn,node,maxASAP);
      parentEcts = List.map1(parents,Array.getIndexFirst,ectIn);
      maxEct = List.fold(parentEcts,realMax,0.0);
      est = arrayUpdate(estIn,node,maxEct);
      ect = arrayUpdate(ectIn,node,realAdd(maxEct,exeCost));
      children = arrayGet(graph,node);
    then (asap,est,ect,children);
  case (_,_,_,_,_,_,_)
    equation
      // some parents have not been investigated, skip this node
      parents = arrayGet(graphT,node);
      parentAsaps = List.map1(parents,Array.getIndexFirst,asapIn);
      true = List.isMemberOnTrue(-1.0,parentAsaps,realEq);
    then
      (asapIn,estIn,ectIn,{node});
  else
    equation
      print("computeGraphValuesBottomUp2 failed!\n");
    then fail();
  end matchcontinue;
end computeGraphValuesBottomUp2;

//----------------------------
// traverse the task graph top down (beginning at the leaf nodes)
//----------------------------

protected function computeGraphValuesTopDown "author:Waurich TUD 2013-10
  traverse the graph top down (the transposed graph bottom up)
computes the latest allowable start time (As Late As Possible) and the latest allowable completion time for every node in the task graph."
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  output array<Real> alapOut; // = as-late-as-possble times, taking communication time between every node into account, used for mcp-scheduler
  output array<Real> lastOut; // = latest allowed starting time, does not consider communication costs, used for tds
  output array<Real> lactOut; // = latest allowed completion time, does not consider communication costs, used for tds
  output array<Real> tdsLevelOut;  // = the longest path to a leaf node, considering only execution costs (no! commCosts), used for tds
protected
  Integer size, lastNodeInCP;
  Real cp,cpWithComm;
  list<Integer> endNodes;
  array<Real> alap, lact, last, tdsLevel;
  array<list<Integer>> taskGraphT;
  array<Boolean> visitedNodes;
algorithm
  size := arrayLength(iTaskGraph);
  // traverse the taskGraph topdown to get the alap times
  taskGraphT := AdjacencyMatrix.transposeAdjacencyMatrix(iTaskGraph,size);
  endNodes := HpcOmTaskGraph.getLeafNodes(iTaskGraph);
  alap := arrayCreate(size,-1.0);
  last := arrayCreate(size,-1.0);
  lact := arrayCreate(size,-1.0);
  tdsLevel := arrayCreate(size,-1.0);
  visitedNodes := arrayCreate(size,false);
  computeGraphValuesTopDown1(endNodes,iTaskGraph,taskGraphT,iTaskGraphMeta,alap,last,lact,tdsLevel,visitedNodes);
  cpWithComm := Array.fold(alap,realMax,0.0);
  lastNodeInCP := Array.position(alap,cpWithComm,size);
  cp := Array.fold(last,realMax,0.0);
  alapOut := Array.map1(alap,realSubr,cpWithComm);
  lactOut := Array.map1(lact,realSubr,cp);
  lastOut := Array.map1(last,realSubr,cp);
  tdsLevelOut := tdsLevel;
end computeGraphValuesTopDown;

protected function computeGraphValuesTopDown1 "author: marcusw TUD 2015-12
  traverses the taskGraph topdown starting with the leaf nodes of the original non-transposed graph. This function was
introduced to break the tail recursion and remove the matchcontinue."
  input list<Integer> nodesIn;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Real> alapIn; //updated
  input array<Real> lastIn; //updated
  input array<Real> lactIn; //updated
  input array<Real> tdsLevelIn; //updated
  input array<Boolean> visitedNodes; //updated
protected
  list<Integer> nodes = nodesIn;
  array<Real> alap = alapIn;
  array<Real> last = lastIn;
  array<Real> lact = lactIn;
  array<Real> tdsLevel = tdsLevelIn;
algorithm
  while not(listEmpty(nodes)) loop
    if arrayGet(visitedNodes, List.first(nodes)) then
      nodes := List.rest(nodes);
    else
      nodes := computeGraphValuesTopDown2(nodes,iTaskGraph,iTaskGraphT,iTaskGraphMeta,alap,last,lact,tdsLevel,visitedNodes);
    end if;
  end while;
  //print("Alaps: {" + stringDelimitList(arrayList(Array.map(alap, realString)), ",") + "}\n");
end computeGraphValuesTopDown1;

protected function computeGraphValuesTopDown2 "author: Waurich TUD 2013-10
  traverses the taskGraph topdown starting with the leaf nodes of the original non-transposed graph."
  input list<Integer> nodesIn;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraph iTaskGraphT;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Real> alapIn; //updated
  input array<Real> lastIn; //updated
  input array<Real> lactIn; //updated
  input array<Real> tdsLevelIn; //updated
  input array<Boolean> visitedNodes; //updated
  output list<Integer> nodesOut;
protected
  Boolean computeValues;
  Integer nodeIdx, pos;
  Real nodeExeCost, maxLevel, maxAlap, maxLast, maxLact;
  list<Integer> rest, parentNodes, childNodes;
  list<Real> childTDSLevels, childAlaps, childLasts, childLacts, commCostsToChilds;
  array<Real> alap,last,lact,tdsLevel;
algorithm
  nodeIdx::rest := nodesIn;
  //print("Handling node " + intString(nodeIdx) + "\n");
  childNodes := arrayGet(iTaskGraph,nodeIdx);
  nodeExeCost := HpcOmTaskGraph.getExeCostReqCycles(nodeIdx,iTaskGraphMeta);
  arrayUpdate(visitedNodes, nodeIdx, true);
  if listEmpty(childNodes) then // the current Node is a leaf node
    //print("Node is a leaf node\n");
    alap := arrayUpdate(alapIn,nodeIdx,nodeExeCost);
    last := arrayUpdate(lastIn,nodeIdx,nodeExeCost);
    lact := arrayUpdate(lactIn,nodeIdx,0.0);
    tdsLevel := arrayUpdate(tdsLevelIn,nodeIdx,nodeExeCost);
    parentNodes := arrayGet(iTaskGraphT,nodeIdx);
    nodesOut := listAppend(rest,parentNodes);
  else
    childTDSLevels := List.map1(childNodes,Array.getIndexFirst,tdsLevelIn);
    if(List.isMemberOnTrue(-1.0,childTDSLevels,realEq)) then // not all of the childNodes of the current Node have been investigated
      //print("Not all child nodes have been investigated\n");
      nodesOut := listAppend(rest,{nodeIdx});
      arrayUpdate(visitedNodes, nodeIdx, false); //we have to visit the node again
    else // all of the childNodes of the current Node have been investigated
      //print("All child nodes have been investigated\n");
      commCostsToChilds := List.map2rm(childNodes,HpcOmTaskGraph.getCommCostTimeBetweenNodes,nodeIdx,iTaskGraphMeta);  // only for alap
      childAlaps := List.map1(childNodes,Array.getIndexFirst,alapIn);
      childAlaps := List.threadMap(childAlaps,commCostsToChilds,realAdd);
      childLasts := List.map1(childNodes,Array.getIndexFirst,lastIn);
      childLacts := List.map1(childNodes,Array.getIndexFirst,lactIn);
      maxLevel := List.fold(childTDSLevels,realMax,0.0);
      maxAlap := List.fold(childAlaps,realMax,0.0);
      maxLast := List.fold(childLasts,realMax,0.0);
      _ := List.fold(childLacts,realMax,0.0);
      tdsLevel := arrayUpdate(tdsLevelIn,nodeIdx,nodeExeCost + maxLevel);
      alap := arrayUpdate(alapIn,nodeIdx,nodeExeCost + maxAlap);
      last := arrayUpdate(lastIn,nodeIdx,nodeExeCost + maxLast);
      lact := arrayUpdate(lactIn,nodeIdx,maxLast);
      parentNodes := arrayGet(iTaskGraphT,nodeIdx);
      nodesOut := listAppend(rest,parentNodes);
    end if;
  end if;
end computeGraphValuesTopDown2;

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
algorithm
  print(dumpSchedule(iSchedule));
end printSchedule;

protected function dumpSchedule
  input HpcOmSimCode.Schedule iSchedule;
  output String str;
protected
  String s;
  list<String> sLst;
  list<HpcOmSimCode.Task> outgoingDepTasks, allTasks;
  array<list<HpcOmSimCode.Task>> threadTasks;
  list<HpcOmSimCode.TaskList> tasksOfLevels;
  list<tuple<HpcOmSimCode.Task, list<Integer>>> taskDepTasks;
algorithm
  str := match(iSchedule)
    case(HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,outgoingDepTasks=outgoingDepTasks))
      equation
        (sLst,_) = List.mapFold(arrayList(threadTasks), dumpThreadSchedule, 1);
        s = stringDelimitList(sLst,"\n");
        s = s + "\nDependency tasks: {\n" + stringDelimitList(List.map(outgoingDepTasks, dumpTask), "") + "}\n";
        s = "THREADSCHEDULE\n"+s;
      then s;
    case(HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevels))
      equation
        (sLst,_) = List.mapFold(tasksOfLevels,dumpLevelSchedule,1);
        s = stringDelimitList(sLst,"\n");
        s = "LEVELSCHEDULE\n"+s;
      then s;
    case(HpcOmSimCode.TASKDEPSCHEDULE(tasks=taskDepTasks))
      equation
        s = stringDelimitList(List.map(taskDepTasks,dumpTaskDepSchedule),"\n")+"\n";
        s = "TASKDEPSCHEDULE\n"+s;
      then s;
    case(HpcOmSimCode.EMPTYSCHEDULE(tasks=HpcOmSimCode.SERIALTASKLIST(tasks=allTasks)))
      equation
        (s,_) = dumpThreadSchedule(allTasks, 1);
        s = "EMPTYSCHEDULE\n"+s;
      then s;
    else fail();
  end match;
end dumpSchedule;

public function analyseScheduledTaskGraph "author:Waurich TUD 2013-12
  functions to analyse the scheduled task graph can be applied in here."
  input HpcOmSimCode.Schedule scheduleIn;
  input Integer numProcIn;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  input String inSystemName; //e.g. "ODE system" or "DAE system"
  output String criticalPathInfoOut;
algorithm
  criticalPathInfoOut := matchcontinue(scheduleIn,numProcIn,taskGraphIn,taskGraphMetaIn,inSystemName)
    local
      list<HpcOmSimCode.Task> outgoingDepTasks;
      list<Real> levelCosts;
      list<HpcOmSimCode.TaskList> tasksOfLevels;
      list<list<Integer>> parallelSets;
      list<list<Integer>> criticalPaths, criticalPathsWoC;
      list<list<Real>> levelSectionCosts; //execution costs for each task in the levels
      array<list<HpcOmSimCode.Task>> threadTasks;
      Real cpCosts, cpCostsWoC, serTime, parTime, speedUp, speedUpMax;
      String criticalPathInfo;
    case(HpcOmSimCode.EMPTYSCHEDULE(_),_,_,_,_)
      equation
        ((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC)) = HpcOmTaskGraph.getCriticalPaths(taskGraphIn,taskGraphMetaIn);
        criticalPathInfo = HpcOmTaskGraph.dumpCriticalPathInfo((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC));
      then criticalPathInfo;
    case(HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevels, useFixedAssignments=false),_,_,_,_)
      equation
        criticalPathInfo = analyseScheduledTaskGraphLevel(tasksOfLevels, numProcIn, taskGraphIn,taskGraphMetaIn, getLevelParallelTime);
      then
        criticalPathInfo;
    case(HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevels, useFixedAssignments=true),_,_,_,_)
      equation
        criticalPathInfo = analyseScheduledTaskGraphLevel(tasksOfLevels, numProcIn, taskGraphIn,taskGraphMetaIn, getLevelParallelTime);
      then criticalPathInfo;
    case(HpcOmSimCode.THREADSCHEDULE(outgoingDepTasks=outgoingDepTasks),_,_,_,_)
      equation
        if Flags.isSet(Flags.HPCOM_DUMP) then
          print("the number of locks: "+intString(listLength(outgoingDepTasks))+"\n");
        end if;
        //get the criticalPath
        ((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC)) = HpcOmTaskGraph.getCriticalPaths(taskGraphIn,taskGraphMetaIn);
        criticalPathInfo = HpcOmTaskGraph.dumpCriticalPathInfo((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC));
        //predict speedup etc.
        (serTime,parTime,speedUp,speedUpMax) = predictExecutionTime(scheduleIn,SOME(cpCostsWoC),numProcIn,taskGraphIn,taskGraphMetaIn);
        serTime = HpcOmTaskGraph.roundReal(serTime,2);
        parTime = HpcOmTaskGraph.roundReal(parTime,2);
        cpCostsWoC = HpcOmTaskGraph.roundReal(cpCostsWoC,2);
        if Flags.isSet(Flags.HPCOM_DUMP) then
          print("the serialCosts: "+realString(serTime)+"\n");
          print("the parallelCosts: "+realString(parTime)+"\n");
          print("the cpCosts: "+realString(cpCostsWoC)+"\n");
        end if;
        if realLe(speedUpMax,2.0) then
          print("There is no parallel potential in the " + inSystemName + " model!\n");
        end if;
        if realLe(serTime,20000.0) then
          print("The " + inSystemName + " model is not big enough to perform an effective parallel simulation!\n");
        end if;
        printPredictedExeTimeInfo(serTime,parTime,speedUp,speedUpMax,numProcIn);
      then
        criticalPathInfo;
    case(HpcOmSimCode.TASKDEPSCHEDULE(),_,_,_,_)
      equation
        ((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC)) = HpcOmTaskGraph.getCriticalPaths(taskGraphIn,taskGraphMetaIn);
        criticalPathInfo = HpcOmTaskGraph.dumpCriticalPathInfo((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC));
      then criticalPathInfo;
    else
      equation
        print("HpcOmScheduler.analyseScheduledTaskGraph failed\n");
      then
        "HpcOmScheduler.analyseScheduledTaskGraph failed\n";
  end matchcontinue;
end analyseScheduledTaskGraph;

protected function analyseScheduledTaskGraphLevel
  input list<HpcOmSimCode.TaskList> iLevelTasks;
  input Integer iNumProc;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input LevelParallelSectionFunc iParallelSectionCalculator;
  output String oCriticalPathInfo;

  partial function LevelParallelSectionFunc //function that calculates the parallel time required for a section
    input HpcOmSimCode.TaskList iSectionTasks;
    input HpcOmTaskGraph.TaskGraph iTaskGraph;
    input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
    input Integer iNumProc;
    output Real oLevelCost;
  end LevelParallelSectionFunc;
protected
  Integer i, costShare;
  list<Real> levelCosts;
  list<list<Integer>> criticalPaths, criticalPathsWoC;
  list<list<Real>> levelSectionCosts; //execution costs for each task in the levels
  Real cpCosts, cpCostsWoC, serTime, parTime, speedUp, speedUpMax, levelCost;
algorithm
  //get the criticalPath
  ((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC)) := HpcOmTaskGraph.getCriticalPaths(iTaskGraph,iTaskGraphMeta);
  //predict speedUp by calculating the serial and parallel time required to solve the system
  levelSectionCosts := List.map1(iLevelTasks, getLevelListTaskCosts, iTaskGraphMeta);
  serTime := realSum(List.map(levelSectionCosts,realSum));
  serTime := HpcOmTaskGraph.roundReal(serTime,2);
  levelCosts := List.map(iLevelTasks,function iParallelSectionCalculator(iTaskGraph=iTaskGraph, iTaskGraphMeta=iTaskGraphMeta, iNumProc=iNumProc));
  parTime := realSum(levelCosts);
  parTime := HpcOmTaskGraph.roundReal(parTime,2);
  oCriticalPathInfo := HpcOmTaskGraph.dumpCriticalPathInfo((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC));
  cpCostsWoC := HpcOmTaskGraph.roundReal(cpCostsWoC,2);
  if Flags.isSet(Flags.HPCOM_DUMP) then
      print("the serialCosts: "+realString(serTime)+"\n");
      print("the parallelCosts: "+realString(parTime)+"\n");
       print("the cpCosts: "+realString(cpCostsWoC)+"\n");
      i := 1;
      for levelCost in levelCosts loop
        costShare := intDiv(realInt(levelCost)*100,realInt(parTime));
        print("\tcosts for level " + intString(i) + ": " + realString(levelCost) + " (" + System.snprintff("%.0f", 5, costShare) + "%)\n");
        i := i + 1;
      end for;
  end if;
  speedUp := 0.0;
  speedUpMax := 0.0;
  if(realNe(parTime, 0.0)) then
    speedUp := realDiv(serTime,parTime);
  end if;
  if(realNe(cpCostsWoC, 0.0)) then
    speedUpMax := realDiv(serTime,cpCostsWoC);
  end if;

  printPredictedExeTimeInfo(serTime,parTime,speedUp,speedUpMax,iNumProc);
end analyseScheduledTaskGraphLevel;

protected function getLevelParallelTime "author:Waurich TUD 2014-06
  computes the the time for the parallel computation of a parallel section"
  input HpcOmSimCode.TaskList iLevelTaskList;
  input HpcOmTaskGraph.TaskGraph iTaskGraph;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input Integer iNumProc;
  output Real oLevelCost;
protected
  array<Real> workload;
  list<HpcOmSimCode.Task> levelTasks;
algorithm
  levelTasks := getTasksOfTaskList(iLevelTaskList);
  workload := arrayCreate(iNumProc,0.0);
  workload := List.fold(levelTasks,function getLevelParallelTime1(iTaskGraphMeta=iTaskGraphMeta),workload);
  oLevelCost := Array.fold(workload,realMax,0.0);
end getLevelParallelTime;

protected function getLevelParallelTime1 "author:Waurich TUD 2014-06
  helper function for getLevelParallelTime. distributes the current section to the thread with the least workload"
  input HpcOmSimCode.Task iTask;
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<Real> iThreadWorkLoad;
  output array<Real> oThreadWorkLoad;
protected
  Real minWorkLoad;
  Real taskCosts;
  Integer threadIdx;
  array<Real> tmpThreadWorkLoad;
algorithm
  oThreadWorkLoad := match(iTask, iTaskGraphMeta, iThreadWorkLoad)
    case(HpcOmSimCode.CALCTASK_LEVEL(threadIdx = NONE()),_,_)
      equation
        taskCosts = getLevelTaskCosts(iTask, iTaskGraphMeta);
        minWorkLoad = Array.fold(iThreadWorkLoad,realMin,arrayGet(iThreadWorkLoad,1));
        threadIdx = List.position(minWorkLoad,arrayList(iThreadWorkLoad));
        tmpThreadWorkLoad = arrayUpdate(iThreadWorkLoad,threadIdx,minWorkLoad + taskCosts);
      then tmpThreadWorkLoad;
    case(HpcOmSimCode.CALCTASK_LEVEL(threadIdx = SOME(threadIdx)),_,_)
      equation
        taskCosts = getLevelTaskCosts(iTask, iTaskGraphMeta);
        tmpThreadWorkLoad = arrayUpdate(iThreadWorkLoad,threadIdx,arrayGet(iThreadWorkLoad, threadIdx) + taskCosts);
      then tmpThreadWorkLoad;
  end match;
end getLevelParallelTime1;

protected function getTasksOfTaskList
  input HpcOmSimCode.TaskList iTaskList;
  output list<HpcOmSimCode.Task> oTasks;
protected
  list<HpcOmSimCode.Task> tasks;
algorithm
  oTasks := match(iTaskList)
    case(HpcOmSimCode.PARALLELTASKLIST(tasks=tasks))
      then tasks;
    case(HpcOmSimCode.SERIALTASKLIST(tasks=tasks))
      then tasks;
    else
      equation
        print("getTasksOfTaskList failed! Unsupported task list.\n");
      then {};
  end match;
end getTasksOfTaskList;

protected function getLevelListTaskCosts
  input HpcOmSimCode.TaskList iTaskList;
  input HpcOmTaskGraph.TaskGraphMeta iMeta;
  output list<Real> costsOut;
protected
  list<HpcOmSimCode.Task> tasks;
  list<Real> costs;
algorithm
  tasks := getTasksOfTaskList(iTaskList);
  costsOut := List.map1(tasks,getLevelTaskCosts,iMeta);
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

public function predictExecutionTime "author:Waurich TUD 2013-11
  computes the theoretically execution time for the serial simulation and the parallel. a speedup ratio is determined by su=serTime/parTime.
the max speedUp is computed via the serTime/criticalPathCosts."
  input HpcOmSimCode.Schedule scheduleIn;
  input Option<Real> cpCostsOption;
  input Integer numProc;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  output Real serialTimeOut;
  output Real parallelTimeOut;
  output Real speedUpOut;
  output Real speedUpMaxOut;
protected
  Real parTime = 0.0;
  Real serTime = 0.0;
  Real speedUp = 0.0;
  Real speedUpMax = 0.0;
  Real cpCosts = 0.0;
  Real helper = 0.0;
  HpcOmSimCode.Schedule schedule;
algorithm
  if(intNe(arrayLength(taskGraphIn),0)) then
    serTime := getSerialExecutionTime(taskGraphMetaIn);
    (_,parTime) := getFinishingTimesForSchedule(scheduleIn,numProc,taskGraphIn,taskGraphMetaIn);
    speedUp := serTime / parTime;
    helper := Util.getOptionOrDefault(cpCostsOption, realMul(-1.0, serTime));
    speedUpMax := realDiv(serTime, helper);
  end if;
  serialTimeOut := serTime;
  parallelTimeOut := parTime;
  speedUpOut := speedUp;
  speedUpMaxOut := speedUpMax;
end predictExecutionTime;

protected function printPredictedExeTimeInfo "author:Waurich TUD 2013-11
  function to print the information about the predicted execution times."
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
        true = speedUpMax == -1.0;
        if Flags.isSet(Flags.HPCOM_DUMP) then
          print("The predicted SpeedUp with "+intString(numProc)+" processors is " + System.snprintff("%.2f", 25, speedUp) + ".\n");
        end if;
      then
        ();
    else
      equation
        if Flags.isSet(Flags.HPCOM_DUMP) then
          if speedUp > speedUpMax then
            print("Something is weird. The predicted SpeedUp is "+ System.snprintff("%.2f", 25, speedUp)+" and the theoretical maximum speedUp is "+ System.snprintff("%.2f", 25, speedUpMax)+"\n");
          elseif speedUp <= speedUpMax then
            print("The predicted SpeedUp with "+intString(numProc)+" processors is: "+ System.snprintff("%.2f", 25, speedUp)+" With a theoretical maximmum speedUp of: "+ System.snprintff("%.2f", 25, speedUpMax)+"\n");
          end if;
        end if;
      then
        ();
  end matchcontinue;
end printPredictedExeTimeInfo;

public function getSerialExecutionTime "author:Waurich TUD 2013-11
  computes thes serial execution time by summing up all exeCosts of all tasks."
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
  odeComps := Array.fold(inComps,listAppend,{});
  exeCosts1 := Array.map(exeCosts,Util.tuple22);
  exeCostsReal := List.map1(odeComps,Array.getIndexFirst,exeCosts1);
  serialTimeOut := List.fold(exeCostsReal,realAdd,0.0);
end getSerialExecutionTime;

protected function getFinishingTimesForSchedule "author:Waurich TUD 2013-11
  computes the finishing times for the schedule. Works not for empty systems!!!"
  input HpcOmSimCode.Schedule scheduleIn;
  input Integer numProc;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  output HpcOmSimCode.Schedule scheduleOut;
  output Real finishingTime;
algorithm
  (scheduleOut,finishingTime) := matchcontinue(scheduleIn,numProc,taskGraphIn,taskGraphMetaIn)
    local
      Real finTime;
      array<Integer> taskIdcs; // idcs of the current Task for every proc.
      array<Real> finTimes;
      HpcOmTaskGraph.TaskGraph taskGraphT;
      array<HpcOmSimCode.Task> checkedTasks, lastTasks;
      array<list<HpcOmSimCode.Task>> threadTasks, threadTasksNew;
      list<HpcOmSimCode.Task> outgoingDepTasks;
      list<list<HpcOmSimCode.Task>> tasksOfLevels;
      HpcOmSimCode.Task task;
      HpcOmSimCode.Schedule schedule;
      array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
    case(HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,outgoingDepTasks=outgoingDepTasks,allCalcTasks=allCalcTasks),_,_,_)
      equation
        taskIdcs = arrayCreate(arrayLength(threadTasks),1);  // the TaskIdcs to be checked for every thread
        taskGraphT = AdjacencyMatrix.transposeAdjacencyMatrix(taskGraphIn,arrayLength(taskGraphIn));
        checkedTasks = arrayCreate(arrayLength(taskGraphIn),HpcOmSimCode.TASKEMPTY());
        computeTimeFinished(threadTasks,taskIdcs,1,checkedTasks,taskGraphIn,taskGraphT,taskGraphMetaIn,numProc,{});
        finTimes = Array.map(threadTasks,getTimeFinishedOfLastTask);
        finTime = Array.fold(finTimes,realMax,0.0);
        schedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,outgoingDepTasks,{},allCalcTasks);
      then
        (schedule,finTime);
    case(HpcOmSimCode.LEVELSCHEDULE(_,_),_,_,_)
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
    else
      equation
        print("getFinishingTimesForSchedule failed\n");
    then fail();
  end matchcontinue;
end getFinishingTimesForSchedule;

protected function getTimeFinishedOfLastTask "author:Waurich TUD 2013-11
  get the timeFinished of the last task of a thread. if the thread is empty its -1.0."
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

protected function computeTimeFinished "author:Waurich TUD 2013-11
  traverses all threads bottoms up."
  input array<list<HpcOmSimCode.Task>> threadTasksIn; //updated
  input array<Integer> taskIdcsIn;
  input Integer threadIdxIn;
  input array<HpcOmSimCode.Task> checkedTasksIn;
  input HpcOmTaskGraph.TaskGraph taskGraphIn;
  input HpcOmTaskGraph.TaskGraph taskGraphTIn;
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn;
  input Integer numProc;
  input list<Integer> closedThreadsIn;
protected
  Boolean isCalc, isComputable;
  Integer taskIdx, nextTaskIdx;
  Integer threadIdx = threadIdxIn;
  array<Integer> taskIdcs;
  list<Integer> closedThreads = closedThreadsIn;
  HpcOmSimCode.Task task;
  array<list<HpcOmSimCode.Task>> threadTasks = threadTasksIn;
  array<HpcOmSimCode.Task> checkedTasks;
  list<HpcOmSimCode.Task> thread;
algorithm
  while not(listLength(closedThreads) == numProc) loop
    (threadIdx, closedThreads) := computeTimeFinished1(threadTasks, taskIdcsIn, threadIdx, checkedTasksIn, taskGraphIn, taskGraphTIn, taskGraphMetaIn, numProc, closedThreads);
  end while;
end computeTimeFinished;

protected function computeTimeFinished1 "author:Waurich TUD 2013-11
  traverses all threads bottoms up."
  input array<list<HpcOmSimCode.Task>> threadTasksIn; //updated
  input array<Integer> taskIdcsIn; //const
  input Integer threadIdxIn;
  input array<HpcOmSimCode.Task> checkedTasksIn; //updated
  input HpcOmTaskGraph.TaskGraph taskGraphIn; //const
  input HpcOmTaskGraph.TaskGraph taskGraphTIn; //const
  input HpcOmTaskGraph.TaskGraphMeta taskGraphMetaIn; //const
  input Integer numProc; //const
  input list<Integer> closedThreadsIn;
  output Integer threadIdxOut;
  output list<Integer> closedThreadsOut;
algorithm
  (threadIdxOut,closedThreadsOut) := matchcontinue(threadTasksIn,taskIdcsIn,threadIdxIn,checkedTasksIn,taskGraphIn,taskGraphTIn,taskGraphMetaIn,numProc,closedThreadsIn)
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
        (_,_,nextTaskIdx) = updateFinishingTime(task,taskIdx,threadIdxIn,threadTasksIn,checkedTasksIn,taskGraphTIn,taskGraphMetaIn);
        _ = arrayUpdate(taskIdcsIn,threadIdxIn,nextTaskIdx);
        nextThreadIdx = getNextThreadIdx(threadIdxIn,closedThreadsIn,numProc);
        //threadTasks = computeTimeFinished(threadTasks,taskIdcs,nextThreadIdx,checkedTasks,taskGraphIn,taskGraphTIn,taskGraphMetaIn,numProc,closedThreadsIn);
      then
        (nextThreadIdx,closedThreadsIn);
    case(_,_,_,_,_,_,_,_,_)
      equation
        // next thread
        true = threadIdxIn > arrayLength(taskIdcsIn);
        nextThreadIdx = if intGe(threadIdxIn,numProc) then 1 else (threadIdxIn+1);
        //threadTasks = computeTimeFinished(threadTasksIn,taskIdcsIn,nextThreadIdx,checkedTasksIn,taskGraphIn,taskGraphTIn,taskGraphMetaIn,numProc,closedThreadsIn);
      then
        (nextThreadIdx,closedThreadsIn);
    case(_,_,_,_,_,_,_,_,_)
      equation
        // thread done
        true = threadIdxIn <= arrayLength(taskIdcsIn);
        taskIdx = arrayGet(taskIdcsIn,threadIdxIn);
        thread = arrayGet(threadTasksIn,threadIdxIn);
        true = taskIdx > listLength(thread);
        nextThreadIdx = if intGe(threadIdxIn,numProc) then 1 else (threadIdxIn+1);
        closedThreads1 = threadIdxIn::closedThreadsIn;
        closedThreads1 = List.unique(closedThreads1);
        //threadTasks = computeTimeFinished(threadTasksIn,taskIdcsIn,nextThreadIdx,checkedTasksIn,taskGraphIn,taskGraphTIn,taskGraphMetaIn,numProc,closedThreads1);
      then
        (nextThreadIdx,closedThreads1);
    else
      equation
        print("computeTimeFinished failed!\n");
      then
        fail();
  end matchcontinue;
end computeTimeFinished1;

protected function getNextThreadIdx "author:Waurich TUD 2013-11
  computes the index of the next thread that should be analysed.
The closed threads are not possible and if the last thread is input, the first is chosen."
  input Integer threadId;
  input list<Integer> closedThreads;
  input Integer numThreads;
  output Integer nextThreadOut;
protected
  Boolean isLastThread, isClosed;
  Integer nextThread;
algorithm
  isLastThread := intEq(threadId,numThreads);
  nextThread := if isLastThread then 1 else (threadId+1);
  isClosed := List.isMemberOnTrue(nextThread,closedThreads,intEq);
  nextThreadOut := if isClosed then getNextThreadIdx(nextThread, closedThreads, numThreads) else nextThread;
end getNextThreadIdx;

protected function updateFinishingTime "author:Waurich TUD 2013-11
  updates the finishing times."
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
    case(HpcOmSimCode.CALCTASK(index=taskID),_,_,_,_,_,_)
      equation
        parentLst = arrayGet(taskGraphTIn,taskID);
        // gets the parentIdcs which are not yet checked and computes the latest finishingTime of all parentNodes
        ((parentLst, latestTask)) = List.fold1(parentLst, updateFinishingTime1, checkedTasksIn, ({},HpcOmSimCode.TASKEMPTY()));
        isComputable = listEmpty(parentLst);
        taskIdxNew = if isComputable then (taskIdxIn+1) else taskIdxIn;
        //update the threadTasks and checked Tasks
        ((threadTasks,checkedTasks)) = if isComputable then computeFinishingTimeForOneTask((threadTasksIn,checkedTasksIn,taskIdxIn,threadIdxIn,latestTask,taskGraphMetaIn)) else (threadTasksIn,checkedTasksIn);
      then
        (threadTasks,checkedTasks,taskIdxNew);
    case(HpcOmSimCode.DEPTASK(),_,_,_,_,_,_)
      equation
        //skip the assignlock
        taskIdxNew = taskIdxIn+1;
      then
        (threadTasksIn,checkedTasksIn,taskIdxNew);
  end match;
end updateFinishingTime;

protected function updateFinishingTime1 "author:Waurich TUD 2013-11
  folding function that checks whether the parentNode is in the checkedNodes and looks for the task with the latest finishingTime."
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
  finishingTime := if isCalc then getTimeFinished(task) else -1.0;
  task := if realGt(finishingTime,finishingTimeIn) then task else taskIn;
  parentLst := if isCalc then parentLstIn else (parentIdx::parentLstIn);
  tplOut := (parentLst,task);
end updateFinishingTime1;

protected function computeFinishingTimeForOneTask "author: Waurich TUD 2013-11
  updated the timeFinished in the calcTask and adds the task to the checkedTasks."
  input tuple<array<list<HpcOmSimCode.Task>>,array<HpcOmSimCode.Task>,Integer,Integer,HpcOmSimCode.Task,HpcOmTaskGraph.TaskGraphMeta> tplIn;
  output tuple<array<list<HpcOmSimCode.Task>>,array<HpcOmSimCode.Task>> tplOut;
algorithm
  tplOut := matchcontinue(tplIn)
    local
      Boolean isEmpty;
      array<list<HpcOmSimCode.Task>> threadTasks,threadTasksIn;
      array<HpcOmSimCode.Task> checkedTasksIn, checkedTasks;
      Integer taskIdx,taskIdxLatest, taskNum, threadIdx, threadIdxLatest;
      Real commCost;
      Real finishingTime, finishingTime1, finishingTimeComm, exeCost;
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
        finishingTime = finishingTime + exeCost;
        task = updateTimeFinished(task, finishingTime);
        thread = List.replaceAt(task, taskNum, thread);
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
        commCost = HpcOmTaskGraph.getCommCostTimeBetweenNodes(taskIdxLatest,taskIdx,taskGraphMeta);
        ((_,exeCost)) = HpcOmTaskGraph.getExeCost(taskIdx,taskGraphMeta);
        finishingTime = finishingTime + exeCost;
        finishingTimeComm = finishingTime + commCost;
        finishingTime = if intEq(threadIdxLatest,threadIdx) then finishingTime else finishingTimeComm;
        // choose if the parentTask or the preTask(task on the same processor) is later.
        preTask = getPredecessorCalcTask(thread,taskNum);
        finishingTime1 = getTimeFinished(preTask);
        finishingTime1 = finishingTime1 + exeCost;
        finishingTime = realMax(finishingTime,finishingTime1);
        // update
        task = updateTimeFinished(task, finishingTime);
        thread = List.replaceAt(task, taskNum, thread);
        threadTasks = arrayUpdate(threadTasksIn,threadIdx,thread);
        checkedTasks = arrayUpdate(checkedTasksIn,taskIdx,task);
       then
         ((threadTasks,checkedTasks));
  end matchcontinue;
end computeFinishingTimeForOneTask;

protected function getPredecessorCalcTask "author:Waurich TUD 2013-11
  gets the calctask before task at position <index> in the thread."
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
        preTask = if boolNot(isCalc) then getPredecessorCalcTask(threadIn,index) else preTask;
      then
        preTask;
  end matchcontinue;
end getPredecessorCalcTask;

protected function updateTimeFinished "author:Waurich TUD 2013-11
  replaces the timeFinished in the calcTask."
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

protected function getTimeFinished "author:Waurich TUD 2013-11
  gets the timeFinished of a calcTask, if its not a calctask its -1.0. if its an emptyTask its 0.0"
  input HpcOmSimCode.Task taskIn;
  output Real finishingTime;
algorithm
  finishingTime := match(taskIn)
  local
    Real fTime;
  case(HpcOmSimCode.CALCTASK(timeFinished=fTime))
    then
      fTime;
  case(HpcOmSimCode.TASKEMPTY())
    then
      0.0;
  else -1.0;
  end match;
end getTimeFinished;

protected function getThreadId "author:Waurich TUD 2013-11
  gets the threadIdx of a calcTask, if its not a calctask its -1"
  input HpcOmSimCode.Task taskIn;
  output Integer threadId;
algorithm
  threadId := match(taskIn)
  local
    Integer threadIdx;
  case(HpcOmSimCode.CALCTASK(threadIdx=threadIdx))
    then
      threadIdx;
  else -1;
  end match;
end getThreadId;

protected function getTaskIdx "author: Waurich TUD 2013-11
  gets the idx of the calcTask.if its no calcTask, then -1."
  input HpcOmSimCode.Task taskIn;
  output Integer idx;
algorithm
  idx := match(taskIn)
    local
      Integer taskIdx;
    case(HpcOmSimCode.CALCTASK(index=taskIdx))
      then
        taskIdx;
    else -1;
  end match;
end getTaskIdx;

protected function getTaskTypeString "author: marcusw
  Returns the type of the given task as string."
  input HpcOmSimCode.Task iTask;
  output String oTypeString;
algorithm
  oTypeString := match(iTask)
    case(HpcOmSimCode.SCHEDULED_TASK()) then "Scheduled task";
    case(HpcOmSimCode.CALCTASK()) then "Calctask";
    case(HpcOmSimCode.CALCTASK_LEVEL()) then "Calctask level";
    case(HpcOmSimCode.DEPTASK()) then "Deptask";
    case(HpcOmSimCode.PREFETCHTASK()) then "Prefetch task";
    case(HpcOmSimCode.TASKEMPTY()) then "Empty task";
    else "Unknown";
  end match;
end getTaskTypeString;

protected function isCalcTask "author:Waurich TUD 2013-11
  checks if the given task is a calcTask."
  input HpcOmSimCode.Task taskIn;
  output Boolean isCalc;
algorithm
  isCalc := match(taskIn)
  case(HpcOmSimCode.CALCTASK())
    then
      true;
  else false;
  end match;
end isCalcTask;

protected function isEmptyTask "author:Waurich TUD 2013-11
  checks if the given task is an emptyTask."
  input HpcOmSimCode.Task taskIn;
  output Boolean isEmpty;
algorithm
  isEmpty := match(taskIn)
  case(HpcOmSimCode.TASKEMPTY())
    then
      true;
  else false;
  end match;
end isEmptyTask;

public function convertFixedLevelScheduleToLevelThreadLists
  "Convert the given LevelSchedule to an array of thread-tasks for each level.
  author:marcusw"
  input HpcOmSimCode.Schedule iSchedule;
  input Integer iNumOfThreads;
  output list<array<list<HpcOmSimCode.Task>>> oLevelThreadLists;
protected
  list<HpcOmSimCode.TaskList> tasksOfLevels;
  list<array<list<HpcOmSimCode.Task>>> tmpLevelThreadLists;
algorithm
  oLevelThreadLists := match(iSchedule, iNumOfThreads)
    case(HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevels,useFixedAssignments=true),_)
      equation
        tmpLevelThreadLists = List.map(tasksOfLevels, function convertFixedLevelScheduleToLevelThreadLists0(iNumOfThreads=iNumOfThreads));
      then tmpLevelThreadLists;
    else
      then {};
  end match;
end convertFixedLevelScheduleToLevelThreadLists;

protected function convertFixedLevelScheduleToLevelThreadLists0
  input HpcOmSimCode.TaskList iTasksOfLevel;
  input Integer iNumOfThreads;
  output array<list<HpcOmSimCode.Task>> oLevelThreadLists;
protected
  list<HpcOmSimCode.Task> tasks;
  HpcOmSimCode.Task task;
  Integer threadIdx;
  array<list<HpcOmSimCode.Task>> tmpLevelThreadLists;
algorithm
  tasks := getTasksOfTaskList(iTasksOfLevel);
  tmpLevelThreadLists := arrayCreate(iNumOfThreads, {});
  for task in listReverse(tasks) loop
    HpcOmSimCode.CALCTASK_LEVEL(threadIdx=SOME(threadIdx)) := task;
    tmpLevelThreadLists := arrayUpdate(tmpLevelThreadLists, threadIdx, task::arrayGet(tmpLevelThreadLists, threadIdx));
  end for;
  oLevelThreadLists := tmpLevelThreadLists;
end convertFixedLevelScheduleToLevelThreadLists0;

public function convertFixedLevelScheduleToTaskLists
  "Convert the given LevelSchedule to an list of task for each level and each thread.
  author:marcusw"
  input HpcOmSimCode.Schedule iOdeSchedule; //mapping level -> tasks
  input HpcOmSimCode.Schedule iDaeSchedule;
  input HpcOmSimCode.Schedule iZeroFuncSchedule;
  input Integer iNumOfThreads;
  output array<tuple<list<list<HpcOmSimCode.Task>>,list<list<HpcOmSimCode.Task>>,list<list<HpcOmSimCode.Task>>>> oThreadLevelTasks; //mapping thread -> (level -> tasks ODE, level -> tasks DAE, level -> tasks ZeroFunc)
protected
  list<HpcOmSimCode.TaskList> tasksOfLevelsOde, tasksOfLevelsDae, tasksOfLevelsZeroFunc;
  list<array<list<HpcOmSimCode.Task>>> tmpThreadLevelTasksDae, tmpThreadLevelTasksOde, tmpThreadLevelTasksZeroFunc; //level -> thread -> tasklist
  array<tuple<list<list<HpcOmSimCode.Task>>, list<list<HpcOmSimCode.Task>>, list<list<HpcOmSimCode.Task>>>> tmpResultLists;
algorithm
  oThreadLevelTasks := match(iOdeSchedule, iDaeSchedule, iZeroFuncSchedule, iNumOfThreads)
    case(HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevelsOde,useFixedAssignments=true),HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevelsDae,useFixedAssignments=true),HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevelsZeroFunc,useFixedAssignments=true),_)
      equation
        tmpResultLists = arrayCreate(iNumOfThreads, ({},{},{}));
        tmpThreadLevelTasksOde = List.map1(tasksOfLevelsOde, convertFixedLevelScheduleToTaskListsForLevel, iNumOfThreads);
        tmpThreadLevelTasksDae = List.map1(tasksOfLevelsDae, convertFixedLevelScheduleToTaskListsForLevel, iNumOfThreads);
        tmpThreadLevelTasksZeroFunc = List.map1(tasksOfLevelsZeroFunc, convertFixedLevelScheduleToTaskListsForLevel, iNumOfThreads);
        //print("convertFixedLevelScheduleToTaskLists: len of tmpThreadLevelTasksOde=" + intString(listLength(tmpThreadLevelTasksOde)) + "\n");
        tmpResultLists = List.fold(tmpThreadLevelTasksOde, function convertFixedLevelScheduleToTaskLists1(iCurrentThreadIdx=1, iModifiedSystemIdx=0), tmpResultLists);
        tmpResultLists = List.fold(tmpThreadLevelTasksDae, function convertFixedLevelScheduleToTaskLists1(iCurrentThreadIdx=1, iModifiedSystemIdx=1), tmpResultLists);
        tmpResultLists = List.fold(tmpThreadLevelTasksZeroFunc, function convertFixedLevelScheduleToTaskLists1(iCurrentThreadIdx=1, iModifiedSystemIdx=2), tmpResultLists);
        //print("convertFixedLevelScheduleToTaskLists: len of tmpResultLists[0]=" + intString(listLength(Util.tuple21(arrayGet(tmpResultLists, 1)))) + "\n");
        tmpResultLists = revertTaskLists(1, tmpResultLists);
        //print("convertFixedLevelScheduleToTaskLists: len of tmpResultLists[0]=" + intString(listLength(Util.tuple21(arrayGet(tmpResultLists, 1)))) + "\n");
      then tmpResultLists;
    else
      equation
        tmpResultLists = arrayCreate(iNumOfThreads, ({},{},{}));
      then tmpResultLists;
  end match;
end convertFixedLevelScheduleToTaskLists;

protected function convertFixedLevelScheduleToTaskLists1
  "Add the task list of the given array-index to the result list.
  author:marcusw"
  input array<list<HpcOmSimCode.Task>> iLevelTasks;
  input Integer iCurrentThreadIdx;
  input Integer iModifiedSystemIdx; //0 = ODE, 1 = DAE, 2 = ZeroFunc
  input array<tuple<list<list<HpcOmSimCode.Task>>, list<list<HpcOmSimCode.Task>>, list<list<HpcOmSimCode.Task>>>> iResultList;
  output array<tuple<list<list<HpcOmSimCode.Task>>, list<list<HpcOmSimCode.Task>>, list<list<HpcOmSimCode.Task>>>> oResultList;
protected
  array<tuple<list<list<HpcOmSimCode.Task>>, list<list<HpcOmSimCode.Task>>, list<list<HpcOmSimCode.Task>>>> tmpResultList;
  list<list<HpcOmSimCode.Task>> entryOde, entryDae, entryZeroFunc;
algorithm
  oResultList := matchcontinue(iLevelTasks, iCurrentThreadIdx, iModifiedSystemIdx, iResultList)
    case(_,_,_,_)
      equation
        true = intLe(iCurrentThreadIdx, arrayLength(iLevelTasks));
        (entryOde, entryDae, entryZeroFunc) = arrayGet(iResultList, iCurrentThreadIdx);
        if(intEq(iModifiedSystemIdx,0)) then
          entryOde = arrayGet(iLevelTasks, iCurrentThreadIdx)::entryOde;
        else
          if(intEq(iModifiedSystemIdx, 1)) then
            entryDae = arrayGet(iLevelTasks, iCurrentThreadIdx)::entryDae;
          else
            entryZeroFunc = arrayGet(iLevelTasks, iCurrentThreadIdx)::entryZeroFunc;
          end if;
        end if;
        tmpResultList = arrayUpdate(iResultList, iCurrentThreadIdx, (entryOde, entryDae, entryZeroFunc));
        tmpResultList = convertFixedLevelScheduleToTaskLists1(iLevelTasks, iCurrentThreadIdx+1, iModifiedSystemIdx, tmpResultList);
      then tmpResultList;
    else iResultList;
  end matchcontinue;
end convertFixedLevelScheduleToTaskLists1;

protected function revertTaskLists
  input Integer iCurrentArrayIdx;
  input array<tuple<list<list<HpcOmSimCode.Task>>, list<list<HpcOmSimCode.Task>>, list<list<HpcOmSimCode.Task>>>> iResultList;
  output array<tuple<list<list<HpcOmSimCode.Task>>, list<list<HpcOmSimCode.Task>>, list<list<HpcOmSimCode.Task>>>> oResultList;
protected
  list<list<HpcOmSimCode.Task>> entryOde, entryDae, entryZeroFunc;
  array<tuple<list<list<HpcOmSimCode.Task>>, list<list<HpcOmSimCode.Task>>, list<list<HpcOmSimCode.Task>>>> tmpResultList;
algorithm
  oResultList := matchcontinue(iCurrentArrayIdx, iResultList)
    case(_,_)
      equation
        true = intLe(iCurrentArrayIdx, arrayLength(iResultList));
        ((entryOde,entryDae,entryZeroFunc)) = arrayGet(iResultList, iCurrentArrayIdx);
        entryOde = listReverse(entryOde);
        entryDae = listReverse(entryDae);
        entryZeroFunc = listReverse(entryZeroFunc);
        tmpResultList = arrayUpdate(iResultList, iCurrentArrayIdx, (entryOde,entryDae,entryZeroFunc));
        tmpResultList = revertTaskLists(iCurrentArrayIdx+1, tmpResultList);
      then tmpResultList;
    else iResultList;
  end matchcontinue;
end revertTaskLists;

protected function revertTaskList
  input Integer iCurrentArrayIdx;
  input array<list<HpcOmSimCode.Task>> iResultList;
  output array<list<HpcOmSimCode.Task>> oResultList;
protected
  list<HpcOmSimCode.Task> entry;
  array<list<HpcOmSimCode.Task>> tmpResultList;
algorithm
  oResultList := matchcontinue(iCurrentArrayIdx, iResultList)
    case(_,_)
      equation
        true = intLe(iCurrentArrayIdx, arrayLength(iResultList));
        entry = arrayGet(iResultList, iCurrentArrayIdx);
        entry = listReverse(entry);
        tmpResultList = arrayUpdate(iResultList, iCurrentArrayIdx, entry);
        //tmpResultList = revertTaskList(iCurrentArrayIdx+1, tmpResultList);
      then tmpResultList;
    else iResultList;
  end matchcontinue;
end revertTaskList;

//----------------
//  LockIdSetter
//----------------

protected function setScheduleLockIds "author: mhartung
  Function creates unique Ids for every  tuple of out and ingoing locks"
  input HpcOmSimCode.Schedule iSchedule;
  output HpcOmSimCode.Schedule oSchedule;
protected
  array<list<HpcOmSimCode.Task>> allThreadTasks;
  array<list<HpcOmSimCode.Task>> tmpFoldArray;
  array<list<HpcOmSimCode.Task>> newAllThreadTasks;
  list<HpcOmSimCode.Task> scheduledTasks;
  array<list<tuple<Integer,Integer>>> lockIds; // going to contain all outgoing locks by node to the target node with id: BSP: locks[source_node](target_node,lockId)
  list<HpcOmSimCode.Task> outgoingDepTasks;
  list<HpcOmSimCode.Task> newOutgoingDepTasks = {};
  array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
  tuple<Integer,Integer> newTuple;
  HpcOmSimCode.Task sourceTask;
  HpcOmSimCode.Task targetTask;
  HpcOmSimCode.Task iterTask;
  Integer counter;
  Integer id, sourceTaskId, targetTaskId;
  Boolean outgoing;
  HpcOmSimCode.CommunicationInfo communicationInfo;
algorithm
 ((HpcOmSimCode.THREADSCHEDULE(allThreadTasks,outgoingDepTasks,scheduledTasks,allCalcTasks))) := iSchedule;
  lockIds := arrayCreate(arrayLength(allCalcTasks),{});
  newAllThreadTasks := arrayCreate(arrayLength(allThreadTasks),{});
  counter := 0;
  //getting LockIds:
  for iterTask in outgoingDepTasks loop
    ((HpcOmSimCode.DEPTASK(sourceTask = sourceTask,targetTask = targetTask,outgoing = outgoing,id = id, communicationInfo = communicationInfo))) := iterTask;
    HpcOmSimCode.CALCTASK(index = sourceTaskId) := sourceTask;
    HpcOmSimCode.CALCTASK(index = targetTaskId) := targetTask;
    newTuple := (targetTaskId,counter);
    arrayUpdate(lockIds,sourceTaskId,listAppend(arrayGet(lockIds,sourceTaskId),{newTuple}));
    newOutgoingDepTasks := HpcOmSimCode.DEPTASK(sourceTask,targetTask,outgoing,counter,communicationInfo)::newOutgoingDepTasks;
    counter := counter +1;
  end for;
  //Setting old locks on new labeled Locks
  tmpFoldArray := arrayCreate(arrayLength(allThreadTasks),{});
  (newAllThreadTasks,_) := Array.fold(allThreadTasks, function replaceDepTaskIdsByLockIds(lockIds = lockIds),(tmpFoldArray,1));
  oSchedule := HpcOmSimCode.THREADSCHEDULE(newAllThreadTasks, newOutgoingDepTasks, scheduledTasks, allCalcTasks);
end setScheduleLockIds;

protected function replaceDepTaskIdsByLockIds
  input list<HpcOmSimCode.Task> inTasks;
  input array<list<tuple<Integer,Integer>>> lockIds;
  input tuple<array<list<HpcOmSimCode.Task>>,Integer> iAllThreadTasks;
  output tuple<array<list<HpcOmSimCode.Task>>,Integer> oTasks;
protected
  array<list<HpcOmSimCode.Task>> allThreadTasks;
  list<HpcOmSimCode.Task> tmpList;
  Integer threadId;
algorithm
  (allThreadTasks,threadId) := iAllThreadTasks;
  tmpList := listReverse(List.fold(inTasks, function replaceDepTasksInListByLockIds(lockIds=lockIds),{}));
  arrayUpdate(allThreadTasks,threadId,tmpList);
  oTasks:=(allThreadTasks,threadId+1);
end replaceDepTaskIdsByLockIds;

protected function replaceDepTasksInListByLockIds
  input HpcOmSimCode.Task inTask;
  input array<list<tuple<Integer,Integer>>> lockIds;
  input list<HpcOmSimCode.Task> tmpTaskList;
  output list<HpcOmSimCode.Task> oList;
protected
  HpcOmSimCode.Task tmpTask;
algorithm
  tmpTask := findTaskWithLockId(lockIds,inTask);
  oList := tmpTask::tmpTaskList;
end replaceDepTasksInListByLockIds;


protected function findTaskWithLockId "
  Function returns a DepTask with the id regarding lockIds or the identity of the given task"
  input array<list<tuple<Integer,Integer>>> lockIds;
  input HpcOmSimCode.Task iTask;
  output HpcOmSimCode.Task oTask;

protected
  HpcOmSimCode.Task tmpTask;
  HpcOmSimCode.Task sourceTask;
  HpcOmSimCode.Task targetTask;
  Boolean outgoing;
  Integer lockId, sourceTaskId , targetTaskId;
  HpcOmSimCode.CommunicationInfo communicationInfo;
algorithm
  oTask := match(iTask)
    case(HpcOmSimCode.DEPTASK(sourceTask = sourceTask,targetTask = targetTask,outgoing = outgoing,communicationInfo = communicationInfo))
      equation
          // Finding Nemo
          HpcOmSimCode.CALCTASK(index = sourceTaskId) = sourceTask;
          HpcOmSimCode.CALCTASK(index = targetTaskId) = targetTask;
          lockId = findInIntTuple1(arrayGet(lockIds,sourceTaskId),targetTaskId);
          tmpTask = HpcOmSimCode.DEPTASK(sourceTask,targetTask,outgoing,lockId,communicationInfo);
      then tmpTask;
    else
    then iTask;
  end match;
end findTaskWithLockId;

protected function findInIntTuple1
  input list<tuple<Integer,Integer>> liste;
  input Integer toFind;
  output Integer secondElement;

protected
  Integer first, second;
  tuple<Integer,Integer> iter;

algorithm
  for iter in liste loop
    (first,second) := iter;
    if intEq(first,toFind) then

      secondElement := second;
      return;
    end if;
  end for;

end findInIntTuple1;


protected function convertFixedLevelScheduleToTaskListsForLevel
  "Convert a level task list into a task list for each thread.
  author:marcusw"
  input HpcOmSimCode.TaskList iTasksOfLevel;
  input Integer iThreadCount;
  output array<list<HpcOmSimCode.Task>> oThreadTasks; //mapping thread -> task list
protected
  array<list<HpcOmSimCode.Task>> tmpTaskLists;
  list<HpcOmSimCode.Task> tasks;
algorithm
  oThreadTasks := match(iTasksOfLevel,iThreadCount)
    case(HpcOmSimCode.PARALLELTASKLIST(tasks=tasks),_)
      equation
        tmpTaskLists = arrayCreate(iThreadCount, {});
        tmpTaskLists = List.fold(tasks, convertFixedLevelScheduleToTaskListsForTask, tmpTaskLists);
        tmpTaskLists = revertTaskList(1, tmpTaskLists);
      then tmpTaskLists;
    case(HpcOmSimCode.SERIALTASKLIST(tasks=tasks),_)
      equation
        tmpTaskLists = arrayCreate(iThreadCount, {});
        tmpTaskLists = arrayUpdate(tmpTaskLists, 1, tasks);
      then tmpTaskLists;
  end match;
end convertFixedLevelScheduleToTaskListsForLevel;

protected function convertFixedLevelScheduleToTaskListsForTask
  "Insert the given Task into the task list of the given thread advice (threadIdx).
  author:marcusw"
  input HpcOmSimCode.Task iTask;
  input array<list<HpcOmSimCode.Task>> iThreadTasks;
  output array<list<HpcOmSimCode.Task>> oThreadTasks;
protected
  array<list<HpcOmSimCode.Task>> tmpTaskLists;
  Integer threadIdx;
  list<HpcOmSimCode.Task> oldTaskList;
algorithm
  oThreadTasks := match(iTask, iThreadTasks)
    case(HpcOmSimCode.CALCTASK_LEVEL(threadIdx=SOME(threadIdx)),_)
      equation
        oldTaskList = arrayGet(iThreadTasks, threadIdx);
        tmpTaskLists = arrayUpdate(iThreadTasks, threadIdx, iTask::oldTaskList);
      then tmpTaskLists;
    case(_,_)
      equation
        print("ConvertFixedLevelScheduleToTaskListsForTask can just handle CALCTASK_LEVEL with defined thread idx!\n");
      then iThreadTasks;
  end match;
end convertFixedLevelScheduleToTaskListsForTask;

protected function printRealArray "author:Waurich TUD 2013-11
  prints the information of the ALAP array"
  input array<Real> inArray;
  input String header;
algorithm
  print("The "+header+"\n");
  print("-----------------------------------------\n");
  _ := Array.fold1(inArray,printRealArray1,header,1);
  print("\n");
end printRealArray;

protected function printRealArray1
  input Real inValue;
  input String header;
  input Integer idxIn;
  output Integer idxOut;
algorithm
  print("node: "+intString(idxIn)+" has the "+header+": "+realString(inValue)+"\n");
  idxOut := idxIn +1;
end printRealArray1;

protected function intListString
  input list<Integer> lstIn;
  output String s;
algorithm
  s := stringDelimitList(List.map(lstIn,intString)," , ");
  s := if listEmpty(lstIn) then "{}" else s;
end intListString;

protected function intListListString
  input list<list<Integer>> lstIn;
  output String s;
algorithm
  s := stringDelimitList(List.map(lstIn,intListString)," | ");
end intListListString;

public function expandSchedule "author:marcusw
  increase the size of the scheduler datastructure from
  iNumUsedProc to iNumProc, by adding empty task lists to the scheduler structure."
  input Integer iNumProc;
  input Integer iNumUsedProc;
  input HpcOmSimCode.Schedule iSchedule;
  output HpcOmSimCode.Schedule oSchedule;
protected
  array<list<HpcOmSimCode.Task>> threadTasks;
  list<HpcOmSimCode.Task> outgoingDepTasks;
  list<HpcOmSimCode.Task> scheduledTasks;
  array<tuple<HpcOmSimCode.Task, Integer>> allCalcTasks;
algorithm
  oSchedule := match(iNumProc, iNumUsedProc, iSchedule)
    case(_,_,HpcOmSimCode.LEVELSCHEDULE())
      then iSchedule;
    case(_,_,HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,outgoingDepTasks=outgoingDepTasks,scheduledTasks=scheduledTasks,allCalcTasks=allCalcTasks))
      equation
        threadTasks = Array.expandToSize(iNumProc, threadTasks, {});
      then HpcOmSimCode.THREADSCHEDULE(threadTasks,outgoingDepTasks,scheduledTasks,allCalcTasks);
    case(_,_,HpcOmSimCode.TASKDEPSCHEDULE())
      then iSchedule;
    case(_,_,HpcOmSimCode.EMPTYSCHEDULE())
      then iSchedule;
  end match;
end expandSchedule;

annotation(__OpenModelica_Interface="backend");
end HpcOmScheduler;
