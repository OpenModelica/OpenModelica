/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
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

protected type Ident = String;

protected

import Ceval;
import CevalScript;
import CevalScriptBackend;
import Error;
import ErrorExt;
import Expression;
import ExpressionSimplify;
import Flags;
import Static;
import Types;
import Values;
import ValuesUtil;


protected function getSimulationArguments
  "Elaborates the arguments of simulate and the other simulation calls."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inImplInst;
  input DAE.Prefix inPrefix;
  input String callName;
  input SourceInfo inInfo;
  output FCore.Cache outCache = inCache;
  output list<DAE.Exp> outSimulationArguments;
protected
  Absyn.Exp crexp;
  DAE.Exp exp;
  DAE.Type ty;
  Boolean typed;
  Values.Value v;
  Absyn.Path className;
  list<tuple<String, Values.Value>> named = {};
algorithm
  {crexp} := inAbsynExpLst;
  checkSimulationArguments(inAbsynNamedArgLst, callName, inInfo);
  exp := Static.elabCodeExp(crexp, outCache, inEnv, DAE.C_TYPENAME(), inInfo);
  // We need to force eval in order to get the correct prefix
  (outCache, v) := Ceval.ceval(outCache, inEnv, exp, true, Absyn.MSG(inInfo), 0);
  Values.CODE(Absyn.C_TYPENAME(className)) := CevalScript.evalCodeTypeName(v, inEnv);

  for arg in inAbsynNamedArgLst loop
    // An argument of the wrong type is ignored, as by Static.getOptionalNamedArg.
    try
      (outCache, exp, DAE.PROP(type_ = ty)) :=
        Static.elabExpInExpression(outCache, inEnv, arg.argValue, inImplInst, true, inPrefix, inInfo);
      exp := Types.matchType(exp, ty, simulationArgumentType(arg.argName), true);
      typed := true;
    else
      typed := false;
    end try;

    if typed then
      (outCache, v) := Ceval.ceval(outCache, inEnv, exp, true, Absyn.MSG(inInfo), 0);
      named := (arg.argName, v) :: named;
    end if;
  end for;

  outSimulationArguments := list(ValuesUtil.valueExp(a) for a in
    CevalScriptBackend.declaredSimulationArguments(className, listReverse(named), callName));
end getSimulationArguments;

protected function simulationArgumentType
  input String name;
  output DAE.Type ty;
algorithm
  ty := match name
    case "startTime" then DAE.T_REAL_DEFAULT;
    case "stopTime" then DAE.T_REAL_DEFAULT;
    case "stepSize" then DAE.T_REAL_DEFAULT;
    case "tolerance" then DAE.T_REAL_DEFAULT;
    case "numberOfIntervals" then DAE.T_INTEGER_DEFAULT;
    else DAE.T_STRING_DEFAULT;
  end match;
end simulationArgumentType;

constant list<String> VALID_SIMULATE_ARGS = {
  "startTime",
  "stopTime",
  "numberOfIntervals",
  "stepSize",
  "tolerance",
  "method",
  "fileNamePrefix",
  "options",
  "outputFormat",
  "variableFilter",
  "cflags",
  "simflags",
  "resimulateExecutable"
};

function checkSimulationArguments
  input list<Absyn.NamedArg> args;
  input String callName;
  input SourceInfo info;
algorithm
  for arg in args loop
    if not listMember(arg.argName, VALID_SIMULATE_ARGS) then
      Error.addSourceMessage(Error.NO_SUCH_PARAMETER, {callName, arg.argName}, info);
      fail();
    end if;
  end for;
end checkSimulationArguments;

public function elabCallInteractive "This function elaborates the functions defined in the interactive environment.
  Since some of these functions are meta-functions, they can not be described in the type
  system, and is thus given the the type T_UNKNOWN"
  input output FCore.Cache cache;
  input FCore.Graph env;
  input Absyn.ComponentRef fn;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean impl;
  input DAE.Prefix pre;
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
  input DAE.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
   (outCache,outExp,outProperties):=
   matchcontinue
     (inCache, inEnv, inComponentRef, inExps, inNamedArgs, inImplInst, inPrefix)
    local
      FCore.Graph env;
      Absyn.ComponentRef cr,cr2;
      Boolean impl;
      DAE.Exp exp_1;
      DAE.Type recordtype;
      list<Absyn.NamedArg> args;
      DAE.Properties prop;
      Absyn.Exp exp;
      FCore.Cache cache;
      DAE.Prefix pre;
      list<DAE.Exp> simulationArgs;
      String name;
    case (cache, env, cr2 as Absyn.CREF_IDENT(), _, _, impl, _)
      algorithm
        ErrorExt.setCheckpoint("Scripting");
        cr := AbsynUtil.joinCrefs(Absyn.CREF_QUAL("OpenModelica",{},Absyn.CREF_IDENT("Scripting",{})),cr2);
        (cache,exp_1,prop) := Static.elabExp(cache,env,Absyn.CALL(cr,Absyn.FUNCTIONARGS(inExps,inNamedArgs),{}),impl,false,inPrefix,info);
        ErrorExt.delCheckpoint("Scripting");
      then (cache,exp_1,prop);

    case (_, _, Absyn.CREF_IDENT(), _, _, _, _)
      algorithm
        ErrorExt.rollBack("Scripting");
      then fail();

    case (cache, env, Absyn.CREF_IDENT(name = "translateModel"), {Absyn.CREF()}, args, _, _)
      algorithm
        (cache, simulationArgs) := getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, "translateModel", info);
      then
        (cache,Expression.makePureBuiltinCall("translateModel",simulationArgs,DAE.T_STRING_DEFAULT),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()));

    case (cache, env, Absyn.CREF_IDENT(name = "buildModel"), {Absyn.CREF()}, args, _, _)
      algorithm
        (cache, simulationArgs) := getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, "buildModel", info);
      then
        (cache,Expression.makePureBuiltinCall("buildModel",simulationArgs,DAE.T_UNKNOWN_DEFAULT),
         DAE.PROP(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_INTEGER(2)}),DAE.C_VAR()));

    case (cache, env, Absyn.CREF_IDENT(name = "simulate"), {Absyn.CREF()}, args, _, _) /* Fill in rest of defaults here */
      algorithm
        (cache, simulationArgs) := getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, "simulate", info);
        recordtype := CevalScriptBackend.getSimulationResultType();
      then
        (cache,Expression.makePureBuiltinCall("simulate",simulationArgs,DAE.T_UNKNOWN_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()));

    case (cache, env, Absyn.CREF_IDENT(name = "translateAcausalDAE"), {Absyn.CREF()}, args, _, _)
      algorithm
        (cache, simulationArgs) := getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, "translateAcausalDAE", info);
      then
        (cache,Expression.makePureBuiltinCall("translateAcausalDAE",simulationArgs,DAE.T_BOOL_DEFAULT),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()));

    case (cache, env, Absyn.CREF_IDENT(name = "buildAcausalDAE"), {Absyn.CREF()}, args, _, _)
      algorithm
        (cache, simulationArgs) := getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, "buildAcausalDAE", info);
      then
        (cache,Expression.makePureBuiltinCall("buildAcausalDAE",simulationArgs,DAE.T_UNKNOWN_DEFAULT),
         DAE.PROP(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_INTEGER(2)}),DAE.C_VAR()));

    case (cache, env, Absyn.CREF_IDENT(name = "simulateAcausalDAE"), {Absyn.CREF()}, args, _, _)
      algorithm
        (cache, simulationArgs) := getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, "simulateAcausalDAE", info);
        recordtype := CevalScriptBackend.getSimulationResultType();
      then
        (cache,Expression.makePureBuiltinCall("simulateAcausalDAE",simulationArgs,DAE.T_UNKNOWN_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()));

    case (cache, env, Absyn.CREF_IDENT(name = "linearize"), {Absyn.CREF()}, args, _, _) /* Fill in rest of defaults here */
      algorithm
        (cache, simulationArgs) := getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, "linearize", info);
        recordtype := CevalScriptBackend.getSimulationResultType();
      then
        (cache,Expression.makePureBuiltinCall("linearize",simulationArgs,DAE.T_UNKNOWN_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()));

    case (cache, env, Absyn.CREF_IDENT(name = "optimize"), {Absyn.CREF()}, args, _, _) /* Fill in rest of defaults here */
      algorithm
        (cache, simulationArgs) := getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, "optimize", info);
        recordtype := CevalScriptBackend.getSimulationResultType();
      then
        (cache,Expression.makePureBuiltinCall("optimize",simulationArgs,DAE.T_UNKNOWN_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()));

    case (cache, env, Absyn.CREF_IDENT(name = "moo"), {Absyn.CREF()}, args, _, _) /* Fill in rest of defaults here */
      algorithm
        (cache, simulationArgs) := getSimulationArguments(cache, env, inExps, args, inImplInst, inPrefix, "moo", info);
        recordtype := CevalScriptBackend.getSimulationResultType();
      then
        (cache,Expression.makePureBuiltinCall("moo",simulationArgs,DAE.T_UNKNOWN_DEFAULT),DAE.PROP(recordtype,DAE.C_VAR()));

    case (cache, env, Absyn.CREF_IDENT(name = "timing"), {exp}, {}, impl, pre)
      algorithm
        (cache,exp_1,_) := elabExp(cache,env, exp, impl, true,pre,info);
      then
        (cache,Expression.makePureBuiltinCall("timing",{exp_1},DAE.T_REAL_DEFAULT),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()));

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
  input DAE.Prefix inPrefix;
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
  input DAE.Prefix inPrefix;
  input SourceInfo info;
  input Integer numErrorMessages;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache, inEnv, inExp, inImplicit, performVectorization, inPrefix)
    local
      Boolean impl,doVect;
      DAE.Exp e_1;
      DAE.Properties prop;
      FCore.Graph env;
      Absyn.ComponentRef fn;
      Absyn.Exp exp;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      FCore.Cache cache;
      DAE.Prefix pre;
  case (cache, env, Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)), impl, _, pre)
      algorithm
        (cache,e_1,prop) := elabCall(cache, env, fn, args, nargs, impl, pre, info, Error.getNumErrorMessages());
        (e_1,_) := ExpressionSimplify.simplify1(e_1);
      then
        (cache,e_1,prop);
    case (cache, env, exp, impl, doVect, pre)
      algorithm
        (cache,e_1,prop) := Static.elabExp(cache,env,exp,impl,doVect,pre,info);
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
  input DAE.Prefix inPrefix;
  input SourceInfo info;
  input Integer numErrorMessages;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache, inEnv, inComponentRef, inAbsynExpLst, inAbsynNamedArgLst, inImplInst, inPrefix)
    local
      DAE.Exp e;
      DAE.Properties prop;
      FCore.Graph env;
      Absyn.ComponentRef fn;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl;
      FCore.Cache cache;
      DAE.Prefix pre;
  case (cache, env, fn, args, nargs, impl, pre)
      algorithm
        (cache,e,prop) := elabCallInteractive_work(cache, env, fn, args, nargs, impl, pre, info) "Elaborate interactive function calls, such as simulate(), plot() etc." ;
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
  input DAE.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache, inEnv, inExp, inImplInst, inPrefix)
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
      DAE.Prefix pre;
    // Function calls
    case (cache, env, Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)), _, pre)
      algorithm
        (cache,e_1,prop) := elabCall(cache,env, fn, args, nargs, true,pre,info,Error.getNumErrorMessages());
      then
        (cache,e_1,prop);
    case (cache, env, e, impl, pre)
      algorithm
        (cache,e_1,prop) := Static.elabGraphicsExp(cache,env,e,impl,pre,info);
      then
        (cache,e_1,prop);
  end matchcontinue;
end elabGraphicsExp;

annotation(__OpenModelica_Interface="backend_main");
end StaticScript;
