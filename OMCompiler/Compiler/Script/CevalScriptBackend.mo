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
import Interactive.Access;
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
import Conversion;
import DAEDump;
import DAEQuery;
import DAEUtil;
import Debug;
import DiffAlgorithm;
import ContainerImage;
import Dump;
import Error;
import ErrorExt;
import ExecStat;
import Expression;
import ExpressionDump;
import FBuiltin;
import FGraph;
import Figaro;
import FindZeroCrossings;
import FInst;
import Flags;
import FlagsUtil;
import FlatModel = NFFlatModel;
import FMI;
import FMIExt;
import FunctionTree = NFFlatten.FunctionTree;
import GCExt;
import Graph;
import InnerOuter;
import Inst;
import LexerModelicaDiff;
import List;
import Lookup;
import NFApi;
import NFConvertDAE;
import NFFlatModel;
import NFFlatten;
import NFInst;
import NFSCodeEnv;
import NFSCodeFlatten;
import NFSCodeLookup;
import Obfuscate;
import PackageManagement;
import Parser;
import Print;
import Refactor;
import RewriteRules;
import SCode;
import SCodeDump;
import SCodeUtil;
import SemanticVersion;
import Settings;
import SimCodeMain;
import SimCodeFunctionUtil;
import SimpleModelicaParser;
import SimulationResults;
import StaticScript;
import StringUtil;
import SymbolicJacobian;
import SymbolTable;
import System;
import TaskGraphResults;
import TotalModelDebug;
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
  },NONE(), false);

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
  },NONE(), false);

protected constant DAE.Type simulationResultType_drModelica = DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationResult")),{
  DAE.TYPES_VAR("messages",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),false,NONE()),
  DAE.TYPES_VAR("flatteningTime",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),false,NONE()),
  DAE.TYPES_VAR("simulationTime",DAE.dummyAttrVar,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),false,NONE())
  },NONE(), false);

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
      Option<Absyn.Modification> experiment_ann;

    // search inside annotation(experiment(...))
    case (_, _, _)
      equation
        defaults = Util.getOptionOrDefault(defaultOption, setFileNamePrefixInSimulationOptions(defaultSimulationOptions, inFileNamePrefix));

        experiment_ann = InteractiveUtil.getInheritedAnnotation(inModelPath, "experiment", SymbolTable.getAbsyn());

        // TODO: Get the values from the modifier directly instead of this mess.
        experimentAnnotationStr = Interactive.getExperimentAnnotationString(experiment_ann);

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
  input output GlobalScript.SimulationOptions options;
  input list<Absyn.NamedArg> args;
protected
  String name;
  Absyn.Exp value;
  Option<DAE.Exp> interval = NONE();
algorithm
  for arg in args loop
    Absyn.NAMEDARG(argName = name, argValue = value) := arg;

    () := match name
      case "Tolerance"         algorithm options.tolerance := getConst(value, DAE.T_REAL_DEFAULT);            then ();
      case "StartTime"         algorithm options.startTime := getConst(value, DAE.T_REAL_DEFAULT);            then ();
      case "StopTime"          algorithm options.stopTime := getConst(value, DAE.T_REAL_DEFAULT);             then ();
      case "NumberOfIntervals" algorithm options.numberOfIntervals := getConst(value, DAE.T_INTEGER_DEFAULT); then ();
      case "Interval"          algorithm interval := SOME(getConst(value, DAE.T_REAL_DEFAULT));               then ();
      else
        algorithm
          if not StringUtil.startsWith(name, "__") then
            Error.addCompilerWarning("Ignoring unknown experiment annotation option: " +
              name + " = " + Dump.printExpStr(value));
          end if;
        then
          ();
    end match;
  end for;

  // Interval needs to be handled last since it depends on the start and stop time.
  if isSome(interval) then
    options := setSimulationOptionsInterval(options, Expression.toReal(Util.getOption(interval)));
  else
    /*fix issue 12070, set proper default value of stepSize when Interval annotation is not provided
      stepSize = (StopTime-StartTime)/500
    */
    options.stepSize := DAE.RCONST((Expression.toReal(options.stopTime) - Expression.toReal(options.startTime)) / 500);
  end if;
end populateSimulationOptions;

function setSimulationOptionsInterval
  input output GlobalScript.SimulationOptions options;
  input Real interval;
protected
  Real start_time, stop_time;
algorithm
  start_time := Expression.toReal(options.startTime);
  stop_time := Expression.toReal(options.stopTime);
  options.stepSize := DAE.RCONST(interval);
  options.numberOfIntervals := DAE.ICONST(realInt((stop_time - start_time) / interval));
end setSimulationOptionsInterval;

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
  output FCore.Cache outCache = inCache;
  output Values.Value outValue;
protected
  import LexerModelicaDiff.{Token,TokenId,tokenContent,scanString,reportErrors,filterModelicaDiff,modelicaDiffTokenEq,modelicaDiffTokenWhitespace};
  import DiffAlgorithm.{Diff,diff,printActual,printDiffTerminalColor,printDiffXml};
algorithm
  outValue := matchcontinue (inFunctionName,inVals)
    local
      String simflags,s1,s2,s3,s4,s5,str,str1,str2,str3,str4,executable,
             outputFormat_str,initfilename,pd,executableSuffixedExe,sim_call,result_file,filename_1,filename,
             name,errMsg, res,workdir,filenameprefix,compileDir,exeDir, scriptFile,logFile, outputFile,
             strlinearizeTime, modeldescriptionfilename, tmpDir, tmpFile, bom, description;
      list<Values.Value> vals;
      Absyn.Path path,classpath,className;
      SCode.Program sp;
      FCore.Graph env;
      Absyn.Program p,pnew;
      Absyn.Class absynClass;
      Absyn.Element elem;
      Absyn.Exp aexp;
      DAE.DAElist dae;
      BackendDAE.BackendDAE daelow;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqnarr;
      array<list<Integer>> m;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      Values.Value ret_val,simValue,v,v1,v2;
      Absyn.ComponentRef cr;
      Integer i,i1,n, resI;
      Option<Integer> fmiContext, fmiInstance, fmiModelVariablesInstance; /* void* implementation: DO NOT UNBOX THE POINTER AS THAT MIGHT CHANGE IT. Just treat this as an opaque type. */
      Integer fmiLogLevel, direction;
      list<Integer> is;
      list<FMI.TypeDefinitions> fmiTypeDefinitionsList;
      list<FMI.ModelVariables> fmiModelVariablesList;
      FMI.ExperimentAnnotation fmiExperimentAnnotation;
      FMI.Info fmiInfo;
      list<String> strs,strs1,strs2,dirs;
      Real timeTotal,timeSimulation,linearizeTime,offset,offset1,offset2,scaleFactor,scaleFactor1,scaleFactor2;
      Boolean bval, b, b1, b2, b3, b4, b5, showProtected, inputConnectors, outputConnectors, sanityCheckFailed;
      Absyn.ComponentRef  crefCName;
      list<tuple<String,Values.Value>> resultValues;
      list<Values.Value> cvars;
      list<Absyn.Path> paths;
      list<Absyn.Class> classes;
      list<Absyn.ElementArg> eltargs;
      Absyn.Within within_;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      Boolean dumpExtractionSteps;
      list<Boolean> blst;
      UnitAbsyn.Unit u1,u2;
      list<Token> tokens1, tokens2, errorTokens;
      list<SimpleModelicaParser.ParseTree> parseTree1, parseTree2;
      //list<tuple<Diff, list<Token>>> diffs;
      list<tuple<Diff, list<SimpleModelicaParser.ParseTree>>> treeDiffs;
      SymbolTable forkedSymbolTable;
      SimCode.SimulationSettings simSettings;

    case ("runScriptParallel",{Values.ARRAY(valueLst=vals),Values.INTEGER(i),Values.BOOL(true)})
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
      then
        v;

    case ("runScriptParallel",{Values.ARRAY(valueLst=vals),Values.INTEGER(i),Values.BOOL(false)})
      equation
        strs = List.map(vals,ValuesUtil.extractValueString);
        strs = List.map1r(strs, stringAppend, stringAppend(Settings.getInstallationDirectoryPath(),"/bin/omc "));
        is = System.systemCallParallel(strs,i);
      then
        ValuesUtil.makeArray(List.map(List.map1(is,intEq,0), ValuesUtil.makeBoolean));

    case ("runScriptParallel",{Values.ARRAY(valueLst=vals),_,_})
      then ValuesUtil.makeArray(List.fill(Values.BOOL(false), listLength(vals)));

    case ("setClassComment",{Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str)})
      equation
        (p,b) = Interactive.setClassComment(path, str, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(b);

    case ("isShortDefinition", {Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        b = isShortDefinition(path, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("getUsedClassNames",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        sp = SymbolTable.getSCode();
        (sp, _) = NFSCodeFlatten.flattenClassInProgram(path, sp);
        sp = SCodeUtil.removeBuiltinsFromTopScope(sp);
        paths = Interactive.getSCodeClassNamesRecursive(sp);
        // paths = bcallret2(sort, List.sort, paths, AbsynUtil.pathGe, paths);
      then
        ValuesUtil.makeCodeTypeNameArray(paths);

    case ("getUsedClassNames",_)
      then ValuesUtil.makeArray({});

    case ("getClassComment",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        elem = InteractiveUtil.getPathedElementInProgram(path, SymbolTable.getAbsyn());
        str = System.unescapedString(getClassElementComment(elem));
      then
        Values.STRING(str);

    case ("getClassComment",{Values.CODE(Absyn.C_TYPENAME(_))})
      then
        Values.STRING("");

    case ("getPackages",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("AllLoadedClasses")))})
      equation
        paths = Interactive.getTopPackages(SymbolTable.getAbsyn());
      then
        ValuesUtil.makeCodeTypeNameArray(paths);

    case ("getPackages",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        paths = Interactive.getPackagesInPath(path, SymbolTable.getAbsyn());
      then
        ValuesUtil.makeCodeTypeNameArray(paths);

    case ("convertUnits",{Values.STRING(str1),Values.STRING(str2)})
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
        Values.TUPLE({Values.BOOL(b),Values.REAL(scaleFactor),Values.REAL(offset)});

    case ("convertUnits",{Values.STRING(_),Values.STRING(_)})
      then Values.TUPLE({Values.BOOL(false),Values.REAL(1.0),Values.REAL(0.0)});

    case ("getDerivedUnits",{Values.STRING(str1)})
      equation
        Error.clearMessages() "Clear messages";
        UnitParserExt.initSIUnits();
        u1 = UnitAbsynBuilder.str2unit(str1, NONE());
        strs = UnitAbsynBuilder.getDerivedUnits(u1, str1);
      then
        ValuesUtil.makeArray(List.map(strs, ValuesUtil.makeString));

    case ("getDerivedUnits",{Values.STRING(_)})
      then ValuesUtil.makeArray({});

    case ("getClassInformation",{Values.CODE(Absyn.C_TYPENAME(className))})
      then getClassInformation(className, SymbolTable.getAbsyn());

    case ("getClassInformation",_)
      then Values.TUPLE({Values.STRING(""),Values.STRING(""),Values.BOOL(false),Values.BOOL(false),Values.BOOL(false),Values.STRING(""),
                                Values.BOOL(false),Values.INTEGER(0),Values.INTEGER(0),Values.INTEGER(0),Values.INTEGER(0),Values.ARRAY({},{0}),
                                Values.BOOL(false),Values.BOOL(false),Values.STRING(""),Values.STRING(""),Values.BOOL(false),Values.STRING("")});

    case ("getTransitions",{Values.CODE(Absyn.C_TYPENAME(className))})
      equation
        false = Interactive.existClass(className, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(className);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then ValuesUtil.makeArray({});

    case ("getTransitions",{Values.CODE(Absyn.C_TYPENAME(className))})
      then getTransitions(className, SymbolTable.getAbsyn());

    case ("getTransitions",_)
      then ValuesUtil.makeArray({});

    case ("addTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_), Values.STRING(_), Values.STRING(_),
                           Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.INTEGER(_), Values.CODE(Absyn.C_EXPRESSION(_))})
      equation
        false = Interactive.existClass(classpath, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        Values.BOOL(false);

    case ("addTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_), Values.STRING(_), Values.STRING(_),
                           Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.INTEGER(_),
                           Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(eqMod=Absyn.NOMOD())))})
      equation
        false = Interactive.existClass(classpath, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        Values.BOOL(false);

    case ("addTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1), Values.STRING(str2), Values.STRING(str3),
                           Values.BOOL(b), Values.BOOL(b1), Values.BOOL(b2), Values.INTEGER(i), Values.CODE(Absyn.C_EXPRESSION(aexp))})
      equation
        (bval, p) = Interactive.addTransition(AbsynUtil.pathToCref(classpath), str1, str2, str3, b, b1, b2, i, Absyn.NAMEDARG("annotate",aexp)::{}, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(bval);

    case ("addTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1), Values.STRING(str2), Values.STRING(str3),
                           Values.BOOL(b), Values.BOOL(b1), Values.BOOL(b2), Values.INTEGER(i),
                           Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(elementArgLst=eltargs,eqMod=Absyn.NOMOD())))})
      equation
        (bval, p) = Interactive.addTransitionWithAnnotation(AbsynUtil.pathToCref(classpath), str1, str2, str3, b, b1, b2, i, Absyn.ANNOTATION(eltargs), SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(bval);

    case ("addTransition",{_,_,_,_,_,_,_,_,_})
      then Values.BOOL(false);

    case ("deleteTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_), Values.STRING(_), Values.STRING(_),
                              Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.INTEGER(_)})
      equation
        false = Interactive.existClass(classpath, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        Values.BOOL(false);

    case ("deleteTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1), Values.STRING(str2), Values.STRING(str3),
                              Values.BOOL(b), Values.BOOL(b1), Values.BOOL(b2), Values.INTEGER(i)})
      equation
        (bval, p) = Interactive.deleteTransition(AbsynUtil.pathToCref(classpath), str1, str2, str3, b, b1, b2, i, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(bval);

    case ("deleteTransition",{_,_,_,_,_,_,_,_})
      then
        Values.BOOL(false);

    case ("updateTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_), Values.STRING(_), Values.STRING(_),
                              Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.INTEGER(_), Values.STRING(_),
                              Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.INTEGER(_), Values.CODE(Absyn.C_EXPRESSION(_))})
      equation
        false = Interactive.existClass(classpath, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        Values.BOOL(false);

    case ("updateTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_), Values.STRING(_), Values.STRING(_),
                              Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.INTEGER(_), Values.STRING(_),
                              Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.INTEGER(_),
                              Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(eqMod=Absyn.NOMOD())))})
      equation
        false = Interactive.existClass(classpath, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        Values.BOOL(false);

    case ("updateTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1), Values.STRING(str2), Values.STRING(str3),
                              Values.BOOL(b), Values.BOOL(b1), Values.BOOL(b2), Values.INTEGER(i), Values.STRING(str4),
                              Values.BOOL(b3), Values.BOOL(b4), Values.BOOL(b5), Values.INTEGER(i1), Values.CODE(Absyn.C_EXPRESSION(aexp))})
      equation
        (bval, p) = Interactive.deleteTransition(AbsynUtil.pathToCref(classpath), str1, str2, str3, b, b1, b2, i, SymbolTable.getAbsyn());
        (bval, p) = Interactive.addTransition(AbsynUtil.pathToCref(classpath), str1, str2, str4, b3, b4, b5, i1, Absyn.NAMEDARG("annotate",aexp)::{}, p);
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(bval);

    case ("updateTransition",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1), Values.STRING(str2), Values.STRING(str3),
                              Values.BOOL(b), Values.BOOL(b1), Values.BOOL(b2), Values.INTEGER(i), Values.STRING(str4),
                              Values.BOOL(b3), Values.BOOL(b4), Values.BOOL(b5), Values.INTEGER(i1),
                              Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(elementArgLst=eltargs,eqMod=Absyn.NOMOD())))})
      equation
        (bval, p) = Interactive.deleteTransition(AbsynUtil.pathToCref(classpath), str1, str2, str3, b, b1, b2, i, SymbolTable.getAbsyn());
        (bval, p) = Interactive.addTransitionWithAnnotation(AbsynUtil.pathToCref(classpath), str1, str2, str4, b3, b4, b5, i1, Absyn.ANNOTATION(eltargs), p);
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(bval);

    case ("updateTransition",_)
      then
        Values.BOOL(false);

    case ("getInitialStates",{Values.CODE(Absyn.C_TYPENAME(className))})
      equation
        false = Interactive.existClass(className, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(className);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        ValuesUtil.makeArray({});

    case ("getInitialStates",{Values.CODE(Absyn.C_TYPENAME(className))})
      then getInitialStates(className, SymbolTable.getAbsyn());

    case ("getInitialStates",_)
      then ValuesUtil.makeArray({});

    case ("addInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_), Values.CODE(Absyn.C_EXPRESSION(_))})
      equation
        false = Interactive.existClass(classpath, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        Values.BOOL(false);

    case ("addInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_),
                             Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(eqMod=Absyn.NOMOD())))})
      equation
        false = Interactive.existClass(classpath, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        Values.BOOL(false);

    case ("addInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1), Values.CODE(Absyn.C_EXPRESSION(aexp))})
      equation
        (bval, p) = addInitialState(classpath, str1, Absyn.NAMEDARG("annotate",aexp)::{}, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(bval);

    case ("addInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1),
                             Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(elementArgLst=eltargs,eqMod=Absyn.NOMOD())))})
      equation
        (bval, p) = addInitialStateWithAnnotation(classpath, str1, Absyn.ANNOTATION(eltargs), SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(bval);

    case ("addInitialState",{_,_,_})
      then Values.BOOL(false);

    case ("deleteInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_)})
      equation
        false = Interactive.existClass(classpath, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        Values.BOOL(false);

    case ("deleteInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1)})
      equation
        (bval, p) = deleteInitialState(classpath, str1, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(bval);

    case ("deleteInitialState",_)
      then
        Values.BOOL(false);

    case ("updateInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_), Values.CODE(Absyn.C_EXPRESSION(_))})
      equation
        false = Interactive.existClass(classpath, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        Values.BOOL(false);

    case ("updateInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(_),
                                Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(eqMod=Absyn.NOMOD())))})
      equation
        false = Interactive.existClass(classpath, SymbolTable.getAbsyn());
        str = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then
        Values.BOOL(false);

    case ("updateInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1), Values.CODE(Absyn.C_EXPRESSION(aexp))})
      equation
        (bval, p) = deleteInitialState(classpath, str1, SymbolTable.getAbsyn());
        (bval, p) = addInitialState(classpath, str1, Absyn.NAMEDARG("annotate",aexp)::{}, p);
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(bval);

    case ("updateInitialState",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str1),
                                Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(elementArgLst=eltargs,eqMod=Absyn.NOMOD())))})
      equation
        (bval, p) = deleteInitialState(classpath, str1, SymbolTable.getAbsyn());
        (bval, p) = addInitialStateWithAnnotation(classpath, str1, Absyn.ANNOTATION(eltargs), p);
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(bval);

    case ("updateInitialState",_)
      then Values.BOOL(false);

    case ("diffModelicaFileListings",{Values.STRING(s1),Values.STRING(s2),Values.ENUM_LITERAL(name=path),Values.BOOL(b)})
      algorithm
        ExecStat.execStatReset();

        (s1, bom) := StringUtil.stripBOM(s1);
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

        (s2, bom) := StringUtil.stripBOM(s2);
        (tokens2, errorTokens) := scanString(s2);
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
            System.writeFile("SanityCheckFailBefore.mo", s3);
            System.writeFile("SanityCheckFailAfter.mo", s4);
            if b then
              Error.addInternalError("After merging the strings, the semantics changed for some reason (see generated files SanityCheckFailBefore.mo SanityCheckFailAfter.mo). Will return the empty string:\ns1:\n"+s1+"\ns2:\n"+s2+"\ns3:\n"+s3+"\ns4:\n"+s4+"\ns5:\n"+s5+"\nparseTree2:"+SimpleModelicaParser.parseTreeStr(parseTree2), sourceInfo());
              fail();
            else
              Error.addInternalError("After merging the strings, the semantics changed for some reason (see generated files SanityCheckFailBefore.mo SanityCheckFailAfter.mo). Will return s2:\ns1:\n"+s1+"\ns2:\n"+s2+"\ns3:\n"+s3+"\ns4:\n"+s4+"\ns5:\n"+s5, sourceInfo());
            end if;
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
      then
        Values.STRING(bom + str);

    case ("diffModelicaFileListings",_) then Values.STRING("");

    // exportToFigaro cases added by Alexander Carlqvist
    case ("exportToFigaro", {Values.CODE(Absyn.C_TYPENAME(path)), Values.STRING(s1), Values.STRING(str), Values.STRING(str1), Values.STRING(str2), Values.STRING(str3)})
      equation
        sp = SymbolTable.getSCode();
        /* The following line of code should be commented out when building from trunk.
        Uncomment when bootstrapping. */
        Figaro.run(sp, path, s1, str, str1, str2, str3);
      then
        Values.BOOL(true);

    case ("exportToFigaro", _) then Values.BOOL(false);

    case ("inferBindings", {Values.CODE(Absyn.C_TYPENAME(classpath))})
       equation
        pnew = Binding.inferBindings(classpath, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(pnew);
      then
         Values.BOOL(true);

    case ("inferBindings", _)
      equation
        print("failed inferBindings\n");
      then
        Values.BOOL(false);

     case ("generateVerificationScenarios", {Values.CODE(Absyn.C_TYPENAME(classpath))})
       equation
        pnew = Binding.generateVerificationScenarios(classpath, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(pnew);
      then
        Values.BOOL(true);

    case ("generateVerificationScenarios", _)
      equation
        print("failed to generateVerificationScenarios\n");
      then
        Values.BOOL(false);

    case ("rewriteBlockCall",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        p = SymbolTable.getAbsyn();
        absynClass = InteractiveUtil.getPathedClassInProgram(path, p);
        classes = {absynClass};
        absynClass = InteractiveUtil.getPathedClassInProgram(classpath, p);
        within_ = InteractiveUtil.buildWithin(classpath);
        pnew = BlockCallRewrite.rewriteBlockCall(Absyn.PROGRAM({absynClass}, within_), Absyn.PROGRAM(classes, within_));
        pnew = InteractiveUtil.updateProgram(pnew, p);
        SymbolTable.setAbsyn(pnew);
        outCache = FCore.emptyCache();
      then
        Values.BOOL(true);

    case ("rewriteBlockCall", _)
      then Values.BOOL(false);

    case ("jacobian",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        (outCache, env, SOME(dae), _) = runFrontEnd(outCache, inEnv, path, true, transform = true);
        filenameprefix = AbsynUtil.pathString(path);
        description = DAEUtil.daeDescription(dae);
        daelow = BackendDAECreate.lower(dae,outCache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        (BackendDAE.DAE({syst},shared)) = BackendDAEUtil.preOptimizeBackendDAE(daelow,NONE());
        (syst,m,_) = BackendDAEUtil.getAdjacencyMatrixfromOption(syst,BackendDAE.NORMAL(),NONE(),BackendDAEUtil.isInitializationDAE(shared));
        vars = BackendVariable.daeVars(syst);
        eqnarr = BackendEquation.getEqnsFromEqSystem(syst);
        (jac, _) = SymbolicJacobian.calculateJacobian(vars, eqnarr, m, false,shared);
        res = BackendDump.dumpJacobianStr(jac);
      then
        Values.STRING(res);

    case ("translateModel",vals as {Values.CODE(Absyn.C_TYPENAME(className)),_,_,_,_,_,Values.STRING(filenameprefix),_,_,_,_,_})
      equation
        (outCache,simSettings) = calculateSimulationSettings(outCache, vals);
        (b,outCache) = translateModel(outCache, inEnv, className, filenameprefix, true, true, SOME(simSettings));
      then
        Values.BOOL(b);

    case ("translateModel",_)
      then Values.BOOL(false);

    case ("modelEquationsUC",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(outputFile),Values.BOOL(dumpExtractionSteps)})
      equation
        (outCache, ret_val) = Uncertainties.modelEquationsUC(outCache, inEnv, className, outputFile,dumpExtractionSteps);
      then
        ret_val;

    case ("modelEquationsUC",_)
      then Values.STRING("There were errors during extraction of uncertainty equations. Use getErrorString() to see them.");

    case ("translateModelFMU", Values.CODE(Absyn.C_TYPENAME(className))::Values.STRING(str1)::Values.STRING(str2)::Values.STRING(filenameprefix)::Values.ARRAY(valueLst=cvars)::_)
      algorithm
        (b, outCache, ret_val) := translateModelFMU(outCache, inEnv, className, str1, str2, filenameprefix, true, list(ValuesUtil.extractValueString(vv) for vv in cvars));
      then
        Values.BOOL(b);

    case ("translateModelFMU", _)
      then Values.STRING("");

    case ("buildModelFMU", Values.CODE(Absyn.C_TYPENAME(className))::Values.STRING(str1)::Values.STRING(str2)::Values.STRING(filenameprefix)::Values.ARRAY(valueLst=cvars)::_)
      algorithm
        (outCache, ret_val) := buildModelFMU(outCache, inEnv, className, str1, str2, filenameprefix, true, list(ValuesUtil.extractValueString(vv) for vv in cvars));
      then
        ret_val;

    case ("buildModelFMU", _)
      then Values.STRING("");

    case ("buildEncryptedPackage", {Values.CODE(Absyn.C_TYPENAME(className)),Values.BOOL(b)})
      algorithm
        p := SymbolTable.getAbsyn();
        b1 := buildEncryptedPackage(className, b, p);
      then
        Values.BOOL(b1);

    case ("buildEncryptedPackage",_)
      then Values.BOOL(false);

    case ("translateModelXML",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)})
      equation
        filenameprefix = Util.stringReplaceChar(filenameprefix,".","_");
        (outCache, ret_val) = translateModelXML(outCache, inEnv, className, filenameprefix, true, NONE());
      then
        ret_val;

    case ("exportDAEtoMatlab",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)})
      equation
        (outCache, ret_val, _) = getAdjacencyMatrix(outCache, inEnv, className, msg, filenameprefix);
      then
        ret_val;

    case ("checkModel",{Values.CODE(Absyn.C_TYPENAME(className))})
      equation
        FlagsUtil.setConfigBool(Flags.CHECK_MODEL, true);
        (outCache, ret_val) = checkModel(outCache, inEnv, className, msg);
        FlagsUtil.setConfigBool(Flags.CHECK_MODEL, false);
      then
        ret_val;

    case ("checkAllModelsRecursive",{Values.CODE(Absyn.C_TYPENAME(className)),Values.BOOL(showProtected)})
      equation
        (outCache, ret_val) = checkAllModelsRecursive(outCache, inEnv, className, showProtected, msg);
      then
        ret_val;

    case ("translateGraphics",{Values.CODE(Absyn.C_TYPENAME(className))})
      then translateGraphics(className, msg);

    case ("getLoadedLibraries",{})
      algorithm
        p := SymbolTable.getAbsyn();
      then
        ValuesUtil.makeArray(List.fold(p.classes,makeLoadLibrariesEntryAbsyn,{}));

    case ("OpenModelica_uriToFilename",{Values.STRING(s1)})
      equation
        res = OpenModelica.Scripting.uriToFilename(s1);
        if Flags.getConfigBool(Flags.BUILDING_FMU) then
          print("The following path is a loaded resource... "+res+"\n");
          fail();
        end if;
      then
        Values.STRING(res);

     /* Note: Only evaluate uriToFilename during scripting. We need simulations to be able to report URI not found */
    case ("OpenModelica_uriToFilename",_)
      guard not Flags.getConfigBool(Flags.BUILDING_MODEL)
      then Values.STRING("");

    case ("getAnnotationVersion",{})
      equation
        res = Config.getAnnotationVersion();
      then
        Values.STRING(res);

    case ("getNoSimplify",{})
      equation
        b = Config.getNoSimplify();
      then
        Values.BOOL(b);

    case ("setNoSimplify",{Values.BOOL(b)})
      equation
        Config.setNoSimplify(b);
      then
        Values.BOOL(true);

    case ("getShowAnnotations",{})
      equation
        b = Config.showAnnotations();
      then
        Values.BOOL(b);

    case ("setShowAnnotations",{Values.BOOL(b)})
      equation
        Config.setShowAnnotations(b);
      then
        Values.BOOL(true);

    case ("getVectorizationLimit",{})
      equation
        i = Config.vectorizationLimit();
      then
        Values.INTEGER(i);

    case ("getOrderConnections",{})
      equation
        b = Config.orderConnections();
      then
        Values.BOOL(b);

    case ("buildModel", vals as Values.CODE(Absyn.C_TYPENAME(className))::_)
      algorithm
        List.map_0(ClockIndexes.buildModelClocks,System.realtimeClear);
        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
        if not Config.simCodeTarget() == "omsic" then
          (b,outCache,compileDir,executable,_,_,initfilename,_,_,vals,_) := buildModel(outCache, inEnv, vals, msg);
        else
          filenameprefix := AbsynUtil.pathString(className);
          try
            (outCache, Values.STRING(str)) := buildModelFMU(outCache, inEnv, className, "2.0", "me", "<default>", true, {"static"});
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
        ValuesUtil.makeArray(if b then {Values.STRING(executable),Values.STRING(initfilename)} else {Values.STRING(""),Values.STRING("")});

    case ("buildModel",_) /* failing build_model */
      then ValuesUtil.makeArray({Values.STRING(""),Values.STRING("")});

    case ("buildLabel",vals)
      equation
        FlagsUtil.setConfigBool(Flags.GENERATE_LABELED_SIMCODE, true);
        //FlagsUtil.set(Flags.WRITE_TO_BUFFER,true);
        List.map_0(ClockIndexes.buildModelClocks,System.realtimeClear);
        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
        (b,outCache,_,executable,_,_,initfilename,_,_,vals,_) = buildModel(outCache,inEnv, vals, msg);
      then
        ValuesUtil.makeArray(if b then {Values.STRING(executable),Values.STRING(initfilename)} else {Values.STRING(""),Values.STRING("")});

     case ("reduceTerms",vals)
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

        (b,outCache,_,executable,_,_,initfilename,_,_,_) = buildModel(outCache,inEnv, vals, msg);
      then
        ValuesUtil.makeArray(if b then {Values.STRING(executable),Values.STRING(initfilename)} else {Values.STRING(""),Values.STRING("")});

    // adrpo: see if the model exists before simulation!
    case ("simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_)
      equation
        false = Interactive.existClass(className, SymbolTable.getAbsyn());
        errMsg = "Simulation Failed. Model: " + AbsynUtil.pathString(className) + " does not exist! Please load it first before simulation.";
      then
        createSimulationResultFailure(errMsg, simOptionsAsString(vals));

    case ("simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_)
      algorithm
        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);

        if Config.simCodeTarget() == "omsicpp" then

         filenameprefix := AbsynUtil.pathString(className);
         (outCache,simSettings) := calculateSimulationSettings(outCache, vals);
         try
             (outCache, Values.STRING(str)) := buildModelFMU(outCache, inEnv, className, "2.0", "me", "<default>", true, {"static"},SOME(simSettings));
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
          (b,outCache,compileDir,executable,_,outputFormat_str,_,simflags,resultValues,vals,dirs) := buildModel(outCache,inEnv,vals,msg);
        else
          Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {"Can't simulate for SimCodeTarget=omsic!\n"});
          fail();
        end if;

        if b then
           exeDir := compileDir;
           (outCache,simSettings) := calculateSimulationSettings(outCache, vals);
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

           resI := System.systemCallRestrictedEnv(sim_call, logFile);

           timeSimulation := System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_SIMULATION);

         else
           result_file := "";
           resI := 1;
           timeSimulation := 0.0;
         end if;

        timeTotal := System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);

        (outCache,simValue) := createSimulationResultFromcallModelExecutable(b,resI,timeTotal,timeSimulation,resultValues,outCache,className,vals,result_file,logFile);
      then
        simValue;

    case ("simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_)
      equation
        Settings.getInstallationDirectoryPath() "simulation fail for some other reason than OPENMODELICAHOME not being set." ;
        str = AbsynUtil.pathString(className);
        res = "Failed to build model: " + str;
      then
        createSimulationResultFailure(res, simOptionsAsString(vals));

    case ("simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_)
      equation
        str = AbsynUtil.pathString(className);
      then
        createSimulationResultFailure(
          "Simulation failed for model: " + str +
          "\nEnvironment variable OPENMODELICAHOME not set.",
          simOptionsAsString(vals));

    case ("moveClass", {Values.CODE(Absyn.C_TYPENAME(className)),
                        Values.INTEGER(direction)})
      algorithm
        (p, b) := moveClass(className, direction, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(b);

    case ("moveClass", _) then Values.BOOL(false);

    case ("moveClassToTop", {Values.CODE(Absyn.C_TYPENAME(className))})
      algorithm
        (p, b) := moveClassToTop(className, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(b);

    case ("moveClassToTop", _) then Values.BOOL(false);

    case ("moveClassToBottom", {Values.CODE(Absyn.C_TYPENAME(className))})
      algorithm
        (p, b) := moveClassToBottom(className, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(b);

    case ("moveClassToBottom", _) then Values.BOOL(false);

    case ("copyClass",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(name), Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        p = SymbolTable.getAbsyn();
        absynClass = InteractiveUtil.getPathedClassInProgram(classpath, p);
        p = copyClass(absynClass, name, InteractiveUtil.parseWithinPath(path), classpath, p);
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(true);

    case ("copyClass", _) then Values.BOOL(false);

    // see if the model exists before linearization!
    case ("linearize",vals as Values.CODE(Absyn.C_TYPENAME(className))::_)
      equation
        false = Interactive.existClass(className, SymbolTable.getAbsyn());
        errMsg = "Linearization Failed. Model: " + AbsynUtil.pathString(className) + " does not exist! Please load it first before linearization.";
      then
        createSimulationResultFailure(errMsg, simOptionsAsString(vals));

    case ("linearize",(vals as Values.CODE(Absyn.C_TYPENAME(className))::_))
      equation
        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);

        (b,outCache,compileDir,executable,_,outputFormat_str,_,simflags,resultValues,vals,dirs) = buildModel(outCache,inEnv,vals,msg);
        if b then
          Values.REAL(linearizeTime) = getListNthShowError(vals,"try to get stop time",0,2);
          executableSuffixedExe = stringAppend(executable, getSimulationExtension(Config.simCodeTarget(),Autoconf.platform));
          logFile = stringAppend(executable,".log");
          if System.regularFileExists(logFile) then
            0 = System.removeFile(logFile);
          end if;
          strlinearizeTime = realString(linearizeTime);
          sim_call = stringAppendList({"\"",compileDir,executableSuffixedExe,"\""," ","-l=",strlinearizeTime," ",simflags});
          System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_SIMULATION);
          SimulationResults.close() "Windows cannot handle reading and writing to the same file from different processes like any real OS :(";

          if 0 == System.systemCallRestrictedEnv(sim_call, logFile) then
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
        simValue;

    case ("linearize",vals as Values.CODE(Absyn.C_TYPENAME(className))::_)
      equation
        str = AbsynUtil.pathString(className);
        res = "Failed to run the linearize command: " + str;
      then
        createSimulationResultFailure(res, simOptionsAsString(vals));

    case ("optimize",(vals as Values.CODE(Absyn.C_TYPENAME(className))::_))
      equation
        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);

        FlagsUtil.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION,true);
        FlagsUtil.setConfigEnum(Flags.GRAMMAR, Flags.OPTIMICA);
        FlagsUtil.setConfigBool(Flags.GENERATE_DYN_OPTIMIZATION_PROBLEM,true);

        (b,outCache,compileDir,executable,_,outputFormat_str,_,simflags,resultValues,vals,dirs) = buildModel(outCache,inEnv,vals,msg);
        if b then
          exeDir=compileDir;
          (outCache,simSettings) = calculateSimulationSettings(outCache, vals);
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
          resI = System.systemCallRestrictedEnv(sim_call, logFile);
          timeSimulation = System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_SIMULATION);
        else
          result_file = "";
          timeSimulation = 0.0;
          resI = 1;
        end if;
        timeTotal = System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
        (outCache,simValue) = createSimulationResultFromcallModelExecutable(b,resI,timeTotal,timeSimulation,resultValues,outCache,className,vals,result_file,logFile);
      then
        simValue;

    case ("optimize",vals as Values.CODE(Absyn.C_TYPENAME(className))::_)
      equation
        str = AbsynUtil.pathString(className);
        res = "Failed to run the optimize command: " + str;
      then
        createSimulationResultFailure(res, simOptionsAsString(vals));

    case ("instantiateModel", {Values.CODE(Absyn.C_TYPENAME(className))})
      algorithm
        (outCache, ret_val) := instantiateModel(outCache, inEnv, className);
      then
        ret_val;

    case ("moo",(vals as Values.CODE(Absyn.C_TYPENAME(className))::_))
      equation
        System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);

        FlagsUtil.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION,true);
        FlagsUtil.setConfigEnum(Flags.GRAMMAR, Flags.OPTIMICA);
        FlagsUtil.setConfigBool(Flags.GENERATE_DYN_OPTIMIZATION_PROBLEM,true);

        (b,outCache,compileDir,executable,_,outputFormat_str,_,simflags,resultValues,vals,dirs) = buildModel(outCache,inEnv,vals,msg);
        simflags = stringAppend(simflags, " -moo");
        if b then
          exeDir=compileDir;
          (outCache,simSettings) = calculateSimulationSettings(outCache, vals);
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
          resI = System.systemCallRestrictedEnv(sim_call, logFile);
          timeSimulation = System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_SIMULATION);
        else
          result_file = "";
          timeSimulation = 0.0;
          resI = 1;
        end if;
        timeTotal = System.realtimeTock(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
        (outCache,simValue) = createSimulationResultFromcallModelExecutable(b,resI,timeTotal,timeSimulation,resultValues,outCache,className,vals,result_file,logFile);
      then
        simValue;

    case ("moo",vals as Values.CODE(Absyn.C_TYPENAME(className))::_)
      equation
        str = AbsynUtil.pathString(className);
        res = "Failed to run the moo command: " + str;
      then
        createSimulationResultFailure(res, simOptionsAsString(vals));

    case ("importFMU",{Values.STRING(filename),Values.STRING(workdir),Values.INTEGER(fmiLogLevel),Values.BOOL(b1), Values.BOOL(b2), Values.BOOL(inputConnectors), Values.BOOL(outputConnectors), Values.CODE(Absyn.C_TYPENAME(classpath))})
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
        name = AbsynUtil.pathString(classpath);
        name = if stringEq(name, "Default") or stringEq(name, "default") then "" else name;
        str = Tpl.tplString2(CodegenFMU.importFMUModelica, FMI.FMIIMPORT(s1, filename, workdir, fmiLogLevel, b2, fmiContext, fmiInstance, fmiInfo, fmiTypeDefinitionsList, fmiExperimentAnnotation, fmiModelVariablesInstance, fmiModelVariablesList, inputConnectors, outputConnectors), name);
        pd = Autoconf.pathDelimiter;
        str1 = FMI.getFMIModelIdentifier(fmiInfo);
        str2 = FMI.getFMIType(fmiInfo);
        str3 = FMI.getFMIVersion(fmiInfo);
        outputFile = if stringEmpty(name) then stringAppendList({str1,"_",str2,"_FMU.mo"}) else stringAppendList({name,".mo"});
        filename_1 = if b1 then stringAppendList({workdir,pd,outputFile}) else outputFile;
        System.writeFile(stringAppendList({workdir,pd,outputFile}), str);
        /* Release FMI objects */
        FMIExt.releaseFMIImport(fmiModelVariablesInstance, fmiInstance, fmiContext, str3);
      then
        Values.STRING(filename_1);

    case ("importFMU",{Values.STRING(filename),Values.STRING(_),Values.INTEGER(_),Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.CODE(_)})
      equation
        false = System.regularFileExists(filename);
        Error.clearMessages() "Clear messages";
        Error.addMessage(Error.FILE_NOT_FOUND_ERROR, {filename});
      then
        Values.STRING("");

    case ("importFMU",{Values.STRING(_),Values.STRING(_),Values.INTEGER(_),Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.CODE(_)})
      then
        Values.STRING("");

    case ("importFMUModelDescription",{Values.STRING(filename), Values.STRING(workdir),Values.INTEGER(fmiLogLevel),Values.BOOL(b1), Values.BOOL(b2), Values.BOOL(inputConnectors), Values.BOOL(outputConnectors)})
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
        Values.STRING(filename_1);

    case ("importFMUModelDescription",{Values.STRING(filename),Values.STRING(_),Values.INTEGER(_),Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.BOOL(_)})
      equation
        if not System.regularFileExists(filename) then
          Error.addMessage(Error.FILE_NOT_FOUND_ERROR, {filename});
        end if;
      then
        Values.STRING("");

    case ("importFMUModelDescription",{Values.STRING(_),Values.STRING(_),Values.INTEGER(_),Values.BOOL(_), Values.BOOL(_), Values.BOOL(_), Values.BOOL(_)})
      then
        Values.STRING("");

    case ("getIndexReductionMethod",_)
      equation
        str = Config.getIndexReductionMethod();
      then
        Values.STRING(str);

    case ("getAvailableIndexReductionMethods",_)
      equation
        (strs1,strs2) = FlagsUtil.getConfigOptionsStringList(Flags.INDEX_REDUCTION_METHOD);
        v1 = ValuesUtil.makeArray(List.map(strs1, ValuesUtil.makeString));
        v2 = ValuesUtil.makeArray(List.map(strs2, ValuesUtil.makeString));
      then
        Values.TUPLE({v1,v2});

    else
      algorithm
        (outCache, ret_val) := cevalInteractiveFunctions4(inCache,inEnv,inFunctionName,inVals,msg);
      then
        ret_val;

  end matchcontinue;
end cevalInteractiveFunctions3;

public function cevalInteractiveFunctions4
"defined in the interactive environment."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String inFunctionName;
  input list<Values.Value> inVals;
  input Absyn.Msg msg;
  output FCore.Cache outCache = inCache;
  output Values.Value outValue;
protected
  import LexerModelicaDiff.{Token,TokenId,tokenContent,scanString,reportErrors,filterModelicaDiff,modelicaDiffTokenEq,modelicaDiffTokenWhitespace};
  import DiffAlgorithm.{Diff,diff,printActual,printDiffTerminalColor,printDiffXml};
algorithm
  outValue := matchcontinue (inFunctionName, inVals)
    local
      String s1,s2,str,str1,str2,str3,str4,method_str, pd,filename_1,filename,
             call,name, title,xLabel,yLabel,yLabelRight,filename2,varNameStr,xml_filename,pwd,omhome,os,
             gridStr, logXStr, logYStr, x1Str, x2Str, y1Str, y2Str, y1RStr, y2RStr, yAxis, curveWidthStr, curveStyleStr, legendPosition, footer, autoScaleStr,
             cname, annStr, annotationname, modifiername;
      list<Values.Value> vals,vals2,cvars;
      Absyn.Path path,classpath,baseClassPath;
      Interactive.GraphicEnvCache genv;
      Absyn.Program p,newp;
      GlobalScript.SimulationOptions simOpt;
      Real startTime,stopTime,tolerance,reltol,reltolDiffMinMax,rangeDelta;
      DAE.Exp startTimeExp,stopTimeExp,toleranceExp,intervalExp;
      DAE.Type tp;
      Absyn.Class absynClass;
      Absyn.ClassDef cdef;
      Absyn.Exp aexp, aexp2, aexp3;
      Option<DAE.DAElist> odae;
      Values.Value v,cvar,cvar2,v1,v2;
      Absyn.ComponentRef cr, cr2;
      Integer size,i,n,curveStyle,numberOfIntervals,x,y;
      Access access;
      list<String> vars_1,args,strings,strs1,strs2,files;
      Real timeStamp,val,x1,x2,y1,y2,y1R,y2R,r1,r2,curveWidth, interval;
      GlobalScript.Statements istmts;
      Boolean b, b1, b2, b3, externalWindow, logX, logY, autoScale, forceOMPlot, keepRedeclares, hintReadAllVars;
      list<Real> realVals;
      list<Absyn.Path> paths;
      list<Absyn.NamedArg> nargs;
      list<Absyn.ElementArg> annlst;
      list<tuple<Absyn.Path,String,list<String>,Boolean>> uses;
      list<String> withoutConversion, withConversion;
      list<tuple<String,String>> relocatableFunctionsTuple;
      list<list<Values.Value>> valsLst;
      SourceInfo info;
      System.StatFileType statFileType;
      Absyn.Modification mod;

    case ("getAvailableIndexReductionMethods",_)
      equation
        (strs1,strs2) = FlagsUtil.getConfigOptionsStringList(Flags.INDEX_REDUCTION_METHOD);
        v1 = ValuesUtil.makeArray(List.map(strs1, ValuesUtil.makeString));
        v2 = ValuesUtil.makeArray(List.map(strs2, ValuesUtil.makeString));
      then
        Values.TUPLE({v1,v2});

    case ("getMatchingAlgorithm",_)
      then Values.STRING(Config.getMatchingAlgorithm());

    case ("getAvailableMatchingAlgorithms",_)
      equation
        (strs1,strs2) = FlagsUtil.getConfigOptionsStringList(Flags.MATCHING_ALGORITHM);
        v1 = ValuesUtil.makeArray(List.map(strs1, ValuesUtil.makeString));
        v2 = ValuesUtil.makeArray(List.map(strs2, ValuesUtil.makeString));
      then
        Values.TUPLE({v1,v2});

    case ("getTearingMethod",_)
      then Values.STRING(Config.getTearingMethod());

    case ("getAvailableTearingMethods",_)
      equation
        (strs1,strs2) = FlagsUtil.getConfigOptionsStringList(Flags.TEARING_METHOD);
        v1 = ValuesUtil.makeArray(List.map(strs1, ValuesUtil.makeString));
        v2 = ValuesUtil.makeArray(List.map(strs2, ValuesUtil.makeString));
      then
        Values.TUPLE({v1,v2});

    case ("saveModel",{Values.STRING(filename),Values.CODE(Absyn.C_TYPENAME(classpath))})
      algorithm
        b := false;
        access := Interactive.checkAccessAnnotationAndEncryption(classpath, SymbolTable.getAbsyn());
        if access >= Access.all then // i.e., The class is not encrypted.
          absynClass := InteractiveUtil.getPathedClassInProgram(classpath, SymbolTable.getAbsyn());
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
        Values.BOOL(b);

    case ("save",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        access = Interactive.checkAccessAnnotationAndEncryption(classpath, SymbolTable.getAbsyn());
        if access >= Access.all then // i.e., The class is not encrypted.
          (newp,filename) = Interactive.getContainedClassAndFile(classpath, SymbolTable.getAbsyn());
          str = Dump.unparseStr(newp);
          System.writeFile(filename, str);
          b = true;
        else
          Error.addMessage(Error.SAVE_ENCRYPTED_CLASS_ERROR, {});
          b = false;
        end if;
      then
        Values.BOOL(b);

    case ("save",{Values.CODE(Absyn.C_TYPENAME(_))})
      then Values.BOOL(false);

    case ("saveAll",{Values.STRING(filename)})
      equation
        str = Dump.unparseStr(SymbolTable.getAbsyn(),true);
        System.writeFile(filename, str);
      then
        Values.BOOL(true);

    case ("saveModel",{Values.STRING(_),Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        cname = AbsynUtil.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {cname,"global"});
      then
        Values.BOOL(false);

    case ("saveTotalModel",{Values.STRING(filename),Values.CODE(Absyn.C_TYPENAME(classpath)),
                                    Values.BOOL(b1), Values.BOOL(b2), Values.BOOL(b3)})
      equation
        access = Interactive.checkAccessAnnotationAndEncryption(classpath, SymbolTable.getAbsyn());
        if access >= Access.all then
          saveTotalModel(filename, classpath, b1, b2, b3);
          b = true;
        else
          Error.addMessage(Error.SAVE_ENCRYPTED_CLASS_ERROR, {});
          b = false;
        end if;
      then
        Values.BOOL(b);

    case ("saveTotalModel",{Values.STRING(_),Values.CODE(Absyn.C_TYPENAME(_)),
                            Values.BOOL(_), Values.BOOL(_), Values.BOOL(_)})
      then Values.BOOL(false);

    case ("saveTotalModelDebug",{Values.STRING(filename),Values.CODE(Absyn.C_TYPENAME(classpath)),
                                 Values.BOOL(b1), Values.BOOL(b2), Values.BOOL(b3)})
      equation
        access = Interactive.checkAccessAnnotationAndEncryption(classpath, SymbolTable.getAbsyn());
        if access >= Access.all then // i.e., Access.documentation
          saveTotalModelDebug(filename, classpath, b1, b2, b3);
          b = true;
        else
          Error.addMessage(Error.SAVE_ENCRYPTED_CLASS_ERROR, {});
          b = false;
        end if;
      then
        Values.BOOL(b);

    case ("saveTotalModelDebug",{Values.STRING(_),Values.CODE(Absyn.C_TYPENAME(_))})
      then Values.BOOL(false);

    case ("getDocumentationAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        access = Interactive.checkAccessAnnotationAndEncryption(classpath, SymbolTable.getAbsyn());
        if access >= Access.documentation then
          ((str1,str2,str3)) = Interactive.getNamedAnnotationExp(classpath, SymbolTable.getAbsyn(), Absyn.IDENT("Documentation"), SOME(("","","")),Interactive.getDocumentationAnnotationString);
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          ((str1,str2,str3)) = ("", "", "");
        end if;
      then
        ValuesUtil.makeArray({Values.STRING(str1),Values.STRING(str2),Values.STRING(str3)});

    case ("addClassAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.CODE(Absyn.C_EXPRESSION(aexp))})
      equation
        p = Interactive.addClassAnnotation(AbsynUtil.pathToCref(classpath), Absyn.NAMEDARG("annotate",aexp)::{}, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(true);

    case ("addClassAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(elementArgLst=annlst,eqMod=Absyn.NOMOD())))})
      algorithm
        p := SymbolTable.getAbsyn();
        absynClass := InteractiveUtil.getPathedClassInProgram(classpath, p);
        absynClass := Interactive.addClassAnnotationToClass(absynClass, Absyn.ANNOTATION(annlst));
        p := InteractiveUtil.updateProgram(Absyn.PROGRAM({absynClass}, if AbsynUtil.pathIsIdent(classpath) then Absyn.TOP() else Absyn.WITHIN(AbsynUtil.stripLast(classpath))), p);
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(true);

    case ("addClassAnnotation",_)
      then Values.BOOL(false);

    case ("setDocumentationAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(str1),Values.STRING(str2)})
      equation
        p = SymbolTable.getAbsyn();
        nargs = List.consOnTrue(not stringEq(str1,""), Absyn.NAMEDARG("info",Absyn.STRING(System.escapedString(str1,false))), {});
        nargs = List.consOnTrue(not stringEq(str2,""), Absyn.NAMEDARG("revisions",Absyn.STRING(System.escapedString(str2,false))), nargs);
        aexp = Absyn.CALL(Absyn.CREF_IDENT("Documentation",{}),Absyn.FUNCTIONARGS({},nargs),{});
        p = Interactive.addClassAnnotation(AbsynUtil.pathToCref(classpath), Absyn.NAMEDARG("annotate",aexp)::{}, p);
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(true);

    case ("setDocumentationAnnotation",_)
      then Values.BOOL(false);

    case ("stat",{Values.STRING(str)})
      algorithm
        (b,r1,r2) := System.stat(str);
      then Values.TUPLE({Values.BOOL(b),Values.REAL(r1),Values.REAL(r2)});

    case ("regularFileExists",{Values.STRING(str)})
      algorithm
        (_,_,_,statFileType) := System.stat(str);
      then Values.BOOL(statFileType==System.StatFileType.RegularFile);

    case ("directoryExists",{Values.STRING(str)})
      algorithm
        (_,_,_,statFileType) := System.stat(str);
      then Values.BOOL(statFileType==System.StatFileType.Directory);

    case ("OpenModelicaInternal_fullPathName",{Values.STRING(str)})
      then Values.STRING(System.realpath(str));

    case ("isType",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        b = Interactive.isType(classpath, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isPackage",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        b = Interactive.isPackage(classpath, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isClass",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        b = Interactive.isClass(classpath, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isRecord",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        b = Interactive.isRecord(classpath, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isBlock",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        b = Interactive.isBlock(classpath, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isFunction",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        b = Interactive.isFunction(classpath, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isPartial",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        b = Interactive.isPartial(classpath, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isReplaceable",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        b = Interactive.isReplaceable(path, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isRedeclare",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        b = Interactive.isRedeclare(path, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isModel",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        b = Interactive.isModel(classpath, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isConnector",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        b = Interactive.isConnector(classpath, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isOptimization",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        b = Interactive.isOptimization(classpath, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isEnumeration",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        b = Interactive.isEnumeration(classpath, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isOperator",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        b = Interactive.isOperator(classpath, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isOperatorRecord",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        b = Interactive.isOperatorRecord(classpath, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isOperatorFunction",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        b = Interactive.isOperatorFunction(classpath, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("isProtectedClass",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(name)})
      equation
        b = Interactive.isProtectedClass(classpath, name, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("getBuiltinType",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        (_, tp, _) = Lookup.lookupType(outCache, inEnv, classpath, SOME(AbsynUtil.dummyInfo));
        str = Types.unparseType(tp);
      then
        Values.STRING(str);

    // if the lookup fails
    case ("getBuiltinType",{Values.CODE(Absyn.C_TYPENAME(_))})
      then Values.STRING("");

    case ("extendsFrom",
          {Values.CODE(Absyn.C_TYPENAME(classpath)),
           Values.CODE(Absyn.C_TYPENAME(baseClassPath))})
      equation
        paths = Interactive.getAllInheritedClasses(classpath, SymbolTable.getAbsyn());
        b = List.applyAndFold1(paths, boolOr, AbsynUtil.pathSuffixOfr, baseClassPath, false);
      then
        Values.BOOL(b);

    case ("extendsFrom",_)
      then Values.BOOL(false);

    case ("isExperiment",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Values.BOOL(isExperiment(classpath, SymbolTable.getAbsyn()));

    case ("getInheritedClasses",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        paths = Interactive.getInheritedClasses(classpath);
      then
        ValuesUtil.makeCodeTypeNameArray(paths);

    case ("getInheritedClasses",_)
      then ValuesUtil.makeArray({});

    case ("getComponentsTest",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(classpath, SymbolTable.getAbsyn());
        genv = Interactive.getClassEnv(SymbolTable.getAbsyn(), classpath);
        valsLst = list(getComponentInfo(c, genv, isProtected=false) for c in InteractiveUtil.getPublicComponentsInClass(absynClass));
        valsLst = listAppend(list(getComponentInfo(c, genv, isProtected=true) for c in InteractiveUtil.getProtectedComponentsInClass(absynClass)), valsLst);
      then ValuesUtil.makeArray(List.flatten(valsLst));

    case ("getComponentsTest",{Values.CODE(Absyn.C_TYPENAME(_))})
      then ValuesUtil.makeArray({});

    case ("getSimulationOptions",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.REAL(startTime),Values.REAL(stopTime),Values.REAL(tolerance),Values.INTEGER(numberOfIntervals),Values.REAL(interval)})
      equation
        cr = AbsynUtil.pathToCref(classpath);
        // ignore the name of the model
        ErrorExt.setCheckpoint("getSimulationOptions");
        simOpt = GlobalScript.SIMULATION_OPTIONS(DAE.RCONST(startTime),DAE.RCONST(stopTime),DAE.ICONST(numberOfIntervals),DAE.RCONST(0.0),DAE.RCONST(tolerance),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""),DAE.SCONST(""));
        ErrorExt.rollBack("getSimulationOptions");
        (_, _::startTimeExp::stopTimeExp::intervalExp::toleranceExp::_) = StaticScript.getSimulationArguments(FCore.emptyCache(), FGraph.empty(), {Absyn.CREF(cr)},{},false,DAE.NOPRE(), "getSimulationOptions", AbsynUtil.dummyInfo,SOME(simOpt));
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
        Values.TUPLE({Values.REAL(startTime), Values.REAL(stopTime), Values.REAL(tolerance), Values.INTEGER(numberOfIntervals), Values.REAL(interval)});

    case ("getAnnotationNamedModifiers",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(annotationname)})
      then getAnnotationNamedModifiers(classpath, annotationname, SymbolTable.getAbsyn());

     case ("getAnnotationModifierValue",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(annotationname),Values.STRING(modifiername)})
       then getAnnotationModifierValue(classpath, annotationname, modifiername, SymbolTable.getAbsyn());

    case ("searchClassNames",{Values.STRING(str), Values.BOOL(b)})
      equation
        (_,paths) = InteractiveUtil.getClassNamesRecursive(NONE(),SymbolTable.getAbsyn(),false,false,{});
        paths = listReverse(paths);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
        vals = searchClassNames(vals, str, b, SymbolTable.getAbsyn());
      then
        ValuesUtil.makeArray(vals);

    case ("getAvailableLibraries",{})
      algorithm
        PackageManagement.installCachedPackages();
        files := PackageManagement.AvailableLibraries.listKeys(PackageManagement.getInstalledLibraries());
      then
        ValuesUtil.makeArray(List.map(files, ValuesUtil.makeString));

    case ("getAvailableLibraryVersions",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT(str1)))})
      algorithm
        PackageManagement.installCachedPackages();
        files := PackageManagement.getInstalledLibraryVersions(str1);
      then
        ValuesUtil.makeArray(List.map(files, ValuesUtil.makeString));

    case ("installPackage",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT(str1))), Values.STRING(str2), Values.BOOL(b)})
      then Values.BOOL(PackageManagement.installPackage(str1, str2, b));

    case ("installPackage",{Values.CODE(Absyn.C_TYPENAME(path as Absyn.QUALIFIED())), _, _})
      algorithm
        Error.addMessage(Error.ERROR_PKG_NOT_IDENT, {AbsynUtil.pathString(path)});
      then
        Values.BOOL(false);

    case ("installPackage",_)
      then Values.BOOL(false);

    case ("updatePackageIndex",{})
      then Values.BOOL(PackageManagement.updateIndex());

    case ("upgradeInstalledPackages",{Values.BOOL(b)})
      then Values.BOOL(PackageManagement.upgradeInstalledPackages(b));

    case ("getAvailablePackageVersions",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT(str1))), Values.STRING(str2)})
      then ValuesUtil.makeArray(list(ValuesUtil.makeString(s) for s in PackageManagement.versionsThatProvideTheWanted(str1, str2, true)));

    case ("getAvailablePackageVersions",_)
      then ValuesUtil.makeArray({});

    case ("getAvailablePackageConversionsFrom",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT(str1))), Values.STRING(str2)})
      then ValuesUtil.makeStringArray(PackageManagement.versionsThatConvertFromTheWanted(str1, str2, true));

    case ("getAvailablePackageConversionsFrom",_)
      then ValuesUtil.makeArray({});

    case ("getAvailablePackageConversionsTo",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT(str1))), Values.STRING(str2)})
      then ValuesUtil.makeStringArray(PackageManagement.versionsThatConvertToTheWanted(str1, str2, true));

    case ("getAvailablePackageConversionsTo",_)
      then ValuesUtil.makeArray({});

    case ("getUses",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        (absynClass as Absyn.CLASS()) = InteractiveUtil.getPathedClassInProgram(classpath, SymbolTable.getAbsyn());
        uses = Interactive.getUsesAnnotation(Absyn.PROGRAM({absynClass},Absyn.TOP()));
      then
        ValuesUtil.makeArray(List.map(uses,makeUsesArray));

    case ("getConversionsFromVersions",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        (absynClass as Absyn.CLASS()) = InteractiveUtil.getPathedClassInProgram(classpath, SymbolTable.getAbsyn());
        (withoutConversion,withConversion) = Interactive.getConversionAnnotation(absynClass);
      then
        Values.TUPLE({ValuesUtil.makeArray(List.map(withoutConversion,ValuesUtil.makeString)), ValuesUtil.makeArray(List.map(withConversion,ValuesUtil.makeString))});

    case ("getDerivedClassModifierNames",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(classpath, SymbolTable.getAbsyn());
        args = Interactive.getDerivedClassModifierNames(absynClass);
        vals = List.map(args, ValuesUtil.makeString);
      then
        ValuesUtil.makeArray(vals);

    case ("getDerivedClassModifierValue",{Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(classpath, SymbolTable.getAbsyn());
        str = Interactive.getDerivedClassModifierValue(absynClass, path);
      then
        Values.STRING(str);

    case ("getAstAsCorbaString",{Values.STRING("<interactive>")})
      equation
        Print.clearBuf();
        Dump.getAstAsCorbaString(SymbolTable.getAbsyn());
        str = Print.getString();
        Print.clearBuf();
      then
        Values.STRING(str);

    case ("getAstAsCorbaString",{Values.STRING(str)})
      equation
        Print.clearBuf();
        Dump.getAstAsCorbaString(SymbolTable.getAbsyn());
        Print.writeBuf(str);
        Print.clearBuf();
        str = "Wrote result to file: " + str;
      then
        Values.STRING(str);

    case ("getAstAsCorbaString",_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"getAstAsCorbaString failed"});
      then
        Values.STRING("");

    case ("readSimulationResult",{Values.STRING(filename),Values.ARRAY(valueLst=cvars),Values.INTEGER(size)})
      equation
        vars_1 = List.map(cvars, ValuesUtil.printCodeVariableName);
        filename = Util.absoluteOrRelative(filename);
      then
        SimulationResults.readDataset(filename, vars_1, size);

    case ("readSimulationResult",_)
      equation
        Error.addMessage(Error.SCRIPT_READ_SIM_RES_ERROR, {});
      then
        Values.META_FAIL();

    case ("readSimulationResultSize",{Values.STRING(filename)})
      equation
        filename = Util.absoluteOrRelative(filename);
        i = SimulationResults.readSimulationResultSize(filename);
      then
        Values.INTEGER(i);

    case ("readSimulationResultVars",{Values.STRING(filename),Values.BOOL(b1),Values.BOOL(b2)})
      equation
        filename = Util.absoluteOrRelative(filename);
        args = SimulationResults.readVariables(filename, b1, b2);
        vals = List.map(args, ValuesUtil.makeString);
      then
        ValuesUtil.makeArray(vals);

    case ("compareSimulationResults",{Values.STRING(filename),Values.STRING(filename_1),Values.STRING(filename2),Values.REAL(x1),Values.REAL(x2),Values.ARRAY(valueLst=cvars)})
      equation
        Error.addMessage(Error.DEPRECATED_API_CALL, {"compareSimulationResults", "diffSimulationResults"});
        filename = Util.absoluteOrRelative(filename);
        filename_1 = Testsuite.friendlyPath(filename_1);
        filename_1 = Util.absoluteOrRelative(filename_1);
        filename2 = Util.absoluteOrRelative(filename2);
        vars_1 = List.map(cvars, ValuesUtil.extractValueString);
        strings = SimulationResults.cmpSimulationResults(Testsuite.isRunning(),filename,filename_1,filename2,x1,x2,vars_1);
        cvars = List.map(strings,ValuesUtil.makeString);
      then
        ValuesUtil.makeArray(cvars);

    case ("compareSimulationResults",_)
      then Values.STRING("Error in compareSimulationResults");

    case ("deltaSimulationResults",{Values.STRING(filename),Values.STRING(filename_1),Values.STRING(method_str),Values.ARRAY(valueLst=cvars)})
      equation
        filename = Util.absoluteOrRelative(filename);
        filename_1 = Testsuite.friendlyPath(filename_1);
        filename_1 = Util.absoluteOrRelative(filename_1);
        vars_1 = List.map(cvars, ValuesUtil.extractValueString);
        val = SimulationResults.deltaSimulationResults(filename,filename_1,method_str,vars_1);
      then
        Values.REAL(val);

    case ("deltaSimulationResults",_)
      then Values.STRING("Error in deltaSimulationResults");

    case ("filterSimulationResults",{Values.STRING(filename),Values.STRING(filename_1),Values.ARRAY(valueLst=cvars),Values.INTEGER(numberOfIntervals),Values.BOOL(b),Values.BOOL(hintReadAllVars)})
      equation
        vars_1 = List.map(cvars, ValuesUtil.extractValueString);
        b = SimulationResults.filterSimulationResults(filename,filename_1,vars_1,numberOfIntervals,b,hintReadAllVars=hintReadAllVars);
      then
        Values.BOOL(b);

    case ("filterSimulationResults",_)
      then Values.BOOL(false);

    case ("diffSimulationResults",{Values.STRING(filename),Values.STRING(filename_1),Values.STRING(filename2),Values.REAL(reltol),Values.REAL(reltolDiffMinMax),Values.REAL(rangeDelta),Values.ARRAY(valueLst=cvars),Values.BOOL(b)})
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
        Values.TUPLE({Values.BOOL(b),v1});

    case ("diffSimulationResults",_)
      equation
        v = ValuesUtil.makeArray({});
      then
        Values.TUPLE({Values.BOOL(false),v});

    case ("diffSimulationResultsHtml",{Values.STRING(str),Values.STRING(filename),Values.STRING(filename_1),Values.REAL(reltol),Values.REAL(reltolDiffMinMax),Values.REAL(rangeDelta)})
      equation
        filename = Util.absoluteOrRelative(filename);
        filename_1 = Testsuite.friendlyPath(filename_1);
        filename_1 = Util.absoluteOrRelative(filename_1);
        str = SimulationResults.diffSimulationResultsHtml(Testsuite.isRunning(),filename,filename_1,reltol,reltolDiffMinMax,rangeDelta,str);
      then
        Values.STRING(str);

    case ("diffSimulationResultsHtml",_)
      then Values.STRING("");

    case ("checkTaskGraph",{Values.STRING(filename),Values.STRING(filename_1)})
      equation
        pwd = System.pwd();
        pd = Autoconf.pathDelimiter;
        filename = if StringUtil.startsWith(filename, "/") then filename else stringAppendList({pwd,pd,filename});
        filename_1 = if StringUtil.startsWith(filename_1, "/") then filename_1 else stringAppendList({pwd,pd,filename_1});
        strings = TaskGraphResults.checkTaskGraph(filename, filename_1);
        cvars = List.map(strings,ValuesUtil.makeString);
      then
        ValuesUtil.makeArray(cvars);

    case ("checkTaskGraph",_)
      then Values.STRING("Error in checkTaskGraph");

    case ("checkCodeGraph",{Values.STRING(filename),Values.STRING(filename_1)})
      equation
        pwd = System.pwd();
        pd = Autoconf.pathDelimiter;
        filename = if StringUtil.startsWith(filename, "/") then filename else stringAppendList({pwd,pd,filename});
        filename_1 = if StringUtil.startsWith(filename_1, "/") then filename_1 else stringAppendList({pwd,pd,filename_1});
        strings = TaskGraphResults.checkCodeGraph(filename, filename_1);
        cvars = List.map(strings,ValuesUtil.makeString);
      then
        ValuesUtil.makeArray(cvars);

    case ("checkCodeGraph",_)
      then Values.STRING("Error in checkCodeGraph");

    //plotAll(model)
    case ("plotAll",
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
          Values.BOOL(forceOMPlot),
          Values.STRING(yAxis),
          Values.STRING(yLabelRight),
          Values.ARRAY(valueLst={Values.REAL(y1R),Values.REAL(y2R)})
        })
      equation
        // get OPENMODELICAHOME
        omhome = Settings.getInstallationDirectoryPath();
        // get the simulation filename
        (outCache,filename) = cevalCurrentSimulationResultExp(outCache,inEnv,filename,msg);
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
          str3 = "--filename=\"" + filename + "\" --title=\"" + title + "\" --grid=" + gridStr + " --plotAll --logx=" + boolString(logX) + " --logy=" + boolString(logY) + " --yaxis=\"" + yAxis + "\" --xlabel=\"" + xLabel + "\" --ylabel=\"" + yLabel + "\" --ylabel-right=\"" + yLabelRight + "\" --xrange=" + realString(x1) + ":" + realString(x2) + " --yrange=" + realString(y1) + ":" + realString(y2) + " --yrange-right=" + realString(y1R) + ":" + realString(y2R) + " --new-window=" + boolString(externalWindow) + " --curve-width=" + realString(curveWidth) + " --curve-style=" + intString(curveStyle) + " --legend-position=\"" + legendPosition + "\" --footer=\"" + footer + "\" --auto-scale=" + boolString(autoScale);
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
        Values.BOOL(true);

    case ("plotAll",_)
      then Values.BOOL(false);

    // plot(x, model)
    case ("plot",
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
          Values.BOOL(forceOMPlot),
          Values.STRING(yAxis),
          Values.STRING(yLabelRight),
          Values.ARRAY(valueLst={Values.REAL(y1R),Values.REAL(y2R)})
        })
      equation
        // get the variables list
        vars_1 = List.map(cvars, ValuesUtil.printCodeVariableName);
        // get OPENMODELICAHOME
        omhome = Settings.getInstallationDirectoryPath();
        // get the simulation filename
        (outCache,filename) = cevalCurrentSimulationResultExp(outCache,inEnv,filename,msg);
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
          str3 = "--filename=\"" + filename + "\" --title=\"" + title + "\" --grid=" + gridStr + " --plot --logx=" + boolString(logX) + " --logy=" + boolString(logY) + " --yaxis=\"" + yAxis + "\" --xlabel=\"" + xLabel + "\" --ylabel=\"" + yLabel + "\" --ylabel-right=\"" + yLabelRight + "\" --xrange=" + realString(x1) + ":" + realString(x2) + " --yrange=" + realString(y1) + ":" + realString(y2) + " --yrange-right=" + realString(y1R) + ":" + realString(y2R) + " --new-window=" + boolString(externalWindow) + " --curve-width=" + realString(curveWidth) + " --curve-style=" + intString(curveStyle) + " --legend-position=\"" + legendPosition + "\" --footer=\"" + footer + "\" --auto-scale=" + boolString(autoScale) + " \"" + str + "\"";
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
        Values.BOOL(true);

    case ("plot",_)
      then Values.BOOL(false);

    case ("val",{cvar,Values.REAL(timeStamp),Values.STRING("<default>")})
      equation
        (outCache,Values.STRING(filename)) = Ceval.ceval(outCache,inEnv,buildCurrentSimulationResultExp(), true, msg, 0);
        varNameStr = ValuesUtil.printCodeVariableName(cvar);
        val = SimulationResults.val(filename,varNameStr,timeStamp);
      then
        Values.REAL(val);

    case ("val",{cvar,Values.REAL(timeStamp),Values.STRING(filename)})
      equation
        false = stringEq(filename,"<default>");
        varNameStr = ValuesUtil.printCodeVariableName(cvar);
        val = SimulationResults.val(filename,varNameStr,timeStamp);
      then
        Values.REAL(val);

    case ("closeSimulationResultFile",_)
      equation
        SimulationResults.close();
      then
        Values.BOOL(true);

    case ("getParameterNames",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        strings = Interactive.getParameterNames(path, SymbolTable.getAbsyn());
        vals = List.map(strings, ValuesUtil.makeString);
      then
        ValuesUtil.makeArray(vals);

    case ("getParameterValue",{Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str1)})
      equation
        str2 = Interactive.getComponentBinding(path, str1, SymbolTable.getAbsyn());
      then
        Values.STRING(str2);

    case ("setParameterValue", {Values.CODE(Absyn.C_TYPENAME(classpath)),
        Values.CODE(Absyn.C_TYPENAME(path)), Values.CODE(Absyn.C_EXPRESSION(aexp))})
      algorithm
        (p, b) := InteractiveUtil.setElementModifier(classpath, path,
          Absyn.Modification.CLASSMOD({}, Absyn.EqMod.EQMOD(aexp, AbsynUtil.dummyInfo)), SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        ValuesUtil.makeBoolean(b);

    case ("getComponentModifierNames",{Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str1)})
      equation
        strings = Interactive.getComponentModifierNames(path, str1, SymbolTable.getAbsyn());
        vals = List.map(strings, ValuesUtil.makeString);
      then
        ValuesUtil.makeArray(vals);

    case ("getComponentModifierValue",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        cr = AbsynUtil.pathToCref(path);
        if AbsynUtil.crefIsIdent(cr) then
          Absyn.CREF_IDENT(name = s1) = cr;
          str = Interactive.getComponentBinding(classpath, s1, SymbolTable.getAbsyn());
        else
          s1 = AbsynUtil.crefFirstIdent(cr);
          cr = AbsynUtil.crefStripFirst(cr);
          str = Interactive.getComponentModifierValue(AbsynUtil.pathToCref(classpath), Absyn.CREF_IDENT(s1, {}), cr, SymbolTable.getAbsyn());
        end if;
      then
        Values.STRING(str);

    case ("getComponentModifierValues",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        cr = AbsynUtil.pathToCref(path);
        if AbsynUtil.crefIsIdent(cr) then
          Absyn.CREF_IDENT(name = s1) = cr;
          str = Interactive.getComponentBinding(classpath, s1, SymbolTable.getAbsyn());
        else
          s1 = AbsynUtil.crefFirstIdent(cr);
          cr = AbsynUtil.crefStripFirst(cr);
          str = Interactive.getComponentModifierValues(AbsynUtil.pathToCref(classpath), Absyn.CREF_IDENT(s1, {}), cr, SymbolTable.getAbsyn());
        end if;
      then
        Values.STRING(str);

    case ("setElementModifierValue",
          {Values.CODE(Absyn.C_TYPENAME(classpath)),
           Values.CODE(Absyn.C_TYPENAME(path)),
           Values.CODE(Absyn.C_MODIFICATION(modification = mod))})
      algorithm
        (p, b) := InteractiveUtil.setElementModifier(classpath, path, mod, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(b);

    case ("getExtendsModifierValue",
          {Values.CODE(Absyn.C_TYPENAME(classpath)),
           Values.CODE(Absyn.C_TYPENAME(baseClassPath)),
           Values.CODE(Absyn.C_TYPENAME(path))})
      then Interactive.getExtendsModifierValue(classpath, baseClassPath, path, SymbolTable.getAbsyn());

    case ("setExtendsModifierValue",
          {Values.CODE(Absyn.C_TYPENAME(classpath)),
           Values.CODE(Absyn.C_TYPENAME(baseClassPath)),
           Values.CODE(Absyn.C_TYPENAME(path)),
           Values.CODE(Absyn.C_MODIFICATION(modification = mod))})
      algorithm
        (p, b) := InteractiveUtil.setExtendsModifier(classpath, baseClassPath, path, mod, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(b);

    case ("setExtendsModifier",
          {Values.CODE(Absyn.C_TYPENAME(classpath)),
           Values.CODE(Absyn.C_TYPENAME(baseClassPath)),
           Values.CODE(Absyn.C_MODIFICATION(modification = mod))})
      algorithm
        (p, b) := InteractiveUtil.setExtendsModifier(classpath, baseClassPath, Absyn.Path.IDENT("_"), mod, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(b);

    case ("isExtendsModifierFinal",
          {Values.CODE(Absyn.C_TYPENAME(classpath)),
           Values.CODE(Absyn.C_TYPENAME(baseClassPath)),
           Values.CODE(Absyn.C_TYPENAME(path))})
      then Interactive.isExtendsModifierFinal(classpath, baseClassPath, path, SymbolTable.getAbsyn());

    case ("removeComponentModifiers",
        Values.CODE(Absyn.C_TYPENAME(path))::
      Values.STRING(str1)::
      Values.BOOL(keepRedeclares)::_)
      equation
        (p,b) = Interactive.removeComponentModifiers(path, str1, SymbolTable.getAbsyn(), keepRedeclares);
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(b);

    case ("getElementModifierNames",{Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str1)})
      equation
        strings = InteractiveUtil.getElementModifierNames(path, str1, SymbolTable.getAbsyn());
        vals = List.map(strings, ValuesUtil.makeString);
      then
        ValuesUtil.makeArray(vals);

    case ("getElementModifierValue",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        cr = AbsynUtil.pathToCref(path);
        if AbsynUtil.crefIsIdent(cr) then
          Absyn.CREF_IDENT(name = s1) = cr;
          str = InteractiveUtil.getElementBinding(classpath, s1, SymbolTable.getAbsyn());
        else
          s1 = AbsynUtil.crefFirstIdent(cr);
          cr = AbsynUtil.crefStripFirst(cr);
          str = InteractiveUtil.getElementModifierValue(AbsynUtil.pathToCref(classpath), Absyn.CREF_IDENT(s1, {}), cr, SymbolTable.getAbsyn());
        end if;
      then
        Values.STRING(str);

    case ("getElementModifierValues",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        cr = AbsynUtil.pathToCref(path);
        if AbsynUtil.crefIsIdent(cr) then
          Absyn.CREF_IDENT(name = s1) = cr;
          str = InteractiveUtil.getElementBinding(classpath, s1, SymbolTable.getAbsyn());
        else
          s1 = AbsynUtil.crefFirstIdent(cr);
          cr = AbsynUtil.crefStripFirst(cr);
          str = InteractiveUtil.getElementModifierValues(AbsynUtil.pathToCref(classpath), Absyn.CREF_IDENT(s1, {}), cr, SymbolTable.getAbsyn());
        end if;
      then
        Values.STRING(str);

    case ("removeElementModifiers",
        Values.CODE(Absyn.C_TYPENAME(path))::
      Values.STRING(str1)::
      Values.BOOL(keepRedeclares)::_)
      equation
        (p,b) = InteractiveUtil.removeElementModifiers(path, str1, SymbolTable.getAbsyn(), keepRedeclares);
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(b);

    case ("removeExtendsModifiers",
          Values.CODE(Absyn.C_TYPENAME(classpath))::
          Values.CODE(Absyn.C_TYPENAME(baseClassPath))::
          Values.BOOL(keepRedeclares)::_)
      equation
        (p,b) = Interactive.removeExtendsModifiers(classpath, baseClassPath, SymbolTable.getAbsyn(), keepRedeclares);
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(b);

    case ("getInstantiatedParametersAndValues",{Values.CODE(Absyn.C_TYPENAME(classpath))})
      equation
        (outCache,_,odae) = runFrontEnd(outCache,inEnv,classpath,true);
        strings = Interactive.getInstantiatedParametersAndValues(odae);
        vals = List.map(strings, ValuesUtil.makeString);
      then
        ValuesUtil.makeArray(vals);

    case ("getInstantiatedParametersAndValues",_)
      equation
        Error.addCompilerWarning("getInstantiatedParametersAndValues failed to instantiate the model.");
      then
        ValuesUtil.makeArray({});

    case ("updateConnection",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(str1), Values.STRING(str2),Values.CODE(Absyn.C_EXPRESSION(aexp))})
      equation
        p = InteractiveUtil.updateConnectionAnnotation(AbsynUtil.pathToCref(classpath), str1, str2, Absyn.NAMEDARG("annotate",aexp)::{}, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(true);

    case ("updateConnection",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(str1), Values.STRING(str2),
                              Values.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(elementArgLst=annlst,eqMod=Absyn.NOMOD())))})
      algorithm
        p := SymbolTable.getAbsyn();
        absynClass := InteractiveUtil.getPathedClassInProgram(classpath, p);
        absynClass := InteractiveUtil.updateConnectionAnnotationInClass(absynClass, str1, str2, Absyn.ANNOTATION(annlst));
        p := InteractiveUtil.updateProgram(Absyn.PROGRAM({absynClass}, if AbsynUtil.pathIsIdent(classpath) then Absyn.TOP() else Absyn.WITHIN(AbsynUtil.stripLast(classpath))), p);
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(true);

    case ("updateConnection",_) then Values.BOOL(false);

    case ("updateConnectionAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(str1), Values.STRING(str2),Values.STRING(annStr)})
      algorithm
        istmts := Parser.parsestringexp("__dummy(" + annStr + ");");
        GlobalScript.ISTMTS(interactiveStmtLst = {GlobalScript.IEXP(exp = aexp)}) := istmts;
        Absyn.CALL(functionArgs = Absyn.FUNCTIONARGS(argNames = nargs)) := aexp;
        Absyn.NAMEDARG(argValue = Absyn.CODE(Absyn.C_MODIFICATION(Absyn.CLASSMOD(elementArgLst=annlst,eqMod=Absyn.NOMOD())))) := listHead(nargs);
        p := SymbolTable.getAbsyn();
        absynClass := InteractiveUtil.getPathedClassInProgram(classpath, p);
        absynClass := InteractiveUtil.updateConnectionAnnotationInClass(absynClass, str1, str2, Absyn.ANNOTATION(annlst));
        p := InteractiveUtil.updateProgram(Absyn.PROGRAM({absynClass}, if AbsynUtil.pathIsIdent(classpath) then Absyn.TOP() else Absyn.WITHIN(AbsynUtil.stripLast(classpath))), p);
        SymbolTable.setAbsynClass(p, absynClass, classpath);
      then
        Values.BOOL(true);

    case ("updateConnectionAnnotation",_) then Values.BOOL(false);

    case ("updateConnectionNames",{Values.CODE(Absyn.C_TYPENAME(classpath)),Values.STRING(str1), Values.STRING(str2),
                                           Values.STRING(str3), Values.STRING(str4)})
      equation
        (b, p) = InteractiveUtil.updateConnectionNames(classpath, str1, str2, str3, str4, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(b);

    case ("updateConnectionNames",_) then Values.BOOL(false);

    case ("getConnectionCount",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        access = Interactive.checkAccessAnnotationAndEncryption(path, SymbolTable.getAbsyn());
        if access >= Access.diagram then
          n = listLength(Interactive.getConnections(absynClass));
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          n = 0;
        end if;
      then
        Values.INTEGER(n);

    case ("getConnectionCount",_) then Values.INTEGER(0);

    case ("getNthConnection",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)})
      equation
        access = Interactive.checkAccessAnnotationAndEncryption(path, SymbolTable.getAbsyn());
        if access >= Access.diagram then
          vals = Interactive.getNthConnection(AbsynUtil.pathToCref(path), SymbolTable.getAbsyn(), n);
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          vals = {};
        end if;
      then
        ValuesUtil.makeArray(vals);

    case ("getNthConnection",_) then ValuesUtil.makeArray({});

    case ("getConnectionList", {Values.CODE(Absyn.C_TYPENAME(path))})
      then getConnectionList(path);

    case ("getAlgorithmCount",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = listLength(getAlgorithms(absynClass));
      then
        Values.INTEGER(n);

    case ("getAlgorithmCount",_) then Values.INTEGER(0);

    case ("getNthAlgorithm",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthAlgorithm(absynClass, n);
      then
        Values.STRING(str);

    case ("getNthAlgorithm",_) then Values.STRING("");

    case ("getInitialAlgorithmCount",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = listLength(getInitialAlgorithms(absynClass));
      then
        Values.INTEGER(n);

    case ("getInitialAlgorithmCount",_) then Values.INTEGER(0);

    case ("getNthInitialAlgorithm",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthInitialAlgorithm(absynClass, n);
      then
        Values.STRING(str);

    case ("getNthInitialAlgorithm",_) then Values.STRING("");

    case ("getAlgorithmItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = getAlgorithmItemsCount(absynClass);
      then
        Values.INTEGER(n);

    case ("getAlgorithmItemsCount",_) then Values.INTEGER(0);

    case ("getNthAlgorithmItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthAlgorithmItem(absynClass, n);
      then
        Values.STRING(str);

    case ("getNthAlgorithmItem",_) then Values.STRING("");

    case ("getInitialAlgorithmItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = getInitialAlgorithmItemsCount(absynClass);
      then
        Values.INTEGER(n);

    case ("getInitialAlgorithmItemsCount",_) then Values.INTEGER(0);

    case ("getNthInitialAlgorithmItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthInitialAlgorithmItem(absynClass, n);
      then
        Values.STRING(str);

    case ("getNthInitialAlgorithmItem",_) then Values.STRING("");

    case ("getEquationCount",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = listLength(getEquations(absynClass));
      then
        Values.INTEGER(n);

    case ("getEquationCount",_) then Values.INTEGER(0);

    case ("getNthEquation",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthEquation(absynClass, n);
      then
        Values.STRING(str);

    case ("getNthEquation",_) then Values.STRING("");

    case ("getInitialEquationCount",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = listLength(getInitialEquations(absynClass));
      then
        Values.INTEGER(n);

    case ("getInitialEquationCount",_) then Values.INTEGER(0);

    case ("getNthInitialEquation",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthInitialEquation(absynClass, n);
      then
        Values.STRING(str);

    case ("getNthInitialEquation",_) then Values.STRING("");

    case ("getEquationItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = getEquationItemsCount(absynClass);
      then
        Values.INTEGER(n);

    case ("getEquationItemsCount",_) then Values.INTEGER(0);

    case ("getNthEquationItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthEquationItem(absynClass, n);
      then
        Values.STRING(str);

    case ("getNthEquationItem",_) then Values.STRING("");

    case ("getInitialEquationItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = getInitialEquationItemsCount(absynClass);
      then
        Values.INTEGER(n);

    case ("getInitialEquationItemsCount",_) then Values.INTEGER(0);

    case ("getNthInitialEquationItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthInitialEquationItem(absynClass, n);
      then
        Values.STRING(str);

    case ("getNthInitialEquationItem",_) then Values.STRING("");

    case ("getAnnotationCount",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = getAnnotationCount(absynClass);
      then
        Values.INTEGER(n);

    case ("getAnnotationCount",_) then Values.INTEGER(0);

    case ("getNthAnnotationString",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        str = getNthAnnotationString(absynClass, n);
      then
        Values.STRING(str);

    case ("getNthAnnotationString",_) then Values.STRING("");

    case ("getImportCount",{Values.CODE(Absyn.C_TYPENAME(path))})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        n = getImportCount(absynClass);
      then
        Values.INTEGER(n);

    case ("getImportCount",_) then Values.INTEGER(0);

    case ("getNthImport",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)})
      equation
        absynClass = InteractiveUtil.getPathedClassInProgram(path, SymbolTable.getAbsyn());
        vals = getNthImport(absynClass, n);
      then
        ValuesUtil.makeArray(vals);

    case ("getNthImport",_) then ValuesUtil.makeArray({});

    // plotParametric
    case ("plotParametric",
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
          Values.BOOL(forceOMPlot),
          Values.STRING(yAxis),
          Values.STRING(yLabelRight),
          Values.ARRAY(valueLst={Values.REAL(y1R),Values.REAL(y2R)})
        })
      equation
        // get OPENMODELICAHOME
        omhome = Settings.getInstallationDirectoryPath();
        // get the simulation filename
        (outCache,filename) = cevalCurrentSimulationResultExp(outCache,inEnv,filename,msg);
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
          str3 = "--filename=\"" + filename + "\" --title=\"" + title + "\" --grid=" + gridStr + " --plotParametric --logx=" + boolString(logX) + " --logy=" + boolString(logY) + " --yaxis=\"" + yAxis + "\" --xlabel=\"" + xLabel + "\" --ylabel=\"" + yLabel + "\" --ylabel-right=\"" + yLabelRight + "\" --xrange=" + realString(x1) + ":" + realString(x2) + " --yrange=" + realString(y1) + ":" + realString(y2) + " --yrange-right=" + realString(y1R) + ":" + realString(y2R) + " --new-window=" + boolString(externalWindow) + " --curve-width=" + realString(curveWidth) + " --curve-style=" + intString(curveStyle) + " --legend-position=\"" + legendPosition + "\" --footer=\"" + footer + "\" --auto-scale=" + boolString(autoScale) + " \"" + str + "\"";
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
        Values.BOOL(true);

    case ("plotParametric",_)
      then Values.BOOL(false);

    case ("dumpXMLDAE",vals)
      equation
        (outCache,xml_filename) = dumpXMLDAE(outCache,inEnv,vals, msg);
      then
        ValuesUtil.makeTuple({Values.BOOL(true),Values.STRING(xml_filename)});

    case ("dumpXMLDAE",_)
      then
        ValuesUtil.makeTuple({Values.BOOL(false),Values.STRING("")});

    case ("solveLinearSystem",{Values.ARRAY(valueLst=vals),v})
      equation
        (realVals,i) = System.dgesv(List.map(vals,ValuesUtil.arrayValueReals),ValuesUtil.arrayValueReals(v));
        v = ValuesUtil.makeArray(List.map(realVals,ValuesUtil.makeReal));
      then
        Values.TUPLE({v,Values.INTEGER(i)});

    case ("solveLinearSystem",{_,v,_,_})
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Unknown input to solveLinearSystem scripting function"});
      then
        Values.TUPLE({v,Values.INTEGER(-1)});

    case ("relocateFunctions",{Values.STRING(str), v as Values.ARRAY()})
      algorithm
        relocatableFunctionsTuple := {};
        for varr in v.valueLst loop
          Values.ARRAY(valueLst={Values.STRING(s1),Values.STRING(s2)}) := varr;
          relocatableFunctionsTuple := (s1,s2)::relocatableFunctionsTuple;
        end for;
        b := System.relocateFunctions(str, relocatableFunctionsTuple);
      then
        Values.BOOL(b);

    case ("toJulia",{})
      algorithm
        str := Tpl.tplString(AbsynToJulia.dumpProgram, SymbolTable.getAbsyn());
      then
        Values.STRING(str);

    case ("interactiveDumpAbsynToJL",{})
      algorithm
        str := Tpl.tplString(AbsynJLDumpTpl.dump, SymbolTable.getAbsyn());
      then
        Values.STRING(str);

    case ("relocateFunctions",_) then Values.BOOL(false);

    case ("runConversionScript", {Values.CODE(Absyn.C_TYPENAME(path)), Values.STRING(str)})
      then runConversionScript(path, str);

    case ("convertPackageToLibrary", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_TYPENAME(path)), Values.STRING(str)})
      then convertPackageToLibrary(classpath, path, str);

    case ("getModelInstance", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.STRING(str), Values.BOOL(b)})
      then NFApi.getModelInstance(classpath, str, b);

    case ("getModelInstanceAnnotation", {Values.CODE(Absyn.C_TYPENAME(classpath)), v as Values.ARRAY(), Values.BOOL(b)})
      then NFApi.getModelInstanceAnnotation(classpath, ValuesUtil.arrayValueStrings(v), b);

    case ("modifierToJSON", {Values.STRING(str), Values.BOOL(b)})
      then NFApi.modifierToJSON(str, b);

    case ("storeAST", {})
      then Values.INTEGER(SymbolTable.storeAST());

    case ("restoreAST", {Values.INTEGER(integer = n)})
      then Values.BOOL(SymbolTable.restoreAST(n));

    case ("qualifyPath", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_TYPENAME(path))})
      then ValuesUtil.makeCodeTypeName(NFApi.mkFullyQual(SymbolTable.getAbsyn(), classpath, path));

    case ("getElementAnnotation", {Values.CODE(Absyn.C_TYPENAME(path))})
      then Values.STRING(InteractiveUtil.getElementAnnotation(path, SymbolTable.getAbsyn()));

    case ("setElementAnnotation",
          {Values.CODE(Absyn.C_TYPENAME(path)),
           Values.CODE(Absyn.C_MODIFICATION(modification = mod))})
      algorithm
        (p, b) := InteractiveUtil.setElementAnnotation(path, mod, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("loadClassContentString",
          {Values.STRING(str), Values.CODE(Absyn.C_TYPENAME(classpath)), Values.INTEGER(x), Values.INTEGER(y)})
      algorithm
        (p, b) := InteractiveUtil.loadClassContentString(str, classpath, x, y, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        Values.BOOL(b);

    case ("setElementType",
          {Values.CODE(Absyn.C_TYPENAME(path)),
           Values.CODE(Absyn.C_VARIABLENAME(cr))})
      algorithm
        (p, b) := InteractiveUtil.setElementType(path, cr, SymbolTable.getAbsyn());
      then
        Values.BOOL(b);

    case ("getExtendsModifierNames",
          {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_TYPENAME(path)), Values.BOOL(b)})
      then InteractiveUtil.getExtendsModifierNames(classpath, path, b, SymbolTable.getAbsyn());

    case ("isPrimitive", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then ValuesUtil.makeBoolean(Interactive.isPrimitive(classpath, SymbolTable.getAbsyn()));

    case ("isParameter", {Values.CODE(Absyn.C_TYPENAME(path)), Values.CODE(Absyn.C_TYPENAME(classpath))})
      then ValuesUtil.makeBoolean(Interactive.isParameter(path, classpath, SymbolTable.getAbsyn()));

    case ("isConstant", {Values.CODE(Absyn.C_TYPENAME(path)), Values.CODE(Absyn.C_TYPENAME(classpath))})
      then ValuesUtil.makeBoolean(Interactive.isConstant(path, classpath, SymbolTable.getAbsyn()));

    case ("isProtected", {Values.CODE(Absyn.C_TYPENAME(path)), Values.CODE(Absyn.C_TYPENAME(classpath))})
      then ValuesUtil.makeBoolean(Interactive.isProtected(path, classpath, SymbolTable.getAbsyn()));

    case ("setComponentDimensions", {Values.CODE(Absyn.C_TYPENAME(classpath)),
        Values.CODE(Absyn.C_TYPENAME(path)), Values.CODE(Absyn.C_EXPRESSION(aexp as Absyn.Exp.ARRAY()))})
      algorithm
        (p, b) := Interactive.setComponentDimensions(classpath, path, aexp.arrayExp, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        ValuesUtil.makeBoolean(b);

    case ("setComponentProperties", {Values.CODE(Absyn.C_TYPENAME(classpath)),
        Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT(name))),
        Values.ARRAY(valueLst = vals),
        Values.ARRAY(valueLst = {Values.STRING(s1)}),
        Values.ARRAY(valueLst = {Values.BOOL(b1), Values.BOOL(b2)}),
        Values.ARRAY(valueLst = {Values.STRING(s2)})})
      algorithm
        (p, v) := Interactive.setComponentProperties(classpath, name,
          list(ValuesUtil.valueBool(va) for va in vals), s1, b1, b2, s2, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        v;

    case ("createModel", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      algorithm
        p := Interactive.createModel(classpath, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        ValuesUtil.makeBoolean(true);

    case ("newModel", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_TYPENAME(path))})
      algorithm
        p := Interactive.newModel(classpath, path, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        ValuesUtil.makeBoolean(true);

    case ("deleteClass", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      algorithm
        (b, p) := Interactive.deleteClass(classpath, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        ValuesUtil.makeBoolean(b);

    case ("addComponent", {Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT(name))),
        Values.CODE(Absyn.C_TYPENAME(path)), Values.CODE(Absyn.C_TYPENAME(classpath)),
        Values.CODE(Absyn.C_EXPRESSION(aexp)), Values.CODE(Absyn.C_MODIFICATION(modification = mod)),
        Values.CODE(Absyn.C_EXPRESSION(aexp2)), Values.CODE(Absyn.C_EXPRESSION(aexp3))})
      algorithm
        (p, b) := Interactive.addComponent(name, path, classpath, aexp, mod, aexp2, aexp3, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        ValuesUtil.makeBoolean(b);

    case ("updateComponent", {Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT(name))),
        Values.CODE(Absyn.C_TYPENAME(path)), Values.CODE(Absyn.C_TYPENAME(classpath)),
        Values.CODE(Absyn.C_EXPRESSION(aexp)), Values.CODE(Absyn.C_MODIFICATION(modification = mod)),
        Values.CODE(Absyn.C_EXPRESSION(aexp2)), Values.CODE(Absyn.C_EXPRESSION(aexp3))})
      algorithm
        (p, b) := Interactive.updateComponent(name, path, classpath, aexp, mod, aexp2, aexp3, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        ValuesUtil.makeBoolean(b);

    case ("deleteComponent", {Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT(name))), Values.CODE(Absyn.C_TYPENAME(classpath))})
      algorithm
        (p, b) := Interactive.deleteComponent(name, classpath, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        ValuesUtil.makeBoolean(b);

    case ("getComponentCount", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then ValuesUtil.makeInteger(Interactive.getComponentCount(classpath, SymbolTable.getAbsyn()));

    case ("getNthComponent", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.INTEGER(n)})
      then Interactive.getNthComponent(classpath, SymbolTable.getAbsyn(), n);

    case ("getComponents", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.BOOL(b)})
      then Interactive.getComponents(classpath, b, SymbolTable.getAbsyn());

    case ("getElements", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.BOOL(b)})
      then Interactive.getElements(classpath, b, SymbolTable.getAbsyn());

    case ("getElementsInfo", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.getElementsInfo(classpath, SymbolTable.getAbsyn());

    case ("getComponentAnnotations", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.getComponentAnnotations(classpath, SymbolTable.getAbsyn());

    case ("getElementAnnotations", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.getElementAnnotations(classpath, SymbolTable.getAbsyn());

    case ("getNthComponentAnnotation", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.INTEGER(n)})
      then Interactive.getNthComponentAnnotation(classpath, n, SymbolTable.getAbsyn());

    case ("getNthComponentModification", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.INTEGER(n)})
      then Interactive.getNthComponentModification(classpath, n, SymbolTable.getAbsyn());

    case ("getNthComponentCondition", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.INTEGER(n)})
      then Interactive.getNthComponentCondition(classpath, n, SymbolTable.getAbsyn());

    case ("getInheritanceCount", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.getInheritanceCount(classpath, SymbolTable.getAbsyn());

    case ("getNthInheritedClass", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.INTEGER(n)})
      then Interactive.getNthInheritedClass(classpath, n);

    case ("setConnectionComment", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_VARIABLENAME(cr)),
                                   Values.CODE(Absyn.C_VARIABLENAME(cr2)), Values.STRING(str)})
      algorithm
        (p, b) := Interactive.setConnectionComment(classpath, cr, cr2, str, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        ValuesUtil.makeBoolean(b);

    case ("addConnection", {Values.CODE(Absyn.C_VARIABLENAME(cr)), Values.CODE(Absyn.C_VARIABLENAME(cr2)),
                            Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_EXPRESSION(aexp)),
                            Values.CODE(Absyn.C_EXPRESSION(aexp2))})
      algorithm
        (p, b) := Interactive.addConnection(classpath, cr, cr2, aexp, aexp2, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        ValuesUtil.makeBoolean(b);

    case ("deleteConnection", {Values.CODE(Absyn.C_VARIABLENAME(cr)), Values.CODE(Absyn.C_VARIABLENAME(cr2)),
                               Values.CODE(Absyn.C_TYPENAME(classpath))})
      algorithm
        (p, b) := Interactive.deleteConnection(classpath, cr, cr2, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        ValuesUtil.makeBoolean(b);

    case ("getNthConnectionAnnotation", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.INTEGER(n)})
      then Interactive.getNthConnectionAnnotation(classpath, n, SymbolTable.getAbsyn());

    case ("getConnectorCount", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.getConnectorCount(classpath, SymbolTable.getAbsyn());

    case ("getNthConnector", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.INTEGER(n)})
      then Interactive.getNthConnector(classpath, n, SymbolTable.getAbsyn());

    case ("getNthConnectorIconAnnotation", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.INTEGER(n)})
      then Interactive.getNthConnectorIconAnnotation(classpath, n, SymbolTable.getAbsyn());

    case ("getIconAnnotation", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.getIconAnnotation(classpath, SymbolTable.getAbsyn());

    case ("getDiagramAnnotation", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.getDiagramAnnotation(classpath, SymbolTable.getAbsyn());

    case ("refactorIconAnnotation", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.refactorIconAnnotation(classpath, SymbolTable.getAbsyn());

    case ("refactorDiagramAnnotation", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.refactorDiagramAnnotation(classpath, SymbolTable.getAbsyn());

    case ("refactorClass", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.refactorClass(classpath, SymbolTable.getAbsyn());

    case ("getNthInheritedClassIconMapAnnotation", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.INTEGER(n)})
      then Interactive.getNthInheritedClassIconMapAnnotation(classpath, n, SymbolTable.getAbsyn());

    case ("getNthInheritedClassDiagramMapAnnotation", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.INTEGER(n)})
      then Interactive.getNthInheritedClassDiagramMapAnnotation(classpath, n, SymbolTable.getAbsyn());

    case ("getNamedAnnotation",
        {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_TYPENAME(path))})
      then Interactive.getNamedAnnotation(classpath, path, SymbolTable.getAbsyn());

    case ("getShortDefinitionBaseClassInformation", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.getShortDefinitionBaseClassInformation(classpath, SymbolTable.getAbsyn());

    case ("getExternalFunctionSpecification", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.getExternalFunctionSpecification(classpath, SymbolTable.getAbsyn());

    case ("getEnumerationLiterals", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.getEnumerationLiterals(classpath, SymbolTable.getAbsyn());

    case ("existClass", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then ValuesUtil.makeBoolean(Interactive.existClass(classpath, SymbolTable.getAbsyn()));

    case ("getComponentComment", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_TYPENAME(path))})
      then Interactive.getComponentComment(classpath, path, SymbolTable.getAbsyn());

    case ("setComponentComment", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_TYPENAME(path)), Values.STRING(str)})
      algorithm
        (p, b) := Interactive.setComponentComment(classpath, path, str, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        ValuesUtil.makeBoolean(b);

    case ("renameClass", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_TYPENAME(path))})
      algorithm
        (p, v) := Interactive.renameClass(classpath, path, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        v;

    case ("renameComponent", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_VARIABLENAME(cr)),
                              Values.CODE(Absyn.C_VARIABLENAME(cr2))})
      algorithm
        (p, v) := Interactive.renameComponent(classpath, cr, cr2, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        v;

    case ("renameComponentInClass", {Values.CODE(Absyn.C_TYPENAME(classpath)), Values.CODE(Absyn.C_VARIABLENAME(cr)),
                              Values.CODE(Absyn.C_VARIABLENAME(cr2))})
      algorithm
        (p, v) := Interactive.renameComponentOnlyInClass(classpath, cr, cr2, SymbolTable.getAbsyn());
        SymbolTable.setAbsyn(p);
      then
        v;

    case ("getCrefInfo", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.getCrefInfo(classpath, SymbolTable.getAbsyn());

    case ("getDefaultComponentName", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.getDefaultComponentName(classpath, SymbolTable.getAbsyn());

    case ("getDefaultComponentPrefixes", {Values.CODE(Absyn.C_TYPENAME(classpath))})
      then Interactive.getDefaultComponentPrefixes(classpath, SymbolTable.getAbsyn());

    case ("getDefinitions", {Values.BOOL(b)})
      then Interactive.getDefinitions(SymbolTable.getAbsyn(), b);

    case ("getDefaultOpenCLDevice", {})
      then ValuesUtil.makeInteger(Config.getDefaultOpenCLDevice());

 end matchcontinue;
end cevalInteractiveFunctions4;

protected function getSimulationExtension
  input String inString;
  input String inString2;
  output String outString;
algorithm
  outString:=match(inString,inString2)
  local
    // We now use a bat script, even for the C runtime, on Windows.
    case ("C","WIN64")
     then ".bat";
    case ("C","WIN32")
      then ".bat";
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
      DAE.DAElist dae;
      FCore.Graph env;
      BackendDAE.BackendDAE dlow;
      Absyn.ComponentRef a_cref;
      Absyn.Msg msg;
      FCore.Cache cache;
      String flatModelicaStr,description;

    case (cache,env,_,_,_) /* mo file directory */
      equation
        (cache, env, SOME(dae), _) = runFrontEnd(cache, env, className, true, transform = true);
        description = DAEUtil.daeDescription(dae);
        a_cref = AbsynUtil.pathToCref(className);
        file_dir = getFileDir(a_cref, SymbolTable.getAbsyn());
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

/* -------------------------------------------------------------------
                         RUN FRONTEND
   ------------------------------------------------------------------- */
public function runFrontEnd
  input output FCore.Cache cache;
  input output FCore.Graph env;
  input Absyn.Path className;
  input Boolean relaxedFrontEnd "Do not check for illegal simulation models, so we allow instantation of packages, etc";
  input Boolean dumpFlat = false;
  input Boolean transform = false;
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
      print(GCExt.profStatsStr(GCExt.getProfStats(), head="GC stats before front-end:") + "\n");
    end if;
    ExecStat.execStat("FrontEnd - loaded program");
    (cache,env,dae,flatString) := runFrontEndWork(cache,env,className,relaxedFrontEnd,dumpFlat);
    if Flags.isSet(Flags.GC_PROF) then
      print(GCExt.profStatsStr(GCExt.getProfStats(), head="GC stats after front-end:") + "\n");
    end if;
    ExecStat.execStat("FrontEnd - DAE generated");

    if transform then
      dae := DAEUtil.transformationsBeforeBackend(cache, env, dae);
    end if;

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
    InteractiveUtil.getPathedClassInProgram(className, p, true);
  else
    str := AbsynUtil.pathFirstIdent(className);
    (p,b) := CevalScript.loadModel({(Absyn.IDENT(str),"the given model name to instantiate",{"default"},false)},Settings.getModelicaPath(Testsuite.isRunning()),p,true,true,true,false);
    Error.assertionOrAddSourceMessage(not b,Error.NOTIFY_IMPLICIT_LOAD,{str,"default"},AbsynUtil.dummyInfo);
    System.loadModelCallBack(str);
    // print(stringDelimitList(list(AbsynUtil.pathString(path) for path in Interactive.getTopClassnames(p)), ",") + "\n");
    SymbolTable.setAbsyn(p);
  end try;

  (p,success) := CevalScript.loadModel(Interactive.getUsesAnnotationOrDefault(p, false),Settings.getModelicaPath(Testsuite.isRunning()),p,false,true,true,false);
  SymbolTable.setAbsyn(p);
  // Always update the SCode structure; otherwise the cache plays tricks on us
  SymbolTable.clearSCode();
end runFrontEndLoadProgram;

protected function runFrontEndWork
  input output FCore.Cache cache;
  input output FCore.Graph env;
  input Absyn.Path className;
  input Boolean relaxedFrontEnd "Do not check for illegal simulation models, so we allow instantation of packages, etc";
  input Boolean dumpFlat;
        output DAE.DAElist dae;
        output String flatString = "";
protected
  Integer numError = Error.getNumErrorMessages();
  Boolean graph_inst, nf_inst, nf_inst_actual;
  SCode.Program scodeP;
  DAE.FunctionTree funcs;
  NFFlatModel flat_model;
  NFFlatten.FunctionTree nf_funcs;
algorithm
  graph_inst := Flags.isSet(Flags.GRAPH_INST);
  nf_inst := Flags.isSet(Flags.SCODE_INST);
  nf_inst_actual := nf_inst;

  // PDEModelica is not yet supported by the new frontend, switch to the old one
  // if `-g=PDEModelica` is set.
  if nf_inst and Flags.getConfigEnum(Flags.GRAMMAR) == Flags.PDEMODELICA then
    nf_inst := false;
    FlagsUtil.set(Flags.SCODE_INST, false);
    Error.addMessage(Error.NF_PDE_NOT_IMPLEMENTED, {});
  end if;

  (cache,env,dae) := matchcontinue (graph_inst, nf_inst)
    case (false, true)
      algorithm
        (flat_model, nf_funcs, flatString) := runFrontEndWorkNF(className, relaxedFrontEnd, dumpFlat);
        (dae, funcs) := NFConvertDAE.convert(flat_model, nf_funcs);

        cache := FCore.emptyCache();
        FCore.setCachedFunctionTree(cache, funcs);
        env := FGraph.new("graph", FCore.dummyTopModel);
      then
        (cache, env, dae);

   case (true, false)
      algorithm
        System.realtimeTick(ClockIndexes.RT_CLOCK_FINST);
        dae := FInst.instPath(className, SymbolTable.getSCode());
      then
        (cache,env,dae);

    case (false, false)
      algorithm
        scodeP := SymbolTable.getSCode();
        ExecStat.execStat("FrontEnd - Absyn->SCode");

        (cache,env,_,dae) := Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,scodeP,className,true,relaxedFrontEnd);
        dae := DAEUtil.mergeAlgorithmSections(dae);

        // adrpo: do not add it to the instantiated classes, it just consumes memory for nothing.
        DAEUtil.getFunctionList(FCore.getFunctionTree(cache),failOnError=true); // Make sure that the functions are valid before returning success
      then (cache,env,dae);

    case (_, _)
      guard Error.getNumErrorMessages() == numError
      algorithm
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Instantiation of " + AbsynUtil.pathString(className) + " failed with no error message."});
        FlagsUtil.set(Flags.SCODE_INST, nf_inst_actual);
      then
        fail();
  end matchcontinue;

  // Switch back to the new frontend in case we changed it at the beginning of the function.
  FlagsUtil.set(Flags.SCODE_INST, nf_inst_actual);
end runFrontEndWork;

public function runFrontEndWorkNF
  input Absyn.Path className;
  input Boolean relaxedFrontend = false;
  input Boolean dumpFlat = false;
  output NFFlatModel flatModel;
  output NFFlatten.FunctionTree functions;
  output String flatString;
protected
  SCode.Program builtin_p, scode_p, annotation_p;
  Boolean nf_api, inst_failed;
  Absyn.Path cls_name = className;
  Obfuscate.Mapping obfuscate_map;
  String obfuscate_mode;
algorithm
  (_, builtin_p) := FBuiltin.getInitialFunctions();
  scode_p := SymbolTable.getSCode();

  obfuscate_mode := Flags.getConfigString(Flags.OBFUSCATE);

  // Enable obfuscation of encrypted variables if a higher obfuscation hasn't
  // been chosen and the AST contains encrypted classes.
  if obfuscate_mode == "none" and Interactive.astContainsEncryptedClass(SymbolTable.getAbsyn()) then
    FlagsUtil.setConfigString(Flags.OBFUSCATE, "encrypted");
  end if;

  if obfuscate_mode == "full" then
    (scode_p, cls_name, _, _, obfuscate_map) := Obfuscate.obfuscateProgram(scode_p, cls_name);
  end if;

  scode_p := listAppend(builtin_p, scode_p);
  ExecStat.execStat("FrontEnd - Absyn->SCode");

  annotation_p := AbsynToSCode.translateAbsyn2SCode(
    InteractiveUtil.modelicaAnnotationProgram(Config.getAnnotationVersion()));

  // make sure we don't run the default instantiateModel using -d=nfAPI
  // only the stuff going via NFApi.mo should have this flag activated
  nf_api := FlagsUtil.set(Flags.NF_API, false);
  inst_failed := false;

  try
    (flatModel, functions, flatString) :=
      NFInst.instClassInProgram(cls_name, scode_p, annotation_p, relaxedFrontend, dumpFlat);
  else
    inst_failed := true;
    NFInst.clearCaches();
  end try;

  FlagsUtil.set(Flags.NF_API, nf_api);

  if inst_failed then
    fail();
  end if;
end runFrontEndWorkNF;

public function translateModel
  input FCore.Cache cache;
  input FCore.Graph env;
  input Absyn.Path className "path for the model";
  input String fileNamePrefix;
  input Boolean runBackend "if true, run the backend as well. This will run SimCode and Codegen as well.";
  input Boolean runSilent "if true, flat modelica code will not be dumped to out stream";
  input Option<SimCode.SimulationSettings> simSettingsOpt;
  output Boolean success;
  output FCore.Cache outCache;
  output list<String> outLibs;
  output String outFileDir;
  output list<tuple<String,Values.Value>> resultValues;
protected
  Flags.Flag flags;
  GlobalScript.SimulationOptions defaultSimOpt;
  Option<SimCode.SimulationSettings> simSettings;
algorithm
  if isSome(simSettingsOpt)  then
    simSettings := simSettingsOpt;
  else
    defaultSimOpt := buildSimulationOptionsFromModelExperimentAnnotation(className, fileNamePrefix, SOME(defaultSimulationOptions));
    simSettings := SOME(convertSimulationOptionsToSimCode(defaultSimOpt));
  end if;

  flags := loadCommandLineOptionsFromModel(className);

  try
    (success, outCache, outLibs, outFileDir, resultValues) :=
      SimCodeMain.translateModel(SimCodeMain.TranslateModelKind.NORMAL(), cache, env, className, fileNamePrefix,
        runBackend, Flags.getConfigBool(Flags.DAE_MODE), runSilent, simSettings, Absyn.FUNCTIONARGS({},{}));
    // reset to the original flags
    FlagsUtil.saveFlags(flags);
  else
    FlagsUtil.saveFlags(flags);
    fail();
  end try;
end translateModel;

protected function getProcsStr
  input Boolean isMake = false;
  output String s;
protected
  Integer n;
  String sn;
algorithm
  n := Flags.getConfigInt(Flags.NUM_PROC);
  sn := intString(n);
  s := if (n == 0)
       then ""
       else (if isMake
             then sn
             else stringAppend("-j", sn));
end getProcsStr;

protected function configureFMU_cmake
"Configure and build binaries with CMake for target platform"
  input String platform;
  input String fmutmp;
  input String fmuTargetName;
  input String logfile;
  input list<String> externalLibLocations;
  input Boolean isWindows;
protected
  String fmuSourceDir;
  String CMAKE_GENERATOR = "", CMAKE_BUILD_TYPE;
  String quote, dquote, defaultFmiIncludeDirectoy;
  String CC;
  SimCodeFunction.MakefileParams makefileParams;
algorithm
  makefileParams := SimCodeFunctionUtil.createMakefileParams({}, {}, {}, false, true);
  fmuSourceDir := fmutmp+"/sources/";
  quote := "'";
  dquote := if isWindows then "\"" else "'";
  CC := "-DCMAKE_C_COMPILER=" + dquote + System.basename(makefileParams.ccompiler) + dquote;
  defaultFmiIncludeDirectoy := dquote + Settings.getInstallationDirectoryPath() + "/include/omc/c/fmi" + dquote;

  // Set build type
  if Flags.getConfigEnum(Flags.FMI_FILTER) == Flags.FMI_BLACKBOX or Flags.getConfigEnum(Flags.FMI_FILTER) == Flags.FMI_PROTECTED then
    CMAKE_BUILD_TYPE := "-DCMAKE_BUILD_TYPE=Release";
  elseif Flags.isSet(Flags.GEN_DEBUG_SYMBOLS) then
    CMAKE_BUILD_TYPE := "-DCMAKE_BUILD_TYPE=Debug";
  else
    CMAKE_BUILD_TYPE := "-DCMAKE_BUILD_TYPE=RelWithDebInfo";
  end if;

  // Remove old log file
  if System.regularFileExists(logfile) then
    System.removeFile(logfile);
  end if;

  _ := match Util.stringSplitAtChar(platform, " ")
    local
      String cmd;
      String cmakeCall;
      String crossTriple, buildDir, fmiTarget;
      list<String> dockerImgArgs;
      ContainerImage.ContainerImage dockerImage;
      list<String> dockerArguments;
      Boolean isOpenModelicaImage, hasKnownDigest;
      Integer uid;
      String cidFile, volumeID, containerID, userID;
      String dockerLogFile;
      String cmake_toolchain;
      list<String> locations, libraries;
    case {"dynamic"}
      algorithm
        if isWindows then
          CMAKE_GENERATOR := "-G " + dquote + "MSYS Makefiles" + dquote + " ";
        end if;
        buildDir := "build_cmake_dynamic";
        cmakeCall := Autoconf.cmake + " " + CMAKE_GENERATOR +
                     CMAKE_BUILD_TYPE + " " + CC +
                     " ..";
        cmd := "cd " + dquote + fmuSourceDir + dquote + " && " +
               "mkdir " + buildDir + " && cd " + buildDir + " && " +
               cmakeCall + " && " +
               Autoconf.cmake + " --build . --parallel " + getProcsStr() + " --target install && " +
               "cd .. && rm -rf " + buildDir;
        if 0 <> System.systemCallRestrictedEnv(cmd, outFile=logfile) then
          Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {"cmd: " + cmd + "\n" + System.readFile(logfile)});
          fail();
        end if;
        then();
    case {"static"}
      algorithm
        if isWindows then
          CMAKE_GENERATOR := "-G " + dquote + "MSYS Makefiles" + dquote + " ";
        end if;
        buildDir := "build_cmake_static";
        cmakeCall := Autoconf.cmake + " " + CMAKE_GENERATOR +
                     CMAKE_BUILD_TYPE + " " + CC +
                     " ..";
        cmd := "cd " + dquote + fmuSourceDir + dquote + " && " +
               "mkdir " + buildDir + " && cd " + buildDir + " && " +
               cmakeCall + " && " +
               Autoconf.cmake + " --build . --parallel " + getProcsStr() + " --target install && " +
               "cd .. && rm -rf " + buildDir;
        if 0 <> System.systemCallRestrictedEnv(cmd, outFile=logfile) then
          Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {"cmd: " + cmd + "\n" + System.readFile(logfile)});
          fail();
        end if;
        then();
    case crossTriple::"docker"::"run"::dockerImgArgs
      algorithm
        (dockerImage, dockerArguments) := ContainerImage.parseWithArgs(dockerImgArgs);
        dockerImage := ContainerImage.getDigestSha(dockerImage);
        Error.addCompilerNotification("Using docker image '" + ContainerImage.toString(dockerImage) + "' for cross compilation.");
        (isOpenModelicaImage, hasKnownDigest) := ContainerImage.isTrustedOpenModelicaImage(dockerImage);

        uid := System.getuid();
        cidFile := fmutmp+".cidfile";

        // Temp log file outside of Docker volume
        dockerLogFile := crossTriple + ".tmp.log";
        // Remove old log file
        if System.regularFileExists(dockerLogFile) then
          System.removeFile(dockerLogFile);
        end if;

        // Only automatically pull trusted images
        if hasKnownDigest then
          ContainerImage.pull(dockerImage);
          ContainerImage.assertSignature(dockerImage);
        end if;

        // Create a docker volume for the FMU since we can't forward volumes
        // to the docker run command depending on where the FMU was generated (inside another volume)
        cmd := "docker volume create";
        runDockerCmd(cmd, dockerLogFile);
        volumeID := List.last(System.strtok(System.readFile(dockerLogFile), "\n"));

        if System.regularFileExists(cidFile) then
          System.removeFile(cidFile);
        end if;
        cmd := "docker run --cidfile " + cidFile + " -v " + volumeID + ":/data busybox true";
        runDockerCmd(cmd, dockerLogFile, true, volumeID, "");

        containerID := System.trim(System.readFile(cidFile));
        System.removeFile(cidFile);

        // Copy the FMU contents to the container
        cmd := "docker cp " + fmutmp + " " + containerID + ":/data";
        runDockerCmd(cmd, dockerLogFile, cleanup=true, volumeID=volumeID, containerID=containerID);

        // Copy the FMI headers to the container
        cmd := "docker cp " + defaultFmiIncludeDirectoy + " " + containerID + ":/data/fmiInclude";
        runDockerCmd(cmd, dockerLogFile, cleanup=true, volumeID=volumeID, containerID=containerID);

        // Copy the external library files to the container
        (locations, libraries) := SimCodeUtil.getDirectoriesForDLLsFromLinkLibs(externalLibLocations);
        for loc in locations loop
          if System.directoryExists(loc) then
            // Create path
            cmd := "docker run --rm --hostname=" + containerID + " --volume=" + volumeID + ":/data busybox mkdir -p " + dquote + "/data" + loc + dquote;
            runDockerCmd(cmd, dockerLogFile, cleanup=true, volumeID=volumeID, containerID=containerID);
            // Copy files
            cmd := "docker cp -a -L " + dquote + loc + dquote + " " + containerID + dquote + ":/data" + System.dirname(loc)  + dquote;
            runDockerCmd(cmd, dockerLogFile, cleanup=true, volumeID=volumeID, containerID=containerID);
          end if;
        end for;

        // Build for target host
        userID := (if uid<>0 then "--user " + String(uid) else "");
        buildDir := "build_cmake_" + crossTriple;
        if 0 <> System.regex(crossTriple, "mingw", 1) then
          fmiTarget := " -DCMAKE_SYSTEM_NAME=Windows ";
        elseif 0 <> System.regex(crossTriple, "apple", 1) then
          fmiTarget := " -DCMAKE_SYSTEM_NAME=Darwin ";
        else
          fmiTarget := "";
        end if;

        if isOpenModelicaImage then
          cmake_toolchain := "-DCMAKE_TOOLCHAIN_FILE=/opt/cmake/toolchain/" + crossTriple + ".cmake -DRUNTIME_DEPENDENCIES_LEVEL=none ";
        else
          cmake_toolchain := "";
        end if;

        cmakeCall := "cmake " + cmake_toolchain +
                            "-DFMI_INTERFACE_HEADER_FILES_DIRECTORY=/fmu/fmiInclude " +
                            "-DDOCKER_VOL_DIR=/fmu " +
                            fmiTarget +
                            CMAKE_BUILD_TYPE +
                            " ..";
        cmd := "docker run " + userID + " --rm -w /fmu -v " + volumeID + ":/fmu " + stringDelimitList(dockerImgArgs," ") +
               " sh -c " + dquote +
                  "cd " + dquote + "/fmu/" + fmuSourceDir + dquote + " && " +
                  "mkdir " + buildDir + " && cd " + buildDir + " && " +
                  cmakeCall + " && " +
                  "cmake --build . &&  make " + getProcsStr(true) + " install && " +
                  "cd .. && rm -rf " + buildDir +
                dquote;
        runDockerCmd(cmd, dockerLogFile, cleanup=true, volumeID=volumeID, containerID=containerID);

        // Copy the files back from the volume (via the container) to the filesystem.
        // Docker cp can't handle too long names on Windows.
        // Workaround: Zip it in the container, copy it to host, unzip it
        if isWindows then
          cmd := "docker run " + userID + " --rm -w /fmu -v " + volumeID + ":/fmu " + stringDelimitList(dockerImgArgs," ") +
                 " tar -zcf comp-fmutmp.tar.gz " + fmutmp;
          runDockerCmd(cmd, dockerLogFile, cleanup=true, volumeID=volumeID, containerID=containerID);

          cmd := "docker cp " + containerID + ":/data/comp-fmutmp.tar.gz .";
          runDockerCmd(cmd, dockerLogFile, cleanup=true, volumeID=volumeID, containerID=containerID);
          System.systemCall("tar zxf comp-fmutmp.tar.gz && rm comp-fmutmp.tar.gz");
        else
          cmd := "docker cp " + containerID + ":/data/" + fmutmp + "/ .";
          runDockerCmd(cmd, dockerLogFile, cleanup=false, volumeID=volumeID, containerID=containerID);
        end if;

        // Cleanup
        System.systemCall("docker rm " + containerID);
        System.systemCall("docker volume rm " + volumeID);

        // Copy log file into resources directory
        System.copyFile(dockerLogFile, logfile);
        System.removeFile(dockerLogFile);
        then();
    else
      algorithm
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR,
                         {"Unknown/unsupported platform \"" + platform + " \" for CMake FMU build. " +
                          "Use platforms={\"dynamic\"} for the default case."});
      then fail();
  end match;
end configureFMU_cmake;

protected function runDockerCmd
  "Run a docker command. Can clean up volumen and container on failure."
  input String cmd;
  input String logfile;
  input Boolean cleanup = false;
  input String volumeID = "";
  input String containerID = "";
protected
  Boolean verbose = false;
algorithm
  System.appendFile(logfile, cmd + "\n");
  if 0 <> System.systemCall(cmd, outFile=logfile) then
    Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {cmd + " failed:\n" + System.readFile(logfile)});

    if cleanup then
      if not stringEqual(containerID, "") then
        System.systemCall("docker rm " + containerID);
      end if;
      if not stringEqual(volumeID, "") then
        System.systemCall("docker volume rm " + volumeID);
      end if;
    end if;

    fail();
  elseif verbose then
      print(System.readFile(logfile) +"\n");
  end if;
end runDockerCmd;

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

  if Flags.isSet(Flags.GEN_DEBUG_SYMBOLS) then
    CFLAGS := "-O0 -g " + System.stringReplace(System.getCFlags(),"${MODELICAUSERCFLAGS}","");
  else
    CFLAGS := "-Os "+System.stringReplace(System.getCFlags(),"${MODELICAUSERCFLAGS}","");
  end if;

  LDFLAGS := ("-L"+dquote+Settings.getInstallationDirectoryPath()+"/lib/"+Autoconf.triple+"/omc"+dquote+" "+
              "-Wl,-rpath,"+dquote+Settings.getInstallationDirectoryPath()+"/lib/"+Autoconf.triple+"/omc"+dquote+" "+
              System.getLDFlags()+" ");
  CPPFLAGS := "-I. -I" + includeDefaultFmi + " -DOMC_FMI_RUNTIME=1";
  if Flags.isSet(Flags.GEN_DEBUG_SYMBOLS) then
    CPPFLAGS := CPPFLAGS + " -O0 -g ";
  end if;
  if needs3rdPartyLibs then
    SUNDIALS :=  "1";
    CPPFLAGS := CPPFLAGS + " -DWITH_SUNDIALS=1 -DLINK_SUNDIALS_STATIC" + " -Isundials";
  else
    SUNDIALS :=  "";
  end if;
  if System.regularFileExists(logfile) then
    System.removeFile(logfile);
  end if;
  nozip := Autoconf.make + " -j" + intString(Config.noProc()) + " nozip";
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
        makefileStr := System.stringReplace(makefileStr, "@NEED_CMINPACK@", "");
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
        makefileStr := System.stringReplace(makefileStr, "@LDFLAGS@", LDFLAGS + Autoconf.ldflags_runtime_fmu_static);
        makefileStr := System.stringReplace(makefileStr, "@LIBS@", "");
        makefileStr := System.stringReplace(makefileStr, "@DLLEXT@", Autoconf.dllExt);
        makefileStr := System.stringReplace(makefileStr, "@NEED_RUNTIME@", "");
        makefileStr := System.stringReplace(makefileStr, "@NEED_DGESV@", "");
        makefileStr := System.stringReplace(makefileStr, "@NEED_CMINPACK@", "");
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
        if 0 <> System.systemCallRestrictedEnv(cmd, outFile=logfile) then
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
      if 0 <> System.systemCallRestrictedEnv("cd " + dir + " && "+ Autoconf.make + " clean > /dev/null 2>&1") then
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

protected function translateModelFMU
  "translates modelica model as FMU, generates only c code and does not build"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input String FMUVersion;
  input String inFMUType;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input list<String> platforms = {"static"};
  input Option<SimCode.SimulationSettings> inSimSettings = NONE();
  output Boolean success;
  output FCore.Cache cache;
  output Values.Value outValue;
protected
  Absyn.Program p;
  Flags.Flag flags;
algorithm
  // handle encryption
  // if AST contains encrypted class show nothing
  p := SymbolTable.getAbsyn();
  if Interactive.astContainsEncryptedClass(p) then
    Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
    cache := inCache;
    outValue := Values.STRING("");
  else
    flags := loadCommandLineOptionsFromModel(className);

    try
      (success, cache, outValue) := callTranslateModelFMU(inCache,inEnv,className,FMUVersion,inFMUType,inFileNamePrefix,addDummy,platforms,inSimSettings);
      // reset to the original flags
      FlagsUtil.saveFlags(flags);
    else
      FlagsUtil.saveFlags(flags);
      fail();
    end try;
  end if;
end translateModelFMU;

protected function callTranslateModelFMU
 "Translates a model into target code and writes CMakeLists.txt"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input String FMUVersion;
  input String inFMUType;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input list<String> platforms = {"static"};
  input Option<SimCode.SimulationSettings> inSimSettings = NONE();
  output Boolean success;
  output FCore.Cache cache;
  output Values.Value outValue;
protected
  String filenameprefix, fmuTargetName;
  GlobalScript.SimulationOptions defaultSimOpt;
  SimCode.SimulationSettings simSettings;
  list<String> libs;
  String FMUType = inFMUType;
algorithm
  cache := inCache;
  if not FMI.checkFMIVersion(FMUVersion) then
    success :=false;
    outValue := Values.STRING("");
    Error.addMessage(Error.UNKNOWN_FMU_VERSION, {FMUVersion});
    return;
  elseif not FMI.checkFMIType(FMUType) then
    success :=false;
    outValue := Values.STRING("");
    Error.addMessage(Error.UNKNOWN_FMU_TYPE, {FMUType});
    return;
  end if;
  if not FMI.canExportFMU(FMUVersion, FMUType) then
    success :=false;
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
  filenameprefix := Util.stringReplaceChar(if inFileNamePrefix == "<default>" then AbsynUtil.pathLastIdent(className) else inFileNamePrefix, ".", "_");
  fmuTargetName := if FMUVersion == "1.0" then filenameprefix else (if inFileNamePrefix == "<default>" then AbsynUtil.pathLastIdent(className) else inFileNamePrefix);
  if isSome(inSimSettings)  then
    SOME(simSettings) := inSimSettings;
  else
    defaultSimOpt := buildSimulationOptionsFromModelExperimentAnnotation(className, filenameprefix, SOME(defaultSimulationOptions));
    simSettings := convertSimulationOptionsToSimCode(defaultSimOpt);
  end if;
  FlagsUtil.setConfigBool(Flags.BUILDING_FMU, true);
  FlagsUtil.setConfigString(Flags.FMI_VERSION, FMUVersion);

  try
    (success, cache, libs, _, _) := SimCodeMain.translateModel(SimCodeMain.TranslateModelKind.FMU(FMUType, fmuTargetName),
                                            cache, inEnv, className, filenameprefix, true, false, true, SOME(simSettings));
    outValue := Values.STRING((if not Testsuite.isRunning() then System.pwd() + Autoconf.pathDelimiter else "") + fmuTargetName + ".fmu");
  else
    success :=false;
    outValue := Values.STRING("");
  end try;
  FlagsUtil.setConfigBool(Flags.BUILDING_FMU, false);
  FlagsUtil.setConfigString(Flags.FMI_VERSION, "");
end callTranslateModelFMU;

protected function buildModelFMU
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input String FMUVersion;
  input String inFMUType;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input list<String> platforms = {"static"};
  input Option<SimCode.SimulationSettings> inSimSettings = NONE();
  output FCore.Cache cache;
  output Values.Value outValue;
protected
  Absyn.Program p;
  Flags.Flag flags;
algorithm
  // handle encryption
  // if AST contains encrypted class show nothing
  p := SymbolTable.getAbsyn();
  if Interactive.astContainsEncryptedClass(p) then
    Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
    cache := inCache;
    outValue := Values.STRING("");
  else
    flags := loadCommandLineOptionsFromModel(className);

    try
      (cache, outValue) := callBuildModelFMU(inCache,inEnv,className,FMUVersion,inFMUType,inFileNamePrefix,addDummy,platforms,inSimSettings);
      // reset to the original flags
      FlagsUtil.saveFlags(flags);
    else
      FlagsUtil.saveFlags(flags);
      fail();
    end try;
  end if;
end buildModelFMU;

protected function callBuildModelFMU
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
  input Option<SimCode.SimulationSettings> inSimSettings = NONE();
  output FCore.Cache cache;
  output Values.Value outValue;
protected
  Boolean staticSourceCodeFMU, success;
  String filenameprefix, fmutmp, logfile, configureLogFile, dir, cmd;
  String fmuTargetName;
  GlobalScript.SimulationOptions defaultSimOpt;
  SimCode.SimulationSettings simSettings;
  list<String> libs;
  Boolean isWindows;
  list<String> fmiFlagsList;
  Boolean needs3rdPartyLibs;
  String FMUType = inFMUType;
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
  filenameprefix := Util.stringReplaceChar(if inFileNamePrefix == "<default>" then AbsynUtil.pathLastIdent(className) else inFileNamePrefix, ".", "_");
  fmuTargetName := if FMUVersion == "1.0" then filenameprefix else (if inFileNamePrefix == "<default>" then AbsynUtil.pathLastIdent(className) else inFileNamePrefix);
  if isSome(inSimSettings)  then
    SOME(simSettings) := inSimSettings;
  else
    defaultSimOpt := buildSimulationOptionsFromModelExperimentAnnotation(className, filenameprefix, SOME(defaultSimulationOptions));
    simSettings := convertSimulationOptionsToSimCode(defaultSimOpt);
  end if;
  FlagsUtil.setConfigBool(Flags.BUILDING_FMU, true);
  FlagsUtil.setConfigString(Flags.FMI_VERSION, FMUVersion);
  try
    (success, cache, libs, _, _) := SimCodeMain.translateModel(SimCodeMain.TranslateModelKind.FMU(FMUType, fmuTargetName),
                                            cache, inEnv, className, filenameprefix, true, false, true, SOME(simSettings));
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

  fmutmp := Util.hashFileNamePrefix(filenameprefix) + ".fmutmp";
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
    if 0 <> System.systemCallRestrictedEnv(Autoconf.make + " -f " + filenameprefix + "_FMU.makefile clean", outFile=logfile) then
      // do nothing
    end if;
    return;
  end if;
  /*Temporary disabled omsicpp*/
  if not ((Config.simCodeTarget() == "omsic")/* or (Config.simCodeTarget() == "omsicpp")*/) then
    CevalScript.compileModel(filenameprefix+"_FMU" , libs);
    ExecStat.execStat("buildModelFMU: Generate the FMI files");
  else
    fmutmp := fmutmp + Autoconf.pathDelimiter;
    CevalScript.compileModel(filenameprefix+"_FMU" , libs, fmutmp);
    return;
  end if;

  // Check flag fmiFlags if we need additional 3rdParty runtime libs and files
  needs3rdPartyLibs := SimCodeUtil.cvodeFmiFlagIsSet(SimCodeUtil.createFMISimulationFlags(false));

  // Warn about deprecated Makefile build
  if not Flags.getConfigBool(Flags.FMU_CMAKE_BUILD) then
    Error.addCompilerNotification("The Makefile build for FMUs is deprecated and will be removed in a future version of OpenModelica."
                                  + " Use \"--" + Flags.getConfigName(Flags.FMU_CMAKE_BUILD) + "=true\".");
  end if;

  // Configure the FMU Makefile
  for platform in platforms loop
    configureLogFile := System.realpath(fmutmp)+"/resources/"+System.stringReplace(listGet(Util.stringSplitAtChar(platform," "),1),"/","-")+".log";
    if Flags.getConfigBool(Flags.FMU_CMAKE_BUILD) then
      configureFMU_cmake(platform, fmutmp, filenameprefix, configureLogFile, libs, isWindows);
    else
      configureFMU(platform, fmutmp, configureLogFile, isWindows, needs3rdPartyLibs);
    end if;
    if Flags.getConfigEnum(Flags.FMI_FILTER) == Flags.FMI_BLACKBOX or Flags.getConfigEnum(Flags.FMI_FILTER) == Flags.FMI_PROTECTED then
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

  if not Flags.isSet(Flags.GEN_DEBUG_SYMBOLS) then
    if not System.removeDirectory(fmutmp) then
      Error.addInternalError("Failed to remove directory: " + fmutmp, sourceInfo());
    end if;
  end if;
end callBuildModelFMU;

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
  cls := InteractiveUtil.getPathedClassInProgram(className, inProgram);
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
      packageTool := stringAppendList({omhome,pd,"bin",pd,"omc-semla",pd,"packagetool",ext});
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

      if (StringUtil.endsWith(fileName, "package.mo")) then
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
  Absyn.Program p;
  Boolean success;
algorithm
  // handle encryption
  // if AST contains encrypted class show nothing
  p := SymbolTable.getAbsyn();
  if Interactive.astContainsEncryptedClass(p) then
    Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
    outValue := Values.STRING("");
  else
    (success,cache) := SimCodeMain.translateModel(SimCodeMain.TranslateModelKind.XML(), cache, env, className, fileNamePrefix, true, false, true, inSimSettingsOpt);
    outValue := Values.STRING(if success then ((if not Testsuite.isRunning() then System.pwd() + Autoconf.pathDelimiter else "") + fileNamePrefix+".xml") else "");
  end if;
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
        cls = InteractiveUtil.getPathedClassInProgram(className, p);
        refactoredClass = Refactor.refactorGraphicalAnnotation(p, cls);
        within_ = InteractiveUtil.buildWithin(className);
        SymbolTable.setAbsyn(InteractiveUtil.updateProgram(Absyn.PROGRAM({refactoredClass}, within_), p));
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
  input list<Values.Value> vals;
  output FCore.Cache outCache;
  output SimCode.SimulationSettings outSimSettings;
algorithm
  (outCache,outSimSettings) := match (inCache,vals)
    local
      String method_str,options_str,outputFormat_str,variableFilter_str;
      Values.Value starttime_v,stoptime_v,tolerance_v;
      Integer interval_i;
      Real starttime_r,stoptime_r,tolerance_r;
      FCore.Cache cache;
      String cflags;
    case (cache, {Values.CODE(Absyn.C_TYPENAME(_)),starttime_v,stoptime_v,Values.INTEGER(interval_i),tolerance_v,Values.STRING(method_str),_,Values.STRING(options_str),Values.STRING(outputFormat_str),Values.STRING(variableFilter_str),Values.STRING(cflags),Values.STRING(_)})
      equation
        starttime_r = ValuesUtil.valueReal(starttime_v);
        stoptime_r = ValuesUtil.valueReal(stoptime_v);
        tolerance_r = ValuesUtil.valueReal(tolerance_v);
        outSimSettings = SimCodeMain.createSimulationSettings(starttime_r,stoptime_r,interval_i,tolerance_r,method_str,options_str,outputFormat_str,variableFilter_str,cflags);
      then
        (cache, outSimSettings);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"CevalScript.calculateSimulationSettings failed: " + ValuesUtil.valString(Values.TUPLE(vals))});
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
          InteractiveUtil.getPathedClassInProgram(inWithin.path, inProg);
      then
        dst_path;

  end match;

  // Update the paths in the class to reflect the new location.
  cls := NFApi.updateMovedClassPaths(inClass, inClassPath, inWithin);

  // Replace the filename of each element with the new path.
  cls := moveClassInfo(cls, dst_path);

  // Change the name of the class and put it in as a copy in the program.
  cls := AbsynUtil.setClassName(cls, inName);
  outProg := InteractiveUtil.updateProgram(Absyn.PROGRAM({cls}, inWithin), inProg);
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
  outAnnotation.elementArgs := list(moveElementArgInfo(e, dstPath) for e in outAnnotation.elementArgs);
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

    else ();
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

    else ();
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
  outComponent.modification := moveModificationInfo(outComponent.modification, dstPath);
end moveComponentInfo;

protected function moveExternalDeclInfo
  input Absyn.ExternalDecl inExtDecl;
  input String dstPath;
  output Absyn.ExternalDecl outExtDecl = inExtDecl;
algorithm
  outExtDecl.annotation_ := moveAnnotationOptInfo(outExtDecl.annotation_, dstPath);
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
  output list<String> outLibsAndLibDirs;
algorithm
  (outCache,compileDir,outString1,outString2,outputFormat_str,outInitFileName,outSimFlags,resultValues,outArgs,outLibsAndLibDirs):=
  matchcontinue (inCache,inEnv,inValues,inMsg)
    local
      BackendDAE.BackendDAE indexed_dlow_1;
      list<String> libsAndLibDirs;
      String file_dir,init_filename,method_str,filenameprefix,exeFile,s3,simflags;
      Absyn.Path classname;
      Absyn.Program p;
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
          simflags_mod := Interactive.getNamedAnnotationExp(classname, SymbolTable.getAbsyn(),
            Absyn.IDENT("__OpenModelica_simulationFlags"), SOME(NONE()), Util.id);
          simflags := formatSimulationFlagsString(simflags_mod);

          if not stringEmpty(simflags) then
            values := List.replaceAt(Values.STRING(simflags), 12, values);
          end if;
        end if;

        compileDir := System.pwd() + Autoconf.pathDelimiter;
        (cache,simSettings) := calculateSimulationSettings(cache, values);
        SimCode.SIMULATION_SETTINGS(method = method_str, outputFormat = outputFormat_str) := simSettings;

        (success,cache,libsAndLibDirs,file_dir,resultValues) := translateModel(cache,env, classname, filenameprefix, true, true, SOME(simSettings));
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
            CevalScript.compileModel(filenameprefix, libsAndLibDirs);
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
        (cache,compileDir,filenameprefix,method_str,outputFormat_str,init_filename,simflags,resultValues,values,libsAndLibDirs);

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
        cdef = InteractiveUtil.getPathedClassInProgram(p_class, p);
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
  input FCore.Graph env;
  input Absyn.Path className;
  input Absyn.Msg inMsg;
        output Values.Value outValue;
algorithm
  outValue := matchcontinue ()
    local
      Option<DAE.DAElist> odae;
      DAE.DAElist dae;
      Integer eqnSize,varSize,simpleEqnSize;
      String retStr,classNameStr;
      Flags.Flag flags;

    // handle normal models
    case ()
      algorithm
        flags := loadCommandLineOptionsFromModel(className);

        try
          (cache, _, odae) := runFrontEnd(cache, env, className, false);
          SOME(dae) := odae;
          (varSize, eqnSize, simpleEqnSize) := CheckModel.checkModel(dae);
          FlagsUtil.saveFlags(flags);
        else
          FlagsUtil.saveFlags(flags);
          fail();
        end try;

        classNameStr := AbsynUtil.pathString(className);
        retStr := stringAppendList({"Check of ",classNameStr," completed successfully.\nClass ",classNameStr," has ",String(eqnSize)," equation(s) and ",
          String(varSize)," variable(s).\n",String(simpleEqnSize)," of these are trivial equation(s)."});
      then Values.STRING(retStr);

    case ()
      equation
        false = Interactive.existClass(className, SymbolTable.getAbsyn());
        Error.addMessage(Error.LOOKUP_ERROR, {AbsynUtil.pathString(className), "<TOP>"});
      then Values.STRING("");

    // errors
    else
      equation
        if Error.getNumMessages() == 0 then
          Error.addMessage(Error.INTERNAL_ERROR,
            {"Check of " + AbsynUtil.pathString(className) + " failed with no error message","<TOP>"});
        end if;
      then Values.STRING("");

  end matchcontinue;
end checkModel;

protected function getWithinStatement "To get a correct Within-path with unknown input-path."
  input Absyn.Path ip;
  output Absyn.Within op;
algorithm op :=  matchcontinue(ip)
  local Absyn.Path path;
    case(path) equation path = AbsynUtil.stripLast(path); then Absyn.WITHIN(path);
    else Absyn.TOP();
  end matchcontinue;
end getWithinStatement;

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

        (cache, env, SOME(dae), _) = runFrontEnd(cache, env, classname, true, transform = true);
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

        (cache, env, SOME(dae), _) = runFrontEnd(cache, env, classname, true, transform = true);
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

        (cache, env, SOME(dae), _) = runFrontEnd(cache, env, classname, true, transform = true);
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

        (cache, env, SOME(dae), _) = runFrontEnd(cache, env, classname, true, transform = true);
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
        strlist = InteractiveUtil.getClassnamesInParts(parts,b,false);
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
        strlist = InteractiveUtil.getClassnamesInParts(parts,b,false);
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
        cdef = InteractiveUtil.getPathedClassInProgram(inPath, p);
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
        // print ("All paths:\n" + stringDelimitList(List.map(allClassPaths, AbsynUtil.pathString), "\n") + "\n");
        failed = checkAll(cache, env, allClassPaths, msg, not Testsuite.isRunning(), 0);
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
  input Boolean reportTimes;
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
        c = InteractiveUtil.getPathedClassInProgram(className, p);
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

        if reportTimes then
          print (s + " seconds -> " + smsg + "\n");
        else
          print(smsg + "\n");
        end if;

        if not stringEmpty(str) then
          print("\t");
        end if;

        print (System.stringReplace(str, "\n", "\n\t"));
        print ("\n");
        print ("Error String:\n" + Print.getErrorString() + "\n");
        print ("Error Buffer:\n" + ErrorExt.printMessagesStr(false) + "\n");
        print ("#" + (if f then "[-]" else "[+]") + ", " +
          (if reportTimes then realString(elapsedTime) + ", " else "") +
          AbsynUtil.pathString(className) + "\n");
        print ("-------------------------------------------------------------------------\n");
        failed = checkAll(cache, env, rest, msg, reportTimes, failed);
      then ();

    case (cache,env,className::rest,msg)
      equation
        c = InteractiveUtil.getPathedClassInProgram(className, p);
        print("Checking skipped: " + Dump.unparseClassAttributesStr(c) + " " + AbsynUtil.pathString(className) + "...\n");
        failed = checkAll(cache, env, rest, msg, reportTimes, failed);
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
  (pub_imports_list , pro_imports_list) := CevalScript.getImportList(inClass);
  outInteger := listLength(pub_imports_list) + listLength(pro_imports_list);
end getImportCount;


protected function getNthImport
"Returns the Nth Import String from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output list<Values.Value> outValue;
protected
  list<Absyn.Import> pub_imports_list , pro_imports_list;
algorithm
  (pub_imports_list, pro_imports_list) := CevalScript.getImportList(inClass);
  outValue := unparseNthImport(listGet(pub_imports_list,inInteger));
end getNthImport;

protected function unparseNthImport
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
        Absyn.CLASS(body = Absyn.DERIVED()) = InteractiveUtil.getPathedClassInProgram(path, p);
      then
        true;
    else false;
  end matchcontinue;
end isShortDefinition;

protected function isExperiment
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
protected
  Absyn.Class cdef;
algorithm
  try
    cdef := InteractiveUtil.getPathedClassInProgram(path, program);
    false := AbsynUtil.isPartial(cdef);
    true := AbsynUtil.isModel(cdef) or AbsynUtil.isBlock(cdef);
    SOME(res) := AbsynUtil.getNamedAnnotationInClass(cdef, Absyn.Path.IDENT("experiment"), hasStopTime);
  else
    res := false;
  end try;
end isExperiment;

protected function hasStopTime "For use with getNamedAnnotationExp"
  input Option<Absyn.Modification> mod;
  output Boolean b;
algorithm
  b := match (mod)
    local
      list<Absyn.ElementArg> arglst;
    case (SOME(Absyn.CLASSMOD(elementArgLst = arglst)))
      then List.any(arglst,hasStopTime2);

  end match;
end hasStopTime;

protected function hasStopTime2 "For use with getNamedAnnotationExp"
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
        absynClass = InteractiveUtil.getPathedClassInProgram(ValuesUtil.getPath(val), p);
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
  input Boolean obfuscate;
protected
  SCode.Program scodeP;
  String str,str1,str2,str3;
  NFSCodeEnv.Env env;
  SCode.Comment cmt;
  String obfuscate_map;
  Absyn.Path cls_path = classpath;
algorithm
  runFrontEndLoadProgram(cls_path);
  scodeP := SymbolTable.getSCode();
  (scodeP, env) := NFSCodeFlatten.flattenClassInProgram(cls_path, scodeP);
  (NFSCodeEnv.CLASS(cls=SCode.CLASS(cmt=cmt)),_,_) := NFSCodeLookup.lookupClassName(cls_path, env, AbsynUtil.dummyInfo);
  scodeP := SCodeUtil.removeBuiltinsFromTopScope(scodeP);

  if stripAnnotations or stripComments then
    scodeP := SCodeUtil.stripCommentsFromProgram(scodeP, stripAnnotations, stripComments);
  end if;

  if obfuscate then
    (scodeP, cls_path, cmt, obfuscate_map) := Obfuscate.obfuscateProgram(scodeP, cls_path, cmt);
    System.writeFile(StringUtil.stripFileExtension(filename) + "_mapping.json", obfuscate_map);
  end if;

  str := SCodeDump.programStr(scodeP,SCodeDump.defaultOptions);
  str1 := AbsynUtil.pathLastIdent(cls_path) + "_total";
  str2 := if stripComments then "" else SCodeDump.printCommentStr(cmt);
  str2 := if stringEq(str2,"") then "" else (" " + str2);
  str3 := if stripAnnotations then "" else SCodeDump.printAnnotationStr(cmt,SCodeDump.defaultOptions);
  str3 := if stringEq(str3,"") then "" else (str3 + ";\n");
  str1 := "\nmodel " + str1 + str2 + "\n  extends " + AbsynUtil.pathString(cls_path) + ";\n" + str3 + "end " + str1 + ";\n";
  System.writeFile(filename, str + str1);
end saveTotalModel;

protected function saveTotalModelDebug
  input String filename;
  input Absyn.Path classPath;
  input Boolean stripAnnotations;
  input Boolean stripComments;
  input Boolean obfuscate;
protected
  SCode.Program prog;
  String str, name_str, cls_str, str1, str2, str3;
  Absyn.Path cls_path = classPath;
  Option<SCode.Comment> ocmt;
  SCode.Comment cmt;
algorithm
  runFrontEndLoadProgram(cls_path);
  prog := SymbolTable.getSCode();
  prog := TotalModelDebug.getTotalModel(prog, cls_path);
  prog := SCodeUtil.removeBuiltinsFromTopScope(prog);
  ocmt := SCodeUtil.getElementComment(InteractiveUtil.getPathedSCodeElementInProgram(cls_path, prog));
  cmt := if isSome(ocmt) then Util.getOption(ocmt) else SCode.noComment;

  if stripAnnotations or stripComments then
    prog := SCodeUtil.stripCommentsFromProgram(prog, stripAnnotations, stripComments);
  end if;

  if obfuscate then
    (prog, cls_path, cmt, _) := Obfuscate.obfuscateProgram(prog, cls_path, cmt);
  end if;

  str := SCodeDump.programStr(prog, SCodeDump.defaultOptions);
  str1 := AbsynUtil.pathLastIdent(cls_path) + "_total";
  str2 := if stripComments then "" else SCodeDump.printCommentStr(cmt);
  str2 := if stringEq(str2,"") then "" else (" " + str2);
  str3 := if stripAnnotations then "" else SCodeDump.printAnnotationStr(cmt,SCodeDump.defaultOptions);
  str3 := if stringEq(str3,"") then "" else (str3 + ";\n");
  str1 := "\nmodel " + str1 + str2 + "\n  extends " + AbsynUtil.pathString(cls_path) + ";\n" + str3 + "end " + str1 + ";\n";
  System.writeFile(filename, str + str1);
end saveTotalModelDebug;

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
        stateStr = Interactive.getNamedAnnotationExp(className, p, Absyn.IDENT("__Dymola_state"), SOME("false"), getDymolaStateAnnotationModStr);
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
  String name,file,strPartial,strFinal,strEncapsulated,res,cmt,str_readonly,str_sline,str_scol,str_eline,str_ecol,version,preferredView,access,versionDate,versionBuild,dateModified,revisionId;
  String dim_str,lastIdent;
  Boolean partialPrefix,finalPrefix,encapsulatedPrefix,isReadOnly,isProtectedClass,isDocClass,isState;
  Absyn.Restriction restr;
  Absyn.ClassDef cdef;
  Integer sl,sc,el,ec;
  Absyn.Path classPath;
algorithm
  Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restr,cdef,_,_,_,SOURCEINFO(file,isReadOnly,sl,sc,el,ec,_)) := InteractiveUtil.getPathedClassInProgram(path, p);
  res := Dump.unparseRestrictionStr(restr);
  cmt := getClassDefComment(cdef);
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
  preferredView := Interactive.getStringNamedAnnotation(path, p, Absyn.IDENT("preferredView"));
  isState := getDymolaStateAnnotation(path, p);
  access := Interactive.getAccessAnnotation(path, p);
  versionDate := Interactive.getStringNamedAnnotation(path, p, Absyn.IDENT("versionDate"));
  versionBuild := Interactive.getIntegerNamedAnnotation(path, p, Absyn.IDENT("versionBuild"));
  dateModified := Interactive.getStringNamedAnnotation(path, p, Absyn.IDENT("dateModified"));
  revisionId := Interactive.getStringNamedAnnotation(path, p, Absyn.IDENT("revisionId"));
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
    Values.STRING(access),
    Values.STRING(versionDate),
    Values.STRING(versionBuild),
    Values.STRING(dateModified),
    Values.STRING(revisionId)
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

function getClassElementComment
  "Returns the comment on a class element."
  input Absyn.Element element;
  output String commentStr;
protected
  Absyn.Class cls;
algorithm
  commentStr := match element
    case Absyn.Element.ELEMENT(specification = Absyn.ElementSpec.CLASSDEF(class_ = cls))
      algorithm
        // The comment can go either before and/or after the constrainedby clause,
        // the one after has higher priority.
        commentStr := InteractiveUtil.getConstrainingClassComment(element.constrainClass);

        if stringEmpty(commentStr) then
          commentStr := getClassDefComment(cls.body);
        end if;
      then
        commentStr;

    else "";
  end match;
end getClassElementComment;

function getClassDefComment "Returns the class comment of a Absyn.ClassDef"
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
end getClassDefComment;

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
        lineProgram = InteractiveUtil.modelicaAnnotationProgram(Config.getAnnotationVersion());
        fargs = Interactive.createFuncargsFromElementargs(mod);
        p_1 = AbsynToSCode.translateAbsyn2SCode(lineProgram);
        (cache,env) = Inst.makeEnvFromProgram(p_1);
        (_,newexp,prop) = StaticScript.elabGraphicsExp(cache,env, Absyn.CALL(Absyn.CREF_IDENT(annName,{}),fargs,{}), false,DAE.NOPRE(), sourceInfo()) "impl" ;
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
  cdef := InteractiveUtil.getPathedClassInProgram(path, p);
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
  cdef := InteractiveUtil.getPathedClassInProgram(path, p);
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
  (b, outProgram) := addInitialStateWithAnnotation(inPath, state, InteractiveUtil.annotationListToAbsyn(inAbsynNamedArgLst), inProgram);
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
        cdef = InteractiveUtil.getPathedClassInProgram(modelpath, p);
        cmt = SOME(Absyn.COMMENT(SOME(ann), NONE()));
        newcdef = Interactive.addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_NORETCALL(Absyn.CREF_IDENT("initialState", {}),
                                Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(state_, {}))}, {})), cmt, AbsynUtil.dummyInfo));
        if AbsynUtil.pathIsIdent(AbsynUtil.makeNotFullyQualified(modelpath)) then
          newp = InteractiveUtil.updateProgram(Absyn.PROGRAM({newcdef},p.within_), p);
        else
          package_ = AbsynUtil.stripLast(modelpath);
          newp = InteractiveUtil.updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(package_)), p);
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
        cdef = InteractiveUtil.getPathedClassInProgram(modelpath, p);
        newcdef = deleteInitialStateInClass(cdef, state_);
        if AbsynUtil.pathIsIdent(AbsynUtil.makeNotFullyQualified(modelpath)) then
          newp = InteractiveUtil.updateProgram(Absyn.PROGRAM({newcdef}, Absyn.TOP()), p);
        else
          modelwithin = AbsynUtil.stripLast(modelpath);
          newp = InteractiveUtil.updateProgram(Absyn.PROGRAM({newcdef}, Absyn.WITHIN(modelwithin)), p);
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
    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann=ann,comment = cmt),
                      info = file_info), state_)
      equation
        eqlst = InteractiveUtil.getEquationList(parts);
        eqlst_1 = deleteInitialStateInEqlist(eqlst, state_);
        parts2 = InteractiveUtil.replaceEquationList(parts, eqlst_1);
        outClass.body = Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then outClass;
    /* an extended class with parts: model extends M end M;  */
    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications=modif,parts = parts,ann = ann,comment = cmt)
                      ,info = file_info), state_)
      equation
        eqlst = InteractiveUtil.getEquationList(parts);
        eqlst_1 = deleteInitialStateInEqlist(eqlst, state_);
        parts2 = InteractiveUtil.replaceEquationList(parts, eqlst_1);
        outClass.body = Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann);
      then outClass;
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
  input Interactive.GraphicEnvCache inEnv;
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
              (_, p_1) = Interactive.mkFullyQual(inEnv, p);
            then AbsynUtil.pathString(p_1);
          else AbsynUtil.pathString(p);
        end matchcontinue;
        vs := {};

        dims1 := list(Dump.printSubscriptStr(sub) for sub in attr.arrayDim);
        r_1 := Interactive.keywordReplaceable(comp.redeclareKeywords);
        inout_str := AbsynUtil.innerOuterStr(comp.innerOuter);
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
    case Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = c1),comment = SOME(Absyn.COMMENT(_,_)))
      then (c1, "");
    case Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = c1),comment = NONE())
      then (c1, "");
  end match;
end getComponentitemsName;

function getAnnotationNamedModifiers
  input Absyn.Path classPath;
  input String annotationName;
  input Absyn.Program program;
  output Values.Value result;
protected
  Absyn.Class cls;
  list<String> names;

  function get_names
    input Option<Absyn.Modification> mod;
    output list<String> names;
  protected
    Absyn.Modification m;
    list<Absyn.Path> paths;
  algorithm
    names := match mod
      case SOME(m)
        algorithm
          paths := list(AbsynUtil.elementArgName(a) for a in m.elementArgLst);
        then
          list(AbsynUtil.pathString(p) for p guard AbsynUtil.pathIsIdent(p) in paths);
      else {};
    end match;
  end get_names;
algorithm
  cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
  SOME(names) := AbsynUtil.getNamedAnnotationInClass(cls, Absyn.Path.IDENT(annotationName), get_names);
  result := ValuesUtil.makeStringArray(names);
end getAnnotationNamedModifiers;

function getOptModifierValue
  input Option<Absyn.Modification> modifier;
  output Values.Value value;
protected
  Absyn.Modification mod;
  Absyn.Exp exp;
algorithm
  SOME(mod) := modifier;
  Absyn.EqMod.EQMOD(exp = exp) := mod.eqMod;
  value := ValuesUtil.absynExpValue(exp);
end getOptModifierValue;

function getAnnotationModifierValue
  input Absyn.Path classPath;
  input String annotationName;
  input String modifierName;
  input Absyn.Program program;
  output Values.Value result;
protected
  Absyn.Class cls;
algorithm
  cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
  SOME(result) := AbsynUtil.getNamedAnnotationInClass(cls,
    Absyn.Path.QUALIFIED(annotationName, Absyn.Path.IDENT(modifierName)), getOptModifierValue);
end getAnnotationModifierValue;

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
  Flags.Flag flags;
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
        flags := loadCommandLineOptionsFromModel(path);

        try
          (cache, _, odae, str) := runFrontEnd(cache, env, path, relaxedFrontEnd = false,
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

          FlagsUtil.saveFlags(flags);
        else
          FlagsUtil.saveFlags(flags);
          fail();
        end try;
      then
        str;

    case ()
      algorithm
        false := Interactive.existClass(path, SymbolTable.getAbsyn());
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

protected function getConnectionList
"@author: rahulp
  Returns a list of all connect equations including those in loops"
  input Absyn.Path className;
  output Values.Value valList;
  protected
    SCode.Program sp, annotation_sp;
    list<list<String>> connList;
  algorithm
    annotation_sp := AbsynToSCode.translateAbsyn2SCode(InteractiveUtil.modelicaAnnotationProgram(Config.getAnnotationVersion()));
    (_, sp) := FBuiltin.getInitialFunctions();
    sp := listAppend(SymbolTable.getSCode(), sp);
    connList := NFInst.instClassForConnection(className, sp, annotation_sp);
    valList := ValuesUtil.makeArray(list(ValuesUtil.makeArray(List.map(conn, ValuesUtil.makeString)) for conn in connList));
end getConnectionList;

protected function runConversionScript
  input Absyn.Path clsPath;
  input String scriptFile;
  output Values.Value res;
protected
  Absyn.Program p;
  Absyn.Class cls;
  Absyn.Within wi;
algorithm
  try
    p := SymbolTable.getAbsyn();
    cls := InteractiveUtil.getPathedClassInProgram(clsPath, p, showError = true);
    //System.startTimer();
    cls := Conversion.convertPackage(cls, scriptFile);
    //System.stopTimer();
    //print("Conversion took " + String(System.getTimerIntervalTime()) + " seconds.\n");
    wi := InteractiveUtil.buildWithin(clsPath);
    p := InteractiveUtil.updateProgram(Absyn.PROGRAM({cls}, wi), p);
    SymbolTable.setAbsyn(p);
    res := Values.BOOL(true);
  else
    res := Values.BOOL(false);
  end try;
end runConversionScript;

protected function convertPackageToLibrary
  input Absyn.Path clsPath;
  input Absyn.Path libPath;
  input String libVersion;
  output Values.Value res;
protected
  Absyn.Program p, lib_program;
  Absyn.Class cls, lib_cls;
  Absyn.Within wi;
  list<String> cls_uses, lib_converts_from;
  Boolean b, has_conversion;
  Option<String> uses_version;
  SemanticVersion.Version lib_version, lib_version_used;
  list<tuple<String, Option<String>, Option<String>>> conversions;
  list<String> scripts;
  String lib_name;
algorithm
  try
    // Get the Absyn for the class and check which version of the library it's using.
    p := SymbolTable.getAbsyn();
    cls := InteractiveUtil.getPathedClassInProgram(clsPath, p, showError = true);
    uses_version := Interactive.getUsedVersion(cls, libPath);

    if isSome(uses_version) then
      lib_version_used := SemanticVersion.parse(Util.getOption(uses_version), true);
    else
      Error.addMessage(Error.CONVERSION_MISSING_USES,
        {AbsynUtil.pathString(clsPath), AbsynUtil.pathString(libPath)});
      fail();
    end if;

    lib_name := AbsynUtil.pathFirstIdent(libPath);
    lib_version := SemanticVersion.parse(CevalScript.getPackageVersion(libPath, p));

    // Check if the wanted version of the library is already loaded, otherwise
    // we need to load it.
    if SemanticVersion.compare(lib_version, SemanticVersion.parse(libVersion)) <> 0 then
      // Try to set the language standard to the version needed to load the wanted library.
      if lib_name == "Modelica" then
        Config.setLanguageStandardFromMSL("Modelica " + libVersion, force = true);
      end if;

      // Load the library that we want to convert the class to.
      (lib_program, true) := CevalScript.loadModel({(libPath, lib_name, {libVersion}, false)},
        Settings.getModelicaPath(Testsuite.isRunning()), p, true, true, false, true);
      SymbolTable.setAbsyn(lib_program);
    else
      lib_program := p;
    end if;

    // Get the version of the library.
    lib_version := SemanticVersion.parse(CevalScript.getPackageVersion(libPath, lib_program));

    // Try to find a sequence of conversion scripts that can be used to convert
    // the class to the desired library version.
    lib_cls := InteractiveUtil.getPathedClassInProgram(libPath, lib_program, showError = true);
    conversions := Interactive.getConversionsInClass(lib_cls);
    scripts := findConversionPaths(conversions, lib_version, lib_version_used);

    if listEmpty(scripts) then
      Error.addMessage(Error.CONVERSION_NO_COMPATIBLE_SCRIPT_FOUND,
        {AbsynUtil.pathString(libPath),
         SemanticVersion.toString(lib_version_used),
         SemanticVersion.toString(lib_version)});
      fail();
    end if;

    // Apply the conversion scripts.
    for script in scripts loop
      script := uriToFilename(script);
      cls := Conversion.convertPackage(cls, script);
    end for;

    // Update the uses-annotation in the class to refer to the new version of the library.
    cls := Interactive.updateUsedVersion(cls, libPath, SemanticVersion.toString(lib_version));

    // Finally update the class in the global Absyn.
    wi := InteractiveUtil.buildWithin(clsPath);
    lib_program := InteractiveUtil.updateProgram(Absyn.PROGRAM({cls}, wi), lib_program);
    SymbolTable.setAbsyn(lib_program);
    res := Values.BOOL(true);
  else
    res := Values.BOOL(false);
  end try;
end convertPackageToLibrary;

function findConversionPaths
  "Tries to find the shortest path for converting from one version to another
   and returns the list of conversion scripts for that path. Usually only one
   conversion is needed, but sometimes the conversion might need to be done in
   several steps (e.g. 2.0.0 => 2.3.5 => 2.4.0)."
  input list<tuple<String, Option<String>, Option<String>>> conversions;
  input SemanticVersion.Version libVersion;
  input SemanticVersion.Version libVersionUsed;
  input Integer depth = 0;
  output list<String> scripts = {};
protected
  String version;
  list<list<String>> paths = {};
  Integer path_len, path_min = 100;
algorithm
  // Abort if we go too deep to avoid crashing on malicious conversion annotations.
  if depth > 100 then
    return;
  end if;

  // Find the possible path for each conversion to the version we're looking for.
  for c in conversions loop
    paths := findConversionPath(c, libVersion, libVersionUsed, conversions, depth) :: paths;
  end for;

  // Return the shortest non-empty path.
  for p in paths loop
    path_len := listLength(p);

    if path_len > 0 and path_len < path_min then
      scripts := p;
      path_min := path_len;
    end if;
  end for;
end findConversionPaths;

function findConversionPath
  input tuple<String, Option<String>, Option<String>> conversion;
  input SemanticVersion.Version libVersion;
  input SemanticVersion.Version libVersionUsed;
  input list<tuple<String, Option<String>, Option<String>>> conversions;
  input Integer depth;
  output list<String> scripts = {};
protected
  String from;
  Option<String> to;
  Option<String> script;
  SemanticVersion.Version from_version, to_version;
algorithm
  (from, to, script) := conversion;

  if isNone(script) then
    return;
  end if;

  from_version := SemanticVersion.parse(from, true);

  if SemanticVersion.compare(libVersionUsed, from_version) == 0 then
    if isSome(to) then
      to_version := SemanticVersion.parse(Util.getOption(to), true);

      if SemanticVersion.compare(libVersion, to_version) <> 0 then
        scripts := findConversionPaths(conversions, libVersion, to_version, depth + 1);
      end if;
    end if;

    scripts := Util.getOption(script) :: scripts;
  end if;
end findConversionPath;

public function loadCommandLineOptionsFromModel
  "Applies flags from the __OpenModelica_commandLineOptions annotation of a given class and returns the old flags."
  input Absyn.Path className;
  output Flags.Flag oldFlags;
protected
  String opts;
  list<String> args;
algorithm
  if Config.ignoreCommandLineOptionsAnnotation() then
    oldFlags := FlagsUtil.loadFlags();
    return;
  end if;

  // read the __OpenModelica_commandLineOptions
  Absyn.STRING(opts) := Interactive.getNamedAnnotationExp(className, SymbolTable.getAbsyn(),
    Absyn.IDENT("__OpenModelica_commandLineOptions"), SOME(Absyn.STRING("")), Interactive.getAnnotationExp);

  if not stringEmpty(opts) then
    // backup the current flags and apply the flags from the annotation
    oldFlags := FlagsUtil.backupFlags();
    args := System.strtok(opts, " ");
    FlagsUtil.readArgs(args);
  else
    oldFlags := FlagsUtil.loadFlags();
  end if;
end loadCommandLineOptionsFromModel;

annotation(__OpenModelica_Interface="backend");

end CevalScriptBackend;
