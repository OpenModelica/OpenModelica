interface package SimCodeBackendTV

package BackendVariable

  function isStateVar
    input BackendDAE.Var inVar;
    output Boolean outBoolean;
  end isStateVar;

end BackendVariable;


package HpcOmSimCode
  uniontype HpcOmData
    record HPCOMDATA
      Option<tuple<HpcOmSimCode.Schedule, HpcOmSimCode.Schedule, HpcOmSimCode.Schedule>> schedules;
      Option<MemoryMap> hpcOmMemory;
    end HPCOMDATA;
  end HpcOmData;

  uniontype CommunicationInfo //stores more detailed information about a communication (edge)
    record COMMUNICATION_INFO
      list<SimCodeVar.SimVar> floatVars; //the float, int and boolean variables that have to be transfered
      list<SimCodeVar.SimVar> intVars;
      list<SimCodeVar.SimVar> boolVars;
    end COMMUNICATION_INFO;
  end CommunicationInfo;

  uniontype Task
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
      list<Integer> nodeIdc;
      Option<Integer> threadIdx;
    end CALCTASK_LEVEL;
    record DEPTASK
      Task sourceTask;
      Task targetTask;
      Boolean outgoing; //true if the dependency is leading to the task of another thread
      Integer id;
      CommunicationInfo communicationInfo;
    end DEPTASK;
  end Task;

  uniontype TaskList
    record PARALLELTASKLIST
      list<Task> tasks;
    end PARALLELTASKLIST;
    record SERIALTASKLIST
      list<Task> tasks;
    end SERIALTASKLIST;
  end TaskList;

  uniontype Schedule
    record LEVELSCHEDULE
      list<TaskList> tasksOfLevels;
      Boolean useFixedAssignments;
    end LEVELSCHEDULE;
    record THREADSCHEDULE
      array<list<Task>> threadTasks;
      list<Task> outgoingDepTasks;
    end THREADSCHEDULE;
    record TASKDEPSCHEDULE
      list<tuple<Task,list<Integer>>> tasks;
    end TASKDEPSCHEDULE;
    record EMPTYSCHEDULE
      TaskList tasks;
    end EMPTYSCHEDULE;
  end Schedule;

  uniontype MemoryMap
    record MEMORYMAP_ARRAY
      Integer floatArraySize;
      Integer intArraySize;
      Integer boolArraySize;
    end MEMORYMAP_ARRAY;
  end MemoryMap;
end HpcOmSimCode;

package HpcOmScheduler
  function convertFixedLevelScheduleToTaskLists
    input HpcOmSimCode.Schedule iOdeSchedule;
    input HpcOmSimCode.Schedule iDaeSchedule;
    input HpcOmSimCode.Schedule iZeroFuncSchedule;
    input Integer iNumOfThreads;
    output array<tuple<list<list<HpcOmSimCode.Task>>,list<list<HpcOmSimCode.Task>>,list<list<HpcOmSimCode.Task>>>> oThreadLevelTasks;
  end convertFixedLevelScheduleToTaskLists;
end HpcOmScheduler;

package HpcOmSimCodeMain
  function getSimCodeEqByIndex
    input list<SimCode.SimEqSystem> iEqs;
    input Integer iIdx;
    output SimCode.SimEqSystem oEq;
  end getSimCodeEqByIndex;
end HpcOmSimCodeMain;

end SimCodeBackendTV;
