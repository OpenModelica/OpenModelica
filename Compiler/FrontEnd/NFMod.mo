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


encapsulated package NFMod
" file:        NFMod.mo
  package:     NFMod
  description: Modification handling for NFInst.


  Functions for handling modifications, used by NFInst.
  "

public import Absyn;
public import SCode;
public import NFEnv;
public import NFInstTypes;

protected import Debug;
protected import Dump;
protected import Error;
protected import Flags;
protected import List;
protected import NFInstDump;
protected import NFInstPrefix;
protected import SCodeDump;
protected import Util;

public type Binding = NFInstTypes.Binding;
public type Env = NFEnv.Env;
public type Entry = NFEnv.Entry;
public type EntryOrigin = NFEnv.EntryOrigin;
public type Prefix = NFInstTypes.Prefix;
public type Modifier = NFInstTypes.Modifier;
public type ConstrainingClass = NFInstTypes.ConstrainingClass;

public function translateMod
  input SCode.Mod inMod;
  input String inElementName;
  input Integer inDimensions;
  input Env inEnv;
  output Modifier outMod;
protected
  Prefix prefix;
algorithm
  outMod := translateMod2(inMod, inElementName, inDimensions, inEnv);
  prefix := NFEnv.scopePrefix(inEnv);
  outMod := compactMod(outMod, (prefix, inElementName));
end translateMod;

public function translateMod2
  input SCode.Mod inMod;
  input String inElementName;
  input Integer inDimensions;
  input Env inEnv;
  output Modifier outMod;
algorithm
  outMod := match(inMod, inElementName, inDimensions, inEnv)
    local
      SCode.Final fp;
      SCode.Each ep;
      list<SCode.SubMod> submods;
      Option<tuple<Absyn.Exp, Boolean>> binding_exp;
      SourceInfo info;
      list<Modifier> mods;
      Binding binding;
      SCode.Element el;
      SCode.Mod smod;
      Modifier mod;
      SCode.Replaceable repl;
      Option<ConstrainingClass> cc;

    case (SCode.NOMOD(), _, _, _) then NFInstTypes.NOMOD();

    case (SCode.MOD(fp, ep, submods, binding_exp, info), _, _, _)
      equation
        binding = translateBinding(binding_exp, ep, inDimensions, inEnv, info);
        mods = translateSubMods(submods, ep, inDimensions, inEnv);
      then
        NFInstTypes.MODIFIER(inElementName, fp, ep, binding, mods, info);

    case (SCode.REDECL(fp, ep, el), _, _, _)
      equation
        smod = SCode.elementMod(el);
        el = SCode.setElementMod(el, SCode.NOMOD());
        mod = translateMod2(smod, "", inDimensions, inEnv);
        repl = SCode.prefixesReplaceable(SCode.elementPrefixes(el));
        cc = translateConstrainingClass(repl, inEnv);
      then
        NFInstTypes.REDECLARE(fp, ep, el, inEnv, mod, cc);

  end match;
end translateMod2;

protected function translateConstrainingClass
  input SCode.Replaceable inReplaceable;
  input Env inEnv;
  output Option<ConstrainingClass> outConstrainingClass;
algorithm
  outConstrainingClass := match(inReplaceable, inEnv)
    local
      SCode.ConstrainClass cc;
      Absyn.Path path;
      SCode.Mod smod;
      Modifier mod;

    case (SCode.REPLACEABLE(cc = SOME(cc)), _)
      equation
        SCode.CONSTRAINCLASS(constrainingClass = path, modifier = smod) = cc;
        mod = translateMod2(smod, "", 0, inEnv);
      then
        SOME(NFInstTypes.CONSTRAINING_CLASS(path, mod));

    else NONE();

  end match;
end translateConstrainingClass;

protected function translateSubMods
  input list<SCode.SubMod> inSubMods;
  input SCode.Each inEach;
  input Integer inDimensions;
  input Env inEnv;
  output list<Modifier> outSubMods;
protected
  Integer pd;
algorithm
  pd := if SCode.eachBool(inEach) then 0 else inDimensions;
  outSubMods := List.map2(inSubMods, translateSubMod, pd, inEnv);
end translateSubMods;

protected function translateSubMod
  input SCode.SubMod inSubMod;
  input Integer inDimensions;
  input Env inEnv;
  output Modifier outMod;
protected
  String name;
  SCode.Mod mod;
algorithm
  SCode.NAMEMOD(name, mod) := inSubMod;
  outMod := translateMod2(mod, name, inDimensions, inEnv);
end translateSubMod;

protected function translateBinding
  input Option<tuple<Absyn.Exp, Boolean>> inBinding;
  input SCode.Each inEachPrefix;
  input Integer inDimensions;
  input Env inEnv;
  input SourceInfo inInfo;
  output Binding outBinding;
algorithm
  outBinding := match(inBinding, inEachPrefix, inDimensions, inEnv, inInfo)
    local
      Absyn.Exp bind_exp;
      Integer pd;

    // See propagateMod for how this works.
    case (SOME((bind_exp, _)), _, _, _, _)
      equation
        pd = if SCode.eachBool(inEachPrefix) then -1 else inDimensions;
      then
        NFInstTypes.RAW_BINDING(bind_exp, inEnv, pd, inInfo);

    else NFInstTypes.UNBOUND();

  end match;
end translateBinding;

public function addModToEnv
  input Modifier inMod;
  input list<EntryOrigin> inModOrigin;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inMod, inModOrigin, inEnv)
    local
      list<tuple<String, Modifier>> mods;
      Env env;

    case (NFInstTypes.NOMOD(), _, _) then inEnv;

    case (_, _, _)
      equation
        mods = splitMod(inMod);
        env = List.fold1(mods, addModToEnv2, inModOrigin, inEnv);
      then
        env;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFMod.addModToEnv failed on modifier " + printMod(inMod));
      then
        fail();

  end matchcontinue;
end addModToEnv;

protected function addModToEnv2
  input tuple<String, Modifier> inMods;
  input list<EntryOrigin> inModOrigin;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inMods, inModOrigin, inEnv)
    local
      String name;
      Modifier mod;
      Env env;
      Option<Entry> uentry;

    case ((name, mod), _, env)
      equation
        (env, uentry) = NFEnv.updateEntry(name, mod, NFEnv.setEntryModifier, inEnv);
        checkModifiedElement(uentry, name, mod, inModOrigin, inEnv);
      then
        env;

  end match;
end addModToEnv2;

protected function checkModifiedElement
  input Option<Entry> inEntry;
  input String inName;
  input Modifier inModifier;
  input list<EntryOrigin> inModOrigin;
  input Env inEnv;
algorithm
  _ := match(inEntry, inName, inModifier, inModOrigin, inEnv)
    local
      String cls_name;
      SourceInfo info;
      Entry entry;
      SCode.Element el;
      Binding binding;

    case (SOME(entry), _, _, _, _)
      equation
        el = NFEnv.entryElement(entry);
        binding = modifierBinding(inModifier);
        info = modifierInfo(inModifier);
        checkClassModifier(el, binding, inName, info);
      then
        ();

    // The modified element couldn't be found, print an error.
    else
      equation
        cls_name = getModOriginPath(inModOrigin, inEnv);
        info = modifierInfo(inModifier);
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {inName, cls_name}, info);
      then
        fail();

  end match;
end checkModifiedElement;

protected function getModOriginPath
  input list<EntryOrigin> inModOrigin;
  input Env inEnv;
  output String outString;
algorithm
  outString := match(inModOrigin, inEnv)
    local
      Absyn.Path path;

    case (NFInstTypes.INHERITED_ORIGIN(baseClass = path) :: _, _)
      then Absyn.pathString(path);

    else NFEnv.scopeName(inEnv);
  end match;
end getModOriginPath;

protected function checkClassModifier
  "This function checks that a modifier isn't trying to replace a class, i.e.
   c(A = B), where A and B are classes. This should only be allowed if the
   modification is an actual redeclaration."
  input SCode.Element inElement;
  input Binding inBinding;
  input String inName;
  input SourceInfo inInfo;
algorithm
  _ := match(inElement, inBinding, inName, inInfo)

    // The modified element is a class but the modifier has no binding, e.g.
    // c(A(x = 3)). This is ok.
    case (SCode.CLASS(), NFInstTypes.UNBOUND(), _, _)
      then ();

    // The modified element is a class but the modifier has a binding. This is
    // not ok, tell the user that the redeclare keyword is missing.
    case (SCode.CLASS(), _, _, _)
      equation
        Error.addSourceMessage(Error.MISSING_REDECLARE_IN_CLASS_MOD,
          {inName}, inInfo);
      then
        fail();

    // Any other element is ok.
    else ();

  end match;
end checkClassModifier;

public function partitionExtendsMods
  input Env inEnv;
  input Integer inExtendsCount;
  output list<Modifier> outExtendsModifiers;
algorithm
  outExtendsModifiers := match(inEnv, inExtendsCount)
    local
      array<list<Modifier>> ext_mods;

    // No extends, no need to partition modifiers.
    case (_, 0) then {};

    else
      equation
        ext_mods = arrayCreate(inExtendsCount, {});
        ext_mods = NFEnv.foldScope(inEnv, partitionExtendsMods2, ext_mods);
      then
        List.map(arrayList(ext_mods), collapseExtendsMod);

  end match;
end partitionExtendsMods;

protected function partitionExtendsMods2
  input Entry inEntry;
  input array<list<Modifier>> inExtendsModifiers;
  output array<list<Modifier>> outExtendsModifiers;
protected
  Modifier mod;
  list<EntryOrigin> origins;
algorithm
  mod := NFEnv.entryModifier(inEntry);
  origins := NFEnv.entryOrigins(inEntry);
  outExtendsModifiers := partitionExtendsMods3(origins, mod, inExtendsModifiers);
end partitionExtendsMods2;

protected function partitionExtendsMods3
  input list<EntryOrigin> inOrigins;
  input Modifier inModifier;
  input array<list<Modifier>> inExtendsModifiers;
  output array<list<Modifier>> outExtendsModifiers;
algorithm
  outExtendsModifiers := match(inOrigins, inModifier, inExtendsModifiers)
    case (_, NFInstTypes.NOMOD(), _) then inExtendsModifiers;
    else List.fold1(inOrigins, partitionExtendsMods4, inModifier, inExtendsModifiers);
  end match;
end partitionExtendsMods3;

protected function partitionExtendsMods4
  input EntryOrigin inOrigin;
  input Modifier inModifier;
  input array<list<Modifier>> inExtendsModifiers;
  output array<list<Modifier>> outExtendsModifiers;
algorithm
  outExtendsModifiers := match(inOrigin, inModifier, inExtendsModifiers)
    local
      Integer idx;
      list<Modifier> mods;
      array<list<Modifier>> ext_mods;

    case (NFInstTypes.INHERITED_ORIGIN(index = idx), _, _)
      equation
        mods = arrayGet(inExtendsModifiers, idx);
        mods = inModifier :: mods;
        ext_mods = arrayUpdate(inExtendsModifiers, idx, mods);
      then
        ext_mods;

    else inExtendsModifiers;
  end match;
end partitionExtendsMods4;

protected function collapseExtendsMod
  input list<Modifier> inModifiers;
  output Modifier outModifier;
algorithm
  outModifier := match(inModifiers)
    case {} then NFInstTypes.NOMOD();

    else NFInstTypes.MODIFIER("", SCode.NOT_FINAL(), SCode.NOT_EACH(),
      NFInstTypes.UNBOUND(), inModifiers, Absyn.dummyInfo);
  end match;
end collapseExtendsMod;

protected function modifierName
  input Modifier inMod;
  output String outName;
algorithm
  outName := match(inMod)
    local
      String name;
      SCode.Element elem;

    case NFInstTypes.MODIFIER(name = name) then name;
    case NFInstTypes.REDECLARE(element = elem)
      then SCode.elementName(elem);
  end match;
end modifierName;

protected function modifierInfo
  input Modifier inMod;
  output SourceInfo outInfo;
algorithm
  outInfo := match(inMod)
    local
      SourceInfo info;
      SCode.Element elem;

    case NFInstTypes.MODIFIER(info = info) then info;
    case NFInstTypes.REDECLARE(element = elem) then SCode.elementInfo(elem);
    else Absyn.dummyInfo;
  end match;
end modifierInfo;

public function modifierBinding
  input Modifier inModifier;
  output Binding outBinding;
algorithm
  outBinding := match(inModifier)
    local
      Binding binding;

    case NFInstTypes.MODIFIER(binding = binding) then binding;
    else NFInstTypes.UNBOUND();

  end match;
end modifierBinding;

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
      SCode.Element el;
      Env env;
      Modifier mod;
      Option<ConstrainingClass> cc;

    // One of the modifiers is NOMOD, return the other.
    case (NFInstTypes.NOMOD(), _) then inInnerMod;
    case (_, NFInstTypes.NOMOD()) then inOuterMod;

    // Neither of the modifiers have a binding, just merge the submods.
    case (NFInstTypes.MODIFIER(subModifiers = submods1, binding = NFInstTypes.UNBOUND(), info = info1),
          NFInstTypes.MODIFIER(name = name, subModifiers = submods2, binding = NFInstTypes.UNBOUND()))
      equation
        submods1 = List.fold(submods1, mergeSubMod, submods2);
      then
        NFInstTypes.MODIFIER(name, SCode.NOT_FINAL(), SCode.NOT_EACH(),
          NFInstTypes.UNBOUND(), submods1, info1);

    // The outer modifier has a binding which takes priority over the inner
    // modifiers binding.
    case (NFInstTypes.MODIFIER(name, fp, ep, binding as NFInstTypes.RAW_BINDING(),
            submods1, info1),
          NFInstTypes.MODIFIER(subModifiers = submods2, info = info2))
      equation
        checkModifierFinalOverride(name, inOuterMod, info1, inInnerMod, info2);
        submods1 = List.fold(submods1, mergeSubMod, submods2);
      then
        NFInstTypes.MODIFIER(name, fp, ep, binding, submods1, info1);

    // The inner modifier has a binding, but not the outer, so keep it.
    case (NFInstTypes.MODIFIER(subModifiers = submods1, info = info1),
          NFInstTypes.MODIFIER(name, fp, ep, binding as NFInstTypes.RAW_BINDING(),
            submods2, info2))
      equation
        checkModifierFinalOverride(name, inOuterMod, info1, inInnerMod, info2);
        submods2 = List.fold(submods1, mergeSubMod, submods2);
      then
        NFInstTypes.MODIFIER(name, fp, ep, binding, submods2, info1);

    // Both modifiers are redeclares, but the inner does not have a constraining
    // class. Keep only the outer redeclare.
    //case (NFInstTypes.REDECLARE(element = _),
    //      NFInstTypes.REDECLARE(constrainingClass = NONE()))
    //  then inOuterMod;

    case (NFInstTypes.REDECLARE(),NFInstTypes.REDECLARE())
      equation
        // Merge outer modifier with outer constraining class.
        // Merge outer modifier with inner constraining class.
      then
        inOuterMod;

    case (NFInstTypes.MODIFIER(),
      NFInstTypes.REDECLARE(fp, ep, el, env, mod, cc))
      equation
        mod = mergeMod(inOuterMod, mod);
        // Merge outer modifier with inner modifier.
      then
        NFInstTypes.REDECLARE(fp, ep, el, env, mod, cc);

    case (NFInstTypes.REDECLARE(fp, ep, el, env, mod, cc),
          NFInstTypes.MODIFIER())
      equation
        mod = mergeMod(mod, inInnerMod);
      then
        NFInstTypes.REDECLARE(fp, ep, el, env, mod, cc);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"NFInstTypes.mergeMod failed on unknown mod."});
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

    case (_, _, _, NFInstTypes.MODIFIER(finalPrefix = SCode.FINAL()), _)
      equation
        NFInstTypes.RAW_BINDING(bindingExp = oexp) = modifierBinding(inOuterMod);
        oexp_str = Dump.printExpStr(oexp);
        Error.addMultiSourceMessage(Error.FINAL_COMPONENT_OVERRIDE,
          {inName, oexp_str}, {inOuterInfo, inInnerInfo});
      then
        fail();

    else ();
  end match;
end checkModifierFinalOverride;

protected function mergeSubMod
  "Merges a sub modifier into a list of sub modifiers."
  input Modifier inSubMod;
  input list<Modifier> inSubMods;
  output list<Modifier> outSubMods;
algorithm
  outSubMods := match(inSubMod, inSubMods)
    local
      String id;

    case (_, _)
      equation
        id = modifierName(inSubMod);
      then
        mergeSubMod_tail(id, inSubMod, inSubMods, {});

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


    case (_, _, mod :: rest_mods, _)
      equation
        id = modifierName(mod);
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

protected function compactMod
  "This function merges the submodifiers in a modifier so that each submodifier
    only occurs once. Ex:

    compactMod((x.start = 2.0, y = 4.0, x(min = 1.0, max = 3.0))) =>
      (x(start = 2.0, min = 1.0, max = 3.0), y = 4.0)

  "
  input Modifier inModifier;
  input tuple<Prefix, String> inModName "Modifier name for error reporting.";
  output Modifier outModifier;
algorithm
  outModifier := match(inModifier, inModName)
    local
      String name;
      SCode.Final fp;
      SCode.Each ep;
      Binding binding;
      list<Modifier> submods;
      SourceInfo info;

    case (NFInstTypes.MODIFIER(name, fp, ep, binding, submods, info), _)
      equation
        submods = compactSubMods(submods, inModName);
      then
        NFInstTypes.MODIFIER(name, fp, ep, binding, submods, info);

    else inModifier;

  end match;
end compactMod;

protected function compactSubMods
  "Merges a list of modifiers so that each modifier occurs only once in the list."
  input list<Modifier> inSubMods;
  input tuple<Prefix, String> inModName;
  output list<Modifier> outSubMods;
protected
  list<tuple<String, Modifier>> mods;
algorithm
  mods := List.fold1(inSubMods, compactSubMod, inModName, {});
  mods := listReverse(mods);
  outSubMods := List.map(mods, Util.tuple22);
end compactSubMods;

protected function compactSubMod
  "Helper function to compactSubMods. Tries to merge the given modifier with an
   existing modifier in the accumulation list. If a matching modifier is not
   found in the list it's added instead."
  input Modifier inSubMod;
  input tuple<Prefix, String> inModName;
  input list<tuple<String, Modifier>> inAccumMods;
  output list<tuple<String, Modifier>> outSubMods;
algorithm
  outSubMods := match(inSubMod, inModName, inAccumMods)
    local
      String name;
      list<tuple<String, Modifier>> mods;
      Boolean found;

    // Strip out any NOMODs.
    case (NFInstTypes.NOMOD(), _, _) then inAccumMods;

    else
      equation
        name = modifierName(inSubMod);
        // Try to find an existing modifier with the same name and merge the
        // given modifier with it. If not found, add it to the list instead.
        (mods, found) = List.findMap3(inAccumMods, compactSubMod2, name, inSubMod, inModName);
      then
        List.consOnTrue(not found, (name, inSubMod), mods);

  end match;
end compactSubMod;

protected function compactSubMod2
  "Helper function to compactSubMod. Merges the given modifier with the existing
    modifier if they have the same name, otherwise does nothing."
  input tuple<String, Modifier> inExistingMod;
  input String inName;
  input Modifier inNewMod;
  input tuple<Prefix, String> inModName;
  output tuple<String, Modifier> outMod;
  output Boolean outFound;
algorithm
  (outMod, outFound) := matchcontinue(inExistingMod, inName, inNewMod, inModName)
    local
      String name;
      Modifier mod;

    // Names not equal, do nothing.
    case ((name, _), _, _, _)
      equation
        false = stringEqual(name, inName);
      then
        (inExistingMod, false);

    // Names equal, try to merge the modifiers.
    case ((name, mod), _, _, _)
      equation
        mod = mergeModsInSameScope(mod, inNewMod, name, inModName);
      then
        ((name, mod), true);

  end matchcontinue;
end compactSubMod2;

protected function splitMod
  "Splits a modifier into a list of its submodifiers, where each element in the
   list is a tuple of the modifier's name and the modifier itself."
  input Modifier inMod;
  output list<tuple<String, Modifier>> outSubMods;
algorithm
  outSubMods := match(inMod)
    local
      list<Modifier> submods;

    case NFInstTypes.MODIFIER(subModifiers = submods)
      then List.filterMap(submods, splitMod2);

    else {};

  end match;
end splitMod;

protected function splitMod2
  input Modifier inMod;
  output tuple<String, Modifier> outMod;
protected
  String name;
algorithm
  name := modifierName(inMod);
  outMod := (name, inMod);
end splitMod2;

protected function mergeModsInSameScope
  "Merges two modifiers in the same scope, i.e. they have the same priority. It's
   thus an error if the modifiers modify the same element."
  input Modifier inMod1;
  input Modifier inMod2;
  input String inElementName;
  input tuple<Prefix, String> inModName;
  output Modifier outMod;
algorithm
  outMod := match(inMod1, inMod2, inElementName, inModName)
    local
      SCode.Final fp;
      SCode.Each ep;
      list<Modifier> submods1, submods2;
      Binding binding;
      String name, comp_str;
      SourceInfo info1, info2;
      Prefix prefix;

    // The second modifier has no binding, use the binding from the first.
    case (NFInstTypes.MODIFIER(name, fp, ep, binding, submods1, info1),
          NFInstTypes.MODIFIER(subModifiers = submods2, binding = NFInstTypes.UNBOUND()), _, _)
      equation
        submods1 = List.fold2(submods1, mergeSubModInSameScope, inModName,
          inElementName, submods2);
      then
        NFInstTypes.MODIFIER(name, fp, ep, binding, submods1, info1);

    // The first modifier has no binding, use the binding from the second.
    case (NFInstTypes.MODIFIER(subModifiers = submods1, binding = NFInstTypes.UNBOUND()),
          NFInstTypes.MODIFIER(name, fp, ep, binding, submods2, info2), _, _)
      equation
        submods1 = List.fold2(submods1, mergeSubModInSameScope, inModName,
          inElementName, submods2);
      then
        NFInstTypes.MODIFIER(name, fp, ep, binding, submods1, info2);

    // Both modifiers have bindings, show duplicate modification error.
    case (_, _, _, (prefix, comp_str))
      equation
        info1 = modifierInfo(inMod1);
        info2 = modifierInfo(inMod2);
        comp_str = "component " + NFInstPrefix.prefixStr(comp_str, prefix);
        Error.addMultiSourceMessage(Error.DUPLICATE_MODIFICATIONS,
          {inElementName, comp_str}, {info2, info1});
      then
        fail();

  end match;
end mergeModsInSameScope;

protected function mergeSubModInSameScope
  input Modifier inSubMod;
  input tuple<Prefix, String> inModName;
  input String inElementName;
  input list<Modifier> inSubMods;
  output list<Modifier> outSubMods;
protected
  Boolean found;
algorithm
  (outSubMods, found) := List.findMap3(inSubMods, mergeSubModInSameScope2,
    inSubMod, inModName, inElementName);
  outSubMods := List.consOnTrue(not found, inSubMod, outSubMods);
end mergeSubModInSameScope;

protected function mergeSubModInSameScope2
  "Helper function to mergeModsInSameScope. Merges two sub modifiers if they
   have the same name."
  input Modifier inExistingMod;
  input Modifier inNewMod;
  input tuple<Prefix, String> inModName;
  input String inElementName;
  output Modifier outMod;
  output Boolean outFound;
algorithm
  (outMod, outFound) :=
  match(inExistingMod, inNewMod, inModName, inElementName)
    local
      String id1, id2;
      Modifier mod;

    case (NFInstTypes.MODIFIER(name = id1),
          NFInstTypes.MODIFIER(name = id2), _, _)
        guard not stringEq(id1, id2)
      then
        (inExistingMod, false);

    case (NFInstTypes.MODIFIER(name = id1), _, _, _)
      equation
        id1 = inElementName + "." + id1;
        mod = mergeModsInSameScope(inExistingMod, inNewMod, id1, inModName);
      then
        (mod, true);

  end match;
end mergeSubModInSameScope2;

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
      NFInstTypes.Binding binding;
      list<Modifier> submods;
      SourceInfo info;

    case (_, 0) then inModifier;

    case (NFInstTypes.MODIFIER(name, fp, ep, binding, submods, info), _)
      equation
        binding = propagateBinding(binding, inDimensions);
        submods = List.map1(submods, propagateMod, inDimensions);
      then
        NFInstTypes.MODIFIER(name, fp, ep, binding, submods, info);

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
      Integer pd;
      SourceInfo info;

    // Special case for the each prefix, don't do anything.
    case (NFInstTypes.RAW_BINDING(propagatedDims = -1), _) then inBinding;

    // A normal binding, increment with the dimension count.
    case (NFInstTypes.RAW_BINDING(bind_exp, env, pd, info), _)
      equation
        pd = pd + inDimensions;
      then
        NFInstTypes.RAW_BINDING(bind_exp, env, pd, info);

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

    case NFInstTypes.MODIFIER(_, fp, ep, binding, submods, _)
      equation
        fstr = SCodeDump.finalStr(fp);
        estr = SCodeDump.eachStr(ep);
        submod_str = stringDelimitList(List.map(submods, printSubMod), ", ");
        bind_str = NFInstDump.bindingStr(binding);
      then
        "MOD(" + fstr + estr + "{" + submod_str + "})" + bind_str;

    case NFInstTypes.REDECLARE(fp, ep, el, _, _, _)
      equation
        fstr = SCodeDump.finalStr(fp);
        estr = SCodeDump.eachStr(ep);
        el_str = SCodeDump.unparseElementStr(el,SCodeDump.defaultOptions);
      then
        "REDECL(" + fstr + estr + el_str + ")";

    case NFInstTypes.NOMOD() then "NOMOD()";
  end match;
end printMod;

protected function printSubMod
  input Modifier inSubMod;
  output String outString;
algorithm
  outString := match(inSubMod)
    local
      String id;

    case NFInstTypes.MODIFIER(name = id)
      then id + " = " + printMod(inSubMod);

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

    case (SCode.NAMEMOD(mod = SCode.MOD(binding = SOME((e, _))))::rest, _)
      equation
        cl = Absyn.getCrefFromExp(e,true,true);
        true = List.applyAndFold1(cl, boolOr, Absyn.crefFirstEqual, id, false);
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
      Boolean b;

    case (SCode.MOD(fp, ep, sl, SOME((e, b)), i),_)
      equation
        sl = removeCrefPrefixFromSubModExp(sl, id);
        (e, _) = Absyn.traverseExp(e, removeCrefPrefix, id);
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
      Option<String> n;
      list<SCode.SubMod> sl;
      SCode.Final fp;
      SCode.Each ep;
      SourceInfo i;
      Option<tuple<Absyn.Exp, Boolean>> binding;

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

  end match;
end removeRedeclaresFromSubMod;

public function extractRedeclares
  "Returns a list of the redeclare elements contained in the given modifier."
  input SCode.Mod inMod;
  output list<SCode.Element> outRedeclares;
algorithm
  outRedeclares := match(inMod)
    local
      list<SCode.SubMod> sub_mods;
      list<SCode.Element> redeclares;

    case SCode.MOD(subModLst = sub_mods)
      equation
        redeclares = List.fold(sub_mods, extractRedeclareFromSubMod, {});
      then
        redeclares;

    else {};

  end match;
end extractRedeclares;

protected function extractRedeclareFromSubMod
  "Checks a submodifier and adds the redeclare element to the list of redeclares
   if the modifier is a redeclaration modifier."
  input SCode.SubMod inMod;
  input list<SCode.Element> inRedeclares;
  output list<SCode.Element> outRedeclares;
algorithm
  outRedeclares := match(inMod, inRedeclares)
    local
      SCode.Element redecl;

    case (SCode.NAMEMOD(mod = SCode.REDECL(element = redecl)), _)
      equation
        //NFSCodeCheck.checkDuplicateRedeclarations(redecl, inRedeclares);
      then
        redecl :: inRedeclares;

    // Skip modifiers that are not redeclarations.
    else inRedeclares;

  end match;
end extractRedeclareFromSubMod;

annotation(__OpenModelica_Interface="frontend");
end NFMod;
