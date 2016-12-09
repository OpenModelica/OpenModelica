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

encapsulated package NFFunc
" file:        NFFunc.mo
  package:     NFFunc
  description: package for handling functions.


  Functions used by NFInst for handling functions.
"

import NFBinding.Binding;
import NFClass.Class;
import NFComponent.Component;
import NFDimension.Dimension;
import NFEquation.Equation;
import NFInstNode.InstNode;
import NFMod.Modifier;
import NFPrefix.Prefix;
import NFStatement.Statement;

protected
import ClassInf;
import ComponentReference;
import Error;
import Expression;
import ExpressionDump;
import Inst = NFInst;
import InstUtil;
import List;
import Lookup = NFLookup;
import NFInstUtil;
import Record = NFRecord;
import Static;
import TypeCheck = NFTypeCheck;
import Types;
import Typing = NFTyping;

public
public uniontype FunctionSlot
  record SLOT
    String name "the name of the slot";
    Option<tuple<DAE.Exp, DAE.Type, DAE.Const>> arg "the argument given by the function call";
    Option<Binding> default "the default value from binding of the input component in the function";
    Option<tuple<DAE.Type, DAE.Const>> expected "the actual type of the input component, what we expect to get";
    Boolean isFilled;
  end SLOT;
end FunctionSlot;

public
function typeFunctionCall
  input Absyn.ComponentRef functionName;
  input Absyn.FunctionArgs functionArgs;
  input InstNode scope;
  input SourceInfo info;
  output DAE.Exp typedExp;
  output DAE.Type ty;
  output DAE.Const variability;
protected
  String fn_name;
  Absyn.Path fn, fn_1;
  InstNode fakeComponent;
  InstNode classNode;
  list<DAE.Exp> arguments;
  DAE.CallAttributes ca;
  DAE.Type classType, resultType;
  list<DAE.FuncArg> funcArg;
  DAE.FunctionAttributes functionAttributes;
  DAE.TypeSource source;
  Prefix prefix;
  SCode.Element cls;
  list<DAE.Var> vars;
  list<Absyn.Exp> args;
  DAE.Const argVariability;
  DAE.FunctionBuiltin isBuiltin;
  Boolean builtin;
  DAE.InlineType inlineType;
algorithm
  try
    // make sure the component is a path (no subscripts)
    fn := Absyn.crefToPath(functionName);
  else
    fn_name := Dump.printComponentRefStr(functionName);
    Error.addSourceMessageAndFail(Error.SUBSCRIPTED_FUNCTION_CALL, {fn_name}, info);
    fail();
  end try;

  try
    // try to lookup the function, if is working then is either a user defined function or present in ModelicaBuiltin.mo
    (classNode, prefix) := Lookup.lookupFunctionName(functionName, scope, info);
  else
    // we could not lookup the class, see if is a special builtin such as String(), etc
    if isSpecialBuiltinFunctionName(functionName) then
      (typedExp, ty, variability) := typeSpecialBuiltinFunctionCall(functionName, functionArgs, scope, info);
      return;
    end if;
    // fail otherwise
    fail();
  end try;

  classNode := Inst.instantiate(classNode, Modifier.NOMOD(), scope);
  fn_name :=  InstNode.name(classNode);
  cls := InstNode.definition(classNode);
  // create a component that has the name of the function and the scope of the function as its type
  fakeComponent := InstNode.newComponent(fn_name,
     SCode.COMPONENT(
       fn_name,
       SCode.defaultPrefixes,
       SCode.defaultVarAttr,
       Absyn.TPATH(fn, NONE()),
       SCode.NOMOD(),
       SCode.COMMENT(NONE(), NONE()),
       NONE(),
       info), scope);

  fakeComponent := Inst.instComponent(fakeComponent, scope, InstNode.parent(classNode));

  // we need something better than this as this will type the function twice
  fakeComponent := Typing.typeComponent(fakeComponent);
  (classNode, classType) := Typing.typeClass(classNode);

  // see if the class is a builtin function (including definitions in the ModelicaBuiltin.mo), record or normal function

  // is builtin function defined in ModelicaBuiltin.mo
  if isBuiltinFunctionName(functionName) then
    (typedExp, ty, variability) := typeBuiltinFunctionCall(functionName, functionArgs, prefix, classNode, classType, cls, scope, info);
    return;
  end if;

  // is record
  if SCode.isRecord(cls) then
    (typedExp, ty, variability) := Record.typeRecordCall(functionName, functionArgs, prefix, classNode, classType, cls, scope, info);
    return;
  end if;

  // is normal function call
  (typedExp, ty, variability) := typeNormalFunction(functionName, functionArgs, prefix, classNode, classType, cls, scope, info);

end typeFunctionCall;

function getFunctionInputs
  input InstNode classNode;
  output list<InstNode> inputs = {};
protected
  InstNode cn;
  Component.Attributes attr;
  array<InstNode> components;
algorithm
  Class.INSTANCED_CLASS(components = components) := InstNode.getClass(classNode);

  for i in arrayLength(components):-1:1 loop
     cn := components[i];
     attr := Component.getAttributes(InstNode.component(cn));
     inputs := match attr
                 case Component.ATTRIBUTES(direction = DAE.INPUT()) then cn::inputs;
                 else inputs;
               end match;
  end for;
end getFunctionInputs;

function getFunctionOutputs
  input InstNode classNode;
  output list<InstNode> outputs = {};
protected
  InstNode cn;
  Component.Attributes attr;
  array<InstNode> components;
algorithm
  Class.INSTANCED_CLASS(components = components) := InstNode.getClass(classNode);

  for i in arrayLength(components):-1:1 loop
     cn := components[i];
     attr := Component.getAttributes(InstNode.component(cn));
     outputs := match attr
                 case Component.ATTRIBUTES(direction = DAE.OUTPUT()) then cn::outputs;
                 else outputs;
               end match;
  end for;
end getFunctionOutputs;

// TODO FIXME! how do we handle vectorization? maybe using the commented out code in NFTypeCheck.mo?
function typeNormalFunction
  input Absyn.ComponentRef functionName;
  input Absyn.FunctionArgs functionArgs;
  input Prefix prefix;
  input InstNode classNode;
  input DAE.Type classType;
  input SCode.Element cls;
  input InstNode scope;
  input SourceInfo info;
  output DAE.Exp typedExp;
  output DAE.Type ty;
  output DAE.Const variability;
protected
  String fn_name, argName;
  Absyn.Path fn, fn_1;
  InstNode fakeComponent;
  Component c;
  DAE.CallAttributes ca;
  DAE.Type resultType;
  list<DAE.FuncArg> funcArg;
  DAE.FunctionAttributes functionAttributes;
  DAE.TypeSource source;
  list<DAE.Var> vars;
  Absyn.Exp arg;
  list<Absyn.Exp> args;
  list<Absyn.NamedArg> nargs;
  list<DAE.Exp> dargs, dnargs; // dae args, dae named args
  list<DAE.Type> dargstys = {}, dnargstys = {}; // dae args types, dae named args types
  list<DAE.Const> dargsvrs = {}, dnargsvrs = {}; // dae args variability, dae named args variability
  list<String> dnargsnames = {}; // the named args names
  DAE.FunctionBuiltin isBuiltin;
  Boolean builtin;
  DAE.InlineType inlineType;
  list<InstNode> inputs;
  list<DAE.Exp> dargs;
  DAE.Exp darg;
  DAE.Type dty;
  DAE.Const dvr;
  list<FunctionSlot> slots = {}, tslots = {};
  FunctionSlot s;
  Component.Attributes attr;
  DAE.VarKind vk;
  Binding b;
  Option<Binding> ob;
  String sname "the name of the slot";
  Option<tuple<DAE.Exp, DAE.Type, DAE.Const>> sarg "the argument given by the function call";
  Option<Binding> sdefault "the default value from binding of the input component in the function";
  Option<tuple<DAE.Type, DAE.Const>> sexpected "the actual type of the input component, what we expect to get";

algorithm

  fn := Absyn.crefToPath(functionName);

  Absyn.FUNCTIONARGS(args = args, argNames = nargs) := functionArgs;

  inputs := getFunctionInputs(classNode);

  // create the slots
  for i in inputs loop
    argName := InstNode.name(i);
    c := InstNode.component(i);
    attr := Component.getAttributes(c);
    Component.ATTRIBUTES(variability = vk) := attr;
    dvr := Typing.variabilityToConst(NFInstUtil.daeToSCodeVariability(vk));
    b := Component.getBinding(c);
    ob := match b case Binding.TYPED_BINDING() then SOME(b); else then NONE(); end match;
    ty := Component.getType(c);
    slots := SLOT(argName, NONE(), ob, SOME((ty, dvr)), false)::slots;
  end for;
  slots := listReverse(slots);

  // handle positional args
  for a in args loop
    (darg, dty, dvr) := Typing.typeExp(a, scope, info);
    s::slots := slots;
    // replace sarg in the slot
    SLOT(sname, sarg, sdefault, sexpected, _) := s;
    sarg := SOME((darg, dty, dvr));
    s := SLOT(sname, sarg, sdefault, sexpected, true);
    tslots := s::tslots;
  end for;
  slots := listAppend(listReverse(tslots), slots);

  // handle named args
  for n in nargs loop
    Absyn.NAMEDARG(argName = argName, argValue = arg) := n;
    (darg, dty, dvr) := Typing.typeExp(arg, scope, info);
    slots := fillNamedSlot(slots, argName, (darg, dty, dvr), fn, prefix, info);
  end for;

  // check that there are no unfilled slots and the types of actual arguments agree with the type of function arguments
  typeCheckFunctionSlots(slots, fn, prefix, info);

  (dargs, variability) := argsFromSlots(slots);

  DAE.T_COMPLEX(varLst = vars) := classType;
  functionAttributes := InstUtil.getFunctionAttributes(cls, vars);
  ty := Types.makeFunctionType(fn, vars, functionAttributes);

  DAE.T_FUNCTION(funcResultType = resultType) := ty;

  (isBuiltin,builtin,fn_1) := Static.isBuiltinFunc(fn, ty);
  inlineType := Static.inlineBuiltin(isBuiltin,functionAttributes.inline);

  ca := DAE.CALL_ATTR(
          resultType,
          Types.isTuple(resultType),
          builtin,
          functionAttributes.isImpure or (not functionAttributes.isOpenModelicaPure),
          functionAttributes.isFunctionPointer,
          inlineType,DAE.NO_TAIL());

  typedExp := DAE.CALL(fn_1, dargs, ca);

end typeNormalFunction;

function argsFromSlots
  input list<FunctionSlot> slots;
  output list<DAE.Exp> args = {};
  output DAE.Const c = DAE.C_CONST();
protected
  Integer d;
  DAE.Exp arg;
  Option<tuple<DAE.Exp, DAE.Type, DAE.Const>> sarg "the argument given by the function call";
  Option<Binding> sdefault "the default value from binding of the input component in the function";
  DAE.Const const;
algorithm
  for s in slots loop
    SLOT(arg = sarg, default = sdefault) := s;
    if isSome(sarg) then
      SOME((arg, _, const)) := sarg;
      c := Types.constAnd(c, const);
    else
      // TODO FIXME what do we do with the propagatedDims?
      SOME(Binding.TYPED_BINDING(bindingExp = arg, variability = const, propagatedDims = d)) := sdefault;
      c := Types.constAnd(c, const);
    end if;
    args := arg :: args;
  end for;
  args := listReverse(args);
end argsFromSlots;

function typeCheckFunctionSlots
  input list<FunctionSlot> slots;
  input Absyn.Path fn;
  input Prefix prefix;
  input SourceInfo info;
algorithm
protected
  String str1, str2, s1, s2, s3, s4, s5;
  Boolean b, found = false;
  String sname "the name of the slot";
  Option<tuple<DAE.Exp, DAE.Type, DAE.Const>> sarg "the argument given by the function call";
  Option<Binding> sdefault "the default value from binding of the input component in the function";
  Option<tuple<DAE.Type, DAE.Const>> sexpected "the actual type of the input component, what we expect to get";
  Boolean sisFilled;
  DAE.Exp expActual;
  DAE.Const vrActual, vrExpected;
  DAE.Type tyActual, tyExpected;
  Integer position = 0;
algorithm
  for s in slots loop
    position := position + 1;
    SLOT(sname, sarg, sdefault, sexpected, sisFilled) := s;

    // slot not filled and there is no default
    if not sisFilled and not isSome(sdefault) then
      Error.addSourceMessage(Error.UNFILLED_SLOT, {sname}, info);
      fail();
    end if;

    SOME((expActual, tyActual, vrActual)) := sarg;
    SOME((tyExpected, vrExpected)) := sexpected;

    // check the typing
    try
      _ := Types.matchType(expActual, tyActual, tyExpected, true);
    else
      s1 := intString(position);
      s2 := Absyn.pathStringNoQual(fn);
      s3 := ExpressionDump.printExpStr(expActual);
      s4 := Types.unparseTypeNoAttr(tyActual);
      s5 := Types.unparseTypeNoAttr(tyExpected);
      Error.addSourceMessage(Error.ARG_TYPE_MISMATCH, {s1,s2,sname,s3,s4,s5}, info);
      fail();
    end try;

    // fail if the variability is wrong
    if not Types.constEqualOrHigher(vrActual, vrExpected) then
      str1 := ExpressionDump.printExpStr(expActual);
      str2 := DAEUtil.constStrFriendly(vrExpected);
      Error.addSourceMessageAndFail(Error.FUNCTION_SLOT_VARIABILITY, {sname, str1, str2}, info);
    end if;
  end for;
end typeCheckFunctionSlots;

function fillNamedSlot
  input list<FunctionSlot> islots;
  input String name;
  input tuple<DAE.Exp, DAE.Type, DAE.Const> arg;
  input Absyn.Path fn;
  input Prefix prefix;
  input SourceInfo info;
  output list<FunctionSlot> oslots = {};
protected
  String str;
  Boolean b, found = false;
  String sname "the name of the slot";
  Option<tuple<DAE.Exp, DAE.Type, DAE.Const>> sarg "the argument given by the function call";
  Option<Binding> sdefault "the default value from binding of the input component in the function";
  Option<tuple<DAE.Type, DAE.Const>> sexpected "the actual type of the input component, what we expect to get";
  Boolean sisFilled;
algorithm
  for s in islots loop
    SLOT(sname, sarg, sdefault, sexpected, sisFilled) := s;
    if (name == sname) then
      found := true;
      // if the slot is already filled, Huston we have a problem, add an error
      if sisFilled then
        str := Prefix.toString(prefix) + "." + Absyn.pathString(fn);
        Error.addSourceMessageAndFail(Error.FUNCTION_SLOT_ALLREADY_FILLED, {name, str}, info);
      end if;
      oslots := SLOT(sname, SOME(arg), sdefault, sexpected, true) :: oslots;
    else
      oslots := s :: oslots;
    end if;
  end for;
  if not found then
    str := Prefix.toString(prefix) + "." + Absyn.pathString(fn);
    Error.addSourceMessageAndFail(Error.NO_SUCH_ARGUMENT, {str, name}, info);
  end if;
end fillNamedSlot;

protected function isSpecialBuiltinFunctionName
"@author: adrpo
 check if the name is special builtin function or
 operator which does not have a definition in ModelicaBuiltin.mo
 TODO FIXME, add all of them"
  input Absyn.ComponentRef functionName;
  output Boolean isBuiltinFname;
algorithm
  isBuiltinFname := matchcontinue(functionName)
    local
      String name;
      Boolean b, b1, b2;
      Absyn.ComponentRef fname;

    case (Absyn.CREF_FULLYQUALIFIED(fname))
      then
        isSpecialBuiltinFunctionName(fname);

    case (Absyn.CREF_IDENT(name, {}))
      equation
        b1 = listMember(name, {"String", "Integer"});
        // these are the new Modelica 3.3 synch operators
        b2 = if intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33)
              then
                listMember(name, {"Clock", "previous", "hold", "subSample", "superSample", "shiftSample",
                                  "backSample", "noClock", "transition", "initialState", "activeState",
                                  "ticksInState", "timeInState"})
              else false;
        b = boolOr(b1, b2);
      then
        b;

    case (_) then false;
  end matchcontinue;
end isSpecialBuiltinFunctionName;

protected function isBuiltinFunctionName
"@author: adrpo
 check if the name is a builtin function or operator
 TODO FIXME, add all of them"
  input Absyn.ComponentRef functionName;
  output Boolean isBuiltinFname;
algorithm
  isBuiltinFname := matchcontinue(functionName)
    local
      String name;
      Boolean b;
      Absyn.ComponentRef fname;

    case (Absyn.CREF_FULLYQUALIFIED(fname))
      then
        isBuiltinFunctionName(fname);

    case (Absyn.CREF_IDENT(name, {}))
      equation
        b = listMember(name,
          {
            "noEvent",
            "smooth",
            "sample",
            "pre",
            "edge",
            "change",
            "reinit",
            "size",
            "rooted",
            "transpose",
            "skew",
            "identity",
            "min",
            "max",
            "cross",
            "diagonal",
            "abs",
            "sum",
            "product",
            "assert",
            "array",
            "cat",
            "rem",
            "actualStream",
            "inStream"});
      then
        b;

    case (_) then false;
  end matchcontinue;
end isBuiltinFunctionName;

// adrpo:
// - see Static.mo for how to check the input arguments or any other checks we need that should be ported
// - try to use Expression.makePureBuiltinCall everywhere instead of creating the typedExp via DAE.CALL
// - this function should handle special builtin operators which are not defined in ModelicaBuiltin.mo
protected function typeSpecialBuiltinFunctionCall
"@author: adrpo
 handle all builtin calls that are not defined at all in ModelicaBuiltin.mo
 TODO FIXME, add all"
  input Absyn.ComponentRef functionName;
  input Absyn.FunctionArgs functionArgs;
  input InstNode scope;
  input SourceInfo info;
  output DAE.Exp typedExp;
  output DAE.Type ty;
  output DAE.Const variability;
protected
   String fnName;
   DAE.Const vr, vr1, vr2;
algorithm
  (typedExp, ty, variability) := matchcontinue(functionName, functionArgs)
    local
      Absyn.ComponentRef acref;
      Absyn.Exp aexp1, aexp2;
      DAE.Exp dexp1, dexp2;
      list<Absyn.Exp>  afargs;
      list<Absyn.NamedArg> anamed_args;
      Absyn.Path call_path;
      list<DAE.Exp> pos_args, args;
      list<tuple<String, DAE.Exp>> named_args;
      list<InstNode> inputs, outputs;
      Absyn.ForIterators iters;
      DAE.Dimensions d1, d2;
      DAE.TypeSource src1, src2;
      DAE.Type el_ty;
      list<DAE.Type> tys;
      list<DAE.Const> vrs;

    // TODO FIXME: String might be overloaded, we need to handle this better! See Static.mo
    case (Absyn.CREF_IDENT(name = "String"), Absyn.FUNCTIONARGS(args = afargs))
      algorithm
        call_path := Absyn.crefToPath(functionName);
        (args, tys, vrs) := Typing.typeExps(afargs, scope, info);
        vr := List.fold(vrs, Types.constAnd, DAE.C_CONST());
        ty := DAE.T_STRING_DEFAULT;
      then
        (DAE.CALL(call_path, args, DAE.callAttrBuiltinOther), ty, vr);

    // TODO FIXME: check that the input is an enumeration
    case (Absyn.CREF_IDENT(name = "Integer"), Absyn.FUNCTIONARGS(args = afargs))
      algorithm
        call_path := Absyn.crefToPath(functionName);
        (args, tys, vrs) := Typing.typeExps(afargs, scope, info);
        vr := List.fold(vrs, Types.constAnd, DAE.C_CONST());
        ty := DAE.T_INTEGER_DEFAULT;
      then
        (DAE.CALL(call_path, args, DAE.callAttrBuiltinOther), ty, vr);

    // TODO FIXME! handle all the Modelica 3.3 operators here, see isSpecialBuiltinFunctionName

 end matchcontinue;
end typeSpecialBuiltinFunctionCall;


// adrpo:
// - see Static.mo for how to check the input arguments or any other checks we need that should be ported
// - try to use Expression.makePureBuiltinCall everywhere instead of creating the typedExp via DAE.CALL
// - all the fuctions that are defined *with no input/output type* in ModelicaBuiltin.mo such as:
//     function NAME "Transpose a matrix"
//       external "builtin";
//     end NAME;
//   need to be handled here!
// - the functions which have a type in the ModelicaBuiltin.mo should be handled by the last case in this function
protected function typeBuiltinFunctionCall
"@author: adrpo
 handle all builtin calls that are not in ModelicaBuiltin.mo
 TODO FIXME, add all"
  input Absyn.ComponentRef functionName;
  input Absyn.FunctionArgs functionArgs;
  input Prefix prefix;
  input InstNode classNode;
  input DAE.Type classType;
  input SCode.Element cls;
  input InstNode scope;
  input SourceInfo info;
  output DAE.Exp typedExp;
  output DAE.Type ty;
  output DAE.Const variability;
protected
   String fnName;
   DAE.Const vr, vr1, vr2;
algorithm
  (typedExp, ty, variability) := matchcontinue(functionName, functionArgs)
    local
      Absyn.ComponentRef acref;
      Absyn.Exp aexp1, aexp2;
      DAE.Exp dexp1, dexp2;
      list<Absyn.Exp>  afargs;
      list<Absyn.NamedArg> anamed_args;
      Absyn.Path call_path;
      list<DAE.Exp> pos_args, args;
      list<tuple<String, DAE.Exp>> named_args;
      list<InstNode> inputs, outputs;
      Absyn.ForIterators iters;
      DAE.Dimension d1, d2;
      DAE.TypeSource src1, src2;
      DAE.Type el_ty, ty1, ty2;

    // size(arr, dim)
    case (Absyn.CREF_IDENT(name = "size"), Absyn.FUNCTIONARGS(args = {aexp1, aexp2}))
      algorithm
        (dexp1, ty1, vr1) := Typing.typeExp(aexp1, scope, info);
        (dexp2, ty2, vr2) := Typing.typeExp(aexp1, scope, info);

        // TODO FIXME: calculate the correct type and the correct variability, see Static.elabBuiltinSize in Static.mo
        ty := DAE.T_INTEGER_DEFAULT;
        // the variability does not actually depend on the variability of "arr" but on the variability of the dimensions of "arr"
        vr := Types.constAnd(vr1, vr2);
      then
        (DAE.SIZE(dexp1, SOME(dexp2)), ty, vr);

    // size(arr)
    case (Absyn.CREF_IDENT(name = "size"), Absyn.FUNCTIONARGS(args = {aexp1}))
      algorithm
        (dexp1, ty1, vr1) := Typing.typeExp(aexp1, scope, info);
        // TODO FIXME: calculate the correct type and the correct variability, see Static.elabBuiltinSize in Static.mo
        ty := DAE.T_INTEGER_DEFAULT;
        // the variability does not actually depend on the variability of "arr" but on the variability of the dimensions of "arr"
        vr := vr1;
      then
        (DAE.SIZE(dexp1, NONE()), ty, vr);

    case (Absyn.CREF_IDENT(name = "smooth"), Absyn.FUNCTIONARGS(args = {aexp1, aexp2}))
      algorithm
        call_path := Absyn.crefToPath(functionName);
        (dexp1, ty1, vr1) := Typing.typeExp(aexp1, scope, info);
        (dexp2, ty2, vr2) := Typing.typeExp(aexp1, scope, info);

        // TODO FIXME: calculate the correct type and the correct variability, see Static.mo
        ty := DAE.T_REAL_DEFAULT;
        vr := vr1;
      then
        (DAE.CALL(call_path, {dexp1,dexp2}, DAE.callAttrBuiltinOther), ty, vr);

    case (Absyn.CREF_IDENT(name = "rooted"), Absyn.FUNCTIONARGS(args = {aexp1}))
      algorithm
        call_path := Absyn.crefToPath(functionName);
        (dexp1, ty1, vr1) := Typing.typeExp(aexp1, scope, info);

        // TODO FIXME: calculate the correct type and the correct variability, see Static.mo
        ty := DAE.T_BOOL_DEFAULT;
        vr := vr1;
      then
        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), ty, vr);

    case (Absyn.CREF_IDENT(name = "transpose"), Absyn.FUNCTIONARGS(args = {aexp1}))
      algorithm
        (dexp1, ty1, vr1) := Typing.typeExp(aexp1, scope, info);

        // transpose the type.
        DAE.T_ARRAY(DAE.T_ARRAY(el_ty, {d1}, src1), {d2}, src2) := ty1;
        ty := DAE.T_ARRAY(DAE.T_ARRAY(el_ty, {d2}, src1), {d1}, src2);

        // create the typed transpose expression
        typedExp := Expression.makePureBuiltinCall("transpose", {dexp1}, ty);
        vr := vr1;
      then
        (typedExp, ty, vr);

    // min|max(arr)
    case (Absyn.CREF_IDENT(name = fnName), Absyn.FUNCTIONARGS(args = {aexp1}))
      algorithm
        true := listMember(fnName, {"min", "max"});
        (dexp1, ty1, vr1) := Typing.typeExp(aexp1, scope, info);

        true := Types.isArray(ty1);
        dexp1 := Expression.matrixToArray(dexp1);
        el_ty := Types.arrayElementType(ty1);
        false := Types.isString(el_ty);

        ty := el_ty;
        vr := vr1;
        typedExp := Expression.makePureBuiltinCall(fnName, {dexp1}, ty);
      then
        (typedExp, ty, vr);

    // min|max(x,y) where x & y are scalars.
    case (Absyn.CREF_IDENT(name = fnName), Absyn.FUNCTIONARGS(args = {aexp1, aexp2}))
      algorithm
        true := listMember(fnName, {"min", "max"});
        (dexp1, ty1, vr1) := Typing.typeExp(aexp1, scope, info);
        (dexp2, ty2, vr2) := Typing.typeExp(aexp2, scope, info);

        ty := Types.scalarSuperType(ty1, ty2);
        (dexp1, _) := Types.matchType(dexp1, ty1, ty, true);
        (dexp2, _) := Types.matchType(dexp2, ty2, ty, true);
        vr := Types.constAnd(vr1, vr2);
        false := Types.isString(ty);
        typedExp := Expression.makePureBuiltinCall(fnName, {dexp1, dexp2}, ty);
      then
        (typedExp, ty, vr);

    case (Absyn.CREF_IDENT(name = "diagonal"), Absyn.FUNCTIONARGS(args = aexp1::_))
      algorithm
        (dexp1, ty1, vr1) := Typing.typeExp(aexp1, scope, info);
        DAE.T_ARRAY(dims = {d1}, ty = el_ty) := ty1;

        ty := DAE.T_ARRAY(DAE.T_ARRAY(el_ty, {d1}, DAE.emptyTypeSource), {d1}, DAE.emptyTypeSource);
        typedExp := Expression.makePureBuiltinCall("diagonal", {dexp1}, ty);
        vr := vr1;
      then
        (typedExp, ty, vr);

    /* adrpo: adapt these to the new structures, see above
    case (Absyn.CREF_IDENT(name = "product"), Absyn.FUNCTIONARGS(args = afargs))
      equation
        call_path = Absyn.crefToPath(functionName);
        (pos_args, globals) = Typing.typeExps(afargs, inEnv, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "pre"), Absyn.FUNCTIONARGS(args = afargs))
      equation
        call_path = Absyn.crefToPath(functionName);
        (pos_args, globals) = Typing.typeExps(afargs, inEnv, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "noEvent"), Absyn.FUNCTIONARGS(args = afargs))
      equation
        call_path = Absyn.crefToPath(functionName);
        (pos_args, globals) = Typing.typeExps(afargs, inEnv, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "sum"), Absyn.FUNCTIONARGS(args = afargs))
      equation
        call_path = Absyn.crefToPath(functionName);
        (pos_args, globals) = Typing.typeExps(afargs, inEnv, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "assert"), Absyn.FUNCTIONARGS(args = afargs))
      equation
        call_path = Absyn.crefToPath(functionName);
        (pos_args, globals) = Typing.typeExps(afargs, inEnv, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "change"), Absyn.FUNCTIONARGS(args = afargs))
      equation
        call_path = Absyn.crefToPath(functionName);
        (pos_args, globals) = Typing.typeExps(afargs, inEnv, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "array"), Absyn.FUNCTIONARGS(args = afargs))
      equation
        call_path = Absyn.crefToPath(functionName);
        (pos_args, globals) = Typing.typeExps(afargs, inEnv, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "array"), Absyn.FOR_ITER_FARG(exp=aexp1, iterators=iters))
      equation
        call_path = Absyn.crefToPath(functionName);
        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
        (dexp1, globals) = Typing.typeExp(aexp1, env, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "sum"), Absyn.FOR_ITER_FARG(exp=aexp1, iterators=iters))
      equation
        call_path = Absyn.crefToPath(functionName);
        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
        (dexp1, globals) = Typing.typeExp(aexp1, env, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "min"), Absyn.FOR_ITER_FARG(exp=aexp1, iterators=iters))
      equation
        call_path = Absyn.crefToPath(functionName);
        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
        (dexp1, globals) = Typing.typeExp(aexp1, env, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "max"), Absyn.FOR_ITER_FARG(exp=aexp1, iterators=iters))
      equation
        call_path = Absyn.crefToPath(functionName);
        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
        (dexp1, globals) = Typing.typeExp(aexp1, env, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "product"), Absyn.FOR_ITER_FARG(exp=aexp1, iterators=iters))
      equation
        call_path = Absyn.crefToPath(functionName);
        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
        (dexp1, globals) = Typing.typeExp(aexp1, env, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "cat"), Absyn.FUNCTIONARGS(args = afargs))
      equation
        call_path = Absyn.crefToPath(functionName);
        (pos_args, globals) = Typing.typeExps(afargs, inEnv, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "actualStream"), Absyn.FUNCTIONARGS(args = afargs))
      equation
        call_path = Absyn.crefToPath(functionName);
        (pos_args, globals) = Typing.typeExps(afargs, inEnv, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "inStream"), Absyn.FUNCTIONARGS(args = afargs))
      equation
        call_path = Absyn.crefToPath(functionName);
        (pos_args, globals) = Typing.typeExps(afargs, inEnv, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "String"), Absyn.FUNCTIONARGS(args = afargs))
      equation
        call_path = Absyn.crefToPath(functionName);
        (pos_args, globals) = Typing.typeExps(afargs, inEnv, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "Integer"), Absyn.FUNCTIONARGS(args = afargs))
      equation
        call_path = Absyn.crefToPath(functionName);
        (pos_args, globals) = Typing.typeExps(afargs, inEnv, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "Real"), Absyn.FUNCTIONARGS(args = afargs))
      equation
        call_path = Absyn.crefToPath(functionName);
        (pos_args, globals) = Typing.typeExps(afargs, inEnv, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);
    */

    // TODO! FIXME!
    // check if more functions need to be handled here
    // we also need to handle Absyn.FOR_ITER_FARG reductions instead of Absyn.FUNCTIONARGS

    /*
    // adrpo: no support for $overload functions yet: div, mod, rem, abs, i.e. ModelicaBuiltin.mo:
    // function mod = $overload(OpenModelica.Internal.intMod,OpenModelica.Internal.realMod)
    case (Absyn.CREF_IDENT(name = "rem"), Absyn.FUNCTIONARGS(args = afargs))
      equation
        call_path = Absyn.crefToPath(functionName);
        (pos_args, globals) = Typing.typeExps(afargs, inEnv, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

    case (Absyn.CREF_IDENT(name = "abs"), Absyn.FUNCTIONARGS(args = afargs))
      equation
        call_path = Absyn.crefToPath(functionName);
        (pos_args, globals) = Typing.typeExps(afargs, inEnv, inPrefix, inInfo, globals);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);
    */

    // hopefully all the other ones have a complete entry in ModelicaBuiltin.mo
    case (_, _)
      algorithm
        (typedExp, ty, vr) := typeNormalFunction(functionName, functionArgs, prefix, classNode, classType, cls, scope, info);
      then
        (typedExp, ty, vr);

 end matchcontinue;
end typeBuiltinFunctionCall;

annotation(__OpenModelica_Interface="frontend");
end NFFunc;
