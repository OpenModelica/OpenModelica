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
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  input GlobalScript.SimulationOptions inSimOpt;
  output FCore.Cache outCache;
  output DAE.Exp startTime "start time, default 0.0";
  output DAE.Exp stopTime "stop time, default 1.0";
  output DAE.Exp numberOfIntervals "number of intervals, default 500";
algorithm
  (outCache, startTime, stopTime, numberOfIntervals) :=
  matchcontinue (inCache, inEnv, inAbsynExpLst, inAbsynNamedArgLst, inImplInst, inPrefix, inInfo, inSimOpt)
    local
      Absyn.ComponentRef cr;
      list<Absyn.NamedArg> args;
      Boolean impl;
      Prefix.Prefix pre;
      SourceInfo info;
      Integer intervals;
      Real rstepTime, rstopTime, rstartTime;
      FCore.Cache cache;
      FCore.Graph env;

    // special case for Parham Vaseles OpenModelica Interactive, where buildModel takes stepSize instead of startTime, stopTime and numberOfIntervals
    case (cache,env,{Absyn.CREF()},args,impl,pre,info,_)
      equation
        // An ICONST is used as the default value of stepSize so that this case
        // fails if stepSize isn't given as argument to buildModel.
        (cache, DAE.RCONST(rstepTime)) =
          Static.getOptionalNamedArg(cache, env, impl, "stepSize", DAE.T_REAL_DEFAULT,
                              args, DAE.ICONST(0), // force failure if stepSize is not found via division by zero below!
                              pre, info);

        (cache,startTime as DAE.RCONST(rstartTime)) =
          Static.getOptionalNamedArg(cache, env, impl, "startTime", DAE.T_REAL_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(inSimOpt, "startTime"),
                              pre, info);

        (cache,stopTime as DAE.RCONST(rstopTime)) =
          Static.getOptionalNamedArg(cache, env, impl, "stopTime", DAE.T_REAL_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(inSimOpt, "stopTime"),
                              pre, info);

        intervals = realInt((rstopTime - rstartTime) / rstepTime);
        numberOfIntervals = DAE.ICONST(intervals);
      then
        (cache, startTime, stopTime, numberOfIntervals);

    // normal case, fill in defaults
    case (cache,env,{Absyn.CREF()},args,impl,pre,info,_)
      equation
        // An ICONST is used as the default value of stepSize so that this case
        // fails if stepSize isn't given as argument to buildModel.
        (cache,startTime) =
          Static.getOptionalNamedArg(cache, env, impl, "startTime", DAE.T_REAL_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(inSimOpt, "startTime"),
                              pre, info);

        (cache,stopTime) =
          Static.getOptionalNamedArg(cache, env, impl, "stopTime", DAE.T_REAL_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(inSimOpt, "stopTime"),
                              pre, info);

        (cache,numberOfIntervals) =
          Static.getOptionalNamedArg(cache, env, impl, "numberOfIntervals", DAE.T_INTEGER_DEFAULT,
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
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  input Option<GlobalScript.SimulationOptions> defaultOption;
  output FCore.Cache outCache;
  output list<DAE.Exp> outSimulationArguments;
algorithm
  (outCache, outSimulationArguments) :=
  match (inCache, inEnv, inAbsynExpLst, inAbsynNamedArgLst, inImplInst, inPrefix, inInfo, defaultOption)
    local
      Absyn.Exp crexp;
      list<Absyn.NamedArg> args;
      Boolean impl;
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
    case (cache,env,{crexp},args,impl,pre,info,_)
      equation
        exp = Static.elabCodeExp(crexp,cache,env,DAE.C_TYPENAME(),info);
        // We need to force eval in order to get the correct prefix
        (cache,v) = Ceval.ceval(cache,env,exp,true,Absyn.MSG(info),0);
        Values.CODE(Absyn.C_TYPENAME(className)) = CevalScript.evalCodeTypeName(v,env);

        cname_str = Absyn.pathString(Absyn.unqotePathIdents(className)) "easier than checking if the file system supports UTF-8...";
        defaulSimOpt = CevalScriptBackend.buildSimulationOptionsFromModelExperimentAnnotation(className, cname_str, defaultOption);

        (cache, startTime, stopTime, numberOfIntervals) =
          calculateSimulationTimes(inCache, inEnv, inAbsynExpLst, inAbsynNamedArgLst, impl, inPrefix, inInfo, defaulSimOpt);

        (cache,tolerance) =
          Static.getOptionalNamedArg(cache, env, impl, "tolerance", DAE.T_REAL_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(defaulSimOpt, "tolerance"),
                              pre,info);

        (cache,method) =
          Static.getOptionalNamedArg(cache, env, impl, "method", DAE.T_STRING_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(defaulSimOpt, "method"),
                              pre, info);

        (cache,fileNamePrefix) =
          Static.getOptionalNamedArg(cache,env, impl, "fileNamePrefix",  DAE.T_STRING_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(defaulSimOpt, "fileNamePrefix"),
                              pre, info);

        (cache,options) =
          Static.getOptionalNamedArg(cache, env, impl, "options", DAE.T_STRING_DEFAULT,
                              args, CevalScriptBackend.getSimulationOption(defaulSimOpt, "options"),
                              pre, info);

        (cache,outputFormat) =
          Static.getOptionalNamedArg(cache, env, impl, "outputFormat", DAE.T_STRING_DEFAULT,
                              args,  CevalScriptBackend.getSimulationOption(defaulSimOpt, "outputFormat"),
                              pre, info);

        (cache,variableFilter) =
          Static.getOptionalNamedArg(cache, env, impl, "variableFilter", DAE.T_STRING_DEFAULT,
                              args,  CevalScriptBackend.getSimulationOption(defaulSimOpt, "variableFilter"),
                              pre, info);

        (cache,cflags) =
          Static.getOptionalNamedArg(cache, env, impl, "cflags", DAE.T_STRING_DEFAULT,
                              args,  CevalScriptBackend.getSimulationOption(defaulSimOpt, "cflags"),
                              pre, info);
        (cache,simflags) =
          Static.getOptionalNamedArg(cache, env, impl, "simflags", DAE.T_STRING_DEFAULT,
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
  input output FCore.Cache cache;
  input FCore.Graph env;
  input Absyn.ComponentRef fn;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean impl;
  input Prefix.Prefix pre;
  input SourceInfo info;
  output DAE.Exp e;
  output DAE.Properties prop;
protected
  list<Integer> handles;
algorithm
  if Flags.getConfigBool(Flags.BUILDING_MODEL) then
    ErrorExt.delCheckpoint("elabCall_InteractiveFunction");
    fail();
  end if;
  handles := ErrorExt.popCheckPoint("elabCall_InteractiveFunction");
  try
    /* An extra try-block to avoid the assignment to handles being optimized away */
    ErrorExt.setCheckpoint("elabCall_InteractiveFunction1");
    (cache,e,prop) := elabCallInteractive_work(cache, env, fn, args, nargs, impl, pre, info) "Elaborate interactive function calls, such as simulate(), plot() etc." ;
    ErrorExt.delCheckpoint("elabCall_InteractiveFunction1");
  else
    ErrorExt.rollBack("elabCall_InteractiveFunction1");
    ErrorExt.pushMessages(handles);
    fail();
  end try;
  ErrorExt.freeMessages(handles);
end elabCallInteractive;

protected function elabCallInteractive_work "This function elaborates the functions defined in the interactive environment.
  Since some of these functions are meta-functions, they can not be described in the type
  system, and is thus given the the type T_UNKNOWN"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Exp> inExps;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplInst;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
   (outCache,outExp,outProperties):=
   matchcontinue
     (inCache,inEnv,inComponentRef,inExps,inNamedArgs,inImplInst,inPrefix,info)
    local
      DAE.ComponentRef cr_1;
      FCore.Graph env;
      Absyn.ComponentRef cr,cr2;
      Boolean impl;
      Ident cname_str,str;
      DAE.Exp filenameprefix,exp_1,crefExp,outputFile,dumpExtractionSteps,fmuversion,fmuType;
      DAE.Type recordtype;
      list<Absyn.NamedArg> args;
      list<DAE.Exp> excludeList;
      DAE.Properties prop;
      Integer excludeListSize;
      Absyn.Exp exp;
      FCore.Cache cache;
      Prefix.Prefix pre;
      Absyn.Path className;
      list<DAE.Exp> simulationArgs;
      String name;
    case (cache,env,cr2 as Absyn.CREF_IDENT(),_,_,impl,_,_)
      equation
        ErrorExt.setCheckpoint("Scripting");
        cr = Absyn.joinCrefs(Absyn.CREF_QUAL("OpenModelica",{},Absyn.CREF_IDENT("Scripting",{})),cr2);
        (cache,exp_1,prop) = Static.elabExp(cache,env,Absyn.CALL(cr,Absyn.FUNCTIONARGS(inExps,inNamedArgs)),impl,false,inPrefix,info);
        ErrorExt.delCheckpoint("Scripting");
      then (cache,exp_1,prop);

    case (_,_,Absyn.CREF_IDENT(),_,_,_,_,_)
      equation
        ErrorExt.rollBack("Scripting");
      then fail();

    case (cache,env,Absyn.CREF_IDENT(name = "translateModel"),{Absyn.CREF()},args,_,_,_)
      equation
        (cache, simulationArgs) = getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, info, NONE());
      then
        (cache,Expression.makePureBuiltinCall("translateModel",simulationArgs,DAE.T_STRING_DEFAULT),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()));

   case (cache,env,Absyn.CREF_IDENT(name = "modelEquationsUC"),{Absyn.CREF(componentRef = cr)},args,impl,pre,_)
      equation
        (cache,cr_1) = Static.elabUntypedCref(cache,env,cr,impl,pre,info);
        className = ComponentReference.crefToPathIgnoreSubs(cr_1) "this extracts the fileNamePrefix which is used when generating code and init-file" ;
        (cache,outputFile) = Static.getOptionalNamedArg(cache, env, impl, "outputFile", DAE.T_STRING_DEFAULT,args, DAE.SCONST(""),pre,info);
        (cache,dumpExtractionSteps) = Static.getOptionalNamedArg(cache,env,impl,"dumpSteps",DAE.T_BOOL_DEFAULT,args,DAE.BCONST(false),pre,info);
      then
        (cache,Expression.makePureBuiltinCall("modelEquationsUC",{DAE.CODE(Absyn.C_TYPENAME(className),DAE.T_UNKNOWN_DEFAULT),outputFile,dumpExtractionSteps},DAE.T_STRING_DEFAULT),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()));

   case (cache,env,Absyn.CREF_IDENT(name = "translateModelCPP"),{Absyn.CREF(componentRef = cr)},args,impl,pre,_)
      equation
        className = Absyn.crefToPath(cr);
        cname_str = Absyn.pathString(className);
        (cache,filenameprefix) = Static.getOptionalNamedArg(cache,env, impl, "fileNamePrefix",
                                                     DAE.T_STRING_DEFAULT, args, DAE.SCONST(cname_str),pre,info);
        recordtype =
        DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationObject")),
        {DAE.TYPES_VAR("flatClass",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
         DAE.TYPES_VAR("exeFile",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE())},
          NONE());
      then
        (cache,Expression.makePureBuiltinCall("translateModelCPP",
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.T_UNKNOWN_DEFAULT),filenameprefix},DAE.T_STRING_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()));

    case (cache,env,Absyn.CREF_IDENT(name = "translateModelXML"),{Absyn.CREF(componentRef = cr)},args,impl,pre,_)
      equation
        className = Absyn.crefToPath(cr);
        cname_str = Absyn.pathString(className);
        (cache,filenameprefix) = Static.getOptionalNamedArg(cache,env, impl, "fileNamePrefix",
                                                     DAE.T_STRING_DEFAULT, args, DAE.SCONST(cname_str),pre,info);
        recordtype =
          DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationObject")),
          {DAE.TYPES_VAR("flatClass",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
           DAE.TYPES_VAR("exeFile",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE())},
           NONE());
      then
        (cache,Expression.makePureBuiltinCall("translateModelXML",
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.T_UNKNOWN_DEFAULT),filenameprefix},DAE.T_STRING_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()));

    case (cache,env,Absyn.CREF_IDENT(name = "exportDAEtoMatlab"),{Absyn.CREF(componentRef = cr)},args,impl,pre,_)
      equation
        className = Absyn.crefToPath(cr);
        cname_str = Absyn.pathString(className);
        (cache,filenameprefix) = Static.getOptionalNamedArg(cache,env, impl, "fileNamePrefix",
          DAE.T_STRING_DEFAULT, args, DAE.SCONST(cname_str),pre,info);
        recordtype =
          DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationObject")),
          {DAE.TYPES_VAR("flatClass",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
           DAE.TYPES_VAR("exeFile",DAE.dummyAttrVar,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE())},
           NONE());
      then
        (cache,Expression.makePureBuiltinCall("exportDAEtoMatlab",
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.T_UNKNOWN_DEFAULT),filenameprefix},DAE.T_STRING_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()));

    case (cache,env,Absyn.CREF_IDENT(name = "buildModel"),{Absyn.CREF()},args,_,_,_)
      equation
        (cache, simulationArgs) = getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, info, NONE());
      then
        (cache,Expression.makePureBuiltinCall("buildModel",simulationArgs,DAE.T_UNKNOWN_DEFAULT),
         DAE.PROP(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_INTEGER(2)}),DAE.C_VAR()));

    case (cache,env,Absyn.CREF_IDENT(name = "buildModelBeast"),{Absyn.CREF()},args,_,_,_)
      equation
        (cache, simulationArgs) = getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, info, NONE());
      then
        (cache,Expression.makePureBuiltinCall("buildModelBeast",simulationArgs,DAE.T_UNKNOWN_DEFAULT),
         DAE.PROP(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_INTEGER(2)}),DAE.C_VAR()));

    case (cache,env,Absyn.CREF_IDENT(name = "simulate"),{Absyn.CREF()},args,_,_,_) /* Fill in rest of defaults here */
      equation
        (cache, simulationArgs) = getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, info, NONE());
        recordtype = CevalScriptBackend.getSimulationResultType();
      then
        (cache,Expression.makePureBuiltinCall("simulate",simulationArgs,DAE.T_UNKNOWN_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()));

    case (cache,env,Absyn.CREF_IDENT(name = "simulation"),{Absyn.CREF()},args,_,_,_) /* Fill in rest of defaults here */
      equation
        (cache, simulationArgs) = getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, info, NONE());
        recordtype = CevalScriptBackend.getDrModelicaSimulationResultType();
      then
        (cache,Expression.makePureBuiltinCall("simulation",simulationArgs,DAE.T_UNKNOWN_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()));

    case (cache,env,Absyn.CREF_IDENT(name = "linearize"),{Absyn.CREF()},args,_,_,_) /* Fill in rest of defaults here */
      equation
        (cache, simulationArgs) = getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, info, NONE());
        recordtype = CevalScriptBackend.getSimulationResultType();
      then
        (cache,Expression.makePureBuiltinCall("linearize",simulationArgs,DAE.T_UNKNOWN_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()));

    case (cache,env,Absyn.CREF_IDENT(name = "optimize"),{Absyn.CREF()},args,_,_,_) /* Fill in rest of defaults here */
      equation
        (cache, simulationArgs) = getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, info, NONE());
        recordtype = CevalScriptBackend.getSimulationResultType();
      then
        (cache,Expression.makePureBuiltinCall("optimize",simulationArgs,DAE.T_UNKNOWN_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()));


    case (cache,env,Absyn.CREF_IDENT(name = "jacobian"),{Absyn.CREF(componentRef = cr)},_,impl,pre,_) /* Fill in rest of defaults here */
      equation
        (cache,cr_1) = Static.elabUntypedCref(cache,env,cr,impl,pre,info);
        crefExp = Expression.crefExp(cr_1);
      then
        (cache,Expression.makePureBuiltinCall("jacobian",{crefExp},DAE.T_STRING_DEFAULT),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()));

    case (cache,env,Absyn.CREF_IDENT(name = "timing"),{exp},{},impl,pre,_)
      equation
        (cache,exp_1,_) = elabExp(cache,env, exp, impl, true,pre,info);
      then
        (cache,Expression.makePureBuiltinCall("timing",{exp_1},DAE.T_REAL_DEFAULT),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()));

      // MathCore-specific. Should be in MathCoreBuiltin.mo :p
    case (cache,_,Absyn.CREF_IDENT(name = "checkExamplePackages"),{},args,_,_,_)
      equation
        excludeList = Static.getOptionalNamedArgExpList("exclude", args);
        excludeListSize = listLength(excludeList);
      then
        (cache,Expression.makePureBuiltinCall("checkExamplePackages",
        {DAE.ARRAY(DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT,{DAE.DIM_INTEGER(excludeListSize)}),false,excludeList)},
        DAE.T_STRING_DEFAULT),
        DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()));

    case (cache,_,Absyn.CREF_IDENT(name = "checkExamplePackages"),{Absyn.STRING(value = str)},args,_,_,_)
      equation
        excludeList = Static.getOptionalNamedArgExpList("exclude", args);
        excludeListSize = listLength(excludeList);
      then
        (cache,Expression.makePureBuiltinCall("checkExamplePackages",
        {DAE.ARRAY(DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT,{DAE.DIM_INTEGER(excludeListSize)}),false,excludeList),DAE.SCONST(str)},
        DAE.T_STRING_DEFAULT),
        DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()));

    case (cache,_,Absyn.CREF_IDENT(name = "checkExamplePackages"),{Absyn.CREF(componentRef = cr)},args,_,_,_)
      equation
        className = Absyn.crefToPath(cr);
        excludeList = Static.getOptionalNamedArgExpList("exclude", args);
        excludeListSize = listLength(excludeList);
      then
        (cache,Expression.makePureBuiltinCall("checkExamplePackages",
        {DAE.ARRAY(DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT,{DAE.DIM_INTEGER(excludeListSize)}),false,excludeList),
        DAE.CODE(Absyn.C_TYPENAME(className),DAE.T_UNKNOWN_DEFAULT)},
        DAE.T_STRING_DEFAULT),
        DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()));

    case (cache,_,Absyn.CREF_IDENT(name = "checkExamplePackages"),{Absyn.CREF(componentRef = cr), Absyn.STRING(value = str)},args,_,_,_)
      equation
        className = Absyn.crefToPath(cr);
        excludeList = Static.getOptionalNamedArgExpList("exclude", args);
        excludeListSize = listLength(excludeList);
      then
        (cache,Expression.makePureBuiltinCall("checkExamplePackages",
        {DAE.ARRAY(DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT,{DAE.DIM_INTEGER(excludeListSize)}),false,excludeList),
         DAE.CODE(Absyn.C_TYPENAME(className),DAE.T_UNKNOWN_DEFAULT),DAE.SCONST(str)},
        DAE.T_STRING_DEFAULT),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()));

  end matchcontinue;
end elabCallInteractive_work;

public function elabExp "
function: elabExp
   This is an special case tha considers elabCallInteractive. If this function fails elabExp is called."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inImplicit;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := elabExp2(inCache,inEnv,inExp,inImplicit,performVectorization,inPrefix,info,Error.getNumErrorMessages());
end elabExp;


protected function elabExp2 "
function: Auxiliary function to elabExp that considers elabCallInteractive. If this function fails elabExp is called."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inImplicit;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  input Integer numErrorMessages;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inExp,inImplicit,performVectorization,inPrefix,info,numErrorMessages)
    local
      Boolean impl,doVect;
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
  case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),impl,_,pre,_,_)
      equation
        (cache,e_1,prop) = elabCall(cache, env, fn, args, nargs, impl, pre, info, Error.getNumErrorMessages());
        (e_1,_) = ExpressionSimplify.simplify1(e_1);
      then
        (cache,e_1,prop);
    case (cache,env,exp,impl,doVect,pre,_,_)
      equation
        (cache,e_1,prop) = Static.elabExp(cache,env,exp,impl,doVect,pre,info);
      then
         (cache,e_1,prop);
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
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  input Integer numErrorMessages;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inComponentRef,inAbsynExpLst,inAbsynNamedArgLst,inImplInst,inPrefix,info,numErrorMessages)
    local
      DAE.Exp e;
      DAE.Properties prop;
      FCore.Graph env;
      Absyn.ComponentRef fn;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl;
      FCore.Cache cache;
      Prefix.Prefix pre;
  case (cache,env,fn,args,nargs,impl,pre,_,_)
      equation
        (cache,e,prop) = elabCallInteractive_work(cache, env, fn, args, nargs, impl, pre, info) "Elaborate interactive function calls, such as simulate(), plot() etc." ;
      then
        (cache,e,prop);
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
        (cache,e_1,prop) = elabCall(cache,env, fn, args, nargs, true,pre,info,Error.getNumErrorMessages());
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
