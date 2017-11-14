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
import NFPrefixes.Variability;

protected
import Binding = NFBinding;
import NFComponent.Component;
import NFInstNode.CachedData;
import ComponentRef = NFComponentRef;
import NFFunction.Function;
import Inst = NFInst;
import NFInstNode.InstNodeType;
import Lookup = NFLookup;
import Typing = NFTyping;
import ExpOrigin = NFTyping.ExpOrigin;
import Types;
import List;
import NFClass.Class;
import ErrorExt;
import Util;
import Prefixes = NFPrefixes;

protected
import NFFunction.NamedArg;
import NFFunction.TypedArg;
import NFFunction.TypedNamedArg;
import NFFunction.FunctionMatchKind;

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

public
uniontype Call
  record UNTYPED_CALL
    ComponentRef ref;
    list<Integer> matchingFuncs;
    list<Expression> arguments;
    list<NamedArg> named_args;
  end UNTYPED_CALL;

  record ARG_TYPED_CALL
    ComponentRef ref;
    list<TypedArg> arguments;
    list<TypedNamedArg> named_args;
  end ARG_TYPED_CALL;

  record TYPED_CALL
    Function fn;
    list<Expression> arguments;
    CallAttributes attributes;
  end TYPED_CALL;

  record UNTYPED_MAP_CALL
    ComponentRef ref;
    Expression exp;
    list<InstNode> iters;
  end UNTYPED_MAP_CALL;

  record TYPED_MAP_CALL
    Function fn;
    Type ty;
    Expression exp;
    list<InstNode> iters;
  end TYPED_MAP_CALL;


  function instantiate
    input Absyn.ComponentRef functionName;
    input Absyn.FunctionArgs functionArgs;
    input InstNode scope;
    input SourceInfo info;
    output Expression callExp;
  algorithm

    callExp := match functionArgs
      case Absyn.FUNCTIONARGS() then instNormalCall(functionName, functionArgs, scope, info);
      case Absyn.FOR_ITER_FARG() then instIteratorCall(functionName, functionArgs, scope, info);
      else
        algorithm
          assert(false, getInstanceName() + " got unknown call type");
        then
          fail();
    end match;

    // callExp := Expression.CALL(call);

  end instantiate;

  protected
  function instNormalCall
    input Absyn.ComponentRef functionName;
    input Absyn.FunctionArgs functionArgs;
    input InstNode scope;
    input SourceInfo info;
    output Expression callExp;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Boolean specialBuiltin;
  algorithm
    (fn_ref, _, specialBuiltin) := Function.instFunc(functionName,scope,info);
    (args, named_args) := instArgs(functionArgs, scope, info);

    if specialBuiltin and Absyn.crefFirstIdent(functionName) == "size" then
      callExp := makeSizeCall(args, named_args, info);
    else
      callExp := Expression.CALL(UNTYPED_CALL(fn_ref, {}, args, named_args));
    end if;
  end instNormalCall;

  function instArgs
    input Absyn.FunctionArgs args;
    input InstNode scope;
    input SourceInfo info;
    output list<Expression> posArgs;
    output list<NamedArg> namedArgs;
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
    output NamedArg arg;
  protected
    String name;
    Absyn.Exp exp;
  algorithm
    Absyn.NAMEDARG(argName = name, argValue = exp) := absynArg;
    arg := (name, Inst.instExp(exp, scope, info));
  end instNamedArg;

  function instIteratorCall
    input Absyn.ComponentRef functionName;
    input Absyn.FunctionArgs functionArgs;
    input InstNode scope;
    input SourceInfo info;
    output Expression callExp;
  protected
    InstNode fn_node;
    ComponentRef fn_ref;
    Expression exp;
    list<InstNode> iters;
    ComponentRef arr_fn_ref;
    Call call, arr_call;
    Absyn.ComponentRef aby_fn_ref;
  algorithm
    aby_fn_ref := match functionName
      case Absyn.CREF_IDENT("$array",{}) then Absyn.CREF_IDENT("array",{});
      else functionName;
    end match;

    (fn_ref, fn_node, _) := Function.instFunc(aby_fn_ref,scope,info);
    (exp, iters) := instIteratorCallArgs(functionArgs, scope, info);

    call := match aby_fn_ref

      case Absyn.CREF_IDENT("min",_) algorithm
        (arr_fn_ref, _) := Function.instFunc(Absyn.CREF_IDENT("array", {}),scope,info);
        arr_call := UNTYPED_MAP_CALL(arr_fn_ref, exp, iters);
      then UNTYPED_CALL(fn_ref, {}, {Expression.CALL(arr_call)}, {});

      case Absyn.CREF_IDENT("max",_) algorithm
        (arr_fn_ref, _) := Function.instFunc(Absyn.CREF_IDENT("array", {}),scope,info);
        arr_call := UNTYPED_MAP_CALL(arr_fn_ref, exp, iters);
      then UNTYPED_CALL(fn_ref, {}, {Expression.CALL(arr_call)}, {});

      case Absyn.CREF_IDENT("sum",_) algorithm
        (arr_fn_ref, _) := Function.instFunc(Absyn.CREF_IDENT("array", {}),scope,info);
        arr_call := UNTYPED_MAP_CALL(arr_fn_ref, exp, iters);
      then UNTYPED_CALL(fn_ref, {}, {Expression.CALL(arr_call)}, {});

      case Absyn.CREF_IDENT("product",_) algorithm
        (arr_fn_ref, _) := Function.instFunc(Absyn.CREF_IDENT("array", {}),scope,info);
        arr_call := UNTYPED_MAP_CALL(arr_fn_ref, exp, iters);
      then UNTYPED_CALL(fn_ref, {}, {Expression.CALL(arr_call)}, {});

      else algorithm
        then UNTYPED_MAP_CALL(fn_ref, exp, iters);
    end match;

    callExp := Expression.CALL(call);
  end instIteratorCall;

  function instIteratorCallArgs
    input Absyn.FunctionArgs args;
    input InstNode scope;
    input SourceInfo info;
    output Expression exp;
    output list<InstNode> iters;
  algorithm
    _ := match args
      local
        InstNode for_scope;

      case Absyn.FOR_ITER_FARG()
        algorithm
          (for_scope, iters) := instIterators(args.iterators, scope, info);
          exp := Inst.instExp(args.exp, for_scope, info);
        then
          ();
    end match;
  end instIteratorCallArgs;

  function instIterators
    input list<Absyn.ForIterator> inIters;
    input InstNode scope;
    input SourceInfo info;
    output InstNode iter_scope;
    output list<InstNode> outIters;
  protected
    Binding binding;
    InstNode iter;
  algorithm
    outIters := {};
    iter_scope := scope;
    for Absiter in inIters loop
      binding := Binding.fromAbsyn(Absiter.range, SCode.NOT_EACH(), 0, iter_scope, info);
      binding := Inst.instBinding(binding);
      (iter_scope, iter) := Inst.addIteratorToScope(Absiter.name, binding, info, iter_scope);
      outIters := iter::outIters;
    end for;

    outIters := listReverse(outIters);
  end instIterators;

  public
  function typeCall
    input output Expression callExp;
    input SourceInfo info;
          output Type ty;
          output Variability variability;
  protected
    Call call;
  algorithm

    (call, ty, variability) := match callExp
      case Expression.CALL(UNTYPED_CALL(ref=ComponentRef.CREF(node=InstNode.CLASS_NODE(name="pre"))))
        then typePreCall(callExp.call, info);
      case Expression.CALL(UNTYPED_CALL()) then typeNormalCall(callExp.call, info);
      case Expression.CALL(UNTYPED_MAP_CALL()) then typeMapIteratorCall(callExp.call, info);
    end match;

    callExp := Expression.CALL(call);

  end typeCall;

  function typeMapIteratorCall
    input output Call call;
    input SourceInfo info;
          output Type ty;
          output Variability variability;
  protected
    InstNode fn_node;
    list<Function> fnl;
    Boolean fn_typed, special;
    Function fn;
    Expression arg;
    Type arg_ty;
    Binding binding;
    Variability arg_var;
  algorithm
    (call , ty, variability) := match call
      case UNTYPED_MAP_CALL(ref = ComponentRef.CREF(node = fn_node))
        algorithm
          // Fetch the cached function(s).
          CachedData.FUNCTION(fnl, fn_typed, special) := InstNode.getFuncCache(fn_node);
          assert(listLength(fnl) == 1, getInstanceName() + " overloaded functions in mapping functions not handled yet.");
          fn::_ := fnl;

          // Type the function(s) if not already done.
          if not fn_typed then
            fnl := list(Function.typeFunction(f) for f in fnl);
            InstNode.setFuncCache(fn_node, CachedData.FUNCTION(fnl, true, special));
          end if;


          for iter in call.iters loop
            Typing.typeIterator(iter, info, false);
          end for;
          (arg, arg_ty, arg_var) := Typing.typeExp(call.exp,info);

          ty := arg_ty;
          variability := Variability.CONSTANT;
          for iter in call.iters loop
            binding := Component.getBinding(InstNode.component(iter));
            ty := Type.liftArrayLeftList(ty,Type.arrayDims(Binding.getType(binding)));
            variability := Variability.variabilityMax(variability,Binding.variability(binding));
          end for;

        then
          (TYPED_MAP_CALL(fn, ty, arg, call.iters), ty, variability);
          // (TYPED_CALL(fn, args, ca), ty, variability);

      else
        algorithm
          assert(false, getInstanceName() + " got invalid function call expression");
        then
          fail();
    end match;
  end typeMapIteratorCall;


  function typeNormalCall
    input output Call call;
    input SourceInfo info;
          output Type ty;
          output Variability variability;
  protected
    Call argtycall;
    InstNode fn_node;
    list<Function> fnl;
    Boolean fn_typed, special;
    Function fn;
    list<Expression> args;
    list<Type> arg_ty;
    list<Variability> arg_var;
    CallAttributes ca;
    list<TypedArg> tyArgs;
  algorithm
    (call , ty, variability) := match call
      case UNTYPED_CALL(ref = ComponentRef.CREF(node = fn_node))
        algorithm
          // Fetch the cached function(s).
          CachedData.FUNCTION(fnl, fn_typed, special) := InstNode.getFuncCache(fn_node);

          // Type the function(s) if not already done.
          if not fn_typed then
            fnl := list(Function.typeFunction(f) for f in fnl);
            InstNode.setFuncCache(fn_node, CachedData.FUNCTION(fnl, true, special));
          end if;

          // Type the arguments.
          argtycall := typeArgs(call,info);
          // Match the arguments with the expected ones.
          (fn,tyArgs) := matchFunctions(argtycall,info);

          args := list(Util.tuple31(a) for a in tyArgs);

          variability := Variability.CONSTANT;
          for a in tyArgs loop
            variability := Prefixes.variabilityMax(variability, Util.tuple33(a));
          end for;

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

        then
          (TYPED_CALL(fn, args, ca), ty, variability);

      else
        algorithm
          assert(false, getInstanceName() + " got invalid function call expression");
        then
          fail();
    end match;
  end typeNormalCall;

  function typePreCall
    input output Call call;
    input SourceInfo info;
          output Type ty;
          output Variability variability;
  protected
    Call argtycall;
    InstNode fn_node;
    list<Function> fnl;
    Boolean fn_typed, special;
    Function fn;
    Expression e;
    list<Type> arg_ty;
    list<Variability> arg_var;
    CallAttributes ca;
    list<TypedArg> tyArgs;
    list<TypedNamedArg> nargs;
  algorithm
    (call , ty, variability) := match call
      case UNTYPED_CALL(ref = ComponentRef.CREF(node = fn_node))
        algorithm
          // Fetch the cached function(s).
          CachedData.FUNCTION({fn}, fn_typed, special) := InstNode.getFuncCache(fn_node);

          // Type the function(s) if not already done.
          if not fn_typed then
            fn := Function.typeFunction(fn);
            InstNode.setFuncCache(fn_node, CachedData.FUNCTION({fn}, true, special));
          end if;

          // Type the arguments.
          ARG_TYPED_CALL(arguments=tyArgs, named_args=nargs) := typeArgs(call,info);
          if not listEmpty(nargs) or listLength(tyArgs) <> 1 then
            Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND, {toString(call), "<REMOVE ME>", "pre(<T>) => <T>"}, info);
          end if;

          {(e,ty,variability)} := tyArgs;

          _ := match e
            case Expression.CREF() then ();
            else
              algorithm
                Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND, {toString(call), "<REMOVE ME>", "pre(variable) => <T>"}, info);
              then fail();
          end match;

          // TODO: Allow record components? Arrays?
          if not Type.isBasic(ty) then
            Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND, {toString(call), "<REMOVE ME>", "pre(basicType)"}, info);
            fail();
          end if;

          // TODO: Check if we are in function context?

          ca := CallAttributes.CALL_ATTR(
            ty,
            Type.isTuple(ty),
            Function.isBuiltin(fn),
            Function.isImpure(fn),
            Function.isFunctionPointer(fn),
            Function.inlineBuiltin(fn),
            DAE.NO_TAIL());

        then
          (TYPED_CALL(fn, {e}, ca), ty, variability);

      else
        algorithm
          assert(false, getInstanceName() + " got invalid function call expression");
        then
          fail();
    end match;
  end typePreCall;

  function typeArgs
    input output Call call;
    input SourceInfo info;
  algorithm

    call := match call
      local
        Expression arg;
        Type arg_ty;
        Variability arg_var;
        list<TypedArg> typedArgs;
        list<TypedNamedArg> typedNamedArgs;
        String name;

      case UNTYPED_CALL() algorithm
        typedArgs := {};
        for arg in call.arguments loop
          (arg, arg_ty, arg_var) := Typing.typeExp(arg, info);
          typedArgs := (arg, arg_ty, arg_var)::typedArgs;
        end for;

        typedArgs := listReverse(typedArgs);

        typedNamedArgs := {};
        for narg in call.named_args loop
          (name,arg) := narg;
          (arg, arg_ty, arg_var) := Typing.typeExp(arg, info);
          typedNamedArgs := (name, arg, arg_ty, arg_var)::typedNamedArgs;
        end for;
        listReverse(typedNamedArgs);

      then
        ARG_TYPED_CALL(call.ref, typedArgs, typedNamedArgs);
    end match;
  end typeArgs;

  function matchFunctions
    input Call call;
    input SourceInfo info;
    output Function outFunc;
    output list<TypedArg> args;
  protected
    list<FunctionMatchKind.MatchedFunction> matchedFunctions, exactMatches;
    Boolean typematched, has_cast;
    list<Function> allfuncs, matchingFuncs;
    InstNode fn_node;
    FunctionMatchKind matchKind;
    Absyn.Path ov_name;
  algorithm
    ErrorExt.setCheckpoint("NFCall:matchFunctions");
    matchingFuncs := {};
    matchedFunctions := {};

    _ := match call
      case ARG_TYPED_CALL(ref = ComponentRef.CREF(node = fn_node)) algorithm
        ov_name := ComponentRef.toPath(call.ref);
        allfuncs := Function.getCachedFuncs(fn_node);
        for fn in allfuncs loop

          (args, typematched, matchKind) := matchFunction(fn, call.arguments, call.named_args, info);

          if typematched then
            matchedFunctions := (fn,args,matchKind)::matchedFunctions;
            matchingFuncs := fn::matchingFuncs;
          end if;
        end for;
      then
        ();
    end match;

    if listEmpty(matchedFunctions) then
      // TODO: Remove "in component" from error message.
      Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND,
        {toString(call), "<REMOVE ME>",
         ":\n  " + stringDelimitList(list(Function.signatureString(fn, true, SOME(ov_name)) for fn in allfuncs), "\n  ")},
        info);
      ErrorExt.delCheckpoint("NFCall:matchFunctions");
      fail();
    end if;
    ErrorExt.rollBack("NFCall:matchFunctions");

    if listLength(matchedFunctions) == 1 then
      (outFunc,args,_) ::_ := matchedFunctions;

      // Overwrite the actuall function name with the overload name
      // for builtin functions.
      // We shouldn't do that for non-builtin functions because we need unique names
      // when collected in to the function cache (and then code generation...)
      // builtin functions are not collected so that is okay.
      // It might be a better idea to never overwrite names and print the actual name like
      // OpenModelica.Internal.intAbs() instead of abs()
      if Function.isBuiltin(outFunc) then
        outFunc.path := ov_name;
      end if;
      return;
    end if;

    if listLength(matchedFunctions) > 1 then
      exactMatches := FunctionMatchKind.getExactMatches(matchedFunctions);
      if listLength(exactMatches) == 1 then
        (outFunc,args,_) ::_ := exactMatches;

        // Overwrite the actuall function name with the overload name
        // for builtin functions.
        // We shouldn't do that for non-builtin functions because we need unique names
        // when collected in to the function cache (and then code generation...)
        // builtin functions are not collected so that is okay.
        // It might be a better idea to never overwrite names and print the actual name like
        // OpenModelica.Internal.intAbs() instead of abs()
        if Function.isBuiltin(outFunc) then
          outFunc.path := ov_name;
        end if;
        return;
      else
        // TODO: FIX ME: Add proper error message.
        print("Ambiguous call: " + toString(call) + "\nCandidates:\n  ");
        print(stringDelimitList(list(Function.signatureString(fn, true, SOME(ov_name)) for fn in matchingFuncs), "\n  "));
        print("\n");
        fail();
      end if;
    end if;

  end matchFunctions;

  function typeOf
    input Call call;
    output Type ty;
  algorithm
    ty := match call
      case TYPED_CALL(attributes = CallAttributes.CALL_ATTR(ty = ty)) then ty;
      case TYPED_MAP_CALL() then call.ty;
      else Type.UNKNOWN();
    end match;
  end typeOf;

protected
  function matchFunction
    input Function func;
    input list<TypedArg> args;
    input list<TypedNamedArg> named_args;
    input SourceInfo info;
    output list<TypedArg> out_args;
    output Boolean matched;
    output FunctionMatchKind matchKind;
  protected
    Boolean slotmatched, typematched, has_cast;
  algorithm
    (out_args, slotmatched) := Function.fillArgs(args, named_args, func, info);
    if slotmatched then
      (out_args, matched, matchKind) := Function.matchArgs(func, out_args, info);
    end if;
  end matchFunction;

  public
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
        then DAE.CALL(Function.nameConsiderBuiltin(call.fn),
          list(Expression.toDAE(e) for e in call.arguments),
          CallAttributes.toDAE(call.attributes));

      case TYPED_MAP_CALL()
        then DAE.REDUCTION(
          DAE.REDUCTIONINFO(Function.name(call.fn), Absyn.COMBINE(), Type.toDAE(call.ty), NONE(), "TMP", "TMP", NONE()),
          Expression.toDAE(call.exp),
          list(iteratorToDAE(iter) for iter in call.iters));

      else
        algorithm
          assert(false, getInstanceName() + " got untyped call");
        then
          fail();
    end match;
  end toDAE;

  function iteratorToDAE
    input InstNode iter;
    output DAE.ReductionIterator diter;
  protected
    Component c;
    Binding b;
  algorithm
    c := InstNode.component(iter);
    diter := match c
      case Component.ITERATOR() algorithm
        b := Component.getBinding(c);
      then
        DAE.REDUCTIONITER(InstNode.name(iter), Expression.toDAE(Binding.getTypedExp(b)), NONE(), Type.toDAE(Binding.getType(b)));
    end match;
  end iteratorToDAE;

  function toString
    input Call call;
    output String str;
  protected
    String name, arg_str,c;
    Expression argexp;
  algorithm
    str := match call
      case UNTYPED_CALL()
        algorithm
          name := ComponentRef.toString(call.ref);
          arg_str := stringDelimitList(list(Expression.toString(arg) for arg in call.arguments), ", ");
        then
          name + "(" + arg_str + ")";

      case ARG_TYPED_CALL()
        algorithm
          name := ComponentRef.toString(call.ref);
          arg_str := stringDelimitList(list(Expression.toString(Util.tuple31(arg)) for arg in call.arguments), ", ");
          for arg in call.named_args loop
            c := if arg_str == "" then "" else ", ";
            arg_str := arg_str + c + Util.tuple41(arg) + " = " + Expression.toString(Util.tuple42(arg));
          end for;
        then
          name + "(" + arg_str + ")";

      case UNTYPED_MAP_CALL()
        algorithm
          name := ComponentRef.toString(call.ref);
          arg_str := Expression.toString(call.exp);
        then
          name + "(" + arg_str + ")";

      case TYPED_CALL()
        algorithm
          name := Absyn.pathString(Function.name(call.fn));
          arg_str := stringDelimitList(list(Expression.toString(arg) for arg in call.arguments), ", ");
        then
          name + "(" + arg_str + ")";

      case TYPED_MAP_CALL()
        algorithm
          name := Absyn.pathString(Function.name(call.fn));
          arg_str := Expression.toString(call.exp);
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
      case TYPED_MAP_CALL() then call.fn;
      else
        algorithm
          assert(false, getInstanceName() + " got untyped function");
        then
          fail();
    end match;
  end typedFunction;

  function makeSizeCall
    input list<Expression> posArgs;
    input list<NamedArg> namedArgs;
    input SourceInfo info;
    output Expression callExp;
  protected
    Integer argc = listLength(posArgs);
    Expression arg1, arg2;
  algorithm
    if not listEmpty(namedArgs) then
      for arg in namedArgs loop
        Error.addSourceMessage(Error.NO_SUCH_PARAMETER,
          {"size", Util.tuple21(arg)}, info);
      end for;
      fail();
    end if;

    callExp := match posArgs
      case {arg1} then Expression.SIZE(arg1, NONE());
      case {arg1, arg2} then Expression.SIZE(arg1, SOME(arg2));
      else
        algorithm
          Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND,
            {"size", "", ":\n  size(array) => Integer[:]\n  size(array, Integer) => Integer"}, info);
        then
          fail();
    end match;
  end makeSizeCall;

  function makeBuiltinCall
    "Creates a call to a builtin function, given a Function and a list of
     argument expressions."
    input Function func;
    input list<Expression> args;
    output Call call;
  algorithm
    call := TYPED_CALL(func, args,
      CallAttributes.CALL_ATTR(func.returnType, false, true, false, false,
        DAE.NO_INLINE(), DAE.NO_TAIL()));
  end makeBuiltinCall;

end Call;

annotation(__OpenModelica_Interface="frontend");
end NFCall;
