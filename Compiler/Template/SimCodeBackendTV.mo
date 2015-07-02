interface package SimCodeBackendTV

package BackendVariable

  function isStateVar
    input BackendDAE.Var inVar;
    output Boolean outBoolean;
  end isStateVar;

end BackendVariable;

package HpcOmScheduler
  function convertFixedLevelScheduleToTaskLists
    input HpcOmSimCode.Schedule iOdeSchedule;
    input HpcOmSimCode.Schedule iDaeSchedule;
    input Integer iNumOfThreads;
    output array<tuple<list<list<HpcOmSimCode.Task>>,list<list<HpcOmSimCode.Task>>>> oThreadLevelTasks;
  end convertFixedLevelScheduleToTaskLists;
end HpcOmScheduler;

end SimCodeBackendTV;
