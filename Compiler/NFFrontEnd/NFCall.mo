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
import Dimension = NFDimension;
import NFFunction.Function;
import Inst = NFInst;
import NFInstNode.InstNodeType;
import Lookup = NFLookup;
import Typing = NFTyping;
import TypeCheck = NFTypeCheck;
import Types;
import List;
import NFClass.Class;
import ErrorExt;
import Util;
import Prefixes = NFPrefixes;
import MetaModelica.Dangerous.listReverseInPlace;
import NFTyping.ExpOrigin;
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
    Type ty;
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
          Error.assertion(false, getInstanceName() + " got unknown call type", sourceInfo());
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

    if specialBuiltin then
      callExp := match Absyn.crefFirstIdent(functionName)
        // size creates Expression.SIZE instead of Expression.CALL.
        case "size" then typeSizeCall(args, named_args, info);
        // array creates Expression.ARRAY instead of Expression.CALL.
        case "array" then typeArrayCall(args, named_args, info);
        else Expression.CALL(UNTYPED_CALL(fn_ref, {}, args, named_args));
      end match;
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
          Error.assertion(false, getInstanceName() + " got unknown function args", sourceInfo());
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
    ComponentRef fn_ref;
    Expression exp;
    list<InstNode> iters;
    Call call;
    Boolean is_builtin, is_array;
  algorithm
    (is_builtin, is_array) := match Absyn.crefFirstIdent(functionName)
      case "$array" then (true, true);
      case "min" then (true, false);
      case "max" then (true, false);
      case "sum" then (true, false);
      case "product" then (true, false);
      else (false, false);
    end match;

    (exp, iters) := instIteratorCallArgs(functionArgs, scope, info);

    if is_builtin then
      // If the call is one of the builtin ones, start by making an array map call.
      fn_ref := Function.instFunc(Absyn.CREF_IDENT("array", {}), scope, info);
      call := UNTYPED_MAP_CALL(fn_ref, exp, iters);

      // If the call is not array itself, wrap the array call in the given
      // function (e.g. sum(array(i for i in ...))).
      if not is_array then
        fn_ref := Function.instFunc(functionName, scope, info);
        call := UNTYPED_CALL(fn_ref, {}, {Expression.CALL(call)}, {});
      end if;
    else
      // Otherwise, make a map call from the given function.
      fn_ref := Function.instFunc(functionName, scope, info);
      call := UNTYPED_MAP_CALL(fn_ref, exp, iters);
    end if;

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
      binding := Binding.fromAbsyn(Absiter.range, false, 0, iter_scope, info);
      binding := Inst.instBinding(binding);
      (iter_scope, iter) := Inst.addIteratorToScope(Absiter.name, binding, info, iter_scope);
      outIters := iter::outIters;
    end for;

    outIters := listReverse(outIters);
  end instIterators;


  function builtinSpecialHandling
    input Call call;
    output Boolean special;
  algorithm
    () := match call
      local
        InstNode fn_node;

      case UNTYPED_CALL(ComponentRef.CREF(node = fn_node)) algorithm
        CachedData.FUNCTION(_, _, special) := InstNode.getFuncCache(fn_node);
      then ();
      case UNTYPED_MAP_CALL(ComponentRef.CREF(node = fn_node)) algorithm
        CachedData.FUNCTION(_, _, special) := InstNode.getFuncCache(fn_node);
      then ();
    end match;
  end builtinSpecialHandling;

  function typeSpecialBuiltinFunction
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    ComponentRef cref;
    InstNode fn_node;
    Expression first;
    list<Expression> rest;
    String name;
  algorithm
    UNTYPED_CALL(ref = cref) := call;

    (callExp, ty, variability) := match ComponentRef.firstName(cref)
      case "cardinality" then typeCardinalityCall(call, origin, info);
      case "change" then typeChangeCall(call, origin, info);
      case "edge" then typeEdgeCall(call, origin, info);
      case "fill" then typeFillCall(call, origin, info);
      case "initial" then typeDiscreteCall(call, origin, info);
      case "matrix" then typeMatrixCall(call, origin, info);
      case "max" then typeMinMaxCall(call, origin, info);
      case "min" then typeMinMaxCall(call, origin, info);
      case "ndims" then typeNdimsCall(call, origin, info);
      case "noEvent" then typeNoEventCall(call, origin, info);
      case "ones" then typeZerosOnesCall(call, origin, info);
      case "pre" then typePreCall(call, origin, info);
      case "product" then typeSumProductCall(call, origin, info);
      case "scalar" then typeScalarCall(call, origin, info);
      case "smooth" then typeSmoothCall(call, origin, info);
      case "sum" then typeSumProductCall(call, origin, info);
      case "symmetric" then typeSymmetricCall(call, origin, info);
      case "terminal" then typeDiscreteCall(call, origin, info);
      case "transpose" then typeTransposeCall(call, origin, info);
      case "vector" then typeVectorCall(call, origin, info);
      case "zeros" then typeZerosOnesCall(call, origin, info);
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unhandled builtin function", sourceInfo());
        then
          fail();
    end match;
  end typeSpecialBuiltinFunction;

  public
  function typeCall
    input output Expression callExp;
    input Integer origin;
    input SourceInfo info;
          output Type ty;
          output Variability variability;
  protected
    Call call;
  algorithm
    () := match callExp
      case Expression.CALL(UNTYPED_CALL())
        algorithm
          if(builtinSpecialHandling(callExp.call)) then
            (callExp, ty, variability) := typeSpecialBuiltinFunction(callExp.call, origin, info);
          else
            (call, ty, variability) := typeMatchNormalCall(callExp.call, origin, info);
            callExp := Expression.CALL(call);
          end if;
        then
          ();

      case Expression.CALL(UNTYPED_MAP_CALL())
        algorithm
          (call, ty, variability) := typeMapIteratorCall(callExp.call, origin, info);
          callExp := Expression.CALL(call);
        then
          ();
    end match;
  end typeCall;

  function typeMapIteratorCall
    input output Call call;
    input Integer origin;
    input SourceInfo info;
          output Type ty;
          output Variability variability;
  protected
    InstNode fn_node;
    list<Function> fnl;
    Function fn;
    Expression arg;
    Type arg_ty;
    Binding binding;
    Variability arg_var;
  algorithm
    (call, ty, variability) := match call
      case UNTYPED_MAP_CALL(ref = ComponentRef.CREF(node = fn_node))  algorithm
        // Fetch the cached function(s).
        fnl := typeCachedFunctions(call.ref);
        Error.assertion(listLength(fnl) == 1, getInstanceName() + " overloaded functions in mapping functions not handled yet.", sourceInfo());
        fn := listHead(fnl);

        for iter in call.iters loop
          Typing.typeIterator(iter, info, ExpOrigin.FUNCTION, structural = false);
        end for;
        (arg, arg_ty, arg_var) := Typing.typeExp(call.exp, origin, info);

        ty := arg_ty;
        variability := Variability.CONSTANT;
        for iter in call.iters loop
          binding := Component.getBinding(InstNode.component(iter));
          ty := Type.liftArrayLeftList(ty,Type.arrayDims(Binding.getType(binding)));
          variability := Variability.variabilityMax(variability,Binding.variability(binding));
        end for;
      then
        (TYPED_MAP_CALL(fn, ty, arg, call.iters), ty, variability);

      else algorithm
        Error.assertion(false, getInstanceName() + " got invalid function call expression", sourceInfo());
      then
        fail();
    end match;
  end typeMapIteratorCall;

  function typeMatchNormalCall
    input output Call call;
    input Integer origin;
    input SourceInfo info;
          output Type ty;
          output Variability variability;
  protected
    Call argtycall;
  algorithm
    argtycall := typeNormalCall(call, origin, info);
    (call, ty, variability) := matchTypedNormalCall(argtycall, info);
  end typeMatchNormalCall;

  function typeNormalCall
    input output Call call;
    input Integer origin;
    input SourceInfo info;
  algorithm
    call := match call
      case UNTYPED_CALL() algorithm
        typeCachedFunctions(call.ref);
      then
        typeArgs(call, origin, info);

      else algorithm
        Error.assertion(false, getInstanceName() + " got invalid function call expression", sourceInfo());
      then
        fail();
    end match;
  end typeNormalCall;

  function typeCachedFunctions
    "Returns the function(s) referenced by the given cref, and types them if
     they are not already typed."
    input ComponentRef functionRef;
    output list<Function> functions;
  protected
    InstNode fn_node;
    Boolean typed, special;
  algorithm
    functions := match functionRef
      case ComponentRef.CREF(node = fn_node)
        algorithm
          CachedData.FUNCTION(functions, typed, special) := InstNode.getFuncCache(fn_node);

          // Type the function(s) if not already done.
          if not typed then
            functions := list(Function.typeFunction(f) for f in functions);
            InstNode.setFuncCache(fn_node, CachedData.FUNCTION(functions, true, special));
            functions := list(Function.typeFunctionBody(f) for f in functions);
            InstNode.setFuncCache(fn_node, CachedData.FUNCTION(functions, true, special));
          end if;
        then
          functions;

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got invalid function call reference", sourceInfo());
        then
          fail();
    end match;
  end typeCachedFunctions;

  function matchTypedNormalCall
    input output Call argtycall;
    input SourceInfo info;
          output Type ty;
          output Variability variability;
  protected
    Function fn;
    list<Expression> args;
    list<Type> arg_ty;
    list<Variability> arg_var;
    CallAttributes ca;
    list<TypedArg> tyArgs;
  algorithm
    (argtycall , ty, variability) := match argtycall
      case ARG_TYPED_CALL() algorithm

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
                                      ty, Type.isTuple(ty), Function.isBuiltin(fn)
                                      , Function.isImpure(fn), Function.isFunctionPointer(fn)
                                      , Function.inlineBuiltin(fn), DAE.NO_TAIL()
                                      );
      then
        (TYPED_CALL(fn, ty, args, ca), ty, variability);

      else algorithm
        Error.assertion(false, getInstanceName() + " got invalid function call expression", sourceInfo());
      then
        fail();
    end match;
  end matchTypedNormalCall;

  function typeArgs
    input output Call call;
    input Integer origin;
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

      case UNTYPED_CALL()
        algorithm
          typedArgs := {};
          for arg in call.arguments loop
            (arg, arg_ty, arg_var) := Typing.typeExp(arg, origin, info);
            typedArgs := (arg, arg_ty, arg_var) :: typedArgs;
          end for;

          typedArgs := listReverse(typedArgs);

          typedNamedArgs := {};
          for narg in call.named_args loop
            (name,arg) := narg;
            (arg, arg_ty, arg_var) := Typing.typeExp(arg, origin, info);
            typedNamedArgs := (name, arg, arg_ty, arg_var) :: typedNamedArgs;
          end for;

          typedNamedArgs := listReverse(typedNamedArgs);
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
    Integer numerr = Error.getNumErrorMessages();
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

    // Don't show error messages for overloaded functions, it leaks
    // implementation details and usually doesn't provide any more info than
    // what the "no match found" error gives anyway.
    if listLength(allfuncs) > 1 then
      ErrorExt.rollBack("NFCall:matchFunctions");
    else
      ErrorExt.delCheckpoint("NFCall:matchFunctions");
    end if;

    if listEmpty(matchedFunctions) then
      // Only show the error message for no matching functions if no other error
      // was shown, i.e. only for overloaded functions or non-overloaded
      // functions that for some reason failed to match without giving any error.
      if numerr == Error.getNumErrorMessages() then
        Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
          {typedString(call), candidateFuncListString(allfuncs,SOME(ov_name))}, info);
      end if;
      fail();
    end if;

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
        print(candidateFuncListString(matchingFuncs,SOME(ov_name)));
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
      case TYPED_CALL() then call.ty;
      case TYPED_MAP_CALL() then call.ty;
      else Type.UNKNOWN();
    end match;
  end typeOf;

  function setType
    input output Call call;
    input Type ty;
  algorithm
    call := match call
      case TYPED_CALL() algorithm call.ty := ty; then call;
      case TYPED_MAP_CALL() algorithm call.ty := ty; then call;
    end match;
  end setType;


protected
  function matchFunction
    input Function func;
    input list<TypedArg> args;
    input list<TypedNamedArg> named_args;
    input SourceInfo info;
    output list<TypedArg> out_args;
    output Boolean matched;
    output FunctionMatchKind matchKind;
  algorithm
    (out_args, matched) := Function.fillArgs(args, named_args, func, info);
    if matched then
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
          Error.assertion(false, getInstanceName() + " got untyped call", sourceInfo());
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

  function typedString
    "Like toString, but prefixes each argument with its type as a comment."
    input Call call;
    output String str;
  protected
    String name, arg_str,c;
    Expression argexp;
  algorithm
    str := match call
      case ARG_TYPED_CALL()
        algorithm
          name := ComponentRef.toString(call.ref);
          arg_str := stringDelimitList(list("/*" + Type.toString(Util.tuple32(arg)) + "*/ " +
            Expression.toString(Util.tuple31(arg)) for arg in call.arguments), ", ");

          for arg in call.named_args loop
            c := if arg_str == "" then "" else ", ";
            arg_str := arg_str + c + Util.tuple41(arg) + " = /*" +
              Type.toString(Util.tuple43(arg)) + "*/ " + Expression.toString(Util.tuple42(arg));
          end for;
        then
          name + "(" + arg_str + ")";

      case TYPED_CALL()
        algorithm
          name := Absyn.pathString(Function.name(call.fn));
          arg_str := stringDelimitList(list(Expression.toStringTyped(arg) for arg in call.arguments), ", ");
        then
          name + "(" + arg_str + ")";

      else toString(call);
    end match;
  end typedString;

  function typedFunction
    input Call call;
    output Function fn;
  algorithm
    fn := match call
      case TYPED_CALL() then call.fn;
      case TYPED_MAP_CALL() then call.fn;
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got untyped function", sourceInfo());
        then
          fail();
    end match;
  end typedFunction;

  function typeSizeCall
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
          Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
            {"size" + List.toString(posArgs, Expression.toStringTyped, "", "(", ", ", ")", true),
             ":\n  size(Expression) => Integer[:]\n  size(Expression, Integer) => Integer"}, info);
        then
          fail();
    end match;
  end typeSizeCall;

  function typeArrayCall
    input list<Expression> posArgs;
    input list<NamedArg> namedArgs;
    input SourceInfo info;
    output Expression arrayExp;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Type ty;
  algorithm
    // array doesn't have any named parameters.
    if not listEmpty(namedArgs) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {"array", Util.tuple21(listHead(namedArgs))}, info);
    end if;

    // array can take any number of arguments, but needs at least one.
    if listEmpty(posArgs) then
      Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {"array" + List.toString(posArgs, Expression.toStringTyped, "", "(", ", ", ")", true),
         ":\n  array(Expression, Expression, ...) => Expression[:]"}, info);
    end if;

    //TODO: Check that the arguments are type compatible.

    ty := Expression.typeOf(listHead(posArgs));
    ty := Type.liftArrayLeft(ty, Dimension.INTEGER(listLength(posArgs)));
    arrayExp := Expression.ARRAY(ty, posArgs);
  end typeArrayCall;

  function makeBuiltinCall
    "Creates a call to a builtin function, given a Function and a list of
     argument expressions."
    input Function func;
    input list<Expression> args;
    output Call call;
  algorithm
    call := TYPED_CALL(func, func.returnType, args,
      CallAttributes.CALL_ATTR(func.returnType, false, true, false, false,
        DAE.NO_INLINE(), DAE.NO_TAIL()));
  end makeBuiltinCall;

protected
  function makeBuiltinCall2
    "Creates a call to a builtin function, given a Function, list of
     argument expressions and a return type. Used for builtin functions defined with no return type."
    input Function func;
    input list<Expression> args;
    input Type returnType;  // you can use func.returnType if the buiting function is defined with the corrrect type.
    output Call call;
  algorithm
    call := TYPED_CALL(func, returnType, args,
      CallAttributes.CALL_ATTR(returnType, false, true, false, false,
        DAE.NO_INLINE(), DAE.NO_TAIL()));
  end makeBuiltinCall2;

  function typeDiscreteCall
    "Types a function call that can be typed normally, but which always has
     discrete variability regardless of the variability of the arguments."
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability = Variability.DISCRETE;
  protected
    Call argtycall;
    Function fn;
    list<TypedArg> args;
    TypedArg start,interval;
  algorithm
    argtycall := typeNormalCall(call, origin, info);
    (argtycall, ty) := matchTypedNormalCall(argtycall, info);
    callExp := Expression.CALL(unboxArgs(argtycall));
  end typeDiscreteCall;

  function typeNdimsCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty = Type.INTEGER();
    output Variability variability = Variability.PARAMETER;
  protected
    list<Expression> args;
    list<NamedArg> named_args;
    Type arg_ty;
  algorithm
    UNTYPED_CALL(arguments = args, named_args = named_args) := call;

    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {"ndims", Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) <> 1 then
      Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {"ndims" + List.toString(args, Expression.toStringTyped, "", "(", ", ", ")", true),
         ":\n  ndims(Expression) => Integer"}, info);
    end if;

    // The number of dimensions an expression has is always known,
    // so we might as well evaluate the ndims call here.
    (_, arg_ty, _) := Typing.typeExp(listHead(args), origin, info);
    callExp := Expression.INTEGER(Type.dimensionCount(arg_ty));
  end typeNdimsCall;

  function typePreCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability = Variability.DISCRETE;
  protected
    Call argtycall;
    Function fn;
    list<TypedArg> args;
    TypedArg arg;
    InstNode fn_node;
    CallAttributes ca;
  algorithm
    // pre may not be used in a function context.
    if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
      Error.addSourceMessage(Error.EXP_INVALID_IN_FUNCTION, {"pre"}, info);
    end if;

    argtycall as ARG_TYPED_CALL(ComponentRef.CREF(node = fn_node), args, _) := typeNormalCall(call, origin, info);
    (argtycall, _) := matchTypedNormalCall(argtycall, info);
    callExp := Expression.CALL(unboxArgs(argtycall));

    {arg} := args;
    if not Expression.isCref(Util.tuple31(arg)) then
      Error.addSourceMessage(Error.ARGUMENT_MUST_BE_VARIABLE,
            {"First", "pre", "<REMOVE ME>"}, info);
      fail();
    end if;

    ty := Util.tuple32(arg);
  end typePreCall;

  function typeChangeCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability = Variability.DISCRETE;
  protected
    Call argtycall;
    Function fn;
    list<TypedArg> args;
    TypedArg arg;
    InstNode fn_node;
    CallAttributes ca;
  algorithm
    // change may not be used in a function context.
    if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
      Error.addSourceMessage(Error.EXP_INVALID_IN_FUNCTION, {"change"}, info);
    end if;

    argtycall as ARG_TYPED_CALL(ComponentRef.CREF(node = fn_node), args, _) := typeNormalCall(call, origin, info);
    (argtycall, ty) := matchTypedNormalCall(argtycall, info);
    callExp := Expression.CALL(unboxArgs(argtycall));

    {arg} := args;
    if not Expression.isCref(Util.tuple31(arg)) then
      Error.addSourceMessage(Error.ARGUMENT_MUST_BE_VARIABLE,
            {"First", "change", "<REMOVE ME>"}, info);
      fail();
    end if;
  end typeChangeCall;

  function typeEdgeCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability = Variability.DISCRETE;
  protected
    Call argtycall;
    Function fn;
    list<TypedArg> args;
    TypedArg arg;
    InstNode fn_node;
    CallAttributes ca;
  algorithm
    // edge may not be used in a function context.
    if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
      Error.addSourceMessage(Error.EXP_INVALID_IN_FUNCTION, {"edge"}, info);
    end if;

    argtycall as ARG_TYPED_CALL(ComponentRef.CREF(node = fn_node), args, _) := typeNormalCall(call, origin, info);
    (argtycall, ty) := matchTypedNormalCall(argtycall, info);
    callExp := Expression.CALL(unboxArgs(argtycall));

    {arg} := args;
    if not Expression.isCref(Util.tuple31(arg)) then
      Error.addSourceMessage(Error.ARGUMENT_MUST_BE_VARIABLE,
            {"First", "edge", "<REMOVE ME>"}, info);
      fail();
    end if;
  end typeEdgeCall;

  function typeMinMaxCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    Call argtycall;
    Function fn;
    list<TypedArg> args;
    TypedArg start,interval;
  algorithm
    argtycall as ARG_TYPED_CALL(_, args, _) := typeNormalCall(call, origin, info);
    (argtycall, ty, variability) := matchTypedNormalCall(argtycall, info);
    callExp := Expression.CALL(unboxArgs(argtycall));
    ty := Type.arrayElementType(Util.tuple32(listHead(args)));
    // TODO: check basic type in two argument overload.
    // check arrays of simple types in one argument overload.
    // fix return type.
  end typeMinMaxCall;

  function typeSumProductCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    Call argtycall;
    Function fn;
    Expression arg;
  algorithm
    argtycall := typeNormalCall(call, origin, info);
    (argtycall, ty, variability) := matchTypedNormalCall(argtycall, info);
    argtycall := unboxArgs(argtycall);

    // TODO: check arrays of simple types.
    ty := match argtycall
      case TYPED_CALL() algorithm
        {arg} := argtycall.arguments;
      then Type.arrayElementType(Expression.typeOf(arg));
    end match;

    callExp := Expression.CALL(setType(argtycall, ty));
  end typeSumProductCall;

  function typeSmoothCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    Call argtycall;
    Function fn;
    list<TypedArg> args;
    TypedArg start,interval;
  algorithm
    argtycall as ARG_TYPED_CALL(_, args, _) := typeNormalCall(call, origin, info);
    (argtycall, ty, variability) := matchTypedNormalCall(argtycall, info);

    // TODO: check if second argument is real or array of real or record of reals.
    callExp := Expression.CALL(unboxArgs(argtycall));
  end typeSmoothCall;

  function typeFillCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression fill_arg;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    // fill doesn't have any named parameters.
    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {"fill", Util.tuple21(listHead(named_args))}, info);
    end if;

    // fill can take any number of arguments, but needs at least two.
    if listLength(args) < 2 then
      Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {"fill" + List.toString(args, Expression.toStringTyped, "", "(", ", ", ")", true),
         ":\n  fill(Expression, Integer, ...) => Expression[:, ...]"}, info);
    end if;

    fill_arg :: args := args;

    // Type the first argument, which is the fill value.
    (fill_arg, ty, _) := Typing.typeExp(fill_arg, origin, info);
    (callExp, ty, variability) := typeFillCall2(fn_ref, ty, {fill_arg}, args, origin, info);
  end typeFillCall;

  function typeFillCall2
    input ComponentRef fnRef;
    input Type fillType;
    input list<Expression> fillArgs;
    input list<Expression> dimensionArgs;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability = Variability.CONSTANT;
  protected
    Expression fill_arg;
    list<Expression> ty_args;
    Variability arg_var;
    Type arg_ty;
    Function fn;
    list<Dimension> dims;
  algorithm
    ty_args := fillArgs;
    dims := {};

    // Type the dimension arguments.
    for arg in dimensionArgs loop
      (arg, arg_ty, arg_var) := Typing.typeExp(arg, origin, info);

      // Each dimension argument must be an Integer expression.
      if not Type.isInteger(arg_ty) then
        Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
          {intString(listLength(ty_args) + 1), ComponentRef.toString(fnRef), "",
          Expression.toString(arg), Type.toString(arg_ty), "Integer"}, info);
      end if;

      variability := Prefixes.variabilityMax(variability, arg_var);
      ty_args := arg :: ty_args;
      dims := Dimension.fromExp(arg, arg_var) :: dims;
    end for;

    ty_args := listReverseInPlace(ty_args);
    dims := listReverseInPlace(dims);

    {fn} := typeCachedFunctions(fnRef);
    ty := Type.ARRAY(fillType, dims);
    callExp := Expression.CALL(makeBuiltinCall2(fn, ty_args, ty));
  end typeFillCall2;

  function typeZerosOnesCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression fill_arg;
    String name;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    // zeros/ones doesn't have any named parameters.
    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {ComponentRef.toString(fn_ref), Util.tuple21(listHead(named_args))}, info);
    end if;

    // zeros/ones can take any number of arguments, but needs at least one.
    if listEmpty(args) then
      name := ComponentRef.toString(fn_ref);
      Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {name + List.toString(args, Expression.toStringTyped, "", "(", ", ", ")", true),
         ":\n  " + name + "(Integer, ...) => Integer[:, ...]"}, info);
    end if;

    (callExp, ty, variability) := typeFillCall2(fn_ref, Type.INTEGER(), {}, args, origin, info);
  end typeZerosOnesCall;

  function typeScalarCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    Call argtycall;
    Expression arg;
    Type argty;
    list<Dimension> dims;
    Dimension dim1,dim2;
  algorithm
    argtycall := typeNormalCall(call, origin, info);
    (argtycall, ty, variability) := matchTypedNormalCall(argtycall, info);
    argtycall := unboxArgs(argtycall);

    // check extra dimensions (>0) are 1.
    ty := match argtycall
      case TYPED_CALL() algorithm
        {arg} := argtycall.arguments;
        argty := Expression.typeOf(arg);
        dims := Type.arrayDims(argty);

        if listLength(dims) > 0 then
          for d in dims loop
            if not Dimension.isEqualKnown(d, Dimension.INTEGER(1)) then
              // TODO: Proper error message
              print("Argument should have all extra dimensions (>0) equal to 1, i.e, size(A,i) = 1 is required for 1 <= i <= ndims(A).");
              fail();
            end if;
          end for;
        end if;
      then Type.arrayElementType(argty);
    end match;

    callExp := Expression.CALL(setType(argtycall, ty));
  end typeScalarCall;

  function typeVectorCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    Call argtycall;
    Expression arg;
    Type argty;
    list<Dimension> dims;
    Integer size;
  algorithm
    argtycall := typeNormalCall(call, origin, info);
    (argtycall, ty, variability) := matchTypedNormalCall(argtycall, info);
    argtycall := unboxArgs(argtycall);

    ty := match argtycall
      case TYPED_CALL() algorithm
        {arg} := argtycall.arguments;
        argty := Expression.typeOf(arg);
        dims := Type.arrayDims(argty);

        if listLength(dims) == 0 then
          dims := {Dimension.INTEGER(1)};
        else
          size := 0;
          for d in dims loop
            if not Dimension.isEqualKnown(d, Dimension.INTEGER(1)) then
              // let this fail if dim is expression
              // The proper way to do this would be to create and ADD() expression.
              // that will need a Dimension to exp function.
              size := size + Dimension.size(d);
            end if;
          end for;
          dims := {Dimension.INTEGER(size)};
        end if;
      then Type.ARRAY(Type.arrayElementType(argty), dims);
    end match;

    callExp := Expression.CALL(setType(argtycall,ty));
  end typeVectorCall;

  function typeMatrixCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    Call argtycall;
    Expression arg;
    Type argty;
    list<Dimension> dims;
    Dimension dim1,dim2;
  algorithm
    argtycall := typeNormalCall(call, origin, info);
    (argtycall, ty, variability) := matchTypedNormalCall(argtycall, info);
    argtycall := unboxArgs(argtycall);

    // check extra dimensions (>2) are 1.
    // take <2 dimensions from the argument
    ty := match argtycall
      case TYPED_CALL() algorithm
        {arg} := argtycall.arguments;
        argty := Expression.typeOf(arg);
        dims := Type.arrayDims(argty);

        if listLength(dims) == 0 then
          dims := {Dimension.INTEGER(1),Dimension.INTEGER(1)};
        elseif listLength(dims) == 1 then
          {dim1} := dims;
          dims := {dim1,Dimension.INTEGER(1)};
        elseif listLength(dims) > 2 then
          dim1::dims := dims;
          dim2::dims := dims;

          for d in dims loop
            if not Dimension.isEqualKnown(d, Dimension.INTEGER(1)) then
              // TODO: Proper error message
              print("Argument should have all extra dimensions (>2) equal to 1, i.e, size(A,i) = 1 is required for 2 < i <= ndims(A).");
              fail();
            end if;
          end for;
          dims := {dim1,dim2};
        end if;
      then Type.ARRAY(Type.arrayElementType(argty), dims);
    end match;

    callExp := Expression.CALL(setType(argtycall,ty));
  end typeMatrixCall;

  function typeSymmetricCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    Call argtycall;
    Expression arg;
  algorithm
    argtycall := typeNormalCall(call, origin, info);
    (argtycall, ty, variability) := matchTypedNormalCall(argtycall, info);
    argtycall := unboxArgs(argtycall);

    ty := match argtycall
      case TYPED_CALL() algorithm
        {arg} := argtycall.arguments;
        // set the output type same as the input type.
      then Expression.typeOf(arg);
    end match;

    callExp := Expression.CALL(setType(argtycall,ty));
  end typeSymmetricCall;

  function typeTransposeCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    Call argtycall;
    Expression arg;
    Type argty;
    list<Dimension> dims;
    Dimension dim1,dim2;
  algorithm
    argtycall := typeNormalCall(call, origin, info);
    (argtycall, ty, variability) := matchTypedNormalCall(argtycall, info);
    argtycall := unboxArgs(argtycall);

    ty := match argtycall
      case TYPED_CALL() algorithm
        {arg} := argtycall.arguments;
        argty := Expression.typeOf(arg);
        dims := Type.arrayDims(argty);

        if listLength(dims) < 2 then
          print("Transpose expects at least two dimensions.");
          fail();
        else
          dim1::dims := dims;
          dim2::dims := dims;
          dims := dim1::dims;
          dims := dim2::dims;
        end if;
      then Type.ARRAY(Type.arrayElementType(argty), dims);
    end match;

    callExp := Expression.CALL(setType(argtycall,ty));
  end typeTransposeCall;

  function typeCardinalityCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability = Variability.PARAMETER;
  protected
    Call argtycall;
    Expression arg;
    Type argty;
    list<Dimension> dims;
    Dimension dim1,dim2;
  algorithm
    argtycall := typeNormalCall(call, origin, info);
    (argtycall, ty, _) := matchTypedNormalCall(argtycall, info);
    callExp := Expression.CALL(unboxArgs(argtycall));
    // TODO: Check cardinality restrictions, 3.7.2.3.
  end typeCardinalityCall;

  function typeNoEventCall
    input Call call;
    input Integer origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    // noEvent doesn't have any named parameters.
    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {"noEvent", Util.tuple21(listHead(named_args))}, info);
    end if;

    // noEvent takes exactly one argument.
    if listLength(args) <> 1 then
      Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {"noEvent" + List.toString(args, Expression.toString, "", "(", ", ", ")", true),
         ":\n  noEvent(Expression) => Expression"}, info);
    end if;

    {arg} := args;
    (arg, ty, variability) := Typing.typeExp(arg, intBitOr(origin, ExpOrigin.NOEVENT), info);

    {fn} := typeCachedFunctions(fn_ref);
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg}, ty));
  end typeNoEventCall;

  function unboxArgs
    input output Call call;
  algorithm
    () := match call
      case TYPED_CALL()
        algorithm
          call.arguments := list(Expression.unbox(arg) for arg in call.arguments);
        then
          ();
    end match;
  end unboxArgs;

  function candidateFuncListString
    input list<Function> fns;
    input Option<Absyn.Path> overload_name;
    output String s = stringDelimitList(list(Function.signatureString(fn, true, overload_name) for fn in fns), "\n  ");
  end candidateFuncListString;

end Call;

annotation(__OpenModelica_Interface="frontend");
end NFCall;
