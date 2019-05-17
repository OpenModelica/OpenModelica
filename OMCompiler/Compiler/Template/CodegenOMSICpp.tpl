// This file defines templates for transforming Modelica/MetaModelica code to FMU
// code. They are used in the code generator phase of the compiler to write
// target code.
//
// There are one root template intended to be called from the code generator:
// translateModel. These template do not return any
// result but instead write the result to files. All other templates return
// text and are used by the root templates (most of them indirectly).
//
// To future maintainers of this file:
//
// - A line like this
//     # var = "" /*BUFD*/
//   declares a text buffer that you can later append text to. It can also be
//   passed to other templates that in turn can append text to it. In the new
//   version of Susan it should be written like this instead:
//     let &var = buffer ""
//
// - A line like this
//     ..., Text var /*BUFP*/, ...
//   declares that a template takes a text buffer as input parameter. In the
//   new version of Susan it should be written like this instead:
//     ..., Text &var, ...
//
// - A line like this:
//     ..., var /*BUFC*/, ...
//   passes a text buffer to a template. In the new version of Susan it should
//   be written like this instead:
//     ..., &var, ...
//
// - Style guidelines:
//
//   - Try (hard) to limit each row to 80 characters
//
//   - Code for a template should be indented with 2 spaces
//
//     - Exception to this rule is if you have only a single case, then that
//       single case can be written using no indentation
//
//       This single case can be seen as a clarification of the input to the
//       template
//
//   - Code after a case should be indented with 2 spaces if not written on the
//     same line

package CodegenOMSICpp

import interface SimCodeTV;
import interface SimCodeBackendTV;
import CodegenUtil.*;
import CodegenCpp.*; //unqualified import, no need the CodegenC is optional when calling a template; or mandatory when the same named template exists in this package (name hiding)
import CodegenCppCommon.*;
import CodegenFMU.*;
import CodegenCppInit;
import CodegenFMUCommon;
import CodegenFMU2;
import CodegenOMSI_common.*;

template translateModel(SimCode simCode, String FMUVersion, String FMUType)
 "Generates C++ code and Makefile for compiling an OSU of a Modelica model.
  Calls CodegenCpp.translateModel for the actual model code."
::=
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
  let guid = getUUIDStr()
  let target  = simulationCodeTarget()
  let stateDerVectorName = "__zDot"
  let &extraFuncs = buffer "" /*BUFD*/
  let &extraFuncsDecl = buffer "" /*BUFD*/
  let &complexStartExpressions = buffer ""

  let numRealVars = numRealvars(modelInfo)
  let numIntVars = numIntvars(modelInfo)
  let numBoolVars = numBoolvars(modelInfo)
  let numStringVars = numStringvars(modelInfo)


  let cpp = CodegenCpp.translateModel(simCode)
  let()= textFile(osuModelCppFile(simCode, extraFuncs, extraFuncsDecl, "",guid, FMUVersion), 'OMCpp<%fileNamePrefix%>OMSU.cpp')

  let()= textFile(fmudeffile(simCode, FMUVersion), '<%fileNamePrefix%>.def')
  let()= textFile(osuMakefile(target,simCode, extraFuncs, extraFuncsDecl, "", FMUVersion, "", "", "", "",false), '<%fileNamePrefix%>.makefile')
  let()= textFile(fmuCalcHelperMainfile(simCode), 'OMCpp<%fileNamePrefix%>CalcHelperMain.cpp')
  let()= textFile(simulationFactoryFile(simCode , &extraFuncs , &extraFuncsDecl, ""),'OMCpp<%fileNamePrefix%>FactoryExport.cpp')
  let()= textFile(simulationOSUMainRunScript(simCode , &extraFuncs , &extraFuncsDecl, "", "", "", "exec"), '<%fileNamePrefix%><%simulationMainRunScriptSuffix(simCode , &extraFuncs , &extraFuncsDecl, "")%>')
 ""
   // Return empty result since result written to files directly
end translateModel;


template simulationFactoryFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Generates code for header file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO()) then
  <<

  <%insertCopyrightOpenModelica()%>

  #if defined (RUNTIME_STATIC_LINKING)
  #include <Core/System/FactoryExport.h>
  #include <Core/DataExchange/SimData.h>
  #include <Core/System/SimVars.h>

    shared_ptr<IMixedSystem> createOSU(shared_ptr<IGlobalSettings> globalSettings,omsi_t* omsu)
    {
       shared_ptr<IMixedSystem> osu =shared_ptr<IMixedSystem>(new <%lastIdentOfPath(modelInfo.name)%>Initialize(globalSettings,omsu) );
       return osu;
    }
    shared_ptr<INonLinSolverSettings> createNewtonSettings()
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"Selected nonlin solver is not yet for omsi cpp available");
    }
    shared_ptr<INonLinSolverSettings> createKinsolSettings()
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"Selected nonlin solver is not yet for omsi cpp available");
    }
    shared_ptr<INonLinearAlgLoopSolver> createNewtonSolver(shared_ptr<INonLinSolverSettings> solver_settings,shared_ptr<INonLinearAlgLoop> algLoop)
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"Selected nonlin solver is not yet for omsi cpp available");
    }
    shared_ptr<INonLinearAlgLoopSolver> createKinsolSolver(shared_ptr<INonLinSolverSettings> solver_settings,shared_ptr<INonLinearAlgLoop> algLoop)
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"Selected nonlin solver is not yet for omsi cpp available");
    }
    
    shared_ptr<ILinSolverSettings> createLinearSolverSettings()
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"Selected lin solver is not yet for omsi cpp available");
    }
    shared_ptr<ILinearAlgLoopSolver> createLinearSolver(shared_ptr<ILinSolverSettings> solver_settings,shared_ptr<ILinearAlgLoop> algLoop = shared_ptr<ILinearAlgLoop>())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"Selected lin solver is not yet for omsi cpp available");
    }
    shared_ptr<ILinSolverSettings> createDgesvSolverSettings()
    {
     throw ModelicaSimulationError(MODEL_FACTORY,"Selected lin solver is not yet for omsi cpp available");
    }
    shared_ptr<ILinearAlgLoopSolver> createDgesvSolver(shared_ptr<ILinSolverSettings> solver_settings,shared_ptr<ILinearAlgLoop> algLoop = shared_ptr<ILinearAlgLoop>())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"Selected lin solver is not yet for omsi cpp available");
    }
    
  #else

   BOOST_EXTENSION_TYPE_MAP_FUNCTION
  {
    typedef boost::extensions::factory<IMixedSystem,shared_ptr<IGlobalSettings> > system_factory;
    types.get<std::map<std::string, system_factory> >()["<%lastIdentOfPath(modelInfo.name)%>"]
      .system_factory::set<<%lastIdentOfPath(modelInfo.name)%>Initialize>();
  }
  #endif
  >>
end simulationFactoryFile;


template fmuCalcHelperMainfile(SimCode simCode)
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__)) then
    <<

    <%insertCopyrightOpenModelica()%>

    /*****************************************************************************
    *
    * Helper file that includes all generated calculation files, except the alg loops.
    * This file is generated by the OpenModelica Compiler and produced to speed-up the compile time.
    *
    *****************************************************************************/
    /*Modelica precompiled header*/
    #include <Core/ModelicaDefine.h>
    #include <Core/Modelica.h>
    //OpenModelcia Simulation Interface Header
    #include <omsi.h>
    #include <Core/System/FactoryExport.h>
    #include <Core/DataExchange/SimData.h>
    #include <Core/System/SimVars.h>
    #include <Core/System/DiscreteEvents.h>
    #include <Core/System/EventHandling.h>
    #include <Core/DataExchange/XmlPropertyReader.h>
    #include <Core/Utils/extension/logger.hpp>

    #include "OMCpp<%fileNamePrefix%>Types.h"
    #include "OMCpp<%fileNamePrefix%>.h"
    #include "OMCpp<%fileNamePrefix%>Functions.h"
    #include "OMCpp<%fileNamePrefix%>Jacobian.h"
    #include "OMCpp<%fileNamePrefix%>Mixed.h"
    #include "OMCpp<%fileNamePrefix%>StateSelection.h"
    #include "OMCpp<%fileNamePrefix%>Initialize.h"

    #include "OMCpp<%fileNamePrefix%>AlgLoopMain.cpp"
    #include "OMCpp<%fileNamePrefix%>Mixed.cpp"
    #include "OMCpp<%fileNamePrefix%>Functions.cpp"
    <%if(boolOr(Flags.isSet(Flags.HARDCODED_START_VALUES), Flags.isSet(Flags.GEN_DEBUG_SYMBOLS))) then
    <<
    #include "OMCpp<%fileNamePrefix%>InitializeParameter.cpp"
    #include "OMCpp<%fileNamePrefix%>InitializeAlgVars.cpp"
    >>
    %>
    #include "OMCpp<%fileNamePrefix%>Initialize.cpp"
    #include "OMCpp<%fileNamePrefix%>Jacobian.cpp"
    #include "OMCpp<%fileNamePrefix%>StateSelection.cpp"
    #include "OMCpp<%fileNamePrefix%>.cpp"
    #include "OMCpp<%fileNamePrefix%>OMSU.cpp"
    #include "OMCpp<%fileNamePrefix%>FactoryExport.cpp"
    #include "OMCpp<%fileNamePrefix%>OMSIEquations.cpp"
    #include "OMCpp<%fileNamePrefix%>OMSIInitEquations.cpp"
    >>
end fmuCalcHelperMainfile;

template fmuWriteOutputHeaderFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Overrides code for writing simulation file. FMU does not write an output file"
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__),simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
  <<
  #pragma once

  // Dummy code for FMU that writes no output file
  class <%lastIdentOfPath(modelInfo.name)%>WriteOutput  : public IWriteOutput,public <%lastIdentOfPath(modelInfo.name)%>StateSelection
  {
   public:
    <%lastIdentOfPath(modelInfo.name)%>WriteOutput(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects): <%lastIdentOfPath(modelInfo.name)%>StateSelection(globalSettings, simObjects) {}
    virtual ~<%lastIdentOfPath(modelInfo.name)%>WriteOutput() {}

    virtual void writeOutput(const IWriteOutput::OUTPUT command = IWriteOutput::UNDEF_OUTPUT) {}
    virtual IHistory* getHistory() {return NULL;}

   protected:
    void initialize() {}
  };
  >>
end fmuWriteOutputHeaderFile;


template osuModelCppFile(SimCode simCode,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, String guid, String FMUVersion)
 "Generates code for OSU target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  let modelName = dotPath(modelInfo.name)
  let modelShortName = lastIdentOfPath(modelInfo.name)
  let modelLongName = System.stringReplace(modelName, ".", "_")
  <<
  <%insertCopyrightOpenModelica()%>

  /***********************************************/
  /**** define model identifier and unique id ***/
  /*********************************************/

  #define MODEL_IDENTIFIER <%modelLongName%>
  #define MODEL_IDENTIFIER_SHORT <%modelShortName%>
  #define MODEL_CLASS <%modelShortName%>FMU
  #define MODEL_GUID "{<%guid%>}"

  /*Modelica precompiled header*/
  #include <Core/ModelicaDefine.h>
  #include <Core/Modelica.h>

  <%ModelDefineData(modelInfo)%>

  //OpenModelica Simulation Interface
  #include <omsi.h>
  #include <fmi2/omsi_fmi2_me.h>
  //FMI2 interface
  #include "fmi2Functions.h"
  #include "fmi2FunctionTypes.h"
  #include "fmi2TypesPlatform.h"



  FMI2_Export const char* fmi2GetTypesPlatform()
  {
    return fmi2TypesPlatform;
  }

   FMI2_Export const char* fmi2GetVersion()
   {
     return fmi2Version;
   }

   FMI2_Export fmi2Status fmi2SetDebugLogging(fmi2Component c,fmi2Boolean loggingOn,size_t  nCategories,const fmi2String categories[])
   {
        return omsi_fmi2_set_debug_logging(c, loggingOn, nCategories, categories);
   }


   FMI2_Export fmi2Component fmi2Instantiate(fmi2String instanceName,fmi2Type   fmuType,fmi2String fmuGUID,fmi2String fmuResourceLocation,const fmi2CallbackFunctions* functions, fmi2Boolean visible,fmi2Boolean loggingOn)
   {
       return omsi_fmi2_instantiate(instanceName, fmuType, fmuGUID, fmuResourceLocation, functions, visible, loggingOn);
   }

   FMI2_Export void fmi2FreeInstance(fmi2Component c)
   {
      omsi_fmi2_free_instance(c);
   }

    FMI2_Export fmi2Status fmi2SetupExperiment(fmi2Component c,fmi2Boolean   toleranceDefined,fmi2Real      tolerance, fmi2Real      startTime, fmi2Boolean   stopTimeDefined, fmi2Real      stopTime)
    {
        return omsi_fmi2_setup_experiment(c, toleranceDefined, tolerance, startTime, stopTimeDefined, stopTime);
    }

    FMI2_Export fmi2Status fmi2EnterInitializationMode(fmi2Component c)
    {
       return omsi_fmi2_enter_initialization_mode(c);
    }

    FMI2_Export fmi2Status fmi2ExitInitializationMode(fmi2Component c)
    {
        return omsi_fmi2_exit_initialization_mode(c);
    }

    FMI2_Export fmi2Status fmi2Terminate(fmi2Component c)
    {
        return omsi_fmi2_terminate(c);
    }

    FMI2_Export fmi2Status fmi2Reset(fmi2Component c)
    {
        return omsi_fmi2_reset(c);
    }

    FMI2_Export fmi2Status fmi2GetReal(fmi2Component c, const fmi2ValueReference vr[],size_t nvr, fmi2Real value[])
    {
        return omsi_fmi2_get_real(c, vr, nvr, value);
    }

    FMI2_Export fmi2Status fmi2GetInteger(fmi2Component c, const fmi2ValueReference vr[],size_t nvr, fmi2Integer value[])
    {
        return omsi_fmi2_get_integer(c, vr, nvr, value);
    }

    FMI2_Export fmi2Status fmi2GetBoolean(fmi2Component c, const fmi2ValueReference vr[],size_t nvr, fmi2Boolean value[])
    {
        return omsi_fmi2_get_boolean(c, vr, nvr, value);
    }

    FMI2_Export fmi2Status fmi2GetString(fmi2Component c, const fmi2ValueReference vr[],size_t nvr, fmi2String value[])
    {
        return omsi_fmi2_get_string(c, vr, nvr, value);
    }

    FMI2_Export fmi2Status fmi2SetReal(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Real value[])
    {
        return omsi_fmi2_set_real(c, vr, nvr, value);
    }

    FMI2_Export fmi2Status fmi2SetInteger(fmi2Component c, const fmi2ValueReference vr[],size_t nvr, const fmi2Integer value[])
    {
        return omsi_fmi2_set_integer(c, vr, nvr, value);
    }

    FMI2_Export fmi2Status fmi2SetBoolean(fmi2Component c, const fmi2ValueReference vr[],size_t nvr, const fmi2Boolean value[])
    {
        return omsi_fmi2_set_boolean(c, vr, nvr, value);
    }

    FMI2_Export fmi2Status fmi2SetString(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2String value[])
    {
        return omsi_fmi2_set_string(c, vr, nvr, value);
    }

    FMI2_Export fmi2Status fmi2GetFMUstate(fmi2Component c, fmi2FMUstate* FMUstate)
    {
        return omsi_fmi2_get_fmu_state(c, FMUstate);
    }

    FMI2_Export fmi2Status fmi2SetFMUstate(fmi2Component c, fmi2FMUstate FMUstate)
    {
        return omsi_fmi2_set_fmu_state(c, FMUstate);
    }

    FMI2_Export fmi2Status fmi2FreeFMUstate(fmi2Component c, fmi2FMUstate* FMUstate)
    {
        return omsi_fmi2_free_fmu_state(c, FMUstate);
    }

    FMI2_Export fmi2Status fmi2SerializedFMUstateSize(fmi2Component c, fmi2FMUstate FMUstate,size_t* size)
    {
        return omsi_fmi2_serialized_fmu_state_size(c, FMUstate, size);
    }

    FMI2_Export fmi2Status fmi2SerializeFMUstate(fmi2Component c, fmi2FMUstate FMUstate,fmi2Byte serializedState[], size_t size)
    {
        return omsi_fmi2_serialize_fmu_state(c, FMUstate, serializedState, size);
    }

    FMI2_Export fmi2Status fmi2DeSerializeFMUstate(fmi2Component c, const fmi2Byte serializedState[],size_t size, fmi2FMUstate* FMUstate)
    {
        return omsi_fmi2_de_serialize_fmu_state(c, serializedState, size, FMUstate);
    }

    FMI2_Export fmi2Status fmi2GetDirectionalDerivative(fmi2Component c,const fmi2ValueReference vUnknown_ref[], size_t nUnknown,const fmi2ValueReference vKnown_ref[],   size_t nKnown, const fmi2Real dvKnown[], fmi2Real dvUnknown[])
    {
        return omsi_fmi2_get_directional_derivative(c, vUnknown_ref, nUnknown, vKnown_ref, nKnown, dvKnown, dvUnknown);
    }

    FMI2_Export fmi2Status fmi2EnterEventMode(fmi2Component c)
    {
        return omsi_fmi2_enter_event_mode(c);
    }

    FMI2_Export fmi2Status fmi2NewDiscreteStates(fmi2Component  c,fmi2EventInfo* fmiEventInfo)
    {
        return omsi_fmi2_new_discrete_state(c, fmiEventInfo);
    }

    FMI2_Export fmi2Status fmi2EnterContinuousTimeMode(fmi2Component c)
    {
        return omsi_fmi2_enter_continuous_time_mode(c);
    }

    FMI2_Export fmi2Status fmi2CompletedIntegratorStep(fmi2Component c,fmi2Boolean   noSetFMUStatePriorToCurrentPoint, fmi2Boolean*  enterEventMode, fmi2Boolean*   terminateSimulation)
    {
        return omsi_fmi2_completed_integrator_step(c, noSetFMUStatePriorToCurrentPoint,enterEventMode, terminateSimulation);
    }

    FMI2_Export fmi2Status fmi2SetTime(fmi2Component c, fmi2Real time)
    {
        return omsi_fmi2_set_time(c, time);
    }

    FMI2_Export fmi2Status fmi2SetContinuousStates(fmi2Component c, const fmi2Real x[],size_t nx)
    {
        return omsi_fmi2_set_continuous_states(c, x, nx);
    }

    FMI2_Export fmi2Status fmi2GetDerivatives(fmi2Component c, fmi2Real derivatives[], size_t nx)
    {
        return omsi_fmi2_get_derivatives(c, derivatives, nx);
    }

    FMI2_Export fmi2Status fmi2GetEventIndicators(fmi2Component c, fmi2Real eventIndicators[], size_t ni)
    {
        return omsi_fmi2_get_event_indicators(c, eventIndicators, ni);
    }

    FMI2_Export fmi2Status fmi2GetContinuousStates(fmi2Component c, fmi2Real x[],size_t nx)
    {
        return omsi_fmi2_get_continuous_states(c, x, nx);
    }

    FMI2_Export fmi2Status fmi2GetNominalsOfContinuousStates(fmi2Component c,fmi2Real x_nominal[],size_t nx)
    {
        return omsi_fmi2_get_nominals_of_continuous_states(c, x_nominal, nx);
    }
  >>
end osuModelCppFile;

template ModelDefineData(ModelInfo modelInfo)
 "Generates global data in simulation file."
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(stateVars = listStates)) then
  <<
  /* TODO: implement external functions in FMU wrapper for c++ target
  <%System.tmpTickReset(0)%>
  <%(functions |> fn => defineExternalFunction(fn) ; separator="\n")%>
  */
  >>
end ModelDefineData;

template DefineVariables(SimVar simVar, Boolean useFlatArrayNotation)
 "Generates code for defining variables in c file for FMU target. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  if stringEq(crefStr(name),"$dummy") then
  <<>>
  else if stringEq(crefStr(name),"der($dummy)") then
  <<>>
  else
  <<
  #define <%cref(name,useFlatArrayNotation)%>_ <%System.tmpTick()%> <%description%>
  >>
end DefineVariables;

template defineExternalFunction(Function fn)
 "Generates external function definitions."
::=
  match fn
    case EXTERNAL_FUNCTION(dynamicLoad=true) then
      let fname = extFunctionName(extName, language)
      <<
      #define $P<%fname%> <%System.tmpTick()%>
      >>
end defineExternalFunction;


template setDefaultStartValues(ModelInfo modelInfo)
 "Generates code in c file for function setStartValues() which will set start values for all variables."
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(numStateVars=numStateVars, numAlgVars= numAlgVars),vars=SIMVARS(__)) then
  <<
  // Set values for all variables that define a start value
  void setDefaultStartValues(ModelInstance *comp) {
  /*
  <%vars.stateVars |> var => initValsDefault(var,"realVars",0) ;separator="\n"%>
  <%vars.derivativeVars |> var => initValsDefault(var,"realVars",numStateVars) ;separator="\n"%>
  <%vars.algVars |> var => initValsDefault(var,"realVars",intMul(2,numStateVars)) ;separator="\n"%>
  <%vars.discreteAlgVars |> var => initValsDefault(var, "realVars", intAdd(intMul(2,numStateVars), numAlgVars)) ;separator="\n"%>
  <%vars.intAlgVars |> var => initValsDefault(var,"integerVars",0) ;separator="\n"%>
  <%vars.boolAlgVars |> var => initValsDefault(var,"booleanVars",0) ;separator="\n"%>
  <%vars.stringAlgVars |> var => initValsDefault(var,"stringVars",0) ;separator="\n"%>
  <%vars.paramVars |> var => initParamsDefault(var,"realParameter") ;separator="\n"%>
  <%vars.intParamVars |> var => initParamsDefault(var,"integerParameter") ;separator="\n"%>
  <%vars.boolParamVars |> var => initParamsDefault(var,"booleanParameter") ;separator="\n"%>
  <%vars.stringParamVars |> var => initParamsDefault(var,"stringParameter") ;separator="\n"%>
  */
  }
  >>
end setDefaultStartValues;

template setStartValues(ModelInfo modelInfo)
 "Generates code in c file for function setStartValues() which will set start values for all variables."
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(numStateVars=numStateVars, numAlgVars= numAlgVars),vars=SIMVARS(__)) then
  <<
  // Set values for all variables that define a start value
  void setStartValues(ModelInstance *comp) {
  /*
  <%vars.stateVars |> var => initVals(var,"realVars",0) ;separator="\n"%>
  <%vars.derivativeVars |> var => initVals(var,"realVars",numStateVars) ;separator="\n"%>
  <%vars.algVars |> var => initVals(var,"realVars",intMul(2,numStateVars)) ;separator="\n"%>
  <%vars.discreteAlgVars |> var => initVals(var, "realVars", intAdd(intMul(2,numStateVars), numAlgVars)) ;separator="\n"%>
  <%vars.intAlgVars |> var => initVals(var,"integerVars",0) ;separator="\n"%>
  <%vars.boolAlgVars |> var => initVals(var,"booleanVars",0) ;separator="\n"%>
  <%vars.stringAlgVars |> var => initVals(var,"stringVars",0) ;separator="\n"%>
  <%vars.paramVars |> var => initParams(var,"realParameter") ;separator="\n"%>
  <%vars.intParamVars |> var => initParams(var,"integerParameter") ;separator="\n"%>
  <%vars.boolParamVars |> var => initParams(var,"booleanParameter") ;separator="\n"%>
  <%vars.stringParamVars |> var => initParams(var,"stringParameter") ;separator="\n"%>
  */
  }
  >>
end setStartValues;

template initVals(SimVar var, String arrayName, Integer offset) ::=
  match var
    case SIMVAR(__) then
    if stringEq(crefStr(name),"$dummy") then
    <<>>
    else if stringEq(crefStr(name),"der($dummy)") then
    <<>>
    else
    let str = 'comp->fmuData->modelData.<%arrayName%>Data[<%intAdd(index,offset)%>].attribute.start'
    <<
      <%str%> =  comp->fmuData->localData[0]-><%arrayName%>[<%intAdd(index,offset)%>];
    >>
end initVals;

template initParams(SimVar var, String arrayName) ::=
  match var
    case SIMVAR(__) then
    let str = 'comp->fmuData->modelData.<%arrayName%>Data[<%index%>].attribute.start'
      '<%str%> = comp->fmuData->simulationInfo.<%arrayName%>[<%index%>];'
end initParams;


template initValsDefault(SimVar var, String arrayName, Integer offset) ::=
  match var
    case SIMVAR(index=index, type_=type_) then
    let str = 'comp->fmuData->modelData.<%arrayName%>Data[<%intAdd(index,offset)%>].attribute.start'
    match initialValue
      case SOME(v) then
      '<%str%> = <%initVal(v)%>;'
      case NONE() then
        match type_
          case T_INTEGER(__)
          case T_REAL(__)
          case T_ENUMERATION(__)
          case T_BOOL(__) then '<%str%> = 0;'
          case T_STRING(__) then '<%str%> = "";'
          else 'UNKOWN_TYPE'
end initValsDefault;

template initParamsDefault(SimVar var, String arrayName) ::=
  match var
    case SIMVAR(__) then
    let str = 'comp->fmuData->modelData.<%arrayName%>Data[<%index%>].attribute.start'
    match initialValue
      case SOME(v) then
      '<%str%> = <%initVal(v)%>;'
end initParamsDefault;

template initVal(Exp initialValue)
::=
  match initialValue
  case ICONST(__) then integer
  case RCONST(__) then real
  case SCONST(__) then '"<%Util.escapeModelicaStringToXmlString(string)%>"'
  case BCONST(__) then if bool then "1" else "0"
  case ENUM_LITERAL(__) then '<%index%>/*ENUM:<%dotPath(name)%>*/'
  else "*ERROR* initial value of unknown type"
end initVal;


template setExternalFunction(ModelInfo modelInfo)
 "Generates setString function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  let externalFuncs = setExternalFunctionsSwitch(functions)
  <<
  fmiStatus setExternalFunction(ModelInstance* c, const fmiValueReference vr, const void* value){
    switch (vr) {
    /*
        <%externalFuncs%>
    */
        default:
            return fmiError;
    }
    return fmiOK;
  }

  >>
end setExternalFunction;

template setExternalFunctionsSwitch(list<Function> functions)
 "Generates external function definitions."
::=
  (functions |> fn => setExternalFunctionSwitch(fn) ; separator="\n")
end setExternalFunctionsSwitch;

template setExternalFunctionSwitch(Function fn)
 "Generates external function definitions."
::=
  match fn
    case EXTERNAL_FUNCTION(dynamicLoad=true) then
      let fname = extFunctionName(extName, language)
      <<
      case $P<%fname%> : ptr_<%fname%>=(ptrT_<%fname%>)value; break;
      >>
end setExternalFunctionSwitch;

template accessFunctionsFMU1(SimCode simCode, String direction, String modelShortName, ModelInfo modelInfo)
 "Generates getters or setters for Real, Integer, Boolean, and String."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  let qualifier = if stringEq(direction, "set") then "const"
  <<
  <%accessVarsFunctionFMU1(simCode, direction, modelShortName, "Real", "double", "_pointerToRealVars")%>
  <%accessVarsFunctionFMU1(simCode, direction, modelShortName, "Integer", "int", "_pointerToIntVars")%>
  <%accessVarsFunctionFMU1(simCode, direction, modelShortName, "Boolean", "int", "_pointerToBoolVars")%>

  void <%modelShortName%>FMU::<%direction%>String(const unsigned int vr[], int nvr, <%qualifier%> string value[]) {
  }
  >>
end accessFunctionsFMU1;

template accessVarsFunctionFMU1(SimCode simCode, String direction, String modelShortName, String typeName, String typeImpl, String arrayName)
 "Generates get<%typeName%> or set<%typeName%> function."
::=
  let qualifier = if stringEq(direction, "set") then "const"
  <<
  void <%modelShortName%>FMU::<%direction%><%typeName%>(const unsigned int vr[], int nvr, <%qualifier%> <%typeImpl%> value[]) {
    for (int i = 0; i < nvr; i++)
    {
      <%if stringEq(direction, "get") then
        'value[i] = <%arrayName%>[vr[i]];'
        else '<%arrayName%>[vr[i]] = value[i];'
      %>
    }
  }
  >>
end accessVarsFunctionFMU1;

template accessFunctionsFMU2(SimCode simCode, String direction, String modelShortName, ModelInfo modelInfo)
 "Generates getters or setters for Real, Integer, Boolean, and String."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__), varInfo=VARINFO(numStateVars=numStateVars, numAlgVars=numAlgVars, numDiscreteReal=numDiscreteReal, numParams=numParams)) then
  <<
  <%accessVarsFunctionFMU2(simCode, direction, modelShortName, "Real", "Real", "double", intAdd(intAdd(intAdd(intMul(2, numStateVars), numAlgVars), numDiscreteReal), numParams), vars.aliasVars)%>
  <%accessVarsFunctionFMU2(simCode, direction, modelShortName, "Integer", "Int", "int", intAdd(listLength(vars.intAlgVars), listLength(vars.intParamVars)), vars.intAliasVars)%>
  <%accessVarsFunctionFMU2(simCode, direction, modelShortName, "Boolean", "Bool", "int", intAdd(listLength(vars.boolAlgVars), listLength(vars.boolParamVars)), vars.boolAliasVars)%>
  <%accessVarsFunctionFMU2(simCode, direction, modelShortName, "String", "String", "string", intAdd(listLength(vars.stringAlgVars), listLength(vars.stringParamVars)), vars.stringAliasVars)%>
  >>
end accessFunctionsFMU2;

template accessVarsFunctionFMU2(SimCode simCode, String direction, String modelShortName, String typeName, String pointerName, String typeImpl, Integer offset, list<SimVar> aliasVars)
 "Generates get<%typeName%> or set<%typeName%> function."
::=
  let qualifier = if stringEq(direction, "set") then "const"
  <<
  void <%modelShortName%>FMU::<%direction%><%typeName%>(const unsigned int vr[], int nvr, <%qualifier%> <%typeImpl%> value[]) {
    for (int i = 0; i < nvr; i++, vr++, value++) {
      // access variables and aliases in SimVars memory
      if (*vr < _dim<%typeName%>)
        <%if stringEq(direction, "get") then
        <<
        *value = _pointerTo<%pointerName%>Vars[*vr];
        >>
        else
        <<
        _pointerTo<%pointerName%>Vars[*vr] = *value;
        >>%>
      // convert negated aliases
      else switch (*vr) {
        <%aliasVars |> var => match var
          case SIMVAR(aliasvar=NEGATEDALIAS()) then
            accessVarFMU2(simCode, direction, var, offset)
          else ''
          end match; separator="\n"%>
        default:
          throw std::invalid_argument("<%direction%><%typeName%> with wrong value reference " + omcpp::to_string(*vr));
      }
    }
  }
  >>
end accessVarsFunctionFMU2;

template accessVarFMU2(SimCode simCode, String direction, SimVar simVar, Integer offset)
 "Generates a case statement accessing one variable."
::=
match simVar
  case SIMVAR(__) then
  let descName = System.stringReplace(crefStrNoUnderscore(name), "$", "_D_")
  let description = if comment then '/* <%descName%> "<%comment%>" */' else '/* <%descName%> */'
  let cppName = getCppName(simCode, simVar)
  let cppSign = getCppSign(simCode, simVar)
  if stringEq(direction, "get") then
  <<
  case <%intAdd(offset, index)%>: <%description%>
    *value = <%cppSign%><%cppName%>; break;
  >>
  else
  <<
  case <%intAdd(offset, index)%>: <%description%>
    <%cppName%> = <%cppSign%>*value; break;
  >>
end accessVarFMU2;

template getCppName(SimCode simCode, SimVar simVar)
  "Get name of variable in Cpp runtime, resolving aliases"
::=
match simVar
  case SIMVAR(__) then
    let actualName = cref1(name, simCode, "", "", "", contextOther, "", "", false)
    match aliasvar
      case ALIAS(__)
      case NEGATEDALIAS(__) then
        '<%cref1(varName, simCode, "", "", "", contextOther, "", "", false)%>'
      else
        '<%actualName%>'
end getCppName;

template getCppSign(SimCode simCode, SimVar simVar)
  "Get sign of variable in Cpp runtime, resolving aliases"
::=
match simVar
  case SIMVAR(type_=type_) then
    match aliasvar
      case NEGATEDALIAS(__) then
        match type_ case T_BOOL(__) then '!' else '-'
      else ''
end getCppSign;

template accessVecVarFMU2(String direction, SimVar simVar, Integer offset, String vecName)
 "Generates a case statement accessing one variable of a vector, neglecting $dummy state."
::=
match simVar
  case SIMVAR(__) then
  let descName = System.stringReplace(crefStrNoUnderscore(name), "$", "_D_")
  let description = if comment then '/* <%descName%> "<%comment%>" */' else '/* <%descName%> */'
  if stringEq(crefStr(name), "$dummy") then
  <<>>
  else if stringEq(crefStr(name), "der($dummy)") then
  <<>>
  else if stringEq(direction, "get") then
  <<
  case <%intAdd(offset, index)%>: <%description%>
    value[i] = <%vecName%>[<%index%>]; break;
  >>
  else
  <<
  case <%intAdd(offset, index)%>: <%description%>
    <%vecName%>[<%index%>] = value[i]; break;
  >>
end accessVecVarFMU2;

template osuMakefile(String target, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, String FMUVersion, String additionalLinkerFlags_GCC,
                            String additionalLinkerFlags_MSVC, String additionalCFlags_GCC, String additionalCFlags_MSVC, Boolean compileForMPI)
 "Generates the contents of the makefile for the simulation case. Copy libexpat & correct linux fmu"
::=

match getGeneralTarget(target)
case "msvc" then
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
  let dirExtra = if modelInfo.directory then '/LIBPATH:"<%modelInfo.directory%>"' //else ""
  let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
  let libsPos1 = if not dirExtra then libsStr //else ""
  let libsPos2 = if dirExtra then libsStr // else ""
  let ParModelicaLibs = if acceptParModelicaGrammar() then '-lOMOCLRuntime -lOpenCL' // else ""
  let extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then
    match s.method case "dassljac" then "-D_OMC_JACOBIAN "
  let modelName =  dotPath(modelInfo.name)
  let OMLibs = match makefileParams.platform case "win32" case "win64" then 'lib' case "linux64" then 'lib/x86_64-linux-gnu' else 'lib'
  let lapackDirWin = match makefileParams.platform case "win32" then '$(OMDEV)/tools/msys/mingw32/bin' case "win64" then '$(OMDEV)/tools/msys/mingw64/bin' else ''
  let libEnding = match makefileParams.platform case "win32" case "win64" then 'dll' else 'so'
  let star = match makefileParams.platform case "win32" case "win64" then '' else '*'
  <<
  # Makefile generated by OpenModelica
  OMHOME=<%makefileParams.omhome%>
  OMLIB=<%makefileParams.omhome%>/<%OMLibs%>
  # Simulations use -O3 by default
  SIM_OR_DYNLOAD_OPT_LEVEL=
  MODELICAUSERCFLAGS=
  CXX=cl
  EXEEXT=.exe
  DLLEXT=.dll
  include <%makefileParams.omhome%>/include/omc/omsicpp/ModelicaConfig_msvc.inc
  include <%makefileParams.omhome%>/include/omc/omsicpp/ModelicaLibraryConfig_msvc.inc
  # /Od - Optimization disabled
  # /EHa enable C++ EH (w/ SEH exceptions)
  # /fp:except - consider floating-point exceptions when generating code
  # /arch:SSE2 - enable use of instructions available with SSE2 enabled CPUs
  # /I - Include Directories
  # /DNOMINMAX - Define NOMINMAX (does what it says)
  # /TP - Use C++ Compiler
  !IF "$(PCH_FILE)" == ""
  CFLAGS=  $(SYSTEM_CFLAGS) /DRUNTIME_STATIC_LINKING /I"<%makefileParams.omhome%>/include/omc/omsicpp/" /I"<%makefileParams.omhome%>/include/omc/omsi/" /I"<%makefileParams.omhome%>/include/omc/omsi/base" /I"<%makefileParams.omhome%>/include/omc/omsi/solver/" /I"<%makefileParams.omhome%>/include/omc/omsi/fmi2/" /I. <%makefileParams.includes%>  /I"$(BOOST_INCLUDE)" /I"$(UMFPACK_INCLUDE)" /I"$(SUNDIALS_INCLUDE)" /DNOMINMAX /TP /DNO_INTERACTIVE_DEPENDENCY <%additionalCFlags_MSVC%>
  !ELSE
  CFLAGS=  $(SYSTEM_CFLAGS) /DRUNTIME_STATIC_LINKING /I"<%makefileParams.omhome%>/include/omc/omsicpp/" /I"<%makefileParams.omhome%>/include/omc/omsi/" /I"<%makefileParams.omhome%>/include/omc/omsi/base" /I"<%makefileParams.omhome%>/include/omc/omsi/solver/" /I"<%makefileParams.omhome%>/include/omc/omsi/fmi2/"  /I. <%makefileParams.includes%>  /I"$(BOOST_INCLUDE)" /I"$(UMFPACK_INCLUDE)" /I"$(SUNDIALS_INCLUDE)" /DNOMINMAX /TP /DNO_INTERACTIVE_DEPENDENCY  /Fp<%makefileParams.omhome%>/include/omc/omsicpp/Core/$(PCH_FILE)  /YuCore/$(H_FILE) <%additionalCFlags_MSVC%>
  !ENDIF
  CPPFLAGS =
  # /ZI enable Edit and Continue debug info
  CDFLAGS = /ZI
  !IF "$(PCH_FILE)" == ""
  LDSYSTEMFLAGS=  /link /DLL  /LIBPATH:"<%makefileParams.omhome%>/lib/omc/omsicpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/lib/omc/omsi/msvc"  /LIBPATH:"<%makefileParams.omhome%>/lib/omc/msvc" /LIBPATH:"<%makefileParams.omhome%>/lib/omc/msvc/debug"  /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)"  OMCppExtensionUtilities_static.lib OMCppModelicaUtilities_static.lib  OMCppOSU.lib   OMSIBase_static.lib OMSISolver_static.lib OMCppDgesv_static.lib OMCppDataExchange_static.lib  OMCppSystem_static.lib   OMCppMath_static.lib  OMCppOMCFactory.lib  libexpat.lib  sundials_nvecserial.lib sundials_kinsol.lib  WSock32.lib Ws2_32.lib
  !ELSE
  LDSYSTEMFLAGS=  /link /DLL  /LIBPATH:"<%makefileParams.omhome%>/lib/omc/omsicpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/lib/omc/omsi/msvc" /LIBPATH:"<%makefileParams.omhome%>/lib/omc/msvc" /LIBPATH:"<%makefileParams.omhome%>/lib/omc/msvc/debug"  /LIBPATH:"<%makefileParams.omhome%>/bin" /LIBPATH:"$(BOOST_LIBS)"  OMCppExtensionUtilities_static.lib OMCppModelicaUtilities_static.lib  OMCppOSU.lib   OMSIBase_static.lib OMSISolver_static.lib OMCppDgesv_static.lib OMCppDataExchange_static.lib  OMCppSystem_static.lib  OMCppMath_static.lib  OMCppOMCFactory.lib   libexpat.lib $(PCH_LIB) sundials_nvecserial.lib sundials_kinsol.lib  WSock32.lib Ws2_32.lib
  !ENDIF
  # lib names should not be appended with a d just switch to lib/omc/omsicpp
  #3rdParty Libraries
  EXPAT_LIBDIR=$(OMLIB)/omc
  EXPAT_LIB=expat

  LAPACK_LIBDIR=<%lapackDirWin%>
  LAPACK_LIB=<%match makefileParams.platform case "win32" case "win64" then 'openblas' else 'lapack'%>
  BLAS_LIB=<%match makefileParams.platform case "win32" case "win64" then '' else 'blas'%>

  KINSOL_LIBDIR=$(OMLIB)/omc
  KINSOL_LIB=sundials_kinsol
  SUNDIALS_NVECSERIAL=sundials_nvecserial
  THIRD_PARTY_DYNAMIC_LIBS =<%match makefileParams.platform case "win32" case "win64" then
  '$(LAPACK_LIBDIR)/lib$(LAPACK_LIB).<%libEnding%>' else ''%>       \
  $(KINSOL_LIBDIR)/lib$(KINSOL_LIB).<%libEnding%><%star%>                                \
  $(KINSOL_LIBDIR)/lib$(SUNDIALS_NVECSERIAL).<%libEnding%><%star%>  

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
  MAINOBJ=<%fileNamePrefix%>$(EXEEXT)


  CALCHELPERMAINFILE=OMCpp<%fileNamePrefix%>CalcHelperMain.cpp
  ALGLOOPMAINFILE=OMCpp<%fileNamePrefix%>AlgLoopMain.cpp
  GENERATEDFILES=$(MAINFILE) $(FUNCTIONFILE) $(ALGLOOPMAINFILE)
  PLATFORM="<%makefileParams.platform%>"
  MODEL_NAME=<%modelName%>
  MODELICA_SYSTEM_LIB=<%fileNamePrefix%>
  CALCHELPERMAINFILE=OMCpp$(MODELICA_SYSTEM_LIB)CalcHelperMain.cpp
  BINARIES=$(MODELICA_SYSTEM_LIB)$(DLLEXT)
  #need boost system lib prior to C++11, forcing also dynamic libs
  BINARIES=$(BINARIES) $(BOOST_LIBS)/$(BOOST_SYSTEM_LIB)$(DLLEXT) $(BOOST_LIBS)/$(BOOST_FILESYSTEM_LIB)$(DLLEXT)


  $(MODEL_NAME).fmu: $(MODELICA_SYSTEM_LIB)$(DLLEXT)
  <%\t%>rm -rf binaries
  <%\t%>mkdir -p "binaries/$(PLATFORM)"
  <%\t%>cp $(BINARIES) "binaries/$(PLATFORM)/"
  <%\t%># Third party libraries
  <%\t%>cp -f $(EXPAT_LIBDIR)/lib$(EXPAT_LIB).a  binaries/$(PLATFORM)
  <%\t%>cp -fP $(THIRD_PARTY_DYNAMIC_LIBS) binaries/$(PLATFORM)
  <%\t%>mkdir -p "resources"
  <%\t%>cp <%fileNamePrefix%>_init.xml "resources"
  <%\t%>rm -f $(MODEL_NAME).fmu
  <%\t%>zip -r "$(MODEL_NAME).fmu" modelDescription.xml binaries resources
  <%\t%>rm -rf binaries

  $(MODELICA_SYSTEM_LIB)$(DLLEXT):
   <%\t%>$(CXX)  /Fe$(MODELICA_SYSTEM_LIB)$(DLLEXT) $(CALCHELPERMAINFILE) $(CFLAGS) $(LDSYSTEMFLAGS) <%dirExtra%> <%libsPos1%> <%libsPos2%>

  >>
end match
case "gcc" then
    match simCode
        case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
            let dirExtra = if modelInfo.directory then '-L"<%modelInfo.directory%>"' //else ""
            let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
            let libsPos1 = if not dirExtra then libsStr //else ""
            let libsPos2 = if dirExtra then libsStr // else ""
            let libsExtra = (makefileParams.libs |> lib => lib ;separator=" ")
            let staticIncludes = '-I"$(SUNDIALS_INCLUDE)" -I"$(SUNDIALS_INCLUDE)/kinsol" -I"$(SUNDIALS_INCLUDE)/nvector"'
            let _extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then ""
            let extraCflags = '<%_extraCflags%><% if Flags.isSet(Flags.GEN_DEBUG_SYMBOLS) then " -g"%>'
            let papiLibs = ' -lOMCppExtensionUtilities_papi -lpapi'
            let CC = if (compileForMPI) then "mpicc" else '<%makefileParams.ccompiler%>'
            let CXX = if (compileForMPI) then "mpicxx" else '<%makefileParams.cxxcompiler%>'
            let extraCppFlags = (getConfigStringList(CPP_FLAGS) |> flag => '<%flag%>'; separator=" ")
            let modelName = dotPath(modelInfo.name)
            let platformstr = match makefileParams.platform case "i386-pc-linux" then 'linux32' case "x86_64-linux" then 'linux64' else '<%makefileParams.platform%>'
            let omhome = makefileParams.omhome
            let platformbins = match platformstr case "win32" case "win64" then '<%omhome%>/bin/libgcc_s_*.dll <%omhome%>/bin/libstdc++-6.dll <%omhome%>/bin/libwinpthread-1.dll' else ''
            let lapackbins = match platformstr case "win32" case "win64" then '<%omhome%>/bin/libopenblas.dll' else ''
            let mkdir = match makefileParams.platform case "win32" case "win64" then '"mkdir.exe"' else 'mkdir'
            let MPIEnvVars = if (compileForMPI)
                then 'OMPI_MPICC=<%makefileParams.ccompiler%> <%\n%>OMPI_MPICXX=<%makefileParams.cxxcompiler%>' else ""
            let OMLibs = match makefileParams.platform case "win32" case "win64" then 'lib' case "linux64" then 'lib/x86_64-linux-gnu' else 'lib'
            let lapackDirWin = match makefileParams.platform case "win32" then '$(OMDEV)/tools/msys/mingw32/bin' case "win64" then '$(OMDEV)/tools/msys/mingw64/bin' else ''
            let libEnding = match makefileParams.platform case "win32" case "win64" then 'dll' else 'so'
            let star = match makefileParams.platform case "win32" case "win64" then '' else '*'
            let rpath = match makefileParams.platform case "win32" case "win64" then '' else "\"-Wl,-rpath,\$$ORIGIN/.\""
            <<
            # Makefile generated by OpenModelica
            OMHOME=<%makefileParams.omhome%>
            OMLIB=<%makefileParams.omhome%>/<%OMLibs%>
            include $(OMHOME)/include/omc/omsicpp/ModelicaConfig_gcc.inc
            include $(OMHOME)/include/omc/omsicpp/ModelicaLibraryConfig_gcc.inc
            # Simulations use -O0 by default
            SIM_OR_DYNLOAD_OPT_LEVEL=-O0
            CC=<%CC%>
            CXX=<%CXX%> $(OPENMP_FLAGS)

            <%MPIEnvVars%>

            EXEEXT=<%makefileParams.exeext%>
            DLLEXT=<%makefileParams.dllext%>

            #simulations use -O0 by default; can be changed to e.g. -O2 or -Ofast
            SIM_OPT_LEVEL=-O0
            # native build or cross compilation
            ifeq ($(TARGET_TRIPLET),)
              TRIPLET=<%Autoconf.triple%>
              CC=<%makefileParams.ccompiler%>
              CXX=<%makefileParams.cxxcompiler%>
              ABI_CFLAG=
              DLLEXT=<%makefileParams.dllext%>
              PLATFORM=<%platformstr%>
            else
              TRIPLET=$(TARGET_TRIPLET)
              CC=$(TRIPLET)-gcc
              CXX=$(TRIPLET)-g++
              ABI_CFLAG=-D_GLIBCXX_USE_CXX11_ABI=0
              DLLEXT=$(if $(findstring mingw,$(TRIPLET)),.dll,.so)
              WORDSIZE=$(if $(findstring x86_64,$(TRIPLET)),64,32)
              PLATFORM=$(if $(findstring darwin,$(TRIPLET)),darwin,$(if $(findstring mingw,$(TRIPLET)),win,linux))$(WORDSIZE)
            endif

            CFLAGS_BASED_ON_INIT_FILE=<%extraCflags%>
            FMU_CFLAGS=$(subst -DUSE_THREAD,,$(subst -O0,$(SIM_OPT_LEVEL),$(SYSTEM_CFLAGS))) $(ABI_CFLAG)
            CFLAGS=$(CFLAGS_BASED_ON_INIT_FILE) -Winvalid-pch $(FMU_CFLAGS) -DFMU_BUILD -DRUNTIME_STATIC_LINKING -I"$(OMHOME)/include/omc/omsicpp" -I"$(OMHOME)/include/omc/omsi/" -I"$(OMHOME)/include/omc/omsi/base" -I"$(OMHOME)/include/omc/omsi/solver" -I"$(OMHOME)/include/omc/omsi/fmi2/"  -I"$(UMFPACK_INCLUDE)" -I"$(SUNDIALS_INCLUDE)" -I"$(BOOST_INCLUDE)" <%makefileParams.includes ; separator=" "%> <%additionalCFlags_GCC%>

            ifeq ($(USE_LOGGER),ON)
              $(eval CFLAGS=$(CFLAGS) -DUSE_LOGGER)
            endif

            CPPFLAGS=$(CFLAGS)
            
            MINGW_EXTRA_LIBS=<%if boolOr(stringEq(makefileParams.platform, "win32"),stringEq(makefileParams.platform, "win64")) then ' -lz -lhdf5 ' else ''%>
            MODELICA_EXTERNAL_LIBS=-L$(LAPACK_LIBS) $(LAPACK_LIBRARIES) $(MINGW_EXTRA_LIBS)
            OMCPP_LIBS=-lOMCppSystem_static  -lOMCppOSU -lOMSIBase_static -lOMSISolver_static -lOMCppDataExchange_static -lOMCppExtensionUtilities_static -lOMCppModelicaUtilities_static    -lOMCppMath_static -lsundials_kinsol -lsundials_nvecserial
            EXTRA_LIBS=<%dirExtra%> <%libsExtra%>
            LIBS=$(OMCPP_LIBS) $(MODELICA_EXTERNAL_LIBS) $(BASE_LIB) $(EXTRA_LIBS) -L$(BOOST_LIBS) -l$(BOOST_SYSTEM_LIB) -l$(BOOST_FILESYSTEM_LIB) -lexpat
            # link with simple dgesv or full lapack
            ifeq ($(USE_DGESV),ON)
               $(eval LIBS=$(LIBS) -lOMCppDgesv_static)
            else
               $(eval LIBS=$(LIBS) -L$(LAPACK_LIBS) $(LAPACK_LIBRARIES))
               $(eval BINARIES=$(BINARIES) <%lapackbins%>)
            endif
            LDFLAGS=-L"$(OMHOME)/lib/$(TRIPLET)/omc/omsicpp" -L"$(OMHOME)/lib/$(TRIPLET)/omc/omsi" -L"$(OMHOME)/lib/$(TRIPLET)/omc/" <%additionalLinkerFlags_GCC%> <%rpath%>
            #3rdParty Libraries
            EXPAT_LIBDIR=$(OMLIB)/omc
            EXPAT_LIB=expat
            
            LAPACK_LIBDIR=<%lapackDirWin%>
            LAPACK_LIB=<%match makefileParams.platform case "win32" case "win64" then 'openblas' else 'lapack'%>
            BLAS_LIB=<%match makefileParams.platform case "win32" case "win64" then '' else 'blas'%>
            
            KINSOL_LIBDIR=$(OMLIB)/omc
            KINSOL_LIB=sundials_kinsol
            SUNDIALS_NVECSERIAL=sundials_nvecserial
            THIRD_PARTY_DYNAMIC_LIBS =<%match makefileParams.platform case "win32" case "win64" then
            '$(LAPACK_LIBDIR)/lib$(LAPACK_LIB).<%libEnding%>' else ''%>       \
            $(KINSOL_LIBDIR)/lib$(KINSOL_LIB).<%libEnding%><%star%>                                \
            $(KINSOL_LIBDIR)/lib$(SUNDIALS_NVECSERIAL).<%libEnding%><%star%>  
            BINARIES=<%fileNamePrefix%>$(DLLEXT) $(BOOST_LIBS)/lib$(BOOST_SYSTEM_LIB)$(DLLEXT) $(BOOST_LIBS)/lib$(BOOST_FILESYSTEM_LIB)$(DLLEXT)




            SYSTEMFILE=OMCpp<%fileNamePrefix%><% if acceptMetaModelicaGrammar() then ".conv"%>.cpp
            SYSTEMOBJ=OMCpp<%fileNamePrefix%>$(DLLEXT)

            CALCHELPERMAINFILE=OMCpp<%fileNamePrefix%>CalcHelperMain.cpp
            ALGLOOPSMAINFILE=OMCpp<%fileNamePrefix%>AlgLoopMain.cpp

            CPPFILES=$(CALCHELPERMAINFILE)
            OFILES=$(CPPFILES:.cpp=.o)

            .PHONY: <%modelName%>.fmu $(CPPFILES) clean

            <%modelName%>.fmu: $(OFILES)
            <%\t%>$(CXX) -shared -o <%fileNamePrefix%>$(DLLEXT) $(OFILES) $(LDFLAGS) $(LIBS)
            <%\t%><%mkdir%> -p "binaries/$(PLATFORM)"
            <%\t%><%mkdir%> -p "resources"
            <%\t%>cp $(BINARIES) "binaries/$(PLATFORM)/"
            <%\t%>cp <%fileNamePrefix%>_init.xml "resources/"
            
            <%\t%>rm -rf documentation
            <%\t%><%mkdir%> -p "documentation"
            <%\t%># Third party libraries
            <%\t%>cp -f $(EXPAT_LIBDIR)/lib$(EXPAT_LIB).a  binaries/$(PLATFORM)
            <%\t%>cp -fP $(THIRD_PARTY_DYNAMIC_LIBS) binaries/$(PLATFORM)
            <%\t%>cp $(OMHOME)/share/omc/runtime/omsicpp/licenses/sundials.license "documentation/"
          
            <%\t%>rm -f <%modelName%>.fmu
            
            <%\t%>zip -r "<%modelName%>.fmu" modelDescription.xml binaries resources documentation
            <%\t%>rm -rf documentation
           
            <%if boolNot(boolOr(stringEq(makefileParams.platform, "win32"),stringEq(makefileParams.platform, "win64"))) then
                <<
                <%\t%>chmod +x <%fileNamePrefix%>.sh
                >>
            %>
            clean:
            <%\t%>rm <%fileNamePrefix%>$(DLLEXT)
            <%\t%>rm -rf binaries

  >>
end osuMakefile;

template simulationOSUMainRunScript(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, String preRunCommandLinux, String preRunCommandWindows, String execCommandLinux)
 "Generates code for header file for simulation target."
::=
  match simCode
   case SIMCODE(modelInfo = MODELINFO(__), makefileParams = MAKEFILE_PARAMS(__), simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
    let start     = settings.startTime
    let end       = settings.stopTime
    let stepsize  = settings.stepSize
    let intervals = settings.numberOfIntervals
    let tol       = settings.tolerance
    let solver    = match simCode case SIMCODE(daeModeData=NONE()) then settings.method else 'ida' //for dae mode only ida is supported
    let moLib     =  makefileParams.compileDir
    let home      = makefileParams.omhome
    let outputformat = settings.outputFormat
    let modelName =  dotPath(modelInfo.name)
    let fileNamePrefixx = fileNamePrefix
    let platformstr = match makefileParams.platform case "i386-pc-linux" then 'linux32' case "x86_64-linux" then 'linux64' else '<%makefileParams.platform%>'
    let execParameters = '-S <%start%> -E <%end%> -H <%stepsize%> -G <%intervals%> -P <%outputformat%> -T <%tol%> -I <%solver%> -R <%simulationLibDir(simulationCodeTarget(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%> -M <%moLib%> -r <%simulationResults(getRunningTestsuite(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%> -p <%moLib%> -o <%modelName%>.fmu'
    let outputParameter = if (stringEq(settings.outputFormat, "empty")) then "-O none" else ""


    let libFolder =simulationLibDir(simulationCodeTarget(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
    let binFolder =simulationBinDir(simulationCodeTarget(),simCode )
    let libPaths = makefileParams.libPaths |> path => path; separator=";"

    match makefileParams.platform
      case  "linux32"
      case  "linux64" then
        <<
        #!/bin/sh
        <%preRunCommandLinux%>
        <%execCommandLinux%> <%binFolder%>/OMCppOSUSimulation <%execParameters%>  <%outputParameter%> $*
        >>
      case  "win32"
      case  "win64" then
        <<
        @echo off
        <%preRunCommandWindows%>
        REM ::export PATH=<%libFolder%>:$PATH REPLACE C: with /C/
        SET PATH=<%binFolder%>;<%libFolder%>;<%libPaths%>;%PATH%
        OMCppOSUSimulation.exe <%execParameters%> <%outputParameter%>
        >>
    end match
  end match
end simulationOSUMainRunScript;




annotation(__OpenModelica_Interface="backend");
end CodegenOMSICpp;

// vim: filetype=susan sw=2 sts=2
