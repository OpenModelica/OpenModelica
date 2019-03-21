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

package CodegenSparseFMI

import interface SimCodeTV;
import CodegenUtil.*;
import CodegenUtilSimulation.*;
import CodegenFMU.*;
import CodegenC.*;
import ExpressionDumpTpl;

template translateModel(SimCode simCode, String FMUVersion, String FMUType, list<String> sourceFiles)
 "Generates C code and Makefile for compiling a FMU of a
  Modelica model."
::=
match simCode
case sc as SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
  let guid = getUUIDStr()
  let target  = simulationCodeTarget()
  let()= textFile(fmumodel_identifierFile(simCode,guid,FMUVersion), '<%fileNamePrefix%>_FMI.cpp')
  let()= textFile(CodegenFMU.fmuModelDescriptionFile(simCode, guid, FMUVersion, FMUType, sourceFiles), 'modelDescription.xml')
  "" // Return empty result since result written to files directly
end translateModel;

template statesnumwithDummy(list<SimVar> vars)
" return number of states without dummy vars"
::=
 (vars |> var =>  match var case SIMVAR(__) then if stringEq(crefStr(name),"$dummy") then '0' else '1' ;separator="\n")
end statesnumwithDummy;

template fmumodel_identifierFile(SimCode simCode, String guid, String FMUVersion)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  // define class name and unique id
  #ifdef FMI_FROM_SOURCE
  #define FMI2_FUNCTION_PREFIX <%modelNamePrefix(simCode)%>_
  #endif
  #include <fmi2TypesPlatform.h>
  #include <fmi2Functions.h>
  #define MODEL_GUID "{<%guid%>}"
  #include <cstdio>
  #include <cstring>
  #include <cassert>
  #include "sfmi_runtime.h"
  using namespace std;
  using namespace sfmi;

  <%ModelDefineData(modelInfo)%>

  // Removed equations

  <%generateEquations(removedEquations)%>

  // dynamic equation functions

  <%generateEquations(allEquations)%>

  // Zero crossing functions

  <%zeroCrossingEqns(zeroCrossings)%>

  // Dependency graph for sparse updates
  static void setupEquationGraph(model_data *data)
  {
      <%generateEquationGraph(allEquations,zeroCrossings)%>
  }

  // initial condition equations

  <%generateEquations(initialEquations)%>
  <%generateEquations(parameterEquations)%>

  <%setDefaultStartValues(modelInfo)%>

  // Solve for unknowns in the model's initial equations
  static void initialEquations(model_data* data)
  {
      <%AllEquations(parameterEquations)%>
      <%AllEquations(initialEquations)%>
  }

  // Solve all dynamic equations
  static void allEquations(model_data* data)
  {
      <%AllEquations(allEquations)%>
  }

  // model exchange functions

  const char* fmi2GetTypesPlatform() { return fmi2TypesPlatform; }
  const char* fmi2GetVersion() { return fmi2Version; }

  fmi2Status fmi2SetDebugLogging(fmi2Component, fmi2Boolean, size_t, const fmi2String*)
  {
      return fmi2OK;
  }

  fmi2Status fmi2SetupExperiment(fmi2Component c, fmi2Boolean, fmi2Real, fmi2Real startTime, fmi2Boolean, fmi2Real)
  {
      return fmi2SetTime(c,startTime);
  }

  fmi2Status fmi2EnterInitializationMode(fmi2Component c)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL) return fmi2Error;
      data->set_mode(FMI_INIT_MODE);
      return fmi2OK;
  }

  fmi2Status fmi2ExitInitializationMode(fmi2Component c)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL) return fmi2Error;
      initialEquations(data);
      allEquations(data);
      data->push_pre();
      return fmi2OK;
  }

  fmi2Status fmi2Terminate(fmi2Component)
  {
      return fmi2OK;
  }

  fmi2Status fmi2Reset(fmi2Component c)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL) return fmi2Error;
      setDefaultStartValues(data);
      initialEquations(data);
      allEquations(data);
      data->push_pre();
      data->set_mode(FMI_INIT_MODE);
      return fmi2OK;
  }

  fmi2Status fmi2GetFMUstate(fmi2Component, fmi2FMUstate*) { return fmi2Error; }
  fmi2Status fmi2SetFMUstate(fmi2Component, fmi2FMUstate) { return fmi2Error; }
  fmi2Status fmi2FreeFMUstate(fmi2Component, fmi2FMUstate*) { return fmi2Error; }
  fmi2Status fmi2SerializedFMUstateSize(fmi2Component, fmi2FMUstate, size_t*) { return fmi2Error; }
  fmi2Status fmi2SerializeFMUstate(fmi2Component, fmi2FMUstate, fmi2Byte*, size_t) { return fmi2Error; }
  fmi2Status fmi2DeSerializeFMUstate(fmi2Component, const fmi2Byte[], size_t, fmi2FMUstate*) { return fmi2Error; }
  fmi2Status fmi2GetDirectionalDerivative(fmi2Component, const fmi2ValueReference*, size_t,
                                                   const fmi2ValueReference*, size_t,
                                                   const fmi2Real*, fmi2Real*) { return fmi2Error; }

  fmi2Status fmi2GetDerivatives(fmi2Component c, fmi2Real* der, size_t nvr)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL || nvr > NUMBER_OF_STATES) return fmi2Error;
      for (size_t i = 0; i < nvr; i++) der[i] = data->real_vars[STATESDERIVATIVES[i]];
      return fmi2OK;
  }

  fmi2Status fmi2GetEventIndicators(fmi2Component c, fmi2Real* z, size_t nvr)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL || nvr > NUMBER_OF_EVENT_INDICATORS) return fmi2Error;
      for (size_t i = 0; i < nvr; i++) z[i] = data->z[i];
      return fmi2OK;
  }

  fmi2Status fmi2GetContinuousStates(fmi2Component c, fmi2Real* states, size_t nvr)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL || nvr > NUMBER_OF_STATES) return fmi2Error;
      for (size_t i = 0; i < nvr; i++) states[i] = data->real_vars[STATES[i]];
      return fmi2OK;
  }

  fmi2Status fmi2SetContinuousStates(fmi2Component c, const fmi2Real* states, size_t nvr)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL || nvr > NUMBER_OF_STATES) return fmi2Error;
      for (size_t i = 0; i < nvr; i++)
      {
          data->real_vars[STATES[i]] = states[i];
          data->modify(&(data->real_vars[STATES[i]]));
      }
      return fmi2OK;
  }

  fmi2Status fmi2GetNominalsOfContinuousStates(fmi2Component c, fmi2Real* nominals, size_t nvr)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL || nvr > NUMBER_OF_STATES) return fmi2Error;
      for (size_t i = 0; i < nvr; i++) nominals[i] = 1.0;
      return fmi2OK;
  }

   fmi2Status fmi2EnterEventMode(fmi2Component c)
   {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL) return fmi2Error;
      data->set_mode(FMI_EVENT_MODE);
      return fmi2OK;
   }

   fmi2Status fmi2NewDiscreteStates(fmi2Component c, fmi2EventInfo* event_info)
   {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL) return fmi2Error;
      data->push_pre();
      data->update();
      if (data->test_pre())
      {
         event_info->newDiscreteStatesNeeded = fmi2False;
         event_info->valuesOfContinuousStatesChanged = fmi2False;
      }
      else
      {
         event_info->newDiscreteStatesNeeded = fmi2True;
         event_info->valuesOfContinuousStatesChanged = fmi2True;
      }
      event_info->terminateSimulation = fmi2False;
      event_info->nominalsOfContinuousStatesChanged = fmi2False;
      event_info->nextEventTimeDefined = fmi2False;
      event_info->nextEventTime = 0.0;
      return fmi2OK;
   }

   fmi2Status fmi2EnterContinuousTimeMode(fmi2Component c)
   {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL) return fmi2Error;
      data->set_mode(FMI_CONT_TIME_MODE);
      return fmi2OK;
   }

   fmi2Status fmi2CompletedIntegratorStep(fmi2Component c, fmi2Boolean,
       fmi2Boolean* enterEventMode, fmi2Boolean* terminateSimulation)
   {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL || enterEventMode == NULL || terminateSimulation == NULL) return fmi2Error;
      data->update();
      *enterEventMode = fmi2False;
      *terminateSimulation = fmi2False;
      return fmi2OK;
   }

  <%setTime2()%>
  <%getRealFunction2()%>
  <%setRealFunction2()%>
  <%getIntegerFunction2()%>
  <%setIntegerFunction2()%>
  <%getBooleanFunction2()%>
  <%setBooleanFunction2()%>
  <%getStringFunction2()%>
  <%setStringFunction2()%>
  <%InstantiateFunction2()%>
  <%FreeFunction2()%>

  >>
end fmumodel_identifierFile;

template AllEquations(list<SimEqSystem> allEquations)
 "Generate calls to all of the model equations."
::=
  let fncalls = (allEquations |> eq =>
                    'eqFunction_<%equationIndex(eq)%>(data);'
                    ;separator="\n")
  <<
  <%fncalls%>

  >>
end AllEquations;

template generateEquations(list<SimEqSystem> allEquations)
 "Generate functions for all equations in the model."
::=
  let &varDecls = buffer ""
  let &eqfuncs = buffer ""
  let fncalls = (allEquations |> eq =>
                    equation_function(eq, contextSimulationDiscrete, &varDecls, &eqfuncs, "")
                    ;separator="\n")
  <<
  <%eqfuncs%>
  >>
end generateEquations;

template InstantiateFunction2()
 "Generates instantiate function for c file."
::=
  <<
  fmi2Component
  fmi2Instantiate(
    fmi2String instanceName,
    fmi2Type fmuType,
    fmi2String fmuGUID,
    fmi2String fmuResourceLocation,
    const fmi2CallbackFunctions* functions,
    fmi2Boolean visible,
    fmi2Boolean loggingOn)
  {
      model_data* data = new model_data(
          NUMBER_OF_REALS,NUMBER_OF_INTEGERS,NUMBER_OF_STRINGS,NUMBER_OF_BOOLEANS,NUMBER_OF_EVENT_INDICATORS);
      setupEquationGraph(data);
      setDefaultStartValues(data);
      initialEquations(data);
      allEquations(data);
      return static_cast<fmi2Component>(data);
  }

  >>
end InstantiateFunction2;

template FreeFunction2()
 "Generates free function for c file."
::=
  <<
  void
  fmi2FreeInstance(fmi2Component c)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data != NULL) delete data;
  }

  >>
end FreeFunction2;

template ModelDefineData(ModelInfo modelInfo)
 "Generates global data in simulation file."
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(stateVars = listStates)) then
let numberOfReals = intAdd(intMul(varInfo.numStateVars,2),intAdd(varInfo.numDiscreteReal, intAdd(varInfo.numAlgVars,intAdd(varInfo.numParams,varInfo.numAlgAliasVars))))
let numberOfIntegers = intAdd(varInfo.numIntAlgVars,intAdd(varInfo.numIntParams,varInfo.numIntAliasVars))
let numberOfStrings = intAdd(varInfo.numStringAlgVars,intAdd(varInfo.numStringParamVars,varInfo.numStringAliasVars))
let numberOfBooleans = intAdd(varInfo.numBoolAlgVars,intAdd(varInfo.numBoolParams,varInfo.numBoolAliasVars))
  <<
  // define model size
  #define NUMBER_OF_STATES <%if intEq(varInfo.numStateVars,1) then statesnumwithDummy(listStates) else  varInfo.numStateVars%>
  #define NUMBER_OF_EVENT_INDICATORS <%varInfo.numZeroCrossings%>
  #define NUMBER_OF_REALS <%numberOfReals%>
  #define NUMBER_OF_INTEGERS <%numberOfIntegers%>
  #define NUMBER_OF_STRINGS <%numberOfStrings%>
  #define NUMBER_OF_BOOLEANS <%numberOfBooleans%>
  #define NUMBER_OF_EXTERNALFUNCTIONS <%countDynamicExternalFunctions(functions)%>

  // define variable data for model
  #define timeValue (data->Time)
  <%System.tmpTickReset(0)%>
  <%vars.stateVars |> var => DefineVariables(var,"real") ;separator="\n"%>
  <%vars.derivativeVars |> var => DefineVariables(var,"real") ;separator="\n"%>
  <%vars.algVars |> var => DefineVariables(var,"real") ;separator="\n"%>
  <%vars.discreteAlgVars |> var => DefineVariables(var,"real") ;separator="\n"%>
  <%vars.paramVars |> var => DefineVariables(var,"real") ;separator="\n"%>
  <%vars.aliasVars |> var => DefineVariables(var,"real") ;separator="\n"%>
  <%vars.stateVars |> var => DefineDummyVariables(var,"real") ;separator="\n"%>
  <%vars.derivativeVars |> var => DefineDummyVariables(var,"real") ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.intAlgVars |> var => DefineVariables(var,"int") ;separator="\n"%>
  <%vars.intParamVars |> var => DefineVariables(var,"int") ;separator="\n"%>
  <%vars.intAliasVars |> var => DefineVariables(var,"int") ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.boolAlgVars |> var => DefineVariables(var,"bool") ;separator="\n"%>
  <%vars.boolParamVars |> var => DefineVariables(var,"bool") ;separator="\n"%>
  <%vars.boolAliasVars |> var => DefineVariables(var,"bool") ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.stringAlgVars |> var => DefineVariables(var,"str") ;separator="\n"%>
  <%vars.stringParamVars |> var => DefineVariables(var,"str") ;separator="\n"%>
  <%vars.stringAliasVars |> var => DefineVariables(var,"str") ;separator="\n"%>

  <%System.tmpTickReset(0)%>
  <%vars.stateVars |> var => DefinePreVariables(var,"real") ;separator="\n"%>
  <%vars.derivativeVars |> var => DefinePreVariables(var,"real") ;separator="\n"%>
  <%vars.algVars |> var => DefinePreVariables(var,"real") ;separator="\n"%>
  <%vars.discreteAlgVars |> var => DefinePreVariables(var,"real") ;separator="\n"%>
  <%vars.paramVars |> var => DefinePreVariables(var,"real") ;separator="\n"%>
  <%vars.aliasVars |> var => DefinePreVariables(var,"real") ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.intAlgVars |> var => DefinePreVariables(var,"int") ;separator="\n"%>
  <%vars.intParamVars |> var => DefinePreVariables(var,"int") ;separator="\n"%>
  <%vars.intAliasVars |> var => DefinePreVariables(var,"int") ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.boolAlgVars |> var => DefinePreVariables(var,"bool") ;separator="\n"%>
  <%vars.boolParamVars |> var => DefinePreVariables(var,"bool") ;separator="\n"%>
  <%vars.boolAliasVars |> var => DefinePreVariables(var,"bool") ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.stringAlgVars |> var => DefinePreVariables(var,"str") ;separator="\n"%>
  <%vars.stringParamVars |> var => DefinePreVariables(var,"str") ;separator="\n"%>
  <%vars.stringAliasVars |> var => DefinePreVariables(var,"str") ;separator="\n"%>

  // define initial state vector as vector of value references
  static const fmi2ValueReference STATES[NUMBER_OF_STATES] = { <%vars.stateVars |> SIMVAR(__) => if stringEq(crefStr(name),"$dummy") then '' else '<%cref(name)%>_'  ;separator=", "%> };
  static const fmi2ValueReference STATESDERIVATIVES[NUMBER_OF_STATES] = { <%vars.derivativeVars |> SIMVAR(__) => if stringEq(crefStr(name),"der($dummy)") then '' else '<%cref(name)%>_'  ;separator=", "%> };

  <%System.tmpTickReset(0)%>
  <%(functions |> fn => defineExternalFunction(fn) ; separator="\n")%>
  >>
end ModelDefineData;

template DefineDummyVariables(SimVar simVar, String arrayName)
 "Generates code for defining variables in c file for FMU target. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  if stringEq(crefStr(name),"$dummy") then
  let idx = System.tmpTick()
  <<
  #define <%cref(name)%>_ <%idx%> <%description%>
  #define <%cref(name)%> (data-><%arrayName%>_vars[<%idx%>]) <%description%>
  >>
  else if stringEq(crefStr(name),"der($dummy)") then
  let idx = System.tmpTick()
  <<
  #define <%cref(name)%>_ <%idx%> <%description%>
  #define <%cref(name)%> (data-><%arrayName%>_vars[<%idx%>]) <%description%>
  >>
  else
  <<>>
end DefineDummyVariables;

template DefinePreVariables(SimVar simVar, String arrayName)
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
  let idx = System.tmpTick()
  <<
  #define _PRE<%cref(name)%>_ <%idx%> <%description%>
  #define _PRE<%cref(name)%> (data->pre_<%arrayName%>_vars[<%idx%>]) <%description%>
  >>
end DefinePreVariables;

template DefineVariables(SimVar simVar, String arrayName)
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
  let idx = System.tmpTick()
  <<
  #define <%cref(name)%>_ <%idx%> <%description%>
  #define <%cref(name)%> (data-><%arrayName%>_vars[<%idx%>]) <%description%>
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
 "Generates code in c file for function setDefaultStartValues() which will set start values for all variables."
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(numStateVars=numStateVars, numAlgVars= numAlgVars),vars=SIMVARS(__)) then
  <<
  // Set values for all variables that define a start value
  static void setDefaultStartValues(model_data *comp)
  {
      comp->Time = 0.0;
      <%vars.stateVars |> var => initValsDefault(var,"real") ;separator="\n"%>
      <%vars.derivativeVars |> var => initValsDefault(var,"real") ;separator="\n"%>
      <%vars.algVars |> var => initValsDefault(var,"real") ;separator="\n"%>
      <%vars.discreteAlgVars |> var => initValsDefault(var, "real") ;separator="\n"%>
      <%vars.intAlgVars |> var => initValsDefault(var,"int") ;separator="\n"%>
      <%vars.boolAlgVars |> var => initValsDefault(var,"bool") ;separator="\n"%>
      <%vars.stringAlgVars |> var => initValsDefault(var,"str") ;separator="\n"%>
      <%vars.paramVars |> var => initValsDefault(var,"real") ;separator="\n"%>
      <%vars.intParamVars |> var => initValsDefault(var,"int") ;separator="\n"%>
      <%vars.boolParamVars |> var => initValsDefault(var,"bool") ;separator="\n"%>
      <%vars.stringParamVars |> var => initValsDefault(var,"str") ;separator="\n"%>
  }

  >>
end setDefaultStartValues;

template initValsDefault(SimVar var, String arrayName) ::=
  match var
    case SIMVAR(index=index, type_=type_) then
    let str = 'comp-><%arrayName%>_vars[<%cref(name)%>_]'
    match initialValue
      case SOME(v as ICONST(__))
      case SOME(v as RCONST(__))
      case SOME(v as SCONST(__))
      case SOME(v as BCONST(__))
      case SOME(v as ENUM_LITERAL(__)) then
      '<%str%> = <%initVal(v)%>;'
      else
        match type_
          case T_INTEGER(__)
          case T_REAL(__)
          case T_ENUMERATION(__)
          case T_BOOL(__) then '<%str%> = 0;'
          case T_STRING(__) then '<%str%> = "";'
          else 'UNKOWN_TYPE'
end initValsDefault;

template initVal(Exp initialValue)
::=
  match initialValue
  case ICONST(__) then integer
  case RCONST(__) then real
  case SCONST(__) then '"<%Util.escapeModelicaStringToXmlString(string)%>"'
  case BCONST(__) then if bool then "1" else "0"
  case ENUM_LITERAL(__) then '<%index%>'
  else "*ERROR* initial value of unknown type"
end initVal;

template setTime2()
::=
  <<
  fmi2Status
  fmi2SetTime(fmi2Component c, fmi2Real t)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL) return fmi2Error;
      data->Time = t;
      data->modify(&(data->Time));
      return fmi2OK;
  }

  >>
end setTime2;

template getRealFunction2()
 "Generates getReal function for c file."
::=
  <<
  fmi2Status
  fmi2GetReal(fmi2Component c, const fmi2ValueReference* vr, size_t nvr, fmi2Real* value)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL) return fmi2Error;
      for (size_t i = 0; i < nvr; i++)
      {
          if (vr[i] >= NUMBER_OF_REALS) return fmi2Error;
          value[i] = data->real_vars[vr[i]];
      }
      return fmi2OK;
  }

  >>
end getRealFunction2;

template setRealFunction2()
 "Generates setReal function for c file."
::=
  <<
  fmi2Status
  fmi2SetReal(fmi2Component c, const fmi2ValueReference* vr, size_t nvr, const fmi2Real* value)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL) return fmi2Error;
      for (size_t i = 0; i < nvr; i++)
      {
          if (vr[i] >= NUMBER_OF_REALS) return fmi2Error;
          data->real_vars[vr[i]] = value[i];
          data->modify((&data->real_vars[vr[i]]));
      }
      return fmi2OK;
  }

  >>
end setRealFunction2;

template getIntegerFunction2()
 "Generates getInteger function for c file."
::=
  <<
  fmi2Status
  fmi2GetInteger(fmi2Component c, const fmi2ValueReference* vr, size_t nvr, fmi2Integer* value)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL) return fmi2Error;
      for (size_t i = 0; i < nvr; i++)
      {
          if (vr[i] >= NUMBER_OF_INTEGERS) return fmi2Error;
          value[i] = data->int_vars[vr[i]];
      }
      return fmi2OK;
  }

  >>
end getIntegerFunction2;

template setIntegerFunction2()
 "Generates setInteger function for c file."
::=
  <<
  fmi2Status
  fmi2SetInteger(fmi2Component c, const fmi2ValueReference* vr, size_t nvr, const fmi2Integer* value)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL) return fmi2Error;
      for (size_t i = 0; i < nvr; i++)
      {
          if (vr[i] >= NUMBER_OF_INTEGERS) return fmi2Error;
          data->int_vars[vr[i]] = value[i];
          data->modify((&data->int_vars[vr[i]]));
      }
      return fmi2OK;
  }

  >>
end setIntegerFunction2;

template getBooleanFunction2()
 "Generates getBoolean function for c file."
::=
  <<
  fmi2Status
  fmi2GetBoolean(fmi2Component c, const fmi2ValueReference* vr, size_t nvr, fmi2Boolean* value)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL) return fmi2Error;
      for (size_t i = 0; i < nvr; i++)
      {
          if (vr[i] >= NUMBER_OF_BOOLEANS) return fmi2Error;
          value[i] = data->bool_vars[vr[i]];
      }
      return fmi2OK;
  }

  >>
end getBooleanFunction2;

template setBooleanFunction2()
 "Generates setBoolean function for c file."
::=
  <<
  fmi2Status
  fmi2SetBoolean(fmi2Component c, const fmi2ValueReference* vr, size_t nvr, const fmi2Boolean* value)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL) return fmi2Error;
      for (size_t i = 0; i < nvr; i++)
      {
          if (vr[i] >= NUMBER_OF_BOOLEANS) return fmi2Error;
          data->bool_vars[vr[i]] = value[i];
          data->modify((&data->bool_vars[vr[i]]));
      }
      return fmi2OK;
  }

  >>
end setBooleanFunction2;

template getStringFunction2()
 "Generates setString function for c file."
::=
  <<
  fmi2Status
  fmi2GetString(fmi2Component c, const fmi2ValueReference* vr, size_t nvr, fmi2String* value)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL) return fmi2Error;
      for (size_t i = 0; i < nvr; i++)
      {
          if (vr[i] >= NUMBER_OF_STRINGS) return fmi2Error;
          value[i] = data->str_vars[vr[i]].c_str();
      }
      return fmi2OK;
  }

  >>
end getStringFunction2;

template setStringFunction2()
 "Generates setString function for c file."
::=
  <<
  fmi2Status
  fmi2SetString(fmi2Component c, const fmi2ValueReference* vr, size_t nvr, const fmi2String* value)
  {
      model_data* data = static_cast<model_data*>(c);
      if (data == NULL) return fmi2Error;
      for (size_t i = 0; i < nvr; i++)
      {
          if (vr[i] >= NUMBER_OF_STRINGS) return fmi2Error;
          data->str_vars[vr[i]] = value[i];
          data->modify((&data->str_vars[vr[i]]));
      }
      return fmi2OK;
  }

  >>
end setStringFunction2;

template equation_function(SimEqSystem eq, Context context, Text &varDecls, Text &eqs, String modelNamePrefix)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently (not at all in this backed)."
::=
  let ix = equationIndex(eq) /*System.tmpTickIndex(10)*/
  let &varD = buffer ""
  let x = equation_(eq,contextOther,varD)
  let() = System.tmpTickResetIndex(0,1) /* Boxed array indices */
  let &eqs +=
  <<

  /*
   <%dumpEqs(fill(eq,1))%>
   */
  static void eqFunction_<%ix%>(model_data *data)
  {
      <%&varD%>
      <%x%>
  }
  >>
  <<
  >>
end equation_function;

template EquationGraphHelper(DAE.Exp exp,String funcType, String ix)
::=
  match exp
  case ICONST(__) then ""
  case RCONST(__) then ""
  case SCONST(__) then ""
  case BCONST(__) then ""
  case ENUM_LITERAL(__) then ""
  case CREF(__) then
    <<
    data->link(&<%cref(componentRef)%>,eq<%funcType%>_<%ix%>);
    >>
  case BINARY(__) then
    <<
    <%EquationGraphHelper(exp1,funcType,ix)%>
    <%EquationGraphHelper(exp2,funcType,ix)%>
    >>
  case UNARY(__) then
    <<
    <%EquationGraphHelper(exp,funcType,ix)%>
    >>
  case LUNARY(__) then
    <<
    <%EquationGraphHelper(exp,funcType,ix)%>
    >>
  case RELATION(__) then
    <<
    <%EquationGraphHelper(exp1,funcType,ix)%>
    <%EquationGraphHelper(exp2,funcType,ix)%>
    >>
  case IFEXP(__) then
    <<
    <%EquationGraphHelper(expCond,funcType,ix)%>
    <%EquationGraphHelper(expThen,funcType,ix)%>
    <%EquationGraphHelper(expElse,funcType,ix)%>
    >>
  case CALL(__) then
    let call_exp = (expLst |> eq => EquationGraphHelper(eq,funcType,ix)
      ;separator="\n")
    <<
    <%call_exp%>
    >>
  case RECORD(__) then "RECORD NOT SUPPORTED"
  case PARTEVALFUNCTION(__) then "PARTEVALFUNCTION NOT SUPPORTED"
  case ARRAY(__) then "ARRAY NOT SUPPORTED"
  case MATRIX(__) then "MATRIX NOT SUPPORTED"
  case RANGE(__) then "RANGE NOT SUPPORTED"
  case TUPLE(__) then "TUPLE NOT SUPPORTED"
  case CAST(__) then "CAST NOT SUPPORTED"
  case ASUB(__) then "ASUB NOT SUPPORTED"
  case TSUB(__) then "TSUB NOT SUPPORTED"
  case SIZE(__) then "SIZE NOT SUPPORTED"
  case CODE(__) then "CODE NOT SUPPORTED"
  case REDUCTION(__) then "REDUCTION NOT SUPPORTED"
  case LIST(__) then "LIST NOT SUPPORTED"
  case CONS(__) then "CONS NOT SUPPORTED"
  case META_TUPLE(__) then "META_TUPLE NOT SUPPORTED"
  case META_OPTION(__) then "META_OPTION NOT SUPPORTED"
  case METARECORDCALL(__) then "METARECORDCALL NOT SUPPORTED"
  case MATCHEXPRESSION(__) then "MATCHEXPRESSION NOT SUPPORTED"
  case BOX(__) then "BOX NOT SUPPORTED"
  case UNBOX(__) then "UNBOX NOT SUPPORTED"
  case SHARED_LITERAL(__) then "SHARED_LITERAL NOT SUPPORTED"
  case PATTERN(__) then "PATTERN NOT SUPPORTED"
  else "EXPRESSION NOT SUPPORTED"
end EquationGraphHelper;

template EquationGraph(SimEqSystem eq)
::=
  let ix = equationIndex(eq)
  match eq
  case e as SES_SIMPLE_ASSIGN(__)
    then
    <<
    data->link(eqFunction_<%ix%>,&<%cref(cref)%>);
    <%EquationGraphHelper(exp,"Function",ix)%>
    >>
  case e as SES_ARRAY_CALL_ASSIGN(__)
    then "ARRAY_CALL"
  case e as SES_IFEQUATION(__)
    then "IF EQUATIONS"
  case e as SES_ALGORITHM(__)
    then "ALG"
  case e as SES_LINEAR(lSystem=ls as LINEARSYSTEM(__))
    then
    let output_vars = (ls.vars |> var => (
                 match var
                   case SIMVAR(__)
                   then
                   <<
                   data->link(eqFunction_<%ix%>,&<%cref(name)%>);
                   >>
             ) ;separator="\n")
    let input_vars = (ls.beqs |> eq => EquationGraphHelper(eq,"Function",ix)
             ;separator="\n")
    <<
    <%output_vars%>
    <%input_vars%>
    >>
  case e as SES_NONLINEAR(__)
    then "NONLINEAR"
  case e as SES_WHEN(__)
    then "WHEN"
  case e as SES_RESIDUAL(__)
    then "NOT IMPLEMENTED EQUATION SES_RESIDUAL"
  case e as SES_MIXED(__)
    then "MIXED"
  else
    "NOT IMPLEMENTED EQUATION equation_"
end EquationGraph;

template generateEquationGraph(list<SimEqSystem> allEquations, list<ZeroCrossing> zeroCrossings)
 "Generate dependency graphs for all equations and variables in the model."
::=
  let xx = (allEquations |> eq => EquationGraph(eq)
      ;separator="\n")
  let zz = (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 => EquationGraphHelper(relation_,"ZeroCrossing",i0)
      ;separator="\n")
  <<
  // Dynamic equations
  <%xx%>
  // Zero crossings
  <%zz%>
  >>
end generateEquationGraph;

// All of this is imported from CodegenAdevs

template zeroCrossingEqns(list<ZeroCrossing> zeroCrossings)
  "Generates function in simulation file."
::=
  let EventFuncCode = (zeroCrossings |> ZERO_CROSSING(__) hasindex idx =>
     (
        let &varDecls = buffer "" /*BUFD*/
        let exp = zeroCrossingEquation(idx, relation_, &varDecls /*bufd*/)
        <<
        static void eqZeroCrossing_<%idx%>(model_data* data)
        {
          <%varDecls%>
          <%exp%>
        }

     >>
     )
  ;separator="\n")
  <<
  <%EventFuncCode%>
  >>
end zeroCrossingEqns;

template allEqns(list<SimEqSystem> allEquationsPlusWhen, list<SimEqSystem> removedEqns)
::=
  let &varDecls = buffer "" /*BUFD*/
  let eqs = (allEquationsPlusWhen |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFD*/)
    ;separator="\n")
  let aliasEqs = (removedEqns |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFD*/)
    ;separator="\n")
  <<
  <%varDecls%>
  // Primary equations
  <%eqs%>
  // Alias equations
  <%aliasEqs%>
  >>
end allEqns;

// Below here is from the Cpp template

template lastIdentOfPath(Path modelName) ::=
  match modelName
  case QUALIFIED(__) then lastIdentOfPath(path)
  case IDENT(__)     then name
  case FULLYQUALIFIED(__) then lastIdentOfPath(path)
end lastIdentOfPath;

// Below here is from the C template but modified in many instances

template zeroCrossingEquation(Integer index1, Exp relation, Text &varDecls /*BUFP*/)
 "Generates code for a zero crossing relations."
::=
  match relation
  case RELATION(__) then
    let &preExp = buffer "" /*BUFD*/
    let e1 = daeExp(exp1, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let op = zeroCrossingOpFunc(operator)
    let e2 = daeExp(exp2, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <%preExp%>
    data->z[<%index1%>] = (<%e1%>)-(<%e2%>);
    >>
  case CALL(path=IDENT(name="floor"), expLst={exp1, idx}) then
    <<
    >>
  case CALL(path=IDENT(name="integer"), expLst={exp1, idx}) then
    <<
    >>
  case CALL(path=IDENT(name="ceil"), expLst={exp1, idx}) then
    <<
    >>
  case CALL(path=IDENT(name="div"), expLst={exp1, exp2, idx}) then
    <<
    >>
  else
    <<
    // IN RELATION: UNKNOWN ZERO CROSSING for <%index1%>
    assert(false);
    >>
end zeroCrossingEquation;

template zeroCrossingOpFunc(Operator op)
 "Generates zero crossing function name for operator."
::=
  match op
  case LESS(__)      then "Adevs_Less"
  case GREATER(__)   then "Adevs_Greater"
  case LESSEQ(__)    then "Adevs_LessEq"
  case GREATEREQ(__) then "Adevs_GreaterEq"
end zeroCrossingOpFunc;

template equation_(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case e as SES_SIMPLE_ASSIGN(__)
    then equationSimpleAssign(e, context, &varDecls /*BUFD*/)
  case e as SES_ARRAY_CALL_ASSIGN(__)
    then equationArrayCallAssign(e, context, &varDecls /*BUFD*/)
  case e as SES_ALGORITHM(__)
    then equationAlgorithm(e, context, &varDecls /*BUFD*/)
  case e as SES_LINEAR(__)
    then equationLinear(e, context, &varDecls /*BUFD*/)
  case e as SES_MIXED(__)
    then equationMixed(e, context, &varDecls /*BUFD*/)
  case e as SES_NONLINEAR(__)
    then equationNonlinear(e, context, &varDecls /*BUFD*/)
  case e as SES_WHEN(__)
    then equationWhen(e, context, &varDecls /*BUFD*/)
  case e as SES_RESIDUAL(__)
    then "NOT IMPLEMENTED SES_RESIDUAL"
  else
    "NOT IMPLEMENTED EQUATION"
end equation_;


template equationSimpleAssign(SimEqSystem eq, Context context,
                              Text &varDecls /*BUFP*/)
 "Generates an equation that is just a simple assignment."
::=
match eq
case SES_SIMPLE_ASSIGN(__) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%preExp%>
  <%cref(cref)%> = <%expPart%>;
  >>
end equationSimpleAssign;


template equationArrayCallAssign(SimEqSystem eq, Context context,
                                 Text &varDecls /*BUFP*/)
 "Generates equation on form 'cref_array = call(...)'."
::=
match eq

case eqn as SES_ARRAY_CALL_ASSIGN(lhs=lhs as CREF(__)) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(exp, context, &preExp, &varDecls /*BUFD*/)
  <<
  <%preExp%>
  <%crefarray(lhs.componentRef)%>.assign(<%expPart%>);
  >>
end equationArrayCallAssign;

template equationAlgorithm(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates an equation that is an algorithm."
::=
match eq
case SES_ALGORITHM(__) then
  (statements |> stmt =>
    algStatement(stmt, context, &varDecls /*BUFD*/)
  ;separator="\n")
end equationAlgorithm;


template equationLinear(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates a linear equation system."
::=
match eq
case SES_LINEAR(lSystem=ls as LINEARSYSTEM(__)) then
  let uid = System.tmpTick()
  let size = listLength(ls.vars)
  let aname = 'A<%uid%>'
  let bname = 'b<%uid%>'
  let pname = 'p<%uid%>'
  let mixedPostfix = if ls.partOfMixed then "_mixed" //else ""
  <<
  <% if not ls.partOfMixed then
    <<
    >> %>
  double* <%aname%> = new double[<%size%>*<%size%>];
  double* <%bname%> = new double[<%size%>];
  long int* <%pname%> = new long int[<%size%>];
  for (int i = 0; i < <%size%>; i++)
  {
    for (int j = 0; j < <%size%>; j++)
    {
      <%aname%>[j+i*<%size%>] = 0.0;
    }
    <%pname%>[i] = i;
    <%bname%>[i] = 0.0;
  }
  <%ls.simJac |> (row, col, eq as SES_RESIDUAL(__)) =>
     let &preExp = buffer "" /*BUFD*/
     let expPart = daeExp(eq.exp, context, &preExp /*BUFC*/,  &varDecls /*BUFD*/)
     '<%preExp%><%aname%>[<%row%>+<%col%>*<%size%>] = <%expPart%>;'
  ;separator="\n"%>
  <%ls.beqs |> exp hasindex i0 =>
     let &preExp = buffer "" /*BUFD*/
     let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
     '<%preExp%><%bname%>[<%i0%>] = <%expPart%>;'
  ;separator="\n"%>
  <%ls.residual |> exp =>
     let &preExp = buffer "" /*BUFD*/
     match exp
     case SES_RESIDUAL(__) then
         let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
         '<%preExp%><%expPart%>;'
    else
         let expPart = equation_(exp, context, &varDecls /*BUFD*/)
         '<%preExp%><%expPart%>;'
  ;separator="\n"%>
  GETRF<%mixedPostfix%>(<%aname%>,<%size%>,<%pname%>);
  GETRS<%mixedPostfix%>(<%aname%>,<%size%>,<%pname%>,<%bname%>);
  <%ls.vars |> SIMVAR(__) hasindex i0 => '<%cref(name)%> = <%bname%>[<%i0%>];' ;separator="\n"%>
  <% if not ls.partOfMixed then
  <<
  delete [] <%aname%>;
  delete [] <%bname%>;
  delete [] <%pname%>;
  >> %>
  >>
end equationLinear;

template equationMixed(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates a mixed equation system."
::=
match eq
case SES_MIXED(__) then
  let contEqs = equation_(cont, context, &varDecls /*BUFD*/)
  let &preDisc = buffer "" /*BUFD*/
  let discLoc2 = (discEqs |> SES_SIMPLE_ASSIGN(__) hasindex i0 =>
      let expPart = daeExp(exp, context, &preDisc /*BUFC*/, &varDecls /*BUFD*/)
      <<
      <%cref(cref)%> = <%expPart%>;
      >>
    ;separator="\n")
  <<
  <%preDisc%>
  <%discLoc2%>
  <%contEqs%>
  >>
end equationMixed;


template equationNonlinear(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates a non linear equation system."
::=
match eq
case SES_NONLINEAR(nlSystem=nls as NONLINEARSYSTEM(__)) then
  <<
  solve_residualFunc<%nls.index%>_cpp();
  >>
end equationNonlinear;

template equationWhen(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates a when equation."
::=
match eq
case SES_WHEN(whenStmtLst = whenStmtLstt,conditions=conditions,elseWhen = NONE()) then
  let helpIf = (conditions |> e => '(<%cref(e)%> && !_PRE<%cref(e)%> /* edge */)';separator=" || ")
  let assign = whenOperators(whenStmtLst, context, &varDecls)
  <<
  if (atEvent) {
      if (<%helpIf%>) {
          <%assign%>
      }
  }
  >>
  case SES_WHEN(whenStmtLst = whenStmtLst,conditions=conditions,elseWhen = SOME(elseWhenEq)) then
  let helpIf = (conditions |> e => '(<%cref(e)%> && !_PRE<%cref(e)%> /* edge */)';separator=" || ")
  let assign = whenOperators(whenStmtLst, context, &varDecls)
  let elseWhen = equationElseWhen(elseWhenEq,context,varDecls)
  <<
  if (atEvent) {
      if (<%helpIf%>) {
          <%assign%>
      }
      <%elseWhen%>
  }
  >>
end equationWhen;

template equationElseWhen(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates a else when equation."
::=
match eq
case SES_WHEN(whenStmtLst = whenStmtLst,conditions=conditions,elseWhen = NONE()) then
  let helpIf = (conditions |> e => '(<%cref(e)%> && !_PRE<%cref(e)%> /* edge */)';separator=" || ")
  let assign = whenOperators(whenStmtLst, context, &varDecls)
  <<
  else if (<%helpIf%>) {
    <%assign%>
  }
  >>
case SES_WHEN(whenStmtLst = whenStmtLst,conditions=conditions,elseWhen = SOME(elseWhenEq)) then
  let helpIf = (conditions |> e => '(<%cref(e)%> && !_PRE<%cref(e)%> /* edge */)';separator=" || ")
  let assign = whenOperators(whenStmtLst, context, &varDecls)
  let elseWhen = equationElseWhen(elseWhenEq,context,varDecls)
  <<
  else if (<%helpIf%>) {
    <%assign%>
  }
  <%elseWhen%>
  >>
end equationElseWhen;

template whenOperators(list<WhenOperator> whenOps, Context context, Text &varDecls)
  "Generates body statements for when equation."
::=
  let body = (whenOps |> whenOp =>
    match whenOp
    case ASSIGN(left = lhs as DAE.CREF(componentRef = cr)) then
      let &preExp = buffer "" /*BUFD*/
      let exp = daeExp(right, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      <<
        <%preExp%>
        <%cref(cr)%> = <%exp%>;
      >>
    case REINIT(__) then
      let &preExp = buffer "" /*BUFD*/
      let val = daeExp(value, contextSimulationDiscrete,
                   &preExp /*BUFC*/, &varDecls /*BUFD*/)
     <<
      <%preExp%>
                double <%cref(stateVar)%>_tmp = <%cref(stateVar)%>;
                <%cref(stateVar)%> = <%val%>;
                reInit = reInit || (<%cref(stateVar)%>_tmp != <%cref(stateVar)%>);
                >>
    case TERMINATE(__) then
      let &preExp = buffer "" /*BUFD*/
    let msgVar = daeExp(message, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
                <%preExp%>
                MODELICA_TERMINATE(<%msgVar%>);
                >>
  case ASSERT(source=SOURCE(info=info)) then
    assertCommon(condition, message, contextSimulationDiscrete, &varDecls, info)
  ;separator="\n")
  <<
  <%body%>
  >>
end whenOperators;

template startValue(DAE.Type ty)
::=
  match ty
  case ty as T_INTEGER(__) then '0'
  case ty as T_REAL(__) then '0.0'
  case ty as T_BOOL(__) then 'false'
  case ty as T_STRING(__) then 'empty'
  case ty as T_ENUMERATION(__) then '0'
  else ""
end startValue;

template contextCref(ComponentRef cr, Context context)
  "Generates code for a component reference depending on which context we're in."
::=
  match context
  case FUNCTION_CONTEXT(__) then "_" + crefStr(cr)
  else cref(cr)
end contextCref;

template contextIteratorName(Ident name, Context context)
  "Generates code for an iterator variable."
::=
  match context
  case FUNCTION_CONTEXT(__) then "_" + name
  else "$P" + name
end contextIteratorName;

template crefarray(ComponentRef cr)
 "Generates C++ name for component reference."
::=
  match cr
    case WILD(__) then ''
    else "_"+ crefarray2(cr)
end crefarray;

template crefarray2(ComponentRef cr)
::=
  match cr
    case CREF_IDENT(__) then
      '<%unquoteIdentifier(ident)%>'
    case CREF_QUAL(ident="$PRE") then
      '_PRE_<%crefarray2(componentRef)%>'
    case CREF_QUAL(ident="$DER") then
      'DER_<%crefarray2(componentRef)%>'
    case CREF_QUAL(__) then
      '<%unquoteIdentifier(ident)%>_<%crefarray2(componentRef)%>'
    case WILD(__) then ''
    else "CREF_NOT_IDENT_OR_QUAL"
end crefarray2;

template cref(ComponentRef cr)
 "Generates C++ name for component reference."
::=
  match cr
    case CREF_IDENT(ident = "time") then "timeValue"
    case WILD(__) then ''
    else
        let &arrayIndices = buffer ""
        let varName = crefToCStr(cr,&arrayIndices)
        if arrayIndices then
          '_<%varName%>_<%arrayIndices%>_'
        else
          '_<%varName%>'
end cref;

template crefToCStr(ComponentRef cr, Text &arrayIndices)
 "Helper function to cref."
::=
  let tmp = arrayIndices
  match cr
    case CREF_IDENT(__) then
      let &arrayIndices += subscriptsToCStr(subscriptLst,tmp)
      '<%unquoteIdentifier(ident)%>'
    case CREF_QUAL(ident="$PRE") then
      let &arrayIndices += subscriptsToCStr(subscriptLst,tmp)
      '_PRE_<%crefToCStr(componentRef,&arrayIndices)%>'
    case CREF_QUAL(ident="$DER") then
      let &arrayIndices += subscriptsToCStr(subscriptLst,tmp)
      'DER_<%crefToCStr(componentRef,&arrayIndices)%>'
    case CREF_QUAL(__) then
      let &arrayIndices += subscriptsToCStr(subscriptLst,tmp)
      '<%unquoteIdentifier(ident)%>_<%crefToCStr(componentRef,&arrayIndices)%>'
    case WILD(__) then ''
    else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStr;

template subscriptsToCStrForArray(list<Subscript> subscripts)
::=
  if subscripts then
    '<%subscripts |> s => subscriptToCStr(s) ;separator="$c"%>'
end subscriptsToCStrForArray;

template subscriptsToCStr(list<Subscript> subscripts, String arrayIndices)
::=
  if not arrayIndices then
    (subscripts |> i => '<%subscriptToCStr(i)%>';separator="_")
  else if subscripts then
    '_<%(subscripts |> i => '<%subscriptToCStr(i)%>';separator="_")%>'
end subscriptsToCStr;

template subscriptsToCStr2(list<Subscript> subscripts)
::=
  if subscripts then
    (subscripts |> i => '_<%subscriptToCStr(i)%>_';separator="")
end subscriptsToCStr2;

template crefToCStr1(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(__) then '<%ident%>'
  case CREF_QUAL(__) then '<%ident%><%subscriptsToCStrForArray(subscriptLst)%>_P_<%crefToCStr1(componentRef)%>'
  case WILD(__) then ' '
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStr1;

template subscriptToCStr(Subscript subscript)
::=
  match subscript
  case INDEX(exp=ICONST(integer=i)) then intSub(i,1)
  case SLICE(exp=ICONST(integer=i)) then intSub(i,1)
  case WHOLEDIM(__) then "WHOLEDIM"
  else "UNKNOWN_SUBSCRIPT"
end subscriptToCStr;

template subscriptsStr(list<Subscript> subscripts)
 "Generares subscript part of the name."
::=
  if subscripts then
    '[<%subscripts |> s => subscriptStr(s) ;separator="_"%>]'
end subscriptsStr;

template crefStr(ComponentRef cr)
 "Generates the name of a variable for variable name array."
::=
  match cr
  case CREF_IDENT(__) then '<%ident%><%subscriptsStr(subscriptLst)%>'
  // Are these even needed? Function context should only have CREF_IDENT :)
  case CREF_QUAL(ident = "$DER") then 'der(<%crefStr(componentRef)%>)'
  case CREF_QUAL(__) then '<%ident%><%subscriptsStr(subscriptLst)%>_<%crefStr(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end crefStr;

template contextArrayCref(ComponentRef cr, Context context)
 "Generates code for an array component reference depending on the context."
::=
  match context
  case FUNCTION_CONTEXT(__) then "_" + arrayCrefStr(cr)
  else arrayCrefCStr(cr)
end contextArrayCref;

template arrayCrefCStr(ComponentRef cr)
::= '$P<%arrayCrefCStr2(cr)%>'
end arrayCrefCStr;

template arrayCrefCStr2(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(__) then '<%unquoteIdentifier(ident)%>'
  case CREF_QUAL(__) then '<%unquoteIdentifier(ident)%><%subscriptsToCStr2(subscriptLst)%>$P<%arrayCrefCStr2(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end arrayCrefCStr2;

template arrayCrefStr(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(__) then '<%ident%>'
  case CREF_QUAL(__) then '<%ident%>.<%arrayCrefStr(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end arrayCrefStr;

template expCref(DAE.Exp ecr)
::=
  match ecr
  case CREF(__) then cref(componentRef)
  case CALL(path = IDENT(name = "der"), expLst = {arg as CREF(__)}) then
    '_DER<%cref(arg.componentRef)%>'
  else "ERROR_NOT_A_CREF"
end expCref;

template crefFunctionName(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(__) then
    System.stringReplace(unquoteIdentifier(ident), "_", "__")
  case CREF_QUAL(__) then
    '<%System.stringReplace(unquoteIdentifier(ident), "_", "__")%>_<%crefFunctionName(componentRef)%>'
end crefFunctionName;

template dotPath(Path path)
 "Generates paths with components separated by dots."
::=
  match path
  case QUALIFIED(__)      then '<%name%>.<%dotPath(path)%>'

  case IDENT(__)          then name
  case FULLYQUALIFIED(__) then dotPath(path)
end dotPath;

template functionHeaders(list<Function> functions)
 "Generates function header part in function files."
::=
  (functions |> fn => functionHeader(fn, false) ; separator="\n")
end functionHeaders;

template functionHeader(Function fn, Boolean inFunc)
 "Generates function header part in function files."
::=
  match fn
    case FUNCTION(__) then
      <<
      <%functionHeaderNormal(underscorePath(name), functionArguments, outVars, inFunc, false)%>
      <%functionHeaderBoxed(underscorePath(name), functionArguments, outVars, isBoxedFunction(fn), false)%>
      >>
    case EXTERNAL_FUNCTION(dynamicLoad=true) then
      <<
      <%functionHeaderNormal(underscorePath(name), funArgs, outVars, inFunc, true)%>
      <%functionHeaderBoxed(underscorePath(name), funArgs, outVars, isBoxedFunction(fn), true)%>

      <%extFunDefDynamic(fn)%>
      >>
    case EXTERNAL_FUNCTION(__) then
      <<
      <%functionHeaderNormal(underscorePath(name), funArgs, outVars, inFunc, false)%>
      <%functionHeaderBoxed(underscorePath(name), funArgs, outVars, isBoxedFunction(fn), false)%>

      <%extFunDef(fn)%>
      >>
    case RECORD_CONSTRUCTOR(__) then
      let fname = underscorePath(name)
      let funArgsStr = (funArgs |> var as VARIABLE(__) =>
          '<%varType(var)%> <%crefStr(name)%>'
        ;separator=", ")
      let funArgsBoxedStr = if acceptMetaModelicaGrammar() then
          (funArgs |> var => funArgBoxedDefinition(var) ;separator=", ")
      let boxedHeader = if acceptMetaModelicaGrammar() then
        <<
        modelica_metatype boxptr_<%fname%>(<%funArgsBoxedStr%>);
        >>
      <<
      #define <%fname%>_rettype_1 targ1
      typedef struct <%fname%>_rettype_s {
        struct <%fname%> targ1;
      } <%fname%>_rettype;

      <%fname%>_rettype _<%fname%>(<%funArgsStr%>);

      <%boxedHeader%>
      >>
end functionHeader;

template recordDeclaration(RecordDeclaration recDecl)
 "Generates structs for a record declaration."
::=
  match recDecl
  case RECORD_DECL_FULL(__) then
    <<
    <%recordDefinition(dotPath(defPath),
                      underscorePath(defPath),
                      (variables |> VARIABLE(__) => '"<%crefStr(name)%>"' ;separator="_"),
                      listLength(variables))%>
    >>
  case RECORD_DECL_DEF(__) then
    <<
    <%recordDefinition(dotPath(path),
                      underscorePath(path),
                      (fieldNames |> name => '"<%name%>"' ;separator="_"),
                      listLength(fieldNames))%>
    >>
end recordDeclaration;

template recordDeclarationHeader(RecordDeclaration recDecl)
 "Generates structs for a record declaration."
::=
  match recDecl
  case RECORD_DECL_FULL(__) then
    <<
    struct <%name%> {
      <%variables |> var as VARIABLE(__) => '<%varType(var)%> <%crefStr(var.name)%>;' ;separator="\n"%>
    };
    <%recordDefinitionHeader(dotPath(defPath),
                      underscorePath(defPath),
                      listLength(variables))%>
    >>
  case RECORD_DECL_DEF(__) then
    <<
    <%recordDefinitionHeader(dotPath(path),
                      underscorePath(path),
                      listLength(fieldNames))%>
    >>
end recordDeclarationHeader;

template recordDefinition(String origName, String encName, String fieldNames, Integer numFields)
 "Generates the definition struct for a record declaration."
::=
  /* adrpo 2011-03-14 make MSVC happy, no arrays of 0 size! */
  let fieldsDescription =
      match numFields
       case 0 then
         'const char* <%encName%>__desc__fields[1] = {"no fields"};'
       case _ then
         'const char* <%encName%>__desc__fields[<%numFields%>] = {<%fieldNames%>};'
  <<
  #define <%encName%>__desc_added 1
  <%fieldsDescription%>
  struct record_description <%encName%>__desc = {
    "<%encName%>", /* package_record__X */
    "<%origName%>", /* package.record_X */
    <%encName%>__desc__fields
  };
  >>
end recordDefinition;

template recordDefinitionHeader(String origName, String encName, Integer numFields)
 "Generates the definition struct for a record declaration."
::=
  <<
  extern struct record_description <%encName%>__desc;
  >>
end recordDefinitionHeader;

template functionHeaderNormal(String fname, list<Variable> fargs, list<Variable> outVars, Boolean inFunc, Boolean dynamicLoad)
::= functionHeaderImpl(fname, fargs, outVars, inFunc, false, dynamicLoad)
end functionHeaderNormal;

template functionHeaderBoxed(String fname, list<Variable> fargs, list<Variable> outVars, Boolean isBoxed, Boolean dynamicLoad)
::= if acceptMetaModelicaGrammar() then
    if isBoxed then '#define boxptr_<%fname%> _<%fname%><%\n%>' else functionHeaderImpl(fname, fargs, outVars, false, true, dynamicLoad)
end functionHeaderBoxed;

template functionHeaderImpl(String fname, list<Variable> fargs, list<Variable> outVars, Boolean inFunc, Boolean boxed, Boolean dynamicLoad)
 "Generates function header for a Modelica/MetaModelica function. Generates a

  boxed version of the header if boxed = true, otherwise a normal header"
::=
  let fargsStr = if boxed then
      (fargs |> var => funArgBoxedDefinition(var) ;separator=", ")
    else
      (fargs |> var => funArgDefinition(var) ;separator=", ")
  let boxStr = if boxed then "boxed"
  let boxPtrStr = if boxed then "boxptr"
  let inFnStr = if boxed then "" else if inFunc then
    <<

    DLLExport
    int in_<%fname%>(type_description * inArgs, type_description * outVar);
    >>

  if outVars then <<
  <%outVars |> _ hasindex i1 fromindex 1 => '#define <%fname%>_rettype<%boxStr%>_<%i1%> targ<%i1%>' ;separator="\n"%>
  typedef struct <%fname%>_rettype<%boxStr%>_s
  {
    <%outVars |> var hasindex i1 fromindex 1 =>
      match var
      case VARIABLE(__) then
        let dimStr = match ty case T_ARRAY(__) then
          '[<%dims |> dim => dimension(dim) ;separator=", "%>]'
        let typeStr = if boxed then varTypeBoxed(var) else varType(var)
        '<%typeStr%> targ<%i1%>; /* <%crefStr(name)%><%dimStr%> */'
      case FUNCTION_PTR(__) then
        'modelica_fnptr targ<%i1%>; /* <%name%> */'
      ;separator="\n"
    %>
  } <%fname%>_rettype<%boxStr%>;
  <%inFnStr%>

  <%if dynamicLoad then '' else '<%fname%>_rettype<%boxStr%> <%boxPtrStr%>_<%fname%>(<%fargsStr%>);'%>
  >> else <<

  <%if dynamicLoad then '' else 'void <%boxPtrStr%>_<%fname%>(<%fargsStr%>);'%>
  >>
end functionHeaderImpl;

template funArgName(Variable var)
::=
  match var
  case VARIABLE(__) then contextCref(name,contextFunction)
  case FUNCTION_PTR(__) then name
end funArgName;

template funArgDefinition(Variable var)
::=
  match var
  case VARIABLE(__) then '<%varType(var)%> <%contextCref(name,contextFunction)%>'
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end funArgDefinition;

template funArgBoxedDefinition(Variable var)
 "A definition for a boxed variable is always of type modelica_metatype,
  unless it's a function pointer"
::=
  match var
  case VARIABLE(__) then 'modelica_metatype <%contextCref(name,contextFunction)%>'
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end funArgBoxedDefinition;

template extFunDef(Function fn)
 "Generates function header for an external function."
::=
match fn
case func as EXTERNAL_FUNCTION(__) then
  let fn_name = extFunctionName(extName, language)
  let fargsStr = extFunDefArgs(extArgs, language)
  'extern <%extReturnType(extReturn)%> <%fn_name%>(<%fargsStr%>);'
end extFunDef;

template extFunDefDynamic(Function fn)
 "Generates function header for an external function."
::=
match fn
case func as EXTERNAL_FUNCTION(__) then
  let fn_name = extFunctionName(extName, language)
  let fargsStr = extFunDefArgs(extArgs, language)
  <<
  typedef <%extReturnType(extReturn)%> (*ptrT_<%fn_name%>)(<%fargsStr%>);
  extern ptrT_<%fn_name%> ptr_<%fn_name%>;
  >>
end extFunDefDynamic;

template extFunctionName(String name, String language)
::=
  match language
  case "C" then '<%name%>'
  case "FORTRAN 77" then '<%name%>_'
  else error(sourceInfo(), 'Unsupport external language: <%language%>')
end extFunctionName;

template extFunDefArgs(list<SimExtArg> args, String language)
::=
  match language
  case "C" then (args |> arg => extFunDefArg(arg) ;separator=", ")
  case "FORTRAN 77" then (args |> arg => extFunDefArgF77(arg) ;separator=", ")
  else error(sourceInfo(), 'Unsupport external language: <%language%>')
end extFunDefArgs;

template extReturnType(SimExtArg extArg)
 "Generates return type for external function."
::=
  match extArg
  case ex as SIMEXTARG(__)    then extType(type_,true /*Treat this as an input (pass by value)*/,false)
  case SIMNOEXTARG(__)  then "void"
  case SIMEXTARGEXP(__) then error(sourceInfo(), 'Expression types are unsupported as return arguments <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
  else error(sourceInfo(), "Unsupported return argument")
end extReturnType;


template extType(Type type, Boolean isInput, Boolean isArray)
 "Generates type for external function argument or return value."
::=
  let s = match type
  case T_INTEGER(__)         then "int"
  case T_REAL(__)        then "double"
  case T_STRING(__)      then "const char*"
  case T_BOOL(__)        then "int"
  case T_ENUMERATION(__) then "int"
  case T_ARRAY(__)       then extType(ty,isInput,true)
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__))
                      then "void *"
  case T_COMPLEX(complexClassType=RECORD(path=rname))
                      then 'struct <%underscorePath(rname)%>'
  case T_METATYPE(__) case T_METABOXED(__)    then "modelica_metatype"
  else error(sourceInfo(), 'Unknown external C type <%unparseType(type)%>')
  match type case T_ARRAY(__) then s else if isInput then (if isArray then '<%match s case "const char*" then "" else "const "%><%s%>*' else s) else '<%s%>*'
end extType;

template extTypeF77(Type type, Boolean isReference)
  "Generates type for external function argument or return value for F77."
::=
  let s = match type
  case T_INTEGER(__)         then "int"
  case T_REAL(__)        then "double"
  case T_STRING(__)      then "char*"
  case T_BOOL(__)        then "int"
  case T_ENUMERATION(__) then "int"
  case T_ARRAY(__)       then extTypeF77(ty, true)
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__))
                      then "void*"
  case T_COMPLEX(complexClassType=RECORD(path=rname))
                      then 'struct <%underscorePath(rname)%>'
  case T_METATYPE(__) case T_METABOXED(__)    then "void*"
  else error(sourceInfo(), 'Unknown external F77 type <%unparseType(type)%>')
  match type case T_ARRAY(__) then s else if isReference then '<%s%>*' else s
end extTypeF77;

template extFunDefArg(SimExtArg extArg)
 "Generates the definition of an external function argument.
  Assume that language is C for now."
::=
  match extArg
  case SIMEXTARG(cref=c, isInput=ii, isArray=ia, type_=t) then
    let name = contextCref(c,contextFunction)
    let typeStr = extType(t,ii,ia)
    <<
    <%typeStr%> /*<%name%>*/
    >>
  case SIMEXTARGEXP(__) then
    let typeStr = extType(type_,true,false)
    <<
    <%typeStr%>
    >>
  case SIMEXTARGSIZE(cref=c) then
    <<
    size_t
    >>
end extFunDefArg;

template extFunDefArgF77(SimExtArg extArg)
::=
  match extArg
  case SIMEXTARG(cref=c, isInput = isInput, type_=t) then
    let name = contextCref(c,contextFunction)
    let typeStr = '<%extTypeF77(t,true)%>'
    '<%typeStr%> /*<%name%>*/'

  case SIMEXTARGEXP(__) then '<%extTypeF77(type_,true)%>'
  case SIMEXTARGSIZE(__) then 'int const *'
end extFunDefArgF77;


template functionName(Function fn, Boolean dotPath)
::=
  match fn
  case FUNCTION(__)
  case EXTERNAL_FUNCTION(__)
  case RECORD_CONSTRUCTOR(__) then if dotPath then dotPath(name) else underscorePath(name)
end functionName;


template functionBodies(list<Function> functions)
 "Generates the body for a set of functions."
::=
  (functions |> fn => functionBody(fn, false) ;separator="\n")
end functionBodies;


template functionBody(Function fn, Boolean inFunc)
 "Generates the body for a function."
::=
  match fn
  case fn as FUNCTION(__)           then functionBodyRegularFunction(fn, inFunc)
  case fn as EXTERNAL_FUNCTION(__)  then functionBodyExternalFunction(fn, inFunc)
  case fn as RECORD_CONSTRUCTOR(__) then functionBodyRecordConstructor(fn)
end functionBody;

template addRoots(Variable var)
"template to add the roots, only the meta-types are added!"
::=
  match var
  case var as VARIABLE(__) then
  match ty
    case T_METATYPE(__)
      then 'mmc_GC_add_root(&<%contextCref(var.name,contextFunction)%>, mmc_GC_local_state, "<%contextCref(var.name,contextFunction)%>");'
    case T_METABOXED(__) then 'mmc_GC_add_root(&<%contextCref(var.name,contextFunction)%>, mmc_GC_local_state, "<%contextCref(var.name,contextFunction)%>");'
    /*case T_COMPLEX(__) then 'mmc_GC_add_root(&<%contextCref(var.name,contextFunction)%>, mmc_GC_local_state, "<%contextCref(var.name,contextFunction)%>");'*/
    case _ then
      let typ = varType(var)
      match typ case "modelica_metatype" then 'mmc_GC_add_root(&<%contextCref(var.name,contextFunction)%>, mmc_GC_local_state, "<%contextCref(var.name,contextFunction)%>");'
  end match
end addRoots;

template functionBodyRegularFunction(Function fn, Boolean inFunc)
 "Generates the body for a Modelica/MetaModelica function."
::=
match fn
case FUNCTION(__) then
  let()= System.tmpTickReset(1)
  let fname = underscorePath(name)
  let retType = if outVars then '<%fname%>_rettype' else "void"
  let &varDecls = buffer "" /*BUFD*/
  let &varInits = buffer "" /*BUFD*/
  let retVar = if outVars then tempDecl(retType, &varDecls /*BUFD*/)
  let _ = (variableDeclarations |> var hasindex i1 fromindex 1 =>
      varInit(var, "", i1, &varDecls /*BUFD*/, &varInits /*BUFC*/)
    )
  let addRootsInputs = (functionArguments |> var => addRoots(var) ;separator="\n")
  let addRootsOutputs = (outVars |> var => addRoots(var) ;separator="\n")
  let funArgs = (functionArguments |> var => functionArg(var, &varInits) ;separator="\n")
  let bodyPart = funStatement(body, &varDecls)
  let &outVarInits = buffer ""
  let &outVarCopy = buffer ""
  let &outVarAssign = buffer ""
  let _1 = (outVars |> var hasindex i1 fromindex 1 =>
      varOutput(var, retVar, i1, &varDecls, &outVarInits, &outVarCopy, &outVarAssign)
      ;separator="\n"; empty
    )
  let boxedFn = if acceptMetaModelicaGrammar() then functionBodyBoxed(fn)
  <<
  <%retType%> _<%fname%>(<%functionArguments |> var => funArgDefinition(var) ;separator=", "%>)
  {
    /* arguments */
    <%funArgs%>
    /* locals */
    <%varDecls%>
    /* out inits */
    <%outVarInits%>

    /* var inits */
    <%varInits%>
    /* body */
    <%bodyPart%>

    _return:
    /* out var copy */
    <%outVarCopy%>
    /* out var assign */
    <%outVarAssign%>

    /* return the outs */
    return <%if outVars then ' <%retVar%>' %>;
  }

  <% if inFunc then
  <<
  int in_<%fname%>(type_description * inArgs, type_description * outVar)
  {
    <%functionArguments |> var => '<%funArgDefinition(var)%>;' ;separator="\n"%>
    <%if outVars then '<%retType%> out;'%>
    <%functionArguments |> arg => readInVar(arg) ;separator="\n"%>
    MMC_TRY_TOP()
    <%if outVars then "out = "%>_<%fname%>(<%functionArguments |> var => funArgName(var) ;separator=", "%>);
    MMC_CATCH_TOP(return 1)
    <%if outVars then (outVars |> var hasindex i1 fromindex 1 => writeOutVar(var, i1) ;separator="\n") else "write_noretcall(outVar);"%>
    return 0;
  }
  >>
  %>

  <%boxedFn%>
  >>
end functionBodyRegularFunction;

template functionBodyExternalFunction(Function fn, Boolean inFunc)
 "Generates the body for an external function (just a wrapper)."
::=
match fn
case efn as EXTERNAL_FUNCTION(__) then
  let()= System.tmpTickReset(1)
  let fname = underscorePath(name)
  let retType = if outVars then '<%fname%>_rettype' else "void"
  let &preExp = buffer "" /*BUFD*/
  let &varDecls = buffer "" /*BUFD*/
  // make sure the variable is named "out", doh!
  let retVar = if outVars then outDecl(retType, &varDecls /*BUFD*/)
  let &outputAlloc = buffer "" /*BUFD*/
  let stateVar = if not acceptMetaModelicaGrammar() then tempDecl("state", &varDecls /*BUFD*/)
  let callPart = extFunCall(fn, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let _ = (outVars |> var hasindex i1 fromindex 1 =>
      varInit(var, retVar, i1, &varDecls /*BUFD*/, &outputAlloc /*BUFC*/)
    )
  let boxedFn = if acceptMetaModelicaGrammar() then functionBodyBoxed(fn)
  let fnBody = <<
  <%retType%> _<%fname%>(<%funArgs |> VARIABLE(__) => '<%expTypeArrayIf(ty)%> <%contextCref(name,contextFunction)%>' ;separator=", "%>)
  {
    <%varDecls%>
    <%if not acceptMetaModelicaGrammar() then '<%stateVar%> = get_memory_state();'%>
    <%preExp%>
    <%outputAlloc%>
    <%callPart%>
    <%if not acceptMetaModelicaGrammar() then 'restore_memory_state(<%stateVar%>);'%>
    return <%if outVars then retVar%>;
  }
  >>
  <<
  <% if dynamicLoad then
  <<
  ptrT_<%extFunctionName(extName, language)%> ptr_<%extFunctionName(extName, language)%>=NULL;
  >> %>
  <%fnBody%>

  <% if inFunc then
  <<
  int in_<%fname%>(type_description * inArgs, type_description * outVar)
  {
    <%funArgs |> VARIABLE(__) => '<%expTypeArrayIf(ty)%> <%contextCref(name,contextFunction)%>;' ;separator="\n"%>
    <%retType%> out;
    <%funArgs |> arg as VARIABLE(__) => readInVar(arg) ;separator="\n"%>
    MMC_TRY_TOP()
    out = _<%fname%>(<%funArgs |> VARIABLE(__) => contextCref(name,contextFunction) ;separator=", "%>);
    MMC_CATCH_TOP(return 1)
    <%outVars |> var as VARIABLE(__) hasindex i1 fromindex 1 => writeOutVar(var, i1) ;separator="\n"%>
    return 0;
  }
  >> %>

  <%boxedFn%>
  >>
end functionBodyExternalFunction;


template functionBodyRecordConstructor(Function fn)
 "Generates the body for a record constructor."
::=
match fn
case RECORD_CONSTRUCTOR(__) then
  let()= System.tmpTickReset(1)
  let &varDecls = buffer "" /*BUFD*/
  let fname = underscorePath(name)
  let retType = '<%fname%>_rettype'
  let retVar = tempDecl(retType, &varDecls /*BUFD*/)
  let structType = 'struct <%fname%>'
  let structVar = tempDecl(structType, &varDecls /*BUFD*/)
  let boxedFn = if acceptMetaModelicaGrammar() then functionBodyBoxed(fn)
  <<
  <%retType%> _<%fname%>(<%funArgs |> VARIABLE(__) => '<%expTypeArrayIf(ty)%> <%crefStr(name)%>' ;separator=", "%>)
  {
    <%varDecls%>
    <%funArgs |> VARIABLE(__) => '<%structVar%>.<%crefStr(name)%> = <%crefStr(name)%>;' ;separator="\n"%>
    <%retVar%>.targ1 = <%structVar%>;
    return <%retVar%>;
  }

  <%boxedFn%>




  >>
end functionBodyRecordConstructor;

template functionBodyBoxed(Function fn)
 "Generates code for a boxed version of a function. Extracts the needed data
  from a function and calls functionBodyBoxedImpl"
::=
  match fn
  case FUNCTION(__) then if not isBoxedFunction(fn) then functionBodyBoxedImpl(name, functionArguments, outVars)
  case EXTERNAL_FUNCTION(__) then if not isBoxedFunction(fn) then functionBodyBoxedImpl(name, funArgs, outVars)
  case RECORD_CONSTRUCTOR(__) then boxRecordConstructor(fn)
end functionBodyBoxed;

template functionBodyBoxedImpl(Absyn.Path name, list<Variable> funargs, list<Variable> outvars)
 "Helper template for functionBodyBoxed, does all the real work."
::=
  let() = System.tmpTickReset(1)
  let fname = underscorePath(name)
  let retType = if outvars then '<%fname%>_rettype' else "void"
  let retTypeBoxed = if outvars then '<%retType%>boxed' else "void"
  let &varDecls = buffer ""
  let retVar = if outvars then tempDecl(retTypeBoxed, &varDecls)
  let funRetVar = if outvars then tempDecl(retType, &varDecls)
  let stateVar = if not acceptMetaModelicaGrammar() then tempDecl("state", &varDecls)
  let &varBox = buffer ""
  let &varUnbox = buffer ""
  let args = (funargs |> arg => funArgUnbox(arg, &varDecls, &varBox) ;separator=", ")
  let retStr = (outvars |> var as VARIABLE(__) hasindex i1 fromindex 1 =>
    let arg = '<%funRetVar%>.<%retType%>_<%i1%>'
    '<%retVar%>.<%retTypeBoxed%>_<%i1%> = <%funArgBox(arg, ty, &varUnbox, &varDecls)%>;'
    ;separator="\n")
  <<
  <%retTypeBoxed%> boxptr_<%fname%>(<%funargs |> var => funArgBoxedDefinition(var) ;separator=", "%>)
  {
    /* GC: save roots mark when you enter the function */
    <%if acceptMetaModelicaGrammar()
      then 'mmc_GC_local_state_type mmc_GC_local_state = mmc_GC_save_roots_state("boxptr__<%fname%>");'%>

    <%varDecls%>
    <%if not acceptMetaModelicaGrammar() then '<%stateVar%> = get_memory_state();'%>
    <%varBox%>
    <%if outvars then '<%funRetVar%> = '%>_<%fname%>(<%args%>);
    <%varUnbox%>
    <%retStr%>
    <%if not acceptMetaModelicaGrammar() then 'restore_memory_state(<%stateVar%>);'%>

    /* GC: pop roots mark when you exit the function */
    <%if acceptMetaModelicaGrammar()
      then 'mmc_GC_undo_roots_state(mmc_GC_local_state);'%>

    return <%retVar%>;
  }
  >>
end functionBodyBoxedImpl;

template boxRecordConstructor(Function fn)
::=
match fn
case RECORD_CONSTRUCTOR(__) then
  let() = System.tmpTickReset(1)
  let fname = underscorePath(name)
  let funArgsStr = (funArgs |> var as VARIABLE(__) => contextCref(name,contextFunction) ;separator=", ")
  let funArgCount = incrementInt(listLength(funArgs), 1)
  <<
  modelica_metatype boxptr_<%fname%>(<%funArgs |> var => funArgBoxedDefinition(var) ;separator=", "%>)
  {
    return mmc_mk_box<%funArgCount%>(3, &<%fname%>__desc, <%funArgsStr%>);
  }
  >>
end boxRecordConstructor;

template funArgUnbox(Variable var, Text &varDecls, Text &varBox)
::=
match var
case VARIABLE(__) then
  let varName = contextCref(name,contextFunction)
  unboxVariable(varName, ty, &varBox, &varDecls)
case FUNCTION_PTR(__) then // Function pointers don't need to be boxed.
  name
end funArgUnbox;

template unboxVariable(String varName, Type varType, Text &preExp, Text &varDecls)
::=
match varType
case T_STRING(__) case T_METATYPE(__) case T_METABOXED(__) then varName
case T_COMPLEX(complexClassType = RECORD(__)) then
  unboxRecord(varName, varType, &preExp, &varDecls)
else
  let shortType = mmcTypeShort(varType)
  let ty = 'modelica_<%shortType%>'
  let tmpVar = tempDecl(ty, &varDecls)
  let &preExp += '<%tmpVar%> = mmc_unbox_<%shortType%>(<%varName%>);<%\n%>'
  tmpVar
end unboxVariable;

template unboxRecord(String recordVar, Type ty, Text &preExp, Text &varDecls)
::=
match ty
case T_COMPLEX(complexClassType = RECORD(path = path), varLst = vars) then
  let tmpVar = tempDecl('struct <%underscorePath(path)%>', &varDecls)
  let &preExp += (vars |> TYPES_VAR(name = compname) hasindex offset fromindex 2 =>
    let varType = mmcTypeShort(ty)
    let untagTmp = tempDecl('modelica_metatype', &varDecls)
    //let offsetStr = incrementInt(i1, 1)
    let &unboxBuf = buffer ""
    let unboxStr = unboxVariable(untagTmp, ty, &unboxBuf, &varDecls)
    <<
    <%untagTmp%> = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%recordVar%>), <%offset%>)));
    <%unboxBuf%>
    <%tmpVar%>.<%compname%> = <%unboxStr%>;
    >>
    ;separator="\n")
  tmpVar
end unboxRecord;

template funArgBox(String varName, Type ty, Text &varUnbox, Text &varDecls)
 "Generates code to box a variable."
::=
  let constructorType = mmcConstructorType(ty)
  if constructorType then
    let constructor = mmcConstructor(ty, varName, &varUnbox, &varDecls)
    let tmpVar = tempDecl(constructorType, &varDecls)
    let &varUnbox += '<%tmpVar%> = <%constructor%>;<%\n%>'
    tmpVar
  else // Some types don't need to be boxed, since they're already boxed.
    varName
end funArgBox;

template mmcConstructorType(Type type)
::=
  match type
  case T_INTEGER(__)
  case T_BOOL(__)
  case T_REAL(__)
  case T_ENUMERATION(__)
  case T_ARRAY(__)
  case T_COMPLEX(__) then 'modelica_metatype'
end mmcConstructorType;

template mmcConstructor(Type type, String varName, Text &preExp, Text &varDecls)
::=
  match type
  case T_INTEGER(__) then 'mmc_mk_icon(<%varName%>)'
  case T_BOOL(__) then 'mmc_mk_icon(<%varName%>)'
  case T_REAL(__) then 'mmc_mk_rcon(<%varName%>)'
  case T_STRING(__) then 'mmc_mk_string(<%varName%>)'
  case T_ENUMERATION(__) then 'mmc_mk_icon(<%varName%>)'
  case T_ARRAY(__) then 'mmc_mk_acon(<%varName%>)'
  case T_COMPLEX(complexClassType = RECORD(path = path), varLst = vars) then
    let varCount = incrementInt(listLength(vars), 1)
    let varsStr = (vars |> var as TYPES_VAR(__) =>
      let varname = '<%varName%>.<%name%>'
      funArgBox(varname, ty, &preExp, &varDecls) ;separator=", ")
    'mmc_mk_box<%varCount%>(3, &<%underscorePath(path)%>__desc, <%varsStr%>)'
  case T_COMPLEX(__) then 'mmc_mk_box(<%varName%>)'
end mmcConstructor;

template readInVar(Variable var)
 "Generates code for reading a variable from inArgs."
::=
  match var
  case VARIABLE(name=cr, ty=T_COMPLEX(complexClassType=RECORD(__))) then
    <<
    if (read_modelica_record(&inArgs, <%readInVarRecordMembers(ty, contextCref(cr,contextFunction))%>)) return 1;
    >>
  case VARIABLE(name=cr, ty=T_STRING(__)) then
    <<
    if (read_<%expTypeArrayIf(ty)%>(&inArgs, <%if not acceptMetaModelicaGrammar() then "(char**)"%> &<%contextCref(name,contextFunction)%>)) return 1;
    >>
  case VARIABLE(__) then
    <<
    if (read_<%expTypeArrayIf(ty)%>(&inArgs, &<%contextCref(name,contextFunction)%>)) return 1;
    >>
end readInVar;


template readInVarRecordMembers(Type type, String prefix)
 "Helper to readInVar."
::=
match type
case T_COMPLEX(varLst=vl) then
  (vl |> subvar as TYPES_VAR(__) =>
    match ty case T_COMPLEX(__) then
      let newPrefix = '<%prefix%>.<%subvar.name%>'
      readInVarRecordMembers(ty, newPrefix)
    else
      '&(<%prefix%>.<%subvar.name%>)'
  ;separator=", ")
end readInVarRecordMembers;


template writeOutVar(Variable var, Integer index)
 "Generates code for writing a variable to outVar."

::=
  match var
  case VARIABLE(ty=T_COMPLEX(complexClassType=RECORD(__))) then
    <<
    write_modelica_record(outVar, <%writeOutVarRecordMembers(ty, index, "")%>);
    >>
  case VARIABLE(__) then

    <<
    write_<%varType(var)%>(outVar, &out.targ<%index%>);
    >>
end writeOutVar;


template writeOutVarRecordMembers(Type type, Integer index, String prefix)
 "Helper to writeOutVar."
::=
match type
case T_COMPLEX(varLst=vl, complexClassType = n) then
  let basename = underscorePath(ClassInf.getStateName(n))
  let args = (vl |> subvar as TYPES_VAR(__) =>
      match ty case T_COMPLEX(__) then
        let newPrefix = '<%prefix%>.<%subvar.name%>'
        '<%expTypeRW(ty)%>, <%writeOutVarRecordMembers(ty, index, newPrefix)%>'
      else
        '<%expTypeRW(ty)%>, &(out.targ<%index%><%prefix%>.<%subvar.name%>)'
    ;separator=", ")
  <<
  &<%basename%>__desc<%if args then ', <%args%>'%>, TYPE_DESC_NONE
  >>
end writeOutVarRecordMembers;

template varInit(Variable var, String outStruct, Integer i, Text &varDecls /*BUFP*/, Text &varInits /*BUFP*/)
 "Generates code to initialize variables.
  Does not return anything: just appends declarations to buffers."
::=
match var
case var as VARIABLE(__) then
  let varName = '<%contextCref(var.name,contextFunction)%>'
  let typ = '<%varType(var)%>'
  let initVar = match typ case "modelica_metatype" then ' = NULL' else ''
  let addRoot = match typ case "modelica_metatype" then ' mmc_GC_add_root(&<%varName%>, mmc_GC_local_state, "<%varName%>");' else ''
  let &varDecls += if not outStruct then '<%typ%> <%varName%><%initVar%>;<%addRoot%><%\n%>' //else ""
  let varName = if outStruct then '<%outStruct%>.targ<%i%>' else '<%contextCref(var.name,contextFunction)%>'
  let instDimsInit = (instDims |> exp =>
      daeExp(exp, contextFunction, &varInits /*BUFC*/, &varDecls /*BUFD*/)
    ;separator=", ")
  if instDims then
    (match var.value
    case SOME(exp) then
      let &varInits += 'alloc_<%expTypeShort(var.ty)%>_array(&<%varName%>, <%listLength(instDims)%>, <%instDimsInit%>);<%\n%>'
      let defaultValue = varDefaultValue(var, outStruct, i, varName, &varDecls, &varInits)
      let &varInits += defaultValue
      let var_name = if outStruct then
        '<%extVarName(var.name)%>' else
        '<%contextCref(var.name, contextFunction)%>'
      let defaultValue1 = '<%var_name%> = <%daeExp(exp, contextFunction, &varInits  /*BUFC*/, &varDecls /*BUFD*/)%>;<%\n%>'
      let &varInits += defaultValue1
      " "
    else
      let &varInits += 'alloc_<%expTypeShort(var.ty)%>_array(&<%varName%>, <%listLength(instDims)%>, <%instDimsInit%>);<%\n%>'
      let defaultValue = varDefaultValue(var, outStruct, i, varName, &varDecls, &varInits)
     let &varInits += defaultValue
      "")
  else
    (match var.value
    case SOME(exp) then
      let defaultValue = '<%contextCref(var.name,contextFunction)%> = <%daeExp(exp, contextFunction, &varInits  /*BUFC*/, &varDecls /*BUFD*/)%>;<%\n%>'
      let &varInits += defaultValue

      " "
    else
      "")
case var as FUNCTION_PTR(__) then
  let &ignore = buffer ""
  let &varDecls += functionArg(var,&ignore)
  ""
else error(sourceInfo(), 'Unknown local variable type')
end varInit;

template varDefaultValue(Variable var, String outStruct, Integer i, String lhsVarName,  Text &varDecls /*BUFP*/, Text &varInits /*BUFP*/)
::=
match var
case var as VARIABLE(__) then
  match value
  case SOME(CREF(componentRef = cr)) then
    'copy_<%expTypeShort(var.ty)%>_array_data(&<%contextCref(cr,contextFunction)%>, &<%outStruct%>.targ<%i%>);<%\n%>'
  case SOME(arr as ARRAY(__)) then
    let arrayExp = '<%daeExp(arr, contextFunction, &varInits /*BUFC*/, &varDecls /*BUFD*/)%>'
    <<
    copy_<%expTypeShort(var.ty)%>_array_data(&<%arrayExp%>, &<%lhsVarName%>);<%\n%>
    >>
end varDefaultValue;

template functionArg(Variable var, Text &varInit)
"Shared code for function arguments that are part of the function variables and valueblocks.
Valueblocks need to declare a reference to the function while input variables
need to initialize."
::=
match var
case var as FUNCTION_PTR(__) then
  let typelist = (args |> arg => mmcVarType(arg) ;separator=", ")
  let rettype = '<%name%>_rettype'
  match tys
    case {} then
      let &varInit += '_<%name%> = (void(*)(<%typelist%>)) <%name%><%\n%>;'
      'void(*_<%name%>)(<%typelist%>);<%\n%>'
    else
      let &varInit += '_<%name%> = (<%rettype%>(*)(<%typelist%>)) <%name%>;<%\n%>'
      <<
      <% tys |> arg hasindex i1 fromindex 1 => '#define <%rettype%>_<%i1%> targ<%i1%>' ; separator="\n" %>
      typedef struct <%rettype%>_s
      {
        <% tys |> ty hasindex i1 fromindex 1 => 'modelica_<%mmcTypeShort(ty)%> targ<%i1%>;' ; separator="\n" %>
      } <%rettype%>;
      <%rettype%>(*_<%name%>)(<%typelist%>);<%\n%>
      >>
  end match
end functionArg;

template varOutput(Variable var, String dest, Integer ix, Text &varDecls,
          Text &varInits, Text &varCopy, Text &varAssign)
 "Generates code to copy result value from a function to dest."
::=
match var
/* The storage size of arrays is known at call time, so they can be allocated
 * before set_memory_state. Strings are not known, so we copy them, etc...
 */
case var as VARIABLE(ty = T_STRING(__)) then
    if not acceptMetaModelicaGrammar() then
      // We need to strdup() all strings, then allocate them on the memory pool again, then free the temporary string
      let strVar = tempDecl("modelica_string_t", &varDecls)
      let &varCopy += '<%strVar%> = strdup(<%contextCref(var.name,contextFunction)%>);<%\n%>'
      let &varAssign +=
        <<
        <%dest%>.targ<%ix%> = init_modelica_string(<%strVar%>);
        free(<%strVar%>);<%\n%>
        >>
      ""
    else
      let &varAssign += '<%dest%>.targ<%ix%> = <%contextCref(var.name,contextFunction)%>;<%\n%>'
      ""
case var as VARIABLE(__) then
  let instDimsInit = (instDims |> exp =>
      daeExp(exp, contextFunction, &varInits /*BUFC*/, &varDecls /*BUFD*/)
    ;separator=", ")
  if instDims then
    let &varInits += 'alloc_<%expTypeShort(var.ty)%>_array(&<%dest%>.targ<%ix%>, <%listLength(instDims)%>, <%instDimsInit%>);<%\n%>'
    let &varAssign += 'copy_<%expTypeShort(var.ty)%>_array_data(&<%contextCref(var.name,contextFunction)%>, &<%dest%>.targ<%ix%>);<%\n%>'
    ""
  else
    let &varInits += initRecordMembers(var)
    let &varAssign += '<%dest%>.targ<%ix%> = <%contextCref(var.name,contextFunction)%>;<%\n%>'
    ""
case var as FUNCTION_PTR(__) then
    let &varAssign += '<%dest%>.targ<%ix%> = (modelica_fnptr) _<%var.name%>;<%\n%>'
    ""
end varOutput;

template initRecordMembers(Variable var)
::=
match var
case VARIABLE(ty = T_COMPLEX(complexClassType = RECORD(__))) then
  let varName = contextCref(name,contextFunction)
  (ty.varLst |> v => recordMemberInit(v, varName) ;separator="\n")
end initRecordMembers;

template recordMemberInit(Var v, Text varName)
::=
match v
case TYPES_VAR(ty = T_ARRAY(__)) then
  let arrayType = expType(ty, true)
  let dims = (ty.dims |> dim => dimension(dim) ;separator=", ")
  'alloc_<%arrayType%>(&<%varName%>.<%name%>, <%listLength(ty.dims)%>, <%dims%>);'
end recordMemberInit;

template extVarName(ComponentRef cr)
::= '<%contextCref(cr,contextFunction)%>_ext'
end extVarName;

template extFunCall(Function fun, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates the call to an external function."
::=
match fun
case EXTERNAL_FUNCTION(__) then
  match language
  case "C" then extFunCallC(fun, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case "FORTRAN 77" then extFunCallF77(fun, &preExp /*BUFC*/, &varDecls /*BUFD*/)
end extFunCall;

template extFunCallC(Function fun, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates the call to an external C function."
::=
match fun
case EXTERNAL_FUNCTION(__) then
  let fname = if dynamicLoad then 'ptr_<%extFunctionName(extName, language)%>' else '<%extName%>'
  let dynamicCheck = if dynamicLoad then
  <<
  if (<%fname%>==NULL) {
    MODELICA_TERMINATE("dynamic external function <%extFunctionName(extName, language)%> not set!")
  } else
  >>
    else ''
  let args = (extArgs |> arg =>
      extArg(arg, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    ;separator=", ")
  let returnAssign = match extReturn case SIMEXTARG(cref=c) then
      '<%extVarName(c)%> = '
    else
      ""
  <<
  <%extArgs |> arg => extFunCallVardecl(arg, &varDecls /*BUFD*/) ;separator="\n"%>
  <%match extReturn case SIMEXTARG(__) then extFunCallVardecl(extReturn, &varDecls /*BUFD*/)%>
  <%dynamicCheck%>
  <%returnAssign%><%fname%>(<%args%>);
  <%extArgs |> arg => extFunCallVarcopy(arg) ;separator="\n"%>
  <%match extReturn case SIMEXTARG(__) then extFunCallVarcopy(extReturn)%>
  >>
end extFunCallC;

template extFunCallF77(Function fun, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates the call to an external Fortran 77 function."
::=
match fun
case EXTERNAL_FUNCTION(__) then
  let args = (extArgs |> arg => extArgF77(arg, &preExp, &varDecls) ;separator=", ")
  let returnAssign = match extReturn case SIMEXTARG(cref=c) then
      '<%extVarName(c)%> = '
    else
      ""
  <<
  <%extArgs |> arg => extFunCallVardeclF77(arg, &varDecls) ;separator="\n"%>
  <%match extReturn case SIMEXTARG(__) then extFunCallVardeclF77(extReturn, &varDecls /*BUFD*/)%>
  <%biVars |> arg => extFunCallBiVarF77(arg, &preExp, &varDecls) ;separator="\n"%>
  <%returnAssign%><%extName%>_(<%args%>);
  <%extArgs |> arg => extFunCallVarcopyF77(arg) ;separator="\n"%>
  <%match extReturn case SIMEXTARG(__) then extFunCallVarcopyF77(extReturn)%>
  >>

end extFunCallF77;

template extFunCallVardecl(SimExtArg arg, Text &varDecls /*BUFP*/)
 "Helper to extFunCall."
::=
  match arg
  case SIMEXTARG(isInput=true, isArray=false, type_=ty, cref=c) then
    match ty case T_STRING(__) then
      ""
    else
      let &varDecls += '<%extType(ty,true,false)%> <%extVarName(c)%>;<%\n%>'
      <<
      <%extVarName(c)%> = (<%extType(ty,true,false)%>)<%contextCref(c,contextFunction)%>;
      >>
  case SIMEXTARG(outputIndex=oi, isArray=false, type_=ty, cref=c) then
    match oi case 0 then
      ""
    else
      let &varDecls += '<%extType(ty,true,false)%> <%extVarName(c)%>;<%\n%>'
      ""
end extFunCallVardecl;

template extFunCallVardeclF77(SimExtArg arg, Text &varDecls)
::=
  match arg
  case SIMEXTARG(isInput = true, isArray = true, type_ = ty, cref = c) then
    let &varDecls += '<%expTypeArrayIf(ty)%> <%extVarName(c)%>;<%\n%>'
    'convert_alloc_<%expTypeArray(ty)%>_to_f77(&<%contextCref(c,contextFunction)%>, &<%extVarName(c)%>);'
  case SIMEXTARG(outputIndex = oi, isArray = ia, type_= ty, cref = c) then
    match oi case 0 then "" else
      match ia
        case false then
          let default_val = typeDefaultValue(ty)
          let default_exp = match default_val case "" then "" else ' = <%default_val%>'
          let &varDecls += '<%extTypeF77(ty,false)%> <%extVarName(c)%><%default_exp%>;<%\n%>'
          ""
        else
          let &varDecls += '<%expTypeArrayIf(ty)%> <%extVarName(c)%>;<%\n%>'
          'convert_alloc_<%expTypeArray(ty)%>_to_f77(&out.targ<%oi%>, &<%extVarName(c)%>);'
  case SIMEXTARG(type_ = ty, cref = c) then
    let &varDecls += '<%extTypeF77(ty,false)%> <%extVarName(c)%>;<%\n%>'
    ""
end extFunCallVardeclF77;

template typeDefaultValue(DAE.Type ty)
::=
  match ty
  case ty as T_INTEGER(__) then '0'
  case ty as T_REAL(__) then '0.0'
  case ty as T_BOOL(__) then '0'
  case ty as T_STRING(__) then '0' /* Always segfault is better than only sometimes segfault :) */
  else ""
end typeDefaultValue;

template extFunCallBiVarF77(Variable var, Text &preExp, Text &varDecls)
::=
  match var
  case var as VARIABLE(__) then
    let var_name = contextCref(name,contextFunction)
    let &varDecls += '<%varType(var)%> <%var_name%>;<%\n%>'
    let &varDecls += '<%varType(var)%> <%extVarName(name)%>;<%\n%>'
    let defaultValue = match value
      case SOME(v) then
        '<%var_name%> = <%daeExp(v, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>;<%\n%>'
      else ""
    let &preExp += defaultValue
    let instDimsInit = (instDims |> exp =>
        daeExp(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/) ;separator=", ")
    if instDims then
      let type = expTypeArray(var.ty)
      let &preExp += 'alloc_<%type%>(&<%var_name%>, <%listLength(instDims)%>, <%instDimsInit%>);<%\n%>'
      let &preExp += 'convert_alloc_<%type%>_to_f77(&<%var_name%>, &<%extVarName(name)%>);<%\n%>'
      ""

    else
      ""
end extFunCallBiVarF77;

template extFunCallVarcopy(SimExtArg arg)
 "Helper to extFunCall."
::=
match arg
case SIMEXTARG(outputIndex=oi, isArray=false, type_=ty, cref=c) then
  match oi case 0 then
    ""
  else
    let cr = '<%extVarName(c)%>'
    <<
    out.targ<%oi%> = (<%expTypeModelica(ty)%>)<%
      if acceptMetaModelicaGrammar() then
        (match ty
          case T_STRING(__) then 'mmc_mk_scon(<%cr%>)'
          else cr)
      else cr %>;
    >>
end extFunCallVarcopy;

template extFunCallVarcopyF77(SimExtArg arg)
 "Generates code to copy results from output variables into the out struct.
  Helper to extFunCallF77."
::=
match arg
case SIMEXTARG(outputIndex=oi, isArray=ai, type_=ty, cref=c) then
  match oi case 0 then
    ""
  else
    let outarg = 'out.targ<%oi%>'
    let ext_name = '<%extVarName(c)%>'
    match ai
    case false then
      '<%outarg%> = (<%expTypeModelica(ty)%>)<%ext_name%>;<%\n%>'
    case true then
      'convert_alloc_<%expTypeArray(ty)%>_from_f77(&<%ext_name%>, &<%outarg%>);'
end extFunCallVarcopyF77;

template extArg(SimExtArg extArg, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Helper to extFunCall."
::=
  match extArg
  case SIMEXTARG(cref=c, outputIndex=oi, isArray=true, type_=t) then
    let name = if oi then 'out.targ<%oi%>' else contextCref(c,contextFunction)
    let shortTypeStr = expTypeShort(t)
    '(<%extType(t,isInput,true)%>) data_of_<%shortTypeStr%>_array(&(<%name%>))'
  case SIMEXTARG(cref=c, isInput=ii, outputIndex=0, type_=t) then
    let cr = '<%contextCref(c,contextFunction)%>'
    if acceptMetaModelicaGrammar() then
      (match t case T_STRING(__) then 'MMC_STRINGDATA(<%cr%>)' else '<%cr%>_ext')
    else
      '<%cr%><%match t case T_STRING(__) then "" else "_ext"%>'
  case SIMEXTARG(cref=c, isInput=ii, outputIndex=oi, type_=t) then
    '&<%extVarName(c)%>'
  case SIMEXTARGEXP(__) then
    daeExternalCExp(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case SIMEXTARGSIZE(cref=c) then
    let typeStr = expTypeShort(type_)
    let name = if outputIndex then 'out.targ<%outputIndex%>' else contextCref(c,contextFunction)
    let dim = daeExp(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    'size_of_dimension_<%typeStr%>_array(&<%name%>, <%dim%>)'
end extArg;

template extArgF77(SimExtArg extArg, Text &preExp, Text &varDecls)
::=
  match extArg
  case SIMEXTARG(cref=c, isArray=true, type_=t) then
    // Arrays are converted to fortran format that are stored in _ext-variables.
    'data_of_<%expTypeShort(t)%>_array(&(<%extVarName(c)%>))'
  case SIMEXTARG(cref=c, outputIndex=oi, type_=T_INTEGER(__)) then
    // Always prefix fortran arguments with &.
    let suffix = if oi then "_ext"
    '(int*) &<%contextCref(c,contextFunction)%><%suffix%>'
  case SIMEXTARG(cref=c, outputIndex=oi, type_=t) then
    // Always prefix fortran arguments with &.
    let suffix = if oi then "_ext"
    '&<%contextCref(c,contextFunction)%><%suffix%>'
  case SIMEXTARGEXP(__) then
    let texp = daeExp(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let tvar = tempDecl(expTypeFromExpFlag(exp,8),&varDecls)
    let &preExp += '<%tvar%> = <%texp%>;<%\n%>'
    '&<%tvar%>'
  case SIMEXTARGSIZE(cref=c) then
    // Fortran functions only takes references to variables, so we must store
    // the result from size_of_dimension_<type>_array in a temporary variable.
    let sizeVarName = tempSizeVarName(c, exp)
    let sizeVar = tempDecl("int", &varDecls)
    let dim = daeExp(exp, contextFunction, &preExp, &varDecls)
    let size_call = 'size_of_dimension_<%expTypeShort(type_)%>_array'
    let &preExp += '<%sizeVar%> = <%size_call%>(&<%contextCref(c,contextFunction)%>, <%dim%>);<%\n%>'
    '&<%sizeVar%>'
end extArgF77;

template tempSizeVarName(ComponentRef c, DAE.Exp indices)

::=
  match indices
  case ICONST(__) then '<%contextCref(c,contextFunction)%>_size_<%integer%>'
  else "tempSizeVarName:UNHANDLED_EXPRESSION"
end tempSizeVarName;

template funStatement(list<DAE.Statement> statementLst, Text &varDecls /*BUFP*/)
 "Generates function statements."
::=
  statementLst |> stmt => algStatement(stmt, contextFunction, &varDecls)
end funStatement;

template statementInfoString(DAE.Statement stmt)
::=
  match stmt
  case STMT_ASSIGN(__)
  case STMT_ASSIGN_ARR(__)
  case STMT_TUPLE_ASSIGN(__)
  case STMT_IF(__)
  case STMT_FOR(__)
  case STMT_WHILE(__)
  case STMT_ASSERT(__)
  case STMT_TERMINATE(__)
  case STMT_WHEN(__)
  case STMT_BREAK(__)
  case STMT_FAILURE(__)
  case STMT_RETURN(__)
  case STMT_NORETCALL(__)
  case STMT_REINIT(__)
  then (match source case s as SOURCE(__) then infoStr(s.info))
end statementInfoString;

template algStatement(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an algorithm statement."
::=
  let res = match stmt
  case s as STMT_ASSIGN(exp1=PATTERN(__)) then algStmtAssignPattern(s, context, &varDecls /*BUFD*/)
  case s as STMT_ASSIGN(__)         then algStmtAssign(s, context, &varDecls /*BUFD*/)
  case s as STMT_ASSIGN_ARR(__)     then algStmtAssignArr(s, context, &varDecls /*BUFD*/)
  case s as STMT_TUPLE_ASSIGN(__)   then algStmtTupleAssign(s, context, &varDecls /*BUFD*/)
  case s as STMT_IF(__)             then algStmtIf(s, context, &varDecls /*BUFD*/)
  case s as STMT_FOR(__)            then algStmtFor(s, context, &varDecls /*BUFD*/)
  case s as STMT_WHILE(__)          then algStmtWhile(s, context, &varDecls /*BUFD*/)
  case s as STMT_ASSERT(__)         then algStmtAssert(s, context, &varDecls /*BUFD*/)
  case s as STMT_TERMINATE(__)      then algStmtTerminate(s, context, &varDecls /*BUFD*/)
  case s as STMT_WHEN(__)           then algStmtWhen(s, context, &varDecls /*BUFD*/)
  case s as STMT_BREAK(__)          then 'break;<%\n%>'
  case s as STMT_FAILURE(__)        then algStmtFailure(s, context, &varDecls /*BUFD*/)
  case s as STMT_RETURN(__)         then 'goto _return;<%\n%>'
  case s as STMT_NORETCALL(__)      then algStmtNoretcall(s, context, &varDecls /*BUFD*/)
  case s as STMT_REINIT(__)         then algStmtReinit(s, context, &varDecls /*BUFD*/)
  else error(sourceInfo(), 'ALG_STATEMENT NYI')
  <<
  /*#modelicaLine <%statementInfoString(stmt)%>*/
  <%res%>
  /*#endModelicaLine*/
  >>
end algStatement;


template algStmtAssign(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an assigment algorithm statement."
::=
  match stmt
  case STMT_ASSIGN(exp1=CREF(componentRef=WILD(__)), exp=e) then
    let &preExp = buffer "" /*BUFD*/
    let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <%preExp%>
    >>
  case STMT_ASSIGN(exp1=CREF(ty = T_FUNCTION_REFERENCE_VAR(__)))
  case STMT_ASSIGN(exp1=CREF(ty = T_FUNCTION_REFERENCE_FUNC(__))) then
    let &preExp = buffer "" /*BUFD*/
    let varPart = scalarLhsCref(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <%preExp%>
    <%varPart%> = (modelica_fnptr) <%expPart%>;
    >>
  case STMT_ASSIGN(exp1=CREF(__)) then
    let &preExp = buffer "" /*BUFD*/
    let varPart = scalarLhsCref(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <%preExp%>
    <%varPart%> = <%expPart%>;
    >>
  case STMT_ASSIGN(exp1=exp1 as ASUB(__),exp=val) then
    (match expTypeFromExpShort(exp)
      case "metatype" then
        // MetaModelica Array
        (match exp case ASUB(exp=arr, sub={idx}) then
        let &preExp = buffer ""
        let arr1 = daeExp(arr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        let idx1 = daeExp(idx, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        let val1 = daeExp(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        <<
        <%preExp%>
        arrayUpdate(<%arr1%>,<%idx1%>,<%val1%>);
        >>)
        // Modelica Array
      else
        let &preExp = buffer "" /*BUFD*/
        let varPart = daeExpAsub(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        let expPart = daeExp(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        <<
        <%preExp%>
        <%varPart%> = <%expPart%>;
        >>
    )
  case STMT_ASSIGN(__) then
    let &preExp = buffer "" /*BUFD*/
    let expPart1 = daeExp(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expPart2 = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <%preExp%>
    <%expPart1%> = <%expPart2%>;
    >>
end algStmtAssign;


template algStmtAssignArr(DAE.Statement stmt, Context context,
                 Text &varDecls /*BUFP*/)
 "Generates an array assigment algorithm statement."
::=
match stmt
case STMT_ASSIGN_ARR(exp=e, lhs=CREF(componentRef=cr), type_=t) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let ispec = indexSpecFromCref(cr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  if ispec then
    <<
    <%preExp%>
    <%indexedAssign(t, expPart, cr, ispec, context, &varDecls)%>
    >>
  else
    <<
    <%preExp%>
    <%copyArrayData(t, expPart, cr, context)%>
    >>
end algStmtAssignArr;

template indexedAssign(DAE.Type ty, String exp, DAE.ComponentRef cr,
  String ispec, Context context, Text &varDecls)
::=
  let type = expTypeArray(ty)
  let cref = contextArrayCref(cr, context)
  match context
  case FUNCTION_CONTEXT(__) then
    'indexed_assign_<%type%>(&<%exp%>, &<%cref%>, &<%ispec%>);'
  else
    let tmp = tempDecl("real_array", &varDecls)
    <<
    indexed_assign_<%type%>(&<%exp%>, &<%tmp%>, &<%ispec%>);
    copy_<%type%>_data_mem(&<%tmp%>, &<%cref%>);
    >>
end indexedAssign;

template copyArrayData(DAE.Type ty, String exp, DAE.ComponentRef cr,

  Context context)
::=
  let type = expTypeArray(ty)
  let cref = contextArrayCref(cr, context)
  match context
  case FUNCTION_CONTEXT(__) then
    'copy_<%type%>_data(&<%exp%>, &<%cref%>);'
  else
    'copy_<%type%>_data_mem(&<%exp%>, &<%cref%>);'
end copyArrayData;

template algStmtTupleAssign(DAE.Statement stmt, Context context,
                   Text &varDecls /*BUFP*/)
 "Generates a tuple assigment algorithm statement."
::=
match stmt
case STMT_TUPLE_ASSIGN(exp=CALL(__)) then
  let &preExp = buffer "" /*BUFD*/
  let retStruct = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%preExp%>
  <%expExpLst |> cr hasindex i1 fromindex 1 =>
    let rhsStr = '<%retStruct%>.targ<%i1%>'
    writeLhsCref(cr, rhsStr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  ;separator="\n"%>
  >>
case STMT_TUPLE_ASSIGN(exp=MATCHEXPRESSION(__)) then
  let &preExp = buffer "" /*BUFD*/
  let prefix = 'tmp<%System.tmpTick()%>'
  let _ = daeExpMatch2(exp, expExpLst, prefix, context, &preExp, &varDecls)
  <<
  <%expExpLst |> cr hasindex i1 fromindex 1 =>
    let rhsStr = '<%prefix%>_targ<%i1%>'
    let typ = '<%expTypeFromExpModelica(cr)%>'
    let initVar = match typ case "modelica_metatype" then ' = NULL' else ''
    let addRoot = match typ case "modelica_metatype" then ' mmc_GC_add_root(&<%rhsStr%>, mmc_GC_local_state, "<%rhsStr%>");' else ''
    let &varDecls += '<%typ%> <%rhsStr%><%initVar%>;<%addRoot%><%\n%>'
    ""
  ;separator="\n";empty%>
  <%preExp%>
  <%expExpLst |> cr hasindex i1 fromindex 1 =>
    let rhsStr = '<%prefix%>_targ<%i1%>'
    writeLhsCref(cr, rhsStr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  ;separator="\n"%>
  >>
else error(sourceInfo(), 'algStmtTupleAssign failed')
end algStmtTupleAssign;

template writeLhsCref(Exp exp, String rhsStr, Context context, Text &preExp /*BUFP*/,
              Text &varDecls /*BUFP*/)
 "Generates code for writing a returnStructur to var."
::=
match exp
case ecr as CREF(componentRef=WILD(__)) then
  ''
case CREF(ty= t as DAE.T_ARRAY(__)) then
  let lhsStr = scalarLhsCref(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match context
  case SIMULATION_CONTEXT(__) then
    <<
    copy_<%expTypeShort(t)%>_array_data_mem(&<%rhsStr%>, &<%lhsStr%>);
    >>
  else
    '<%lhsStr%> = <%rhsStr%>;'
case UNARY(exp = e as CREF(ty= t as DAE.T_ARRAY(__))) then
  let lhsStr = scalarLhsCref(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match context
  case SIMULATION_CONTEXT(__) then
    <<
    usub_<%expTypeShort(t)%>_array(&<%rhsStr%>);<%\n%>
    copy_<%expTypeShort(t)%>_array_data_mem(&<%rhsStr%>, &<%lhsStr%>);
    >>
  else
    '<%lhsStr%> = -<%rhsStr%>;'
case CREF(__) then
  let lhsStr = scalarLhsCref(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%lhsStr%> = <%rhsStr%>;
  >>
case UNARY(exp = e as CREF(__)) then
  let lhsStr = scalarLhsCref(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%lhsStr%> = -<%rhsStr%>;
  >>
end writeLhsCref;

template algStmtIf(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an if algorithm statement."
::=
match stmt
case STMT_IF(__) then
  let &preExp = buffer "" /*BUFD*/
  let condExp = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%preExp%>
  if (<%condExp%>) {
    <%statementLst |> stmt => algStatement(stmt, context, &varDecls /*BUFD*/) ;separator="\n"%>
  }
  <%elseExpr(else_, context, &varDecls /*BUFD*/)%>
  >>
end algStmtIf;


template algStmtFor(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a for algorithm statement."
::=
  match stmt
  case s as STMT_FOR(range=rng as RANGE(__)) then
    algStmtForRange(s, context, &varDecls /*BUFD*/)
  case s as STMT_FOR(__) then
    algStmtForGeneric(s, context, &varDecls /*BUFD*/)
end algStmtFor;


template algStmtForRange(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a for algorithm statement where range is RANGE."
::=
match stmt
case STMT_FOR(range=rng as RANGE(__)) then
  let identType = expType(type_, iterIsArray)
  let identTypeShort = expTypeShort(type_)
  let stmtStr = (statementLst |> stmt => algStatement(stmt, context, &varDecls)
                 ;separator="\n")
  algStmtForRange_impl(rng, iter, identType, identTypeShort, stmtStr, context, &varDecls)
end algStmtForRange;

template algStmtForRange_impl(Exp range, Ident iterator, String type, String shortType, Text body, Context context, Text &varDecls)
 "The implementation of algStmtForRange, which is also used by daeExpReduction."
::=
match range
case RANGE(__) then
  let iterName = contextIteratorName(iterator, context)
  let stateVar = if not acceptMetaModelicaGrammar() then tempDecl("state", &varDecls)
  let startVar = tempDecl(type, &varDecls)
  let stepVar = tempDecl(type, &varDecls)
  let stopVar = tempDecl(type, &varDecls)
  let &preExp = buffer ""
  let startValue = daeExp(start, context, &preExp, &varDecls)
  let stepValue = match step case SOME(eo) then
      daeExp(eo, context, &preExp, &varDecls)
    else
      "(1)"
  let stopValue = daeExp(stop, context, &preExp, &varDecls)
  <<
  <%preExp%>
  <%startVar%> = <%startValue%>; <%stepVar%> = <%stepValue%>; <%stopVar%> = <%stopValue%>;
  if (!<%stepVar%>) {
    MODELICA_ASSERT(__FILE__,__LINE__,"assertion range step != 0 failed");
  } else if (!(((<%stepVar%> > 0) && (<%startVar%> > <%stopVar%>)) || ((<%stepVar%> < 0) && (<%startVar%> < <%stopVar%>)))) {
    <%type%> <%iterName%>;
    for (<%iterName%> = <%startValue%>; in_range_<%shortType%>(<%iterName%>, <%startVar%>, <%stopVar%>); <%iterName%> += <%stepVar%>) {
      <%if not acceptMetaModelicaGrammar() then '<%stateVar%> = get_memory_state();'%>
      <%body%>
      <%if not acceptMetaModelicaGrammar() then 'restore_memory_state(<%stateVar%>);'%>
    }
  }
  >> /* else we're looping over a zero-length range */
end algStmtForRange_impl;

template algStmtForGeneric(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a for algorithm statement where range is not RANGE."
::=
match stmt
case STMT_FOR(__) then
  let iterType = expType(type_, iterIsArray)
  let arrayType = expTypeArray(type_)


  let stmtStr = (statementLst |> stmt =>
    algStatement(stmt, context, &varDecls) ;separator="\n")
  algStmtForGeneric_impl(range, iter, iterType, arrayType, iterIsArray, stmtStr,
    context, &varDecls)
end algStmtForGeneric;

template algStmtForGeneric_impl(Exp exp, Ident iterator, String type,
  String arrayType, Boolean iterIsArray, Text &body, Context context, Text &varDecls)
 "The implementation of algStmtForGeneric, which is also used by daeExpReduction."
::=
  let iterName = contextIteratorName(iterator, context)
  let stateVar = if not acceptMetaModelicaGrammar() then tempDecl("state", &varDecls)
  let tvar = tempDecl("int", &varDecls)
  let ivar = tempDecl(type, &varDecls)
  let &preExp = buffer ""
  let evar = daeExp(exp, context, &preExp, &varDecls)
  let stmtStuff = if iterIsArray then
      'simple_index_alloc_<%type%>1(&<%evar%>, <%tvar%>, &<%ivar%>);'
    else
      '<%iterName%> = *(<%arrayType%>_element_addr1(&<%evar%>, 1, <%tvar%>));'
  <<
  <%preExp%>
  {
    <%type%> <%iterName%>;

    for(<%tvar%> = 1; <%tvar%> <= size_of_dimension_<%arrayType%>(&<%evar%>, 1); ++<%tvar%>) {
      <%if not acceptMetaModelicaGrammar() then '<%stateVar%> = get_memory_state();'%>
      <%stmtStuff%>
      <%body%>
      <%if not acceptMetaModelicaGrammar() then 'restore_memory_state(<%stateVar%>);'%>
    }
  }
  >>
end algStmtForGeneric_impl;

template algStmtWhile(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a while algorithm statement."
::=
match stmt
case STMT_WHILE(__) then
  let &preExp = buffer "" /*BUFD*/
  let var = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  while (1) {
    <%preExp%>
    if (!<%var%>) break;
    <%statementLst |> stmt => algStatement(stmt, context, &varDecls /*BUFD*/) ;separator="\n"%>

  }
  >>
end algStmtWhile;


template algStmtAssert(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an assert algorithm statement."
::=
match stmt
case STMT_ASSERT(source=SOURCE(info=info)) then
  assertCommon(cond, msg, context, &varDecls, info)
end algStmtAssert;

template algStmtTerminate(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an assert algorithm statement."
::=
match stmt
case STMT_TERMINATE(__) then
  let &preExp = buffer "" /*BUFD*/
  let msgVar = daeExp(msg, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%preExp%>
  MODELICA_TERMINATE(<%msgVar%>);
  >>
end algStmtTerminate;

template algStmtMatchcasesVarDeclsAndAssign(list<Exp> expList, Context context, Text &varDecls, Text &varAssign, Text &preExp)
::=
  (expList |> exp =>
    let decl = tempDecl(expTypeFromExpModelica(exp), &varDecls)
    // let content = daeExp(exp, context, &preExp, &varDecls)
    let lhs = scalarLhsCref(exp, context, &preExp, &varDecls)
    let &varAssign += '<%decl%> = <%lhs%>;' + "\n"
      '<%lhs%> = <%decl%>;'
    ; separator = "\n")
end algStmtMatchcasesVarDeclsAndAssign;

template algStmtFailure(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a failure() algorithm statement."
::=
match stmt
case STMT_FAILURE(__) then
  let tmp = tempDecl("modelica_boolean", &varDecls /*BUFD*/)
  let stmtBody = (body |> stmt =>
      algStatement(stmt, context, &varDecls /*BUFD*/)
    ;separator="\n")
  <<
  <%tmp%> = 0; /* begin failure */
  MMC_TRY()
    <%stmtBody%>
    <%tmp%> = 1;
  MMC_CATCH()
  if (<%tmp%>) MMC_THROW(); /* end failure */
  >>
end algStmtFailure;


template algStmtNoretcall(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a no return call algorithm statement."
::=
match stmt
case STMT_NORETCALL(__) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%preExp%>
  <%expPart%>;
  >>
end algStmtNoretcall;


template algStmtWhen(DAE.Statement when, Context context, Text &varDecls /*BUFP*/)
 "Generates a when algorithm statement."
::=
match context
case SIMULATION_CONTEXT(genDiscrete=true) then
  match when
  case STMT_WHEN(__) then
    let helpIf = (conditions |> e => '(<%cref(e)%> && !_PRE<%cref(e)%> /* edge */)';separator=" || ")
    let statements = (statementLst |> stmt =>
        algStatement(stmt, context, &varDecls /*BUFD*/)
      ;separator="\n")
    let else = algStatementWhenElse(elseWhen, &varDecls /*BUFD*/)
    <<
    if(<%helpIf%>)
    {
      <%statements%>
    }
    <%else%>
    >>
  end match
end algStmtWhen;


template algStatementWhenElse(Option<DAE.Statement> stmt, Text &varDecls /*BUFP*/)
 "Helper to algStmtWhen."
::=
match stmt
case SOME(when as STMT_WHEN(__)) then
  let statements = (when.statementLst |> stmt =>
      algStatement(stmt, contextSimulationDiscrete, &varDecls /*BUFD*/)
    ;separator="\n")
  let else = algStatementWhenElse(when.elseWhen, &varDecls /*BUFD*/)
  let elseCondStr = (when.conditions |> e => '(<%cref(e)%> && !_PRE<%cref(e)%> /* edge */)';separator=" || ")
  <<
  else if(<%elseCondStr%>)
  {
    <%statements%>
  }
  <%else%>
  >>
end algStatementWhenElse;


template algStmtReinit(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an assigment algorithm statement."
::=
  match stmt
  case STMT_REINIT(__) then
    let &preExp = buffer "" /*BUFD*/
    let expPart1 = daeExp(var, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expPart2 = daeExp(value, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    _PRE<%expPart1%> = <%expPart1%>;
    <%preExp%>
    <%expPart1%> = <%expPart2%>;
    >>
end algStmtReinit;

template indexSpecFromCref(ComponentRef cr, Context context, Text &preExp /*BUFP*/,
                  Text &varDecls /*BUFP*/)
 "Helper to algStmtAssignArr.
  Currently works only for CREF_IDENT."
::=
match cr
case CREF_IDENT(subscriptLst=subs as (_ :: _)) then
  daeExpCrefRhsIndexSpec(subs, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
end indexSpecFromCref;


template elseExpr(DAE.Else else_, Context context, Text &varDecls /*BUFP*/)
 "Helper to algStmtIf."
 ::=
  match else_
  case NOELSE(__) then
    ""
  case ELSEIF(__) then
    let &preExp = buffer "" /*BUFD*/
    let condExp = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    else {
      <%preExp%>
      if (<%condExp%>) {
        <%statementLst |> stmt =>
          algStatement(stmt, context, &varDecls /*BUFD*/)
        ;separator="\n"%>
      }
      <%elseExpr(else_, context, &varDecls /*BUFD*/)%>
    }
    >>
  case ELSE(__) then

    <<
    else {
      <%statementLst |> stmt =>
        algStatement(stmt, context, &varDecls /*BUFD*/)
      ;separator="\n"%>
    }
    >>
end elseExpr;

template scalarLhsCref(Exp ecr, Context context, Text &preExp, Text &varDecls)
 "Generates the left hand side (for use on left hand side) of a component
  reference."
::=
  match ecr
  case CREF(componentRef = cr, ty = T_FUNCTION_REFERENCE_VAR(__)) then
    '*((modelica_fnptr*)&_<%crefStr(cr)%>)'
  case ecr as CREF(componentRef=CREF_IDENT(__)) then
    if crefNoSub(ecr.componentRef) then
      contextCref(ecr.componentRef, context)
    else
      daeExpCrefRhs(ecr, context, &preExp, &varDecls)
  case ecr as CREF(componentRef=CREF_QUAL(__)) then
    contextCref(ecr.componentRef, context)
  case ecr as CREF(componentRef=WILD(__)) then
    ''
  else
    "ONLY_IDENT_OR_QUAL_CREF_SUPPORTED_SLHS"
end scalarLhsCref;

template rhsCref(ComponentRef cr, Type ty)
 "Like cref but with cast if type is integer."
::=
  match cr
  case CREF_IDENT(__) then '<%rhsCrefType(ty)%><%ident%>'
  case CREF_QUAL(__)  then '<%rhsCrefType(ty)%><%ident%>.<%rhsCref(componentRef,ty)%>'
  else "rhsCref:ERROR"
end rhsCref;


template rhsCrefType(Type type)
 "Helper to rhsCref."
::=
  match type
  case T_INTEGER(__) then "(modelica_integer)"
  case T_ENUMERATION(__) then "(modelica_integer)"
  //else ""
end rhsCrefType;


template daeExp(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for an expression."
::=
  match exp
  case e as ICONST(__)          then '(modelica_integer) <%integer%>' /* Yes, we need to cast int to long on 64-bit arch... */
  case e as RCONST(__)          then real
  case e as SCONST(__)          then daeExpSconst(string, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as BCONST(__)          then if bool then "(1)" else "(0)"
  case e as ENUM_LITERAL(__)    then index
  case e as CREF(__)            then daeExpCrefRhs(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as BINARY(__)          then daeExpBinary(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as UNARY(__)           then daeExpUnary(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as LBINARY(__)         then daeExpLbinary(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as LUNARY(__)          then daeExpLunary(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as RELATION(__)        then daeExpRelation(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as IFEXP(__)           then daeExpIf(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as CALL(__)            then daeExpCall(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as ARRAY(__)           then daeExpArray(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as MATRIX(__)          then daeExpMatrix(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as RANGE(__)           then daeExpRange(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as CAST(__)            then daeExpCast(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as ASUB(__)            then daeExpAsub(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as SIZE(__)            then daeExpSize(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as REDUCTION(__)       then daeExpReduction(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as LIST(__)            then daeExpList(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as CONS(__)            then daeExpCons(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as META_TUPLE(__)      then daeExpMetaTuple(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as META_OPTION(__)     then daeExpMetaOption(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as METARECORDCALL(__)  then daeExpMetarecordcall(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as MATCHEXPRESSION(__) then daeExpMatch(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as BOX(__)             then daeExpBox(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as UNBOX(__)           then daeExpUnbox(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as SHARED_LITERAL(__)  then daeExpSharedLiteral(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  else error(sourceInfo(), 'Unknown expression: <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
end daeExp;


template daeExternalCExp(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
  "Like daeExp, but also converts the type to external C"
::=
  match typeof(exp)
    case T_ARRAY(__) then  // Array-expressions
      let shortTypeStr = expTypeShort(typeof(exp))
      '(<%extType(typeof(exp),true,true)%>) data_of_<%shortTypeStr%>_array(&<%daeExp(exp, context, &preExp, &varDecls)%>)'
    else daeExp(exp, context, &preExp, &varDecls)
end daeExternalCExp;

template daeExpSconst(String string, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for a string constant."
::=
  '"<%Util.escapeModelicaStringToCString(string)%>"'
end daeExpSconst;

template daeExpCrefRhs(Exp exp, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/)
 "Generates code for a component reference on the right hand side of an
 expression."
::=
  match exp
  // A record cref without subscripts (i.e. a record instance) is handled
  // by daeExpRecordCrefRhs only in a simulation context, not in a function.
  case CREF(componentRef = cr, ty = t as T_COMPLEX(complexClassType = RECORD(path = _))) then
    match context case FUNCTION_CONTEXT(__) then
      daeExpCrefRhs2(exp, context, &preExp, &varDecls)
    else
      daeExpRecordCrefRhs(t, cr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case CREF(componentRef = cr, ty = T_FUNCTION_REFERENCE_FUNC(__)) then
    '((modelica_fnptr)boxptr_<%crefFunctionName(cr)%>)'
  case CREF(componentRef = cr, ty = T_FUNCTION_REFERENCE_VAR(__)) then
    '((modelica_fnptr) _<%crefStr(cr)%>)'
  else daeExpCrefRhs2(exp, context, &preExp, &varDecls)
end daeExpCrefRhs;

template daeExpCrefRhs2(Exp ecr, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/)
 "Generates code for a component reference."
::=
  match ecr
  case ecr as CREF(componentRef=cr, ty=ty) then
    let box = daeExpCrefRhsArrayBox(ecr, context, &preExp, &varDecls)
    if box then
      box
    else if crefIsScalar(cr, context) then
      let cast = match ty case T_INTEGER(__) then "(modelica_integer)"
                          case T_ENUMERATION(__) then "(modelica_integer)" //else ""
      '<%cast%><%contextCref(cr,context)%>'
    else
     if crefSubIsScalar(cr) then
      // The array subscript results in a scalar
      let arrName = contextCref(crefStripLastSubs(cr), context)
      let arrayType = expTypeArray(ty)
      let dimsLenStr = listLength(crefSubs(cr))
      let dimsValuesStr = (crefSubs(cr) |> INDEX(__) =>
          daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        ;separator=", ")
      match arrayType
        case "metatype_array" then
          'arrayGet(<%arrName%>,<%dimsValuesStr%>) /* DAE.CREF */'

        else
          <<
          (*<%arrayType%>_element_addr(&<%arrName%>, <%dimsLenStr%>, <%dimsValuesStr%>))
          >>
    else
      // The array subscript denotes a slice

      let arrName = contextArrayCref(cr, context)
      let arrayType = expTypeArray(ty)
      let tmp = tempDecl(arrayType, &varDecls /*BUFD*/)
      let spec1 = daeExpCrefRhsIndexSpec(crefSubs(cr), context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      let &preExp += 'index_alloc_<%arrayType%>(&<%arrName%>, &<%spec1%>, &<%tmp%>);<%\n%>'
      tmp
end daeExpCrefRhs2;

template daeExpCrefRhsIndexSpec(list<Subscript> subs, Context context,
                                Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Helper to daeExpCrefRhs."
::=
  let nridx_str = listLength(subs)
  let idx_str = (subs |> sub =>
      match sub
      case INDEX(__) then
        let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        <<
        (0), make_index_array(1, (int) <%expPart%>), 'S'

        >>
      case WHOLEDIM(__) then
        <<
        (1), (int*)0, 'W'
        >>
      case SLICE(__) then
        let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        let tmp = tempDecl("modelica_integer", &varDecls /*BUFD*/)
        let &preExp += '<%tmp%> = size_of_dimension_integer_array(&<%expPart%>, 1);<%\n%>'
        <<
        (int) <%tmp%>, integer_array_make_index_array(&<%expPart%>), 'A'
        >>
    ;separator=", ")
  let tmp = tempDecl("index_spec_t", &varDecls /*BUFD*/)
  let &preExp += 'create_index_spec(&<%tmp%>, <%nridx_str%>, <%idx_str%>);<%\n%>'
  tmp
end daeExpCrefRhsIndexSpec;


template daeExpCrefRhsArrayBox(Exp ecr, Context context, Text &preExp /*BUFP*/,
                               Text &varDecls /*BUFP*/)
 "Helper to daeExpCrefRhs."
::=
match ecr
case ecr as CREF(ty=T_ARRAY(ty=aty,dims=dims)) then
  match context
  case FUNCTION_CONTEXT(__) then ''
  else
    // For context simulation and other array variables must be boxed into a real_array
    // object since they are represented only in a double array.
    let tmpArr = tempDecl(expTypeArray(aty), &varDecls /*BUFD*/)
    let dimsLenStr = listLength(dims)
    let dimsValuesStr = (dims |> dim => dimension(dim) ;separator=", ")
    let type = expTypeShort(aty)
    let &preExp += '<%type%>_array_create(&<%tmpArr%>, ((modelica_<%type%>*)&(<%arrayCrefCStr(ecr.componentRef)%>)), <%dimsLenStr%>, <%dimsValuesStr%>);<%\n%>'
    tmpArr
end daeExpCrefRhsArrayBox;


template daeExpRecordCrefRhs(DAE.Type ty, ComponentRef cr, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/)
::=
match ty
case T_COMPLEX(complexClassType = record_state, varLst = var_lst) then
  let vars = var_lst |> v => daeExp(makeCrefRecordExp(cr,v), context, &preExp, &varDecls)
             ;separator=", "
  let record_type_name = underscorePath(ClassInf.getStateName(record_state))
  let ret_type = '<%record_type_name%>_rettype'
  let ret_var = tempDecl(ret_type, &varDecls)
  let &preExp += '<%ret_var%> = _<%record_type_name%>(<%vars%>);<%\n%>'
  '<%ret_var%>.<%ret_type%>_1'
end daeExpRecordCrefRhs;

template daeExpBinary(Exp exp, Context context, Text &preExp /*BUFP*/,
                      Text &varDecls /*BUFP*/)
 "Generates code for a binary expression."
::=

match exp
case BINARY(__) then
  let e1 = daeExp(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let e2 = daeExp(exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match operator
  case ADD(ty = T_STRING(__)) then
    let tmpStr = if acceptMetaModelicaGrammar()
                 then tempDecl("modelica_metatype", &varDecls /*BUFD*/)
                 else tempDecl("modelica_string", &varDecls /*BUFD*/)
    let &preExp += if acceptMetaModelicaGrammar() then
        '<%tmpStr%> = stringAppend(<%e1%>,<%e2%>);<%\n%>'
      else
        '<%tmpStr%> = cat_modelica_string(<%e1%>,<%e2%>);<%\n%>'
    tmpStr
  case ADD(__) then '(<%e1%> + <%e2%>)'
  case SUB(__) then '(<%e1%> - <%e2%>)'
  case MUL(__) then '(<%e1%> * <%e2%>)'
  case DIV(__) then '(<%e1%> / <%e2%>)'
  case POW(__) then
    if isHalf(exp2) then 'sqrt(<%e1%>)'
    else match realExpIntLit(exp2)
      case SOME(2) then
        let tmp = tempDecl("modelica_real", &varDecls)
        let &preExp += '<%tmp%> = <%e1%>;'
        '(<%tmp%> * <%tmp%>)'
      case SOME(3) then
        let tmp = tempDecl("modelica_real", &varDecls)
        let &preExp += '<%tmp%> = <%e1%>;'
        '(<%tmp%> * <%tmp%> * <%tmp%>)'
      case SOME(4) then
        let tmp = tempDecl("modelica_real", &varDecls)
        let &preExp += '<%tmp%> = <%e1%>;'
        let &preExp += '<%tmp%> *= <%tmp%>;'
        '(<%tmp%> * <%tmp%>)'
      case SOME(i) then 'real_int_pow(<%e1%>, <%i%>)'
      else 'pow(<%e1%>, <%e2%>)'
  case UMINUS(__) then daeExpUnary(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case ADD_ARR(__) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "integer_array"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDecl(type, &varDecls /*BUFD*/)
    let &preExp += 'add_alloc_<%type%>(&<%e1%>, &<%e2%>, &<%var%>);<%\n%>'
    '<%var%>'
  case SUB_ARR(__) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "integer_array"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDecl(type, &varDecls /*BUFD*/)
    let &preExp += 'sub_alloc_<%type%>(&<%e1%>, &<%e2%>, &<%var%>);<%\n%>'
    '<%var%>'
  case MUL_ARR(__) then  'daeExpBinary:ERR for MUL_ARR'
  case DIV_ARR(__) then  'daeExpBinary:ERR for DIV_ARR'
  case MUL_ARRAY_SCALAR(__) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "integer_array"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDecl(type, &varDecls /*BUFD*/)
    let &preExp += 'mul_alloc_<%type%>_scalar(&<%e1%>, <%e2%>, &<%var%>);<%\n%>'
    '<%var%>'
  case ADD_ARRAY_SCALAR(__) then 'daeExpBinary:ERR for ADD_ARRAY_SCALAR'
  case SUB_SCALAR_ARRAY(__) then 'daeExpBinary:ERR for SUB_SCALAR_ARRAY'
  case MUL_SCALAR_PRODUCT(__) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "integer_scalar"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "integer_scalar"
                        else "real_scalar"
    'mul_<%type%>_product(&<%e1%>, &<%e2%>)'
  case MUL_MATRIX_PRODUCT(__) then
    let typeShort = match ty case T_ARRAY(ty=T_INTEGER(__)) then "integer"
                             case T_ARRAY(ty=T_ENUMERATION(__)) then "integer"
                             else "real"
    let type = '<%typeShort%>_array'
    let var = tempDecl(type, &varDecls /*BUFD*/)
    let &preExp += 'mul_alloc_<%typeShort%>_matrix_product_smart(&<%e1%>, &<%e2%>, &<%var%>);<%\n%>'
    '<%var%>'
  case DIV_ARRAY_SCALAR(__) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "integer_array"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDecl(type, &varDecls /*BUFD*/)
    let &preExp += 'div_alloc_<%type%>_scalar(&<%e1%>, <%e2%>, &<%var%>);<%\n%>'
    '<%var%>'
  case DIV_SCALAR_ARRAY(__) then 'daeExpBinary:ERR for DIV_SCALAR_ARRAY'
  case POW_ARRAY_SCALAR(__) then 'daeExpBinary:ERR for POW_ARRAY_SCALAR'
  case POW_SCALAR_ARRAY(__) then 'daeExpBinary:ERR for POW_SCALAR_ARRAY'
  case POW_ARR(__) then 'daeExpBinary:ERR for POW_ARR'
  case POW_ARR2(__) then 'daeExpBinary:ERR for POW_ARR2'
  else "daeExpBinary:ERR"
end daeExpBinary;


template daeExpUnary(Exp exp, Context context, Text &preExp /*BUFP*/,
                     Text &varDecls /*BUFP*/)
 "Generates code for a unary expression."
::=
match exp
case UNARY(__) then
  let e = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match operator
  case UMINUS(__)     then '(-<%e%>)'
  case UMINUS_ARR(ty=T_ARRAY(ty=T_REAL(__))) then
    let &preExp += 'usub_real_array(&<%e%>);<%\n%>'
    '<%e%>'
  case UMINUS_ARR(__) then 'unary minus for non-real arrays not implemented'
  else "daeExpUnary:ERR"
end daeExpUnary;


template daeExpLbinary(Exp exp, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/)
 "Generates code for a logical binary expression."
::=
match exp
case LBINARY(__) then
  let e1 = daeExp(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let e2 = daeExp(exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match operator
  case AND(__) then '(<%e1%> && <%e2%>)'
  case OR(__)  then '(<%e1%> || <%e2%>)'
  else "daeExpLbinary:ERR"
end daeExpLbinary;


template daeExpLunary(Exp exp, Context context, Text &preExp /*BUFP*/,
                      Text &varDecls /*BUFP*/)
 "Generates code for a logical unary expression."
::=
match exp
case LUNARY(__) then
  let e = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match operator
  case NOT(__) then '(!<%e%>)'
end daeExpLunary;


template daeExpRelation(Exp exp, Context context, Text &preExp /*BUFP*/,
                        Text &varDecls /*BUFP*/)
 "Generates code for a relation expression."
::=
match exp
case rel as RELATION(__) then
  let simRel = daeExpRelationSim(rel, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  if simRel then
    simRel
  else
    let e1 = daeExp(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let e2 = daeExp(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    match rel.operator

    case LESS(ty = T_BOOL(__))             then '(!<%e1%> && <%e2%>)'
    case LESS(ty = T_STRING(__))           then '(stringCompare(<%e1%>, <%e2%>) < 0)'
    case LESS(ty = T_INTEGER(__))              then '(<%e1%> < <%e2%>)'
    case LESS(ty = T_REAL(__))             then '(<%e1%> < <%e2%>)'
    case LESS(ty = T_ENUMERATION(__))      then '(<%e1%> < <%e2%>)'

    case GREATER(ty = T_BOOL(__))          then '(<%e1%> && !<%e2%>)'
    case GREATER(ty = T_STRING(__))        then '(stringCompare(<%e1%>, <%e2%>) > 0)'
    case GREATER(ty = T_INTEGER(__))           then '(<%e1%> > <%e2%>)'
    case GREATER(ty = T_REAL(__))          then '(<%e1%> > <%e2%>)'
    case GREATER(ty = T_ENUMERATION(__))   then '(<%e1%> > <%e2%>)'

    case LESSEQ(ty = T_BOOL(__))           then '(!<%e1%> || <%e2%>)'
    case LESSEQ(ty = T_STRING(__))         then '(stringCompare(<%e1%>, <%e2%>) <= 0)'
    case LESSEQ(ty = T_INTEGER(__))            then '(<%e1%> <= <%e2%>)'
    case LESSEQ(ty = T_REAL(__))           then '(<%e1%> <= <%e2%>)'
    case LESSEQ(ty = T_ENUMERATION(__))    then '(<%e1%> <= <%e2%>)'

    case GREATEREQ(ty = T_BOOL(__))        then '(<%e1%> || !<%e2%>)'
    case GREATEREQ(ty = T_STRING(__))      then '(stringCompare(<%e1%>, <%e2%>) >= 0)'
    case GREATEREQ(ty = T_INTEGER(__))         then '(<%e1%> >= <%e2%>)'
    case GREATEREQ(ty = T_REAL(__))        then '(<%e1%> >= <%e2%>)'
    case GREATEREQ(ty = T_ENUMERATION(__)) then '(<%e1%> >= <%e2%>)'

    case EQUAL(ty = T_BOOL(__))            then '((!<%e1%> && !<%e2%>) || (<%e1%> && <%e2%>))'
    case EQUAL(ty = T_STRING(__))          then '(stringEqual(<%e1%>, <%e2%>))'
    case EQUAL(ty = T_INTEGER(__))             then '(<%e1%> == <%e2%>)'
    case EQUAL(ty = T_REAL(__))            then '(<%e1%> == <%e2%>)'
    case EQUAL(ty = T_ENUMERATION(__))     then '(<%e1%> == <%e2%>)'

    case NEQUAL(ty = T_BOOL(__))           then '((!<%e1%> && <%e2%>) || (<%e1%> && !<%e2%>))'
    case NEQUAL(ty = T_STRING(__))         then '(!stringEqual(<%e1%>, <%e2%>))'
    case NEQUAL(ty = T_INTEGER(__))            then '(<%e1%> != <%e2%>)'
    case NEQUAL(ty = T_REAL(__))           then '(<%e1%> != <%e2%>)'
    case NEQUAL(ty = T_ENUMERATION(__))    then '(<%e1%> != <%e2%>)'

    else "daeExpRelation:ERR"
end daeExpRelation;


template daeExpRelationSim(Exp exp, Context context, Text &preExp /*BUFP*/,
                           Text &varDecls /*BUFP*/)
 "Helper to daeExpRelation."
::=
match exp
case rel as RELATION(__) then
  match context
  case SIMULATION_CONTEXT(genDiscrete=false) then
     match rel.optionExpisASUB
     case NONE() then
        let e1 = daeExp(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let e2 = daeExp(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let res = tempDecl("modelica_boolean", &varDecls /*BUFC*/)
        match rel.operator
        case LESS(__) then
          let &preExp += 'ADEVS_RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,<);<%\n%>'
          res
        case LESSEQ(__) then
          let &preExp += 'ADEVS_RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,<=);<%\n%>'
          res
        case GREATER(__) then
          let &preExp += 'ADEVS_RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,>);<%\n%>'
          res
        case GREATEREQ(__) then
          let &preExp += 'ADEVS_RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,>=);<%\n%>'
          res
        end match
    case SOME((exp,i,j)) then
        let e1 = daeExp(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let e2 = daeExp(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let iterator = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let res = tempDecl("modelica_boolean", &varDecls /*BUFC*/)
        //let e3 = daeExp(createArray(i), context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        match rel.operator
        case LESS(__) then
          let &preExp += 'ADEVS_RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,<);<%\n%>'
          res
        case LESSEQ(__) then
          let &preExp += 'ADEVS_RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,<=);<%\n%>'
          res
        case GREATER(__) then
          let &preExp += 'ADEVS_RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,>);<%\n%>'
          res
        case GREATEREQ(__) then
          let &preExp += 'ADEVS_RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,>=);<%\n%>'
          res
        end match
      end match
   case SIMULATION_CONTEXT(genDiscrete=true) then
     match rel.optionExpisASUB
     case NONE() then
        let e1 = daeExp(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let e2 = daeExp(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let res = tempDecl("modelica_boolean", &varDecls /*BUFC*/)
        match rel.operator
        case LESS(__) then
          let &preExp += 'ADEVS_SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,<);<%\n%>'
          res
        case LESSEQ(__) then
          let &preExp += 'ADEVS_SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,<=);<%\n%>'
          res
        case GREATER(__) then
          let &preExp += 'ADEVS_SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,>);<%\n%>'
          res
        case GREATEREQ(__) then
          let &preExp += 'ADEVS_SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,>=);<%\n%>'
          res
        end match
    case SOME((exp,i,j)) then
         let e1 = daeExp(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
         let e2 = daeExp(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
         let res = tempDecl("modelica_boolean", &varDecls /*BUFC*/)
         //let e3 = daeExp(createArray(i), context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
         let iterator = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
         match rel.operator
         case LESS(__) then
            let &preExp += 'ADEVS_SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>, <%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,<);<%\n%>'
            res
         case LESSEQ(__) then
            let &preExp += 'ADEVS_SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>, <%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,<=);<%\n%>'
            res
         case GREATER(__) then
            let &preExp += 'ADEVS_SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>, <%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,>);<%\n%>'
            res
         case GREATEREQ(__) then
            let &preExp += 'ADEVS_SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>,<%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,>=);<%\n%>'
            res
            end match
          end match
    end match
end match
end daeExpRelationSim;

template daeExpIf(Exp exp, Context context, Text &preExp /*BUFP*/,
                  Text &varDecls /*BUFP*/)
 "Generates code for an if expression."
::=
match exp
case IFEXP(__) then
  let condExp = daeExp(expCond, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let &preExpThen = buffer "" /*BUFD*/
  let eThen = daeExp(expThen, context, &preExpThen /*BUFC*/, &varDecls /*BUFD*/)
  let &preExpElse = buffer "" /*BUFD*/
  let eElse = daeExp(expElse, context, &preExpElse /*BUFC*/, &varDecls /*BUFD*/)
  let shortIfExp = if preExpThen then "" else if preExpElse then "" else "x"
  (if shortIfExp
    then
      // Safe to do if eThen and eElse don't emit pre-expressions
      '(<%condExp%>?<%eThen%>:<%eElse%>)'
    else
      let condVar = tempDecl("modelica_boolean", &varDecls /*BUFD*/)
      let resVarType = expTypeFromExpArrayIf(expThen)
      let resVar = tempDecl(resVarType, &varDecls /*BUFD*/)
      let &preExp +=
      <<
      <%condVar%> = (modelica_boolean)<%condExp%>;
      if (<%condVar%>) {
        <%preExpThen%>
        <%resVar%> = (<%resVarType%>)<%eThen%>;
      } else {
        <%preExpElse%>
        <%resVar%> = (<%resVarType%>)<%eElse%>;
      }<%\n%>
      >>
      resVar)
end daeExpIf;


template daeExpCall(Exp call, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates code for a function call."
::=
  match call
  // special builtins
  case CALL(path=IDENT(name="DIVISION"),
            expLst={e1, e2, DAE.SCONST(string=string)}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    let var3 = Util.escapeModelicaStringToCString(string)
    'DIVISION(<%var1%>,<%var2%>,"<%var3%>")'

  case CALL(attr=CALL_ATTR(__),
            path=IDENT(name="DIVISION_ARRAY_SCALAR"),
            expLst={e1, e2, DAE.SCONST(string=string)}) then
    let type = match attr.ty case T_ARRAY(ty=T_INTEGER(__)) then "integer_array"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDecl(type, &varDecls)
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    let var3 = Util.escapeModelicaStringToCString(string)
    let &preExp += 'division_alloc_<%type%>_scalar(&<%var1%>, <%var2%>, &<%var%>,"<%var3%>");<%\n%>'
    '<%var%>'

  case CALL(path=IDENT(name="der"), expLst={arg as CREF(__)}) then
    '_DER<%cref(arg.componentRef)%>'
  case CALL(path=IDENT(name="der"), expLst={exp}) then
    error(sourceInfo(), 'Code generation does not support der(<%ExpressionDumpTpl.dumpExp(exp,"\"")%>)')
  case CALL(path=IDENT(name="pre"), expLst={arg}) then
    daeExpCallPre(arg, context, preExp, varDecls)
  case CALL(path=IDENT(name="edge"), expLst={arg as CREF(__)}) then
    '(<%cref(arg.componentRef)%> && !_PRE<%cref(arg.componentRef)%>)'
  case CALL(path=IDENT(name="edge"), expLst={exp}) then
    error(sourceInfo(), 'Code generation does not support edge(<%ExpressionDumpTpl.dumpExp(exp,"\"")%>)')
  case CALL(path=IDENT(name="change"), expLst={arg as CREF(__)}) then
    '(<%cref(arg.componentRef)%> != _PRE<%cref(arg.componentRef)%>)'
  case CALL(path=IDENT(name="change"), expLst={exp}) then
    error(sourceInfo(), 'Code generation does not support change(<%ExpressionDumpTpl.dumpExp(exp,"\"")%>)')

  case CALL(path=IDENT(name="print"), expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    if acceptMetaModelicaGrammar() then 'print(<%var1%>)' else 'puts(<%var1%>)'

  case CALL(path=IDENT(name="max"), attr=CALL_ATTR(ty = T_REAL(__)), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    'fmax(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="max"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    'modelica_integer_max((modelica_integer)<%var1%>,(modelica_integer)<%var2%>)'

  case CALL(attr=CALL_ATTR(ty = T_REAL(__)),
            path=IDENT(name="min"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    'fmin(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="min"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    'modelica_integer_min((modelica_integer)<%var1%>,(modelica_integer)<%var2%>)'

  case CALL(path=IDENT(name="abs"), expLst={e1}, attr=CALL_ATTR(ty=T_INTEGER(__))) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    'labs(<%var1%>)'

  case CALL(path=IDENT(name="abs"), expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    'fabs(<%var1%>)'

    //sqrt
  case CALL(path=IDENT(name="sqrt"), expLst={e1}, attr=attr as CALL_ATTR(__)) then
    let retPre = assertCommon(createAssertforSqrt(e1),createDAEString("Model error: Argument of sqrt should be >= 0"), context, &varDecls, dummyInfo)
    let argStr = daeExp(e1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let &preExp += '<%retPre%>'
    'sqrt(<%argStr%>)'

  case CALL(path=IDENT(name="div"), expLst={e1,e2}, attr=CALL_ATTR(ty = T_INTEGER(__))) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    'ldiv(<%var1%>,<%var2%>).quot'

  case CALL(path=IDENT(name="div"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    'trunc(<%var1%>/<%var2%>)'

  case CALL(path=IDENT(name="floor"), expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    '::floor(<%var1%>)'

  case CALL(path=IDENT(name="ceil"), expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    '::ceil(<%var1%>)'

  case CALL(path=IDENT(name="mod"), expLst={e1,e2}, attr=CALL_ATTR(__)) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    'modelica_mod_<%expTypeShort(attr.ty)%>(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="max"), expLst={array}) then
    let expVar = daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArray(array)%>'
    let tvar = tempDecl(expTypeFromExpModelica(array), &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = max_<%arr_tp_str%>(&<%expVar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="min"), expLst={array}) then
    let expVar = daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArray(array)%>'
    let tvar = tempDecl(expTypeFromExpModelica(array), &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = min_<%arr_tp_str%>(&<%expVar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="fill"), expLst=val::dims, attr=CALL_ATTR(__)) then
    let valExp = daeExp(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let dimsExp = (dims |> dim =>
      daeExp(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/) ;separator=", ")
    let ty_str = '<%expTypeArray(attr.ty)%>'
    let tvar = tempDecl(ty_str, &varDecls /*BUFD*/)
    let &preExp += 'fill_alloc_<%ty_str%>(&<%tvar%>, <%valExp%>, <%listLength(dims)%>, <%dimsExp%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="cat"), expLst=dim::arrays, attr=CALL_ATTR(__)) then
    let dim_exp = daeExp(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arrays_exp = (arrays |> array =>
      daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/) ;separator=", &")
    let ty_str = '<%expTypeArray(attr.ty)%>'
    let tvar = tempDecl(ty_str, &varDecls /*BUFD*/)
    let &preExp += 'cat_alloc_<%ty_str%>(<%dim_exp%>, &<%tvar%>, <%listLength(arrays)%>, &<%arrays_exp%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="promote"), expLst={A, n}) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let var2 = daeExp(n, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'promote_alloc_<%arr_tp_str%>(&<%var1%>, <%var2%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="transpose"), expLst={A}) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'transpose_alloc_<%arr_tp_str%>(&<%var1%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="cross"), expLst={v1, v2}) then
    let var1 = daeExp(v1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let var2 = daeExp(v2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArray(v1)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'cross_alloc_<%arr_tp_str%>(&<%var1%>, &<%var2%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="identity"), expLst={A}) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'identity_alloc_<%arr_tp_str%>(<%var1%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="rem"),
            expLst={e1, e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    let typeStr = expTypeFromExpShort(e1)
    'modelica_rem_<%typeStr%>(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="String"),
            expLst={s, format}) then
    let tvar = tempDecl("modelica_string", &varDecls /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let formatExp = daeExp(format, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeStr = expTypeFromExpModelica(s)
    let &preExp += '<%tvar%> = <%typeStr%>_to_modelica_string_format(<%sExp%>, <%formatExp%>);<%\n%>'
    '<%tvar%>'


  case CALL(path=IDENT(name="String"),
            expLst={s, minlen, leftjust}) then
    let tvar = tempDecl("modelica_string", &varDecls /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let minlenExp = daeExp(minlen, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let leftjustExp = daeExp(leftjust, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeStr = expTypeFromExpModelica(s)
    let &preExp += '<%tvar%> = <%typeStr%>_to_modelica_string(<%sExp%>, <%minlenExp%>, <%leftjustExp%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="String"),
            expLst={s, signdig, minlen, leftjust}) then
    let tvar = tempDecl("modelica_string", &varDecls /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let minlenExp = daeExp(minlen, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let leftjustExp = daeExp(leftjust, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let signdigExp = daeExp(signdig, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = modelica_real_to_modelica_string(<%sExp%>, <%signdigExp%>, <%minlenExp%>, <%leftjustExp%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="delay"),
            expLst={ICONST(integer=index), e, d, delayMax}) then
    let tvar = tempDecl("modelica_real", &varDecls /*BUFD*/)
    let var1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let var2 = daeExp(d, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = calcDelay(<%index%>, <%var1%>, timeValue, <%var2%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="integer"),
            expLst={toBeCasted}) then
    let castedVar = daeExp(toBeCasted, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    '((modelica_integer)(::floor(<%castedVar%>)))'

  case CALL(path=IDENT(name="Integer"),
            expLst={toBeCasted}) then
    let castedVar = daeExp(toBeCasted, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    '((modelica_integer)<%castedVar%>)'

  case CALL(path=IDENT(name="clock"), expLst={}) then
    'mmc_clock()'

  case CALL(path=IDENT(name="noEvent"),
            expLst={e1}) then
    daeExp(e1, context, &preExp, &varDecls)

  case CALL(path=IDENT(name="anyString"),
            expLst={e1}) then
    'mmc_anyString(<%daeExp(e1, context, &preExp, &varDecls)%>)'


  case CALL(path=IDENT(name="mmc_get_field"),
            expLst={s1, ICONST(integer=i)}) then
    let tvar = tempDecl("modelica_metatype", &varDecls /*BUFD*/)
    let expPart = daeExp(s1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%expPart%>), <%i%>));<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name = "mmc_unbox_record"),
            expLst={s1}, attr=CALL_ATTR(__)) then
    let argStr = daeExp(s1, context, &preExp, &varDecls)
    unboxRecord(argStr, attr.ty, &preExp, &varDecls)

  case exp as CALL(attr=CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = if attr.builtin then (match attr.ty case T_NORETCALL(__) then ""
      else expTypeModelica(attr.ty))
      else '<%funName%>_rettype'
    let retVar = match attr.ty
      case T_NORETCALL(__) then ""
      else tempDecl(retType, &varDecls)
    let &preExp += if not attr.builtin then match context case SIMULATION_CONTEXT(__) then
      <<
      #ifdef _OMC_MEASURE_TIME
      SIM_PROF_TICK_FN(<%funName%>_index);
      #endif<%\n%>
      >>
    let &preExp += '<%if retVar then '<%retVar%> = '%><%daeExpCallBuiltinPrefix(attr.builtin)%><%funName%>(<%argStr%>);<%\n%>'
    let &preExp += if not attr.builtin then match context case SIMULATION_CONTEXT(__) then
      <<
      #ifdef _OMC_MEASURE_TIME
      SIM_PROF_ACC_FN(<%funName%>_index);
      #endif<%\n%>
      >>
    match exp
      // no return calls
      case CALL(attr=CALL_ATTR(ty=T_NORETCALL(__))) then '/* NORETCALL */'
      // non tuple calls (single return value)
      case CALL(attr=CALL_ATTR(tuple_=false)) then
        if attr.builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'
      // tuple calls (multiple return values)
      case CALL(attr=CALL_ATTR(tuple_=true)) then
        '<%retVar%>'
end daeExpCall;


template daeExpCallBuiltinPrefix(Boolean builtin)
 "Helper to daeExpCall."
::=
  match builtin
  case true  then ""
  case false then "_"
end daeExpCallBuiltinPrefix;


template daeExpArray(Exp exp, Context context, Text &preExp /*BUFP*/,
                     Text &varDecls /*BUFP*/)
 "Generates code for an array expression."
::=
match exp
case ARRAY(__) then
  let scalarRef = if scalar then "&" else ""
  let params = (array |> e =>
      let prefix = if scalar then '(<%expTypeFromExpModelica(e)%>)' else '&'
      '<%prefix%><%daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>'
    ;separator="_")
  '<%params%>'
end daeExpArray;

template daeExpMatrix(Exp exp, Context context, Text &preExp /*BUFP*/,
                      Text &varDecls /*BUFP*/)
 "Generates code for a matrix expression."
::=
  match exp
  case MATRIX(matrix={{}})  // special case for empty matrix: create dimensional array Real[0,1]
  case MATRIX(matrix={})    // special case for empty array: create dimensional array Real[0,1]
    then
    let arrayTypeStr = expTypeArray(ty)
    let tmp = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
    let &preExp += 'alloc_<%arrayTypeStr%>(&<%tmp%>, 2, 0, 1);<%\n%>'
    tmp
  case m as MATRIX(__) then
    let arrayTypeStr = expTypeArray(m.ty)
    let &vars2 = buffer "" /*BUFD*/
    let &promote = buffer "" /*BUFD*/
    let catAlloc = (m.matrix |> row =>
        let tmp = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
        let vars = daeExpMatrixRow(row, arrayTypeStr, context,
                                 &promote /*BUFC*/, &varDecls /*BUFD*/)
        let &vars2 += ', &<%tmp%>'
        'cat_alloc_<%arrayTypeStr%>(2, &<%tmp%>, <%listLength(row)%><%vars%>);'
      ;separator="\n")
    let &preExp += promote
    let &preExp += catAlloc
    let &preExp += "\n"
    let tmp = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
    let &preExp += 'cat_alloc_<%arrayTypeStr%>(1, &<%tmp%>, <%listLength(m.matrix)%><%vars2%>);<%\n%>'
    tmp
end daeExpMatrix;


template daeExpMatrixRow(list<Exp> row, String arrayTypeStr,
                         Context context, Text &preExp /*BUFP*/,
                         Text &varDecls /*BUFP*/)
 "Helper to daeExpMatrix."
::=
  let &varLstStr = buffer "" /*BUFD*/

  let preExp2 = (row |> e =>
      let expVar = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      let tmp = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
      let &varLstStr += ', &<%tmp%>'
      'promote_scalar_<%arrayTypeStr%>(<%expVar%>, 2, &<%tmp%>);'
    ;separator="\n")
  let &preExp2 += "\n"
  let &preExp += preExp2
  varLstStr
end daeExpMatrixRow;

template daeExpRange(Exp exp, Context context, Text &preExp /*BUFP*/,
                      Text &varDecls /*BUFP*/)
 "Generates code for a range expression."
::=
  match exp
  case RANGE(step = NONE()) then
    let ty_str = expTypeArray(ty)
    let start_exp = daeExp(start, context, &preExp, &varDecls)
    let stop_exp = daeExp(stop, context, &preExp, &varDecls)
    let tmp = tempDecl(ty_str, &varDecls)
    let &preExp += 'create_integer_range_array(&<%tmp%>, <%start_exp%>, 1, <%stop_exp%>);<%\n%>'
    '<%tmp%>'
end daeExpRange;

template daeExpCast(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates code for a cast expression."
::=
match exp
case CAST(__) then
  let expVar = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match ty
  case T_INTEGER(__)   then '((modelica_integer)<%expVar%>)'
  case T_REAL(__)  then '((modelica_real)<%expVar%>)'
  case T_ENUMERATION(__)   then '((modelica_integer)<%expVar%>)'
  case T_BOOL(__)   then '((modelica_boolean)<%expVar%>)'
  case T_ARRAY(__) then
    let arrayTypeStr = expTypeArray(ty)
    let tvar = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
    let to = expTypeShort(ty)
    let from = expTypeFromExpShort(exp)
    let &preExp += 'cast_<%from%>_array_to_<%to%>(&<%expVar%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'
  else
    '(<%expVar%>) /* could not cast, using the variable as it is */'
end daeExpCast;


template daeExpAsub(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates code for an asub expression."
::=
  match expTypeFromExpShort(exp)
  case "metatype" then
  // MetaModelica Array
    (match exp case ASUB(exp=e, sub={idx}) then
      let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      let idx1 = daeExp(idx, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      'arrayGet(<%e1%>,<%idx1%>) /* DAE.ASUB */')
  // Modelica Array
  else
  match exp

  // Faster asub: Do not construct a whole new array just to access one subscript
  case ASUB(exp=exp as ARRAY(scalar=true), sub={idx}) then
    let res = tempDecl(expTypeFromExpShort(exp),&varDecls)
    let idx1 = daeExp(idx, context, &preExp, &varDecls)
    let expl = (exp.array |> e hasindex i1 fromindex 1 =>
      let &caseVarDecls = buffer ""
      let &casePreExp = buffer ""
      let v = daeExp(e, context, &casePreExp, &caseVarDecls)
      <<
      case <%i1%>: {
        <%&caseVarDecls%>
        <%&casePreExp%>
        <%res%> = <%v%>;
        break;
      }
      >> ; separator = "\n")
    let &preExp +=
    <<
    switch (<%idx1%>) { /* ASUB */
    <%expl%>
    default:
      assert(NULL == "index out of bounds");
    }
    >>
    res

  case ASUB(exp=RANGE(ty=t), sub={idx}) then
    'ASUB_EASY_CASE'

  case ASUB(exp=ASUB(
              exp=ASUB(
                exp=ASUB(exp=e, sub={ICONST(integer=i)}),
                sub={ICONST(integer=j)}),
              sub={ICONST(integer=k)}),
            sub={ICONST(integer=l)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get_4D(&<%e1%>, <%incrementInt(i,-1)%>, <%incrementInt(j,-1)%>, <%incrementInt(k,-1)%>, <%incrementInt(l,-1)%>)'

  case ASUB(exp=ASUB(
              exp=ASUB(exp=e, sub={ICONST(integer=i)}),
              sub={ICONST(integer=j)}),
            sub={ICONST(integer=k)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get_3D(&<%e1%>, <%incrementInt(i,-1)%>, <%incrementInt(j,-1)%>, <%incrementInt(k,-1)%>)'

  case ASUB(exp=ASUB(exp=e, sub={ICONST(integer=i)}),
            sub={ICONST(integer=j)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get_2D(&<%e1%>, <%incrementInt(i,-1)%>, <%incrementInt(j,-1)%>)'

  case ASUB(exp=e, sub={ICONST(integer=i)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get(&<%e1%>, <%incrementInt(i,-1)%>)'

  case ASUB(exp=ecr as CREF(__), sub=subs) then
    let arrName = daeExpCrefRhs(buildCrefExpFromAsub(ecr, subs), context,
                              &preExp /*BUFC*/, &varDecls /*BUFD*/)
    match context case FUNCTION_CONTEXT(__)  then
      arrName
    else
      arrayScalarRhs(ecr.ty, subs, arrName, context, &preExp, &varDecls)

  case ASUB(exp=ASUB(
              exp=ASUB(
                exp=ASUB(exp=e, sub={ENUM_LITERAL(index=i)}),
                sub={ENUM_LITERAL(index=j)}),
              sub={ENUM_LITERAL(index=k)}),
            sub={ENUM_LITERAL(index=l)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get_4D(&<%e1%>, <%incrementInt(i,-1)%>, <%incrementInt(j,-1)%>, <%incrementInt(k,-1)%>, <%incrementInt(l,-1)%>)'

  case ASUB(exp=ASUB(
              exp=ASUB(exp=e, sub={ENUM_LITERAL(index=i)}),
              sub={ENUM_LITERAL(index=j)}),
            sub={ENUM_LITERAL(index=k)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get_3D(&<%e1%>, <%incrementInt(i,-1)%>, <%incrementInt(j,-1)%>, <%incrementInt(k,-1)%>)'

  case ASUB(exp=ASUB(exp=e, sub={ENUM_LITERAL(index=i)}),
            sub={ENUM_LITERAL(index=j)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get_2D(&<%e1%>, <%incrementInt(i,-1)%>, <%incrementInt(j,-1)%>)'

  case ASUB(exp=e, sub={ENUM_LITERAL(index=i)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get(&<%e1%>, <%incrementInt(i,-1)%>)'

  case ASUB(exp=e, sub={index}) then
    let exp = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get(&<%exp%>, ((<%expIndex%>) - 1))'

  case ASUB(exp=e, sub=indexes) then
    let exp = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expIndexes = (indexes |> index => '<%daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>' ;separator=", ")
    'CODEGEN_COULD_NOT_HANDLE_ASUB(<%exp%>[<%expIndexes%>])'

  else
    'OTHER_ASUB'
end daeExpAsub;

template daeExpCallPre(Exp exp, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/)
  "Generates code for an asub of a cref, which becomes cref + offset."
::=
  match exp
  case cr as CREF(__) then
    '_PRE<%cref(cr.componentRef)%>'
  case ASUB(exp = cr as CREF(__), sub = {sub_exp}) then
    let offset = daeExp(sub_exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let cref = cref(cr.componentRef)
    '*(&_PRE<%cref%> + <%offset%>)'
  else
    error(sourceInfo(), 'Code generation does not support pre(<%ExpressionDumpTpl.dumpExp(exp,"\"")%>)')
end daeExpCallPre;

template daeExpSize(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates code for a size expression."
::=
  match exp
  case SIZE(exp=CREF(__), sz=SOME(dim)) then
    let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let dimPart = daeExp(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let resVar = tempDecl("modelica_integer", &varDecls /*BUFD*/)
    let typeStr = '<%expTypeArray(exp.ty)%>'
    let &preExp += '<%resVar%> = size_of_dimension_<%typeStr%>(&<%expPart%>, <%dimPart%>);<%\n%>'
    resVar
  else "size(X) not implemented"
end daeExpSize;


template daeExpReduction(Exp exp, Context context, Text &preExp /*BUFP*/,
                         Text &varDecls /*BUFP*/)
 "Generates code for a reduction expression. The code is quite messy because it handles all
  special reduction functions (list, listReverse, array) and handles both list and array as input"
::=
  match exp
  case r as REDUCTION(reductionInfo=ri as REDUCTIONINFO(__),iterators={iter as REDUCTIONITER(__)}) then
  let &tmpVarDecls = buffer ""
  let &tmpExpPre = buffer ""
  let &bodyExpPre = buffer ""
  let &guardExpPre = buffer ""
  let &rangeExpPre = buffer ""
  let stateVar = if not acceptMetaModelicaGrammar() then tempDecl("state", &varDecls /*BUFD*/)
  let identType = expTypeFromExpModelica(iter.exp)
  let arrayType = expTypeFromExpArray(iter.exp)
  let arrayTypeResult = expTypeFromExpArray(r)
  let loopVar = match identType
    case "modelica_metatype" then tempDecl(identType,&tmpVarDecls)
    else tempDecl(arrayType,&tmpVarDecls)
  let firstIndex = match identType case "modelica_metatype" then "" else tempDecl("int",&tmpVarDecls)
  let arrIndex = match ri.path case IDENT(name="array") then tempDecl("int",&tmpVarDecls)
  let foundFirst = if not ri.defaultValue then tempDecl("int",&tmpVarDecls)
  let rangeExp = daeExp(iter.exp,context,&rangeExpPre,&tmpVarDecls)
  let resType = expTypeArrayIf(typeof(exp))
  let res = "_$reductionFoldTmpB"
  let &tmpVarDecls += '<%resType%> <%res%>;<%\n%>'
  let resTmp = tempDecl(resType,&varDecls)
  let &preDefault = buffer ""
  let resTail = match ri.path case IDENT(name="list") then tempDecl("modelica_metatype*",&tmpVarDecls)
  let defaultValue = match ri.path case IDENT(name="array") then "" else match ri.defaultValue
    case SOME(v) then daeExp(valueExp(v),context,&preDefault,&tmpVarDecls)
    end match
  let guardCond = match iter.guardExp case SOME(grd) then daeExp(grd, context, &guardExpPre, &tmpVarDecls) else "1"
  let empty = match identType case "modelica_metatype" then 'listEmpty(<%loopVar%>)' else '0 == size_of_dimension_base_array(&<%loopVar%>, 1)'
  let length = match identType case "modelica_metatype" then 'listLength(<%loopVar%>)' else 'size_of_dimension_base_array(&<%loopVar%>, 1)'
  let reductionBodyExpr = "_$reductionFoldTmpA"
  let bodyExprType = expTypeArrayIf(typeof(r.expr))
  let reductionBodyExprWork = daeExp(r.expr, context, &bodyExpPre, &tmpVarDecls)
  let &tmpVarDecls += '<%bodyExprType%> <%reductionBodyExpr%>;<%\n%>'
  let &bodyExpPre += '<%reductionBodyExpr%> = <%reductionBodyExprWork%>;<%\n%>'
  let foldExp = match ri.path
    case IDENT(name="list") then
    <<
    *<%resTail%> = mmc_mk_cons(<%reductionBodyExpr%>,0);
    <%resTail%> = &MMC_CDR(*<%resTail%>);
    >>
    case IDENT(name="listReverse") then // This is too easy; the damn list is already in the correct order
      '<%res%> = mmc_mk_cons(<%reductionBodyExpr%>,<%res%>);'
    case IDENT(name="array") then
      '*(<%arrayTypeResult%>_element_addr1(&<%res%>, 1, <%arrIndex%>++)) = <%reductionBodyExpr%>;'
    else match ri.foldExp case SOME(fExp) then
      let &foldExpPre = buffer ""
      let fExpStr = daeExp(fExp, context, &bodyExpPre, &tmpVarDecls)
      if not ri.defaultValue then
      <<
      if (<%foundFirst%>) {
        <%res%> = <%fExpStr%>;
      } else {
        <%res%> = <%reductionBodyExpr%>;
        <%foundFirst%> = 1;
      }
      >>
      else '<%res%> = <%fExpStr%>;'
  let firstValue = match ri.path
     case IDENT(name="array") then
     <<
     <%arrIndex%> = 1;
     simple_alloc_1d_<%arrayTypeResult%>(&<%res%>,<%length%>);
     >>
     else if ri.defaultValue then
     <<
     <%&preDefault%>
     <%res%> = <%defaultValue%>; /* defaultValue */
     >>
     else
     <<
     <%foundFirst%> = 0; /* <%dotPath(ri.path)%> lacks default-value */
     >>
  let iteratorName = contextIteratorName(iter.id, context)
  let loopHead = match identType
    case "modelica_metatype" then
    <<
    while (!<%empty%>) {
      <%identType%> <%iteratorName%>;
      <%iteratorName%> = MMC_CAR(<%loopVar%>);
      <%loopVar%> = MMC_CDR(<%loopVar%>);
    >>
    else
    <<
    while (<%firstIndex%> <= size_of_dimension_<%arrayType%>(&<%loopVar%>, 1)) {
      <%identType%> <%iteratorName%>;
      <%iteratorName%> = *(<%arrayType%>_element_addr1(&<%loopVar%>, 1, <%firstIndex%>++));
      <%if not acceptMetaModelicaGrammar() then '<%stateVar%> = get_memory_state();'%>
    >>
  let loopTail = match identType
     case "modelica_metatype" then "}"
     else if not acceptMetaModelicaGrammar() then 'restore_memory_state(<%stateVar%>);<%\n%>}' else "}"
  let &preExp += <<
  {
    <%&tmpVarDecls%>
    <%&rangeExpPre%>
    <%loopVar%> = <%rangeExp%>;
    <% if firstIndex then '<%firstIndex%> = 1;' %>
    <%firstValue%>
    <% if resTail then '<%resTail%> = &<%res%>;' %>
    <%loopHead%>
      <%&guardExpPre%>
      if (<%guardCond%>) {
        <%&bodyExpPre%>
        <%foldExp%>
      }
    <%loopTail%>
    <% if not ri.defaultValue then 'if (!<%foundFirst%>) MMC_THROW();' %>
    <% if resTail then '*<%resTail%> = mmc_mk_nil();' %>
    <% resTmp %> = <% res %>;
  }<%\n%>
  >>
  resTmp
  else error(sourceInfo(), 'Code generation does not support multiple iterators: <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
end daeExpReduction;

template daeExpMatch(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for a match expression."
::=
match exp
case exp as MATCHEXPRESSION(__) then
  let res = match et case T_NORETCALL(__) then "ERROR_MATCH_EXPRESSION_NORETCALL" else tempDecl(expTypeModelica(et), &varDecls)
  daeExpMatch2(exp,listExpLength1,res,context,&preExp,&varDecls)
end daeExpMatch;

template daeExpMatch2(Exp exp, list<Exp> tupleAssignExps, Text res, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for a match expression."
::=
match exp
case exp as MATCHEXPRESSION(__) then
  let &preExpInner = buffer ""
  let &preExpRes = buffer ""
  let &varDeclsInput = buffer ""
  let &varDeclsInner = buffer ""
  let &ignore = buffer ""
  let ignore2 = (elementVars(localDecls) |> var =>
      varInit(var, "", 0, &varDeclsInner /*BUFC*/, &preExpInner /*BUFC*/)
    )
  let prefix = 'tmp<%System.tmpTick()%>'
  let &preExpInput = buffer ""
  let &expInput = buffer ""
  let ignore3 = (inputs |> exp hasindex i0 =>
    let decl = '<%prefix%>_in<%i0%>'
    let typ = '<%expTypeFromExpModelica(exp)%>'
    let initVar = match typ case "modelica_metatype" then ' = NULL' else ''
    let addRoot = match typ case "modelica_metatype" then ' mmc_GC_add_root(&<%decl%>, mmc_GC_local_state, "<%decl%>");' else ''
    let &varDeclsInput += '<%typ%> <%decl%><%initVar%>;<%addRoot%><%\n%>'
    let &expInput += '<%decl%> = <%daeExp(exp, context, &preExpInput, &varDeclsInput)%>;<%\n%>'
    ""; empty)
  let ix = match exp.matchType
    case MATCH(switch=SOME((switchIndex,T_STRING(__),div))) then
      'stringHashDjb2Mod(<%prefix%>_in<%switchIndex%>,<%div%>)'
    case MATCH(switch=SOME((switchIndex,T_METATYPE(__),_))) then
      'valueConstructor(<%prefix%>_in<%switchIndex%>)'
    case MATCH(switch=SOME((switchIndex,ty as T_INTEGER(__),_))) then

      '<%prefix%>_in<%switchIndex%>'
    case MATCH(switch=SOME(_)) then
      error(sourceInfo(), 'Unknown switch: <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
    else tempDecl('int', &varDeclsInner)
  let done = tempDecl('int', &varDeclsInner)
  let onPatternFail = match exp.matchType case MATCHCONTINUE(__) then "MMC_THROW()" case MATCH(__) then "break"
  let &preExp +=
      <<
      { /* <% match exp.matchType case MATCHCONTINUE(__) then "matchcontinue expression" case MATCH(__) then "match expression" %> */
        <%varDeclsInput%>
        <%preExpInput%>
        <%expInput%>

        /* GC: push the mark! */
        <%if acceptMetaModelicaGrammar()
          then 'mmc_GC_local_state_type mmc_GC_local_state = mmc_GC_save_roots_state("match");'%>

        {
          <%varDeclsInner%>
          <%preExpInner%>
          <%match exp.matchType
          case MATCH(switch=SOME(_)) then '<%done%> = 0;<%\n%>{'
          else 'for (<%ix%> = 0, <%done%> = 0; <%ix%> < <%listLength(exp.cases)%> && !<%done%>; <%ix%>++) {'
          %>
            <% match exp.matchType case MATCHCONTINUE(__) then "MMC_TRY()" %>

            switch (<%ix%>) {
            <%daeExpMatchCases(exp.cases,tupleAssignExps,exp.matchType,ix,res,prefix,onPatternFail,done,context,&varDecls)%>
            }

            <% match exp.matchType case MATCHCONTINUE(__) then "MMC_CATCH()" %>
          }

          if (!<%done%>) MMC_THROW();
        }

        /* GC: pop the mark! */
        <%if acceptMetaModelicaGrammar()
          then 'mmc_GC_undo_roots_state(mmc_GC_local_state);'%>
      }
      >>
  res
end daeExpMatch2;

template daeExpMatchCases(list<MatchCase> cases, list<Exp> tupleAssignExps, DAE.MatchType ty, Text ix, Text res, Text prefix, Text onPatternFail, Text done, Context context, Text &varDecls)
::=
  cases |> c as CASE(__) hasindex i0 =>
  let &varDeclsCaseInner = buffer ""
  let &preExpCaseInner = buffer ""
  let &assignments = buffer ""
  let &preRes = buffer ""
  let patternMatching = (c.patterns |> lhs hasindex i0 => patternMatch(lhs,'<%prefix%>_in<%i0%>',onPatternFail,&varDeclsCaseInner,&assignments); empty)
  let stmts = (c.body |> stmt => algStatement(stmt, context, &varDeclsCaseInner); separator="\n")
  let caseRes = (match c.result
    case SOME(TUPLE(PR=exps)) then
      (exps |> e hasindex i1 fromindex 1 => '<%res%>_targ<%i1%> = <%daeExp(e,context,&preRes,&varDeclsCaseInner)%>;<%\n%>')
    case SOME(exp as CALL(attr=CALL_ATTR(tuple_=true))) then
      let retStruct = daeExp(exp, context, &preRes, &varDeclsCaseInner)
      (tupleAssignExps |> cr hasindex i1 fromindex 1 =>
        '<%res%>_targ<%i1%> = <%retStruct%>.targ<%i1%>;<%\n%>')
    case SOME(e) then '<%res%> = <%daeExp(e,context,&preRes,&varDeclsCaseInner)%>;<%\n%>')
  let _ = (elementVars(c.localDecls) |> var => varInit(var, "", 0, &varDeclsCaseInner, &preExpCaseInner))
  <<<%match ty case MATCH(switch=SOME((n,_,ea))) then switchIndex(listGet(c.patterns,n),ea) else 'case <%i0%>'%>: {

    <%varDeclsCaseInner%>
    <%preExpCaseInner%>

     /* GC: push the mark! */
     <%if acceptMetaModelicaGrammar()
       then 'mmc_GC_local_state_type mmc_GC_local_state = mmc_GC_save_roots_state("case");'%>

    <%patternMatching%>
    <% match c.jump
       case 0 then "/* Pattern matching succeeded */"
       else '<%ix%> += <%c.jump%>; /* Pattern matching succeeded; we may skip some cases if we fail */'
    %>
    <%assignments%>
    <%stmts%>
    /*#modelicaLine <%infoStr(c.resultInfo)%>*/
    <% if c.result then '<%preRes%><%caseRes%>' else 'MMC_THROW();<%\n%>' %>
    /*#endModelicaLine*/
    <%done%> = 1;

    /* GC: pop the mark! */
    <%if acceptMetaModelicaGrammar()
      then 'mmc_GC_undo_roots_state( mmc_GC_local_state);'%>

    break;
  }<%\n%>
  >>
end daeExpMatchCases;

template switchIndex(Pattern pattern, Integer extraArg)
::=
  match pattern
    case PAT_CALL(__) then 'case <%getValueCtor(index)%>'
    case PAT_CONSTANT(exp=e as SCONST(__)) then 'case <%stringHashDjb2Mod(e.string,extraArg)%> /* <%e.string%> */'
    case PAT_CONSTANT(exp=e as ICONST(__)) then 'case <%e.integer%>'
    else 'default'
end switchIndex;

template daeExpBox(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for a match expression."
::=
match exp
case exp as BOX(__) then
  let ty = expTypeFromExpShort(exp.exp)
  let res = daeExp(exp.exp,context,&preExp,&varDecls)
  'mmc_mk_<%ty%>(<%res%>)'
end daeExpBox;

template daeExpUnbox(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for a match expression."
::=
match exp
case exp as UNBOX(__) then
  let ty = expTypeShort(exp.ty)
  let res = daeExp(exp.exp,context,&preExp,&varDecls)
  'mmc_unbox_<%ty%>(<%res%>) /* DAE.UNBOX */'
end daeExpUnbox;

template daeExpSharedLiteral(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for a match expression."
::=
match exp case exp as SHARED_LITERAL(__) then '_OMC_LIT<%exp.index%>'
end daeExpSharedLiteral;


// TODO: Optimize as in Codegen
// TODO: Use this function in other places where almost the same thing is hard
//       coded
template arrayScalarRhs(Type ty, list<Exp> subs, String arrName, Context context,
               Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Helper to daeExpAsub."
::=
  let arrayType = expTypeArray(ty)
  let dimsLenStr = listLength(subs)
  let dimsValuesStr = (subs |> exp =>
      daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)

    ;separator=", ")
  match arrayType
    case "metatype_array" then
      'arrayGet(<%arrName%>,<%dimsValuesStr%>) /*arrayScalarRhs*/'
    else
      <<
      (*<%arrayType%>_element_addr(&<%arrName%>, <%dimsLenStr%>, <%dimsValuesStr%>))
      >>
end arrayScalarRhs;

template daeExpList(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates code for a meta modelica list expression."
::=
match exp
case LIST(__) then
  let tmp = tempDecl("modelica_metatype", &varDecls /*BUFD*/)
  let expPart = daeExpListToCons(valList, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let &preExp += '<%tmp%> = <%expPart%>;<%\n%>'
  tmp
end daeExpList;


template daeExpListToCons(list<Exp> listItems, Context context, Text &preExp /*BUFP*/,
                          Text &varDecls /*BUFP*/)
 "Helper to daeExpList."
::=
  match listItems
  case {} then "MMC_REFSTRUCTLIT(mmc_nil)"
  case e :: rest then
    let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let restList = daeExpListToCons(rest, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    mmc_mk_cons(<%expPart%>, <%restList%>)
    >>
end daeExpListToCons;


template daeExpCons(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates code for a meta modelica cons expression."
::=
match exp
case CONS(__) then
  let tmp = tempDecl("modelica_metatype", &varDecls /*BUFD*/)
  let carExp = daeExp(car, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)

  let cdrExp = daeExp(cdr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let &preExp += '<%tmp%> = mmc_mk_cons(<%carExp%>, <%cdrExp%>);<%\n%>'
  tmp
end daeExpCons;


template daeExpMetaTuple(Exp exp, Context context, Text &preExp /*BUFP*/,
                         Text &varDecls /*BUFP*/)
 "Generates code for a meta modelica tuple expression."
::=
match exp
case META_TUPLE(__) then
  let start = daeExpMetaHelperBoxStart(listLength(listExp))
  let args = (listExp |> e => daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    ;separator=", ")
  let tmp = tempDecl("modelica_metatype", &varDecls /*BUFD*/)
  let &preExp += '<%tmp%> = mmc_mk_box<%start%>0<%if args then ", "%><%args%>);<%\n%>'
  tmp
end daeExpMetaTuple;


template daeExpMetaOption(Exp exp, Context context, Text &preExp /*BUFP*/,
                          Text &varDecls /*BUFP*/)
 "Generates code for a meta modelica option expression."
::=
  match exp
  case META_OPTION(exp=NONE()) then
    "mmc_mk_none()"
  case META_OPTION(exp=SOME(e)) then
    let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    'mmc_mk_some(<%expPart%>)'
end daeExpMetaOption;


template daeExpMetarecordcall(Exp exp, Context context, Text &preExp /*BUFP*/,
                              Text &varDecls /*BUFP*/)
 "Generates code for a meta modelica record call expression."
::=
match exp
case METARECORDCALL(__) then
  let newIndex = getValueCtor(index)
  let argsStr = if args then
      ', <%args |> exp =>
        daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      ;separator=", "%>'
    else
      ""
  let box = 'mmc_mk_box<%daeExpMetaHelperBoxStart(incrementInt(listLength(args), 1))%><%newIndex%>, &<%underscorePath(path)%>__desc<%argsStr%>)'
  let tmp = tempDecl("modelica_metatype", &varDecls /*BUFD*/)
  let &preExp += '<%tmp%> = <%box%>;<%\n%>'
  tmp
end daeExpMetarecordcall;

template daeExpMetaHelperBoxStart(Integer numVariables)
 "Helper to determine how mmc_mk_box should be called."
::=
  match numVariables
  case 0
  case 1
  case 2
  case 3
  case 4
  case 5
  case 6
  case 7
  case 8
  case 9 then '<%numVariables%>('
  else '(<%numVariables%>, '
end daeExpMetaHelperBoxStart;

template outDecl(String ty, Text &varDecls /*BUFP*/)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar = 'out'
  let &varDecls += '<%ty%> <%newVar%>;<%\n%>'
  newVar
end outDecl;

template tempDecl(String ty, Text &varDecls /*BUFP*/)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar = 'tmp<%System.tmpTick()%>'
  let initVarAddRoot
         = match ty /* TODO! FIXME! UGLY! UGLY! hack! */
             case "modelica_metatype"
             case "metamodelica_string"
             case "metamodelica_string_const"
             case "stringListStringChar_rettype"
             case "stringAppendList_rettype"
             case "stringGetStringChar_rettype"
             case "stringUpdateStringChar_rettype"
             case "listReverse_rettype"
             case "listAppend_rettype"
             case "listGet_rettype"
             case "listDelete_rettype"
             case "listRest_rettype"
             case "listHead_rettype"
             case "arrayGet_rettype"
             case "arrayCreate_rettype"
             case "arrayList_rettype"
             case "listArray_rettype"
             case "arrayUpdate_rettype"
             case "arrayCopy_rettype"
             case "arrayAppend_rettype"
             case "getGlobalRoot_rettype"
               then ' = NULL;  mmc_GC_add_root(&<%newVar%>, mmc_GC_local_state, "<%newVar%>");' else ';'
  let &varDecls += '<%ty%> <%newVar%><%initVarAddRoot%><%\n%>'
  newVar
end tempDecl;

template tempDeclConst(String ty, String val, Text &varDecls /*BUFP*/)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar = 'tmp<%System.tmpTick()%>'
  let &varDecls += '<%ty%> <%newVar%> = <%val%>;<%\n%>'
  newVar
end tempDeclConst;

template varType(Variable var)
 "Generates type for a variable."
::=
match var
case var as VARIABLE(__) then
  if instDims then
    expTypeArray(var.ty)
  else
    expTypeArrayIf(var.ty)
end varType;

template varTypeBoxed(Variable var)
::=
match var
case VARIABLE(__) then 'modelica_metatype'
case FUNCTION_PTR(__) then 'modelica_fnptr'
end varTypeBoxed;



template expTypeRW(DAE.Type type)
 "Helper to writeOutVarRecordMembers."
::=
  match type
  case T_INTEGER(__)         then "TYPE_DESC_INT"
  case T_REAL(__)        then "TYPE_DESC_REAL"
  case T_STRING(__)      then "TYPE_DESC_STRING"
  case T_BOOL(__)        then "TYPE_DESC_BOOL"
  case T_ENUMERATION(__) then "TYPE_DESC_INT"
  case T_ARRAY(__)       then '<%expTypeRW(ty)%>_ARRAY'
  case T_COMPLEX(complexClassType=RECORD(__))
                      then "TYPE_DESC_RECORD"
  case T_METATYPE(__) case T_METABOXED(__)    then "TYPE_DESC_MMC"
end expTypeRW;

template expTypeShort(DAE.Type type)
 "Generate type helper."
::=
  match type
  case T_INTEGER(__)     then "integer"
  case T_REAL(__)        then "real"
  case T_STRING(__)      then if acceptMetaModelicaGrammar() then "metatype" else "string"
  case T_BOOL(__)        then "boolean"
  case T_ENUMERATION(__) then "integer"
  case T_UNKNOWN(__)     then "complex"
  case T_ANYTYPE(__)     then "complex"
  case T_ARRAY(__)       then expTypeShort(ty)
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__))
                      then "complex"
  case T_COMPLEX(__)     then 'struct <%underscorePath(ClassInf.getStateName(complexClassType))%>'
  case T_METATYPE(__) case T_METABOXED(__)    then "metatype"
  case T_FUNCTION_REFERENCE_VAR(__) then "fnptr"
  else "expTypeShort:ERROR"
end expTypeShort;

template mmcVarType(Variable var)
::=
  match var
  case VARIABLE(__) then 'modelica_<%mmcTypeShort(ty)%>'
  case FUNCTION_PTR(__) then 'modelica_fnptr'
end mmcVarType;

template mmcTypeShort(DAE.Type type)
::=
  match type
  case T_INTEGER(__)                     then "integer"
  case T_REAL(__)                    then "real"
  case T_STRING(__)                  then "string"
  case T_BOOL(__)                    then "integer"
  case T_ENUMERATION(__)             then "integer"
  case T_ARRAY(__)                   then "array"
  case T_METATYPE(__) case T_METABOXED(__)                then "metatype"
  case T_FUNCTION_REFERENCE_VAR(__)  then "fnptr"
  else "mmcTypeShort:ERROR"
end mmcTypeShort;


template expType(DAE.Type ty, Boolean array)
 "Generate type helper."
::=
  match array
  case true  then expTypeArray(ty)
  case false then expTypeModelica(ty)
end expType;


template expTypeModelica(DAE.Type ty)
 "Generate type helper."
::=
  expTypeFlag(ty, 2)
end expTypeModelica;


template expTypeArray(DAE.Type ty)
 "Generate type helper."
::=
  expTypeFlag(ty, 3)
end expTypeArray;


template expTypeArrayIf(DAE.Type ty)
 "Generate type helper."
::=
  expTypeFlag(ty, 4)
end expTypeArrayIf;


template expTypeFromExpShort(Exp exp)
 "Generate type helper."
::=
  expTypeFromExpFlag(exp, 1)
end expTypeFromExpShort;


template expTypeFromExpModelica(Exp exp)
 "Generate type helper."
::=
  expTypeFromExpFlag(exp, 2)
end expTypeFromExpModelica;


template expTypeFromExpArray(Exp exp)
 "Generate type helper."
::=
  expTypeFromExpFlag(exp, 3)
end expTypeFromExpArray;


template expTypeFromExpArrayIf(Exp exp)
 "Generate type helper."
::=
  expTypeFromExpFlag(exp, 4)
end expTypeFromExpArrayIf;


template expTypeFlag(DAE.Type ty, Integer flag)
 "Generate type helper."
::=
  match flag
  case 1 then
    // we want the short type
    expTypeShort(ty)
  case 2 then
    // we want the "modelica type"
    match ty case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__)) then
      'modelica_<%expTypeShort(ty)%>'
    else match ty case T_COMPLEX(__) then
      'struct <%underscorePath(ClassInf.getStateName(complexClassType))%>'
    else
      'modelica_<%expTypeShort(ty)%>'
  case 3 then
    // we want the "array type"
    '<%expTypeShort(ty)%>_array'
  case 4 then
    // we want the "array type" only if type is array, otherwise "modelica type"
    match ty
    case T_ARRAY(__) then '<%expTypeShort(ty)%>_array'
    else expTypeFlag(ty, 2)
end expTypeFlag;



template expTypeFromExpFlag(Exp exp, Integer flag)
 "Generate type helper."
::=
  match exp
  case ICONST(__)        then match flag case 8 then "int" case 1 then "integer" else "modelica_integer"
  case RCONST(__)        then match flag case 1 then "real" else "modelica_real"
  case SCONST(__)        then if acceptMetaModelicaGrammar() then
                                (match flag case 1 then "metatype" else "modelica_metatype")
                              else
                                (match flag case 1 then "string" else "modelica_string")
  case BCONST(__)        then match flag case 1 then "boolean" else "modelica_boolean"
  case ENUM_LITERAL(__)  then match flag case 8 then "int" case 1 then "integer" else "modelica_integer"
  case e as BINARY(__)
  case e as UNARY(__)
  case e as LBINARY(__)
  case e as LUNARY(__)
  case e as RELATION(__) then expTypeFromOpFlag(e.operator, flag)
  case IFEXP(__)         then expTypeFromExpFlag(expThen, flag)
  case CALL(attr=CALL_ATTR(__)) then expTypeFlag(attr.ty, flag)
  case c as ARRAY(__)
  case c as MATRIX(__)
  case c as RANGE(__)
  case c as CAST(__)
  case c as CREF(__)
  case c as CODE(__)     then expTypeFlag(c.ty, flag)
  case ASUB(__)          then expTypeFromExpFlag(exp, flag)
  case REDUCTION(__)     then expTypeFlag(typeof(exp), flag)
  case BOX(__)
  case CONS(__)
  case LIST(__)

  case META_TUPLE(__)
  case META_OPTION(__)
  case MATCHEXPRESSION(__)
  case METARECORDCALL(__)
  case BOX(__)           then match flag case 1 then "metatype" else "modelica_metatype"
  case c as UNBOX(__)    then expTypeFlag(c.ty, flag)
  case c as SHARED_LITERAL(__) then expTypeFromExpFlag(c.exp, flag)
  else error(sourceInfo(), 'expTypeFromExpFlag:<%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
end expTypeFromExpFlag;


template expTypeFromOpFlag(Operator op, Integer flag)
 "Generate type helper."
::=
  match op
  case o as ADD(__)
  case o as SUB(__)
  case o as MUL(__)
  case o as DIV(__)
  case o as POW(__)

  case o as UMINUS(__)
  case o as UMINUS_ARR(__)
  case o as ADD_ARR(__)
  case o as SUB_ARR(__)
  case o as MUL_ARR(__)
  case o as DIV_ARR(__)
  case o as MUL_ARRAY_SCALAR(__)
  case o as ADD_ARRAY_SCALAR(__)
  case o as SUB_SCALAR_ARRAY(__)
  case o as MUL_SCALAR_PRODUCT(__)
  case o as MUL_MATRIX_PRODUCT(__)
  case o as DIV_ARRAY_SCALAR(__)
  case o as DIV_SCALAR_ARRAY(__)
  case o as POW_ARRAY_SCALAR(__)
  case o as POW_SCALAR_ARRAY(__)
  case o as POW_ARR(__)
  case o as POW_ARR2(__)
  case o as LESS(__)
  case o as LESSEQ(__)
  case o as GREATER(__)
  case o as GREATEREQ(__)
  case o as EQUAL(__)
  case o as NEQUAL(__) then
    expTypeFlag(o.ty, flag)
  case o as AND(__)
  case o as OR(__)
  case o as NOT(__) then
    match flag case 1 then "boolean" else "modelica_boolean"
  else "expTypeFromOpFlag:ERROR"
end expTypeFromOpFlag;

template dimension(Dimension d)
::=
  match d
  case DAE.DIM_INTEGER(__) then integer
  case DAE.DIM_ENUM(__) then size
  case DAE.DIM_UNKNOWN(__) then ":"
  else "INVALID_DIMENSION"
end dimension;

template algStmtAssignPattern(DAE.Statement stmt, Context context, Text &varDecls)
 "Generates an assigment algorithm statement."
::=
  match stmt
  case s as STMT_ASSIGN(exp1=lhs as PATTERN(__)) then
    let &preExp = buffer ""
    let &assignments = buffer ""
    let expPart = daeExp(s.exp, context, &preExp, &varDecls)
    <</* Pattern-matching assignment */
    <%preExp%>
    <%patternMatch(lhs.pattern,expPart,"MMC_THROW()",&varDecls,&assignments)%><%assignments%>>>
end algStmtAssignPattern;

template patternMatch(Pattern pat, Text rhs, Text onPatternFail, Text &varDecls, Text &assignments)
::=
  match pat
  case PAT_WILD(__) then ""
  case p as PAT_CONSTANT(__)
    then
      let &unboxBuf = buffer ""
      let urhs = (match p.ty
        case SOME(et) then unboxVariable(rhs, et, &unboxBuf, &varDecls)
        else rhs
      )
      <<<%unboxBuf%><%match p.exp
        case c as ICONST(__) then 'if (<%c.integer%> != <%urhs%>) <%onPatternFail%>;<%\n%>'
        case c as RCONST(__) then 'if (<%c.real%> != <%urhs%>) <%onPatternFail%>;<%\n%>'
        case c as SCONST(__) then
          let escstr = Util.escapeModelicaStringToCString(c.string)
          'if (<%unescapedStringLength(escstr)%> != MMC_STRLEN(<%urhs%>) || strcmp("<%escstr%>", MMC_STRINGDATA(<%urhs%>)) != 0) <%onPatternFail%>;<%\n%>'
        case c as BCONST(__) then 'if (<%if c.bool then 1 else 0%> != <%urhs%>) <%onPatternFail%>;<%\n%>'
        case c as LIST(valList = {}) then 'if (!listEmpty(<%urhs%>)) <%onPatternFail%>;<%\n%>'
        case c as META_OPTION(exp = NONE()) then 'if (!optionNone(<%urhs%>)) <%onPatternFail%>;<%\n%>'

        else 'UNKNOWN_CONSTANT_PATTERN'
      %>>>
  case p as PAT_SOME(__) then
    let tvar = tempDecl("modelica_metatype", &varDecls)
    <<if (optionNone(<%rhs%>)) <%onPatternFail%>;
    <%tvar%> = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%rhs%>), 1));
    <%patternMatch(p.pat,tvar,onPatternFail,&varDecls,&assignments)%>>>
  case PAT_CONS(__) then
    let tvarHead = tempDecl("modelica_metatype", &varDecls)
    let tvarTail = tempDecl("modelica_metatype", &varDecls)
    <<if (listEmpty(<%rhs%>)) <%onPatternFail%>;
    <%tvarHead%> = MMC_CAR(<%rhs%>);
    <%tvarTail%> = MMC_CDR(<%rhs%>);
    <%patternMatch(head,tvarHead,onPatternFail,&varDecls,&assignments)%><%patternMatch(tail,tvarTail,onPatternFail,&varDecls,&assignments)%>>>
  case PAT_META_TUPLE(__)
    then
      (patterns |> p hasindex i1 fromindex 1 =>
        let tvar = tempDecl("modelica_metatype", &varDecls)
        <<<%tvar%> = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%rhs%>), <%i1%>));
        <%patternMatch(p,tvar,onPatternFail,&varDecls,&assignments)%>
        >>; empty /* increase the counter even if no output is produced */)
  case PAT_CALL_TUPLE(__)
    then
      (patterns |> p hasindex i1 fromindex 1 =>
        let nrhs = '<%rhs%>.targ<%i1%>'
        patternMatch(p,nrhs,onPatternFail,&varDecls,&assignments)
        ; empty /* increase the counter even if no output is produced */
      )
  case PAT_CALL_NAMED(__)
    then
      <<<%patterns |> (p,n,t) =>
        let tvar = tempDecl(expTypeModelica(t), &varDecls)
        <<<%tvar%> = <%rhs%>.<%n%>;
        <%patternMatch(p,tvar,onPatternFail,&varDecls,&assignments)%>
        >>%>
      >>
  case PAT_CALL(__)
    then
      <<if (mmc__uniontype__metarecord__typedef__equal(<%rhs%>,<%index%>,<%listLength(patterns)%>) == 0) <%onPatternFail%>;
      <%(patterns |> p hasindex i2 fromindex 2 =>
        let tvar = tempDecl("modelica_metatype", &varDecls)
        <<<%tvar%> = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%rhs%>), <%i2%>));
        <%patternMatch(p,tvar,onPatternFail,&varDecls,&assignments)%>
        >> ;empty) /* increase the counter even if no output is produced */
      %>
      >>
  case p as PAT_AS_FUNC_PTR(__) then
    let &assignments += '*((modelica_fnptr*)&_<%p.id%>) = <%rhs%>;<%\n%>'
    <<<%patternMatch(p.pat,rhs,onPatternFail,&varDecls,&assignments)%>
    >>
  case p as PAT_AS(ty = NONE()) then
    let &assignments += '_<%p.id%> = <%rhs%>;<%\n%>'
    <<<%patternMatch(p.pat,rhs,onPatternFail,&varDecls,&assignments)%>
    >>
  case p as PAT_AS(ty = SOME(et)) then
    let &unboxBuf = buffer ""
    let &assignments += '_<%p.id%> = <%unboxVariable(rhs, et, &unboxBuf, &varDecls)%>;<%\n%>'
    <<<%&unboxBuf%>
    <%patternMatch(p.pat,rhs,onPatternFail,&varDecls,&assignments)%>
    >>
  else 'UNKNOWN_PATTERN /* rhs: <%rhs%> */<%\n%>'
end patternMatch;

template assertCommon(Exp condition, Exp message, Context context, Text &varDecls, builtin.SourceInfo info)
::=
  let &preExpCond = buffer ""
  let &preExpMsg = buffer ""
  let condVar = daeExp(condition, context, &preExpCond, &varDecls)
  let msgVar = daeExp(message, context, &preExpMsg, &varDecls)
  <<
  <%preExpCond%>
  if (!<%condVar%>) {
    <%preExpMsg%>
    MODELICA_ASSERT(__FILE__,__LINE__,<%if acceptMetaModelicaGrammar() then 'MMC_STRINGDATA(<%msgVar%>)' else msgVar%>);
  }
  >>
end assertCommon;

template literalExpConst(Exp lit, Integer index) "These should all be declared static X const"
::=
  let name = '_OMC_LIT<%index%>'
  let tmp = '_OMC_LIT_STRUCT<%index%>'
  let meta = 'static modelica_metatype const <%name%>'

  match lit
  case SCONST(__) then
    let escstr = Util.escapeModelicaStringToCString(string)
    if acceptMetaModelicaGrammar() then
      /* TODO: Change this when OMC takes constant input arguments (so we cannot write to them)
               The cost of not doing this properly is small (<257 bytes of constants)
      match unescapedStringLength(escstr)
      case 0 then '#define <%name%> mmc_emptystring'
      case 1 then '#define <%name%> mmc_strings_len1["<%escstr%>"[0]]'
      else */
      <<
      #define <%name%>_data "<%escstr%>"
      static const size_t <%name%>_strlen = <%unescapedStringLength(escstr)%>;
      static const MMC_DEFSTRINGLIT(<%tmp%>,<%unescapedStringLength(escstr)%>,<%name%>_data);
      #define <%name%> MMC_REFSTRINGLIT(<%tmp%>)
      >>
    else
      <<
      #define <%name%>_data "<%escstr%>"
      static const size_t <%name%>_strlen = <%unescapedStringLength(string)%>;
      static const char <%name%>[<%intAdd(1,unescapedStringLength(string))%>] = <%name%>_data;
      >>
  case BOX(exp=exp as ICONST(__)) then
    <<
    <%meta%> = MMC_IMMEDIATE(MMC_TAGFIXNUM(<%exp.integer%>));
    >>
  case BOX(exp=exp as BCONST(__)) then
    <<
    <%meta%> = MMC_IMMEDIATE(MMC_TAGFIXNUM(<%if exp.bool then 1 else 0%>));
    >>
  case BOX(exp=exp as RCONST(__)) then
    /* We need to use #define's to be C-compliant. Yea, total crap :) */
    <<
    static const MMC_DEFREALLIT(<%tmp%>,<%exp.real%>);
    #define <%name%> MMC_REFREALLIT(<%tmp%>)
    >>
  case CONS(__) then
    /* We need to use #define's to be C-compliant. Yea, total crap :) */
    <<
    static const MMC_DEFSTRUCTLIT(<%tmp%>,2,1) {<%literalExpConstBoxedVal(car)%>,<%literalExpConstBoxedVal(cdr)%>}};
    #define <%name%> MMC_REFSTRUCTLIT(<%tmp%>)
    >>
  case META_TUPLE(__) then
    /* We need to use #define's to be C-compliant. Yea, total crap :) */
    <<
    static const MMC_DEFSTRUCTLIT(<%tmp%>,<%listLength(listExp)%>,0) {<%listExp |> exp => literalExpConstBoxedVal(exp); separator="_"%>}};
    #define <%name%> MMC_REFSTRUCTLIT(<%tmp%>)
    >>
  case META_OPTION(exp=SOME(exp)) then
    /* We need to use #define's to be C-compliant. Yea, total crap :) */
    <<
    static const MMC_DEFSTRUCTLIT(<%tmp%>,1,1) {<%literalExpConstBoxedVal(exp)%>}};
    #define <%name%> MMC_REFSTRUCTLIT(<%tmp%>)
    >>
  case METARECORDCALL(__) then
    /* We need to use #define's to be C-compliant. Yea, total crap :) */
    let newIndex = getValueCtor(index)
    <<
    static const MMC_DEFSTRUCTLIT(<%tmp%>,<%intAdd(1,listLength(args))%>,<%newIndex%>) {&<%underscorePath(path)%>__desc,<%args |> exp => literalExpConstBoxedVal(exp); separator="_"%>}};
    #define <%name%> MMC_REFSTRUCTLIT(<%tmp%>)
    >>
  else error(sourceInfo(), 'literalExpConst failed: <%ExpressionDumpTpl.dumpExp(lit,"\"")%>')
end literalExpConst;

template literalExpConstBoxedVal(Exp lit)
::=
  match lit
  case ICONST(__) then 'MMC_IMMEDIATE(MMC_TAGFIXNUM(<%integer%>))'
  case lit as BCONST(__) then 'MMC_IMMEDIATE(MMC_TAGFIXNUM(<%if lit.bool then 1 else 0%>))'
  case LIST(valList={}) then
    <<
    MMC_REFSTRUCTLIT(mmc_nil)
    >>
  case META_OPTION(exp=NONE()) then
    <<
    MMC_REFSTRUCTLIT(mmc_none)
    >>
  case BOX(__) then literalExpConstBoxedVal(exp)
  case lit as SHARED_LITERAL(__) then '_OMC_LIT<%lit.index%>'
  else error(sourceInfo(), 'literalExpConstBoxedVal failed: <%ExpressionDumpTpl.dumpExp(lit,"\"")%>')
end literalExpConstBoxedVal;

template error(builtin.SourceInfo srcInfo, String errMessage)
"Example source template error reporting template to be used together with the sourceInfo() magic function.
Usage: error(sourceInfo(), <<message>>) "
::=
let() = Tpl.addSourceTemplateError(errMessage, srcInfo)
<<

#error "<% Error.infoStr(srcInfo) %> <% errMessage %>"<%\n%>
>>
end error;

annotation(__OpenModelica_Interface="backend");
end CodegenSparseFMI;

// vim: filetype=susan sw=2 sts=2
