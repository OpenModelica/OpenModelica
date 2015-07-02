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


package FMI
  uniontype Info
    record INFO
      String fmiVersion;
      Integer fmiType;
      String fmiModelName;
      String fmiModelIdentifier;
      String fmiGuid;
      String fmiDescription;
      String fmiGenerationTool;
      String fmiGenerationDateAndTime;
      String fmiVariableNamingConvention;
      list<Integer> fmiNumberOfContinuousStates;
      list<Integer> fmiNumberOfEventIndicators;
    end INFO;
  end Info;

  uniontype TypeDefinitions
    record ENUMERATIONTYPE
      String name;
      String description;
      String quantity;
      Integer min;
      Integer max;
      list<EnumerationItem> items;
    end ENUMERATIONTYPE;
  end TypeDefinitions;

  uniontype EnumerationItem
    record ENUMERATIONITEM
      String name;
      String description;
    end ENUMERATIONITEM;
  end EnumerationItem;

  uniontype ExperimentAnnotation
    record EXPERIMENTANNOTATION
      Real fmiExperimentStartTime;
      Real fmiExperimentStopTime;
      Real fmiExperimentTolerance;
    end EXPERIMENTANNOTATION;
  end ExperimentAnnotation;

  uniontype ModelVariables
    record REALVARIABLE
      Integer instance;
      String name;
      String description;
      String baseType;
      String variability;
      String causality;
      Boolean hasStartValue;
      Real startValue;
      Boolean isFixed;
      Real valueReference;
      Integer x1Placement;
      Integer x2Placement;
      Integer y1Placement;
      Integer y2Placement;
    end REALVARIABLE;

    record INTEGERVARIABLE
      Integer instance;
      String name;
      String description;
      String baseType;
      String variability;
      String causality;
      Boolean hasStartValue;
      Integer startValue;
      Boolean isFixed;
      Real valueReference;
      Integer x1Placement;
      Integer x2Placement;
      Integer y1Placement;
      Integer y2Placement;
    end INTEGERVARIABLE;

    record BOOLEANVARIABLE
      Integer instance;
      String name;
      String description;
      String baseType;
      String variability;
      String causality;
      Boolean hasStartValue;
      Boolean startValue;
      Boolean isFixed;
      Real valueReference;
      Integer x1Placement;
      Integer x2Placement;
      Integer y1Placement;
      Integer y2Placement;
    end BOOLEANVARIABLE;

    record STRINGVARIABLE
      Integer instance;
      String name;
      String description;
      String baseType;
      String variability;
      String causality;
      Boolean hasStartValue;
      String startValue;
      Boolean isFixed;
      Real valueReference;
      Integer x1Placement;
      Integer x2Placement;
      Integer y1Placement;
      Integer y2Placement;
    end STRINGVARIABLE;

    record ENUMERATIONVARIABLE
      Integer instance;
      String name;
      String description;
      String baseType;
      String variability;
      String causality;
      Boolean hasStartValue;
      Integer startValue;
      Boolean isFixed;
      Real valueReference;
      Integer x1Placement;
      Integer x2Placement;
      Integer y1Placement;
      Integer y2Placement;
    end ENUMERATIONVARIABLE;
  end ModelVariables;

  uniontype FmiImport
    record FMIIMPORT
      String platform;
      String fmuFileName;
      String fmuWorkingDirectory;
      Integer fmiLogLevel;
      Boolean fmiDebugOutput;
      Option<Integer> fmiContext;
      Option<Integer> fmiInstance;
      Info fmiInfo;
      list<TypeDefinitions> fmiTypeDefinitionsList;
      ExperimentAnnotation fmiExperimentAnnotation;
      Option<Integer> fmiModelVariablesInstance;
      list<ModelVariables> fmiModelVariablesList;
      Boolean generateInputConnectors;
      Boolean generateOutputConnectors;
    end FMIIMPORT;
  end FmiImport;

  function getFMIType
    input Info inFMIInfo;
    output String fmiType;
  end getFMIType;

  function isFMIVersion20 "Checks if the FMI version is 2.0."
    input String inFMUVersion;
    output Boolean success;
  end isFMIVersion20;

  function isFMICSType "Checks if FMU type is co-simulation"
    input String inFMIType;
    output Boolean success;
  end isFMICSType;

  function getEnumerationTypeFromTypes
    input list<TypeDefinitions> inTypeDefinitionsList;
    input String inBaseType;
    output String outEnumerationType;
  end getEnumerationTypeFromTypes;
end FMI;

end SimCodeBackendTV;
