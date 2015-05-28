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

encapsulated package HpcOmSimCode

  public import HashTableCrILst;
  public import SimCodeVar;

  public constant HpcOmData emptyHpcomData = HPCOMDATA(NONE(), NONE());

  public uniontype HpcOmData
    record HPCOMDATA
      Option<tuple<HpcOmSimCode.Schedule, HpcOmSimCode.Schedule>> schedules; //<ode schedule, dae schedule>
      Option<HpcOmSimCode.MemoryMap> hpcOmMemory;
    end HPCOMDATA;
  end HpcOmData;

  public uniontype MemoryMap //stores information to organize the memory for the parallel code in an efficient way
    record MEMORYMAP_ARRAY
      Integer floatArraySize; //array size including state, state der and other float variables that are necessary for code generation
      Integer intArraySize;
      Integer boolArraySize;
    end MEMORYMAP_ARRAY;
    record MEMORYMAP_UNIFORM
    end MEMORYMAP_UNIFORM;
  end MemoryMap;

  public uniontype CommunicationInfo //stores more detailed information about a communication (edge)
    record COMMUNICATION_INFO
      list<SimCodeVar.SimVar> floatVars; //the float, int and boolean variables that have to be transfered
      list<SimCodeVar.SimVar> intVars;
      list<SimCodeVar.SimVar> boolVars;
    end COMMUNICATION_INFO;
  end CommunicationInfo;

  public uniontype Task
    record SCHEDULED_TASK
      Integer compIdx;
      Integer numThreads;
      Schedule taskSchedule;
    end SCHEDULED_TASK;
    record CALCTASK //Task which calculates something
      Integer weighting;
      Integer index;
      Real calcTime;
      Real timeFinished;
      Integer threadIdx;
      list<Integer> eqIdc;
    end CALCTASK;
    record CALCTASK_LEVEL
      list<Integer> eqIdc;
      list<Integer> nodeIdc; //graph-node indices of same level nodes
      Option<Integer> threadIdx; //an advice which thread should calculate the task
    end CALCTASK_LEVEL;
    record DEPTASK
      Task sourceTask;
      Task targetTask;
      Boolean outgoing; //true if the dependency is leading to the task of another thread
      CommunicationInfo communicationInfo;
    end DEPTASK;
    record PREFETCHTASK //This task will load variables in the cache
      list<Integer> varIdc;
      Integer varArrayidx;
    end PREFETCHTASK;
    record TASKEMPTY //Dummy Task
    end TASKEMPTY;
  end Task;

  public uniontype TaskList
    record PARALLELTASKLIST
      list<Task> tasks;
    end PARALLELTASKLIST;
    record SERIALTASKLIST
      list<Task> tasks;
      Boolean masterOnly; //Set to true if only the master thread should calculate the tasks in the list
    end SERIALTASKLIST;
  end TaskList;

  //TODO: Use the TaskList for the other schedulers, too
  public uniontype Schedule   // stores all scheduling-informations
    record LEVELSCHEDULE
      list<TaskList> tasksOfLevels; //List of tasks solved in the same level in parallel
      Boolean useFixedAssignments; //true if the scheduling is fully static -> all tasks need to have a threadIdx
    end LEVELSCHEDULE;
    record THREADSCHEDULE
      array<list<Task>> threadTasks; //List of tasks assigned to the thread <%idx%>
      list<Task> outgoingDepTasks; //all outgoing dep-tasks -> can be used for example to initialize locks
      list<Task> scheduledTasks;
      array<tuple<Task,Integer>> allCalcTasks; //mapping task idx -> (calc task, reference counter)
    end THREADSCHEDULE;
    record TASKDEPSCHEDULE
      list<tuple<Task,list<Integer>>> tasks; //topological sorted tasks with <taskIdx, parentTaskIdc>
    end TASKDEPSCHEDULE;
    record EMPTYSCHEDULE  // a dummy schedule. used if there is no ODE-system or if the serial code should be produced
      TaskList tasks;
    end EMPTYSCHEDULE;
  end Schedule;

annotation(__OpenModelica_Interface="backend");
end HpcOmSimCode;
