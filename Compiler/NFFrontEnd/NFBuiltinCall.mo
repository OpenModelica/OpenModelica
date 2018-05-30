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

protected
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
      case "max" then typeMinMaxCall(call, origin, info);
      case "min" then typeMinMaxCall(call, origin, info);
      case "ndims" then typeNdimsCall(call, origin, info);
      case "noEvent" then typeNoEventCall(call, origin, info);
      case "ones" then typeZerosOnesCall("ones", call, origin, info);
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
      case "zeros" then typeZerosOnesCall("zeros", call, origin, info);
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

    arrayExp := Expression.ARRAY(Type.UNKNOWN(), posArgs);
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
    callExp := Expression.CALL(makeCall2(NFBuiltinFuncs.CAT, Expression.INTEGER(n)::res, resTy, variability));
  end makeCatExp;

  function makeCall
    "Creates a call to a builtin function, given a Function and a list of
     argument expressions."
    input Function func;
    input list<Expression> args;
    input Variability var;
    output Call call;
  algorithm
    call := Call.TYPED_CALL(func, func.returnType, var, args,
      CallAttributes.CALL_ATTR(func.returnType, false, true, false, false,
        DAE.NO_INLINE(), DAE.NO_TAIL()));
  end makeCall;

  function makeCall2
    "Creates a call to a builtin function, given a Function, list of argument
     expressions and a return type. Used for builtin functions defined with no
     return type."
    input Function func;
    input list<Expression> args;
    input Type returnType;
    input Variability var;
    output Call call;
  algorithm
    call := Call.TYPED_CALL(func, returnType, var, args,
      CallAttributes.CALL_ATTR(returnType, false, true, false, false,
        DAE.NO_INLINE(), DAE.NO_TAIL()));
  end makeCall2;

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

    fn_ref := Function.instFuncRef(fn_ref, InstNode.info(recopnode));
    candidates := Function.typeRefCache(fn_ref);
    for fn in candidates loop
      TypeCheck.checkValidOperatorOverload("'String'", fn, recopnode);
    end for;

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
        Call.TYPED_CALL(
          matchedFunc.func,
          outType,
          var,
          list(Util.tuple31(a) for a in matchedFunc.args),
          CallAttributes.CALL_ATTR(outType, false, false, false, false, DAE.NO_INLINE(),DAE.NO_TAIL()))
      );
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

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(makeCall2(fn, {arg}, ty, var));
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
    if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
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
    callExp := Expression.CALL(makeCall2(fn, {arg}, ty, variability));
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
    callExp := Expression.CALL(makeCall2(fn, {arg}, ty, variability));
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
    input Call call;
    input ExpOrigin.Type origin;
    input SourceInfo info;
    output Expression callExp;
    output Type ty;
    output Variability var;
  protected
    Call argtycall;
  algorithm
    argtycall := Call.typeMatchNormalCall(call, origin, info);
    argtycall := Call.unboxArgs(argtycall);
    ty := Call.typeOf(argtycall);
    var := Call.variability(argtycall);
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
    argtycall := Call.typeMatchNormalCall(call, origin, info);
    argtycall := Call.unboxArgs(argtycall);
    ty := Call.typeOf(argtycall);
    var := Call.variability(argtycall);
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
    callExp := Expression.CALL(makeCall2(fn, {arg1, arg2}, ty, var));
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

    {fn} := Function.typeRefCache(fnRef);
    ty := Type.liftArrayLeftList(fillType, dims);

    if variability <= Variability.STRUCTURAL_PARAMETER and intBitAnd(origin, ExpOrigin.FUNCTION) == 0 then
      callExp := Ceval.evalBuiltinFill(ty_args);
    else
      callExp := Expression.CALL(makeCall2(NFBuiltinFuncs.FILL_FUNC, ty_args, ty, variability));
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
    Variability var;
    Function fn;
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

    ty := Type.arrayElementType(ty);
    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(makeCall2(fn, {arg}, ty, variability));
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
      if Dimension.isKnown(dim) then
        if Dimension.size(dim) > 1 then
          if dim_size == -1 then
            dim_size := Dimension.size(dim);
          else
            Error.addSourceMessageAndFail(Error.NF_VECTOR_INVALID_DIMENSIONS,
              {Type.toString(ty), Call.toString(call)}, info);
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
    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(makeCall2(fn, {arg}, ty, variability));
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("matrix", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "vector(Any) => Any[:]\n  vector(Any[:, ...]) => Any[:]"}, info);
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
    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(makeCall2(fn, {arg}, ty, variability));
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
    callExp := Expression.CALL(makeCall2(fn, {arg}, ty, variability));
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
    callExp := Expression.CALL(makeCall2(fn, {arg}, ty, variability));
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("cardinality", named_args, info);

    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Connector) => Integer"}, info);
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

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.INTEGER();
    callExp := Expression.CALL(makeCall2(fn, {arg}, ty, var));
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("Connections.branch", named_args, info);

    if listLength(args) <> 2 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), ComponentRef.toString(fn_ref) + "(Connector, Connector)"}, info);
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

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.NORETCALL();
    callExp := Expression.CALL(makeCall2(fn, {arg1, arg2}, ty, var));
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

    if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty) := Typing.typeExp(listHead(args), origin, info);
    checkConnectionsArgument(arg, ty, fn_ref, 1, info);

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.BOOLEAN();
    callExp := Expression.CALL(makeCall2(fn, {arg}, ty, var));
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

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.NORETCALL();
    callExp := Expression.CALL(makeCall2(fn, {arg1, arg2}, ty, var));
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

    if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty) := Typing.typeExp(listHead(args), origin, info);
    checkConnectionsArgument(arg, ty, fn_ref, 1, info);

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.NORETCALL();
    callExp := Expression.CALL(makeCall2(fn, {arg}, ty, var));
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

    if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
      Error.addSourceMessageAndFail(Error.EXP_INVALID_IN_FUNCTION,
        {ComponentRef.toString(fn_ref)}, info);
    end if;

    (arg, ty) := Typing.typeExp(listHead(args), origin, info);
    checkConnectionsArgument(arg, ty, fn_ref, 1, info);

    {fn} := Function.typeRefCache(fn_ref);
    ty := Type.BOOLEAN();
    callExp := Expression.CALL(makeCall2(fn, {arg}, ty, var));
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
    Call.UNTYPED_CALL(ref = fn_ref, arguments = args, named_args = named_args) := call;
    assertNoNamedParams("noEvent", named_args, info);

    // noEvent takes exactly one argument.
    if listLength(args) <> 1 then
      Error.addSourceMessageAndFail(Error.NO_MATCHING_FUNCTION_FOUND_NFINST,
        {Call.toString(call), "noEvent(Any) => Any"}, info);
    end if;

    {arg} := args;
    (arg, ty, variability) := Typing.typeExp(arg, intBitOr(origin, ExpOrigin.NOEVENT), info);

    {fn} := Function.typeRefCache(fn_ref);
    callExp := Expression.CALL(makeCall2(fn, {arg}, ty, variability));
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

annotation(__OpenModelica_Interface="frontend");
end NFBuiltinCall;
