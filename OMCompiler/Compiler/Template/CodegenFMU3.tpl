/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

// This file defines templates for generating the modelDescription.xml file for
// the FMI 3.0 (released, "3.0") export of OpenModelica.
//
// The most important differences from FMI 2.0 (CodegenFMU2.tpl) are:
//
//   - the root attribute is `instantiationToken` instead of `guid`;
//   - the FMU may declare ModelExchange, CoSimulation and ScheduledExecution;
//   - ModelVariables contains typed variable elements (<Float64>, <Int32>,
//     <Boolean>, <String>, <Enumeration>, ...) instead of <ScalarVariable> with
//     a nested type element;
//   - the independent variable (time) must be declared explicitly with
//     causality="independent";
//   - value references must be globally unique (in FMI 2.0 they only had to be
//     unique per base type); we achieve this with the per-base-type offset
//     scheme implemented in SimCodeUtil.getFMI3ValueReference;
//   - ModelStructure references unknowns by valueReference (Output,
//     ContinuousStateDerivative, InitialUnknown, EventIndicator) instead of by
//     a 1-based index.

package CodegenFMU3

import interface SimCodeTV;
import interface SimCodeBackendTV;
import CodegenUtil.*;
import CodegenUtilSimulation.*;
import CodegenC.*; //unqualified import, no need the CodegenC is optional when calling a template; or mandatory when the same named template exists in this package (name hiding)
import CodegenFMUCommon.*;

// Code for generating modelDescription.xml file for FMI 3.0.
template fmiModelDescription(SimCode simCode, String guid, String FMUType, list<String> sourceFiles)
 "Generates code for ModelDescription file for FMI 3.0 FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <fmiModelDescription
    <%fmiModelDescriptionAttributes(simCode,guid)%>>
    <%if isFMIMEType(FMUType) then ModelExchange3(simCode, sourceFiles)%>
    <%if isFMICSType(FMUType) then CoSimulation3(simCode, sourceFiles)%>
    <%if isFMISEType(FMUType) then ScheduledExecution3(simCode, sourceFiles)%>
    <%UnitDefinitions(simCode)%>
    <%TypeDefinitions3(simCode)%>
    <% if Flags.isSet(Flags.FMU_EXPERIMENTAL) then
    <<
    <LogCategories>
      <Category name="logEvents" description="logEvents" />
      <Category name="logSingularLinearSystems" description="logSingularLinearSystems" />
      <Category name="logNonlinearSystems" description="logNonlinearSystems" />
      <Category name="logDynamicStateSelection" description="logDynamicStateSelection" />
      <Category name="logStatusWarning" description="logStatusWarning" />
      <Category name="logStatusDiscard" description="logStatusDiscard" />
      <Category name="logStatusError" description="logStatusError" />
      <Category name="logStatusFatal" description="logStatusFatal" />
      <Category name="logStatusPending" description="logStatusPending" />
      <Category name="logAll" description="logAll" />
      <Category name="logFmi3Call" description="logFmi3Call" />
    </LogCategories>
    >> else
    <<
    <LogCategories>
      <Category name="logEvents" />
      <Category name="logSingularLinearSystems" />
      <Category name="logNonlinearSystems" />
      <Category name="logDynamicStateSelection" />
      <Category name="logStatusWarning" />
      <Category name="logStatusDiscard" />
      <Category name="logStatusError" />
      <Category name="logStatusFatal" />
      <Category name="logStatusPending" />
      <Category name="logAll" />
      <Category name="logFmi3Call" />
    </LogCategories>
    >> %>
    <%DefaultExperiment3(simulationSettingsOpt)%>
    <%fmiModelVariables3(simCode, FMUType)%>
    <%modelStructure3(simCode, modelStructure)%>
  </fmiModelDescription>
  >>
end fmiModelDescription;

template fmiBuildDescriptionFile(SimCode simCode, list<String> sourceFiles, String fileNamePrefixHash)
 "Writes sources/buildDescription.xml (FMI 3.0). Returns the empty string (the
  content is written to a file). Skipped when there are no source files
  (--fmiFilter=blackBox or fmiSources=false)."
::=
match sourceFiles
case {} then ''
else
  let()= textFile(fmiBuildDescription(simCode, sourceFiles), '<%fileNamePrefixHash%>.fmutmp/sources/buildDescription.xml')
  ''
end fmiBuildDescriptionFile;

template fmiBuildDescription(SimCode simCode, list<String> sourceFiles)
 "Generates the FMI 3.0 sources/buildDescription.xml: the C source files, include
  directories and preprocessor definitions needed to build the source FMU. In FMI
  2.0 the source file list lived in modelDescription.xml (<SourceFiles>); FMI 3.0
  moves it here. Paths are relative to the sources/ directory."
::=
match simCode
case SIMCODE(__) then
  let modelIdentifier = modelNamePrefix(simCode)
  <<
  <?xml version="1.0" encoding="UTF-8"?>
  <fmiBuildDescription fmiVersion="3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://raw.githubusercontent.com/modelica/fmi-standard/v3.0.2/schema/fmi3BuildDescription.xsd">
    <BuildConfiguration modelIdentifier="<%modelIdentifier%>">
      <SourceFileSet language="C17">
        <%sourceFiles |> file => '<SourceFile name="<%file%>"/>' ;separator="\n"%>
        <PreprocessorDefinition name="FMI2_OVERRIDE_FUNCTION_PREFIX"/>
        <PreprocessorDefinition name="FMI3_OVERRIDE_FUNCTION_PREFIX"/>
        <IncludeDirectory name="."/>
        <IncludeDirectory name="fmi"/>
      </SourceFileSet>
    </BuildConfiguration>
  </fmiBuildDescription>
  >>
end fmiBuildDescription;

template fmiTerminalsAndIconsFile(SimCode simCode, String fileNamePrefixHash)
 "Writes terminalsAndIcons/terminalsAndIcons.xml into the FMU when the model has
  connector-derived terminals. Returns the empty string (the content is written to
  a file). The terminalsAndIcons/ directory is created in SimCodeMain beforehand."
::=
match SimCodeUtil.getFMI3Terminals(simCode)
case {} then ''
case terminals then
  let()= textFile(fmiTerminalsAndIcons(terminals), '<%fileNamePrefixHash%>.fmutmp/terminalsAndIcons/terminalsAndIcons.xml')
  ''
end fmiTerminalsAndIconsFile;

template fmiTerminalsAndIcons(list<FmiTerminal> terminals)
 "Generates the terminalsAndIcons.xml content (FMI 3.0 Terminals): one <Terminal>
  per connector instance, grouping its member variables. The connector membership
  is detected from the flat-model component type (a connector-typed cref qualifier)
  in SimCodeUtil.getFMI3Terminals."
::=
  <<
  <?xml version="1.0" encoding="UTF-8"?>
  <fmiTerminalsAndIcons fmiVersion="3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://raw.githubusercontent.com/modelica/fmi-standard/v3.0.2/schema/fmi3TerminalsAndIcons.xsd">
    <Terminals>
      <%terminals |> t => Terminal3(t) ;separator="\n"%>
    </Terminals>
  </fmiTerminalsAndIcons>
  >>
end fmiTerminalsAndIcons;

template Terminal3(FmiTerminal terminal)
 "Generates one <Terminal>. Members are matched by name (memberName) when two
  terminals are connected: matchingRule=\"plug\" for an ordinary, fully-defined
  Modelica connector (all members must match), \"bus\" for an expandable connector
  (partial matching allowed). terminalKind, when known, carries the connector type
  path so importers can check type compatibility."
::=
match terminal
case FMI_TERMINAL(__) then
  let rule = if isExpandable then "bus" else "plug"
  let kindAttr = if stringEq(terminalKind, "") then "" else ' terminalKind="<%Util.escapeModelicaStringToXmlString(terminalKind)%>"'
  <<
  <Terminal name="<%Util.escapeModelicaStringToXmlString(name)%>" matchingRule="<%rule%>"<%kindAttr%>>
    <%members |> m => TerminalMember3(m) ;separator="\n"%>
  </Terminal>
  >>
end Terminal3;

template TerminalMember3(FmiTerminalMember member)
 "Generates a <TerminalMemberVariable> referencing a modelDescription variable.
  variableName is formatted exactly like the variable name in modelDescription.xml."
::=
match member
case FMI_TERMINAL_MEMBER(__) then
  let varName = Util.escapeModelicaStringToXmlString(System.stringReplace(crefStrNoUnderscore(variable),"$", "_D_"))
  '<TerminalMemberVariable variableName="<%varName%>" memberName="<%Util.escapeModelicaStringToXmlString(memberName)%>" variableKind="<%variableKind%>"/>'
end TerminalMember3;

template fmiModelDescriptionAttributes(SimCode simCode, String guid)
 "Generates the attributes of the fmiModelDescription element for FMI 3.0."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__), vars = SIMVARS(stateVars = listStates))) then
  let fmiVersion = '3.0'
  let modelName = dotPath(modelInfo.name)
  let description = modelInfo.description
  let author = modelInfo.author
  let version = modelInfo.version
  let copyright = modelInfo.copyright
  let license = modelInfo.license
  let generationTool= 'OpenModelica Compiler <%getVersionNr()%>'
  let generationDateAndTime = xsdateTime(getCurrentDateTime())
  let variableNamingConvention = 'structured'
  let numberOfEventIndicators = getNumberOfEventIndicators(simCode)
  <<
  fmiVersion="<%fmiVersion%>"
  modelName="<%Util.escapeModelicaStringToXmlString(modelName)%>"
  instantiationToken="{<%guid%>}"
  description="<%Util.escapeModelicaStringToXmlString(description)%>"
  version="<%Util.escapeModelicaStringToXmlString(version)%>"
  <% if stringEq(author, "") then '' else 'author="<%Util.escapeModelicaStringToXmlString(author)%>"'%>
  <% if stringEq(copyright, "") then '' else 'copyright="<%Util.escapeModelicaStringToXmlString(copyright)%>"'%>
  <% if stringEq(license, "") then '' else 'license="<%Util.escapeModelicaStringToXmlString(license)%>"'%>
  generationTool="<%Util.escapeModelicaStringToXmlString(generationTool)%>"
  generationDateAndTime="<%Util.escapeModelicaStringToXmlString(generationDateAndTime)%>"
  variableNamingConvention="<%variableNamingConvention%>"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:noNamespaceSchemaLocation="https://raw.githubusercontent.com/modelica/fmi-standard/main/schema/fmi3ModelDescription.xsd"
  >>
end fmiModelDescriptionAttributes;

template ModelExchange3(SimCode simCode, list<String> sourceFiles)
 "Generates the ModelExchange element for FMI 3.0."
::=
match simCode
case SIMCODE(__) then
  let modelIdentifier = modelNamePrefix(simCode)
  <<
  <ModelExchange
    modelIdentifier="<%modelIdentifier%>"
    needsExecutionTool="false"
    canBeInstantiatedOnlyOncePerProcess="false"
    canGetAndSetFMUState="true"
    canSerializeFMUState="true"
    <% if providesDirectionalDerivative(simCode) then 'providesDirectionalDerivatives="true"' else 'providesDirectionalDerivatives="false"'%>
    providesAdjointDerivatives="false"
    providesPerElementDependencies="false"
    needsCompletedIntegratorStep="true"/>
  >>
end ModelExchange3;

template CoSimulation3(SimCode simCode, list<String> sourceFiles)
 "Generates the CoSimulation element for FMI 3.0."
::=
match simCode
case SIMCODE(__) then
  let modelIdentifier = modelNamePrefix(simCode)
  <<
  <CoSimulation
    modelIdentifier="<%Util.escapeModelicaStringToXmlString(modelIdentifier)%>"
    needsExecutionTool="false"
    canHandleVariableCommunicationStepSize="true"
    canBeInstantiatedOnlyOncePerProcess="false"
    maxOutputDerivativeOrder="1"
    providesIntermediateUpdate="false"
    mightReturnEarlyFromDoStep="true"
    canReturnEarlyAfterIntermediateUpdate="false"
    hasEventMode="true"
    providesEvaluateDiscreteStates="false"
    recommendedIntermediateInputSmoothness="0"
    canGetAndSetFMUState="true"
    canSerializeFMUState="true"
    <% if providesDirectionalDerivative(simCode) then 'providesDirectionalDerivatives="true"' else 'providesDirectionalDerivatives="false"'%>
    providesAdjointDerivatives="false"
    providesPerElementDependencies="false"/>
  >>
end CoSimulation3;

template ScheduledExecution3(SimCode simCode, list<String> sourceFiles)
 "Generates the ScheduledExecution element for FMI 3.0."
::=
match simCode
case SIMCODE(__) then
  let modelIdentifier = modelNamePrefix(simCode)
  <<
  <ScheduledExecution
    modelIdentifier="<%Util.escapeModelicaStringToXmlString(modelIdentifier)%>"
    needsExecutionTool="false"
    canBeInstantiatedOnlyOncePerProcess="false"
    canGetAndSetFMUState="true"
    canSerializeFMUState="true"
    <% if providesDirectionalDerivative(simCode) then 'providesDirectionalDerivatives="true"' else 'providesDirectionalDerivatives="false"'%>
    providesAdjointDerivatives="false"
    providesPerElementDependencies="false"/>
  >>
end ScheduledExecution3;

template DefaultExperiment3(Option<SimulationSettings> simulationSettingsOpt)
 "Generates the DefaultExperiment element for FMI 3.0."
::=
match simulationSettingsOpt
  case SOME(SIMULATION_SETTINGS(startTime=startTime, stopTime=stopTime, tolerance=tolerance, stepSize=stepSize)) then
    <<
    <DefaultExperiment startTime="<%startTime%>" stopTime="<%stopTime%>" tolerance="<%tolerance%>" stepSize="<%stepSize%>"/>
    >>
end DefaultExperiment3;

template TypeDefinitions3(SimCode simCode)
 "Generates TypeDefinitions for FMI 3.0 (enumeration declared types)."
::=
match simCode
case SIMCODE(modelInfo=modelInfo) then
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  let types = (SimCodeUtil.getEnumerationTypes(vars) |> var => TypeDefinition3(var) ;separator="\n")
  if boolNot(stringEq(types, "")) then
  <<
  <TypeDefinitions>
    <%types%>
  </TypeDefinitions>
  >>
end TypeDefinitions3;

template TypeDefinition3(SimVar simVar)
::=
match simVar
case SIMVAR(type_ = T_ENUMERATION(path=path, names=names)) then
  <<
  <EnumerationType name="<%AbsynUtil.pathString(path, ".", false)%>" quantity="<%AbsynUtil.pathString(path, ".", false)%>">
    <%names |> name hasindex i0 fromindex 1 => '<Item name="<%name%>" value="<%i0%>"/>' ;separator="\n"%>
  </EnumerationType>
  >>
end TypeDefinition3;

template fmiModelVariables3(SimCode simCode, String FMUType)
 "Generates the ModelVariables element for FMI 3.0. FMUType selects the clock
  causality: Scheduled Execution clocks are input clocks (the importer activates
  the model partition), all others are output clocks."
::=
match simCode
case SIMCODE(modelInfo=modelInfo) then
match modelInfo
case MODELINFO(vars=SIMVARS(stateVars=stateVars)) then
  <<
  <ModelVariables>
    <%TimeVariable3(simCode)%>
    <%vars.stateVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%vars.derivativeVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%vars.algVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%vars.discreteAlgVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%vars.paramVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%vars.aliasVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%vars.intAlgVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%vars.intParamVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%vars.intAliasVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%vars.boolAlgVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%vars.boolParamVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%vars.boolAliasVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%vars.stringAlgVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%vars.stringParamVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%vars.stringAliasVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%vars.extObjVars |> var => Variable3(var, simCode, stateVars) ;separator="\n"%>
    <%SimCodeUtil.getFMI3Clocks(simCode) |> clk => Clock3(clk, FMUType) ;separator="\n"%>
    <%EventIndicatorVariables3(simCode)%>
  </ModelVariables>
  >>
end fmiModelVariables3;

template EventIndicatorVariables3(SimCode simCode)
 "FMI 3.0 requires event indicators to be exposed as Float64 variables that are
  then referenced by valueReference from the ModelStructure EventIndicator list.
  OpenModelica does not expose event indicators as named Modelica variables, so
  we declare synthetic local Float64 variables for them. Their value references
  form a contiguous block starting right after the time value reference
  (FMI3_EVENT_INDICATOR_VR_START in the generated runtime), and the runtime
  returns their values from the event indicators array in fmi3GetFloat64."
::=
  let n = getNumberOfEventIndicators(simCode)
  let timeVR = SimCodeUtil.getFMI3TimeValueReference(simCode)
  if intGt(stringInt(n), 0) then
  (List.intRange(stringInt(n)) |> i =>
    '<Float64 name="__zc_<%intSub(i,1)%>" valueReference="<%intAdd(stringInt(timeVR), i)%>" causality="local" variability="continuous" initial="calculated" description="event indicator <%intSub(i,1)%>"/>' ;separator="\n")
end EventIndicatorVariables3;

template TimeVariable3(SimCode simCode)
 "Generates the mandatory independent variable (time) for FMI 3.0."
::=
  <<
  <Float64 name="time" valueReference="<%SimCodeUtil.getFMI3TimeValueReference(simCode)%>" causality="independent" variability="continuous" description="Simulation time"/>
  >>
end TimeVariable3;

template Variable3(SimVar simVar, SimCode simCode, list<SimVar> stateVars)
 "Generates a typed variable element for FMI 3.0."
::=
match simVar
case SIMVAR(name = name, type_ = T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(__))) then
  // FMI 3.0 Binary variable: a Modelica ExternalObject is an opaque handle
  // (void*); it is exported as a Binary whose value is the raw handle bytes (see
  // fmi3GetBinary/fmi3SetBinary in fmu3_model_interface.c).
  '<Binary <%BinaryVariableAttributes3(simVar, simCode)%>/>'
case SIMVAR(name = name, exportVar = exportVar, type_ = T_ARRAY(ty = arrayElementType)) then
  // FMI 3.0 native array variable: one element with one valueReference and
  // <Dimension> children (the value reference of the first scalar element; the
  // array occupies a contiguous block of scalar value references).
  if boolNot(isSome(exportVar)) then ''
  else
  match arrayElementType
    case T_REAL(__) then
      '<Float64 <%VariableCommonAttributes3(simVar, simCode)%><%DerivativeAttribute3(simVar, simCode, stateVars)%><%ArrayStartString3(simVar)%>><%Dimensions3(simVar)%></Float64>'
    case T_INTEGER(__) then
      '<Int32 <%VariableCommonAttributes3(simVar, simCode)%><%ArrayStartString3(simVar)%>><%Dimensions3(simVar)%></Int32>'
    case T_BOOL(__) then
      '<Boolean <%VariableCommonAttributes3(simVar, simCode)%><%ArrayStartString3(simVar)%>><%Dimensions3(simVar)%></Boolean>'
    case T_STRING(__) then
      '<String <%VariableCommonAttributes3(simVar, simCode)%>><%Dimensions3(simVar)%></String>'
    case T_ENUMERATION(path = path) then
      '<Enumeration <%VariableCommonAttributes3(simVar, simCode)%>declaredType="<%AbsynUtil.pathString(path, ".", false)%>"<%ArrayStartString3(simVar)%>><%Dimensions3(simVar)%></Enumeration>'
    else '<!-- UNKNOWN_ARRAY_TYPE <%crefStr(name)%> -->'
case SIMVAR(__) then
  if SimCodeUtil.isFMI3NestableAlias(simVar) then
  // emitted as an <Alias> child of its canonical variable (shares its
  // valueReference), not as a separate ModelVariables entry
  ''
  else if stringEq(crefStr(name),"$dummy") then
  <<>>
  else if stringEq(crefStr(name),"der($dummy)") then
  <<>>
  else if boolNot(isSome(exportVar)) then
  ''
  else
  match type_
    case T_REAL(__) then
      '<Float64 <%VariableCommonAttributes3(simVar, simCode)%><%DerivativeAttribute3(simVar, simCode, stateVars)%><%ScalarStartString3(simVar)%><%MinString2(simVar)%><%MaxString2(simVar)%><%NominalString2(simVar)%><%UnitString2(simVar)%><%relativeQuantity(simVar)%><%CloseWithAliases3("Float64", simVar, simCode)%>'
    case T_INTEGER(__) then
      '<Int32 <%VariableCommonAttributes3(simVar, simCode)%><%ScalarStartString3(simVar)%><%MinString2(simVar)%><%MaxString2(simVar)%><%CloseWithAliases3("Int32", simVar, simCode)%>'
    case T_BOOL(__) then
      '<Boolean <%VariableCommonAttributes3(simVar, simCode)%><%ScalarStartString3(simVar)%><%CloseWithAliases3("Boolean", simVar, simCode)%>'
    case T_STRING(__) then
      '<String <%VariableCommonAttributes3(simVar, simCode)%>><%StringStartChild3(simVar)%><%AliasElements3(simVar, simCode)%></String>'
    case T_ENUMERATION(path=path) then
      '<Enumeration <%VariableCommonAttributes3(simVar, simCode)%>declaredType="<%AbsynUtil.pathString(path, ".", false)%>"<%ScalarStartString3(simVar)%><%MinString2(simVar)%><%MaxString2(simVar)%><%CloseWithAliases3("Enumeration", simVar, simCode)%>'
    else '<!-- UNKNOWN_TYPE <%crefStr(name)%> -->'
end Variable3;

template CloseWithAliases3(String tag, SimVar simVar, SimCode simCode)
 "Close a typed FMI 3.0 variable element: self-closing when it has no FMI 3.0
  <Alias> members, otherwise an open/close pair wrapping the <Alias> children."
::=
  let kids = AliasElements3(simVar, simCode)
  if stringEq(kids, "") then '/>'
  else '><%\n%><%kids%><%\n%>  </<%tag%>>'
end CloseWithAliases3;

template AliasElements3(SimVar simVar, SimCode simCode)
 "Emit the FMI 3.0 <Alias> child elements of a canonical variable: one per
  positive local alias that shares this variable's valueReference."
::=
match simVar
case SIMVAR(__) then
  match SimCodeUtil.getFMI3VariableAliases(simCode, name)
  case {} then ''
  case aliases then (aliases |> a => AliasElement3(a) ;separator="\n")
end AliasElements3;

template AliasElement3(SimVar aliasVar)
 "One FMI 3.0 <Alias> element. The name is formatted exactly like a variable name
  in modelDescription.xml; the alias shares the parent variable's valueReference."
::=
match aliasVar
case SIMVAR(__) then
  let nm = Util.escapeModelicaStringToXmlString(System.stringReplace(crefStrNoUnderscore(Util.getOption(exportVar)),"$", "_D_"))
  let desc = if comment then ' description="<%Util.escapeModelicaStringToXmlString(comment)%>"'
  '    <Alias name="<%nm%>"<%desc%>/>'
end AliasElement3;

template Clock3(FmiClock clock, String FMUType)
 "Generates an FMI 3.0 <Clock> variable for a model clock. For Scheduled
  Execution the clock is an input clock (the importer activates the associated
  model partition via fmi3ActivateModelPartition); otherwise it is an output
  clock the FMU activates. intervalVariability is required; the period
  (intervalDecimal) or the counter/resolution fraction is emitted when known."
::=
match clock
case FMI_CLOCK(__) then
  let causality = if isFMISEType(FMUType) then "input" else "output"
  let nm = Util.escapeModelicaStringToXmlString(System.stringReplace(name,"$", "_D_"))
  let intervalDec = if boolNot(stringEq(intervalDecimal, "")) then ' intervalDecimal="<%intervalDecimal%>"'
  let fraction = if supportsFraction then ' supportsFraction="true"'
  let counter = if boolNot(stringEq(intervalCounter, "")) then ' intervalCounter="<%intervalCounter%>"'
  let res = if boolNot(stringEq(resolution, "")) then ' resolution="<%resolution%>"'
  '<Clock name="<%nm%>" valueReference="<%valueReference%>" causality="<%causality%>" intervalVariability="<%intervalVariability%>"<%intervalDec%><%fraction%><%counter%><%res%>/>'
end Clock3;

template ScalarStartString3(SimVar simVar)
 "Generates the start attribute for an FMI 3.0 scalar variable. Like the shared
  StartString2 but additionally emits the start for continuous-time states: a
  state is initial = exact (fixed start) or approx (unfixed start) and both
  require a start, but the new backend leaves initial_ unset for states (it uses
  the fixed attribute instead). FMI 3.0 specific so the FMI 2.0 output (which
  uses StartString2) is unchanged. Mirrors ArrayStartString3 for array states."
::=
match simVar
case SIMVAR(aliasvar = SimCodeVar.ALIAS(__)) then ''
case SIMVAR(initialValue = NONE()) then ''
case SIMVAR(varKind = STATE(__)) then startString3(simVar)
case SIMVAR(causality = SOME(SimCodeVar.INPUT())) then startString3(simVar)
case SIMVAR(initial_ = SOME(SimCodeVar.EXACT())) then startString3(simVar)
case SIMVAR(initial_ = SOME(SimCodeVar.APPROX())) then startString3(simVar)
else ''
end ScalarStartString3;

template ArrayStartString3(SimVar simVar)
 "Generates the start attribute (a space separated list of the scalar element
  start values) for an FMI 3.0 array variable. Emitted only where a scalar would
  emit a start (exact/approx initial or input), to keep the schema consistent."
::=
match simVar
case SIMVAR(aliasvar = SimCodeVar.ALIAS(__)) then ''
case SIMVAR(varKind = STATE(__)) then arrayStartAttr(simVar)
case SIMVAR(initial_ = SOME(SimCodeVar.EXACT())) then arrayStartAttr(simVar)
case SIMVAR(initial_ = SOME(SimCodeVar.APPROX())) then arrayStartAttr(simVar)
case SIMVAR(causality = SOME(SimCodeVar.INPUT())) then arrayStartAttr(simVar)
else ''
end ArrayStartString3;

template arrayStartAttr(SimVar simVar)
::=
  let s = SimCodeUtil.getFMI3ArrayStart(simVar)
  if stringEq(s, "") then '' else ' start="<%s%>"'
end arrayStartAttr;

template Dimensions3(SimVar simVar)
 "Generates the <Dimension start='N'/> children of an FMI 3.0 array variable
  from the variable's dimension sizes (row major)."
::=
match simVar
case SIMVAR(numArrayElement = dims) then
  (dims |> d => '<Dimension start="<%d%>"/>' ;separator="")
end Dimensions3;

template FmiInitialAttribute3(SimVar simVar)
 "Generates the FMI 3.0 initial attribute. Continuous-time states are special:
  the non-scalarized array backend does not populate their initial_ field, so we
  derive it from the variable's fixed attribute here. A fixed start is an exact
  initial value (initial=\"exact\"), an unfixed start is a guess (initial=\"approx\").
  All other variables fall back to the generic SimCode-derived attribute."
::=
match simVar
case SIMVAR(varKind = STATE(__), isFixed = true) then "exact"
case SIMVAR(varKind = STATE(__)) then "approx"
else getFmiInitialAttributeStr(simVar)
end FmiInitialAttribute3;

template VariableCommonAttributes3(SimVar simVar, SimCode simCode)
 "Generates the common attributes (name, valueReference, description, causality,
  variability, initial) shared by all FMI 3.0 typed variable elements. Note the
  trailing space so type-specific attributes can be appended directly."
::=
match simVar
case SIMVAR(__) then
  let name = Util.escapeModelicaStringToXmlString(System.stringReplace(crefStrNoUnderscore(Util.getOption(exportVar)),"$", "_D_"))
  let valueReference = SimCodeUtil.getFMI3ValueReference(simVar, simCode)
  let description = if comment then 'description="<%Util.escapeModelicaStringToXmlString(comment)%>" '
  let variability_ = getVariability2(variability)
  let caus = getCausality2(causality)
  let initial = FmiInitialAttribute3(simVar)
  <<
  name="<%name%>" valueReference="<%valueReference%>" <%description%><%if boolNot(stringEq(caus, "")) then 'causality="'+caus+'" '%><%if boolNot(stringEq(variability_, "")) then 'variability="'+variability_+'" '%><%if boolNot(stringEq(initial, "")) then 'initial="'+initial+'" '%>
  >>
end VariableCommonAttributes3;

template BinaryVariableAttributes3(SimVar simVar, SimCode simCode)
 "Generates the attributes for an FMI 3.0 Binary variable (a Modelica
  ExternalObject). External objects have no exportVar/start; the name is taken
  directly from the SimVar cref. They are constructed during initialization and
  constant afterwards, hence variability=\"fixed\", causality=\"local\"."
::=
match simVar
case SIMVAR(__) then
  let nm = Util.escapeModelicaStringToXmlString(System.stringReplace(crefStrNoUnderscore(name),"$", "_D_"))
  let valueReference = SimCodeUtil.getFMI3ValueReference(simVar, simCode)
  let description = if comment then 'description="<%Util.escapeModelicaStringToXmlString(comment)%>" '
  <<
  name="<%nm%>" valueReference="<%valueReference%>" <%description%>causality="local" variability="fixed"
  >>
end BinaryVariableAttributes3;

template DerivativeAttribute3(SimVar simVar, SimCode simCode, list<SimVar> stateVars)
 "Generates the derivative attribute (FMI 3.0 references the *valueReference* of
  the state variable). For the C runtime the state value references precede the
  state derivative value references contiguously in the real block, hence the
  state value reference is the derivative value reference minus the number of
  states."
::=
match simVar
case SIMVAR(varKind = STATE_DER(__)) then
  match simCode
  case SIMCODE(modelInfo = MODELINFO(vars = SIMVARS(stateVars = stateVarsList))) then
    // per-scalar state count, so the derivative VR minus it yields the state VR
    // (works for non-scalarized array states too).
    ' derivative="<%intSub(stringInt(SimCodeUtil.getFMI3ValueReference(simVar, simCode)), SimCodeUtil.numScalarElems(stateVarsList))%>"'
  else ''
else ''
end DerivativeAttribute3;

template StringStartChild3(SimVar simVar)
 "Generates the nested <Start value=.../> element for an FMI 3.0 String variable."
::=
match simVar
case SIMVAR(aliasvar = SimCodeVar.ALIAS(__)) then ''
case SIMVAR(initialValue = SOME(e as SCONST(__))) then
  '<Start value="<%initValXml(e, "")%>"/>'
case SIMVAR(causality = SOME(SimCodeVar.INPUT())) then
  '<Start value=""/>'
else ''
end StringStartChild3;

template modelStructure3(SimCode simCode, Option<FmiModelStructure> fmiModelStructure)
 "Generates the FMI 3.0 ModelStructure. Unknowns are referenced by valueReference."
::=
match fmiModelStructure
case SOME(fmistruct as FMIMODELSTRUCTURE(__)) then
  <<
  <ModelStructure>
    <%ModelStructureOutputs3(simCode, fmistruct.fmiOutputs)%>
    <%ModelStructureDerivatives3(simCode, fmistruct.fmiDerivatives)%>
    <%ModelStructureInitialUnknowns3(simCode, fmistruct.fmiInitialUnknowns)%>
    <%EventIndicators3(simCode)%>
  </ModelStructure>
  >>
else
  <<
  <ModelStructure>
    <%EventIndicators3(simCode)%>
  </ModelStructure>
  >>
end modelStructure3;

template ModelStructureOutputs3(SimCode simCode, FmiOutputs fmiOutputs)
::=
match fmiOutputs
case FMIOUTPUTS(fmiUnknownsList={}) then ""
case FMIOUTPUTS(__) then
  (fmiUnknownsList |> u => FmiUnknown3(simCode, u, "Output") ;separator="\n")
end ModelStructureOutputs3;

template ModelStructureDerivatives3(SimCode simCode, FmiDerivatives fmiDerivatives)
::=
match fmiDerivatives
case FMIDERIVATIVES(fmiUnknownsList={}) then ""
case FMIDERIVATIVES(__) then
  (fmiUnknownsList |> u => FmiUnknown3(simCode, u, "ContinuousStateDerivative") ;separator="\n")
end ModelStructureDerivatives3;

template ModelStructureInitialUnknowns3(SimCode simCode, FmiInitialUnknowns fmiInitialUnknowns)
::=
match fmiInitialUnknowns
case FMIINITIALUNKNOWNS(fmiUnknownsList={}) then ""
case FMIINITIALUNKNOWNS(__) then
  (fmiUnknownsList |> u => FmiUnknown3(simCode, u, "InitialUnknown") ;separator="\n")
end ModelStructureInitialUnknowns3;

template FmiUnknown3(SimCode simCode, FmiUnknown fmiUnknown, String element)
 "Generates a single FMI 3.0 ModelStructure entry, mapping the stored FMI index
  to its value reference. Dependencies (also stored as indices) are mapped to
  the value references of the corresponding knowns."
::=
match fmiUnknown
case FMIUNKNOWN(__) then
  let vr = SimCodeUtil.getFMI3ValueReferenceFromFMIIndex(simCode, index)
  let deps = (dependencies |> d => SimCodeUtil.getFMI3ValueReferenceFromFMIIndex(simCode, d) ;separator=" ")
  let depsAttr = if dependencies then ' dependencies="<%deps%>"'
  let depsKindAttr = if dependenciesKind then ' dependenciesKind="<%dependenciesKind |> k => k ;separator=" "%>"'
  <<
  <<%element%> valueReference="<%vr%>"<%depsAttr%><%depsKindAttr%>/>
  >>
end FmiUnknown3;

template EventIndicators3(SimCode simCode)
 "Generates the EventIndicator entries for FMI 3.0. The event indicators have
  their own value reference range starting at FMI3_EVENT_INDICATOR_VR_START in
  the generated runtime; here we only need them to be unique within the FMU."
::=
  let n = getNumberOfEventIndicators(simCode)
  let timeVR = SimCodeUtil.getFMI3TimeValueReference(simCode)
  if intGt(stringInt(n), 0) then
  (List.intRange(stringInt(n)) |> i =>
    '<EventIndicator valueReference="<%intAdd(stringInt(timeVR), i)%>"/>' ;separator="\n")
end EventIndicators3;

annotation(__OpenModelica_Interface="codegen");
end CodegenFMU3;

// vim: filetype=susan sw=2 sts=2
