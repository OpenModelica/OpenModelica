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
import Expression = NFExpression;
import NFInstNode.InstNode;
import NFPrefixes.Variability;
import Type = NFType;

protected
import BuiltinCall = NFBuiltinCall;
import Ceval = NFCeval;
import ComponentRef = NFComponentRef;
import Dimension = NFDimension;
import ErrorExt;
import Inline = NFInline;
import Inst = NFInst;
import List;
import Lookup = NFLookup;
import MetaModelica.Dangerous.listReverseInPlace;
import NFBinding.Binding;
import NFClass.Class;
import NFComponent.Component;
import NFFunction.Function;
import NFFunction.FunctionMatchKind;
import NFFunction.MatchedFunction;
import NFFunction.NamedArg;
import NFFunction.TypedArg;
import NFFunction.TypedNamedArg;
import NFInstNode.CachedData;
import NFTyping.ExpOrigin;
import Prefixes = NFPrefixes;
import TypeCheck = NFTypeCheck;
import Typing = NFTyping;
import Util;

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

protected
  type ParameterTree = ParameterTreeImpl.Tree;

  encapsulated package ParameterTreeImpl
    import BaseAvlTree;
    import Expression = NFExpression;

    extends BaseAvlTree(redeclare type Key = String,
                        redeclare type Value = Expression);

    redeclare function extends keyStr
    algorithm
      outString := inKey;
    end keyStr;

    redeclare function extends valueStr
    algorithm
      outString := Expression.toString(inValue);
    end valueStr;

    redeclare function extends keyCompare
    algorithm
      outResult := stringCompare(inKey1, inKey2);
    end keyCompare;

    annotation(__OpenModelica_Interface="util");
  end ParameterTreeImpl;

public
uniontype Call
  record UNTYPED_CALL
    ComponentRef ref;
    list<Expression> arguments;
    list<NamedArg> named_args;
    InstNode call_scope;
  end UNTYPED_CALL;

  record ARG_TYPED_CALL
    ComponentRef ref;
    list<TypedArg> arguments;
    list<TypedNamedArg> named_args;
    InstNode call_scope;
  end ARG_TYPED_CALL;

  record TYPED_CALL
    Function fn;
    Type ty;
    Variability var;
    list<Expression> arguments;
    CallAttributes attributes;
  end TYPED_CALL;

  // Right now this represents only array() calls.
  // Any other mapping call e.g. F(i for i in ...) is converted to
  // array(F(i) for i in ...) at instIteratorCall().
  // So the fn is always NFBuiltinFuncs.ARRAY_FUNC.

  // Note that F(i for i in ...) only allows
  // calling functions with just one argument according to the current
  // grammar anyway. array(F(i,j) for i in ..) makes this multi calls possible
  // in Modelica code.

  // If you need to have more mapping calls e.g list() at some point just add them
  // and make use of fn;
  record UNTYPED_MAP_CALL
    // Function fn;
    Expression exp;
    list<tuple<InstNode, Expression>> iters;
  end UNTYPED_MAP_CALL;

  record TYPED_MAP_CALL
    // Function fn;
    Type ty;
    Variability var;
    Expression exp;
    list<tuple<InstNode, Expression>> iters;
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
  end instantiate;

  function typeCall
    input Expression callExp;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression outExp;
    output Type ty;
    output Variability var;
  protected
    Call call;
    list<Expression> args;
    ComponentRef cref;
  algorithm
    outExp := match callExp
      case Expression.CALL(UNTYPED_CALL(ref = cref))
        algorithm
          if(BuiltinCall.needSpecialHandling(callExp.call)) then
            (outExp, ty, var) := BuiltinCall.typeSpecial(callExp.call, origin, info);
          else
            call := typeMatchNormalCall(callExp.call, origin, info);
            ty := typeOf(call);
            var := variability(call);

            if isRecordConstructor(call) then
              outExp := toRecordExpression(call, ty);
            else
              outExp := Expression.CALL(call);
              outExp := Inline.inlineCallExp(outExp);
            end if;
          end if;
        then
          outExp;

      case Expression.CALL(UNTYPED_MAP_CALL())
        algorithm
          call := typeMapIteratorCall(callExp.call, origin, info);
          ty := typeOf(call);
          var := variability(call);
        then
          Expression.CALL(call);

      case Expression.CALL(call as TYPED_CALL())
        algorithm
          ty := call.ty;
          var := call.var;
        then
          callExp;

      case Expression.CALL(call as TYPED_MAP_CALL())
        algorithm
          ty := call.ty;
          var := call.var;
        then
          callExp;

      else
        algorithm
          Error.assertion(false, getInstanceName() + ": " + Expression.toString(callExp), sourceInfo());
        then fail();
    end match;
  end typeCall;

  function typeNormalCall
    input output Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
  algorithm
    call := match call
      local
        list<Function> fnl;
        Boolean is_external;

      case UNTYPED_CALL()
        algorithm
          fnl := Function.typeRefCache(call.ref);
          // Don't evaluate constants or structural parameters for external functions,
          // the code generation can't handle it in some cases (see bug #4904).
          // TODO: Remove this when #4904 is fixed.
          is_external := if listEmpty(fnl) then false else Function.isExternal(listHead(fnl));
        then
          typeArgs(call, not is_external, origin, info);

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got invalid function call expression", sourceInfo());
        then
          fail();
    end match;
  end typeNormalCall;

  function makeTypedCall
    input Function fn;
    input list<Expression> args;
    input Variability variability;
    input Type returnType = fn.returnType;
    output Call call;
  protected
    CallAttributes ca;
  algorithm
    ca := CallAttributes.CALL_ATTR(
      returnType,
      Type.isTuple(returnType),
      Function.isBuiltin(fn),
      Function.isImpure(fn),
      Function.isFunctionPointer(fn),
      Function.inlineBuiltin(fn),
      DAE.NO_TAIL()
    );

    call := TYPED_CALL(fn, returnType, variability, args, ca);
  end makeTypedCall;

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

  function typeMatchNormalCall
    input output Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
  protected
    Call argtycall;
  algorithm
    argtycall := typeNormalCall(call, origin, info);
    call := matchTypedNormalCall(argtycall, origin, info);
  end typeMatchNormalCall;

  function matchTypedNormalCall
    input output Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
  protected
    Function func;
    list<Expression> args;
    list<TypedArg> typed_args;
    MatchedFunction matchedFunc;
    InstNode scope;
    Variability var, arg_var;
    Type ty;
    Expression arg_exp;
  algorithm
    ARG_TYPED_CALL(call_scope = scope) := call;
    matchedFunc := checkMatchingFunctions(call,info);

    func := matchedFunc.func;
    typed_args := matchedFunc.args;

    args := {};
    var := Variability.CONSTANT;
    for a in typed_args loop
      (arg_exp, _, arg_var) := a;
      args := arg_exp :: args;
      var := Prefixes.variabilityMax(var, arg_var);
    end for;
    args := listReverseInPlace(args);

    ty := Function.returnType(func);

    // Hack to fix return type of some builtin functions.
    if Type.isPolymorphic(ty) then
      ty := getSpecialReturnType(func, args);
    end if;

    // Functions that return a discrete type, e.g. Integer, should probably be
    // treated as implicitly discrete if the arguments are continuous.
    if Type.isDiscrete(ty) and var == Variability.CONTINUOUS then
      var := Variability.IMPLICITLY_DISCRETE;
    end if;

    if intBitAnd(origin, ExpOrigin.FUNCTION) == 0 then
      ty := evaluateCallType(ty, func, args);
    end if;

    call := makeTypedCall(func, args, var, ty);

    // If the matching was a vectorized one then create a map call
    // using the vectorization dim. This means going through each argument
    // and subscipting it with an iterator for each dim and creating a map call.
    if MatchedFunction.isVectorized(matchedFunc) then
      call := vectorizeCall(call, matchedFunc.mk, scope, info);
    end if;
  end matchTypedNormalCall;

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

  function variability
    input Call call;
    output Variability var;
  algorithm
    var := match call
      local
        Boolean var_set;

      case UNTYPED_CALL()
        algorithm
          var_set := true;

          if ComponentRef.isSimple(call.ref) then
            var := match ComponentRef.firstName(call.ref)
              case "change" then Variability.DISCRETE;
              case "edge" then Variability.DISCRETE;
              case "pre" then Variability.DISCRETE;
              case "ndims" then Variability.PARAMETER;
              case "cardinality" then Variability.PARAMETER;
              else algorithm var_set := false; then Variability.CONTINUOUS;
            end match;
          end if;

          if not var_set then
            var := Expression.variabilityList(call.arguments);

            for narg in call.named_args loop
              var := Prefixes.variabilityMax(var, Expression.variability(Util.tuple22(narg)));
            end for;
          end if;
        then
          var;

      case UNTYPED_MAP_CALL() then Expression.variability(call.exp);
      case TYPED_CALL() then call.var;
      case TYPED_MAP_CALL() then call.var;
      else algorithm
        Error.assertion(false, getInstanceName() + " got untyped call", sourceInfo());
        then fail();
    end match;
  end variability;

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

  function isExternal
    input Call call;
    output Boolean isExternal;
  algorithm
    isExternal := match call
      case UNTYPED_CALL() then Class.isExternalFunction(InstNode.getClass(ComponentRef.node(call.ref)));
      case ARG_TYPED_CALL() then Class.isExternalFunction(InstNode.getClass(ComponentRef.node(call.ref)));
      case TYPED_CALL() then Function.isExternal(call.fn);
      else false;
    end match;
  end isExternal;

  function isRecordConstructor
    input Call call;
    output Boolean isConstructor;
  algorithm
    isConstructor := match call
      case UNTYPED_CALL()
        then SCode.isRecord(InstNode.definition(ComponentRef.node(call.ref)));
      case TYPED_CALL()
        then SCode.isRecord(InstNode.definition(call.fn.node));
      else false;
    end match;
  end isRecordConstructor;

  function inlineType
    input Call call;
    output DAE.InlineType inlineTy;
  algorithm
    inlineTy := match call
      case TYPED_CALL(attributes = CallAttributes.CALL_ATTR(inlineType = inlineTy))
        then inlineTy;
      else DAE.InlineType.NO_INLINE();
    end match;
  end inlineType;

  function typedFunction
    input Call call;
    output Function fn;
  algorithm
    fn := match call
      case TYPED_CALL() then call.fn;
      case TYPED_MAP_CALL() then NFBuiltinFuncs.ARRAY_FUNC;
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got untyped function", sourceInfo());
        then
          fail();
    end match;
  end typedFunction;

  function arguments
    input Call call;
    output list<Expression> arguments;
  algorithm
    arguments := match call
      case UNTYPED_CALL() then call.arguments;
      case TYPED_CALL() then call.arguments;
    end match;
  end arguments;

  function toRecordExpression
    input Call call;
    input Type ty;
    output Expression exp;
  algorithm
    exp := match call
      case TYPED_CALL()
        then Expression.RECORD(Function.name(call.fn), ty, call.arguments);
    end match;
  end toRecordExpression;

  function toString
    input Call call;
    output String str;
  protected
    String name, arg_str,c;
    Expression argexp;
    list<InstNode> iters;
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
          name := Absyn.pathString(Function.name(NFBuiltinFuncs.ARRAY_FUNC));
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
          name := Absyn.pathString(Function.name(NFBuiltinFuncs.ARRAY_FUNC));
          arg_str := Expression.toString(call.exp);
          c := stringDelimitList(list(InstNode.name(Util.tuple21(iter)) + " in " +
            Expression.toString(Util.tuple22(iter)) for iter in call.iters), ", ");
        then
          name + "(" + arg_str + " for " + c + ")";

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

  function toDAE
    input Call call;
    output DAE.Exp daeCall;
  algorithm
    daeCall := match call
      case TYPED_CALL()
        then DAE.CALL(
          Function.nameConsiderBuiltin(call.fn),
          list(Expression.toDAE(e) for e in call.arguments),
          CallAttributes.toDAE(call.attributes));

      case TYPED_MAP_CALL()
        then DAE.REDUCTION(
          DAE.REDUCTIONINFO(
            Function.name(NFBuiltinFuncs.ARRAY_FUNC),
            Absyn.COMBINE(),
            Type.toDAE(call.ty),
            NONE(),
            String(Util.getTempVariableIndex()),
            String(Util.getTempVariableIndex()),
            NONE()),
          Expression.toDAE(call.exp),
          list(iteratorToDAE(iter) for iter in call.iters));

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got untyped call", sourceInfo());
        then
          fail();
    end match;
  end toDAE;

  function isVectorizeable
    input Call call;
    output Boolean isVect;
  algorithm
    isVect := match call
      local
        String name;

      case TYPED_CALL(fn = Function.FUNCTION(path = Absyn.IDENT(name = name)))
        then match name
          case "der" then false;
          case "pre" then false;
          case "previous" then false;
          else true;
        end match;

      else true;
    end match;
  end isVectorizeable;

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
  algorithm
    (args, named_args) := instArgs(functionArgs, scope, info);

    callExp := match Absyn.crefFirstIdent(functionName)
      // size creates Expression.SIZE instead of Expression.CALL.
      case "size" then BuiltinCall.makeSizeExp(args, named_args, info);
      // array() call with no iterators creates Expression.ARRAY instead of Expression.CALL.
      // If it had iterators then it will not reach here. The args would have been parsed to
      // Absyn.FOR_ITER_FARG and that is handled in instIteratorCall.
      case "array" then BuiltinCall.makeArrayExp(args, named_args, info);
      else
        algorithm
          fn_ref := Function.instFunction(functionName,scope,info);
        then
          Expression.CALL(UNTYPED_CALL(fn_ref, args, named_args, scope));
    end match;
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
    ComponentRef fn_ref, arr_fn_ref;
    Expression exp;
    list<tuple<InstNode, Expression>> iters;
    Call call;
    Boolean is_builtin_reduction, is_array;
  algorithm
    (is_builtin_reduction, is_array) := match Absyn.crefFirstIdent(functionName)
      case "$array" then (false, true);
      case "array" then (false, true);
      case "min" then (true, false);
      case "max" then (true, false);
      case "sum" then (true, false);
      case "product" then (true, false);
      else (false, false);
    end match;

    (exp, iters) := instIteratorCallArgs(functionArgs, scope, info);

    // If it is one of the builtin functions above the call operates as a "reduction"
    // (think of it like just a call to the overload of the function that takes array as argument.)
    // We handle it by making a call to the builtin function with an array as argument.
    // Which is valid since all these builtin functions accept array arguments anyway.
    if is_builtin_reduction then
      // start by making an array map call.
      call := UNTYPED_MAP_CALL(exp, iters);

      // wrap the array call in the given function
      // e.g. sum(array(i for i in ...)).
      fn_ref := Function.instFunction(functionName, scope, info);
      call := UNTYPED_CALL(fn_ref, {Expression.CALL(call)}, {}, scope);
    else
      // Otherwise, make an array call with the original function call as an argument.
      // But only if the original function is not array() itself.
      // e.g. Change myfunc(i for i in ...) TO array(myfunc(i) for i in ...).
      if not is_array then
      fn_ref := Function.instFunction(functionName, scope, info);
        call := UNTYPED_CALL(fn_ref, {exp}, {}, scope);
        exp := Expression.CALL(call);
      end if;

      call := UNTYPED_MAP_CALL(exp, iters);
    end if;

    callExp := Expression.CALL(call);
  end instIteratorCall;

  function instIteratorCallArgs
    input Absyn.FunctionArgs args;
    input InstNode scope;
    input SourceInfo info;
    output Expression exp;
    output list<tuple<InstNode, Expression>> iters;
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
    output InstNode outScope = scope;
    output list<tuple<InstNode, Expression>> outIters = {};
  protected
    Expression range;
    InstNode iter;
  algorithm
    for i in inIters loop
      range := Inst.instExp(Util.getOption(i.range), outScope, info);
      (outScope, iter) := Inst.addIteratorToScope(i.name, outScope, info);
      outIters := (iter, range) :: outIters;
    end for;

    outIters := listReverse(outIters);
  end instIterators;

  function typeMapIteratorCall
    input output Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
          output Type ty;
          output Variability variability;
  protected
    Expression arg, range;
    Type iter_ty;
    Binding binding;
    Variability iter_var;
    InstNode iter;
    list<Dimension> dims = {};
    list<tuple<InstNode, Expression>> iters = {};
    ExpOrigin.Type next_origin;
  algorithm
    (call, ty, variability) := match call
      // This is always a call to the function array()/$array(). See instIteratorCall.
      // Other mapping function calls are already wrapped by array() at this point.
      case UNTYPED_MAP_CALL()
        algorithm
          variability := Variability.CONSTANT;

          for i in call.iters loop
            (iter, range) := i;
            (range, iter_ty, iter_var) := Typing.typeIterator(iter, range, origin, structural = false);
            dims := listAppend(Type.arrayDims(iter_ty), dims);
            variability := Variability.variabilityMax(variability, iter_var);
            iters := (iter, range) :: iters;
          end for;
          iters := listReverseInPlace(iters);

          // ExpOrigin.FOR is used here as a marker that this expression may contain iterators.
          next_origin := intBitOr(origin, ExpOrigin.FOR);
          (arg, ty) := Typing.typeExp(call.exp, next_origin, info);
          ty := Type.liftArrayLeftList(ty, dims);
        then
          (TYPED_MAP_CALL(ty, variability, arg, iters), ty, variability);

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got invalid function call expression", sourceInfo());
        then
          fail();
    end match;
  end typeMapIteratorCall;

  function typeArgs
    input output Call call;
    input Boolean replaceConstants;
    input ExpOrigin.Type origin;
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
            (arg, arg_ty, arg_var) := Typing.typeExp(arg, origin, info, replaceConstants = replaceConstants);
            typedArgs := (arg, arg_ty, arg_var) :: typedArgs;
          end for;

          typedArgs := listReverse(typedArgs);

          typedNamedArgs := {};
          for narg in call.named_args loop
            (name,arg) := narg;
            (arg, arg_ty, arg_var) := Typing.typeExp(arg, origin, info, replaceConstants = replaceConstants);
            typedNamedArgs := (name, arg, arg_ty, arg_var) :: typedNamedArgs;
          end for;

          typedNamedArgs := listReverse(typedNamedArgs);
        then
          ARG_TYPED_CALL(call.ref, typedArgs, typedNamedArgs, call.call_scope);
    end match;
  end typeArgs;

  function checkMatchingFunctions
    input Call call;
    input SourceInfo info;
    output MatchedFunction matchedFunc;
  protected
    list<MatchedFunction> matchedFunctions, exactMatches;
    Function func;
    list<Function> allfuncs;
    InstNode fn_node;
    Integer numerr = Error.getNumErrorMessages();
    list<Integer> errors;
  algorithm
    ErrorExt.setCheckpoint("NFCall:checkMatchingFunctions");

    matchedFunctions := match call
      case ARG_TYPED_CALL(ref = ComponentRef.CREF(node = fn_node))
        algorithm
          allfuncs := Function.getCachedFuncs(fn_node);

          if listLength(allfuncs) > 1 then
            allfuncs := list(fn for fn guard not Function.isDefaultRecordConstructor(fn) in allfuncs);
          end if;
        then
          Function.matchFunctions(allfuncs, call.arguments, call.named_args, info);
    end match;

    if listEmpty(matchedFunctions) then
      // Don't show error messages for overloaded functions, it leaks
      // implementation details and usually doesn't provide any more info than
      // what the "no match found" error gives anyway.
      if listLength(allfuncs) > 1 then
        ErrorExt.rollBack("NFCall:checkMatchingFunctions");
        Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
            {typedString(call), Function.candidateFuncListString(allfuncs)}, info);

      // Only show the error message for no matching functions if no other error
      // was shown.
      // functions that for some reason failed to match without giving any error.
      elseif numerr == Error.getNumErrorMessages() then
        ErrorExt.rollBack("NFCall:checkMatchingFunctions");
        Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
            {typedString(call), Function.candidateFuncListString(allfuncs)}, info);
      else
        ErrorExt.delCheckpoint("NFCall:checkMatchingFunctions");
      end if;

      fail();
    end if;

    // If we have at least one matching function then we discard all error messages
    // about matching. We have one matching func if we reach here.
    ErrorExt.rollBack("NFCall:checkMatchingFunctions");

    if listLength(matchedFunctions) > 1 then
      exactMatches := MatchedFunction.getExactMatches(matchedFunctions);

      if listLength(exactMatches) > 1 then
        Error.addSourceMessage(Error.AMBIGUOUS_MATCHING_FUNCTIONS_NFINST,
          {typedString(call), Function.candidateFuncListString(list(mfn.func for mfn in matchedFunctions))}, info);
          fail();
      end if;

      matchedFunc := listHead(exactMatches);
    else
      matchedFunc := listHead(matchedFunctions);
    end if;

    // Overwrite the actual function name with the overload name for builtin functions.
    if Function.isBuiltin(matchedFunc.func) then
      func := matchedFunc.func;
      func.path := Function.nameConsiderBuiltin(func);
      matchedFunc.func := func;
    end if;
  end checkMatchingFunctions;

  function iteratorToDAE
    input tuple<InstNode, Expression> iter;
    output DAE.ReductionIterator diter;
  protected
    InstNode iter_node;
    Expression iter_range;
    Component c;
    Binding b;
  algorithm
    (iter_node, iter_range) := iter;
    diter := DAE.REDUCTIONITER(InstNode.name(iter_node), Expression.toDAE(iter_range), NONE(),
      Type.toDAE(Expression.typeOf(iter_range)));
  end iteratorToDAE;

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

  function vectorizeCall
    input Call base_call;
    input FunctionMatchKind mk;
    input InstNode scope;
    input SourceInfo info;
    output Call vectorized_call;
  protected
    Type ty, vect_ty;
    Expression exp;
    list<tuple<InstNode, Expression>> iters;
    InstNode iter;
    Integer i;
    list<Dimension> vect_dims;
    list<Boolean> arg_is_vected, b_list;
    Boolean b;
    list<Expression> vect_args;
  algorithm
    vectorized_call := match base_call
      case TYPED_CALL()
        algorithm
          FunctionMatchKind.VECTORIZED(vect_dims, arg_is_vected) := mk;
          iters := {};
          i := 1;

          for dim in vect_dims loop
            Error.assertion(Dimension.isKnown(dim, allowExp = true), getInstanceName() +
              " got unknown dimension for vectorized call", info);

            // Create the range on which we will iterate to vectorize.
            ty := Type.ARRAY(Type.INTEGER(), {dim});
            exp := Expression.RANGE(ty, Expression.INTEGER(1), NONE(), Dimension.sizeExp(dim));

            // Create the iterator.
            iter := InstNode.fromComponent("$i" + intString(i),
              Component.ITERATOR(Type.INTEGER(), Variability.CONSTANT, info), scope);

            iters := (iter, exp) :: iters;

            // Now that iterator is ready apply it, as a subscript, to each argument that is supposed to be vectorized
            // Make a cref expression from the iterator
            exp := Expression.CREF(Type.INTEGER(), ComponentRef.makeIterator(iter, Type.INTEGER()));
            vect_args := {};
            b_list := arg_is_vected;
            for arg in base_call.arguments loop
              // If the argument is supposed to be vectorized
              b :: b_list := b_list;
              vect_args := (if b then Expression.applyIndexSubscript(exp, arg) else arg) :: vect_args;
            end for;

            base_call.arguments := listReverse(vect_args);
            i := i + 1;
          end for;

          vect_ty := Type.liftArrayLeftList(base_call.ty, vect_dims);
        then
          TYPED_MAP_CALL(vect_ty, base_call.var, Expression.CALL(base_call), iters);

     end match;
  end vectorizeCall;

  function evaluateCallType
    input output Type ty;
    input Function fn;
    input list<Expression> args;
    input output ParameterTree ptree = ParameterTree.EMPTY();
  algorithm
    ty := match ty
      local
        list<Dimension> dims;
        list<Type> tys;

      case Type.ARRAY()
        algorithm
          (dims, ptree) := List.map1Fold(ty.dimensions, evaluateCallTypeDim, (fn, args), ptree);
          ty.dimensions := dims;
        then
          ty;

      case Type.TUPLE()
        algorithm
          (tys, ptree) := List.map2Fold(ty.types, evaluateCallType, fn, args, ptree);
          ty.types := tys;
        then
          ty;

      else ty;
    end match;
  end evaluateCallType;

  function evaluateCallTypeDim
    input output Dimension dim;
    input tuple<Function, list<Expression>> fnArgs;
    input output ParameterTree ptree;
  algorithm
    dim := match dim
      local
        Expression exp;

      case Dimension.EXP()
        algorithm
          ptree := buildParameterTree(fnArgs, ptree);
          exp := Expression.map(dim.exp, function evaluateCallTypeDimExp(ptree = ptree));
          exp := Ceval.evalExp(exp, Ceval.EvalTarget.IGNORE_ERRORS());
        then
          Dimension.fromExp(exp, Variability.CONSTANT);

      else dim;
    end match;
  end evaluateCallTypeDim;

  function buildParameterTree
    input tuple<Function, list<Expression>> fnArgs;
    input output ParameterTree ptree;
  protected
    Function fn;
    list<Expression> args;
    Expression arg;
  algorithm
    if not ParameterTree.isEmpty(ptree) then
      return;
    end if;

    (fn, args) := fnArgs;

    for i in fn.inputs loop
      arg :: args := args;
      ptree := ParameterTree.add(ptree, InstNode.name(i), arg);
    end for;

    // TODO: Add local variable bindings.
  end buildParameterTree;

  function evaluateCallTypeDimExp
    input Expression exp;
    input ParameterTree ptree;
    output Expression outExp;
  algorithm
    outExp := match exp
      local
        InstNode node;
        Option<Expression> oexp;
        Expression e;

      case Expression.CREF(cref = ComponentRef.CREF(node = node, restCref = ComponentRef.EMPTY()))
        algorithm
          oexp := ParameterTree.getOpt(ptree, InstNode.name(node));

          if isSome(oexp) then
            SOME(outExp) := oexp;
            // TODO: Apply subscripts.
          end if;
        then
          outExp;

      else exp;
    end match;
  end evaluateCallTypeDimExp;

  function getSpecialReturnType
    input Function fn;
    input list<Expression> args;
    output Type ty;
  algorithm
    ty := match fn.path
      case Absyn.IDENT("min")
        then Type.arrayElementType(Expression.typeOf(Expression.unbox(listHead(args))));
      case Absyn.IDENT("max")
        then Type.arrayElementType(Expression.typeOf(Expression.unbox(listHead(args))));
      case Absyn.IDENT("sum")
        then Type.arrayElementType(Expression.typeOf(Expression.unbox(listHead(args))));
      case Absyn.IDENT("product")
        then Type.arrayElementType(Expression.typeOf(Expression.unbox(listHead(args))));
      else
        algorithm
          Error.assertion(false, getInstanceName() + ": unhandled case for " +
            Absyn.pathString(fn.path), sourceInfo());
        then
          fail();
    end match;
  end getSpecialReturnType;
end Call;

annotation(__OpenModelica_Interface="frontend");
end NFCall;
