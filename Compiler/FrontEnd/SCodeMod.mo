/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */


encapsulated package SCodeMod 
" file:        SCodeMod.mo
  package:     SCodeMod
  description: Modification handling for SCodeInst.

  RCS: $Id: SCodeMod.mo 7705 2011-01-17 09:53:52Z sjoelund.se $

  Functions for handling modifications, used by SCodeInst.
  "
  
public import Absyn;
public import SCode;
public import SCodeEnv;
public import InstTypes;

protected import Dump;
protected import Error;
protected import InstDump;
protected import List;
protected import SCodeDump;
protected import SCodeLookup;
protected import Util;

public type Binding = InstTypes.Binding;
public type Env = SCodeEnv.Env;
public type Prefix = InstTypes.Prefix;
public type Modifier = InstTypes.Modifier;

public function translateMod
  input SCode.Mod inMod;
  input String inElementName;
  input Integer inDimensions;
  input Prefix inPrefix;
  input Env inEnv;
  output Modifier outMod;
algorithm
  outMod := match(inMod, inElementName, inDimensions, inPrefix, inEnv)
    local
      SCode.Final fp;
      SCode.Each ep;
      list<SCode.SubMod> submods;
      Option<tuple<Absyn.Exp, Boolean>> binding_exp;
      Absyn.Info info;
      list<Modifier> mods;
      Binding binding;
      SCode.Element el;
      Integer pd;

    case (SCode.NOMOD(), _, _, _, _) then InstTypes.NOMOD();

    case (SCode.MOD(fp, ep, submods, binding_exp, info), _, _, _, _)
      equation
        pd = Util.if_(SCode.eachBool(ep), 0, inDimensions);
        mods = List.map3(submods, translateSubMod, pd, inPrefix, inEnv);
        binding = translateBinding(binding_exp, ep, pd, inPrefix, inEnv, info);
      then
        InstTypes.MODIFIER(inElementName, fp, ep, binding, mods, info);

    case (SCode.REDECL(fp, ep, el), _, _, _, _)
      then InstTypes.REDECLARE(fp, ep, el);

  end match;
end translateMod;

protected function translateSubMod
  input SCode.SubMod inSubMod;
  input Integer inDimensions;
  input Prefix inPrefix;
  input Env inEnv;
  output Modifier outMod;
protected
  String name;
  SCode.Mod mod;
algorithm
  SCode.NAMEMOD(name, mod) := inSubMod;
  outMod := translateMod(mod, name, inDimensions, inPrefix, inEnv);
end translateSubMod;

protected function translateBinding
  input Option<tuple<Absyn.Exp, Boolean>> inBinding;
  input SCode.Each inEachPrefix;
  input Integer inDimensions;
  input Prefix inPrefix;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Binding outBinding;
algorithm
  outBinding := match(inBinding, inEachPrefix, inDimensions, inPrefix, inEnv, inInfo)
    local
      Absyn.Exp bind_exp;
      Integer pd;

    case (NONE(), _, _, _, _, _) then InstTypes.UNBOUND();

    // See propagateMod for how this works.
    case (SOME((bind_exp, _)), _, _, _, _, _)
      equation
        pd = Util.if_(SCode.eachBool(inEachPrefix), -1, inDimensions);
      then 
        InstTypes.RAW_BINDING(bind_exp, inEnv, inPrefix, pd, inInfo);

  end match;
end translateBinding;

public function applyModifications
  "Applies a class modifier to the class' elements."
  input Modifier inMod;
  input list<SCode.Element> inElements;
  input Prefix inPrefix;
  input Env inEnv;
  output list<tuple<SCode.Element, Modifier>> outElements;
protected
  list<tuple<String, Modifier>> mods;
  list<tuple<String, Option<list<Absyn.Path>>, Modifier>> upd_mods;
  list<tuple<SCode.Element, Modifier>> el;
algorithm
  /***************************************************************************/
  // TODO: This is pretty inefficient, particularly applyModifications2, and
  // should be reimplemented using a hashtable or something.
  /***************************************************************************/
  mods := splitMod(inMod, inPrefix);
  upd_mods := List.map2(mods, updateModElement, inEnv, inPrefix);
  el := List.map(inElements, addNoMod);
  outElements := List.fold(upd_mods, applyModifications2, el);
end applyModifications;

protected function addNoMod
  input SCode.Element inElement;
  output tuple<SCode.Element, Modifier> outElement;
algorithm
  outElement := (inElement, InstTypes.NOMOD());
end addNoMod;

protected function updateModElement
  "Given a tuple of an element name and a modifier, checks if the element 
   is in the local scope, or if it comes from an extends clause. If it comes
   from an extends, return a new tuple that also contains the paths of the
   extends, otherwise the option will be NONE."
  input tuple<String, Modifier> inMod;
  input Env inEnv;
  input Prefix inPrefix;
  output tuple<String, Option<list<Absyn.Path>>, Modifier> outMod;
protected
  String name;
  Modifier mod;
  SCodeEnv.Item item;
  Option<list<Absyn.Path>> bcl;
algorithm
  (name, mod) := inMod;
  (item, bcl) := lookupMod(name, inEnv, inPrefix, mod);
  checkClassModifier(item, inMod, inPrefix);
  outMod := (name, bcl, mod);
end updateModElement;

protected function lookupMod
  input String inName;
  input Env inEnv;
  input Prefix inPrefix;
  input Modifier inMod;
  output SCodeEnv.Item outItem;
  output Option<list<Absyn.Path>> outBaseClasses;
algorithm
  (outItem, outBaseClasses) := matchcontinue(inName, inEnv, inPrefix, inMod)
    local
      SCodeEnv.Item item;
      list<Absyn.Path> bcl;
      Absyn.Info info;
      String pre_str;

    // Check if the modified element can be found in the local scope.
    case (_, _, _, _)
      equation
        (item, _) = SCodeLookup.lookupInClass(inName, inEnv);
      then
        (item, NONE());

    // Check if the modified element can be found in one of the extended classes.
    case (_, _, _, _)
      equation
        (item :: _, bcl) = SCodeLookup.lookupInheritedNameAndBC(inName, inEnv);
      then
        (item, SOME(bcl));

    // The modified element couldn't be found, show an error.
    else
      equation
        pre_str = InstDump.prefixStr(inPrefix);
        info = getModifierInfo(inMod);
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {inName, pre_str}, info);
      then
        fail();

  end matchcontinue;
end lookupMod;

protected function checkClassModifier
  "This function checks that a modifier isn't trying to replace a class, i.e.
   c(A = B), where A and B are classes. This should only be allowed if the
   modification is an actual redeclaration."
  input SCodeEnv.Item inItem;
  input tuple<String, Modifier> inMod;
  input Prefix inPrefix;
algorithm
  _ := match(inItem, inMod, inPrefix)
    local
      String name, pre_str;
      Modifier mod;
      Absyn.Info info;

    // The modified element is a class but the modifier has no binding, e.g.
    // c(A(x = 3)). This is ok.
    case (SCodeEnv.CLASS(cls = _), 
        (_, InstTypes.MODIFIER(binding = InstTypes.UNBOUND())), _)
      then ();

    // The modified element is a class but the modifier has a binding. This is
    // not ok, tell the user that the redeclare keyword is missing.
    case (SCodeEnv.CLASS(cls = _), (name, mod), _)
      equation
        info = getModifierInfo(mod);
        pre_str = InstDump.prefixStr(inPrefix);
        Error.addSourceMessage(Error.MISSING_REDECLARE_IN_CLASS_MOD,
          {name, pre_str}, info);
      then
        fail();

    else ();

  end match;
end checkClassModifier;

protected function getModifierInfo
  input Modifier inMod;
  output Absyn.Info outInfo;
algorithm
  outInfo := match(inMod)
    local
      Absyn.Info info;

    case InstTypes.MODIFIER(info = info) then info;
    else Absyn.dummyInfo;

  end match;
end getModifierInfo;

protected function applyModifications2
  input tuple<String, Option<list<Absyn.Path>>, Modifier> inMod;
  input list<tuple<SCode.Element, Modifier>> inElements;
  output list<tuple<SCode.Element, Modifier>> outElements;
algorithm
  outElements := matchcontinue(inMod, inElements)
    local
      String name, id;
      Absyn.Path path, bc_path;
      Modifier outer_mod, sub_mod, inner_mod;
      SCode.Element el;
      list<tuple<SCode.Element, Modifier>> rest_el;
      tuple<SCode.Element, Modifier> e;
      list<Absyn.Path> bcl;

    // No more elements, this should actually be an error!
    case (_, {}) then {};

    // The optional path is NONE, we are looking for an element.
    case ((id, NONE(), outer_mod),
        (el as SCode.COMPONENT(name = name), inner_mod) :: rest_el)
      equation
        true = stringEq(id, name);
        // Element name matches, merge the modifiers.
        inner_mod = mergeMod(outer_mod, inner_mod);
      then
        (el, inner_mod) :: rest_el;

    // The optional path is SOME, we are looking for an extends.
    case ((id, SOME(bcl as _ :: _), sub_mod),
        (el as SCode.EXTENDS(baseClassPath = bc_path), inner_mod) :: rest_el)
      equation
        (bcl, SOME(_)) = List.deleteMemberOnTrue(bc_path, bcl, Absyn.pathEqual);
        // Element name matches. Create a new modifier with the given modifier
        // as a named sub modifier, since the modifier is meant for an element
        // in the extended class, and merge the modifiers.
        outer_mod = InstTypes.MODIFIER("", SCode.NOT_FINAL(), SCode.NOT_EACH(),
          InstTypes.UNBOUND(), {sub_mod}, Absyn.dummyInfo);
        inner_mod = mergeMod(outer_mod, inner_mod);
        rest_el = applyModifications2((id, SOME(bcl), sub_mod), rest_el);
      then
        (el, inner_mod) :: rest_el;

    // All extends that the modifier should be applied to have been found.
    case ((_, SOME({}), _), _) then inElements;

    // No match, search the rest of the elements.
    case (_, e :: rest_el)
      equation
        rest_el = applyModifications2(inMod, rest_el);
      then
        e :: rest_el;

  end matchcontinue;
end applyModifications2;
        
public function mergeMod
  "Merges two modifiers, where the outer modifier has higher priority than the
   inner one."
  input Modifier inOuterMod;
  input Modifier inInnerMod;
  output Modifier outMod;
algorithm
  outMod := match(inOuterMod, inInnerMod)
    local
      SCode.Final fp;
      SCode.Each ep;
      list<Modifier> submods1, submods2;
      Binding binding;
      Absyn.Info info1, info2;
      String name;

    // One of the modifiers is NOMOD, return the other.
    case (InstTypes.NOMOD(), _) then inInnerMod;
    case (_, InstTypes.NOMOD()) then inOuterMod;

    // Neither of the modifiers have a binding, just merge the submods.
    case (InstTypes.MODIFIER(subModifiers = submods1, binding = InstTypes.UNBOUND(), info = info1),
          InstTypes.MODIFIER(name = name, subModifiers = submods2, binding = InstTypes.UNBOUND()))
      equation
        submods1 = List.fold(submods1, mergeSubMod, submods2);
      then
        InstTypes.MODIFIER(name, SCode.NOT_FINAL(), SCode.NOT_EACH(),
          InstTypes.UNBOUND(), submods1, info1);

    // The outer modifier has a binding which takes priority over the inner
    // modifiers binding.
    case (InstTypes.MODIFIER(name, fp, ep, binding as InstTypes.RAW_BINDING(bindingExp = _),
            submods1, info1),
          InstTypes.MODIFIER(subModifiers = submods2, info = info2))
      equation
        checkModifierFinalOverride(name, inOuterMod, info1, inInnerMod, info2);
        submods1 = List.fold(submods1, mergeSubMod, submods2);
      then
        InstTypes.MODIFIER(name, fp, ep, binding, submods1, info1);

    // The inner modifier has a binding, but not the outer, so keep it.
    case (InstTypes.MODIFIER(subModifiers = submods1, info = info1),
          InstTypes.MODIFIER(name, fp, ep, binding as InstTypes.RAW_BINDING(bindingExp = _),
            submods2, info2))
      equation
        checkModifierFinalOverride(name, inOuterMod, info1, inInnerMod, info2);
        submods2 = List.fold(submods1, mergeSubMod, submods2);
      then
        InstTypes.MODIFIER(name, fp, ep, binding, submods2, info1);

    case (InstTypes.MODIFIER(name = _), InstTypes.REDECLARE(element = _))
      then inOuterMod;

    case (InstTypes.REDECLARE(element = _), _) then inInnerMod;

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"InstTypes.mergeMod failed on unknown mod."});
      then
        fail();
  end match;
end mergeMod;

protected function checkModifierFinalOverride
  "Checks that a modifier is not trying to override a final modifier. In that
   case it prints an error and fails, otherwise it does nothing."
  input String inName;
  input Modifier inOuterMod;
  input Absyn.Info inOuterInfo;
  input Modifier inInnerMod;
  input Absyn.Info inInnerInfo;
algorithm
  _ := match(inName, inOuterMod, inOuterInfo, inInnerMod, inInnerInfo)
    local
      Absyn.Exp oexp;
      String oexp_str;

    case (_, _, _, InstTypes.MODIFIER(finalPrefix = SCode.FINAL()), _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inOuterInfo);
        InstTypes.RAW_BINDING(bindingExp = oexp) = getModifierBinding(inOuterMod);
        oexp_str = Dump.printExpStr(oexp);
        Error.addSourceMessage(Error.FINAL_COMPONENT_OVERRIDE,
          {inName, oexp_str}, inInnerInfo);
      then
        fail();

    else ();
  end match;
end checkModifierFinalOverride;

protected function mergeSubMod
  "Merges a sub modifier into a list of sub modifier."
  input Modifier inSubMod;
  input list<Modifier> inSubMods;
  output list<Modifier> outSubMods;
algorithm
  outSubMods := match(inSubMod, inSubMods)
    local
      String id;

    case (InstTypes.MODIFIER(name = id), _)
      then mergeSubMod_tail(id, inSubMod, inSubMods, {});

    else inSubMods;

  end match;
end mergeSubMod;

protected function mergeSubMod_tail
  "Tail-recursive implementation of mergeSubMod."
  input String inSubModId;
  input Modifier inSubMod;
  input list<Modifier> inSubMods;
  input list<Modifier> inAccumMods;
  output list<Modifier> outSubMods;
algorithm
  outSubMods := match(inSubModId, inSubMod, inSubMods, inAccumMods)
    local
      SCode.Ident id;
      Modifier mod;
      list<Modifier> rest_mods, accum;
      Boolean is_equal;

    case (_, _, (mod as InstTypes.MODIFIER(name = id)) :: rest_mods, _)
      equation
        is_equal = stringEq(inSubModId, id);
      then
        mergeSubMod_tail2(inSubModId, inSubMod, mod, is_equal, rest_mods, inAccumMods);

    case (_, _, {}, _)
      equation
        accum = inSubMod :: inAccumMods;
      then
        listReverse(accum);

    case (_, _, _ :: rest_mods, _)
      then mergeSubMod_tail(inSubModId, inSubMod, rest_mods, inAccumMods);

  end match;
end mergeSubMod_tail;

protected function mergeSubMod_tail2
  "Helper function to mergeSubMod_tail."
  input String inSubModId;
  input Modifier inSubMod1;
  input Modifier inSubMod2;
  input Boolean inIsEqual;
  input list<Modifier> inSubMods;
  input list<Modifier> inAccumMods;
  output list<Modifier> outSubMods;
algorithm
  outSubMods := match(inSubModId, inSubMod1, inSubMod2, inIsEqual, inSubMods, inAccumMods)
    local
      Modifier mod;
      list<Modifier> accum;

    // If both sub modifiers have the same identifier, merge them and return the
    // list of modifiers with the new modifier in it.
    case (_, _, _, true, _, _)
      equation
        mod = mergeMod(inSubMod1, inSubMod2);
        accum = mod :: inAccumMods;
        accum = listReverse(accum);
      then
        listAppend(accum, inSubMods);

    // Otherwise, continue to search for a matching modifier.
    else mergeSubMod_tail(inSubModId, inSubMod1, inSubMods, inSubMod2 :: inAccumMods);

  end match;
end mergeSubMod_tail2;

protected function splitMod
  "Splits a modifier that contains sub modifiers info a list of tuples of
   element names with their corresponding modifiers. Ex:
     MOD(x(w = 2), y = 3, x(z = 4) = 5 => 
      {('x', MOD(w = 2, z = 4) = 5), ('y', MOD() = 3)}" 
  input Modifier inMod;
  input Prefix inPrefix;
  output list<tuple<String, Modifier>> outMods;
algorithm
  outMods := match(inMod, inPrefix)
    local
      list<Modifier> submods;
      list<tuple<String, Modifier>> mods;

    // TOOD: print an error if this modifier has a binding?
    case (InstTypes.MODIFIER(subModifiers = submods), _)
      equation
        mods = List.fold1(submods, splitSubMod, inPrefix, {});
      then
        mods;

    else {};

  end match;
end splitMod;

protected function splitSubMod
  "Splits a named sub modifier."
  input Modifier inSubMod;
  input Prefix inPrefix;
  input list<tuple<String, Modifier>> inMods;
  output list<tuple<String, Modifier>> outMods;
algorithm
  outMods := match(inSubMod, inPrefix, inMods)
    local
      SCode.Ident id;
      list<tuple<String, Modifier>> mods;

    // Filter out redeclarations, they have already been applied.
    case (InstTypes.REDECLARE(element = _), _, _)
      then inMods;

    case (InstTypes.MODIFIER(name = id), _, _)
      equation
        mods = splitMod2(id, inSubMod, inPrefix, inMods);
      then
        mods;

    case (InstTypes.NOMOD(), _, _) then inMods;

  end match;
end splitSubMod;

protected function splitMod2
  "Helper function to splitSubMod. Tries to find a modifier for the same element
   as the given modifier, and in that case merges them. Otherwise, add the
   modifier to the given list."
  input String inId;
  input Modifier inMod;
  input Prefix inPrefix;
  input list<tuple<String, Modifier>> inMods;
  output list<tuple<String, Modifier>> outMods;
algorithm
  outMods := matchcontinue(inId, inMod, inPrefix, inMods)
    local
      Modifier mod;
      tuple<String, Modifier> tup_mod;
      list<tuple<String, Modifier>> rest_mods;
      String id;

    // No match, add the modifier to the list.
    case (_, _, _, {}) then {(inId, inMod)};

    case (_, _, _, (id, mod) :: rest_mods)
      equation
        true = stringEq(id, inId);
        // Matching element, merge the modifiers.
        mod = mergeModsInSameScope(mod, inMod, id, inPrefix);
      then
        (inId, mod) :: rest_mods;

    case (_, _, _, tup_mod :: rest_mods)
      equation
        rest_mods = splitMod2(inId, inMod, inPrefix, rest_mods);
      then
        tup_mod :: rest_mods;

  end matchcontinue;
end splitMod2;

protected function mergeModsInSameScope
  "Merges two modifier in the same scope, i.e. they have the same priority. It's
   thus an error if the modifiers modify the same element."
  input Modifier inMod1;
  input Modifier inMod2;
  input String inElementName;
  input Prefix inPrefix;
  output Modifier outMod;
algorithm
  outMod := match(inMod1, inMod2, inElementName, inPrefix)
    local
      SCode.Final fp;
      SCode.Each ep;
      list<Modifier> submods1, submods2;
      Binding binding;
      String name, comp_str;
      Absyn.Info info1, info2;

    // The second modifier has no binding, use the binding from the first.
    case (InstTypes.MODIFIER(name, fp, ep, binding, submods1, info1),
          InstTypes.MODIFIER(subModifiers = submods2, binding = InstTypes.UNBOUND()), _, _)
      equation
        submods1 = List.fold2(submods1, mergeSubModInSameScope, inPrefix,
          inElementName, submods2);
      then
        InstTypes.MODIFIER(name, fp, ep, binding, submods1, info1);

    // The first modifier has no binding, use the binding from the second.
    case (InstTypes.MODIFIER(subModifiers = submods1, binding = InstTypes.UNBOUND()),
          InstTypes.MODIFIER(name, fp, ep, binding, submods2, info2), _, _)
      equation
        submods1 = List.fold2(submods1, mergeSubModInSameScope, inPrefix,
          inElementName, submods2);
      then
        InstTypes.MODIFIER(name, fp, ep, binding, submods1, info2);

    // Both modifiers have bindings, show duplicate modification error.
    case (InstTypes.MODIFIER(binding = InstTypes.RAW_BINDING(bindingExp = _), info = info1),
          InstTypes.MODIFIER(binding = InstTypes.RAW_BINDING(bindingExp = _), info = info2), _, _)
      equation
        comp_str = InstDump.prefixStr(inPrefix);
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, info2);
        Error.addSourceMessage(Error.DUPLICATE_MODIFICATIONS, 
          {inElementName, comp_str}, info1);
      then
        fail();

  end match;
end mergeModsInSameScope;

protected function mergeSubModInSameScope
  "Merges two sub modifiers in the same scope."
  input Modifier inSubMod;
  input Prefix inPrefix;
  input String inElementName;
  input list<Modifier> inSubMods;
  output list<Modifier> outSubMods;
algorithm
  outSubMods := match(inSubMod, inPrefix, inElementName, inSubMods)
    local
      SCode.Ident id1, id2;
      Modifier mod;
      list<Modifier> rest_mods;

    case (_, _, _, {}) then inSubMods;

    case (InstTypes.MODIFIER(name = id1), _, _, 
        (mod as InstTypes.MODIFIER(name = id2)) :: rest_mods)
      equation
        true = stringEq(id1, id2);
        id1 = inElementName +& "." +& id1;
        mod = mergeModsInSameScope(inSubMod, mod, id1, inPrefix);
      then
        mod :: rest_mods;

    case (_, _, _, mod :: rest_mods)
      equation
        rest_mods = mergeSubModInSameScope(inSubMod, inPrefix, inElementName, rest_mods);
      then
        mod :: rest_mods;

  end match;
end mergeSubModInSameScope;

public function getModifierBinding
  input Modifier inModifier;
  output Binding outBinding;
algorithm
  outBinding := match(inModifier)
    local
      Binding binding;

    case InstTypes.MODIFIER(binding = binding) then binding;
    else InstTypes.UNBOUND();

  end match;
end getModifierBinding;

public function propagateMod
  "Saves information about how a modifier has been propagated. Since arrays are
   not expanded during the instantiation we need to know where a binding comes
   from, e.g:
  
     model A
       Real x;
     end A;

     model B
       A a[3](x = {1, 2, 3});
     end B;

     model C
       B b[2];
     end C;

   This results in a component b[2].a[3].x = {1, 2, 3}. Since x is a scalar we
   need to add dimensions to it (or remove from the binding) when doing type
   checking, so that it matches the binding. To do this we need to now how many
   dimensions the binding has been propagated through. In this case it's been
   propagated from B.a to A.x, and since B.a has one dimension we should add
   that dimension to A.x to make it match the binding. The number of dimensions
   that a binding is propagated through is therefore saved in a binding. A
   binding can also have the 'each' prefix, meaning that the binding should be
   applied as it is. In that case we set the dimension counter to -1 and don't
   increment it when the binding is propagated.

   This function simply goes through a modifier recursively and increments the
   dimension counter by the number of dimensions that an element has."
  input Modifier inModifier;
  input Integer inDimensions;
  output Modifier outModifier;
algorithm
  outModifier := match(inModifier, inDimensions)
    local
      String name;
      SCode.Final fp;
      SCode.Each ep;
      InstTypes.Binding binding;
      list<Modifier> submods;
      Absyn.Info info;

    case (_, 0) then inModifier;

    case (InstTypes.MODIFIER(name, fp, ep, binding, submods, info), _)
      equation
        binding = propagateBinding(binding, inDimensions);
        submods = List.map1(submods, propagateMod, inDimensions);
      then
        InstTypes.MODIFIER(name, fp, ep, binding, submods, info);

    else inModifier;

  end match;
end propagateMod;

protected function propagateBinding
  input Binding inBinding;
  input Integer inDimensions;
  output Binding outBinding;
algorithm
  outBinding := match(inBinding, inDimensions)
    local
      Absyn.Exp bind_exp;
      Env env;
      Prefix prefix;
      Integer pd;
      Absyn.Info info;

    // Special case for the each prefix, don't do anything.
    case (InstTypes.RAW_BINDING(propagatedDims = -1), _) then inBinding;

    // A normal binding, increment with the dimension count.
    case (InstTypes.RAW_BINDING(bind_exp, env, prefix, pd, info), _)
      equation
        pd = pd + inDimensions;
      then 
        InstTypes.RAW_BINDING(bind_exp, env, prefix, pd, info);

    else inBinding;
  end match;
end propagateBinding;

public function printMod
  input Modifier inMod;
  output String outString;
algorithm
  outString := match(inMod)
    local
      SCode.Final fp;
      SCode.Each ep;
      list<Modifier> submods;
      Binding binding;
      SCode.Element el;
      String fstr, estr, submod_str, bind_str, el_str;

    case InstTypes.MODIFIER(_, fp, ep, binding, submods, _)
      equation
        fstr = SCodeDump.finalStr(fp);
        estr = SCodeDump.eachStr(ep);
        submod_str = stringDelimitList(List.map(submods, printSubMod), ", ");
        bind_str = InstDump.bindingStr(binding);
      then
        "MOD(" +& fstr +& estr +& "{" +& submod_str +& "})" +& bind_str;

    case InstTypes.REDECLARE(fp, ep, el)
      equation
        fstr = SCodeDump.finalStr(fp);
        estr = SCodeDump.eachStr(ep);
        el_str = SCodeDump.unparseElementStr(el);
      then
        "REDECL(" +& fstr +& estr +& el_str +& ")";

    case InstTypes.NOMOD() then "NOMOD()";
  end match;
end printMod;

protected function printSubMod
  input Modifier inSubMod;
  output String outString;
algorithm
  outString := match(inSubMod)
    local
      list<SCode.Subscript> subs;
      String id, mod_str, subs_str;

    case InstTypes.MODIFIER(name = id)
      then id +& " = " +& printMod(inSubMod);

    else "";
  end match;
end printSubMod;

public function removeModFromModContainingCref
"@author: adrpo
 removes the named modifier bound to an expression that contains the given id"
  input SCode.Mod inMod;
  input Absyn.ComponentRef id;
  output SCode.Mod outMod;
algorithm
  outMod := match(inMod, id)
    local
      Option<String> n;
      list<SCode.SubMod> sl;
      SCode.Final fp;
      SCode.Each ep;
      Option<tuple<Absyn.Exp, Boolean>> b;
      Absyn.Info i;
      
    case (SCode.MOD(fp, ep, sl, b, i),_)
      equation
        sl = removeModFromSubModContainingCref(sl, id);
      then
        SCode.MOD(fp, ep, sl, b, i);
    
    else inMod;
    
  end match;
end removeModFromModContainingCref;

protected function removeModFromSubModContainingCref
"@author: adrpo
 removes the named modifier bound to an expression that contains the given id"
  input list<SCode.SubMod> inSl;
  input Absyn.ComponentRef id;
  output list<SCode.SubMod> outSl;
algorithm
  outSl := matchcontinue(inSl, id)
    local
      String n;
      list<SCode.SubMod> sl,rest;
      Absyn.Exp e;
      list<Absyn.ComponentRef> cl;
      SCode.SubMod sm;
    
    case ({}, _) then {};
    
    case (SCode.NAMEMOD(ident = n, A = SCode.MOD(binding = SOME((e, _))))::rest, _)
      equation
        cl = Absyn.getCrefFromExp(e,true);
        true = List.fold(List.map1(cl, Absyn.crefFirstEqual, id), boolOr, false);  
      then
        rest;
    
    case (sm::rest, _) 
      equation
        sl = removeModFromSubModContainingCref(rest, id);
      then 
        sm::sl;
  end matchcontinue;
end removeModFromSubModContainingCref;

public function removeCrefPrefixFromModExp
"@author: adrpo
 removes the cref prefix from a modifier bound to an expression that contains the given id.
 i.e. Type c(z = c.xi) -> Type c(z = xi)"
  input SCode.Mod inMod;
  input Absyn.ComponentRef id;
  output SCode.Mod outMod;
algorithm
  outMod := match(inMod, id)
    local
      Option<String> n;
      list<SCode.SubMod> sl;
      SCode.Final fp;
      SCode.Each ep;
      Absyn.Info i;
      Absyn.Exp e;
      Boolean b;
      
    case (SCode.MOD(fp, ep, sl, SOME((e, b)), i),_)
      equation
        sl = removeCrefPrefixFromSubModExp(sl, id);
        ((e, _)) = Absyn.traverseExp(e, removeCrefPrefix, id); 
      then
        SCode.MOD(fp, ep, sl, SOME((e, b)), i);
        
    case (SCode.MOD(fp, ep, sl, NONE(), i),_)
      equation
        sl = removeCrefPrefixFromSubModExp(sl, id);
      then
        SCode.MOD(fp, ep, sl, NONE(), i);
    
    else inMod;
    
  end match;
end removeCrefPrefixFromModExp;

protected function removeCrefPrefixFromSubModExp
"@author: adrpo
 removes the cref prefix from a modifier bound to an expression that contains the given id.
 i.e. Type c(z = c.xi) -> Type c(z = xi)"
  input list<SCode.SubMod> inSl;
  input Absyn.ComponentRef id;
  output list<SCode.SubMod> outSl;
algorithm
  outSl := matchcontinue(inSl, id)
    local
      String n;
      list<SCode.SubMod> sl,rest;
      SCode.SubMod sm;
      SCode.Mod m;
      list<SCode.Subscript> ssl;
    
    case ({}, _) then {};
    
    case (SCode.NAMEMOD(n, m)::rest, _)
      equation
        m = removeCrefPrefixFromModExp(m, id);
        sl = removeCrefPrefixFromSubModExp(rest, id); 
      then
        SCode.NAMEMOD(n, m)::sl;
        
    case (SCode.IDXMOD(ssl, m)::rest, _)
      equation
        m = removeCrefPrefixFromModExp(m, id); 
        sl = removeCrefPrefixFromSubModExp(rest, id);
      then
        SCode.IDXMOD(ssl, m)::sl;
    
    case (sm::rest, _) 
      equation
        sl = removeCrefPrefixFromSubModExp(rest, id);
      then 
        sm::sl;
  end matchcontinue;
end removeCrefPrefixFromSubModExp;

protected function removeCrefPrefix
  input tuple<Absyn.Exp, Absyn.ComponentRef> inCrefExp_inPrefix;
  output tuple<Absyn.Exp, Absyn.ComponentRef> outCrefExp_outPrefix;
algorithm
  outCrefExp_outPrefix := matchcontinue(inCrefExp_inPrefix)
    local
      Absyn.ComponentRef cr, pre;
      
    case ((Absyn.CREF(cr), pre))
      equation
        true = Absyn.crefFirstEqual(cr, pre);
        cr = Absyn.crefStripFirst(cr);  
      then
        ((Absyn.CREF(cr), pre));
    
    else inCrefExp_inPrefix;
  end matchcontinue;
end removeCrefPrefix;

public function removeRedeclaresFromMod
"@author: adrpo
 removes redeclares from the mod."
  input SCode.Mod inMod;
  output SCode.Mod outMod;
algorithm
  outMod := match(inMod)
    local
      Option<String> n;
      list<SCode.SubMod> sl;
      SCode.Final fp;
      SCode.Each ep;
      Absyn.Info i;
      Option<tuple<Absyn.Exp, Boolean>> binding;
      
    case (SCode.MOD(fp, ep, sl, binding, i))
      equation
        sl = removeRedeclaresFromSubMod(sl); 
      then
        SCode.MOD(fp, ep, sl, binding, i);
    
    case (SCode.REDECL(element = _)) then SCode.NOMOD();
    
    else inMod;
    
  end match;
end removeRedeclaresFromMod;

protected function removeRedeclaresFromSubMod
"@author: adrpo
 removes the redeclares from a submod"
  input list<SCode.SubMod> inSl;
  output list<SCode.SubMod> outSl;
algorithm
  outSl := matchcontinue(inSl)
    local
      String n;
      list<SCode.SubMod> sl,rest;
      SCode.SubMod sm;
      SCode.Mod m;
      list<SCode.Subscript> ssl;
    
    case ({}) then {};
    
    case (SCode.NAMEMOD(n, m)::rest)
      equation
        m = removeRedeclaresFromMod(m);
        sl = removeRedeclaresFromSubMod(rest);
      then
        SCode.NAMEMOD(n, m)::sl;
        
    case (SCode.IDXMOD(ssl, m)::rest)
      equation
        m = removeRedeclaresFromMod(m); 
        sl = removeRedeclaresFromSubMod(rest);
      then
        SCode.IDXMOD(ssl, m)::sl;
        
  end matchcontinue;
end removeRedeclaresFromSubMod;

end SCodeMod;
