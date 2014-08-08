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

template translateModel(SimCode simCode, Boolean useFlatArrayNotation)
 "Generates C code and Makefile for compiling a FMU of a
  Modelica model."
::=
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
  let guid = getUUIDStr()
  let target  = simulationCodeTarget()
  let name = lastIdentOfPath(modelInfo.name)
  let()= textFile(simulationHeaderFile(simCode,false), 'OMCpp<%name%>.h')
  let()= textFile(simulationCppFile(simCode,false), 'OMCpp<%name%>.cpp')
  let()= textFile(simulationFunctionsHeaderFile(simCode,modelInfo.functions,literals,false), 'OMCpp<%lastIdentOfPath(modelInfo.name)%>Functions.h')
  let()= textFile(simulationFunctionsFile(simCode, modelInfo.functions,literals,externalFunctionIncludes,false), 'OMCpp<%lastIdentOfPath(modelInfo.name)%>Functions.cpp')
  let()= textFile(simulationTypesHeaderFile(simCode,modelInfo.functions,literals, useFlatArrayNotation), 'OMCpp<%fileNamePrefix%>Types.h')
  let()= textFile(fmuModelWrapperFile(simCode,guid,name), 'OMCpp<%name%>FMU.cpp')
  let()= textFile(fmuModelDescriptionFileCpp(simCode,guid), 'modelDescription.xml')
  let()= textFile(simulationInitHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>Initialize.h')
  let()= textFile(simulationInitCppFile(simCode,false),'OMCpp<%fileNamePrefix%>Initialize.cpp')
  let()= textFile(simulationFactoryFile(simCode),'OMCpp<%fileNamePrefix%>FactoryExport.cpp')
  let()= textFile(simulationExtensionHeaderFile(simCode),'OMCpp<%fileNamePrefix%>Extension.h')
  let()= textFile(simulationExtensionCppFile(simCode),'OMCpp<%fileNamePrefix%>Extension.cpp')
  let()= textFile(simulationJacobianHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>Jacobian.h')
  let()= textFile(simulationJacobianCppFile(simCode,false),'OMCpp<%fileNamePrefix%>Jacobian.cpp')
  let()= textFile(simulationWriteOutputHeaderFile(simCode),'OMCpp<%fileNamePrefix%>WriteOutput.h')
  let()= textFile(simulationWriteOutputCppFile(simCode,false),'OMCpp<%fileNamePrefix%>WriteOutput.cpp')
  let()= textFile(simulationStateSelectionCppFile(simCode,false), 'OMCpp<%fileNamePrefix%>StateSelection.cpp')
  let()= textFile(simulationStateSelectionHeaderFile(simCode),'OMCpp<%fileNamePrefix%>StateSelection.h')
  let()= textFile(fmudeffile(simCode,"1.0"), '<%name%>.def')
  let()= textFile(fmuMakefile(target,simCode), '<%fileNamePrefix%>_FMU.makefile')
  let jac =  (jacobianMatrixes |> (mat, _,_, _, _, _,_)  =>
          (mat |> (eqs,_,_) =>  algloopfiles(eqs,simCode,contextAlgloopJacobian,false) ;separator="")
         ;separator="")
  let algs = algloopfiles(listAppend(allEquations,initialEquations),simCode,contextAlgloop,false)
  let()= textFile(algloopMainfile(listAppend(allEquations,initialEquations),simCode,contextAlgloop), 'OMCpp<%fileNamePrefix%>AlgLoopMain.cpp')
  let()= textFile(calcHelperMainfile(simCode), 'OMCpp<%fileNamePrefix%>CalcHelperMain.cpp')
 ""
   // Return empty result since result written to files directly
end translateModel;

template fmuModelDescriptionFileCpp(SimCode simCode, String guid)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <?xml version="1.0" encoding="UTF-8"?>
  <%fmiModelDescriptionCpp(simCode,guid)%>

  >>
end fmuModelDescriptionFileCpp;

template fmiModelDescriptionCpp(SimCode simCode, String guid)
 "Generates code for ModelDescription file for FMU target."
::=
//  <%UnitDefinitions(simCode)%>
//  <%TypeDefinitions(simCode)%>
//  <%VendorAnnotations(simCode)%>
match simCode
case SIMCODE(__) then
  <<
  <fmiModelDescription
    <%fmiModelDescriptionAttributesCpp(simCode,guid)%>>
    <%CodegenFMU.DefaultExperiment(simulationSettingsOpt)%>
    <%CodegenFMU.ModelVariables(modelInfo,"1.0")%>
  </fmiModelDescription>
  >>
end fmiModelDescriptionCpp;

template fmiModelDescriptionAttributesCpp(SimCode simCode, String guid)
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
  let numberOfEventIndicators = zerocrosslength(simCode)
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

template fmuModelWrapperFile(SimCode simCode, String guid, String name)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  let modelName = lastIdentOfPath(modelInfo.name)
  <<
  // define class name and unique id
  #define MODEL_IDENTIFIER <%System.stringReplace(fileNamePrefix,".", "_")%>Extension
  #define MODEL_GUID "{<%guid%>}"

  #include "Modelica.h"
  #include "ModelicaDefine.h"
  #include <System/IMixedSystem.h>
   #include <SimulationSettings/IGlobalSettings.h>
   #include <System/IAlgLoopSolverFactory.h>
   #include <System/IMixedSystem.h>
   #include <System/IAlgLoop.h>
   #include <Solver/IAlgLoopSolver.h>
   #include <System/IAlgLoopSolverFactory.h>
   #include <SimController/ISimData.h>
  #include "OMCpp<%lastIdentOfPath(modelInfo.name)%>Extension.h"

  <%ModelDefineData(modelInfo)%>
  #define NUMBER_OF_EVENT_INDICATORS <%zerocrosslength(simCode)%>

  #include "FMU/FMUWrapper.cpp"

  #define OBJECTCONSTRUCTOR (new FMUWrapper(instanceName, GUID, functions, loggingOn))
  #include "FMU/FMULibInterface.cpp"

  #if 0
  <%setDefaultStartValues(modelInfo)%>
  <%setStartValues(modelInfo)%>
  <%setExternalFunction(modelInfo)%>
  #endif

  >>
end fmuModelWrapperFile;

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

template fmuMakefile(String target,SimCode simCode)
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
  CFLAGS=/Od /EHa /MP /fp:except /I"<%makefileParams.omhome%>/include/omc/cpp/" -I"$(BOOST_INCLUDE)" /I. /DNOMINMAX /TP /DNO_INTERACTIVE_DEPENDENCY

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
  let modelName = '<%lastIdentOfPath(modelInfo.name)%>'
  let platformstr = match makefileParams.platform case "linux-i686" then 'linux32' else '<%makefileParams.platform%>'
  let mkdir = match makefileParams.platform case "win32" then '"mkdir.exe"' else 'mkdir'
  <<
  # Makefile generated by OpenModelica
  include <%makefileParams.omhome%>/include/omc/cpp/ModelicaConfig.inc
  # Simulations use -O0 by default
  SIM_OR_DYNLOAD_OPT_LEVEL=-O0
  CC=<%makefileParams.ccompiler%>
  CXX=<%makefileParams.cxxcompiler%>
  LINK=<%makefileParams.linker%>
  EXEEXT=<%makefileParams.exeext%>
  DLLEXT=<%makefileParams.dllext%>
  CFLAGS_BASED_ON_INIT_FILE=<%extraCflags%>

  CFLAGS=$(CFLAGS_BASED_ON_INIT_FILE) -Winvalid-pch $(SYSTEM_CFLAGS) -I"<%makefileParams.omhome%>/include/omc/cpp" -I"<%makefileParams.omhome%>/include/omc/cpp/Core" -I"<%makefileParams.omhome%>/include/omc/cpp/SimCoreFactory" -I"$(BOOST_INCLUDE)" <%makefileParams.includes ; separator=" "%>
  LDFLAGS=-L"<%makefileParams.omhome%>/lib/omc/cpp" -L$(BOOST_LIBS)  -L"$(BOOST_LIBS)" -l:$(BOOST_SYSTEM_LIB) -l:$(BOOST_FILESYSTEM_LIB)  -l:$(BOOST_PROGRAM_OPTIONS_LIB)
  PLATFORM="<%platformstr%>"
  SRC=OMCpp<%modelName%>.cpp
  SRC+= OMCpp<%modelName%>FMU.cpp
  SRC+= OMCpp<%fileNamePrefix%>CalcHelperMain.cpp
  SRC+= OMCpp<%fileNamePrefix%>AlgLoopMain.cpp
  LIBS= -lOMCppSystem_static -lOMCppDataExchange_static -lOMCppOMCFactory $(BASE_LIB)
  LIBS+= $(BOOST_SYSTEM_LIB) $(BOOST_FILESYSTEM_LIB) $(BOOST_SERIALIZATION_LIB)
  LIBS+= $(LINUX_LIB_DL)

  <%modelName%>.fmu: $(SRC)
  <%\t%>$(CXX) -shared -I. -o <%modelName%>$(DLLEXT) $(SRC) $(CFLAGS) $(LDFLAGS) $(LIBS)
  <%\t%>rm -rf binaries
  <%\t%><%mkdir%> -p "binaries/$(PLATFORM)"
  <%\t%>cp <%modelName%>$(DLLEXT) "binaries/$(PLATFORM)/"
  <%\t%>rm -f <%modelName%>.fmu
  <%\t%>zip -r "<%modelName%>.fmu" modelDescription.xml binaries binaries/$(PLATFORM) binaries/$(PLATFORM)/<%modelName%>$(DLLEXT)
  <%\t%>rm -rf binaries

  .PHONY: clean
  clean:
  <%\t%>rm $(SRC) <%modelName%>$(DLLEXT)

  >>
end fmuMakefile;


end CodegenFMUCpp;

// vim: filetype=susan sw=2 sts=2
