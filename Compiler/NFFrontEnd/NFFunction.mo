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
import NFExpression.Expression;
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
end Slot;

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
  end FUNCTION;

  function new
    input Absyn.Path path;
    input InstNode node;
    output Function func;
  protected
    Class cls;
    list<InstNode> inputs, outputs, locals;
    list<Slot> slots;
    DAE.FunctionAttributes attr;
  algorithm
    (inputs, outputs, locals) := collectVars(node);
    slots := makeSlots(inputs);
    attr := makeAttributes(node, inputs, outputs);
    func := FUNCTION(path, node, inputs, outputs, locals, slots, Type.UNKNOWN(), attr);
  end new;

  function path
    input Function func;
    output Absyn.Path path = func.path;
  end path;

  function matchArgs
    "Matches the given arguments to the slots in a function, and returns the
     arguments sorted in the order of the function parameters."
    input list<Expression> posArgs;
    input list<tuple<String, Expression>> namedArgs;
    input Function func;
    input Option<SourceInfo> info;
    output list<Expression> args = posArgs;
    output Boolean matching;
  protected
    list<Slot> slots;
    list<Expression> named_args;
  algorithm
    slots := func.slots;

    // Make sure we have enough slots for at least the positional arguments.
    if listLength(posArgs) > listLength(slots) then
      if isSome(info) then
        Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND,
          {Absyn.pathString(func.path), "", signatureString(func)}, Util.getOption(info));
      end if;

      matching := false;
      return;
    end if;

    // Remove as many slots as there are positional arguments. We don't actually
    // need to fill the slots, the positional arguments will always be first
    // anyway. This makes it a bit slower to figure out what error to give if a
    // named argument is wrong, but faster for the most common case of
    // everything being correct.
    for arg in posArgs loop
      slots := listRest(slots);
    end for;

    // Fill the remaining slots with the named arguments.
    (named_args, matching) := fillNamedSlots(namedArgs, slots, func, info);

    // Append the now ordered named arguments to the positional arguments.
    if matching then
      args := listAppend(posArgs, named_args);
    end if;
  end matchArgs;

  function isTyped
    input Function func;
    output Boolean isTyped;
  algorithm
    isTyped := match func.returnType
      case Type.UNKNOWN() then false;
      else true;
    end match;
  end isTyped;

  function typeFunction
    input output Function func;
  protected
    DAE.FunctionAttributes attr;
  algorithm
    if not isTyped(func) then
      Typing.typeClass(func.node);
      func.returnType := makeReturnType(func);
    end if;
  end typeFunction;

  function isBuiltin
    input Function func;
    output Boolean isBuiltin;
  algorithm
    isBuiltin := match func.attributes.isBuiltin
      case DAE.FunctionBuiltin.FUNCTION_NOT_BUILTIN() then false;
      else true;
    end match;
  end isBuiltin;

  function isImpure
    input Function func;
    output Boolean isImpure = func.attributes.isImpure;
  end isImpure;

  function isFunctionPointer
    input Function func;
    output Boolean isPointer = func.attributes.isFunctionPointer;
  end isFunctionPointer;

  function inlineBuiltin
    input Function func;
    output DAE.InlineType inlineType;
  algorithm
    inlineType := match func.attributes.isBuiltin
      case DAE.FunctionBuiltin.FUNCTION_BUILTIN_PTR()
        then DAE.BUILTIN_EARLY_INLINE();
      else func.attributes.inline;
    end match;
  end inlineBuiltin;

protected
  function collectVars
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
              (inputs, outputs, locals) := collectVars(n, inputs, outputs, locals);
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
  end collectVars;

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
    output list<Slot> slots;
  algorithm
    slots := list(makeSlot(c) for c in inputs);
  end makeSlots;

  function makeSlot
    input InstNode component;
    output Slot slot;
  protected
    Component comp;
    Option<Expression> default;
    String name;
  algorithm
    try
      comp := InstNode.component(component);
      default := Binding.untypedExp(Component.getBinding(comp));
      name := InstNode.name(component);

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
    input Function func;
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
      (slots_arr, matching) := fillNamedSlot(name, arg, slots_arr, func, info);

      if not matching then
        return;
      end if;
    end for;

    (args, matching) := collectArgs(slots_arr, info);
  end fillNamedSlots;

  function fillNamedSlot
    input String argName;
    input Expression argExp;
    input output array<Slot> slots;
    input Function func;
    input Option<SourceInfo> info;
          output Boolean matching = true;
  protected
    Slot s;
  algorithm
    // Try to find a slot and fill it with the argument expression.
    for i in 1:arrayLength(slots) loop
      s := slots[i];

      if s.name == argName then
        if isNone(s.arg) then
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
      for s in func.slots loop
        if argName == s.name then
          // We found a slot, so it must have already been filled.
          Error.addSourceMessage(Error.FUNCTION_SLOT_ALREADY_FILLED,
            {argName, ""}, Util.getOption(info));
          return;
        end if;
      end for;

      // No slot could be found, so it doesn't exist.
      Error.addSourceMessage(Error.NO_SUCH_PARAMETER,
        {InstNode.name(func.node), argName}, Util.getOption(info));
    end if;
  end fillNamedSlot;

  function collectArgs
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
        case (SOME(e), _) then e :: args; // Otherwise, use the default value for the parameter.
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

  function makeReturnType
    input Function func;
    output Type funcType;
  protected
    array<InstNode> params;
    list<Component> in_params, out_params;
    Type ret_ty;
    list<Type> ret_tyl;
    Component c;
  algorithm
    Class.INSTANCED_CLASS(components = params) := InstNode.getClass(func.node);
    //in_params := list(InstNode.component(i) for i in func.inputs);
    //out_params := list(InstNode.component(o) for o in func.outputs);

    ret_tyl := list(InstNode.getType(o) for o in func.outputs);

    ret_ty := match ret_tyl
      case {} then Type.NORETCALL();
      case {ret_ty} then ret_ty;
      else Type.TUPLE(ret_tyl, NONE());
    end match;

    funcType := Type.FUNCTION(ret_ty, func.attributes);
  end makeReturnType;

  function signatureString
    input Function func;
    output String str;
  protected
    String arg_str;
  algorithm
    // TODO: Print parameter types and return type too.
    arg_str := stringDelimitList(list(InstNode.name(i) for i in func.inputs), ", ");
    str := InstNode.name(func.node) + "(" + arg_str + ")";
  end signatureString;
end Function;

annotation(__OpenModelica_Interface="frontend");
end NFFunction;
