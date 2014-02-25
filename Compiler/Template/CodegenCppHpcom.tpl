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
  case SIMCODE(modelInfo = MODELINFO(__)) then
  let target  = simulationCodeTarget()
   let()= textFile(simulationMainFile(simCode), 'OMCpp<%fileNamePrefix%>Main.cpp')
  let()= textFile(simulationHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>.h')
  let()= textFile(simulationCppFile(simCode), 'OMCpp<%fileNamePrefix%>.cpp')
  let()= textFile(simulationFunctionsHeaderFile(simCode,modelInfo.functions,literals), 'OMCpp<%fileNamePrefix%>Functions.h')
  let()= textFile(simulationFunctionsFile(simCode, modelInfo.functions,literals,externalFunctionIncludes), 'OMCpp<%fileNamePrefix%>Functions.cpp')
  let()= textFile(simulationMakefile(target,simCode), '<%fileNamePrefix%>.makefile')
  let()= textFile(simulationInitHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>Initialize.h')
  let()= textFile(simulationInitCppFile(simCode),'OMCpp<%fileNamePrefix%>Initialize.cpp')
  let()= textFile(simulationJacobianHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>Jacobian.h')
  let()= textFile(simulationJacobianCppFile(simCode),'OMCpp<%fileNamePrefix%>Jacobian.cpp')
  let()= textFile(simulationExtensionHeaderFile(simCode),'OMCpp<%fileNamePrefix%>Extension.h')
  let()= textFile(simulationExtensionCppFile(simCode),'OMCpp<%fileNamePrefix%>Extension.cpp')
  let()= textFile(simulationWriteOutputHeaderFile(simCode),'OMCpp<%fileNamePrefix%>WriteOutput.h')
  let()= textFile(simulationWriteOutputCppFile(simCode),'OMCpp<%fileNamePrefix%>WriteOutput.cpp')
  let()= textFile(simulationFactoryFile(simCode),'OMCpp<%fileNamePrefix%>FactoryExport.cpp')
  let()= textFile(simulationMainRunScrip(simCode), '<%fileNamePrefix%><%simulationMainRunScripSuffix(simCode)%>')
  algloopfiles(listAppend(allEquations,initialEquations),simCode)
  // empty result of the top-level template .., only side effects
end translateModel;

template simulationHeaderFile(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(__) then
  <<
   <%generateHeaderInlcudeString(simCode)%>
   #include <omp.h>
   <%generateClassDeclarationCode(simCode)%>

   >>
end simulationHeaderFile;

template simulationCppFile(SimCode simCode)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let hpcomConstructorExtension = getHpcomConstructorExtension(hpcOmSchedule)
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
  <<
  
  >>
end getAddHpcomFunctionHeaders;

template getAddHpcomVarHeaders(Option<ScheduleSimCode> hpcOmScheduleOpt)
::=
  match hpcOmScheduleOpt 
    case SOME(hpcOmSchedule as THREADSCHEDULESC(__)) then
        let type = getConfigString(HPCOM_CODE)
        let locks = hpcOmSchedule.lockIdc |> idx => function_HPCOM_createLock(idx, "lock", type); separator="\n"
        <<
        <%locks%>
        >>
end getAddHpcomVarHeaders;

// CODE

template getHpcomConstructorExtension(Option<ScheduleSimCode> hpcOmScheduleOpt)
::=
  match hpcOmScheduleOpt 
    case SOME(hpcOmSchedule as THREADSCHEDULESC(__)) then
        let type = getConfigString(HPCOM_CODE)
        let initlocks = hpcOmSchedule.lockIdc |> idx => function_HPCOM_initializeLock(idx, "lock", type); separator="\n"
        let assignLocks = hpcOmSchedule.lockIdc |> idx => function_HPCOM_assignLock(idx, "lock", type); separator="\n"
        <<
        <%initlocks%>
        
        <%assignLocks%>
        >>
end getHpcomConstructorExtension;

template getHpcomDestructorExtension(Option<ScheduleSimCode> hpcOmScheduleOpt)
::=
  match hpcOmScheduleOpt 
    case SOME(hpcOmSchedule as THREADSCHEDULESC(__)) then
        let type = getConfigString(HPCOM_CODE)
        let destroylocks = hpcOmSchedule.lockIdc |> idx => function_HPCOM_destroyLock(idx, "lock", type); separator="\n"
        <<
        <%destroylocks%>
        >>
end getHpcomDestructorExtension;

template update( list<SimEqSystem> allEquationsPlusWhen,list<SimWhenClause> whenClauses, SimCode simCode, Context context)
::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
      let parCode = update2(allEquationsPlusWhen, modelInfo.name, whenClauses, simCode, hpcOmSchedule, context)
      <<
      <%parCode%>
      >>
end update;

template update2(list<SimEqSystem> allEquationsPlusWhen, Absyn.Path name, list<SimWhenClause> whenClauses, SimCode simCode, Option<ScheduleSimCode> hpcOmScheduleOpt, Context context)
::=
  let &varDecls = buffer "" /*BUFD*/
  let all_equations = (allEquationsPlusWhen |> eqs => (eqs |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFC*/,simCode))
    ;separator="\n")

  let reinit = (whenClauses |> when hasindex i0 =>
         genreinits(when, &varDecls,i0,simCode,context)
    ;separator="\n";empty)
    
  match hpcOmScheduleOpt 
    case SOME(hpcOmSchedule as LEVELSCHEDULESC(__)) then
      let odeEqs = hpcOmSchedule.eqsOfLevels |> eqs => functionXXX_system0_HPCOM_Level(allEquationsPlusWhen, eqs, &varDecls, simCode); separator="\n"
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
      let type = getConfigString(HPCOM_CODE)
      
      match type 
        case ("openmp") then
          let taskEqs = functionXXX_system0_HPCOM_Thread(allEquationsPlusWhen,hpcOmSchedule.threadTasks, type, &varDecls, simCode); separator="\n"
          <<
          
          //using type: <%type%>
          bool <%lastIdentOfPath(name)%>::evaluate(const UPDATETYPE command)
          {
            bool state_var_reinitialized = false;

            omp_set_dynamic(0);
            
            <%varDecls%>
            <%taskEqs%>
            <%reinit%>
           
            return state_var_reinitialized;
          }
          >>
end update2;

template functionXXX_system0_HPCOM_Level(list<SimEqSystem> allEquationsPlusWhen, list<Integer> eqsOfLevel, Text &varDecls, SimCode simCode)
::=
  let odeEqs = eqsOfLevel |> eq => equationNamesHPCOMLevel_(eq,allEquationsPlusWhen,contextSimulationNonDiscrete, &varDecls, simCode); separator="\n"
  <<
  if (omp_get_dynamic())
    omp_set_dynamic(0);
  #pragma omp parallel sections num_threads(<%getConfigInt(NUM_PROC)%>)
  {
     <%odeEqs%>
  }
  >>
end functionXXX_system0_HPCOM_Level;

template functionXXX_system0_HPCOM_Thread(list<SimEqSystem> derivativEquations, list<list<Task>> threadTasks, String iType, Text &varDecls, SimCode simCode)
::=
  let odeEqs = threadTasks |> tt => functionXXX_system0_HPCOM_Thread0(derivativEquations,tt,iType,&varDecls,simCode); separator="\n"
  match iType 
    case ("openmp") then
      <<
      if (omp_get_dynamic())
        omp_set_dynamic(0);
      #pragma omp parallel sections num_threads(<%listLength(threadTasks)%>)
      {
         <%odeEqs%>
      }
      >>
    case ("pthreads") then
      <<
      //not implemented
      >>
    case ("pthreads_spin") then
      <<
      //not implemented
      >>

end functionXXX_system0_HPCOM_Thread;

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

template function_HPCOM_initializeLock(String lockIdx, String lockPrefix, String iType)
::=
  match iType 
    case ("openmp") then
      <<
      omp_init_lock(&<%lockPrefix%>_<%lockIdx%>);
      >>
    case ("pthreads") then
      <<
      pthread_mutex_init(&<%lockPrefix%>_<%lockIdx%>, NULL);
      >>
    case ("pthreads_spin") then
      <<
      pthread_spin_init(&<%lockPrefix%>_<%lockIdx%>, 0);
      >>
end function_HPCOM_initializeLock;

template function_HPCOM_createLock(String lockIdx, String prefix, String iType)
::=
  match iType 
    case ("openmp") then
      <<
      omp_lock_t <%prefix%>_<%lockIdx%>;
      >>
    case ("pthreads") then
      <<
      static pthread_mutex_t <%prefix%>_<%lockIdx%>;
      >>
    case ("pthreads_spin") then
      <<
      static pthread_spinlock_t <%prefix%>_<%lockIdx%>;
      >>
end function_HPCOM_createLock;

template function_HPCOM_destroyLock(String lockIdx, String prefix, String iType)
::=
  match iType 
    case ("openmp") then
      <<
      omp_destroy_lock(&<%prefix%>_<%lockIdx%>);
      >>
    case ("pthreads") then
      <<
      pthread_mutex_destroy(&<%prefix%>_<%lockIdx%>);
      >>
    case ("pthreads_spin") then
      <<
      pthread_spin_destroy(&<%prefix%>_<%lockIdx%>);
      >>
end function_HPCOM_destroyLock;

template function_HPCOM_assignLock(String lockIdx, String prefix, String iType)
::=
  match iType 
    case ("openmp") then
      <<
      omp_set_lock(&<%prefix%>_<%lockIdx%>);
      >>
    case ("pthreads") then
      <<
      pthread_mutex_lock(&<%prefix%>_<%lockIdx%>);
      >>
    case ("pthreads_spin") then
      <<
      pthread_spin_lock(&<%prefix%>_<%lockIdx%>);
      >>
end function_HPCOM_assignLock;

template function_HPCOM_releaseLock(String lockIdx, String prefix, String iType)
::=
  match iType 
    case ("openmp") then
      <<
      omp_unset_lock(&<%prefix%>_<%lockIdx%>);
      >>
    case ("pthreads") then
      <<
      pthread_mutex_unlock(&<%prefix%>_<%lockIdx%>);
      >>
    case ("pthreads_spin") then
      <<
      pthread_spin_unlock(&<%prefix%>_<%lockIdx%>);
      >>
end function_HPCOM_releaseLock;

end CodegenCppHpcom;