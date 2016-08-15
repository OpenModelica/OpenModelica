// This file defines template-extensions for transforming Modelica code into parallel hpcom-code.
//
// There are one root template intended to be called from the code generator:
// translateModel. These template do not return any
// result but instead write the result to files. All other templates return
// text and are used by the root templates (most of them indirectly).

package CodegenCppHpcom

import interface SimCodeBackendTV;
import interface SimCodeTV;
import CodegenUtil.*;
import CodegenCppCommon.*;
import CodegenCppInit.*;
import CodegenCpp.*; //unqualified import, no need the CodegenC is optional when calling a template; or mandatory when the same named template exists in this package (name hiding)



template translateModel(SimCode simCode)
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__), makefileParams = MAKEFILE_PARAMS(__), hpcomData = HPCOMDATA(__)) then
      let target  = simulationCodeTarget()
      let &extraFuncs = buffer "" /*BUFD*/
      let &extraFuncsDecl = buffer "" /*BUFD*/
	  let &extraResidualsFuncsDecl = buffer "" /*BUFD*/
      let &dummyTypeElemCreation = buffer "" //remove this workaround if GCC > 4.4 is the default compiler
      let stateDerVectorName = "__zDot"
      let useMemoryOptimization = Flags.isSet(Flags.HPCOM_MEMORY_OPT)

      let className = lastIdentOfPath(modelInfo.name)
      let numRealVars = numRealvarsHpcom(modelInfo, hpcomData.hpcOmMemory)
      let numIntVars = numIntvarsHpcom(modelInfo, hpcomData.hpcOmMemory)
      let numBoolVars = numBoolvarsHpcom(modelInfo, hpcomData.hpcOmMemory)
      let numStringVars = numStringvars(modelInfo)
      let numPreVars = numPreVarsHpcom(modelInfo, hpcomData.hpcOmMemory)

      let() = textFile(simulationMainFile(target, simCode, &extraFuncs, &extraFuncsDecl, "",
                                          (if Flags.isSet(USEMPI) then "#include <mpi.h>" else ""),
                                          (if Flags.isSet(USEMPI) then mpiInit() else ""),
                                          (if Flags.isSet(USEMPI) then mpiFinalize() else ""),
                                          numRealVars, numIntVars, numBoolVars, numStringVars, numPreVars),
                                          'OMCpp<%fileNamePrefix%>Main.cpp')
      let() = textFile(simulationCppFile(simCode, contextOther, updateHpcom(allEquations, simCode, &extraFuncs, &extraFuncsDecl, "", contextOther, stateDerVectorName, false),
                                         '<%numRealVars%>-1', '<%numIntVars%>-1', '<%numBoolVars%>-1', '<%numStringVars%>-1', &extraFuncs, &extraFuncsDecl, className,
                                         additionalHpcomConstructorDefinitions(hpcomData.schedules),
                                         additionalHpcomConstructorBodyStatements(hpcomData.schedules, className, dotPath(modelInfo.name)),
                                         additionalHpcomDestructorBodyStatements(hpcomData.schedules),
                                         stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>.cpp')

      let() = textFile(simulationHeaderFile(simCode ,contextOther, &extraFuncs, &extraFuncsDecl, "",
                      additionalHpcomIncludes(simCode, &extraFuncs, &extraFuncsDecl, className, false),
                      "",
                      additionalHpcomProtectedMemberDeclaration(simCode, &extraFuncs, &extraFuncsDecl, "", false),
                      memberVariableDefine(modelInfo, varToArrayIndexMapping, '<%numRealVars%>-1', '<%numIntVars%>-1', '<%numBoolVars%>-1', '<%numStringVars%>-1', Flags.isSet(Flags.GEN_DEBUG_SYMBOLS), false),
                      memberVariableDefinePreVariables(modelInfo, varToArrayIndexMapping, '<%numRealVars%>-1', '<%numIntVars%>-1', '<%numBoolVars%>-1', '<%numStringVars%>-1', Flags.isSet(Flags.GEN_DEBUG_SYMBOLS), false), false),
                      //CodegenCpp.MemberVariablePreVariables(modelInfo,false), false),
                      'OMCpp<%fileNamePrefix%>.h')

      let() = textFile(simulationTypesHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, "", &dummyTypeElemCreation, modelInfo.functions, literals,stateDerVectorName,false), 'OMCpp<%fileNamePrefix%>Types.h')
      let() = textFile(simulationMakefile(target,simCode, &extraFuncs, &extraFuncsDecl, ""), '<%fileNamePrefix%>.makefile')

      let &extraFuncsFun = buffer "" /*BUFD*/
      let &extraFuncsDeclFun = buffer "" /*BUFD*/
      let() = textFile(simulationFunctionsHeaderFile(simCode, &extraFuncsFun, &extraFuncsDeclFun, "",modelInfo.functions, literals,stateDerVectorName,false), 'OMCpp<%fileNamePrefix%>Functions.h')
      let() = textFile(simulationFunctionsFile(simCode, &extraFuncsFun, &extraFuncsDeclFun, "", modelInfo.functions, literals,externalFunctionIncludes,stateDerVectorName,false), 'OMCpp<%fileNamePrefix%>Functions.cpp')
      let &extraFuncsInit = buffer "" /*BUFD*/
      let &extraFuncsDeclInit = buffer "" /*BUFD*/
      let &complexStartExpressions = buffer ""
      let() = textFile(modelInitXMLFile(simCode, numRealVars, numIntVars, numBoolVars, numStringVars, "", "", "", false, "", complexStartExpressions, stateDerVectorName),'<%fileNamePrefix%>_init.xml')
      let() = textFile(simulationInitCppFile(simCode ,&extraFuncsInit, &extraFuncsDeclInit, "", dummyTypeElemCreation, stateDerVectorName, false, complexStartExpressions), 'OMCpp<%fileNamePrefix%>Initialize.cpp')

      let _ = match boolOr(Flags.isSet(Flags.HARDCODED_START_VALUES), Flags.isSet(Flags.GEN_DEBUG_SYMBOLS))
        case true then
          let()= textFile(simulationInitParameterCppFile(simCode, &extraFuncsInit, &extraFuncsDeclInit, '<%className%>Initialize', stateDerVectorName, false),'OMCpp<%fileNamePrefix%>InitializeParameter.cpp')
          let()= textFile(simulationInitAliasVarsCppFile(simCode, &extraFuncsInit, &extraFuncsDeclInit, '<%className%>Initialize', stateDerVectorName, false),'OMCpp<%fileNamePrefix%>InitializeAliasVars.cpp')
          let()= textFile(simulationInitAlgVarsCppFile(simCode , &extraFuncsInit , &extraFuncsDeclInit, '<%className%>Initialize', stateDerVectorName, false),'OMCpp<%fileNamePrefix%>InitializeAlgVars.cpp')
          ""
        else
          ""

      let()= textFile(simulationInitExtVarsCppFile(simCode, &extraFuncsInit, &extraFuncsDeclInit, '<%className%>Initialize', stateDerVectorName, false),'OMCpp<%fileNamePrefix%>InitializeExtVars.cpp')
      let() = textFile(simulationInitHeaderFile(simCode, &extraFuncsInit, &extraFuncsDeclInit, ""), 'OMCpp<%fileNamePrefix%>Initialize.h')

      let &jacobianVarsInit = buffer "" /*BUFD*/
      let() = textFile(simulationJacobianHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, "", &jacobianVarsInit, Flags.isSet(Flags.GEN_DEBUG_SYMBOLS)), 'OMCpp<%fileNamePrefix%>Jacobian.h')
      let() = textFile(simulationJacobianCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", &jacobianVarsInit, stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>Jacobian.cpp')
      let() = textFile(simulationStateSelectionCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>StateSelection.cpp')
      let() = textFile(simulationStateSelectionHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>StateSelection.h')

      let()= textFile(simulationMixedSystemCppFile(simCode ,updateResiduals(simCode,extraFuncs,extraResidualsFuncsDecl,className,stateDerVectorName /*=__zDot*/, false)
                   	                               , &extraFuncs , &extraFuncsDecl, "", stateDerVectorName, false),'OMCpp<%fileNamePrefix%>Mixed.cpp')
	  let() = textFile(simulationMixedSystemHeaderFile(simCode, &extraFuncs, &extraResidualsFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>Mixed.h')
      let() = textFile(simulationWriteOutputHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>WriteOutput.h')
      let() = textFile(simulationWriteOutputCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>WriteOutput.cpp')
      let() = textFile(simulationFactoryFile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>FactoryExport.cpp')

      let() = textFile(simulationMainRunScript(simCode, &extraFuncs, &extraFuncsDecl, ""), '<%fileNamePrefix%><%simulationMainRunScriptSuffix(simCode, &extraFuncs, &extraFuncsDecl, "")%>')
      let jac =  (jacobianMatrixes |> (mat, _,_, _, _, _,_) =>
          (mat |> (eqs,_,_) =>  algloopfiles(eqs,simCode, &extraFuncs, &extraFuncsDecl, "",contextAlgloopJacobian, stateDerVectorName, false) ;separator="")
          ;separator="")
      let alg = algloopfiles(listAppend(allEquations,initialEquations), simCode, &extraFuncs, &extraFuncsDecl, "", contextAlgloop, stateDerVectorName, false)
      let() = textFile(algloopMainfile(listAppend(allEquations,initialEquations), simCode, &extraFuncs, &extraFuncsDecl, "", contextAlgloop), 'OMCpp<%fileNamePrefix%>AlgLoopMain.cpp')
      let() = textFile(calcHelperMainfile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>CalcHelperMain.cpp')
      ""
      // empty result of the top-level template .., only side effects
  end match
end translateModel;

// HEADER
template additionalHpcomIncludes(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
 "Generates code for header file for simulation target."
::=
  match simCode
    case SIMCODE(__) then
      <<
      <%additionalHpcomIncludesForParallelCode(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace)%>
      >>
  end match
end additionalHpcomIncludes;

template additionalHpcomIncludesForParallelCode(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace)
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
      >>
    case ("tbb") then
      <<
      #include <tbb/tbb.h>
      #include <tbb/flow_graph.h>
      #include <tbb/tbb_stddef.h>
      #include <boost/function.hpp>
      #include <boost/bind.hpp>
      #if TBB_INTERFACE_VERSION >= 8000
      #include <tbb/task_arena.h>
      #endif
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
end additionalHpcomIncludesForParallelCode;

template additionalHpcomProtectedMemberDeclaration(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
 "Generates class declarations."
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__), hpcomData=HPCOMDATA(schedules=schedulesOpt)) then
      let &extraFuncsDecl += generateAdditionalFunctionHeaders(hpcomData.schedules)
      let &extraFuncsDecl += generateAdditionalHpcomVarHeaders(hpcomData.schedules)
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
            #if defined(USE_THREAD)
              #if !defined(USE_CPP_03)
                return std::hash<std::thread::id>()(std::this_thread::get_id());
              #else
                boost::hash<std::string> string_hash;
                return (long unsigned int)string_hash(boost::lexical_cast<std::string>(boost::this_thread::get_id()));
              #endif
            #else
              return 0;
            #endif
            >>
        end match %>
      }
      <% if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
      <<
      std::vector<MeasureTimeData*> *measureTimeArrayHpcom;
      std::vector<MeasureTimeData*> *measureTimeSchedulerArrayHpcom_evaluateODE;
      std::vector<MeasureTimeData*> *measureTimeSchedulerArrayHpcom_evaluateDAE;
      std::vector<MeasureTimeData*> *measureTimeSchedulerArrayHpcom_evaluateZeroFuncs;
      //MeasureTimeValues *measuredStartValuesODE, *measuredEndValuesODE;
      MeasureTimeValues *measuredSchedulerStartValues, *measuredSchedulerEndValues;

      #ifdef MEASURETIME_MODELFUNCTIONS
      std::vector<MeasureTimeData*> *measureTimeThreadArrayOdeHpcom;
      std::vector<MeasureTimeData*> *measureTimeThreadArrayDaeHpcom;
      std::vector<MeasureTimeData*> *measureTimeThreadArrayZeroFuncHpcom;
      <%List.intRange(getConfigInt(NUM_PROC)) |> threadIdx => 'MeasureTimeValues* measuredSchedulerStartValues_<%intSub(threadIdx,1)%>;'; separator="\n"%>
      <%List.intRange(getConfigInt(NUM_PROC)) |> threadIdx => 'MeasureTimeValues* measuredSchedulerEndValues_<%intSub(threadIdx,1)%>;'; separator="\n"%>
      #endif //MEASURETIME_MODELFUNCTIONS
      >>%>
      >>
  end match
end additionalHpcomProtectedMemberDeclaration;

template generateAdditionalStructHeaders(Schedule odeSchedule)
::=
  let type = getConfigString(HPCOM_CODE)
  match odeSchedule
    case TASKDEPSCHEDULE(__) then
      match type
        case ("openmp") then
          <<
          >>
        case ("tbb") then
          <<
          //Required for Intel TBB
          struct VoidFunctionBody {
            function<void(void)> void_function;
            VoidFunctionBody(function<void(void)> void_function) : void_function(void_function) { }
            FORCE_INLINE void operator()( tbb::flow::continue_msg ) const
            {
              void_function();
            }
          };
          #if TBB_INTERFACE_VERSION >= 8000
          struct TbbArenaFunctor
          {
            tbb::flow::graph * g;
            tbb::flow::broadcast_node<tbb::flow::continue_msg> * sn;

            TbbArenaFunctor( )
            {
              g = NULL;
              sn = NULL;
            }

            TbbArenaFunctor( tbb::flow::graph & in_g , tbb::flow::broadcast_node<tbb::flow::continue_msg> & in_sn )
            {
              g = &in_g;
              sn = &in_sn;
            }

            void operator()()
            {
              sn->try_put( tbb::flow::continue_msg() );
              g->wait_for_all();
            }

          };
          #endif
          >>
        else ""
      end match
    else ""
  end match
end generateAdditionalStructHeaders;

template generateAdditionalFunctionHeaders(Option<tuple<Schedule,Schedule,Schedule>> schedulesOpt)
::=
  let type = getConfigString(HPCOM_CODE)
  <<
  FORCE_INLINE void evaluateParallel(const UPDATETYPE command, int evaluateMode);
  <%match schedulesOpt
    case SOME((odeSchedule as THREADSCHEDULE(__),_,_)) then
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
    case SOME((odeSchedule as TASKDEPSCHEDULE(__),daeSchedule as TASKDEPSCHEDULE(__),zeroFuncSchedule as TASKDEPSCHEDULE(__))) then
      match type
        case ("openmp") then
          <<
          >>
        case ("tbb") then
          let voidfuncsOde = odeSchedule.tasks |> task => (
              match task
                case ((task as CALCTASK(__),parents)) then
                  <<
                  void taskFuncOde_<%task.index%>();
                  >>
                else ""
              ); separator="\n"
          let voidfuncsDae = daeSchedule.tasks |> task => (
              match task
                case ((task as CALCTASK(__),parents)) then
                  <<
                  void taskFuncAll_<%task.index%>();
                  >>
                else ""
              ); separator="\n"
          let voidfuncsZeroFunc = zeroFuncSchedule.tasks |> task => (
              match task
                case ((task as CALCTASK(__),parents)) then
                  <<
                  void taskFuncZeroFunc_<%task.index%>();
                  >>
                else ""
              ); separator="\n"
          <<
          <%generateAdditionalStructHeaders(odeSchedule)%>

          <%voidfuncsOde%>
          <%voidfuncsDae%>
          <%voidfuncsZeroFunc%>
          >>
        else ""
      end match
    else ""
  end match%>
  >>
end generateAdditionalFunctionHeaders;

template generateAdditionalHpcomVarHeaders(Option<tuple<Schedule,Schedule,Schedule>> schedulesOpt)
::=
  let type = getConfigString(HPCOM_CODE)
  <<
  UPDATETYPE _command;
  int _evaluateMode;
  <%
  match schedulesOpt
    case SOME((odeSchedule as LEVELSCHEDULE(useFixedAssignments=true),_,_)) then
      match type
        case ("pthreads")
        case ("pthreads_spin") then
          <<
          <%List.intRange(getConfigInt(NUM_PROC)) |> thIdx hasindex i0 fromindex 0 => generateThreadHeaderDecl(i0, type)%>
          <%createBarrierByName("levelBarrier","", getConfigInt(NUM_PROC), type)%>
          <%createLockByLockName("measureTimeArrayLock", "", type)%>
          bool _simulationFinished;
          >>
        else ""
      end match
    case SOME((odeSchedule as THREADSCHEDULE(__),daeSchedule as THREADSCHEDULE(__),zeroFuncSchedule as THREADSCHEDULE(__))) then
      let odeLocks = createLockArrayByName(listLength(odeSchedule.outgoingDepTasks),"_lockOde",type)//odeSchedule.outgoingDepTasks |> task => createLockByDepTask(task, "_lockOde", type); separator="\n"
      let daeLocks = createLockArrayByName(listLength(daeSchedule.outgoingDepTasks),"_lockDae",type)//daeSchedule.outgoingDepTasks |> task => createLockByDepTask(task, "_lockDae", type); separator="\n"
      let zeroFuncLocks = createLockArrayByName(listLength(zeroFuncSchedule.outgoingDepTasks),"_lockZeroFunc",type)//daeSchedule.outgoingDepTasks |> task => createLockByDepTask(task, "_lockDae", type); separator="\n"
      match type
        case ("openmp") then
          let threadDecl = arrayList(odeSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => generateThreadHeaderDecl(i0, type); separator="\n"
          <<
          <%odeLocks%>
          <%daeLocks%>
          <%zeroFuncLocks%>
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
          bool _terminateThreads;
          <%odeLocks%>
          <%daeLocks%>
          <%zeroFuncLocks%>
          <%thLocks%>
          <%thLocks1%>
          <%threadDecl%>
          >>
      end match
    case SOME((odeSchedule as TASKDEPSCHEDULE(__),_,_)) then
      match type
        case ("openmp") then
          << >>
        case ("tbb") then
          <<
          tbb::flow::graph _tbbGraphOde;
          tbb::flow::broadcast_node<tbb::flow::continue_msg> _tbbStartNodeOde;
          tbb::flow::graph _tbbGraphAll;
          tbb::flow::broadcast_node<tbb::flow::continue_msg> _tbbStartNodeAll;
          tbb::flow::graph _tbbGraphZeroFunc;
          tbb::flow::broadcast_node<tbb::flow::continue_msg> _tbbStartNodeZeroFunc;
          std::vector<tbb::flow::continue_node<tbb::flow::continue_msg>* > _tbbNodeListOde;
          std::vector<tbb::flow::continue_node<tbb::flow::continue_msg>* > _tbbNodeListAll;
          std::vector<tbb::flow::continue_node<tbb::flow::continue_msg>* > _tbbNodeListZeroFunc;
          #if TBB_INTERFACE_VERSION >= 8000
          tbb::task_arena _tbbArena;
          TbbArenaFunctor _tbbArenaFunctorOde;
          TbbArenaFunctor _tbbArenaFunctorAll;
          TbbArenaFunctor _tbbArenaFunctorZeroFunc;
          #endif
          >>
        else ""
      end match
    else ""
  end match
  %>
  >>
end generateAdditionalHpcomVarHeaders;

template generateThreadHeaderDecl(Integer threadIdx, String iType)
::=
  match iType
    case ("openmp") then
      <<
      >>
    else
      <<
      thread* evaluateThread<%threadIdx%>;
      >>
  end match
end generateThreadHeaderDecl;

template generateThreadFunctionHeaderDecl(Integer threadIdx)
::=
  <<
  void evaluateThreadFunc<%threadIdx%>();
  >>
end generateThreadFunctionHeaderDecl;

template additionalHpcomConstructorDefinitions(Option<tuple<Schedule,Schedule,Schedule>> scheduleOpt)
::=
  let type = getConfigString(HPCOM_CODE)
  match scheduleOpt
    case SOME((odeSchedule as LEVELSCHEDULE(useFixedAssignments=true),_,_)) then
      match type
        case ("pthreads")
        case ("pthreads_spin") then
          <<
          ,_command(IContinuous::UNDEF_UPDATE)
          ,_simulationFinished(false)
          ,<%initializeBarrierByName("levelBarrier","",getConfigInt(NUM_PROC),type)%>
          >>
        else ""
    case SOME((odeSchedule as TASKDEPSCHEDULE(__),daeSchedule as TASKDEPSCHEDULE(__),zeroFuncSchedule as TASKDEPSCHEDULE(__))) then
      match type
        case ("tbb") then
          <<
          ,_tbbGraphOde()
          ,_tbbGraphAll()
          ,_tbbGraphZeroFunc()
          ,_tbbStartNodeOde(_tbbGraphOde)
          ,_tbbStartNodeAll(_tbbGraphAll)
          ,_tbbStartNodeZeroFunc(_tbbGraphZeroFunc)
          ,_tbbNodeListOde(<%listLength(odeSchedule.tasks)%>,NULL)
          ,_tbbNodeListAll(<%listLength(daeSchedule.tasks)%>,NULL)
          ,_tbbNodeListZeroFunc(<%listLength(zeroFuncSchedule.tasks)%>,NULL)
          >>
        else ""
      end match
    else ""
  end match
end additionalHpcomConstructorDefinitions;

template additionalHpcomConstructorBodyStatements(Option<tuple<Schedule,Schedule,Schedule>> schedulesOpt, String modelNamePrefixStr, String fullModelName)
::=
  let type = getConfigString(HPCOM_CODE)
  let threadMeasureTimeBlocks = if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then generateThreadMeasureTimeDeclaration(fullModelName, getConfigInt(NUM_PROC)) else ""
  let schedulerSpecificReturn = match schedulesOpt
    case SOME((odeSchedule as LEVELSCHEDULE(useFixedAssignments=true),daeSchedule as LEVELSCHEDULE(useFixedAssignments=true),zeroFuncSchedule as LEVELSCHEDULE(useFixedAssignments=true))) then
      match type
        case ("pthreads")
        case ("pthreads_spin") then
          let threadFuncs = List.intRange(intSub(getConfigInt(NUM_PROC),1)) |> tt hasindex i0 fromindex 1 => generateThread(i0, type, modelNamePrefixStr,"evaluateThreadFunc"); separator="\n"
          <<
          <%threadFuncs%>

          <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
            <<
            #ifdef MEASURETIME_MODELFUNCTIONS
            measureTimeSchedulerArrayHpcom_evaluateODE = new std::vector<MeasureTimeData*>(size_t(<%listLength(odeSchedule.tasksOfLevels)%>), NULL);
            MeasureTime::addResultContentBlock("<%fullModelName%>","functions_HPCOM_Sections_ODE",measureTimeSchedulerArrayHpcom_evaluateODE);
            measuredSchedulerStartValues = MeasureTime::getZeroValues();
            measuredSchedulerEndValues = MeasureTime::getZeroValues();
            <%List.intRange(listLength(odeSchedule.tasksOfLevels)) |> levelIdx => '(*measureTimeSchedulerArrayHpcom_evaluateODE)[<%intSub(levelIdx,1)%>] = new MeasureTimeData("evaluateODE_level_<%levelIdx%>");'; separator="\n"%>

            measureTimeSchedulerArrayHpcom_evaluateDAE = new std::vector<MeasureTimeData*>(size_t(<%listLength(daeSchedule.tasksOfLevels)%>), NULL);
            MeasureTime::addResultContentBlock("<%fullModelName%>","functions_HPCOM_Sections_DAE",measureTimeSchedulerArrayHpcom_evaluateDAE);
            measuredSchedulerStartValues = MeasureTime::getZeroValues();
            measuredSchedulerEndValues = MeasureTime::getZeroValues();
            <%List.intRange(listLength(daeSchedule.tasksOfLevels)) |> levelIdx => '(*measureTimeSchedulerArrayHpcom_evaluateDAE)[<%intSub(levelIdx,1)%>] = new MeasureTimeData("evaluateDAE_level_<%levelIdx%>");'; separator="\n"%>

            measureTimeSchedulerArrayHpcom_evaluateZeroFuncs = new std::vector<MeasureTimeData*>(size_t(<%listLength(zeroFuncSchedule.tasksOfLevels)%>), NULL);
            MeasureTime::addResultContentBlock("<%fullModelName%>","functions_HPCOM_Sections_ZeroFuncs",measureTimeSchedulerArrayHpcom_evaluateZeroFuncs);
            measuredSchedulerStartValues = MeasureTime::getZeroValues();
            measuredSchedulerEndValues = MeasureTime::getZeroValues();
            <%List.intRange(listLength(zeroFuncSchedule.tasksOfLevels)) |> levelIdx => '(*measureTimeSchedulerArrayHpcom_evaluateZeroFuncs)[<%intSub(levelIdx,1)%>] = new MeasureTimeData("evaluateZeroFunc_level_<%levelIdx%>");'; separator="\n"%>
            #endif //MEASURETIME_MODELFUNCTIONS
            >>
          %>
          >>
        else ""
      end match
    case SOME((odeSchedule as THREADSCHEDULE(__),daeSchedule as THREADSCHEDULE(__),zeroFuncSchedule as THREADSCHEDULE(__))) then
      let initLocksOde = initializeArrayLocks(listLength(odeSchedule.outgoingDepTasks),"_lockOde",type)//odeSchedule.outgoingDepTasks |> task => initializeLockByDepTask(task, "_lockOde", type); separator="\n"
      let assignLocksOde = assignArrayLocks(listLength(odeSchedule.outgoingDepTasks),"_lockOde",type)//odeSchedule.outgoingDepTasks |> task => assignLockByDepTask(task, "_lockOde", type); separator="\n"
      let initLocksDae = initializeArrayLocks(listLength(daeSchedule.outgoingDepTasks),"_lockDae",type)//daeSchedule.outgoingDepTasks |> task => initializeLockByDepTask(task, "_lockDae", type); separator="\n"
      let assignLocksDae = assignArrayLocks(listLength(daeSchedule.outgoingDepTasks),"_lockDae",type)//daeSchedule.outgoingDepTasks |> task => assignLockByDepTask(task, "_lockDae", type); separator="\n"
      let initLocksZeroFunc = initializeArrayLocks(listLength(zeroFuncSchedule.outgoingDepTasks),"_lockZeroFunc",type)//daeSchedule.outgoingDepTasks |> task => initializeLockByDepTask(task, "_lockDae", type); separator="\n"
      let assignLocksZeroFunc = assignArrayLocks(listLength(zeroFuncSchedule.outgoingDepTasks),"_lockZeroFunc",type)//daeSchedule.outgoingDepTasks |> task => assignLockByDepTask(task, "_lockDae", type); separator="\n"

      match type
        case ("openmp") then
          let threadFuncs = arrayList(odeSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => generateThread(i0, type, modelNamePrefixStr,"evaluateThreadFunc"); separator="\n"
          <<
          omp_set_dynamic(0);
          <%threadFuncs%>
          <%initLocksOde%>
          <%initLocksDae%>
          <%initLocksZeroFunc%>
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
          _terminateThreads = false;
          _command = IContinuous::UNDEF_UPDATE;
          _evaluateMode = -1;

          <%initLocksOde%>
          <%initLocksDae%>
          <%initLocksZeroFunc%>
          <%threadLocksInit%>
          <%threadLocksInit1%>

          <%assignLocksDae%>
          <%assignLocksOde%>
          <%assignLocksZeroFunc%>
          <%threadAssignLocks%>
          <%threadAssignLocks1%>

          <%threadFuncs%>
          >>
    case SOME((odeSchedule as TASKDEPSCHEDULE(__),daeSchedule as TASKDEPSCHEDULE(__),zeroFuncSchedule as TASKDEPSCHEDULE(__))) then
      match type
        case ("tbb") then
          let tbbVars = generateTbbConstructorExtension(odeSchedule.tasks, daeSchedule.tasks, zeroFuncSchedule.tasks, modelNamePrefixStr)
          <<
          <%tbbVars%>
          >>
        else ""
    else ""
  end match
  <<
  <%schedulerSpecificReturn%>
  <%threadMeasureTimeBlocks%>
  >>
end additionalHpcomConstructorBodyStatements;

template generateThreadMeasureTimeDeclaration(String fullModelName, Integer numberOfThreads)
::=
  <<
  #ifdef MEASURETIME_MODELFUNCTIONS
  measureTimeThreadArrayOdeHpcom = new std::vector<MeasureTimeData*>(size_t(<%numberOfThreads%>), NULL);
  measureTimeThreadArrayDaeHpcom = new std::vector<MeasureTimeData*>(size_t(<%numberOfThreads%>), NULL);
  measureTimeThreadArrayZeroFuncHpcom = new std::vector<MeasureTimeData*>(size_t(<%numberOfThreads%>), NULL);
  MeasureTime::addResultContentBlock("<%fullModelName%>","evaluateODE_threads",measureTimeThreadArrayOdeHpcom);
  MeasureTime::addResultContentBlock("<%fullModelName%>","evaluateDAE_threads",measureTimeThreadArrayDaeHpcom);
  MeasureTime::addResultContentBlock("<%fullModelName%>","evaluateZeroFunc_threads",measureTimeThreadArrayZeroFuncHpcom);
  <%List.intRange(numberOfThreads) |> threadIdx => 'measuredSchedulerStartValues_<%intSub(threadIdx,1)%> = MeasureTime::getZeroValues();'; separator="\n"%>
  <%List.intRange(numberOfThreads) |> threadIdx => 'measuredSchedulerEndValues_<%intSub(threadIdx,1)%> = MeasureTime::getZeroValues();'; separator="\n"%>
  <%List.intRange(numberOfThreads) |> threadIdx => '(*measureTimeThreadArrayOdeHpcom)[<%intSub(threadIdx,1)%>] = new MeasureTimeData("evaluateODE_thread_<%threadIdx%>");'; separator="\n"%>
  <%List.intRange(numberOfThreads) |> threadIdx => '(*measureTimeThreadArrayDaeHpcom)[<%intSub(threadIdx,1)%>] = new MeasureTimeData("evaluateDAE_thread_<%threadIdx%>");'; separator="\n"%>
  <%List.intRange(numberOfThreads) |> threadIdx => '(*measureTimeThreadArrayZeroFuncHpcom)[<%intSub(threadIdx,1)%>] = new MeasureTimeData("evaluateZeroFunc_thread_<%threadIdx%>");'; separator="\n"%>
  #endif //MEASURETIME_MODELFUNCTIONS
  >>
end generateThreadMeasureTimeDeclaration;

template initializeArrayLocks(Integer numComms, String lockName, String iType)
::=
match(iType)
  case "openmp" then
  <<
  for(unsigned i=0;i<<%numComms%>;++i)
    omp_init_lock(&<%lockName%>_[i]);
  >>
  case "pthreads" then
  <<
  for(unsigned i=0;i<<%numComms%>;++i)
    <%lockName%>_[i] = new alignedLock();
  >>
  case "pthreads_spin" then
  <<
  for(unsigned i=0;i<<%numComms%>;++i)
    <%lockName%>_[i] = new alignedSpinlock();
  >>
  else
  <<
  //Unsupported parallel instrumentation
  >>
end initializeArrayLocks;

template assignArrayLocks(Integer numComms, String lockName, String iType)
::=
  match iType
    case ("openmp") then
      <<
      for(unsigned i=0;i<<%numComms%>;++i)
        omp_set_lock(&<%lockName%>_[i]);
      >>
    case ("pthreads")
    case ("pthreads_spin") then
      <<
      for(unsigned i=0;i<<%numComms%>;++i)
        <%lockName%>_[i]->lock();
      >>

  else
  <<
  //Unsupported parallel instrumentation
  >>
  end match
end assignArrayLocks;

template createLockArrayByName(Integer numComms, String lockName, String iType)
::=
match(iType)
  case "openmp" then
  <<
  omp_lock_t <%lockName%>_[<%numComms%>];
  >>
  case "pthreads" then
  <<
  alignedLock* <%lockName%>_[<%numComms%>];
  >>
  case "pthreads_spin" then
  <<
  alignedSpinlock* <%lockName%>_[<%numComms%>];
  >>
  else
  <<
  //Unsupported parallel instrumentation
  >>
end createLockArrayByName;

template destroyArrayLocks(Integer numComms, String lockName, String iType)
::=
match(iType)
  case "openmp" then
  <<
  for(unsigned i=0;i<<%numComms%>;++i)
    omp_destroy_lock(&<%lockName%>_[i]);
  >>
  case "pthreads"
  case "pthreads_spin" then
  <<
  for(unsigned i=0;i<<%numComms%>;++i)
    delete <%lockName%>_[i];
  >>
  else
  <<
  //Unsupported parallel instrumentation
  >>
end destroyArrayLocks;

template additionalHpcomDestructorBodyStatements(Option<tuple<Schedule,Schedule,Schedule>> schedulesOpt)
::=
  let type = getConfigString(HPCOM_CODE)

  let schedulerSpecificCode = match schedulesOpt
    case SOME((odeSchedule as LEVELSCHEDULE(useFixedAssignments=true),_,_)) then
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
    case SOME((odeSchedule as THREADSCHEDULE(__),daeSchedule as THREADSCHEDULE(__),zeroFuncSchedule as THREADSCHEDULE(__))) then
      let destroyLocksOde = destroyArrayLocks(listLength(odeSchedule.outgoingDepTasks),"_lockOde",type)//odeSchedule.outgoingDepTasks |> task => destroyLockByDepTask(task, "_lockOde", type); separator="\n"
      let destroyLocksDae = destroyArrayLocks(listLength(daeSchedule.outgoingDepTasks),"_lockDae",type)//daeSchedule.outgoingDepTasks |> task => destroyLockByDepTask(task, "_lockDae", type); separator="\n"
      let destroyLocksZeroFunc = destroyArrayLocks(listLength(zeroFuncSchedule.outgoingDepTasks),"_lockZeroFunc",type)//daeSchedule.outgoingDepTasks |> task => destroyLockByDepTask(task, "_lockDae", type); separator="\n"
      match type
        case ("openmp") then
          <<
          <%destroyLocksOde%>
          <%destroyLocksDae%>
          <%destroyLocksZeroFunc%>
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
          _terminateThreads = true;
          <%threadReleaseLocks%>
          <%joinThreads%>
          <%destroyLocksOde%>
          <%destroyLocksDae%>
          <%destroyLocksZeroFunc%>
          <%threadLocksDel%>
          <%threadLocksDel1%>
          <%destroyThreads%>
          >>
    case SOME((odeSchedule as TASKDEPSCHEDULE(__),_,_)) then
      match type
        case ("tbb") then
          <<
          for(std::vector<tbb::flow::continue_node<tbb::flow::continue_msg>* >::iterator it = _tbbNodeListOde.begin(); it != _tbbNodeListOde.end(); it++)
            delete *it;
          for(std::vector<tbb::flow::continue_node<tbb::flow::continue_msg>* >::iterator it = _tbbNodeListAll.begin(); it != _tbbNodeListAll.end(); it++)
            delete *it;
          for(std::vector<tbb::flow::continue_node<tbb::flow::continue_msg>* >::iterator it = _tbbNodeListZeroFunc.begin(); it != _tbbNodeListZeroFunc.end(); it++)
            delete *it;
          >>
        else ""
    else ""
  end match
  <<
  #ifdef MEASURETIME_MODELFUNCTIONS
  <%List.intRange(getConfigInt(NUM_PROC)) |> threadIdx => 'delete measuredSchedulerStartValues_<%intSub(threadIdx,1)%>;'; separator="\n"%>
  <%List.intRange(getConfigInt(NUM_PROC)) |> threadIdx => 'delete measuredSchedulerEndValues_<%intSub(threadIdx,1)%>;'; separator="\n"%>
  #endif //MEASURETIME_MODELFUNCTIONS
  <%schedulerSpecificCode%>
  >>
end additionalHpcomDestructorBodyStatements;

template updateHpcom(list<SimEqSystem> allEquationsPlusWhen, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/

  match simCode
    case SIMCODE(modelInfo = MODELINFO(__), hpcomData=HPCOMDATA(__)) then
      let &extraFuncsPar = buffer ""
      let parCode = generateParallelEvaluate(allEquationsPlusWhen, modelInfo.name, simCode, extraFuncsPar ,extraFuncsDecl, extraFuncsNamespace, hpcomData.schedules, context, stateDerVectorName, lastIdentOfPath(modelInfo.name), useFlatArrayNotation)
      <<
      <%equationFunctions(allEquations, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextSimulationDiscrete,stateDerVectorName,useFlatArrayNotation,false)%>

      <%createEvaluateConditions(allEquations, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextOther, stateDerVectorName, useFlatArrayNotation)%>

      <%clockedFunctions(getSubPartitions(clockedPartitions), simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, contextSimulationDiscrete, stateDerVectorName, useFlatArrayNotation, boolNot(stringEq(getConfigString(PROFILING_LEVEL), "none")))%>

      <%parCode%>

      <%extraFuncsPar%>
      >>
  end match
end updateHpcom;

template generateParallelEvaluate(list<SimEqSystem> allEquationsPlusWhen, Absyn.Path name,
                 SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Option<tuple<Schedule, Schedule, Schedule>> schedulesOpt, Context context, Text stateDerVectorName /*=__zDot*/,
                 String modelNamePrefixStr, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/
  let measureTimeEvaluateOdeStart = if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then generateMeasureTimeStartCode("measuredFunctionStartValues", "evaluateODE", "MEASURETIME_MODELFUNCTIONS") else ""
  let measureTimeEvaluateOdeEnd = if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "(*measureTimeFunctionsArray)[0]", "evaluateODE", "MEASURETIME_MODELFUNCTIONS") else ""

  let measureTimeEvaluateAllStart = if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then generateMeasureTimeStartCode("measuredFunctionStartValues", "evaluateAll", "MEASURETIME_MODELFUNCTIONS") else ""
  let measureTimeEvaluateAllEnd = if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "(*measureTimeFunctionsArray)[1]", "evaluateAll", "MEASURETIME_MODELFUNCTIONS") else ""

  let measureTimeEvaluateZeroFuncStart = if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then generateMeasureTimeStartCode("measuredFunctionStartValues", "evaluateZeroFuncs", "MEASURETIME_MODELFUNCTIONS") else ""
  let measureTimeEvaluateZeroFuncEnd = if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then generateMeasureTimeEndCode("measuredFunctionStartValues", "measuredFunctionEndValues", "(*measureTimeFunctionsArray)[4]", "evaluateZeroFuncs", "MEASURETIME_MODELFUNCTIONS") else ""

  let type = getConfigString(HPCOM_CODE)

  // Head of function is the same for all schedulers and parallelization methods:
  let functionHead =
  <<
  //using type: <%type%>

  void <%lastIdentOfPath(name)%>::evaluateZeroFuncs(const UPDATETYPE command)
  {
    <%measureTimeEvaluateZeroFuncStart%>
    evaluateParallel(command, 1);
    <%measureTimeEvaluateZeroFuncEnd%>
  }

  bool <%lastIdentOfPath(name)%>::evaluateAll(const UPDATETYPE command)
  {
    <%measureTimeEvaluateAllStart%>

    <%createTimeConditionTreatments(timeEventLength(simCode))%>

    <%varDecls%>

    evaluateParallel(command, -1);
    <%measureTimeEvaluateAllEnd%>

    return _state_var_reinitialized;
  }

  void <%lastIdentOfPath(name)%>::evaluateODE(const UPDATETYPE command)
  {
    <%measureTimeEvaluateOdeStart%>
    evaluateParallel(command, 0);
    <%measureTimeEvaluateOdeEnd%>
  }

  //evaluateMode = 0 : evaluateODE
  //evaluateMode < 0 : evaluateAll
  //evaluateMode > 0 : evaluateZeroFunc
  void <%lastIdentOfPath(name)%>::evaluateParallel(const UPDATETYPE command, int evaluateMode)
  >>

  match schedulesOpt
    case SOME((odeSchedule as EMPTYSCHEDULE(tasks=SERIALTASKLIST(tasks=taskListOde)), daeSchedule as EMPTYSCHEDULE(tasks=SERIALTASKLIST(tasks=taskListDae)), zeroFuncsSchedule as EMPTYSCHEDULE(tasks=SERIALTASKLIST(tasks=taskListZeroFunc)))) then
        <<
        <%functionHead%>
        {
          if(evaluateMode == 0) //evaluate ODE
          {
            <%parallelThreadCodeWithSplit(allEquationsPlusWhen, taskListOde, 1, 1, "", "", &varDecls, simCode, extraFuncs, extraFuncsDecl, lastIdentOfPath(name), "evaluateODE_Th1", useFlatArrayNotation)%>
          }
          else if(evaluateMode < 0) //evaluate All
          {
            <%parallelThreadCodeWithSplit(allEquationsPlusWhen, taskListDae, 1, 1, "", "", &varDecls, simCode, extraFuncs, extraFuncsDecl, lastIdentOfPath(name), "evaluateAll_Th1", useFlatArrayNotation)%>
          }
          else //evaluate ZeroFuncs
          {
            <%parallelThreadCodeWithSplit(allEquationsPlusWhen, taskListZeroFunc, 1, 1, "", "", &varDecls, simCode, extraFuncs, extraFuncsDecl, lastIdentOfPath(name), "evaluateZeroFunc_Th1", useFlatArrayNotation)%>
          }
        }
        >>
    case SOME((odeSchedule as LEVELSCHEDULE(useFixedAssignments=false, tasksOfLevels=tasksOfLevelsOde), daeSchedule as LEVELSCHEDULE(useFixedAssignments=false, tasksOfLevels=tasksOfLevelsDae), zeroFuncSchedule as LEVELSCHEDULE(useFixedAssignments=false, tasksOfLevels=tasksOfLevelsZeroFunc))) then
      let odeEqs = tasksOfLevelsOde |> tasks => generateLevelCodeForLevel(allEquationsPlusWhen, tasks, type, &varDecls, simCode, extraFuncs, extraFuncsDecl, lastIdentOfPath(name), useFlatArrayNotation); separator="\n"
      let daeEqs = tasksOfLevelsDae |> tasks => generateLevelCodeForLevel(allEquationsPlusWhen, tasks, type, &varDecls, simCode, extraFuncs, extraFuncsDecl, lastIdentOfPath(name), useFlatArrayNotation); separator="\n"
      let zeroFuncEqs = tasksOfLevelsZeroFunc |> tasks => generateLevelCodeForLevel(allEquationsPlusWhen, tasks, type, &varDecls, simCode, extraFuncs, extraFuncsDecl, lastIdentOfPath(name), useFlatArrayNotation); separator="\n"

      match type
        case ("openmp") then
          let &extraFuncsDecl +=
          <<
          void evaluateODE_Parallel();
          void evaluateAll_Parallel();
          void evaluateZeroFuncs_Parallel();
          >>

          <<
          void <%lastIdentOfPath(name)%>::evaluateODE_Parallel()
          {
            #pragma omp parallel num_threads(<%getConfigInt(NUM_PROC)%>)
            {
              <%odeEqs%>
            }
          }

          void <%lastIdentOfPath(name)%>::evaluateAll_Parallel()
          {
            #pragma omp parallel num_threads(<%getConfigInt(NUM_PROC)%>)
            {
              <%daeEqs%>
            }
          }

          void <%lastIdentOfPath(name)%>::evaluateZeroFuncs_Parallel()
          {
            #pragma omp parallel num_threads(<%getConfigInt(NUM_PROC)%>)
            {
              <%zeroFuncEqs%>
            }
          }

          <%functionHead%>
          {
            this->_evaluateMode = _evaluateMode;
            this->_command = command;
            if(evaluateMode == 0)
            {
              evaluateODE_Parallel();
            }
            else if(evaluateMode < 0)
            {
              evaluateAll_Parallel();
            }
            else
            {
              evaluateZeroFuncs_Parallel();
            }
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
   case SOME((odeSchedule as LEVELSCHEDULE(useFixedAssignments=true), daeSchedule as LEVELSCHEDULE(useFixedAssignments=true), zeroFuncSchedule as LEVELSCHEDULE(useFixedAssignments=true))) then
      match type
        case ("openmp") then
          let odeEqs = HpcOmScheduler.convertFixedLevelScheduleToLevelThreadLists(odeSchedule, getConfigInt(NUM_PROC)) |> tasks hasindex i0 fromindex 0 => generateLevelFixedCodeForLevel(allEquationsPlusWhen, tasks, type, &varDecls, name, simCode, extraFuncs, extraFuncsDecl, lastIdentOfPath(name), useFlatArrayNotation); separator="\n"
          let daeEqs = HpcOmScheduler.convertFixedLevelScheduleToLevelThreadLists(daeSchedule, getConfigInt(NUM_PROC)) |> tasks hasindex i0 fromindex 0 => generateLevelFixedCodeForLevel(allEquationsPlusWhen, tasks, type, &varDecls, name, simCode, extraFuncs, extraFuncsDecl, lastIdentOfPath(name), useFlatArrayNotation); separator="\n"
          let zeroFuncEqs = HpcOmScheduler.convertFixedLevelScheduleToLevelThreadLists(zeroFuncSchedule, getConfigInt(NUM_PROC)) |> tasks hasindex i0 fromindex 0 => generateLevelFixedCodeForLevel(allEquationsPlusWhen, tasks, type, &varDecls, name, simCode, extraFuncs, extraFuncsDecl, lastIdentOfPath(name), useFlatArrayNotation); separator="\n"

          let &extraFuncsDecl +=
            <<
            void evaluateODE_Parallel();
            void evaluateAll_Parallel();
            void evaluateZeroFuncs_Parallel();
            >>

          <<
          void <%lastIdentOfPath(name)%>::evaluateODE_Parallel()
          {
            #pragma omp parallel num_threads(<%getConfigInt(NUM_PROC)%>)
            {
              int threadNum = getThreadNumber();
              <%odeEqs%>
            }
          }

          void <%lastIdentOfPath(name)%>::evaluateAll_Parallel()
          {
            #pragma omp parallel num_threads(<%getConfigInt(NUM_PROC)%>)
            {
              int threadNum = getThreadNumber();
              <%daeEqs%>
            }
          }

          void <%lastIdentOfPath(name)%>::evaluateZeroFuncs_Parallel()
          {
            #pragma omp parallel num_threads(<%getConfigInt(NUM_PROC)%>)
            {
              int threadNum = getThreadNumber();
              <%zeroFuncEqs%>
            }
          }

          <%functionHead%>
          {
            this->_evaluateMode = _evaluateMode;
            this->_command = command;
            if(evaluateMode == 0)
            {
              evaluateODE_Parallel();
            }
            else if(evaluateMode < 0)
            {
              evaluateAll_Parallel();
            }
            else
            {
              evaluateZeroFuncs_Parallel();
            }
          }
          >>
        case ("pthreads")
        case ("pthreads_spin") then
          let eqsFuncs = arrayList(HpcOmScheduler.convertFixedLevelScheduleToTaskLists(odeSchedule, daeSchedule, zeroFuncSchedule, getConfigInt(NUM_PROC))) |> tasks hasindex i0 fromindex 0 => generateLevelFixedCodeForThread(allEquationsPlusWhen, tasks, i0, type, &varDecls, name, simCode, extraFuncs, extraFuncsDecl, lastIdentOfPath(name), useFlatArrayNotation); separator="\n"
          let threadLocks = List.intRange(getConfigInt(NUM_PROC)) |> tt => createLockByLockName('threadLock<%tt%>', "", type); separator="\n"
          <<
          <%eqsFuncs%>

          <%functionHead%>
          {
            this->_command = command;
            this->_evaluateMode = evaluateMode;

            if(evaluateMode == 0) //evaluate ODE
            {
              _levelBarrier.wait();
              evaluateThreadFuncODE_0();
              _levelBarrier.wait();

              <%generateStateVarPrefetchCode(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace)%>
            }
            else if(evaluateMode < 0) //evaluate All
            {
              _levelBarrier.wait();
              evaluateThreadFuncAll_0();
              _levelBarrier.wait();
            }
            else //evaluate ZeroFuncs
            {
              _levelBarrier.wait();
              evaluateThreadFuncZeroFunc_0();
              _levelBarrier.wait();
            }
          }
          >>
        else
          <<
          <%functionHead%>
          {
            throw std::runtime_error("Type <%type%> is unsupported for levelfix scheduling.");
          }
          >>
      end match
   case SOME((odeSchedule as THREADSCHEDULE(threadTasks=threadTasksOde), daeSchedule as THREADSCHEDULE(threadTasks=threadTasksDae), zeroFuncSchedule as THREADSCHEDULE(threadTasks=threadTasksZeroFunc))) then
      match type
        case ("openmp") then
          let threadAssignLocksOde = arrayList(threadTasksOde) |> tt hasindex i0 fromindex 0 => function_HPCOM_assignThreadLocks(arrayGet(threadTasksOde, intAdd(i0, 1)), "_lockOde", i0, type); separator="\n"
          let threadReleaseLocksOde = arrayList(threadTasksOde) |> tt hasindex i0 fromindex 0 => function_HPCOM_releaseThreadLocks(arrayGet(threadTasksOde, intAdd(i0, 1)), "_lockOde", i0, type); separator="\n"
          let threadAssignLocksDae = arrayList(threadTasksOde) |> tt hasindex i0 fromindex 0 => function_HPCOM_assignThreadLocks(arrayGet(threadTasksDae, intAdd(i0, 1)), "_lockDae", i0, type); separator="\n"
          let threadReleaseLocksDae = arrayList(threadTasksOde) |> tt hasindex i0 fromindex 0 => function_HPCOM_releaseThreadLocks(arrayGet(threadTasksDae, intAdd(i0, 1)), "_lockDae", i0, type); separator="\n"
          let threadAssignLocksZeroFunc = arrayList(threadTasksZeroFunc) |> tt hasindex i0 fromindex 0 => function_HPCOM_assignThreadLocks(arrayGet(threadTasksZeroFunc, intAdd(i0, 1)), "_lockZeroFunc", i0, type); separator="\n"
          let threadReleaseLocksZeroFunc = arrayList(threadTasksZeroFunc) |> tt hasindex i0 fromindex 0 => function_HPCOM_releaseThreadLocks(arrayGet(threadTasksZeroFunc, intAdd(i0, 1)), "_lockZeroFunc", i0, type); separator="\n"

          let odeEqs = arrayList(threadTasksOde) |> tt hasindex i0 => parallelThreadCodeWithSplit(allEquationsPlusWhen,tt,i0,intSub(arrayLength(threadTasksOde),1),type,"_lockOde",&varDecls,simCode, extraFuncs, extraFuncsDecl, lastIdentOfPath(name), "evaluateODE", useFlatArrayNotation); separator="\n"
          let daeEqs = arrayList(threadTasksDae) |> tt hasindex i0 => parallelThreadCodeWithSplit(allEquationsPlusWhen,tt,i0,intSub(arrayLength(threadTasksDae),1),type,"_lockDae",&varDecls,simCode, extraFuncs, extraFuncsDecl, lastIdentOfPath(name), "evaluateAll", useFlatArrayNotation); separator="\n"
          let zeroFuncEqs = arrayList(threadTasksZeroFunc) |> tt hasindex i0 => parallelThreadCodeWithSplit(allEquationsPlusWhen,tt,i0,intSub(arrayLength(threadTasksZeroFunc),1),type,"_lockZeroFunc",&varDecls,simCode, extraFuncs, extraFuncsDecl, lastIdentOfPath(name), "evaluateZeroFunc", useFlatArrayNotation); separator="\n"

          let &extraFuncsDecl +=
            <<
            void evaluateODE_Parallel();
            void evaluateAll_Parallel();
            void evaluateZeroFuncs_Parallel();
            >>
          <<
          void <%lastIdentOfPath(name)%>::evaluateODE_Parallel()
          {
            #pragma omp parallel num_threads(<%getConfigInt(NUM_PROC)%>)
            {
              int threadNum = getThreadNumber();
              <%threadAssignLocksOde%>
              #pragma omp barrier
              <%odeEqs%>
              #pragma omp barrier
              <%threadReleaseLocksOde%>
            }
          }

          void <%lastIdentOfPath(name)%>::evaluateAll_Parallel()
          {
            #pragma omp parallel num_threads(<%getConfigInt(NUM_PROC)%>)
            {
              int threadNum = getThreadNumber();
              <%threadAssignLocksDae%>
              #pragma omp barrier
              <%daeEqs%>
              #pragma omp barrier
              <%threadReleaseLocksDae%>
            }
          }

          void <%lastIdentOfPath(name)%>::evaluateZeroFuncs_Parallel()
          {
            #pragma omp parallel num_threads(<%getConfigInt(NUM_PROC)%>)
            {
              int threadNum = getThreadNumber();
              <%threadAssignLocksZeroFunc%>
              #pragma omp barrier
              <%zeroFuncEqs%>
              #pragma omp barrier
              <%threadReleaseLocksZeroFunc%>
            }
          }

          <%functionHead%>
          {
            this->_evaluateMode = _evaluateMode;
            this->_command = command;
            if(evaluateMode == 0)
            {
              evaluateODE_Parallel();
            }
            else if(evaluateMode < 0)
            {
              evaluateAll_Parallel();
            }
            else
            {
              evaluateZeroFuncs_Parallel();
            }
          }
          >>
        case ("mpi") then
          <<
          <%functionHead%>
          {
            // MFlehmig: Todo
          }
          >>
        else
          let &mainThreadCode = buffer "" /*BUFD*/
          let threadFuncs = List.intRange(arrayLength(odeSchedule.threadTasks)) |> threadIdx => generateThreadFunc(allEquationsPlusWhen, arrayGet(odeSchedule.threadTasks, threadIdx), arrayGet(daeSchedule.threadTasks, threadIdx), arrayGet(zeroFuncSchedule.threadTasks, threadIdx), type, intSub(threadIdx, 1), modelNamePrefixStr, &varDecls, simCode, extraFuncs, extraFuncsDecl, lastIdentOfPath(name), &mainThreadCode, useFlatArrayNotation); separator="\n"
          let threadAssignLocks1 = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => assignLockByLockName(i0, "th_lock1", type); separator="\n"
          let threadReleaseLocks = List.rest(arrayList(odeSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => releaseLockByLockName(i0, "th_lock", type); separator="\n"
          <<
          <%threadFuncs%>

          <%functionHead%>
          {
            this->_evaluateMode = _evaluateMode;
            this->_command = command;
            <%threadReleaseLocks%>
            <%mainThreadCode%>
            <%threadAssignLocks1%>
          }
          >>
      end match
    case SOME((odeSchedule as TASKDEPSCHEDULE(__), daeSchedule as TASKDEPSCHEDULE(__), zeroFuncSchedule as TASKDEPSCHEDULE(__))) then
      match type
        case ("openmp") then
          let odeTaskEqs = function_HPCOM_TaskDep(odeSchedule.tasks, allEquationsPlusWhen, type, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
          let daeTaskEqs = function_HPCOM_TaskDep(daeSchedule.tasks, allEquationsPlusWhen, type, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
          let zeroFuncTaskEqs = function_HPCOM_TaskDep(zeroFuncSchedule.tasks, allEquationsPlusWhen, type, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
          <<
          <%functionHead%>
          {
            this->_evaluateMode = _evaluateMode;
            this->_command = command;
            <%&varDecls%>
            if(_evaluateMode == 0)
            {
              <%odeTaskEqs%>
            }
            else if(_evaluateMode < 0)
            {
              <%daeTaskEqs%>
            }
            else
            {
              <%zeroFuncTaskEqs%>
            }
          }
          >>
        case ("tbb") then
          let taskFuncs = function_HPCOM_TaskDep_voidfunc(odeSchedule.tasks, daeSchedule.tasks, zeroFuncSchedule.tasks, allEquationsPlusWhen,type, name, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
          <<
          //void functions for functionhandling in tbb_nodes
          <%taskFuncs%>

          <%functionHead%>
          {
            this->_evaluateMode = _evaluateMode;
            this->_command = command;
            <%&varDecls%>
            if(_evaluateMode == 0)
            {
              #if TBB_INTERFACE_VERSION >= 8000
                _tbbArena.execute(_tbbArenaFunctorOde);
              #else
                _tbbStartNodeOde.try_put(tbb::flow::continue_msg());
                _tbbGraphOde.wait_for_all();
              #endif
            }
            else if(_evaluateMode < 0)
            {
              #if TBB_INTERFACE_VERSION >= 8000
                _tbbArena.execute(_tbbArenaFunctorAll);
              #else
                _tbbStartNodeAll.try_put(tbb::flow::continue_msg());
                _tbbGraphAll.wait_for_all();
              #endif
            }
            else
            {
              #if TBB_INTERFACE_VERSION >= 8000
                _tbbArena.execute(_tbbArenaFunctorZeroFunc);
              #else
                _tbbStartNodeZeroFunc.try_put(tbb::flow::continue_msg());
                _tbbGraphZeroFunc.wait_for_all();
              #endif
            }
          }
          >>
        else ""
      end match
    else ""
end generateParallelEvaluate;

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
    <%taskCode(allEquationsPlusWhen, iTask, iType, "", &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation)%>
  }
  >>
end generateLevelCodeForTask;

template generateLevelFixedCodeForLevel(list<SimEqSystem> allEquationsPlusWhen, array<list<HpcOmSimCode.Task>> tasksOfLevel, String iType, Text &varDecls, Absyn.Path name, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  let eqs = (arrayList(tasksOfLevel) |> threadTasks hasindex i0 =>
    <<
    if(threadNum == <%i0%>) {
      <%threadTasks |> t => taskCode(allEquationsPlusWhen, t, iType, "", varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"%>
    }
    >>; separator="\n")

  <<
  <%eqs%>
  #pragma omp barrier
  >>
end generateLevelFixedCodeForLevel;

template generateLevelFixedCodeForThread(list<SimEqSystem> allEquationsPlusWhen, tuple<list<list<HpcOmSimCode.Task>>,list<list<HpcOmSimCode.Task>>,list<list<HpcOmSimCode.Task>>> tasksOfLevels,
                                         Integer iThreadIdx, String iType, Text &varDecls, Absyn.Path name, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                                         Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  match iType
    case ("pthreads")
    case ("pthreads_spin") then
      match(tasksOfLevels)
        case((odeTasksOfLevel, daeTasksOfLevel, zeroFuncTasksOfLevel)) then
          let odeEqs = odeTasksOfLevel |> tasks hasindex levelIdx => generateLevelFixedCodeForThreadLevel(allEquationsPlusWhen, tasks, iThreadIdx, "evaluateODE", iType, levelIdx, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
          let daeEqs = daeTasksOfLevel |> tasks hasindex levelIdx => generateLevelFixedCodeForThreadLevel(allEquationsPlusWhen, tasks, iThreadIdx, "evaluateDAE", iType, levelIdx, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
          let zeroFuncEqs = zeroFuncTasksOfLevel |> tasks hasindex levelIdx => generateLevelFixedCodeForThreadLevel(allEquationsPlusWhen, tasks, iThreadIdx, "evaluateZeroFuncs", iType, levelIdx, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
          let &extraFuncsDecl +=
          <<
          void evaluateThreadFuncODE_<%iThreadIdx%>();
          void evaluateThreadFuncAll_<%iThreadIdx%>();
          void evaluateThreadFuncZeroFunc_<%iThreadIdx%>();
          void evaluateThreadFunc<%iThreadIdx%>();
          <%\n%>
          >>
          <<
          void <%lastIdentOfPath(name)%>::evaluateThreadFuncODE_<%iThreadIdx%>()
          {
            <%odeEqs%>
          }

          void <%lastIdentOfPath(name)%>::evaluateThreadFuncAll_<%iThreadIdx%>()
          {
            <%daeEqs%>
          }

          void <%lastIdentOfPath(name)%>::evaluateThreadFuncZeroFunc_<%iThreadIdx%>()
          {
            <%zeroFuncEqs%>
          }

          <%if (intGt(iThreadIdx, 0)) then
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
                if(_evaluateMode == 0)
                {
                  evaluateThreadFuncODE_<%iThreadIdx%>();
                  <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
                  <<
                  <%generateMeasureTimeEndCode("valuesStart", "valuesEnd", '(*measureTimeThreadArrayOdeHpcom)[<%iThreadIdx%>]', 'evaluateODEThread<%iThreadIdx%>', "MEASURETIME_MODELFUNCTIONS")%>
                  >>%>
                }
                else if(_evaluateMode < 0)
                {
                  evaluateThreadFuncAll_<%iThreadIdx%>();
                  <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
                  <<
                  <%generateMeasureTimeEndCode("valuesStart", "valuesEnd", '(*measureTimeThreadArrayDaeHpcom)[<%iThreadIdx%>]', 'evaluateDaeThread<%iThreadIdx%>', "MEASURETIME_MODELFUNCTIONS")%>
                  >>%>
                }
                else
                {
                  evaluateThreadFuncZeroFunc_<%iThreadIdx%>();
                  <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
                  <<
                  <%generateMeasureTimeEndCode("valuesStart", "valuesEnd", '(*measureTimeThreadArrayZeroFuncHpcom)[<%iThreadIdx%>]', 'evaluateZeroFuncThread<%iThreadIdx%>', "MEASURETIME_MODELFUNCTIONS")%>
                  >>%>
                }

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
          %>
          >>
    else ""
end generateLevelFixedCodeForThread;

template generateLevelFixedCodeForThreadLevel(list<SimEqSystem> allEquationsPlusWhen, list<HpcOmSimCode.Task> tasksOfLevel,
                                              Integer iThreadIdx, String functionName, String iType, Integer iLevelIdx, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  let tasks = tasksOfLevel |> t => taskCode(allEquationsPlusWhen, t, iType, "", varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
  <<
  //Start of Level <%iLevelIdx%>
  <%if intEq(iThreadIdx, 0) then
    <<
    <%generateMeasureTimeStartCode("measuredSchedulerStartValues", '<%functionName%>_level_<%intAdd(iLevelIdx,1)%>', "MEASURETIME_MODELFUNCTIONS")%>
    >>
  %>

  <%if(stringEq(tasks,"")) then '' else ''%>
  <%tasks%>
  _levelBarrier.wait();

  <%if intEq(iThreadIdx, 0) then
    <<
    <%generateMeasureTimeEndCode("measuredSchedulerStartValues", "measuredSchedulerEndValues", '(*measureTimeSchedulerArrayHpcom_<%functionName%>)[<%iLevelIdx%>]', '<%functionName%>_level_<%intAdd(iLevelIdx,1)%>', "MEASURETIME_MODELFUNCTIONS")%>
    >>
  %>
  //End of Level <%iLevelIdx%>
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
      let taskEqs = taskCode(allEquationsPlusWhen, task, iType, "", &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace,useFlatArrayNotation); separator="\n"
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

template generateTbbConstructorExtension(list<tuple<Task,list<Integer>>> odeTasks, list<tuple<Task,list<Integer>>> daeTasks, list<tuple<Task,list<Integer>>> zeroFuncTasks, String modelNamePrefixStr)
::=
  let odeNodes = odeTasks |> t hasindex i fromindex 0 => generateTbbConstructorExtensionNodes(t,i,"Ode",modelNamePrefixStr); separator="\n"
  let odeEdges = odeTasks |> t hasindex i fromindex 0 => generateTbbConstructorExtensionEdges(t,i,"Ode",modelNamePrefixStr); separator="\n"
  let daeNodes = daeTasks |> t hasindex i fromindex 0 => generateTbbConstructorExtensionNodes(t,i,"All",modelNamePrefixStr); separator="\n"
  let daeEdges = daeTasks |> t hasindex i fromindex 0 => generateTbbConstructorExtensionEdges(t,i,"All",modelNamePrefixStr); separator="\n"
  let zeroFuncNodes = zeroFuncTasks |> t hasindex i fromindex 0 => generateTbbConstructorExtensionNodes(t,i,"ZeroFunc",modelNamePrefixStr); separator="\n"
  let zeroFuncEdges = zeroFuncTasks |> t hasindex i fromindex 0 => generateTbbConstructorExtensionEdges(t,i,"ZeroFunc",modelNamePrefixStr); separator="\n"
  <<
  tbb::flow::continue_node<tbb::flow::continue_msg> *tbb_task;
  <%odeNodes%>
  <%odeEdges%>
  <%daeNodes%>
  <%daeEdges%>
  <%zeroFuncNodes%>
  <%zeroFuncEdges%>
  #if TBB_INTERFACE_VERSION >= 8000
  _tbbArena = tbb::task_arena(<%getConfigInt(NUM_PROC)%>);
  _tbbArenaFunctorOde = TbbArenaFunctor(_tbbGraphOde,_tbbStartNodeOde);
  _tbbArenaFunctorAll = TbbArenaFunctor(_tbbGraphAll,_tbbStartNodeAll);
  _tbbArenaFunctorZeroFunc = TbbArenaFunctor(_tbbGraphZeroFunc,_tbbStartNodeZeroFunc);
  #endif
  >>
end generateTbbConstructorExtension;

template generateTbbConstructorExtensionNodes(tuple<Task,list<Integer>> taskIn, Integer taskIndex, String funcSuffix, String modelNamePrefixStr)
::=
  match taskIn
    case ((task as CALCTASK(__),parents)) then
      <<
      tbb_task = new tbb::flow::continue_node<tbb::flow::continue_msg>(_tbbGraph<%funcSuffix%>,VoidFunctionBody(bind<void>(&<%modelNamePrefixStr%>::taskFunc<%funcSuffix%>_<%task.index%>,this)));
      _tbbNodeList<%funcSuffix%>.at(<%taskIndex%>) = tbb_task;
      >>
  end match
end generateTbbConstructorExtensionNodes;

template generateTbbConstructorExtensionEdges(tuple<Task,list<Integer>> taskIn, Integer taskIndex, String funcSuffix, String modelNamePrefixStr)
::=
  match taskIn
    case ((task as CALCTASK(__),parents)) then
      let parentEdges = parents |> p => 'tbb::flow::make_edge(*(_tbbNodeList<%funcSuffix%>.at(<%intSub(p,1)%>)),*(_tbbNodeList<%funcSuffix%>.at(<%taskIndex%>)));'; separator = "\n"
      let startNodeEdge = if intEq(0, listLength(parents)) then 'tbb::flow::make_edge(_tbbStartNode<%funcSuffix%>,*(_tbbNodeList<%funcSuffix%>.at(<%taskIndex%>)));' else ""
      <<
      <%parentEdges%>
      <%startNodeEdge%>
      >>
  end match
end generateTbbConstructorExtensionEdges;

template function_HPCOM_TaskDep_voidfunc(list<tuple<Task,list<Integer>>> odeTasks, list<tuple<Task,list<Integer>>> daeTasks, list<tuple<Task,list<Integer>>> zeroFuncTasks, list<SimEqSystem> allEquationsPlusWhen,
                                         String iType, Absyn.Path name, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  let funcTasksOde = odeTasks |> t => function_HPCOM_TaskDep_voidfunc0(t,allEquationsPlusWhen,iType, "Ode", name, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
  let funcTasksDae = daeTasks |> t => function_HPCOM_TaskDep_voidfunc0(t,allEquationsPlusWhen,iType, "All", name, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
  let funcTasksZeroFunc = zeroFuncTasks |> t => function_HPCOM_TaskDep_voidfunc0(t,allEquationsPlusWhen,iType, "ZeroFunc", name, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
  <<
  <%funcTasksOde%>
  <%funcTasksDae%>
  <%funcTasksZeroFunc%>
  >>
end function_HPCOM_TaskDep_voidfunc;

template function_HPCOM_TaskDep_voidfunc0(tuple<Task,list<Integer>> taskIn, list<SimEqSystem> allEquationsPlusWhen, String iType, String funcSuffix, Absyn.Path name, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  match taskIn
    case ((task as CALCTASK(__),parents)) then
      let &tempvarDecl = buffer "" /*BUFD*/
      let taskEqs = taskCode(allEquationsPlusWhen, task, iType, "", &tempvarDecl, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace,useFlatArrayNotation); separator="\n"
      <<
      void <%lastIdentOfPath(name)%>::taskFunc<%funcSuffix%>_<%task.index%>()
      {
        <%tempvarDecl%>
        <%taskEqs%>
      }
      >>
  end match
end function_HPCOM_TaskDep_voidfunc0;

/*
template function_HPCOM_Thread(list<SimEqSystem> allEquationsPlusWhen, array<list<Task>> threadTasksOde, array<list<Task>> threadTasksDae, array<list<Task>> threadTasksZeroFunc, String iType,Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  let odeEqs = arrayList(threadTasksOde) |> tt hasindex i0 => parallelThreadCodeWithSplit(allEquationsPlusWhen,tt,i0,iType,"_lockOde",&varDecls,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, "evaluateODE", useFlatArrayNotation); separator="\n"
  let daeEqs = arrayList(threadTasksDae) |> tt hasindex i0 => parallelThreadCodeWithSplit(allEquationsPlusWhen,tt,i0,iType,"_lockDae",&varDecls,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, "evaluateAll", useFlatArrayNotation); separator="\n"
  let zeroFuncEqs = arrayList(threadTasksDae) |> tt hasindex i0 => parallelThreadCodeWithSplit(allEquationsPlusWhen,tt,i0,iType,"_lockZeroFunc",&varDecls,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, "evaluateZeroFunc", useFlatArrayNotation); separator="\n"
  match iType
    case ("mpi") then
      <<
      int world_rank;
      MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
      if(_evaluateMode == 0)
      {
        <%odeEqs%>
      }
      else if(_evaluateMode < 0)
      {
        <%daeEqs%>
      }
      else
      {
        <%zeroFuncEqs%>
      }
      >>
    else
      <<
      if(_evaluateMode == 0)
      {
        <%generateMeasureTimeStartCode("measuredSchedulerStartValues", "evaluateODE_threads", "MEASURETIME_MODELFUNCTIONS")%>
        <%odeEqs%>
        <%generateMeasureTimeEndCode("measuredSchedulerStartValues", "measuredSchedulerEndValues", "(*measureTimeThreadArrayOdeHpcom)[threadNum]", "evaluateODE_threads", "MEASURETIME_MODELFUNCTIONS")%>
      }
      else if(_evaluateMode < 0)
      {
        <%generateMeasureTimeStartCode("measuredSchedulerStartValues", "evaluateDAE_threads", "MEASURETIME_MODELFUNCTIONS")%>
        <%daeEqs%>
        <%generateMeasureTimeEndCode("measuredSchedulerStartValues", "measuredSchedulerEndValues", "(*measureTimeThreadArrayDaeHpcom)[threadNum]", "evaluateDAE_threads", "MEASURETIME_MODELFUNCTIONS")%>
      }
      else
      {
        <%generateMeasureTimeStartCode("measuredSchedulerStartValues", "evaluateZeroFunc_threads", "MEASURETIME_MODELFUNCTIONS")%>
        <%zeroFuncEqs%>
        <%generateMeasureTimeEndCode("measuredSchedulerStartValues", "measuredSchedulerEndValues", "(*measureTimeThreadArrayZeroFuncHpcom)[threadNum]", "evaluateZeroFunc_threads", "MEASURETIME_MODELFUNCTIONS")%>
      }
      >>
  end match
end function_HPCOM_Thread;
*/
template generateThreadFunc(list<SimEqSystem> allEquationsPlusWhen, list<Task> threadTasksOde, list<Task> threadTasksDae, list<Task> threadTasksZeroFunc, String iType, Integer iThreadIdx, String modelNamePrefixStr, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text& mainThreadCode, Boolean useFlatArrayNotation)
::=
  let &varDeclsLoc = buffer "" /*BUFD*/
  let taskEqsOde = parallelThreadCode(allEquationsPlusWhen, threadTasksOde, iThreadIdx, iType, "_lockOde", &varDeclsLoc, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, "evaluateODE", useFlatArrayNotation); separator="\n"
  let taskEqsDae = parallelThreadCode(allEquationsPlusWhen, threadTasksDae, iThreadIdx, iType, "_lockDae", &varDeclsLoc, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, "evaluateAll", useFlatArrayNotation); separator="\n"
  let taskEqsZeroFunc = parallelThreadCode(allEquationsPlusWhen, threadTasksZeroFunc, iThreadIdx, iType, "_lockZeroFunc", &varDeclsLoc, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, "evaluateZeroFunc", useFlatArrayNotation); separator="\n"
  let assLock = assignLockByLockName(iThreadIdx, "th_lock", iType); separator="\n"
  let relLock = releaseLockByLockName(iThreadIdx, "th_lock1", iType); separator="\n"
  let &extraFuncsDecl +=
    <<
    void evaluateThreadFuncODE_<%iThreadIdx%>();
    void evaluateThreadFuncAll_<%iThreadIdx%>();
    void evaluateThreadFuncZeroFunc_<%iThreadIdx%>();
    >>

  if (intGt(iThreadIdx, 0)) then
    <<
    void <%modelNamePrefixStr%>::evaluateThreadFuncODE_<%iThreadIdx%>()
    {
      <%taskEqsOde%>
    }

    void <%modelNamePrefixStr%>::evaluateThreadFuncAll_<%iThreadIdx%>()
    {
      <%taskEqsDae%>
    }

    void <%modelNamePrefixStr%>::evaluateThreadFuncZeroFunc_<%iThreadIdx%>()
    {
      <%taskEqsZeroFunc%>
    }

    void <%modelNamePrefixStr%>::evaluateThreadFunc<%iThreadIdx%>()
    {
      #ifdef MEASURETIME_MODELFUNCTIONS
      MeasureTimeValues *measuredSchedulerStartValues = measuredSchedulerStartValues_<%intSub(iThreadIdx,1)%>;
      MeasureTimeValues *measuredSchedulerEndValues = measuredSchedulerEndValues_<%intSub(iThreadIdx,1)%>;
      #endif //MEASURETIME_MODELFUNCTIONS
      <%&varDeclsLoc%>
      while(1)
      {
        <%assLock%>
        if(_terminateThreads)
           return;

		if(_evaluateMode == 0)
		{
          evaluateThreadFuncODE_<%iThreadIdx%>();
        }
        else if(_evaluateMode < 0)
        {
          evaluateThreadFuncAll_<%iThreadIdx%>();
        }
        else
        {
          evaluateThreadFuncZeroFunc_<%iThreadIdx%>();
        }
        <%relLock%>
      }
    }
    >>
  else
    let &mainThreadCode += &varDeclsLoc
    let &mainThreadCode +=
      <<
      #ifdef MEASURETIME_MODELFUNCTIONS
      MeasureTimeValues *measuredSchedulerStartValues = measuredSchedulerStartValues_0;
      MeasureTimeValues *measuredSchedulerEndValues = measuredSchedulerEndValues_0;
      #endif //MEASURETIME_MODELFUNCTIONS
      if(_evaluateMode == 0)
      {
        evaluateThreadFuncODE_<%iThreadIdx%>();
      }
      else if(_evaluateMode < 0)
      {
        evaluateThreadFuncAll_<%iThreadIdx%>();
      }
      else
      {
        evaluateThreadFuncZeroFunc_<%iThreadIdx%>();
      }
      >>
    <<
    void <%modelNamePrefixStr%>::evaluateThreadFuncODE_<%iThreadIdx%>()
    {
      <%taskEqsOde%>
    }

    void <%modelNamePrefixStr%>::evaluateThreadFuncAll_<%iThreadIdx%>()
    {
      <%taskEqsDae%>
    }

    void <%modelNamePrefixStr%>::evaluateThreadFuncZeroFunc_<%iThreadIdx%>()
    {
      <%taskEqsZeroFunc%>
    }
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

template parallelThreadCodeWithSplit(list<SimEqSystem> allEquationsPlusWhen, list<Task> threadTaskList, Integer iThreadNum, Integer iMaxThreadNumber,
                                String iType, String lockPrefix, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                                Text extraFuncsNamespace, String extraFunctionName, Boolean useFlatArrayNotation)
::=
  let functionCalls = List.partition(threadTaskList, 100) |> tt hasindex i0 => parallelThreadCode(allEquationsPlusWhen,tt,i0,iType,lockPrefix,&varDecls,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, '<%extraFunctionName%>_Th<%iThreadNum%>', useFlatArrayNotation); separator="\n"
  match iType
    case ("openmp") then
      <<
      <%if intEq(iThreadNum, 0) then 'switch(threadNum) <%\n%>{<%\n%>' else '' %>case <%iThreadNum%>:
        <%functionCalls%>
        break;
      <%if intEq(iThreadNum, iMaxThreadNumber) then '<%\n%>}' else ''%>
      >>
    case ("mpi") then
      <<
      if (world_rank == <%iThreadNum%>)
      {
        <%functionCalls%>
      }
      >>
    else
      <<
      <%functionCalls%>
      >>
  end match
end parallelThreadCodeWithSplit;

template parallelThreadCode(list<SimEqSystem> allEquationsPlusWhen, list<Task> threadTaskList, Integer iPartitionIndex,
                                String iType, String lockPrefix, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, String extraFunctionName, Boolean useFlatArrayNotation)
::=
  let threadTasks = threadTaskList |> tt => taskCode(allEquationsPlusWhen,tt,iType,lockPrefix,&varDecls,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace,useFlatArrayNotation); separator="\n"
  let &extraFuncs +=
  <<
  void <%extraFuncsNamespace%>::<%extraFunctionName%>_<%iPartitionIndex%>()
  {
    <%threadTasks%>
  }<%\n%><%\n%>
  >>
  let &extraFuncsDecl += 'void <%extraFunctionName%>_<%iPartitionIndex%>();'

  <<
  <%extraFunctionName%>_<%iPartitionIndex%>();
  >>
end parallelThreadCode;

template taskCode(list<SimEqSystem> allEquationsPlusWhen, Task iTask, String iType, String lockPrefix, Text &varDecls,
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
      let assLck = assignLockByDepTask(task, lockPrefix, iType); separator="\n"
      <<
      <%assLck%>
      >>
    case(task as DEPTASK(outgoing=true)) then
      let relLck = releaseLockByDepTask(task, lockPrefix, iType); separator="\n"
      <<
      <%relLck%>
      >>
  end match
end taskCode;

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
      evaluateThread<%threadIdx%> = new thread(bind(&<%modelNamePrefixStr%>::<%funcName%><%threadIdx%>, this));
      >>
  end match
end generateThread;

template getLockNameByDepTask(Task depTask)
::=
  match depTask
    case(task as DEPTASK(__)) then
      '[<%task.id%>]'
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
    case ("pthreads")
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


template mpiFinalize()
 "Finalize the MPI environment in main function."
::=
  <<
  } // End sequential
  MPI_Finalize();
  >>
end mpiFinalize;

template mpiInit()
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
end mpiInit;

template mpiRunCommandInRunScript(String type, Text &getNumOfProcs, Text &execCommandLinux)
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
end mpiRunCommandInRunScript;

template simulationMainRunScript(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace)
 "Generates code for header file for simulation target."
::=
  let type = if Flags.isSet(Flags.USEMPI) then "mpi" else ''
  let &preRunCommandLinux = buffer ""
  let &execCommandLinux = buffer ""
  let _ = mpiRunCommandInRunScript(type, &preRunCommandLinux, &execCommandLinux)
  let preRunCommandWindows = ""

  CodegenCpp.simulationMainRunScript(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, preRunCommandLinux, preRunCommandWindows, execCommandLinux)
end simulationMainRunScript;

template getAdditionalMakefileFlags(Text& additionalLinkerFlags_GCC, Text& additionalLinkerFlags_MSVC, Text& additionalCFlags_GCC, Text& additionalCFlags_MSVC)
::=
  let type = getConfigString(HPCOM_CODE)

  let &additionalCFlags_GCC += if stringEq(type,"openmp") then " -fopenmp" else ""
  let &additionalCFlags_GCC += if stringEq(type,"tbb") then ' -I"$(INTEL_TBB_INCLUDE)"' else ""

  let &additionalCFlags_MSVC += if stringEq(type,"openmp") then "/openmp" else ""

  let &additionalLinkerFlags_GCC += if stringEq(type,"tbb") then "-L$(INTEL_TBB_LIBS) $(INTEL_TBB_LIBRARIES) " else ""
  let &additionalLinkerFlags_GCC += if stringEq(type,"openmp") then " -fopenmp" else ""
  <<
  >>
end getAdditionalMakefileFlags;

template simulationMakefile(String target, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace)
 "Adds specific compiler flags for HPCOM mode to simulation makefile."
::=
  let &additionalCFlags_GCC = buffer ""
  let &additionalCFlags_MSVC = buffer ""
  let &additionalLinkerFlags_GCC = buffer ""
  let &additionalLinkerFlags_MSVC = buffer ""

  <<
  <%getAdditionalMakefileFlags(additionalLinkerFlags_GCC, additionalLinkerFlags_MSVC, additionalCFlags_GCC, additionalCFlags_MSVC)%>
  <%CodegenCpp.simulationMakefile(target, simCode, extraFuncs ,extraFuncsDecl, extraFuncsNamespace, additionalLinkerFlags_GCC,
                                additionalLinkerFlags_MSVC, additionalCFlags_GCC, additionalCFlags_MSVC,
                                Flags.isSet(Flags.USEMPI))%>
  >>
end simulationMakefile;

template numPreVarsHpcom(ModelInfo modelInfo, Option<MemoryMap> hpcOmMemoryOpt)
::=
  match(hpcOmMemoryOpt)
    case(SOME(hpcomMemory as MEMORYMAP_ARRAY(floatArraySize=floatArraySize,intArraySize=intArraySize,boolArraySize=boolArraySize))) then
      '<%floatArraySize%> + <%intArraySize%> + <%boolArraySize%>'
    else
      CodegenCpp.getPreVarsCount(modelInfo)
end numPreVarsHpcom;

template numRealvarsHpcom(ModelInfo modelInfo, Option<MemoryMap> hpcOmMemoryOpt)
::=
  match(hpcOmMemoryOpt)
    case(SOME(hpcomMemory as MEMORYMAP_ARRAY(floatArraySize=floatArraySize))) then
      '<%floatArraySize%>'
    else
      '<%CodegenCpp.numRealvars(modelInfo)%>'
end numRealvarsHpcom;

template numIntvarsHpcom(ModelInfo modelInfo, Option<MemoryMap> hpcOmMemoryOpt)
::=
  match(hpcOmMemoryOpt)
    case(SOME(hpcomMemory as MEMORYMAP_ARRAY(intArraySize=intArraySize))) then
      '<%intArraySize%>'
    else
      CodegenCpp.numIntvars(modelInfo)
end numIntvarsHpcom;

template numBoolvarsHpcom(ModelInfo modelInfo, Option<MemoryMap> hpcOmMemoryOpt)
::=
  match(hpcOmMemoryOpt)
    case(SOME(hpcomMemory as MEMORYMAP_ARRAY(boolArraySize=boolArraySize))) then
      '<%boolArraySize%>'
    else
      CodegenCpp.numBoolvars(modelInfo)
end numBoolvarsHpcom;

template numStringvarsHpcom(ModelInfo modelInfo, Option<MemoryMap> hpcOmMemoryOpt)
::=
  match(hpcOmMemoryOpt)
    case(SOME(hpcomMemory as MEMORYMAP_ARRAY(stringArraySize=stringArraySize))) then
      '<%stringArraySize%>'
    else
      CodegenCpp.numStringvars(modelInfo)
end numStringvarsHpcom;

annotation(__OpenModelica_Interface="backend");
end CodegenCppHpcom;
