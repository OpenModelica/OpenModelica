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


encapsulated package NFSCodeMod
" file:        NFSCodeMod.mo
  package:     NFSCodeMod
  description: Modification handling for NFSCodeInst.

  RCS: $Id: NFSCodeMod.mo 7705 2011-01-17 09:53:52Z sjoelund.se $

  Functions for handling modifications, used by NFSCodeInst.
  "

public import Absyn;
public import SCode;
public import NFSCodeEnv;
public import NFInstTypesOld;

protected import BaseHashTable;
protected import Debug;
protected import Dump;
protected import Error;
protected import Flags;
protected import List;
protected import NFInstDump;
protected import NFSCodeLookup;
protected import System;
protected import Util;

public type Binding = NFInstTypesOld.Binding;
public type Env = NFSCodeEnv.Env;
public type Prefix = NFInstTypesOld.Prefix;
public type Modifier = NFInstTypesOld.Modifier;

protected type Extends = NFSCodeEnv.Extends;

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
      Option<Absyn.Exp> binding_exp;
      SourceInfo info;
      list<Modifier> mods;
      Binding binding;
      SCode.Element el;
      Integer pd;

    case (SCode.NOMOD(), _, _, _, _) then NFInstTypesOld.NOMOD();

    case (SCode.MOD(fp, ep, submods, binding_exp, info), _, _, _, _)
      equation
        pd = if SCode.eachBool(ep) then 0 else inDimensions;
        mods = List.map3(submods, translateSubMod, pd, inPrefix, inEnv);
        binding = translateBinding(binding_exp, ep, pd, inPrefix, inEnv, info);
      then
        NFInstTypesOld.MODIFIER(inElementName, fp, ep, binding, mods, info);

    case (SCode.REDECL(fp, ep, el), _, _, _, _)
      then NFInstTypesOld.REDECLARE(fp, ep, el);

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
  input Option<Absyn.Exp> inBinding;
  input SCode.Each inEachPrefix;
  input Integer inDimensions;
  input Prefix inPrefix;
  input Env inEnv;
  input SourceInfo inInfo;
  output Binding outBinding;
algorithm
  outBinding := match inBinding
    local
      Absyn.Exp bind_exp;
      Integer pd;

    case NONE() then NFInstTypesOld.UNBOUND();

    // See propagateMod for how this works.
    case SOME(bind_exp)
      equation
        pd = if SCode.eachBool(inEachPrefix) then -1 else inDimensions;
      then
        NFInstTypesOld.RAW_BINDING(bind_exp, inEnv, inPrefix, pd, inInfo);

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
algorithm
  outElements := matchcontinue(inMod, inElements, inPrefix, inEnv)
    local
      list<tuple<String, Modifier>> mods;
      list<tuple<String, list<Absyn.Path>, Modifier>> upd_mods;
      list<tuple<SCode.Element, Modifier>> el;
      ModifierTable mod_table;
      list<Extends> exts;

    case (NFInstTypesOld.NOMOD(), _, _, _)
      equation
        el = List.map(inElements, addNoMod);
      then
        el;

    case (_, _, _, _)
      equation
        mods = splitMod(inMod, inPrefix);
        upd_mods = List.map2(mods, updateModElement, inEnv, inPrefix);
        mod_table = emptyModifierTable(listLength(upd_mods));
        mod_table = List.fold(upd_mods, updateModTable, mod_table);
        exts = NFSCodeEnv.getEnvExtendsFromTable(inEnv);
        (el, _) = List.map1Fold(inElements, updateElementWithMod, mod_table, exts);
      then
        el;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFSCodeMod.applyModifications failed on modifier " +
          printMod(inMod));
      then
        fail();

  end matchcontinue;
end applyModifications;

protected function addNoMod
  input SCode.Element inElement;
  output tuple<SCode.Element, Modifier> outElement;
algorithm
  outElement := (inElement, NFInstTypesOld.NOMOD());
end addNoMod;

protected function updateModElement
  "Given a tuple of an element name and a modifier, checks if the element
   is in the local scope, or if it comes from an extends clause. If it comes
   from an extends, return a new tuple that also contains the paths of the
   extends, otherwise the option will be NONE."
  input tuple<String, Modifier> inMod;
  input Env inEnv;
  input Prefix inPrefix;
  output tuple<String, list<Absyn.Path>, Modifier> outMod;
protected
  String name;
  Modifier mod;
  NFSCodeEnv.Item item;
  list<Absyn.Path> bcl;
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
  output NFSCodeEnv.Item outItem;
  output list<Absyn.Path> outBaseClasses;
algorithm
  (outItem, outBaseClasses) := matchcontinue(inName, inEnv, inPrefix, inMod)
    local
      NFSCodeEnv.Item item;
      list<Absyn.Path> bcl;
      SourceInfo info;
      String pre_str;

    // Check if the modified element can be found in one of the extended classes.
    case (_, _, _, _)
      equation
        (item :: _, bcl) = NFSCodeLookup.lookupInheritedNameAndBC(inName, inEnv);
      then
        (item, bcl);

    // Check if the modified element can be found in the local scope.
    case (_, _, _, _)
      equation
        (item, _) = NFSCodeLookup.lookupInClass(inName, inEnv);
      then
        (item, {});

    // The modified element couldn't be found, show an error.
    else
      equation
        pre_str = NFInstDump.prefixStr(inPrefix);
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
  input NFSCodeEnv.Item inItem;
  input tuple<String, Modifier> inMod;
  input Prefix inPrefix;
algorithm
  _ := match(inItem, inMod, inPrefix)
    local
      String name, pre_str;
      Modifier mod;
      SourceInfo info;

    // The modified element is a class but the modifier has no binding, e.g.
    // c(A(x = 3)). This is ok.
    case (NFSCodeEnv.CLASS(),
        (_, NFInstTypesOld.MODIFIER(binding = NFInstTypesOld.UNBOUND())), _)
      then ();

    // The modified element is a class but the modifier has a binding. This is
    // not ok, tell the user that the redeclare keyword is missing.
    case (NFSCodeEnv.CLASS(), (name, mod), _)
      equation
        info = getModifierInfo(mod);
        pre_str = NFInstDump.prefixStr(inPrefix);
        Error.addSourceMessage(Error.MISSING_REDECLARE_IN_CLASS_MOD,
          {name, pre_str}, info);
      then
        fail();

    else ();

  end match;
end checkClassModifier;

protected function getModifierInfo
  input Modifier inMod;
  output SourceInfo outInfo;
algorithm
  outInfo := match(inMod)
    local
      SourceInfo info;

    case NFInstTypesOld.MODIFIER(info = info) then info;
    else Absyn.dummyInfo;

  end match;
end getModifierInfo;

protected function updateModTable
  input tuple<String, list<Absyn.Path>, Modifier> inMod;
  input ModifierTable inTable;
  output ModifierTable outTable;
protected
  String name;
  list<Absyn.Path> bcl;
  Modifier mod;
algorithm
  (name, bcl, mod) := inMod;
  outTable := BaseHashTable.addNoUpdCheck((Absyn.IDENT(name), mod), inTable);
  outTable := List.fold1(bcl, updateModTable2, mod, outTable);
end updateModTable;

protected function getExtendsMod
  input Absyn.Path inBaseClass;
  input ModifierTable inTable;
  output Modifier outMod;
algorithm
  outMod := matchcontinue(inBaseClass, inTable)
    local
      Modifier mod;

    case (_, _)
      equation
        mod = BaseHashTable.get(inBaseClass, inTable);
      then
        mod;

    else NFInstTypesOld.NOMOD();
  end matchcontinue;
end getExtendsMod;

protected function updateModTable2
  input Absyn.Path inName;
  input Modifier inMod;
  input ModifierTable inTable;
  output ModifierTable outTable;
protected
  Modifier inner_mod, outer_mod;
algorithm
  inner_mod := getExtendsMod(inName, inTable);
  outer_mod := NFInstTypesOld.MODIFIER("", SCode.NOT_FINAL(), SCode.NOT_EACH(),
    NFInstTypesOld.UNBOUND(), {inMod}, Absyn.dummyInfo);
  inner_mod := mergeMod(outer_mod, inner_mod);
  outTable := BaseHashTable.addNoUpdCheck((inName, inner_mod), inTable);
end updateModTable2;

protected function updateElementWithMod
  input SCode.Element inElement;
  input ModifierTable inTable;
  input list<Extends> inExtends;
  output tuple<SCode.Element, Modifier> outElement;
  output list<Extends> outExtends;
algorithm
  (outElement, outExtends) := matchcontinue(inElement, inTable, inExtends)
    local
      String name;
      Modifier mod;
      Absyn.Path bc;
      list<Extends> rest_exts;

    case (SCode.COMPONENT(name = name), _, _)
      equation
        mod = BaseHashTable.get(Absyn.IDENT(name), inTable);
      then
        ((inElement, mod), inExtends);

    case (SCode.EXTENDS(), _,
        NFSCodeEnv.EXTENDS(baseClass = bc) :: rest_exts)
      equation
        mod = BaseHashTable.get(bc, inTable);
      then
        ((inElement, mod), rest_exts);

    case (SCode.EXTENDS(), _, _ :: rest_exts)
      then ((inElement, NFInstTypesOld.NOMOD()), rest_exts);

    else ((inElement, NFInstTypesOld.NOMOD()), inExtends);

  end matchcontinue;
end updateElementWithMod;

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
      SourceInfo info1, info2;
      String name;

    // One of the modifiers is NOMOD, return the other.
    case (NFInstTypesOld.NOMOD(), _) then inInnerMod;
    case (_, NFInstTypesOld.NOMOD()) then inOuterMod;

    // Neither of the modifiers have a binding, just merge the submods.
    case (NFInstTypesOld.MODIFIER(subModifiers = submods1, binding = NFInstTypesOld.UNBOUND(), info = info1),
          NFInstTypesOld.MODIFIER(name = name, subModifiers = submods2, binding = NFInstTypesOld.UNBOUND()))
      equation
        submods1 = List.fold(submods1, mergeSubMod, submods2);
      then
        NFInstTypesOld.MODIFIER(name, SCode.NOT_FINAL(), SCode.NOT_EACH(),
          NFInstTypesOld.UNBOUND(), submods1, info1);

    // The outer modifier has a binding which takes priority over the inner
    // modifiers binding.
    case (NFInstTypesOld.MODIFIER(name, fp, ep, binding as NFInstTypesOld.RAW_BINDING(),
            submods1, info1),
          NFInstTypesOld.MODIFIER(subModifiers = submods2, info = info2))
      equation
        checkModifierFinalOverride(name, inOuterMod, info1, inInnerMod, info2);
        submods1 = List.fold(submods1, mergeSubMod, submods2);
      then
        NFInstTypesOld.MODIFIER(name, fp, ep, binding, submods1, info1);

    // The inner modifier has a binding, but not the outer, so keep it.
    case (NFInstTypesOld.MODIFIER(subModifiers = submods1, info = info1),
          NFInstTypesOld.MODIFIER(name, fp, ep, binding as NFInstTypesOld.RAW_BINDING(),
            submods2, info2))
      equation
        checkModifierFinalOverride(name, inOuterMod, info1, inInnerMod, info2);
        submods2 = List.fold(submods1, mergeSubMod, submods2);
      then
        NFInstTypesOld.MODIFIER(name, fp, ep, binding, submods2, info1);

    case (NFInstTypesOld.MODIFIER(), NFInstTypesOld.REDECLARE())
      then inOuterMod;

    case (NFInstTypesOld.REDECLARE(), _) then inInnerMod;

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"NFInstTypesOld.mergeMod failed on unknown mod."});
      then
        fail();
  end match;
end mergeMod;

protected function checkModifierFinalOverride
  "Checks that a modifier is not trying to override a final modifier. In that
   case it prints an error and fails, otherwise it does nothing."
  input String inName;
  input Modifier inOuterMod;
  input SourceInfo inOuterInfo;
  input Modifier inInnerMod;
  input SourceInfo inInnerInfo;
algorithm
  _ := match(inName, inOuterMod, inOuterInfo, inInnerMod, inInnerInfo)
    local
      Absyn.Exp oexp;
      String oexp_str;

    case (_, _, _, NFInstTypesOld.MODIFIER(finalPrefix = SCode.FINAL()), _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inOuterInfo);
        NFInstTypesOld.RAW_BINDING(bindingExp = oexp) = getModifierBinding(inOuterMod);
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

    case (NFInstTypesOld.MODIFIER(name = id), _)
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

    case (_, _, (mod as NFInstTypesOld.MODIFIER(name = id)) :: rest_mods, _)
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
     MOD(x(w = 2), y = 3, x(z = 4) = 5) =>
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
    case (NFInstTypesOld.MODIFIER(subModifiers = submods), _)
      equation
        mods = List.fold1(submods, splitSubMod, inPrefix, {});
      then
        mods;

    else {};

  end match;
end splitMod;

protected function splitSubMod
  "Adds the given sub modifier to the list of modifiers, merging it with an
   already existing modifier with the same name if such a modifier exists."
  input Modifier inSubMod;
  input Prefix inPrefix;
  input list<tuple<String, Modifier>> inMods;
  output list<tuple<String, Modifier>> outMods;
algorithm
  outMods := match(inSubMod, inPrefix, inMods)
    local
      SCode.Ident id;
      list<tuple<String, Modifier>> mods;
      Boolean found;

    // Filter out redeclarations, they have already been applied.
    case (NFInstTypesOld.REDECLARE(), _, _)
      then inMods;

    case (NFInstTypesOld.MODIFIER(name = id), _, _)
      equation
        // Use splitMod2 to try and find a matching modifier to merge with.
        (mods, found) = List.findMap3(inMods, splitMod2, id, inSubMod, inPrefix);
        // Add the sub modifier to the list if it wasn't merged by splitMod2.
        mods = List.consOnTrue(not found, (id, inSubMod), mods);
      then
        mods;

    case (NFInstTypesOld.NOMOD(), _, _) then inMods;

  end match;
end splitSubMod;

protected function splitMod2
  "Helper function to splitSubMod. Merges the given modifiers if they have the
   same name, i.e. if they modify the same element."
  input tuple<String, Modifier> inExistingMod;
  input String inId;
  input Modifier inNewMod;
  input Prefix inPrefix;
  output tuple<String, Modifier> outMod;
  output Boolean outFound;
algorithm
  (outMod, outFound) := match(inExistingMod, inId, inNewMod, inPrefix)
    local
      String id;
      Modifier mod;

    case ((id, _), _, _, _) guard not stringEq(id, inId)
      then
        (inExistingMod, false);

    case ((id, mod), _, _, _)
      equation
        mod = mergeModsInSameScope(mod, inNewMod, id, inPrefix);
      then
        ((id, mod), true);

  end match;
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
      SourceInfo info1, info2;

    // The second modifier has no binding, use the binding from the first.
    case (NFInstTypesOld.MODIFIER(name, fp, ep, binding, submods1, info1),
          NFInstTypesOld.MODIFIER(subModifiers = submods2, binding = NFInstTypesOld.UNBOUND()), _, _)
      equation
        submods1 = List.fold2(submods1, mergeSubModInSameScope, inPrefix,
          inElementName, submods2);
      then
        NFInstTypesOld.MODIFIER(name, fp, ep, binding, submods1, info1);

    // The first modifier has no binding, use the binding from the second.
    case (NFInstTypesOld.MODIFIER(subModifiers = submods1, binding = NFInstTypesOld.UNBOUND()),
          NFInstTypesOld.MODIFIER(name, fp, ep, binding, submods2, info2), _, _)
      equation
        submods1 = List.fold2(submods1, mergeSubModInSameScope, inPrefix,
          inElementName, submods2);
      then
        NFInstTypesOld.MODIFIER(name, fp, ep, binding, submods1, info2);

    // Both modifiers have bindings, show duplicate modification error.
    case (NFInstTypesOld.MODIFIER(binding = NFInstTypesOld.RAW_BINDING(), info = info1),
          NFInstTypesOld.MODIFIER(binding = NFInstTypesOld.RAW_BINDING(), info = info2), _, _)
      equation
        comp_str = NFInstDump.prefixStr(inPrefix);
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, info2);
        Error.addSourceMessage(Error.DUPLICATE_MODIFICATIONS,
          {inElementName, comp_str}, info1);
      then
        fail();

  end match;
end mergeModsInSameScope;

protected function mergeSubModInSameScope
  input Modifier inSubMod;
  input Prefix inPrefix;
  input String inElementName;
  input list<Modifier> inSubMods;
  output list<Modifier> outSubMods;
protected
  Boolean found;
algorithm
  (outSubMods, found) := List.findMap3(inSubMods, mergeSubModInSameScope2,
    inSubMod, inPrefix, inElementName);
  outSubMods := List.consOnTrue(not found, inSubMod, outSubMods);
end mergeSubModInSameScope;

protected function mergeSubModInSameScope2
  "Helper function to mergeModsInSameScope. Merges two sub modifiers if they
   have the same name."
  input Modifier inExistingMod;
  input Modifier inNewMod;
  input Prefix inPrefix;
  input String inElementName;
  output Modifier outMod;
  output Boolean outFound;
algorithm
  (outMod, outFound) :=
  match(inExistingMod, inNewMod, inPrefix, inElementName)
    local
      String id1, id2;
      Modifier mod;

    case (NFInstTypesOld.MODIFIER(name = id1),
          NFInstTypesOld.MODIFIER(name = id2), _, _) guard not stringEq(id1, id2)
      then
        (inExistingMod, false);

    case (NFInstTypesOld.MODIFIER(name = id1), _, _, _)
      equation
        id1 = inElementName + "." + id1;
        mod = mergeModsInSameScope(inExistingMod, inNewMod, id1, inPrefix);
      then
        (mod, true);

  end match;
end mergeSubModInSameScope2;

public function getModifierBinding
  input Modifier inModifier;
  output Binding outBinding;
algorithm
  outBinding := match(inModifier)
    local
      Binding binding;

    case NFInstTypesOld.MODIFIER(binding = binding) then binding;
    else NFInstTypesOld.UNBOUND();

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
      NFInstTypesOld.Binding binding;
      list<Modifier> submods;
      SourceInfo info;

    case (_, 0) then inModifier;

    case (NFInstTypesOld.MODIFIER(name, fp, ep, binding, submods, info), _)
      equation
        binding = propagateBinding(binding, inDimensions);
        submods = List.map1(submods, propagateMod, inDimensions);
      then
        NFInstTypesOld.MODIFIER(name, fp, ep, binding, submods, info);

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
      SourceInfo info;

    // Special case for the each prefix, don't do anything.
    case (NFInstTypesOld.RAW_BINDING(propagatedDims = -1), _) then inBinding;

    // A normal binding, increment with the dimension count.
    case (NFInstTypesOld.RAW_BINDING(bind_exp, env, prefix, pd, info), _)
      equation
        pd = pd + inDimensions;
      then
        NFInstTypesOld.RAW_BINDING(bind_exp, env, prefix, pd, info);

    else inBinding;
  end match;
end propagateBinding;

public function printMod
  input Modifier inMod;
  output String outString;
algorithm
  outString := "MOD";
end printMod;

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
      Option<Absyn.Exp> b;
      SourceInfo i;

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

    case (SCode.NAMEMOD(mod = SCode.MOD(binding = SOME(e)))::rest, _)
      equation
        cl = Absyn.getCrefFromExp(e,true,true);
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
      SourceInfo i;
      Absyn.Exp e;

    case (SCode.MOD(fp, ep, sl, SOME(e), i),_)
      equation
        sl = removeCrefPrefixFromSubModExp(sl, id);
        (e, _) = Absyn.traverseExp(e, removeCrefPrefix, id);
      then
        SCode.MOD(fp, ep, sl, SOME(e), i);

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

    case (sm::rest, _)
      equation
        sl = removeCrefPrefixFromSubModExp(rest, id);
      then
        sm::sl;
  end matchcontinue;
end removeCrefPrefixFromSubModExp;

protected function removeCrefPrefix
  input Absyn.Exp inExp;
  input Absyn.ComponentRef inPrefix;
  output Absyn.Exp outExp;
  output Absyn.ComponentRef outPrefix;
algorithm
  (outExp,outPrefix) := matchcontinue (inExp,inPrefix)
    local
      Absyn.ComponentRef cr, pre;

    case (Absyn.CREF(cr), pre)
      equation
        true = Absyn.crefFirstEqual(cr, pre);
        cr = Absyn.crefStripFirst(cr);
      then
        (Absyn.CREF(cr), pre);

    else (inExp,inPrefix);
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
      list<SCode.SubMod> sl;
      SCode.Final fp;
      SCode.Each ep;
      SourceInfo i;
      Option<Absyn.Exp> binding;

    case (SCode.MOD(fp, ep, sl, binding, i))
      equation
        sl = removeRedeclaresFromSubMod(sl);
      then
        SCode.MOD(fp, ep, sl, binding, i);

    case (SCode.REDECL()) then SCode.NOMOD();

    else inMod;

  end match;
end removeRedeclaresFromMod;

protected function removeRedeclaresFromSubMod
"@author: adrpo
 removes the redeclares from a submod"
  input list<SCode.SubMod> inSl;
  output list<SCode.SubMod> outSl;
algorithm
  outSl := match(inSl)
    local
      String n;
      list<SCode.SubMod> sl,rest;
      SCode.Mod m;
      list<SCode.Subscript> ssl;

    case ({}) then {};

    case (SCode.NAMEMOD(n, m)::rest)
      equation
        m = removeRedeclaresFromMod(m);
        sl = removeRedeclaresFromSubMod(rest);
      then
        SCode.NAMEMOD(n, m)::sl;

  end match;
end removeRedeclaresFromSubMod;


// Modifier hashtable implementation.
protected type Key = Absyn.Path;
protected type Value = Modifier;

protected type ModifierTableFuncs = tuple<FuncHash, FuncKeyEqual, FuncKeyStr, FuncValueStr>;
protected type ModifierTable = tuple<
  array<list<tuple<Key, Integer>>>,
  tuple<Integer, Integer, array<Option<tuple<Key, Value>>>>,
  Integer,
  Integer,
  ModifierTableFuncs
>;

partial function FuncHash
  input Key inKey;
  input Integer inMod;
  output Integer outHash;
end FuncHash;

partial function FuncKeyEqual
  input Key inKey1;
  input Key inKey2;
  output Boolean outEqual;
end FuncKeyEqual;

partial function FuncKeyStr
  input Key inKey;
  output String outString;
end FuncKeyStr;

partial function FuncValueStr
  input Value inValue;
  output String outString;
end FuncValueStr;

protected function hashFunc
  input Key inKey;
  input Integer inMod;
  output Integer outHash;
protected
  String str;
algorithm
  str := Absyn.pathString(inKey);
  outHash := System.stringHashDjb2Mod(str, inMod);
end hashFunc;

protected function emptyModifierTable
  input Integer inModCount;
  output ModifierTable outTable;
protected
  Integer table_size;
algorithm
  table_size := Util.nextPrime(inModCount);
  outTable := BaseHashTable.emptyHashTableWork(table_size,
    (hashFunc, Absyn.pathEqual, Absyn.pathString, printMod));
end emptyModifierTable;

annotation(__OpenModelica_Interface="frontend");
end NFSCodeMod;
