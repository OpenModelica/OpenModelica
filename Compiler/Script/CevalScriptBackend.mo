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

encapsulated package CevalScriptBackend
"
  This module handles constant propagation of expressions for scripting
  functions. This module contains the parts not needed for the
  bootstrapping.
"

// public imports
import Absyn;
import BackendDAE;
import Ceval;
import DAE;
import FCore;
import Error;
import GlobalScript;
import Interactive;
import Values;
import SimCode;
import UnitAbsyn;

// protected imports
protected
import BackendDump;
import BackendDAECreate;
import BackendDAEUtil;
import BackendDAEOptimize;
import BackendEquation;
import BackendVariable;
import Builtin;
import CevalScript;
import CheckModel;
import ClassInf;
import ClockIndexes;
import Config;
import DAEQuery;
import DAEUtil;
import DAEDump;
import Debug;
import Dump;
import Expression;
import Figaro;
import FindZeroCrossings;
import Flags;
import FInst;
import FGraph;
import FGraphDump;
import GC;
import GlobalScriptUtil;
import Graph;
import HashSetString;
import Inst;
import InnerOuter;
import LexerModelicaDiff;
import DiffAlgorithm;
import List;
import Lookup;
import NFSCodeLookup;
import Prefix;
import Parser;
import Print;
import Refactor;
import SCodeDump;
import NFInst;
import NFSCodeEnv;
import NFSCodeFlatten;
import SimCodeMain;
import System;
import StaticScript;
import SCode;
import SCodeUtil;
import Settings;
import SimulationResults;
import SymbolicJacobian;
import TaskGraphResults;
import Tpl;
import CodegenFMU;
import Types;
import Util;
import ValuesUtil;
import XMLDump;
import ComponentReference;
import Uncertainties;
import OpenTURNS;
import FMI;
import FMIExt;
import ErrorExt;
import UnitAbsynBuilder;
import UnitParserExt;
import RewriteRules;
import BlockCallRewrite;

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
    "cflags",
    "simflags"
  } "names of simulation options";

public function getSimulationResultType
  output DAE.Type t;
algorithm
  t := if Config.getRunningTestsuite() then simulationResultType_rtest else simulationResultType_full;
end getSimulationResultType;

public function getDrModelicaSimulationResultType
  output DAE.Type t;
algorithm
  t := if Config.getRunningTestsuite() then simulationResultType_rtest else simulationResultType_drModelica;
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
  fields := if notest then List.map(resultValues, Util.tuple21) else {};
  vals := if notest then List.map(resultValues, Util.tuple22) else {};
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
  fields := if notest then List.map(resultValues, Util.tuple21) else {};
  vals := if notest then List.map(resultValues, Util.tuple22) else {};
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
  input FCore.Cache inCache;
  input FCore.Graph env;
  input String inputFilename;
  input GlobalScript.SymbolTable st;
  input Absyn.Msg msg;
  output FCore.Cache outCache;
  output String filename;
algorithm
  (outCache,filename) := match (inCache,env,inputFilename,st,msg)
    local FCore.Cache cache;
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
      DAE.SCONST(cflags),
      _)) equation
        options = "";

    then SimCode.SIMULATION_SETTINGS(startTime,stopTime,nIntervals,stepSize,tolerance,method,options,format,varFilter,cflags);
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
  outOptionValue := match(inSimOpt, optionName)
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
    case (GlobalScript.SIMULATION_OPTIONS(cflags = e),            "cflags")            then e;
    case (GlobalScript.SIMULATION_OPTIONS(simflags = e),          "simflags")          then e;
    case (_,                                         name)
      equation
        msg = "Unknown simulation option: " + name;
        Error.addCompilerWarning(msg);
      then
        fail();
  end match;
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
            GlobalScriptUtil.getSymbolTableAST(inSymTab),
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
        = Parser.parsestringexp("experiment(" + experimentAnnotationStr + ");\n", "<experiment>");

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
  DAE.Exp startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, options, outputFormat, variableFilter, cflags, simflags;
  Boolean UseOtimica;
algorithm
  UseOtimica := Config.acceptOptimicaGrammar() or Flags.getConfigBool(Flags.GENERATE_DYN_OPTIMIZATION_PROBLEM);
  GlobalScript.SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, _, options, outputFormat, variableFilter, cflags, simflags) := inSimOpt;
  method := if UseOtimica then DAE.SCONST("optimization") else method;
  numberOfIntervals := if UseOtimica then DAE.ICONST(50) else numberOfIntervals;
  outSimOpt := GlobalScript.SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, DAE.SCONST(inFileNamePrefix), options, outputFormat, variableFilter, cflags, simflags);
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
      Integer i;
      Real r;
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

    case (Absyn.INTEGER(i), DAE.T_INTEGER())  then DAE.ICONST(i);
    case (Absyn.REAL(str),    DAE.T_REAL()) equation r = System.stringReal(str); then DAE.RCONST(r);
    case (Absyn.INTEGER(i), DAE.T_REAL()) equation r = intReal(i); then DAE.RCONST(r);

    else
      equation
        str = "CevalScript.getConst: experiment annotation contains unsupported expression: " + Dump.printExpStr(inAbsynExp) + " of type " + Types.unparseType(inExpType) + "\n";
        Error.addCompilerError(str);
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
      DAE.Exp variableFilter, cflags, simflags;
      Real rStepSize, rStopTime, rStartTime;
      Integer iNumberOfIntervals;
      String name,msg;

    case (_, {}) then inSimOpt;

    case (GlobalScript.SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix,  options, outputFormat, variableFilter, cflags, simflags),
          Absyn.NAMEDARG(argName = "Tolerance", argValue = exp)::rest)
      equation
        tolerance = getConst(exp, DAE.T_REAL_DEFAULT);
        simOpt = populateSimulationOptions(
          GlobalScript.SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,options,outputFormat,variableFilter,cflags,simflags),
             rest);
      then
        simOpt;

    case (GlobalScript.SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, options, outputFormat, variableFilter, cflags, simflags),
          Absyn.NAMEDARG(argName = "StartTime", argValue = exp)::rest)
      equation
        startTime = getConst(exp, DAE.T_REAL_DEFAULT);
        simOpt = populateSimulationOptions(
          GlobalScript.SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,options,outputFormat,variableFilter,cflags,simflags),
             rest);
      then
        simOpt;

    case (GlobalScript.SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, options, outputFormat, variableFilter, cflags, simflags),
          Absyn.NAMEDARG(argName = "StopTime", argValue = exp)::rest)
      equation
        stopTime = getConst(exp, DAE.T_REAL_DEFAULT);
        simOpt = populateSimulationOptions(
          GlobalScript.SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,options,outputFormat,variableFilter,cflags,simflags),
             rest);
      then
        simOpt;

    case (GlobalScript.SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, options, outputFormat, variableFilter, cflags, simflags),
          Absyn.NAMEDARG(argName = "NumberOfIntervals", argValue = exp)::rest)
      equation
        numberOfIntervals = getConst(exp, DAE.T_INTEGER_DEFAULT);
        simOpt = populateSimulationOptions(
          GlobalScript.SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,options,outputFormat,variableFilter,cflags,simflags),
             rest);
      then
        simOpt;

    case (GlobalScript.SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, options, outputFormat, variableFilter, cflags, simflags),
          Absyn.NAMEDARG(argName = "Interval", argValue = exp)::rest)
      equation
        DAE.RCONST(rStepSize) = getConst(exp, DAE.T_REAL_DEFAULT);
        // a bit different for Interval, handle it LAST!!!!
        GlobalScript.SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                           fileNamePrefix,options,outputFormat,variableFilter,cflags,simflags) =
          populateSimulationOptions(inSimOpt, rest);

       DAE.RCONST(rStartTime) = startTime;
       DAE.RCONST(rStopTime) = stopTime;
       iNumberOfIntervals = realInt(realDiv(realSub(rStopTime, rStartTime), rStepSize));

       numberOfIntervals = DAE.ICONST(iNumberOfIntervals);
       stepSize = DAE.RCONST(rStepSize);

       simOpt = GlobalScript.SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                                   fileNamePrefix,options,outputFormat,variableFilter,cflags,simflags);
      then
        simOpt;

    case (_,Absyn.NAMEDARG(argName = name, argValue = exp)::rest)
      equation
        msg = "Ignoring unknown experiment annotation option: " + name + " = " + Dump.printExpStr(exp);
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

public function cevalInteractiveFunctions3
"defined in the interactive environment."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String inFunctionName;
  input list<Values.Value> inVals;
  input GlobalScript.SymbolTable inSt;
  input Absyn.Msg msg;
  output FCore.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
protected
  import LexerModelicaDiff.{Token,TokenId,tokenContent,scanString,filterModelicaDiff,modelicaDiffTokenEq,modelicaDiffTokenWhitespace};
  import DiffAlgorithm.{Diff,diff,printActual,printDiffTerminalColor,printDiffXml};
algorithm
  (outCache,outValue,outInteractiveSymbolTable) := matchcontinue (inCache,inEnv,inFunctionName,inVals,inSt,msg)
    local
      String omdev,simflags,s1,s2,s3,str,str1,str2,str3,token,varid,cmd,executable,executable1,encoding,method_str,
             outputFormat_str,initfilename,pd,executableSuffixedExe,sim_call,result_file,filename_1,filename,
             call,str_1,mp,pathstr,name,cname,errMsg,errorStr,
             title,xLabel,yLabel,filename2,varNameStr,xml_filename,xml_contents,visvar_str,pwd,omhome,omlib,omcpath,os,
             platform,usercflags,senddata,res,workdir,gcc,confcmd,touch_file,uname,filenameprefix,compileDir,libDir,exeDir,configDir,from,to,
             gridStr, logXStr, logYStr, x1Str, x2Str, y1Str, y2Str, curveWidthStr, curveStyleStr, legendPosition, footer, autoScaleStr,scriptFile,logFile, simflags2, outputFile,
             systemPath, gccVersion, gd, strlinearizeTime, direction, suffix;
      list<DAE.Exp> simOptions;
      list<Values.Value> vals;
      Absyn.Path path,classpath,className,baseClassPath;
      SCode.Program scodeP,sp;
      Option<list<SCode.Element>> fp;
      FCore.Graph env;
      GlobalScript.SymbolTable newst,st_1,st;
      Absyn.Program p,ip,pnew,newp,ptot;
      list<Absyn.Program> newps;
      list<GlobalScript.InstantiatedClass> ic,ic_1;
      list<GlobalScript.Variable> iv;
      list<GlobalScript.CompiledCFunction> cf;
      GlobalScript.SimulationOptions simOpt;
      Real startTime,stopTime,tolerance,reltol,reltolDiffMinMax,rangeDelta;
      DAE.Exp startTimeExp,stopTimeExp,toleranceExp,intervalExp;
      DAE.Type tp, ty;
      list<DAE.Type> tys;
      Absyn.Class absynClass;
      Absyn.ClassDef cdef;
      Absyn.Exp aexp;
      DAE.DAElist dae;
      BackendDAE.BackendDAE daelow,optdae;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqnarr;
      array<list<Integer>> m,mt;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      Values.Value ret_val,simValue,value,v,cvar,cvar2,v1,v2,v3;
      Absyn.ComponentRef cr,cr_1;
      Integer size,resI,i,i1,i2,i3,n,curveStyle,numberOfIntervals, status;
      Option<Integer> fmiContext, fmiInstance, fmiModelVariablesInstance; /* void* implementation: DO NOT UNBOX THE POINTER AS THAT MIGHT CHANGE IT. Just treat this as an opaque type. */
      Integer fmiLogLevel;
      list<Integer> is;
      list<FMI.TypeDefinitions> fmiTypeDefinitionsList;
      list<FMI.ModelVariables> fmiModelVariablesList;
      FMI.ExperimentAnnotation fmiExperimentAnnotation;
      FMI.Info fmiInfo;
      list<String> vars_1,args,strings,strs,strs1,strs2,visvars,postOptModStrings,postOptModStringsOrg,mps,files,dirs;
      Real timeTotal,timeSimulation,timeStamp,val,x1,x2,y1,y2,r,r1,r2,linearizeTime,curveWidth,offset,offset1,offset2,scaleFactor,scaleFactor1,scaleFactor2;
      GlobalScript.Statements istmts;
      list<GlobalScript.Statements> istmtss;
      Boolean have_corba, bval, anyCode, b, b1, b2, externalWindow, logX, logY, autoScale, forceOMPlot, gcc_res, omcfound, rm_res, touch_res, uname_res,  ifcpp, ifmsvc,sort, builtin, showProtected, inputConnectors, outputConnectors;
      FCore.Cache cache;
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
      GlobalScript.SimulationOptions defaulSimOpt;
      SimCode.SimulationSettings simSettings;
      Boolean dumpExtractionSteps, requireExactVersion;
      list<tuple<Absyn.Path,list<String>>> uses;
      Config.LanguageStandard oldLanguageStd;
      SCode.Element cl;
      list<SCode.Element> cls, elts;
      list<String> names, namesPublic, namesProtected, namesChanged, fileNames;
      HashSetString.HashSet hashSetString;
      list<Boolean> blst;
      list<Error.TotalMessage> messages;
      UnitAbsyn.Unit u1,u2;
      Real stoptime,starttime,tol,stepsize,interval;
      String stoptime_str,stepsize_str,starttime_str,tol_str,num_intervalls_str,description,prefix;
      list<String> interfaceType;
      list<tuple<String,list<String>>> interfaceTypeAssoc;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;
      list<list<Values.Value>> valsLst;
      list<Token> tokens1, tokens2;
      list<tuple<Diff, list<Token>>> diffs;

    case (cache,_,"setClassComment",{Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str)},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        (p,b) = Interactive.setClassComment(path, str, p);
        st = GlobalScriptUtil.setSymbolTableAST(st, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache, _, "isShortDefinition", {Values.CODE(Absyn.C_TYPENAME(path))}, st as GlobalScript.SYMBOLTABLE(ast = p), _)
      equation
        b = isShortDefinition(path, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"getUsedClassNames",{Values.CODE(Absyn.C_TYPENAME(path))},st as GlobalScript.SYMBOLTABLE(),_)
      equation
        (sp, st) = GlobalScriptUtil.symbolTableToSCode(st);
        (sp, _) = NFSCodeFlatten.flattenClassInProgram(path, sp);
        sp = SCode.removeBuiltinsFromTopScope(sp);
        paths = Interactive.getSCodeClassNamesRecursive(sp);
        // paths = bcallret2(sort, List.sort, paths, Absyn.pathGe, paths);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then (cache,ValuesUtil.makeArray(vals),st);

    case (cache,_,"getUsedClassNames",_,st as GlobalScript.SYMBOLTABLE(),_)
      then (cache,ValuesUtil.makeArray({}),st);

    case (cache,_,"getClassComment",{Values.CODE(Absyn.C_TYPENAME(path))},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        Absyn.CLASS(_,_,_,_,_,cdef,_) = Interactive.getPathedClassInProgram(path, p);
        str = System.unescapedString(getClassComment(cdef));
      then
        (cache,Values.STRING(str),st);

    case (cache,_,"getClassComment",{Values.CODE(Absyn.C_TYPENAME(_))},st as GlobalScript.SYMBOLTABLE(),_)
      then
        (cache,Values.STRING(""),st);

    case (cache,_,"getPackages",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("AllLoadedClasses")))},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        paths = Interactive.getTopPackages(p);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,_,"getPackages",{Values.CODE(Absyn.C_TYPENAME(path))},st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        paths = Interactive.getPackagesInPath(path, p);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,_,"convertUnits",{Values.STRING(str1),Values.STRING(str2)},st,_)
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

    case (cache,_,"getClassInformation",{Values.CODE(Absyn.C_TYPENAME(className))},st as GlobalScript.SYMBOLTABLE(),_)
      equation
        v = getClassInformation(className, st.ast);
      then (cache,v,st);

    case (cache,_,"getClassInformation",_,st,_)
      then (cache,Values.TUPLE({Values.STRING(""),Values.STRING(""),Values.BOOL(false),Values.BOOL(false),Values.BOOL(false),Values.STRING(""),
                                Values.BOOL(false),Values.INTEGER(0),Values.INTEGER(0),Values.INTEGER(0),Values.INTEGER(0),Values.ARRAY({},{0}),
                                Values.BOOL(false),Values.BOOL(false)}),st);

    case (cache,_,"diffModelicaFileListings",{Values.STRING(s1),Values.STRING(s2),Values.ENUM_LITERAL(name=path)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      algorithm
        tokens1 := scanString(s1);
        tokens2 := scanString(s2);
        diffs := diff(tokens1, tokens2, modelicaDiffTokenEq, modelicaDiffTokenWhitespace, tokenContent);
        // print("Before filtering:\n"+printDiffTerminalColor(diffs, tokenContent)+"\n");
        diffs := filterModelicaDiff(diffs,removeWhitespace=false);
        // Scan a second time, with comments filtered into place
        str := printActual(diffs, tokenContent);
        // print("Intermediate string:\n"+printDiffTerminalColor(diffs, tokenContent)+"\n");
        tokens2 := scanString(str);
        diffs := diff(tokens1, tokens2, modelicaDiffTokenEq, modelicaDiffTokenWhitespace, tokenContent);
        // print("Before filtering (2):\n"+printDiffTerminalColor(diffs, tokenContent)+"\n");
        diffs := filterModelicaDiff(diffs);
        str := match Absyn.pathLastIdent(path)
          case "plain" then printActual(diffs, tokenContent);
          case "color" then printDiffTerminalColor(diffs, tokenContent);
          case "xml" then printDiffXml(diffs, tokenContent);
          else
            algorithm
              Error.addInternalError("Unknown diffModelicaFileListings choice", sourceInfo());
            then fail();
        end match;
      then (cache,Values.STRING(str),st);

    case (cache,_,"diffModelicaFileListings",_,st,_) then (cache,Values.STRING(""),st);

  // exportToFigaro cases added by Alexander Carlqvist
    case (cache, _, "exportToFigaro", {Values.CODE(Absyn.C_TYPENAME(path)), Values.STRING(s1), Values.STRING(str), Values.STRING(str1), Values.STRING(str2), Values.STRING(str3)}, st as GlobalScript.SYMBOLTABLE(ast = p), _)
      equation
    (scodeP, _) = GlobalScriptUtil.symbolTableToSCode(st);
    /* The following line of code should be commented out when building from trunk.
    Uncomment when bootstrapping. */
    Figaro.run(scodeP, path, s1, str, str1, str2, str3);
      then (cache, Values.BOOL(true), st);

    case (cache, _, "exportToFigaro", _, st, _)
      then (cache, Values.BOOL(false), st);

    case (_,_, "rewriteBlockCall",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_TYPENAME(path))},
       (st as GlobalScript.SYMBOLTABLE(p as Absyn.PROGRAM())),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        classes = {absynClass};
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        within_ = Interactive.buildWithin(classpath);
        pnew = BlockCallRewrite.rewriteBlockCall(Absyn.PROGRAM({absynClass}, within_), Absyn.PROGRAM(classes, within_));
        pnew = Interactive.updateProgram(pnew, p);
        newst = GlobalScriptUtil.setSymbolTableAST(st, pnew);
      then
        (FCore.emptyCache(),Values.BOOL(true), newst);

    case (cache, _, "rewriteBlockCall", _, st, _)
      then (cache, Values.BOOL(false), st);

    case (cache,env,"jacobian",{Values.CODE(Absyn.C_TYPENAME(path))},
          (GlobalScript.SYMBOLTABLE(
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
        (BackendDAE.DAE({syst},shared)) = BackendDAEUtil.preOptimizeBackendDAE(daelow,NONE());
        (syst,m,_) = BackendDAEUtil.getIncidenceMatrixfromOption(syst,BackendDAE.NORMAL(),NONE());
        vars = BackendVariable.daeVars(syst);
        eqnarr = BackendEquation.getEqnsFromEqSystem(syst);
        (jac, _) = SymbolicJacobian.calculateJacobian(vars, eqnarr, m, false,shared);
        res = BackendDump.dumpJacobianStr(jac);
      then
        (cache,Values.STRING(res),GlobalScript.SYMBOLTABLE(p,fp,ic_1,iv,cf,lf));

    case (cache,env,"translateModel",vals as {Values.CODE(Absyn.C_TYPENAME(className)),_,_,_,_,_,Values.STRING(filenameprefix),_,_,_,_,_},st,_)
      equation
        (cache,simSettings) = calculateSimulationSettings(cache,env,vals,st,msg);
        (cache,st_1,_,_,_,_) = translateModel(cache, env, className, st, filenameprefix, true, SOME(simSettings));
      then
        (cache,Values.BOOL(true),st_1);

    case (cache,_,"translateModel",_,st,_)
      then (cache,Values.BOOL(false),st);

    case (cache,env,"modelEquationsUC",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(outputFile),Values.BOOL(dumpExtractionSteps)},st,_)
      equation
        (cache,ret_val,st_1) = Uncertainties.modelEquationsUC(cache, env, className, st, outputFile,dumpExtractionSteps);
      then
        (cache,ret_val,st_1);

    case (cache,_,"modelEquationsUC",_,st,_)
      then (cache,Values.STRING("There were errors during extraction of uncertainty equations. Use getErrorString() to see them."),st);

    /*case (cache,env,"translateModelCPP",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)},st,msg)
      equation
        (cache,ret_val,st_1,_,_,_,_) = translateModelCPP(cache,env, className, st, filenameprefix,true,NONE());
      then
        (cache,ret_val,st_1);*/

    case (cache,env,"translateModelFMU", {Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(str1),Values.STRING(str2),Values.STRING(filenameprefix)},st,_)
      algorithm
        (cache,ret_val,st_1) := buildModelFMU(cache, env, className, st, str1, str2, filenameprefix, true);
      then (cache,ret_val,st_1);

    case (cache,env,"buildModelFMU", {Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(str1),Values.STRING(str2),Values.STRING(filenameprefix),Values.ARRAY(valueLst=cvars)},st,_)
      algorithm
        (cache,ret_val,st_1) := buildModelFMU(cache, env, className, st, str1, str2, filenameprefix, true, list(ValuesUtil.extractValueString(vv) for vv in cvars));
      then (cache,ret_val,st_1);

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

    case (cache,_,"setPlotCommand",{Values.STRING(_)},st,_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,_,"getAnnotationVersion",{},st,_)
      equation
        res = Config.getAnnotationVersion();
      then
        (cache,Values.STRING(res),st);

    case (cache,_,"getNoSimplify",{},st,_)
      equation
        b = Config.getNoSimplify();
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"setNoSimplify",{Values.BOOL(b)},st,_)
      equation
        Config.setNoSimplify(b);
      then
        (cache,Values.BOOL(true),st);

    case (cache,_,"getShowAnnotations",{},st,_)
      equation
        b = Config.showAnnotations();
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"setShowAnnotations",{Values.BOOL(b)},st,_)
      equation
        Config.setShowAnnotations(b);
      then
        (cache,Values.BOOL(true),st);

    case (cache,_,"getVectorizationLimit",{},st,_)
      equation
        i = Config.vectorizationLimit();
      then
        (cache,Values.INTEGER(i),st);

    case (cache,_,"getOrderConnections",{},st,_)
      equation
        b = Config.orderConnections();
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"buildModel",vals,st,_)
      equation
        List.map_0(ClockIndexes.buildModelClocks,System.realtimeClear);
        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
        (cache,st,compileDir,executable,_,_,initfilename,_,_) = buildModel(cache,env, vals, st, msg);
        executable = if not Config.getRunningTestsuite() then compileDir + executable else executable;
      then
        (cache,ValuesUtil.makeArray({Values.STRING(executable),Values.STRING(initfilename)}),st);

    case(cache,env,"buildOpenTURNSInterface",vals,st,_)
      equation
        (cache,scriptFile,st) = buildOpenTURNSInterface(cache,env,vals,st,msg);
      then
        (cache,Values.STRING(scriptFile),st);
    case(_,_,"buildOpenTURNSInterface",_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"buildOpenTURNSInterface failed. Use getErrorString() to see why."});
      then
        fail();

    case(cache,env,"runOpenTURNSPythonScript",vals,st,_)
      equation
        (cache,logFile,st) = runOpenTURNSPythonScript(cache,env,vals,st,msg);
      then
        (cache,Values.STRING(logFile),st);
    case(_,_,"runOpenTURNSPythonScript",_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"runOpenTURNSPythonScript failed. Use getErrorString() to see why"});
      then
        fail();

    case (cache,_,"buildModel",_,st,_) /* failing build_model */
      then (cache,ValuesUtil.makeArray({Values.STRING(""),Values.STRING("")}),st);

    case (cache,env,"buildModelBeast",vals,st,_)
      equation
        (cache,st,compileDir,executable,_,initfilename) = buildModelBeast(cache,env,vals,st,msg);
        executable = if not Config.getRunningTestsuite() then compileDir + executable else executable;
      then
        (cache,ValuesUtil.makeArray({Values.STRING(executable),Values.STRING(initfilename)}),st);

    // adrpo: see if the model exists before simulation!
    case (cache,_,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        crefCName = Absyn.pathToCref(className);
        false = Interactive.existClass(crefCName, p);
        errMsg = "Simulation Failed. Model: " + Absyn.pathString(className) + " does not exist! Please load it first before simulation.";
        simValue = createSimulationResultFailure(errMsg, simOptionsAsString(vals));
      then
        (cache,simValue,st);

    case (cache,env,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,st_1,_)
      equation
        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
        (cache,st,compileDir,executable,_,outputFormat_str,_,simflags,resultValues) = buildModel(cache,env,vals,st_1,msg);

        exeDir=compileDir;
         (cache,simSettings) = calculateSimulationSettings(cache,env,vals,st_1,msg);
        SimCode.SIMULATION_SETTINGS(outputFormat = outputFormat_str)
           = simSettings;
        result_file = stringAppendList(List.consOnTrue(not Config.getRunningTestsuite(),compileDir,{executable,"_res.",outputFormat_str}));
        executableSuffixedExe = stringAppend(executable, getSimulationExtension(Config.simCodeTarget(),System.platform()));
        logFile = stringAppend(executable,".log");
        // adrpo: log file is deleted by buildModel! do NOT DELETE IT AGAIN!
        // we should really have different log files for simulation/compilation!
        // as the buildModel log file will be deleted here and that gives less information to the user!
        if System.regularFileExists(logFile) then
          0 = System.removeFile(logFile);
        end if;
        sim_call = stringAppendList({"\"",exeDir,executableSuffixedExe,"\""," ",simflags});
        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_SIMULATION);
        SimulationResults.close() "Windows cannot handle reading and writing to the same file from different processes like any real OS :(";
        resI = System.systemCall(sim_call,logFile);
        timeSimulation = System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_SIMULATION);
        timeTotal = System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
        (cache,simValue,newst) = createSimulationResultFromcallModelExecutable(resI,timeTotal,timeSimulation,resultValues,cache,className,vals,st,result_file,logFile);
      then
        (cache,simValue,newst);

    case (cache,_,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,st,_)
      equation
        _ = Settings.getInstallationDirectoryPath() "simulation fail for some other reason than OPENMODELICAHOME not being set." ;
        str = Absyn.pathString(className);
        res = "Failed to build model: " + str;
        simValue = createSimulationResultFailure(res, simOptionsAsString(vals));
      then
        (cache,simValue,st);

    case (cache,_,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,st,_)
      equation
        str = Absyn.pathString(className);
        simValue = createSimulationResultFailure(
          "Simulation failed for model: " + str +
          "\nEnvironment variable OPENMODELICAHOME not set.",
          simOptionsAsString(vals));
      then
        (cache,simValue,st);

    // adrpo: see if the model exists before moving!
    case (cache,_,"moveClass",{Values.CODE(Absyn.C_TYPENAME(className)),
                                         Values.STRING(_)},
          st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        crefCName = Absyn.pathToCref(className);
        false = Interactive.existClass(crefCName, p);
        simValue = Values.BOOL(false);
      then
        (cache,simValue,st);

    // everything should work fine here
    case (cache,_,"moveClass",{Values.CODE(Absyn.C_TYPENAME(className)),
                                        Values.STRING(direction)},
          st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        crefCName = Absyn.pathToCref(className);
        true = Interactive.existClass(crefCName, p);
        p = moveClass(className, direction, p);
        st = GlobalScriptUtil.setSymbolTableAST(st, p);
        simValue = Values.BOOL(true);
      then
        (cache,simValue,st);

    // adrpo: some error happened!
    case (cache,_,"moveClass",{Values.CODE(Absyn.C_TYPENAME(className)),
                                        Values.STRING(_)},
          st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        crefCName = Absyn.pathToCref(className);
        true = Interactive.existClass(crefCName, p);
        errMsg = "moveClass Error: Could not move the model " + Absyn.pathString(className) + ". Unknown error.";
        Error.addMessage(Error.INTERNAL_ERROR, {errMsg});
        simValue = Values.BOOL(false);
      then
        (cache,simValue,st);

    case (cache,_,"copyClass",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(name), Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("TopLevel")))},
          st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        p = copyClass(absynClass, name, Absyn.TOP(), p);
        st = GlobalScriptUtil.setSymbolTableAST(st, p);
        ret_val = Values.BOOL(true);
      then
        (cache,ret_val,st);

    case (cache,_,"copyClass",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(name), Values.CODE(Absyn.C_TYPENAME(path))},
          st as GlobalScript.SYMBOLTABLE(ast = p),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        p = copyClass(absynClass, name, Absyn.WITHIN(path), p);
        st = GlobalScriptUtil.setSymbolTableAST(st, p);
        ret_val = Values.BOOL(true);
      then
        (cache,ret_val,st);

    case (cache,env,"linearize",(vals as Values.CODE(Absyn.C_TYPENAME(_))::_),st_1,_)
      equation

        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);

        b = Flags.getConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION);
        Flags.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION, true);

        (cache,st,compileDir,executable,_,outputFormat_str,_,simflags,resultValues) = buildModel(cache,env,vals,st_1,msg);
        Values.REAL(linearizeTime) = getListNthShowError(vals,"try to get stop time",0,2);
        executableSuffixedExe = stringAppend(executable, System.getExeExt());
        logFile = stringAppend(executable,".log");
        if System.regularFileExists(logFile) then
          0 = System.removeFile(logFile);
        end if;
        strlinearizeTime = realString(linearizeTime);
        sim_call = stringAppendList({"\"",compileDir,executableSuffixedExe,"\""," ","-l=",strlinearizeTime," ",simflags});
        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_SIMULATION);
        SimulationResults.close() "Windows cannot handle reading and writing to the same file from different processes like any real OS :(";
        0 = System.systemCall(sim_call,logFile);

        result_file = stringAppendList(List.consOnTrue(not Config.getRunningTestsuite(),compileDir,{executable,"_res.",outputFormat_str}));
        timeSimulation = System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_SIMULATION);
        timeTotal = System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
        simValue = createSimulationResult(
           result_file,
           simOptionsAsString(vals),
           System.readFile(logFile),
           ("timeTotal", Values.REAL(timeTotal)) ::
           ("timeSimulation", Values.REAL(timeSimulation)) ::
          resultValues);
        newst = GlobalScriptUtil.addVarToSymboltable(
          DAE.CREF_IDENT("currentSimulationResult", DAE.T_STRING_DEFAULT, {}),
          Values.STRING(result_file), FGraph.empty(), st);
        //reset config flag
        Flags.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION, b);
      then
        (cache,simValue,newst);

   case (cache,env,"optimize",(vals as Values.CODE(Absyn.C_TYPENAME(className))::_),st_1,_)
      equation

        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);

        Flags.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION,true);
        Flags.setConfigEnum(Flags.GRAMMAR, Flags.OPTIMICA);
        Flags.setConfigBool(Flags.GENERATE_DYN_OPTIMIZATION_PROBLEM,true);

        (cache,st,compileDir,executable,_,outputFormat_str,_,simflags,resultValues) = buildModel(cache,env,vals,st_1,msg);
        exeDir=compileDir;
        (cache,simSettings) = calculateSimulationSettings(cache,env,vals,st_1,msg);
        SimCode.SIMULATION_SETTINGS(outputFormat = outputFormat_str) = simSettings;
        result_file = stringAppendList(List.consOnTrue(not Config.getRunningTestsuite(),compileDir,{executable,"_res.",outputFormat_str}));
        executableSuffixedExe = stringAppend(executable, getSimulationExtension(Config.simCodeTarget(),System.platform()));
        logFile = stringAppend(executable,".log");
        // adrpo: log file is deleted by buildModel! do NOT DELTE IT AGAIN!
        // we should really have different log files for simulation/compilation!
        // as the buildModel log file will be deleted here and that gives less information to the user!
        if System.regularFileExists(logFile) then
          0 = System.removeFile(logFile);
        end if;
        sim_call = stringAppendList({"\"",exeDir,executableSuffixedExe,"\""," ",simflags});
        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_SIMULATION);
        SimulationResults.close() "Windows cannot handle reading and writing to the same file from different processes like any real OS :(";
        resI = System.systemCall(sim_call,logFile);
        timeSimulation = System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_SIMULATION);
        timeTotal = System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
        (cache,simValue,newst) = createSimulationResultFromcallModelExecutable(resI,timeTotal,timeSimulation,resultValues,cache,className,vals,st,result_file,logFile);
      then
        (cache,simValue,newst);

    case (cache,env,"instantiateModel",{Values.CODE(Absyn.C_TYPENAME(className))},st,_)
      equation
        (cache,env,dae,st) = runFrontEnd(cache,env,className,st,true);
        str = DAEDump.dumpStr(dae,FCore.getFunctionTree(cache));
      then
        (cache,Values.STRING(str),st);

    case (cache,_,"instantiateModel",{Values.CODE(Absyn.C_TYPENAME(path))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        cr_1 = Absyn.pathToCref(path);
        false = Interactive.existClass(cr_1, p);
        str = Absyn.pathString(path);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        (cache,Values.STRING(""),st);

    case (cache,_,"instantiateModel",{Values.CODE(Absyn.C_TYPENAME(path))},st,_)
      equation
        b = Error.getNumMessages() == 0;
        str = Absyn.pathString(path);
        str = "Instantiation of " + str + " failed with no error message";
        if b then
          Error.addMessage(Error.INTERNAL_ERROR, {str,"<TOP>"});
        end if;
      then
        (cache,Values.STRING(""),st);

    case (cache,_,"importFMU",{Values.STRING(filename),Values.STRING(workdir),Values.INTEGER(fmiLogLevel),Values.BOOL(b1), Values.BOOL(b2), Values.BOOL(inputConnectors), Values.BOOL(outputConnectors)},st,_)
      equation
        Error.clearMessages() "Clear messages";
        true = System.regularFileExists(filename);
        workdir = if System.directoryExists(workdir) then workdir else System.pwd();
        /* Initialize FMI objects */
        (b, fmiContext, fmiInstance, fmiInfo, fmiTypeDefinitionsList, fmiExperimentAnnotation, fmiModelVariablesInstance, fmiModelVariablesList) = FMIExt.initializeFMIImport(filename, workdir, fmiLogLevel, inputConnectors, outputConnectors);
        true = b; /* if something goes wrong while initializing */
        fmiTypeDefinitionsList = listReverse(fmiTypeDefinitionsList);
        fmiModelVariablesList = listReverse(fmiModelVariablesList);
        s1 = System.tolower(System.platform());
        str = Tpl.tplString(CodegenFMU.importFMUModelica, FMI.FMIIMPORT(s1, filename, workdir, fmiLogLevel, b2, fmiContext, fmiInstance, fmiInfo, fmiTypeDefinitionsList, fmiExperimentAnnotation, fmiModelVariablesInstance, fmiModelVariablesList, inputConnectors, outputConnectors));
        pd = System.pathDelimiter();
        str1 = FMI.getFMIModelIdentifier(fmiInfo);
        str2 = FMI.getFMIType(fmiInfo);
        str3 = FMI.getFMIVersion(fmiInfo);
        outputFile = stringAppendList({workdir,pd,str1,"_",str2,"_FMU.mo"});
        filename_1 = if b1 then stringAppendList({workdir,pd,str1,"_",str2,"_FMU.mo"}) else stringAppendList({str1,"_",str2,"_FMU.mo"});
        System.writeFile(outputFile, str);
        /* Release FMI objects */
        FMIExt.releaseFMIImport(fmiModelVariablesInstance, fmiInstance, fmiContext, str3);
      then
        (cache,Values.STRING(filename_1),st);

    case (cache,_,"importFMU",{Values.STRING(filename),Values.STRING(_),Values.INTEGER(_),Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.BOOL(_)},st,_)
      equation
        false = System.regularFileExists(filename);
        Error.clearMessages() "Clear messages";
        Error.addMessage(Error.FILE_NOT_FOUND_ERROR, {filename});
      then
        (cache,Values.STRING(""),st);

    case (cache,_,"importFMU",{Values.STRING(_),Values.STRING(_),Values.INTEGER(_),Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.BOOL(_)},st,_)
      then
        (cache,Values.STRING(""),st);

    case (cache,_,"getIndexReductionMethod",_,st,_)
      equation
        str = Config.getIndexReductionMethod();
      then (cache,Values.STRING(str),st);

    case (cache,_,"getAvailableIndexReductionMethods",_,st,_)
      equation
        (strs1,strs2) = Flags.getConfigOptionsStringList(Flags.INDEX_REDUCTION_METHOD);
        v1 = ValuesUtil.makeArray(List.map(strs1, ValuesUtil.makeString));
        v2 = ValuesUtil.makeArray(List.map(strs2, ValuesUtil.makeString));
        v = Values.TUPLE({v1,v2});
      then (cache,v,st);

    case (cache,_,"getMatchingAlgorithm",_,st,_)
      equation
        str = Config.getMatchingAlgorithm();
      then (cache,Values.STRING(str),st);

    case (cache,_,"getAvailableMatchingAlgorithms",_,st,_)
      equation
        (strs1,strs2) = Flags.getConfigOptionsStringList(Flags.MATCHING_ALGORITHM);
        v1 = ValuesUtil.makeArray(List.map(strs1, ValuesUtil.makeString));
        v2 = ValuesUtil.makeArray(List.map(strs2, ValuesUtil.makeString));
        v = Values.TUPLE({v1,v2});
      then (cache,v,st);

    case (cache,_,"getTearingMethod",_,st,_)
      equation
        str = Config.getTearingMethod();
      then (cache,Values.STRING(str),st);

    case (cache,_,"getAvailableTearingMethods",_,st,_)
      equation
        (strs1,strs2) = Flags.getConfigOptionsStringList(Flags.TEARING_METHOD);
        v1 = ValuesUtil.makeArray(List.map(strs1, ValuesUtil.makeString));
        v2 = ValuesUtil.makeArray(List.map(strs2, ValuesUtil.makeString));
        v = Values.TUPLE({v1,v2});
      then (cache,v,st);

    case (cache,_,"saveModel",{Values.STRING(filename),Values.CODE(Absyn.C_TYPENAME(classpath))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        str = Dump.unparseStr(Absyn.PROGRAM({absynClass},Absyn.TOP()),true);
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,_,"save",{Values.CODE(Absyn.C_TYPENAME(className))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        (newp,filename) = Interactive.getContainedClassAndFile(className, p);
        str = Dump.unparseStr(newp,true);
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,_,"save",{Values.CODE(Absyn.C_TYPENAME(_))},st,_)
    then (cache,Values.BOOL(false),st);

    case (cache,_,"saveAll",{Values.STRING(filename)},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        str = Dump.unparseStr(p,true);
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,_,"saveModel",{Values.STRING(name),Values.CODE(Absyn.C_TYPENAME(classpath))},
        (st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        _ = Interactive.getPathedClassInProgram(classpath, p);
        Error.addMessage(Error.WRITING_FILE_ERROR, {name});
      then
        (cache,Values.BOOL(false),st);

    case (cache,_,"saveModel",{Values.STRING(_),Values.CODE(Absyn.C_TYPENAME(classpath))},st,_)
      equation
        cname = Absyn.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {cname,"global"});
      then
        (cache,Values.BOOL(false),st);

    case (cache,_,"saveTotalModel",{Values.STRING(filename),Values.CODE(Absyn.C_TYPENAME(classpath))},st,_)
      equation
        st = saveTotalModel(filename,classpath,st);
      then
        (cache, Values.BOOL(true), st);

    case (cache,_,"saveTotalModel",{Values.STRING(_),Values.CODE(Absyn.C_TYPENAME(_))},(st as GlobalScript.SYMBOLTABLE()),_)
      then (cache, Values.BOOL(false), st);

    case (cache,_,"getDocumentationAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        ((str1,str2)) = Interactive.getNamedAnnotation(classpath, p, Absyn.IDENT("Documentation"), SOME(("","")),Interactive.getDocumentationAnnotationString);
      then
        (cache,ValuesUtil.makeArray({Values.STRING(str1),Values.STRING(str2)}),st);

    case (cache,_,"addClassAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.CODE(Absyn.C_EXPRESSION(aexp))},GlobalScript.SYMBOLTABLE(p,_,ic,iv,cf,lf),_)
      equation
        p = Interactive.addClassAnnotation(Absyn.pathToCref(classpath), Absyn.NAMEDARG("annotate",aexp)::{}, p);
      then
        (cache,Values.BOOL(true),GlobalScript.SYMBOLTABLE(p,NONE(),ic,iv,cf,lf));

    case (cache,_,"addClassAnnotation",_,st as GlobalScript.SYMBOLTABLE(),_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,_,"setDocumentationAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(str1),Values.STRING(str2)},GlobalScript.SYMBOLTABLE(p,_,ic,iv,cf,lf),_)
      equation
        nargs = List.consOnTrue(not stringEq(str1,""), Absyn.NAMEDARG("info",Absyn.STRING(str1)), {});
        nargs = List.consOnTrue(not stringEq(str2,""), Absyn.NAMEDARG("revisions",Absyn.STRING(str2)), nargs);
        aexp = Absyn.CALL(Absyn.CREF_IDENT("Documentation",{}),Absyn.FUNCTIONARGS({},nargs));
        p = Interactive.addClassAnnotation(Absyn.pathToCref(classpath), Absyn.NAMEDARG("annotate",aexp)::{}, p);
      then
        (cache,Values.BOOL(true),GlobalScript.SYMBOLTABLE(p,NONE(),ic,iv,cf,lf));

    case (cache,_,"setDocumentationAnnotation",_,st as GlobalScript.SYMBOLTABLE(),_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,_,"isType",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isType(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"isPackage",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isPackage(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"isClass",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isClass(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"isRecord",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isRecord(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"isBlock",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isBlock(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"isFunction",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isFunction(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"isPartial",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isPartial(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"isModel",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isModel(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"isConnector",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isConnector(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"isOptimization",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isOptimization(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"isEnumeration",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isEnumeration(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"isOperator",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isOperator(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"isOperatorRecord",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isOperatorRecord(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"isOperatorFunction",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isOperatorFunction(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"isProtectedClass",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(name)},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.isProtectedClass(classpath, name, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"getBuiltinType",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(),_)
      equation
        (_, tp, _) = Lookup.lookupType(cache, env, classpath, SOME(Absyn.dummyInfo));
        str = Types.unparseType(tp);
      then
        (cache,Values.STRING(str),st);

    // if the lookup fails
    case (cache,_,"getBuiltinType",{Values.CODE(Absyn.C_TYPENAME(_))},st as GlobalScript.SYMBOLTABLE(ast=_),_)
      then
        (cache,Values.STRING(""),st);

    case (cache,_,"extendsFrom",
          {Values.CODE(Absyn.C_TYPENAME(classpath)),
           Values.CODE(Absyn.C_TYPENAME(baseClassPath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        paths = Interactive.getAllInheritedClasses(classpath, p);
        b = List.applyAndFold1(paths, boolOr, Absyn.pathSuffixOfr, baseClassPath, false);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"extendsFrom",_,st as GlobalScript.SYMBOLTABLE(),_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,_,"isExperiment",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        b = Interactive.getNamedAnnotation(classpath, p, Absyn.IDENT("experiment"), SOME(false), hasStopTime);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"isExperiment",_,st as GlobalScript.SYMBOLTABLE(),_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,_,"getInheritedClasses",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        paths = Interactive.getInheritedClasses(classpath, st);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,_,"getInheritedClasses",_,st as GlobalScript.SYMBOLTABLE(),_)
      then (cache,ValuesUtil.makeArray({}),st);

    case (cache,_,"getComponentsTest",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        (sp, st) = GlobalScriptUtil.symbolTableToSCode(st);
        (cache, env) = Inst.makeEnvFromProgram(FCore.emptyCache(), sp, Absyn.IDENT(""));
        (cache,(cl as SCode.CLASS(name=name,encapsulatedPrefix=encflag,restriction=restr)),env) = Lookup.lookupClass(cache, env, classpath, NONE());
        env = FGraph.openScope(env, encflag, SOME(name), FGraph.restrictionToScopeType(restr));
        (_, env) = Inst.partialInstClassIn(cache, env, InnerOuter.emptyInstHierarchy, DAE.NOMOD(), Prefix.NOPRE(),
          ClassInf.start(restr, FGraph.getGraphName(env)), cl, SCode.PUBLIC(), {}, 0);
        valsLst = list(getComponentInfo(c, env, isProtected=false) for c in Interactive.getPublicComponentsInClass(absynClass));
        valsLst = listAppend(list(getComponentInfo(c, env, isProtected=true) for c in Interactive.getProtectedComponentsInClass(absynClass)), valsLst);
      then (cache,ValuesUtil.makeArray(List.flatten(valsLst)),st);

    case (cache,_,"getComponentsTest",{Values.CODE(Absyn.C_TYPENAME(_))},st as GlobalScript.SYMBOLTABLE(),_)
      then
        (cache,Values.ARRAY({},{}),st);


    case (cache,_,"getSimulationOptions",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.REAL(startTime),Values.REAL(stopTime),Values.REAL(tolerance),Values.INTEGER(numberOfIntervals),Values.REAL(interval)},st as GlobalScript.SYMBOLTABLE(),_)
      equation
        cr_1 = Absyn.pathToCref(classpath);
        // ignore the name of the model
        ErrorExt.setCheckpoint("getSimulationOptions");
        simOpt = GlobalScript.SIMULATION_OPTIONS(DAE.RCONST(startTime),DAE.RCONST(stopTime),DAE.ICONST(numberOfIntervals),DAE.RCONST(0.0),DAE.RCONST(tolerance),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""));
        ErrorExt.rollBack("getSimulationOptions");
        (_, _::startTimeExp::stopTimeExp::intervalExp::toleranceExp::_) = StaticScript.getSimulationArguments(FCore.emptyCache(), FGraph.empty(), {Absyn.CREF(cr_1)},{},false,SOME(st),Prefix.NOPRE(),Absyn.dummyInfo,SOME(simOpt));
        startTime = ValuesUtil.valueReal(Util.makeValueOrDefault(Ceval.cevalSimple,startTimeExp,Values.REAL(startTime)));
        stopTime = ValuesUtil.valueReal(Util.makeValueOrDefault(Ceval.cevalSimple,stopTimeExp,Values.REAL(stopTime)));
        tolerance = ValuesUtil.valueReal(Util.makeValueOrDefault(Ceval.cevalSimple,toleranceExp,Values.REAL(tolerance)));
        Values.INTEGER(numberOfIntervals) = Util.makeValueOrDefault(Ceval.cevalSimple,intervalExp,Values.INTEGER(numberOfIntervals)); // number of intervals
        if numberOfIntervals == 0 then
          numberOfIntervals = if interval > 0.0 then integer(ceil((stopTime - startTime)/interval)) else 0;
        else
          interval = (stopTime-startTime) / max(numberOfIntervals,1);
        end if;
      then
        (cache,Values.TUPLE({Values.REAL(startTime),Values.REAL(stopTime),Values.REAL(tolerance),Values.INTEGER(numberOfIntervals),Values.REAL(interval)}),st);

    case (cache,_,"searchClassNames",{Values.STRING(str), Values.BOOL(b)},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        (_,paths) = Interactive.getClassNamesRecursive(NONE(),p,false,{});
        paths = listReverse(paths);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
        vals = searchClassNames(vals, str, b, p);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,_,"getAvailableLibraries",{},st,_)
      equation
        mp = Settings.getModelicaPath(Config.getRunningTestsuite());
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        files = List.flatten(List.map(mps, System.moFiles));
        dirs = List.flatten(List.map(mps, System.subDirectories));
        files = List.map(List.map1(listAppend(files,dirs), System.strtok, ". "), listHead);
        (str, status) = System.popen("impact search '' | perl -pe 's/\\e\\[?.*?[\\@-~]//g' | grep '[^ :]*:' | cut -d: -f1 2>&1");
        if 0==status then
          files = listAppend(files, System.strtok(str,"\n"));
        end if;
        files = List.sort(files,Util.strcmpBool);
        files = List.sortedUnique(files, stringEqual);
        v = ValuesUtil.makeArray(List.map(files, ValuesUtil.makeString));
      then
        (cache,v,st);

    case (cache,_,"getUses",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        (absynClass as Absyn.CLASS()) = Interactive.getPathedClassInProgram(classpath, p);
        uses = Interactive.getUsesAnnotation(Absyn.PROGRAM({absynClass},Absyn.TOP()));
        v = ValuesUtil.makeArray(List.map(uses,makeUsesArray));
      then
        (cache,v,st);

    case (cache,_,"getDerivedClassModifierNames",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        args = Interactive.getDerivedClassModifierNames(absynClass);
        vals = List.map(args, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v,st);

    case (cache,_,"getDerivedClassModifierValue",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_TYPENAME(className))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        str = Interactive.getDerivedClassModifierValue(absynClass, className);
      then
        (cache,Values.STRING(str),st);

    case (cache,_,"getAstAsCorbaString",{Values.STRING("<interactive>")},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        Print.clearBuf();
        Dump.getAstAsCorbaString(p);
        res = Print.getString();
        Print.clearBuf();
      then
        (cache,Values.STRING(res),st);

    case (cache,_,"getAstAsCorbaString",{Values.STRING(str)},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        Print.clearBuf();
        Dump.getAstAsCorbaString(p);
        Print.writeBuf(str);
        Print.clearBuf();
        str = "Wrote result to file: " + str;
      then
        (cache,Values.STRING(str),st);

    case (cache,_,"getAstAsCorbaString",_,st,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"getAstAsCorbaString failed"});
      then (cache,Values.STRING(""),st);

    case (cache,_,"readSimulationResult",{Values.STRING(filename),Values.ARRAY(valueLst=cvars),Values.INTEGER(size)},st,_)
      equation
        vars_1 = List.map(cvars, ValuesUtil.printCodeVariableName);
        filename_1 = Util.absoluteOrRelative(filename);
        value = SimulationResults.readDataset(filename_1, vars_1, size);
      then
        (cache,value,st);

    case (cache,_,"readSimulationResult",_,st,_)
      equation
        Error.addMessage(Error.SCRIPT_READ_SIM_RES_ERROR, {});
      then (cache,Values.META_FAIL(),st);

    case (cache,_,"readSimulationResultSize",{Values.STRING(filename)},st,_)
      equation
        filename_1 = Util.absoluteOrRelative(filename);
        i = SimulationResults.readSimulationResultSize(filename_1);
      then
        (cache,Values.INTEGER(i),st);

    case (cache,_,"readSimulationResultVars",{Values.STRING(filename),Values.BOOL(b1),Values.BOOL(b2)},st,_)
      equation
        filename_1 = Util.absoluteOrRelative(filename);
        args = SimulationResults.readVariables(filename_1, b1, b2);
        vals = List.map(args, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v,st);

    case (cache,_,"compareSimulationResults",{Values.STRING(filename),Values.STRING(filename_1),Values.STRING(filename2),Values.REAL(x1),Values.REAL(x2),Values.ARRAY(valueLst=cvars)},st,_)
      equation
        filename = Util.absoluteOrRelative(filename);
        filename_1 = Util.testsuiteFriendlyPath(filename_1);
        filename_1 = Util.absoluteOrRelative(filename_1);
        filename2 = Util.absoluteOrRelative(filename2);
        vars_1 = List.map(cvars, ValuesUtil.extractValueString);
        strings = SimulationResults.cmpSimulationResults(Config.getRunningTestsuite(),filename,filename_1,filename2,x1,x2,vars_1);
        cvars = List.map(strings,ValuesUtil.makeString);
        v = ValuesUtil.makeArray(cvars);
      then
        (cache,v,st);

    case (cache,_,"compareSimulationResults",_,st,_)
      then (cache,Values.STRING("Error in compareSimulationResults"),st);

    case (cache,_,"filterSimulationResults",{Values.STRING(filename),Values.STRING(filename_1),Values.ARRAY(valueLst=cvars),Values.INTEGER(numberOfIntervals)},st,_)
      equation
        vars_1 = List.map(cvars, ValuesUtil.extractValueString);
        b = SimulationResults.filterSimulationResults(filename,filename_1,vars_1,numberOfIntervals);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"filterSimulationResults",_,st,_)
      then (cache,Values.BOOL(false),st);

    case (cache,_,"diffSimulationResults",{Values.STRING(filename),Values.STRING(filename_1),Values.STRING(filename2),Values.REAL(reltol),Values.REAL(reltolDiffMinMax),Values.REAL(rangeDelta),Values.ARRAY(valueLst=cvars),Values.BOOL(b)},st,_)
      equation
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename = Util.absoluteOrRelative(filename);
        filename_1 = Util.testsuiteFriendlyPath(filename_1);
        filename_1 = Util.absoluteOrRelative(filename_1);
        filename2 = Util.absoluteOrRelative(filename2);
        vars_1 = List.map(cvars, ValuesUtil.extractValueString);
        (b,strings) = SimulationResults.diffSimulationResults(Config.getRunningTestsuite(),filename,filename_1,filename2,reltol,reltolDiffMinMax,rangeDelta,vars_1,b);
        cvars = List.map(strings,ValuesUtil.makeString);
        v1 = ValuesUtil.makeArray(cvars);
      then
        (cache,Values.TUPLE({Values.BOOL(b),v1}),st);

    case (cache,_,"diffSimulationResults",_,st,_)
      equation
        v = ValuesUtil.makeArray({});
      then (cache,Values.TUPLE({Values.BOOL(false),v}),st);

    case (cache,_,"diffSimulationResultsHtml",{Values.STRING(str),Values.STRING(filename),Values.STRING(filename_1),Values.REAL(reltol),Values.REAL(reltolDiffMinMax),Values.REAL(rangeDelta)},st,_)
      equation
        filename = Util.absoluteOrRelative(filename);
        filename_1 = Util.testsuiteFriendlyPath(filename_1);
        filename_1 = Util.absoluteOrRelative(filename_1);
        str = SimulationResults.diffSimulationResultsHtml(Config.getRunningTestsuite(),filename,filename_1,reltol,reltolDiffMinMax,rangeDelta,str);
      then
        (cache,Values.STRING(str),st);

    case (cache,_,"diffSimulationResultsHtml",_,st,_)
      then (cache,Values.STRING(""),st);

    case (cache,_,"checkTaskGraph",{Values.STRING(filename),Values.STRING(filename_1)},st,_)
      equation
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename = if System.substring(filename,1,1) == "/" then filename else stringAppendList({pwd,pd,filename});
        filename_1 = if System.substring(filename_1,1,1) == "/" then filename_1 else stringAppendList({pwd,pd,filename_1});
        strings = TaskGraphResults.checkTaskGraph(filename, filename_1);
        cvars = List.map(strings,ValuesUtil.makeString);
        v = ValuesUtil.makeArray(cvars);
      then (cache,v,st);

    case (cache,_,"checkTaskGraph",_,st,_)
      then (cache,Values.STRING("Error in checkTaskGraph"),st);

    case (cache,_,"checkCodeGraph",{Values.STRING(filename),Values.STRING(filename_1)},st,_)
      equation
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename = if System.substring(filename,1,1) == "/" then filename else stringAppendList({pwd,pd,filename});
        filename_1 = if System.substring(filename_1,1,1) == "/" then filename_1 else stringAppendList({pwd,pd,filename_1});
        strings = TaskGraphResults.checkCodeGraph(filename, filename_1);
        cvars = List.map(strings,ValuesUtil.makeString);
        v = ValuesUtil.makeArray(cvars);
      then (cache,v,st);

    case (cache,_,"checkCodeGraph",_,st,_)
      then (cache,Values.STRING("Error in checkCodeGraph"),st);

    //plotAll(model)
    case (cache,env,"plotAll",
        {
          Values.BOOL(externalWindow),
          Values.STRING(filename),
          Values.STRING(title),
          Values.STRING(gridStr),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.ARRAY(valueLst={Values.REAL(x1),Values.REAL(x2)}),
          Values.ARRAY(valueLst={Values.REAL(y1),Values.REAL(y2)}),
          Values.REAL(curveWidth),
          Values.INTEGER(curveStyle),
          Values.STRING(legendPosition),
          Values.STRING(footer),
          Values.BOOL(autoScale),
          Values.BOOL(forceOMPlot)
        },
        st,
        _)
      equation
        // get OPENMODELICAHOME
        omhome = Settings.getInstallationDirectoryPath();
        // get the simulation filename
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        pd = System.pathDelimiter();
        // create absolute path of simulation result file
        str1 = System.pwd() + pd + filename;
        s1 = if System.os() == "Windows_NT" then ".exe" else "";
        filename = if System.regularFileExists(str1) then str1 else filename;
        // check if plot callback is defined
        b = System.plotCallBackDefined();
        if boolOr(forceOMPlot, boolNot(b)) then
          // create the path till OMPlot
          str2 = stringAppendList({omhome,pd,"bin",pd,"OMPlot",s1});
          // create the list of arguments for OMPlot
          str3 = "--filename=\"" + filename + "\" --title=\"" + title + "\" --grid=" + gridStr + " --plotAll --logx=" + boolString(logX) + " --logy=" + boolString(logY) + " --xlabel=\"" + xLabel + "\" --ylabel=\"" + yLabel + "\" --xrange=" + realString(x1) + ":" + realString(x2) + " --yrange=" + realString(y1) + ":" + realString(y2) + " --new-window=" + boolString(externalWindow) + " --curve-width=" + realString(curveWidth) + " --curve-style=" + intString(curveStyle) + " --legend-position=\"" + legendPosition + "\" --footer=\"" + footer + "\" --auto-scale=" + boolString(autoScale);
          call = stringAppendList({"\"",str2,"\""," ",str3});
          0 = System.spawnCall(str2, call);
        elseif b then
          logXStr = boolString(logX);
          logYStr = boolString(logY);
          x1Str = realString(x1);
          x2Str = realString(x2);
          y1Str = realString(y1);
          y2Str = realString(y2);
          curveWidthStr = realString(curveWidth);
          curveStyleStr = intString(curveStyle);
          autoScaleStr = boolString(autoScale);
          System.plotCallBack(externalWindow,filename,title,gridStr,"plotall",logXStr,logYStr,xLabel,yLabel,x1Str,x2Str,y1Str,y2Str,curveWidthStr,curveStyleStr,legendPosition,footer,autoScaleStr,"");
        end if;
      then
        (cache,Values.BOOL(true),st);

    case (cache,_,"plotAll",_,st,_)
      then (cache,Values.BOOL(false),st);

    // plot(x, model)
    case (cache,env,"plot",
        {
          Values.ARRAY(valueLst = cvars),
          Values.BOOL(externalWindow),
          Values.STRING(filename),
          Values.STRING(title),
          Values.STRING(gridStr),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.ARRAY(valueLst={Values.REAL(x1),Values.REAL(x2)}),
          Values.ARRAY(valueLst={Values.REAL(y1),Values.REAL(y2)}),
          Values.REAL(curveWidth),
          Values.INTEGER(curveStyle),
          Values.STRING(legendPosition),
          Values.STRING(footer),
          Values.BOOL(autoScale),
          Values.BOOL(forceOMPlot)
        },
        st,_)
      equation
        // get the variables list
        vars_1 = List.map(cvars, ValuesUtil.printCodeVariableName);
        // get OPENMODELICAHOME
        omhome = Settings.getInstallationDirectoryPath();
        // get the simulation filename
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        pd = System.pathDelimiter();
        // create absolute path of simulation result file
        str1 = System.pwd() + pd + filename;
        s1 = if System.os() == "Windows_NT" then ".exe" else "";
        filename = if System.regularFileExists(str1) then str1 else filename;
        // check if plot callback is defined
        b = System.plotCallBackDefined();
        if boolOr(forceOMPlot, boolNot(b)) then
          // seperate the variables
          str = stringDelimitList(vars_1,"\" \"");
          // create the path till OMPlot
          str2 = stringAppendList({omhome,pd,"bin",pd,"OMPlot",s1});
          // create the list of arguments for OMPlot
          str3 = "--filename=\"" + filename + "\" --title=\"" + title + "\" --grid=" + gridStr + " --plot --logx=" + boolString(logX) + " --logy=" + boolString(logY) + " --xlabel=\"" + xLabel + "\" --ylabel=\"" + yLabel + "\" --xrange=" + realString(x1) + ":" + realString(x2) + " --yrange=" + realString(y1) + ":" + realString(y2) + " --new-window=" + boolString(externalWindow) + " --curve-width=" + realString(curveWidth) + " --curve-style=" + intString(curveStyle) + " --legend-position=\"" + legendPosition + "\" --footer=\"" + footer + "\" --auto-scale=" + boolString(autoScale) + " \"" + str + "\"";
          call = stringAppendList({"\"",str2,"\""," ",str3});
          0 = System.spawnCall(str2, call);
        elseif b then
          logXStr = boolString(logX);
          logYStr = boolString(logY);
          x1Str = realString(x1);
          x2Str = realString(x2);
          y1Str = realString(y1);
          y2Str = realString(y2);
          curveWidthStr = realString(curveWidth);
          curveStyleStr = intString(curveStyle);
          autoScaleStr = boolString(autoScale);
          // seperate the variables
          str = stringDelimitList(vars_1, " ");
          System.plotCallBack(externalWindow,filename,title,gridStr,"plot",logXStr,logYStr,xLabel,yLabel,x1Str,x2Str,y1Str,y2Str,curveWidthStr,curveStyleStr,legendPosition,footer,autoScaleStr,str);
        end if;
      then
        (cache,Values.BOOL(true),st);

    case (cache,_,"plot",_,st,_)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"val",{cvar,Values.REAL(timeStamp),Values.STRING("<default>")},st,_)
      equation
        (cache,Values.STRING(filename),_) = Ceval.ceval(cache,env,buildCurrentSimulationResultExp(), true, SOME(st),msg, 0);
        varNameStr = ValuesUtil.printCodeVariableName(cvar);
        val = SimulationResults.val(filename,varNameStr,timeStamp);
      then (cache,Values.REAL(val),st);

    case (cache,_,"val",{cvar,Values.REAL(timeStamp),Values.STRING(filename)},st,_)
      equation
        false = stringEq(filename,"<default>");
        varNameStr = ValuesUtil.printCodeVariableName(cvar);
        val = SimulationResults.val(filename,varNameStr,timeStamp);
      then (cache,Values.REAL(val),st);

    case (cache,_,"closeSimulationResultFile",_,st,_)
      equation
        SimulationResults.close();
      then
        (cache,Values.BOOL(true),st);

    case (cache,_,"getParameterNames",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        strings = Interactive.getParameterNames(path, p);
        vals = List.map(strings, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v,st);

    case (cache,_,"getParameterValue",{Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str1)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        str2 = Interactive.getComponentBinding(path, str1, p);
      then
        (cache,Values.STRING(str2),st);

    case (cache,_,"getComponentModifierNames",{Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str1)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        strings = Interactive.getComponentModifierNames(path, str1, p);
        vals = List.map(strings, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v,st);

    case (cache,_,"removeComponentModifiers",{Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str1)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        (p,b) = Interactive.removeComponentModifiers(path, str1, p);
        st = GlobalScriptUtil.setSymbolTableAST(st, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"removeExtendsModifiers",
          {Values.CODE(Absyn.C_TYPENAME(classpath)),
           Values.CODE(Absyn.C_TYPENAME(baseClassPath))},st as GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        (p,b) = Interactive.removeExtendsModifiers(classpath, baseClassPath, p);
        st = GlobalScriptUtil.setSymbolTableAST(st, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,_,"getAlgorithmCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = listLength(getAlgorithms(absynClass));
      then
        (cache,Values.INTEGER(n),st);

    case (cache,_,"getAlgorithmCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,_,"getNthAlgorithm",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthAlgorithm(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,_,"getNthAlgorithm",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,_,"getInitialAlgorithmCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = listLength(getInitialAlgorithms(absynClass));
      then
        (cache,Values.INTEGER(n),st);

    case (cache,_,"getInitialAlgorithmCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,_,"getNthInitialAlgorithm",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthInitialAlgorithm(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,_,"getNthInitialAlgorithm",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,_,"getAlgorithmItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getAlgorithmItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);

    case (cache,_,"getAlgorithmItemsCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,_,"getNthAlgorithmItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthAlgorithmItem(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,_,"getNthAlgorithmItem",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,_,"getInitialAlgorithmItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getInitialAlgorithmItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);

    case (cache,_,"getInitialAlgorithmItemsCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,_,"getNthInitialAlgorithmItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthInitialAlgorithmItem(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,_,"getNthInitialAlgorithmItem",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,_,"getEquationCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = listLength(getEquations(absynClass));
      then
        (cache,Values.INTEGER(n),st);

    case (cache,_,"getEquationCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,_,"getNthEquation",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthEquation(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,_,"getNthEquation",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,_,"getInitialEquationCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = listLength(getInitialEquations(absynClass));
      then
        (cache,Values.INTEGER(n),st);

    case (cache,_,"getInitialEquationCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,_,"getNthInitialEquation",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthInitialEquation(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,_,"getNthInitialEquation",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,_,"getEquationItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getEquationItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);

    case (cache,_,"getEquationItemsCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,_,"getNthEquationItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthEquationItem(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,_,"getNthEquationItem",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,_,"getInitialEquationItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getInitialEquationItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);

    case (cache,_,"getInitialEquationItemsCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,_,"getNthInitialEquationItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthInitialEquationItem(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,_,"getNthInitialEquationItem",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,_,"getAnnotationCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getAnnotationCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);

    case (cache,_,"getAnnotationCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,_,"getNthAnnotationString",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthAnnotationString(absynClass, n);
      then
        (cache,Values.STRING(str),st);

    case (cache,_,"getNthAnnotationString",_,st,_) then (cache,Values.STRING(""),st);

    case (cache,_,"getImportCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getImportCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);

    case (cache,_,"getImportCount",_,st,_) then (cache,Values.INTEGER(0),st);

    case (cache,_,"getNthImport",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        vals = getNthImport(absynClass, n);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,_,"getNthImport",_,st,_) then (cache,ValuesUtil.makeArray({}),st);

    // plotParametric
    case (cache,env,"plotParametric",
        {
          cvar,
          cvar2,
          Values.BOOL(externalWindow),
          Values.STRING(filename),
          Values.STRING(title),
          Values.STRING(gridStr),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.ARRAY(valueLst={Values.REAL(x1),Values.REAL(x2)}),
          Values.ARRAY(valueLst={Values.REAL(y1),Values.REAL(y2)}),
          Values.REAL(curveWidth),
          Values.INTEGER(curveStyle),
          Values.STRING(legendPosition),
          Values.STRING(footer),
          Values.BOOL(autoScale),
          Values.BOOL(forceOMPlot)
        },
        st,_)
      equation
        // get OPENMODELICAHOME
        omhome = Settings.getInstallationDirectoryPath();
        // get the simulation filename
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        pd = System.pathDelimiter();
        // create absolute path of simulation result file
        str1 = System.pwd() + pd + filename;
        s1 = if System.os() == "Windows_NT" then ".exe" else "";
        filename = if System.regularFileExists(str1) then str1 else filename;
        // check if plot callback is defined
        b = System.plotCallBackDefined();
        if boolOr(forceOMPlot, boolNot(b)) then
          // get the variables
          str = ValuesUtil.printCodeVariableName(cvar) + "\" \"" + ValuesUtil.printCodeVariableName(cvar2);
          // create the path till OMPlot
          str2 = stringAppendList({omhome,pd,"bin",pd,"OMPlot",s1});
          // create the list of arguments for OMPlot
          str3 = "--filename=\"" + filename + "\" --title=\"" + title + "\" --grid=" + gridStr + " --plotParametric --logx=" + boolString(logX) + " --logy=" + boolString(logY) + " --xlabel=\"" + xLabel + "\" --ylabel=\"" + yLabel + "\" --xrange=" + realString(x1) + ":" + realString(x2) + " --yrange=" + realString(y1) + ":" + realString(y2) + " --new-window=" + boolString(externalWindow) + " --curve-width=" + realString(curveWidth) + " --curve-style=" + intString(curveStyle) + " --legend-position=\"" + legendPosition + "\" --footer=\"" + footer + "\" --auto-scale=" + boolString(autoScale) + " \"" + str + "\"";
          call = stringAppendList({"\"",str2,"\""," ",str3});
          0 = System.spawnCall(str2, call);
        elseif b then
          // get the variables
          str = ValuesUtil.printCodeVariableName(cvar) + " " + ValuesUtil.printCodeVariableName(cvar2);
          logXStr = boolString(logX);
          logYStr = boolString(logY);
          x1Str = realString(x1);
          x2Str = realString(x2);
          y1Str = realString(y1);
          y2Str = realString(y2);
          curveWidthStr = realString(curveWidth);
          curveStyleStr = intString(curveStyle);
          autoScaleStr = boolString(autoScale);
          System.plotCallBack(externalWindow,filename,title,gridStr,"plotparametric",logXStr,logYStr,xLabel,yLabel,x1Str,x2Str,y1Str,y2Str,curveWidthStr,curveStyleStr,legendPosition,footer,autoScaleStr,str);
        end if;
      then
        (cache,Values.BOOL(true),st);

    case (cache,_,"plotParametric",_,st,_)
      then (cache,Values.BOOL(false),st);

    case (cache,env,"dumpXMLDAE",vals,st,_)
      equation
        (cache,st,xml_filename) = dumpXMLDAE(cache,env,vals,st, msg);
      then
        (cache,ValuesUtil.makeTuple({Values.BOOL(true),Values.STRING(xml_filename)}),st);

    case (cache,_,"dumpXMLDAE",_,st,_)
      then
        (cache,ValuesUtil.makeTuple({Values.BOOL(false),Values.STRING("")}),st);

    case (cache,_,"solveLinearSystem",{Values.ARRAY(valueLst=vals),v,Values.ENUM_LITERAL(index=1 /*dgesv*/),Values.ARRAY(valueLst={Values.INTEGER(-1)})},st,_)
      equation
        (realVals,i) = System.dgesv(List.map(vals,ValuesUtil.arrayValueReals),ValuesUtil.arrayValueReals(v));
        v = ValuesUtil.makeArray(List.map(realVals,ValuesUtil.makeReal));
      then (cache,Values.TUPLE({v,Values.INTEGER(i)}),st);

    case (cache,_,"solveLinearSystem",{Values.ARRAY(valueLst=vals),v,Values.ENUM_LITERAL(index=2 /*lpsolve55*/),Values.ARRAY(valueLst=vals2)},st,_)
      equation
        (realVals,i) = System.lpsolve55(List.map(vals,ValuesUtil.arrayValueReals),ValuesUtil.arrayValueReals(v),List.map(vals2,ValuesUtil.valueInteger));
        v = ValuesUtil.makeArray(List.map(realVals,ValuesUtil.makeReal));
      then (cache,Values.TUPLE({v,Values.INTEGER(i)}),st);

    case (cache,_,"solveLinearSystem",{_,v,_,_},st,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Unknown input to solveLinearSystem scripting function"});
      then (cache,Values.TUPLE({v,Values.INTEGER(-1)}),st);

 end matchcontinue;
end cevalInteractiveFunctions3;


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
    else System.getExeExt();
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

public function getIncidenceMatrix " author: adrpo
 translates a model and returns the incidence matrix"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  input String filenameprefix;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      list<GlobalScript.InstantiatedClass> ic_1,ic;
      BackendDAE.BackendDAE dlow;
      Absyn.ComponentRef a_cref;
      GlobalScript.SymbolTable st;
      Absyn.Program p;
      list<GlobalScript.Variable> iv;
      list<GlobalScript.CompiledCFunction> cf;
      Absyn.Msg msg;
      FCore.Cache cache;
      String flatModelicaStr,description;

    case (cache,env,_,(st as GlobalScript.SYMBOLTABLE(ast = p,instClsLst = ic)),_,_) /* mo file directory */
      equation
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env,_,dae_1) =
        Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,p_1,className);
        dae  = DAEUtil.transformationsBeforeBackend(cache,env,dae_1);
        description = DAEUtil.daeDescription(dae);
        _ = Interactive.addInstantiatedClass(ic, GlobalScript.INSTCLASS(className,dae,env));
        a_cref = Absyn.pathToCref(className);
        file_dir = getFileDir(a_cref, p);
        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        dlow = FindZeroCrossings.findZeroCrossings(dlow);
        flatModelicaStr = DAEDump.dumpStr(dae,FCore.getFunctionTree(cache));
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Boolean relaxedFrontEnd "Do not check for illegal simulation models, so we allow instantation of packages, etc";
  output FCore.Cache cache;
  output FCore.Graph env;
  output DAE.DAElist dae;
  output GlobalScript.SymbolTable st;
algorithm
  // add program to the cache so it can be used to lookup modelica://
  // URIs in external functions IncludeDirectory/LibraryDirectory
  st := runFrontEndLoadProgram(className, inInteractiveSymbolTable);
  cache := FCore.setProgramInCache(inCache, GlobalScriptUtil.getSymbolTableAST(st));
  if Flags.isSet(Flags.GC_PROF) then
    print(GC.profStatsStr(GC.getProfStats(), head="GC stats before front-end:") + "\n");
  end if;
  (cache,env,dae,st) := runFrontEndWork(cache,inEnv,className,st,relaxedFrontEnd,Error.getNumErrorMessages());
  if Flags.isSet(Flags.GC_PROF) then
    print(GC.profStatsStr(GC.getProfStats(), head="GC stats after front-end:") + "\n");
  end if;

end runFrontEnd;

protected function runFrontEndLoadProgram
  input Absyn.Path className;
  input GlobalScript.SymbolTable inSt;
  output GlobalScript.SymbolTable st;
algorithm
  st := matchcontinue (className, inSt)
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
      DAE.FunctionTree funcs;
      Boolean b;
    case (_, GlobalScript.SYMBOLTABLE(ast=p))
      equation
        _ = Interactive.getPathedClassInProgram(className, p, true);
      then inSt;
    case (_, GlobalScript.SYMBOLTABLE(p,fp,ic,iv,cf,lf))
      equation
        str = Absyn.pathFirstIdent(className);
        (p,b) = CevalScript.loadModel({(Absyn.IDENT(str),{"default"})},Settings.getModelicaPath(Config.getRunningTestsuite()),p,true,true,true,false);
        Error.assertionOrAddSourceMessage(not b,Error.NOTIFY_NOT_LOADED,{str,"default"},Absyn.dummyInfo);
        // print(stringDelimitList(list(Absyn.pathString(path) for path in Interactive.getTopClassnames(p)), ",") + "\n");
      then GlobalScript.SYMBOLTABLE(p,fp,ic,iv,cf,lf);
  end matchcontinue;
end runFrontEndLoadProgram;

protected function runFrontEndWork
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Boolean relaxedFrontEnd "Do not check for illegal simulation models, so we allow instantation of packages, etc";
  input Integer numError;
  output FCore.Cache cache;
  output FCore.Graph env;
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
      DAE.FunctionTree funcs;

   case (cache,env,_,GlobalScript.SYMBOLTABLE(p,fp,ic,iv,cf,lf),_,_)
      equation
        true = Flags.isSet(Flags.GRAPH_INST);
        false = Flags.isSet(Flags.SCODE_INST);

        System.realtimeTick(ClockIndexes.RT_CLOCK_FINST);
        str = Absyn.pathString(className);
        (absynClass as Absyn.CLASS(restriction = restriction)) = Interactive.getPathedClassInProgram(className, p, true);
        re = Absyn.restrString(restriction);
        Error.assertionOrAddSourceMessage(relaxedFrontEnd or not (Absyn.isFunctionRestriction(restriction) or Absyn.isPackageRestriction(restriction)),
          Error.INST_INVALID_RESTRICTION,{str,re},Absyn.dummyInfo);
        (p,true) = CevalScript.loadModel(Interactive.getUsesAnnotationOrDefault(Absyn.PROGRAM({absynClass},Absyn.TOP()), false),Settings.getModelicaPath(Config.getRunningTestsuite()),p,false,true,true,false);
        print("Load deps:      " + realString(System.realtimeTock(ClockIndexes.RT_CLOCK_FINST)) + "\n");

        System.realtimeTick(ClockIndexes.RT_CLOCK_FINST);
        scodeP = SCodeUtil.translateAbsyn2SCode(p);
        print("Absyn->SCode:   " + realString(System.realtimeTock(ClockIndexes.RT_CLOCK_FINST)) + "\n");

        dae = FInst.instPath(className, scodeP);
        ic_1 = ic;
      then
        (cache,env,dae,GlobalScript.SYMBOLTABLE(p,fp,ic_1,iv,cf,lf));

    case (_, _, _, GlobalScript.SYMBOLTABLE(p, fp, ic, iv, cf, lf), _, _)
      equation
        false = Flags.isSet(Flags.GRAPH_INST);
        true = Flags.isSet(Flags.SCODE_INST);
        scodeP = SCodeUtil.translateAbsyn2SCode(p);
        // remove extends Modelica.Icons.*
        //scodeP = SCodeSimplify.simplifyProgram(scodeP);

       // (_,scode_builtin) = Builtin.getInitialFunctions();

       // nfenv = NFEnv.buildInitialEnv(scodeP, scode_builtin);
       // (dae, funcs) = NFInst.instClass(className, nfenv);

       // cache = FCore.emptyCache();
       // cache = FCore.setCachedFunctionTree(cache, funcs);
       // env = FGraph.empty();
       // ic_1 = Interactive.addInstantiatedClass(ic,
       //   GlobalScript.INSTCLASS(className, dae, env));
       // st = GlobalScript.SYMBOLTABLE(p, fp, ic_1, iv, cf, lf);
        _ = NFInst.instClassInProgram(className, scodeP);

        cache = FCore.emptyCache();
        env = FGraph.empty();
        dae = DAE.DAE({});
        st = inInteractiveSymbolTable;
      then
        (cache, env, dae, st);

    case (cache,env,_,GlobalScript.SYMBOLTABLE(p,fp,ic,iv,cf,lf),_,_)
      equation
        false = Flags.isSet(Flags.GRAPH_INST);
        false = Flags.isSet(Flags.SCODE_INST);
        str = Absyn.pathString(className);
        (absynClass as Absyn.CLASS(restriction = restriction)) = Interactive.getPathedClassInProgram(className, p, true);
        re = Absyn.restrString(restriction);
        Error.assertionOrAddSourceMessage(relaxedFrontEnd or not (Absyn.isFunctionRestriction(restriction) or Absyn.isPackageRestriction(restriction)),
          Error.INST_INVALID_RESTRICTION,{str,re},Absyn.dummyInfo);
        (p,true) = CevalScript.loadModel(Interactive.getUsesAnnotationOrDefault(Absyn.PROGRAM({absynClass},Absyn.TOP()), false),Settings.getModelicaPath(Config.getRunningTestsuite()),p,false,true,true,false);

        //System.stopTimer();
        //print("\nExists+Dependency: " + realString(System.getTimerIntervalTime()));

        //System.startTimer();
        //print("\nAbsyn->SCode");

        scodeP = SCodeUtil.translateAbsyn2SCode(p);

        // TODO: Why not simply get the whole thing from the cached SCode? It's faster, just need to stop doing the silly Dependency stuff.

        //System.stopTimer();
        //print("\nAbsyn->SCode: " + realString(System.getTimerIntervalTime()));

        //System.startTimer();
        //print("\nInst.instantiateClass");
        (cache,env,_,dae) = Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,scodeP,className);

        FGraphDump.dumpGraph(env, "F:\\dev\\" + Absyn.pathString(className) + ".graph.graphml");

        //System.stopTimer();
        //print("\nInst.instantiateClass: " + realString(System.getTimerIntervalTime()));

        // adrpo: do not add it to the instantiated classes, it just consumes memory for nothing.
        ic_1 = ic;
        // ic_1 = Interactive.addInstantiatedClass(ic, GlobalScript.INSTCLASS(className,dae,env));
        _ = DAEUtil.getFunctionList(FCore.getFunctionTree(cache)); // Make sure that the functions are valid before returning success
      then (cache,env,dae,GlobalScript.SYMBOLTABLE(p,fp,ic_1,iv,cf,lf));

    case (cache,env,_,st as GlobalScript.SYMBOLTABLE(ast=p),_,_)
      equation
        str = Absyn.pathString(className);
        failure(_ = Interactive.getPathedClassInProgram(className, p));
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then fail();

    else
      equation
        str = Absyn.pathString(className);
        true = Error.getNumErrorMessages() == numError;
        str = "Instantiation of " + str + " failed with no error message.";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end runFrontEndWork;

protected function translateModel " author: x02lucpo
 translates a model into cpp code and writes also a makefile"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output FCore.Cache outCache;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  (outCache,outInteractiveSymbolTable,outBackendDAE,outStringLst,outFileDir,resultValues):=
  match (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix,addDummy,inSimSettingsOpt)
    local
      FCore.Cache cache;
      FCore.Graph env;
      BackendDAE.BackendDAE indexed_dlow;
      GlobalScript.SymbolTable st;
      list<String> libs;
      String file_dir, fileNamePrefix;
      Absyn.Program p;

    case (cache,env,_,st as GlobalScript.SYMBOLTABLE(),fileNamePrefix,_,_)
      equation
        (cache, st, indexed_dlow, libs, file_dir, resultValues) =
          SimCodeMain.translateModel(cache,env,className,st,fileNamePrefix,addDummy,inSimSettingsOpt,Absyn.FUNCTIONARGS({},{}));
      then
        (cache,st,indexed_dlow,libs,file_dir,resultValues);

  end match;
end translateModel;

/*protected function translateModelCPP " author: x02lucpo
 translates a model into cpp code and writes also a makefile"
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
  match (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix,addDummy,inSimSettingsOpt)
    local
      FCore.Cache cache;
      FCore.Graph env;
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

protected function buildModelFMU " author: Frenkel TUD
 translates a model into cpp code and writes also a makefile"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input String FMUVersion;
  input String FMUType;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input list<String> platforms = {"dynamic"};
  output FCore.Cache cache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable st;
protected
  Boolean staticSourceCodeFMU;
  String filenameprefix, quote, fmutmp, thisplatform, cmd, logfile;
  GlobalScript.SimulationOptions defaulSimOpt;
  SimCode.SimulationSettings simSettings;
  list<String> libs;
  Boolean isWindows;
algorithm
  st := inInteractiveSymbolTable;
  cache := inCache;
  if not FMI.checkFMIVersion(FMUVersion) then
    outValue := Values.STRING("");
    Error.addMessage(Error.UNKNOWN_FMU_VERSION, {FMUVersion});
    return;
  elseif not FMI.checkFMIType(FMUType) then
    outValue := Values.STRING("");
    Error.addMessage(Error.UNKNOWN_FMU_TYPE, {FMUType});
    return;
  end if;
  filenameprefix := Util.stringReplaceChar(if inFileNamePrefix == "<default>" then Absyn.pathString(className) else inFileNamePrefix,".","_");
  defaulSimOpt := buildSimulationOptionsFromModelExperimentAnnotation(st, className, filenameprefix, SOME(defaultSimulationOptions));
  simSettings := convertSimulationOptionsToSimCode(defaulSimOpt);
  try
    (cache, outValue, st,_, libs,_, _) := SimCodeMain.translateModelFMU(cache, inEnv, className, st, FMUVersion, FMUType, filenameprefix, addDummy, simSettings);
  else
    outValue := Values.STRING("");
    return;
  end try;
  isWindows := System.os() == "Windows_NT";
  // compile
  quote := if isWindows then "" else "'";
  CevalScript.compileModel(filenameprefix+"_FMU" , libs);
  if Config.simCodeTarget() == "Cpp" then
    // Cpp FMUs are not source-code FMUs
    return;
  end if;

  fmutmp := filenameprefix + ".fmutmp";
  logfile := filenameprefix+".log";

  thisplatform := " CC="+quote+System.getCCompiler()+quote+
      " CFLAGS="+quote+System.stringReplace(System.getCFlags(),"${MODELICAUSERCFLAGS}","")+quote+
      " LDFLAGS="+quote+("-L'"+Settings.getInstallationDirectoryPath()+"/lib/"+System.getTriple()+"/omc' "+
                         "-Wl,-rpath,'"+Settings.getInstallationDirectoryPath()+"/lib/"+System.getTriple()+"/omc' "+
                         System.getLDFlags()+" ");

  for platform in platforms loop
    cmd := "cd \"" +  fmutmp+"/sources\" && ./configure "+
      (if platform == "dynamic" then
        " --with-dynamic-om-runtime"+thisplatform+System.getRTLibsSim()+quote
      elseif platform == "static" then
        thisplatform+quote
      else
        (
        " --host="+quote+platform+quote+
        " CFLAGS="+quote+"-Os -flto"+quote+" LDFLAGS=-flto"
        )
      ) + " && make clean";
    if System.regularFileExists(logfile) then
      System.removeFile(logfile);
    end if;
    if 0 <> System.systemCall(cmd, outFile=logfile) then
      outValue := Values.STRING("");
      Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {System.readFile(logfile)});
      return;
    end if;
    CevalScript.compileModel(filenameprefix , libs, workingDir=fmutmp+"/sources", makeVars={});
  end for;

  System.removeDirectory(fmutmp);
end buildModelFMU;


protected function translateModelXML " author: Alachew
 translates a model into XML code "
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
algorithm
  (outCache,outValue,outInteractiveSymbolTable):=
  match (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix,addDummy,inSimSettingsOpt)
    local
      FCore.Cache cache;
      FCore.Graph env;
      BackendDAE.BackendDAE indexed_dlow;
      GlobalScript.SymbolTable st;
      list<String> libs;
      Values.Value outValMsg;
      String file_dir, fileNamePrefix, str;
    case (cache,env,_,st,fileNamePrefix,_,_) /* mo file directory */
      equation
        (cache, outValMsg, st,_,_,_, _) =
          SimCodeMain.translateModelXML(cache,env,className,st,fileNamePrefix,addDummy,inSimSettingsOpt);
      then
        (cache,outValMsg,st);
    else /* mo file directory */
      equation
         str = Error.printMessagesStr(false);
      then
        (inCache,ValuesUtil.makeArray({Values.STRING("translateModelXML error."),Values.STRING(str)}),inInteractiveSymbolTable);
  end match;
end translateModelXML;


public function translateGraphics "function: translates the graphical annotations from old to new version"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  output FCore.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable) :=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg)
    local
      FCore.Graph env;
      list<GlobalScript.InstantiatedClass> ic;
      GlobalScript.SymbolTable st;
      Absyn.Program p;
      list<GlobalScript.Variable> iv;
      list<GlobalScript.CompiledCFunction> cf;
      Absyn.Msg msg;
      FCore.Cache cache;
      list<GlobalScript.LoadedFile> lf;
      String errorMsg,retStr,s1;
      Absyn.Class cls, refactoredClass;
      Absyn.Within within_;
      Absyn.Program p1;
      Boolean strEmpty;

    case (cache,_,_,(GlobalScript.SYMBOLTABLE(p as Absyn.PROGRAM(),_,ic,iv,cf,lf)),_)
      equation
        cls = Interactive.getPathedClassInProgram(className, p);
        refactoredClass = Refactor.refactorGraphicalAnnotation(p, cls);
        within_ = Interactive.buildWithin(className);
        p1 = Interactive.updateProgram(Absyn.PROGRAM({refactoredClass}, within_), p);
        s1 = Absyn.pathString(className);
        retStr=stringAppendList({"Translation of ",s1," successful.\n"});
      then
        (cache,Values.STRING(retStr),GlobalScript.SYMBOLTABLE(p1,NONE(),ic,iv,cf,lf));

    case (cache,_,_,st,_)
      equation
        errorMsg = Error.printMessagesStr(false);
        strEmpty = (stringCompare("",errorMsg)==0);
        errorMsg = if strEmpty then "Internal error, translating graphics to new version" else errorMsg;
      then
        (cache,Values.STRING(errorMsg),st);
  end matchcontinue;
end translateGraphics;


protected function calculateSimulationSettings " author: x02lucpo
 calculates the start,end,interval,stepsize, method and initFileName"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Values.Value> vals;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      Absyn.Msg msg;
      FCore.Cache cache;
      String cflags,simflags;
    case (cache,_,{Values.CODE(Absyn.C_TYPENAME(_)),starttime_v,stoptime_v,Values.INTEGER(interval_i),tolerance_v,Values.STRING(method_str),_,Values.STRING(options_str),Values.STRING(outputFormat_str),Values.STRING(variableFilter_str),Values.STRING(cflags),Values.STRING(_)},
         (GlobalScript.SYMBOLTABLE()),_)
      equation
        starttime_r = ValuesUtil.valueReal(starttime_v);
        stoptime_r = ValuesUtil.valueReal(stoptime_v);
        tolerance_r = ValuesUtil.valueReal(tolerance_v);
        outSimSettings = SimCodeMain.createSimulationSettings(starttime_r,stoptime_r,interval_i,tolerance_r,method_str,options_str,outputFormat_str,variableFilter_str,cflags);
      then
        (cache, outSimSettings);
    else
      equation
        s = "CevalScript.calculateSimulationSettings failed: " + ValuesUtil.valString(Values.TUPLE(vals));
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
    case (lst, _, _, _)
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
  outProg := match(inClassName, inDirection, inProg)
    local
      Absyn.Path c, parent;
      Absyn.Program p;
      list<Absyn.Class>  cls;
      Absyn.Within       w;
      String name;
      Absyn.Class parentparentClass;

    case (Absyn.FULLYQUALIFIED(c), _, _)
      equation
        p = moveClass(c, inDirection, inProg);
      then
        p;

    case (Absyn.IDENT(name), _, p as Absyn.PROGRAM())
      equation
        p.classes = moveClassInList(name, p.classes, inDirection);
      then p;

    case (Absyn.QUALIFIED(_, _), _, p)
      equation
        parent = Absyn.stripLast(inClassName);
        _ = Interactive.getPathedClassInProgram(parent, p);
      then
        p;

  end match;
end moveClass;

protected function moveClassInList
  input String inClassName;
  input list<Absyn.Class> inCls;
  input String inDirection;
  output list<Absyn.Class> outCls;
algorithm
  outCls := inCls;
end moveClassInList;

protected function copyClass
  input Absyn.Class inClass;
  input String inName;
  input Absyn.Within inWithin;
  input Absyn.Program inProg;
  output Absyn.Program outProg;
algorithm
  outProg := match(inClass, inName, inWithin, inProg)
    local
      Absyn.Within within_;
      Absyn.Program p, newp;
      String name, newName;
      Boolean partialPrefix,finalPrefix,encapsulatedPrefix;
      Absyn.Restriction restriction;
      Absyn.ClassDef classDef;
    case (Absyn.CLASS(partialPrefix = partialPrefix,finalPrefix = finalPrefix,encapsulatedPrefix = encapsulatedPrefix,restriction = restriction,
          body = classDef), newName, within_, p)
      equation
        newp = Interactive.updateProgram(Absyn.PROGRAM({Absyn.CLASS(newName, partialPrefix, finalPrefix, encapsulatedPrefix, restriction, classDef, Absyn.dummyInfo)},
                                         within_), p);
      then newp;
  end match;
end copyClass;

protected function buildModel "translates and builds the model by running compiler script on the generated makefile"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Values.Value> inValues;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      SimCode.SimulationSettings simSettings;
      Values.Value starttime,stoptime,interval,tolerance,method,options,outputFormat,variableFilter;
      list<Values.Value> vals, values;
      Absyn.Msg msg;
      FCore.Cache cache;
      Boolean existFile;

    // compile the model
    case (cache,env,vals,st,msg)
      equation
        // buildModel expects these arguments:
        // className, startTime, stopTime, numberOfIntervals, tolerance, method, fileNamePrefix,
        // options, outputFormat, variableFilter, cflags, simflags
        values = vals;
        (Values.CODE(Absyn.C_TYPENAME(classname)),vals) = getListFirstShowError(vals, "while retreaving the className (1 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the startTime (2 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the stopTime (3 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the numberOfIntervals (4 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the tolerance (5 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the method (6 arg) from the buildModel arguments");
        (Values.STRING(filenameprefix),vals) = getListFirstShowError(vals, "while retreaving the fileNamePrefix (7 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the options (8 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the outputFormat (9 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the variableFilter (10 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the cflags (11 arg) from the buildModel arguments");
        (Values.STRING(simflags),vals) = getListFirstShowError(vals, "while retreaving the simflags (12 arg) from the buildModel arguments");

        Error.clearMessages() "Clear messages";
        compileDir = System.pwd() + System.pathDelimiter();
        (cache,simSettings) = calculateSimulationSettings(cache, env, values, st, msg);
        SimCode.SIMULATION_SETTINGS(method = method_str, outputFormat = outputFormat_str)
           = simSettings;

        (cache,st as GlobalScript.SYMBOLTABLE(),_,libs,file_dir,resultValues) = translateModel(cache,env, classname, st, filenameprefix,true, SOME(simSettings));
        //cname_str = Absyn.pathString(classname);
        //SimCodeUtil.generateInitData(indexed_dlow_1, classname, filenameprefix, init_filename,
        //  starttime_r, stoptime_r, interval_r, tolerance_r, method_str,options_str,outputFormat_str);

        System.realtimeTick(ClockIndexes.RT_CLOCK_BUILD_MODEL);
        init_filename = filenameprefix + "_init.xml"; //a hack ? should be at one place somewhere
        //win1 = getWithinStatement(classname);

        if Flags.isSet(Flags.DYN_LOAD) then
          Debug.traceln("buildModel: about to compile model " + filenameprefix + ", " + file_dir);
        end if;
        CevalScript.compileModel(filenameprefix, libs);
        if Flags.isSet(Flags.DYN_LOAD) then
          Debug.trace("buildModel: Compiling done.\n");
        end if;
        // p = setBuildTime(p,classname);
        st2 = st;// Interactive.replaceSymbolTableProgram(st,p);
        timeCompile = System.realtimeTock(ClockIndexes.RT_CLOCK_BUILD_MODEL);
        resultValues = ("timeCompile",Values.REAL(timeCompile)) :: resultValues;
      then
        (cache,st2,compileDir,filenameprefix,method_str,outputFormat_str,init_filename,simflags,resultValues);

    // failure
    else
      equation
        Error.assertion(listLength(inValues) == 12, "buildModel failure, length = " + intString(listLength(inValues)), Absyn.dummyInfo);
      then fail();
  end matchcontinue;
end buildModel;

protected function createSimulationResultFromcallModelExecutable
"This function calls the compiled simulation executable."
  input Integer callRet;
  input Real timeTotal;
  input Real timeSimulation;
  input list<tuple<String,Values.Value>> resultValues;
  input FCore.Cache inCache;
  input Absyn.Path className;
  input list<Values.Value> inVals;
  input GlobalScript.SymbolTable inSt;
  input String result_file;
  input String logFile;
  output FCore.Cache outCache;
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
        newst = GlobalScriptUtil.addVarToSymboltable(
          DAE.CREF_IDENT("currentSimulationResult", DAE.T_STRING_DEFAULT, {}),
          Values.STRING(result_file), FGraph.empty(), inSt);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Values.Value> vals;
  input GlobalScript.SymbolTable inSt;
  input Absyn.Msg inMsg;
  output FCore.Cache outCache;
  output String scriptFile;
  output GlobalScript.SymbolTable outSt;
algorithm
  (outCache,scriptFile,outSt):= match(inCache,inEnv,vals,inSt,inMsg)
    local
      String templateFile, str;
      Absyn.Program p;
      Absyn.Path className;
      FCore.Cache cache;
      DAE.DAElist dae;
      FCore.Graph env;
      BackendDAE.BackendDAE dlow;
      DAE.FunctionTree funcs;
      GlobalScript.SymbolTable st;
      Boolean showFlatModelica;
      String filenameprefix,description;

    case(cache,_,{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(templateFile),Values.BOOL(showFlatModelica)},GlobalScript.SYMBOLTABLE(ast=p),_)
      equation
        (cache,env,dae,_) = runFrontEnd(cache,inEnv,className,inSt,false);
        //print("instantiated class\n");
        dae = DAEUtil.transformationsBeforeBackend(cache,env,dae);
        funcs = FCore.getFunctionTree(cache);
        if showFlatModelica then
          print(DAEDump.dumpStr(dae, funcs));
        end if;
        // get all the variable names with a distribution
        // TODO FIXME
        // sort all variable names in the distribution order
        // TODO FIXME
        filenameprefix = Absyn.pathString(className);
        description = DAEUtil.daeDescription(dae);
        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        //print("lowered class\n");
        //print("calling generateOpenTurnsInterface\n");
        scriptFile = OpenTURNS.generateOpenTURNSInterface(dlow, className, p, templateFile);
      then
        (cache,scriptFile,inSt);

  end match;
end buildOpenTURNSInterface;

protected function runOpenTURNSPythonScript
"runs OpenTURNS with the given python script returning the log file"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Values.Value> vals;
  input GlobalScript.SymbolTable inSt;
  input Absyn.Msg inMsg;
  output FCore.Cache outCache;
  output String outLogFile;
  output GlobalScript.SymbolTable outSt;
algorithm
  (outCache,outLogFile,outSt):= match(inCache,inEnv,vals,inSt,inMsg)
    local
      String pythonScriptFile, logFile;
      FCore.Cache cache;
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
      String filename,pd,dir_1,omhome,omhome_1;
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
    case (_,_)
      equation
        omhome = Settings.getInstallationDirectoryPath() "model not yet saved! change to $OPENMODELICAHOME/work" ;
        omhome_1 = System.trim(omhome, "\"");
        pd = System.pathDelimiter();
        dir_1 = stringAppendList({"\"",omhome_1,pd,"work","\""});
      then
        dir_1;
    else "";  /* this function should never fail */
  end matchcontinue;
end getFileDir;

public function checkModel " checks a model and returns number of variables and equations"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  output FCore.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable) :=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg)
    local
      DAE.DAElist dae;
      FCore.Graph env;
      GlobalScript.SymbolTable st;
      Absyn.Program p;
      Absyn.Msg msg;
      FCore.Cache cache;
      Integer eqnSize,varSize,simpleEqnSize;
      String errorMsg,eqnSizeStr,varSizeStr,retStr,classNameStr,simpleEqnSizeStr;
      Boolean strEmpty;
      Absyn.Restriction restriction;
      Absyn.Class c;

    // handle normal models
    case (cache,env,_,(st as GlobalScript.SYMBOLTABLE()),_)
      equation
        (cache,env,dae,st) = runFrontEnd(cache,env,className,st,false);

        (varSize,eqnSize,simpleEqnSize) = CheckModel.checkModel(dae);
        eqnSizeStr = intString(eqnSize);
        varSizeStr = intString(varSize);
        simpleEqnSizeStr = intString(simpleEqnSize);

        classNameStr = Absyn.pathString(className);
        retStr = stringAppendList({"Check of ",classNameStr," completed successfully.","\nClass ",classNameStr," has ",eqnSizeStr," equation(s) and ",
          varSizeStr," variable(s).\n",simpleEqnSizeStr," of these are trivial equation(s)."});
      then
        (cache,Values.STRING(retStr),st);

    // handle functions
    case (cache,env,_,(st as GlobalScript.SYMBOLTABLE(ast = p)),_)
      equation
        (Absyn.CLASS(restriction=restriction)) = Interactive.getPathedClassInProgram(className, p);
        true = Absyn.isFunctionRestriction(restriction) or Absyn.isPackageRestriction(restriction);
        (cache,env,_,st) = runFrontEnd(cache,env,className,st,true);
        classNameStr = Absyn.pathString(className);
      then
        (cache,Values.STRING(""),st);

    case (cache,_,_,st as GlobalScript.SYMBOLTABLE(ast=p), _)
      equation
        classNameStr = Absyn.pathString(className);
        false = Interactive.existClass(Absyn.pathToCref(className), p);
        Error.addMessage(Error.LOOKUP_ERROR, {classNameStr,"<TOP>"});
      then
        (cache,Values.STRING(""),st);

    // errors
    case (cache,_,_,st,_)
      equation
        classNameStr = Absyn.pathString(className);
        strEmpty = Error.getNumMessages() == 0;
        errorMsg = "Check of " + classNameStr + " failed with no error message";
        if strEmpty then
          Error.addMessage(Error.INTERNAL_ERROR, {errorMsg,"<TOP>"});
        end if;
      then
        (cache,Values.STRING(""),st);

  end matchcontinue;
end checkModel;

protected function selectIfNotEmpty
  input String inString;
  input String selector " ";
  output String outString;
algorithm
  outString := match(inString, selector)
    local
      String s;

    case (_, "") then "";

    else
      equation
        s = inString + selector;
      then s;
  end match;
end selectIfNotEmpty;

protected function getWithinStatement "To get a correct Within-path with unknown input-path."
  input Absyn.Path ip;
  output Absyn.Within op;
algorithm op :=  matchcontinue(ip)
  local Absyn.Path path;
    case(path) equation path = Absyn.stripLast(path); then Absyn.WITHIN(path);
    else Absyn.TOP();
  end matchcontinue;
end getWithinStatement;

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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inClassName;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output DAE.DAElist outDae;
algorithm
  (outCache, outEnv, outDae) := match(inCache, inEnv, inClassName, inInteractiveSymbolTable)
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

  end match;
end dumpXMLDAEFrontEnd;

protected function dumpXMLDAE " author: fildo
 This function outputs the DAE system corresponding to a specific model."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Values.Value> vals;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  output FCore.Cache outCache;
  output GlobalScript.SymbolTable outInteractiveSymbolTable3;
  output String xml_filename;
algorithm
  (outCache,outInteractiveSymbolTable3,xml_filename) :=
  matchcontinue (inCache,inEnv,vals,inInteractiveSymbolTable,inMsg)
    local
      String cname_str,filenameprefix,compileDir,rewriteRulesFile,description;
      FCore.Graph env;
      Absyn.Path classname;
      Absyn.Program p;
      BackendDAE.BackendDAE dlow,dlow_1,indexed_dlow;
      FCore.Cache cache;
      Boolean addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals;
      GlobalScript.SymbolTable st;
      Absyn.Msg msg;
      DAE.DAElist dae_1,dae;
      list<SCode.Element> p_1;

    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="flat"),
                     Values.BOOL(addOriginalIncidenceMatrix),Values.BOOL(addSolvingInfo),
                     Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),
                     Values.STRING(filenameprefix),Values.STRING(rewriteRulesFile)},st,_)
      equation
        Error.clearMessages() "Clear messages";

        // set the rewrite rules flag
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, rewriteRulesFile);
        // load the rewrite rules
        RewriteRules.loadRules();

        (cache, env, dae) = dumpXMLDAEFrontEnd(cache, env, classname, st);
        description = DAEUtil.daeDescription(dae);

        compileDir = System.pwd() + System.pathDelimiter();
        cname_str = Absyn.pathString(classname);
        filenameprefix = if filenameprefix == "<default>" then cname_str else filenameprefix;

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
        compileDir = if Config.getRunningTestsuite() then "" else compileDir;

        // clear the rewrite rules!
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, "");
        RewriteRules.clearRules();
      then
        (cache,st,stringAppendList({compileDir,xml_filename}));

    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="optimiser"),
                     Values.BOOL(addOriginalIncidenceMatrix),Values.BOOL(addSolvingInfo),
                     Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),
                     Values.STRING(filenameprefix),Values.STRING(rewriteRulesFile)},(st as GlobalScript.SYMBOLTABLE()),_)
      equation
        //asInSimulationCode==false => it's NOT necessary to do all the translation's steps before dumping with xml
        Error.clearMessages() "Clear messages";

        // set the rewrite rules flag
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, rewriteRulesFile);
        // load the rewrite rules
        RewriteRules.loadRules();

        (cache, env, dae) = dumpXMLDAEFrontEnd(cache, env, classname, st);
        description = DAEUtil.daeDescription(dae);

        compileDir = System.pwd() + System.pathDelimiter();
        cname_str = Absyn.pathString(classname);
        filenameprefix = if filenameprefix == "<default>" then cname_str else filenameprefix;

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
        compileDir = if Config.getRunningTestsuite() then "" else compileDir;

        // clear the rewrite rules!
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, "");
        RewriteRules.clearRules();
      then
        (cache,st,stringAppendList({compileDir,xml_filename}));

    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="backEnd"),
                     Values.BOOL(addOriginalIncidenceMatrix),Values.BOOL(addSolvingInfo),
                     Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),
                     Values.STRING(filenameprefix),Values.STRING(rewriteRulesFile)},(st as GlobalScript.SYMBOLTABLE()),_)
      equation
        //asInSimulationCode==true => it's necessary to do all the translation's steps before dumping with xml
        Error.clearMessages() "Clear messages";

        // set the rewrite rules flag
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, rewriteRulesFile);
        // load the rewrite rules
        RewriteRules.loadRules();

        (cache, env, dae) = dumpXMLDAEFrontEnd(cache, env, classname, st);
        description = DAEUtil.daeDescription(dae);

        compileDir = System.pwd() + System.pathDelimiter();
        cname_str = Absyn.pathString(classname);
        filenameprefix = if filenameprefix == "<default>" then cname_str else filenameprefix;

        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        indexed_dlow = BackendDAEUtil.getSolvedSystem(dlow,"");
        xml_filename = stringAppendList({filenameprefix,".xml"});

        // apply rewrite rules to the back-end
        indexed_dlow = applyRewriteRulesOnBackend(indexed_dlow);

        Print.clearBuf();
        XMLDump.dumpBackendDAE(indexed_dlow,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,false);
        Print.writeBuf(xml_filename);
        Print.clearBuf();
        compileDir = if Config.getRunningTestsuite() then "" else compileDir;

        // clear the rewrite rules!
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, "");
        RewriteRules.clearRules();
      then
        (cache,st,stringAppendList({compileDir,xml_filename}));

    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="stateSpace"),
                     Values.BOOL(addOriginalIncidenceMatrix),Values.BOOL(addSolvingInfo),
                     Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),
                     Values.STRING(filenameprefix),Values.STRING(rewriteRulesFile)},(st as GlobalScript.SYMBOLTABLE()),_)
      equation
        //asInSimulationCode==true => it's necessary to do all the translation's steps before dumping with xml
        Error.clearMessages() "Clear messages";

        // set the rewrite rules flag
        Flags.setConfigString(Flags.REWRITE_RULES_FILE, rewriteRulesFile);
        // load the rewrite rules
        RewriteRules.loadRules();

        (cache, env, dae) = dumpXMLDAEFrontEnd(cache, env, classname, st);
        description = DAEUtil.daeDescription(dae);

        compileDir = System.pwd() + System.pathDelimiter();
        cname_str = Absyn.pathString(classname);
        filenameprefix = if filenameprefix == "<default>" then cname_str else filenameprefix;

        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        indexed_dlow = BackendDAEUtil.getSolvedSystem(dlow,"");
        xml_filename = stringAppendList({filenameprefix,".xml"});

        // apply rewrite rules to the back-end
        indexed_dlow = applyRewriteRulesOnBackend(indexed_dlow);

        Print.clearBuf();
        XMLDump.dumpBackendDAE(indexed_dlow,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,true);
        Print.writeBuf(xml_filename);
        Print.clearBuf();
        compileDir = if Config.getRunningTestsuite() then "" else compileDir;

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
      FCore.Cache cache;
      FCore.Graph env;

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

    case (_,_,Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH())),_)
      equation
      then
        {};

    case (_,_,Absyn.CLASS(body = Absyn.OVERLOAD(_, _)),_)
      equation
      then {};

    case (_,_,Absyn.CLASS(body = Absyn.ENUMERATION(_, _)),_)
      equation
      then {};

    case (_,_,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts=parts)),b)
      equation
        strlist = Interactive.getClassnamesInParts(parts,b);
      then strlist;

    case (_,_,Absyn.CLASS(body = Absyn.PDER(_,_,_)),_)
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
    else
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className;
  input Boolean inCheckProtected;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  output FCore.Cache outCache;
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
      FCore.Cache cache;
      String ret;
      FCore.Graph env;
      Boolean b;

    case (cache,env,_,b,(st as GlobalScript.SYMBOLTABLE(ast = p)),msg)
      equation
        allClassPaths = getAllClassPathsRecursive(className, b, p);
        print("Number of classes to check: " + intString(listLength(allClassPaths)) + "\n");
        // print ("All paths: \n" + stringDelimitList(List.map(allClassPaths, Absyn.pathString), "\n") + "\n");
        checkAll(cache, env, allClassPaths, st, msg);
        ret = "Number of classes checked: " + intString(listLength(allClassPaths));
      then
        (cache,Values.STRING(ret),st);

    case (cache,_,_,_,(st as GlobalScript.SYMBOLTABLE()),_)
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
    else "FAILED!";
  end matchcontinue;
end failOrSuccess;

function checkAll
"@author adrpo
 checks all models and returns number of variables and equations"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
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
      FCore.Cache cache;
      String  str, s;
      FCore.Graph env;
      Real t1, t2, elapsedTime;
      Absyn.ComponentRef cr;
      Absyn.Class c;
    case (_,_,{},_,_) then ();

    case (cache,env,className::rest,(st as GlobalScript.SYMBOLTABLE(ast = p)),msg)
      equation
        c = Interactive.getPathedClassInProgram(className, p);
        // filter out partial classes
        // Absyn.CLASS(partialPrefix = false) = c; // do not filter partial classes
        // filter out packages
        false = Interactive.isPackage(className, p);
        // filter out functions
        // false = Interactive.isFunction(cr, p);
        // filter out types
        false = Interactive.isType(className, p);
        print("Checking: " + Dump.unparseClassAttributesStr(c) + " " + Absyn.pathString(className) + "... ");
        t1 = clock();
        Flags.setConfigBool(Flags.CHECK_MODEL, true);
        (_,Values.STRING(str),_) = checkModel(FCore.emptyCache(), env, className, st, msg);
        Flags.setConfigBool(Flags.CHECK_MODEL, false);
        (_,Values.STRING(str),_) = checkModel(FCore.emptyCache(), env, className, st, msg);
        t2 = clock();
        elapsedTime = t2 - t1;
        s = realString(elapsedTime);
        print (s + " seconds -> " + failOrSuccess(str) + "\n\t");
        print (System.stringReplace(str, "\n", "\n\t"));
        print ("\n");
        checkAll(cache, env, rest, st, msg);
      then
        ();

    case (cache,env,className::rest,(st as GlobalScript.SYMBOLTABLE(ast = p)),msg)
      equation
        c = Interactive.getPathedClassInProgram(className, p);
        print("Checking skipped: " + Dump.unparseClassAttributesStr(c) + " " + Absyn.pathString(className) + "... \n");
        checkAll(cache, env, rest, st, msg);
      then
        ();
  end matchcontinue;
end checkAll;

public function buildModelBeast " copy & pasted by: Otto
 translates and builds the model by running compiler script on the generated makefile"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Values.Value> vals;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Absyn.Msg inMsg;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      Values.Value starttime,stoptime,interval,method,tolerance,options;
      Absyn.Msg msg;
      Absyn.Within win1;
      FCore.Cache cache;
      SimCode.SimulationSettings simSettings;

    // normal call
    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),_,_,_,_, _,Values.STRING(filenameprefix),_},(st as GlobalScript.SYMBOLTABLE(ast = p  as Absyn.PROGRAM())),msg)
      equation
        _ = Interactive.getPathedClassInProgram(classname,p);
        Error.clearMessages() "Clear messages";
        compileDir = System.pwd() + System.pathDelimiter();
        (cache,simSettings) = calculateSimulationSettings(cache,env,vals,st,msg);
        (cache,st,_,libs,file_dir,_)
          = translateModel(cache,env, classname, st, filenameprefix,true,SOME(simSettings));
        SimCode.SIMULATION_SETTINGS() = simSettings;
        //cname_str = Absyn.pathString(classname);
        //(cache,init_filename,starttime_r,stoptime_r,interval_r,tolerance_r,method_str,options_str,outputFormat_str)
        //= calculateSimulationSettings(cache,env, exp, st, msg, cname_str);
        //SimCodeUtil.generateInitData(indexed_dlow_1, classname, filenameprefix, init_filename, starttime_r, stoptime_r, interval_r,tolerance_r,method_str,options_str,outputFormat_str);
        if Flags.isSet(Flags.DYN_LOAD) then
          Debug.traceln("buildModel: about to compile model " + filenameprefix + ", " + file_dir);
        end if;
        CevalScript.compileModel(filenameprefix, libs);
        if Flags.isSet(Flags.DYN_LOAD) then
          Debug.trace("buildModel: Compiling done.\n");
        end if;
        // SimCodegen.generateMakefileBeast(makefilename, filenameprefix, libs, file_dir);
        _ = getWithinStatement(classname);
        CevalScript.compileModel(filenameprefix, libs);
        // (p as Absyn.PROGRAM(globalBuildTimes=Absyn.TIMESTAMP(r1,r2))) = Interactive.updateProgram2(p2,p,false);
        st2 = st; // Interactive.replaceSymbolTableProgram(st,p);
      then
        (cache,st2,compileDir,filenameprefix,"","");

    // failure
    else
      then
        fail();
  end match;
end buildModelBeast;

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
    case Absyn.CLASS(body = Absyn.DERIVED()) then {};
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
    case ((cp as Absyn.ALGORITHMS()) :: xs)
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
    case Absyn.CLASS(body = Absyn.DERIVED()) then {};
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
    case ((cp as Absyn.INITIALALGORITHMS()) :: xs)
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
    case Absyn.CLASS(body = Absyn.DERIVED()) then 0;
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
    case (Absyn.ALGORITHMITEM() :: xs)
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
    case ((Absyn.ALGORITHMS(contents = algs) :: _),n)
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
      SourceInfo inf;
      list<Absyn.AlgorithmItem> xs;
      Integer newn,n;
    case ((Absyn.ALGORITHMITEM(algorithm_ = alg, comment = cmt, info = inf) :: _), 1)
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
    case Absyn.CLASS(body = Absyn.DERIVED()) then 0;
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
    case ((Absyn.INITIALALGORITHMS(contents = algs) :: _),n)
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
    case Absyn.CLASS(body = Absyn.DERIVED()) then {};
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
    case ((cp as Absyn.EQUATIONS()) :: xs)
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
    case Absyn.CLASS(body = Absyn.DERIVED()) then {};
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
    case ((cp as Absyn.INITIALEQUATIONS()) :: xs)
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
    case Absyn.CLASS(body = Absyn.DERIVED()) then 0;
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
    case (Absyn.EQUATIONITEM() :: xs)
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
    case ((Absyn.EQUATIONS(contents = eqs) :: _),n)
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
    case ((Absyn.EQUATIONITEM(equation_ = eq) :: _), 1)
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
    case Absyn.CLASS(body = Absyn.DERIVED()) then 0;
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
    case ((Absyn.INITIALEQUATIONS(contents = eqs) :: _),n)
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
    case Absyn.CLASS(body = Absyn.DERIVED()) then 0;
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
    case Absyn.CLASS(body = Absyn.DERIVED()) then 0;
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
    case (Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.IMPORT())) :: els)
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
    case ((Absyn.PUBLIC(contents = els) :: _),n)
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
    case ((Absyn.PROTECTED(contents = els) :: _),n)
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
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.IMPORT(import_ = import_))) :: _), 1)
      equation
        vals = unparseNthImport(import_);
      then
        vals;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.IMPORT())) :: els), n)
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
        Absyn.CLASS(body = Absyn.DERIVED()) = Interactive.getPathedClassInProgram(path, p);
      then
        true;
    else false;
  end matchcontinue;
end isShortDefinition;

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
        p1 = Absyn.PROGRAM({absynClass},Absyn.TOP());
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
    case ({}, _, _, _) then {};
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

protected function saveTotalModel
  input String filename;
  input Absyn.Path classpath;
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSt;
protected
  SCode.Program scodeP;
  String str,str1,str2,str3;
  NFSCodeEnv.Env env;
  SCode.Comment cmt;
algorithm
  (scodeP, outSt) := GlobalScriptUtil.symbolTableToSCode(st);
  (scodeP, env) := NFSCodeFlatten.flattenClassInProgram(classpath, scodeP);
  (NFSCodeEnv.CLASS(cls=SCode.CLASS(cmt=cmt)),_,_) := NFSCodeLookup.lookupClassName(classpath, env, Absyn.dummyInfo);
  scodeP := SCode.removeBuiltinsFromTopScope(scodeP);
  str := SCodeDump.programStr(scodeP,SCodeDump.defaultOptions);
  str1 := Absyn.pathLastIdent(classpath) + "_total";
  str2 := SCodeDump.printCommentStr(cmt);
  str2 := if stringEq(str2,"") then "" else (" " + str2);
  str3 := SCodeDump.printAnnotationStr(cmt,SCodeDump.defaultOptions);
  str3 := if stringEq(str3,"") then "" else (str3 + ";\n");
  str1 := "\nmodel " + str1 + str2 + "\n  extends " + Absyn.pathString(classpath) + ";\n" + str3 + "end " + str1 + ";\n";
  System.writeFile(filename, str + str1);
end saveTotalModel;

protected function getClassInformation
"author: PA
  Returns all the possible class information.
  changed by adrpo 2006-02-24 (latest 2006-03-14) to return more info and in a different format:
  {\"restriction\",\"comment\",\"filename.mo\",{bool,bool,bool},{\"readonly|writable\",int,int,int,int}}
  if you like more named attributes, use getClassAttributes API which uses get_class_attributes function
  change by sjoelund.se 2014-11-14 to actually be sane. Using the typed API.
  "
  input Absyn.Path path;
  input Absyn.Program p;
  output Values.Value res_1;
protected
  String name,file,strPartial,strFinal,strEncapsulated,res,cmt,str_readonly,str_sline,str_scol,str_eline,str_ecol;
  String dim_str,lastIdent;
  Boolean partialPrefix,finalPrefix,encapsulatedPrefix,isReadOnly,isProtectedClass,isDocClass;
  Absyn.Restriction restr;
  Absyn.ClassDef cdef;
  Integer sl,sc,el,ec;
  Absyn.Path classPath;
algorithm
  Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restr,cdef,SOURCEINFO(file,isReadOnly,sl,sc,el,ec,_)) := Interactive.getPathedClassInProgram(path, p);
  res := Dump.unparseRestrictionStr(restr);
  cmt := getClassComment(cdef);
  file := Util.testsuiteFriendly(file);
  if Absyn.pathIsIdent(Absyn.makeNotFullyQualified(path)) then
    isProtectedClass := false;
  else
    lastIdent := Absyn.pathLastIdent(Absyn.makeNotFullyQualified(path));
    classPath := Absyn.stripLast(path);
    isProtectedClass := Interactive.isProtectedClass(classPath, lastIdent, p);
  end if;
  isDocClass := Interactive.getDocumentationClassAnnotation(path, p);
  res_1 := Values.TUPLE({
    Values.STRING(res),
    Values.STRING(cmt),
    Values.BOOL(partialPrefix),
    Values.BOOL(finalPrefix),
    Values.BOOL(encapsulatedPrefix),
    Values.STRING(file),
    Values.BOOL(isReadOnly),
    Values.INTEGER(sl),
    Values.INTEGER(sc),
    Values.INTEGER(el),
    Values.INTEGER(ec),
    getClassDimensions(cdef),
    Values.BOOL(isProtectedClass),
    Values.BOOL(isDocClass)
  });
end getClassInformation;

function getClassDimensions
"return the dimensions of a class
 as vector of dimension sizes in a string.
 Note: A class can only have dimensions if it is a short class definition."
  input Absyn.ClassDef cdef;
  output Values.Value v;
algorithm
  v := match cdef
    local
      Absyn.ArrayDim ad;
    case(Absyn.DERIVED(typeSpec=Absyn.TPATH(arrayDim=SOME(ad))))
      then ValuesUtil.makeArray(list(Values.STRING(Dump.printSubscriptStr(d)) for d in ad));
    else ValuesUtil.makeArray({});
  end match;
end getClassDimensions;

function getClassComment "Returns the class comment of a Absyn.ClassDef"
  input Absyn.ClassDef inClassDef;
  output String outString;
algorithm
  outString:=
  matchcontinue (inClassDef)
    local
      String str,res;
      Option<Absyn.Comment> cmt;
    case (Absyn.PARTS(comment = SOME(str))) then str;
    case (Absyn.DERIVED(comment = cmt))
      then Interactive.getStringComment2(cmt);
    case (Absyn.ENUMERATION(comment = cmt))
      then Interactive.getStringComment2(cmt);
    case (Absyn.ENUMERATION(comment = cmt))
      then Interactive.getStringComment2(cmt);
    case (Absyn.OVERLOAD(comment = cmt))
      then Interactive.getStringComment2(cmt);
    case (Absyn.CLASS_EXTENDS(comment = SOME(str))) then str;
    else "";
  end matchcontinue;
end getClassComment;

function getComponentInfo
  input Absyn.Element comp;
  input FCore.Graph inEnv;
  input Boolean isProtected;
  output list<Values.Value> vs;
algorithm
  vs := match comp
    local
      SCode.Element c;
      Absyn.Path envpath, p_1, p;
      String tpname, typename, inout_str, variability_str, dir_str, access, name, comment;
      String typeAdStr;
      Boolean r_1, b;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.ElementAttributes attr;
      Option<Absyn.ArrayDim> typeAd;
      FCore.Graph env;
      list<String> dims, dims1;
      Absyn.ArrayDim subs;
      Absyn.ElementSpec spec;

    case Absyn.ELEMENT(specification = spec as Absyn.COMPONENTS(attributes = attr as Absyn.ATTR(),typeSpec = Absyn.TPATH(p, _)))
      algorithm
        typename := matchcontinue ()
          case ()
            equation
              (_,_,env) = Lookup.lookupClass(FCore.emptyCache(), inEnv, p, NONE());
              SOME(envpath) = FGraph.getScopePath(env);
              tpname = Absyn.pathLastIdent(p);
              p_1 = Absyn.joinPaths(envpath, Absyn.IDENT(tpname));
            then Absyn.pathString(p_1);
          else Absyn.pathString(p);
        end matchcontinue;
        vs := {};

        dims1 := list(Dump.printSubscriptStr(sub) for sub in attr.arrayDim);
        r_1 := Interactive.keywordReplaceable(comp.redeclareKeywords);

        inout_str := innerOuterStr(comp.innerOuter);

        variability_str := attrVariabilityStr(attr);
        dir_str := attrDirectionStr(attr);

        for ci in spec.components loop
          (name, comment) := getComponentitemsName(ci);

          dims := match ci
            case Absyn.COMPONENTITEM(component=Absyn.COMPONENT(arrayDim=subs))
              then listAppend(list(Dump.printSubscriptStr(sub) for sub in subs), dims1);
          end match;

          vs := makeGetComponentsRecord(
            className = typename, name = name, comment = comment,
            isProtected=isProtected, isReplaceable=r_1, isFinal=comp.finalPrefix, innerOuter=inout_str, isFlow=attr.flowPrefix,
            isStream=attr.streamPrefix, variability=variability_str, inputOutput=dir_str, dimensions=dims) :: vs;
        end for;
      then vs;
  end match;
end getComponentInfo;

function makeGetComponentsRecord
  input String className;
  input String name;
  input String comment;
  input Boolean isProtected;
  input Boolean isFinal;
  input Boolean isFlow;
  input Boolean isStream;
  input Boolean isReplaceable;
  input String variability;
  input String innerOuter;
  input String inputOutput;
  input list<String> dimensions;
  output Values.Value v;
algorithm
  v := Values.RECORD(
    Absyn.QUALIFIED("OpenModelica", Absyn.QUALIFIED("Scripting", Absyn.QUALIFIED("getComponentsTest", Absyn.IDENT("Component")))),
    {
      Values.STRING(className),
      Values.STRING(name),
      Values.STRING(comment),
      Values.BOOL(isProtected),
      Values.BOOL(isFinal),
      Values.BOOL(isFlow),
      Values.BOOL(isStream),
      Values.BOOL(isReplaceable),
      Values.STRING(variability),
      Values.STRING(innerOuter),
      Values.STRING(inputOutput),
      ValuesUtil.makeArray(list(Values.STRING(s) for s in dimensions))
    },
    {"className","name","comment","isProtected","isFinal","isFlow","isStream","isReplaceable","variability","innerOuter","inputOutput","dimensions"},
    -1
  );
end makeGetComponentsRecord;

function innerOuterStr
"Helper function to getComponentInfo, retrieve the inner outer string."
  input Absyn.InnerOuter inInnerOuter;
  output String outString;
algorithm
  outString:=
  match (inInnerOuter)
    case Absyn.INNER() then "inner";
    case Absyn.OUTER() then "outer";
    case Absyn.NOT_INNER_OUTER() then "";
    case Absyn.INNER_OUTER() then "inner outer";
  end match;
end innerOuterStr;


function attrVariabilityStr
"Helper function to get_component_info,
  retrieve variability as a string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    case (Absyn.ATTR(variability = Absyn.VAR())) then "";
    case (Absyn.ATTR(variability = Absyn.DISCRETE())) then "discrete";
    case (Absyn.ATTR(variability = Absyn.PARAM())) then "parameter";
    case (Absyn.ATTR(variability = Absyn.CONST())) then "constant";
  end match;
end attrVariabilityStr;

function attrDirectionStr
"Helper function to get_component_info,
  retrieve direction as a string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    case (Absyn.ATTR(direction = Absyn.INPUT())) then "input";
    case (Absyn.ATTR(direction = Absyn.OUTPUT())) then "output";
    case (Absyn.ATTR(direction = Absyn.BIDIR())) then "";
  end match;
end attrDirectionStr;

function getComponentitemsName
  " separated list of all component names and comments (if any)."
  input Absyn.ComponentItem ci;
  output String name, comment;
algorithm
  (name, comment) := match ci
    local
      String c1,s2;
    case Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = c1),comment = SOME(Absyn.COMMENT(_,SOME(s2))))
      then (c1, s2);
    case Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = c1),comment = NONE())
      then (c1, "");
  end match;
end getComponentitemsName;

annotation(__OpenModelica_Interface="backend");
end CevalScriptBackend;
