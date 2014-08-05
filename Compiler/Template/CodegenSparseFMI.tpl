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
import CodegenC.*;
import CodegenFMU.*;

template translateModel(SimCode simCode, String FMUVersion)
 "Generates C code and Makefile for compiling a FMU of a
  Modelica model."
::=
match simCode
case sc as SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
  let guid = getUUIDStr()
  let target  = simulationCodeTarget()
  let()= textFile(fmumodel_identifierFile(simCode,guid,FMUVersion), '<%fileNamePrefix%>_FMI.cpp')
  let()= textFile(CodegenFMU.fmuModelDescriptionFile(simCode,guid,FMUVersion), 'modelDescription.xml')
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
  #define FMI2_FUNCTION_PREFIX <%modelNamePrefix(simCode)%>_
  #include <fmi2TypesPlatform.h>
  #include <fmi2Functions.h>
  #define MODEL_GUID "{<%guid%>}"
  #include <cstdio>
  #include <cstring>
  #include <cassert>
  #include <string>
  #include <map>
  #include <list>
  using namespace std;

  <%ModelDefineData(modelInfo)%>

  struct FMI2_FUNCTION_PREFIX_model_data_t
  {
      fmi2Real Time;
      fmi2Real real_vars[NUMBER_OF_REALS];
      fmi2Integer int_vars[NUMBER_OF_INTEGERS];
    fmi2Boolean bool_vars[NUMBER_OF_BOOLEANS];
    std::string str_vars[NUMBER_OF_STRINGS];
    // Map from variable addresses to addresses of functions that have the variable for input
    map<void*,list<void (*)(FMI2_FUNCTION_PREFIX_model_data_t*)> > input_info;
    // Map from addresses of functions to variables they modify
    map<void (*)(FMI2_FUNCTION_PREFIX_model_data_t*),list<void*> > output_info;
  };

  // equation functions

  <%generateEquations(allEquations)%>

  <%generateEquationGraph(allEquations)%>

  <%setDefaultStartValues(modelInfo)%>

  // model exchange functions

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
  /* TODO
  <%setStartValues(modelInfo)%>
  <%eventUpdateFunction2(simCode)%>

  <%setExternalFunction2(modelInfo)%> */
  >>
end fmumodel_identifierFile;

template generateEquations(list<SimEqSystem> allEquations)
 "Generate functions for all equations in the model."
::=
  let &varDecls = buffer ""
  let &eqfuncs = buffer ""
  let fncalls = (allEquations |> eq hasindex i0 =>
                    equation_(eq, contextSimulationDiscrete, &varDecls, &eqfuncs, "")
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
      FMI2_FUNCTION_PREFIX_model_data_t* data = new FMI2_FUNCTION_PREFIX_model_data_t();
    setDefaultStartValues(data);
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
      FMI2_FUNCTION_PREFIX_model_data_t* data = static_cast<FMI2_FUNCTION_PREFIX_model_data_t*>(c);
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
  #define time (data->Time)
  <%System.tmpTickReset(0)%>
  <%vars.stateVars |> var => DefineVariables(var,"real") ;separator="\n"%>
  <%vars.derivativeVars |> var => DefineVariables(var,"real") ;separator="\n"%>
  <%vars.algVars |> var => DefineVariables(var,"real") ;separator="\n"%>
  <%vars.discreteAlgVars |> var => DefineVariables(var,"real") ;separator="\n"%>
  <%vars.paramVars |> var => DefineVariables(var,"real") ;separator="\n"%>
  <%vars.aliasVars |> var => DefineVariables(var,"real") ;separator="\n"%>
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

  // define initial state vector as vector of value references
  #define STATES { <%vars.stateVars |> SIMVAR(__) => if stringEq(crefStr(name),"$dummy") then '' else '<%cref(name)%>_'  ;separator=", "%> }
  #define STATESDERIVATIVES { <%vars.derivativeVars |> SIMVAR(__) => if stringEq(crefStr(name),"der($dummy)") then '' else '<%cref(name)%>_'  ;separator=", "%> }

  <%System.tmpTickReset(0)%>
  <%(functions |> fn => defineExternalFunction(fn) ; separator="\n")%>
  >>
end ModelDefineData;

template dervativeNameCStyle(ComponentRef cr)
 "Generates the name of a derivative in c style, replaces ( with _"
::=
  match cr
  case CREF_QUAL(ident = "$DER") then 'der_<%crefStr(componentRef)%>_'
end dervativeNameCStyle;

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
  static void setDefaultStartValues(FMI2_FUNCTION_PREFIX_model_data_t *comp)
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

template setStartValues(ModelInfo modelInfo)
 "Generates code in c file for function setStartValues() which will set start values for all variables."
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(numStateVars=numStateVars, numAlgVars= numAlgVars),vars=SIMVARS(__)) then
  <<
  // Set values for all variables that define a start value
  void setStartValues(ModelInstance *comp) {

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
  }
  >>
end setStartValues;

template initializeFunction(list<SimEqSystem> allEquations)
  "Generates initialize function for c file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let eqPart = ""/* (allEquations |> eq as SES_SIMPLE_ASSIGN(__) =>
      equation_(eq, contextOther, &varDecls)
    ;separator="\n") */
  <<
  // Used to set the first time event, if any.
  void initialize(ModelInstance* comp, fmiEventInfo* eventInfo) {

    <%varDecls%>

    <%eqPart%>
    <%allEquations |> SES_SIMPLE_ASSIGN(__) =>
      'if (sim_verbose) { printf("Setting variable start value: %s(start=%f)\n", "<%cref(cref)%>", <%cref(cref)%>); }'
    ;separator="\n"%>

  }
  >>
end initializeFunction;


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
  case ENUM_LITERAL(__) then '<%index%>'
  else "*ERROR* initial value of unknown type"
end initVal;

template eventUpdateFunction(SimCode simCode)
 "Generates event update function for c file."
::=
match simCode
case SIMCODE(__) then
  <<
  // Used to set the next time event, if any.
  void eventUpdate(ModelInstance* comp, fmiEventInfo* eventInfo) {
  }

  >>
end eventUpdateFunction;

template setExternalFunction(ModelInfo modelInfo)
 "Generates setString function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  let externalFuncs = setExternalFunctionsSwitch(functions)
  <<
  fmiStatus setExternalFunction(ModelInstance* c, const fmiValueReference vr, const void* value){
    switch (vr) {
        <%externalFuncs%>
        default:
            return fmiError;
    }
    return fmiOK;
  }

  >>
end setExternalFunction;

template eventUpdateFunction2(SimCode simCode)
 "Generates event update function for c file."
::=
match simCode
case SIMCODE(__) then
  <<
  // Used to set the next time event, if any.
  void eventUpdate(ModelInstance* comp, fmi2EventInfo* eventInfo) {
  }

  >>
end eventUpdateFunction2;

template setTime2()
::=
  <<
  fmi2Status
  fmi2SetTime(fmi2Component c, fmi2Real t)
  {
      FMI2_FUNCTION_PREFIX_model_data_t* data = static_cast<FMI2_FUNCTION_PREFIX_model_data_t*>(c);
      if (data == NULL) return fmi2Error;
    data->Time = t;
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
      FMI2_FUNCTION_PREFIX_model_data_t* data = static_cast<FMI2_FUNCTION_PREFIX_model_data_t*>(c);
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
      FMI2_FUNCTION_PREFIX_model_data_t* data = static_cast<FMI2_FUNCTION_PREFIX_model_data_t*>(c);
      if (data == NULL) return fmi2Error;
    for (size_t i = 0; i < nvr; i++)
    {
          if (vr[i] >= NUMBER_OF_REALS) return fmi2Error;
          data->real_vars[vr[i]] = value[i];
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
      FMI2_FUNCTION_PREFIX_model_data_t* data = static_cast<FMI2_FUNCTION_PREFIX_model_data_t*>(c);
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
      FMI2_FUNCTION_PREFIX_model_data_t* data = static_cast<FMI2_FUNCTION_PREFIX_model_data_t*>(c);
      if (data == NULL) return fmi2Error;
    for (size_t i = 0; i < nvr; i++)
    {
          if (vr[i] >= NUMBER_OF_INTEGERS) return fmi2Error;
          data->int_vars[vr[i]] = value[i];
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
      FMI2_FUNCTION_PREFIX_model_data_t* data = static_cast<FMI2_FUNCTION_PREFIX_model_data_t*>(c);
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
      FMI2_FUNCTION_PREFIX_model_data_t* data = static_cast<FMI2_FUNCTION_PREFIX_model_data_t*>(c);
      if (data == NULL) return fmi2Error;
    for (size_t i = 0; i < nvr; i++)
    {
          if (vr[i] >= NUMBER_OF_BOOLEANS) return fmi2Error;
          data->bool_vars[vr[i]] = value[i];
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
      FMI2_FUNCTION_PREFIX_model_data_t* data = static_cast<FMI2_FUNCTION_PREFIX_model_data_t*>(c);
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
      FMI2_FUNCTION_PREFIX_model_data_t* data = static_cast<FMI2_FUNCTION_PREFIX_model_data_t*>(c);
      if (data == NULL) return fmi2Error;
    for (size_t i = 0; i < nvr; i++)
    {
          if (vr[i] >= NUMBER_OF_STRINGS) return fmi2Error;
          data->str_vars[vr[i]] = value[i];
      }
      return fmi2OK;
  }

  >>
end setStringFunction2;

template setExternalFunction2(ModelInfo modelInfo)
 "Generates setString function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  let externalFuncs = setExternalFunctionsSwitch(functions)
  <<
  fmi2Status setExternalFunction(ModelInstance* c, const fmi2ValueReference vr, const void* value){
    switch (vr) {
        <%externalFuncs%>
        default:
            return fmi2Error;
    }
    return fmi2OK;
  }

  >>
end setExternalFunction2;

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

template SwitchVars(SimVar simVar, String arrayName, Integer offset)
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
  case <%cref(name)%>_ : return comp->fmuData->localData[0]-><%arrayName%>[<%intAdd(index,offset)%>]; break;
  >>
end SwitchVars;

template SwitchParameters(SimVar simVar, String arrayName)
 "Generates code for defining variables in c file for FMU target. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  <<
  case <%cref(name)%>_ : return comp->fmuData->simulationInfo.<%arrayName%>[<%index%>]; break;
  >>
end SwitchParameters;


template SwitchAliasVars(SimVar simVar, String arrayName, String negate)
 "Generates code for defining variables in c file for FMU target. "
::=
match simVar
  case SIMVAR(__) then
    let description = if comment then '// "<%comment%>"'
    let crefName = '<%cref(name)%>_'
      match aliasvar
        case ALIAS(__) then
        if stringEq(crefStr(varName),"time") then
        <<
        case <%crefName%> : return comp->fmuData->localData[0]->timeValue; break;
        >>
        else
        <<
        case <%crefName%> : return get<%arrayName%>(comp, <%cref(varName)%>_); break;
        >>
        case NEGATEDALIAS(__) then
        if stringEq(crefStr(varName),"time") then
        <<
        case <%crefName%> : return comp->fmuData->localData[0]->timeValue; break;
        >>
        else
        <<
        case <%crefName%> : return (<%negate%> get<%arrayName%>(comp, <%cref(varName)%>_)); break;
        >>
     end match
end SwitchAliasVars;


template SwitchVarsSet(SimVar simVar, String arrayName, Integer offset)
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
  case <%cref(name)%>_ : comp->fmuData->localData[0]-><%arrayName%>[<%intAdd(index,offset)%>]=value; break;
  >>
end SwitchVarsSet;

template SwitchParametersSet(SimVar simVar, String arrayName)
 "Generates code for defining variables in c file for FMU target. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  <<
  case <%cref(name)%>_ : comp->fmuData->simulationInfo.<%arrayName%>[<%index%>]=value; break;
  >>
end SwitchParametersSet;


template SwitchAliasVarsSet(SimVar simVar, String arrayName, String negate)
 "Generates code for defining variables in c file for FMU target. "
::=
match simVar
  case SIMVAR(__) then
    let description = if comment then '// "<%comment%>"'
    let crefName = '<%cref(name)%>_'
      match aliasvar
        case ALIAS(__) then
        if stringEq(crefStr(varName),"time") then
        <<
        >>
        else
        <<
        case <%crefName%> : return set<%arrayName%>(comp, <%cref(varName)%>_, value); break;
        >>
        case NEGATEDALIAS(__) then
        if stringEq(crefStr(varName),"time") then
        <<
        >>
        else
        <<
        case <%crefName%> : return set<%arrayName%>(comp, <%cref(varName)%>_, (<%negate%> value)); break;
        >>
     end match
end SwitchAliasVarsSet;

template equation_(SimEqSystem eq, Context context, Text &varDecls, Text &eqs, String modelNamePrefix)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently (not at all in this backed)."
::=
  match eq
  case e as SES_ALGORITHM(statements={})
  then ""
  else
  (
  let ix = equationIndex(eq) /*System.tmpTickIndex(10)*/
  let &tmp = buffer ""
  let &varD = buffer ""
  let &tempeqns = buffer ""
  let() = System.tmpTickResetIndex(0,1) /* Boxed array indices */
  let disc = match context
  case SIMULATION_CONTEXT(genDiscrete=true) then 1
  else 0
  let x = match eq
  case e as SES_SIMPLE_ASSIGN(__)
    then CodegenC.equationSimpleAssign(e, context, &varD, &tempeqns)
  case e as SES_ARRAY_CALL_ASSIGN(__)
    then CodegenC.equationArrayCallAssign(e, context, &varD, &tempeqns)
  case e as SES_IFEQUATION(__)
    then CodegenC.equationIfEquationAssign(e, context, &varD, &tempeqns, modelNamePrefix)
  case e as SES_ALGORITHM(__)
    then CodegenC.equationAlgorithm(e, context, &varD, &tempeqns)
  case e as SES_LINEAR(__)
    then CodegenC.equationLinear(e, context, &varD)
  case e as SES_NONLINEAR(__) then
    let &tempeqns += (e.eqs |> eq => 'void <%CodegenC.symbolName(modelNamePrefix,"eqFunction")%>_<%equationIndex(eq)%>(DATA*);' ; separator = "\n")
    CodegenC.equationNonlinear(e, context, &varD, modelNamePrefix)
  case e as SES_WHEN(__)
    then CodegenC.equationWhen(e, context, &varD, &tempeqns)
  case e as SES_RESIDUAL(__)
    then "NOT IMPLEMENTED EQUATION SES_RESIDUAL"
  case e as SES_MIXED(__)
    then CodegenC.equationMixed(e, context, &varD, &eqs, modelNamePrefix)
  else
    "NOT IMPLEMENTED EQUATION equation_"
  let &varD += CodegenC.addRootsTempArray()
  let &eqs +=
  <<

  <%tempeqns%>
  /*
   <%dumpEqs(fill(eq,1))%>
   */
  static void eqFunction_<%ix%>(FMI2_FUNCTION_PREFIX_model_data_t *data)
  {
      <%&varD%>
      <%x%>
  }
  >>
  <<
  <% if profileAll() then 'SIM_PROF_TICK_EQ(<%ix%>);' %>
  <%CodegenC.symbolName(modelNamePrefix,"eqFunction")%>_<%ix%>(data);
  <% if profileAll() then 'SIM_PROF_ACC_EQ(<%ix%>);' %>
  >>
  )
end equation_;

template EquationGraphHelper(DAE.Exp exp,String ix)
::=
  match exp
  case CREF(__) then
    <<
    data->input_info[&<%cref(componentRef)%>].push_back(eqFunction_<%ix%>);
    >>
  case BINARY(__) then
    <<
  <%EquationGraphHelper(exp1,ix)%>
  <%EquationGraphHelper(exp2,ix)%>
    >>
  case UNARY(__) then
    <<
  <%EquationGraphHelper(exp,ix)%>
  >>
  else "EXPRESSION NOT SUPPORTED"
end EquationGraphHelper;

template EquationGraph(SimEqSystem eq)
::=
  let ix = equationIndex(eq)
  match eq
  case e as SES_SIMPLE_ASSIGN(__)
    then
    <<
    data->output_info[eqFunction_<%ix%>].push_back(&<%cref(cref)%>);
    <%EquationGraphHelper(exp,ix)%>
    >>
  case e as SES_ARRAY_CALL_ASSIGN(__)
    then "ARRAY_CALL"
  case e as SES_IFEQUATION(__)
    then "IF EQN"
  case e as SES_ALGORITHM(__)
    then "ALG"
  case e as SES_LINEAR(__)
    then "LINEAR"
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

template generateEquationGraph(list<SimEqSystem> allEquations)
 "Generate dependency graphs for all equations and variables in the model."
::=
  let xx = (allEquations |> eq hasindex i0 => EquationGraph(eq)
      ;separator="\n")
  <<
  static void setupEquationGraph(FMI2_FUNCTION_PREFIX_model_data_t *data)
  {
      <%xx%>
  }
  >>
end generateEquationGraph;

end CodegenSparseFMI;

// vim: filetype=susan sw=2 sts=2
