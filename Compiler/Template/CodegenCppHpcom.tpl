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



template translateModel(SimCode simCode)
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__), makefileParams = MAKEFILE_PARAMS(__), hpcomData = HPCOMDATA(__)) then
      let target  = simulationCodeTarget()
      let &extraFuncs = buffer "" /*BUFD*/
      let &extraFuncsDecl = buffer "" /*BUFD*/
      let stateDerVectorName = "__zDot"
      let useMemoryOptimization = Flags.isSet(Flags.HPCOM_MEMORY_OPT)

      let className = lastIdentOfPath(modelInfo.name)
      let numRealVars = numRealvars(modelInfo, hpcomData.hpcOmMemory)
      let numIntVars = numIntvars(modelInfo, hpcomData.hpcOmMemory)
      let numBoolVars = numBoolvars(modelInfo, hpcomData.hpcOmMemory)
      let numPreVars = getPreVarsCount(modelInfo, hpcomData.hpcOmMemory)

      let() = textFile(simulationMainFile(target, simCode, &extraFuncs, &extraFuncsDecl, "",
                                          (if Flags.isSet(USEMPI) then "#include <mpi.h>" else ""),
                                          (if Flags.isSet(USEMPI) then MPIInit() else ""),
                                          (if Flags.isSet(USEMPI) then MPIFinalize() else ""),
                                          numRealVars, numIntVars, numBoolVars, numPreVars),
                                          'OMCpp<%fileNamePrefix%>Main.cpp')
      let() = textFile(simulationCppFile(simCode, contextOther, Update(simCode, extraFuncs, extraFuncsDecl, className, stateDerVectorName, false),
                                         '<%numRealVars%>-1', '<%numIntVars%>-1', '<%numBoolVars%>-1', &extraFuncs, &extraFuncsDecl, className,
                                         generateAdditionalConstructorDefinitions(hpcomData.odeSchedule),
                                         generateAdditionalConstructorBodyStatements(hpcomData.odeSchedule, className, dotPath(modelInfo.name)),
                                         generateAdditionalDestructorBodyStatements(hpcomData.odeSchedule),
                                         stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>.cpp')

      let() = textFile(simulationHeaderFile(simCode ,contextOther, &extraFuncs, &extraFuncsDecl, "",
                      generateAdditionalIncludes(simCode, &extraFuncs, &extraFuncsDecl, className, false),
                      "",
                      generateAdditionalProtectedMemberDeclaration(simCode, &extraFuncs, &extraFuncsDecl, "", false),
                      MemberVariableDefine(modelInfo, varToArrayIndexMapping, '<%numRealVars%>-1', '<%numIntVars%>-1', '<%numBoolVars%>-1', false),
                      MemberVariablePreVariables(modelInfo, varToArrayIndexMapping, '<%numRealVars%>-1', '<%numIntVars%>-1', '<%numBoolVars%>-1', false), false),
                      //CodegenCpp.MemberVariablePreVariables(modelInfo,false), false),
                      'OMCpp<%fileNamePrefix%>.h')

      let() = textFile(simulationTypesHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, "",modelInfo.functions, literals,stateDerVectorName,false), 'OMCpp<%fileNamePrefix%>Types.h')
      let() = textFile(simulationMakefile(target,simCode, &extraFuncs, &extraFuncsDecl, ""), '<%fileNamePrefix%>.makefile')

      let &extraFuncsFun = buffer "" /*BUFD*/
      let &extraFuncsDeclFun = buffer "" /*BUFD*/
      let() = textFile(simulationFunctionsHeaderFile(simCode, &extraFuncsFun, &extraFuncsDeclFun, "",modelInfo.functions, literals,stateDerVectorName,false), 'OMCpp<%fileNamePrefix%>Functions.h')
      let() = textFile(simulationFunctionsFile(simCode, &extraFuncsFun, &extraFuncsDeclFun, "", modelInfo.functions, literals,externalFunctionIncludes,stateDerVectorName,false), 'OMCpp<%fileNamePrefix%>Functions.cpp')
      let &extraFuncsInit = buffer "" /*BUFD*/
      let &extraFuncsDeclInit = buffer "" /*BUFD*/
      let() = textFile(simulationInitHeaderFile(simCode, &extraFuncsInit, &extraFuncsDeclInit, ""), 'OMCpp<%fileNamePrefix%>Initialize.h')
      let() = textFile(simulationInitCppFile(simCode ,&extraFuncsInit, &extraFuncsDeclInit, "", stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>Initialize.cpp')
      let() = textFile(simulationInitParameterCppFile(simCode, &extraFuncsInit, &extraFuncsDeclInit, "", stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>InitializeParameter.cpp')
      let() = textFile(simulationInitExtVarsCppFile(simCode, &extraFuncsInit, &extraFuncsDeclInit, "", stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>InitializeExtVars.cpp')
      let() = textFile(simulationInitAliasVarsCppFile(simCode, &extraFuncsInit, &extraFuncsDeclInit, "", stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>InitializeAliasVars.cpp')
      let() = textFile(simulationInitAlgVarsCppFile(simCode, &extraFuncsInit, &extraFuncsDeclInit, "", stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>InitializeAlgVars.cpp')

      let() = textFile(simulationJacobianHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>Jacobian.h')
      let() = textFile(simulationJacobianCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>Jacobian.cpp')
      let() = textFile(simulationStateSelectionCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>StateSelection.cpp')
      let() = textFile(simulationStateSelectionHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>StateSelection.h')
      let() = textFile(simulationExtensionHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>Extension.h')
      let() = textFile(simulationExtensionCppFile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>Extension.cpp')
      let() = textFile(simulationWriteOutputHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>WriteOutput.h')
      let() = textFile(simulationWriteOutputCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>WriteOutput.cpp')
      let() = textFile(simulationWriteOutputAlgVarsCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>WriteOutputAlgVars.cpp')
      let() = textFile(simulationWriteOutputParameterCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", false), 'OMCpp<%fileNamePrefix%>WriteOutputParameter.cpp')
      let() = textFile(simulationWriteOutputAliasVarsCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>WriteOutputAliasVars.cpp')
      let() = textFile(simulationFactoryFile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>FactoryExport.cpp')
      let() = textFile(simulationMainRunScript(simCode, &extraFuncs, &extraFuncsDecl, ""), '<%fileNamePrefix%><%simulationMainRunScriptSuffix(simCode, &extraFuncs, &extraFuncsDecl, "")%>')
      let jac =  (jacobianMatrixes |> (mat, _,_, _, _, _,_) =>
          (mat |> (eqs,_,_) =>  algloopfiles(eqs,simCode, &extraFuncs, &extraFuncsDecl, "",contextAlgloopJacobian, stateDerVectorName, false) ;separator="")
          ;separator="")
      let alg = algloopfiles(listAppend(allEquations,initialEquations), simCode, &extraFuncs, &extraFuncsDecl, "", contextAlgloop, stateDerVectorName, false)
      let() = textFile(algloopMainfile(listAppend(allEquations,initialEquations), simCode, &extraFuncs, &extraFuncsDecl, "", contextAlgloop), 'OMCpp<%fileNamePrefix%>AlgLoopMain.cpp')
      let() = textFile(calcHelperMainfile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>CalcHelperMain.cpp')
      let() = textFile(calcHelperMainfile2(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>CalcHelperMain2.cpp')
      let() = textFile(calcHelperMainfile3(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>CalcHelperMain3.cpp')
      let() = textFile(calcHelperMainfile4(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>CalcHelperMain4.cpp')
      let() = textFile(calcHelperMainfile5(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>CalcHelperMain5.cpp')
      ""
      // empty result of the top-level template .., only side effects
  end match
end translateModel;

template Update(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match simCode
    case SIMCODE(__) then
      <<
      <%update(allEquations, whenClauses, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)%>
      >>
  end match
end Update;

// HEADER
template generateAdditionalIncludes(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
 "Generates code for header file for simulation target."
::=
  match simCode
    case SIMCODE(__) then
      <<
      <%generateAdditionalIncludesForParallelCode(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace)%>
      >>
  end match
end generateAdditionalIncludes;

template generateAdditionalIncludesForParallelCode(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace)
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
      #include <boost/thread.hpp>
      #include <Core/Utils/extension/busywaiting_barrier.hpp>
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
  end match
end generateAdditionalIncludesForParallelCode;

template generateAdditionalProtectedMemberDeclaration(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
 "Generates class declarations."
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__), hpcomData=HPCOMDATA(__)) then
      let &extraFuncsDecl += generateAdditionalFunctionHeaders(hpcomData.odeSchedule)
      let &extraFuncsDecl += generateAdditionalHpcomVarHeaders(hpcomData.odeSchedule)
      let type = getConfigString(HPCOM_CODE)

      <<
      static long unsigned int getThreadNumber()
      {
        <% match type
          case ("openmp") then
            <<
            return (long unsigned int)omp_get_thread_num();
            >>
          case ("mpi") then
            <<
            return -1; //not supported
            >>
          case ("tbb") then
            <<
            return -1; //not supported
            >>
          else
            <<
            boost::hash<std::string> string_hash;
            return (long unsigned int)string_hash(boost::lexical_cast<std::string>(boost::this_thread::get_id()));
            >>
        end match %>
      }

      <% if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
      <<
      std::vector<MeasureTimeData> measureTimeArrayHpcom;
      std::vector<MeasureTimeData> measureTimeSchedulerArrayHpcom;
      //MeasureTimeValues *measuredStartValuesODE, *measuredEndValuesODE;
      MeasureTimeValues *measuredSchedulerStartValues, *measuredSchedulerEndValues;
      >>%>
      >>
  end match
end generateAdditionalProtectedMemberDeclaration;

template generateAdditionalStructHeaders(Option<Schedule> odeScheduleOpt)
::=
  let type = getConfigString(HPCOM_CODE)
  match odeScheduleOpt
    case SOME(odeSchedule as TASKDEPSCHEDULE(__)) then
      match type
        case ("openmp") then
          <<
          >>
        case ("tbb") then
          <<
          //Required for Intel TBB
          struct VoidFunctionBody {
            boost::function<void(void)> void_function;
            VoidFunctionBody(boost::function<void(void)> void_function) : void_function(void_function) { }
            FORCE_INLINE void operator()( tbb::flow::continue_msg ) const
            {
              void_function();
            }
          };
          >>
        else ""
      end match
    else ""
  end match
end generateAdditionalStructHeaders;

template generateAdditionalFunctionHeaders(Option<Schedule> odeScheduleOpt)
::=
  let type = getConfigString(HPCOM_CODE)
  match odeScheduleOpt
    case SOME(odeSchedule as LEVELSCHEDULE(useFixedAssignments=true)) then
      match type
        case ("pthreads")
        case ("pthreads_spin") then
          let threadFuncs = List.intRange(getConfigInt(NUM_PROC)) |> thIdx hasindex i0 fromindex 0 => 'void evaluateThreadFunc<%i0%>();'; separator="\n"
          <<
          <%threadFuncs%>
          >>
        else ""
      end match
    case SOME(odeSchedule as THREADSCHEDULE(__)) then
      let locks = odeSchedule.outgoingDepTasks |> task => createLockByDepTask(task, "lock", type); separator="\n"
      match type
        case ("openmp") then
          <<
          >>
        else
          let headers = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => generateThreadFunctionHeaderDecl(i0); separator="\n"
          <<
          <%headers%>
          >>
      end match
    case SOME(odeSchedule as TASKDEPSCHEDULE(__)) then
      match type
        case ("openmp") then
          <<
          >>
        case ("tbb") then
          let voidfuncs = odeSchedule.tasks |> task => (
              match task
                case ((task as CALCTASK(__),parents)) then
                  <<
                  void task_func_<%task.index%>();
                  >>
                else ""
              ); separator="\n"
          <<
          <%generateAdditionalStructHeaders(odeScheduleOpt)%>

          <%voidfuncs%>
          >>
        else ""
      end match
    else ""
  end match
end generateAdditionalFunctionHeaders;

template generateAdditionalHpcomVarHeaders(Option<Schedule> odeScheduleOpt)
::=
  let type = getConfigString(HPCOM_CODE)
  match odeScheduleOpt
    case SOME(odeSchedule as LEVELSCHEDULE(useFixedAssignments=true)) then
      match type
        case ("pthreads")
        case ("pthreads_spin") then
          <<
          <%List.intRange(getConfigInt(NUM_PROC)) |> thIdx hasindex i0 fromindex 0 => generateThreadHeaderDecl(i0, type)%>
          <%createBarrierByName("levelBarrier","", getConfigInt(NUM_PROC), type)%>
          <%createLockByLockName("measureTimeArrayLock", "", type)%>
          bool _simulationFinished;
          UPDATETYPE _command;
          >>
        else ""
      end match
    case SOME(odeSchedule as THREADSCHEDULE(__)) then
      let locks = odeSchedule.outgoingDepTasks |> task => createLockByDepTask(task, "lock", type); separator="\n"
      match type
        case ("openmp") then
          let threadDecl = arrayList(odeSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => generateThreadHeaderDecl(i0, type); separator="\n"
          <<
          <%locks%>
          <%threadDecl%>
          >>
        case "mpi" then
          <<
          //MF Todo BLABLUB
          >>
        else
          let threadDecl = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => generateThreadHeaderDecl(i0, type); separator="\n"
          let thLocks = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => createLockByLockName(i0, "th_lock", type); separator="\n"
          let thLocks1 = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => createLockByLockName(i0, "th_lock1", type); separator="\n"
          <<
          bool terminateThreads;
          UPDATETYPE command;
          <%locks%>
          <%thLocks%>
          <%thLocks1%>
          <%threadDecl%>
          >>
      end match
    case SOME(odeSchedule as TASKDEPSCHEDULE(__)) then
      match type
        case ("openmp") then
          << >>
        case ("tbb") then
          <<
          tbb::flow::graph _tbbGraph;
          tbb::flow::broadcast_node<tbb::flow::continue_msg> _tbbStartNode;
          std::vector<tbb::flow::continue_node<tbb::flow::continue_msg>* > _tbbNodeList;
          >>
        else ""
      end match
    else ""
  end match
end generateAdditionalHpcomVarHeaders;

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
  end match
end generateThreadHeaderDecl;

template generateThreadFunctionHeaderDecl(Integer threadIdx)
::=
  <<
  void evaluateThreadFunc<%threadIdx%>();
  >>
end generateThreadFunctionHeaderDecl;

template generateAdditionalConstructorDefinitions(Option<Schedule> odeScheduleOpt)
::=
  let type = getConfigString(HPCOM_CODE)
  match odeScheduleOpt
    case SOME(odeSchedule as LEVELSCHEDULE(useFixedAssignments=true)) then
      match type
        case ("pthreads")
        case ("pthreads_spin") then
          <<
          ,_command(IContinuous::UNDEF_UPDATE)
          ,_simulationFinished(false)
          ,<%initializeBarrierByName("levelBarrier","",getConfigInt(NUM_PROC),type)%>
          >>
        else ""
    case SOME(odeSchedule as TASKDEPSCHEDULE(__)) then
      match type
        case ("tbb") then
          <<
          ,_tbbGraph()
          ,_tbbStartNode(_tbbGraph)
          ,_tbbNodeList(<%listLength(odeSchedule.tasks)%>,NULL)
          >>
        else ""
      end match
    else ""
  end match
end generateAdditionalConstructorDefinitions;

template generateAdditionalConstructorBodyStatements(Option<Schedule> odeScheduleOpt, String modelNamePrefixStr, String fullModelName)
::=
  let type = getConfigString(HPCOM_CODE)
  match odeScheduleOpt
    case SOME(odeSchedule as LEVELSCHEDULE(useFixedAssignments=true)) then
      match type
        case ("pthreads")
        case ("pthreads_spin") then
          let threadFuncs = List.intRange(intSub(getConfigInt(NUM_PROC),1)) |> tt hasindex i0 fromindex 1 => generateThread(i0, type, modelNamePrefixStr,"evaluateThreadFunc"); separator="\n"
          <<
          <%threadFuncs%>

          <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
            <<
            #ifdef MEASURETIME_MODELFUNCTIONS
            MeasureTime::addResultContentBlock("<%fullModelName%>","functions_HPCOM_Sections",&measureTimeSchedulerArrayHpcom);
            measureTimeSchedulerArrayHpcom = std::vector<MeasureTimeData>(<%listLength(odeSchedule.tasksOfLevels)%>);
            measuredSchedulerStartValues = MeasureTime::getZeroValues();
            measuredSchedulerEndValues = MeasureTime::getZeroValues();
            <%List.intRange(listLength(odeSchedule.tasksOfLevels)) |> levelIdx => 'measureTimeSchedulerArrayHpcom[<%intSub(levelIdx,1)%>] = MeasureTimeData("evaluateODE_level_<%levelIdx%>");'; separator="\n"%>
            #endif //MEASURETIME_MODELFUNCTIONS
            >>
          %>
          >>
        else ""
      end match
    case SOME(odeSchedule as THREADSCHEDULE(__)) then
      let initlocks = odeSchedule.outgoingDepTasks |> task => initializeLockByDepTask(task, "lock", type); separator="\n"
      let assignLocks = odeSchedule.outgoingDepTasks |> task => assignLockByDepTask(task, "lock", type); separator="\n"
      match type
        case ("openmp") then
          let threadFuncs = arrayList(odeSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => generateThread(i0, type, modelNamePrefixStr,"evaluateThreadFunc"); separator="\n"
          <<
          <%threadFuncs%>
          <%initlocks%>
          >>
        case ("mpi") then
          <<
          //MF: Initialize MPI related stuff - nothing todo?
          >>
        else
          let threadFuncs = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => generateThread(i0, type, modelNamePrefixStr,"evaluateThreadFunc"); separator="\n"
          let threadLocksInit = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => initializeLockByLockName(i0, "th_lock", type); separator="\n"
          let threadLocksInit1 = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => initializeLockByLockName(i0, "th_lock1", type); separator="\n"
          let threadAssignLocks = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => assignLockByLockName(i0, "th_lock", type); separator="\n"
          let threadAssignLocks1 = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => assignLockByLockName(i0, "th_lock1", type); separator="\n"
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
      end match
    case SOME(odeSchedule as TASKDEPSCHEDULE(__)) then
      match type
        case ("tbb") then
          let tbbVars = generateTbbConstructorExtension(odeSchedule.tasks, modelNamePrefixStr)
          <<
          <%tbbVars%>
          >>
        else ""
    else ""
  end match
end generateAdditionalConstructorBodyStatements;

template generateAdditionalDestructorBodyStatements(Option<Schedule> odeScheduleOpt)
::=
  let type = getConfigString(HPCOM_CODE)
  match odeScheduleOpt
    case SOME(odeSchedule as LEVELSCHEDULE(useFixedAssignments=true)) then
      match type
        case ("pthreads")
        case ("pthreads_spin") then
          <<
          _simulationFinished = true;
          //_evaluateBarrier.wait();
          _levelBarrier.wait();
          //_evaluateBarrier.wait();
          _levelBarrier.wait();
          >>
        else ""
    case SOME(odeSchedule as THREADSCHEDULE(__)) then
      let destroylocks = odeSchedule.outgoingDepTasks |> task => destroyLockByDepTask(task, "lock", type); separator="\n"
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
          let destroyThreads = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => function_HPCOM_destroyThread(i0, type); separator="\n"
          let threadLocksDel = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => destroyLockByLockName(i0, "th_lock", type); separator="\n"
          let threadLocksDel1 = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => destroyLockByLockName(i0, "th_lock1", type); separator="\n"
          let joinThreads = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => function_HPCOM_joinThread(i0, type); separator="\n"
          let threadReleaseLocks = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => releaseLockByLockName(i0, "th_lock", type); separator="\n"
          <<
          terminateThreads = true;
          <%threadReleaseLocks%>
          <%joinThreads%>
          <%destroylocks%>
          <%threadLocksDel%>
          <%threadLocksDel1%>
          <%destroyThreads%>
          >>
    case SOME(odeSchedule as TASKDEPSCHEDULE(__)) then
      match type
        case ("tbb") then
          <<
          for(std::vector<tbb::flow::continue_node<tbb::flow::continue_msg>* >::iterator it = _tbbNodeList.begin(); it != _tbbNodeList.end(); it++)
            delete *it;
          >>
        else ""
    else ""
  end match
end generateAdditionalDestructorBodyStatements;


template update(list<SimEqSystem> allEquationsPlusWhen, list<SimWhenClause> whenClauses, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/

  match simCode
    case SIMCODE(modelInfo = MODELINFO(__), hpcomData=HPCOMDATA(__)) then
      let parCode = generateParallelEvaluateOde(allEquationsPlusWhen, odeEquations, modelInfo.name, whenClauses, simCode, extraFuncs ,extraFuncsDecl, extraFuncsNamespace, hpcomData.odeSchedule, context, lastIdentOfPath(modelInfo.name), useFlatArrayNotation)
      <<
      <%equationFunctions(allEquations,whenClauses, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextSimulationDiscrete,stateDerVectorName,useFlatArrayNotation,false)%>

      <%createEvaluateAll(allEquations,whenClauses, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation, boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")))%>

      <%createEvaluateZeroFuncs(equationsForZeroCrossings, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther) %>

      <%createEvaluateConditions(allEquations,whenClauses, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)%>
      <%parCode%>
      >>
  end match
end update;

template generateParallelEvaluateOde(list<SimEqSystem> allEquationsPlusWhen, list<list<SimEqSystem>> odeEquations, Absyn.Path name,
                 list<SimWhenClause> whenClauses, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Option<Schedule> odeScheduleOpt, Context context,
                 String modelNamePrefixStr, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  /* let all_equations = (allEquationsPlusWhen |> eqs => (eqs |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFC*/,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace))
    ;separator="\n") */

  /* let reinit = (whenClauses |> when hasindex i0 => genreinits(when, &varDecls,i0,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace,context)
    ;separator="\n";empty) */

  // Head of function is the same for all schedulers and parallelization methods:
  let functionHead = 'void <%lastIdentOfPath(name)%>::evaluateODE(const UPDATETYPE command)'

  let type = getConfigString(HPCOM_CODE)

  match odeScheduleOpt
    case SOME(odeSchedule as EMPTYSCHEDULE(__)) then
        <<
        <%CodegenCpp.createEvaluate(odeEquations, whenClauses, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, context, boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")))%>
        >>
    case SOME(odeSchedule as LEVELSCHEDULE(useFixedAssignments=false, tasksOfLevels=tasksOfLevels)) then
      let odeEqs = tasksOfLevels |> tasks => generateLevelCodeForLevel(allEquationsPlusWhen, tasks, type, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"

      match type
        case ("openmp") then
          <<
          <%functionHead%>
          {
            <%generateMeasureTimeStartCode("measuredFunctionStartValues", "evaluateODE", "MEASURETIME_MODELFUNCTIONS")%>
            <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then '//MeasureTimeValues **threadValues = new MeasureTimeValues*[<%getConfigInt(NUM_PROC)%>];'%>
            #pragma omp parallel num_threads(<%getConfigInt(NUM_PROC)%>)
            {
              <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
              <<
              /*MeasureTimeValues *valuesStart = MeasureTime::getZeroValues();
              MeasureTimeValues *valuesEnd = MeasureTime::getZeroValues();
              <%generateMeasureTimeStartCode('valuesStart', "evaluateODEInner", "MEASURETIME_MODELFUNCTIONS")%>*/
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

            <%generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "measureTimeFunctionsArray[0]", "evaluateODE", "MEASURETIME_MODELFUNCTIONS")%>
          }
          >>
        else
          <<
          <%functionHead%>
          {
            throw std::runtime_error("Type <%type%> is unsupported for level scheduling.");
          }
          >>
     end match
   case SOME(odeSchedule as LEVELSCHEDULE(useFixedAssignments=true, tasksOfLevels=tasksOfLevels)) then
      match type
        case ("pthreads")
        case ("pthreads_spin") then
          let &mainThreadCode = buffer "" /*BUFD*/
          let eqsFuncs = arrayList(HpcOmScheduler.convertFixedLevelScheduleToTaskLists(odeSchedule, getConfigInt(NUM_PROC))) |> tasks hasindex i0 fromindex 0 => generateLevelFixedCodeForThread(allEquationsPlusWhen, tasks, i0, type, &varDecls, name, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, &mainThreadCode, useFlatArrayNotation); separator="\n"
          let threadLocks = List.intRange(getConfigInt(NUM_PROC)) |> tt => createLockByLockName('threadLock<%tt%>', "", type); separator="\n"
          <<
          <%eqsFuncs%>

          <%functionHead%>
          {
            <%generateMeasureTimeStartCode("measuredFunctionStartValues", "evaluateODE", "MEASURETIME_MODELFUNCTIONS")%>
            this->_command = command;
            //_evaluateBarrier.wait(); //start calculation
            <%mainThreadCode%>
            //_evaluateBarrier.wait(); //calculation finished

            <%generateStateVarPrefetchCode(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace)%>
            <%generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "measureTimeFunctionsArray[0]", "evaluateODE", "MEASURETIME_MODELFUNCTIONS")%>
          }
          >>
        else ""
      end match
   case SOME(odeSchedule as THREADSCHEDULE(__)) then
      match type
        case ("openmp") then
          let taskEqs = function_HPCOM_Thread(allEquationsPlusWhen,odeSchedule.threadTasks, type, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
          <<
          //using type: <%type%>
          <%functionHead%>
          {
            <%&varDecls%>
            <%taskEqs%>
          }
          >>
        case ("mpi") then
          <<
          //using type: <%type%> and threadscheduling
          <%functionHead%>
          {
            // MFlehmig: Todo
          }
          >>
        else
          let &mainThreadCode = buffer "" /*BUFD*/
          let threadFuncs = List.intRange(arrayLength(odeSchedule.threadTasks)) |> threadIdx => generateThreadFunc(allEquationsPlusWhen, arrayGet(odeSchedule.threadTasks, threadIdx), type, intSub(threadIdx, 1), modelNamePrefixStr, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, &mainThreadCode, useFlatArrayNotation); separator="\n"
          let threadAssignLocks1 = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => assignLockByLockName(i0, "th_lock1", type); separator="\n"
          let threadReleaseLocks = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => releaseLockByLockName(i0, "th_lock", type); separator="\n"
          <<
          <%threadFuncs%>

          //using type: <%type%>
          <%functionHead%>
          {
            this->command = command;
            <%threadReleaseLocks%>
            <%mainThreadCode%>
            <%threadAssignLocks1%>
          }
          >>
      end match
    case SOME(odeSchedule as TASKDEPSCHEDULE(__)) then
      match type
        case ("openmp") then
          let taskEqs = function_HPCOM_TaskDep(odeSchedule.tasks, allEquationsPlusWhen, type, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
          <<
          //using type: <%type%>
          <%functionHead%>
          {
            omp_set_dynamic(1);
            <%&varDecls%>
            <%taskEqs%>
          }
          >>
        case ("tbb") then

          let taskFuncs = function_HPCOM_TaskDep_voidfunc(odeSchedule.tasks, allEquationsPlusWhen,type, name, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
          <<
          //using type: <%type%>
          //void functions for functionhandling in tbb_nodes
          <%taskFuncs%>

          <%functionHead%>
          {
            //Start
            _tbbStartNode.try_put(tbb::flow::continue_msg());
            _tbbGraph.wait_for_all();
            //End
          }
          >>
        else ""
      end match
    else ""
end generateParallelEvaluateOde;

template generateStateVarPrefetchCode(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace)
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(vars = vars as SIMVARS(__))) then
      <<
      <%(List.intRange3(0, 8, intSub(listLength(vars.stateVars), 1)) |> index =>
      'PREFETCH(&__z[<%index%>], 0, 3);'
       ;separator="\n")%>
      >>
    else ''
  end match
end generateStateVarPrefetchCode;

template generateLevelCodeForLevel(list<SimEqSystem> allEquationsPlusWhen, TaskList tasksOfLevel, String iType, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  match(tasksOfLevel)
    case(PARALLELTASKLIST(__)) then
      let odeEqs = tasks |> task => generateLevelCodeForTask(allEquationsPlusWhen,task,iType, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
      <<
      #pragma omp sections
      {
        <%odeEqs%>
      }
      >>
    case(SERIALTASKLIST(__)) then
      let odeEqs = tasks |> task => generateLevelCodeForTask(allEquationsPlusWhen,task,iType, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
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
  end match
end generateLevelCodeForLevel;

template generateLevelCodeForTask(list<SimEqSystem> allEquationsPlusWhen, Task iTask, String iType, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  <<
  #pragma omp section
  {
    <%function_HPCOM_Task(allEquationsPlusWhen,iTask,iType, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation)%>
  }
  >>
end generateLevelCodeForTask;

template generateLevelFixedCodeForThread(list<SimEqSystem> allEquationsPlusWhen, list<list<HpcOmSimCode.Task>> tasksOfLevels, Integer iThreadIdx, String iType, Text &varDecls, Absyn.Path name, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text &mainThreadCode, Boolean useFlatArrayNotation)
::=
  let odeEqs = tasksOfLevels |> tasks hasindex levelIdx => generateLevelFixedCodeForThreadLevel(allEquationsPlusWhen, tasks, iThreadIdx, iType, levelIdx, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
  if (intGt(iThreadIdx, 0)) then
  <<
  void <%lastIdentOfPath(name)%>::evaluateThreadFunc<%iThreadIdx%>()
  {
    <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
    <<
    MeasureTimeValues *valuesStart = MeasureTime::getZeroValues();
    MeasureTimeValues *valuesEnd = MeasureTime::getZeroValues();
    >>%>

    while(!_simulationFinished)
    {
        //_evaluateBarrier.wait();
        _levelBarrier.wait();
        if(_simulationFinished)
        {
            //_evaluateBarrier.wait();
            _levelBarrier.wait();
            break;
        }
        <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then '<%generateMeasureTimeStartCode("valuesStart", 'evaluateODEThread<%iThreadIdx%>', "MEASURETIME_MODELFUNCTIONS")%>'%>
        <%odeEqs%>

        <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
        <<
        //MeasureTime::getTimeValuesEnd(valuesEnd);
        //valuesEnd->sub(valuesStart);
        //valuesEnd->sub(MeasureTime::getOverhead());

        //_measureTimeArrayLock.lock();
        //measureTimeArrayHpcom[0].sumMeasuredValues->add(valuesEnd);
        //_measureTimeArrayLock.unlock();
        <%generateMeasureTimeEndCode("valuesStart", "valuesEnd", 'measureTimeArrayHpcom[<%iThreadIdx%>]', 'evaluateODEThread<%iThreadIdx%>', "MEASURETIME_MODELFUNCTIONS")%>
        >>%>

        //_evaluateBarrier.wait();
        _levelBarrier.wait();
    }
    <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
    <<
    delete valuesStart;
    delete valuesEnd;
    >>%>
  }
  >>
  else
    let &mainThreadCode +=
    '
    _levelBarrier.wait();
    <%odeEqs%>
    _levelBarrier.wait();
    '
    <<

    >>
end generateLevelFixedCodeForThread;

template generateLevelFixedCodeForThreadLevel(list<SimEqSystem> allEquationsPlusWhen, list<HpcOmSimCode.Task> tasksOfLevel,
                                              Integer iThreadIdx, String iType, Integer iLevelIdx, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  let tasks = tasksOfLevel |> t => function_HPCOM_Task(allEquationsPlusWhen, t, iType, varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
  <<
  //Start of Level
  <%if intEq(iThreadIdx, 0) then
    <<
    <%generateMeasureTimeStartCode("measuredSchedulerStartValues", 'evaluateODE_level_<%intAdd(iLevelIdx,1)%>', "MEASURETIME_MODELFUNCTIONS")%>
    >>
  %>

  <%if(stringEq(tasks,"")) then '' else ''%>
  <%tasks%>
  _levelBarrier.wait();

  <%if intEq(iThreadIdx, 0) then
    <<
    <%generateMeasureTimeEndCode("measuredSchedulerStartValues", "measuredSchedulerEndValues", 'measureTimeSchedulerArrayHpcom[<%iLevelIdx%>]', 'evaluateODE_level_<%intAdd(iLevelIdx,1)%>', "MEASURETIME_MODELFUNCTIONS")%>
    >>
  %>
  //End of Level
  >>
end generateLevelFixedCodeForThreadLevel;

template function_HPCOM_TaskDep(list<tuple<Task,list<Integer>>> tasks, list<SimEqSystem> allEquationsPlusWhen, String iType,
                                Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  let odeEqs = tasks |> t => function_HPCOM_TaskDep0(t,allEquationsPlusWhen, iType, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
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

template function_HPCOM_TaskDep0(tuple<Task,list<Integer>> taskIn, list<SimEqSystem> allEquationsPlusWhen, String iType, Text &varDecls,
                                 SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  match taskIn
    case ((task as CALCTASK(__),parents)) then
      let taskEqs = function_HPCOM_Task(allEquationsPlusWhen,task,iType,&varDecls,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace,useFlatArrayNotation); separator="\n"
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
  end match
end function_HPCOM_TaskDep0;

template generateTbbConstructorExtension(list<tuple<Task,list<Integer>>> tasks, String modelNamePrefixStr)
::=
  let nodesAndEdges = tasks |> t hasindex i fromindex 0 => generateTbbConstructorExtensionNodesAndEdges(t,i,modelNamePrefixStr); separator="\n"
  <<
  tbb::flow::continue_node<tbb::flow::continue_msg> *tbb_task;
  <%nodesAndEdges%>
  >>
end generateTbbConstructorExtension;

template generateTbbConstructorExtensionNodesAndEdges(tuple<Task,list<Integer>> taskIn, Integer taskIndex, String modelNamePrefixStr)
::=
  match taskIn
    case ((task as CALCTASK(__),parents)) then
      let parentEdges = parents |> p => 'tbb::flow::make_edge(*(_tbbNodeList.at(<%intSub(p,1)%>)),*(_tbbNodeList.at(<%taskIndex%>)));'; separator = "\n"
      let startNodeEdge = if intEq(0, listLength(parents)) then 'tbb::flow::make_edge(_tbbStartNode,*(_tbbNodeList.at(<%taskIndex%>)));' else ""
      <<
      tbb_task = new tbb::flow::continue_node<tbb::flow::continue_msg>(_tbbGraph,VoidFunctionBody(boost::bind<void>(&<%modelNamePrefixStr%>::task_func_<%task.index%>,this)));
      _tbbNodeList.at(<%taskIndex%>) = tbb_task;
      <%parentEdges%>
      <%startNodeEdge%>
      >>
  end match
end generateTbbConstructorExtensionNodesAndEdges;

template function_HPCOM_TaskDep_voidfunc(list<tuple<Task,list<Integer>>> tasks, list<SimEqSystem> allEquationsPlusWhen,
                                         String iType, Absyn.Path name, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  let funcTasks = tasks |> t => function_HPCOM_TaskDep_voidfunc0(t,allEquationsPlusWhen,iType, name, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
  <<
  <%funcTasks%>
  >>
end function_HPCOM_TaskDep_voidfunc;

template function_HPCOM_TaskDep_voidfunc0(tuple<Task,list<Integer>> taskIn, list<SimEqSystem> allEquationsPlusWhen, String iType, Absyn.Path name, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  match taskIn
    case ((task as CALCTASK(__),parents)) then
      let &tempvarDecl = buffer "" /*BUFD*/
      let taskEqs = function_HPCOM_Task(allEquationsPlusWhen,task,iType,&tempvarDecl,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace,useFlatArrayNotation); separator="\n"
      <<
      void <%lastIdentOfPath(name)%>::task_func_<%task.index%>()
      {
        <%tempvarDecl%>
        <%taskEqs%>
      }
      >>
  end match
end function_HPCOM_TaskDep_voidfunc0;

template function_HPCOM_Thread(list<SimEqSystem> allEquationsPlusWhen, array<list<Task>> threadTasks, String iType, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  match iType
    case ("openmp") then
      let odeEqs = arrayList(threadTasks) |> tt hasindex i0 => function_HPCOM_Thread0(allEquationsPlusWhen,tt,i0,iType,&varDecls,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
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
        function_HPCOM_Thread0(allEquationsPlusWhen, tt, i0, iType, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
      <<
      int world_rank;
      MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
      <%odeEqs%>
      >>
    else
      let odeEqs = arrayList(threadTasks) |> tt hasindex i0 => function_HPCOM_Thread0(allEquationsPlusWhen,tt,i0,iType,&varDecls,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
      <<
      <%odeEqs%>
      >>
  end match
end function_HPCOM_Thread;

template generateThreadFunc(list<SimEqSystem> allEquationsPlusWhen, list<Task> threadTasks, String iType, Integer iThreadIdx, String modelNamePrefixStr, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text& mainThreadCode, Boolean useFlatArrayNotation)
::=
  let &varDeclsLoc = buffer "" /*BUFD*/
  let taskEqs = function_HPCOM_Thread0(allEquationsPlusWhen, threadTasks, iThreadIdx, iType, &varDeclsLoc, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
  let assLock = assignLockByLockName(iThreadIdx, "th_lock", iType); separator="\n"
  let relLock = releaseLockByLockName(iThreadIdx, "th_lock1", iType); separator="\n"
  if (intGt(iThreadIdx, 0)) then
    <<
    void <%modelNamePrefixStr%>::evaluateThreadFunc<%iThreadIdx%>()
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
  else
    let &mainThreadCode += &varDeclsLoc
    let &mainThreadCode += taskEqs
    <<
    >>
end generateThreadFunc;

template function_HPCOM_assignThreadLocks(list<Task> iThreadTasks, String iLockPrefix, Integer iThreadNum, String iType)
::=
  let lockAssign = iThreadTasks |> tt => '<%(
    match(tt)
      case(task as DEPTASK(outgoing=true)) then
        assignLockByDepTask(task, iLockPrefix, iType)
      else ""
    end match)%>'; separator="\n"
  <<
  <%if intNe(iThreadNum, 0) then 'else ' else ''%>if(threadNum == <%iThreadNum%>)
  {
    <%lockAssign%>
  }
  >>
end function_HPCOM_assignThreadLocks;

template function_HPCOM_releaseThreadLocks(list<Task> iThreadTasks, String iLockPrefix, Integer iThreadNum, String iType)
::=
  let lockAssign = iThreadTasks |> tt => '<%(
    match(tt)
      case(DEPTASK(outgoing=false)) then
        releaseLockByDepTask(tt, iLockPrefix, iType)
      else ""
    end match)%>'; separator="\n"
  <<
  <%if intNe(iThreadNum, 0) then 'else ' else ''%>if(threadNum == <%iThreadNum%>)
  {
    <%lockAssign%>
  }
  >>
end function_HPCOM_releaseThreadLocks;

template function_HPCOM_Thread0(list<SimEqSystem> allEquationsPlusWhen, list<Task> threadTaskList, Integer iThreadNum,
                                String iType, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  let threadTasks = threadTaskList |> tt => function_HPCOM_Task(allEquationsPlusWhen,tt,iType,&varDecls,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace,useFlatArrayNotation); separator="\n"
  match iType
    case ("openmp") then
      <<
      <%if intNe(iThreadNum, 0) then 'else ' else ''%>if(threadNum == <%iThreadNum%>)
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
  end match
end function_HPCOM_Thread0;

template function_HPCOM_Task(list<SimEqSystem> allEquationsPlusWhen, Task iTask, String iType, Text &varDecls,
                             SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  match iTask
    case (task as CALCTASK(__)) then
      let odeEqs = task.eqIdc |> eq => equationNamesHPCOM_(eq,allEquationsPlusWhen,contextSimulationNonDiscrete,&varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
      let &varDeclsLocal = buffer "" /*BUFL*/
      <<
      // Task <%task.index%>
      <%odeEqs%>
      // End Task <%task.index%>
      >>
    case (task as CALCTASK_LEVEL(__)) then
      let odeEqs = task.eqIdc |> eq => equationNamesHPCOM_(eq,allEquationsPlusWhen,contextSimulationNonDiscrete,&varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
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
  end match
end function_HPCOM_Task;

template equationNamesHPCOM_(Integer idx, list<SimEqSystem> allEquationsPlusWhen, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  let eq = equationHPCOM_(getSimCodeEqByIndex(allEquationsPlusWhen, idx), idx, context, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation)
  <<
  <%eq%>
  >>
end equationNamesHPCOM_;

template equationHPCOM_(SimEqSystem eq, Integer idx, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  equation_function_call(eq, context, &varDecls /*BUFC*/, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, "evaluate")
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
  end match
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
  end match
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
  end match
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
      <%lockPrefix%>_<%lockName%> = new alignedLock();
      >>
    case ("pthreads_spin") then
      <<
      <%lockPrefix%>_<%lockName%> = new alignedSpinlock();
      >>
  end match
end initializeLockByLockName;

template initializeBarrierByName(String lockName, String lockPrefix, Integer numberOfThreads, String iType)
::=
  match iType
    case ("pthreads")
    case ("pthreads_spin") then
      <<
      <%lockPrefix%>_<%lockName%>(<%numberOfThreads%>)
      >>
  end match
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
      alignedLock* <%lockPrefix%>_<%lockName%>;
      >>
    case ("pthreads_spin") then
      <<
      alignedSpinlock* <%lockPrefix%>_<%lockName%>;
      >>
  end match
end createLockByLockName;

template createBarrierByName(String lockName, String lockPrefix, Integer numOfThreads, String iType)
::=
  match iType
    case ("pthreads")
    case ("pthreads_spin") then
      <<
      busywaiting_barrier <%lockPrefix%>_<%lockName%>;
      >>
  end match
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
    case ("pthreads")
    case ("pthreads_spin") then
      <<
      delete <%lockPrefix%>_<%lockName%>;
      >>
    else
      <<
      >>
  end match
end destroyLockByLockName;

template assignLockByDepTask(Task depTask, String lockPrefix, String iType)
::=
  match(depTask)
    case(DEPTASK(__)) then
      let lockName = getLockNameByDepTask(depTask)
      //let commInfoStr = printCommunicationInfoVariables(depTask.communicationInfo)
      <<
      <%assignLockByLockName(lockName, lockPrefix, iType)%>
      >>
  end match
end assignLockByDepTask;

template printCommunicationInfoVariables(CommunicationInfo commInfo)
::=
  ""
  /*
  match(commInfo)
    case(COMMUNICATION_INFO(__)) then
      let floatVarsStr = floatVars |> v => '<%CodegenCpp.MemberVariableDefine2(v, "", false, true)%>' ;separator="\n"
      let intVarsStr = intVars |> v => '<%CodegenCpp.MemberVariableDefine2(v, "", false, true)%>' ;separator="\n"
      let boolVarsStr = boolVars |> v => '<%CodegenCpp.MemberVariableDefine2(v, "", false, true)%>' ;separator="\n"
      <<
      <%floatVarsStr%>
      >>
    else
      <<
      //unsupported communcation info
      >>
  end match
  */
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
      <%lockPrefix%>_<%lockName%>->lock();
      >>
    case ("pthreads_spin") then
      <<
      <%lockPrefix%>_<%lockName%>->lock();
      >>
  end match
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
      <%lockPrefix%>_<%lockName%>->unlock();
      >>
    case ("pthreads_spin") then
      <<
      <%lockPrefix%>_<%lockName%>->unlock();
      >>
  end match
end releaseLockByLockName;


template MPIFinalize()
 "Finalize the MPI environment in main function."
::=
  <<
  } // End sequential
  MPI_Finalize();
  >>
end MPIFinalize;

template MPIInit()
 "Initialize the MPI environment in main function."
::=
  <<
  char** argvNotConst = const_cast<char**>(argv);
  MPI_Init(&argc, &argvNotConst);
  int world_rank, world_size;
  MPI_Comm_size(MPI_COMM_WORLD, &world_size);
  MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
  std::cout << "Hello world! This is MPI process " << world_rank
            << " of " << world_size << " processes."  << endl;

  // Run simulation in sequential
  if (0 == world_rank) {
    std::cout << "Remark: Simulation is not (yet) MPI parallel!\n";
  >>
end MPIInit;

template MPIRunCommandInRunScript(String type, Text &getNumOfProcs, Text &execCommandLinux)
 "If MPI is used:
    - Add the run execution command 'mpirun -np $NPROCESSORS',
    - number of MPI processors can be passed as command line argument to simulation
      run script."
::=
  match type
    case "mpi" then
      let &execCommandLinux += "mpirun -np ${NPROCESSORS}"
      let &getNumOfProcs += "\nif [ $# -gt 0 ]; then\n  NPROCESSORS=$1\n shift \nelse\n  NPROCESSORS=1\nfi\n\n"
      ""
    else
      let &execCommandLinux += "exec"
      ""
  end match
end MPIRunCommandInRunScript;

template simulationMainRunScript(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace)
 "Generates code for header file for simulation target."
::=
  let type = if Flags.isSet(Flags.USEMPI) then "mpi" else ''
  let &preRunCommandLinux = buffer ""
  let &execCommandLinux = buffer ""
  let _ = MPIRunCommandInRunScript(type, &preRunCommandLinux, &execCommandLinux)
  let preRunCommandWindows = ""

  CodegenCpp.simulationMainRunScript(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, preRunCommandLinux, preRunCommandWindows, execCommandLinux)
end simulationMainRunScript;

template simulationMakefile(String target, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace)
 "Adds specific compiler flags for HPCOM mode to simulation makefile."
::=
  let type = getConfigString(HPCOM_CODE)

  let &additionalCFlags_GCC = buffer ""
  let &additionalCFlags_GCC += if stringEq(type,"openmp") then " -fopenmp" else ""
  let &additionalCFlags_GCC += if stringEq(type,"tbb") then ' -I"$(INTEL_TBB_INCLUDE)"' else ""

  let &additionalCFlags_MSVC = buffer ""
  let &additionalCFlags_MSVC += if stringEq(type,"openmp") then "/openmp" else ""

  let &additionalLinkerFlags_GCC = buffer ""
  let &additionalLinkerFlags_GCC += if stringEq(type,"tbb") then " $(INTEL_TBB_LIBRARIES) " else ""
  let &additionalLinkerFlags_GCC += if stringEq(type,"openmp") then " -fopenmp" else ""

  let &additionalLinkerFlags_MSVC = buffer ""

  CodegenCpp.simulationMakefile(target, simCode, extraFuncs ,extraFuncsDecl, extraFuncsNamespace, additionalLinkerFlags_GCC,
                                additionalCFlags_MSVC, additionalCFlags_GCC,
                                additionalLinkerFlags_MSVC, Flags.isSet(Flags.USEMPI))
end simulationMakefile;

template getPreVarsCount(ModelInfo modelInfo, Option<MemoryMap> hpcOmMemoryOpt)
::=
  match(hpcOmMemoryOpt)
    case(SOME(hpcomMemory as MEMORYMAP_ARRAY(floatArraySize=floatArraySize,intArraySize=intArraySize,boolArraySize=boolArraySize))) then
      '<%floatArraySize%> + <%intArraySize%> + <%boolArraySize%>'
    else
      CodegenCpp.getPreVarsCount(modelInfo)
end getPreVarsCount;

template numRealvars(ModelInfo modelInfo, Option<MemoryMap> hpcOmMemoryOpt)
::=
  match(hpcOmMemoryOpt)
    case(SOME(hpcomMemory as MEMORYMAP_ARRAY(floatArraySize=floatArraySize))) then
      '<%floatArraySize%>'
    else
      '<%CodegenCpp.numRealvars(modelInfo)%>'
end numRealvars;

template numIntvars(ModelInfo modelInfo, Option<MemoryMap> hpcOmMemoryOpt)
::=
  match(hpcOmMemoryOpt)
    case(SOME(hpcomMemory as MEMORYMAP_ARRAY(intArraySize=intArraySize))) then
      '<%intArraySize%>'
    else
      CodegenCpp.numIntvars(modelInfo)
end numIntvars;

template numBoolvars(ModelInfo modelInfo, Option<MemoryMap> hpcOmMemoryOpt)
::=
  match(hpcOmMemoryOpt)
    case(SOME(hpcomMemory as MEMORYMAP_ARRAY(boolArraySize=boolArraySize))) then
      '<%boolArraySize%>'
    else
      CodegenCpp.numBoolvars(modelInfo)
end numBoolvars;

annotation(__OpenModelica_Interface="backend");
end CodegenCppHpcom;
