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


encapsulated package NFModifier
" file:        NFModifier.mo
  package:     NFModifier
  description: Modification handling for NFInst.


  Functions for handling modifications, used by NFInst.
  "

public
import Absyn;
import BaseAvlTree;
import NFBinding.Binding;
import NFComponent.Component;
import NFInstNode.InstNode;
import SCode;
import Inst = NFInst;

protected
import Error;
import List;

constant Modifier EMPTY_MOD = NOMOD();

public
encapsulated package ModTable
  import BaseAvlTree;
  import NFModifier.Modifier;
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

  record COMPONENT
    String name;
  end COMPONENT;

  record CLASS
    String name;
  end CLASS;

  record EXTENDS
    Absyn.Path path;
  end EXTENDS;

  function fromElement
    input SCode.Element element;
    output ModifierScope scope;
  algorithm
    scope := match element
      case SCode.Element.COMPONENT() then COMPONENT(element.name);
      case SCode.Element.CLASS() then CLASS(element.name);
      case SCode.Element.EXTENDS() then EXTENDS(element.baseClassPath);
    end match;
  end fromElement;

  function name
    input ModifierScope scope;
    output String name;
  algorithm
    name := match scope
      case COMPONENT() then scope.name;
      case CLASS() then scope.name;
      case EXTENDS() then Absyn.pathString(scope.path);
    end match;
  end name;

  function toString
    input ModifierScope scope;
    output String string;
  algorithm
    string := match scope
      case COMPONENT() then "component " + scope.name;
      case CLASS() then "class " + scope.name;
      case EXTENDS() then "extends " + Absyn.pathString(scope.path);
    end match;
  end toString;
end ModifierScope;

uniontype Modifier
  record MODIFIER
    String name;
    SCode.Final finalPrefix;
    SCode.Each eachPrefix;
    Binding binding;
    ModTable.Tree subModifiers;
    SourceInfo info;
  end MODIFIER;

  record REDECLARE
    SCode.Final finalPrefix;
    SCode.Each eachPrefix;
    InstNode element;
    Modifier mod;
  end REDECLARE;

  record NOMOD end NOMOD;

public
  function create
    input SCode.Mod mod;
    input String name;
    input ModifierScope modScope;
    input list<InstNode> parents;
    input InstNode scope;
    output Modifier newMod;
  algorithm
    newMod := match mod
      local
        list<tuple<String, Modifier>> submod_lst;
        ModTable.Tree submod_table;
        Binding binding;
        SCode.Element elem;
        SCode.Mod smod;
        Boolean is_each;
        InstNode node;
        list<InstNode> pars;

      case SCode.NOMOD() then NOMOD();

      case SCode.MOD()
        algorithm
          is_each := SCode.eachBool(mod.eachPrefix);
          binding := Binding.fromAbsyn(mod.binding, is_each, parents, scope, mod.info);
          pars := if is_each then {} else parents;
          submod_lst := list((m.ident, createSubMod(m, modScope, pars, scope)) for m in mod.subModLst);
          submod_table := ModTable.fromList(submod_lst,
            function mergeLocal(scope = modScope, prefix = {}));
        then
          MODIFIER(name, mod.finalPrefix, mod.eachPrefix, binding, submod_table, mod.info);

      case SCode.REDECL(element = elem)
        algorithm
          node := InstNode.new(elem, scope);

          if InstNode.isClass(node) then
            Inst.partialInstClass(node);
          end if;
        then
          REDECLARE(mod.finalPrefix, mod.eachPrefix, node, NOMOD());

    end match;
  end create;

  function stripSCodeMod
    input output SCode.Element elem;
          output SCode.Mod mod;
  algorithm
    mod := match elem
      local
        SCode.ClassDef cdef;

      case SCode.Element.CLASS(classDef = cdef as SCode.ClassDef.DERIVED(modifications = mod))
        algorithm
          if not SCode.isEmptyMod(mod) then
            cdef.modifications := SCode.Mod.NOMOD();
            elem.classDef := cdef;
          end if;
        then
          mod;

      case SCode.Element.COMPONENT(modifications = mod)
        algorithm
          if not SCode.isEmptyMod(mod) then
            elem.modifications := SCode.Mod.NOMOD();
          end if;
        then
          mod;

      else SCode.Mod.NOMOD();
    end match;
  end stripSCodeMod;

  function fromElement
    input SCode.Element element;
    input list<InstNode> parents;
    input InstNode scope;
    output Modifier mod;
  algorithm
    mod := match element
      local
        SCode.ClassDef def;
        SCode.Mod smod;

      case SCode.EXTENDS()
        then create(element.modifications, "", ModifierScope.EXTENDS(element.baseClassPath), parents, scope);

      case SCode.COMPONENT()
        algorithm
          smod := patchElementModFinal(element.prefixes, element.info, element.modifications);
        then
          create(smod, element.name, ModifierScope.COMPONENT(element.name), parents, scope);

      case SCode.CLASS(classDef = def as SCode.DERIVED())
        then create(def.modifications, element.name, ModifierScope.CLASS(element.name), parents, scope);

      case SCode.CLASS(classDef = def as SCode.CLASS_EXTENDS())
        then create(def.modifications, element.name, ModifierScope.CLASS(element.name), parents, scope);

      else NOMOD();
    end match;
  end fromElement;

  function patchElementModFinal
    // TODO: This would be cheaper to do in SCodeUtil when creating the
    //       modifiers, but it breaks the old instantiation.
    "This function makes modifiers applied to final elements final, e.g. for
     'final Real x(start = 1.0)' it will mark '(start = 1.0)' as final. This is
     done so that we only need to check for final violations while merging
     modifiers."
    input SCode.Prefixes prefixes;
    input SourceInfo info;
    input output SCode.Mod mod;
  algorithm
    if SCode.finalBool(SCode.prefixesFinal(prefixes)) then
      mod := match mod
        case SCode.Mod.MOD()
          algorithm
            mod.finalPrefix := SCode.Final.FINAL();
          then
            mod;

        case SCode.Mod.REDECL()
          algorithm
            mod.finalPrefix := SCode.Final.FINAL();
          then
            mod;

        else SCode.Mod.MOD(SCode.Final.FINAL(), SCode.Each.NOT_EACH(), {}, NONE(), info);
      end match;
    end if;
  end patchElementModFinal;

  function addParent
    input InstNode parent;
    input Modifier mod;
    output Modifier outMod;
  algorithm
    outMod := match mod
      local
        Binding binding;

      case MODIFIER(binding = binding)
        algorithm
          mod.binding := Binding.addParent(parent, binding);
        then
          map(mod, function addParent_work(parent = parent));

      else mod;
    end match;
  end addParent;

  function addParent_work
    input String name;
    input InstNode parent;
    input Modifier mod;
    output Modifier outMod;
  algorithm
    outMod := match mod
      local
        Binding binding;

      case MODIFIER(binding = binding)
        algorithm
          mod.binding := Binding.addParent(parent, binding);
        then
          if not Binding.isEach(binding) then
            map(mod, function addParent_work(parent = parent))
          else
            mod;

      else mod;
    end match;
  end addParent_work;

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
      case REDECLARE() then InstNode.name(modifier.element);
    end match;
  end name;

  function info
    input Modifier modifier;
    output SourceInfo info;
  algorithm
    info := match modifier
      case MODIFIER() then modifier.info;
      case REDECLARE() then InstNode.info(modifier.element);
      else Absyn.dummyInfo;
    end match;
  end info;

  function hasBinding
    input Modifier modifier;
    output Boolean hasBinding;
  algorithm
    hasBinding := match modifier
      case MODIFIER() then Binding.isBound(modifier.binding);
      else false;
    end match;
  end hasBinding;

  function binding
    input Modifier modifier;
    output Binding binding;
  algorithm
    binding := match modifier
      case MODIFIER() then modifier.binding;
      else NFBinding.EMPTY_BINDING;
    end match;
  end binding;

  function setBinding
    input Binding binding;
    input output Modifier modifier;
  algorithm
    () := match modifier
      case MODIFIER()
        algorithm
          modifier.binding := binding;
        then
          ();
    end match;
  end setBinding;

  function merge
    input Modifier outerMod;
    input Modifier innerMod;
    input String name = "";
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
          checkFinalOverride(innerMod.finalPrefix, outerMod, innerMod.info);
          binding := if Binding.isBound(outerMod.binding) then
            outerMod.binding else innerMod.binding;
          submods := ModTable.join(innerMod.subModifiers, outerMod.subModifiers, merge);
        then
          MODIFIER(outerMod.name, outerMod.finalPrefix, outerMod.eachPrefix, binding, submods, outerMod.info);

      case (REDECLARE(), MODIFIER())
        algorithm
          outerMod.mod := merge(outerMod.mod, innerMod);
        then
          outerMod;

      case (MODIFIER(), REDECLARE())
        algorithm
          innerMod.mod := merge(outerMod, innerMod.mod);
        then
          innerMod;

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

  function isRedeclare
    input Modifier mod;
    output Boolean isRedeclare;
  algorithm
    isRedeclare := match mod
      case REDECLARE() then true;
      else false;
    end match;
  end isRedeclare;

  function toList
    input Modifier mod;
    output list<Modifier> modList;
  algorithm
    modList := match mod
      case MODIFIER() then ModTable.listValues(mod.subModifiers);
      else {};
    end match;
  end toList;

  function isEach
    input Modifier mod;
    output Boolean isEach;
  algorithm
    isEach := match mod
      case MODIFIER(eachPrefix = SCode.EACH()) then true;
      else false;
    end match;
  end isEach;

  function isFinal
    input Modifier mod;
    output Boolean isFinal;
  algorithm
    isFinal := match mod
      case MODIFIER(finalPrefix = SCode.FINAL()) then true;
      else false;
    end match;
  end isFinal;

  function map
    input output Modifier mod;
    input FuncT func;

    partial function FuncT
      input String name;
      input output Modifier submod;
    end FuncT;
  algorithm
    () := match mod
      case MODIFIER()
        algorithm
          mod.subModifiers := ModTable.map(mod.subModifiers, func);
        then
          ();

      else ();
    end match;
  end map;

  function toString
    input Modifier mod;
    input Boolean printName = true;
    output String string;
  algorithm
    string := match mod
      local
        list<Modifier> submods;
        String subs_str, binding_str, binding_sep;

      case MODIFIER()
        algorithm
          submods := ModTable.listValues(mod.subModifiers);
          if not listEmpty(submods) then
            subs_str := "(" + stringDelimitList(list(toString(s) for s in submods), ", ") + ")";
            binding_sep := " = ";
          else
            subs_str := "";
            binding_sep := if printName then " = " else "= ";
          end if;

          binding_str := Binding.toString(mod.binding, binding_sep);
        then
          if printName then mod.name + subs_str + binding_str else subs_str + binding_str;

      case REDECLARE() then InstNode.toString(mod.element);
      else "";
    end match;
  end toString;

protected
  function createSubMod
    input SCode.SubMod subMod;
    input ModifierScope modScope;
    input list<InstNode> parents;
    input InstNode scope;
    output Modifier mod = create(subMod.mod, subMod.ident, modScope, parents, scope);
  end createSubMod;

  function checkFinalOverride
    "Checks that a modifier is not trying to override a final modifier. In that
     case it prints an error and fails, otherwise it does nothing."
    input SCode.Final innerFinal;
    input Modifier outerMod;
    input SourceInfo innerInfo;
  algorithm
    _ := match innerFinal
      case SCode.FINAL()
        algorithm
          Error.addMultiSourceMessage(Error.FINAL_COMPONENT_OVERRIDE,
            {name(outerMod), Modifier.toString(outerMod, printName = false)},
            {info(outerMod), innerInfo});
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
    input String name = "";
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

      // Both modifiers modify the same element, give duplicate modification error.
      else
        algorithm
          comp_name := stringDelimitList(listReverse(Modifier.name(mod1) :: prefix), ".");
          Error.addMultiSourceMessage(Error.DUPLICATE_MODIFICATIONS,
            {comp_name, ModifierScope.toString(scope)},
            {Modifier.info(mod1), Modifier.info(mod2)});
        then
          fail();

    end match;
  end mergeLocal;
end Modifier;

annotation(__OpenModelica_Interface="frontend");
end NFModifier;
