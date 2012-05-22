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
public import Interactive;
public import Dependency;
public import Values;

// protected imports
protected import AbsynDep;
protected import BackendDump;
protected import BackendDAECreate;
protected import BackendDAEOptimize;
protected import BackendDAEUtil;
protected import BackendEquation;
protected import BackendVariable;
protected import Builtin;
protected import ClassInf;
protected import ClassLoader;
protected import Config;
protected import DAEQuery;
protected import DAEUtil;
protected import DAEDump;
protected import Debug;
protected import Dump;
protected import Expression;
protected import Flags;
protected import Inst;
protected import InnerOuter;
protected import List;
protected import Lookup;
protected import MetaUtil;
protected import Prefix;
protected import Parser;
protected import Print;
protected import Refactor;
protected import SCodeDump;
protected import SCodeFlatten;
protected import SimCode;
protected import System;
protected import Static;
protected import SCode;
protected import SCodeUtil;
protected import Settings;
protected import SimulationResults;
protected import Tpl;
protected import Types;
protected import Unparsing;
protected import Util;
protected import ValuesUtil;
protected import XMLDump;
protected import ComponentReference;
protected import Uncertainties;

public constant Integer RT_CLOCK_SIMULATE_TOTAL = 8;
public constant Integer RT_CLOCK_SIMULATE_SIMULATION = 9;
public constant Integer RT_CLOCK_BUILD_MODEL = 10;
public constant Integer RT_CLOCK_EXECSTAT_MAIN = Inst.RT_CLOCK_EXECSTAT_MAIN /* 11 */;
public constant Integer RT_CLOCK_EXECSTAT_BACKEND_MODULES = BackendDAE.RT_CLOCK_EXECSTAT_BACKEND_MODULES /* 12 */;
public constant Integer RT_CLOCK_FRONTEND = 13;
public constant Integer RT_CLOCK_BACKEND = 14;
public constant Integer RT_CLOCK_SIMCODE = 15;
public constant Integer RT_CLOCK_LINEARIZE = 16;
public constant Integer RT_CLOCK_TEMPLATES = 17;
public constant Integer RT_CLOCK_UNCERTAINTIES = 18;
public constant Integer RT_CLOCK_USER_RESERVED = 19;
public constant list<Integer> buildModelClocks = {RT_CLOCK_BUILD_MODEL,RT_CLOCK_SIMULATE_TOTAL,RT_CLOCK_TEMPLATES,RT_CLOCK_LINEARIZE,RT_CLOCK_SIMCODE,RT_CLOCK_BACKEND,RT_CLOCK_FRONTEND};

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


public
uniontype SimulationOptions "these are the simulation/buildModel* options"
  record SIMULATION_OPTIONS "simulation/buildModel* options"
    DAE.Exp startTime "start time, default 0.0";
    DAE.Exp stopTime "stop time, default 1.0";
    DAE.Exp numberOfIntervals "number of intervals, default 500";
    DAE.Exp stepSize "stepSize, default (stopTime-startTime)/numberOfIntervals";
    DAE.Exp tolerance "tolerance, default 1e-6";
    DAE.Exp method "method, default 'dassl'";
    DAE.Exp fileNamePrefix "file name prefix, default ''";
    DAE.Exp storeInTemp "store in temp, default false";
    DAE.Exp noClean "no cleaning, default false";
    DAE.Exp options "options, default ''";
    DAE.Exp outputFormat "output format, default 'plt'";
    DAE.Exp variableFilter "variable filter, regex does whole string matching, i.e. it becomes ^.*$ in the runtime";
    DAE.Exp measureTime "Enables time measurements, default false";
    DAE.Exp cflags "Compiler flags, in addition to MODELICAUSERCFLAGS";
    DAE.Exp simflags "Flags sent to the simulation executable (doesn't do anything for buildModel)";
  end SIMULATION_OPTIONS;
end SimulationOptions;

public constant DAE.Exp defaultStartTime         = DAE.RCONST(0.0)     "default startTime";
public constant DAE.Exp defaultStopTime          = DAE.RCONST(1.0)     "default stopTime";
public constant DAE.Exp defaultNumberOfIntervals = DAE.ICONST(500)     "default numberOfIntervals";
public constant DAE.Exp defaultStepSize          = DAE.RCONST(0.002)   "default stepSize";
public constant DAE.Exp defaultTolerance         = DAE.RCONST(1e-6)    "default tolerance";
public constant DAE.Exp defaultMethod            = DAE.SCONST("dassl") "default method";
public constant DAE.Exp defaultFileNamePrefix    = DAE.SCONST("")      "default fileNamePrefix";
public constant DAE.Exp defaultStoreInTemp       = DAE.BCONST(false)   "default storeInTemp";
public constant DAE.Exp defaultNoClean           = DAE.BCONST(false)   "default noClean";
public constant DAE.Exp defaultOptions           = DAE.SCONST("")      "default options";
public constant DAE.Exp defaultOutputFormat      = DAE.SCONST("mat")   "default outputFormat";
public constant DAE.Exp defaultVariableFilter    = DAE.SCONST(".*")    "default variableFilter; does whole string matching, i.e. it becomes ^.*$ in the runtime";
public constant DAE.Exp defaultMeasureTime       = DAE.BCONST(false)   "time measurement disabled by default";
public constant DAE.Exp defaultCflags            = DAE.SCONST("")      "default compiler flags";
public constant DAE.Exp defaultSimflags          = DAE.SCONST("")      "default simulation flags";

public constant SimulationOptions defaultSimulationOptions =
  SIMULATION_OPTIONS(
    defaultStartTime,
    defaultStopTime,
    defaultNumberOfIntervals,
    defaultStepSize,
    defaultTolerance,
    defaultMethod,    
    defaultFileNamePrefix,
    defaultStoreInTemp,
    defaultNoClean,
    defaultOptions,
    defaultOutputFormat,
    defaultVariableFilter,
    defaultMeasureTime,
    defaultCflags,
    defaultSimflags
    ) "default simulation options";
    
public constant list<String> simulationOptionsNames =
  {
    "startTime",
    "stopTime",
    "numberOfIntervals",
    "tolerance",
    "method",
    "fileNamePrefix",
    "storeInTemp",    
    "noClean",
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
  Boolean isTestType;
algorithm
  resultValues := listReverse(inAddResultValues);
  //TODO: maybe we should test if the fields are the ones in simulationResultType_full
  fields := Util.if_(Config.getRunningTestsuite(), {},
                     List.map(resultValues, Util.tuple21));
  vals := Util.if_(Config.getRunningTestsuite(), {}, 
                   List.map(resultValues, Util.tuple22));
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
  input Env.Cache inCache;
  input Env.Env env;
  input String inputFilename;
  input Interactive.SymbolTable st;
  input Ceval.Msg msg;
  output Env.Cache outCache;
  output String filename;
algorithm
  (outCache,filename) := match (inCache,env,inputFilename,st,msg)
    local Env.Cache cache;
    case (cache,_,"<default>",_,_)
      equation
        (cache,Values.STRING(filename),_) = Ceval.ceval(cache,env,buildCurrentSimulationResultExp(),true,SOME(st),msg);
      then (cache,filename);
    else (inCache,inputFilename);
  end match;
end cevalCurrentSimulationResultExp;

public function getSimulationOption
"@author: adrpo
  get the value from simulation option"
  input SimulationOptions inSimOpt;
  input String optionName;
  output DAE.Exp outOptionValue;
algorithm
  outOptionValue := matchcontinue(inSimOpt, optionName)
    local
      DAE.Exp e; String name, msg;
    
    case (SIMULATION_OPTIONS(startTime = e),         "startTime")         then e;
    case (SIMULATION_OPTIONS(stopTime = e),          "stopTime")          then e;
    case (SIMULATION_OPTIONS(numberOfIntervals = e), "numberOfIntervals") then e;
    case (SIMULATION_OPTIONS(stepSize = e),          "stepSize")          then e;
    case (SIMULATION_OPTIONS(tolerance = e),         "tolerance")         then e;
    case (SIMULATION_OPTIONS(method = e),            "method")            then e;
    case (SIMULATION_OPTIONS(fileNamePrefix = e),    "fileNamePrefix")    then e;
    case (SIMULATION_OPTIONS(storeInTemp = e),       "storeInTemp")       then e;
    case (SIMULATION_OPTIONS(options = e),           "options")           then e;
    case (SIMULATION_OPTIONS(noClean = e),           "noClean")           then e;
    case (SIMULATION_OPTIONS(outputFormat = e),      "outputFormat")      then e;
    case (SIMULATION_OPTIONS(variableFilter = e),    "variableFilter")    then e;
    case (SIMULATION_OPTIONS(measureTime = e),       "measureTime")       then e;
    case (SIMULATION_OPTIONS(cflags = e),            "cflags")            then e;
    case (SIMULATION_OPTIONS(simflags = e),          "simflags")          then e;
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
  input Interactive.SymbolTable inSymTab;
  input Absyn.Path inModelPath;
  input String inFileNamePrefix;
  output SimulationOptions outSimOpt;
algorithm
  outSimOpt := matchcontinue (inSymTab, inModelPath, inFileNamePrefix)
    local
      SimulationOptions defaults, simOpt,methodbyflag;
      String experimentAnnotationStr;
      list<Absyn.NamedArg> named;
      String msg;
      Boolean methodflag;
    
    // search inside annotation(experiment(...))
    case (inSymTab, inModelPath, inFileNamePrefix)
      equation
        defaults = setFileNamePrefixInSimulationOptions(defaultSimulationOptions, inFileNamePrefix);
        
        experimentAnnotationStr = 
          Interactive.getNamedAnnotation(
            inModelPath, 
            Interactive.getSymbolTableAST(inSymTab), 
            "experiment", 
            SOME("{}"),
            Interactive.getExperimentAnnotationString);
                // parse the string we get back, either {} or {StopTime=5, Tolerance = 0.10};
        
        // jump to next case if the annotation is empty  
        false = stringEq(experimentAnnotationStr, "{}");
        
        // get rid of '{' and '}'
        experimentAnnotationStr = System.stringReplace(experimentAnnotationStr, "{", "");
        experimentAnnotationStr = System.stringReplace(experimentAnnotationStr, "}", "");
        
        Interactive.ISTMTS({Interactive.IEXP(exp = Absyn.CALL(functionArgs = Absyn.FUNCTIONARGS(_, named)))}, _)
        = Parser.parsestringexp("experiment(" +& experimentAnnotationStr +& ");\n", "<experiment>");
        
        simOpt = populateSimulationOptions(defaults, named);
      then
        simOpt;

    // if we fail, just use the defaults
    case (inSymTab, inModelPath, inFileNamePrefix)
      equation
        defaults = setFileNamePrefixInSimulationOptions(defaultSimulationOptions, inFileNamePrefix);
      then
        defaults;
  end matchcontinue;
end buildSimulationOptionsFromModelExperimentAnnotation;

protected function setFileNamePrefixInSimulationOptions
  input  SimulationOptions inSimOpt;
  input  String inFileNamePrefix;
  output SimulationOptions outSimOpt;
protected
  DAE.Exp startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime, cflags, simflags;
algorithm
  SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, _, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime, cflags, simflags) := inSimOpt;
  outSimOpt := SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, DAE.SCONST(inFileNamePrefix), storeInTemp, noClean, options, outputFormat, variableFilter, measureTime, cflags, simflags);
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
    
    case (Absyn.INTEGER(i), DAE.T_INTEGER(source = _))  then DAE.ICONST(i);
    case (Absyn.REAL(r),    DAE.T_REAL(source = _)) then DAE.RCONST(r);
        
    case (Absyn.INTEGER(i), DAE.T_REAL(source = _)) equation r = intReal(i); then DAE.RCONST(r);
    case (Absyn.REAL(r),    DAE.T_INTEGER(source = _))  equation i = realInt(r); then DAE.ICONST(i);
    
    case (exp,    _)  
      equation 
        print("CevalScript.getConst: Not handled exp: " +& Dump.printExpStr(exp) +& "\n");
      then 
        fail();
  end matchcontinue;
end getConst;

protected function populateSimulationOptions
"@auhtor: adrpo
  populate simulation options"
  input SimulationOptions inSimOpt;
  input list<Absyn.NamedArg> inExperimentSettings;
  output SimulationOptions outSimOpt;
algorithm
  outSimOpt := matchcontinue(inSimOpt, inExperimentSettings)
    local
      Absyn.Exp exp;
      list<Absyn.NamedArg> rest;
      SimulationOptions simOpt;
      DAE.Exp startTime;
      DAE.Exp stopTime;
      DAE.Exp numberOfIntervals;
      DAE.Exp stepSize;
      DAE.Exp tolerance;
      DAE.Exp method;
      DAE.Exp fileNamePrefix;
      DAE.Exp storeInTemp;
      DAE.Exp noClean;
      DAE.Exp options;
      DAE.Exp outputFormat;
      DAE.Exp variableFilter, measureTime, cflags, simflags;
      Real rStepSize, rStopTime, rStartTime;
      Integer iNumberOfIntervals;
      String name,msg;
      
    case (inSimOpt, {}) then inSimOpt;
    
    case (SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime, cflags, simflags), 
          Absyn.NAMEDARG(argName = "Tolerance", argValue = exp)::rest)
      equation
        tolerance = getConst(exp, DAE.T_REAL_DEFAULT);
        simOpt = populateSimulationOptions(
          SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,storeInTemp,noClean,options,outputFormat,variableFilter,measureTime,cflags,simflags),
             rest);
      then
        simOpt;
    
    case (SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime, cflags, simflags), 
          Absyn.NAMEDARG(argName = "StartTime", argValue = exp)::rest)
      equation
        startTime = getConst(exp, DAE.T_REAL_DEFAULT);
        simOpt = populateSimulationOptions(
          SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,storeInTemp,noClean,options,outputFormat,variableFilter,measureTime,cflags,simflags),
             rest);
      then
        simOpt;

    case (SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime, cflags, simflags), 
          Absyn.NAMEDARG(argName = "StopTime", argValue = exp)::rest)
      equation
        stopTime = getConst(exp, DAE.T_REAL_DEFAULT);
        simOpt = populateSimulationOptions(
          SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,storeInTemp,noClean,options,outputFormat,variableFilter,measureTime,cflags,simflags),
             rest);
      then
        simOpt;

    case (SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime, cflags, simflags), 
          Absyn.NAMEDARG(argName = "NumberOfIntervals", argValue = exp)::rest)
      equation
        numberOfIntervals = getConst(exp, DAE.T_INTEGER_DEFAULT);
        simOpt = populateSimulationOptions(
          SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,storeInTemp,noClean,options,outputFormat,variableFilter,measureTime,cflags,simflags),
             rest);
      then
        simOpt;

    case (SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime, cflags, simflags), 
          Absyn.NAMEDARG(argName = "Interval", argValue = exp)::rest)
      equation
        DAE.RCONST(rStepSize) = getConst(exp, DAE.T_REAL_DEFAULT);
        // a bit different for Interval, handle it LAST!!!!
        SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                           fileNamePrefix,storeInTemp,noClean,options,outputFormat,variableFilter,measureTime,cflags,simflags) = 
          populateSimulationOptions(inSimOpt, rest);
       
       DAE.RCONST(rStartTime) = startTime;
       DAE.RCONST(rStopTime) = stopTime;
       iNumberOfIntervals = realInt(realDiv(realSub(rStopTime, rStartTime), rStepSize));
       
       numberOfIntervals = DAE.ICONST(iNumberOfIntervals);
       stepSize = DAE.RCONST(rStepSize);
       
       simOpt = SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                                   fileNamePrefix,storeInTemp,noClean,options,outputFormat,variableFilter,measureTime,cflags,simflags);
      then
        simOpt;

    case (SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime, cflags, simflags), 
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
    case ((path,strings)::modelsToLoad,modelicaPath,p,forceLoad,notifyLoad)
      equation
        b = checkModelLoaded((path,strings),p,forceLoad,NONE());
        pnew = Debug.bcallret3(not b, ClassLoader.loadClass, path, strings, modelicaPath, Absyn.PROGRAM({},Absyn.TOP(),Absyn.dummyTimeStamp));
        className = Absyn.pathString(path);
        version = Debug.bcallret2(not b, getPackageVersion, path, pnew, "");
        Error.assertionOrAddSourceMessage(b or not notifyLoad,Error.NOTIFY_NOT_LOADED,{className,version},Absyn.dummyInfo);
        p = Interactive.updateProgram(pnew, p);
        (p,b1) = loadModel(Interactive.getUsesAnnotationOrDefault(pnew),modelicaPath,p,false,notifyLoad);
        (p,b2) = loadModel(modelsToLoad,modelicaPath,p,forceLoad,notifyLoad);
      then (p,b1 and b2);
    case ((path,strings)::_,modelicaPath,p,_,_)
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
      list<String> validVersions;

    case (_,_,true,_) then false;
    case ((path,str1::_),p,false,_)
      equation
        cdef = Interactive.getPathedClassInProgram(path,p);
        ostr2 = Interactive.getNamedAnnotationInClass(cdef,"version",Interactive.getAnnotationStringValueOrFail);
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
    case (path,str1,SOME(str2))
      equation
        pathStr = Absyn.pathString(path);
        Error.addMessage(Error.LOAD_MODEL_DIFFERENT_VERSIONS,{pathStr,str1,str2});
      then ();
    case (path,str1,NONE())
      equation
        pathStr = Absyn.pathString(path);
        Error.addMessage(Error.LOAD_MODEL_DIFFERENT_VERSIONS,{pathStr,str1,"unknown"});
      then ();
  end matchcontinue;
end checkValidVersion;

public function cevalInteractiveFunctions
"function cevalInteractiveFunctions
  This function evaluates the functions
  defined in the interactive environment."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp "expression to evaluate";
  input Interactive.SymbolTable inSymbolTable;
  input Ceval.Msg msg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable) := matchcontinue (inCache,inEnv,inExp,inSymbolTable,msg)
    local
      Env.Cache cache;
      Env.Env env;
      DAE.Exp exp;      
      list<DAE.Exp> eLst;
      list<Values.Value> valLst;
      String name;
      Values.Value value;
      Real t1,t2,time;
      Interactive.SymbolTable st;
      Option<Interactive.SymbolTable> stOpt;
      
      // This needs to be first because otherwise it takes 0 time to get the value :)
    case (cache,env,DAE.CALL(path = Absyn.IDENT(name = "timing"),expLst = {exp}),st,msg)
      equation
        t1 = System.time();
        (cache,value,SOME(st)) = Ceval.ceval(cache,env, exp, true, SOME(st),msg);
        t2 = System.time();
        time = t2 -. t1;
      then
        (cache,Values.REAL(time),st);

    case (cache,env,DAE.CALL(path=Absyn.IDENT(name),attr=DAE.CALL_ATTR(builtin=true),expLst=eLst),st,msg)
      equation
        (cache,valLst,stOpt) = Ceval.cevalList(cache,env,eLst,true,SOME(st),msg);
        valLst = List.map1(valLst,evalCodeTypeName,env);
        st = Util.getOptionOrDefault(stOpt, st);
        (cache,value,st) = cevalInteractiveFunctions2(cache,env,name,valLst,st,msg);
      then 
        (cache,value,st);

  end matchcontinue;
end cevalInteractiveFunctions;

protected function cevalInteractiveFunctions2
"function cevalInteractiveFunctions
  This function evaluates the functions
  defined in the interactive environment."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input String inFunctionName;
  input list<Values.Value> inVals;
  input Interactive.SymbolTable inSt;
  input Ceval.Msg msg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable) := matchcontinue (inCache,inEnv,inFunctionName,inVals,inSt,msg)
    local
      String omdev,functionName,simflags,s1,str,str1,str2,str3,re,token,varid,cmd,executable,executable1,encoding,method_str,
             outputFormat_str,initfilename,cit,pd,executableSuffixedExe,sim_call,result_file,filename_1,filename,omhome_1,
             plotCmd,tmpPlotFile,call,str_1,mp,pathstr,name,cname,fileNamePrefix_s,errMsg,errorStr,uniqueStr,interpolation,
             title,xLabel,yLabel,filename2,varNameStr,xml_filename,xml_contents,visvar_str,pwd,omhome,omlib,omcpath,os,
             platform,usercflags,senddata,res,workdir,gcc,confcmd,touch_file,uname,filenameprefix,compileDir,from,to,
             legendStr, gridStr, logXStr, logYStr, x1Str, x2Str, y1Str, y2Str;
      list<Values.Value> vals;
      Absyn.Path path,p1,classpath,className;
      SCode.Program scodeP,sp;
      Option<list<SCode.Element>> fp;
      list<Env.Frame> env;
      SCode.Element c; 
      DAE.ComponentRef cr,cref,classname;
      Interactive.SymbolTable newst,st_1,st;
      Absyn.Program p,pnew,newp,ptot;
      list<Interactive.InstantiatedClass> ic,ic_1;
      list<Interactive.Variable> iv;
      list<Interactive.CompiledCFunction> cf;
      DAE.Type tp;
      Absyn.Class absynClass;
      Absyn.ClassDef cdef;
      DAE.DAElist dae;
      BackendDAE.BackendDAE daelow,optdae;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqnarr;
      array<BackendDAE.MultiDimEquation> ae;
      array<BackendDAE.ComplexEquation> ce;
      list<DAE.Exp> expVars,options;
      array<list<Integer>> m,mt;
      Option<array<list<Integer>>> om,omt;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      Values.Value ret_val,simValue,size_value,value,v,cvar,cvar2,xRange,yRange,xRange1,xRange2,yRange1,yRange2;
      DAE.Exp exp,size_expression,bool_exp,storeInTemp,translationLevel,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,varName,varTimeStamp;
      Absyn.ComponentRef cr_1;
      Absyn.Restriction restriction;
      Integer size,length,resI,timeStampI,i,n;
      list<String> vars_1,vars_2,args,strings,strVars,strs,visvars;
      Real t1,t2,time,timeTotal,timeSimulation,timeStamp,val,x1,x2,y1,y2,r;
      Interactive.Statements istmts; 
      Boolean bval, b, b1, b2, externalWindow, legend, grid, logX, logY, points, gcc_res, omcfound, rm_res, touch_res, uname_res, extended, insensitive,ifcpp, sort, builtin, showProtected;
      Env.Cache cache;
      list<Interactive.LoadedFile> lf;
      AbsynDep.Depends aDep;
      Absyn.ComponentRef crefCName;
      list<tuple<String,Values.Value>> resultValues;
      list<Real> timeStamps,realVals;
      list<DAE.Exp> expLst;
      list<tuple<String,list<String>>> deps;
      Absyn.CodeNode codeNode;
      list<Values.Value> cvars,vals2;
      DAE.FunctionTree funcs;
      list<Absyn.Path> paths;
      list<Absyn.Class> classes;
      Absyn.Within within_;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      SimCode.SimulationSettings simSettings;
      list<tuple<Absyn.Path,list<String>>> usedModels;
      Absyn.Info info;
    
    case (cache,env,"parseString",{Values.STRING(str1),Values.STRING(str2)},st,msg)
      equation
        Absyn.PROGRAM(classes=classes,within_=within_) = Parser.parsestring(str1,str2);
        paths = List.map(classes,Absyn.className);
        paths = List.map1r(paths,Absyn.joinWithinPath,within_);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"parseString",_,st,msg)
      then (cache,ValuesUtil.makeArray({}),st);

    case (cache,env,"parseFile",{Values.STRING(str1),Values.STRING(encoding)},st,msg)
      equation
        // clear the errors before!
        Error.clearMessages() "Clear messages";
        Print.clearErrorBuf() "Clear error buffer";
        (paths, st) = Interactive.parseFile(str1, encoding, st);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"loadFileInteractiveQualified",{Values.STRING(str1),Values.STRING(encoding)},st,msg)
      equation
        // clear the errors before!
        Error.clearMessages() "Clear messages";
        Print.clearErrorBuf() "Clear error buffer";
        (paths, st) = Interactive.loadFileInteractiveQualified(str1, encoding, st);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"loadFileInteractive",{Values.STRING(str1),Values.STRING(encoding)},st as Interactive.SYMBOLTABLE(ast=p),msg)
      equation
        pnew = ClassLoader.loadFile(str1,encoding) "System.regularFileExists(name) => 0 &    Parser.parse(name) => p1 &" ;
        vals = List.map(Interactive.getTopClassnames(pnew),ValuesUtil.makeCodeTypeName);
        p = Interactive.updateProgram(pnew, p);
        st = Interactive.setSymbolTableAST(st, p);
      then (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"getSourceFile",{Values.CODE(Absyn.C_TYPENAME(path))},st as Interactive.SYMBOLTABLE(ast=p),msg)
      equation
        str = Interactive.getSourceFile(path, p);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"setSourceFile",{Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str)},st as Interactive.SYMBOLTABLE(ast=p),msg)
      equation
        (b,p) = Interactive.setSourceFile(path, str, p);
        st = Interactive.setSymbolTableAST(st,p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"setClassComment",{Values.CODE(Absyn.C_TYPENAME(path)),Values.STRING(str)},st as Interactive.SYMBOLTABLE(ast=p),msg)
      equation
        (p,b) = Interactive.setClassComment(path, str, p);
        st = Interactive.setSymbolTableAST(st, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache, env, "isShortDefinition", {Values.CODE(Absyn.C_TYPENAME(path))}, st as Interactive.SYMBOLTABLE(ast = p), msg)
      equation
        b = isShortDefinition(path, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"getClassNames",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("AllLoadedClasses"))),Values.BOOL(false),_,Values.BOOL(sort),Values.BOOL(builtin),Values.BOOL(showProtected)},st as Interactive.SYMBOLTABLE(ast = p),msg)
      equation
        p = Debug.bcallret2(builtin,Interactive.updateProgram,p,Builtin.getInitialFunctions(),p);
        paths = Interactive.getTopClassnames(p);
        paths = Debug.bcallret2(sort, List.sort, paths, Absyn.pathGe, paths);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"getClassNames",{Values.CODE(Absyn.C_TYPENAME(path)),Values.BOOL(false),Values.BOOL(b),Values.BOOL(sort),Values.BOOL(builtin),Values.BOOL(showProtected)},st as Interactive.SYMBOLTABLE(ast = p),msg)
      equation
        p = Debug.bcallret2(builtin,Interactive.updateProgram,p,Builtin.getInitialFunctions(),p);
        paths = Interactive.getClassnamesInPath(path, p, showProtected);
        paths = Debug.bcallret3(b,List.map1r,paths,Absyn.joinPaths,path,paths);
        paths = Debug.bcallret2(sort, List.sort, paths, Absyn.pathGe, paths);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"getClassNames",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("AllLoadedClasses"))),Values.BOOL(true),_,Values.BOOL(sort),Values.BOOL(builtin),Values.BOOL(showProtected)},st as Interactive.SYMBOLTABLE(ast = p),msg)
      equation
        p = Debug.bcallret2(builtin,Interactive.updateProgram,p,Builtin.getInitialFunctions(),p);
        (_,paths) = Interactive.getClassNamesRecursive(NONE(),p,showProtected,{});
        paths = listReverse(paths);
        paths = Debug.bcallret2(sort, List.sort, paths, Absyn.pathGe, paths);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"getClassNames",{Values.CODE(Absyn.C_TYPENAME(path)),Values.BOOL(true),_,Values.BOOL(sort),Values.BOOL(builtin),Values.BOOL(showProtected)},st as Interactive.SYMBOLTABLE(ast = p),msg)
      equation
        p = Debug.bcallret2(builtin,Interactive.updateProgram,p,Builtin.getInitialFunctions(),p);
        (_,paths) = Interactive.getClassNamesRecursive(SOME(path),p,showProtected,{});
        paths = listReverse(paths);
        paths = Debug.bcallret2(sort, List.sort, paths, Absyn.pathGe, paths);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals),st);
        
    case (cache,env,"getClassComment",{Values.CODE(Absyn.C_TYPENAME(path))},st as Interactive.SYMBOLTABLE(ast = p),msg)
      equation
        Absyn.CLASS(_,_,_,_,_,cdef,_) = Interactive.getPathedClassInProgram(path, p);
        str = Interactive.getClassComment(cdef);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"getClassComment",{Values.CODE(Absyn.C_TYPENAME(path))},st as Interactive.SYMBOLTABLE(ast = p),msg)
      then
        (cache,Values.STRING(""),st);

    case (cache,env,"getPackages",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("AllLoadedClasses")))},st as Interactive.SYMBOLTABLE(ast = p),msg)
      equation
        paths = Interactive.getTopPackages(p);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    case (cache,env,"getPackages",{Values.CODE(Absyn.C_TYPENAME(path))},st as Interactive.SYMBOLTABLE(ast = p),msg)
      equation
        paths = Interactive.getPackagesInPath(path, p);
        vals = List.map(paths,ValuesUtil.makeCodeTypeName);
      then
        (cache,ValuesUtil.makeArray(vals),st);

    /* Does not exist in the env...
    case (cache,env,"lookupClass",{Values.CODE(Absyn.C_TYPENAME(path))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        ptot = Dependency.getTotalProgram(path,p);
        scodeP = SCodeUtil.translateAbsyn2SCode(ptot);
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
     
    case (cache,env,"basename",{Values.STRING(str)},st,msg)
      equation
        str = System.basename(str);
      then (cache,Values.STRING(str),st);
    
    case (cache,env,"dirname",{Values.STRING(str)},st,msg)
      equation
        str = System.dirname(str);
      then (cache,Values.STRING(str),st);
    
    case (cache,env,"codeToString",{Values.CODE(codeNode)},st,msg)
      equation
        str = Dump.printCodeStr(codeNode);
      then (cache,Values.STRING(str),st);
    
    case (cache,env,"typeOf",{Values.CODE(Absyn.C_VARIABLENAME(Absyn.CREF_IDENT(name = varid)))},(st as Interactive.SYMBOLTABLE(lstVarVal = iv)),msg)
      equation
        tp = Interactive.getTypeOfVariable(varid, iv);
        str = Types.unparseType(tp);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,"clear",{},st,msg)
      then (cache,Values.BOOL(true),Interactive.emptySymboltable);
    
    case (cache,env,"clearVariables",{},
        (st as Interactive.SYMBOLTABLE(
          ast = p,
          depends = aDep,
          explodedAst = fp,
          instClsLst = ic,
          compiledFunctions = cf,
          loadedFiles = lf)),msg)
      equation
        newst = Interactive.SYMBOLTABLE(p,aDep,fp,ic,{},cf,lf);
      then
        (cache,Values.BOOL(true),newst);
        
    // Note: This is not the environment caches, passed here as cache, but instead the cached instantiated classes.
    case (cache,env,"clearCache",{},
        (st as Interactive.SYMBOLTABLE(
          ast = p,depends=aDep,explodedAst = fp,instClsLst = ic,
          lstVarVal = iv,compiledFunctions = cf,
          loadedFiles = lf)),msg)
      equation
        newst = Interactive.SYMBOLTABLE(p,aDep,fp,{},iv,cf,lf);
      then
        (cache,Values.BOOL(true),newst);
    
    case (cache,env,"regex",{Values.STRING(str),Values.STRING(re),Values.INTEGER(i),Values.BOOL(extended),Values.BOOL(insensitive)},st,msg)
      equation
        (n,strs) = System.regex(str,re,i,extended,insensitive);
        vals = List.map(strs,ValuesUtil.makeString);
        v = Values.ARRAY(vals,{i});
      then
        (cache,Values.TUPLE({Values.INTEGER(n),v}),st);

    case (cache,env,"regex",{Values.STRING(str),Values.STRING(re),Values.INTEGER(i),Values.BOOL(extended),Values.BOOL(insensitive)},st,msg)
      equation
        strs = List.fill("",i);
        vals = List.map(strs,ValuesUtil.makeString);
        v = Values.ARRAY(vals,{i});
      then
        (cache,Values.TUPLE({Values.INTEGER(-1),v}),st);

    case (cache,env,"list",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("AllLoadedClasses"))),Values.BOOL(false),Values.BOOL(false)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        str = Dump.unparseStr(p,false);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,"list",{Values.CODE(Absyn.C_TYPENAME(path)),Values.BOOL(b1),Values.BOOL(b2)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        absynClass = Debug.bcallret1(b1,Absyn.getFunctionInterface,absynClass,absynClass);
        absynClass = Debug.bcallret1(b2,Absyn.getShortClass,absynClass,absynClass);
        str = Dump.unparseStr(Absyn.PROGRAM({absynClass},Absyn.TOP(),Absyn.TIMESTAMP(0.0,0.0)),false) ;
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,"list",_,st,msg) then (cache,Values.STRING(""),st);
    
    case (cache,env,"listVariables",{},st as Interactive.SYMBOLTABLE(lstVarVal = iv),msg)
      equation
        v = ValuesUtil.makeArray(getVariableNames(iv,{}));
      then
        (cache,v,st);

    case (cache,env,"jacobian",{Values.CODE(Absyn.C_TYPENAME(path))},
          (st as Interactive.SYMBOLTABLE(
            ast = p,depends=aDep,explodedAst = fp,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),msg)
      equation
        ptot = Dependency.getTotalProgram(path,p);
        scodeP = SCodeUtil.translateAbsyn2SCode(ptot);
        (cache, env, _, dae) = Inst.instantiateClass(cache, InnerOuter.emptyInstHierarchy, scodeP, path);
        dae  = DAEUtil.transformationsBeforeBackend(cache,env,dae);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(path,dae,env));
        funcs = Env.getFunctionTree(cache);
        daelow = BackendDAECreate.lower(dae, funcs, false) "no dummy state" ;
        (optdae as BackendDAE.DAE({syst},shared)) = BackendDAEUtil.preOptimiseBackendDAE(daelow,NONE());
        (syst,m,mt) = BackendDAEUtil.getIncidenceMatrixfromOption(syst,shared,BackendDAE.NORMAL());
        vars = BackendVariable.daeVars(syst);
        eqnarr = BackendEquation.daeEqns(syst);
        ae = BackendEquation.daeArrayEqns(optdae);
        ce = BackendEquation.daeComplexEqns(optdae);
        jac = BackendDAEUtil.calculateJacobian(vars, eqnarr, ae, ce, m, mt,false);
        res = BackendDump.dumpJacobianStr(jac);
      then
        (cache,Values.STRING(res),Interactive.SYMBOLTABLE(p,aDep,fp,ic_1,iv,cf,lf));
    
    case (cache,env,"translateModel",vals as {Values.CODE(Absyn.C_TYPENAME(className)),_,_,_,_,_,Values.STRING(filenameprefix),_,_,_,_,_,_,_,_},st,msg)
      equation
        (cache,simSettings) = calculateSimulationSettings(cache,env,vals,st,msg);
        (cache,ret_val,st_1,_,_,_,_) = translateModel(cache, env, className, st, filenameprefix, true, SOME(simSettings));
      then
        (cache,ret_val,st_1);
   
    case (cache,env,"translateModel",_,st,msg)
      then (cache,Values.STRING("There were errors during translation. Use getErrorString() to see them."),st);

    case (cache,env,"modelEquationsUC",vals as {Values.CODE(Absyn.C_TYPENAME(className)),_,_,_,_,_,Values.STRING(filenameprefix),_,_,_,_,_,_,_,_},st,msg)
      equation
        (cache,ret_val,st_1) = Uncertainties.modelEquationsUC(cache, env, className, st, filenameprefix);
      then
        (cache,ret_val,st_1);
   
    case (cache,env,"modelEquationsUC",_,st,msg)
      then (cache,Values.STRING("There were errors during extraction of uncertainty equations. Use getErrorString() to see them."),st);     

    /*case (cache,env,"translateModelCPP",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)},st,msg)
      equation
        (cache,ret_val,st_1,_,_,_,_) = translateModelCPP(cache,env, className, st, filenameprefix,true,NONE());
      then
        (cache,ret_val,st_1);*/
        
    case (cache,env,"translateModelFMU",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)},st,msg)
      equation
        filenameprefix = Util.stringReplaceChar(filenameprefix,".","_");
        (cache,ret_val,st_1) = translateModelFMU(cache, env, className, st, filenameprefix, true, NONE());
      then
        (cache,ret_val,st_1);
    
    case (cache,env,"exportDAEtoMatlab",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)},st,msg)
      equation
        (cache,ret_val,st_1,_) = getIncidenceMatrix(cache,env, className, st, msg, filenameprefix);
      then
        (cache,ret_val,st_1);
    
    case (cache,env,"checkModel",{Values.CODE(Absyn.C_TYPENAME(className))},st,msg)
      equation
        Flags.setConfigBool(Flags.CHECK_MODEL, true);
        (cache,ret_val,st_1) = checkModel(cache, env, className, st, msg);
        Flags.setConfigBool(Flags.CHECK_MODEL, false);
      then
        (cache,ret_val,st_1);
    
    case (cache,env,"checkAllModelsRecursive",{Values.CODE(Absyn.C_TYPENAME(className)),Values.BOOL(showProtected)},st,msg)
      equation
        (cache,ret_val,st_1) = checkAllModelsRecursive(cache, env, className, showProtected, st, msg);
      then
        (cache,ret_val,st_1);
    
    case (cache,env,"translateGraphics",{Values.CODE(Absyn.C_TYPENAME(className))},st,msg)
      equation
        (cache,ret_val,st_1) = translateGraphics(cache,env, className, st, msg);
      then
        (cache,ret_val,st_1);
    
    case (cache,env,"setCompileCommand",{Values.STRING(cmd)},st,msg)
      equation
        // cmd = Util.rawStringToInputString(cmd);
        Settings.setCompileCommand(cmd);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"getCompileCommand",{},st,msg)
      equation
        res = Settings.getCompileCommand();
      then
        (cache,Values.STRING(res),st);
        
    case (cache,env,"setPlotCommand",{Values.STRING(cmd)},st,msg)
      then
        (cache,Values.BOOL(false),st);
        
    case (cache,env,"setTempDirectoryPath",{Values.STRING(cmd)},st,msg)
      equation
        // cmd = Util.rawStringToInputString(cmd);
        Settings.setTempDirectoryPath(cmd);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"getTempDirectoryPath",{},st,msg)
      equation
        res = Settings.getTempDirectoryPath();
      then
        (cache,Values.STRING(res),st);
        
    case (cache,env,"setEnvironmentVar",{Values.STRING(varid),Values.STRING(str)},st,msg)
      equation
        b = 0 == System.setEnv(varid,str,true);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"getEnvironmentVar",{Values.STRING(varid)},st,msg)
      equation
        res = Util.makeValueOrDefault(System.readEnv, varid, "");
      then
        (cache,Values.STRING(res),st);

    case (cache,env,"setInstallationDirectoryPath",{Values.STRING(cmd)},st,msg)
      equation
        // cmd = Util.rawStringToInputString(cmd);
        Settings.setInstallationDirectoryPath(cmd);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"getInstallationDirectoryPath",{},st,msg)
      equation
        res = Settings.getInstallationDirectoryPath();
      then
        (cache,Values.STRING(res),st);
        
    case (cache,env,"getModelicaPath",{},st,msg)
      equation
        res = Settings.getModelicaPath();
      then
        (cache,Values.STRING(res),st);
        
    case (cache,env,"setModelicaPath",{Values.STRING(cmd)},st,msg)
      equation
        // cmd = Util.rawStringToInputString(cmd);
        Settings.setModelicaPath(cmd);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"setModelicaPath",_,st,msg)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"getAnnotationVersion",{},st,msg)
      equation
        res = Config.getAnnotationVersion();
      then
        (cache,Values.STRING(res),st);

    case (cache,env,"getNoSimplify",{},st,msg)
      equation
        b = Config.getNoSimplify();
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"setNoSimplify",{Values.BOOL(b)},st,msg)
      equation
        Config.setNoSimplify(b);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"getShowAnnotations",{},st,msg)
      equation
        b = Config.showAnnotations();
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"setShowAnnotations",{Values.BOOL(b)},st,msg)
      equation
        Config.setShowAnnotations(b);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"getVectorizationLimit",{},st,msg)
      equation
        i = Config.vectorizationLimit();
      then
        (cache,Values.INTEGER(i),st);

    case (cache,env,"getOrderConnections",{},st,msg)
      equation
        b = Config.orderConnections();
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"getLanguageStandard",{},st,msg)
      equation
        res = Config.languageStandardString(Config.getLanguageStandard());
      then
        (cache,Values.STRING(res),st);

    case (cache,env,"buildModel",vals,st,msg)
      equation
        List.map_0(buildModelClocks,System.realtimeClear);
        System.realtimeTick(RT_CLOCK_SIMULATE_TOTAL);
        (cache,st,compileDir,executable,method_str,outputFormat_str,initfilename,_,_) = buildModel(cache,env, vals, st, msg);
        executable = Util.if_(not Config.getRunningTestsuite(),compileDir +& executable,executable);
      then
        (cache,ValuesUtil.makeArray({Values.STRING(executable),Values.STRING(initfilename)}),st);
        
    case (cache,env,"buildModel",_,st,msg) /* failing build_model */
      then (cache,ValuesUtil.makeArray({Values.STRING(""),Values.STRING("")}),st);
        
    case (cache,env,"buildModelBeast",vals,st,msg)
      equation
        (cache,st,compileDir,executable,method_str,initfilename) = buildModelBeast(cache,env,vals,st,msg);
        executable = Util.if_(not Config.getRunningTestsuite(),compileDir +& executable,executable);
      then
        (cache,ValuesUtil.makeArray({Values.STRING(executable),Values.STRING(initfilename)}),st);
    
    // Remove output.log before simulate in case it already exists. 
    // This is so we can check for the presence of output.log later.
    case (cache,env,"simulate",vals,st,msg)
      equation
        true = System.regularFileExists("output.log");
        false = 0 == System.removeFile("output.log");
        simValue = createSimulationResultFailure("Failed to remove existing file output.log", simOptionsAsString(vals));
      then (cache,simValue,st);
        
    // adrpo: see if the model exists before simulation!
    case (cache,env,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,st as Interactive.SYMBOLTABLE(ast = p),msg)
      equation
        crefCName = Absyn.pathToCref(className);
        false = Interactive.existClass(crefCName, p);
        errMsg = "Simulation Failed. Model: " +& Absyn.pathString(className) +& " does not exists! Please load it first before simulation.";
        simValue = createSimulationResultFailure(errMsg, simOptionsAsString(vals));
      then
        (cache,simValue,st);
        
    case (cache,env,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,st_1,msg)
      equation
        System.realtimeTick(RT_CLOCK_SIMULATE_TOTAL);
        (cache,st,compileDir,executable,method_str,outputFormat_str,_,simflags,resultValues) = buildModel(cache,env,vals,st_1,msg);
        
        cit = winCitation();
        ifcpp=Util.equal(Config.simCodeTarget(),"Cpp");
        executable1=Util.if_(ifcpp,"Simulation",executable);
        executableSuffixedExe = stringAppend(executable1, System.getExeExt());
        // sim_call = stringAppendList({"sh -c ",cit,"ulimit -t 60; ",cit,pwd,pd,executableSuffixedExe,cit," > output.log 2>&1",cit});
        sim_call = stringAppendList({cit,compileDir,executableSuffixedExe,cit," ",simflags," > output.log 2>&1"});
        System.realtimeTick(RT_CLOCK_SIMULATE_SIMULATION);
        SimulationResults.close() "Windows cannot handle reading and writing to the same file from different processes like any real OS :(";
        0 = System.systemCall(sim_call);
        
        result_file = stringAppendList(List.consOnTrue(not Config.getRunningTestsuite(),compileDir,{executable,"_res.",outputFormat_str}));
        timeSimulation = System.realtimeTock(RT_CLOCK_SIMULATE_SIMULATION);
        timeTotal = System.realtimeTock(RT_CLOCK_SIMULATE_TOTAL);
        simValue = createSimulationResult(
           result_file, 
           simOptionsAsString(vals), 
           System.readFile("output.log"),
           ("timeTotal", Values.REAL(timeTotal)) :: 
           ("timeSimulation", Values.REAL(timeSimulation)) ::
          resultValues);
        newst = Interactive.addVarToSymboltable("currentSimulationResult", Values.STRING(result_file), DAE.T_STRING_DEFAULT, st);
      then
        (cache,simValue,newst);
        
    case (cache,env,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,st,msg)
      equation
        true = System.regularFileExists("output.log");
        res = System.readFile("output.log");
        str = Absyn.pathString(className);
        res = stringAppendList({"Simulation execution failed for model: ", str, "\n", res});
        simValue = createSimulationResultFailure(res, simOptionsAsString(vals));
      then
        (cache,simValue,st);

    case (cache,env,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,st,msg)
      equation
        omhome = Settings.getInstallationDirectoryPath() "simulation fail for some other reason than OPENMODELICAHOME not being set." ;
        errorStr = Error.printMessagesStr();
        str = Absyn.pathString(className);
        res = stringAppendList({"Simulation failed for model: ", str, "\n", errorStr});
        simValue = createSimulationResultFailure(res, simOptionsAsString(vals));
      then
        (cache,simValue,st);
        
    case (cache,env,"simulate",vals as Values.CODE(Absyn.C_TYPENAME(className))::_,st,msg)
      equation
        str = Absyn.pathString(className);
        simValue = createSimulationResultFailure(
          "Simulation failed for model: " +& str +& 
          "\nEnvironment variable OPENMODELICAHOME not set.", 
          simOptionsAsString(vals));
      then
        (cache,simValue,st);
        
    case (cache,env,"instantiateModel",{Values.CODE(Absyn.C_TYPENAME(className))},st,msg)
      equation
        (cache,env,dae,st) = runFrontEnd(cache,env,className,st,true);
        str = DAEDump.dumpStr(dae,Env.getFunctionTree(cache));
      then
        (cache,Values.STRING(str),st);
        
    case (cache,env,"instantiateModel",{Values.CODE(Absyn.C_TYPENAME(className))},st as Interactive.SYMBOLTABLE(ast=p),msg)
      equation
        cr_1 = Absyn.pathToCref(className);
        false = Interactive.existClass(cr_1, p);
        str = "Unknown model in instantiateModel: " +& Absyn.pathString(className) +& "\n";
      then
        (cache,Values.STRING(str),st);
        
    case (cache,env,"instantiateModel",{Values.CODE(Absyn.C_TYPENAME(path))},st,msg)
      equation
        b = Error.getNumMessages() == 0;
        cname = Absyn.pathString(path);
        str = "Internal error, instantiation of " +& cname +& 
          " failed with no error message.";
        str = Util.if_(b, str, "");
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"reopenStandardStream",{Values.ENUM_LITERAL(index=i),Values.STRING(filename)},st,msg)
      equation
        b = System.reopenStandardStream(i-1,filename);
      then
        (cache,Values.BOOL(b),st);
    
    case (cache,env,"importFMU",{Values.STRING(filename),Values.STRING(workdir)},st,msg)
      equation
        // get OPENMODELICAHOME
        omhome = Settings.getInstallationDirectoryPath();
        // create the path till fmigenerator
        str = omhome +& "/bin/fmigenerator";
        workdir = Util.if_(System.directoryExists(workdir), workdir, System.pwd());
        // create the list of arguments for fmigenerator
        call = str +& " " +& "--fmufile=\"" +& filename +& "\" --outputdir=\"" +& workdir +& "\"";
        0 = System.systemCall(call);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"importFMU",_,st,msg)
      then
        (cache,Values.BOOL(false),st);
        
    case (cache,env,"iconv",{Values.STRING(str),Values.STRING(from),Values.STRING(to)},st,msg)
      equation
        str = System.iconv(str,from,to);
      then
        (cache,Values.STRING(str),st);
        
    case (cache,env,"setCompiler",{Values.STRING(str)},st,msg)
      equation
        System.setCCompiler(str);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"setCXXCompiler",{Values.STRING(str)},st,msg)
      equation
        System.setCXXCompiler(str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"setCompilerFlags",{Values.STRING(str)},st,msg)
      equation
        System.setCFlags(str);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"setLinker",{Values.STRING(str)},st,msg)
      equation
        System.setLinker(str);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"setLinkerFlags",{Values.STRING(str)},st,msg)
      equation
        System.setLDFlags(str);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"setCommandLineOptions",{Values.STRING(str)},st,msg)
      equation
        args = System.strtok(str, " ");
        _ = Flags.readArgs(args);
      then
        (Env.emptyCache(),Values.BOOL(true),st);
        
    case (cache,env,"setCommandLineOptions",_,st,msg)
      then (cache,Values.BOOL(false),st);
        
    case (cache,env,"cd",{Values.STRING("")},st,msg)
      equation
        str_1 = System.pwd();
      then
        (cache,Values.STRING(str_1),st);
        
    case (cache,env,"cd",{Values.STRING(str)},st,msg)
      equation
        resI = System.cd(str);
        (resI == 0) = true;
        str_1 = System.pwd();
      then
        (cache,Values.STRING(str_1),st);
        
    case (cache,env,"cd",{Values.STRING(str)},st,msg)
      equation
        failure(true = System.directoryExists(str));
        res = stringAppendList({"Error, directory ",str," does not exist,"});
      then
        (cache,Values.STRING(res),st);
        
    case (cache,env,"getVersion",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("OpenModelica")))},st,msg)
      equation
        str_1 = Settings.getVersionNr();
      then
        (cache,Values.STRING(str_1),st);
        
    case (cache,env,"getVersion",{Values.CODE(Absyn.C_TYPENAME(path))},st as Interactive.SYMBOLTABLE(ast=p),msg)
      equation
        str_1 = getPackageVersion(path,p);
      then
        (cache,Values.STRING(str_1),st);
        
    case (cache,env,"getTempDirectoryPath",{},st,msg)
      equation
        str_1 = Settings.getTempDirectoryPath();
      then
        (cache,Values.STRING(str_1),st);
        
    case (cache,env,"system",{Values.STRING(str)},st,msg)
      equation
        resI = System.systemCall(str);
      then
        (cache,Values.INTEGER(resI),st);
        
    case (cache,env,"timerClear",{Values.INTEGER(i)},st,msg)
      equation
        System.realtimeClear(i);
      then
        (cache,Values.NORETCALL(),st);

    case (cache,env,"timerTick",{Values.INTEGER(i)},st,msg)
      equation
        System.realtimeTick(i);
      then
        (cache,Values.NORETCALL(),st);

    case (cache,env,"timerTock",{Values.INTEGER(i)},st,msg)
      equation
        true = System.realtimeNtick(i) > 0;
        r = System.realtimeTock(i);
      then
        (cache,Values.REAL(r),st);

    case (cache,env,"timerTock",_,st,msg)
      then (cache,Values.REAL(-1.0),st);

    case (cache,env,"regularFileExists",{Values.STRING(str)},st,msg)
      equation
        b = System.regularFileExists(str);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"readFile",{Values.STRING(str)},st,msg)
      equation
        str_1 = System.readFile(str);
      then
        (cache,Values.STRING(str_1),st);
        
    case (cache,env,"writeFile",{Values.STRING(str),Values.STRING(str1),Values.BOOL(false)},st,msg)
      equation
        System.writeFile(str,str1);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"writeFile",{Values.STRING(str),Values.STRING(str1),Values.BOOL(true)},st,msg)
      equation
        System.appendFile(str, str1);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"writeFile",_,st,msg)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"readFileNoNumeric",{Values.STRING(str)},st,msg)
      equation
        str_1 = System.readFileNoNumeric(str);
      then
        (cache,Values.STRING(str_1),st);
        
    case (cache,env,"getErrorString",{},st,msg)
      equation
        str = Error.printMessagesStr();
      then
        (cache,Values.STRING(str),st);
        
    case (cache,env,"clearMessages",{},st,msg)
      equation
        Error.clearMessages();
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"getMessagesStringInternal",{},st,msg)
      equation
        v = ValuesUtil.makeArray(List.map(Error.getMessages(),errorToValue));
      then
        (cache,v,st);
        
    case (cache,env,"runScript",{Values.STRING(str)},st,msg)
      equation
        istmts = Parser.parseexp(str);
        (res,newst) = Interactive.evaluate(istmts, st, true);
      then
        (cache,Values.STRING(res),newst);
        
    case (cache,env,"runScript",_,st,msg)
    then (cache,Values.STRING("Failed"),st);
    
    case (cache,env,"typeNameString",{Values.CODE(A=Absyn.C_TYPENAME(path=path))},st,_)
      equation
        str = Absyn.pathString(path);
      then (cache,Values.STRING(str),st);

    case (cache,env,"typeNameStrings",{Values.CODE(A=Absyn.C_TYPENAME(path=path))},st,_)
      equation
        v = ValuesUtil.makeArray(List.map(Absyn.pathToStringList(path),ValuesUtil.makeString));
      then (cache,v,st);

    case (cache,env,"generateHeader",{Values.STRING(filename)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        str = Tpl.tplString(Unparsing.programExternalHeader, SCodeUtil.translateAbsyn2SCode(p));
        System.writeFile(filename,str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"generateHeader",_,st,msg)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"generateCode",{Values.CODE(Absyn.C_TYPENAME(path))},st,msg)
      equation
        (cache,Util.SUCCESS()) = Static.instantiateDaeFunction(cache, env, path, false, NONE(), true);
        (cache,_) = cevalGenerateFunction(cache,env,path);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"generateCode",_,st,msg)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"generateSeparateCode",{},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        sp = SCodeUtil.translateAbsyn2SCode(p);
        deps = generateFunctions(cache,env,sp,{});
      then (cache,Values.BOOL(true),st);

    case (cache,env,"generateSeparateCode",{},st,msg)
      then (cache,Values.BOOL(false),st);

    case (cache,env,"loadModel",{Values.CODE(Absyn.C_TYPENAME(path)),Values.ARRAY(valueLst=cvars),Values.BOOL(b)},
          (st as Interactive.SYMBOLTABLE(
            ast = p,depends=aDep,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),msg) /* add path to symboltable for compiled functions
            Interactive.SYMBOLTABLE(p,sp,ic,iv,(path,t)::cf),
            but where to get t? */
      equation
        mp = Settings.getModelicaPath();
        strings = List.map(cvars, ValuesUtil.extractValueString);
        (p,b) = loadModel({(path,strings)},mp,p,true,b);
        str = Print.getString();
        newst = Interactive.SYMBOLTABLE(p,aDep,NONE(),{},iv,cf,lf);
      then
        (Env.emptyCache(),Values.BOOL(b),newst);
        
    case (cache,env,"loadModel",Values.CODE(Absyn.C_TYPENAME(path))::_,st,msg)
      equation
        pathstr = Absyn.pathString(path);
        Error.addMessage(Error.LOAD_MODEL_ERROR, {pathstr});
      then
        (cache,Values.BOOL(false),st);
        
    case (cache,env,"loadFile",{Values.STRING(name),Values.STRING(encoding)},
          (st as Interactive.SYMBOLTABLE(
            ast = p,depends=aDep,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),msg)
      equation
        newp = ClassLoader.loadFile(name,encoding);
        newp = Interactive.updateProgram(newp, p);
      then
        (Env.emptyCache(),Values.BOOL(true),Interactive.SYMBOLTABLE(newp,aDep,NONE(),ic,iv,cf,lf));
        
    case (cache,env,"loadFile",_,st,msg)
      then (cache,Values.BOOL(false),st);
        
    case (cache,env,"loadString",{Values.STRING(str),Values.STRING(name),Values.STRING(encoding)},
          (st as Interactive.SYMBOLTABLE(
            ast = p,depends=aDep,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),msg)
      equation
        str = Debug.bcallret3(not (encoding ==& "UTF-8"), System.iconv, str, encoding, "UTF-8", str);
        newp = Parser.parsestring(str,name);
        newp = Interactive.updateProgram(newp, p);
      then
        (Env.emptyCache(),Values.BOOL(true),Interactive.SYMBOLTABLE(newp,aDep,NONE(),ic,iv,cf,lf));
        
    case (cache,env,"loadString",_,st,msg)
    then (cache,Values.BOOL(false),st);
        
    case (cache,env,"saveModel",{Values.STRING(filename),Values.CODE(Absyn.C_TYPENAME(classpath))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        str = Dump.unparseStr(Absyn.PROGRAM({absynClass},Absyn.TOP(),Absyn.TIMESTAMP(0.0,0.0)),true) ;
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"saveTotalModel",{Values.STRING(filename),Values.CODE(Absyn.C_TYPENAME(classpath))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        ptot = Dependency.getTotalProgram(classpath,p);
        str = Dump.unparseStr(ptot,true);
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"save",{Values.CODE(Absyn.C_TYPENAME(className))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        (newp,filename) = Interactive.getContainedClassAndFile(className, p);
        str = Dump.unparseStr(newp,true);
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"save",{Values.CODE(Absyn.C_TYPENAME(className))},st,msg)
    then (cache,Values.BOOL(false),st);
        
    case (cache,env,"saveAll",{Values.STRING(filename)},st as Interactive.SYMBOLTABLE(ast=p),msg)
      equation
        str = Dump.unparseStr(p,true);
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"saveModel",{Values.STRING(name),Values.CODE(Absyn.C_TYPENAME(classpath))},
        (st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(classpath, p);
        str = Dump.unparseStr(Absyn.PROGRAM({absynClass},Absyn.TOP(),Absyn.TIMESTAMP(0.0,0.0)),true);
        Error.addMessage(Error.WRITING_FILE_ERROR, {name});
      then
        (cache,Values.BOOL(false),st);
    
    case (cache,env,"saveModel",{Values.STRING(name),Values.CODE(Absyn.C_TYPENAME(classpath))},st,msg)
      equation
        cname = Absyn.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {cname,"global"});
      then
        (cache,Values.BOOL(false),st);
        
    case (cache, env, "saveTotalSCode", 
        {Values.STRING(filename), Values.CODE(Absyn.C_TYPENAME(classpath))}, st, msg)
      equation
        (scodeP, st) = Interactive.symbolTableToSCode(st);
        scodeP = SCodeFlatten.flattenClassInProgram(classpath, scodeP);
        scodeP = SCode.removeBuiltinsFromTopScope(scodeP);
        str = SCodeDump.programStr(scodeP);
        System.writeFile(filename, str);
      then
        (cache, Values.BOOL(true), st);
        
    case (cache, env, "saveTotalSCode", _, st, msg)
      then (cache, Values.BOOL(false), st);
        
    case (cache,env,"getDocumentationAnnotation",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as Interactive.SYMBOLTABLE(ast=p),msg)
      equation
        ((str1,str2)) = Interactive.getNamedAnnotation(classpath, p, "Documentation", SOME(("","")),Interactive.getDocumentationAnnotationString);
      then
        (cache,ValuesUtil.makeArray({Values.STRING(str1),Values.STRING(str2)}),st);
      
    case (cache,env,"isPackage",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as Interactive.SYMBOLTABLE(ast=p),msg)
      equation
        b = Interactive.isPackage(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"isPartial",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as Interactive.SYMBOLTABLE(ast=p),msg)
      equation
        b = Interactive.isPartial(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"isModel",{Values.CODE(Absyn.C_TYPENAME(classpath))},st as Interactive.SYMBOLTABLE(ast=p),msg)
      equation
        b = Interactive.isModel(classpath, p);
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"getAstAsCorbaString",{Values.STRING("<interactive>")},st as Interactive.SYMBOLTABLE(ast=p),msg)
      equation
        Print.clearBuf();
        Dump.getAstAsCorbaString(p);
        res = Print.getString();
        Print.clearBuf();
      then
        (cache,Values.STRING(res),st);

    case (cache,env,"getAstAsCorbaString",{Values.STRING(str)},st as Interactive.SYMBOLTABLE(ast=p),msg)
      equation
        Print.clearBuf();
        Dump.getAstAsCorbaString(p);
        Print.writeBuf(str);
        Print.clearBuf();
        str = "Wrote result to file: " +& str;
      then
        (cache,Values.STRING(str),st);

    case (cache,env,"getAstAsCorbaString",_,st,msg)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"getAstAsCorbaString failed"});
      then (cache,Values.STRING(""),st);
        
    case (cache,env,"strtok",{Values.STRING(str),Values.STRING(token)},st,msg)
      equation
        vals = List.map(System.strtok(str,token), ValuesUtil.makeString);
        i = listLength(vals);
      then (cache,Values.ARRAY(vals,{i}),st);

    case (cache,env,"stringReplace",{Values.STRING(str1),Values.STRING(str2),Values.STRING(str3)},st,msg)
      equation
        str = System.stringReplace(str1, str2, str3);
      then (cache,Values.STRING(str),st);

        /* Checks the installation of OpenModelica and tries to find common errors */
    case (cache,env,"checkSettings",{},st,msg)
      equation
        vars_1 = {"OPENMODELICAHOME","OPENMODELICALIBRARY","OMC_PATH","OMDEV_PATH","OMC_FOUND","MODELICAUSERCFLAGS","WORKING_DIRECTORY","CREATE_FILE_WORKS","REMOVE_FILE_WORKS","OS","SYSTEM_INFO","RTLIBS","C_COMPILER","C_COMPILER_RESPONDING","CONFIGURE_CMDLINE"};
        omhome = Settings.getInstallationDirectoryPath();
        omlib = Settings.getModelicaPath();
        omcpath = omhome +& "/bin/omc" +& System.getExeExt();
        omdev = Util.makeValueOrDefault(System.readEnv,"OMDEV","");
        omcfound = System.regularFileExists(omcpath);
        os = System.os();
        touch_file = "omc.checksettings.create_file_test";
        usercflags = Util.makeValueOrDefault(System.readEnv,"MODELICAUSERCFLAGS","");
        workdir = System.pwd();
        touch_res = 0 == System.systemCall("touch " +& touch_file);
        uname_res = 0 == System.systemCall("uname -a > " +& touch_file);
        uname = System.readFile(touch_file);
        rm_res = 0 == System.systemCall("rm " +& touch_file);
        platform = System.platform();
        senddata = System.getRTLibs();
        gcc = System.getCCompiler();
        gcc_res = 0 == System.systemCall(gcc +& " -v > /dev/null 2>&1");
        confcmd = System.configureCommandLine();
        vals = {Values.STRING(omhome),
                Values.STRING(omlib),
                Values.STRING(omcpath),
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
                Values.BOOL(gcc_res),
                Values.STRING(confcmd)};
      then (cache,Values.RECORD(Absyn.IDENT("OpenModelica.Scripting.CheckSettingsResult"),vals,vars_1,-1),st);
        
    case (cache,env,"readSimulationResult",{Values.STRING(filename),Values.ARRAY(valueLst=cvars),Values.INTEGER(size)},st,msg)
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
        
    case (cache,env,"readSimulationResultSize",{Values.STRING(filename)},st,msg)
      equation
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename_1 = Util.if_(System.strncmp("/",filename,1)==0,filename,stringAppendList({pwd,pd,filename}));
        i = SimulationResults.readSimulationResultSize(filename_1);
      then
        (cache,Values.INTEGER(i),st);
        
    case (cache,env,"readSimulationResultVars",{Values.STRING(filename)},st,msg)
      equation
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename_1 = Util.if_(System.strncmp("/",filename,1)==0,filename,stringAppendList({pwd,pd,filename}));
        args = SimulationResults.readVariables(filename_1);
        vals = List.map(args, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v,st);

    case (cache,env,"compareSimulationResults",{Values.STRING(filename),Values.STRING(filename_1),Values.STRING(filename2),Values.REAL(x1),Values.REAL(x2),Values.ARRAY(valueLst=cvars)},st,msg)
      equation
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename = stringAppendList({pwd,pd,filename});
        filename_1 = stringAppendList({pwd,pd,filename_1});
        filename2 = stringAppendList({pwd,pd,filename2});
        vars_1 = List.map(cvars, ValuesUtil.valString);
        strings = SimulationResults.cmpSimulationResults(filename,filename_1,filename2,x1,x2,vars_1);
        cvars = List.map(strings,ValuesUtil.makeString);
        v = Util.if_(intGt(listLength(cvars),1),Values.LIST(cvars),listNth(cvars,0));
      then
        (cache,v,st);
        
    case (cache,env,"compareSimulationResults",_,st,msg)
      then (cache,Values.STRING("Error in compareSimulationResults"),st);
        
    case (cache,env,"getPlotSilent",{},st,msg)
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
          Values.BOOL(legend),
          Values.BOOL(grid),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.ARRAY(valueLst={Values.REAL(x1),Values.REAL(x2)}),
          Values.ARRAY(valueLst={Values.REAL(y1),Values.REAL(y2)})
        },
        st,
        msg)
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
        str3 = "--filename=\"" +& filename +& "\" --title=\"" +& title +& "\" --legend=" +& boolString(legend) +& " --grid=" +& boolString(grid) +& " --plotAll --logx=" +& boolString(logX) +& " --logy=" +& boolString(logY) +& " --xlabel=\"" +& xLabel +& "\" --ylabel=\"" +& yLabel +& "\" --xrange=" +& realString(x1) +& ":" +& realString(x2) +& " --yrange=" +& realString(y1) +& ":" +& realString(y2) +& " --new-window=" +& boolString(externalWindow);
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
          Values.BOOL(legend),
          Values.BOOL(grid),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.ARRAY(valueLst={Values.REAL(x1),Values.REAL(x2)}),
          Values.ARRAY(valueLst={Values.REAL(y1),Values.REAL(y2)})
        },
        st,
        msg)
      equation
        // check if plot is set to silent or not
        true = Config.getPlotSilent();
        // get the simulation filename
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        pd = System.pathDelimiter();
        // create absolute path of simulation result file
        str1 = System.pwd() +& pd +& filename;
        filename = Util.if_(System.regularFileExists(str1), str1, filename);
        legendStr = boolString(legend);
        gridStr = boolString(grid);
        logXStr = boolString(logX);
        logYStr = boolString(logY);
        x1Str = realString(x1);
        x2Str = realString(x2);
        y1Str = realString(y1);
        y2Str = realString(y2);
        args = {"_omc_PlotResult",filename,title,legendStr,gridStr,"plotAll",logXStr,logYStr,xLabel,yLabel,x1Str,x2Str,y1Str,y2Str};
        vals = List.map(args, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v,st);
    
    case (cache,env,"plotAll",_,st,msg)
      then (cache,Values.BOOL(false),st);

    // plot(x, model)
    case (cache,env,"plot",
        {
          Values.ARRAY(valueLst = cvars),
          Values.BOOL(externalWindow),
          Values.STRING(filename),
          Values.STRING(title),
          Values.BOOL(legend),
          Values.BOOL(grid),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.ARRAY(valueLst={Values.REAL(x1),Values.REAL(x2)}),
          Values.ARRAY(valueLst={Values.REAL(y1),Values.REAL(y2)})
        },
        st,msg)
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
        str3 = "--filename=\"" +& filename +& "\" --title=\"" +& title +& "\" --legend=" +& boolString(legend) +& " --grid=" +& boolString(grid) +& " --plot --logx=" +& boolString(logX) +& " --logy=" +& boolString(logY) +& " --xlabel=\"" +& xLabel +& "\" --ylabel=\"" +& yLabel +& "\" --xrange=" +& realString(x1) +& ":" +& realString(x2) +& " --yrange=" +& realString(y1) +& ":" +& realString(y2) +& " --new-window=" +& boolString(externalWindow) +& " \"" +& str +& "\"";
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
          Values.BOOL(legend),
          Values.BOOL(grid),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.ARRAY(valueLst={Values.REAL(x1),Values.REAL(x2)}),
          Values.ARRAY(valueLst={Values.REAL(y1),Values.REAL(y2)})
        },
        st,msg)
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
        legendStr = boolString(legend);
        gridStr = boolString(grid);
        logXStr = boolString(logX);
        logYStr = boolString(logY);
        x1Str = realString(x1);
        x2Str = realString(x2);
        y1Str = realString(y1);
        y2Str = realString(y2);
        args = {"_omc_PlotResult",filename,title,legendStr,gridStr,"plot",logXStr,logYStr,xLabel,yLabel,x1Str,x2Str,y1Str,y2Str};
        args = listAppend(args, vars_1);
        vals = List.map(args, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v,st);
        
    case (cache,env,"plot",_,st,msg)
      then
        (cache,Values.BOOL(false),st);
        
    // visualize2
    case (cache,env,"visualize",
        {
          Values.CODE(Absyn.C_TYPENAME(className)),
          Values.BOOL(externalWindow),
          Values.STRING(filename)
        },(st as Interactive.SYMBOLTABLE(ast = p)),msg)
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
        
    case (cache,env,"visualize",_,st,msg)
      then
        (cache,Values.BOOL(false),st);
        
    case (cache,env,"val",{cvar,Values.REAL(timeStamp)},st,msg)
      equation
        (cache,Values.STRING(filename),_) = Ceval.ceval(cache,env,buildCurrentSimulationResultExp(), true, SOME(st),msg);
        varNameStr = ValuesUtil.printCodeVariableName(cvar);
        val = SimulationResults.val(filename,varNameStr,timeStamp);
      then (cache,Values.REAL(val),st);

    case (cache,env,"closeSimulationResultFile",_,st,msg)
      equation
        SimulationResults.close();
      then
        (cache,Values.BOOL(true),st);
            
    case (cache,env,"getAlgorithmCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = listLength(getAlgorithms(absynClass));
      then
        (cache,Values.INTEGER(n),st);
    
    case (cache,env,"getAlgorithmCount",_,st,msg) then (cache,Values.INTEGER(0),st);
      
    case (cache,env,"getNthAlgorithm",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthAlgorithm(absynClass, n);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,"getNthAlgorithm",_,st,msg) then (cache,Values.STRING(""),st);
      
    case (cache,env,"getInitialAlgorithmCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = listLength(getInitialAlgorithms(absynClass));
      then
        (cache,Values.INTEGER(n),st);
    
    case (cache,env,"getInitialAlgorithmCount",_,st,msg) then (cache,Values.INTEGER(0),st);
      
    case (cache,env,"getNthInitialAlgorithm",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthInitialAlgorithm(absynClass, n);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,"getNthInitialAlgorithm",_,st,msg) then (cache,Values.STRING(""),st);
      
    case (cache,env,"getAlgorithmItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getAlgorithmItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);
    
    case (cache,env,"getAlgorithmItemsCount",_,st,msg) then (cache,Values.INTEGER(0),st);
      
    case (cache,env,"getNthAlgorithmItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthAlgorithmItem(absynClass, n);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,"getNthAlgorithmItem",_,st,msg) then (cache,Values.STRING(""),st);
    
    case (cache,env,"getInitialAlgorithmItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getInitialAlgorithmItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);
    
    case (cache,env,"getInitialAlgorithmItemsCount",_,st,msg) then (cache,Values.INTEGER(0),st);
      
    case (cache,env,"getNthInitialAlgorithmItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthInitialAlgorithmItem(absynClass, n);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,"getNthInitialAlgorithmItem",_,st,msg) then (cache,Values.STRING(""),st);
    
    case (cache,env,"getEquationCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = listLength(getEquations(absynClass));
      then
        (cache,Values.INTEGER(n),st);
    
    case (cache,env,"getEquationCount",_,st,msg) then (cache,Values.INTEGER(0),st);
      
    case (cache,env,"getNthEquation",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthEquation(absynClass, n);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,"getNthEquation",_,st,msg) then (cache,Values.STRING(""),st);
      
    case (cache,env,"getInitialEquationCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = listLength(getInitialEquations(absynClass));
      then
        (cache,Values.INTEGER(n),st);
    
    case (cache,env,"getInitialEquationCount",_,st,msg) then (cache,Values.INTEGER(0),st);
      
    case (cache,env,"getNthInitialEquation",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthInitialEquation(absynClass, n);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,"getNthInitialEquation",_,st,msg) then (cache,Values.STRING(""),st);
    
    case (cache,env,"getEquationItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getEquationItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);
    
    case (cache,env,"getEquationItemsCount",_,st,msg) then (cache,Values.INTEGER(0),st);
      
    case (cache,env,"getNthEquationItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthEquationItem(absynClass, n);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,"getNthEquationItem",_,st,msg) then (cache,Values.STRING(""),st);
    
    case (cache,env,"getInitialEquationItemsCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getInitialEquationItemsCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);
    
    case (cache,env,"getInitialEquationItemsCount",_,st,msg) then (cache,Values.INTEGER(0),st);
      
    case (cache,env,"getNthInitialEquationItem",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthInitialEquationItem(absynClass, n);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,"getNthInitialEquationItem",_,st,msg) then (cache,Values.STRING(""),st);
      
    case (cache,env,"getAnnotationCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getAnnotationCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);
    
    case (cache,env,"getAnnotationCount",_,st,msg) then (cache,Values.INTEGER(0),st);
      
    case (cache,env,"getNthAnnotationString",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = getNthAnnotationString(absynClass, n);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,"getNthAnnotationString",_,st,msg) then (cache,Values.STRING(""),st);
    
    case (cache,env,"getImportCount",{Values.CODE(Absyn.C_TYPENAME(path))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        n = getImportCount(absynClass);
      then
        (cache,Values.INTEGER(n),st);
    
    case (cache,env,"getImportCount",_,st,msg) then (cache,Values.INTEGER(0),st);

    case (cache,env,"getNthImport",{Values.CODE(Absyn.C_TYPENAME(path)),Values.INTEGER(n)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        vals = getNthImport(absynClass, n);
      then
        (cache,ValuesUtil.makeArray(vals),st);
    
    case (cache,env,"getNthImport",_,st,msg) then (cache,ValuesUtil.makeArray({}),st);
        
    // plotParametric
    case (cache,env,"plotParametric",
        {
          cvar,
          cvar2,
          Values.BOOL(externalWindow),
          Values.STRING(filename),
          Values.STRING(title),
          Values.BOOL(legend),
          Values.BOOL(grid),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.ARRAY(valueLst={Values.REAL(x1),Values.REAL(x2)}),
          Values.ARRAY(valueLst={Values.REAL(y1),Values.REAL(y2)})
        },
        st,msg)
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
        str3 = "--filename=\"" +& filename +& "\" --title=\"" +& title +& "\" --legend=" +& boolString(legend) +& " --grid=" +& boolString(grid) +& " --plotParametric --logx=" +& boolString(logX) +& " --logy=" +& boolString(logY) +& " --xlabel=\"" +& xLabel +& "\" --ylabel=\"" +& yLabel +& "\" --xrange=" +& realString(x1) +& ":" +& realString(x2) +& " --yrange=" +& realString(y1) +& ":" +& realString(y2) +& " --new-window=" +& boolString(externalWindow) +& " \"" +& str +& "\"";
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
          Values.BOOL(legend),
          Values.BOOL(grid),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.ARRAY(valueLst={Values.REAL(x1),Values.REAL(x2)}),
          Values.ARRAY(valueLst={Values.REAL(y1),Values.REAL(y2)})
        },
        st,msg)
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
        legendStr = boolString(legend);
        gridStr = boolString(grid);
        logXStr = boolString(logX);
        logYStr = boolString(logY);
        x1Str = realString(x1);
        x2Str = realString(x2);
        y1Str = realString(y1);
        y2Str = realString(y2);
        args = {"_omc_PlotResult",filename,title,legendStr,gridStr,"plotParametric",logXStr,logYStr,xLabel,yLabel,x1Str,x2Str,y1Str,y2Str,str,str3};
        vals = List.map(args, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v,st);
    
    case (cache,env,"plotParametric",_,st,msg)
      then (cache,Values.BOOL(false),st);
    
    case (cache,env,"echo",{v as Values.BOOL(bval)},st,msg)
      equation
        setEcho(bval);
      then (cache,v,st);

    case (cache,env,"strictRMLCheck",_,st as Interactive.SYMBOLTABLE(ast = p),msg)
      equation
        _ = List.map1r(List.map(Interactive.getFunctionsInProgram(p), SCodeUtil.translateClass), MetaUtil.strictRMLCheck, true);
        str = Error.printMessagesStr();
        v = Values.STRING(str);
      then (cache,v,st);

    case (cache,env,"dumpXMLDAE",vals,st,msg)
      equation
        (cache,st,xml_filename,xml_contents) = dumpXMLDAE(cache,env,vals,st, msg);
      then
        (cache,ValuesUtil.makeArray({Values.STRING(xml_filename),Values.STRING(xml_contents)}),st);
        
    case (cache,env,"dumpXMLDAE",_,st,msg)
      equation
        str = Error.printMessagesStr();
      then (cache,ValuesUtil.makeArray({Values.STRING("Xml dump error."),Values.STRING(str)}),st);
        
    case (cache,env,"uriToFilename",{Values.STRING(str)},st,msg)
      equation
        str = getFullPathFromUri(str,true);
      then (cache,Values.STRING(str),st);

    case (cache,env,"uriToFilename",_,st,msg)
      then (cache,Values.STRING(""),st);
        
    case (cache,env,"solveLinearSystem",{Values.ARRAY(valueLst=vals),v,Values.ENUM_LITERAL(index=1 /*dgesv*/),Values.ARRAY(valueLst={Values.INTEGER(-1)})},st,msg)
      equation
        (realVals,i) = System.dgesv(List.map(vals,ValuesUtil.arrayValueReals),ValuesUtil.arrayValueReals(v));
        v = ValuesUtil.makeArray(List.map(realVals,ValuesUtil.makeReal));
      then (cache,Values.TUPLE({v,Values.INTEGER(i)}),st);

    case (cache,env,"solveLinearSystem",{Values.ARRAY(valueLst=vals),v,Values.ENUM_LITERAL(index=2 /*lpsolve55*/),Values.ARRAY(valueLst=vals2)},st,msg)
      equation
        (realVals,i) = System.lpsolve55(List.map(vals,ValuesUtil.arrayValueReals),ValuesUtil.arrayValueReals(v),List.map(vals2,ValuesUtil.valueInteger));
        v = ValuesUtil.makeArray(List.map(realVals,ValuesUtil.makeReal));
      then (cache,Values.TUPLE({v,Values.INTEGER(i)}),st);

    case (cache,env,"solveLinearSystem",{_,v,_,_},st,msg)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Unknown input to solveLinearSystem scripting function"});
      then (cache,Values.TUPLE({v,Values.INTEGER(-1)}),st);

 end matchcontinue;
end cevalInteractiveFunctions2;

protected function visualizationVarShouldBeAdded
  input String var;
  input list<String> inIds;
algorithm
  _ := matchcontinue (var,inIds)
    local
      String id;
      list<String> ids;
      
    case (var,id::ids)
      equation
        false = 0 == stringLength(id);
        true = 0 == System.strncmp(var,id,stringLength(id));
      then ();
    case (var,_::ids)
      equation
        visualizationVarShouldBeAdded(var,ids);
      then ();
  end matchcontinue;
end visualizationVarShouldBeAdded;

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

public function getIncidenceMatrix "function getIncidenceMatrix
 author: adrpo
 translates a model and returns the incidence matrix"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  input String filenameprefix;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.SymbolTable outInteractiveSymbolTable;
  output String outString;
algorithm
  (outCache,outValue,outInteractiveSymbolTable,outString):=
  match (inCache,inEnv,className,inInteractiveSymbolTable,inMsg,filenameprefix)
    local
      String filename,file_dir, str;
      list<SCode.Element> p_1,sp;
      DAE.DAElist dae_1,dae;
      list<Env.Frame> env;
      list<Interactive.InstantiatedClass> ic_1,ic;
      BackendDAE.BackendDAE dlow;
      Absyn.ComponentRef a_cref;
      Interactive.SymbolTable st;
      Absyn.Program p;
      list<Interactive.Variable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      DAE.Exp fileprefix;
      Env.Cache cache;
      String flatModelicaStr;

    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg,filenameprefix) /* mo file directory */
      equation
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env,_,dae_1) =
        Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,p_1,className);
        dae  = DAEUtil.transformationsBeforeBackend(cache,env,dae_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dae,env));
        a_cref = Absyn.pathToCref(className);
        file_dir = getFileDir(a_cref, p);
        dlow = BackendDAECreate.lower(dae, Env.getFunctionTree(cache), false);
        dlow = BackendDAECreate.findZeroCrossings(dlow);
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
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input Boolean relaxedFrontEnd "Do not check for illegal simulation models, so we allow instantation of packages, etc";
  output Env.Cache cache;
  output Env.Env env;
  output DAE.DAElist dae;
  output Interactive.SymbolTable st;
algorithm
  (cache,env,dae,st) := runFrontEndWork(inCache,inEnv,className,inInteractiveSymbolTable,relaxedFrontEnd,Error.getNumErrorMessages());
end runFrontEnd;

protected function runFrontEndWork
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className;
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input Boolean relaxedFrontEnd "Do not check for illegal simulation models, so we allow instantation of packages, etc";
  input Integer numError;
  output Env.Cache cache;
  output Env.Env env;
  output DAE.DAElist dae;
  output Interactive.SymbolTable st;
algorithm
  (cache,env,dae,st) := matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,relaxedFrontEnd,numError)
    local
      Absyn.Restriction restriction;
      Absyn.Class absynClass;
      String str,re;
      Option<SCode.Program> fp;
      SCode.Program scodeP;
      list<SCode.Element> sp;
      list<Env.Frame> env;
      list<Interactive.InstantiatedClass> ic,ic_1;
      Interactive.SymbolTable st;
      Absyn.Program p,ptot;
      list<Interactive.Variable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      list<Interactive.LoadedFile> lf;
      Absyn.TimeStamp ts;
      AbsynDep.Depends aDep;
      list<tuple<Absyn.Path,list<String>>> usedModels;
      
    case (cache,env,className,Interactive.SYMBOLTABLE(p,aDep,fp,ic,iv,cf,lf),relaxedFrontEnd,_)
      equation
        str = Absyn.pathString(className);
        (absynClass as Absyn.CLASS(restriction = restriction)) = Interactive.getPathedClassInProgram(className, p);
        re = Absyn.restrString(restriction);
        Error.assertionOrAddSourceMessage(relaxedFrontEnd or not (Absyn.isFunctionRestriction(restriction) or Absyn.isPackageRestriction(restriction)),
          Error.INST_INVALID_RESTRICTION,{str,re},Absyn.dummyInfo);
        (p,true) = loadModel(Interactive.getUsesAnnotationOrDefault(Absyn.PROGRAM({absynClass},Absyn.TOP(),Absyn.dummyTimeStamp)),Settings.getModelicaPath(),p,false,true);
        
        ptot = Dependency.getTotalProgram(className,p);
        
        //System.stopTimer();
        //print("\nExists+Dependency: " +& realString(System.getTimerIntervalTime()));
        
        //System.startTimer();
        //print("\nAbsyn->SCode");
        
        scodeP = SCodeUtil.translateAbsyn2SCode(ptot);
        
        // TODO: Why not simply get the whole thing from the cached SCode? It's faster, just need to stop doing the silly Dependency stuff.
        
        //System.stopTimer();
        //print("\nAbsyn->SCode: " +& realString(System.getTimerIntervalTime()));
        
        //System.startTimer();
        //print("\nInst.instantiateClass");
        
        (cache,env,_,dae) = Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,scodeP,className);
        
        //System.stopTimer();
        //print("\nInst.instantiateClass: " +& realString(System.getTimerIntervalTime()));
        
        // adrpo: do not add it to the instantiated classes, it just consumes memory for nothing.
        // ic_1 = ic;
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dae,env));
      then (cache,env,dae,Interactive.SYMBOLTABLE(p,aDep,fp,ic_1,iv,cf,lf));

    case (cache,env,className,st as Interactive.SYMBOLTABLE(ast=p),_,_)
      equation
        str = Absyn.pathString(className);
        failure(_ = Interactive.getPathedClassInProgram(className, p));
        Error.addMessage(Error.LOOKUP_ERROR, {str,"<TOP>"});
      then fail();
        
    case (cache,env,className,st,_,numError)
      equation
        str = Absyn.pathString(className);
        true = Error.getNumErrorMessages() == numError;
        str = "Instantiation of " +& str +& " failed with no error message.";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end runFrontEndWork;

protected function translateModel "function translateModel
 author: x02lucpo
 translates a model into cpp code and writes also a makefile"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.SymbolTable outInteractiveSymbolTable;
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
      Interactive.SymbolTable st;
      list<String> libs;
      Values.Value outValMsg;
      String file_dir, fileNamePrefix, str, re;
      Absyn.Class absynClass;
      Absyn.Restriction restriction;
      list<tuple<Absyn.Path,list<String>>> usedModels;
      Absyn.Program p;
    
    case (cache,env,className,st as Interactive.SYMBOLTABLE(ast=p),fileNamePrefix,addDummy,inSimSettingsOpt)
      equation
        (cache, outValMsg, st, indexed_dlow, libs, file_dir, resultValues) =
          SimCode.translateModel(cache,env,className,st,fileNamePrefix,addDummy,inSimSettingsOpt,Absyn.FUNCTIONARGS({},{}));
      then
        (cache,outValMsg,st,indexed_dlow,libs,file_dir,resultValues);

  end match;
end translateModel;

/*protected function translateModelCPP "function translateModel
 author: x02lucpo
 translates a model into cpp code and writes also a makefile"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.SymbolTable outInteractiveSymbolTable;
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
      Interactive.SymbolTable st;
      list<String> libs;
      Values.Value outValMsg;
      String file_dir, fileNamePrefix;
    
    case (cache,env,className,st,fileNamePrefix,addDummy,inSimSettingsOpt)
      equation
        (cache, outValMsg, st, indexed_dlow, libs, file_dir, resultValues) =
          SimCode.translateModelCPP(cache,env,className,st,fileNamePrefix,addDummy,inSimSettingsOpt);
      then
        (cache,outValMsg,st,indexed_dlow,libs,file_dir,resultValues);
  end match;
end translateModelCPP;*/

protected function translateModelFMU "function translateModelFMU
 author: Frenkel TUD
 translates a model into cpp code and writes also a makefile"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable):=
  match (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix,addDummy,inSimSettingsOpt)
    local
      Env.Cache cache;
      list<Env.Frame> env;
      BackendDAE.BackendDAE indexed_dlow;
      Interactive.SymbolTable st;
      list<String> libs;
      Values.Value outValMsg;
      String file_dir, fileNamePrefix, str;
    case (cache,env,className,st,fileNamePrefix,addDummy,inSimSettingsOpt) /* mo file directory */
      equation
        (cache, outValMsg, st, indexed_dlow, libs, file_dir, _) =
          SimCode.translateModelFMU(cache,env,className,st,fileNamePrefix,addDummy,inSimSettingsOpt);
          
        // compile
        fileNamePrefix = stringAppend(fileNamePrefix,"_FMU");
        compileModel(fileNamePrefix , libs, file_dir, "", "");
          
      then
        (cache,outValMsg,st);
    case (cache,env,className,st,fileNamePrefix,addDummy,inSimSettingsOpt) /* mo file directory */
      equation
         str = Error.printMessagesStr();
      then
        (cache,ValuesUtil.makeArray({Values.STRING("translateModelFMU error."),Values.STRING(str)}),st);
  end match;
end translateModelFMU;


public function translateGraphics "function: translates the graphical annotations from old to new version"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className;
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable) :=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg)
    local
      list<SCode.Element> sp;
      list<Env.Frame> env;
      list<Interactive.InstantiatedClass> ic;
      Interactive.SymbolTable st;
      Absyn.Program p;
      list<Interactive.Variable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Env.Cache cache;
      list<Interactive.LoadedFile> lf;
      Absyn.TimeStamp ts;
      AbsynDep.Depends aDep;
      String errorMsg,retStr,s1;
      Absyn.Class cls, refactoredClass;
      Absyn.Within within_;
      Absyn.Program p1;
      Boolean strEmpty;

    case (cache,env,className,(st as Interactive.SYMBOLTABLE(p as Absyn.PROGRAM(globalBuildTimes=ts),aDep,_,ic,iv,cf,lf)),msg)
      equation
        cls = Interactive.getPathedClassInProgram(className, p);
        refactoredClass = Refactor.refactorGraphicalAnnotation(p, cls);
        within_ = Interactive.buildWithin(className);
        p1 = Interactive.updateProgram(Absyn.PROGRAM({refactoredClass}, within_,ts), p);
        s1 = Absyn.pathString(className);
        retStr=stringAppendList({"Translation of ",s1," successful.\n"});
      then
        (cache,Values.STRING(retStr),Interactive.SYMBOLTABLE(p1,aDep,NONE(),ic,iv,cf,lf));

    case (cache,_,_,st,_)
      equation
        errorMsg = Error.printMessagesStr();
        strEmpty = (stringCompare("",errorMsg)==0);
        errorMsg = Util.if_(strEmpty,"Internal error, translating graphics to new version",errorMsg);
      then 
        (cache,Values.STRING(errorMsg),st);
  end matchcontinue;
end translateGraphics;


protected function calculateSimulationSettings "function calculateSimulationSettings
 author: x02lucpo
 calculates the start,end,interval,stepsize, method and initFileName"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Values.Value> vals;
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output SimCode.SimulationSettings outSimSettings;
algorithm
  (outCache,outSimSettings):=
  match (inCache,inEnv,vals,inInteractiveSymbolTable,inMsg)
    local
      String method_str,options_str,outputFormat_str,variableFilter_str,s;
      Interactive.SymbolTable st;
      Values.Value starttime_v,stoptime_v,tolerance_v;
      Integer interval_i;
      Real starttime_r,stoptime_r,tolerance_r;
      list<Env.Frame> env;
      DAE.Exp starttime,stoptime,interval,toleranceExp,method,options,outputFormat;
      Ceval.Msg msg;
      Env.Cache cache;
      Boolean measureTime;
      String cflags,simflags;
    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(_)),starttime_v,stoptime_v,Values.INTEGER(interval_i),tolerance_v,Values.STRING(method_str),_,_,_,Values.STRING(options_str),Values.STRING(outputFormat_str),Values.STRING(variableFilter_str),Values.BOOL(measureTime),Values.STRING(cflags),Values.STRING(simflags)},
         (st as Interactive.SYMBOLTABLE(ast = _)),msg)
      equation
        starttime_r = ValuesUtil.valueReal(starttime_v);
        stoptime_r = ValuesUtil.valueReal(stoptime_v);
        tolerance_r = ValuesUtil.valueReal(tolerance_v);
        outSimSettings = SimCode.createSimulationSettings(starttime_r,stoptime_r,interval_i,tolerance_r,method_str,options_str,outputFormat_str,variableFilter_str,measureTime,cflags);
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
  (outValue, restValues) := matchcontinue(inValues, errorMessage)
    local
      Values.Value v;
      list<Values.Value> rest;
    
    // everything is fine and dandy
    case (v::rest, _) then (v, rest);
    
    // ups, we're missing an argument
    case ({}, errorMessage)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {errorMessage});
      then
        fail();
  end matchcontinue; 
end getListFirstShowError;

protected function buildModel "function buildModel
 author: x02lucpo
 translates and builds the model by running compiler script on the generated makefile"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Values.Value> inValues;
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Interactive.SymbolTable outInteractiveSymbolTable3;  
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
      Values.Value ret_val;
      Interactive.SymbolTable st,st_1,st2;
      BackendDAE.BackendDAE indexed_dlow_1;
      list<String> libs;
      String file_dir,init_filename,method_str,filenameprefix,oldDir,exeFile,s3,simflags;
      Absyn.Path classname;
      Absyn.Program p;
      Absyn.Class cdef;
      list<Interactive.CompiledCFunction> cf;
      Real edit,build,globalEdit,globalBuild,timeCompile;
      list<Env.Frame> env;
      SimCode.SimulationSettings simSettings;
      Values.Value starttime,stoptime,interval,tolerance,method,fileprefix,storeInTemp,noClean,options,outputFormat,variableFilter;
      list<SCode.Element> sp;
      list<Values.Value> vals, values;
      list<Interactive.InstantiatedClass> ic;
      list<Interactive.Variable> iv;
      Ceval.Msg msg;
      Env.Cache cache;
      Boolean cdToTemp,existFile;
      Absyn.TimeStamp ts;
      
    // do not recompile.
    case (cache,env,vals,
          (st as Interactive.SYMBOLTABLE(ast = p as Absyn.PROGRAM(globalBuildTimes=Absyn.TIMESTAMP(_,edit)))),msg)
      // If we already have an up-to-date version of the binary file, we don't need to recompile.
      equation
        // buildModel expects these arguments:
        // className, startTime, stopTime, numberOfIntervals, tolerance, method, fileNamePrefix, 
        // storeInTemp, noClean, options, outputFormat, variableFilter, measureTime, cflags, simflags
        (Values.CODE(Absyn.C_TYPENAME(classname)),vals) = getListFirstShowError(vals, "while retreaving the className (1 arg) from the buildModel arguments");
        (starttime,vals) = getListFirstShowError(vals, "while retreaving the startTime (2 arg) from the buildModel arguments");
        (stoptime,vals) = getListFirstShowError(vals, "while retreaving the stopTime (3 arg) from the buildModel arguments");
        (interval,vals) = getListFirstShowError(vals, "while retreaving the numberOfIntervals (4 arg) from the buildModel arguments");
        (tolerance,vals) = getListFirstShowError(vals, "while retreaving the tolerance (5 arg) from the buildModel arguments");
        (Values.STRING(method_str),vals) = getListFirstShowError(vals, "while retreaving the method (6 arg) from the buildModel arguments");
        (Values.STRING(filenameprefix),vals) = getListFirstShowError(vals, "while retreaving the fileNamePrefix (7 arg) from the buildModel arguments");
        (Values.BOOL(cdToTemp),vals) = getListFirstShowError(vals, "while retreaving the storeInTemp (8 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the noClean (9 arg) from the buildModel arguments");
        (options,vals) = getListFirstShowError(vals, "while retreaving the options (10 arg) from the buildModel arguments");
        (Values.STRING(outputFormat_str),vals) = getListFirstShowError(vals, "while retreaving the outputFormat (11 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the variableFilter (12 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the measureTime (13 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the cflags (14 arg) from the buildModel arguments");
        (Values.STRING(simflags),vals) = getListFirstShowError(vals, "while retreaving the simflags (15 arg) from the buildModel arguments");
        //cdef = Interactive.getPathedClassInProgram(classname,p);
        Error.clearMessages() "Clear messages";
        // Only compile if change occured after last build.
        (Absyn.CLASS(info = Absyn.INFO(buildTimes= Absyn.TIMESTAMP(build,_)))) = Interactive.getPathedClassInProgram(classname,p);
        true = (build >. edit);
        oldDir = System.pwd();
        compileDir = changeToTempDirectory(cdToTemp);
        init_filename = stringAppendList({filenameprefix,"_init.xml"});
        exeFile = filenameprefix +& System.getExeExt();
        existFile = System.regularFileExists(exeFile);
        _ = System.cd(oldDir);
        true = existFile;
    then
      (cache,st,compileDir,filenameprefix,method_str,outputFormat_str,init_filename,simflags,zeroAdditionalSimulationResultValues);
    
    // compile the model
    case (cache,env,vals,(st_1 as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        // buildModel expects these arguments:
        // className, startTime, stopTime, numberOfIntervals, tolerance, method, fileNamePrefix, 
        // storeInTemp, noClean, options, outputFormat, variableFilter, measureTime, cflags, simflags
        values = vals;
        (Values.CODE(Absyn.C_TYPENAME(classname)),vals) = getListFirstShowError(vals, "while retreaving the className (1 arg) from the buildModel arguments");
        (starttime,vals) = getListFirstShowError(vals, "while retreaving the startTime (2 arg) from the buildModel arguments");
        (stoptime,vals) = getListFirstShowError(vals, "while retreaving the stopTime (3 arg) from the buildModel arguments");
        (interval,vals) = getListFirstShowError(vals, "while retreaving the numberOfIntervals (4 arg) from the buildModel arguments");
        (tolerance,vals) = getListFirstShowError(vals, "while retreaving the tolerance (5 arg) from the buildModel arguments");
        (method,vals) = getListFirstShowError(vals, "while retreaving the method (6 arg) from the buildModel arguments");
        (Values.STRING(filenameprefix),vals) = getListFirstShowError(vals, "while retreaving the fileNamePrefix (7 arg) from the buildModel arguments");
        (Values.BOOL(cdToTemp),vals) = getListFirstShowError(vals, "while retreaving the storeInTemp (8 arg) from the buildModel arguments");
        (noClean,vals) = getListFirstShowError(vals, "while retreaving the noClean (9 arg) from the buildModel arguments");
        (options,vals) = getListFirstShowError(vals, "while retreaving the options (10 arg) from the buildModel arguments");
        (outputFormat,vals) = getListFirstShowError(vals, "while retreaving the outputFormat (11 arg) from the buildModel arguments");
        (variableFilter,vals) = getListFirstShowError(vals, "while retreaving the variableFilter (12 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the measureTime (13 arg) from the buildModel arguments");
        (_,vals) = getListFirstShowError(vals, "while retreaving the cflags (14 arg) from the buildModel arguments");
        (Values.STRING(simflags),vals) = getListFirstShowError(vals, "while retreaving the simflags (15 arg) from the buildModel arguments");
        
        (cdef as Absyn.CLASS(info = Absyn.INFO(buildTimes=ts as Absyn.TIMESTAMP(_,globalEdit)))) = Interactive.getPathedClassInProgram(classname,p);
        Absyn.PROGRAM(_,_,Absyn.TIMESTAMP(globalBuild,_)) = p;

       Error.clearMessages() "Clear messages";
        oldDir = System.pwd();
        compileDir = changeToTempDirectory(cdToTemp);
        (cache,simSettings) = calculateSimulationSettings(cache,env,values,st_1,msg);
        SimCode.SIMULATION_SETTINGS(method = method_str, outputFormat = outputFormat_str) 
           = simSettings;
        
        (cache,ret_val,st,indexed_dlow_1,libs,file_dir,resultValues) = translateModel(cache,env, classname, st_1, filenameprefix,true, SOME(simSettings));
        //cname_str = Absyn.pathString(classname);
        //SimCode.generateInitData(indexed_dlow_1, classname, filenameprefix, init_filename,
        //  starttime_r, stoptime_r, interval_r, tolerance_r, method_str,options_str,outputFormat_str);
        
        System.realtimeTick(RT_CLOCK_BUILD_MODEL);
        init_filename = filenameprefix +& "_init.xml"; //a hack ? should be at one place somewhere
        //win1 = getWithinStatement(classname);
        s3 = extractNoCleanCommand(noClean);
        
        Debug.fprintln(Flags.DYN_LOAD, "buildModel: about to compile model " +& filenameprefix +& ", " +& file_dir);
        compileModel(filenameprefix, libs, file_dir, s3, method_str);
        Debug.fprintln(Flags.DYN_LOAD, "buildModel: Compiling done.");
        _ = System.cd(oldDir);
        p = setBuildTime(p,classname);
        st2 = st;// Interactive.replaceSymbolTableProgram(st,p);
        timeCompile = System.realtimeTock(RT_CLOCK_BUILD_MODEL);
        resultValues = ("timeCompile",Values.REAL(timeCompile)) :: resultValues;
      then
        (cache,st2,compileDir,filenameprefix,method_str,outputFormat_str,init_filename,simflags,resultValues);
    
    // failure
    case (_,_,vals,_,_)
      equation
        Error.assertion(listLength(vals) == 15, "buildModel failure, length = " +& intString(listLength(vals)), Absyn.dummyInfo);
      then
        fail();
  end matchcontinue;
end buildModel;

protected function changeToTempDirectory "function changeToTempDirectory
changes to temp directory (set using the functions from Settings.mo)
if the boolean flag given as input is true"
  input Boolean cdToTemp;
  output String tempDir;
algorithm
  tempDir := matchcontinue(cdToTemp)
    case (true)
      equation
        tempDir = Settings.getTempDirectoryPath();
        0 = System.cd(tempDir);
      then tempDir +& System.pathDelimiter();
    else stringAppend(System.pwd(),System.pathDelimiter());
  end matchcontinue;
end changeToTempDirectory;

public function getFileDir "function: getFileDir
  author: x02lucpo
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

//protected function compileModel "function: compileModel
public function compileModel "function: compileModel
  author: PA, x02lucpo
  Compiles a model given a file-prefix, helper function to buildModel."
  input String inFilePrefix;
  input list<String> inLibsList;
  input String inFileDir;
  input String noClean;
  input String solverMethod "inline solvers requires setting environment variables";
algorithm
  _ := matchcontinue (inFilePrefix,inLibsList,inFileDir,noClean,solverMethod)
    local
      String pd,omhome,omhome_1,cd_path,libsfilename,libs_str,win_call,make_call,s_call,fileprefix,file_dir,command,filename,str,extra_command, 
             fileDLL, fileEXE, fileLOG, make;
      list<String> libs;
      Boolean isWindows;

    // If compileCommand not set, use $OPENMODELICAHOME\bin\Compile
    // adrpo 2009-11-29: use ALL THE TIME $OPENMODELICAHOME/bin/Compile
    case (fileprefix,libs,file_dir,noClean,solverMethod)
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
        omhome = Util.if_(isWindows, "set OPENMODELICAHOME=\"" +& System.stringReplace(omhome_1, "/", "\\") +& "\"&& ", "");
        win_call = stringAppendList({omhome,"\"",omhome_1,pd,"share",pd,"omc",pd,"scripts",pd,"Compile","\""," ",fileprefix," ",noClean});
        make = System.getMakeCommand();
        make_call = stringAppendList({make," -f ",fileprefix,".makefile >",fileprefix,".log 2>&1"});
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
        0 = System.systemCall(s_call);
        
        Debug.fprintln(Flags.DYN_LOAD, "compileModel: successful! ");
      then
        ();
    case (fileprefix,libs,file_dir,_,_) /* compilation failed */
      equation
        filename = stringAppendList({fileprefix,".log"});
        true = System.regularFileExists(filename);
        str = System.readFile(filename);
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {str});
        Debug.fprintln(Flags.DYN_LOAD, "compileModel: failed!");
      then
        fail();

    case (fileprefix,libs,file_dir,_,_) /* compilation failed\\n */
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
    case (fileprefix,libs,file_dir,_,_)
      equation
        failure(_ = Settings.getInstallationDirectoryPath());
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {"$OPENMODELICAHOME not found."});
      then
        fail();
  end matchcontinue;
end compileModel;

protected function readEnvNoFail
"@author: adrpo
 System.readEnv can fail, if it does this function returns the empty string"
  input String variableName;
  output String variableValue;
algorithm
    variableValue := matchcontinue(variableName)
      local String vValue;
      case (variableName)
        equation
          vValue = System.readEnv(variableName);
        then
          vValue;
      case (variableName) then "";
  end matchcontinue;
end readEnvNoFail;

protected function winCitation "function: winCitation
  author: PA
  Returns a citation mark if platform is windows, otherwise empty string.
  Used by simulate to make whitespaces work in filepaths for WIN32"
  output String outString;
algorithm
  outString:=
  matchcontinue ()
    case ()
      equation
        "WIN32" = System.platform();
      then
        "\"";
    case () then "";
  end matchcontinue;
end winCitation;

protected function extractFilePrefix "function extractFilePrefix
  author: x02lucpo
  extracts the file prefix from DAE.Exp as string"
  input Env.Cache cache;
  input Env.Env env;
  input DAE.Exp filenameprefix;
  input Interactive.SymbolTable st;
  input Ceval.Msg msg;
  output Env.Cache outCache;
  output String outString;
algorithm
  (outCache,Values.STRING(outString),_) := Ceval.ceval(cache, env, filenameprefix, true, SOME(st),msg);
end extractFilePrefix;

public function cevalAstExp
"function: cevalAstExp
  Part of meta-programming using CODE.
  This function evaluates a piece of Expression AST, replacing Eval(variable)
  with the value of the variable, given that it is of type \"Expression\".

  Example: y = Code(1 + x)
           2 + 5  ( x + Eval(y) )  =>   2 + 5  ( x + 1 + x )"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Absyn.Exp outExp;
algorithm
  (outCache,outExp) :=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      Absyn.Exp e,e1_1,e2_1,e1,e2,e_1,cond_1,then_1,else_1,cond,then_,else_,exp,e3_1,e3;
      list<Env.Frame> env;
      Absyn.Operator op;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Ceval.Msg msg;
      list<tuple<Absyn.Exp, Absyn.Exp>> nest_1,nest;
      Absyn.ComponentRef cr;
      Absyn.FunctionArgs fa;
      list<Absyn.Exp> expl_1,expl;
      Env.Cache cache;
      DAE.Exp daeExp;
      list<list<Absyn.Exp>> lstExpl_1,lstExpl;

    case (cache,_,(e as Absyn.INTEGER(value = _)),_,_,_,info) then (cache,e);
    case (cache,_,(e as Absyn.REAL(value = _)),_,_,_,info) then (cache,e);
    case (cache,_,(e as Absyn.CREF(componentRef = _)),_,_,_,info) then (cache,e);
    case (cache,_,(e as Absyn.STRING(value = _)),_,_,_,info) then (cache,e);
    case (cache,_,(e as Absyn.BOOL(value = _)),_,_,_,info) then (cache,e);
    
    case (cache,env,Absyn.BINARY(exp1 = e1,op = op,exp2 = e2),impl,st,msg,info)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg, info);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg, info);
      then
        (cache,Absyn.BINARY(e1_1,op,e2_1));
    
    case (cache,env,Absyn.UNARY(op = op,exp = e),impl,st,msg,info)
      equation
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg, info);
      then
        (cache,Absyn.UNARY(op,e_1));
    
    case (cache,env,Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2),impl,st,msg,info)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg, info);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg, info);
      then
        (cache,Absyn.LBINARY(e1_1,op,e2_1));
    
    case (cache,env,Absyn.LUNARY(op = op,exp = e),impl,st,msg,info)
      equation
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg, info);
      then
        (cache,Absyn.LUNARY(op,e_1));
    
    case (cache,env,Absyn.RELATION(exp1 = e1,op = op,exp2 = e2),impl,st,msg,info)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg, info);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg, info);
      then
        (cache,Absyn.RELATION(e1_1,op,e2_1));
    
    case (cache,env,Absyn.IFEXP(ifExp = cond,trueBranch = then_,elseBranch = else_,elseIfBranch = nest),impl,st,msg,info)
      equation
        (cache,cond_1) = cevalAstExp(cache,env, cond, impl, st, msg, info);
        (cache,then_1) = cevalAstExp(cache,env, then_, impl, st, msg, info);
        (cache,else_1) = cevalAstExp(cache,env, else_, impl, st, msg, info);
        (cache,nest_1) = cevalAstExpexpList(cache,env, nest, impl, st, msg, info);
      then
        (cache,Absyn.IFEXP(cond_1,then_1,else_1,nest_1));
    
    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "Eval",subscripts = {}),functionArgs = Absyn.FUNCTIONARGS(args = {e},argNames = {})),impl,st,msg,info)
      equation
        (cache,daeExp,_,_) = Static.elabExp(cache, env, e, impl, st, true, Prefix.NOPRE(), info);
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp)),_) = Ceval.ceval(cache, env, daeExp, impl, st, msg);
      then
        (cache,exp);
    
    case (cache,env,(e as Absyn.CALL(function_ = cr,functionArgs = fa)),_,_,msg,info) then (cache,e);
    
    case (cache,env,Absyn.ARRAY(arrayExp = expl),impl,st,msg,info)
      equation
        (cache,expl_1) = cevalAstExpList(cache,env, expl, impl, st, msg, info);
      then
        (cache,Absyn.ARRAY(expl_1));
    
    case (cache,env,Absyn.MATRIX(matrix = lstExpl),impl,st,msg,info)
      equation
        (cache,lstExpl_1) = cevalAstExpListList(cache, env, lstExpl, impl, st, msg, info);
      then
        (cache,Absyn.MATRIX(lstExpl_1));
    
    case (cache,env,Absyn.RANGE(start = e1,step = SOME(e2),stop = e3),impl,st,msg,info)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg, info);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg, info);
        (cache,e3_1) = cevalAstExp(cache,env, e3, impl, st, msg, info);
      then
        (cache,Absyn.RANGE(e1_1,SOME(e2_1),e3_1));
    
    case (cache,env,Absyn.RANGE(start = e1,step = NONE(),stop = e3),impl,st,msg,info)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg, info);
        (cache,e3_1) = cevalAstExp(cache,env, e3, impl, st, msg, info);
      then
        (cache,Absyn.RANGE(e1_1,NONE(),e3_1));
    
    case (cache,env,Absyn.TUPLE(expressions = expl),impl,st,msg,info)
      equation
        (cache,expl_1) = cevalAstExpList(cache,env, expl, impl, st, msg, info);
      then
        (cache,Absyn.TUPLE(expl_1));
    
    case (cache,env,Absyn.END(),_,_,msg,info) then (cache,Absyn.END());
    
    case (cache,env,(e as Absyn.CODE(code = _)),_,_,msg,info) then (cache,e);

  end matchcontinue;
end cevalAstExp;

public function cevalAstExpList
"function: cevalAstExpList
  List version of cevalAstExp"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm
  (outCache,outAbsynExpLst) :=
  match (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      list<Env.Frame> env;
      Ceval.Msg msg;
      Absyn.Exp e_1,e;
      list<Absyn.Exp> res,es;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Env.Cache cache;
    
    case (cache,env,{},_,_,msg,info) then (cache,{});
    
    case (cache,env,(e :: es),impl,st,msg,info)
      equation
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg, info);
        (cache,res) = cevalAstExpList(cache,env, es, impl, st, msg, info);
      then
        (cache,e :: res);
  end match;
end cevalAstExpList;

protected function cevalAstExpListList "function: cevalAstExpListList"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<list<Absyn.Exp>> inAbsynExpLstLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<list<Absyn.Exp>> outAbsynExpLstLst;
algorithm
  (outCache,outAbsynExpLstLst) :=
  match (inCache,inEnv,inAbsynExpLstLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      list<Env.Frame> env;
      Ceval.Msg msg;
      list<Absyn.Exp> e_1,e;
      list<list<Absyn.Exp>> res,es;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Env.Cache cache;
    
    case (cache,env,{},_,_,msg,info) then (cache,{});
    
    case (cache,env,(e :: es),impl,st,msg,info)
      equation
        (cache,e_1) = cevalAstExpList(cache,env, e, impl, st, msg, info);
        (cache,res) = cevalAstExpListList(cache,env, es, impl, st, msg, info);
      then
        (cache,e :: res);
  end match;
end cevalAstExpListList;

protected function cevalAstExpexpList
"function: cevalAstExpexpList
  For IFEXP"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<tuple<Absyn.Exp, Absyn.Exp>> inTplAbsynExpAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<tuple<Absyn.Exp, Absyn.Exp>> outTplAbsynExpAbsynExpLst;
algorithm
  (outCache,outTplAbsynExpAbsynExpLst) :=
  match (inCache,inEnv,inTplAbsynExpAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      Ceval.Msg msg;
      Absyn.Exp e1_1,e2_1,e1,e2;
      list<tuple<Absyn.Exp, Absyn.Exp>> res,xs;
      list<Env.Frame> env;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Env.Cache cache;
    case (cache,_,{},_,_,msg,info) then (cache,{});
    case (cache,env,((e1,e2) :: xs),impl,st,msg,info)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg, info);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg, info);
        (cache,res) = cevalAstExpexpList(cache,env, xs, impl, st, msg, info);
      then
        (cache,(e1_1,e2_1) :: res);
  end match;
end cevalAstExpexpList;

public function cevalAstElt
"function: cevalAstElt
  Evaluates an ast constructor for Element nodes, e.g.
  Code(parameter Real x=1;)"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Element inElement;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Absyn.Element outElement;
algorithm
  (outCache,outElement) :=
  match (inCache,inEnv,inElement,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Absyn.ComponentItem> citems_1,citems;
      list<Env.Frame> env;
      Boolean f,isReadOnly,impl;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter io;
      String id,file;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tp;
      Absyn.Info info;
      Integer sline,scolumn,eline,ecolumn;
      Option<Absyn.ConstrainClass> c;
      Option<Interactive.SymbolTable> st;
      Ceval.Msg msg;
      Env.Cache cache;
    case (cache,env,Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = io,name = id,specification = Absyn.COMPONENTS(attributes = attr,typeSpec = tp,components = citems),info = (info as Absyn.INFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scolumn,lineNumberEnd = eline,columnNumberEnd = ecolumn)),constrainClass = c),impl,st,msg)
      equation
        (cache,citems_1) = cevalAstCitems(cache,env, citems, impl, st, msg, info);
      then
        (cache,Absyn.ELEMENT(f,r,io,id,Absyn.COMPONENTS(attr,tp,citems_1),info,c));
  end match;
end cevalAstElt;

protected function cevalAstCitems
"function: cevalAstCitems
  Helper function to cevalAstElt."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm
  (outCache,outAbsynComponentItemLst) :=
  matchcontinue (inCache,inEnv,inAbsynComponentItemLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      Ceval.Msg msg;
      list<Absyn.ComponentItem> res,xs;
      Option<Absyn.Modification> modopt_1,modopt;
      list<Absyn.Subscript> ad_1,ad;
      list<Env.Frame> env;
      String id;
      Option<Absyn.Exp> cond;
      Option<Absyn.Comment> cmt;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Absyn.ComponentItem x;
      Env.Cache cache;
    case (cache,_,{},_,_,msg,info) then (cache,{});
    case (cache,env,(Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = ad,modification = modopt),condition = cond,comment = cmt) :: xs),impl,st,msg,info) /* If one component fails, the rest should still succeed */
      equation
        (cache,res) = cevalAstCitems(cache,env, xs, impl, st, msg, info);
        (cache,modopt_1) = cevalAstModopt(cache,env, modopt, impl, st, msg, info);
        (cache,ad_1) = cevalAstArraydim(cache,env, ad, impl, st, msg, info);
      then
        (cache,Absyn.COMPONENTITEM(Absyn.COMPONENT(id,ad_1,modopt_1),cond,cmt) :: res);
    case (cache,env,(x :: xs),impl,st,msg,info) /* If one component fails, the rest should still succeed */
      equation
        (cache,res) = cevalAstCitems(cache,env, xs, impl, st, msg, info);
      then
        (cache,x :: res);
  end matchcontinue;
end cevalAstCitems;

protected function cevalAstModopt
"function: cevalAstModopt"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Option<Absyn.Modification> inAbsynModificationOption;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Option<Absyn.Modification> outAbsynModificationOption;
algorithm
  (outCache,outAbsynModificationOption) :=
  match (inCache,inEnv,inAbsynModificationOption,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      Absyn.Modification res,mod;
      list<Env.Frame> env;
      Boolean st;
      Option<Interactive.SymbolTable> impl;
      Ceval.Msg msg;
      Env.Cache cache;
    case (cache,env,SOME(mod),st,impl,msg,info)
      equation
        (cache,res) = cevalAstModification(cache,env, mod, st, impl, msg, info);
      then
        (cache,SOME(res));
    case (cache,env,NONE(),_,_,msg,info) then (cache,NONE());
  end match;
end cevalAstModopt;

protected function cevalAstModification "function: cevalAstModification
  This function evaluates Eval(variable) inside an AST Modification  and replaces
  the Eval operator with the value of the variable if it has a type \"Expression\""
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Modification inModification;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Absyn.Modification outModification;
algorithm
  (outCache,outModification) :=
  match (inCache,inEnv,inModification,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      Absyn.Exp e_1,e;
      list<Absyn.ElementArg> eltargs_1,eltargs;
      list<Env.Frame> env;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Ceval.Msg msg;
      Env.Cache cache;
      Absyn.Info info2;
    case (cache,env,Absyn.CLASSMOD(elementArgLst = eltargs,eqMod = Absyn.EQMOD(e,info2)),impl,st,msg,info)
      equation
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg, info);
        (cache,eltargs_1) = cevalAstEltargs(cache,env, eltargs, impl, st, msg, info);
      then
        (cache,Absyn.CLASSMOD(eltargs_1,Absyn.EQMOD(e_1,info2)));
    case (cache,env,Absyn.CLASSMOD(elementArgLst = eltargs,eqMod = Absyn.NOMOD()),impl,st,msg,info)
      equation
        (cache,eltargs_1) = cevalAstEltargs(cache,env, eltargs, impl, st, msg, info);
      then
        (cache,Absyn.CLASSMOD(eltargs_1,Absyn.NOMOD()));
  end match;
end cevalAstModification;

protected function cevalAstEltargs "function: cevalAstEltargs
  Helper function to cevalAstModification."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm
  (outCache,outAbsynElementArgLst):=
  matchcontinue (inCache,inEnv,inAbsynElementArgLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      list<Env.Frame> env;
      Ceval.Msg msg;
      Absyn.Modification mod_1,mod;
      list<Absyn.ElementArg> res,args;
      Boolean b,impl;
      Absyn.Each e;
      Absyn.ComponentRef cr;
      Option<String> stropt;
      Option<Interactive.SymbolTable> st;
      Absyn.ElementArg m;
      Env.Cache cache;
      Absyn.Info mod_info;

    case (cache,env,{},_,_,msg,info) then (cache,{});
    /* TODO: look through redeclarations for Eval(var) as well */
    case (cache,env,(Absyn.MODIFICATION(finalPrefix = b,eachPrefix = e,componentRef = cr,modification = SOME(mod),comment = stropt, info = mod_info) :: args),impl,st,msg,info)
      equation
        (cache,mod_1) = cevalAstModification(cache,env, mod, impl, st, msg, info);
        (cache,res) = cevalAstEltargs(cache,env, args, impl, st, msg, info);
      then
        (cache,Absyn.MODIFICATION(b,e,cr,SOME(mod_1),stropt,mod_info) :: res);
    case (cache,env,(m :: args),impl,st,msg,info) /* TODO: look through redeclarations for Eval(var) as well */
      equation
        (cache,res) = cevalAstEltargs(cache,env, args, impl, st, msg, info);
      then
        (cache,m :: res);
  end matchcontinue;
end cevalAstEltargs;

protected function cevalAstArraydim "function: cevalAstArraydim
  Helper function to cevaAstCitems"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ArrayDim inArrayDim;
  input Boolean inBoolean;
  input Option<Interactive.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Absyn.ArrayDim outArrayDim;
algorithm
  (outCache,outArrayDim) :=
  match (inCache,inEnv,inArrayDim,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      list<Env.Frame> env;
      Ceval.Msg msg;
      list<Absyn.Subscript> res,xs;
      Boolean impl;
      Option<Interactive.SymbolTable> st;
      Absyn.Exp e_1,e;
      Env.Cache cache;
    case (cache,env,{},_,_,msg,info) then (cache,{});
    case (cache,env,(Absyn.NOSUB() :: xs),impl,st,msg,info)
      equation
        (cache,res) = cevalAstArraydim(cache,env, xs, impl, st, msg, info);
      then
        (cache,Absyn.NOSUB() :: res);
    case (cache,env,(Absyn.SUBSCRIPT(subscript = e) :: xs),impl,st,msg,info)
      equation
        (cache,res) = cevalAstArraydim(cache,env, xs, impl, st, msg, info);
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg, info);
      then
        (cache,Absyn.SUBSCRIPT(e) :: res);
  end match;
end cevalAstArraydim;

public function checkModel "function: checkModel
 checks a model and returns number of variables and equations"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className;
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable) :=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg)
    local
      list<SCode.Element> p_1,sp;
      DAE.DAElist dae;
      list<Env.Frame> env;
      list<Interactive.InstantiatedClass> ic;
      BackendDAE.BackendDAE dlow,dlow1;
      Interactive.SymbolTable st;
      Absyn.Program p,ptot;
      list<Interactive.Variable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Env.Cache cache;
      Integer eqnSize,varSize,simpleEqnSize,eqnSize1;
      String errorMsg,warnings,eqnSizeStr,varSizeStr,retStr,classNameStr,simpleEqnSizeStr;
      BackendDAE.EquationArray eqns,eqns1;
      Boolean partialPrefix,finalPrefix,encapsulatedPrefix,strEmpty;
      Absyn.Restriction restriction;
      Absyn.Info info;
      DAE.FunctionTree funcs;
      BackendDAE.Variables vars;
      BackendDAE.IncidenceMatrix m;
      Absyn.Class c;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    
    // handle normal models
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        Error.clearMessages() "Clear messages";
        Print.clearErrorBuf() "Clear error buffer";
        (cache,env,dae,st) = runFrontEnd(cache,env,className,st,false);

        //UnitParserExt.clear();
        //UnitAbsynBuilder.registerUnits(ptot);
        //UnitParserExt.commit();

        dae  = DAEUtil.transformationsBeforeBackend(cache,env, dae);
        // adrpo: do not store instantiated class as we don't use it later!
        // ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dae,env));
        funcs = Env.getFunctionTree(cache);
        (dlow as BackendDAE.DAE({syst},shared)) = BackendDAECreate.lower(dae, funcs, false) "no dummy state" ;
        Debug.fcall(Flags.DUMP_DAE_LOW, BackendDump.dump, dlow);
        eqns = BackendEquation.daeEqns(syst);
        eqnSize = BackendDAEUtil.equationSize(eqns);
        vars = BackendVariable.daeVars(syst);
        varSize = BackendVariable.varsSize(vars);
        (eqnSize,varSize) = subtractDummy(vars,eqnSize,varSize);
        (m,_) = BackendDAEUtil.incidenceMatrix(syst, shared, BackendDAE.NORMAL());
        simpleEqnSize = BackendDAEOptimize.countSimpleEquations(dlow,m);
        eqnSizeStr = intString(eqnSize);
        varSizeStr = intString(varSize);
        simpleEqnSizeStr = intString(simpleEqnSize);

        classNameStr = Absyn.pathString(className);
        warnings = Error.printMessagesStr();
        retStr=stringAppendList({"Check of ",classNameStr," completed successfully.\n\n",warnings,"\nClass ",classNameStr," has ",eqnSizeStr," equation(s) and ",
          varSizeStr," variable(s).\n",simpleEqnSizeStr," of these are trivial equation(s).\n"});
      then
        (cache,Values.STRING(retStr),st);

    // handle functions
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p)),msg)
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
        warnings = Error.printMessagesStr();
        // TODO: add a check if warnings is empty, if so then remove \n... --> warnings,"\nClass  <--- line below.
        retStr=stringAppendList({"Check of ",classNameStr," completed successfully.\n\n",warnings,"\n"});
      then
        (cache,Values.STRING(retStr),st);

    case (cache,env,className,st as Interactive.SYMBOLTABLE(ast=p), _)
      equation
        classNameStr = Absyn.pathString(className);
        false = Interactive.existClass(Absyn.pathToCref(className), p);
        errorMsg = "Unknown model in checkModel: " +& classNameStr +& "\n";
      then
        (cache,Values.STRING(errorMsg),st);

    // errors
    case (cache,env,className,st,_)
      equation
      classNameStr = Absyn.pathString(className);
      errorMsg = Error.printMessagesStr();
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
    
    case (inString, selector)
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
    case(inTpl) then inTpl;

    case((Absyn.CLASS(name,p,f,e,r,cdef,Absyn.INFO(fname,ro,i1,i2,i3,i4,ts)),NONE(),path))
      equation
        true = Absyn.pathEqual(Absyn.IDENT(name),path);
        ts =Absyn.setTimeStampBool(ts,false);
      then ((Absyn.CLASS(name,p,f,e,r,cdef,Absyn.INFO(fname,ro,i1,i2,i3,i4,ts)),NONE(),path));
    case(inTpl) then inTpl;
  end matchcontinue;
end setBuildTimeVisitor;

protected function extractNoCleanCommand "Function: extractNoCleanCommand"
input Values.Value val;
output String outString;
algorithm
  outString := match (val)
    case(Values.BOOL(true)) then "noclean";
    else "";
  end match;
end extractNoCleanCommand;

protected function getWithinStatement " function getWithinStatement
To get a correct Within-path with unknown input-path."
  input Absyn.Path ip;
  output Absyn.Within op;
algorithm op :=  matchcontinue(ip)
  local Absyn.Path path;
  case(path) equation path = Absyn.stripLast(path); then Absyn.WITHIN(path);
  case(path) then Absyn.TOP();
end matchcontinue;
end getWithinStatement;

protected function compileOrNot " function compileOrNot
This function compares last-build-time vs last-edit-time, and if we have edited since we built last time
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
    case(vars,eqnSize,varSize) equation
      (_,_) = BackendVariable.getVar(ComponentReference.makeCrefIdent("$dummy",DAE.T_UNKNOWN_DEFAULT,{}),vars);
    then (eqnSize-1,varSize-1);
    case(vars,eqnSize,varSize) then (eqnSize,varSize);
  end matchcontinue;
end subtractDummy;

protected function dumpXMLDAE "function dumpXMLDAE
 author: fildo
 This function outputs the DAE system corresponding to a specific model."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Values.Value> vals;
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Interactive.SymbolTable outInteractiveSymbolTable3;
  output String xml_filename "initFileName";
  output String xml_contents;
algorithm
  (outCache,outInteractiveSymbolTable3,xml_filename,xml_contents) :=
  matchcontinue (inCache,inEnv,vals,inInteractiveSymbolTable,inMsg)
    local
      Boolean cdToTemp;
      String cname_str,filenameprefix,oldDir,translationLevel,compileDir;
      list<Interactive.InstantiatedClass> ic_1,ic;
      list<Interactive.Variable> iv;
      list<Interactive.CompiledCFunction> cf;
      list<Env.Frame> env;
      Absyn.Path classname;
      Absyn.Program p;
      BackendDAE.BackendDAE dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      Env.Cache cache;
      Boolean addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals;
      Interactive.SymbolTable st,st_1;
      Ceval.Msg msg;
      array<Integer> ass1,ass2;
      DAE.DAElist dae_1,dae;
      BackendDAE.IncidenceMatrix m,mT;
      Option<BackendDAE.IncidenceMatrix> om,omT;
      list<SCode.Element> p_1,sp;
      list<list<Integer>> comps;
      DAE.FunctionTree funcs,funcs1;
    
    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="flat"),Values.BOOL(addOriginalIncidenceMatrix),Values.BOOL(addSolvingInfo),Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),Values.STRING(filenameprefix),Values.BOOL(cdToTemp)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        //translationLevel=DAE.SCONST(string="flat")
        Error.clearMessages() "Clear messages";
        oldDir = System.pwd();
        compileDir = changeToTempDirectory(cdToTemp);
        filenameprefix = Util.if_(filenameprefix ==& "<default>", Absyn.pathString(classname), filenameprefix);
        cname_str = Absyn.pathString(classname);
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env,_,dae_1) = Inst.instantiateClass(cache, InnerOuter.emptyInstHierarchy, p_1, classname);
        dae = DAEUtil.transformationsBeforeBackend(cache,env,dae_1);
        funcs = Env.getFunctionTree(cache);
        dlow = BackendDAECreate.lower(dae, funcs, true); //Verificare cosa fa
        dlow_1 = BackendDAEUtil.preOptimiseBackendDAE(dlow,NONE());
        dlow_1 = BackendDAECreate.findZeroCrossings(dlow_1);
        xml_filename = stringAppendList({filenameprefix,".xml"});
        Print.clearBuf();
        XMLDump.dumpBackendDAE(dlow_1,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals);
        xml_contents = Print.getString();
        Print.clearBuf();
        System.writeFile(xml_filename,xml_contents);
        compileDir = Util.if_(Config.getRunningTestsuite(),"",compileDir);
      then
        (cache,st,xml_contents,stringAppendList({"The model has been dumped to xml file: ",compileDir,xml_filename}));
      
    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="optimiser"),Values.BOOL(addOriginalIncidenceMatrix),Values.BOOL(addSolvingInfo),Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),Values.STRING(filenameprefix),Values.BOOL(cdToTemp)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        //translationLevel=DAE.SCONST(string="optimiser")
        //asInSimulationCode==false => it's NOT necessary to do all the translation's steps before dumping with xml
        Error.clearMessages() "Clear messages";
        oldDir = System.pwd();
        compileDir = changeToTempDirectory(cdToTemp);
        cname_str = Absyn.pathString(classname);
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env,_,dae_1) = Inst.instantiateClass(cache, InnerOuter.emptyInstHierarchy, p_1, classname);
        dae = DAEUtil.transformationsBeforeBackend(cache,env,dae_1);
        funcs = Env.getFunctionTree(cache);
        dlow = BackendDAECreate.lower(dae, funcs, true); //Verificare cosa fa
        dlow_1 = BackendDAEUtil.preOptimiseBackendDAE(dlow,NONE());
        dlow_1 = BackendDAEUtil.transformBackendDAE(dlow_1,NONE(),NONE(),NONE());
        dlow_1 = BackendDAECreate.findZeroCrossings(dlow_1);
        xml_filename = stringAppendList({filenameprefix,".xml"});
        Print.clearBuf();
        XMLDump.dumpBackendDAE(dlow_1,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals);
        xml_contents = Print.getString();
        Print.clearBuf();
        System.writeFile(xml_filename,xml_contents);
        compileDir = Util.if_(Config.getRunningTestsuite(),"",compileDir);
      then
        (cache,st,xml_contents,stringAppendList({"The model has been dumped to xml file: ",compileDir,xml_filename}));
      
    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="backEnd"),Values.BOOL(addOriginalIncidenceMatrix),Values.BOOL(addSolvingInfo),Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),Values.STRING(filenameprefix),Values.BOOL(cdToTemp)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        //translationLevel=DAE.SCONST(string="backEnd")
        //asInSimulationCode==true => it's necessary to do all the translation's steps before dumping with xml
        Error.clearMessages() "Clear messages";
        oldDir = System.pwd();
        compileDir = changeToTempDirectory(cdToTemp);
        cname_str = Absyn.pathString(classname);
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env,_,dae_1) = Inst.instantiateClass(cache, InnerOuter.emptyInstHierarchy, p_1, classname);
        dae = DAEUtil.transformationsBeforeBackend(cache,env,dae_1);
        funcs = Env.getFunctionTree(cache);
        dlow = BackendDAECreate.lower(dae, funcs, true);
        indexed_dlow = BackendDAEUtil.getSolvedSystem(cache, env, dlow, NONE(), NONE(), NONE(), NONE());
        xml_filename = stringAppendList({filenameprefix,".xml"});
        Print.clearBuf();
        XMLDump.dumpBackendDAE(indexed_dlow,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals);
        xml_contents = Print.getString();
        Print.clearBuf();
        System.writeFile(xml_filename,xml_contents);
        compileDir = Util.if_(Config.getRunningTestsuite(),"",compileDir);
      then
        (cache,st,xml_contents,stringAppendList({"The model has been dumped to xml file: ",compileDir,xml_filename}));
    
  end matchcontinue;
end dumpXMLDAE;

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

    case (inmodel,p,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName, _, _, parts)),b)
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
    case (inPath, b, p)
      equation
        cdef = Interactive.getPathedClassInProgram(inPath, p);
        strlst = getClassnamesInClassList(inPath, p, cdef, b);
        result_path_lst = List.map1(strlst, joinPaths, inPath);
        result = List.flatten(List.map2(result_path_lst, getAllClassPathsRecursive, b, p));
      then
        inPath::result;
    case (inPath, b, _)
      equation
        parent_string = Absyn.pathString(inPath);
        s = Error.printMessagesStr();
        s = stringAppendList({parent_string,"->","PROBLEM GETTING CLASS PATHS: ", s, "\n"});
        print(s);
      then {};
  end matchcontinue;
end getAllClassPathsRecursive;

protected function filterLib
  input Absyn.Path path;
  output Boolean b;
  Boolean b1, b2, b3;
algorithm
  b1 := not Absyn.pathPrefixOf(Absyn.QUALIFIED("Modelica", Absyn.IDENT("Media")), path);
  b2 := not Absyn.pathPrefixOf(Absyn.QUALIFIED("Modelica", Absyn.IDENT("Fluid")), path);
  b3 := not Absyn.pathPrefixOf(
              Absyn.QUALIFIED("Modelica", 
                Absyn.QUALIFIED("Mechanics",
                  Absyn.QUALIFIED("MultiBody",
                    Absyn.QUALIFIED("Examples",
                      Absyn.QUALIFIED("Loops",
                        Absyn.QUALIFIED("Utilities",
                          Absyn.IDENT("EngineV6_analytic"))))))), path);
  b  := b1 and b2; // and b3;
end filterLib;

public function checkAllModelsRecursive
"@author adrpo
 checks all models and returns number of variables and equations"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className;
  input Boolean inCheckProtected;
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.SymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inEnv,className,inCheckProtected,inInteractiveSymbolTable,inMsg)
    local
      list<Absyn.Path> allClassPaths;
      list<SCode.Element> sp;
      list<Interactive.InstantiatedClass> ic;
      Interactive.SymbolTable st;
      Absyn.Program p;
      list<Interactive.Variable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Env.Cache cache;
      String ret;
      list<Env.Frame> env;
      Boolean b;
    
    case (cache,env,className,b,(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        allClassPaths = getAllClassPathsRecursive(className, b, p);
        // allClassPaths = List.select(allClassPaths, filterLib);
        // allClassPaths = listReverse(allClassPaths);
        print("Number of classes to check: " +& intString(listLength(allClassPaths)) +& "\n");
        // print ("All paths: \n" +& stringDelimitList(List.map(allClassPaths, Absyn.pathString), "\n") +& "\n");
        checkAll(cache, env, allClassPaths, st, msg);
        ret = "Number of classes checked: " +& intString(listLength(allClassPaths));
      then
        (cache,Values.STRING(ret),st);
    
    case (cache,env,className,b,(st as Interactive.SYMBOLTABLE(ast = p)),msg)
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
    case (inStr)
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
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
algorithm
  _ := matchcontinue (inCache,inEnv,allClasses,inInteractiveSymbolTable,inMsg)
    local
      list<Absyn.Path> rest;
      Absyn.Path className;
      list<SCode.Element> sp;
      list<Interactive.InstantiatedClass> ic;
      Interactive.SymbolTable st;
      Absyn.Program p;
      list<Interactive.Variable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Env.Cache cache;
      String  str, s;
      list<Env.Frame> env;
      Real t1, t2, elapsedTime;
      Absyn.ComponentRef cr;
      Absyn.Class c;
    case (cache,env,{},_,_) then ();

    case (cache,env,className::rest,(st as Interactive.SYMBOLTABLE(ast = p)),msg)
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

    case (cache,env,className::rest,(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        c = Interactive.getPathedClassInProgram(className, p);
        print("Checking skipped: " +& Dump.unparseClassAttributesStr(c) +& " " +& Absyn.pathString(className) +& "... \n");
        checkAll(cache, env, rest, st, msg);
      then
        ();
  end matchcontinue;
end checkAll;

public function buildModelBeast "function buildModelBeast
 copy & pasted by: Otto
 translates and builds the model by running compiler script on the generated makefile"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Values.Value> vals;
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Interactive.SymbolTable outInteractiveSymbolTable;  
  output String compileDir;
  output String outString1 "className";
  output String outString2 "method";
  output String outString4 "initFileName";
algorithm
  (outCache,outInteractiveSymbolTable,compileDir,outString1,outString2,outString4):=
  match (inCache,inEnv,vals,inInteractiveSymbolTable,inMsg)
    local
      Values.Value ret_val;
      Interactive.SymbolTable st,st_1,st2;
      BackendDAE.BackendDAE indexed_dlow_1;
      list<String> libs;
      String file_dir,method_str,filenameprefix,oldDir,s3;
      Absyn.Path classname;
      Absyn.Program p,p2;
      Absyn.Class cdef;
      list<Interactive.CompiledCFunction> cf;
      list<Env.Frame> env;
      Values.Value starttime,stoptime,interval,method,tolerance,fileprefix,storeInTemp,noClean,options;
      list<SCode.Element> sp;
      list<Interactive.InstantiatedClass> ic;
      list<Interactive.Variable> iv;
      Ceval.Msg msg;
      Absyn.Within win1;
      Env.Cache cache;
      Boolean cdToTemp;
      SimCode.SimulationSettings simSettings;
      Absyn.TimeStamp ts;
    
    // normal call
    case (cache,env,vals as {Values.CODE(Absyn.C_TYPENAME(classname)),starttime,stoptime,interval,tolerance, method,Values.STRING(filenameprefix),Values.BOOL(cdToTemp),noClean,options},(st as Interactive.SYMBOLTABLE(ast = p  as Absyn.PROGRAM(globalBuildTimes=ts))),msg)
      equation
        cdef = Interactive.getPathedClassInProgram(classname,p);
        Error.clearMessages() "Clear messages";
        oldDir = System.pwd();
        compileDir = changeToTempDirectory(cdToTemp);
        (cache,simSettings) = calculateSimulationSettings(cache,env,vals,st,msg);
        (cache,ret_val,st,indexed_dlow_1,libs,file_dir,_) 
          = translateModel(cache,env, classname, st, filenameprefix,true,SOME(simSettings));
        SimCode.SIMULATION_SETTINGS(method = method_str) = simSettings;
        //cname_str = Absyn.pathString(classname);
        //(cache,init_filename,starttime_r,stoptime_r,interval_r,tolerance_r,method_str,options_str,outputFormat_str) 
        //= calculateSimulationSettings(cache,env, exp, st, msg, cname_str);
        //SimCode.generateInitData(indexed_dlow_1, classname, filenameprefix, init_filename, starttime_r, stoptime_r, interval_r,tolerance_r,method_str,options_str,outputFormat_str);
        Debug.fprintln(Flags.DYN_LOAD, "buildModel: about to compile model " +& filenameprefix +& ", " +& file_dir);
        compileModel(filenameprefix, libs, file_dir, "", method_str);
        Debug.fprintln(Flags.DYN_LOAD, "buildModel: Compiling done.");
        // SimCodegen.generateMakefileBeast(makefilename, filenameprefix, libs, file_dir);
        win1 = getWithinStatement(classname);
        p2 = Absyn.PROGRAM({cdef},win1,ts);
        s3 = extractNoCleanCommand(noClean);
        compileModel(filenameprefix, libs, file_dir,s3,method_str);
        _ = System.cd(oldDir);
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
  dependencies := SimCode.getCalledFunctionsInFunction(functionName,funcs);
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

public function cevalGenerateFunction "function: cevalGenerateFunction
  Generates code for a given function name."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output String functionName;
algorithm
  (outCache,functionName) := matchcontinue (inCache,inEnv,inPath)
    local
      String pathstr;
      list<Env.Frame> env;
      Absyn.Path path;
      Env.Cache cache;
      DAE.Function mainFunction;
      list<DAE.Function> d;
      list<Absyn.Path> uniontypePaths,paths;
      list<DAE.Type> metarecordTypes;
      DAE.FunctionTree funcs;
    // template based translation
    case (cache, env, path)
      equation
        false = Flags.isSet(Flags.NO_GEN);
        false = Flags.isSet(Flags.GENERATE_CODE_CHEAT);
        
        (cache, mainFunction, d, metarecordTypes) = collectDependencies(cache, env, path);
        
        pathstr = generateFunctionName(path);
        SimCode.translateFunctions(pathstr, SOME(mainFunction), d, metarecordTypes, {});
        compileModel(pathstr, {}, "", "", "");
      then
        (cache, pathstr);

    // Cheat if we want to generate code for Main.main
    // * Don't do dependency analysis of what functions to generate; just generate all of them
    // * Don't generate extra code for unreferenced MetaRecord types (for external functions)
    //   This could be an annotation instead anyway.
    // * Don't compile the generated files
    case (cache, env, path)
      equation
        false = Flags.isSet(Flags.NO_GEN);
        true = Flags.isSet(Flags.GENERATE_CODE_CHEAT);
        funcs = Env.getFunctionTree(cache);
        // First check if the main function exists... If it does not it might be an interactive function...
        pathstr = generateFunctionName(path);
        
        // The list of functions is not ordered, so we need to filter out the main function...
        d = DAEUtil.getFunctionList(funcs);
        SimCode.translateFunctions(pathstr, NONE(), d, {}, {});
      then
        (cache, pathstr);

    case (cache, env, path)
      equation
        false = Flags.isSet(Flags.NO_GEN);
        (cache,false) = Static.isExternalObjectFunction(cache,env,path);
        pathstr = generateFunctionName(path);
        pathstr = stringAppend("/*- CevalScript.cevalGenerateFunction failed(", pathstr);
        pathstr = stringAppend(pathstr,")*/\n");
        Debug.fprint(Flags.FAILTRACE, pathstr);
      then
        fail();
  end matchcontinue;
end cevalGenerateFunction;

protected function generateFunctions
  input Env.Cache icache;
  input Env.Env ienv;
  input list<SCode.Element> isp;
  input list<tuple<String,list<String>>> iacc;
  output list<tuple<String,list<String>>> deps;
algorithm
  deps := match (icache,ienv,isp,iacc)
    local
      String name;
      list<String> names,dependencies;
      list<Absyn.Path> paths;
      list<SCode.Element> elementLst;
      DAE.FunctionTree funcs;
      list<DAE.Function> d;
      list<tuple<String,list<String>>> acc;
      list<SCode.Element> sp;
      Env.Cache cache;
      Env.Env env;

    case (cache,env,{},acc) then acc;
    case (cache,env,SCode.CLASS(name="OpenModelica")::sp,acc)
      equation
        acc = generateFunctions(cache,env,sp,acc);
      then acc;
    case (cache,env,SCode.CLASS(name=name,encapsulatedPrefix=SCode.ENCAPSULATED(),restriction=SCode.R_PACKAGE(),classDef=SCode.PARTS(elementLst=elementLst))::sp,acc)
      equation
        names = List.map(List.filterOnTrue(List.map(List.filterOnTrue(elementLst, SCode.elementIsClass), SCode.getElementClass), SCode.isFunction), SCode.className);
        paths = List.map1r(names,Absyn.makeQualifiedPathFromStrings,name);
        cache = instantiateDaeFunctions(cache, env, paths);
        funcs = Env.getFunctionTree(cache);
        d = List.map1(paths, DAEUtil.getNamedFunction, funcs);
        (_,(_,dependencies)) = DAEUtil.traverseDAEFunctions(d,Expression.traverseSubexpressionsHelper,(matchQualifiedCalls,{}));
        print(name +& " has dependencies: " +& stringDelimitList(dependencies,",") +& "\n");
        acc = (name,dependencies)::acc;
        dependencies = List.map1(dependencies,stringAppend,".h\"");
        dependencies = List.map1r(dependencies,stringAppend,"#include \"");
        SimCode.translateFunctions(name, NONE(), d, {}, dependencies);
        acc = generateFunctions(cache,env,sp,acc);
      then acc;
    case (cache,env,_::sp,acc)
      equation
        acc = generateFunctions(cache,env,sp,acc);
      then acc;
  end match;
end generateFunctions;

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
    case ((e as DAE.CALL(path = Absyn.FULLYQUALIFIED(Absyn.QUALIFIED(name,Absyn.IDENT(_))), attr = DAE.CALL_ATTR(builtin = false)),acc))
      equation
        acc = List.consOnTrue(not listMember(name,acc),name,acc);
      then ((e,acc));
        /*
    case ((e as DAE.METARECORDCALL(path = Absyn.QUALIFIED(name,Absyn.QUALIFIED(path=Absyn.IDENT(_)))),acc))
      equation
        acc = List.consOnTrue(not listMember(name,acc),name,acc);
      then ((e,acc));
      */
    case ((e as DAE.CREF(componentRef=cr,ty=DAE.T_FUNCTION_REFERENCE_FUNC(builtin=false)),acc))
      equation
        Absyn.QUALIFIED(name,Absyn.IDENT(_)) = ComponentReference.crefToPath(cr);
        acc = List.consOnTrue(not listMember(name,acc),name,acc);
      then ((e,acc));
    case itpl then itpl;
  end match;
end matchQualifiedCalls;

protected function instantiateDaeFunctions
  input Env.Cache icache;
  input Env.Env ienv;
  input list<Absyn.Path> ipaths;
  output Env.Cache outCache;
algorithm
  outCache := matchcontinue (icache,ienv,ipaths)
    local
      Absyn.Path path;
      Env.Cache cache; Env.Env env;
      list<Absyn.Path> paths;
    case (cache,env,{}) then cache;
    case (cache,env,path::paths)
      equation
        (cache,Util.SUCCESS()) = Static.instantiateDaeFunction(cache,env,path,false,NONE(),true);
        cache = instantiateDaeFunctions(cache,env,paths);
      then cache;
  end matchcontinue;
end instantiateDaeFunctions;

protected function getBasePathFromUri "Handle modelica:// URIs"
  input String scheme;
  input String iname;
  input String modelicaPath;
  input Boolean printError;
  output String basePath;
algorithm
  basePath := matchcontinue (scheme,iname,modelicaPath,printError)
    local
      list<String> mps,names;
      String gd,mp,bp,str,name;
    case ("modelica://",name,mp,_)
      equation
        names = System.strtok(name,".");
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        bp = findModelicaPath(mps,names);
      then bp;
    case ("file://",_,_,_) then "";
    case ("modelica://",name,mp,true)
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
  output String basePath;
algorithm
  basePath := matchcontinue (imps,names)
    local
      String mp;
      list<String> mps;
      
    case (mp::_,names)
      then findModelicaPath2(mp,names,false);
    case (_::mps,names)
      then findModelicaPath(mps,names);
  end matchcontinue;
end findModelicaPath;

protected function findModelicaPath2 "Handle modelica:// URIs"
  input String mp;
  input list<String> names;
  input Boolean b;
  output String basePath;
algorithm
  basePath := matchcontinue (mp,names,b)
    local
      list<String> mps,names;
      String gd,mp,bp,str,name;
    case (mp,name::names,_)
      equation
        true = System.directoryExists(mp +& "/" +& name);
      then findModelicaPath2(mp,names,true);
    case (mp,name::names,_)
      equation
        true = System.regularFileExists(mp +& "/" +& name +& ".mo");
      then mp;
      // This class is part of the current package.mo, or whatever... 
    case (mp,name::names,true)
      then mp;
  end matchcontinue;
end findModelicaPath2;

public function getFullPathFromUri
  input String uri;
  input Boolean printError;
  output String path;
protected
  String str1,str2,str3;
algorithm
  (str1,str2,str3) := System.uriToClassAndPath(uri);
  path := getBasePathFromUri(str1,str2,Settings.getModelicaPath(),printError) +& str3;
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
      String message;
      Integer id;
      Error.Severity severity;
      Error.MessageType ty;
      Absyn.Info info;
    case Error.TOTALMESSAGE(Error.MESSAGE(id,ty,severity,message),info)
      equation
        msgpath = Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("OpenModelica",Absyn.QUALIFIED("Scripting",Absyn.IDENT("ErrorMessage"))));
        tyVal = errorTypeToValue(ty);
        severityVal = errorLevelToValue(severity);
        infoVal = infoToValue(info);
        values = {infoVal,Values.STRING(message),tyVal,severityVal,Values.INTEGER(id)};
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
  input list<Interactive.Variable> vars;
  input list<Values.Value> acc;
  output list<Values.Value> ovars;
algorithm
  ovars := match (vars,acc)
    local
      list<Values.Value> res;
      list<Interactive.Variable> vs;
      String p;
    case ({},acc) then listReverse(acc);
    case (Interactive.IVAR(varIdent = "$echo") :: vs,acc)
      then getVariableNames(vs,acc);
    case (Interactive.IVAR(varIdent = p) :: vs,acc)
      then getVariableNames(vs,Values.CODE(Absyn.C_VARIABLENAME(Absyn.CREF_IDENT(p,{})))::acc);
  end match;
end getVariableNames;

protected function getAlgorithms
"function: getAlgorithms
  Counts the number of Algorithm sections in a class."
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
"function: getAlgorithmsInClassParts
  Helper function to getAlgorithms"
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
"function: getNthAlgorithm
  Returns the Nth Algorithm section from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output String outString;
  protected list<Absyn.ClassPart> algsList;
algorithm
  algsList := getAlgorithms(inClass);
  outString := getNthAlgorithmInClass(listGet(algsList, inInteger));
end getNthAlgorithm;

protected function getNthAlgorithmInClass
"function: getNthAlgorithmInClass
  Helper function to getNthAlgorithm."
  input Absyn.ClassPart inClassPart;
  output String outString;
algorithm
  outString := match (inClassPart)
    local
      String str;
      list<Absyn.AlgorithmItem> algs;
  case (Absyn.ALGORITHMS(contents = algs))
      equation
        str = Dump.unparseAlgorithmStrLst(0, algs, "\n");
      then
        str;
  end match; 
end getNthAlgorithmInClass;

protected function getInitialAlgorithms
"function: getInitialAlgorithms
  Counts the number of Initial Algorithm sections in a class."
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
"function: getInitialAlgorithmsInClassParts
  Helper function to getInitialAlgorithms"
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
"function: getNthInitialAlgorithm
  Returns the Nth Initial Algorithm section from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output String outString;
  protected list<Absyn.ClassPart> algsList;
algorithm
  algsList := getInitialAlgorithms(inClass);
  outString := getNthInitialAlgorithmInClass(listGet(algsList, inInteger));
end getNthInitialAlgorithm;

protected function getNthInitialAlgorithmInClass
"function: getNthInitialAlgorithmInClass
  Helper function to getNthInitialAlgorithm."
  input Absyn.ClassPart inClassPart;
  output String outString;
algorithm
  outString := match (inClassPart)
    local
      String str;
      list<Absyn.AlgorithmItem> algs;
  case (Absyn.INITIALALGORITHMS(contents = algs))
      equation
        str = Dump.unparseAlgorithmStrLst(0, algs, "\n");
      then
        str;
  end match; 
end getNthInitialAlgorithmInClass;

protected function getAlgorithmItemsCount
"function: getAlgorithmItemsCount
  Counts the number of Algorithm items in a class."
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
"function: getAlgorithmItemsCountInClassParts
  Helper function to getAlgorithmItemsCount"
 input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.ClassPart> xs;
      Absyn.ClassPart cp;
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
"function: getAlgorithmItemsCountInAlgorithmItems
  Helper function to getAlgorithmItemsCountInClassParts"
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
"function: getNthAlgorithmItem
  Returns the Nth Algorithm Item from a class."
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
"function: getNthAlgorithmItemInClassParts
  Helper function to getNthAlgorithmItem"
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
"function: getNthAlgorithmItemInAlgorithms
   This function takes an Algorithm list and an int
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
        str = Dump.unparseAlgorithmStr(0, Absyn.ALGORITHMITEM(alg, cmt, inf));
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
"function: getInitialAlgorithmItemsCount
  Counts the number of Initial Algorithm items in a class."
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
"function: getInitialAlgorithmItemsCountInClassParts
  Helper function to getInitialAlgorithmItemsCount"
 input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.ClassPart> xs;
      Absyn.ClassPart cp;
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
"function: getNthInitialAlgorithmItem
  Returns the Nth Initial Algorithm Item from a class."
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
"function: getNthInitialAlgorithmItemInClassParts
  Helper function to getNthInitialAlgorithmItem"
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
"function: getEquations
  Counts the number of Equation sections in a class."
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
"function: getEquationsInClassParts
  Helper function to getEquations"
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
"function: getNthEquation
  Returns the Nth Equation section from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output String outString;
  protected list<Absyn.ClassPart> eqsList;
algorithm
  eqsList := getEquations(inClass);
  outString := getNthEquationInClass(listGet(eqsList, inInteger));
end getNthEquation;

protected function getNthEquationInClass
"function: getNthEquationInClass
  Helper function to getNthEquation"
  input Absyn.ClassPart inClassPart;
  output String outString;
algorithm
  outString := match (inClassPart)
    local
      String str;
      list<Absyn.EquationItem> eqs;
  case (Absyn.EQUATIONS(contents = eqs))
      equation
        str = Dump.unparseEquationitemStrLst(0, eqs, ";\n");
      then
        str;
  end match; 
end getNthEquationInClass;

protected function getInitialEquations
"function: getInitialEquations
  Counts the number of Initial Equation sections in a class."
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
"function: getInitialEquationsInClassParts
  Helper function to getInitialEquations"
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
"function: getNthInitialEquation
  Returns the Nth Initial Equation section from a class."
  input Absyn.Class inClass;
  input Integer inInteger;
  output String outString;
  protected list<Absyn.ClassPart> eqsList;
algorithm
  eqsList := getInitialEquations(inClass);
  outString := getNthInitialEquationInClass(listGet(eqsList, inInteger));
end getNthInitialEquation;

protected function getNthInitialEquationInClass
"function: getNthInitialEquationInClass
  Helper function to getNthInitialEquation."
  input Absyn.ClassPart inClassPart;
  output String outString;
algorithm
  outString := match (inClassPart)
    local
      String str;
      list<Absyn.EquationItem> eqs;
  case (Absyn.INITIALEQUATIONS(contents = eqs))
      equation
        str = Dump.unparseEquationitemStrLst(0, eqs, ";\n");
      then
        str;
  end match; 
end getNthInitialEquationInClass;

protected function getEquationItemsCount
"function: getAlgorithmItemsCount
  Counts the number of Equation items in a class."
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
"function: getEquationItemsCountInClassParts
  Helper function to getEquationItemsCount"
 input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.EquationItem> eqs;
      list<Absyn.ClassPart> xs;
      Absyn.ClassPart cp;
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
"function: getEquationItemsCountInEquationItems
  Helper function to getEquationItemsCountInClassParts"
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
"function: getNthEquationItem
  Returns the Nth Equation Item from a class."
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
"function: getNthEquationItemInClassParts
  Helper function to getNthEquationItem"
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
"function: getNthEquationItemInEquations
   This function takes an Equation list and an int
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
        str = Dump.unparseEquationStr(0, eq);
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
"function: getInitialEquationItemsCount
  Counts the number of Initial Equation items in a class."
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
"function: getInitialEquationItemsCountInClassParts
  Helper function to getInitialEquationItemsCount"
 input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.EquationItem> eqs;
      list<Absyn.ClassPart> xs;
      Absyn.ClassPart cp;
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
"function: getNthInitialEquationItem
  Returns the Nth Initial Equation Item from a class."
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
"function: getNthInitialEquationItemInClassParts
  Helper function to getNthInitialEquationItem"
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
"function: getAnnotationCount
  Counts the number of Annotation sections in a class."
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm
  outInteger := match (inClass)
    local
      list<Absyn.ClassPart> parts;
      Integer count;
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        count = getAnnotationsInClassParts(parts);
      then
        count;
    // check also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        count = getAnnotationsInClassParts(parts);
      then
        count;
    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = _)) then 0;
  end match;
end getAnnotationCount;

protected function getAnnotationsInClassParts
"function: getAnnotationsInClassParts
  Helper function to getAnnotationCount"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ElementItem> els;
      list<Absyn.EquationItem> eqs;
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.ClassPart> xs;
      Absyn.ClassPart cp;
      Integer c1, c2, res;
    case (Absyn.PUBLIC(contents = els) :: xs)
      equation
        c1 = getAnnotationsInElementItems(els);
        c2 = getAnnotationsInClassParts(xs);
      then
        c1 + c2;
    case (Absyn.PROTECTED(contents = els) :: xs)
      equation
        c1 = getAnnotationsInElementItems(els);
        c2 = getAnnotationsInClassParts(xs);
      then
        c1 + c2;
/*        
    case (Absyn.CONSTRAINTS(contents = eqs) :: xs)
      equation
        c1 = getAnnotationsInEquationsItems(eqs);
        c2 = getAnnotationsInClassParts(xs);
      then
        c1 + c2;
*/        
    case (Absyn.EQUATIONS(contents = eqs) :: xs)
      equation
        c1 = getAnnotationsInEquationsItems(eqs);
        c2 = getAnnotationsInClassParts(xs);
      then
        c1 + c2;
    case (Absyn.INITIALEQUATIONS(contents = eqs) :: xs)
      equation
        c1 = getAnnotationsInEquationsItems(eqs);
        c2 = getAnnotationsInClassParts(xs);
      then
        c1 + c2;
    case (Absyn.ALGORITHMS(contents = algs) :: xs)
      equation
        c1 = getAnnotationsInAlgorithmsItems(algs);
        c2 = getAnnotationsInClassParts(xs);
      then
        c1 + c2;
    case (Absyn.INITIALALGORITHMS(contents = algs) :: xs)
      equation
        c1 = getAnnotationsInAlgorithmsItems(algs);
        c2 = getAnnotationsInClassParts(xs);
      then
        c1 + c2;
    case ((_ :: xs))
      equation
        res = getAnnotationsInClassParts(xs);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end getAnnotationsInClassParts;

protected function getAnnotationsInElementItems
"function: getAnnotationsInElementItems
  Helper function to getAnnotationCount"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynElementItemLst)
    local
      list<Absyn.ElementItem> xs;
      Integer c1, res;
    case (Absyn.ANNOTATIONITEM(annotation_ = Absyn.ANNOTATION(elementArgs = _)) :: xs)
      equation
        c1 = getAnnotationsInElementItems(xs);
      then
        c1 + 1;
    case ((_ :: xs))
      equation
        res = getAnnotationsInElementItems(xs);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end getAnnotationsInElementItems;

protected function getAnnotationsInEquationsItems
"function: getAnnotationsInEquationsItems
  Helper function to getAnnotationCount"
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynEquationItemLst)
    local
      list<Absyn.EquationItem> xs;
      Integer c1, res;
    case (Absyn.EQUATIONITEMANN(annotation_ = Absyn.ANNOTATION(elementArgs = _)) :: xs)
      equation
        c1 = getAnnotationsInEquationsItems(xs);
      then
        c1 + 1;
    case ((_ :: xs))
      equation
        res = getAnnotationsInEquationsItems(xs);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end getAnnotationsInEquationsItems;

protected function getAnnotationsInAlgorithmsItems
"function: getAnnotationsInAlgorithmsItems
  Helper function to getAnnotationCount"
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynAlgorithmItemLst)
    local
      list<Absyn.AlgorithmItem> xs;
      Integer c1, res;
    case (Absyn.ALGORITHMITEMANN(annotation_ = Absyn.ANNOTATION(elementArgs = _)) :: xs)
      equation
        c1 = getAnnotationsInAlgorithmsItems(xs);
      then
        c1 + 1;
    case ((_ :: xs))
      equation
        res = getAnnotationsInAlgorithmsItems(xs);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end getAnnotationsInAlgorithmsItems;

protected function getNthAnnotationString
"function: getNthAnnotationString
  Returns the Nth Annotation String from a class."
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
        str = getNthAnnotationStringInClassParts(parts,n);
      then
        str;
    // check also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),n)
      equation
        str = getNthAnnotationStringInClassParts(parts,n);
      then
        str;
  end match;
end getNthAnnotationString;

protected function getNthAnnotationStringInClassParts
"function: getNthAnnotationStringInClassParts
  Helper function to getNthAnnotationString"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynClassPartLst,inInteger)
    local
      String str;
      list<Absyn.ElementItem> els;
      list<Absyn.EquationItem> eqs;
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.ClassPart> xs;
      Integer n,c1,newn;
    case ((Absyn.PUBLIC(contents = els) :: xs),n)
      equation
        str = getNthAnnotationStringInElements(els, n);
      then
        str;
    case ((Absyn.PUBLIC(contents = els) :: xs),n) /* The rule above failed, subtract the number of annotations in the first section and try with the rest of the classparts */
      equation
        c1 = getAnnotationsInElementItems(els);
        newn = n - c1;
        str = getNthAnnotationStringInClassParts(xs, newn);
      then
        str;
    case ((Absyn.PROTECTED(contents = els) :: xs),n)
      equation
        str = getNthAnnotationStringInElements(els, n);
      then
        str;
    case ((Absyn.PROTECTED(contents = els) :: xs),n) /* The rule above failed, subtract the number of annotations in the first section and try with the rest of the classparts */
      equation
        c1 = getAnnotationsInElementItems(els);
        newn = n - c1;
        str = getNthAnnotationStringInClassParts(xs, newn);
      then
        str;
/*        
    case ((Absyn.CONSTRAINTS(contents = eqs) :: xs),n)
      equation
        str = getNthAnnotationStringInEquations(eqs, n);
      then
        str;
    case ((Absyn.CONSTRAINTS(contents = eqs) :: xs),n) // The rule above failed, subtract the number of annotations in the first section and try with the rest of the classparts 
      equation
        c1 = getAnnotationsInEquationsItems(eqs);
        newn = n - c1;
        str = getNthAnnotationStringInClassParts(xs, newn);
      then
        str;
*/        
    case ((Absyn.EQUATIONS(contents = eqs) :: xs),n)
      equation
        str = getNthAnnotationStringInEquations(eqs, n);
      then
        str;
    case ((Absyn.EQUATIONS(contents = eqs) :: xs),n) /* The rule above failed, subtract the number of annotations in the first section and try with the rest of the classparts */
      equation
        c1 = getAnnotationsInEquationsItems(eqs);
        newn = n - c1;
        str = getNthAnnotationStringInClassParts(xs, newn);
      then
        str;
    case ((Absyn.INITIALEQUATIONS(contents = eqs) :: xs),n)
      equation
        str = getNthAnnotationStringInEquations(eqs, n);
      then
        str;
    case ((Absyn.INITIALEQUATIONS(contents = eqs) :: xs),n) /* The rule above failed, subtract the number of annotations in the first section and try with the rest of the classparts */
      equation
        c1 = getAnnotationsInEquationsItems(eqs);
        newn = n - c1;
        str = getNthAnnotationStringInClassParts(xs, newn);
      then
        str;
    case ((Absyn.ALGORITHMS(contents = algs) :: xs),n)
      equation
        str = getNthAnnotationStringInAlgorithms(algs, n);
      then
        str;
    case ((Absyn.ALGORITHMS(contents = algs) :: xs),n) /* The rule above failed, subtract the number of annotations in the first section and try with the rest of the classparts */
      equation
        c1 = getAnnotationsInAlgorithmsItems(algs);
        newn = n - c1;
        str = getNthAnnotationStringInClassParts(xs, newn);
      then
        str;
    case ((Absyn.INITIALALGORITHMS(contents = algs) :: xs),n)
      equation
        str = getNthAnnotationStringInAlgorithms(algs, n);
      then
        str;
    case ((Absyn.INITIALALGORITHMS(contents = algs) :: xs),n) /* The rule above failed, subtract the number of annotations in the first section and try with the rest of the classparts */
      equation
        c1 = getAnnotationsInAlgorithmsItems(algs);
        newn = n - c1;
        str = getNthAnnotationStringInClassParts(xs, newn);
      then
        str;
    case ((_ :: xs),n)
      equation
        str = getNthAnnotationStringInClassParts(xs, n);
      then
        str;
  end matchcontinue;
end getNthAnnotationStringInClassParts;

protected function getNthAnnotationStringInElements
"function: getNthAnnotationStringInElements
   This function takes an Element list and an int
   and returns the nth annotation as string.
   If the number is larger than the number of annotations
   in the list, the function fails. Helper function to getNthAnnotationString."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynElementItemLst,inInteger)
    local
      String str;
      Absyn.Annotation ann;
      list<Absyn.ElementItem> xs;
      Integer newn,n;
    case ((Absyn.ANNOTATIONITEM(annotation_ = ann) :: xs), 1)
      equation
        str = Dump.unparseAnnotationOption(0, SOME(ann));
        str = stringAppend(str, ";");
        str = System.trim(str, " ");
      then
        str;
    case ((Absyn.ANNOTATIONITEM(annotation_ = Absyn.ANNOTATION(elementArgs = _)) :: xs),n)
      equation
        newn = n - 1;
        str = getNthAnnotationStringInElements(xs, newn);
      then
        str;
    case ((_ :: xs),n)
      equation
        str = getNthAnnotationStringInElements(xs, n);
      then
        str;
    case ({},_) then fail();
  end matchcontinue;
end getNthAnnotationStringInElements;

protected function getNthAnnotationStringInEquations
"function: getNthConnectionitemInEquations
   This function takes  an Equation list and an int
   and returns the nth connection as an Equation.
   If the number is larger than the number of connections
   in the list, the function fails. Helper function to getNthAnnotationString."
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynEquationItemLst,inInteger)
    local
      String str;
      Absyn.Annotation ann;
      list<Absyn.EquationItem> xs;
      Integer newn,n;
    case ((Absyn.EQUATIONITEMANN(annotation_ = ann) :: xs), 1)
      equation
        str = Dump.unparseAnnotationOption(0, SOME(ann));
        str = stringAppend(str, ";");
        str = System.trim(str, " ");
      then
        str;
    case ((Absyn.EQUATIONITEMANN(annotation_ = Absyn.ANNOTATION(elementArgs = _)) :: xs),n)
      equation
        newn = n - 1;
        str = getNthAnnotationStringInEquations(xs, newn);
      then
        str;
    case ((_ :: xs),n)
      equation
        str = getNthAnnotationStringInEquations(xs, n);
      then
        str;
    case ({},_) then fail();
  end matchcontinue;
end getNthAnnotationStringInEquations;

protected function getNthAnnotationStringInAlgorithms
"function: getNthAnnotationStringInAlgorithms
   This function takes an Algorithm list and an int
   and returns the nth annotation as String.
   If the number is larger than the number of annotations
   in the list, the function fails. Helper function to getNthAnnotationString."
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynAlgorithmItemLst,inInteger)
    local
      String str;
      Absyn.Annotation ann;
      list<Absyn.AlgorithmItem> xs;
      Integer newn,n;
    case ((Absyn.ALGORITHMITEMANN(annotation_ = ann) :: xs), 1)
      equation
        str = Dump.unparseAnnotationOption(0, SOME(ann));
        str = stringAppend(str, ";");
        str = System.trim(str, " ");
      then
        str;
    case ((Absyn.ALGORITHMITEMANN(annotation_ = Absyn.ANNOTATION(elementArgs = _)) :: xs),n)
      equation
        newn = n - 1;
        str = getNthAnnotationStringInAlgorithms(xs, newn);
      then
        str;
    case ((_ :: xs),n)
      equation
        str = getNthAnnotationStringInAlgorithms(xs, n);
      then
        str;
    case ({},_) then fail();
  end matchcontinue;
end getNthAnnotationStringInAlgorithms;

protected function getImportCount
"function: getImportCount
  Counts the number of Import sections in a class."
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
"function: getImportsInClassParts
  Helper function to getImportCount"
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
"function: getImportsInElementItems
  Helper function to getImportCount"
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
"function: getNthImport
  Returns the Nth Import String from a class."
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
"function: getNthImportInClassParts
  Helper function to getNthImport"
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
"function: getNthImportInElementItems
   This function takes an Element list and an int
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
"function: unparseNthImport
   helperfunction to getNthImport."
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

protected function evalCodeTypeName
  input Values.Value val;
  input Env.Env env;
  output Values.Value res;
algorithm
  res := matchcontinue (val,env)
    local
      Absyn.Path path;
      String s1;
    case (Values.CODE(Absyn.C_TYPENAME(path)),env)
      equation
        (_,_,_,DAE.VALBOUND(valBound=Values.CODE(A=Absyn.C_TYPENAME(path=path))),_,_,_,_,_) = Lookup.lookupVar(Env.emptyCache(), env, ComponentReference.pathToCref(path));
      then Values.CODE(Absyn.C_TYPENAME(path));
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
      Absyn.Class class_;
      Boolean res;
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
    case (path,p)
      equation
        Config.setEvaluateParametersInAnnotations(true);
        Absyn.STRING(version) = Interactive.getNamedAnnotation(path, p, "version", SOME(Absyn.STRING("")), Interactive.getAnnotationExp);
        Config.setEvaluateParametersInAnnotations(false);
      then version;
    else "(version unknown)";
  end matchcontinue;
end getPackageVersion;

end CevalScript;
