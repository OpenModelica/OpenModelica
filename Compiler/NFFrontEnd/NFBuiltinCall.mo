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
  import NFCall.Call;
  import NFCall.CallAttributes;
  import DAE;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import NFPrefixes.Variability;
  import Type = NFType;
  import Subscript = NFSubscript;

protected
  import Config;
  import Ceval = NFCeval;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import List;
  import MetaModelica.Dangerous.listReverseInPlace;
  import NFClass.Class;
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
  import ExpandExp = NFExpandExp;
  import Operator = NFOperator;
  import NFComponent.Component;

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
    Call.UNTYPED_CALL(ref = cref) := call;

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
      case "getInstanceName" then typeGetInstanceName(call);
      case "initial" then typeDiscreteCall(call, origin, info);
      case "isRoot" then typeIsRootCall(call, origin, info);
      case "matrix" then typeMatrixCall(call, origin, info);
      case "max" then typeMinMaxCall("max", call, origin, info);
      case "min" then typeMinMaxCall("min", call, origin, info);
      case "ndims" then typeNdimsCall(call, origin, info);
      case "noEvent" then typeNoEventCall(call, origin, info);
      case "ones" then typeZerosOnesCall("ones", call, origin, info);
      case "potentialRoot" then typePotentialRootCall(call, origin, info);
      case "pre" then typePreCall(call, origin, info);
      case "product" then typeProductCall(call, origin, info);
      case "root" then typeRootCall(call, origin, info);
      case "rooted" then typeRootedCall(call, origin, info);
      case "scalar" then typeScalarCall(call, origin, info);
      case "smooth" then typeSmoothCall(call, origin, info);
      case "sum" then typeSumCall(call, origin, info);
      case "symmetric" then typeSymmetricCall(call, origin, info);
      case "terminal" then typeDiscreteCall(call, origin, info);
      case "transpose" then typeTransposeCall(call, origin, info);
      case "vector" then typeVectorCall(call, origin, info);
      case "zeros" then typeZerosOnesCall("zeros", call, origin, info);
      case "Clock" guard Config.synchronousFeaturesAllowed() then typeClockCall(call, origin, info);
      case "sample" then typeSampleCall(call, origin, info);
      /*
      case "hold" guard Config.synchronousFeaturesAllowed() then typeHoldCall(call, origin, info);
      case "shiftSample" guard Config.synchronousFeaturesAllowed() then typeShiftSampleCall(call, origin, info);
      case "backSample" guard Config.synchronousFeaturesAllowed() then typeBackSampleCall(call, origin, info);
      case "noClock" guard Config.synchronousFeaturesAllowed() then typeNoClockCall(call, origin, info);
      case "transition" guard Config.synchronousFeaturesAllowed() then typeTransitionCall(call, origin, info);
      case "initialState" guard Config.synchronousFeaturesAllowed() then typeInitialStateCall(call, origin, info);
      case "activeState" guard Config.synchronousFeaturesAllowed() then typeActiveStateCall(call, origin, info);
      case "ticksInState" guard Config.synchronousFeaturesAllowed() then typeTicksInStateCall(call, origin, info);
      case "timeInState" guard Config.synchronousFeaturesAllowed() then typeTimeInStateCall(call, origin, info);
      */
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
    callExp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.CAT, Expression.INTEGER(n)::res, variability, resTy));
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
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type outType;
    output Variability var;
  protected
    Type arg_ty;
    list<TypedArg> args;
    list<TypedNamedArg> named_args;
    Call ty_call;
  algorithm
    ty_call as Call.ARG_TYPED_CALL(_, args, named_args) := Call.typeNormalCall(call, origin, info);
    (_, arg_ty, _) :: _ := args;
    arg_ty := Type.arrayElementType(arg_ty);

    if Type.isComplex(arg_ty) then
      (callExp, outType, var) := typeOverloadedStringCall(arg_ty, args, named_args, ty_call, origin, info);
    else
      (callExp, outType, var) := typeBuiltinStringCall(ty_call, origin, info);
    end if;
  end typeStringCall;

  function typeBuiltinStringCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var;
  protected
    Call ty_call;
  algorithm
    ty_call := Call.matchTypedNormalCall(call, origin, info);
    ty := Call.typeOf(ty_call);
    var := Call.variability(ty_call);
    callExp := Expression.CALL(ty_call);
  end typeBuiltinStringCall;

  function typeOverloadedStringCall
    input Type overloadedType;
    input list<TypedArg> args;
    input list<TypedNamedArg> namedArgs;
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type outType;
    output Variability var = Variability.CONSTANT;
  protected
    ComponentRef fn_ref;
    list<Function> candidates;
    InstNode recopnode;
    MatchedFunction matchedFunc;
    list<MatchedFunction> matchedFunctions, exactMatches;
  algorithm
    Type.COMPLEX(cls=recopnode) := overloadedType;

    try
      fn_ref := Function.lookupFunctionSimple("'String'", recopnode);
    else
      // If there's no 'String' overload, let the normal String handler print the error.
      typeBuiltinStringCall(call, origin, info);
      fail();
    end try;

    fn_ref := Function.instFunctionRef(fn_ref, InstNode.info(recopnode));
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
        var := Prefixes.variabilityMax(var, Util.tuple33(arg));
      end for;

      callExp := Expression.CALL(
        Call.makeTypedCall(
          matchedFunc.func,
          list(Util.tuple31(a) for a in matchedFunc.args),
          var,
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
    argtycall := Call.typeMatchNormalCall(call, origin, info);
    ty := Call.typeOf(argtycall);
    callExp := Expression.CALL(Call.unboxArgs(argtycall));
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
    Call.UNTYPED_CALL(arguments = args, named_args = named_args) := call;

    assertNoNamedParams("ndims", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "ndims(Any) => Integer"}, info);
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
    output Variability variability;
  algorithm
    (callExp, ty, variability) := typePreChangeCall("pre", call, origin, info);
  end typePreCall;

  function typeChangeCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability variability;
  algorithm
    (callExp, ty, variability) := typePreChangeCall("change", call, origin, info);
    ty := Type.setArrayElementType(ty, Type.BOOLEAN());
  end typeChangeCall;

  function typePreChangeCall
    input String name;
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;

    assertNoNamedParams(name, named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Any) => Any"}, info);
    end if;

    // pre/change may not be used in a function context.
    if ExpOrigin.flagSet(origin, ExpOrigin.FUNCTION) then
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

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, var, ty));
  end typePreChangeCall;

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
    if ExpOrigin.flagSet(origin, ExpOrigin.FUNCTION) then
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

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, ty));
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("diagonal", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "diagonal(Any[n]) => Any[n, n]"}, info);
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

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, ty));
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
    if ExpOrigin.flagSet(origin, ExpOrigin.FUNCTION) then
      Error.addSourceMessage(Error.EXP_INVALID_IN_FUNCTION, {"edge"}, info);
      fail();
    end if;

    argtycall as Call.ARG_TYPED_CALL(ComponentRef.CREF(node = fn_node), args, _) := Call.typeNormalCall(call, origin, info);
    argtycall := Call.matchTypedNormalCall(argtycall, origin, info);
    ty := Call.typeOf(argtycall);
    callExp := Expression.CALL(Call.unboxArgs(argtycall));

    {arg} := args;
    if not Expression.isCref(Util.tuple31(arg)) then
      Error.addSourceMessage(Error.ARGUMENT_MUST_BE_VARIABLE,
            {"First", "edge", "<REMOVE ME>"}, info);
      fail();
    end if;
  end typeEdgeCall;

  function typeMinMaxCall
    input String name;
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    Expression arg;
    Function fn;
    Expression arg1, arg2;
    Type ty1, ty2;
    Variability var1, var2;
    TypeCheck.MatchKind mk;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams(name, named_args, info);

    (args, ty, var) := match args
      case {arg1}
        algorithm
          (arg1, ty1, var1) := Typing.typeExp(arg1, origin, info);
          ty := Type.arrayElementType(ty1);

          if not (Type.isArray(ty1) and Type.isBasic(ty)) then
            Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
              {"1", name, "", Expression.toString(arg1), Type.toString(ty1), "Any[:, ...]"}, info);
          end if;

        then
          ({arg1}, ty, var1);

      case {arg1, arg2}
        algorithm
          (arg1, ty1, var1) := Typing.typeExp(arg1, origin, info);
          (arg2, ty2, var2) := Typing.typeExp(arg2, origin, info);

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
          ({arg1, arg2}, ty, Prefixes.variabilityMax(var1, var2));

      else
        algorithm
          Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
            {Call.toString(call), name + "(Any[:, ...]) => Any\n" + name + "(Any, Any) => Any"}, info);
        then
          fail();
    end match;

    fn := listHead(Function.typeRefCache(fn_ref));
    callExp := Expression.CALL(Call.makeTypedCall(fn, args, var, ty));
  end typeMinMaxCall;

  function typeSumCall
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
    Boolean expanded;
    Operator op;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("sum", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "sum(Any[:, ...]) => Any"}, info);
    end if;

    (arg, ty, variability) := Typing.typeExp(listHead(args), origin, info);
    ty := Type.arrayElementType(ty);

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, ty));
  end typeSumCall;

  function typeProductCall
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
    Boolean expanded;
    Operator op;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("product", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "product(Any[:, ...]) => Any"}, info);
    end if;

    (arg, ty, variability) := Typing.typeExp(listHead(args), origin, info);
    ty := Type.arrayElementType(ty);

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, ty));
  end typeProductCall;

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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("smooth", named_args, info);

    if listLength(args) <> 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "smooth(Integer, Any) => Any"}, info);
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

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg1, arg2}, var, ty));
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("fill", named_args, info);

    // fill can take any number of arguments, but needs at least two.
    if listLength(args) < 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "fill(Any, Integer, ...) => Any[:, ...]"}, info);
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
    Boolean evaluated;
  algorithm
    ty_args := {fillArg};
    dims := {};
    evaluated := true;

    // Type the dimension arguments.
    for arg in dimensionArgs loop
      (arg, arg_ty, arg_var) := Typing.typeExp(arg, origin, info);

      if arg_var <= Variability.STRUCTURAL_PARAMETER and not Expression.containsIterator(arg, origin) then
        arg := Ceval.evalExp(arg);
        arg_ty := Expression.typeOf(arg);
      else
        evaluated := false;
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

    {fn} := Function.typeRefCache(fnRef);
    ty := Type.liftArrayLeftList(fillType, dims);

    if evaluated and ExpOrigin.flagNotSet(origin, ExpOrigin.FUNCTION) then
      callExp := Ceval.evalBuiltinFill(ty_args);
    else
      callExp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.FILL_FUNC, ty_args, variability, ty));
    end if;
  end typeFillCall2;

  function typeZerosOnesCall
    input String name;
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams(name, named_args, info);

    // zeros/ones can take any number of arguments, but needs at least one.
    if listEmpty(args) then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Integer, ...) => Integer[:, ...]"}, info);
    end if;

    fill_arg := Expression.INTEGER(if name == "ones" then 1 else 0);
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
    Function fn;
    Boolean expanded;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("scalar", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "scalar(Any[1, ...]) => Any"}, info);
    end if;

    (arg, ty, variability) := Typing.typeExp(listHead(args), origin, info);

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
      callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, ty));
    end if;
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
    Dimension vector_dim = Dimension.fromInteger(1);
    Boolean dim_found = false;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("vector", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "vector(Any) => Any[:]\n  vector(Any[:, ...]) => Any[:]"}, info);
    end if;

    (arg, ty, variability) := Typing.typeExp(listHead(args), origin, info);

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

    ty := Type.ARRAY(Type.arrayElementType(ty), {vector_dim});
    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, ty));
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
    Integer i, ndims;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("matrix", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "vector(Any) => Any[:]\n  vector(Any[:, ...]) => Any[:]"}, info);
    end if;

    (arg, ty, variability) := Typing.typeExp(listHead(args), origin, info);
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
      callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, ty));
    end if;
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("cat", named_args, info);

    if listLength(args) < 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "cat(Integer, Any[:,:], ...) => Any[:]"}, info);
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

    (callExp, ty) := makeCatExp(n, listReverse(res), listReverse(tys), variability, info);
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("symmetric", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "symmetric(Any[n, n]) => Any[n, n]"}, info);
    end if;

    (arg, ty, variability) := Typing.typeExp(listHead(args), origin, info);

    if not Type.isSquareMatrix(ty) then
      Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
        {"1", ComponentRef.toString(fn_ref), "", Expression.toString(arg),
         Type.toString(ty), "Any[n, n]"}, info);
    end if;

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, ty));
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("transpose", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "transpose(Any[n, m, ...]) => Any[m, n, ...]"}, info);
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

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, ty));
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
    InstNode node;
  algorithm
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("cardinality", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Connector) => Integer"}, info);
    end if;

    if ExpOrigin.flagSet(origin, ExpOrigin.FUNCTION) then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty) := Typing.typeExp(listHead(args), origin, info);

    if not Expression.isCref(arg) then
      Error.addSourceMessageAndFail(Error.ARGUMENT_MUST_BE_VARIABLE,
        {"First", ComponentRef.toString(fn_ref), "<REMOVE ME>"}, info);
    end if;

    node := ComponentRef.node(Expression.toCref(arg));

    if not (Type.isScalar(ty) and InstNode.isComponent(node) and Component.isConnector(InstNode.component(node))) then
      Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH,
        {"1", ComponentRef.toString(fn_ref), "",
         Expression.toString(arg), Type.toString(ty), "connector"}, info);
    end if;

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.INTEGER();
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, var, ty));
    // TODO: Check cardinality restrictions, 3.7.2.3.

    System.setUsesCardinality(true);
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("Connections.branch", named_args, info);

    if listLength(args) <> 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Connector, Connector)"}, info);
    end if;

    if ExpOrigin.flagSet(origin, ExpOrigin.FUNCTION) then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    {arg1, arg2} := args;

    (arg1, ty) := Typing.typeExp(arg1, origin, info);
    checkConnectionsArgument(arg1, ty, fn_ref, 1, info);
    (arg2, ty) := Typing.typeExp(arg2, origin, info);
    checkConnectionsArgument(arg2, ty, fn_ref, 2, info);

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.NORETCALL();
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg1, arg2}, var, ty));
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("Connections.isRoot", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Connector)"}, info);
    end if;

    if ExpOrigin.flagSet(origin, ExpOrigin.FUNCTION) then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty) := Typing.typeExp(listHead(args), origin, info);
    checkConnectionsArgument(arg, ty, fn_ref, 1, info);

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.BOOLEAN();
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, var, ty));
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

    if ExpOrigin.flagSet(origin, ExpOrigin.FUNCTION) then
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

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.NORETCALL();
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg1, arg2}, var, ty));
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("Connections.root", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Connector)"}, info);
    end if;

    if ExpOrigin.flagSet(origin, ExpOrigin.FUNCTION) then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty) := Typing.typeExp(listHead(args), origin, info);
    checkConnectionsArgument(arg, ty, fn_ref, 1, info);

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.NORETCALL();
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, var, ty));
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("Connections.rooted", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Connector)"}, info);
    end if;

    if ExpOrigin.flagSet(origin, ExpOrigin.FUNCTION) then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty) := Typing.typeExp(listHead(args), origin, info);
    checkConnectionsArgument(arg, ty, fn_ref, 1, info);

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.BOOLEAN();
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, var, ty));
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

      case Expression.CREF()
        algorithm
          valid_cref := match arg.cref
            case ComponentRef.CREF(node = node, origin = NFComponentRef.Origin.CREF,
                restCref = ComponentRef.CREF(ty = ty2, origin = NFComponentRef.Origin.CREF))
              algorithm
                ty2 := match ty2
                  case Type.ARRAY()
                    guard listLength(ComponentRef.subscriptsAllFlat(arg.cref)) == listLength(ty2.dimensions)
                    then ty2.elementType;
                  else ty2;
                end match;
              then Class.isOverdetermined(InstNode.getClass(node)) and
                   Type.isConnector(ty2);

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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("noEvent", named_args, info);

    // noEvent takes exactly one argument.
    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "noEvent(Any) => Any"}, info);
    end if;

    {arg} := args;
    (arg, ty, variability) := Typing.typeExp(arg, ExpOrigin.setFlag(origin, ExpOrigin.NOEVENT), info);

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(Call.makeTypedCall(fn, {arg}, variability, ty));
  end typeNoEventCall;

  function typeGetInstanceName
    input Call call;
    output Expression result;
    output Type ty = Type.STRING();
    output Variability var = Variability.CONSTANT;
  protected
    InstNode scope;
  algorithm
    Call.UNTYPED_CALL(call_scope = scope) := call;
    result := Expression.STRING(Absyn.pathString(InstNode.scopePath(scope, includeRoot = true)));
  end typeGetInstanceName;

  function typeClockCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type outType = Type.CLOCK();
    output Variability var = Variability.PARAMETER;
  protected
    Call ty_call;
    list<Expression> args;
    Integer args_count;
    Expression e1, e2;
  algorithm
    Call.TYPED_CALL(arguments = args) := Call.typeMatchNormalCall(call, origin, info);
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
            // Clock(intervalCounter, resolution) - integer clock.
            case Type.INTEGER()
              algorithm
                Error.assertionOrAddSourceMessage(Expression.integerValue(e2) >= 1,
                  Error.WRONG_VALUE_OF_ARG, {"Clock", "resolution", Expression.toString(e2), "=> 1"}, info);
              then
                Expression.CLKCONST(Expression.INTEGER_CLOCK(e1, e2));

            // Clock(condition, startInterval) - boolean clock.
            case Type.REAL()
              then Expression.CLKCONST(Expression.BOOLEAN_CLOCK(e1, e2));

            // Clock(c, solverMethod) - solver clock.
            case Type.STRING()
              then Expression.CLKCONST(Expression.SOLVER_CLOCK(e1, e2));
          end match;
        then
          callExp;

    end match;
  end typeClockCall;

  function typeSampleCall
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type outType;
    output Variability var;
  protected
    Call ty_call;
    Type arg_ty;
    list<TypedArg> args;
    list<TypedNamedArg> namedArgs;
    Expression e, e1, e2;
    Type t, t1, t2;
    Variability v, v1, v2;
    ComponentRef fn_ref;
    Function normalSample, clockedSample;
    InstNode recopnode;
  algorithm
    Call.ARG_TYPED_CALL(fn_ref, args, namedArgs) := Call.typeNormalCall(call, origin, info);

    recopnode := ComponentRef.node(fn_ref);

    fn_ref := Function.instFunctionRef(fn_ref, InstNode.info(recopnode));
    {normalSample, clockedSample} := Function.typeRefCache(fn_ref);

    (callExp, outType, var) := match(args, namedArgs)

      // sample(start, Real interval) - the usual stuff
      case ({(e, t, v), (e1, Type.INTEGER(), v1)}, {})
        algorithm
          if valueEq(t, Type.INTEGER()) then
            e := Expression.CAST(Type.REAL(), e);
          end if;
          ty_call := Call.makeTypedCall(normalSample, {e, Expression.CAST(Type.REAL(), e1)}, Variability.PARAMETER, Type.BOOLEAN());
        then
          (Expression.CALL(ty_call), Type.BOOLEAN(), Variability.PARAMETER);

      // sample(start, Real interval) - the usual stuff
      case ({(e, t, v), (e1, Type.REAL(), v1)}, {})
        algorithm
          if valueEq(t, Type.INTEGER()) then
            e := Expression.CAST(Type.REAL(), e);
          end if;
          ty_call := Call.makeTypedCall(normalSample, {e, e1}, Variability.PARAMETER, Type.BOOLEAN());
        then
          (Expression.CALL(ty_call), Type.BOOLEAN(), Variability.PARAMETER);

      // sample(start, Real interval = value) - the usual stuff
      case ({(e, t, v)}, {("interval", e1, Type.REAL(), v1)})
        algorithm
          if valueEq(t, Type.INTEGER()) then
            e := Expression.CAST(Type.REAL(), e);
          end if;
          ty_call := Call.makeTypedCall(normalSample, {e, e1}, Variability.PARAMETER, Type.BOOLEAN());
        then
          (Expression.CALL(ty_call), Type.BOOLEAN(), Variability.PARAMETER);

      // sample(u) - inferred clock
      case ({(e, t, v)}, {}) guard Config.synchronousFeaturesAllowed()
        algorithm
          ty_call := Call.makeTypedCall(clockedSample, {e, Expression.CLKCONST(Expression.ClockKind.INFERRED_CLOCK())}, v, t);
        then
          (Expression.CALL(ty_call), t, v);

      // sample(u, c) - specified clock
      case ({(e, t, v), (e1, Type.CLOCK(), v1)}, {}) guard Config.synchronousFeaturesAllowed()
        algorithm
          ty_call := Call.makeTypedCall(clockedSample, {e, e1}, v, t);
        then
          (Expression.CALL(ty_call), t, v);

      // sample(u, Clock c = c) - specified clock
      case ({(e, t, v)}, {("c", e1, Type.CLOCK(), v1)}) guard Config.synchronousFeaturesAllowed()
        algorithm
          ty_call := Call.makeTypedCall(clockedSample, {e, e1}, v, t);
        then
          (Expression.CALL(ty_call), t, v);

      else
        algorithm
          Error.addSourceMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {Call.toString(call), "<NO COMPONENT>"}, info);
        then
          fail();
    end match;
  end typeSampleCall;

annotation(__OpenModelica_Interface="frontend");
end NFBuiltinCall;
