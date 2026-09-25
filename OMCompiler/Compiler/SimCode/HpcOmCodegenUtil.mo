/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package HpcOmCodegenUtil
"The HpcOm schedule and task-graph queries the code generators need."

import HpcOmSimCode;
import SimCode;

protected
import Error;
import List;

public

public function getTasksOfTaskList
  input HpcOmSimCode.TaskList iTaskList;
  output list<HpcOmSimCode.Task> oTasks;
protected
  list<HpcOmSimCode.Task> tasks;
algorithm
  oTasks := match iTaskList
    case HpcOmSimCode.PARALLELTASKLIST(tasks=tasks)
      then tasks;
    case HpcOmSimCode.SERIALTASKLIST(tasks=tasks)
      then tasks;
    else
      algorithm
        print("getTasksOfTaskList failed! Unsupported task list.\n");
      then {};
  end match;
end getTasksOfTaskList;

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
  oLevelThreadLists := match iSchedule
    case HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevels,useFixedAssignments=true)
      algorithm
        tmpLevelThreadLists := List.map(tasksOfLevels, function convertFixedLevelScheduleToLevelThreadLists0(iNumOfThreads=iNumOfThreads));
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
  oThreadLevelTasks := match(iOdeSchedule, iDaeSchedule, iZeroFuncSchedule)
    case(HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevelsOde,useFixedAssignments=true), HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevelsDae,useFixedAssignments=true), HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=tasksOfLevelsZeroFunc,useFixedAssignments=true))
      algorithm
        tmpResultLists := arrayCreate(iNumOfThreads, ({},{},{}));
        tmpThreadLevelTasksOde := List.map1(tasksOfLevelsOde, convertFixedLevelScheduleToTaskListsForLevel, iNumOfThreads);
        tmpThreadLevelTasksDae := List.map1(tasksOfLevelsDae, convertFixedLevelScheduleToTaskListsForLevel, iNumOfThreads);
        tmpThreadLevelTasksZeroFunc := List.map1(tasksOfLevelsZeroFunc, convertFixedLevelScheduleToTaskListsForLevel, iNumOfThreads);
        //print("convertFixedLevelScheduleToTaskLists: len of tmpThreadLevelTasksOde=" + intString(listLength(tmpThreadLevelTasksOde)) + "\n");
        tmpResultLists := List.fold(tmpThreadLevelTasksOde, function convertFixedLevelScheduleToTaskLists1(iCurrentThreadIdx=1, iModifiedSystemIdx=0), tmpResultLists);
        tmpResultLists := List.fold(tmpThreadLevelTasksDae, function convertFixedLevelScheduleToTaskLists1(iCurrentThreadIdx=1, iModifiedSystemIdx=1), tmpResultLists);
        tmpResultLists := List.fold(tmpThreadLevelTasksZeroFunc, function convertFixedLevelScheduleToTaskLists1(iCurrentThreadIdx=1, iModifiedSystemIdx=2), tmpResultLists);
        //print("convertFixedLevelScheduleToTaskLists: len of tmpResultLists[0]=" + intString(listLength(Util.tuple21(arrayGet(tmpResultLists, 1)))) + "\n");
        tmpResultLists := revertTaskLists(1, tmpResultLists);
        //print("convertFixedLevelScheduleToTaskLists: len of tmpResultLists[0]=" + intString(listLength(Util.tuple21(arrayGet(tmpResultLists, 1)))) + "\n");
      then tmpResultLists;
    else
      algorithm
        tmpResultLists := arrayCreate(iNumOfThreads, ({},{},{}));
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
  oResultList := matchcontinue iResultList
    case _
      algorithm
        true := intLe(iCurrentThreadIdx, arrayLength(iLevelTasks));
        (entryOde, entryDae, entryZeroFunc) := arrayGet(iResultList, iCurrentThreadIdx);
        if(intEq(iModifiedSystemIdx,0)) then
          entryOde := arrayGet(iLevelTasks, iCurrentThreadIdx)::entryOde;
        else
          if(intEq(iModifiedSystemIdx, 1)) then
            entryDae := arrayGet(iLevelTasks, iCurrentThreadIdx)::entryDae;
          else
            entryZeroFunc := arrayGet(iLevelTasks, iCurrentThreadIdx)::entryZeroFunc;
          end if;
        end if;
        tmpResultList := arrayUpdate(iResultList, iCurrentThreadIdx, (entryOde, entryDae, entryZeroFunc));
        tmpResultList := convertFixedLevelScheduleToTaskLists1(iLevelTasks, iCurrentThreadIdx+1, iModifiedSystemIdx, tmpResultList);
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
  oResultList := matchcontinue iResultList
    case _
      algorithm
        true := intLe(iCurrentArrayIdx, arrayLength(iResultList));
        (entryOde,entryDae,entryZeroFunc) := arrayGet(iResultList, iCurrentArrayIdx);
        entryOde := listReverse(entryOde);
        entryDae := listReverse(entryDae);
        entryZeroFunc := listReverse(entryZeroFunc);
        tmpResultList := arrayUpdate(iResultList, iCurrentArrayIdx, (entryOde,entryDae,entryZeroFunc));
        tmpResultList := revertTaskLists(iCurrentArrayIdx+1, tmpResultList);
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
  oResultList := matchcontinue iResultList
    case _
      algorithm
        true := intLe(iCurrentArrayIdx, arrayLength(iResultList));
        entry := arrayGet(iResultList, iCurrentArrayIdx);
        entry := listReverse(entry);
        tmpResultList := arrayUpdate(iResultList, iCurrentArrayIdx, entry);
        //tmpResultList = revertTaskList(iCurrentArrayIdx+1, tmpResultList);
      then tmpResultList;
    else iResultList;
  end matchcontinue;
end revertTaskList;

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
  oThreadTasks := match iTasksOfLevel
    case HpcOmSimCode.PARALLELTASKLIST(tasks=tasks)
      algorithm
        tmpTaskLists := arrayCreate(iThreadCount, {});
        tmpTaskLists := List.fold(tasks, convertFixedLevelScheduleToTaskListsForTask, tmpTaskLists);
        tmpTaskLists := revertTaskList(1, tmpTaskLists);
      then tmpTaskLists;
    case HpcOmSimCode.SERIALTASKLIST(tasks=tasks)
      algorithm
        tmpTaskLists := arrayCreate(iThreadCount, {});
        tmpTaskLists := arrayUpdate(tmpTaskLists, 1, tasks);
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
  oThreadTasks := match iTask
    case HpcOmSimCode.CALCTASK_LEVEL(threadIdx=SOME(threadIdx))
      algorithm
        oldTaskList := arrayGet(iThreadTasks, threadIdx);
        tmpTaskLists := arrayUpdate(iThreadTasks, threadIdx, iTask::oldTaskList);
      then tmpTaskLists;
    case _
      algorithm
        print("ConvertFixedLevelScheduleToTaskListsForTask can just handle CALCTASK_LEVEL with defined thread idx!\n");
      then iThreadTasks;
  end match;
end convertFixedLevelScheduleToTaskListsForTask;

public function getSimCodeEqByIndex "author: marcusw
  Returns the SimEqSystem which has the given Index. This method is called from susan."
  input list<SimCode.SimEqSystem> iEqs; //All SimEqSystems
  input Integer iIdx; //The index of the required system
  output SimCode.SimEqSystem oEq;
protected
  list<SimCode.SimEqSystem> rest;
  SimCode.SimEqSystem head;
  Integer headIdx,headIdx2;
algorithm
  oEq := matchcontinue iEqs
    case head::rest
      algorithm
        (headIdx,headIdx2) := getIndexBySimCodeEq(head);
        //print("getSimCodeEqByIndex listLength: " + intString(listLength(iEqs)) + " head idx: " + intString(headIdx) + "\n");
        true := intEq(headIdx,iIdx) or intEq(headIdx2,iIdx);
      then head;
    case head::rest then getSimCodeEqByIndex(rest,iIdx);
    else
      algorithm
        print("getSimCodeEqByIndex failed. Looking for Index " + intString(iIdx) + "\n");
        //print(" -- available indices: " + stringDelimitList(List.map(List.map(iEqs,getIndexBySimCodeEq), intString), ",") + "\n");
      then fail();
  end matchcontinue;
end getSimCodeEqByIndex;

public function getIndexBySimCodeEq "author: marcusw
  Just a small helper function to get the index of a SimEqSystem."
  input SimCode.SimEqSystem iEq;
  output Integer oIdx;
  output Integer oIdx2;
protected
  Integer index,index2;
algorithm
  (oIdx,oIdx2) := match iEq
    case SimCode.SES_RESIDUAL(index=index) then (index,0);
    case SimCode.SES_SIMPLE_ASSIGN(index=index) then (index,0);
    case SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS(index=index) then (index,0);
    case SimCode.SES_ARRAY_CALL_ASSIGN(index=index) then (index,0);
    case SimCode.SES_IFEQUATION(index=index) then (index,0);
    case SimCode.SES_ALGORITHM(index=index) then (index,0);
    // no dynamic tearing
    case SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(index=index), NONE()) then (index,0);
    case SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(index=index), NONE()) then (index,0);
    // dynamic tearing
    case SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(index=index), SOME(SimCode.LINEARSYSTEM(index=index2))) then (index,index2);
    case SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(index=index), SOME(SimCode.NONLINEARSYSTEM(index=index2))) then (index,index2);
    case SimCode.SES_MIXED(index=index) then (index,0);
    case SimCode.SES_WHEN(index=index) then (index,0);
    case SimCode.SES_ALIAS(aliasOf=index) then (index,0);
    else
      algorithm
        Error.addInternalError(getInstanceName()+" failed", sourceInfo());
      then fail();
  end match;
end getIndexBySimCodeEq;

annotation(__OpenModelica_Interface="codegen_util");
end HpcOmCodegenUtil;
