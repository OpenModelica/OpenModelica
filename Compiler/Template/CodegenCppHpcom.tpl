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



template translateModel(SimCode simCode, Boolean useFlatArrayNotation) ::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__), makefileParams= MAKEFILE_PARAMS(__)) then
  let target  = simulationCodeTarget()
  let()= textFile((if Flags.isSet(Flags.HPCOM_ANALYZATION_MODE) then simulationMainFileAnalyzation(simCode) else simulationMainFile(simCode)), 'OMCpp<%fileNamePrefix%>Main.cpp')
  let()= textFile(simulationHeaderFile(simCode, generateAdditionalIncludes(simCode, Util.isSome(hpcOmMemory)), generateAdditionalProtectedMemberDeclaration(simCode, Util.isSome(hpcOmMemory)), false, Util.isSome(hpcOmMemory)), 'OMCpp<%fileNamePrefix%>.h')
  let()= textFile(simulationCppFile(simCode,Util.isSome(hpcOmMemory)), 'OMCpp<%fileNamePrefix%>.cpp')
  let()= textFile(simulationFunctionsHeaderFile(simCode,modelInfo.functions,literals,false), 'OMCpp<%fileNamePrefix%>Functions.h')
  let()= textFile(simulationFunctionsFile(simCode, modelInfo.functions,literals,externalFunctionIncludes,false), 'OMCpp<%fileNamePrefix%>Functions.cpp')
  let()= textFile(simulationTypesHeaderFile(simCode,modelInfo.functions,literals,useFlatArrayNotation), 'OMCpp<%fileNamePrefix%>Types.h')
  let()= textFile(simulationMakefile(target,simCode), '<%fileNamePrefix%>.makefile')
  let()= textFile(simulationInitHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>Initialize.h')
  let()= textFile(simulationInitCppFile(simCode,Util.isSome(hpcOmMemory)),'OMCpp<%fileNamePrefix%>Initialize.cpp')
  let()= textFile(simulationJacobianHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>Jacobian.h')
  let()= textFile(simulationJacobianCppFile(simCode,Util.isSome(hpcOmMemory)),'OMCpp<%fileNamePrefix%>Jacobian.cpp')
  let()= textFile(simulationStateSelectionCppFile(simCode,Util.isSome(hpcOmMemory)), 'OMCpp<%fileNamePrefix%>StateSelection.cpp')
  let()= textFile(simulationStateSelectionHeaderFile(simCode),'OMCpp<%fileNamePrefix%>StateSelection.h')
  let()= textFile(simulationExtensionHeaderFile(simCode),'OMCpp<%fileNamePrefix%>Extension.h')
  let()= textFile(simulationExtensionCppFile(simCode),'OMCpp<%fileNamePrefix%>Extension.cpp')
  let()= textFile(simulationWriteOutputHeaderFile(simCode),'OMCpp<%fileNamePrefix%>WriteOutput.h')
  let()= textFile(simulationWriteOutputCppFile(simCode,Util.isSome(hpcOmMemory)),'OMCpp<%fileNamePrefix%>WriteOutput.cpp')
  let()= textFile(simulationFactoryFile(simCode),'OMCpp<%fileNamePrefix%>FactoryExport.cpp')
  let()= textFile(simulationMainRunScript(simCode), '<%fileNamePrefix%><%simulationMainRunScriptSuffix(simCode)%>')
  let jac =  (jacobianMatrixes |> (mat, _,_, _, _, _,_) =>
          (mat |> (eqs,_,_) =>  algloopfiles(eqs,simCode,contextAlgloopJacobian,Util.isSome(hpcOmMemory)) ;separator="")
         ;separator="")
  let alg = algloopfiles(listAppend(allEquations,initialEquations),simCode,contextAlgloop,Util.isSome(hpcOmMemory))
  let()= textFile(algloopMainfile(listAppend(allEquations,initialEquations),simCode,contextAlgloop), 'OMCpp<%fileNamePrefix%>AlgLoopMain.cpp')
  let()= textFile(calcHelperMainfile(simCode), 'OMCpp<%fileNamePrefix%>CalcHelperMain.cpp')
 ""
  // empty result of the top-level template .., only side effects
end translateModel;

template Update(SimCode simCode, Boolean useFlatArrayNotation)
::=
match simCode
case SIMCODE(__) then
  <<
  <%update(allEquations,whenClauses,simCode,contextOther,useFlatArrayNotation)%>
  >>
end Update;

// HEADER
template generateAdditionalIncludes(SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(__) then
  <<
     #ifdef ANALYZATION_MODE
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
      #include <System/IMixedSystem.h>

      #include <boost/numeric/ublas/matrix_sparse.hpp>
      typedef uBlas::compressed_matrix<double, uBlas::column_major, 0, uBlas::unbounded_array<int>, uBlas::unbounded_array<double> > SparseMatrix;
     #endif
     <%generateHpcomSpecificIncludes(simCode)%>
   >>
end generateAdditionalIncludes;

template generateAdditionalProtectedMemberDeclaration(SimCode simCode, Boolean useFlatArrayNotation)
 "Generates class declarations."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
    let addHpcomFunctionHeaders = getAddHpcomFunctionHeaders(hpcOmSchedule)
    let addHpcomVarHeaders = getAddHpcomVarHeaders(hpcOmSchedule)
    let addHpcomArrayHeaders = getAddHpcomVarArrays(hpcOmMemory)
    let type = getConfigString(HPCOM_CODE)

    <<
    // HPCOM
    #ifdef __GNUC__
        #define VARARRAY_ALIGN_PRE
        #define VARARRAY_ALIGN_POST __attribute__((aligned(0x40)))
    #else
        #define VARARRAY_ALIGN_PRE __declspec(align(64))
        #define VARARRAY_ALIGN_POST
    #endif

    static long unsigned int getThreadNumber()
    {
      <% match type
            case ("openmp") then
                <<
                return (long unsigned int)omp_get_thread_num();
                >>
            else
                <<
                boost::hash<std::string> string_hash;
                return (long unsigned int)string_hash(boost::lexical_cast<std::string>(boost::this_thread::get_id()));
                >>
      %>
    }

    <%addHpcomFunctionHeaders%>
    <%addHpcomArrayHeaders%>
    <%addHpcomVarHeaders%>
    <%MemberVariable(modelInfo, hpcOmMemory,useFlatArrayNotation,false)%>

    <% if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
    <<
    /* std::vector<MeasureTimeData> measureTimeArrayHpcom;
    MeasureTimeValues *measuredStartValuesODE, *measuredEndValuesODE; */
    >>%>
    >>
end generateAdditionalProtectedMemberDeclaration;

template getAddHpcomStructHeaders(Option<Schedule> hpcOmScheduleOpt)
::=
  let type = getConfigString(HPCOM_CODE)
  match hpcOmScheduleOpt
    case SOME(hpcOmSchedule as TASKDEPSCHEDULE(__)) then
        match type
            case ("openmp") then
                <<
                >>
            case ("tbb") then
                <<
                struct VoidBody {
                    boost::function<void(void)> void_function;
                    VoidBody(boost::function<void(void)> void_function) : void_function(void_function) { }
                    void operator()( tbb::flow::continue_msg ) const
                    {
                        void_function();
                    }
                };
                >>
            else ""
    else ""
end getAddHpcomStructHeaders;

template getAddHpcomFunctionHeaders(Option<Schedule> hpcOmScheduleOpt)
::=
  let type = getConfigString(HPCOM_CODE)
  match hpcOmScheduleOpt
    case SOME(hpcOmSchedule as LEVELSCHEDULE(useFixedAssignments=true)) then
        match type
            case ("pthreads")
            case ("pthreads_spin") then
                let threadFuncs = List.intRange(getConfigInt(NUM_PROC)) |> thIdx hasindex i0 fromindex 0 => 'void evaluateThreadFunc<%i0%>();'; separator="\n"
                <<
                <%threadFuncs%>
                >>
            else ""
    case SOME(hpcOmSchedule as THREADSCHEDULE(__)) then
        let locks = hpcOmSchedule.outgoingDepTasks |> task => createLockByDepTask(task, "lock", type); separator="\n"

        match type
            case ("openmp") then
                <<
                >>
            else
                let headers = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => generateThreadFunctionHeaderDecl(i0); separator="\n"
                <<
                <%headers%>
                >>
    case SOME(hpcOmSchedule as TASKDEPSCHEDULE(__)) then
        match type
            case ("openmp") then
                <<
                >>
            case ("tbb") then
                let voidfuncs = hpcOmSchedule.tasks |> task => getAddHpcomFuncHeadersTaskDep(task); separator="\n"
                <<
                <%getAddHpcomStructHeaders(hpcOmScheduleOpt)%>

                <%voidfuncs%>
                >>
            else ""
    else ""
end getAddHpcomFunctionHeaders;

template getAddHpcomVarArrays(Option<MemoryMap> optHpcomMemoryMap)
::=
    match optHpcomMemoryMap
        case(SOME(hpcomMemoryMap)) then
            match hpcomMemoryMap
                case(MEMORYMAP_ARRAY(__)) then
                    <<
                    <%if intGt(floatArraySize,0) then 'VARARRAY_ALIGN_PRE double varArray1[<%floatArraySize%>] VARARRAY_ALIGN_POST ; //float variables'%>
                    >>
                else ''
            end match
        else ''
    end match
end getAddHpcomVarArrays;

template getAddHpcomVarHeaders(Option<Schedule> hpcOmScheduleOpt)
::=
  let type = getConfigString(HPCOM_CODE)
  match hpcOmScheduleOpt
    case SOME(hpcOmSchedule as LEVELSCHEDULE(useFixedAssignments=true)) then
        match type
            case ("pthreads")
            case ("pthreads_spin") then
                <<
                <%List.intRange(getConfigInt(NUM_PROC)) |> thIdx hasindex i0 fromindex 0 => generateThreadHeaderDecl(i0, type)%>
                <%createBarrierByName("evaluateBarrier","", intAdd(1, getConfigInt(NUM_PROC)), type)%>
                <%createBarrierByName("levelBarrier","", getConfigInt(NUM_PROC), type)%>
                <%createLockByLockName("measureTimeArrayLock", "", type)%>
                bool _simulationFinished;
                UPDATETYPE _command;
                >>
            else ""
    case SOME(hpcOmSchedule as THREADSCHEDULE(__)) then
        let locks = hpcOmSchedule.outgoingDepTasks |> task => createLockByDepTask(task, "lock", type); separator="\n"
        let threadDecl = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => generateThreadHeaderDecl(i0, type); separator="\n"
        match type
            case ("openmp") then
                <<
                <%locks%>
                <%threadDecl%>
                >>
            case "mpi" then
                <<
                //BLABLUB
                >>
            else
                let thLocks = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => createLockByLockName(i0, "th_lock", type); separator="\n"
                let thLocks1 = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => createLockByLockName(i0, "th_lock1", type); separator="\n"
                <<
                bool terminateThreads;
                UPDATETYPE command;
                <%locks%>
                <%thLocks%>
                <%thLocks1%>
                <%threadDecl%>
                >>
     case SOME(hpcOmSchedule as TASKDEPSCHEDULE(__)) then
        match type
            case ("openmp") then
                <<
                >>
            case ("tbb") then
                <<
                    tbb::flow::graph tbb_graph;
                >>
            else ""
     else ""
end getAddHpcomVarHeaders;

template getAddHpcomFuncHeadersTaskDep(tuple<Task,list<Integer>> taskIn)
::=
  match taskIn
    case ((task as CALCTASK(__),parents)) then
        <<
        void task_func_<%task.index%>();
        >>
end getAddHpcomFuncHeadersTaskDep;

template generateHpcomSpecificIncludes(SimCode simCode)
::=
    let type = getConfigString(HPCOM_CODE)

    match type
        case ("openmp") then
        <<
        #include <omp.h>
        >>
        case ("pthreads")
        case ("pthreads_spin") then
        <<
        #include <boost/smart_ptr/detail/spinlock.hpp>
        #include <boost/thread/mutex.hpp>
        #include <boost/thread.hpp>
        #include <boost/thread/barrier.hpp>
        >>
        case ("tbb") then
        <<
        #include <tbb/tbb.h>
        #include <tbb/flow_graph.h>
        #include <boost/function.hpp>
        #include <boost/bind.hpp>
        >>
        case ("mpi") then // MF: mpi.h
        <<
        #include <mpi.h>
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


template simulationCppFile(SimCode simCode, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let hpcomConstructorExtension = getHpcomConstructorExtension(hpcOmSchedule, lastIdentOfPath(modelInfo.name))
  let hpcomMemberVariableDefinition = getHpcomMemberVariableDefinition(hpcOmSchedule)
  let hpcomDestructorExtension = getHpcomDestructorExtension(hpcOmSchedule)
  let type = getConfigString(HPCOM_CODE)
  let className = lastIdentOfPath(modelInfo.name)
  <<
   #include <Core/Modelica.h>
   #include <Core/ModelicaDefine.h>
   #include "OMCpp<%fileNamePrefix%>.h"
   #include "OMCpp<%fileNamePrefix%>Functions.h"

    /* Constructor */
    <%className%>::<%className%>(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData)
        :SystemDefaultImplementation(globalSettings)
        ,_algLoopSolverFactory(nonlinsolverfactory)
        ,_simData(simData)
        <%hpcomMemberVariableDefinition%>
        <%MemberVariable(modelInfo, hpcOmMemory,useFlatArrayNotation,true)%>
        <%simulationInitFile(simCode, useFlatArrayNotation)%>
    {
    //I don't know why this line is necessary if we link statically, but without it a segfault occurs
    _global_settings = globalSettings;
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
        <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
            let numOfEqs = SimCodeUtil.getMaxSimEqSystemIndex(simCode)
            <<
            measureTimeProfileBlocksArray = std::vector<MeasureTimeData>(<%numOfEqs%>);
            MeasureTime::addResultContentBlock("<%dotPath(modelInfo.name)%>","profileBlocks",&measureTimeProfileBlocksArray);
            measureTimeFunctionsArray = std::vector<MeasureTimeData>(3); //1 evaluateODE ; 2 evaluateAll; 3 writeOutput
            MeasureTime::addResultContentBlock("<%dotPath(modelInfo.name)%>","functions",&measureTimeFunctionsArray);
            measuredProfileBlockStartValues = MeasureTime::getZeroValues();
            measuredProfileBlockEndValues = MeasureTime::getZeroValues();
            measuredFunctionStartValues = MeasureTime::getZeroValues();
            measuredFunctionEndValues = MeasureTime::getZeroValues();

            for(int i = 0; i < <%numOfEqs%>; i++)
            {
                ostringstream ss;
                ss << i;
                measureTimeProfileBlocksArray[i] = MeasureTimeData(ss.str());
            }

            measureTimeFunctionsArray[0] = MeasureTimeData("evaluateODE");
            measureTimeFunctionsArray[1] = MeasureTimeData("evaluateAll");
            measureTimeFunctionsArray[2] = MeasureTimeData("writeOutput");
            >>
        %>

    //DAE's are not supported yet, Index reduction is enabled
    _dimAE = 0; // algebraic equations
    //Initialize the state vector
    SystemDefaultImplementation::initialize();
    //Instantiate auxiliary object for event handling functionality
    _event_handling.getCondition =  boost::bind(&<%className%>::getCondition, this, _1);
     //Todo: arrayReindex(modelInfo,useFlatArrayNotation)
    //Initialize array elements
    <%initializeArrayElements(simCode,useFlatArrayNotation)%>

    _functions = new Functions(_simTime,__z,__zDot,_initial,_terminate);

    <%hpcomConstructorExtension%>

    }
    <%lastIdentOfPath(modelInfo.name)%>::~<%lastIdentOfPath(modelInfo.name)%>()
    {
        if(_functions != NULL)
            delete _functions;
        <%hpcomDestructorExtension%>
    }

   <%Update(simCode,useFlatArrayNotation)%>

    <%DefaultImplementationCode(simCode,useFlatArrayNotation)%>
    <%checkForDiscreteEvents(discreteModelVars,simCode,useFlatArrayNotation)%>
    <%giveZeroFunc1(zeroCrossings,simCode,useFlatArrayNotation)%>

    <%setConditions(simCode)%>
    <%geConditions(simCode)%>
    <%isConsistent(simCode)%>

    <%generateStepCompleted(listAppend(allEquations,initialEquations),simCode,useFlatArrayNotation)%>

    <%generateStepStarted(listAppend(allEquations,initialEquations),simCode,useFlatArrayNotation)%>

    <%generatehandleTimeEvent(timeEvents, simCode)%>
    <%generateDimTimeEvent(listAppend(allEquations,initialEquations),simCode)%>
    <%generateTimeEvent(timeEvents, simCode, true)%>

    <%isODE(simCode)%>
    <%DimZeroFunc(simCode)%>

   <%getCondition(zeroCrossings,whenClauses,simCode,useFlatArrayNotation)%>
   <%handleSystemEvents(zeroCrossings,whenClauses,simCode)%>
   <%saveall(modelInfo,simCode,useFlatArrayNotation)%>
   <%initPrevars(modelInfo,simCode,useFlatArrayNotation)%>
   <%savediscreteVars(modelInfo,simCode,useFlatArrayNotation)%>
   <%LabeledDAE(modelInfo.labels,simCode,useFlatArrayNotation)%>
    <%giveVariables(modelInfo,useFlatArrayNotation,simCode)%>
   >>
end simulationCppFile;

template getHpcomMemberVariableDefinition(Option<Schedule> hpcOmScheduleOpt)
::=
  let type = getConfigString(HPCOM_CODE)
  match hpcOmScheduleOpt
    case SOME(hpcOmSchedule as LEVELSCHEDULE(useFixedAssignments=true)) then
        match type
            case ("pthreads")
            case ("pthreads_spin") then
                <<
                ,_command(IContinuous::UNDEF_UPDATE)
                ,_simulationFinished(false)
                ,<%initializeBarrierByName("evaluateBarrier","",intAdd(1,getConfigInt(NUM_PROC)),type)%>
                ,<%initializeBarrierByName("levelBarrier","",getConfigInt(NUM_PROC),type)%>
                >>
            else ""
        end match
    else ""
  end match
end getHpcomMemberVariableDefinition;

template getHpcomConstructorExtension(Option<Schedule> hpcOmScheduleOpt, String modelNamePrefixStr)
::=
  let type = getConfigString(HPCOM_CODE)
  match hpcOmScheduleOpt
    case SOME(hpcOmSchedule as LEVELSCHEDULE(useFixedAssignments=true)) then
        match type
            case ("pthreads")
            case ("pthreads_spin") then
                let threadFuncs = List.intRange(getConfigInt(NUM_PROC)) |> tt hasindex i0 fromindex 0 => generateThread(i0, type, modelNamePrefixStr,"evaluateThreadFunc"); separator="\n"
                <<

                <%threadFuncs%>
                >>
            else ""
    case SOME(hpcOmSchedule as THREADSCHEDULE(__)) then
        let initlocks = hpcOmSchedule.outgoingDepTasks |> task => initializeLockByDepTask(task, "lock", type); separator="\n"
        let assignLocks = hpcOmSchedule.outgoingDepTasks |> task => assignLockByDepTask(task, "lock", type); separator="\n"
        let threadFuncs = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => generateThread(i0, type, modelNamePrefixStr,"evaluateThreadFunc"); separator="\n"
        match type
            case ("openmp") then
                <<
                <%threadFuncs%>
                <%initlocks%>
                >>
            case ("mpi") then
                <<
                //MFlehmig: Initialize MPI related stuff
                >>
            else
                let threadLocksInit = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => initializeLockByLockName(i0, "th_lock", type); separator="\n"
                let threadLocksInit1 = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => initializeLockByLockName(i0, "th_lock1", type); separator="\n"
                let threadAssignLocks = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => assignLockByLockName(i0, "th_lock", type); separator="\n"
                let threadAssignLocks1 = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => assignLockByLockName(i0, "th_lock1", type); separator="\n"
                <<
                    terminateThreads = false;
                    command = IContinuous::UNDEF_UPDATE;

                    <%initlocks%>
                    <%threadLocksInit%>
                    <%threadLocksInit1%>

                    <%assignLocks%>
                    <%threadAssignLocks%>
                    <%threadAssignLocks1%>

                    <%threadFuncs%>
                >>
     else ""
end getHpcomConstructorExtension;


template getHpcomDestructorExtension(Option<Schedule> hpcOmScheduleOpt)
::=
  let type = getConfigString(HPCOM_CODE)
  match hpcOmScheduleOpt
    case SOME(hpcOmSchedule as LEVELSCHEDULE(useFixedAssignments=true)) then
        match type
            case ("pthreads")
            case ("pthreads_spin") then
                <<
                _simulationFinished = true;
                _evaluateBarrier.wait();
                _evaluateBarrier.wait();
                >>
            else ""
    case SOME(hpcOmSchedule as THREADSCHEDULE(__)) then
        let destroylocks = hpcOmSchedule.outgoingDepTasks |> task => destroyLockByDepTask(task, "lock", type); separator="\n"
        let destroyThreads = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => function_HPCOM_destroyThread(i0, type); separator="\n"
        match type
            case ("openmp") then
                <<
                <%destroylocks%>
                >>
      case "mpi" then
        <<
        //MF: Destruct MPI related stuff - nothing at the moment.
        >>
            else
                let joinThreads = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => function_HPCOM_joinThread(i0, type); separator="\n"
                let threadReleaseLocks = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => releaseLockByLockName(i0, "th_lock", type); separator="\n"
                <<
                terminateThreads = true;
                <%threadReleaseLocks%>
                <%joinThreads%>
                <%destroylocks%>
                <%destroyThreads%>
                >>
    else ""
end getHpcomDestructorExtension;


template update( list<SimEqSystem> allEquationsPlusWhen,list<SimWhenClause> whenClauses, SimCode simCode, Context context, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/

  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
      let parCode = update2(allEquationsPlusWhen, odeEquations, modelInfo.name, whenClauses, simCode, hpcOmSchedule, context, lastIdentOfPath(modelInfo.name), useFlatArrayNotation)
      <<
       <%equationFunctions(allEquations,whenClauses,simCode,contextSimulationDiscrete,useFlatArrayNotation,false)%>

       <%createEvaluateAll(allEquations,whenClauses,simCode,contextOther,useFlatArrayNotation)%>

       <%createEvaluateZeroFuncs(equationsForZeroCrossings,simCode,contextOther) %>

       <%createEvaluateConditions(simCode, allEquationsPlusWhen, whenClauses, modelInfo.name, context, useFlatArrayNotation)%>
      <%parCode%>
      >>
end update;


template createEvaluateConditions(SimCode simCode, list<SimEqSystem> allEquationsPlusWhen, list<SimWhenClause> whenClauses, Absyn.Path name, Context context, Boolean useFlatArrayNotation)
::=
  match simCode
    case SIMCODE(__) then
    let &varDecls = buffer "" /*BUFD*/
    let eqs = equationsForConditions |> eq => equation_function_call(eq,contextSimulationNonDiscrete,&varDecls, simCode,"evaluate"); separator="\n"
    let reinit = (whenClauses |> when hasindex i0 => genreinits(when, &varDecls,i0,simCode,context,useFlatArrayNotation) ;separator="\n";empty)
    <<
    bool <%lastIdentOfPath(name)%>::evaluateConditions(const UPDATETYPE command)
    {
        bool state_var_reinitialized = false;
        //length: <%listLength(equationsForConditions)%>
        <%eqs%>
        <%reinit%>
        return state_var_reinitialized;
    }
    >>
end createEvaluateConditions;

template update2(list<SimEqSystem> allEquationsPlusWhen, list<list<SimEqSystem>> odeEquations, Absyn.Path name, list<SimWhenClause> whenClauses, SimCode simCode, Option<Schedule> hpcOmScheduleOpt, Context context, String modelNamePrefixStr, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  /* let all_equations = (allEquationsPlusWhen |> eqs => (eqs |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFC*/,simCode))
    ;separator="\n") */

  /* let reinit = (whenClauses |> when hasindex i0 => genreinits(when, &varDecls,i0,simCode,context)
    ;separator="\n";empty) */
  let type = getConfigString(HPCOM_CODE)

  match hpcOmScheduleOpt
    case SOME(hpcOmSchedule as EMPTYSCHEDULE(__)) then
        <<
        <%CodegenCpp.createEvaluate(odeEquations, whenClauses, simCode, context)%>
        >>
    case SOME(hpcOmSchedule as LEVELSCHEDULE(useFixedAssignments=false, tasksOfLevels=tasksOfLevels)) then
      let odeEqs = tasksOfLevels |> tasks => function_HPCOM_Level(allEquationsPlusWhen, tasks, type, &varDecls, simCode, useFlatArrayNotation); separator="\n"

      match type
        case ("openmp") then
          <<
          void <%lastIdentOfPath(name)%>::evaluateODE(const UPDATETYPE command)
          {
             <%generateMeasureTimeStartCode("measuredFunctionStartValues", "evaluateODE")%>
             <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then '//MeasureTimeValues **threadValues = new MeasureTimeValues*[<%getConfigInt(NUM_PROC)%>];'%>
             #pragma omp parallel num_threads(<%getConfigInt(NUM_PROC)%>)
             {
                <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
                <<
                /*MeasureTimeValues *valuesStart = MeasureTime::getZeroValues();
                MeasureTimeValues *valuesEnd = MeasureTime::getZeroValues();
                MeasureTime::getInstance()->initializeThread(getThreadNumber);
                <%generateMeasureTimeStartCode('valuesStart', "evaluateODEInner")%>*/
                >>%>

                <%odeEqs%>

                <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
                <<
                /*MeasureTime::getTimeValuesEnd(valuesEnd);
                valuesEnd->sub(valuesStart);
                valuesEnd->sub(MeasureTime::getOverhead());
                #pragma omp critical
                {
                    measureTimeArrayHpcom[0].sumMeasuredValues->add(valuesEnd);
                }
                delete valuesStart;
                delete valuesEnd;*/
                >>%>
             }
             <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
             <<
             /*delete threadValues;
             ++(measureTimeArrayHpcom[0].numCalcs);*/
             >>%>

             <%generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "measureTimeFunctionsArray[0]")%>
          }
          >>
        case ("mpi") then
          <<
          // MFlehmig: MPI with level scheduling
          void <%lastIdentOfPath(name)%>::evaluateODE(const UPDATETYPE command)
          {
            //ToDo
          }
          >>
        else
          <<
          void <%lastIdentOfPath(name)%>::evaluateODE(const UPDATETYPE command)
          {
            throw std::runtime_error("Type <%type%> is unsupported for level scheduling.");
          }
          >>
     end match
   case SOME(hpcOmSchedule as LEVELSCHEDULE(useFixedAssignments=true, tasksOfLevels=tasksOfLevels)) then
      match type
        case ("pthreads")
        case ("pthreads_spin") then
          let eqsFuncs = arrayList(HpcOmScheduler.convertFixedLevelScheduleToTaskLists(hpcOmSchedule, getConfigInt(NUM_PROC))) |> tasks hasindex i0 fromindex 0 => generateLevelFixedCodeForThread(allEquationsPlusWhen, tasks, i0, type, &varDecls, name, simCode, useFlatArrayNotation); separator="\n"
          let threadLocks = List.intRange(getConfigInt(NUM_PROC)) |> tt => createLockByLockName('threadLock<%tt%>', "", type); separator="\n"
          <<
          <%eqsFuncs%>

          void <%lastIdentOfPath(name)%>::evaluateODE(const UPDATETYPE command)
          {
            /*<%generateMeasureTimeStartCode("measuredFunctionStartValues", "evaluateODE")%>*/
            this->_command = command;
            _evaluateBarrier.wait(); //start calculation
            _evaluateBarrier.wait(); //calculation finished
            /*<%generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "measureTimeFunctionsArray[0]")%>*/
          }
          >>
        else ""
      end match
   case SOME(hpcOmSchedule as THREADSCHEDULE(__)) then
      match type
        case ("openmp") then
          let taskEqs = function_HPCOM_Thread(allEquationsPlusWhen,hpcOmSchedule.threadTasks, type, &varDecls, simCode, useFlatArrayNotation); separator="\n"
          <<
          //using type: <%type%>
          void <%lastIdentOfPath(name)%>::evaluateODE(const UPDATETYPE command)
          {
            <%&varDecls%>
            <%taskEqs%>
          }
          >>
        case ("mpi") then
          <<
          //using type: <%type%> and threadscheduling
          void <%lastIdentOfPath(name)%>::evaluateODE(const UPDATETYPE command)
          {
            // MFlehmig: Todo

          }
          >>
        else
          let threadFuncs = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => generateThreadFunc(allEquationsPlusWhen, hpcOmSchedule.threadTasks, type, i0, modelNamePrefixStr, &varDecls, simCode, useFlatArrayNotation); separator="\n"
          let threadAssignLocks1 = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => assignLockByLockName(i0, "th_lock1", type); separator="\n"
          let threadReleaseLocks = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => releaseLockByLockName(i0, "th_lock", type); separator="\n"
          <<
          <%threadFuncs%>

          //using type: <%type%>
          void <%lastIdentOfPath(name)%>::evaluateODE(const UPDATETYPE command)
          {

            this->command = command;
            <%threadReleaseLocks%>
            <%threadAssignLocks1%>


          }
          >>
      end match
    case SOME(hpcOmSchedule as TASKDEPSCHEDULE(__)) then
        match type
            case ("openmp") then
                let taskEqs = function_HPCOM_TaskDep(hpcOmSchedule.tasks, allEquationsPlusWhen, type, &varDecls, simCode, useFlatArrayNotation); separator="\n"
                <<
                //using type: <%type%>
                void <%lastIdentOfPath(name)%>::evaluateODE(const UPDATETYPE command)
                {

                  omp_set_dynamic(1);

                  <%&varDecls%>
                  <%taskEqs%>


                }
                >>
            case ("tbb") then
                let taskNodes = function_HPCOM_TaskDep_tbb(hpcOmSchedule.tasks, allEquationsPlusWhen, type, name, &varDecls, simCode, useFlatArrayNotation); separator="\n"
                let taskFuncs = function_HPCOM_TaskDep_voidfunc(hpcOmSchedule.tasks, allEquationsPlusWhen,type, name, &varDecls, simCode, useFlatArrayNotation); separator="\n"
                <<
                    //using type: <%type%>

                    //void functions for functionhandling in tbb_nodes
                    <%taskFuncs%>

                    void <%lastIdentOfPath(name)%>::evaluateODE(const UPDATETYPE command)
                    {
                      using namespace tbb::flow;


                      // Declaration of nodes and edges
                      <%taskNodes%>
                    }
                >>
            else ""
       end match
    else ""
end update2;

template function_HPCOM_Level(list<SimEqSystem> allEquationsPlusWhen, TaskList tasksOfLevel, String iType, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
::=
  match(tasksOfLevel)
    case(PARALLELTASKLIST(__)) then
      let odeEqs = tasks |> task => function_HPCOM_Level0(allEquationsPlusWhen,task,iType, &varDecls, simCode, useFlatArrayNotation); separator="\n"
      <<
      #pragma omp sections
      {
        <%odeEqs%>
      }
      >>
    case(SERIALTASKLIST(__)) then
      let odeEqs = tasks |> task => function_HPCOM_Level0(allEquationsPlusWhen,task,iType, &varDecls, simCode, useFlatArrayNotation); separator="\n"
      <<
      #pragma omp master
      {
        <%odeEqs%>
      }
      #pragma omp barrier
      >>
    else
      <<

      >>
end function_HPCOM_Level;

template function_HPCOM_Level0(list<SimEqSystem> allEquationsPlusWhen, Task iTask, String iType, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
::=
  <<
  #pragma omp section
  {
      <%function_HPCOM_Task(allEquationsPlusWhen,iTask,iType, &varDecls, simCode, useFlatArrayNotation)%>
  }
  >>
end function_HPCOM_Level0;

template generateLevelFixedCodeForThread(list<SimEqSystem> allEquationsPlusWhen, list<list<HpcOmSimCode.Task>> tasksOfLevels, Integer iThreadIdx, String iType, Text &varDecls, Absyn.Path name, SimCode simCode, Boolean useFlatArrayNotation)
::=
  let odeEqs = tasksOfLevels |> tasks => generateLevelFixedCodeForThreadLevel(allEquationsPlusWhen, tasks, iThreadIdx, iType, &varDecls, simCode, useFlatArrayNotation); separator="\n"
  <<
  void <%lastIdentOfPath(name)%>::evaluateThreadFunc<%iThreadIdx%>()
  {
    <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
    <<
    MeasureTimeValues *valuesStart = MeasureTime::getZeroValues();
    MeasureTimeValues *valuesEnd = MeasureTime::getZeroValues();
    MeasureTime::getInstance()->initializeThread(getThreadNumber);
    //<%generateMeasureTimeStartCode('valuesStart', "evaluateODEThread")%>
    >>%>

    while(!_simulationFinished)
    {
        _evaluateBarrier.wait();
        if(_simulationFinished)
        {
            _evaluateBarrier.wait();
            break;
        }
        <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then '<%generateMeasureTimeStartCode("valuesStart", "evaluateODEThread")%>'%>
        <%odeEqs%>

        <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
        <<
        //MeasureTime::getTimeValuesEnd(valuesEnd);
        //valuesEnd->sub(valuesStart);
        //valuesEnd->sub(MeasureTime::getOverhead());

        //_measureTimeArrayLock.lock();
        //measureTimeArrayHpcom[0].sumMeasuredValues->add(valuesEnd);
        <%if intEq(iThreadIdx,0) then '' else 'measureTimeArrayHpcom[0].numCalcs--;'%>
        //_measureTimeArrayLock.unlock();
        <%generateMeasureTimeEndCode("valuesStart", "valuesEnd", "measureTimeFunctionsArray[0]")%>
        >>%>

        _evaluateBarrier.wait();
    }
    <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
    <<
    delete valuesStart;
    delete valuesEnd;
    >>%>
  }
  >>
end generateLevelFixedCodeForThread;

template generateLevelFixedCodeForThreadLevel(list<SimEqSystem> allEquationsPlusWhen, list<HpcOmSimCode.Task> tasksOfLevel, Integer iThreadIdx, String iType, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
::=
  let tasks = tasksOfLevel |> t => function_HPCOM_Task(allEquationsPlusWhen, t, iType, varDecls, simCode, useFlatArrayNotation); separator="\n"
  <<
  //Start of Level
  <%if(stringEq(tasks,"")) then '' else ''%>
  <%tasks%>
  _levelBarrier.wait();
  //End of Level
  >>
end generateLevelFixedCodeForThreadLevel;

template function_HPCOM_TaskDep(list<tuple<Task,list<Integer>>> tasks, list<SimEqSystem> allEquationsPlusWhen, String iType, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
::=
  let odeEqs = tasks |> t => function_HPCOM_TaskDep0(t,allEquationsPlusWhen, iType, &varDecls, simCode, useFlatArrayNotation); separator="\n"
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
end function_HPCOM_TaskDep;

template function_HPCOM_TaskDep0(tuple<Task,list<Integer>> taskIn, list<SimEqSystem> allEquationsPlusWhen, String iType, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
::=
  match taskIn
    case ((task as CALCTASK(__),parents)) then
        let taskEqs = function_HPCOM_Task(allEquationsPlusWhen,task,iType,&varDecls,simCode,useFlatArrayNotation); separator="\n"
        let parentDependencies = parents |> p => 't[<%p%>]'; separator = ","
        let taskDependencies = parents |> p => '<%p%>'; separator = ","
        let depIn = if intGt(listLength(parents),0) then 'depend(in:<%parentDependencies%>) ' else ""
        <<
        //TG_NODE: <%task.index%> TG_PARENTS: <%taskDependencies%>
        #pragma omp task <%depIn%>depend(out:t[<%task.index%>])
        {
            <%taskEqs%>
        }
        >>
end function_HPCOM_TaskDep0;

template function_HPCOM_TaskDep_tbb(list<tuple<Task,list<Integer>>> tasks, list<SimEqSystem> allEquationsPlusWhen, String iType, Absyn.Path name, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
::=
  let noteEqs = tasks |> t => function_HPCOM_TaskDep_tbb0(t,allEquationsPlusWhen, iType, name, &varDecls, simCode); separator="\n"
  <<
        //Init base node
        broadcast_node< continue_msg > tbb_start(tbb_graph);

        <%noteEqs%>

        //Start
        tbb_start.try_put(continue_msg());
        tbb_graph.wait_for_all();
        //End
  >>
end function_HPCOM_TaskDep_tbb;

template function_HPCOM_TaskDep_voidfunc(list<tuple<Task,list<Integer>>> tasks, list<SimEqSystem> allEquationsPlusWhen, String iType, Absyn.Path name, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
::=
  let funcTasks = tasks |> t => function_HPCOM_TaskDep_voidfunc0(t,allEquationsPlusWhen,iType, name, &varDecls, simCode, useFlatArrayNotation); separator="\n"
  <<
  <%funcTasks%>
  >>
end function_HPCOM_TaskDep_voidfunc;

template function_HPCOM_TaskDep_tbb0(tuple<Task,list<Integer>> taskIn, list<SimEqSystem> allEquationsPlusWhen, String iType, Absyn.Path name, Text &varDecls, SimCode simCode)
::=
  match taskIn
    case ((task as CALCTASK(__),parents)) then
        let parentEdges = parents |> p => 'make_edge(tbb_task_<%p%>,tbb_task_<%task.index%>);'; separator = "\n"
        <<
            continue_node < continue_msg > tbb_task_<%task.index%>(tbb_graph,VoidBody(boost::bind<void>(&<%lastIdentOfPath(name)%>::task_func_<%task.index%>,this)));
            <%parentEdges%>

        >>
end function_HPCOM_TaskDep_tbb0;

template function_HPCOM_TaskDep_voidfunc0(tuple<Task,list<Integer>> taskIn, list<SimEqSystem> allEquationsPlusWhen, String iType, Absyn.Path name, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
::=
  match taskIn
    case ((task as CALCTASK(__),parents)) then
        let &tempvarDecl = buffer "" /*BUFD*/
        let taskEqs = function_HPCOM_Task(allEquationsPlusWhen,task,iType,&tempvarDecl,simCode,useFlatArrayNotation); separator="\n"
        <<
        void <%lastIdentOfPath(name)%>::task_func_<%task.index%>()
        {
            <%tempvarDecl%>
            <%taskEqs%>
        }
        >>
end function_HPCOM_TaskDep_voidfunc0;

template function_HPCOM_Thread(list<SimEqSystem> allEquationsPlusWhen, array<list<Task>> threadTasks, String iType, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
::=
  match iType
    case ("openmp") then
      let odeEqs = arrayList(threadTasks) |> tt hasindex i0 => function_HPCOM_Thread0(allEquationsPlusWhen,tt,i0,iType,&varDecls,simCode, useFlatArrayNotation); separator="\n"
      let threadAssignLocks = arrayList(threadTasks) |> tt hasindex i0 fromindex 0 => function_HPCOM_assignThreadLocks(arrayGet(threadTasks, intAdd(i0, 1)), "lock", i0, iType); separator="\n"
      let threadReleaseLocks = arrayList(threadTasks) |> tt hasindex i0 fromindex 0 => function_HPCOM_releaseThreadLocks(arrayGet(threadTasks, intAdd(i0, 1)), "lock", i0, iType); separator="\n"
      <<
      if (omp_get_dynamic())
        omp_set_dynamic(0);
      #pragma omp parallel num_threads(<%arrayLength(threadTasks)%>)
      {
         int threadNum = omp_get_thread_num();

         //Assign locks first
         <%threadAssignLocks%>
         #pragma omp barrier
         <%odeEqs%>
         #pragma omp barrier
         //Release locks after calculation
         <%threadReleaseLocks%>
      }
      >>
    case ("mpi") then
      let odeEqs = arrayList(threadTasks) |> tt hasindex i0 =>
        function_HPCOM_Thread0(allEquationsPlusWhen, tt, i0, iType, &varDecls, simCode, useFlatArrayNotation); separator="\n"
      <<
      int world_rank;
      MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
      <%odeEqs%>
      >>
    else
      let odeEqs = arrayList(threadTasks) |> tt hasindex i0 => function_HPCOM_Thread0(allEquationsPlusWhen,tt,i0,iType,&varDecls,simCode, useFlatArrayNotation); separator="\n"
      <<
      <%odeEqs%>
      >>

end function_HPCOM_Thread;

template generateThreadFunc(list<SimEqSystem> allEquationsPlusWhen, array<list<Task>> threadTasks, String iType, Integer idx, String modelNamePrefixStr, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
::=
  let &varDeclsLoc = buffer "" /*BUFD*/
  let taskEqs = function_HPCOM_Thread0(allEquationsPlusWhen, arrayGet(threadTasks,intAdd(idx,1)), idx, iType, &varDeclsLoc, simCode, useFlatArrayNotation); separator="\n"
  let assLock = assignLockByLockName(idx, "th_lock", iType); separator="\n"
  let relLock = releaseLockByLockName(idx, "th_lock1", iType); separator="\n"
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

template function_HPCOM_assignThreadLocks(list<Task> iThreadTasks, String iLockPrefix, Integer iThreadNum, String iType)
::=
  let lockAssign = iThreadTasks |> tt => '<%(
    match(tt)
        case(task as DEPTASK(outgoing=false)) then
            assignLockByDepTask(task, iLockPrefix, iType)
        else ""
    end match)%>'; separator="\n"
  <<
  if(threadNum == <%iThreadNum%>)
  {
    <%lockAssign%>
  }
  >>
end function_HPCOM_assignThreadLocks;

template function_HPCOM_releaseThreadLocks(list<Task> iThreadTasks, String iLockPrefix, Integer iThreadNum, String iType)
::=
  let lockAssign = iThreadTasks |> tt => '<%(
    match(tt)
        case(DEPTASK(outgoing=true)) then
            releaseLockByDepTask(tt, iLockPrefix, iType)
        else ""
    end match)%>'; separator="\n"
  <<
  if(threadNum == <%iThreadNum%>)
  {
    <%lockAssign%>
  }
  >>
end function_HPCOM_releaseThreadLocks;

template function_HPCOM_Thread0(list<SimEqSystem> allEquationsPlusWhen, list<Task> threadTaskList, Integer iThreadNum, String iType, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
::=
  let threadTasks = threadTaskList |> tt => function_HPCOM_Task(allEquationsPlusWhen,tt,iType,&varDecls,simCode,useFlatArrayNotation); separator="\n"
  match iType
    case ("openmp") then
      <<
      if(threadNum == <%iThreadNum%>)
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
    case ("mpi") then
      <<
      if (world_rank == <%iThreadNum%>)
      {
        <%threadTasks%>
      }
      >>
end function_HPCOM_Thread0;

template function_HPCOM_Task(list<SimEqSystem> allEquationsPlusWhen, Task iTask, String iType, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
::=
  match iTask
    case (task as CALCTASK(__)) then
      let odeEqs = task.eqIdc |> eq => equationNamesHPCOM_(eq,allEquationsPlusWhen,contextSimulationNonDiscrete,&varDecls, simCode, useFlatArrayNotation); separator="\n"
      let &varDeclsLocal = buffer "" /*BUFL*/
      <<
      // Task <%task.index%>
      <%odeEqs%>
      // End Task <%task.index%>
      >>
    case (task as CALCTASK_LEVEL(__)) then
      let odeEqs = task.eqIdc |> eq => equationNamesHPCOM_(eq,allEquationsPlusWhen,contextSimulationNonDiscrete,&varDecls, simCode, useFlatArrayNotation); separator="\n"
      let taskStr = task.nodeIdc |> task => '<%task%>';separator=","
      let &varDeclsLocal = buffer "" /*BUFL*/
      <<
      // Tasks <%taskStr%>
      <%odeEqs%>
      >>
    case(task as DEPTASK(outgoing=false)) then
      let assLck = assignLockByDepTask(task, "lock", iType); separator="\n"
      <<
      <%assLck%>
      >>
    case(task as DEPTASK(outgoing=true)) then
      let relLck = releaseLockByDepTask(task, "lock", iType); separator="\n"
      <<
      <%relLck%>
      >>
end function_HPCOM_Task;

template equationNamesHPCOM_(Integer idx, list<SimEqSystem> allEquationsPlusWhen, Context context, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
::=
    let eq = equationHPCOM_(getSimCodeEqByIndex(allEquationsPlusWhen, idx), idx, context, &varDecls, simCode, useFlatArrayNotation)
    <<
    <%eq%>
    >>
end equationNamesHPCOM_;

template equationHPCOM_(SimEqSystem eq, Integer idx, Context context, Text &varDecls, SimCode simCode, Boolean useFlatArrayNotation)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  equation_function_call(eq, context, &varDecls /*BUFC*/, simCode,"evaluate")
/*  match eq
  case e as SES_SIMPLE_ASSIGN(__) then
    let &varDeclsLocal = buffer "" BUFL
    let eqText = equation_(eq,context,&varDeclsLocal,simCode, useFlatArrayNotation)
    <<
    <%varDeclsLocal%>
    <%eqText%>
    >>
  case e as SES_ALGORITHM(__)
    then 'evaluate_<%idx%>();'
  case e as SES_WHEN(__)
    then 'evaluate_<%idx%>();'
  case e as SES_ARRAY_CALL_ASSIGN(__)
    then 'evaluate_<%idx%>();'
  case e as SES_LINEAR(__)
  case e as SES_NONLINEAR(__)
    then 'evaluate_<%idx%>();'
  case e as SES_MIXED(__)
    then 'evaluate_<%idx%>();'
  else
    "NOT IMPLEMENTED EQUATION"
*/
end equationHPCOM_;

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

template generateThread(Integer threadIdx, String iType, String modelNamePrefixStr, String funcName)
::=
  match iType
    case ("openmp") then
      <<
      >>
    else
      <<
      evaluateThread<%threadIdx%> = new boost::thread(boost::bind(&<%modelNamePrefixStr%>::<%funcName%><%threadIdx%>, this));
      >>
end generateThread;

template getLockNameByDepTask(Task depTask)
::=
  match(depTask)
    case(DEPTASK(sourceTask=CALCTASK(index=sourceIdx), targetTask=CALCTASK(index=targetIdx))) then
      '<%sourceIdx%>_<%targetIdx%>'
    else
      'invalidLockTask'
  end match
end getLockNameByDepTask;

template initializeLockByDepTask(Task depTask, String lockPrefix, String iType)
::=
  let lockName = getLockNameByDepTask(depTask)
  <<
  <%initializeLockByLockName(lockName, lockPrefix, iType)%>
  >>
end initializeLockByDepTask;

template initializeLockByLockName(String lockName, String lockPrefix, String iType)
::=
  match iType
    case ("openmp") then
      <<
      omp_init_lock(&<%lockPrefix%>_<%lockName%>);
      >>
    case ("pthreads") then
      <<
      >>
    case ("pthreads_spin") then
      <<
      <%lockPrefix%>_<%lockName%> = BOOST_DETAIL_SPINLOCK_INIT;
      >>
end initializeLockByLockName;

template initializeBarrierByName(String lockName, String lockPrefix, Integer numberOfThreads, String iType)
::=
  match iType
    case ("pthreads")
    case ("pthreads_spin") then
      <<
      <%lockPrefix%>_<%lockName%>(<%numberOfThreads%>)
      >>
end initializeBarrierByName;

template createLockByDepTask(Task depTask, String lockPrefix, String iType)
::=
  let lockName = getLockNameByDepTask(depTask)
  <<
  <%createLockByLockName(lockName, lockPrefix, iType)%>
  >>
end createLockByDepTask;

template createLockByLockName(String lockName, String lockPrefix, String iType)
::=
  match iType
    case ("openmp") then
      <<
      omp_lock_t <%lockPrefix%>_<%lockName%>;
      >>
    case ("pthreads") then
      <<
      boost::mutex <%lockPrefix%>_<%lockName%>;
      >>
    case ("pthreads_spin") then
      <<
      boost::detail::spinlock <%lockPrefix%>_<%lockName%>;
      >>
end createLockByLockName;

template createBarrierByName(String lockName, String lockPrefix, Integer numOfThreads, String iType)
::=
  match iType
    case ("pthreads")
    case ("pthreads_spin") then
      <<
      boost::barrier <%lockPrefix%>_<%lockName%>;
      >>
end createBarrierByName;

template destroyLockByDepTask(Task depTask, String lockPrefix, String iType)
::=
  let lockName = getLockNameByDepTask(depTask)
  <<
  <%destroyLockByLockName(lockName, lockPrefix, iType)%>
  >>
end destroyLockByDepTask;

template destroyLockByLockName(String lockName, String lockPrefix, String iType)
::=
  match iType
    case ("openmp") then
      <<
      omp_destroy_lock(&<%lockPrefix%>_<%lockName%>);
      >>
    else
      <<
      >>
end destroyLockByLockName;

template assignLockByDepTask(Task depTask, String lockPrefix, String iType)
::=
  match(depTask)
    case(DEPTASK(__)) then
      let lockName = getLockNameByDepTask(depTask)
      <<
      /*<%printCommunicationInfoVariables(depTask.communicationInfo)%>*/
      <%assignLockByLockName(lockName, lockPrefix, iType)%>
      >>
  end match
end assignLockByDepTask;

template printCommunicationInfoVariables(CommunicationInfo commInfo)
::=
  match(commInfo)
    case(COMMUNICATION_INFO(__)) then
      let floatVarsStr = floatVars |> v => '<%CodegenCpp.MemberVariableDefine2(v, "", false)%>' ;separator="\n"
      let intVarsStr = intVars |> v => '<%CodegenCpp.MemberVariableDefine2(v, "", false)%>' ;separator="\n"
      let boolVarsStr = boolVars |> v => '<%CodegenCpp.MemberVariableDefine2(v, "", false)%>' ;separator="\n"
      <<
      <%floatVarsStr%>
      >>
    else
      <<
      //unsupported communcation info
      >>
  end match
end printCommunicationInfoVariables;

template assignLockByLockName(String lockName, String lockPrefix, String iType)
::=
  match iType
    case ("openmp") then
      <<
      omp_set_lock(&<%lockPrefix%>_<%lockName%>);
      >>
    case ("pthreads") then
      <<
      <%lockPrefix%>_<%lockName%>.lock();
      >>
    case ("pthreads_spin") then
      <<
      <%lockPrefix%>_<%lockName%>.lock();
      >>
end assignLockByLockName;

template releaseLockByDepTask(Task depTask, String lockPrefix, String iType)
::=
  let lockName = getLockNameByDepTask(depTask)
  <<
  <%releaseLockByLockName(lockName, lockPrefix, iType)%>
  >>
end releaseLockByDepTask;

template releaseLockByLockName(String lockName, String lockPrefix, String iType)
::=
  match iType
    case ("openmp") then
      <<
      omp_unset_lock(&<%lockPrefix%>_<%lockName%>);
      >>
    case ("pthreads") then
      <<
      <%lockPrefix%>_<%lockName%>.unlock();
      >>
    case ("pthreads_spin") then
      <<
      <%lockPrefix%>_<%lockName%>.unlock();
      >>
end releaseLockByLockName;


template simulationMainFileAnalyzation(SimCode simCode)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__)) then
  <<

  #ifndef BOOST_ALL_DYN_LINK
    #define BOOST_ALL_DYN_LINK
  #endif
  #include <Core/Modelica.h>
  #include <Core/ModelicaDefine.h>
  #include <SimCoreFactory/Policies/FactoryConfig.h>
  #include <SimController/ISimController.h>

  #ifdef ANALYZATION_MODE
  #include "Solver/IAlgLoopSolver.h"
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

  #include <SimCoreFactory/Policies/FactoryConfig.h>
  #include <SimController/ISimController.h>
  <%
    match(getConfigString(PROFILING_LEVEL))
        case("none") then ''
        case("all_perf") then '#include "Core/Utils/extension/measure_time_papi.hpp"'
        else '#include "Core/Utils/extension/measure_time_rdtsc.hpp"'
    end match
  %>

  #if defined(_MSC_VER) || defined(__MINGW32__)
  #include <tchar.h>
  int _tmain(int argc, const _TCHAR* argv[])
  #else
  int main(int argc, const char* argv[])
  #endif
  {
      <%
      match(getConfigString(PROFILING_LEVEL))
          case("none") then '//no profiling used'
          case("all_perf") then 'MeasureTimePAPI::initialize();'
          else 'MeasureTimeRDTSC::initialize();'
      end match
      %>
      try
      {
      boost::shared_ptr<OMCFactory>  _factory =  boost::shared_ptr<OMCFactory>(new StaticOMCFactory());
            //SimController to start simulation

            std::pair<boost::shared_ptr<ISimController>,SimSettings> simulation =  _factory->createSimulation(argc,argv);


        //create Modelica system
         #ifdef ANALYZATION_MODE
            std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> > system = simulation.first->LoadSystem(&createSimData, &createSystem, "<%lastIdentOfPath(modelInfo.name)%>");
         #else
            std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> > system = simulation.first->LoadSystem("OMCpp<%fileNamePrefix%><%makefileParams.dllext%>","<%lastIdentOfPath(modelInfo.name)%>");
         #endif
            simulation.first->Start(system.first,simulation.second, "<%lastIdentOfPath(modelInfo.name)%>");

            <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
                <<
                MeasureTime::getInstance()->writeToJson();
                //MeasureTimeRDTSC::deinitialize();
                >>
            %>
            return 0;

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

template MPIInMainFile(String type)
::=
  match type
    case "mpi" then
      <<
      char** argvNotConst = const_cast<char**>(argv);
      MPI_Init(&argc, &argvNotConst);
      int world_rank, world_size;
      MPI_Comm_size(MPI_COMM_WORLD, &world_size);
      MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

      std::cout << "Hello World! This is MPI process " << world_rank
                << " of " << world_size << " processes."  << endl;
      >>
    else
      " "
  end match
end MPIInMainFile;


// MF: MPI header file must be included when compiling MPI parallel code.
template IncludeMPIHeader()
 "Includes mpi header file."
::=
  <<
  #include <mpi.h>
  >>
end IncludeMPIHeader;


// MF: Added MPI header and MPI code ("Hello World!") to main file.
template simulationMainFile(SimCode simCode)
 "Generates code for header file for simulation target."
::=
  let type = getConfigString(HPCOM_CODE)
  let MPICode = MPIInMainFile(type)
  let MPIFinalize = (match type case "mpi" then 'MPI_Finalize();' else '')
  let MPIHeaderInclude = (match type case "mpi" then IncludeMPIHeader() else '')

  match simCode
    case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__)) then
      <<
      #ifndef BOOST_ALL_DYN_LINK
        #define BOOST_ALL_DYN_LINK
      #endif

      #include "Modelica.h"
      #include "ModelicaDefine.h"
      #include <SimCoreFactory/Policies/FactoryConfig.h>
      #include <SimController/ISimController.h>
      <%
      match(getConfigString(PROFILING_LEVEL))
        case("none") then ''
        case("all_perf") then '#include "Core/Utils/extension/measure_time_papi.hpp"'
        else '#include "Core/Utils/extension/measure_time_rdtsc.hpp"'
      end match
      %>

      <%MPIHeaderInclude%>

      #if defined(_MSC_VER) || defined(__MINGW32__)
        #include <tchar.h>
        int _tmain(int argc, const _TCHAR* argv[])
      #else
        int main(int argc, const char* argv[])
      #endif
      {
       <%
      match(getConfigString(PROFILING_LEVEL))
          case("none") then '//no profiling used'
          case("all_perf") then 'MeasureTimePAPI::initialize();'
          else 'MeasureTimeRDTSC::initialize();'
      end match
      %>
        try
        {
          <%MPICode%>

          boost::shared_ptr<OMCFactory> _factory = boost::shared_ptr<OMCFactory>(new OMCFactory());
          //SimController to start simulation
          std::pair<boost::shared_ptr<ISimController>, SimSettings> simulation = _factory->createSimulation(argc, argv);

          //Create Modelica system
          std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> > system = simulation.first->LoadSystem("OMCpp<%fileNamePrefix%><%makefileParams.dllext%>", "<%lastIdentOfPath(modelInfo.name)%>");

          simulation.first->Start(system.first, simulation.second, "<%lastIdentOfPath(modelInfo.name)%>");

          <%MPIFinalize%>

            <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
                <<
                MeasureTime::getInstance()->writeToJson();
                //MeasureTimeRDTSC::deinitialize();
                >>
            %>
            return 0;
        }
        catch(std::exception& ex)
        {
          //std::string error = ex.what();
          std::cerr << "Simulation stopped: " << ex.what() << endl; //error;
          return 1;
        }
      }
    >>
  end match
end simulationMainFile;

// MF
template MPIRunCommandInRunScript(String type, Text &getNumOfProcs, Text &executionCommand)
 "If MPI is used:
    - Add the run execution command 'mpirun -np $NPROCESSORS',
    - number of MPI processors can be passed as command line argument to simulation
      run script."
::=
  match type
    case "mpi" then
      let &executionCommand += "mpirun -np ${NPROCESSORS}"
      let &getNumOfProcs += "\nif [ $# -gt 0 ]; then\n  NPROCESSORS=$1\nelse\n  NPROCESSORS=1\nfi\n\n"
      ""
    else
      let &executionCommand += "exec"
      ""
  end match
end MPIRunCommandInRunScript;


// MF: Added the 'getNumOfProcs' and branching of execution command in case of MPI usage.
template simulationMainRunScript(SimCode simCode)
 "Generates code for header file for simulation target."
::=
  let type = getConfigString(HPCOM_CODE)
  //let executionCommand = match type case "mpi" then 'mpirun -np ${NPROCESSORS}' else 'exec'
  let &getNumOfProcs = buffer "" /*BUFD*/
  let &executionCommand = buffer "" /*BUFD*/
  let _ = MPIRunCommandInRunScript(type, &getNumOfProcs, &executionCommand)

  match simCode
    case SIMCODE(makefileParams=MAKEFILE_PARAMS(__)) then
      match makefileParams.platform
        case "linux64"
        case "linux32" then
          match simCode
            case SIMCODE(modelInfo=MODELINFO(__),makefileParams=MAKEFILE_PARAMS(__),simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
              let start = settings.startTime
              let end = settings.stopTime
              let stepsize = settings.stepSize
              let intervals = settings.numberOfIntervals
              let tol = settings.tolerance
              let solver = settings.method
              let moLib =  makefileParams.compileDir
              let home = makefileParams.omhome
              <<
              #!/bin/sh
              <%getNumOfProcs%>
              <%executionCommand%> ./OMCpp<%fileNamePrefix%>Main -s <%start%> -e <%end%> -f <%stepsize%> -v <%intervals%> -y <%tol%> -i <%solver%> -r <%simulationLibDir(simulationCodeTarget(),simCode)%> -m <%moLib%> -R <%simulationResults(getRunningTestsuite(),simCode)%> -o <%settings.outputFormat%> $*
              >>
          end match
        case  "win32"
        case  "win64" then
          match simCode
            case SIMCODE(modelInfo=MODELINFO(__),makefileParams=MAKEFILE_PARAMS(__),simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
              let start = settings.startTime
              let end = settings.stopTime
              let stepsize = settings.stepSize
              let intervals = settings.numberOfIntervals
              let tol = settings.tolerance
              let solver = settings.method
              let moLib = makefileParams.compileDir
              let home = makefileParams.omhome
              <<
              @echo off
              <%moLib%>/OMCpp<%fileNamePrefix%>Main.exe -s <%start%> -e <%end%> -f <%stepsize%> -v <%intervals%> -y <%tol%> -i <%solver%> -r <%simulationLibDir(simulationCodeTarget(),simCode)%> -m <%moLib%> -R <%simulationResults(getRunningTestsuite(),simCode)%> -o <%settings.outputFormat%>
              >>
          end match
  end match
end simulationMainRunScript;


template simulationMakefile(String target,SimCode simCode)
 "Adds specific compiler flags for HPCOM mode to simulation makefile."
::=
    let type = getConfigString(HPCOM_CODE)

    let &additionalCFlags_GCC = buffer ""
    let &additionalCFlags_GCC += if stringEq(type,"openmp") then " -fopenmp" else ""
    let &additionalCFlags_GCC += if Flags.isSet(Flags.HPCOM_ANALYZATION_MODE) then ' -D ANALYZATION_MODE -I"$(SUNDIALS_INCLUDE)" -I"$(SUNDIALS_INCLUDE)/kinsol" -I"$(SUNDIALS_INCLUDE)/nvector"' else ""

    let &additionalCFlags_MSVC = buffer ""
    let &additionalCFlags_MSVC += if stringEq(type,"openmp") then "/openmp" else ""
    let &additionalCFlags_MSVC += if Flags.isSet(Flags.HPCOM_ANALYZATION_MODE) then '/DANALYZATION_MODE /I"$(SUNDIALS_INCLUDE)" /I"$(SUNDIALS_INCLUDE)/kinsol" /I"$(SUNDIALS_INCLUDE)/nvector"' else ""

    let &additionalLinkerFlags_GCC = buffer ""
    let &additionalLinkerFlags_GCC += if Flags.isSet(Flags.HPCOM_ANALYZATION_MODE) then '$(LIBOMCPPOMCFACTORY) $(LIBOMCPPSIMCONTROLLER) $(LIBOMCPPSIMULATIONSETTINGS) $(LIBOMCPPSYSTEM) $(LIBOMCPPDATAEXCHANGE) $(LIBOMCPPNEWTON) $(LIBOMCPPUMFPACK) $(LIBOMCPPKINSOL) $(LIBOMCPPCVODE) $(LIBOMCPPSOLVER) $(LIBOMCPPMATH) $(LIBOMCPPMODELICAUTILITIES) $(SUNDIALS_LIBS) $(LAPACK_LIBS) $(BASE_LIB)' else '-lOMCppOMCFactory $(BASE_LIB)'
    let &additionalLinkerFlags_GCC += if stringEq(type,"tbb") then "-ltbb" else ""

    let &additionalLinkerFlags_MSVC = buffer ""

    // MF: Are we using MPI parallel code?
    let &compileForMPI = buffer ""
    let &compileForMPI += if stringEq(type, "mpi") then "true" else "false"

    CodegenCpp.simulationMakefile(target, simCode, additionalLinkerFlags_GCC,
                                additionalCFlags_MSVC, additionalCFlags_GCC,
                                additionalLinkerFlags_MSVC, Util.stringBool(compileForMPI), Flags.isSet(Flags.HPCOM_ANALYZATION_MODE))
end simulationMakefile;


// --------------------------------------------------------------------------------------------------------------------------------------------
// Member Variable Stuff
// --------------------------------------------------------------------------------------------------------------------------------------------

template MemberVariable(ModelInfo modelInfo, Option<MemoryMap> hpcOmMemory, Boolean useFlatArrayNotation, Boolean createConstructorDeclaration)
 "Define membervariable in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  <%vars.algVars |> var =>
    MemberVariableDefine2(var, "algebraics", hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
  <%vars.discreteAlgVars |> var =>
    MemberVariableDefine2(var, "algebraics", hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
  <%vars.paramVars |> var =>
    MemberVariableDefine2(var, "parameters", hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
   <%vars.aliasVars |> var =>
    MemberVariableDefine2(var, "aliasVars", hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
  <%vars.intAlgVars |> var =>
    MemberVariableDefine("int", var, "intVariables.algebraics",hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
  <%vars.intParamVars |> var =>
    MemberVariableDefine("int", var, "intVariables.parameters",hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
   <%vars.intAliasVars |> var =>
    MemberVariableDefine("int", var, "intVariables.AliasVars",hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
  <%vars.boolAlgVars |> var =>
    MemberVariableDefine("bool",var, "boolVariables.algebraics",hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
  <%vars.boolParamVars |> var =>
    MemberVariableDefine("bool",var, "boolVariables.parameters",hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
   <%vars.boolAliasVars |> var =>
    MemberVariableDefine("bool ",var, "boolVariables.AliasVars",hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
  <%vars.stringAlgVars |> var =>
    MemberVariableDefine("string",var, "stringVariables.algebraics",hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
  <%vars.stringParamVars |> var =>
    MemberVariableDefine("string",var, "stringVariables.parameters",hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
  <%vars.stringAliasVars |> var =>
    MemberVariableDefine("string",var, "stringVariables.AliasVars",hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
   <%vars.constVars |> var =>
    MemberVariableDefine2(var, "constvariables", hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
   <%vars.intConstVars |> var =>
    MemberVariableDefine("const int", var, "intConstvariables",hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
   <%vars.boolConstVars |> var =>
    MemberVariableDefine("const bool", var, "boolConstvariables",hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
   <%vars.stringConstVars |> var =>
    MemberVariableDefine("const string",var, "stringConstvariables",hpcOmMemory,useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
   <%vars.extObjVars |> var =>
    MemberVariableDefine("void*",var, "extObjVars",hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
  ;separator="\n"%>
  >>
end MemberVariable;

template MemberVariableDefine(String type,SimVar simVar, String arrayName, Option<MemoryMap> hpcOmMemoryOpt, Boolean useFlatArrayNotation, Boolean createConstructorDeclaration)
::=
match simVar

     case SIMVAR(numArrayElement={},arrayCref=NONE(),name=CREF_IDENT(subscriptLst=_::_)) then ''

    case SIMVAR(name=varName,numArrayElement={},arrayCref=NONE()) then
        match(hpcOmMemoryOpt)
            case SOME(hpcOmMemory) then
              <<
              // case 2 MemberVariableDefine
              <%MemberVariableDefine3(HpcOmMemory.getPositionMappingByArrayName(hpcOmMemory,varName), simVar, useFlatArrayNotation, createConstructorDeclaration)%>
              >>
            else
              <<
              <%if createConstructorDeclaration then '' else '<%variableType(simVar.type_)%> <%cref(simVar.name,useFlatArrayNotation)%>; //no cacheMap defined'%>
              >>
        end match
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num) then
      let &dims = buffer "" /*BUFD*/
      let arrayName = arraycref2(name,dims)
      <<
      multi_array<<%variableType(type_)%>,<%dims%>>  <%arrayName%>;
      >>
    case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(arrayCrefLocal),numArrayElement=num,type_=varType) then
      let &dims = buffer "" /*BUFD*/
      let arrayName = arraycref2(name,dims)
      let typeString = variableType(type_)
      let arraysize = arrayextentDims(name,v.numArrayElement)
      match(hpcOmMemoryOpt)
            case SOME(hpcOmMemory) then
              let varDeclarations = HpcOmMemory.expandCref(name,num) |> crefLocal => MemberVariableDefine4(HpcOmMemory.getPositionMappingByArrayName(hpcOmMemory,crefLocal), crefLocal, varType, useFlatArrayNotation, createConstructorDeclaration); separator="\n"
              <<
              // case 3 MemberVariableDefine dims:<%dims%> nums:<%num%>
              <%varDeclarations%>
              >>
            else
              <<
              <%if createConstructorDeclaration then '' else 'StatArrayDim<%dims%><<%variableType(v.type_)%>,<%arraysize%>>  <%arrayName%>; //no cacheMap defined' %>
              >>
      end match
    case SIMVAR(numArrayElement=_::_) then
      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      let varType = variableType(type_)
      match dims
        case "0" then  if createConstructorDeclaration then '' else '<%varType%> <%varName%>;'
        else ''
      end match
end MemberVariableDefine;

template MemberVariableDefine2(SimVar simVar, String arrayName, Option<MemoryMap> hpcOmMemoryOpt, Boolean useFlatArrayNotation, Boolean createConstructorDeclaration)
::=
match simVar
      case SIMVAR(numArrayElement={},arrayCref=NONE(),name=CREF_IDENT(subscriptLst=_::_)) then ''

      case SIMVAR(name=varName,numArrayElement={},arrayCref=NONE()) then
        match(hpcOmMemoryOpt)
            case SOME(hpcOmMemory) then
              <<
              <%MemberVariableDefine3(HpcOmMemory.getPositionMappingByArrayName(hpcOmMemory,varName), simVar, useFlatArrayNotation, createConstructorDeclaration)%>
              >>
            else
              <<
              <%if createConstructorDeclaration then '' else '<%variableType(simVar.type_)%> <%cref(simVar.name,useFlatArrayNotation)%>; //no cacheMap defined'%>
              >>
        end match
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(arrayCrefLocal),numArrayElement=num,type_=varType) then
        let &dims = buffer "" /*BUFD*/
        let arrayName = arraycref2(name,dims)
        let typeString = variableType(type_)
        let arraysize = arrayextentDims(name,v.numArrayElement)
        match(hpcOmMemoryOpt)
            case SOME(hpcOmMemory) then
              let varDeclarations = HpcOmMemory.expandCref(arrayCrefLocal,num) |> crefLocal => MemberVariableDefine4(HpcOmMemory.getPositionMappingByArrayName(hpcOmMemory,crefLocal), crefLocal, varType, useFlatArrayNotation, createConstructorDeclaration); separator="\n"
              <<
              // case 2 MemberVariableDefine2
              <%varDeclarations%>
              >>
            else
              <<
              <%if createConstructorDeclaration then '' else 'StatArrayDim<%dims%><<%typeString%>,<%arraysize%>> <%arrayName%>; //no cacheMap defined' %>
              >>
        end match
    case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(arrayCrefLocal),numArrayElement=num,type_=varType) then
      let &dims = buffer "" /*BUFD*/
      let arrayName = arraycref2(name,dims)
      let typeString = variableType(type_)
      let arraysize = arrayextentDims(name,v.numArrayElement)
      match(hpcOmMemoryOpt)
            case SOME(hpcOmMemory) then
              let varDeclarations = HpcOmMemory.expandCref(name,num) |> crefLocal => MemberVariableDefine4(HpcOmMemory.getPositionMappingByArrayName(hpcOmMemory,crefLocal), crefLocal, varType, useFlatArrayNotation, createConstructorDeclaration); separator="\n"
              <<
              // case 3 MemberVariableDefine2 dims:<%dims%> nums:<%num%>
              <%varDeclarations%>
              >>
            else
              <<
              <%if createConstructorDeclaration then '' else 'StatArrayDim<%dims%><<%typeString%>, <%arraysize%>> <%arrayName%>; //no cacheMap defined' %>
              >>
      end match
   /*special case for varibales that marked as array but are not arrays */
    case SIMVAR(numArrayElement=_::_) then
      let& dims = buffer "" /*BUFD*/
      let varName = arraycref2(name,dims)
      let varType = variableType(type_)
      match dims
        case "0" then (if createConstructorDeclaration then '' else '<%varType%> <%varName%>;')
        else ''
      end match
end MemberVariableDefine2;

template MemberVariableDefine3(Option<tuple<Integer,Integer>> optVarArrayAssignment, SimVar simVar, Boolean useFlatArrayNotation, Boolean createConstructorDeclaration)
::=
  match optVarArrayAssignment
    case SOME((varIdx, arrayIdx))
        then
            match simVar
                case SIMVAR(__) then
                    <<
                    <%if createConstructorDeclaration then ',<%cref(name, useFlatArrayNotation)%>(varArray<%arrayIdx%>[<%varIdx%>])'
                      else '<%variableType(type_)%>& <%cref(name, useFlatArrayNotation)%>;// = varArray<%arrayIdx%>[<%varIdx%>] - MemberVariableDefine3' %>
                    >>
            end match
        else
            match simVar
                case SIMVAR(__) then
                <<
                <%if createConstructorDeclaration then '/* no varIdx found for variable <%cref(name,useFlatArrayNotation)%> */' else '<%variableType(type_)%> <%cref(name, useFlatArrayNotation)%>; //not optimized' %>
                >>
            end match
  end match
end MemberVariableDefine3;

template MemberVariableDefine4(Option<tuple<Integer,Integer>> optVarArrayAssignment, DAE.ComponentRef varName, DAE.Type type_, Boolean useFlatArrayNotation, Boolean createConstructorDeclaration)
::=
  match optVarArrayAssignment
    case SOME((varIdx, arrayIdx)) then
        <<
        <%if createConstructorDeclaration then ',<%cref(varName,useFlatArrayNotation)%>(varArray<%arrayIdx%>[<%varIdx%>])'
        else '<%variableType(type_)%>& <%cref(varName,useFlatArrayNotation)%>;// = varArray<%arrayIdx%>[<%varIdx%>] - MemberVariableDefine4' %>
        >>
    else
        <<
        <%if createConstructorDeclaration then '/* no varIdx found for variable <%cref(varName,useFlatArrayNotation)%> */' else '<%variableType(type_)%> <%cref(varName,useFlatArrayNotation)%>;'%>
        >>
  end match
end MemberVariableDefine4;

annotation(__OpenModelica_Interface="backend");
end CodegenCppHpcom;
