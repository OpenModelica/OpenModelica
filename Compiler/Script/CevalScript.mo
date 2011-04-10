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
" file:         CevalScript.mo
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
public import Interactive;
public import Dependency;
public import Values;

// protected imports
protected import AbsynDep;
protected import BackendDump;
protected import BackendDAEUtil;
protected import BackendDAECreate;
protected import BackendDAEOptimize;
protected import BackendDAETransform;
protected import BackendEquation;
protected import BackendVariable;
protected import ClassInf;
protected import ClassLoader;
protected import DAEQuery;
protected import DAEUtil;
protected import DAEDump;
protected import Debug;
protected import Dump;
protected import Error;
protected import Expression;
protected import Inst;
protected import InnerOuter;
protected import Lookup;
protected import MetaUtil;
protected import ModUtil;
protected import OptManager;
protected import Prefix;
protected import Parser;
protected import Print;
protected import Refactor;
protected import RTOpts;
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

public constant Integer RT_CLOCK_SIMULATE_TOTAL = 8;
public constant Integer RT_CLOCK_SIMULATE_SIMULATION = 9;
public constant Integer RT_CLOCK_BUILD_MODEL = 10;

protected constant DAE.Type simulationResultType_rtest = (DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationResult")),{
  DAE.TYPES_VAR("resultFile",DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("simulationOptions",DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("messages",DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE())
  },NONE(),NONE()),NONE());

protected constant DAE.Type simulationResultType_full = (DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationResult")),{
  DAE.TYPES_VAR("resultFile",DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("simulationOptions",DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("messages",DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("timeFrontend",DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("timeBackend",DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("timeSimCode",DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("timeTemplates",DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("timeCompile",DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("timeSimulation",DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()),
  DAE.TYPES_VAR("timeTotal",DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE())
  },NONE(),NONE()),NONE());

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
    defaultMeasureTime
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
    "measureTime"
  } "names of simulation options";

public function getSimulationResultType
  output DAE.Type t;
algorithm
  t := Util.if_(RTOpts.getRunningTestsuite(), simulationResultType_rtest, simulationResultType_full);
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
  fields := Util.if_(RTOpts.getRunningTestsuite(), {},
                     Util.listMap(resultValues, Util.tuple21));
  vals := Util.if_(RTOpts.getRunningTestsuite(), {}, 
                   Util.listMap(resultValues, Util.tuple22));
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
  cref := ComponentReference.makeCrefIdent("currentSimulationResult",DAE.ET_OTHER(),{});
  outExp := Expression.makeCrefExp(cref,DAE.ET_OTHER());
end buildCurrentSimulationResultExp;

protected function cevalCurrentSimulationResultExp
  input Env.Cache cache;
  input Env.Env env;
  input String inputFilename;
  input Interactive.InteractiveSymbolTable st;
  input Ceval.Msg msg;
  output Env.Cache outCache;
  output String filename;
algorithm
  (outCache,filename) := match (cache,env,inputFilename,st,msg)
    case (_,_,"<default>",_,_)
      equation
        (cache,Values.STRING(filename),_) = Ceval.ceval(cache,env,buildCurrentSimulationResultExp(),true,SOME(st),NONE(),msg);
      then (cache,filename);
    else (cache,inputFilename);
  end match;
end cevalCurrentSimulationResultExp;

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
  input DAE.Exp storeInTemp "store in temp, default false";
  input DAE.Exp noClean "no cleaning, default false";
  input DAE.Exp options "options, default ''";
  input DAE.Exp outputFormat "output format, default 'plt'";
  input DAE.Exp variableFilter;
  input DAE.Exp measureTime;
  output SimulationOptions outSimulationOptions;
algorithm
  outSimulationOptions := 
    SIMULATION_OPTIONS(
    startTime,
    stopTime,
    numberOfIntervals,
    stepSize,
    tolerance,
    method,
    fileNamePrefix,
    storeInTemp,
    noClean,
    options,    
    outputFormat,
    variableFilter,
    measureTime
  );
end buildSimulationOptions;

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
  input Interactive.InteractiveSymbolTable inSymTab;
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
  DAE.Exp startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime;
algorithm
  SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, _, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime) := inSimOpt;
  outSimOpt := SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, DAE.SCONST(inFileNamePrefix), storeInTemp, noClean, options, outputFormat, variableFilter, measureTime);
end setFileNamePrefixInSimulationOptions;

protected function getConst
"@author: adrpo
  Tranform a literal Absyn.Exp to DAE.Exp with the given DAE.ExpType"
  input  Absyn.Exp inAbsynExp;
  input DAE.ExpType inExpType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inAbsynExp, inExpType)
    local
      Integer i; Real r;
      Absyn.Exp exp;
    
    case (Absyn.INTEGER(i), DAE.ET_INT())  then DAE.ICONST(i);
    case (Absyn.REAL(r),    DAE.ET_REAL()) then DAE.RCONST(r);
        
    case (Absyn.INTEGER(i), DAE.ET_REAL()) equation r = intReal(i); then DAE.RCONST(r);
    case (Absyn.REAL(r),    DAE.ET_INT())  equation i = realInt(r); then DAE.ICONST(i);
    
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
      DAE.Exp variableFilter, measureTime;
      Real rStepSize, rStopTime, rStartTime;
      Integer iNumberOfIntervals;
      String name,msg;
      
    case (inSimOpt, {}) then inSimOpt;
    
    case (SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime), 
          Absyn.NAMEDARG(argName = "Tolerance", argValue = exp)::rest)
      equation
        tolerance = getConst(exp, DAE.ET_REAL());
        simOpt = populateSimulationOptions(
          SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,storeInTemp,noClean,options,outputFormat,variableFilter,measureTime),
             rest);
      then
        simOpt;
    
    case (SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime), 
          Absyn.NAMEDARG(argName = "StartTime", argValue = exp)::rest)
      equation
        startTime = getConst(exp, DAE.ET_REAL());
        simOpt = populateSimulationOptions(
          SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,storeInTemp,noClean,options,outputFormat,variableFilter,measureTime),
             rest);
      then
        simOpt;

    case (SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime), 
          Absyn.NAMEDARG(argName = "StopTime", argValue = exp)::rest)
      equation
        stopTime = getConst(exp, DAE.ET_REAL());
        simOpt = populateSimulationOptions(
          SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,storeInTemp,noClean,options,outputFormat,variableFilter,measureTime),
             rest);
      then
        simOpt;

    case (SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime), 
          Absyn.NAMEDARG(argName = "NumberOfIntervals", argValue = exp)::rest)
      equation
        numberOfIntervals = getConst(exp, DAE.ET_INT());
        simOpt = populateSimulationOptions(
          SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                             fileNamePrefix,storeInTemp,noClean,options,outputFormat,variableFilter,measureTime),
             rest);
      then
        simOpt;

    case (SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime), 
          Absyn.NAMEDARG(argName = "Interval", argValue = exp)::rest)
      equation
        DAE.RCONST(rStepSize) = getConst(exp, DAE.ET_REAL());
        // a bit different for Interval, handle it LAST!!!!
        SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                           fileNamePrefix,storeInTemp,noClean,options,outputFormat,variableFilter,measureTime) = 
          populateSimulationOptions(inSimOpt, rest);
       
       DAE.RCONST(rStartTime) = startTime;
       DAE.RCONST(rStopTime) = startTime;
       
       iNumberOfIntervals = realInt(realDiv(realSub(rStopTime, rStartTime), rStepSize));
       
       numberOfIntervals = DAE.ICONST(iNumberOfIntervals);
       stepSize = DAE.RCONST(rStepSize);
       
       simOpt = SIMULATION_OPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,
                                   fileNamePrefix,storeInTemp,noClean,options,outputFormat,variableFilter,measureTime);
      then
        simOpt;

    case (SIMULATION_OPTIONS(startTime, stopTime, numberOfIntervals, stepSize, tolerance, method, fileNamePrefix, storeInTemp, noClean, options, outputFormat, variableFilter, measureTime), 
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
        simOptsValues = Util.listMap(lst, ValuesUtil.valString);
        // trim " from strings!
        simOptsValues = Util.listMap2(simOptsValues, System.stringReplace, "\"", "\'");
        
        str = Util.buildMapStr(simulationOptionsNames, simOptsValues, " = ", ", ");
      then
        str;
    
    // on failure
    case (_::lst)
      equation
        // build a list with the values  
        simOptsValues = Util.listMap(lst, ValuesUtil.valString);
        // trim " from strings!
        simOptsValues = Util.listMap2(simOptsValues, System.stringReplace, "\"", "\'");
        
        str = Util.stringDelimitList(simOptsValues, ", ");
      then
        str;
  end matchcontinue;
end simOptionsAsString;

public function cevalInteractiveFunctions
"function cevalInteractiveFunctions
  This function evaluates the functions
  defined in the interactive environment."
  input Env.Cache cache;
  input Env.Env env;
  input DAE.Exp exp "expression to evaluate";
  input Interactive.InteractiveSymbolTable st;
  input Ceval.Msg msg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable) := matchcontinue (cache,env,exp,st,msg)
    local
      list<DAE.Exp> eLst;
      list<Values.Value> valLst;
      String name;
      Values.Value value;
      Real t1,t2,time;
      // This needs to be first because otherwise it takes 0 time to get the value :)
    case (cache,env,DAE.CALL(path = Absyn.IDENT(name = "timing"),expLst = {exp}),st,msg)
      equation
        t1 = System.time();
        (cache,value,SOME(st)) = Ceval.ceval(cache,env, exp, true, SOME(st),NONE(), msg);
        t2 = System.time();
        time = t2 -. t1;
      then
        (cache,Values.REAL(time),st);

    case (cache,env,DAE.CALL(path=Absyn.IDENT(name),builtin=true,expLst=eLst),st,msg)
      equation
        (cache,valLst) = Ceval.cevalList(cache,env,eLst,true,SOME(st),msg);
        (cache,value,st) = cevalInteractiveFunctions2(cache,env,name,valLst,st,msg);
      then (cache,value,st);

  end matchcontinue;
end cevalInteractiveFunctions;

protected function cevalInteractiveFunctions2
"function cevalInteractiveFunctions
  This function evaluates the functions
  defined in the interactive environment."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input String functionName;
  input list<Values.Value> vals;
  input Interactive.InteractiveSymbolTable st;
  input Ceval.Msg msg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inEnv,functionName,vals,st,msg)
    local
      Absyn.Path path,p1,classpath,className;
      list<SCode.Class> scodeP,sp,fp;
      list<Env.Frame> env;
      SCode.Class c;
      String s1,str,str1,str2,str3,re,token,varid,cmd,executable,method_str,outputFormat_str,initfilename,cit,pd,executableSuffixedExe,sim_call,result_file,filename_1,filename,omhome_1,plotCmd,tmpPlotFile,call,str_1,mp,pathstr,name,cname,fileNamePrefix_s,errMsg,errorStr,uniqueStr,interpolation,title,xLabel,yLabel,filename2,varNameStr,xml_filename,xml_contents,visvar_str,pwd,omhome,omlib,omcpath,os,platform,usercflags,senddata,res,workdir,gcc,confcmd,touch_file,uname,filenameprefix;
      DAE.ComponentRef cr,cref,classname;
      Interactive.InteractiveSymbolTable newst,st_1;
      Absyn.Program p,pnew,newp,ptot;
      list<Interactive.InstantiatedClass> ic,ic_1;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      DAE.Type tp;
      Absyn.Class absynClass;
      DAE.DAElist dae;
      BackendDAE.BackendDAE daelow,optdae;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqnarr;
      array<BackendDAE.MultiDimEquation> ae;
      list<DAE.Exp> expVars,options;
      array<list<Integer>> m,mt;
      Option<array<list<Integer>>> om,omt;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      Values.Value ret_val,simValue,size_value,value,v,cvar,cvar2,xRange,yRange,xRange1,xRange2,yRange1,yRange2;
      DAE.Exp exp,size_expression,bool_exp,storeInTemp,translationLevel,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,varName,varTimeStamp;
      Absyn.ComponentRef cr_1;
      Integer size,length,resI,timeStampI,i,n;
      list<String> vars_1,vars_2,args,strings,strVars,strs,visvars;
      Real t1,t2,time,timeTotal,timeSimulation,timeStamp,val,x1,x2,y1,y2;
      Interactive.InteractiveStmts istmts;
      Boolean bval, b, externalWindow, legend, grid, logX, logY, points, gcc_res, omcfound, rm_res, touch_res, uname_res, extended, insensitive;
      Env.Cache cache;
      list<Interactive.LoadedFile> lf;
      AbsynDep.Depends aDep;
      Absyn.ComponentRef crefCName;
      list<tuple<String,Values.Value>> resultValues;
      list<Real> timeStamps;
      list<DAE.Exp> expLst;
      list<tuple<String,list<String>>> deps;
      Absyn.CodeNode codeNode;
      list<Values.Value> cvars;
      DAE.FunctionTree funcs;
    
    /* Does not exist in the env...
    case (cache,env,"lookupClass",{Values.CODE(Absyn.C_TYPENAME(path))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        ptot = Dependency.getTotalProgram(path,p);
        scodeP = SCodeUtil.translateAbsyn2SCode(ptot);
        (cache,env) = Inst.makeEnvFromProgram(cache, scodeP, Absyn.IDENT(""));
        (cache,c,env) = Lookup.lookupClass(cache,env, path, true);
        SOME(p1) = Env.getEnvPath(env);
        s1 = ModUtil.pathString(p1);
        Print.printBuf("Found class ");
        Print.printBuf(s1);
        Print.printBuf("\n\n");
        str = Print.getString();
      then
        (cache,Values.STRING(str),st);
     */
     
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
        vals = Util.listMap(strs,ValuesUtil.makeString);
        v = Values.ARRAY(vals,{i});
      then
        (cache,Values.TUPLE({Values.INTEGER(n),v}),st);

    case (cache,env,"regex",{Values.STRING(str),Values.STRING(re),Values.INTEGER(i),Values.BOOL(extended),Values.BOOL(insensitive)},st,msg)
      equation
        strs = Util.listFill("",i);
        vals = Util.listMap(strs,ValuesUtil.makeString);
        v = Values.ARRAY(vals,{i});
      then
        (cache,Values.TUPLE({Values.INTEGER(-1),v}),st);

    case (cache,env,"list",{Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT("AllLoadedClasses")))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        str = Dump.unparseStr(p,false);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,"list",{Values.CODE(Absyn.C_TYPENAME(path))},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        absynClass = Interactive.getPathedClassInProgram(path, p);
        str = Dump.unparseStr(Absyn.PROGRAM({absynClass},Absyn.TOP(),Absyn.TIMESTAMP(0.0,0.0)),false) ;
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,"list",_,st,msg) then (cache,Values.STRING(""),st);
    
    case (cache,env,"jacobian",{Values.CODE(Absyn.C_TYPENAME(path))},
          (st as Interactive.SYMBOLTABLE(
            ast = p,depends=aDep,explodedAst = sp,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),msg)
      equation
        ptot = Dependency.getTotalProgram(path,p);
        scodeP = SCodeUtil.translateAbsyn2SCode(ptot);
        (cache, env, _, dae) = Inst.instantiateClass(cache, InnerOuter.emptyInstHierarchy, scodeP, path);
        dae  = DAEUtil.transformationsBeforeBackend(dae);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(path,dae,env));
        funcs = Env.getFunctionTree(cache);
        daelow = BackendDAECreate.lower(dae, funcs, false) "no dummy state" ;
        (optdae,om,omt) = BackendDAEUtil.preOptimiseBackendDAE(daelow,funcs,NONE(),NONE(),NONE());
        (m,mt) = BackendDAEUtil.getIncidenceMatrixfromOption(optdae,om,omt);
        vars = BackendVariable.daeVars(optdae);
        eqnarr = BackendEquation.daeEqns(optdae);
        ae = BackendEquation.daeArrayEqns(optdae);
        jac = BackendDAEUtil.calculateJacobian(vars, eqnarr, ae, m, mt,false);
        res = BackendDump.dumpJacobianStr(jac);
      then
        (cache,Values.STRING(res),Interactive.SYMBOLTABLE(p,aDep,sp,ic_1,iv,cf,lf));
    
    case (cache,env,"translateModel",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)},
          (st as Interactive.SYMBOLTABLE(
            ast = p,
            explodedAst = sp,
            instClsLst = ic,
            lstVarVal = iv,
            compiledFunctions = cf)),msg)
      equation
        (cache,ret_val,st_1,_,_,_,_) = translateModel(cache,env, className, st, filenameprefix,true,NONE());
      then
        (cache,ret_val,st_1);
   
     case (cache,env,"translateModelCPP",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)},
          (st as Interactive.SYMBOLTABLE(
            ast = p,
            explodedAst = sp,
            instClsLst = ic,
            lstVarVal = iv,
            compiledFunctions = cf)),msg)
      equation
        (cache,ret_val,st_1,_,_,_,_) = translateModelCPP(cache,env, className, st, filenameprefix,true,NONE());
      then
        (cache,ret_val,st_1);
        
    case (cache,env,"translateModelFMU",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)},
          (st as Interactive.SYMBOLTABLE(
            ast = p,
            explodedAst = sp,
            instClsLst = ic,
            lstVarVal = iv,
            compiledFunctions = cf)),msg)
      equation
        (cache,ret_val,st_1) = translateModelFMU(cache,env, className, st, filenameprefix, true, NONE());
      then
        (cache,ret_val,st_1);
    
    case (cache,env,"exportDAEtoMatlab",{Values.CODE(Absyn.C_TYPENAME(className)),Values.STRING(filenameprefix)},
          (st as Interactive.SYMBOLTABLE(
            ast = p,
            explodedAst = sp,
            instClsLst = ic,
            lstVarVal = iv,
            compiledFunctions = cf)),msg)
      equation
        (cache,ret_val,st_1,_) = getIncidenceMatrix(cache,env, className, st, msg, filenameprefix);
      then
        (cache,ret_val,st_1);
    
    case (cache,env,"checkModel",{Values.CODE(Absyn.C_TYPENAME(className))},st,msg)
      equation
        OptManager.setOption("checkModel", true);
        (cache,ret_val,st_1) = checkModel(cache, env, className, st, msg);
        OptManager.setOption("checkModel", false);
      then
        (cache,ret_val,st_1);
    
    case (cache,env,"checkAllModelsRecursive",{Values.CODE(Absyn.C_TYPENAME(className))},st,msg)
      equation
        (cache,ret_val,st_1) = checkAllModelsRecursive(cache, env, className, st, msg);
      then
        (cache,ret_val,st_1);
    
    case (cache,env,"translateGraphics",{Values.CODE(Absyn.C_TYPENAME(className))},st,msg)
      equation
        (cache,ret_val,st_1) = translateGraphics(cache,env, className, st, msg);
      then
        (cache,ret_val,st_1);
    
    case (cache,env,"setCompileCommand",{Values.STRING(cmd)},st,msg)
      equation
        cmd = Util.rawStringToInputString(cmd);
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
        cmd = Util.rawStringToInputString(cmd);
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
        cmd = Util.rawStringToInputString(cmd);
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
        cmd = Util.rawStringToInputString(cmd);
        Settings.setModelicaPath(cmd);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"setModelicaPath",_,st,msg)
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,"getAnnotationVersion",{},st,msg)
      equation
        res = RTOpts.getAnnotationVersion();
      then
        (cache,Values.STRING(res),st);

    case (cache,env,"getNoSimplify",{},st,msg)
      equation
        b = RTOpts.getNoSimplify();
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"setNoSimplify",{Values.BOOL(b)},st,msg)
      equation
        RTOpts.setNoSimplify(b);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"getShowAnnotations",{},st,msg)
      equation
        b = RTOpts.showAnnotations();
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"setShowAnnotations",{Values.BOOL(b)},st,msg)
      equation
        RTOpts.setShowAnnotations(b);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,"getVectorizationLimit",{},st,msg)
      equation
        i = RTOpts.vectorizationLimit();
      then
        (cache,Values.INTEGER(i),st);

    case (cache,env,"getOrderConnections",{},st,msg)
      equation
        b = RTOpts.orderConnections();
      then
        (cache,Values.BOOL(b),st);

    case (cache,env,"buildModel",vals,st,msg)
      equation
        (cache,executable,method_str,outputFormat_str,st,initfilename,_) = buildModel(cache,env, vals, st, msg);
      then
        (cache,ValuesUtil.makeArray({Values.STRING(executable),Values.STRING(initfilename)}),st);
        
    case (cache,env,"buildModel",_,st,msg) /* failing build_model */
    then (cache,ValuesUtil.makeArray({Values.STRING(""),Values.STRING("")}),st);
        
    case (cache,env,"buildModelBeast",vals,st,msg)
      equation
        (cache,executable,method_str,st,initfilename) = buildModelBeast(cache,env,vals,st,msg);
      then
        (cache,ValuesUtil.makeArray({Values.STRING(executable),Values.STRING(initfilename)}),st);
    
      /* Remove output.log before simulate in case it already exists. This is so we can check for the presence of output.log later. */
    case (cache,env,"simulate",vals,st,msg)
      equation
        true = System.regularFileExists("output.log");
        false = 0 == System.removeFile("output.log");
        simValue = createSimulationResultFailure("Failed to remove existing file output.log", simOptionsAsString(vals));
      then (cache,simValue,st);
        
        /* adrpo: see if the model exists before simulation! */
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
        (cache,executable,method_str,outputFormat_str,st,_,resultValues) = buildModel(cache,env,vals,st_1,msg);
        
        cit = winCitation();
        pwd = System.pwd();
        pd = System.pathDelimiter();
        executableSuffixedExe = stringAppend(executable, System.getExeExt());
        // sim_call = stringAppendList({"sh -c ",cit,"ulimit -t 60; ",cit,pwd,pd,executableSuffixedExe,cit," > output.log 2>&1",cit});
        sim_call = stringAppendList({cit,pwd,pd,executableSuffixedExe,cit," > output.log 2>&1"});
        System.realtimeTick(RT_CLOCK_SIMULATE_SIMULATION);
        SimulationResults.close() "Windows cannot handle reading and writing to the same file from different processes like any real OS :(";
        0 = System.systemCall(sim_call);
        
        result_file = stringAppendList({executable,"_res.",outputFormat_str});
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
        
    case (cache,env,"instantiateModel",{Values.CODE(Absyn.C_TYPENAME(className))},
          (st as Interactive.SYMBOLTABLE(
            ast = p,depends=aDep,explodedAst = sp,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),msg)
      equation
        //System.startTimer();
        //print("\nExists+Dependency");
        
        crefCName = Absyn.pathToCref(className);
        true = Interactive.existClass(crefCName, p);
        ptot = Dependency.getTotalProgram(className,p);
        
        //System.stopTimer();
        //print("\nExists+Dependency: " +& realString(System.getTimerIntervalTime()));
        
        //System.startTimer();
        //print("\nAbsyn->SCode");
        
        scodeP = SCodeUtil.translateAbsyn2SCode(ptot);
        
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
        
        // System.startTimer();
        // print("\nFlatModelica");
        str = DAEDump.dumpStr(dae,Env.getFunctionTree(cache));
        // System.stopTimer();
        // print("\nFlatModelica: " +& realString(System.getTimerIntervalTime()));
      then
        (cache,Values.STRING(str),Interactive.SYMBOLTABLE(p,aDep,sp,ic_1,iv,cf,lf));
        
    case (cache,env,"instantiateModel",{Values.CODE(Absyn.C_TYPENAME(className))},
          (st as Interactive.SYMBOLTABLE(
            ast = p,depends=aDep,explodedAst = sp,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),msg) /* model does not exist */
      equation
        cr_1 = Absyn.pathToCref(className);
        false = Interactive.existClass(cr_1, p);
      then
        (cache,Values.STRING("Unknown model.\n"),Interactive.SYMBOLTABLE(p,aDep,sp,ic,iv,cf,lf));
        
    case (cache,env,"instantiateModel",{Values.CODE(Absyn.C_TYPENAME(path))},
          (st as Interactive.SYMBOLTABLE(
            ast = p,depends=aDep,explodedAst = sp,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),msg)
      equation
        ptot = Dependency.getTotalProgram(path,p);
        scodeP = SCodeUtil.translateAbsyn2SCode(ptot);
        str = Print.getErrorString() "we do not want error msg twice.." ;
        failure((_,_,_,_) =
        Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,scodeP,path));
        Print.clearErrorBuf();
        Print.printErrorBuf(str);
        str = Print.getErrorString();
      then
        (cache,Values.STRING(str),Interactive.SYMBOLTABLE(p,aDep,sp,ic,iv,cf,lf));

    case (cache,env,"setDataPort",{Values.INTEGER(i)},st,msg)
      equation
        System.setDataPort(i);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"setCompiler",{Values.STRING(str)},st,msg)
      equation
        System.setCCompiler(str);
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
        args = RTOpts.args({str});
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
        
    case (cache,env,"getVersion",{},st,msg)
      equation
        str_1 = Settings.getVersionNr();
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
        
    case (cache,env,"readFile",{Values.STRING(str)},st,msg)
      equation
        str_1 = System.readFile(str);
      then
        (cache,Values.STRING(str_1),st);
        
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
        str = Error.getMessagesStr();
      then
        (cache,Values.STRING(str),st);
        
    case (cache,env,"runScript",{Values.STRING(str)},st,msg)
      equation
        istmts = Parser.parseexp(str);
        (res,newst) = Interactive.evaluate(istmts, st, true);
      then
        (cache,Values.STRING(res),newst);
        
    case (cache,env,"runScript",_,st,msg)
    then (cache,Values.STRING("Failed"),st);
        
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

    case (cache,env,"loadModel",{Values.CODE(Absyn.C_TYPENAME(path))},
          (st as Interactive.SYMBOLTABLE(
            ast = p,depends=aDep,explodedAst = sp,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),msg) /* add path to symboltable for compiled functions
            Interactive.SYMBOLTABLE(p,sp,ic,iv,(path,t)::cf),
            but where to get t? */
      equation
        mp = Settings.getModelicaPath();
        pnew = ClassLoader.loadClass(path, mp);
        p = Interactive.updateProgram(pnew, p);
        str = Print.getString();
        newst = Interactive.SYMBOLTABLE(p,aDep,sp,{},iv,cf,lf);
      then
        (Env.emptyCache(),Values.BOOL(true),newst);
        
    case (cache,env,"loadModel",{Values.CODE(Absyn.C_TYPENAME(path))},st,msg)
      equation
        pathstr = ModUtil.pathString(path);
        Error.addMessage(Error.LOAD_MODEL_ERROR, {pathstr});
      then
        (cache,Values.BOOL(false),st);
        
    case (cache,env,"loadModel",{Values.CODE(Absyn.C_TYPENAME(path))},st,msg)
    then (cache,Values.BOOL(false),st);  /* loadModel failed */
        
    case (cache,env,"loadFile",{Values.STRING(name)},
          (st as Interactive.SYMBOLTABLE(
            ast = p,depends=aDep,explodedAst = sp,instClsLst = ic,
            lstVarVal = iv,compiledFunctions = cf,
            loadedFiles = lf)),msg)
      equation
        newp = ClassLoader.loadFile(name) "System.regularFileExists(name) => 0 & Parser.parse(name) => p1 &" ;
        newp = Interactive.updateProgram(newp, p);
      then
        (Env.emptyCache(),Values.BOOL(true),Interactive.SYMBOLTABLE(newp,aDep,sp,ic,iv,cf,lf));
        
    case (cache,env,"loadFile",{Values.STRING(name)},st,msg)
      equation
        false = System.regularFileExists(name);
      then
        (cache,Values.BOOL(false),st);
        
    case (cache,env,"loadFile",{Values.STRING(name)},st,msg)
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
        (st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
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
      then
        (cache,Values.STRING("Failed to output string"),st);
        
    case (cache,env,"strtok",{Values.STRING(str),Values.STRING(token)},st,msg)
      equation
        vals = Util.listMap(System.strtok(str,token), ValuesUtil.makeString);
        i = listLength(vals);
      then (cache,Values.ARRAY(vals,{i}),st);

        /* Checks the installation of OpenModelica and tries to find common errors */
    case (cache,env,"checkSettings",{},st,msg)
      equation
        vars_1 = {"OPENMODELICAHOME","OPENMODELICALIBRARY","OMC_PATH","OMC_FOUND","MODELICAUSERCFLAGS","WORKING_DIRECTORY","CREATE_FILE_WORKS","REMOVE_FILE_WORKS","OS","SYSTEM_INFO","SENDDATALIBS","C_COMPILER","C_COMPILER_RESPONDING","CONFIGURE_CMDLINE"};
        omhome = Settings.getInstallationDirectoryPath();
        omlib = Settings.getModelicaPath();
        omcpath = omhome +& "/bin/omc" +& System.getExeExt();
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
        senddata = System.getSendDataLibs();
        gcc = System.getCCompiler();
        gcc_res = 0 == System.systemCall(gcc +& " -v > /dev/null");
        confcmd = System.configureCommandLine();
        vals = {Values.STRING(omhome),Values.STRING(omlib),
                Values.STRING(omcpath),Values.BOOL(omcfound),
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
        vars_1 = Util.listMap(cvars, ValuesUtil.printCodeVariableName);
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename_1 = stringAppendList({pwd,pd,filename});
        value = ValuesUtil.readDataset(filename_1, vars_1, size);
      then
        (cache,value,st);
        
    case (cache,env,"readSimulationResult",_,_,_)
      equation
        Error.addMessage(Error.SCRIPT_READ_SIM_RES_ERROR, {});
      then (cache,Values.META_FAIL(),st);
        
    case (cache,env,"readSimulationResultSize",{Values.STRING(filename)},st,msg)
      equation
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename_1 = stringAppendList({pwd,pd,filename});
        i = SimulationResults.readSimulationResultSize(filename_1);
      then
        (cache,Values.INTEGER(i),st);
        
    case (cache,env,"readSimulationResultVars",{Values.STRING(filename)},st,msg)
      equation
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename_1 = stringAppendList({pwd,pd,filename});
        args = SimulationResults.readVariables(filename_1);
        vals = Util.listMap(args, ValuesUtil.makeString);
        v = ValuesUtil.makeArray(vals);
      then
        (cache,v,st);
        
    case (cache,env,"plot2",{Values.ARRAY(valueLst = cvars),Values.STRING(filename)},st,msg)
      equation
        vars_1 = Util.listMap(cvars, ValuesUtil.printCodeVariableName);
        vars_2 = Util.listUnionElt("time", vars_1);
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        value = ValuesUtil.readDataset(filename, vars_2, 0);
        pwd = System.pwd();
        cit = winCitation();
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.trim(omhome, "\"");
        pd = System.pathDelimiter();
        plotCmd = stringAppendList({cit,omhome_1,pd,"share",pd,"omc",pd,"scripts",pd,"doPlot",cit});
        uniqueStr = intString(tick());
        tmpPlotFile = stringAppendList({pwd,pd,"tmpPlot_",uniqueStr,".plt"});
        resI = ValuesUtil.writePtolemyplotDataset(tmpPlotFile, value, vars_2, "Plot by OpenModelica");
        call = stringAppendList({cit,plotCmd," \"",tmpPlotFile,"\"",cit});
        
        _ = System.systemCall(call);
      then (cache,Values.BOOL(true),st);
        
        // plot error
    case (cache,env,"plot2",_,st,msg) then (cache,Values.BOOL(false),st);
        
        //plotAll(model)
    case (cache,env,"plotAll",
        {
          Values.STRING(filename),
          Values.STRING(interpolation),
          Values.STRING(title),
          Values.BOOL(legend),
          Values.BOOL(grid),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.BOOL(points),
          xRange,
          yRange
        },
        st,
        msg)
      equation        
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        
        vars_2 = Util.listSetDifference(SimulationResults.readVariables(filename),{"time"});
        vars_2 = "time" :: vars_2;
        value = ValuesUtil.readDataset(filename, vars_2, 0);
        
        resI = ValuesUtil.sendPtolemyplotDataset(value, vars_2, "Plot by OpenModelica", interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, ValuesUtil.valString(xRange), ValuesUtil.valString(yRange));
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"plotAll",_,st,msg)
      then (cache,Values.BOOL(false),st);

    //plotAll(model)
    case (cache,env,"plotAll3",
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
        str3 = "\"" +& filename +& "\" \"" +& title +& "\" \"" +& boolString(legend) +& "\" \"" +& boolString(grid) +& "\" \"plotall\" \"" +& boolString(logX) +& "\" \"" +& boolString(logY) +& "\" \"" +& xLabel +& "\" \"" +& yLabel +& "\" \"" +& realString(x1) +& "\" \"" +& realString(x2) +& "\" \"" +& realString(y1) +& "\" \"" +& realString(y2) +& "\" -ew \"" +& boolString(externalWindow) +& "\"";
        call = str2 +& " " +& str3;
        
        0 = System.spawnCall(str2, call);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"plotAll3",_,st,msg)
      then (cache,Values.BOOL(false),st);

      // plot without sendData support is plot2()
    case (cache,env,"plot",_,st,msg)
      equation
        false = System.getHasSendDataSupport();
      then (cache,Values.STRING("OpenModelica is compiled without Qt. Configure it with-sendData-Qt and recompile. Or use a command like plot2() that does not require Qt."),st);

    // plot(x, model)
    case (cache,env,"plot",
        {
          Values.ARRAY(valueLst = cvars),
          Values.STRING(filename),
          Values.STRING(interpolation),
          Values.STRING(title),
          Values.BOOL(legend),
          Values.BOOL(grid),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.BOOL(points),
          xRange,
          yRange
        },
        st,msg)
      equation
        vars_1 = Util.listMap(cvars, ValuesUtil.printCodeVariableName);
        vars_2 = Util.listUnionElt("time", vars_1);
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        
        value = ValuesUtil.readDataset(filename, vars_2, 0);
        
        resI = ValuesUtil.sendPtolemyplotDataset(value, vars_2, "Plot by OpenModelica", interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, ValuesUtil.valString(xRange), ValuesUtil.valString(yRange));
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"plot",_,st,msg)
      then
        (cache,Values.BOOL(false),st);
    
    // plot3(x, model)
    case (cache,env,"plot3",
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
        // get the variables list
        vars_1 = Util.listMap(cvars, ValuesUtil.printCodeVariableName);
        // seperate the variables
        str = Util.stringDelimitList(vars_1,"\" \"");
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
        str3 = "\"" +& filename +& "\" \"" +& title +& "\" \"" +& boolString(legend) +& "\" \"" +& boolString(grid) +& "\" \"plot\" \"" +& boolString(logX) +& "\" \"" +& boolString(logY) +& "\" \"" +& xLabel +& "\" \"" +& yLabel +& "\" \"" +& realString(x1) +& "\" \"" +& realString(x2) +& "\" \"" +& realString(y1) +& "\" \"" +& realString(y2) +& "\" \"" +& str +& "\" -ew \"" +& boolString(externalWindow) +& "\"";
        call = str2 +& " " +& str3;
        
        0 = System.spawnCall(str2, call);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"plot3",_,st,msg)
      then
        (cache,Values.BOOL(false),st);
        
        // he-mag, visualize
        // visualize(model, x)
    case (cache,env,"visualize",{Values.CODE(Absyn.C_TYPENAME(className))},
        (st as Interactive.SYMBOLTABLE(
          ast = p,explodedAst = sp,instClsLst = ic,
          lstVarVal = iv,compiledFunctions = cf,
          loadedFiles = lf)),msg)
      equation
        //Jag måste få readptol att skicka alla variabler i .plt-filen, och en ide är
        //att göra en egen enkel funktion som i princip är en grep på DataSet: i filen..
        //Kolla på senddata:emulateStreamData
        (visvars,visvar_str) = Interactive.getElementsOfVisType(className, p);
        filename = Absyn.pathString(className);
        filename = stringAppendList({filename, "_res.plt"});
        strVars = SimulationResults.readVariables(filename);
        strVars = Util.listFilter1(strVars, visualizationVarShouldBeAdded, visvars);
        vars_2 = Util.listUnionElt("time", strVars);
        value = ValuesUtil.readDataset(filename, vars_2, 0);
        resI = ValuesUtil.sendPtolemyplotDataset2(value, vars_2, visvar_str, "Plot by OpenModelica");
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"visualize",_,st,msg)
      then
        (cache,Values.BOOL(false),st);
        
    case (cache,env,"val",{cvar,Values.REAL(timeStamp)},st,msg)
      equation
        (cache,Values.STRING(filename),_) = Ceval.ceval(cache,env,buildCurrentSimulationResultExp(), true, SOME(st),NONE(), msg);
        varNameStr = ValuesUtil.printCodeVariableName(cvar);
        val = SimulationResults.val(filename,varNameStr,timeStamp);
      then (cache,Values.REAL(val),st);
                
        /* plotparametric This rule represents the normal case when an array of at least two elements
         *  is given as an argument
         */
    case (cache,env,"plotParametric2",{cvar,Values.ARRAY(valueLst=cvars),Values.STRING(filename)},st,msg)
      equation
        vars_1 = Util.listMap(cvar::cvars, ValuesUtil.printCodeVariableName);
        length = listLength(vars_1);
        (length > 1) = true;
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        value = ValuesUtil.readDataset(filename, vars_1, 0);
        pwd = System.pwd();
        cit = winCitation();
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.trim(omhome, "\"");
        pd = System.pathDelimiter();
        plotCmd = stringAppendList({cit,omhome_1,pd,"share",pd,"omc",pd,"scripts",pd,"doPlot",cit});
        uniqueStr = intString(tick());
        tmpPlotFile = stringAppendList({pwd,pd,"tmpPlot_",uniqueStr,".plt"});
        resI = ValuesUtil.writePtolemyplotDataset(tmpPlotFile, value, vars_1, "Plot by OpenModelica");
        call = stringAppendList({cit,plotCmd," \"",tmpPlotFile,"\"",cit});
        _ = System.systemCall(call);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"plotParametric2",_,st,msg) then (cache,Values.BOOL(false),st);
        
    case (cache,env,"plotParametric",
        {
          cvar,
          Values.ARRAY(valueLst = cvars),
          Values.STRING(filename),
          Values.STRING(interpolation),
          Values.STRING(title),
          Values.BOOL(legend),
          Values.BOOL(grid),
          Values.BOOL(logX),
          Values.BOOL(logY),
          Values.STRING(xLabel),
          Values.STRING(yLabel),
          Values.BOOL(points),
          xRange,
          yRange
        },
        st,msg)
      equation
        vars_1 = Util.listMap(cvar::cvars, ValuesUtil.printCodeVariableName);
        length = listLength(vars_1);
        (length > 1) = true;
        (cache,filename) = cevalCurrentSimulationResultExp(cache,env,filename,st,msg);
        
        value = ValuesUtil.readDataset(filename, vars_1, 0);
        pwd = System.pwd();
        cit = winCitation();
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.trim(omhome, "\"");
        pd = System.pathDelimiter();
        plotCmd = stringAppendList({cit,omhome_1,pd,"share",pd,"omc",pd,"scripts",pd,"doPlot",cit});
        uniqueStr = intString(tick());
        tmpPlotFile = stringAppendList({pwd,pd,"tmpPlot_",uniqueStr,".plt"});
        resI = ValuesUtil.sendPtolemyplotDataset(value, vars_1, "Plot by OpenModelica", interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, ValuesUtil.valString(xRange), ValuesUtil.valString(yRange));
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"plotParametric",_,st,msg)
      then (cache,Values.BOOL(false),st);
        
    // plotParametric3
    case (cache,env,"plotParametric3",
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
        str3 = "\"" +& filename +& "\" \"" +& title +& "\" \"" +& boolString(legend) +& "\" \"" +& boolString(grid) +& "\" \"plotparametric\" \"" +& boolString(logX) +& "\" \"" +& boolString(logY) +& "\" \"" +& xLabel +& "\" \"" +& yLabel +& "\" \"" +& realString(x1) +& "\" \"" +& realString(x2) +& "\" \"" +& realString(y1) +& "\" \"" +& realString(y2) +& "\" \"" +& str +& "\" -ew \"" +& boolString(externalWindow) +& "\"";
        call = str2 +& " " +& str3;
        
        0 = System.spawnCall(str2, call);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"plotParametric3",_,st,msg)
      then (cache,Values.BOOL(false),st);
    
    case (cache,env,"echo",{v as Values.BOOL(bval)},st,msg)
      equation
        setEcho(bval);
      then (cache,v,st);

    case (cache,env,"enableSendData",{Values.BOOL(b)},st,msg)
      equation
        System.enableSendData(b);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,"strictRMLCheck",_,st as Interactive.SYMBOLTABLE(ast = p),msg)
      equation
        _ = Util.listMap1r(Util.listMap(Interactive.getFunctionsInProgram(p), SCodeUtil.translateClass), MetaUtil.strictRMLCheck, true);
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

 end matchcontinue;
end cevalInteractiveFunctions2;
        
protected function visualizationVarShouldBeAdded
  input String var;
  input list<String> ids;
algorithm
  _ := matchcontinue (var,ids)
    local
      String id;
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
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  input String filenameprefix;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
  output String outString;
algorithm
  (outCache,outValue,outInteractiveSymbolTable,outString):=
  match (inCache,inEnv,className,inInteractiveSymbolTable,inMsg,filenameprefix)
    local
      String filenameprefix,filename,file_dir, str;
      list<SCode.Class> p_1,sp;
      DAE.DAElist dae_1,dae;
      list<Env.Frame> env;
      list<Interactive.InstantiatedClass> ic_1,ic;
      BackendDAE.BackendDAE dlow;
      Absyn.ComponentRef a_cref;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      DAE.Exp fileprefix;
      Env.Cache cache;
      Integer elimLevel;
      String flatModelicaStr;

    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg,filenameprefix) /* mo file directory */
      equation
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env,_,dae_1) =
        Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,p_1,className);
        dae  = DAEUtil.transformationsBeforeBackend(dae_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dae,env));
        a_cref = Absyn.pathToCref(className);
        file_dir = getFileDir(a_cref, p);
        elimLevel = RTOpts.eliminationLevel();
        RTOpts.setEliminationLevel(0); // No variable eliminiation
        dlow = BackendDAECreate.lower(dae, Env.getFunctionTree(cache), false);
        dlow = BackendDAECreate.findZeroCrossings(dlow);
        RTOpts.setEliminationLevel(elimLevel); // Reset elimination level
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


protected function translateModel "function translateModel
 author: x02lucpo
 translates a model into cpp code and writes also a makefile"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
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
      Interactive.InteractiveSymbolTable st;
      list<String> libs;
      Values.Value outValMsg;
      String file_dir, fileNamePrefix;
    
    case (cache,env,className,st,fileNamePrefix,addDummy,inSimSettingsOpt)
      equation
        (cache, outValMsg, st, indexed_dlow, libs, file_dir, resultValues) =
          SimCode.translateModel(cache,env,className,st,fileNamePrefix,addDummy,inSimSettingsOpt);
      then
        (cache,outValMsg,st,indexed_dlow,libs,file_dir,resultValues);
  end match;
end translateModel;

protected function translateModelCPP "function translateModel
 author: x02lucpo
 translates a model into cpp code and writes also a makefile"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
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
      Interactive.InteractiveSymbolTable st;
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
end translateModelCPP;

protected function translateModelFMU "function translateModelFMU
 author: Frenkel TUD
 translates a model into cpp code and writes also a makefile"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable):=
  match (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix,addDummy,inSimSettingsOpt)
    local
      Env.Cache cache;
      list<Env.Frame> env;
      BackendDAE.BackendDAE indexed_dlow;
      Interactive.InteractiveSymbolTable st;
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
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable) :=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg)
    local
      list<SCode.Class> sp;
      list<Env.Frame> env;
      list<Interactive.InstantiatedClass> ic;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p;
      list<Interactive.InteractiveVariable> iv;
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

    case (cache,env,className,(st as Interactive.SYMBOLTABLE(p as Absyn.PROGRAM(globalBuildTimes=ts),aDep,sp,ic,iv,cf,lf)),msg)
      equation
        cls = Interactive.getPathedClassInProgram(className, p);
        refactoredClass = Refactor.refactorGraphicalAnnotation(p, cls);
        within_ = Interactive.buildWithin(className);
        p1 = Interactive.updateProgram(Absyn.PROGRAM({refactoredClass}, within_,ts), p);
        s1 = Absyn.pathString(className);
        retStr=stringAppendList({"Translation of ",s1," successful.\n"});
      then
        (cache,Values.STRING(retStr),Interactive.SYMBOLTABLE(p1,aDep,sp,ic,iv,cf,lf));

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
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output SimCode.SimulationSettings outSimSettings;
algorithm
  (outCache,outSimSettings):=
  match (inCache,inEnv,vals,inInteractiveSymbolTable,inMsg)
    local
      String method_str,options_str,outputFormat_str,variableFilter_str,s;
      Interactive.InteractiveSymbolTable st;
      Values.Value starttime_v,stoptime_v,tolerance_v;
      Integer interval_i;
      Real starttime_r,stoptime_r,tolerance_r;
      list<Env.Frame> env;
      DAE.Exp starttime,stoptime,interval,toleranceExp,method,options,outputFormat;
      Ceval.Msg msg;
      Env.Cache cache;
      Boolean measureTime;
    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(_)),starttime_v,stoptime_v,Values.INTEGER(interval_i),tolerance_v,Values.STRING(method_str),_,_,_,Values.STRING(options_str),Values.STRING(outputFormat_str),Values.STRING(variableFilter_str),Values.BOOL(measureTime)},
         (st as Interactive.SYMBOLTABLE(ast = _)),msg)
      equation
        starttime_r = ValuesUtil.valueReal(starttime_v);
        stoptime_r = ValuesUtil.valueReal(stoptime_v);
        tolerance_r = ValuesUtil.valueReal(tolerance_v);
        outSimSettings = SimCode.createSimulationSettings(starttime_r,stoptime_r,interval_i,tolerance_r,method_str,options_str,outputFormat_str,variableFilter_str,measureTime);
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

protected function buildModel "function buildModel
 author: x02lucpo
 translates and builds the model by running compiler script on the generated makefile"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Values.Value> vals;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output String outString1 "className";
  output String outString2 "method";
  output String outputFormat_str;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable3;
  output String outString4 "initFileName";
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  (outCache,outString1,outString2,outputFormat_str,outInteractiveSymbolTable3,outString4,resultValues):=
  matchcontinue (inCache,inEnv,vals,inInteractiveSymbolTable,inMsg)
    local
      Values.Value ret_val;
      Interactive.InteractiveSymbolTable st,st_1,st2;
      BackendDAE.BackendDAE indexed_dlow_1;
      list<String> libs;
      String file_dir,init_filename,method_str,filenameprefix,oldDir,exeFile,s3;
      Absyn.Path classname;
      Absyn.Program p;
      Absyn.Class cdef;
      list<Interactive.CompiledCFunction> cf;
      Real edit,build,globalEdit,globalBuild,timeCompile;
      list<Env.Frame> env;
      SimCode.SimulationSettings simSettings;
      Values.Value starttime,stoptime,interval,tolerance,method,fileprefix,storeInTemp,noClean,options,outputFormat,variableFilter;
      list<SCode.Class> sp;
      list<Values.Value> vals;
      list<Interactive.InstantiatedClass> ic;
      list<Interactive.InteractiveVariable> iv;
      Ceval.Msg msg;
      Env.Cache cache;
      Boolean cdToTemp,existFile;
      Absyn.TimeStamp ts;
      
    // do not recompile.
    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),starttime,stoptime,interval,tolerance,Values.STRING(method_str),Values.STRING(filenameprefix),Values.BOOL(cdToTemp),_,options,Values.STRING(outputFormat_str),_},
          (st as Interactive.SYMBOLTABLE(ast = p as Absyn.PROGRAM(globalBuildTimes=Absyn.TIMESTAMP(_,edit)),explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      // If we already have an up-to-date version of the binary file, we don't need to recompile.
      equation
        //cdef = Interactive.getPathedClassInProgram(classname,p);
       _ = Error.getMessagesStr() "Clear messages";
        // Only compile if change occured after last build.
        ( Absyn.CLASS(info = Absyn.INFO(buildTimes= Absyn.TIMESTAMP(build,_)))) = Interactive.getPathedClassInProgram(classname,p);
        true = (build >. edit);
        oldDir = System.pwd();
        changeToTempDirectory(cdToTemp);
        init_filename = stringAppendList({filenameprefix,"_init.txt"});
        exeFile = filenameprefix +& System.getExeExt();
        existFile = System.regularFileExists(exeFile);
        _ = System.cd(oldDir);
        true = existFile;
    then
      (cache,filenameprefix,method_str,outputFormat_str,st,init_filename,zeroAdditionalSimulationResultValues);
    
    // compile the model
    case (cache,env,vals as {Values.CODE(Absyn.C_TYPENAME(classname)),starttime,stoptime,interval,tolerance,method,Values.STRING(filenameprefix),Values.BOOL(cdToTemp),noClean,options,outputFormat,variableFilter,_},(st_1 as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation
        (cdef as Absyn.CLASS(info = Absyn.INFO(buildTimes=ts as Absyn.TIMESTAMP(_,globalEdit)))) = Interactive.getPathedClassInProgram(classname,p);
        Absyn.PROGRAM(_,_,Absyn.TIMESTAMP(globalBuild,_)) = p;

       _ = Error.getMessagesStr() "Clear messages";
        oldDir = System.pwd();
        changeToTempDirectory(cdToTemp);
        (cache,simSettings) = calculateSimulationSettings(cache,env,vals,st_1,msg);
        SimCode.SIMULATION_SETTINGS(method = method_str, outputFormat = outputFormat_str) 
           = simSettings;
        
        (cache,ret_val,st,indexed_dlow_1,libs,file_dir,resultValues) = translateModel(cache,env, classname, st_1, filenameprefix,true, SOME(simSettings));
        //cname_str = Absyn.pathString(classname);
        //SimCode.generateInitData(indexed_dlow_1, classname, filenameprefix, init_filename,
        //  starttime_r, stoptime_r, interval_r, tolerance_r, method_str,options_str,outputFormat_str);
        
        System.realtimeTick(RT_CLOCK_BUILD_MODEL);
        init_filename = filenameprefix +& "_init.txt"; //a hack ? should be at one place somewhere
        //win1 = getWithinStatement(classname);
        s3 = extractNoCleanCommand(noClean);
        
        Debug.fprintln("dynload", "buildModel: about to compile model " +& filenameprefix +& ", " +& file_dir);
        compileModel(filenameprefix, libs, file_dir, s3, method_str);
        Debug.fprintln("dynload", "buildModel: Compiling done.");
        _ = System.cd(oldDir);
        p = setBuildTime(p,classname);
        st2 = st;// Interactive.replaceSymbolTableProgram(st,p);
        timeCompile = System.realtimeTock(RT_CLOCK_BUILD_MODEL);
        resultValues = ("timeCompile",Values.REAL(timeCompile)) :: resultValues;
      then
        (cache,filenameprefix,method_str,outputFormat_str,st2,init_filename,resultValues);
    
    // failure
    case (_,_,_,_,_)
      then
        fail();
  end matchcontinue;
end buildModel;

protected function changeToTempDirectory "function changeToTempDirectory
changes to temp directory (set using the functions from Settings.mo)
if the boolean flag given as input is true"
  input Boolean cdToTemp;
algorithm
  _ := matchcontinue(cdToTemp)
  local String tempDir;
    case(true) equation
        tempDir = Settings.getTempDirectoryPath();
        0 = System.cd(tempDir);
        then ();
    case(_) then ();
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
        dir = Util.listStripLast(filename_1);
        dir_1 = Util.stringDelimitList(dir, pd);
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

protected function compileModel "function: compileModel
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
      String pd,omhome,omhome_1,cd_path,libsfilename,libs_str,s_call,fileprefix,file_dir,command,filename,str,extra_command;
      list<String> libs;

    // If compileCommand not set, use $OPENMODELICAHOME\bin\Compile
    // adrpo 2009-11-29: use ALL THE TIME $OPENMODELICAHOME/bin/Compile
    case (fileprefix,libs,file_dir,noClean,solverMethod)
      equation
        pd = System.pathDelimiter();
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.stringReplace(omhome, "\"", "");
        cd_path = System.pwd();
        libsfilename = stringAppend(fileprefix, ".libs");
        libs_str = Util.stringDelimitList(libs, " ");
        
        System.writeFile(libsfilename, libs_str);
        // We only need to set OPENMODELICAHOME on Windows, and set doesn't work in bash shells anyway
        // adrpo: 2010-10-05: 
        //        whatever you do, DO NOT add a space before the && otherwise
        //        OPENMODELICAHOME that we set will contain a SPACE at the end!
        //        set OPENMODELICAHOME=DIR && actually adds the space between the DIR and &&
        //        to the environment variable! Don't ask me why, ask Microsoft.
        omhome = Util.if_(System.os() ==& "Windows_NT", "set OPENMODELICAHOME=\"" +& omhome_1 +& "\"&& ", "");
        s_call =
        stringAppendList({omhome,
          omhome_1,pd,"share",pd,"omc",pd,"scripts",pd,"Compile"," ",fileprefix," ",noClean});
        Debug.fprintln("dynload", "compileModel: running " +& s_call);
        0 = System.systemCall(s_call)  ;
        Debug.fprintln("dynload", "compileModel: successful! ");
      then
        ();

    case (fileprefix,libs,file_dir,_,_) /* compilation failed */
      equation
        filename = stringAppendList({fileprefix,".log"});
        true = System.regularFileExists(filename);
        str = System.readFile(filename);
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {str});
        Debug.fprintln("dynload", "compileModel: failed!");
      then
        fail();

    case (fileprefix,libs,file_dir,_,_) /* compilation failed\\n */
      equation
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.stringReplace(omhome, "\"", "");
        pd = System.pathDelimiter();
        command = Util.if_(System.os() ==& "Windows_NT", "Compile.bat", "Compile");
        s_call = stringAppendList({omhome_1,pd,"share",pd,"omc",pd,"scripts",pd,command});
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
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output String outString;
algorithm
  (outCache,outString):=
  match (inCache,inEnv,inExp,inInteractiveSymbolTable,inMsg)
    local
      String prefix_str;
      Interactive.InteractiveSymbolTable st;
      list<Env.Frame> env;
      DAE.Exp filenameprefix;
      Absyn.Program p;
      list<SCode.Class> sp;
      list<Interactive.InstantiatedClass> ic;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Env.Cache cache;
    case (cache,env,filenameprefix,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation
        (cache,Values.STRING(prefix_str),SOME(st)) = Ceval.ceval(cache,env, filenameprefix, true, SOME(st),NONE(), msg);
      then
        (cache,prefix_str);
    case (_,_,_,_,_) then fail();
  end match;
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
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
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
      Option<Interactive.InteractiveSymbolTable> st;
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
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp)),_) = Ceval.ceval(cache, env, daeExp, impl, st, NONE(), msg);
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
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
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
      Option<Interactive.InteractiveSymbolTable> st;
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
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
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
      Option<Interactive.InteractiveSymbolTable> st;
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
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
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
      Option<Interactive.InteractiveSymbolTable> st;
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
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
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
      Option<Interactive.InteractiveSymbolTable> st;
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
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
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
      Option<Interactive.InteractiveSymbolTable> st;
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
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
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
      Option<Interactive.InteractiveSymbolTable> impl;
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
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
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
      Option<Interactive.InteractiveSymbolTable> st;
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
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
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
      Option<Interactive.InteractiveSymbolTable> st;
      Absyn.ElementArg m;
      Env.Cache cache;
    case (cache,env,{},_,_,msg,info) then (cache,{});
    /* TODO: look through redeclarations for Eval(var) as well */
    case (cache,env,(Absyn.MODIFICATION(finalItem = b,each_ = e,componentRef = cr,modification = SOME(mod),comment = stropt) :: args),impl,st,msg,info)
      equation
        (cache,mod_1) = cevalAstModification(cache,env, mod, impl, st, msg, info);
        (cache,res) = cevalAstEltargs(cache,env, args, impl, st, msg, info);
      then
        (cache,Absyn.MODIFICATION(b,e,cr,SOME(mod_1),stropt) :: res);
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
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
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
      Option<Interactive.InteractiveSymbolTable> st;
      Absyn.Exp e_1,e;
      Env.Cache cache;
    case (cache,env,{},_,_,msg,info) then (cache,{});
    case (cache,env,(Absyn.NOSUB() :: xs),impl,st,msg,info)
      equation
        (cache,res) = cevalAstArraydim(cache,env, xs, impl, st, msg, info);
      then
        (cache,Absyn.NOSUB() :: res);
    case (cache,env,(Absyn.SUBSCRIPT(subScript = e) :: xs),impl,st,msg,info)
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
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable) :=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg)
    local
      list<SCode.Class> p_1,sp;
      DAE.DAElist dae;
      list<Env.Frame> env;
      list<Interactive.InstantiatedClass> ic;
      BackendDAE.BackendDAE dlow,dlow1;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p,ptot;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Env.Cache cache;
      Integer eqnSize,varSize,simpleEqnSize,elimLevel;
      String errorMsg,warnings,eqnSizeStr,varSizeStr,retStr,classNameStr,simpleEqnSizeStr;
      BackendDAE.EquationArray eqns;
      Boolean partialPrefix,finalPrefix,encapsulatedPrefix,strEmpty;
      Absyn.Restriction restriction;
      Absyn.Info info;
      DAE.FunctionTree funcs;
      BackendDAE.Variables vars;
    
    // handle partial models
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation
        ptot = Dependency.getTotalProgram(className,p);
        // see if class is partial
        Absyn.CLASS(partialPrefix = partialPrefix as true, finalPrefix = finalPrefix, encapsulatedPrefix = encapsulatedPrefix, restriction =  restriction, info = info) = 
          Interactive.getPathedClassInProgram(className, p);
        // this case should not handle functions so here we check anything but functions!
        false = listMember(restriction, {Absyn.R_FUNCTION()});
        _ = Error.getMessagesStr() "Clear messages";
        Print.clearErrorBuf() "Clear error buffer";
        classNameStr = Absyn.pathString(className);
        /* this part is not needed anymore as when checkModel is active you can normally instantiate partial classes
           I leave it here as we might use it in some other part 
        // add a non-partial class to ptot with the same flags (final, encapsulated) and same restriction but instead of partial make it non-partial.
        Absyn.PROGRAM(classes, within_, globalBuildTimes) = ptot;
        classNameStr_dummy = classNameStr +& "_$_non_partial";
        // make a dummy class part containing an element definition as extends given-for-check-partial-class;
        dummyClassPart = 
                     Absyn.PUBLIC({
                       Absyn.ELEMENTITEM(
                          Absyn.ELEMENT(false, NONE(), Absyn.UNSPECIFIED(), "extends", 
                            Absyn.EXTENDS(className, {}, NONE()), // extend the given-for-check partial class 
                            info, NONE())
                                   )});
        dummyClass = Absyn.CLASS(classNameStr_dummy, 
                                 false, 
                                 finalPrefix, 
                                 encapsulatedPrefix, 
                                 restriction, 
                                 Absyn.PARTS({dummyClassPart}, NONE()),   
                                 info);
        // add the dummy class to the program
        ptot = Absyn.PROGRAM(dummyClass::classes, within_, globalBuildTimes);
        */
        // translate the program
        p_1 = SCodeUtil.translateAbsyn2SCode(ptot);

        //UnitParserExt.clear();
        //UnitAbsynBuilder.registerUnits(ptot);
        //UnitParserExt.commit();

        // instantiate the partial class nomally as it works during checkModel.
        (cache, env, _, dae) = Inst.instantiateClass(inCache, InnerOuter.emptyInstHierarchy, p_1, className);
        dae  = DAEUtil.transformationsBeforeBackend(dae);
        // adrpo: do not store instantiated class as we don't use it later!
        // ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dae,env));
        elimLevel = RTOpts.eliminationLevel();
        RTOpts.setEliminationLevel(0); // No variable elimination
        funcs = Env.getFunctionTree(cache);
        dlow = BackendDAECreate.lower(dae, funcs, false) "no dummy state" ;
        (dlow1,_,_) = BackendDAEUtil.preOptimiseBackendDAE(dlow,funcs,
            SOME({"removeSimpleEquations","expandDerOperator"}),NONE(),NONE());
        Debug.fcall("dumpdaelow", BackendDump.dump, dlow1);
        RTOpts.setEliminationLevel(elimLevel); // reset elimination level.
        eqns = BackendEquation.daeEqns(dlow1);
        eqnSize = BackendDAEUtil.equationSize(eqns);
        vars = BackendVariable.daeVars(dlow1);
        varSize = BackendVariable.varsSize(vars);
        (eqnSize,varSize) = subtractDummy(vars,eqnSize,varSize);
        simpleEqnSize = BackendDAEOptimize.countSimpleEquations(eqns);
        eqnSizeStr = intString(eqnSize);
        varSizeStr = intString(varSize);
        simpleEqnSizeStr = intString(simpleEqnSize);
        
        warnings = Error.printMessagesStr();
        retStr=stringAppendList({"Check of ",classNameStr," completed successfully.\n\n",warnings,"\nClass ",classNameStr," has ",eqnSizeStr," equation(s) and ",
          varSizeStr," variable(s).\n",simpleEqnSizeStr," of these are trivial equation(s).\n"});
      then
        (cache,Values.STRING(retStr),st);

    // handle normal models
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation
        ptot = Dependency.getTotalProgram(className,p);
        // non-partial non-functions
        Absyn.CLASS(partialPrefix = false, restriction = restriction) = Interactive.getPathedClassInProgram(className, p);
        // this case should not handle functions so here we check anything but functions!
        false = listMember(restriction, {Absyn.R_FUNCTION()});
        _ = Error.getMessagesStr() "Clear messages";
        Print.clearErrorBuf() "Clear error buffer";
        p_1 = SCodeUtil.translateAbsyn2SCode(ptot);

        //UnitParserExt.clear();
        //UnitAbsynBuilder.registerUnits(ptot);
        //UnitParserExt.commit();

        (cache, env, _, dae) =
        Inst.instantiateClass(inCache, InnerOuter.emptyInstHierarchy, p_1, className);
        dae  = DAEUtil.transformationsBeforeBackend(dae);
        // adrpo: do not store instantiated class as we don't use it later!
        // ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dae,env));
        elimLevel = RTOpts.eliminationLevel();
        RTOpts.setEliminationLevel(0); // No variable elimination
        funcs = Env.getFunctionTree(cache);
        dlow = BackendDAECreate.lower(dae, funcs, false) "no dummy state" ;
        (dlow1,_,_) = BackendDAEUtil.preOptimiseBackendDAE(dlow,funcs,
            SOME({"removeSimpleEquations","expandDerOperator"}),NONE(),NONE());
        Debug.fcall("dumpdaelow", BackendDump.dump, dlow1);
        RTOpts.setEliminationLevel(elimLevel); // reset elimination level.
        eqns = BackendEquation.daeEqns(dlow1);
        eqnSize = BackendDAEUtil.equationSize(eqns);
        vars = BackendVariable.daeVars(dlow1);
        varSize = BackendVariable.varsSize(vars);
        (eqnSize,varSize) = subtractDummy(vars,eqnSize,varSize);
        simpleEqnSize = BackendDAEOptimize.countSimpleEquations(eqns);
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
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation
        ptot = Dependency.getTotalProgram(className,p);
        Absyn.CLASS(_,_,_,_,Absyn.R_FUNCTION(),_,_) = Interactive.getPathedClassInProgram(className, p);
        _ = Error.getMessagesStr() "Clear messages";
        Print.clearErrorBuf() "Clear error buffer";
        p_1 = SCodeUtil.translateAbsyn2SCode(ptot);

        //UnitParserExt.clear();
        //UnitAbsynBuilder.registerUnits(ptot);
        //UnitParserExt.commit();

        (cache, env, _) =
        Inst.instantiateFunctionImplicit(inCache, InnerOuter.emptyInstHierarchy, p_1, className);

        // adrpo: do not store instantiated class as we don't use it later!
        // ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dae,env));
        classNameStr = Absyn.pathString(className);
        warnings = Error.printMessagesStr();
        // TODO: add a check if warnings is empty, if so then remove \n... --> warnings,"\nClass  <--- line below.
        retStr=stringAppendList({"Check of ",classNameStr," completed successfully.\n\n",warnings,"\n"});
      then
        (cache,Values.STRING(retStr),st);

    // errors
    case (cache,env,className,st,_)
      equation
      classNameStr = Absyn.pathString(className);
      errorMsg = Error.printMessagesStr();
      strEmpty = (stringCompare("",errorMsg)==0);
      errorMsg = Util.if_(strEmpty,"Internal error, check of model failed with no error message.",errorMsg);
      // errorMsg = errorMsg +& selectIfNotEmpty("Error Buffer:\n", Print.getErrorString());
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
        true = ModUtil.pathEqual(Absyn.joinPaths(path2,Absyn.IDENT(name)),path);
        ts =Absyn.setTimeStampBool(ts,false);
      then ((Absyn.CLASS(name,p,f,e,r,cdef,Absyn.INFO(fname,ro,i1,i2,i3,i4,ts)),SOME(path),path));
    case(inTpl) then inTpl;

    case((Absyn.CLASS(name,p,f,e,r,cdef,Absyn.INFO(fname,ro,i1,i2,i3,i4,ts)),NONE(),path))
      equation
        true = ModUtil.pathEqual(Absyn.IDENT(name),path);
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
      (_,_) = BackendVariable.getVar(ComponentReference.makeCrefIdent("$dummy",DAE.ET_OTHER(),{}),vars);
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
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable3;
  output String xml_filename "initFileName";
  output String xml_contents;
algorithm
  (outCache,outInteractiveSymbolTable3,xml_filename,xml_contents) :=
  matchcontinue (inCache,inEnv,vals,inInteractiveSymbolTable,inMsg)
    local
      Boolean cdToTemp;
      String cname_str,filenameprefix,oldDir,translationLevel;
      list<Interactive.InstantiatedClass> ic_1,ic;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      list<Env.Frame> env;
      Absyn.Path classname;
      Absyn.Program p;
      BackendDAE.BackendDAE dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      Env.Cache cache;
      Boolean addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals;
      Interactive.InteractiveSymbolTable st,st_1;
      Ceval.Msg msg;
      list<DAE.Function> funcelems;
      array<Integer> ass1,ass2;
      DAE.DAElist dae_1,dae;
      BackendDAE.IncidenceMatrix m,mT;
      Option<BackendDAE.IncidenceMatrix> om,omT;
      list<SCode.Class> p_1,sp;
      list<list<Integer>> comps;
      DAE.FunctionTree funcs;
    
    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="flat"),Values.BOOL(addOriginalIncidenceMatrix),Values.BOOL(addSolvingInfo),Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),Values.STRING(filenameprefix),Values.BOOL(cdToTemp)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        //translationLevel=DAE.SCONST(string="flat")
        _ = Error.getMessagesStr() "Clear messages";
        oldDir = System.pwd();
        changeToTempDirectory(cdToTemp);
        filenameprefix = Util.if_(filenameprefix ==& "<default>", Absyn.pathString(classname), filenameprefix);
        cname_str = Absyn.pathString(classname);
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env,_,dae_1) = Inst.instantiateClass(cache, InnerOuter.emptyInstHierarchy, p_1, classname);
        dae = DAEUtil.transformationsBeforeBackend(dae_1);
        funcs = Env.getFunctionTree(cache);
        dlow = BackendDAECreate.lower(dae, funcs, true); //Verificare cosa fa
        (dlow_1,_,_) = BackendDAEUtil.preOptimiseBackendDAE(dlow,funcs,NONE(),NONE(),NONE());
        dlow_1 = BackendDAECreate.findZeroCrossings(dlow_1);
        xml_filename = stringAppendList({filenameprefix,".xml"});
        funcelems = DAEUtil.getFunctionList(funcs);
        Print.clearBuf();
        XMLDump.dumpBackendDAE(dlow_1,funcelems,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals);
        xml_contents = Print.getString();
        Print.clearBuf();
        System.writeFile(xml_filename,xml_contents);
      then
        (cache,st,xml_contents,stringAppend("The model has been dumped to xml file: ",xml_filename));
      
    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="optimiser"),Values.BOOL(addOriginalIncidenceMatrix),Values.BOOL(addSolvingInfo),Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),Values.STRING(filenameprefix),Values.BOOL(cdToTemp)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        //translationLevel=DAE.SCONST(string="optimiser")
        //asInSimulationCode==false => it's NOT necessary to do all the translation's steps before dumping with xml
        _ = Error.getMessagesStr() "Clear messages";
        oldDir = System.pwd();
        changeToTempDirectory(cdToTemp);
        cname_str = Absyn.pathString(classname);
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env,_,dae_1) = Inst.instantiateClass(cache, InnerOuter.emptyInstHierarchy, p_1, classname);
        dae = DAEUtil.transformationsBeforeBackend(dae_1);
        funcs = Env.getFunctionTree(cache);
        dlow = BackendDAECreate.lower(dae, funcs, true); //Verificare cosa fa
        (dlow_1,om,omT) = BackendDAEUtil.preOptimiseBackendDAE(dlow,funcs,NONE(),NONE(),NONE());
        (dlow_1,_,_,_,_,_) = BackendDAEUtil.transformDAE(dlow_1,funcs,BackendDAETransform.dummyDerivative,om,omT);
        dlow_1 = BackendDAECreate.findZeroCrossings(dlow_1);
        xml_filename = stringAppendList({filenameprefix,".xml"});
        funcelems = DAEUtil.getFunctionList(Env.getFunctionTree(cache));
        Print.clearBuf();
        XMLDump.dumpBackendDAE(dlow_1,funcelems,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals);
        xml_contents = Print.getString();
        Print.clearBuf();
        System.writeFile(xml_filename,xml_contents);
      then
        (cache,st,xml_contents,stringAppend("The model has been dumped to xml file: ",xml_filename));
      
    case (cache,env,{Values.CODE(Absyn.C_TYPENAME(classname)),Values.STRING(string="backEnd"),Values.BOOL(addOriginalIncidenceMatrix),Values.BOOL(addSolvingInfo),Values.BOOL(addMathMLCode),Values.BOOL(dumpResiduals),Values.STRING(filenameprefix),Values.BOOL(cdToTemp)},(st as Interactive.SYMBOLTABLE(ast = p)),msg)
      equation
        //translationLevel=DAE.SCONST(string="backEnd")
        //asInSimulationCode==true => it's necessary to do all the translation's steps before dumping with xml
        _ = Error.getMessagesStr() "Clear messages";
        oldDir = System.pwd();
        changeToTempDirectory(cdToTemp);
        cname_str = Absyn.pathString(classname);
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env,_,dae_1) = Inst.instantiateClass(cache, InnerOuter.emptyInstHierarchy, p_1, classname);
        dae = DAEUtil.transformationsBeforeBackend(dae_1);
        funcs = Env.getFunctionTree(cache);
        dlow = BackendDAECreate.lower(dae, funcs, true);
        (indexed_dlow,_,_,_,_,_) = BackendDAEUtil.getSolvedSystem(cache, env, dlow, funcs,
          NONE(), BackendDAETransform.dummyDerivative, NONE());
        xml_filename = stringAppendList({filenameprefix,".xml"});
        funcelems = DAEUtil.getFunctionList(funcs);
        Print.clearBuf();
        XMLDump.dumpBackendDAE(indexed_dlow,funcelems,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals);
        xml_contents = Print.getString();
        Print.clearBuf();
        System.writeFile(xml_filename,xml_contents);
      then
        (cache,st,xml_contents,stringAppend("The model has been dumped to xml file: ",xml_filename));
    
  end matchcontinue;
end dumpXMLDAE;

protected function getClassnamesInClassList
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  output list<String> outStrings;
algorithm
  outStrings :=
  match (inPath,inProgram,inClass)
    local
      list<String> strlist;
      list<Absyn.ClassPart> parts;
      Absyn.Path inmodel,path;
      Absyn.Program p;
      String  baseClassName;
    case (_,_,Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation
        strlist = Interactive.getClassnamesInParts(parts);
      then
        strlist;

    case (inmodel,p,Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH(path = path))))
      equation
      then
        {};

    case (inmodel,p,Absyn.CLASS(body = Absyn.OVERLOAD(_, _)))
      equation
      then {};

    case (inmodel,p,Absyn.CLASS(body = Absyn.ENUMERATION(_, _)))
      equation
      then {};

    case (inmodel,p,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName, _, _, parts)))
      equation
        strlist = Interactive.getClassnamesInParts(parts);
      then strlist;

    case (inmodel,p,Absyn.CLASS(body = Absyn.PDER(_,_,_)))
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
  input Absyn.Program inProgram "the program";
  output list<Absyn.Path> outPaths;
algorithm
  outPaths :=
  matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef;
      String parent_string, s;
      list<String> strlst;
      Absyn.Program p;
      list<Absyn.Path> result_path_lst, result;
    case (inPath, p)
      equation
        cdef = Interactive.getPathedClassInProgram(inPath, p);
        strlst = getClassnamesInClassList(inPath, p, cdef);
        result_path_lst = Util.listMap1(strlst, joinPaths, inPath);
        result = Util.listFlatten(Util.listMap1(result_path_lst, getAllClassPathsRecursive, p));
      then
        inPath::result;
    case (inPath, _)
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
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg)
    local
      list<Absyn.Path> allClassPaths;
      list<SCode.Class> sp;
      list<Interactive.InstantiatedClass> ic;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Env.Cache cache;
      String ret;
      list<Env.Frame> env;
    
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation
        allClassPaths = getAllClassPathsRecursive(className, p);
        // allClassPaths = Util.listSelect(allClassPaths, filterLib);
        // allClassPaths = listReverse(allClassPaths);
        print("Number of classes to check: " +& intString(listLength(allClassPaths)) +& "\n");
        // print ("All paths: \n" +& Util.stringDelimitList(Util.listMap(allClassPaths, Absyn.pathString), "\n") +& "\n");
        checkAll(cache, env, allClassPaths, st, msg);
        ret = "Number of classes checked: " +& intString(listLength(allClassPaths));
      then
        (cache,Values.STRING(ret),st);
    
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
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
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
algorithm
  _ := matchcontinue (inCache,inEnv,allClasses,inInteractiveSymbolTable,inMsg)
    local
      list<Absyn.Path> rest;
      Absyn.Path className;
      list<SCode.Class> sp;
      list<Interactive.InstantiatedClass> ic;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Env.Cache cache;
      String  str, s;
      list<Env.Frame> env;
      Real t1, t2, elapsedTime;
      Absyn.ComponentRef cr;
      Absyn.Class c;
    case (cache,env,{},_,_) then ();

    case (cache,env,className::rest,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation
        c = Interactive.getPathedClassInProgram(className, p);
        // filter out partial classes
        // Absyn.CLASS(partialPrefix = false) = c; // do not filter partial classes
        cr = Absyn.pathToCref(className);
        // filter out packages
        false = Interactive.isPackage(cr, p);
        // filter out functions
        // false = Interactive.isFunction(cr, p);
        // filter out types
        false = Interactive.isType(cr, p);
        print("Checking: " +& Dump.unparseClassAttributesStr(c) +& " " +& Absyn.pathString(className) +& "... ");
        t1 = clock();
        OptManager.setOption("checkModel", true);
        (_,Values.STRING(str),_) = checkModel(cache, env, className, st, msg);
        OptManager.setOption("checkModel", false);
        t2 = clock(); elapsedTime = t2 -. t1; s = realString(elapsedTime);
        print (s +& " seconds -> " +& failOrSuccess(str) +& "\n\t");
        print (System.stringReplace(str, "\n", "\n\t"));
        print ("\n");
        checkAll(cache, env, rest, st, msg);
      then
        ();

    case (cache,env,className::rest,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
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
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output String outString1 "className";
  output String outString2 "method";
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable3;
  output String outString4 "initFileName";
algorithm
  (outCache,outString1,outString2,outInteractiveSymbolTable3,outString4):=
  match (inCache,inEnv,vals,inInteractiveSymbolTable,inMsg)
    local
      Values.Value ret_val;
      Interactive.InteractiveSymbolTable st,st_1,st2;
      BackendDAE.BackendDAE indexed_dlow_1;
      list<String> libs;
      String file_dir,method_str,filenameprefix,oldDir,s3;
      Absyn.Path classname;
      Absyn.Program p,p2;
      Absyn.Class cdef;
      list<Interactive.CompiledCFunction> cf;
      list<Env.Frame> env;
      Values.Value starttime,stoptime,interval,method,tolerance,fileprefix,storeInTemp,noClean,options;
      list<SCode.Class> sp;
      list<Interactive.InstantiatedClass> ic;
      list<Interactive.InteractiveVariable> iv;
      Ceval.Msg msg;
      Absyn.Within win1;
      Env.Cache cache;
      Boolean cdToTemp;
      SimCode.SimulationSettings simSettings;
      Absyn.TimeStamp ts;
    
    // normal call
    case (cache,env,vals as {Values.CODE(Absyn.C_TYPENAME(classname)),starttime,stoptime,interval,tolerance, method,Values.STRING(filenameprefix),Values.BOOL(cdToTemp),noClean,options},(st as Interactive.SYMBOLTABLE(ast = p  as Absyn.PROGRAM(globalBuildTimes=ts),explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation
        cdef = Interactive.getPathedClassInProgram(classname,p);
        _ = Error.getMessagesStr() "Clear messages";
        oldDir = System.pwd();
        changeToTempDirectory(cdToTemp);
        (cache,simSettings) = calculateSimulationSettings(cache,env,vals,st,msg);
        (cache,ret_val,st,indexed_dlow_1,libs,file_dir,_) 
          = translateModel(cache,env, classname, st, filenameprefix,true,SOME(simSettings));
        SimCode.SIMULATION_SETTINGS(method = method_str) = simSettings;
        //cname_str = Absyn.pathString(classname);
        //(cache,init_filename,starttime_r,stoptime_r,interval_r,tolerance_r,method_str,options_str,outputFormat_str) 
        //= calculateSimulationSettings(cache,env, exp, st, msg, cname_str);
        //SimCode.generateInitData(indexed_dlow_1, classname, filenameprefix, init_filename, starttime_r, stoptime_r, interval_r,tolerance_r,method_str,options_str,outputFormat_str);
        Debug.fprintln("dynload", "buildModel: about to compile model " +& filenameprefix +& ", " +& file_dir);
        compileModel(filenameprefix, libs, file_dir, "", method_str);
        Debug.fprintln("dynload", "buildModel: Compiling done.");
        // SimCodegen.generateMakefileBeast(makefilename, filenameprefix, libs, file_dir);
        win1 = getWithinStatement(classname);
        p2 = Absyn.PROGRAM({cdef},win1,ts);
        s3 = extractNoCleanCommand(noClean);
        compileModel(filenameprefix, libs, file_dir,s3,method_str);
        _ = System.cd(oldDir);
        // (p as Absyn.PROGRAM(globalBuildTimes=Absyn.TIMESTAMP(r1,r2))) = Interactive.updateProgram2(p2,p,false);
        st2 = st; // Interactive.replaceSymbolTableProgram(st,p);
      then
        (cache,filenameprefix,"",st2,"");
    
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
  functionName := ModUtil.pathStringReplaceDot(functionPath, "_");
end generateFunctionName;

public function cevalGenerateFunction "function: cevalGenerateFunction
  Generates code for a given function name."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output String functionName;
algorithm
  (outCache,functionName) :=
  matchcontinue (inCache,inEnv,inPath)
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
        false = RTOpts.debugFlag("nogen");
        false = RTOpts.debugFlag("generateCodeCheat");
        funcs = Env.getFunctionTree(cache);
        // First check if the main function exists... If it does not it might be an interactive function...
        mainFunction = DAEUtil.getNamedFunction(path, funcs);
        pathstr = generateFunctionName(path);
        paths = SimCode.getCalledFunctionsInFunction(path,funcs);

        // The list of functions is not ordered, so we need to filter out the main function...
        funcs = Env.getFunctionTree(cache);
        d = Util.listMap1(paths, DAEUtil.getNamedFunction, funcs);
        d = Util.listSetDifference(d, {mainFunction});
        uniontypePaths = DAEUtil.getUniontypePaths(d,{});
        (cache,metarecordTypes) = Lookup.lookupMetarecordsRecursive(cache, env, uniontypePaths);
        
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
        false = RTOpts.debugFlag("nogen");
        true = RTOpts.debugFlag("generateCodeCheat");
        funcs = Env.getFunctionTree(cache);
        // First check if the main function exists... If it does not it might be an interactive function...
        pathstr = generateFunctionName(path);
        
        // The list of functions is not ordered, so we need to filter out the main function...
        funcs = Env.getFunctionTree(cache);
        d = DAEUtil.getFunctionList(funcs);
        SimCode.translateFunctions(pathstr, NONE(), d, {}, {});
      then
        (cache, pathstr);

    case (cache, env, path)
      equation
        false = RTOpts.debugFlag("nogen");
        (cache,false) = Static.isExternalObjectFunction(cache,env,path);
        pathstr = generateFunctionName(path);
        pathstr = stringAppend("/*- CevalScript.cevalGenerateFunction failed(", pathstr);
        pathstr = stringAppend(pathstr,")*/\n");
        Debug.fprint("failtrace", pathstr);
      then
        fail();
  end matchcontinue;
end cevalGenerateFunction;

protected function generateFunctions
  input Env.Cache cache;
  input Env.Env env;
  input list<SCode.Class> sp;
  input list<tuple<String,list<String>>> acc;
  output list<tuple<String,list<String>>> deps;
algorithm
  deps := match (cache,env,sp,acc)
    local
      String name;
      list<String> names,dependencies;
      list<Absyn.Path> paths;
      list<SCode.Element> elementLst;
      DAE.FunctionTree funcs;
      list<DAE.Function> d;
    case (cache,env,{},acc) then acc;
    case (cache,env,SCode.CLASS(name="OpenModelica")::sp,acc)
      equation
        acc = generateFunctions(cache,env,sp,acc);
      then acc;
    case (cache,env,SCode.CLASS(name=name,encapsulatedPrefix=true,restriction=SCode.R_PACKAGE(),classDef=SCode.PARTS(elementLst=elementLst))::sp,acc)
      equation
        names = Util.listMap(Util.listFilterBoolean(Util.listMap(Util.listFilterBoolean(elementLst, SCode.elementIsClass), SCode.getElementClass), SCode.isFunction), SCode.className);
        paths = Util.listMap1r(names,Absyn.makeQualifiedPathFromStrings,name);
        cache = instantiateDaeFunctions(cache, env, paths);
        funcs = Env.getFunctionTree(cache);
        d = Util.listMap1(paths, DAEUtil.getNamedFunction, funcs);
        (_,(_,dependencies)) = DAEUtil.traverseDAEFunctions(d,Expression.traverseSubexpressionsHelper,(matchQualifiedCalls,{}));
        print(name +& " has dependencies: " +& Util.stringDelimitList(dependencies,",") +& "\n");
        acc = (name,dependencies)::acc;
        dependencies = Util.listMap1(dependencies,stringAppend,".h\"");
        dependencies = Util.listMap1r(dependencies,stringAppend,"#include \"");
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
    case ((e as DAE.CALL(path = Absyn.FULLYQUALIFIED(Absyn.QUALIFIED(name,Absyn.IDENT(_))), builtin = false),acc))
      equation
        acc = Util.listConsOnTrue(not listMember(name,acc),name,acc);
      then ((e,acc));
        /*
    case ((e as DAE.METARECORDCALL(path = Absyn.QUALIFIED(name,Absyn.QUALIFIED(path=Absyn.IDENT(_)))),acc))
      equation
        acc = Util.listConsOnTrue(not listMember(name,acc),name,acc);
      then ((e,acc));
      */
    case ((e as DAE.CREF(componentRef=cr,ty=DAE.ET_FUNCTION_REFERENCE_FUNC(builtin=false)),acc))
      equation
        Absyn.QUALIFIED(name,Absyn.IDENT(_)) = ComponentReference.crefToPath(cr);
        acc = Util.listConsOnTrue(not listMember(name,acc),name,acc);
      then ((e,acc));
    case itpl then itpl;
  end match;
end matchQualifiedCalls;

protected function instantiateDaeFunctions
  input Env.Cache cache;
  input Env.Env env;
  input list<Absyn.Path> paths;
  output Env.Cache outCache;
algorithm
  outCache := matchcontinue (cache,env,paths)
    local
      Absyn.Path path;
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
  input String name;
  input String modelicaPath;
  input Boolean printError;
  output String basePath;
algorithm
  basePath := matchcontinue (scheme,name,modelicaPath,printError)
    local
      list<String> mps,names;
      String gd,mp,bp,str;
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
  input list<String> mps;
  input list<String> names;
  output String basePath;
algorithm
  basePath := matchcontinue (mps,names)
    local
      String mp;
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

end CevalScript;
