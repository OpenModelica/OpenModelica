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

encapsulated package NFCall

import Absyn;
import NFInstNode.InstNode;
import NFExpression.Expression;
import Type = NFType;

protected
import NFInstNode.CachedData;
import NFExpression.CallAttributes;
import ComponentRef = NFComponentRef;
import NFFunction.Function;
import Inst = NFInst;
import Lookup = NFLookup;
import Typing = NFTyping;
import Types;

public
function instantiate
  input Absyn.ComponentRef functionName;
  input Absyn.FunctionArgs functionArgs;
  input InstNode scope;
  input SourceInfo info;
        output Expression callExp;
protected
  InstNode fn_node;
  Function fn;
  list<Function> fnl;
  CachedData cache;
  ComponentRef fn_ref;
  Absyn.Path fn_path;
algorithm
  // Look up the the function.
  (fn_node, fn_ref, fn_path) := lookupFunction(functionName, scope, info);
  cache := InstNode.cachedData(fn_node);

  // Check if a cached instantiation of this function already exists.
  fnl := match cache
    case CachedData.FUNCTION() then cache.funcs;

    else // Not yet instantiated, instantiate it and cache it in the node.
      algorithm
        fn_node := Inst.instantiate(fn_node);
        Inst.instExpressions(fn_node);
        fn := Function.new(fn_path, fn_node);
        fn_node := InstNode.cacheAddFunc(fn, fn_node);
      then
        {fn};
  end match;

  callExp := makeCall(fn_ref, fnl, functionArgs, scope, info);
end instantiate;

function typeCall
  input output Expression callExp;
  input InstNode scope;
  input SourceInfo info;
        output Type ty;
        output DAE.Const variability;
protected
  InstNode fn_node;
  list<Function> fnl;
  Boolean fn_typed;
  Function fn;
  list<Expression> args;
  list<Type> arg_ty;
  list<DAE.Const> arg_var;
  CallAttributes ca;
algorithm
  (callExp, ty, variability) := match callExp
    case Expression.CALL(ref = ComponentRef.CREF(node = fn_node))
      algorithm
        // Fetch the cached function(s).
        CachedData.FUNCTION(fnl, fn_typed) := InstNode.cachedData(fn_node);

        // Type the function(s) if not already done.
        if not fn_typed then
          fnl := list(Function.typeFunction(f) for f in fnl);
          InstNode.setCachedData(CachedData.FUNCTION(fnl, true), fn_node);
        end if;

        assert(not listEmpty(fnl), getInstanceName() + " couldn't find a cached function");

        fn := match fnl
          case {fn} then fn; // The normal case of only one matching function.
          else // TODO: Handle overloaded functions.
            algorithm
              assert(false, getInstanceName() + ": IMPLEMENT ME");
            then
              fail();
        end match;


        // Type the arguments.
        (args, arg_ty, arg_var) := Typing.typeExpl(callExp.arguments, scope, info);
        variability := Types.constAnd(v for v in arg_var);

        ty := fn.returnType;
        ca := CallAttributes.CALL_ATTR(
          ty,
          Type.isTuple(fn.returnType),
          Function.isBuiltin(fn),
          Function.isImpure(fn),
          Function.isFunctionPointer(fn),
          Function.inlineBuiltin(fn),
          DAE.NO_TAIL());

        // TODO: Type check arguments against the inputs, and check variability.

        callExp := Expression.CALL(callExp.ref, args, SOME(ca));
      then
        (callExp, ty, variability);

    else
      algorithm
        assert(false, getInstanceName() + " got invalid function call expression");
      then
        fail();
  end match;
end typeCall;

protected
function lookupFunction
  input Absyn.ComponentRef functionName;
  input InstNode scope;
  input SourceInfo info;
  output InstNode node;
  output ComponentRef functionRef;
  output Absyn.Path functionPath;
protected
  list<InstNode> nodes;
  InstNode found_scope;
algorithm
  try
    // Make sure the name is a path.
    functionPath := Absyn.crefToPath(functionName);
  else
    Error.addSourceMessageAndFail(Error.SUBSCRIPTED_FUNCTION_CALL,
      {Dump.printComponentRefStr(functionName)}, info);
  end try;

  // Look up the function and create a cref for it.
  (node, nodes, found_scope) := Lookup.lookupFunctionName(functionName, scope, info);

  for s in InstNode.scopeList(found_scope) loop
    functionPath := Absyn.QUALIFIED(InstNode.name(s), functionPath);
  end for;

  functionRef := ComponentRef.fromNodeList(InstNode.scopeList(found_scope));
  functionRef := Inst.makeCref(functionName, nodes, scope, info, functionRef);
end lookupFunction;

function makeCall
  input ComponentRef fnRef;
  input list<Function> funcs;
  input Absyn.FunctionArgs callArgs;
  input InstNode scope;
  input SourceInfo info;
  output Expression call;
  output list<Function> matchingFuncs;
protected
  list<Expression> args;
  list<tuple<String, Expression>> named_args;
algorithm
  (args, named_args) := instArgs(callArgs, scope, info);
  (args, matchingFuncs) := matchArgs(args, named_args, funcs, info);
  call := Expression.CALL(fnRef, args, NONE());
end makeCall;

function instArgs
  input Absyn.FunctionArgs args;
  input InstNode scope;
  input SourceInfo info;
  output list<Expression> posArgs;
  output list<tuple<String, Expression>> namedArgs;
algorithm
  (posArgs, namedArgs) := match args
    case Absyn.FUNCTIONARGS()
      algorithm
        posArgs := list(Inst.instExp(a, scope, info) for a in args.args);
        namedArgs := list(instNamedArg(a, scope, info) for a in args.argNames);
      then
        (posArgs, namedArgs);

    else
      algorithm
        assert(false, getInstanceName() + " got unknown function args");
      then
        fail();
  end match;
end instArgs;

function instNamedArg
  input Absyn.NamedArg absynArg;
  input InstNode scope;
  input SourceInfo info;
  output tuple<String, Expression> arg;
protected
  String name;
  Absyn.Exp exp;
algorithm
  Absyn.NAMEDARG(argName = name, argValue = exp) := absynArg;
  arg := (name, Inst.instExp(exp, scope, info));
end instNamedArg;

function matchArgs
  input list<Expression> posArgs;
  input list<tuple<String, Expression>> namedArgs;
  input list<Function> funcs;
  input SourceInfo info;
  output list<Expression> args;
  output list<Function> matchingFuncs;
protected
  Function fn;
algorithm
  if listLength(funcs) == 1 then
    (args, true) := Function.matchArgs(posArgs, namedArgs, listHead(funcs), SOME(info));
    matchingFuncs := funcs;
  else
    // TODO: Implement case for overloaded functions.
    assert(false, getInstanceName() + ": IMPLEMENT ME");
  end if;
end matchArgs;

annotation(__OpenModelica_Interface="frontend");
end NFCall;
