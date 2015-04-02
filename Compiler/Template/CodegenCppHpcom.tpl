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
    case SIMCODE(modelInfo = MODELINFO(__), makefileParams= MAKEFILE_PARAMS(__)) then
      let target  = simulationCodeTarget()
      let &extraFuncs = buffer "" /*BUFD*/
      let &extraFuncsDecl = buffer "" /*BUFD*/
      let preVarsCount = getPreVarsCount(simCode)
      let stateDerVectorName = "__zDot"
      let useMemoryOptimization = HpcOmMemory.useHpcomMemoryOptimization(hpcOmMemory)

      let() = textFile(simulationMainFile(target, simCode, &extraFuncs, &extraFuncsDecl, "", (if Flags.isSet(USEMPI) then "#include <mpi.h>" else ""), (if Flags.isSet(USEMPI) then MPIInit() else ""), (if Flags.isSet(USEMPI) then MPIFinalize() else "")), 'OMCpp<%fileNamePrefix%>Main.cpp')

      let() = textFile(simulationHeaderFile(simCode ,contextOther, &extraFuncs, &extraFuncsDecl, "",
                      generateAdditionalIncludes(simCode, &extraFuncs, &extraFuncsDecl, "", stringBool(useMemoryOptimization)), "",
                      generateAdditionalProtectedMemberDeclaration(simCode, &extraFuncs, &extraFuncsDecl, "", stringBool(useMemoryOptimization)),
                      MemberVariable(modelInfo, hpcOmMemory,stringBool(useMemoryOptimization),false), false),
                      'OMCpp<%fileNamePrefix%>.h')
      let() = textFile(simulationCppFile(simCode ,contextOther, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, stringBool(useMemoryOptimization)), 'OMCpp<%fileNamePrefix%>.cpp')
      let() = textFile(simulationFunctionsHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, "",modelInfo.functions, literals,stateDerVectorName,false), 'OMCpp<%fileNamePrefix%>Functions.h')
      let() = textFile(simulationFunctionsFile(simCode, &extraFuncs, &extraFuncsDecl, "", modelInfo.functions, literals,externalFunctionIncludes,stateDerVectorName,false), 'OMCpp<%fileNamePrefix%>Functions.cpp')
      let() = textFile(simulationTypesHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, "",modelInfo.functions, literals,stateDerVectorName,false), 'OMCpp<%fileNamePrefix%>Types.h')
      let() = textFile(simulationMakefile(target,simCode, &extraFuncs, &extraFuncsDecl, ""), '<%fileNamePrefix%>.makefile')
      let() = textFile(simulationInitHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>Initialize.h')
      let() = textFile(simulationInitCppFile(simCode ,&extraFuncs, &extraFuncsDecl, "", stateDerVectorName, stringBool(useMemoryOptimization)), 'OMCpp<%fileNamePrefix%>Initialize.cpp')
      let() = textFile(simulationInitParameterCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, stringBool(useMemoryOptimization)), 'OMCpp<%fileNamePrefix%>InitializeParameter.cpp')
      let() = textFile(simulationInitExtVarsCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, stringBool(useMemoryOptimization)), 'OMCpp<%fileNamePrefix%>InitializeExtVars.cpp')
      let() = textFile(simulationInitAliasVarsCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, stringBool(useMemoryOptimization)), 'OMCpp<%fileNamePrefix%>InitializeAliasVars.cpp')
      let() = textFile(simulationInitAlgVarsCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, stringBool(useMemoryOptimization)), 'OMCpp<%fileNamePrefix%>InitializeAlgVars.cpp')
      let() = textFile(simulationJacobianHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>Jacobian.h')
      let() = textFile(simulationJacobianCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, stringBool(useMemoryOptimization)), 'OMCpp<%fileNamePrefix%>Jacobian.cpp')
      let() = textFile(simulationStateSelectionCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, stringBool(useMemoryOptimization)), 'OMCpp<%fileNamePrefix%>StateSelection.cpp')
      let() = textFile(simulationStateSelectionHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>StateSelection.h')
      let() = textFile(simulationExtensionHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>Extension.h')
      let() = textFile(simulationExtensionCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", preVarsCount), 'OMCpp<%fileNamePrefix%>Extension.cpp')
      let() = textFile(simulationWriteOutputHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>WriteOutput.h')
      let() = textFile(simulationPreVarsHeaderFile(simCode, &extraFuncs, &extraFuncsDecl, "", MemberVariablePreVariables(modelInfo, hpcOmMemory, stringBool(useMemoryOptimization), false), generateAdditionalPublicMemberDeclaration(simCode, &extraFuncs, &extraFuncsDecl, ""), preVarsCount, false), 'OMCpp<%fileNamePrefix%>PreVariables.h')
      let() = textFile(simulationWriteOutputCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, stringBool(useMemoryOptimization)), 'OMCpp<%fileNamePrefix%>WriteOutput.cpp')
      let() = textFile(simulationPreVarsCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, stringBool(useMemoryOptimization)), 'OMCpp<%fileNamePrefix%>PreVariables.cpp')
      let() = textFile(simulationWriteOutputAlgVarsCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, stringBool(useMemoryOptimization)), 'OMCpp<%fileNamePrefix%>WriteOutputAlgVars.cpp')
      let() = textFile(simulationWriteOutputParameterCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stringBool(useMemoryOptimization)), 'OMCpp<%fileNamePrefix%>WriteOutputParameter.cpp')
      let() = textFile(simulationWriteOutputAliasVarsCppFile(simCode, &extraFuncs, &extraFuncsDecl, "", stateDerVectorName, stringBool(useMemoryOptimization)), 'OMCpp<%fileNamePrefix%>WriteOutputAliasVars.cpp')
      let() = textFile(simulationFactoryFile(simCode, &extraFuncs, &extraFuncsDecl, ""), 'OMCpp<%fileNamePrefix%>FactoryExport.cpp')
      let() = textFile(simulationMainRunScript(simCode, &extraFuncs, &extraFuncsDecl, ""), '<%fileNamePrefix%><%simulationMainRunScriptSuffix(simCode, &extraFuncs, &extraFuncsDecl, "")%>')
      let jac =  (jacobianMatrixes |> (mat, _,_, _, _, _,_) =>
          (mat |> (eqs,_,_) =>  algloopfiles(eqs,simCode, &extraFuncs, &extraFuncsDecl, "",contextAlgloopJacobian, stateDerVectorName, stringBool(useMemoryOptimization)) ;separator="")
          ;separator="")
      let alg = algloopfiles(listAppend(allEquations,initialEquations), simCode, &extraFuncs, &extraFuncsDecl, "", contextAlgloop, stateDerVectorName, stringBool(useMemoryOptimization))
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
      <%generateHpcomSpecificIncludes(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace)%>
      >>
  end match
end generateAdditionalIncludes;

template generateAdditionalPublicMemberDeclaration(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace)
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__)) then
      if(HpcOmMemory.useHpcomMemoryOptimization(hpcOmMemory)) then
        let addHpcomArrayHeaders = getAddHpcomVarArrays(hpcOmMemory)
        <<
        <%addHpcomArrayHeaders%>

        void* operator new(size_t size)
        {
           //see: http://stackoverflow.com/questions/12504776/aligned-malloc-in-c
           void *p1;
           void **p2;
           size_t alignment = 64;
           int offset=alignment - 1 + sizeof(void*);
           p1 = malloc(size + offset);
           p2=(void**)(((size_t)(p1)+offset)&~(alignment-1));
           p2[-1]=p1; //line 6

           if(((size_t)p2) % 64 != 0)
              throw std::runtime_error("Memory was not alligned correctly!");

           return p2;
        }
        void operator delete(void *p)
        {
           void* p1 = ((void**)p)[-1];         // get the pointer to the buffer we allocated
           free( p1 );
        }
        >>
        /*

        */

      else ''
    else ''
  end match
end generateAdditionalPublicMemberDeclaration;

template generateAdditionalProtectedMemberDeclaration(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
 "Generates class declarations."
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__)) then
      let addHpcomFunctionHeaders = getAddHpcomFunctionHeaders(hpcOmSchedule)
      let addHpcomVarHeaders = getAddHpcomVarHeaders(hpcOmSchedule)
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

      <%addHpcomFunctionHeaders%>
      <%addHpcomVarHeaders%>

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
      end match
    case SOME(hpcOmSchedule as THREADSCHEDULE(__)) then
      let locks = hpcOmSchedule.outgoingDepTasks |> task => createLockByDepTask(task, "lock", type); separator="\n"
      match type
        case ("openmp") then
          <<
          >>
        else
          let headers = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => generateThreadFunctionHeaderDecl(i0); separator="\n"
          <<
          <%headers%>
          >>
      end match
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
      end match
    else ""
  end match
end getAddHpcomFunctionHeaders;

template getAddHpcomVarArrays(Option<MemoryMap> optHpcomMemoryMap)
::=
  match optHpcomMemoryMap
    case(SOME(hpcomMemoryMap)) then
      match hpcomMemoryMap
        case(MEMORYMAP_ARRAY(__)) then
          <<
          <%if intGt(floatArraySize,0) then 'double varArray1[<%floatArraySize%>]; //float variables'%>
          <%if intGt(intArraySize,0) then 'int varArray2[<%intArraySize%>]; //int variables'%>
          <%if intGt(boolArraySize,0) then 'bool varArray3[<%boolArraySize%>]; //bool variables'%>
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
          <%createBarrierByName("levelBarrier","", getConfigInt(NUM_PROC), type)%>
          <%createLockByLockName("measureTimeArrayLock", "", type)%>
          bool _simulationFinished;
          UPDATETYPE _command;
          >>
        else ""
      end match
    case SOME(hpcOmSchedule as THREADSCHEDULE(__)) then
      let locks = hpcOmSchedule.outgoingDepTasks |> task => createLockByDepTask(task, "lock", type); separator="\n"
      match type
        case ("openmp") then
          let threadDecl = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => generateThreadHeaderDecl(i0, type); separator="\n"
          <<
          <%locks%>
          <%threadDecl%>
          >>
        case "mpi" then
          <<
          //MF Todo BLABLUB
          >>
        else
          let threadDecl = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => generateThreadHeaderDecl(i0, type); separator="\n"
          let thLocks = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => createLockByLockName(i0, "th_lock", type); separator="\n"
          let thLocks1 = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => createLockByLockName(i0, "th_lock1", type); separator="\n"
          <<
          bool terminateThreads;
          UPDATETYPE command;
          <%locks%>
          <%thLocks%>
          <%thLocks1%>
          <%threadDecl%>
          >>
      end match
    case SOME(hpcOmSchedule as TASKDEPSCHEDULE(__)) then
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
end getAddHpcomVarHeaders;


template getAddHpcomFuncHeadersTaskDep(tuple<Task, list<Integer>> taskIn)
::=
  match taskIn
    case ((task as CALCTASK(__),parents)) then
      <<
      void task_func_<%task.index%>();
      >>
  end match
end getAddHpcomFuncHeadersTaskDep;

template generateHpcomSpecificIncludes(SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace)
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
  end match
end generateThreadHeaderDecl;

template generateThreadFunctionHeaderDecl(Integer threadIdx)
::=
  <<
  void evaluateThreadFunc<%threadIdx%>();
  >>
end generateThreadFunctionHeaderDecl;


template simulationCppFile(SimCode simCode, Context context, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for main cpp file for simulation target."
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__)) then
      let hpcomConstructorExtension = getHpcomConstructorExtension(hpcOmSchedule, lastIdentOfPath(modelInfo.name), dotPath(modelInfo.name))
      let hpcomMemberVariableDefinition = getHpcomMemberVariableDefinition(hpcOmSchedule)
      let hpcomDestructorExtension = getHpcomDestructorExtension(hpcOmSchedule)
      let type = getConfigString(HPCOM_CODE)
      let className = lastIdentOfPath(modelInfo.name)
      <<
      #include <Core/Modelica.h>
      #include <Core/ModelicaDefine.h>
      #include "OMCpp<%fileNamePrefix%>PreVariables.h"
      #include "OMCpp<%fileNamePrefix%>.h"
      #include "OMCpp<%fileNamePrefix%>Functions.h"
      #include <Core/System/EventHandling.h>
      #include <Core/System/DiscreteEvents.h>
      #if defined(__TRICORE__) || defined(__vxworks)
      #include <DataExchange/SimDouble.h>
      #endif

      /* Constructor */
      <%className%>::<%className%>(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data)
        : SystemDefaultImplementation(globalSettings)
        , <%className%>PreVariables()
        , _algLoopSolverFactory(nonlinsolverfactory)
        , _sim_data(sim_data)
        <%hpcomMemberVariableDefinition%>
        <%MemberVariable(modelInfo, hpcOmMemory, useFlatArrayNotation,true)%>
        <%simulationInitFile(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
      {
        //I don't know why this line is necessary if we link statically, but without it a segfault occurs
        _global_settings = globalSettings;
        //Number of equations
        <%dimension1(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace)%>
        _dimZeroFunc= <%zerocrosslength(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace)%>;
        _dimTimeEvent = <%timeeventlength(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace)%>;
        //Number of residues
        _event_handling= boost::shared_ptr<EventHandling>(new EventHandling());
        <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
          <<
          _dimResidues=<%numResidues(allEquations)%>;
          >>
        %>
            <%if boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")) then
                let numOfEqs = SimCodeUtil.getMaxSimEqSystemIndex(simCode)
                <<
                #ifdef MEASURETIME_PROFILEBLOCKS
                measureTimeProfileBlocksArray = std::vector<MeasureTimeData>(<%numOfEqs%>);
                MeasureTime::addResultContentBlock("<%dotPath(modelInfo.name)%>","profileBlocks",&measureTimeProfileBlocksArray);
                measuredProfileBlockStartValues = MeasureTime::getZeroValues();
                measuredProfileBlockEndValues = MeasureTime::getZeroValues();

                for(int i = 0; i < <%numOfEqs%>; i++)
                {
                    ostringstream ss;
                    ss << i;
                    measureTimeProfileBlocksArray[i] = MeasureTimeData(ss.str());
                }
                #endif //MEASURETIME_PROFILEBLOCKS

                #ifdef MEASURETIME_MODELFUNCTIONS
                MeasureTime::addResultContentBlock("<%dotPath(modelInfo.name)%>","functions_HPCOM",&measureTimeArrayHpcom);
                measureTimeArrayHpcom = std::vector<MeasureTimeData>(<%getConfigInt(NUM_PROC)%>);

                <%List.intRange(getConfigInt(NUM_PROC)) |> threadIdx => 'measureTimeArrayHpcom[<%intSub(threadIdx,1)%>] = MeasureTimeData("evaluateODE_thread<%threadIdx%>");'; separator="\n"%>

                MeasureTime::addResultContentBlock("<%dotPath(modelInfo.name)%>","functions",&measureTimeFunctionsArray);
                measureTimeFunctionsArray = std::vector<MeasureTimeData>(4); //1 evaluateODE ; 2 evaluateAll; 3 writeOutput; 4 handleTimeEvents
                measuredFunctionStartValues = MeasureTime::getZeroValues();
                measuredFunctionEndValues = MeasureTime::getZeroValues();

                measureTimeFunctionsArray[0] = MeasureTimeData("evaluateODE");
                measureTimeFunctionsArray[1] = MeasureTimeData("evaluateAll_wo_ODE");
                measureTimeFunctionsArray[2] = MeasureTimeData("writeOutput");
                measureTimeFunctionsArray[3] = MeasureTimeData("handleTimeEvents");
                #endif //MEASURETIME_MODELFUNCTIONS
                >>
           %>

        //DAE's are not supported yet, Index reduction is enabled
        _dimAE = 0; // algebraic equations
        //Initialize the state vector
        SystemDefaultImplementation::initialize();
        //Instantiate auxiliary object for event handling functionality
        //_event_handling.getCondition =  boost::bind(&<%className%>::getCondition, this, _1);

        //Todo: reindex all arrays removed  // arrayReindex(modelInfo,useFlatArrayNotation)

        _functions = new Functions(_simTime,__z,__zDot,_initial,_terminate);
        <%hpcomConstructorExtension%>
      }

      /* Destructor */
      <%className%>::~<%className%>()
      {
        <%hpcomDestructorExtension%>
        deleteObjects();
      }

      void <%className%>::deleteObjects()
      {

        if(_functions != NULL)
          delete _functions;

        deleteAlgloopSolverVariables();
      }


      <%generateInitAlgloopsolverVariables(jacobianMatrixes,listAppend(allEquations,initialEquations),simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace,className)%>

      <%generateDeleteAlgloopsolverVariables(jacobianMatrixes,listAppend(allEquations,initialEquations),simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace,className)%>

      <%Update(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>

      <%DefaultImplementationCode(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
      <%checkForDiscreteEvents(discreteModelVars,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace,useFlatArrayNotation)%>
      <%giveZeroFunc1(zeroCrossings,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>

      <%setConditions(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace)%>
      <%geConditions(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace)%>
      <%isConsistent(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace)%>

      <%generateStepCompleted(listAppend(allEquations,initialEquations),simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>

      <%generateStepStarted(listAppend(allEquations,initialEquations),simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation)%>

      <%generatehandleTimeEvent(timeEvents, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")))%>
      <%generateDimTimeEvent(listAppend(allEquations,initialEquations),simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace)%>
      <%generateTimeEvent(timeEvents, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, true)%>

      <%isODE(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace)%>
      <%DimZeroFunc(simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace)%>

      <%getCondition(zeroCrossings,whenClauses,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
      <%handleSystemEvents(zeroCrossings,whenClauses,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace)%>
      <%saveAll(modelInfo,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace,stateDerVectorName,useFlatArrayNotation)%>

      <%LabeledDAE(modelInfo.labels,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>
      <%giveVariables(modelInfo,context,useFlatArrayNotation,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace,stateDerVectorName)%>
      <%extraFuncs%>
      >>
  end match
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
          ,<%initializeBarrierByName("levelBarrier","",getConfigInt(NUM_PROC),type)%>
          >>
        else ""
    case SOME(hpcOmSchedule as TASKDEPSCHEDULE(__)) then
      match type
        case ("tbb") then
          <<
          ,_tbbGraph()
          ,_tbbStartNode(_tbbGraph)
          ,_tbbNodeList(<%listLength(hpcOmSchedule.tasks)%>,NULL)
          >>
        else ""
      end match
    else ""
  end match
end getHpcomMemberVariableDefinition;

template getHpcomConstructorExtension(Option<Schedule> hpcOmScheduleOpt, String modelNamePrefixStr, String fullModelName)
::=
  let type = getConfigString(HPCOM_CODE)
  match hpcOmScheduleOpt
    case SOME(hpcOmSchedule as LEVELSCHEDULE(useFixedAssignments=true)) then
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
            measureTimeSchedulerArrayHpcom = std::vector<MeasureTimeData>(<%listLength(hpcOmSchedule.tasksOfLevels)%>);
            measuredSchedulerStartValues = MeasureTime::getZeroValues();
            measuredSchedulerEndValues = MeasureTime::getZeroValues();
            <%List.intRange(listLength(hpcOmSchedule.tasksOfLevels)) |> levelIdx => 'measureTimeSchedulerArrayHpcom[<%intSub(levelIdx,1)%>] = MeasureTimeData("evaluateODE_level_<%levelIdx%>");'; separator="\n"%>
            #endif //MEASURETIME_MODELFUNCTIONS
            >>
          %>
          >>
        else ""
      end match
    case SOME(hpcOmSchedule as THREADSCHEDULE(__)) then
      let initlocks = hpcOmSchedule.outgoingDepTasks |> task => initializeLockByDepTask(task, "lock", type); separator="\n"
      let assignLocks = hpcOmSchedule.outgoingDepTasks |> task => assignLockByDepTask(task, "lock", type); separator="\n"
      match type
        case ("openmp") then
          let threadFuncs = arrayList(hpcOmSchedule.threadTasks) |> tt hasindex i0 fromindex 0 => generateThread(i0, type, modelNamePrefixStr,"evaluateThreadFunc"); separator="\n"
          <<
          <%threadFuncs%>
          <%initlocks%>
          >>
        case ("mpi") then
          <<
          //MF: Initialize MPI related stuff - nothing todo?
          >>
        else
          let threadFuncs = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => generateThread(i0, type, modelNamePrefixStr,"evaluateThreadFunc"); separator="\n"
          let threadLocksInit = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => initializeLockByLockName(i0, "th_lock", type); separator="\n"
          let threadLocksInit1 = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => initializeLockByLockName(i0, "th_lock1", type); separator="\n"
          let threadAssignLocks = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => assignLockByLockName(i0, "th_lock", type); separator="\n"
          let threadAssignLocks1 = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => assignLockByLockName(i0, "th_lock1", type); separator="\n"
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
    case SOME(hpcOmSchedule as TASKDEPSCHEDULE(__)) then
      match type
        case ("tbb") then
          let tbbVars = generateTbbConstructorExtension(hpcOmSchedule.tasks, modelNamePrefixStr)
          <<
          <%tbbVars%>
          >>
        else ""
    else ""
  end match
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
          //_evaluateBarrier.wait();
          _levelBarrier.wait();
          //_evaluateBarrier.wait();
          _levelBarrier.wait();
          >>
        else ""
    case SOME(hpcOmSchedule as THREADSCHEDULE(__)) then
      let destroylocks = hpcOmSchedule.outgoingDepTasks |> task => destroyLockByDepTask(task, "lock", type); separator="\n"
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
          let destroyThreads = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => function_HPCOM_destroyThread(i0, type); separator="\n"
          let threadLocksDel = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => destroyLockByLockName(i0, "th_lock", type); separator="\n"
          let threadLocksDel1 = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => destroyLockByLockName(i0, "th_lock1", type); separator="\n"
          let joinThreads = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => function_HPCOM_joinThread(i0, type); separator="\n"
          let threadReleaseLocks = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => releaseLockByLockName(i0, "th_lock", type); separator="\n"
          <<
          terminateThreads = true;
          <%threadReleaseLocks%>
          <%joinThreads%>
          <%destroylocks%>
          <%threadLocksDel%>
          <%threadLocksDel1%>
          <%destroyThreads%>
          >>
    case SOME(hpcOmSchedule as TASKDEPSCHEDULE(__)) then
      match type
        case ("tbb") then
          <<
          for(std::vector<tbb::flow::continue_node<tbb::flow::continue_msg>* >::iterator it = _tbbNodeList.begin(); it != _tbbNodeList.end(); it++)
            delete *it;
          >>
        else ""
    else ""
  end match
end getHpcomDestructorExtension;


template update(list<SimEqSystem> allEquationsPlusWhen, list<SimWhenClause> whenClauses, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Context context, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let &varDecls = buffer "" /*BUFD*/

  match simCode
    case SIMCODE(modelInfo = MODELINFO(__)) then
      let parCode = generateParallelEvaluateOde(allEquationsPlusWhen, odeEquations, modelInfo.name, whenClauses, simCode, extraFuncs ,extraFuncsDecl, extraFuncsNamespace, hpcOmSchedule, context, lastIdentOfPath(modelInfo.name), useFlatArrayNotation)
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
                 list<SimWhenClause> whenClauses, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Option<Schedule> hpcOmScheduleOpt, Context context,
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

  match hpcOmScheduleOpt
    case SOME(hpcOmSchedule as EMPTYSCHEDULE(__)) then
        <<
        <%CodegenCpp.createEvaluate(odeEquations, whenClauses, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, context, boolNot(stringEq(getConfigString(PROFILING_LEVEL),"none")))%>
        >>
    case SOME(hpcOmSchedule as LEVELSCHEDULE(useFixedAssignments=false, tasksOfLevels=tasksOfLevels)) then
      let odeEqs = tasksOfLevels |> tasks => function_HPCOM_Level(allEquationsPlusWhen, tasks, type, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"

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
   case SOME(hpcOmSchedule as LEVELSCHEDULE(useFixedAssignments=true, tasksOfLevels=tasksOfLevels)) then
      match type
        case ("pthreads")
        case ("pthreads_spin") then
          let &mainThreadCode = buffer "" /*BUFD*/
          let eqsFuncs = arrayList(HpcOmScheduler.convertFixedLevelScheduleToTaskLists(hpcOmSchedule, getConfigInt(NUM_PROC))) |> tasks hasindex i0 fromindex 0 => generateLevelFixedCodeForThread(allEquationsPlusWhen, tasks, i0, type, &varDecls, name, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, &mainThreadCode, useFlatArrayNotation); separator="\n"
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
   case SOME(hpcOmSchedule as THREADSCHEDULE(__)) then
      match type
        case ("openmp") then
          let taskEqs = function_HPCOM_Thread(allEquationsPlusWhen,hpcOmSchedule.threadTasks, type, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
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
          let threadFuncs = List.intRange(arrayLength(hpcOmSchedule.threadTasks)) |> threadIdx => generateThreadFunc(allEquationsPlusWhen, arrayGet(hpcOmSchedule.threadTasks, threadIdx), type, intSub(threadIdx, 1), modelNamePrefixStr, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, &mainThreadCode, useFlatArrayNotation); separator="\n"
          let threadAssignLocks1 = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => assignLockByLockName(i0, "th_lock1", type); separator="\n"
          let threadReleaseLocks = List.rest(arrayList(hpcOmSchedule.threadTasks)) |> tt hasindex i0 fromindex 1 => releaseLockByLockName(i0, "th_lock", type); separator="\n"
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
    case SOME(hpcOmSchedule as TASKDEPSCHEDULE(__)) then
      match type
        case ("openmp") then
          let taskEqs = function_HPCOM_TaskDep(hpcOmSchedule.tasks, allEquationsPlusWhen, type, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
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

          let taskFuncs = function_HPCOM_TaskDep_voidfunc(hpcOmSchedule.tasks, allEquationsPlusWhen,type, name, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
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

template function_HPCOM_Level(list<SimEqSystem> allEquationsPlusWhen, TaskList tasksOfLevel, String iType, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  match(tasksOfLevel)
    case(PARALLELTASKLIST(__)) then
      let odeEqs = tasks |> task => function_HPCOM_Level0(allEquationsPlusWhen,task,iType, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
      <<
      #pragma omp sections
      {
        <%odeEqs%>
      }
      >>
    case(SERIALTASKLIST(__)) then
      let odeEqs = tasks |> task => function_HPCOM_Level0(allEquationsPlusWhen,task,iType, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation); separator="\n"
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
end function_HPCOM_Level;

template function_HPCOM_Level0(list<SimEqSystem> allEquationsPlusWhen, Task iTask, String iType, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Boolean useFlatArrayNotation)
::=
  <<
  #pragma omp section
  {
    <%function_HPCOM_Task(allEquationsPlusWhen,iTask,iType, &varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation)%>
  }
  >>
end function_HPCOM_Level0;

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
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  equation_function_call(eq, context, &varDecls /*BUFC*/, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, "evaluate")
/*  match eq
  case e as SES_SIMPLE_ASSIGN(__) then
    let &varDeclsLocal = buffer "" BUFL
    let eqText = equation_(eq,context,&varDeclsLocal,simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, useFlatArrayNotation)
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
      let commInfoStr = printCommunicationInfoVariables(depTask.communicationInfo)
      <<
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

  let &additionalLinkerFlags_MSVC = buffer ""

  CodegenCpp.simulationMakefile(target, simCode, extraFuncs ,extraFuncsDecl, extraFuncsNamespace, additionalLinkerFlags_GCC,
                                additionalCFlags_MSVC, additionalCFlags_GCC,
                                additionalLinkerFlags_MSVC, Flags.isSet(Flags.USEMPI))
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
    //Using optimized variables
    /*parameter real vars*/
    <%vars.paramVars |> var =>
      MemberVariableDefine2(var, "parameters", hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
      ;separator="\n"%>
    /*parameter int vars*/
    <%vars.intParamVars |> var =>
      MemberVariableDefine("int", var, "intVariables.parameters", hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
      ;separator="\n"%>
    /*parameter bool vars*/
    <%vars.boolParamVars |> var =>
      MemberVariableDefine("bool",var, "boolVariables.parameters", hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
      ;separator="\n"%>
    <%vars.stringParamVars |> var =>
      MemberVariableDefine("string",var, "stringVariables.parameters", hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
      ;separator="\n"%>
    <%vars.stringAliasVars |> var =>
      MemberVariableDefine("string",var, "stringVariables.AliasVars", hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
      ;separator="\n"%>
    <%vars.extObjVars |> var =>
      MemberVariableDefine("void*",var, "extObjVars", hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
      ;separator="\n"%>
    >>
  end match
end MemberVariable;

template MemberVariablePreVariables(ModelInfo modelInfo, Option<MemoryMap> hpcOmMemory, Boolean useFlatArrayNotation, Boolean createConstructorDeclaration)
 "Define membervariable in simulation file."
::=
  match modelInfo
    case MODELINFO(vars=SIMVARS(__)) then
    <<
    //Variables saved for pre, edge and change operator
    <%vars.algVars |> var =>
      MemberVariableDefine2(var, "algebraics", hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
      ;separator="\n"%>
    <%vars.discreteAlgVars |> var =>
      MemberVariableDefine2(var, "algebraics", hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
      ;separator="\n"%>
    <%vars.boolAlgVars |> var =>
      MemberVariableDefine("bool",var, "boolVariables.algebraics", hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
      ;separator="\n"%>
    <%vars.stringAlgVars |> var =>
      MemberVariableDefine("string",var, "stringVariables.algebraics", hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
      ;separator="\n"%>
    <%vars.intAlgVars |> var =>
      MemberVariableDefine("int", var, "intVariables.algebraics", hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
      ;separator="\n"%>
    /*alias real vars*/
    <%vars.aliasVars |> var =>
      MemberVariableDefine2(var, "aliasVars", hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
      ;separator="\n"%>
    /*alias int vars*/
    <%vars.intAliasVars |> var =>
      MemberVariableDefine("int", var, "intVariables.AliasVars", hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
      ;separator="\n"%>
    /*alias bool vars*/
    <%vars.boolAliasVars |> var =>
      MemberVariableDefine("bool ",var, "boolVariables.AliasVars", hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
      ;separator="\n"%>
    /*mixed array variables*/
    <%vars.mixedArrayVars |> arrVar =>
      MemberVariableDefine2(arrVar, "mixed", hpcOmMemory, useFlatArrayNotation, createConstructorDeclaration)
      ;separator="\n"%>
    >>
  end match
end MemberVariablePreVariables;

template MemberVariableDefine(String type, SimVar simVar, String arrayName, Option<MemoryMap> hpcOmMemoryOpt, Boolean useFlatArrayNotation, Boolean createConstructorDeclaration)
::=
  match simVar
    case simVar as SIMVAR(name=varName,numArrayElement={},arrayCref=NONE()) then
      if(HpcOmMemory.useHpcomMemoryOptimization(hpcOmMemoryOpt)) then
        match(hpcOmMemoryOpt)
          case SOME(hpcOmMemory) then
            <<
            // case 2 MemberVariableDefine
            <%MemberVariableDefine3(HpcOmMemory.getPositionMappingByArrayName(hpcOmMemory,varName), simVar, useFlatArrayNotation, createConstructorDeclaration)%>
            >>
        end match
      else
        <<
        <%if createConstructorDeclaration then '' else '<%type%> <%cref(simVar.name,useFlatArrayNotation)%>; //no cacheMap defined'%>
        >>
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(_),numArrayElement=num)
    case v as SIMVAR(name=CREF_QUAL(__),arrayCref=SOME(arrayCrefLocal),numArrayElement=num) then
      let &dims = buffer "" /*BUFD*/
      let arrayName = arraycref2(name,dims)
      let typeString = variableType(type_)
      let arraysize = arrayextentDims(name,v.numArrayElement)
      let varType = variableType(type_)
      if(HpcOmMemory.useHpcomMemoryOptimization(hpcOmMemoryOpt)) then
        match dims
          case "0" then
            match(hpcOmMemoryOpt)
              case SOME(hpcOmMemory) then
                <<
                <%MemberVariableDefine3(HpcOmMemory.getPositionMappingByArrayName(hpcOmMemory,name), simVar, useFlatArrayNotation, createConstructorDeclaration)%>
                >>
            end match
          else
            match(hpcOmMemoryOpt)
              case SOME(hpcOmMemory) then
                let varDeclarations = HpcOmMemory.expandCref(name,num) |> crefLocal => MemberVariableDefine4(HpcOmMemory.getPositionMappingByArrayName(hpcOmMemory,crefLocal), crefLocal, type_, useFlatArrayNotation, createConstructorDeclaration); separator="\n"
                <<
                // case 3 MemberVariableDefine dims:<%dims%> nums:<%num%>
                <%varDeclarations%>
                >>
            end match
        end match
      else
        match dims
          case "0" then
            <<
            <%if createConstructorDeclaration then '' else '<%varType%> <%arrayName%>; //no cacheMap defined' %>
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
  end match
end MemberVariableDefine;

template MemberVariableDefine2(SimVar simVar, String arrayName, Option<MemoryMap> hpcOmMemoryOpt, Boolean useFlatArrayNotation, Boolean createConstructorDeclaration)
::=
  match simVar
    case SIMVAR(numArrayElement={},arrayCref=NONE(),name=CREF_IDENT(subscriptLst=_::_)) then ''

    case simVar as SIMVAR(name=varName,numArrayElement={},arrayCref=NONE()) then
      if(HpcOmMemory.useHpcomMemoryOptimization(hpcOmMemoryOpt)) then
        match(hpcOmMemoryOpt)
          case SOME(hpcOmMemory) then
            <<
            <%MemberVariableDefine3(HpcOmMemory.getPositionMappingByArrayName(hpcOmMemory,varName), simVar, useFlatArrayNotation, createConstructorDeclaration)%>
            >>
        end match
        else
          <<
          <%if createConstructorDeclaration then '' else '<%variableType(simVar.type_)%> <%cref(simVar.name,useFlatArrayNotation)%>; //no cacheMap defined'%>
          >>
    case v as SIMVAR(name=CREF_IDENT(__),arrayCref=SOME(arrayCrefLocal),numArrayElement=num,type_=varType) then
      let &dims = buffer "" /*BUFD*/
      let arrayName = arraycref2(name,dims)
      let typeString = variableType(type_)
      let arraysize = arrayextentDims(name,v.numArrayElement)
      match dims
        case "0" then
          if(HpcOmMemory.useHpcomMemoryOptimization(hpcOmMemoryOpt)) then
            match(hpcOmMemoryOpt)
              case SOME(hpcOmMemory) then
                <<
                <%MemberVariableDefine3(HpcOmMemory.getPositionMappingByArrayName(hpcOmMemory,name), simVar, useFlatArrayNotation, createConstructorDeclaration)%>
                >>
            end match
          else
            <<
            <%if createConstructorDeclaration then '' else '<%typeString%> <%arrayName%>; //no cacheMap defined' %>
            >>
        else
          if(HpcOmMemory.useHpcomMemoryOptimization(hpcOmMemoryOpt)) then
            match(hpcOmMemoryOpt)
              case SOME(hpcOmMemory) then
                let varDeclarations = HpcOmMemory.expandCref(arrayCrefLocal,num) |> crefLocal => MemberVariableDefine4(HpcOmMemory.getPositionMappingByArrayName(hpcOmMemory,crefLocal), crefLocal, varType, useFlatArrayNotation, createConstructorDeclaration); separator="\n"
                <<
                // case 2 MemberVariableDefine2
                <%varDeclarations%>
                >>
            end match
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
      match dims
        case "0" then
          if(HpcOmMemory.useHpcomMemoryOptimization(hpcOmMemoryOpt)) then
            match(hpcOmMemoryOpt)
              case SOME(hpcOmMemory) then
                <<
                <%MemberVariableDefine3(HpcOmMemory.getPositionMappingByArrayName(hpcOmMemory,name), simVar, useFlatArrayNotation, createConstructorDeclaration)%>
                >>
            end match
          else
            <<
            <%if createConstructorDeclaration then '' else '<%typeString%> <%arrayName%>; //no cacheMap defined' %>
            >>
        else
          if(HpcOmMemory.useHpcomMemoryOptimization(hpcOmMemoryOpt)) then
            match(hpcOmMemoryOpt)
              case SOME(hpcOmMemory) then
               let varDeclarations = HpcOmMemory.expandCref(name,num) |> crefLocal => MemberVariableDefine4(HpcOmMemory.getPositionMappingByArrayName(hpcOmMemory,crefLocal), crefLocal, varType, useFlatArrayNotation, createConstructorDeclaration); separator="\n"
               <<
               // case 3 MemberVariableDefine2 dims:<%dims%> nums:<%num%>
               <%varDeclarations%>
               >>
            end match
          else
            <<
            <%if createConstructorDeclaration then '' else 'StatArrayDim<%dims%><<%typeString%>,<%arraysize%>> <%arrayName%>; //no cacheMap defined' %>
            >>
       end match
    /*special case for varibales that marked as array but are not arrays */
    case SIMVAR(numArrayElement=_::_,type_=varType,name=varName) then
      let& dims = buffer "" /*BUFD*/
      let varNameStr = arraycref2(name,dims)
      let varTypeStr = variableType(type_)
      match dims
        case "0" then (if createConstructorDeclaration then '' else (
          if(HpcOmMemory.useHpcomMemoryOptimization(hpcOmMemoryOpt)) then
            match(hpcOmMemoryOpt)
              case SOME(hpcOmMemory) then
                <<
                <%MemberVariableDefine4(HpcOmMemory.getPositionMappingByArrayName(hpcOmMemory,varName), varName, varType, useFlatArrayNotation, createConstructorDeclaration)%>
                >>
            end match
          else
            <<
            <%varTypeStr%> <%varNameStr%>;
            >>
          )
        )
        else ''
      end match
  end match
end MemberVariableDefine2;

template MemberVariableDefine3(Option<tuple<Integer,Integer>> optVarArrayAssignment, SimVar simVar, Boolean useFlatArrayNotation, Boolean createConstructorDeclaration)
::=
  match optVarArrayAssignment
    case SOME((varIdx, arrayIdx)) then
      match simVar
        case SIMVAR(__) then
          <<
          <%if createConstructorDeclaration then '//,<%cref(name, useFlatArrayNotation)%>(varArray<%arrayIdx%>[<%varIdx%>])'
            else '#define <%cref(name, useFlatArrayNotation)%> varArray<%arrayIdx%>[<%varIdx%>] //<%variableType(type_)%>& <%cref(name, useFlatArrayNotation)%>;// = varArray<%arrayIdx%>[<%varIdx%>] - MemberVariableDefine3' %>
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
      <%if createConstructorDeclaration then '//,<%cref(varName,useFlatArrayNotation)%>(varArray<%arrayIdx%>[<%varIdx%>])'
        else '#define <%cref(varName,useFlatArrayNotation)%> varArray<%arrayIdx%>[<%varIdx%>] //<%variableType(type_)%>& <%cref(varName,useFlatArrayNotation)%>;// = varArray<%arrayIdx%>[<%varIdx%>] - MemberVariableDefine4' %>
      >>
    else
      <<
      <%if createConstructorDeclaration then '/* no varIdx found for variable <%cref(varName,useFlatArrayNotation)%> */' else '<%variableType(type_)%> <%cref(varName,useFlatArrayNotation)%>;'%>
      >>
  end match
end MemberVariableDefine4;

annotation(__OpenModelica_Interface="backend");
end CodegenCppHpcom;
