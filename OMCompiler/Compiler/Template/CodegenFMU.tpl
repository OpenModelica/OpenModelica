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

package CodegenFMU

import interface SimCodeTV;
import interface SimCodeBackendTV;
import CodegenUtil.*;
import CodegenUtilSimulation.*;
import CodegenC.*; //unqualified import, no need the CodegenC is optional when calling a template; or mandatory when the same named template exists in this package (name hiding)
import CodegenCFunctions.*;
import CodegenFMUCommon.*;
import CodegenFMU1;
import CodegenFMU2;


template translateModel(SimCode simCode, String FMUVersion, String FMUType, list<String> sourceFiles)
 "Generates C code and Makefile for compiling a FMU of a
  Modelica model."
::=
match simCode
case sc as SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
  let guid = getUUIDStr()
  let target  = simulationCodeTarget()
  let fileNamePrefixTmpDir = '<%fileNamePrefix%>.fmutmp/sources/<%fileNamePrefix%>'
  let()= textFile(simulationLiteralsFile(fileNamePrefix, literals), '<%fileNamePrefixTmpDir%>_literals.h')
  let()= textFile(simulationFunctionsHeaderFile(fileNamePrefix, modelInfo.functions, recordDecls), '<%fileNamePrefixTmpDir%>_functions.h')
  let()= textFile(simulationFunctionsFile(fileNamePrefix, modelInfo.functions), '<%fileNamePrefixTmpDir%>_functions.c')
  let()= textFile(externalFunctionIncludes(sc.externalFunctionIncludes), '<%fileNamePrefixTmpDir%>_includes.h')
  let()= textFile(recordsFile(fileNamePrefix, recordDecls, true /*isSimulation*/), '<%fileNamePrefixTmpDir%>_records.c')
  let()= textFile(simulationHeaderFile(simCode), '<%fileNamePrefixTmpDir%>_model.h')

  let _ = generateSimulationFiles(simCode,guid,fileNamePrefixTmpDir,FMUVersion)

  let()= textFile(simulationInitFunction(simCode,guid), '<%fileNamePrefixTmpDir%>_init_fmu.c')
  let()= textFile(fmumodel_identifierFile(simCode,guid,FMUVersion), '<%fileNamePrefixTmpDir%>_FMU.c')

  /* Doesn't seem to work properly
  let &fmuModelDescription = buffer ""
  let &fmuModelDescription += redirectToFile('<%fileNamePrefix%>.fmutmp/modelDescription.xml')
  let &fmuModelDescription += fmuModelDescriptionFile(simCode,guid,FMUVersion,FMUType)
  let &fmuModelDescription += closeFile()
  */

  let()= textFile(fmuModelDescriptionFile(simCode, guid, FMUVersion, FMUType, sourceFiles), '<%fileNamePrefix%>.fmutmp/modelDescription.xml')

  // Generate optional <fmiPrefix>_flags.json
  let _ = match sc.fmiSimulationFlags
    case SOME(fmiSimFlags as FMI_SIMULATION_FLAGS(__)) then
      let() = textFile(fmuSimulationFlagsFile(fmiSimFlags), '<%fileNamePrefix%>.fmutmp/resources/<%fileNamePrefix%>_flags.json')
      ""
    else
      ""
    end match

  let()= textFile(fmudeffile(simCode,FMUVersion), '<%fileNamePrefix%>.fmutmp/sources/<%fileNamePrefix%>.def')
  let()= textFile('# Dummy file so OMDEV Compile.bat works<%\n%>include Makefile<%\n%>', '<%fileNamePrefix%>.fmutmp/sources/<%fileNamePrefix%>.makefile')
  let()= textFile(fmuSourceMakefile(simCode,FMUVersion), '<%fileNamePrefix%>_FMU.makefile')
  "" // Return empty result since result written to files directly
end translateModel;

/* public */ template generateSimulationFiles(SimCode simCode, String guid, String modelNamePrefix, String fmuVersion)
 "Generates code in different C files for the simulation target.
  To make the compilation faster we split the simulation files into several
  used in Compiler/Template/CodegenFMU.tpl"
 ::=
  match simCode
    case simCode as SIMCODE(__) then
     // external objects
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile_exo(simCode), '<%modelNamePrefix%>_01exo.c')
     // non-linear systems
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile_nls(simCode), '<%modelNamePrefix%>_02nls.c')
     // linear systems
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile_lsy(simCode), '<%modelNamePrefix%>_03lsy.c')
     // state set
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile_set(simCode), '<%modelNamePrefix%>_04set.c')
     // events: sample, zero crossings, relations
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile_evt(simCode), '<%modelNamePrefix%>_05evt.c')
     // initialization
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile_inz(simCode), '<%modelNamePrefix%>_06inz.c')
     // delay
     let()= textFileConvertLines(simulationFile_dly(simCode), '<%modelNamePrefix%>_07dly.c')
     // update bound start values, update bound parameters
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile_bnd(simCode), '<%modelNamePrefix%>_08bnd.c')
     // algebraic
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile_alg(simCode), '<%modelNamePrefix%>_09alg.c')
     // asserts
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile_asr(simCode), '<%modelNamePrefix%>_10asr.c')
     // mixed systems
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let &mixheader = buffer ""
     let()= textFileConvertLines(simulationFile_mix(simCode,&mixheader), '<%modelNamePrefix%>_11mix.c')
     let()= textFile(&mixheader, '<%modelNamePrefix%>_11mix.h')
     // jacobians
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile_jac(simCode), '<%modelNamePrefix%>_12jac.c')
     let()= textFile(simulationFile_jac_header(simCode), '<%modelNamePrefix%>_12jac.h')
     // optimization
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile_opt(simCode), '<%modelNamePrefix%>_13opt.c')
     let()= textFile(simulationFile_opt_header(simCode), '<%modelNamePrefix%>_13opt.h')
     // linearization
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile_lnz(simCode), '<%modelNamePrefix%>_14lnz.c')
     // synchronous
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile_syn(simCode), '<%modelNamePrefix%>_15syn.c')
     // residuals
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile_dae(simCode), '<%modelNamePrefix%>_16dae.c')
     // inline solver
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile_inl(simCode), '<%modelNamePrefix%>_17inl.c')
     // main file
     let()=tmpTickResetIndex(0, 0)
     let()=tmpTickResetIndex(0, 1)
     let()= textFileConvertLines(simulationFile(simCode,guid,fmuVersion), '<%modelNamePrefix%>.c')
     ""
  end match
end generateSimulationFiles;

template fmuModelDescriptionFile(SimCode simCode, String guid, String FMUVersion, String FMUType, list<String> sourceFiles)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <?xml version="1.0" encoding="UTF-8"?>
  <%
  if isFMIVersion20(FMUVersion) then CodegenFMU2.fmiModelDescription(simCode, guid, FMUType, sourceFiles)
  else CodegenFMU1.fmiModelDescription(simCode,guid,FMUType)
  %>
  >>
end fmuModelDescriptionFile;

template fmuSimulationFlagsFile(FmiSimulationFlags fmiSimulationFlags)
  "Generates <fmiPrefix>_flags.json file for FMUs with custom simulation flags."
 ::=
  match fmiSimulationFlags
  case flags as FMI_SIMULATION_FLAGS(__) then
  let fileContent = (flags.nameValueTuples |> (name, value) =>
      '"<%name%>" : "<%value%>"'
      ;separator=",\n")
    <<
    {
      <%fileContent%>
    }
    >>
end fmuSimulationFlagsFile;

template VendorAnnotations(SimCode simCode)
 "Generates code for VendorAnnotations file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <VendorAnnotations>
  </VendorAnnotations>
  >>
end VendorAnnotations;

template fmumodel_identifierFile(SimCode simCode, String guid, String FMUVersion)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  // define class name and unique id
  #define MODEL_IDENTIFIER <%modelNamePrefix(simCode)%>
  #define MODEL_GUID "{<%guid%>}"

  // include fmu header files, typedefs and macros
  #include <stdio.h>
  #include <string.h>
  #include <assert.h>
  #include "openmodelica.h"
  #include "openmodelica_func.h"
  #include "simulation_data.h"
  #include "util/omc_error.h"
  #include "<%fileNamePrefix%>_functions.h"
  #include "simulation/solver/initialization/initialization.h"
  #include "simulation/solver/events.h"
  <%if isFMIVersion20(FMUVersion) then
  <<
  #include "fmi-export/fmu2_model_interface.h"
  #include "fmi-export/fmu_read_flags.h"
  >>
  else
  '#include "fmi-export/fmu1_model_interface.h"'%>

  #ifdef __cplusplus
  extern "C" {
  #endif

  void setStartValues(ModelInstance *comp);
  void setDefaultStartValues(ModelInstance *comp);
  <%if isFMIVersion20(FMUVersion) then
  <<
  void eventUpdate(ModelInstance* comp, fmi2EventInfo* eventInfo);
  fmi2Real getReal(ModelInstance* comp, const fmi2ValueReference vr);
  fmi2Status setReal(ModelInstance* comp, const fmi2ValueReference vr, const fmi2Real value);
  fmi2Integer getInteger(ModelInstance* comp, const fmi2ValueReference vr);
  fmi2Status setInteger(ModelInstance* comp, const fmi2ValueReference vr, const fmi2Integer value);
  fmi2Boolean getBoolean(ModelInstance* comp, const fmi2ValueReference vr);
  fmi2Status setBoolean(ModelInstance* comp, const fmi2ValueReference vr, const fmi2Boolean value);
  fmi2String getString(ModelInstance* comp, const fmi2ValueReference vr);
  fmi2Status setString(ModelInstance* comp, const fmi2ValueReference vr, fmi2String value);
  fmi2Status setExternalFunction(ModelInstance* c, const fmi2ValueReference vr, const void* value);
  fmi2ValueReference mapInputReference2InputNumber(const fmi2ValueReference vr);
  fmi2ValueReference mapOutputReference2OutputNumber(const fmi2ValueReference vr);
  >>
  else
  <<
  void eventUpdate(ModelInstance* comp, fmiEventInfo* eventInfo);
  fmiReal getReal(ModelInstance* comp, const fmiValueReference vr);
  fmiStatus setReal(ModelInstance* comp, const fmiValueReference vr, const fmiReal value);
  fmiInteger getInteger(ModelInstance* comp, const fmiValueReference vr);
  fmiStatus setInteger(ModelInstance* comp, const fmiValueReference vr, const fmiInteger value);
  fmiBoolean getBoolean(ModelInstance* comp, const fmiValueReference vr);
  fmiStatus setBoolean(ModelInstance* comp, const fmiValueReference vr, const fmiBoolean value);
  fmiString getString(ModelInstance* comp, const fmiValueReference vr);
  fmiStatus setString(ModelInstance* comp, const fmiValueReference vr, fmiString value);
  fmiStatus setExternalFunction(ModelInstance* c, const fmiValueReference vr, const void* value);
  >>
  %>

  <%ModelDefineData(simCode, modelInfo)%>

  // implementation of the Model Exchange functions
  <%if isFMIVersion20(FMUVersion) then
    <<
    extern void <%symbolName(modelNamePrefix(simCode),"setupDataStruc")%>(DATA *data, threadData_t *threadData);
    #define fmu2_model_interface_setupDataStruc <%symbolName(modelNamePrefix(simCode),"setupDataStruc")%>
    #include "fmi-export/fmu2_model_interface.c.inc"
    #include "fmi-export/fmu_read_flags.c.inc"
    >>
  else
    <<
    extern void <%symbolName(modelNamePrefix(simCode),"setupDataStruc")%>(DATA *data, threadData_t *threadData);
    #define fmu1_model_interface_setupDataStruc <%symbolName(modelNamePrefix(simCode),"setupDataStruc")%>
    #include "fmi-export/fmu1_model_interface.c.inc"
    >>
  %>

  <%setDefaultStartValues(modelInfo)%>
  <%setStartValues(modelInfo)%>
  <%if isFMIVersion20(FMUVersion) then
  <<
  <%eventUpdateFunction2(simCode)%>
  <%getRealFunction2(simCode, modelInfo)%>
  <%setRealFunction2(simCode, modelInfo)%>
  <%getIntegerFunction2(simCode, modelInfo)%>
  <%setIntegerFunction2(simCode, modelInfo)%>
  <%getBooleanFunction2(simCode, modelInfo)%>
  <%setBooleanFunction2(simCode, modelInfo)%>
  <%getStringFunction2(simCode, modelInfo)%>
  <%setStringFunction2(simCode, modelInfo)%>
  <%setExternalFunction2(modelInfo)%>
  <%mapInputAndOutputs(simCode)%>
  >>
  else
  <<
    <%eventUpdateFunction(simCode)%>
    <%getRealFunction(simCode, modelInfo)%>
    <%setRealFunction(simCode, modelInfo)%>
    <%getIntegerFunction(simCode, modelInfo)%>
    <%setIntegerFunction(simCode, modelInfo)%>
    <%getBooleanFunction(simCode, modelInfo)%>
    <%setBooleanFunction(simCode, modelInfo)%>
    <%getStringFunction(simCode, modelInfo)%>
    <%setStringFunction(simCode, modelInfo)%>
    <%setExternalFunction(modelInfo)%>
  >>
  %>

  #ifdef __cplusplus
  }
  #endif

  >>
end fmumodel_identifierFile;

template ModelDefineData(SimCode simCode, ModelInfo modelInfo)
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

  // define initial state vector as vector of value references
  #define STATES { <%vars.stateVars |> SIMVAR(__) => if stringEq(crefStr(name),"$dummy") then '' else lookupVR(name, simCode)  ;separator=", "%> }
  #define STATESDERIVATIVES { <%vars.derivativeVars |> SIMVAR(__) => if stringEq(crefStr(name),"der($dummy)") then '' else lookupVR(name, simCode)  ;separator=", "%> }

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
  OMC_DISABLE_OPT
  void setDefaultStartValues(ModelInstance *comp) {
    <%vars.stateVars |> var => initValsDefault(var,"realVars") ;separator="\n"%>
    <%vars.derivativeVars |> var => initValsDefault(var,"realVars") ;separator="\n"%>
    <%vars.algVars |> var => initValsDefault(var,"realVars") ;separator="\n"%>
    <%vars.discreteAlgVars |> var => initValsDefault(var, "realVars") ;separator="\n"%>
    <%vars.intAlgVars |> var => initValsDefault(var,"integerVars") ;separator="\n"%>
    <%vars.boolAlgVars |> var => initValsDefault(var,"booleanVars") ;separator="\n"%>
    <%vars.stringAlgVars |> var => initValsDefault(var,"stringVars") ;separator="\n"%>
    <%vars.paramVars |> var => initParamsDefault(var,"realParameter") ;separator="\n"%>
    <%vars.intParamVars |> var => initParamsDefault(var,"integerParameter") ;separator="\n"%>
    <%vars.boolParamVars |> var => initParamsDefault(var,"booleanParameter") ;separator="\n"%>
    <%vars.stringParamVars |> var => initParamsDefault(var,"stringParameter") ;separator="\n"%>
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
  OMC_DISABLE_OPT
  void setStartValues(ModelInstance *comp) {
    <%vars.stateVars |> var => initVals(var,"realVars") ;separator="\n"%>
    <%vars.derivativeVars |> var => initVals(var,"realVars") ;separator="\n"%>
    <%vars.algVars |> var => initVals(var,"realVars") ;separator="\n"%>
    <%vars.discreteAlgVars |> var => initVals(var, "realVars") ;separator="\n"%>
    <%vars.intAlgVars |> var => initVals(var,"integerVars") ;separator="\n"%>
    <%vars.boolAlgVars |> var => initVals(var,"booleanVars") ;separator="\n"%>
    <%vars.stringAlgVars |> var => initVals(var,"stringVars") ;separator="\n"%>
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
      'if (sim_verbose) { printf("Setting variable start value: %s(start=%f)\n", "<%escapeModelicaStringToCString(crefStrNoUnderscore(cref))%>", <%cref(cref)%>); }'
    ;separator="\n"%>

  }
  >>
end initializeFunction;


template initVals(SimVar var, String arrayName) ::=
  match var
    case SIMVAR(__) then
    if stringEq(crefStr(name),"$dummy") then
      ''
    else if stringEq(crefStr(name),"der($dummy)") then
      ''
    else
    let str = 'comp->fmuData->modelData-><%arrayName%>Data[<%index%>].attribute.start'
      '<%str%> =  comp->fmuData->localData[0]-><%arrayName%>[<%index%>];'
end initVals;

template initParams(SimVar var, String arrayName) ::=
  match var
    case SIMVAR(__) then
    let str = 'comp->fmuData->modelData-><%arrayName%>Data[<%index%>].attribute.start'
      '<%str%> = comp->fmuData->simulationInfo-><%arrayName%>[<%index%>];'
end initParams;

template initValsDefault(SimVar var, String arrayName) ::=
  match var
    case SIMVAR(index=index, type_=type_) then
    let str = 'comp->fmuData->modelData-><%arrayName%>Data[<%index%>].attribute.start'
    '<%str%> = <%initValDefault(var)%>;'
end initValsDefault;

template initParamsDefault(SimVar var, String arrayName) ::=
  match var
    case SIMVAR(__) then
    let str = 'comp->fmuData->modelData-><%arrayName%>Data[<%index%>].attribute.start'
    match initialValue
      case SOME(v as SCONST(__)) then
      '<%str%> = mmc_mk_scon_persist(<%initVal(v)%>); /* TODO: these are not freed currently, see #6161 */'
      else
      '<%str%> = <%initValDefault(var)%>;'
end initParamsDefault;

template initValDefault(SimVar var) ::=
  match var
    case var as SIMVAR(__) then
    match var.initialValue
      case SOME(v as ICONST(__))
      case SOME(v as RCONST(__))
      case SOME(v as SCONST(__))
      case SOME(v as BCONST(__))
      case SOME(v as ENUM_LITERAL(__)) then initVal(v)
      else
        match var.type_
          case T_INTEGER(__)
          case T_REAL(__)
          case T_ENUMERATION(__)
          case T_BOOL(__) then '0'
          case T_STRING(__) then 'mmc_mk_scon("")'
          else error(sourceInfo(), 'Unknown type for initValDefault: <%unparseType(var.type_)%>')
end initValDefault;

template initVal(Exp initialValue)
::=
  match initialValue
  case ICONST(__) then integer
  case RCONST(__) then real
  case SCONST(__) then '"<%Util.escapeModelicaStringToXmlString(string)%>"'
  case BCONST(__) then if bool then "1" else "0"
  case ENUM_LITERAL(__) then '<%index%>'
  else error(sourceInfo(), 'initial value of unknown type: <%printExpStr(initialValue)%>')
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

template getRealFunction(SimCode simCode, ModelInfo modelInfo)
 "Generates getReal function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__),varInfo=VARINFO(numStateVars=numStateVars, numAlgVars= numAlgVars)) then
  <<
  fmiReal getReal(ModelInstance* comp, const fmiValueReference vr) {
    switch (vr) {
      <%vars.stateVars |> var => SwitchVars(simCode, var, "realVars") ;separator="\n"%>
      <%vars.derivativeVars |> var => SwitchVars(simCode, var, "realVars") ;separator="\n"%>
      <%vars.algVars |> var => SwitchVars(simCode, var, "realVars") ;separator="\n"%>
      <%vars.discreteAlgVars |> var => SwitchVars(simCode, var, "realVars") ;separator="\n"%>
      <%vars.paramVars |> var => SwitchParameters(simCode, var, "realParameter") ;separator="\n"%>
      <%vars.aliasVars |> var => SwitchAliasVars(simCode, var, "Real","-") ;separator="\n"%>
      default:
        return 0;
    }
  }

  >>
end getRealFunction;

template setRealFunction(SimCode simCode, ModelInfo modelInfo)
 "Generates setReal function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__),varInfo=VARINFO(numStateVars=numStateVars, numAlgVars= numAlgVars)) then
  <<
  fmiStatus setReal(ModelInstance* comp, const fmiValueReference vr, const fmiReal value) {
    switch (vr) {
      <%vars.stateVars |> var => SwitchVarsSet(simCode, var, "realVars") ;separator="\n"%>
      <%vars.derivativeVars |> var => SwitchVarsSet(simCode, var, "realVars") ;separator="\n"%>
      <%vars.algVars |> var => SwitchVarsSet(simCode, var, "realVars") ;separator="\n"%>
      <%vars.discreteAlgVars |> var => SwitchVarsSet(simCode, var, "realVars") ;separator="\n"%>
      <%vars.paramVars |> var => SwitchParametersSet(simCode, var, "realParameter") ;separator="\n"%>
      <%vars.aliasVars |> var => SwitchAliasVarsSet(simCode, var, "Real", "-") ;separator="\n"%>
      default:
        return fmiError;
    }
    return fmiOK;
  }

  >>
end setRealFunction;

template getIntegerFunction(SimCode simCode, ModelInfo modelInfo)
 "Generates getInteger function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmiInteger getInteger(ModelInstance* comp, const fmiValueReference vr) {
    switch (vr) {
      <%vars.intAlgVars |> var => SwitchVars(simCode, var, "integerVars") ;separator="\n"%>
      <%vars.intParamVars |> var => SwitchParameters(simCode, var, "integerParameter") ;separator="\n"%>
      <%vars.intAliasVars |> var => SwitchAliasVars(simCode, var, "Integer", "-") ;separator="\n"%>
      default:
        return 0;
    }
  }
  >>
end getIntegerFunction;

template setIntegerFunction(SimCode simCode, ModelInfo modelInfo)
 "Generates setInteger function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmiStatus setInteger(ModelInstance* comp, const fmiValueReference vr, const fmiInteger value) {
    switch (vr) {
      <%vars.intAlgVars |> var => SwitchVarsSet(simCode, var, "integerVars") ;separator="\n"%>
      <%vars.intParamVars |> var => SwitchParametersSet(simCode, var, "integerParameter") ;separator="\n"%>
      <%vars.intAliasVars |> var => SwitchAliasVarsSet(simCode, var, "Integer", "-") ;separator="\n"%>
      default:
        return fmiError;
    }
    return fmiOK;
  }
  >>
end setIntegerFunction;

template getBooleanFunction(SimCode simCode, ModelInfo modelInfo)
 "Generates getBoolean function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmiBoolean getBoolean(ModelInstance* comp, const fmiValueReference vr) {
    switch (vr) {
      <%vars.boolAlgVars |> var => SwitchVars(simCode, var, "booleanVars") ;separator="\n"%>
      <%vars.boolParamVars |> var => SwitchParameters(simCode, var, "booleanParameter") ;separator="\n"%>
      <%vars.boolAliasVars |> var => SwitchAliasVars(simCode, var, "Boolean", "!") ;separator="\n"%>
      default:
        return fmiFalse;
    }
  }

  >>
end getBooleanFunction;

template setBooleanFunction(SimCode simCode, ModelInfo modelInfo)
 "Generates setBoolean function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmiStatus setBoolean(ModelInstance* comp, const fmiValueReference vr, const fmiBoolean value) {
    switch (vr) {
      <%vars.boolAlgVars |> var => SwitchVarsSet(simCode, var, "booleanVars") ;separator="\n"%>
      <%vars.boolParamVars |> var => SwitchParametersSet(simCode, var, "booleanParameter") ;separator="\n"%>
      <%vars.boolAliasVars |> var => SwitchAliasVarsSet(simCode, var, "Boolean", "!") ;separator="\n"%>
      default:
        return fmiError;
    }
    return fmiOK;
  }

  >>
end setBooleanFunction;

template getStringFunction(SimCode simCode, ModelInfo modelInfo)
 "Generates getString function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmiString getString(ModelInstance* comp, const fmiValueReference vr) {
    switch (vr) {
      <%vars.stringAlgVars |> var => SwitchVars(simCode, var, "stringVars") ;separator="\n"%>
      <%vars.stringParamVars |> var => SwitchParameters(simCode, var, "stringParameter") ;separator="\n"%>
      <%vars.stringAliasVars |> var => SwitchAliasVars(simCode, var, "String", "") ;separator="\n"%>
      default:
        return "";
    }
  }

  >>
end getStringFunction;

template setStringFunction(SimCode simCode, ModelInfo modelInfo)
 "Generates setString function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmiStatus setString(ModelInstance* comp, const fmiValueReference vr, fmiString value) {
    switch (vr) {
      <%vars.stringAlgVars |> var => SwitchVarsSet(simCode, var, "stringVars") ;separator="\n"%>
      <%vars.stringParamVars |> var => SwitchParametersSet(simCode, var, "stringParameter") ;separator="\n"%>
      <%vars.stringAliasVars |> var => SwitchAliasVarsSet(simCode, var, "String", "") ;separator="\n"%>
      default:
        return fmiError;
    }
    return fmiOK;
  }

  >>
end setStringFunction;

template setExternalFunction(ModelInfo modelInfo)
 "Generates setExternal function for c file."
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

template getRealFunction2(SimCode simCode, ModelInfo modelInfo)
 "Generates getReal function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__),varInfo=VARINFO(numAlgAliasVars=numAlgAliasVars, numParams=numParams, numStateVars=numStateVars, numAlgVars= numAlgVars, numDiscreteReal=numDiscreteReal)) then
  let ixFirstParam = intAdd(intMul(2,numStateVars),intAdd(numAlgVars,numDiscreteReal))
  let ixFirstAlias = intAdd(numParams, intAdd(intMul(2,numStateVars),intAdd(numAlgVars,numDiscreteReal)))
  let ixEnd = intAdd(numAlgAliasVars,intAdd(numParams, intAdd(intMul(2,numStateVars),intAdd(numAlgVars,numDiscreteReal))))
  <<
  <%if numAlgAliasVars then
  <<
  static const int realAliasIndexes[<%numAlgAliasVars%>] = {
    <%vars.aliasVars |> v as SIMVAR(__) => aliasSetVR(simCode, aliasvar) ; separator=", "; align=20; alignSeparator=",\n" %>
  };

  >>
  %>
  fmi2Real getReal(ModelInstance* comp, const fmi2ValueReference vr) {
    if (vr < <%ixFirstParam%>) {
      return comp->fmuData->localData[0]->realVars[vr];
    }
    if (vr < <%ixFirstAlias%>) {
      return comp->fmuData->simulationInfo->realParameter[vr-<%ixFirstParam%>];
    }
    <%if numAlgAliasVars then
    <<
    if (vr < <%ixEnd%>) {
      int ix = realAliasIndexes[vr-<%ixFirstAlias%>];
      return ix>=0 ? getReal(comp, ix) : -getReal(comp, -(ix+1));
    }
    >>
    %>
    return NAN;
  }

  >>
end getRealFunction2;

template setRealFunction2(SimCode simCode, ModelInfo modelInfo)
 "Generates setReal function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__),varInfo=VARINFO(numAlgAliasVars=numAlgAliasVars, numParams=numParams, numStateVars=numStateVars, numAlgVars= numAlgVars, numDiscreteReal=numDiscreteReal)) then
  let ixFirstParam = intAdd(intMul(2,numStateVars),intAdd(numAlgVars,numDiscreteReal))
  let ixFirstAlias = intAdd(numParams, intAdd(intMul(2,numStateVars),intAdd(numAlgVars,numDiscreteReal)))
  let ixEnd = intAdd(numAlgAliasVars,intAdd(numParams, intAdd(intMul(2,numStateVars),intAdd(numAlgVars,numDiscreteReal))))
  <<
  fmi2Status setReal(ModelInstance* comp, const fmi2ValueReference vr, const fmi2Real value) {
    if (vr < <%ixFirstParam%>) {
      comp->fmuData->localData[0]->realVars[vr] = value;
      return fmi2OK;
    }
    if (vr < <%ixFirstAlias%>) {
      comp->fmuData->simulationInfo->realParameter[vr-<%ixFirstParam%>] = value;
      return fmi2OK;
    }
    <%if numAlgAliasVars then
    <<
    if (vr < <%ixEnd%>) {
      int ix = realAliasIndexes[vr-<%ixFirstAlias%>];
      return ix >= 0 ? setReal(comp, ix, value) : setReal(comp, -(ix+1), -value);
    }
    >>
    %>
    return fmi2Error;
  }

  >>
end setRealFunction2;

template aliasSetVR(SimCode simCode, AliasVariable v)
::=
  match v
  case NOALIAS(__) then error(sourceInfo(), "aliasSetVR expected an alias")
  case ALIAS(__) then lookupVR(varName,simCode)
  case NEGATEDALIAS(__) then intSub(-1, lookupVR(varName,simCode)) /* Subtracting 1 is necessary to make vr=0 possible to have a negative alias */
end aliasSetVR;

template getIntegerFunction2(SimCode simCode, ModelInfo modelInfo)
 "Generates setInteger function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__),varInfo=VARINFO(numIntAliasVars=numAliasVars, numIntParams=numParams, numIntAlgVars=numAlgVars)) then
  let ixFirstParam = numAlgVars
  let ixFirstAlias = intAdd(numParams, numAlgVars)
  let ixEnd = intAdd(numAliasVars,intAdd(numParams, numAlgVars))
  <<
  <% if numAliasVars then
  <<
  static const int intAliasIndexes[<%numAliasVars%>] = {
    <%vars.intAliasVars |> v as SIMVAR(__) => aliasSetVR(simCode, aliasvar) ; separator=", "; align=20; alignSeparator=",\n" %>
  };

  >>
  %>
  fmi2Integer getInteger(ModelInstance* comp, const fmi2ValueReference vr) {
    if (vr < <%ixFirstParam%>) {
      return comp->fmuData->localData[0]->integerVars[vr];
    }
    if (vr < <%ixFirstAlias%>) {
      return comp->fmuData->simulationInfo->integerParameter[vr-<%ixFirstParam%>];
    }
    <% if numAliasVars then
    <<
    if (vr < <%ixEnd%>) {
      int ix = intAliasIndexes[vr-<%ixFirstAlias%>];
      return ix>=0 ? getInteger(comp, ix) : -getInteger(comp, -(ix+1));
    }
    >>
    %>
    return 0;
  }

  >>
end getIntegerFunction2;

template setIntegerFunction2(SimCode simCode, ModelInfo modelInfo)
 "Generates getInteger function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__),varInfo=VARINFO(numIntAliasVars=numAliasVars, numIntParams=numParams, numIntAlgVars=numAlgVars)) then
  let ixFirstParam = numAlgVars
  let ixFirstAlias = intAdd(numParams, numAlgVars)
  let ixEnd = intAdd(numAliasVars,intAdd(numParams, numAlgVars))
  <<
  fmi2Status setInteger(ModelInstance* comp, const fmi2ValueReference vr, const fmi2Integer value) {
    if (vr < <%ixFirstParam%>) {
      comp->fmuData->localData[0]->integerVars[vr] = value;
      return fmi2OK;
    }
    if (vr < <%ixFirstAlias%>) {
      comp->fmuData->simulationInfo->integerParameter[vr-<%ixFirstParam%>] = value;
      return fmi2OK;
    }
    <% if numAliasVars then
    <<
    if (vr < <%ixEnd%>) {
      int ix = intAliasIndexes[vr-<%ixFirstAlias%>];
      return ix >= 0 ? setInteger(comp, ix, value) : setInteger(comp, -(ix+1), -value);
    }
    >>
    %>
    return fmi2Error;
  }
  >>
end setIntegerFunction2;

template getBooleanFunction2(SimCode simCode, ModelInfo modelInfo)
 "Generates setBoolean function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmi2Boolean getBoolean(ModelInstance* comp, const fmi2ValueReference vr) {
    switch (vr) {
      <%vars.boolAlgVars |> var => SwitchVars(simCode, var, "booleanVars") ;separator="\n"%>
      <%vars.boolParamVars |> var => SwitchParameters(simCode, var, "booleanParameter") ;separator="\n"%>
      <%vars.boolAliasVars |> var => SwitchAliasVars(simCode, var, "Boolean", "!") ;separator="\n"%>
      default:
        return fmi2False;
    }
  }

  >>
end getBooleanFunction2;

template setBooleanFunction2(SimCode simCode, ModelInfo modelInfo)
 "Generates getBoolean function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmi2Status setBoolean(ModelInstance* comp, const fmi2ValueReference vr, const fmi2Boolean value) {
    switch (vr) {
      <%vars.boolAlgVars |> var => SwitchVarsSet(simCode, var, "booleanVars") ;separator="\n"%>
      <%vars.boolParamVars |> var => SwitchParametersSet(simCode, var, "booleanParameter") ;separator="\n"%>
      <%vars.boolAliasVars |> var => SwitchAliasVarsSet(simCode, var, "Boolean", "!") ;separator="\n"%>
      default:
        return fmi2Error;
    }
    return fmi2OK;
  }

  >>
end setBooleanFunction2;

template getStringFunction2(SimCode simCode, ModelInfo modelInfo)
 "Generates getString function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmi2String getString(ModelInstance* comp, const fmi2ValueReference vr) {
    switch (vr) {
      <%vars.stringAlgVars |> var => SwitchVars(simCode, var, "stringVars") ;separator="\n"%>
      <%vars.stringParamVars |> var => SwitchParameters(simCode, var, "stringParameter") ;separator="\n"%>
      <%vars.stringAliasVars |> var => SwitchAliasVars(simCode, var, "String", "") ;separator="\n"%>
      default:
        return "";
    }
  }

  >>
end getStringFunction2;

template setStringFunction2(SimCode simCode, ModelInfo modelInfo)
 "Generates setString function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmi2Status setString(ModelInstance* comp, const fmi2ValueReference vr, fmi2String value) {
    switch (vr) {
      <%vars.stringAlgVars |> var => SwitchVarsSet(simCode, var, "stringVars") ;separator="\n"%>
      <%vars.stringParamVars |> var => SwitchParametersSet(simCode, var, "stringParameter") ;separator="\n"%>
      <%vars.stringAliasVars |> var => SwitchAliasVarsSet(simCode, var, "String", "") ;separator="\n"%>
      default:
        return fmi2Error;
    }
    return fmi2OK;
  }

  >>
end setStringFunction2;

template setExternalFunction2(ModelInfo modelInfo)
 "Generates setExternal function for c file."
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

template SwitchVars(SimCode simCode, SimVar simVar, String arrayName)
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
  if stringEq(arrayName, "stringVars")
  then
  <<
  case <%lookupVR(name,simCode)%> : return MMC_STRINGDATA(comp->fmuData->localData[0]-><%arrayName%>[<%index%>]); break;
  >>
  else
  <<
  case <%lookupVR(name,simCode)%> : return comp->fmuData->localData[0]-><%arrayName%>[<%index%>]; break;
  >>
end SwitchVars;

template SwitchParameters(SimCode simCode, SimVar simVar, String arrayName)
 "Generates code for defining variables in c file for FMU target. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  if stringEq(arrayName,  "stringParameter")
  then
  <<
  case <%lookupVR(name,simCode)%> : return MMC_STRINGDATA(comp->fmuData->simulationInfo-><%arrayName%>[<%index%>]); break;
  >>
  else
  <<
  case <%lookupVR(name,simCode)%> : return comp->fmuData->simulationInfo-><%arrayName%>[<%index%>]; break;
  >>
end SwitchParameters;


template SwitchAliasVars(SimCode simCode, SimVar simVar, String arrayName, String negate)
 "Generates code for defining variables in c file for FMU target. "
::=
match simVar
  case SIMVAR(__) then
    let description = if comment then '// "<%comment%>"'
    let crefName = lookupVR(name,simCode)
      match aliasvar
        case ALIAS(__) then
        if stringEq(crefStr(varName),"time") then
        <<
        case <%crefName%> : return comp->fmuData->localData[0]->timeValue; break;
        >>
        else
        <<
        case <%crefName%> : return get<%arrayName%>(comp, <%lookupVR(varName,simCode)%>); break;
        >>
        case NEGATEDALIAS(__) then
        if stringEq(crefStr(varName),"time") then
        <<
        case <%crefName%> : return comp->fmuData->localData[0]->timeValue; break;
        >>
        else
        <<
        case <%crefName%> : return (<%negate%> get<%arrayName%>(comp, <%lookupVR(varName,simCode)%>)); break;
        >>
     end match
end SwitchAliasVars;


template SwitchVarsSet(SimCode simCode, SimVar simVar, String arrayName)
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
  if stringEq(arrayName, "stringVars")
  then
  <<
  case <%lookupVR(name,simCode)%> : comp->fmuData->localData[0]-><%arrayName%>[<%index%>] = mmc_mk_scon(value); break;
  >>
  else
  <<
  case <%lookupVR(name,simCode)%> : comp->fmuData->localData[0]-><%arrayName%>[<%index%>] = value; break;
  >>
end SwitchVarsSet;

template SwitchParametersSet(SimCode simCode, SimVar simVar, String arrayName)
 "Generates code for defining variables in c file for FMU target. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  if stringEq(arrayName, "stringParameter")
  then
  <<
  case <%lookupVR(name,simCode)%> : comp->fmuData->simulationInfo-><%arrayName%>[<%index%>] = mmc_mk_scon(value); break;
  >>
  else
  <<
  case <%lookupVR(name,simCode)%> : comp->fmuData->simulationInfo-><%arrayName%>[<%index%>] = value; break;
  >>
end SwitchParametersSet;


template SwitchAliasVarsSet(SimCode simCode, SimVar simVar, String arrayName, String negate)
 "Generates code for defining variables in c file for FMU target. "
::=
match simVar
  case SIMVAR(__) then
    let description = if comment then '// "<%comment%>"'
    let crefName = lookupVR(name,simCode)
      match aliasvar
        case ALIAS(__) then
        if stringEq(crefStr(varName),"time") then
        <<
        >>
        else
        <<
        case <%crefName%> : return set<%arrayName%>(comp, <%lookupVR(varName,simCode)%>, value); break;
        >>
        case NEGATEDALIAS(__) then
        if stringEq(crefStr(varName),"time") then
        <<
        >>
        else
        <<
        case <%crefName%> : return set<%arrayName%>(comp, <%lookupVR(varName,simCode)%>, (<%negate%> value)); break;
        >>
     end match
end SwitchAliasVarsSet;

template mapInputAndOutputs(SimCode simCode)
""
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(vars=SIMVARS(inputVars=inputVars, outputVars=outputVars))) then
    <<
    /* function maps input references to a input index used in partialDerivatives */
    fmi2ValueReference mapInputReference2InputNumber(const fmi2ValueReference vr) {
        switch (vr) {
          <%inputVars |> var hasindex index0 =>  match var case SIMVAR(name=name, type_=T_REAL()) then
          'case <%lookupVR(name, simCode)%>: return <%index0%>; break;' ;separator="\n"%>
          default:
            return -1;
        }
    }
    /* function maps output references to a input index used in partialDerivatives */
    fmi2ValueReference mapOutputReference2OutputNumber(const fmi2ValueReference vr) {
        switch (vr) {
          <%outputVars |> var hasindex index0 =>  match var case SIMVAR(name=name, type_=T_REAL()) then
          'case <%lookupVR(name, simCode)%>: return <%index0%>; break;' ;separator="\n"%>
          default:
            return -1;
        }
    }
    >>
end match
end mapInputAndOutputs;


template getPlatformString2(String modelNamePrefix, String platform, String fileNamePrefix, String fmuTargetName, String dirExtra, String libsPos1, String libsPos2, String omhome, String FMUVersion)
 "returns compilation commands for the platform. "
::=
let fmudirname = '<%fileNamePrefix%>.fmutmp'
match platform
  case "win32"
  case "win64" then
  <<
  <%fileNamePrefix%>_FMU: nozip
  <%\t%>cd .. && rm -f ../<%fileNamePrefix%>.fmu && zip -r ../<%fmuTargetName%>.fmu *
  nozip: <%fileNamePrefix%>_functions.h <%fileNamePrefix%>_literals.h $(OFILES) $(RUNTIMEFILES) $(FMISUNDIALSFILES)
  <%\t%>$(CXX) -shared -I. -o <%modelNamePrefix%>$(DLLEXT) $(RUNTIMEFILES) $(FMISUNDIALSFILES) $(OFILES) $(CPPFLAGS) <%dirExtra%> <%libsPos1%> <%libsPos2%> $(CFLAGS) $(LDFLAGS) -llis -Wl,--kill-at
  <%\t%>mkdir.exe -p ../binaries/<%platform%>
  <%\t%>dlltool -d <%fileNamePrefix%>.def --dllname <%fileNamePrefix%>$(DLLEXT) --output-lib <%fileNamePrefix%>.lib --kill-at
  <%\t%>cp <%fileNamePrefix%>$(DLLEXT) <%fileNamePrefix%>.lib <%fileNamePrefix%>_FMU.libs ../binaries/<%platform%>/
  <%\t%>rm -f *.o <%fileNamePrefix%>$(DLLEXT) $(OFILES) $(RUNTIMEFILES) $(FMISUNDIALSFILES)
  <%\t%>cd .. && rm -f ../<%fileNamePrefix%>.fmu && zip -r ../<%fmuTargetName%>.fmu *

  >>
  else
  <<
  <%fileNamePrefix%>_FMU: nozip
  <%\t%>cd .. && rm -f ../<%fileNamePrefix%>.fmu && zip -r ../<%fmuTargetName%>.fmu *
  nozip: <%fileNamePrefix%>_functions.h <%fileNamePrefix%>_literals.h $(OFILES) $(RUNTIMEFILES) $(FMISUNDIALSFILES)
  <%\t%>mkdir -p ../binaries/$(FMIPLATFORM)
  ifeq (@LIBTYPE_DYNAMIC@,1)
  <%\t%>$(LD) -o <%modelNamePrefix%>$(DLLEXT) $(OFILES) $(RUNTIMEFILES) $(FMISUNDIALSFILES) <%dirExtra%> <%libsPos1%> @BSTATIC@ <%libsPos2%> @BDYNAMIC@ $(LDFLAGS)
  <%\t%>cp <%fileNamePrefix%>$(DLLEXT) <%fileNamePrefix%>_FMU.libs ../binaries/$(FMIPLATFORM)/
  endif
  <%if intLt(Flags.getConfigEnum(Flags.FMI_FILTER), 4) then
  '<%\t%>head -n20 Makefile > ../resources/$(FMIPLATFORM).summary'
   %>
  ifeq (@LIBTYPE_STATIC@,1)
  <%\t%>rm -f <%modelNamePrefix%>.a
  <%\t%>$(AR) -rsu <%modelNamePrefix%>.a $(OFILES) $(RUNTIMEFILES) $(FMISUNDIALSFILES)
  <%\t%>cp <%fileNamePrefix%>.a <%fileNamePrefix%>_FMU.libs ../binaries/$(FMIPLATFORM)/
  endif
  <% if not Flags.isSet(Flags.GEN_DEBUG_SYMBOLS) then "\t$(MAKE) distclean" %>
  distclean: clean
  <%\t%>rm -f Makefile config.status config.log
  clean:
  <%\t%>rm -f <%fileNamePrefix%>.def <%fileNamePrefix%>.o <%fileNamePrefix%>.a <%fileNamePrefix%>$(DLLEXT) $(MAINOBJ) $(OFILES) $(RUNTIMEFILES) $(FMISUNDIALSFILES)
  >>
end getPlatformString2;

template settingsfile(SimCode simCode)
"Generates content of omc_simulation_settings.h"
::=
  match simCode
  case SIMCODE(modelInfo=MODELINFO(varInfo=varInfo as VARINFO(__)), delayedExps=DELAYED_EXPRESSIONS(maxDelayedIndex=maxDelayedIndex), fmiSimulationFlags=fmiSimulationFlags) then
  <<
  #if !defined(OMC_SIM_SETTINGS_CMDLINE)
  #define OMC_SIM_SETTINGS_CMDLINE
  #define OMC_NUM_LINEAR_SYSTEMS <%varInfo.numLinearSystems%>
  #define OMC_NUM_NONLINEAR_SYSTEMS <%varInfo.numNonLinearSystems%>
  #define OMC_NUM_MIXED_SYSTEMS <%varInfo.numMixedSystems%>
  #define OMC_NDELAY_EXPRESSIONS <%maxDelayedIndex%>
  #define OMC_NVAR_STRING <%varInfo.numStringAlgVars%>
  <% if Flags.isSet(Flags.FMU_EXPERIMENTAL) then '#define FMU_EXPERIMENTAL 1'%>
  #define OMC_MODEL_PREFIX "<%modelNamePrefix(simCode)%>"
  #define OMC_MINIMAL_RUNTIME 1
  #define OMC_FMI_RUNTIME 1
  <%if isSome(fmiSimulationFlags) then "#define WITH_SUNDIALS 1"%>
  #endif
 >>
end settingsfile;

template fmuMakefile(String target, SimCode simCode, String FMUVersion, list<String> sourceFiles, list<String> runtimeObjectFiles, list<String> dgesvObjectFiles, list <String> sundialsObjectFiles)
 "Generates the contents of the makefile for the simulation case. Copy libexpat & correct linux fmu"
::=
  let common =
    match simCode
    case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
    <<
    CFILES = <%sourceFiles ; separator=" \\\n         "%>
    OFILES=$(CFILES:.c=.o)

    RUNTIMEDIR=.
    ifneq ($(NEED_DGESV),)
    DGESV_OBJS = <%dgesvObjectFiles ; separator = " "%>
    endif
    ifneq ($(NEED_RUNTIME),)
    RUNTIMEFILES=<%runtimeObjectFiles ; separator = " "%> $(DGESV_OBJS)
    endif
    ifneq ($(NEED_SUNDIALS),)
    FMISUNDIALSFILES=<%sundialsObjectFiles ; separator = " "%>
    LDFLAGS+=-lsundials_cvode -lsundials_nvecserial
    endif
    >>

  match getGeneralTarget(target)
  case "msvc" then
    match simCode
    case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
      let dirExtra = if modelInfo.directory then '/LIBPATH:"<%modelInfo.directory%>"' //else ""
      let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
      let libsPos1 = if not dirExtra then libsStr //else ""
      let libsPos2 = if dirExtra then libsStr // else ""
      let fmudirname = '<%fileNamePrefix%>.fmutmp'
      let compilecmds = getPlatformString2(modelNamePrefix(simCode), makefileParams.platform, fileNamePrefix, fmuTargetName, dirExtra, libsPos1, libsPos2, makefileParams.omhome, FMUVersion)
      let mkdir = match makefileParams.platform case "win32" case "win64" then '"mkdir.exe"' else 'mkdir'
      <<
      # Makefile generated by OpenModelica

      # Simulations use -O3 by default
      SIM_OR_DYNLOAD_OPT_LEVEL=
      MODELICAUSERCFLAGS=
      CXX=cl
      EXEEXT=.exe
      DLLEXT=.dll
      FMUEXT=.fmu
      PLATWIN32 = win32

      # /Od - Optimization disabled
      # /EHa enable C++ EH (w/ SEH exceptions)
      # /fp:except - consider floating-point exceptions when generating code
      # /arch:SSE2 - enable use of instructions available with SSE2 enabled CPUs
      # /I - Include Directories
      # /DNOMINMAX - Define NOMINMAX (does what it says)
      # /TP - Use C++ Compiler
      CFLAGS=/MP /Od /ZI /EHa /fp:except /I"<%makefileParams.omhome%>/include/omc/c" /I"<%makefileParams.omhome%>/include/omc/msvc/" <%if isFMIVersion20(FMUVersion) then '/I"<%makefileParams.omhome%>/include/omc/c/fmi2"' else '/I"<%makefileParams.omhome%>/include/omc/c/fmi1"'%> /I. /DNOMINMAX /TP /DNO_INTERACTIVE_DEPENDENCY  <% if Flags.isSet(Flags.FMU_EXPERIMENTAL) then '/DFMU_EXPERIMENTAL'%>

      # /ZI enable Edit and Continue debug info
      CDFLAGS=/ZI

      # /MD - link with MSVCRT.LIB
      # /link - [linker options and libraries]
      # /LIBPATH: - Directories where libs can be found
      LDFLAGS=/MD /link /dll /debug /pdb:"<%fileNamePrefix%>.pdb" /LIBPATH:"<%makefileParams.omhome%>/lib/<%Autoconf.triple%>/omc/msvc/" /LIBPATH:"<%makefileParams.omhome%>/lib/<%Autoconf.triple%>/omc/msvc/release/" <%dirExtra%> <%libsPos1%> <%libsPos2%> f2c.lib initialization.lib libexpat.lib math-support.lib meta.lib results.lib simulation.lib solver.lib sundials_kinsol.lib sundials_nvecserial.lib util.lib lapack_win32_MT.lib lis.lib  omcgc.lib user32.lib pthreadVC2.lib wsock32.lib cminpack.lib umfpack.lib amd.lib

      # /MDd link with MSVCRTD.LIB debug lib
      # lib names should not be appended with a d just switch to lib/omc/msvc/debug


      <%common%>

      <%fileNamePrefix%>$(FMUEXT): <%fileNamePrefix%>$(DLLEXT) modelDescription.xml
          if not exist <%fmudirname%>\binaries\$(PLATWIN32) <%mkdir%> <%fmudirname%>\binaries\$(PLATWIN32)
          if not exist <%fmudirname%>\sources <%mkdir%> <%fmudirname%>\sources

          copy <%fileNamePrefix%>.dll <%fmudirname%>\binaries\$(PLATWIN32)
          copy <%fileNamePrefix%>.lib <%fmudirname%>\binaries\$(PLATWIN32)
          copy <%fileNamePrefix%>.pdb <%fmudirname%>\binaries\$(PLATWIN32)
          copy <%fileNamePrefix%>.c <%fmudirname%>\sources\<%fileNamePrefix%>.c
          copy <%fileNamePrefix%>_model.h <%fmudirname%>\sources\<%fileNamePrefix%>_model.h
          copy <%fileNamePrefix%>_FMU.c <%fmudirname%>\sources\<%fileNamePrefix%>_FMU.c
          copy <%fileNamePrefix%>_info.c <%fmudirname%>\sources\<%fileNamePrefix%>_info.c
          copy <%fileNamePrefix%>_init_fmu.c <%fmudirname%>\sources\<%fileNamePrefix%>_init_fmu.c
          copy <%fileNamePrefix%>_functions.c <%fmudirname%>\sources\<%fileNamePrefix%>_functions.c
          copy <%fileNamePrefix%>_functions.h <%fmudirname%>\sources\<%fileNamePrefix%>_functions.h
          copy <%fileNamePrefix%>_records.c <%fmudirname%>\sources\<%fileNamePrefix%>_records.c
          copy modelDescription.xml <%fmudirname%>\modelDescription.xml
          copy <%stringReplace(makefileParams.omhome,"/","\\")%>\bin\SUNDIALS_CVODE.DLL <%fmudirname%>\binaries\$(PLATWIN32)
          copy <%stringReplace(makefileParams.omhome,"/","\\")%>\bin\SUNDIALS_KINSOL.DLL <%fmudirname%>\binaries\$(PLATWIN32)
          copy <%stringReplace(makefileParams.omhome,"/","\\")%>\bin\SUNDIALS_NVECSERIAL.DLL <%fmudirname%>\binaries\$(PLATWIN32)
          copy <%stringReplace(makefileParams.omhome,"/","\\")%>\bin\LAPACK_WIN32_MT.DLL <%fmudirname%>\binaries\$(PLATWIN32)
          copy <%stringReplace(makefileParams.omhome,"/","\\")%>\bin\pthreadVC2.dll <%fmudirname%>\binaries\$(PLATWIN32)
          cd <%fmudirname%>
          "zip.exe" -r ../<%fmuTargetName%>.fmu *
          cd ..
          rm -rf <%fmudirname%>

      <%fileNamePrefix%>$(DLLEXT): $(MAINOBJ) $(CFILES)
          $(CXX) /Fe<%fileNamePrefix%>$(DLLEXT) <%fileNamePrefix%>_FMU.c <%fileNamePrefix%>_FMU.c $(CFILES) $(CFLAGS) $(LDFLAGS)
      >>
    end match
  case "gcc" then
    match simCode
    case SIMCODE(modelInfo=MODELINFO(varInfo=varInfo as VARINFO(__)), delayedExps=DELAYED_EXPRESSIONS(maxDelayedIndex=maxDelayedIndex), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt, fmiSimulationFlags = fmiSimulationFlags) then
      let dirExtra = if modelInfo.directory then '-L"<%modelInfo.directory%>"' //else ""
      let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
      let libsPos1 = if not dirExtra then libsStr //else ""
      let libsPos2 = if dirExtra then libsStr // else ""
      let compilecmds = getPlatformString2(modelNamePrefix(simCode), makefileParams.platform, fileNamePrefix, fmuTargetName, dirExtra, libsPos1, libsPos2, makefileParams.omhome, FMUVersion)
      let platformstr = makefileParams.platform
      let thirdPartyInclude = match fmiSimulationFlags case SOME(__) then "-Isundials/ -I/util" else ""
      <<
      # Makefile generated by OpenModelica
      CC=@CC@
      AR=@AR@
      CFLAGS=@CFLAGS@
      LD=$(CC) -shared
      LDFLAGS=@LDFLAGS@ @LIBS@
      DLLEXT=@DLLEXT@
      NEED_RUNTIME=@NEED_RUNTIME@
      NEED_DGESV=@NEED_DGESV@
      NEED_SUNDIALS=@NEED_SUNDIALS@
      FMIPLATFORM=@FMIPLATFORM@
      # Note: Simulation of the fmu with dymola does not work with -finline-small-functions (enabled by most optimization levels)
      CPPFLAGS=@CPPFLAGS@

      override CPPFLAGS += <%makefileParams.includes ; separator=" "%>

      <%common%>

      PHONY: <%fileNamePrefix%>_FMU
      <%compilecmds%>
      >>
    end match
  else
    error(sourceInfo(), 'target <%target%> is not handled!')
end fmuMakefile;


template fmuSourceMakefile(SimCode simCode, String FMUVersion)
 "Generates the contents of the makefile for the simulation case. Copy libexpat & correct linux fmu"
::=
  match simCode
  case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
  let includedir = '<%fileNamePrefix%>.fmutmp/sources/'
  let mkdir = match makefileParams.platform case "win32" case "win64" then '"mkdir.exe"' else 'mkdir'
  <<
  # FIXME: before you push into master...
  RUNTIMEDIR=<%makefileParams.omhome%>/include/omc/c/
  #COPY_RUNTIMEFILES=$(FMI_ME_OBJS:%= && (OMCFILE=% && cp $(RUNTIMEDIR)/$$OMCFILE.c $$OMCFILE.c))

  fmu:
  <%\t%>rm -f <%fileNamePrefix%>.fmutmp/sources/<%fileNamePrefix%>_init.xml<%/*Already translated to .c*/%>
  <%\t%>cp -a "<%makefileParams.omhome%>/share/omc/runtime/c/fmi/buildproject/"* <%fileNamePrefix%>.fmutmp/sources
  <%\t%>cp -a <%fileNamePrefix%>_FMU.libs <%fileNamePrefix%>.fmutmp/sources/
  <%if boolNot(boolOr(stringEq(makefileParams.platform, "win32"),stringEq(makefileParams.platform, "win64"))) then
     match  Config.simCodeTarget()
     case "omsicpp" then
     <<
     <%\t%>chmod +x <%fileNamePrefix%>.sh
     >>
     end match
  %>
  <%\n%>
  >>
end fmuSourceMakefile;

template fmudeffile(SimCode simCode, String FMUVersion)
 "Generates the def file of the fmu."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
  if isFMIVersion20(FMUVersion) then
  <<
  EXPORTS
    ;***************************************************
    ;Common Functions
    ;****************************************************
    <%fileNamePrefix%>_fmiGetTypesPlatform @1
    <%fileNamePrefix%>_fmiGetVersion @2
    <%fileNamePrefix%>_fmiSetDebugLogging @3
    <%fileNamePrefix%>_fmiInstantiate @4
    <%fileNamePrefix%>_fmiFreeInstance @5
    <%fileNamePrefix%>_fmiSetupExperiment @6
    <%fileNamePrefix%>_fmiEnterInitializationMode @7
    <%fileNamePrefix%>_fmiExitInitializationMode @8
    <%fileNamePrefix%>_fmiTerminate @9
    <%fileNamePrefix%>_fmiReset @10
    <%fileNamePrefix%>_fmiGetReal @11
    <%fileNamePrefix%>_fmiGetInteger @12
    <%fileNamePrefix%>_fmiGetBoolean @13
    <%fileNamePrefix%>_fmiGetString @14
    <%fileNamePrefix%>_fmiSetReal @15
    <%fileNamePrefix%>_fmiSetInteger @16
    <%fileNamePrefix%>_fmiSetBoolean @17
    <%fileNamePrefix%>_fmiSetString @18
    <%fileNamePrefix%>_fmiGetFMUstate @19
    <%fileNamePrefix%>_fmiSetFMUstate @20
    <%fileNamePrefix%>_fmiFreeFMUstate @21
    <%fileNamePrefix%>_fmiSerializedFMUstateSize @22
    <%fileNamePrefix%>_fmiSerializeFMUstate @23
    <%fileNamePrefix%>_fmiDeSerializeFMUstate @24
    <%fileNamePrefix%>_fmiGetDirectionalDerivative @25
    ;***************************************************
    ;Functions for FMI for Model Exchange
    ;****************************************************
    <%fileNamePrefix%>_fmiEnterEventMode @26
    <%fileNamePrefix%>_fmiNewDiscreteStates @27
    <%fileNamePrefix%>_fmiEnterContinuousTimeMode @28
    <%fileNamePrefix%>_fmiCompletedIntegratorStep @29
    <%fileNamePrefix%>_fmiSetTime @30
    <%fileNamePrefix%>_fmiSetContinuousStates @31
    <%fileNamePrefix%>_fmiGetDerivatives @32
    <%fileNamePrefix%>_fmiGetEventIndicators @33
    <%fileNamePrefix%>_fmiGetContinuousStates @34
    <%fileNamePrefix%>_fmiGetNominalsOfContinuousStates @35
    ;***************************************************
    ;Functions for FMI for Co-Simulation
    ;****************************************************
    <%fileNamePrefix%>_fmiSetRealInputDerivatives @36
    <%fileNamePrefix%>_fmiGetRealOutputDerivatives @37
    <%fileNamePrefix%>_fmiDoStep @38
    <%fileNamePrefix%>_fmiCancelStep @39
    <%fileNamePrefix%>_fmiGetStatus @40
    <%fileNamePrefix%>_fmiGetRealStatus @41
    <%fileNamePrefix%>_fmiGetIntegerStatus @42
    <%fileNamePrefix%>_fmiGetBooleanStatus @43
    <%fileNamePrefix%>_fmiGetStringStatus @44
    <% if Flags.isSet(Flags.FMU_EXPERIMENTAL) then
    <<
    ;***************************************************
    ; Experimetnal function for FMI for ModelExchange
    ;****************************************************
    <%fileNamePrefix%>_fmiGetSpecificDerivatives @45
    >> %>
  >>
  else
  <<
  EXPORTS
    <%fileNamePrefix%>_fmiCompletedIntegratorStep @1
    <%fileNamePrefix%>_fmiEventUpdate @2
    <%fileNamePrefix%>_fmiFreeModelInstance @3
    <%fileNamePrefix%>_fmiGetBoolean @4
    <%fileNamePrefix%>_fmiGetContinuousStates @5
    <%fileNamePrefix%>_fmiGetDerivatives @6
    <%fileNamePrefix%>_fmiGetEventIndicators @7
    <%fileNamePrefix%>_fmiGetInteger @8
    <%fileNamePrefix%>_fmiGetModelTypesPlatform @9
    <%fileNamePrefix%>_fmiGetNominalContinuousStates @10
    <%fileNamePrefix%>_fmiGetReal @11
    <%fileNamePrefix%>_fmiGetStateValueReferences @12
    <%fileNamePrefix%>_fmiGetString @13
    <%fileNamePrefix%>_fmiGetVersion @14
    <%fileNamePrefix%>_fmiInitialize @15
    <%fileNamePrefix%>_fmiInstantiateModel @16
    <%fileNamePrefix%>_fmiSetBoolean @17
    <%fileNamePrefix%>_fmiSetContinuousStates @18
    <%fileNamePrefix%>_fmiSetDebugLogging @19
    <%fileNamePrefix%>_fmiSetExternalFunction @20
    <%fileNamePrefix%>_fmiSetInteger @21
    <%fileNamePrefix%>_fmiSetReal @22
    <%fileNamePrefix%>_fmiSetString @23
    <%fileNamePrefix%>_fmiSetTime @24
    <%fileNamePrefix%>_fmiTerminate @25
  >>
end fmudeffile;

template importFMUModelDescription(FmiImport fmi)
 "Generates Modelica code for FMU model description"
::=
match fmi
case FMIIMPORT(fmiInfo=INFO(__),fmiExperimentAnnotation=EXPERIMENTANNOTATION(__)) then
  <<
  model <%fmiInfo.fmiModelIdentifier%>_Input_Output_FMU<%if stringEq(fmiInfo.fmiDescription, "") then "" else " \""+fmiInfo.fmiDescription+"\""%>
    <%dumpFMITypeDefinitions(fmiTypeDefinitionsList)%>
    <%dumpFMUModelDescriptionVariablesList("1.0", fmiModelVariablesList, fmiTypeDefinitionsList, generateInputConnectors, generateOutputConnectors)%>
  end <%fmiInfo.fmiModelIdentifier%>_Input_Output_FMU;
  >>
end importFMUModelDescription;

template dumpFMUModelDescriptionVariablesList(String FMUVersion, list<ModelVariables> fmiModelVariablesList, list<TypeDefinitions> fmiTypeDefinitionsList, Boolean generateInputConnectors, Boolean generateOutputConnectors)
 "Generates the Model Variables code."
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpFMUModelDescriptionVariable(FMUVersion, fmiModelVariable, fmiTypeDefinitionsList, generateInputConnectors, generateOutputConnectors) ;separator="\n"%>
  >>
end dumpFMUModelDescriptionVariablesList;

template dumpFMUModelDescriptionVariable(String FMUVersion, ModelVariables fmiModelVariable, list<TypeDefinitions> fmiTypeDefinitionsList, Boolean generateInputConnectors, Boolean generateOutputConnectors)
::=
match FMUVersion
case "1.0" then
  match fmiModelVariable
  case REALVARIABLE(__) then
    let isInputOrOutput = if boolOr(stringEq(causality, "input"), stringEq(causality, "output")) then true
    if isInputOrOutput then
    <<
    <%dumpFMUModelDescriptionInputOutputVariable(name, causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
    >>
  case INTEGERVARIABLE(__) then
    let isInputOrOutput = if boolOr(stringEq(causality, "input"), stringEq(causality, "output")) then true
    if isInputOrOutput then
    <<
    <%dumpFMUModelDescriptionInputOutputVariable(name, causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
    >>
  case BOOLEANVARIABLE(__) then
    let isInputOrOutput = if boolOr(stringEq(causality, "input"), stringEq(causality, "output")) then true
    if isInputOrOutput then
    <<
    <%dumpFMUModelDescriptionInputOutputVariable(name, causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
    >>
  case STRINGVARIABLE(__) then
    let isInputOrOutput = if boolOr(stringEq(causality, "input"), stringEq(causality, "output")) then true
    if isInputOrOutput then
    <<
    <%dumpFMUModelDescriptionInputOutputVariable(name, causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
    >>
  case ENUMERATIONVARIABLE(__) then
    let isInputOrOutput = if boolOr(stringEq(causality, "input"), stringEq(causality, "output")) then true
    if isInputOrOutput then
    <<
    <%dumpFMUModelDescriptionInputOutputVariable(name, causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
    >>
  end match
end dumpFMUModelDescriptionVariable;

template dumpFMUModelDescriptionInputOutputVariable(String name, String causality, String baseType, Boolean generateInputConnectors, Boolean generateOutputConnectors)
::=
  if boolAnd(generateInputConnectors, boolAnd(stringEq(causality, "input"),stringEq(baseType, "Real"))) then "Modelica.Blocks.Interfaces.RealInput "+name+""
  else if boolAnd(generateInputConnectors, boolAnd(stringEq(causality, "input"),stringEq(baseType, "Integer"))) then "Modelica.Blocks.Interfaces.IntegerInput "+name+""
  else if boolAnd(generateInputConnectors, boolAnd(stringEq(causality, "input"),stringEq(baseType, "Boolean"))) then "Modelica.Blocks.Interfaces.BooleanInput "+name+""
  else if boolAnd(generateOutputConnectors, boolAnd(stringEq(causality, "output"),stringEq(baseType, "Real"))) then "Modelica.Blocks.Interfaces.RealOutput "+name+""
  else if boolAnd(generateOutputConnectors, boolAnd(stringEq(causality, "output"),stringEq(baseType, "Integer"))) then "Modelica.Blocks.Interfaces.IntegerOutput "+name+""
  else if boolAnd(generateOutputConnectors, boolAnd(stringEq(causality, "output"),stringEq(baseType, "Boolean"))) then "Modelica.Blocks.Interfaces.BooleanOutput "+name+""
end dumpFMUModelDescriptionInputOutputVariable;

template importFMUModelica(FmiImport fmi)
 "Generates the Modelica code depending on the FMU type."
::=
match fmi
case FMIIMPORT(__) then
  match fmiInfo
    case (INFO(fmiVersion = "1.0", fmiType = 0)) then
      importFMU1ModelExchange(fmi)
    case (INFO(fmiVersion = "1.0", fmiType = 1)) then
      importFMU1CoSimulationStandAlone(fmi)
    case (INFO(fmiVersion = "2.0", fmiType = 1)) then
      importFMU2ModelExchange(fmi)
end importFMUModelica;

template importFMU1ModelExchange(FmiImport fmi)
 "Generates Modelica code for FMI Model Exchange version 1.0"
::=
match fmi
case FMIIMPORT(fmiInfo=INFO(__),fmiExperimentAnnotation=EXPERIMENTANNOTATION(__)) then
  /* Get Real parameters and their value references */
  let realParametersVRs = dumpVariables(fmiModelVariablesList, "real", "parameter", false, 1, "1.0")
  let realParametersNames = dumpVariables(fmiModelVariablesList, "real", "parameter", false, 2, "1.0")
  /* Get Integer parameters and their value references */
  let integerParametersVRs = dumpVariables(fmiModelVariablesList, "integer", "parameter", false, 1, "1.0")
  let integerParametersNames = dumpVariables(fmiModelVariablesList, "integer", "parameter", false, 2, "1.0")
  /* Get Boolean parameters and their value references */
  let booleanParametersVRs = dumpVariables(fmiModelVariablesList, "boolean", "parameter", false, 1, "1.0")
  let booleanParametersNames = dumpVariables(fmiModelVariablesList, "boolean", "parameter", false, 2, "1.0")
  /* Get String parameters and their value references */
  let stringParametersVRs = dumpVariables(fmiModelVariablesList, "string", "parameter", false, 1, "1.0")
  let stringParametersNames = dumpVariables(fmiModelVariablesList, "string", "parameter", false, 2, "1.0")
  /* Get dependent Real parameters and their value references */
  let realDependentParametersVRs = dumpVariables(fmiModelVariablesList, "real", "parameter", true, 1, "1.0")
  let realDependentParametersNames = dumpVariables(fmiModelVariablesList, "real", "parameter", true, 2, "1.0")
  /* Get dependent Integer parameters and their value references */
  let integerDependentParametersVRs = dumpVariables(fmiModelVariablesList, "integer", "parameter", true, 1, "1.0")
  let integerDependentParametersNames = dumpVariables(fmiModelVariablesList, "integer", "parameter", true, 2, "1.0")
  /* Get dependent Boolean parameters and their value references */
  let booleanDependentParametersVRs = dumpVariables(fmiModelVariablesList, "boolean", "parameter", true, 1, "1.0")
  let booleanDependentParametersNames = dumpVariables(fmiModelVariablesList, "boolean", "parameter", true, 2, "1.0")
  /* Get dependent String parameters and their value references */
  let stringDependentParametersVRs = dumpVariables(fmiModelVariablesList, "string", "parameter", true, 1, "1.0")
  let stringDependentParametersNames = dumpVariables(fmiModelVariablesList, "string", "parameter", true, 2, "1.0")
  /* Get input Real varibales and their value references */
  let realInputVariablesVRs = dumpVariables(fmiModelVariablesList, "real", "input", false, 1, "1.0")
  let realInputVariablesNames = dumpVariables(fmiModelVariablesList, "real", "input", false, 2, "1.0")
  let realInputVariablesReturnNames = dumpVariables(fmiModelVariablesList, "real", "input", false, 3, "1.0")
  /* Get input Integer varibales and their value references */
  let integerInputVariablesVRs = dumpVariables(fmiModelVariablesList, "integer", "input", false, 1, "1.0")
  let integerInputVariablesNames = dumpVariables(fmiModelVariablesList, "integer", "input", false, 2, "1.0")
  let integerInputVariablesReturnNames = dumpVariables(fmiModelVariablesList, "integer", "input", false, 3, "1.0")
  /* Get input Boolean varibales and their value references */
  let booleanInputVariablesVRs = dumpVariables(fmiModelVariablesList, "boolean", "input", false, 1, "1.0")
  let booleanInputVariablesNames = dumpVariables(fmiModelVariablesList, "boolean", "input", false, 2, "1.0")
  let booleanInputVariablesReturnNames = dumpVariables(fmiModelVariablesList, "boolean", "input", false, 3, "1.0")
  /* Get input String varibales and their value references */
  let stringInputVariablesVRs = dumpVariables(fmiModelVariablesList, "string", "input", false, 1, "1.0")
  let stringStartVariablesNames = dumpVariables(fmiModelVariablesList, "string", "input", false, 2, "1.0")
  let stringInputVariablesReturnNames = dumpVariables(fmiModelVariablesList, "string", "input", false, 3, "1.0")
  /* Get output Real varibales and their value references */
  let realOutputVariablesVRs = dumpVariables(fmiModelVariablesList, "real", "output", false, 1, "1.0")
  let realOutputVariablesNames = dumpVariables(fmiModelVariablesList, "real", "output", false, 2, "1.0")
  /* Get output Integer varibales and their value references */
  let integerOutputVariablesVRs = dumpVariables(fmiModelVariablesList, "integer", "output", false, 1, "1.0")
  let integerOutputVariablesNames = dumpVariables(fmiModelVariablesList, "integer", "output", false, 2, "1.0")
  /* Get output Boolean varibales and their value references */
  let booleanOutputVariablesVRs = dumpVariables(fmiModelVariablesList, "boolean", "output", false, 1, "1.0")
  let booleanOutputVariablesNames = dumpVariables(fmiModelVariablesList, "boolean", "output", false, 2, "1.0")
  /* Get output String varibales and their value references */
  let stringOutputVariablesVRs = dumpVariables(fmiModelVariablesList, "string", "output", false, 1, "1.0")
  let stringOutputVariablesNames = dumpVariables(fmiModelVariablesList, "string", "output", false, 2, "1.0")
  <<
  model <%fmiInfo.fmiModelIdentifier%>_<%getFMIType(fmiInfo)%>_FMU<%if stringEq(fmiInfo.fmiDescription, "") then "" else " \""+fmiInfo.fmiDescription+"\""%>
    <%dumpFMITypeDefinitions(fmiTypeDefinitionsList)%>
    constant String fmuWorkingDir = "<%fmuWorkingDirectory%>";
    parameter Integer logLevel = <%fmiLogLevel%> "log level used during the loading of FMU" annotation (Dialog(tab="FMI", group="Enable logging"));
    parameter Boolean debugLogging = <%fmiDebugOutput%> "enables the FMU simulation logging" annotation (Dialog(tab="FMI", group="Enable logging"));
    <%dumpFMIModelVariablesList("1.0", fmiModelVariablesList, fmiTypeDefinitionsList, generateInputConnectors, generateOutputConnectors)%>
  protected
    FMI1ModelExchange fmi1me = FMI1ModelExchange(logLevel, fmuWorkingDir, "<%fmiInfo.fmiModelIdentifier%>", debugLogging);
    constant Integer numberOfContinuousStates = <%listLength(fmiInfo.fmiNumberOfContinuousStates)%>;
    Real fmi_x[numberOfContinuousStates] "States";
    Real fmi_x_new[numberOfContinuousStates](each fixed = true) "New States";
    constant Integer numberOfEventIndicators = <%listLength(fmiInfo.fmiNumberOfEventIndicators)%>;
    Real fmi_z[numberOfEventIndicators] "Events Indicators";
    Boolean fmi_z_positive[numberOfEventIndicators](each fixed = true);
    parameter Real flowStartTime(fixed=false);
    Real flowTime;
    parameter Real flowInitialized(fixed=false);
    parameter Real flowParamsStart(fixed=false);
    parameter Real flowInitInputs(fixed=false);
    Real flowStatesInputs;
    <%if not stringEq(realInputVariablesVRs, "") then "Real "+realInputVariablesReturnNames+";"%>
    <%if not stringEq(integerInputVariablesVRs, "") then "Integer "+integerInputVariablesReturnNames+";"%>
    <%if not stringEq(booleanInputVariablesVRs, "") then "Boolean "+booleanInputVariablesReturnNames+";"%>
    <%if not stringEq(stringInputVariablesVRs, "") then "String "+stringInputVariablesReturnNames+";"%>
    Boolean callEventUpdate;
    constant Boolean intermediateResults = false;
    Boolean newStatesAvailable(fixed = true);
    Real triggerDSSEvent;
    Real nextEventTime;
  initial equation
    flowStartTime = fmi1Functions.fmi1SetTime(fmi1me, time, 1);
    flowInitialized = fmi1Functions.fmi1Initialize(fmi1me, flowParamsStart+flowInitInputs+flowStartTime);
    <%if intGt(listLength(fmiInfo.fmiNumberOfContinuousStates), 0) then
    <<
    fmi_x = fmi1Functions.fmi1GetContinuousStates(fmi1me, numberOfContinuousStates, flowParamsStart+flowInitialized);
    >>
    %>
  initial algorithm
    flowParamsStart := 1;
    <%if not stringEq(realParametersVRs, "") then "flowParamsStart := fmi1Functions.fmi1SetRealParameter(fmi1me, {"+realParametersVRs+"}, {"+realParametersNames+"});"%>
    <%if not stringEq(integerParametersVRs, "") then "flowParamsStart := fmi1Functions.fmi1SetIntegerParameter(fmi1me, {"+integerParametersVRs+"}, {"+integerParametersNames+"});"%>
    <%if not stringEq(booleanParametersVRs, "") then "flowParamsStart := fmi1Functions.fmi1SetBooleanParameter(fmi1me, {"+booleanParametersVRs+"}, {"+booleanParametersNames+"});"%>
    <%if not stringEq(stringParametersVRs, "") then "flowParamsStart := fmi1Functions.fmi1SetStringParameter(fmi1me, {"+stringParametersVRs+"}, {"+stringParametersNames+"});"%>
    flowInitInputs := 1;
  initial equation
    <%if not stringEq(realDependentParametersVRs, "") then "{"+realDependentParametersNames+"} = fmi1Functions.fmi1GetReal(fmi1me, {"+realDependentParametersVRs+"}, flowInitialized);"%>
    <%if not stringEq(integerDependentParametersVRs, "") then "{"+integerDependentParametersNames+"} = fmi1Functions.fmi1GetInteger(fmi1me, {"+integerDependentParametersVRs+"}, flowInitialized);"%>
    <%if not stringEq(booleanDependentParametersVRs, "") then "{"+booleanDependentParametersNames+"} = fmi1Functions.fmi1GetBoolean(fmi1me, {"+booleanDependentParametersVRs+"}, flowInitialized);"%>
    <%if not stringEq(stringDependentParametersVRs, "") then "{"+stringDependentParametersNames+"} = fmi1Functions.fmi1GetString(fmi1me, {"+stringDependentParametersVRs+"}, flowInitialized);"%>
  equation
    flowTime = fmi1Functions.fmi1SetTime(fmi1me, time, flowInitialized);
    <%if not stringEq(realInputVariablesVRs, "") then "{"+realInputVariablesReturnNames+"} = fmi1Functions.fmi1SetReal(fmi1me, {"+realInputVariablesVRs+"}, {"+realInputVariablesNames+"});"%>
    <%if not stringEq(integerInputVariablesVRs, "") then "{"+integerInputVariablesReturnNames+"} = fmi1Functions.fmi1SetInteger(fmi1me, {"+integerInputVariablesVRs+"}, {"+integerInputVariablesNames+"});"%>
    <%if not stringEq(booleanInputVariablesVRs, "") then "{"+booleanInputVariablesReturnNames+"} = fmi1Functions.fmi1SetBoolean(fmi1me, {"+booleanInputVariablesVRs+"}, {"+booleanInputVariablesNames+"});"%>
    <%if not stringEq(stringInputVariablesVRs, "") then "{"+stringInputVariablesReturnNames+"} = fmi1Functions.fmi1SetString(fmi1me, {"+stringInputVariablesVRs+"}, {"+stringStartVariablesNames+"});"%>
    flowStatesInputs = fmi1Functions.fmi1SetContinuousStates(fmi1me, fmi_x, flowParamsStart + flowTime);
    der(fmi_x) = fmi1Functions.fmi1GetDerivatives(fmi1me, numberOfContinuousStates, flowStatesInputs);
    fmi_z  = fmi1Functions.fmi1GetEventIndicators(fmi1me, numberOfEventIndicators, flowStatesInputs);
    for i in 1:size(fmi_z,1) loop
      fmi_z_positive[i] = if not terminal() then fmi_z[i] > 0 else pre(fmi_z_positive[i]);
    end for;
    callEventUpdate = fmi1Functions.fmi1CompletedIntegratorStep(fmi1me, flowStatesInputs);
    triggerDSSEvent = noEvent(if callEventUpdate then flowStatesInputs+1.0 else flowStatesInputs-1.0);
    nextEventTime = fmi1Functions.fmi1nextEventTime(fmi1me, flowStatesInputs);
    <%if not boolAnd(stringEq(realOutputVariablesNames, ""), stringEq(realOutputVariablesVRs, "")) then "{"+realOutputVariablesNames+"} = fmi1Functions.fmi1GetReal(fmi1me, {"+realOutputVariablesVRs+"}, flowStatesInputs);"%>
    <%if not boolAnd(stringEq(integerOutputVariablesNames, ""), stringEq(integerOutputVariablesVRs, "")) then "{"+integerOutputVariablesNames+"} = fmi1Functions.fmi1GetInteger(fmi1me, {"+integerOutputVariablesVRs+"}, flowStatesInputs);"%>
    <%if not boolAnd(stringEq(booleanOutputVariablesNames, ""), stringEq(booleanOutputVariablesVRs, "")) then "{"+booleanOutputVariablesNames+"} = fmi1Functions.fmi1GetBoolean(fmi1me, {"+booleanOutputVariablesVRs+"}, flowStatesInputs);"%>
    <%if not boolAnd(stringEq(stringOutputVariablesNames, ""), stringEq(stringOutputVariablesVRs, "")) then "{"+stringOutputVariablesNames+"} = fmi1Functions.fmi1GetString(fmi1me, {"+stringOutputVariablesVRs+"}, flowStatesInputs);"%>
    <%dumpOutputGetEnumerationVariables(fmiModelVariablesList, fmiTypeDefinitionsList, "fmi1Functions.fmi1GetInteger", "fmi1me")%>
  algorithm
  <%if intGt(listLength(fmiInfo.fmiNumberOfEventIndicators), 0) then
  <<
    when {<%fmiInfo.fmiNumberOfEventIndicators |> eventIndicator =>  "change(fmi_z_positive["+eventIndicator+"])" ;separator=" or "%>, triggerDSSEvent > flowStatesInputs, nextEventTime < time, terminal()} then
  >>
  else
  <<
    when {triggerDSSEvent > flowStatesInputs, nextEventTime < time, terminal()} then
  >>
  %>
      newStatesAvailable := fmi1Functions.fmi1EventUpdate(fmi1me, intermediateResults);
  <%if intGt(listLength(fmiInfo.fmiNumberOfContinuousStates), 0) then
  <<
      if newStatesAvailable then
        fmi_x_new := fmi1Functions.fmi1GetContinuousStates(fmi1me, numberOfContinuousStates, flowStatesInputs);
        <%fmiInfo.fmiNumberOfContinuousStates |> continuousStates =>  "reinit(fmi_x["+continuousStates+"], fmi_x_new["+continuousStates+"]);" ;separator="\n"%>
      end if;
  >>
  %>
    end when;
    annotation(experiment(StartTime=<%fmiExperimentAnnotation.fmiExperimentStartTime%>, StopTime=<%fmiExperimentAnnotation.fmiExperimentStopTime%>, Tolerance=<%fmiExperimentAnnotation.fmiExperimentTolerance%>));
    annotation (Icon(graphics={
        Rectangle(
          extent={{-100,100},{100,-100}},
          lineColor={0,0,0},
          fillColor={240,240,240},
          fillPattern=FillPattern.Solid,
          lineThickness=0.5),
        Text(
          extent={{-100,40},{100,0}},
          lineColor={0,0,0},
          textString="%name"),
        Text(
          extent={{-100,-50},{100,-90}},
          lineColor={0,0,0},
          textString="V1.0")}));
  protected
    class FMI1ModelExchange
      extends ExternalObject;
        function constructor
          input Integer logLevel;
          input String workingDirectory;
          input String instanceName;
          input Boolean debugLogging;
          output FMI1ModelExchange fmi1me;
          external "C" fmi1me = FMI1ModelExchangeConstructor_OMC(logLevel, workingDirectory, instanceName, debugLogging) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
        end constructor;

        function destructor
          input FMI1ModelExchange fmi1me;
          external "C" FMI1ModelExchangeDestructor_OMC(fmi1me) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
        end destructor;
    end FMI1ModelExchange;

    <%dumpFMITypeDefinitionsMappingFunctions(fmiTypeDefinitionsList)%>

    <%dumpFMITypeDefinitionsArrayMappingFunctions(fmiTypeDefinitionsList)%>

    package fmi1Functions
      function fmi1Initialize
        input FMI1ModelExchange fmi1me;
        input Real preInitialized;
        output Real postInitialized=preInitialized;
        external "C" fmi1Initialize_OMC(fmi1me) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1Initialize;

      function fmi1SetTime
        input FMI1ModelExchange fmi1me;
        input Real inTime;
        input Real inFlow;
        output Real outFlow = inFlow;
        external "C" fmi1SetTime_OMC(fmi1me, inTime) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1SetTime;

      function fmi1GetContinuousStates
        input FMI1ModelExchange fmi1me;
        input Integer numberOfContinuousStates;
        input Real inFlowParams;
        output Real fmi_x[numberOfContinuousStates];
        external "C" fmi1GetContinuousStates_OMC(fmi1me, numberOfContinuousStates, inFlowParams, fmi_x) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1GetContinuousStates;

      function fmi1SetContinuousStates
        input FMI1ModelExchange fmi1me;
        input Real fmi_x[:];
        input Real inFlowParams;
        output Real outFlowStates;
        external "C" outFlowStates = fmi1SetContinuousStates_OMC(fmi1me, size(fmi_x, 1), inFlowParams, fmi_x) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1SetContinuousStates;

      function fmi1GetDerivatives
        input FMI1ModelExchange fmi1me;
        input Integer numberOfContinuousStates;
        input Real inFlowStates;
        output Real fmi_x[numberOfContinuousStates];
        external "C" fmi1GetDerivatives_OMC(fmi1me, numberOfContinuousStates, inFlowStates, fmi_x) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1GetDerivatives;

      function fmi1GetEventIndicators
        input FMI1ModelExchange fmi1me;
        input Integer numberOfEventIndicators;
        input Real inFlowStates;
        output Real fmi_z[numberOfEventIndicators];
        external "C" fmi1GetEventIndicators_OMC(fmi1me, numberOfEventIndicators, inFlowStates, fmi_z) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1GetEventIndicators;

      function fmi1GetReal
        input FMI1ModelExchange fmi1me;
        input Real realValuesReferences[:];
        input Real inFlowStatesInput;
        output Real realValues[size(realValuesReferences, 1)];
        external "C" fmi1GetReal_OMC(fmi1me, size(realValuesReferences, 1), realValuesReferences, inFlowStatesInput, realValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1GetReal;

      function fmi1SetReal
        input FMI1ModelExchange fmi1me;
        input Real realValueReferences[:];
        input Real realValues[size(realValueReferences, 1)];
        output Real outValues[size(realValueReferences, 1)] = realValues;
        external "C" fmi1SetReal_OMC(fmi1me, size(realValueReferences, 1), realValueReferences, realValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1SetReal;

      function fmi1SetRealParameter
        input FMI1ModelExchange fmi1me;
        input Real realValueReferences[:];
        input Real realValues[size(realValueReferences, 1)];
        output Real out_Value = 1;
        external "C" fmi1SetReal_OMC(fmi1me, size(realValueReferences, 1), realValueReferences, realValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1SetRealParameter;

      function fmi1GetInteger
        input FMI1ModelExchange fmi1me;
        input Real integerValueReferences[:];
        input Real inFlowStatesInput;
        output Integer integerValues[size(integerValueReferences, 1)];
        external "C" fmi1GetInteger_OMC(fmi1me, size(integerValueReferences, 1), integerValueReferences, inFlowStatesInput, integerValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1GetInteger;

      function fmi1SetInteger
        input FMI1ModelExchange fmi1me;
        input Real integerValuesReferences[:];
        input Integer integerValues[size(integerValuesReferences, 1)];
        output Integer outValues[size(integerValuesReferences, 1)] = integerValues;
        external "C" fmi1SetInteger_OMC(fmi1me, size(integerValuesReferences, 1), integerValuesReferences, integerValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1SetInteger;

      function fmi1SetIntegerParameter
        input FMI1ModelExchange fmi1me;
        input Real integerValuesReferences[:];
        input Integer integerValues[size(integerValuesReferences, 1)];
        output Real out_Value = 1;
        external "C" fmi1SetInteger_OMC(fmi1me, size(integerValuesReferences, 1), integerValuesReferences, integerValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1SetIntegerParameter;

      function fmi1GetBoolean
        input FMI1ModelExchange fmi1me;
        input Real booleanValuesReferences[:];
        input Real inFlowStatesInput;
        output Boolean booleanValues[size(booleanValuesReferences, 1)];
        external "C" fmi1GetBoolean_OMC(fmi1me, size(booleanValuesReferences, 1), booleanValuesReferences, inFlowStatesInput, booleanValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1GetBoolean;

      function fmi1SetBoolean
        input FMI1ModelExchange fmi1me;
        input Real booleanValueReferences[:];
        input Boolean booleanValues[size(booleanValueReferences, 1)];
        output Boolean outValues[size(booleanValueReferences, 1)] = booleanValues;
        external "C" fmi1SetBoolean_OMC(fmi1me, size(booleanValueReferences, 1), booleanValueReferences, booleanValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1SetBoolean;

      function fmi1SetBooleanParameter
        input FMI1ModelExchange fmi1me;
        input Real booleanValueReferences[:];
        input Boolean booleanValues[size(booleanValueReferences, 1)];
        output Real out_Value = 1;
        external "C" fmi1SetBoolean_OMC(fmi1me, size(booleanValueReferences, 1), booleanValueReferences, booleanValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1SetBooleanParameter;

      function fmi1GetString
        input FMI1ModelExchange fmi1me;
        input Real stringValuesReferences[:];
        input Real inFlowStatesInput;
        output String stringValues[size(stringValuesReferences, 1)];
        external "C" fmi1GetString_OMC(fmi1me, size(stringValuesReferences, 1), stringValuesReferences, inFlowStatesInput, stringValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1GetString;

      function fmi1SetString
        input FMI1ModelExchange fmi1me;
        input Real stringValueReferences[:];
        input String stringValues[size(stringValueReferences, 1)];
        output String outValues[size(stringValueReferences, 1)] = stringValues;
        external "C" fmi1SetString_OMC(fmi1me, size(stringValueReferences, 1), stringValueReferences, stringValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1SetString;

      function fmi1SetStringParameter
        input FMI1ModelExchange fmi1me;
        input Real stringValueReferences[:];
        input String stringValues[size(stringValueReferences, 1)];
        output Real out_Value = 1;
        external "C" fmi1SetString_OMC(fmi1me, size(stringValueReferences, 1), stringValueReferences, stringValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1SetStringParameter;

      function fmi1EventUpdate
        input FMI1ModelExchange fmi1me;
        input Boolean intermediateResults;
        output Boolean outNewStatesAvailable;
        external "C" outNewStatesAvailable = fmi1EventUpdate_OMC(fmi1me, intermediateResults) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1EventUpdate;

      function fmi1nextEventTime
        input FMI1ModelExchange fmi1me;
        input Real inFlowStates;
        output Real outNewnextTime;
        external "C" outNewnextTime = fmi1nextEventTime_OMC(fmi1me, inFlowStates) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1nextEventTime;

      function fmi1CompletedIntegratorStep
        input FMI1ModelExchange fmi1me;
        input Real inFlowStates;
        output Boolean outCallEventUpdate;
        external "C" outCallEventUpdate = fmi1CompletedIntegratorStep_OMC(fmi1me, inFlowStates) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1CompletedIntegratorStep;
    end fmi1Functions;
  end <%fmiInfo.fmiModelIdentifier%>_<%getFMIType(fmiInfo)%>_FMU;
  >>
end importFMU1ModelExchange;

template importFMU2ModelExchange(FmiImport fmi)
 "Generates Modelica code for FMI Model Exchange version 2.0"
::=
match fmi
case FMIIMPORT(fmiInfo=INFO(__),fmiExperimentAnnotation=EXPERIMENTANNOTATION(__)) then
  /* Get Real parameters and their value references */
  let realParametersVRs = dumpVariables(fmiModelVariablesList, "real", "parameter", false, 1, "2.0")
  let realParametersNames = dumpVariables(fmiModelVariablesList, "real", "parameter", false, 2, "2.0")
  /* Get Integer parameters and their value references */
  let integerParametersVRs = dumpVariables(fmiModelVariablesList, "integer", "parameter", false, 1, "2.0")
  let integerParametersNames = dumpVariables(fmiModelVariablesList, "integer", "parameter", false, 2, "2.0")
  /* Get Boolean parameters and their value references */
  let booleanParametersVRs = dumpVariables(fmiModelVariablesList, "boolean", "parameter", false, 1, "2.0")
  let booleanParametersNames = dumpVariables(fmiModelVariablesList, "boolean", "parameter", false, 2, "2.0")
  /* Get String parameters and their value references */
  let stringParametersVRs = dumpVariables(fmiModelVariablesList, "string", "parameter", false, 1, "2.0")
  let stringParametersNames = dumpVariables(fmiModelVariablesList, "string", "parameter", false, 2, "2.0")
  /* Get dependent Real parameters and their value references */
  let realDependentParametersVRs = dumpVariables(fmiModelVariablesList, "real", "parameter", true, 1, "2.0")
  let realDependentParametersNames = dumpVariables(fmiModelVariablesList, "real", "parameter", true, 2, "2.0")
  /* Get dependent Integer parameters and their value references */
  let integerDependentParametersVRs = dumpVariables(fmiModelVariablesList, "integer", "parameter", true, 1, "2.0")
  let integerDependentParametersNames = dumpVariables(fmiModelVariablesList, "integer", "parameter", true, 2, "2.0")
  /* Get dependent Boolean parameters and their value references */
  let booleanDependentParametersVRs = dumpVariables(fmiModelVariablesList, "boolean", "parameter", true, 1, "2.0")
  let booleanDependentParametersNames = dumpVariables(fmiModelVariablesList, "boolean", "parameter", true, 2, "2.0")
  /* Get dependent String parameters and their value references */
  let stringDependentParametersVRs = dumpVariables(fmiModelVariablesList, "string", "parameter", true, 1, "2.0")
  let stringDependentParametersNames = dumpVariables(fmiModelVariablesList, "string", "parameter", true, 2, "2.0")
  /* Get input Real varibales and their value references */
  let nRealInputVariables = listLength(filterModelVariables(fmiModelVariablesList, "real", "input"))
  let realInputVariablesVRs = dumpVariables(fmiModelVariablesList, "real", "input", false, 1, "2.0")
  let realInputVariablesNames = dumpVariables(fmiModelVariablesList, "real", "input", false, 2, "2.0")
  let realInputVariablesReturnNames = dumpVariables(fmiModelVariablesList, "real", "input", false, 3, "2.0")
  /* Get input Integer varibales and their value references */
  let nIntegerInputVariables = listLength(filterModelVariables(fmiModelVariablesList, "integer", "input"))
  let integerInputVariablesVRs = dumpVariables(fmiModelVariablesList, "integer", "input", false, 1, "2.0")
  let integerInputVariablesNames = dumpVariables(fmiModelVariablesList, "integer", "input", false, 2, "2.0")
  let integerInputVariablesReturnNames = dumpVariables(fmiModelVariablesList, "integer", "input", false, 3, "2.0")
  /* Get input Boolean varibales and their value references */
  let nBooleanInputVariables = listLength(filterModelVariables(fmiModelVariablesList, "boolean", "input"))
  let booleanInputVariablesVRs = dumpVariables(fmiModelVariablesList, "boolean", "input", false, 1, "2.0")
  let booleanInputVariablesNames = dumpVariables(fmiModelVariablesList, "boolean", "input", false, 2, "2.0")
  let booleanInputVariablesReturnNames = dumpVariables(fmiModelVariablesList, "boolean", "input", false, 3, "2.0")
  /* Get input String varibales and their value references */
  let nStringInputVariables = listLength(filterModelVariables(fmiModelVariablesList, "string", "input"))
  let stringInputVariablesVRs = dumpVariables(fmiModelVariablesList, "string", "input", false, 1, "2.0")
  let stringStartVariablesNames = dumpVariables(fmiModelVariablesList, "string", "input", false, 2, "2.0")
  let stringInputVariablesReturnNames = dumpVariables(fmiModelVariablesList, "string", "input", false, 3, "2.0")
  /* Get output Real varibales and their value references */
  let realOutputVariablesVRs = dumpVariables(fmiModelVariablesList, "real", "output", false, 1, "2.0")
  let realOutputVariablesNames = dumpVariables(fmiModelVariablesList, "real", "output", false, 2, "2.0")
  /* Get output Integer varibales and their value references */
  let integerOutputVariablesVRs = dumpVariables(fmiModelVariablesList, "integer", "output", false, 1, "2.0")
  let integerOutputVariablesNames = dumpVariables(fmiModelVariablesList, "integer", "output", false, 2, "2.0")
  /* Get output Boolean varibales and their value references */
  let booleanOutputVariablesVRs = dumpVariables(fmiModelVariablesList, "boolean", "output", false, 1, "2.0")
  let booleanOutputVariablesNames = dumpVariables(fmiModelVariablesList, "boolean", "output", false, 2, "2.0")
  /* Get output String varibales and their value references */
  let stringOutputVariablesVRs = dumpVariables(fmiModelVariablesList, "string", "output", false, 1, "2.0")
  let stringOutputVariablesNames = dumpVariables(fmiModelVariablesList, "string", "output", false, 2, "2.0")
  <<
  model <%fmiInfo.fmiModelIdentifier%>_<%getFMIType(fmiInfo)%>_FMU<%if stringEq(fmiInfo.fmiDescription, "") then "" else " \""+fmiInfo.fmiDescription+"\""%>
    <%dumpFMITypeDefinitions(fmiTypeDefinitionsList)%>
    constant String fmuWorkingDir = "<%fmuWorkingDirectory%>";
    parameter Integer logLevel = <%fmiLogLevel%> "log level used during the loading of FMU" annotation (Dialog(tab="FMI", group="Enable logging"));
    parameter Boolean debugLogging = <%fmiDebugOutput%> "enables the FMU simulation logging" annotation (Dialog(tab="FMI", group="Enable logging"));
    <%dumpFMIModelVariablesList("2.0", fmiModelVariablesList, fmiTypeDefinitionsList, generateInputConnectors, generateOutputConnectors)%>
  protected
    FMI2ModelExchange fmi2me = FMI2ModelExchange(logLevel, fmuWorkingDir, "<%fmiInfo.fmiModelIdentifier%>", debugLogging);
    constant Integer numberOfContinuousStates = <%listLength(fmiInfo.fmiNumberOfContinuousStates)%>;
    Real fmi_x[numberOfContinuousStates] "States";
    Real fmi_x_new[numberOfContinuousStates](each fixed=true) "New States";
    constant Integer numberOfEventIndicators = <%listLength(fmiInfo.fmiNumberOfEventIndicators)%>;
    Real fmi_z[numberOfEventIndicators] "Events Indicators";
    Boolean fmi_z_positive[numberOfEventIndicators](each fixed=true);
    parameter Real flowStartTime(fixed=false);
    Real flowTime;
    parameter Real flowEnterInitialization(fixed=false);
    parameter Real flowInitialized(fixed=false);
    parameter Real flowParamsStart(fixed=false);
    parameter Real flowInitInputs(fixed=false);
    Real flowStatesInputs;
    <%if not stringEq(realInputVariablesVRs, "") then "Real realInputVariables["+nRealInputVariables+"];"%>
    <%if not stringEq(realInputVariablesVRs, "") then "Real "+realInputVariablesReturnNames+";"%>
    <%if not stringEq(integerInputVariablesVRs, "") then "Integer integerInputVariables["+nIntegerInputVariables+"];"%>
    <%if not stringEq(integerInputVariablesVRs, "") then "Integer "+integerInputVariablesReturnNames+";"%>
    <%if not stringEq(booleanInputVariablesVRs, "") then "Boolean booleanInputVariables["+nBooleanInputVariables+"];"%>
    <%if not stringEq(booleanInputVariablesVRs, "") then "Boolean "+booleanInputVariablesReturnNames+";"%>
    <%if not stringEq(stringInputVariablesVRs, "") then "String stringInputVariables["+nStringInputVariables+"];"%>
    <%if not stringEq(stringInputVariablesVRs, "") then "String "+stringInputVariablesReturnNames+";"%>
    Boolean callEventUpdate;
    Boolean newStatesAvailable(fixed = true);
    Real triggerDSSEvent;
    Real nextEventTime(fixed = true);
  initial equation
    flowStartTime = fmi2Functions.fmi2SetTime(fmi2me, time, 1);
    flowEnterInitialization = fmi2Functions.fmi2EnterInitialization(fmi2me, flowParamsStart+flowInitInputs+flowStartTime);
    flowInitialized = fmi2Functions.fmi2ExitInitialization(fmi2me, flowParamsStart+flowInitInputs+flowStartTime+flowEnterInitialization);
    <%if intGt(listLength(fmiInfo.fmiNumberOfContinuousStates), 0) then
    <<
    fmi_x = fmi2Functions.fmi2GetContinuousStates(fmi2me, numberOfContinuousStates, flowParamsStart+flowInitialized);
    >>
    %>
  initial algorithm
    flowParamsStart := 1;
    <%if not stringEq(realParametersVRs, "") then "flowParamsStart := fmi2Functions.fmi2SetRealParameter(fmi2me, {"+realParametersVRs+"}, {"+realParametersNames+"});"%>
    <%if not stringEq(integerParametersVRs, "") then "flowParamsStart := fmi2Functions.fmi2SetIntegerParameter(fmi2me, {"+integerParametersVRs+"}, {"+integerParametersNames+"});"%>
    <%if not stringEq(booleanParametersVRs, "") then "flowParamsStart := fmi2Functions.fmi2SetBooleanParameter(fmi2me, {"+booleanParametersVRs+"}, {"+booleanParametersNames+"});"%>
    <%if not stringEq(stringParametersVRs, "") then "flowParamsStart := fmi2Functions.fmi2SetStringParameter(fmi2me, {"+stringParametersVRs+"}, {"+stringParametersNames+"});"%>
    flowInitInputs := 1;
  initial equation
    <%if not stringEq(realDependentParametersVRs, "") then "{"+realDependentParametersNames+"} = fmi2Functions.fmi2GetReal(fmi2me, {"+realDependentParametersVRs+"}, flowInitialized);"%>
    <%if not stringEq(integerDependentParametersVRs, "") then "{"+integerDependentParametersNames+"} = fmi2Functions.fmi2GetInteger(fmi2me, {"+integerDependentParametersVRs+"}, flowInitialized);"%>
    <%if not stringEq(booleanDependentParametersVRs, "") then "{"+booleanDependentParametersNames+"} = fmi2Functions.fmi2GetBoolean(fmi2me, {"+booleanDependentParametersVRs+"}, flowInitialized);"%>
    <%if not stringEq(stringDependentParametersVRs, "") then "{"+stringDependentParametersNames+"} = fmi2Functions.fmi2GetString(fmi2me, {"+stringDependentParametersVRs+"}, flowInitialized);"%>
  algorithm
    flowTime := fmi2Functions.fmi2SetTime(fmi2me, time, flowInitialized);
    /* algorithm section ensures that inputs to fmi (if any) are set directly after the new time is set */
    <%if not stringEq(realInputVariablesVRs, "") then "realInputVariables := fmi2Functions.fmi2SetReal(fmi2me, {"+realInputVariablesVRs+"}, {"+realInputVariablesNames+"});"%>
    <%if not stringEq(integerInputVariablesVRs, "") then "integerInputVariables := fmi2Functions.fmi2SetInteger(fmi2me, {"+integerInputVariablesVRs+"}, {"+integerInputVariablesNames+"});"%>
    <%if not stringEq(booleanInputVariablesVRs, "") then "booleanInputVariables := fmi2Functions.fmi2SetBoolean(fmi2me, {"+booleanInputVariablesVRs+"}, {"+booleanInputVariablesNames+"});"%>
    <%if not stringEq(stringInputVariablesVRs, "") then "stringInputVariables := fmi2Functions.fmi2SetString(fmi2me, {"+stringInputVariablesVRs+"}, {"+stringStartVariablesNames+"});"%>
  equation
    <%if not stringEq(realInputVariablesVRs, "") then "{"+realInputVariablesReturnNames+"} = realInputVariables;"%>
    <%if not stringEq(integerInputVariablesVRs, "") then "{"+integerInputVariablesReturnNames+"} = integerInputVariables;"%>
    <%if not stringEq(booleanInputVariablesVRs, "") then "{"+booleanInputVariablesReturnNames+"} = booleanInputVariables;"%>
    <%if not stringEq(stringInputVariablesVRs, "") then "{"+stringInputVariablesReturnNames+"} = stringInputVariables;"%>
    flowStatesInputs = fmi2Functions.fmi2SetContinuousStates(fmi2me, fmi_x, flowParamsStart + flowTime);
    der(fmi_x) = fmi2Functions.fmi2GetDerivatives(fmi2me, numberOfContinuousStates, flowStatesInputs);
    fmi_z  = fmi2Functions.fmi2GetEventIndicators(fmi2me, numberOfEventIndicators, flowStatesInputs);
    for i in 1:size(fmi_z,1) loop
      fmi_z_positive[i] = if not terminal() then fmi_z[i] > 0 else pre(fmi_z_positive[i]);
    end for;

    triggerDSSEvent = noEvent(if callEventUpdate then flowStatesInputs+1.0 else flowStatesInputs-1.0);

    <%if not boolAnd(stringEq(realOutputVariablesNames, ""), stringEq(realOutputVariablesVRs, "")) then "{"+realOutputVariablesNames+"} = fmi2Functions.fmi2GetReal(fmi2me, {"+realOutputVariablesVRs+"}, flowStatesInputs);"%>
    <%if not boolAnd(stringEq(integerOutputVariablesNames, ""), stringEq(integerOutputVariablesVRs, "")) then "{"+integerOutputVariablesNames+"} = fmi2Functions.fmi2GetInteger(fmi2me, {"+integerOutputVariablesVRs+"}, flowStatesInputs);"%>
    <%if not boolAnd(stringEq(booleanOutputVariablesNames, ""), stringEq(booleanOutputVariablesVRs, "")) then "{"+booleanOutputVariablesNames+"} = fmi2Functions.fmi2GetBoolean(fmi2me, {"+booleanOutputVariablesVRs+"}, flowStatesInputs);"%>
    <%if not boolAnd(stringEq(stringOutputVariablesNames, ""), stringEq(stringOutputVariablesVRs, "")) then "{"+stringOutputVariablesNames+"} = fmi2Functions.fmi2GetString(fmi2me, {"+stringOutputVariablesVRs+"}, flowStatesInputs);"%>
    <%dumpOutputGetEnumerationVariables(fmiModelVariablesList, fmiTypeDefinitionsList, "fmi2Functions.fmi2GetInteger", "fmi2me")%>
    callEventUpdate = fmi2Functions.fmi2CompletedIntegratorStep(fmi2me, flowStatesInputs+flowTime);
  algorithm
  <%if intGt(listLength(fmiInfo.fmiNumberOfEventIndicators), 0) then
  <<
    when {<%fmiInfo.fmiNumberOfEventIndicators |> eventIndicator =>  "change(fmi_z_positive["+eventIndicator+"])" ;separator=" or "%>, triggerDSSEvent > flowStatesInputs, pre(nextEventTime) < time, terminal()} then
  >>
  else
  <<
    when {triggerDSSEvent > flowStatesInputs, pre(nextEventTime) < time, terminal()} then
  >>
  %>
      newStatesAvailable := fmi2Functions.fmi2EventUpdate(fmi2me);
      nextEventTime := fmi2Functions.fmi2nextEventTime(fmi2me, flowStatesInputs);
  <%if intGt(listLength(fmiInfo.fmiNumberOfContinuousStates), 0) then
  <<
      if newStatesAvailable then
        fmi_x_new := fmi2Functions.fmi2GetContinuousStates(fmi2me, numberOfContinuousStates, flowStatesInputs);
        <%fmiInfo.fmiNumberOfContinuousStates |> continuousStates =>  "reinit(fmi_x["+continuousStates+"], fmi_x_new["+continuousStates+"]);" ;separator="\n"%>
      end if;
  >>
  %>
    end when;
    annotation(experiment(StartTime=<%fmiExperimentAnnotation.fmiExperimentStartTime%>, StopTime=<%fmiExperimentAnnotation.fmiExperimentStopTime%>, Tolerance=<%fmiExperimentAnnotation.fmiExperimentTolerance%>));
    annotation (Icon(graphics={
        Rectangle(
          extent={{-100,100},{100,-100}},
          lineColor={0,0,0},
          fillColor={240,240,240},
          fillPattern=FillPattern.Solid,
          lineThickness=0.5),
        Text(
          extent={{-100,40},{100,0}},
          lineColor={0,0,0},
          textString="%name"),
        Text(
          extent={{-100,-50},{100,-90}},
          lineColor={0,0,0},
          textString="V2.0")}));
  protected
    class FMI2ModelExchange
      extends ExternalObject;
        function constructor
          input Integer logLevel;
          input String workingDirectory;
          input String instanceName;
          input Boolean debugLogging;
          output FMI2ModelExchange fmi2me;
          external "C" fmi2me = FMI2ModelExchangeConstructor_OMC(logLevel, workingDirectory, instanceName, debugLogging) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
        end constructor;

        function destructor
          input FMI2ModelExchange fmi2me;
          external "C" FMI2ModelExchangeDestructor_OMC(fmi2me) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
        end destructor;
    end FMI2ModelExchange;

    <%dumpFMITypeDefinitionsMappingFunctions(fmiTypeDefinitionsList)%>

    <%dumpFMITypeDefinitionsArrayMappingFunctions(fmiTypeDefinitionsList)%>

    package fmi2Functions
      function fmi2SetTime
        input FMI2ModelExchange fmi2me;
        input Real inTime;
        input Real inFlow;
        output Real outFlow = inFlow;
        external "C" fmi2SetTime_OMC(fmi2me, inTime) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2SetTime;

      function fmi2EnterInitialization
        input FMI2ModelExchange fmi2me;
        input Real inFlowVariable;
        output Real outFlowVariable = inFlowVariable;
        external "C" fmi2EnterInitializationModel_OMC(fmi2me) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2EnterInitialization;

      function fmi2ExitInitialization
        input FMI2ModelExchange fmi2me;
        input Real inFlowVariable;
        output Real outFlowVariable = inFlowVariable;
        external "C" fmi2ExitInitializationModel_OMC(fmi2me) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2ExitInitialization;

      function fmi2GetContinuousStates
        input FMI2ModelExchange fmi2me;
        input Integer numberOfContinuousStates;
        input Real inFlowParams;
        output Real fmi_x[numberOfContinuousStates];
        external "C" fmi2GetContinuousStates_OMC(fmi2me, numberOfContinuousStates, inFlowParams, fmi_x) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2GetContinuousStates;

      function fmi2SetContinuousStates
        input FMI2ModelExchange fmi2me;
        input Real fmi_x[:];
        input Real inFlowParams;
        output Real outFlowStates;
        external "C" outFlowStates = fmi2SetContinuousStates_OMC(fmi2me, size(fmi_x, 1), inFlowParams, fmi_x) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2SetContinuousStates;

      function fmi2GetDerivatives
        input FMI2ModelExchange fmi2me;
        input Integer numberOfContinuousStates;
        input Real inFlowStates;
        output Real fmi_x[numberOfContinuousStates];
        external "C" fmi2GetDerivatives_OMC(fmi2me, numberOfContinuousStates, inFlowStates, fmi_x) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2GetDerivatives;

      function fmi2GetEventIndicators
        input FMI2ModelExchange fmi2me;
        input Integer numberOfEventIndicators;
        input Real inFlowStates;
        output Real fmi_z[numberOfEventIndicators];
        external "C" fmi2GetEventIndicators_OMC(fmi2me, numberOfEventIndicators, inFlowStates, fmi_z) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2GetEventIndicators;

      function fmi2GetReal
        input FMI2ModelExchange fmi2me;
        input Real realValuesReferences[:];
        input Real inFlowStatesInput;
        output Real realValues[size(realValuesReferences, 1)];
        external "C" fmi2GetReal_OMC(fmi2me, size(realValuesReferences, 1), realValuesReferences, inFlowStatesInput, realValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2GetReal;

      function fmi2SetReal
        input FMI2ModelExchange fmi2me;
        input Real realValueReferences[:];
        input Real realValues[size(realValueReferences, 1)];
        output Real outValues[size(realValueReferences, 1)] = realValues;
        external "C" fmi2SetReal_OMC(fmi2me, size(realValueReferences, 1), realValueReferences, realValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2SetReal;

      function fmi2SetRealParameter
        input FMI2ModelExchange fmi2me;
        input Real realValueReferences[:];
        input Real realValues[size(realValueReferences, 1)];
        output Real out_Value = 1;
        external "C" fmi2SetReal_OMC(fmi2me, size(realValueReferences, 1), realValueReferences, realValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2SetRealParameter;

      function fmi2GetInteger
        input FMI2ModelExchange fmi2me;
        input Real integerValueReferences[:];
        input Real inFlowStatesInput;
        output Integer integerValues[size(integerValueReferences, 1)];
        external "C" fmi2GetInteger_OMC(fmi2me, size(integerValueReferences, 1), integerValueReferences, inFlowStatesInput, integerValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2GetInteger;

      function fmi2SetInteger
        input FMI2ModelExchange fmi2me;
        input Real integerValuesReferences[:];
        input Integer integerValues[size(integerValuesReferences, 1)];
        output Integer outValues[size(integerValuesReferences, 1)] = integerValues;
        external "C" fmi2SetInteger_OMC(fmi2me, size(integerValuesReferences, 1), integerValuesReferences, integerValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2SetInteger;

      function fmi2SetIntegerParameter
        input FMI2ModelExchange fmi2me;
        input Real integerValuesReferences[:];
        input Integer integerValues[size(integerValuesReferences, 1)];
        output Real out_Value = 1;
        external "C" fmi2SetInteger_OMC(fmi2me, size(integerValuesReferences, 1), integerValuesReferences, integerValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2SetIntegerParameter;

      function fmi2GetBoolean
        input FMI2ModelExchange fmi2me;
        input Real booleanValuesReferences[:];
        input Real inFlowStatesInput;
        output Boolean booleanValues[size(booleanValuesReferences, 1)];
        external "C" fmi2GetBoolean_OMC(fmi2me, size(booleanValuesReferences, 1), booleanValuesReferences, inFlowStatesInput, booleanValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2GetBoolean;

      function fmi2SetBoolean
        input FMI2ModelExchange fmi2me;
        input Real booleanValueReferences[:];
        input Boolean booleanValues[size(booleanValueReferences, 1)];
        output Boolean outValues[size(booleanValueReferences, 1)] = booleanValues;
        external "C" fmi2SetBoolean_OMC(fmi2me, size(booleanValueReferences, 1), booleanValueReferences, booleanValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2SetBoolean;

      function fmi2SetBooleanParameter
        input FMI2ModelExchange fmi2me;
        input Real booleanValueReferences[:];
        input Boolean booleanValues[size(booleanValueReferences, 1)];
        output Real out_Value = 1;
        external "C" fmi2SetBoolean_OMC(fmi2me, size(booleanValueReferences, 1), booleanValueReferences, booleanValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2SetBooleanParameter;

      function fmi2GetString
        input FMI2ModelExchange fmi2me;
        input Real stringValuesReferences[:];
        input Real inFlowStatesInput;
        output String stringValues[size(stringValuesReferences, 1)];
        external "C" fmi2GetString_OMC(fmi2me, size(stringValuesReferences, 1), stringValuesReferences, inFlowStatesInput, stringValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2GetString;

      function fmi2SetString
        input FMI2ModelExchange fmi2me;
        input Real stringValueReferences[:];
        input String stringValues[size(stringValueReferences, 1)];
        output String outValues[size(stringValueReferences, 1)] = stringValues;
        external "C" fmi2SetString_OMC(fmi2me, size(stringValueReferences, 1), stringValueReferences, stringValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2SetString;

      function fmi2SetStringParameter
        input FMI2ModelExchange fmi2me;
        input Real stringValueReferences[:];
        input String stringValues[size(stringValueReferences, 1)];
        output Real out_Value = 1;
        external "C" fmi2SetString_OMC(fmi2me, size(stringValueReferences, 1), stringValueReferences, stringValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2SetStringParameter;

      function fmi2EventUpdate
        input FMI2ModelExchange fmi2me;
        output Boolean outNewStatesAvailable;
        external "C" outNewStatesAvailable = fmi2EventUpdate_OMC(fmi2me) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2EventUpdate;

      function fmi2nextEventTime
        input FMI2ModelExchange fmi2me;
        input Real inFlowStates;
        output Real outNewnextTime;
        external "C" outNewnextTime = fmi2nextEventTime_OMC(fmi2me, inFlowStates) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2nextEventTime;

      function fmi2CompletedIntegratorStep
        input FMI2ModelExchange fmi2me;
        input Real inFlowStates;
        output Boolean outCallEventUpdate;
        external "C" outCallEventUpdate = fmi2CompletedIntegratorStep_OMC(fmi2me, inFlowStates) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi2CompletedIntegratorStep;
    end fmi2Functions;
  end <%fmiInfo.fmiModelIdentifier%>_<%getFMIType(fmiInfo)%>_FMU;
  >>
end importFMU2ModelExchange;

template importFMU1CoSimulationStandAlone(FmiImport fmi)
 "Generates Modelica code for FMI Co-simulation stand alone version 1.0"
::=
match fmi
case FMIIMPORT(fmiInfo=INFO(__),fmiExperimentAnnotation=EXPERIMENTANNOTATION(__)) then
  /* Get Real parameters and their value references */
  let realParametersVRs = dumpVariables(fmiModelVariablesList, "real", "parameter", false, 1, "1.0")
  let realParametersNames = dumpVariables(fmiModelVariablesList, "real", "parameter", false, 2, "1.0")
  /* Get Integer parameters and their value references */
  let integerParametersVRs = dumpVariables(fmiModelVariablesList, "integer", "parameter", false, 1, "1.0")
  let integerParametersNames = dumpVariables(fmiModelVariablesList, "integer", "parameter", false, 2, "1.0")
  /* Get Boolean parameters and their value references */
  let booleanParametersVRs = dumpVariables(fmiModelVariablesList, "boolean", "parameter", false, 1, "1.0")
  let booleanParametersNames = dumpVariables(fmiModelVariablesList, "boolean", "parameter", false, 2, "1.0")
  /* Get String parameters and their value references */
  let stringParametersVRs = dumpVariables(fmiModelVariablesList, "string", "parameter", false, 1, "1.0")
  let stringParametersNames = dumpVariables(fmiModelVariablesList, "string", "parameter", false, 2, "1.0")
  /* Get dependent Real parameters and their value references */
  let realDependentParametersVRs = dumpVariables(fmiModelVariablesList, "real", "parameter", true, 1, "1.0")
  let realDependentParametersNames = dumpVariables(fmiModelVariablesList, "real", "parameter", true, 2, "1.0")
  /* Get dependent Integer parameters and their value references */
  let integerDependentParametersVRs = dumpVariables(fmiModelVariablesList, "integer", "parameter", true, 1, "1.0")
  let integerDependentParametersNames = dumpVariables(fmiModelVariablesList, "integer", "parameter", true, 2, "1.0")
  /* Get dependent Boolean parameters and their value references */
  let booleanDependentParametersVRs = dumpVariables(fmiModelVariablesList, "boolean", "parameter", true, 1, "1.0")
  let booleanDependentParametersNames = dumpVariables(fmiModelVariablesList, "boolean", "parameter", true, 2, "1.0")
  /* Get dependent String parameters and their value references */
  let stringDependentParametersVRs = dumpVariables(fmiModelVariablesList, "string", "parameter", true, 1, "1.0")
  let stringDependentParametersNames = dumpVariables(fmiModelVariablesList, "string", "parameter", true, 2, "1.0")
  /* Get input Real varibales and their value references */
  let realInputVariablesVRs = dumpVariables(fmiModelVariablesList, "real", "input", false, 1, "1.0")
  let realInputVariablesNames = dumpVariables(fmiModelVariablesList, "real", "input", false, 2, "1.0")
  let realInputVariablesReturnNames = dumpVariables(fmiModelVariablesList, "real", "input", false, 3, "1.0")
  /* Get input Integer varibales and their value references */
  let integerInputVariablesVRs = dumpVariables(fmiModelVariablesList, "integer", "input", false, 1, "1.0")
  let integerInputVariablesNames = dumpVariables(fmiModelVariablesList, "integer", "input", false, 2, "1.0")
  let integerInputVariablesReturnNames = dumpVariables(fmiModelVariablesList, "integer", "input", false, 3, "1.0")
  /* Get input Boolean varibales and their value references */
  let booleanInputVariablesVRs = dumpVariables(fmiModelVariablesList, "boolean", "input", false, 1, "1.0")
  let booleanInputVariablesNames = dumpVariables(fmiModelVariablesList, "boolean", "input", false, 2, "1.0")
  let booleanInputVariablesReturnNames = dumpVariables(fmiModelVariablesList, "boolean", "input", false, 3, "1.0")
  /* Get input String varibales and their value references */
  let stringInputVariablesVRs = dumpVariables(fmiModelVariablesList, "string", "input", false, 1, "1.0")
  let stringStartVariablesNames = dumpVariables(fmiModelVariablesList, "string", "input", false, 2, "1.0")
  let stringInputVariablesReturnNames = dumpVariables(fmiModelVariablesList, "string", "input", false, 3, "1.0")
  /* Get output Real varibales and their value references */
  let realOutputVariablesVRs = dumpVariables(fmiModelVariablesList, "real", "output", false, 1, "1.0")
  let realOutputVariablesNames = dumpVariables(fmiModelVariablesList, "real", "output", false, 2, "1.0")
  /* Get output Integer varibales and their value references */
  let integerOutputVariablesVRs = dumpVariables(fmiModelVariablesList, "integer", "output", false, 1, "1.0")
  let integerOutputVariablesNames = dumpVariables(fmiModelVariablesList, "integer", "output", false, 2, "1.0")
  /* Get output Boolean varibales and their value references */
  let booleanOutputVariablesVRs = dumpVariables(fmiModelVariablesList, "boolean", "output", false, 1, "1.0")
  let booleanOutputVariablesNames = dumpVariables(fmiModelVariablesList, "boolean", "output", false, 2, "1.0")
  /* Get output String varibales and their value references */
  let stringOutputVariablesVRs = dumpVariables(fmiModelVariablesList, "string", "output", false, 1, "1.0")
  let stringOutputVariablesNames = dumpVariables(fmiModelVariablesList, "string", "output", false, 2, "1.0")
  <<
  model <%fmiInfo.fmiModelIdentifier%>_<%getFMIType(fmiInfo)%>_FMU<%if stringEq(fmiInfo.fmiDescription, "") then "" else " \""+fmiInfo.fmiDescription+"\""%>
    <%dumpFMITypeDefinitions(fmiTypeDefinitionsList)%>
    constant String fmuLocation = "file://<%fmuWorkingDirectory%>/resources";
    constant String fmuWorkingDir = "<%fmuWorkingDirectory%>";
    parameter Integer logLevel = <%fmiLogLevel%> "log level used during the loading of FMU" annotation (Dialog(tab="FMI", group="Enable logging"));
    parameter Boolean debugLogging = <%fmiDebugOutput%> "enables the FMU simulation logging" annotation (Dialog(tab="FMI", group="Enable logging"));
    constant String mimeType = "";
    constant Real timeout = 0.0;
    constant Boolean visible = false;
    constant Boolean interactive = false;
    parameter Real startTime = <%fmiExperimentAnnotation.fmiExperimentStartTime%> "start time used to initialize the slave" annotation (Dialog(tab="FMI", group="Step time"));
    parameter Real stopTime = <%fmiExperimentAnnotation.fmiExperimentStopTime%> "stop time used to initialize the slave" annotation (Dialog(tab="FMI", group="Step time"));
    parameter Real numberOfSteps = 500 annotation (Dialog(tab="FMI", group="Step time"));
    parameter Real communicationStepSize = (stopTime-startTime)/numberOfSteps "step size used by fmiDoStep" annotation (Dialog(tab="FMI", group="Step time"));
    constant Boolean stopTimeDefined = true;
    <%dumpFMIModelVariablesList("1.0", fmiModelVariablesList, fmiTypeDefinitionsList, generateInputConnectors, generateOutputConnectors)%>
  protected
    FMI1CoSimulation fmi1cs = FMI1CoSimulation(logLevel, fmuWorkingDir, "<%fmiInfo.fmiModelIdentifier%>", debugLogging, fmuLocation, mimeType, timeout, visible, interactive, startTime, stopTimeDefined, stopTime);
    parameter Real flowInitialized(fixed=false);
    Real flowStep;
    <%if not stringEq(realInputVariablesVRs, "") then "Real "+realInputVariablesReturnNames+";"%>
    <%if not stringEq(integerInputVariablesVRs, "") then "Integer "+integerInputVariablesReturnNames+";"%>
    <%if not stringEq(booleanInputVariablesVRs, "") then "Boolean "+booleanInputVariablesReturnNames+";"%>
    <%if not stringEq(stringInputVariablesVRs, "") then "String "+stringInputVariablesReturnNames+";"%>
  initial equation
    flowInitialized = fmi1Functions.fmi1InitializeSlave(fmi1cs, 1);
  equation
    <%if not boolAnd(stringEq(realOutputVariablesNames, ""), stringEq(realOutputVariablesVRs, "")) then "{"+realOutputVariablesNames+"} = fmi1Functions.fmi1GetReal(fmi1cs, {"+realOutputVariablesVRs+"}, flowInitialized);"%>
    <%if not boolAnd(stringEq(integerOutputVariablesNames, ""), stringEq(integerOutputVariablesVRs, "")) then "{"+integerOutputVariablesNames+"} = fmi1Functions.fmi1GetInteger(fmi1cs, {"+integerOutputVariablesVRs+"}, flowInitialized);"%>
    <%if not boolAnd(stringEq(booleanOutputVariablesNames, ""), stringEq(booleanOutputVariablesVRs, "")) then "{"+booleanOutputVariablesNames+"} = fmi1Functions.fmi1GetBoolean(fmi1cs, {"+booleanOutputVariablesVRs+"}, flowInitialized);"%>
    <%if not boolAnd(stringEq(stringOutputVariablesNames, ""), stringEq(stringOutputVariablesVRs, "")) then "{"+stringOutputVariablesNames+"} = fmi1Functions.fmi1GetString(fmi1cs, {"+stringOutputVariablesVRs+"}, flowInitialized);"%>
    <%if not stringEq(realInputVariablesVRs, "") then "{"+realInputVariablesReturnNames+"} = fmi1Functions.fmi1SetReal(fmi1cs, {"+realInputVariablesVRs+"}, {"+realInputVariablesNames+"});"%>
    <%if not stringEq(integerInputVariablesVRs, "") then "{"+integerInputVariablesReturnNames+"} = fmi1Functions.fmi1SetInteger(fmi1cs, {"+integerInputVariablesVRs+"}, {"+integerInputVariablesNames+"});"%>
    <%if not stringEq(booleanInputVariablesVRs, "") then "{"+booleanInputVariablesReturnNames+"} = fmi1Functions.fmi1SetBoolean(fmi1cs, {"+booleanInputVariablesVRs+"}, {"+booleanInputVariablesNames+"});"%>
    <%if not stringEq(stringInputVariablesVRs, "") then "{"+stringInputVariablesReturnNames+"} = fmi1Functions.fmi1SetString(fmi1cs, {"+stringInputVariablesVRs+"}, {"+stringStartVariablesNames+"});"%>
    flowStep = fmi1Functions.fmi1DoStep(fmi1cs, time, communicationStepSize, true, flowInitialized);
    annotation(experiment(StartTime=<%fmiExperimentAnnotation.fmiExperimentStartTime%>, StopTime=<%fmiExperimentAnnotation.fmiExperimentStopTime%>, Tolerance=<%fmiExperimentAnnotation.fmiExperimentTolerance%>));
    annotation (Icon(graphics={
        Rectangle(
          extent={{-100,100},{100,-100}},
          lineColor={0,0,0},
          fillColor={240,240,240},
          fillPattern=FillPattern.Solid,
          lineThickness=0.5),
        Text(
          extent={{-100,40},{100,0}},
          lineColor={0,0,0},
          textString="%name"),
        Text(
          extent={{-100,-50},{100,-90}},
          lineColor={0,0,0},
          textString="V1.0")}));
  protected
    class FMI1CoSimulation
      extends ExternalObject;
        function constructor
          input Integer fmiLogLevel;
          input String workingDirectory;
          input String instanceName;
          input Boolean debugLogging;
          input String fmuLocation;
          input String mimeType;
          input Real timeOut;
          input Boolean visible;
          input Boolean interactive;
          input Real tStart;
          input Boolean stopTimeDefined;
          input Real tStop;
          output FMI1CoSimulation fmi1cs;
          external "C" fmi1cs = FMI1CoSimulationConstructor_OMC(fmiLogLevel, workingDirectory, instanceName, debugLogging, fmuLocation, mimeType, timeOut, visible, interactive, tStart, stopTimeDefined, tStop) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
        end constructor;

        function destructor
          input FMI1CoSimulation fmi1cs;
          external "C" FMI1CoSimulationDestructor_OMC(fmi1cs) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
        end destructor;
    end FMI1CoSimulation;

    <%dumpFMITypeDefinitionsMappingFunctions(fmiTypeDefinitionsList)%>

    <%dumpFMITypeDefinitionsArrayMappingFunctions(fmiTypeDefinitionsList)%>

    package fmi1Functions
      function fmi1InitializeSlave
        input FMI1CoSimulation fmi1cs;
        input Real preInitialized;
        output Real postInitialized=preInitialized;
        external "C" fmi1InitializeSlave_OMC(fmi1cs) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1InitializeSlave;

      function fmi1DoStep
        input FMI1CoSimulation fmi1cs;
        input Real currentCommunicationPoint;
        input Real communicationStepSize;
        input Boolean newStep;
        input Real preInitialized;
        output Real postInitialized=preInitialized;
        external "C" fmi1DoStep_OMC(fmi1cs, currentCommunicationPoint, communicationStepSize, newStep) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1DoStep;

      function fmi1GetReal
        input FMI1CoSimulation fmi1cs;
        input Real realValuesReferences[:];
        input Real inFlowStatesInput;
        output Real realValues[size(realValuesReferences, 1)];
        external "C" fmi1GetReal_OMC(fmi1cs, size(realValuesReferences, 1), realValuesReferences, inFlowStatesInput, realValues, 2) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1GetReal;

      function fmi1SetReal
        input FMI1CoSimulation fmi1cs;
        input Real realValuesReferences[:];
        input Real realValues[size(realValuesReferences, 1)];
        output Real out_Values[size(realValuesReferences, 1)];
        external "C" fmi1SetReal_OMC(fmi1cs, size(realValuesReferences, 1), realValuesReferences, realValues, out_Values, 2) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1SetReal;

      function fmi1GetInteger
        input FMI1CoSimulation fmi1cs;
        input Real integerValuesReferences[:];
        input Real inFlowStatesInput;
        output Integer integerValues[size(integerValuesReferences, 1)];
        external "C" fmi1GetInteger_OMC(fmi1cs, size(integerValuesReferences, 1), integerValuesReferences, inFlowStatesInput, integerValues, 2) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1GetInteger;

      function fmi1SetInteger
        input FMI1CoSimulation fmi1cs;
        input Real integerValuesReferences[:];
        input Integer integerValues[size(integerValuesReferences, 1)];
        output Real out_Values[size(integerValuesReferences, 1)];
        external "C" fmi1SetInteger_OMC(fmi1cs, size(integerValuesReferences, 1), integerValuesReferences, integerValues, out_Values, 2) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1SetInteger;

      function fmi1GetBoolean
        input FMI1CoSimulation fmi1cs;
        input Real booleanValuesReferences[:];
        input Real inFlowStatesInput;
        output Boolean booleanValues[size(booleanValuesReferences, 1)];
        external "C" fmi1GetBoolean_OMC(fmi1cs, size(booleanValuesReferences, 1), booleanValuesReferences, inFlowStatesInput, booleanValues, 2) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1GetBoolean;

      function fmi1SetBoolean
        input FMI1CoSimulation fmi1cs;
        input Real booleanValuesReferences[:];
        input Boolean booleanValues[size(booleanValuesReferences, 1)];
        output Boolean out_Values[size(booleanValuesReferences, 1)];
        external "C" fmi1SetBoolean_OMC(fmi1cs, size(booleanValuesReferences, 1), booleanValuesReferences, booleanValues, out_Values, 2) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1SetBoolean;

      function fmi1GetString
        input FMI1CoSimulation fmi1cs;
        input Real stringValuesReferences[:];
        input Real inFlowStatesInput;
        output String stringValues[size(stringValuesReferences, 1)];
        external "C" fmi1GetString_OMC(fmi1cs, size(stringValuesReferences, 1), stringValuesReferences, inFlowStatesInput, stringValues, 2) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1GetString;

      function fmi1SetString
        input FMI1CoSimulation fmi1cs;
        input Real stringValuesReferences[:];
        input String stringValues[size(stringValuesReferences, 1)];
        output String out_Values[size(stringValuesReferences, 1)];
        external "C" fmi1SetString_OMC(fmi1cs, size(stringValuesReferences, 1), stringValuesReferences, stringValues, out_Values, 2) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end fmi1SetString;
    end fmi1Functions;
  end <%fmiInfo.fmiModelIdentifier%>_<%getFMIType(fmiInfo)%>_FMU;
  >>
end importFMU1CoSimulationStandAlone;

template dumpFMITypeDefinitions(list<TypeDefinitions> fmiTypeDefinitionsList)
 "Generates the Type Definitions code."
::=
  <<
  <%fmiTypeDefinitionsList |> fmiTypeDefinition => dumpFMITypeDefinition(fmiTypeDefinition) ;separator="\n"%>
  >>
end dumpFMITypeDefinitions;

template dumpFMITypeDefinition(TypeDefinitions fmiTypeDefinition)
 "Generates the Type code."
::=
match fmiTypeDefinition
case ENUMERATIONTYPE(__) then
  <<
  type <%name%> = enumeration(
    <%dumpFMITypeDefinitionsItems(items)%>);
  >>
end dumpFMITypeDefinition;

template dumpFMITypeDefinitionsItems(list<EnumerationItem> items)
 "Generates the Enumeration Type items code."
::=
  <<
  <%items |> item => dumpFMITypeDefinitionsItem(item) ;separator=",\n"%>
  >>
end dumpFMITypeDefinitionsItems;

template dumpFMITypeDefinitionsItem(EnumerationItem item)
 "Generates the Enumeration Type item name."
::=
match item
case ENUMERATIONITEM(__) then
  <<
  <%name%>
  >>
end dumpFMITypeDefinitionsItem;

template dumpFMITypeDefinitionsMappingFunctions(list<TypeDefinitions> fmiTypeDefinitionsList)
 "Generates the mapping functions for all enumeration types."
::=
  <<
  <%fmiTypeDefinitionsList |> fmiTypeDefinition => dumpFMITypeDefinitionMappingFunction(fmiTypeDefinition) ;separator="\n"%>
  >>
end dumpFMITypeDefinitionsMappingFunctions;

template dumpFMITypeDefinitionMappingFunction(TypeDefinitions fmiTypeDefinition)
 "Generates the mapping function from integer to enumeration type."
::=
match fmiTypeDefinition
case ENUMERATIONTYPE(__) then
  <<
  function map_<%name%>_from_integer
    input Integer i;
    output <%name%> outType;
  algorithm
    <%items |> item hasindex i0 fromindex 1 => dumpFMITypeDefinitionMappingFunctionItems(item, name, i0) ;separator="\n"%>
    <%if intGt(listLength(items), 1) then "end if;"%>
  end map_<%name%>_from_integer;
  >>
end dumpFMITypeDefinitionMappingFunction;

template dumpFMITypeDefinitionMappingFunctionItems(EnumerationItem item, String typeName, Integer i)
 "Dumps the mapping function conditions. This is closely related to dumpFMITypeDefinitionMappingFunction."
::=
match item
case ENUMERATIONITEM(__) then
  if intEq(i, 1) then
  <<
  if i == <%i%> then outType := <%typeName%>.<%name%>;
  >>
  else
  <<
  elseif i == <%i%> then outType := <%typeName%>.<%name%>;
  >>
end dumpFMITypeDefinitionMappingFunctionItems;

template dumpFMITypeDefinitionsArrayMappingFunctions(list<TypeDefinitions> fmiTypeDefinitionsList)
 "Generates the array mapping functions for all enumeration types."
::=
  <<
  <%fmiTypeDefinitionsList |> fmiTypeDefinition => dumpFMITypeDefinitionsArrayMappingFunction(fmiTypeDefinition) ;separator="\n"%>
  >>
end dumpFMITypeDefinitionsArrayMappingFunctions;

template dumpFMITypeDefinitionsArrayMappingFunction(TypeDefinitions fmiTypeDefinition)
 "Generates the mapping function from integer to enumeration type."
::=
match fmiTypeDefinition
case ENUMERATIONTYPE(__) then
  <<
  function map_<%name%>_from_integers
    input Integer fromInt[size(fromInt, 1)];
    output <%name%> toEnum[size(fromInt, 1)];
  protected
    Integer n = size(fromInt, 1);
  algorithm
    for i in 1:n loop
      toEnum[i] := map_<%name%>_from_integer(fromInt[i]);
    end for;
  end map_<%name%>_from_integers;
  >>
end dumpFMITypeDefinitionsArrayMappingFunction;

template dumpFMIModelVariablesList(String FMUVersion, list<ModelVariables> fmiModelVariablesList, list<TypeDefinitions> fmiTypeDefinitionsList, Boolean generateInputConnectors, Boolean generateOutputConnectors)
 "Generates the Model Variables code."
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpFMIModelVariable(FMUVersion, fmiModelVariable, fmiTypeDefinitionsList, generateInputConnectors, generateOutputConnectors) ;separator="\n"%>
  >>
end dumpFMIModelVariablesList;

template dumpFMIModelVariable(String FMUVersion, ModelVariables fmiModelVariable, list<TypeDefinitions> fmiTypeDefinitionsList, Boolean generateInputConnectors, Boolean generateOutputConnectors)
::=
match FMUVersion
case "1.0" then
  match fmiModelVariable
  case REALVARIABLE(__) then
    <<
    <%dumpFMIModelVariableVariability(variability)%><%dumpFMIModelVariableCausalityAndBaseType(causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%name%><%dumpFMIRealModelVariableStartValue(FMUVersion, variability, hasStartValue, startValue, isFixed)%><%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
    >>
  case INTEGERVARIABLE(__) then
    <<
    <%dumpFMIModelVariableVariability(variability)%><%dumpFMIModelVariableCausalityAndBaseType(causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%name%><%dumpFMIIntegerModelVariableStartValue(FMUVersion, variability, hasStartValue, startValue, isFixed)%><%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
    >>
  case BOOLEANVARIABLE(__) then
    <<
    <%dumpFMIModelVariableVariability(variability)%><%dumpFMIModelVariableCausalityAndBaseType(causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%name%><%dumpFMIBooleanModelVariableStartValue(FMUVersion, variability, hasStartValue, startValue, isFixed)%><%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
    >>
  case STRINGVARIABLE(__) then
    <<
    <%dumpFMIModelVariableVariability(variability)%><%dumpFMIModelVariableCausalityAndBaseType(causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%name%><%dumpFMIStringModelVariableStartValue(FMUVersion, variability, hasStartValue, startValue, isFixed)%><%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
    >>
  case ENUMERATIONVARIABLE(__) then
    <<
    <%dumpFMIModelVariableVariability(variability)%><%dumpFMIModelVariableCausalityAndBaseType(causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%name%><%dumpFMIEnumerationModelVariableStartValue(fmiTypeDefinitionsList, baseType, hasStartValue, startValue, isFixed)%><%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
    >>
  end match
case "2.0" then
  match fmiModelVariable
  case REALVARIABLE(__) then
    <<
    <%dumpFMIModelVariableVariability(variability)%><%dumpFMIModelVariableCausalityAndBaseType(causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%name%><%dumpFMIRealModelVariableStartValue(FMUVersion, causality, hasStartValue, startValue, isFixed)%><%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
    >>
  case INTEGERVARIABLE(__) then
    <<
    <%dumpFMIModelVariableVariability(variability)%><%dumpFMIModelVariableCausalityAndBaseType(causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%name%><%dumpFMIIntegerModelVariableStartValue(FMUVersion, causality, hasStartValue, startValue, isFixed)%><%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
    >>
  case BOOLEANVARIABLE(__) then
    <<
    <%dumpFMIModelVariableVariability(variability)%><%dumpFMIModelVariableCausalityAndBaseType(causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%name%><%dumpFMIBooleanModelVariableStartValue(FMUVersion, causality, hasStartValue, startValue, isFixed)%><%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
    >>
  case STRINGVARIABLE(__) then
    <<
    <%dumpFMIModelVariableVariability(variability)%><%dumpFMIModelVariableCausalityAndBaseType(causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%name%><%dumpFMIStringModelVariableStartValue(FMUVersion, causality, hasStartValue, startValue, isFixed)%><%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
    >>
  case ENUMERATIONVARIABLE(__) then
    <<
    <%dumpFMIModelVariableVariability(variability)%><%dumpFMIModelVariableCausalityAndBaseType(causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%name%><%dumpFMIEnumerationModelVariableStartValue(fmiTypeDefinitionsList, baseType, hasStartValue, startValue, isFixed)%><%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
    >>
  end match
end dumpFMIModelVariable;

template dumpFMIModelVariableVariability(String variability)
::=
  <<
  <%if stringEq(variability, "") then "" else variability+" "%>
  >>
end dumpFMIModelVariableVariability;

template dumpFMIModelVariableCausalityAndBaseType(String causality, String baseType, Boolean generateInputConnectors, Boolean generateOutputConnectors)
::=
  if boolAnd(generateInputConnectors, boolAnd(stringEq(causality, "input"),stringEq(baseType, "Real"))) then "Modelica.Blocks.Interfaces.RealInput"
  else if boolAnd(generateInputConnectors, boolAnd(stringEq(causality, "input"),stringEq(baseType, "Integer"))) then "Modelica.Blocks.Interfaces.IntegerInput"
  else if boolAnd(generateInputConnectors, boolAnd(stringEq(causality, "input"),stringEq(baseType, "Boolean"))) then "Modelica.Blocks.Interfaces.BooleanInput"
  else if boolAnd(generateOutputConnectors, boolAnd(stringEq(causality, "output"),stringEq(baseType, "Real"))) then "Modelica.Blocks.Interfaces.RealOutput"
  else if boolAnd(generateOutputConnectors, boolAnd(stringEq(causality, "output"),stringEq(baseType, "Integer"))) then "Modelica.Blocks.Interfaces.IntegerOutput"
  else if boolAnd(generateOutputConnectors, boolAnd(stringEq(causality, "output"),stringEq(baseType, "Boolean"))) then "Modelica.Blocks.Interfaces.BooleanOutput"
  else if stringEq(causality, "") then baseType else causality+" "+baseType
end dumpFMIModelVariableCausalityAndBaseType;

template dumpFMIModelVariableCausality(String causality)
::=
  <<
  <%if stringEq(causality, "") then "" else causality+" "%>
  >>
end dumpFMIModelVariableCausality;

template dumpFMIRealModelVariableStartValue(String FMUVersion, String variabilityCausality, Boolean hasStartValue, Real startValue, Boolean isFixed)
::=
match FMUVersion
case "1.0" then
  match variabilityCausality
  case "parameter" then
    if boolAnd(hasStartValue,isFixed) then " = "+startValue
    else if boolAnd(hasStartValue,boolNot(isFixed)) then "(start="+startValue+",fixed=false)"
    else if boolAnd(boolNot(hasStartValue),isFixed) then "(fixed=true)"
    else if boolAnd(boolNot(hasStartValue),boolNot(isFixed)) then "(fixed=false)"
  case "" then
    if boolAnd(hasStartValue,boolNot(isFixed)) then "(start="+startValue+",fixed=false)"
  end match
case "2.0" then
  match variabilityCausality
  case "parameter" then
    if boolAnd(hasStartValue,isFixed) then " = "+startValue
    else if boolAnd(hasStartValue,boolNot(isFixed)) then "(start="+startValue+",fixed=false)"
    else if boolAnd(boolNot(hasStartValue),isFixed) then "(fixed=true)"
    else if boolAnd(boolNot(hasStartValue),boolNot(isFixed)) then "(fixed=false)"
  else
    if boolAnd(hasStartValue,boolNot(isFixed)) then "(start="+startValue+",fixed=false)"
end dumpFMIRealModelVariableStartValue;

template dumpFMIIntegerModelVariableStartValue(String FMUVersion, String variabilityCausality, Boolean hasStartValue, Integer startValue, Boolean isFixed)
::=
match FMUVersion
case "1.0" then
  match variabilityCausality
  case "parameter" then
    if boolAnd(hasStartValue,isFixed) then " = "+startValue
    else if boolAnd(hasStartValue,boolNot(isFixed)) then "(start="+startValue+",fixed=false)"
    else if boolAnd(boolNot(hasStartValue),isFixed) then "(fixed=true)"
    else if boolAnd(boolNot(hasStartValue),boolNot(isFixed)) then "(fixed=false)"
  case "" then
    if boolAnd(hasStartValue,boolNot(isFixed)) then "(start="+startValue+",fixed=false)"
  end match
case "2.0" then
  match variabilityCausality
  case "parameter" then
    if boolAnd(hasStartValue,isFixed) then " = "+startValue
    else if boolAnd(hasStartValue,boolNot(isFixed)) then "(start="+startValue+",fixed=false)"
    else if boolAnd(boolNot(hasStartValue),isFixed) then "(fixed=true)"
    else if boolAnd(boolNot(hasStartValue),boolNot(isFixed)) then "(fixed=false)"
  else
    if boolAnd(hasStartValue,boolNot(isFixed)) then "(start="+startValue+",fixed=false)"
end dumpFMIIntegerModelVariableStartValue;

template dumpFMIBooleanModelVariableStartValue(String FMUVersion, String variabilityCausality, Boolean hasStartValue, Boolean startValue, Boolean isFixed)
::=
match FMUVersion
case "1.0" then
  match variabilityCausality
  case "parameter" then
    if boolAnd(hasStartValue,isFixed) then " = "+startValue
    else if boolAnd(hasStartValue,boolNot(isFixed)) then "(start="+startValue+",fixed=false)"
    else if boolAnd(boolNot(hasStartValue),isFixed) then "(fixed=true)"
    else if boolAnd(boolNot(hasStartValue),boolNot(isFixed)) then "(fixed=false)"
  case "" then
    if boolAnd(hasStartValue,boolNot(isFixed)) then "(start="+startValue+",fixed=false)"
  end match
case "2.0" then
  match variabilityCausality
  case "parameter" then
    if boolAnd(hasStartValue,isFixed) then " = "+startValue
    else if boolAnd(hasStartValue,boolNot(isFixed)) then "(start="+startValue+",fixed=false)"
    else if boolAnd(boolNot(hasStartValue),isFixed) then "(fixed=true)"
    else if boolAnd(boolNot(hasStartValue),boolNot(isFixed)) then "(fixed=false)"
  else
    if boolAnd(hasStartValue,boolNot(isFixed)) then "(start="+startValue+",fixed=false)"
end dumpFMIBooleanModelVariableStartValue;

template dumpFMIStringModelVariableStartValue(String FMUVersion, String variabilityCausality, Boolean hasStartValue, String startValue, Boolean isFixed)
::=
match FMUVersion
case "1.0" then
  match variabilityCausality
  case "parameter" then
    if boolAnd(hasStartValue,isFixed) then " = \""+startValue+"\""
    /* If we set fixed=false, we generate bad code; let make OM handle the bad values */
    else if boolAnd(hasStartValue,boolNot(isFixed)) then "(start=\""+startValue+"\")"
    else if boolAnd(boolNot(hasStartValue),isFixed) then "(fixed=true)"
    else if boolAnd(boolNot(hasStartValue),boolNot(isFixed)) then "(fixed=false)"
  case "" then
    if boolAnd(hasStartValue,boolNot(isFixed)) then "(start=\""+startValue+"\",fixed=false)"
  end match
case "2.0" then
  match variabilityCausality
  case "parameter" then
    if boolAnd(hasStartValue,isFixed) then " = \""+startValue+"\""
    else if boolAnd(hasStartValue,boolNot(isFixed)) then "(start=\""+startValue+"\",fixed=false)"
    else if boolAnd(boolNot(hasStartValue),isFixed) then "(fixed=true)"
    else if boolAnd(boolNot(hasStartValue),boolNot(isFixed)) then "(fixed=false)"
  else
    if boolAnd(hasStartValue,boolNot(isFixed)) then "(start=\""+startValue+"\",fixed=false)"
end dumpFMIStringModelVariableStartValue;

template dumpFMIEnumerationModelVariableStartValue(list<TypeDefinitions> fmiTypeDefinitionsList, String baseType, Boolean hasStartValue, Integer startValue, Boolean isFixed)
::=
  <<
  <%if hasStartValue then " = map_" + getEnumerationTypeFromTypes(fmiTypeDefinitionsList, baseType) + "_from_integer(" + startValue + ")"%>
  >>
end dumpFMIEnumerationModelVariableStartValue;

template dumpFMIModelVariableDescription(String description)
::=
  <<
  <%if stringEq(description, "") then "" else " \""+description+"\""%>
  >>
end dumpFMIModelVariableDescription;

template dumpFMIModelVariablePlacementAnnotation(Integer x1Placement, Integer x2Placement, Integer y1Placement, Integer y2Placement, Boolean generateInputConnectors, Boolean generateOutputConnectors, String causality)
::=
  if boolAnd(generateInputConnectors, stringEq(causality, "input")) then " annotation(Placement(transformation(extent={{"+x1Placement+","+y1Placement+"},{"+x2Placement+","+y2Placement+"}})))"
  else if boolAnd(generateOutputConnectors, stringEq(causality, "output")) then " annotation(Placement(transformation(extent={{"+x1Placement+","+y1Placement+"},{"+x2Placement+","+y2Placement+"}})))"
end dumpFMIModelVariablePlacementAnnotation;

template dumpVariables(list<ModelVariables> fmiModelVariablesList, String type, String variabilityCausality, Boolean dependent, Integer what, String fmiVersion)
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpVariable(fmiModelVariable, type, variabilityCausality, dependent, what, fmiVersion) ;separator=", "%>
  >>
end dumpVariables;

template dumpVariable(ModelVariables fmiModelVariable, String type, String variabilityCausality, Boolean dependent, Integer what, String fmiVersion)
::=
if boolAnd(stringEq(type, "real"), (boolAnd(stringEq(variabilityCausality, "parameter"), boolNot(dependent)))) then
<<
<%
if stringEq(fmiVersion,"1.0") then
match fmiModelVariable
  case REALVARIABLE(variability="parameter", hasStartValue=true) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
end match
else if stringEq(fmiVersion,"2.0") then
  match fmiModelVariable
  case REALVARIABLE(causality="parameter", hasStartValue=true) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
%>
>>
else if boolAnd(stringEq(type, "integer"), (boolAnd(stringEq(variabilityCausality, "parameter"), boolNot(dependent)))) then
<<
<%
if stringEq(fmiVersion,"1.0") then
match fmiModelVariable
  case INTEGERVARIABLE(variability="parameter", hasStartValue=true) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
end match
else if stringEq(fmiVersion,"2.0") then
match fmiModelVariable
  case INTEGERVARIABLE(causality="parameter", hasStartValue=true) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
%>
>>
else if boolAnd(stringEq(type, "boolean"), (boolAnd(stringEq(variabilityCausality, "parameter"), boolNot(dependent)))) then
<<
<%
if stringEq(fmiVersion,"1.0") then
match fmiModelVariable
  case BOOLEANVARIABLE(variability="parameter", hasStartValue=true) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
end match
else if stringEq(fmiVersion,"2.0") then
match fmiModelVariable
  case BOOLEANVARIABLE(causality="parameter", hasStartValue=true) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
%>
>>
else if boolAnd(stringEq(type, "string"), (boolAnd(stringEq(variabilityCausality, "parameter"), boolNot(dependent)))) then
<<
<%
if stringEq(fmiVersion,"1.0") then
match fmiModelVariable
  case STRINGVARIABLE(variability="parameter", hasStartValue=true) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
end match
else if stringEq(fmiVersion,"2.0") then
match fmiModelVariable
  case STRINGVARIABLE(causality="parameter", hasStartValue=true) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
%>
>>
else if boolAnd(stringEq(type, "real"), (boolAnd(stringEq(variabilityCausality, "parameter"), dependent))) then
<<
<%
if stringEq(fmiVersion,"1.0") then
match fmiModelVariable
  case REALVARIABLE(variability="parameter",  hasStartValue=false, isFixed=false) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
end match
else if stringEq(fmiVersion,"2.0") then
match fmiModelVariable
  case REALVARIABLE(causality="parameter", hasStartValue=false, isFixed=false) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
%>
>>
else if boolAnd(stringEq(type, "integer"), (boolAnd(stringEq(variabilityCausality, "parameter"), dependent))) then
<<
<%
if stringEq(fmiVersion,"1.0") then
match fmiModelVariable
  case INTEGERVARIABLE(variability="parameter",  hasStartValue=false, isFixed=false) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
end match
else if stringEq(fmiVersion,"2.0") then
match fmiModelVariable
  case INTEGERVARIABLE(causality="parameter", hasStartValue=false, isFixed=false) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
%>
>>
else if boolAnd(stringEq(type, "boolean"), (boolAnd(stringEq(variabilityCausality, "parameter"), dependent))) then
<<
<%
if stringEq(fmiVersion,"1.0") then
match fmiModelVariable
  case BOOLEANVARIABLE(variability="parameter",  hasStartValue=false, isFixed=false) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
end match
else if stringEq(fmiVersion,"2.0") then
match fmiModelVariable
  case BOOLEANVARIABLE(causality="parameter", hasStartValue=false, isFixed=false) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
%>
>>
else if boolAnd(stringEq(type, "string"), (boolAnd(stringEq(variabilityCausality, "parameter"), dependent))) then
<<
<%
if stringEq(fmiVersion,"1.0") then
match fmiModelVariable
  case STRINGVARIABLE(variability="parameter",  hasStartValue=false, isFixed=false) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
end match
else if stringEq(fmiVersion,"2.0") then
match fmiModelVariable
  case STRINGVARIABLE(causality="parameter", hasStartValue=false, isFixed=false) then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
%>
>>
else if boolAnd(stringEq(type, "real"), stringEq(variabilityCausality, "input")) then
<<
<%
match fmiModelVariable
  case REALVARIABLE(causality="input") then
    if intEq(what,1) then valueReference else if intEq(what,2) then name else if intEq(what,3) then "fmi_input_"+name
%>
>>
else if boolAnd(stringEq(type, "integer"), stringEq(variabilityCausality, "input")) then
<<
<%
match fmiModelVariable
  case INTEGERVARIABLE(causality="input") then
    if intEq(what,1) then valueReference else if intEq(what,2) then name else if intEq(what,3) then "fmi_input_"+name
%>
>>
else if boolAnd(stringEq(type, "boolean"), stringEq(variabilityCausality, "input")) then
<<
<%
match fmiModelVariable
  case BOOLEANVARIABLE(causality="input") then
    if intEq(what,1) then valueReference else if intEq(what,2) then name else if intEq(what,3) then "fmi_input_"+name
%>
>>
else if boolAnd(stringEq(type, "string"), stringEq(variabilityCausality, "input")) then
<<
<%
match fmiModelVariable
  case STRINGVARIABLE(causality="input") then
    if intEq(what,1) then valueReference else if intEq(what,2) then name else if intEq(what,3) then "fmi_input_"+name
%>
>>
else if boolAnd(stringEq(type, "real"), stringEq(variabilityCausality, "output")) then
<<
<%
match fmiModelVariable
  case REALVARIABLE(variability = "",causality="") then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
  case REALVARIABLE(variability = "",causality="output") then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
%>
>>
else if boolAnd(stringEq(type, "integer"), stringEq(variabilityCausality, "output")) then
<<
<%
match fmiModelVariable
  case INTEGERVARIABLE(variability = "",causality="") then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
  case INTEGERVARIABLE(variability = "",causality="output") then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
%>
>>
else if boolAnd(stringEq(type, "boolean"), stringEq(variabilityCausality, "output")) then
<<
<%
match fmiModelVariable
  case BOOLEANVARIABLE(variability = "",causality="") then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
  case BOOLEANVARIABLE(variability = "",causality="output") then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
%>
>>
else if boolAnd(stringEq(type, "string"), stringEq(variabilityCausality, "output")) then
<<
<%
match fmiModelVariable
  case STRINGVARIABLE(variability = "",causality="") then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
  case STRINGVARIABLE(variability = "",causality="output") then
    if intEq(what,1) then valueReference else if intEq(what,2) then name
%>
>>
end dumpVariable;

template dumpOutputGetEnumerationVariables(list<ModelVariables> fmiModelVariablesList, list<TypeDefinitions> fmiTypeDefinitionsList, String fmiGetFunction, String fmiType)
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpOutputGetEnumerationVariable(fmiModelVariable, fmiTypeDefinitionsList, fmiGetFunction, fmiType)%>
  >>
end dumpOutputGetEnumerationVariables;

template dumpOutputGetEnumerationVariable(ModelVariables fmiModelVariable, list<TypeDefinitions> fmiTypeDefinitionsList, String fmiGetFunction, String fmiType)
::=
match fmiModelVariable
case ENUMERATIONVARIABLE(variability = "",causality="") then
  <<
  {<%name%>} = map_<%getEnumerationTypeFromTypes(fmiTypeDefinitionsList, baseType)%>_from_integers(<%fmiGetFunction%>(<%fmiType%>, {<%valueReference%>}, flowStatesInputs));<%\n%>
  >>
case ENUMERATIONVARIABLE(variability = "",causality="output") then
  <<
  {<%name%>} = map_<%getEnumerationTypeFromTypes(fmiTypeDefinitionsList, baseType)%>_from_integers(<%fmiGetFunction%>(<%fmiType%>, {<%valueReference%>}, flowStatesInputs));<%\n%>
  >>
end dumpOutputGetEnumerationVariable;

/* public */ template simulationInitFunction(SimCode simCode, String guid)
 "Generates the contents of the makefile for the simulation case.
  used in Compiler/Template/CodegenFMU.tpl"
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(functions = functions, varInfo = vi as VARINFO(__), vars = vars as SIMVARS(__)),
             simulationSettingsOpt = SOME(s as SIMULATION_SETTINGS(__)), makefileParams = makefileParams as MAKEFILE_PARAMS(__))
  then
  <<
  #include "simulation_data.h"

  OMC_DISABLE_OPT<%/* This function is very simple and doesn't need to be optimized. GCC/clang spend way too much time looking at it. */%>
  void <%symbolName(modelNamePrefix(simCode),"read_input_fmu")%>(MODEL_DATA* modelData, SIMULATION_INFO* simulationInfo)
  {
    simulationInfo->startTime = <%s.startTime%>;
    simulationInfo->stopTime = <%s.stopTime%>;
    simulationInfo->stepSize = <%s.stepSize%>;
    simulationInfo->tolerance = <%s.tolerance%>;
    simulationInfo->solverMethod = "<%s.method%>";
    simulationInfo->outputFormat = "<%s.outputFormat%>";
    simulationInfo->variableFilter = "<%s.variableFilter%>";
    simulationInfo->OPENMODELICAHOME = "<%makefileParams.omhome%>";
    <%System.tmpTickReset(1000)%>
    <%System.tmpTickResetIndex(0,2)%>
    <%vars.stateVars       |> var => ScalarVariableFMU(var,"realVarsData") ;separator="\n";empty%>
    <%vars.derivativeVars  |> var => ScalarVariableFMU(var,"realVarsData") ;separator="\n";empty%>
    <%vars.algVars         |> var => ScalarVariableFMU(var,"realVarsData") ;separator="\n";empty%>
    <%vars.discreteAlgVars |> var => ScalarVariableFMU(var,"realVarsData") ;separator="\n";empty%>
    <%vars.realOptimizeConstraintsVars
                           |> var => ScalarVariableFMU(var,"realVarsData") ;separator="\n";empty%>
    <%vars.realOptimizeFinalConstraintsVars
                           |> var => ScalarVariableFMU(var,"realVarsData") ;separator="\n";empty%>
    <%System.tmpTickResetIndex(0,2)%>
    <%vars.paramVars       |> var => ScalarVariableFMU(var,"realParameterData") ;separator="\n";empty%>
    <%System.tmpTickResetIndex(0,2)%>
    <%vars.intAlgVars      |> var => ScalarVariableFMU(var,"integerVarsData") ;separator="\n";empty%>
    <%System.tmpTickResetIndex(0,2)%>
    <%vars.intParamVars    |> var => ScalarVariableFMU(var,"integerParameterData") ;separator="\n";empty%>
    <%System.tmpTickResetIndex(0,2)%>
    <%vars.boolAlgVars     |> var => ScalarVariableFMU(var,"booleanVarsData") ;separator="\n";empty%>
    <%System.tmpTickResetIndex(0,2)%>
    <%vars.boolParamVars   |> var => ScalarVariableFMU(var,"booleanParameterData") ;separator="\n";empty%>
    <%System.tmpTickResetIndex(0,2)%>
    <%vars.stringAlgVars   |> var => ScalarVariableFMU(var,"stringVarsData") ;separator="\n";empty%>
    <%System.tmpTickResetIndex(0,2)%>
    <%vars.stringParamVars |> var => ScalarVariableFMU(var,"stringParameterData") ;separator="\n";empty%>
    <%System.tmpTickResetIndex(0,2)%>
    <%
    /* Skip these; shouldn't be needed to look at in the FMU
    <%vars.aliasVars       |> var => ScalarVariableFMU(var,"realAlias") ;separator="\n";empty%>
    <%System.tmpTickResetIndex(0,2)%>
    <%vars.intAliasVars    |> var => ScalarVariableFMU(var,"integerAlias") ;separator="\n";empty%>
    <%System.tmpTickResetIndex(0,2)%>
    <%vars.boolAliasVars   |> var => ScalarVariableFMU(var,"booleanAlias") ;separator="\n";empty%>
    <%System.tmpTickResetIndex(0,2)%>
    <%vars.stringAliasVars |> var => ScalarVariableFMU(var,"stringAlias") ;separator="\n";empty%>
    <%System.tmpTickResetIndex(0,2)%>
    */
    %>
  }
  >>
end simulationInitFunction;

template getInfoArgsFMU(String str, builtin.SourceInfo info)
::=
  match info
    case SOURCEINFO(__) then
      <<
      <%str%>.filename = "<%Util.escapeModelicaStringToCString(fileName)%>";
      <%str%>.lineStart = <%lineNumberStart%>;
      <%str%>.colStart = <%columnNumberStart%>;
      <%str%>.lineEnd = <%lineNumberEnd%>;
      <%str%>.colEnd = <%columnNumberEnd%>;
      <%str%>.readonly = <%if isReadOnly then 1 else 0%>;
      >>
end getInfoArgsFMU;

template ScalarVariableFMU(SimVar simVar, String classType)
 "Generates code for ScalarVariable file for FMU target."
::=
  match simVar
    case SIMVAR(source = SOURCE(info = info)) then
      let valueReference = System.tmpTick()
      let ci = System.tmpTickIndex(2)
      let description = if comment then Util.escapeModelicaStringToCString(comment)
      let infostr = 'modelData-><%classType%>[<%ci%>].info'
      let attrstr = 'modelData-><%classType%>[<%ci%>].attribute'
      <<
      <%infostr%>.id = <%valueReference%>;
      <%infostr%>.name = "<%Util.escapeModelicaStringToCString(crefStrNoUnderscore(name))%>";
      <%infostr%>.comment = "<%description%>";
      <%getInfoArgsFMU(infostr+".info", info)%>
      <%ScalarVariableTypeFMU(attrstr, unit, displayUnit, minValue, maxValue, initialValue, nominalValue, isFixed, type_)%>
      >>
end ScalarVariableFMU;

template optInitValFMU(Option<Exp> exp, String default)
::=
  match exp
  case SOME(e) then
  (
  match e
  case ICONST(__) then integer
  case RCONST(__) then real
  case SCONST(__) then 'mmc_mk_scon("<%Util.escapeModelicaStringToCString(string)%>")'
  case BCONST(__) then if bool then 1 else 0
  case ENUM_LITERAL(__) then '<%index%>'
  else default // error(sourceInfo(), 'initial value of unknown type: <%printExpStr(e)%>')
  )
  else default
end optInitValFMU;

template ScalarVariableTypeFMU(String attrstr, String unit, String displayUnit, Option<DAE.Exp> minValue, Option<DAE.Exp> maxValue, Option<DAE.Exp> startValue, Option<DAE.Exp> nominalValue, Boolean isFixed, DAE.Type type_)
 "Generates code for ScalarVariable Type file for FMU target."
::=
  match type_
    case T_INTEGER(__) then
      <<
      <%attrstr%>.min = <%optInitValFMU(minValue,"-LONG_MAX")%>;
      <%attrstr%>.max = <%optInitValFMU(maxValue,"LONG_MAX")%>;
      <%attrstr%>.fixed = <%if isFixed then 1 else 0%>;
      <%attrstr%>.start = <%optInitValFMU(startValue,"0")%>;
      >>
    case T_REAL(__) then
      <<
      <%attrstr%>.unit = "<%Util.escapeModelicaStringToCString(unit)%>";
      <%attrstr%>.displayUnit = "<%Util.escapeModelicaStringToCString(displayUnit)%>";
      <%attrstr%>.min = <%optInitValFMU(minValue,"-DBL_MAX")%>;
      <%attrstr%>.max = <%optInitValFMU(maxValue,"DBL_MAX")%>;
      <%attrstr%>.fixed = <%if isFixed then 1 else 0%>;
      <%attrstr%>.useNominal = <%if nominalValue then 1 else 0%>;
      <%attrstr%>.nominal = <%optInitValFMU(nominalValue,"1.0")%>;
      <%attrstr%>.start = <%optInitValFMU(startValue,"0.0")%>;
      >>
    case T_BOOL(__) then
      <<
      <%attrstr%>.fixed = <%if isFixed then 1 else 0%>;
      <%attrstr%>.start = <%optInitValFMU(startValue,"0")%>;
      >>
    case T_STRING(__) then
      <<
      <%attrstr%>.start = <%optInitValFMU(startValue,"mmc_mk_scon(\"\")")%>;
      >>
    case T_ENUMERATION(__) then
      <<
      <%attrstr%>.min = <%optInitValFMU(minValue,"1")%>;
      <%attrstr%>.max = <%optInitValFMU(maxValue,listLength(names))%>;
      <%attrstr%>.fixed = <%if isFixed then 1 else 0%>;
      <%attrstr%>.start = <%optInitValFMU(startValue,"0")%>;
      >>
    else error(sourceInfo(), 'ScalarVariableTypeFMU: <%unparseType(type_)%>')
end ScalarVariableTypeFMU;

annotation(__OpenModelica_Interface="backend");
end CodegenFMU;

// vim: filetype=susan sw=2 sts=2
