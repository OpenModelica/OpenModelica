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

package CodegenOMSICpp

//imports used later for smaler extensions to omsic code generation
import interface SimCodeTV;
import interface SimCodeBackendTV;
import CodegenUtil.*;
import CodegenCpp.*;

//import CodegenCppCommon.*;
//import CodegenOMSI_common.*;

template translateModel(SimCode simCode, String FMUVersion, String FMUType)

::=
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then

  let &extraFuncs = buffer "" /*BUFD*/
  let &extraFuncsDecl = buffer "" /*BUFD*/

  let()= textFile(simulationOMSUCPPMainRunScript(simCode , &extraFuncs , &extraFuncsDecl, "", "", "", "exec"), '<%dotPath(modelInfo.name)%><%simulationMainRunScriptSuffix(simCode , &extraFuncs , &extraFuncsDecl, "")%>')

 ""
end translateModel;


template simulationOMSUCPPMainRunScript(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, String preRunCommandLinux, String preRunCommandWindows, String execCommandLinux)
 "Generates code for header file for simulation target."
::=
  match simCode
   case SIMCODE(modelInfo = MODELINFO(__), makefileParams = MAKEFILE_PARAMS(__), simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
    let start     = settings.startTime
    let end       = settings.stopTime
    let stepsize  = settings.stepSize
    let intervals = settings.numberOfIntervals
    let tol       = settings.tolerance
    let solver    = match simCode case SIMCODE(daeModeData=NONE()) then settings.method else 'ida' //for dae mode only ida is supported
    let moLib     =  makefileParams.compileDir
    let home      = makefileParams.omhome
    let outputformat = settings.outputFormat
    let modelName =  dotPath(modelInfo.name)
    let fileNamePrefixx = fileNamePrefix
    let platformstr = match makefileParams.platform case "i386-pc-linux" then 'linux32' case "x86_64-linux" then 'linux64' else '<%makefileParams.platform%>'
    let execParameters = '-S <%start%> -E <%end%> -H <%stepsize%> -G <%intervals%> -P <%outputformat%> -T <%tol%> -I <%solver%> -R <%simulationLibDir(simulationCodeTarget(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%> -M <%moLib%> -r <%simulationResults(Testsuite.isRunning(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)%> -a <%moLib%> -o <%modelName%>.fmu'
    let outputParameter = if (stringEq(settings.outputFormat, "empty")) then "-O none" else ""


    let libFolder =simulationLibDir(simulationCodeTarget(),simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
    let binFolder =simulationBinDir(simulationCodeTarget(),simCode )
    let libPaths = makefileParams.libPaths |> path => path; separator=";"
    let zermMQParams = if getConfigBool(USE_ZEROMQ_IN_SIM) then '-u true -p <%getConfigInt(ZEROMQ_PUB_PORT)%> -s <%getConfigInt(ZEROMQ_SUB_PORT)%> -v <%getConfigString(ZEROMQ_SERVER_ID)%> -c <%getConfigString(ZEROMQ_CLIENT_ID)%> -g <%getConfigString(ZEROMQ_JOB_ID)%>' else ''
    match makefileParams.platform
      case  "linux32"
      case  "linux64" then
        <<
        #!/bin/sh
        <%preRunCommandLinux%>
        <%execCommandLinux%> <%binFolder%>/OMCppOSUSimulation <%execParameters%> <%zermMQParams%> <%outputParameter%> $*
        >>
      case  "win32"
      case  "win64" then
        <<
        @echo off
        SET PATH=<%binFolder%>;<%libFolder%>;<%libPaths%>;%PATH%
        REM ::export PATH=<%libFolder%>:$PATH REPLACE C: with /C/
        <%preRunCommandWindows%>
        OMCppOSUSimulation.exe <%execParameters%> <%zermMQParams%> <%outputParameter%>
        >>
    end match
  end match
end simulationOMSUCPPMainRunScript;




annotation(__OpenModelica_Interface="backend");
end CodegenOMSICpp;


