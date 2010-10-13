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

spackage SimCodeFMU

typeview "SimCodeTV.mo"

template translateModel(SimCode simCode) 
 "Generates C code and Makefile for compiling a FMU of a
  Modelica model."
::=
match simCode
case SIMCODE(__) then
  let()= textFile(fmuModelDescriptionFile(simCode), 'modelDescription.xml')
  let()= textFile(fmumodel_identifierFile(simCode), '<%fileNamePrefix%>_FMU.cpp')
  let()= textFile(fmuMakefile(simCode), '<%fileNamePrefix%>_FMU.makefile')
  "" // Return empty result since result written to files directly
end translateModel;


template fmuModelDescriptionFile(SimCode simCode)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <?xml version="1.0" encoding="UTF8"?>
  <%fmiModelDescription(simCode)%>
  
  >>
end fmuModelDescriptionFile;

template fmiModelDescription(SimCode simCode)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <fmiModelDescription <%fmiModelDescriptionAttributes(simCode)%>>
  <%UnitDefinitions(simCode)%>
  <%TypeDefinitions(simCode)%>
  <%DefaultExperiment(simCode)%>
  <%VendorAnnotations(simCode)%>
  <%ModelVariables(modelInfo)%>  
  </fmiModelDescription>  
  >>
end fmiModelDescription;

template fmiModelDescriptionAttributes(SimCode simCode)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  let fmiVersion = '1.0' 
  let modelName = dotPath(modelInfo.name)
  let modelIdentifier = fileNamePrefix
  let guid = '0.0'
  let description = ''
  let author = ''
  let version= '' 
  let generationTool= 'OpenModelica Compiler <%getVersionNr()%>'
  let generationDateAndTime = ''
  let variableNamingConvention= 'structured'
  let numberOfContinuousStates = ''
  let numberOfEventIndicators = '' 
  << 
  fmiVersion="<%fmiVersion%>" modelName="<%modelName%>" modelIdentifier="<%modelIdentifier%>" guid="{<%guid%>}" description="<%description%>"
  author="<%author%>" version="<%version%>" 
  generationTool="<%generationTool%>" generationDateAndTime="<%generationDateAndTime%>"
  variableNamingConvention="<%variableNamingConvention%>" numberOfContinuousStates="<%numberOfContinuousStates%>" numberOfEventIndicators="<%numberOfEventIndicators%>" 
  >>
end fmiModelDescriptionAttributes;

template dotPath(Path path)
 "Generates paths with components separated by dots."
::=
  match path
  case QUALIFIED(__)      then '<%name%>.<%dotPath(path)%>'

  case IDENT(__)          then name
  case FULLYQUALIFIED(__) then dotPath(path)
end dotPath;

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

template DefaultExperiment(SimCode simCode)
 "Generates code for DefaultExperiment file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <DefaultExperiment>
  </DefaultExperiment>  
  >>
end DefaultExperiment;

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
case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
  <<
  <ModelVariables>
  <%vars.stateVars |> var =>
    ScalarVariable(var, "continuous")
  ;separator="\n"%>  
  <%vars.derivativeVars |> var =>
    ScalarVariable(var, "continuous")
  ;separator="\n"%>
  <%vars.algVars |> var =>
    ScalarVariable(var, "continuous")
  ;separator="\n"%>
  <%vars.paramVars |> var =>
    ScalarVariable(var, "parameter")
  ;separator="\n"%>
  <%vars.extObjVars |> var =>
    ScalarVariable(var, "continuous")
  ;separator="\n"%>
  <%vars.intAlgVars |> var =>
    ScalarVariable(var, "continuous")
  ;separator="\n"%>
  <%vars.intParamVars |> var =>
    ScalarVariable(var, "parameter")
  ;separator="\n"%>
  <%vars.boolAlgVars |> var =>
    ScalarVariable(var, "continuous")
  ;separator="\n"%>
  <%vars.boolParamVars |> var =>
    ScalarVariable(var, "parameter")
  ;separator="\n"%>  
  <%vars.stringAlgVars |> var =>
    ScalarVariable(var, "continuous")
  ;separator="\n"%>
  <%vars.stringParamVars |> var =>
    ScalarVariable(var, "parameter")
  ;separator="\n"%> 
  </ModelVariables>  
  >>
end ModelVariables;

template ScalarVariable(SimVar simVar, String variability)
 "Generates code for ScalarVariable file for FMU target."
::=
match simVar
  case SIMVAR(__) then
  <<
  <ScalarVariable >
  <%ScalarVariableAttribute(simVar,variability)%>
  </ScalarVariable>  
  >>
end ScalarVariable;

template ScalarVariableAttribute(SimVar simVar, String variability)
 "Generates code for ScalarVariable Attribute file for FMU target."
::=
match simVar
  case SIMVAR(__) then
  let valueReference = ''
  let description = comment
  let causality = ''
  let alias = ''
  <<
  name="<%crefStr(name)%>" valueReference="<%valueReference%>" description="<%description%>"
  variability="<%variability%>" causality="<%causality%>" alias="<%alias%>"
  >>  
end ScalarVariableAttribute;

template crefStr(ComponentRef cr)
 "Generates the name of a variable for variable name array."
::=
  match cr
  case CREF_IDENT(__) then '<%ident%><%subscriptsStr(subscriptLst)%>'
  case CREF_QUAL(ident = "$DER") then 'der(<%crefStr(componentRef)%>)'
  case CREF_QUAL(__) then '<%ident%><%subscriptsStr(subscriptLst)%>.<%crefStr(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end crefStr;

template subscriptsStr(list<Subscript> subscripts)
 "Generares subscript part of the name."
::=
  if subscripts then
    '[<%subscripts |> s => subscriptStr(s) ;separator=","%>]'
end subscriptsStr;

template subscriptStr(Subscript subscript)
 "Generates a single subscript.
  Only works for constant integer indicies."

::=
  let &preExp = buffer ""
  let &varDecls = buffer ""
  match subscript
  case INDEX(__) 
  case SLICE(__) then daeExp(exp, contextFunction, &preExp, &varDecls)
  case WHOLEDIM(__) then "WHOLEDIM"
  else "UNKNOWN_SUBSCRIPT"
end subscriptStr;

template daeExp(Exp exp, Context context, Text &preExp /*BUFP*/,
       Text &varDecls /*BUFP*/)
 "Generates code for an expression."
::=
  match exp
  case e as ICONST(__)         then integer
  case e as RCONST(__)         then real
  case e as BCONST(__)         then if bool then "(1)" else "(0)"
  case e as ENUM_LITERAL(__)   then index

  else "UNKNOWN_EXP"
end daeExp;

template fmumodel_identifierFile(SimCode simCode)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  #define MODEL_IDENTIFIER <%fileNamePrefix%>
  #define MODEL_GUID 
  #include "fmiModelFunctions.h"
  
  >>
end fmumodel_identifierFile;

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
