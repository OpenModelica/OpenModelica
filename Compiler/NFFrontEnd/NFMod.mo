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
import BaseAvlTree;
import NFBinding.Binding;
import SCode;

protected
import Dump;
import Error;
import List;

constant Modifier EMPTY_MOD = NOMOD();

public
encapsulated package ModTable
  import BaseAvlTree;
  import NFMod.Modifier;
  extends BaseAvlTree(redeclare type Key = String,
                      redeclare type Value = Modifier);

  redeclare function extends keyStr
  algorithm
    outString := inKey;
  end keyStr;

  redeclare function extends valueStr
  algorithm
    outString := Modifier.toString(inValue);
  end valueStr;

  redeclare function extends keyCompare
  algorithm
    outResult := stringCompare(inKey1, inKey2);
  end keyCompare;
  annotation(__OpenModelica_Interface="util");
end ModTable;

public
uniontype ModifierScope
  "Structure that represents where a modifier comes from."

  record COMPONENT_SCOPE
    String name;
  end COMPONENT_SCOPE;

  record CLASS_SCOPE
    String name;
  end CLASS_SCOPE;

  record EXTENDS_SCOPE
    Absyn.Path path;
  end EXTENDS_SCOPE;

  function toString
    input ModifierScope scope;
    output String string;
  algorithm
    string := match scope
      case COMPONENT_SCOPE() then "component " + scope.name;
      case CLASS_SCOPE() then "class " + scope.name;
      case EXTENDS_SCOPE() then "extends " + Absyn.pathString(scope.path);
    end match;
  end toString;
end ModifierScope;

uniontype Modifier
  record MODIFIER
    String name;
    Binding binding;
    ModTable.Tree subModifiers;
    SourceInfo info;
  end MODIFIER;

  record REDECLARE
    SCode.Final finalPrefix;
    SCode.Each eachPrefix;
    SCode.Element element;
    Integer scope;
  end REDECLARE;

  record NOMOD end NOMOD;

public
  function create
    input SCode.Mod mod;
    input String name;
    input ModifierScope modScope;
    //input Integer dimensions;
    input Integer scope;
    output Modifier newMod;
  algorithm
    newMod := match mod
      local
        list<tuple<String, Modifier>> submod_lst;
        ModTable.Tree submod_table;
        Binding binding;

      case SCode.NOMOD() then NOMOD();

      case SCode.MOD()
        algorithm
          binding := Binding.fromAbsyn(mod.binding, mod.finalPrefix,
            mod.eachPrefix, scope, mod.info);
          submod_lst := list((m.ident, createSubMod(m, scope, modScope)) for m in mod.subModLst);
          submod_table := ModTable.fromList(submod_lst,
            function mergeLocal(scope = modScope, prefix = {}));
        then
          MODIFIER(name, binding, submod_table, mod.info);

      case SCode.REDECL()
        then REDECLARE(mod.finalPrefix, mod.eachPrefix, mod.element, scope);

    end match;
  end create;

  function lookupModifier
    input String modName;
    input Modifier modifier;
    output Modifier subMod;
  algorithm
    subMod := matchcontinue modifier
      case MODIFIER() then ModTable.get(modifier.subModifiers, modName);
      else EMPTY_MOD;
    end matchcontinue;
  end lookupModifier;

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

  function merge
    input Modifier outerMod;
    input Modifier innerMod;
    output Modifier mergedMod;
  algorithm
    mergedMod := match(outerMod, innerMod)
      local
        ModTable.Tree submods;
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
          submods := ModTable.join(innerMod.subModifiers, outerMod.subModifiers, merge);
        then
          MODIFIER(outerMod.name, binding, submods, outerMod.info);

      case (REDECLARE(), _) then outerMod;
      case (_, REDECLARE()) then innerMod;

      else
        algorithm
          Error.addMessage(Error.INTERNAL_ERROR,
            {"Mod.mergeMod failed on unknown mod."});
        then
          fail();

    end match;
  end merge;

  function isEmpty
    input Modifier mod;
    output Boolean isEmpty;
  algorithm
    isEmpty := match mod
      case NOMOD() then true;
      else false;
    end match;
  end isEmpty;

  function toList
    input Modifier mod;
    output list<Modifier> modList;
  algorithm
    modList := match mod
      case MODIFIER() then ModTable.listValues(mod.subModifiers);
      else {};
    end match;
  end toList;

  function toString
    input Modifier mod;
    output String string;
  algorithm
    string := match mod
      local
        list<Modifier> submods;
        String subs_str;

      case NOMOD() then "";
      case MODIFIER()
        algorithm
          submods := ModTable.listValues(mod.subModifiers);
          if not listEmpty(submods) then
            subs_str := "(" + stringDelimitList(list(toString(s) for s in submods), ", ") + ")";
          else
            subs_str := "";
          end if;
        then
          mod.name + subs_str + Binding.toString(mod.binding, " = ");

      case REDECLARE() then "redeclare";
    end match;
  end toString;

protected
  function createSubMod
    input SCode.SubMod subMod;
    input Integer scope;
    input ModifierScope modScope;
    output Modifier mod = create(subMod.mod, subMod.ident, modScope, scope);
  end createSubMod;

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

  function mergeLocal
    "Merges two modifiers in the same scope, i.e. like a(x(y = 1), x(z = 2)).
     This is allowed as long as the two modifiers doesn't modify the same
     element, otherwise it's an error."
    input Modifier mod1;
    input Modifier mod2;
    input ModifierScope scope;
    input list<String> prefix = {};
    output Modifier mod;
  protected
    String comp_name;
  algorithm
    mod := match (mod1, mod2)
      // The second modifier has no binding, use the binding from the first.
      case (MODIFIER(), MODIFIER(binding = Binding.UNBOUND()))
        algorithm
          mod1.subModifiers := ModTable.join(mod1.subModifiers, mod2.subModifiers,
            function mergeLocal(scope = scope, prefix = mod1.name :: prefix));
        then
          mod1;

      // The first modifier has no binding, use the binding from the second.
      case (MODIFIER(binding = Binding.UNBOUND()), MODIFIER())
        algorithm
          mod2.subModifiers := ModTable.join(mod2.subModifiers, mod1.subModifiers,
            function mergeLocal(scope = scope, prefix = mod1.name :: prefix));
        then
          mod2;

      // Both modifiers have bindings, give duplicate modification error.
      case (MODIFIER(), MODIFIER())
        algorithm
          comp_name := stringDelimitList(listReverse(mod1.name :: prefix), ".");
          Error.addMultiSourceMessage(Error.DUPLICATE_MODIFICATIONS,
            {comp_name, ModifierScope.toString(scope)}, {mod1.info, mod2.info});
        then
          fail();

    end match;
  end mergeLocal;
end Modifier;

annotation(__OpenModelica_Interface="frontend");
end NFMod;
