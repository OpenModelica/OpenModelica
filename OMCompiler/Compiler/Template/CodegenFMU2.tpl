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

package CodegenFMU2

import interface SimCodeTV;
import interface SimCodeBackendTV;
import CodegenUtil.*;
import CodegenUtilSimulation.*;
import CodegenC.*; //unqualified import, no need the CodegenC is optional when calling a template; or mandatory when the same named template exists in this package (name hiding)
import CodegenFMUCommon.*;

// Code for generating modelDescription.xml file for FMI 2.0 ModelExchange.
template fmiModelDescription(SimCode simCode, String guid, String FMUType, list<String> sourceFiles)
 "Generates code for ModelDescription file for FMU target."
::=
//  <%UnitDefinitions(simCode)%>
//  <%VendorAnnotations(simCode)%>
match simCode
case SIMCODE(__) then
  <<
  <fmiModelDescription
    <%fmiModelDescriptionAttributes(simCode,guid)%>>
    <%if isFMIMEType(FMUType) then ModelExchange(simCode, sourceFiles)%>
    <%if isFMICSType(FMUType) then CoSimulation(simCode, sourceFiles)%>
    <%fmiTypeDefinitions(simCode, "2.0")%>
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
      <Category name="logFmi2Call" description="logFmi2Call" />
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
      <Category name="logFmi2Call" />
    </LogCategories>
    >> %>
    <%DefaultExperiment(simulationSettingsOpt)%>
    <%fmiModelVariables(simCode, "2.0")%>
    <%ModelStructure(modelStructure)%>
  </fmiModelDescription>
  >>
end fmiModelDescription;

template fmiModelDescriptionAttributes(SimCode simCode, String guid)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__), vars = SIMVARS(stateVars = listStates))) then
  let fmiVersion = '2.0'
  let modelName = dotPath(modelInfo.name)
  let description = modelInfo.description
  let generationTool= 'OpenModelica Compiler <%getVersionNr()%>'
  let generationDateAndTime = xsdateTime(getCurrentDateTime())
  let variableNamingConvention = 'structured'
  let numberOfEventIndicators = getNumberOfEventIndicators(simCode)
  <<
  fmiVersion="<%fmiVersion%>"
  modelName="<%Util.escapeModelicaStringToXmlString(modelName)%>"
  guid="{<%guid%>}"
  description="<%Util.escapeModelicaStringToXmlString(description)%>"
  generationTool="<%Util.escapeModelicaStringToXmlString(generationTool)%>"
  generationDateAndTime="<%Util.escapeModelicaStringToXmlString(generationDateAndTime)%>"
  variableNamingConvention="<%variableNamingConvention%>"
  numberOfEventIndicators="<%numberOfEventIndicators%>"
  >>
end fmiModelDescriptionAttributes;

template CoSimulation(SimCode simCode, list<String> sourceFiles)
 "Generates CoSimulation code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  let modelIdentifier = modelNamePrefix(simCode)
  <<
  <CoSimulation
    modelIdentifier="<%Util.escapeModelicaStringToXmlString(modelIdentifier)%>"
    needsExecutionTool="false"
    canHandleVariableCommunicationStepSize="true"
    canInterpolateInputs="false"
    maxOutputDerivativeOrder="0"
    canRunAsynchronuously = "false"
    canBeInstantiatedOnlyOncePerProcess="false"
    canNotUseMemoryManagementFunctions="false"
    canGetAndSetFMUstate="false"
    canSerializeFMUstate="false"
    <% if Flags.isSet(FMU_EXPERIMENTAL) then 'providesDirectionalDerivative="true"'%>>
    <%SourceFiles(sourceFiles)%>
  </CoSimulation>
  >>
end CoSimulation;


annotation(__OpenModelica_Interface="backend");
end CodegenFMU2;

// vim: filetype=susan sw=2 sts=2
