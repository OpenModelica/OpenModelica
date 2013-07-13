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
import CodegenUtil.*;
import CodegenC.*; //unqualified import, no need the CodegenC is optional when calling a template; or mandatory when the same named template exists in this package (name hiding)


template translateModel(SimCode simCode)
 "Generates C code and Makefile for compiling a FMU of a
  Modelica model."
::=
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
  let guid = getUUIDStr()
  let target  = simulationCodeTarget()
  let()= textFile(simulationFunctionsHeaderFile(fileNamePrefix, modelInfo.functions, recordDecls), '<%fileNamePrefix%>_functions.h')
  let()= textFile(simulationFunctionsFile(fileNamePrefix, modelInfo.functions, literals), '<%fileNamePrefix%>_functions.c')
  let()= textFile(recordsFile(fileNamePrefix, recordDecls), '<%fileNamePrefix%>_records.c')
  let()= textFile(simulationHeaderFile(simCode,guid), '<%fileNamePrefix%>_model.h')
  let()= textFile(simulationFile(simCode,guid), '<%fileNamePrefix%>.c')
  let()= textFile(simulationInitFileCString(simulationInitFile(simCode,guid)), '<%fileNamePrefix%>_init.c')
  let()= textFile(fmumodel_identifierFile(simCode,guid), '<%fileNamePrefix%>_FMU.c')
  let()= textFile(fmuModelDescriptionFile(simCode,guid), 'modelDescription.xml')
  let()= textFile(fmudeffile(simCode), '<%fileNamePrefix%>.def')
  let()= textFile(fmuMakefile(target,simCode), '<%fileNamePrefix%>_FMU.makefile')
  "" // Return empty result since result written to files directly
end translateModel;

template simulationInitFileCString(Text text)
::=
  <<
  data->modelData.initXMLData = "<%Util.escapeModelicaStringToCString(text)%>";
  >>
end simulationInitFileCString;

template fmuModelDescriptionFile(SimCode simCode, String guid)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <?xml version="1.0" encoding="UTF-8"?>
  <%fmiModelDescription(simCode,guid)%>

  >>
end fmuModelDescriptionFile;

template fmiModelDescription(SimCode simCode, String guid)
 "Generates code for ModelDescription file for FMU target."
::=
//  <%UnitDefinitions(simCode)%>
//  <%TypeDefinitions(simCode)%>
//  <%VendorAnnotations(simCode)%>
match simCode
case SIMCODE(__) then
  <<
  <fmiModelDescription
    <%fmiModelDescriptionAttributes(simCode,guid)%>>
    <%DefaultExperiment(simulationSettingsOpt)%>
    <%ModelVariables(modelInfo)%>
  </fmiModelDescription>
  >>
end fmiModelDescription;

template fmiModelDescriptionAttributes(SimCode simCode, String guid)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__), vars = SIMVARS(stateVars = listStates))) then
  let fmiVersion = '1.0'
  let modelName = dotPath(modelInfo.name)
  let modelIdentifier = System.stringReplace(fileNamePrefix,".", "_")
  let description = ''
  let author = ''
  let version= ''
  let generationTool= 'OpenModelica Compiler <%getVersionNr()%>'
  let generationDateAndTime = xsdateTime(getCurrentDateTime())
  let variableNamingConvention = 'structured'
  let numberOfContinuousStates = if intEq(vi.numStateVars,1) then statesnumwithDummy(listStates) else  vi.numStateVars
  let numberOfEventIndicators = vi.numZeroCrossings
//  description="<%description%>"
//    author="<%author%>"
//    version="<%version%>"
  <<
  fmiVersion="<%fmiVersion%>"
  modelName="<%modelName%>"
  modelIdentifier="<%modelIdentifier%>"
  guid="{<%guid%>}"
  generationTool="<%generationTool%>"
  generationDateAndTime="<%generationDateAndTime%>"
  variableNamingConvention="<%variableNamingConvention%>"
  numberOfContinuousStates="<%numberOfContinuousStates%>"
  numberOfEventIndicators="<%numberOfEventIndicators%>"
  >>
end fmiModelDescriptionAttributes;

template statesnumwithDummy(list<SimVar> vars)
" return number of states without dummy vars"
::=
 (vars |> var =>  match var case SIMVAR(__) then if stringEq(crefStr(name),"$dummy") then '0' else '1' ;separator="\n")
end statesnumwithDummy;

template xsdateTime(DateTime dt)
 "YYYY-MM-DDThh:mm:ssZ"
::=
  match dt
  case DATETIME(__) then '<%year%>-<%twodigit(mon)%>-<%twodigit(mday)%>T<%twodigit(hour)%>:<%twodigit(min)%>:<%twodigit(sec)%>Z'
end xsdateTime;

template UnitDefinitions(SimCode simCode)
 "Generates code for UnitDefinitions file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <UnitDefinitions>
  </UnitDefinitions>
  >>
end UnitDefinitions;

template TypeDefinitions(SimCode simCode)
 "Generates code for TypeDefinitions file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <TypeDefinitions>
  </TypeDefinitions>
  >>
end TypeDefinitions;

template DefaultExperiment(Option<SimulationSettings> simulationSettingsOpt)
 "Generates code for DefaultExperiment file for FMU target."
::=
match simulationSettingsOpt
  case SOME(v) then
    <<
    <DefaultExperiment <%DefaultExperimentAttribute(v)%>/>
    >>
end DefaultExperiment;

template DefaultExperimentAttribute(SimulationSettings simulationSettings)
 "Generates code for DefaultExperiment Attribute file for FMU target."
::=
match simulationSettings
  case SIMULATION_SETTINGS(__) then
    <<
    startTime="<%startTime%>" stopTime="<%stopTime%>" tolerance="<%tolerance%>"
      >>
end DefaultExperimentAttribute;

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

template ModelVariables(ModelInfo modelInfo)
 "Generates code for ModelVariables file for FMU target."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  <ModelVariables>
  <%System.tmpTickReset(0)%>
  <%vars.stateVars |> var =>
    ScalarVariable(var)
  ;separator="\n"%>
  <%vars.derivativeVars |> var =>
    ScalarVariable(var)
  ;separator="\n"%>
  <%vars.algVars |> var =>
    ScalarVariable(var)
  ;separator="\n"%>
  <%vars.paramVars |> var =>
    ScalarVariable(var)
  ;separator="\n"%>
  <%vars.aliasVars |> var =>
    ScalarVariable(var)
  ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.intAlgVars |> var =>
    ScalarVariable(var)
  ;separator="\n"%>
  <%vars.intParamVars |> var =>
    ScalarVariable(var)
  ;separator="\n"%>
  <%vars.intAliasVars |> var =>
    ScalarVariable(var)
  ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.boolAlgVars |> var =>
    ScalarVariable(var)
  ;separator="\n"%>
  <%vars.boolParamVars |> var =>
    ScalarVariable(var)
  ;separator="\n"%>
  <%vars.boolAliasVars |> var =>
    ScalarVariable(var)
  ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.stringAlgVars |> var =>
    ScalarVariable(var)
  ;separator="\n"%>
  <%vars.stringParamVars |> var =>
    ScalarVariable(var)
  ;separator="\n"%>
  <%vars.stringAliasVars |> var =>
    ScalarVariable(var)
  ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%externalFunctions(modelInfo)%>
  </ModelVariables>
  >>
end ModelVariables;

template ScalarVariable(SimVar simVar)
 "Generates code for ScalarVariable file for FMU target."
::=
match simVar
case SIMVAR(__) then
  if stringEq(crefStr(name),"$dummy") then
  <<>>
  else if stringEq(crefStr(name),"der($dummy)") then
  <<>>
  else
  <<
  <ScalarVariable
    <%ScalarVariableAttribute(simVar)%>>
    <%ScalarVariableType(type_,unit,displayUnit,initialValue,isFixed)%>
  </ScalarVariable>
  >>
end ScalarVariable;

template ScalarVariableAttribute(SimVar simVar)
 "Generates code for ScalarVariable Attribute file for FMU target."
::=
match simVar
  case SIMVAR(__) then
  let valueReference = '<%System.tmpTick()%>'
  let variability = getVariablity(varKind)
  let description = if comment then 'description="<%Util.escapeModelicaStringToXmlString(comment)%>"'
  let alias = getAliasVar(aliasvar)
  let caus = getCausality(causality)
  <<
  name="<%System.stringReplace(crefStrNoUnderscore(name),"$", "_D_")%>"
  valueReference="<%valueReference%>"
  <%description%>
  variability="<%variability%>"
  causality="<%caus%>"
  alias="<%alias%>"
  >>
end ScalarVariableAttribute;

template getCausality(Causality c)
 "Returns the Causality Attribute of ScalarVariable."
::=
match c
  case NONECAUS(__) then "none"
  case INTERNAL(__) then "internal"
  case OUTPUT(__) then "output"
  case INPUT(__) then "input"
end getCausality;

template getVariablity(VarKind varKind)
 "Returns the variablity Attribute of ScalarVariable."
::=
match varKind
  case DISCRETE(__) then "discrete"
  case PARAM(__) then "parameter"
  case CONST(__) then "constant"
  else "continuous"
end getVariablity;

template getAliasVar(AliasVariable aliasvar)
 "Returns the alias Attribute of ScalarVariable."
::=
match aliasvar
  case NOALIAS(__) then "noAlias"
  /* We don't handle the alias and negatedAlias properly. If a variable is alias it must get the valueReference of the aliased variable. */
  /*case ALIAS(__) then "alias"
  case NEGATEDALIAS(__) then "negatedAlias"
  */
  else "noAlias"
end getAliasVar;

template ScalarVariableType(DAE.Type type_, String unit, String displayUnit, Option<DAE.Exp> initialValue, Boolean isFixed)
 "Generates code for ScalarVariable Type file for FMU target."
::=
match type_
  case T_INTEGER(__) then '<Integer<%ScalarVariableTypeCommonAttribute(initialValue,isFixed)%>/>'
  /* Don't generate the units for now since it is wrong. If you generate a unit attribute here then we must add the UnitDefinitions tag section also. */
  case T_REAL(__) then '<Real<%ScalarVariableTypeCommonAttribute(initialValue,isFixed)/*%> <%ScalarVariableTypeRealAttribute(unit,displayUnit)*/%>/>'
  case T_BOOL(__) then '<Boolean<%ScalarVariableTypeCommonAttribute(initialValue,isFixed)%>/>'
  case T_STRING(__) then '<String<%ScalarVariableTypeCommonAttribute(initialValue,isFixed)%>/>'
  case T_ENUMERATION(__) then '<Integer<%ScalarVariableTypeCommonAttribute(initialValue,isFixed)%>/>'
  else 'UNKOWN_TYPE'
end ScalarVariableType;

template ScalarVariableTypeCommonAttribute(Option<DAE.Exp> initialValue, Boolean isFixed)
 "Generates code for ScalarVariable Type file for FMU target."
::=
match initialValue
  case SOME(exp) then ' start="<%initVal(exp)%>" fixed="<%isFixed%>"'
end ScalarVariableTypeCommonAttribute;

template ScalarVariableTypeRealAttribute(String unit, String displayUnit)
 "Generates code for ScalarVariable Type Real file for FMU target."
::=
  let unit_ = if unit then 'unit="<%unit%>"'
  let displayUnit_ = if displayUnit then 'displayUnit="<%displayUnit%>"'
  <<
  <%unit_%> <%displayUnit_%>
  >>
end ScalarVariableTypeRealAttribute;

template externalFunctions(ModelInfo modelInfo)
 "Generates external function definitions."
::=
match modelInfo
case MODELINFO(__) then
  (functions |> fn => externalFunction(fn) ; separator="\n")
end externalFunctions;

template externalFunction(Function fn)
 "Generates external function definitions."
::=
  match fn
    case EXTERNAL_FUNCTION(dynamicLoad=true) then
      let fname = extFunctionName(extName, language)
      <<
      <ExternalFunction
        name="<%fname%>"
        valueReference="<%System.tmpTick()%>"/>
      >>
end externalFunction;


template fmumodel_identifierFile(SimCode simCode, String guid)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<

  // define class name and unique id
  #define MODEL_IDENTIFIER <%System.stringReplace(fileNamePrefix,".", "_")%>
  #define MODEL_GUID "{<%guid%>}"

  // include fmu header files, typedefs and macros
  #include <stdio.h>
  #include <string.h>
  #include <assert.h>
  #include "openmodelica.h"
  #include "openmodelica_func.h"
  #include "simulation_data.h"
  #include "omc_error.h"
  #include "fmiModelTypes.h"
  #include "fmiModelFunctions.h"
  #include "<%fileNamePrefix%>_functions.h"
  #include "initialization.h"
  #include "events.h"
  #include "fmu_model_interface.h"

  #ifdef __cplusplus
  extern "C" {
  #endif

  void setStartValues(ModelInstance *comp);
  void setDefaultStartValues(ModelInstance *comp);
  void eventUpdate(ModelInstance* comp, fmiEventInfo* eventInfo);
  fmiReal getReal(ModelInstance* comp, const fmiValueReference vr);
  fmiStatus setReal(ModelInstance* comp, const fmiValueReference vr, const fmiReal value);
  fmiInteger getInteger(ModelInstance* comp, const fmiValueReference vr);
  fmiStatus setInteger(ModelInstance* comp, const fmiValueReference vr, const fmiInteger value);
  fmiBoolean getBoolean(ModelInstance* comp, const fmiValueReference vr);
  fmiStatus setBoolean(ModelInstance* comp, const fmiValueReference vr, const fmiBoolean value);
  fmiString getString(ModelInstance* comp, const fmiValueReference vr);
  fmiStatus setExternalFunction(ModelInstance* c, const fmiValueReference vr, const void* value);

  <%ModelDefineData(modelInfo)%>

  // implementation of the Model Exchange functions
  #include "fmu_model_interface.c"

  <%setDefaultStartValues(modelInfo)%>
  <%setStartValues(modelInfo)%>
  <%eventUpdateFunction(simCode)%>
  <%getRealFunction(modelInfo)%>
  <%setRealFunction(modelInfo)%>
  <%getIntegerFunction(modelInfo)%>
  <%setIntegerFunction(modelInfo)%>
  <%getBooleanFunction(modelInfo)%>
  <%setBooleanFunction(modelInfo)%>
  <%getStringFunction(modelInfo)%>
  <%setExternalFunction(modelInfo)%>

  #ifdef __cplusplus
  }
  #endif

  >>
end fmumodel_identifierFile;

template ModelDefineData(ModelInfo modelInfo)
 "Generates global data in simulation file."
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(stateVars = listStates)) then
let numberOfReals = intAdd(intMul(varInfo.numStateVars,2),intAdd(varInfo.numAlgVars,intAdd(varInfo.numParams,varInfo.numAlgAliasVars)))
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
  <%System.tmpTickReset(0)%>
  <%vars.stateVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.derivativeVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.algVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.paramVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.aliasVars |> var => DefineVariables(var) ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.intAlgVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.intParamVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.intAliasVars |> var => DefineVariables(var) ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.boolAlgVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.boolParamVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.boolAliasVars |> var => DefineVariables(var) ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.stringAlgVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.stringParamVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.stringAliasVars |> var => DefineVariables(var) ;separator="\n"%>


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

template DefineVariables(SimVar simVar)
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
  #define <%cref(name)%>_ <%System.tmpTick()%> <%description%>
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
case MODELINFO(varInfo=VARINFO(numStateVars=numStateVars),vars=SIMVARS(__)) then
  <<
  // Set values for all variables that define a start value
  void setDefaultStartValues(ModelInstance *comp) {

  <%vars.stateVars |> var => initValsDefault(var,"realVars",0) ;separator="\n"%>
  <%vars.derivativeVars |> var => initValsDefault(var,"realVars",numStateVars) ;separator="\n"%>
  <%vars.algVars |> var => initValsDefault(var,"realVars",intMul(2,numStateVars)) ;separator="\n"%>
  <%vars.intAlgVars |> var => initValsDefault(var,"integerVars",0) ;separator="\n"%>
  <%vars.boolAlgVars |> var => initValsDefault(var,"booleanVars",0) ;separator="\n"%>
  <%vars.stringAlgVars |> var => initValsDefault(var,"stringVars",0) ;separator="\n"%>
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
case MODELINFO(varInfo=VARINFO(numStateVars=numStateVars),vars=SIMVARS(__)) then
  <<
  // Set values for all variables that define a start value
  void setStartValues(ModelInstance *comp) {

  <%vars.stateVars |> var => initVals(var,"realVars",0) ;separator="\n"%>
  <%vars.derivativeVars |> var => initVals(var,"realVars",numStateVars) ;separator="\n"%>
  <%vars.algVars |> var => initVals(var,"realVars",intMul(2,numStateVars)) ;separator="\n"%>
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

template getRealFunction(ModelInfo modelInfo)
 "Generates getReal function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__),varInfo=VARINFO(numStateVars=numStateVars)) then
  <<
  fmiReal getReal(ModelInstance* comp, const fmiValueReference vr) {
    switch (vr) {
        <%vars.stateVars |> var => SwitchVars(var, "realVars", 0) ;separator="\n"%>
        <%vars.derivativeVars |> var => SwitchVars(var, "realVars", numStateVars) ;separator="\n"%>
        <%vars.algVars |> var => SwitchVars(var, "realVars", intMul(2,numStateVars)) ;separator="\n"%>
        <%vars.paramVars |> var => SwitchParameters(var, "realParameter") ;separator="\n"%>
        <%vars.aliasVars |> var => SwitchAliasVars(var, "Real","-") ;separator="\n"%>
        default:
            return fmiError;
    }
  }

  >>
end getRealFunction;

template setRealFunction(ModelInfo modelInfo)
 "Generates setReal function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__),varInfo=VARINFO(numStateVars=numStateVars)) then
  <<
  fmiStatus setReal(ModelInstance* comp, const fmiValueReference vr, const fmiReal value) {
    switch (vr) {
        <%vars.stateVars |> var => SwitchVarsSet(var, "realVars", 0) ;separator="\n"%>
        <%vars.derivativeVars |> var => SwitchVarsSet(var, "realVars", numStateVars) ;separator="\n"%>
        <%vars.algVars |> var => SwitchVarsSet(var, "realVars", intMul(2,numStateVars)) ;separator="\n"%>
        <%vars.paramVars |> var => SwitchParametersSet(var, "realParameter") ;separator="\n"%>
        <%vars.aliasVars |> var => SwitchAliasVarsSet(var, "Real", "-") ;separator="\n"%>
        default:
            return fmiError;
    }
    return fmiOK;
  }

  >>
end setRealFunction;

template getIntegerFunction(ModelInfo modelInfo)
 "Generates setInteger function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmiInteger getInteger(ModelInstance* comp, const fmiValueReference vr) {
    switch (vr) {
        <%vars.intAlgVars |> var => SwitchVars(var, "integerVars", 0) ;separator="\n"%>
        <%vars.intParamVars |> var => SwitchParameters(var, "integerParameter") ;separator="\n"%>
        <%vars.intAliasVars |> var => SwitchAliasVars(var, "Integer", "-") ;separator="\n"%>
        default:
            return 0;
    }
  }
  >>
end getIntegerFunction;

template setIntegerFunction(ModelInfo modelInfo)
 "Generates setInteger function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmiStatus setInteger(ModelInstance* comp, const fmiValueReference vr, const fmiInteger value) {
    switch (vr) {
        <%vars.intAlgVars |> var => SwitchVarsSet(var, "integerVars", 0) ;separator="\n"%>
        <%vars.intParamVars |> var => SwitchParametersSet(var, "integerParameter") ;separator="\n"%>
        <%vars.intAliasVars |> var => SwitchAliasVarsSet(var, "Integer", "-") ;separator="\n"%>
        default:
            return fmiError;
    }
    return fmiOK;
  }
  >>
end setIntegerFunction;

template getBooleanFunction(ModelInfo modelInfo)
 "Generates setBoolean function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmiBoolean getBoolean(ModelInstance* comp, const fmiValueReference vr) {
    switch (vr) {
        <%vars.boolAlgVars |> var => SwitchVars(var, "booleanVars", 0) ;separator="\n"%>
        <%vars.boolParamVars |> var => SwitchParameters(var, "booleanParameter") ;separator="\n"%>
        <%vars.boolAliasVars |> var => SwitchAliasVars(var, "Boolean", "!") ;separator="\n"%>
        default:
            return 0;
    }
  }

  >>
end getBooleanFunction;

template setBooleanFunction(ModelInfo modelInfo)
 "Generates setBoolean function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmiStatus setBoolean(ModelInstance* comp, const fmiValueReference vr, const fmiBoolean value) {
    switch (vr) {
        <%vars.boolAlgVars |> var => SwitchVarsSet(var, "booleanVars", 0) ;separator="\n"%>
        <%vars.boolParamVars |> var => SwitchParametersSet(var, "booleanParameter") ;separator="\n"%>
        <%vars.boolAliasVars |> var => SwitchAliasVarsSet(var, "Boolean", "!") ;separator="\n"%>
        default:
            return fmiError;
    }
    return fmiOK;
  }

  >>
end setBooleanFunction;

template getStringFunction(ModelInfo modelInfo)
 "Generates setString function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmiString getString(ModelInstance* comp, const fmiValueReference vr) {
    switch (vr) {
        <%vars.stringAlgVars |> var => SwitchVars(var, "stringVars", 0) ;separator="\n"%>
        <%vars.stringParamVars |> var => SwitchParameters(var, "stringParameter") ;separator="\n"%>
        <%vars.stringAliasVars |> var => SwitchAliasVars(var, "string", "") ;separator="\n"%>
        default:
            return 0;
    }
  }

  >>
end getStringFunction;

template setStringFunction(ModelInfo modelInfo)
 "Generates setString function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmiString getString(ModelInstance* comp, const fmiValueReference vr) {
    switch (vr) {
        <%vars.stringAlgVars |> var => SwitchVarsSet(var, "stringVars", 0) ;separator="\n"%>
        <%vars.stringParamVars |> var => SwitchParametersSet(var, "stringParameter") ;separator="\n"%>
        <%vars.stringAliasVars |> var => SwitchAliasVarsSet(var, "String", "") ;separator="\n"%>
        default:
            return 0;
    }
  }

  >>
end setStringFunction;

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


template getPlatformString2(String platform, String fileNamePrefix, String dirExtra, String libsPos1, String libsPos2, String omhome)
 "returns compilation commands for the platform. "
::=
let fmudirname = '<%fileNamePrefix%>.fmutmp'
match platform
  case "win32" then
  <<
  <%fileNamePrefix%>_FMU: <%fileNamePrefix%>.def <%fileNamePrefix%>.dll
  <%\t%> dlltool -d <%fileNamePrefix%>.def --dllname <%fileNamePrefix%>.dll --output-lib <%fileNamePrefix%>.lib --kill-at

  <%\t%> cp <%fileNamePrefix%>.dll <%fmudirname%>/binaries/<%platform%>/
  <%\t%> cp <%fileNamePrefix%>.lib <%fmudirname%>/binaries/<%platform%>/
  <%\t%> cp <%fileNamePrefix%>.c <%fmudirname%>/sources/<%fileNamePrefix%>.c
  <%\t%> cp <%fileNamePrefix%>_model.h <%fmudirname%>/sources/<%fileNamePrefix%>_model.h
  <%\t%> cp <%fileNamePrefix%>_FMU.c <%fmudirname%>/sources/<%fileNamePrefix%>_FMU.c
  <%\t%> cp <%fileNamePrefix%>_info.c <%fmudirname%>/sources/<%fileNamePrefix%>_info.c
  <%\t%> cp <%fileNamePrefix%>_init.c <%fmudirname%>/sources/<%fileNamePrefix%>_init.c
  <%\t%> cp <%fileNamePrefix%>_functions.c <%fmudirname%>/sources/<%fileNamePrefix%>_functions.c
  <%\t%> cp <%fileNamePrefix%>_functions.h <%fmudirname%>/sources/<%fileNamePrefix%>_functions.h
  <%\t%> cp <%fileNamePrefix%>_records.c <%fmudirname%>/sources/<%fileNamePrefix%>_records.c
  <%\t%> cp modelDescription.xml <%fmudirname%>/modelDescription.xml
  <%\t%> cp <%omhome%>/lib/omc/libexec/gnuplot/binary/libexpat-1.dll <%fmudirname%>/binaries/<%platform%>/
  <%\t%> cd <%fmudirname%>&& rm -f ../<%fileNamePrefix%>.fmu&& zip -r ../<%fileNamePrefix%>.fmu *
  <%\t%> rm -rf <%fmudirname%>
  <%\t%> rm -f <%fileNamePrefix%>.def <%fileNamePrefix%>.o <%fileNamePrefix%>_FMU.libs <%fileNamePrefix%>_FMU.makefile <%fileNamePrefix%>_FMU.o <%fileNamePrefix%>_records.o

  <%fileNamePrefix%>.dll: clean <%fileNamePrefix%>_FMU.o <%fileNamePrefix%>.o <%fileNamePrefix%>_records.o
  <%\t%> $(CXX) -shared -I. -o <%fileNamePrefix%>.dll <%fileNamePrefix%>_FMU.o <%fileNamePrefix%>.o <%fileNamePrefix%>_records.o  $(CPPFLAGS) <%dirExtra%> <%libsPos1%> <%libsPos2%> $(CFLAGS) $(LDFLAGS) <%match System.os() case "OSX" then "-lf2c" else "-Wl,-Bstatic -lf2c -Wl,-Bdynamic"%> -Wl,--kill-at

  <%\t%> "mkdir.exe" -p <%fmudirname%>
  <%\t%> "mkdir.exe" -p <%fmudirname%>/binaries
  <%\t%> "mkdir.exe" -p <%fmudirname%>/binaries/<%platform%>
  <%\t%> "mkdir.exe" -p <%fmudirname%>/sources
  >>
  else
  <<
  <%fileNamePrefix%>_FMU: <%fileNamePrefix%>_FMU.o <%fileNamePrefix%>.o <%fileNamePrefix%>_records.o
  <%\t%> $(CXX) -shared -I. -o <%fileNamePrefix%>$(DLLEXT) <%fileNamePrefix%>_FMU.o <%fileNamePrefix%>.o <%fileNamePrefix%>_records.o $(CPPFLAGS) <%dirExtra%> <%libsPos1%> <%libsPos2%> $(CFLAGS) $(LDFLAGS) <%match System.os() case "OSX" then "-lf2c" else "-Wl,-Bstatic -lf2c -Wl,-Bdynamic"%>

  <%\t%> mkdir -p <%fmudirname%>
  <%\t%> mkdir -p <%fmudirname%>/binaries

  <%\t%> mkdir -p <%fmudirname%>/binaries/$(PLATFORM)
  <%\t%> mkdir -p <%fmudirname%>/sources

  <%\t%> cp <%fileNamePrefix%>$(DLLEXT) <%fmudirname%>/binaries/$(PLATFORM)/
  <%\t%> cp <%fileNamePrefix%>_FMU.libs <%fmudirname%>/binaries/$(PLATFORM)/
  <%\t%> cp <%fileNamePrefix%>.c <%fmudirname%>/sources/<%fileNamePrefix%>.c
  <%\t%> cp <%fileNamePrefix%>_model.h <%fmudirname%>/sources/<%fileNamePrefix%>_model.h
  <%\t%> cp <%fileNamePrefix%>_info.c <%fmudirname%>/sources/<%fileNamePrefix%>_info.c
  <%\t%> cp <%fileNamePrefix%>_init.c <%fmudirname%>/sources/<%fileNamePrefix%>_init.c
  <%\t%> cp <%fileNamePrefix%>_FMU.c <%fmudirname%>/sources/<%fileNamePrefix%>_FMU.c
  <%\t%> cp <%fileNamePrefix%>_functions.c <%fmudirname%>/sources/<%fileNamePrefix%>_functions.c
  <%\t%> cp <%fileNamePrefix%>_functions.h <%fmudirname%>/sources/<%fileNamePrefix%>_functions.h
  <%\t%> cp <%fileNamePrefix%>_records.c <%fmudirname%>/sources/<%fileNamePrefix%>_records.c
  <%\t%> cp modelDescription.xml <%fmudirname%>/modelDescription.xml
  <%\t%> cd <%fmudirname%>; rm -f ../<%fileNamePrefix%>.fmu && zip -r ../<%fileNamePrefix%>.fmu *
  <%\t%> rm -rf <%fmudirname%>
  <%\t%> rm -f <%fileNamePrefix%>.def <%fileNamePrefix%>.o <%fileNamePrefix%>_FMU.libs <%fileNamePrefix%>_FMU.makefile <%fileNamePrefix%>_FMU.o <%fileNamePrefix%>_records.o

  >>
end getPlatformString2;

template fmuMakefile(String target, SimCode simCode)
 "Generates the contents of the makefile for the simulation case. Copy libexpat & correct linux fmu"
::=
match target
case "msvc" then
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
  let dirExtra = if modelInfo.directory then '-L"<%modelInfo.directory%>"' //else ""
  let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
  let libsPos1 = if not dirExtra then libsStr //else ""
  let libsPos2 = if dirExtra then libsStr // else ""
  let fmudirname = '<%fileNamePrefix%>.fmutmp'
  let extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then
    '<%if s.measureTime then "-D_OMC_MEASURE_TIME "%> <%match s.method
       case "inline-euler" then "-D_OMC_INLINE_EULER"
       case "inline-rungekutta" then "-D_OMC_INLINE_RK"%>'
  let compilecmds = getPlatformString2(makefileParams.platform, fileNamePrefix, dirExtra, libsPos1, libsPos2, makefileParams.omhome)
  <<
  # Makefile generated by OpenModelica

  # Simulations use -O3 by default
  SIM_OR_DYNLOAD_OPT_LEVEL=
  MODELICAUSERCFLAGS=
  CXX=cl
  EXEEXT=.exe
  DLLEXT=.dll
  FMUEXT=.fmu
  PLATLINUX = linux32
  PLATWIN32 = win32

  # /Od - Optimization disabled
  # /EHa enable C++ EH (w/ SEH exceptions)
  # /fp:except - consider floating-point exceptions when generating code
  # /arch:SSE2 - enable use of instructions available with SSE2 enabled CPUs
  # /I - Include Directories
  # /DNOMINMAX - Define NOMINMAX (does what it says)
  # /TP - Use C++ Compiler
  CFLAGS=/Od /ZI /EHa /fp:except /I"<%makefileParams.omhome%>/include/omc" /I. /DNOMINMAX /TP /DNO_INTERACTIVE_DEPENDENCY

  # /ZI enable Edit and Continue debug info
  CDFLAGS = /ZI

  # /MD - link with MSVCRT.LIB
  # /link - [linker options and libraries]
  # /LIBPATH: - Directories where libs can be found
  LDFLAGS=/MD /link /dll /debug /pdb:"<%fileNamePrefix%>.pdb" /LIBPATH:"<%makefileParams.omhome%>/lib/omc/msvc/" /LIBPATH:"<%makefileParams.omhome%>/lib/omc/msvc/release/" <%dirExtra%> <%libsPos1%> <%libsPos2%> f2c.lib initialization.lib libexpat.lib math-support.lib meta.lib ModelicaExternalC.lib results.lib simulation.lib solver.lib sundials_kinsol.lib sundials_nvecserial.lib util.lib lapack_win32_MT.lib

  # /MDd link with MSVCRTD.LIB debug lib
  # lib names should not be appended with a d just switch to lib/omc/msvc/debug


  FILEPREFIX=<%fileNamePrefix%>
  MAINFILE=$(FILEPREFIX).c
  MAINOBJ=$(FILEPREFIX).obj
  GENERATEDFILES=$(MAINFILE) $(FILEPREFIX)_functions.c $(FILEPREFIX)_functions.h $(FILEPREFIX)_records.c $(FILEPREFIX).makefile

  $(FILEPREFIX)$(FMUEXT): $(FILEPREFIX)$(DLLEXT) modelDescription.xml
      if not exist <%fmudirname%>\binaries\$(PLATWIN32) mkdir <%fmudirname%>\binaries\$(PLATWIN32)
      if not exist <%fmudirname%>\sources mkdir <%fmudirname%>\sources

      copy <%fileNamePrefix%>.dll <%fmudirname%>\binaries\$(PLATWIN32)
      copy <%fileNamePrefix%>.lib <%fmudirname%>\binaries\$(PLATWIN32)
      copy <%fileNamePrefix%>.pdb <%fmudirname%>\binaries\$(PLATWIN32)
      copy <%fileNamePrefix%>.c <%fmudirname%>\sources\<%fileNamePrefix%>.c
      copy <%fileNamePrefix%>_model.h <%fmudirname%>\sources\<%fileNamePrefix%>_model.h
      copy <%fileNamePrefix%>_FMU.c <%fmudirname%>\sources\<%fileNamePrefix%>_FMU.c
      copy <%fileNamePrefix%>_info.c <%fmudirname%>\sources\<%fileNamePrefix%>_info.c
      copy <%fileNamePrefix%>_init.c <%fmudirname%>\sources\<%fileNamePrefix%>_init.c
      copy <%fileNamePrefix%>_functions.c <%fmudirname%>\sources\<%fileNamePrefix%>_functions.c
      copy <%fileNamePrefix%>_functions.h <%fmudirname%>\sources\<%fileNamePrefix%>_functions.h
      copy <%fileNamePrefix%>_records.c <%fmudirname%>\sources\<%fileNamePrefix%>_records.c
      copy modelDescription.xml <%fmudirname%>\modelDescription.xml
      copy <%stringReplace(makefileParams.omhome,"/","\\")%>\lib\omc\libexec\gnuplot\binary\libexpat-1.dll <%fmudirname%>\binaries\$(PLATWIN32)
      cd <%fmudirname%>
      "$(MINGW)\bin\zip.exe" -r ../<%fileNamePrefix%>.fmu *
      cd ..
      rmdir /S /Q <%fmudirname%>

  $(FILEPREFIX)$(DLLEXT): $(MAINOBJ) $(FILEPREFIX)_records.c $(FILEPREFIX)_functions.c $(FILEPREFIX)_functions.h
      $(CXX) /Fe$(FILEPREFIX)$(DLLEXT) $(MAINFILE) $(FILEPREFIX)_FMU.c $(FILEPREFIX)_records.c $(CFLAGS) $(LDFLAGS)
  >>
end match
case "gcc" then
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
  let dirExtra = if modelInfo.directory then '-L"<%modelInfo.directory%>"' //else ""
  let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
  let libsPos1 = if not dirExtra then libsStr //else ""
  let libsPos2 = if dirExtra then libsStr // else ""
  let extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then
    '<%if s.measureTime then "-D_OMC_MEASURE_TIME "%> <%match s.method
       case "inline-euler" then "-D_OMC_INLINE_EULER"
       case "inline-rungekutta" then "-D_OMC_INLINE_RK"%>'
  let compilecmds = getPlatformString2(makefileParams.platform, fileNamePrefix, dirExtra, libsPos1, libsPos2, makefileParams.omhome)
  let platformstr = match makefileParams.platform case "linux-i686" then 'linux32' else '<%makefileParams.platform%>'
  <<
  # Makefile generated by OpenModelica

  # Simulation of the fmu with dymola does not work
  # with inline-small-functions
  SIM_OR_DYNLOAD_OPT_LEVEL=-O #-O2  -fno-inline-small-functions
  CC=<%makefileParams.ccompiler%>
  CXX=<%makefileParams.cxxcompiler%>
  LINK=<%makefileParams.linker%>
  EXEEXT=<%makefileParams.exeext%>
  DLLEXT=<%makefileParams.dllext%>
  CFLAGS_BASED_ON_INIT_FILE=<%extraCflags%>
  PLATFORM = <%platformstr%>
  PLAT34 = <%makefileParams.platform%>
  CFLAGS=$(CFLAGS_BASED_ON_INIT_FILE) -I"<%makefileParams.omhome%>/include/omc" <%makefileParams.cflags%> <%match sopt case SOME(s as SIMULATION_SETTINGS(__)) then s.cflags /* From the simulate() command */%>
  CPPFLAGS=-I"<%makefileParams.omhome%>/include/omc" -I. <%dirExtra%> <%makefileParams.includes ; separator=" "%>
  LDFLAGS=-L"<%makefileParams.omhome%>/lib/omc" -Wl,-rpath,'<%makefileParams.omhome%>/lib/omc' -lSimulationRuntimeC -linteractive <%makefileParams.ldflags%> <%makefileParams.runtimelibs%>
  PERL=perl
  MAINFILE=<%fileNamePrefix%>_FMU<% if acceptMetaModelicaGrammar() then ".conv"%>.c
  MAINOBJ=<%fileNamePrefix%>_FMU<% if acceptMetaModelicaGrammar() then ".conv"%>.o

  PHONY: <%fileNamePrefix%>_FMU
  <%compilecmds%>

  <%fileNamePrefix%>.conv.c: <%fileNamePrefix%>.c
  <%\t%> $(PERL) <%makefileParams.omhome%>/share/omc/scripts/convert_lines.pl $< $@.tmp
  <%\t%> @mv $@.tmp $@
  $(MAINOBJ): $(MAINFILE) <%fileNamePrefix%>.c <%fileNamePrefix%>_functions.c <%fileNamePrefix%>_functions.h
  clean:
  <%\t%> @rm -f <%fileNamePrefix%>_records.o $(MAINOBJ) <%fileNamePrefix%>_FMU.o <%fileNamePrefix%>.o
  >>
end match
else
  error(sourceInfo(), 'target <%target%> is not handled!')
end fmuMakefile;

template fmudeffile(SimCode simCode)
 "Generates the def file of the fmu."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
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

template importFMUModelica(FmiImport fmi)
 "Generates the Modelica code depending on the FMU type."
::=
match fmi
case FMIIMPORT(fmiInfo=INFO(__)) then
  match fmiInfo.fmiType
    case 0 then
      importFMUModelExchange(fmi)
    case 1 then
      importFMUCoSimulationStandAlone(fmi)
end importFMUModelica;

template importFMUModelExchange(FmiImport fmi)
 "Generates Modelica code for FMI Model Exchange."
::=
match fmi
case FMIIMPORT(fmiInfo=INFO(__)) then
  match fmiInfo.fmiVersion
    case "1.0" then
      importFMU1ModelExchange(fmi)
    case "2.0" then
      importFMU2ModelExchange(fmi)
end importFMUModelExchange;

template importFMU1ModelExchange(FmiImport fmi)
 "Generates Modelica code for FMI Model Exchange version 1.0"
::=
match fmi
case FMIIMPORT(fmiInfo=INFO(__),fmiExperimentAnnotation=EXPERIMENTANNOTATION(__)) then
  /* Get Real varibales and their value references */
  let realVariablesNames = dumpRealVariablesName(fmiModelVariablesList)
  let realVariablesValueReferences = dumpRealVariablesVR(fmiModelVariablesList)
  /* Get start Real varibales and their value references */
  let realStartVariablesValueReferences = dumpStartRealVariablesValueReference(fmiModelVariablesList)
  let realStartVariablesNames = dumpStartRealVariablesName(fmiModelVariablesList)
  /* Get Integer varibales and their value references */
  let integerVariablesNames = dumpIntegerVariablesName(fmiModelVariablesList)
  let integerVariablesValueReferences = dumpIntegerVariablesVR(fmiModelVariablesList)
  /* Get start Integer varibales and their value references */
  let integerStartVariablesValueReferences = dumpStartIntegerVariablesValueReference(fmiModelVariablesList)
  let integerStartVariablesNames = dumpStartIntegerVariablesName(fmiModelVariablesList)
  /* Get Boolean varibales and their value references */
  let booleanVariablesNames = dumpBooleanVariablesName(fmiModelVariablesList)
  let booleanVariablesValueReferences = dumpBooleanVariablesVR(fmiModelVariablesList)
  /* Get start Boolean varibales and their value references */
  let booleanStartVariablesValueReferences = dumpStartBooleanVariablesValueReference(fmiModelVariablesList)
  let booleanStartVariablesNames = dumpStartBooleanVariablesName(fmiModelVariablesList)
  /* Get String varibales and their value references */
  let stringVariablesNames = dumpStringVariablesName(fmiModelVariablesList)
  let stringVariablesValueReferences = dumpStringVariablesVR(fmiModelVariablesList)
  /* Get start String varibales and their value references */
  let stringStartVariablesValueReferences = dumpStartStringVariablesValueReference(fmiModelVariablesList)
  let stringStartVariablesNames = dumpStartStringVariablesName(fmiModelVariablesList)
  <<
  model <%fmiInfo.fmiModelIdentifier%>_<%getFMIType(fmiInfo)%>_FMU<%if stringEq(fmiInfo.fmiDescription, "") then "" else " \""+fmiInfo.fmiDescription+"\""%>
    constant String fmuFile = "<%fmuFileName%>";
    constant String fmuWorkingDir = "<%fmuWorkingDirectory%>";
    constant Integer fmiLogLevel = <%fmiLogLevel%>;
    constant Boolean debugLogging = <%fmiDebugOutput%>;
    FMI1ModelExchange fmi1me = FMI1ModelExchange(fmiLogLevel, fmuWorkingDir, "<%fmiInfo.fmiModelIdentifier%>", debugLogging);
    <%dumpFMIModelVariablesList(fmiModelVariablesList, generateInputConnectors, generateOutputConnectors)%>
    constant Integer numberOfContinuousStates = <%listLength(fmiInfo.fmiNumberOfContinuousStates)%>;
    Real fmi_x[numberOfContinuousStates] "States";
    Real fmi_x_new[numberOfContinuousStates] "New States";
    constant Integer numberOfEventIndicators = <%listLength(fmiInfo.fmiNumberOfEventIndicators)%>;
    Real fmi_z[numberOfEventIndicators] "Events Indicators";
    Boolean fmi_z_positive[numberOfEventIndicators];
    parameter Real flowInstantiate(fixed=false);
    Real flowTime;
    parameter Real flowParamsStart(fixed=false);
    Real flowStatesInputs;
    Boolean callEventUpdate;
    constant Boolean intermediateResults = false;
    Boolean newStatesAvailable;
    Real triggerDSSEvent;
    Real nextEventTime;
  initial algorithm
    flowParamsStart := 0;
    <%if not boolAnd(stringEq(realStartVariablesValueReferences, ""), stringEq(realStartVariablesNames, "")) then "flowParamsStart := fmi1Functions.fmi1SetReal(fmi1me, {"+realStartVariablesValueReferences+"}, {"+realStartVariablesNames+"});"%>
    <%if not boolAnd(stringEq(integerStartVariablesValueReferences, ""), stringEq(integerStartVariablesNames, "")) then "flowParamsStart := fmi1Functions.fmi1SetInteger(fmi1me, {"+integerStartVariablesValueReferences+"}, {"+integerStartVariablesNames+"});"%>
    <%if not boolAnd(stringEq(booleanStartVariablesValueReferences, ""), stringEq(booleanStartVariablesNames, "")) then "flowParamsStart := fmi1Functions.fmi1SetBoolean(fmi1me, {"+booleanStartVariablesValueReferences+"}, {"+booleanStartVariablesNames+"});"%>
    <%if not boolAnd(stringEq(stringStartVariablesValueReferences, ""), stringEq(stringStartVariablesNames, "")) then "flowParamsStart := fmi1Functions.fmi1SetString(fmi1me, {"+stringStartVariablesValueReferences+"}, {"+stringStartVariablesNames+"});"%>
  <%if intGt(listLength(fmiInfo.fmiNumberOfContinuousStates), 0) then
    <<
      fmi_x := fmi1Functions.fmi1GetContinuousStates(fmi1me, numberOfContinuousStates, flowParamsStart);
    >>
  %>
  equation
    flowTime = fmi1Functions.fmi1SetTime(fmi1me, time);
    flowStatesInputs = fmi1Functions.fmi1SetContinuousStates(fmi1me, fmi_x, flowParamsStart + flowTime);
    der(fmi_x) = fmi1Functions.fmi1GetDerivatives(fmi1me, numberOfContinuousStates, flowStatesInputs);
    fmi_z  = fmi1Functions.fmi1GetEventIndicators(fmi1me, numberOfEventIndicators, flowStatesInputs);
    for i in 1:size(fmi_z,1) loop
      fmi_z_positive[i] = if not terminal() then fmi_z[i] > 0 else pre(fmi_z_positive[i]);
    end for;
    callEventUpdate = fmi1Functions.fmi1CompletedIntegratorStep(fmi1me, flowStatesInputs);
    triggerDSSEvent = noEvent(if callEventUpdate then flowStatesInputs+1.0 else flowStatesInputs-1.0);
    nextEventTime = fmi1Functions.fmi1nextEventTime(fmi1me, flowStatesInputs);
    <%if not boolAnd(stringEq(realVariablesNames, ""), stringEq(realVariablesValueReferences, "")) then "{"+realVariablesNames+"} = fmi1Functions.fmi1GetReal(fmi1me, {"+realVariablesValueReferences+"}, flowStatesInputs);"%>
    <%if not boolAnd(stringEq(integerVariablesNames, ""), stringEq(integerVariablesValueReferences, "")) then "{"+integerVariablesNames+"} = fmi1Functions.fmi1GetInteger(fmi1me, {"+integerVariablesValueReferences+"}, flowStatesInputs);"%>
    <%if not boolAnd(stringEq(booleanVariablesNames, ""), stringEq(booleanVariablesValueReferences, "")) then "{"+booleanVariablesNames+"} = fmi1Functions.fmi1GetBoolean(fmi1me, {"+booleanVariablesValueReferences+"}, flowStatesInputs);"%>
    <%if not boolAnd(stringEq(stringVariablesNames, ""), stringEq(stringVariablesValueReferences, "")) then "{"+stringVariablesNames+"} = fmi1Functions.fmi1GetString(fmi1me, {"+stringVariablesValueReferences+"}, flowStatesInputs);"%>
  algorithm
  <%if intGt(listLength(fmiInfo.fmiNumberOfEventIndicators), 0) then
  <<
    when {(<%fmiInfo.fmiNumberOfEventIndicators |> eventIndicator =>  "change(fmi_z_positive["+eventIndicator+"])" ;separator=" or "%>) and not initial(),triggerDSSEvent > flowStatesInputs, nextEventTime < time} then
  >>
  else
  <<
    when {not initial(), triggerDSSEvent > flowStatesInputs, nextEventTime < time} then
  >>
  %>
      (newStatesAvailable) := fmi1Functions.fmi1EventUpdate(fmi1me, intermediateResults, flowStatesInputs);
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
          input Integer fmiLogLevel;
          input String workingDirectory;
          input String instanceName;
          input Boolean debugLogging;
          output FMI1ModelExchange fmi1me;
          external "C" fmi1me = FMI1ModelExchangeConstructor_OMC(fmiLogLevel, workingDirectory, instanceName, debugLogging) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
        end constructor;
        
        function destructor
          input FMI1ModelExchange fmi1me;
          external "C" FMI1ModelExchangeDestructor_OMC(fmi1me) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
        end destructor;
    end FMI1ModelExchange;

    package fmi1Functions
      function fmi1SetTime
        input FMI1ModelExchange fmi1me;
        input Real inTime;
        output Real status;
        external "C" status = fmi1SetTime_OMC(fmi1me, inTime) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi1SetTime;

      function fmi1GetContinuousStates
        input FMI1ModelExchange fmi1me;
        input Integer numberOfContinuousStates;
        input Real inFlowParams;
        output Real fmi_x[numberOfContinuousStates];
        external "C" fmi1GetContinuousStates_OMC(fmi1me, numberOfContinuousStates, inFlowParams, fmi_x) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi1GetContinuousStates;

      function fmi1SetContinuousStates
        input FMI1ModelExchange fmi1me;
        input Real fmi_x[:];
        input Real inFlowParams;
        output Real outFlowStates;
        external "C" outFlowStates = fmi1SetContinuousStates_OMC(fmi1me, size(fmi_x, 1), inFlowParams, fmi_x) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi1SetContinuousStates;

      function fmi1GetDerivatives
        input FMI1ModelExchange fmi1me;
        input Integer numberOfContinuousStates;
        input Real inFlowStates;
        output Real fmi_x[numberOfContinuousStates];
        external "C" fmi1GetDerivatives_OMC(fmi1me, numberOfContinuousStates, inFlowStates, fmi_x) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi1GetDerivatives;

      function fmi1GetEventIndicators
        input FMI1ModelExchange fmi1me;
        input Integer numberOfEventIndicators;
        input Real inFlowStates;
        output Real fmi_z[numberOfEventIndicators];
        external "C" fmi1GetEventIndicators_OMC(fmi1me, numberOfEventIndicators, inFlowStates, fmi_z) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi1GetEventIndicators;

      <%dumpFMI1CommonFunctions(platform)%>

      function fmi1EventUpdate
        input FMI1ModelExchange fmi1me;
        input Boolean intermediateResults;
        input Real inFlowStates;
        output Boolean outNewStatesAvailable;
        external "C" outNewStatesAvailable = fmi1EventUpdate_OMC(fmi1me, intermediateResults, inFlowStates) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi1EventUpdate;

      function fmi1nextEventTime
        input FMI1ModelExchange fmi1me;
        input Real inFlowStates;
        output Real outNewnextTime;
        external "C" outNewnextTime = fmi1nextEventTime_OMC(fmi1me, inFlowStates) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi1nextEventTime;

      function fmi1CompletedIntegratorStep
        input FMI1ModelExchange fmi1me;
        input Real inFlowStates;
        output Boolean outCallEventUpdate;
        external "C" outCallEventUpdate = fmi1CompletedIntegratorStep_OMC(fmi1me, inFlowStates) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi1CompletedIntegratorStep;
    end fmi1Functions;

    package fmiStatus
      constant Integer fmiOK=0;
      constant Integer fmiWarning=1;
      constant Integer fmiDiscard=2;
      constant Integer fmiError=3;
      constant Integer fmiFatal=4;
      constant Integer fmiPending=5;
    end fmiStatus;
  end <%fmiInfo.fmiModelIdentifier%>_<%getFMIType(fmiInfo)%>_FMU;
  >>
end importFMU1ModelExchange;

/* Fix the FMI 2.0 code generation. The one below is just the copy of FMI 1.0. Also write the wrapper C files for it. */
template importFMU2ModelExchange(FmiImport fmi)
 "Generates Modelica code for FMI Model Exchange version 2.0"
::=
match fmi
case FMIIMPORT(fmiInfo=INFO(__),fmiExperimentAnnotation=EXPERIMENTANNOTATION(__)) then
  /* Get Real varibales and their value references */
  let realVariablesNames = dumpRealVariablesName(fmiModelVariablesList)
  let realVariablesValueReferences = dumpRealVariablesVR(fmiModelVariablesList)
  /* Get start Real varibales and their value references */
  let realStartVariablesValueReferences = dumpStartRealVariablesValueReference(fmiModelVariablesList)
  let realStartVariablesNames = dumpStartRealVariablesName(fmiModelVariablesList)
  /* Get Integer varibales and their value references */
  let integerVariablesNames = dumpIntegerVariablesName(fmiModelVariablesList)
  let integerVariablesValueReferences = dumpIntegerVariablesVR(fmiModelVariablesList)
  /* Get start Integer varibales and their value references */
  let integerStartVariablesValueReferences = dumpStartIntegerVariablesValueReference(fmiModelVariablesList)
  let integerStartVariablesNames = dumpStartIntegerVariablesName(fmiModelVariablesList)
  /* Get Boolean varibales and their value references */
  let booleanVariablesNames = dumpBooleanVariablesName(fmiModelVariablesList)
  let booleanVariablesValueReferences = dumpBooleanVariablesVR(fmiModelVariablesList)
  /* Get start Boolean varibales and their value references */
  let booleanStartVariablesValueReferences = dumpStartBooleanVariablesValueReference(fmiModelVariablesList)
  let booleanStartVariablesNames = dumpStartBooleanVariablesName(fmiModelVariablesList)
  /* Get String varibales and their value references */
  let stringVariablesNames = dumpStringVariablesName(fmiModelVariablesList)
  let stringVariablesValueReferences = dumpStringVariablesVR(fmiModelVariablesList)
  /* Get start String varibales and their value references */
  let stringStartVariablesValueReferences = dumpStartStringVariablesValueReference(fmiModelVariablesList)
  let stringStartVariablesNames = dumpStartStringVariablesName(fmiModelVariablesList)
  <<
  model <%fmiInfo.fmiModelIdentifier%>_<%getFMIType(fmiInfo)%>_FMU<%if stringEq(fmiInfo.fmiDescription, "") then "" else " \""+fmiInfo.fmiDescription+"\""%>
    constant String fmuFile = "<%fmuFileName%>";
    constant String fmuWorkingDir = "<%fmuWorkingDirectory%>";
    constant Integer fmiLogLevel = <%fmiLogLevel%>;
    constant Boolean debugLogging = <%fmiDebugOutput%>;
    fmi2ImportInstance fmi = fmi2ImportInstance(context, fmuWorkingDir);
    fmi2ImportContext context = fmi2ImportContext(fmiLogLevel);
    fmi2EventInfo eventInfo;
    <%dumpFMIModelVariablesList(fmiModelVariablesList, generateInputConnectors, generateOutputConnectors)%>
    constant Integer numberOfContinuousStates = <%listLength(fmiInfo.fmiNumberOfContinuousStates)%>;
    Real fmi_x[numberOfContinuousStates] "States";
    Real fmi_x_new[numberOfContinuousStates] "New States";
    constant Integer numberOfEventIndicators = <%listLength(fmiInfo.fmiNumberOfEventIndicators)%>;
    Real fmi_z[numberOfEventIndicators] "Events Indicators";
    Boolean fmi_z_positive[numberOfEventIndicators];
    parameter Real flowInstantiate(fixed=false);
    Real flowTime;
    parameter Real flowParamsStart(fixed=false);
    Real flowStatesInputs;
    Boolean callEventUpdate;
    constant Boolean intermediateResults = false;
    Boolean newStatesAvailable;
    Integer fmi_status;
  initial algorithm
    flowInstantiate := fmiFunctions.fmi2InstantiateModel(fmi, "<%fmiInfo.fmiModelIdentifier%>", debugLogging);
    flowTime := fmiFunctions.fmi2SetTime(fmi, time);
    <%if not boolAnd(stringEq(realStartVariablesValueReferences, ""), stringEq(realStartVariablesNames, "")) then "flowParamsStart := fmiFunctions.fmi2SetReal(fmi, {"+realStartVariablesValueReferences+"}, {"+realStartVariablesNames+"});"%>
    <%if not boolAnd(stringEq(integerStartVariablesValueReferences, ""), stringEq(integerStartVariablesNames, "")) then "flowParamsStart := fmiFunctions.fmi2SetInteger(fmi, {"+integerStartVariablesValueReferences+"}, {"+integerStartVariablesNames+"});"%>
    <%if not boolAnd(stringEq(booleanStartVariablesValueReferences, ""), stringEq(booleanStartVariablesNames, "")) then "flowParamsStart := fmiFunctions.fmi2SetBoolean(fmi, {"+booleanStartVariablesValueReferences+"}, {"+booleanStartVariablesNames+"});"%>
    <%if not boolAnd(stringEq(stringStartVariablesValueReferences, ""), stringEq(stringStartVariablesNames, "")) then "flowParamsStart := fmiFunctions.fmi2SetString(fmi, {"+stringStartVariablesValueReferences+"}, {"+stringStartVariablesNames+"});"%>
    eventInfo := fmiFunctions.fmi2Initialize(fmi, eventInfo);
  <%if intGt(listLength(fmiInfo.fmiNumberOfContinuousStates), 0) then
    <<
      fmi_x := fmiFunctions.fmi2GetContinuousStates(fmi, numberOfContinuousStates, flowParamsStart);
    >>
  %>
  equation
    flowTime = fmiFunctions.fmi2SetTime(fmi, time);
    flowStatesInputs = fmiFunctions.fmi2SetContinuousStates(fmi, fmi_x, flowParamsStart + flowTime);
    der(fmi_x) = fmiFunctions.fmi2GetDerivatives(fmi, numberOfContinuousStates, flowStatesInputs);
    fmi_z  = fmiFunctions.fmi2GetEventIndicators(fmi, numberOfEventIndicators, flowStatesInputs);
    for i in 1:size(fmi_z,1) loop
      fmi_z_positive[i] = if not terminal() then fmi_z[i] > 0 else pre(fmi_z_positive[i]);
    end for;
    callEventUpdate = fmiFunctions.fmi2CompletedIntegratorStep(fmi, flowStatesInputs);
    <%if not boolAnd(stringEq(realVariablesNames, ""), stringEq(realVariablesValueReferences, "")) then "{"+dumpRealVariablesName(fmiModelVariablesList)+"} = fmiFunctions.fmi2GetReal(fmi, {"+dumpRealVariablesVR(fmiModelVariablesList)+"}, flowStatesInputs);"%>
    <%if not boolAnd(stringEq(integerVariablesNames, ""), stringEq(integerVariablesValueReferences, "")) then "{"+dumpIntegerVariablesName(fmiModelVariablesList)+"} = fmiFunctions.fmi2GetInteger(fmi, {"+dumpIntegerVariablesVR(fmiModelVariablesList)+"}, flowStatesInputs);"%>
    <%if not boolAnd(stringEq(booleanVariablesNames, ""), stringEq(booleanVariablesValueReferences, "")) then "{"+dumpBooleanVariablesName(fmiModelVariablesList)+"} = fmiFunctions.fmi2GetBoolean(fmi, {"+dumpBooleanVariablesVR(fmiModelVariablesList)+"}, flowStatesInputs);"%>
    <%if not boolAnd(stringEq(stringVariablesNames, ""), stringEq(stringVariablesValueReferences, "")) then "{"+dumpStringVariablesName(fmiModelVariablesList)+"} = fmiFunctions.fmi2GetString(fmi, {"+dumpStringVariablesVR(fmiModelVariablesList)+"}, flowStatesInputs);"%>
  algorithm
  <%if intGt(listLength(fmiInfo.fmiNumberOfEventIndicators), 0) then
  <<
    when (<%fmiInfo.fmiNumberOfEventIndicators |> eventIndicator =>  "change(fmi_z_positive["+eventIndicator+"])" ;separator=" or "%>) and not initial() then
  >>
  else
  <<
    when not initial() then
  >>
  %>
      (newStatesAvailable) := fmiFunctions.fmi2EventUpdate(fmi, intermediateResults, eventInfo, flowStatesInputs);
  <%if intGt(listLength(fmiInfo.fmiNumberOfContinuousStates), 0) then
  <<
      if newStatesAvailable then
        fmi_x_new := fmiFunctions.fmi2GetContinuousStates(fmi, numberOfContinuousStates, flowStatesInputs);
        <%fmiInfo.fmiNumberOfContinuousStates |> continuousStates =>  "reinit(fmi_x["+continuousStates+"], fmi_x_new["+continuousStates+"]);" ;separator="\n"%>
      end if;
  >>
  %>
    end when;
    when terminal() then
      fmi_status := fmiFunctions.fmi2Terminate(fmi);
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
    <%dumpFMI2CommonObjects(platform)%>

    class fmi2EventInfo
      extends ExternalObject;
        function constructor
        end constructor;

        function destructor
          input fmi2EventInfo eventInfo;
          external "C" fmi2FreeEventInfo_OMC(eventInfo) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
        end destructor;
    end fmi2EventInfo;

    package fmiFunctions
      function fmi2InstantiateModel
        input fmi2ImportInstance fmi;
        input String instanceName;
        input Boolean debugLogging;
        output Real outFlowInstantiate;
        external "C" outFlowInstantiate = fmi2InstantiateModel_OMC(fmi, instanceName, debugLogging) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi2InstantiateModel;

      function fmi2Initialize
        input fmi2ImportInstance fmi;
        input fmi2EventInfo inEventInfo;
        output fmi2EventInfo outEventInfo;
        external "C" outEventInfo = fmi2Initialize_OMC(fmi, inEventInfo) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi2Initialize;

      function fmi2SetTime
        input fmi2ImportInstance fmi;
        input Real inTime;
        output Real status;
        external "C" status = fmi2SetTime_OMC(fmi, inTime) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi2SetTime;

      function fmi2GetContinuousStates
        input fmi2ImportInstance fmi;
        input Integer numberOfContinuousStates;
        input Real inFlowParams;
        output Real fmi_x[numberOfContinuousStates];
        external "C" fmi2GetContinuousStates_OMC(fmi, numberOfContinuousStates, inFlowParams, fmi_x) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi2GetContinuousStates;

      function fmi2SetContinuousStates
        input fmi2ImportInstance fmi;
        input Real fmi_x[:];
        input Real inFlowParams;
        output Real outFlowStates;
        external "C" outFlowStates = fmi2SetContinuousStates_OMC(fmi, size(fmi_x, 1), inFlowParams, fmi_x) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi2SetContinuousStates;

      function fmi2GetDerivatives
        input fmi2ImportInstance fmi;
        input Integer numberOfContinuousStates;
        input Real inFlowStates;
        output Real fmi_x[numberOfContinuousStates];
        external "C" fmi2GetDerivatives_OMC(fmi, numberOfContinuousStates, inFlowStates, fmi_x) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi2GetDerivatives;

      function fmi2GetEventIndicators
        input fmi2ImportInstance fmi;
        input Integer numberOfEventIndicators;
        input Real inFlowStates;
        output Real fmi_z[numberOfEventIndicators];
        external "C" fmi2GetEventIndicators_OMC(fmi, numberOfEventIndicators, inFlowStates, fmi_z) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi2GetEventIndicators;

      <%dumpFMI2CommonFunctions(platform)%>

      function fmi2EventUpdate
        input fmi2ImportInstance fmi;
        input Boolean intermediateResults;
        input fmi2EventInfo inEventInfo;
        input Real inFlowStates;
        output Boolean outNewStatesAvailable;
        external "C" outNewStatesAvailable = fmi2EventUpdate_OMC(fmi, intermediateResults, inEventInfo, inFlowStates) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi2EventUpdate;

      function fmi2CompletedIntegratorStep
        input fmi2ImportInstance fmi;
        input Real inFlowStates;
        output Boolean outCallEventUpdate;
        external "C" outCallEventUpdate = fmi2CompletedIntegratorStep_OMC(fmi, inFlowStates) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi2CompletedIntegratorStep;

      function fmi2Terminate
        input fmi2ImportInstance fmi;
        output Integer status;
        external "C" status = fmi2Terminate_OMC(fmi) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi2Terminate;
    end fmiFunctions;

    package fmiStatus
      constant Integer fmiOK=0;
      constant Integer fmiWarning=1;
      constant Integer fmiDiscard=2;
      constant Integer fmiError=3;
      constant Integer fmiFatal=4;
      constant Integer fmiPending=5;
    end fmiStatus;
  end <%fmiInfo.fmiModelIdentifier%>_<%getFMIType(fmiInfo)%>_FMU;
  >>
end importFMU2ModelExchange;

template importFMUCoSimulationStandAlone(FmiImport fmi)
 "Generates Modelica code for FMI Co-simulation stand alone."
::=
match fmi
case FMIIMPORT(fmiInfo=INFO(__)) then
  match fmiInfo.fmiVersion
    case "1.0" then
      importFMU1CoSimulationStandAlone(fmi)
    case "2.0" then
      importFMU2CoSimulationStandAlone(fmi)
end importFMUCoSimulationStandAlone;

template importFMU1CoSimulationStandAlone(FmiImport fmi)
 "Generates Modelica code for FMI Co-simulation stand alone version 1.0"
::=
match fmi
case FMIIMPORT(fmiInfo=INFO(__),fmiExperimentAnnotation=EXPERIMENTANNOTATION(__)) then
  /* Get Real varibales and their value references */
  let realVariablesNames = dumpRealVariablesName(fmiModelVariablesList)
  let realVariablesValueReferences = dumpRealVariablesVR(fmiModelVariablesList)
  /* Get start Real varibales and their value references */
  let realStartVariablesValueReferences = dumpStartRealVariablesValueReference(fmiModelVariablesList)
  let realStartVariablesNames = dumpStartRealVariablesName(fmiModelVariablesList)
  /* Get Integer varibales and their value references */
  let integerVariablesNames = dumpIntegerVariablesName(fmiModelVariablesList)
  let integerVariablesValueReferences = dumpIntegerVariablesVR(fmiModelVariablesList)
  /* Get start Integer varibales and their value references */
  let integerStartVariablesValueReferences = dumpStartIntegerVariablesValueReference(fmiModelVariablesList)
  let integerStartVariablesNames = dumpStartIntegerVariablesName(fmiModelVariablesList)
  /* Get Boolean varibales and their value references */
  let booleanVariablesNames = dumpBooleanVariablesName(fmiModelVariablesList)
  let booleanVariablesValueReferences = dumpBooleanVariablesVR(fmiModelVariablesList)
  /* Get start Boolean varibales and their value references */
  let booleanStartVariablesValueReferences = dumpStartBooleanVariablesValueReference(fmiModelVariablesList)
  let booleanStartVariablesNames = dumpStartBooleanVariablesName(fmiModelVariablesList)
  /* Get String varibales and their value references */
  let stringVariablesNames = dumpStringVariablesName(fmiModelVariablesList)
  let stringVariablesValueReferences = dumpStringVariablesVR(fmiModelVariablesList)
  /* Get start String varibales and their value references */
  let stringStartVariablesValueReferences = dumpStartStringVariablesValueReference(fmiModelVariablesList)
  let stringStartVariablesNames = dumpStartStringVariablesName(fmiModelVariablesList)
  <<
  model <%fmiInfo.fmiModelIdentifier%>_<%getFMIType(fmiInfo)%>_FMU<%if stringEq(fmiInfo.fmiDescription, "") then "" else " \""+fmiInfo.fmiDescription+"\""%>
    constant String fmuFile = "<%fmuFileName%>";
    constant String fmuWorkingDir = "<%fmuWorkingDirectory%>";
    constant Integer fmiLogLevel = <%fmiLogLevel%>;
    constant Boolean debugLogging = <%fmiDebugOutput%>;
    constant String mimeType = "";
    constant Real timeout = 0.0;
    constant Boolean visible = false;
    constant Boolean interactive = false;
    constant Real communicationStepSize = 0.005;
    fmi1ImportInstance fmi = fmi1ImportInstance(context, fmuWorkingDir);
    fmi1ImportContext context = fmi1ImportContext(fmiLogLevel);
    <%dumpFMIModelVariablesList(fmiModelVariablesList, generateInputConnectors, generateOutputConnectors)%>
    constant Boolean stopTimeDefined = false;
    Real flowControl;
    Boolean initializationDone(start=false);
  initial algorithm
    if not initializationDone then
      fmiFunctions.fmi1InstantiateSlave(fmi, "<%fmiInfo.fmiModelIdentifier%>", fmuFile, mimeType, timeout, visible, interactive, debugLogging);
      fmiFunctions.fmi1InitializeSlave(fmi, <%fmiExperimentAnnotation.fmiExperimentStartTime%>, stopTimeDefined, <%fmiExperimentAnnotation.fmiExperimentStopTime%>);
      initializationDone := true;
    end if;
  algorithm
    initializationDone := true;
  equation
    flowControl = fmiFunctions.fmi1DoStep(fmi, time, communicationStepSize, true);
    <%if not boolAnd(stringEq(realVariablesNames, ""), stringEq(realVariablesValueReferences, "")) then "{"+dumpRealVariablesName(fmiModelVariablesList)+"} = fmiFunctions.fmi1GetReal(fmi, {"+dumpRealVariablesVR(fmiModelVariablesList)+"}, flowControl);"%>
    <%if not boolAnd(stringEq(integerVariablesNames, ""), stringEq(integerVariablesValueReferences, "")) then "{"+dumpIntegerVariablesName(fmiModelVariablesList)+"} = fmiFunctions.fmi1GetInteger(fmi, {"+dumpIntegerVariablesVR(fmiModelVariablesList)+"}, flowControl);"%>
    <%if not boolAnd(stringEq(booleanVariablesNames, ""), stringEq(booleanVariablesValueReferences, "")) then "{"+dumpBooleanVariablesName(fmiModelVariablesList)+"} = fmiFunctions.fmi1GetBoolean(fmi, {"+dumpBooleanVariablesVR(fmiModelVariablesList)+"}, flowControl);"%>
    <%if not boolAnd(stringEq(stringVariablesNames, ""), stringEq(stringVariablesValueReferences, "")) then "{"+dumpStringVariablesName(fmiModelVariablesList)+"} = fmiFunctions.fmi1GetString(fmi, {"+dumpStringVariablesVR(fmiModelVariablesList)+"}, flowControl);"%>
  algorithm
    when terminal() then
      fmiFunctions.fmi1TerminateSlave(fmi);
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
    <%dumpFMI1CommonObjects(platform)%>

    package fmiFunctions
      function fmi1InstantiateSlave
        input fmi1ImportInstance fmi;
        input String instanceName;
        input String fmuLocation;
        input String mimeType;
        input Real timeout;
        input Boolean visible;
        input Boolean interactive;
        input Boolean debugLogging;
        external "C" fmi1InstantiateSlave_OMC(fmi, instanceName, fmuLocation, mimeType, timeout, visible, interactive, debugLogging) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi1InstantiateSlave;

      function fmi1InitializeSlave
        input fmi1ImportInstance fmi;
        input Real tStart;
        input Boolean stopTimeDefined;
        input Real tStop;
        external "C" fmi1InitializeSlave_OMC(fmi, tStart, stopTimeDefined, tStop) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi1InitializeSlave;

      function fmi1DoStep
        input fmi1ImportInstance fmi;
        input Real currentCommunicationPoint;
        input Real communicationStepSize;
        input Boolean newStep;
        output Real outFlowControl;
        external "C" outFlowControl = fmi1DoStep_OMC(fmi, currentCommunicationPoint, communicationStepSize, newStep) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi1DoStep;

      <%dumpFMI1CommonFunctions(platform)%>

      function fmi1TerminateSlave
        input fmi1ImportInstance fmi;
        output Integer status;
        external "C" status = fmi1TerminateSlave_OMC(fmi) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end fmi1TerminateSlave;
    end fmiFunctions;

    package fmiStatus
      constant Integer fmiOK=0;
      constant Integer fmiWarning=1;
      constant Integer fmiDiscard=2;
      constant Integer fmiError=3;
      constant Integer fmiFatal=4;
      constant Integer fmiPending=5;
    end fmiStatus;
  end <%fmiInfo.fmiModelIdentifier%>_<%getFMIType(fmiInfo)%>_FMU;
  >>
end importFMU1CoSimulationStandAlone;

template importFMU2CoSimulationStandAlone(FmiImport fmi)
 "Generates Modelica code for FMI Co-simulation stand alone version 2.0"
::=
<<
>>
end importFMU2CoSimulationStandAlone;

template dumpFMI1CommonObjects(String platform)
  "Generates the common FMI external objects used by OMC to reference FMIL Objects."
::=
  <<
  class fmi1ImportContext
    extends ExternalObject;
      function constructor
        input Integer fmiLogLevel;
        output fmi1ImportContext context;
        external "C" context = fmi1ImportContext_OMC(fmiLogLevel) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end constructor;

      function destructor
        input fmi1ImportContext context;
        external "C" fmi1ImportFreeContext_OMC(context) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end destructor;
  end fmi1ImportContext;

  class fmi1ImportInstance
    extends ExternalObject;
      function constructor
        input fmi1ImportContext context;
        input String tempPath;
        output fmi1ImportInstance fmi;
        external "C" fmi = fmi1ImportInstance_OMC(context, tempPath) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end constructor;

      function destructor
        input fmi1ImportInstance fmi;
        external "C" fmi1ImportFreeInstance_OMC(fmi) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end destructor;
  end fmi1ImportInstance;
  >>
end dumpFMI1CommonObjects;

template dumpFMI2CommonObjects(String platform)
  "Generates the common FMI 2.0 external objects used by OMC to reference FMIL Objects."
::=
  <<
  class fmi2ImportContext
    extends ExternalObject;
      function constructor
        input Integer fmiLogLevel;
        output fmi2ImportContext context;
        external "C" context = fmi2ImportContext_OMC(fmiLogLevel) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end constructor;

      function destructor
        input fmi2ImportContext context;
        external "C" fmi2ImportFreeContext_OMC(context) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end destructor;
  end fmi2ImportContext;

  class fmi2ImportInstance
    extends ExternalObject;
      function constructor
        input fmi2ImportContext context;
        input String tempPath;
        output fmi2ImportInstance fmi;
        external "C" fmi = fmi2ImportInstance_OMC(context, tempPath) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end constructor;

      function destructor
        input fmi2ImportInstance fmi;
        external "C" fmi2ImportFreeInstance_OMC(fmi) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
      end destructor;
  end fmi2ImportInstance;
  >>
end dumpFMI2CommonObjects;

template dumpFMI1CommonFunctions(String platform)
 "Generates the common FMI 1.0 functions wrapped by OMC."
::=
  <<
  function fmi1GetReal
    input FMI1ModelExchange fmi1me;
    input Real realValuesReferences[:];
    input Real inFlowStatesInput;
    output Real realValues[size(realValuesReferences, 1)];
    external "C" fmi1GetReal_OMC(fmi1me, size(realValuesReferences, 1), realValuesReferences, inFlowStatesInput, realValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi1GetReal;

  function fmi1SetReal
    input FMI1ModelExchange fmi1me;
    input Real realValuesReferences[:];
    input Real realValues[size(realValuesReferences, 1)];
    output Real outFlowParams;
    external "C" outFlowParams = fmi1SetReal_OMC(fmi1me, size(realValuesReferences, 1), realValuesReferences, realValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi1SetReal;

  function fmi1GetInteger
    input FMI1ModelExchange fmi1me;
    input Real integerValuesReferences[:];
    input Real inFlowStatesInput;
    output Integer integerValues[size(integerValuesReferences, 1)];
    external "C" fmi1GetInteger_OMC(fmi1me, size(integerValuesReferences, 1), integerValuesReferences, inFlowStatesInput, integerValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi1GetInteger;

  function fmi1SetInteger
    input FMI1ModelExchange fmi1me;
    input Real integerValuesReferences[:];
    input Integer integerValues[size(integerValuesReferences, 1)];
    output Real outFlowParams;
    external "C" outFlowParams = fmi1SetInteger_OMC(fmi1me, size(integerValuesReferences, 1), integerValuesReferences, integerValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi1SetInteger;

  function fmi1GetBoolean
    input FMI1ModelExchange fmi1me;
    input Real booleanValuesReferences[:];
    input Real inFlowStatesInput;
    output Boolean booleanValues[size(booleanValuesReferences, 1)];
    external "C" fmi1GetBoolean_OMC(fmi1me, size(booleanValuesReferences, 1), booleanValuesReferences, inFlowStatesInput, booleanValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi1GetBoolean;

  function fmi1SetBoolean
    input FMI1ModelExchange fmi1me;
    input Real booleanValuesReferences[:];
    input Boolean booleanValues[size(booleanValuesReferences, 1)];
    output Real outFlowParams;
    external "C" outFlowParams = fmi1SetBoolean_OMC(fmi1me, size(booleanValuesReferences, 1), booleanValuesReferences, booleanValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi1SetBoolean;

  function fmi1GetString
    input FMI1ModelExchange fmi1me;
    input Real stringValuesReferences[:];
    input Real inFlowStatesInput;
    output String stringValues[size(stringValuesReferences, 1)];
    external "C" fmi1GetString_OMC(fmi1me, size(stringValuesReferences, 1), stringValuesReferences, inFlowStatesInput, stringValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi1GetString;

  function fmi1SetString
    input FMI1ModelExchange fmi1me;
    input Real stringValuesReferences[:];
    input String stringValues[size(stringValuesReferences, 1)];
    output Real outFlowParams;
    external "C" outFlowParams = fmi1SetString_OMC(fmi1me, size(stringValuesReferences, 1), stringValuesReferences, stringValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi1SetString;
  >>
end dumpFMI1CommonFunctions;

template dumpFMI2CommonFunctions(String platform)
 "Generates the common FMI 2.0 functions wrapped by OMC."
::=
  <<
  function fmi2GetReal
    input fmi2ImportInstance fmi;
    input Real realValuesReferences[:];
    input Real inFlowStatesInput;
    output Real realValues[size(realValuesReferences, 1)];
    external "C" fmi2GetReal_OMC(fmi, size(realValuesReferences, 1), realValuesReferences, inFlowStatesInput, realValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi2GetReal;

  function fmi2SetReal
    input fmi2ImportInstance fmi;
    input Real realValuesReferences[:];
    input Real realValues[size(realValuesReferences, 1)];
    output Real outFlowParams;
    external "C" outFlowParams = fmi2SetReal_OMC(fmi, size(realValuesReferences, 1), realValuesReferences, realValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi2SetReal;

  function fmi2GetInteger
    input fmi2ImportInstance fmi;
    input Real integerValuesReferences[:];
    input Real inFlowStatesInput;
    output Integer integerValues[size(integerValuesReferences, 1)];
    external "C" fmi2GetInteger_OMC(fmi, size(integerValuesReferences, 1), integerValuesReferences, inFlowStatesInput, integerValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi2GetInteger;

  function fmi2SetInteger
    input fmi2ImportInstance fmi;
    input Real integerValuesReferences[:];
    input Integer integerValues[size(integerValuesReferences, 1)];
    output Real outFlowParams;
    external "C" outFlowParams = fmi2SetInteger_OMC(fmi, size(integerValuesReferences, 1), integerValuesReferences, integerValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi2SetInteger;

  function fmi2GetBoolean
    input fmi2ImportInstance fmi;
    input Real booleanValuesReferences[:];
    input Real inFlowStatesInput;
    output Boolean booleanValues[size(booleanValuesReferences, 1)];
    external "C" fmi2GetBoolean_OMC(fmi, size(booleanValuesReferences, 1), booleanValuesReferences, inFlowStatesInput, booleanValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi2GetBoolean;

  function fmi2SetBoolean
    input fmi2ImportInstance fmi;
    input Real booleanValuesReferences[:];
    input Boolean booleanValues[size(booleanValuesReferences, 1)];
    output Real outFlowParams;
    external "C" outFlowParams = fmi2SetBoolean_OMC(fmi, size(booleanValuesReferences, 1), booleanValuesReferences, booleanValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi2SetBoolean;

  function fmi2GetString
    input fmi2ImportInstance fmi;
    input Real stringValuesReferences[:];
    input Real inFlowStatesInput;
    output String stringValues[size(stringValuesReferences, 1)];
    external "C" fmi2GetString_OMC(fmi, size(stringValuesReferences, 1), stringValuesReferences, inFlowStatesInput, stringValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi2GetString;

  function fmi2SetString
    input fmi2ImportInstance fmi;
    input Real stringValuesReferences[:];
    input String stringValues[size(stringValuesReferences, 1)];
    output Real outFlowParams;
    external "C" outFlowParams = fmi2SetString_OMC(fmi, size(stringValuesReferences, 1), stringValuesReferences, stringValues) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"<%if stringEq(platform, "win32") then ", \"shlwapi\""%>});
  end fmi2SetString;
  >>
end dumpFMI2CommonFunctions;

template dumpFMIModelVariablesList(list<ModelVariables> fmiModelVariablesList, Boolean generateInputConnectors, Boolean generateOutputConnectors)
 "Generates the Model Variables code."
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpFMIModelVariable(fmiModelVariable, generateInputConnectors, generateOutputConnectors) ;separator="\n"%>
  >>
end dumpFMIModelVariablesList;

template dumpFMIModelVariable(ModelVariables fmiModelVariable, Boolean generateInputConnectors, Boolean generateOutputConnectors)
::=
match fmiModelVariable
case REALVARIABLE(__) then
  <<
  <%dumpFMIModelVariableVariability(variability)%><%dumpFMIModelVariableCausalityAndBaseType(causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%name%><%dumpFMIRealModelVariableStartValue(hasStartValue, startValue, isFixed)%><%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
  >>
case INTEGERVARIABLE(__) then
  <<
  <%dumpFMIModelVariableVariability(variability)%><%dumpFMIModelVariableCausalityAndBaseType(causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%name%><%dumpFMIIntegerModelVariableStartValue(hasStartValue, startValue, isFixed)%><%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
  >>
case BOOLEANVARIABLE(__) then
  <<
  <%dumpFMIModelVariableVariability(variability)%><%dumpFMIModelVariableCausalityAndBaseType(causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%name%><%dumpFMIBooleanModelVariableStartValue(hasStartValue, startValue, isFixed)%><%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
  >>
case STRINGVARIABLE(__) then
  <<
  <%dumpFMIModelVariableVariability(variability)%><%dumpFMIModelVariableCausalityAndBaseType(causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%name%><%dumpFMIStringModelVariableStartValue(hasStartValue, startValue, isFixed)%><%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
  >>
case ENUMERATIONVARIABLE(__) then
  <<
  <%dumpFMIModelVariableVariability(variability)%><%dumpFMIModelVariableCausalityAndBaseType(causality, baseType, generateInputConnectors, generateOutputConnectors)%> <%name%><%dumpFMIIntegerModelVariableStartValue(hasStartValue, startValue, isFixed)%><%dumpFMIModelVariableDescription(description)%><%dumpFMIModelVariablePlacementAnnotation(x1Placement, x2Placement, y1Placement, y2Placement, generateInputConnectors, generateOutputConnectors, causality)%>;
  >>
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

template dumpFMIRealModelVariableStartValue(Boolean hasStartValue, Real startValue, Boolean isFixed)
::=
  <<
  <%if hasStartValue then "(start="+startValue%><%if boolAnd(hasStartValue,isFixed) then ",fixed=true"%><%if boolAnd(boolNot(hasStartValue),isFixed) then "(fixed=true"%><%if boolOr(hasStartValue,isFixed) then ")"%>
  >>
end dumpFMIRealModelVariableStartValue;

template dumpFMIIntegerModelVariableStartValue(Boolean hasStartValue, Integer startValue, Boolean isFixed)
::=
  <<
  <%if hasStartValue then "(start="+startValue%><%if boolAnd(hasStartValue,isFixed) then ",fixed=true"%><%if boolAnd(boolNot(hasStartValue),isFixed) then "(fixed=true"%><%if boolOr(hasStartValue,isFixed) then ")"%>
  >>
end dumpFMIIntegerModelVariableStartValue;

template dumpFMIBooleanModelVariableStartValue(Boolean hasStartValue, Boolean startValue, Boolean isFixed)
::=
  <<
  <%if hasStartValue then "(start="+startValue%><%if boolAnd(hasStartValue,isFixed) then ",fixed=true"%><%if boolAnd(boolNot(hasStartValue),isFixed) then "(fixed=true"%><%if boolOr(hasStartValue,isFixed) then ")"%>
  >>
end dumpFMIBooleanModelVariableStartValue;

template dumpFMIStringModelVariableStartValue(Boolean hasStartValue, String startValue, Boolean isFixed)
::=
  <<
  <%if hasStartValue then "(start=\""+startValue+"\""%><%if boolAnd(hasStartValue,isFixed) then ",fixed=true"%><%if boolAnd(boolNot(hasStartValue),isFixed) then "(fixed=true"%><%if boolOr(hasStartValue,isFixed) then ")"%>
  >>
end dumpFMIStringModelVariableStartValue;

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

template dumpRealVariablesVR(list<ModelVariables> fmiModelVariablesList)
 "Generates the Model Variables value reference arrays."
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpRealVariableVR(fmiModelVariable) ;separator=", "%>
  >>
end dumpRealVariablesVR;

template dumpRealVariableVR(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case REALVARIABLE(variability = "",causality="") then
  <<
  <%valueReference%>
  >>
case REALVARIABLE(variability = "",causality="output") then
  <<
  <%valueReference%>
  >>
end dumpRealVariableVR;

template dumpIntegerVariablesVR(list<ModelVariables> fmiModelVariablesList)
 "Generates the Model Variables value reference arrays."
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpIntegerVariableVR(fmiModelVariable) ;separator=", "%>
  >>
end dumpIntegerVariablesVR;

template dumpIntegerVariableVR(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case INTEGERVARIABLE(variability = "",causality="") then
  <<
  <%valueReference%>
  >>
case INTEGERVARIABLE(variability = "",causality="output") then
  <<
  <%valueReference%>
  >>
end dumpIntegerVariableVR;

template dumpBooleanVariablesVR(list<ModelVariables> fmiModelVariablesList)
 "Generates the Model Variables value reference arrays."
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpBooleanVariableVR(fmiModelVariable) ;separator=", "%>
  >>
end dumpBooleanVariablesVR;

template dumpBooleanVariableVR(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case BOOLEANVARIABLE(variability = "",causality="") then
  <<
  <%valueReference%>
  >>
case BOOLEANVARIABLE(variability = "",causality="output") then
  <<
  <%valueReference%>
  >>
end dumpBooleanVariableVR;

template dumpStringVariablesVR(list<ModelVariables> fmiModelVariablesList)
 "Generates the Model Variables value reference arrays."
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpStringVariableVR(fmiModelVariable) ;separator=", "%>
  >>
end dumpStringVariablesVR;

template dumpStringVariableVR(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case STRINGVARIABLE(variability = "",causality="") then
  <<
  <%valueReference%>
  >>
case STRINGVARIABLE(variability = "",causality="output") then
  <<
  <%valueReference%>
  >>
end dumpStringVariableVR;

template dumpStartRealVariablesValueReference(list<ModelVariables> fmiModelVariablesList)
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpStartRealVariableValueReference(fmiModelVariable) ;separator=", "%>
  >>
end dumpStartRealVariablesValueReference;

template dumpStartRealVariableValueReference(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case REALVARIABLE(hasStartValue = true, isFixed = false) then
  <<
  <%valueReference%>
  >>
case REALVARIABLE(causality="input") then
  <<
  <%valueReference%>
  >>
end dumpStartRealVariableValueReference;

template dumpStartRealVariablesName(list<ModelVariables> fmiModelVariablesList)
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpStartRealVariableName(fmiModelVariable) ;separator=", "%>
  >>
end dumpStartRealVariablesName;

template dumpStartRealVariableName(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case REALVARIABLE(hasStartValue = true, isFixed = false) then
  <<
  <%name%>
  >>
case REALVARIABLE(causality="input") then
  <<
  <%name%>
  >>
end dumpStartRealVariableName;

template dumpStartIntegerVariablesValueReference(list<ModelVariables> fmiModelVariablesList)
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpStartIntegerVariableValueReference(fmiModelVariable) ;separator=", "%>
  >>
end dumpStartIntegerVariablesValueReference;

template dumpStartIntegerVariableValueReference(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case INTEGERVARIABLE(hasStartValue = true, isFixed = false) then
  <<
  <%valueReference%>
  >>
case INTEGERVARIABLE(causality="input") then
  <<
  <%valueReference%>
  >>
end dumpStartIntegerVariableValueReference;

template dumpStartIntegerVariablesName(list<ModelVariables> fmiModelVariablesList)
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpStartIntegerVariableName(fmiModelVariable) ;separator=", "%>
  >>
end dumpStartIntegerVariablesName;

template dumpStartIntegerVariableName(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case INTEGERVARIABLE(hasStartValue = true, isFixed = false) then
  <<
  <%name%>
  >>
case INTEGERVARIABLE(causality="input") then
  <<
  <%name%>
  >>
end dumpStartIntegerVariableName;

template dumpStartBooleanVariablesValueReference(list<ModelVariables> fmiModelVariablesList)
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpStartBooleanVariableValueReference(fmiModelVariable) ;separator=", "%>
  >>
end dumpStartBooleanVariablesValueReference;

template dumpStartBooleanVariableValueReference(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case BOOLEANVARIABLE(hasStartValue = true, isFixed = false) then
  <<
  <%valueReference%>
  >>
case BOOLEANVARIABLE(causality="input") then
  <<
  <%valueReference%>
  >>
end dumpStartBooleanVariableValueReference;

template dumpStartBooleanVariablesName(list<ModelVariables> fmiModelVariablesList)
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpStartBooleanVariableName(fmiModelVariable) ;separator=", "%>
  >>
end dumpStartBooleanVariablesName;

template dumpStartBooleanVariableName(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case BOOLEANVARIABLE(hasStartValue = true, isFixed = false) then
  <<
  <%name%>
  >>
case BOOLEANVARIABLE(causality="input") then
  <<
  <%name%>
  >>
end dumpStartBooleanVariableName;

template dumpStartStringVariablesValueReference(list<ModelVariables> fmiModelVariablesList)
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpStartStringVariableValueReference(fmiModelVariable) ;separator=", "%>
  >>
end dumpStartStringVariablesValueReference;

template dumpStartStringVariableValueReference(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case STRINGVARIABLE(hasStartValue = true, isFixed = false) then
  <<
  <%valueReference%>
  >>
case STRINGVARIABLE(causality="input") then
  <<
  <%valueReference%>
  >>
end dumpStartStringVariableValueReference;

template dumpStartStringVariablesName(list<ModelVariables> fmiModelVariablesList)
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpStartStringVariableName(fmiModelVariable) ;separator=", "%>
  >>
end dumpStartStringVariablesName;

template dumpStartStringVariableName(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case STRINGVARIABLE(hasStartValue = true, isFixed = false) then
  <<
  <%name%>
  >>
case STRINGVARIABLE(causality="input") then
  <<
  <%name%>
  >>
end dumpStartStringVariableName;

template dumpRealVariablesName(list<ModelVariables> fmiModelVariablesList)
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpRealVariableName(fmiModelVariable) ;separator=", "%>
  >>
end dumpRealVariablesName;

template dumpRealVariableName(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case REALVARIABLE(variability = "",causality="") then
  <<
  <%name%>
  >>
case REALVARIABLE(variability = "",causality="output") then
  <<
  <%name%>
  >>
end dumpRealVariableName;

template dumpIntegerVariablesName(list<ModelVariables> fmiModelVariablesList)
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpIntegerVariableName(fmiModelVariable) ;separator=", "%>
  >>
end dumpIntegerVariablesName;

template dumpIntegerVariableName(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case INTEGERVARIABLE(variability = "",causality="") then
  <<
  <%name%>
  >>
case INTEGERVARIABLE(variability = "",causality="output") then
  <<
  <%name%>
  >>
end dumpIntegerVariableName;

template dumpBooleanVariablesName(list<ModelVariables> fmiModelVariablesList)
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpBooleanVariableName(fmiModelVariable) ;separator=", "%>
  >>
end dumpBooleanVariablesName;

template dumpBooleanVariableName(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case BOOLEANVARIABLE(variability = "",causality="") then
  <<
  <%name%>
  >>
case BOOLEANVARIABLE(variability = "",causality="output") then
  <<
  <%name%>
  >>
end dumpBooleanVariableName;

template dumpStringVariablesName(list<ModelVariables> fmiModelVariablesList)
::=
  <<
  <%fmiModelVariablesList |> fmiModelVariable => dumpStringVariableName(fmiModelVariable) ;separator=", "%>
  >>
end dumpStringVariablesName;

template dumpStringVariableName(ModelVariables fmiModelVariable)
::=
match fmiModelVariable
case STRINGVARIABLE(variability = "",causality="") then
  <<
  <%name%>
  >>
case STRINGVARIABLE(variability = "",causality="output") then
  <<
  <%name%>
  >>
end dumpStringVariableName;

end CodegenFMU;

// vim: filetype=susan sw=2 sts=2
