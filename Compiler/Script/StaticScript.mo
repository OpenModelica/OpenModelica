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

encapsulated package StaticScript

public import Absyn;
public import DAE;
public import FCore;
public import GlobalScript;
public import Prefix;

protected type Ident = String;

protected

import Ceval;
import CevalScript;
import CevalScriptBackend;
import ClassInf;
import ComponentReference;
import Error;
import ErrorExt;
import Expression;
import ExpressionSimplify;
import Static;
import Types;
import Values;


protected function calculateSimulationTimes
"@author:
  Calculates the simulation times: startTime, stopTime, numberOfIntervals from the given input arguments"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inImplInst;
  input Option<GlobalScript.SymbolTable> inSymbolTable;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  input GlobalScript.SimulationOptions inSimOpt;
  output FCore.Cache outCache;
  output DAE.Exp startTime "start time, default 0.0";
  output DAE.Exp stopTime "stop time, default 1.0";
  output DAE.Exp numberOfIntervals "number of intervals, default 500";
algorithm
  (outCache, startTime, stopTime, numberOfIntervals) :=
  matchcontinue (inCache, inEnv, inAbsynExpLst, inAbsynNamedArgLst, inImplInst, inSymbolTable, inPrefix, inInfo, inSimOpt)
    local
      Absyn.ComponentRef cr;
      list<Absyn.NamedArg> args;
      Boolean impl;
      GlobalScript.SymbolTable st;
      Prefix.Prefix pre;
      SourceInfo info;
      Integer intervals;
      Real rstepTime, rstopTime, rstartTime;
      FCore.Cache cache;
      FCore.Graph env;

    // special case for Parham Vaseles OpenModelica Interactive, where buildModel takes stepSize instead of startTime, stopTime and numberOfIntervals
    case (cache,env,{Absyn.CREF()},args,impl,SOME(st),pre,info,_)
      equation
        // An ICONST is used as the default value of stepSize so that this case
        // fails if stepSize isn't given as argument to buildModel.
        (cache, DAE.RCONST(rstepTime)) =
          Static.getOptionalNamedArg(cache, env, SOME(st), impl, "stepSize", DAE.T_REAL_DEFAULT,
                              args, DAE.ICONST(0), // force failure if stepSize is not found via division by zero below!
                              pre, info);

        (cache,startTime as DAE.RCONST(rstartTime)) =
          Static.getOptionalNamedArg(cache, env, SOME(st), impl, "startTime", DAE.T_REAL_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(inSimOpt, "startTime"),
                              pre, info);

        (cache,stopTime as DAE.RCONST(rstopTime)) =
          Static.getOptionalNamedArg(cache, env, SOME(st), impl, "stopTime", DAE.T_REAL_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(inSimOpt, "stopTime"),
                              pre, info);

        intervals = realInt((rstopTime - rstartTime) / rstepTime);
        numberOfIntervals = DAE.ICONST(intervals);
      then
        (cache, startTime, stopTime, numberOfIntervals);

    // normal case, fill in defaults
    case (cache,env,{Absyn.CREF()},args,impl,SOME(st),pre,info,_)
      equation
        // An ICONST is used as the default value of stepSize so that this case
        // fails if stepSize isn't given as argument to buildModel.
        (cache,startTime) =
          Static.getOptionalNamedArg(cache, env, SOME(st), impl, "startTime", DAE.T_REAL_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(inSimOpt, "startTime"),
                              pre, info);

        (cache,stopTime) =
          Static.getOptionalNamedArg(cache, env, SOME(st), impl, "stopTime", DAE.T_REAL_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(inSimOpt, "stopTime"),
                              pre, info);

        (cache,numberOfIntervals) =
          Static.getOptionalNamedArg(cache, env, SOME(st), impl, "numberOfIntervals", DAE.T_INTEGER_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(inSimOpt, "numberOfIntervals"),
                              pre, info);
      then
        (cache, startTime, stopTime, numberOfIntervals);

   end matchcontinue;
end calculateSimulationTimes;



public function getSimulationArguments
"@author: adrpo
  This functiong gets the simulation options"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inImplInst;
  input Option<GlobalScript.SymbolTable> inSymbolTable;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  input Option<GlobalScript.SimulationOptions> defaultOption;
  output FCore.Cache outCache;
  output list<DAE.Exp> outSimulationArguments;
algorithm
  (outCache, outSimulationArguments) :=
  match (inCache, inEnv, inAbsynExpLst, inAbsynNamedArgLst, inImplInst, inSymbolTable, inPrefix, inInfo, defaultOption)
    local
      Absyn.Exp crexp;
      list<Absyn.NamedArg> args;
      Boolean impl;
      GlobalScript.SymbolTable st;
      Prefix.Prefix pre;
      SourceInfo info;
      String cname_str;
      Absyn.Path className;
      DAE.Exp exp,startTime,stopTime,numberOfIntervals,tolerance,method,cflags,simflags;
      DAE.Exp fileNamePrefix,options,outputFormat,variableFilter;
      GlobalScript.SimulationOptions defaulSimOpt;
      FCore.Cache cache;
      FCore.Graph env;
      Values.Value v;

    // fill in defaults
    case (cache,env,{crexp},args,impl,SOME(st),pre,info,_)
      equation
        exp = Static.elabCodeExp(crexp,cache,env,DAE.C_TYPENAME(),SOME(st),info);
        // We need to force eval in order to get the correct prefix
        (cache,v,SOME(st)) = Ceval.ceval(cache,env,exp,true,SOME(st),Absyn.MSG(info),0);
        Values.CODE(Absyn.C_TYPENAME(className)) = CevalScript.evalCodeTypeName(v,env);

        cname_str = Absyn.pathString(Absyn.unqotePathIdents(className)) "easier than checking if the file system supports UTF-8...";
        defaulSimOpt = CevalScriptBackend.buildSimulationOptionsFromModelExperimentAnnotation(st, className, cname_str, defaultOption);

        (cache, startTime, stopTime, numberOfIntervals) =
          calculateSimulationTimes(inCache, inEnv, inAbsynExpLst, inAbsynNamedArgLst, impl, inSymbolTable, inPrefix, inInfo, defaulSimOpt);

        (cache,tolerance) =
          Static.getOptionalNamedArg(cache, env, SOME(st), impl, "tolerance", DAE.T_REAL_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(defaulSimOpt, "tolerance"),
                              pre,info);

        (cache,method) =
          Static.getOptionalNamedArg(cache, env, SOME(st), impl, "method", DAE.T_STRING_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(defaulSimOpt, "method"),
                              pre, info);

        (cache,fileNamePrefix) =
          Static.getOptionalNamedArg(cache,env, SOME(st), impl, "fileNamePrefix",  DAE.T_STRING_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(defaulSimOpt, "fileNamePrefix"),
                              pre, info);

        (cache,options) =
          Static.getOptionalNamedArg(cache, env, SOME(st), impl, "options", DAE.T_STRING_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(defaulSimOpt, "options"),
                              pre, info);

        (cache,outputFormat) =
          Static.getOptionalNamedArg(cache, env, SOME(st), impl, "outputFormat", DAE.T_STRING_DEFAULT,
                              args,  CevalScriptBackend.getSimulationOption(defaulSimOpt, "outputFormat"),
                              pre, info);

        (cache,variableFilter) =
          Static.getOptionalNamedArg(cache, env, SOME(st), impl, "variableFilter", DAE.T_STRING_DEFAULT,
                              args,  CevalScriptBackend.getSimulationOption(defaulSimOpt, "variableFilter"),
                              pre, info);

        (cache,cflags) =
          Static.getOptionalNamedArg(cache, env, SOME(st), impl, "cflags", DAE.T_STRING_DEFAULT,
                              args,  CevalScriptBackend.getSimulationOption(defaulSimOpt, "cflags"),
                              pre, info);
        (cache,simflags) =
          Static.getOptionalNamedArg(cache, env, SOME(st), impl, "simflags", DAE.T_STRING_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(defaulSimOpt, "simflags"),
                              pre, info);

      then
        (cache,
         {DAE.CODE(Absyn.C_TYPENAME(className),DAE.T_UNKNOWN_DEFAULT),
          startTime,
          stopTime,
          numberOfIntervals,
          tolerance,
          method,
          fileNamePrefix,
          options,
          outputFormat,
          variableFilter,
          cflags,
          simflags});

  end match;
end getSimulationArguments;

public function elabCallInteractive "This function elaborates the functions defined in the interactive environment.
  Since some of these functions are meta-functions, they can not be described in the type
  system, and is thus given the the type T_UNKNOWN"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Exp> inExps;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplInst;
  input Option<GlobalScript.SymbolTable> inSymbolTable;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outSymbolTable;
 algorithm
   (outCache,outExp,outProperties,outSymbolTable):=
   matchcontinue
     (inCache,inEnv,inComponentRef,inExps,inNamedArgs,inImplInst,inSymbolTable,inPrefix,info)
    local
      DAE.ComponentRef cr_1;
      FCore.Graph env;
      Absyn.ComponentRef cr,cr2;
      Boolean impl;
      GlobalScript.SymbolTable st;
      Ident cname_str,str;
      DAE.Exp filenameprefix,exp_1,crefExp,outputFile,dumpExtractionSteps,fmuversion,fmuType;
      DAE.Type recordtype;
      list<Absyn.NamedArg> args;
      list<DAE.Exp> excludeList;
      DAE.Properties prop;
      Option<GlobalScript.SymbolTable> st_1;
      Integer excludeListSize;
      Absyn.Exp exp;
      FCore.Cache cache;
      Prefix.Prefix pre;
      Absyn.Path className;
      list<DAE.Exp> simulationArgs;
      String name;
    case (cache,env,cr2 as Absyn.CREF_IDENT(),_,_,impl,SOME(st),_,_)
      equation
        ErrorExt.setCheckpoint("Scripting");
        cr = Absyn.joinCrefs(Absyn.CREF_QUAL("OpenModelica",{},Absyn.CREF_IDENT("Scripting",{})),cr2);
        (cache,exp_1,prop,st_1) = Static.elabExp(cache,env,Absyn.CALL(cr,Absyn.FUNCTIONARGS(inExps,inNamedArgs)),impl,SOME(st),false,inPrefix,info);
        ErrorExt.delCheckpoint("Scripting");
      then (cache,exp_1,prop,st_1);

    case (_,_,Absyn.CREF_IDENT(),_,_,_,SOME(_),_,_)
      equation
        ErrorExt.rollBack("Scripting");
      then fail();

    case (cache,env,Absyn.CREF_IDENT(name = "translateModel"),{Absyn.CREF()},args,_,SOME(st),_,_)
      equation
        (cache, simulationArgs) = getSimulationArguments(cache, env, inExps, args, inImplInst, inSymbolTable, inPrefix, info, NONE());
      then
        (cache,Expression.makePureBuiltinCall("translateModel",simulationArgs,DAE.T_STRING_DEFAULT),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

   case (cache,env,Absyn.CREF_IDENT(name = "modelEquationsUC"),{Absyn.CREF(componentRef = cr)},args,impl,SOME(st),pre,_)
      equation
        (cache,cr_1) = Static.elabUntypedCref(cache,env,cr,impl,pre,info);
        className = ComponentReference.crefToPathIgnoreSubs(cr_1) "this extracts the fileNamePrefix which is used when generating code and init-file" ;
        (cache,outputFile) = Static.getOptionalNamedArg(cache, env, SOME(st), impl, "outputFile", DAE.T_STRING_DEFAULT,args, DAE.SCONST(""),pre,info);
        (cache,dumpExtractionSteps) = Static.getOptionalNamedArg(cache,env,SOME(st),impl,"dumpSteps",DAE.T_BOOL_DEFAULT,args,DAE.BCONST(false),pre,info);
      then
        (cache,Expression.makePureBuiltinCall("modelEquationsUC",{DAE.CODE(Absyn.C_TYPENAME(className),DAE.T_UNKNOWN_DEFAULT),outputFile,dumpExtractionSteps},DAE.T_STRING_DEFAULT),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

   case (cache,env,Absyn.CREF_IDENT(name = "translateModelCPP"),{Absyn.CREF(componentRef = cr)},args,impl,SOME(st),pre,_)
      equation
        className = Absyn.crefToPath(cr);
        cname_str = Absyn.pathString(className);
        (cache,filenameprefix) = Static.getOptionalNamedArg(cache,env, SOME(st), impl, "fileNamePrefix",
                                                     DAE.T_STRING_DEFAULT, args, DAE.SCONST(cname_str),pre,info);
        recordtype =
        DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationObject")),
        {DAE.TYPES_VAR("flatClass",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
         DAE.TYPES_VAR("exeFile",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE())},
          NONE(),DAE.emptyTypeSource);
      then
        (cache,Expression.makePureBuiltinCall("translateModelCPP",
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.T_UNKNOWN_DEFAULT),filenameprefix},DAE.T_STRING_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "translateModelFMU"),{Absyn.CREF(componentRef = cr)},args,impl,SOME(st),pre,_)
      equation
        className = Absyn.crefToPath(cr);
        cname_str = Absyn.pathString(className);
        (cache,fmuversion) = Static.getOptionalNamedArg(cache,env, SOME(st), impl, "version",
                                                     DAE.T_STRING_DEFAULT, args, DAE.SCONST("1.0"),pre,info);
        (cache,fmuType) = Static.getOptionalNamedArg(cache,env, SOME(st), impl, "fmuType",
                                                     DAE.T_STRING_DEFAULT, args, DAE.SCONST("me"),pre,info);
        (cache, filenameprefix) = Static.getOptionalNamedArg(cache,env, SOME(st), impl, "fileNamePrefix",
                                                     DAE.T_STRING_DEFAULT, args, DAE.SCONST(cname_str),pre,info);
        recordtype =
          DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationObject")),
          {DAE.TYPES_VAR("flatClass",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
           DAE.TYPES_VAR("exeFile",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE())},
           NONE(),DAE.emptyTypeSource);
      then
        (cache,Expression.makePureBuiltinCall("translateModelFMU",
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.T_UNKNOWN_DEFAULT),fmuversion,fmuType,filenameprefix},DAE.T_STRING_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "translateModelXML"),{Absyn.CREF(componentRef = cr)},args,impl,SOME(st),pre,_)
      equation
        className = Absyn.crefToPath(cr);
        cname_str = Absyn.pathString(className);
        (cache,filenameprefix) = Static.getOptionalNamedArg(cache,env, SOME(st), impl, "fileNamePrefix",
                                                     DAE.T_STRING_DEFAULT, args, DAE.SCONST(cname_str),pre,info);
        recordtype =
          DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationObject")),
          {DAE.TYPES_VAR("flatClass",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
           DAE.TYPES_VAR("exeFile",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE())},
           NONE(),DAE.emptyTypeSource);
      then
        (cache,Expression.makePureBuiltinCall("translateModelXML",
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.T_UNKNOWN_DEFAULT),filenameprefix},DAE.T_STRING_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "exportDAEtoMatlab"),{Absyn.CREF(componentRef = cr)},args,impl,SOME(st),pre,_)
      equation
        className = Absyn.crefToPath(cr);
        cname_str = Absyn.pathString(className);
        (cache,filenameprefix) = Static.getOptionalNamedArg(cache,env, SOME(st), impl, "fileNamePrefix",
          DAE.T_STRING_DEFAULT, args, DAE.SCONST(cname_str),pre,info);
        recordtype =
          DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationObject")),
          {DAE.TYPES_VAR("flatClass",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
           DAE.TYPES_VAR("exeFile",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE())},
           NONE(),DAE.emptyTypeSource);
      then
        (cache,Expression.makePureBuiltinCall("exportDAEtoMatlab",
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.T_UNKNOWN_DEFAULT),filenameprefix},DAE.T_STRING_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "buildModel"),{Absyn.CREF()},args,_,SOME(st),_,_)
      equation
        (cache, simulationArgs) = getSimulationArguments(cache, env, inExps, args, inImplInst, inSymbolTable, inPrefix, info, NONE());
      then
        (cache,Expression.makePureBuiltinCall("buildModel",simulationArgs,DAE.T_UNKNOWN_DEFAULT),
         DAE.PROP(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_INTEGER(2)},DAE.emptyTypeSource),DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "buildModelBeast"),{Absyn.CREF()},args,_,SOME(st),_,_)
      equation
        (cache, simulationArgs) = getSimulationArguments(cache, env, inExps, args, inImplInst, inSymbolTable, inPrefix, info, NONE());
      then
        (cache,Expression.makePureBuiltinCall("buildModelBeast",simulationArgs,DAE.T_UNKNOWN_DEFAULT),
         DAE.PROP(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_INTEGER(2)},DAE.emptyTypeSource),DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "simulate"),{Absyn.CREF()},args,_,SOME(st),_,_) /* Fill in rest of defaults here */
      equation
        (cache, simulationArgs) = getSimulationArguments(cache, env, inExps, args, inImplInst, inSymbolTable, inPrefix, info, NONE());
        recordtype = CevalScriptBackend.getSimulationResultType();
      then
        (cache,Expression.makePureBuiltinCall("simulate",simulationArgs,DAE.T_UNKNOWN_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "simulation"),{Absyn.CREF()},args,_,SOME(st),_,_) /* Fill in rest of defaults here */
      equation
        (cache, simulationArgs) = getSimulationArguments(cache, env, inExps, args, inImplInst, inSymbolTable, inPrefix, info, NONE());
        recordtype = CevalScriptBackend.getDrModelicaSimulationResultType();
      then
        (cache,Expression.makePureBuiltinCall("simulation",simulationArgs,DAE.T_UNKNOWN_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "linearize"),{Absyn.CREF()},args,_,SOME(st),_,_) /* Fill in rest of defaults here */
      equation
        (cache, simulationArgs) = getSimulationArguments(cache, env, inExps, args, inImplInst, inSymbolTable, inPrefix, info, NONE());
        recordtype = CevalScriptBackend.getSimulationResultType();
      then
        (cache,Expression.makePureBuiltinCall("linearize",simulationArgs,DAE.T_UNKNOWN_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "optimize"),{Absyn.CREF()},args,_,SOME(st),_,_) /* Fill in rest of defaults here */
      equation
        (cache, simulationArgs) = getSimulationArguments(cache, env, inExps, args, inImplInst, inSymbolTable, inPrefix, info, NONE());
        recordtype = CevalScriptBackend.getSimulationResultType();
      then
        (cache,Expression.makePureBuiltinCall("optimize",simulationArgs,DAE.T_UNKNOWN_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()),SOME(st));


    case (cache,env,Absyn.CREF_IDENT(name = "jacobian"),{Absyn.CREF(componentRef = cr)},_,impl,SOME(st),pre,_) /* Fill in rest of defaults here */
      equation
        (cache,cr_1) = Static.elabUntypedCref(cache,env,cr,impl,pre,info);
        crefExp = Expression.crefExp(cr_1);
      then
        (cache,Expression.makePureBuiltinCall("jacobian",{crefExp},DAE.T_STRING_DEFAULT),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "timing"),{exp},{},impl,SOME(st),pre,_)
      equation
        (cache,exp_1,_,st_1) = elabExp(cache,env, exp, impl, SOME(st),true,pre,info);
      then
        (cache,Expression.makePureBuiltinCall("timing",{exp_1},DAE.T_REAL_DEFAULT),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()),st_1);

      // MathCore-specific. Should be in MathCoreBuiltin.mo :p
    case (cache,_,Absyn.CREF_IDENT(name = "checkExamplePackages"),{},args,_,SOME(st),_,_)
      equation
        excludeList = Static.getOptionalNamedArgExpList("exclude", args);
        excludeListSize = listLength(excludeList);
      then
        (cache,Expression.makePureBuiltinCall("checkExamplePackages",
        {DAE.ARRAY(DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT,{DAE.DIM_INTEGER(excludeListSize)},DAE.emptyTypeSource),false,excludeList)},
        DAE.T_STRING_DEFAULT),
        DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()),SOME(st));

    case (cache,_,Absyn.CREF_IDENT(name = "checkExamplePackages"),{Absyn.STRING(value = str)},args,_,SOME(st),_,_)
      equation
        excludeList = Static.getOptionalNamedArgExpList("exclude", args);
        excludeListSize = listLength(excludeList);
      then
        (cache,Expression.makePureBuiltinCall("checkExamplePackages",
        {DAE.ARRAY(DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT,{DAE.DIM_INTEGER(excludeListSize)},DAE.emptyTypeSource),false,excludeList),DAE.SCONST(str)},
        DAE.T_STRING_DEFAULT),
        DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()),SOME(st));

    case (cache,_,Absyn.CREF_IDENT(name = "checkExamplePackages"),{Absyn.CREF(componentRef = cr)},args,_,SOME(st),_,_)
      equation
        className = Absyn.crefToPath(cr);
        excludeList = Static.getOptionalNamedArgExpList("exclude", args);
        excludeListSize = listLength(excludeList);
      then
        (cache,Expression.makePureBuiltinCall("checkExamplePackages",
        {DAE.ARRAY(DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT,{DAE.DIM_INTEGER(excludeListSize)},DAE.emptyTypeSource),false,excludeList),
        DAE.CODE(Absyn.C_TYPENAME(className),DAE.T_UNKNOWN_DEFAULT)},
        DAE.T_STRING_DEFAULT),
        DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()),SOME(st));

    case (cache,_,Absyn.CREF_IDENT(name = "checkExamplePackages"),{Absyn.CREF(componentRef = cr), Absyn.STRING(value = str)},args,_,SOME(st),_,_)
      equation
        className = Absyn.crefToPath(cr);
        excludeList = Static.getOptionalNamedArgExpList("exclude", args);
        excludeListSize = listLength(excludeList);
      then
        (cache,Expression.makePureBuiltinCall("checkExamplePackages",
        {DAE.ARRAY(DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT,{DAE.DIM_INTEGER(excludeListSize)},DAE.emptyTypeSource),false,excludeList),
         DAE.CODE(Absyn.C_TYPENAME(className),DAE.T_UNKNOWN_DEFAULT),DAE.SCONST(str)},
        DAE.T_STRING_DEFAULT),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()),SOME(st));

  end matchcontinue;
end elabCallInteractive;

public function elabExp "
function: elabExp
   This is an special case tha considers elabCallInteractive. If this function fails elabExp is called."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inSymbolTable;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> st;
algorithm
  (outCache,outExp,outProperties,st) := elabExp2(inCache,inEnv,inExp,inImplicit,inSymbolTable,performVectorization,inPrefix,info,Error.getNumErrorMessages());
end elabExp;


protected function elabExp2 "
function: Auxiliary function to elabExp that considers elabCallInteractive. If this function fails elabExp is called."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inSymbolTable;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  input Integer numErrorMessages;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outSymbolTable;
algorithm
  (outCache,outExp,outProperties,outSymbolTable):=
  matchcontinue (inCache,inEnv,inExp,inImplicit,inSymbolTable,performVectorization,inPrefix,info,numErrorMessages)
    local
      Boolean impl,doVect;
      Option<GlobalScript.SymbolTable> st,st_1;
      DAE.Exp e_1;
      DAE.Properties prop;
      FCore.Graph env;
      Absyn.ComponentRef fn;
      DAE.Const c;
      Absyn.Exp exp;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      FCore.Cache cache;
      Prefix.Prefix pre;
  case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),impl,st,_,pre,_,_)
      equation
        (cache,e_1,prop,st_1) = elabCall(cache, env, fn, args, nargs, impl, st, pre, info, Error.getNumErrorMessages());
        _ = Types.propAllConst(prop);
        (e_1,_) = ExpressionSimplify.simplify1(e_1);
      then
        (cache,e_1,prop,st_1);
    case (cache,env,exp,impl,st,doVect,pre,_,_)
      equation
        (cache,e_1,prop,st_1) = Static.elabExp(cache,env,exp,impl,st,doVect,pre,info);
      then
         (cache,e_1,prop,st_1);
  end matchcontinue;
end elabExp2;


protected function elabCall "
function: elabCall
  This is an special case that considers elabCallInteractive."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inImplInst;
  input Option<GlobalScript.SymbolTable> inSymbolTable;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  input Integer numErrorMessages;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outSymbolTable;
algorithm
  (outCache,outExp,outProperties,outSymbolTable):=
  match (inCache,inEnv,inComponentRef,inAbsynExpLst,inAbsynNamedArgLst,inImplInst,inSymbolTable,inPrefix,info,numErrorMessages)
    local
      DAE.Exp e;
      DAE.Properties prop;
      Option<GlobalScript.SymbolTable> st;
      FCore.Graph env;
      Absyn.ComponentRef fn;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl;
      FCore.Cache cache;
      Prefix.Prefix pre;
  case (cache,env,fn,args,nargs,impl,st as SOME(_),pre,_,_)
      equation
        (cache,e,prop,st) = elabCallInteractive(cache, env, fn, args, nargs, impl, st, pre, info) "Elaborate interactive function calls, such as simulate(), plot() etc." ;
      then
        (cache,e,prop,st);
  end match;
end elabCall;

public function elabGraphicsExp
"This is an special case tha considers elabCallInteractive. If this function fails Static.elabGraphicsExp is called"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inImplInst;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inExp,inImplInst,inPrefix,info)
    local
      Boolean impl;
      DAE.Exp e_1;
      DAE.Properties prop;
      FCore.Graph env;
      Absyn.ComponentRef fn;
      Absyn.Exp e;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      FCore.Cache cache;
      Prefix.Prefix pre;
    // Function calls
    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),_,pre,_)
      equation
        (cache,e_1,prop,_) = elabCall(cache,env, fn, args, nargs, true,NONE(),pre,info,Error.getNumErrorMessages());
      then
        (cache,e_1,prop);
    case (cache,env,e,impl,pre,_)
      equation
        (cache,e_1,prop) = Static.elabGraphicsExp(cache,env,e,impl,pre,info);
      then
        (cache,e_1,prop);
  end matchcontinue;
end elabGraphicsExp;

annotation(__OpenModelica_Interface="backend");
end StaticScript;
