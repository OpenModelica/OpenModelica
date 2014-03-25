/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package CevalScript
" file:        CevalScript.mo
  package:     CevalScript
  description: Constant propagation of expressions

  RCS: $Id$

  This module handles scripting.

  Input:
    Env: Environment with bindings
    Exp: Expression to evaluate
    Bool flag determines whether the current instantiation is implicit
    InteractiveSymbolTable is optional, and used in interactive mode, e.g. from OMShell

  Output:
    Value: The evaluated value
    InteractiveSymbolTable: Modified symbol table
    Subscript list : Evaluates subscripts and generates constant expressions."

// public imports
public import Absyn;
public import BackendDAE;
public import Ceval;
public import DAE;
public import Env;
public import Error;
public import GlobalScript;
public import Interactive;
public import Values;
public import SimCode;
public import UnitAbsyn;

// protected imports
protected import BackendDump;
protected import BackendDAECreate;
protected import BackendDAEUtil;
protected import BackendDAEOptimize;
protected import BackendEquation;
protected import BackendVariable;
protected import BaseHashSet;
protected import Builtin;
protected import CevalFunction;
protected import CheckModel;
protected import ClassInf;
protected import ClassLoader;
protected import CodegenC;
protected import Config;
protected import Corba;
protected import DAEQuery;
protected import DAEUtil;
protected import DAEDump;
protected import Debug;
protected import Dump;
protected import DynLoad;
protected import Expression;
protected import ExpressionDump;
protected import FindZeroCrossings;
protected import Flags;
protected import Global;
protected import Graph;
protected import HashSetString;
protected import Inst;
protected import InstFunction;
protected import InnerOuter;
protected import List;
protected import Lookup;
protected import MetaUtil;
protected import Mod;
protected import Prefix;
protected import Parser;
protected import Print;
protected import Refactor;
protected import SCodeDump;
protected import NFEnv;
protected import NFInst;
protected import NFSCodeEnv;
protected import NFSCodeFlatten;
protected import SimCodeMain;
protected import System;
protected import Static;
protected import StaticScript;
protected import SCode;
protected import SCodeUtil;
protected import Settings;
protected import SimulationResults;
protected import TaskGraphResults;
protected import Tpl;
protected import CodegenFMU;
protected import Types;
protected import Unparsing;
protected import Util;
protected import ValuesUtil;
protected import XMLDump;
protected import ComponentReference;
protected import Uncertainties;
protected import OpenTURNS;
protected import FMI;
protected import FMIExt;
protected import ErrorExt;
protected import UnitAbsynBuilder;
protected import UnitParserExt;
protected import RewriteRules;

protected constant DAE.Type simulationResultType_rtest = DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationResult")),{
  DAE.TYPES_VAR("resultFile",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("simulationOptions",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("messages",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE())
  },NONE(),DAE.emptyTypeSource);

protected constant DAE.Type simulationResultType_full = DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationResult")),{
  DAE.TYPES_VAR("resultFile",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("simulationOptions",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("messages",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("timeFrontend",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("timeBackend",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("timeSimCode",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("timeTemplates",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("timeCompile",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("timeSimulation",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("timeTotal",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE())
  },NONE(),DAE.emptyTypeSource);

protected constant DAE.Type simulationResultType_drModelica = DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationResult")),{
  DAE.TYPES_VAR("messages",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("flatteningTime",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("simulationTime",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE())
  },NONE(),DAE.emptyTypeSource);

//these are in reversed order than above
protected constant list<tuple<String,Values.Value>> zeroAdditionalSimulationResultValues =
  { ("timeTotal",      Values.REAL(0.0)),
    ("timeSimulation", Values.REAL(0.0)),
    ("timeCompile",    Values.REAL(0.0)),
    ("timeTemplates",  Values.REAL(0.0)),
    ("timeSimCode",    Values.REAL(0.0)),
    ("timeBackend",    Values.REAL(0.0)),
    ("timeFrontend",   Values.REAL(0.0))
  };

protected constant DAE.Exp defaultStartTime         = DAE.RCONST(0.0)     "default startTime";
protected constant DAE.Exp defaultStopTime          = DAE.RCONST(1.0)     "default stopTime";
protected constant DAE.Exp defaultNumberOfIntervals = DAE.ICONST(500)     "default numberOfIntervals";
protected constant DAE.Exp defaultStepSize          = DAE.RCONST(0.002)   "default stepSize";
protected constant DAE.Exp defaultTolerance         = DAE.RCONST(1e-6)    "default tolerance";
protected constant DAE.Exp defaultMethod            = DAE.SCONST("dassl") "default method";
protected constant DAE.Exp defaultFileNamePrefix    = DAE.SCONST("")      "default fileNamePrefix";
protected constant DAE.Exp defaultOptions           = DAE.SCONST("")      "default options";
protected constant DAE.Exp defaultOutputFormat      = DAE.SCONST("mat")   "default outputFormat";
protected constant DAE.Exp defaultVariableFilter    = DAE.SCONST(".*")    "default variableFilter; does whole string matching, i.e. it becomes ^.*$ in the runtime";
protected constant DAE.Exp defaultMeasureTime       = DAE.BCONST(false)   "time measurement disabled by default";
protected constant DAE.Exp defaultCflags            = DAE.SCONST("")      "default compiler flags";
protected constant DAE.Exp defaultSimflags          = DAE.SCONST("")      "default simulation flags";

protected constant GlobalScript.SimulationOptions defaultSimulationOptions =
  GlobalScript.SIMULATION_OPTIONS(
    defaultStartTime,
    defaultStopTime,
    defaultNumberOfIntervals,
    defaultStepSize,
    defaultTolerance,
    defaultMethod,
    defaultFileNamePrefix,
    defaultOptions,
    defaultOutputFormat,
    defaultVariableFilter,
    defaultMeasureTime,
    defaultCflags,
    defaultSimflags
    ) "default simulation options";

protected constant list<String> simulationOptionsNames =
  {
    "startTime",
    "stopTime",
    "numberOfIntervals",
    "tolerance",
    "method",
    "fileNamePrefix",
    "options",
    "outputFormat",
    "variableFilter",
    "measureTime",
    "cflags",
    "simflags"
  } "names of simulation options";

public function getSimulationResultType
  output DAE.Type t;
algorithm
  t := Util.if_(Config.getRunningTestsuite(), simulationResultType_rtest, simulationResultType_full);
end getSimulationResultType;

public function getDrModelicaSimulationResultType
  output DAE.Type t;
algorithm
  t := Util.if_(Config.getRunningTestsuite(), simulationResultType_rtest, simulationResultType_drModelica);
end getDrModelicaSimulationResultType;

public function createSimulationResult
  input String resultFile;
  input String options;
  input String message;
  input list<tuple<String,Values.Value>> inAddResultValues "additional values in reversed order; expected values see in CevalScript.simulationResultType_full";
  output Values.Value res;
protected
  list<tuple<String,Values.Value>> resultValues;
  list<Values.Value> vals;
  list<String> fields;
  Boolean isTestType,notest;
algorithm
  resultValues := listReverse(inAddResultValues);
  //TODO: maybe we should test if the fields are the ones in simulationResultType_full
  notest := not Config.getRunningTestsuite();
  fields := Debug.bcallret2(notest, List.map, resultValues, Util.tuple21, {});
  vals := Debug.bcallret2(notest, List.map, resultValues, Util.tuple22, {});
  res := Values.RECORD(Absyn.IDENT("SimulationResult"),
    Values.STRING(resultFile)::Values.STRING(options)::Values.STRING(message)::vals,
    "resultFile"::"simulationOptions"::"messages"::fields,-1);
end createSimulationResult;

public function createDrModelicaSimulationResult
  input String resultFile;
  input String options;
  input String message;
  input list<tuple<String,Values.Value>> inAddResultValues "additional values in reversed order; expected values see in CevalScript.simulationResultType_full";
  output Values.Value res;
protected
  list<tuple<String,Values.Value>> resultValues;
  list<Values.Value> vals;
  list<String> fields;
  Boolean isTestType,notest;
algorithm
  resultValues := listReverse(inAddResultValues);
  //TODO: maybe we should test if the fields are the ones in simulationResultType_full
  notest := not Config.getRunningTestsuite();
  fields := Debug.bcallret2(notest, List.map, resultValues, Util.tuple21, {});
  vals := Debug.bcallret2(notest, List.map, resultValues, Util.tuple22, {});
  res := Values.RECORD(Absyn.IDENT("SimulationResult"),Values.STRING(message)::
    vals, "messages"::fields,-1);
end createDrModelicaSimulationResult;

public function createSimulationResultFailure
  input String message;
  input String options;
  output Values.Value res;
protected
  list<Values.Value> vals;
  list<String> fields;
algorithm
  res := createSimulationResult("", options, message, zeroAdditionalSimulationResultValues);
end createSimulationResultFailure;

public function createDrModelicaSimulationResultFailure
  input String message;
  input String options;
  output Values.Value res;
protected
  list<Values.Value> vals;
  list<String> fields;
algorithm
  res := createDrModelicaSimulationResult("", options, message, {});
end createDrModelicaSimulationResultFailure;

protected function buildCurrentSimulationResultExp
  output DAE.Exp outExp;
protected
  DAE.ComponentRef cref;
algorithm
  cref := ComponentReference.makeCrefIdent("currentSimulationResult",DAE.T_UNKNOWN_DEFAULT,{});
  outExp := Expression.makeCrefExp(cref,DAE.T_UNKNOWN_DEFAULT);
end buildCurrentSimulationResultExp;

protected function cevalCurrentSimulationResultExp
  input Env.Cache inCache;
  input Env.Env env;
  input String inputFilename;
  input GlobalScript.SymbolTable st;
  input Absyn.Msg msg;
  output Env.Cache outCache;
  output String filename;
algorithm
  (outCache,filename) := match (inCache,env,inputFilename,st,msg)
    local Env.Cache cache;
    case (cache,_,"<default>",_,_)
      equation
        (cache,Values.STRING(filename),_) = Ceval.ceval(cache,env,buildCurrentSimulationResultExp(),true,SOME(st),msg,0);
      then (cache,filename);
    else (inCache,inputFilename);
  end match;
end cevalCurrentSimulationResultExp;

public function convertSimulationOptionsToSimCode "converts SimulationOptions to SimCode.SimulationSettings"
  input GlobalScript.SimulationOptions opts;
  output SimCode.SimulationSettings settings;
algorithm
  settings := match(opts)
  local
    Real startTime,stopTime,stepSize,tolerance;
    Integer nIntervals;
    String method,format,varFilter,cflags,options;
    Boolean measureTime;

    case(GlobalScript.SIMULATION_OPTIONS(
      DAE.RCONST(startTime),
      DAE.RCONST(stopTime),
      DAE.ICONST(nIntervals),
      DAE.RCONST(stepSize),
      DAE.RCONST(tolerance),
      DAE.SCONST(method),
      _, /* fileNamePrefix*/
      _, /* options */
      DAE.SCONST(format),
      DAE.SCONST(varFilter),
      DAE.BCONST(measureTime),
      DAE.SCONST(cflags),
      _)) equation
        options = "";

    then SimCode.SIMULATION_SETTINGS(startTime,stopTime,nIntervals,stepSize,tolerance,method,options,format,varFilter,measureTime,cflags);
  end match;
end convertSimulationOptionsToSimCode;

public function buildSimulationOptions
"@author: adrpo
  builds a SimulationOptions record from the given input"
  input DAE.Exp startTime "start time, default 0.0";
  input DAE.Exp stopTime "stop time, default 1.0";
  input DAE.Exp numberOfIntervals "number of intervals, default 500";
  input DAE.Exp stepSize "stepSize, default (stopTime-startTime)/numberOfIntervals";
  input DAE.Exp tolerance "tolerance, default 1e-6";
  input DAE.Exp method "method, default 'dassl'";
  input DAE.Exp fileNamePrefix "file name prefix, default ''";
  input DAE.Exp options "options, default ''";
  input DAE.Exp outputFormat "output format, default 'plt'";
  input DAE.Exp variableFilter;
  input DAE.Exp measureTime;
  input DAE.Exp cflags;
  input DAE.Exp simflags;
  output GlobalScript.SimulationOptions outSimulationOptions;
algorithm
  outSimulationOptions :=
    GlobalScript.SIMULATION_OPTIONS(
    startTime,
    stopTime,
    numberOfIntervals,
    stepSize,
    tolerance,
    method,
    fileNamePrefix,
    options,
    outputFormat,
    variableFilter,
    measureTime,
    cflags,
    simflags
  );
end buildSimulationOptions;

public function getSimulationOption
"@author: adrpo
  get the value from simulation option"
  input GlobalScript.SimulationOptions inSimOpt;
  input String optionName;
  output DAE.Exp outOptionValue;
algorithm
  outOptionValue := matchcontinue(inSimOpt, optionName)
    local
      DAE.Exp e;
      String name, msg;

    case (GlobalScript.SIMULATION_OPTIONS(startTime = e),         "startTime")         then e;
    case (GlobalScript.SIMULATION_OPTIONS(stopTime = e),          "stopTime")          then e;
    case (GlobalScript.SIMULATION_OPTIONS(numberOfIntervals = e), "numberOfIntervals") then e;
    case (GlobalScript.SIMULATION_OPTIONS(stepSize = e),          "stepSize")          then e;
    case (GlobalScript.SIMULATION_OPTIONS(tolerance = e),         "tolerance")         then e;
    case (GlobalScript.SIMULATION_OPTIONS(method = e),            "method")            then e;
    case (GlobalScript.SIMULATION_OPTIONS(fileNamePrefix = e),    "fileNamePrefix")    then e;
    case (GlobalScript.SIMULATION_OPTIONS(options = e),           "options")           then e;
    case (GlobalScript.SIMULATION_OPTIONS(outputFormat = e),      "outputFormat")      then e;
    case (GlobalScript.SIMULATION_OPTIONS(variableFilter = e),    "variableFilter")    then e;
    case (GlobalScript.SIMULATION_OPTIONS(measureTime = e),       "measureTime")       then e;
    case (GlobalScript.SIMULATION_OPTIONS(cflags = e),            "cflags")            then e;
    case (GlobalScript.SIMULATION_OPTIONS(simflags = e),          "simflags")          then e;
    case (_,                                         name)
      equation
        msg = "Unknown simulation option: " +& name;
        Error.addCompilerWarning(msg);
      then
        fail();
  end matchcontinue;
end getSimulationOption;

public function buildSimulationOptionsFromModelExperimentAnnotation
"@author: adrpo
  retrieve annotation(experiment(....)) values and build a SimulationOptions object to return"
  input GlobalScript.SymbolTable inSymTab;
  input Absyn.Path inModelPath;
  input String inFileNamePrefix;
  input Option<GlobalScript.SimulationOptions> defaultOption;
  output GlobalScript.SimulationOptions outSimOpt;
algorithm
  outSimOpt := matchcontinue (inSymTab, inModelPath, inFileNamePrefix, defaultOption)
    local
      GlobalScript.SimulationOptions defaults, simOpt;
      String experimentAnnotationStr;
      list<Absyn.NamedArg> named;

    // search inside annotation(experiment(...))
    case (_, _, _, _)
      equation
        defaults = Util.getOptionOrDefault(defaultOption, setFileNamePrefixInSimulationOptions(defaultSimulationOptions, inFileNamePrefix));

        experimentAnnotationStr =
          Interactive.getNamedAnnotation(
            inModelPath,
            Interactive.getSymbolTableAST(inSymTab),
            Absyn.IDENT("experiment"),
            SOME("{}"),
            Interactive.getExperimentAnnotationString);
                // parse the string we get back, either {} or {StopTime=5, Tolerance = 0.10};

        // jump to next case if the annotation is empty
        false = stringEq(experimentAnnotationStr, "{}");

        // get rid of '{' and '}'
        experimentAnnotationStr = System.stringReplace(experimentAnnotationStr, "{", "");
        experimentAnnotationStr = System.stringReplace(experimentAnnotationStr, "}", "");

        GlobalScript.ISTMTS({GlobalScript.IEXP(exp = Absyn.CALL(functionArgs = Absyn.FUNCTIONARGS(_, named)))}, _)
        = Parser.parsestringexp("experiment(" +& experimentAnnotationStr +& ");\n", "<experiment>");

        simOpt = populateSimulationOptions(defaults, named);
      then
        simOpt;

    // if we fail, just use the defaults
    else
      equation
        defaults = setFileNamePrefixInSimulationOptions(defaultSimulationOptions, inFileNamePrefix);
      then defaults;
  end matchcontinue;
end buildSimulationOptionsFromModelExperimentAnnotation;

protected function setFileNamePrefixInSimulationOptions
  input  GlobalScript.SimulationOptions inSimOpt;
  input  String inFileNamePrefix;
  output GlobalScript.SimulationOptions outSimOpt;
protected
  DAE.Exp startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, options, outputFormat, variableFilter, measureTime, cflags, simflags;
  Boolean UseOtimica;  
algorithm
  UseOtimica := Config.acceptOptimicaGrammar();
  GlobalScript.SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, _, options, outputFormat, variableFilter, measureTime, cflags, simflags) := inSimOpt;
  method := Util.if_(UseOtimica, DAE.SCONST("optimization"),method);
  outSimOpt := GlobalScript.SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, DAE.SCONST(inFileNamePrefix), options, outputFormat, variableFilter, measureTime, cflags, simflags); 
end setFileNamePrefixInSimulationOptions;

protected function getConst
"@author: adrpo
  Tranform a literal Absyn.Exp to DAE.Exp with the given DAE.Type"
  input  Absyn.Exp inAbsynExp;
  input DAE.Type inExpType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inAbsynExp, inExpType)
    local
      Integer i; Real r;
      Absyn.Exp exp;
      String str;

    case (Absyn.UNARY(Absyn.UMINUS(),exp), _)
      equation
        DAE.ICONST(i) = getConst(exp, inExpType);
        i = intNeg(i);
      then
        DAE.ICONST(i);

    case (Absyn.UNARY(Absyn.UMINUS(),exp), _)
      equation
        DAE.RCONST(r) = getConst(exp, inExpType);
        r = realNeg(r);
      then
        DAE.RCONST(r);

    case (Absyn.INTEGER(i), DAE.T_INTEGER(source = _))  then DAE.ICONST(i);
    case (Absyn.REAL(r),    DAE.T_REAL(source = _)) then DAE.RCONST(r);
    case (Absyn.INTEGER(i), DAE.T_REAL(source = _)) equation r = intReal(i); then DAE.RCONST(r);

    case (exp,    _)
      equation
        str = "CevalScript.getConst: Not handled exp: " +& Dump.printExpStr(exp) +& " of type " +& Types.unparseType(inExpType) +& "\n";
        print(str);
      then
        fail();
  end matchcontinue;
end getConst;

protected function populateSimulationOptions
"@auhtor: adrpo
  populate simulation options"
  input GlobalScript.SimulationOptions inSimOpt;
  input list<Absyn.NamedArg> inExperimentSettings;
  output GlobalScript.SimulationOptions outSimOpt;
algorithm
  outSimOpt := matchcontinue(inSimOpt, inExperimentSettings)
    local
      Absyn.Exp exp;
      list<Absyn.NamedArg> rest;
      GlobalScript.SimulationOptions simOpt;
      DAE.Exp startTime;
      DAE.Exp stopTime;
      DAE.Exp numberOfIntervals;
      DAE.Exp stepSize;
      DAE.Exp tolerance;
      DAE.Exp method;
      DAE.Exp fileNamePrefix;
      DAE.Exp options;
      DAE.Exp outputFormat;
      DAE.Exp variableFilter, measureTime, cflags, simflags;
      Real rStepSize, rStopTime, rStartTime;
      Integer iNumberOfIntervals;
      String name,msg;

    case (_, {}) then inSimOpt;

    case (GlobalScript.SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix,  options, outputFormat, variableFilter, measureTime, cflags, simflags),
          Absyn.NAMEDARG(argName = "Tolerance", argValue = exp)::rest)
      equation
        tolerance = getConst(exp, DAE.T_REAL_DEFAULT);
        simOpt = populateSimulationOptions(
          GlobalScript.SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,options,outputFormat,variableFilter,measureTime,cflags,simflags),
             rest);
      then
        simOpt;

    case (GlobalScript.SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, options, outputFormat, variableFilter, measureTime, cflags, simflags),
          Absyn.NAMEDARG(argName = "StartTime", argValue = exp)::rest)
      equation
        startTime = getConst(exp, DAE.T_REAL_DEFAULT);
        simOpt = populateSimulationOptions(
          GlobalScript.SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,options,outputFormat,variableFilter,measureTime,cflags,simflags),
             rest);
      then
        simOpt;

    case (GlobalScript.SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, options, outputFormat, variableFilter, measureTime, cflags, simflags),
          Absyn.NAMEDARG(argName = "StopTime", argValue = exp)::rest)
      equation
        stopTime = getConst(exp, DAE.T_REAL_DEFAULT);
        simOpt = populateSimulationOptions(
          GlobalScript.SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,options,outputFormat,variableFilter,measureTime,cflags,simflags),
             rest);
      then
        simOpt;

    case (GlobalScript.SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, options, outputFormat, variableFilter, measureTime, cflags, simflags),
          Absyn.NAMEDARG(argName = "NumberOfIntervals", argValue = exp)::rest)
      equation
        numberOfIntervals = getConst(exp, DAE.T_INTEGER_DEFAULT);
        simOpt = populateSimulationOptions(
          GlobalScript.SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,options,outputFormat,variableFilter,measureTime,cflags,simflags),
             rest);
      then
        simOpt;

    case (GlobalScript.SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, options, outputFormat, variableFilter, measureTime, cflags, simflags),
          Absyn.NAMEDARG(argName = "Interval", argValue = exp)::rest)
      equation
        DAE.RCONST(rStepSize) = getConst(exp, DAE.T_REAL_DEFAULT);
        // a bit different for Interval, handle it LAST!!!!
        GlobalScript.SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                           fileNamePrefix,options,outputFormat,variableFilter,measureTime,cflags,simflags) =
          populateSimulationOptions(inSimOpt, rest);

       DAE.RCONST(rStartTime) = startTime;
       DAE.RCONST(rStopTime) = stopTime;
       iNumberOfIntervals = realInt(realDiv(realSub(rStopTime, rStartTime), rStepSize));

       numberOfIntervals = DAE.ICONST(iNumberOfIntervals);
       stepSize = DAE.RCONST(rStepSize);

       simOpt = GlobalScript.SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                                   fileNamePrefix,options,outputFormat,variableFilter,measureTime,cflags,simflags);
      then
        simOpt;

    case (GlobalScript.SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, options, outputFormat, variableFilter, measureTime, cflags, simflags),
          Absyn.NAMEDARG(argName = name, argValue = exp)::rest)
      equation
        msg = "Ignoring unknown experiment annotation option: " +& name +& " = " +& Dump.printExpStr(exp);
        Error.addCompilerWarning(msg);
        simOpt = populateSimulationOptions(inSimOpt, rest);
      then
        simOpt;
  end matchcontinue;
end populateSimulationOptions;

protected function simOptionsAsString
"@author: adrpo
  Gets the simulation options as string"
  input list<Values.Value> vals;
  output String str;
algorithm
  str := matchcontinue vals
    local
      list<String> simOptsValues;
      list<Values.Value> lst;

    case _::lst
      equation
        // build a list with the values
        simOptsValues = List.map(lst, ValuesUtil.valString);
        // trim " from strings!
        simOptsValues = List.map2(simOptsValues, System.stringReplace, "\"", "\'");

        str = Util.buildMapStr(simulationOptionsNames, simOptsValues, " = ", ", ");
      then
        str;

    // on failure
    case (_::lst)
      equation
        // build a list with the values
        simOptsValues = List.map(lst, ValuesUtil.valString);
        // trim " from strings!
        simOptsValues = List.map2(simOptsValues, System.stringReplace, "\"", "\'");

        str = stringDelimitList(simOptsValues, ", ");
      then
        str;
  end matchcontinue;
end simOptionsAsString;

protected function loadModel
  input list<tuple<Absyn.Path,list<String>>> imodelsToLoad;
  input String modelicaPath;
  input Absyn.Program ip;
  input Boolean forceLoad;
  input Boolean notifyLoad;
  output Absyn.Program pnew;
  output Boolean success;
algorithm
  (pnew,success) := matchcontinue (imodelsToLoad,modelicaPath,ip,forceLoad,notifyLoad)
    local
      Absyn.Path path;
      String pathStr,versions,className,version;
      list<String> strings;
      Boolean b,b1,b2;
      Absyn.Program p;
      list<tuple<Absyn.Path,list<String>>> modelsToLoad;

    case ({},_,p,_,_) then (p,true);
    case ((path,strings)::modelsToLoad,_,p,_,_)
      equation
        b = checkModelLoaded((path,strings),p,forceLoad,NONE());
        pnew = Debug.bcallret4(not b, ClassLoader.loadClass, path, strings, modelicaPath, NONE(), Absyn.PROGRAM({},Absyn.TOP(),Absyn.dummyTimeStamp));
        className = Absyn.pathString(path);
        version = Debug.bcallret2(not b, getPackageVersion, path, pnew, "");
        Error.assertionOrAddSourceMessage(b or not notifyLoad,Error.NOTIFY_NOT_LOADED,{className,version},Absyn.dummyInfo);
        p = Interactive.updateProgram(pnew, p);
        (p,b1) = loadModel(Interactive.getUsesAnnotationOrDefault(pnew),modelicaPath,p,false,notifyLoad);
        (p,b2) = loadModel(modelsToLoad,modelicaPath,p,forceLoad,notifyLoad);
      then (p,b1 and b2);
    case ((path,strings)::_,_,p,_,_)
      equation
        pathStr = Absyn.pathString(path);
        versions = stringDelimitList(strings,",");
        Error.addMessage(Error.LOAD_MODEL,{pathStr,versions,modelicaPath});
      then (p,false);
  end matchcontinue;
end loadModel;

protected function checkModelLoaded
  input tuple<Absyn.Path,list<String>> tpl;
  input Absyn.Program p;
  input Boolean forceLoad;
  input Option<String> failNonLoad;
  output Boolean loaded;
algorithm
  loaded := matchcontinue (tpl,p,forceLoad,failNonLoad)
    local
      Absyn.Class cdef;
      String str1,str2;
      Option<String> ostr2;
      Absyn.Path path;

    case (_,_,true,_) then false;
    case ((path,str1::_),_,false,_)
      equation
        cdef = Interactive.getPathedClassInProgram(path,p);
        ostr2 = Absyn.getNamedAnnotationInClass(cdef,Absyn.IDENT("version"),Interactive.getAnnotationStringValueOrFail);
        checkValidVersion(path,str1,ostr2);
      then true;
    case (_,_,_,NONE()) then false;
    case ((path,_),_,_,SOME(str2))
      equation
        str1 = Absyn.pathString(path);
        Error.addMessage(Error.INST_NON_LOADED, {str1,str2});
      then false;
  end matchcontinue;
end checkModelLoaded;

protected function checkValidVersion
  input Absyn.Path path;
  input String version;
  input Option<String> actualVersion;
algorithm
  _ := matchcontinue (path,version,actualVersion)
    local
      String pathStr,str1,str2;
    case (_,str1,SOME(str2))
      equation
        true = stringEq(str1,str2);
      then ();
    case (_,str1,SOME(str2))
      equation
        pathStr = Absyn.pathString(path);
        Error.addMessage(Error.LOAD_MODEL_DIFFERENT_VERSIONS,{pathStr,str1,str2});
      then ();
    case (_,str1,NONE())
      equation
        pathStr = Absyn.pathString(path);
        Error.addMessage(Error.LOAD_MODEL_DIFFERENT_VERSIONS,{pathStr,str1,"unknown"});
      then ();
  end matchcontinue;
end checkValidVersion;

public function cevalInteractiveFunctions
"defined in the interactive environment."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp "expression to evaluate";
  input GlobalScript.SymbolTable inSymbolTable;
  input Absyn.Msg msg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable) := matchcontinue (inCache,inEnv,inExp,inSymbolTable,msg,numIter)
    local
      Env.Cache cache;
      Env.Env env;
      DAE.Exp exp;
      list<DAE.Exp> eLst;
      list<Values.Value> valLst;
      String name;
      Values.Value value;
      Real t1,t2,t;
      GlobalScript.SymbolTable st;
      Option<GlobalScript.SymbolTable> stOpt;

      // This needs to be first because otherwise it takes 0 time to get the value :)
    case (cache,env,DAE.CALL(path = Absyn.IDENT(name = "timing"),expLst = {exp}),st,_,_)
      equation
        t1 = System.time();
        (cache,value,SOME(st)) = Ceval.ceval(cache,env, exp, true, SOME(st),msg,numIter+1);
        t2 = System.time();
        t = t2 -. t1;
      then
        (cache,Values.REAL(t),st);

    case (cache,env,DAE.CALL(path=Absyn.IDENT(name),attr=DAE.CALL_ATTR(builtin=true),expLst=eLst),st,_,_)
      equation
        (cache,valLst,stOpt) = Ceval.cevalList(cache,env,eLst,true,SOME(st),msg,numIter);
        valLst = List.map1(valLst,evalCodeTypeName,env);
        st = Util.getOptionOrDefault(stOpt, st);
        (cache,value,st) = cevalInteractiveFunctions2(cache,env,name,valLst,st,msg);
      then
        (cache,value,st);

  end matchcontinue;
end cevalInteractiveFunctions;

protected function cevalInteractiveFunctions2
"defined in the interactive environment."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input String inFunctionName;
  input list<Values.Value> inVals;
  input GlobalScript.SymbolTable inSt;
  input Absyn.Msg msg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable) := matchcontinue (inCache,inEnv,inFunctionName,inVals,inSt,msg)
    local
      String omdev,simflags,s1,str,str1,str2,str3,token,varid,cmd,executable,executable1,encoding,method_str,
             outputFormat_str,initfilename,cit,pd,executableSuffixedExe,sim_call,result_file,filename_1,filename,
             call,str_1,mp,pathstr,name,cname,errMsg,errorStr,
             title,xLabel,yLabel,filename2,varNameStr,xml_filename,xml_contents,visvar_str,pwd,omhome,omlib,omcpath,os,
             platform,usercflags,senddata,res,workdir,gcc,confcmd,touch_file,uname,filenameprefix,compileDir,libDir,exeDir,configDir,from,to,
             gridStr, logXStr, logYStr, x1Str, x2Str, y1Str, y2Str, curveWidthStr, curveStyleStr, legendPosition,scriptFile,logFile, simflags2, outputFile,
             systemPath, gccVersion, gd, strlinearizeTime, direction, suffix;
      list<DAE.Exp> simOptions;
      list<Values.Value> vals;
      Absyn.Path path,classpath,className,baseClassPath;
      SCode.Program scodeP,sp;
      Option<list<SCode.Element>> fp;
      list<Env.Frame> env;
      GlobalScript.SymbolTable newst,st_1,st;
      Absyn.Program p,pnew,newp,ptot;
      list<Absyn.Program> newps;
      list<GlobalScript.InstantiatedClass> ic,ic_1;
      list<GlobalScript.Variable> iv;
      list<GlobalScript.CompiledCFunction> cf;
      GlobalScript.SimulationOptions simOpt;
      Real startTime,stopTime,tolerance,reltol,reltolDiffMinMax,rangeDelta;
      DAE.Exp startTimeExp,stopTimeExp,toleranceExp,intervalExp;
      DAE.Type tp;
      Absyn.Class absynClass;
      Absyn.ClassDef cdef;
      Absyn.Exp aexp;
      DAE.DAElist dae;
      BackendDAE.BackendDAE daelow,optdae;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqnarr;
      array<list<Integer>> m,mt;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      Values.Value ret_val,simValue,value,v,cvar,cvar2,v1,v2;
      Absyn.ComponentRef cr_1;
      Integer size,resI,i,i1,i2,i3,n,curveStyle,numberOfIntervals;
      Option<Integer> fmiContext, fmiInstance, fmiModelVariablesInstance; /* void* implementation: DO NOT UNBOX THE POINTER AS THAT MIGHT CHANGE IT. Just treat this as an opaque type. */
      Integer fmiLogLevel;
      list<Integer> is;
      list<FMI.ModelVariables> fmiModelVariablesList, fmiModelVariablesList1;
      FMI.ExperimentAnnotation fmiExperimentAnnotation;
      FMI.Info fmiInfo;
      list<String> vars_1,args,strings,strs,strs1,strs2,visvars,postOptModStrings,postOptModStringsOrg,mps,files,dirs;
      Real timeTotal,timeSimulation,timeStamp,val,x1,x2,y1,y2,r,r1,r2,linearizeTime,curveWidth,offset,offset1,offset2,scaleFactor,scaleFactor1,scaleFactor2;
      GlobalScript.Statements istmts;
      list<GlobalScript.Statements> istmtss;
      Boolean have_corba, bval, anyCode, b, b1, b2, externalWindow, grid, logX, logY,  gcc_res, omcfound, rm_res, touch_res, uname_res,  ifcpp, ifmsvc,sort, builtin, showProtected, inputConnectors, outputConnectors;
      Env.Cache cache;
      list<GlobalScript.LoadedFile> lf;
      Absyn.ComponentRef  crefCName;
      list<tuple<String,Values.Value>> resultValues;
      list<Real> realVals;
      list<tuple<String,list<String>>> deps,depstransitive,depstransposed,depstransposedtransitive,depsmerged,depschanged;
      Absyn.CodeNode codeNode;
      list<Values.Value> cvars,vals2;
      list<Absyn.Path> paths;
      list<Absyn.NamedArg> nargs;
      list<Absyn.Class> classes;
      Absyn.Within within_;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      SimCode.SimulationSettings simSettings;
      Boolean dumpExtractionSteps;
      list<tuple<Absyn.Path,list<String>>> uses;
      Config.LanguageStandard oldLanguageStd;
      SCode.Element cl;
      list<SCode.Element> cls;
      list<String> names, namesPublic, namesProtected, namesChanged, fileNames;
      HashSetString.HashSet hashSetString;
      list<Boolean> blst;
      list<Error.TotalMessage> messages;
      UnitAbsyn.Unit u1,u2;
      Real stoptime,starttime,tol,stepsize,interval;
      String stoptime_str,stepsize_str,starttime_str,tol_str,num_intervalls_str,description,prefix;
    case (cache,env,"parseString",{Values.STRING(str1),Values.STRING(str2)},st,_)
      equation
        Absyn.PROGRAM(classes=classes,within_=within_) = Parser.parsestring(str1,str2);
        paths = List.map(classes,Absyn.className);
        paths = List.map1r(paths,Absyn.joinWithinPath,within_);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"parseString",_,st,_)
      then (cache,ValuesUtil.makeArray({}),st);

    case (cache,env,"parseFile",{Values.STRING(str1),Values.STRING(encoding)},st,_)
      equation
        // clear the errors before!
        Error.clearMessages() "Clear messages";
        Print.clearErrorBuf() "Clear error buffer";
        (paths, st) = Interactive.parseFile(str1, encoding, st);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"loadFileInteractiveQualified",{Values.STRING(str1),Values.STRING(encoding)},st,_)
      equation
        // clear the errors before!
        Error.clearMessages() "Clear messages";
        Print.clearErrorBuf() "Clear error buffer";
        (paths, st) = Interactive.loadFileInteractiveQualified(str1, encoding, st);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"loadFileInteractive",{Values.STRING(str1),Values.STRING(encoding)},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        pnew = ClassLoader.loadFile(str1,encoding) "System.regularFileExists(name) => 0 &    Parser.parse(name) => p1 &" ;
        vals = List.map(Interactive.getTopClassnames(pnew),ValuesUtil.makeCodeTypeName);
        p = Interactive.updateProgram(pnew, p);
        st = Interactive.setSymbolTableAST(st, p);
      then (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"getSourceFile",{Values.CODE(Absyn.C_TYPENAME(path))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        str = Interactive.getSourceFile(path, p);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"setSourceFile",{Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str)},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        (b,p) = Interactive.setSourceFile(path, str, p);
        st = Interactive.setSymbolTableAST(st,p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"setClassComment",{Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str)},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        (p,b) = Interactive.setClassComment(path, str, p);
        st = Interactive.setSymbolTableAST(st, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache, env, "isShortDefinition", {Values.CODE(Absyn.C_TYPENAME(path))}, st as GlobalScript.SYMBOLTABLE(ast = p), _)
      equation
        b = isShortDefinition(path, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"getClassNames",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("AllLoadedClasses"))),Values.BOOL(false),_,Values.BOOL(sort),Values.BOOL(builtin),Values.BOOL(showProtected)},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        p = Debug.bcallret2(builtin,Interactive.updateProgram,p,Builtin.getInitialFunctions(),p);
        paths = Interactive.getTopClassnames(p);
        paths = Debug.bcallret2(sort, List.sort, paths, Absyn.pathGe, paths);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"getClassNames",{Values.CODE(Absyn.C_TYPENAME(path)),Values.BOOL(false),Values.BOOL(b),Values.BOOL(sort),Values.BOOL(builtin),Values.BOOL(showProtected)},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        p = Debug.bcallret2(builtin,Interactive.updateProgram,p,Builtin.getInitialFunctions(),p);
        paths = Interactive.getClassnamesInPath(path, p, showProtected);
        paths = Debug.bcallret3(b,List.map1r,paths,Absyn.joinPaths,path,paths);
        paths = Debug.bcallret2(sort, List.sort, paths, Absyn.pathGe, paths);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"getClassNames",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("AllLoadedClasses"))),Values.BOOL(true),_,Values.BOOL(sort),Values.BOOL(builtin),Values.BOOL(showProtected)},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        p = Debug.bcallret2(builtin,Interactive.updateProgram,p,Builtin.getInitialFunctions(),p);
        (_,paths) = Interactive.getClassNamesRecursive(NONE(),p,showProtected,{});
        paths = listReverse(paths);
        paths = Debug.bcallret2(sort, List.sort, paths, Absyn.pathGe, paths);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"getClassNames",{Values.CODE(Absyn.C_TYPENAME(path)),Values.BOOL(true),_,Values.BOOL(sort),Values.BOOL(builtin),Values.BOOL(showProtected)},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        p = Debug.bcallret2(builtin,Interactive.updateProgram,p,Builtin.getInitialFunctions(),p);
        (_,paths) = Interactive.getClassNamesRecursive(SOME(path),p,showProtected,{});
        paths = listReverse(paths);
        paths = Debug.bcallret2(sort, List.sort, paths, Absyn.pathGe, paths);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"getClassComment",{Values.CODE(Absyn.C_TYPENAME(path))},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        Absyn.CLASS(_,_,_,_,_,cdef,_) = Interactive.getPathedClassInProgram(path, p);
        str = Interactive.getClassComment(cdef);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"getClassComment",{Values.CODE(Absyn.C_TYPENAME(path))},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      then
        (cache,Values.STRING(""),st);

    case (cache,env,"getPackages",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("AllLoadedClasses")))},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        paths = Interactive.getTopPackages(p);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"getPackages",{Values.CODE(Absyn.C_TYPENAME(path))},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        paths = Interactive.getPackagesInPath(path, p);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    /* Does not exist in the env...
    case (cache,env,"lookupClass",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),msg)
      equation
        scodeP = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env) = Inst.makeEnvFromProgram(cache, scodeP, Absyn.IDENT(""));
        (cache,c,env) = Lookup.lookupClass(cache,env, path, true);
        SOME(p1) = Env.getEnvPath(env);
        s1 = Absyn.pathString(p1);
        Print.printBuf("Found class ");
        Print.printBuf(s1);
        Print.printBuf("\n\n");
        str = Print.getString();
      then
        (cache,Values.STRING(str),st);
     */

    case (cache,env,"basename",{Values.STRING(str)},st,_)
      equation
        str = System.basename(str);
      then (cache,Values.STRING(str),st);

    case (cache,env,"dirname",{Values.STRING(str)},st,_)
      equation
        str = System.dirname(str);
      then (cache,Values.STRING(str),st);

    case (cache,env,"codeToString",{Values.CODE(codeNode)},st,_)
      equation
        str = Dump.printCodeStr(codeNode);
      then (cache,Values.STRING(str),st);

    case (cache,env,"typeOf",{Values.CODE(Absyn.C_VARIABLENAME(Absyn.CREF_IDENT(name = varid)))},(st as GlobalScript.SYMBOLTABLE(lstVarVal = iv)),_)
      equation
        tp = Interactive.getTypeOfVariable(varid, iv);
        str = Types.unparseType(tp);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"GC_gcollect_and_unmap",{},st,_)
      equation
        System.GC_gcollect_and_unmap();
      then (cache,Values.BOOL(true),st);

    case (cache,env,"clear",{},st,_)
      then (cache,Values.BOOL(true),GlobalScript.emptySymboltable);

    case (cache,env,"clearProgram",{},GlobalScript.SYMBOLTABLE(lstVarVal=iv),_)
      equation
        newst = GlobalScript.SYMBOLTABLE(Absyn.PROGRAM({},Absyn.TOP(),Absyn.dummyTimeStamp),
                 NONE(),
                 {},
                 iv,
                 {},
                 {});
      then (cache,Values.BOOL(true),newst);

    case (cache,env,"clearVariables",{},
        (st as GlobalScript.SYMBOLTABLE(
          ast = p,
          explodedAst = fp,
          instClsLst = ic,
          compiledFunctions = cf,
          loadedFiles = lf)),_)
      equation
        newst = GlobalScript.SYMBOLTABLE(p,fp,ic,{},cf,lf);
      then
        (cache,Values.BOOL(true),newst);

    // Note: This is not the environment caches, passed here as cache, but instead the cached instantiated classes.
    case (cache,env,"clearCache",{},
        (st as GlobalScript.SYMBOLTABLE(
          ast = p,explodedAst = fp,instClsLst = ic,
          lstVarVal = iv,compiledFunctions = cf,
          loadedFiles = lf)),_)
      equation
        newst = GlobalScript.SYMBOLTABLE(p,fp,{},iv,cf,lf);
      then
        (cache,Values.BOOL(true),newst);

    case (cache,env,"convertUnits",{Values.STRING(str1),Values.STRING(str2)},st,_)
      equation
        UnitParserExt.initSIUnits();
        (u1,scaleFactor1,offset1) = UnitAbsynBuilder.str2unitWithScaleFactor(str1,NONE());
        (u2,scaleFactor2,offset2) = UnitAbsynBuilder.str2unitWithScaleFactor(str2,NONE());
        b = valueEq(u1,u2);
        /* How to calculate the final scale factor and offset?
        ºF = (ºK - 273.15)* 1.8000 + 32.00 = (ºK - 255.37)* 1.8000
        ºC = (ºK - 273.15)

        ºF = (ºC - (255.37 - 273.15))*(1.8/1.0)
        */
        scaleFactor = realDiv(scaleFactor2, scaleFactor1);
        offset = realSub(offset2,offset1);
      then
        (cache,Values.TUPLE({Values.BOOL(b),Values.REAL(scaleFactor),Values.REAL(offset)}),st);

    case (cache,env,"list",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("AllLoadedClasses"))),Values.BOOL(false),Values.BOOL(false),Values.ENUM_LITERAL(name=path)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        (scodeP,st) = Interactive.symbolTableToSCode(st);
        name = Absyn.pathLastIdent(path);
        str = Debug.bcallret2(name ==& "Absyn", Dump.unparseStr, p, false, "");
        str = Debug.bcallret2(name ==& "SCode", SCodeDump.programStr, scodeP, SCodeDump.defaultOptions, str);
        str = Debug.bcallret2(name ==& "MetaModelicaInterface", SCodeDump.programStr, scodeP, SCodeDump.OPTIONS(true,false,true,true,true), str);
        str = Debug.bcallret1(name ==& "Internal", System.anyStringCode, p, str);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"list",{Values.CODE(Absyn.C_TYPENAME(className)),Values.BOOL(b1),Values.BOOL(b2),Values.ENUM_LITERAL(name=path)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        (scodeP,st) = Interactive.symbolTableToSCode(st);
        name = Absyn.pathLastIdent(path);
        absynClass = Interactive.getPathedClassInProgram(className, p);
        absynClass = Debug.bcallret1(b1,Absyn.getFunctionInterface,absynClass,absynClass);
        absynClass = Debug.bcallret1(b2,Absyn.getShortClass,absynClass,absynClass);
        p = Absyn.PROGRAM({absynClass},Absyn.TOP(),Absyn.TIMESTAMP(0.0,0.0));
        str = Debug.bcallret2(name ==& "Absyn", Dump.unparseStr, p, false, "");
        str = Debug.bcallret1(name ==& "Internal", System.anyStringCode, p, str);
        cl = SCode.getElementWithPath(scodeP, className);
        str = Debug.bcallret2(name ==& "SCode", SCodeDump.unparseElementStr, cl, SCodeDump.defaultOptions, str);
        str = Debug.bcallret2(name ==& "MetaModelicaInterface", SCodeDump.unparseElementStr, cl, SCodeDump.OPTIONS(true,false,true,true,true), str);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"list",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,env,"listVariables",{},st as GlobalScript.SYMBOLTABLE(lstVarVal = iv),_)
      equation
        v = ValuesUtil.makeArray(getVariableNames(iv,{}));
      then
        (cache,v,st);

    case (cache,env,"jacobian",{Values.CODE(Absyn.C_TYPENAME(path))},
          (st as GlobalScript.SYMBOLTABLE(
            ast = p,explodedAst = fp,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),_)
      equation
        scodeP = SCodeUtil.translateAbsyn2SCode(p);
        (cache, env, _, dae) = Inst.instantiateClass(cache, InnerOuter.emptyInstHierarchy, scodeP, path);
        dae  = DAEUtil.transformationsBeforeBackend(cache,env,dae);
        ic_1 = Interactive.addInstantiatedClass(ic, GlobalScript.INSTCLASS(path,dae,env));
        filenameprefix = Absyn.pathString(path);
        description = DAEUtil.daeDescription(dae);
        daelow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        (optdae as BackendDAE.DAE({syst},shared)) = BackendDAEUtil.preOptimizeBackendDAE(daelow,NONE());
        (syst,m,mt) = BackendDAEUtil.getIncidenceMatrixfromOption(syst,BackendDAE.NORMAL(),NONE());
        vars = BackendVariable.daeVars(syst);
        eqnarr = BackendEquation.daeEqns(syst);
        (jac, _) = BackendDAEUtil.calculateJacobian(vars, eqnarr, m, false,shared);
        res = BackendDump.dumpJacobianStr(jac);
      then
        (cache,Values.STRING(res),GlobalScript.SYMBOLTABLE(p,fp,ic_1,iv,cf,lf));

    case (cache,env,"translateModel",vals as {Values.CODE(Absyn.C_TYPENAME(className)),_,_,_,_,_,Values.STRING(filenameprefix),_,_,_,_,_,_},st,_)
      equation
        (cache,simSettings) = calculateSimulationSettings(cache,env,vals,st,msg);
        (cache,st_1,_,_,_,_) = translateModel(cache, env, className, st, filenameprefix, true, SOME(simSettings));
      then
        (cache,Values.BOOL(true),st_1);

    case (cache,env,"translateModel",_,st,_)
      then (cache,Values.BOOL(false),st);

    case (cache,env,"modelEquationsUC",vals as {Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(outputFile),Values.BOOL(dumpExtractionSteps)},st,_)
      equation
        (cache,ret_val,st_1) = Uncertainties.modelEquationsUC(cache, env, className, st, outputFile,dumpExtractionSteps);
      then
        (cache,ret_val,st_1);

    case (cache,env,"modelEquationsUC",_,st,_)
      then (cache,Values.STRING("There were errors during extraction of uncertainty equations. Use getErrorString() to see them."),st);

    /*case (cache,env,"translateModelCPP",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)},st,msg)
      equation
        (cache,ret_val,st_1,_,_,_,_) = translateModelCPP(cache,env, className, st, filenameprefix,true,NONE());
      then
        (cache,ret_val,st_1);*/

    case (cache,env,"translateModelFMU", vals as {Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)},st,_)
      equation
        filenameprefix = Util.stringReplaceChar(filenameprefix,".","_");
        simSettings = convertSimulationOptionsToSimCode(defaultSimulationOptions);
        (cache,ret_val,st_1) = translateModelFMU(cache, env, className, st, filenameprefix, true, SOME(simSettings));
      then
        (cache,ret_val,st_1);

    case (cache,env,"translateModelXML",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)},st,_)
      equation
        filenameprefix = Util.stringReplaceChar(filenameprefix,".","_");
        (cache,ret_val,st_1) = translateModelXML(cache, env, className, st, filenameprefix, true, NONE());
      then
        (cache,ret_val,st_1);

    case (cache,env,"exportDAEtoMatlab",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)},st,_)
      equation
        (cache,ret_val,st_1,_) = getIncidenceMatrix(cache,env, className, st, msg, filenameprefix);
      then
        (cache,ret_val,st_1);

    case (cache,env,"checkModel",{Values.CODE(Absyn.C_TYPENAME(className))},st,_)
      equation
        Flags.setConfigBool(Flags.CHECK_MODEL, true);
        (cache,ret_val,st_1) = checkModel(cache, env, className, st, msg);
        Flags.setConfigBool(Flags.CHECK_MODEL, false);
      then
        (cache,ret_val,st_1);

    case (cache,env,"checkAllModelsRecursive",{Values.CODE(Absyn.C_TYPENAME(className)),Values.BOOL(showProtected)},st,_)
      equation
        (cache,ret_val,st_1) = checkAllModelsRecursive(cache, env, className, showProtected, st, msg);
      then
        (cache,ret_val,st_1);

    case (cache,env,"translateGraphics",{Values.CODE(Absyn.C_TYPENAME(className))},st,_)
      equation
        (cache,ret_val,st_1) = translateGraphics(cache,env, className, st, msg);
      then
        (cache,ret_val,st_1);

    case (cache,env,"setCompileCommand",{Values.STRING(cmd)},st,_)
      equation
        // cmd = Util.rawStringToInputString(cmd);
        Settings.setCompileCommand(cmd);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"getCompileCommand",{},st,_)
      equation
        res = Settings.getCompileCommand();
      then
        (cache,Values.STRING(res),st);

    case (cache,env,"setPlotCommand",{Values.STRING(cmd)},st,_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"setTempDirectoryPath",{Values.STRING(cmd)},st,_)
      equation
        // cmd = Util.rawStringToInputString(cmd);
        Settings.setTempDirectoryPath(cmd);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"getTempDirectoryPath",{},st,_)
      equation
        res = Settings.getTempDirectoryPath();
      then
        (cache,Values.STRING(res),st);

    case (cache,env,"setEnvironmentVar",{Values.STRING(varid),Values.STRING(str)},st,_)
      equation
        b = 0 == System.setEnv(varid,str,true);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"getEnvironmentVar",{Values.STRING(varid)},st,_)
      equation
        res = Util.makeValueOrDefault(System.readEnv, varid, "");
      then
        (cache,Values.STRING(res),st);

    case (cache,env,"setInstallationDirectoryPath",{Values.STRING(cmd)},st,_)
      equation
        // cmd = Util.rawStringToInputString(cmd);
        Settings.setInstallationDirectoryPath(cmd);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"getInstallationDirectoryPath",{},st,_)
      equation
        res = Settings.getInstallationDirectoryPath();
      then
        (cache,Values.STRING(res),st);

    case (cache,env,"getModelicaPath",{},st,_)
      equation
        res = Settings.getModelicaPath(Config.getRunningTestsuite());
      then
        (cache,Values.STRING(res),st);

    case (cache,env,"setModelicaPath",{Values.STRING(cmd)},st,_)
      equation
        // cmd = Util.rawStringToInputString(cmd);
        Settings.setModelicaPath(cmd);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"setModelicaPath",_,st,_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"getAnnotationVersion",{},st,_)
      equation
        res = Config.getAnnotationVersion();
      then
        (cache,Values.STRING(res),st);

    case (cache,env,"getNoSimplify",{},st,_)
      equation
        b = Config.getNoSimplify();
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"setNoSimplify",{Values.BOOL(b)},st,_)
      equation
        Config.setNoSimplify(b);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"getShowAnnotations",{},st,_)
      equation
        b = Config.showAnnotations();
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"setShowAnnotations",{Values.BOOL(b)},st,_)
      equation
        Config.setShowAnnotations(b);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"getVectorizationLimit",{},st,_)
      equation
        i = Config.vectorizationLimit();
      then
        (cache,Values.INTEGER(i),st);

    case (cache,env,"getOrderConnections",{},st,_)
      equation
        b = Config.orderConnections();
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"getLanguageStandard",{},st,_)
      equation
        res = Config.languageStandardString(Config.getLanguageStandard());
      then
        (cache,Values.STRING(res),st);

    case (cache,env,"buildModel",vals,st,_)
      equation
        List.map_0(GlobalScript.buildModelClocks,System.realtimeClear);
        System.realtimeTick(GlobalScript.RT_CLOCK_SIMULATE_TOTAL);
        (cache,st,compileDir,executable,method_str,outputFormat_str,initfilename,_,_) = buildModel(cache,env, vals, st, msg);
        executable = Util.if_(not Config.getRunningTestsuite(),compileDir +& executable,executable);
      then
        (cache,ValuesUtil.makeArray({Values.STRING(executable),Values.STRING(initfilename)}),st);

    case(cache,env,"buildOpenTURNSInterface",vals,st,_)
      equation
        (cache,scriptFile,st) = buildOpenTURNSInterface(cache,env,vals,st,msg);
      then
        (cache,Values.STRING(scriptFile),st);
    case(cache,env,"buildOpenTURNSInterface",vals,st,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"buildOpenTURNSInterface failed. Use getErrorString() to see why."});
      then
        fail();

    case(cache,env,"runOpenTURNSPythonScript",vals,st,_)
      equation
        (cache,logFile,st) = runOpenTURNSPythonScript(cache,env,vals,st,msg);
      then
        (cache,Values.STRING(logFile),st);
    case(cache,env,"runOpenTURNSPythonScript",vals,st,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"runOpenTURNSPythonScript failed. Use getErrorString() to see why"});
      then
        fail();

    case (cache,env,"buildModel",_,st,_) /* failing build_model */
      then (cache,ValuesUtil.makeArray({Values.STRING(""),Values.STRING("")}),st);

    case (cache,env,"buildModelBeast",vals,st,_)
      equation
        (cache,st,compileDir,executable,method_str,initfilename) = buildModelBeast(cache,env,vals,st,msg);
        executable = Util.if_(not Config.getRunningTestsuite(),compileDir +& executable,executable);
      then
        (cache,ValuesUtil.makeArray({Values.STRING(executable),Values.STRING(initfilename)}),st);

    // adrpo: see if the model exists before simulation!
    case (cache,env,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        crefCName = Absyn.pathToCref(className);
        false = Interactive.existClass(crefCName, p);
        errMsg = "Simulation Failed. Model: " +& Absyn.pathString(className) +& " does not exist! Please load it first before simulation.";
        simValue = createSimulationResultFailure(errMsg, simOptionsAsString(vals));
      then
        (cache,simValue,st);

    case (cache,env,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,st_1,_)
      equation
        System.realtimeTick(GlobalScript.RT_CLOCK_SIMULATE_TOTAL);
        (cache,st,compileDir,executable,method_str,outputFormat_str,_,simflags,resultValues) = buildModel(cache,env,vals,st_1,msg);

        cit = winCitation();
       
        exeDir=compileDir;
         (cache,simSettings) = calculateSimulationSettings(cache,env,vals,st_1,msg);
        SimCode.SIMULATION_SETTINGS(startTime=starttime,stopTime=stoptime,tolerance=tol,stepSize=stepsize,method = method_str, outputFormat = outputFormat_str)
           = simSettings;
        result_file = stringAppendList(List.consOnTrue(not Config.getRunningTestsuite(),compileDir,{executable,"_res.",outputFormat_str}));
        executableSuffixedExe = stringAppend(executable, getSimulationExtension(Config.simCodeTarget(),System.platform()));
        logFile = stringAppend(executable,".log");
        // adrpo: log file is deleted by buildModel! do NOT DELTE IT AGAIN!
        // we should really have different log files for simulation/compilation!
        // as the buildModel log file will be deleted here and that gives less information to the user!
        0 = Debug.bcallret1(System.regularFileExists(logFile),System.removeFile,logFile,0);
        sim_call = stringAppendList({cit,exeDir,executableSuffixedExe,cit," ",simflags});
        System.realtimeTick(GlobalScript.RT_CLOCK_SIMULATE_SIMULATION);
        SimulationResults.close() "Windows cannot handle reading and writing to the same file from different processes like any real OS :(";
        resI = System.systemCall(sim_call,logFile);
        timeSimulation = System.realtimeTock(GlobalScript.RT_CLOCK_SIMULATE_SIMULATION);
        timeTotal = System.realtimeTock(GlobalScript.RT_CLOCK_SIMULATE_TOTAL);
        (cache,simValue,newst) = createSimulationResultFromcallModelExecutable(resI,timeTotal,timeSimulation,resultValues,cache,className,vals,st,result_file,logFile);
      then
        (cache,simValue,newst);

    case (cache,env,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,st,_)
      equation
        omhome = Settings.getInstallationDirectoryPath() "simulation fail for some other reason than OPENMODELICAHOME not being set." ;
        str = Absyn.pathString(className);
        res = "Failed to build model: " +& str;
        simValue = createSimulationResultFailure(res, simOptionsAsString(vals));
      then
        (cache,simValue,st);

    case (cache,env,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,st,_)
      equation
        str = Absyn.pathString(className);
        simValue = createSimulationResultFailure(
          "Simulation failed for model: " +& str +&
          "\nEnvironment variable OPENMODELICAHOME not set.",
          simOptionsAsString(vals));
      then
        (cache,simValue,st);

    // adrpo: see if the model exists before moving!
    case (cache,env,"moveClass",vals as {Values.CODE(Absyn.C_TYPENAME(className)),
                                         Values.STRING(direction)},
          st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        crefCName = Absyn.pathToCref(className);
        false = Interactive.existClass(crefCName, p);
        simValue = Values.BOOL(false);
      then
        (cache,simValue,st);
    
    // everything should work fine here
    case (cache,env,"moveClass",vals as {Values.CODE(Absyn.C_TYPENAME(className)),
                                        Values.STRING(direction)},
          st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        crefCName = Absyn.pathToCref(className);
        true = Interactive.existClass(crefCName, p);
        p = moveClass(className, direction, p);
        st = Interactive.setSymbolTableAST(st, p);
        simValue = Values.BOOL(true);
      then
        (cache,simValue,st);
    
    // adrpo: some error happened!
    case (cache,env,"moveClass",vals as {Values.CODE(Absyn.C_TYPENAME(className)),
                                        Values.STRING(direction)},
          st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        crefCName = Absyn.pathToCref(className);
        true = Interactive.existClass(crefCName, p);
        errMsg = "moveClass Error: Could not move the model " +& Absyn.pathString(className) +& ". Unknown error.";
        Error.addMessage(Error.INTERNAL_ERROR, {errMsg});
        simValue = Values.BOOL(false);
      then
        (cache,simValue,st);

    case (cache,env,"linearize",(vals as Values.CODE(Absyn.C_TYPENAME(className))::_),st_1,_)
      equation

        System.realtimeTick(GlobalScript.RT_CLOCK_SIMULATE_TOTAL);
        
        b = Flags.getConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION);
        Flags.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION, true);

        (cache,st,compileDir,executable,method_str,outputFormat_str,_,simflags,resultValues) = buildModel(cache,env,vals,st_1,msg);
        Values.REAL(linearizeTime) = getListNthShowError(vals,"try to get stop time",0,2);
        cit = winCitation();
        executableSuffixedExe = stringAppend(executable, System.getExeExt());
        logFile = stringAppend(executable,".log");
        0 = Debug.bcallret1(System.regularFileExists(logFile),System.removeFile,logFile,0);
        strlinearizeTime = realString(linearizeTime);
        sim_call = stringAppendList({cit,compileDir,executableSuffixedExe,cit," ","-l=",strlinearizeTime," ",simflags});
        System.realtimeTick(GlobalScript.RT_CLOCK_SIMULATE_SIMULATION);
        SimulationResults.close() "Windows cannot handle reading and writing to the same file from different processes like any real OS :(";
        0 = System.systemCall(sim_call,logFile);

        result_file = stringAppendList(List.consOnTrue(not Config.getRunningTestsuite(),compileDir,{executable,"_res.",outputFormat_str}));
        timeSimulation = System.realtimeTock(GlobalScript.RT_CLOCK_SIMULATE_SIMULATION);
        timeTotal = System.realtimeTock(GlobalScript.RT_CLOCK_SIMULATE_TOTAL);
        simValue = createSimulationResult(
           result_file,
           simOptionsAsString(vals),
           System.readFile(logFile),
           ("timeTotal", Values.REAL(timeTotal)) ::
           ("timeSimulation", Values.REAL(timeSimulation)) ::
          resultValues);
        newst = Interactive.addVarToSymboltable(
          DAE.CREF_IDENT("currentSimulationResult", DAE.T_STRING_DEFAULT, {}),
          Values.STRING(result_file), Env.emptyEnv, st);
        //reset config flag
        Flags.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION, b);
      then
        (cache,simValue,newst);
        
   case (cache,env,"optimize",(vals as Values.CODE(Absyn.C_TYPENAME(className))::_),st_1,_)
      equation

        System.realtimeTick(GlobalScript.RT_CLOCK_SIMULATE_TOTAL);
        
        b = Flags.getConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION);
        Flags.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION, true);

        (cache,st,compileDir,executable,method_str,outputFormat_str,_,simflags,resultValues) = buildModel(cache,env,vals,st_1,msg);
        cit = winCitation();
        exeDir=compileDir;
        (cache,simSettings) = calculateSimulationSettings(cache,env,vals,st_1,msg); 
        SimCode.SIMULATION_SETTINGS(startTime=starttime,stopTime=stoptime,tolerance=tol,stepSize=stepsize,method = method_str, outputFormat = outputFormat_str) = simSettings;   
        result_file = stringAppendList(List.consOnTrue(not Config.getRunningTestsuite(),compileDir,{executable,"_res.",outputFormat_str}));
        executableSuffixedExe = stringAppend(executable, getSimulationExtension(Config.simCodeTarget(),System.platform()));
        logFile = stringAppend(executable,".log");
        // adrpo: log file is deleted by buildModel! do NOT DELTE IT AGAIN!
        // we should really have different log files for simulation/compilation!
        // as the buildModel log file will be deleted here and that gives less information to the user!
        0 = Debug.bcallret1(System.regularFileExists(logFile),System.removeFile,logFile,0);
        sim_call = stringAppendList({cit,exeDir,executableSuffixedExe,cit," ",simflags});
        System.realtimeTick(GlobalScript.RT_CLOCK_SIMULATE_SIMULATION);
        SimulationResults.close() "Windows cannot handle reading and writing to the same file from different processes like any real OS :(";
        resI = System.systemCall(sim_call,logFile);
        timeSimulation = System.realtimeTock(GlobalScript.RT_CLOCK_SIMULATE_SIMULATION);
        timeTotal = System.realtimeTock(GlobalScript.RT_CLOCK_SIMULATE_TOTAL);
        (cache,simValue,newst) = createSimulationResultFromcallModelExecutable(resI,timeTotal,timeSimulation,resultValues,cache,className,vals,st,result_file,logFile);
        //reset config flag
        Flags.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION, b);
      then
        (cache,simValue,newst);

    case (cache,env,"instantiateModel",{Values.CODE(Absyn.C_TYPENAME(className))},st,_)
      equation
        (cache,env,dae,st) = runFrontEnd(cache,env,className,st,true);
        str = DAEDump.dumpStr(dae,Env.getFunctionTree(cache));
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"instantiateModel",{Values.CODE(Absyn.C_TYPENAME(path))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        cr_1 = Absyn.pathToCref(path);
        false = Interactive.existClass(cr_1, p);
        str = Absyn.pathString(path);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        (cache,Values.STRING(""),st);

    case (cache,env,"instantiateModel",{Values.CODE(Absyn.C_TYPENAME(path))},st,_)
      equation
        b = Error.getNumMessages() == 0;
        str = Absyn.pathString(path);
        str = "Instantiation of " +& str +& " failed with no error message";
        Debug.bcall2(b, Error.addMessage, Error.INTERNAL_ERROR, {str,"<TOP>"});
      then
        (cache,Values.STRING(""),st);

    case (cache,env,"reopenStandardStream",{Values.ENUM_LITERAL(index=i),Values.STRING(filename)},st,_)
      equation
        b = System.reopenStandardStream(i-1,filename);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"importFMUOld",{Values.STRING(filename),Values.STRING(workdir)},st,_)
      equation
        // get OPENMODELICAHOME
        omhome = Settings.getInstallationDirectoryPath();
        // create the path till fmigenerator
        str = omhome +& "/bin/fmigenerator";
        workdir = Util.if_(System.directoryExists(workdir), workdir, System.pwd());
        // create the list of arguments for fmigenerator
        call = str +& " " +& "--fmufile=\"" +& filename +& "\" --outputdir=\"" +& workdir +& "\"";
        0 = System.systemCall(call,"");
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"importFMUOld",_,st,_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"importFMU",{Values.STRING(filename),Values.STRING(workdir),Values.INTEGER(fmiLogLevel),Values.BOOL(b1), Values.BOOL(b2), Values.BOOL(inputConnectors), Values.BOOL(outputConnectors)},st,_)
      equation
        Error.clearMessages() "Clear messages";
        true = System.regularFileExists(filename);
        workdir = Util.if_(System.directoryExists(workdir), workdir, System.pwd());
        /* Initialize FMI objects */
        (b, fmiContext, fmiInstance, fmiInfo, fmiExperimentAnnotation, fmiModelVariablesInstance, fmiModelVariablesList) = FMIExt.initializeFMIImport(filename, workdir, fmiLogLevel, inputConnectors, outputConnectors);
        true = b; /* if something goes wrong while initializing */
        fmiModelVariablesList1 = listReverse(fmiModelVariablesList);
        s1 = System.tolower(System.platform());
        str = Tpl.tplString(CodegenFMU.importFMUModelica, FMI.FMIIMPORT(s1, filename, workdir, fmiLogLevel, b2, fmiContext, fmiInstance, fmiInfo, fmiExperimentAnnotation, fmiModelVariablesInstance, fmiModelVariablesList1, inputConnectors, outputConnectors));
        pd = System.pathDelimiter();
        str1 = FMI.getFMIModelIdentifier(fmiInfo);
        str2 = FMI.getFMIType(fmiInfo);
        str3 = FMI.getFMIVersion(fmiInfo);
        outputFile = stringAppendList({workdir,pd,str1,"_",str2,"_FMU.mo"});
        filename_1 = Util.if_(b1,stringAppendList({workdir,pd,str1,"_",str2,"_FMU.mo"}),stringAppendList({str1,"_",str2,"_FMU.mo"}));
        System.writeFile(outputFile, str);
        /* Release FMI objects */
        FMIExt.releaseFMIImport(fmiModelVariablesInstance, fmiInstance, fmiContext, str3);
      then
        (cache,Values.STRING(filename_1),st);

    case (cache,env,"importFMU",{Values.STRING(filename),Values.STRING(workdir),Values.INTEGER(fmiLogLevel),Values.BOOL(b1), Values.BOOL(b2), Values.BOOL(inputConnectors), Values.BOOL(outputConnectors)},st,_)
      equation
        false = System.regularFileExists(filename);
        Error.clearMessages() "Clear messages";
        Error.addMessage(Error.FILE_NOT_FOUND_ERROR, {filename});
      then
        (cache,Values.STRING(""),st);

    case (cache,env,"importFMU",{Values.STRING(filename),Values.STRING(workdir),Values.INTEGER(fmiLogLevel),Values.BOOL(b1), Values.BOOL(b2), Values.BOOL(inputConnectors), Values.BOOL(outputConnectors)},st,_)
      then
        (cache,Values.STRING(""),st);

    case (cache,env,"iconv",{Values.STRING(str),Values.STRING(from),Values.STRING(to)},st,_)
      equation
        str = System.iconv(str,from,to);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"getCompiler",{},st,_)
      equation
        str = System.getCCompiler();
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"setCFlags",{Values.STRING(str)},st,_)
      equation
        System.setCFlags(str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"getCFlags",{},st,_)
      equation
        str = System.getCFlags();
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"setCompiler",{Values.STRING(str)},st,_)
      equation
        System.setCCompiler(str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"getCXXCompiler",{},st,_)
      equation
        str = System.getCXXCompiler();
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"setCXXCompiler",{Values.STRING(str)},st,_)
      equation
        System.setCXXCompiler(str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"setCompilerFlags",{Values.STRING(str)},st,_)
      equation
        System.setCFlags(str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"getLinker",{},st,_)
      equation
        str = System.getLinker();
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"setLinker",{Values.STRING(str)},st,_)
      equation
        System.setLinker(str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"getLinkerFlags",{},st,_)
      equation
        str = System.getLDFlags();
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"setLinkerFlags",{Values.STRING(str)},st,_)
      equation
        System.setLDFlags(str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"setCommandLineOptions",{Values.STRING(str)},st,_)
      equation
        args = System.strtok(str, " ");
        _ = Flags.readArgs(args);
      then
        (Env.emptyCache(),Values.BOOL(true),st);

    case (cache,env,"setCommandLineOptions",_,st,_)
      then (cache,Values.BOOL(false),st);

    case (cache,env,"clearCommandLineOptions",{},st,_)
      equation
        Flags.resetDebugFlags();
        Flags.resetConfigFlags();
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"clearCommandLineOptions",_,st,_)
      then (cache,Values.BOOL(false),st);

    case (cache,env,"clearDebugFlags",_,st,_)
      equation
        Flags.resetDebugFlags();
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"clearDebugFlags",_,st,_)
      then (cache,Values.BOOL(false),st);

    case (cache,env,"cd",{Values.STRING("")},st,_)
      equation
        str_1 = System.pwd();
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,"cd",{Values.STRING(str)},st,_)
      equation
        resI = System.cd(str);
        (resI == 0) = true;
        str_1 = System.pwd();
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,"cd",{Values.STRING(str)},st,_)
      equation
        failure(true = System.directoryExists(str));
        res = stringAppendList({"Error, directory ",str," does not exist,"});
      then
        (cache,Values.STRING(res),st);

    case (cache,env,"mkdir",{Values.STRING(str)},st,_)
      equation
        true = System.directoryExists(str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"mkdir",{Values.STRING(str)},st,_)
      equation
        b = Util.createDirectoryTree(str);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"remove",{Values.STRING(str)},st,_)
      equation
        b = System.removeDirectory(str);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"getVersion",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("OpenModelica")))},st,_)
      equation
        str_1 = Settings.getVersionNr();
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,"getVersion",{Values.CODE(Absyn.C_TYPENAME(path))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        str_1 = getPackageVersion(path,p);
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,"getTempDirectoryPath",{},st,_)
      equation
        str_1 = Settings.getTempDirectoryPath();
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,"system",{Values.STRING(str),Values.STRING(filename)},st,_)
      equation
        resI = System.systemCall(str,filename);
      then
        (cache,Values.INTEGER(resI),st);

    case (cache,env,"system_parallel",{Values.ARRAY(valueLst=vals),Values.INTEGER(i)},st,_)
      equation
        strs = List.map(vals, ValuesUtil.extractValueString);
        v = ValuesUtil.makeIntArray(System.systemCallParallel(strs,i));
      then
        (cache,v,st);

    case (cache,env,"timerClear",{Values.INTEGER(i)},st,_)
      equation
        System.realtimeClear(i);
      then
        (cache,Values.NORETCALL(),st);

    case (cache,env,"timerTick",{Values.INTEGER(i)},st,_)
      equation
        System.realtimeTick(i);
      then
        (cache,Values.NORETCALL(),st);

    case (cache,env,"timerTock",{Values.INTEGER(i)},st,_)
      equation
        true = System.realtimeNtick(i) > 0;
        r = System.realtimeTock(i);
      then
        (cache,Values.REAL(r),st);

    case (cache,env,"timerTock",_,st,_)
      then (cache,Values.REAL(-1.0),st);

    case (cache,env,"readFile",{Values.STRING(str)},st,_)
      equation
        str_1 = System.readFile(str);
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,"writeFile",{Values.STRING(str),Values.STRING(str1),Values.BOOL(false)},st,_)
      equation
        System.writeFile(str,str1);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"writeFile",{Values.STRING(str),Values.STRING(str1),Values.BOOL(true)},st,_)
      equation
        System.appendFile(str, str1);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"writeFile",_,st,_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"compareFilesAndMove",{Values.STRING(str1),Values.STRING(str2)},st,_)
      equation
        true = System.regularFileExists(str1);
        b = System.regularFileExists(str2) and System.fileContentsEqual(str1,str2);
        b = Debug.bcallret2(not b,System.rename,str1,str2,b);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"compareFilesAndMove",_,st,_)
      then (cache,Values.BOOL(false),st);

    case (cache,env,"readFileNoNumeric",{Values.STRING(str)},st,_)
      equation
        str_1 = System.readFileNoNumeric(str);
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,"getErrorString",{Values.BOOL(b)},st,_)
      equation
        str = Error.printMessagesStr(b);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"countMessages",_,st,_)
      equation
        i1 = Error.getNumMessages();
        i2 = Error.getNumErrorMessages();
        i3 = ErrorExt.getNumWarningMessages();
      then
        (cache,Values.TUPLE({Values.INTEGER(i1),Values.INTEGER(i2),Values.INTEGER(i3)}),st);

    case (cache,env,"clearMessages",{},st,_)
      equation
        Error.clearMessages();
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"getMessagesStringInternal",{Values.BOOL(true)},st,_)
      equation
        messages = List.unique(Error.getMessages());
        v = ValuesUtil.makeArray(List.map(messages, errorToValue));
      then
        (cache,v,st);
    
    case (cache,env,"getMessagesStringInternal",{Values.BOOL(false)},st,_)
      equation
        v = ValuesUtil.makeArray(List.map(Error.getMessages(), errorToValue));
      then
        (cache,v,st);

    case (cache,env,"getIndexReductionMethod",_,st,_)
      equation
        str = Config.getIndexReductionMethod();
      then (cache,Values.STRING(str),st);

    case (cache,env,"getAvailableIndexReductionMethods",_,st,_)
      equation
        (strs1,strs2) = Flags.getConfigOptionsStringList(Flags.INDEX_REDUCTION_METHOD);
        v1 = ValuesUtil.makeArray(List.map(strs1, ValuesUtil.makeString));
        v2 = ValuesUtil.makeArray(List.map(strs2, ValuesUtil.makeString));
        v = Values.TUPLE({v1,v2});
      then (cache,v,st);

    case (cache,env,"getMatchingAlgorithm",_,st,_)
      equation
        str = Config.getMatchingAlgorithm();
      then (cache,Values.STRING(str),st);

    case (cache,env,"getAvailableMatchingAlgorithms",_,st,_)
      equation
        (strs1,strs2) = Flags.getConfigOptionsStringList(Flags.MATCHING_ALGORITHM);
        v1 = ValuesUtil.makeArray(List.map(strs1, ValuesUtil.makeString));
        v2 = ValuesUtil.makeArray(List.map(strs2, ValuesUtil.makeString));
        v = Values.TUPLE({v1,v2});
      then (cache,v,st);

    case (cache,env,"getTearingMethod",_,st,_)
      equation
        str = Config.getTearingMethod();
      then (cache,Values.STRING(str),st);

    case (cache,env,"getAvailableTearingMethods",_,st,_)
      equation
        (strs1,strs2) = Flags.getConfigOptionsStringList(Flags.TEARING_METHOD);
        v1 = ValuesUtil.makeArray(List.map(strs1, ValuesUtil.makeString));
        v2 = ValuesUtil.makeArray(List.map(strs2, ValuesUtil.makeString));
        v = Values.TUPLE({v1,v2});
      then (cache,v,st);

    case (cache,env,"typeNameString",{Values.CODE(A=Absyn.C_TYPENAME(path=path))},st,_)
      equation
        str = Absyn.pathString(path);
      then (cache,Values.STRING(str),st);

    case (cache,env,"typeNameStrings",{Values.CODE(A=Absyn.C_TYPENAME(path=path))},st,_)
      equation
        v = ValuesUtil.makeArray(List.map(Absyn.pathToStringList(path),ValuesUtil.makeString));
      then (cache,v,st);

    case (cache,env,"generateHeader",{Values.STRING(filename)},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        str = Tpl.tplString(Unparsing.programExternalHeader, SCodeUtil.translateAbsyn2SCode(p));
        System.writeFile(filename,str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"generateHeader",_,st,_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"generateCode",{Values.CODE(Absyn.C_TYPENAME(path))},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        (cache,Util.SUCCESS()) = Static.instantiateDaeFunction(cache, env, path, false, NONE(), true);
        (cache,_,_) = cevalGenerateFunction(cache,env,p,path);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"generateCode",_,st,_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"generateEntryPoint",{Values.STRING(filename),Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str)},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        str = Tpl.tplString2(CodegenC.generateEntryPoint, path, str);
        System.writeFile(filename,str);
      then (cache,Values.BOOL(true),st);

    case (cache,env,"generateEntryPoint",_,st as GlobalScript.SYMBOLTABLE(ast = p),_)
      then (cache,Values.BOOL(false),st);

    case (cache,env,"generateSeparateCodeDependenciesMakefile",{Values.STRING(filename),Values.STRING(prefix),Values.STRING(suffix)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        (sp,st) = Interactive.symbolTableToSCode(st);
        names = List.filterMap(sp,SCode.getElementName);
        deps = Graph.buildGraph(names,buildDependencyGraphPublicImports,sp);
        strs = List.map3(sp,writeModuleDepends,prefix,suffix,deps);
        System.writeFile(filename,stringDelimitList(strs,"\n"));
      then (cache,Values.BOOL(true),st);

    case (cache,env,"generateSeparateCodeDependenciesMakefile",_,(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      then (cache,Values.BOOL(false),st);

    case (cache,env,"generateSeparateCodeDependencies",{Values.STRING(suffix)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        (sp,st) = Interactive.symbolTableToSCode(st);
        names = List.filterMap(sp,SCode.getElementName);
        
        deps = Graph.buildGraph(names,buildDependencyGraph,sp);
        namesPublic = List.map(List.select(sp, containsPublicInterface), SCode.getElementName);
        namesChanged = List.filterMap1(sp,getChangedClass,suffix);
        hashSetString = HashSetString.emptyHashSet();
        hashSetString = List.fold(namesChanged,BaseHashSet.add,hashSetString);
        // print("namesChanged: " +& stringDelimitList(namesChanged, ",") +& "\n");

        depstransposed = Graph.transposeGraph(Graph.emptyGraph(names),deps,stringEq);
        depstransposedtransitive = Graph.buildGraph(namesPublic,buildTransitiveDependencyGraph,depstransposed);
        // depstransposedtransitive = List.sort(depstransposed, compareNumberOfDependencies);

        depstransitive = Graph.transposeGraph(Graph.emptyGraph(names),depstransposedtransitive,stringEq);
        depstransitive = List.sort(depstransitive, compareNumberOfDependencies);

        depsmerged = Graph.merge(deps,depstransitive,stringEq,compareDependencyNode);
        // depsmerged = List.sort(depsmerged, compareNumberOfDependencies);

        /*
         print("Total number of modules: " +& intString(listLength(depsmerged)) +& "\n");
         str = stringDelimitList(List.map(depsmerged, transitiveDependencyString), "\n");
         print(str +& "\n");
        */

        depschanged = List.select1(depsmerged,isChanged,hashSetString);
        names = List.map(depschanged, Util.tuple21);
        // print("Files to recompile (" +& intString(listLength(depschanged)) +& "): " +& stringDelimitList(names, ",") +& "\n");
        fileNames = List.map1(names, stringAppend, suffix);
        _ = List.map(fileNames, System.removeFile);
        v = ValuesUtil.makeArray(List.map(names,ValuesUtil.makeString));
      then (cache,v,st);

    case (cache,env,"generateSeparateCodeDependencies",_,(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      then (cache,Values.META_FAIL(),st);

    case (cache,env,"generateSeparateCode",{v,Values.BOOL(b)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        (sp,st) = Interactive.symbolTableToSCode(st);
        name = getTypeNameIdent(v);
        setGlobalRoot(Global.instOnlyForcedFunctions,SOME(true));
        cl = List.getMemberOnTrue(name, sp, SCode.isClassNamed);
        (cache,env) = generateFunctions(cache,env,p,{cl},b);
        setGlobalRoot(Global.instOnlyForcedFunctions,NONE());
      then (cache,Values.BOOL(true),st);

    case (cache,env,"generateSeparateCode",{v,Values.BOOL(b)},st,_)
      equation
        (sp,st) = Interactive.symbolTableToSCode(st);
        name = getTypeNameIdent(v);
        failure(_ = List.getMemberOnTrue(name, sp, SCode.isClassNamed));
        Error.addMessage(Error.LOOKUP_ERROR, {name,"<TOP>"});
      then fail();

    case (cache,env,"generateSeparateCode",_,st,_)
      equation
        setGlobalRoot(Global.instOnlyForcedFunctions,NONE());
      then (cache,Values.BOOL(false),st);

    case (cache,env,"loadModel",{Values.CODE(Absyn.C_TYPENAME(path)),Values.ARRAY(valueLst=cvars),Values.BOOL(b),Values.STRING(str)},
          (st as GlobalScript.SYMBOLTABLE(
            ast = p,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),_) /* add path to symboltable for compiled functions
            GlobalScript.SYMBOLTABLE(p,sp,ic,iv,(path,t)::cf),
            but where to get t? */
      equation
        mp = Settings.getModelicaPath(Config.getRunningTestsuite());
        strings = List.map(cvars, ValuesUtil.extractValueString);
        /* If the user requests a custom version to parse as, set it up */
        oldLanguageStd = Config.getLanguageStandard();
        b1 = not stringEq(str,"");
        Debug.bcall1(b1,Config.setLanguageStandard,Debug.bcallret1(b1,Config.versionStringToStd,str,Config.MODELICA_LATEST() /* Unused */));
        (p,b) = loadModel({(path,strings)},mp,p,true,b);
        Debug.bcall1(b1,Config.setLanguageStandard,oldLanguageStd);
        _ = Print.getString();
        newst = GlobalScript.SYMBOLTABLE(p,NONE(),{},iv,cf,lf);
      then
        (Env.emptyCache(),Values.BOOL(b),newst);

    case (cache,env,"loadModel",Values.CODE(Absyn.C_TYPENAME(path))::_,st,_)
      equation
        pathstr = Absyn.pathString(path);
        Error.addMessage(Error.LOAD_MODEL_ERROR, {pathstr});
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"loadFile",{Values.STRING(name),Values.STRING(encoding)},
          (st as GlobalScript.SYMBOLTABLE(
            ast = p,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),_)
      equation
        name = Util.testsuiteFriendlyPath(name);
        newp = ClassLoader.loadFile(name,encoding);
        newp = Interactive.updateProgram(newp, p);
      then
        (Env.emptyCache(),Values.BOOL(true),GlobalScript.SYMBOLTABLE(newp,NONE(),ic,iv,cf,lf));

    case (cache,env,"loadFile",_,st,_)
      then (cache,Values.BOOL(false),st);

    case (cache,env,"loadFiles",{Values.ARRAY(valueLst=vals as _::_::_),Values.STRING(encoding),Values.INTEGER(i)},
          (st as GlobalScript.SYMBOLTABLE(
            ast = p,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),_)
      equation
        false = System.isRML() or Config.noProc()==1;
        strs = List.mapMap(vals,ValuesUtil.extractValueString,Util.testsuiteFriendlyPath);
        System.GC_disable();
        newps = System.launchParallelTasks(i, List.map1(strs,Util.makeTuple,encoding), loadFileThread);
        System.GC_enable();
        newp = List.fold(newps, Interactive.updateProgram, p);
      then
        (Env.emptyCache(),Values.BOOL(true),GlobalScript.SYMBOLTABLE(newp,NONE(),ic,iv,cf,lf));

    case (cache,env,"loadFiles",{Values.ARRAY(valueLst=vals),Values.STRING(encoding),Values.INTEGER(i)},
          (st as GlobalScript.SYMBOLTABLE(
            ast = p,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),_)
      equation
        strs = List.mapMap(vals,ValuesUtil.extractValueString,Util.testsuiteFriendlyPath);
        newps = List.map(List.map1(strs,Util.makeTuple,encoding), loadFileThread);
        newp = List.fold(newps, Interactive.updateProgram, p);
      then
        (Env.emptyCache(),Values.BOOL(true),GlobalScript.SYMBOLTABLE(newp,NONE(),ic,iv,cf,lf));

    case (cache,env,"loadFiles",_,st,_)
      equation
        // System.GC_enable();
      then (cache,Values.BOOL(false),st);

    case (cache,env,"alarm",{Values.INTEGER(i)},st,_)
      equation
        i = System.alarm(i);
      then (cache,Values.INTEGER(i),st);

    case (cache,env,"reloadClass",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(encoding)},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        Absyn.CLASS(info=Absyn.INFO(fileName=filename,buildTimes=Absyn.TIMESTAMP(lastEditTime=r2))) = Interactive.getPathedClassInProgram(classpath, p);
        (true,_,r1) = System.stat(filename);
        b = realEq(r1,r2);
        st = Debug.bcallret3(not b, reloadClass, filename, encoding, st, st);
      then (cache,Values.BOOL(true),st);

    case (cache,env,"reloadClass",{Values.CODE(Absyn.C_TYPENAME(classpath)),_},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        failure(_ = Interactive.getPathedClassInProgram(classpath, p));
        str = Absyn.pathString(classpath);
        Error.addMessage(Error.LOAD_MODEL_ERROR, {str});
      then (cache,Values.BOOL(false),st);

    case (cache,env,"reloadClass",_,st,_)
      then (cache,Values.BOOL(false),st);

    case (cache,env,"loadString",{Values.STRING(str),Values.STRING(name),Values.STRING(encoding)},
          (st as GlobalScript.SYMBOLTABLE(
            ast = p,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),_)
      equation
        str = Debug.bcallret3(not (encoding ==& "UTF-8"), System.iconv, str, encoding, "UTF-8", str);
        newp = Parser.parsestring(str,name);
        newp = Interactive.updateProgram(newp, p);
      then
        (Env.emptyCache(),Values.BOOL(true),GlobalScript.SYMBOLTABLE(newp,NONE(),ic,iv,cf,lf));

    case (cache,env,"loadString",_,st,_)
    then (cache,Values.BOOL(false),st);

    case (cache,env,"saveModel",{Values.STRING(filename),Values.CODE(Absyn.C_TYPENAME(classpath))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        str = Dump.unparseStr(Absyn.PROGRAM({absynClass},Absyn.TOP(),Absyn.TIMESTAMP(0.0,0.0)),true) ;
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"saveTotalModel",{Values.STRING(filename),Values.CODE(Absyn.C_TYPENAME(classpath))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        (scodeP, st) = Interactive.symbolTableToSCode(st);
        (scodeP, _) = NFSCodeFlatten.flattenClassInProgram(classpath, scodeP);
        scodeP = SCode.removeBuiltinsFromTopScope(scodeP);
        str = SCodeDump.programStr(scodeP,SCodeDump.defaultOptions);
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"save",{Values.CODE(Absyn.C_TYPENAME(className))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        (newp,filename) = Interactive.getContainedClassAndFile(className, p);
        str = Dump.unparseStr(newp,true);
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"save",{Values.CODE(Absyn.C_TYPENAME(className))},st,_)
    then (cache,Values.BOOL(false),st);

    case (cache,env,"saveAll",{Values.STRING(filename)},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        str = Dump.unparseStr(p,true);
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"help",{Values.STRING("")},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        str = Flags.printUsage();
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"help",{Values.STRING(str)},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        str = Flags.printHelp({str});
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"saveModel",{Values.STRING(name),Values.CODE(Absyn.C_TYPENAME(classpath))},
        (st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        str = Dump.unparseStr(Absyn.PROGRAM({absynClass},Absyn.TOP(),Absyn.TIMESTAMP(0.0,0.0)),true);
        Error.addMessage(Error.WRITING_FILE_ERROR, {name});
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"saveModel",{Values.STRING(name),Values.CODE(Absyn.C_TYPENAME(classpath))},st,_)
      equation
        cname = Absyn.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {cname,"global"});
      then
        (cache,Values.BOOL(false),st);

    case (cache, env, "saveTotalSCode",
        {Values.STRING(filename), Values.CODE(Absyn.C_TYPENAME(classpath))}, st, _)
      equation
        (scodeP, st) = Interactive.symbolTableToSCode(st);
        (scodeP, _) = NFSCodeFlatten.flattenClassInProgram(classpath, scodeP);
        scodeP = SCode.removeBuiltinsFromTopScope(scodeP);
        str = SCodeDump.programStr(scodeP,SCodeDump.defaultOptions);
        System.writeFile(filename, str);
      then
        (cache, Values.BOOL(true), st);

    case (cache, env, "saveTotalSCode", _, st, _)
      then (cache, Values.BOOL(false), st);

    case (cache,env,"getDocumentationAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        ((str1,str2)) = Interactive.getNamedAnnotation(classpath, p, Absyn.IDENT("Documentation"), SOME(("","")),Interactive.getDocumentationAnnotationString);
      then
        (cache,ValuesUtil.makeArray({Values.STRING(str1),Values.STRING(str2)}),st);

    case (cache,env,"addClassAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.CODE(Absyn.C_EXPRESSION(aexp))},GlobalScript.SYMBOLTABLE(p,_,ic,iv,cf,lf),_)
      equation
        p = Interactive.addClassAnnotation(Absyn.pathToCref(classpath), Absyn.NAMEDARG("annotate",aexp)::{}, p);
      then
        (cache,Values.BOOL(true),GlobalScript.SYMBOLTABLE(p,NONE(),ic,iv,cf,lf));

    case (cache,env,"addClassAnnotation",_,st as GlobalScript.SYMBOLTABLE(ast=p),_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"setDocumentationAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(str1),Values.STRING(str2)},GlobalScript.SYMBOLTABLE(p,_,ic,iv,cf,lf),_)
      equation
        nargs = List.consOnTrue(not stringEq(str1,""), Absyn.NAMEDARG("info",Absyn.STRING(str1)), {});
        nargs = List.consOnTrue(not stringEq(str2,""), Absyn.NAMEDARG("revisions",Absyn.STRING(str2)), nargs);
        aexp = Absyn.CALL(Absyn.CREF_IDENT("Documentation",{}),Absyn.FUNCTIONARGS({},nargs));
        p = Interactive.addClassAnnotation(Absyn.pathToCref(classpath), Absyn.NAMEDARG("annotate",aexp)::{}, p);
      then
        (cache,Values.BOOL(true),GlobalScript.SYMBOLTABLE(p,NONE(),ic,iv,cf,lf));

    case (cache,env,"setDocumentationAnnotation",_,st as GlobalScript.SYMBOLTABLE(ast=p),_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"getTimeStamp",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        Absyn.CLASS(info=Absyn.INFO(buildTimes=Absyn.TIMESTAMP(lastEditTime=r))) = Interactive.getPathedClassInProgram(classpath,p);
        str = System.ctime(r);
      then (cache,Values.TUPLE({Values.REAL(r),Values.STRING(str)}),st);

    case (cache,env,"getTimeStamp",_,st as GlobalScript.SYMBOLTABLE(ast=p),_)
      then
        (cache,Values.TUPLE({Values.REAL(0.0),Values.STRING("")}),st);

    case (cache,env,"isPackage",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isPackage(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"isPartial",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isPartial(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"isModel",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isModel(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"isOperator",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isOperator(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"isOperatorRecord",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isOperatorRecord(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"isOperatorFunction",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isOperatorFunction(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"isProtectedClass",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(name)},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isProtectedClass(classpath, name, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"extendsFrom",
          {Values.CODE(Absyn.C_TYPENAME(classpath)),
           Values.CODE(Absyn.C_TYPENAME(baseClassPath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        paths = Interactive.getAllInheritedClasses(classpath, p);
        b = List.applyAndFold1(paths, boolOr, Absyn.pathSuffixOfr, baseClassPath, false);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"extendsFrom",_,st as GlobalScript.SYMBOLTABLE(ast=p),_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"isExperiment",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.getNamedAnnotation(classpath, p, Absyn.IDENT("experiment"), SOME(false), hasStopTime);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"isExperiment",_,st as GlobalScript.SYMBOLTABLE(ast=p),_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"getSimulationOptions",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.REAL(startTime),Values.REAL(stopTime),Values.REAL(tolerance),Values.INTEGER(numberOfIntervals),Values.REAL(interval)},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        cr_1 = Absyn.pathToCref(classpath);
        // ignore the name of the model
        ErrorExt.setCheckpoint("getSimulationOptions");
        simOpt = GlobalScript.SIMULATION_OPTIONS(DAE.RCONST(startTime),DAE.RCONST(stopTime),DAE.ICONST(numberOfIntervals),DAE.RCONST(0.0),DAE.RCONST(tolerance),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""),DAE.BCONST(false),DAE.SCONST(""),DAE.SCONST(""));
        ErrorExt.rollBack("getSimulationOptions");
        (_, _::startTimeExp::stopTimeExp::intervalExp::toleranceExp::_) = StaticScript.getSimulationArguments(Env.emptyCache(), {},{Absyn.CREF(cr_1)},{},false,SOME(st),Prefix.NOPRE(),Absyn.dummyInfo,SOME(simOpt));
        startTime = ValuesUtil.valueReal(Util.makeValueOrDefault(Ceval.cevalSimple,startTimeExp,Values.REAL(startTime)));
        stopTime = ValuesUtil.valueReal(Util.makeValueOrDefault(Ceval.cevalSimple,stopTimeExp,Values.REAL(stopTime)));
        tolerance = ValuesUtil.valueReal(Util.makeValueOrDefault(Ceval.cevalSimple,toleranceExp,Values.REAL(tolerance)));
        Values.INTEGER(numberOfIntervals) = Util.makeValueOrDefault(Ceval.cevalSimple,intervalExp,Values.INTEGER(numberOfIntervals)); // number of intervals
        interval = Util.if_(numberOfIntervals == 0, interval, realDiv(realSub(stopTime,startTime),intReal(intMax(numberOfIntervals,1))));
        r1 = realSub(stopTime,startTime);
        r2 = realMax(interval,1e-30  /* TODO: Use real if-expressions to skip these things */);
        r = Debug.bcallret2(realGt(interval,0.0), realDiv, r1, r2, 0.0);
        numberOfIntervals = Util.if_(numberOfIntervals == 0, Util.if_(realGt(interval,0.0),realInt(realCeil(r)),0), numberOfIntervals);
      then
        (cache,Values.TUPLE({Values.REAL(startTime),Values.REAL(stopTime),Values.REAL(tolerance),Values.INTEGER(numberOfIntervals),Values.REAL(interval)}),st);

    case (cache,env,"classAnnotationExists",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.CODE(Absyn.C_TYPENAME(path))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.getNamedAnnotation(classpath, p, path, SOME(false), Util.isSome);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"getBooleanClassAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.CODE(Absyn.C_TYPENAME(path))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        Absyn.BOOL(b) = Interactive.getNamedAnnotation(classpath, p, path, NONE(), Interactive.getAnnotationExp);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"getBooleanClassAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.CODE(Absyn.C_TYPENAME(path))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        str1 = Absyn.pathString(path);
        str2 = Absyn.pathString(classpath);
        Error.addMessage(Error.CLASS_ANNOTATION_DOES_NOT_EXIST, {str1,str2});
      then fail();

    case (cache,env,"searchClassNames",{Values.STRING(str), Values.BOOL(b)},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        (_,paths) = Interactive.getClassNamesRecursive(NONE(),p,false,{});
        paths = listReverse(paths);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
        vals = searchClassNames(vals, str, b, p);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"getAvailableLibraries",{},st,_)
      equation
        mp = Settings.getModelicaPath(Config.getRunningTestsuite());
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        files = List.flatten(List.map(mps, System.moFiles));
        dirs = List.flatten(List.map(mps, System.subDirectories));
        files = List.map(List.map1(listAppend(files,dirs), System.strtok, ". "), List.first);
        files = List.sort(files,Util.strcmpBool);
        files = List.sortedUnique(files, stringEqual);
        v = ValuesUtil.makeArray(List.map(files, ValuesUtil.makeString));
      then
        (cache,v,st);

    case (cache,env,"getUses",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        (absynClass as Absyn.CLASS(restriction = _)) = Interactive.getPathedClassInProgram(classpath, p);
        uses = Interactive.getUsesAnnotation(Absyn.PROGRAM({absynClass},Absyn.TOP(),Absyn.dummyTimeStamp));
        v = ValuesUtil.makeArray(List.map(uses,makeUsesArray));
      then
        (cache,v,st);

    case (cache,env,"getDerivedClassModifierNames",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        args = Interactive.getDerivedClassModifierNames(absynClass);
        vals = List.map(args, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v,st);

    case (cache,env,"getDerivedClassModifierValue",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_TYPENAME(className))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        str = Interactive.getDerivedClassModifierValue(absynClass, className);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"getAstAsCorbaString",{Values.STRING("<interactive>")},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        Print.clearBuf();
        Dump.getAstAsCorbaString(p);
        res = Print.getString();
        Print.clearBuf();
      then
        (cache,Values.STRING(res),st);

    case (cache,env,"getAstAsCorbaString",{Values.STRING(str)},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        Print.clearBuf();
        Dump.getAstAsCorbaString(p);
        Print.writeBuf(str);
        Print.clearBuf();
        str = "Wrote result to file: " +& str;
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"getAstAsCorbaString",_,st,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"getAstAsCorbaString failed"});
      then (cache,Values.STRING(""),st);

    case (cache,env,"strtok",{Values.STRING(str),Values.STRING(token)},st,_)
      equation
        vals = List.map(System.strtok(str,token), ValuesUtil.makeString);
        i = listLength(vals);
      then (cache,Values.ARRAY(vals,{i}),st);

    case (cache,env,"stringReplace",{Values.STRING(str1),Values.STRING(str2),Values.STRING(str3)},st,_)
      equation
        str = System.stringReplace(str1, str2, str3);
      then (cache,Values.STRING(str),st);

        /* Checks the installation of OpenModelica and tries to find common errors */
    case (cache,env,"checkSettings",{},st,_)
      equation
        vars_1 = {"OPENMODELICAHOME",
                  "OPENMODELICALIBRARY",
                  "OMC_PATH",
                  "SYSTEM_PATH",
                  "OMDEV_PATH",
                  "OMC_FOUND",
                  "MODELICAUSERCFLAGS",
                  "WORKING_DIRECTORY",
                  "CREATE_FILE_WORKS",
                  "REMOVE_FILE_WORKS",
                  "OS",
                  "SYSTEM_INFO",
                  "RTLIBS",
                  "C_COMPILER",
                  "C_COMPILER_VERSION",
                  "C_COMPILER_RESPONDING",
                  "HAVE_CORBA",
                  "CONFIGURE_CMDLINE"};
        omhome = Settings.getInstallationDirectoryPath();
        omlib = Settings.getModelicaPath(Config.getRunningTestsuite());
        omcpath = omhome +& "/bin/omc" +& System.getExeExt();
        systemPath = Util.makeValueOrDefault(System.readEnv,"PATH","");
        omdev = Util.makeValueOrDefault(System.readEnv,"OMDEV","");
        omcfound = System.regularFileExists(omcpath);
        os = System.os();
        touch_file = "omc.checksettings.create_file_test";
        usercflags = Util.makeValueOrDefault(System.readEnv,"MODELICAUSERCFLAGS","");
        workdir = System.pwd();
        touch_res = 0 == System.systemCall("touch " +& touch_file, "");
        uname_res = 0 == System.systemCall("uname -a", touch_file);
        uname = System.readFile(touch_file);
        rm_res = 0 == System.systemCall("rm " +& touch_file, "");
        platform = System.platform();
        senddata = System.getRTLibs();
        gcc = System.getCCompiler();
        have_corba = Corba.haveCorba();
        gcc_res = 0 == System.systemCall(gcc +& " -v", touch_file);
        gccVersion = System.readFile(touch_file);
        _ = System.systemCall("rm " +& touch_file, "");
        confcmd = System.configureCommandLine();
        vals = {Values.STRING(omhome),
                Values.STRING(omlib),
                Values.STRING(omcpath),
                Values.STRING(systemPath),
                Values.STRING(omdev),
                Values.BOOL(omcfound),
                Values.STRING(usercflags),
                Values.STRING(workdir),
                Values.BOOL(touch_res),
                Values.BOOL(rm_res),
                Values.STRING(os),
                Values.STRING(uname),
                Values.STRING(senddata),
                Values.STRING(gcc),
                Values.STRING(gccVersion),
                Values.BOOL(gcc_res),
                Values.BOOL(have_corba),
                Values.STRING(confcmd)};
      then (cache,Values.RECORD(Absyn.IDENT("OpenModelica.Scripting.CheckSettingsResult"),vals,vars_1,-1),st);

    case (cache,env,"readSimulationResult",{Values.STRING(filename),Values.ARRAY(valueLst=cvars),Values.INTEGER(size)},st,_)
      equation
        vars_1 = List.map(cvars, ValuesUtil.printCodeVariableName);
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename_1 = Util.if_(System.strncmp("/",filename,1)==0,filename,stringAppendList({pwd,pd,filename}));
        value = ValuesUtil.readDataset(filename_1, vars_1, size);
      then
        (cache,value,st);

    case (cache,env,"readSimulationResult",_,st,_)
      equation
        Error.addMessage(Error.SCRIPT_READ_SIM_RES_ERROR, {});
      then (cache,Values.META_FAIL(),st);

    case (cache,env,"readSimulationResultSize",{Values.STRING(filename)},st,_)
      equation
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename_1 = Util.if_(System.strncmp("/",filename,1)==0,filename,stringAppendList({pwd,pd,filename}));
        i = SimulationResults.readSimulationResultSize(filename_1);
      then
        (cache,Values.INTEGER(i),st);

    case (cache,env,"readSimulationResultVars",{Values.STRING(filename)},st,_)
      equation
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename_1 = Util.if_(System.strncmp("/",filename,1)==0,filename,stringAppendList({pwd,pd,filename}));
        args = SimulationResults.readVariables(filename_1);
        vals = List.map(args, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v,st);

    case (cache,env,"compareSimulationResults",{Values.STRING(filename),Values.STRING(filename_1),Values.STRING(filename2),Values.REAL(x1),Values.REAL(x2),Values.ARRAY(valueLst=cvars)},st,_)
      equation
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename = Util.if_(System.substring(filename,1,1) ==& "/",filename,stringAppendList({pwd,pd,filename}));
        filename_1 = Util.testsuiteFriendlyPath(filename_1);
        filename_1 = Util.if_(System.substring(filename_1,1,1) ==& "/",filename_1,stringAppendList({pwd,pd,filename_1}));
        filename2 = Util.if_(System.substring(filename2,1,1) ==& "/",filename2,stringAppendList({pwd,pd,filename2}));
        vars_1 = List.map(cvars, ValuesUtil.extractValueString);
        strings = SimulationResults.cmpSimulationResults(Config.getRunningTestsuite(),filename,filename_1,filename2,x1,x2,vars_1);
        cvars = List.map(strings,ValuesUtil.makeString);
        v = ValuesUtil.makeArray(cvars);
      then
        (cache,v,st);

    case (cache,env,"compareSimulationResults",_,st,_)
      then (cache,Values.STRING("Error in compareSimulationResults"),st);

    case (cache,env,"diffSimulationResults",{Values.STRING(filename),Values.STRING(filename_1),Values.STRING(filename2),Values.REAL(reltol),Values.REAL(reltolDiffMinMax),Values.REAL(rangeDelta),Values.ARRAY(valueLst=cvars),Values.BOOL(b)},st,_)
      equation
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename = Util.if_(System.substring(filename,1,1) ==& "/",filename,stringAppendList({pwd,pd,filename}));
        filename_1 = Util.testsuiteFriendlyPath(filename_1);
        filename_1 = Util.if_(System.substring(filename_1,1,1) ==& "/",filename_1,stringAppendList({pwd,pd,filename_1}));
        filename2 = Util.if_(System.substring(filename2,1,1) ==& "/",filename2,stringAppendList({pwd,pd,filename2}));
        vars_1 = List.map(cvars, ValuesUtil.extractValueString);
        (b,strings) = SimulationResults.diffSimulationResults(Config.getRunningTestsuite(),filename,filename_1,filename2,reltol,reltolDiffMinMax,rangeDelta,vars_1,b);
        cvars = List.map(strings,ValuesUtil.makeString);
        v = ValuesUtil.makeArray(cvars);
      then
        (cache,Values.TUPLE({Values.BOOL(b),v}),st);

    case (cache,env,"diffSimulationResults",_,st,_)
      equation
        v = ValuesUtil.makeArray({});
      then (cache,Values.TUPLE({Values.BOOL(false),v}),st);

    case (cache,env,"diffSimulationResultsHtml",{Values.STRING(str),Values.STRING(filename),Values.STRING(filename_1),Values.REAL(reltol),Values.REAL(reltolDiffMinMax),Values.REAL(rangeDelta)},st,_)
      equation
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename = Util.if_(System.substring(filename,1,1) ==& "/",filename,stringAppendList({pwd,pd,filename}));
        filename_1 = Util.testsuiteFriendlyPath(filename_1);
        filename_1 = Util.if_(System.substring(filename_1,1,1) ==& "/",filename_1,stringAppendList({pwd,pd,filename_1}));
        str = SimulationResults.diffSimulationResultsHtml(Config.getRunningTestsuite(),filename,filename_1,reltol,reltolDiffMinMax,rangeDelta,str);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"diffSimulationResultsHtml",_,st,_)
      then (cache,Values.STRING(""),st);

    case (cache,env,"checkTaskGraph",{Values.STRING(filename),Values.STRING(filename_1)},st,_)
      equation
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename = Util.if_(System.substring(filename,1,1) ==& "/",filename,stringAppendList({pwd,pd,filename}));
        filename_1 = Util.if_(System.substring(filename_1,1,1) ==& "/",filename_1,stringAppendList({pwd,pd,filename_1}));
        strings = TaskGraphResults.checkTaskGraph(filename, filename_1);
        cvars = List.map(strings,ValuesUtil.makeString);
        v = ValuesUtil.makeArray(cvars);
      then (cache,v,st);
    
    case (cache,env,"checkTaskGraph",_,st,_)
      then (cache,Values.STRING("Error in checkTaskGraph"),st);
        
    case (cache,env,"getPlotSilent",{},st,_)
      equation
        b = Config.getPlotSilent();
      then
        (cache,Values.BOOL(b),st);

    //plotAll(model)
    case (cache,env,"plotAll",
        {
          Values.BOOL(externalWindow),
          Values.STRING(filename),
          Values.STRING(title),
          Values.BOOL(grid),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.ARRAY(valueLst={Values.REAL(x1),Values.REAL(x2)}),
          Values.ARRAY(valueLst={Values.REAL(y1),Values.REAL(y2)}),
          Values.REAL(curveWidth),
          Values.INTEGER(curveStyle),
          Values.STRING(legendPosition)
        },
        st,
        _)
      equation
        // check if plot is set to silent or not
        false = Config.getPlotSilent();
        // get OPENMODELICAHOME
        omhome = Settings.getInstallationDirectoryPath();
        // get the simulation filename
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        pd = System.pathDelimiter();
        // create absolute path of simulation result file
        str1 = System.pwd() +& pd +& filename;
        s1 = Util.if_(System.os() ==& "Windows_NT", ".exe", "");
        filename = Util.if_(System.regularFileExists(str1), str1, filename);
        // create the path till OMPlot
        str2 = stringAppendList({omhome,pd,"bin",pd,"OMPlot",s1});
        // create the list of arguments for OMPlot
        str3 = "--filename=\"" +& filename +& "\" --title=\"" +& title +& "\" --grid=" +& boolString(grid) +& " --plotAll --logx=" +& boolString(logX) +& " --logy=" +& boolString(logY) +& " --xlabel=\"" +& xLabel +& "\" --ylabel=\"" +& yLabel +& "\" --xrange=" +& realString(x1) +& ":" +& realString(x2) +& " --yrange=" +& realString(y1) +& ":" +& realString(y2) +& " --new-window=" +& boolString(externalWindow) +& " --curve-width=" +& realString(curveWidth) +& " --curve-style=" +& intString(curveStyle) +& " --legend-position=\"" +& legendPosition +& "\"";
        call = stringAppendList({"\"",str2,"\""," ",str3});
        0 = System.spawnCall(str2, call);
      then
        (cache,Values.BOOL(true),st);

    /* in case plot is set to silent */
    case (cache,env,"plotAll",
        {
          Values.BOOL(externalWindow),
          Values.STRING(filename),
          Values.STRING(title),
          Values.BOOL(grid),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.ARRAY(valueLst={Values.REAL(x1),Values.REAL(x2)}),
          Values.ARRAY(valueLst={Values.REAL(y1),Values.REAL(y2)}),
          Values.REAL(curveWidth),
          Values.INTEGER(curveStyle),
          Values.STRING(legendPosition)
        },
        st,
        _)
      equation
        // check if plot is set to silent or not
        true = Config.getPlotSilent();
        // get the simulation filename
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        pd = System.pathDelimiter();
        // create absolute path of simulation result file
        str1 = System.pwd() +& pd +& filename;
        filename = Util.if_(System.regularFileExists(str1), str1, filename);
        gridStr = boolString(grid);
        logXStr = boolString(logX);
        logYStr = boolString(logY);
        x1Str = realString(x1);
        x2Str = realString(x2);
        y1Str = realString(y1);
        y2Str = realString(y2);
        curveWidthStr = realString(curveWidth);
        curveStyleStr = intString(curveStyle);
        args = {"_omc_PlotResult",filename,title,gridStr,"plotAll",logXStr,logYStr,xLabel,yLabel,x1Str,x2Str,y1Str,y2Str,curveWidthStr,curveStyleStr,legendPosition};
        vals = List.map(args, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v,st);

    case (cache,env,"plotAll",_,st,_)
      then (cache,Values.BOOL(false),st);

    // plot(x, model)
    case (cache,env,"plot",
        {
          Values.ARRAY(valueLst = cvars),
          Values.BOOL(externalWindow),
          Values.STRING(filename),
          Values.STRING(title),
          Values.BOOL(grid),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.ARRAY(valueLst={Values.REAL(x1),Values.REAL(x2)}),
          Values.ARRAY(valueLst={Values.REAL(y1),Values.REAL(y2)}),
          Values.REAL(curveWidth),
          Values.INTEGER(curveStyle),
          Values.STRING(legendPosition)
        },
        st,_)
      equation
        // check if plot is set to silent or not
        false = Config.getPlotSilent();
        // get the variables list
        vars_1 = List.map(cvars, ValuesUtil.printCodeVariableName);
        // seperate the variables
        str = stringDelimitList(vars_1,"\" \"");
        // get OPENMODELICAHOME
        omhome = Settings.getInstallationDirectoryPath();
        // get the simulation filename
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        pd = System.pathDelimiter();
        // create absolute path of simulation result file
        str1 = System.pwd() +& pd +& filename;
        s1 = Util.if_(System.os() ==& "Windows_NT", ".exe", "");
        filename = Util.if_(System.regularFileExists(str1), str1, filename);
        // create the path till OMPlot
        str2 = stringAppendList({omhome,pd,"bin",pd,"OMPlot",s1});
        // create the list of arguments for OMPlot
        str3 = "--filename=\"" +& filename +& "\" --title=\"" +& title +& "\" --grid=" +& boolString(grid) +& " --plot --logx=" +& boolString(logX) +& " --logy=" +& boolString(logY) +& " --xlabel=\"" +& xLabel +& "\" --ylabel=\"" +& yLabel +& "\" --xrange=" +& realString(x1) +& ":" +& realString(x2) +& " --yrange=" +& realString(y1) +& ":" +& realString(y2) +& " --new-window=" +& boolString(externalWindow) +& " --curve-width=" +& realString(curveWidth) +& " --curve-style=" +& intString(curveStyle) +& " --legend-position=\"" +& legendPosition +& "\" \"" +& str +& "\"";
        call = stringAppendList({"\"",str2,"\""," ",str3});
        0 = System.spawnCall(str2, call);
      then
        (cache,Values.BOOL(true),st);

    /* in case plot is set to silent */
    case (cache,env,"plot",
        {
          Values.ARRAY(valueLst = cvars),
          Values.BOOL(externalWindow),
          Values.STRING(filename),
          Values.STRING(title),
          Values.BOOL(grid),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.ARRAY(valueLst={Values.REAL(x1),Values.REAL(x2)}),
          Values.ARRAY(valueLst={Values.REAL(y1),Values.REAL(y2)}),
          Values.REAL(curveWidth),
          Values.INTEGER(curveStyle),
          Values.STRING(legendPosition)
        },
        st,_)
      equation
        // check if plot is set to silent or not
        true = Config.getPlotSilent();
        // get the variables list
        vars_1 = List.map(cvars, ValuesUtil.printCodeVariableName);
        // seperate the variables
        str = stringDelimitList(vars_1,"\" \"");
        // get the simulation filename
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        pd = System.pathDelimiter();
        // create absolute path of simulation result file
        str1 = System.pwd() +& pd +& filename;
        filename = Util.if_(System.regularFileExists(str1), str1, filename);
        gridStr = boolString(grid);
        logXStr = boolString(logX);
        logYStr = boolString(logY);
        x1Str = realString(x1);
        x2Str = realString(x2);
        y1Str = realString(y1);
        y2Str = realString(y2);
        curveWidthStr = realString(curveWidth);
        curveStyleStr = intString(curveStyle);
        args = {"_omc_PlotResult",filename,title,gridStr,"plot",logXStr,logYStr,xLabel,yLabel,x1Str,x2Str,y1Str,y2Str,curveWidthStr,curveStyleStr,legendPosition};
        args = listAppend(args, vars_1);
        vals = List.map(args, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v,st);

    case (cache,env,"plot",_,st,_)
      then
        (cache,Values.BOOL(false),st);

    // visualize2
    case (cache,env,"visualize",
        {
          Values.CODE(Absyn.C_TYPENAME(className)),
          Values.BOOL(externalWindow),
          Values.STRING(filename)
        },(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        // get OPENMODELICAHOME
        omhome = Settings.getInstallationDirectoryPath();
        // get the simulation filename
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        pd = System.pathDelimiter();
        // create absolute path of simulation result file
        str = System.pwd() +& pd +& filename;
        filename = Util.if_(System.regularFileExists(str), str, filename);
        (visvars,visvar_str) = Interactive.getElementsOfVisType(className, p);
        // write the visualizing objects to the file
        str1 = System.pwd() +& pd +& Absyn.pathString(className) +& ".visualize";
        System.writeFile(str1, visvar_str);
        s1 = Util.if_(System.os() ==& "Windows_NT", ".exe", "");
        // create the path till OMVisualize
        str2 = stringAppendList({omhome,pd,"bin",pd,"OMVisualize",s1});
        // create the list of arguments for OMVisualize
        str3 = "--visualizationfile=\"" +& str1 +& "\" --simulationfile=\"" +& filename +& "\"" +& " --new-window=" +& boolString(externalWindow);
        call = stringAppendList({"\"",str2,"\""," ",str3});

        0 = System.spawnCall(str2, call);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"visualize",_,st,_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"val",{cvar,Values.REAL(timeStamp),Values.STRING("<default>")},st,_)
      equation
        (cache,Values.STRING(filename),_) = Ceval.ceval(cache,env,buildCurrentSimulationResultExp(), true, SOME(st),msg, 0);
        varNameStr = ValuesUtil.printCodeVariableName(cvar);
        val = SimulationResults.val(filename,varNameStr,timeStamp);
      then (cache,Values.REAL(val),st);

    case (cache,env,"val",{cvar,Values.REAL(timeStamp),Values.STRING(filename)},st,_)
      equation
        false = stringEq(filename,"<default>");
        varNameStr = ValuesUtil.printCodeVariableName(cvar);
        val = SimulationResults.val(filename,varNameStr,timeStamp);
      then (cache,Values.REAL(val),st);

    case (cache,env,"closeSimulationResultFile",_,st,_)
      equation
        SimulationResults.close();
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"getAlgorithmCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = listLength(getAlgorithms(absynClass));
      then
        (cache,Values.INTEGER(n),st);

    case (cache,env,"getAlgorithmCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,env,"getNthAlgorithm",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthAlgorithm(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"getNthAlgorithm",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,env,"getInitialAlgorithmCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = listLength(getInitialAlgorithms(absynClass));
      then
        (cache,Values.INTEGER(n),st);

    case (cache,env,"getInitialAlgorithmCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,env,"getNthInitialAlgorithm",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthInitialAlgorithm(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"getNthInitialAlgorithm",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,env,"getAlgorithmItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getAlgorithmItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);

    case (cache,env,"getAlgorithmItemsCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,env,"getNthAlgorithmItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthAlgorithmItem(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"getNthAlgorithmItem",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,env,"getInitialAlgorithmItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getInitialAlgorithmItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);

    case (cache,env,"getInitialAlgorithmItemsCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,env,"getNthInitialAlgorithmItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthInitialAlgorithmItem(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"getNthInitialAlgorithmItem",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,env,"getEquationCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = listLength(getEquations(absynClass));
      then
        (cache,Values.INTEGER(n),st);

    case (cache,env,"getEquationCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,env,"getNthEquation",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthEquation(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"getNthEquation",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,env,"getInitialEquationCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = listLength(getInitialEquations(absynClass));
      then
        (cache,Values.INTEGER(n),st);

    case (cache,env,"getInitialEquationCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,env,"getNthInitialEquation",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthInitialEquation(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"getNthInitialEquation",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,env,"getEquationItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getEquationItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);

    case (cache,env,"getEquationItemsCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,env,"getNthEquationItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthEquationItem(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"getNthEquationItem",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,env,"getInitialEquationItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getInitialEquationItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);

    case (cache,env,"getInitialEquationItemsCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,env,"getNthInitialEquationItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthInitialEquationItem(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"getNthInitialEquationItem",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,env,"getAnnotationCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getAnnotationCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);

    case (cache,env,"getAnnotationCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,env,"getNthAnnotationString",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthAnnotationString(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"getNthAnnotationString",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,env,"getImportCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getImportCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);

    case (cache,env,"getImportCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,env,"getNthImport",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        vals = getNthImport(absynClass, n);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"getNthImport",_,st,_) then (cache,ValuesUtil.makeArray({}),st);

    // plotParametric
    case (cache,env,"plotParametric",
        {
          cvar,
          cvar2,
          Values.BOOL(externalWindow),
          Values.STRING(filename),
          Values.STRING(title),
          Values.BOOL(grid),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.ARRAY(valueLst={Values.REAL(x1),Values.REAL(x2)}),
          Values.ARRAY(valueLst={Values.REAL(y1),Values.REAL(y2)}),
          Values.REAL(curveWidth),
          Values.INTEGER(curveStyle),
          Values.STRING(legendPosition)
        },
        st,_)
      equation
        // check if plot is set to silent or not
        false = Config.getPlotSilent();
        // get the variables
        str = ValuesUtil.printCodeVariableName(cvar) +& "\" \"" +& ValuesUtil.printCodeVariableName(cvar2);
        // get OPENMODELICAHOME
        omhome = Settings.getInstallationDirectoryPath();
        // get the simulation filename
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        pd = System.pathDelimiter();
        // create absolute path of simulation result file
        str1 = System.pwd() +& pd +& filename;
        s1 = Util.if_(System.os() ==& "Windows_NT", ".exe", "");
        filename = Util.if_(System.regularFileExists(str1), str1, filename);
        // create the path till OMPlot
        str2 = stringAppendList({omhome,pd,"bin",pd,"OMPlot",s1});
        // create the list of arguments for OMPlot
        str3 = "--filename=\"" +& filename +& "\" --title=\"" +& title +& "\" --grid=" +& boolString(grid) +& " --plotParametric --logx=" +& boolString(logX) +& " --logy=" +& boolString(logY) +& " --xlabel=\"" +& xLabel +& "\" --ylabel=\"" +& yLabel +& "\" --xrange=" +& realString(x1) +& ":" +& realString(x2) +& " --yrange=" +& realString(y1) +& ":" +& realString(y2) +& " --new-window=" +& boolString(externalWindow) +& " --curve-width=" +& realString(curveWidth) +& " --curve-style=" +& intString(curveStyle) +& " --legend-position=\"" +& legendPosition +& "\" \"" +& str +& "\"";
        call = stringAppendList({"\"",str2,"\""," ",str3});
        0 = System.spawnCall(str2, call);
      then
        (cache,Values.BOOL(true),st);

    /* in case plot is set to silent */
    case (cache,env,"plotParametric",
        {
          cvar,
          cvar2,
          Values.BOOL(externalWindow),
          Values.STRING(filename),
          Values.STRING(title),
          Values.BOOL(grid),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.ARRAY(valueLst={Values.REAL(x1),Values.REAL(x2)}),
          Values.ARRAY(valueLst={Values.REAL(y1),Values.REAL(y2)}),
          Values.REAL(curveWidth),
          Values.INTEGER(curveStyle),
          Values.STRING(legendPosition)
        },
        st,_)
      equation
        // check if plot is set to silent or not
        true = Config.getPlotSilent();
        // get the variables
        str = ValuesUtil.printCodeVariableName(cvar);
        str3 = ValuesUtil.printCodeVariableName(cvar2);
        // get the simulation filename
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        pd = System.pathDelimiter();
        // create absolute path of simulation result file
        str1 = System.pwd() +& pd +& filename;
        filename = Util.if_(System.regularFileExists(str1), str1, filename);
        gridStr = boolString(grid);
        logXStr = boolString(logX);
        logYStr = boolString(logY);
        x1Str = realString(x1);
        x2Str = realString(x2);
        y1Str = realString(y1);
        y2Str = realString(y2);
        curveWidthStr = realString(curveWidth);
        curveStyleStr = intString(curveStyle);
        args = {"_omc_PlotResult",filename,title,gridStr,"plotParametric",logXStr,logYStr,xLabel,yLabel,x1Str,x2Str,y1Str,y2Str,curveWidthStr,curveStyleStr,legendPosition,str,str3};
        vals = List.map(args, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v,st);

    case (cache,env,"plotParametric",_,st,_)
      then (cache,Values.BOOL(false),st);

    case (cache,env,"echo",{v as Values.BOOL(bval)},st,_)
      equation
        setEcho(bval);
      then (cache,v,st);

    case (cache,env,"strictRMLCheck",_,st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        _ = List.map1r(List.map(Interactive.getFunctionsInProgram(p), SCodeUtil.translateClass), MetaUtil.strictRMLCheck, true);
        str = Error.printMessagesStr(false);
        v = Values.STRING(str);
      then (cache,v,st);

    case (cache,env,"dumpXMLDAE",vals,st,_)
      equation
        (cache,st,xml_filename) = dumpXMLDAE(cache,env,vals,st, msg);
      then
        (cache,ValuesUtil.makeTuple({Values.BOOL(true),Values.STRING(xml_filename)}),st);

    case (cache,env,"dumpXMLDAE",_,st,_)
      then 
        (cache,ValuesUtil.makeTuple({Values.BOOL(false),Values.STRING("")}),st);

    case (cache,env,"solveLinearSystem",{Values.ARRAY(valueLst=vals),v,Values.ENUM_LITERAL(index=1 /*dgesv*/),Values.ARRAY(valueLst={Values.INTEGER(-1)})},st,_)
      equation
        (realVals,i) = System.dgesv(List.map(vals,ValuesUtil.arrayValueReals),ValuesUtil.arrayValueReals(v));
        v = ValuesUtil.makeArray(List.map(realVals,ValuesUtil.makeReal));
      then (cache,Values.TUPLE({v,Values.INTEGER(i)}),st);

    case (cache,env,"solveLinearSystem",{Values.ARRAY(valueLst=vals),v,Values.ENUM_LITERAL(index=2 /*lpsolve55*/),Values.ARRAY(valueLst=vals2)},st,_)
      equation
        (realVals,i) = System.lpsolve55(List.map(vals,ValuesUtil.arrayValueReals),ValuesUtil.arrayValueReals(v),List.map(vals2,ValuesUtil.valueInteger));
        v = ValuesUtil.makeArray(List.map(realVals,ValuesUtil.makeReal));
      then (cache,Values.TUPLE({v,Values.INTEGER(i)}),st);

    case (cache,env,"solveLinearSystem",{_,v,_,_},st,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Unknown input to solveLinearSystem scripting function"});
      then (cache,Values.TUPLE({v,Values.INTEGER(-1)}),st);

    case (cache,env,"numProcessors",{},st,_)
      equation
        i = Config.noProc();
      then (cache,Values.INTEGER(i),st);

    case (cache,env,"runScript",{Values.STRING(str)},st,_)
      equation
        str = Util.testsuiteFriendlyPath(str);
        istmts = Parser.parseexp(str);
        (res,newst) = Interactive.evaluate(istmts, st, true);
      then
        (cache,Values.STRING(res),newst);

    case (cache,env,"runScript",_,st,_)
      then (cache,Values.STRING("Failed"),st);

    case (cache,env,"runScriptParallel",{Values.ARRAY(valueLst=vals),Values.INTEGER(i),Values.BOOL(true)},st,_)
      equation
        strs = List.map(vals,ValuesUtil.extractValueString);
        blst = System.launchParallelTasks(i, List.map1(strs, Util.makeTuple, st), Interactive.evaluateFork);
        v = ValuesUtil.makeArray(List.map(blst, ValuesUtil.makeBoolean));
      then (cache,v,st);

    case (cache,env,"runScriptParallel",{Values.ARRAY(valueLst=vals),Values.INTEGER(i),Values.BOOL(false)},st,_)
      equation
        strs = List.map(vals,ValuesUtil.extractValueString);
        strs = List.map1r(strs, stringAppend, stringAppend(Settings.getInstallationDirectoryPath(),"/bin/omc "));
        is = System.systemCallParallel(strs,i);
        v = ValuesUtil.makeArray(List.map(List.map1(is,intEq,0), ValuesUtil.makeBoolean));
      then (cache,v,st);

    case (cache,env,"runScriptParallel",{Values.ARRAY(valueLst=vals),_,_},st,_)
      equation
        v = ValuesUtil.makeArray(List.fill(Values.BOOL(false), listLength(vals)));
      then (cache,v,st);

    case (cache,env,"exit",{Values.INTEGER(i)},st,_)
      equation
        System.exit(i);
        /* Cannot reach here */
      then fail();

    case (cache,env,"getMemorySize",{},st,_)
      equation
        r = System.getMemorySize();
        v = Values.REAL(r);
      then (cache,v,st);

 end matchcontinue;
end cevalInteractiveFunctions2;


protected function getSimulationExtension
input String inString;
input String inString2;
output String outString;
algorithm
  outString:=match(inString,inString2)
  local
    case ("Cpp","WIN32")
       then ".bat";
    case ("Cpp","WIN64")
       then ".bat";
    else
  then System.getExeExt(); 
  end match;
 end getSimulationExtension;    


protected function sconstToString
"@author: adrpo
  Transform an DAE.SCONST into a string.
  Fails if the given DAE.Exp is not a DAE.SCONST."
  input DAE.Exp exp;
  output String str;
algorithm
  DAE.SCONST(str) := exp;
end sconstToString;

protected function setEcho
  input Boolean echo;
algorithm
  _ := match (echo)
    local
    case (true)
      equation
        Settings.setEcho(1);
      then
        ();
    case (false)
      equation
        Settings.setEcho(0);
      then
        ();
  end match;
end setEcho;

public function getIncidenceMatrix " author: adrpo
 translates a model and returns the incidence matrix"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  input String filenameprefix;
  output Env.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
  output String outString;
algorithm
  (outCache,outValue,outInteractiveSymbolTable,outString):=
  match (inCache,inEnv,className,inInteractiveSymbolTable,inMsg,filenameprefix)
    local
      String filename,file_dir, str;
      list<SCode.Element> p_1;
      DAE.DAElist dae_1,dae;
      list<Env.Frame> env;
      list<GlobalScript.InstantiatedClass> ic_1,ic;
      BackendDAE.BackendDAE dlow;
      Absyn.ComponentRef a_cref;
      GlobalScript.SymbolTable st;
      Absyn.Program p;
      list<GlobalScript.Variable> iv;
      list<GlobalScript.CompiledCFunction> cf;
      Absyn.Msg msg;
      Env.Cache cache;
      String flatModelicaStr,description;

    case (cache,env,_,(st as GlobalScript.SYMBOLTABLE(ast = p,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg,_) /* mo file directory */
      equation
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env,_,dae_1) =
        Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,p_1,className);
        dae  = DAEUtil.transformationsBeforeBackend(cache,env,dae_1);
        description = DAEUtil.daeDescription(dae);
        ic_1 = Interactive.addInstantiatedClass(ic, GlobalScript.INSTCLASS(className,dae,env));
        a_cref = Absyn.pathToCref(className);
        file_dir = getFileDir(a_cref, p);
        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        dlow = FindZeroCrossings.findZeroCrossings(dlow);
        flatModelicaStr = DAEDump.dumpStr(dae,Env.getFunctionTree(cache));
        flatModelicaStr = stringAppend("OldEqStr={'", flatModelicaStr);
        flatModelicaStr = System.stringReplace(flatModelicaStr, "\n", "%##%");
        flatModelicaStr = System.stringReplace(flatModelicaStr, "%##%", "','");
        flatModelicaStr = stringAppend(flatModelicaStr,"'};");
        filename = DAEQuery.writeIncidenceMatrix(dlow, filenameprefix, flatModelicaStr);
        str = stringAppend("The equation system was dumped to Matlab file:", filename);
      then
        (cache,Values.STRING(str),st,file_dir);
  end match;
end getIncidenceMatrix;

public function runFrontEnd
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Boolean relaxedFrontEnd "Do not check for illegal simulation models, so we allow instantation of packages, etc";
  output Env.Cache cache;
  output Env.Env env;
  output DAE.DAElist dae;
  output GlobalScript.SymbolTable st;
algorithm
  // add program to the cache so it can be used to lookup modelica:// 
  // URIs in external functions IncludeDirectory/LibraryDirectory
  cache := Env.setProgramInCache(inCache, Interactive.getSymbolTableAST(inInteractiveSymbolTable));
  (cache,env,dae,st) := runFrontEndWork(cache,inEnv,className,inInteractiveSymbolTable,relaxedFrontEnd,Error.getNumErrorMessages());
end runFrontEnd;

protected function runFrontEndWork
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Boolean relaxedFrontEnd "Do not check for illegal simulation models, so we allow instantation of packages, etc";
  input Integer numError;
  output Env.Cache cache;
  output Env.Env env;
  output DAE.DAElist dae;
  output GlobalScript.SymbolTable st;
algorithm
  (cache,env,dae,st) := matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,relaxedFrontEnd,numError)
    local
      Absyn.Restriction restriction;
      Absyn.Class absynClass;
      String str,re;
      Option<SCode.Program> fp;
      SCode.Program scodeP, scodePNew, scode_builtin;
      list<GlobalScript.InstantiatedClass> ic,ic_1;
      Absyn.Program p,ptot,p_builtin;
      list<GlobalScript.Variable> iv;
      list<GlobalScript.CompiledCFunction> cf;
      list<GlobalScript.LoadedFile> lf;
      NFSCodeEnv.Env senv;
      NFEnv.Env nfenv;
      DAE.FunctionTree funcs;

    case (_, _, _, GlobalScript.SYMBOLTABLE(p, fp, ic, iv, cf, lf), _, _)
      equation
        true = Flags.isSet(Flags.SCODE_INST);
        scodeP = SCodeUtil.translateAbsyn2SCode(p);
        // remove extends Modelica.Icons.*
        //scodeP = SCodeSimplify.simplifyProgram(scodeP);

        p_builtin = Builtin.getInitialFunctions();
        scode_builtin = SCodeUtil.translateAbsyn2SCode(p_builtin);

        nfenv = NFEnv.buildInitialEnv(scodeP, scode_builtin);
        (dae, funcs) = NFInst.instClass(className, nfenv);

        cache = Env.emptyCache();
        cache = Env.setCachedFunctionTree(cache, funcs);
        env = Env.emptyEnv;
        ic_1 = Interactive.addInstantiatedClass(ic,
          GlobalScript.INSTCLASS(className, dae, env));
        st = GlobalScript.SYMBOLTABLE(p, fp, ic_1, iv, cf, lf);
      then
        (cache, env, dae, st);

    case (cache,env,_,GlobalScript.SYMBOLTABLE(p,fp,ic,iv,cf,lf),_,_)
      equation
        false = Flags.isSet(Flags.SCODE_INST);
        str = Absyn.pathString(className);
        (absynClass as Absyn.CLASS(restriction = restriction)) = Interactive.getPathedClassInProgram(className, p);
        re = Absyn.restrString(restriction);
        Error.assertionOrAddSourceMessage(relaxedFrontEnd or not (Absyn.isFunctionRestriction(restriction) or Absyn.isPackageRestriction(restriction)),
          Error.INST_INVALID_RESTRICTION,{str,re},Absyn.dummyInfo);
        (p,true) = loadModel(Interactive.getUsesAnnotationOrDefault(Absyn.PROGRAM({absynClass},Absyn.TOP(),Absyn.dummyTimeStamp)),Settings.getModelicaPath(Config.getRunningTestsuite()),p,false,true);

        //System.stopTimer();
        //print("\nExists+Dependency: " +& realString(System.getTimerIntervalTime()));

        //System.startTimer();
        //print("\nAbsyn->SCode");

        scodeP = SCodeUtil.translateAbsyn2SCode(p);

        // TODO: Why not simply get the whole thing from the cached SCode? It's faster, just need to stop doing the silly Dependency stuff.

        //System.stopTimer();
        //print("\nAbsyn->SCode: " +& realString(System.getTimerIntervalTime()));

        //System.startTimer();
        //print("\nInst.instantiateClass");

        (cache,env,_,dae) = Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,scodeP,className);

        //System.stopTimer();
        //print("\nInst.instantiateClass: " +& realString(System.getTimerIntervalTime()));

        // adrpo: do not add it to the instantiated classes, it just consumes memory for nothing.
        ic_1 = ic;
        // ic_1 = Interactive.addInstantiatedClass(ic, GlobalScript.INSTCLASS(className,dae,env));
      
      then (cache,env,dae,GlobalScript.SYMBOLTABLE(p,fp,ic_1,iv,cf,lf));

    case (cache,env,_,st as GlobalScript.SYMBOLTABLE(ast=p),_,_)
      equation
        str = Absyn.pathString(className);
        failure(_ = Interactive.getPathedClassInProgram(className, p));
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then fail();

    case (cache,env,_,st,_,_)
      equation
        str = Absyn.pathString(className);
        true = Error.getNumErrorMessages() == numError;
        str = "Instantiation of " +& str +& " failed with no error message.";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end runFrontEndWork;

protected function translateModel " author: x02lucpo
 translates a model into cpp code and writes also a makefile"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output Env.Cache outCache;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  (outCache,outInteractiveSymbolTable,outBackendDAE,outStringLst,outFileDir,resultValues):=
  match (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix,addDummy,inSimSettingsOpt)
    local
      Env.Cache cache;
      list<Env.Frame> env;
      BackendDAE.BackendDAE indexed_dlow;
      GlobalScript.SymbolTable st;
      list<String> libs;
      String file_dir, fileNamePrefix;
      Absyn.Program p;

    case (cache,env,_,st as GlobalScript.SYMBOLTABLE(ast=p),fileNamePrefix,_,_)
      equation
        (cache, st, indexed_dlow, libs, file_dir, resultValues) =
          SimCodeMain.translateModel(cache,env,className,st,fileNamePrefix,addDummy,inSimSettingsOpt,Absyn.FUNCTIONARGS({},{}));
      then
        (cache,st,indexed_dlow,libs,file_dir,resultValues);

  end match;
end translateModel;

/*protected function translateModelCPP " author: x02lucpo
 translates a model into cpp code and writes also a makefile"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output Env.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  (outCache,outValue,outInteractiveSymbolTable,outBackendDAE,outStringLst,outFileDir,resultValues):=
  match (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix,addDummy,inSimSettingsOpt)
    local
      Env.Cache cache;
      list<Env.Frame> env;
      BackendDAE.BackendDAE indexed_dlow;
      GlobalScript.SymbolTable st;
      list<String> libs;
      Values.Value outValMsg;
      String file_dir, fileNamePrefix;

    case (cache,env,className,st,fileNamePrefix,addDummy,inSimSettingsOpt)
      equation
        (cache, outValMsg, st, indexed_dlow, libs, file_dir, resultValues) =
          SimCodeUtil.translateModelCPP(cache,env,className,st,fileNamePrefix,addDummy,inSimSettingsOpt);
      then
        (cache,outValMsg,st,indexed_dlow,libs,file_dir,resultValues);
  end match;
end translateModelCPP;*/

protected function translateModelFMU " author: Frenkel TUD
 translates a model into cpp code and writes also a makefile"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output Env.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable):=
  match (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix,addDummy,inSimSettingsOpt)
    local
      Env.Cache cache;
      list<Env.Frame> env;
      BackendDAE.BackendDAE indexed_dlow;
      GlobalScript.SymbolTable st;
      list<String> libs;
      Values.Value outValMsg;
      String file_dir, fileNamePrefix, str;
    case (cache,env,_,st,fileNamePrefix,_,_) /* mo file directory */
      equation
        (cache, outValMsg, st, indexed_dlow, libs, file_dir, _) =
          SimCodeMain.translateModelFMU(cache,env,className,st,fileNamePrefix,addDummy,inSimSettingsOpt);

        // compile
        fileNamePrefix = stringAppend(fileNamePrefix,"_FMU");
        compileModel(fileNamePrefix , libs, file_dir, "");

      then
        (cache,outValMsg,st);
    case (cache,env,_,st,fileNamePrefix,_,_) /* mo file directory */
      equation
         str = Error.printMessagesStr(false);
      then
        (cache,ValuesUtil.makeArray({Values.STRING("translateModelFMU error."),Values.STRING(str)}),st);
  end match;
end translateModelFMU;


protected function translateModelXML " author: Alachew
 translates a model into XML code "
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output Env.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable):=
  match (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix,addDummy,inSimSettingsOpt)
    local
      Env.Cache cache;
      list<Env.Frame> env;
      BackendDAE.BackendDAE indexed_dlow;
      GlobalScript.SymbolTable st;
      list<String> libs;
      Values.Value outValMsg;
      String file_dir, fileNamePrefix, str;
    case (cache,env,_,st,fileNamePrefix,_,_) /* mo file directory */
      equation
        (cache, outValMsg, st, indexed_dlow, libs, file_dir, _) =
          SimCodeMain.translateModelXML(cache,env,className,st,fileNamePrefix,addDummy,inSimSettingsOpt);
      then
        (cache,outValMsg,st);
    case (cache,env,_,st,fileNamePrefix,_,_) /* mo file directory */
      equation
         str = Error.printMessagesStr(false);
      then
        (cache,ValuesUtil.makeArray({Values.STRING("translateModelXML error."),Values.STRING(str)}),st);
  end match;
end translateModelXML;


public function translateGraphics "function: translates the graphical annotations from old to new version"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable) :=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg)
    local
      list<Env.Frame> env;
      list<GlobalScript.InstantiatedClass> ic;
      GlobalScript.SymbolTable st;
      Absyn.Program p;
      list<GlobalScript.Variable> iv;
      list<GlobalScript.CompiledCFunction> cf;
      Absyn.Msg msg;
      Env.Cache cache;
      list<GlobalScript.LoadedFile> lf;
      Absyn.TimeStamp ts;
      String errorMsg,retStr,s1;
      Absyn.Class cls, refactoredClass;
      Absyn.Within within_;
      Absyn.Program p1;
      Boolean strEmpty;

    case (cache,env,_,(st as GlobalScript.SYMBOLTABLE(p as Absyn.PROGRAM(globalBuildTimes=ts),_,ic,iv,cf,lf)),msg)
      equation
        cls = Interactive.getPathedClassInProgram(className, p);
        refactoredClass = Refactor.refactorGraphicalAnnotation(p, cls);
        within_ = Interactive.buildWithin(className);
        p1 = Interactive.updateProgram(Absyn.PROGRAM({refactoredClass}, within_,ts), p);
        s1 = Absyn.pathString(className);
        retStr=stringAppendList({"Translation of ",s1," successful.\n"});
      then
        (cache,Values.STRING(retStr),GlobalScript.SYMBOLTABLE(p1,NONE(),ic,iv,cf,lf));

    case (cache,_,_,st,_)
      equation
        errorMsg = Error.printMessagesStr(false);
        strEmpty = (stringCompare("",errorMsg)==0);
        errorMsg = Util.if_(strEmpty,"Internal error, translating graphics to new version",errorMsg);
      then
        (cache,Values.STRING(errorMsg),st);
  end matchcontinue;
end translateGraphics;


protected function calculateSimulationSettings " author: x02lucpo
 calculates the start,end,interval,stepsize, method and initFileName"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Values.Value> vals;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  output Env.Cache outCache;
  output SimCode.SimulationSettings outSimSettings;
algorithm
  (outCache,outSimSettings):=
  match (inCache,inEnv,vals,inInteractiveSymbolTable,inMsg)
    local
      String method_str,options_str,outputFormat_str,variableFilter_str,s;
      GlobalScript.SymbolTable st;
      Values.Value starttime_v,stoptime_v,tolerance_v;
      Integer interval_i;
      Real starttime_r,stoptime_r,tolerance_r;
      list<Env.Frame> env;
      Absyn.Msg msg;
      Env.Cache cache;
      Boolean measureTime;
      String cflags,simflags;
    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(_)),starttime_v,stoptime_v,Values.INTEGER(interval_i),tolerance_v,Values.STRING(method_str),_,Values.STRING(options_str),Values.STRING(outputFormat_str),Values.STRING(variableFilter_str),Values.BOOL(measureTime),Values.STRING(cflags),Values.STRING(simflags)},
         (st as GlobalScript.SYMBOLTABLE(ast = _)),msg)
      equation
        starttime_r = ValuesUtil.valueReal(starttime_v);
        stoptime_r = ValuesUtil.valueReal(stoptime_v);
        tolerance_r = ValuesUtil.valueReal(tolerance_v);
        outSimSettings = SimCodeMain.createSimulationSettings(starttime_r,stoptime_r,interval_i,tolerance_r,method_str,options_str,outputFormat_str,variableFilter_str,measureTime,cflags);
      then
        (cache, outSimSettings);
    else
      equation
        s = "CevalScript.calculateSimulationSettings failed: " +& ValuesUtil.valString(Values.TUPLE(vals));
        Error.addMessage(Error.INTERNAL_ERROR, {s});
      then
        fail();
  end match;
end calculateSimulationSettings;

protected function getListFirstShowError
"@author: adrpo
 return the first element in the list and the rest of values.
 if the list is empty display the errorMessage!"
  input list<Values.Value> inValues;
  input String errorMessage;
  output Values.Value outValue;
  output list<Values.Value> restValues;
algorithm
  (outValue, restValues) := match(inValues, errorMessage)
    local
      Values.Value v;
      list<Values.Value> rest;

    // everything is fine and dandy
    case (v::rest, _) then (v, rest);

    // ups, we're missing an argument
    case ({}, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {errorMessage});
      then
        fail();
  end match;
end getListFirstShowError;

protected function getListNthShowError
"@author: adrpo
 return the N-th element in the list and the rest of values.
 if the list is empty display the errorMessage!"
  input list<Values.Value> inValues;
  input String errorMessage;
  input Integer currentElement;
  input Integer nthElement;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue(inValues, errorMessage, currentElement, nthElement)
    local
      Values.Value v;
      list<Values.Value> lst,rest;
      Integer i,n;

    // everything is fine and dandy
    case (lst, _, i, n)
      equation
        true = i < n;
        (_,rest) = getListFirstShowError(lst,errorMessage);
        v = getListNthShowError(rest,errorMessage, i+1, n);
      then v;

    // everything is fine and dandy
    case (lst, _, i, n)
      equation
      (v, _) = getListFirstShowError(lst,errorMessage);
    then v;

  end matchcontinue;
end getListNthShowError;

protected function moveClass
  input Absyn.Path inClassName;
  input String inDirection;
  input Absyn.Program inProg;
  output Absyn.Program outProg;
algorithm
  outProg := matchcontinue(inClassName, inDirection, inProg)
    local 
      Absyn.Path c, parent; 
      Absyn.Program p;
      list<Absyn.Class>  cls;
      Absyn.Within       w;
      Absyn.TimeStamp    gbt;
      String name;
      Absyn.Class parentClass;
      
    case (Absyn.FULLYQUALIFIED(c), _, _)
      equation
        p = moveClass(c, inDirection, inProg);
      then
        p;
    
    case (Absyn.IDENT(name), _, Absyn.PROGRAM(cls, w, gbt))
      equation
        cls = moveClassInList(name, cls, inDirection);
        p = Absyn.PROGRAM(cls, w, gbt);
      then
        p;
        
    case (Absyn.QUALIFIED(_, _), _, p)
      equation
        name = Absyn.pathLastIdent(inClassName);
        parent = Absyn.stripLast(inClassName);
        parentClass = Interactive.getPathedClassInProgram(parent, p);
      then
        p;
  
  end matchcontinue;
end moveClass;

protected function moveClassInList
  input String inClassName;
  input list<Absyn.Class> inCls;
  input String inDirection;
  output list<Absyn.Class> outCls;
algorithm
  outCls := inCls;
end moveClassInList;

protected function buildModel " author: x02lucpo
 translates and builds the model by running compiler script on the generated makefile"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Values.Value> inValues;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  output Env.Cache outCache;
  output GlobalScript.SymbolTable outInteractiveSymbolTable3;
  output String compileDir;
  output String outString1 "className";
  output String outString2 "method";
  output String outputFormat_str;
  output String outInitFileName "initFileName";
  output String outSimFlags;
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  (outCache,outInteractiveSymbolTable3,compileDir,outString1,outString2,outputFormat_str,outInitFileName,outSimFlags,resultValues):=
  matchcontinue (inCache,inEnv,inValues,inInteractiveSymbolTable,inMsg)
    local
      GlobalScript.SymbolTable st,st_1,st2;
      BackendDAE.BackendDAE indexed_dlow_1;
      list<String> libs;
      String file_dir,init_filename,method_str,filenameprefix,exeFile,s3,simflags;
      Absyn.Path classname;
      Absyn.Program p;
      Absyn.Class cdef;
      Real edit,build,globalEdit,globalBuild,timeCompile;
      list<Env.Frame> env;
      SimCode.SimulationSettings simSettings;
      Values.Value starttime,stoptime,interval,tolerance,method,options,outputFormat,variableFilter;
      list<Values.Value> vals, values;
      Absyn.Msg msg;
      Env.Cache cache;
      Boolean existFile;
      Absyn.TimeStamp ts;

    // do not recompile.
    case (cache,env,vals,
          (st as GlobalScript.SYMBOLTABLE(ast = p as Absyn.PROGRAM(globalBuildTimes=Absyn.TIMESTAMP(_,edit)))),msg)
      // If we already have an up-to-date version of the binary file, we don't need to recompile.
      equation
        // buildModel expects these arguments:
        // className, startTime, stopTime, numberOfIntervals, tolerance, method, fileNamePrefix,
        // options, outputFormat, variableFilter, measureTime, cflags, simflags
        (Values.CODE(Absyn.C_TYPENAME(classname)),vals) = getListFirstShowError(vals, "while retreaving the className (1 arg) from the buildModel arguments");
        (starttime,vals) = getListFirstShowError(vals, "while retreaving the startTime (2 arg) from the buildModel arguments");
        (stoptime,vals) = getListFirstShowError(vals, "while retreaving the stopTime (3 arg) from the buildModel arguments");
        (interval,vals) = getListFirstShowError(vals, "while retreaving the numberOfIntervals (4 arg) from the buildModel arguments");
        (tolerance,vals) = getListFirstShowError(vals, "while retreaving the tolerance (5 arg) from the buildModel arguments");
        (Values.STRING(method_str),vals) = getListFirstShowError(vals, "while retreaving the method (6 arg) from the buildModel arguments");
        (Values.STRING(filenameprefix),vals) = getListFirstShowError(vals, "while retreaving the fileNamePrefix (7 arg) from the buildModel arguments");
        (options,vals) = getListFirstShowError(vals, "while retreaving the options (8 arg) from the buildModel arguments");
        (Values.STRING(outputFormat_str),vals) = getListFirstShowError(vals, "while retreaving the outputFormat (9 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the variableFilter (10 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the measureTime (11 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the cflags (12 arg) from the buildModel arguments");
        (Values.STRING(simflags),vals) = getListFirstShowError(vals, "while retreaving the simflags (13 arg) from the buildModel arguments");
        //cdef = Interactive.getPathedClassInProgram(classname,p);
        Error.clearMessages() "Clear messages";
        // Only compile if change occured after last build.
        (Absyn.CLASS(info = Absyn.INFO(buildTimes= Absyn.TIMESTAMP(build,_)))) = Interactive.getPathedClassInProgram(classname,p);
        compileDir = System.pwd() +& System.pathDelimiter();
        true = (build >. edit);
        init_filename = stringAppendList({filenameprefix,"_init.xml"});
        exeFile = filenameprefix +& System.getExeExt();
        existFile = System.regularFileExists(exeFile);
        true = existFile;
    then (cache,st,compileDir,filenameprefix,method_str,outputFormat_str,init_filename,simflags,zeroAdditionalSimulationResultValues);

    // compile the model
    case (cache,env,vals,(st_1 as GlobalScript.SYMBOLTABLE(ast = p)),msg)
      equation
        // buildModel expects these arguments:
        // className, startTime, stopTime, numberOfIntervals, tolerance, method, fileNamePrefix,
        // options, outputFormat, variableFilter, measureTime, cflags, simflags
        values = vals;
        (Values.CODE(Absyn.C_TYPENAME(classname)),vals) = getListFirstShowError(vals, "while retreaving the className (1 arg) from the buildModel arguments");
        (starttime,vals) = getListFirstShowError(vals, "while retreaving the startTime (2 arg) from the buildModel arguments");
        (stoptime,vals) = getListFirstShowError(vals, "while retreaving the stopTime (3 arg) from the buildModel arguments");
        (interval,vals) = getListFirstShowError(vals, "while retreaving the numberOfIntervals (4 arg) from the buildModel arguments");
        (tolerance,vals) = getListFirstShowError(vals, "while retreaving the tolerance (5 arg) from the buildModel arguments");
        (method,vals) = getListFirstShowError(vals, "while retreaving the method (6 arg) from the buildModel arguments");
        (Values.STRING(filenameprefix),vals) = getListFirstShowError(vals, "while retreaving the fileNamePrefix (7 arg) from the buildModel arguments");
        (options,vals) = getListFirstShowError(vals, "while retreaving the options (8 arg) from the buildModel arguments");
        (outputFormat,vals) = getListFirstShowError(vals, "while retreaving the outputFormat (9 arg) from the buildModel arguments");
        (variableFilter,vals) = getListFirstShowError(vals, "while retreaving the variableFilter (10 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the measureTime (11 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the cflags (12 arg) from the buildModel arguments");
        (Values.STRING(simflags),vals) = getListFirstShowError(vals, "while retreaving the simflags (13 arg) from the buildModel arguments");

        (cdef as Absyn.CLASS(info = Absyn.INFO(buildTimes=ts as Absyn.TIMESTAMP(_,globalEdit)))) = Interactive.getPathedClassInProgram(classname,p);
        Absyn.PROGRAM(_,_,Absyn.TIMESTAMP(globalBuild,_)) = p;

        Error.clearMessages() "Clear messages";
        compileDir = System.pwd() +& System.pathDelimiter();
        (cache,simSettings) = calculateSimulationSettings(cache,env,values,st_1,msg);
        SimCode.SIMULATION_SETTINGS(method = method_str, outputFormat = outputFormat_str)
           = simSettings;

        (cache,st,indexed_dlow_1,libs,file_dir,resultValues) = translateModel(cache,env, classname, st_1, filenameprefix,true, SOME(simSettings));
        //cname_str = Absyn.pathString(classname);
        //SimCodeUtil.generateInitData(indexed_dlow_1, classname, filenameprefix, init_filename,
        //  starttime_r, stoptime_r, interval_r, tolerance_r, method_str,options_str,outputFormat_str);

        System.realtimeTick(GlobalScript.RT_CLOCK_BUILD_MODEL);
        init_filename = filenameprefix +& "_init.xml"; //a hack ? should be at one place somewhere
        //win1 = getWithinStatement(classname);

        Debug.fprintln(Flags.DYN_LOAD, "buildModel: about to compile model " +& filenameprefix +& ", " +& file_dir);
        compileModel(filenameprefix, libs, file_dir, method_str);
        Debug.fprintln(Flags.DYN_LOAD, "buildModel: Compiling done.");
        p = setBuildTime(p,classname);
        st2 = st;// Interactive.replaceSymbolTableProgram(st,p);
        timeCompile = System.realtimeTock(GlobalScript.RT_CLOCK_BUILD_MODEL);
        resultValues = ("timeCompile",Values.REAL(timeCompile)) :: resultValues;
      then
        (cache,st2,compileDir,filenameprefix,method_str,outputFormat_str,init_filename,simflags,resultValues);

    // failure
    case (_,_,vals,_,_)
      equation
        Error.assertion(listLength(vals) == 13, "buildModel failure, length = " +& intString(listLength(vals)), Absyn.dummyInfo);
      then fail();
  end matchcontinue;
end buildModel;

protected function createSimulationResultFromcallModelExecutable
"This function calls the compiled simulation executable."
  input Integer callRet;
  input Real timeTotal;
  input Real timeSimulation;
  input list<tuple<String,Values.Value>> resultValues;
  input Env.Cache inCache;
  input Absyn.Path className;
  input list<Values.Value> inVals;
  input GlobalScript.SymbolTable inSt;
  input String result_file;
  input String logFile;
  output Env.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable) := matchcontinue (callRet,timeTotal,timeSimulation,resultValues,inCache,className,inVals,inSt,result_file,logFile)
    local
      GlobalScript.SymbolTable newst;
      String res,str;
      Values.Value simValue;

    case (0,_,_,_,_,_,_,_,_,_)
      equation
        simValue = createSimulationResult(
           result_file,
           simOptionsAsString(inVals),
           System.readFile(logFile),
           ("timeTotal", Values.REAL(timeTotal)) ::
           ("timeSimulation", Values.REAL(timeSimulation)) ::
          resultValues);
        newst = Interactive.addVarToSymboltable(
          DAE.CREF_IDENT("currentSimulationResult", DAE.T_STRING_DEFAULT, {}), 
          Values.STRING(result_file), Env.emptyEnv, inSt);
      then
        (inCache,simValue,newst);
    else
      equation
        true = System.regularFileExists(logFile);
        res = System.readFile(logFile);
        str = Absyn.pathString(className);
        res = stringAppendList({"Simulation execution failed for model: ", str, "\n", res});
        simValue = createSimulationResult("", simOptionsAsString(inVals), res, resultValues);
      then
        (inCache,simValue,inSt);
  end matchcontinue;
end createSimulationResultFromcallModelExecutable;

protected function buildOpenTURNSInterface "builds the OpenTURNS interface by calling the OpenTURNS module"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Values.Value> vals;
  input GlobalScript.SymbolTable inSt;
  input Absyn.Msg inMsg;
  output Env.Cache outCache;
  output String scriptFile;
  output GlobalScript.SymbolTable outSt;
algorithm
  (outCache,scriptFile,outSt):= match(inCache,inEnv,vals,inSt,inMsg)
    local
      String templateFile, str;
      Absyn.Program p;
      Absyn.Path className;
      Env.Cache cache;
      DAE.DAElist dae;
      Env.Env env;
      BackendDAE.BackendDAE dlow;
      DAE.FunctionTree funcs;
      GlobalScript.SymbolTable st;
      Boolean showFlatModelica;
      String filenameprefix,description;

    case(cache,_,{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(templateFile),Values.BOOL(showFlatModelica)},GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        (cache,env,dae,st) = runFrontEnd(cache,inEnv,className,inSt,false);
        //print("instantiated class\n");
        dae = DAEUtil.transformationsBeforeBackend(cache,env,dae);
        funcs = Env.getFunctionTree(cache);
        str = Debug.bcallret2(showFlatModelica, DAEDump.dumpStr, dae, funcs, "");
        Debug.bcall(showFlatModelica, print, str);
        // get all the variable names with a distribution
        // TODO FIXME
        // sort all variable names in the distribution order
        // TODO FIXME
        filenameprefix = Absyn.pathString(className);
        description = DAEUtil.daeDescription(dae);
        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        //print("lowered class\n");
        //print("calling generateOpenTurnsInterface\n");
        scriptFile = OpenTURNS.generateOpenTURNSInterface(cache,inEnv,dlow,funcs,className,p,dae,templateFile);
      then
        (cache,scriptFile,inSt);

  end match;
end buildOpenTURNSInterface;

protected function getRunScriptExtension
input String inString;
output String outString;
algorithm
  outString:=match(inString)
  local
    case "LINUX32"
      then ".sh";
    case "LINUX64"
      then ".sh";
    case "WIN32"
      then ".bat";
    case "WIN64"
      then ".bat";
   end match;
 end getRunScriptExtension;     

protected function runOpenTURNSPythonScript
"runs OpenTURNS with the given python script returning the log file"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Values.Value> vals;
  input GlobalScript.SymbolTable inSt;
  input Absyn.Msg inMsg;
  output Env.Cache outCache;
  output String outLogFile;
  output GlobalScript.SymbolTable outSt;
algorithm
  (outCache,outLogFile,outSt):= match(inCache,inEnv,vals,inSt,inMsg)
    local
      String pythonScriptFile, logFile;
      Env.Cache cache;
    case(cache,_,{Values.STRING(pythonScriptFile)},_,_)
      equation
        logFile = OpenTURNS.runPythonScript(pythonScriptFile);
      then
        (cache,logFile,inSt);
  end match;
end runOpenTURNSPythonScript;

public function getFileDir "author: x02lucpo
  returns the dir where class file (.mo) was saved or
  $OPENMODELICAHOME/work if the file was not saved yet"
  input Absyn.ComponentRef inComponentRef "class";
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Class cdef;
      String filename,pd,dir_1,omhome,omhome_1,cit;
      String pd_1;
      list<String> filename_1,dir;
      Absyn.ComponentRef class_;
      Absyn.Program p;
    case (class_,p)
      equation
        p_class = Absyn.crefToPath(class_) "change to the saved files directory" ;
        cdef = Interactive.getPathedClassInProgram(p_class, p);
        filename = Absyn.classFilename(cdef);
        pd = System.pathDelimiter();
        (pd_1 :: _) = stringListStringChar(pd);
        filename_1 = Util.stringSplitAtChar(filename, pd_1);
        dir = List.stripLast(filename_1);
        dir_1 = stringDelimitList(dir, pd);
      then
        dir_1;
    case (class_,p)
      equation
        omhome = Settings.getInstallationDirectoryPath() "model not yet saved! change to $OPENMODELICAHOME/work" ;
        omhome_1 = System.trim(omhome, "\"");
        pd = System.pathDelimiter();
        cit = winCitation();
        dir_1 = stringAppendList({cit,omhome_1,pd,"work",cit});
      then
        dir_1;
    case (_,_) then "";  /* this function should never fail */
  end matchcontinue;
end getFileDir;

public function compileModel "Compiles a model given a file-prefix, helper function to buildModel."
  input String inFilePrefix;
  input list<String> inLibsList;
  input String inFileDir;
  input String solverMethod "inline solvers requires setting environment variables";
algorithm
  _ := matchcontinue (inFilePrefix,inLibsList,inFileDir,solverMethod)
    local
      String pd,omhome,omhome_1,cd_path,libsfilename,libs_str,win_call,make_call,s_call,fileprefix,file_dir,filename,str,fileDLL, fileEXE, fileLOG, make,target,numParallelStr,winCompileMode;
      list<String> libs;
      Boolean isWindows;
      Integer numParallel;

    // If compileCommand not set, use $OPENMODELICAHOME\bin\Compile
    // adrpo 2009-11-29: use ALL THE TIME $OPENMODELICAHOME/bin/Compile
    case (fileprefix,libs,file_dir,_)
      equation
        pd = System.pathDelimiter();
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.stringReplace(omhome, "\"", "");
        cd_path = System.pwd();
        libsfilename = stringAppend(fileprefix, ".libs");
        libs_str = stringDelimitList(libs, " ");

        System.writeFile(libsfilename, libs_str);
        // We only need to set OPENMODELICAHOME on Windows, and set doesn't work in bash shells anyway
        // adrpo: 2010-10-05:
        //        whatever you do, DO NOT add a space before the && otherwise
        //        OPENMODELICAHOME that we set will contain a SPACE at the end!
        //        set OPENMODELICAHOME=DIR && actually adds the space between the DIR and &&
        //        to the environment variable! Don't ask me why, ask Microsoft.
        isWindows = System.os() ==& "Windows_NT";
        target = Config.simulationCodeTarget();
        winCompileMode = Util.if_(Config.getRunningTestsuite(), "serial", "parallel");
        omhome = Util.if_(isWindows, "set OPENMODELICAHOME=\"" +& System.stringReplace(omhome_1, "/", "\\") +& "\"&& ", "");
        win_call = stringAppendList({omhome,"\"",omhome_1,pd,"share",pd,"omc",pd,"scripts",pd,"Compile","\""," ",fileprefix," ",target," ", winCompileMode});
        make = System.getMakeCommand();
        numParallel = Util.if_(Config.getRunningTestsuite(), 1, Config.noProc());
        numParallelStr = intString(numParallel);
        make_call = stringAppendList({make," -j",numParallelStr," -f ",fileprefix,".makefile"});
        s_call = Util.if_(isWindows, win_call, make_call);
        Debug.fprintln(Flags.DYN_LOAD, "compileModel: running " +& s_call);

        // remove .exe .dll .log!
        fileEXE = fileprefix +& System.getExeExt();
        fileDLL = fileprefix +& System.getDllExt();
        fileLOG = fileprefix +& ".log";
        0 = Debug.bcallret1(System.regularFileExists(fileEXE),System.removeFile,fileEXE,0);
        0 = Debug.bcallret1(System.regularFileExists(fileDLL),System.removeFile,fileDLL,0);
        0 = Debug.bcallret1(System.regularFileExists(fileLOG),System.removeFile,fileLOG,0);

        // call the system command to compile the model!
        0 = System.systemCall(s_call,Util.if_(isWindows,"",fileLOG));
        Debug.bcall2(Config.getRunningTestsuite(), System.appendFile, Config.getRunningTestsuiteFile(),
          fileEXE +& "\n" +& fileDLL +& "\n" +& fileLOG +& "\n" +& fileprefix +& ".o\n" +& fileprefix +& ".libs\n" +&
          fileprefix +& "_records.o\n" +& fileprefix +& "_res.mat\n");

        Debug.fprintln(Flags.DYN_LOAD, "compileModel: successful! ");
      then
        ();
    case (fileprefix,libs,file_dir,_) /* compilation failed */
      equation
        filename = stringAppendList({fileprefix,".log"});
        true = System.regularFileExists(filename);
        str = System.readFile(filename);
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {str});
        Debug.fprintln(Flags.DYN_LOAD, "compileModel: failed!");
      then
        fail();

    case (fileprefix,libs,file_dir,_) /* compilation failed\\n */
      equation
        "Windows_NT" = System.os();
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.stringReplace(omhome, "\"", "");
        pd = System.pathDelimiter();
        s_call = stringAppendList({omhome_1,pd,"share",pd,"omc",pd,"scripts",pd,"Compile.bat"});
        false = System.regularFileExists(s_call);
        str=stringAppendList({"command ",s_call," not found. Check $OPENMODELICAHOME"});
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {str});
      then
        fail();
    else
      equation
        failure(_ = Settings.getInstallationDirectoryPath());
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {"$OPENMODELICAHOME not found."});
      then
        fail();
  end matchcontinue;
end compileModel;

protected function winCitation "author: PA
  Returns a citation mark if platform is windows, otherwise empty string.
  Used by simulate to make whitespaces work in filepaths for WIN32"
  output String outString;
algorithm
  outString:=
  matchcontinue ()
    case ()
      equation
        "WIN32" = System.platform();
      then "\"";
    case () then "";
  end matchcontinue;
end winCitation;

public function checkModel " checks a model and returns number of variables and equations"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable) :=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg)
    local
      DAE.DAElist dae;
      list<Env.Frame> env;
      GlobalScript.SymbolTable st;
      Absyn.Program p;
      Absyn.Msg msg;
      Env.Cache cache;
      Integer eqnSize,varSize,simpleEqnSize;
      String errorMsg,warnings,eqnSizeStr,varSizeStr,retStr,classNameStr,simpleEqnSizeStr;
      Boolean strEmpty;
      Absyn.Restriction restriction;
      Absyn.Class c;

    // handle normal models
    case (cache,env,_,(st as GlobalScript.SYMBOLTABLE(ast = p)),msg)
      equation
        Error.clearMessages() "Clear messages";
        Print.clearErrorBuf() "Clear error buffer";
        (cache,env,dae,st) = runFrontEnd(cache,env,className,st,false);

        (varSize,eqnSize,simpleEqnSize) = CheckModel.checkModel(dae);

        eqnSizeStr = intString(eqnSize);
        varSizeStr = intString(varSize);
        simpleEqnSizeStr = intString(simpleEqnSize);

        classNameStr = Absyn.pathString(className);
        warnings = Error.printMessagesStr(false);
        retStr=stringAppendList({"Check of ",classNameStr," completed successfully.\n\n",warnings,"\nClass ",classNameStr," has ",eqnSizeStr," equation(s) and ",
          varSizeStr," variable(s).\n",simpleEqnSizeStr," of these are trivial equation(s).\n"});
      then
        (cache,Values.STRING(retStr),st);

    // handle functions
    case (cache,env,_,(st as GlobalScript.SYMBOLTABLE(ast = p)),msg)
      equation
        (c as Absyn.CLASS(restriction=restriction)) = Interactive.getPathedClassInProgram(className, p);
        true = Absyn.isFunctionRestriction(restriction) or Absyn.isPackageRestriction(restriction);
        Error.clearMessages() "Clear messages";
        Print.clearErrorBuf() "Clear error buffer";
        (cache,env,dae,st) = runFrontEnd(cache,env,className,st,true);

        //UnitParserExt.clear();
        //UnitAbsynBuilder.registerUnits(ptot);
        //UnitParserExt.commit();

        classNameStr = Absyn.pathString(className);
        warnings = Error.printMessagesStr(false);
        // TODO: add a check if warnings is empty, if so then remove \n... --> warnings,"\nClass  <--- line below.
        retStr=stringAppendList({"Check of ",classNameStr," completed successfully.\n\n",warnings,"\n"});
      then
        (cache,Values.STRING(retStr),st);

    case (cache,env,_,st as GlobalScript.SYMBOLTABLE(ast=p), _)
      equation
        classNameStr = Absyn.pathString(className);
        false = Interactive.existClass(Absyn.pathToCref(className), p);
        errorMsg = "Unknown model in checkModel: " +& classNameStr +& "\n";
      then
        (cache,Values.STRING(errorMsg),st);

    // errors
    case (cache,env,_,st,_)
      equation
      classNameStr = Absyn.pathString(className);
      errorMsg = Error.printMessagesStr(false);
      strEmpty = (stringCompare("",errorMsg)==0);
      errorMsg = Util.if_(strEmpty,"Internal error! Check of: " +& classNameStr +& " failed with no error message.", errorMsg);
    then
      (cache,Values.STRING(errorMsg),st);

  end matchcontinue;
end checkModel;

protected function selectIfNotEmpty
  input String inString;
  input String selector " ";
  output String outString;
algorithm
  outString := matchcontinue(inString, selector)
    local
      String s;

    case (_, "") then "";

    else
      equation
        s = inString +& selector;
      then s;
  end matchcontinue;
end selectIfNotEmpty;

protected function setBuildTime "sets the build time of a class.
 This is done using traverseClasses and not using updateProgram,
 because updateProgram updates edit times"
  input Absyn.Program p;
  input Absyn.Path path;
  output Absyn.Program outP;
algorithm
  ((outP,_,_)) := Interactive.traverseClasses(p,NONE(), setBuildTimeVisitor, path, false /* Skip protected */);
end setBuildTime;

protected function setBuildTimeVisitor "Visitor function to set build time"
  input tuple<Absyn.Class, Option<Absyn.Path>,Absyn.Path> inTpl;
  output tuple<Absyn.Class, Option<Absyn.Path>,Absyn.Path> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local String name; Boolean p,f,e,ro; Absyn.Restriction r; Absyn.ClassDef cdef;
    String fname; Integer i1,i2,i3,i4;
    Absyn.Path path2,path;
    Absyn.TimeStamp ts;

    case((Absyn.CLASS(name,p,f,e,r,cdef,Absyn.INFO(fname,ro,i1,i2,i3,i4,ts)),SOME(path2),path))
      equation
        true = Absyn.pathEqual(Absyn.joinPaths(path2,Absyn.IDENT(name)),path);
        ts =Absyn.setTimeStampBool(ts,false);
      then ((Absyn.CLASS(name,p,f,e,r,cdef,Absyn.INFO(fname,ro,i1,i2,i3,i4,ts)),SOME(path),path));
    case _ then inTpl;

    case((Absyn.CLASS(name,p,f,e,r,cdef,Absyn.INFO(fname,ro,i1,i2,i3,i4,ts)),NONE(),path))
      equation
        true = Absyn.pathEqual(Absyn.IDENT(name),path);
        ts =Absyn.setTimeStampBool(ts,false);
      then ((Absyn.CLASS(name,p,f,e,r,cdef,Absyn.INFO(fname,ro,i1,i2,i3,i4,ts)),NONE(),path));
    case _ then inTpl;
  end matchcontinue;
end setBuildTimeVisitor;

protected function getWithinStatement "To get a correct Within-path with unknown input-path."
  input Absyn.Path ip;
  output Absyn.Within op;
algorithm op :=  matchcontinue(ip)
  local Absyn.Path path;
  case(path) equation path = Absyn.stripLast(path); then Absyn.WITHIN(path);
  case(path) then Absyn.TOP();
end matchcontinue;
end getWithinStatement;

protected function compileOrNot "This function compares last-build-time vs last-edit-time, and if we have edited since we built last time
it fails."
input Absyn.Class classIn;
algorithm _:= matchcontinue(classIn)
  local
    Absyn.Class c1;
    Absyn.Info nfo;
    Real tb,te;
    case(c1 as Absyn.CLASS(info = nfo as Absyn.INFO(buildTimes = Absyn.TIMESTAMP(tb,te))))
    equation
    true = (tb >. te);
     then ();
    case(_) then fail();
end matchcontinue;
end compileOrNot;

public function subtractDummy
"if $dummy is present in Variables, subtract 1 from equation and variable size, otherwise not"
  input BackendDAE.Variables vars;
  input Integer eqnSize;
  input Integer varSize;
  output Integer outEqnSize;
  output Integer outVarSize;
algorithm
  (outEqnSize,outVarSize) := matchcontinue(vars,eqnSize,varSize)
    case(_,_,_)
      equation
        (_,_) = BackendVariable.getVar(ComponentReference.makeCrefIdent("$dummy",DAE.T_UNKNOWN_DEFAULT,{}),vars);
      then (eqnSize-1,varSize-1);
    else (eqnSize,varSize);
  end matchcontinue;
end subtractDummy;

protected function dumpXMLDAEFrontEnd
"@author: adrpo
 this function runs the front-end for the dumpXMLDAE function"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inClassName;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  output Env.Cache outCache;
  output Env.Env outEnv; 
  output DAE.DAElist outDae;
algorithm
  (outCache, outEnv, outDae) := matchcontinue(inCache, inEnv, inClassName, inInteractiveSymbolTable)
    local
      Absyn.Program p;
      SCode.Program scode;
    
    case (_, _, _, _) 
      equation
        GlobalScript.SYMBOLTABLE(ast = p) = inInteractiveSymbolTable;  
        scode = SCodeUtil.translateAbsyn2SCode(p);
        (outCache, outEnv, _, outDae) = Inst.instantiateClass(inCache, InnerOuter.emptyInstHierarchy, scode, inClassName);
        outDae = DAEUtil.transformationsBeforeBackend(outCache,outEnv,outDae);
     then
       (outCache, outEnv, outDae);
       
  end matchcontinue;
end dumpXMLDAEFrontEnd;

protected function dumpXMLDAE " author: fildo
 This function outputs the DAE system corresponding to a specific model."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Values.Value> vals;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  output Env.Cache outCache;
  output GlobalScript.SymbolTable outInteractiveSymbolTable3;
  output String xml_filename;
algorithm
  (outCache,outInteractiveSymbolTable3,xml_filename) :=
  matchcontinue (inCache,inEnv,vals,inInteractiveSymbolTable,inMsg)
    local
      String cname_str,filenameprefix,compileDir,rewriteRulesFile,description;
      list<Env.Frame> env;
      Absyn.Path classname;
      Absyn.Program p;
      BackendDAE.BackendDAE dlow,dlow_1,indexed_dlow;
      Env.Cache cache;
      Boolean addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals;
      GlobalScript.SymbolTable st;
      Absyn.Msg msg;
      DAE.DAElist dae_1,dae;
      list<SCode.Element> p_1;

    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="flat"),
                     Values.BOOL(addOriginalIncidenceMatrix),Values.BOOL(addSolvingInfo),
                     Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),
                     Values.STRING(filenameprefix),Values.STRING(rewriteRulesFile)},st,msg)
      equation
        Error.clearMessages() "Clear messages";
        
        // set the rewrite rules flag
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, rewriteRulesFile);
        // load the rewrite rules
        RewriteRules.loadRules();
        
        (cache, env, dae) = dumpXMLDAEFrontEnd(cache, env, classname, st);
        description = DAEUtil.daeDescription(dae);
        
        compileDir = System.pwd() +& System.pathDelimiter();
        cname_str = Absyn.pathString(classname);
        filenameprefix = Util.if_(filenameprefix ==& "<default>", cname_str, filenameprefix);
        
        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix)); //Verificare cosa fa
        dlow_1 = BackendDAEUtil.preOptimizeBackendDAE(dlow,NONE());
        dlow_1 = FindZeroCrossings.findZeroCrossings(dlow_1);
        xml_filename = stringAppendList({filenameprefix,".xml"});
        
        // apply rewrite rules to the back-end
        dlow_1 = applyRewriteRulesOnBackend(dlow_1);
        
        Print.clearBuf();
        XMLDump.dumpBackendDAE(dlow_1,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,false);
        Print.writeBuf(xml_filename);
        Print.clearBuf();
        compileDir = Util.if_(Config.getRunningTestsuite(),"",compileDir);
        
        // clear the rewrite rules!
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, "");
        RewriteRules.clearRules();
      then
        (cache,st,stringAppendList({compileDir,xml_filename}));

    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="optimiser"),
                     Values.BOOL(addOriginalIncidenceMatrix),Values.BOOL(addSolvingInfo),
                     Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),
                     Values.STRING(filenameprefix),Values.STRING(rewriteRulesFile)},(st as GlobalScript.SYMBOLTABLE(ast = p)),msg)
      equation
        //asInSimulationCode==false => it's NOT necessary to do all the translation's steps before dumping with xml
        Error.clearMessages() "Clear messages";

        // set the rewrite rules flag
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, rewriteRulesFile);
        // load the rewrite rules
        RewriteRules.loadRules();
        
        (cache, env, dae) = dumpXMLDAEFrontEnd(cache, env, classname, st);
        description = DAEUtil.daeDescription(dae);
        
        compileDir = System.pwd() +& System.pathDelimiter();
        cname_str = Absyn.pathString(classname);
        filenameprefix = Util.if_(filenameprefix ==& "<default>", cname_str, filenameprefix);
        
        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix)); //Verificare cosa fa
        dlow_1 = BackendDAEUtil.preOptimizeBackendDAE(dlow,NONE());
        dlow_1 = BackendDAEUtil.transformBackendDAE(dlow_1,NONE(),NONE(),NONE());
        dlow_1 = FindZeroCrossings.findZeroCrossings(dlow_1);
        xml_filename = stringAppendList({filenameprefix,".xml"});
        
        // apply rewrite rules to the back-end
        dlow_1 = applyRewriteRulesOnBackend(dlow_1);
        
        Print.clearBuf();
        XMLDump.dumpBackendDAE(dlow_1,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,false);
        Print.writeBuf(xml_filename);
        Print.clearBuf();
        compileDir = Util.if_(Config.getRunningTestsuite(),"",compileDir);
        
        // clear the rewrite rules!
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, "");
        RewriteRules.clearRules();
      then
        (cache,st,stringAppendList({compileDir,xml_filename}));

    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="backEnd"),
                     Values.BOOL(addOriginalIncidenceMatrix),Values.BOOL(addSolvingInfo),
                     Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),
                     Values.STRING(filenameprefix),Values.STRING(rewriteRulesFile)},(st as GlobalScript.SYMBOLTABLE(ast = p)),msg)
      equation
        //asInSimulationCode==true => it's necessary to do all the translation's steps before dumping with xml
        Error.clearMessages() "Clear messages";
        
        // set the rewrite rules flag
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, rewriteRulesFile);
        // load the rewrite rules
        RewriteRules.loadRules();

        (cache, env, dae) = dumpXMLDAEFrontEnd(cache, env, classname, st);
        description = DAEUtil.daeDescription(dae);
        
        compileDir = System.pwd() +& System.pathDelimiter();
        cname_str = Absyn.pathString(classname);
        filenameprefix = Util.if_(filenameprefix ==& "<default>", cname_str, filenameprefix);
        
        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        indexed_dlow = BackendDAEUtil.getSolvedSystem(dlow, NONE(), NONE(), NONE(), NONE());
        xml_filename = stringAppendList({filenameprefix,".xml"});
        
        // apply rewrite rules to the back-end
        indexed_dlow = applyRewriteRulesOnBackend(indexed_dlow);
        
        Print.clearBuf();
        XMLDump.dumpBackendDAE(indexed_dlow,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,false);
        Print.writeBuf(xml_filename);
        Print.clearBuf();
        compileDir = Util.if_(Config.getRunningTestsuite(),"",compileDir);
        
        // clear the rewrite rules!
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, "");
        RewriteRules.clearRules();        
      then
        (cache,st,stringAppendList({compileDir,xml_filename}));
        
    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="stateSpace"),
                     Values.BOOL(addOriginalIncidenceMatrix),Values.BOOL(addSolvingInfo),
                     Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),
                     Values.STRING(filenameprefix),Values.STRING(rewriteRulesFile)},(st as GlobalScript.SYMBOLTABLE(ast = p)),msg)
      equation
        //asInSimulationCode==true => it's necessary to do all the translation's steps before dumping with xml
        Error.clearMessages() "Clear messages";
        
        // set the rewrite rules flag
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, rewriteRulesFile);
        // load the rewrite rules
        RewriteRules.loadRules();

        (cache, env, dae) = dumpXMLDAEFrontEnd(cache, env, classname, st);
        description = DAEUtil.daeDescription(dae);
        
        compileDir = System.pwd() +& System.pathDelimiter();
        cname_str = Absyn.pathString(classname);
        filenameprefix = Util.if_(filenameprefix ==& "<default>", cname_str, filenameprefix);
        
        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        indexed_dlow = BackendDAEUtil.getSolvedSystem(dlow, NONE(), NONE(), NONE(), NONE());
        xml_filename = stringAppendList({filenameprefix,".xml"});
        
        // apply rewrite rules to the back-end
        indexed_dlow = applyRewriteRulesOnBackend(indexed_dlow);
        
        Print.clearBuf();
        XMLDump.dumpBackendDAE(indexed_dlow,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,true);
        Print.writeBuf(xml_filename);
        Print.clearBuf();
        compileDir = Util.if_(Config.getRunningTestsuite(),"",compileDir);
        
        // clear the rewrite rules!
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, "");
        RewriteRules.clearRules();
      then
        (cache,st,stringAppendList({compileDir,xml_filename}));
  
    else
    equation
        // clear the rewrite rules if we fail!
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, "");
        RewriteRules.clearRules();
    then fail();
  
  end matchcontinue;
end dumpXMLDAE;

protected function applyRewriteRulesOnBackend
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
algorithm
  outBackendDAE := matchcontinue(inBackendDAE)
    local
      list<BackendDAE.Var> vars,knvars,extvars,aliasvars;
      BackendDAE.Variables vars_knownVars;
      BackendDAE.Variables vars_externalObject;
      BackendDAE.VariableArray varArr_externalObject;
      BackendDAE.Variables vars_aliasVars;
      BackendDAE.VariableArray varArr_aliasVars;
      BackendDAE.ExternalObjectClasses extObjCls;
      BackendDAE.EquationArray reqns,ieqns;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;
      list<DAE.Function> functionsElems;
      BackendDAE.BackendDAEType btp;
      list<BackendDAE.EqSystem> systs;
      BackendDAE.SymbolicJacobians symjacs;
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.ExtraInfo extraInfo;
      Env.Cache cache;
      Env.Env env;

    // no rewrites!
    case _
      equation
        true = RewriteRules.noRewriteRulesBackEnd();
      then 
        inBackendDAE;

    // some rewrites
    case _
      equation
        false = RewriteRules.noRewriteRulesBackEnd();
        outBackendDAE = BackendDAEOptimize.applyRewriteRulesBackend(inBackendDAE); 
      then
        outBackendDAE;
  
  end matchcontinue; 
end applyRewriteRulesOnBackend;

protected function getClassnamesInClassList
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  input Boolean inShowProtected;
  output list<String> outStrings;
algorithm
  outStrings :=
  match (inPath,inProgram,inClass,inShowProtected)
    local
      list<String> strlist;
      list<Absyn.ClassPart> parts;
      Absyn.Path inmodel,path;
      Absyn.Program p;
      String  baseClassName;
      Boolean b;
    case (_,_,Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),b)
      equation
        strlist = Interactive.getClassnamesInParts(parts,b);
      then
        strlist;

    case (inmodel,p,Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH(path = path))),b)
      equation
      then
        {};

    case (inmodel,p,Absyn.CLASS(body = Absyn.OVERLOAD(_, _)),b)
      equation
      then {};

    case (inmodel,p,Absyn.CLASS(body = Absyn.ENUMERATION(_, _)),b)
      equation
      then {};

    case (inmodel,p,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts=parts)),b)
      equation
        strlist = Interactive.getClassnamesInParts(parts,b);
      then strlist;

    case (inmodel,p,Absyn.CLASS(body = Absyn.PDER(_,_,_)),b)
      equation
      then {};

  end match;
end getClassnamesInClassList;

protected function joinPaths
  input String child;
  input Absyn.Path parent;
  output Absyn.Path outPath;
algorithm
  outPath := match (child, parent)
    local
      Absyn.Path r, res;
      String c;
    case (c, r)
      equation
        res = Absyn.joinPaths(r, Absyn.IDENT(c));
      then res;
  end match;
end joinPaths;

protected function getAllClassPathsRecursive
"@author adrpo
 Returns all paths of the classes recursively defined in a given class with the specified path."
  input Absyn.Path inPath "the given class path";
  input Boolean inCheckProtected;
  input Absyn.Program inProgram "the program";
  output list<Absyn.Path> outPaths;
algorithm
  outPaths :=
  matchcontinue (inPath,inCheckProtected,inProgram)
    local
      Absyn.Class cdef;
      String parent_string, s;
      list<String> strlst;
      Absyn.Program p;
      list<Absyn.Path> result_path_lst, result;
      Boolean b;
    case (_, b, p)
      equation
        cdef = Interactive.getPathedClassInProgram(inPath, p);
        strlst = getClassnamesInClassList(inPath, p, cdef, b);
        result_path_lst = List.map1(strlst, joinPaths, inPath);
        result = List.flatten(List.map2(result_path_lst, getAllClassPathsRecursive, b, p));
      then
        inPath::result;
    case (_, b, _)
      equation
        parent_string = Absyn.pathString(inPath);
        s = Error.printMessagesStr(false);
        s = stringAppendList({parent_string,"->","PROBLEM GETTING CLASS PATHS: ", s, "\n"});
        print(s);
      then {};
  end matchcontinue;
end getAllClassPathsRecursive;

public function checkAllModelsRecursive
"@author adrpo
 checks all models and returns number of variables and equations"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className;
  input Boolean inCheckProtected;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inEnv,className,inCheckProtected,inInteractiveSymbolTable,inMsg)
    local
      list<Absyn.Path> allClassPaths;
      GlobalScript.SymbolTable st;
      Absyn.Program p;
      Absyn.Msg msg;
      Env.Cache cache;
      String ret;
      list<Env.Frame> env;
      Boolean b;

    case (cache,env,_,b,(st as GlobalScript.SYMBOLTABLE(ast = p)),msg)
      equation
        allClassPaths = getAllClassPathsRecursive(className, b, p);
        print("Number of classes to check: " +& intString(listLength(allClassPaths)) +& "\n");
        // print ("All paths: \n" +& stringDelimitList(List.map(allClassPaths, Absyn.pathString), "\n") +& "\n");
        checkAll(cache, env, allClassPaths, st, msg);
        ret = "Number of classes checked: " +& intString(listLength(allClassPaths));
      then
        (cache,Values.STRING(ret),st);

    case (cache,env,_,b,(st as GlobalScript.SYMBOLTABLE(ast = p)),msg)
      equation
        ret = stringAppend("Error checking: ", Absyn.pathString(className));
    then
      (cache,Values.STRING(ret),st);
  end matchcontinue;
end checkAllModelsRecursive;

function failOrSuccess
"@author adrpo"
  input String inStr;
  output String outStr;
algorithm
  outStr := matchcontinue(inStr)
    local Integer res;
    case _
      equation
        res = System.stringFind(inStr, "successfully");
        true = (res >= 0);
      then "OK";
    case (_) then "FAILED!";
  end matchcontinue;
end failOrSuccess;

function checkAll
"@author adrpo
 checks all models and returns number of variables and equations"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Path> allClasses;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
algorithm
  _ := matchcontinue (inCache,inEnv,allClasses,inInteractiveSymbolTable,inMsg)
    local
      list<Absyn.Path> rest;
      Absyn.Path className;
      GlobalScript.SymbolTable st;
      Absyn.Program p;
      Absyn.Msg msg;
      Env.Cache cache;
      String  str, s;
      list<Env.Frame> env;
      Real t1, t2, elapsedTime;
      Absyn.ComponentRef cr;
      Absyn.Class c;
    case (cache,env,{},_,_) then ();

    case (cache,env,className::rest,(st as GlobalScript.SYMBOLTABLE(ast = p)),msg)
      equation
        c = Interactive.getPathedClassInProgram(className, p);
        // filter out partial classes
        // Absyn.CLASS(partialPrefix = false) = c; // do not filter partial classes
        cr = Absyn.pathToCref(className);
        // filter out packages
        false = Interactive.isPackage(className, p);
        // filter out functions
        // false = Interactive.isFunction(cr, p);
        // filter out types
        false = Interactive.isType(cr, p);
        print("Checking: " +& Dump.unparseClassAttributesStr(c) +& " " +& Absyn.pathString(className) +& "... ");
        t1 = clock();
        Flags.setConfigBool(Flags.CHECK_MODEL, true);
        (_,Values.STRING(str),_) = checkModel(Env.emptyCache(), env, className, st, msg);
        Flags.setConfigBool(Flags.CHECK_MODEL, false);
        (_,Values.STRING(str),_) = checkModel(Env.emptyCache(), env, className, st, msg);
        t2 = clock(); elapsedTime = t2 -. t1; s = realString(elapsedTime);
        print (s +& " seconds -> " +& failOrSuccess(str) +& "\n\t");
        print (System.stringReplace(str, "\n", "\n\t"));
        print ("\n");
        checkAll(cache, env, rest, st, msg);
      then
        ();

    case (cache,env,className::rest,(st as GlobalScript.SYMBOLTABLE(ast = p)),msg)
      equation
        c = Interactive.getPathedClassInProgram(className, p);
        print("Checking skipped: " +& Dump.unparseClassAttributesStr(c) +& " " +& Absyn.pathString(className) +& "... \n");
        checkAll(cache, env, rest, st, msg);
      then
        ();
  end matchcontinue;
end checkAll;

public function buildModelBeast " copy & pasted by: Otto
 translates and builds the model by running compiler script on the generated makefile"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Values.Value> vals;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  output Env.Cache outCache;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
  output String compileDir;
  output String outString1 "className";
  output String outString2 "method";
  output String outString4 "initFileName";
algorithm
  (outCache,outInteractiveSymbolTable,compileDir,outString1,outString2,outString4):=
  match (inCache,inEnv,vals,inInteractiveSymbolTable,inMsg)
    local
      GlobalScript.SymbolTable st,st2;
      BackendDAE.BackendDAE indexed_dlow_1;
      list<String> libs;
      String file_dir,method_str,filenameprefix,s3;
      Absyn.Path classname;
      Absyn.Program p,p2;
      Absyn.Class cdef;
      list<Env.Frame> env;
      Values.Value starttime,stoptime,interval,method,tolerance,options;
      Absyn.Msg msg;
      Absyn.Within win1;
      Env.Cache cache;
      SimCode.SimulationSettings simSettings;
      Absyn.TimeStamp ts;

    // normal call
    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),starttime,stoptime,interval,tolerance, method,Values.STRING(filenameprefix),options},(st as GlobalScript.SYMBOLTABLE(ast = p  as Absyn.PROGRAM(globalBuildTimes=ts))),msg)
      equation
        cdef = Interactive.getPathedClassInProgram(classname,p);
        Error.clearMessages() "Clear messages";
        compileDir = System.pwd() +& System.pathDelimiter();
        (cache,simSettings) = calculateSimulationSettings(cache,env,vals,st,msg);
        (cache,st,indexed_dlow_1,libs,file_dir,_)
          = translateModel(cache,env, classname, st, filenameprefix,true,SOME(simSettings));
        SimCode.SIMULATION_SETTINGS(method = method_str) = simSettings;
        //cname_str = Absyn.pathString(classname);
        //(cache,init_filename,starttime_r,stoptime_r,interval_r,tolerance_r,method_str,options_str,outputFormat_str)
        //= calculateSimulationSettings(cache,env, exp, st, msg, cname_str);
        //SimCodeUtil.generateInitData(indexed_dlow_1, classname, filenameprefix, init_filename, starttime_r, stoptime_r, interval_r,tolerance_r,method_str,options_str,outputFormat_str);
        Debug.fprintln(Flags.DYN_LOAD, "buildModel: about to compile model " +& filenameprefix +& ", " +& file_dir);
        compileModel(filenameprefix, libs, file_dir, method_str);
        Debug.fprintln(Flags.DYN_LOAD, "buildModel: Compiling done.");
        // SimCodegen.generateMakefileBeast(makefilename, filenameprefix, libs, file_dir);
        win1 = getWithinStatement(classname);
        p2 = Absyn.PROGRAM({cdef},win1,ts);
        compileModel(filenameprefix, libs, file_dir,method_str);
        // (p as Absyn.PROGRAM(globalBuildTimes=Absyn.TIMESTAMP(r1,r2))) = Interactive.updateProgram2(p2,p,false);
        st2 = st; // Interactive.replaceSymbolTableProgram(st,p);
      then
        (cache,st2,compileDir,filenameprefix,"","");

    // failure
    case (_,_,_,_,_)
      then
        fail();
  end match;
end buildModelBeast;

protected function generateFunctionName
"@author adrpo:
 generate the function name from a path."
  input Absyn.Path functionPath;
  output String functionName;
algorithm
  functionName := System.unquoteIdentifier(Absyn.pathStringReplaceDot(functionPath, "_"));
end generateFunctionName;

protected function generateFunctionFileName
"@author adrpo:
 generate the function name from a path."
  input Absyn.Path functionPath;
  output String functionName;
algorithm
  functionName := matchcontinue(functionPath)
    local String name, n1, n2; Integer len;
    case (_)
      equation
        name = Absyn.pathStringReplaceDot(functionPath, "_");
        name = System.unquoteIdentifier(name);
        len = stringLength(name);
        // not bigger than
        true = len > Global.maxFunctionFileLength;
        n1 = Absyn.pathFirstIdent(functionPath);
        n2 = Absyn.pathLastIdent(functionPath);
        name = System.unquoteIdentifier(n1 +& "_" +& n2);
        name = name +& "_" +& intString(tick()); 
      then
        name;
    case (_)
      equation
        name = Absyn.pathStringReplaceDot(functionPath, "_");
        name = System.unquoteIdentifier(name);
      then
        name;
  end matchcontinue;
end generateFunctionFileName;

public function getFunctionDependencies
"returns all function dependencies as paths, also the main function and the function tree"
  input Env.Cache cache;
  input Absyn.Path functionName;
  output DAE.Function mainFunction "the main function";
  output list<Absyn.Path> dependencies "the dependencies as paths";
  output DAE.FunctionTree funcs "the function tree";
algorithm
  funcs := Env.getFunctionTree(cache);
  // First check if the main function exists... If it does not it might be an interactive function...
  mainFunction := DAEUtil.getNamedFunction(functionName, funcs);
  dependencies := SimCodeMain.getCalledFunctionsInFunction(functionName,funcs);
end getFunctionDependencies;

public function collectDependencies
"collects all function dependencies, also the main function, uniontypes, metarecords"
  input Env.Cache inCache;
  input Env.Env env;
  input Absyn.Path functionName;
  output Env.Cache outCache;
  output DAE.Function mainFunction;
  output list<DAE.Function> dependencies;
  output list<DAE.Type> metarecordTypes;
protected
  list<Absyn.Path> uniontypePaths,paths;
  DAE.FunctionTree funcs;
algorithm
  (mainFunction, paths, funcs) := getFunctionDependencies(inCache, functionName);
  // The list of functions is not ordered, so we need to filter out the main function...
  dependencies := List.map1(paths, DAEUtil.getNamedFunction, funcs);
  dependencies := List.setDifference(dependencies, {mainFunction});
  uniontypePaths := DAEUtil.getUniontypePaths(dependencies,{});
  (outCache,metarecordTypes) := Lookup.lookupMetarecordsRecursive(inCache, env, uniontypePaths);
end collectDependencies;

public function cevalGenerateFunction "Generates code for a given function name."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Program program;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output String functionName;
  output String functionFileName;
algorithm
  (outCache,functionName,functionFileName) := matchcontinue (inCache,inEnv,program,inPath)
    local
      String pathstr, fileName;
      list<Env.Frame> env;
      Absyn.Path path;
      Env.Cache cache;
      DAE.Function mainFunction;
      list<DAE.Function> d;
      list<DAE.Type> metarecordTypes;
      DAE.FunctionTree funcs;
    // template based translation
    case (cache, env, _, path)
      equation
        true = Flags.isSet(Flags.GEN);
        false = Flags.isSet(Flags.GENERATE_CODE_CHEAT);

        (cache, mainFunction, d, metarecordTypes) = collectDependencies(cache, env, path);

        pathstr  = generateFunctionName(path);
        fileName = generateFunctionFileName(path);
        SimCodeMain.translateFunctions(program, fileName, SOME(mainFunction), d, metarecordTypes, {});
        compileModel(fileName, {}, "", "");
      then
        (cache, pathstr, fileName);

    // Cheat if we want to generate code for Main.main
    // * Don't do dependency analysis of what functions to generate; just generate all of them
    // * Don't generate extra code for unreferenced MetaRecord types (for external functions)
    //   This could be an annotation instead anyway.
    // * Don't compile the generated files
    case (cache, env, _, path)
      equation
        true = Flags.isSet(Flags.GEN);
        true = Flags.isSet(Flags.GENERATE_CODE_CHEAT);
        funcs = Env.getFunctionTree(cache);
        // First check if the main function exists... If it does not it might be an interactive function...
        pathstr = generateFunctionName(path);
        fileName = generateFunctionFileName(path);
        // The list of functions is not ordered, so we need to filter out the main function...
        d = DAEUtil.getFunctionList(funcs);
        SimCodeMain.translateFunctions(program, fileName, NONE(), d, {}, {});
      then
        (cache, pathstr, fileName);

    case (cache, env, _, path)
      equation
        true = Flags.isSet(Flags.GEN);
        (cache,false) = Static.isExternalObjectFunction(cache,env,path);
        pathstr = generateFunctionName(path);
        fileName = generateFunctionFileName(path);
        pathstr = "CevalScript.cevalGenerateFunction failed:\nfunction: " +& pathstr +& "\nfile: " +& fileName +& "\n";
        Debug.fprint(Flags.FAILTRACE, pathstr);
      then
        fail();
  end matchcontinue;
end cevalGenerateFunction;

protected function generateFunctions
  input Env.Cache icache;
  input Env.Env ienv;
  input Absyn.Program p;
  input list<SCode.Element> isp;
  input Boolean cleanCache;
  output Env.Cache cache;
  output Env.Env env;
algorithm
  (cache,env) := match (icache,ienv,p,isp,cleanCache)
    local
      String name;
      list<String> names,dependencies;
      list<Absyn.Path> paths;
      list<SCode.Element> elementLst;
      DAE.FunctionTree funcs;
      list<DAE.Function> d;
      list<tuple<String,list<String>>> acc;
      list<SCode.Element> sp;
      String file,nameHeader,str;
      Integer n;
      Absyn.Info info;
      SCode.Element cl;

    case (cache,env,_,{},_) then (cache,env);
    case (cache,env,_,(cl as SCode.CLASS(name=name,encapsulatedPrefix=SCode.ENCAPSULATED(),restriction=SCode.R_PACKAGE(),classDef=SCode.PARTS(elementLst=elementLst),info=info))::sp,_)
      equation
        (cache,env) = generateFunctions2(cache,env,p,cl,name,elementLst,info,cleanCache);
        (cache,env) = generateFunctions(cache,env,p,sp,cleanCache);
      then (cache,env);
    case (cache,env,_,SCode.CLASS(encapsulatedPrefix=SCode.NOT_ENCAPSULATED(),name=name,info=info as Absyn.INFO(fileName=file))::sp,_)
      equation
        (n,_) = System.regex(file, "ModelicaBuiltin.mo$", 1, false, false);
        Error.assertion(n > 0, "Not an encapsulated class (required for separate compilation): " +& name, info);
      then fail();
  end match;
end generateFunctions;

protected function generateFunctions2
  input Env.Cache icache;
  input Env.Env ienv;
  input Absyn.Program p;
  input SCode.Element cl;
  input String name;
  input list<SCode.Element> elementLst;
  input Absyn.Info info;
  input Boolean cleanCache;
  output Env.Cache cache;
  output Env.Env env;
algorithm
  (cache,env) := matchcontinue (icache,ienv,p,cl,name,elementLst,info,cleanCache)
    local
      list<String> names,dependencies,strs;
      list<Absyn.Path> paths;
      DAE.FunctionTree funcs;
      list<DAE.Function> d;
      list<tuple<String,list<String>>> acc;
      list<SCode.Element> sp;
      String file,nameHeader,str;
      Integer n;

    case (cache,env,_,_,_,_,Absyn.INFO(fileName=file),_)
      equation
        (1,_) = System.regex(file, "ModelicaBuiltin.mo$", 1, false, false);
      then (cache,env);

    case (cache,env,_,_,_,_,_,_)
      equation
        cache = Util.if_(cleanCache, Env.emptyCache(), cache);
        paths = List.fold1(elementLst, findFunctionsToCompile, Absyn.FULLYQUALIFIED(Absyn.IDENT(name)), {});
        cache = instantiateDaeFunctions(cache, env, paths);
        funcs = Env.getFunctionTree(cache);
        d = List.map2(paths, DAEUtil.getNamedFunctionWithError, funcs, info);
        (_,(_,dependencies)) = DAEUtil.traverseDAEFunctions(d,Expression.traverseSubexpressionsHelper,(matchQualifiedCalls,{}),{});
        // print(name +& " has dependencies: " +& stringDelimitList(dependencies,",") +& "\n");
        dependencies = List.sort(dependencies,Util.strcmpBool);
        dependencies = List.map1(dependencies,stringAppend,".h");
        nameHeader = name +& ".h";
        strs = List.map1r(nameHeader::dependencies, stringAppend, "$(GEN_DIR)");
        System.writeFile(name +& ".deps", "$(GEN_DIR)" +& name +& ".o: $(GEN_DIR)" +& name +& ".c" +& " " +& stringDelimitList(strs," "));
        dependencies = List.map1(dependencies,stringAppend,"\"");
        dependencies = List.map1r(dependencies,stringAppend,"#include \"");
        SimCodeMain.translateFunctions(p, name, NONE(), d, {}, dependencies);
        str = Tpl.tplString(Unparsing.programExternalHeader, {cl});
        System.writeFile(name +& "_records.c","#include <meta/meta_modelica.h>\n" +& str);
        cache = Util.if_(cleanCache, icache, cache);
      then (cache,env);
    else
      equation
        Error.addSourceMessage(Error.SEPARATE_COMPILATION_PACKAGE_FAILED,{name},info);
      then fail();
  end matchcontinue;
end generateFunctions2;

protected function matchQualifiedCalls
"Collects the packages used by the functions"
  input tuple<DAE.Exp,list<String>> itpl;
  output tuple<DAE.Exp,list<String>> otpl;
algorithm
  otpl := match itpl
    local
      DAE.Exp e;
      list<String> acc;
      String name;
      DAE.ComponentRef cr;
    case ((e as DAE.CALL(path = Absyn.FULLYQUALIFIED(Absyn.QUALIFIED(name=name)), attr = DAE.CALL_ATTR(builtin = false)),acc))
      equation
        acc = List.consOnTrue(not listMember(name,acc),name,acc);
      then ((e,acc));
    case ((e as DAE.CREF(componentRef=cr,ty=DAE.T_FUNCTION_REFERENCE_FUNC(builtin=false)),acc))
      equation
        Absyn.QUALIFIED(name,Absyn.IDENT(_)) = ComponentReference.crefToPath(cr);
        acc = List.consOnTrue(not listMember(name,acc),name,acc);
      then ((e,acc));
    case _ then itpl;
  end match;
end matchQualifiedCalls;

protected function instantiateDaeFunctions
  input Env.Cache icache;
  input Env.Env ienv;
  input list<Absyn.Path> ipaths;
  output Env.Cache outCache;
algorithm
  outCache := match (icache,ienv,ipaths)
    local
      Absyn.Path path;
      Env.Cache cache; Env.Env env;
      list<Absyn.Path> paths;
    case (cache,env,{}) then cache;
    case (cache,env,path::paths)
      equation
        // print("force inst: " +& Absyn.pathString(path));
        (cache,Util.SUCCESS()) = Static.instantiateDaeFunctionForceInst(cache,env,path,false,NONE(),true);
        // print(" ok\n");
        cache = instantiateDaeFunctions(cache,env,paths);
      then cache;
  end match;
end instantiateDaeFunctions;

protected function getBasePathFromUri "Handle modelica:// URIs"
  input String scheme;
  input String iname;
  input Absyn.Program program;
  input String modelicaPath;
  input Boolean printError;
  output String basePath;
algorithm
  basePath := matchcontinue (scheme,iname,program,modelicaPath,printError)
    local
      Boolean isDir;
      list<String> mps,names;
      String gd,mp,bp,str,name,version,fileName;
    case ("modelica://",name,_,mp,_)
      equation
        (name::names) = System.strtok(name,".");
        Absyn.CLASS(info=Absyn.INFO(fileName=fileName)) = Interactive.getPathedClassInProgram(Absyn.IDENT(name),program);
        mp = System.dirname(fileName);
        bp = findModelicaPath2(mp,names,"",true);
      then bp;
    case ("modelica://",name,_,mp,_)
      equation
        (name::names) = System.strtok(name,".");
        failure(_ = Interactive.getPathedClassInProgram(Absyn.IDENT(name),program));
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        (mp,name,isDir) = System.getLoadModelPath(name,{"default"},mps);
        mp = Util.if_(isDir,mp +& name,mp);
        bp = findModelicaPath2(mp,names,"",true);
      then bp;
    case ("file://",_,_,_,_) then "";
    case ("modelica://",name,_,mp,true)
      equation
        name::_ = System.strtok(name,".");
        str = "Could not resolve modelica://" +& name +& " with MODELICAPATH: " +& mp;
        Error.addMessage(Error.COMPILER_ERROR,{str});
      then fail();
  end matchcontinue;
end getBasePathFromUri;

protected function findModelicaPath "Handle modelica:// URIs"
  input list<String> imps;
  input list<String> names;
  input String version;
  output String basePath;
algorithm
  basePath := matchcontinue (imps,names,version)
    local
      String mp;
      list<String> mps;

    case (mp::_,_,_)
      then findModelicaPath2(mp,names,version,false);
    case (_::mps,_,_)
      then findModelicaPath(mps,names,version);
  end matchcontinue;
end findModelicaPath;

protected function findModelicaPath2 "Handle modelica:// URIs"
  input String mp;
  input list<String> inames;
  input String version;
  input Boolean b;
  output String basePath;
algorithm
  basePath := matchcontinue (mp,inames,version,b)
    local
      list<String> names;
      String name,file;

    case (_,name::names,_,_)
      equation
        false = stringEq(version,"");
        file = mp +& "/" +& name +& " " +& version;
        true = System.directoryExists(file);
        // print("Found file 1: " +& file +& "\n");
      then findModelicaPath2(file,names,"",true);
    case (_,name::names,_,_)
      equation
        false = stringEq(version,"");
        file = mp +& "/" +& name +& " " +& version +& ".mo";
        true = System.regularFileExists(file);
        // print("Found file 2: " +& file +& "\n");
      then mp;

    case (_,name::names,_,_)
      equation
        file = mp +& "/" +& name;
        true = System.directoryExists(file);
        // print("Found file 3: " +& file +& "\n");
      then findModelicaPath2(file,names,"",true);
    case (_,name::names,_,_)
      equation
        file = mp +& "/" +& name +& ".mo";
        true = System.regularFileExists(file);
        // print("Found file 4: " +& file +& "\n");
      then mp;

      // This class is part of the current package.mo, or whatever...
    case (_,_,_,true)
      equation
        // print("Did not find file 5: " +& mp +& " - " +& name +& "\n");
      then mp;
  end matchcontinue;
end findModelicaPath2;

public function getFullPathFromUri
  input Absyn.Program program;
  input String uri;
  input Boolean printError;
  output String path;
protected
  String str1,str2,str3;
algorithm
  (str1,str2,str3) := System.uriToClassAndPath(uri);
  path := getBasePathFromUri(str1,str2,program,Settings.getModelicaPath(Config.getRunningTestsuite()),printError) +& str3;
end getFullPathFromUri;

protected function errorToValue
  input Error.TotalMessage err;
  output Values.Value val;
algorithm
  val := match err
    local
      Absyn.Path msgpath;
      Values.Value tyVal,severityVal,infoVal;
      list<Values.Value> values;
      Util.TranslatableContent message;
      String msg_str;
      Integer id;
      Error.Severity severity;
      Error.MessageType ty;
      Absyn.Info info;
    case Error.TOTALMESSAGE(Error.MESSAGE(id,ty,severity,message),info)
      equation
        msg_str = Util.translateContent(message);
        msgpath = Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("OpenModelica",Absyn.QUALIFIED("Scripting",Absyn.IDENT("ErrorMessage"))));
        tyVal = errorTypeToValue(ty);
        severityVal = errorLevelToValue(severity);
        infoVal = infoToValue(info);
        values = {infoVal,Values.STRING(msg_str),tyVal,severityVal,Values.INTEGER(id)};
      then Values.RECORD(msgpath,values,{"info","message","kind","level","id"},-1);
  end match;
end errorToValue;

protected function infoToValue
  input Absyn.Info info;
  output Values.Value val;
algorithm
  val := match info
    local
      list<Values.Value> values;
      Absyn.Path infopath;
      Integer ls,cs,le,ce;
      String filename;
      Boolean readonly;
    case Absyn.INFO(filename,readonly,ls,cs,le,ce,_)
      equation
        infopath = Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("OpenModelica",Absyn.QUALIFIED("Scripting",Absyn.IDENT("SourceInfo"))));
        values = {Values.STRING(filename),Values.BOOL(readonly),Values.INTEGER(ls),Values.INTEGER(cs),Values.INTEGER(le),Values.INTEGER(ce)};
      then Values.RECORD(infopath,values,{"filename","readonly","lineStart","columnStart","lineEnd","columnEnd"},-1);
  end match;
end infoToValue;

protected function makeErrorEnumLiteral
  input String enumName;
  input String enumField;
  input Integer index;
  output Values.Value val;
  annotation(__OpenModelica_EarlyInline=true);
algorithm
  val := Values.ENUM_LITERAL(Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("OpenModelica",Absyn.QUALIFIED("Scripting",Absyn.QUALIFIED(enumName,Absyn.IDENT(enumField))))),index);
end makeErrorEnumLiteral;

protected function errorTypeToValue
  input Error.MessageType ty;
  output Values.Value val;
algorithm
  val := match ty
    case Error.SYNTAX() then makeErrorEnumLiteral("ErrorKind","syntax",1);
    case Error.GRAMMAR() then makeErrorEnumLiteral("ErrorKind","grammar",2);
    case Error.TRANSLATION() then makeErrorEnumLiteral("ErrorKind","translation",3);
    case Error.SYMBOLIC() then makeErrorEnumLiteral("ErrorKind","symbolic",4);
    case Error.SIMULATION() then makeErrorEnumLiteral("ErrorKind","runtime",5);
    case Error.SCRIPTING() then makeErrorEnumLiteral("ErrorKind","scripting",6);
    else
      equation
        print("errorTypeToValue failed\n");
      then fail();
  end match;
end errorTypeToValue;

protected function errorLevelToValue
  input Error.Severity severity;
  output Values.Value val;
algorithm
  val := match severity
    case Error.ERROR() then makeErrorEnumLiteral("ErrorLevel","error",1);
    case Error.WARNING() then makeErrorEnumLiteral("ErrorLevel","warning",2);
    case Error.NOTIFICATION() then makeErrorEnumLiteral("ErrorLevel","notification",3);
    else
      equation
        print("errorLevelToValue failed\n");
      then fail();
  end match;
end errorLevelToValue;

protected function getVariableNames
  input list<GlobalScript.Variable> vars;
  input list<Values.Value> acc;
  output list<Values.Value> ovars;
algorithm
  ovars := match (vars,acc)
    local
      list<GlobalScript.Variable> vs;
      String p;
    case ({},_) then listReverse(acc);
    case (GlobalScript.IVAR(varIdent = "$echo") :: vs,_)
      then getVariableNames(vs,acc);
    case (GlobalScript.IVAR(varIdent = p) :: vs,_)
      then getVariableNames(vs,Values.CODE(Absyn.C_VARIABLENAME(Absyn.CREF_IDENT(p,{})))::acc);
  end match;
end getVariableNames;

protected function getAlgorithms
"Counts the number of Algorithm sections in a class."
  input Absyn.Class inClass;
  output list<Absyn.ClassPart> outList;
algorithm
  outList := match (inClass)
    local
      list<Absyn.ClassPart> algsList;
      list<Absyn.ClassPart> parts;
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        algsList = getAlgorithmsInClassParts(parts);
      then
        algsList;
    // check also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        algsList = getAlgorithmsInClassParts(parts);
      then
        algsList;
    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = _)) then {};
  end match;
end getAlgorithms;

protected function getAlgorithmsInClassParts
"Helper function to getAlgorithms"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ClassPart> outList;
algorithm
  outList := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ClassPart> algsList;
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.ClassPart> xs;
      Absyn.ClassPart cp;
    case ((cp as Absyn.ALGORITHMS(contents = algs)) :: xs)
      equation
        algsList = getAlgorithmsInClassParts(xs);
      then
        cp::algsList;
    case ((_ :: xs))
      equation
        algsList = getAlgorithmsInClassParts(xs);
      then
        algsList;
    case ({}) then {};
  end matchcontinue;
end getAlgorithmsInClassParts;

protected function getNthAlgorithm
"Returns the Nth Algorithm section from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output String outString;
  protected list<Absyn.ClassPart> algsList;
algorithm
  algsList := getAlgorithms(inClass);
  outString := getNthAlgorithmInClass(listGet(algsList, inInteger));
end getNthAlgorithm;

protected function getNthAlgorithmInClass
"Helper function to getNthAlgorithm."
  input Absyn.ClassPart inClassPart;
  output String outString;
algorithm
  outString := match (inClassPart)
    local
      String str;
      list<Absyn.AlgorithmItem> algs;
  case (Absyn.ALGORITHMS(contents = algs))
      equation
        str = Dump.unparseAlgorithmStrLst(algs, "\n");
      then
        str;
  end match;
end getNthAlgorithmInClass;

protected function getInitialAlgorithms
"Counts the number of Initial Algorithm sections in a class."
  input Absyn.Class inClass;
  output list<Absyn.ClassPart> outList;
algorithm
  outList := match (inClass)
    local
      list<Absyn.ClassPart> algsList;
      list<Absyn.ClassPart> parts;
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        algsList = getInitialAlgorithmsInClassParts(parts);
      then
        algsList;
    // check also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        algsList = getInitialAlgorithmsInClassParts(parts);
      then
        algsList;
    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = _)) then {};
  end match;
end getInitialAlgorithms;

protected function getInitialAlgorithmsInClassParts
"Helper function to getInitialAlgorithms"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ClassPart> outList;
algorithm
  outList := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ClassPart> algsList;
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.ClassPart> xs;
      Absyn.ClassPart cp;
    case ((cp as Absyn.INITIALALGORITHMS(contents = algs)) :: xs)
      equation
        algsList = getInitialAlgorithmsInClassParts(xs);
      then
        cp::algsList;
    case ((_ :: xs))
      equation
        algsList = getInitialAlgorithmsInClassParts(xs);
      then
        algsList;
    case ({}) then {};
  end matchcontinue;
end getInitialAlgorithmsInClassParts;

protected function getNthInitialAlgorithm
"Returns the Nth Initial Algorithm section from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output String outString;
  protected list<Absyn.ClassPart> algsList;
algorithm
  algsList := getInitialAlgorithms(inClass);
  outString := getNthInitialAlgorithmInClass(listGet(algsList, inInteger));
end getNthInitialAlgorithm;

protected function getNthInitialAlgorithmInClass
"Helper function to getNthInitialAlgorithm."
  input Absyn.ClassPart inClassPart;
  output String outString;
algorithm
  outString := match (inClassPart)
    local
      String str;
      list<Absyn.AlgorithmItem> algs;
  case (Absyn.INITIALALGORITHMS(contents = algs))
      equation
        str = Dump.unparseAlgorithmStrLst(algs, "\n");
      then
        str;
  end match;
end getNthInitialAlgorithmInClass;

protected function getAlgorithmItemsCount
"Counts the number of Algorithm items in a class."
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm
  outInteger := match (inClass)
    local
      list<Absyn.ClassPart> parts;
      Integer count;
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        count = getAlgorithmItemsCountInClassParts(parts);
      then
        count;
    // check also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        count = getAlgorithmItemsCountInClassParts(parts);
      then
        count;
    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = _)) then 0;
  end match;
end getAlgorithmItemsCount;

protected function getAlgorithmItemsCountInClassParts
"Helper function to getAlgorithmItemsCount"
 input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.ClassPart> xs;
      Integer c1, c2, res;
    case (Absyn.ALGORITHMS(contents = algs) :: xs)
      equation
        c1 = getAlgorithmItemsCountInAlgorithmItems(algs);
        c2 = getAlgorithmItemsCountInClassParts(xs);
      then
        c1 + c2;
    case ((_ :: xs))
      equation
        res = getAlgorithmItemsCountInClassParts(xs);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end getAlgorithmItemsCountInClassParts;

protected function getAlgorithmItemsCountInAlgorithmItems
"Helper function to getAlgorithmItemsCountInClassParts"
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynAlgorithmItemLst)
    local
      list<Absyn.AlgorithmItem> xs;
      Absyn.Algorithm alg;
      Integer c1, res;
    case (Absyn.ALGORITHMITEM(algorithm_ = alg) :: xs)
      equation
        c1 = getAlgorithmItemsCountInAlgorithmItems(xs);
      then
        c1 + 1;
    case ((_ :: xs))
      equation
        res = getAlgorithmItemsCountInAlgorithmItems(xs);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end getAlgorithmItemsCountInAlgorithmItems;

protected function getNthAlgorithmItem
"Returns the Nth Algorithm Item from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output String outString;
algorithm
  outString := match (inClass,inInteger)
    local
      list<Absyn.ClassPart> parts;
      String str;
      Integer n;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),n)
      equation
        str = getNthAlgorithmItemInClassParts(parts,n);
      then
        str;
    // check also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),n)
      equation
        str = getNthAlgorithmItemInClassParts(parts,n);
      then
        str;
  end match;
end getNthAlgorithmItem;

protected function getNthAlgorithmItemInClassParts
"Helper function to getNthAlgorithmItem"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynClassPartLst,inInteger)
    local
      String str;
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.ClassPart> xs;
      Integer n,c1,newn;
    case ((Absyn.ALGORITHMS(contents = algs) :: xs),n)
      equation
        str = getNthAlgorithmItemInAlgorithms(algs, n);
      then
        str;
    case ((Absyn.ALGORITHMS(contents = algs) :: xs),n) /* The rule above failed, subtract the number of algorithms in the first section and try with the rest of the classparts */
      equation
        c1 = getAlgorithmItemsCountInAlgorithmItems(algs);
        newn = n - c1;
        str = getNthAlgorithmItemInClassParts(xs, newn);
      then
        str;
    case ((_ :: xs),n)
      equation
        str = getNthAlgorithmItemInClassParts(xs, n);
      then
        str;
  end matchcontinue;
end getNthAlgorithmItemInClassParts;

protected function getNthAlgorithmItemInAlgorithms
" This function takes an Algorithm list and an int
   and returns the nth algorithm item as String.
   If the number is larger than the number of algorithms
   in the list, the function fails. Helper function to getNthAlgorithmItemInClassParts."
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynAlgorithmItemLst,inInteger)
    local
      String str;
      Absyn.Algorithm alg;
      Option<Absyn.Comment> cmt;
      Absyn.Info inf;
      list<Absyn.AlgorithmItem> xs;
      Integer newn,n;
    case ((Absyn.ALGORITHMITEM(algorithm_ = alg, comment = cmt, info = inf) :: xs), 1)
      equation
        str = Dump.unparseAlgorithmStr(Absyn.ALGORITHMITEM(alg, cmt, inf));
      then
        str;
    case ((_ :: xs),n)
      equation
        newn = n - 1;
        str = getNthAlgorithmItemInAlgorithms(xs, newn);
      then
        str;
    case ({},_) then fail();
  end matchcontinue;
end getNthAlgorithmItemInAlgorithms;

protected function getInitialAlgorithmItemsCount
"Counts the number of Initial Algorithm items in a class."
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm
  outInteger := match (inClass)
    local
      list<Absyn.ClassPart> parts;
      Integer count;
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        count = getInitialAlgorithmItemsCountInClassParts(parts);
      then
        count;
    // check also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        count = getInitialAlgorithmItemsCountInClassParts(parts);
      then
        count;
    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = _)) then 0;
  end match;
end getInitialAlgorithmItemsCount;

protected function getInitialAlgorithmItemsCountInClassParts
"Helper function to getInitialAlgorithmItemsCount"
 input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.ClassPart> xs;
      Integer c1, c2, res;
    case (Absyn.INITIALALGORITHMS(contents = algs) :: xs)
      equation
        c1 = getAlgorithmItemsCountInAlgorithmItems(algs);
        c2 = getInitialAlgorithmItemsCountInClassParts(xs);
      then
        c1 + c2;
    case ((_ :: xs))
      equation
        res = getInitialAlgorithmItemsCountInClassParts(xs);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end getInitialAlgorithmItemsCountInClassParts;

protected function getNthInitialAlgorithmItem
"Returns the Nth Initial Algorithm Item from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output String outString;
algorithm
  outString := match (inClass,inInteger)
    local
      list<Absyn.ClassPart> parts;
      String str;
      Integer n;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),n)
      equation
        str = getNthInitialAlgorithmItemInClassParts(parts,n);
      then
        str;
    // check also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),n)
      equation
        str = getNthInitialAlgorithmItemInClassParts(parts,n);
      then
        str;
  end match;
end getNthInitialAlgorithmItem;

protected function getNthInitialAlgorithmItemInClassParts
"Helper function to getNthInitialAlgorithmItem"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynClassPartLst,inInteger)
    local
      String str;
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.ClassPart> xs;
      Integer n,c1,newn;
    case ((Absyn.INITIALALGORITHMS(contents = algs) :: xs),n)
      equation
        str = getNthAlgorithmItemInAlgorithms(algs, n);
      then
        str;
    case ((Absyn.INITIALALGORITHMS(contents = algs) :: xs),n) /* The rule above failed, subtract the number of algorithms in the first section and try with the rest of the classparts */
      equation
        c1 = getAlgorithmItemsCountInAlgorithmItems(algs);
        newn = n - c1;
        str = getNthInitialAlgorithmItemInClassParts(xs, newn);
      then
        str;
    case ((_ :: xs),n)
      equation
        str = getNthInitialAlgorithmItemInClassParts(xs, n);
      then
        str;
  end matchcontinue;
end getNthInitialAlgorithmItemInClassParts;

protected function getEquations
"Counts the number of Equation sections in a class."
  input Absyn.Class inClass;
  output list<Absyn.ClassPart> outList;
algorithm
  outList := match (inClass)
    local
      list<Absyn.ClassPart> eqsList;
      list<Absyn.ClassPart> parts;
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        eqsList = getEquationsInClassParts(parts);
      then
        eqsList;
    // check also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        eqsList = getEquationsInClassParts(parts);
      then
        eqsList;
    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = _)) then {};
  end match;
end getEquations;

protected function getEquationsInClassParts
"Helper function to getEquations"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ClassPart> outList;
algorithm
  outList := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ClassPart> eqsList;
      list<Absyn.EquationItem> eqs;
      list<Absyn.ClassPart> xs;
      Absyn.ClassPart cp;
    case ((cp as Absyn.EQUATIONS(contents = eqs)) :: xs)
      equation
        eqsList = getEquationsInClassParts(xs);
      then
        cp::eqsList;
    case ((_ :: xs))
      equation
        eqsList = getEquationsInClassParts(xs);
      then
        eqsList;
    case ({}) then {};
  end matchcontinue;
end getEquationsInClassParts;

protected function getNthEquation
"Returns the Nth Equation section from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output String outString;
  protected list<Absyn.ClassPart> eqsList;
algorithm
  eqsList := getEquations(inClass);
  outString := getNthEquationInClass(listGet(eqsList, inInteger));
end getNthEquation;

protected function getNthEquationInClass
"Helper function to getNthEquation"
  input Absyn.ClassPart inClassPart;
  output String outString;
algorithm
  outString := match (inClassPart)
    local
      String str;
      list<Absyn.EquationItem> eqs;
  case (Absyn.EQUATIONS(contents = eqs))
      equation
        str = Dump.unparseEquationItemStrLst(eqs, "\n");
      then
        str;
  end match;
end getNthEquationInClass;

protected function getInitialEquations
"Counts the number of Initial Equation sections in a class."
  input Absyn.Class inClass;
  output list<Absyn.ClassPart> outList;
algorithm
  outList := match (inClass)
    local
      list<Absyn.ClassPart> eqsList;
      list<Absyn.ClassPart> parts;
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        eqsList = getInitialEquationsInClassParts(parts);
      then
        eqsList;
    // check also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        eqsList = getInitialEquationsInClassParts(parts);
      then
        eqsList;
    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = _)) then {};
  end match;
end getInitialEquations;

protected function getInitialEquationsInClassParts
"Helper function to getInitialEquations"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ClassPart> outList;
algorithm
  outList := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ClassPart> eqsList;
      list<Absyn.EquationItem> eqs;
      list<Absyn.ClassPart> xs;
      Absyn.ClassPart cp;
    case ((cp as Absyn.INITIALEQUATIONS(contents = eqs)) :: xs)
      equation
        eqsList = getInitialEquationsInClassParts(xs);
      then
        cp::eqsList;
    case ((_ :: xs))
      equation
        eqsList = getInitialEquationsInClassParts(xs);
      then
        eqsList;
    case ({}) then {};
  end matchcontinue;
end getInitialEquationsInClassParts;

protected function getNthInitialEquation
"Returns the Nth Initial Equation section from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output String outString;
  protected list<Absyn.ClassPart> eqsList;
algorithm
  eqsList := getInitialEquations(inClass);
  outString := getNthInitialEquationInClass(listGet(eqsList, inInteger));
end getNthInitialEquation;

protected function getNthInitialEquationInClass
"Helper function to getNthInitialEquation."
  input Absyn.ClassPart inClassPart;
  output String outString;
algorithm
  outString := match (inClassPart)
    local
      String str;
      list<Absyn.EquationItem> eqs;
  case (Absyn.INITIALEQUATIONS(contents = eqs))
      equation
        str = Dump.unparseEquationItemStrLst(eqs, "\n");
      then
        str;
  end match;
end getNthInitialEquationInClass;

protected function getEquationItemsCount
"Counts the number of Equation items in a class."
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm
  outInteger := match (inClass)
    local
      list<Absyn.ClassPart> parts;
      Integer count;
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        count = getEquationItemsCountInClassParts(parts);
      then
        count;
    // check also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        count = getEquationItemsCountInClassParts(parts);
      then
        count;
    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = _)) then 0;
  end match;
end getEquationItemsCount;

protected function getEquationItemsCountInClassParts
"Helper function to getEquationItemsCount"
 input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.EquationItem> eqs;
      list<Absyn.ClassPart> xs;
      Integer c1, c2, res;
    case (Absyn.EQUATIONS(contents = eqs) :: xs)
      equation
        c1 = getEquationItemsCountInEquationItems(eqs);
        c2 = getEquationItemsCountInClassParts(xs);
      then
        c1 + c2;
    case ((_ :: xs))
      equation
        res = getEquationItemsCountInClassParts(xs);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end getEquationItemsCountInClassParts;

protected function getEquationItemsCountInEquationItems
"Helper function to getEquationItemsCountInClassParts"
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynEquationItemLst)
    local
      list<Absyn.EquationItem> xs;
      Absyn.Equation eq;
      Integer c1, res;
    case (Absyn.EQUATIONITEM(equation_ = eq) :: xs)
      equation
        c1 = getEquationItemsCountInEquationItems(xs);
      then
        c1 + 1;
    case ((_ :: xs))
      equation
        res = getEquationItemsCountInEquationItems(xs);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end getEquationItemsCountInEquationItems;

protected function getNthEquationItem
"Returns the Nth Equation Item from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output String outString;
algorithm
  outString := match (inClass,inInteger)
    local
      list<Absyn.ClassPart> parts;
      String str;
      Integer n;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),n)
      equation
        str = getNthEquationItemInClassParts(parts,n);
      then
        str;
    // check also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),n)
      equation
        str = getNthEquationItemInClassParts(parts,n);
      then
        str;
  end match;
end getNthEquationItem;

protected function getNthEquationItemInClassParts
"Helper function to getNthEquationItem"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynClassPartLst,inInteger)
    local
      String str;
      list<Absyn.EquationItem> eqs;
      list<Absyn.ClassPart> xs;
      Integer n,c1,newn;
    case ((Absyn.EQUATIONS(contents = eqs) :: xs),n)
      equation
        str = getNthEquationItemInEquations(eqs, n);
      then
        str;
    case ((Absyn.EQUATIONS(contents = eqs) :: xs),n) /* The rule above failed, subtract the number of equations in the first section and try with the rest of the classparts */
      equation
        c1 = getEquationItemsCountInEquationItems(eqs);
        newn = n - c1;
        str = getNthEquationItemInClassParts(xs, newn);
      then
        str;
    case ((_ :: xs),n)
      equation
        str = getNthEquationItemInClassParts(xs, n);
      then
        str;
  end matchcontinue;
end getNthEquationItemInClassParts;

protected function getNthEquationItemInEquations
" This function takes an Equation list and an int
   and returns the nth Equation item as String.
   If the number is larger than the number of algorithms
   in the list, the function fails. Helper function to getNthEquationItemInClassParts."
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynEquationItemLst,inInteger)
    local
      String str;
      Absyn.Equation eq;
      list<Absyn.EquationItem> xs;
      Integer newn,n;
    case ((Absyn.EQUATIONITEM(equation_ = eq) :: xs), 1)
      equation
        str = Dump.unparseEquationStr(eq);
        str = stringAppend(str, ";");
        str = System.trim(str, " ");
      then
        str;
    case ((_ :: xs),n)
      equation
        newn = n - 1;
        str = getNthEquationItemInEquations(xs, newn);
      then
        str;
    case ({},_) then fail();
  end matchcontinue;
end getNthEquationItemInEquations;

protected function getInitialEquationItemsCount
"Counts the number of Initial Equation items in a class."
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm
  outInteger := match (inClass)
    local
      list<Absyn.ClassPart> parts;
      Integer count;
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        count = getInitialEquationItemsCountInClassParts(parts);
      then
        count;
    // check also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        count = getInitialEquationItemsCountInClassParts(parts);
      then
        count;
    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = _)) then 0;
  end match;
end getInitialEquationItemsCount;

protected function getInitialEquationItemsCountInClassParts
"Helper function to getInitialEquationItemsCount"
 input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.EquationItem> eqs;
      list<Absyn.ClassPart> xs;
      Integer c1, c2, res;
    case (Absyn.INITIALEQUATIONS(contents = eqs) :: xs)
      equation
        c1 = getEquationItemsCountInEquationItems(eqs);
        c2 = getInitialEquationItemsCountInClassParts(xs);
      then
        c1 + c2;
    case ((_ :: xs))
      equation
        res = getInitialEquationItemsCountInClassParts(xs);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end getInitialEquationItemsCountInClassParts;

protected function getNthInitialEquationItem
"Returns the Nth Initial Equation Item from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output String outString;
algorithm
  outString := match (inClass,inInteger)
    local
      list<Absyn.ClassPart> parts;
      String str;
      Integer n;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),n)
      equation
        str = getNthInitialEquationItemInClassParts(parts,n);
      then
        str;
    // check also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),n)
      equation
        str = getNthInitialEquationItemInClassParts(parts,n);
      then
        str;
  end match;
end getNthInitialEquationItem;

protected function getNthInitialEquationItemInClassParts
"Helper function to getNthInitialEquationItem"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynClassPartLst,inInteger)
    local
      String str;
      list<Absyn.EquationItem> eqs;
      list<Absyn.ClassPart> xs;
      Integer n,c1,newn;
    case ((Absyn.INITIALEQUATIONS(contents = eqs) :: xs),n)
      equation
        str = getNthEquationItemInEquations(eqs, n);
      then
        str;
    case ((Absyn.INITIALEQUATIONS(contents = eqs) :: xs),n) /* The rule above failed, subtract the number of equations in the first section and try with the rest of the classparts */
      equation
        c1 = getEquationItemsCountInEquationItems(eqs);
        newn = n - c1;
        str = getNthInitialEquationItemInClassParts(xs, newn);
      then
        str;
    case ((_ :: xs),n)
      equation
        str = getNthInitialEquationItemInClassParts(xs, n);
      then
        str;
  end matchcontinue;
end getNthInitialEquationItemInClassParts;

protected function getAnnotationCount
"Counts the number of Annotation sections in a class."
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm
  outInteger := match (inClass)
    local
      list<Absyn.Annotation> ann;
      Integer count;
    case Absyn.CLASS(body = Absyn.PARTS(ann = ann))
      then listLength(ann);
    // check also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(ann = ann))
      then listLength(ann);
    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = _)) then 0;
  end match;
end getAnnotationCount;

protected function getNthAnnotationString
"Returns the Nth Annotation String from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output String outString;
algorithm
  outString := match (inClass,inInteger)
    local
      list<Absyn.Annotation> anns;
      Absyn.Annotation ann;
      String str;
      Integer n;
    case (Absyn.CLASS(body = Absyn.PARTS(ann = anns)),n)
      equation
        ann = listGet(anns,n);
        str = Dump.unparseAnnotation(ann);
        str = stringAppend(str, ";");
        str = System.trim(str, " ");
      then
        str;
    // check also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(ann = anns)),n)
      equation
        ann = listGet(anns,n);
        str = Dump.unparseAnnotation(ann);
        str = stringAppend(str, ";");
        str = System.trim(str, " ");
      then
        str;
  end match;
end getNthAnnotationString;

protected function getImportCount
"Counts the number of Import sections in a class."
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm
  outInteger := match (inClass)
    local
      list<Absyn.ClassPart> parts;
      Integer count;
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        count = getImportsInClassParts(parts);
      then
        count;
    // check also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        count = getImportsInClassParts(parts);
      then
        count;
    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = _)) then 0;
  end match;
end getImportCount;

protected function getImportsInClassParts
"Helper function to getImportCount"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ElementItem> els;
      list<Absyn.ClassPart> xs;
      Integer c1, c2, res;
    case (Absyn.PUBLIC(contents = els) :: xs)
      equation
        c1 = getImportsInElementItems(els);
        c2 = getImportsInClassParts(xs);
      then
        c1 + c2;
    case (Absyn.PROTECTED(contents = els) :: xs)
      equation
        c1 = getImportsInElementItems(els);
        c2 = getImportsInClassParts(xs);
      then
        c1 + c2;
    case ((_ :: xs))
      equation
        res = getImportsInClassParts(xs);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end getImportsInClassParts;

protected function getImportsInElementItems
"Helper function to getImportCount"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynElementItemLst)
    local
      Absyn.Import import_;
      list<Absyn.ElementItem> els;
      Integer c1, res;
    case (Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.IMPORT(import_ = import_))) :: els)
      equation
        c1 = getImportsInElementItems(els);
      then
        c1 + 1;
    case ((_ :: els))
      equation
        res = getImportsInElementItems(els);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end getImportsInElementItems;

protected function getNthImport
"Returns the Nth Import String from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output list<Values.Value> outValue;
algorithm
  outValue := match (inClass,inInteger)
    local
      list<Absyn.ClassPart> parts;
      list<Values.Value> vals;
      Integer n;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),n)
      equation
        vals = getNthImportInClassParts(parts,n);
      then
        vals;
    // check also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),n)
      equation
        vals = getNthImportInClassParts(parts,n);
      then
        vals;
  end match;
end getNthImport;

protected function getNthImportInClassParts
"Helper function to getNthImport"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Integer inInteger;
  output list<Values.Value> outValue;
algorithm
  outValue := matchcontinue (inAbsynClassPartLst,inInteger)
    local
      list<Values.Value> vals;
      list<Absyn.ElementItem> els;
      list<Absyn.ClassPart> xs;
      Integer n,c1,newn;
    case ((Absyn.PUBLIC(contents = els) :: xs),n)
      equation
        vals = getNthImportInElementItems(els, n);
      then
        vals;
    case ((Absyn.PUBLIC(contents = els) :: xs),n) /* The rule above failed, subtract the number of imports in the first section and try with the rest of the classparts */
      equation
        c1 = getImportsInElementItems(els);
        newn = n - c1;
        vals = getNthImportInClassParts(xs, newn);
      then
        vals;
    case ((Absyn.PROTECTED(contents = els) :: xs),n)
      equation
        vals = getNthImportInElementItems(els, n);
      then
        vals;
    case ((Absyn.PROTECTED(contents = els) :: xs),n) /* The rule above failed, subtract the number of imports in the first section and try with the rest of the classparts */
      equation
        c1 = getImportsInElementItems(els);
        newn = n - c1;
        vals = getNthImportInClassParts(xs, newn);
      then
        vals;
    case ((_ :: xs),n)
      equation
        vals = getNthImportInClassParts(xs, n);
      then
        vals;
  end matchcontinue;
end getNthImportInClassParts;

protected function getNthImportInElementItems
" This function takes an Element list and an int
   and returns the nth import as string.
   If the number is larger than the number of annotations
   in the list, the function fails. Helper function to getNthImport."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Integer inInteger;
  output list<Values.Value> outValue;
algorithm
  outValue := matchcontinue (inAbsynElementItemLst,inInteger)
    local
      list<Values.Value> vals;
      Absyn.Import import_;
      list<Absyn.ElementItem> els;
      Integer newn,n;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.IMPORT(import_ = import_))) :: els), 1)
      equation
        vals = unparseNthImport(import_);
      then
        vals;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.IMPORT(import_ = import_))) :: els), n)
      equation
        newn = n - 1;
        vals = getNthImportInElementItems(els, newn);
      then
        vals;
    case ((_ :: els),n)
      equation
        vals = getNthImportInElementItems(els, n);
      then
        vals;
    case ({},_) then fail();
  end matchcontinue;
end getNthImportInElementItems;

public function unparseNthImport
" helperfunction to getNthImport."
  input Absyn.Import inImport;
  output list<Values.Value> outValue;
algorithm
  outValue := match (inImport)
    local
      list<Values.Value> vals;
      list<Absyn.GroupImport> gi;
      String path_str,id;
      Absyn.Path path;
    case (Absyn.NAMED_IMPORT(name = id,path = path))
      equation
        path_str = Absyn.pathString(path);
        vals = {Values.STRING(path_str),Values.STRING(id),Values.STRING("named")};
      then
        vals;
    case (Absyn.QUAL_IMPORT(path = path))
      equation
        path_str = Absyn.pathString(path);
        vals = {Values.STRING(path_str),Values.STRING(""),Values.STRING("qualified")};
      then
        vals;
    case (Absyn.UNQUAL_IMPORT(path = path))
      equation
        path_str = Absyn.pathString(path);
        path_str = stringAppendList({path_str, ".*"});
        vals = {Values.STRING(path_str),Values.STRING(""),Values.STRING("unqualified")};
      then
        vals;
    case (Absyn.GROUP_IMPORT(prefix = path, groups = gi))
      equation
        path_str = Absyn.pathString(path);
        id = stringDelimitList(unparseGroupImport(gi),",");
        path_str = stringAppendList({path_str,".{",id,"}"});
        vals = {Values.STRING(path_str),Values.STRING(""),Values.STRING("multiple")};
      then
        vals;
  end match;
end unparseNthImport;

protected function unparseGroupImport
  input list<Absyn.GroupImport> inAbsynGroupImportLst;
  output list<String> outList;
algorithm
  outList := matchcontinue (inAbsynGroupImportLst)
  local
    list<Absyn.GroupImport> rest;
    list<String> lst;
    String str;
    case {} then {};
    case (Absyn.GROUP_IMPORT_NAME(name = str) :: rest)
      equation
        lst = unparseGroupImport(rest);
      then
        (str::lst);
    case ((_ :: rest))
      equation
        lst = unparseGroupImport(rest);
      then
        lst;
  end matchcontinue;
end unparseGroupImport;

public function evalCodeTypeName
  input Values.Value val;
  input Env.Env env;
  output Values.Value res;
algorithm
  res := matchcontinue (val,env)
    local
      Absyn.Path path;
    case (Values.CODE(Absyn.C_TYPENAME(path as Absyn.IDENT(_) /* We only want to lookup idents in the symboltable; also speeds up e.g. simulate(Modelica.A.B.C) so we do not instantiate all classes */)),_)
      equation
        (_,_,_,DAE.VALBOUND(valBound=res as Values.CODE(A=Absyn.C_TYPENAME(path=_))),_,_,_,_,_) = Lookup.lookupVar(Env.emptyCache(), env, ComponentReference.pathToCref(path));
      then res;
    else val;
  end matchcontinue;
end evalCodeTypeName;

public function isShortDefinition
"@auhtor:adrpo
  returns true if the class is derived or false otherwise"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inPath,inProgram)
    local
      Absyn.Path path;
      Absyn.Program p;
    case (path,p)
      equation
        Absyn.CLASS(body = Absyn.DERIVED(typeSpec = _)) = Interactive.getPathedClassInProgram(path, p);
      then
        true;
    case (_,_) then false;
  end matchcontinue;
end isShortDefinition;

protected function getPackageVersion
  input Absyn.Path path;
  input Absyn.Program p;
  output String version;
algorithm
  version := matchcontinue (path,p)
    case (_,_)
      equation
        Config.setEvaluateParametersInAnnotations(true);
        Absyn.STRING(version) = Interactive.getNamedAnnotation(path, p, Absyn.IDENT("version"), SOME(Absyn.STRING("")), Interactive.getAnnotationExp);
        Config.setEvaluateParametersInAnnotations(false);
      then version;
    else "";
  end matchcontinue;
end getPackageVersion;

protected function hasStopTime "For use with getNamedAnnotation"
  input Option<Absyn.Modification> mod;
  output Boolean b;
algorithm
  b := match (mod)
    local
      list<Absyn.ElementArg> arglst;
    case (SOME(Absyn.CLASSMOD(elementArgLst = arglst)))
      then List.exist(arglst,hasStopTime2);

  end match;
end hasStopTime;

protected function hasStopTime2 "For use with getNamedAnnotation"
  input Absyn.ElementArg arg;
  output Boolean b;
algorithm
  b := match (arg)
    local

    case Absyn.MODIFICATION(path=Absyn.IDENT(name="StopTime")) then true;
    else false;

  end match;
end hasStopTime2;

public function cevalCallFunctionEvaluateOrGenerate
"This function evaluates CALL expressions, i.e. function calls.
  They are currently evaluated by generating code for the function and
  then dynamicly load the function and call it."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input list<Values.Value> inValuesValueLst;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSymTab;
  input Absyn.Msg inMsg;
  input Boolean bIsCompleteFunction;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outSymTab;
algorithm
  (outCache,outValue,outSymTab) := matchcontinue (inCache,inEnv,inExp,inValuesValueLst,impl,inSymTab,inMsg,bIsCompleteFunction)
    local
      Values.Value newval;
      list<Env.Frame> env;
      DAE.Exp e;
      Absyn.Path funcpath;
      list<DAE.Exp> expl;
      Boolean  print_debug;
      list<Values.Value> vallst;
      Absyn.Msg msg;
      Env.Cache cache;
      list<GlobalScript.CompiledCFunction> cflist;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Program p;
      Integer libHandle, funcHandle;
      String fNew,fOld;
      Real buildTime, edit, build;
      Option<list<SCode.Element>> a;
      list<GlobalScript.InstantiatedClass> b;
      list<GlobalScript.Variable> c;
      list<GlobalScript.CompiledCFunction> cf;
      list<GlobalScript.LoadedFile> lf;
      Absyn.TimeStamp ts;
      String funcstr,f,fileName;
      list<GlobalScript.CompiledCFunction> newCF;
      String name;
      Boolean ppref, fpref, epref;
      Absyn.ClassDef    body;
      Absyn.Info        info;
      Absyn.Within      w;
      list<Absyn.Path> functionDependencies;
      SCode.Element sc;
      SCode.ClassDef cdef;
      String error_Str;
      DAE.Function func;
      SCode.Restriction res;
      GlobalScript.SymbolTable syt;
      Absyn.FunctionRestriction funcRest;
      DAE.Type ty;

    // try function interpretation
    case (cache,env, DAE.CALL(path = funcpath, attr = DAE.CALL_ATTR(ty = ty, builtin = false)), vallst, _, st, msg, _)
      equation
        true = Flags.isSet(Flags.EVAL_FUNC);
        failure(cevalIsExternalObjectConstructor(cache, funcpath, env, msg));
        // Debug.bcall1(Flags.isSet(Flags.DYN_LOAD), print,"[dynload]: try constant evaluation: " +& Absyn.pathString(funcpath) +& "\n");
        (cache,
         sc as SCode.CLASS(
          partialPrefix = SCode.NOT_PARTIAL(),
          restriction = res,
          classDef = cdef),
         env) = Lookup.lookupClass(cache, env, funcpath, false);
        isCevaluableFunction(sc);
        (cache, env, _) = InstFunction.implicitFunctionInstantiation(
          cache,
          env,
          InnerOuter.emptyInstHierarchy,
          DAE.NOMOD(),
          Prefix.NOPRE(),
          sc,
          {});
        func = Env.getCachedInstFunc(cache, funcpath);
        (cache, newval, st) = CevalFunction.evaluate(cache, env, func, vallst, st);
        // Debug.bcall1(Flags.isSet(Flags.DYN_LOAD), print, "[dynload]: constant evaluation SUCCESS: " +& Absyn.pathString(funcpath) +& "\n");
      then
        (cache, newval, st);

    // see if function is in CF list and the build time is less than the edit time
    case (cache,env,(e as DAE.CALL(path = funcpath, expLst = expl, attr = DAE.CALL_ATTR(builtin = false))),vallst,_,// (impl as true)
      (st as SOME(GlobalScript.SYMBOLTABLE(ast=p as Absyn.PROGRAM(globalBuildTimes=Absyn.TIMESTAMP(_,edit)),compiledFunctions=cflist))),msg, _)
      equation
        true = bIsCompleteFunction;
        true = Flags.isSet(Flags.GEN);
        failure(cevalIsExternalObjectConstructor(cache,funcpath,env,msg));
        Debug.fprintln(Flags.DYN_LOAD, "[dynload]: [func from file] check if is in CF list: " +& Absyn.pathString(funcpath) +& "\n");

        (true, funcHandle, buildTime, fOld) = Static.isFunctionInCflist(cflist, funcpath);
        Absyn.CLASS(_,_,_,_,Absyn.R_FUNCTION(funcRest),_,Absyn.INFO(fileName = fNew)) = Interactive.getPathedClassInProgram(funcpath, p);
        // see if the build time from the class is the same as the build time from the compiled functions list
        false = stringEq(fNew,""); // see if the WE have a file or not!
        false = Static.needToRebuild(fNew,fOld,buildTime); // we don't need to rebuild!

        Debug.bcall1(Flags.isSet(Flags.DYN_LOAD), print,"[dynload]: [func from file] About to execute function present in CF list: " +& Absyn.pathString(funcpath) +& "\n");

        print_debug = Flags.isSet(Flags.DYN_LOAD);
        newval = DynLoad.executeFunction(funcHandle, vallst, print_debug);
        //print("CALL: [func from file] CF LIST:\n\t" +& stringDelimitList(List.map(cflist, Interactive.dumpCompiledFunction), "\n\t") +& "\n");
      then
        (cache,newval,st);

    // see if function is in CF list and the build time is less than the edit time
    case (cache,env,(e as DAE.CALL(path = funcpath, expLst = expl, attr = DAE.CALL_ATTR(builtin = false))),vallst,_,// impl as true
      (st as SOME(GlobalScript.SYMBOLTABLE(ast=p as Absyn.PROGRAM(globalBuildTimes=Absyn.TIMESTAMP(_,edit)),compiledFunctions=cflist))), msg, _)
      equation
        true = bIsCompleteFunction;
        true = Flags.isSet(Flags.GEN);
        failure(cevalIsExternalObjectConstructor(cache,funcpath,env,msg));

        Debug.bcall1(Flags.isSet(Flags.DYN_LOAD), print,"[dynload]: [func from buffer] check if is in CF list: " +& Absyn.pathString(funcpath) +& "\n");

        (true, funcHandle, buildTime, fOld) = Static.isFunctionInCflist(cflist, funcpath);
        Absyn.CLASS(_,_,_,_,Absyn.R_FUNCTION(funcRest),_,Absyn.INFO(fileName = fNew, buildTimes= Absyn.TIMESTAMP(build,_))) = Interactive.getPathedClassInProgram(funcpath, p);
        // note, this should only work for classes that have no file name!
        true = stringEq(fNew,""); // see that we don't have a file!

        // see if the build time from the class is the same as the build time from the compiled functions list
        true = (buildTime >=. build);
        true = (buildTime >. edit);

        Debug.bcall1(Flags.isSet(Flags.DYN_LOAD), print,"[dynload]: [func from buffer] About to execute function present in CF list: " +& Absyn.pathString(funcpath) +& "\n");

        print_debug = Flags.isSet(Flags.DYN_LOAD);
        newval = DynLoad.executeFunction(funcHandle, vallst, print_debug);
      then
        (cache,newval,st);

    // not in CF list, we have a symbol table, generate function and update symtab
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl,attr = DAE.CALL_ATTR(builtin = false))),vallst,_,
          SOME(syt as GlobalScript.SYMBOLTABLE(p as Absyn.PROGRAM(globalBuildTimes=ts),a,b,c,cf,lf)), msg, _) // yeha! we have a symboltable!
      equation
        true = bIsCompleteFunction;
        true = Flags.isSet(Flags.GEN);
        failure(cevalIsExternalObjectConstructor(cache,funcpath,env,msg));

        Debug.bcall1(Flags.isSet(Flags.DYN_LOAD), print,"[dynload]: [SOME SYMTAB] not in in CF list: " +& Absyn.pathString(funcpath) +& "\n");

        // remove it and all its dependencies as it might be there with an older build time.
        // get dependencies!
        (_, functionDependencies, _) = getFunctionDependencies(cache, funcpath);
        //print("\nFunctions before:\n\t" +& stringDelimitList(List.map(cf, Interactive.dumpCompiledFunction), "\n\t") +& "\n");
        newCF = Interactive.removeCfAndDependencies(cf, funcpath::functionDependencies);
        //print("\nFunctions after remove:\n\t" +& stringDelimitList(List.map(newCF, Interactive.dumpCompiledFunction), "\n\t") +& "\n");

        Debug.bcall1(Flags.isSet(Flags.DYN_LOAD), print,"[dynload]: [SOME SYMTAB] not in in CF list: removed deps:" +&
          stringDelimitList(List.map(functionDependencies, Absyn.pathString) ,", ") +& "\n");
        //print("\nfunctions in SYMTAB: " +& Interactive.dumpCompiledFunctions(syt)

        // now is safe to generate code
        (cache, funcstr, fileName) = cevalGenerateFunction(cache, env, p, funcpath);
        print_debug = Flags.isSet(Flags.DYN_LOAD);
        libHandle = System.loadLibrary(fileName, print_debug);
        funcHandle = System.lookupFunction(libHandle, stringAppend("in_", funcstr));
        newval = DynLoad.executeFunction(funcHandle, vallst, print_debug);
        System.freeLibrary(libHandle, print_debug);
        buildTime = System.getCurrentTime();
        // update the build time in the class!
        Absyn.CLASS(name,ppref,fpref,epref,Absyn.R_FUNCTION(funcRest),body,info) = Interactive.getPathedClassInProgram(funcpath, p);

        info = Absyn.setBuildTimeInInfo(buildTime,info);
        ts = Absyn.setTimeStampBuild(ts, buildTime);
        w = Interactive.buildWithin(funcpath);

        Debug.bcall1(Flags.isSet(Flags.DYN_LOAD), print,"[dynload]: Updating build time for function path: " +& Absyn.pathString(funcpath) +& " within: " +& Dump.unparseWithin(w) +& "\n");

        p = Interactive.updateProgram(Absyn.PROGRAM({Absyn.CLASS(name,ppref,fpref,epref,Absyn.R_FUNCTION(funcRest),body,info)},w,ts), p);
        f = Absyn.getFileNameFromInfo(info);

        syt = GlobalScript.SYMBOLTABLE(
                p, a, b, c,
                GlobalScript.CFunction(funcpath,DAE.T_UNKNOWN({funcpath}),funcHandle,buildTime,f)::newCF,
                lf);

        Debug.bcall1(Flags.isSet(Flags.DYN_LOAD), print,"[dynload]: [SOME SYMTAB] not in in CF list [finished]: " +&
          Absyn.pathString(funcpath) +& "\n");
        //print("\nfunctions in SYMTAB: " +& Interactive.dumpCompiledFunctions(syt));
      then
        (cache,newval,SOME(syt));

    // no symtab, WE SHOULD NOT EVALUATE! but we do anyway with suppressed error messages!
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl,attr = DAE.CALL_ATTR(builtin = false))),vallst,_,NONE(), msg, _) // crap! we have no symboltable!
      equation
        true = bIsCompleteFunction;
        true = Flags.isSet(Flags.GEN);
        failure(cevalIsExternalObjectConstructor(cache,funcpath,env,msg));
        ErrorExt.setCheckpoint("cevalCallFunctionEvaluateOrGenerate_NO_SYMTAB");
        
        Debug.bcall1(Flags.isSet(Flags.DYN_LOAD), print,"[dynload]: [NO SYMTAB] not in in CF list: " +& Absyn.pathString(funcpath) +& "\n");

        // we might actually have a function loaded here already!
        // we need to unload all functions to not get conflicts!
        p = Env.getProgramFromCache(cache);
        (cache,funcstr,fileName) = cevalGenerateFunction(cache, env, p, funcpath);
        // generate a uniquely named dll!
        Debug.bcall1(Flags.isSet(Flags.DYN_LOAD), print,"[dynload]: cevalCallFunction: about to execute " +& funcstr +& "\n");
        print_debug = Flags.isSet(Flags.DYN_LOAD);
        libHandle = System.loadLibrary(fileName, print_debug);
        funcHandle = System.lookupFunction(libHandle, stringAppend("in_", funcstr));
        newval = DynLoad.executeFunction(funcHandle, vallst, print_debug);
        System.freeFunction(funcHandle, print_debug);
        System.freeLibrary(libHandle, print_debug);

        Debug.fprintln(Flags.DYN_LOAD, "CALL: [NO SYMTAB] not in in CF list [finished]: " +& Absyn.pathString(funcpath) +& "\n");
        ErrorExt.rollBack("cevalCallFunctionEvaluateOrGenerate_NO_SYMTAB");
      then
        (cache,newval,NONE());

    // cleanup the case below when we failed. we should delete generated files too
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl,attr = DAE.CALL_ATTR(builtin = false))),vallst,_,NONE(),msg, _) // crap! we have no symboltable!
      equation
        true = bIsCompleteFunction;
        true = Flags.isSet(Flags.GEN);
        failure(cevalIsExternalObjectConstructor(cache,funcpath,env,msg));
        ErrorExt.rollBack("cevalCallFunctionEvaluateOrGenerate_NO_SYMTAB");
      then
        fail();

    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl)),vallst,_,st, msg, _)
      equation
        Debug.bcall1(Flags.isSet(Flags.DYN_LOAD), print,"[dynload]: FAILED to constant evaluate function: " +& Absyn.pathString(funcpath) +& "\n");
        error_Str = Absyn.pathString(funcpath);
        //TODO: readd this when testsuite is okay.
        //Error.addMessage(Error.FAILED_TO_EVALUATE_FUNCTION, {error_Str});
        false = Flags.isSet(Flags.GEN);
        Debug.fprint(Flags.FAILTRACE, "- codegeneration is turned off. switch \"nogen\" flag off\n");
      then
        fail();

  end matchcontinue;
end cevalCallFunctionEvaluateOrGenerate;

protected function checkLibraryUsage
  input String inLibrary;
  input Absyn.Exp inExp;
  output Boolean isUsed;
algorithm
  isUsed := match(inLibrary, inExp)
    local
      String s;
      list<Absyn.Exp> exps;

    case (_, Absyn.STRING(s)) then stringEq(s, inLibrary);
    case (_, Absyn.ARRAY(exps))
      then List.isMemberOnTrue(inLibrary, exps, checkLibraryUsage);
  end match;
end checkLibraryUsage;


protected function isCevaluableFunction
  "Checks if an element is a function or external function that can be evaluated
  by CevalFunction."
  input SCode.Element inElement;
algorithm
  _ := match(inElement)
    local
      String fid;
      SCode.Mod mod;
      Absyn.Exp lib;

    //only some external functions.
    case (SCode.CLASS(restriction = SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(_)),
      classDef = SCode.PARTS(externalDecl = SOME(SCode.EXTERNALDECL(
        funcName = SOME(fid),
        annotation_ = SOME(SCode.ANNOTATION(mod)))))))
      equation
        SCode.MOD(binding = SOME((lib, _))) = Mod.getUnelabedSubMod(mod, "Library");
        true = checkLibraryUsage("Lapack", lib) or checkLibraryUsage("lapack", lib);
        isCevaluableFunction2(fid);
      then
        ();

    // All other functions can be evaluated.
    case (SCode.CLASS(restriction = SCode.R_FUNCTION(_))) then ();

  end match;
end isCevaluableFunction;

protected function isCevaluableFunction2
  "Checks if a function name belongs to a known external function that we can
  constant evaluate."
  input String inFuncName;
algorithm
  _ := match(inFuncName)
    local
      // Lapack functions.
      case "dgbsv" then ();
      case "dgeev" then ();
      case "dgegv" then ();
      case "dgels" then ();
      case "dgelsx" then ();
      case "dgeqpf" then ();
      case "dgesv" then ();
      case "dgesvd" then ();
      case "dgetrf" then ();
      case "dgetri" then ();
      case "dgetrs" then ();
      case "dgglse" then ();
      case "dgtsv" then ();
      case "dorgqr" then ();
  end match;
end isCevaluableFunction2;

public function cevalCallFunction "This function evaluates CALL expressions, i.e. function calls.
  They are currently evaluated by generating code for the function and
  then dynamicly load the function and call it."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input list<Values.Value> inValuesValueLst;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSymTab;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outSymTab;
algorithm
  (outCache,outValue,outSymTab) := matchcontinue (inCache,inEnv,inExp,inValuesValueLst,impl,inSymTab,inMsg,numIter)
    local
      Values.Value newval;
      list<Env.Frame> env;
      DAE.Exp e;
      Absyn.Path funcpath;
      list<DAE.Exp> expl;
      list<Values.Value> vallst, pubVallst, proVallst;
      Absyn.Msg msg;
      Env.Cache cache;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Path complexName;
      list<DAE.Var> pubVarLst, proVarLst, varLst;
      list<String> pubVarNames, proVarNames, varNames;
      DAE.Type ty;
      Absyn.Info info;
      String str;
      Boolean bIsCompleteFunction;

    // External functions that are "known" should be evaluated without compilation, e.g. all math functions
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl)),vallst,_,st,msg,_)
      equation
        (cache,newval) = Ceval.cevalKnownExternalFuncs(cache,env, funcpath, vallst, msg);
      then
        (cache,newval,st);

    // This case prevents the constructor call of external objects of being evaluated
    case (cache,env as _ :: _,(e as DAE.CALL(path = funcpath,expLst = expl)),vallst,_,st,msg,_)
      equation
        cevalIsExternalObjectConstructor(cache,funcpath,env,msg);
      then
        fail();

    // Record constructors
    case(cache,env,(e as DAE.CALL(path = funcpath,attr = DAE.CALL_ATTR(ty = DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(complexName), varLst=varLst)))),pubVallst,_,st,msg,_)
      equation
        Debug.fprintln(Flags.DYN_LOAD, "CALL: record constructor: func: " +& Absyn.pathString(funcpath) +& " type path: " +& Absyn.pathString(complexName));
        true = Absyn.pathEqual(funcpath,complexName);
        (pubVarLst,proVarLst) = List.splitOnTrue(varLst,Types.isPublicVar);
        expl = List.map1(proVarLst, Types.getBindingExp, funcpath);
        (cache,proVallst,st) = Ceval.cevalList(cache, env, expl, impl, st, msg, numIter);
        pubVarNames = List.map(pubVarLst,Expression.varName);
        proVarNames = List.map(proVarLst,Expression.varName);
        varNames = listAppend(pubVarNames, proVarNames);
        vallst = listAppend(pubVallst, proVallst);
        // Debug.fprintln(Flags.DYN_LOAD, "CALL: record constructor: [success] func: " +& Absyn.pathString(funcpath));
      then
        (cache,Values.RECORD(funcpath,vallst,varNames,-1),st);

    // evaluate or generate non-partial and non-replaceable functions
    case (cache,env, DAE.CALL(path = funcpath, attr = DAE.CALL_ATTR(ty = ty, builtin = false)), vallst, _, st, msg, _)
      equation
        failure(cevalIsExternalObjectConstructor(cache, funcpath, env, msg));
        Debug.fprintln(Flags.DYN_LOAD, "CALL: try to evaluate or generate function: " +& Absyn.pathString(funcpath));

        bIsCompleteFunction = isCompleteFunction(cache, env, funcpath);
        false = Types.hasMetaArray(ty);

        Debug.fprintln(Flags.DYN_LOAD, "CALL: is complete function: " +& Absyn.pathString(funcpath) +& " " +&  Util.if_(bIsCompleteFunction, "[true]", "[false]"));
        (cache, newval, st) = cevalCallFunctionEvaluateOrGenerate(inCache,inEnv,inExp,inValuesValueLst,impl,inSymTab,inMsg,bIsCompleteFunction);

        // Debug.fprintln(Flags.DYN_LOAD, "CALL: constant evaluation success: " +& Absyn.pathString(funcpath));
      then
        (cache, newval, st);

    // partial and replaceable functions should not be evaluated!
    case (cache,env, DAE.CALL(path = funcpath, attr = DAE.CALL_ATTR(ty = ty, builtin = false)), vallst, _, st, msg, _)
      equation
        failure(cevalIsExternalObjectConstructor(cache, funcpath, env, msg));
        false = isCompleteFunction(cache, env, funcpath);

        Debug.fprintln(Flags.DYN_LOAD, "CALL: constant evaluation failed (not complete function): " +& Absyn.pathString(funcpath));
      then
        fail();

    case (cache,env, DAE.CALL(path = funcpath, attr = DAE.CALL_ATTR(ty = ty, builtin = false)), vallst, _, st, msg as Absyn.MSG(info), _)
      equation
        failure(cevalIsExternalObjectConstructor(cache, funcpath, env, msg));
        true = isCompleteFunction(cache, env, funcpath);
        true = Types.hasMetaArray(ty);
        str = ExpressionDump.printExpStr(inExp);
        Error.addSourceMessage(Error.FUNCTION_RETURNS_META_ARRAY, {str}, info);
      then fail();

  end matchcontinue;
end cevalCallFunction;

public function isCompleteFunction
"a function is complete if is:
 - not partial
 - not replaceable (without redeclare)
 - replaceable and called functions are not partial or not replaceable (without redeclare)"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inFuncPath;
  output Boolean isComplete;
algorithm
 isComplete := matchcontinue(inCache, inEnv, inFuncPath)
   local
     Env.Cache cache;
     Env.Env env;
     Absyn.Path fpath;

   // external functions are complete :)
   case (cache, env, fpath)
     equation
       (_, SCode.CLASS(classDef = SCode.PARTS(externalDecl = SOME(_))), _) = Lookup.lookupClass(cache, env, fpath, false);
     then
       true;

   // if is partial instantiation no function evaluation/generation
   case (cache, env, fpath)
     equation
       true = System.getPartialInstantiation();
     then
       false;

   // partial functions are not complete!
   case (cache, env, fpath)
     equation
       (_, SCode.CLASS(partialPrefix = SCode.PARTIAL()), _) = Lookup.lookupClass(cache, env, fpath, false);
     then
       false;

   case (cache, env, fpath)
     then true;

  end matchcontinue;
end isCompleteFunction;

public function cevalIsExternalObjectConstructor
  input Env.Cache cache;
  input Absyn.Path funcpath;
  input Env.Env env;
  input Absyn.Msg msg;
protected
  Absyn.Path funcpath2;
  DAE.Type tp;
  Option<Absyn.Info> info;
algorithm
  _ := match(cache, funcpath, env, msg)
    case (_, _, {}, Absyn.NO_MSG()) then fail();
    case (_, _, _, Absyn.NO_MSG())
      equation
        (funcpath2, Absyn.IDENT("constructor")) = Absyn.splitQualAndIdentPath(funcpath);
        info = Util.if_(Util.isEqual(msg, Absyn.NO_MSG()), NONE(), SOME(Absyn.dummyInfo));
        (_, tp, _) = Lookup.lookupType(cache, env, funcpath2, info);
        Types.externalObjectConstructorType(tp);
      then
        ();
  end match;
end cevalIsExternalObjectConstructor;



public function ceval "
  This is a wrapper funtion to Ceval.ceval. The purpose of this
  function is to concetrate all the calls to Ceval.ceval made from
  the Script files. This will simplify the separation of the scripting
  environment from the FrontEnd"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input Boolean inBoolean "impl";
  input Option<GlobalScript.SymbolTable> inST;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outST;

  partial function ReductionOperator
    input Values.Value v1;
    input Values.Value v2;
    output Values.Value res;
  end ReductionOperator;
algorithm
  (outCache,outValue,outST):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inST,inMsg,numIter)
    local
      Option<GlobalScript.SymbolTable> stOpt;
      Boolean impl;
      list<Env.Frame> env;
      Absyn.Msg msg;
      list<Values.Value> vallst;
      list<DAE.Exp> expl;
      Values.Value newval,value;
      DAE.Exp e;
      Absyn.Path funcpath;
      Env.Cache cache;
      GlobalScript.SymbolTable st;

    // adrpo: TODO! this needs more work as if we don't have a symtab we run into unloading of dlls problem
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl)),impl,stOpt,msg,_)
      equation
        // do not handle Connection.isRoot here!
        false = stringEq("Connection.isRoot", Absyn.pathString(funcpath));
        // do not roll back errors generated by evaluating the arguments
        (cache,vallst,stOpt) = Ceval.cevalList(cache,env, expl, impl, stOpt, msg, numIter);

        (cache,newval,stOpt)= cevalCallFunction(cache, env, e, vallst, impl, stOpt, msg, numIter+1);
      then
        (cache,newval,stOpt);

    // Try Interactive functions last
    case (cache,env,(e as DAE.CALL(path = _)),(impl as true),SOME(st),msg,_)
      equation
        (cache,value,st) = cevalInteractiveFunctions(cache, env, e, st, msg, numIter+1);
      then
        (cache,value,SOME(st));
    case (cache,env,e,impl,stOpt,msg,_)
      equation
        (cache,value,stOpt) = Ceval.ceval(cache,env,e,impl,stOpt,msg,numIter+1);
      then
         (cache,value,stOpt);
  end matchcontinue;
end ceval;

protected function searchClassNames
  input list<Values.Value> inVals;
  input String inSearchText;
  input Boolean inFindInText;
  input Absyn.Program inProgram;
  output list<Values.Value> outVals;
algorithm
  outVals := matchcontinue (inVals, inSearchText, inFindInText, inProgram)
    local
      list<Values.Value> valsList;
      String str, str1;
      Boolean b;
      Absyn.Program p, p1;
      Absyn.Class absynClass;
      Integer position;
      list<Values.Value> xs;
      Values.Value val;
    case ((val as Values.CODE(_)) :: xs, str1, true, p)
      equation
        absynClass = Interactive.getPathedClassInProgram(ValuesUtil.getPath(val), p);
        p1 = Absyn.PROGRAM({absynClass},Absyn.TOP(),Absyn.TIMESTAMP(0.0,0.0));
        /* Don't consider packages for FindInText search */
        false = Interactive.isPackage(ValuesUtil.getPath(val), inProgram);
        str = Dump.unparseStr(p1, false);
        position = System.stringFind(System.tolower(str), System.tolower(str1));
        true = (position > -1);
        valsList = searchClassNames(xs, str1, true, p);
      then
        val::valsList;
    case ((val as Values.CODE(_)) :: xs, str1, b, p)
      equation
        str = ValuesUtil.valString(val);
        position = System.stringFind(System.tolower(str), System.tolower(str1));
        true = (position > -1);
        valsList = searchClassNames(xs, str1, b, p);
      then
        val::valsList;
    case ((_ :: xs), str1, b, p)
      equation
        valsList = searchClassNames(xs, str1, b, p);
      then
        valsList;
    case ({}, str1, b, p) then {};
  end matchcontinue;
end searchClassNames;

protected function makeUsesArray
  input tuple<Absyn.Path,list<String>> inTpl;
  output Values.Value v;
algorithm
  v := match inTpl
    local
      Absyn.Path p;
      String pstr,ver;
    case ((p,{ver}))
      equation
        pstr = Absyn.pathString(p);
      then ValuesUtil.makeArray({Values.STRING(pstr),Values.STRING(ver)});
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"makeUsesArray failed"});
      then fail();
  end match;
end makeUsesArray;

protected function getTypeNameIdent
  input Values.Value val;
  output String str;
algorithm
  Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT(str))) := val;
end getTypeNameIdent;

protected function buildDependencyGraph
  input String name;
  input SCode.Program sp;
  output list<String> edges;
algorithm
  edges := match (name,sp)
    local
      list<SCode.Element> elts;
    case (_,_)
      equation
        SCode.CLASS(classDef=SCode.PARTS(elementLst=elts)) = List.getMemberOnTrue(name, sp, SCode.isClassNamed);
        (_,_,_,elts,_) = SCode.partitionElements(elts);
      then List.map(elts, importDepenency);
  end match;
end buildDependencyGraph;

protected function buildDependencyGraphPublicImports
  input String name;
  input SCode.Program sp;
  output list<String> edges;
algorithm
  edges := match (name,sp)
    local
      list<SCode.Element> elts;
    case (_,_)
      equation
        SCode.CLASS(classDef=SCode.PARTS(elementLst=elts)) = List.getMemberOnTrue(name, sp, SCode.isClassNamed);
        elts = List.select(elts,SCode.elementIsPublicImport);
      then List.map(elts, importDepenency);
  end match;
end buildDependencyGraphPublicImports;

protected function buildTransitiveDependencyGraph
  input String name;
  input list<tuple<String,list<String>>> oldgraph;
  output list<String> edges;
algorithm
  edges := matchcontinue (name,oldgraph)
    local
      String str;
    case (_,_) then List.setDifference(Graph.allReachableNodes(({name},{}),oldgraph,stringEq),{name});
    else
      equation
        str = "CevalScript.buildTransitiveDependencyGraph failed: " +& name;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end buildTransitiveDependencyGraph;

protected function importDepenency
  input SCode.Element simp;
  output String name;
algorithm
  name := match simp
    local
      Absyn.Import imp;
      Absyn.Info info;
      String str;
      Absyn.Path path;
    case SCode.IMPORT(imp=Absyn.NAMED_IMPORT(path=path)) then Absyn.pathFirstIdent(path);
    case SCode.IMPORT(imp=Absyn.NAMED_IMPORT(path=path)) then Absyn.pathFirstIdent(path);
    case SCode.IMPORT(imp=Absyn.QUAL_IMPORT(path=path)) then Absyn.pathFirstIdent(path);
    case SCode.IMPORT(imp=Absyn.UNQUAL_IMPORT(path=path)) then Absyn.pathFirstIdent(path);
    case SCode.IMPORT(imp=Absyn.GROUP_IMPORT(prefix=path)) then Absyn.pathFirstIdent(path);
    case SCode.IMPORT(imp=imp,info=info)
      equation
        str = "CevalScript.importDepenency could not handle:" +& Dump.unparseImportStr(imp);
        Error.addSourceMessage(Error.INTERNAL_ERROR,{str},info);
      then fail();
  end match;
end importDepenency;

protected function compareNumberOfDependencies
  input tuple<String,list<String>> node1;
  input tuple<String,list<String>> node2;
  output Boolean cmp;
protected
  list<String> deps1,deps2;
algorithm
  (_,deps1) := node1;
  (_,deps2) := node2;
  cmp := listLength(deps1) >= listLength(deps2);
end compareNumberOfDependencies;

protected function compareDependencyNode
  input tuple<String,list<String>> node1;
  input tuple<String,list<String>> node2;
  output Boolean cmp;
protected
  String s1,s2;
algorithm
  (s1,_) := node1;
  (s2,_) := node2;
  cmp := Util.strcmpBool(s1,s2);
end compareDependencyNode;

protected function dependencyString
  input tuple<String,list<String>> deps;
  output String str;
protected
  list<String> strs;
algorithm
  (str,strs) := deps;
  str := str +& " (" +& intString(listLength(strs)) +& "): " +& stringDelimitList(strs, ",");
end dependencyString;

protected function transitiveDependencyString
  input tuple<String,list<String>> deps;
  output String str;
protected
  list<String> strs;
algorithm
  (str,strs) := deps;
  str := intString(listLength(strs)) +& ": ("+&str+&") " +& stringDelimitList(strs, ",");
end transitiveDependencyString;

protected function containsPublicInterface
  input SCode.Element elt;
  output Boolean b;
algorithm
  b := match elt
    local
      list<SCode.Element> elts;
      String name;
    case SCode.CLASS(restriction=SCode.R_PACKAGE(), encapsulatedPrefix=SCode.ENCAPSULATED(), classDef=SCode.PARTS(elementLst=elts))
      then List.exist(elts, containsPublicInterface2);
    else
      equation
        name = SCode.elementName(elt);
        name = "CevalScript.containsPublicInterface failed: " +& name;
        Error.addMessage(Error.INTERNAL_ERROR, {name});
      then fail();
  end match;
end containsPublicInterface;

protected function containsPublicInterface2
  "If the package contains a public type or constant, we depend on this package also through other modules"
  input SCode.Element elt;
  output Boolean b;
algorithm
  b := match elt
    local
      String name;
    case SCode.IMPORT(info=_) then false;
    case SCode.EXTENDS(info=_) then false;
    case SCode.CLASS(restriction=SCode.R_FUNCTION(_)) then false;
    case SCode.COMPONENT(name=name,prefixes=SCode.PREFIXES(visibility=SCode.PUBLIC()))
      equation
        // print("public component " +& name +& ": ");
      then true;
    case SCode.CLASS(name=name,prefixes=SCode.PREFIXES(visibility=SCode.PUBLIC()))
      equation
        // print("public class " +& name +& ": ");
      then true;
    else false;
  end match;
end containsPublicInterface2;

protected function containsImport
  input SCode.Element elt;
  input SCode.Visibility visibility;
  output Boolean b;
algorithm
  b := match (elt,visibility)
    local
      list<SCode.Element> elts;
      String name;
    case (SCode.CLASS(restriction=SCode.R_PACKAGE(), encapsulatedPrefix=SCode.ENCAPSULATED(), classDef=SCode.PARTS(elementLst=elts)),_)
      then List.exist1(elts, containsImport2, visibility);
    else
      equation
        name = SCode.elementName(elt);
        name = "CevalScript.containsPublicInterface failed: " +& name;
        Error.addMessage(Error.INTERNAL_ERROR, {name});
      then fail();
  end match;
end containsImport;

protected function containsImport2
  "If the package contains a public type or constant, we depend on this package also through other modules"
  input SCode.Element elt;
  input SCode.Visibility visibility;
  output Boolean b;
algorithm
  b := match (elt,visibility)
    local
      String name;
    case (SCode.IMPORT(visibility=SCode.PUBLIC(),info=_),SCode.PUBLIC()) then true;
    case (SCode.IMPORT(visibility=SCode.PROTECTED(),info=_),SCode.PROTECTED()) then true;
    else false;
  end match;
end containsImport2;

protected function printInterfaceString
  input SCode.Element elt;
protected
  String str;
algorithm
  SCode.CLASS(name=str) := elt;
  print(str +& ": " +& boolString(containsPublicInterface(elt)) +& "\n");
end printInterfaceString;

protected function getChangedClass
  input SCode.Element elt;
  input String suffix;
  output String name;
algorithm
  name := matchcontinue (elt,suffix)
    local
      String fileName;
    case (SCode.CLASS(name=name,info=Absyn.INFO(fileName=fileName)),_)
      equation
        false = System.regularFileExists(name +& suffix);
      then name;
    case (SCode.CLASS(name=name,info=Absyn.INFO(fileName=fileName)),_)
      equation
        true = System.fileIsNewerThan(fileName, name +& suffix);
      then name;
  end matchcontinue;
end getChangedClass;

protected function isChanged
  input tuple<String,list<String>> node;
  input HashSetString.HashSet hs;
  output Boolean b;
protected
  String str;
  list<String> strs;
algorithm
  (str,strs) := node;
  b := List.exist1(str::strs,BaseHashSet.has,hs);
  // print(str +& ": " +&  boolString(b) +& "\n");
end isChanged;

protected function loadFileThread
  input tuple<String,String> inFileEncoding;
  output Absyn.Program program;
algorithm
  program := matchcontinue inFileEncoding
    local
      String filename,encoding;
    case ((filename,encoding)) then ClassLoader.loadFile(filename,encoding);
    /* TODO: Add locking mechanism to write to parent's error stream instead of stdout */
    else equation print(Error.printMessagesStr(false)); then fail();
  end matchcontinue;
end loadFileThread;

protected function reloadClass
  input String filename;
  input String encoding;
  input GlobalScript.SymbolTable inST;
  output GlobalScript.SymbolTable outST;
protected
  Absyn.Program p,newp;
algorithm
  GlobalScript.SYMBOLTABLE(ast=p) := inST;
  newp := Parser.parse(filename,encoding); /* Don't use the classloader since that can pull in entire directory structures. We only want to reload one single file. */
  newp := Interactive.updateProgram(newp, p);
  outST := Interactive.setSymbolTableAST(inST, newp);
end reloadClass;

protected function writeModuleDepends
  input SCode.Element cl;
  input String prefix;
  input String suffix;
  input list<tuple<String,list<String>>> deps;
  output String str;
algorithm
  str := matchcontinue (cl,prefix,suffix,deps)
    local
      String name;
      list<String> allDepends,protectedDepends;
      list<SCode.Element> elts;
      Absyn.Info info;
    case (SCode.CLASS(name=name, classDef=SCode.PARTS(elementLst=elts)),_,_,_)
      equation
        protectedDepends = List.map(List.select(elts,SCode.elementIsProtectedImport),importDepenency);
        _::allDepends = Graph.allReachableNodes((name::protectedDepends,{}),deps,stringEq);
        allDepends = List.map1r(allDepends, stringAppend, prefix);
        allDepends = List.map1(allDepends, stringAppend, ".interface.mo");
        str = prefix +& name +& suffix +& ": " +& prefix +& name +& ".mo " +& stringDelimitList(allDepends," ");
      then str;
    case (SCode.CLASS(name=name,info=info),_,_,_)
      equation
        Error.addSourceMessage(Error.GENERATE_SEPARATE_CODE_DEPENDENCIES_FAILED, {name}, info);
      then fail();
  end matchcontinue;
end writeModuleDepends;

protected function findFunctionsToCompile
  input SCode.Element elt;
  input Absyn.Path pathPrefix;
  input list<Absyn.Path> acc;
  output list<Absyn.Path> paths;
algorithm
  paths := match (elt,pathPrefix,acc)
    local
      Absyn.Path p;
      String name;
      list<SCode.Element> elts;
    case (SCode.CLASS(name=name, partialPrefix=SCode.NOT_PARTIAL(), restriction=SCode.R_FUNCTION(_), classDef=SCode.PARTS(elementLst=elts)),_,_)
      equation
         p = Absyn.joinPaths(pathPrefix,Absyn.IDENT(name));
         paths = List.fold1(elts,findFunctionsToCompile,Absyn.joinPaths(pathPrefix,Absyn.IDENT(name)),acc);
      then p::paths;
    case (SCode.CLASS(name=name, partialPrefix=SCode.NOT_PARTIAL(), classDef=SCode.PARTS(elementLst=elts)),_,_)
      equation
         paths = List.fold1(elts,findFunctionsToCompile,Absyn.joinPaths(pathPrefix,Absyn.IDENT(name)),acc);
      then paths;
    else acc;
  end match;
end findFunctionsToCompile;

end CevalScript;
