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

template translateModel(SimCode simCode)
 "Generates C code and Makefile for compiling a FMU of a
  Modelica model."
::=
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
  let guid = getUUIDStr()
  let target  = simulationCodeTarget()
  let name = lastIdentOfPath(modelInfo.name)
  let()= textFile(simulationHeaderFile(simCode), '<%name%>.h')
  let()= textFile(simulationCppFile(simCode), '<%name%>.cpp')
  let()= textFile(simulationFunctionsHeaderFile(simCode,modelInfo.functions,literals), 'Functions.h')
  let()= textFile(simulationFunctionsFile(simCode, modelInfo.functions,literals), 'Functions.cpp')
  let()= textFile(fmuModelWrapperFile(simCode,guid,name), '<%name%>FMU.cpp')
  let()= textFile(fmuModelDescriptionFile(simCode,guid), 'modelDescription.xml')
  let()= textFile(fmudeffile(simCode), '<%name%>.def')
  let()= textFile(fmuMakefile(target,simCode), '<%fileNamePrefix%>_FMU.makefile')
  algloopfiles(allEquations,simCode)
   // Return empty result since result written to files directly
end translateModel;


template fmuModelWrapperFile(SimCode simCode, String guid, String name)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  let modelName = lastIdentOfPath(modelInfo.name)
  <<
  // define class name and unique id
  #define MODEL_IDENTIFIER <%System.stringReplace(fileNamePrefix,".", "_")%>
  #define MODEL_GUID "{<%guid%>}"

  #include "Modelica.h"
  #include "<%modelName%>.h"
  
  <%ModelDefineData(modelInfo)%>
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
  /*
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
  */
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
  /*
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
    '<%if s.measureTime then "-D_OMC_MEASURE_TIME "%> <%match s.method
       case "inline-euler" then "-D_OMC_INLINE_EULER "
       case "inline-rungekutta" then "-D_OMC_INLINE_RK "
       case "dassljac" then "-D_OMC_JACOBIAN "%>'

  <<
  # Makefile generated by OpenModelica

  # Simulations use -O3 by default
  SIM_OR_DYNLOAD_OPT_LEVEL=
  MODELICAUSERCFLAGS=
  CXX=cl
  EXEEXT=.exe
  DLLEXT=.dll
  include <%makefileParams.omhome%>/include/omc/cpp/ModelicaConfic.inc
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
  LDFLAGS=/MD   /link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/omc/cpp/" /LIBPATH:"<%makefileParams.omhome%>/bin" OMCppSystem.lib OMCppMath.lib OMCppModelicaExternalC.lib

  # /MDd link with MSVCRTD.LIB debug lib
  # lib names should not be appended with a d just switch to lib/omc/cpp


  FILEPREFIX=<%fileNamePrefix%>
  FUNCTIONFILE=Functions.cpp
  MAINFILE=<%lastIdentOfPath(modelInfo.name)%><% if acceptMetaModelicaGrammar() then ".conv"%>.cpp
  MAINFILEFMU=<%lastIdentOfPath(modelInfo.name)%>FMU.cpp
  MAINOBJ=$(MODELICA_SYSTEM_LIB)
  GENERATEDFILES=$(MAINFILEFMU) $(MAINFILE) $(FUNCTIONFILE)  <%algloopcppfilenames(allEquations,simCode)%>

  $(MODELICA_SYSTEM_LIB)$(DLLEXT):
  <%\t%>$(CXX) /Fe$(MODELICA_SYSTEM_LIB) $(MAINFILEFMU) $(MAINFILE) $(FUNCTIONFILE)  <%algloopcppfilenames(allEquations,simCode)%> $(CFLAGS) $(LDFLAGS)
  >>
end match
case "gcc" then
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
let extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then
    '<%if s.measureTime then "-D_OMC_MEASURE_TIME "%> <%match s.method
       case "inline-euler" then "-D_OMC_INLINE_EULER"
       case "inline-rungekutta" then "-D_OMC_INLINE_RK"%>'
let modelName = '<%lastIdentOfPath(modelInfo.name)%>'
  <<
  # Makefile generated by OpenModelica
  include <%makefileParams.omhome%>/include/omc/cpp/ModelicaConfic.inc
  # Simulations use -O0 by default
  SIM_OR_DYNLOAD_OPT_LEVEL=-O0
  CC=<%makefileParams.ccompiler%>
  CXX=<%makefileParams.cxxcompiler%>
  LINK=<%makefileParams.linker%>
  EXEEXT=<%makefileParams.exeext%>
  DLLEXT=<%makefileParams.dllext%>
  CFLAGS_BASED_ON_INIT_FILE=<%extraCflags%>
  
  CFLAGS=$(CFLAGS_BASED_ON_INIT_FILE) -I"<%makefileParams.omhome%>/include/omc/cpp" -I"<%makefileParams.omhome%>/include/omc/cpp/Core" -I"$(BOOST_INCLUDE)" <%makefileParams.includes ; separator=" "%> <%makefileParams.cflags%> <%match sopt case SOME(s as SIMULATION_SETTINGS(__)) then s.cflags %>
  LDFLAGS=-L"<%makefileParams.omhome%>/lib/omc/cpp"
  
  OBJS=<%modelName%>.o
  OBJS+= <%modelName%>FMU.o
  OBJS+= Functions.o
  
  LIBS= -ldl
  LIBS+= -lOMCppSystem_static
  LIBS+= -lboost_system -lboost_filesystem -lboost_serialization
  
  %.o: %.cpp
  <%\t%>$(CXX) $(CFLAGS) -I. -c -o $@ $<
  
  <%modelName%>.fmu: $(OBJS)
  <%\t%>$(CXX) -shared -I. -o <%modelName%>.so $(OBJS) <%algloopcppfilenames(allEquations,simCode)%> $(CFLAGS) $(LDFLAGS) $(LIBS)
  <%\t%>-rm -rf fmu
  <%\t%>-rm <%modelName%>.fmu
  <%\t%>mkdir fmu
  <%\t%>mkdir fmu/binaries
  <%\t%>mkdir fmu/binaries/linux32
  <%\t%>mkdir fmu/binaries/linux64
  <%\t%>cp <%modelName%>.so fmu/binaries/linux32/
  <%\t%>cp <%modelName%>.so fmu/binaries/linux64/
  <%\t%>cp modelDescription.xml fmu
  <%\t%>(cd fmu; zip -r ../<%modelName%>.fmu *)
  <%\t%>rm -rf fmu
  
  .PHONY: clean
  clean:
  <%\t%>rm $(OBJS) <%modelName%>.so
  
  >>
end fmuMakefile;


end CodegenFMUCpp;

// vim: filetype=susan sw=2 sts=2
