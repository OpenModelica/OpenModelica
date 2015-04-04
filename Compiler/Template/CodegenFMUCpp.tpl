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

package CodegenFMUCpp



import interface SimCodeTV;
import CodegenUtil.*;
import CodegenCpp.*; //unqualified import, no need the CodegenC is optional when calling a template; or mandatory when the same named template exists in this package (name hiding)
import CodegenFMU.*;

template translateModel(SimCode simCode, String FMUVersion, String FMUType)
 "Generates C++ code and Makefile for compiling an FMU of a Modelica model.
  Calls CodegenCpp.translateModel for the actual model code."
::=
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
  let guid = getUUIDStr()
  let target  = simulationCodeTarget()
  let stateDerVectorName = "__zDot"
  let &extraFuncs = buffer "" /*BUFD*/
  let &extraFuncsDecl = buffer "" /*BUFD*/
  let cpp = CodegenCpp.translateModel(simCode)
  let()= textFile(fmuWriteOutputHeaderFile(simCode , &extraFuncs , &extraFuncsDecl, ""),'OMCpp<%fileNamePrefix%>WriteOutput.h')
  let()= textFile(fmuModelHeaderFile(simCode, extraFuncs, extraFuncsDecl, "",guid, FMUVersion), 'OMCpp<%fileNamePrefix%>FMU.h')
  let()= textFile(fmuModelCppFile(simCode, extraFuncs, extraFuncsDecl, "",guid, FMUVersion), 'OMCpp<%fileNamePrefix%>FMU.cpp')
  let()= textFile(fmuModelDescriptionFileCpp(simCode, extraFuncs, extraFuncsDecl, "", guid, FMUVersion, FMUType), 'modelDescription.xml')
  let()= textFile(fmudeffile(simCode, FMUVersion), '<%fileNamePrefix%>.def')
  let()= textFile(fmuMakefile(target,simCode, extraFuncs, extraFuncsDecl, "", FMUVersion), '<%fileNamePrefix%>_FMU.makefile')
 ""
   // Return empty result since result written to files directly
end translateModel;

template fmuWriteOutputHeaderFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Overrides code for writing simulation file. FMU does not write an output file"
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__),simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
  <<
  #pragma once
  #include <Core/Modelica.h>

  // Dummy code for FMU that writes no output file
  class <%lastIdentOfPath(modelInfo.name)%>WriteOutput {
   public:
    <%lastIdentOfPath(modelInfo.name)%>WriteOutput(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonLinSolverFactory, boost::shared_ptr<ISimData> simData) {}
    virtual ~<%lastIdentOfPath(modelInfo.name)%>WriteOutput() {}

    virtual void writeOutput(const IWriteOutput::OUTPUT command = IWriteOutput::UNDEF_OUTPUT) {}
    virtual IHistory* getHistory() {}

   protected:
    void initialize() {}
  };
  >>
end fmuWriteOutputHeaderFile;

template fmuModelDescriptionFileCpp(SimCode simCode,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,String guid, String FMUVersion, String FMUType)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <?xml version="1.0" encoding="UTF-8"?>
  <%
    if isFMIVersion20(FMUVersion) then fmi2ModelDescription(simCode, guid)
    else fmiModelDescriptionCpp(simCode, extraFuncs ,extraFuncsDecl, extraFuncsNamespace,guid)
  %>
  >>
end fmuModelDescriptionFileCpp;

template fmiModelDescriptionCpp(SimCode simCode,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, String guid)
 "Generates code for ModelDescription file for FMU target."
::=
//  <%UnitDefinitions(simCode, extraFuncs ,extraFuncsDecl, extraFuncsNamespace)%>
//  <%TypeDefinitions(simCode, extraFuncs ,extraFuncsDecl, extraFuncsNamespace)%>
//  <%VendorAnnotations(simCode, extraFuncs ,extraFuncsDecl, extraFuncsNamespace)%>
match simCode
case SIMCODE(__) then
  <<
  <fmiModelDescription
    <%fmiModelDescriptionAttributesCpp(simCode, extraFuncs ,extraFuncsDecl, extraFuncsNamespace,guid)%>>
    <%CodegenFMU.DefaultExperiment(simulationSettingsOpt)%>
    <%CodegenFMU.ModelVariables(modelInfo,"1.0")%>
  </fmiModelDescription>
  >>
end fmiModelDescriptionCpp;

template fmiModelDescriptionAttributesCpp(SimCode simCode,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, String guid)
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
  let numberOfContinuousStates = vi.numStateVars
  let numberOfEventIndicators = zerocrosslength(simCode, extraFuncs ,extraFuncsDecl, extraFuncsNamespace)
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
end fmiModelDescriptionAttributesCpp;

template fmuModelHeaderFile(SimCode simCode,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, String guid, String FMUVersion)
 "Generates declaration for FMU target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  let modelIdentifier = lastIdentOfPath(modelInfo.name)
  //let modelIdentifier = System.stringReplace(dotPath(modelInfo.name), ".", "_")
  <<
  // declaration for Cpp FMU target
  #include "OMCpp<%fileNamePrefix%>Extension.h"

  class <%modelIdentifier%>FMU: public <%modelIdentifier%>Extension {
   public:
    // constructor
    <%modelIdentifier%>FMU(IGlobalSettings* globalSettings,
        boost::shared_ptr<IAlgLoopSolverFactory> nonLinSolverFactory,
        boost::shared_ptr<ISimData> simData);

    // getters for given value references
    virtual void getReal(const unsigned int vr[], int nvr, double value[]);
    virtual void getInteger(const unsigned int vr[], int nvr, int value[]);
    virtual void getBoolean(const unsigned int vr[], int nvr, int value[]);
    virtual void getString(const unsigned int vr[], int nvr, string value[]);

    // setters for given value references
    virtual void setReal(const unsigned int vr[], int nvr, const double value[]);
    virtual void setInteger(const unsigned int vr[], int nvr, const int value[]);
    virtual void setBoolean(const unsigned int vr[], int nvr, const int value[]);
    virtual void setString(const unsigned int vr[], int nvr, const string value[]);
  };
  >>
end fmuModelHeaderFile;

template fmuModelCppFile(SimCode simCode,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, String guid, String FMUVersion)
 "Generates code for FMU target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  let modelName = dotPath(modelInfo.name)
  let modelShortName = lastIdentOfPath(modelInfo.name)
  //let modelIdentifier = System.stringReplace(modelName, ".", "_")
  let modelIdentifier = modelShortName
  <<
  // define model identifier and unique id
  #define MODEL_IDENTIFIER <%modelIdentifier%>
  #define MODEL_GUID "{<%guid%>}"

  #include <Core/Modelica.h>
  #include <Core/ModelicaDefine.h>
  #include <System/IMixedSystem.h>
  #include <SimulationSettings/IGlobalSettings.h>
  #include <System/IAlgLoopSolverFactory.h>
  #include <System/IMixedSystem.h>
  #include <System/IAlgLoop.h>
  #include <Solver/IAlgLoopSolver.h>
  #include <System/IAlgLoopSolverFactory.h>
  #include <SimController/ISimData.h>
  #include "OMCpp<%fileNamePrefix%>FMU.h"

  <%ModelDefineData(modelInfo)%>
  #define NUMBER_OF_EVENT_INDICATORS <%zerocrosslength(simCode, extraFuncs ,extraFuncsDecl, extraFuncsNamespace)%>

  <%if isFMIVersion20(FMUVersion) then
    '#include "FMU2/FMU2Wrapper.cpp"'
  else
    '#include "FMU/FMUWrapper.cpp"'%>
  <%if isFMIVersion20(FMUVersion) then
    '#include "FMU2/FMU2Interface.cpp"'
  else
    '#include "FMU/FMULibInterface.cpp"'%>

  // constructor
  <%modelIdentifier%>FMU::<%modelIdentifier%>FMU(IGlobalSettings* globalSettings,
      boost::shared_ptr<IAlgLoopSolverFactory> nonLinSolverFactory,
      boost::shared_ptr<ISimData> simData):
    PreVariables(<%getPreVarsCount(simCode)%>),
    <%modelIdentifier%>(globalSettings, nonLinSolverFactory, simData),
    <%modelIdentifier%>Extension(globalSettings, nonLinSolverFactory, simData) {
  }

  // getters
  <%accessFunctions(simCode, "get", modelIdentifier, modelInfo)%>
  // setters
  <%accessFunctions(simCode, "set", modelIdentifier, modelInfo)%>
  >>
  // TODO:
  // <%setDefaultStartValues(modelInfo)%>
  // <%setStartValues(modelInfo)%>
  // <%setExternalFunction(modelInfo)%>
end fmuModelCppFile;

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

template accessFunctions(SimCode simCode, String direction, String modelIdentifier, ModelInfo modelInfo)
 "Generates getters or setters for Real, Integer, Boolean, and String."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  <%accessRealFunction(simCode, direction, modelIdentifier, modelInfo)%>
  <%accessVarsFunction(simCode, direction, modelIdentifier, "Integer", "int", vars.intAlgVars, vars.intParamVars, vars.intAliasVars)%>
  <%accessVarsFunction(simCode, direction, modelIdentifier, "Boolean", "int", vars.boolAlgVars, vars.boolParamVars, vars.boolAliasVars)%>
  <%accessVarsFunction(simCode, direction, modelIdentifier, "String", "string", vars.stringAlgVars, vars.stringParamVars, vars.stringAliasVars)%>
  >>
end accessFunctions;

template accessRealFunction(SimCode simCode, String direction, String modelIdentifier, ModelInfo modelInfo)
 "Generates getReal or setReal function."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__), varInfo=VARINFO(numStateVars=numStateVars, numAlgVars=numAlgVars, numDiscreteReal=numDiscreteReal, numParams=numParams)) then
  let qualifier = if stringEq(direction, "set") then "const"
  let statesOffset = intMul(2, stringInt(numFMUStateVars(vars.stateVars)))
  <<
  void <%modelIdentifier%>FMU::<%direction%>Real(const unsigned int vr[], int nvr, <%qualifier%> double value[]) {
    for (int i = 0; i < nvr; i++)
      switch (vr[i]) {
        <%vars.stateVars |> var => accessVecVar(direction, var, 0, "__z"); separator="\n"%>
        <%vars.derivativeVars |> var => accessVecVar(direction, var, numStateVars, "__zDot"); separator="\n"%>
        <%vars.algVars |> var => accessVar(simCode, direction, var, stringInt(statesOffset)); separator="\n"%>
        <%vars.discreteAlgVars |> var => accessVar(simCode, direction, var, intAdd(stringInt(statesOffset), numAlgVars)); separator="\n"%>
        <%vars.paramVars |> var => accessVar(simCode, direction, var, intAdd(intAdd(stringInt(statesOffset), numAlgVars), numDiscreteReal)); separator="\n"%>
        <%vars.aliasVars |> var => accessVar(simCode, direction, var, intAdd(intAdd(intAdd(stringInt(statesOffset), numAlgVars), numDiscreteReal), numParams)); separator="\n"%>
        default:
          std::ostringstream message;
          message << "<%direction%>Real with wrong value reference " << vr[i];
          throw std::invalid_argument(message.str());
      }
  }

  >>
end accessRealFunction;

template numFMUStateVars(list<SimVar> stateVars)
 "Return number of states without dummy state"
::=
 if intGt(listLength(stateVars), 1) then listLength(stateVars) else (stateVars |> var => match var case SIMVAR(__) then if stringEq(crefStr(name), "$dummy") then 0 else 1)
end numFMUStateVars;

template accessVarsFunction(SimCode simCode, String direction, String modelIdentifier, String typeName, String typeImpl, list<SimVar> algVars, list<SimVar> paramVars, list<SimVar> aliasVars)
 "Generates get<%typeName%> or set<%typeName%> function."
::=
  let qualifier = if stringEq(direction, "set") then "const"
  <<
  void <%modelIdentifier%>FMU::<%direction%><%typeName%>(const unsigned int vr[], int nvr, <%qualifier%> <%typeImpl%> value[]) {
    for (int i = 0; i < nvr; i++)
      switch (vr[i]) {
        <%algVars |> var => accessVar(simCode, direction, var, 0); separator="\n"%>
        <%paramVars |> var => accessVar(simCode, direction, var, listLength(algVars)); separator="\n"%>
        <%aliasVars |> var => accessVar(simCode, direction, var, intAdd(listLength(algVars), listLength(paramVars))); separator="\n"%>
        default:
          std::ostringstream message;
          message << "<%direction%><%typeName%> with wrong value reference " << vr[i];
          throw std::invalid_argument(message.str());
      }
  }

  >>
end accessVarsFunction;

template accessVar(SimCode simCode, String direction, SimVar simVar, Integer offset)
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
    value[i] = <%cppSign%><%cppName%>; break;
  >>
  else
  <<
  case <%intAdd(offset, index)%>: <%description%>
    <%cppName%> = <%cppSign%>value[i]; break;
  >>
end accessVar;

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
  case SIMVAR(__) then
    match aliasvar
      case NEGATEDALIAS(__) then '-'
      else ''
end getCppSign;

template accessVecVar(String direction, SimVar simVar, Integer offset, String vecName)
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
end accessVecVar;

template getPlatformString2(String platform, String fileNamePrefix, String dirExtra, String libsPos1, String libsPos2, String omhome)
 "returns compilation commands for the platform. "
::=
match platform
  case "win32" then
  <<
  <%fileNamePrefix%>_FMU: <%fileNamePrefix%>.def <%fileNamePrefix%>.dll
  <%\t%> dlltool -d <%fileNamePrefix%>.def --dllname <%fileNamePrefix%>.dll --output-lib <%fileNamePrefix%>.lib --kill-at

  <%\t%> cp <%fileNamePrefix%>.dll <%fileNamePrefix%>/binaries/<%platform%>/
  <%\t%> cp <%fileNamePrefix%>.lib <%fileNamePrefix%>/binaries/<%platform%>/
  <%\t%> cp <%fileNamePrefix%>.c <%fileNamePrefix%>/sources/<%fileNamePrefix%>.c
  <%\t%> cp _<%fileNamePrefix%>.h <%fileNamePrefix%>/sources/_<%fileNamePrefix%>.h
  <%\t%> cp <%fileNamePrefix%>_FMU.c <%fileNamePrefix%>/sources/<%fileNamePrefix%>_FMU.c
  <%\t%> cp <%fileNamePrefix%>_functions.c <%fileNamePrefix%>/sources/<%fileNamePrefix%>_functions.c
  <%\t%> cp <%fileNamePrefix%>_functions.h <%fileNamePrefix%>/sources/<%fileNamePrefix%>_functions.h
  <%\t%> cp <%fileNamePrefix%>_records.c <%fileNamePrefix%>/sources/<%fileNamePrefix%>_records.c
  <%\t%> cp modelDescription.xml <%fileNamePrefix%>/modelDescription.xml
  <%\t%> cp <%omhome%>/lib/omc/libexec/gnuplot/binary/libexpat-1.dll <%fileNamePrefix%>/binaries/<%platform%>/
  <%\t%> cd <%fileNamePrefix%>&& rm -f ../<%fileNamePrefix%>.fmu&& zip -r ../<%fileNamePrefix%>.fmu *
  <%\t%> rm -rf <%fileNamePrefix%>
  <%\t%> rm -f <%fileNamePrefix%>.def <%fileNamePrefix%>.o <%fileNamePrefix%>_FMU.libs <%fileNamePrefix%>_FMU.makefile <%fileNamePrefix%>_FMU.o <%fileNamePrefix%>_records.o

  <%fileNamePrefix%>.dll: clean <%fileNamePrefix%>_FMU.o <%fileNamePrefix%>.o <%fileNamePrefix%>_records.o
  <%\t%> $(CXX) -shared -I. -o <%fileNamePrefix%>.dll <%fileNamePrefix%>_FMU.o <%fileNamePrefix%>.o <%fileNamePrefix%>_records.o  $(CPPFLAGS) <%dirExtra%> <%libsPos1%> <%libsPos2%> $(CFLAGS) $(LDFLAGS) <%match System.os() case "OSX" then "-lf2c" else "-Wl,-Bstatic -lf2c -Wl,-Bdynamic"%> -Wl,--kill-at

  <%\t%> "mkdir.exe" -p <%fileNamePrefix%>
  <%\t%> "mkdir.exe" -p <%fileNamePrefix%>/binaries
  <%\t%> "mkdir.exe" -p <%fileNamePrefix%>/binaries/<%platform%>
  <%\t%> "mkdir.exe" -p <%fileNamePrefix%>/sources
  >>
  else
  <<
  <%fileNamePrefix%>_FMU: <%fileNamePrefix%>_FMU.o <%fileNamePrefix%>.o <%fileNamePrefix%>_records.o
  <%\t%> $(CXX) -shared -I. -o <%fileNamePrefix%>$(DLLEXT) <%fileNamePrefix%>_FMU.o <%fileNamePrefix%>.o <%fileNamePrefix%>_records.o $(CPPFLAGS) <%dirExtra%> <%libsPos1%> <%libsPos2%> $(CFLAGS) $(LDFLAGS) <%match System.os() case "OSX" then "-lf2c" else "-Wl,-Bstatic -lf2c -Wl,-Bdynamic"%>

  <%\t%> mkdir -p <%fileNamePrefix%>
  <%\t%> mkdir -p <%fileNamePrefix%>/binaries

  <%\t%> mkdir -p <%fileNamePrefix%>/binaries/<%platform%>
  <%\t%> mkdir -p <%fileNamePrefix%>/sources

  <%\t%> cp <%fileNamePrefix%>$(DLLEXT) <%fileNamePrefix%>/binaries/<%platform%>/
  <%\t%> cp <%fileNamePrefix%>_FMU.libs <%fileNamePrefix%>/binaries/<%platform%>/
  <%\t%> cp <%fileNamePrefix%>.c <%fileNamePrefix%>/sources/<%fileNamePrefix%>.c
  <%\t%> cp _<%fileNamePrefix%>.h <%fileNamePrefix%>/sources/_<%fileNamePrefix%>.h
  <%\t%> cp <%fileNamePrefix%>_FMU.c <%fileNamePrefix%>/sources/<%fileNamePrefix%>_FMU.c
  <%\t%> cp <%fileNamePrefix%>_functions.c <%fileNamePrefix%>/sources/<%fileNamePrefix%>_functions.c
  <%\t%> cp <%fileNamePrefix%>_functions.h <%fileNamePrefix%>/sources/<%fileNamePrefix%>_functions.h
  <%\t%> cp <%fileNamePrefix%>_records.c <%fileNamePrefix%>/sources/<%fileNamePrefix%>_records.c
  <%\t%> cp modelDescription.xml <%fileNamePrefix%>/modelDescription.xml
  <%\t%> cd <%fileNamePrefix%>; rm -f ../<%fileNamePrefix%>.fmu && zip -r ../<%fileNamePrefix%>.fmu *
  <%\t%> rm -rf <%fileNamePrefix%>
  <%\t%> rm -f <%fileNamePrefix%>.def <%fileNamePrefix%>.o <%fileNamePrefix%>_FMU.libs <%fileNamePrefix%>_FMU.makefile <%fileNamePrefix%>_FMU.o <%fileNamePrefix%>_records.o

  >>
end getPlatformString2;

template fmuMakefile(String target, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, String FMUVersion)
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
  let ParModelicaLibs = if acceptParModelicaGrammar() then '-lOMOCLRuntime -lOpenCL' // else ""
  let extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then
    match s.method case "dassljac" then "-D_OMC_JACOBIAN "

  <<
  # Makefile generated by OpenModelica

  # Simulations use -O3 by default
  SIM_OR_DYNLOAD_OPT_LEVEL=
  MODELICAUSERCFLAGS=
  CXX=cl
  EXEEXT=.exe
  DLLEXT=.dll
  include <%makefileParams.omhome%>/include/omc/cpp/ModelicaConfig.inc
  # /Od - Optimization disabled
  # /EHa enable C++ EH (w/ SEH exceptions)
  # /fp:except - consider floating-point exceptions when generating code
  # /arch:SSE2 - enable use of instructions available with SSE2 enabled CPUs
  # /I - Include Directories
  # /DNOMINMAX - Define NOMINMAX (does what it says)
  # /TP - Use C++ Compiler
  CFLAGS=/Od /EHa /MP /fp:except /I"<%makefileParams.omhome%>/include/omc/cpp/" /I"$(BOOST_INCLUDE)" /I"$(SUITESPARSE_INCLUDE)" /I. /DNOMINMAX /TP /DNO_INTERACTIVE_DEPENDENCY

  # /ZI enable Edit and Continue debug info
  CDFLAGS = /ZI

  # /MD - link with MSVCRT.LIB
  # /link - [linker options and libraries]
  # /LIBPATH: - Directories where libs can be found
  LDFLAGS=/MD   /link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/omc/cpp/" /LIBPATH:"<%makefileParams.omhome%>/bin" OMCppSystem.lib OMCppBase.lib OMCppMath.lib OMCppModelicaExternalC.lib

  # /MDd link with MSVCRTD.LIB debug lib
  # lib names should not be appended with a d just switch to lib/omc/cpp


  FILEPREFIX=<%fileNamePrefix%>
  FUNCTIONFILE=OMCpp<%lastIdentOfPath(modelInfo.name)%>Functions.cpp
  INITFILE=OMCpp<%fileNamePrefix%>Initialize.cpp
  FACTORYFILE=OMCpp<%fileNamePrefix%>FactoryExport.cpp
  EXTENSIONFILE=OMCpp<%fileNamePrefix%>Extension.cpp
  JACOBIANFILE=OMCpp<%fileNamePrefix%>Jacobian.cpp
  WRITEOUTPUTFILE=OMCpp<%fileNamePrefix%>WriteOutput.cpp
  MAINFILE=OMCpp<%lastIdentOfPath(modelInfo.name)%><% if acceptMetaModelicaGrammar() then ".conv"%>.cpp
  MAINFILEFMU=OMCpp<%lastIdentOfPath(modelInfo.name)%>FMU.cpp
  STATESELECTIONFILE=OMCpp<%fileNamePrefix%>StateSelection.cpp
  MAINOBJ=$(MODELICA_SYSTEM_LIB)

  CALCHELPERMAINFILE=OMCpp<%fileNamePrefix%>CalcHelperMain.cpp
  ALGLOOPMAINFILE=OMCpp<%fileNamePrefix%>AlgLoopMain.cpp
  GENERATEDFILES=$(MAINFILEFMU) $(MAINFILE) $(FUNCTIONFILE) $(ALGLOOPMAINFILE)

  $(MODELICA_SYSTEM_LIB)$(DLLEXT):
  <%\t%>$(CXX) /Fe$(MODELICA_SYSTEM_LIB) $(MAINFILEFMU) $(MAINFILE) $(CALCHELPERMAINFILE) $(GENERATEDFILES) $(CFLAGS) $(LDFLAGS)
  >>
end match
case "gcc" then
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
  let extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then ""
  // Note: FMI 1.0 did not distinguish modelIdentifier from fileNamePrefix
  let modelName = if isFMIVersion20(FMUVersion) then dotPath(modelInfo.name) else fileNamePrefix
  let platformstr = match makefileParams.platform case "i386-pc-linux" then 'linux32' case "x86_64-linux" then 'linux64' else '<%makefileParams.platform%>'
  let mkdir = match makefileParams.platform case "win32" then '"mkdir.exe"' else 'mkdir'
  <<
  # Makefile generated by OpenModelica
  OMHOME=<%makefileParams.omhome%>
  include $(OMHOME)/include/omc/cpp/ModelicaConfig.inc
  # Simulations use -O0 by default
  SIM_OR_DYNLOAD_OPT_LEVEL=-O0
  CC=<%makefileParams.ccompiler%>
  CXX=<%makefileParams.cxxcompiler%>
  LINK=<%makefileParams.linker%>
  EXEEXT=<%makefileParams.exeext%>
  DLLEXT=<%makefileParams.dllext%>
  CFLAGS_BASED_ON_INIT_FILE=<%extraCflags%>

  CFLAGS=$(CFLAGS_BASED_ON_INIT_FILE) -Winvalid-pch $(SYSTEM_CFLAGS) -I"$(OMHOME)/include/omc/cpp" -I"$(UMFPACK_INCLUDE)" -I"$(OMHOME)/include/omc/cpp/Core" -I"$(OMHOME)/include/omc/cpp/SimCoreFactory" -I"$(BOOST_INCLUDE)" <%makefileParams.includes ; separator=" "%>
  CPPFLAGS = $(CFLAGS)
  LDFLAGS=-L"$(OMHOME)/lib/omc/cpp" -L"$(BOOST_LIBS)"
  PLATFORM="<%platformstr%>"

  CALCHELPERMAINFILE=OMCpp<%fileNamePrefix%>CalcHelperMain.cpp
  CALCHELPERMAINFILE2=OMCpp<%fileNamePrefix%>CalcHelperMain2.cpp
  CALCHELPERMAINFILE3=OMCpp<%fileNamePrefix%>CalcHelperMain3.cpp
  #skip CALCHELPERMAINFILE4 with WriteOutput
  CALCHELPERMAINFILE5=OMCpp<%fileNamePrefix%>CalcHelperMain5.cpp
  ALGLOOPSMAINFILE=OMCpp<%fileNamePrefix%>AlgLoopMain.cpp

  OMCPP_LIBS= -lOMCppSystem_FMU -lOMCppDataExchange_static -lOMCppOMCFactory -lOMCppMath_static
  OMCPP_SOLVER_LIBS= -Wl,-rpath,$(OMHOME)/lib/omc/cpp
  BOOST_LIBRARIES = -lboost_system -lboost_filesystem -lboost_program_options
  LIBS= $(OMCPP_LIBS) $(OMCPP_SOLVER_LIBS) $(BASE_LIB) $(BOOST_LIBRARIES) $(LINUX_LIB_DL)

  CPPFILES=OMCpp<%fileNamePrefix%>.cpp OMCpp<%fileNamePrefix%>FMU.cpp $(CALCHELPERMAINFILE) $(CALCHELPERMAINFILE2) $(CALCHELPERMAINFILE3) $(CALCHELPERMAINFILE5) $(ALGLOOPSMAINFILE)
  OFILES=$(CPPFILES:.cpp=.o)

  .PHONY: <%modelName%>.fmu $(CPPFILES) clean

  <%modelName%>.fmu: $(OFILES)
  <%\t%>$(CXX) -shared -I. -o <%fileNamePrefix%>$(DLLEXT) $(OFILES) $(CFLAGS) $(LDFLAGS) $(LIBS)
  <%\t%>rm -rf binaries
  <%\t%><%mkdir%> -p "binaries/$(PLATFORM)"
  <%\t%>cp <%fileNamePrefix%>$(DLLEXT) "binaries/$(PLATFORM)/"
  <%\t%>rm -f <%modelName%>.fmu
  <%\t%>zip -r "<%modelName%>.fmu" modelDescription.xml binaries binaries/$(PLATFORM) binaries/$(PLATFORM)/<%modelName%>$(DLLEXT)
  <%\t%>rm -rf binaries

  clean:
  <%\t%>rm $(SRC) <%fileNamePrefix%>$(DLLEXT)

  >>
end fmuMakefile;

annotation(__OpenModelica_Interface="backend");
end CodegenFMUCpp;

// vim: filetype=susan sw=2 sts=2
