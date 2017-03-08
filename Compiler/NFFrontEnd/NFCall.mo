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
import DAE;
import NFInstNode.InstNode;
import Expression = NFExpression;
import Type = NFType;

protected
import NFInstNode.CachedData;
import ComponentRef = NFComponentRef;
import NFFunction.Function;
import Inst = NFInst;
import NFInstNode.InstNodeType;
import Lookup = NFLookup;
import Typing = NFTyping;
import Types;
import List;
import NFClass.Class;

public
uniontype CallAttributes
  record CALL_ATTR
    Type ty "The type of the return value, if several return values this is undefined";
    Boolean tuple_ "tuple" ;
    Boolean builtin "builtin Function call" ;
    Boolean isImpure "if the function has prefix *impure* is true, else false";
    Boolean isFunctionPointerCall;
    DAE.InlineType inlineType;
    DAE.TailCall tailCall "Input variables of the function if the call is tail-recursive";
  end CALL_ATTR;

  function toDAE
    input CallAttributes attr;
    output DAE.CallAttributes fattr;
  algorithm
    fattr := DAE.CALL_ATTR(Type.toDAE(attr.ty), attr.tuple_, attr.builtin,
      attr.isImpure, attr.isFunctionPointerCall, attr.inlineType, attr.tailCall);
  end toDAE;
end CallAttributes;

public constant CallAttributes callAttrBuiltinBool = CALL_ATTR(Type.BOOLEAN(),false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
public constant CallAttributes callAttrBuiltinInteger = CALL_ATTR(Type.INTEGER(),false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
public constant CallAttributes callAttrBuiltinReal = CALL_ATTR(Type.REAL(),false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
public constant CallAttributes callAttrBuiltinString = CALL_ATTR(Type.STRING(),false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
public constant CallAttributes callAttrBuiltinOther = CALL_ATTR(Type.UNKNOWN(),false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
public constant CallAttributes callAttrBuiltinImpureBool = CALL_ATTR(Type.BOOLEAN(),false,true,true,false,DAE.NO_INLINE(),DAE.NO_TAIL());
public constant CallAttributes callAttrBuiltinImpureInteger = CALL_ATTR(Type.INTEGER(),false,true,true,false,DAE.NO_INLINE(),DAE.NO_TAIL());
public constant CallAttributes callAttrBuiltinImpureReal = CALL_ATTR(Type.REAL(),false,true,true,false,DAE.NO_INLINE(),DAE.NO_TAIL());

uniontype Call
  record UNTYPED_CALL
    ComponentRef ref;
    list<Integer> matchingFuncs;
    list<Expression> arguments;
  end UNTYPED_CALL;

  record TYPED_CALL
    Function fn;
    list<Expression> arguments;
    CallAttributes attributes;
  end TYPED_CALL;

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
          // Function components shouldn't be prefixed, so mark the node as root class.
          fn_node := InstNode.setNodeType(InstNodeType.ROOT_CLASS(), fn_node);
          fn_node := Inst.instantiate(fn_node);
          Inst.instExpressions(fn_node);
          fnl := makeFunctions(fn_path, fn_node);
          fn_node := InstNode.setCachedData(CachedData.FUNCTION(fnl, false), fn_node);
        then
          fnl;
    end match;

    callExp := makeCall(fn_ref, fnl, functionArgs, scope, info);
  end instantiate;

  function makeFunctions
    input Absyn.Path path;
    input InstNode node;
    output list<Function> funcs;
  protected
    Class cls = InstNode.getClass(node);
  algorithm
    funcs := match cls
      case Class.OVERLOADED_CLASS()
        algorithm
          funcs := list(Function.new(path, o) for o in cls.overloads);
        then
          funcs;

      else {Function.new(path, node)};
    end match;
  end makeFunctions;

  function typeCall
    input output Expression callExp;
    input InstNode scope;
    input SourceInfo info;
          output Type ty;
          output DAE.Const variability;
  protected
    Call call;
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
      case Expression.CALL(call = call as UNTYPED_CALL(ref = ComponentRef.CREF(node = fn_node)))
        algorithm
          // Fetch the cached function(s).
          CachedData.FUNCTION(fnl, fn_typed) := InstNode.cachedData(fn_node);

          // Type the function(s) if not already done.
          if not fn_typed then
            fnl := list(Function.typeFunction(f) for f in fnl);
            InstNode.setCachedData(CachedData.FUNCTION(fnl, true), fn_node);
          end if;

          // The instantiation should make sure this never happens.
          assert(not listEmpty(fnl), getInstanceName() + " couldn't find a cached function");

          // Type the arguments.
          (args, arg_ty, arg_var) := Typing.typeExpl(call.arguments, scope, info);

          // TODO: Figure out why this segfaults.
          //variability := Types.constAnd(v for v in arg_var);
          variability := List.fold(arg_var, Types.constAnd, DAE.C_CONST());

          // Type check the arguments.
          (args, fn) := typeCheckCall(fnl, call.matchingFuncs, args, arg_ty, arg_var, info);

          // Construct the call expression.
          ty := Function.returnType(fn);
          ca := CallAttributes.CALL_ATTR(
            ty,
            Type.isTuple(ty),
            Function.isBuiltin(fn),
            Function.isImpure(fn),
            Function.isFunctionPointer(fn),
            Function.inlineBuiltin(fn),
            DAE.NO_TAIL());

          callExp := Expression.CALL(TYPED_CALL(fn, args, ca));
        then
          (callExp, ty, variability);

      else
        algorithm
          assert(false, getInstanceName() + " got invalid function call expression");
        then
          fail();
    end match;
  end typeCall;

  function arguments
    input Call call;
    output list<Expression> arguments;
  algorithm
    arguments := match call
      case UNTYPED_CALL() then call.arguments;
      case TYPED_CALL() then call.arguments;
    end match;
  end arguments;

  function compare
    input Call call1;
    input Call call2;
    output Integer comp;
  algorithm
    comp := match (call1, call2)
      case (UNTYPED_CALL(), UNTYPED_CALL())
        then ComponentRef.compare(call1.ref, call2.ref);

      case (TYPED_CALL(), TYPED_CALL())
        then Absyn.pathCompare(Function.name(call1.fn), Function.name(call2.fn));

      case (UNTYPED_CALL(), TYPED_CALL())
        then Absyn.pathCompare(ComponentRef.toPath(call1.ref), Function.name(call2.fn));

      case (TYPED_CALL(), UNTYPED_CALL())
        then Absyn.pathCompare(Function.name(call1.fn), ComponentRef.toPath(call2.ref));
    end match;

    if comp == 0 then
      comp := Expression.compareList(arguments(call1), arguments(call2));
    end if;
  end compare;

  function toDAE
    input Call call;
    output DAE.Exp daeCall;
  algorithm
    daeCall := match call
      case TYPED_CALL()
        then DAE.CALL(Function.name(call.fn),
          list(Expression.toDAE(e) for e in call.arguments),
          CallAttributes.toDAE(call.attributes));

      else
        algorithm
          assert(false, getInstanceName() + " got untyped call");
        then
          fail();
    end match;
  end toDAE;

  function toString
    input Call call;
    output String str;
  protected
    String name, arg_str;
  algorithm
    str := match call
      case UNTYPED_CALL()
        algorithm
          name := ComponentRef.toString(call.ref);
          arg_str := stringDelimitList(list(Expression.toString(arg) for arg in call.arguments), ", ");
        then
          name + "(" + arg_str + ")";

      case TYPED_CALL()
        algorithm
          name := Absyn.pathString(Function.name(call.fn));
          arg_str := stringDelimitList(list(Expression.toString(arg) for arg in call.arguments), ", ");
        then
          name + "(" + arg_str + ")";
    end match;
  end toString;

  function typedFunction
    input Call call;
    output Function fn;
  algorithm
    fn := match call
      case TYPED_CALL() then call.fn;
      else
        algorithm
          assert(false, getInstanceName() + " got untyped function");
        then
          fail();
    end match;
  end typedFunction;

  //function makeBuiltinCall
  //  "Create a CALL with the given data for a call to a builtin function."
  //  input String name;
  //  input Expression cref "pointer to class and prefix";
  //  input list<Expression> args;
  //  input Type result_type;
  //  input Boolean isImpure;
  //  output Expression call;
  //  annotation(__OpenModelica_EarlyInline = true);
  //algorithm
  //  call := Expression.CALL(Absyn.IDENT(name), cref, args,
  //    CallAttributes.CALL_ATTR(result_type, false, true, isImpure, false, DAE.NO_INLINE(), DAE.NO_TAIL()));
  //end makeBuiltinCall;

  //function makePureBuiltinCall
  //  "Create a CALL with the given data for a call to a builtin function."
  //  input String name;
  //  input Expression cref "pointer to class and prefix";
  //  input list<Expression> args;
  //  input Type result_type;
  //  output Expression call;
  //  annotation(__OpenModelica_EarlyInline = true);
  //algorithm
  //  call := makeBuiltinCall(name, cref, args, result_type, false);
  //end makePureBuiltinCall;
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
  protected
    list<Expression> args;
    list<tuple<String, Expression>> named_args;
    list<Integer> matching_funcs;
  algorithm
    (args, named_args) := instArgs(callArgs, scope, info);
    (args, matching_funcs) := matchArgs(args, named_args, funcs, info);
    call := Expression.CALL(UNTYPED_CALL(fnRef, matching_funcs, args));
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
    output list<Integer> matchingFuncs = {};
  protected
    Function fn;
    Boolean matching;
    list<Expression> argl;
    Integer i;

    String fn_name, fn_defs, args_str;
  algorithm
    if listLength(funcs) == 1 then
      (args, true) := Function.matchArgs(posArgs, namedArgs, listHead(funcs), SOME(info));
    else
      i := 1;

      for fn in funcs loop
        (argl, matching) := Function.matchArgs(posArgs, namedArgs, fn, NONE());

        if matching then
          args := argl;
          matchingFuncs := i :: matchingFuncs;
        end if;

        i := i + 1;
      end for;

      // No matching function, print an error message.
      if listEmpty(matchingFuncs) then
        // TODO: Remove "in component" from error message.
        Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND,
          {Function.callString(listHead(funcs), posArgs, namedArgs), "<REMOVE ME>",
           ":\n  " + stringDelimitList(list(Function.signatureString(fn, false) for fn in funcs), "\n  ")},
          info);

        fail();
      end if;

      matchingFuncs := listReverse(matchingFuncs);
    end if;
  end matchArgs;

  function typeCheckCall
    input list<Function> funcs;
    input list<Integer> matchingFuncs;
    input output list<Expression> args;
    input list<Type> types;
    input list<DAE.Const> variabilities;
    input SourceInfo info;
    output Function fn;
  protected
    list<Integer> matching_funcs;
    Integer i = 1, idx;
    Boolean correct;
  algorithm
    if listLength(funcs) == 1 then
      fn := listHead(funcs);
      (args, true) := Function.typeCheckArgs(fn, args, types, variabilities, SOME(info));
    else
      idx :: matching_funcs := matchingFuncs;

      for func in funcs loop
        if idx == i then
          (args, correct) := Function.typeCheckArgs(func, args, types, variabilities, NONE());

          if correct then
            fn := func;
            return;
          elseif listEmpty(matching_funcs) then
            break;
          else
            idx :: matching_funcs := matching_funcs;
          end if;
        end if;

        i := i + 1;
      end for;

      // TODO: Remove "in component" from error message.
      Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND,
        {Function.callString(listHead(funcs), args, {}), "<REMOVE ME>",
         ":\n  " + stringDelimitList(list(Function.signatureString(fn) for fn in funcs), "\n  ")},
        info);
      fail();
    end if;
  end typeCheckCall;

end Call;

annotation(__OpenModelica_Interface="frontend");
end NFCall;
