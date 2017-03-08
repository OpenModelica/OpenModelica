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
    Option<Expression> arg;
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

type FuncType = enumeration(
  NORMAL,
  SPECIAL_MATCHING,
  SPECIAL_TYPING
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
    slots := makeSlots(inputs);
    attr := makeAttributes(node, inputs, outputs);
    collected := Util.makeStatefulBoolean(false);
    fn := FUNCTION(path, node, inputs, outputs, locals, slots, Type.UNKNOWN(), attr, collected);

    // Make sure builtin functions aren't added to the function tree.
    if isBuiltin(fn) then
      collect(fn);
    end if;
  end new;

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
    output String str;
  protected
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
    str := Absyn.pathString(fn.path) + "(" + input_str + ")" + output_str;
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

  function matchArgs
    "Matches the given arguments to the slots in a function, and returns the
     arguments sorted in the order of the function parameters."
    input list<Expression> posArgs;
    input list<tuple<String, Expression>> namedArgs;
    input Function fn;
    input Option<SourceInfo> info;
    output list<Expression> args = posArgs;
    output Boolean matching;
  protected
    Slot slot;
    list<Slot> slots;
    list<Expression> named_args;
  algorithm
    slots := fn.slots;

    // Make sure we have enough slots for at least the positional arguments.
    if listLength(posArgs) > listLength(slots) then
      if isSome(info) then
        // TODO: Remove "in component" from error message.
        Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND,
          {callString(fn, posArgs, namedArgs), "<REMOVE ME>",
           ":\n  " + signatureString(fn)}, Util.getOption(info));
      end if;

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
    (named_args, matching) := fillNamedSlots(namedArgs, slots, fn, info);

    // Append the now ordered named arguments to the positional arguments.
    if matching then
      args := listAppend(posArgs, named_args);
    end if;
  end matchArgs;

  function typeCheckArgs
    "Checks that the given arguments is type compatible with the function input
     parameters. Also adds default arguments from the function to the list of
     arguments if needed."
    input Function fn;
    input output list<Expression> args;
    input list<Type> types;
    input list<DAE.Const> variabilities;
    input Option<SourceInfo> info;
          output Boolean correct;
  protected
    InstNode i;
    list<InstNode> rest_i = fn.inputs;
    Component c;
    Type ty;
    list<Type> rest_ty = types;
    DAE.Const var;
    list<DAE.Const> rest_vars = variabilities;
    list<Expression> checked_args = {};
    list<Slot> rest_slots = fn.slots;
    Slot slot;
    Integer idx;
  algorithm
    // This should be caught during argument matching.
    assert(listLength(args) <= listLength(fn.inputs),
      getInstanceName() + " got too many arguments");

    for arg in args loop
      i :: rest_i := rest_i;
      ty :: rest_ty := rest_ty;
      var :: rest_vars := rest_vars;
      slot :: rest_slots := rest_slots;
      c := InstNode.component(i);

      (arg, _, correct) := TypeCheck.matchTypes(ty, Component.getType(c), arg);

      // Type mismatch, print an error.
      if not correct then
        if isSome(info) then
          idx := listLength(fn.slots) - listLength(rest_slots);
          Error.addSourceMessage(Error.ARG_TYPE_MISMATCH, {
            intString(idx), Absyn.pathString(fn.path), slot.name, Expression.toString(arg),
            Type.toString(ty), Type.toString(Component.getType(c))
          }, Util.getOption(info));
        end if;

        return;
      end if;

      correct := TypeCheck.checkConstVariability(var, Component.variability(c));

      // Variability mismatch, print an error.
      if not correct then
        if isSome(info) then
          idx := listLength(fn.slots) - listLength(rest_slots);
          Error.addSourceMessage(Error.FUNCTION_SLOT_VARIABILITY, {
            slot.name, Expression.toString(arg), DAEDump.dumpKindStr(Component.variability(c))
          }, Util.getOption(info));
          return;
        end if;
      end if;

      checked_args := arg :: checked_args;
    end for;

    // If we still have slots left, add their default arguments to the list of
    // arguments.
    for s in rest_slots loop
      // Should be caught by the instantiation.
      assert(isSome(s.default), getInstanceName() + " found slot without default value");
      checked_args := Util.getOption(s.default) :: checked_args;
    end for;

    correct := true;
    args := listReverse(checked_args);
  end typeCheckArgs;

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
      Typing.typeClass(fn.node);
      checkParamTypes(fn);
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
      default := Binding.untypedExp(Component.getBinding(comp));
      name := InstNode.name(component);
      hasDefault := isSome(default);

      // All parameters with default arguments should be declared last in a
      // function, otherwise it's useless to have default arguments. Modelica
      // does not seem to strictly forbid this, so we just give a warning.
      if defaultRequired and not hasDefault then
        Error.addSourceMessage(Error.MISSING_DEFAULT_ARG,
          {name}, InstNode.info(component));
      end if;

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

  function fillNamedSlots
    "Sorts a list of named arguments based on the given slots, and returns the
     arguments for the slots if the arguments are correct. If the arguments
     are not correct the list of expressions returned is undefined, along with
     the matching output being false."
    input list<tuple<String, Expression>> namedArgs;
    input list<Slot> slots;
    input Function fn;
    input Option<SourceInfo> info;
    output list<Expression> args = {};
    output Boolean matching = true;
  protected
    array<Slot> slots_arr = listArray(slots);
    String name;
    Expression arg;
  algorithm
    for narg in namedArgs loop
      (name, arg) := narg;
      (slots_arr, matching) := fillNamedSlot(name, arg, slots_arr, fn, info);

      if not matching then
        return;
      end if;
    end for;

    (args, matching) := collectArgs(slots_arr, info);
  end fillNamedSlots;

  function fillNamedSlot
    "Looks up a slot with the given name and tries to fill it with the given
     argument expression."
    input String argName;
    input Expression argExp;
    input output array<Slot> slots;
    input Function fn "For error reporting";
    input Option<SourceInfo> info;
          output Boolean matching = true;
  protected
    Slot s;
  algorithm
    // Try to find a slot and fill it with the argument expression.
    for i in 1:arrayLength(slots) loop
      s := slots[i];

      if s.name == argName then
        if not Slot.named(s) then
          // Slot doesn't allow named argument (used for some builtin functions).
          matching := false;
        elseif isNone(s.arg) then
          s.arg := SOME(argExp);
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
  end fillNamedSlot;

  function collectArgs
    "Collects the arguments from the given slots."
    input array<Slot> slots;
    input Option<SourceInfo> info;
    output list<Expression> args = {};
    output Boolean matching = true;
  protected
    Option<Expression> default, arg;
    Expression e;
    String name;
  algorithm
    for s in slots loop
      SLOT(name = name, default = default, arg = arg) := s;

      args := match (default, arg)
        case (_, SOME(e)) then e :: args; // Use the argument from the call if one was given.
        case (SOME(_), _) then args; // Otherwise, check that a default value exists.
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
  end collectArgs;

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
