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
  translateFunctions fuction.

  RCS: $Id$"

// public imports
public
import Absyn;
import BackendDAE;
import BackendDAEUtil;
import Ceval;
import DAE;
import FCore;
import GlobalScript;
import HashTableExpToIndex;
import Tpl;
import Values;
import SimCode;

// protected imports
protected
import BackendDAECreate;
import ClockIndexes;
import CevalScriptBackend;
import CodegenC;
import CodegenFMU;
import CodegenFMUCpp;
import CodegenFMUCppHpcom;
import CodegenAdevs;
import CodegenSparseFMI;
import CodegenCSharp;
import CodegenCpp;
import CodegenCppHpcom;
import CodegenXML;
import CodegenJava;
import CodegenJS;
import Config;
import DAEUtil;
import Debug;
import Error;
import Flags;
import FMI;
import HpcOmSimCodeMain;
import HpcOmTaskGraph;
import SerializeModelInfo;
import SimCodeDump;
import TaskSystemDump;
import SimCodeUtil;
import System;
import Util;
import BackendDump;

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
  input Boolean inUseHomotopy "true if homotopy(...) is used during initialization";
  input list<BackendDAE.Equation> inRemovedInitialEquationLst;
  input list<BackendDAE.Var> inPrimaryParameters "already sorted";
  input list<BackendDAE.Var> inAllPrimaryParameters "already sorted";
  input Absyn.Program p;
  input Absyn.Path className;
  input String FMUVersion;
  input String FMUType;
  input String filenamePrefix;
  input Option<SimCode.SimulationSettings> simSettingsOpt;
  output list<String> libs;
  output String fileDir;
  output Real timeSimCode;
  output Real timeTemplates;
protected
  list<String> includes,includeDirs;
  list<SimCode.Function> functions;
  String filename, funcfilename;
  SimCode.SimCode simCode;
  list<SimCode.RecordDeclaration> recordDecls;
  BackendDAE.BackendDAE indexed_dlow,indexed_dlow_1;
  Absyn.ComponentRef a_cref;
  list<String> libPaths;
  tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>> literals;
algorithm
  System.realtimeTick(ClockIndexes.RT_CLOCK_SIMCODE);
  a_cref := Absyn.pathToCref(className);
  fileDir := CevalScriptBackend.getFileDir(a_cref, p);
  (libs,libPaths,includes, includeDirs, recordDecls, functions, literals) :=
    SimCodeUtil.createFunctions(p, inBackendDAE);
  simCode := createSimCode(inBackendDAE, inInitDAE, inUseHomotopy, inRemovedInitialEquationLst, inPrimaryParameters, inAllPrimaryParameters,
    className, filenamePrefix, fileDir, functions, includes, includeDirs, libs, libPaths, simSettingsOpt, recordDecls, literals, Absyn.FUNCTIONARGS({},{}), isFMU=true);
  timeSimCode := System.realtimeTock(ClockIndexes.RT_CLOCK_SIMCODE);
  SimCodeFunctionUtil.execStat("SimCode");

  System.realtimeTick(ClockIndexes.RT_CLOCK_TEMPLATES);
  callTargetTemplatesFMU(simCode, Config.simCodeTarget(), FMUVersion, FMUType);
  timeTemplates := System.realtimeTock(ClockIndexes.RT_CLOCK_TEMPLATES);
end generateModelCodeFMU;


protected function generateModelCodeXML "
  Generates code for a model by creating a SimCode structure and calling the
  template-based code generator on it."
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.BackendDAE inInitDAE;
  input Boolean inUseHomotopy "true if homotopy(...) is used during initialization";
  input list<BackendDAE.Equation> inRemovedInitialEquationLst;
  input list<BackendDAE.Var> inPrimaryParameters "already sorted";
  input list<BackendDAE.Var> inAllPrimaryParameters "already sorted";
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
  list<SimCode.Function> functions;
  String filename, funcfilename;
  SimCode.SimCode simCode;
  list<SimCode.RecordDeclaration> recordDecls;
  BackendDAE.BackendDAE indexed_dlow,indexed_dlow_1;
  list<String> libPaths;
  Absyn.ComponentRef a_cref;
  tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>> literals;
algorithm
  System.realtimeTick(ClockIndexes.RT_CLOCK_SIMCODE);
  a_cref := Absyn.pathToCref(className);
  fileDir := CevalScriptBackend.getFileDir(a_cref, p);
  (libs, libPaths, includes, includeDirs, recordDecls, functions, literals) :=
    SimCodeUtil.createFunctions(p, inBackendDAE);
  (simCode,_) := SimCodeUtil.createSimCode(inBackendDAE, inInitDAE, inUseHomotopy, inRemovedInitialEquationLst, inPrimaryParameters, inAllPrimaryParameters,
    className, filenamePrefix, fileDir, functions, includes, includeDirs, libs,libPaths, simSettingsOpt, recordDecls, literals,Absyn.FUNCTIONARGS({},{}));
  timeSimCode := System.realtimeTock(ClockIndexes.RT_CLOCK_SIMCODE);
  SimCodeFunctionUtil.execStat("SimCode");

  System.realtimeTick(ClockIndexes.RT_CLOCK_TEMPLATES);
  callTargetTemplatesXML(simCode, Config.simCodeTarget());
  timeTemplates := System.realtimeTock(ClockIndexes.RT_CLOCK_TEMPLATES);
end generateModelCodeXML;


public function translateModelFMU
"Entry point to translate a Modelica model for FMU export.

 Called from other places in the compiler."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input String inFMUVersion;
  input String inFMUType;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output FCore.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  (outCache,outValue,outInteractiveSymbolTable,outBackendDAE,outStringLst,outFileDir,resultValues):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inFMUVersion,inFMUType,inFileNamePrefix,addDummy,inSimSettingsOpt)
    local
      String FMUVersion,FMUType,filenameprefix,file_dir,resstr;
      DAE.DAElist dae;
      FCore.Graph graph;
      BackendDAE.BackendDAE dlow,dlow_1;
      list<String> libs;
      GlobalScript.SymbolTable st;
      Absyn.Program p;
      //DAE.Exp fileprefix;
      FCore.Cache cache;
      DAE.FunctionTree funcs;
      Real timeSimCode, timeTemplates, timeBackend, timeFrontend;
      String description;
      Boolean symbolicJacActivated;
      Boolean fmi20;
      Boolean flagValue;
      BackendDAE.BackendDAE initDAE;
      Boolean useHomotopy "true if homotopy(...) is used during initialization";
      list<BackendDAE.Equation> removedInitialEquationLst;
      list<BackendDAE.Var> primaryParameters "already sorted";
      list<BackendDAE.Var> allPrimaryParameters "already sorted";

    case (cache,graph,_,st as GlobalScript.SYMBOLTABLE(ast=p),FMUVersion,FMUType,filenameprefix,_, _)
      equation
        /* calculate stuff that we need to create SimCode data structure */
        System.realtimeTick(ClockIndexes.RT_CLOCK_FRONTEND);
        //(cache,Values.STRING(filenameprefix),SOME(_)) = Ceval.ceval(cache,graph, fileprefix, true, SOME(st),NONE(), msg);
        (cache,graph,dae,st) = CevalScriptBackend.runFrontEnd(cache,graph,className,st,false);
        timeFrontend = System.realtimeTock(ClockIndexes.RT_CLOCK_FRONTEND);
        System.realtimeTick(ClockIndexes.RT_CLOCK_BACKEND);

        // activate symolic jacobains for fmi 2.0
        // to provide dependence information and partial derivatives
        fmi20 = FMI.isFMIVersion20(FMUVersion);
        symbolicJacActivated = Flags.getConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION);
        Flags.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION, fmi20);
        if not Flags.isSet(Flags.FMU_EXPERIMENTAL) then
            flagValue = Flags.enableDebug(Flags.DIS_SYMJAC_FMI20);
        end if;

        _ = FCore.getFunctionTree(cache);
        dae = DAEUtil.transformationsBeforeBackend(cache,graph,dae);
        description = DAEUtil.daeDescription(dae);
        dlow = BackendDAECreate.lower(dae, cache, graph, BackendDAE.EXTRA_INFO(description,filenameprefix));
        (dlow_1, initDAE, useHomotopy, removedInitialEquationLst, primaryParameters, allPrimaryParameters) = BackendDAEUtil.getSolvedSystem(dlow, inFileNamePrefix);
        timeBackend = System.realtimeTock(ClockIndexes.RT_CLOCK_BACKEND);

        (libs,file_dir,timeSimCode,timeTemplates) =
          generateModelCodeFMU(dlow_1, initDAE, useHomotopy, removedInitialEquationLst, primaryParameters, allPrimaryParameters, p, className, FMUVersion, FMUType, filenameprefix, inSimSettingsOpt);

        //reset config flag
        Flags.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION, symbolicJacActivated);
        if not Flags.isSet(Flags.FMU_EXPERIMENTAL) then
            Flags.set(Flags.DIS_SYMJAC_FMI20, flagValue);
        end if;

        resultValues =
        {("timeTemplates",Values.REAL(timeTemplates)),
          ("timeSimCode",  Values.REAL(timeSimCode)),
          ("timeBackend",  Values.REAL(timeBackend)),
          ("timeFrontend", Values.REAL(timeFrontend))
          };
          resstr = Absyn.pathStringNoQual(className);
        resstr = stringAppendList({"SimCode: The model ",resstr," has been translated to FMU"});
      then
        (cache,Values.STRING(resstr),st,dlow_1,libs,file_dir, resultValues);
    case (_,_,_,_,_,_,_,_,_)
      equation
        resstr = Absyn.pathStringNoQual(className);
        resstr = stringAppendList({"SimCode: The model ",resstr," could not be translated to FMU"});
        Error.addMessage(Error.INTERNAL_ERROR, {resstr});
      then
        fail();
  end matchcontinue;
end translateModelFMU;


public function translateModelXML
"Entry point to translate a Modelica model for XML export.

 Called from other places in the compiler."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output FCore.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  (outCache,outValue,outInteractiveSymbolTable,outBackendDAE,outStringLst,outFileDir,resultValues):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix,addDummy, inSimSettingsOpt)
    local
      String filenameprefix,file_dir,resstr,description;
      DAE.DAElist dae;
      FCore.Graph graph;
      BackendDAE.BackendDAE dlow,dlow_1;
      list<String> libs;
      GlobalScript.SymbolTable st;
      Absyn.Program p;
      //DAE.Exp fileprefix;
      FCore.Cache cache;
      DAE.FunctionTree funcs;
      Real timeSimCode, timeTemplates, timeBackend, timeFrontend;
      BackendDAE.BackendDAE initDAE;
      Boolean useHomotopy "true if homotopy(...) is used during initialization";
      list<BackendDAE.Equation> removedInitialEquationLst;
      list<BackendDAE.Var> primaryParameters "already sorted";
      list<BackendDAE.Var> allPrimaryParameters "already sorted";

    case (cache,graph,_,st as GlobalScript.SYMBOLTABLE(ast=p),filenameprefix,_, _)
      equation
        /* calculate stuff that we need to create SimCode data structure */
        System.realtimeTick(ClockIndexes.RT_CLOCK_FRONTEND);
        //(cache,Values.STRING(filenameprefix),SOME(_)) = Ceval.ceval(cache,graph, fileprefix, true, SOME(st),NONE(), msg);
        (cache,graph,dae,st) = CevalScriptBackend.runFrontEnd(cache,graph,className,st,false);
        timeFrontend = System.realtimeTock(ClockIndexes.RT_CLOCK_FRONTEND);
        System.realtimeTick(ClockIndexes.RT_CLOCK_BACKEND);
        _ = FCore.getFunctionTree(cache);
        dae = DAEUtil.transformationsBeforeBackend(cache,graph,dae);
        description = DAEUtil.daeDescription(dae);
        dlow = BackendDAECreate.lower(dae, cache, graph, BackendDAE.EXTRA_INFO(description,filenameprefix));
        (dlow_1, initDAE, useHomotopy, removedInitialEquationLst, primaryParameters, allPrimaryParameters) = BackendDAEUtil.getSolvedSystem(dlow,inFileNamePrefix);
        timeBackend = System.realtimeTock(ClockIndexes.RT_CLOCK_BACKEND);

        (libs,file_dir,timeSimCode,timeTemplates) =
          generateModelCodeXML(dlow_1, initDAE, useHomotopy, removedInitialEquationLst, primaryParameters, allPrimaryParameters, p, className, filenameprefix, inSimSettingsOpt);
        resultValues =
        {("timeTemplates",Values.REAL(timeTemplates)),
          ("timeSimCode",  Values.REAL(timeSimCode)),
          ("timeBackend",  Values.REAL(timeBackend)),
          ("timeFrontend", Values.REAL(timeFrontend))
          };
          resstr = Absyn.pathStringNoQual(className);
        resstr = stringAppendList({"SimCode: The model ",resstr," has been translated to XML"});
      then
        (cache,Values.STRING(resstr),st,dlow_1,libs,file_dir, resultValues);
    case (_,_,_,_,_,_, _)
      equation
        resstr = Absyn.pathStringNoQual(className);
        resstr = stringAppendList({"SimCode: The model ",resstr," could not be translated to XML"});
        Error.addMessage(Error.INTERNAL_ERROR, {resstr});
      then
        fail();
  end matchcontinue;
end translateModelXML;



public function generateModelCode "
  Generates code for a model by creating a SimCode structure and calling the
  template-based code generator on it."
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.BackendDAE inInitDAE;
  input Boolean inUseHomotopy "true if homotopy(...) is used during initialization";
  input list<BackendDAE.Equation> inRemovedInitialEquationLst;
  input list<BackendDAE.Var> inPrimaryParameters "already sorted";
  input list<BackendDAE.Var> inAllPrimaryParameters "already sorted";
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
  list<String> includes, includeDirs,libPaths;
  list<SimCode.Function> functions;
  SimCode.SimCode simCode;
  list<SimCode.RecordDeclaration> recordDecls;
  Absyn.ComponentRef a_cref;
  tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> literals;
algorithm
  if Flags.isSet(Flags.GRAPHML) then
    HpcOmTaskGraph.dumpTaskGraph(inBackendDAE, filenamePrefix);
  end if;
  System.realtimeTick(ClockIndexes.RT_CLOCK_SIMCODE);
  a_cref := Absyn.pathToCref(className);
  fileDir := CevalScriptBackend.getFileDir(a_cref, p);

  (libs, libPaths, includes, includeDirs, recordDecls, functions, literals) := SimCodeUtil.createFunctions(p, inBackendDAE);
  simCode := createSimCode(inBackendDAE, inInitDAE, inUseHomotopy, inRemovedInitialEquationLst, inPrimaryParameters, inAllPrimaryParameters, className, filenamePrefix, fileDir, functions, includes, includeDirs, libs,libPaths, simSettingsOpt, recordDecls, literals, args);
  timeSimCode := System.realtimeTock(ClockIndexes.RT_CLOCK_SIMCODE);
  SimCodeFunctionUtil.execStat("SimCode");

  System.realtimeTick(ClockIndexes.RT_CLOCK_TEMPLATES);
  callTargetTemplates(simCode, Config.simCodeTarget());
  timeTemplates := System.realtimeTock(ClockIndexes.RT_CLOCK_TEMPLATES);
  SimCodeFunctionUtil.execStat("Templates");
end generateModelCode;

protected function createSimCode "
  SimCode generator switch - if the NUMPROC-Flag is set, the simcode will be extended with parallel informations."
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.BackendDAE inInitDAE;
  input Boolean inUseHomotopy "true if homotopy(...) is used during initialization";
  input list<BackendDAE.Equation> inRemovedInitialEquationLst;
  input list<BackendDAE.Var> inPrimaryParameters "already sorted";
  input list<BackendDAE.Var> inAllPrimaryParameters "already sorted";
  input Absyn.Path inClassName;
  input String filenamePrefix;
  input String inString11;
  input list<SimCode.Function> functions;
  input list<String> externalFunctionIncludes;
  input list<String> includeDirs;
  input list<String> libs;
  input list<String> libPaths;
  input Option<SimCode.SimulationSettings> simSettingsOpt;
  input list<SimCode.RecordDeclaration> recordDecls;
  input tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> literals;
  input Absyn.FunctionArgs args;
  input Boolean isFMU=false;
  output SimCode.SimCode simCode;
algorithm
  simCode := matchcontinue(inBackendDAE, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs, libPaths,simSettingsOpt, recordDecls, literals, args)
    local
      Integer numProc;
      SimCode.SimCode tmpSimCode;

    case(_, _, _, _, _, _, _, _, _, _,_, _, _) equation
      true = Flags.isSet(Flags.HPCOM);

      // either generate code for profiling or for parallel simulation
      //bcall(not stringEq("none",Flags.getConfigString(Flags.PROFILING_LEVEL)),print,"Deactivate profiling if you want to simulate in parallel.\n");
      //_ = bcallret2((not stringEq("none",Flags.getConfigString(Flags.PROFILING_LEVEL))) and (not stringEq("all_perf",Flags.getConfigString(Flags.PROFILING_LEVEL))),Flags.set,Flags.HPCOM,false,true);
      //true = stringEq("none",Flags.getConfigString(Flags.PROFILING_LEVEL)) or stringEq("all_perf",Flags.getConfigString(Flags.PROFILING_LEVEL));

      numProc = Flags.getConfigInt(Flags.NUM_PROC);
      true = numProc == 0;
      print("hpcom computes the ideal number of processors. If you want to set the number manually, use the flag +n=_ \n");
    then HpcOmSimCodeMain.createSimCode(inBackendDAE, inInitDAE, inUseHomotopy, inRemovedInitialEquationLst, inPrimaryParameters, inAllPrimaryParameters, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs,libPaths, simSettingsOpt, recordDecls, literals, args);

    case(_, _, _, _, _, _, _, _, _,_, _, _, _) equation
      true = Flags.isSet(Flags.HPCOM);

      // either generate code for profiling or for parallel simulation
      //bcall((not stringEq("none",Flags.getConfigString(Flags.PROFILING_LEVEL))) and (not stringEq("all_perf",Flags.getConfigString(Flags.PROFILING_LEVEL))),print,"Deactivate profiling if you want to simulate in parallel.\n");
      //_ = bcallret2(not stringEq("none",Flags.getConfigString(Flags.PROFILING_LEVEL)),Flags.set,Flags.HPCOM,false,true);
      //true = stringEq("none",Flags.getConfigString(Flags.PROFILING_LEVEL)) or stringEq("all_perf",Flags.getConfigString(Flags.PROFILING_LEVEL));

      numProc = Flags.getConfigInt(Flags.NUM_PROC);
      true = (numProc > 0);
    then HpcOmSimCodeMain.createSimCode(inBackendDAE, inInitDAE, inUseHomotopy, inRemovedInitialEquationLst, inPrimaryParameters, inAllPrimaryParameters, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs, libPaths,simSettingsOpt, recordDecls, literals, args);

    else equation
      (tmpSimCode, _) = SimCodeUtil.createSimCode(inBackendDAE, inInitDAE, inUseHomotopy, inRemovedInitialEquationLst, inPrimaryParameters, inAllPrimaryParameters, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs,libPaths, simSettingsOpt, recordDecls, literals, args, isFMU=isFMU);
    then tmpSimCode;
  end matchcontinue;
end createSimCode;

// TODO: use another switch ... later make it first class option like -target or so
protected function callTargetTemplates "
  Generate target code by passing the SimCode data structure to templates."
  input SimCode.SimCode simCode;
  input String target;
algorithm
  _ := match target
    local
      String str, guid;

    case "CSharp" equation
      Tpl.tplNoret(CodegenCSharp.translateModel, simCode);
    then ();

    case "Cpp" equation
      callTargetTemplatesCPP(simCode);
    then ();

    case "Adevs" equation
      Tpl.tplNoret(CodegenAdevs.translateModel, simCode);
    then ();

    case "sfmi" equation
      Tpl.tplNoret3(CodegenSparseFMI.translateModel, simCode, "2.0", "me");
    then ();

    case "C" equation
      guid = System.getUUIDStr();

      System.realtimeTick(ClockIndexes.RT_PROFILER0);
      Tpl.tplNoret2(CodegenC.translateInitFile, simCode, guid);
      // print("SimCode -> init.xml: " + realString(System.realtimeTock(ClockIndexes.RT_PROFILER0)*1000) + "ms\n");
      // System.realtimeTick(ClockIndexes.RT_PROFILER0);
      if Flags.isSet(Flags.MODEL_INFO_JSON) then
        SerializeModelInfo.serialize(simCode, Flags.isSet(Flags.INFO_XML_OPERATIONS));
      else
        Tpl.tplNoret2(SimCodeDump.dumpSimCode, simCode, Flags.isSet(Flags.INFO_XML_OPERATIONS));
      end if;
      dumpTaskSystemIfFlag(simCode);
      // print("SimCode -> info.xml: " + realString(System.realtimeTock(ClockIndexes.RT_PROFILER0)*1000) + "ms\n");
      // System.realtimeTick(ClockIndexes.RT_PROFILER0);
      // print("SimCode -> info.json: " + realString(System.realtimeTock(ClockIndexes.RT_PROFILER0)*1000) + "ms\n");
      Tpl.tplNoret2(CodegenC.translateModel, simCode, guid);
      // print("SimCode -> C-files: " + realString(System.realtimeTock(ClockIndexes.RT_PROFILER0)*1000) + "ms\n");
    then ();

    case "JavaScript" equation
      guid = System.getUUIDStr();
      Tpl.tplNoret2(CodegenC.translateModel, simCode, guid);
      Tpl.tplNoret2(CodegenC.translateInitFile, simCode, guid);
      Tpl.tplNoret2(SimCodeDump.dumpSimCodeToC, simCode, false);
      Tpl.tplNoret(CodegenJS.markdownFile, simCode);
    then ();

    case "XML" equation
      Tpl.tplNoret(CodegenXML.translateModel, simCode);
    then ();

    case "Java" equation
      Tpl.tplNoret(CodegenJava.translateModel, simCode);
    then ();

    case "None"
    then ();

    else equation
      str = "Unknown template target: " + target;
      Error.addMessage(Error.INTERNAL_ERROR, {str});
    then fail();
  end match;
end callTargetTemplates;

protected function dumpTaskSystemIfFlag
  input SimCode.SimCode simCode;
algorithm
  if Flags.isSet(Flags.PARMODAUTO) then
    Tpl.tplNoret2(TaskSystemDump.dumpTaskSystem, simCode, Flags.isSet(Flags.INFO_XML_OPERATIONS));
  end if;
end dumpTaskSystemIfFlag;

protected function callTargetTemplatesCPP
  input SimCode.SimCode iSimCode;
algorithm
  if(Flags.isSet(Flags.HPCOM)) then
    Tpl.tplNoret(CodegenCppHpcom.translateModel, iSimCode);
  else
    Tpl.tplNoret(CodegenCpp.translateModel, iSimCode);
  end if;
end callTargetTemplatesCPP;

protected function callTargetTemplatesFMU
"Generate target code by passing the SimCode data structure to templates."
  input SimCode.SimCode simCode;
  input String target;
  input String FMUVersion;
  input String FMUType;
algorithm
  _ := match (simCode,target)
    local
      String str;
      String fmutmp;

    case (SimCode.SIMCODE(),"C")
      algorithm
        fmutmp := simCode.fileNamePrefix + ".fmutmp";
        if System.directoryExists(fmutmp) then
          if not System.removeDirectory(fmutmp) then
            print("Failed to remove directory: " + fmutmp + "\n");
            fail();
          end if;
        end if;
        Util.createDirectoryTree(fmutmp + "/sources/include/");
        if Flags.isSet(Flags.MODEL_INFO_JSON) then
          SerializeModelInfo.serialize(simCode, Flags.isSet(Flags.INFO_XML_OPERATIONS));
          str := fmutmp + "/sources/" + simCode.fileNamePrefix;
          true := System.covertTextFileToCLiteral(simCode.fileNamePrefix+"_info.json", str+"_info.c");
        else
          Tpl.tplNoret2(SimCodeDump.dumpSimCodeToC, simCode, false);
        end if;
        Tpl.tplNoret3(CodegenFMU.translateModel, simCode, FMUVersion, FMUType);
      then ();
    case (_,"Cpp")
      equation
        if(Flags.isSet(Flags.HPCOM)) then
          Tpl.tplNoret3(CodegenFMUCppHpcom.translateModel, simCode, FMUVersion, FMUType);
        else
          Tpl.tplNoret3(CodegenFMUCpp.translateModel, simCode, FMUVersion, FMUType);
        end if;
      then ();
    else
      equation
        str = "Unknown FMU template target: " + target;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end match;
end callTargetTemplatesFMU;


protected function callTargetTemplatesXML
"Generate target code by passing the SimCode data structure to templates."
  input SimCode.SimCode simCode;
  input String target;
algorithm
  Tpl.tplNoret(CodegenXML.translateModel, simCode);
end callTargetTemplatesXML;

public function translateModel "
  Entry point to translate a Modelica model for simulation.
  Called from other places in the compiler."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  input Absyn.FunctionArgs args "labels for remove terms";
  output FCore.Cache outCache;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String, Values.Value>> resultValues;
algorithm
  (outCache, outInteractiveSymbolTable, outBackendDAE, outStringLst, outFileDir, resultValues) :=
  matchcontinue (inCache, inEnv, className, inInteractiveSymbolTable, inFileNamePrefix, addDummy, inSimSettingsOpt, args)
    local
      String filenameprefix, file_dir, resstr, description;
      DAE.DAElist dae;
      FCore.Graph graph;
      BackendDAE.BackendDAE dlow, dlow_1;
      list<String> libs;
      GlobalScript.SymbolTable st;
      Absyn.Program p;
      //DAE.Exp fileprefix;
      FCore.Cache cache;
      Real timeSimCode, timeTemplates, timeBackend, timeFrontend;
      BackendDAE.BackendDAE initDAE;
      Boolean useHomotopy "true if homotopy(...) is used during initialization";
      list<BackendDAE.Equation> removedInitialEquationLst;
      list<BackendDAE.Var> primaryParameters "already sorted";
      list<BackendDAE.Var> allPrimaryParameters "already sorted";

    case (cache, graph, _, (st as GlobalScript.SYMBOLTABLE(ast=p)), filenameprefix, _, _, _) equation
      // calculate stuff that we need to create SimCode data structure
      System.realtimeTick(ClockIndexes.RT_CLOCK_FRONTEND);
      System.realtimeTick(ClockIndexes.RT_CLOCK_EXECSTAT);
      System.realtimeTick(ClockIndexes.RT_CLOCK_EXECSTAT_CUMULATIVE);
      (cache, graph, dae, st) = CevalScriptBackend.runFrontEnd(cache, graph, className, st, false);
      SimCodeFunctionUtil.execStat("FrontEnd");
      timeFrontend = System.realtimeTock(ClockIndexes.RT_CLOCK_FRONTEND);

      System.realtimeTick(ClockIndexes.RT_CLOCK_BACKEND);
      dae = DAEUtil.transformationsBeforeBackend(cache, graph, dae);
      SimCodeFunctionUtil.execStat("Transformations before backend");
      description = DAEUtil.daeDescription(dae);
      dlow = BackendDAECreate.lower(dae, cache, graph, BackendDAE.EXTRA_INFO(description,filenameprefix));
      //BackendDump.printBackendDAE(dlow);
      (dlow_1, initDAE, useHomotopy, removedInitialEquationLst, primaryParameters, allPrimaryParameters) = BackendDAEUtil.getSolvedSystem(dlow,inFileNamePrefix);
      timeBackend = System.realtimeTock(ClockIndexes.RT_CLOCK_BACKEND);

      (libs, file_dir, timeSimCode, timeTemplates) =
        generateModelCode(dlow_1, initDAE, useHomotopy, removedInitialEquationLst, primaryParameters, allPrimaryParameters, p, className, filenameprefix, inSimSettingsOpt, args);

      resultValues = {("timeTemplates", Values.REAL(timeTemplates)),
                      ("timeSimCode", Values.REAL(timeSimCode)),
                      ("timeBackend", Values.REAL(timeBackend)),
                      ("timeFrontend", Values.REAL(timeFrontend))};
    then (cache, st, dlow_1, libs, file_dir, resultValues);

    case (_, _, _, _, _, _, _, _) equation
      true = Flags.isSet(Flags.FAILTRACE);
      resstr = Absyn.pathStringNoQual(className);
      resstr = stringAppendList({"SimCode: The model ", resstr, " could not be translated"});
      Error.addMessage(Error.INTERNAL_ERROR, {resstr});
    then fail();
  end matchcontinue;
end translateModel;

annotation(__OpenModelica_Interface="backend");
end SimCodeMain;
