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
import BindingOrigin = NFBindingOrigin;
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
import NFFunction.MatchedFunction;
import Ceval = NFCeval;
import SimplifyExp = NFSimplifyExp;
import Subscript = NFSubscript;
import Inline = NFInline;

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
  algorithm
    (args, named_args) := instArgs(functionArgs, scope, info);

    callExp := match Absyn.crefFirstIdent(functionName)
      // size creates Expression.SIZE instead of Expression.CALL.
      case "size" then makeSizeExp(args, named_args, info);
      // array() call with no iterators creates Expression.ARRAY instead of Expression.CALL.
      // If it had iterators then it will not reach here. The args would have been parsed to
      // Absyn.FOR_ITER_FARG and that is handled in instIteratorCall.
      case "array" then makeArrayExp(args, named_args, info);
      else algorithm
        (fn_ref, _, _) := Function.instFunc(functionName,scope,info);
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
      fn_ref := Function.instFunc(functionName, scope, info);
      call := UNTYPED_CALL(fn_ref, {Expression.CALL(call)}, {}, scope);
    else
      // Otherwise, make an array call with the original function call as an argument.
      // But only if the original function is not array() itself.
      // e.g. Change myfunc(i for i in ...) TO array(myfunc(i) for i in ...).
      if not is_array then
        fn_ref := Function.instFunc(functionName, scope, info);
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
      case UNTYPED_MAP_CALL() algorithm
        Error.assertion(false, getInstanceName() + " got a map call: " + Call.toString(call), sourceInfo());
      then ();
    end match;
  end builtinSpecialHandling;

  function typeSpecialBuiltinFunction
    input Call call;
    input ExpOrigin.Type origin;
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
      case "String" then typeStringCall(call, origin, info);
      case "branch" then typeBranchCall(call, origin, info);
      case "cardinality" then typeCardinalityCall(call, origin, info);
      case "cat" then typeCatCall(call, origin, info);
      case "change" then typeChangeCall(call, origin, info);
      case "der" then typeDerCall(call, origin, info);
      case "diagonal" then typeDiagonalCall(call, origin, info);
      case "edge" then typeEdgeCall(call, origin, info);
      case "fill" then typeFillCall(call, origin, info);
      case "initial" then typeDiscreteCall(call, origin, info);
      case "isRoot" then typeIsRootCall(call, origin, info);
      case "matrix" then typeMatrixCall(call, origin, info);
      case "max" then typeMinMaxCall(call, origin, info);
      case "min" then typeMinMaxCall(call, origin, info);
      case "ndims" then typeNdimsCall(call, origin, info);
      case "noEvent" then typeNoEventCall(call, origin, info);
      case "ones" then typeZerosOnesCall(call, origin, info);
      case "potentialRoot" then typePotentialRootCall(call, origin, info);
      case "pre" then typePreCall(call, origin, info);
      case "product" then typeSumProductCall(call, origin, info);
      case "root" then typeRootCall(call, origin, info);
      case "rooted" then typeRootedCall(call, origin, info);
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
          Error.assertion(false, getInstanceName() + " got unhandled builtin function: " + Call.toString(call), sourceInfo());
        then
          fail();
    end match;
  end typeSpecialBuiltinFunction;

  public
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
          if(builtinSpecialHandling(callExp.call)) then
            (outExp, ty, var) := typeSpecialBuiltinFunction(callExp.call, origin, info);
          else
            call := typeMatchNormalCall(callExp.call, origin, info);
            ty := getType(call);
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
          ty := getType(call);
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
  algorithm
    (call, ty, variability) := match call
      // This is always a call to the function array()/$array(). See instIteratorCall.
      // Other mapping function calls are already wrapped by array() at this point.
      case UNTYPED_MAP_CALL()
        algorithm
          variability := Variability.CONSTANT;

          for i in call.iters loop
            (iter, range) := i;
            (range, iter_ty, iter_var) := Typing.typeIterator(iter, range, ExpOrigin.FUNCTION, structural = false);
            dims := listAppend(Type.arrayDims(iter_ty), dims);
            variability := Variability.variabilityMax(variability, iter_var);
            iters := (iter, range) :: iters;
          end for;
          iters := listReverseInPlace(iters);

          (arg, ty) := Typing.typeExp(call.exp, origin, info);
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

  function typeNormalCall
    input output Call call;
    input ExpOrigin.Type origin;
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
    String name;
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
    input output Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
  protected
    Function func;
    list<Expression> args;
    CallAttributes ca;
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
    // Don't evaluate structural parameters for external functions, the code generation can't handle it in
    // some cases (see bug #4904). For constants we'll get issues no matter if we evaluate them or not,
    // but evaluating them will probably cause the last amount of issues.
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

    if intBitAnd(origin, ExpOrigin.FUNCTION) == 0 then
      ty := evaluateCallType(ty, func, args);
    end if;

    ca := CallAttributes.CALL_ATTR(
            ty, Type.isTuple(ty), Function.isBuiltin(func)
            , Function.isImpure(func), Function.isFunctionPointer(func)
            , Function.inlineBuiltin(func), DAE.NO_TAIL()
          );

    call := TYPED_CALL(func, ty, var, args, ca);

    // If the matching was a vectorized one then create a map call
    // using the vectorization dim. This means going through each argument
    // and subscipting it with an iterator for each dim and creating a map call.
    if MatchedFunction.isVectorized(matchedFunc) then
      call := vectorizeCall(call, matchedFunc.mk, scope, info);
    end if;

  end matchTypedNormalCall;

  function vectorizeCall
    input Call base_call;
    input FunctionMatchKind mk;
    input InstNode scope;
    input SourceInfo info;
    output Call vectorized_call;
  protected
    Type ty, vect_ty;
    Expression exp;
    Binding bind;
    list<tuple<InstNode, Expression>> iters;
    InstNode iter;
    BindingOrigin origin;
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
            Error.assertion(Dimension.isKnown(dim), getInstanceName() +
              " got unknown dimension for vectorized call", info);

            // Create the range on which we will iterate to vectorize.
            ty := Type.ARRAY(Type.INTEGER(), {dim});
            exp := Expression.RANGE(ty, Expression.INTEGER(1), NONE(), Expression.INTEGER(Dimension.size(dim)));

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
          Dimension.fromExp(exp, dim.var);

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

  function typeArgs
    input output Call call;
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
            (arg, arg_ty, arg_var) := Typing.typeExp(arg, origin, info, replaceConstants = false);
            typedArgs := (arg, arg_ty, arg_var) :: typedArgs;
          end for;

          typedArgs := listReverse(typedArgs);

          typedNamedArgs := {};
          for narg in call.named_args loop
            (name,arg) := narg;
            (arg, arg_ty, arg_var) := Typing.typeExp(arg, origin, info, replaceConstants = false);
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
    matchedFunctions := {};

    _ := match call
      case ARG_TYPED_CALL(ref = ComponentRef.CREF(node = fn_node)) algorithm
        allfuncs := Function.getCachedFuncs(fn_node);
        matchedFunctions := Function.matchFunctions(allfuncs, call.arguments, call.named_args, info);
      then
        ();
    end match;

    if listEmpty(matchedFunctions) then
      // Don't show error messages for overloaded functions, it leaks
      // implementation details and usually doesn't provide any more info than
      // what the "no match found" error gives anyway.
      if listLength(allfuncs) > 1 then
        ErrorExt.rollBack("NFCall:checkMatchingFunctions");
        Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
            {typedString(call), candidateFuncListString(allfuncs)}, info);

      // Only show the error message for no matching functions if no other error
      // was shown.
      // functions that for some reason failed to match without giving any error.
      elseif numerr == Error.getNumErrorMessages() then
        ErrorExt.rollBack("NFCall:checkMatchingFunctions");
        Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
            {typedString(call), candidateFuncListString(allfuncs)}, info);
      else
        ErrorExt.delCheckpoint("NFCall:checkMatchingFunctions");
      end if;

      fail();
    end if;

    // If we have at least one matching function then we discard all error messages
    // about matching. We have one matching func if we reach here.
    ErrorExt.rollBack("NFCall:checkMatchingFunctions");

    if listLength(matchedFunctions) == 1 then
      matchedFunc ::_ := matchedFunctions;

      // Overwrite the actuall function name with the overload name
      // for builtin functions.
      if Function.isBuiltin(matchedFunc.func) then
        func := matchedFunc.func;
        func.path := Function.nameConsiderBuiltin(func);
        matchedFunc.func := func;
      end if;
      return;
    end if;

    if listLength(matchedFunctions) > 1 then
      exactMatches := MatchedFunction.getExactMatches(matchedFunctions);
      if listLength(exactMatches) == 1 then
        matchedFunc ::_ := exactMatches;

        // Overwrite the actuall function name with the overload name
        // for builtin functions.
        if Function.isBuiltin(matchedFunc.func) then
          func := matchedFunc.func;
          func.path := Function.nameConsiderBuiltin(func);
          matchedFunc.func := func;
        end if;
        return;
      else
        matchedFunctions := resolveOverloadedVsDefaultConstructorAmbigutiy(matchedFunctions);
        if listLength(matchedFunctions) == 1 then
          matchedFunc ::_ := matchedFunctions;
          return;
        else
          Error.addSourceMessage(Error.AMBIGUOUS_MATCHING_FUNCTIONS_NFINST,
            {typedString(call), candidateFuncListString(list(mfn.func for mfn in matchedFunctions))}, info);
          fail();
        end if;
      end if;
    end if;

  end checkMatchingFunctions;

  function resolveOverloadedVsDefaultConstructorAmbigutiy
    input list<MatchedFunction> matchedFunctions;
    output list<MatchedFunction> outMatches;
  algorithm
    outMatches := {};
    // We have at least two exact matches. find the default constructor (if there is one) and remove it from the list
    // so that it
    // - doesn't cause ambiguities if there is only one other match left OR
    // - it doesn't appear in the error messages in the case of more than one overloaded constructor matches.
    for mt_fn in matchedFunctions loop
      if not stringEqual(Absyn.pathLastIdent(mt_fn.func.path), "'constructor'.'$default'") then
        outMatches := mt_fn::outMatches;
      end if;
    end for;

    outMatches := listReverse(outMatches);
  end resolveOverloadedVsDefaultConstructorAmbigutiy;

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

  function getType = typeOf;

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

  function makeBuiltinCat
    input Integer n;
    input list<Expression> args;
    input list<Type> tys;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
  protected
    Expression arg2;
    list<Expression> args2 = {}, res = {};
    list<Type> tys2 = tys, tys3;
    list<list<Dimension>> dimsLst = {};
    list<Dimension> dims;
    Type resTy = Type.UNKNOWN(), ty1, ty2, resTyToMatch;
    TypeCheck.MatchKind mk;
    Integer maxn, pos;
    Dimension sumDim;
  algorithm
    Error.assertion(listLength(args)==listLength(tys) and listLength(args)>=1, getInstanceName() + " got wrong input sizes", sourceInfo());

    // First: Get the number of dimensions and the element type

    for arg in args loop
      ty::tys2 := tys2;
      dimsLst := Type.arrayDims(ty) :: dimsLst;
      if Type.isEqual(resTy, Type.UNKNOWN()) then
        resTy := Type.arrayElementType(ty);
      else
        (,, ty1, mk) := TypeCheck.matchExpressions(Expression.INTEGER(0), Type.arrayElementType(ty), Expression.INTEGER(0), resTy);
        if TypeCheck.isCompatibleMatch(mk) then
          resTy := ty1;
        end if;
      end if;
    end for;

    maxn := max(listLength(d) for d in dimsLst);
    if maxn <> min(listLength(d) for d in dimsLst) then
      Error.addSourceMessageAndFail(Error.NF_DIFFERENT_NUM_DIM_IN_ARGUMENTS, {stringDelimitList(list(String(listLength(d)) for d in dimsLst), ", "), "cat"}, info);
    end if;
    if n < 1 or n > maxn then
      Error.addSourceMessageAndFail(Error.NF_CAT_WRONG_DIMENSION, {String(maxn), String(n)}, info);
    end if;

    tys2 := tys;
    tys3 := {};
    args2 := {};
    pos := listLength(args)+2;

    // Second: Try to match the element type of all the arguments

    for arg in args loop
      ty::tys2 := tys2;
      pos := pos-1;
      ty2 := Type.setArrayElementType(ty, resTy);
      (arg2, ty1, mk) := TypeCheck.matchTypes(ty, ty2, arg, allowUnknown = true);
      if TypeCheck.isIncompatibleMatch(mk) then
        Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH, {String(pos), "cat", "arg", Expression.toString(arg), Type.toString(ty), Type.toString(ty2)}, info);
      end if;
      args2 := arg2 :: args2;
      tys3 := ty1 :: tys3;
    end for;

    // Third: We now have matched the element types of all arguments
    //        Try to match the dimensions as well

    resTy := Type.UNKNOWN();
    tys2 := tys3;

    for arg in args2 loop
      ty::tys2 := tys2;

      if Type.isEqual(resTy, Type.UNKNOWN()) then
        resTy := ty;
      else
        (,, ty1, mk) := TypeCheck.matchExpressions(Expression.INTEGER(0), ty, Expression.INTEGER(0), resTy);
        if TypeCheck.isCompatibleMatch(mk) then
          resTy := ty1;
        end if;
      end if;
    end for;

    // Got the supertype of the dimensions; trying to match all arguments
    // with the concatenated dimension set to unknown.

    dims := Type.arrayDims(resTy);
    resTyToMatch := Type.ARRAY(Type.arrayElementType(resTy), List.set(dims, n, Dimension.UNKNOWN()));
    dims := list(listGet(lst, n) for lst in dimsLst);
    sumDim := Dimension.fromInteger(0);
    for d in dims loop
      // Create the concatenated dimension
      sumDim := Dimension.add(sumDim, d);
    end for;
    resTy := Type.ARRAY(Type.arrayElementType(resTy), List.set(Type.arrayDims(resTy), n, sumDim));
    tys2 := tys3;
    tys3 := {};
    res := {};
    pos := listLength(args)+2;

    for arg in args2 loop
      ty::tys2 := tys2;
      pos := pos-1;
      (arg2, ty1, mk) := TypeCheck.matchTypes(ty, resTyToMatch, arg, allowUnknown=true);
      if TypeCheck.isIncompatibleMatch(mk) then
        Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH, {String(pos), "cat", "arg", Expression.toString(arg), Type.toString(ty), Type.toString(resTyToMatch)}, info);
      end if;
      res := arg2 :: res;
      tys3 := ty1 :: tys3;
    end for;

    // We have all except dimension n having equal sizes; with matching types

    ty := resTy;
    callExp := Expression.CALL(makeBuiltinCall2(NFBuiltinFuncs.CAT, Expression.INTEGER(n)::res, resTy));
  end makeBuiltinCat;

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
          DAE.REDUCTIONINFO(Function.name(NFBuiltinFuncs.ARRAY_FUNC), Absyn.COMBINE(), Type.toDAE(call.ty), NONE(), String(Util.getTempVariableIndex()), String(Util.getTempVariableIndex()), NONE()),
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

  function makeSizeExp
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
            {"size" + List.toString(posArgs, Expression.toString, "", "(", ", ", ")", true),
             "size(Any[:, ...]) => Integer[:]\n  size(Any[:, ...], Integer) => Integer"}, info);
        then
          fail();
    end match;
  end makeSizeExp;

  function makeArrayExp
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
      for arg in namedArgs loop
        Error.addSourceMessage(Error.NO_SUCH_PARAMETER,
          {"array", Util.tuple21(arg)}, info);
      end for;
      fail();
    end if;

    // array can take any number of arguments, but needs at least one.
    if listEmpty(posArgs) then
      Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {"array" + List.toString(posArgs, Expression.toString, "", "(", ", ", ")", true),
         "array(Any, Any, ...) => Any[:]"}, info);
      fail();
    end if;

    arrayExp := Expression.ARRAY(Type.UNKNOWN(), posArgs);
  end makeArrayExp;

  function makeBuiltinCall
    "Creates a call to a builtin function, given a Function and a list of
     argument expressions."
    input Function func;
    input list<Expression> args;
    input Variability var = Variability.CONSTANT;
    output Call call;
  algorithm
    call := TYPED_CALL(func, func.returnType, var, args,
      CallAttributes.CALL_ATTR(func.returnType, false, true, false, false,
        DAE.NO_INLINE(), DAE.NO_TAIL()));
  end makeBuiltinCall;

  function makeBuiltinCall2
    "Creates a call to a builtin function, given a Function, list of
     argument expressions and a return type. Used for builtin functions defined with no return type."
    input Function func;
    input list<Expression> args;
    input Type returnType;  // you can use func.returnType if the buiting function is defined with the corrrect type.
    input Variability var = Variability.CONSTANT; // :( We don't have variability info in the arg expressions.
    output Call call;
  algorithm
    call := TYPED_CALL(func, returnType, var, args,
      CallAttributes.CALL_ATTR(returnType, false, true, false, false,
        DAE.NO_INLINE(), DAE.NO_TAIL()));
  end makeBuiltinCall2;

  function typeStringCall
    input Call inCall;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type outType;
    output Variability var;
  protected
    Call call;
    Function operfn;
    list<TypedArg> args;
    list<TypedNamedArg> named_args;
    Type argty;
    Expression exp;
    ComponentRef fn_ref;
    list<Function> candidates;
    Boolean matched;
    InstNode recopnode;
    FunctionMatchKind matchKind;
    MatchedFunction matchedFunc;
    list<MatchedFunction> matchedFunctions, exactMatches;
  algorithm
    call as ARG_TYPED_CALL(_, args, named_args) := typeNormalCall(inCall, origin, info);
    (exp, argty, _)::_ := args;

    if Type.isComplex(Type.arrayElementType(argty)) then
      Type.COMPLEX(cls=recopnode) := argty;

      // This will fail if it can't find the function.
      fn_ref := Function.lookupFunctionSimple("'String'", recopnode);
      fn_ref := Function.instFuncRef(fn_ref, InstNode.info(recopnode));
      candidates := Call.typeCachedFunctions(fn_ref);
      for fn in candidates loop
        TypeCheck.checkValidOperatorOverload("'String'", fn, recopnode);
      end for;

      matchedFunctions := Function.matchFunctionsSilent(candidates, args, named_args, info);
      exactMatches := MatchedFunction.getExactMatches(matchedFunctions);
      if listEmpty(exactMatches) then
        Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
          {typedString(call), candidateFuncListString(candidates)}, info);
        fail();
      end if;

      if listLength(exactMatches) == 1 then
        matchedFunc ::_ := exactMatches;
        outType := Function.returnType(matchedFunc.func);
        callExp := Expression.CALL(Call.TYPED_CALL(matchedFunc.func, outType, Variability.CONSTANT, list(Util.tuple31(a) for a in matchedFunc.args)
                                                  , CallAttributes.CALL_ATTR(
                                                      outType, false, false, false, false, DAE.NO_INLINE(),DAE.NO_TAIL())
                                                  )
                                  );

        return;
      else
        Error.addSourceMessage(Error.AMBIGUOUS_MATCHING_FUNCTIONS_NFINST,
          {typedString(call), candidateFuncListString(list(mfn.func for mfn in matchedFunctions))}, info);
        fail();
      end if;

    end if;

    call := matchTypedNormalCall(call, origin, info);
    outType := getType(call);
    var := variability(call);
    callExp := Expression.CALL(call);
  end typeStringCall;

protected
  function typeDiscreteCall
    "Types a function call that can be typed normally, but which always has
     discrete variability regardless of the variability of the arguments."
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.DISCRETE;
  protected
    Call argtycall;
    Function fn;
    list<TypedArg> args;
    TypedArg start,interval;
  algorithm
    argtycall := typeMatchNormalCall(call, origin, info);
    ty := getType(argtycall);
    callExp := Expression.CALL(unboxArgs(argtycall));
  end typeDiscreteCall;

  function typeNdimsCall
    input Call call;
    input ExpOrigin.Type origin;
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
        {toString(call), "ndims(Any) => Integer"}, info);
      fail();
    end if;

    // The number of dimensions an expression has is always known,
    // so we might as well evaluate the ndims call here.
    (_, arg_ty, _) := Typing.typeExp(listHead(args), origin, info);
    callExp := Expression.INTEGER(Type.dimensionCount(arg_ty));
  end typeNdimsCall;

  function typePreCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability = Variability.DISCRETE;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Variability var;
    Function fn;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {ComponentRef.toString(fn_ref), Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), ComponentRef.toString(fn_ref) + "(Any) => Any"}, info);
    end if;

    // pre/change may not be used in a function context.
    if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty, var) := Typing.typeExp(listHead(args), origin, info);

    if not Expression.isCref(arg) then
      Error.addSourceMessage(Error.ARGUMENT_MUST_BE_VARIABLE,
            {"First", ComponentRef.toString(fn_ref), "<REMOVE ME>"}, info);
      fail();
    end if;

    if var == Variability.CONTINUOUS then
      Error.addSourceMessageAndFail(Error.INVALID_ARGUMENT_VARIABILITY,
        {"1", ComponentRef.toString(fn_ref), Prefixes.variabilityString(Variability.DISCRETE),
         Expression.toString(arg), Prefixes.variabilityString(var)}, info);
    end if;

    {fn} := typeCachedFunctions(fn_ref);
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg}, ty, var));
  end typePreCall;

  function typeChangeCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability = Variability.DISCRETE;
  algorithm
    (callExp, ty, variability) := typePreCall(call, origin, info);
    ty := Type.setArrayElementType(ty, Type.BOOLEAN());
  end typeChangeCall;

  function typeDerCall
    input Call call;
    input ExpOrigin.Type origin;
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
    Type ety;
  algorithm
    // der may not be used in a function context.
    if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
      Error.addSourceMessage(Error.EXP_INVALID_IN_FUNCTION, {"der"}, info);
      fail();
    end if;

    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {"der", Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), "der(Real) => Real"}, info);
    end if;

    {arg} := args;
    (arg, ty, variability) := Typing.typeExp(arg, origin, info);

    ety := Type.arrayElementType(ty);

    if Type.isInteger(ety) then
      ty := Type.setArrayElementType(ty, Type.REAL());
      arg := Expression.typeCastElements(arg, Type.REAL());
    elseif not Type.isReal(ety) then
      Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
        {"1", ComponentRef.toString(fn_ref), "", Expression.toString(arg),
         Type.toString(ty), "Real"}, info);
    end if;

    {fn} := typeCachedFunctions(fn_ref);
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg}, ty, variability));
  end typeDerCall;

  function typeDiagonalCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Dimension dim;
    Function fn;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {"diagonal", Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), "diagonal(Any[n]) => Any[n, n]"}, info);
    end if;

    (arg, ty, variability) := Typing.typeExp(listHead(args), origin, info);

    ty := match ty
      case Type.ARRAY(dimensions = {dim})
        then Type.ARRAY(ty.elementType, {dim, dim});

      else
        algorithm
          Error.addSourceMessage(Error.ARG_TYPE_MISMATCH,
            {"1", ComponentRef.toString(fn_ref), "", Expression.toString(arg),
             Type.toString(ty), "Any[:]"}, info);
        then
          fail();
    end match;

    {fn} := typeCachedFunctions(fn_ref);
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg}, ty, variability));
  end typeDiagonalCall;

  function typeEdgeCall
    input Call call;
    input ExpOrigin.Type origin;
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
      fail();
    end if;

    argtycall as ARG_TYPED_CALL(ComponentRef.CREF(node = fn_node), args, _) := typeNormalCall(call, origin, info);
    argtycall := matchTypedNormalCall(argtycall, origin, info);
    ty := getType(argtycall);
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
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var;
  protected
    Call argtycall;
  algorithm
    argtycall := typeMatchNormalCall(call, origin, info);
    argtycall := unboxArgs(argtycall);
    ty := getType(argtycall);
    var := variability(argtycall);
    callExp := Expression.CALL(argtycall);
    // TODO: check basic type in two argument overload.
    // check arrays of simple types in one argument overload.
    // fix return type.
  end typeMinMaxCall;

  function typeSumProductCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var;
  protected
    Call argtycall;
  algorithm
    // TODO: Rewrite this whole thing.
    argtycall := typeMatchNormalCall(call, origin, info);
    argtycall := unboxArgs(argtycall);
    ty := getType(argtycall);
    var := variability(argtycall);
    callExp := Expression.CALL(argtycall);
  end typeSumProductCall;

  function typeSmoothCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg1, arg2;
    Type ty1, ty2;
    Variability var;
    Function fn;
    TypeCheck.MatchKind mk;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    // smooth doesn't have any named parameters.
    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {"smooth", Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) <> 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), "smooth(Integer, Any) => Any"}, info);
    end if;

    {arg1, arg2} := args;
    (arg1, ty1, var) := Typing.typeExp(arg1, origin, info);
    (arg2, ty2, variability) := Typing.typeExp(arg2, origin, info);

    // First argument must be Integer.
    if not Type.isInteger(ty1) then
      Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
        {"1", ComponentRef.toString(fn_ref), "", Expression.toString(arg1),
         Type.toString(ty1), "Integer"}, info);
    end if;

    // First argument must be a parameter expression.
    if var > Variability.PARAMETER then
      Error.addSourceMessageAndFail(Error.INVALID_ARGUMENT_VARIABILITY,
        {"1", ComponentRef.toString(fn_ref), Prefixes.variabilityString(Variability.PARAMETER),
         Expression.toString(arg1), Prefixes.variabilityString(variability)}, info);
    end if;

    // Second argument must be Real, array of allowed expressions or record
    // containing only components of allowed expressions.
    // TODO: Also handle records here.
    (arg2, ty, mk) := TypeCheck.matchTypes(ty2, Type.setArrayElementType(ty2, Type.REAL()), arg2, true);

    if not TypeCheck.isValidArgumentMatch(mk) then
      Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
        {"2", ComponentRef.toString(fn_ref), "", Expression.toString(arg2),
         Type.toString(ty2), "Real\n  Real[:, ...]\n  Real record\n  Real record[:, ...]"}, info);
    end if;

    {fn} := typeCachedFunctions(fn_ref);
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg1, arg2}, ty, var));
  end typeSmoothCall;

  function typeFillCall
    input Call call;
    input ExpOrigin.Type origin;
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
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), "fill(Any, Integer, ...) => Any[:, ...]"}, info);
    end if;

    fill_arg :: args := args;

    // Type the first argument, which is the fill value.
    (fill_arg, ty, _) := Typing.typeExp(fill_arg, origin, info);
    (callExp, ty, variability) := typeFillCall2(fn_ref, ty, fill_arg, args, origin, info);
  end typeFillCall;

  function typeFillCall2
    input ComponentRef fnRef;
    input Type fillType;
    input Expression fillArg;
    input list<Expression> dimensionArgs;
    input ExpOrigin.Type origin;
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
    ty_args := {fillArg};
    dims := {};

    // Type the dimension arguments.
    for arg in dimensionArgs loop
      (arg, arg_ty, arg_var) := Typing.typeExp(arg, origin, info);

      if arg_var <= Variability.STRUCTURAL_PARAMETER then
        arg := Ceval.evalExp(arg);
        arg_ty := Expression.typeOf(arg);
      end if;

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
    ty := Type.liftArrayLeftList(fillType, dims);

    if variability <= Variability.STRUCTURAL_PARAMETER and intBitAnd(origin, ExpOrigin.FUNCTION) == 0 then
      callExp := Ceval.evalBuiltinFill(ty_args);
    else
      callExp := Expression.CALL(makeBuiltinCall2(NFBuiltinFuncs.FILL_FUNC, ty_args, ty, variability));
    end if;
  end typeFillCall2;

  function typeZerosOnesCall
    input Call call;
    input ExpOrigin.Type origin;
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

    // zeros/ones doesn't have any named parameters.
    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {ComponentRef.toString(fn_ref), Util.tuple21(listHead(named_args))}, info);
    end if;

    // zeros/ones can take any number of arguments, but needs at least one.
    if listEmpty(args) then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), ComponentRef.toString(fn_ref) + "(Integer, ...) => Integer[:, ...]"}, info);
    end if;

    if ComponentRef.firstName(fn_ref) == "ones" then
      fill_arg := Expression.INTEGER(1);
    else
      fill_arg := Expression.INTEGER(0);
    end if;

    (callExp, ty, variability) := typeFillCall2(fn_ref, Type.INTEGER(), fill_arg, args, origin, info);
  end typeZerosOnesCall;

  function typeScalarCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Variability var;
    Function fn;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {ComponentRef.toString(fn_ref), Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), "scalar(Any[1, ...]) => Any"}, info);
    end if;

    (arg, ty, variability) := Typing.typeExp(listHead(args), origin, info);

    // scalar requires all dimensions of the array to be 1.
    for dim in Type.arrayDims(ty) loop
      if Dimension.isKnown(dim) and not Dimension.size(dim) == 1 then
        Error.addSourceMessageAndFail(Error.INVALID_ARRAY_DIM_IN_SCALAR_OP,
          {Type.toString(ty)}, info);
      end if;
    end for;

    ty := Type.arrayElementType(ty);
    {fn} := typeCachedFunctions(fn_ref);
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg}, ty, variability));
  end typeScalarCall;

  function typeVectorCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Variability var;
    Function fn;
    Integer dim_size = -1, i = 1;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {ComponentRef.toString(fn_ref), Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), "vector(Any) => Any[:]\n  vector(Any[:, ...]) => Any[:]"}, info);
    end if;

    (arg, ty, variability) := Typing.typeExp(listHead(args), origin, info);

    // vector requires that at most one dimension is > 1, and that dimension
    // determines the type of the vector call.
    for dim in Type.arrayDims(ty) loop
      if Dimension.isKnown(dim) then
        if Dimension.size(dim) > 1 then
          if dim_size == -1 then
            dim_size := Dimension.size(dim);
          else
            Error.addSourceMessageAndFail(Error.NF_VECTOR_INVALID_DIMENSIONS,
              {Type.toString(ty), toString(call)}, info);
          end if;
        end if;
      end if;

      i := i + 1;
    end for;

    // If the argument was scalar or an array where all dimensions where 1, set
    // the dimension size to 1.
    if dim_size == -1 then
      dim_size := 1;
    end if;

    ty := Type.ARRAY(Type.arrayElementType(ty), {Dimension.fromInteger(dim_size)});
    {fn} := typeCachedFunctions(fn_ref);
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg}, ty, variability));
  end typeVectorCall;

  function typeMatrixCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Variability var;
    Function fn;
    list<Dimension> dims;
    Dimension dim1, dim2;
    Integer i;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {ComponentRef.toString(fn_ref), Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), "vector(Any) => Any[:]\n  vector(Any[:, ...]) => Any[:]"}, info);
    end if;

    (arg, ty, variability) := Typing.typeExp(listHead(args), origin, info);
    dims := Type.arrayDims(ty);

    dims := match listLength(dims)
      case 0 then {Dimension.fromInteger(1), Dimension.fromInteger(1)};
      case 1 then {listHead(dims), Dimension.fromInteger(1)};
      case 2 then dims;
      else
        algorithm
          // matrix requires all but the first two dimensions to have size 1.
          dim1 :: dim2 :: dims := dims;
          i := 3;

          for dim in dims loop
            if Dimension.isKnown(dim) and Dimension.size(dim) > 1 then
              Error.addSourceMessageAndFail(Error.INVALID_ARRAY_DIM_IN_CONVERSION_OP,
                {String(i), "matrix", "1", Dimension.toString(dim)}, info);
            end if;

            i := i + 1;
          end for;
        then
          {dim1, dim2};
    end match;

    ty := Type.ARRAY(Type.arrayElementType(ty), dims);
    {fn} := typeCachedFunctions(fn_ref);
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg}, ty, variability));
  end typeMatrixCall;

  function typeCatCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    ComponentRef fn_ref;
    list<Expression> args, res;
    list<NamedArg> named_args;
    list<Type> tys;
    Expression arg;
    Variability var;
    TypeCheck.MatchKind mk;
    Function fn;
    Integer n;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {ComponentRef.toString(fn_ref), Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) < 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), "cat(Integer, Any[:,:], ...) => Any[:]"}, info);
    end if;

    arg::args := args;

    (arg, ty, variability) := Typing.typeExp(arg, origin, info);
    (arg, ty, mk) := TypeCheck.matchTypes(ty, Type.INTEGER(), arg);

    if variability > Variability.PARAMETER then
      Error.addSourceMessageAndFail(Error.NF_CAT_FIRST_ARG_EVAL, {Expression.toString(arg), Prefixes.variabilityString(variability)}, info);
    end if;
    Expression.INTEGER(n) := Ceval.evalExp(arg, Ceval.EvalTarget.GENERIC(info));

    res := {};
    tys := {};

    for a in args loop
      (arg, ty, var) := Typing.typeExp(a, origin, info);
      variability := Prefixes.variabilityMax(var, variability);
      res := arg :: res;
      tys := ty :: tys;
    end for;

    (callExp, ty) := makeBuiltinCat(n, listReverse(res), listReverse(tys), info);

  end typeCatCall;

  function typeSymmetricCall
    input Call call;
    input ExpOrigin.Type origin;
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

    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {"symmetric", Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), "symmetric(Any[n, m]) => Any[n, m]"}, info);
    end if;

    (arg, ty, variability) := Typing.typeExp(listHead(args), origin, info);

    if not Type.isMatrix(ty) then
      Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
        {"1", ComponentRef.toString(fn_ref), "", Expression.toString(arg),
         Type.toString(ty), "Any[:, :]"}, info);
    end if;

    {fn} := typeCachedFunctions(fn_ref);
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg}, ty, variability));
  end typeSymmetricCall;

  function typeTransposeCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Dimension dim1, dim2;
    list<Dimension> rest_dims;
    Function fn;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {"transpose", Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), "transpose(Any[n, m, ...]) => Any[m, n, ...]"}, info);
    end if;

    (arg, ty, variability) := Typing.typeExp(listHead(args), origin, info);

    ty := match ty
      case Type.ARRAY(dimensions = dim1 :: dim2 :: rest_dims)
        then Type.ARRAY(ty.elementType, dim2 :: dim1 :: rest_dims);

      else
        algorithm
          Error.addSourceMessage(Error.ARG_TYPE_MISMATCH,
            {"1", ComponentRef.toString(fn_ref), "", Expression.toString(arg),
             Type.toString(ty), "Any[:, :, ...]"}, info);
        then
          fail();
    end match;

    {fn} := typeCachedFunctions(fn_ref);
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg}, ty, variability));
  end typeTransposeCall;

  function typeCardinalityCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.PARAMETER;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {ComponentRef.toString(fn_ref), Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), ComponentRef.toString(fn_ref) + "(Connector) => Integer"}, info);
    end if;

    if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty) := Typing.typeExp(listHead(args), origin, info);

    if not Expression.isCref(arg) then
      Error.addSourceMessageAndFail(Error.ARGUMENT_MUST_BE_VARIABLE,
        {"First", ComponentRef.toString(fn_ref), "<REMOVE ME>"}, info);
    end if;

    if not Type.isConnector(ty) then
      Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
        {"1", ComponentRef.toString(fn_ref), "",
         Expression.toString(arg), Type.toString(ty), "connector"}, info);
    end if;

    {fn} := typeCachedFunctions(fn_ref);
    ty := Type.INTEGER();
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg}, ty, var));
    // TODO: Check cardinality restrictions, 3.7.2.3.
  end typeCardinalityCall;

  function typeBranchCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.PARAMETER;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg1, arg2;
    Function fn;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {ComponentRef.toString(fn_ref), Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) <> 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), ComponentRef.toString(fn_ref) + "(Connector, Connector)"}, info);
    end if;

    if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    {arg1, arg2} := args;

    (arg1, ty) := Typing.typeExp(arg1, origin, info);
    checkConnectionsArgument(arg1, ty, fn_ref, 1, info);
    (arg2, ty) := Typing.typeExp(arg2, origin, info);
    checkConnectionsArgument(arg2, ty, fn_ref, 2, info);

    {fn} := typeCachedFunctions(fn_ref);
    ty := Type.NORETCALL();
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg1, arg2}, ty, var));
  end typeBranchCall;

  function typeIsRootCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.PARAMETER;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {ComponentRef.toString(fn_ref), Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), ComponentRef.toString(fn_ref) + "(Connector)"}, info);
    end if;

    if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty) := Typing.typeExp(listHead(args), origin, info);
    checkConnectionsArgument(arg, ty, fn_ref, 1, info);

    {fn} := typeCachedFunctions(fn_ref);
    ty := Type.BOOLEAN();
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg}, ty, var));
  end typeIsRootCall;

  function typePotentialRootCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.PARAMETER;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg1, arg2;
    Function fn;
    Integer args_len;
    String name;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    for narg in named_args loop
      (name, arg2) := narg;

      if name == "priority" then
        args := listAppend(args, {arg2});
      else
        Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
          {ComponentRef.toString(fn_ref), name}, info);
      end if;
    end for;

    args_len := listLength(args);
    if args_len < 1 or args_len > 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), ComponentRef.toString(fn_ref) + "(Connector, Integer = 0)"}, info);
    end if;

    if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    arg1 :: args := args;

    (arg1, ty) := Typing.typeExp(arg1, origin, info);
    checkConnectionsArgument(arg1, ty, fn_ref, 1, info);

    if args_len == 2 then
      arg2 := listHead(args);
      (arg2, ty) := Typing.typeExp(arg2, origin, info);

      if not Type.isInteger(ty) then
        Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
          {"2", ComponentRef.toString(fn_ref), "", Expression.toString(arg2),
           Type.toString(ty), "Integer"}, info);
      end if;
    else
      arg2 := Expression.INTEGER(0);
    end if;

    {fn} := typeCachedFunctions(fn_ref);
    ty := Type.NORETCALL();
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg1, arg2}, ty, var));
  end typePotentialRootCall;

  function typeRootCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.PARAMETER;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {ComponentRef.toString(fn_ref), Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), ComponentRef.toString(fn_ref) + "(Connector)"}, info);
    end if;

    if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty) := Typing.typeExp(listHead(args), origin, info);
    checkConnectionsArgument(arg, ty, fn_ref, 1, info);

    {fn} := typeCachedFunctions(fn_ref);
    ty := Type.NORETCALL();
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg}, ty, var));
  end typeRootCall;

  function typeRootedCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.PARAMETER;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
  algorithm
    UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    if not listEmpty(named_args) then
      Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
        {ComponentRef.toString(fn_ref), Util.tuple21(listHead(named_args))}, info);
    end if;

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), ComponentRef.toString(fn_ref) + "(Connector)"}, info);
    end if;

    if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty) := Typing.typeExp(listHead(args), origin, info);
    checkConnectionsArgument(arg, ty, fn_ref, 1, info);

    {fn} := typeCachedFunctions(fn_ref);
    ty := Type.BOOLEAN();
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg}, ty, var));
  end typeRootedCall;

  function checkConnectionsArgument
    input Expression arg;
    input Type ty;
    input ComponentRef fnRef;
    input Integer argIndex;
    input SourceInfo info;
  algorithm
    () := match arg
      local
        Type ty2;
        InstNode node;
        Boolean valid_cref;
        ComponentRef rest_cref;

      case Expression.CREF()
        algorithm
          valid_cref := match arg.cref
            case ComponentRef.CREF(node = node, origin = NFComponentRef.Origin.CREF,
                restCref = ComponentRef.CREF(ty = ty2, origin = NFComponentRef.Origin.CREF,
                restCref = rest_cref))
              then Class.isOverdetermined(InstNode.getClass(node)) and
                   Type.isConnector(ty2) and
                   not ComponentRef.isFromCref(rest_cref);

            else false;
          end match;

          if not valid_cref then
            Error.addSourceMessageAndFail(
              if argIndex == 1 then Error.INVALID_ARGUMENT_TYPE_BRANCH_FIRST else
                                    Error.INVALID_ARGUMENT_TYPE_BRANCH_SECOND,
              {ComponentRef.toString(fnRef)}, info);
          end if;
        then
          ();

      else
        algorithm
          Error.addSourceMessage(Error.ARG_TYPE_MISMATCH,
            {String(argIndex), ComponentRef.toString(fnRef), "",
             Expression.toString(arg), Type.toString(ty), "overconstrained type/record"}, info);
        then
          fail();
    end match;
  end checkConnectionsArgument;

  function typeNoEventCall
    input Call call;
    input ExpOrigin.Type origin;
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
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {toString(call), "noEvent(Any) => Any"}, info);
    end if;

    {arg} := args;
    (arg, ty, variability) := Typing.typeExp(arg, intBitOr(origin, ExpOrigin.NOEVENT), info);

    {fn} := typeCachedFunctions(fn_ref);
    callExp := Expression.CALL(makeBuiltinCall2(fn, {arg}, ty, variability));
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

  public
  function candidateFuncListString
    input list<Function> fns;
    output String s = stringDelimitList(list(Function.signatureString(fn, true) for fn in fns), "\n  ");
  end candidateFuncListString;

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

  function toRecordExpression
    input Call call;
    input Type ty;
    output Expression exp;
  algorithm
    exp := match call
      case TYPED_CALL()
        then Expression.RECORD(Absyn.stripLast(Function.name(call.fn)), ty, call.arguments);
    end match;
  end toRecordExpression;

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
end Call;

annotation(__OpenModelica_Interface="frontend");
end NFCall;
