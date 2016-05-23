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

public
import NFBinding.Binding;
//import NFEnvScope.{ScopeIndex};
import SCode;

protected
import Dump;
import Error;
import List;

constant Modifier EMPTY_MOD = NOMOD();

public
uniontype Modifier
  record MODIFIER
    String name;
    Binding binding;
    // TODO: AvlTree?
    list<Modifier> subModifiers;
    SourceInfo info;
  end MODIFIER;

  record REDECLARE
    SCode.Final finalPrefix;
    SCode.Each eachPrefix;
    SCode.Element element;
  end REDECLARE;

  record NOMOD end NOMOD;

public
  function translate
    input SCode.Mod mod;
    input String elementName;
    //input Integer inDimensions;
    //input ScopeIndex inScope;
    output Modifier translatedMod;
  algorithm
    translatedMod := match mod
      local
        list<Modifier> submods;
        Binding binding;

      case SCode.NOMOD() then NOMOD();

      case SCode.MOD()
        algorithm
          binding := Binding.fromAbsyn(mod.binding, mod.finalPrefix,
              mod.eachPrefix, mod.info);
          submods := translateSubMods(mod.subModLst);
        then
          MODIFIER(elementName, binding, submods, mod.info);

      case SCode.REDECL()
        then REDECLARE(mod.finalPrefix, mod.eachPrefix, mod.element);

    end match;
  end translate;

  function lookupSub
    input Modifier modifier;
    input String modName;
    output Modifier subMod;
  protected
    list<Modifier> submods;
  algorithm
    submods := subModifiers(modifier);

    for m in submods loop
      if modName == name(m) then
        subMod := m;
        return;
      end if;
    end for;

    subMod := EMPTY_MOD;
  end lookupSub;

  function name
    input Modifier modifier;
    output String name;
  algorithm
    name := match modifier
      case MODIFIER() then modifier.name;
      case REDECLARE(element = SCode.COMPONENT(name = name)) then name;
      case REDECLARE(element = SCode.CLASS(name = name)) then name;
    end match;
  end name;

  function binding
    input Modifier modifier;
    output Binding binding;
  algorithm
    binding := match modifier
      case MODIFIER() then modifier.binding;
      else Binding.UNBOUND();
    end match;
  end binding;

  function subModifiers
    input Modifier modifier;
    output list<Modifier> subMods;
  algorithm
    subMods := match modifier
      case MODIFIER() then modifier.subModifiers;
      else {};
    end match;
  end subModifiers;

  function merge
    input Modifier outerMod;
    input Modifier innerMod;
    output Modifier mergedMod;
  algorithm
    mergedMod := match(outerMod, innerMod)
      local
        list<Modifier> submods;
        Binding binding;

      // One of the modifiers is NOMOD, return the other.
      case (NOMOD(), _) then innerMod;
      case (_, NOMOD()) then outerMod;

      // Two modifiers, merge bindings and submodifiers.
      case (MODIFIER(), MODIFIER())
        algorithm
          checkFinalOverride(outerMod.name, outerMod.binding,
            outerMod.info, innerMod.binding, innerMod.info);
          binding := if Binding.isBound(outerMod.binding) then
            outerMod.binding else innerMod.binding;
          submods := mergeSubMods(outerMod.subModifiers, innerMod.subModifiers);
        then
          MODIFIER(outerMod.name, binding, submods, outerMod.info);

      else
        algorithm
          Error.addMessage(Error.INTERNAL_ERROR,
            {"Mod.mergeMod failed on unknown mod."});
        then
          fail();

    end match;
  end merge;

  function toString
    input Modifier mod;
    output String string;
  algorithm
    string := match mod
      local
        String subs_str;

      case NOMOD() then "";
      case MODIFIER()
        algorithm
          if not listEmpty(mod.subModifiers) then
            subs_str := "(" + stringDelimitList(list(toString(s) for s in
              mod.subModifiers), ", ") + ")";
          else
            subs_str := "";
          end if;
        then
          mod.name + subs_str + Binding.toString(mod.binding, " = ");

      case REDECLARE() then "redeclare";
    end match;
  end toString;

protected
  function translateSubMods
    input list<SCode.SubMod> subMods;
    //input ScopeIndex inScope;
    output list<Modifier> translatedSubMods;
  algorithm
    //  pd := if SCode.eachBool(inEach) then 0 else inDimensions;
    translatedSubMods := list(translateSubMod(m) for m in subMods);
  end translateSubMods;

  function translateSubMod
    input SCode.SubMod subMod;
    //input ScopeIndex inScope;
    output Modifier mod = translate(subMod.mod, subMod.ident);
  end translateSubMod;

  function checkFinalOverride
    "Checks that a modifier is not trying to override a final modifier. In that
     case it prints an error and fails, otherwise it does nothing."
    input String name;
    input Binding outerBinding;
    input SourceInfo outerInfo;
    input Binding innerBinding;
    input SourceInfo innerInfo;
  algorithm
    _ := match (outerBinding, innerBinding)
      case (Binding.RAW_BINDING(), Binding.RAW_BINDING(finalPrefix = SCode.FINAL()))
        algorithm
          Error.addMultiSourceMessage(Error.FINAL_COMPONENT_OVERRIDE,
            {name, Dump.printExpStr(outerBinding.bindingExp)},
            {outerInfo, innerInfo});
        then
          fail();

      else ();
    end match;
  end checkFinalOverride;

  function mergeSubMods
    input list<Modifier> outerSubMods;
    input list<Modifier> innerSubMods;
    output list<Modifier> subMods;
  algorithm
    subMods := List.fold(outerSubMods, mergeSubMod, innerSubMods);
  end mergeSubMods;

  function mergeSubMod
    input Modifier subMod;
    input list<Modifier> subMods;
    output list<Modifier> mergedSubMods = {};
  protected
    String id;
    Modifier mod;
    list<Modifier> rest_mods = subMods;
  algorithm
    id := name(subMod);

    // Try to find a modifier with the same name.
    while not listEmpty(rest_mods) loop
      mod :: rest_mods := rest_mods;

      // Matching modifier found, merge them and return.
      if name(mod) == id then
        mod := merge(subMod, mod);
        mergedSubMods := listAppend(listReverse(mod :: mergedSubMods), rest_mods);
        return;
      end if;

      mergedSubMods := mod :: mergedSubMods;
    end while;

    // No matching modifier found, add the new one to the list.
    mergedSubMods := listReverse(subMod :: mergedSubMods);
  end mergeSubMod;
end Modifier;

annotation(__OpenModelica_Interface="frontend");
end NFMod;
