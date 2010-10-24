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
  <?xml version="1.0" encoding="UTF8"?>
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
case SIMCODE(modelInfo=MODELINFO(varInfo=VARINFO(numStateVars=numStateVars,numZeroCrossings=numZeroCrossings))) then
  let fmiVersion = '1.0' 
  let modelName = dotPath(modelInfo.name)
  let modelIdentifier = fileNamePrefix
  let description = ''
  let author = ''
  let version= '' 
  let generationTool= 'OpenModelica Compiler <%getVersionNr()%>'
  let generationDateAndTime = xsdateTime(getCurrentDateTime())
  let variableNamingConvention= 'structured'
  let numberOfContinuousStates = numStateVars
  let numberOfEventIndicators = numZeroCrossings
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
  case DATETIME(__) then '<%year%>-<%mon%>-<%mday%>T<%hour%>:<%min%>:<%sec%>Z'
end xsdateTime;

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
case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
  <<
  <ModelVariables>
  <%vars.stateVars |> var =>
    ScalarVariable(var,"internal",0)
  ;separator="\n"%>  
  <%vars.derivativeVars |> var =>
    ScalarVariable(var,"internal",10000)
  ;separator="\n"%>
  <%vars.inputVars |> var =>
    ScalarVariable(var,"input",100000)
  ;separator="\n"%>
  <%vars.outputVars |> var =>
    ScalarVariable(var,"output",200000)
  ;separator="\n"%>
  <%vars.algVars |> var =>
    ScalarVariable(var,"internal",1000000)
  ;separator="\n"%>
  <%vars.paramVars |> var =>
    ScalarVariable(var,"internal",5000000)
  ;separator="\n"%>
  <%vars.intAlgVars |> var =>
	ScalarVariable(var,"internal",0)
  ;separator="\n"%>
  <%vars.intParamVars |> var =>
    ScalarVariable(var,"internal",1000000)
  ;separator="\n"%>
  <%vars.boolAlgVars |> var =>
    ScalarVariable(var,"internal",0)
  ;separator="\n"%>
  <%vars.boolParamVars |> var =>
    ScalarVariable(var,"internal",1000000)
  ;separator="\n"%>  
  <%vars.stringAlgVars |> var =>
    ScalarVariable(var,"internal",0)
  ;separator="\n"%>
  <%vars.stringParamVars |> var =>
    ScalarVariable(var,"internal",1000000)
  ;separator="\n"%> 
  </ModelVariables>  
  >>
end ModelVariables;

template ScalarVariable(SimVar simVar, String causality, Integer offset)
 "Generates code for ScalarVariable file for FMU target."
::=
match simVar
  case SIMVAR(__) then
  <<
  <ScalarVariable 
  <%ScalarVariableAttribute(simVar,causality,offset)%>>
  <%ScalarVariableType(type_,unit,displayUnit,initialValue,isFixed)%>
  </ScalarVariable>  
  >>
end ScalarVariable;

template ScalarVariableAttribute(SimVar simVar, String causality, Integer offset)
 "Generates code for ScalarVariable Attribute file for FMU target."
::=
match simVar
  case SIMVAR(__) then
  let valueReference = intAdd(index,offset)
  let variability = getVariablity(varKind)
  let description = if stringEqual(comment,"") then 
      '' 
    else 
      'description="<%comment%>"' 
  let alias = 'noAlias'  //TODO get the right information about alias {noAlias,alias,negatedAlias}
  <<
    name="<%crefStr(name)%>" 
    valueReference="<%valueReference%>" 
    <%description%>
    variability="<%variability%>" 
    causality="<%causality%>" 
    alias="<%alias%>"
  >>  
end ScalarVariableAttribute;

template getVariablity(VarKind varKind)
 "Returns the variablity Attribute of ScalarVariable."
::=
match varKind
  case DISCRETE(__) then 'discrete'
  case PARAM(__) then 'parameter'
  case CONST(__) then 'constant'
  else 'continuous'
end getVariablity;

template ScalarVariableType(DAE.ExpType type_, String unit, String displayUnit, Option<DAE.Exp> initialValue, Boolean isFixed)
 "Generates code for ScalarVariable Type file for FMU target."
::=
match type_
  case ET_INT(__) then '  <Integer/>' 
  case ET_REAL(__) then '  <Real <%ScalarVariableTypeCommonAttribute(initialValue,isFixed)%> <%ScalarVariableTypeRealAttribute(unit,displayUnit)%>/>' 
  case ET_BOOL(__) then '  <Boolean/>' 
  case ET_STRING(__) then '  <String/>' 
  case ET_ENUMERATION(__) then '  <Enumeration/>' 
  else 'UNKOWN_TYPE'
end ScalarVariableType;

template ScalarVariableTypeCommonAttribute(Option<DAE.Exp> initialValue, Boolean isFixed)
 "Generates code for ScalarVariable Type file for FMU target."
::=
match initialValue
  case SOME(exp) then 'start="<%initVals(exp)%> fixed="<%isFixed%>"'
end ScalarVariableTypeCommonAttribute;

template ScalarVariableTypeRealAttribute(String unit, String displayUnit)
 "Generates code for ScalarVariable Type Real file for FMU target."
::=
  let unit_ = if stringEqual(unit,"") then 
      '' 
    else 
      'unit="<%unit%>"'   
  let displayUnit_ = if stringEqual(displayUnit,"") then 
      '' 
    else 
      'displayUnit="<%displayUnit%>"'   
  <<
  <%unit_%> <%displayUnit_%>
  >>
end ScalarVariableTypeRealAttribute;

template initVals(DAE.Exp initialValue)
::=
match initialValue 
  case ICONST(__) then integer
  case RCONST(__) then real
  case SCONST(__) then '"<%Util.escapeModelicaStringToCString(string)%>"'
  case BCONST(__) then if bool then "true" else "false"
  case ENUM_LITERAL(__) then '<%index%>'
  else "*ERROR* initial value of unknown type"
end initVals;

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

template fmumodel_identifierFile(SimCode simCode, String guid)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  #define MODEL_IDENTIFIER <%fileNamePrefix%>
  #define MODEL_GUID "<%guid%>"
  #include "fmiModelFunctions.h"
  // implementation of the Model Exchange functions
  #include "fmu_model_interface.c"
  
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
