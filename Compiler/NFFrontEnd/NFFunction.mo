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

encapsulated package NFFunction

import Absyn;
import Expression = NFExpression;
import Pointer;
import NFInstNode.InstNode;
import Type = NFType;
import NFPrefixes.*;
import List;
import FunctionDerivative = NFFunctionDerivative;
import NFModifier.Modifier;

protected
import ErrorExt;
import Inst = NFInst;
import NFBinding.Binding;
import Config;
import DAE;
import DAEDump;
import Error;
import InstUtil;
import NFClass.Class;
import NFComponent.Component;
import NFComponent.Component.Attributes;
import Typing = NFTyping;
import TypeCheck = NFTypeCheck;
import Util;
import ComponentRef = NFComponentRef;
import NFInstNode.CachedData;
import Lookup = NFLookup;
import ClassTree = NFClassTree.ClassTree;
import Prefixes = NFPrefixes;
import NFLookupState.LookupState;
import Record = NFRecord;
import NFTyping.ClassScope;
import MatchKind = NFTypeCheck.MatchKind;
import Restriction = NFRestriction;
import NFTyping.ExpOrigin;
import Dimension = NFDimension;
import Statement = NFStatement;
import Sections = NFSections;
import Algorithm = NFAlgorithm;
import OperatorOverloading = NFOperatorOverloading;
import MetaModelica.Dangerous.listReverseInPlace;
import Array;
import ElementSource;


public
type NamedArg = tuple<String, Expression>;
type TypedArg = tuple<Expression, Type, Variability>;
type TypedNamedArg = tuple<String, Expression, Type, Variability>;

public
type SlotType = enumeration(
  POSITIONAL "Only accepts positional arguments.",
  NAMED      "Only accepts named argument.",
  GENERIC    "Accepts both positional and named arguments."
) "Determines which type of argument a slot accepts.";

type SlotEvalStatus = enumeration(NOT_EVALUATED, EVALUATING, EVALUATED);

uniontype Slot
  record SLOT
    String name;
    SlotType ty;
    Option<Expression> default;
    Option<TypedArg> arg;
    Integer index;
    SlotEvalStatus evalStatus;
  end SLOT;

  function positional
    input Slot slot;
    output Boolean pos;
  algorithm
    pos := match slot.ty
      case SlotType.POSITIONAL then true;
      case SlotType.GENERIC then true;
      else false;
    end match;
  end positional;

  function named
    input Slot slot;
    output Boolean pos;
  algorithm
    pos := match slot.ty
      case SlotType.NAMED then true;
      case SlotType.GENERIC then true;
      else false;
    end match;
  end named;

  function hasName
    input String name;
    input Slot slot;
    output Boolean hasName = name == slot.name;
  end hasName;
end Slot;

public
encapsulated
uniontype FunctionMatchKind
  import Dimension = NFDimension;

  record EXACT "Exact match." end EXACT;

  record CAST "Matched by casting one or more arguments. e.g. Integer to Real" end CAST;

  record GENERIC "Matched with a generic type on one or more arguments e.g. function F<T> input T i; end F; F(1)"
  end GENERIC;

  record VECTORIZED "Matched by vectorization"
    list<Dimension> vect_dims;
    // When vectorizing a call exact argument matches are allowed to not be vectorized
    // Instead they are added to each call as is.
    // This list represents which args should be vectorized.
    list<Boolean> is_vectorized;
    FunctionMatchKind baseMatch;
  end VECTORIZED;

  record NOT_COMPATIBLE end NOT_COMPATIBLE;

  function isValid
    input FunctionMatchKind mk;
    output Boolean b;
  algorithm
    b := match mk
      case NOT_COMPATIBLE() then false;
      else true;
    end match;
  end isValid;

  function isExact
    input FunctionMatchKind mk;
    output Boolean b;
  algorithm
    b := match mk
      case EXACT() then true;
      else false;
    end match;
  end isExact;

  function isVectorized
    input FunctionMatchKind mk;
    output Boolean b;
  algorithm
    b := match mk
      case VECTORIZED() then true;
      else false;
    end match;
  end isVectorized;

  function isExactVectorized
    input FunctionMatchKind mk;
    output Boolean b;
  algorithm
    b := match mk
      case VECTORIZED(baseMatch = EXACT()) then true;
      else false;
    end match;
  end isExactVectorized;

end FunctionMatchKind;

constant FunctionMatchKind EXACT_MATCH = FunctionMatchKind.EXACT();
constant FunctionMatchKind CAST_MATCH = FunctionMatchKind.CAST();
constant FunctionMatchKind GENERIC_MATCH = FunctionMatchKind.GENERIC();
constant FunctionMatchKind NO_MATCH = FunctionMatchKind.NOT_COMPATIBLE();

encapsulated
uniontype MatchedFunction
  import NFFunction.Function;
  import NFFunction.TypedArg;
  import NFFunction.FunctionMatchKind;

  record MATCHED_FUNC
    Function func;
    list<TypedArg> args;
    FunctionMatchKind mk;
  end MATCHED_FUNC;

  function getExactMatches
    input list<MatchedFunction> matchedFunctions;
    output list<MatchedFunction> outFuncs = list(mf for mf guard(FunctionMatchKind.isExact(mf.mk)) in matchedFunctions);
  end getExactMatches;

  function getExactVectorizedMatches
    input list<MatchedFunction> matchedFunctions;
    output list<MatchedFunction> outFuncs =
      list(mf for mf guard(FunctionMatchKind.isExactVectorized(mf.mk)) in matchedFunctions);
  end getExactVectorizedMatches;

  function isVectorized
    input MatchedFunction mf;
    output Boolean b = FunctionMatchKind.isVectorized(mf.mk);
  end isVectorized;

end MatchedFunction;

type FunctionStatus = enumeration(
  BUILTIN    "A builtin function.",
  INITIAL    "The initial status.",
  EVALUATED  "Constants in the function has been evaluated by EvalConstants.",
  SIMPLIFIED "The function has been simplified by SimplifyModel.",
  COLLECTED  "The function has been added to the function tree."
);

uniontype Function

  record FUNCTION
    Absyn.Path path;
    InstNode node;
    list<InstNode> inputs;
    list<InstNode> outputs;
    list<InstNode> locals;
    list<Slot> slots;
    Type returnType;
    DAE.FunctionAttributes attributes;
    list<FunctionDerivative> derivatives;
    Pointer<FunctionStatus> status;
    Pointer<Integer> callCounter "Used during function evaluation to limit recursion.";
  end FUNCTION;

  function new
    input Absyn.Path path;
    input InstNode node;
    output Function fn;
  protected
    Class cls;
    list<InstNode> inputs, outputs, locals;
    list<Slot> slots;
    DAE.FunctionAttributes attr;
    FunctionStatus status;
  algorithm
    (inputs, outputs, locals) := collectParams(node);
    attr := makeAttributes(node, inputs, outputs);
    // Make sure builtin functions aren't added to the function tree.
    status := if isBuiltinAttr(attr) then FunctionStatus.COLLECTED else FunctionStatus.INITIAL;
    fn := FUNCTION(path, node, inputs, outputs, locals, {}, Type.UNKNOWN(),
      attr, {}, Pointer.create(status), Pointer.create(0));
  end new;

  function lookupFunctionSimple
    input String functionName;
    input InstNode scope;
    output ComponentRef functionRef;
  protected
    InstNode found_scope;
    LookupState state;
    Absyn.Path functionPath;
    ComponentRef prefix;
  algorithm
    (functionRef, found_scope) :=
      Lookup.lookupFunctionNameSilent(Absyn.CREF_IDENT(functionName, {}), scope);
    prefix := ComponentRef.fromNodeList(InstNode.scopeList(found_scope));
    functionRef := ComponentRef.append(functionRef, prefix);
  end lookupFunctionSimple;

  function lookupFunction
    input Absyn.ComponentRef functionName;
    input InstNode scope;
    input SourceInfo info;
    output ComponentRef functionRef;
  protected
    InstNode found_scope;
    LookupState state;
    Absyn.Path functionPath;
    ComponentRef prefix;
    Boolean is_class;
  algorithm
    try
      // Make sure the name is a path.
      functionPath := Absyn.crefToPath(functionName);
    else
      Error.addSourceMessageAndFail(Error.SUBSCRIPTED_FUNCTION_CALL,
        {Dump.printComponentRefStr(functionName)}, info);
    end try;

    (functionRef, found_scope) := Lookup.lookupFunctionName(functionName, scope, info);
    // If we found a function class we include the root in the prefix, but if we
    // instead found a component (i.e. a functional parameter) we don't.
    is_class := InstNode.isClass(ComponentRef.node(functionRef));
    prefix := ComponentRef.fromNodeList(InstNode.scopeList(InstNode.classScope(found_scope), includeRoot = is_class));
    functionRef := ComponentRef.append(functionRef, prefix);
  end lookupFunction;

  function instFunction
    input Absyn.ComponentRef functionName;
    input InstNode scope;
    input SourceInfo info;
    output ComponentRef fn_ref;
    output InstNode fn_node;
    output Boolean specialBuiltin;
  protected
    CachedData cache;
  algorithm
    fn_ref := lookupFunction(functionName, scope, info);
    (fn_ref, fn_node, specialBuiltin) := instFunctionRef(fn_ref, info);
  end instFunction;

  function instFunctionRef
    input output ComponentRef fn_ref;
    input SourceInfo info;
    output InstNode fn_node;
    output Boolean specialBuiltin;
  protected
    CachedData cache;
  algorithm
    fn_node := InstNode.classScope(ComponentRef.node(fn_ref));
    cache := InstNode.getFuncCache(fn_node);

    // Check if a cached instantiation of this function already exists.
    (fn_node, specialBuiltin) := match cache
      case CachedData.FUNCTION() then (fn_node, cache.specialBuiltin);
      else instFunction2(ComponentRef.toPath(fn_ref), fn_node, info);
    end match;
  end instFunctionRef;

  function instFunctionNode
    "Instantiates the given InstNode as a function."
    input output InstNode node;
  protected
    CachedData cache;
  algorithm
    cache := InstNode.getFuncCache(node);

    () := match cache
      case CachedData.FUNCTION() then ();
      else
        algorithm
          node := instFunction2(InstNode.scopePath(node), node, InstNode.info(node));
        then
          ();
    end match;
  end instFunctionNode;

  function instFunction2
    input Absyn.Path fnPath;
    input output InstNode fnNode;
    input SourceInfo info;
          output Boolean specialBuiltin;
  protected
    SCode.Element def = InstNode.definition(fnNode);
  algorithm
    (fnNode, specialBuiltin) := match def
      local
        SCode.ClassDef cdef;
        Function fn;
        Absyn.ComponentRef cr;
        InstNode sub_fnNode;
        list<Function> funcs;
        list<FunctionDerivative> fn_ders;

      case SCode.CLASS() guard SCode.isOperatorRecord(def)
        algorithm
          fnNode := instFunction3(fnNode);
          fnNode := OperatorOverloading.instConstructor(fnPath, fnNode, info);
        then
          (fnNode, false);

      case SCode.CLASS() guard SCode.isRecord(def)
        algorithm
          fnNode := instFunction3(fnNode);
          fnNode := Record.instDefaultConstructor(fnPath, fnNode, info);
        then
          (fnNode, false);

      case SCode.CLASS(restriction = SCode.R_OPERATOR(), classDef = cdef as SCode.PARTS())
        algorithm
          fnNode := instFunction3(fnNode);
          fnNode := OperatorOverloading.instOperatorFunctions(fnNode, info);
        then
          (fnNode, false);

      case SCode.CLASS(classDef = cdef as SCode.OVERLOAD())
        algorithm
          for p in cdef.pathLst loop
            cr := Absyn.pathToCref(p);
            (_,sub_fnNode,specialBuiltin) := instFunction(cr,fnNode,info);
            for f in getCachedFuncs(sub_fnNode) loop
              fnNode := InstNode.cacheAddFunc(fnNode, f, specialBuiltin);
            end for;
          end for;
        then
          (fnNode, false);

      case SCode.CLASS()
        algorithm
          if SCode.isOperator(def) then
            OperatorOverloading.checkOperatorRestrictions(fnNode);
          end if;

          fnNode := InstNode.setNodeType(NFInstNode.InstNodeType.ROOT_CLASS(), fnNode);
          fnNode := instFunction3(fnNode);
          fn := new(fnPath, fnNode);
          specialBuiltin := isSpecialBuiltin(fn);
          fn.derivatives := FunctionDerivative.instDerivatives(fnNode, fn);
          fnNode := InstNode.cacheAddFunc(fnNode, fn, specialBuiltin);
        then
          (fnNode, specialBuiltin);

    end match;
  end instFunction2;

  function instFunction3
    input output InstNode fnNode;
  algorithm
    fnNode := Inst.instantiate(fnNode);
    // Set up an empty function cache to signal that this function is
    // currently being instantiated, so recursive functions can be handled.
    InstNode.cacheInitFunc(fnNode);
    Inst.instExpressions(fnNode);
  end instFunction3;

  function getCachedFuncs
    input InstNode inNode;
    output list<Function> outFuncs;
  protected
    CachedData cache;
  algorithm
    cache := InstNode.getFuncCache(InstNode.classScope(inNode));
    outFuncs := match cache
      case CachedData.FUNCTION() then cache.funcs;
      else fail();
    end match;
  end getCachedFuncs;

  function isEvaluated
    input Function fn;
    output Boolean evaluated;
  algorithm
    evaluated := match Pointer.access(fn.status)
      case FunctionStatus.BUILTIN then true;
      case FunctionStatus.EVALUATED then true;
      else false;
    end match;
  end isEvaluated;

  function markEvaluated
    input Function fn;
  algorithm
    if Pointer.access(fn.status) <> FunctionStatus.BUILTIN then
      Pointer.update(fn.status, FunctionStatus.EVALUATED);
    end if;
  end markEvaluated;

  function isSimplified
    input Function fn;
    output Boolean simplified;
  algorithm
    simplified := match Pointer.access(fn.status)
      case FunctionStatus.BUILTIN then true;
      case FunctionStatus.SIMPLIFIED then true;
      else false;
    end match;
  end isSimplified;

  function markSimplified
    input Function fn;
  algorithm
    if Pointer.access(fn.status) <> FunctionStatus.BUILTIN then
      Pointer.update(fn.status, FunctionStatus.SIMPLIFIED);
    end if;
  end markSimplified;

  function isCollected
    "Returns true if this function has already been added to the function tree
     (or shouldn't be added, e.g. if it's builtin), otherwise false."
    input Function fn;
    output Boolean collected;
  algorithm
    collected := match Pointer.access(fn.status)
      case FunctionStatus.BUILTIN then true;
      case FunctionStatus.COLLECTED then true;
      else false;
    end match;
  end isCollected;

  function collect
    "Marks this function as collected for addition to the function tree."
    input Function fn;
  algorithm
    // The pointer might be immutable, check before assigning to it.
    if Pointer.access(fn.status) <> FunctionStatus.BUILTIN then
      Pointer.update(fn.status, FunctionStatus.COLLECTED);
    end if;
  end collect;

  function name
    input Function fn;
    output Absyn.Path path = fn.path;
  end name;

  function setName
    input Absyn.Path name;
    input output Function fn;
  algorithm
    fn.path := name;
  end setName;

  function nameConsiderBuiltin "Handles the DAE.mo structure where builtin calls are replaced by their simpler name"
    input Function fn;
    output Absyn.Path path;
  algorithm
    path := match fn.attributes.isBuiltin
      local
        String name;
      case DAE.FUNCTION_BUILTIN(name=SOME(name)) then Absyn.IDENT(name);
      case DAE.FUNCTION_BUILTIN() then Absyn.pathLast(fn.path);
      else fn.path;
    end match;
  end nameConsiderBuiltin;

  function signatureString
    "Constructs a signature string for a function, e.g. Real func(Real x, Real y)"
    input Function fn;
    input Boolean printTypes = true;
    output String str;
  protected
    Absyn.Path fn_name;
    String input_str, output_str, var_s;
    list<String> inputs_strl = {};
    list<InstNode> inputs = fn.inputs;
    Component c;
    Expression def_exp;
    Type ty;
  algorithm
    for s in fn.slots loop
      input_str := "";
      c := InstNode.component(listHead(inputs));
      inputs := listRest(inputs);

      // Add the default expression if it has any.
      if isSome(s.default) then
        SOME(def_exp) := s.default;
        input_str := " = " + Expression.toString(def_exp);
      end if;

      // Add the name from the slot and not the node, since some builtin
      // functions don't bother using proper names for the nodes.
      input_str := s.name + input_str;

      // Add a $ in front of the name if the parameter only takes positional
      // arguments.
      input_str := match s.ty
        case SlotType.POSITIONAL then "$" + input_str;
        else input_str;
      end match;

      // Add the type if the parameter has been typed.
      if printTypes and Component.isTyped(c) then
        ty := Component.getType(c);
        var_s := Prefixes.unparseVariability(Component.variability(c), ty);
        input_str := var_s + Type.toString(ty) + " " + input_str;
      end if;

      inputs_strl := input_str :: inputs_strl;
    end for;

    input_str := stringDelimitList(listReverse(inputs_strl), ", ");
    output_str := if printTypes and isTyped(fn) then " => " + Type.toString(fn.returnType) else "";
    fn_name := nameConsiderBuiltin(fn);
    // if isSome(display_name) then Util.getOption(display_name) else fn.path;
    str := Absyn.pathString(fn_name) + "(" + input_str + ")" + output_str;
  end signatureString;

  function candidateFuncListString
    input list<Function> fns;
    output String s = stringDelimitList(list(Function.signatureString(fn, true) for fn in fns), "\n  ");
  end candidateFuncListString;

  function callString
    "Constructs a string representing a call, for use in error messages."
    input Function fn;
    input list<Expression> posArgs;
    input list<NamedArg> namedArgs;
    output String str;
  algorithm
    str := stringDelimitList(list(Expression.toString(arg) for arg in posArgs), ", ");

    if not listEmpty(namedArgs) then
      str := str + ", " + stringDelimitList(
        list(Util.tuple21(arg) + " = " + Expression.toString(Util.tuple22(arg))
          for arg in namedArgs), ", ");
    end if;

    str := Absyn.pathString(fn.path) + "(" + str + ")";
  end callString;

  function typeString
    "Constructs a string representing the type of the function, on the form
     function_name<function>(input types) => output type"
    input Function fn;
    output String str;
  algorithm
    str := List.toString(fn.inputs, paramTypeString,
      Absyn.pathString(name(fn)) + "<function>",
      "(", ", ", ") => " + Type.toString(fn.returnType), true);
  end typeString;

  function paramTypeString
    input InstNode param;
    output String str = Type.toString(InstNode.getType(param));
  end paramTypeString;

  function instance
    input Function fn;
    output InstNode node = fn.node;
  end instance;

  function returnType
    input Function fn;
    output Type ty = fn.returnType;
  end returnType;

  function setReturnType
    input Type ty;
    input output Function fn;
  algorithm
    fn.returnType := ty;
  end setReturnType;

  function getSlots
    input Function fn;
    output list<Slot> slots = fn.slots;
  end getSlots;

  function fillArgs
    "Matches the given arguments to the slots in a function, and returns the
     arguments sorted in the order of the function parameters."
    input list<TypedArg> posArgs;
    input list<TypedNamedArg> namedArgs;
    input Function fn;
    input SourceInfo info;
    output list<TypedArg> args = posArgs;
    output Boolean matching;
  protected
    Slot slot;
    list<Slot> slots, remaining_slots;
    list<TypedArg> filled_named_args;
    array<Slot> slots_arr;
    Integer pos_arg_count, slot_count, index = 1;
  algorithm
    slots := fn.slots;
    pos_arg_count := listLength(posArgs);
    slot_count := listLength(slots);

    if pos_arg_count > slot_count then
      // If we have too many positional arguments it can't possibly match.
      matching := false;
      return;
    elseif pos_arg_count == slot_count and listEmpty(namedArgs) then
      // If we have exactly as many positional arguments as slots and no named
      // arguments we can just return the list of arguments as it is.
      matching := true;
      return;
    end if;

    slots_arr := listArray(slots);

    for arg in args loop
      slot := slots_arr[index];

      if not Slot.positional(slot) then
        // Slot doesn't allow positional arguments (used for some builtin functions).
        matching := false;
        return;
      end if;

      slot.arg := SOME(arg);
      arrayUpdate(slots_arr, index, slot);
      index := index + 1;
    end for;

    for narg in namedArgs loop
      (slots_arr, matching) := fillNamedArg(narg, slots_arr, fn, info);

      if not matching then
        return;
      end if;
    end for;

    (args, matching) := collectArgs(slots_arr, info);
  end fillArgs;

  function fillNamedArg
    "Looks up a slot with the given name and tries to fill it with the given
     argument expression."
    input TypedNamedArg inArg;
    input output array<Slot> slots;
    input Function fn "For error reporting";
    input SourceInfo info;
          output Boolean matching = true;
  protected
    Slot s;
    String argName;
    Type ty;
    Expression argExp;
    Variability var;
  algorithm
    // Try to find a slot and fill it with the argument expression.
    // Positional arguments fill the slots from the start of the array, so
    // searching backwards will generally be a bit more efficient.
    for i in arrayLength(slots):-1:1 loop
      s := slots[i];

      (argName, argExp, ty, var) := inArg;

      if s.name == argName then
        if not Slot.named(s) then
          // Slot doesn't allow named argument (used for some builtin functions).
          matching := false;
        elseif isNone(s.arg) then
          s.arg := SOME((argExp,ty,var));
          slots[i] := s;
        else
          // TODO: Improve the error message, should mention function name.
          Error.addSourceMessage(Error.FUNCTION_SLOT_ALREADY_FILLED,
            {argName, ""}, info);
          matching := false;
        end if;

        return;
      end if;
    end for;

    // No slot could be found.
    matching := false;

    // A slot with the given name couldn't be found. This means it doesn't
    // exist, or we removed it when handling positional argument. We need to
    // search through all slots to be sure.
    for s in fn.slots loop
      if argName == s.name then
        // We found a slot, so it must have already been filled.
        Error.addSourceMessage(Error.FUNCTION_SLOT_ALREADY_FILLED,
          {argName, ""}, info);
        return;
      end if;

      // No slot could be found, so it doesn't exist.
      Error.addSourceMessage(Error.NO_SUCH_PARAMETER,
        {InstNode.name(instance(fn)), argName}, info);
    end for;

  end fillNamedArg;

  function collectArgs
    "Collects the arguments from the given slots."
    input array<Slot> slots;
    input SourceInfo info;
    output list<TypedArg> args = {};
    output Boolean matching = true;
  protected
    Option<Expression> default;
    Expression e;
    Option<TypedArg> arg;
    TypedArg a;
    String name;
  algorithm
    for s in slots loop
      SLOT(name = name, default = default, arg = arg) := s;

      args := matchcontinue arg
        // Use the argument from the call if one was given.
        case SOME(a) then a :: args;

        // Otherwise, try to fill the slot with its default argument.
        case _ then fillDefaultSlot(s, slots, info) :: args;

        else
          algorithm
            matching := false;
          then
            args;
      end matchcontinue;
    end for;

    args := listReverse(args);
  end collectArgs;

  function fillDefaultSlot
    input Slot slot;
    input array<Slot> slots;
    input SourceInfo info;
    output TypedArg outArg;
  algorithm
    outArg := match slot
      // Slot already filled by function argument.
      case SLOT(arg = SOME(outArg)) then outArg;

      // Slot not filled by function argument, but has default value.
      case SLOT(default = SOME(_))
        then fillDefaultSlot2(slot, slots, info);

      // Give an error if no argument was given and there's no default argument.
      else
        algorithm
          Error.addSourceMessage(Error.UNFILLED_SLOT, {slot.name}, info);
        then
          fail();

    end match;
  end fillDefaultSlot;

  function fillDefaultSlot2
    input Slot slot;
    input array<Slot> slots;
    input SourceInfo info;
    output TypedArg outArg;
  algorithm
    outArg := match slot.evalStatus
      local
        Expression exp;

      // An already evaluated slot, return its binding.
      case SlotEvalStatus.EVALUATED
        then Util.getOption(slot.arg);

      // A slot in the process of being evaluated => cyclic bindings.
      case SlotEvalStatus.EVALUATING
        algorithm
          Error.addSourceMessage(Error.CYCLIC_DEFAULT_VALUE, {slot.name}, info);
        then
          fail();

      // A slot with a not evaluated binding, evaluate the binding and return it.
      case SlotEvalStatus.NOT_EVALUATED
        algorithm
          slot.evalStatus := SlotEvalStatus.EVALUATING;
          arrayUpdate(slots, slot.index, slot);

          exp := evaluateSlotExp(Util.getOption(slot.default), slots, info);
          outArg := (exp, Expression.typeOf(exp), Expression.variability(exp));

          slot.arg := SOME(outArg);
          slot.evalStatus := SlotEvalStatus.EVALUATED;
          arrayUpdate(slots, slot.index, slot);
        then
          outArg;

    end match;
  end fillDefaultSlot2;

  function evaluateSlotExp
    input Expression exp;
    input array<Slot> slots;
    input SourceInfo info;
    output Expression outExp;
  algorithm
    outExp := Expression.map(exp,
      function evaluateSlotExp_traverser(slots = slots, info = info));
  end evaluateSlotExp;

  function evaluateSlotExp_traverser
    input Expression exp;
    input array<Slot> slots;
    input SourceInfo info;
    output Expression outExp;
  algorithm
    outExp := match exp
      local
        ComponentRef cref;
        Option<Slot> slot;

      case Expression.CREF(cref = cref as ComponentRef.CREF(restCref = ComponentRef.EMPTY()))
        algorithm
          slot := lookupSlotInArray(ComponentRef.firstName(cref), slots);
        then
          if isSome(slot) then Util.tuple31(fillDefaultSlot(Util.getOption(slot), slots, info)) else exp;

      else exp;
    end match;
  end evaluateSlotExp_traverser;

  function lookupSlotInArray
    input String slotName;
    input array<Slot> slots;
    output Option<Slot> outSlot;
  protected
    Slot slot;
  algorithm
    try
      slot := Array.getMemberOnTrue(slotName, slots, Slot.hasName);
      outSlot := SOME(slot);
    else
      outSlot := NONE();
    end try;
  end lookupSlotInArray;

  function matchArgsVectorize
    input Function func;
    input output list<TypedArg> args;
    input SourceInfo info;
          output Boolean correct;
          output FunctionMatchKind funcMatchKind = EXACT_MATCH;
  protected
    Component comp;
    InstNode inputnode;
    list<InstNode> inputs;
    Expression argexp, margexp, vect_arg;
    Type argty, compty, tmpty, mty;
    Variability var;
    list<TypedArg> checked_args;
    Integer idx;
    TypeCheck.MatchKind matchKind;
    list<Dimension> argdims, compdims, vectdims, tmpdims, outvectdims;
    Boolean has_cast;
    list<Boolean> vectorized;
    FunctionMatchKind base_mk = EXACT_MATCH;
  algorithm
    checked_args := {};
    idx := 1;
    inputs := func.inputs;
    outvectdims := {};
    vectorized := {};
    has_cast := false;
    vect_arg := Expression.INTEGER(0);

    for arg in args loop
      (argexp,argty,var) := arg;
      inputnode :: inputs := inputs;
      comp := InstNode.component(inputnode);
      compty := Component.getType(comp);
      compdims := Type.arrayDims(compty);
      argdims := Type.arrayDims(argty);

      correct := false;
      if listLength(argdims) == listLength(compdims) then
        // We have unvectorized match. Keep it.
        (margexp, mty, matchKind) := TypeCheck.matchTypes(argty, compty, argexp, false);
        correct := TypeCheck.isValidArgumentMatch(matchKind);
        vectorized := false::vectorized;

      elseif listLength(argdims) > listLength(compdims) then
        // Try vectorized matching since we have more dims in the actual argument.
        (vectdims, tmpdims) := List.split(argdims, listLength(argdims)-listLength(compdims));

        // make sure the vectorization dims are consistent.
        if listEmpty(outvectdims) then
          outvectdims := vectdims;
          vect_arg := argexp;
        elseif not List.isEqualOnTrue(outvectdims, vectdims, Dimension.isEqual) then
          Error.addSourceMessage(Error.VECTORIZE_CALL_DIM_MISMATCH,
            {"", Expression.toString(vect_arg), "", Expression.toString(argexp),
             Dimension.toStringList(outvectdims), Dimension.toStringList(vectdims)}, info);
          fail();
        end if;

        tmpty := Type.arrayElementType(argty);
        if not listEmpty(tmpdims) then
          tmpty := Type.ARRAY(tmpty, tmpdims);
        end if;

        (margexp, mty, matchKind) := TypeCheck.matchTypes(tmpty, compty, argexp, false);
        correct := TypeCheck.isValidArgumentMatch(matchKind);
        vectorized := true::vectorized;
      end if;

      // Type mismatch, print an error.
      if not correct then
        Error.addSourceMessage(Error.ARG_TYPE_MISMATCH, {
          intString(idx), Absyn.pathString(func.path), InstNode.name(inputnode), Expression.toString(argexp),
          Type.toString(argty), Type.toString(compty)
        }, info);
        funcMatchKind := NO_MATCH;
        return;
      end if;

      // Variability mismatch, print an error.
      if var > Component.variability(comp) then
        correct := false;
        Error.addSourceMessage(Error.FUNCTION_SLOT_VARIABILITY, {
          InstNode.name(inputnode), Expression.toString(argexp),
          Absyn.pathString(Function.name(func)),
          Prefixes.variabilityString(var),
          Prefixes.variabilityString(Component.variability(comp))
        }, info);
        funcMatchKind := NO_MATCH;
        return;
      end if;

      if TypeCheck.isCastMatch(matchKind) then
        base_mk := CAST_MATCH;
      elseif TypeCheck.isGenericMatch(matchKind) then
        base_mk := GENERIC_MATCH;
      end if;

      checked_args := (margexp,mty,var) :: checked_args;
      idx := idx + 1;
    end for;

    correct := true;
    args := listReverse(checked_args);
    funcMatchKind := VECTORIZED(vectdims, listReverse(vectorized), base_mk);
  end matchArgsVectorize;

  function matchArgs
    input Function func;
    input output list<TypedArg> args;
    input SourceInfo info;
          output Boolean correct;
          output FunctionMatchKind funcMatchKind = EXACT_MATCH;
  protected
    Component comp;
    InstNode inputnode;
    list<InstNode> inputs;
    Expression argexp, margexp;
    Type ty, mty;
    Variability var;
    list<TypedArg> checked_args;
    Integer idx;
    TypeCheck.MatchKind matchKind;
  algorithm

    checked_args := {};
    idx := 1;
    inputs := func.inputs;

    for arg in args loop
      (argexp,ty,var) := arg;
      inputnode :: inputs := inputs;
      comp := InstNode.component(inputnode);

      (margexp, mty, matchKind) := TypeCheck.matchTypes(ty, Component.getType(comp), argexp, allowUnknown = true);
      correct := TypeCheck.isValidArgumentMatch(matchKind);
      // TODO: This should be a running reduction of the matches. Not just based on the
      // last match.
      if TypeCheck.isCastMatch(matchKind) then
        funcMatchKind := CAST_MATCH;
      elseif TypeCheck.isGenericMatch(matchKind) then
        funcMatchKind := GENERIC_MATCH;
      end if;

      // Type mismatch, print an error.
      if not correct then
        Error.addSourceMessage(Error.ARG_TYPE_MISMATCH, {
          intString(idx), Absyn.pathString(func.path), InstNode.name(inputnode), Expression.toString(argexp),
          Type.toString(ty), Type.toString(Component.getType(comp))
        }, info);
        funcMatchKind := NO_MATCH;
        return;
      end if;

      // Variability mismatch, print an error.
      if var > Component.variability(comp) then
        correct := false;
        Error.addSourceMessage(Error.FUNCTION_SLOT_VARIABILITY, {
          InstNode.name(inputnode), Expression.toString(argexp),
          Absyn.pathString(name(func)),
          Prefixes.variabilityString(var),
          Prefixes.variabilityString(Component.variability(comp))
        }, info);
        funcMatchKind := NO_MATCH;
        return;
      end if;

      checked_args := (margexp,mty,var) :: checked_args;
      idx := idx + 1;
    end for;

    correct := true;
    args := listReverse(checked_args);
  end matchArgs;

  function matchFunction
    input Function func;
    input list<TypedArg> args;
    input list<TypedNamedArg> named_args;
    input SourceInfo info;
    input Boolean vectorize = true;
    output list<TypedArg> out_args;
    output FunctionMatchKind matchKind = NO_MATCH;
  protected
    Boolean slot_matched, matched;
  algorithm
    (out_args, slot_matched) := fillArgs(args, named_args, func, info);
    if slot_matched then
      (out_args, matched, matchKind) := matchArgs(func, out_args, info);

      // If we failed to match a function normally then we try to see if
      // we can have a vectorized match.
      if not matched and vectorize then
        (out_args, matched, matchKind) := matchArgsVectorize(func, out_args, info);
      end if;
    end if;
  end matchFunction;

  function matchFunctions
    input list<Function> funcs;
    input list<TypedArg> args;
    input list<TypedNamedArg> named_args;
    input SourceInfo info;
    input Boolean vectorize = true;
    output list<MatchedFunction> matchedFunctions;
  protected
    list<TypedArg> m_args;
    FunctionMatchKind matchKind;
    Boolean matched;
  algorithm
    matchedFunctions := {};
    for func in funcs loop
      (m_args, matchKind) := matchFunction(func, args, named_args, info, vectorize);

      if FunctionMatchKind.isValid(matchKind) then
        matchedFunctions := MatchedFunction.MATCHED_FUNC(func,m_args,matchKind)::matchedFunctions;
      end if;
    end for;
  end matchFunctions;

  function matchFunctionsSilent
    input list<Function> funcs;
    input list<TypedArg> args;
    input list<TypedNamedArg> named_args;
    input SourceInfo info;
    input Boolean vectorize = true;
    output list<MatchedFunction> matchedFunctions;
  protected
  algorithm
    ErrorExt.setCheckpoint("NFFunction:matchFunctions");
    matchedFunctions := matchFunctions(funcs, args, named_args, info, vectorize);
    ErrorExt.rollBack("NFFunction:matchFunctions");
  end matchFunctionsSilent;

  function isTyped
    input Function fn;
    output Boolean isTyped;
  algorithm
    isTyped := match fn.returnType
      case Type.UNKNOWN() then false;
      else true;
    end match;
  end isTyped;

  function typeRefCache
    "Returns the function(s) referenced by the given cref, and types them if
     they are not already typed."
    input ComponentRef functionRef;
    output list<Function> functions;
  algorithm
    functions := match functionRef
      case ComponentRef.CREF() then typeNodeCache(functionRef.node);
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got invalid function call reference", sourceInfo());
        then
          fail();
    end match;
  end typeRefCache;

  function typeNodeCache
    "Returns the function(s) in the cache of the given node, and types them if
     they are not already typed."
    input InstNode functionNode;
    output list<Function> functions;
  protected
    InstNode fn_node;
    Boolean typed, special;
    String name;
  algorithm
    fn_node := InstNode.classScope(functionNode);
    CachedData.FUNCTION(functions, typed, special) := InstNode.getFuncCache(fn_node);

    // Type the function(s) if not already done.
    if not typed then
      functions := list(typeFunctionSignature(f) for f in functions);
      InstNode.setFuncCache(fn_node, CachedData.FUNCTION(functions, true, special));
      functions := list(typeFunctionBody(f) for f in functions);
      InstNode.setFuncCache(fn_node, CachedData.FUNCTION(functions, true, special));
    end if;
  end typeNodeCache;

  function getRefCache
    input ComponentRef fnRef;
    output list<Function> functions;
  protected
    InstNode fn_node;
  algorithm
    fn_node := InstNode.classScope(ComponentRef.node(fnRef));
    CachedData.FUNCTION(funcs = functions) := InstNode.getFuncCache(fn_node);
  end getRefCache;

  function typeFunction
    input output Function fn;
  algorithm
    fn := typeFunctionSignature(fn);
    fn := typeFunctionBody(fn);
  end typeFunction;

  function typeFunctionSignature
    "Types a function's parameters, local components and default arguments."
    input output Function fn;
  protected
    DAE.FunctionAttributes attr;
    InstNode node = fn.node;
  algorithm
    if not isTyped(fn) then
      // Type all the components in the function.
      Typing.typeClassType(node, NFBinding.EMPTY_BINDING, ExpOrigin.FUNCTION, node);
      Typing.typeComponents(node, ExpOrigin.FUNCTION);

      if InstNode.isPartial(node) then
        ClassTree.applyComponents(Class.classTree(InstNode.getClass(node)), boxFunctionParameter);
      end if;

      // Type the bindings of the inputs only. This is done because they are
      // needed when type checking a function call. The outputs are not needed
      // for that and can contain recursive calls to the function, so we leave
      // them for later.
      for c in fn.inputs loop
        Typing.typeComponentBinding(c, ExpOrigin.FUNCTION);
      end for;

      // Make the slots and return type for the function.
      fn.slots := makeSlots(fn.inputs);
      checkParamTypes(fn);
      fn.returnType := makeReturnType(fn);
    end if;
  end typeFunctionSignature;

  function typeFunctionBody
    "Types the body of a function, along with any bindings of local variables
     and outputs."
    input output Function fn;
  algorithm
    // Type the bindings of the outputs and local variables.
    for c in fn.outputs loop
      Typing.typeComponentBinding(c, ExpOrigin.FUNCTION);
    end for;

    for c in fn.locals loop
      Typing.typeComponentBinding(c, ExpOrigin.FUNCTION);
    end for;

    // Type the algorithm section of the function, if it has one.
    Typing.typeFunctionSections(fn.node, ExpOrigin.FUNCTION);

    // Type any derivatives of the function.
    for fn_der in fn.derivatives loop
      FunctionDerivative.typeDerivative(fn_der);
    end for;
  end typeFunctionBody;

  function boxFunctionParameter
    input InstNode component;
  protected
    Component comp;
  algorithm
    comp := InstNode.component(component);
    comp := Component.setType(Type.box(Component.getType(comp)), comp);
    InstNode.updateComponent(comp, component);
  end boxFunctionParameter;

  function typePartialApplication
    input output Expression exp;
    input ExpOrigin.Type origin;
    input SourceInfo info;
          output Type ty;
          output Variability variability;
  protected
    ComponentRef fn_ref;
    list<Expression> args, ty_args = {};
    list<String> arg_names, rest_names;
    String arg_name;
    Expression arg_exp;
    Type arg_ty;
    Variability arg_var;
    Function fn;
    ExpOrigin.Type next_origin = ExpOrigin.setFlag(origin, ExpOrigin.SUBEXPRESSION);
    list<InstNode> inputs;
    list<Slot> slots;
  algorithm
    Expression.PARTIAL_FUNCTION_APPLICATION(fn = fn_ref, args = args, argNames = arg_names) := exp;
    // TODO: Handle overloaded functions?
    fn :: _ := typeRefCache(fn_ref);
    inputs := fn.inputs;
    slots := fn.slots;
    rest_names := arg_names;

    variability := if Function.isImpure(fn) or Function.isOMImpure(fn)
      then Variability.PARAMETER else Variability.CONSTANT;

    for arg in args loop
      (arg, arg_ty, arg_var) := Typing.typeExp(arg, origin, info);

      arg_name :: rest_names := rest_names;
      (arg, inputs, slots) :=
        applyPartialApplicationArg(arg_name, arg, arg_ty, inputs, slots, fn, info);

      ty_args := Expression.box(arg) :: ty_args;
      variability := Prefixes.variabilityMax(variability, arg_var);
    end for;

    fn.inputs := inputs;
    fn.slots := slots;
    ty := Type.FUNCTION(fn, NFType.FunctionType.FUNCTIONAL_VARIABLE);
    exp := Expression.PARTIAL_FUNCTION_APPLICATION(fn_ref, listReverseInPlace(ty_args), arg_names, ty);
  end typePartialApplication;

  function applyPartialApplicationArg
    input String argName;
    input output Expression argExp;
    input Type argType;
    input list<InstNode> inputs;
    input list<Slot> slots;
    input Function fn;
    input SourceInfo info;
          output list<InstNode> outInputs = {};
          output list<Slot> outSlots = {};
  protected
    InstNode i;
    list<InstNode> rest_inputs = inputs;
    Slot s;
    list<Slot> rest_slots = slots;
    TypeCheck.MatchKind mk;
  algorithm
    while not listEmpty(rest_inputs) loop
      i :: rest_inputs := rest_inputs;
      s :: rest_slots := rest_slots;

      if s.name == argName then
        (argExp, _, mk) := TypeCheck.matchTypes(argType, InstNode.getType(i), argExp, true);

        if TypeCheck.isIncompatibleMatch(mk) then
          Error.addSourceMessage(Error.NAMED_ARG_TYPE_MISMATCH,
            {Absyn.pathString(name(fn)), argName, Expression.toString(argExp),
             Type.toString(argType), Type.toString(InstNode.getType(i))}, info);
          fail();
        end if;

        outInputs := listAppend(listReverseInPlace(outInputs), rest_inputs);
        outSlots := listAppend(listReverseInPlace(outSlots), rest_slots);
        return;
      end if;

      outInputs := i :: outInputs;
      outSlots := s :: outSlots;
    end while;

    Error.addSourceMessage(Error.NO_SUCH_INPUT_PARAMETER,
      {Absyn.pathString(name(fn)), argName}, info);
    fail();
  end applyPartialApplicationArg;

  function isBuiltin
    input Function fn;
    output Boolean isBuiltin = isBuiltinAttr(fn.attributes);
  end isBuiltin;

  function isBuiltinAttr
    input DAE.FunctionAttributes attrs;
    output Boolean isBuiltin;
  algorithm
    isBuiltin := match attrs.isBuiltin
      case DAE.FunctionBuiltin.FUNCTION_NOT_BUILTIN() then false;
      else true;
    end match;
  end isBuiltinAttr;

  function isSpecialBuiltin
    input Function fn;
    output Boolean special;
  protected
    Absyn.Path path;
  algorithm
    if not isBuiltin(fn) then
      special := false;
    else
      path := Function.nameConsiderBuiltin(fn);

      if not Absyn.pathIsIdent(path) then
        special := false;
      else
        special := match Absyn.pathFirstIdent(path)
          // Can have variable number of arguments.
          case "array" then true;
          case "branch" then true;
          case "cardinality" then true;
          case "cat" then true;
          // Function should not be used in function context.
          // argument should be a cref?
          case "change" then true;
          case "der" then true;
          case "diagonal" then true;
          // Function should not be used in function context.
          case "edge" then true;
          // can have variable number of arguments
          case "fill" then true;
          case "getInstanceName" then true;
          // Always discrete.
          case "initial" then true;
          case "isRoot" then true;
          // Arguments can be scalar, vector, matrix, 3d array .... basically anything
          // We need to make sure size(Arg,i) = 1 for 2 < i <= ndims(Arg).
          // return type should always be Matrix.
          case "matrix" then true;
          // Needs to check that arguments are basic types or enums
          // We need to check array inputs as well
          case "max" then true;
          // Needs to check that arguments are basic types or enums
          // We need to check array inputs as well
          case "min" then true;
          // Argument can have any number of dimensions.
          case "ndims" then true;
          // Can take any expression as argument.
          case "noEvent" then true;
          // can have variable number of arguments
          case "ones" then true;
          case "potentialRoot" then true;
          // Function should not be used in function context.
          // argument should be a cref?
          case "pre" then true;
          // needs unboxing and return type fix.
          case "product" then true;
          case "root" then true;
          case "rooted" then true;
          // We need to make sure size(Arg,i) = 1 for 0 <= i <= ndims(Arg).
          // return type should always be scalar.
          case "scalar" then true;
          // First argument can have any number of dimensions.
          case "size" then true;
          // Needs to check that second argument is real or array of real or record of reals.
          case "smooth" then true;
          // needs unboxing and return type fix.
          case "sum" then true;
          // unbox args and set return type.
          case "symmetric" then true;
          // Always discrete.
          case "terminal" then true;
          // unbox args and set return type (swap the first two dims).
          case "transpose" then true;
          // We need to construct output diminsion size from the size of elements in the array
          // return type should always be vector.
          case "vector" then true;
          // can have variable number of arguments
          case "zeros" then true;
          // sample - overloaded for sync features
          case "sample" then true;
          else false;
        end match;
      end if;
    end if;
  end isSpecialBuiltin;

  function isSubscriptableBuiltin
    input Function fn;
    output Boolean scalarBuiltin;
  protected
  algorithm
    if not isBuiltin(fn) then
      scalarBuiltin := false;
    else
      scalarBuiltin := match Absyn.pathFirstIdent(Function.nameConsiderBuiltin(fn))
        case "change" then true;
        case "der" then true;
        case "pre" then true;
        else false;
      end match;
    end if;
  end isSubscriptableBuiltin;

  function isImpure
    input Function fn;
    output Boolean isImpure = fn.attributes.isImpure;
  end isImpure;

  function isOMImpure
    input Function fn;
    output Boolean isImpure = not fn.attributes.isOpenModelicaPure;
  end isOMImpure;

  function isFunctionPointer
    input Function fn;
    output Boolean isPointer = fn.attributes.isFunctionPointer;
  end isFunctionPointer;

  function setFunctionPointer
    input Boolean isPointer;
    input output Function fn;
  protected
    DAE.FunctionAttributes attr = fn.attributes;
  algorithm
    attr.isFunctionPointer := isPointer;
    fn.attributes := attr;
    // The whole function should just be this, but it doesn't compile yet.
    //fn.attributes.isFunctionPointer := isPointer;
  end setFunctionPointer;

  function isExternal
    input Function fn;
    output Boolean isExternal = not InstNode.isEmpty(fn.node) and
                                Class.isExternalFunction(InstNode.getClass(fn.node));
  end isExternal;

  function inlineBuiltin
    input Function fn;
    output DAE.InlineType inlineType;
  algorithm
    inlineType := match fn.attributes.isBuiltin
      case DAE.FunctionBuiltin.FUNCTION_BUILTIN_PTR()
        then DAE.InlineType.BUILTIN_EARLY_INLINE();
      else fn.attributes.inline;
    end match;
  end inlineBuiltin;

  function isDefaultRecordConstructor
    input Function fn;
    output Boolean isConstructor;
  algorithm
    isConstructor := match Class.restriction(InstNode.getClass(fn.node))
      case Restriction.RECORD_CONSTRUCTOR() then true;
      else false;
    end match;
  end isDefaultRecordConstructor;

  function toDAE
    input Function fn;
    input DAE.FunctionDefinition def;
    output DAE.Function daeFn;
  protected
    SCode.Visibility vis;
    Boolean par, impr;
    DAE.InlineType ity;
    DAE.Type ty;
    list<DAE.FunctionDefinition> defs;
  algorithm
    vis := SCode.PUBLIC(); // TODO: Use the actual visibility.
    par := false; // TODO: Use the actual partial prefix.
    impr := fn.attributes.isImpure;
    ity := fn.attributes.inline;
    ty := makeDAEType(fn);
    defs := def :: list(FunctionDerivative.toDAE(fn_der) for fn_der in fn.derivatives);
    daeFn := DAE.FUNCTION(fn.path, defs, ty, vis, par, impr, ity,
      ElementSource.createElementSource(InstNode.info(fn.node)),
      SCode.getElementComment(InstNode.definition(fn.node)));
  end toDAE;

  function makeDAEType
    input Function fn;
    input Boolean boxTypes = false;
    output DAE.Type outType;
  protected
    list<DAE.FuncArg> params = {};
    String pname;
    Type ty;
    DAE.Type ptype;
    DAE.Const pconst;
    DAE.VarParallelism ppar;
    Option<DAE.Exp> pdefault;
    Component comp;
  algorithm
    for param in fn.inputs loop
      comp := InstNode.component(param);
      pname := InstNode.name(param);
      ty := Component.getType(comp);
      ptype := Type.toDAE(if boxTypes then Type.box(ty) else ty);
      pconst := Prefixes.variabilityToDAEConst(Component.variability(comp));
      ppar := Prefixes.parallelismToDAE(Component.parallelism(comp));
      pdefault := Util.applyOption(Binding.typedExp(Component.getBinding(comp)), Expression.toDAE);
      params := DAE.FuncArg.FUNCARG(pname, ptype, pconst, ppar, pdefault) :: params;
    end for;

    params := listReverse(params);
    ty := if boxTypes then Type.box(fn.returnType) else fn.returnType;
    outType := DAE.T_FUNCTION(params, Type.toDAE(ty), fn.attributes, fn.path);
  end makeDAEType;

  function getBody
    input Function fn;
    output list<Statement> body = getBody2(fn.node);
  end getBody;

  function hasUnboxArgs
    "Returns true if the function has the __OpenModelica_UnboxArguments annotation, otherwise false."
    input Function fn;
    output Boolean res;
  algorithm
    res := match fn.attributes
      case DAE.FunctionAttributes.FUNCTION_ATTRIBUTES(
        isBuiltin = DAE.FunctionBuiltin.FUNCTION_BUILTIN(unboxArgs = res)) then res;
      else false;
    end match;
  end hasUnboxArgs;

  function hasUnboxArgsAnnotation
    input SCode.Comment cmt;
    output Boolean res = SCode.commentHasBooleanNamedAnnotation(cmt, "__OpenModelica_UnboxArguments");
  end hasUnboxArgsAnnotation;

  function hasOptionalArgument
    input SCode.Element component;
    output Boolean res = SCode.hasBooleanNamedAnnotationInComponent(component, "__OpenModelica_optionalArgument");
  end hasOptionalArgument;

  function mapExp
    input output Function fn;
    input MapFunc mapFn;
    input Boolean mapParameters = true;
    input Boolean mapBody = true;

    partial function MapFunc
      input output Expression exp;
    end MapFunc;
  protected
    Class cls;
    ClassTree ctree;
    array<InstNode> comps;
    Sections sections;
    Component comp;
    Binding binding, binding2;
  algorithm
    cls := InstNode.getClass(fn.node);

    if mapParameters then
      ctree := Class.classTree(cls);
      ClassTree.applyComponents(ctree, function mapExpParameter(mapFn = mapFn));
      fn.returnType := makeReturnType(fn);
    end if;

    if mapBody then
      sections := Sections.mapExp(Class.getSections(cls), mapFn);
      cls := cls.setSections(sections, cls);
      InstNode.updateClass(cls, fn.node);
    end if;
  end mapExp;

  function mapExpParameter
    input InstNode node;
    input MapFunc mapFn;

    partial function MapFunc
      input output Expression exp;
    end MapFunc;
  protected
    Component comp;
    Binding binding, binding2;
    Class cls;
    Type ty;
    Boolean dirty = false;
  algorithm
    if not InstNode.isEmpty(node) then
      comp := InstNode.component(node);
      binding := Component.getBinding(comp);
      binding2 := Binding.mapExp(binding, mapFn);

      if not referenceEq(binding, binding2) then
        comp := Component.setBinding(binding2, comp);
        dirty := true;
      end if;

      () := match comp
        case Component.TYPED_COMPONENT()
          algorithm
            ty := Type.mapDims(comp.ty, function Dimension.mapExp(func = mapFn));

            if not referenceEq(ty, comp.ty) then
              comp.ty := ty;
              dirty := true;
            end if;

            cls := InstNode.getClass(comp.classInst);
            ClassTree.applyComponents(Class.classTree(cls),
              function mapExpParameter(mapFn = mapFn));
          then
            ();

        else ();
      end match;

      if dirty then
        InstNode.updateComponent(comp, node);
      end if;
    end if;
  end mapExpParameter;

  function isPartial
    input Function fn;
    output Boolean isPartial = InstNode.isPartial(fn.node);
  end isPartial;

protected
  function collectParams
    "Sorts all the function parameters as inputs, outputs and locals."
    input InstNode node;
    input output list<InstNode> inputs = {};
    input output list<InstNode> outputs = {};
    input output list<InstNode> locals = {};
  protected
    Class cls;
    array<InstNode> comps;
    InstNode n;
  algorithm
    Error.assertion(InstNode.isClass(node), getInstanceName() + " got non-class node", sourceInfo());
    cls := InstNode.getClass(node);

    () := match cls
      case Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps))
        algorithm
          for i in arrayLength(comps):-1:1 loop
            n := comps[i];

            if InstNode.isEmpty(n) then
              continue;
            end if;

            // Sort the components based on their direction.
            () := match paramDirection(n)
              case Direction.INPUT algorithm inputs := n :: inputs; then ();
              case Direction.OUTPUT algorithm outputs := n :: outputs; then ();
              case Direction.NONE algorithm locals := n :: locals; then ();
            end match;
          end for;
        then
          ();

      case Class.EXPANDED_DERIVED()
        algorithm
          (inputs, outputs, locals) := collectParams(cls.baseClass);
        then
          ();

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got non-instantiated function", sourceInfo());
        then
          fail();
    end match;
  end collectParams;

  function paramDirection
    input InstNode component;
    output Direction direction;
  protected
    ConnectorType cty;
    InnerOuter io;
    Visibility vis;
    Variability var;
  algorithm
    Component.Attributes.ATTRIBUTES(
      connectorType = cty,
      direction = direction,
      innerOuter = io) := Component.getAttributes(InstNode.component(component));

    vis := InstNode.visibility(component);
    var := Component.variability(InstNode.component(component));

    // Function components may not be connectors.
    if cty == ConnectorType.FLOW or cty == ConnectorType.STREAM then
      Error.addSourceMessage(Error.INNER_OUTER_FORMAL_PARAMETER,
        {Prefixes.connectorTypeString(cty), InstNode.name(component)},
        InstNode.info(component));
      fail();
    end if;

    // Function components may not be inner/outer.
    if io <> InnerOuter.NOT_INNER_OUTER then
      Error.addSourceMessage(Error.INNER_OUTER_FORMAL_PARAMETER,
        {Prefixes.innerOuterString(io), InstNode.name(component)},
        InstNode.info(component));
      fail();
    end if;

    // Formal parameters must be public, other function variables must be protected.
    if direction <> Direction.NONE then
      if vis == Visibility.PROTECTED then
        Error.addSourceMessage(Error.PROTECTED_FORMAL_FUNCTION_VAR,
          {InstNode.name(component)}, InstNode.info(component));
        fail();
      end if;
    else

      if vis == Visibility.PUBLIC then
        Error.addSourceMessage(Error.NON_FORMAL_PUBLIC_FUNCTION_VAR,
          {InstNode.name(component)}, InstNode.info(component));
        // @adrpo: alow public constants and parameters in functions
        if var > Variability.PARAMETER then
          fail();
        end if;
      end if;
    end if;
  end paramDirection;

  function makeSlots
    input list<InstNode> inputs;
    output list<Slot> slots = {};
  protected
    Integer index = 1;
  algorithm
    for i in inputs loop
      slots := makeSlot(i, index) :: slots;
      index := index + 1;
    end for;

    slots := listReverseInPlace(slots);
  end makeSlots;

  function makeSlot
    input InstNode component;
    input Integer index;
    output Slot slot;
  protected
    Component comp;
    Option<Expression> default;
    String name;
  algorithm
    try
      comp := InstNode.component(component);
      default := Binding.typedExp(Component.getBinding(comp));
      name := InstNode.name(component);

      // Remove $in_ for OM input output arguments.
      if stringGet(name, 1) == 36 /*$*/ then
        if stringLength(name) > 4 and substring(name, 1, 4) == "$in_" then
          name := substring(name, 5, stringLength(name));
        end if;
      end if;

      slot := SLOT(InstNode.name(component), SlotType.GENERIC, default, NONE(), index, SlotEvalStatus.NOT_EVALUATED);
    else
      Error.assertion(false, getInstanceName() + " got invalid component", sourceInfo());
    end try;
  end makeSlot;

  function hasOMPure
    input SCode.Comment cmt;
    output Boolean res =
      not SCode.commentHasBooleanNamedAnnotation(cmt, "__OpenModelica_Impure");
  end hasOMPure;

  function hasImpure
    input SCode.Comment cmt;
    output Boolean res =
      SCode.commentHasBooleanNamedAnnotation(cmt, "__ModelicaAssociation_Impure");
  end hasImpure;

  function getBuiltin
    input SCode.Element def;
    output DAE.FunctionBuiltin builtin = if SCode.isBuiltinElement(def) then
       DAE.FUNCTION_BUILTIN_PTR() else DAE.FUNCTION_NOT_BUILTIN();
  end getBuiltin;

  function mergeFunctionAnnotations
    "Merges the function's comments from inherited classes."
    input list<SCode.Comment> comments;
    output SCode.Comment outComment;
  protected
    Option<String> comment = NONE();
    SCode.Mod mod = SCode.NOMOD(), mod2;
  algorithm
    for cmt in comments loop
      if isNone(comment) then
        comment := cmt.comment;
      end if;

      mod := match cmt
        case SCode.COMMENT(annotation_ = SOME(SCode.ANNOTATION(modification = mod2)))
          then SCode.mergeModifiers(mod2, mod);
        else mod;
      end match;
    end for;

    outComment := match mod
      case SCode.NOMOD() then SCode.COMMENT(NONE(), comment);
      else SCode.COMMENT(SOME(SCode.ANNOTATION(mod)), comment);
    end match;
  end mergeFunctionAnnotations;

  function makeAttributes
    input InstNode node;
    input list<InstNode> inputs;
    input list<InstNode> outputs;
    output DAE.FunctionAttributes attr;
  protected
    SCode.Element def;
    array<InstNode> params;
    SCode.Restriction res;
    SCode.FunctionRestriction fres;
    Boolean is_partial;
    list<SCode.Comment> cmts;
    SCode.Comment cmt;
  algorithm
    def := InstNode.definition(node);
    res := SCode.getClassRestriction(def);

    Error.assertion(SCode.isFunctionRestriction(res), getInstanceName() + " got non-function restriction", sourceInfo());

    SCode.Restriction.R_FUNCTION(functionRestriction = fres) := res;
    is_partial := SCode.isPartial(def);

    cmts := InstNode.getComments(node);
    cmt := mergeFunctionAnnotations(cmts);

    attr := matchcontinue fres
      local
        Boolean is_impure, is_om_pure, has_out_params, has_unbox_args;
        String name;
        list<String> in_params, out_params;
        DAE.InlineType inline_ty;
        DAE.FunctionBuiltin builtin;

      // External function.
      case SCode.FunctionRestriction.FR_EXTERNAL_FUNCTION(is_impure)
        algorithm
          in_params := list(InstNode.name(i) for i in inputs);
          out_params := list(InstNode.name(o) for o in outputs);
          name := SCode.isBuiltinFunction(def, in_params, out_params);
          inline_ty := InstUtil.commentIsInlineFunc(cmt);
          is_impure := is_impure or hasImpure(cmt);
          has_unbox_args := hasUnboxArgsAnnotation(cmt);
        then
          DAE.FUNCTION_ATTRIBUTES(inline_ty, hasOMPure(cmt), is_impure, is_partial,
            DAE.FUNCTION_BUILTIN(SOME(name), has_unbox_args), DAE.FP_NON_PARALLEL());

      // Parallel function: there are some builtin functions.
      case SCode.FunctionRestriction.FR_PARALLEL_FUNCTION()
        algorithm
          in_params := list(InstNode.name(i) for i in inputs);
          out_params := list(InstNode.name(o) for o in outputs);
          name := SCode.isBuiltinFunction(def, in_params, out_params);
          inline_ty := InstUtil.commentIsInlineFunc(cmt);
          has_unbox_args := hasUnboxArgsAnnotation(cmt);
        then
          DAE.FUNCTION_ATTRIBUTES(inline_ty, hasOMPure(cmt), false, is_partial,
            DAE.FUNCTION_BUILTIN(SOME(name), has_unbox_args), DAE.FP_PARALLEL_FUNCTION());

      // Parallel function: non-builtin.
      case SCode.FunctionRestriction.FR_PARALLEL_FUNCTION()
        algorithm
          inline_ty := InstUtil.commentIsInlineFunc(cmt);
        then
          DAE.FUNCTION_ATTRIBUTES(inline_ty, hasOMPure(cmt), false, is_partial,
            getBuiltin(def), DAE.FP_PARALLEL_FUNCTION());

      // Kernel functions: never builtin and never inlined.
      case SCode.FunctionRestriction.FR_KERNEL_FUNCTION()
        then DAE.FUNCTION_ATTRIBUTES(DAE.NO_INLINE(), true, false, is_partial,
          DAE.FUNCTION_NOT_BUILTIN(), DAE.FP_KERNEL_FUNCTION());

      // Normal function.
      else
        algorithm
          inline_ty := InstUtil.commentIsInlineFunc(cmt);

          // In Modelica 3.2 and before, external functions with side-effects are not marked.
          is_impure := SCode.isRestrictionImpure(res,
              Config.languageStandardAtLeast(Config.LanguageStandard.'3.3') or
              not listEmpty(outputs)) or
            SCode.commentHasBooleanNamedAnnotation(cmt, "__ModelicaAssociation_Impure");
        then
          DAE.FUNCTION_ATTRIBUTES(inline_ty, hasOMPure(cmt), is_impure, is_partial,
            getBuiltin(def), DAE.FP_NON_PARALLEL());

    end matchcontinue;
  end makeAttributes;

  function checkParamTypes
    "Checks that all the function parameters have types which are allowed in a
     function."
    input Function fn;
  algorithm
    checkParamTypes2(fn.inputs);
    checkParamTypes2(fn.outputs);
    checkParamTypes2(fn.locals);
  end checkParamTypes;

  function checkParamTypes2
    input list<InstNode> params;
  protected
    Type ty;
  algorithm
    for p in params loop
      ty := InstNode.getType(p);

      if not isValidParamType(ty) then
        Error.addSourceMessage(Error.INVALID_FUNCTION_VAR_TYPE,
          {Type.toString(ty), InstNode.name(p)}, InstNode.info(p));
        fail();
      end if;
    end for;
  end checkParamTypes2;

  function isValidParamType
    input Type ty;
    output Boolean isValid;
  algorithm
    isValid := match ty
      case Type.INTEGER() then true;
      case Type.REAL() then true;
      case Type.STRING() then true;
      case Type.BOOLEAN() then true;
      case Type.CLOCK() then true;
      case Type.ENUMERATION() then true;
      case Type.ENUMERATION_ANY() then true;
      case Type.POLYMORPHIC() then true;
      case Type.ARRAY() then isValidParamType(ty.elementType);
      case Type.COMPLEX() then isValidParamState(ty.cls);
      case Type.FUNCTION() then true;
      case Type.METABOXED() then isValidParamType(ty.ty);
      else false;
    end match;
  end isValidParamType;

  function isValidParamState
    input InstNode cls;
    output Boolean isValid;
  algorithm
    isValid := match Class.restriction(InstNode.getClass(cls))
      case Restriction.RECORD() then true;
      case Restriction.TYPE() then true;
      case Restriction.OPERATOR() then true;
      case Restriction.FUNCTION() then true;
      case Restriction.EXTERNAL_OBJECT() then true;
      else false;
    end match;
  end isValidParamState;

  public function makeReturnType
    input Function fn;
    output Type returnType;
  protected
    list<Type> ret_tyl;
  algorithm
    ret_tyl := list(InstNode.getType(o) for o in fn.outputs);

    returnType := match ret_tyl
      case {} then Type.NORETCALL();
      case {returnType} then returnType;
      else Type.TUPLE(ret_tyl, NONE());
    end match;
  end makeReturnType;

  function getBody2
    input InstNode node;
    output list<Statement> body;
  protected
    Class cls = InstNode.getClass(node);
    Algorithm fn_body;
  algorithm
    body := match cls
      case Class.INSTANCED_CLASS(sections = Sections.SECTIONS(algorithms = {fn_body})) then fn_body.statements;
      case Class.INSTANCED_CLASS(sections = Sections.EMPTY()) then {};

      case Class.INSTANCED_CLASS(sections = Sections.SECTIONS(algorithms = _ :: _))
        algorithm
          Error.assertion(false, getInstanceName() + " got function with multiple algorithm sections", sourceInfo());
        then
          fail();

      case Class.TYPED_DERIVED() then getBody2(cls.baseClass);

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown function", sourceInfo());
        then
          fail();

    end match;
  end getBody2;
end Function;

annotation(__OpenModelica_Interface="frontend");
end NFFunction;
