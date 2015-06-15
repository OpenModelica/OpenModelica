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

package CodegenFMU1

import interface SimCodeTV;
import CodegenUtil.*;
import CodegenC.*; //unqualified import, no need the CodegenC is optional when calling a template; or mandatory when the same named template exists in this package (name hiding)
import CodegenFMUCommon.*;

// Code for generating modelDescription.xml file for FMI 1.0 ModelExchange.
template fmiModelDescription(SimCode simCode, String guid, String FMUType)
 "Generates code for ModelDescription file for FMU target."
::=
//  <%UnitDefinitions(simCode)%>
//  <%VendorAnnotations(simCode)%>
match simCode
case SIMCODE(__) then
  <<
  <fmiModelDescription
    <%fmiModelDescriptionAttributes(simCode,guid)%>>
    <%fmiTypeDefinitions(modelInfo, "1.0")%>
    <%DefaultExperiment(simulationSettingsOpt)%>
    <%fmiModelVariables(modelInfo, "1.0")%>
    <%if isFMICSType(FMUType) then Implementation()%>
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
  let modelIdentifier = modelNamePrefix(simCode)
  let description = modelInfo.description
  let generationTool= 'OpenModelica Compiler <%getVersionNr()%>'
  let generationDateAndTime = xsdateTime(getCurrentDateTime())
  let variableNamingConvention = 'structured'
  let numberOfContinuousStates = if intEq(vi.numStateVars,1) then statesnumwithDummy(listStates) else vi.numStateVars
  let numberOfEventIndicators = vi.numZeroCrossings
  <<
  fmiVersion="<%fmiVersion%>"
  modelName="<%modelName%>"
  modelIdentifier="<%modelIdentifier%>"
  guid="{<%guid%>}"
  description="<%description%>"
  generationTool="<%generationTool%>"
  generationDateAndTime="<%generationDateAndTime%>"
  variableNamingConvention="<%variableNamingConvention%>"
  numberOfContinuousStates="<%numberOfContinuousStates%>"
  numberOfEventIndicators="<%numberOfEventIndicators%>"
  >>
end fmiModelDescriptionAttributes;

annotation(__OpenModelica_Interface="backend");
end CodegenFMU1;

// vim: filetype=susan sw=2 sts=2
