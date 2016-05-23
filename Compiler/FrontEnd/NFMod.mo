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
    input SCode.Mod inMod;
    input String inElementName;
    //input Integer inDimensions;
    //input ScopeIndex inScope;
    output Modifier outMod;
  algorithm
    outMod := match inMod
      local
        list<Modifier> submods;
        Binding binding;

      case SCode.NOMOD() then NOMOD();

      case SCode.MOD()
        algorithm
          binding := Binding.fromAbsyn(inMod.binding, inMod.finalPrefix,
              inMod.eachPrefix, inMod.info);
          submods := translateSubMods(inMod.subModLst);
        then
          MODIFIER(inElementName, binding, submods, inMod.info);

      case SCode.REDECL()
        then REDECLARE(inMod.finalPrefix, inMod.eachPrefix, inMod.element);

    end match;
  end translate;

  function lookupSub
    input Modifier inModifier;
    input String inName;
    output Modifier outSubMod;
  protected
    list<Modifier> submods;
  algorithm
    submods := subModifiers(inModifier);

    for m in submods loop
      if inName == name(m) then
        outSubMod := m;
        return;
      end if;
    end for;

    outSubMod := EMPTY_MOD;
  end lookupSub;

  function name
    input Modifier inModifier;
    output String outName;
  algorithm
    outName := match inModifier
      case MODIFIER() then inModifier.name;
      case REDECLARE(element = SCode.COMPONENT(name = outName)) then outName;
      case REDECLARE(element = SCode.CLASS(name = outName)) then outName;
    end match;
  end name;

  function binding
    input Modifier inModifier;
    output Binding outBinding;
  algorithm
    outBinding := match inModifier
      case MODIFIER() then inModifier.binding;
      else Binding.UNBOUND();
    end match;
  end binding;

  function subModifiers
    input Modifier inModifier;
    output list<Modifier> outSubMods;
  algorithm
    outSubMods := match inModifier
      case MODIFIER() then inModifier.subModifiers;
      else {};
    end match;
  end subModifiers;

  function merge
    input Modifier inOuterMod;
    input Modifier inInnerMod;
    output Modifier outMod;
  algorithm
    outMod := match(inOuterMod, inInnerMod)
      local
        list<Modifier> submods;
        Binding binding;

      // One of the modifiers is NOMOD, return the other.
      case (NOMOD(), _) then inInnerMod;
      case (_, NOMOD()) then inOuterMod;

      // Two modifiers, merge bindings and submodifiers.
      case (MODIFIER(), MODIFIER())
        algorithm
          checkFinalOverride(inOuterMod.name, inOuterMod.binding,
            inOuterMod.info, inInnerMod.binding, inInnerMod.info);
          binding := if Binding.isBound(inOuterMod.binding) then
            inOuterMod.binding else inInnerMod.binding;
          submods := mergeSubMods(inOuterMod.subModifiers, inInnerMod.subModifiers);
        then
          MODIFIER(inOuterMod.name, binding, submods, inOuterMod.info);

      else
        algorithm
          Error.addMessage(Error.INTERNAL_ERROR,
            {"Mod.mergeMod failed on unknown mod."});
        then
          fail();

    end match;
  end merge;

  function toString
    input Modifier inMod;
    output String outString;
  algorithm
    outString := match inMod
      local
        String subs_str;

      case NOMOD() then "";
      case MODIFIER()
        algorithm
          if not listEmpty(inMod.subModifiers) then
            subs_str := "(" + stringDelimitList(list(toString(s) for s in
              inMod.subModifiers), ", ") + ")";
          else
            subs_str := "";
          end if;
        then
          inMod.name + subs_str + Binding.toString(inMod.binding, " = ");

      case REDECLARE() then "redeclare";
    end match;
  end toString;

protected
  function translateSubMods
    input list<SCode.SubMod> inSubMods;
    //input ScopeIndex inScope;
    output list<Modifier> outSubMods;
  algorithm
    //  pd := if SCode.eachBool(inEach) then 0 else inDimensions;
    outSubMods := list(translateSubMod(m) for m in inSubMods);
  end translateSubMods;

  function translateSubMod
    input SCode.SubMod inSubMod;
    //input ScopeIndex inScope;
    output Modifier outMod;
  protected
    String name;
    SCode.Mod mod;
  algorithm
    SCode.NAMEMOD(name, mod) := inSubMod;
    outMod := translate(mod, name);
  end translateSubMod;

  function checkFinalOverride
    "Checks that a modifier is not trying to override a final modifier. In that
     case it prints an error and fails, otherwise it does nothing."
    input String inName;
    input Binding inOuterBinding;
    input SourceInfo inOuterInfo;
    input Binding inInnerBinding;
    input SourceInfo inInnerInfo;
  algorithm
    _ := match (inOuterBinding, inInnerBinding)
      case (Binding.RAW_BINDING(), Binding.RAW_BINDING(finalPrefix = SCode.FINAL()))
        algorithm
          Error.addMultiSourceMessage(Error.FINAL_COMPONENT_OVERRIDE,
            {inName, Dump.printExpStr(inOuterBinding.bindingExp)},
            {inOuterInfo, inInnerInfo});
        then
          fail();

      else ();
    end match;
  end checkFinalOverride;

  function mergeSubMods
    input list<Modifier> inOuterSubMods;
    input list<Modifier> inInnerSubMods;
    output list<Modifier> outSubMods;
  algorithm
    outSubMods := List.fold(inOuterSubMods, mergeSubMod, inInnerSubMods);
  end mergeSubMods;

  function mergeSubMod
    input Modifier inSubMod;
    input list<Modifier> inSubMods;
    output list<Modifier> outSubMods = {};
  protected
    String id;
    Modifier mod;
    list<Modifier> rest_mods = inSubMods;
  algorithm
    id := name(inSubMod);

    // Try to find a modifier with the same name.
    while not listEmpty(rest_mods) loop
      mod :: rest_mods := rest_mods;

      // Matching modifier found, merge them and return.
      if name(mod) == id then
        mod := merge(inSubMod, mod);
        outSubMods := listAppend(listReverse(mod :: outSubMods), rest_mods);
        return;
      end if;

      outSubMods := mod :: outSubMods;
    end while;

    // No matching modifier found, add the new one to the list.
    outSubMods := listReverse(inSubMod :: outSubMods);
  end mergeSubMod;
end Modifier;

annotation(__OpenModelica_Interface="frontend");
end NFMod;
