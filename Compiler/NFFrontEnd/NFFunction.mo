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
import NFInstNode.InstNode;
import Type = NFType;

protected
import Inst = NFInst;
import Binding = NFBinding;
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

import MatchKind = NFTypeCheck.MatchKind;

public
type NamedArg = tuple<String, Expression>;
type TypedArg = tuple<Expression, Type, DAE.Const>;
type TypedNamedArg = tuple<String, Expression, Type, DAE.Const>;

public
type SlotType = enumeration(
  POSITIONAL "Only accepts positional arguments.",
  NAMED      "Only accepts named argument.",
  GENERIC    "Accepts both positional and named arguments."
) "Determines which type of argument a slot accepts.";

uniontype Slot
  record SLOT
    String name;
    SlotType ty;
    Option<Expression> default;
    Option<TypedArg> arg;
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
end Slot;

public
encapsulated
uniontype FunctionMatchKind
  import NFFunction.Function;
  import NFFunction.TypedArg;

  type MatchedFunction = tuple<Function,list<TypedArg>,FunctionMatchKind>;

  record EXACT "Exact match." end EXACT;

  record CAST "Matched by casting one or more arguments. e.g. Integer to Real" end CAST;

  record GENERIC "Matched with a generic type on one or more arguments e.g. function F<T> input T i; end F; F(1)"
  end GENERIC;

  record VECTORIZED "Matched by vectorization"
  end VECTORIZED;

  record NOT_COMPATIBLE end NOT_COMPATIBLE;

  function getExactMatches
    input list<MatchedFunction> matchedFunctions;
    output list<MatchedFunction> outFuncs = {};
  algorithm
    for mf in matchedFunctions loop
      if isExactMatch(mf) then
        outFuncs := mf::outFuncs;
      end if;
    end for;
    listReverse(outFuncs);
  end getExactMatches;

  function isExactMatch
    input MatchedFunction mf;
    output Boolean b;
  algorithm
    b := match mf
      case (_,_,EXACT_MATCH) then true;
      else false;
    end match;
  end isExactMatch;

end FunctionMatchKind;

constant FunctionMatchKind EXACT_MATCH = FunctionMatchKind.EXACT();
constant FunctionMatchKind CAST_MATCH = FunctionMatchKind.CAST();
constant FunctionMatchKind NO_MATCH = FunctionMatchKind.NOT_COMPATIBLE();


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
    Util.StatefulBoolean collected "Whether this function has already been added to the function tree or not.";
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
    array<Boolean> collected;
  algorithm
    (inputs, outputs, locals) := collectParams(node);
    // Slots should be created after typing
    // slots := makeSlots(inputs);
    attr := makeAttributes(node, inputs, outputs);
    collected := Util.makeStatefulBoolean(false);
    fn := FUNCTION(path, node, inputs, outputs, locals, {}, Type.UNKNOWN(), attr, collected);

    // Make sure builtin functions aren't added to the function tree.
    if isBuiltin(fn) then
      collect(fn);
    end if;
  end new;

  protected
  function lookupFunction
    input Absyn.ComponentRef functionName;
    input InstNode scope;
    input SourceInfo info;
    output InstNode node;
    output ComponentRef functionRef;
    output Absyn.Path functionPath;
  protected
    list<InstNode> nodes;
    InstNode found_scope;
  algorithm
    try
      // Make sure the name is a path.
      functionPath := Absyn.crefToPath(functionName);
    else
      Error.addSourceMessageAndFail(Error.SUBSCRIPTED_FUNCTION_CALL,
        {Dump.printComponentRefStr(functionName)}, info);
    end try;

    // Look up the function and create a cref for it.
    (node, nodes, found_scope) := Lookup.lookupFunctionName(functionName, scope, info);

    for s in InstNode.scopeList(found_scope) loop
      functionPath := Absyn.QUALIFIED(InstNode.name(s), functionPath);
    end for;

    functionRef := ComponentRef.fromNodeList(InstNode.scopeList(found_scope));
    functionRef := Inst.makeCref(functionName, nodes, scope, info, functionRef);
  end lookupFunction;

  public
  function instFunc
    input Absyn.ComponentRef functionName;
    input InstNode scope;
    input SourceInfo info;
    output ComponentRef fn_ref;
    output InstNode fn_node;
  protected
    CachedData cache;
    Absyn.Path fn_path;
  algorithm
    // Look up the the function.
    (fn_node, fn_ref, fn_path) := lookupFunction(functionName, scope, info);
    cache := InstNode.cachedData(fn_node);

    // Check if a cached instantiation of this function already exists.
    fn_node := match cache
      case CachedData.FUNCTION() then fn_node;
      else instFunc2(fn_path,fn_node, info);
    end match;
  end instFunc;

  protected
  function instFunc2
    input Absyn.Path fnPath;
    input output InstNode fnNode;
    input SourceInfo info;
  algorithm

    fnNode := match InstNode.definition(fnNode)
      local
        SCode.ClassDef cdef;
        Function fn;
        Absyn.ComponentRef cr;
        InstNode sub_fnNode;

      case SCode.CLASS(classDef = cdef as SCode.PARTS())
        algorithm
          fnNode := InstNode.setNodeType(NFInstNode.InstNodeType.ROOT_CLASS(), fnNode);
          fnNode := Inst.instantiate(fnNode);
          Inst.instExpressions(fnNode);
          fn := Function.new(fnPath, fnNode);
          fnNode := InstNode.cacheAddFunc(fn, fnNode);
        then fnNode;

      case SCode.CLASS(classDef = cdef as SCode.OVERLOAD())
        algorithm
          for p in cdef.pathLst loop
            cr := Absyn.pathToCref(p);
            (_,sub_fnNode) := instFunc(cr,fnNode /*This should be the scope right?*/,info);
            for f in getCachedFuncs(sub_fnNode) loop
              fnNode := InstNode.cacheAddFunc(f, fnNode);
            end for;
          end for;
        then fnNode;
    end match;
  end instFunc2;

  public
  function getCachedFuncs
    input InstNode inNode;
    output list<Function> outFuncs;
  protected
    CachedData cache;
  algorithm
    cache := InstNode.cachedData(inNode);
    outFuncs := match cache
      case CachedData.FUNCTION() then cache.funcs;
      else fail();
    end match;
  end getCachedFuncs;

  function isCollected
    "Returns true if this function has already been added to the function tree
     (or shouldn't be added, e.g. if it's builtin), otherwise false."
    input Function fn;
    output Boolean collected = Util.getStatefulBoolean(fn.collected);
  end isCollected;

  function collect
    "Marks this function as collected for addition to the function tree."
    input Function fn;
  algorithm
    Util.setStatefulBoolean(fn.collected, true);
  end collect;

  function name
    input Function fn;
    output Absyn.Path path = fn.path;
  end name;

  function signatureString
    "Constructs a signature string for a function, e.g. Real func(Real x, Real y)"
    input Function fn;
    input Boolean printTypes = true;
    input Option<Absyn.Path> display_name;
    output String str;
  protected
    Absyn.Path fn_name;
    String input_str, output_str;
    list<String> inputs_strl = {};
    list<InstNode> inputs = fn.inputs;
    Component c;
    Expression def_exp;
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
        input_str := Type.toString(Component.getType(c)) + " " + input_str;
      end if;

      inputs_strl := input_str :: inputs_strl;
    end for;

    input_str := stringDelimitList(listReverse(inputs_strl), ", ");
    output_str := if printTypes and isTyped(fn) then " => " + Type.toString(fn.returnType) else "";
    fn_name := if isSome(display_name) then Util.getOption(display_name) else fn.path;
    str := Absyn.pathString(fn_name) + "(" + input_str + ")" + output_str;
  end signatureString;

  function callString
    "Constructs a string representing a call, for use in error messages."
    input Function fn;
    input list<Expression> posArgs;
    input list<tuple<String, Expression>> namedArgs;
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

  function instance
    input Function fn;
    output InstNode node = fn.node;
  end instance;

  function returnType
    input Function fn;
    output Type ty = fn.returnType;
  end returnType;

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
    input Option<SourceInfo> info;
    output list<TypedArg> args = posArgs;
    output Boolean matching;
  protected
    Slot slot;
    list<Slot> slots;
    list<TypedArg> filled_named_args;
  algorithm
    slots := fn.slots;

    if listLength(posArgs) > listLength(slots) then
      matching := false;
      return;
    end if;
    // Remove as many slots as there are positional arguments. We don't actually
    // need to fill the slots, the positional arguments will always be first
    // anyway. This makes it a bit slower to figure out what error to give if a
    // named argument is wrong, but faster for the most common case of
    // everything being correct.
    for arg in args loop
      slot :: slots := slots;

      if not Slot.positional(slot) then
        // Slot doesn't allow positional arguments (used for some builtin functions).
        matching := false;
        return;
      end if;
    end for;

    // Fill the remaining slots with the named arguments.
    (filled_named_args, matching) := fillNamedArgs(namedArgs, slots, fn, info);

    // Append the now ordered named arguments to the positional arguments.
    if matching then
      args := listAppend(posArgs, filled_named_args);
    end if;
  end fillArgs;

  function fillNamedArgs
    "Sorts a list of named arguments based on the given slots, and returns the
     arguments for the slots if the arguments are correct. If the arguments
     are not correct the list of expressions returned is undefined, along with
     the matching output being false."
    input list<TypedNamedArg> namedArgs;
    input list<Slot> slots;
    input Function fn;
    input Option<SourceInfo> info;
    output list<TypedArg> args = {};
    output Boolean matching = true;
  protected
    array<Slot> slots_arr = listArray(slots);
    String name;
    Expression arg;
  algorithm
    for narg in namedArgs loop
      (slots_arr, matching) := fillNamedArg(narg, slots_arr, fn, info);

      if not matching then
        return;
      end if;
    end for;

    (args, matching) := collectArgsNew(slots_arr, info);
  end fillNamedArgs;

  function fillNamedArg
    "Looks up a slot with the given name and tries to fill it with the given
     argument expression."
    input TypedNamedArg inArg;
    input output array<Slot> slots;
    input Function fn "For error reporting";
    input Option<SourceInfo> info;
          output Boolean matching = true;
  protected
    Slot s;
    String argName;
    Type ty;
    Expression argExp;
    DAE.Const var;
  algorithm
    // Try to find a slot and fill it with the argument expression.
    for i in 1:arrayLength(slots) loop
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
            {argName, ""}, Util.getOption(info));
          matching := false;
        end if;

        return;
      end if;
    end for;

    // No slot could be found.
    matching := false;

    // Only print error if info is given.
    if isSome(info) then
      // A slot with the given name couldn't be found. This means it doesn't
      // exist, or we removed it when handling positional argument. We need to
      // search through all slots to be sure.
      for s in fn.slots loop
        if argName == s.name then
          // We found a slot, so it must have already been filled.
          Error.addSourceMessage(Error.FUNCTION_SLOT_ALREADY_FILLED,
            {argName, ""}, Util.getOption(info));
          return;
        end if;
      end for;

      // No slot could be found, so it doesn't exist.
      Error.addSourceMessage(Error.NO_SUCH_PARAMETER,
        {InstNode.name(instance(fn)), argName}, Util.getOption(info));
    end if;
  end fillNamedArg;

  function collectArgsNew
    "Collects the arguments from the given slots."
    input array<Slot> slots;
    input Option<SourceInfo> info;
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

      args := match (default, arg)
        case (_, SOME(a)) then a :: args; // Use the argument from the call if one was given.
        // TODO: save this info in the defaults in slots (the type we can get from the exp manually but the variability is lost.).
        case (SOME(e), _) then (e,Expression.typeOf(e),DAE.C_CONST()) ::args; // Otherwise, check that a default value exists.
        else // Give an error if no argument was given and there's no default value.
          algorithm
            if isSome(info) then
              Error.addSourceMessage(Error.UNFILLED_SLOT, {name}, Util.getOption(info));
            end if;

            matching := false;
          then
            args;
      end match;
    end for;

    args := listReverse(args);
  end collectArgsNew;

  function matchArgs
    input Function func;
    input output list<TypedArg> args;
    input Option<SourceInfo> info;
          output Boolean correct;
          output FunctionMatchKind funcMatchKind = EXACT_MATCH;
  protected
    Component comp;
    InstNode inputnode;
    list<InstNode> inputs;
    Expression argexp, margexp;
    Type ty, mty;
    DAE.Const var;
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

      (margexp, mty, matchKind) := TypeCheck.matchTypes(ty, Component.getType(comp), argexp);
      correct := TypeCheck.isCompatibleMatch(matchKind);
      if TypeCheck.isCastMatch(matchKind) then
        funcMatchKind := CAST_MATCH;
      end if;

      // Type mismatch, print an error.
      if not correct then
        if isSome(info) then
          Error.addSourceMessage(Error.ARG_TYPE_MISMATCH, {
            intString(idx), Absyn.pathString(func.path), InstNode.name(inputnode), Expression.toString(argexp),
            Type.toString(ty), Type.toString(Component.getType(comp))
          }, Util.getOption(info));
        end if;

        return;
      end if;

      correct := TypeCheck.checkConstVariability(var, Component.variability(comp));

      // Variability mismatch, print an error.
      if not correct then
        if isSome(info) then
          Error.addSourceMessage(Error.FUNCTION_SLOT_VARIABILITY, {
            InstNode.name(inputnode), Expression.toString(argexp), DAEDump.dumpKindStr(Component.variability(comp))
          }, Util.getOption(info));
          return;
        end if;
      end if;

      checked_args := (margexp,mty,var) :: checked_args;
      idx := idx + 1;
    end for;

    correct := true;
    args := listReverse(checked_args);
  end matchArgs;

  function isTyped
    input Function fn;
    output Boolean isTyped;
  algorithm
    isTyped := match fn.returnType
      case Type.UNKNOWN() then false;
      else true;
    end match;
  end isTyped;

  function typeFunction
    input output Function fn;
  protected
    DAE.FunctionAttributes attr;
  algorithm
    if not isTyped(fn) then
      Typing.typeFunction(fn.node);
      checkParamTypes(fn);
      fn.slots := makeSlots(fn.inputs);
      fn.returnType := makeReturnType(fn);
    end if;
  end typeFunction;

  function isBuiltin
    input Function fn;
    output Boolean isBuiltin;
  algorithm
    isBuiltin := match fn.attributes.isBuiltin
      case DAE.FunctionBuiltin.FUNCTION_NOT_BUILTIN() then false;
      else true;
    end match;
  end isBuiltin;

  function isImpure
    input Function fn;
    output Boolean isImpure = fn.attributes.isImpure;
  end isImpure;

  function isFunctionPointer
    input Function fn;
    output Boolean isPointer = fn.attributes.isFunctionPointer;
  end isFunctionPointer;

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

  function toDAE
    input Function fn;
    input list<DAE.FunctionDefinition> defs;
    output DAE.Function daeFn;
  protected
    SCode.Visibility vis;
    Boolean par, impr;
    DAE.InlineType ity;
  algorithm
    vis := SCode.PUBLIC(); // TODO: Use the actual visibility.
    par := false; // TODO: Use the actual partial prefix.
    impr := fn.attributes.isImpure;
    ity := fn.attributes.inline;
    daeFn := DAE.FUNCTION(fn.path, defs, Type.toDAE(fn.returnType), vis,
      par, impr, ity, DAE.emptyElementSource, NONE());
  end toDAE;

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
    assert(InstNode.isClass(node), getInstanceName() + " got non-class node");
    cls := InstNode.getClass(node);

    () := match cls
      case Class.INSTANCED_CLASS(components = comps)
        algorithm
          for i in arrayLength(comps):-1:1 loop
            n := comps[i];
            if InstNode.isComponent(n) then
              // Sort the components based on their direction.
              () := match paramDirection(n)
                case DAE.VarDirection.INPUT() algorithm inputs := n :: inputs; then ();
                case DAE.VarDirection.OUTPUT() algorithm outputs := n :: outputs; then ();
                case DAE.VarDirection.BIDIR() algorithm locals := n :: locals; then ();
              end match;
            else
              (inputs, outputs, locals) := collectParams(n, inputs, outputs, locals);
            end if;
          end for;
        then
          ();

      else
        algorithm
          assert(false, getInstanceName() + " got non-instantiated function");
        then
          fail();
    end match;
  end collectParams;

  function paramDirection
    input InstNode component;
    output DAE.VarDirection direction;
  protected
    DAE.ConnectorType cty;
    DAE.VarInnerOuter io;
    DAE.VarVisibility vis;
  algorithm
    Component.Attributes.ATTRIBUTES(
      connectorType = cty,
      direction = direction,
      innerOuter = io,
      visibility = vis) := Component.getAttributes(InstNode.component(component));

    // Function components may not be connectors.
    () := match cty
      case DAE.ConnectorType.NON_CONNECTOR() then ();
      else
        algorithm
          // TODO: This error will look weird if we get a connector that's neither
          // flow nor stream. Maybe better to just say "formal parameter may not be
          // connector".
          Error.addSourceMessage(Error.INNER_OUTER_FORMAL_PARAMETER,
            {DAEDump.dumpConnectorType(cty), InstNode.name(component)}, InstNode.info(component));
        then
          fail();
    end match;

    // Function components may not be inner/outer.
    () := match io
      case DAE.VarInnerOuter.NOT_INNER_OUTER() then ();
      else
        algorithm
          Error.addSourceMessage(Error.INNER_OUTER_FORMAL_PARAMETER,
            {DAEDump.unparseVarInnerOuter(io), InstNode.name(component)},
            InstNode.info(component));
        then
          fail();
    end match;

    // Formal parameters must be public, other function variables must be protected.
    () := match (direction, vis)
      case (DAE.VarDirection.INPUT(), DAE.VarVisibility.PUBLIC()) then ();
      case (DAE.VarDirection.OUTPUT(), DAE.VarVisibility.PUBLIC()) then ();
      case (DAE.VarDirection.BIDIR(), DAE.VarVisibility.PROTECTED()) then ();

      case (_, DAE.VarVisibility.PUBLIC())
        algorithm
          Error.addSourceMessage(Error.NON_FORMAL_PUBLIC_FUNCTION_VAR,
            {InstNode.name(component)}, InstNode.info(component));
        then
          fail();

      case (_, DAE.VarVisibility.PROTECTED())
        algorithm
          Error.addSourceMessage(Error.PROTECTED_FORMAL_FUNCTION_VAR,
            {InstNode.name(component)}, InstNode.info(component));
        then
          fail();
    end match;
  end paramDirection;

  function makeSlots
    input list<InstNode> inputs;
    output list<Slot> slots = {};
  protected
    Boolean has_default, default_required = false;
    Slot s;
  algorithm
    for i in inputs loop
      (s, has_default) := makeSlot(i, default_required);
      slots := s :: slots;
      default_required := default_required or has_default;
    end for;

    slots := listReverse(slots);
  end makeSlots;

  function makeSlot
    input InstNode component;
    input Boolean defaultRequired;
    output Slot slot;
    output Boolean hasDefault;
  protected
    Component comp;
    Option<Expression> default;
    String name;
  algorithm
    try
      comp := InstNode.component(component);
      default := Binding.typedExp(Component.getBinding(comp));
      name := InstNode.name(component);
      hasDefault := isSome(default);

      // function F
      //   input Real a = 1;
      //   input Real b;
      // end F;
      // F(b=2);  is a valid call
      /*
      // All parameters with default arguments should be declared last in a
      // function, otherwise it's useless to have default arguments. Modelica
      // does not seem to strictly forbid this, so we just give a warning.
      if defaultRequired and not hasDefault then
        Error.addSourceMessage(Error.MISSING_DEFAULT_ARG,
          {name}, InstNode.info(component));
      end if;
      */

      // Remove $in_ for OM input output arguments.
      if stringGet(name, 1) == 36 /*$*/ then
        if stringLength(name) > 4 and substring(name, 1, 4) == "$in_" then
          name := substring(name, 5, stringLength(name));
        end if;
      end if;

      slot := SLOT(InstNode.name(component), SlotType.GENERIC, default, NONE());
    else
      assert(false, getInstanceName() + " got invalid component");
    end try;
  end makeSlot;

  function hasOMPure
    input SCode.Element def;
    output Boolean res =
      not SCode.hasBooleanNamedAnnotationInClass(def, "__OpenModelica_Impure");
  end hasOMPure;

  function hasImpure
    input SCode.Element def;
    output Boolean res =
      SCode.hasBooleanNamedAnnotationInClass(def, "__ModelicaAssociation_Impure");
  end hasImpure;

  function hasUnboxArgs
    input SCode.Element def;
    output Boolean res =
      SCode.hasBooleanNamedAnnotationInClass(def, "__OpenModelica_UnboxArguments");
  end hasUnboxArgs;

  function getBuiltin
    input SCode.Element def;
    output DAE.FunctionBuiltin builtin =
     if SCode.hasBooleanNamedAnnotationInClass(def, "__OpenModelica_BuiltinPtr") then
       DAE.FUNCTION_BUILTIN_PTR() else DAE.FUNCTION_NOT_BUILTIN();
  end getBuiltin;

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
  algorithm
    def := InstNode.definition(node);
    res := SCode.getClassRestriction(def);

    assert(SCode.isFunctionRestriction(res),
      getInstanceName() + " got non-function restriction");

    SCode.Restriction.R_FUNCTION(functionRestriction = fres) := res;

    attr := matchcontinue fres
      local
        Boolean is_impure, is_om_pure, has_out_params;
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
          inline_ty := InstUtil.isInlineFunc(def);
          is_impure := is_impure or hasImpure(def);
        then
          DAE.FUNCTION_ATTRIBUTES(inline_ty, hasOMPure(def), is_impure, false,
            DAE.FUNCTION_BUILTIN(SOME(name), hasUnboxArgs(def)), DAE.FP_NON_PARALLEL());

      // Parallel function: there are some builtin functions.
      case SCode.FunctionRestriction.FR_PARALLEL_FUNCTION()
        algorithm
          in_params := list(InstNode.name(i) for i in inputs);
          out_params := list(InstNode.name(o) for o in outputs);
          name := SCode.isBuiltinFunction(def, in_params, out_params);
          inline_ty := InstUtil.isInlineFunc(def);
        then
          DAE.FUNCTION_ATTRIBUTES(inline_ty, hasOMPure(def), false, false,
            DAE.FUNCTION_BUILTIN(SOME(name), hasUnboxArgs(def)), DAE.FP_PARALLEL_FUNCTION());

      // Parallel function: non-builtin.
      case SCode.FunctionRestriction.FR_PARALLEL_FUNCTION()
        algorithm
          inline_ty := InstUtil.isInlineFunc(def);
        then
          DAE.FUNCTION_ATTRIBUTES(inline_ty, hasOMPure(def), false, false,
            getBuiltin(def), DAE.FP_PARALLEL_FUNCTION());

      // Kernel functions: never builtin and never inlined.
      case SCode.FunctionRestriction.FR_KERNEL_FUNCTION()
        then DAE.FUNCTION_ATTRIBUTES(DAE.NO_INLINE(), true, false, false,
          DAE.FUNCTION_NOT_BUILTIN(), DAE.FP_KERNEL_FUNCTION());

      // Normal function.
      else
        algorithm
          inline_ty := InstUtil.isInlineFunc(def);

          // In Modelica 3.2 and before, external functions with side-effects are not marked.
          is_impure := SCode.isRestrictionImpure(res,
              Config.languageStandardAtLeast(Config.LanguageStandard.'3.3') or
              not listEmpty(outputs)) or
            SCode.hasBooleanNamedAnnotationInClass(def, "__ModelicaAssociation_Impure");
        then
          DAE.FUNCTION_ATTRIBUTES(inline_ty, hasOMPure(def), is_impure, false,
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
      case Type.ARRAY() then isValidParamType(ty.elementType);
      case Type.COMPLEX() then isValidParamState(ty.cls);
    end match;
  end isValidParamType;

  function isValidParamState
    input InstNode cls;
    output Boolean isValid;
  protected
    SCode.Restriction res;
  algorithm
    // TODO: Use derived restriction instead, since classes can inherit restrictions.
    res := SCode.getClassRestriction(InstNode.definition(cls));

    isValid := match res
      case SCode.Restriction.R_RECORD() then true;
      case SCode.Restriction.R_TYPE() then true;
      case SCode.Restriction.R_OPERATOR() then true;
      case SCode.Restriction.R_FUNCTION() then true;
      else false;
    end match;
  end isValidParamState;

  function makeReturnType
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
end Function;

annotation(__OpenModelica_Interface="frontend");
end NFFunction;
