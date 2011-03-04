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

package SimCodeFMU

import interface SimCodeTV;
import SimCodeC.*; //unqualified import, no need the SimCodeC is optional when calling a template; or mandatory when the same named template exists in this package (name hiding) 


template translateModel(SimCode simCode) 
 "Generates C code and Makefile for compiling a FMU of a
  Modelica model."
::=
match simCode
case SIMCODE(__) then
  let guid = getUUIDStr()
  let()= textFile(fmuModelDescriptionFile(simCode,guid), 'modelDescription.xml')
  let()= textFile(fmumodel_identifierFile(simCode,guid), '<%fileNamePrefix%>_FMU.cpp')
  let()= textFile(fmuMakefile(simCode), '<%fileNamePrefix%>_FMU.makefile')
  "" // Return empty result since result written to files directly
end translateModel;


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
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__))) then
  let fmiVersion = '1.0' 
  let modelName = dotPath(modelInfo.name)
  let modelIdentifier = fileNamePrefix
  let description = ''
  let author = ''
  let version= '' 
  let generationTool= 'OpenModelica Compiler <%getVersionNr()%>'
  let generationDateAndTime = xsdateTime(getCurrentDateTime())
  let variableNamingConvention= 'structured'
  let numberOfContinuousStates = vi.numStateVars //the same as modelInfo.varInfo.numStateVars without the vi binding; but longer
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
    ScalarVariable(var,"internal")
  ;separator="\n"%>  
  <%vars.derivativeVars |> var =>
    ScalarDerivativeVariable(var,"internal")
  ;separator="\n"%>
  <%vars.algVars |> var =>
    ScalarVariable(var,"internal")
  ;separator="\n"%>
  <%vars.paramVars |> var =>
    ScalarVariable(var,"internal")
  ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.intAlgVars |> var =>
	ScalarVariable(var,"internal")
  ;separator="\n"%>
  <%vars.intParamVars |> var =>
    ScalarVariable(var,"internal")
  ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.boolAlgVars |> var =>
    ScalarVariable(var,"internal")
  ;separator="\n"%>
  <%vars.boolParamVars |> var =>
    ScalarVariable(var,"internal")
  ;separator="\n"%>  
  <%System.tmpTickReset(0)%>
  <%vars.stringAlgVars |> var =>
    ScalarVariable(var,"internal")
  ;separator="\n"%>
  <%vars.stringParamVars |> var =>
    ScalarVariable(var,"internal")
  ;separator="\n"%> 
  </ModelVariables>  
  >>
end ModelVariables;

template ScalarVariable(SimVar simVar, String causality)
 "Generates code for ScalarVariable file for FMU target."
::=
match simVar
case SIMVAR(__) then
  <<
  <ScalarVariable 
    <%ScalarVariableAttribute(simVar,causality)%>>
    <%ScalarVariableType(type_,unit,displayUnit,initialValue,isFixed)%>
  </ScalarVariable>  
  >>
end ScalarVariable;

template ScalarDerivativeVariable(SimVar simVar, String causality)
 "Generates code for ScalarVariable file for FMU target."
::=
match simVar
case SIMVAR(__) then
  <<
  <ScalarVariable 
    <%ScalarDerivativeVariableAttribute(simVar,causality)%>>
    <%ScalarVariableType(type_,unit,displayUnit,initialValue,isFixed)%>
  </ScalarVariable>  
  >>
end ScalarDerivativeVariable;

template ScalarVariableAttribute(SimVar simVar, String causality)
 "Generates code for ScalarVariable Attribute file for FMU target."
::=
match simVar
  case SIMVAR(__) then
  let valueReference = '<%System.tmpTick()%>'
  let variability = getVariablity(varKind)
  let description = if comment then 'description="<%comment%>"' 
  let alias = getAliasVar(aliasvar)
  <<
  name="<%crefStr(name)%>_" 
  valueReference="<%valueReference%>" 
  <%description%>
  variability="<%variability%>" 
  causality="<%causality%>" 
  alias="<%alias%>"
  >>  
end ScalarVariableAttribute;

template ScalarDerivativeVariableAttribute(SimVar simVar, String causality)
 "Generates code for ScalarVariable Attribute file for FMU target."
::=
match simVar
  case SIMVAR(__) then
  let valueReference = '<%System.tmpTick()%>'
  let variability = getVariablity(varKind)
  let description = if comment then 'description="<%comment%>"' 
  let alias = getAliasVar(aliasvar)
  <<
  name="<%dervativeNameCStyle(name)%>" 
  valueReference="<%valueReference%>" 
  <%description%>
  variability="<%variability%>" 
  causality="<%causality%>" 
  alias="<%alias%>"
  >>  
end ScalarDerivativeVariableAttribute;

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
  case ALIAS(__) then "alias"
  case NEGATEDALIAS(__) then "negatedAlias"
  else "noAlias"
end getAliasVar;

template ScalarVariableType(DAE.ExpType type_, String unit, String displayUnit, Option<DAE.Exp> initialValue, Boolean isFixed)
 "Generates code for ScalarVariable Type file for FMU target."
::=
match type_
  case ET_INT(__) then '<Integer/>' 
  case ET_REAL(__) then '<Real <%ScalarVariableTypeCommonAttribute(initialValue,isFixed)%> <%ScalarVariableTypeRealAttribute(unit,displayUnit)%>/>' 
  case ET_BOOL(__) then '<Boolean/>' 
  case ET_STRING(__) then '<String/>' 
  case ET_ENUMERATION(__) then '<Enumeration/>' 
  else 'UNKOWN_TYPE'
end ScalarVariableType;

template ScalarVariableTypeCommonAttribute(Option<DAE.Exp> initialValue, Boolean isFixed)
 "Generates code for ScalarVariable Type file for FMU target."
::=
match initialValue
  case SOME(exp) then 'start="<%SimCodeC.initVal(exp)%>" fixed="<%isFixed%>"'
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


template fmumodel_identifierFile(SimCode simCode, String guid)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  
  // define class name and unique id
  #define MODEL_IDENTIFIER <%fileNamePrefix%>
  #define MODEL_GUID "{<%guid%>}"
  
  // include fmu header files, typedefs and macros
  #include "fmiModelFunctions.h"
  #include "fmu_model_interface.h"

  void setStartValues(ModelInstance *comp);
  void getEventIndicator(ModelInstance* comp, int i);
  void eventUpdate(ModelInstance* comp, fmiEventInfo* eventInfo);
  fmiReal getReal(ModelInstance* comp, const fmiValueReference vr);  
  fmiStatus setReal(ModelInstance* comp, const fmiValueReference vr, const fmiReal value);  
  fmiInteger getInteger(ModelInstance* comp, const fmiValueReference vr);  
  fmiStatus setInteger(ModelInstance* comp, const fmiValueReference vr, const fmiInteger value);  
  fmiBoolean getBoolean(ModelInstance* comp, const fmiValueReference vr);  
  fmiStatus setBoolean(ModelInstance* comp, const fmiValueReference vr, const fmiBoolean value);  
  fmiString getString(ModelInstance* comp, const fmiValueReference vr);  
  fmiStatus setString(ModelInstance* comp, const fmiValueReference vr, const fmiString value);  

  <%ModelDefineData(modelInfo)%>
  
  // implementation of the Model Exchange functions
  #include "fmu_model_interface.c"
 
  <%setStartValues(modelInfo)%>
  <%getEventIndicatorFunction(simCode)%>
  <%eventUpdateFunction(simCode)%>
  <%getRealFunction(modelInfo)%>
  <%setRealFunction(modelInfo)%>
  <%getIntegerFunction(modelInfo)%>
  <%setIntegerFunction(modelInfo)%>
  <%getBooleanFunction(modelInfo)%>
  <%setBooleanFunction(modelInfo)%>
  <%getStringFunction(modelInfo)%>
  <%setStringFunction(modelInfo)%>
  
  
  >>
end fmumodel_identifierFile;

template ModelDefineData(ModelInfo modelInfo)
 "Generates global data in simulation file."
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
let numberOfReals = intAdd(varInfo.numStateVars,intAdd(varInfo.numAlgVars,varInfo.numParams))
let numberOfIntegers = intAdd(varInfo.numIntAlgVars,varInfo.numIntParams)
let numberOfStrings = intAdd(varInfo.numStringAlgVars,varInfo.numStringParamVars)
let numberOfBooleans = intAdd(varInfo.numBoolAlgVars,varInfo.numBoolParams)
  <<
  // define model size
  #define NUMBER_OF_STATES <%varInfo.numStateVars%>
  #define NUMBER_OF_EVENT_INDICATORS <%varInfo.numZeroCrossings%>
  #define NUMBER_OF_REALS <%numberOfReals%>
  #define NUMBER_OF_INTEGERS <%numberOfIntegers%>
  #define NUMBER_OF_STRINGS <%numberOfStrings%>
  #define NUMBER_OF_BOOLEANS <%numberOfBooleans%>
  
  // define variable data for model
  <%System.tmpTickReset(0)%>
  <%vars.stateVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.derivativeVars |> var => DefineDerivativeVariables(var) ;separator="\n"%>
  <%vars.algVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.paramVars |> var => DefineVariables(var) ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.intAlgVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.intParamVars |> var => DefineVariables(var) ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.boolAlgVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.boolParamVars |> var => DefineVariables(var) ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.stringAlgVars |> var => DefineVariables(var) ;separator="\n"%>
  <%vars.stringParamVars |> var => DefineVariables(var) ;separator="\n"%>
  
  // define initial state vector as vector of value references
  #define STATES { <%vars.stateVars |> SIMVAR(__) => '<%crefStr(name)%>_'  ;separator=", "%> }
  #define STATESDERIVATIVES { <%vars.derivativeVars |> SIMVAR(__) => '<%dervativeNameCStyle(name)%>'  ;separator=", "%> }
  
  >>
end ModelDefineData;

template DefineDerivativeVariables(SimVar simVar)
 "Generates code for defining variables in c file for FMU target.  "
::=
match simVar
  case SIMVAR(__) then
  <<
  #define <%dervativeNameCStyle(name)%> <%System.tmpTick()%>
  >>
end DefineDerivativeVariables;

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
  <<
  #define <%crefStr(name)%>_ <%System.tmpTick()%> <%description%>
  >>
end DefineVariables;

template setStartValues(ModelInfo modelInfo)
 "Generates code in c file for function setStartValues() which will set start values for all variables." 
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  // Set values for all variables that define a start value
  void setStartValues(ModelInstance *comp) {
  
  <%initVals(vars.stateVars,"r","states")%>
  <%initDerivativeVals(vars.derivativeVars)%>
  <%initVals(vars.algVars,"r","algebraics")%>
  <%initVals(vars.paramVars,"r","parameters")%>
  <%initVals(vars.intParamVars,"i","intVariables.parameters")%>
  <%initVals(vars.intAlgVars,"i","intVariables.algebraics")%>
  <%initVals(vars.boolParamVars,"b","boolVariables.parameters")%>
  <%initVals(vars.boolAlgVars,"b","boolVariables.algebraics")%>
  <%initVals(vars.stringParamVars,"s","stringVariables.parameters")%>
  <%initVals(vars.stringAlgVars,"s","stringVariables.algebraics")%>  
  }
  >>
end setStartValues;

template initializeFunction(list<SimEqSystem> allEquations)
  "Generates initialize function for c file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let eqPart = (allEquations |> eq as SES_SIMPLE_ASSIGN(__) =>
      equation_(eq, contextOther, &varDecls /*BUFC*/)
    ;separator="\n")
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


template initVals(list<SimVar> varsLst, String prefix, String arrayName) ::=
  varsLst |> SIMVAR(__) =>
  <<
  globalData-><%arrayName%>[<%index%>] = <%match initialValue
    case SOME(v) then
     initVal(v)
    else 
     setDefaultVal(prefix)
    %>;
    >>  
  ;separator="\n"
end initVals;

template setDefaultVal(String prefix) 
::=
  match prefix 
  case "r" then "0.0; //default value for real"
  case "i" then "0; //default value for integer"
  case "b" then "false; //default value for bool"
  case "s" then "\"\"; //default value for string"
end setDefaultVal;

template initDerivativeVals(list<SimVar> varsLst) ::=
  varsLst |> SIMVAR(__) =>
  <<
  globalData->statesDerivatives[<%index%>] = <%match initialValue
    case SOME(v) then
     initVal(v)
    else 
     "0.0; //default"
    %>; 
    >>
  ;separator="\n"
end initDerivativeVals;

template initVal(Exp initialValue) 
::=
  match initialValue 
  case ICONST(__) then integer
  case RCONST(__) then real
  case SCONST(__) then '"<%Util.escapeModelicaStringToCString(string)%>"'
  case BCONST(__) then if bool then "true" else "false"
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

template getEventIndicatorFunction(SimCode simCode)
 "Generates get event indicator function for c file."
::=
match simCode
case SIMCODE(__) then
  <<
  // Used to get event indicators
  void getEventIndicator(ModelInstance* comp, int i) {
  }
  
  >>
end getEventIndicatorFunction;

template getRealFunction(ModelInfo modelInfo)
 "Generates getReal function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmiReal getReal(ModelInstance* comp, const fmiValueReference vr) {
    switch (vr) {
        <%vars.stateVars |> var => SwitchVars(var,"states") ;separator="\n"%>
        <%vars.derivativeVars |> var => SwitchDerivativeVariables(var) ;separator="\n"%>
        <%vars.algVars |> var => SwitchVars(var,"algebraics") ;separator="\n"%>
        <%vars.paramVars |> var => SwitchVars(var,"parameters") ;separator="\n"%>
        default: 
        	return 0.0;
    }
  }
  
  >>
end getRealFunction;

template setRealFunction(ModelInfo modelInfo)
 "Generates setReal function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  fmiStatus setReal(ModelInstance* comp, const fmiValueReference vr, const fmiReal value) {
    switch (vr) {
        <%vars.stateVars |> var => SwitchVarsSet(var,"states") ;separator="\n"%>
        <%vars.derivativeVars |> var => SwitchDerivativeVariablesSet(var) ;separator="\n"%>
        <%vars.algVars |> var => SwitchVarsSet(var,"algebraics") ;separator="\n"%>
        <%vars.paramVars |> var => SwitchVarsSet(var,"parameters") ;separator="\n"%>
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
        <%vars.intAlgVars |> var => SwitchVars(var,"intVariables.algebraics") ;separator="\n"%>
        <%vars.intParamVars |> var => SwitchVars(var,"intVariables.parameters") ;separator="\n"%>
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
        <%vars.intAlgVars |> var => SwitchVarsSet(var,"intVariables.algebraics") ;separator="\n"%>
        <%vars.intParamVars |> var => SwitchVarsSet(var,"intVariables.parameters") ;separator="\n"%>
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
        <%vars.boolAlgVars |> var => SwitchVars(var,"boolVariables.algebraics") ;separator="\n"%>
        <%vars.boolParamVars |> var => SwitchVars(var,"boolVariables.parameters") ;separator="\n"%>
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
        <%vars.boolAlgVars |> var => SwitchVarsSet(var,"boolVariables.algebraics") ;separator="\n"%>
        <%vars.boolParamVars |> var => SwitchVarsSet(var,"boolVariables.parameters") ;separator="\n"%>
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
        <%vars.stringAlgVars |> var => SwitchVars(var,"stringVariables.algebraics") ;separator="\n"%>
        <%vars.stringParamVars |> var => SwitchVars(var,"stringVariables.parameters") ;separator="\n"%>
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
  fmiStatus setString(ModelInstance* comp, const fmiValueReference vr, const fmiString value) {
    switch (vr) {
        <%vars.stringAlgVars |> var => SwitchVarsSet(var,"stringVariables.algebraics") ;separator="\n"%>
        <%vars.stringParamVars |> var => SwitchVarsSet(var,"stringVariables.parameters") ;separator="\n"%>
        default: 
        	return fmiError;
    }
    return fmiOK;
  }
  
  >>
end setStringFunction;

template SwitchVars(SimVar simVar, String arrayName)
 "Generates code for defining variables in c file for FMU target. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  <<
  case <%crefStr(name)%>_ : return globalData-><%arrayName%>[<%index%>]; break;
  >>
end SwitchVars;

template SwitchVarsSet(SimVar simVar, String arrayName)
 "Generates code for defining variables in c file for FMU target. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  <<
  case <%crefStr(name)%>_ : globalData-><%arrayName%>[<%index%>]=value; break;
  >>
end SwitchVarsSet;

template SwitchDerivativeVariables(SimVar simVar)
 "Generates code for defining variables in c file for FMU target.  "
::=
match simVar
  case SIMVAR(__) then
  <<
  case <%dervativeNameCStyle(name)%> : return globalData->statesDerivatives[<%index%>]; break;
  >>
end SwitchDerivativeVariables;

template SwitchDerivativeVariablesSet(SimVar simVar)
 "Generates code for defining variables in c file for FMU target.  "
::=
match simVar
  case SIMVAR(__) then
  <<
  case <%dervativeNameCStyle(name)%> : globalData->statesDerivatives[<%index%>]=value; break;
  >>
end SwitchDerivativeVariablesSet;

template fmuMakefile(SimCode simCode)
 "Generates the contents of the makefile for the simulation case."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__)) then
  let dirExtra = if modelInfo.directory then '-L"<%modelInfo.directory%>"' //else ""
  let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
  let libsPos1 = if not dirExtra then libsStr //else ""
  let libsPos2 = if dirExtra then libsStr // else ""
  <<
  # Makefile generated by OpenModelica
  
  CC=<%makefileParams.ccompiler%>
  CXX=<%makefileParams.cxxcompiler%>
  LINK=<%makefileParams.linker%>
  EXEEXT=<%makefileParams.exeext%>
  DLLEXT=<%makefileParams.dllext%>
  CFLAGS=-I"<%makefileParams.omhome%>/include/omc" <%makefileParams.cflags%>
  LDFLAGS=-L"<%makefileParams.omhome%>/lib/omc" <%makefileParams.ldflags%>
  SENDDATALIBS=<%makefileParams.senddatalibs%>
  
  .PHONY: <%fileNamePrefix%>
  <%fileNamePrefix%>: <%fileNamePrefix%>.cpp
  <%\t%> $(CXX) $(CFLAGS) -I. -o <%fileNamePrefix%>$(DLLEXT) <%fileNamePrefix%>.cpp <%dirExtra%> <%libsPos1%> -lsim $(LDFLAGS) -lf2c -linteractive $(SENDDATALIBS) <%libsPos2%>
  >>
end fmuMakefile;

end SimCodeFMU;

// vim: filetype=susan sw=2 sts=2
