// This file defines template-extensions for transforming Modelica code into parallel hpcom-code.
//
// There are one root template intended to be called from the code generator:
// translateModel. These template do not return any
// result but instead write the result to files. All other templates return
// text and are used by the root templates (most of them indirectly).

package CodegenCppHpcom

import interface SimCodeTV;
import CodegenUtil.*;
import CodegenCpp.*; //unqualified import, no need the CodegenC is optional when calling a template; or mandatory when the same named template exists in this package (name hiding)


// ----------------------
// BEGIN COPIED FUNCTIONS
// ----------------------

template translateModel(SimCode simCode) ::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__), makefileParams= MAKEFILE_PARAMS(__)) then
  let target  = simulationCodeTarget()
  let()= textFile((if Flags.isSet(Flags.HPCOM_ANALYZATION_MODE) then simulationMainFileAnalyzation(simCode) else simulationMainFile(simCode)), 'OMCpp<%fileNamePrefix%>Main.cpp')
  let()= textFile(simulationHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>.h')
  let()= textFile(simulationCppFile(simCode), 'OMCpp<%fileNamePrefix%>.cpp')
  let()= textFile(simulationFunctionsHeaderFile(simCode,modelInfo.functions,literals), 'OMCpp<%fileNamePrefix%>Functions.h')
  let()= textFile(simulationFunctionsFile(simCode, modelInfo.functions,literals,externalFunctionIncludes), 'OMCpp<%fileNamePrefix%>Functions.cpp')
  let()= textFile(simulationMakefile(target,simCode), '<%fileNamePrefix%>.makefile')
  let()= textFile(simulationInitHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>Initialize.h')
  let()= textFile(simulationInitCppFile(simCode),'OMCpp<%fileNamePrefix%>Initialize.cpp')
  let()= textFile(simulationJacobianHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>Jacobian.h')
  let()= textFile(simulationJacobianCppFile(simCode),'OMCpp<%fileNamePrefix%>Jacobian.cpp')
  let()= textFile(simulationStateSelectionCppFile(simCode), 'OMCpp<%fileNamePrefix%>StateSelection.cpp')
  let()= textFile(simulationStateSelectionHeaderFile(simCode),'OMCpp<%fileNamePrefix%>StateSelection.h')
  let()= textFile(simulationExtensionHeaderFile(simCode),'OMCpp<%fileNamePrefix%>Extension.h')
  let()= textFile(simulationExtensionCppFile(simCode),'OMCpp<%fileNamePrefix%>Extension.cpp')
  let()= textFile(simulationWriteOutputHeaderFile(simCode),'OMCpp<%fileNamePrefix%>WriteOutput.h')
  let()= textFile(simulationWriteOutputCppFile(simCode),'OMCpp<%fileNamePrefix%>WriteOutput.cpp')
  let()= textFile(simulationFactoryFile(simCode),'OMCpp<%fileNamePrefix%>FactoryExport.cpp')
  let()= textFile(simulationMainRunScrip(simCode), '<%fileNamePrefix%><%simulationMainRunScripSuffix(simCode)%>')
  let jac =  (jacobianMatrixes |> (mat, _,_, _, _, _) hasindex index0 =>
          (mat |> (eqs,_,_) =>  algloopfiles(eqs,simCode,contextAlgloopJacobian) ;separator="")
         ;separator="")
  let algs = algloopfiles(listAppend(allEquations,initialEquations),simCode,contextAlgloop)
 ""
  // empty result of the top-level template .., only side effects
end translateModel;

template simulationHeaderFile(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(__) then
  <<
   <%generateHeaderInlcudeString(simCode)%>
   <%generateHpcomSpecificIncludes(simCode)%>
   <%generateClassDeclarationCode(simCode)%>

   >>
end simulationHeaderFile;

template simulationCppFile(SimCode simCode)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let hpcomConstructorExtension = getHpcomConstructorExtension(hpcOmSchedule, lastIdentOfPath(modelInfo.name))
  let hpcomDestructorExtension = getHpcomDestructorExtension(hpcOmSchedule)
  <<
   #include "Modelica.h"
   #include "OMCpp<%fileNamePrefix%>.h"
 
    
    <%lastIdentOfPath(modelInfo.name)%>::<%lastIdentOfPath(modelInfo.name)%>(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData) 
   :SystemDefaultImplementation(*globalSettings)
    ,_algLoopSolverFactory(nonlinsolverfactory)
    ,_simData(simData)
    <%simulationInitFile(simCode)%>
    {
    //Number of equations
    <%dimension1(simCode)%>
    _dimZeroFunc= <%zerocrosslength(simCode)%>;
    _dimTimeEvent = <%timeeventlength(simCode)%>;
    //Number of residues
    <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
      <<
      _dimResidues=<%numResidues(allEquations)%>;
      >>
    %>
    //DAE's are not supported yet, Index reduction is enabled
    _dimAE = 0; // algebraic equations
    //Initialize the state vector
    SystemDefaultImplementation::initialize();
    //Instantiate auxiliary object for event handling functionality
    _event_handling.getCondition =  boost::bind(&<%lastIdentOfPath(modelInfo.name)%>::getCondition, this, _1);
     <%arrayReindex(modelInfo)%>
    //Initialize array elements
    <%initializeArrayElements(simCode)%>
   
    <%hpcomConstructorExtension%>

    }
    <%lastIdentOfPath(modelInfo.name)%>::~<%lastIdentOfPath(modelInfo.name)%>()
    {
       <%hpcomDestructorExtension%>
    }
  
  
   <%Update(simCode)%>
  
   <%DefaultImplementationCode(simCode)%>
   <%checkForDiscreteEvents(discreteModelVars,simCode)%>
   <%giveZeroFunc1(zeroCrossings,simCode)%>
   <%setConditions(simCode)%>
   <%geConditions(simCode)%>
   <%isConsistent(simCode)%>
   <%generateStepCompleted(listAppend(allEquations,initialEquations),simCode)%>
   <%generatehandleTimeEvent(timeEvents, simCode)%>
   <%generateDimTimeEvent(listAppend(allEquations,initialEquations),simCode)%>
   <%generateTimeEvent(timeEvents, simCode)%>
   
   
   <%isODE(simCode)%>
   <%DimZeroFunc(simCode)%>
  
   
  
   <%getCondition(zeroCrossings,whenClauses,simCode)%>
   <%handleSystemEvents(zeroCrossings,whenClauses,simCode)%>
   <%saveall(modelInfo,simCode)%>
   <%savediscreteVars(modelInfo,simCode)%>
   <%LabeledDAE(modelInfo.labels,simCode)%>
    <%giveVariables(modelInfo)%>
   >>
end simulationCppFile;

template Update(SimCode simCode)
::=
match simCode
case SIMCODE(__) then
  <<
  <%update(allEquations,whenClauses,simCode,contextOther)%>
  >>
end Update;

// --------------------
// END COPIED FUNCTIONS
// --------------------

// HEADER

template generateClassDeclarationCode(SimCode simCode)
 "Generates class declarations."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let addHpcomFunctionHeaders = getAddHpcomFunctionHeaders(hpcOmSchedule)
  let addHpcomVarHeaders = getAddHpcomVarHeaders(hpcOmSchedule)
  << 
  class <%lastIdentOfPath(modelInfo.name)%>: public IContinuous, public IEvent,  public ITime, public ISystemProperties <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then ', public IReduceDAE'%>, public SystemDefaultImplementation
  {

   <%generatefriendAlgloops(listAppend(allEquations,initialEquations),simCode)%>

  public: 
      <%lastIdentOfPath(modelInfo.name)%>(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactor,boost::shared_ptr<ISimData>); 

      ~<%lastIdentOfPath(modelInfo.name)%>();

       <%generateMethodDeclarationCode(simCode)%>
     virtual  bool getCondition(unsigned int index);
  protected:

    //Methods:
    
    <%addHpcomFunctionHeaders%>
    
     bool isConsistent();
    //Called to handle all  events occured at same time
    bool handleSystemEvents( bool* events);
     //Saves all variables before an event is handled, is needed for the pre, edge and change operator
    void saveAll();
    void getJacobian(SparseMatrix& matrix);
    
    
     //Variables:
     
     <%addHpcomVarHeaders%>
     
     EventHandling _event_handling;

     <%MemberVariable(modelInfo)%>
     <%conditionvariable(zeroCrossings,simCode)%>
     Functions _functions;
  
  
     boost::shared_ptr<IAlgLoopSolverFactory>
        _algLoopSolverFactory;    ///< Factory that provides an appropriate solver
     <%generateAlgloopsolverVariables(listAppend(allEquations,initialEquations),simCode)%>
   
    boost::shared_ptr<ISimData> _simData;

   };
  >>
end generateClassDeclarationCode;

template getAddHpcomFunctionHeaders(Option<ScheduleSimCode> hpcOmScheduleOpt)
::=
  match hpcOmScheduleOpt 
    case SOME(hpcOmSchedule as THREADSCHEDULESC(__)) then
        let type = getConfigString(HPCOM_CODE)
        let locks = hpcOmSchedule.lockIdc |> idx => function_HPCOM_createLock(idx, "lock", type); separator="\n"
        
        match type 
            case ("openmp") then
                <<
                >>
            else
                let headers = hpcOmSchedule.threadTasks |> tt hasindex i0 fromindex 0 => generateThreadFunctionHeaderDecl(i0); separator="\n"
                <<
                <%headers%>
                >>  
end getAddHpcomFunctionHeaders;

template getAddHpcomVarHeaders(Option<ScheduleSimCode> hpcOmScheduleOpt)
::=
  match hpcOmScheduleOpt 
    case SOME(hpcOmSchedule as THREADSCHEDULESC(__)) then
        let type = getConfigString(HPCOM_CODE)
        let locks = hpcOmSchedule.lockIdc |> idx => function_HPCOM_createLock(idx, "lock", type); separator="\n"
        let threadDecl = hpcOmSchedule.threadTasks |> tt hasindex i0 fromindex 0 => generateThreadHeaderDecl(i0, type); separator="\n"
        match type 
            case ("openmp") then
                <<
                <%locks%>
                <%threadDecl%>
                >>
            else
                let thLocks = hpcOmSchedule.threadTasks |> tt hasindex i0 fromindex 0 => function_HPCOM_createLock(i0, "th_lock", type); separator="\n"
                let thLocks1 = hpcOmSchedule.threadTasks |> tt hasindex i0 fromindex 0 => function_HPCOM_createLock(i0, "th_lock1", type); separator="\n"
                <<
                bool terminateThreads;
                UPDATETYPE command;
                <%locks%>
                <%thLocks%>
                <%thLocks1%>
                <%threadDecl%>
                >>
end getAddHpcomVarHeaders;

template generateHpcomSpecificIncludes(SimCode simCode)
::=
    let type = getConfigString(HPCOM_CODE)
    
    match type 
        case ("openmp") then
        <<
        #include <omp.h>
        >>
        case ("pthreads_spin") then
        <<
        #include <boost/smart_ptr/detail/spinlock.hpp>
        #include <boost/thread/mutex.hpp>
        #include <boost/thread.hpp>
        >>
        else
        <<
        #include <boost/thread/mutex.hpp>
        #include <boost/thread.hpp>
        >>
end generateHpcomSpecificIncludes;

template generateThreadHeaderDecl(Integer threadIdx, String iType)
::=
    match iType 
        case ("openmp") then
        <<
        >>
        else
        <<
        boost::thread* evaluateThread<%threadIdx%>;
        >>
end generateThreadHeaderDecl;

template generateThreadFunctionHeaderDecl(Integer threadIdx)
::=
    <<
    void evaluateThreadFunc<%threadIdx%>();
    >>
end generateThreadFunctionHeaderDecl;

// CODE

template getHpcomConstructorExtension(Option<ScheduleSimCode> hpcOmScheduleOpt, String modelNamePrefixStr)
::=
  match hpcOmScheduleOpt 
    case SOME(hpcOmSchedule as THREADSCHEDULESC(__)) then
        let type = getConfigString(HPCOM_CODE)
        let initlocks = hpcOmSchedule.lockIdc |> idx => function_HPCOM_initializeLock(idx, "lock", type); separator="\n"
        let assignLocks = hpcOmSchedule.lockIdc |> idx => function_HPCOM_assignLock(idx, "lock", type); separator="\n"
        let threadFuncs = hpcOmSchedule.threadTasks |> tt hasindex i0 fromindex 0 => generateThread(i0, type, modelNamePrefixStr); separator="\n"
        match type 
            case ("openmp") then
                <<
                    <%threadFuncs%>
                    <%initlocks%>
                    <%assignLocks%>
                >>
            else
                let threadLocksInit = hpcOmSchedule.threadTasks |> tt hasindex i0 fromindex 0 => function_HPCOM_initializeLock(i0, "th_lock", type); separator="\n"
                let threadLocksInit1 = hpcOmSchedule.threadTasks |> tt hasindex i0 fromindex 0 => function_HPCOM_initializeLock(i0, "th_lock1", type); separator="\n"
                let threadAssignLocks = hpcOmSchedule.threadTasks |> tt hasindex i0 fromindex 0 => function_HPCOM_assignLock(i0, "th_lock", type); separator="\n"
                let threadAssignLocks1 = hpcOmSchedule.threadTasks |> tt hasindex i0 fromindex 0 => function_HPCOM_assignLock(i0, "th_lock1", type); separator="\n"
                <<
                    terminateThreads = false;
                    command = IContinuous::UNDEF_UPDATE;
                    
                    <%threadFuncs%>
                    
                    <%initlocks%>
                    <%threadLocksInit%>
                    <%threadLocksInit1%>
                    
                    <%assignLocks%>  
                    <%threadAssignLocks%>
                    <%threadAssignLocks1%>      
                >>       
end getHpcomConstructorExtension;

template getHpcomDestructorExtension(Option<ScheduleSimCode> hpcOmScheduleOpt)
::=
  match hpcOmScheduleOpt 
    case SOME(hpcOmSchedule as THREADSCHEDULESC(__)) then
        let type = getConfigString(HPCOM_CODE)
        let destroylocks = hpcOmSchedule.lockIdc |> idx => function_HPCOM_destroyLock(idx, "lock", type); separator="\n"
        let destroyThreads = hpcOmSchedule.threadTasks |> tt hasindex i0 fromindex 0 => function_HPCOM_destroyThread(i0, type); separator="\n"
        match type 
            case ("openmp") then
                <<
                <%destroylocks%>
                >>
            else
                let joinThreads = hpcOmSchedule.threadTasks |> tt hasindex i0 fromindex 0 => function_HPCOM_joinThread(i0, type); separator="\n"
                <<
                terminateThreads = true;
                <%joinThreads%>
                <%destroylocks%>
                >>
end getHpcomDestructorExtension;

template update( list<SimEqSystem> allEquationsPlusWhen,list<SimWhenClause> whenClauses, SimCode simCode, Context context)
::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
      let parCode = update2(allEquationsPlusWhen, modelInfo.name, whenClauses, simCode, hpcOmSchedule, context, lastIdentOfPath(modelInfo.name))
      <<
      <%parCode%>
      >>
end update;

template update2(list<SimEqSystem> allEquationsPlusWhen, Absyn.Path name, list<SimWhenClause> whenClauses, SimCode simCode, Option<ScheduleSimCode> hpcOmScheduleOpt, Context context, String modelNamePrefixStr)
::=
  let &varDecls = buffer "" /*BUFD*/
  let all_equations = (allEquationsPlusWhen |> eqs => (eqs |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFC*/,simCode))
    ;separator="\n")

  let reinit = (whenClauses |> when hasindex i0 =>
         genreinits(when, &varDecls,i0,simCode,context)
    ;separator="\n";empty)
  let type = getConfigString(HPCOM_CODE)
    
  match hpcOmScheduleOpt 
    case SOME(hpcOmSchedule as LEVELSCHEDULESC(__)) then
      let odeEqs = hpcOmSchedule.tasksOfLevels |> tasks => functionXXX_system0_HPCOM_Level(allEquationsPlusWhen, tasks, type, &varDecls, simCode); separator="\n"
      <<
          bool <%lastIdentOfPath(name)%>::evaluate(const UPDATETYPE command)
          {
            bool state_var_reinitialized = false;
            <%varDecls%>
            <%odeEqs%>
            <%reinit%>
           
            return state_var_reinitialized;
          }
      >>
   case SOME(hpcOmSchedule as THREADSCHEDULESC(__)) then
      
      match type 
        case ("openmp") then
          let taskEqs = functionXXX_system0_HPCOM_Thread(allEquationsPlusWhen,hpcOmSchedule.threadTasks, type, &varDecls, simCode); separator="\n"
          <<
          
          //using type: <%type%>
          bool <%lastIdentOfPath(name)%>::evaluate(const UPDATETYPE command)
          {
            bool state_var_reinitialized = false;
            omp_set_dynamic(0);
            
            <%&varDecls%>
            <%taskEqs%>
            <%reinit%>
           
            return state_var_reinitialized;
          }
          >>
        else
          let threadFuncs = hpcOmSchedule.threadTasks |> tt hasindex i0 fromindex 0 => generateThreadFunc(allEquationsPlusWhen, hpcOmSchedule.threadTasks, type, i0, modelNamePrefixStr, &varDecls, simCode); separator="\n"
          let threadAssignLocks1 = hpcOmSchedule.threadTasks |> tt hasindex i0 fromindex 0 => function_HPCOM_assignLock(i0, "th_lock1", type); separator="\n"
          let threadReleaseLocks = hpcOmSchedule.threadTasks |> tt hasindex i0 fromindex 0 => function_HPCOM_releaseLock(i0, "th_lock", type); separator="\n"
          <<
          
          <%threadFuncs%>
          
          //using type: <%type%>
          bool <%lastIdentOfPath(name)%>::evaluate(const UPDATETYPE command)
          {
            bool state_var_reinitialized = false;
            this->command = command;            
            <%threadReleaseLocks%>
            <%threadAssignLocks1%>
            <%reinit%>
           
            return state_var_reinitialized;
          }
          >>
    case SOME(hpcOmSchedule as TASKDEPSCHEDULESC(__)) then
        let taskEqs = functionXXX_system0_HPCOM_TaskDep(hpcOmSchedule.tasks, allEquationsPlusWhen, type, &varDecls, simCode); separator="\n"
        <<
        //using type: <%type%>
        bool <%lastIdentOfPath(name)%>::evaluate(const UPDATETYPE command)
        {
          bool state_var_reinitialized = false;
          omp_set_dynamic(1);
            
          <%&varDecls%>
          <%taskEqs%>
          <%reinit%>
           
          return state_var_reinitialized;
        }
        >>
end update2;

template functionXXX_system0_HPCOM_Level(list<SimEqSystem> allEquationsPlusWhen, list<Task> tasksOfLevel, String iType, Text &varDecls, SimCode simCode)
::=
  let odeEqs = tasksOfLevel |> task => functionXXX_system0_HPCOM_Level0(allEquationsPlusWhen,task,iType, &varDecls, simCode); separator="\n"
  <<
  if (omp_get_dynamic())
    omp_set_dynamic(0);
  #pragma omp parallel sections num_threads(<%getConfigInt(NUM_PROC)%>)
  {
     <%odeEqs%>
  }
  >>
end functionXXX_system0_HPCOM_Level;

template functionXXX_system0_HPCOM_Level0(list<SimEqSystem> allEquationsPlusWhen, Task iTask, String iType, Text &varDecls, SimCode simCode)
::=
<<
#pragma omp section
{
    <%function_HPCOM_Task(allEquationsPlusWhen,iTask,iType, &varDecls, simCode)%>
}
>>
end functionXXX_system0_HPCOM_Level0;

template functionXXX_system0_HPCOM_TaskDep(list<tuple<Task,list<Integer>>> tasks, list<SimEqSystem> allEquationsPlusWhen, String iType, Text &varDecls, SimCode simCode)
::=
  let odeEqs = tasks |> t => functionXXX_system0_HPCOM_TaskDep0(t,allEquationsPlusWhen, iType, &varDecls, simCode); separator="\n"
  <<
  
  int t[0];
  #pragma omp parallel
  {
    #pragma omp master
    {
        <%odeEqs%>
    }
  }
  >>
end functionXXX_system0_HPCOM_TaskDep;

template functionXXX_system0_HPCOM_TaskDep0(tuple<Task,list<Integer>> taskIn, list<SimEqSystem> allEquationsPlusWhen, String iType, Text &varDecls, SimCode simCode)
::=
  match taskIn 
    case ((task as CALCTASK(__),parents)) then
        let taskEqs = function_HPCOM_Task(allEquationsPlusWhen,task,iType,&varDecls,simCode); separator="\n"
        let parentDependencies = parents |> p => 't[<%p%>]'; separator = ","
        let depIn = if intGt(listLength(parents),0) then 'depend(in:<%parentDependencies%>)' else ""
        <<
        #pragma omp task <%depIn%> depend(out:t[<%task.index%>])
        {
            <%taskEqs%>
        }
        >>
end functionXXX_system0_HPCOM_TaskDep0;

template functionXXX_system0_HPCOM_Thread(list<SimEqSystem> allEquationsPlusWhen, list<list<Task>> threadTasks, String iType, Text &varDecls, SimCode simCode)
::=
  match iType 
    case ("openmp") then
      let odeEqs = threadTasks |> tt => functionXXX_system0_HPCOM_Thread0(allEquationsPlusWhen,tt,iType,&varDecls,simCode); separator="\n"
      <<
      if (omp_get_dynamic())
        omp_set_dynamic(0);
      #pragma omp parallel sections num_threads(<%listLength(threadTasks)%>)
      {
         <%odeEqs%>
      }
      >>
    else
      let odeEqs = threadTasks |> tt => functionXXX_system0_HPCOM_Thread0(allEquationsPlusWhen,tt,iType,&varDecls,simCode); separator="\n"
      <<
      <%odeEqs%>
      >>

end functionXXX_system0_HPCOM_Thread;

template generateThreadFunc(list<SimEqSystem> allEquationsPlusWhen, list<list<Task>> threadTasks, String iType, Integer idx, String modelNamePrefixStr, Text &varDecls, SimCode simCode)
::=
  let &varDeclsLoc = buffer "" /*BUFD*/
  let taskEqs = functionXXX_system0_HPCOM_Thread0(allEquationsPlusWhen, listNth(threadTasks,idx), iType, &varDeclsLoc, simCode); separator="\n"
  let assLock = function_HPCOM_assignLock(idx, "th_lock", iType); separator="\n"
  let relLock = function_HPCOM_releaseLock(idx, "th_lock1", iType); separator="\n"
  <<
  void <%modelNamePrefixStr%>::evaluateThreadFunc<%idx%>()
  { 
    <%&varDeclsLoc%>
    while(1)
    {
      <%assLock%>
      if(terminateThreads)
         return;
      
      <%taskEqs%>
      <%relLock%>
    }
  }
  >>
end generateThreadFunc;

template functionXXX_system0_HPCOM_Thread0(list<SimEqSystem> allEquationsPlusWhen, list<Task> threadTaskList, String iType, Text &varDecls, SimCode simCode)
::=
  let threadTasks = threadTaskList |> tt => function_HPCOM_Task(allEquationsPlusWhen,tt,iType,&varDecls,simCode); separator="\n"
  match iType 
    case ("openmp") then
      <<
      #pragma omp section
      {
        <%threadTasks%>
      }
      >>
    case ("pthreads") then
      <<
      <%threadTasks%>
      >>
    case ("pthreads_spin") then
      <<
      <%threadTasks%>
      >>
end functionXXX_system0_HPCOM_Thread0;

template function_HPCOM_Task(list<SimEqSystem> allEquationsPlusWhen, Task iTask, String iType, Text &varDecls, SimCode simCode)
::=
  match iTask 
    case (task as CALCTASK(__)) then
      let odeEqs = task.eqIdc |> eq => equationNamesHPCOM_(eq,allEquationsPlusWhen,contextSimulationNonDiscrete,&varDecls, simCode); separator="\n"
      <<
      // Task <%task.index%>
      <%odeEqs%>
      // End Task <%task.index%>
      >>
    case (task as CALCTASK_LEVEL(__)) then
      let odeEqs = task.eqIdc |> eq => equationNamesHPCOM_(eq,allEquationsPlusWhen,contextSimulationNonDiscrete,&varDecls, simCode); separator="\n"
      <<
      <%odeEqs%>
      >>
    case (task as ASSIGNLOCKTASK(__)) then
      let assLck = function_HPCOM_assignLock(task.lockId, "lock", iType); separator="\n"
      <<
      //Assign lock <%task.lockId%>
      <%assLck%>
      >>
    case (task as RELEASELOCKTASK(__)) then
      let relLck = function_HPCOM_releaseLock(task.lockId, "lock", iType); separator="\n"
      <<
      //Release lock <%task.lockId%>
      <%relLck%>
      >>
end function_HPCOM_Task;

template equationNamesHPCOM_(Integer idx, list<SimEqSystem> allEquationsPlusWhen, Context context, Text &varDecls, SimCode simCode)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
    let eq =  equation_(getSimCodeEqByIndex(allEquationsPlusWhen, idx), context, &varDecls, simCode)
    <<
    <%eq%>
    >>
end equationNamesHPCOM_;

template equationNamesHPCOMLevel_(Integer idx, list<SimEqSystem> allEquationsPlusWhen, Context context, Text &varDecls, SimCode simCode)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
    let eq =  equation_(getSimCodeEqByIndex(allEquationsPlusWhen, idx), context, &varDecls, simCode)
    <<
    #pragma omp section
    {
        <%eq%>
    }
    >>
end equationNamesHPCOMLevel_;

template function_HPCOM_joinThread(String threadIdx, String iType)
::=
  match iType 
    case ("openmp") then
      <<
      >>
    else
      <<
      evaluateThread<%threadIdx%>->join();
      >>  
end function_HPCOM_joinThread;

template function_HPCOM_destroyThread(String threadIdx, String iType)
::=
  match iType 
    case ("openmp") then
      <<
      >>
    else
      <<
      delete evaluateThread<%threadIdx%>;
      >>  
end function_HPCOM_destroyThread;

template generateThread(Integer threadIdx, String iType, String modelNamePrefixStr)
::=
  match iType 
    case ("openmp") then
      <<
      >>
    else
      <<
      evaluateThread<%threadIdx%> = new boost::thread(boost::bind(&<%modelNamePrefixStr%>::evaluateThreadFunc<%threadIdx%>, this));
      >>  
end generateThread;

template function_HPCOM_initializeLock(String lockIdx, String lockPrefix, String iType)
::=
  match iType 
    case ("openmp") then
      <<
      omp_init_lock(&<%lockPrefix%>_<%lockIdx%>);
      >>
    case ("pthreads") then
      <<
      >>
    case ("pthreads_spin") then
      <<
      >>
end function_HPCOM_initializeLock;

template function_HPCOM_createLock(String lockIdx, String lockPrefix, String iType)
::=
  match iType 
    case ("openmp") then
      <<
      omp_lock_t <%lockPrefix%>_<%lockIdx%>;
      >>
    case ("pthreads") then
      <<
      boost::mutex <%lockPrefix%>_<%lockIdx%>;
      >>
    case ("pthreads_spin") then
      <<
      boost::detail::spinlock <%lockPrefix%>_<%lockIdx%>;
      >>
end function_HPCOM_createLock;

template function_HPCOM_destroyLock(String lockIdx, String lockPrefix, String iType)
::=
  match iType 
    case ("openmp") then
      <<
      omp_destroy_lock(&<%lockPrefix%>_<%lockIdx%>);
      >>
    else
      <<
      >>
end function_HPCOM_destroyLock;

template function_HPCOM_assignLock(String lockIdx, String lockPrefix, String iType)
::=
  match iType 
    case ("openmp") then
      <<
      omp_set_lock(&<%lockPrefix%>_<%lockIdx%>);
      >>
    case ("pthreads") then
      <<
      <%lockPrefix%>_<%lockIdx%>.lock();
      >>
    case ("pthreads_spin") then
      <<
      <%lockPrefix%>_<%lockIdx%>.lock();
      >>
end function_HPCOM_assignLock;

template function_HPCOM_releaseLock(String lockIdx, String lockPrefix, String iType)
::=
  match iType 
    case ("openmp") then
      <<
      omp_unset_lock(&<%lockPrefix%>_<%lockIdx%>);
      >>
    case ("pthreads") then
      <<
      <%lockPrefix%>_<%lockIdx%>.unlock();
      >>
    case ("pthreads_spin") then
      <<
      <%lockPrefix%>_<%lockIdx%>.unlock();
      >>
end function_HPCOM_releaseLock;

// MAINFILE

template simulationMainFileAnalyzation(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__)) then
  <<

  #ifndef BOOST_ALL_DYN_LINK
  #define BOOST_ALL_DYN_LINK
    #endif
  #include <boost/shared_ptr.hpp>
  #include <boost/weak_ptr.hpp>
  #include <boost/numeric/ublas/vector.hpp>
  #include <boost/numeric/ublas/matrix.hpp>
  #include <string>
  #include <vector>
  #include <map>
  using std::string;
  using std::vector;
  using std::map;
 
  #include <SimCoreFactory/Policies/FactoryConfig.h>
  #include <SimController/ISimController.h>
  #if defined(_MSC_VER) || defined(__MINGW32__)
  #include <tchar.h>
  
  #ifdef ANALYZATION_MODE
  #include "DataExchange/SimData.h"
  #include "DataExchange/SimData.h"
  #include "System/IContinuous.h"
  #include "System/IMixedSystem.h"
  #include "System/IWriteOutput.h"
  #include "System/IEvent.h"
  #include "System/ITime.h"
  #include "System/ISystemProperties.h"
  #include "System/ISystemInitialization.h"
  #include "System/IStateSelection.h"
  #include "SimCoreFactory/OMCFactory/StaticOMCFactory.h"
  #include "OMCpp<%dotPath(modelInfo.name)%>Extension.h"
  //namespace ublas = boost::numeric::ublas;
  boost::shared_ptr<ISimData> createSimData()
  {
    boost::shared_ptr<ISimData> sp( new SimData() );
    return sp;
  }
  
  boost::shared_ptr<IMixedSystem> createSystem(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> algLoopSolverFactory, boost::shared_ptr<ISimData> simData)
  {
    boost::shared_ptr<IMixedSystem> sp( new <%lastIdentOfPath(modelInfo.name)%>Extension(globalSettings, algLoopSolverFactory, simData) );
    return sp;
  }
  #else
  namespace ublas = boost::numeric::ublas;
  #endif
  
  int _tmain(int argc, const _TCHAR* argv[])
  #else
  int main(int argc, const char* argv[])
  #endif
  {
      try
      {
      boost::shared_ptr<OMCFactory>  _factory =  boost::shared_ptr<OMCFactory>(new StaticOMCFactory());
            //SimController to start simulation
            
            std::pair<boost::shared_ptr<ISimController>,SimSettings> simulation =  _factory->createSimulation(argc,argv);
           
      
        //create Modelica system
         #ifdef ANALYZATION_MODE
            std::pair<boost::weak_ptr<IMixedSystem>,boost::weak_ptr<ISimData> > system = simulation.first->LoadSystem(&createSimData, &createSystem, "<%lastIdentOfPath(modelInfo.name)%>");
         #else
            std::pair<boost::weak_ptr<IMixedSystem>,boost::weak_ptr<ISimData> > system = simulation.first->LoadSystem("OMCpp<%fileNamePrefix%><%makefileParams.dllext%>","<%lastIdentOfPath(modelInfo.name)%>");
         #endif
            simulation.first->Start(system.first,simulation.second);
       

      }
      catch(std::exception& ex)
      {
          std::string error = ex.what();
          std::cerr << "Simulation stopped: "<<  error ;
          return 1;
      }
  }
>>
end simulationMainFileAnalyzation;

// MAKEFILE

template simulationMakefile(String target,SimCode simCode)
 "Generates the contents of the makefile for the simulation case."
::=
match target
case "msvc" then
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
   let dirExtra = if modelInfo.directory then '/LIBPATH:"<%modelInfo.directory%>"' //else ""
  let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
  let libsPos1 = if not dirExtra then libsStr //else ""
  let libsPos2 = if dirExtra then libsStr // else ""
  let ParModelicaLibs = if acceptParModelicaGrammar() then '-lOMOCLRuntime -lOpenCL' // else ""
  let extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then
    '<%if s.measureTime then "-D_OMC_MEASURE_TIME "%> <%match s.method
       case "inline-euler" then "-D_OMC_INLINE_EULER "
       case "inline-rungekutta" then "-D_OMC_INLINE_RK "
       case "dassljac" then "-D_OMC_JACOBIAN "%>'
    
  <<
  # Makefile generated by OpenModelica

  # Simulations use -O3 by default
  SIM_OR_DYNLOAD_OPT_LEVEL=
  MODELICAUSERCFLAGS=
  CXX=cl
  EXEEXT=.exe
  DLLEXT=.dll
  include <%makefileParams.omhome%>/include/omc/cpp/ModelicaConfig.inc
  # /Od - Optimization disabled
  # /EHa enable C++ EH (w/ SEH exceptions)
  # /fp:except - consider floating-point exceptions when generating code
  # /arch:SSE2 - enable use of instructions available with SSE2 enabled CPUs
  # /I - Include Directories
  # /DNOMINMAX - Define NOMINMAX (does what it says)
  # /TP - Use C++ Compiler
  CFLAGS=  /ZI /Od /EHa /MP /fp:except /I"<%makefileParams.omhome%>/include/omc/cpp/Core/" /I"<%makefileParams.omhome%>/include/omc/cpp/" -I. <%makefileParams.includes%>  -I"$(BOOST_INCLUDE)" /I. /DNOMINMAX /TP /DNO_INTERACTIVE_DEPENDENCY
    
  CPPFLAGS = /DOMC_BUILD
  # /ZI enable Edit and Continue debug info 
  CDFLAGS = /ZI

  # /MD - link with MSVCRT.LIB
  # /link - [linker options and libraries]
  # /LIBPATH: - Directories where libs can be found
  #LDFLAGS=/MDd   /link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/omc/cpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)" OMCppSystem.lib OMCppMath.lib 
  LDSYTEMFLAGS=/MD /Debug  /link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/omc/cpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)" OMCppSystem.lib OMCppModelicaUtilities.lib  OMCppMath.lib   OMCppOMCFactory.lib
  LDMAINFLAGS=/MD /Debug  /link /LIBPATH:"<%makefileParams.omhome%>/lib/omc/cpp/msvc" OMCppOMCFactory.lib  /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)"    
  # /MDd link with MSVCRTD.LIB debug lib
  # lib names should not be appended with a d just switch to lib/omc/cpp


  FILEPREFIX=<%fileNamePrefix%>
  FUNCTIONFILE=OMCpp<%fileNamePrefix%>Functions.cpp
  INITFILE=OMCpp<%fileNamePrefix%>Initialize.cpp
  FACTORYFILE=OMCpp<%fileNamePrefix%>FactoryExport.cpp
  EXTENSIONFILE=OMCpp<%fileNamePrefix%>Extension.cpp
  JACOBIANFILE=OMCpp<%fileNamePrefix%>Jacobian.cpp
  STATESELECTIONFILE=OMCpp<%fileNamePrefix%>StateSelection.cpp
  WRITEOUTPUTFILE=OMCpp<%fileNamePrefix%>WriteOutput.cpp
  SYSTEMFILE=OMCpp<%fileNamePrefix%><% if acceptMetaModelicaGrammar() then ".conv"%>.cpp
  MAINFILE = OMCpp<%fileNamePrefix%>Main.cpp
  MAINOBJ=OMCpp<%fileNamePrefix%>Main$(EXEEXT)
  SYSTEMOBJ=OMCpp<%fileNamePrefix%>$(DLLEXT)
  GENERATEDFILES=$(MAINFILE) $(FUNCTIONFILE)  <%algloopcppfilenames(allEquations,simCode)%> 
 
  $(MODELICA_SYSTEM_LIB)$(DLLEXT): 
  <%\t%>$(CXX)  /Fe$(SYSTEMOBJ) $(SYSTEMFILE) $(FUNCTIONFILE)   <%algloopcppfilenames(listAppend(allEquations,initialEquations),simCode)%> $(INITFILE) $(FACTORYFILE)  $(EXTENSIONFILE) $(WRITEOUTPUTFILE) $(JACOBIANFILE) $(STATESELECTIONFILE) $(CFLAGS)     $(LDSYTEMFLAGS) <%dirExtra%> <%libsPos1%> <%libsPos2%>
   <%\t%>$(CXX) $(CPPFLAGS) /Fe$(MAINOBJ)  $(MAINFILE)   $(CFLAGS) $(LDMAINFLAGS)
  >>
end match
case "gcc" then      
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
let dirExtra = if modelInfo.directory then '-L"<%modelInfo.directory%>"' //else ""
let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
let libsPos1 = if not dirExtra then libsStr //else ""
let libsPos2 = if dirExtra then libsStr // else ""
let _extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then
    '<%if s.measureTime then "-D_OMC_MEASURE_TIME "%> <%match s.method
       case "inline-euler" then "-D_OMC_INLINE_EULER"
       case "inline-rungekutta" then "-D_OMC_INLINE_RK"%>'
let extraCflags = '<%_extraCflags%><% if Flags.isSet(Flags.GEN_DEBUG_SYMBOLS) then " -g"%>'

let analyzationLibs = if Flags.isSet(Flags.HPCOM_ANALYZATION_MODE) then '$(LIBOMCPPOMCFACTORY) $(LIBOMCPPSIMCONTROLLER) $(LIBOMCPPSIMULATIONSETTINGS) $(LIBOMCPPSYSTEM) $(LIBOMCPPDATAEXCHANGE) $(LIBOMCPPNEWTON) $(LIBOMCPPCVODE) $(LIBOMCPPSOLVER) $(LIBOMCPPMATH)  $(SUNDIALS_LIBS) $(LAPACK_LIBS)' else '-lOMCppOMCFactory'
let _extraCflags = if Flags.isSet(Flags.HPCOM_ANALYZATION_MODE) then '<%extraCflags%> -D ANALYZATION_MODE -I"$(SUNDIALS_INCLUDE)"' else '<%extraCflags%>'
<<
# Makefile generated by OpenModelica
include <%makefileParams.omhome%>/include/omc/cpp/ModelicaConfig.inc
OMHOME=<%makefileParams.omhome%>
include <%makefileParams.omhome%>/include/omc/cpp/ModelicaLibraryConfig.inc
# Simulations use -O0 by default
SIM_OR_DYNLOAD_OPT_LEVEL=-O0
CC=<%makefileParams.ccompiler%>
CXX=<%makefileParams.cxxcompiler%>
LINK=<%makefileParams.linker%>
EXEEXT=<%makefileParams.exeext%>
DLLEXT=<%makefileParams.dllext%>
CFLAGS_BASED_ON_INIT_FILE=<%_extraCflags%> -I"<%makefileParams.omhome%>/../SimulationRuntime/cpp" -I"<%makefileParams.omhome%>/../SimulationRuntime/cpp/Core" -I"<%makefileParams.omhome%>/../SimulationRuntime/cpp/Include/SimCoreFactory" -I"<%makefileParams.omhome%>/../SimulationRuntime/cpp/Include/Core"
CFLAGS=$(CFLAGS_BASED_ON_INIT_FILE) -I"<%makefileParams.omhome%>/include/omc/cpp/Core" -I"<%makefileParams.omhome%>/include/omc/cpp/"   -I. <%makefileParams.includes%> -I"$(BOOST_INCLUDE)" <%makefileParams.includes ; separator=" "%> <%makefileParams.cflags%> <%match sopt case SOME(s as SIMULATION_SETTINGS(__)) then s.cflags %>
LDSYTEMFLAGS=-L"<%makefileParams.omhome%>/lib/omc/cpp"    -L"$(BOOST_LIBS)"
CPP_RUNTIME_LIBS=<%analyzationLibs%>
LDMAINFLAGS=-L"<%makefileParams.omhome%>/lib/omc/cpp" <%simulationMainDLLib(simCode)%> -L"<%makefileParams.omhome%>/bin" $(CPP_RUNTIME_LIBS) -L"$(BOOST_LIBS)" $(BOOST_SYSTEM_LIB) $(BOOST_FILESYSTEM_LIB) $(BOOST_PROGRAM_OPTIONS_LIB) $(BOOST_SERIALIZATION_LIB) $(BOOST_THREAD_LIB)
CPPFLAGS = $(CFLAGS) -DOMC_BUILD -DBOOST_SYSTEM_NO_DEPRICATED
SYSTEMFILE=OMCpp<%fileNamePrefix%><% if acceptMetaModelicaGrammar() then ".conv"%>.cpp
FUNCTIONFILE=OMCpp<%fileNamePrefix%>Functions.cpp
INITFILE=OMCpp<%fileNamePrefix%>Initialize.cpp
EXTENSIONFILE=OMCpp<%fileNamePrefix%>Extension.cpp
WRITEOUTPUTFILE=OMCpp<%fileNamePrefix%>WriteOutput.cpp
JACOBIANFILE=OMCpp<%fileNamePrefix%>Jacobian.cpp
STATESELECTIONFILE=OMCpp<%fileNamePrefix%>StateSelection.cpp
FACTORYFILE=OMCpp<%fileNamePrefix%>FactoryExport.cpp
MAINFILE = OMCpp<%fileNamePrefix%>Main.cpp
MAINOBJ=OMCpp<%fileNamePrefix%>Main$(EXEEXT)
SYSTEMOBJ=OMCpp<%fileNamePrefix%>$(DLLEXT)



CPPFILES=$(SYSTEMFILE) $(FUNCTIONFILE) $(INITFILE) $(WRITEOUTPUTFILE) $(EXTENSIONFILE) $(FACTORYFILE) $(JACOBIANFILE) $(STATESELECTIONFILE) <%algloopcppfilenames(listAppend(allEquations,initialEquations),simCode)%>
OFILES=$(CPPFILES:.cpp=.o)

.PHONY: <%lastIdentOfPath(modelInfo.name)%> $(CPPFILES)

<%fileNamePrefix%>: $(MAINFILE) $(OFILES)
<%if Flags.isSet(Flags.HPCOM_ANALYZATION_MODE) then "#"%><%\t%>$(CXX) -shared -I. -o $(SYSTEMOBJ) $(OFILES) $(CPPFLAGS) $(LDSYTEMFLAGS)  <%dirExtra%> <%libsPos1%> <%libsPos2%> -lOMCppSystem -lOMCppModelicaUtilities -lOMCppMath "$(BOOST_THREAD_LIB)"
<%if Flags.isSet(Flags.HPCOM_ANALYZATION_MODE) then "#"%><%\t%>$(CXX) $(CPPFLAGS) -I. -o $(MAINOBJ) $(MAINFILE) $(LDMAINFLAGS)
<%if boolNot(Flags.isSet(Flags.HPCOM_ANALYZATION_MODE)) then "#"%><%\t%>$(CXX) -I. -o $(MAINOBJ) $(MAINFILE) $(OFILES) -D BOOST_UBLAS_SHALLOW_ARRAY_ADAPTOR $(CPPFLAGS) -I. $(LDMAINFLAGS)
<% if boolNot(stringEq(makefileParams.platform, "win32")) then
  <<
  <%\t%>chmod +x <%fileNamePrefix%>.sh
  <%\t%>ln -s <%fileNamePrefix%>.sh <%fileNamePrefix%>
  >>
%>
>>

end simulationMakefile;

end CodegenCppHpcom;