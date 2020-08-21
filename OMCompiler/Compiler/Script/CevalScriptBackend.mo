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
import AbsynUtil;
import AbsynJLDumpTpl;
import BackendDAE;
import Ceval;
import DAE;
import FCore;
import GlobalScript;
import Interactive;
import InteractiveUtil;
import Values;
import SimCode;
import UnitAbsyn;

// protected imports
protected
import AbsynToJulia;
import AbsynToSCode;
import Autoconf;
import BackendDAECreate;
import BackendDAEOptimize;
import BackendDAEUtil;
import BackendDump;
import BackendEquation;
import BackendVariable;
import Binding;
import BlockCallRewrite;
import CevalScript;
import CheckModel;
import ClassInf;
import ClockIndexes;
import CodegenFMU;
import ComponentReference;
import Config;
import DAEDump;
import DAEQuery;
import DAEUtil;
import Debug;
import DiffAlgorithm;
import Dump;
import Error;
import ErrorExt;
import ErrorTypes;
import ExecStat;
import Expression;
import ExpressionDump;
import FBuiltin;
import FGraph;
import FGraphDump;
import Figaro;
import FindZeroCrossings;
import FInst;
import Flags;
import FlagsUtil;
import FMI;
import FMIExt;
import GC;
import Graph;
import HashSetString;
import InnerOuter;
import Inst;
import LexerModelicaDiff;
import List;
import Lookup;
import NFFlatModel;
import NFFlatten;
import NFInst;
import NFSCodeEnv;
import NFSCodeFlatten;
import NFSCodeLookup;
import OpenTURNS;
import PackageManagement;
import Parser;
import Print;
import Refactor;
import RewriteRules;
import SCode;
import SCodeDump;
import SCodeUtil;
import Settings;
import SimCodeMain;
import SimpleModelicaParser;
import SimulationResults;
import StaticScript;
import StringUtil;
import SymbolicJacobian;
import SymbolTable;
import System;
import TaskGraphResults;
import Tpl;
import Types;
import Uncertainties;
import UnitAbsynBuilder;
import UnitParserExt;
import Util;
import ValuesUtil;
import XMLDump;


protected constant DAE.Type simulationResultType_rtest = DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationResult")),{
  DAE.TYPES_VAR("resultFile",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),false,NONE()),
  DAE.TYPES_VAR("simulationOptions",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),false,NONE()),
  DAE.TYPES_VAR("messages",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),false,NONE())
  },NONE());

protected constant DAE.Type simulationResultType_full = DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationResult")),{
  DAE.TYPES_VAR("resultFile",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),false,NONE()),
  DAE.TYPES_VAR("simulationOptions",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),false,NONE()),
  DAE.TYPES_VAR("messages",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),false,NONE()),
  DAE.TYPES_VAR("timeFrontend",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),false,NONE()),
  DAE.TYPES_VAR("timeBackend",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),false,NONE()),
  DAE.TYPES_VAR("timeSimCode",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),false,NONE()),
  DAE.TYPES_VAR("timeTemplates",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),false,NONE()),
  DAE.TYPES_VAR("timeCompile",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),false,NONE()),
  DAE.TYPES_VAR("timeSimulation",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),false,NONE()),
  DAE.TYPES_VAR("timeTotal",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),false,NONE())
  },NONE());

protected constant DAE.Type simulationResultType_drModelica = DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationResult")),{
  DAE.TYPES_VAR("messages",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),false,NONE()),
  DAE.TYPES_VAR("flatteningTime",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),false,NONE()),
  DAE.TYPES_VAR("simulationTime",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),false,NONE())
  },NONE());

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
  t := if Testsuite.isRunning() then simulationResultType_rtest else simulationResultType_full;
end getSimulationResultType;

public function getDrModelicaSimulationResultType
  output DAE.Type t;
algorithm
  t := if Testsuite.isRunning() then simulationResultType_rtest else simulationResultType_drModelica;
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
  notest := not Testsuite.isRunning();
  fields := if notest then List.map(resultValues, Util.tuple21) else {};
  vals := if notest then List.map(resultValues, Util.tuple22) else {};
  res := Values.RECORD(Absyn.IDENT("SimulationResult"),
    Values.STRING(resultFile)::Values.STRING(options)::Values.STRING(message)::vals,
    "resultFile"::"simulationOptions"::"messages"::fields,-1);
end createSimulationResult;

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
  input Absyn.Msg msg;
  output FCore.Cache outCache;
  output String filename;
algorithm
  (outCache,filename) := match (inCache,env,inputFilename,msg)
    local FCore.Cache cache;
    case (cache,_,"<default>",_)
      equation
        (cache,Values.STRING(filename)) = Ceval.ceval(cache,env,buildCurrentSimulationResultExp(),true,msg,0);
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
  input Absyn.Path inModelPath;
  input String inFileNamePrefix;
  input Option<GlobalScript.SimulationOptions> defaultOption;
  output GlobalScript.SimulationOptions outSimOpt;
algorithm
  outSimOpt := matchcontinue (inModelPath, inFileNamePrefix, defaultOption)
    local
      GlobalScript.SimulationOptions defaults, simOpt;
      String experimentAnnotationStr;
      list<Absyn.NamedArg> named;

    // search inside annotation(experiment(...))
    case (_, _, _)
      equation
        defaults = Util.getOptionOrDefault(defaultOption, setFileNamePrefixInSimulationOptions(defaultSimulationOptions, inFileNamePrefix));

        experimentAnnotationStr =
          Interactive.getNamedAnnotation(
            inModelPath,
            SymbolTable.getAbsyn(),
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
  if UseOtimica then
    method := DAE.SCONST("optimization");
  elseif  Flags.getConfigBool(Flags.DAE_MODE) then
    method := DAE.SCONST("ida");
  end if;
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
  input Absyn.Msg msg;
  output FCore.Cache outCache;
  output Values.Value outValue;
protected
  import LexerModelicaDiff.{Token,TokenId,tokenContent,scanString,reportErrors,filterModelicaDiff,modelicaDiffTokenEq,modelicaDiffTokenWhitespace};
  import DiffAlgorithm.{Diff,diff,printActual,printDiffTerminalColor,printDiffXml};
algorithm
  (outCache,outValue) := matchcontinue (inCache,inEnv,inFunctionName,inVals,msg)
    local
      String omdev,simflags,s1,s2,s3,s4,s5,str,str1,str2,str3,str4,token,varid,cmd,executable,executable1,encoding,method_str,
             outputFormat_str,initfilename,pd,executableSuffixedExe,sim_call,result_file,filename_1,filename,
             call,str_1,mp,pathstr,name,cname,errMsg,errorStr,
             title,xLabel,yLabel,filename2,varNameStr,xml_filename,xml_contents,visvar_str,pwd,omhome,omlib,omcpath,os,
             platform,usercflags,senddata,res,workdir,gcc,confcmd,touch_file,uname,filenameprefix,compileDir,libDir,exeDir,configDir,from,to,
             gridStr, logXStr, logYStr, x1Str, x2Str, y1Str, y2Str, curveWidthStr, curveStyleStr, legendPosition, footer, autoScaleStr,scriptFile,logFile, simflags2, outputFile,
             systemPath, gccVersion, gd, strlinearizeTime, suffix,cname, modeldescriptionfilename, tmpDir, tmpFile;
      list<DAE.Exp> simOptions;
      list<Values.Value> vals;
      Absyn.Path path,classpath,className,baseClassPath;
      SCode.Program scodeP,sp;
      FCore.Graph env;
      Absyn.Program p,ip,pnew;
      list<Absyn.Program> newps;
      GlobalScript.SimulationOptions simOpt;
      Real startTime,stopTime,tolerance,reltol,reltolDiffMinMax,rangeDelta;
      DAE.Exp startTimeExp,stopTimeExp,toleranceExp,intervalExp;
      DAE.Type tp, ty;
      list<DAE.Type> tys;
      Absyn.Class absynClass, absynClass2;
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
      Integer size,resI,i,i1,i2,i3,n,curveStyle,numberOfIntervals, status, access;
      Option<Integer> fmiContext, fmiInstance, fmiModelVariablesInstance; /* void* implementation: DO NOT UNBOX THE POINTER AS THAT MIGHT CHANGE IT. Just treat this as an opaque type. */
      Integer fmiLogLevel, direction;
      list<Integer> is;
      list<FMI.TypeDefinitions> fmiTypeDefinitionsList;
      list<FMI.ModelVariables> fmiModelVariablesList;
      FMI.ExperimentAnnotation fmiExperimentAnnotation;
      FMI.Info fmiInfo;
      list<String> vars_1,args,strings,strs,strs1,strs2,visvars,postOptModStrings,postOptModStringsOrg,mps,files,dirs,modifiernamelst;
      Real timeTotal,timeSimulation,timeStamp,val,x1,x2,y1,y2,r,r1,r2,linearizeTime,curveWidth,offset,offset1,offset2,scaleFactor,scaleFactor1,scaleFactor2;
      GlobalScript.Statements istmts;
      list<GlobalScript.Statements> istmtss;
      Boolean have_corba, bval, anyCode, b, b1, b2, b3, b4, b5, externalWindow, logX, logY, autoScale, forceOMPlot, gcc_res, omcfound, rm_res, touch_res, uname_res,  ifcpp, ifmsvc,sort, builtin, showProtected, inputConnectors, outputConnectors, sanityCheckFailed, keepRedeclares;
      FCore.Cache cache;
      Absyn.ComponentRef  crefCName;
      list<tuple<String,Values.Value>> resultValues;
      list<Real> realVals;
      list<tuple<String,list<String>>> deps,depstransitive,depstransposed,depstransposedtransitive,depsmerged,depschanged;
      Absyn.CodeNode codeNode;
      list<Values.Value> cvars,vals2;
      list<Absyn.Path> paths;
      list<Absyn.NamedArg> nargs;
      list<Absyn.Class> classes;
      list<Absyn.ElementArg> eltargs,annlst;
      Absyn.Within within_;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      GlobalScript.SimulationOptions defaulSimOpt;
      SimCode.SimulationSettings simSettings;
      Boolean dumpExtractionSteps, requireExactVersion;
      list<tuple<Absyn.Path,String,list<String>,Boolean>> uses;
      Config.LanguageStandard oldLanguageStd;
      SCode.Element cl;
      list<SCode.Element> cls, elts;
      list<String> names, namesPublic, namesProtected, namesChanged, fileNames;
      HashSetString.HashSet hashSetString;
      list<Boolean> blst;
      list<ErrorTypes.TotalMessage> messages;
      UnitAbsyn.Unit u1,u2;
      Real stoptime,starttime,tol,stepsize,interval;
      String stoptime_str,stepsize_str,starttime_str,tol_str,num_intervalls_str,description,prefix,method,annotationname,modifiername,modifiervalue;
      list<String> interfaceType;
      list<tuple<String,list<String>>> interfaceTypeAssoc;
      list<tuple<String,String>> relocatableFunctionsTuple;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;
      list<list<Values.Value>> valsLst;
      list<Token> tokens1, tokens2, errorTokens;
      list<SimpleModelicaParser.ParseTree> parseTree1, parseTree2;
      list<tuple<Diff, list<Token>>> diffs;
      list<tuple<Diff, list<SimpleModelicaParser.ParseTree>>> treeDiffs;
      SourceInfo info;
      SymbolTable forkedSymbolTable;

    case (cache,_,"runScriptParallel",{Values.ARRAY(valueLst=vals),Values.INTEGER(i),Values.BOOL(true)},_)
      equation
        strs = List.map(vals,ValuesUtil.extractValueString);
        /* One of the few times we can allow to directly manipulate the symbol table
         * Each thread will get a copy of the symbol table and the results will not
         * be stored in the parent.
         */
        forkedSymbolTable = SymbolTable.get();
        blst = System.launchParallelTasks(i, List.map1(strs, Util.makeTuple, forkedSymbolTable), Interactive.evaluateFork);
        v = ValuesUtil.makeArray(List.map(blst, ValuesUtil.makeBoolean));
        SymbolTable.update(forkedSymbolTable);
      then (cache,v);

    case (cache,_,"runScriptParallel",{Values.ARRAY(valueLst=vals),Values.INTEGER(i),Values.BOOL(false)},_)
      equation
        strs = List.map(vals,ValuesUtil.extractValueString);
        strs = List.map1r(strs, stringAppend, stringAppend(Settings.getInstallationDirectoryPath(),"/bin/omc "));
        is = System.systemCallParallel(strs,i);
        v = ValuesUtil.makeArray(List.map(List.map1(is,intEq,0), ValuesUtil.makeBoolean));
      then (cache,v);

    case (cache,_,"runScriptParallel",{Values.ARRAY(valueLst=vals),_,_},_)
      equation
        v = ValuesUtil.makeArray(List.fill(Values.BOOL(false), listLength(vals)));
      then (cache,v);

    case (cache,_,"setClassComment",{Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str)},_)
      equation
        (p,b) = Interactive.setClassComment(path, str, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(b));

    case (cache, _, "isShortDefinition", {Values.CODE(Absyn.C_TYPENAME(path))}, _)
      equation
        b = isShortDefinition(path, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,_,"getUsedClassNames",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        sp = SymbolTable.getSCode();
        (sp, _) = NFSCodeFlatten.flattenClassInProgram(path, sp);
        sp = SCodeUtil.removeBuiltinsFromTopScope(sp);
        paths = Interactive.getSCodeClassNamesRecursive(sp);
        // paths = bcallret2(sort, List.sort, paths, AbsynUtil.pathGe, paths);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then (cache,ValuesUtil.makeArray(vals));

    case (cache,_,"getUsedClassNames",_,_)
      then (cache,ValuesUtil.makeArray({}));

    case (cache,_,"getClassComment",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        Absyn.CLASS(_,_,_,_,_,cdef,_) = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = System.unescapedString(getClassComment(cdef));
      then
        (cache,Values.STRING(str));

    case (cache,_,"getClassComment",{Values.CODE(Absyn.C_TYPENAME(_))},_)
      then
        (cache,Values.STRING(""));

    case (cache,_,"getPackages",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("AllLoadedClasses")))},_)
      equation
        paths = Interactive.getTopPackages(SymbolTable.getAbsyn());
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals));

    case (cache,_,"getPackages",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        paths = Interactive.getPackagesInPath(path, SymbolTable.getAbsyn());
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals));

    case (cache,_,"convertUnits",{Values.STRING(str1),Values.STRING(str2)},_)
      equation
        Error.clearMessages() "Clear messages";
        UnitParserExt.initSIUnits();
        (u1,scaleFactor1,offset1) = UnitAbsynBuilder.str2unitWithScaleFactor(str1,NONE());
        (u2,scaleFactor2,offset2) = UnitAbsynBuilder.str2unitWithScaleFactor(str2,NONE());
        b = valueEq(u1,u2);
        /* How to calculate the final scale factor and offset:
        F = C*1.8 + 32
        C = (F - 32)/1.8 = F/1.8 - 32/1.8
        */
        scaleFactor = realDiv(scaleFactor2, scaleFactor1);
        offset = realDiv(realSub(offset2, offset1), scaleFactor1);
      then
        (cache,Values.TUPLE({Values.BOOL(b),Values.REAL(scaleFactor),Values.REAL(offset)}));

    case (cache,_,"convertUnits",{Values.STRING(_),Values.STRING(_)},_)
      then
        (cache,Values.TUPLE({Values.BOOL(false),Values.REAL(1.0),Values.REAL(0.0)}));

    case (cache,_,"getDerivedUnits",{Values.STRING(str1)},_)
      equation
        Error.clearMessages() "Clear messages";
        UnitParserExt.initSIUnits();
        u1 = UnitAbsynBuilder.str2unit(str1, NONE());
        strs = UnitAbsynBuilder.getDerivedUnits(u1, str1);
        v = ValuesUtil.makeArray(List.map(strs, ValuesUtil.makeString));
      then (cache,v);

    case (cache,_,"getDerivedUnits",{Values.STRING(_)},_)
      then
        (cache,ValuesUtil.makeArray({}));

    case (cache,_,"getClassInformation",{Values.CODE(Absyn.C_TYPENAME(className))},_)
      equation
        v = getClassInformation(className, SymbolTable.getAbsyn());
      then (cache,v);

    case (cache,_,"getClassInformation",_,_)
      then (cache,Values.TUPLE({Values.STRING(""),Values.STRING(""),Values.BOOL(false),Values.BOOL(false),Values.BOOL(false),Values.STRING(""),
                                Values.BOOL(false),Values.INTEGER(0),Values.INTEGER(0),Values.INTEGER(0),Values.INTEGER(0),Values.ARRAY({},{0}),
                                Values.BOOL(false),Values.BOOL(false),Values.STRING(""),Values.STRING(""),Values.BOOL(false),Values.STRING("")}));

    case (cache,_,"getTransitions",{Values.CODE(Absyn.C_TYPENAME(className))},_)
      equation
        cr_1 = AbsynUtil.pathToCref(className);
        false = Interactive.existClass(cr_1, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(className);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then (cache, Values.ARRAY({},{}));

    case (cache,_,"getTransitions",{Values.CODE(Absyn.C_TYPENAME(className))},_)
      equation
        v = getTransitions(className, SymbolTable.getAbsyn());
      then (cache, v);

    case (cache,_,"getTransitions",_,_)
      then (cache, Values.ARRAY({},{}));

    case (cache,_,"addTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_), Values.STRING(_), Values.STRING(_),
                                   Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.INTEGER(_), Values.CODE(Absyn.C_EXPRESSION(_))}, _)
      equation
        cr_1 = AbsynUtil.pathToCref(classpath);
        false = Interactive.existClass(cr_1, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        (cache,Values.BOOL(false));

    case (cache,_,"addTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_), Values.STRING(_), Values.STRING(_),
                                   Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.INTEGER(_),
                                   Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(eqMod=Absyn.NOMOD())))},_)
      equation
        cr_1 = AbsynUtil.pathToCref(classpath);
        false = Interactive.existClass(cr_1, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        (cache,Values.BOOL(false));

    case (cache,_,"addTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1), Values.STRING(str2), Values.STRING(str3),
                                   Values.BOOL(b), Values.BOOL(b1), Values.BOOL(b2), Values.INTEGER(i), Values.CODE(Absyn.C_EXPRESSION(aexp))},_)
      equation
        (bval, p) = Interactive.addTransition(AbsynUtil.pathToCref(classpath), str1, str2, str3, b, b1, b2, i, Absyn.NAMEDARG("annotate",aexp)::{}, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(bval));

    case (cache,_,"addTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1), Values.STRING(str2), Values.STRING(str3),
                                   Values.BOOL(b), Values.BOOL(b1), Values.BOOL(b2), Values.INTEGER(i),
                                   Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(elementArgLst=eltargs,eqMod=Absyn.NOMOD())))},_)
      equation
        (bval, p) = Interactive.addTransitionWithAnnotation(AbsynUtil.pathToCref(classpath), str1, str2, str3, b, b1, b2, i, Absyn.ANNOTATION(eltargs), SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(bval));

    case (cache,_,"addTransition",{_,_,_,_,_,_,_,_,_},_)
      then
        (cache,Values.BOOL(false));

    case (cache,_,"deleteTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_), Values.STRING(_), Values.STRING(_),
                                      Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.INTEGER(_)},_)
      equation
        cr_1 = AbsynUtil.pathToCref(classpath);
        false = Interactive.existClass(cr_1, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        (cache,Values.BOOL(false));

    case (cache,_,"deleteTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1), Values.STRING(str2), Values.STRING(str3),
                                      Values.BOOL(b), Values.BOOL(b1), Values.BOOL(b2), Values.INTEGER(i)},_)
      equation
        (bval, p) = Interactive.deleteTransition(AbsynUtil.pathToCref(classpath), str1, str2, str3, b, b1, b2, i, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(bval));

    case (cache,_,"deleteTransition",{_,_,_,_,_,_,_,_},_)
      then
        (cache,Values.BOOL(false));

    case (cache,_,"updateTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_), Values.STRING(_), Values.STRING(_),
                                      Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.INTEGER(_), Values.STRING(_),
                                      Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.INTEGER(_), Values.CODE(Absyn.C_EXPRESSION(_))},_)
      equation
        cr_1 = AbsynUtil.pathToCref(classpath);
        false = Interactive.existClass(cr_1, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        (cache,Values.BOOL(false));

    case (cache,_,"updateTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_), Values.STRING(_), Values.STRING(_),
                                      Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.INTEGER(_), Values.STRING(_),
                                      Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.INTEGER(_),
                                      Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(eqMod=Absyn.NOMOD())))},_)
      equation
        cr_1 = AbsynUtil.pathToCref(classpath);
        false = Interactive.existClass(cr_1, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        (cache,Values.BOOL(false));

    case (cache,_,"updateTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1), Values.STRING(str2), Values.STRING(str3),
                                      Values.BOOL(b), Values.BOOL(b1), Values.BOOL(b2), Values.INTEGER(i), Values.STRING(str4),
                                      Values.BOOL(b3), Values.BOOL(b4), Values.BOOL(b5), Values.INTEGER(i1), Values.CODE(Absyn.C_EXPRESSION(aexp))},_)
      equation
        (bval, p) = Interactive.deleteTransition(AbsynUtil.pathToCref(classpath), str1, str2, str3, b, b1, b2, i, SymbolTable.getAbsyn());
        (bval, p) = Interactive.addTransition(AbsynUtil.pathToCref(classpath), str1, str2, str4, b3, b4, b5, i1, Absyn.NAMEDARG("annotate",aexp)::{}, p);
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(bval));

    case (cache,_,"updateTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1), Values.STRING(str2), Values.STRING(str3),
                                      Values.BOOL(b), Values.BOOL(b1), Values.BOOL(b2), Values.INTEGER(i), Values.STRING(str4),
                                      Values.BOOL(b3), Values.BOOL(b4), Values.BOOL(b5), Values.INTEGER(i1),
                                      Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(elementArgLst=eltargs,eqMod=Absyn.NOMOD())))},_)
      equation
        (bval, p) = Interactive.deleteTransition(AbsynUtil.pathToCref(classpath), str1, str2, str3, b, b1, b2, i, SymbolTable.getAbsyn());
        (bval, p) = Interactive.addTransitionWithAnnotation(AbsynUtil.pathToCref(classpath), str1, str2, str4, b3, b4, b5, i1, Absyn.ANNOTATION(eltargs), p);
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(bval));

    case (cache,_,"updateTransition",_,_)
      then
        (cache,Values.BOOL(false));

    case (cache,_,"getInitialStates",{Values.CODE(Absyn.C_TYPENAME(className))},_)
      equation
        cr_1 = AbsynUtil.pathToCref(className);
        false = Interactive.existClass(cr_1, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(className);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then (cache, Values.ARRAY({},{}));

    case (cache,_,"getInitialStates",{Values.CODE(Absyn.C_TYPENAME(className))},_)
      equation
        v = getInitialStates(className, SymbolTable.getAbsyn());
      then (cache, v);

    case (cache,_,"getInitialStates",_,_)
      then (cache, Values.ARRAY({},{}));

    case (cache,_,"addInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_), Values.CODE(Absyn.C_EXPRESSION(_))},_)
      equation
        cr_1 = AbsynUtil.pathToCref(classpath);
        false = Interactive.existClass(cr_1, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        (cache,Values.BOOL(false));

    case (cache,_,"addInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_),
                                     Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(eqMod=Absyn.NOMOD())))},_)
      equation
        cr_1 = AbsynUtil.pathToCref(classpath);
        false = Interactive.existClass(cr_1, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        (cache,Values.BOOL(false));

    case (cache,_,"addInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1), Values.CODE(Absyn.C_EXPRESSION(aexp))},_)
      equation
        (bval, p) = addInitialState(classpath, str1, Absyn.NAMEDARG("annotate",aexp)::{}, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(bval));

    case (cache,_,"addInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1),
                                     Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(elementArgLst=eltargs,eqMod=Absyn.NOMOD())))},_)
      equation
        (bval, p) = addInitialStateWithAnnotation(classpath, str1, Absyn.ANNOTATION(eltargs), SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(bval));

    case (cache,_,"addInitialState",{_,_,_},_)
      then
        (cache,Values.BOOL(false));

    case (cache,_,"deleteInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_)},_)
      equation
        cr_1 = AbsynUtil.pathToCref(classpath);
        false = Interactive.existClass(cr_1, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        (cache,Values.BOOL(false));

    case (cache,_,"deleteInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1)},_)
      equation
        (bval, p) = deleteInitialState(classpath, str1, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(bval));

    case (cache,_,"deleteInitialState",_,_)
      then
        (cache,Values.BOOL(false));

    case (cache,_,"updateInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_), Values.CODE(Absyn.C_EXPRESSION(_))},_)
      equation
        cr_1 = AbsynUtil.pathToCref(classpath);
        false = Interactive.existClass(cr_1, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        (cache,Values.BOOL(false));

    case (cache,_,"updateInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_),
                                        Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(eqMod=Absyn.NOMOD())))},_)
      equation
        cr_1 = AbsynUtil.pathToCref(classpath);
        false = Interactive.existClass(cr_1, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        (cache,Values.BOOL(false));

    case (cache,_,"updateInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1), Values.CODE(Absyn.C_EXPRESSION(aexp))},_)
      equation
        (bval, p) = deleteInitialState(classpath, str1, SymbolTable.getAbsyn());
        (bval, p) = addInitialState(classpath, str1, Absyn.NAMEDARG("annotate",aexp)::{}, p);
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(bval));

    case (cache,_,"updateInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1),
                                        Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(elementArgLst=eltargs,eqMod=Absyn.NOMOD())))},_)
      equation
        (bval, p) = deleteInitialState(classpath, str1, SymbolTable.getAbsyn());
        (bval, p) = addInitialStateWithAnnotation(classpath, str1, Absyn.ANNOTATION(eltargs), p);
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(bval));

    case (cache,_,"updateInitialState",_,_)
      then
        (cache,Values.BOOL(false));

    case (cache,_,"diffModelicaFileListings",{Values.STRING(s1),Values.STRING(s2),Values.ENUM_LITERAL(name=path)},_)
      algorithm
        ExecStat.execStatReset();

        (tokens1, errorTokens) := scanString(s1);
        reportErrors(errorTokens);

        if false and s1<>stringAppendList(list(tokenContent(t) for t in tokens1)) then
          // Debugging code. Make sure the scanner works before debugging the diff.
          System.writeFile("string.before", s1);
          System.writeFile("string.after", stringAppendList(list(tokenContent(t) for t in tokens1)));
          Error.assertion(false, "Lexed string does not match the original. See files string.before and string.after", sourceInfo());
          fail();
        end if;

        ExecStat.execStat("diffModelicaFileListings scan string 1");
        (_,parseTree1) := SimpleModelicaParser.stored_definition(tokens1, {});
        ExecStat.execStat("diffModelicaFileListings parse string 1");

        if false and s1<>SimpleModelicaParser.parseTreeStr(parseTree1) then
          // Debugging code. Make sure the parser works before debugging the diff.
          System.writeFile("string.before", s1);
          System.writeFile("string.after", SimpleModelicaParser.parseTreeStr(parseTree1));
          Error.assertion(false, "Parsed string does not match the original. See files string.before and string.after", sourceInfo());
          fail();
        end if;

        tokens2 := scanString(s2);
        reportErrors(errorTokens);
        ExecStat.execStat("diffModelicaFileListings scan string 2");
        (_,parseTree2) := SimpleModelicaParser.stored_definition(tokens2, {});
        ExecStat.execStat("diffModelicaFileListings parse string 2");

        if false and s2<>SimpleModelicaParser.parseTreeStr(parseTree2) then
          // Debugging code. Make sure the parser works before debugging the diff.
          System.writeFile("string.before", s2);
          System.writeFile("string.after", SimpleModelicaParser.parseTreeStr(parseTree2));
          Error.assertion(false, "Parsed string does not match the original. See files string.before and string.after", sourceInfo());
          fail();
        end if;

        treeDiffs := SimpleModelicaParser.treeDiff(parseTree1, parseTree2, max(listLength(tokens1),listLength(tokens2)));

        ExecStat.execStat("treeDiff");

        sanityCheckFailed := false;

        if true then
          // Do a sanity check
          s3 := Dump.unparseStr(Parser.parsestring(s2));
          ExecStat.execStat("sanity parsestring(s2)");
          s5 := printActual(treeDiffs, SimpleModelicaParser.parseTreeNodeStr);
          try
            s4 := Dump.unparseStr(Parser.parsestring(s5));
            ExecStat.execStat("sanity parsestring(s5)");
          else
            System.writeFile("SanityCheckFail.mo", s5);
            Error.addInternalError("Failed to parse merged string (see generated file SanityCheckFail.mo)\n", sourceInfo());
            fail();
          end try;
          if not StringUtil.equalIgnoreSpace(s3, s4) then
            Error.addInternalError("After merging the strings, the semantics changed for some reason (will simply return s2):\ns1:\n"+s1+"\ns2:\n"+s2+"\ns3:\n"+s3+"\ns4:\n"+s4+"\ns5:\n"+s5, sourceInfo());
            sanityCheckFailed := true;
          end if;
        end if;

        /*
        diffs := diff(tokens1, tokens2, modelicaDiffTokenEq, modelicaDiffTokenWhitespace, tokenContent);
        ExecStat.execStat("diffModelicaFileListings diff 1");
        // print("Before filtering:\n"+printDiffTerminalColor(diffs, tokenContent)+"\n");
        diffs := filterModelicaDiff(diffs,removeWhitespace=false);
        ExecStat.execStat("diffModelicaFileListings filter diff 1");
        // Scan a second time, with comments filtered into place
        str := printActual(diffs, tokenContent);
        // print("Intermediate string:\n"+printDiffTerminalColor(diffs, tokenContent)+"\n");
        tokens2 := scanString(str);
        ExecStat.execStat("diffModelicaFileListings prepare pass 2");
        diffs := diff(tokens1, tokens2, modelicaDiffTokenEq, modelicaDiffTokenWhitespace, tokenContent);
        ExecStat.execStat("diffModelicaFileListings diff 2");
        // print("Before filtering (2):\n"+printDiffTerminalColor(diffs, tokenContent)+"\n");
        diffs := filterModelicaDiff(diffs);
        ExecStat.execStat("diffModelicaFileListings filter diff 2");
        */
        str := if sanityCheckFailed then s2 else matchcontinue AbsynUtil.pathLastIdent(path)
          case "plain" then printActual(treeDiffs, SimpleModelicaParser.parseTreeNodeStr);
          case "color" then printDiffTerminalColor(treeDiffs, SimpleModelicaParser.parseTreeNodeStr);
          case "xml" then printDiffXml(treeDiffs, SimpleModelicaParser.parseTreeNodeStr);
          else
            algorithm
              Error.addInternalError("Unknown diffModelicaFileListings choice", sourceInfo());
            then fail();
        end matchcontinue;
      then (cache,Values.STRING(str));

    case (cache,_,"diffModelicaFileListings",_,_) then (cache,Values.STRING(""));

  // exportToFigaro cases added by Alexander Carlqvist
    case (cache, _, "exportToFigaro", {Values.CODE(Absyn.C_TYPENAME(path)), Values.STRING(s1), Values.STRING(str), Values.STRING(str1), Values.STRING(str2), Values.STRING(str3)}, _)
      equation
        scodeP = SymbolTable.getSCode();
        /* The following line of code should be commented out when building from trunk.
        Uncomment when bootstrapping. */
        Figaro.run(scodeP, path, s1, str, str1, str2, str3);
      then (cache, Values.BOOL(true));

    case (cache, _, "exportToFigaro", _, _)
      then (cache, Values.BOOL(false));

    case (cache,_, "inferBindings", {Values.CODE(Absyn.C_TYPENAME(classpath))}, _)
       equation
        pnew = Binding.inferBindings(classpath, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(pnew);
      then
         (cache,Values.BOOL(true));

    case (cache, _, "inferBindings", _, _)
      equation
        print("failed inferBindings\n");
      then (cache, Values.BOOL(false));

     case (cache,_, "generateVerificationScenarios", {Values.CODE(Absyn.C_TYPENAME(classpath))},_)
       equation
        pnew = Binding.generateVerificationScenarios(classpath, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(pnew);
      then (cache,Values.BOOL(true));

    case (cache, _, "generateVerificationScenarios", _, _)
      equation
        print("failed to generateVerificationScenarios\n");
      then (cache, Values.BOOL(false));

    case (_,_, "rewriteBlockCall",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        p = SymbolTable.getAbsyn();
        absynClass = Interactive.getPathedClassInProgram(path, p);
        classes = {absynClass};
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        within_ = Interactive.buildWithin(classpath);
        pnew = BlockCallRewrite.rewriteBlockCall(Absyn.PROGRAM({absynClass}, within_), Absyn.PROGRAM(classes, within_));
        pnew = Interactive.updateProgram(pnew, p);
        SymbolTable.setAbsyn(pnew);
      then
        (FCore.emptyCache(),Values.BOOL(true));

    case (cache, _, "rewriteBlockCall", _, _)
      then (cache, Values.BOOL(false));

    case (cache,env,"jacobian",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        scodeP = SymbolTable.getSCode();
        (cache, env, _, dae) = Inst.instantiateClass(cache, InnerOuter.emptyInstHierarchy, scodeP, path);
        dae  = DAEUtil.transformationsBeforeBackend(cache,env,dae);
        filenameprefix = AbsynUtil.pathString(path);
        description = DAEUtil.daeDescription(dae);
        daelow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        (BackendDAE.DAE({syst},shared)) = BackendDAEUtil.preOptimizeBackendDAE(daelow,NONE());
        (syst,m,_) = BackendDAEUtil.getAdjacencyMatrixfromOption(syst,BackendDAE.NORMAL(),NONE(),BackendDAEUtil.isInitializationDAE(shared));
        vars = BackendVariable.daeVars(syst);
        eqnarr = BackendEquation.getEqnsFromEqSystem(syst);
        (jac, _) = SymbolicJacobian.calculateJacobian(vars, eqnarr, m, false,shared);
        res = BackendDump.dumpJacobianStr(jac);
      then
        (cache,Values.STRING(res));

    case (cache,env,"translateModel",vals as {Values.CODE(Absyn.C_TYPENAME(className)),_,_,_,_,_,Values.STRING(filenameprefix),_,_,_,_,_},_)
      equation
        (cache,simSettings) = calculateSimulationSettings(cache,env,vals,msg);
        (b,cache,_,_,_) = translateModel(cache, env, className, filenameprefix, true, SOME(simSettings));
      then
        (cache,Values.BOOL(b));

    case (cache,_,"translateModel",_,_)
      then (cache,Values.BOOL(false));

    case (cache,env,"modelEquationsUC",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(outputFile),Values.BOOL(dumpExtractionSteps)},_)
      equation
        (cache,ret_val) = Uncertainties.modelEquationsUC(cache, env, className, outputFile,dumpExtractionSteps);
      then
        (cache,ret_val);

    case (cache,_,"modelEquationsUC",_,_)
      then (cache,Values.STRING("There were errors during extraction of uncertainty equations. Use getErrorString() to see them."));

    case (cache,env,"translateModelFMU", Values.CODE(Absyn.C_TYPENAME(className))::Values.STRING(str1)::Values.STRING(str2)::Values.STRING(filenameprefix)::_,_)
      algorithm
        (cache,ret_val) := buildModelFMU(cache, env, className, str1, str2, filenameprefix, true);
      then (cache,ret_val);

    case (cache,_,"translateModelFMU", _,_)
      then (cache,Values.STRING(""));

    case (cache,env,"buildModelFMU", Values.CODE(Absyn.C_TYPENAME(className))::Values.STRING(str1)::Values.STRING(str2)::Values.STRING(filenameprefix)::Values.ARRAY(valueLst=cvars)::_,_)
      algorithm
        (cache,ret_val) := buildModelFMU(cache, env, className, str1, str2, filenameprefix, true, list(ValuesUtil.extractValueString(vv) for vv in cvars));
      then (cache,ret_val);

    case (cache,_,"buildModelFMU", _,_)
      then (cache,Values.STRING(""));

    case (cache,_,"buildEncryptedPackage", {Values.CODE(Absyn.C_TYPENAME(className)),Values.BOOL(b)},_)
      algorithm
        p := SymbolTable.getAbsyn();
        b1 := buildEncryptedPackage(className, b, p);
      then (cache,Values.BOOL(b1));

    case (cache,_,"buildEncryptedPackage",_,_)
      then (cache,Values.BOOL(false));

    case (cache,env,"translateModelXML",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)},_)
      equation
        filenameprefix = Util.stringReplaceChar(filenameprefix,".","_");
        (cache,ret_val) = translateModelXML(cache, env, className, filenameprefix, true, NONE());
      then
        (cache,ret_val);

    case (cache,env,"exportDAEtoMatlab",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)},_)
      equation
        (cache,ret_val,_) = getAdjacencyMatrix(cache,env, className, msg, filenameprefix);
      then
        (cache,ret_val);

    case (cache,env,"checkModel",{Values.CODE(Absyn.C_TYPENAME(className))},_)
      equation
        FlagsUtil.setConfigBool(Flags.CHECK_MODEL, true);
        (cache,ret_val) = checkModel(cache, env, className, msg);
        FlagsUtil.setConfigBool(Flags.CHECK_MODEL, false);
      then
        (cache,ret_val);

    case (cache,env,"checkAllModelsRecursive",{Values.CODE(Absyn.C_TYPENAME(className)),Values.BOOL(showProtected)},_)
      equation
        (cache,ret_val) = checkAllModelsRecursive(cache, env, className, showProtected, msg);
      then
        (cache,ret_val);

    case (cache,_,"translateGraphics",{Values.CODE(Absyn.C_TYPENAME(className))},_)
      then (cache,translateGraphics(className, msg));

    case (cache,_,"setPlotCommand",{Values.STRING(_)},_)
      then
        (cache,Values.BOOL(false));

    case (cache,_,"getLoadedLibraries",{},_)
      algorithm
        p := SymbolTable.getAbsyn();
        v := ValuesUtil.makeArray(List.fold(p.classes,makeLoadLibrariesEntryAbsyn,{}));
      then (cache,v);

    case (cache,_,"OpenModelica_uriToFilename",{Values.STRING(s1)},_)
      equation
        res = OpenModelica.Scripting.uriToFilename(s1);
        if Flags.getConfigBool(Flags.BUILDING_FMU) then
          print("The following path is a loaded resource... "+res+"\n");
          fail();
        end if;
      then (cache,Values.STRING(res));
     /* Note: Only evaluate uriToFilename during scripting. We need simulations to be able to report URI not found */
    case (cache,_,"OpenModelica_uriToFilename",_,_)
      guard not Flags.getConfigBool(Flags.BUILDING_MODEL)
      then (cache,Values.STRING(""));

    case (cache,_,"getAnnotationVersion",{},_)
      equation
        res = Config.getAnnotationVersion();
      then
        (cache,Values.STRING(res));

    case (cache,_,"getNoSimplify",{},_)
      equation
        b = Config.getNoSimplify();
      then
        (cache,Values.BOOL(b));

    case (cache,_,"setNoSimplify",{Values.BOOL(b)},_)
      equation
        Config.setNoSimplify(b);
      then
        (cache,Values.BOOL(true));

    case (cache,_,"getShowAnnotations",{},_)
      equation
        b = Config.showAnnotations();
      then
        (cache,Values.BOOL(b));

    case (cache,_,"setShowAnnotations",{Values.BOOL(b)},_)
      equation
        Config.setShowAnnotations(b);
      then
        (cache,Values.BOOL(true));

    case (cache,_,"getVectorizationLimit",{},_)
      equation
        i = Config.vectorizationLimit();
      then
        (cache,Values.INTEGER(i));

    case (cache,_,"getOrderConnections",{},_)
      equation
        b = Config.orderConnections();
      then
        (cache,Values.BOOL(b));

    case (cache,env,"buildModel", vals as Values.CODE(Absyn.C_TYPENAME(className))::_,_)
      algorithm
        List.map_0(ClockIndexes.buildModelClocks,System.realtimeClear);
        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
        if not Config.simCodeTarget() == "omsic" then
          (b,cache,compileDir,executable,_,_,initfilename,_,_,vals) := buildModel(cache,env, vals, msg);
        else
          filenameprefix := AbsynUtil.pathString(className);
          try
            (cache, Values.STRING(str)) := buildModelFMU(cache, env, className, "2.0", "me", "<default>", true, {"static"});
            if stringEmpty(str) then
              fail();
            end if;
            b := true;
          else
            b := false;
          end try;
          compileDir := System.pwd() + Autoconf.pathDelimiter;
          executable := filenameprefix + "_me_FMU";
          initfilename := filenameprefix + "_init_xml";
        end if;
        executable := if not Testsuite.isRunning() then compileDir + executable else executable;
      then
        (cache,ValuesUtil.makeArray(if b then {Values.STRING(executable),Values.STRING(initfilename)} else {Values.STRING(""),Values.STRING("")}));

    case (cache,_,"buildModel",_,_) /* failing build_model */
      then (cache,ValuesUtil.makeArray({Values.STRING(""),Values.STRING("")}));

    case (cache,env,"buildLabel",vals,_)
      equation
        FlagsUtil.setConfigBool(Flags.GENERATE_LABELED_SIMCODE, true);
        //FlagsUtil.set(Flags.WRITE_TO_BUFFER,true);
        List.map_0(ClockIndexes.buildModelClocks,System.realtimeClear);
        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
        (b,cache,_,executable,_,_,initfilename,_,_,vals) = buildModel(cache,env, vals, msg);
      then
        (cache,ValuesUtil.makeArray(if b then {Values.STRING(executable),Values.STRING(initfilename)} else {Values.STRING(""),Values.STRING("")}));

     case (cache,env,"reduceTerms",vals,_)
      equation
        FlagsUtil.setConfigBool(Flags.REDUCE_TERMS, true);
        // FlagsUtil.setConfigBool(Flags.DISABLE_EXTRA_LABELING, true);
        FlagsUtil.setConfigBool(Flags.GENERATE_LABELED_SIMCODE, false);
        FlagsUtil.disableDebug(Flags.WRITE_TO_BUFFER);
        List.map_0(ClockIndexes.buildModelClocks,System.realtimeClear);
        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);

        if listLength(vals)<>13 then
          Error.addInternalError("reduceTerms expected 13 arguments", sourceInfo());
        end if;
        _ =listGet(vals,13);
        vals=listDelete(vals,13);
        /* labelstoCancel; doesn't do anything */

        (b,cache,_,executable,_,_,initfilename,_,_) = buildModel(cache,env, vals, msg);
      then
        (cache,ValuesUtil.makeArray(if b then {Values.STRING(executable),Values.STRING(initfilename)} else {Values.STRING(""),Values.STRING("")}));
    case(cache,env,"buildOpenTURNSInterface",vals,_)
      equation
        (cache,scriptFile) = buildOpenTURNSInterface(cache,env,vals,msg);
      then
        (cache,Values.STRING(scriptFile));
    case(_,_,"buildOpenTURNSInterface",_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"buildOpenTURNSInterface failed. Use getErrorString() to see why."});
      then
        fail();

    case(cache,env,"runOpenTURNSPythonScript",vals,_)
      equation
        (cache,logFile) = runOpenTURNSPythonScript(cache,env,vals,msg);
      then
        (cache,Values.STRING(logFile));
    case(_,_,"runOpenTURNSPythonScript",_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"runOpenTURNSPythonScript failed. Use getErrorString() to see why"});
      then
        fail();

    // adrpo: see if the model exists before simulation!
    case (cache,_,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,_)
      equation
        crefCName = AbsynUtil.pathToCref(className);
        false = Interactive.existClass(crefCName, SymbolTable.getAbsyn());
        errMsg = "Simulation Failed. Model: " + AbsynUtil.pathString(className) + " does not exist! Please load it first before simulation.";
        simValue = createSimulationResultFailure(errMsg, simOptionsAsString(vals));
      then
        (cache,simValue);

    case (cache,env,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,_)
      algorithm
        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);

        if Config.simCodeTarget() == "omsicpp" then

         filenameprefix := AbsynUtil.pathString(className);
         try
             (cache, Values.STRING(str)) := buildModelFMU(cache, env, className, "2.0", "me", "<default>", true, {"static"});
            if stringEmpty(str) then
              fail();
            end if;
           b := true;
          else
            b := false;
          end try;
          
          compileDir := System.pwd() + Autoconf.pathDelimiter;
          executable := filenameprefix;
          initfilename := filenameprefix + "_init_xml";
          simflags:="";
          resultValues:={};
        elseif not Config.simCodeTarget() == "omsic" then
          (b,cache,compileDir,executable,_,outputFormat_str,_,simflags,resultValues,vals) := buildModel(cache,env,vals,msg);
        else
          Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {"Can't simulate for SimCodeTarget=omsic!\n"});
          fail();
        end if;

        if b then
           exeDir := compileDir;
           (cache,simSettings) := calculateSimulationSettings(cache,env,vals,msg);
           SimCode.SIMULATION_SETTINGS(outputFormat = outputFormat_str) := simSettings;
           result_file := stringAppendList(List.consOnTrue(not Testsuite.isRunning(),compileDir,{executable,"_res.",outputFormat_str}));
            // result file might have been set by simflags (-r ...)

           result_file := selectResultFile(result_file, simflags);

            executableSuffixedExe := stringAppend(executable, getSimulationExtension(Config.simCodeTarget(),Autoconf.platform));
            logFile := stringAppend(executable,".log");
            // adrpo: log file is deleted by buildModel! do NOT DELETE IT AGAIN!
            // we should really have different log files for simulation/compilation!
            // as the buildModel log file will be deleted here and that gives less information to the user!
            if System.regularFileExists(logFile) then
              0 := System.removeFile(logFile);
            end if;
            sim_call := stringAppendList({"\"",exeDir,executableSuffixedExe,"\""," ",simflags});
            System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_SIMULATION);
            SimulationResults.close() "Windows cannot handle reading and writing to the same file from different processes like any real OS :(";

            resI := System.systemCall(sim_call,logFile);

            timeSimulation := System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_SIMULATION);

         else
           result_file := "";
           resI := 1;
           timeSimulation := 0.0;
         end if;

        timeTotal := System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);

        (cache,simValue) := createSimulationResultFromcallModelExecutable(b,resI,timeTotal,timeSimulation,resultValues,cache,className,vals,result_file,logFile);
      then
        (cache,simValue);
    case (cache,_,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,_)
      equation
        Settings.getInstallationDirectoryPath() "simulation fail for some other reason than OPENMODELICAHOME not being set." ;
        str = AbsynUtil.pathString(className);
        res = "Failed to build model: " + str;
        simValue = createSimulationResultFailure(res, simOptionsAsString(vals));
      then
        (cache,simValue);

    case (cache,_,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,_)
      equation
        str = AbsynUtil.pathString(className);
        simValue = createSimulationResultFailure(
          "Simulation failed for model: " + str +
          "\nEnvironment variable OPENMODELICAHOME not set.",
          simOptionsAsString(vals));
      then
        (cache,simValue);

    case (_, _, "moveClass", {Values.CODE(Absyn.C_TYPENAME(className)),
                                  Values.INTEGER(direction)}, _)
      algorithm
        (p, b) := moveClass(className, direction, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        (inCache, Values.BOOL(b));

    case (_, _, "moveClass", _, _) then (inCache, Values.BOOL(false));

    case (_, _, "moveClassToTop", {Values.CODE(Absyn.C_TYPENAME(className))}, _)
      algorithm
        (p, b) := moveClassToTop(className, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        (inCache, Values.BOOL(b));

    case (_, _, "moveClassToTop", _, _) then (inCache, Values.BOOL(false));

    case (_, _, "moveClassToBottom", {Values.CODE(Absyn.C_TYPENAME(className))}, _)
      algorithm
        (p, b) := moveClassToBottom(className, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        (inCache, Values.BOOL(b));

    case (_, _, "moveClassToBottom", _, _) then (inCache, Values.BOOL(false));

    case (cache,_,"copyClass",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(name), Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("TopLevel")))},_)
      equation
        p = SymbolTable.getAbsyn();
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        p = copyClass(absynClass, name, Absyn.TOP(), classpath, p);
        SymbolTable.setAbsyn(p);
        ret_val = Values.BOOL(true);
      then
        (cache,ret_val);

    case (cache,_,"copyClass",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(name), Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        p = SymbolTable.getAbsyn();
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        p = copyClass(absynClass, name, Absyn.WITHIN(path), classpath, p);
        SymbolTable.setAbsyn(p);
        ret_val = Values.BOOL(true);
      then
        (cache,ret_val);

    case (_, _, "copyClass", _, _) then (inCache, Values.BOOL(false));

    case (cache,env,"linearize",(vals as Values.CODE(Absyn.C_TYPENAME(className))::_),_)
      equation

        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);

        (b,cache,compileDir,executable,_,outputFormat_str,_,simflags,resultValues,vals) = buildModel(cache,env,vals,msg);
        if b then
          Values.REAL(linearizeTime) = getListNthShowError(vals,"try to get stop time",0,2);
          executableSuffixedExe = stringAppend(executable, Autoconf.exeExt);
          logFile = stringAppend(executable,".log");
          if System.regularFileExists(logFile) then
            0 = System.removeFile(logFile);
          end if;
          strlinearizeTime = realString(linearizeTime);
          sim_call = stringAppendList({"\"",compileDir,executableSuffixedExe,"\""," ","-l=",strlinearizeTime," ",simflags});
          System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_SIMULATION);
          SimulationResults.close() "Windows cannot handle reading and writing to the same file from different processes like any real OS :(";

          if 0 == System.systemCall(sim_call,logFile) then
            result_file = stringAppendList(List.consOnTrue(not Testsuite.isRunning(),compileDir,{executable,"_res.",outputFormat_str}));
            timeSimulation = System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_SIMULATION);
            timeTotal = System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
            simValue = createSimulationResult(
               result_file,
               simOptionsAsString(vals),
               System.readFile(logFile),
               ("timeTotal", Values.REAL(timeTotal)) ::
               ("timeSimulation", Values.REAL(timeSimulation)) ::
              resultValues);
            SymbolTable.addVar(
              DAE.CREF_IDENT("currentSimulationResult", DAE.T_STRING_DEFAULT, {}),
              Values.STRING(result_file), FGraph.empty());
          else
            res = "Succeeding building the linearized executable, but failed to run the linearize command: " + sim_call + "\n" + System.readFile(logFile);
            simValue = createSimulationResultFailure(res, simOptionsAsString(vals));
          end if;
        else
          timeSimulation = 0.0;
          timeTotal = System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
          simValue = createSimulationResult(
               "",
               simOptionsAsString(vals),
               "Failed to run the linearize command: " + AbsynUtil.pathString(className),
               ("timeTotal", Values.REAL(timeTotal)) ::
               ("timeSimulation", Values.REAL(timeSimulation)) ::
              resultValues);
        end if;
      then
        (cache,simValue);

    case (cache,_,"linearize",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,_)
      equation
        str = AbsynUtil.pathString(className);
        res = "Failed to run the linearize command: " + str;
        simValue = createSimulationResultFailure(res, simOptionsAsString(vals));
     then (cache,simValue);

   case (cache,env,"optimize",(vals as Values.CODE(Absyn.C_TYPENAME(className))::_),_)
      equation

        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);

        FlagsUtil.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION,true);
        FlagsUtil.setConfigEnum(Flags.GRAMMAR, Flags.OPTIMICA);
        FlagsUtil.setConfigBool(Flags.GENERATE_DYN_OPTIMIZATION_PROBLEM,true);

        (b,cache,compileDir,executable,_,outputFormat_str,_,simflags,resultValues,vals) = buildModel(cache,env,vals,msg);
        if b then
          exeDir=compileDir;
          (cache,simSettings) = calculateSimulationSettings(cache,env,vals,msg);
          SimCode.SIMULATION_SETTINGS(outputFormat = outputFormat_str) = simSettings;
          result_file = stringAppendList(List.consOnTrue(not Testsuite.isRunning(),compileDir,{executable,"_res.",outputFormat_str}));
          executableSuffixedExe = stringAppend(executable, getSimulationExtension(Config.simCodeTarget(),Autoconf.platform));
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
        else
          result_file = "";
          timeSimulation = 0.0;
          resI = 1;
        end if;
        timeTotal = System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
        (cache,simValue) = createSimulationResultFromcallModelExecutable(b,resI,timeTotal,timeSimulation,resultValues,cache,className,vals,result_file,logFile);
      then
        (cache,simValue);

    case (cache,_,"optimize",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,_)
      equation
        str = AbsynUtil.pathString(className);
        res = "Failed to run the optimize command: " + str;
        simValue = createSimulationResultFailure(res, simOptionsAsString(vals));
     then (cache,simValue);

    case (_, _, "instantiateModel", {Values.CODE(Absyn.C_TYPENAME(className))}, _)
      then instantiateModel(inCache, inEnv, className);

    case (cache,_,"importFMU",{Values.STRING(filename),Values.STRING(workdir),Values.INTEGER(fmiLogLevel),Values.BOOL(b1), Values.BOOL(b2), Values.BOOL(inputConnectors), Values.BOOL(outputConnectors)},_)
      equation
        Error.clearMessages() "Clear messages";
        true = System.regularFileExists(filename);
        workdir = if System.directoryExists(workdir) then workdir else System.pwd();
        /* Initialize FMI objects */
        (b, fmiContext, fmiInstance, fmiInfo, fmiTypeDefinitionsList, fmiExperimentAnnotation, fmiModelVariablesInstance, fmiModelVariablesList) = FMIExt.initializeFMIImport(filename, workdir, fmiLogLevel, inputConnectors, outputConnectors);
        true = b; /* if something goes wrong while initializing */
        fmiTypeDefinitionsList = listReverse(fmiTypeDefinitionsList);
        fmiModelVariablesList = listReverse(fmiModelVariablesList);
        s1 = System.tolower(Autoconf.platform);
        str = Tpl.tplString(CodegenFMU.importFMUModelica, FMI.FMIIMPORT(s1, filename, workdir, fmiLogLevel, b2, fmiContext, fmiInstance, fmiInfo, fmiTypeDefinitionsList, fmiExperimentAnnotation, fmiModelVariablesInstance, fmiModelVariablesList, inputConnectors, outputConnectors));
        pd = Autoconf.pathDelimiter;
        str1 = FMI.getFMIModelIdentifier(fmiInfo);
        str2 = FMI.getFMIType(fmiInfo);
        str3 = FMI.getFMIVersion(fmiInfo);
        outputFile = stringAppendList({workdir,pd,str1,"_",str2,"_FMU.mo"});
        filename_1 = if b1 then stringAppendList({workdir,pd,str1,"_",str2,"_FMU.mo"}) else stringAppendList({str1,"_",str2,"_FMU.mo"});
        System.writeFile(outputFile, str);
        /* Release FMI objects */
        FMIExt.releaseFMIImport(fmiModelVariablesInstance, fmiInstance, fmiContext, str3);
      then
        (cache,Values.STRING(filename_1));

    case (cache,_,"importFMU",{Values.STRING(filename),Values.STRING(_),Values.INTEGER(_),Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.BOOL(_)},_)
      equation
        false = System.regularFileExists(filename);
        Error.clearMessages() "Clear messages";
        Error.addMessage(Error.FILE_NOT_FOUND_ERROR, {filename});
      then
        (cache,Values.STRING(""));

    case (cache,_,"importFMU",{Values.STRING(_),Values.STRING(_),Values.INTEGER(_),Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.BOOL(_)},_)
      then
        (cache,Values.STRING(""));

    case (cache,_,"importFMUModelDescription",{Values.STRING(filename), Values.STRING(workdir),Values.INTEGER(fmiLogLevel),Values.BOOL(b1), Values.BOOL(b2), Values.BOOL(inputConnectors), Values.BOOL(outputConnectors)},_)
      equation
        Error.clearMessages() "Clear messages";
        true = System.regularFileExists(filename);
        workdir = if System.directoryExists(workdir) then workdir else System.pwd();
        // create a temporary directory
        tmpDir = System.createTemporaryDirectory(Settings.getTempDirectoryPath() + "/" + "fmuTmp" + intString(System.intRand(1000)));
        tmpFile = tmpDir + "/" + "modelDescription.xml";
        System.systemCall("cp -f " + filename + " " + tmpFile);
        modeldescriptionfilename = tmpDir + "/modelDescription.fmu";
        System.systemCall("zip -j " +  modeldescriptionfilename + " " + tmpFile);
        true = System.regularFileExists(modeldescriptionfilename);
        /* Initialize FMI objects */
        (b, fmiContext, fmiInstance, fmiInfo, fmiTypeDefinitionsList, fmiExperimentAnnotation, fmiModelVariablesInstance, fmiModelVariablesList) =
          FMIExt.initializeFMIImport(modeldescriptionfilename, tmpDir, fmiLogLevel, inputConnectors, outputConnectors, true);
        true = b; /* if something goes wrong while initializing */
        fmiTypeDefinitionsList = listReverse(fmiTypeDefinitionsList);
        fmiModelVariablesList = listReverse(fmiModelVariablesList);
        s1 = System.tolower(Autoconf.platform);
        str = Tpl.tplString(CodegenFMU.importFMUModelDescription, FMI.FMIIMPORT(s1, modeldescriptionfilename, workdir, fmiLogLevel, b2, fmiContext, fmiInstance, fmiInfo, fmiTypeDefinitionsList, fmiExperimentAnnotation, fmiModelVariablesInstance, fmiModelVariablesList, inputConnectors, outputConnectors));
        pd = Autoconf.pathDelimiter;
        str1 = FMI.getFMIModelIdentifier(fmiInfo);
        str3 = FMI.getFMIVersion(fmiInfo);
        outputFile = stringAppendList({workdir,pd,str1,"_Input_Output_FMU.mo"});
        filename_1 = if b1 then stringAppendList({workdir,pd,str1,"_Input_Output_FMU.mo"}) else stringAppendList({str1,"_Input_Output_FMU.mo"});
        System.writeFile(outputFile, str);
        /* Release FMI objects */
        FMIExt.releaseFMIImport(fmiModelVariablesInstance, fmiInstance, fmiContext, str3);
        System.removeDirectory(tmpDir);
      then
        (cache,Values.STRING(filename_1));

    case (cache,_,"importFMUModelDescription",{Values.STRING(filename),Values.STRING(_),Values.INTEGER(_),Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.BOOL(_)},_)
      equation
        if not System.regularFileExists(filename) then
          Error.addMessage(Error.FILE_NOT_FOUND_ERROR, {filename});
        end if;
      then
        (cache,Values.STRING(""));

    case (cache,_,"importFMUModelDescription",{Values.STRING(_),Values.STRING(_),Values.INTEGER(_),Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.BOOL(_)},_)
      then
        (cache,Values.STRING(""));

    case (cache,_,"getIndexReductionMethod",_,_)
      equation
        str = Config.getIndexReductionMethod();
      then (cache,Values.STRING(str));

    case (cache,_,"getAvailableIndexReductionMethods",_,_)
      equation
        (strs1,strs2) = FlagsUtil.getConfigOptionsStringList(Flags.INDEX_REDUCTION_METHOD);
        v1 = ValuesUtil.makeArray(List.map(strs1, ValuesUtil.makeString));
        v2 = ValuesUtil.makeArray(List.map(strs2, ValuesUtil.makeString));
        v = Values.TUPLE({v1,v2});
      then (cache,v);

    else then cevalInteractiveFunctions4(inCache,inEnv,inFunctionName,inVals,msg);

 end matchcontinue;
end cevalInteractiveFunctions3;

public function cevalInteractiveFunctions4
"defined in the interactive environment."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String inFunctionName;
  input list<Values.Value> inVals;
  input Absyn.Msg msg;
  output FCore.Cache outCache;
  output Values.Value outValue;
protected
  import LexerModelicaDiff.{Token,TokenId,tokenContent,scanString,reportErrors,filterModelicaDiff,modelicaDiffTokenEq,modelicaDiffTokenWhitespace};
  import DiffAlgorithm.{Diff,diff,printActual,printDiffTerminalColor,printDiffXml};
algorithm
  (outCache,outValue) := matchcontinue (inCache,inEnv,inFunctionName,inVals,msg)
    local
      String omdev,simflags,s1,s2,s3,s4,s5,str,str1,str2,str3,str4,token,varid,cmd,executable,executable1,encoding,method_str,
             outputFormat_str,initfilename,pd,executableSuffixedExe,sim_call,result_file,filename_1,filename,
             call,str_1,mp,pathstr,name,cname,errMsg,errorStr,
             title,xLabel,yLabel,filename2,varNameStr,xml_filename,xml_contents,visvar_str,pwd,omhome,omlib,omcpath,os,
             platform,usercflags,senddata,res,workdir,gcc,confcmd,touch_file,uname,filenameprefix,compileDir,libDir,exeDir,configDir,from,to,
             gridStr, logXStr, logYStr, x1Str, x2Str, y1Str, y2Str, curveWidthStr, curveStyleStr, legendPosition, footer, autoScaleStr,scriptFile,logFile, simflags2, outputFile,
             systemPath, gccVersion, gd, strlinearizeTime, suffix,cname, modeldescriptionfilename, tmpDir, tmpFile;
      list<DAE.Exp> simOptions;
      list<Values.Value> vals;
      Absyn.Path path,classpath,className,baseClassPath;
      SCode.Program scodeP,sp;
      FCore.Graph env;
      Absyn.Program p,ip,pnew,newp;
      list<Absyn.Program> newps;
      GlobalScript.SimulationOptions simOpt;
      Real startTime,stopTime,tolerance,reltol,reltolDiffMinMax,rangeDelta;
      DAE.Exp startTimeExp,stopTimeExp,toleranceExp,intervalExp;
      DAE.Type tp, ty;
      list<DAE.Type> tys;
      Absyn.Class absynClass, absynClass2;
      Absyn.ClassDef cdef;
      Absyn.Exp aexp;
      DAE.DAElist dae;
      Option<DAE.DAElist> odae;
      BackendDAE.BackendDAE daelow,optdae;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqnarr;
      array<list<Integer>> m,mt;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      Values.Value ret_val,simValue,value,v,cvar,cvar2,v1,v2,v3;
      Absyn.ComponentRef cr,cr_1;
      Integer size,resI,i,i1,i2,i3,n,curveStyle,numberOfIntervals, status, access;
      Option<Integer> fmiContext, fmiInstance, fmiModelVariablesInstance; /* void* implementation: DO NOT UNBOX THE POINTER AS THAT MIGHT CHANGE IT. Just treat this as an opaque type. */
      Integer fmiLogLevel, direction;
      list<Integer> is;
      list<FMI.TypeDefinitions> fmiTypeDefinitionsList;
      list<FMI.ModelVariables> fmiModelVariablesList;
      FMI.ExperimentAnnotation fmiExperimentAnnotation;
      FMI.Info fmiInfo;
      list<String> vars_1,args,strings,strs,strs1,strs2,visvars,postOptModStrings,postOptModStringsOrg,mps,files,dirs,modifiernamelst;
      Real timeTotal,timeSimulation,timeStamp,val,x1,x2,y1,y2,r,r1,r2,linearizeTime,curveWidth,offset,offset1,offset2,scaleFactor,scaleFactor1,scaleFactor2;
      GlobalScript.Statements istmts;
      list<GlobalScript.Statements> istmtss;
      Boolean have_corba, bval, anyCode, b, b1, b2, b3, b4, b5, externalWindow, logX, logY, autoScale, forceOMPlot, gcc_res, omcfound, rm_res, touch_res, uname_res,  ifcpp, ifmsvc,sort, builtin, showProtected, inputConnectors, outputConnectors, sanityCheckFailed, keepRedeclares;
      FCore.Cache cache;
      Absyn.ComponentRef  crefCName;
      list<tuple<String,Values.Value>> resultValues;
      list<Real> realVals;
      list<tuple<String,list<String>>> deps,depstransitive,depstransposed,depstransposedtransitive,depsmerged,depschanged;
      Absyn.CodeNode codeNode;
      list<Values.Value> cvars,vals2;
      list<Absyn.Path> paths;
      list<Absyn.NamedArg> nargs;
      list<Absyn.Class> classes;
      list<Absyn.ElementArg> eltargs,annlst;
      Absyn.Within within_;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      GlobalScript.SimulationOptions defaulSimOpt;
      SimCode.SimulationSettings simSettings;
      Boolean dumpExtractionSteps, requireExactVersion;
      list<tuple<Absyn.Path,String,list<String>,Boolean>> uses;
      list<String> withoutConversion, withConversion;
      Config.LanguageStandard oldLanguageStd;
      SCode.Element cl;
      list<SCode.Element> cls, elts;
      list<String> names, namesPublic, namesProtected, namesChanged, fileNames;
      HashSetString.HashSet hashSetString;
      list<Boolean> blst;
      list<ErrorTypes.TotalMessage> messages;
      UnitAbsyn.Unit u1,u2;
      Real stoptime,starttime,tol,stepsize,interval;
      String stoptime_str,stepsize_str,starttime_str,tol_str,num_intervalls_str,description,prefix,method,annotationname,modifiername,modifiervalue;
      list<String> interfaceType;
      list<tuple<String,list<String>>> interfaceTypeAssoc;
      list<tuple<String,String>> relocatableFunctionsTuple;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;
      list<list<Values.Value>> valsLst;
      list<Token> tokens1, tokens2, errorTokens;
      list<SimpleModelicaParser.ParseTree> parseTree1, parseTree2;
      list<tuple<Diff, list<Token>>> diffs;
      list<tuple<Diff, list<SimpleModelicaParser.ParseTree>>> treeDiffs;
      SourceInfo info;
      SymbolTable forkedSymbolTable;

    case (cache,_,"getAvailableIndexReductionMethods",_,_)
      equation
        (strs1,strs2) = FlagsUtil.getConfigOptionsStringList(Flags.INDEX_REDUCTION_METHOD);
        v1 = ValuesUtil.makeArray(List.map(strs1, ValuesUtil.makeString));
        v2 = ValuesUtil.makeArray(List.map(strs2, ValuesUtil.makeString));
        v = Values.TUPLE({v1,v2});
      then (cache,v);

    case (cache,_,"getMatchingAlgorithm",_,_)
      equation
        str = Config.getMatchingAlgorithm();
      then (cache,Values.STRING(str));

    case (cache,_,"getAvailableMatchingAlgorithms",_,_)
      equation
        (strs1,strs2) = FlagsUtil.getConfigOptionsStringList(Flags.MATCHING_ALGORITHM);
        v1 = ValuesUtil.makeArray(List.map(strs1, ValuesUtil.makeString));
        v2 = ValuesUtil.makeArray(List.map(strs2, ValuesUtil.makeString));
        v = Values.TUPLE({v1,v2});
      then (cache,v);

    case (cache,_,"getTearingMethod",_,_)
      equation
        str = Config.getTearingMethod();
      then (cache,Values.STRING(str));

    case (cache,_,"getAvailableTearingMethods",_,_)
      equation
        (strs1,strs2) = FlagsUtil.getConfigOptionsStringList(Flags.TEARING_METHOD);
        v1 = ValuesUtil.makeArray(List.map(strs1, ValuesUtil.makeString));
        v2 = ValuesUtil.makeArray(List.map(strs2, ValuesUtil.makeString));
        v = Values.TUPLE({v1,v2});
      then (cache,v);

    case (cache,_,"saveModel",{Values.STRING(filename),Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      algorithm
        b := false;
        Values.ENUM_LITERAL(index=access) := Interactive.checkAccessAnnotationAndEncryption(classpath, SymbolTable.getAbsyn());
        if (access >= 9) then // i.e., The class is not encrypted.
          absynClass := Interactive.getPathedClassInProgram(classpath, SymbolTable.getAbsyn());
          str := Dump.unparseStr(Absyn.PROGRAM({absynClass},Absyn.TOP()),true);
          try
            System.writeFile(filename, str);
            b := true;
          else
            Error.addMessage(Error.WRITING_FILE_ERROR, {filename});
          end try;
        else
          Error.addMessage(Error.SAVE_ENCRYPTED_CLASS_ERROR, {});
          b := false;
        end if;
      then
        (cache,Values.BOOL(b));

    case (cache,_,"save",{Values.CODE(Absyn.C_TYPENAME(className))},_)
      equation
        Values.ENUM_LITERAL(index=access) = Interactive.checkAccessAnnotationAndEncryption(className, SymbolTable.getAbsyn());
        if (access >= 9) then // i.e., The class is not encrypted.
          (newp,filename) = Interactive.getContainedClassAndFile(className, SymbolTable.getAbsyn());
          str = Dump.unparseStr(newp);
          System.writeFile(filename, str);
          b = true;
        else
          Error.addMessage(Error.SAVE_ENCRYPTED_CLASS_ERROR, {});
          b = false;
        end if;
      then
        (cache,Values.BOOL(b));

    case (cache,_,"save",{Values.CODE(Absyn.C_TYPENAME(_))},_)
    then (cache,Values.BOOL(false));

    case (cache,_,"saveAll",{Values.STRING(filename)},_)
      equation
        str = Dump.unparseStr(SymbolTable.getAbsyn(),true);
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true));

    case (cache,_,"saveModel",{Values.STRING(_),Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        cname = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {cname,"global"});
      then
        (cache,Values.BOOL(false));

    case (cache,_,"saveTotalModel",{Values.STRING(filename),Values.CODE(Absyn.C_TYPENAME(classpath)),
                                    Values.BOOL(b1), Values.BOOL(b2)},_)
      equation
        Values.ENUM_LITERAL(index=access) = Interactive.checkAccessAnnotationAndEncryption(classpath, SymbolTable.getAbsyn());
        if (access >= 9) then // i.e., Access.documentation
          saveTotalModel(filename, classpath, b1, b2);
          b = true;
        else
          Error.addMessage(Error.SAVE_ENCRYPTED_CLASS_ERROR, {});
          b = false;
        end if;
      then
        (cache, Values.BOOL(b));

    case (cache,_,"saveTotalModel",{Values.STRING(_),Values.CODE(Absyn.C_TYPENAME(_)),
                                    Values.BOOL(_), Values.BOOL(_)},_)
      then (cache, Values.BOOL(false));

    case (cache,_,"getDocumentationAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        Values.ENUM_LITERAL(index=access) = Interactive.checkAccessAnnotationAndEncryption(classpath, SymbolTable.getAbsyn());
        if (access >= 3) then // i.e., Access.documentation
          ((str1,str2,str3)) = Interactive.getNamedAnnotation(classpath, SymbolTable.getAbsyn(), Absyn.IDENT("Documentation"), SOME(("","","")),Interactive.getDocumentationAnnotationString);
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          ((str1,str2,str3)) = ("", "", "");
        end if;
      then
        (cache,ValuesUtil.makeArray({Values.STRING(str1),Values.STRING(str2),Values.STRING(str3)}));

    case (cache,_,"addClassAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.CODE(Absyn.C_EXPRESSION(aexp))},_)
      equation
        p = Interactive.addClassAnnotation(AbsynUtil.pathToCref(classpath), Absyn.NAMEDARG("annotate",aexp)::{}, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(true));

    case (cache,_,"addClassAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(elementArgLst=eltargs,eqMod=Absyn.NOMOD())))},_)
      algorithm
        p := SymbolTable.getAbsyn();
        absynClass := Interactive.getPathedClassInProgram(classpath, p);
        absynClass := Interactive.addClassAnnotationToClass(absynClass, Absyn.ANNOTATION(eltargs));
        p := Interactive.updateProgram(Absyn.PROGRAM({absynClass}, if AbsynUtil.pathIsIdent(classpath) then Absyn.TOP() else Absyn.WITHIN(AbsynUtil.stripLast(classpath))), p);
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(true));

    case (cache,_,"addClassAnnotation",_,_)
      then
        (cache,Values.BOOL(false));

    case (cache,_,"setDocumentationAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(str1),Values.STRING(str2)},_)
      equation
        p = SymbolTable.getAbsyn();
        nargs = List.consOnTrue(not stringEq(str1,""), Absyn.NAMEDARG("info",Absyn.STRING(System.escapedString(str1,false))), {});
        nargs = List.consOnTrue(not stringEq(str2,""), Absyn.NAMEDARG("revisions",Absyn.STRING(System.escapedString(str2,false))), nargs);
        aexp = Absyn.CALL(Absyn.CREF_IDENT("Documentation",{}),Absyn.FUNCTIONARGS({},nargs));
        p = Interactive.addClassAnnotation(AbsynUtil.pathToCref(classpath), Absyn.NAMEDARG("annotate",aexp)::{}, p);
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(true));

    case (cache,_,"setDocumentationAnnotation",_,_)
      then
        (cache,Values.BOOL(false));

    case (cache,_,"stat",{Values.STRING(str)},_)
      algorithm
        (b,r1,r2) := System.stat(str);
      then (cache,Values.TUPLE({Values.BOOL(b),Values.REAL(r1),Values.REAL(r2)}));

    case (cache,_,"isType",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        b = Interactive.isType(classpath, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,_,"isPackage",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        b = Interactive.isPackage(classpath, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,_,"isClass",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        b = Interactive.isClass(classpath, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,_,"isRecord",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        b = Interactive.isRecord(classpath, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,_,"isBlock",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        b = Interactive.isBlock(classpath, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,_,"isFunction",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        b = Interactive.isFunction(classpath, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,_,"isPartial",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        b = Interactive.isPartial(classpath, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,_,"isModel",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        b = Interactive.isModel(classpath, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,_,"isConnector",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        b = Interactive.isConnector(classpath, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,_,"isOptimization",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        b = Interactive.isOptimization(classpath, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,_,"isEnumeration",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        b = Interactive.isEnumeration(classpath, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,_,"isOperator",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        b = Interactive.isOperator(classpath, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,_,"isOperatorRecord",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        b = Interactive.isOperatorRecord(classpath, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,_,"isOperatorFunction",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        b = Interactive.isOperatorFunction(classpath, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,_,"isProtectedClass",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(name)},_)
      equation
        b = Interactive.isProtectedClass(classpath, name, SymbolTable.getAbsyn());
      then
        (cache,Values.BOOL(b));

    case (cache,env,"getBuiltinType",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        (_, tp, _) = Lookup.lookupType(cache, env, classpath, SOME(AbsynUtil.dummyInfo));
        str = Types.unparseType(tp);
      then
        (cache,Values.STRING(str));

    // if the lookup fails
    case (cache,_,"getBuiltinType",{Values.CODE(Absyn.C_TYPENAME(_))},_)
      then
        (cache,Values.STRING(""));

    case (cache,_,"extendsFrom",
          {Values.CODE(Absyn.C_TYPENAME(classpath)),
           Values.CODE(Absyn.C_TYPENAME(baseClassPath))},_)
      equation
        paths = Interactive.getAllInheritedClasses(classpath, SymbolTable.getAbsyn());
        b = List.applyAndFold1(paths, boolOr, AbsynUtil.pathSuffixOfr, baseClassPath, false);
      then
        (cache,Values.BOOL(b));

    case (cache,_,"extendsFrom",_,_)
      then
        (cache,Values.BOOL(false));

    case (cache,_,"isExperiment",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        b = Interactive.getNamedAnnotation(classpath, SymbolTable.getAbsyn(), Absyn.IDENT("experiment"), SOME(false), hasStopTime);
      then
        (cache,Values.BOOL(b));

    case (cache,_,"isExperiment",_,_)
      then
        (cache,Values.BOOL(false));

    case (cache,_,"getInheritedClasses",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        paths = Interactive.getInheritedClasses(classpath);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals));

    case (cache,_,"getInheritedClasses",_,_)
      then (cache,ValuesUtil.makeArray({}));

    case (cache,_,"getComponentsTest",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, SymbolTable.getAbsyn());
        sp = SymbolTable.getSCode();
        (cache, env) = Inst.makeEnvFromProgram(sp);
        (cache,(cl as SCode.CLASS(name=name,encapsulatedPrefix=encflag,restriction=restr)),env) = Lookup.lookupClass(cache, env, classpath, NONE());
        env = FGraph.openScope(env, encflag, name, FGraph.restrictionToScopeType(restr));
        (_, env) = Inst.partialInstClassIn(cache, env, InnerOuter.emptyInstHierarchy, DAE.NOMOD(), DAE.NOPRE(),
          ClassInf.start(restr, FGraph.getGraphName(env)), cl, SCode.PUBLIC(), {}, 0);
        valsLst = list(getComponentInfo(c, env, isProtected=false) for c in Interactive.getPublicComponentsInClass(absynClass));
        valsLst = listAppend(list(getComponentInfo(c, env, isProtected=true) for c in Interactive.getProtectedComponentsInClass(absynClass)), valsLst);
      then (cache,ValuesUtil.makeArray(List.flatten(valsLst)));

    case (cache,_,"getComponentsTest",{Values.CODE(Absyn.C_TYPENAME(_))},_)
      then
        (cache,Values.ARRAY({},{}));


    case (cache,_,"getSimulationOptions",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.REAL(startTime),Values.REAL(stopTime),Values.REAL(tolerance),Values.INTEGER(numberOfIntervals),Values.REAL(interval)},_)
      equation
        cr_1 = AbsynUtil.pathToCref(classpath);
        // ignore the name of the model
        ErrorExt.setCheckpoint("getSimulationOptions");
        simOpt = GlobalScript.SIMULATION_OPTIONS(DAE.RCONST(startTime),DAE.RCONST(stopTime),DAE.ICONST(numberOfIntervals),DAE.RCONST(0.0),DAE.RCONST(tolerance),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""));
        ErrorExt.rollBack("getSimulationOptions");
        (_, _::startTimeExp::stopTimeExp::intervalExp::toleranceExp::_) = StaticScript.getSimulationArguments(FCore.emptyCache(), FGraph.empty(), {Absyn.CREF(cr_1)},{},false,DAE.NOPRE(), "getSimulationOptions", AbsynUtil.dummyInfo,SOME(simOpt));
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
        (cache,Values.TUPLE({Values.REAL(startTime), Values.REAL(stopTime), Values.REAL(tolerance), Values.INTEGER(numberOfIntervals), Values.REAL(interval)}));

    case (cache,_,"getAnnotationNamedModifiers",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(annotationname)},_)
      equation
          Absyn.CLASS(body=cdef,info=info) =Interactive.getPathedClassInProgram(classpath,SymbolTable.getAbsyn());
          annlst= getAnnotationList(cdef);
          modifiernamelst=getElementArgsModifiers(annlst,annotationname,AbsynUtil.pathString(classpath),info);
          v1 = ValuesUtil.makeArray(List.map(modifiernamelst, ValuesUtil.makeString));
      then
          (cache,v1);

     case (cache,_,"getAnnotationModifierValue",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(annotationname),Values.STRING(modifiername)},_)
      equation
          Absyn.CLASS(_,_,_,_,_,cdef,_) =Interactive.getPathedClassInProgram(classpath,SymbolTable.getAbsyn());
          annlst= getAnnotationList(cdef);
          modifiervalue=getElementArgsModifiersValue(annlst,annotationname,modifiername);
      then
          (cache,Values.STRING(modifiervalue));

    case (cache,_,"searchClassNames",{Values.STRING(str), Values.BOOL(b)},_)
      equation
        (_,paths) = Interactive.getClassNamesRecursive(NONE(),SymbolTable.getAbsyn(),false,false,{});
        paths = listReverse(paths);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
        vals = searchClassNames(vals, str, b, SymbolTable.getAbsyn());
      then
        (cache,ValuesUtil.makeArray(vals));

    case (cache,_,"getAvailableLibraries",{},_)
      algorithm
        files := PackageManagement.AvailableLibraries.listKeys(PackageManagement.getInstalledLibraries());
        v := ValuesUtil.makeArray(List.map(files, ValuesUtil.makeString));
      then
        (cache,v);

    case (cache,_,"installPackage",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT(str1))), Values.STRING(str2), Values.BOOL(b)},_)
      algorithm
        v := Values.BOOL(PackageManagement.installPackage(str1, str2, b));
      then (cache,v);

    case (cache,_,"installPackage",{Values.CODE(Absyn.C_TYPENAME(path as Absyn.QUALIFIED())), _, _},_)
      algorithm
        Error.addMessage(Error.ERROR_PKG_NOT_IDENT, {AbsynUtil.pathString(path)});
      then (cache, Values.BOOL(false));

    case (cache,_,"installPackage",_,_)
      then (cache, Values.BOOL(false));

    case (cache,_,"updatePackageIndex",{},_)
      algorithm
        v := Values.BOOL(PackageManagement.updateIndex());
      then (cache,v);

    case (cache,_,"upgradeInstalledPackages",{Values.BOOL(b)},_)
      algorithm
        v := Values.BOOL(PackageManagement.upgradeInstalledPackages(b));
      then (cache,v);

    case (cache,_,"getUses",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        (absynClass as Absyn.CLASS()) = Interactive.getPathedClassInProgram(classpath, SymbolTable.getAbsyn());
        uses = Interactive.getUsesAnnotation(Absyn.PROGRAM({absynClass},Absyn.TOP()));
        v = ValuesUtil.makeArray(List.map(uses,makeUsesArray));
      then
        (cache,v);

    case (cache,_,"getConversionsFromVersions",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        (absynClass as Absyn.CLASS()) = Interactive.getPathedClassInProgram(classpath, SymbolTable.getAbsyn());
        (withoutConversion,withConversion) = Interactive.getConversionAnnotation(absynClass);
        v = Values.TUPLE({ValuesUtil.makeArray(List.map(withoutConversion,ValuesUtil.makeString)), ValuesUtil.makeArray(List.map(withConversion,ValuesUtil.makeString))});
      then
        (cache,v);

    case (cache,_,"getDerivedClassModifierNames",{Values.CODE(Absyn.C_TYPENAME(classpath))},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, SymbolTable.getAbsyn());
        args = Interactive.getDerivedClassModifierNames(absynClass);
        vals = List.map(args, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v);

    case (cache,_,"getDerivedClassModifierValue",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_TYPENAME(className))},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, SymbolTable.getAbsyn());
        str = Interactive.getDerivedClassModifierValue(absynClass, className);
      then
        (cache,Values.STRING(str));

    case (cache,_,"getAstAsCorbaString",{Values.STRING("<interactive>")},_)
      equation
        Print.clearBuf();
        Dump.getAstAsCorbaString(SymbolTable.getAbsyn());
        res = Print.getString();
        Print.clearBuf();
      then
        (cache,Values.STRING(res));

    case (cache,_,"getAstAsCorbaString",{Values.STRING(str)},_)
      equation
        Print.clearBuf();
        Dump.getAstAsCorbaString(SymbolTable.getAbsyn());
        Print.writeBuf(str);
        Print.clearBuf();
        str = "Wrote result to file: " + str;
      then
        (cache,Values.STRING(str));

    case (cache,_,"getAstAsCorbaString",_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"getAstAsCorbaString failed"});
      then (cache,Values.STRING(""));

    case (cache,_,"readSimulationResult",{Values.STRING(filename),Values.ARRAY(valueLst=cvars),Values.INTEGER(size)},_)
      equation
        vars_1 = List.map(cvars, ValuesUtil.printCodeVariableName);
        filename_1 = Util.absoluteOrRelative(filename);
        value = SimulationResults.readDataset(filename_1, vars_1, size);
      then
        (cache,value);

    case (cache,_,"readSimulationResult",_,_)
      equation
        Error.addMessage(Error.SCRIPT_READ_SIM_RES_ERROR, {});
      then (cache,Values.META_FAIL());

    case (cache,_,"readSimulationResultSize",{Values.STRING(filename)},_)
      equation
        filename_1 = Util.absoluteOrRelative(filename);
        i = SimulationResults.readSimulationResultSize(filename_1);
      then
        (cache,Values.INTEGER(i));

    case (cache,_,"readSimulationResultVars",{Values.STRING(filename),Values.BOOL(b1),Values.BOOL(b2)},_)
      equation
        filename_1 = Util.absoluteOrRelative(filename);
        args = SimulationResults.readVariables(filename_1, b1, b2);
        vals = List.map(args, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v);

    case (cache,_,"compareSimulationResults",{Values.STRING(filename),Values.STRING(filename_1),Values.STRING(filename2),Values.REAL(x1),Values.REAL(x2),Values.ARRAY(valueLst=cvars)},_)
      equation
        Error.addMessage(Error.DEPRECATED_API_CALL, {"compareSimulationResults", "diffSimulationResults"});
        filename = Util.absoluteOrRelative(filename);
        filename_1 = Testsuite.friendlyPath(filename_1);
        filename_1 = Util.absoluteOrRelative(filename_1);
        filename2 = Util.absoluteOrRelative(filename2);
        vars_1 = List.map(cvars, ValuesUtil.extractValueString);
        strings = SimulationResults.cmpSimulationResults(Testsuite.isRunning(),filename,filename_1,filename2,x1,x2,vars_1);
        cvars = List.map(strings,ValuesUtil.makeString);
        v = ValuesUtil.makeArray(cvars);
      then
        (cache,v);

    case (cache,_,"deltaSimulationResults",{Values.STRING(filename),Values.STRING(filename_1),Values.STRING(method_str),Values.ARRAY(valueLst=cvars)},_)
      equation
        filename = Util.absoluteOrRelative(filename);
        filename_1 = Testsuite.friendlyPath(filename_1);
        filename_1 = Util.absoluteOrRelative(filename_1);
        vars_1 = List.map(cvars, ValuesUtil.extractValueString);
        val = SimulationResults.deltaSimulationResults(filename,filename_1,method_str,vars_1);
      then
        (cache,Values.REAL(val));

    case (cache,_,"deltaSimulationResults",_,_)
      then (cache,Values.STRING("Error in deltaSimulationResults"));


    case (cache,_,"compareSimulationResults",_,_)
      then (cache,Values.STRING("Error in compareSimulationResults"));

    case (cache,_,"filterSimulationResults",{Values.STRING(filename),Values.STRING(filename_1),Values.ARRAY(valueLst=cvars),Values.INTEGER(numberOfIntervals),Values.BOOL(b)},_)
      equation
        vars_1 = List.map(cvars, ValuesUtil.extractValueString);
        b = SimulationResults.filterSimulationResults(filename,filename_1,vars_1,numberOfIntervals,b);
      then
        (cache,Values.BOOL(b));

    case (cache,_,"filterSimulationResults",_,_)
      then (cache,Values.BOOL(false));

    case (cache,_,"diffSimulationResults",{Values.STRING(filename),Values.STRING(filename_1),Values.STRING(filename2),Values.REAL(reltol),Values.REAL(reltolDiffMinMax),Values.REAL(rangeDelta),Values.ARRAY(valueLst=cvars),Values.BOOL(b)},_)
      equation
        filename = Util.absoluteOrRelative(filename);
        filename_1 = Testsuite.friendlyPath(filename_1);
        filename_1 = Util.absoluteOrRelative(filename_1);
        filename2 = Util.absoluteOrRelative(filename2);
        vars_1 = List.map(cvars, ValuesUtil.extractValueString);
        (b,strings) = SimulationResults.diffSimulationResults(Testsuite.isRunning(),filename,filename_1,filename2,reltol,reltolDiffMinMax,rangeDelta,vars_1,b);
        cvars = List.map(strings,ValuesUtil.makeString);
        v1 = ValuesUtil.makeArray(cvars);
      then
        (cache,Values.TUPLE({Values.BOOL(b),v1}));

    case (cache,_,"diffSimulationResults",_,_)
      equation
        v = ValuesUtil.makeArray({});
      then (cache,Values.TUPLE({Values.BOOL(false),v}));

    case (cache,_,"diffSimulationResultsHtml",{Values.STRING(str),Values.STRING(filename),Values.STRING(filename_1),Values.REAL(reltol),Values.REAL(reltolDiffMinMax),Values.REAL(rangeDelta)},_)
      equation
        filename = Util.absoluteOrRelative(filename);
        filename_1 = Testsuite.friendlyPath(filename_1);
        filename_1 = Util.absoluteOrRelative(filename_1);
        str = SimulationResults.diffSimulationResultsHtml(Testsuite.isRunning(),filename,filename_1,reltol,reltolDiffMinMax,rangeDelta,str);
      then
        (cache,Values.STRING(str));

    case (cache,_,"diffSimulationResultsHtml",_,_)
      then (cache,Values.STRING(""));

    case (cache,_,"checkTaskGraph",{Values.STRING(filename),Values.STRING(filename_1)},_)
      equation
        pwd = System.pwd();
        pd = Autoconf.pathDelimiter;
        filename = if System.substring(filename,1,1) == "/" then filename else stringAppendList({pwd,pd,filename});
        filename_1 = if System.substring(filename_1,1,1) == "/" then filename_1 else stringAppendList({pwd,pd,filename_1});
        strings = TaskGraphResults.checkTaskGraph(filename, filename_1);
        cvars = List.map(strings,ValuesUtil.makeString);
        v = ValuesUtil.makeArray(cvars);
      then (cache,v);

    case (cache,_,"checkTaskGraph",_,_)
      then (cache,Values.STRING("Error in checkTaskGraph"));

    case (cache,_,"checkCodeGraph",{Values.STRING(filename),Values.STRING(filename_1)},_)
      equation
        pwd = System.pwd();
        pd = Autoconf.pathDelimiter;
        filename = if System.substring(filename,1,1) == "/" then filename else stringAppendList({pwd,pd,filename});
        filename_1 = if System.substring(filename_1,1,1) == "/" then filename_1 else stringAppendList({pwd,pd,filename_1});
        strings = TaskGraphResults.checkCodeGraph(filename, filename_1);
        cvars = List.map(strings,ValuesUtil.makeString);
        v = ValuesUtil.makeArray(cvars);
      then (cache,v);

    case (cache,_,"checkCodeGraph",_,_)
      then (cache,Values.STRING("Error in checkCodeGraph"));

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
        _)
      equation
        // get OPENMODELICAHOME
        omhome = Settings.getInstallationDirectoryPath();
        // get the simulation filename
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,msg);
        pd = Autoconf.pathDelimiter;
        // create absolute path of simulation result file
        str1 = System.pwd() + pd + filename;
        s1 = if Autoconf.os == "Windows_NT" then ".exe" else "";
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
        (cache,Values.BOOL(true));

    case (cache,_,"plotAll",_,_)
      then (cache,Values.BOOL(false));

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
        _)
      equation
        // get the variables list
        vars_1 = List.map(cvars, ValuesUtil.printCodeVariableName);
        // get OPENMODELICAHOME
        omhome = Settings.getInstallationDirectoryPath();
        // get the simulation filename
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,msg);
        pd = Autoconf.pathDelimiter;
        // create absolute path of simulation result file
        str1 = System.pwd() + pd + filename;
        s1 = if Autoconf.os == "Windows_NT" then ".exe" else "";
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
        (cache,Values.BOOL(true));

    case (cache,_,"plot",_,_)
      then
        (cache,Values.BOOL(false));

    case (cache,env,"val",{cvar,Values.REAL(timeStamp),Values.STRING("<default>")},_)
      equation
        (cache,Values.STRING(filename)) = Ceval.ceval(cache,env,buildCurrentSimulationResultExp(), true, msg, 0);
        varNameStr = ValuesUtil.printCodeVariableName(cvar);
        val = SimulationResults.val(filename,varNameStr,timeStamp);
      then (cache,Values.REAL(val));

    case (cache,_,"val",{cvar,Values.REAL(timeStamp),Values.STRING(filename)},_)
      equation
        false = stringEq(filename,"<default>");
        varNameStr = ValuesUtil.printCodeVariableName(cvar);
        val = SimulationResults.val(filename,varNameStr,timeStamp);
      then (cache,Values.REAL(val));

    case (cache,_,"closeSimulationResultFile",_,_)
      equation
        SimulationResults.close();
      then
        (cache,Values.BOOL(true));

    case (cache,_,"getParameterNames",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        strings = Interactive.getParameterNames(path, SymbolTable.getAbsyn());
        vals = List.map(strings, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v);

    case (cache,_,"getParameterValue",{Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str1)},_)
      equation
        str2 = Interactive.getComponentBinding(path, str1, SymbolTable.getAbsyn());
      then
        (cache,Values.STRING(str2));

    case (cache,_,"getComponentModifierNames",{Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str1)},_)
      equation
        strings = Interactive.getComponentModifierNames(path, str1, SymbolTable.getAbsyn());
        vals = List.map(strings, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v);

    case (cache,_,"getComponentModifierValue",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        cr = AbsynUtil.pathToCref(path);
        if AbsynUtil.crefIsIdent(cr) then
          Absyn.CREF_IDENT(name = s1) = cr;
          str = Interactive.getComponentBinding(classpath, s1, SymbolTable.getAbsyn());
        else
          s1 = AbsynUtil.crefFirstIdent(cr);
          cr_1 = AbsynUtil.crefStripFirst(cr);
          str = Interactive.getComponentModifierValue(AbsynUtil.pathToCref(classpath), Absyn.CREF_IDENT(s1, {}), cr_1, SymbolTable.getAbsyn());
        end if;
      then
        (cache,Values.STRING(str));

    case (cache,_,"getComponentModifierValues",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        cr = AbsynUtil.pathToCref(path);
        if AbsynUtil.crefIsIdent(cr) then
          Absyn.CREF_IDENT(name = s1) = cr;
          str = Interactive.getComponentBinding(classpath, s1, SymbolTable.getAbsyn());
        else
          s1 = AbsynUtil.crefFirstIdent(cr);
          cr_1 = AbsynUtil.crefStripFirst(cr);
          str = Interactive.getComponentModifierValues(AbsynUtil.pathToCref(classpath), Absyn.CREF_IDENT(s1, {}), cr_1, SymbolTable.getAbsyn());
        end if;
      then
        (cache,Values.STRING(str));

    case (cache,_,"removeComponentModifiers",
        Values.CODE(Absyn.C_TYPENAME(path))::
      Values.STRING(str1)::
      Values.BOOL(keepRedeclares)::_,_)
      equation
        (p,b) = Interactive.removeComponentModifiers(path, str1, SymbolTable.getAbsyn(), keepRedeclares);
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(b));

    case (cache,_,"removeExtendsModifiers",
          Values.CODE(Absyn.C_TYPENAME(classpath))::
          Values.CODE(Absyn.C_TYPENAME(baseClassPath))::
      Values.BOOL(keepRedeclares)::_,_)
      equation
        (p,b) = Interactive.removeExtendsModifiers(classpath, baseClassPath, SymbolTable.getAbsyn(), keepRedeclares);
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(b));

    case (cache,env,"getInstantiatedParametersAndValues",{Values.CODE(Absyn.C_TYPENAME(className))},_)
      equation
        (cache,env,odae) = runFrontEnd(cache,env,className,true);
        strings = Interactive.getInstantiatedParametersAndValues(odae);
        vals = List.map(strings, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v);

    case (cache,_,"getInstantiatedParametersAndValues",_,_)
      equation
        Error.addCompilerWarning("getInstantiatedParametersAndValues failed to instantiate the model.");
        v = ValuesUtil.makeArray({});
      then
        (cache,v);

    case (cache,_,"updateConnection",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(str1), Values.STRING(str2),Values.CODE(Absyn.C_EXPRESSION(aexp))},_)
      equation
        p = InteractiveUtil.updateConnectionAnnotation(AbsynUtil.pathToCref(classpath), str1, str2, Absyn.NAMEDARG("annotate",aexp)::{}, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(true));

    case (cache,_,"updateConnection",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(str1), Values.STRING(str2),
                                      Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(elementArgLst=eltargs,eqMod=Absyn.NOMOD())))},_)
      algorithm
        p := SymbolTable.getAbsyn();
        absynClass := Interactive.getPathedClassInProgram(classpath, p);
        absynClass := InteractiveUtil.updateConnectionAnnotationInClass(absynClass, str1, str2, Absyn.ANNOTATION(eltargs));
        p := Interactive.updateProgram(Absyn.PROGRAM({absynClass}, if AbsynUtil.pathIsIdent(classpath) then Absyn.TOP() else Absyn.WITHIN(AbsynUtil.stripLast(classpath))), p);
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(true));

    case (cache,_,"updateConnection",_,_) then (cache,Values.BOOL(false));

    case (cache,_,"updateConnectionNames",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(str1), Values.STRING(str2),
                                           Values.STRING(str3), Values.STRING(str4)},_)
      equation
        (b, p) = InteractiveUtil.updateConnectionNames(classpath, str1, str2, str3, str4, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        (cache,Values.BOOL(b));

    case (cache,_,"updateConnectionNames",_,_) then (cache,Values.BOOL(false));

    case (cache,_,"getConnectionCount",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        Values.ENUM_LITERAL(index=access) = Interactive.checkAccessAnnotationAndEncryption(path, SymbolTable.getAbsyn());
        if (access >= 4) then // i.e., Access.diagram
          n = listLength(Interactive.getConnections(absynClass));
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          n = 0;
        end if;
      then
        (cache,Values.INTEGER(n));

    case (cache,_,"getConnectionCount",_,_) then (cache,Values.INTEGER(0));

    case (cache,_,"getNthConnection",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},_)
      equation
        Values.ENUM_LITERAL(index=access) = Interactive.checkAccessAnnotationAndEncryption(path, SymbolTable.getAbsyn());
        if (access >= 4) then // i.e., Access.diagram
          vals = Interactive.getNthConnection(AbsynUtil.pathToCref(path), SymbolTable.getAbsyn(), n);
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          vals = {};
        end if;
      then
        (cache,ValuesUtil.makeArray(vals));

    case (cache,_,"getNthConnection",_,_) then (cache,ValuesUtil.makeArray({}));

    case (cache,_,"getAlgorithmCount",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = listLength(getAlgorithms(absynClass));
      then
        (cache,Values.INTEGER(n));

    case (cache,_,"getAlgorithmCount",_,_) then (cache,Values.INTEGER(0));

    case (cache,_,"getNthAlgorithm",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthAlgorithm(absynClass, n);
      then
        (cache,Values.STRING(str));

    case (cache,_,"getNthAlgorithm",_,_) then (cache,Values.STRING(""));

    case (cache,_,"getInitialAlgorithmCount",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = listLength(getInitialAlgorithms(absynClass));
      then
        (cache,Values.INTEGER(n));

    case (cache,_,"getInitialAlgorithmCount",_,_) then (cache,Values.INTEGER(0));

    case (cache,_,"getNthInitialAlgorithm",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthInitialAlgorithm(absynClass, n);
      then
        (cache,Values.STRING(str));

    case (cache,_,"getNthInitialAlgorithm",_,_) then (cache,Values.STRING(""));

    case (cache,_,"getAlgorithmItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = getAlgorithmItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n));

    case (cache,_,"getAlgorithmItemsCount",_,_) then (cache,Values.INTEGER(0));

    case (cache,_,"getNthAlgorithmItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthAlgorithmItem(absynClass, n);
      then
        (cache,Values.STRING(str));

    case (cache,_,"getNthAlgorithmItem",_,_) then (cache,Values.STRING(""));

    case (cache,_,"getInitialAlgorithmItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = getInitialAlgorithmItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n));

    case (cache,_,"getInitialAlgorithmItemsCount",_,_) then (cache,Values.INTEGER(0));

    case (cache,_,"getNthInitialAlgorithmItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthInitialAlgorithmItem(absynClass, n);
      then
        (cache,Values.STRING(str));

    case (cache,_,"getNthInitialAlgorithmItem",_,_) then (cache,Values.STRING(""));

    case (cache,_,"getEquationCount",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = listLength(getEquations(absynClass));
      then
        (cache,Values.INTEGER(n));

    case (cache,_,"getEquationCount",_,_) then (cache,Values.INTEGER(0));

    case (cache,_,"getNthEquation",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthEquation(absynClass, n);
      then
        (cache,Values.STRING(str));

    case (cache,_,"getNthEquation",_,_) then (cache,Values.STRING(""));

    case (cache,_,"getInitialEquationCount",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = listLength(getInitialEquations(absynClass));
      then
        (cache,Values.INTEGER(n));

    case (cache,_,"getInitialEquationCount",_,_) then (cache,Values.INTEGER(0));

    case (cache,_,"getNthInitialEquation",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthInitialEquation(absynClass, n);
      then
        (cache,Values.STRING(str));

    case (cache,_,"getNthInitialEquation",_,_) then (cache,Values.STRING(""));

    case (cache,_,"getEquationItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = getEquationItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n));

    case (cache,_,"getEquationItemsCount",_,_) then (cache,Values.INTEGER(0));

    case (cache,_,"getNthEquationItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthEquationItem(absynClass, n);
      then
        (cache,Values.STRING(str));

    case (cache,_,"getNthEquationItem",_,_) then (cache,Values.STRING(""));

    case (cache,_,"getInitialEquationItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = getInitialEquationItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n));

    case (cache,_,"getInitialEquationItemsCount",_,_) then (cache,Values.INTEGER(0));

    case (cache,_,"getNthInitialEquationItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthInitialEquationItem(absynClass, n);
      then
        (cache,Values.STRING(str));

    case (cache,_,"getNthInitialEquationItem",_,_) then (cache,Values.STRING(""));

    case (cache,_,"getAnnotationCount",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = getAnnotationCount(absynClass);
      then
        (cache,Values.INTEGER(n));

    case (cache,_,"getAnnotationCount",_,_) then (cache,Values.INTEGER(0));

    case (cache,_,"getNthAnnotationString",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthAnnotationString(absynClass, n);
      then
        (cache,Values.STRING(str));

    case (cache,_,"getNthAnnotationString",_,_) then (cache,Values.STRING(""));

    case (cache,_,"getImportCount",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = getImportCount(absynClass);
      then
        (cache,Values.INTEGER(n));

    case (cache,_,"getImportCount",_,_) then (cache,Values.INTEGER(0));

    case (cache,_,"getNthImport",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},_)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        vals = getNthImport(absynClass, n);
      then
        (cache,ValuesUtil.makeArray(vals));

    case (cache,_,"getNthImport",_,_) then (cache,ValuesUtil.makeArray({}));

    case (cache,_,"getImportedNames",{Values.CODE(Absyn.C_TYPENAME(path))},_)
      algorithm
        absynClass := Interactive.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        (vals,vals2) := getImportedNames(absynClass);
        v := Values.TUPLE({ValuesUtil.makeArray(vals),ValuesUtil.makeArray(vals2)});
      then
        (cache, v);

    case (cache,_,"getImportedNames",_,_)
      then (cache,Values.TUPLE({ValuesUtil.makeArray({}),ValuesUtil.makeArray({})}));

    case (cache,_,"getMMfileTotalDependencies",{Values.STRING(s1), Values.STRING(s2)},_)
      algorithm
        names := getMMfileTotalDependencies(s1, s2);
        vals := list(Values.STRING(s) for s in names);
      then
        (cache,ValuesUtil.makeArray(vals));

    case (cache,_,"getMMfileTotalDependencies",_,_) then (cache,ValuesUtil.makeArray({}));

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
        _)
      equation
        // get OPENMODELICAHOME
        omhome = Settings.getInstallationDirectoryPath();
        // get the simulation filename
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,msg);
        pd = Autoconf.pathDelimiter;
        // create absolute path of simulation result file
        str1 = System.pwd() + pd + filename;
        s1 = if Autoconf.os == "Windows_NT" then ".exe" else "";
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
        (cache,Values.BOOL(true));

    case (cache,_,"plotParametric",_,_)
      then (cache,Values.BOOL(false));

    case (cache,env,"dumpXMLDAE",vals,_)
      equation
        (cache,xml_filename) = dumpXMLDAE(cache,env,vals, msg);
      then
        (cache,ValuesUtil.makeTuple({Values.BOOL(true),Values.STRING(xml_filename)}));

    case (cache,_,"dumpXMLDAE",_,_)
      then
        (cache,ValuesUtil.makeTuple({Values.BOOL(false),Values.STRING("")}));

    case (cache,_,"solveLinearSystem",{Values.ARRAY(valueLst=vals),v,Values.ENUM_LITERAL(index=1 /*dgesv*/),Values.ARRAY(valueLst={Values.INTEGER(-1)})},_)
      equation
        (realVals,i) = System.dgesv(List.map(vals,ValuesUtil.arrayValueReals),ValuesUtil.arrayValueReals(v));
        v = ValuesUtil.makeArray(List.map(realVals,ValuesUtil.makeReal));
      then (cache,Values.TUPLE({v,Values.INTEGER(i)}));

    case (cache,_,"solveLinearSystem",{Values.ARRAY(valueLst=vals),v,Values.ENUM_LITERAL(index=2 /*lpsolve55*/),Values.ARRAY(valueLst=vals2)},_)
      equation
        (realVals,i) = System.lpsolve55(List.map(vals,ValuesUtil.arrayValueReals),ValuesUtil.arrayValueReals(v),List.map(vals2,ValuesUtil.valueInteger));
        v = ValuesUtil.makeArray(List.map(realVals,ValuesUtil.makeReal));
      then (cache,Values.TUPLE({v,Values.INTEGER(i)}));

    case (cache,_,"solveLinearSystem",{_,v,_,_},_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Unknown input to solveLinearSystem scripting function"});
      then (cache,Values.TUPLE({v,Values.INTEGER(-1)}));

    case (cache,_,"relocateFunctions",{Values.STRING(str), v as Values.ARRAY()},_)
      algorithm
        relocatableFunctionsTuple := {};
        for varr in v.valueLst loop
          Values.ARRAY(valueLst={Values.STRING(s1),Values.STRING(s2)}) := varr;
          relocatableFunctionsTuple := (s1,s2)::relocatableFunctionsTuple;
        end for;
        b := System.relocateFunctions(str, relocatableFunctionsTuple);
      then (cache,Values.BOOL(b));

    case (cache,_,"toJulia",{},_)
      algorithm
        str := Tpl.tplString(AbsynToJulia.dumpProgram, SymbolTable.getAbsyn());
      then (cache,Values.STRING(str));

    case (cache,_,"interactiveDumpAbsynToJL",{},_)
      algorithm
        str := Tpl.tplString(AbsynJLDumpTpl.dump, SymbolTable.getAbsyn());
      then (cache,Values.STRING(str));

    case (cache,_,"relocateFunctions",_,_)
      then (cache,Values.BOOL(false));

 end matchcontinue;
end cevalInteractiveFunctions4;

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
    case ("Cpp","Unix")
       then ".sh";
    case ("omsicpp","WIN64")
     then ".bat";
    case ("omsicpp","WIN32")
       then ".bat";
    case ("omsicpp","Unix")
       then ".sh";
    else Autoconf.exeExt;
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

public function getAdjacencyMatrix " author: adrpo
 translates a model and returns the adjacency matrix"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input Absyn.Msg inMsg;
  input String filenameprefix;
  output FCore.Cache outCache;
  output Values.Value outValue;
  output String outString;
algorithm
  (outCache,outValue,outString):=
  match (inCache,inEnv,className,inMsg,filenameprefix)
    local
      String filename,file_dir, str;
      list<SCode.Element> p_1;
      DAE.DAElist dae_1,dae;
      FCore.Graph env;
      BackendDAE.BackendDAE dlow;
      Absyn.ComponentRef a_cref;
      Absyn.Program p;
      Absyn.Msg msg;
      FCore.Cache cache;
      String flatModelicaStr,description;

    case (cache,env,_,_,_) /* mo file directory */
      equation
        p = SymbolTable.getAbsyn();
        p_1 = SymbolTable.getSCode();
        (cache,env,_,dae_1) =
        Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,p_1,className);
        dae  = DAEUtil.transformationsBeforeBackend(cache,env,dae_1);
        description = DAEUtil.daeDescription(dae);
        a_cref = AbsynUtil.pathToCref(className);
        file_dir = getFileDir(a_cref, p);
        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        dlow = FindZeroCrossings.findZeroCrossings(dlow);
        flatModelicaStr = DAEDump.dumpStr(dae,FCore.getFunctionTree(cache));
        flatModelicaStr = stringAppend("OldEqStr={'", flatModelicaStr);
        flatModelicaStr = System.stringReplace(flatModelicaStr, "\n", "%##%");
        flatModelicaStr = System.stringReplace(flatModelicaStr, "%##%", "','");
        flatModelicaStr = stringAppend(flatModelicaStr,"'};");
        filename = DAEQuery.writeAdjacencyMatrix(dlow, filenameprefix, flatModelicaStr);
        str = stringAppend("The equation system was dumped to Matlab file:", filename);
      then
        (cache,Values.STRING(str),file_dir);
  end match;
end getAdjacencyMatrix;

public function runFrontEnd
  input output FCore.Cache cache;
  input output FCore.Graph env;
  input Absyn.Path className;
  input Boolean relaxedFrontEnd "Do not check for illegal simulation models, so we allow instantation of packages, etc";
  input Boolean dumpFlat = false;
  output Option<DAE.DAElist> odae = NONE();
  output String flatString = "";
protected
  DAE.DAElist dae;
  Boolean b;
algorithm
  // add program to the cache so it can be used to lookup modelica://
  // URIs in external functions IncludeDirectory/LibraryDirectory
  FlagsUtil.setConfigBool(Flags.BUILDING_MODEL, true);
  try
    b := runFrontEndLoadProgram(className);
    true := b;
    if Flags.isSet(Flags.GC_PROF) then
      print(GC.profStatsStr(GC.getProfStats(), head="GC stats before front-end:") + "\n");
    end if;
    ExecStat.execStat("FrontEnd - loaded program");
    (cache,env,dae,flatString) := runFrontEndWork(cache,env,className,relaxedFrontEnd,dumpFlat);
    if Flags.isSet(Flags.GC_PROF) then
      print(GC.profStatsStr(GC.getProfStats(), head="GC stats after front-end:") + "\n");
    end if;
    ExecStat.execStat("FrontEnd - DAE generated");
    odae := SOME(dae);
  else
    // Return odae=NONE(); needed to update cache and symbol table if we fail
  end try;
  FlagsUtil.setConfigBool(Flags.BUILDING_MODEL, false);
end runFrontEnd;

protected function runFrontEndLoadProgram
  input Absyn.Path className;
  output Boolean success;
protected
  Absyn.Restriction restriction;
  Absyn.Class absynClass;
  String str;
  SCode.Program scodeP;
  Absyn.Program p;
  DAE.FunctionTree funcs;
  Boolean b;
algorithm
  p := SymbolTable.getAbsyn();
  try
    Interactive.getPathedClassInProgram(className, p, true);
  else
    str := AbsynUtil.pathFirstIdent(className);
    (p,b) := CevalScript.loadModel({(Absyn.IDENT(str),"the given model name to instantiate",{"default"},false)},Settings.getModelicaPath(Testsuite.isRunning()),p,true,true,true,false);
    Error.assertionOrAddSourceMessage(not b,Error.NOTIFY_NOT_LOADED,{str,"default"},AbsynUtil.dummyInfo);
    // print(stringDelimitList(list(AbsynUtil.pathString(path) for path in Interactive.getTopClassnames(p)), ",") + "\n");
    SymbolTable.setAbsyn(p);
  end try;

  (p,success) := CevalScript.loadModel(Interactive.getUsesAnnotationOrDefault(p, false),Settings.getModelicaPath(Testsuite.isRunning()),p,false,true,true,false);
  SymbolTable.setAbsyn(p);
  // Always update the SCode structure; otherwise the cache plays tricks on us
  SymbolTable.clearSCode();
end runFrontEndLoadProgram;

protected function runFrontEndWork
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className;
  input Boolean relaxedFrontEnd "Do not check for illegal simulation models, so we allow instantation of packages, etc";
  input Boolean dumpFlat;
  output FCore.Cache cache;
  output FCore.Graph env;
  output DAE.DAElist dae;
  output String flatString = "";
protected
  Integer numError = Error.getNumErrorMessages();
algorithm
  (cache,env,dae) := matchcontinue (inCache,inEnv,className)
    local
      Absyn.Restriction restriction;
      Absyn.Class absynClass;
      String str,re;
      SCode.Program scodeP;
      Absyn.Program p;
      DAE.FunctionTree funcs;
      NFFlatModel flat_model;
      NFFlatten.FunctionTree nf_funcs;

   case (cache,env,_)
      equation
        true = Flags.isSet(Flags.GRAPH_INST);
        false = Flags.isSet(Flags.SCODE_INST);

        System.realtimeTick(ClockIndexes.RT_CLOCK_FINST);
        str = AbsynUtil.pathString(className);
        (Absyn.CLASS(restriction = restriction)) = Interactive.getPathedClassInProgram(className, SymbolTable.getAbsyn(), true);
        re = AbsynUtil.restrString(restriction);
        Error.assertionOrAddSourceMessage(relaxedFrontEnd or not (AbsynUtil.isFunctionRestriction(restriction) or AbsynUtil.isPackageRestriction(restriction)),
          Error.INST_INVALID_RESTRICTION,{str,re},AbsynUtil.dummyInfo);

        System.realtimeTick(ClockIndexes.RT_CLOCK_FINST);

        dae = FInst.instPath(className, SymbolTable.getSCode());
      then (cache,env,dae);

    case (_, _, _)
      algorithm
        false := Flags.isSet(Flags.GRAPH_INST);
        true := Flags.isSet(Flags.SCODE_INST);

        (flat_model, nf_funcs, flatString) := runFrontEndWorkNF(className, dumpFlat);
        (dae, funcs) := NFConvertDAE.convert(flat_model, nf_funcs);

        cache := FCore.emptyCache();
        FCore.setCachedFunctionTree(cache, funcs);
        env := FGraph.empty();

      then (cache, env, dae);

    case (cache,env,_)
      equation
        false = Flags.isSet(Flags.GRAPH_INST);
        false = Flags.isSet(Flags.SCODE_INST);
        str = AbsynUtil.pathString(className);
        p = SymbolTable.getAbsyn();
        (Absyn.CLASS(restriction = restriction)) = Interactive.getPathedClassInProgram(className, p, true);
        re = AbsynUtil.restrString(restriction);
        Error.assertionOrAddSourceMessage(relaxedFrontEnd or not (AbsynUtil.isFunctionRestriction(restriction) or AbsynUtil.isPackageRestriction(restriction)),
          Error.INST_INVALID_RESTRICTION,{str,re},AbsynUtil.dummyInfo);

        //System.stopTimer();
        //print("\nExists+Dependency: " + realString(System.getTimerIntervalTime()));

        //System.startTimer();
        //print("\nAbsyn->SCode");
        scodeP = SymbolTable.getSCode();

        ExecStat.execStat("FrontEnd - Absyn->SCode");

        //System.stopTimer();
        //print("\nAbsyn->SCode: " + realString(System.getTimerIntervalTime()));

        //System.startTimer();
        //print("\nInst.instantiateClass");
        (cache,env,_,dae) = Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,scodeP,className);

        dae = DAEUtil.mergeAlgorithmSections(dae);

        //FGraphDump.dumpGraph(env, "F:\\dev\\" + AbsynUtil.pathString(className) + ".graph.graphml");

        //System.stopTimer();
        //print("\nInst.instantiateClass: " + realString(System.getTimerIntervalTime()));

        // adrpo: do not add it to the instantiated classes, it just consumes memory for nothing.
        DAEUtil.getFunctionList(FCore.getFunctionTree(cache),failOnError=true); // Make sure that the functions are valid before returning success
      then (cache,env,dae);

    case (_,_,_)
      equation
        failure(Interactive.getPathedClassInProgram(className, SymbolTable.getAbsyn()));
        Error.addMessage(Error.LOOKUP_ERROR, {AbsynUtil.pathString(className),"<TOP>"});
      then fail();

    else
      equation
        str = AbsynUtil.pathString(className);
        true = Error.getNumErrorMessages() == numError;
        str = "Instantiation of " + str + " failed with no error message.";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end runFrontEndWork;

function runFrontEndWorkNF
  input Absyn.Path className;
  input Boolean dumpFlat = false;
  output NFFlatModel flatModel;
  output NFFlatten.FunctionTree functions;
  output String flatString;
protected
  Absyn.Program placement_p;
  SCode.Program builtin_p, scode_p, graphic_p;
  Boolean b;
algorithm
  (_, builtin_p) := FBuiltin.getInitialFunctions();
  scode_p := listAppend(builtin_p, SymbolTable.getSCode());
  ExecStat.execStat("FrontEnd - Absyn->SCode");

  // add also the graphics annotations if we are using the NF_API
  if Flags.isSet(Flags.NF_API) then
    placement_p := Interactive.modelicaAnnotationProgram(Config.getAnnotationVersion());
    graphic_p := AbsynToSCode.translateAbsyn2SCode(placement_p);
    scode_p := listAppend(scode_p, graphic_p);
  end if;

  // make sure we don't run the default instantiateModel using -d=nfAPI
  // only the stuff going via NFApi.mo should have this flag activated
  b := FlagsUtil.set(Flags.NF_API, false);
  try
    (flatModel, functions, flatString) := NFInst.instClassInProgram(className, scode_p, dumpFlat);
	FlagsUtil.set(Flags.NF_API, b);
  else
    FlagsUtil.set(Flags.NF_API, b);
	fail();
  end try;
end runFrontEndWorkNF;

protected function translateModel " author: x02lucpo
 translates a model into cpp code and writes also a makefile"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output Boolean success;
  output FCore.Cache outCache;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  (outCache,outStringLst,outFileDir,resultValues):=
  match (inCache,inEnv,className,inFileNamePrefix,addDummy,inSimSettingsOpt)
    local
      FCore.Cache cache;
      FCore.Graph env;
      list<String> libs;
      String file_dir, fileNamePrefix;
      Absyn.Program p;
      Flags.Flag flags;
      String commandLineOptions;
      list<String> args;
      Boolean haveAnnotation;

    case (cache,env,_,fileNamePrefix,_,_)
      algorithm
        if Config.ignoreCommandLineOptionsAnnotation() then
          (success, cache, libs, file_dir, resultValues) :=
            callTranslateModel(cache,env,className,fileNamePrefix,inSimSettingsOpt);
        else
          // read the __OpenModelica_commandLineOptions
          Absyn.STRING(commandLineOptions) := Interactive.getNamedAnnotation(className, SymbolTable.getAbsyn(), Absyn.IDENT("__OpenModelica_commandLineOptions"), SOME(Absyn.STRING("")), Interactive.getAnnotationExp);
          haveAnnotation := boolNot(stringEq(commandLineOptions, ""));
          // backup the flags.
          flags := if haveAnnotation then FlagsUtil.backupFlags() else FlagsUtil.loadFlags();
          try
            // apply if there are any new flags
            if haveAnnotation then
              args := System.strtok(commandLineOptions, " ");
              FlagsUtil.readArgs(args);
            end if;

            (success, cache, libs, file_dir, resultValues) :=
              callTranslateModel(cache,env,className,fileNamePrefix,inSimSettingsOpt);
            // reset to the original flags
            FlagsUtil.saveFlags(flags);
          else
            FlagsUtil.saveFlags(flags);
            fail();
          end try;
        end if;
      then
        (cache,libs,file_dir,resultValues);

  end match;
end translateModel;

protected function translateLabeledModel " author: Fatima
 translates a labeled model into cpp code and writes also a makefile"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  input list<Absyn.NamedArg> inLabelstoCancel;
  output FCore.Cache outCache;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  (outCache,outStringLst,outFileDir,resultValues):=
  match (inCache,inEnv,className,inFileNamePrefix,addDummy,inSimSettingsOpt,inLabelstoCancel)
    local
      FCore.Cache cache;
      FCore.Graph env;
      BackendDAE.BackendDAE indexed_dlow;
      list<String> libs;
      String file_dir, fileNamePrefix;
      Absyn.Program p;
      Flags.Flag flags;
      String commandLineOptions;
      list<String> args;
      Boolean haveAnnotation;
      list<Absyn.NamedArg> labelstoCancel;

    case (cache,env,_,fileNamePrefix,_,_,labelstoCancel)
      algorithm

        if Config.ignoreCommandLineOptionsAnnotation() then
          (true, cache, libs, file_dir, resultValues) :=
            SimCodeMain.translateModel(SimCodeMain.TranslateModelKind.NORMAL(),cache,env,className,fileNamePrefix,addDummy,inSimSettingsOpt,Absyn.FUNCTIONARGS({},argNames =labelstoCancel));
        else
          // read the __OpenModelica_commandLineOptions
          Absyn.STRING(commandLineOptions) := Interactive.getNamedAnnotation(className, SymbolTable.getAbsyn(), Absyn.IDENT("__OpenModelica_commandLineOptions"), SOME(Absyn.STRING("")), Interactive.getAnnotationExp);
          haveAnnotation := boolNot(stringEq(commandLineOptions, ""));
          // backup the flags.
          flags := if haveAnnotation then FlagsUtil.backupFlags() else FlagsUtil.loadFlags();
          try
            // apply if there are any new flags
            if haveAnnotation then
              args := System.strtok(commandLineOptions, " ");
              FlagsUtil.readArgs(args);
            end if;

            (true, cache, libs, file_dir, resultValues) :=
              SimCodeMain.translateModel(SimCodeMain.TranslateModelKind.NORMAL(),cache,env,className,fileNamePrefix,addDummy,inSimSettingsOpt,Absyn.FUNCTIONARGS({},argNames =labelstoCancel));
            // reset to the original flags
            FlagsUtil.saveFlags(flags);
          else
            FlagsUtil.saveFlags(flags);
            fail();
          end try;
        end if;
      then
        (cache,libs,file_dir,resultValues);

  end match;
end translateLabeledModel;

protected function callTranslateModel
"Call the main translate function. This function
 distinguish between the modes. Now between DAEMode and ODEmode.
 The appropriate function create model code and writes also a makefile"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input String inFileNamePrefix;
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output Boolean success;
  output FCore.Cache outCache;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  if Flags.getConfigBool(Flags.DAE_MODE) then
    (outCache, outStringLst, outFileDir, resultValues) :=
    SimCodeMain.translateModelDAEMode(inCache,inEnv,className,inFileNamePrefix,
    inSimSettingsOpt,Absyn.FUNCTIONARGS({},{}));
    success := true;
  else
    (success, outCache, outStringLst, outFileDir, resultValues) :=
    SimCodeMain.translateModel(SimCodeMain.TranslateModelKind.NORMAL(),inCache,inEnv,
      className,inFileNamePrefix,true,inSimSettingsOpt,Absyn.FUNCTIONARGS({},{}));
  end if;
end callTranslateModel;

protected function configureFMU
"Configures Makefile.in of FMU for traget configuration."
  input String platform;
  input String fmutmp;
  input String logfile;
  input Boolean isWindows;
  input Boolean needs3rdPartyLibs;
protected
  String CC, CFLAGS, CPPFLAGS, LDFLAGS, SUNDIALS, makefileStr, container, host, nozip, path1, path2,
    dir=fmutmp+"/sources/", cmd="",
    quote="'",
    dquote = if isWindows then "\"" else "'",
    includeDefaultFmi, volumeID, cidFile, containerID;
  list<String> rest;
  Boolean finishedBuild;
  Integer uid, status;
  Boolean verbose = false;
algorithm
  includeDefaultFmi := dquote + Settings.getInstallationDirectoryPath() + "/include/omc/c/fmi" + dquote;

  CC := System.getCCompiler();
  CFLAGS := "-Os "+System.stringReplace(System.getCFlags(),"${MODELICAUSERCFLAGS}","");

  LDFLAGS := ("-L"+dquote+Settings.getInstallationDirectoryPath()+"/lib/"+Autoconf.triple+"/omc"+dquote+" "+
              "-Wl,-rpath,"+dquote+Settings.getInstallationDirectoryPath()+"/lib/"+Autoconf.triple+"/omc"+dquote+" "+
              System.getLDFlags()+" ");
  CPPFLAGS := "-I" + includeDefaultFmi + " -DOMC_FMI_RUNTIME=1";
  if needs3rdPartyLibs then
    SUNDIALS :=  "1";
    CPPFLAGS := CPPFLAGS + " -DWITH_SUNDIALS=1" + " -Isundials";
  else
    SUNDIALS :=  "";
  end if;
  if System.regularFileExists(logfile) then
    System.removeFile(logfile);
  end if;
  nozip := Autoconf.make+" -j"+intString(Config.noProc()) + " nozip";
  finishedBuild := match Util.stringSplitAtChar(platform, " ")
    case {"dynamic"}
      algorithm
        makefileStr := System.readFile(dir + "Makefile.in");
        // replace @XX@ variables in the Makefile
        makefileStr := System.stringReplace(makefileStr, "@CC@", CC);
        makefileStr := System.stringReplace(makefileStr, "@CFLAGS@", CFLAGS);
        makefileStr := System.stringReplace(makefileStr, "@LDFLAGS@", LDFLAGS+Autoconf.ldflags_runtime_sim);
        makefileStr := System.stringReplace(makefileStr, "@LIBS@", "");
        makefileStr := System.stringReplace(makefileStr, "@DLLEXT@", Autoconf.dllExt);
        makefileStr := System.stringReplace(makefileStr, "@NEED_RUNTIME@", "");
        makefileStr := System.stringReplace(makefileStr, "@NEED_DGESV@", "");
        makefileStr := System.stringReplace(makefileStr, "@NEED_SUNDIALS@", "");
        makefileStr := System.stringReplace(makefileStr, "@FMIPLATFORM@", System.modelicaPlatform());
        makefileStr := System.stringReplace(makefileStr, "@CPPFLAGS@", CPPFLAGS + " -DOMC_SIM_SETTINGS_CMDLINE");
        makefileStr := System.stringReplace(makefileStr, "@LIBTYPE_DYNAMIC@", "1");
        makefileStr := System.stringReplace(makefileStr, "@BSTATIC@", Autoconf.bstatic);
        makefileStr := System.stringReplace(makefileStr, "@BDYNAMIC@", Autoconf.bdynamic);
        makefileStr := System.stringReplace(makefileStr, "\r\n", "\n");
        System.writeFile(dir + "Makefile", makefileStr);
        System.writeFile(dir + "config.log", "Using cached values for dynamic platform");
        cmd := "cached values";
      then false;
    case {"static"}
      algorithm
        makefileStr := System.readFile(dir + "Makefile.in");
        // replace @XX@ variables in the Makefile
        makefileStr := System.stringReplace(makefileStr, "@CC@", CC);
        makefileStr := System.stringReplace(makefileStr, "@CFLAGS@", CFLAGS);
        makefileStr := System.stringReplace(makefileStr, "@LDFLAGS@", LDFLAGS+" -lSimulationRuntimeFMI "+Autoconf.ldflags_runtime_fmu);
        makefileStr := System.stringReplace(makefileStr, "@LIBS@", "");
        makefileStr := System.stringReplace(makefileStr, "@DLLEXT@", Autoconf.dllExt);
        makefileStr := System.stringReplace(makefileStr, "@NEED_RUNTIME@", "");
        makefileStr := System.stringReplace(makefileStr, "@NEED_DGESV@", "");
        makefileStr := System.stringReplace(makefileStr, "@NEED_SUNDIALS@", SUNDIALS);
        makefileStr := System.stringReplace(makefileStr, "@FMIPLATFORM@", System.modelicaPlatform());
        makefileStr := System.stringReplace(makefileStr, "@CPPFLAGS@", CPPFLAGS + " -DCMINPACK_NO_DLL=1");
        makefileStr := System.stringReplace(makefileStr, "@LIBTYPE_DYNAMIC@", "1");
        makefileStr := System.stringReplace(makefileStr, "@BSTATIC@", Autoconf.bstatic);
        makefileStr := System.stringReplace(makefileStr, "@BDYNAMIC@", Autoconf.bdynamic);
        makefileStr := System.stringReplace(makefileStr, "\r\n", "\n");
        System.writeFile(dir + "Makefile", makefileStr);
        System.writeFile(dir + "config.log", "Using cached values for static platform");
        cmd := "cached values";
      then false;
    case {_}
      algorithm
        cmd := "cd \"" +  fmutmp + "/sources\" && ./configure --host="+quote+platform+quote+
               " CFLAGS=" + quote + "-Os" + quote + " CPPFLAGS=" + quote + CPPFLAGS + quote+
               " LDFLAGS= && " + nozip;
        if 0 <> System.systemCall(cmd, outFile=logfile) then
          Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {System.readFile(logfile)});
          System.removeFile(logfile);
          fail();
        end if;
      then true;
    case host::"docker"::"run"::rest
      algorithm
        uid := System.getuid();
        // Create a docker volume for the FMU since we can't forward volumes
        // to the docker run command depending on where the FMU was generated (inside another volume)
        cmd := "docker volume create";
        if 0 <> System.systemCall(cmd, outFile=logfile) then
          Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {cmd + " failed:\n" + System.readFile(logfile)});
          fail();
        elseif verbose then
           print(cmd + "\n" + System.readFile(logfile) +"\n");
        end if;
        cidFile := fmutmp+".cidfile";
        if System.regularFileExists(cidFile) then
          System.removeFile(cidFile);
        end if;
        volumeID := System.trim(System.readFile(logfile));
        cmd := "docker run --cidfile "+cidFile+" -v "+volumeID+":/data busybox true";
        if 0 <> System.systemCall(cmd, outFile=logfile) then
          Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {cmd + " failed:\n" + System.readFile(logfile)});
          // Cleanup
          System.systemCall("docker volume rm " + volumeID);
          fail();
        elseif verbose then
           print(cmd + "\n" + System.readFile(logfile) +"\n");
        end if;
        containerID := System.trim(System.readFile(cidFile));
        System.removeFile(cidFile);
        // Copy the FMU contents to the container
        cmd := "docker cp "+fmutmp+" "+containerID+":/data";
        if 0 <> System.systemCall(cmd, outFile=logfile) then
          Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {cmd + " failed:\n" + System.readFile(logfile)});
          // Cleanup
          System.systemCall("docker rm " + containerID);
          System.systemCall("docker volume rm " + volumeID);
          fail();
        elseif verbose then
           print(cmd + "\n" + System.readFile(logfile) +"\n");
        end if;
        // Copy the FMI headers to the container
        cmd := "docker cp "+includeDefaultFmi+" "+containerID+":/data/fmiInclude";
        if 0 <> System.systemCall(cmd, outFile=logfile) then
          Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {cmd + " failed:\n" + System.readFile(logfile)});
          // Cleanup
          System.systemCall("docker rm " + containerID);
          System.systemCall("docker volume rm " + volumeID);
          fail();
        elseif verbose then
           print(cmd + "\n" + System.readFile(logfile) +"\n");
        end if;
        cmd := "docker run "+(if uid<>0 then "--user " + String(uid) else "")+" --rm -w /fmu -v "+volumeID+":/fmu "+stringDelimitList(rest," ")+ " sh -c " + dquote +
               "cd " + dquote + "/fmu/" + System.basename(fmutmp) + "/sources" + dquote + " && " +
               "./configure --host="+quote+host+quote+" CFLAGS="+quote+"-Os"+quote+" CPPFLAGS=-I/fmu/fmiInclude LDFLAGS= && " +
               nozip + dquote;
        if 0 <> System.systemCall(cmd, outFile=logfile) then
          Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {cmd + ":\n" + System.readFile(logfile)});
          System.removeFile(logfile);
          // Cleanup
          System.systemCall("docker rm " + containerID);
          System.systemCall("docker volume rm " + volumeID);
          fail();
        elseif verbose then
           print(cmd + "\n" + System.readFile(logfile) +"\n");
        end if;
        // Copy the files back from the volume (via the container) to the filesystem
        cmd := "docker cp " + quote + containerID + ":/data/" + fmutmp + quote + " .";
        if 0 <> System.systemCall(cmd, outFile=logfile) then
          Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {cmd + ":\n" + System.readFile(logfile)});
          fail();
        elseif verbose then
           print(cmd + "\n" + System.readFile(logfile) +"\n");
        end if;
        // Cleanup
        System.systemCall("docker rm " + containerID);
        System.systemCall("docker volume rm " + volumeID);
      then true;
    else
      algorithm
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {"Unknown platform (contains spaces but does does not conform to \"platform docker run [args] container\""});
      then fail();
  end match;
  ExecStat.execStat("buildModelFMU: configured platform " + platform + " using " + cmd);
  if not finishedBuild then
    if not isWindows then
      if 0 <> System.systemCall("cd " + dir + " && make clean > /dev/null 2>&1") then
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {"Failed to make clean"});
        fail();
      end if;
    end if;
    if 0 <> System.systemCall("cd \"" +  fmutmp + "/sources\" && " + nozip, outFile=logfile) then
      Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {System.readFile(logfile)});
      System.removeFile(logfile);
      fail();
    end if;
  end if;
end configureFMU;

protected function buildModelFMU
 " Author: Frenkel TUD
   Translates a model into target code and writes also a makefile."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input String FMUVersion;
  input String inFMUType;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input list<String> platforms = {"static"};
  output FCore.Cache cache;
  output Values.Value outValue;
protected
  Boolean staticSourceCodeFMU, success;
  String filenameprefix, fmutmp, logfile, configureLogFile, dir, cmd;
  String fmuTargetName;
  GlobalScript.SimulationOptions defaulSimOpt;
  SimCode.SimulationSettings simSettings;
  list<String> libs;
  Boolean isWindows;
  list<String> fmiFlagsList;
  Boolean needs3rdPartyLibs;
  String FMUType = inFMUType;
  Boolean debug = false;

algorithm
  
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
  if not FMI.canExportFMU(FMUVersion, FMUType) then
    outValue := Values.STRING("");
    Error.addMessage(Error.FMU_EXPORT_NOT_SUPPORTED, {FMUType, FMUVersion});
    return;
  end if;
  if Config.simCodeTarget() == "Cpp" and FMI.isFMICSType(FMUType) then
    Error.addMessage(Error.FMU_EXPORT_NOT_SUPPORTED_CPP, {FMUType});
    FMUType := "me";
  end if;

  // NOTE: The FMUs use fileNamePrefix for the internal name when it would be expected to be fileNamePrefix that decides the .fmu filename
  //       The scripting environment from a user's perspective is like that. fmuTargetName is the name of the .fmu in the templates, etc.
  filenameprefix := Util.stringReplaceChar(if inFileNamePrefix == "<default>" then AbsynUtil.pathString(className) else inFileNamePrefix, ".", "_");
  fmuTargetName := if FMUVersion == "1.0" then filenameprefix else (if inFileNamePrefix == "<default>" then AbsynUtil.pathString(className) else inFileNamePrefix);
  defaulSimOpt := buildSimulationOptionsFromModelExperimentAnnotation(className, filenameprefix, SOME(defaultSimulationOptions));
  simSettings := convertSimulationOptionsToSimCode(defaulSimOpt);
  FlagsUtil.setConfigBool(Flags.BUILDING_FMU, true);
  FlagsUtil.setConfigString(Flags.FMI_VERSION, FMUVersion);
  try
    (success, cache, libs, _, _) := SimCodeMain.translateModel(SimCodeMain.TranslateModelKind.FMU(FMUType, fmuTargetName), cache, inEnv, className, filenameprefix, addDummy, SOME(simSettings));
    true := success;
    outValue := Values.STRING((if not Testsuite.isRunning() then System.pwd() + Autoconf.pathDelimiter else "") + fmuTargetName + ".fmu");
  else
    outValue := Values.STRING("");
    FlagsUtil.setConfigBool(Flags.BUILDING_FMU, false);
    FlagsUtil.setConfigString(Flags.FMI_VERSION, "");
    return;
  end try;
  FlagsUtil.setConfigBool(Flags.BUILDING_FMU, false);
  FlagsUtil.setConfigString(Flags.FMI_VERSION, "");

  System.realtimeTick(ClockIndexes.RT_CLOCK_BUILD_MODEL);

  isWindows := Autoconf.os == "Windows_NT";

  fmutmp := filenameprefix + ".fmutmp";
  logfile := filenameprefix + ".log";
  dir := fmutmp+"/sources/";

  if Config.simCodeTarget() == "Cpp" then
    System.removeDirectory("binaries");
    for platform in platforms loop
      if platform == "dynamic" or platform == "static" then
        CevalScript.compileModel(filenameprefix + "_FMU", libs);
      else
        CevalScript.compileModel(filenameprefix + "_FMU", libs,
                                 makeVars={"TARGET_TRIPLET=" + platform});
      end if;
      ExecStat.execStat("buildModelFMU: Generate C++ for platform " + platform);
    end for;
    if 0 <> System.systemCall("make -f " + filenameprefix + "_FMU.makefile clean", outFile=logfile) then
      // do nothing
    end if;
    return;
  end if;
  /*Temporary disabled omsicpp*/
  if not ((Config.simCodeTarget() == "omsic")/* or (Config.simCodeTarget() == "omsicpp")*/) then
    CevalScript.compileModel(filenameprefix+"_FMU" , libs);
    ExecStat.execStat("buildModelFMU: Generate the FMI files");
  else
    fmutmp := filenameprefix+".fmutmp" + Autoconf.pathDelimiter;
    CevalScript.compileModel(filenameprefix+"_FMU" , libs, fmutmp);
    return;
  end if;

  // Check flag fmiFlags if we need additional 3rdParty runtime libs and files
  fmiFlagsList := Flags.getConfigStringList(Flags.FMI_FLAGS);
  if listLength(fmiFlagsList) >= 1 and not stringEqual(List.first(fmiFlagsList), "none") then
    needs3rdPartyLibs := true;
  else
    needs3rdPartyLibs := false;
  end if;

  // Configure the FMU Makefile
  for platform in platforms loop
    configureLogFile := System.realpath(fmutmp)+"/resources/"+System.stringReplace(listGet(Util.stringSplitAtChar(platform," "),1),"/","-")+".log";
    configureFMU(platform, fmutmp, configureLogFile, isWindows, needs3rdPartyLibs);
    if Flags.getConfigEnum(Flags.FMI_FILTER) == Flags.FMI_BLACKBOX then
      System.removeFile(configureLogFile);
    end if;
    ExecStat.execStat("buildModelFMU: Generate platform " + platform);
  end for;

  // check for '--fmiSource=false' or '--fmiFilter=blackBox' and remove the sources directory before packing the fmu
  if not Flags.getConfigBool(Flags.FMI_SOURCES) or Flags.getConfigEnum(Flags.FMI_FILTER) == Flags.FMI_BLACKBOX then
    if not System.removeDirectory(fmutmp + "/sources/") then
      Error.addInternalError("Failed to remove directory: " + fmutmp, sourceInfo());
    end if;
  end if;

  cmd := "rm -f \"" + fmuTargetName + ".fmu\" && cd \"" + fmutmp + "\" && zip -r \"../" + fmuTargetName + ".fmu\" *";
  if 0 <> System.systemCall(cmd, outFile=logfile) then
    Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {cmd + "\n\n" + System.readFile(logfile)});
    ExecStat.execStat("buildModelFMU failed");
  end if;

  if not System.regularFileExists(fmuTargetName + ".fmu") then
    Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {"Build commands returned success, but " + fmuTargetName + ".fmu does not exist"});
    fail();
  end if;

  if not debug then
    System.removeDirectory(fmutmp);
  end if;
end buildModelFMU;

protected function buildEncryptedPackage
  input Absyn.Path className "path for the model";
  input Boolean encrypt;
  input Absyn.Program inProgram;
  output Boolean success;
protected
  Absyn.Class cls;
  String fileName, logFile, omhome, pd, ext, packageTool, packageToolArgs, command;
  Boolean runCommand;
  String molName, dirPath, rmCommand, cdCommand, mvCommand, dirOrFileName, zipCommand;
algorithm
  cls := Interactive.getPathedClassInProgram(className, inProgram);
  fileName := AbsynUtil.classFilename(cls);
  logFile := "buildEncryptedPackage.log";
  runCommand := true;
  if (System.regularFileExists(fileName)) then
    // get OPENMODELICAHOME
    omhome := Settings.getInstallationDirectoryPath();
    pd := Autoconf.pathDelimiter;
    ext := if Autoconf.os == "Windows_NT" then ".exe" else "";
    if encrypt then
      // create the path till packagetool
      packageTool := stringAppendList({omhome,pd,"lib",pd,"omc",pd,"SEMLA",pd,"packagetool",ext});
      if System.regularFileExists(packageTool) then
        // create the list of arguments for packagetool
        packageToolArgs := "-librarypath \"" + System.dirname(fileName) + "\" -version \"1.0\" -language \"3.2\" -encrypt \"" + boolString(encrypt) + "\"";
        command := stringAppendList({"\"",packageTool,"\""," ",packageToolArgs});
      else
        Error.addMessage(Error.ENCRYPTION_NOT_SUPPORTED, {packageTool});
        success := false;
        runCommand := false;
      end if;
    else
      molName := AbsynUtil.pathString(className) + ".mol";
      dirPath := System.dirname(fileName);
      // commands
      rmCommand := "rm -f \"" + molName + "\"";
      cdCommand := "cd \"" +  dirPath + "\"";
      mvCommand := "mv \"" + molName +"\" \"" + System.pwd() + "\"";

      if (Util.endsWith(fileName, "package.mo")) then
        dirOrFileName := System.basename(dirPath);
        zipCommand := "zip -r \"" + System.pwd() + pd + molName + "\" \"" + dirOrFileName + "\"";
        command := stringAppendList({rmCommand, " && ", cdCommand, " && cd .. && ", zipCommand});
      else
        dirOrFileName := System.basename(fileName);
        zipCommand := "zip -r \"" + System.pwd() + pd + molName + "\" \"" + dirOrFileName + "\"";
        command := stringAppendList({rmCommand, " && ", cdCommand, " && ", zipCommand});
      end if;
    end if;

    if runCommand then
      // remove the logFile if it already exists.
      if System.regularFileExists(logFile) then
        System.removeFile(logFile);
      end if;
      // run the command
      success := 0 == System.systemCall(command, logFile);
      if not(success) then
        Error.addCompilerError("Command failed: " + command);
      end if;
    end if;
  else
    Error.addMessage(Error.FILE_NOT_FOUND_ERROR, {fileName});
    success := false;
  end if;
end buildEncryptedPackage;

protected function translateModelXML " author: Alachew
 translates a model into XML code "
  input output FCore.Cache cache;
  input FCore.Graph env;
  input Absyn.Path className "path for the model";
  output Values.Value outValue;
  input String fileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
protected
  Boolean success;
algorithm
  (success,cache) := SimCodeMain.translateModel(SimCodeMain.TranslateModelKind.XML(),cache,env,className,fileNamePrefix,addDummy,inSimSettingsOpt);
  outValue := Values.STRING(if success then ((if not Testsuite.isRunning() then System.pwd() + Autoconf.pathDelimiter else "") + fileNamePrefix+".xml") else "");
end translateModelXML;


public function translateGraphics "function: translates the graphical annotations from old to new version"
  input Absyn.Path className;
  input Absyn.Msg inMsg;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue (className,inMsg)
    local
      Absyn.Program p;
      Absyn.Msg msg;
      String errorMsg,retStr,s1;
      Absyn.Class cls, refactoredClass;
      Absyn.Within within_;
      Absyn.Program p1;
      Boolean strEmpty;

    case (_,_)
      equation
        p = SymbolTable.getAbsyn();
        cls = Interactive.getPathedClassInProgram(className, p);
        refactoredClass = Refactor.refactorGraphicalAnnotation(p, cls);
        within_ = Interactive.buildWithin(className);
        SymbolTable.setAbsyn(Interactive.updateProgram(Absyn.PROGRAM({refactoredClass}, within_), p));
        s1 = AbsynUtil.pathString(className);
        retStr=stringAppendList({"Translation of ",s1," successful.\n"});
      then Values.STRING(retStr);

    else
      equation
        errorMsg = Error.printMessagesStr(false);
        strEmpty = (stringCompare("",errorMsg)==0);
        errorMsg = if strEmpty then "Internal error, translating graphics to new version" else errorMsg;
      then Values.STRING(errorMsg);
  end matchcontinue;
end translateGraphics;


protected function calculateSimulationSettings " author: x02lucpo
 calculates the start,end,interval,stepsize, method and initFileName"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Values.Value> vals;
  input Absyn.Msg inMsg;
  output FCore.Cache outCache;
  output SimCode.SimulationSettings outSimSettings;
algorithm
  (outCache,outSimSettings) := match (inCache,inEnv,vals,inMsg)
    local
      String method_str,options_str,outputFormat_str,variableFilter_str,s;
      Values.Value starttime_v,stoptime_v,tolerance_v;
      Integer interval_i;
      Real starttime_r,stoptime_r,tolerance_r;
      FCore.Graph env;
      Absyn.Msg msg;
      FCore.Cache cache;
      String cflags,simflags;
    case (cache,_,{Values.CODE(Absyn.C_TYPENAME(_)),starttime_v,stoptime_v,Values.INTEGER(interval_i),tolerance_v,Values.STRING(method_str),_,Values.STRING(options_str),Values.STRING(outputFormat_str),Values.STRING(variableFilter_str),Values.STRING(cflags),Values.STRING(_)},_)
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
  "Moves the referenced class by a certain offset in the given program, relative
   to other classes."
  input Absyn.Path inClassName;
  input Integer inOffset;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
  output Boolean outSuccess;
protected
  Absyn.Path parent_cls;
  String cls_name;
algorithm
  // No offset, nothing to do.
  if inOffset == 0 then
    outProgram := inProgram;
    outSuccess := true;
    return;
  end if;

  try
    if AbsynUtil.pathIsIdent(inClassName) then
      // Simple identifier, move a top-level class in the program.
      outProgram := moveClassInProgram(AbsynUtil.pathFirstIdent(inClassName), inOffset, inProgram);
    else
      // Qualified identifier, move the class inside its parent.
      (parent_cls, Absyn.IDENT(cls_name)) := AbsynUtil.splitQualAndIdentPath(inClassName);
      outProgram := Interactive.transformPathedClassInProgram(parent_cls, inProgram,
         function moveClassInClass(inName = cls_name, inOffset = inOffset));
    end if;

    outSuccess := true;
  else
    outProgram := inProgram;
    outSuccess := false;
  end try;
end moveClass;

protected function moveClassToTop
  "Moves a named class to the top of its enclosing class."
  input Absyn.Path inClassName;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram = inProgram;
  output Boolean outSuccess;
protected
  Absyn.Path parent_cls;
  String cls_name;
algorithm
  try
    if AbsynUtil.pathIsIdent(inClassName) then
      outProgram := match outProgram
        local
          list<Absyn.Class> classes;
          Absyn.Class cls;

        case Absyn.PROGRAM()
          algorithm
            (classes, SOME(cls)) :=
              List.deleteMemberOnTrue(AbsynUtil.pathFirstIdent(inClassName),
                outProgram.classes, AbsynUtil.isClassNamed);
            outProgram.classes := cls :: classes;
          then
            outProgram;
      end match;
    else
      (parent_cls, Absyn.IDENT(cls_name)) := AbsynUtil.splitQualAndIdentPath(inClassName);
      outProgram := Interactive.transformPathedClassInProgram(parent_cls, inProgram,
        function moveClassToTopInClass(inName = cls_name));
    end if;

    outSuccess := true;
  else
    outSuccess := false;
  end try;
end moveClassToTop;

protected function moveClassToBottom
  "Moves a named class to the bottom of its enclosing class."
  input Absyn.Path inClassName;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram = inProgram;
  output Boolean outSuccess;
protected
  Absyn.Path parent_cls;
  String cls_name;
algorithm
  try
    if AbsynUtil.pathIsIdent(inClassName) then
      outProgram := match outProgram
        local
          list<Absyn.Class> classes;
          Absyn.Class cls;

        case Absyn.PROGRAM()
          algorithm
            (classes, SOME(cls)) :=
              List.deleteMemberOnTrue(AbsynUtil.pathFirstIdent(inClassName),
                outProgram.classes, AbsynUtil.isClassNamed);
            outProgram.classes := listAppend(classes, {cls});
          then
            outProgram;
      end match;
    else
      (parent_cls, Absyn.IDENT(cls_name)) := AbsynUtil.splitQualAndIdentPath(inClassName);
      outProgram := Interactive.transformPathedClassInProgram(parent_cls, inProgram,
        function moveClassToBottomInClass(inName = cls_name));
    end if;

    outSuccess := true;
  else
    outSuccess := false;
  end try;
end moveClassToBottom;

protected function moveClassInProgram
  "Moves a named class a certain offset within a program."
  input String inName;
  input Integer inOffset;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram = inProgram;
algorithm
  outProgram := match outProgram
    case Absyn.PROGRAM()
      algorithm
        outProgram.classes := moveClassInClassList(inName, inOffset, outProgram.classes);
      then
        outProgram;
  end match;
end moveClassInProgram;

protected function moveClassInClassList
  "Moves a named class a certain offset within a list of classes. Fails if no
   class with the given name could be found."
  input String inName;
  input Integer inOffset;
  input list<Absyn.Class> inClasses;
  output list<Absyn.Class> outClasses;
protected
  Absyn.Class cls;
  list<Absyn.Class> acc = {}, rest = inClasses;
  String name;
  Integer offset;
algorithm
  // Move classes from rest to acc until we find the class.
  // This will intentionally fail if the class isn't found.
  while true loop
    (cls as Absyn.CLASS(name = name)) :: rest := rest;

    if name == inName then
      break;
    else
      acc := cls :: acc;
    end if;
  end while;

  if inOffset > 0 then
    // Clamp offset so we don't move outside the list.
    offset := min(inOffset, listLength(rest));

    // Move 'offset' number of classes from rest to acc.
    for i in 1:offset loop
      acc := listHead(rest) :: acc;
      rest := listRest(rest);
    end for;
  else
    // Clamp offset so we don't move outside the list.
    offset := max(inOffset, -listLength(acc));

    // Move 'offset' number of classes from acc to rest.
    for i in offset:-1 loop
      rest := listHead(acc) :: rest;
      acc := listRest(acc);
    end for;
  end if;

  // Assemble the class list again with the class in the correct position.
  outClasses := List.append_reverse(acc, cls :: rest);
end moveClassInClassList;

protected function moveClassInClass
  "Moves a named class a certain offset within another class. Only handles long
  class and class extends definitions, since there's no meaningful way of moving
  a class inside e.g. a short class definition. Fails if the class can't be
  found. An out of bounds offset is clamped."
  input String inName;
  input Integer inOffset;
  input Absyn.Class inClass;
  output Absyn.Class outClass;
protected
  Absyn.ClassDef body;
algorithm
  Absyn.CLASS(body = body) := inClass;

  body := match body
    case Absyn.PARTS()
      algorithm
        body.classParts := moveClassInClassParts(inName, inOffset, body.classParts);
      then
        body;

    case Absyn.CLASS_EXTENDS()
      algorithm
        body.parts := moveClassInClassParts(inName, inOffset, body.parts);
      then
        body;

  end match;

  outClass := AbsynUtil.setClassBody(inClass, body);
end moveClassInClass;

protected function moveClassInClassParts
  input String inName;
  input Integer inOffset;
  input list<Absyn.ClassPart> inClassParts;
  output list<Absyn.ClassPart> outClassParts = inClassParts;
protected
  Absyn.ClassPart part;
  list<Absyn.ClassPart> acc = {}, rest = inClassParts, parts;
  Option<Absyn.ElementItem> cls = NONE();
  Integer offset;
  Boolean is_public, is_empty;
algorithm
  // Go through the parts until we find the one containing the named class.
  while true loop
    part :: rest := rest;
    (part, cls, offset, is_public) := moveClassInClassPart(inName, inOffset, part);

    if isSome(cls) then
      break;
    else
      acc := part :: acc;
    end if;
  end while;

  is_empty := AbsynUtil.isEmptyClassPart(part);
  // Operate on either rest or acc depending on offset direction.
  parts := if offset > 0 then rest else acc;

  if listEmpty(parts) and offset <> 0 then
    // No parts left but offset isn't 0, insert the class at the end.
    parts := moveClassInClassParts3(Util.getOption(cls), offset < 0, is_public, part, parts);
  else
    // Otherwise, keeps moving the class until it's in the correct part.
    parts := moveClassInClassParts2(Util.getOption(cls), offset, is_public, parts);

    if not is_empty then
      // Only add the part we moved the class from if it contains something.
      parts := part :: parts;
    end if;
  end if;

  if offset > 0 then
    rest := parts;
  else
    acc := parts;
  end if;

  // If the part we moved the class from is empty, try to merge the surrounding
  // parts so that repeated moving don't fragment the class.
  if is_empty and not listEmpty(rest) then
    part :: rest := rest;
    acc := mergeClassPartWithList(part, acc);
  end if;

  outClassParts := List.append_reverse(acc, rest);
end moveClassInClassParts;

protected function mergeClassPartWithList
  "Tries to merge the given class part with the first part in the list. If they
   are not the same type it just adds the part to the head of the list instead."
  input Absyn.ClassPart inClassPart;
  input list<Absyn.ClassPart> inClassParts;
  output list<Absyn.ClassPart> outClassParts;
protected
  Absyn.ClassPart part;
  list<Absyn.ClassPart> rest;
algorithm
  outClassParts := match (inClassPart, inClassParts)
    case (Absyn.PUBLIC(), (part as Absyn.PUBLIC()) :: rest)
      then Absyn.PUBLIC(listAppend(part.contents, inClassPart.contents)) :: rest;
    case (Absyn.PROTECTED(), (part as Absyn.PROTECTED()) :: rest)
      then Absyn.PROTECTED(listAppend(part.contents, inClassPart.contents)) :: rest;
    else inClassPart :: inClassParts;
  end match;
end mergeClassPartWithList;

protected function moveClassInClassParts2
  "Helper function to moveClassInClassParts. Inserts the class into the correct
   class part."
  input Absyn.ElementItem inClass;
  input Integer inOffset;
  input Boolean inIsPublic;
  input list<Absyn.ClassPart> inClassParts;
  output list<Absyn.ClassPart> outClassParts;
protected
  Absyn.ClassPart part;
  list<Absyn.ClassPart> rest = inClassParts, parts, acc = {};
  Integer offset = inOffset;
  Boolean moved;
algorithm
  // Loop while we still have some offset to move the class.
  while offset <> 0 loop
    part :: rest := rest;
    // Move the class through the next part.
    (parts, offset, moved) := moveClassInClassPart3(inClass, offset, inIsPublic, part);

    if listEmpty(rest) and not moved then
      // We ran out of class parts, add the class at the end.
      acc := moveClassInClassParts3(inClass, inOffset > 0, inIsPublic, part, acc);
      break;
    elseif offset == 0 and not moved then
      // The offset is zero, but the class still hasn't been inserted anywhere.
      // This happens when the class was just moved outside the current part,
      // and should be inserted into the next one.
      // Add the parts we've just processed.
      acc := listAppend(parts, acc);
      // Add the class to the next part if it has the same protection, otherwise
      // create a new part for it.
      part :: rest := rest;
      acc := moveClassInClassParts3(inClass, inOffset > 0, inIsPublic, part, acc);
      break;
    end if;

    acc := listAppend(if inOffset > 0 then parts else listReverse(parts), acc);
  end while;

  outClassParts := List.append_reverse(acc, rest);
end moveClassInClassParts2;

protected function moveClassInClassParts3
  "Helper function to moveClassInClassParts2. Inserts a class into a given class
   part if they have the same protection, or create a new part for the class
   otherwise. Then the part(s) are added to the given list of parts."
  input Absyn.ElementItem inClass;
  input Boolean inPositiveOffset;
  input Boolean inIsPublic;
  input Absyn.ClassPart inClassPart;
  input list<Absyn.ClassPart> inClassParts;
  output list<Absyn.ClassPart> outClassParts;
algorithm
  outClassParts := match (inPositiveOffset, inIsPublic, inClassPart)
    case (true,  true,  Absyn.PUBLIC())
      then Absyn.PUBLIC(inClass :: inClassPart.contents) :: inClassParts;
    case (true,  false, Absyn.PROTECTED())
      then Absyn.PROTECTED(inClass :: inClassPart.contents) :: inClassParts;
    case (false, true,  Absyn.PUBLIC())
      then Absyn.PUBLIC(listAppend(inClassPart.contents, {inClass})) :: inClassParts;
    case (false, false, Absyn.PROTECTED())
      then Absyn.PROTECTED(listAppend(inClassPart.contents, {inClass})) :: inClassParts;
    case (_,  true,  _)
      then Absyn.PUBLIC({inClass}) :: inClassPart :: inClassParts;
    case (_,  false, _)
      then Absyn.PROTECTED({inClass}) :: inClassPart :: inClassParts;
  end match;
end moveClassInClassParts3;

protected function moveClassInClassPart
  "Moves a named class a certain offset within a single class part."
  input String inName;
  input Integer inOffset;
  input Absyn.ClassPart inClassPart;
  output Absyn.ClassPart outClassPart = inClassPart;
  output Option<Absyn.ElementItem> outClass;
  output Integer outRemainingOffset;
  output Boolean outIsPublic;
protected
  list<Absyn.ElementItem> elements;
algorithm
  (outClassPart, outClass, outRemainingOffset, outIsPublic) := match outClassPart
    case Absyn.PUBLIC()
      algorithm
        (elements, outClass, outRemainingOffset) :=
          moveClassInClassPart2(inName, inOffset, outClassPart.contents);
        outClassPart.contents := elements;
      then
        (outClassPart, outClass, outRemainingOffset, true);

    case Absyn.PROTECTED()
      algorithm
        (elements, outClass, outRemainingOffset) :=
          moveClassInClassPart2(inName, inOffset, outClassPart.contents);
        outClassPart.contents := elements;
      then
        (outClassPart, outClass, outRemainingOffset, false);

    else (outClassPart, NONE(), inOffset, false);
  end match;
end moveClassInClassPart;

protected function moveClassInClassPart2
  "Helper function to moveClassInClassPart. Moves a named class a certain offset
   within a list of element items."
  input String inName;
  input Integer inOffset;
  input list<Absyn.ElementItem> inElements;
  output list<Absyn.ElementItem> outElements;
  output Option<Absyn.ElementItem> outClass = NONE();
  output Integer outRemainingOffset;
protected
  Absyn.ElementItem e;
  list<Absyn.ElementItem> elements = inElements, acc = {};
algorithm
  // Try to find an element item containing the class we're looking for.
  while not listEmpty(elements) loop
    e :: elements := elements;

    if AbsynUtil.isElementItemClassNamed(inName, e) then
      // Found the class, exit the loop.
      outClass := SOME(e);
      break;
    else
      acc := e :: acc;
    end if;
  end while;

  // No class found.
  if isNone(outClass) then
    outElements := inElements;
    outRemainingOffset := inOffset;
    return;
  end if;

  // Try to move the class within the elements we have.
  (acc, elements, outRemainingOffset) :=
    moveClassInSplitClassPart(inOffset, acc, elements);

  // Insert the class again if it was moved within this class part. Otherwise it needs
  // to be moved into another class part, which is handled by moveClassInClassParts.
  if outRemainingOffset == 0 then
    elements := e :: elements;
  end if;

  outElements := List.append_reverse(acc, elements);
end moveClassInClassPart2;

protected function makeClassPart
  input list<Absyn.ElementItem> inElements;
  input Boolean inPublic;
  output Absyn.ClassPart outPart =
    if inPublic then Absyn.PUBLIC(inElements) else Absyn.PROTECTED(inElements);
end makeClassPart;

protected function moveClassInClassPart3
  "Helper function to moveClassInClassParts2. Moves a class a certain offset in
   a given class part."
  input Absyn.ElementItem inClass;
  input Integer inOffset;
  input Boolean inIsPublic;
  input Absyn.ClassPart inClassPart;
  output list<Absyn.ClassPart> outClassParts;
  output Integer outRemainingOffset;
  output Boolean outMoved = false;
protected
  Boolean same_part_type, reached_end;
  list<Absyn.ElementItem> elems_before, elems_after, elems;
algorithm
  // Fetch the elements of the part, and remember if it has the same protection
  // as the class to be moved.
  (elems, same_part_type) := match inClassPart
    case Absyn.PUBLIC() then (inClassPart.contents, inIsPublic);
    case Absyn.PROTECTED() then (inClassPart.contents, not inIsPublic);
  end match;

  // Use moveClassInSplitClassPart to shuffle elements.
  if inOffset > 0 then
    elems_before := {};
    elems_after := elems;
  else
    elems_before := elems;
    elems_after := {};
  end if;

  (elems_before, elems_after, outRemainingOffset, reached_end) :=
    moveClassInSplitClassPart(inOffset, listReverse(elems_before), elems_after);

  // No remaining offset, the class has been moved to where it should be.
  if outRemainingOffset == 0 then
    if same_part_type then
      // The class and the class part has the same protection, insert the class
      // into the part.
      elems := List.append_reverse(elems_before, inClass :: elems_after);
      outClassParts := {makeClassPart(elems, inIsPublic)};
      outMoved := true;
    elseif not reached_end then
      // If we did not reach the end, and the protection isn't the same, split
      // the class part into three potential parts, with the class in its own
      // part in the middle.
      outClassParts := if listEmpty(elems_before) then {} else
        {makeClassPart(listReverse(elems_before), not inIsPublic)};
      outClassParts := makeClassPart({inClass}, inIsPublic) :: outClassParts;
      if not listEmpty(elems_after) then
        outClassParts := makeClassPart(elems_after, not inIsPublic) :: outClassParts;
      end if;
      outMoved := true;
    else
      // Different protection, and we did reach the end. In that case the class
      // should be moved into the next part, if that part has the same
      // protection. We don't know that here, so we return the class part as it
      // is and let moveClassInClassParts2 sort it out.
      outClassParts := {inClassPart};
    end if;
  else
    outClassParts := {inClassPart};
  end if;
end moveClassInClassPart3;

protected function moveClassInSplitClassPart
  "Takes two lists of element items and an offset. Moves elements from one list
   to the other until offset number of classes has been moved or the end in
   either direction has been reached."
  input Integer inOffset;
  input list<Absyn.ElementItem> inElementsBefore;
  input list<Absyn.ElementItem> inElementsAfter;
  output list<Absyn.ElementItem> outElementsBefore = inElementsBefore;
  output list<Absyn.ElementItem> outElementsAfter = inElementsAfter;
  output Integer outRemainingOffset = inOffset;
  output Boolean outReachedEnd;
protected
  Absyn.ElementItem e;
algorithm
  if inOffset > 0 then
    // Positive offset, move elements from after to before.
    while outRemainingOffset > 0 loop
      if listEmpty(outElementsAfter) then // No more elements, we're done.
        break;
      else
        e :: outElementsAfter := outElementsAfter;
        outElementsBefore := e :: outElementsBefore;

        // Decrease the offset for each class we move.
        if AbsynUtil.isElementItemClass(e) then
          outRemainingOffset := outRemainingOffset - 1;
        end if;
      end if;
    end while;
    outReachedEnd := listEmpty(outElementsAfter);
  else
    // Negative offset, move elements from before to after.
    while outRemainingOffset < 0 loop
      if listEmpty(outElementsBefore) then // No more elements, we're done.
        break;
      else
        e :: outElementsBefore := outElementsBefore;
        outElementsAfter := e :: outElementsAfter;

        // Increase the offset for each class we move.
        if AbsynUtil.isElementItemClass(e) then
          outRemainingOffset := outRemainingOffset + 1;
        end if;
      end if;
    end while;
    outReachedEnd := listEmpty(outElementsBefore);
  end if;
end moveClassInSplitClassPart;

protected function deleteClassInClassPart
  input String inName;
  input Absyn.ClassPart inClassPart;
  output Absyn.ClassPart outClassPart = inClassPart;
  output Option<Absyn.ElementItem> outClass;
protected
  list<Absyn.ElementItem> elements;
algorithm
  (outClassPart, outClass) := match outClassPart
    case Absyn.PUBLIC()
      algorithm
        (elements, outClass) := List.deleteMemberOnTrue(inName,
          outClassPart.contents, AbsynUtil.isElementItemClassNamed);
        outClassPart.contents := elements;
      then
        (outClassPart, outClass);

    case Absyn.PROTECTED()
      algorithm
        (elements, outClass) := List.deleteMemberOnTrue(inName,
          outClassPart.contents, AbsynUtil.isElementItemClassNamed);
        outClassPart.contents := elements;
      then
        (outClassPart, outClass);

    else (outClassPart, NONE());
  end match;
end deleteClassInClassPart;

protected function moveClassToTopInClass
  input String inName;
  input Absyn.Class inClass;
  output Absyn.Class outClass;
protected
  Absyn.ClassDef body;
algorithm
  Absyn.CLASS(body = body) := inClass;

  body := match body
    case Absyn.PARTS()
      algorithm
        body.classParts := moveClassToTopInClassParts(inName, body.classParts);
      then
        body;

    case Absyn.CLASS_EXTENDS()
      algorithm
        body.parts := moveClassToTopInClassParts(inName, body.parts);
      then
        body;

  end match;

  outClass := AbsynUtil.setClassBody(inClass, body);
end moveClassToTopInClass;

protected function moveClassToTopInClassParts
  input String inName;
  input list<Absyn.ClassPart> inClassParts;
  output list<Absyn.ClassPart> outClassParts;
protected
  Absyn.ClassPart part, first;
  list<Absyn.ClassPart> acc = {}, rest = inClassParts;
  Option<Absyn.ElementItem> ocls;
  Absyn.ElementItem cls;
  Boolean is_public;
algorithm
  while true loop
    part :: rest := rest;
    (part, ocls) := deleteClassInClassPart(inName, part);

    if isSome(ocls) then
      // Remove the part if it's now empty and not the only part.
      if not AbsynUtil.isEmptyClassPart(part) or listEmpty(acc) or listEmpty(rest) then
        rest := part :: rest;
      end if;
      outClassParts := List.append_reverse(acc, rest);
      break;
    else
      acc := part :: acc;
    end if;
  end while;

  SOME(cls) := ocls;
  first :: rest := outClassParts;

  outClassParts := match (first, part)
    case (Absyn.PUBLIC(), Absyn.PUBLIC())
      algorithm
        first.contents := cls :: first.contents;
      then
        first :: rest;
    case (Absyn.PROTECTED(), Absyn.PROTECTED())
      algorithm
        first.contents := cls :: first.contents;
      then
        first :: rest;
    case (_, Absyn.PUBLIC()) then Absyn.PUBLIC({cls}) :: first :: rest;
    case (_, Absyn.PROTECTED()) then Absyn.PROTECTED({cls}) :: first :: rest;
  end match;
end moveClassToTopInClassParts;

protected function moveClassToBottomInClass
  input String inName;
  input Absyn.Class inClass;
  output Absyn.Class outClass;
protected
  Absyn.ClassDef body;
algorithm
  Absyn.CLASS(body = body) := inClass;

  body := match body
    case Absyn.PARTS()
      algorithm
        body.classParts := moveClassToBottomInClassParts(inName, body.classParts);
      then
        body;

    case Absyn.CLASS_EXTENDS()
      algorithm
        body.parts := moveClassToBottomInClassParts(inName, body.parts);
      then
        body;

  end match;

  outClass := AbsynUtil.setClassBody(inClass, body);
end moveClassToBottomInClass;

protected function moveClassToBottomInClassParts
  input String inName;
  input list<Absyn.ClassPart> inClassParts;
  output list<Absyn.ClassPart> outClassParts;
protected
  Absyn.ClassPart part, last;
  list<Absyn.ClassPart> acc = {}, rest = inClassParts;
  Option<Absyn.ElementItem> ocls;
  Absyn.ElementItem cls;
  Boolean is_public;
algorithm
  while true loop
    part :: rest := rest;
    (part, ocls) := deleteClassInClassPart(inName, part);

    if isSome(ocls) then
      break;
    else
      acc := part :: acc;
    end if;
  end while;

  SOME(cls) := ocls;

  // Remove the part if it's empty and not the only remaining part.
  if not AbsynUtil.isEmptyClassPart(part) or listEmpty(rest) then
    rest := part :: rest;
  end if;

  last :: rest := listReverse(rest);

  rest := match (last, part)
    case (Absyn.PUBLIC(), Absyn.PUBLIC())
      algorithm
        last.contents := listAppend(last.contents, {cls});
      then
        last :: rest;
    case (Absyn.PROTECTED(), Absyn.PROTECTED())
      algorithm
        last.contents := listAppend(last.contents, {cls});
      then
        last :: rest;
    case (_, Absyn.PUBLIC()) then Absyn.PUBLIC({cls}) :: last :: rest;
    case (_, Absyn.PROTECTED()) then Absyn.PROTECTED({cls}) :: last :: rest;
  end match;

  outClassParts := List.append_reverse(acc, listReverse(rest));
end moveClassToBottomInClassParts;

protected function copyClass
  input Absyn.Class inClass;
  input String inName;
  input Absyn.Within inWithin;
  input Absyn.Path inClassPath;
  input Absyn.Program inProg;
  output Absyn.Program outProg;
protected
  Absyn.Class cls;
  String orig_file, dst_path;
  Absyn.Path cls_path = inClassPath;
algorithm
  Absyn.CLASS(info = SOURCEINFO(fileName = orig_file)) := inClass;

  dst_path := match inWithin
    // Destination is top scope, put the copy in a new file.
    case Absyn.TOP() then "<interactive>";

    // Destination is within another class, put the copy in the same file as the
    // destination class.
    case Absyn.WITHIN()
      algorithm
        Absyn.CLASS(info = SOURCEINFO(fileName = dst_path)) :=
          Interactive.getPathedClassInProgram(inWithin.path, inProg);
      then
        dst_path;

  end match;

  // Replace the filename of each element with the new path.
  cls := moveClassInfo(inClass, dst_path);
  // Change the name of the class and put it in as a copy in the program.
  cls := AbsynUtil.setClassName(cls, inName);
  outProg := Interactive.updateProgram(Absyn.PROGRAM({cls}, inWithin), inProg);
end copyClass;

protected function moveSourceInfo
  input SourceInfo inInfo;
  input String dstPath;
  output SourceInfo outInfo = inInfo;
algorithm
  _ := match outInfo

    case SOURCEINFO()
      algorithm
        outInfo.fileName := dstPath;
        outInfo.isReadOnly := false;
      then
        ();

  end match;
end moveSourceInfo;

protected function moveClassInfo
  input Absyn.Class inClass;
  input String dstPath;
  output Absyn.Class outClass = inClass;
protected
  SourceInfo info;
algorithm
  _ := match outClass
    case Absyn.CLASS(info = info as SOURCEINFO())
      algorithm
        outClass.body := moveClassDefInfo(outClass.body, dstPath);
        outClass.info := moveSourceInfo(info, dstPath);
      then
        ();
  end match;
end moveClassInfo;

protected function moveClassDefInfo
  input Absyn.ClassDef inClassDef;
  input String dstPath;
  output Absyn.ClassDef outClassDef = inClassDef;
algorithm
  _ := match outClassDef
    case Absyn.PARTS()
      algorithm
        outClassDef.classParts := list(moveClassPartInfo(cp, dstPath)
          for cp in outClassDef.classParts);
        outClassDef.ann := list(moveAnnotationInfo(a, dstPath)
          for a in outClassDef.ann);
      then
        ();

    case Absyn.DERIVED()
      algorithm
        outClassDef.arguments := list(moveElementArgInfo(e, dstPath)
          for e in outClassDef.arguments);
          outClassDef.comment := moveCommentInfo(outClassDef.comment, dstPath);
      then
        ();

    case Absyn.ENUMERATION()
      algorithm
        outClassDef.comment := moveCommentInfo(outClassDef.comment, dstPath);
      then
        ();

    case Absyn.OVERLOAD()
      algorithm
        outClassDef.comment := moveCommentInfo(outClassDef.comment, dstPath);
      then
        ();

    case Absyn.CLASS_EXTENDS()
      algorithm
        outClassDef.modifications := list(moveElementArgInfo(e, dstPath)
          for e in outClassDef.modifications);
        outClassDef.parts := list(moveClassPartInfo(cp, dstPath)
          for cp in outClassDef.parts);
        outClassDef.ann := list(moveAnnotationInfo(a, dstPath)
           for a in outClassDef.ann);
      then
        ();

    case Absyn.PDER()
      algorithm
        outClassDef.comment := moveCommentInfo(outClassDef.comment, dstPath);
      then
        ();

    else ();
  end match;
end moveClassDefInfo;

protected function moveClassPartInfo
  input Absyn.ClassPart inPart;
  input String dstPath;
  output Absyn.ClassPart outPart;
algorithm
  outPart := match inPart
    local
      list<Absyn.ElementItem> el;
      list<Absyn.EquationItem> eq;
      list<Absyn.AlgorithmItem> alg;
      Absyn.ExternalDecl ext;
      Option<Absyn.Annotation> ann;

    case Absyn.PUBLIC(el)
      then Absyn.PUBLIC(list(moveElementItemInfo(e, dstPath) for e in el));

    case Absyn.PROTECTED(el)
      then Absyn.PROTECTED(list(moveElementItemInfo(e, dstPath) for e in el));

    case Absyn.EQUATIONS(eq)
      then Absyn.EQUATIONS(list(moveEquationItemInfo(e, dstPath) for e in eq));

    case Absyn.INITIALEQUATIONS(eq)
      then Absyn.INITIALEQUATIONS(list(moveEquationItemInfo(e, dstPath) for e in eq));

    case Absyn.ALGORITHMS(alg)
      then Absyn.ALGORITHMS(list(moveAlgorithmItemInfo(e, dstPath) for e in alg));

    case Absyn.INITIALALGORITHMS(alg)
      then Absyn.INITIALALGORITHMS(list(moveAlgorithmItemInfo(e, dstPath) for e in alg));

    case Absyn.EXTERNAL(ext, ann)
      algorithm
        ext := moveExternalDeclInfo(ext, dstPath);
        ann := moveAnnotationOptInfo(ann, dstPath);
      then
        Absyn.EXTERNAL(ext, ann);

    else inPart;
  end match;
end moveClassPartInfo;

protected function moveAnnotationOptInfo
  input Option<Absyn.Annotation> inAnnotation;
  input String dstPath;
  output Option<Absyn.Annotation> outAnnotation;
algorithm
  outAnnotation := match inAnnotation
    local
      Absyn.Annotation a;

    case SOME(a) then SOME(moveAnnotationInfo(a, dstPath));
    else inAnnotation;
  end match;
end moveAnnotationOptInfo;

protected function moveAnnotationInfo
  input Absyn.Annotation inAnnotation;
  input String dstPath;
  output Absyn.Annotation outAnnotation = inAnnotation;
algorithm
  _ := match outAnnotation
    case Absyn.ANNOTATION()
      algorithm
        outAnnotation.elementArgs := list(moveElementArgInfo(e, dstPath)
          for e in outAnnotation.elementArgs);
      then
        ();
  end match;
end moveAnnotationInfo;

protected function moveElementItemInfo
  input Absyn.ElementItem inElement;
  input String dstPath;
  output Absyn.ElementItem outElement;
algorithm
  outElement := match inElement
    case Absyn.ELEMENTITEM()
      then Absyn.ELEMENTITEM(moveElementInfo(inElement.element, dstPath));
    else inElement;
  end match;
end moveElementItemInfo;

protected function moveElementInfo
  input Absyn.Element inElement;
  input String dstPath;
  output Absyn.Element outElement = inElement;
algorithm
  _ := match outElement
    case Absyn.ELEMENT()
      algorithm
        outElement.specification := moveElementSpecInfo(outElement.specification, dstPath);
        outElement.constrainClass := moveConstrainClassInfo(outElement.constrainClass, dstPath);
        outElement.info := moveSourceInfo(outElement.info, dstPath);
      then
        ();

    case Absyn.TEXT()
      algorithm
        outElement.info := moveSourceInfo(outElement.info, dstPath);
      then
        ();

    else ();
  end match;
end moveElementInfo;

protected function moveElementArgInfo
  input Absyn.ElementArg inArg;
  input String dstPath;
  output Absyn.ElementArg outArg = inArg;
algorithm
  _ := match outArg
    case Absyn.MODIFICATION()
      algorithm
        outArg.modification := moveModificationInfo(outArg.modification, dstPath);
        outArg.info := moveSourceInfo(outArg.info, dstPath);
      then
        ();

    case Absyn.REDECLARATION()
      algorithm
        outArg.elementSpec := moveElementSpecInfo(outArg.elementSpec, dstPath);
        outArg.constrainClass := moveConstrainClassInfo(outArg.constrainClass, dstPath);
        outArg.info := moveSourceInfo(outArg.info, dstPath);
      then
        ();

  end match;
end moveElementArgInfo;

protected function moveModificationInfo
  input Option<Absyn.Modification> inMod;
  input String dstPath;
  output Option<Absyn.Modification> outMod;
algorithm
  outMod := match inMod
    local
      list<Absyn.ElementArg> el;
      Absyn.EqMod eq;

    case SOME(Absyn.CLASSMOD(el, eq))
      algorithm
        el := list(moveElementArgInfo(e, dstPath) for e in el);
        eq := moveEqModInfo(eq, dstPath);
      then
        SOME(Absyn.CLASSMOD(el, eq));

    else inMod;
  end match;
end moveModificationInfo;

protected function moveEqModInfo
  input Absyn.EqMod inEqMod;
  input String dstPath;
  output Absyn.EqMod outEqMod;
algorithm
  outEqMod := match inEqMod
    case Absyn.EQMOD()
      then Absyn.EQMOD(inEqMod.exp, moveSourceInfo(inEqMod.info, dstPath));
    else inEqMod;
  end match;
end moveEqModInfo;

protected function moveConstrainClassInfo
  input Option<Absyn.ConstrainClass> inCC;
  input String dstPath;
  output Option<Absyn.ConstrainClass> outCC;
algorithm
  outCC := match inCC
    local
      Absyn.ElementSpec spec;
      Option<Absyn.Comment> cmt;

    case SOME(Absyn.CONSTRAINCLASS(spec, cmt))
      algorithm
        spec := moveElementSpecInfo(spec, dstPath);
        cmt := moveCommentInfo(cmt, dstPath);
      then
        SOME(Absyn.CONSTRAINCLASS(spec, cmt));

    else inCC;
  end match;
end moveConstrainClassInfo;

protected function moveCommentInfo
  input Option<Absyn.Comment> inComment;
  input String dstPath;
  output Option<Absyn.Comment> outComment;
algorithm
  outComment := match inComment
    local
      Absyn.Annotation a;
      Option<String> c;

    case SOME(Absyn.COMMENT(SOME(a), c))
      algorithm
        a := moveAnnotationInfo(a, dstPath);
      then
        SOME(Absyn.COMMENT(SOME(a), c));

    else inComment;
  end match;
end moveCommentInfo;

protected function moveEquationItemInfo
  input Absyn.EquationItem inEquation;
  input String dstPath;
  output Absyn.EquationItem outEquation;
algorithm
  outEquation := match inEquation
    local
      Absyn.Equation eq;
      Option<Absyn.Comment> cmt;
      SourceInfo info;

    case Absyn.EQUATIONITEM(eq, cmt, info)
      algorithm
        cmt := moveCommentInfo(cmt, dstPath);
        info := moveSourceInfo(info, dstPath);
      then
        Absyn.EQUATIONITEM(eq, cmt, info);

    else inEquation;
  end match;
end moveEquationItemInfo;

protected function moveAlgorithmItemInfo
  input Absyn.AlgorithmItem inAlgorithm;
  input String dstPath;
  output Absyn.AlgorithmItem outAlgorithm;
algorithm
  outAlgorithm := match inAlgorithm
    local
      Absyn.Algorithm alg;
      Option<Absyn.Comment> cmt;
      SourceInfo info;

    case Absyn.ALGORITHMITEM(alg, cmt, info)
      algorithm
        cmt := moveCommentInfo(cmt, dstPath);
        info := moveSourceInfo(info, dstPath);
      then
        Absyn.ALGORITHMITEM(alg, cmt, info);

    else inAlgorithm;
  end match;
end moveAlgorithmItemInfo;

protected function moveElementSpecInfo
  input Absyn.ElementSpec inSpec;
  input String dstPath;
  output Absyn.ElementSpec outSpec = inSpec;
algorithm
  _ := match outSpec
    case Absyn.CLASSDEF()
      algorithm
        outSpec.class_ := moveClassInfo(outSpec.class_, dstPath);
      then
        ();

    case Absyn.EXTENDS()
      algorithm
        outSpec.elementArg := list(moveElementArgInfo(e, dstPath)
          for e in outSpec.elementArg);
        outSpec.annotationOpt := moveAnnotationOptInfo(outSpec.annotationOpt, dstPath);
      then
        ();

    case Absyn.IMPORT()
      algorithm
        outSpec.comment := moveCommentInfo(outSpec.comment, dstPath);
        outSpec.info := moveSourceInfo(outSpec.info, dstPath);
      then
        ();

    case Absyn.COMPONENTS()
      algorithm
        outSpec.components := list(moveComponentItemInfo(c, dstPath)
          for c in outSpec.components);
      then
        ();

  end match;
end moveElementSpecInfo;

protected function moveComponentItemInfo
  input Absyn.ComponentItem inComponent;
  input String dstPath;
  output Absyn.ComponentItem outComponent;
protected
  Absyn.Component comp;
  Option<Absyn.ComponentCondition> cond;
  Option<Absyn.Comment> cmt;
algorithm
  Absyn.COMPONENTITEM(comp, cond, cmt) := inComponent;
  comp := moveComponentInfo(comp, dstPath);
  cmt := moveCommentInfo(cmt, dstPath);
  outComponent := Absyn.COMPONENTITEM(comp, cond, cmt);
end moveComponentItemInfo;

protected function moveComponentInfo
  input Absyn.Component inComponent;
  input String dstPath;
  output Absyn.Component outComponent = inComponent;
algorithm
  _ := match outComponent
    case Absyn.COMPONENT()
      algorithm
        outComponent.modification :=
          moveModificationInfo(outComponent.modification, dstPath);
      then
        ();
  end match;
end moveComponentInfo;

protected function moveExternalDeclInfo
  input Absyn.ExternalDecl inExtDecl;
  input String dstPath;
  output Absyn.ExternalDecl outExtDecl = inExtDecl;
algorithm
  _ := match outExtDecl
    case Absyn.EXTERNALDECL()
      algorithm
        outExtDecl.annotation_ :=
          moveAnnotationOptInfo(outExtDecl.annotation_, dstPath);
      then
        ();
  end match;
end moveExternalDeclInfo;

protected function buildModel "translates and builds the model by running compiler script on the generated makefile"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Values.Value> inValues;
  input Absyn.Msg inMsg;
  output Boolean success=false;
  output FCore.Cache outCache;
  output String compileDir;
  output String outString1 "className";
  output String outString2 "method";
  output String outputFormat_str;
  output String outInitFileName "initFileName";
  output String outSimFlags;
  output list<tuple<String,Values.Value>> resultValues;
  output list<Values.Value> outArgs;
algorithm
  (outCache,compileDir,outString1,outString2,outputFormat_str,outInitFileName,outSimFlags,resultValues,outArgs):=
  matchcontinue (inCache,inEnv,inValues,inMsg)
    local
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
      Option<Absyn.Modification> simflags_mod;

    // compile the model
    case (cache,env,vals,msg)
      algorithm
        // buildModel expects these arguments:
        // className, startTime, stopTime, numberOfIntervals, tolerance, method, fileNamePrefix,
        // options, outputFormat, variableFilter, cflags, simflags
        values := vals;
        (Values.CODE(Absyn.C_TYPENAME(classname)),vals) := getListFirstShowError(vals, "while retreaving the className (1 arg) from the buildModel arguments");
        (_,vals) := getListFirstShowError(vals, "while retreaving the startTime (2 arg) from the buildModel arguments");
        (_,vals) := getListFirstShowError(vals, "while retreaving the stopTime (3 arg) from the buildModel arguments");
        (_,vals) := getListFirstShowError(vals, "while retreaving the numberOfIntervals (4 arg) from the buildModel arguments");
        (_,vals) := getListFirstShowError(vals, "while retreaving the tolerance (5 arg) from the buildModel arguments");
        (_,vals) := getListFirstShowError(vals, "while retreaving the method (6 arg) from the buildModel arguments");
        (Values.STRING(filenameprefix),vals) := getListFirstShowError(vals, "while retreaving the fileNamePrefix (7 arg) from the buildModel arguments");
       
        
        (_,vals) := getListFirstShowError(vals, "while retreaving the options (8 arg) from the buildModel arguments");
        (_,vals) := getListFirstShowError(vals, "while retreaving the outputFormat (9 arg) from the buildModel arguments");
        (_,vals) := getListFirstShowError(vals, "while retreaving the variableFilter (10 arg) from the buildModel arguments");
        (_,vals) := getListFirstShowError(vals, "while retreaving the cflags (11 arg) from the buildModel arguments");
        (Values.STRING(simflags),vals) := getListFirstShowError(vals, "while retreaving the simflags (12 arg) from the buildModel arguments");

        Error.clearMessages() "Clear messages";

        // If simflags is empty and --ignoreSimulationFlagsAnnotation isn't used,
        // use the __OpenModelica_simulationFlags annotation in the class to be simulated.
        if stringEmpty(simflags) and not Flags.getConfigBool(Flags.IGNORE_SIMULATION_FLAGS_ANNOTATION) then
          simflags_mod := Interactive.getNamedAnnotation(classname, SymbolTable.getAbsyn(),
            Absyn.IDENT("__OpenModelica_simulationFlags"), SOME(NONE()), Util.id);
          simflags := formatSimulationFlagsString(simflags_mod);

          if not stringEmpty(simflags) then
            values := List.replaceAt(Values.STRING(simflags), 12, values);
          end if;
        end if;

        compileDir := System.pwd() + Autoconf.pathDelimiter;
        (cache,simSettings) := calculateSimulationSettings(cache, env, values, msg);
        SimCode.SIMULATION_SETTINGS(method = method_str, outputFormat = outputFormat_str) := simSettings;

        (success,cache,libs,file_dir,resultValues) := translateModel(cache,env, classname, filenameprefix,true, SOME(simSettings));
        //cname_str = AbsynUtil.pathString(classname);
        //SimCodeUtil.generateInitData(indexed_dlow_1, classname, filenameprefix, init_filename,
        //  starttime_r, stoptime_r, interval_r, tolerance_r, method_str,options_str,outputFormat_str);

        System.realtimeTick(ClockIndexes.RT_CLOCK_BUILD_MODEL);
        init_filename := filenameprefix + "_init.xml"; //a hack ? should be at one place somewhere
        //win1 = getWithinStatement(classname);

        if Flags.isSet(Flags.DYN_LOAD) then
          Debug.traceln("buildModel: about to compile model " + filenameprefix + ", " + file_dir);
        end if;
        if success then
          try
            CevalScript.compileModel(filenameprefix, libs);
          else
            success := false;
          end try;
          timeCompile := System.realtimeTock(ClockIndexes.RT_CLOCK_BUILD_MODEL);
        else
          timeCompile := 0.0;
        end if;
        if Flags.isSet(Flags.DYN_LOAD) then
          Debug.trace("buildModel: Compiling done.\n");
        end if;
        resultValues := ("timeCompile",Values.REAL(timeCompile)) :: resultValues;
      then
        (cache,compileDir,filenameprefix,method_str,outputFormat_str,init_filename,simflags,resultValues,values);

    // failure
    else
      equation
        Error.assertion(listLength(inValues) == 12, "buildModel failure, length = " + intString(listLength(inValues)), AbsynUtil.dummyInfo);
      then fail();
  end matchcontinue;
end buildModel;

function formatSimulationFlagsString
  "Formats a modification in the format expected by the simflags argument to buildModel."
  input Option<Absyn.Modification> mod;
  output String str;
algorithm
  str := match mod
    local
      list<Absyn.ElementArg> args;

    case SOME(Absyn.CLASSMOD(elementArgLst = args))
      then List.toString(args, formatSimulationFlagString, "", "-", " -", "", false);

    else "";
  end match;
end formatSimulationFlagsString;

function formatSimulationFlagString
  input Absyn.ElementArg arg;
  output String str;
algorithm
  str := match arg
    local
      Absyn.Exp exp;

    case Absyn.ElementArg.MODIFICATION(modification =
        SOME(Absyn.Modification.CLASSMOD(eqMod = Absyn.EqMod.EQMOD(exp = exp))))
      then
        match exp
          case Absyn.STRING("()") then AbsynUtil.pathString(arg.path);
          else AbsynUtil.pathString(arg.path) + "=" + Dump.printExpStr(exp);
        end match;

    case Absyn.ElementArg.MODIFICATION()
      then AbsynUtil.pathString(arg.path);

  end match;
end formatSimulationFlagString;

protected function createSimulationResultFromcallModelExecutable
"This function calls the compiled simulation executable."
  input Boolean buildSuccess;
  input Integer callRet;
  input Real timeTotal;
  input Real timeSimulation;
  input list<tuple<String,Values.Value>> resultValues;
  input FCore.Cache inCache;
  input Absyn.Path className;
  input list<Values.Value> inVals;
  input String result_file;
  input String logFile;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) := matchcontinue (buildSuccess,callRet)
    local
      String res,str;
      Values.Value simValue;

    case (false,_)
      equation
        simValue = createSimulationResult(
           result_file,
           simOptionsAsString(inVals),
           "Failed to build model: " + AbsynUtil.pathString(className),
           ("timeTotal", Values.REAL(timeTotal)) ::
           ("timeSimulation", Values.REAL(timeSimulation)) ::
          resultValues);
      then (inCache,simValue);

    case (_,0)
      equation
        simValue = createSimulationResult(
           result_file,
           simOptionsAsString(inVals),
           System.readFile(logFile),
           ("timeTotal", Values.REAL(timeTotal)) ::
           ("timeSimulation", Values.REAL(timeSimulation)) ::
          resultValues);
        SymbolTable.addVar(
          DAE.CREF_IDENT("currentSimulationResult", DAE.T_STRING_DEFAULT, {}),
          Values.STRING(result_file), FGraph.empty());
      then
        (inCache,simValue);
    else
      equation
        res = if System.regularFileExists(logFile) then System.readFile(logFile) else (logFile + " does not exist");
        str = AbsynUtil.pathString(className);
        res = stringAppendList({"Simulation execution failed for model: ", str, "\n", res});
        simValue = createSimulationResult("", simOptionsAsString(inVals), res,
          ("timeTotal", Values.REAL(timeTotal)) ::
          ("timeSimulation", Values.REAL(timeSimulation)) ::
          resultValues);
      then
        (inCache,simValue);
  end matchcontinue;
end createSimulationResultFromcallModelExecutable;

protected function buildOpenTURNSInterface "builds the OpenTURNS interface by calling the OpenTURNS module"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Values.Value> vals;
  input Absyn.Msg inMsg;
  output FCore.Cache outCache;
  output String scriptFile;
algorithm
  (outCache,scriptFile):= match(inCache,inEnv,vals,inMsg)
    local
      String templateFile, str;
      Absyn.Program p;
      Absyn.Path className;
      FCore.Cache cache;
      DAE.DAElist dae;
      FCore.Graph env;
      BackendDAE.BackendDAE dlow;
      DAE.FunctionTree funcs;
      Boolean showFlatModelica;
      String filenameprefix,description;

    case(cache,_,{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(templateFile),Values.BOOL(showFlatModelica)},_)
      equation
        (cache,env,SOME(dae),_) = runFrontEnd(cache,inEnv,className,false);
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
        filenameprefix = AbsynUtil.pathString(className);
        description = DAEUtil.daeDescription(dae);
        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        //print("lowered class\n");
        //print("calling generateOpenTurnsInterface\n");
        scriptFile = OpenTURNS.generateOpenTURNSInterface(dlow, className, SymbolTable.getAbsyn(), templateFile);
      then
        (cache,scriptFile);

  end match;
end buildOpenTURNSInterface;

protected function runOpenTURNSPythonScript
"runs OpenTURNS with the given python script returning the log file"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Values.Value> vals;
  input Absyn.Msg inMsg;
  output FCore.Cache outCache;
  output String outLogFile;
algorithm
  (outCache,outLogFile):= match(inCache,inEnv,vals,inMsg)
    local
      String pythonScriptFile, logFile;
      FCore.Cache cache;
    case(cache,_,{Values.STRING(pythonScriptFile)},_)
      equation
        logFile = OpenTURNS.runPythonScript(pythonScriptFile);
      then
        (cache,logFile);
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
        p_class = AbsynUtil.crefToPath(class_) "change to the saved files directory" ;
        cdef = Interactive.getPathedClassInProgram(p_class, p);
        filename = AbsynUtil.classFilename(cdef);
        pd = Autoconf.pathDelimiter;
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
        pd = Autoconf.pathDelimiter;
        dir_1 = stringAppendList({"\"",omhome_1,pd,"work","\""});
      then
        dir_1;
    else "";  /* this function should never fail */
  end matchcontinue;
end getFileDir;

public function checkModel " checks a model and returns number of variables and equations"
  input output FCore.Cache cache;
  input FCore.Graph inEnv;
  input Absyn.Path className;
  output Values.Value outValue;
  input Absyn.Msg inMsg;
algorithm
  outValue := matchcontinue (inEnv,className,inMsg)
    local
      Option<DAE.DAElist> odae;
      DAE.DAElist dae;
      FCore.Graph env;
      Absyn.Program p;
      Absyn.Msg msg;
      Integer eqnSize,varSize,simpleEqnSize;
      String errorMsg,eqnSizeStr,varSizeStr,retStr,classNameStr,simpleEqnSizeStr;
      Boolean strEmpty;
      Absyn.Restriction restriction;
      Absyn.Class c;

    // handle normal models
    case (env,_,_)
      equation
        (cache,env,odae) = runFrontEnd(cache,env,className,false);
        SOME(dae) = odae;
        (varSize,eqnSize,simpleEqnSize) = CheckModel.checkModel(dae);
        eqnSizeStr = intString(eqnSize);
        varSizeStr = intString(varSize);
        simpleEqnSizeStr = intString(simpleEqnSize);

        classNameStr = AbsynUtil.pathString(className);
        retStr = stringAppendList({"Check of ",classNameStr," completed successfully.","\nClass ",classNameStr," has ",eqnSizeStr," equation(s) and ",
          varSizeStr," variable(s).\n",simpleEqnSizeStr," of these are trivial equation(s)."});
      then Values.STRING(retStr);

    // handle functions
    case (env,_,_)
      equation
        Absyn.CLASS(restriction=restriction) = Interactive.getPathedClassInProgram(className, SymbolTable.getAbsyn());
        true = AbsynUtil.isFunctionRestriction(restriction) or AbsynUtil.isPackageRestriction(restriction);
        (cache,env,_) = runFrontEnd(cache,env,className,true);
      then Values.STRING("");

    case (_,_,_)
      equation
        classNameStr = AbsynUtil.pathString(className);
        false = Interactive.existClass(AbsynUtil.pathToCref(className), SymbolTable.getAbsyn());
        Error.addMessage(Error.LOOKUP_ERROR, {classNameStr,"<TOP>"});
      then Values.STRING("");

    // errors
    else
      equation
        classNameStr = AbsynUtil.pathString(className);
        strEmpty = Error.getNumMessages() == 0;
        errorMsg = "Check of " + classNameStr + " failed with no error message";
        if strEmpty then
          Error.addMessage(Error.INTERNAL_ERROR, {errorMsg,"<TOP>"});
        end if;
      then Values.STRING("");

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
    case(path) equation path = AbsynUtil.stripLast(path); then Absyn.WITHIN(path);
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
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output DAE.DAElist outDae;
algorithm
  (outCache, outEnv, _, outDae) := Inst.instantiateClass(inCache, InnerOuter.emptyInstHierarchy, SymbolTable.getSCode(), inClassName);
  outDae := DAEUtil.transformationsBeforeBackend(outCache,outEnv,outDae);
end dumpXMLDAEFrontEnd;

protected function dumpXMLDAE " author: fildo
 This function outputs the DAE system corresponding to a specific model."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Values.Value> vals;
  input Absyn.Msg inMsg;
  output FCore.Cache outCache;
  output String xml_filename;
algorithm
  (outCache,xml_filename) :=
  matchcontinue (inCache,inEnv,vals,inMsg)
    local
      String cname_str,filenameprefix,compileDir,rewriteRulesFile,description;
      FCore.Graph env;
      Absyn.Path classname;
      Absyn.Program p;
      BackendDAE.BackendDAE dlow,dlow_1,indexed_dlow;
      FCore.Cache cache;
      Boolean addOriginalAdjacencyMatrix,addSolvingInfo,addMathMLCode,dumpResiduals;
      Absyn.Msg msg;
      DAE.DAElist dae_1,dae;
      list<SCode.Element> p_1;

    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="flat"),
                     Values.BOOL(addOriginalAdjacencyMatrix),Values.BOOL(addSolvingInfo),
                     Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),
                     Values.STRING(filenameprefix),Values.STRING(rewriteRulesFile)},_)
      equation
        Error.clearMessages() "Clear messages";

        // set the rewrite rules flag
        FlagsUtil.setConfigString(Flags.REWRITE_RULES_FILE, rewriteRulesFile);
        // load the rewrite rules
        RewriteRules.loadRules();

        (cache, env, dae) = dumpXMLDAEFrontEnd(cache, env, classname);
        description = DAEUtil.daeDescription(dae);

        compileDir = System.pwd() + Autoconf.pathDelimiter;
        cname_str = AbsynUtil.pathString(classname);
        filenameprefix = if filenameprefix == "<default>" then cname_str else filenameprefix;

        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix)); //Verificare cosa fa
        dlow_1 = BackendDAEUtil.preOptimizeBackendDAE(dlow,NONE());
        dlow_1 = FindZeroCrossings.findZeroCrossings(dlow_1);
        xml_filename = stringAppendList({filenameprefix,".xml"});

        // apply rewrite rules to the back-end
        dlow_1 = applyRewriteRulesOnBackend(dlow_1);

        Print.clearBuf();
        XMLDump.dumpBackendDAE(dlow_1,addOriginalAdjacencyMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,false);
        Print.writeBuf(xml_filename);
        Print.clearBuf();
        compileDir = if Testsuite.isRunning() then "" else compileDir;

        // clear the rewrite rules!
        FlagsUtil.setConfigString(Flags.REWRITE_RULES_FILE, "");
        RewriteRules.clearRules();
      then
        (cache,stringAppendList({compileDir,xml_filename}));

    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="optimiser"),
                     Values.BOOL(addOriginalAdjacencyMatrix),Values.BOOL(addSolvingInfo),
                     Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),
                     Values.STRING(filenameprefix),Values.STRING(rewriteRulesFile)},_)
      equation
        //asInSimulationCode==false => it's NOT necessary to do all the translation's steps before dumping with xml
        Error.clearMessages() "Clear messages";

        // set the rewrite rules flag
        FlagsUtil.setConfigString(Flags.REWRITE_RULES_FILE, rewriteRulesFile);
        // load the rewrite rules
        RewriteRules.loadRules();

        (cache, env, dae) = dumpXMLDAEFrontEnd(cache, env, classname);
        description = DAEUtil.daeDescription(dae);

        compileDir = System.pwd() + Autoconf.pathDelimiter;
        cname_str = AbsynUtil.pathString(classname);
        filenameprefix = if filenameprefix == "<default>" then cname_str else filenameprefix;

        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix)); //Verificare cosa fa
        dlow_1 = BackendDAEUtil.preOptimizeBackendDAE(dlow,NONE());
        dlow_1 = BackendDAEUtil.transformBackendDAE(dlow_1,NONE(),NONE(),NONE());
        dlow_1 = FindZeroCrossings.findZeroCrossings(dlow_1);
        xml_filename = stringAppendList({filenameprefix,".xml"});

        // apply rewrite rules to the back-end
        dlow_1 = applyRewriteRulesOnBackend(dlow_1);

        Print.clearBuf();
        XMLDump.dumpBackendDAE(dlow_1,addOriginalAdjacencyMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,false);
        Print.writeBuf(xml_filename);
        Print.clearBuf();
        compileDir = if Testsuite.isRunning() then "" else compileDir;

        // clear the rewrite rules!
        FlagsUtil.setConfigString(Flags.REWRITE_RULES_FILE, "");
        RewriteRules.clearRules();
      then
        (cache,stringAppendList({compileDir,xml_filename}));

    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="backEnd"),
                     Values.BOOL(addOriginalAdjacencyMatrix),Values.BOOL(addSolvingInfo),
                     Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),
                     Values.STRING(filenameprefix),Values.STRING(rewriteRulesFile)},_)
      equation
        //asInSimulationCode==true => it's necessary to do all the translation's steps before dumping with xml
        Error.clearMessages() "Clear messages";

        // set the rewrite rules flag
        FlagsUtil.setConfigString(Flags.REWRITE_RULES_FILE, rewriteRulesFile);
        // load the rewrite rules
        RewriteRules.loadRules();

        (cache, env, dae) = dumpXMLDAEFrontEnd(cache, env, classname);
        description = DAEUtil.daeDescription(dae);

        compileDir = System.pwd() + Autoconf.pathDelimiter;
        cname_str = AbsynUtil.pathString(classname);
        filenameprefix = if filenameprefix == "<default>" then cname_str else filenameprefix;

        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        indexed_dlow = BackendDAEUtil.getSolvedSystem(dlow,"");
        xml_filename = stringAppendList({filenameprefix,".xml"});

        // apply rewrite rules to the back-end
        indexed_dlow = applyRewriteRulesOnBackend(indexed_dlow);

        Print.clearBuf();
        XMLDump.dumpBackendDAE(indexed_dlow,addOriginalAdjacencyMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,false);
        Print.writeBuf(xml_filename);
        Print.clearBuf();
        compileDir = if Testsuite.isRunning() then "" else compileDir;

        // clear the rewrite rules!
        FlagsUtil.setConfigString(Flags.REWRITE_RULES_FILE, "");
        RewriteRules.clearRules();
      then
        (cache,stringAppendList({compileDir,xml_filename}));

    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="stateSpace"),
                     Values.BOOL(addOriginalAdjacencyMatrix),Values.BOOL(addSolvingInfo),
                     Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),
                     Values.STRING(filenameprefix),Values.STRING(rewriteRulesFile)},_)
      equation
        //asInSimulationCode==true => it's necessary to do all the translation's steps before dumping with xml
        Error.clearMessages() "Clear messages";

        // set the rewrite rules flag
        FlagsUtil.setConfigString(Flags.REWRITE_RULES_FILE, rewriteRulesFile);
        // load the rewrite rules
        RewriteRules.loadRules();

        (cache, env, dae) = dumpXMLDAEFrontEnd(cache, env, classname);
        description = DAEUtil.daeDescription(dae);

        compileDir = System.pwd() + Autoconf.pathDelimiter;
        cname_str = AbsynUtil.pathString(classname);
        filenameprefix = if filenameprefix == "<default>" then cname_str else filenameprefix;

        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        indexed_dlow = BackendDAEUtil.getSolvedSystem(dlow,"");
        xml_filename = stringAppendList({filenameprefix,".xml"});

        // apply rewrite rules to the back-end
        indexed_dlow = applyRewriteRulesOnBackend(indexed_dlow);

        Print.clearBuf();
        XMLDump.dumpBackendDAE(indexed_dlow,addOriginalAdjacencyMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,true);
        Print.writeBuf(xml_filename);
        Print.clearBuf();
        compileDir = if Testsuite.isRunning() then "" else compileDir;

        // clear the rewrite rules!
        FlagsUtil.setConfigString(Flags.REWRITE_RULES_FILE, "");
        RewriteRules.clearRules();
      then
        (cache,stringAppendList({compileDir,xml_filename}));

    else
    equation
        // clear the rewrite rules if we fail!
        FlagsUtil.setConfigString(Flags.REWRITE_RULES_FILE, "");
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
      BackendDAE.Variables vars_aliasVars;
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
        strlist = Interactive.getClassnamesInParts(parts,b,false);
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
        strlist = Interactive.getClassnamesInParts(parts,b,false);
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
        res = AbsynUtil.joinPaths(r, Absyn.IDENT(c));
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
        parent_string = AbsynUtil.pathString(inPath);
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
  input Absyn.Msg inMsg;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  matchcontinue (inCache,inEnv,className,inCheckProtected,inMsg)
    local
      list<Absyn.Path> allClassPaths;
      Absyn.Program p;
      Absyn.Msg msg;
      FCore.Cache cache;
      String ret;
      FCore.Graph env;
      Boolean b;
      Integer failed;

    case (cache,env,_,b,msg)
      equation
        allClassPaths = getAllClassPathsRecursive(className, b, SymbolTable.getAbsyn());
        print("Number of classes to check: " + intString(listLength(allClassPaths)) + "\n");
        // print ("All paths: \n" + stringDelimitList(List.map(allClassPaths, AbsynUtil.pathString), "\n") + "\n");
        failed = checkAll(cache, env, allClassPaths, msg, 0);
        ret = "Number of classes checked / failed: " + intString(listLength(allClassPaths)) + "/" + intString(failed);
      then
        (cache,Values.STRING(ret));

    case (cache,_,_,_,_)
      equation
        ret = stringAppend("Error checking: ", AbsynUtil.pathString(className));
    then
      (cache,Values.STRING(ret));
  end matchcontinue;
end checkAllModelsRecursive;

function failOrSuccess
"@author adrpo"
  input String inStr;
  output String outStr;
  output Boolean failed = false;
algorithm
  outStr := matchcontinue(inStr)
    local Integer res;
    case _
      algorithm
        res := System.stringFind(inStr, "successfully");
        true := (res >= 0);
        failed := false;
      then
        "OK";
    else
      algorithm
        failed := true;
      then
        "FAILED!";
  end matchcontinue;
end failOrSuccess;

function checkAll
"@author adrpo
 checks all models and returns number of variables and equations"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Path> allClasses;
  input Absyn.Msg inMsg;
  input output Integer failed;
protected
  Absyn.Program p;
algorithm
  p := SymbolTable.getAbsyn();
  _ := matchcontinue (inCache,inEnv,allClasses,inMsg)
    local
      list<Absyn.Path> rest;
      Absyn.Path className;
      Absyn.Msg msg;
      FCore.Cache cache;
      String  str, s, smsg;
      FCore.Graph env;
      Real t1, t2, elapsedTime;
      Absyn.ComponentRef cr;
      Absyn.Class c;
      Boolean f = false;

    case (_,_,{},_) then ();

    case (cache,env,className::rest,msg)
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
        print("Checking: " + Dump.unparseClassAttributesStr(c) + " " + AbsynUtil.pathString(className) + "... ");
        t1 = clock();
        FlagsUtil.setConfigBool(Flags.CHECK_MODEL, true);
        (_,Values.STRING(str)) = checkModel(FCore.emptyCache(), env, className, msg);
        FlagsUtil.setConfigBool(Flags.CHECK_MODEL, false);
        t2 = clock();
        elapsedTime = t2 - t1;
        s = realString(elapsedTime);
        (smsg, f) = failOrSuccess(str);
        failed = if f then failed + 1 else failed;
        print (s + " seconds -> " + smsg + "\n\t");
        print (System.stringReplace(str, "\n", "\n\t"));
        print ("\n");
        print ("Error String:\n" + Print.getErrorString() + "\n");
        print ("Error Buffer:\n" + ErrorExt.printMessagesStr(false) + "\n");
        print ("#" + (if f then "[-]" else "[+]") + ", " +
          realString(elapsedTime) + ", " +
          AbsynUtil.pathString(className) + "\n");
        print ("-------------------------------------------------------------------------\n");
        failed = checkAll(cache, env, rest, msg, failed);
      then ();

    case (cache,env,className::rest,msg)
      equation
        c = Interactive.getPathedClassInProgram(className, p);
        print("Checking skipped: " + Dump.unparseClassAttributesStr(c) + " " + AbsynUtil.pathString(className) + "... \n");
        failed = checkAll(cache, env, rest, msg, failed);
      then
        ();
  end matchcontinue;
end checkAll;

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
protected
  list<Absyn.Import> pub_imports_list , pro_imports_list;
algorithm
  (pub_imports_list , pro_imports_list) := getImportList(inClass);
  outInteger := listLength(pub_imports_list) + listLength(pro_imports_list);
end getImportCount;

protected function getMMfileTotalDependencies
  input String in_package_name;
  input String public_imports_dir;
  output list<String> total_pub_imports = {};
protected
  Absyn.Class package_class;
  list<Absyn.Import> pub_imports_list , pro_imports_list;
  String imp_ident;
algorithm
  package_class := Interactive.getPathedClassInProgram(Absyn.IDENT(in_package_name), SymbolTable.getAbsyn());

  (pub_imports_list , pro_imports_list) := getImportList(package_class);

  for imp in pub_imports_list loop
   imp_ident := AbsynUtil.pathFirstIdent(AbsynUtil.importPath(imp));
   if imp_ident <> "MetaModelica" then
     total_pub_imports := getMMfilePublicDependencies(imp_ident, public_imports_dir, total_pub_imports);
   end if;
  end for;

  for imp in pro_imports_list loop
   imp_ident := AbsynUtil.pathFirstIdent(AbsynUtil.importPath(imp));
   if imp_ident <> "MetaModelica" then
     total_pub_imports := getMMfilePublicDependencies(imp_ident, public_imports_dir, total_pub_imports);
   end if;
  end for;

end getMMfileTotalDependencies;

protected function getMMfilePublicDependencies
  input String in_package_name;
  input String public_imports_dir;
  input output list<String> packages;
protected
  String dep_public_imports_file, pub_imports_total;
algorithm
  if listMember(in_package_name, packages) then
    return;
  end if;

  packages := in_package_name::packages;

  dep_public_imports_file := public_imports_dir + "/" + in_package_name + ".public.imports";
  pub_imports_total := System.readFile(dep_public_imports_file);

  for pub_imp in System.strtok(pub_imports_total, ";") loop
    packages := getMMfilePublicDependencies(pub_imp, public_imports_dir, packages);
  end for;

end getMMfilePublicDependencies;



protected function getImportedNames
  input Absyn.Class inClass;
  output list<Values.Value> outPublicImports;
  output list<Values.Value> outProtectedImports;
protected
  String ident;
  list<Absyn.Import> pub_imports_list , pro_imports_list;
algorithm
  (pub_imports_list , pro_imports_list) := getImportList(inClass);

  outPublicImports := {};
  for imp in pub_imports_list loop
     ident := AbsynUtil.pathFirstIdent(AbsynUtil.importPath(imp));
     if ident <> "MetaModelica" then
       outPublicImports := Values.STRING(ident)::outPublicImports;
     end if;
  end for;

  outProtectedImports := {};
  for imp in pro_imports_list loop
     ident := AbsynUtil.pathFirstIdent(AbsynUtil.importPath(imp));
     if ident <> "MetaModelica" then
       outProtectedImports := Values.STRING(ident)::outProtectedImports;
     end if;
  end for;
end getImportedNames;

protected function getImportList
"Counts the number of Import sections in a class."
  input Absyn.Class inClass;
  input output list<Absyn.Import> pub_imports_list = {};
  input output list<Absyn.Import> pro_imports_list = {};
algorithm
  () := match (inClass)
    local
      list<Absyn.ClassPart> parts;

    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts)) algorithm
      for part in parts loop
        (pub_imports_list, pro_imports_list) := getImportsInClassPart(part, pub_imports_list, pro_imports_list);
      end for;
    then ();

    // check also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)) algorithm
      for part in parts loop
        (pub_imports_list, pro_imports_list) := getImportsInClassPart(part, pub_imports_list, pro_imports_list);
      end for;
    then ();

    case Absyn.CLASS(body = Absyn.DERIVED()) then ();
  end match;
end getImportList;

protected function getImportsInClassPart
  input Absyn.ClassPart inAbsynClassPart;
  input output list<Absyn.Import> pub_imports_list;
  input output list<Absyn.Import> pro_imports_list;
algorithm
  () := matchcontinue (inAbsynClassPart)
    local
      list<Absyn.ElementItem> els;
    case Absyn.PUBLIC(contents = els) algorithm
      for elem in els loop
        pub_imports_list := getImportsInElementItem(elem, pub_imports_list);
      end for;
    then ();

    case Absyn.PROTECTED(contents = els) algorithm
      for elem in els loop
        pro_imports_list := getImportsInElementItem(elem, pro_imports_list);
      end for;
    then ();

    else ();

  end matchcontinue;
end getImportsInClassPart;

protected function getImportsInElementItem
"Helper function to getImportCount"
  input Absyn.ElementItem inAbsynElementItem;
  input output list<Absyn.Import> imports_list;
algorithm
  () := matchcontinue inAbsynElementItem
    local
      Absyn.Import import_;
      Absyn.Class class_;

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.IMPORT(import_ = import_)))
      algorithm
        imports_list := import_::imports_list;
      then ();

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = class_)))
      algorithm
        // imports_list := getImportList(class_, get_protected, imports_list);
      then ();

    else ();
  end matchcontinue;
end getImportsInElementItem;

protected function getNthImport
"Returns the Nth Import String from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output list<Values.Value> outValue;
protected
  list<Absyn.Import> pub_imports_list , pro_imports_list;
algorithm
  (pub_imports_list, pro_imports_list) := getImportList(inClass);
  outValue := unparseNthImport(listGet(pub_imports_list,inInteger));
end getNthImport;

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
        path_str = AbsynUtil.pathString(path);
        vals = {Values.STRING(path_str),Values.STRING(id),Values.STRING("named")};
      then
        vals;
    case (Absyn.QUAL_IMPORT(path = path))
      equation
        path_str = AbsynUtil.pathString(path);
        vals = {Values.STRING(path_str),Values.STRING(""),Values.STRING("qualified")};
      then
        vals;
    case (Absyn.UNQUAL_IMPORT(path = path))
      equation
        path_str = AbsynUtil.pathString(path);
        path_str = stringAppendList({path_str, ".*"});
        vals = {Values.STRING(path_str),Values.STRING(""),Values.STRING("unqualified")};
      then
        vals;
    case (Absyn.GROUP_IMPORT(prefix = path, groups = gi))
      equation
        path_str = AbsynUtil.pathString(path);
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
  input tuple<Absyn.Path,String,list<String>,Boolean> inTpl;
  output Values.Value v;
algorithm
  v := match inTpl
    local
      Absyn.Path p;
      String pstr,ver;
    case ((p,_,{ver},_))
      equation
        pstr = AbsynUtil.pathString(p);
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
  input Boolean stripAnnotations;
  input Boolean stripComments;
protected
  SCode.Program scodeP;
  String str,str1,str2,str3;
  NFSCodeEnv.Env env;
  SCode.Comment cmt;
algorithm
  runFrontEndLoadProgram(classpath);
  scodeP := SymbolTable.getSCode();
  (scodeP, env) := NFSCodeFlatten.flattenClassInProgram(classpath, scodeP);
  (NFSCodeEnv.CLASS(cls=SCode.CLASS(cmt=cmt)),_,_) := NFSCodeLookup.lookupClassName(classpath, env, AbsynUtil.dummyInfo);
  scodeP := SCodeUtil.removeBuiltinsFromTopScope(scodeP);

  if stripAnnotations or stripComments then
    scodeP := SCodeUtil.stripCommentsFromProgram(scodeP, stripAnnotations, stripComments);
  end if;

  str := SCodeDump.programStr(scodeP,SCodeDump.defaultOptions);
  str1 := AbsynUtil.pathLastIdent(classpath) + "_total";
  str2 := if stripComments then "" else SCodeDump.printCommentStr(cmt);
  str2 := if stringEq(str2,"") then "" else (" " + str2);
  str3 := if stripAnnotations then "" else SCodeDump.printAnnotationStr(cmt,SCodeDump.defaultOptions);
  str3 := if stringEq(str3,"") then "" else (str3 + ";\n");
  str1 := "\nmodel " + str1 + str2 + "\n  extends " + AbsynUtil.pathString(classpath) + ";\n" + str3 + "end " + str1 + ";\n";
  System.writeFile(filename, str + str1);
end saveTotalModel;

protected function getDymolaStateAnnotation
  "Returns the __Dymola_state annotation of a class.
  This is annotated with the annotation:
  annotation (__Dymola_state=true); in the class definition"
  input Absyn.Path className;
  input Absyn.Program p;
  output Boolean isState;
algorithm
  isState := match(className,p)
    local
      String stateStr;
    case(_,_)
      equation
        stateStr = Interactive.getNamedAnnotation(className, p, Absyn.IDENT("__Dymola_state"), SOME("false"), getDymolaStateAnnotationModStr);
      then
        stringEq(stateStr, "true");
  end match;
end getDymolaStateAnnotation;

protected function getDymolaStateAnnotationModStr
  "Extractor function for getDymolaStateAnnotation"
  input Option<Absyn.Modification> mod;
  output String stateStr;
algorithm
  stateStr := matchcontinue(mod)
    local Absyn.Exp e;

    case(SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=e))))
      equation
        stateStr = Dump.printExpStr(e);
      then
        stateStr;

    else "false";

  end matchcontinue;
end getDymolaStateAnnotationModStr;

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
  String name,file,strPartial,strFinal,strEncapsulated,res,cmt,str_readonly,str_sline,str_scol,str_eline,str_ecol,version,preferredView,access;
  String dim_str,lastIdent;
  Boolean partialPrefix,finalPrefix,encapsulatedPrefix,isReadOnly,isProtectedClass,isDocClass,isState;
  Absyn.Restriction restr;
  Absyn.ClassDef cdef;
  Integer sl,sc,el,ec;
  Absyn.Path classPath;
algorithm
  Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restr,cdef,SOURCEINFO(file,isReadOnly,sl,sc,el,ec,_)) := Interactive.getPathedClassInProgram(path, p);
  res := Dump.unparseRestrictionStr(restr);
  cmt := getClassComment(cdef);
  file := Testsuite.friendly(file);
  if AbsynUtil.pathIsIdent(AbsynUtil.makeNotFullyQualified(path)) then
    isProtectedClass := false;
  else
    lastIdent := AbsynUtil.pathLastIdent(AbsynUtil.makeNotFullyQualified(path));
    classPath := AbsynUtil.stripLast(path);
    isProtectedClass := Interactive.isProtectedClass(classPath, lastIdent, p);
  end if;
  isDocClass := Interactive.getDocumentationClassAnnotation(path, p);
  version := CevalScript.getPackageVersion(path, p);
  Absyn.STRING(preferredView) := Interactive.getNamedAnnotation(path, p, Absyn.IDENT("preferredView"), SOME(Absyn.STRING("")), Interactive.getAnnotationExp);
  isState := getDymolaStateAnnotation(path, p);
  access := Interactive.getAccessAnnotation(path, p);
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
    Values.BOOL(isDocClass),
    Values.STRING(version),
    Values.STRING(preferredView),
    Values.BOOL(isState),
    Values.STRING(access)
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
  match (inClassDef)
    local
      String str,res;
      Option<Absyn.Comment> cmt;
    case (Absyn.PARTS(comment = SOME(str))) then str;
    case (Absyn.DERIVED(comment = cmt))
      then Interactive.getStringComment(cmt);
    case (Absyn.ENUMERATION(comment = cmt))
      then Interactive.getStringComment(cmt);
    case (Absyn.ENUMERATION(comment = cmt))
      then Interactive.getStringComment(cmt);
    case (Absyn.OVERLOAD(comment = cmt))
      then Interactive.getStringComment(cmt);
    case (Absyn.CLASS_EXTENDS(comment = SOME(str))) then str;
    else "";
  end match;
end getClassComment;

protected function getAnnotationInEquation
  "This function takes an `EquationItem\' and returns a comma separated
  string of values  from the flat record of an equation annotation that
  is found in the `EquationItem\'."
  input Absyn.EquationItem inEquationItem;
  output String outString;
algorithm
  outString := match (inEquationItem)
    local
      String annotationStr;
      list<String> annotationList;
      list<Absyn.ElementArg> annotations;

    case (Absyn.EQUATIONITEM(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annotations)),_))))
      equation
        annotationList = getAnnotationInEquationElArgs(annotations);
        annotationStr = stringDelimitList(annotationList, ", ");
      then
        annotationStr;
    case (Absyn.EQUATIONITEM(comment = NONE()))
      then
        "";
  end match;
end getAnnotationInEquation;

protected function getAnnotationInEquationElArgs
  input list<Absyn.ElementArg> inElArgLst;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inElArgLst)
    local
      Absyn.FunctionArgs fargs;
      list<SCode.Element> p_1;
      FCore.Graph env;
      DAE.Exp newexp;
      String gexpstr, gexpstr_1, annName;
      list<String> res;
      list<Absyn.ElementArg>  mod, rest;
      FCore.Cache cache;
      DAE.Properties prop;
      Absyn.Program lineProgram;

    // handle empty
    case ({}) then {};

    case (Absyn.MODIFICATION(path = Absyn.IDENT(annName), modification = SOME(Absyn.CLASSMOD(mod,_))) :: rest)
      equation
        lineProgram = Interactive.modelicaAnnotationProgram(Config.getAnnotationVersion());
        fargs = Interactive.createFuncargsFromElementargs(mod);
        p_1 = AbsynToSCode.translateAbsyn2SCode(lineProgram);
        (cache,env) = Inst.makeEnvFromProgram(p_1);
        (_,newexp,prop) = StaticScript.elabGraphicsExp(cache,env, Absyn.CALL(Absyn.CREF_IDENT(annName,{}),fargs), false,DAE.NOPRE(), sourceInfo()) "impl" ;
        (cache, newexp, prop) = Ceval.cevalIfConstant(cache, env, newexp, prop, false, sourceInfo());
        Print.clearErrorBuf() "this is to clear the error-msg generated by the annotations." ;
        gexpstr = ExpressionDump.printExpStr(newexp);
        res = getAnnotationInEquationElArgs(rest);
      then
        (gexpstr :: res);
    case (Absyn.MODIFICATION(path = Absyn.IDENT(annName), modification = SOME(Absyn.CLASSMOD(_,Absyn.NOMOD()))) :: rest)
      equation
        gexpstr_1 = stringAppendList({annName,"(error)"});
        res = getAnnotationInEquationElArgs(rest);
      then
        (gexpstr_1 :: res);
  end matchcontinue;
end getAnnotationInEquationElArgs;

protected function getTransitions
  input Absyn.Path path;
  input Absyn.Program p;
  output Values.Value res;
protected
  list<list<String>> transitions;
  Absyn.Class cdef;
algorithm
  cdef := Interactive.getPathedClassInProgram(path, p);
  transitions := listReverse(getTransitionsInClass(cdef));
  res := ValuesUtil.makeArray(List.map(transitions, ValuesUtil.makeStringArray));
end getTransitions;

protected function getTransitionsInClass
  "Gets the list of transitions in a class."
  input Absyn.Class inClass;
  output list<list<String>> outTransitions;
algorithm
  outTransitions := match (inClass)
    local
      list<list<String>> transitions;
      list<Absyn.ClassPart> parts;

    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        transitions = getTransitionsInClassParts(parts);
      then
        transitions;

    // handle also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        transitions = getTransitionsInClassParts(parts);
      then
        transitions;

    case Absyn.CLASS(body = Absyn.DERIVED()) then {};

  end match;
end getTransitionsInClass;

protected function getTransitionsInClassParts
  "Helper function for getTransitionsInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<list<String>> outTransitions;
algorithm
  outTransitions := matchcontinue (inAbsynClassPartLst)
    local
      list<list<String>> transitions1, transitions2;
      list<Absyn.EquationItem> eqlist;
      list<Absyn.ClassPart> xs;

    case ((Absyn.EQUATIONS(contents = eqlist) :: xs))
      equation
        transitions1 = getTransitionsInEquations(eqlist, {});
        transitions2 = getTransitionsInClassParts(xs);
      then
        listAppend(transitions1, transitions2);

    case ((_ :: xs))
      equation
        transitions1 = getTransitionsInClassParts(xs);
      then
        transitions1;

    case ({})
      then {};

  end matchcontinue;
end getTransitionsInClassParts;

protected function getTransitionsInEquations
  "Helper function for getTransitionsInClass."
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  input list<list<String>> inTransitions;
  output list<list<String>> outTransitions;
algorithm
  outTransitions := match (inAbsynEquationItemLst, inTransitions)
    local
      list<list<String>> transitions;
      list<String> transition;
      Absyn.EquationItem eqItem;
      Absyn.Equation eq;
      list<Absyn.EquationItem> xs;

    case (((eqItem as Absyn.EQUATIONITEM(equation_ = eq as Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT(name = "transition")))) :: xs),transitions)
      equation
        transition = getTransitionInEquation(eq);
        transition = List.insert(transition, listLength(transition) + 1, getAnnotationInEquation(eqItem));
        transitions = listAppend({transition}, transitions);
      then
        getTransitionsInEquations(xs, transitions);

    case ((_ :: xs), _)
      then
        getTransitionsInEquations(xs, inTransitions);

    case ({}, _)
      then
        inTransitions;

  end match;
end getTransitionsInEquations;

protected function getTransitionInEquation
  "Transition is a Absyn.EQ_NORETCALL.
  So we read the function arguments and named arguments.
  This function should always return a list with 7 values."
  input Absyn.Equation inEquation;
  output list<String> outTransition;
algorithm
  outTransition := match (inEquation)
    local
      list<Absyn.Exp> expArgs;
      list<Absyn.NamedArg> namedArgs;
      list<String> transition;

    case Absyn.EQ_NORETCALL(functionArgs = Absyn.FUNCTIONARGS(args = expArgs, argNames = namedArgs))
      equation
        transition = List.map(expArgs, Dump.printExpStr);
        // if we have named args then give them preference
        transition = Interactive.addOrUpdateNamedArg(namedArgs, "immediate", "true", transition, 4);
        transition = Interactive.addOrUpdateNamedArg(namedArgs, "reset", "true", transition, 5);
        transition = Interactive.addOrUpdateNamedArg(namedArgs, "synchronize", "false", transition, 6);
        transition = Interactive.addOrUpdateNamedArg(namedArgs, "priority", "1", transition, 7);
      then
        transition;

    else {"", "", "", "true", "true", "false", "1"};

  end match;
end getTransitionInEquation;

protected function getInitialStates
  input Absyn.Path path;
  input Absyn.Program p;
  output Values.Value res;
protected
  list<list<String>> initialStates;
  Absyn.Class cdef;
algorithm
  cdef := Interactive.getPathedClassInProgram(path, p);
  initialStates := listReverse(getInitialStatesInClass(cdef));
  res := ValuesUtil.makeArray(List.map(initialStates, ValuesUtil.makeStringArray));
end getInitialStates;

protected function getInitialStatesInClass
  "Gets the list of initial states in a class."
  input Absyn.Class inClass;
  output list<list<String>> outInitialStates;
algorithm
  outInitialStates := match (inClass)
    local
      list<list<String>> initialStates;
      list<Absyn.ClassPart> parts;

    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        initialStates = getInitialStatesInClassParts(parts);
      then
        initialStates;

    // handle also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        initialStates = getInitialStatesInClassParts(parts);
      then
        initialStates;

    case Absyn.CLASS(body = Absyn.DERIVED()) then {};

  end match;
end getInitialStatesInClass;

protected function getInitialStatesInClassParts
  "Helper function for getInitialStatesInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<list<String>> outInitialStates;
algorithm
  outInitialStates := matchcontinue (inAbsynClassPartLst)
    local
      list<list<String>> initialStates1, initialStates2;
      list<Absyn.EquationItem> eqlist;
      list<Absyn.ClassPart> xs;

    case ((Absyn.EQUATIONS(contents = eqlist) :: xs))
      equation
        initialStates1 = getInitialStatesInEquations(eqlist, {});
        initialStates2 = getInitialStatesInClassParts(xs);
      then
        listAppend(initialStates1, initialStates2);

    case ((_ :: xs))
      equation
        initialStates1 = getInitialStatesInClassParts(xs);
      then
        initialStates1;

    case ({})
      then {};

  end matchcontinue;
end getInitialStatesInClassParts;

protected function getInitialStatesInEquations
  "Helper function for getInitialStatesInClass."
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  input list<list<String>> inInitialStates;
  output list<list<String>> outInitialStates;
algorithm
  outInitialStates := match (inAbsynEquationItemLst, inInitialStates)
    local
      list<list<String>> initialStates;
      list<String> initialState;
      Absyn.EquationItem eqItem;
      Absyn.Equation eq;
      list<Absyn.EquationItem> xs;

    case (((eqItem as Absyn.EQUATIONITEM(equation_ = eq as Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT(name = "initialState")))) :: xs),initialStates)
      equation
        initialState = getInitialStateInEquation(eq);
        initialState = List.insert(initialState, listLength(initialState) + 1, getAnnotationInEquation(eqItem));
        initialStates = listAppend({initialState}, initialStates);
      then
        getInitialStatesInEquations(xs, initialStates);

    case ((_ :: xs), _)
      then
        getInitialStatesInEquations(xs, inInitialStates);

    case ({}, _)
      then
        inInitialStates;

  end match;
end getInitialStatesInEquations;

protected function getInitialStateInEquation
  "Initial state is a Absyn.EQ_NORETCALL.
  So we read the function arguments and named arguments.
  This function should always return a list with 1 value."
  input Absyn.Equation inEquation;
  output list<String> outInitialState;
algorithm
  outInitialState := match (inEquation)
    local
      list<Absyn.Exp> expArgs;
      list<Absyn.NamedArg> namedArgs;
      list<String> initialState;

    case Absyn.EQ_NORETCALL(functionArgs = Absyn.FUNCTIONARGS(args = expArgs))
      equation
        initialState = List.map(expArgs, Dump.printExpStr);
      then
        initialState;

    else {""};

  end match;
end getInitialStateInEquation;

protected function addInitialState
"Adds an initial state to the model, i.e., initialState(state1)"
  input Absyn.Path inPath;
  input String state;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Absyn.Program inProgram;
  output Boolean b;
  output Absyn.Program outProgram;
algorithm
  (b, outProgram) := addInitialStateWithAnnotation(inPath, state, Interactive.annotationListToAbsyn(inAbsynNamedArgLst), inProgram);
end addInitialState;

protected function addInitialStateWithAnnotation
"Adds an initial state to the model, i.e., initialState(state1)"
  input Absyn.Path inPath;
  input String state;
  input Absyn.Annotation inAnnotation;
  input Absyn.Program inProgram;
  output Boolean b;
  output Absyn.Program outProgram;
algorithm
  (b, outProgram) := match (inPath, state, inAnnotation, inProgram)
    local
      Absyn.Path modelpath, package_;
      Absyn.Class cdef, newcdef;
      Absyn.Program newp, p;
      String state_;
      Absyn.Annotation ann;
      Option<Absyn.Comment> cmt;

    case (modelpath, state_, ann,(p as Absyn.PROGRAM()))
      equation
        cdef = Interactive.getPathedClassInProgram(modelpath, p);
        cmt = SOME(Absyn.COMMENT(SOME(ann), NONE()));
        newcdef = Interactive.addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_NORETCALL(Absyn.CREF_IDENT("initialState", {}),
                                Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(state_, {}))}, {})), cmt, AbsynUtil.dummyInfo));
        if AbsynUtil.pathIsIdent(AbsynUtil.makeNotFullyQualified(modelpath)) then
          newp = Interactive.updateProgram(Absyn.PROGRAM({newcdef},p.within_), p);
        else
          package_ = AbsynUtil.stripLast(modelpath);
          newp = Interactive.updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(package_)), p);
        end if;
      then
        (true, newp);
    case (_,_,_,(p as Absyn.PROGRAM())) then (false, p);
  end match;
end addInitialStateWithAnnotation;

protected function deleteInitialState
"Delete the initial state initialState(c1) from a model."
  input Absyn.Path inPath;
  input String state;
  input Absyn.Program inProgram;
  output Boolean b;
  output Absyn.Program outProgram;
algorithm
  (b,outProgram) := matchcontinue (inPath, state, inProgram)
    local
      Absyn.Path modelpath, modelwithin;
      Absyn.Class cdef, newcdef;
      Absyn.Program newp, p;
      Absyn.ComponentRef model_;
      String state_;

    case (modelpath, state_, (p as Absyn.PROGRAM()))
      equation
        cdef = Interactive.getPathedClassInProgram(modelpath, p);
        newcdef = deleteInitialStateInClass(cdef, state_);
        if AbsynUtil.pathIsIdent(AbsynUtil.makeNotFullyQualified(modelpath)) then
          newp = Interactive.updateProgram(Absyn.PROGRAM({newcdef}, Absyn.TOP()), p);
        else
          modelwithin = AbsynUtil.stripLast(modelpath);
          newp = Interactive.updateProgram(Absyn.PROGRAM({newcdef}, Absyn.WITHIN(modelwithin)), p);
        end if;
      then
        (true, newp);
    case (_,_,(p as Absyn.PROGRAM())) then (false, p);
  end matchcontinue;
end deleteInitialState;

protected function deleteInitialStateInClass
"Helper function to deleteInitialState."
  input Absyn.Class inClass;
  input String state;
  output Absyn.Class outClass;
algorithm
  outClass := match (inClass, state)
    local
      list<Absyn.EquationItem> eqlst,eqlst_1;
      list<Absyn.ClassPart> parts2,parts;
      String i, bcname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      SourceInfo file_info;
      String state_;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;
    /* a class with parts */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann=ann,comment = cmt),
                      info = file_info), state_)
      equation
        eqlst = Interactive.getEquationList(parts);
        eqlst_1 = deleteInitialStateInEqlist(eqlst, state_);
        parts2 = Interactive.replaceEquationList(parts, eqlst_1);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt),file_info);
    /* an extended class with parts: model extends M end M;  */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications=modif,parts = parts,ann = ann,comment = cmt)
                      ,info = file_info), state_)
      equation
        eqlst = Interactive.getEquationList(parts);
        eqlst_1 = deleteInitialStateInEqlist(eqlst, state_);
        parts2 = Interactive.replaceEquationList(parts, eqlst_1);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann),file_info);
  end match;
end deleteInitialStateInClass;

protected function deleteInitialStateInEqlist
"Helper function to deleteInitialState."
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  input String state;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm
  outAbsynEquationItemLst := matchcontinue (inAbsynEquationItemLst, state)
    local
      list<Absyn.EquationItem> res,xs;
      String state_;
      Absyn.ComponentRef name;
      list<Absyn.Exp> expArgs;
      list<Absyn.NamedArg> namedArgs;
      list<String> args;
      Absyn.EquationItem x;

    case ({},_) then {};
    case ((Absyn.EQUATIONITEM(equation_ = Absyn.EQ_NORETCALL(name, Absyn.FUNCTIONARGS(expArgs, _))) :: xs), state_)
      guard AbsynUtil.crefEqual(name, Absyn.CREF_IDENT("initialState", {}))
      equation
        args = List.map(expArgs, Dump.printExpStr);
        true = compareInitialStateFuncArgs(args, state_);
      then
        deleteInitialStateInEqlist(xs, state_);
    case ((x :: xs), state_)
      equation
        res = deleteInitialStateInEqlist(xs, state_);
      then
        (x :: res);
  end matchcontinue;
end deleteInitialStateInEqlist;

protected function compareInitialStateFuncArgs
"Helper function to deleteInitialState."
  input list<String> args;
  input String state;
  output Boolean b;
algorithm
  b := matchcontinue (args, state)
    local
      String state1, state2;

    case ({state1}, state2)
      guard
        stringEq(state1, state2)
      then
        true;

    else false;
  end matchcontinue;
end compareInitialStateFuncArgs;

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
              tpname = AbsynUtil.pathLastIdent(p);
              p_1 = AbsynUtil.joinPaths(envpath, Absyn.IDENT(tpname));
            then AbsynUtil.pathString(p_1);
          else AbsynUtil.pathString(p);
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


// new functions added for getting vendorannotation modifiers names and their values
function getAnnotationList
   "@author arun Helper function which returns the list of annotation items as elementargs "
   input Absyn.ClassDef inclassdef;
   output list<Absyn.ElementArg> anninfo;
algorithm
   anninfo:=matchcontinue(inclassdef)
   local
     list<Absyn.Annotation> ann;
     list<Absyn.ElementArg> annlst;

   case(Absyn.PARTS(_,_,_,ann,_))
     equation
       annlst = List.flatten(List.map(ann,AbsynUtil.annotationToElementArgs));
     then
      annlst;

   case (Absyn.CLASS_EXTENDS(ann=ann))
      equation
        annlst = List.flatten(List.map(ann,AbsynUtil.annotationToElementArgs));
      then
        annlst;

    case (Absyn.DERIVED(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annlst)),_))))
      then
        annlst;

    case (Absyn.ENUMERATION(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annlst)),_))))
      then
        annlst;

    case (Absyn.OVERLOAD(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annlst)),_))))
      then
        annlst;

    case(_)then {};

  end matchcontinue;
end getAnnotationList;


function getElementArgsModifiers
 "@author arun Helper function which parses list of elementargs,annotationname returns the list of modifiers name in the annotation"
    input list<Absyn.ElementArg> inargs;
    input String instring;
    input String inClass;
    input SourceInfo info;
    output list<String> outstring;
algorithm
    outstring:=match(inargs,instring)
    local
    list<Absyn.ElementArg> elt,eltarglst;
    Option<Absyn.Modification> modification;
    String name,name1, s;
    list<String> modfiernamelist;
    Absyn.ElementArg eltarg;
  case (Absyn.MODIFICATION(_,_, Absyn.IDENT(name),modification,_)::_,name1)
    guard stringEq(name, name1)
    equation
       elt=getElementArgsList(modification);
       modfiernamelist =getModifiersNameList(elt);
    then
        modfiernamelist;

  case((_::eltarglst),name1)
    then
        getElementArgsModifiers(eltarglst,name1,inClass,info);

  case ({},_)
    algorithm
      Error.addSourceMessage(Error.CLASS_ANNOTATION_DOES_NOT_EXIST, {instring, inClass}, info);
    then {};
 end match;
end getElementArgsModifiers;


function getElementArgsModifiersValue
   "@author arun Helper function which parses list of elementargs,annotationname and modifiername and returns the value"
    input list<Absyn.ElementArg> inargs;
    input String instring;
    input String instring1;
    output String outstring;
algorithm
   outstring:=match(inargs,instring,instring1)
    local
      list<Absyn.ElementArg> elt,eltarglst;
      Option<Absyn.Modification> modification;
      String name,name1,name2,s;
      String modfiername_value;
      Absyn.ElementArg eltarg;

    case (Absyn.MODIFICATION(_,_, Absyn.IDENT(name),modification,_)::_,name1,name2)
      guard stringEq(name1, name)
      equation
        elt=getElementArgsList(modification);
        modfiername_value =getModifierNamedValue(elt,name2);
      then
        modfiername_value;

    case((_::eltarglst),name1,name2)
      equation
        modfiername_value=getElementArgsModifiersValue(eltarglst,name1,name2);
      then
        modfiername_value;

    case({},_,_) then "The Searched value not Found";
  end match;

 end getElementArgsModifiersValue;

function getElementArgsList
  "@author arun Helper function which gives list of elementargs from modification"
  input Option<Absyn.Modification> inmod;
  output list<Absyn.ElementArg> outargs;
algorithm
  outargs:=match(inmod)
   local
   list<Absyn.ElementArg> elementargs;
   case(SOME(Absyn.CLASSMOD(elementargs,_))) then elementargs;
  end match;
end getElementArgsList;


function getModifiersNameList
"@author arun Function which retrives vendor annotation modifiers name list"
  input list<Absyn.ElementArg> eltArgs;
  output list<String> strs;
  protected
  String name;
algorithm
  strs := list(match mod case (Absyn.MODIFICATION(_,_, Absyn.IDENT(name),_)) then name; end match for mod in eltArgs);
end getModifiersNameList;

function checkModifierName
" @author arun Function which retrives vendor annotation modifiername value"
  input Absyn.ElementArg eltArg;
  input String inString;
  output Boolean b;
  algorithm
    b:=match(eltArg,inString)
    local
      String name,name1;
      case (Absyn.MODIFICATION(path=Absyn.IDENT(name)),name1) then stringEq(name,name1);
      else false;
     end match;
end checkModifierName;

function getModifierNamedValue
" @author arun Function which retrives vendor annotation modifiername value"
  input list<Absyn.ElementArg> eltArgs;
  input String instring;
  output String strs;
  protected
  Absyn.Exp e;
  Boolean b;
algorithm
   strs:= match List.find1(eltArgs,checkModifierName, instring)
    case (Absyn.MODIFICATION(modification=SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(e)))))
      then getExpValue(e);
  end match;
end getModifierNamedValue;

function getExpValue
  input Absyn.Exp inexp;
  output String outstring;
algorithm
  outstring:=match(inexp)
    local
      String s;
    case(Absyn.STRING(s)) then System.unescapedString(s);
    case(_) then "";
  end match;
end getExpValue;

function makeLoadLibrariesEntryAbsyn "Needed to be able to resolve modelica:// during runtime, etc.
Should not be part of CevalScript since ModelicaServices needs this feature and the frontend needs to take care of it."
  input Absyn.Class cl;
  input list<Values.Value> acc;
  output list<Values.Value> out;
algorithm
  out := match (cl,acc)
    local
      String name,fileName,dir;
      Values.Value v;
      Boolean b;
    case (Absyn.CLASS(info=SOURCEINFO(fileName="<interactive>")),_) then acc;
    case (Absyn.CLASS(name=name,info=SOURCEINFO(fileName=fileName)),_)
      equation
        dir = System.dirname(fileName);
        fileName = System.basename(fileName);
        v = ValuesUtil.makeArray({Values.STRING(name),Values.STRING(dir)});
        b = stringEq(fileName,"ModelicaBuiltin.mo") or stringEq(fileName,"MetaModelicaBuiltin.mo") or stringEq(dir,".");
      then List.consOnTrue(not b,v,acc);
  end match;
end makeLoadLibrariesEntryAbsyn;

function selectResultFile
  input output String resultFile;
  input String simflags;
protected
  Integer nm;
  String f = "";
algorithm
  // if there is no -r in the simflags, return
  if  System.stringFind(simflags, "-r") < 0 then
    return;
  end if;
  // never fail!
  try
   // match -r="file"
   (nm, {_, f}) := System.regex(simflags, "-r=\"(.*?)\"", 2, true);
   if nm == 2 then
     resultFile := f; return;
   end if;
   // match -r='file'
   (nm, {_, f}) := System.regex(simflags, "-r=\'(.*?)\'", 2, true);
   if nm == 2 then
     resultFile := f; return;
   end if;
   // match -r 'file'
   (nm, {_, f}) := System.regex(simflags, "-r[ ]*\"(.*?)\"", 2, true);
   if nm == 2 then
     resultFile := f; return;
   end if;
   // match -r "file"
   (nm, {_, f}) := System.regex(simflags, "-r[ ]*\'(.*?)\'", 2, true);
   if nm == 2 then
     resultFile := f; return;
   end if;
   // match -r=file
   (nm, {_, f}) := System.regex(simflags, "-r=([^ ]*)", 2, true);
   if nm == 2 then
     resultFile := f; return;
   end if;
   // match -r file
   (nm, {_, f}) := System.regex(simflags, "-r[ ]*([^ ]*)", 2, true);
   if nm == 2 then
     resultFile := f; return;
   end if;
  else
    // do nothing
  end try;
end selectResultFile;

function instantiateModel
  input output FCore.Cache cache;
  input FCore.Graph env;
  input Absyn.Path path;
        output Values.Value result;
protected
  String str;
  Absyn.Program p;
  Option<DAE.DAElist> odae;
  NFFlatModel flat_model;
  NFFlatten.FunctionTree funcs;
algorithm
  str := matchcontinue ()
    // handle encryption
    case ()
      algorithm
        // if AST contains encrypted class show nothing
        p := SymbolTable.getAbsyn();
        true := Interactive.astContainsEncryptedClass(p);
        Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
      then
        "";

    case ()
      algorithm
        ExecStat.execStatReset();
        (cache, _, odae, str) := runFrontEnd(cache, env, path, relaxedFrontEnd = true,
          dumpFlat = Config.flatModelica() and not Config.silent());
        ExecStat.execStat("runFrontEnd");

        if not stringEmpty(str) then
          // str already contains flat model.
        elseif isNone(odae) then
          str := "";
        elseif Config.silent() then
          str := "model " + AbsynUtil.pathString(path) + "\n  /* Silent mode */\nend" +
            AbsynUtil.pathString(path) + ";\n"; // Not the empty string, so we can
        else
          str := DAEDump.dumpStr(Util.getOption(odae), FCore.getFunctionTree(cache));
          ExecStat.execStat("DAEDump.dumpStr");
        end if;
      then
        str;

    case ()
      algorithm
        false := Interactive.existClass(AbsynUtil.pathToCref(path), SymbolTable.getAbsyn());
        Error.addMessage(Error.LOOKUP_ERROR, {AbsynUtil.pathString(path), "<TOP>"});
      then
        "";

    else
      algorithm
        if Error.getNumMessages() == 0 then
          str := "Instantiation of " + AbsynUtil.pathString(path) +
                 " failed with no error message";
          Error.addMessage(Error.INTERNAL_ERROR, {str, "<TOP>"});
        end if;
      then
        "";
  end matchcontinue;

  result := Values.STRING(str);
end instantiateModel;

annotation(__OpenModelica_Interface="backend");

end CevalScriptBackend;
