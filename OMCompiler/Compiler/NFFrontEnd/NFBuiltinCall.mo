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

encapsulated package NFBuiltinCall
  import Absyn;
  import AbsynUtil;
  import Call = NFCall;
  import NFCallAttributes;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import NFPrefixes.{Variability, Purity};
  import Type = NFType;
  import Subscript = NFSubscript;
  import System;

protected
  import Config;
  import Ceval = NFCeval;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import List;
  import MetaModelica.Dangerous.listReverseInPlace;
  import Class = NFClass;
  import NFFunction.Function;
  import NFFunction.FunctionMatchKind;
  import NFFunction.MatchedFunction;
  import NFFunction.NamedArg;
  import NFFunction.TypedArg;
  import NFInstNode.CachedData;
  import NFTyping.InstContext;
  import Prefixes = NFPrefixes;
  import TypeCheck = NFTypeCheck;
  import Typing = NFTyping;
  import Util;
  import ExpandExp = NFExpandExp;
  import Operator = NFOperator;
  import Component = NFComponent;
  import NFPrefixes.ConnectorType;
  import ClockKind = NFClockKind;
  import Structural = NFStructural;

public
  function needSpecialHandling
    input Call call;
    output Boolean special;
  algorithm
    () := match call
      case Call.UNTYPED_CALL()
        algorithm
          CachedData.FUNCTION(specialBuiltin = special) :=
            InstNode.getFuncCache(InstNode.classScope(ComponentRef.node(call.ref)));
        then
          ();

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown call: " +
            Call.toString(call), sourceInfo());
        then
          fail();
    end match;
  end needSpecialHandling;

  function typeSpecial
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity;
  protected
    ComponentRef cref;
    InstNode fn_node;
    Expression first;
    list<Expression> rest;
    String name;
    InstContext.Type next_context;
  algorithm
    Call.UNTYPED_CALL(ref = cref) := call;
    next_context := InstContext.set(context, NFInstContext.SUBEXPRESSION);

    (callExp, ty, variability, purity) := match ComponentRef.firstName(cref)
      //case "activeState" then typeActiveStateCall(call, next_context, info);
      case "actualStream" then typeActualInStreamCall("actualStream", call, next_context, info);
      case "backSample" then typeBackSampleCall(call, next_context, info);
      case "branch" then typeBranchCall(call, next_context, info);
      case "cardinality" then typeCardinalityCall(call, next_context, info);
      case "cat" then typeCatCall(call, next_context, info);
      case "change" then typeChangeCall(call, next_context, info);
      case "Clock" then typeClockCall(call, next_context, info);
      case "der" then typeDerCall(call, next_context, info);
      case "DynamicSelect" then typeDynamicSelectCall("DynamicSelect", call, next_context, info);
      case "edge" then typeEdgeCall(call, next_context, info);
      case "fill" then typeFillCall(call, next_context, info);
      case "getInstanceName" then typeGetInstanceName(call);
      //case "initialState" then typeInitialStateCall(call, next_context, info);
      case "initial" then typeDiscreteCall(call, next_context, info);
      case "inStream" then typeActualInStreamCall("inStream", call, next_context, info);
      case "isRoot" then typeIsRootCall(call, next_context, info);
      case "matrix" then typeMatrixCall(call, next_context, info);
      case "max" then typeMinMaxCall("max", call, next_context, info);
      case "min" then typeMinMaxCall("min", call, next_context, info);
      case "ndims" then typeNdimsCall(call, next_context, info);
      case "noEvent" then typeNoEventCall(call, next_context, info);
      case "ones" then typeZerosOnesCall("ones", call, next_context, info);
      case "potentialRoot" then typePotentialRootCall(call, next_context, info);
      case "pre" then typePreCall(call, next_context, info);
      case "product" then typeProductCall(call, next_context, info);
      case "promote" then typePromoteCall(call, next_context, info);
      case "pure" then typePureCall(call, next_context, info);
      case "rooted" then typeRootedCall(call, next_context, info);
      case "root" then typeRootCall(call, next_context, info);
      case "sample" then typeSampleCall(call, next_context, info);
      case "scalar" then typeScalarCall(call, next_context, info);
      case "shiftSample" then typeShiftSampleCall(call, next_context, info);
      case "smooth" then typeSmoothCall(call, next_context, info);
      case "String" then typeStringCall(call, next_context, info);
      case "subSample" then typeSubSampleCall(call, next_context, info);
      case "sum" then typeSumCall(call, next_context, info);
      case "superSample" then typeSuperSampleCall(call, next_context, info);
      case "symmetric" then typeSymmetricCall(call, next_context, info);
      case "terminal" then typeDiscreteCall(call, next_context, info);
      //case "ticksInState" then typeTicksInStateCall(call, next_context, info);
      //case "timeInState" then typeTimeInStateCall(call, next_context, info);
      //case "transition" then typeTransitionCall(call, next_context, info);
      case "transpose" then typeTransposeCall(call, next_context, info);
      case "uniqueRootIndices" then typeUniqueRootIndicesCall(call, next_context, info);
      case "uniqueRoot" then typeUniqueRootCall(call, next_context, info);
      case "vector" then typeVectorCall(call, next_context, info);
      case "zeros" then typeZerosOnesCall("zeros", call, next_context, info);
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unhandled builtin function: " + Call.toString(call), sourceInfo());
        then
          fail();
    end match;
  end typeSpecial;

  function makeSizeExp
    input list<Expression> posArgs;
    input list<NamedArg> namedArgs;
    input SourceInfo info;
    output Expression callExp;
  protected
    Integer argc = listLength(posArgs);
    Expression arg1, arg2;
  algorithm
    assertNoNamedParams("size", namedArgs, info);

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
    assertNoNamedParams("array", namedArgs, info);

    // array can take any number of arguments, but needs at least one.
    if listEmpty(posArgs) then
      Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {"array" + List.toString(posArgs, Expression.toString, "", "(", ", ", ")", true),
         "array(Any, Any, ...) => Any[:]"}, info);
      fail();
    end if;

    arrayExp := Expression.makeArray(Type.UNKNOWN(), posArgs);
  end makeArrayExp;

  function makeCatExp
    input Integer n;
    input list<Expression> args;
    input list<Type> tys;
    input Variability variability;
    input Purity purity;
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
    callExp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.CAT,
      Expression.INTEGER(n)::res, variability, purity, resTy));
  end makeCatExp;

protected
  function assertNoNamedParams
    input String fnName;
    input list<NamedArg> namedArgs;
    input SourceInfo info;
  algorithm
    if not listEmpty(namedArgs) then
      Error.addSourceMessage(Error.NO_SUCH_PARAMETER,
        {fnName, Util.tuple21(listHead(namedArgs))}, info);
      fail();
    end if;
  end assertNoNamedParams;

  function typeStringCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type outType;
    output Variability var;
    output Purity purity;
  protected
    Type arg_ty;
    list<TypedArg> args;
    list<TypedArg> named_args;
    TypedArg arg;
    Call ty_call;
  algorithm
    ty_call as Call.ARG_TYPED_CALL(_, args, named_args) := Call.typeNormalCall(call, context, info);
    arg := listHead(args);
    arg_ty := Type.arrayElementType(arg.ty);

    if Type.isComplex(arg_ty) then
      (callExp, outType, var, purity) := typeOverloadedStringCall(arg_ty, args, named_args, ty_call, context, info);
    else
      (callExp, outType, var, purity) := typeBuiltinStringCall(ty_call, context, info);
    end if;
  end typeStringCall;

  function typeBuiltinStringCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var;
    output Purity purity;
  protected
    Call ty_call;
  algorithm
    ty_call := Call.matchTypedNormalCall(call, context, info);
    ty := Call.typeOf(ty_call);
    var := Call.variability(ty_call);
    purity := Call.purity(ty_call);
    callExp := Expression.CALL(ty_call);
  end typeBuiltinStringCall;

  function typeOverloadedStringCall
    input Type overloadedType;
    input list<TypedArg> args;
    input list<TypedArg> namedArgs;
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type outType;
    output Variability var = Variability.CONSTANT;
    output Purity purity = Purity.PURE;
  protected
    ComponentRef fn_ref;
    list<Function> candidates;
    InstNode recopnode;
    MatchedFunction matchedFunc;
    list<MatchedFunction> matchedFunctions, exactMatches;
  algorithm
    Type.COMPLEX(cls=recopnode) := overloadedType;

    try
      fn_ref := Function.lookupFunctionSimple("'String'", recopnode, context);
    else
      // If there's no 'String' overload, let the normal String handler print the error.
      typeBuiltinStringCall(call, context, info);
      fail();
    end try;

    fn_ref := Function.instFunctionRef(fn_ref, context, InstNode.info(recopnode));
    candidates := Function.typeRefCache(fn_ref);
    //for fn in candidates loop
    //  TypeCheck.checkValidOperatorOverload("'String'", fn, recopnode);
    //end for;

    matchedFunctions := Function.matchFunctionsSilent(candidates, args, namedArgs, info);
    exactMatches := MatchedFunction.getExactMatches(matchedFunctions);
    if listEmpty(exactMatches) then
      Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.typedString(call), Function.candidateFuncListString(candidates)}, info);
      fail();
    end if;

    if listLength(exactMatches) == 1 then
      matchedFunc ::_ := exactMatches;
      outType := Function.returnType(matchedFunc.func);

      for arg in matchedFunc.args loop
        var := Prefixes.variabilityMax(var, arg.var);
        purity := Prefixes.purityMin(purity, arg.purity);
      end for;

      callExp := Expression.CALL(
        Call.makeTypedCall(
          matchedFunc.func,
          list(a.value for a in matchedFunc.args),
          var,
          purity,
          outType));
      return;
    else
      Error.addSourceMessage(Error.AMBIGUOUS_MATCHING_FUNCTIONS_NFINST,
        {Call.typedString(call), Function.candidateFuncListString(list(mfn.func for mfn in matchedFunctions))}, info);
      fail();
    end if;
  end typeOverloadedStringCall;

  function typeDiscreteCall
    "Types a function call that can be typed normally, but which always has
     discrete variability regardless of the variability of the arguments."
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.DISCRETE;
    output Purity purity = Purity.IMPURE;
  protected
    Call argtycall;
    Function fn;
    list<TypedArg> args;
    TypedArg start,interval;
  algorithm
    argtycall := Call.typeMatchNormalCall(call, context, info);
    ty := Call.typeOf(argtycall);
    callExp := Expression.CALL(Call.unboxArgs(argtycall));
  end typeDiscreteCall;

  function typeNdimsCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty = Type.INTEGER();
    output Variability variability = Variability.PARAMETER;
    output Purity purity = Purity.PURE;
  protected
    list<Expression> args;
    list<NamedArg> named_args;
    Type arg_ty;
  algorithm
    Call.UNTYPED_CALL(arguments = args, named_args = named_args) := call;

    assertNoNamedParams("ndims", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "ndims(Any) => Integer"}, info);
      fail();
    end if;

    // The number of dimensions an expression has is always known,
    // so we might as well evaluate the ndims call here.
    (_, arg_ty, _) := Typing.typeExp(listHead(args), context, info);
    callExp := Expression.INTEGER(Type.dimensionCount(arg_ty));
  end typeNdimsCall;

  function typePreCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity = Purity.IMPURE;
  algorithm
    (callExp, ty, variability) := typePreChangeCall("pre", call, context, info);
  end typePreCall;

  function typeChangeCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity = Purity.IMPURE;
  algorithm
    (callExp, ty, variability) := typePreChangeCall("change", call, context, info);
    ty := Type.setArrayElementType(ty, Type.BOOLEAN());
  end typeChangeCall;

  function typePreChangeCall
    input String name;
    input Call call;
    input InstContext.Type context;
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    assertNoNamedParams(name, named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Any) => Any"}, info);
    end if;

    // pre/change may not be used in a function context.
    if InstContext.inFunction(context) then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty, var) := Typing.typeExp(listHead(args), context, info);

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

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, var, Purity.IMPURE, ty));
  end typePreChangeCall;

  function typeDerCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity = Purity.IMPURE;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
    Type ety;
  algorithm
    // der may not be used in a function context.
    if InstContext.inFunction(context) then
      Error.addSourceMessage(Error.EXP_INVALID_IN_FUNCTION, {"der"}, info);
      fail();
    end if;

    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("der", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "der(Real) => Real"}, info);
    end if;

    {arg} := args;
    (arg, ty, variability) := Typing.typeExp(arg, context, info);

    // The argument of der must be a Real scalar or array.
    ety := Type.arrayElementType(ty);

    if Type.isInteger(ety) then
      ty := Type.setArrayElementType(ty, Type.REAL());
      arg := Expression.typeCast(arg, Type.REAL());
    elseif not Type.isReal(ety) then
      Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
        {"1", ComponentRef.toString(fn_ref), "", Expression.toString(arg),
         Type.toString(ty), "Real"}, info);
    end if;

    // The argument must be differentiable, i.e. not discrete, unless where in a
    // scope where everything is discrete (like an initial equation).
    if variability == Variability.DISCRETE and not InstContext.inDiscreteScope(context) then
      Error.addSourceMessageAndFail(Error.DER_OF_NONDIFFERENTIABLE_EXP,
        {Expression.toString(arg)}, info);
    end if;

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, purity, ty));
  end typeDerCall;

  function typeEdgeCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability = Variability.DISCRETE;
    output Purity purity = Purity.IMPURE;
  protected
    Call argtycall;
    Function fn;
    list<TypedArg> args;
    TypedArg arg;
    InstNode fn_node;
    NFCallAttributes ca;
  algorithm
    // edge may not be used in a function context.
    if InstContext.inFunction(context) then
      Error.addSourceMessage(Error.EXP_INVALID_IN_FUNCTION, {"edge"}, info);
      fail();
    end if;

    argtycall as Call.ARG_TYPED_CALL(ComponentRef.CREF(node = fn_node), args, _) := Call.typeNormalCall(call, context, info);
    argtycall := Call.matchTypedNormalCall(argtycall, context, info);
    ty := Call.typeOf(argtycall);
    callExp := Expression.CALL(Call.unboxArgs(argtycall));

    {arg} := args;
    if not Expression.isCref(arg.value) then
      Error.addSourceMessage(Error.ARGUMENT_MUST_BE_VARIABLE,
            {"First", "edge", "<REMOVE ME>"}, info);
      fail();
    end if;
  end typeEdgeCall;

  function typeMinMaxCall
    input String name;
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var;
    output Purity purity;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
    Expression arg1, arg2;
    Type ty1, ty2;
    Variability var1, var2;
    Purity pur1, pur2;
    TypeCheck.MatchKind mk;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams(name, named_args, info);

    (args, ty, var, purity) := match args
      case {arg1}
        algorithm
          (arg1, ty1, var, purity) := Typing.typeExp(arg1, context, info);
          ty := Type.arrayElementType(ty1);

          if not (Type.isArray(ty1) and Type.isBasic(ty)) then
            Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
              {"1", name, "", Expression.toString(arg1), Type.toString(ty1), "Any[:, ...]"}, info);
          end if;

          // If the argument is an array with a single element we can just
          // return that element instead of making a min/max call.
          if Type.isSingleElementArray(ty1) then
            callExp := Expression.applySubscript(Subscript.first(listHead(Type.arrayDims(ty1))), arg1);
            return;
          end if;
        then
          ({arg1}, ty, var, purity);

      case {arg1, arg2}
        algorithm
          (arg1, ty1, var1, pur1) := Typing.typeExp(arg1, context, info);
          (arg2, ty2, var2, pur2) := Typing.typeExp(arg2, context, info);

          if not Type.isBasic(ty1) then
            Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
              {"1", name, "", Expression.toString(arg1), Type.toString(ty1), "Any"}, info);
          end if;

          if not Type.isBasic(ty2) then
            Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
              {"2", name, "", Expression.toString(arg2), Type.toString(ty2), "Any"}, info);
          end if;

          (arg1, arg2, ty, mk) := TypeCheck.matchExpressions(arg1, ty1, arg2, ty2);

          if not TypeCheck.isValidArgumentMatch(mk) then
            Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
              {Call.toString(call), name + "(Any[:, ...]) => Any\n" + name + "(Any, Any) => Any"}, info);
          end if;
        then
          ({arg1, arg2}, ty, Prefixes.variabilityMax(var1, var2), Purity.purityMin(pur1, pur2));

      else
        algorithm
          Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
            {Call.toString(call), name + "(Any[:, ...]) => Any\n" + name + "(Any, Any) => Any"}, info);
        then
          fail();
    end match;

    fn := listHead(Function.typeRefCache(fn_ref));
    callExp := Expression.CALL(Call.makeTypedCall(fn, args, var, purity, ty));
  end typeMinMaxCall;

  function typeSumCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
    Boolean expanded;
    Operator op;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("sum", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "sum(Any[:, ...]) => Any"}, info);
    end if;

    (arg, ty, variability, purity) := Typing.typeExp(listHead(args), context, info);
    ty := Type.arrayElementType(ty);

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, purity, ty));
  end typeSumCall;

  function typeProductCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
    Boolean expanded;
    Operator op;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("product", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "product(Any[:, ...]) => Any"}, info);
    end if;

    (arg, ty, variability, purity) := Typing.typeExp(listHead(args), context, info);
    ty := Type.arrayElementType(ty);

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, purity, ty));
  end typeProductCall;

  function typePromoteCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression exp_arg, n_arg;
    Type exp_ty, n_ty;
    Variability n_var;
    Function fn;
    Integer n;
  algorithm
    if not Config.languageStandardAtLeast(Config.LanguageStandard.experimental) then
      Error.addSourceMessageAndFail(Error.EXPERIMENTAL_REQUIRED, {"promote"}, info);
    end if;

    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("promote", named_args, info);

    if listLength(args) <> 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "promote(Any[...], Integer) => Any[...]"}, info);
    end if;

    {exp_arg, n_arg} := args;
    (exp_arg, exp_ty, variability, purity) := Typing.typeExp(exp_arg, context, info);
    (n_arg, n_ty, n_var) := Typing.typeExp(n_arg, context, info);

    if not Type.isInteger(n_ty) then
      Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
        {"2", "promote", "", Expression.toString(n_arg), Type.toString(n_ty), "Integer"}, info);
    end if;

    if n_var > Variability.CONSTANT then
      Error.addSourceMessageAndFail(Error.INVALID_ARGUMENT_VARIABILITY,
        {"2", "promote", Prefixes.variabilityString(Variability.CONSTANT),
         Expression.toString(n_arg), Prefixes.variabilityString(n_var)}, info);
    end if;

    n_arg := Ceval.evalExp(n_arg, Ceval.EvalTarget.GENERIC(info));
    n := Expression.integerValue(n_arg);

    if n < Type.dimensionCount(exp_ty) then
      Error.addSourceMessageAndFail(Error.INVALID_NUMBER_OF_DIMENSIONS_FOR_PROMOTE,
        {String(n), String(Type.dimensionCount(exp_ty))}, info);
    end if;

    (callExp, ty) := Expression.promote(exp_arg, Expression.typeOf(exp_arg), Expression.integerValue(n_arg));
  end typePromoteCall;

  function typeSmoothCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity = Purity.IMPURE;
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("smooth", named_args, info);

    if listLength(args) <> 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "smooth(Integer, Any) => Any"}, info);
    end if;

    {arg1, arg2} := args;
    (arg1, ty1, var) := Typing.typeExp(arg1, context, info);
    (arg2, ty2, variability) := Typing.typeExp(arg2, context, info);

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

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg1, arg2}, var, purity, ty));
  end typeSmoothCall;

  function typeFillCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression fill_arg;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("fill", named_args, info);

    // fill can take any number of arguments, but needs at least two.
    if listLength(args) < 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "fill(Any, Integer, ...) => Any[:, ...]"}, info);
    end if;

    fill_arg :: args := args;

    // Type the first argument, which is the fill value.
    (fill_arg, ty, variability, purity) := Typing.typeExp(fill_arg, context, info);
    (callExp, ty, variability, purity) :=
      typeFillCall2(fn_ref, ty, fill_arg, variability, purity, args, context, info);
  end typeFillCall;

  function typeFillCall2
    input ComponentRef fnRef;
    input Type fillType;
    input Expression fillArg;
    input Variability fillVariability;
    input Purity fillPurity;
    input list<Expression> dimensionArgs;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability = fillVariability;
    output Purity purity = fillPurity;
  protected
    Expression fill_arg;
    list<Expression> ty_args;
    Variability arg_var;
    Purity arg_pur;
    Type arg_ty;
    Function fn;
    list<Dimension> dims;
    Boolean evaluated;
    Integer index = 1;
  algorithm
    ty_args := {fillArg};
    dims := {};
    evaluated := true;

    // Type the dimension arguments.
    for arg in dimensionArgs loop
      (arg, arg_ty, arg_var, arg_pur) := Typing.typeExp(arg, context, info);

      if not (InstContext.inAlgorithm(context) or InstContext.inFunction(context)) then
        if arg_var > Variability.PARAMETER then
          Error.addSourceMessageAndFail(Error.NON_PARAMETER_EXPRESSION_DIMENSION,
            {Expression.toString(arg), String(index),
             List.toString(fillArg :: dimensionArgs, Expression.toString,
                 ComponentRef.toString(fnRef), "(", ", ", ")", true)}, info);
        end if;

        if arg_pur == Purity.PURE and not Structural.isExpressionNotFixed(arg) then
          Structural.markExp(arg);
          arg := Ceval.evalExp(arg);
          arg_ty := Expression.typeOf(arg);
        end if;
      else
        evaluated := false;
      end if;

      // Each dimension argument must be an Integer expression.
      if not Type.isInteger(arg_ty) then
        Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
          {intString(listLength(ty_args) + 1), ComponentRef.toString(fnRef), "",
          Expression.toString(arg), Type.toString(arg_ty), "Integer"}, info);
      end if;

      if not Expression.isInteger(arg) then
        // Argument might be a binding expression that needs to be flattened
        // before we can evaluate the fill call.
        evaluated := false;
      end if;

      variability := Prefixes.variabilityMax(variability, arg_var);
      purity := Prefixes.purityMin(purity, arg_pur);
      ty_args := arg :: ty_args;
      dims := Dimension.fromExp(arg, arg_var) :: dims;
    end for;

    ty_args := listReverseInPlace(ty_args);
    dims := listReverseInPlace(dims);

    {fn} := Function.typeRefCache(fnRef);
    ty := Type.liftArrayLeftList(fillType, dims);

    if evaluated then
      callExp := Ceval.evalBuiltinFill(ty_args);
    else
      callExp := Expression.CALL(
        Call.makeTypedCall(NFBuiltinFuncs.FILL_FUNC, ty_args, variability, purity, ty));
    end if;
  end typeFillCall2;

  function typeZerosOnesCall
    input String name;
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression fill_arg;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams(name, named_args, info);

    // zeros/ones can take any number of arguments, but needs at least one.
    if listEmpty(args) then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Integer, ...) => Integer[:, ...]"}, info);
    end if;

    fill_arg := Expression.INTEGER(if name == "ones" then 1 else 0);
    (callExp, ty, variability, purity) :=
      typeFillCall2(fn_ref, Type.INTEGER(), fill_arg, Variability.CONSTANT, Purity.PURE, args, context, info);
  end typeZerosOnesCall;

  function typeScalarCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
    Boolean expanded;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("scalar", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "scalar(Any[1, ...]) => Any"}, info);
    end if;

    (arg, ty, variability, purity) := Typing.typeExp(listHead(args), context, info);

    // scalar requires all dimensions of the array to be 1.
    for dim in Type.arrayDims(ty) loop
      if Dimension.isKnown(dim) and not Dimension.size(dim) == 1 then
        Error.addSourceMessageAndFail(Error.INVALID_ARRAY_DIM_IN_SCALAR_OP,
          {Type.toString(ty)}, info);
      end if;
    end for;

    (arg, expanded) := ExpandExp.expand(arg);
    ty := Type.arrayElementType(ty);

    if expanded then
      args := Expression.arrayScalarElements(arg);

      if listLength(args) <> 1 then
        Error.assertion(false, getInstanceName() + " failed to expand scalar(" +
          Expression.toString(arg) + ") correctly", info);
      end if;

      callExp := listHead(args);
    else
      {fn} := Function.typeRefCache(fn_ref);
      callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, purity, ty));
    end if;
  end typeScalarCall;

  function typeVectorCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Variability var;
    Function fn;
    Dimension vector_dim = Dimension.fromInteger(1);
    Boolean dim_found = false;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("vector", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "vector(Any) => Any[:]\n  vector(Any[:, ...]) => Any[:]"}, info);
    end if;

    (arg, ty, variability, purity) := Typing.typeExp(listHead(args), context, info);

    // vector requires that at most one dimension is > 1, and that dimension
    // determines the type of the vector call.
    for dim in Type.arrayDims(ty) loop
      if not Dimension.isKnown(dim) or Dimension.size(dim) > 1 then
        if dim_found then
          Error.addSourceMessageAndFail(Error.NF_VECTOR_INVALID_DIMENSIONS,
            {Type.toString(ty), Call.toString(call)}, info);
        else
          vector_dim := dim;
          dim_found := true;
        end if;
      end if;
    end for;

    // The array might be empty even if one dimension is larger than 1,
    // in that case the result will also be an empty array.
    if Type.isEmptyArray(ty) then
      vector_dim := Dimension.fromInteger(0);
    end if;

    ty := Type.ARRAY(Type.arrayElementType(ty), {vector_dim});
    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, purity, ty));
  end typeVectorCall;

  function typeMatrixCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Variability var;
    Function fn;
    list<Dimension> dims;
    Dimension dim1, dim2;
    Integer i, ndims;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("matrix", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "matrix(Any) => Any[:]\n  matrix(Any[:, ...]) => Any[:]"}, info);
    end if;

    (arg, ty, variability, purity) := Typing.typeExp(listHead(args), context, info);
    dims := Type.arrayDims(ty);
    ndims := listLength(dims);

    if ndims < 2 then
      // matrix(A) where A is a scalar or vector returns promote(A, 2).
      (callExp, ty) := Expression.promote(arg, ty, 2);
    elseif ndims == 2 then
      // matrix(A) where A is a matrix just returns A.
      callExp := arg;
    else
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

      ty := Type.ARRAY(Type.arrayElementType(ty), {dim1, dim2});
      {fn} := Function.typeRefCache(fn_ref);
      callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, purity, ty));
    end if;
  end typeMatrixCall;

  function typeCatCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity;
  protected
    ComponentRef fn_ref;
    list<Expression> args, res;
    list<NamedArg> named_args;
    list<Type> tys;
    Expression arg;
    Variability var;
    Purity pur;
    TypeCheck.MatchKind mk;
    Function fn;
    Integer n;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("cat", named_args, info);

    if listLength(args) < 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "cat(Integer, Any[:,:], ...) => Any[:]"}, info);
    end if;

    arg::args := args;

    (arg, ty, variability, purity) := Typing.typeExp(arg, context, info);
    (arg, ty, mk) := TypeCheck.matchTypes(ty, Type.INTEGER(), arg);

    if variability > Variability.PARAMETER or purity <> Purity.PURE then
      Error.addSourceMessageAndFail(Error.NF_CAT_FIRST_ARG_EVAL, {Expression.toString(arg), Prefixes.variabilityString(variability)}, info);
    end if;
    Expression.INTEGER(n) := Ceval.evalExp(arg, Ceval.EvalTarget.GENERIC(info));

    res := {};
    tys := {};

    for a in args loop
      (arg, ty, var, pur) := Typing.typeExp(a, context, info);
      variability := Prefixes.variabilityMax(var, variability);
      purity := Prefixes.purityMin(pur, purity);
      res := arg :: res;
      tys := ty :: tys;
    end for;

    (callExp, ty) := makeCatExp(n, listReverse(res), listReverse(tys), variability, purity, info);
  end typeCatCall;

  function typeSymmetricCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("symmetric", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "symmetric(Any[n, n]) => Any[n, n]"}, info);
    end if;

    (arg, ty, variability, purity) := Typing.typeExp(listHead(args), context, info);

    if not Type.isSquareMatrix(ty) then
      Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
        {"1", ComponentRef.toString(fn_ref), "", Expression.toString(arg),
         Type.toString(ty), "Any[n, n]"}, info);
    end if;

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, purity, ty));
  end typeSymmetricCall;

  function typeTransposeCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Dimension dim1, dim2;
    list<Dimension> rest_dims;
    Function fn;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("transpose", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "transpose(Any[n, m, ...]) => Any[m, n, ...]"}, info);
    end if;

    (arg, ty, variability, purity) := Typing.typeExp(listHead(args), context, info);

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

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, purity, ty));
  end typeTransposeCall;

  function typeCardinalityCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.PARAMETER;
    output Purity purity = Purity.IMPURE;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
    InstNode node;
  algorithm
    // cardinality may only be used in a condition of an assert or
    // if-statement/equation (the specification says only if-statement,
    // but e.g. the MSL only uses them in if-equations and asserts).
    if not (InstContext.inCondition(context) and
       (InstContext.inIf(context) or InstContext.inAssert(context))) then
      Error.addSourceMessageAndFail(Error.INVALID_CARDINALITY_CONTEXT, {}, info);
    end if;

    if InstContext.inFunction(context) then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {AbsynUtil.pathString(Call.functionName(call))}, info);
    end if;

    (callExp, ty, _, _) := typeBuiltinCallExp(call, context, info, vectorize = false);
    System.setUsesCardinality(true);
  end typeCardinalityCall;

  function typeBranchCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.PARAMETER;
    output Purity purity = Purity.IMPURE;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg1, arg2;
    Function fn;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("Connections.branch", named_args, info);

    if listLength(args) <> 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Connector, Connector)"}, info);
    end if;

    if InstContext.inFunction(context) then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    {arg1, arg2} := args;

    (arg1, ty) := Typing.typeExp(arg1, context, info);
    checkConnectionsArgument(arg1, ty, fn_ref, 1, info);
    (arg2, ty) := Typing.typeExp(arg2, context, info);
    checkConnectionsArgument(arg2, ty, fn_ref, 2, info);

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.NORETCALL();
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg1, arg2}, var, purity, ty));
  end typeBranchCall;

  function typeIsRootCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.PARAMETER;
    output Purity purity = Purity.IMPURE;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("Connections.isRoot", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Connector)"}, info);
    end if;

    if InstContext.inFunction(context) then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty) := Typing.typeExp(listHead(args), context, info);
    checkConnectionsArgument(arg, ty, fn_ref, 1, info);

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.BOOLEAN();
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, var, purity, ty));
  end typeIsRootCall;

  function typePotentialRootCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.PARAMETER;
    output Purity purity = Purity.IMPURE;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg1, arg2;
    Function fn;
    Integer args_len;
    String name;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    for narg in named_args loop
      (name, arg2) := narg;

      if name == "priority" then
        args := List.appendElt(arg2, args);
      else
        Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
          {ComponentRef.toString(fn_ref), name}, info);
      end if;
    end for;

    args_len := listLength(args);
    if args_len < 1 or args_len > 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Connector, Integer = 0)"}, info);
    end if;

    if InstContext.inFunction(context) then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    arg1 :: args := args;

    (arg1, ty) := Typing.typeExp(arg1, context, info);
    checkConnectionsArgument(arg1, ty, fn_ref, 1, info);

    if args_len == 2 then
      arg2 := listHead(args);
      (arg2, ty) := Typing.typeExp(arg2, context, info);

      if not Type.isInteger(ty) then
        Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
          {"2", ComponentRef.toString(fn_ref), "", Expression.toString(arg2),
           Type.toString(ty), "Integer"}, info);
      end if;
    else
      arg2 := Expression.INTEGER(0);
    end if;

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.NORETCALL();
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg1, arg2}, var, purity, ty));
  end typePotentialRootCall;

  function typeRootCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.PARAMETER;
    output Purity purity = Purity.IMPURE;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("Connections.root", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Connector)"}, info);
    end if;

    if InstContext.inFunction(context) then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty) := Typing.typeExp(listHead(args), context, info);
    checkConnectionsArgument(arg, ty, fn_ref, 1, info);

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.NORETCALL();
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, var, purity, ty));
  end typeRootCall;

  function typeRootedCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.PARAMETER;
    output Purity purity = Purity.IMPURE;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("Connections.rooted", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Connector)"}, info);
    end if;

    if InstContext.inFunction(context) then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty) := Typing.typeExp(listHead(args), context, info);
    checkConnectionsArgument(arg, ty, fn_ref, 1, info);

    if ComponentRef.isSimple(fn_ref) then
      Error.addSourceMessage(Error.DEPRECATED_API_CALL, {"rooted", "Connections.rooted"}, info);
    end if;

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.BOOLEAN();
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, var, purity, ty));
  end typeRootedCall;

  function typeUniqueRootCall
    "see also typeUniqueRootIndicesCall"
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.PARAMETER;
    output Purity purity = Purity.IMPURE;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg1, arg2;
    Function fn;
    Integer args_len;
    String name;
  algorithm
    Error.addSourceMessage(Error.NON_STANDARD_OPERATOR, {"Connections.uniqueRoot"}, info);

    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    for narg in named_args loop
      (name, arg2) := narg;

      if name == "message" then
        args := List.appendElt(arg2, args);
      else
        Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
          {ComponentRef.toString(fn_ref), name}, info);
      end if;
    end for;

    args_len := listLength(args);
    if args_len < 1 or args_len > 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Connector, String = \"\")"}, info);
    end if;

    if InstContext.inFunction(context) then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    arg1 :: args := args;

    (arg1, ty) := Typing.typeExp(arg1, context, info);
    checkConnectionsArgument(arg1, ty, fn_ref, 1, info);

    if args_len == 2 then
      arg2 := listHead(args);
      (arg2, ty) := Typing.typeExp(arg2, context, info);

      if not Type.isString(ty) then
        Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
          {"2", ComponentRef.toString(fn_ref), "", Expression.toString(arg2),
           Type.toString(ty), "String"}, info);
      end if;
    else
      arg2 := Expression.STRING("");
    end if;

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.NORETCALL();
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg1, arg2}, var, purity, ty));
  end typeUniqueRootCall;

  function typeUniqueRootIndicesCall
  "See Modelica_StateGraph2:
    https://github.com/modelica/Modelica_StateGraph2
    and
    https://trac.modelica.org/Modelica/ticket/984
    and
    http://www.ep.liu.se/ecp/043/041/ecp09430108.pdf
    for a specification of this operator"
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var = Variability.PARAMETER;
    output Purity purity = Purity.IMPURE;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg1, arg2, arg3;
    Function fn;
    Integer args_len;
    String name;
    Type ty1, ty2, ty3;
  algorithm
    Error.addSourceMessage(Error.NON_STANDARD_OPERATOR, {"Connections.uniqueRootIndices"}, info);

    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    for narg in named_args loop
      (name, arg3) := narg;

      if name == "message" then
        args := List.appendElt(arg3, args);
      else
        Error.addSourceMessageAndFail(Error.NO_SUCH_PARAMETER,
          {ComponentRef.toString(fn_ref), name}, info);
      end if;
    end for;

    args_len := listLength(args);
    if args_len < 2 or args_len > 3 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Connector, Connector, String = \"\")"}, info);
    end if;

    if InstContext.inFunction(context) then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    arg1 :: arg2 :: args := args;

    (arg1, ty1) := Typing.typeExp(arg1, context, info);
    checkConnectionsArgument(arg1, ty1, fn_ref, 1, info);
    (arg2, ty2) := Typing.typeExp(arg2, context, info);
    checkConnectionsArgument(arg2, ty2, fn_ref, 1, info);

    if args_len == 3 then
      arg3 := listHead(args);
      (arg3, ty3) := Typing.typeExp(arg3, context, info);

      if not Type.isString(ty3) then
        Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
          {"3", ComponentRef.toString(fn_ref), "", Expression.toString(arg2),
           Type.toString(ty3), "String"}, info);
      end if;
    else
      arg2 := Expression.STRING("");
    end if;

    {fn} := Function.typeRefCache(fn_ref);
    assert(listLength(Type.arrayDims(ty1)) == listLength(Type.arrayDims(ty2)), "the first two parameters need to have the same size");
    ty := Type.ARRAY(Type.Type.INTEGER(), Type.arrayDims(ty1));
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg1, arg2}, var, purity, ty));

  end typeUniqueRootIndicesCall;

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
        Boolean valid_cref, isConnector;

      case Expression.CREF()
        algorithm
          (valid_cref, isConnector) := match arg.cref
            // check form A.R
            case ComponentRef.CREF(node = node, origin = NFComponentRef.Origin.CREF,
                restCref = ComponentRef.CREF(ty = ty2, origin = NFComponentRef.Origin.CREF))
              algorithm
                ty2 := match ty2
                  case Type.ARRAY()
                    guard listLength(ComponentRef.subscriptsAllFlat(arg.cref)) == listLength(ty2.dimensions)
                    then ty2.elementType;
                  else ty2;
                end match;
              then (Class.isOverdetermined(InstNode.getClass(node)), Type.isConnector(ty2));

            // adrpo #5821, allow for R only instead of A.R and issue a warning
            case ComponentRef.CREF(node = node, ty = ty2)
              algorithm
                ty2 := match ty2
                  case Type.ARRAY()
                    guard listLength(ComponentRef.subscriptsAllFlat(arg.cref)) == listLength(ty2.dimensions)
                    then ty2.elementType;
                  else ty2;
                end match;
              then (Class.isOverdetermined(InstNode.getClass(node)), Type.isConnector(ty2));

            else (false, false);
          end match;

          if not (valid_cref and isConnector) then
            if valid_cref then
              Error.addSourceMessage(
                if argIndex == 1 then Error.W_INVALID_ARGUMENT_TYPE_BRANCH_FIRST else
                                      Error.W_INVALID_ARGUMENT_TYPE_BRANCH_SECOND,
                {ComponentRef.toString(arg.cref), ComponentRef.toString(fnRef)}, info);
            else
              Error.addSourceMessageAndFail(
                if argIndex == 1 then Error.INVALID_ARGUMENT_TYPE_BRANCH_FIRST else
                                      Error.INVALID_ARGUMENT_TYPE_BRANCH_SECOND,
                {ComponentRef.toString(arg.cref), ComponentRef.toString(fnRef)}, info);
            end if;
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
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
    output Purity purity;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("noEvent", named_args, info);

    // noEvent takes exactly one argument.
    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "noEvent(Any) => Any"}, info);
    end if;

    {arg} := args;
    (arg, ty, variability, purity) := Typing.typeExp(arg, InstContext.set(context, NFInstContext.NOEVENT), info);

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, purity, ty));
  end typeNoEventCall;

  function typeGetInstanceName
    input Call call;
    output Expression result;
    output Type ty = Type.STRING();
    output Variability var = Variability.CONSTANT;
    output Purity purity = Purity.PURE;
  protected
    InstNode scope;
  algorithm
    Call.UNTYPED_CALL(call_scope = scope) := call;
    result := Expression.STRING(AbsynUtil.pathString(InstNode.scopePath(scope, includeRoot = true)));
  end typeGetInstanceName;

  function typeClockCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type outType = Type.CLOCK();
    output Variability var = Variability.PARAMETER;
    output Purity purity = Purity.IMPURE;
  protected
    Call ty_call;
    list<Expression> args;
    Integer args_count;
    Expression e1, e2;
  algorithm
    Call.TYPED_CALL(arguments = args) := Call.typeMatchNormalCall(call, context, info, vectorize = false);
    args_count := listLength(args);

    callExp := match args
      // Clock() - inferred clock.
      case {} then Expression.CLKCONST(Expression.ClockKind.INFERRED_CLOCK());
      // Clock(interval) - real clock.
      case {e1} then Expression.CLKCONST(Expression.ClockKind.REAL_CLOCK(e1));
      case {e1, e2}
        algorithm
          e2 := Ceval.evalExp(e2);

          callExp := match Expression.typeOf(e2)
            // Clock(intervalCounter, resolution) - rational clock.
            case Type.INTEGER()
              algorithm
                Error.assertionOrAddSourceMessage(Expression.integerValue(e2) >= 1,
                  Error.WRONG_VALUE_OF_ARG, {"Clock", "resolution", Expression.toString(e2), "=> 1"}, info);
              then
                Expression.CLKCONST(ClockKind.RATIONAL_CLOCK(e1, e2));

            // Clock(condition, startInterval) - event clock.
            case Type.REAL()
              then Expression.CLKCONST(ClockKind.EVENT_CLOCK(e1, e2));

            // Clock(c, solverMethod) - solver clock.
            case Type.STRING()
              then Expression.CLKCONST(ClockKind.SOLVER_CLOCK(e1, e2));
          end match;
        then
          callExp;

    end match;
  end typeClockCall;

  function typeSampleCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type outType;
    output Variability var;
    output Purity purity = Purity.IMPURE;
  protected
    Call ty_call;
    Type arg_ty;
    list<TypedArg> args;
    list<TypedArg> namedArgs;
    Expression e1, e2;
    Type t1, t2;
    Variability v1, v2;
    ComponentRef fn_ref;
    Function normalSample, clockedSample;
    InstNode recopnode;
  algorithm
    Call.ARG_TYPED_CALL(fn_ref, args, namedArgs) := Call.typeNormalCall(call, context, info);

    recopnode := ComponentRef.node(fn_ref);

    fn_ref := Function.instFunctionRef(fn_ref, context, InstNode.info(recopnode));
    {normalSample, clockedSample} := Function.typeRefCache(fn_ref);

    (callExp, outType, var) := match(args, namedArgs)

      // sample(start, Real interval) - the usual stuff
      case ({TypedArg.TYPED_ARG(value = e1, ty = t1),
             TypedArg.TYPED_ARG(value = e2, ty = Type.INTEGER())}, {})
        algorithm
          if Type.isInteger(t1) then
            e1 := Expression.CAST(Type.REAL(), e1);
          end if;
          ty_call := Call.makeTypedCall(normalSample,
            {e1, Expression.CAST(Type.REAL(), e2)}, Variability.PARAMETER, purity, Type.BOOLEAN());
        then
          (Expression.CALL(ty_call), Type.BOOLEAN(), Variability.PARAMETER);

      // sample(start, Real interval) - the usual stuff
      case ({TypedArg.TYPED_ARG(value = e1, ty = t1),
             TypedArg.TYPED_ARG(value = e2, ty = Type.REAL())}, {})
        algorithm
          if Type.isInteger(t1) then
            e1 := Expression.CAST(Type.REAL(), e1);
          end if;
          ty_call := Call.makeTypedCall(normalSample, {e1, e2}, Variability.PARAMETER, purity, Type.BOOLEAN());
        then
          (Expression.CALL(ty_call), Type.BOOLEAN(), Variability.PARAMETER);

      // sample(start, Real interval = value) - the usual stuff
      case ({TypedArg.TYPED_ARG(value = e1, ty = t1)},
            {TypedArg.TYPED_ARG(name = SOME("interval"), value = e2, ty = Type.REAL())})
        algorithm
          if Type.isInteger(t1) then
            e1 := Expression.CAST(Type.REAL(), e1);
          end if;
          ty_call := Call.makeTypedCall(normalSample, {e1, e2}, Variability.PARAMETER, purity, Type.BOOLEAN());
        then
          (Expression.CALL(ty_call), Type.BOOLEAN(), Variability.PARAMETER);

      // sample(u) - inferred clock
      case ({TypedArg.TYPED_ARG(value = e1, ty = t1, var = v1)}, {})
        algorithm
          ty_call := Call.makeTypedCall(clockedSample,
            {e1, Expression.CLKCONST(Expression.ClockKind.INFERRED_CLOCK())}, v1, purity, t1);
        then
          (Expression.CALL(ty_call), t1, v1);

      // sample(u, c) - specified clock
      case ({TypedArg.TYPED_ARG(value = e1, ty = t1, var = v1),
             TypedArg.TYPED_ARG(value = e2, ty = Type.CLOCK())}, {})
        algorithm
          ty_call := Call.makeTypedCall(clockedSample, {e1, e2}, v1, purity, t1);
        then
          (Expression.CALL(ty_call), t1, v1);

      // sample(u, Clock c = c) - specified clock
      case ({TypedArg.TYPED_ARG(value = e1, ty = t1, var = v1)},
            {TypedArg.TYPED_ARG(name = SOME("c"), value = e2, ty = Type.CLOCK())})
        algorithm
          ty_call := Call.makeTypedCall(clockedSample, {e1, e2}, v1, purity, t1);
        then
          (Expression.CALL(ty_call), t1, v1);

      else
        algorithm
          Error.addSourceMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {Call.toString(call), "<NO COMPONENT>"}, info);
        then
          fail();
    end match;
  end typeSampleCall;

  function typeActualInStreamCall
    input String name;
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability = Variability.DISCRETE;
    output Purity purity = Purity.IMPURE;
  protected
    ComponentRef fn_ref, arg_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Variability var;
    Function fn;
    InstNode arg_node;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams(name, named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(stream variable) => Real"}, info);
    end if;

    (arg, ty, var) := Typing.typeExp(listHead(args), context, info);
    arg := ExpandExp.expand(arg);

    {fn} := Function.typeRefCache(fn_ref);
    callExp := typeActualInStreamCall2(name, fn, arg, var, info);
  end typeActualInStreamCall;

  function typeActualInStreamCall2
    input String name;
    input Function fn;
    input Expression arg;
    input Variability var;
    input SourceInfo info;
    output Expression callExp;
  algorithm
    callExp := match arg
      local
        InstNode arg_node;

      case Expression.CREF()
        algorithm
          arg_node := ComponentRef.node(arg.cref);

          // The argument of actualStream/inStream must be a stream variable.
          if not InstNode.isComponent(arg_node) or
             not ConnectorType.isStream(Component.connectorType(InstNode.component(arg_node))) then
            Error.addSourceMessageAndFail(Error.NON_STREAM_OPERAND_IN_STREAM_OPERATOR,
              {ComponentRef.toString(arg.cref), name}, info);
          end if;

          // The argument of actualStream/inStream must have subscripts that can be evaluated.
          for sub in ComponentRef.subscriptsAllFlat(arg.cref) loop
            if Subscript.variability(sub) > Variability.PARAMETER then
              Error.addSourceMessageAndFail(Error.CONNECTOR_NON_PARAMETER_SUBSCRIPT,
                {ComponentRef.toString(arg.cref), Subscript.toString(sub)}, info);
            end if;
          end for;
        then
          Expression.CALL(Call.makeTypedCall(fn, {arg}, var, Purity.IMPURE, arg.ty));

      case Expression.ARRAY()
        algorithm
          arg.elements := list(typeActualInStreamCall2(name, fn, e, var, info) for e in arg.elements);
        then
          arg;

      else
        algorithm
          Error.addSourceMessage(Error.NON_STREAM_OPERAND_IN_STREAM_OPERATOR,
            {Expression.toString(arg), name}, info);
        then
          fail();

    end match;
  end typeActualInStreamCall2;

  function typeDynamicSelectCall
    input String name;
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability = Variability.CONTINUOUS;
    output Purity purity = Purity.IMPURE;
  protected
    ComponentRef fn_ref, arg_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg1, arg2;
    Variability var1, var2;
    Function fn;
    InstNode arg_node;
    Type ty1, ty2;
    Expression expStatic, expDynamic;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams(name, named_args, info);

    if listLength(args) <> 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(static expression, dynamic expression)"}, info);
    end if;

    {expStatic, expDynamic} := list(Expression.unbox(arg) for arg in args);
    (arg1, ty1, var1) := Typing.typeExp(expStatic, context, info);
    arg1 := ExpandExp.expand(arg1);

    // if we cannot typecheck the dynamic part, ignore it!
    // https://trac.openmodelica.org/OpenModelica/ticket/5631
    try
      (arg2, ty2, var2) := Typing.typeExp(expDynamic, context, info);
    else
      variability := var1;
      callExp := arg1;
      return;
    end try;

    arg2 := ExpandExp.expand(arg2);
    ty := ty1;
    variability := var2;

    {fn} := Function.typeRefCache(fn_ref);

    if Flags.isSet(Flags.NF_API_DYNAMIC_SELECT) then
      callExp := Expression.CALL(Call.makeTypedCall(fn, {arg1, arg2}, variability, purity, ty1));
    else
      variability := var1;
      callExp := arg1;
    end if;
  end typeDynamicSelectCall;

  function typeBackSampleCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var;
    output Purity purity = Purity.IMPURE;
  protected
    Call ty_call;
    Expression counter, resolution;
  algorithm
    ty_call as Call.TYPED_CALL(arguments = {_, counter, resolution}, ty = ty, var = var) :=
      Call.typeMatchNormalCall(call, context, info, vectorize = false);
    Structural.markExp(counter);
    Structural.markExp(resolution);
    callExp := Expression.CALL(ty_call);
  end typeBackSampleCall;

  function typeShiftSampleCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var;
    output Purity purity = Purity.IMPURE;
  protected
    Call ty_call;
    Expression counter, resolution;
  algorithm
    ty_call as Call.TYPED_CALL(arguments = {_, counter, resolution}, ty = ty, var = var) :=
      Call.typeMatchNormalCall(call, context, info, vectorize = false);
    Structural.markExp(counter);
    Structural.markExp(resolution);
    callExp := Expression.CALL(ty_call);
  end typeShiftSampleCall;

  function typeSubSampleCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var;
    output Purity purity = Purity.IMPURE;
  protected
    Call ty_call;
    Expression factor;
  algorithm
    ty_call as Call.TYPED_CALL(arguments = {_, factor}, ty = ty, var = var) :=
      Call.typeMatchNormalCall(call, context, info, vectorize = false);
    Structural.markExp(factor);
    callExp := Expression.CALL(ty_call);
  end typeSubSampleCall;

  function typeSuperSampleCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var;
    output Purity purity = Purity.IMPURE;
  protected
    Call ty_call;
    Expression factor;
  algorithm
    ty_call as Call.TYPED_CALL(arguments = {_, factor}, ty = ty, var = var) :=
      Call.typeMatchNormalCall(call, context, info, vectorize = false);
    Structural.markExp(factor);
    callExp := Expression.CALL(ty_call);
  end typeSuperSampleCall;

  function typePureCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var;
    output Purity purity = Purity.PURE;
  protected
    Expression arg;
    Call c;
  algorithm
    Call.TYPED_CALL(arguments = {arg}, ty = ty, var = var) :=
      Call.typeMatchNormalCall(call, context, info, vectorize = false);
    callExp := Expression.unbox(arg);

    callExp := match callExp
      case Expression.CALL(call = c as Call.TYPED_CALL())
        algorithm
          c.purity := Expression.purityList(c.arguments);
        then
          Expression.CALL(c);

      else
        algorithm
          Error.addSourceMessage(Error.FUNCTION_ARGUMENT_MUST_BE,
            {"pure", Gettext.translateContent(Error.FUNCTION_CALL_EXPRESSION)}, info);
        then
          fail();
    end match;
  end typePureCall;

  function typeBuiltinCallExp
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    input Boolean vectorize = true;
    output Expression outExp;
    output Type ty;
    output Variability var;
    output Purity pur;
  protected
    Call c;
  algorithm
    (c, ty, var, pur) := typeBuiltinCall(call, context, info, vectorize);
    outExp := Expression.CALL(c);
  end typeBuiltinCallExp;

  function typeBuiltinCall
    input Call call;
    input InstContext.Type context;
    input SourceInfo info;
    input Boolean vectorize = true;
    output Call outCall;
    output Type ty;
    output Variability var;
    output Purity pur;
  protected
    Call c;
  algorithm
    outCall := Call.typeMatchNormalCall(call, context, info, vectorize);
    ty := Call.typeOf(outCall);
    var := Call.variability(outCall);
    pur := Call.purity(outCall);
  end typeBuiltinCall;

annotation(__OpenModelica_Interface="frontend");
end NFBuiltinCall;
