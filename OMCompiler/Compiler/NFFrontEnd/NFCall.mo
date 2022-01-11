 /*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

encapsulated uniontype NFCall

import Absyn;
import AbsynUtil;
import DAE;
import Expression = NFExpression;
import NFCallAttributes;
import NFInstNode.InstNode;
import NFPrefixes.{Variability, Purity};
import Type = NFType;
import Record = NFRecord;

protected
import Binding = NFBinding;
import BuiltinCall = NFBuiltinCall;
import Ceval = NFCeval;
import Component = NFComponent;
import ComponentRef = NFComponentRef;
import Config;
import Dimension = NFDimension;
import ErrorExt;
import EvalFunction = NFEvalFunction;
import Inline = NFInline;
import Inst = NFInst;
import List;
import Lookup = NFLookup;
import MetaModelica.Dangerous.listReverseInPlace;
import Class = NFClass;
import NFFunction.Function;
import NFFunction.FunctionMatchKind;
import NFFunction.MatchedFunction;
import NFFunction.NamedArg;
import NFFunction.TypedArg;
import NFInstNode.CachedData;
import Operator = NFOperator;
import Prefixes = NFPrefixes;
import SCodeUtil;
import SimplifyExp = NFSimplifyExp;
import Subscript = NFSubscript;
import TypeCheck = NFTypeCheck;
import Typing = NFTyping;
import Util;
import InstContext = NFInstContext;
import ComplexType = NFComplexType;

import Call = NFCall;

protected
  import NFCallParameterTree;
  type ParameterTree = NFCallParameterTree.Tree;
public
  record UNTYPED_CALL
    ComponentRef ref;
    list<Expression> arguments;
    list<NamedArg> named_args;
    InstNode call_scope;
  end UNTYPED_CALL;

  record ARG_TYPED_CALL
    ComponentRef ref;
    list<TypedArg> positional_args;
    list<TypedArg> named_args;
    InstNode call_scope;
  end ARG_TYPED_CALL;

  record TYPED_CALL
    Function fn;
    Type ty;
    Variability var;
    Purity purity;
    list<Expression> arguments;
    NFCallAttributes attributes;
  end TYPED_CALL;

  record UNTYPED_ARRAY_CONSTRUCTOR
    Expression exp;
    list<tuple<InstNode, Expression>> iters;
  end UNTYPED_ARRAY_CONSTRUCTOR;

  record TYPED_ARRAY_CONSTRUCTOR
    Type ty;
    Variability var;
    Purity purity;
    Expression exp;
    list<tuple<InstNode, Expression>> iters;
  end TYPED_ARRAY_CONSTRUCTOR;

  record UNTYPED_REDUCTION
    ComponentRef ref;
    Expression exp;
    list<tuple<InstNode, Expression>> iters;
  end UNTYPED_REDUCTION;

  record TYPED_REDUCTION
    Function fn;
    Type ty;
    Variability var;
    Purity purity;
    Expression exp;
    list<tuple<InstNode, Expression>> iters;
    Option<Expression> defaultExp;
    tuple<Option<Expression>, String, String> foldExp;
  end TYPED_REDUCTION;

  function instantiate
    input Absyn.ComponentRef functionName;
    input Absyn.FunctionArgs functionArgs;
    input InstNode scope;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
  algorithm
    callExp := match functionArgs
      case Absyn.FUNCTIONARGS() then instNormalCall(functionName, functionArgs, scope, context, info);
      case Absyn.FOR_ITER_FARG() then instIteratorCall(functionName, functionArgs, scope, context, info);
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown call type", sourceInfo());
        then
          fail();
    end match;
  end instantiate;

  function typeCall
    input Expression callExp;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression outExp;
    output Type ty;
    output Variability var;
    output Purity pur;
  protected
    NFCall call, ty_call;
    list<Expression> args;
    ComponentRef cref;
  algorithm
    Expression.CALL(call = call) := callExp;

    outExp := match call
      case UNTYPED_CALL(ref = cref)
        algorithm
          if BuiltinCall.needSpecialHandling(call) then
            (outExp, ty, var, pur) := BuiltinCall.typeSpecial(call, context, info);
          else
            checkNotPartial(cref, context, info);
            ty_call := typeMatchNormalCall(call, context, info);
            ty := typeOf(ty_call);
            var := variability(ty_call);
            pur := purity(ty_call);

            if isRecordConstructor(ty_call) then
              outExp := toRecordExpression(ty_call, ty);
            else
              if Function.hasUnboxArgs(typedFunction(ty_call)) then
                outExp := Expression.CALL(unboxArgs(ty_call));
              else
                outExp := Expression.CALL(ty_call);
              end if;
              outExp := Inline.inlineCallExp(outExp);
            end if;
          end if;
        then
          outExp;

      case UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          (ty_call, ty, var, pur) := typeArrayConstructor(call, context, info);
        then
          Expression.CALL(ty_call);

      case UNTYPED_REDUCTION()
        algorithm
          checkNotPartial(call.ref, context, info);
          (ty_call, ty, var, pur) := typeReduction(call, context, info);
        then
          Expression.CALL(ty_call);

      case TYPED_CALL()
        algorithm
          ty := call.ty;
          var := call.var;
          pur := call.purity;
        then
          callExp;

      case TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          ty := call.ty;
          var := call.var;
          pur := call.purity;
        then
          callExp;

      case TYPED_REDUCTION()
        algorithm
          ty := call.ty;
          var := call.var;
          pur := call.purity;
        then
          callExp;

      else
        algorithm
          Error.assertion(false, getInstanceName() + ": " + Expression.toString(callExp), sourceInfo());
        then fail();
    end match;
  end typeCall;

  function checkNotPartial
    input ComponentRef fnRef;
    input InstContext.Type context;
    input SourceInfo info;
  algorithm
    if InstNode.isPartial(ComponentRef.node(fnRef)) and not InstContext.inRelaxed(context) then
      Error.addSourceMessage(Error.PARTIAL_FUNCTION_CALL,
        {ComponentRef.toString(fnRef)}, info);
      fail();
    end if;
  end checkNotPartial;

  function typeNormalCall
    input output NFCall call;
    input InstContext.Type context;
    input SourceInfo info;
  algorithm
    call := match call
      local
        list<Function> fnl;
        Boolean is_external;
        InstContext.Type fn_context;

      case UNTYPED_CALL()
        algorithm
          // Strip any contexts that don't apply inside the function itself.
          if InstContext.inRelaxed(context) then
            fn_context := InstContext.set(NFInstContext.FUNCTION, NFInstContext.RELAXED);
          else
            fn_context := NFInstContext.FUNCTION;
          end if;

          fnl := Function.typeRefCache(call.ref, fn_context);
        then
          typeArgs(call, context, info);

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
    input Purity purity;
    input Type returnType = fn.returnType;
    output NFCall call;
  protected
    NFCallAttributes ca;
  algorithm
    ca := NFCallAttributes.CALL_ATTR(
      Type.isTuple(returnType),
      Function.isBuiltin(fn),
      Function.isImpure(fn),
      Function.isFunctionPointer(fn),
      Function.inlineBuiltin(fn),
      DAE.NO_TAIL()
    );

    call := TYPED_CALL(fn, returnType, variability, purity, args, ca);
  end makeTypedCall;

  function unboxArgs
    input output NFCall call;
  protected
    Call c;
  algorithm
    () := match call
      case TYPED_CALL()
        algorithm
          call.arguments := list(Expression.unbox(arg) for arg in call.arguments);
        then
          ();

      case TYPED_ARRAY_CONSTRUCTOR(exp = Expression.CALL(call = c))
        algorithm
          call.exp := Expression.CALL(unboxArgs(c));
        then
          ();

      else ();
    end match;
  end unboxArgs;

  function typeMatchNormalCall
    input output NFCall call;
    input InstContext.Type context;
    input SourceInfo info;
    input Boolean vectorize = true;
  protected
    NFCall argtycall;
  algorithm
    argtycall := typeNormalCall(call, context, info);
    call := matchTypedNormalCall(argtycall, context, info, vectorize);
  end typeMatchNormalCall;

  function matchTypedNormalCall
    input output NFCall call;
    input InstContext.Type context;
    input SourceInfo info;
    input Boolean vectorize = true;
  protected
    Function func;
    list<Expression> args;
    list<TypedArg> typed_args;
    MatchedFunction matchedFunc;
    InstNode scope;
    Variability var, arg_var;
    Purity pur, arg_pur;
    Type ty;
    Expression arg_exp;
  algorithm
    ARG_TYPED_CALL(call_scope = scope) := call;
    matchedFunc := checkMatchingFunctions(call, info, vectorize);

    func := matchedFunc.func;
    typed_args := matchedFunc.args;

    args := {};
    var := Variability.CONSTANT;
    pur := if Function.isImpure(func) or Function.isOMImpure(func) then Purity.IMPURE else Purity.PURE;

    for a in typed_args loop
      TypedArg.TYPED_ARG(value = arg_exp, var = arg_var, purity = arg_pur) := a;
      args := arg_exp :: args;
      var := Prefixes.variabilityMax(var, arg_var);
      pur := Prefixes.purityMin(pur, arg_pur);
    end for;
    args := listReverseInPlace(args);

    ty := Function.returnType(func);
    ty := resolvePolymorphicReturnType(func, typed_args, ty);

    if var == Variability.PARAMETER and Function.isExternal(func) then
      // Mark external functions with parameter expressions as non-structural,
      // to avoid them being marked as structural unnecessarily.
      var := Variability.NON_STRUCTURAL_PARAMETER;
    elseif Type.isDiscrete(ty) and var == Variability.CONTINUOUS then
      // Functions that return a discrete type, e.g. Integer, should probably be
      // treated as implicitly discrete if the arguments are continuous.
      var := Variability.IMPLICITLY_DISCRETE;
    end if;

    ty := evaluateCallType(ty, func, args);
    call := makeTypedCall(func, args, var, pur, ty);

    // If the matching was a vectorized one then create a map call
    // using the vectorization dim. This means going through each argument
    // and subscripting it with an iterator for each dim and creating a map call.
    if MatchedFunction.isVectorized(matchedFunc) then
      call := vectorizeCall(call, matchedFunc.mk, scope, info);
    end if;
  end matchTypedNormalCall;

  function typeOf
    input NFCall call;
    output Type ty;
  algorithm
    ty := match call
      case TYPED_CALL() then call.ty;
      case TYPED_ARRAY_CONSTRUCTOR() then call.ty;
      case TYPED_REDUCTION() then call.ty;
      else Type.UNKNOWN();
    end match;
  end typeOf;

  function setType
    input output NFCall call;
    input Type ty;
  algorithm
    call := match call
      case TYPED_CALL() algorithm call.ty := ty; then call;
      case TYPED_ARRAY_CONSTRUCTOR() algorithm call.ty := ty; then call;
      case TYPED_REDUCTION() algorithm call.ty := ty; then call;
    end match;
  end setType;

  function variability
    input NFCall call;
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

      case UNTYPED_ARRAY_CONSTRUCTOR() then Expression.variability(call.exp);
      case UNTYPED_REDUCTION() then Expression.variability(call.exp);
      case TYPED_CALL() then call.var;
      case TYPED_ARRAY_CONSTRUCTOR() then call.var;
      case TYPED_REDUCTION() then call.var;
      else algorithm
        Error.assertion(false, getInstanceName() + " got untyped call", sourceInfo());
        then fail();
    end match;
  end variability;

  function purity
    input Call call;
    output Purity purity;
  algorithm
    purity := match call
      case TYPED_CALL() then call.purity;
      case TYPED_ARRAY_CONSTRUCTOR() then call.purity;
      case TYPED_REDUCTION() then call.purity;
      else Purity.PURE;
    end match;
  end purity;

  function compare
    input NFCall call1;
    input NFCall call2;
    output Integer comp;
  algorithm
    comp := match (call1, call2)
      case (UNTYPED_CALL(), UNTYPED_CALL())
        then ComponentRef.compare(call1.ref, call2.ref);

      case (TYPED_CALL(), TYPED_CALL())
        then AbsynUtil.pathCompare(Function.name(call1.fn), Function.name(call2.fn));

      case (UNTYPED_CALL(), TYPED_CALL())
        then AbsynUtil.pathCompare(ComponentRef.toPath(call1.ref), Function.name(call2.fn));

      case (TYPED_CALL(), UNTYPED_CALL())
        then AbsynUtil.pathCompare(Function.name(call1.fn), ComponentRef.toPath(call2.ref));
    end match;

    if comp == 0 then
      comp := Expression.compareList(arguments(call1), arguments(call2));
    end if;
  end compare;

  function isExternal
    input NFCall call;
    output Boolean isExternal;
  algorithm
    isExternal := match call
      case UNTYPED_CALL() then Class.isExternalFunction(InstNode.getClass(ComponentRef.node(call.ref)));
      case ARG_TYPED_CALL() then Class.isExternalFunction(InstNode.getClass(ComponentRef.node(call.ref)));
      case TYPED_CALL() then Function.isExternal(call.fn);
      else false;
    end match;
  end isExternal;

  function isImpure
    input NFCall call;
    output Boolean isImpure;
  algorithm
    isImpure := match call
      case UNTYPED_CALL() then Function.isImpure(listHead(Function.getRefCache(call.ref)));
      case TYPED_CALL(purity = Purity.IMPURE) then Function.isImpure(call.fn) or Function.isOMImpure(call.fn);
      else false;
    end match;
  end isImpure;

  function isRecordConstructor
    input NFCall call;
    output Boolean isConstructor;
  algorithm
    isConstructor := match call
      case UNTYPED_CALL()
        then SCodeUtil.isRecord(InstNode.definition(ComponentRef.node(call.ref)));
      case TYPED_CALL()
        then SCodeUtil.isRecord(InstNode.definition(call.fn.node));
      else false;
    end match;
  end isRecordConstructor;

  function isExternalObjectConstructor
    input NFCall call;
    output Boolean isConstructor;
  algorithm
    isConstructor := match call
      // Only constructors may return external objects...
      case TYPED_CALL()
        then Type.isExternalObject(call.ty);
      else false;
    end match;
  end isExternalObjectConstructor;

  function inlineType
    input NFCall call;
    output DAE.InlineType inlineTy;
  algorithm
    inlineTy := match call
      case TYPED_CALL(attributes = NFCallAttributes.CALL_ATTR(inlineType = inlineTy))
        then inlineTy;
      else DAE.InlineType.NO_INLINE();
    end match;
  end inlineType;

  function typedFunction
    input NFCall call;
    output Function fn;
  algorithm
    fn := match call
      case TYPED_CALL() then call.fn;
      case TYPED_ARRAY_CONSTRUCTOR() then NFBuiltinFuncs.ARRAY_FUNC;
      case TYPED_REDUCTION() then call.fn;
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got untyped function", sourceInfo());
        then
          fail();
    end match;
  end typedFunction;

  function functionName
    input NFCall call;
    output Absyn.Path name;
  algorithm
    name := match call
      case UNTYPED_CALL() then ComponentRef.toPath(call.ref);
      case ARG_TYPED_CALL() then ComponentRef.toPath(call.ref);
      case TYPED_CALL() then Function.name(call.fn);
      case UNTYPED_ARRAY_CONSTRUCTOR() then Absyn.IDENT("array");
      case TYPED_ARRAY_CONSTRUCTOR() then Absyn.IDENT("array");
      case UNTYPED_REDUCTION() then ComponentRef.toPath(call.ref);
      case TYPED_REDUCTION() then Function.name(call.fn);
    end match;
  end functionName;

  function isNamed
    input Call call;
    input String name;
    output Boolean res;
  protected
    Absyn.Path path;
  algorithm
    path := functionName(call);

    res := match path
      case Absyn.IDENT() then path.name == name;
      else false;
    end match;
  end isNamed;

  function arguments
    input NFCall call;
    output list<Expression> arguments;
  algorithm
    arguments := match call
      case UNTYPED_CALL() then call.arguments;
      case TYPED_CALL() then call.arguments;
    end match;
  end arguments;

  function toRecordExpression
    input NFCall call;
    input Type ty;
    output Expression exp;
  algorithm
    exp := match call
      case TYPED_CALL()
        then EvalFunction.evaluateRecordConstructor(call.fn, ty, call.arguments, evaluate = false);

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown call", sourceInfo());
        then
          fail();

    end match;
  end toRecordExpression;

  function toString
    input NFCall call;
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
          arg_str :=
          stringDelimitList(list(Expression.toString(arg.value) for arg in call.positional_args), ", ");
          for arg in call.named_args loop
            c := if arg_str == "" then "" else ", ";
            arg_str := arg_str + c + Util.getOption(arg.name) + " = " + Expression.toString(arg.value);
          end for;
        then
          name + "(" + arg_str + ")";

      case UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          name := AbsynUtil.pathString(Function.nameConsiderBuiltin(NFBuiltinFuncs.ARRAY_FUNC));
          arg_str := Expression.toString(call.exp);
          c := stringDelimitList(list(InstNode.name(Util.tuple21(iter)) + " in " +
            Expression.toString(Util.tuple22(iter)) for iter in call.iters), ", ");
        then
          "{" + arg_str + " for " + c + "}";

      case UNTYPED_REDUCTION()
        algorithm
          name := ComponentRef.toString(call.ref);
          arg_str := Expression.toString(call.exp);
          c := stringDelimitList(list(InstNode.name(Util.tuple21(iter)) + " in " +
            Expression.toString(Util.tuple22(iter)) for iter in call.iters), ", ");
        then
          name + "(" + arg_str + " for " + c + ")";

      case TYPED_CALL()
        algorithm
          name := AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn));
          arg_str := stringDelimitList(list(Expression.toString(arg) for arg in call.arguments), ", ");
        then
          name + "(" + arg_str + ")";

      case TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          name := AbsynUtil.pathString(Function.nameConsiderBuiltin(NFBuiltinFuncs.ARRAY_FUNC));
          arg_str := Expression.toString(call.exp);
          c := stringDelimitList(list(InstNode.name(Util.tuple21(iter)) + " in " +
            Expression.toString(Util.tuple22(iter)) for iter in call.iters), ", ");
        then
          "{" + arg_str + " for " + c + "}";

      case TYPED_REDUCTION()
        algorithm
          name := AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn));
          arg_str := Expression.toString(call.exp);
          c := stringDelimitList(list(InstNode.name(Util.tuple21(iter)) + " in " +
            Expression.toString(Util.tuple22(iter)) for iter in call.iters), ", ");
        then
          name + "(" + arg_str + " for " + c + ")";

    end match;
  end toString;

  function toFlatString
    input NFCall call;
    output String str;
  protected
    String name, arg_str,c;
    Expression argexp;
    list<InstNode> iters;
  algorithm
    str := match call
      case TYPED_CALL()
        algorithm
          name := AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn));
          arg_str := stringDelimitList(list(Expression.toFlatString(arg) for arg in call.arguments), ", ");
        then
          if Function.isBuiltin(call.fn) then
            stringAppendList({name, "(", arg_str, ")"})
          elseif isExternalObjectConstructor(call) then
            stringAppendList({Type.toFlatString(call.ty), "(", arg_str, ")"})
          else
            stringAppendList({Util.makeQuotedIdentifier(name), "(", arg_str, ")"});

      case TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          if isVectorized(call) then
            // Vectorized calls contains iterators with illegal Modelica names
            // (to avoid name conflicts), to make the flat output legal such
            // calls are reverted to their original form here.
            str := toFlatString(devectorizeCall(call));
          else
            name := AbsynUtil.pathString(Function.nameConsiderBuiltin(NFBuiltinFuncs.ARRAY_FUNC));
            arg_str := Expression.toFlatString(call.exp);
            c := stringDelimitList(list(InstNode.name(Util.tuple21(iter)) + " in " +
              Expression.toFlatString(Util.tuple22(iter)) for iter in call.iters), ", ");
            str := stringAppendList({"{", arg_str, " for ", c, "}"});
          end if;
        then
          str;

      case TYPED_REDUCTION()
        algorithm
          name := AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn));
          arg_str := Expression.toFlatString(call.exp);
          c := stringDelimitList(list(InstNode.name(Util.tuple21(iter)) + " in " +
            Expression.toFlatString(Util.tuple22(iter)) for iter in call.iters), ", ");
        then
          if Function.isBuiltin(call.fn) then
            stringAppendList({name, "(", arg_str, " for ", c, ")"})
          else
            stringAppendList({Util.makeQuotedIdentifier(name), "(", arg_str, " for ", c, ")"});

    end match;
  end toFlatString;

  function typedString
    "Like toString, but prefixes each argument with its type as a comment."
    input NFCall call;
    output String str;
  protected
    String name, arg_str,c;
    Expression argexp;
  algorithm
    str := match call
      case ARG_TYPED_CALL()
        algorithm
          name := ComponentRef.toString(call.ref);
          arg_str := stringDelimitList(list("/*" + Type.toString(arg.ty) + "*/ " +
            Expression.toString(arg.value) for arg in call.positional_args), ", ");

          for arg in call.named_args loop
            c := if arg_str == "" then "" else ", ";
            arg_str := arg_str + c + Util.getOption(arg.name) + " = /*" +
              Type.toString(arg.ty) + "*/ " + Expression.toString(arg.value);
          end for;
        then
          name + "(" + arg_str + ")";

      case TYPED_CALL()
        algorithm
          name := AbsynUtil.pathString(Function.name(call.fn));
          arg_str := stringDelimitList(list(Expression.toStringTyped(arg) for arg in call.arguments), ", ");
        then
          name + "(" + arg_str + ")";

      else toString(call);
    end match;
  end typedString;

  function toAbsyn
    input Call call;
    output Absyn.Exp absynCall;
  algorithm
    absynCall := match call
      local
        list<Absyn.Exp> pargs;
        list<Absyn.NamedArg> nargs;

      case UNTYPED_CALL()
        algorithm
          pargs := list(Expression.toAbsyn(arg) for arg in call.arguments);
          nargs := list(Absyn.NamedArg.NAMEDARG(Util.tuple21(arg),
            Expression.toAbsyn(Util.tuple22(arg))) for arg in call.named_args);
        then
          AbsynUtil.makeCall(ComponentRef.toAbsyn(call.ref), pargs, nargs);

      case ARG_TYPED_CALL()
        algorithm
          pargs := list(Expression.toAbsyn(arg.value) for arg in call.positional_args);
          nargs := list(Absyn.NamedArg.NAMEDARG(Util.getOption(arg.name),
            Expression.toAbsyn(arg.value)) for arg in call.named_args);
        then
          AbsynUtil.makeCall(ComponentRef.toAbsyn(call.ref), pargs, nargs);

      case TYPED_CALL()
        algorithm
          pargs := list(Expression.toAbsyn(arg) for arg in call.arguments);
        then
          AbsynUtil.makeCall(AbsynUtil.pathToCref(Function.name(call.fn)), pargs);

      case UNTYPED_ARRAY_CONSTRUCTOR()
        then Absyn.Exp.CALL(Absyn.ComponentRef.CREF_IDENT("array", {}), toAbsynIterators(call.exp, call.iters), {});

      case TYPED_ARRAY_CONSTRUCTOR()
        then Absyn.Exp.CALL(Absyn.ComponentRef.CREF_IDENT("array", {}), toAbsynIterators(call.exp, call.iters), {});

      case UNTYPED_REDUCTION()
        then Absyn.Exp.CALL(ComponentRef.toAbsyn(call.ref), toAbsynIterators(call.exp, call.iters), {});

      case TYPED_REDUCTION()
        then Absyn.Exp.CALL(AbsynUtil.pathToCref(Function.name(call.fn)), toAbsynIterators(call.exp, call.iters), {});

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown call", sourceInfo());
        then
          fail();
    end match;
  end toAbsyn;

  function toAbsynIterators
    input Expression iterExp;
    input list<tuple<InstNode, Expression>> iters;
    output Absyn.FunctionArgs args;
  algorithm
    args := Absyn.FunctionArgs.FOR_ITER_FARG(
      Expression.toAbsyn(iterExp),
      Absyn.ReductionIterType.COMBINE(),
      list(Absyn.ForIterator.ITERATOR(
          InstNode.name(Util.tuple21(i)),
          NONE(),
          SOME(Expression.toAbsyn(Util.tuple22(i)))
        ) for i in iters));
  end toAbsynIterators;

  function toDAE
    input NFCall call;
    output DAE.Exp daeCall;
  algorithm
    // The code generation can't handle reductions/array constructors with
    // multiple iterators so we need to convert them to nested calls with one
    // iterator each. But the frontend can handle multiple iterators more
    // efficiently so we do it only just before passing them to the backend.
    daeCall := toDAE_work(expandReduction(call));
  end toDAE;

  function toDAE_work
    input NFCall call;
    output DAE.Exp daeCall;
  algorithm
    daeCall := match call
      local
        String fold_id, res_id;
        Option<Expression> fold_exp;

      case TYPED_CALL()
        then DAE.CALL(
          Function.nameConsiderBuiltin(call.fn),
          list(Expression.toDAE(e) for e in call.arguments),
          NFCallAttributes.toDAE(call.attributes, call.ty));

      case TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          fold_id := Util.getTempVariableIndex();
          res_id := Util.getTempVariableIndex();
        then
          DAE.REDUCTION(
            DAE.REDUCTIONINFO(
              Function.name(NFBuiltinFuncs.ARRAY_FUNC),
              Absyn.COMBINE(),
              Type.toDAE(call.ty),
              NONE(),
              fold_id,
              res_id,
              NONE()),
            Expression.toDAE(call.exp),
            list(iteratorToDAE(iter) for iter in call.iters));

      case TYPED_REDUCTION()
        algorithm
          (fold_exp, fold_id, res_id) := call.foldExp;
        then
          DAE.REDUCTION(
            DAE.REDUCTIONINFO(
              Function.name(call.fn),
              Absyn.COMBINE(),
              Type.toDAE(call.ty),
              Expression.toDAEValueOpt(call.defaultExp),
              fold_id,
              res_id,
              Expression.toDAEOpt(fold_exp)),
            Expression.toDAE(call.exp),
            list(iteratorToDAE(iter) for iter in call.iters));

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got untyped call", sourceInfo());
        then
          fail();
    end match;
  end toDAE_work;

  function expandReduction
    "Turns reductions/array constructors with multiple iterators into nested
     reductions/array constructors."
    input Call call;
    output Call outCall;
  algorithm
    outCall := match call
      local
        list<tuple<InstNode, Expression>> iters;
        tuple<InstNode, Expression> iter;
        Type ty;

      case TYPED_ARRAY_CONSTRUCTOR(iters = iters)
        guard listLength(iters) > 1
        algorithm
          iter :: iters := iters;
          ty := Type.liftArrayLeftList(Expression.typeOf(call.exp),
            Type.arrayDims(Expression.typeOf(Util.tuple22(iter))));
          outCall := TYPED_ARRAY_CONSTRUCTOR(ty, call.var, call.purity, call.exp, {iter});

          for i in iters loop
            ty := Type.liftArrayLeftList(ty, Type.arrayDims(Expression.typeOf(Util.tuple22(i))));
            outCall := TYPED_ARRAY_CONSTRUCTOR(ty, call.var, call.purity, Expression.CALL(outCall), {i});
          end for;
        then
          outCall;

      case TYPED_REDUCTION(iters = iters)
        guard listLength(iters) > 1
        algorithm
          iter :: iters := iters;
          outCall := makeTypedReduction(call.fn, call.ty, call.var, call.purity,
            call.exp, {iter}, AbsynUtil.dummyInfo);

          for i in iters loop
            outCall := makeTypedReduction(call.fn, call.ty, call.var, call.purity,
              Expression.CALL(outCall), {i}, AbsynUtil.dummyInfo);
          end for;
        then
          outCall;

      else call;
    end match;
  end expandReduction;

  function isVectorizeable
    input NFCall call;
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

  function retype
    input output NFCall call;
  algorithm
    () := match call
      local
        Type ty;
        list<Dimension> dims;

      case TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          dims := {};

          for i in listReverse(call.iters) loop
            dims := listAppend(Type.arrayDims(Expression.typeOf(Util.tuple22(i))), dims);
          end for;

          call.ty := Type.liftArrayLeftList(Type.arrayElementType(call.ty), dims);
        then
          ();

      else ();
    end match;
  end retype;

  function typeCast
    input output Expression callExp;
    input Type ty;
  protected
    NFCall call;
    Type cast_ty;
  algorithm
    Expression.CALL(call = call) := callExp;

    callExp := match call
      case TYPED_CALL() guard Function.isBuiltin(call.fn)
        algorithm
          cast_ty := Type.setArrayElementType(call.ty, ty);
        then
          match AbsynUtil.pathFirstIdent(Function.name(call.fn))
            // For 'fill' we can type cast the first argument rather than the
            // whole array that 'fill' constructs.
            case "fill"
              algorithm
                call.arguments := Expression.typeCast(listHead(call.arguments), ty) ::
                                  listRest(call.arguments);
                call.ty := cast_ty;
              then
                Expression.CALL(call);

            // For diagonal we can type cast the argument rather than the
            // matrix that diagonal constructs.
            case "diagonal"
              algorithm
                call.arguments := {Expression.typeCast(listHead(call.arguments), ty)};
                call.ty := cast_ty;
              then
                Expression.CALL(call);

            else Expression.CAST(cast_ty, callExp);
          end match;

      else Expression.CAST(Type.setArrayElementType(typeOf(call), ty), callExp);
    end match;
  end typeCast;

  function containsExp
    input Call call;
    input ContainsPred func;
    output Boolean res;

    partial function ContainsPred
      input Expression exp;
      output Boolean res;
    end ContainsPred;
  algorithm
    res := match call
      local
        Expression e;

      case UNTYPED_CALL()
        algorithm
          res := Expression.listContains(call.arguments, func);

          if not res then
            for arg in call.named_args loop
              (_, e) := arg;

              if Expression.contains(e, func) then
                res := true;
                break;
              end if;
            end for;
          end if;
        then
          res;

      case ARG_TYPED_CALL()
        algorithm
          for arg in call.positional_args loop
            if Expression.contains(arg.value, func) then
              res := true;
              return;
            end if;
          end for;

          for arg in call.named_args loop
            if Expression.contains(arg.value, func) then
              res := true;
              return;
            end if;
          end for;
        then
          false;

      case TYPED_CALL() then Expression.listContains(call.arguments, func);
      case UNTYPED_ARRAY_CONSTRUCTOR() then Expression.contains(call.exp, func);
      case TYPED_ARRAY_CONSTRUCTOR() then Expression.contains(call.exp, func);
      case UNTYPED_REDUCTION() then Expression.contains(call.exp, func);
      case TYPED_REDUCTION() then Expression.contains(call.exp, func);
    end match;
  end containsExp;

  function containsExpShallow
    input Call call;
    input ContainsPred func;
    output Boolean res;

    partial function ContainsPred
      input Expression exp;
      output Boolean res;
    end ContainsPred;
  algorithm
    res := match call
      local
        Expression e;

      case UNTYPED_CALL()
        algorithm
          res := Expression.listContainsShallow(call.arguments, func);

          if not res then
            for arg in call.named_args loop
              (_, e) := arg;

              if func(e) then
                res := true;
                break;
              end if;
            end for;
          end if;
        then
          res;

      case ARG_TYPED_CALL()
        algorithm
          for arg in call.positional_args loop
            if func(arg.value) then
              res := true;
              return;
            end if;
          end for;

          for arg in call.named_args loop
            if func(arg.value) then
              res := true;
              return;
            end if;
          end for;
        then
          false;

      case TYPED_CALL() then Expression.listContainsShallow(call.arguments, func);
      case UNTYPED_ARRAY_CONSTRUCTOR() then func(call.exp);
      case TYPED_ARRAY_CONSTRUCTOR() then func(call.exp);
      case UNTYPED_REDUCTION() then func(call.exp);
      case TYPED_REDUCTION() then func(call.exp);
    end match;
  end containsExpShallow;

  function applyExp
    input Call call;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match call
      local
        Expression e;

      case UNTYPED_CALL()
        algorithm
          Expression.applyList(call.arguments, func);

          for arg in call.named_args loop
            (_, e) := arg;
            Expression.apply(e, func);
          end for;
        then
          ();

      case ARG_TYPED_CALL()
        algorithm
          for arg in call.positional_args loop
            Expression.apply(arg.value, func);
          end for;

          for arg in call.named_args loop
            Expression.apply(arg.value, func);
          end for;
        then
          ();

      case TYPED_CALL()
        algorithm
          Expression.applyList(call.arguments, func);
        then
          ();

      case UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          Expression.apply(call.exp, func);

          for i in call.iters loop
            Expression.apply(Util.tuple22(i), func);
          end for;
        then
          ();

      case TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          Expression.apply(call.exp, func);

          for i in call.iters loop
            Expression.apply(Util.tuple22(i), func);
          end for;
        then
          ();

      case UNTYPED_REDUCTION()
        algorithm
          Expression.apply(call.exp, func);

          for i in call.iters loop
            Expression.apply(Util.tuple22(i), func);
          end for;
        then
          ();

      case TYPED_REDUCTION()
        algorithm
          Expression.apply(call.exp, func);

          for i in call.iters loop
            Expression.apply(Util.tuple22(i), func);
          end for;

          Expression.applyOpt(call.defaultExp, func);
          Expression.applyOpt(Util.tuple31(call.foldExp), func);
        then
          ();
    end match;
  end applyExp;

  function applyExpShallow
    input Call call;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match call
      local
        Expression e;

      case UNTYPED_CALL()
        algorithm
          Expression.applyListShallow(call.arguments, func);

          for arg in call.named_args loop
            (_, e) := arg;
            func(e);
          end for;
        then
          ();

      case ARG_TYPED_CALL()
        algorithm
          for arg in call.positional_args loop
            func(arg.value);
          end for;

          for arg in call.named_args loop
            func(arg.value);
          end for;
        then
          ();

      case TYPED_CALL()
        algorithm
          Expression.applyListShallow(call.arguments, func);
        then
          ();

      case UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          func(call.exp);

          for i in call.iters loop
            func(Util.tuple22(i));
          end for;
        then
          ();

      case TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          func(call.exp);

          for i in call.iters loop
            func(Util.tuple22(i));
          end for;
        then
          ();

      case UNTYPED_REDUCTION()
        algorithm
          func(call.exp);

          for i in call.iters loop
            func(Util.tuple22(i));
          end for;
        then
          ();

      case TYPED_REDUCTION()
        algorithm
          func(call.exp);

          for i in call.iters loop
            func(Util.tuple22(i));
          end for;

          Expression.applyShallowOpt(call.defaultExp, func);
          Expression.applyShallowOpt(Util.tuple31(call.foldExp), func);
        then
          ();
    end match;
  end applyExpShallow;

  function foldExp<ArgT>
    input Call call;
    input FoldFunc func;
    input output ArgT foldArg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    () := match call
      local
        Expression e;

      case UNTYPED_CALL()
        algorithm
          foldArg := Expression.foldList(call.arguments, func, foldArg);

          for arg in call.named_args loop
            (_, e) := arg;
            foldArg := Expression.fold(e, func, foldArg);
          end for;
        then
          ();

      case ARG_TYPED_CALL()
        algorithm
          for arg in call.positional_args loop
            foldArg := Expression.fold(arg.value, func, foldArg);
          end for;

          for arg in call.named_args loop
            foldArg := Expression.fold(arg.value, func, foldArg);
          end for;
        then
          ();

      case TYPED_CALL()
        algorithm
          foldArg := Expression.foldList(call.arguments, func, foldArg);
        then
          ();

      case UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          foldArg := Expression.fold(call.exp, func, foldArg);

          for i in call.iters loop
            foldArg := Expression.fold(Util.tuple22(i), func, foldArg);
          end for;
        then
          ();

      case TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          foldArg := Expression.fold(call.exp, func, foldArg);

          for i in call.iters loop
            foldArg := Expression.fold(Util.tuple22(i), func, foldArg);
          end for;
        then
          ();

      case UNTYPED_REDUCTION()
        algorithm
          foldArg := Expression.fold(call.exp, func, foldArg);

          for i in call.iters loop
            foldArg := Expression.fold(Util.tuple22(i), func, foldArg);
          end for;
        then
          ();

      case TYPED_REDUCTION()
        algorithm
          foldArg := Expression.fold(call.exp, func, foldArg);

          for i in call.iters loop
            foldArg := Expression.fold(Util.tuple22(i), func, foldArg);
          end for;

          foldArg := Expression.foldOpt(call.defaultExp, func, foldArg);
          foldArg := Expression.foldOpt(Util.tuple31(call.foldExp), func, foldArg);
        then
          ();
    end match;
  end foldExp;

  function mapExp
    input Call call;
    input MapFunc func;
    output Call outCall;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  algorithm
    outCall := match call
      local
        list<Expression> args;
        list<NamedArg> nargs;
        list<TypedArg> targs, tnargs;
        String s;
        Expression e;
        list<tuple<InstNode, Expression>> iters;
        Option<Expression> default_exp;
        tuple<Option<Expression>, String, String> fold_exp;

      case UNTYPED_CALL()
        algorithm
          args := list(Expression.map(arg, func) for arg in call.arguments);
          nargs := {};

          for arg in call.named_args loop
            (s, e) := arg;
            e := Expression.map(e, func);
            nargs := (s, e) :: nargs;
          end for;
        then
          UNTYPED_CALL(call.ref, args, listReverse(nargs), call.call_scope);

      case ARG_TYPED_CALL()
        algorithm
          targs := {};
          tnargs := {};

          for arg in call.positional_args loop
            arg.value := Expression.map(arg.value, func);
            targs := arg :: targs;
          end for;

          for arg in call.named_args loop
            arg.value := Expression.map(arg.value, func);
            tnargs := arg :: tnargs;
          end for;
        then
          ARG_TYPED_CALL(call.ref, listReverse(targs), listReverse(tnargs), call.call_scope);

      case TYPED_CALL()
        algorithm
          args := list(Expression.map(arg, func) for arg in call.arguments);
        then
          TYPED_CALL(call.fn, call.ty, call.var, call.purity, args, call.attributes);

      case UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          e := Expression.map(call.exp, func);
          iters := mapIteratorsExp(call.iters, func);
        then
          UNTYPED_ARRAY_CONSTRUCTOR(e, iters);

      case TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          e := Expression.map(call.exp, func);
          iters := mapIteratorsExp(call.iters, func);
        then
          TYPED_ARRAY_CONSTRUCTOR(call.ty, call.var, call.purity, e, iters);

      case UNTYPED_REDUCTION()
        algorithm
          e := Expression.map(call.exp, func);
          iters := mapIteratorsExp(call.iters, func);
        then
          UNTYPED_REDUCTION(call.ref, e, iters);

      case TYPED_REDUCTION()
        algorithm
          e := Expression.map(call.exp, func);
          iters := mapIteratorsExp(call.iters, func);
          default_exp := Expression.mapOpt(call.defaultExp, func);
          fold_exp := Util.applyTuple31(call.foldExp, function Expression.mapOpt(func = func));
        then
          TYPED_REDUCTION(call.fn, call.ty, call.var, call.purity, e, iters, default_exp, fold_exp);

    end match;
  end mapExp;

  function mapIteratorsExp
    input list<tuple<InstNode, Expression>> iters;
    input MapFunc func;
    output list<tuple<InstNode, Expression>> outIters = {};

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  protected
    InstNode node;
    Expression exp, new_exp;
  algorithm
    for i in iters loop
      (node, exp) := i;
      new_exp := Expression.map(exp, func);
      outIters := (if referenceEq(new_exp, exp) then i else (node, new_exp)) :: outIters;
    end for;

    outIters := listReverseInPlace(outIters);
  end mapIteratorsExp;

  function mapExpShallow
    input Call call;
    input MapFunc func;
    output Call outCall;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  algorithm
    outCall := match call
      local
        list<Expression> args;
        list<NamedArg> nargs;
        list<TypedArg> targs, tnargs;
        String s;
        Expression e;
        list<tuple<InstNode, Expression>> iters;
        Option<Expression> default_exp;
        tuple<Option<Expression>, String, String> fold_exp;

      case UNTYPED_CALL()
        algorithm
          args := list(func(arg) for arg in call.arguments);
          nargs := {};

          for arg in call.named_args loop
            (s, e) := arg;
            e := func(e);
            nargs := (s, e) :: nargs;
          end for;
        then
          UNTYPED_CALL(call.ref, args, listReverse(nargs), call.call_scope);

      case ARG_TYPED_CALL()
        algorithm
          targs := {};
          tnargs := {};

          for arg in call.positional_args loop
            arg.value := func(arg.value);
            targs := arg :: targs;
          end for;

          for arg in call.named_args loop
            arg.value := func(arg.value);
            tnargs := arg :: tnargs;
          end for;
        then
          ARG_TYPED_CALL(call.ref, listReverse(targs), listReverse(tnargs), call.call_scope);

      case TYPED_CALL()
        algorithm
          args := list(func(arg) for arg in call.arguments);
        then
          TYPED_CALL(call.fn, call.ty, call.var, call.purity, args, call.attributes);

      case UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          e := func(call.exp);
        then
          UNTYPED_ARRAY_CONSTRUCTOR(e, call.iters);

      case TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          e := func(call.exp);
        then
          TYPED_ARRAY_CONSTRUCTOR(call.ty, call.var, call.purity, e, call.iters);

      case UNTYPED_REDUCTION()
        algorithm
          e := func(call.exp);
        then
          UNTYPED_REDUCTION(call.ref, e, call.iters);

      case TYPED_REDUCTION()
        algorithm
          e := func(call.exp);
          iters := mapIteratorsExpShallow(call.iters, func);
          default_exp := Expression.mapShallowOpt(call.defaultExp, func);
          fold_exp := Util.applyTuple31(call.foldExp, function Expression.mapShallowOpt(func = func));
        then
          TYPED_REDUCTION(call.fn, call.ty, call.var, call.purity, e, iters, default_exp, fold_exp);

    end match;
  end mapExpShallow;

  function mapIteratorsExpShallow
    input list<tuple<InstNode, Expression>> iters;
    input MapFunc func;
    output list<tuple<InstNode, Expression>> outIters = {};

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  protected
    InstNode node;
    Expression exp, new_exp;
  algorithm
    for i in iters loop
      (node, exp) := i;
      new_exp := func(exp);
      outIters := (if referenceEq(new_exp, exp) then i else (node, new_exp)) :: outIters;
    end for;

    outIters := listReverseInPlace(outIters);
  end mapIteratorsExpShallow;

  function mapFoldExp<ArgT>
    input Call call;
    input MapFunc func;
          output Call outCall;
    input output ArgT foldArg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  algorithm
    outCall := match call
      local
        list<Expression> args;
        list<NamedArg> nargs;
        list<TypedArg> targs, tnargs;
        String s;
        Expression e;
        list<tuple<InstNode, Expression>> iters;
        Option<Expression> default_exp;
        tuple<Option<Expression>, String, String> fold_exp;
        Option<Expression> oe;

      case UNTYPED_CALL()
        algorithm
          (args, foldArg) := List.map1Fold(call.arguments, Expression.mapFold, func, foldArg);
          nargs := {};

          for arg in call.named_args loop
            (s, e) := arg;
            (e, foldArg) := Expression.mapFold(e, func, foldArg);
            nargs := (s, e) :: nargs;
          end for;
        then
          UNTYPED_CALL(call.ref, args, listReverse(nargs), call.call_scope);

      case ARG_TYPED_CALL()
        algorithm
          targs := {};
          tnargs := {};

          for arg in call.positional_args loop
            (e, foldArg) := Expression.mapFold(arg.value, func, foldArg);
            arg.value := e;
            targs := arg :: targs;
          end for;

          for arg in call.named_args loop
            (e, foldArg) := Expression.mapFold(arg.value, func, foldArg);
            arg.value := e;
            targs := arg :: targs;
          end for;
        then
          ARG_TYPED_CALL(call.ref, listReverse(targs), listReverse(tnargs), call.call_scope);

      case TYPED_CALL()
        algorithm
          (args, foldArg) := List.map1Fold(call.arguments, Expression.mapFold, func, foldArg);
        then
          TYPED_CALL(call.fn, call.ty, call.var, call.purity, args, call.attributes);

      case UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          (e, foldArg) := Expression.mapFold(call.exp, func, foldArg);
          (iters, foldArg) := mapFoldIteratorsExp(call.iters, func, foldArg);
        then
          UNTYPED_ARRAY_CONSTRUCTOR(e, iters);

      case TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          (e, foldArg) := Expression.mapFold(call.exp, func, foldArg);
          (iters, foldArg) := mapFoldIteratorsExp(call.iters, func, foldArg);
        then
          TYPED_ARRAY_CONSTRUCTOR(call.ty, call.var, call.purity, e, iters);

      case UNTYPED_REDUCTION()
        algorithm
          (e, foldArg) := Expression.mapFold(call.exp, func, foldArg);
          (iters, foldArg) := mapFoldIteratorsExp(call.iters, func, foldArg);
        then
          UNTYPED_REDUCTION(call.ref, e, iters);

      case TYPED_REDUCTION()
        algorithm
          (e, foldArg) := Expression.mapFold(call.exp, func, foldArg);
          (iters, foldArg) := mapFoldIteratorsExp(call.iters, func, foldArg);
          (default_exp, foldArg) := Expression.mapFoldOpt(call.defaultExp, func, foldArg);
          oe := Util.tuple31(call.foldExp);

          if isSome(oe) then
            (oe, foldArg) := Expression.mapFoldOpt(oe, func, foldArg);
            fold_exp := Util.applyTuple31(call.foldExp, function Util.replace(arg = oe));
          else
            fold_exp := call.foldExp;
          end if;
        then
          TYPED_REDUCTION(call.fn, call.ty, call.var, call.purity, e, iters, default_exp, fold_exp);
    end match;
  end mapFoldExp;

  function mapFoldIteratorsExp<ArgT>
    input list<tuple<InstNode, Expression>> iters;
    input MapFunc func;
          output list<tuple<InstNode, Expression>> outIters = {};
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  protected
    InstNode node;
    Expression exp, new_exp;
  algorithm
    for i in iters loop
      (node, exp) := i;
      (new_exp, arg) := Expression.mapFold(exp, func, arg);
      outIters := (if referenceEq(new_exp, exp) then i else (node, new_exp)) :: outIters;
    end for;

    outIters := listReverseInPlace(outIters);
  end mapFoldIteratorsExp;

  function mapFoldExpShallow<ArgT>
    input Call call;
    input MapFunc func;
          output Call outCall;
    input output ArgT foldArg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  algorithm
    outCall := match call
      local
        list<Expression> args;
        list<NamedArg> nargs;
        list<TypedArg> targs, tnargs;
        String s;
        Expression e;
        list<tuple<InstNode, Expression>> iters;
        Option<Expression> default_exp;
        tuple<Option<Expression>, String, String> fold_exp;
        Option<Expression> oe;

      case UNTYPED_CALL()
        algorithm
          (args, foldArg) := List.mapFold(call.arguments, func, foldArg);
          nargs := {};

          for arg in call.named_args loop
            (s, e) := arg;
            (e, foldArg) := func(e, foldArg);
            nargs := (s, e) :: nargs;
          end for;
        then
          UNTYPED_CALL(call.ref, args, listReverse(nargs), call.call_scope);

      case ARG_TYPED_CALL()
        algorithm
          targs := {};
          tnargs := {};

          for arg in call.positional_args loop
            (e, foldArg) := func(arg.value, foldArg);
            arg.value := e;
            targs := arg :: targs;
          end for;

          for arg in call.named_args loop
            (e, foldArg) := func(arg.value, foldArg);
            arg.value := e;
            targs := arg :: targs;
          end for;
        then
          ARG_TYPED_CALL(call.ref, listReverse(targs), listReverse(tnargs), call.call_scope);

      case TYPED_CALL()
        algorithm
          (args, foldArg) := List.mapFold(call.arguments, func, foldArg);
        then
          TYPED_CALL(call.fn, call.ty, call.var, call.purity, args, call.attributes);

      case UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          (e, foldArg) := func(call.exp, foldArg);
          iters := mapFoldIteratorsExpShallow(call.iters, func, foldArg);
        then
          UNTYPED_ARRAY_CONSTRUCTOR(e, iters);

      case TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          (e, foldArg) := func(call.exp, foldArg);
          iters := mapFoldIteratorsExpShallow(call.iters, func, foldArg);
        then
          TYPED_ARRAY_CONSTRUCTOR(call.ty, call.var, call.purity, e, iters);

      case UNTYPED_REDUCTION()
        algorithm
          (e, foldArg) := func(call.exp, foldArg);
          iters := mapFoldIteratorsExpShallow(call.iters, func, foldArg);
        then
          UNTYPED_REDUCTION(call.ref, e, iters);

      case TYPED_REDUCTION()
        algorithm
          (e, foldArg) := func(call.exp, foldArg);
          iters := mapFoldIteratorsExpShallow(call.iters, func, foldArg);
          (default_exp, foldArg) := Expression.mapFoldOptShallow(call.defaultExp, func, foldArg);
          oe := Util.tuple31(call.foldExp);

          if isSome(oe) then
            (oe, foldArg) := Expression.mapFoldOptShallow(oe, func, foldArg);
            fold_exp := Util.applyTuple31(call.foldExp, function Util.replace(arg = oe));
          else
            fold_exp := call.foldExp;
          end if;
        then
          TYPED_REDUCTION(call.fn, call.ty, call.var, call.purity, e, iters, default_exp, fold_exp);

    end match;
  end mapFoldExpShallow;

  function mapFoldIteratorsExpShallow<ArgT>
    input list<tuple<InstNode, Expression>> iters;
    input MapFunc func;
          output list<tuple<InstNode, Expression>> outIters = {};
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  protected
    InstNode node;
    Expression exp, new_exp;
  algorithm
    for i in iters loop
      (node, exp) := i;
      (new_exp, arg) := func(exp, arg);
      outIters := (if referenceEq(new_exp, exp) then i else (node, new_exp)) :: outIters;
    end for;

    outIters := listReverseInPlace(outIters);
  end mapFoldIteratorsExpShallow;

protected
  function instNormalCall
    input Absyn.ComponentRef functionName;
    input Absyn.FunctionArgs functionArgs;
    input InstNode scope;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
  protected
    ComponentRef fn_ref;
    list<Expression> args;
    list<NamedArg> named_args;
    String name;
  algorithm

    name := AbsynUtil.crefFirstIdent(functionName);

    // try to inst the parameters
    try
      (args, named_args) := instArgs(functionArgs, scope, context, info);
    else
      // didn't work, is this DynamicSelect dynamic part?! #5631
      if Config.getGraphicsExpMode() and stringEq(name, "DynamicSelect") then
        // return just the first part of DynamicSelect
        callExp := match functionArgs
           case Absyn.FUNCTIONARGS() then
             Inst.instExp(listHead(functionArgs.args), scope, context, info);
        end match;
        return;
      else
        fail();
      end if;
    end try;

    callExp := match name
      // size creates Expression.SIZE instead of Expression.CALL.
      case "size" then BuiltinCall.makeSizeExp(args, named_args, info);
      // array() call with no iterators creates Expression.ARRAY instead of Expression.CALL.
      // If it had iterators then it will not reach here. The args would have been parsed to
      // Absyn.FOR_ITER_FARG and that is handled in instIteratorCall.
      case "array" then BuiltinCall.makeArrayExp(args, named_args, info);

      case _ guard InstContext.inGraphicalExp(context)
        algorithm
          // If we're in a graphic annotation expression, first try to find the
          // function in the top scope in case there's a user-defined function
          // with the same name. If it's not found, check the normal scope.
          try
            fn_ref := Function.instFunction(functionName, InstNode.topScope(scope), context, info);
          else
            fn_ref := Function.instFunction(functionName, scope, context, info);
          end try;
        then
          Expression.CALL(UNTYPED_CALL(fn_ref, args, named_args, scope));

      else
        algorithm
          fn_ref := Function.instFunction(functionName, scope, context, info);
        then
          Expression.CALL(UNTYPED_CALL(fn_ref, args, named_args, scope));

    end match;
  end instNormalCall;

  function instArgs
    input Absyn.FunctionArgs args;
    input InstNode scope;
    input InstContext.Type context;
    input SourceInfo info;
    output list<Expression> posArgs;
    output list<NamedArg> namedArgs;
  algorithm
    (posArgs, namedArgs) := match args
      case Absyn.FUNCTIONARGS()
        algorithm
          posArgs := list(Inst.instExp(a, scope, context, info) for a in args.args);
          namedArgs := list(instNamedArg(a, scope, context, info) for a in args.argNames);
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
    input InstContext.Type context;
    input SourceInfo info;
    output NamedArg arg;
  protected
    String name;
    Absyn.Exp exp;
  algorithm
    Absyn.NAMEDARG(argName = name, argValue = exp) := absynArg;
    arg := (name, Inst.instExp(exp, scope, context, info));
  end instNamedArg;

  function instIteratorCall
    input Absyn.ComponentRef functionName;
    input Absyn.FunctionArgs functionArgs;
    input InstNode scope;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression callExp;
  protected
    Absyn.ComponentRef fn_name;
    ComponentRef fn_ref;
    Expression exp;
    list<tuple<InstNode, Expression>> iters;
    Boolean is_array;
  algorithm
    // The parser turns {exp for i in ...} into $array(exp for i in ...), but we
    // change it to just array here so we can handle array constructors uniformly.
    fn_name := match functionName
      case Absyn.CREF_IDENT("$array") then Absyn.CREF_IDENT("array", {});
      else functionName;
    end match;

    (exp, iters) := instIteratorCallArgs(functionArgs, scope, context, info);

    if AbsynUtil.crefFirstIdent(fn_name) == "array" then
      callExp := Expression.CALL(UNTYPED_ARRAY_CONSTRUCTOR(exp, iters));
    else
      fn_ref := Function.instFunction(fn_name, scope, context, info);
      callExp := Expression.CALL(UNTYPED_REDUCTION(fn_ref, exp, iters));
    end if;
  end instIteratorCall;

  function instIteratorCallArgs
    input Absyn.FunctionArgs args;
    input InstNode scope;
    input InstContext.Type context;
    input SourceInfo info;
    output Expression exp;
    output list<tuple<InstNode, Expression>> iters;
  algorithm
    _ := match args
      local
        InstNode for_scope;

      case Absyn.FOR_ITER_FARG()
        algorithm
          (for_scope, iters) := instIterators(args.iterators, scope, context, info);
          exp := Inst.instExp(args.exp, for_scope, context, info);
        then
          ();
    end match;
  end instIteratorCallArgs;

  function instIterators
    input list<Absyn.ForIterator> inIters;
    input InstNode scope;
    input InstContext.Type context;
    input SourceInfo info;
    output InstNode outScope = scope;
    output list<tuple<InstNode, Expression>> outIters = {};
  protected
    Expression range;
    InstNode iter, range_node;
    Type ty;
  algorithm
    for i in inIters loop
      if isSome(i.range) then
        range := Inst.instExp(Util.getOption(i.range), outScope, context, info);
      else
        // Use an empty expression to indicate that the range is missing and
        // needs to be deduced during typing.
        range := Expression.EMPTY(Type.UNKNOWN());
      end if;

      // If the range is a cref, use it as the iterator type to allow lookup in
      // the iterator.
      ty := match range
        case Expression.CREF(cref = ComponentRef.CREF(node = range_node))
          guard InstNode.isComponent(range_node)
          then Type.COMPLEX(Component.classInstance(InstNode.component(range_node)), ComplexType.CLASS());
        else Type.UNKNOWN();
      end match;

      (outScope, iter) := Inst.addIteratorToScope(i.name, outScope, info, ty);
      outIters := (iter, range) :: outIters;
    end for;

    outIters := listReverse(outIters);
  end instIterators;

  function typeArrayConstructor
    input output NFCall call;
    input InstContext.Type context;
    input SourceInfo info;
          output Type ty;
          output Variability variability;
          output Purity purity;
  protected
    Expression arg, range;
    Type iter_ty;
    Variability iter_var, exp_var;
    Purity iter_pur, exp_pur;
    InstNode iter;
    list<Dimension> dims = {};
    list<tuple<InstNode, Expression>> iters = {};
    InstContext.Type next_context;
    Boolean is_structural;
  algorithm
    (call, ty, variability, purity) := match call
      case UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          variability := Variability.CONSTANT;
          purity := Purity.PURE;
          // The size of the expression must be known unless we're in a function.
          is_structural := not InstContext.inFunction(context);
          next_context := InstContext.set(context, NFInstContext.SUBEXPRESSION);

          for i in call.iters loop
            (iter, range) := i;

            if Expression.isEmpty(range) then
              range := Typing.deduceIterationRangeExp(Expression.CALL(call), iter, info);
            end if;

            (range, iter_ty, iter_var, iter_pur) := Typing.typeIterator(iter, range, next_context, is_structural);

            if is_structural then
              range := Ceval.evalExp(range, Ceval.EvalTarget.RANGE(info));
              iter_ty := Expression.typeOf(range);
            end if;

            dims := listAppend(Type.arrayDims(iter_ty), dims);
            variability := Prefixes.variabilityMax(variability, iter_var);
            purity := Prefixes.purityMin(purity, iter_pur);
            iters := (iter, range) :: iters;
          end for;
          iters := listReverseInPlace(iters);

          // InstContext.FOR is used here as a marker that this expression may contain iterators.
          next_context := InstContext.set(next_context, NFInstContext.FOR);
          (arg, ty, exp_var, exp_pur) := Typing.typeExp(call.exp, next_context, info);
          variability := Prefixes.variabilityMax(variability, exp_var);
          purity := Prefixes.purityMin(purity, exp_pur);
          ty := Type.liftArrayLeftList(ty, dims);
        then
          (TYPED_ARRAY_CONSTRUCTOR(ty, variability, purity, arg, iters), ty, variability, purity);

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got invalid function call expression", sourceInfo());
        then
          fail();
    end match;
  end typeArrayConstructor;

  function typeReduction
    input output NFCall call;
    input InstContext.Type context;
    input SourceInfo info;
          output Type ty;
          output Variability variability;
          output Purity purity;
  protected
    Expression range, arg;
    Option<Expression> default_exp, fold_exp;
    InstNode iter;
    Variability iter_var, exp_var;
    Purity iter_pur, exp_pur;
    list<tuple<InstNode, Expression>> iters = {};
    InstContext.Type next_context;
    Function fn;
    String fold_id, res_id;
    tuple<Option<Expression>, String, String> fold_tuple;
  algorithm
    (call, ty, variability, purity) := match call
      case UNTYPED_REDUCTION()
        algorithm
          variability := Variability.CONSTANT;
          purity := Purity.PURE;
          next_context := InstContext.set(context, NFInstContext.SUBEXPRESSION);

          for i in call.iters loop
            (iter, range) := i;

            if Expression.isEmpty(range) then
              range := Typing.deduceIterationRangeExp(Expression.CALL(call), iter, info);
            end if;

            (range, _, iter_var, iter_pur) := Typing.typeIterator(iter, range, context, structural = false);
            variability := Variability.variabilityMax(variability, iter_var);
            purity := Variability.purityMin(purity, iter_pur);
            iters := (iter, range) :: iters;
          end for;

          iters := listReverseInPlace(iters);

          // InstContext.FOR is used here as a marker that this expression may contain iterators.
          next_context := InstContext.set(next_context, NFInstContext.FOR);
          (arg, ty, exp_var, exp_pur) := Typing.typeExp(call.exp, next_context, info);
          variability := Variability.variabilityMax(variability, exp_var);
          purity := Variability.purityMin(purity, exp_pur);
          {fn} := Function.typeRefCache(call.ref);
          TypeCheck.checkReductionType(ty, Function.name(fn), call.exp, info);
        then
          (makeTypedReduction(fn, ty, variability, purity, arg, iters, info), ty, variability, purity);

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got invalid reduction call", sourceInfo());
        then
          fail();
    end match;
  end typeReduction;

public
  function makeTypedReduction
    input Function fn;
    input Type ty;
    input Variability var;
    input Purity purity;
    input Expression arg;
    input list<tuple<InstNode, Expression>> iters;
    input SourceInfo info;
    output Call call;
  protected
    String fold_id, res_id;
    Option<Expression> default_exp, fold_exp;
    tuple<Option<Expression>, String, String> fold_tuple;
  algorithm
    fold_id := Util.getTempVariableIndex();
    res_id := Util.getTempVariableIndex();
    default_exp := reductionDefaultValue(fn, ty);
    fold_exp := reductionFoldExpression(fn, ty, var, purity, fold_id, res_id, info);
    fold_tuple := (fold_exp, fold_id, res_id);

    call := TYPED_REDUCTION(fn, ty, var, purity, arg, iters, default_exp, fold_tuple);
  end makeTypedReduction;

protected
  function reductionDefaultValue
    input Function fn;
    input Type ty;
    output Option<Expression> defaultValue;
  algorithm
    if Type.isArray(ty) then
      defaultValue := NONE();
    else
      defaultValue := match AbsynUtil.pathFirstIdent(Function.name(fn))
        case "sum" then SOME(Expression.makeZero(ty));
        case "product" then SOME(Expression.makeOne(ty));
        case "min" then SOME(Expression.makeMaxValue(ty));
        case "max" then SOME(Expression.makeMinValue(ty));
        else
          algorithm
            Error.addSourceMessage(Error.INTERNAL_ERROR,
              {getInstanceName() + " got unknown reduction name " + AbsynUtil.pathFirstIdent(Function.name(fn))},
              sourceInfo());
          then
            fail();
      end match;
    end if;
  end reductionDefaultValue;

  function reductionFoldExpression
    input Function reductionFn;
    input Type reductionType;
    input Variability reductionVar;
    input Purity reductionPurity;
    input String foldId;
    input String resultId;
    input SourceInfo info;
    output Option<Expression> foldExp;
  protected
    Type ty;
    InstNode op_node;
    Function fn;
  algorithm
    if Type.isComplex(reductionType) then
      foldExp := match AbsynUtil.pathFirstIdent(Function.name(reductionFn))
        case "sum"
          algorithm
            Type.COMPLEX(cls = op_node) := reductionType;
            op_node := Class.lookupElement("'+'", InstNode.getClass(op_node));
            Function.instFunctionNode(op_node, NFInstContext.NO_CONTEXT, info);
            {fn} := Function.typeNodeCache(op_node);
          then
            SOME(Expression.CALL(makeTypedCall(fn,
              {reductionFoldIterator(resultId, reductionType),
               reductionFoldIterator(foldId, reductionType)}, reductionVar, reductionPurity)));

        else NONE();
      end match;
    else
      foldExp := match AbsynUtil.pathFirstIdent(Function.name(reductionFn))
        case "sum"
          then SOME(Expression.BINARY(
            reductionFoldIterator(resultId, reductionType),
            Operator.makeAdd(reductionType),
            reductionFoldIterator(foldId, reductionType)));

        case "product"
          then SOME(Expression.BINARY(
            reductionFoldIterator(resultId, reductionType),
            Operator.makeMul(reductionType),
            reductionFoldIterator(foldId, reductionType)));

        case "$array" then NONE();
        case "array" then NONE();
        case "list" then NONE();
        case "listReverse" then NONE();

        else
          SOME(Expression.CALL(makeTypedCall(reductionFn,
            {reductionFoldIterator(foldId, reductionType),
             reductionFoldIterator(resultId, reductionType)},
            reductionVar, reductionPurity, reductionType)));

      end match;
    end if;
  end reductionFoldExpression;

  function reductionFoldIterator
    input String name;
    input Type ty;
    output Expression iterExp;
  algorithm
    iterExp := Expression.CREF(ty, ComponentRef.makeIterator(InstNode.NAME_NODE(name), ty));
  end reductionFoldIterator;

  function typeArgs
    input output NFCall call;
    input InstContext.Type context;
    input SourceInfo info;
  algorithm
    call := match call
      local
        Expression arg;
        Type arg_ty;
        Variability arg_var;
        Purity arg_pur;
        list<TypedArg> typed_args, typed_nargs;
        String name;
        InstContext.Type next_context;

      case UNTYPED_CALL()
        algorithm
          typed_args := {};
          next_context := InstContext.set(context, NFInstContext.SUBEXPRESSION);

          for arg in call.arguments loop
            (arg, arg_ty, arg_var, arg_pur) := Typing.typeExp(arg, next_context, info);
            typed_args := TypedArg.TYPED_ARG(NONE(), arg, arg_ty, arg_var, arg_pur) :: typed_args;
          end for;

          typed_args := listReverse(typed_args);

          typed_nargs := {};
          for narg in call.named_args loop
            (name, arg) := narg;
            (arg, arg_ty, arg_var, arg_pur) := Typing.typeExp(arg, next_context, info);
            typed_nargs := TypedArg.TYPED_ARG(SOME(name), arg, arg_ty, arg_var, arg_pur) :: typed_nargs;
          end for;

          typed_nargs := listReverse(typed_nargs);
        then
          ARG_TYPED_CALL(call.ref, typed_args, typed_nargs, call.call_scope);
    end match;
  end typeArgs;

  function checkMatchingFunctions
    input NFCall call;
    input SourceInfo info;
    input Boolean vectorize = true;
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
          Function.matchFunctions(allfuncs, call.positional_args, call.named_args, info, vectorize);
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

      if listEmpty(exactMatches) then
        exactMatches := MatchedFunction.getExactVectorizedMatches(matchedFunctions);
      end if;

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
      Type.toDAE(InstNode.getType(iter_node)));
  end iteratorToDAE;

  function vectorizeCall
    input NFCall base_call;
    input FunctionMatchKind mk;
    input InstNode scope;
    input SourceInfo info;
    output NFCall vectorized_call;
  protected
    Type ty, vect_ty;
    Expression exp;
    list<tuple<InstNode, Expression>> iters;
    InstNode iter;
    Integer i;
    list<Expression> call_args;
    Subscript sub;
  algorithm
    vectorized_call := match (base_call, mk)
      case (TYPED_CALL(arguments = call_args), FunctionMatchKind.VECTORIZED())
        algorithm
          iters := {};
          i := 1;

          for dim in mk.vectDims loop
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
            sub := Subscript.INDEX(exp);

            call_args := List.mapIndices(call_args, mk.vectorizedArgs,
              function Expression.applySubscript(subscript = sub, restSubscripts = {}));

            i := i + 1;
          end for;

          vect_ty := Type.liftArrayLeftList(base_call.ty, mk.vectDims);
          base_call.arguments := call_args;
        then
          TYPED_ARRAY_CONSTRUCTOR(vect_ty, base_call.var, base_call.purity, Expression.CALL(base_call), iters);

      else
        algorithm
          Error.addInternalError(getInstanceName() + " got unknown call", info);
        then
          fail();

     end match;
  end vectorizeCall;

  function isVectorized
    input NFCall call;
    output Boolean vectorized;
  algorithm
    vectorized := match call
      // A call is considered to be vectorized if the first iterator has a name
      // beginning with $.
      case TYPED_ARRAY_CONSTRUCTOR(exp = Expression.CALL())
        then stringGet(InstNode.name(Util.tuple21(listHead(call.iters))), 1) == 36; /* $ */
      else false;
    end match;
  end isVectorized;

  function devectorizeCall
    "Transforms a vectorized call into a non-vectorized one. This function is
     used as a helper to output valid flat Modelica, and should probably not
     be used where e.g. correct types are required."
    input NFCall call;
    output NFCall outCall;
  protected
    Expression exp, iter_exp;
    list<tuple<InstNode, Expression>> iters;
    InstNode iter_node;
  algorithm
    TYPED_ARRAY_CONSTRUCTOR(exp = exp, iters = iters) := call;

    for i in iters loop
      (iter_node, iter_exp) := i;
      exp := Expression.replaceIterator(exp, iter_node, iter_exp);
    end for;

    exp := SimplifyExp.simplify(exp);
    Expression.CALL(call = outCall) := exp;
  end devectorizeCall;

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

          ErrorExt.setCheckpoint(getInstanceName());
          try
            exp := Ceval.evalExp(exp, Ceval.EvalTarget.IGNORE_ERRORS());
          else
          end try;
          ErrorExt.rollBack(getInstanceName());
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
          else
            outExp := exp;
          end if;
        then
          outExp;

      else exp;
    end match;
  end evaluateCallTypeDimExp;

  function resolvePolymorphicReturnType
    "Resolves a polymorphic type to the actual type based on the inputs of a function."
    input Function fn;
    input list<TypedArg> args;
    input Type ty;
    output Type outType;
  protected
    String name;
    Type input_ty;
    TypedArg arg;
    list<TypedArg> rest_args = args;
  algorithm
    outType := match ty
      case Type.POLYMORPHIC(name = name)
        algorithm
          // Go through the inputs until we find one with the same polymorphic
          // type as the one we're looking for.
          for i in fn.inputs loop
            arg :: rest_args := rest_args;
            input_ty := InstNode.getType(i);

            if Type.isPolymorphicNamed(Type.arrayElementType(input_ty), name) then
              // Replace the type with the corresponding argument type, but
              // remove as many dimensions from it as the input has.
              //   For example: T[:] and Real[2, 3] gives T = Real[3]
              outType := Type.unliftArrayN(Type.dimensionCount(input_ty), arg.ty);
              return;
            end if;
          end for;

          // If no input with the same type could be found and the result type
          // is __Scalar, try to find some input with the type __Array and
          // assume they have the same element type.
          if name == "__Scalar" then
            outType := resolvePolymorphicReturnType(fn, args, Type.POLYMORPHIC("__Array"));
            outType := Type.arrayElementType(outType);
            return;
          end if;
        then
          fail();

      case Type.ARRAY(elementType = Type.POLYMORPHIC())
        algorithm
          // For an array of polymorphic types, only resolve the polymorphic
          // type itself and keep the dimensions.
          ty.elementType := resolvePolymorphicReturnType(fn, args, ty.elementType);
        then
          ty;

      else ty;
    end match;
  end resolvePolymorphicReturnType;

annotation(__OpenModelica_Interface="frontend");
end NFCall;
