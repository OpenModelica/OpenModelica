/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package SimCodeMain
" file:        SimCodeMain.mo
  package:     SimCodeMain
  description: Code generation using Susan templates

  The entry points to this module are the translateModel function and the
  translateFunctions function."

public
import Absyn;
import BackendDAE;
import BackendDAEUtil;
import Ceval;
import DAE;
import FCore;
import HashTableExpToIndex;
import Tpl;
import Values;
import SimCode;

protected
import Autoconf;
import AvlSetString;
import BackendDAECreate;
import BackendDump;
import BackendVariable;
import Builtin;
import ClockIndexes;
import CevalScriptBackend;
import CodegenC;
import CodegenEmbeddedC;
import CodegenFMU;
import CodegenFMUCppOld;
import CodegenOMSICpp;
import CodegenFMUCppHpcomOld;
import CodegenCppOld;
import CodegenCppHpcomOld;
import CodegenOMSIC;
import CodegenOMSI_common;
import CodegenXML;
import CodegenJS;
import Config;
import DAEMode;
import DAEUtil;
import Debug;
import DoubleEnded;
import Error;
import ErrorExt;
import ExecStat;
import Flags;
import FMI;
import GCExt;
import HashTable;
import HashTableCrefSimVar;
import HashTableCrIListArray;
import HashTableCrILst;
import HpcOmSimCodeMain;
import HpcOmTaskGraph;
import RuntimeSources;
import SerializeModelInfo;
import SerializeInitXML;
import SimCodeUtil;
import StackOverflow;
import StringUtil;
import SymbolicJacobian;
import SymbolTable;
import System;
import Testsuite;
import Util;
import SerializeTaskSystemInfo;

public
constant Boolean debug=true;
uniontype TranslateModelKind
  record NORMAL
  end NORMAL;
  record XML
  end XML;
  record FMU
    String kind;
    String targetName;
  end FMU;
end TranslateModelKind;

public function createSimulationSettings
  input Real startTime;
  input Real stopTime;
  input Integer inumberOfIntervals;
  input Real tolerance;
  input String method;
  input String options;
  input String outputFormat;
  input String variableFilter;
  input String cflags;
  output SimCode.SimulationSettings simSettings;
protected
  Real stepSize;
  Integer numberOfIntervals;
algorithm
  numberOfIntervals := if inumberOfIntervals <= 0 then 1 else inumberOfIntervals;
  stepSize := (stopTime - startTime) / intReal(numberOfIntervals);
  simSettings := SimCode.SIMULATION_SETTINGS(
    startTime, stopTime, numberOfIntervals, stepSize, tolerance,
    method, options, outputFormat, variableFilter, cflags);
end createSimulationSettings;


protected function generateModelCodeFMU "
  Generates code for a model by creating a SimCode structure and calling the
  template-based code generator on it."
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.BackendDAE inInitDAE;
  input Option<BackendDAE.BackendDAE> inInitDAE_lambda0;
  input BackendDAE.SymbolicJacobians inFMIDer;
  input list<BackendDAE.Equation> inRemovedInitialEquationLst;
  input Absyn.Program p;
  input Absyn.Path className;
  input String FMUVersion;
  input String FMUType;
  input String filenamePrefix;
  input String fmuTargetName;
  input Option<SimCode.SimulationSettings> simSettings;
  output list<String> libs;
  output String fileDir;
  output Real timeSimCode;
  output Real timeTemplates;
protected
  list<String> includes,includeDirs;
  list<SimCodeFunction.Function> functions;
  String filename, funcfilename;
  SimCode.SimCode simCode;
  list<SimCodeFunction.RecordDeclaration> recordDecls;
  BackendDAE.BackendDAE indexed_dlow,indexed_dlow_1;
  Absyn.ComponentRef a_cref;
  list<String> libPaths;
  tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>> literals;
algorithm
  System.realtimeTick(ClockIndexes.RT_CLOCK_SIMCODE);
  a_cref := AbsynUtil.pathToCref(className);
  /*Temporary disabled omsicpp*/
  if ((Config.simCodeTarget() ==  "omsic") /*or (Config.simCodeTarget() == "omsicpp")*/) then
    fileDir := listHead(AbsynUtil.pathToStringList(className))+".tmp";
  else
    fileDir := CevalScriptBackend.getFileDir(a_cref, p);
  end if;
  (libs,libPaths,includes, includeDirs, recordDecls, functions, literals) :=
    SimCodeUtil.createFunctions(p, inBackendDAE.shared.functionTree);
  simCode := createSimCode(inBackendDAE, inInitDAE, inInitDAE_lambda0, NONE(),
    inRemovedInitialEquationLst, className, filenamePrefix, fileDir, functions,
    includes, includeDirs, libs, libPaths, p, simSettings, recordDecls,
    literals, Absyn.FUNCTIONARGS({},{}), isFMU=true, FMUVersion=FMUVersion,
    fmuTargetName=fmuTargetName, inFMIDer=inFMIDer);
  timeSimCode := System.realtimeTock(ClockIndexes.RT_CLOCK_SIMCODE);
  ExecStat.execStat("SimCode");

  System.realtimeTick(ClockIndexes.RT_CLOCK_TEMPLATES);
  /*Temporary disabled omsi fmu and generate C-fmu for omsicpp simcodetarget*/
  if Config.simCodeTarget() == "omsicpp" then
     callTargetTemplatesFMU(simCode, "C", FMUVersion, FMUType);
   else
    callTargetTemplatesFMU(simCode, Config.simCodeTarget(), FMUVersion, FMUType);
  end if;
  timeTemplates := System.realtimeTock(ClockIndexes.RT_CLOCK_TEMPLATES);
end generateModelCodeFMU;


protected function generateModelCodeXML "
  Generates code for a model by creating a SimCode structure and calling the
  template-based code generator on it."
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.BackendDAE inInitDAE;
  input Option<BackendDAE.BackendDAE> inInitDAE_lambda0;
  input list<BackendDAE.Equation> inRemovedInitialEquationLst;
  input Absyn.Program p;
  input Absyn.Path className;
  input String filenamePrefix;
  input Option<SimCode.SimulationSettings> simSettingsOpt;
  output list<String> libs;
  output String fileDir;
  output Real timeSimCode;
  output Real timeTemplates;
protected
  list<String> includes,includeDirs;
  list<SimCodeFunction.Function> functions;
  String filename, funcfilename;
  SimCode.SimCode simCode;
  list<SimCodeFunction.RecordDeclaration> recordDecls;
  BackendDAE.BackendDAE indexed_dlow,indexed_dlow_1;
  list<String> libPaths;
  Absyn.ComponentRef a_cref;
  tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>> literals;
  list<tuple<String, String>> program;
algorithm
  System.realtimeTick(ClockIndexes.RT_CLOCK_SIMCODE);
  a_cref := AbsynUtil.pathToCref(className);
  fileDir := CevalScriptBackend.getFileDir(a_cref, p);
  (libs, libPaths, includes, includeDirs, recordDecls, functions, literals) :=
    SimCodeUtil.createFunctions(p, inBackendDAE.shared.functionTree);
  (simCode,_) := SimCodeUtil.createSimCode(inBackendDAE, inInitDAE, inInitDAE_lambda0, NONE(), inRemovedInitialEquationLst,
    className, filenamePrefix, fileDir, functions, includes, includeDirs, libs,libPaths, p, simSettingsOpt, recordDecls, literals,Absyn.FUNCTIONARGS({},{}));
  timeSimCode := System.realtimeTock(ClockIndexes.RT_CLOCK_SIMCODE);
  ExecStat.execStat("SimCode");

  System.realtimeTick(ClockIndexes.RT_CLOCK_TEMPLATES);
  callTargetTemplatesXML(simCode, Config.simCodeTarget());
  timeTemplates := System.realtimeTock(ClockIndexes.RT_CLOCK_TEMPLATES);
end generateModelCodeXML;

public function generateModelCode "
  Generates code for a model by creating a SimCode structure and calling the
  template-based code generator on it."
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.BackendDAE inInitDAE;
  input Option<BackendDAE.BackendDAE> inInitDAE_lambda0;
  input Option<BackendDAE.InlineData> inInlineData;
  input list<BackendDAE.Equation> inRemovedInitialEquationLst;
  input Absyn.Program p;
  input Absyn.Path className;
  input String filenamePrefix;
  input Option<SimCode.SimulationSettings> simSettingsOpt;
  input Absyn.FunctionArgs args;
  input BackendDAE.SymbolicJacobians inFMIDer = {};
  output list<String> libs;
  output String fileDir;
  output Real timeSimCode;
  output Real timeTemplates;
protected
  list<String> includes, includeDirs,libPaths;
  list<SimCodeFunction.Function> functions;
  SimCode.SimCode simCode;
  list<SimCodeFunction.RecordDeclaration> recordDecls;
  Absyn.ComponentRef a_cref;
  tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> literals;
  list<tuple<String, String>> program;
  Integer numCheckpoints;
  String fmuVersion;

algorithm
  numCheckpoints:=ErrorExt.getNumCheckpoints();
  try
  StackOverflow.clearStacktraceMessages();
  if Flags.isSet(Flags.GRAPHML) then
    HpcOmTaskGraph.dumpTaskGraph(inBackendDAE, filenamePrefix);
    BackendDump.dumpBackendDAEBipartiteGraph(inBackendDAE, "BipartiteGraph_CompleteDAE_"+filenamePrefix);
  end if;
  System.realtimeTick(ClockIndexes.RT_CLOCK_SIMCODE);
  a_cref := AbsynUtil.pathToCref(className);
  fileDir := CevalScriptBackend.getFileDir(a_cref, p);

  (libs, libPaths, includes, includeDirs, recordDecls, functions, literals) := SimCodeUtil.createFunctions(p, inBackendDAE.shared.functionTree);
   /*Temporary disabled omsicpp
   if Config.simCodeTarget() ==  "omsicpp" then
     fmuVersion:="2.0";
     simCode := createSimCode(inBackendDAE, inInitDAE, inInitDAE_lambda0, inInlineData, inRemovedInitialEquationLst, className, filenamePrefix, fileDir, functions, includes, includeDirs, libs,libPaths, p, simSettingsOpt, recordDecls, literals, args,isFMU=true, FMUVersion=fmuVersion,
    fmuTargetName=listHead(AbsynUtil.pathToStringList(className)), inFMIDer=inFMIDer);
   else*/
    simCode := createSimCode(inBackendDAE, inInitDAE, inInitDAE_lambda0, inInlineData, inRemovedInitialEquationLst, className, filenamePrefix, fileDir, functions, includes, includeDirs, libs,libPaths, p, simSettingsOpt, recordDecls, literals, args,inFMIDer=inFMIDer);
   /*end if;*/
  timeSimCode := System.realtimeTock(ClockIndexes.RT_CLOCK_SIMCODE);
  ExecStat.execStat("SimCode");

  if Flags.isSet(Flags.SERIALIZED_SIZE) then
    serializeNotify(simCode, "SimCode");
    ExecStat.execStat("Serialize simCode");
  end if;

  System.realtimeTick(ClockIndexes.RT_CLOCK_TEMPLATES);
  callTargetTemplates(simCode, Config.simCodeTarget());
  timeTemplates := System.realtimeTock(ClockIndexes.RT_CLOCK_TEMPLATES);
  ExecStat.execStat("Templates");
  return;
  else
  setGlobalRoot(Global.stackoverFlowIndex, NONE());
  ErrorExt.rollbackNumCheckpoints(ErrorExt.getNumCheckpoints()-numCheckpoints);
  Error.addInternalError("Stack overflow in "+getInstanceName()+"...\n"+stringDelimitList(StackOverflow.readableStacktraceMessages(), "\n"), sourceInfo());
  /* Do not fail or we can loop too much */
  StackOverflow.clearStacktraceMessages();
  end try annotation(__OpenModelica_stackOverflowCheckpoint=true);
  fail();
end generateModelCode;

protected function createSimCode "
  SimCode generator switch - if the NUMPROC-Flag is set, the simcode will be extended with parallel informations."
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.BackendDAE inInitDAE;
  input Option<BackendDAE.BackendDAE> inInitDAE_lambda0;
  input Option<BackendDAE.InlineData> inInlineData;
  input list<BackendDAE.Equation> inRemovedInitialEquationLst;
  input Absyn.Path inClassName;
  input String filenamePrefix;
  input String inString11;
  input list<SimCodeFunction.Function> functions;
  input list<String> externalFunctionIncludes;
  input list<String> includeDirs;
  input list<String> libs;
  input list<String> libPaths;
  input Absyn.Program program;
  input Option<SimCode.SimulationSettings> simSettingsOpt;
  input list<SimCodeFunction.RecordDeclaration> recordDecls;
  input tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> literals;
  input Absyn.FunctionArgs args;
  input Boolean isFMU=false;
  input String FMUVersion="";
  input String fmuTargetName="";
  input BackendDAE.SymbolicJacobians inFMIDer = {};
  output SimCode.SimCode simCode;
algorithm
  // FIXME This matchcontinue is extremely horrible! Please remove it
  simCode := matchcontinue(inBackendDAE, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs, libPaths, program, simSettingsOpt, recordDecls, literals, args)
    local
      Integer numProc;
      SimCode.SimCode tmpSimCode;

    case(_, _, _, _, _, _, _, _, _, _,_, _, _, _) equation
      // MULTI_RATE PARTITIONINIG
      true = Flags.isSet(Flags.MULTIRATE_PARTITION);
    then HpcOmSimCodeMain.createSimCode(inBackendDAE, inInitDAE, inInitDAE_lambda0, inRemovedInitialEquationLst, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs,libPaths, program, simSettingsOpt, recordDecls, literals, args);

    case(_, _, _, _, _, _, _, _, _, _,_, _, _, _) equation
      true = Flags.isSet(Flags.HPCOM);

      // either generate code for profiling or for parallel simulation
      //bcall(not stringEq("none",Flags.getConfigString(Flags.PROFILING_LEVEL)),print,"Deactivate profiling if you want to simulate in parallel.\n");
      //_ = bcallret2((not stringEq("none",Flags.getConfigString(Flags.PROFILING_LEVEL))) and (not stringEq("all_perf",Flags.getConfigString(Flags.PROFILING_LEVEL))),FlagsUtil.set,Flags.HPCOM,false,true);
      //true = stringEq("none",Flags.getConfigString(Flags.PROFILING_LEVEL)) or stringEq("all_perf",Flags.getConfigString(Flags.PROFILING_LEVEL));

      numProc = Flags.getConfigInt(Flags.NUM_PROC);
      true = numProc == 0;
      print("hpcom computes the ideal number of processors. If you want to set the number manually, use the flag +n=_ \n");
    then HpcOmSimCodeMain.createSimCode(inBackendDAE, inInitDAE, inInitDAE_lambda0, inRemovedInitialEquationLst, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs,libPaths,program, simSettingsOpt, recordDecls, literals, args);

    case(_, _, _, _, _, _, _, _, _,_, _, _, _, _) equation
      true = Flags.isSet(Flags.HPCOM);

      // either generate code for profiling or for parallel simulation
      //bcall((not stringEq("none",Flags.getConfigString(Flags.PROFILING_LEVEL))) and (not stringEq("all_perf",Flags.getConfigString(Flags.PROFILING_LEVEL))),print,"Deactivate profiling if you want to simulate in parallel.\n");
      //_ = bcallret2(not stringEq("none",Flags.getConfigString(Flags.PROFILING_LEVEL)),FlagsUtil.set,Flags.HPCOM,false,true);
      //true = stringEq("none",Flags.getConfigString(Flags.PROFILING_LEVEL)) or stringEq("all_perf",Flags.getConfigString(Flags.PROFILING_LEVEL));

      numProc = Flags.getConfigInt(Flags.NUM_PROC);
      true = (numProc > 0);
    then HpcOmSimCodeMain.createSimCode(inBackendDAE, inInitDAE, inInitDAE_lambda0, inRemovedInitialEquationLst, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs, libPaths,program,simSettingsOpt, recordDecls, literals, args);

    else equation
      (tmpSimCode, _) = SimCodeUtil.createSimCode(inBackendDAE, inInitDAE, inInitDAE_lambda0, inInlineData, inRemovedInitialEquationLst, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs,libPaths,program, simSettingsOpt, recordDecls, literals, args, isFMU=isFMU, FMUVersion=FMUVersion, fmuTargetName=fmuTargetName, inFMIDer=inFMIDer);
    then tmpSimCode;
  end matchcontinue;
end createSimCode;

protected
partial function PartialRunTpl
  output tuple<Boolean,list<String>> res;
end PartialRunTpl;

partial function FuncText
  input Tpl.Text txt;
  output Tpl.Text out_txt;
end FuncText;

function runTplWriteFile
  extends PartialRunTpl;
  input FuncText func;
  input String file;
protected
  Integer nErr;
algorithm
  res := (false,{});
  try
    SimCodeUtil.resetFunctionIndex();
    SimCodeFunctionUtil.codegenResetTryThrowIndex();
    if Config.acceptMetaModelicaGrammar() or Flags.isSet(Flags.GEN_DEBUG_SYMBOLS) then
      Tpl.textFileConvertLines(Tpl.tplCallWithFailErrorNoArg(func), file);
    else
      nErr := Error.getNumErrorMessages();
      Tpl.closeFile(Tpl.tplCallWithFailErrorNoArg(func,Tpl.redirectToFile(Tpl.emptyTxt, file)));
      Tpl.failIfTrue(Error.getNumErrorMessages() > nErr);
    end if;
    res := (true,SimCodeUtil.getFunctionIndex());
  else
  end try;
end runTplWriteFile;

function runTpl
  extends PartialRunTpl;
  input FuncText func;
algorithm
  res := (false,{});
  try
    SimCodeUtil.resetFunctionIndex();
    SimCodeFunctionUtil.codegenResetTryThrowIndex();
    Tpl.tplCallWithFailErrorNoArg(func);
    res := (true,SimCodeUtil.getFunctionIndex());
  else
  end try;
end runTpl;

// TODO: use another switch ... later make it first class option like -target or so
protected function callTargetTemplates "
  Generate target code by passing the SimCode data structure to templates."
  input SimCode.SimCode simCode;
  input String target;
protected
  partial function Func
    input Tpl.Text txt;
    input SimCode.SimCode a_simCode;
    output Tpl.Text out_txt;
  end Func;
  partial function FuncText
    input Tpl.Text txt;
    output Tpl.Text out_txt;
  end FuncText;
  partial function BoolFunc
    input Tpl.Text txt;
    input SimCode.SimCode a_simCode;
    output Tpl.Text out_txt;
  end BoolFunc;
  Func func;
  Tpl.Text txt;

  function runToStr
    extends PartialRunTpl;
    input Func func;
    partial function Func
      output String str;
    end Func;
  algorithm
    res := (false,{});
    try
      SimCodeUtil.resetFunctionIndex();
      SimCodeFunctionUtil.codegenResetTryThrowIndex();
      func();
      res := (true,SimCodeUtil.getFunctionIndex());
    else
    end try;
  end runToStr;

  function runCodegenFunc
    input PartialRunTpl func;
    output tuple<Boolean,list<String>> res;
  protected
    Boolean b;
  algorithm
    (res as (b,_)) := func();
    if not b then
      Error.addInternalError(System.dladdr(func) + " failed\n", sourceInfo());
    end if;
    if ErrorExt.getNumMessages() > 0 then
      ErrorExt.moveMessagesToParentThread();
    end if;
  end runCodegenFunc;

  function runToBoolean
    input Func func;
    output tuple<Boolean,list<String>> res;
  protected
    partial function Func
      output Boolean b;
    end Func;
  algorithm
    res := (func(),{});
  end runToBoolean;


  AvlSetString.Tree generatedObjects=AvlSetString.EMPTY();
algorithm
  setGlobalRoot(Global.optionSimCode, SOME(simCode));
  _ := match target
    local
      String str, guid;
      list<PartialRunTpl> codegenFuncs;
      Integer numThreads, n;
      list<tuple<Boolean,list<String>>> res;
      list<String> strs, tmp, matches;

    case "Cpp"
      algorithm
        callTargetTemplatesCPP(simCode);
        for str in {"CalcHelperMain.o\n",".so\n"} loop
          generatedObjects := AvlSetString.add(generatedObjects, "OMCpp" + simCode.fileNamePrefix + str);
        end for;
      then ();

    case "C"
      algorithm
        guid := System.getUUIDStr();

        System.realtimeTick(ClockIndexes.RT_PROFILER0);
        codegenFuncs := {};
        codegenFuncs := (function runToBoolean(func=function SerializeInitXML.simulationInitFileReturnBool(simCode=simCode, guid=guid))) :: codegenFuncs;
        codegenFuncs := (function runTpl(func=function CodegenC.translateModel(in_a_simCode=simCode))) :: codegenFuncs;
        for f in {
          // external objects
          (CodegenC.simulationFile_exo, "_01exo.c"),
          // non-linear systems
          (CodegenC.simulationFile_nls, "_02nls.c"),
          (CodegenC.simulationFile_lsy, "_03lsy.c"),
          (CodegenC.simulationFile_set, "_04set.c"),
          (CodegenC.simulationFile_evt, "_05evt.c"),
          (CodegenC.simulationFile_inz, "_06inz.c"),
          (CodegenC.simulationFile_dly, "_07dly.c"),
          (CodegenC.simulationFile_bnd, "_08bnd.c"),
          (CodegenC.simulationFile_alg, "_09alg.c"),
          (CodegenC.simulationFile_asr, "_10asr.c"),
          (CodegenC.simulationFile_jac, "_12jac.c"),
          (CodegenC.simulationFile_jac_header, "_12jac.h"),
          (CodegenC.simulationFile_opt, "_13opt.c"),
          (CodegenC.simulationFile_opt_header, "_13opt.h"),
          (CodegenC.simulationFile_lnz, "_14lnz.c"),
          (CodegenC.simulationFile_syn, "_15syn.c"),
          (CodegenC.simulationFile_dae, "_16dae.c"),
          (CodegenC.simulationFile_dae_header, "_16dae.h"),
          (CodegenC.simulationFile_inl, "_17inl.c"),
          (CodegenC.simulationFile_spd, "_18spd.c"),
          (CodegenC.simulationHeaderFile, "_model.h")
        } loop
          (func,str) := f;
          codegenFuncs := (function runTplWriteFile(func=function func(a_simCode=simCode), file=simCode.fileNamePrefix + str)) :: codegenFuncs;
          (n,matches) := System.regex(str, "\\(.*\\)[.]c$", 2, false, false);
          if n==2 then
            _::str::_ := matches;
            generatedObjects := AvlSetString.add(generatedObjects, simCode.fileNamePrefix + str + ".o\n");
          end if;
        end for;
        for str in {"_11mix.o\n","_functions.o\n","_info.json\n","_init.xml\n"} loop
          generatedObjects := AvlSetString.add(generatedObjects, simCode.fileNamePrefix + str);
        end for;
        codegenFuncs := (function runTpl(func=function CodegenC.simulationFile_mixAndHeader(a_simCode=simCode, a_modelNamePrefix=simCode.fileNamePrefix))) :: codegenFuncs;
        codegenFuncs := (function runTplWriteFile(func=function CodegenC.simulationFile(in_a_simCode=simCode, in_a_guid=guid, in_a_isModelExchangeFMU=""), file=simCode.fileNamePrefix + ".c")) :: codegenFuncs;
        codegenFuncs := (function runTplWriteFile(func=function CodegenC.simulationFunctionsFile(a_filePrefix=simCode.fileNamePrefix, a_functions=simCode.modelInfo.functions), file=simCode.fileNamePrefix + "_functions.c")) :: codegenFuncs;

        codegenFuncs := (function runToStr(func=function SerializeModelInfo.serialize(code=simCode, withOperations=Flags.isSet(Flags.INFO_XML_OPERATIONS)))) :: codegenFuncs;

        if Flags.getConfigBool(Flags.PARMODAUTO) then
          codegenFuncs := (function runToStr(func=function SerializeTaskSystemInfo.serializeParMod(code=simCode, withOperations=Flags.isSet(Flags.INFO_XML_OPERATIONS)))) :: codegenFuncs;
        end if;

        // Test the parallel code generator in the test suite. Should give decent results given that the task is disk-intensive.
        numThreads := max(1, if Testsuite.isRunning() then min(2, System.numProcessors()) else Config.noProc());
        if (not Flags.isSet(Flags.PARALLEL_CODEGEN)) or numThreads==1 then
          res := list(func() for func in codegenFuncs);
        else
          res := System.launchParallelTasks(numThreads, codegenFuncs, runCodegenFunc);
        end if;
        strs := {};
        for tpl in res loop
          (true,tmp) := tpl;
          strs := List.append_reverse(tmp, strs);
        end for;
        strs := listReverse(strs);
        // Some files are only sometimes generated, like initialization when it has >2000 equations
        for str in strs loop
          (n,matches) := System.regex(str, "\\(.*\\)[.]c$", 2, false, false);
          if n==2 then
            _::str::_ := matches;
            generatedObjects := AvlSetString.add(generatedObjects, simCode.fileNamePrefix + str + ".o\n");
          end if;
        end for;
        // write the makefile last!
        Tpl.closeFile(Tpl.tplCallWithFailError3(CodegenC.simulationMakefile,Config.simulationCodeTarget(),simCode,strs,txt=Tpl.redirectToFile(Tpl.emptyTxt, simCode.fileNamePrefix+".makefile")));
      then ();

    case "ExperimentalEmbeddedC"
      algorithm
        _ := System.getUUIDStr();

        System.realtimeTick(ClockIndexes.RT_PROFILER0);
        codegenFuncs := {};
        for f in {
          (CodegenEmbeddedC.mainFile, "_main.c")
        } loop
          (func,str) := f;
          codegenFuncs := (function runTplWriteFile(func=function func(a_simCode=simCode), file=simCode.fileNamePrefix + str)) :: codegenFuncs;
        end for;

        // Test the parallel code generator in the test suite. Should give decent results given that the task is disk-intensive.
        numThreads := max(1, if Testsuite.isRunning() then min(2, System.numProcessors()) else Config.noProc());
        if (not Flags.isSet(Flags.PARALLEL_CODEGEN)) or numThreads==1 then
          res := list(func() for func in codegenFuncs);
        else
          res := System.launchParallelTasks(numThreads, codegenFuncs, runCodegenFunc);
        end if;
        strs := {};
        for tpl in res loop
          (true,tmp) := tpl;
          strs := List.append_reverse(tmp, strs);
        end for;
        strs := listReverse(strs);
        // write the makefile last!
      then ();

    case "JavaScript" equation
      guid = System.getUUIDStr();
      Tpl.tplNoret(CodegenC.translateModel, simCode);
      SerializeInitXML.simulationInitFile(simCode, guid);
      System.covertTextFileToCLiteral(simCode.fileNamePrefix+"_init.xml",simCode.fileNamePrefix+"_init.c", Config.simulationCodeTarget());
      SerializeModelInfo.serialize(simCode, Flags.isSet(Flags.INFO_XML_OPERATIONS));
      Tpl.tplNoret(CodegenJS.markdownFile, simCode);
    then ();

    case "XML" equation
      Tpl.tplNoret(CodegenXML.translateModel, simCode);
    then ();

    case "None"
    then ();

    else equation
      str = "Unknown template target: " + target;
      Error.addMessage(Error.INTERNAL_ERROR, {str});
    then fail();
  end match;
  if Testsuite.isRunning() then
    System.appendFile(Testsuite.getTempFilesFile(), stringAppendList(AvlSetString.listKeys(generatedObjects)));
  end if;
  setGlobalRoot(Global.optionSimCode, NONE());
end callTargetTemplates;

protected function callTargetTemplatesCPP
  input SimCode.SimCode iSimCode;
algorithm
  if(Flags.isSet(Flags.HPCOM)) then
    Tpl.tplNoret(CodegenCppHpcomOld.translateModel, iSimCode);
  else
    Tpl.tplNoret(CodegenCppOld.translateModel, iSimCode);
  end if;
end callTargetTemplatesCPP;

protected function callTargetTemplatesOMSICpp
  input SimCode.SimCode iSimCode;
  protected
  String fmuVersion;
  String fmuType;

algorithm
    fmuVersion:="2.0";
    fmuType:="me";
   Tpl.tplNoret3(CodegenOMSICpp.translateModel, iSimCode, fmuVersion, fmuType);
   callTargetTemplatesFMU(iSimCode,"C",fmuVersion,fmuType);
end callTargetTemplatesOMSICpp;

protected function callTargetTemplatesFMU
"Generate target code by passing the SimCode data structure to templates."
  input SimCode.SimCode simCode;
  input String target;
  input String FMUVersion;
  input String FMUType;
algorithm

  setGlobalRoot(Global.optionSimCode, SOME(simCode));
  _ := match (simCode,target)
    local
      String str, newdir, newpath, resourcesDir, dirname;
      String fmutmp;
      String guid;
      Boolean b;
      Boolean needSundials = false;
      String fileprefix;
      String install_include_omc_dir, install_include_omc_c_dir, install_fmu_sources_dir, fmu_tmp_sources_dir;
      list<String> sourceFiles, model_desc_src_files;
      list<String> dgesv_sources, simrt_c_sundials_sources, simrt_linear_solver_sources, simrt_non_linear_solver_sources;
      list<String> simrt_mixed_solver_sources, fmi_export_files, model_gen_files, model_all_gen_files, shared_source_files;
      SimCode.VarInfo varInfo;
    case (SimCode.SIMCODE(),"C")
      algorithm
        fmutmp := simCode.fileNamePrefix + ".fmutmp";
        if System.directoryExists(fmutmp) then
          if not System.removeDirectory(fmutmp) then
            Error.addInternalError("Failed to remove directory: " + fmutmp, sourceInfo());
            fail();
          end if;
        end if;
        Util.createDirectoryTree(fmutmp + "/sources/include/");
        Util.createDirectoryTree(fmutmp + "/resources/");
        resourcesDir := fmutmp + "/resources/";
        for path in simCode.modelInfo.resourcePaths loop
          dirname := System.dirname(path);
          // on windows, remove ":" from the path!
          if Autoconf.os == "Windows_NT" then
            dirname := System.stringReplace(dirname, ":", "");
          end if;
          newdir := resourcesDir + dirname;
          newpath := resourcesDir + path;
          if System.regularFileExists(newpath) or System.directoryExists(newpath) then
            /* Already copied. Maybe one resource loaded a library and this one only a file in the directory */
            continue;
          end if;
          Util.createDirectoryTree(newdir);
          // copy the file or directory
          if 0 <> System.systemCall("cp -rf \"" + path + "\" \"" + newdir + "/\"") then
            Error.addInternalError("Failed to copy path " + path + " to " + fmutmp + "/resources/" + dirname, sourceInfo());
          end if;
        end for;

        // Add optional _flags.json to resources
        _ := match simCode.fmiSimulationFlags
          local
            SimCode.FmiSimulationFlags fmiSimFlags;
            String pathToFlagsJson;
          case SOME(fmiSimFlags as SimCode.FMI_SIMULATION_FLAGS_FILE(path=pathToFlagsJson))
            algorithm
            needSundials := true;
            if 0 <> System.systemCall("cp -rf \"" + pathToFlagsJson + "\" \"" + fmutmp + "/resources/" + simCode.fileNamePrefix+"_flags.json\"") then
              Error.addInternalError("Failed to copy " + pathToFlagsJson + " to " + fmutmp + "/resources/" + simCode.fileNamePrefix + "_flags.json", sourceInfo());
            end if;
            then();
          else
            then();
          end match;

        SerializeModelInfo.serialize(simCode, Flags.isSet(Flags.INFO_XML_OPERATIONS));
        str := fmutmp + "/sources/" + simCode.fileNamePrefix;
        if FMUVersion == "1.0" then
          b := System.covertTextFileToCLiteral(simCode.fileNamePrefix+"_info.json", str+"_info.c", Flags.getConfigString(Flags.TARGET));
          if not b then
            Error.addMessage(Error.INTERNAL_ERROR, {"System.covertTextFileToCLiteral failed. Could not write "+str+"_info.c\n"});
            fail();
          end if;
        else
          // check for _info.json file in resource directory  when --fmiFilter=blackBox is not set
          if Flags.getConfigEnum(Flags.FMI_FILTER) <> Flags.FMI_BLACKBOX then
            if 0 <> System.systemCall("mv '" + simCode.fileNamePrefix + "_info.json"+"' '" + fmutmp+"/resources/" + "'") then
              Error.addInternalError("Failed to move " + simCode.fileNamePrefix + "_info.json file", sourceInfo());
            end if;
          end if;
        end if;
        SimCodeUtil.resetFunctionIndex();
        varInfo := simCode.modelInfo.varInfo;


        install_include_omc_dir := Settings.getInstallationDirectoryPath() + "/include/omc/";
        install_include_omc_c_dir := install_include_omc_dir + "c/";
        install_fmu_sources_dir := Settings.getInstallationDirectoryPath() + RuntimeSources.fmu_sources_dir;
        fmu_tmp_sources_dir := fmutmp + "/sources/";

        // The simrt c headers are in the include/omc/c directory.
        copyFiles(RuntimeSources.simrt_c_headers, source=install_include_omc_c_dir, destination=fmu_tmp_sources_dir);
        // The simrt C source files are installed to the folder specified by RuntimeSources.fmu_sources_dir. Copy them from there.
        copyFiles(RuntimeSources.simrt_c_sources, source=install_fmu_sources_dir, destination=fmu_tmp_sources_dir);

        if varInfo.numLinearSystems > 0 or varInfo.numNonLinearSystems > 0 then
          // The dgesv headers are in the RuntimeSources.fmu_sources_dir for now since they are not properly installed in the include folder
          copyFiles(RuntimeSources.dgesv_headers, source=install_fmu_sources_dir, destination=fmu_tmp_sources_dir);
          copyFiles(RuntimeSources.dgesv_sources, source=install_fmu_sources_dir, destination=fmu_tmp_sources_dir);
          dgesv_sources := RuntimeSources.dgesv_sources;
        else
          dgesv_sources := {};
        end if;

        // Check if the sundials files are needed. Shouldn't this actually check what the flags are
        // instead of just checking if flags are set only?
        if isSome(simCode.fmiSimulationFlags) then
          // The sundials headers are in the include directory.
          copyFiles(RuntimeSources.sundials_headers, source=install_include_omc_dir, destination=fmu_tmp_sources_dir);
          copyFiles(RuntimeSources.simrt_c_sundials_sources, source=install_fmu_sources_dir, destination=fmu_tmp_sources_dir);
          simrt_c_sundials_sources := RuntimeSources.simrt_c_sundials_sources;
        else
          simrt_c_sundials_sources := {};
        end if;


        simrt_linear_solver_sources := if varInfo.numLinearSystems > 0 then RuntimeSources.simrt_linear_solver_sources else {};
        copyFiles(simrt_linear_solver_sources, source=install_fmu_sources_dir, destination=fmu_tmp_sources_dir);

        simrt_non_linear_solver_sources := if varInfo.numNonLinearSystems > 0 then RuntimeSources.simrt_non_linear_solver_sources else {};
        copyFiles(simrt_non_linear_solver_sources, source=install_fmu_sources_dir, destination=fmu_tmp_sources_dir);

        simrt_mixed_solver_sources := if varInfo.numMixedSystems > 0 then RuntimeSources.simrt_mixed_solver_sources else {};
        copyFiles(simrt_mixed_solver_sources, source=install_fmu_sources_dir, destination=fmu_tmp_sources_dir);

        // This fmu export files of OMC are located in a very unexpected place. Right now they are in SimulationRuntime/fmi/export/openmodelica
        // and then then they are installed to include/omc/c/fmi-export for some reason. The source, install, and source fmu location
        // for these files should be made consistent. For now to avoid modifing things a lot they are left as they are and copied here.
        fmi_export_files := if FMUVersion == "1.0" then RuntimeSources.fmi1Files else RuntimeSources.fmi2Files;
        copyFiles(fmi_export_files, source=install_include_omc_c_dir, destination=fmu_tmp_sources_dir);

        System.writeFile(fmutmp+"/sources/isfmi" + (if FMUVersion=="1.0" then "1" else "2"), "");

        model_gen_files := list(simCode.fileNamePrefix + f for f in RuntimeSources.defaultFileSuffixes);
        model_all_gen_files := listAppend(model_gen_files, SimCodeUtil.getFunctionIndex());

        // I need to see some tests failing or something not working to make sense of what to add here
        shared_source_files := List.flatten({RuntimeSources.simrt_c_sources,
                                             // dgesv_sources, // listed separately
                                             // simrt_c_sundials_sources, // listed separately
                                             simrt_linear_solver_sources,
                                             simrt_non_linear_solver_sources,
                                             simrt_mixed_solver_sources
                                            });

        // check for fmiSource=false or --fmiFilter=blackBox
        if not Flags.getConfigBool(Flags.FMI_SOURCES) or Flags.getConfigEnum(Flags.FMI_FILTER) == Flags.FMI_BLACKBOX then
          model_desc_src_files := {}; // set the sourceFiles to empty, to remove the sources in modeldescription.xml
        else
          model_desc_src_files := listAppend(model_all_gen_files, shared_source_files);
        end if;

        Tpl.tplNoret(function CodegenFMU.translateModel(in_a_FMUVersion=FMUVersion, in_a_FMUType=FMUType, in_a_sourceFiles=model_desc_src_files), simCode);

        Tpl.closeFile(Tpl.tplCallWithFailErrorNoArg(function CodegenFMU.fmuMakefile(a_target=Config.simulationCodeTarget(), a_simCode=simCode, a_FMUVersion=FMUVersion, a_sourceFiles=model_all_gen_files, a_runtimeObjectFiles=list(System.stringReplace(f,".c",".o") for f in shared_source_files), a_dgesvObjectFiles=list(System.stringReplace(f,".c",".o") for f in dgesv_sources), a_sundialsObjectFiles=list(System.stringReplace(f,".c",".o") for f in simrt_c_sundials_sources)),
                      txt=Tpl.redirectToFile(Tpl.emptyTxt, simCode.fileNamePrefix+".fmutmp/sources/Makefile.in")));
        Tpl.closeFile(Tpl.tplCallWithFailError(CodegenFMU.settingsfile, simCode,
                      txt=Tpl.redirectToFile(Tpl.emptyTxt, simCode.fileNamePrefix+".fmutmp/sources/omc_simulation_settings.h")));
        /*Temporary generate extra files for omsicpp simcodetarget, additionaly to C-fmu code*/
        if Config.simCodeTarget() ==  "omsicpp" then
         runTpl(func = function CodegenOMSICpp.translateModel(a_simCode=simCode, a_FMUVersion=FMUVersion, a_FMUType=FMUType));
         end if;
      then ();
    case (_,"omsic")
       algorithm
        guid := System.getUUIDStr();
        fileprefix := simCode.fileNamePrefix;

        // create tmp directory for generated files, but first remove the old one!
        if System.directoryExists(simCode.fullPathPrefix) then
          if not System.removeDirectory(simCode.fullPathPrefix) then
            Error.addInternalError("Failed to remove directory: " + simCode.fullPathPrefix, sourceInfo());
            fail();
          end if;
        end if;
        if not System.createDirectory(simCode.fullPathPrefix) then
          Error.addInternalError("Failed to create tmp folder "+simCode.fullPathPrefix, sourceInfo());
          System.fflush();
          fail();
        end if;

        SerializeInitXML.simulationInitFileReturnBool(simCode=simCode, guid=guid);
        SerializeModelInfo.serialize(simCode, Flags.isSet(Flags.INFO_XML_OPERATIONS));

        //runTplWriteFile(func = function CodegenFMU.fmuModelDescriptionFile(in_a_simCode=simCode, in_a_guid=guid, in_a_FMUVersion=FMUVersion, in_a_FMUType=FMUType, in_a_sourceFiles={}), file=simCode.fullPathPrefix+"/"+"modelDescription.xml");
        runTpl(func = function CodegenOMSI_common.generateFMUModelDescriptionFile(a_simCode=simCode, a_guid=guid, a_FMUVersion=FMUVersion, a_FMUType=FMUType, a_sourceFiles={}, a_fileName=simCode.fullPathPrefix+"/"+"modelDescription.xml"));
        runTplWriteFile(func = function CodegenOMSIC.createMakefile(a_simCode=simCode, a_target=Config.simulationCodeTarget(), a_makeflieName=fileprefix+"_FMU.makefile"), file=simCode.fullPathPrefix+"/"+fileprefix+"_FMU.makefile");

        runTplWriteFile(func = function CodegenOMSIC.generateOMSIC(a_simCode=simCode), file=simCode.fullPathPrefix+"/"+fileprefix+"_omsic.c");

        runTpl(func = function CodegenOMSI_common.generateEquationsCode(a_simCode=simCode, a_FileNamePrefix=fileprefix));
      then ();
      /*Temporarily disabled
      case (_,"omsicpp")
       algorithm
        guid := System.getUUIDStr();
        fileprefix := simCode.fileNamePrefix;

        // create tmp directory for generated files, but first remove the old one!
        if System.directoryExists(simCode.fullPathPrefix) then
          if not System.removeDirectory(simCode.fullPathPrefix) then
            Error.addInternalError("Failed to remove directory: " + simCode.fullPathPrefix, sourceInfo());
            fail();
          end if;
        end if;
        if not System.createDirectory(simCode.fullPathPrefix) then
          Error.addInternalError("Failed to create tmp folder "+simCode.fullPathPrefix, sourceInfo());
          System.fflush();
          fail();
        end if;

        SerializeInitXML.simulationInitFileReturnBool(simCode=simCode, guid=guid);
        SerializeModelInfo.serialize(simCode, Flags.isSet(Flags.INFO_XML_OPERATIONS));

        //runTplWriteFile(func = function CodegenFMU.fmuModelDescriptionFile(in_a_simCode=simCode, in_a_guid=guid, in_a_FMUVersion=FMUVersion, in_a_FMUType=FMUType, in_a_sourceFiles={}), file=simCode.fullPathPrefix+"/"+"modelDescription.xml");
        runTpl(func = function CodegenOMSI_common.generateFMUModelDescriptionFile(a_simCode=simCode, a_guid=guid, a_FMUVersion=FMUVersion, a_FMUType=FMUType, a_sourceFiles={}, a_fileName=simCode.fullPathPrefix+"/"+"modelDescription.xml"));
        runTplWriteFile(func = function CodegenOMSIC.createMakefile(a_simCode=simCode, a_target=Config.simulationCodeTarget(), a_makeflieName=fileprefix+"_FMU.makefile"), file=simCode.fullPathPrefix+"/"+fileprefix+"_FMU.makefile");

        runTplWriteFile(func = function CodegenOMSIC.generateOMSIC(a_simCode=simCode), file=simCode.fullPathPrefix+"/"+fileprefix+"_omsic.c");

        runTpl(func = function CodegenOMSI_common.generateEquationsCode(a_simCode=simCode, a_FileNamePrefix=fileprefix));

           runTpl(func = function CodegenOMSICpp.translateModel(a_simCode=simCode, a_FMUVersion=FMUVersion, a_FMUType=FMUType));
      then ();
*/
    case (_,"Cpp")
      equation
        if(Flags.isSet(Flags.HPCOM)) then
          Tpl.tplNoret3(CodegenFMUCppHpcomOld.translateModel, simCode, FMUVersion, FMUType);
        else
          Tpl.tplNoret(function CodegenFMUCppOld.translateModel(in_a_FMUVersion=FMUVersion, in_a_FMUType=FMUType, in_a_sourceFiles={}), simCode);
        end if;
      then ();
    else
      equation
        str = "Unknown FMU template target: " + target;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end match;
  setGlobalRoot(Global.optionSimCode, NONE());
end callTargetTemplatesFMU;


protected function callTargetTemplatesXML
"Generate target code by passing the SimCode data structure to templates."
  input SimCode.SimCode simCode;
  input String target;
algorithm
  Tpl.tplNoret(CodegenXML.translateModel, simCode);
end callTargetTemplatesXML;

public function translateModel "
  Entry point to translate a Modelica model for simulation / FMU / XML.
  Called from other places in the compiler."
  output Boolean success;
  input TranslateModelKind kind;
  input output FCore.Cache cache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  input Absyn.FunctionArgs args=Absyn.emptyFunctionArgs "labels for remove terms";
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String, Values.Value>> resultValues;
protected
  FCore.Cache inCache = cache;
  Boolean generateFunctions = false;
  Real timeSimCode=0.0, timeTemplates=0.0, timeBackend=0.0, timeFrontend=0.0;
  type State = enumeration(frontend, backend, templates, simcode);
  State state = State.frontend;
algorithm
  FlagsUtil.setConfigBool(Flags.BUILDING_MODEL, true);
  (success, outStringLst, outFileDir) :=
  matchcontinue (inEnv, className, inFileNamePrefix, addDummy, inSimSettingsOpt, args)
    local
      String filenameprefix, file_dir, resstr, description, fmuType;
      DAE.DAElist dae, dae1;
      FCore.Graph graph;
      BackendDAE.BackendDAE dlow, dlow_1;
      BackendDAE.Shared shared;
      list<String> libs;
      BackendDAE.BackendDAE initDAE;
      Option<BackendDAE.BackendDAE> initDAE_lambda0;
      Option<BackendDAE.InlineData> inlineData;
      list<BackendDAE.Equation> removedInitialEquationLst;
      Real fsize;
      Option<DAE.DAElist> odae;
      Option<list<String>> strPreOptModules;
      Boolean isFMI2;
      BackendDAE.SymbolicJacobians fmiDer;
      DAE.FunctionTree funcs;
      list<Option<Integer>> allRoots;

    case (graph, _, filenameprefix, _, _, _) algorithm

      // calculate stuff that we need to create SimCode data structure
      System.realtimeTick(ClockIndexes.RT_CLOCK_FRONTEND);
      ExecStat.execStatReset();
      (cache, graph, odae) := CevalScriptBackend.runFrontEnd(cache, graph, className, false);
      ExecStat.execStat("FrontEnd");
      SOME(dae1) := odae;

      if Flags.isSet(Flags.SERIALIZED_SIZE) then
        allRoots := {};
        for i in 1:300 loop
          try
            allRoots := getGlobalRoot(i)::allRoots;
          else
          end try;
        end for;
        serializeNotify(allRoots, "All local+global roots (1:300)");
        serializeNotify(dae1, "FrontEnd DAE");
        serializeNotify((graph,inEnv,cache,inCache), "FCore.Graph + Cache + Old graph + Old cache");
        serializeNotify((SymbolTable.get(),dae1,graph,inEnv,cache,inCache), "Symbol Table, DAE, Graph, OldGraph, Cache, OldCache");
        ExecStat.execStat("Serialize FrontEnd");
      end if;

      timeFrontend := System.realtimeTock(ClockIndexes.RT_CLOCK_FRONTEND);

      System.realtimeTick(ClockIndexes.RT_CLOCK_BACKEND);
      state := State.backend;
      dae := DAEUtil.transformationsBeforeBackend(cache, graph, dae1);
      ExecStat.execStat("Transformations before backend");

      if Flags.isSet(Flags.SERIALIZED_SIZE) then
        serializeNotify(dae, "FrontEnd DAE after transformations");
        serializeNotify((dae,dae1), "FrontEnd DAE before+after transformations");
        ExecStat.execStat("Serialize DAE (2)");
      end if;
      GCExt.free(dae1);
      GCExt.free(odae);
      odae := NONE();
      dae1 := DAE.emptyDae;

      generateFunctions := FlagsUtil.set(Flags.GEN, false);
      // We should not need to lookup constants and classes in the backend,
      // so let's free up the old graph and just make it the initial environment.
      if not Flags.isSet(Flags.BACKEND_KEEP_ENV_GRAPH) then
        (cache,graph) := Builtin.initialGraph(cache);
      end if;

      description := DAEUtil.daeDescription(dae);
      dlow := BackendDAECreate.lower(dae, cache, graph, BackendDAE.EXTRA_INFO(description,filenameprefix));

      GCExt.free(dae);
      dae := DAE.emptyDae;

      if Flags.isSet(Flags.SERIALIZED_SIZE) then
        serializeNotify(dlow, "BackendDAECreate.lower");
        ExecStat.execStat("Serialize dlow");
      end if;

      isFMI2 := match kind
        case TranslateModelKind.FMU(fmuType) then FMI.isFMIVersion20();
        else false;
      end match;
      // FMI 2.0: enable postOptModule to create alias variables for output states
      strPreOptModules := if (isFMI2) then SOME("introduceOutputAliases"::BackendDAEUtil.getPreOptModulesString()) else NONE();

      // FMI 2.0: enable postOptModule "introduceOutputRealDerivatives" to set maxOutputDerivativeOrder = 1
      if (isFMI2 and fmuType == "cs") then
        strPreOptModules := SOME("introduceOutputRealDerivatives":: Util.getOption(strPreOptModules));
      end if;

      //BackendDump.printBackendDAE(dlow);
      (dlow, initDAE, initDAE_lambda0, inlineData, removedInitialEquationLst) := BackendDAEUtil.getSolvedSystem(dlow,inFileNamePrefix,strPreOptModules=strPreOptModules);

      // generate derivatives
      if (isFMI2) and not Flags.isSet(Flags.FMI20_DEPENDENCIES) then
        // activate symolic jacobains for fmi 2.0
        // to provide dependence information and partial derivatives
        (fmiDer, funcs) := SymbolicJacobian.createFMIModelDerivatives(dlow);
        dlow := BackendDAEUtil.setFunctionTree(dlow, funcs);
      else
        fmiDer := {};
      end if;
      timeBackend := System.realtimeTock(ClockIndexes.RT_CLOCK_BACKEND);
      state := State.simcode;

      if Flags.isSet(Flags.SERIALIZED_SIZE) then
        serializeNotify(dlow, "BackendDAE (simulation)");
        serializeNotify(initDAE, "BackendDAE (initialization)");
        serializeNotify(initDAE_lambda0, "BackendDAE (lambda0)");
        serializeNotify((dlow,initDAE,initDAE_lambda0,inlineData,removedInitialEquationLst), "BackendDAE (simulation+initialization+lambda0+inlineData+removedInitialEquationLst)");
        ExecStat.execStat("Serialize solved system");
      end if;

      (libs, file_dir, timeSimCode, timeTemplates) := match kind
        case TranslateModelKind.NORMAL()
          algorithm
            (libs, file_dir, timeSimCode, timeTemplates) := generateModelCode(dlow, initDAE, initDAE_lambda0, inlineData, removedInitialEquationLst, SymbolTable.getAbsyn(), className, filenameprefix, inSimSettingsOpt, args,fmiDer);
          then (libs, file_dir, timeSimCode, timeTemplates);
        case TranslateModelKind.FMU()
          algorithm

            (libs,file_dir,timeSimCode,timeTemplates) := generateModelCodeFMU(dlow, initDAE, initDAE_lambda0, fmiDer, removedInitialEquationLst, SymbolTable.getAbsyn(), className, FMI.getFMIVersionString(), kind.kind, filenameprefix, kind.targetName, inSimSettingsOpt);
          then (libs, file_dir, timeSimCode, timeTemplates);
        case TranslateModelKind.XML()
          algorithm
            (libs, file_dir, timeSimCode, timeTemplates) := generateModelCodeXML(dlow, initDAE, initDAE_lambda0, removedInitialEquationLst, SymbolTable.getAbsyn(), className, filenameprefix, inSimSettingsOpt);
          then (libs, file_dir, timeSimCode, timeTemplates);
        else
          algorithm
            Error.addInternalError("Unknown translateModel kind: " + anyString(kind), sourceInfo());
          then fail();
      end match;
    then (true, libs, file_dir);

    else
      algorithm
        _ := match kind
          case TranslateModelKind.NORMAL()
            algorithm
              if Flags.isSet(Flags.FAILTRACE) then
                resstr := AbsynUtil.pathStringNoQual(className);
                resstr := stringAppendList({"SimCode: The model ", resstr, " could not be translated"});
                Error.addMessage(Error.INTERNAL_ERROR, {resstr});
              end if;
            then ();
          case TranslateModelKind.XML()
            algorithm
              Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + ": The model ",AbsynUtil.pathStringNoQual(className)," could not be translated to XML"});
            then ();
        end match;
        if state==State.frontend then
          timeFrontend := System.realtimeTock(ClockIndexes.RT_CLOCK_FRONTEND);
        elseif state==State.backend then
          timeBackend := System.realtimeTock(ClockIndexes.RT_CLOCK_BACKEND);
        elseif state==State.simcode then
          timeSimCode := System.realtimeTock(ClockIndexes.RT_CLOCK_SIMCODE);
        else
          timeTemplates := System.realtimeTock(ClockIndexes.RT_CLOCK_TEMPLATES);
        end if;
      then (false, {}, "");
  end matchcontinue;
  if generateFunctions then
    FlagsUtil.set(Flags.GEN, true);
  end if;
  resultValues := {("timeTemplates", Values.REAL(timeTemplates)),
                  ("timeSimCode", Values.REAL(timeSimCode)),
                  ("timeBackend", Values.REAL(timeBackend)),
                  ("timeFrontend", Values.REAL(timeFrontend))};
  FlagsUtil.setConfigBool(Flags.BUILDING_MODEL, false);
end translateModel;

public function translateModelDAEMode
" Entry point to translate a Modelica model for simulation in DAE mode
  Called from CevalScriptBackend"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input String inFileNamePrefix;
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  input Absyn.FunctionArgs args "labels for remove terms";
  output FCore.Cache outCache;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String, Values.Value>> resultValues;
protected
  Boolean generateFunctions = false;
algorithm
  (outStringLst, outFileDir, resultValues) :=
  matchcontinue (inCache, inEnv, className, inFileNamePrefix, inSimSettingsOpt, args)
    local
      String filenameprefix = inFileNamePrefix;
      String file_dir, resstr, description;
      DAE.DAElist dae;
      FCore.Graph graph;
      BackendDAE.BackendDAE dlow, bdae;
      list<String> libs;
      Absyn.Program p;
      //DAE.Exp fileprefix;
      FCore.Cache cache;
      Real timeSimCode, timeTemplates, timeBackend, timeFrontend;
      BackendDAE.BackendDAE initDAE;
      list<BackendDAE.Equation> removedInitialEquationLst;
      Option<BackendDAE.BackendDAE> initDAE_lambda0_option;
      Real fsize;
      Absyn.ComponentRef classNameCref;

    case (_, _, _, _, _, _) algorithm
      // calculate stuff that we need to create SimCode data structure
      System.realtimeTick(ClockIndexes.RT_CLOCK_FRONTEND);
      ExecStat.execStatReset();
      (outCache, graph, SOME(dae), _) := CevalScriptBackend.runFrontEnd(inCache, inEnv, className, false);
      ExecStat.execStat("FrontEnd");

      if Flags.isSet(Flags.SERIALIZED_SIZE) then
        serializeNotify(dae, "dae");
        serializeNotify(graph, "graph");
        serializeNotify(outCache, "cache");
        ExecStat.execStat("Serialize FrontEnd");
      end if;

      timeFrontend := System.realtimeTock(ClockIndexes.RT_CLOCK_FRONTEND);

      System.realtimeTick(ClockIndexes.RT_CLOCK_BACKEND);
      dae := DAEUtil.transformationsBeforeBackend(outCache, graph, dae);
      ExecStat.execStat("Transformations before backend");

      if Flags.isSet(Flags.SERIALIZED_SIZE) then
        serializeNotify(dae, "dae2");
        ExecStat.execStat("Serialize DAE (2)");
      end if;

      generateFunctions := FlagsUtil.set(Flags.GEN, false);
      // We should not need to lookup constants and classes in the backend,
      // so let's free up the old graph and just make it the initial environment.
      if not Flags.isSet(Flags.BACKEND_KEEP_ENV_GRAPH) then
        (outCache,graph) := Builtin.initialGraph(outCache);
      end if;

      description := DAEUtil.daeDescription(dae);
      dlow := BackendDAECreate.lower(dae, outCache, graph, BackendDAE.EXTRA_INFO(description,filenameprefix));

      GCExt.free(dae);

      if Flags.isSet(Flags.SERIALIZED_SIZE) then
        serializeNotify(dlow, "dlow");
        ExecStat.execStat("Serialize dlow");
      end if;

      //BackendDump.printBackendDAE(dlow);
      (bdae, initDAE, initDAE_lambda0_option, removedInitialEquationLst) := DAEMode.getEqSystemDAEmode(dlow, inFileNamePrefix);
      ExecStat.execStat("Backend");

      timeBackend := System.realtimeTock(ClockIndexes.RT_CLOCK_BACKEND);

      if Flags.isSet(Flags.SERIALIZED_SIZE) then
        serializeNotify(bdae, "simDAE");
        serializeNotify(initDAE, "initDAE");
        serializeNotify(removedInitialEquationLst, "removedInitialEquationLst");
        ExecStat.execStat("Serialize solved system");
      end if;

      (libs, file_dir, timeSimCode, timeTemplates) := generateModelCodeDAE(bdae, initDAE, initDAE_lambda0_option, removedInitialEquationLst, SymbolTable.getAbsyn(), className, filenameprefix, inSimSettingsOpt, args);
      timeSimCode := System.realtimeTock(ClockIndexes.RT_CLOCK_SIMCODE);
      timeTemplates := System.realtimeTock(ClockIndexes.RT_CLOCK_TEMPLATES);

      resultValues := {("timeTemplates", Values.REAL(timeTemplates)),
                      ("timeSimCode", Values.REAL(timeSimCode)),
                      ("timeBackend", Values.REAL(timeBackend)),
                      ("timeFrontend", Values.REAL(timeFrontend))};



    then (libs, file_dir, resultValues);

    else equation
      if generateFunctions then
        FlagsUtil.set(Flags.GEN, true);
      end if;
      true = Flags.isSet(Flags.FAILTRACE);
      resstr = AbsynUtil.pathStringNoQual(className);
      resstr = stringAppendList({"SimCode DAEmode: The model ", resstr, " could not be translated"});
      Error.addMessage(Error.INTERNAL_ERROR, {resstr});
    then fail();
  end matchcontinue;
  if generateFunctions then
    FlagsUtil.set(Flags.GEN, true);
  end if;
end translateModelDAEMode;

protected function generateModelCodeDAE
" Generates code for a model by creating a SimCode structure for the DAEmode
  and call the template target generator. "
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.BackendDAE inInitDAE;
  input Option<BackendDAE.BackendDAE> initDAE_lambda0_option;
  input list<BackendDAE.Equation> inRemovedInitialEquationLst;
  input Absyn.Program p;
  input Absyn.Path className;
  input String filenamePrefix;
  input Option<SimCode.SimulationSettings> simSettingsOpt;
  input Absyn.FunctionArgs args;
  output list<String> libs;
  output String fileDir;
  output Real timeSimCode;
  output Real timeTemplates;
protected
  constant Boolean debug = false;
  list<String> includes, includeDirs,libPaths;
  list<SimCodeFunction.Function> functions;
  SimCode.SimCode simCode;
  list<SimCodeFunction.RecordDeclaration> recordDecls;
  Absyn.ComponentRef a_cref;
  tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> literals;
  list<DAE.Exp> lits;
  list<tuple<String, String>> program;
  Integer numCheckpoints;
  list<SimCodeVar.SimVar> tempVars = {};
  BackendDAE.BackendDAE emptyBDAE;
  BackendDAE.BackendDAE initDAE_lambda0;

  SimCode.ModelInfo modelInfo;
  SimCode.ExtObjInfo extObjInfo;
  SimCode.HashTableCrefToSimVar crefToSimVarHT;
  SimCodeFunction.MakefileParams makefileParams;
  SimCode.SpatialDistributionInfo spatialInfo;
  list<tuple<Integer, tuple<DAE.Exp, DAE.Exp, DAE.Exp>>> delayedExps;
  Integer maxDelayedExpIndex;
  Integer uniqueEqIndex = 1;
  Integer nStates;
  Integer numberofEqns, numberofLinearSys, numberofNonLinearSys,
  numberofMixedSys, numberOfJacobians, numberofFixedParameters;
  Boolean tmpB;

  list<DAE.ComponentRef> discreteModelVars;
  list<BackendDAE.TimeEvent> timeEvents;
  BackendDAE.ZeroCrossingSet zeroCrossingsSet, sampleZCSet;
  DoubleEnded.MutableList<BackendDAE.ZeroCrossing> de_relations;
  list<BackendDAE.ZeroCrossing> zeroCrossings, sampleZC, relations;

  BackendDAE.Variables daeVars, resVars, algStateVars, auxVars;
  list<BackendDAE.Var> varsLst;
  list<BackendDAE.Equation> eqnsLst;
  BackendDAE.EquationArray daeEqns;
  BackendDAE.Variables localSharedAlgVars;
  Option<SimCode.JacobianMatrix> daeModeSP;
  Option<SimCode.DaeModeData> daeModeData;
  SimCode.DaeModeConfig daeModeConf;
  list<String> matrixnames;
  list<list<SimCode.SimEqSystem>> daeEquations;
  list<SimCodeVar.SimVar> residualVars, algebraicStateVars, auxiliaryVars;

  tuple<Option<BackendDAE.SymbolicJacobian>, BackendDAE.SparsePattern, BackendDAE.SparseColoring> daeModeJac;
  SimCode.JacobianMatrix symDAESparsPattern;
  list<SimCode.JacobianMatrix> symJacs, SymbolicJacs, SymbolicJacsNLS, SymbolicJacsTemp, SymbolicJacsStateSelect;
  list<SimCode.SimEqSystem> initialEquations;
  list<SimCode.SimEqSystem> initialEquations_lambda0;
  list<SimCode.SimEqSystem> removedInitialEquations, jacobianEquations;
  list<SimCodeVar.SimVar> jacobianSimvars, seedVars;
  list<SimCode.SimEqSystem> startValueEquations;        // --> updateBoundStartValues
  list<SimCode.SimEqSystem> maxValueEquations;          // --> updateBoundMaxValues
  list<SimCode.SimEqSystem> minValueEquations;          // --> updateBoundMinValues
  list<SimCode.SimEqSystem> nominalValueEquations;      // --> updateBoundNominalValues
  list<SimCode.SimEqSystem> parameterEquations;         // --> updateBoundParameters
algorithm
  numCheckpoints:=ErrorExt.getNumCheckpoints();
  try
    StackOverflow.clearStacktraceMessages();
    System.realtimeTick(ClockIndexes.RT_CLOCK_SIMCODE);

    // +++ create SimCode stuff +++
    // create SimCode functions
    a_cref := AbsynUtil.pathToCref(className);
    fileDir := CevalScriptBackend.getFileDir(a_cref, p);
    (libs, libPaths, includes, includeDirs, recordDecls, functions, literals) := SimCodeUtil.createFunctions(p, inBackendDAE.shared.functionTree);

    // create external objects
    extObjInfo := SimCodeUtil.createExtObjInfo(inBackendDAE.shared);
    // create make file params
    makefileParams := SimCodeFunctionUtil.createMakefileParams(includeDirs, libs, libPaths, false, false);
    //create delay exps
    (delayedExps, maxDelayedExpIndex) := SimCodeUtil.extractDelayedExpressions(inBackendDAE);
    spatialInfo := SimCodeUtil.extractSpatialDistributionInfo(inBackendDAE);

    // created event suff e.g. zeroCrossings, samples, ...
    timeEvents := inBackendDAE.shared.eventInfo.timeEvents;
    (zeroCrossings,relations,sampleZC) := match inBackendDAE.shared.eventInfo
      case BackendDAE.EVENT_INFO(zeroCrossings=zeroCrossingsSet, relations=de_relations, samples=sampleZCSet)
      then (ZeroCrossings.toList(zeroCrossingsSet), DoubleEnded.toListNoCopyNoClear(de_relations), ZeroCrossings.toList(sampleZCSet));
    end match;

    // initialization stuff
    // ********************

    // generate equations for initDAE
    (initialEquations, uniqueEqIndex, tempVars) := SimCodeUtil.createInitialEquations(inInitDAE, uniqueEqIndex, tempVars);

    // generate equations for initDAE_lambda0
    if isSome(initDAE_lambda0_option) then
      SOME(initDAE_lambda0) := initDAE_lambda0_option;
      (initialEquations_lambda0, uniqueEqIndex, tempVars) := SimCodeUtil.createInitialEquations_lambda0(initDAE_lambda0, uniqueEqIndex, tempVars);
    else
      initialEquations_lambda0 := {};
    end if;

    // generate equations for removed initial equations
    (removedInitialEquations, uniqueEqIndex, tempVars) := SimCodeUtil.createNonlinearResidualEquations(inRemovedInitialEquationLst, uniqueEqIndex, tempVars, inBackendDAE.shared.functionTree);
    //removedInitialEquations := listReverse(removedInitialEquations);

    ExecStat.execStat("simCode: created initialization part");

    // create parameter equations
    ((uniqueEqIndex, startValueEquations, _)) := BackendDAEUtil.foldEqSystem(inInitDAE, SimCodeUtil.createStartValueEquations, (uniqueEqIndex, {}, inBackendDAE.shared.globalKnownVars));
    if debug then ExecStat.execStat("simCode: createStartValueEquations"); end if;
    ((uniqueEqIndex, nominalValueEquations)) := BackendDAEUtil.foldEqSystem(inBackendDAE, SimCodeUtil.createNominalValueEquations, (uniqueEqIndex, {}));
    if debug then ExecStat.execStat("simCode: createNominalValueEquations"); end if;
    ((uniqueEqIndex, minValueEquations)) := BackendDAEUtil.foldEqSystem(inBackendDAE, SimCodeUtil.createMinValueEquations, (uniqueEqIndex, {}));
    if debug then ExecStat.execStat("simCode: createMinValueEquations"); end if;
    ((uniqueEqIndex, maxValueEquations)) := BackendDAEUtil.foldEqSystem(inBackendDAE, SimCodeUtil.createMaxValueEquations, (uniqueEqIndex, {}));
    if debug then ExecStat.execStat("simCode: createMaxValueEquations"); end if;
    ((uniqueEqIndex, parameterEquations)) := BackendDAEUtil.foldEqSystem(inBackendDAE, SimCodeUtil.createVarNominalAssertFromVars, (uniqueEqIndex, {}));
    if debug then ExecStat.execStat("simCode: createVarNominalAssertFromVars"); end if;
    (uniqueEqIndex, parameterEquations, _) := SimCodeUtil.createParameterEquations(uniqueEqIndex, parameterEquations, inBackendDAE.shared.globalKnownVars);
    if debug then ExecStat.execStat("simCode: createParameterEquations"); end if;

    discreteModelVars := BackendDAEUtil.foldEqSystem(inBackendDAE, SimCodeUtil.extractDiscreteModelVars, {});

    // create DAEmode equations
    (daeEquations, uniqueEqIndex, tempVars) := SimCodeUtil.createEquationsfromBackendDAE(inBackendDAE, uniqueEqIndex, tempVars, true, true);

    // create model info
    // create dummy system where all original variables are created
    emptyBDAE := BackendDAE.DAE(BackendDAEUtil.createEqSystem(
                                  Util.getOption(inBackendDAE.shared.daeModeData.modelVars))::{},
                                inBackendDAE.shared);
    // disable start value calculation, it's only helpful in case of algebraic loops
    // and they are not present in DAEmode
    tmpB := FlagsUtil.set(Flags.NO_START_CALC, true);
    modelInfo := SimCodeUtil.createModelInfo(className, p, emptyBDAE, inInitDAE, functions, {}, 0, spatialInfo.maxIndex, fileDir, 0, tempVars);
    FlagsUtil.set(Flags.NO_START_CALC, tmpB);

    //create hash table
    crefToSimVarHT := SimCodeUtil.createCrefToSimVarHT(modelInfo);

    // collect symbolic jacobians in initialization loops of the overall jacobians
    SymbolicJacsNLS := {};
    (initialEquations, modelInfo, SymbolicJacsTemp) := SimCodeUtil.addAlgebraicLoopsModelInfo(initialEquations, modelInfo);
    SymbolicJacsNLS := listAppend(SymbolicJacsTemp, SymbolicJacsNLS);
    (initialEquations_lambda0, modelInfo, SymbolicJacsTemp) := SimCodeUtil.addAlgebraicLoopsModelInfo(initialEquations_lambda0, modelInfo);
    SymbolicJacsNLS := listAppend(SymbolicJacsTemp, SymbolicJacsNLS);
    (parameterEquations, modelInfo, SymbolicJacsTemp) := SimCodeUtil.addAlgebraicLoopsModelInfo(parameterEquations, modelInfo);
    SymbolicJacsNLS := listAppend(SymbolicJacsTemp, SymbolicJacsNLS);
    // check for datareconciliation is present and pass the matrixnames
    if Util.isSome(inBackendDAE.shared.dataReconciliationData) then
      matrixnames := {"A", "B", "C", "D"};
    else
      matrixnames := {"A", "B", "C", "D", "F"};
    end if;
    (symJacs, uniqueEqIndex) := SimCodeUtil.createSymbolicJacobianssSimCode({}, crefToSimVarHT, uniqueEqIndex, matrixnames, {});
    (SymbolicJacs, modelInfo, SymbolicJacsTemp) := SimCodeUtil.addAlgebraicLoopsModelInfoSymJacs(symJacs, modelInfo);

    // collect jacobian equation only for equantion info file
    jacobianEquations := SimCodeUtil.collectAllJacobianEquations(SymbolicJacs);
    if debug then ExecStat.execStat("simCode: create Jacobian linear code"); end if;

    SymbolicJacs := listAppend(listReverse(SymbolicJacsNLS), listAppend(SymbolicJacs, SymbolicJacsTemp));
    jacobianSimvars := SimCodeUtil.collectAllJacobianVars(SymbolicJacs);
    modelInfo := SimCodeUtil.setJacobianVars(jacobianSimvars, modelInfo);
    seedVars := SimCodeUtil.collectAllSeedVars(SymbolicJacs);
    modelInfo := SimCodeUtil.setSeedVars(seedVars, modelInfo);

    // create dae SimVars: residual and algebraic
    varsLst := BackendVariable.equationSystemsVarsLst(inBackendDAE.eqs);
    daeVars := BackendVariable.listVar(varsLst);

    // create residual variables, set index and push them SimCode HashTable
    ((_, resVars)) := BackendVariable.traverseBackendDAEVars(daeVars, BackendVariable.collectVarKindVarinVariables, (BackendVariable.isDAEmodeResVar, BackendVariable.emptyVars()));
    ((residualVars, _)) :=  BackendVariable.traverseBackendDAEVars(resVars, SimCodeUtil.traversingdlowvarToSimvar, ({}, BackendVariable.emptyVars()));
    residualVars := SimCodeUtil.rewriteIndex(residualVars, 0);
    (residualVars, _) := SimCodeUtil.setVariableIndexHelper(residualVars, 0, 0);
    crefToSimVarHT:= List.fold(residualVars,HashTableCrefSimVar.addSimVarToHashTable,crefToSimVarHT);

    // create auxiliary variables, set index and push them SimCode Hash Table
    ((_, auxVars)) := BackendVariable.traverseBackendDAEVars(daeVars, BackendVariable.collectVarKindVarinVariables, (BackendVariable.isDAEmodeAuxVar, BackendVariable.emptyVars()));
    ((auxiliaryVars, _)) :=  BackendVariable.traverseBackendDAEVars(auxVars, SimCodeUtil.traversingdlowvarToSimvar, ({}, BackendVariable.emptyVars()));
    auxiliaryVars := List.sort(auxiliaryVars, SimCodeUtil.simVarCompareByCrefSubsAtEndlLexical);
    auxiliaryVars := SimCodeUtil.rewriteIndex(auxiliaryVars, 0);
    (auxiliaryVars, _) := SimCodeUtil.setVariableIndexHelper(auxiliaryVars, 0, 0);
    crefToSimVarHT:= List.fold(auxiliaryVars,HashTableCrefSimVar.addSimVarToHashTable,crefToSimVarHT);

    // create SimCodeVars for algebraic states
    algStateVars := BackendVariable.listVar(inBackendDAE.shared.daeModeData.algStateVars);
    ((algebraicStateVars, _)) :=  BackendVariable.traverseBackendDAEVars(algStateVars, SimCodeUtil.traversingdlowvarToSimvar, ({}, BackendVariable.emptyVars()));

    algebraicStateVars := SimCodeUtil.sortSimVarsAndWriteIndex(algebraicStateVars, crefToSimVarHT);

    /* This lines seem to be not neccsary and actually problematic.
       The algebraicStateVars are already in the simvars. Which means they are already addded
       to the hastable somewhere above. Here we try to add them again but with wrong indexs because
       setVariableIndexHelper does not actually update the indices we want. If you want to enable this
      for some reason use rewriteIndex.
    */
    // SimCode.VARINFO(numStateVars=nStates) := modelInfo.varInfo;
    // // (algebraicStateVars, _) := SimCodeUtil.setVariableIndexHelper(algebraicStateVars, 2*nStates);
    // (algebraicStateVars, _) := SimCodeUtil.rewriteIndex(algebraicStateVars, 2*nStates);
    // crefToSimVarHT:= List.fold(algebraicStateVars,HashTableCrefSimVar.addSimVarToHashTable,crefToSimVarHT);

    // create DAE mode Sparse pattern and TODO: Jacobians
    // sparsity pattern generation
    daeModeJac := listGet(inBackendDAE.shared.symjacs, BackendDAE.SymbolicJacobianAIndex);
    ({symDAESparsPattern}, uniqueEqIndex) := SimCodeUtil.createSymbolicJacobianssSimCode({daeModeJac}, crefToSimVarHT, uniqueEqIndex, {"daeMode"}, {});
    daeModeSP := SOME(symDAESparsPattern);
    daeModeConf := SimCode.ALL_EQUATIONS();
    daeModeData := SOME(SimCode.DAEMODEDATA(daeEquations, daeModeSP, residualVars, algebraicStateVars, auxiliaryVars, daeModeConf));

    /* This is a *much* better estimate than the guessed number of equations */
    modelInfo := SimCodeUtil.addNumEqns(modelInfo, uniqueEqIndex-listLength(jacobianEquations));

    // update hash table
    // mahge: This creates a new crefToSimVarHT discarding everything added upto here
    // The updated variable 'numEquations' (by SimCodeUtil.addNumEqns) is not even used in createCrefToSimVarHT :/
    // crefToSimVarHT := SimCodeUtil.createCrefToSimVarHT(modelInfo);

    simCode := SimCode.SIMCODE(
      modelInfo                   = modelInfo,
      literals                    = {},               // Set by the traversal below...
      recordDecls                 = recordDecls,
      externalFunctionIncludes    = includes,
      localKnownVars              = {},
      allEquations                = {},
      odeEquations                = {},
      algebraicEquations          = {},
      clockedPartitions           = {},
      initialEquations            = initialEquations,
      initialEquations_lambda0    = initialEquations_lambda0,
      removedInitialEquations     = removedInitialEquations,
      startValueEquations         = startValueEquations,
      nominalValueEquations       = nominalValueEquations,
      minValueEquations           = minValueEquations,
      maxValueEquations           = maxValueEquations,
      parameterEquations          = parameterEquations,
      removedEquations            = {},
      algorithmAndEquationAsserts = {},
      equationsForZeroCrossings   = {},
      jacobianEquations           = {},
      stateSets                   = {},
      constraints                 = {},
      classAttributes             = {},
      zeroCrossings               = zeroCrossings,
      relations                   = relations,
      timeEvents                  = timeEvents,
      discreteModelVars           = discreteModelVars,
      extObjInfo                  = extObjInfo,
      makefileParams              = makefileParams,
      delayedExps                 = SimCode.DELAYED_EXPRESSIONS(delayedExps, maxDelayedExpIndex),
      spatialInfo                 = spatialInfo,
      jacobianMatrixes            = SymbolicJacs,
      simulationSettingsOpt       = simSettingsOpt,
      fileNamePrefix              = filenamePrefix,
      fullPathPrefix              = "",
      fmuTargetName               = "",
      hpcomData                   = HpcOmSimCode.emptyHpcomData,
      valueReferences             = AvlTreeCRToInt.EMPTY(),
      varToArrayIndexMapping      = HashTableCrIListArray.emptyHashTable(),
      varToIndexMapping           = HashTableCrILst.emptyHashTable(),
      crefToSimVarHT              = crefToSimVarHT,
      crefToClockIndexHT          = HashTable.emptyHashTable(),
      backendMapping              = NONE(),
      modelStructure              = NONE(),
      fmiSimulationFlags          = NONE(),
      partitionData               = SimCode.emptyPartitionData,
      daeModeData                 = daeModeData,
      inlineEquations             = {},
      omsiData                    = NONE()
    );

    (simCode, (_, _, lits)) := SimCodeUtil.traverseExpsSimCode(simCode, SimCodeFunctionUtil.findLiteralsHelper, literals);
    simCode.literals := listReverse(lits);

    timeSimCode := System.realtimeTock(ClockIndexes.RT_CLOCK_SIMCODE);
    ExecStat.execStat("SimCode");

    if Flags.isSet(Flags.SERIALIZED_SIZE) then
      serializeNotify(simCode, "SimCode");
      ExecStat.execStat("Serialize simCode");
    end if;

    if Flags.isSet(Flags.DUMP_SIMCODE) then
      SimCodeUtil.dumpSimCodeDebug(simCode);
    end if;

    System.realtimeTick(ClockIndexes.RT_CLOCK_TEMPLATES);
    callTargetTemplates(simCode, Config.simCodeTarget());
    timeTemplates := System.realtimeTock(ClockIndexes.RT_CLOCK_TEMPLATES);
    ExecStat.execStat("Templates");
    return;
  else
    setGlobalRoot(Global.stackoverFlowIndex, NONE());
    ErrorExt.rollbackNumCheckpoints(ErrorExt.getNumCheckpoints()-numCheckpoints);
    Error.addInternalError("Stack overflow in "+getInstanceName()+"...\n"+stringDelimitList(StackOverflow.readableStacktraceMessages(), "\n"), sourceInfo());
    /* Do not fail or we can loop too much */
    StackOverflow.clearStacktraceMessages();
  end try annotation(__OpenModelica_stackOverflowCheckpoint=true);
  fail();
end generateModelCodeDAE;

protected function serializeNotify<T>
  input T data;
  input String name;
protected
  Real sz,raw_sz,nonSharedStringSize;
algorithm
  (sz,raw_sz,nonSharedStringSize) := System.getSizeOfData(data);
  Error.addMessage(Error.SERIALIZED_SIZE, {name, StringUtil.bytesToReadableUnit(sz), StringUtil.bytesToReadableUnit(raw_sz), StringUtil.bytesToReadableUnit(nonSharedStringSize)});
end serializeNotify;

protected function copyFiles
  input list<String> files;
  input String source, destination;
protected
  String f2, d2;
algorithm
  for f in files loop
    f2 := destination+"/"+f;
    d2 := System.dirname(f2);
    if not System.directoryExists(d2) then
      Error.assertion(Util.createDirectoryTree(d2), "Failed to create directory " + d2, sourceInfo());
    end if;
    Error.assertion(System.copyFile(source + "/" + f, f2), "Failed to copy file " + f + " from " + source + " to " + destination, sourceInfo());
  end for;
end copyFiles;

annotation(__OpenModelica_Interface="backend");
end SimCodeMain;
