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

encapsulated package InteractiveUtil
" file:        InteractiveUtil.mo
  package:     InteractiveUtil
  description: This module contain functionality for model management,
               expression evaluation, etc. in the interactive environment.

  $Id: InteractiveUtil.mo 25580 2015-04-16 14:04:16Z jansilar $

  This module contains utility functions for Interactive.mo"

//public imports
import Absyn;
import AbsynToSCode;
import AbsynUtil;
import ConnectionGraph;
import DAE;
import FCore;
import Interactive;
import Interactive.Access;
import SCode;

// protected imports
protected

import Ceval;
import ClassInf;
import Config;
import DAE.Connect;
import DAEUtil;
import DoubleEnded;
import Dump;
import Error;
import ErrorExt;
import ExpressionDump;
import ExpressionSimplify;
import FBuiltin;
import FGraph;
import Flags;
import FlagsUtil;
import InnerOuter;
import Inst;
import InstTypes;
import List;
import Lookup;
import Mod;
import NFApi;
import Parser;
import Print;
import SCodeUtil;
import StaticScript;
import StringUtil;
import SymbolTable;
import System;
import UnitAbsyn;
import UnorderedSet;
import UnorderedMap;
import Util;

import MetaModelica.Dangerous;

public
type GraphicEnvCache = Interactive.GraphicEnvCache;
type AnnotationType = Interactive.AnnotationType;

type Visibility = enumeration(PUBLIC, PROTECTED, ANY);

public function getExtendsElementspecInClass
"Retrieve all ElementSpec of a class that are EXTENDS."
  input Absyn.Class inClass;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm
  outAbsynElementSpecLst:=
  matchcontinue (inClass)
    local
      list<Absyn.ElementSpec> ext;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementArg> eltArg;
      Absyn.Path tp;
    /* a class with parts */
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation
        ext = getExtendsElementspecInClassparts(parts);
      then
        ext;
    /* adrpo: handle also model extends M end M; */
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)))
      equation
        ext = getExtendsElementspecInClassparts(parts);
      then
        ext;
    /* a derived class */
    case (Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH(tp,_), arguments=eltArg)))
      then
        {Absyn.EXTENDS(tp,eltArg,NONE())};
        // Note: the array dimensions of DERIVED are lost. They must be
        // queried by another api-function
    else {};
  end matchcontinue;
end getExtendsElementspecInClass;

protected function getExtendsElementspecInClassparts
"Helper function to getExtendsElementspecInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm
  outAbsynElementSpecLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ElementSpec> lst1,lst2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
      Absyn.ClassPart elt;

    case ({}) then {};

    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation
        lst1 = getExtendsElementspecInClassparts(rest);
        lst2 = getExtendsElementspecInElementitems(elts);
        res = listAppend(lst1, lst2);
      then
        res;

    case ((Absyn.PROTECTED(contents = elts) :: rest))
      equation
        lst1 = getExtendsElementspecInClassparts(rest);
        lst2 = getExtendsElementspecInElementitems(elts);
        res = listAppend(lst1, lst2);
      then
        res;

    case ((_ :: rest))
      equation
        res = getExtendsElementspecInClassparts(rest);
      then
        res;

  end matchcontinue;
end getExtendsElementspecInClassparts;

protected function getExtendsElementspecInElementitems
"Helper function to getExtendsElementspecInClassparts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm
  outAbsynElementSpecLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      Absyn.Element el;
      Absyn.ElementSpec elt;
      list<Absyn.ElementSpec> res;
      list<Absyn.ElementItem> rest;
    case ({}) then {};
    case ((Absyn.ELEMENTITEM(element = el) :: rest))
      equation
        elt = getExtendsElementspecInElement(el) "Bug in MetaModelica Compiler (MMC). If the two premisses below are in swapped order
    the compiler enters infinite loop (but no stack overflow)" ;
        res = getExtendsElementspecInElementitems(rest);
      then
        (elt :: res);
    case ((_ :: rest))
      equation
        res = getExtendsElementspecInElementitems(rest);
      then
        res;
  end matchcontinue;
end getExtendsElementspecInElementitems;

protected function getExtendsElementspecInElement
"Helper function to getExtendsElementspecInElementitems."
  input Absyn.Element inElement;
  output Absyn.ElementSpec outElementSpec;
algorithm
  outElementSpec:=
  match (inElement)
    local Absyn.ElementSpec ext;
    case (Absyn.ELEMENT(specification = (ext as Absyn.EXTENDS()))) then ext;
  end match;
end getExtendsElementspecInElement;

public function removeElementModifiers
  "Removes all the modifiers of a component."
  input Absyn.Path path;
  input String inComponentName;
  input Absyn.Program inProgram;
  input Boolean keepRedeclares;
  output Absyn.Program outProgram;
  output Boolean outResult;
protected
  Absyn.Within within_;
  Absyn.Class cls;
algorithm
  try
    within_ := buildWithin(path);
    cls := getPathedClassInProgram(path, inProgram);
    cls := clearComponentModifiersInClass(cls, inComponentName, keepRedeclares);
    outProgram := updateProgram(Absyn.PROGRAM({cls}, within_), inProgram);
    outResult := true;
  else
    outProgram := inProgram;
    outResult := false;
  end try;
end removeElementModifiers;

public function clearComponentModifiersInClass
  input Absyn.Class inClass;
  input String inComponentName;
  input Boolean keepRedeclares;
  output Absyn.Class outClass = inClass;
algorithm
  (outClass, true) := AbsynUtil.traverseClassComponents(inClass,
    function clearComponentModifiersInCompitems(inComponentName =
      inComponentName, keepRedeclares = keepRedeclares), false);
end clearComponentModifiersInClass;

protected function clearComponentModifiersInCompitems
  "Helper function to clearComponentModifiersInClass. Clears the modifiers in a ComponentItem."
  input list<Absyn.ComponentItem> inComponents;
  input Boolean inFound;
  input String inComponentName;
  input Boolean keepRedeclares = false;
  output list<Absyn.ComponentItem> outComponents = {};
  output Boolean outFound;
  output Boolean outContinue;
protected
  Absyn.ComponentItem item;
  list<Absyn.ComponentItem> rest_items = inComponents;
  Absyn.Component comp;
  list<Absyn.ElementArg> args_old, args_new;
  Absyn.EqMod eqmod_old, eqmod_new;
algorithm
  // Try to find the component we're looking for.
  while not listEmpty(rest_items) loop
    item :: rest_items := rest_items;

    if AbsynUtil.componentName(item) == inComponentName then
      // Found component, propagate the modifier to it.
      _ := match item
        case Absyn.COMPONENTITEM(component = comp as Absyn.COMPONENT())
          algorithm
            comp.modification := if not keepRedeclares then NONE() else stripModifiersKeepRedeclares(comp.modification);
            item.component := comp;
          then
            ();
      end match;

      // Reassemble the item list and return.
      outComponents := List.append_reverse(outComponents, item :: rest_items);
      outFound := true;
      outContinue := false;
      return;
    end if;
    outComponents := item :: outComponents;
  end while;

  // Component not found, continue looking.
  outComponents := inComponents;
  outFound := false;
  outContinue := true;
end clearComponentModifiersInCompitems;

protected function stripModifiersKeepRedeclares
  input Option<Absyn.Modification> inMod;
  output Option<Absyn.Modification> outMod;
algorithm
  outMod := match(inMod)
    local
      Absyn.Modification m;
      list<Absyn.ElementArg> ea;
      Absyn.EqMod em;
    case NONE() then NONE();
    case SOME(Absyn.CLASSMOD(ea, _))
      algorithm
        ea := list(e for e guard(match e case Absyn.REDECLARATION() then true; else false; end match) in ea);
        m := Absyn.CLASSMOD(ea, Absyn.NOMOD());
      then
        SOME(m);
  end match;
end stripModifiersKeepRedeclares;

public function setElementModifier
  "Sets a submodifier of an element."
  input Absyn.Path inClass;
  input Absyn.Path inElementName;
  input Absyn.Modification inMod;
  input output Absyn.Program program;
        output Boolean outResult;
protected
  Absyn.Within within_;
  Absyn.Class cls;
algorithm
  try
    cls := getPathedClassInProgram(inClass, program);
    (cls, outResult) := setElementSubmodifierInClass(cls, inElementName, inMod);
    within_ := buildWithin(inClass);
    program := updateProgram(Absyn.PROGRAM({cls}, within_), program);
  else
    outResult := false;
  end try;
end setElementModifier;

public function setExtendsModifier
  "Sets a submodifier on an extends clause in a class."
  input Absyn.Path className;
  input Absyn.Path extendsName;
  input Absyn.Path elementName;
  input Absyn.Modification mod;
  input output Absyn.Program program;
        output Boolean result;
protected
  Absyn.Within within_;
  Absyn.Class cls;
  GraphicEnvCache env;
algorithm
  try
    cls := getPathedClassInProgram(className, program);
    env := Interactive.getClassEnv(program, className);
    (cls, result) := setExtendsSubmodifierInClass(cls, extendsName, elementName, mod, env);
    within_ := buildWithin(className);
    program := updateProgram(Absyn.PROGRAM({cls}, within_), program);
   else
    result := false;
  end try;
end setExtendsModifier;

protected function setElementSubmodifierInClass
" Sets a sub modifier on a component in a class.
   inputs: (Absyn.Class,
              Absyn.Ident, /* component name */
              Absyn.ComponentRef, /* subvariable path */
              Absyn.Modification)
   outputs: Absyn.Class"
  input Absyn.Class inClass;
  input Absyn.Path inElementName;
  input Absyn.Modification inMod;
  output Absyn.Class outClass = inClass;
  output Boolean found;
algorithm
  (outClass, found) := AbsynUtil.traverseClassElements(inClass,
    function setSubmodifierInElement(elementName = inElementName, mod = inMod), false);
end setElementSubmodifierInClass;

protected function setExtendsSubmodifierInClass
  "Helper function to setExtendsSubmodifierValue."
  input output Absyn.Class cls;
  input Absyn.Path extendsPath;
  input Absyn.Path elementName;
  input Absyn.Modification mod;
  input GraphicEnvCache env;
        output Boolean found;
algorithm
  (cls, found) := AbsynUtil.traverseClassElements(cls,
    function setExtendsSubmodifierInElement(extendsPath = extendsPath,
      elementName = elementName, mod = mod, env = env), false);
end setExtendsSubmodifierInClass;

protected function setSubmodifierInElement
  "Helper function to setElementSubmodifierInClass.
   Sets the modifier in an Element."
  input output Absyn.Element element;
  input output Boolean found;
  input Absyn.Path elementName;
  input Absyn.Modification mod;
        output Boolean outContinue = true;
protected
  list<Absyn.ElementArg> args_old, args_new;
  Absyn.EqMod eqmod_old, eqmod_new;
  String el_id, id = "";
  Absyn.ElementSpec el_spec;
algorithm
  el_id := AbsynUtil.pathFirstIdent(elementName);
  el_spec := AbsynUtil.elementSpec(element);

  if not AbsynUtil.isClassOrComponentElementSpec(el_spec) then
    return;
  end if;

  // this will fail if no class or component (extends, import, etc)
  id := AbsynUtil.elementSpecName(el_spec);

  if el_id == id then
    try
      () := match element
        case Absyn.ELEMENT()
          algorithm
            element.specification := setSubmodifierInElementSpec(elementName, mod, element.specification);
          then ();
      end match;
      found := true;
      outContinue := false;
    else
    end try;
  end if;
end setSubmodifierInElement;

protected function setExtendsSubmodifierInElement
  "Helper function to setExtendsSubmodifierValue."
  input output Absyn.Element element;
  input Absyn.Path extendsPath;
  input Absyn.Path elementName;
  input Absyn.Modification mod;
  input GraphicEnvCache env;
  input output Boolean found;
        output Boolean outContinue = true;
protected
  Absyn.ElementSpec ext_spec;
  Absyn.Path full_path;
  list<Absyn.ElementArg> eargs;
  Option<Absyn.Modification> opt_mod;
algorithm
  found := matchcontinue element
    case Absyn.ELEMENT(specification = ext_spec as Absyn.EXTENDS(elementArg = eargs))
      algorithm
        (_, full_path) := Interactive.mkFullyQual(env, ext_spec.path);
        true := AbsynUtil.pathEqual(extendsPath, full_path);

        if AbsynUtil.pathFirstIdent(elementName) == "_" then
          // If the element name is _, then apply the modifier directly to the
          // extends clause instead of to a specific element.
          opt_mod := propagateMod(elementName, mod, SOME(Absyn.CLASSMOD(eargs, Absyn.NOMOD())));
        else
          opt_mod := propagateMod(AbsynUtil.prefixPath("dummy", elementName),
            mod, SOME(Absyn.CLASSMOD(eargs, Absyn.NOMOD())));
        end if;

        ext_spec.elementArg := match opt_mod
          case SOME(Absyn.Modification.CLASSMOD(elementArgLst = eargs)) then eargs;
          else {};
        end match;

        element.specification := ext_spec;
      then
        true;

    else false;
  end matchcontinue;

  outContinue := not found;
end setExtendsSubmodifierInElement;

function setSubmodifierInElementSpec
  input Absyn.Path elementName;
  input Absyn.Modification mod;
  input output Absyn.ElementSpec elSpec;
algorithm
  () := match elSpec
    case Absyn.CLASSDEF()
      algorithm
        elSpec.class_ := setSubmodifierInClass(elementName, elSpec.class_, mod);
      then
        ();

    case Absyn.COMPONENTS()
      algorithm
        elSpec.components := setComponentSubmodifierInCompitems(elSpec.components, false, elementName, mod);
      then
        ();
  end match;
end setSubmodifierInElementSpec;

function setSubmodifierInClass
  input Absyn.Path inElementName;
  input Absyn.Class inClass;
  input Absyn.Modification inMod;
  output Absyn.Class outClass;
protected
  Absyn.Class cls = inClass;
  Option<Absyn.Modification> optMod;
  Absyn.Modification mod;
  Absyn.ClassDef body;
algorithm
  outClass := match cls
    case Absyn.CLASS()
      algorithm
        body := cls.body;
        body := match body
          case Absyn.DERIVED()
            algorithm
              SOME(mod) := propagateMod(inElementName, inMod, SOME(Absyn.CLASSMOD(body.arguments, Absyn.NOMOD())));
              body.arguments := match mod case Absyn.CLASSMOD() then mod.elementArgLst; end match;
            then body;
        end match;
        cls.body := body;
      then
        cls;
  end match;
end setSubmodifierInClass;

public function setComponentSubmodifierInCompitems
  "Helper function to setComponentSubmodifierInClass. Sets the modifier in a
   ComponentItem."
  input list<Absyn.ComponentItem> inComponents;
  input Boolean inFound;
  input Absyn.Path inComponentName;
  input Absyn.Modification inMod;
  output list<Absyn.ComponentItem> outComponents = {};
  output Boolean outFound;
  output Boolean outContinue;
protected
  Absyn.ComponentItem item;
  list<Absyn.ComponentItem> rest_items = inComponents;
  Absyn.Component comp;
  list<Absyn.ElementArg> args_old, args_new;
  Absyn.EqMod eqmod_old, eqmod_new;
  String comp_id;
algorithm
  comp_id := AbsynUtil.pathFirstIdent(inComponentName);

  // Try to find the component we're looking for.
  while not listEmpty(rest_items) loop
    item :: rest_items := rest_items;

    if AbsynUtil.componentName(item) == comp_id then
      // Found component, propagate the modifier to it.
      _ := match item
        case Absyn.COMPONENTITEM(component = comp as Absyn.COMPONENT())
          algorithm
            comp.modification := propagateMod(inComponentName, inMod, comp.modification);
            item.component := comp;
          then
            ();
      end match;

      // Reassemble the item list and return.
      outComponents := List.append_reverse(outComponents, item :: rest_items);
      outFound := true;
      outContinue := false;
      return;
    end if;
    outComponents := item :: outComponents;
  end while;

  // Component not found, continue looking.
  outComponents := inComponents;
  outFound := false;
  outContinue := true;
end setComponentSubmodifierInCompitems;

public function propagateMod
  input Absyn.Path inComponentName;
  input Absyn.Modification inNewMod;
  input Option<Absyn.Modification> inOldMod;
  output Option<Absyn.Modification> outMod;
protected
  list<Absyn.ElementArg> new_args, old_args;
  Absyn.EqMod new_eqmod, old_eqmod;
  Absyn.Modification mod;
algorithm
  if isSome(inOldMod) then
    SOME(Absyn.CLASSMOD(elementArgLst = old_args, eqMod = old_eqmod)) := inOldMod;
  else
    old_args := {};
    old_eqmod := Absyn.NOMOD();
  end if;

  if AbsynUtil.pathIsIdent(inComponentName) then
    Absyn.CLASSMOD(elementArgLst = new_args, eqMod = new_eqmod) := inNewMod;

    // If we have no eqmod but a list of submods, keep the old eqmod.
    if valueEq(new_eqmod, Absyn.NOMOD()) and not listEmpty(new_args) then
      new_eqmod := old_eqmod;
    end if;

    // Merge submodifiers if the new mod isn't empty, otherwise clear them.
    if not AbsynUtil.isEmptyMod(inNewMod) then
      new_args := mergeElementArgs(old_args, new_args);
    end if;

    mod := Absyn.CLASSMOD(new_args, new_eqmod);
  else
    new_args := propagateMod2(inComponentName, old_args, inNewMod);
    mod := Absyn.CLASSMOD(new_args, old_eqmod);
  end if;

  outMod := if AbsynUtil.isEmptyMod(mod) then NONE() else SOME(mod);
end propagateMod;

protected function mergeElementArgs
  input list<Absyn.ElementArg> inOldArgs;
  input list<Absyn.ElementArg> inNewArgs;
  output list<Absyn.ElementArg> outArgs = inOldArgs;
protected
  Boolean found;
algorithm
  if listEmpty(inOldArgs) then
    outArgs := removeEmptySubMods(inNewArgs);
  elseif listEmpty(inNewArgs) then
    outArgs := inOldArgs;
  else
    for narg in inNewArgs loop
      (outArgs, found) := List.replaceOnTrue(narg, outArgs,
        function AbsynUtil.elementArgEqualName(inArg2 = narg));

      if not found then
        outArgs := List.appendElt(narg, outArgs);
      end if;
    end for;

    outArgs := removeEmptySubMods(outArgs);
  end if;
end mergeElementArgs;

function removeEmptySubMods
  input list<Absyn.ElementArg> subMods;
  output list<Absyn.ElementArg> outSubMods = {};
protected
  Absyn.Modification mod;
algorithm
  for m in subMods loop
    () := match m
      case Absyn.ElementArg.MODIFICATION(modification = SOME(mod))
        algorithm
          mod.elementArgLst := removeEmptySubMods(mod.elementArgLst);
          m.modification := if AbsynUtil.isEmptyMod(mod) then NONE() else SOME(mod);
        then
          ();

      else ();
    end match;

    if not AbsynUtil.isEmptySubMod(m) then
      outSubMods := m :: outSubMods;
    end if;
  end for;

  outSubMods := Dangerous.listReverseInPlace(outSubMods);
end removeEmptySubMods;

protected function propagateMod2
  input Absyn.Path inComponentName;
  input list<Absyn.ElementArg> inSubMods;
  input Absyn.Modification inNewMod;
  output list<Absyn.ElementArg> outSubMods = {};
protected
  Absyn.ElementArg submod;
  list<Absyn.ElementArg> rest_submods = inSubMods;
  Absyn.Modification new_mod;
  Absyn.Path comp_name, comp_rest;
algorithm
  // Search through the submods to see if one matches the component name.
  while not listEmpty(rest_submods) loop
    submod :: rest_submods := rest_submods;
    comp_name := AbsynUtil.pathRest(inComponentName);
    comp_rest := comp_name;

    // Try to find the submod whose path matches the best. If we have a
    // component name a.b.c, then first check a.b.c, then a.b, then a.
    while true loop
      if AbsynUtil.pathEqual(comp_name, AbsynUtil.elementArgName(submod)) then
        // Found matching submod, propagate the modifier to it.
        _ := match(submod)
          case Absyn.MODIFICATION()
            algorithm
              if not AbsynUtil.pathIsIdent(comp_name) then
                comp_name := AbsynUtil.pathPrefix(comp_name);
                comp_rest := AbsynUtil.removePrefix(comp_name, comp_rest);
              end if;

              submod.modification := propagateMod(comp_rest, inNewMod, submod.modification);

              if isSome(submod.modification) then
                rest_submods := submod :: rest_submods;
              end if;
            then
              ();

          case Absyn.REDECLARATION()
            algorithm
              submod.elementSpec := setSubmodifierInElementSpec(comp_rest, inNewMod, submod.elementSpec);
              rest_submods := submod :: rest_submods;
            then
              ();

          else ();
        end match;

        outSubMods := List.append_reverse(outSubMods, rest_submods);
        return;
      end if;

      if AbsynUtil.pathIsIdent(comp_name) then
        // Nothing left of the path, break and continue with next submod.
        break;
      else
        // Remove the last part of the component name and see if that matches
        // instead.
        comp_name := AbsynUtil.pathPrefix(comp_name);
      end if;
    end while;

    outSubMods := submod :: outSubMods;
  end while;

  if not AbsynUtil.isEmptyMod(inNewMod) then
    // No matching submod was found, create a new submod and insert it into the list.
    submod := createNestedSubMod(AbsynUtil.pathRest(inComponentName), inNewMod);
    outSubMods := listReverse(submod :: outSubMods);
  else
    outSubMods := inSubMods;
  end if;
end propagateMod2;

protected function createNestedSubMod
  input Absyn.Path inComponentName;
  input Absyn.Modification inMod;
  output Absyn.ElementArg outSubMod;
protected
  Absyn.ElementArg e;
algorithm
  if AbsynUtil.pathIsIdent(inComponentName) then
    outSubMod := Absyn.MODIFICATION(false, Absyn.NON_EACH(), inComponentName,
      SOME(inMod), NONE(), AbsynUtil.dummyInfo);
  else
    outSubMod := createNestedSubMod(AbsynUtil.pathRest(inComponentName), inMod);
    outSubMod := Absyn.MODIFICATION(false, Absyn.NON_EACH(),
                   AbsynUtil.pathFirstPath(inComponentName),
                   SOME(Absyn.CLASSMOD({outSubMod}, Absyn.NOMOD())), NONE(),
                   AbsynUtil.dummyInfo);
  end if;
end createNestedSubMod;

public function getElementModifierValue
  input Absyn.ComponentRef classRef;
  input Absyn.ComponentRef varRef;
  input Absyn.ComponentRef subModRef;
  input Absyn.Program program;
  output String valueStr;
protected
  Absyn.Path cls_path;
  String name, elName;
  Absyn.Class cls;
  list<Absyn.ElementArg> args = {};
  list<Absyn.Element> elems;
  Boolean found = false;
  list<Absyn.ComponentItem> components;
  Option<Absyn.Modification> optMod;
algorithm
  try
    cls_path := AbsynUtil.crefToPath(classRef);
    elName := AbsynUtil.crefIdent(varRef);
    cls := getPathedClassInProgram(cls_path, program);
    elems := getElementsInClass(cls);
    for e in elems loop
      args := match e
        case Absyn.ELEMENT(specification=Absyn.CLASSDEF(class_ = Absyn.CLASS(name = name, body = Absyn.DERIVED(arguments = args)))) guard stringEq(name, elName)
          algorithm
            found := true;
          then
            args;
        case Absyn.ELEMENT(specification=Absyn.COMPONENTS(components = components))
          algorithm
            for c in components loop
              Absyn.COMPONENTITEM(Absyn.COMPONENT(name = name, modification = optMod)) := c;
              if stringEq(name, elName) then
                Absyn.CLASSMOD(elementArgLst = args) := Util.getOptionOrDefault(optMod, Absyn.CLASSMOD({}, Absyn.NOMOD()));
                found := true;
              end if;
            end for;
          then
            args;
        else {};
      end match;
      if found then
        break;
      end if;
    end for;
    if found then
      valueStr := getModificationValueStr(args, AbsynUtil.crefToPath(subModRef));
    else
      valueStr := "";
    end if;
  else
    valueStr := "";
  end try;
end getElementModifierValue;

public function getModificationValueStr
  "Looks up a modifier in a list of element args and returns its binding
   expression, or fails if no modifier is found."
  input list<Absyn.ElementArg> args;
  input Absyn.Path path;
  output String value = "";
protected
  String name;
  list<Absyn.ElementArg> rest_args = args;
  Absyn.ElementArg arg;
  Boolean found = false;
  Absyn.ElementSpec elSpec;
  Absyn.Exp exp;
algorithm
  while not found loop
    arg :: rest_args := rest_args;

    found := match arg
      case Absyn.MODIFICATION() guard AbsynUtil.pathEqual(arg.path, path)
        algorithm
          SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp = exp))) := arg.modification;
          value := Dump.printExpStr(exp);
        then
          true;

      case Absyn.MODIFICATION(path = Absyn.IDENT(name = name))
          guard name == AbsynUtil.pathFirstIdent(path)
        algorithm
          SOME(Absyn.CLASSMOD(elementArgLst = rest_args)) := arg.modification;
          value := getModificationValueStr(rest_args, AbsynUtil.pathRest(path));
        then
          true;

      case Absyn.REDECLARATION(elementSpec = elSpec)
        guard AbsynUtil.pathFirstIdent(path) == AbsynUtil.elementSpecName(elSpec)
        algorithm
          value := System.escapedString(Dump.unparseElementArgStr(arg), false);
        then
          true;

      else false;
    end match;
  end while;
end getModificationValueStr;

public function getElementModifierValues
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.Program inProgram4;
  output String outString;
algorithm
  outString := matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inProgram4)
    local
      Absyn.Path p_class;
      String name,res;
      Absyn.Class cdef;
      list<Absyn.Element> elems;
      list<list<Absyn.ComponentItem>> compelts;
      list<Absyn.ComponentItem> compelts_1;
      Absyn.Modification mod;
      Absyn.ComponentRef class_,ident,subident;
      Absyn.Program p;
      list<Absyn.ElementArg> elementArgLst;

    case (class_,ident,subident,p)
      equation
        p_class = AbsynUtil.crefToPath(class_);
        Absyn.IDENT(name) = AbsynUtil.crefToPath(ident);
        cdef = getPathedClassInProgram(p_class, p);
        elems = getElementsInClass(cdef);
        compelts = List.map(elems, getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        {Absyn.COMPONENTITEM(component=Absyn.COMPONENT(modification=SOME(Absyn.CLASSMOD(elementArgLst=elementArgLst))))} = List.select1(compelts_1, componentitemNamed, name);
        mod = getModificationValues(elementArgLst, AbsynUtil.crefToPath(subident));
        res = unparseMods(mod);
      then
        res;
    else "Error";
  end matchcontinue;
end getElementModifierValues;

public function unparseMods
  input Absyn.Modification mod;
  output String s;
protected
  Absyn.ElementArg arg;
algorithm
  s := match(mod)
    case Absyn.CLASSMOD(elementArgLst = (arg as Absyn.REDECLARATION())::_)
     then System.escapedString(Dump.unparseElementArgStr(arg), false);
    else
     then Dump.unparseModificationStr(mod);
  end match;
end unparseMods;

protected function getModificationValues
  "Helper function to getComponentModifierValues
   Investigates modifications to find submodifier."
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Absyn.Path inPath;
  output Absyn.Modification outModification;
algorithm
  outModification:=
  match (inAbsynElementArgLst,inPath)
    local
      Boolean f;
      Absyn.Each each_;
      Absyn.Path p1,p2;
      Absyn.Modification mod,res;
      Option<String> cmt;
      list<Absyn.ElementArg> rest,args;
      String name1,name2;
      Absyn.ElementSpec elSpec;
      Absyn.ElementArg elArg;
    case ((Absyn.MODIFICATION(path = p1,modification = SOME(mod)) :: _),p2) guard AbsynUtil.pathEqual(p1, p2)
      then
        mod;
    case ((Absyn.MODIFICATION(path = Absyn.IDENT(name = name1),modification = SOME(Absyn.CLASSMOD(elementArgLst=args))) :: _),Absyn.QUALIFIED(name = name2,path = p2))
      guard stringEq(name1, name2)
      equation
        res = getModificationValues(args, p2);
      then
        res;
    case ((elArg as Absyn.REDECLARATION(elementSpec = elSpec)) :: _, p1) guard AbsynUtil.pathFirstIdent(p1) == AbsynUtil.elementSpecName(elSpec)
        then
          Absyn.CLASSMOD({elArg}, Absyn.NOMOD());
    case ((_ :: rest),_)
      equation
        mod = getModificationValues(rest, inPath);
      then
        mod;
  end match;
end getModificationValues;

public function getElementModifierNames
 "Return the modifiernames of an element"
  input Absyn.Path path;
  input String inElementName;
  input Absyn.Program inProgram3;
  output list<String> outList;
algorithm
  outList:=
  matchcontinue (path,inElementName,inProgram3)
    local
      Absyn.Class cdef;
      list<Absyn.Element> elems;
      list<Absyn.ElementSpec> elSpec;
      list<String> res;
      String name;
      Absyn.Program p;
      list<Absyn.ElementArg> mod = {}, args = {};
      list<Absyn.ComponentItem> components;
      Boolean found = false;
      Option<Absyn.Modification> optMod;
    case (_,_,p)
      algorithm
        cdef := getPathedClassInProgram(path, p);
        elems := getElementsInClass(cdef);
        for e in elems loop
          mod := match e
            case Absyn.ELEMENT(specification=Absyn.CLASSDEF(class_ = Absyn.CLASS(name = name, body = Absyn.DERIVED(arguments = args)))) guard stringEq(name, inElementName)
              algorithm
                found := true;
              then
                args;
            case Absyn.ELEMENT(specification=Absyn.COMPONENTS(components = components))
              algorithm
                for c in components loop
                  Absyn.COMPONENTITEM(Absyn.COMPONENT(name = name, modification = optMod)) := c;
                  if stringEq(name, inElementName) then
                    Absyn.CLASSMOD(elementArgLst = mod) := Util.getOptionOrDefault(optMod, Absyn.CLASSMOD({}, Absyn.NOMOD()));
                    found := true;
                  end if;
                end for;
              then
                mod;
            else {};
          end match;
          if found then
            break;
          end if;
        end for;
        res := getModificationNames(mod, includeRedeclares = true);
      then
        res;
    else {};
  end matchcontinue;
end getElementModifierNames;

function getExtendsModifierNames
  "Return the modifier names of a modification on an extends clause.
   For instance,
     model test extends A(p1=3,p2(z=3));end test;
     getExtendsModifierNames(test,A) => {p1,p2.z}
  "
  input Absyn.Path classPath;
  input Absyn.Path extendsPath;
  input Boolean useQuotes;
  input Absyn.Program program;
  output Values.Value result;
protected
  Absyn.Class cdef;
  list<Absyn.ElementSpec> exts;
  GraphicEnvCache env;
  list<Absyn.ElementArg> extmod;
  list<String> res;
  String res_str;
  Boolean silent = not Flags.isSet(Flags.NF_API_NOISE);
algorithm
  if silent then
    ErrorExt.setCheckpoint(getInstanceName());
  end if;

  try
    SOME(Absyn.EXTENDS(elementArg = extmod)) :=
      getPathedExtendsInProgram(classPath, extendsPath, program);
    res := getModificationNames(extmod, includeRedeclares = true);

    if useQuotes then
      res := Interactive.insertQuotesToList(res);
    end if;

    result := ValuesUtil.makeArray(list(ValuesUtil.makeCodeTypeName(AbsynUtil.makeIdentPathFromString(s)) for s in res));
  else
    result := ValuesUtil.makeString("Error");
  end try;

  if silent then
    ErrorExt.rollBack(getInstanceName());
  end if;
end getExtendsModifierNames;

function hasModifiers
  input list<Absyn.ElementSpec> exts;
  output Boolean b = false;
protected
   Absyn.ElementSpec ext;
algorithm
  for e in exts loop
    b := match e
      case ext as Absyn.EXTENDS() then not listEmpty(ext.elementArg);
      else false;
    end match;
    if b then
      break;
    end if;
  end for;
end hasModifiers;

protected function getModificationNames
"Helper function to getElementModifierNames"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Boolean includeRedeclares = false;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynElementArgLst)
    local
      list<String> names,names2,names2_1,names2_2,res;
      Boolean f;
      Absyn.Each each_;
      String name;
      Option<String> cmt;
      list<Absyn.ElementArg> rest,args;
      Absyn.ElementSpec elSpec;
      Absyn.Path p;

    case ({}) then {};

    case (Absyn.MODIFICATION(path = Absyn.IDENT(name = name),modification = NONE()) :: rest)
      equation
        names = getModificationNames(rest, includeRedeclares);
      then
        name :: names;

    case (Absyn.MODIFICATION(path = p,modification = SOME(Absyn.CLASSMOD({},_))) :: rest)
      equation
        name = AbsynUtil.pathString(p);
        names = getModificationNames(rest, includeRedeclares);
      then
        name :: names;

    // modifier with submodifiers -and- binding, e.g. m(...)=2, add also m to list
    case (Absyn.MODIFICATION(path = p,modification = SOME(Absyn.CLASSMOD(args,Absyn.EQMOD()))) :: rest)
      equation
        name = AbsynUtil.pathString(p);
        names2 = list(stringAppend(stringAppend(name, "."), n) for n in getModificationNames(args, includeRedeclares));
        names = getModificationNames(rest, includeRedeclares);
        res = listAppend(names2, names);
      then
        name :: res;

    // modifier with submodifiers, e.g. m(...)
    case (Absyn.MODIFICATION(path = p,modification = SOME(Absyn.CLASSMOD(args,_))) :: rest)
      equation
        name = AbsynUtil.pathString(p);
        names2 = list(stringAppend(stringAppend(name, "."), n) for n in getModificationNames(args, includeRedeclares));
        names = getModificationNames(rest, includeRedeclares);
        res = listAppend(names2, names);
      then
        res;

    case (Absyn.REDECLARATION(elementSpec = elSpec) :: rest) guard includeRedeclares
      equation
        name = AbsynUtil.elementSpecName(elSpec);
        names = getModificationNames(rest, includeRedeclares);
      then
        name :: names;

    case (_ :: rest)
      equation
        names = getModificationNames(rest, includeRedeclares);
      then
        names;

  end matchcontinue;
end getModificationNames;

public function getElementBinding
" Returns the value of a component in a class.
   For example, the component
     Real x=1;
     returns 1.
   This can be used for both parameters, constants and variables."
  input Absyn.Path path;
  input String parameterName;
  input Absyn.Program program;
  output String bindingStr;
protected
  Absyn.Class cls;
  Absyn.ComponentItem component;
algorithm
  try
    cls := getPathedClassInProgram(path, program);
    component := getComponentInClass(cls, parameterName);
    bindingStr := Dump.printExpStr(getVariableBindingInComponentitem(component));
  else
    bindingStr := "";
  end try;
end getElementBinding;

public function getComponentInClass
  "Returns the component with the given name in the given class, or fails if no
   such component exists."
  input Absyn.Class cls;
  input Absyn.Ident componentName;
  output Absyn.ComponentItem component;
protected
  Absyn.ClassDef body;
  list<Absyn.ClassPart> parts;
  list<Absyn.ElementItem> elements;
  list<Absyn.ComponentItem> components;
  Boolean found = false;
algorithm
  Absyn.CLASS(body = body) := cls;

  parts := match body
    case Absyn.PARTS() then body.classParts;
    case Absyn.CLASS_EXTENDS() then body.parts;
  end match;

  for part in parts loop
    elements := match part
      case Absyn.PUBLIC() then part.contents;
      case Absyn.PROTECTED() then part.contents;
      else {};
    end match;

    for e in elements loop
      components := match e
        case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification =
          Absyn.COMPONENTS(components = components))) then components;
        else {};
      end match;

      for c in components loop
        if AbsynUtil.componentName(c) == componentName then
          component := c;
          return;
        end if;
      end for;
    end for;

  end for;

  fail();
end getComponentInClass;

public function getNthComponentInClass
  "Returns the n:th component in a class."
  input Absyn.Class inClass;
  input Integer nth;
  output Absyn.Element outElement;
protected
  list<Absyn.Element> pub, pro, lst;
  Integer n;
algorithm
  pub := getPublicComponentsInClass(inClass);
  n := listLength(pub);
  if nth <= n then
    outElement := listGet(pub, nth);
  else
    // !TODO, check access annotation
    pro := getProtectedComponentsInClass(inClass);
    outElement := listGet(pro, nth-n);
  end if;
end getNthComponentInClass;

public function getComponentsInClass
" Both public and protected lists are searched."
  input Absyn.Class inClass;
  input Visibility visibility = Visibility.ANY;
  output list<Absyn.Element> outAbsynElementLst;
algorithm
  outAbsynElementLst:=
  match (inClass)
    local
      list<Absyn.Element> lst1,res;
      list<Absyn.ClassPart> lst;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = {}))) then {};
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = lst)))
      algorithm
        res := {};
        for elt in lst loop
          res := match elt
              case Absyn.PUBLIC() guard visibility <> Visibility.PROTECTED
                algorithm
                  lst1 := getComponentsInElementitems(elt.contents);
                then
                  List.append_reverse(lst1, res);
              case Absyn.PROTECTED() guard visibility <> Visibility.PUBLIC
                algorithm
                  lst1 := getComponentsInElementitems(elt.contents);
                then
                  List.append_reverse(lst1, res);
              else res;
            end match;
        end for;
      then
        Dangerous.listReverseInPlace(res);

    // adrpo: handle also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = {}))) then {};
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = lst)))
      algorithm
        res := {};
        for elt in lst loop
          res := match elt
              case Absyn.PUBLIC() guard visibility <> Visibility.PROTECTED
                algorithm
                  lst1 := getComponentsInElementitems(elt.contents);
                then
                  List.append_reverse(lst1, res);
              case Absyn.PROTECTED() guard visibility <> Visibility.PUBLIC
                algorithm
                  lst1 := getComponentsInElementitems(elt.contents);
                then
                  List.append_reverse(lst1, res);
              else res;
            end match;
        end for;
      then
        Dangerous.listReverseInPlace(res);

    else {};

  end match;
end getComponentsInClass;

function getPublicComponentsInClass
  input Absyn.Class inClass;
  output list<Absyn.Element> components;
algorithm
  components := getComponentsInClass(inClass, Visibility.PUBLIC);
end getPublicComponentsInClass;

function getProtectedComponentsInClass
  input Absyn.Class inClass;
  output list<Absyn.Element> components;
algorithm
  components := getComponentsInClass(inClass, Visibility.PROTECTED);
end getProtectedComponentsInClass;

public function getComponentsInElementitems
"Helper function to getComponentsInClass."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.Element> outAbsynElementLst = {};
algorithm
  for el in inAbsynElementItemLst loop
    _ := match (el)
        local
          Absyn.Element elt;
        case Absyn.ELEMENTITEM(element = elt as Absyn.ELEMENT(specification = Absyn.COMPONENTS()))
          algorithm
            outAbsynElementLst := elt :: outAbsynElementLst;
          then ();

        else ();
      end match;
  end for;
  outAbsynElementLst := Dangerous.listReverseInPlace(outAbsynElementLst);
end getComponentsInElementitems;

public function getVariableBindingInComponentitem
" Retrieve the variable binding from an ComponentItem"
  input Absyn.ComponentItem inComponentItem;
  output Absyn.Exp outExp;
algorithm
  outExp := match (inComponentItem)
    local Absyn.Exp e;
    case (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=e)))))) then e;
  end match;
end getVariableBindingInComponentitem;

public function buildWithin
" From a fully qualified model name, build a suitable within clause"
  input Absyn.Path inPath;
  output Absyn.Within outWithin;
algorithm
  outWithin := match inPath
    local Absyn.Path w_path,path;
    case (Absyn.IDENT()) then Absyn.TOP();
    case (Absyn.FULLYQUALIFIED(path)) // handle fully qual also!
      then
        buildWithin(path);
    case (path)
      equation
        w_path = AbsynUtil.stripLast(path);
      then
        Absyn.WITHIN(w_path);
  end match;
end buildWithin;

public function componentitemNamed
" Returns true if the component item has
   the name matching the second argument."
  input Absyn.ComponentItem inComponentItem;
  input Absyn.Ident inIdent;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inComponentItem,inIdent)
    local String id1,id2;
    case (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id1)),id2)
      guard
        stringEq(id1, id2)
      then
        true;
    else false;
  end match;
end componentitemNamed;

public function getComponentitemsInElement
" Retrieves the ComponentItems of a component Element.
   If Element is not a component, empty list is returned."
  input Absyn.Element inElement;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm
  outAbsynComponentItemLst := match (inElement)
    local list<Absyn.ComponentItem> l;
    case (Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = l))) then l;
    else {};
  end match;
end getComponentitemsInElement;

public function updateProgram
" This function takes an old program (second argument), i.e. the old
   symboltable, and a new program (first argument), i.e. a new set of
   classes and updates the old program with the definitions in the new one.
   It also takes in the current symboltable and returns a new one with any
   replaced functions cache cleared."
  input Absyn.Program inNewProgram;
  input Absyn.Program inOldProgram;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Program outProgram;
protected
  list<Absyn.Class> cs;
  Absyn.Within w;
algorithm
  Absyn.PROGRAM(classes=cs,within_=w) := inNewProgram;
  outProgram := updateProgram2(listReverse(cs),w,inOldProgram, mergeAST);
end updateProgram;

protected function updateProgram2
" This function takes an old program (second argument), i.e. the old
   symboltable, and a new program (first argument), i.e. a new set of
   classes and updates the old program with the definitions in the new one.
   It also takes in the current symboltable and returns a new one with any
   replaced functions cache cleared."
  input list<Absyn.Class> inNewClasses;
  input Absyn.Within w;
  input Absyn.Program inOldProgram;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Program outProgram;
algorithm
  outProgram := match (inNewClasses,w,inOldProgram)
    local
      Absyn.Program prg,newp,p2,newp_1;
      Absyn.Class c1;
      String name;
      list<Absyn.Class> c2,c3;
      Absyn.Within w2;

    case ({},_,prg) then prg;

    case ((c1 as Absyn.CLASS(name = name)) :: c2,Absyn.TOP(), (p2 as Absyn.PROGRAM(classes = c3,within_ = w2)))
      equation
        if classInProgram(name, p2) then
          newp = replaceClassInProgram(c1, p2, mergeAST);
        else
          newp = Absyn.PROGRAM((c1 :: c3),w2);
        end if;
      then updateProgram2(c2,w,newp, mergeAST);

    case ((c1 :: c2),Absyn.WITHIN(),p2)
      equation
        newp = insertClassInProgram(c1, w, p2, mergeAST);
        newp_1 = updateProgram2(c2,w,newp, mergeAST);
      then newp_1;

  end match;
end updateProgram2;

public function createEnvironment
  input Absyn.Program p;
  input Option<SCode.Program> os;
  input Absyn.Path modelPath;
  output Interactive.GraphicEnvCache genv;
protected
  FCore.Graph env,env_1,env2;
  SCode.Program s;
  SCode.Element c;
  String id;
  SCode.Encapsulated encflag;
  SCode.Restriction restr;
  ClassInf.State ci_state;
  Absyn.ComponentRef model_;
  FCore.Cache cache;
  Boolean b, permissive;
algorithm
  if Flags.isSet(Flags.NF_API) then
    genv := Interactive.GRAPHIC_ENV_FULL_CACHE(p, modelPath, FCore.emptyCache(), FGraph.emptyGraph);
  else
    s := Util.getOptionOrDefault(os, AbsynToSCode.translateAbsyn2SCode(p));
    (cache,env) := Inst.makeEnvFromProgram(s);
    (cache,(c as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1) := Lookup.lookupClass(cache, env, modelPath);
    env2 := FGraph.openScope(env_1, encflag, id, FGraph.restrictionToScopeType(restr));
    ci_state := ClassInf.start(restr, FGraph.getGraphName(env2));
    permissive := Flags.getConfigBool(Flags.PERMISSIVE);
    FlagsUtil.setConfigBool(Flags.PERMISSIVE, true);
    try
      (_,env2,_,_,_) :=
        Inst.partialInstClassIn(cache, env2, InnerOuter.emptyInstHierarchy, DAE.NOMOD(),
          DAE.NOPRE(), ci_state, c, SCode.PUBLIC(), {}, 0);
      FlagsUtil.setConfigBool(Flags.PERMISSIVE, permissive);
    else
      FlagsUtil.setConfigBool(Flags.PERMISSIVE, permissive);
      fail();
    end try;
    genv := Interactive.GRAPHIC_ENV_FULL_CACHE(SymbolTable.getAbsyn(), modelPath, cache, env2);
  end if;
end createEnvironment;

public function getClassCommentInCommentOpt
"Helper function to getComponentComment."
  input Option<Absyn.Comment> inComment;
  output String outString;
algorithm
  outString := match inComment
    case SOME(Absyn.COMMENT(comment = SOME(outString))) then outString;
    else "";
  end match;
end getClassCommentInCommentOpt;

public function getClassnamesInClass
" This function takes a `Class\' definition and a Path identifying the
   class.
   It returns a string containing comma separated package names found
   in the class definition.
   The list also contains proctected classes if inShowProtected is true."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  input Boolean inShowProtected;
  input Boolean includeConstants;
  output list<Absyn.Path> paths;
algorithm
  paths := match (inPath,inProgram,inClass,inShowProtected,includeConstants)
    local
      list<String> strlist;
      list<Absyn.ClassPart> parts;
      Absyn.Path inmodel,path;
      Absyn.Program p;
      Boolean b,c;
    /* a class with parts */
    case (_,_,Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),b,c)
      equation
        strlist = getClassnamesInParts(parts,b,c);
      then List.map(strlist,AbsynUtil.makeIdentPathFromString);
    /* an extended class with parts: model extends M end M; */
    case (_,_,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),b,c)
      equation
        strlist = getClassnamesInParts(parts,b,c);
      then List.map(strlist,AbsynUtil.makeIdentPathFromString);
    /* a derived class */
    case (_,_,Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH(_, _))),_,_)
      equation
        /* adrpo 2009-10-27: we sholdn't dive into derived classes!
        (cdef,newpath) = lookupClassdef(path, inmodel, p);
        res = getClassnamesInClass(newpath, p, cdef);
        */
      then {};
  end match;
end getClassnamesInClass;

public function getClassnamesInParts
"Helper function to getClassnamesInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Boolean inShowProtected;
  input Boolean includeConstants;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynClassPartLst,inShowProtected,includeConstants)
    local
      list<String> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
      Boolean b,c;

    case ({},_,_) then {};

    case ((Absyn.PUBLIC(contents = elts) :: rest),b,c)
      equation
        l1 = getClassnamesInElts(elts,c);
        l2 = getClassnamesInParts(rest,b,c);
        res = listAppend(l1, l2);
      then
        res;

    // adeas31 2012-01-25: Also check the protected sections.
    case ((Absyn.PROTECTED(contents = elts) :: rest), true, c)
      equation
        l1 = getClassnamesInElts(elts,c);
        l2 = getClassnamesInParts(rest,true,c);
        res = listAppend(l1, l2);
      then
        res;

    case ((_ :: rest),b,c)
      equation
        res = getClassnamesInParts(rest,b,c);
      then
        res;

  end matchcontinue;
end getClassnamesInParts;

public function getClassnamesInElts
"Helper function to getClassnamesInParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Boolean includeConstants;
  output list<String> outStringLst;
protected
  DoubleEnded.MutableList<String> delst;
algorithm
  delst := DoubleEnded.fromList({});
  for elt in inAbsynElementItemLst loop
  _ := match elt
    local
      list<String> res;
      String id;
      list<Absyn.ElementItem> rest;
      Boolean c;
      list<Absyn.ComponentItem> lst;
      list<String> names;

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ =
                 Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = id)))))
      algorithm
        DoubleEnded.push_back(delst, id);
      then ();

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ =
                 Absyn.CLASS(name = id))))
      algorithm
        DoubleEnded.push_back(delst, id);
      then ();

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(attributes = Absyn.ATTR(variability = Absyn.CONST()),
                 components = lst))) guard includeConstants
      algorithm
        DoubleEnded.push_list_back(delst, getComponentItemsName(lst,false));
      then ();

    else ();
  end match;
  end for;
  outStringLst := DoubleEnded.toListAndClear(delst);
end getClassnamesInElts;

public function getElementAnnotationsFromElts
"Helper function to getElementAnnotations."
  input list<Absyn.Element> els;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output Values.Value result;
protected
  list<SCode.Element> graphicProgramSCode;
  FCore.Graph env;
  list<String> res;
  Absyn.Program placementProgram;
  GraphicEnvCache cache;
algorithm
  if not Flags.isSet(Flags.NF_API) then
    placementProgram := modelicaAnnotationProgram(Config.getAnnotationVersion());
    graphicProgramSCode := AbsynToSCode.translateAbsyn2SCode(placementProgram);
    (_,env) := Inst.makeEnvFromProgram(graphicProgramSCode);
  else
    env := FGraph.emptyGraph;
  end if;
  cache := Interactive.GRAPHIC_ENV_NO_CACHE(inFullProgram, inModelPath);
  result := getElementitemsAnnotations(els, env, inClass, cache);
end getElementAnnotationsFromElts;

protected function getElementitemsAnnotations
"Helper function to getElementAnnotationsFromElts"
  input list<Absyn.Element> inElements;
  input FCore.Graph inEnv;
  input Absyn.Class inClass;
  input GraphicEnvCache inCache;
  output Values.Value result;
protected
  list<Values.Value> res, accum = {};
  GraphicEnvCache cache = inCache;
  list<Absyn.ComponentItem> items;
  Option<Absyn.ConstrainClass> cc;
  list<Absyn.ElementArg> annotations;
  Option<Absyn.Comment> cmt;
  Absyn.Program fullProgram;
  Absyn.Path modelPath;
algorithm
  if Flags.isSet(Flags.NF_API) then
    (fullProgram, modelPath) := Interactive.cacheProgramAndPath(inCache);
    result := makeAnnotationArrayValue(NFApi.evaluateAnnotations(fullProgram, modelPath, inElements));
    return;
  end if;

  for e in listReverse(inElements) loop
    accum := matchcontinue e
      case Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = items), constrainClass = cc)
        algorithm
          (res, cache) := getElementitemsAnnotationsFromItems(items,
            getAnnotationsFromConstraintClass(cc), inEnv, inClass, cache);
        then
          listAppend(res, accum);

      case Absyn.ELEMENT(specification = Absyn.CLASSDEF(
           class_ = Absyn.CLASS(body = Absyn.DERIVED(comment = cmt))),
           constrainClass = cc)
        algorithm
          annotations := match cmt
            case SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(annotations))))
              then annotations;
            else {};
          end match;
          (res, cache) := getElementitemsAnnotationsFromElArgs(annotations,
            getAnnotationsFromConstraintClass(cc), inEnv, inClass, cache);
        then
          ValuesUtil.makeArray(res) :: accum;

      case Absyn.ELEMENT(specification = Absyn.COMPONENTS())
        then Values.Value.ARRAY({}, {0}) :: accum;

      case Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(body = Absyn.DERIVED())))
        then Values.Value.ARRAY({}, {0}) :: accum;

      else accum;
    end matchcontinue;
  end for;

  result := ValuesUtil.makeArray(accum);
end getElementitemsAnnotations;

protected function getElementitemsAnnotationsFromElArgs
"Helper function to getElementitemsAnnotations."
  input list<Absyn.ElementArg> inAnnotations;
  input list<Absyn.ElementArg> ccAnnotations;
  input FCore.Graph inEnv;
  input Absyn.Class inClass;
  input GraphicEnvCache inCache;
  output list<Values.Value> result;
  output GraphicEnvCache outCache = inCache;
protected
  list<Absyn.ElementArg> annotations;
  list<String> strl;
algorithm
  annotations := listAppend(inAnnotations, ccAnnotations);
  (strl, outCache) := getElementitemsAnnotationsElArgs(annotations, inEnv, inClass, outCache);
  result := list(ValuesUtil.makeCodeTypeNameStr(s) for s in strl);
end getElementitemsAnnotationsFromElArgs;

protected function getAnnotationsFromConstraintClass
  input Option<Absyn.ConstrainClass> inCC;
  output list<Absyn.ElementArg> outElArgLst;
algorithm
  outElArgLst := match(inCC)
    local list<Absyn.ElementArg> elementArgs;
    case SOME(Absyn.CONSTRAINCLASS(comment = SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(elementArgs))))))
      then elementArgs;
    else {};
  end match;
end getAnnotationsFromConstraintClass;

public function getElementitemsAnnotationsElArgs
"Helper function to getElementitemsAnnotationsFromItems."
  input list<Absyn.ElementArg> inElementArgs;
  input FCore.Graph inEnv;
  input Absyn.Class inClass;
  input GraphicEnvCache inCache;
  input Boolean addAnnotationName = true;
  output list<String> outStringLst = {};
  output GraphicEnvCache outCache = inCache;
protected
  String str, ann_name;
  Absyn.Exp eq_aexp, graphic_exp;
  DAE.Exp eq_dexp, graphic_dexp;
  DAE.Properties prop;
  SourceInfo info;
  FCore.Cache cache;
  FCore.Graph env, env2;
  list<Absyn.ElementArg> mod, stripped_mod, graphic_mod;
  SCode.Element c;
  SCode.Mod smod;
  DAE.Mod dmod;
  DAE.DAElist dae;
  Boolean is_icon, is_diagram;
  Absyn.Program graphic_prog;
  SCode.Element placement_cls;
algorithm
  for e in listReverse(inElementArgs) loop

    e := AbsynUtil.createChoiceArray(e);

    str := matchcontinue e
      case Absyn.MODIFICATION(
          path = Absyn.IDENT(ann_name),
          modification = SOME(Absyn.CLASSMOD({}, Absyn.EQMOD(eq_aexp))),
          info = info)
        algorithm
          (cache, env, _, outCache) := buildEnvForGraphicProgram(outCache, {});

          (_, eq_dexp, prop) :=
            StaticScript.elabGraphicsExp(cache, env, eq_aexp, false, DAE.NOPRE(), info);

          (cache, eq_dexp, prop) := Ceval.cevalIfConstant(cache, env, eq_dexp, prop, false, info);
          eq_dexp := ExpressionSimplify.simplify1(eq_dexp);
          Print.clearErrorBuf() "Clear any error messages generated by the annotations.";

          str := ExpressionDump.printExpStr(eq_dexp);
        then
          stringAppendList({ann_name, "=", str});

      case Absyn.MODIFICATION(
          path = Absyn.IDENT(ann_name),
          modification = SOME(Absyn.CLASSMOD(mod, Absyn.NOMOD())),
          info = info)
        algorithm
          if not listMember(ann_name, {"Icon", "Diagram", "choices"}) then
            (cache, env, _, outCache) := buildEnvForGraphicProgram(outCache, mod);

            (cache, c, env2) := Lookup.lookupClassIdent(cache, inEnv, ann_name);
            smod := AbsynToSCode.translateMod(SOME(Absyn.CLASSMOD(mod,
              Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), NONE(), info);
            (cache, dmod) := Mod.elabMod(cache, env, InnerOuter.emptyInstHierarchy, DAE.NOPRE(),
              smod, false, Mod.COMPONENT(ann_name), AbsynUtil.dummyInfo);

            c := SCodeUtil.classSetPartial(c, SCode.NOT_PARTIAL());
            (_, _, _, _, dae) := Inst.instClass(cache, env2, InnerOuter.emptyInstHierarchy,
              UnitAbsyn.noStore, dmod, DAE.NOPRE(), c, {}, false,
              InstTypes.TOP_CALL(), ConnectionGraph.EMPTY, Connect.emptySet);

            str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
          else // icon, diagram or choices
            is_icon := ann_name == "Icon";
            is_diagram := ann_name == "Diagram" or ann_name == "choices";

            (stripped_mod, graphic_mod) := AbsynUtil.stripGraphicsAndInteractionModification(mod);
            ErrorExt.setCheckpoint("buildEnvForGraphicProgram");
            // GRAPHIC_ENV_NO_CACHE(inFullProgram, inModelPath)
            try
            (cache, env, graphic_prog, _) :=
              buildEnvForGraphicProgram(inCache, mod);
              ErrorExt.rollBack("buildEnvForGraphicProgram");
            else
              ErrorExt.delCheckpoint("buildEnvForGraphicProgram");
              // Fallback to only the graphical primitives left in the program
              (cache, env, graphic_prog, _) := buildEnvForGraphicProgram(inCache, {});
            end try;

            smod := AbsynToSCode.translateMod(SOME(Absyn.CLASSMOD(stripped_mod, Absyn.NOMOD())),
              SCode.NOT_FINAL(), SCode.NOT_EACH(), NONE(), info);
            (cache, dmod) := Mod.elabMod(cache, env, InnerOuter.emptyInstHierarchy,
              DAE.NOPRE(), smod, false, Mod.COMPONENT(ann_name), info);

            placement_cls := AbsynToSCode.translateClass(getClassInProgram(ann_name, graphic_prog));
            (cache, _, _, _, dae) :=
              Inst.instClass(cache, env, InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore,
                dmod, DAE.NOPRE(), placement_cls, {}, false, InstTypes.TOP_CALL(),
                ConnectionGraph.EMPTY, Connect.emptySet);
            str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));

            // Icon and Diagram contain graphic primitives which must be handled
            // specially.
            if is_icon or is_diagram then
              try
                {Absyn.MODIFICATION(modification = SOME(Absyn.CLASSMOD(eqMod =
                  Absyn.EQMOD(exp = graphic_exp))))} := graphic_mod;
                (_, graphic_dexp, prop) := StaticScript.elabGraphicsExp(cache, env,
                  graphic_exp, false, DAE.NOPRE(), info);

                if is_icon then
                  ErrorExt.setCheckpoint("getAnnotationString: Icon");
                  (cache, graphic_dexp) :=
                    Ceval.cevalIfConstant(cache, env, graphic_dexp, prop, false, info);
                  graphic_dexp := ExpressionSimplify.simplify1(graphic_dexp);
                  ErrorExt.rollBack("getAnnotationString: Icon");
                end if;

                str := str + "," + ExpressionDump.printExpStr(graphic_dexp);
              else
              end try;
            end if;

            Print.clearErrorBuf() "This is to clear the error-msg generated by the annotations.";
          end if;
        then
          if addAnnotationName
          then stringAppendList({ann_name, "(", str, ")"})
          else str;

      case Absyn.MODIFICATION(path = Absyn.IDENT(ann_name), modification = NONE())
        algorithm
          (cache, _, _, outCache) := buildEnvForGraphicProgram(outCache, {});

          (cache, c, env) := Lookup.lookupClassIdent(cache, inEnv, ann_name);
          c := SCodeUtil.classSetPartial(c, SCode.NOT_PARTIAL());
          (_, _, _, _, dae) := Inst.instClass(cache, env, InnerOuter.emptyInstHierarchy,
            UnitAbsyn.noStore, DAE.NOMOD(), DAE.NOPRE(), c, {}, false,
            InstTypes.TOP_CALL(), ConnectionGraph.EMPTY, Connect.emptySet);

          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        then
          if addAnnotationName
          then stringAppendList({ann_name, "(", str, ")"})
          else str;

      case Absyn.MODIFICATION(
          path = Absyn.IDENT(ann_name),
          info = info)
        algorithm
          str := "error evaluating: annotation(" + Dump.unparseElementArgStr(e) + ")";
          str := Util.escapeQuotes(str);
        then
          stringAppendList({ann_name, "(\"", str, "\")"});

    end matchcontinue;

    outStringLst := str :: outStringLst;
  end for;
end getElementitemsAnnotationsElArgs;

protected function getElementitemsAnnotationsFromItems
"Helper function to getElementitemsAnnotations."
  input list<Absyn.ComponentItem> inComponentItems;
  input list<Absyn.ElementArg> ccAnnotations;
  input FCore.Graph inEnv;
  input Absyn.Class inClass;
  input GraphicEnvCache inCache;
  output list<Values.Value> result = {};
  output GraphicEnvCache outCache = inCache;
protected
  list<Absyn.ElementArg> annotations;
  list<String> strl;
algorithm
  for comp in listReverse(inComponentItems) loop
    annotations := match comp
      case Absyn.COMPONENTITEM(comment = SOME(Absyn.COMMENT(annotation_ =
          SOME(Absyn.ANNOTATION(annotations)))))
        then listAppend(annotations, ccAnnotations);
      else ccAnnotations;
    end match;

    (strl, outCache) := getElementitemsAnnotationsElArgs(annotations, inEnv, inClass, outCache);
    result := makeAnnotationArrayValue(strl) :: result;
  end for;
end getElementitemsAnnotationsFromItems;

public function modelicaAnnotationProgram
  input String annotationVersion "1.x or 2.x or 3.x";
  output Absyn.Program annotationProgram;
protected
  String filename;
algorithm
  filename := Settings.getInstallationDirectoryPath() +
              "/lib/omc/AnnotationsBuiltin_" +
              Util.stringReplaceChar(annotationVersion, ".", "_") +
              ".mo";
  annotationProgram := Parser.parsebuiltin(filename, "UTF-8");
end modelicaAnnotationProgram;

public function buildEnvForGraphicProgram
  "Builds an environment for instantiating graphical annotations. If the
   annotation modification only contains literals we only need to make an
   environment from the program, otherwise we need to fully instantiate the
   class used. To avoid doing this work over and over this function takes and
   returns a GraphicEnvCache, which is used to save the state between multiple
   calls to this function.

   This function is called by getAnnotationString, which expects to get back an
   Absyn.Program where the graphical annotation classes have been added. Since
   this is only used by getAnnotationString so far, and it always calls this
   function with an empty cache, this function returns a dummy program when
   called with a non-empty cache. The generated absyn program could easily be
   added to the cache if necessary though."
  input GraphicEnvCache inCache;
  input list<Absyn.ElementArg> inAnnotationMod;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output Absyn.Program outGraphicProgram;
  output GraphicEnvCache outGraphicEnvCache;
algorithm
  (outCache, outEnv, outGraphicProgram, outGraphicEnvCache) := match inCache
    local
      Absyn.Program absyn_program;
      SCode.Program scode_program;

    // Class already fully instantiated, return cached data.
    case Interactive.GRAPHIC_ENV_FULL_CACHE()
      then (inCache.cache, inCache.env, AbsynUtil.dummyProgram, inCache);

    // Partial cache, instantiate class to make full cache if needed.
    case Interactive.GRAPHIC_ENV_PARTIAL_CACHE()
      algorithm
        if AbsynUtil.onlyLiteralsInAnnotationMod(inAnnotationMod) then
          outCache := inCache.cache;
          outEnv := inCache.env;
          outGraphicEnvCache := inCache;
          outGraphicProgram := inCache.program;
        else
          (outCache, outEnv, outGraphicProgram) :=
            buildEnvForGraphicProgramFull(inCache.program, inCache.modelPath);
          outGraphicEnvCache := Interactive.GRAPHIC_ENV_FULL_CACHE(inCache.program, inCache.modelPath, outCache, outEnv);
        end if;
      then
        (outCache, outEnv, outGraphicProgram, outGraphicEnvCache);

    // No cache, make partial or full cache as needed.
    case Interactive.GRAPHIC_ENV_NO_CACHE()
      algorithm
        if AbsynUtil.onlyLiteralsInAnnotationMod(inAnnotationMod) then
          outGraphicProgram := modelicaAnnotationProgram(Config.getAnnotationVersion());
          scode_program := AbsynToSCode.translateAbsyn2SCode(outGraphicProgram);
          (outCache, outEnv) := Inst.makeEnvFromProgram(scode_program);
          outGraphicEnvCache :=
            Interactive.GRAPHIC_ENV_PARTIAL_CACHE(inCache.program, inCache.modelPath, outCache, outEnv);
        else
          (outCache, outEnv, outGraphicProgram) :=
            buildEnvForGraphicProgramFull(inCache.program, inCache.modelPath);
          outGraphicEnvCache := Interactive.GRAPHIC_ENV_FULL_CACHE(inCache.program, inCache.modelPath, outCache, outEnv);
        end if;
      then
        (outCache, outEnv, outGraphicProgram, outGraphicEnvCache);

  end match;
end buildEnvForGraphicProgram;

protected function buildEnvForGraphicProgramFull
  "Helper function to buildEnvForGraphicProgram. Builds an environment by fully
   instantiating the currently used class."
  input Absyn.Program inProgram;
  input Absyn.Path inModelPath;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output Absyn.Program outProgram;
protected
  Boolean check_model, eval_param, failed = false, graphics_mode;
  Absyn.Program graphic_program;
  SCode.Program scode_program;
algorithm
  graphic_program := modelicaAnnotationProgram(Config.getAnnotationVersion());
  outProgram := updateProgram(graphic_program, inProgram);
  scode_program := AbsynToSCode.translateAbsyn2SCode(outProgram);

  check_model := Flags.getConfigBool(Flags.CHECK_MODEL);
  eval_param := Config.getEvaluateParametersInAnnotations();
  graphics_mode := Config.getGraphicsExpMode();
  FlagsUtil.setConfigBool(Flags.CHECK_MODEL, true);
  Config.setEvaluateParametersInAnnotations(true);
  Config.setGraphicsExpMode(true);

  try
    (outCache, outEnv) := Inst.instantiateClass(FCore.emptyCache(), InnerOuter.emptyInstHierarchy, scode_program, inModelPath);
  else
    failed := true;
  end try;

  Config.setEvaluateParametersInAnnotations(eval_param);
  FlagsUtil.setConfigBool(Flags.CHECK_MODEL, check_model);
  Config.setGraphicsExpMode(graphics_mode);
  if failed then
    fail();
  end if;
end buildEnvForGraphicProgramFull;

public function getElementsInClass
" Both public and protected lists are searched."
  input Absyn.Class inClass;
  output list<Absyn.Element> outAbsynElementLst;
algorithm
  outAbsynElementLst:=
  match (inClass)
    local
      list<Absyn.Element> lst1,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> lst;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = {}))) then {};
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = lst)))
      algorithm
        res := {};
        for elt in lst loop
          _ := match elt
              case Absyn.PUBLIC(contents = elts)
                algorithm
                  lst1 := getElementsInElementitems(elts);
                  res := List.append_reverse(lst1, res);
                then ();
                case Absyn.PROTECTED(contents = elts)
                  algorithm
                    lst1 := getElementsInElementitems(elts);
                    res := List.append_reverse(lst1, res);
                  then ();
              else ();
            end match;
        end for;
        res := Dangerous.listReverseInPlace(res);
      then
        res;

    // adrpo: handle also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = {}))) then {};
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = lst)))
      algorithm
        res := {};
        for elt in lst loop
          _ := match elt
              case Absyn.PUBLIC(contents = elts)
                algorithm
                  lst1 := getElementsInElementitems(elts);
                  res := List.append_reverse(lst1, res);
                then ();
                case Absyn.PROTECTED(contents = elts)
                  algorithm
                    lst1 := getElementsInElementitems(elts);
                    res := List.append_reverse(lst1, res);
                  then ();
              else ();
            end match;
        end for;
        res := Dangerous.listReverseInPlace(res);
      then
        res;

    else {};

  end match;
end getElementsInClass;

public function getPublicElementsInClass
" Public lists are searched."
  input Absyn.Class inClass;
  output list<Absyn.Element> outAbsynElementLst;
algorithm
  outAbsynElementLst:=
  match (inClass)
    local
      list<Absyn.Element> lst1,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> lst;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = {}))) then {};
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = lst)))
      algorithm
        res := {};
        for elt in lst loop
          _ := match elt
              case Absyn.PUBLIC(contents = elts)
                algorithm
                  lst1 := getElementsInElementitems(elts);
                  res := List.append_reverse(lst1, res);
                then ();
              else ();
            end match;
        end for;
        res := Dangerous.listReverseInPlace(res);
      then
        res;

    // adrpo: handle also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = {}))) then {};
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = lst)))
      algorithm
        res := {};
        for elt in lst loop
          _ := match elt
              case Absyn.PUBLIC(contents = elts)
                algorithm
                  lst1 := getElementsInElementitems(elts);
                  res := List.append_reverse(lst1, res);
                then ();
              else ();
            end match;
        end for;
        res := Dangerous.listReverseInPlace(res);
      then
        res;

    else {};
  end match;
end getPublicElementsInClass;

public function getProtectedElementsInClass
" Protected lists are searched."
  input Absyn.Class inClass;
  output list<Absyn.Element> outAbsynElementLst;
algorithm
  outAbsynElementLst:=
  match (inClass)
    local
      list<Absyn.Element> lst1,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> lst;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = {}))) then {};
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = lst)))
      algorithm
        res := {};
        for elt in lst loop
          _ := match elt
              case Absyn.PROTECTED(contents = elts)
                algorithm
                  lst1 := getElementsInElementitems(elts);
                  res := List.append_reverse(lst1, res);
                then ();
              else ();
            end match;
        end for;
        res := Dangerous.listReverseInPlace(res);
      then
        res;

    // adrpo: handle also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = {}))) then {};
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = lst)))
      algorithm
        res := {};
        for elt in lst loop
          _ := match elt
              case Absyn.PROTECTED(contents = elts)
                algorithm
                  lst1 := getElementsInElementitems(elts);
                  res := List.append_reverse(lst1, res);
                then ();
              else ();
            end match;
        end for;
        res := Dangerous.listReverseInPlace(res);
      then
        res;

    else {};
  end match;
end getProtectedElementsInClass;

protected function getElementsInElementitems
"Helper function to getElementsInClass."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.Element> outAbsynElementLst = {};
algorithm
  for el in inAbsynElementItemLst loop
    _ := match (el)
        local
          Absyn.Element elt;
        case Absyn.ELEMENTITEM(element = elt)
          algorithm
            outAbsynElementLst := elt :: outAbsynElementLst;
          then ();

        else ();
      end match;
  end for;
  outAbsynElementLst := Dangerous.listReverseInPlace(outAbsynElementLst);
end getElementsInElementitems;

public function dimensionListValues
  input list<Absyn.Subscript> dims;
  output list<Values.Value> vals;
algorithm
  vals := list(ValuesUtil.makeCodeTypeNameStr(Dump.printSubscriptStr(d)) for d in dims);
end dimensionListValues;

protected function getElementInfo
" This function takes an Element and returns a list of strings
   of comma separated values of the type and name and comment,
   and attributes of  of the component, If Element is not a
   component, the empty string is returned.
   inputs: (Absyn.Element, string, /* public or protected */, FCore.Graph)
   outputs: string list"
  input Absyn.Element element;
  input Boolean isPublic;
  input Boolean quoteNames;
  input Boolean onlyComponents;
  input GraphicEnvCache env;
  input output list<Values.Value> infos = {};
protected
  Absyn.ElementAttributes attr;
  Absyn.Path ty, cc_path;
  list<Absyn.ComponentItem> comps;
  String name, cmt;
  list<Values.Value> common_info, info;
  Absyn.Class cls;
  Absyn.Restriction restriction;
  Option<Absyn.Comment> opt_cmt;
  Option<Absyn.ConstrainClass> opt_cc;
  Option<Absyn.ArrayDim> opt_adim;
  list<Values.Value> common_dims, dims;
  Values.Value dims_val;
algorithm
  infos := match element
    case Absyn.ELEMENT(specification = Absyn.COMPONENTS(
          attributes = attr, typeSpec = Absyn.TPATH(path = ty, arrayDim = opt_adim), components = comps),
        constrainClass = opt_cc)
      algorithm
        common_info := {};
        ty := qualifyPath(env, ty);
        common_dims := dimensionListValues(attr.arrayDim);

        if not onlyComponents then
          cc_path := getConstrainClassPath(env, opt_cc);

          if quoteNames then
            common_info := ValuesUtil.makeString(AbsynUtil.pathString(cc_path)) :: common_info;
          else
            common_info := ValuesUtil.makeCodeTypeName(getConstrainClassPath(env, opt_cc)) :: common_info;
          end if;
        end if;

        common_info := getElementAttributeValues(element, isPublic, quoteNames, common_info);

        for comp in listReverse(comps) loop
          name := comp.component.name;
          cmt := getComponentComment(comp, element);
          dims := dimensionListValues(comp.component.arrayDim);
          dims_val := ValuesUtil.makeArray(listAppend(dims, common_dims));

          if quoteNames then
            dims_val := ValuesUtil.makeString(ValuesUtil.printValStr(dims_val));
          end if;

          info := List.appendElt(dims_val, common_info);
          info := ValuesUtil.makeString(cmt) :: info;

          if quoteNames then
            info := ValuesUtil.makeString(name) :: info;
            info := ValuesUtil.makeString(AbsynUtil.pathString(ty)) :: info;
          else
            info := ValuesUtil.makeCodeTypeNameStr(name) :: info;
            info := ValuesUtil.makeCodeTypeName(ty) :: info;
          end if;

          if not onlyComponents then
            info := ValuesUtil.makeString("co") :: ValuesUtil.makeString("-") :: info;
          end if;

          infos := ValuesUtil.makeArray(info) :: infos;
        end for;
      then
        infos;

    case Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = cls as Absyn.CLASS(
            name = name, restriction = restriction,
            body = Absyn.DERIVED(typeSpec = Absyn.TPATH(ty, opt_adim), attributes = attr, comment = opt_cmt))),
          constrainClass = opt_cc)
      guard not onlyComponents
      algorithm
        ty := qualifyPath(env, ty);

        cmt := getConstrainingClassComment(opt_cc);

        if stringEmpty(cmt) then
          cmt := getClassCommentInCommentOpt(opt_cmt);
        end if;

        dims := if isSome(opt_adim) then dimensionListValues(Util.getOption(opt_adim)) else {};
        dims := listAppend(dimensionListValues(attr.arrayDim), dims);
        dims_val := ValuesUtil.makeArray(dims);

        if quoteNames then
          dims_val := ValuesUtil.makeString(ValuesUtil.printValStr(dims_val));
        end if;

        info := {dims_val};
        info := ValuesUtil.makeCodeTypeName(getConstrainClassPath(env, opt_cc)) :: info;
        info := getElementAttributeValues(element, isPublic, quoteNames, info);
        info := ValuesUtil.makeString(cmt) :: info;
        info := ValuesUtil.makeCodeTypeNameStr(name) :: info;
        info := ValuesUtil.makeCodeTypeName(ty) :: info;
        info := ValuesUtil.makeString(Dump.unparseRestrictionStr(restriction)) :: info;
        info := ValuesUtil.makeString("cl") :: info;

        infos := ValuesUtil.makeArray(info) :: infos;
      then
        infos;

    else infos;
  end match;
end getElementInfo;

public function getElementAttributeValues
  input Absyn.Element element;
  input Boolean isPublic;
  input Boolean quoteNames;
  input output list<Values.Value> attrValues;
protected
  Absyn.ElementAttributes attr;
  Values.Value vis_val, final_val, flow_val, stream_val, repl_val, var_val, io_val, dir_val;
algorithm
  attrValues := match element
    case Absyn.Element.ELEMENT()
      algorithm
        attr := match element.specification
          case Absyn.ElementSpec.CLASSDEF(class_ = Absyn.Class.CLASS(body = Absyn.ClassDef.DERIVED(attributes = attr))) then attr;
          case Absyn.ElementSpec.COMPONENTS(attributes = attr) then attr;
        end match;

        attrValues := ValuesUtil.makeString(attrVariabilityStr(attr)) ::
                      ValuesUtil.makeString(innerOuterStr(element.innerOuter)) ::
                      ValuesUtil.makeString(attrDirectionStr(attr)) ::
                      attrValues;

        if quoteNames then
          attrValues := ValuesUtil.makeString(String(element.finalPrefix)) ::
                        ValuesUtil.makeString(String(attr.flowPrefix)) ::
                        ValuesUtil.makeString(String(attr.streamPrefix)) ::
                        ValuesUtil.makeString(String(AbsynUtil.isElementReplaceable(element))) ::
                        attrValues;
        else
          attrValues := ValuesUtil.makeBoolean(element.finalPrefix) ::
                        ValuesUtil.makeBoolean(attr.flowPrefix) ::
                        ValuesUtil.makeBoolean(attr.streamPrefix) ::
                        ValuesUtil.makeBoolean(AbsynUtil.isElementReplaceable(element)) ::
                        attrValues;
        end if;

        attrValues := ValuesUtil.makeString(if isPublic then "public" else "protected") :: attrValues;
      then
        attrValues;
  end match;
end getElementAttributeValues;

public function qualifyPath
  input GraphicEnvCache inEnv;
  input Absyn.Path inPath;
  output Absyn.Path outPath;
protected
  String n;
algorithm
  outPath := match inPath
    case Absyn.FULLYQUALIFIED(__) then inPath;
    case Absyn.IDENT("Real") then inPath;
    case Absyn.IDENT("Integer") then inPath;
    case Absyn.IDENT("Boolean") then inPath;
    case Absyn.IDENT("String") then inPath;
    else
      algorithm
        try
          if Flags.isSet(Flags.NF_API) then
            (_, outPath) := Interactive.mkFullyQual(inEnv, inPath);
          else
            outPath := qualifyType(Interactive.envFromGraphicEnvCache(inEnv), inPath);
          end if;
        else
          outPath := inPath;
        end try;
      then
        outPath;
  end match;
end qualifyPath;

public function getConstrainClassPath
  input GraphicEnvCache inEnv;
  input Option<Absyn.ConstrainClass> occ;
  output Absyn.Path path;
algorithm
  path := matchcontinue occ
    case SOME(Absyn.CONSTRAINCLASS(elementSpec = Absyn.EXTENDS(path = path)))
      then qualifyPath(inEnv, path);
    else Absyn.Path.IDENT("$Any");
  end matchcontinue;
end getConstrainClassPath;

public function qualifyType
  input FGraph.Graph inEnv;
  input Absyn.Path p;
  output Absyn.Path fqp = p;
protected
  Option<Absyn.Path> oenv_path;
  Absyn.Path env_path, tp_path, pkg_path;
  String tp_name;
  FGraph.Graph env;
algorithm
  if AbsynUtil.pathIsFullyQualified(p) then
    return;
  end if;

  fqp := matchcontinue ()
    // Look up the full type path.
    case ()
      algorithm
        (_, _, env) := Lookup.lookupClass(FCore.emptyCache(), inEnv, p);
        oenv_path := FGraph.getScopePath(env);

        // If the type was found in a non-top scope, construct the fully
        // qualified path of the type. Otherwise the type is already fully
        // qualified, and we can use it as it is.
        if isSome(oenv_path) then
          SOME(env_path) := oenv_path;
          tp_name := AbsynUtil.pathLastIdent(p);
          tp_path := AbsynUtil.suffixPath(env_path, tp_name);
        else
          tp_path := p;
        end if;
      then
        tp_path;

    // If the first case fails, i.e. if the type name doesn't reference an
    // existing type, try to construct a fully qualified path to where the
    // type should be, but isn't.
    case ()
      algorithm
        // Look up the first identifier in the type name.
        pkg_path := AbsynUtil.pathFirstPath(p);
        (_, _, env) := Lookup.lookupClass(FCore.emptyCache(), inEnv, pkg_path);
        oenv_path := FGraph.getScopePath(env);

        // Replace the first identifier in the type name with the path to
        // the found class. If the class was found at top-scope, i.e. if
        // oenv_path is NONE, then the type name is already fully qualified.
        if isSome(oenv_path) then
          SOME(env_path) := oenv_path;
          tp_path := AbsynUtil.joinPaths(env_path, p);
        else
          tp_path := p;
        end if;
      then
        tp_path;

    else p;
  end matchcontinue;
end qualifyType;

protected function arrayDimensionStr
"prints array dimensions to a string"
  input Option<Absyn.ArrayDim> ad;
  output String str;
algorithm
  str:=match(ad)
  local Absyn.ArrayDim adim;
    case(SOME(adim)) equation
      str = stringDelimitList(List.map(adim,Dump.printSubscriptStr),",");
    then str;
    else "";
  end match;
end arrayDimensionStr;

public function getElementsInfo
  input list<Absyn.Element> elements;
  input Boolean isPublic;
  input Boolean useQuotes;
  input Boolean onlyComponents;
  input Interactive.GraphicEnvCache env;
  input output list<Values.Value> infos = {};
algorithm
  for elem in listReverse(elements) loop
    infos := getElementInfo(elem, isPublic, useQuotes, onlyComponents, env, infos);
  end for;
end getElementsInfo;

public function keywordReplaceable
"Returns true if RedeclareKeywords contains replaceable."
  input Option<Absyn.RedeclareKeywords> inAbsynRedeclareKeywordsOption;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inAbsynRedeclareKeywordsOption)
    case (SOME(Absyn.REPLACEABLE())) then true;
    case (SOME(Absyn.REDECLARE_REPLACEABLE())) then true;
    else false;
  end match;
end keywordReplaceable;

public function innerOuterStr
"Helper function to getElementInfo, retrieve the inner outer string."
  input Absyn.InnerOuter inInnerOuter;
  output String outString;
algorithm
  outString:=
  match (inInnerOuter)
    case (Absyn.INNER()) then "inner";
    case (Absyn.OUTER()) then "outer";
    case (Absyn.NOT_INNER_OUTER()) then "none";
    case (Absyn.INNER_OUTER()) then "innerouter";
  end match;
end innerOuterStr;

public function attrFlowStr
"Helper function to get_component_info,
  retrieve flow attribite as bool string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    local
      String res;
      Boolean f;
    case (Absyn.ATTR(flowPrefix = f))
      equation
        res = boolString(f);
      then
        res;
  end match;
end attrFlowStr;

public function attrStreamStr
"Helper function to get_component_info,
  retrieve stream attribute as bool string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    local
      String res;
      Boolean s;
    case (Absyn.ATTR(streamPrefix = s))
      equation
        res = boolString(s);
      then
        res;
  end match;
end attrStreamStr;

public function attrParallelismStr
"Helper function to get_component_info,
  retrieve parallelism as a string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    case (Absyn.ATTR(parallelism = Absyn.PARGLOBAL())) then "parglobal";
    case (Absyn.ATTR(parallelism = Absyn.PARLOCAL())) then "parlocal";
    case (Absyn.ATTR(parallelism = Absyn.NON_PARALLEL())) then "";
  end match;
end attrParallelismStr;

public function attrVariabilityStr
"Helper function to get_component_info,
  retrieve variability as a string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    case (Absyn.ATTR(variability = Absyn.VAR())) then "unspecified";
    case (Absyn.ATTR(variability = Absyn.DISCRETE())) then "discrete";
    case (Absyn.ATTR(variability = Absyn.PARAM())) then "parameter";
    case (Absyn.ATTR(variability = Absyn.CONST())) then "constant";
  end match;
end attrVariabilityStr;

public function attrDimensionStr
"Helper function to getElementInfo,
  retrieve dimension as a string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
      local Absyn.ArrayDim ad;
    case (Absyn.ATTR(arrayDim = ad)) then arrayDimensionStr(SOME(ad));
  end match;
end attrDimensionStr;

public function attrDirectionStr
"Helper function to get_component_info,
  retrieve direction as a string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    case (Absyn.ATTR(direction = Absyn.INPUT())) then "input";
    case (Absyn.ATTR(direction = Absyn.OUTPUT())) then "output";
    case (Absyn.ATTR(direction = Absyn.BIDIR())) then "unspecified";
  end match;
end attrDirectionStr;

public function getConstrainingClassComment
  input Option<Absyn.ConstrainClass> constrainingClass;
  output String comment;
algorithm
  comment := match constrainingClass
    case SOME(Absyn.ConstrainClass.CONSTRAINCLASS(
      comment = SOME(Absyn.Comment.COMMENT(comment = SOME(comment))))) then comment;
    else "";
  end match;
end getConstrainingClassComment;

public function getComponentComment
  input Absyn.ComponentItem component;
  input Absyn.Element element;
  output String comment;
algorithm
  // The Modelica syntax allows a comment on both the element and the
  // constraining clause, but the specification recommends putting it on
  // the constraining clause. So check the constraining clause first.
  comment := getConstrainingClassComment(AbsynUtil.getElementConstrainingClass(element));

  if stringEmpty(comment) then
    comment := getClassCommentInCommentOpt(component.comment);
  end if;
end getComponentComment;

public function getComponentItemsNameAndComment
" separated list of all component names and comments (if any)."
  input list<Absyn.ComponentItem> inComponents;
  input Absyn.Element inElement;
  output list<list<String>> outStrings = {};
protected
  String name, cmt_str;
algorithm
  for comp in listReverse(inComponents) loop
    _ := match comp
      case Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name))
        algorithm
          cmt_str := getComponentComment(comp, inElement);
          cmt_str := StringUtil.quote(cmt_str);

          outStrings := {name, cmt_str} :: outStrings;
        then
          ();

      else ();
    end match;
  end for;
end getComponentItemsNameAndComment;

public function getComponentItemsName
" separated list of all component names."
  input list<Absyn.ComponentItem> inComponents;
  input Boolean inQuoteNames "Adds quotes around the component names if true.";
  output list<String> outStrings = {};
protected
  String name;
algorithm
  for comp in listReverse(inComponents) loop
    _ := match comp
      case Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name))
        algorithm
          outStrings := (if inQuoteNames then
            stringAppendList({"\"", name, "\""}) else
            stringAppendList({name})) :: outStrings;
        then
          ();

      else ();
    end match;
  end for;
end getComponentItemsName;

protected function replaceClassInProgram2
  input Absyn.Class inClass;
  input String inClassName;
  output Boolean outReplace;
protected
  String cls_name;
algorithm
  Absyn.CLASS(name = cls_name) := inClass;
  outReplace := cls_name == inClassName;
end replaceClassInProgram2;

public function replaceClassInProgram
" This function takes a Class and a Program and replaces the class
   definition at the top level in the program by the class definition of
   the Class. It also updates the functionlist for the symboltable if needed."
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Program outProgram;
protected
  String cls_name1, cls_name2;
  list<Absyn.Class> clst, clsFilter;
  Absyn.Within w;
  Boolean replaced;
  Absyn.Class cls;
algorithm
  Absyn.CLASS(name = cls_name1) := inClass;
  Absyn.PROGRAM(classes = clst, within_ = w) := inProgram;
  if mergeAST then
    clsFilter := List.filterOnTrue(clst, function replaceClassInProgram2(inClassName = cls_name1));
    if listEmpty(clsFilter)
    then
      cls := inClass;
    else
      cls::_ := clsFilter;
      cls := mergeClasses(inClass, cls);
    end if;
  else
   cls := inClass;
  end if;
  (clst, replaced) := List.replaceOnTrue(cls, clst,
    function replaceClassInProgram2(inClassName = cls_name1));

  if not replaced then
    clst := List.appendElt(inClass, clst);
  end if;

  outProgram := Absyn.PROGRAM(clst, w);
end replaceClassInProgram;

public function insertClassInProgram
" This function inserts the class into the Program at the scope given by
   the within argument. If the class referenced by the within argument is
   not defined, the function prints an error message and fails."
  input Absyn.Class inClass;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inClass,inWithin,inProgram)
    local
      Absyn.Class c2,c3,c1;
      Absyn.Program pnew,p;
      Absyn.Within w;
      String n1,s1,s2,name;
      list<Absyn.Path> paths;

    case (c1,(w as Absyn.WITHIN(path = Absyn.QUALIFIED(name = n1))),p as Absyn.PROGRAM())
      equation
        c2 = getClassInProgram(n1, p);
        c3 = insertClassInClass(c1, w, c2, mergeAST);
        pnew = updateProgram(Absyn.PROGRAM({c3},Absyn.TOP()), p, mergeAST);
      then
        pnew;

    case (c1,(w as Absyn.WITHIN(path = Absyn.IDENT(name = n1))),p as Absyn.PROGRAM())
      equation
        c2 = getClassInProgram(n1, p);
        c3 = insertClassInClass(c1, w, c2, mergeAST);
        pnew = updateProgram(Absyn.PROGRAM({c3},Absyn.TOP()), p, mergeAST);
      then
        pnew;

    case (_,Absyn.WITHIN(path=Absyn.QUALIFIED(name="OpenModelica")),p) then p;

    case ((Absyn.CLASS(name = name)),w,p)
      equation
        s1 = Dump.unparseWithin(w);
        /* adeas31 2012-01-25: false indicates that the classnamesrecursive doesn't look into protected sections */
        /* adeas31 2016-11-29: false indicates that the classnamesrecursive doesn't look for constants */
        (_, paths) = getClassNamesRecursive(NONE(), p, false, false, {});
        s2 = stringAppendList(List.map1r(list(AbsynUtil.pathString(p) for p in paths),stringAppend,"\n  "));
        Error.addMessage(Error.INSERT_CLASS, {name,s1,s2});
      then
        fail();

  end matchcontinue;
end insertClassInProgram;

protected function insertClassInClass "
   This function takes a class to update (the first argument)  and an inner
   class (which is either replacing
   an earlier class or is a new inner definition) and a within statement
   pointing inside the class (including the class itself in the reference),
   and updates the class with the inner class.
"
  input Absyn.Class inClass1;
  input Absyn.Within inWithin2;
  input Absyn.Class inClass3;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Class outClass;
algorithm
  outClass := match (inClass1,inWithin2,inClass3)
    local
      Absyn.Class cnew,c1,c2,cinner,cnew_1;
      String name,name2;
      Absyn.Path path;

    case (c1,Absyn.WITHIN(path = Absyn.IDENT()),c2)
      then replaceInnerClass(c1, c2, mergeAST);

    case (c1,Absyn.WITHIN(path = Absyn.QUALIFIED(path = path)),c2)
      equation
        name2 = getFirstIdentFromPath(path);
        cinner = getInnerClass(c2, name2);
        cnew = insertClassInClass(c1, Absyn.WITHIN(path), cinner, mergeAST);
      then replaceInnerClass(cnew, c2, mergeAST);

  end match;
end insertClassInClass;

protected function getFirstIdentFromPath "
   This function takes a `Path` as argument and returns the first `Ident\'
   of the path.
"
  input Absyn.Path inPath;
  output Absyn.Ident outIdent;
algorithm
  outIdent:=
  match (inPath)
    local
      String name;
      Absyn.Path path;
    case (Absyn.IDENT(name = name)) then name;
    case (Absyn.QUALIFIED(name = name)) then name;
  end match;
end getFirstIdentFromPath;

protected function classElementItemIsNamed
  input String inClassName;
  input Absyn.ElementItem inElement;
  output Boolean outIsNamed;
algorithm
  outIsNamed := match(inElement)
    local
      String name;

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification =
        Absyn.CLASSDEF(class_ = (Absyn.CLASS(name = name)))))
      then inClassName == name;

    else false;
  end match;
end classElementItemIsNamed;

protected function replaceInnerClass
"This function takes two class definitions. The first one is
  inserted/replaced as a local class inside the second one."
  input Absyn.Class inClass1;
  input Absyn.Class inClass2;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass1,inClass2)
    local
      list<Absyn.ElementItem> publst,publst2,prolst,prolst2;
      list<Absyn.ClassPart> parts2,parts;
      Absyn.Class c1;
      String a,bcname;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      SourceInfo file_info;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;

    // a class with parts - we can find the element in the public list
    case (c1,outClass as Absyn.CLASS(body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann=ann,comment = cmt)))
      equation
        publst = getPublicList(parts);
        (publst2, true) = replaceClassInElementitemlist(publst, c1, mergeAST);
        parts2 = replacePublicList(parts, publst2);
        outClass.body = Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then
        outClass;

    // a class with parts - we can find the element in the protected list
    case (c1,outClass as Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann=ann,comment = cmt),info = file_info))
      equation
        prolst = getProtectedList(parts);
        (prolst2, true) = replaceClassInElementitemlist(prolst, c1, mergeAST);
        parts2 = replaceProtectedList(parts, prolst2);
        outClass.body = Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then
        outClass;

    // a class with parts - we cannot find the element in the public or protected list, add it to the public list
    case (c1,outClass as Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann=ann,comment = cmt),info = file_info))
      equation
        publst = getPublicList(parts);
        publst = addClassInElementitemlist(publst, c1);
        parts2 = replacePublicList(parts, publst);
        outClass.body = Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then
        outClass;

    // an extended class with parts: model extends M end M; - we can find the element in the public list
    case (c1,outClass as Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications = modif,parts = parts,ann=ann,comment = cmt)))
      equation
        publst = getPublicList(parts);
        (publst2, true) = replaceClassInElementitemlist(publst, c1, mergeAST);
        parts2 = replacePublicList(parts, publst2);
        outClass.body = Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann);
      then
        outClass;

    // an extended class with parts: model extends M end M; - we can find the element in the protected list
    case (c1,outClass as Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications = modif,parts = parts,ann=ann,comment = cmt)))
      equation
        prolst = getProtectedList(parts);
        (prolst2, true) = replaceClassInElementitemlist(prolst, c1, mergeAST);
        parts2 = replaceProtectedList(parts, prolst2);
        outClass.body = Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann);
      then
        outClass;

    // an extended class with parts: model extends M end M; - we cannot find the element in the public or protected list, add it to the public list
    case (c1,outClass as Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications = modif,parts = parts,ann=ann,comment = cmt)))
      equation
        publst = getPublicList(parts);
        publst = addClassInElementitemlist(publst, c1);
        parts2 = replacePublicList(parts, publst);
        outClass.body = Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann);
      then
        outClass;

    else
      equation
        Print.printBuf("Failed in replaceInnerClass\n");
      then
        fail();
  end matchcontinue;
end replaceInnerClass;

protected function replaceClassInElementitemlist
"This function takes an Element list and a Class and returns a modified
  element list where the class definition of the class is updated or added."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Class inClass;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output list<Absyn.ElementItem> outAbsynElementItemLst;
  output Boolean replaced "true signals a replacement, false nothing changed!";
algorithm
  (outAbsynElementItemLst, replaced) := match (inAbsynElementItemLst,inClass)
    local
      list<Absyn.ElementItem> res,xs;
      Absyn.ElementItem a1,e1;
      Absyn.Class c, c1, c2;
      String name1,name;
      Boolean a,e;
      Option<Absyn.RedeclareKeywords> b;
      SourceInfo info;
      Option<Absyn.ConstrainClass> h;
      Absyn.InnerOuter io;

    case (((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = a,redeclareKeywords = b,innerOuter = io,specification = Absyn.CLASSDEF(replaceable_ = e,class_ = c1 as Absyn.CLASS(name = name1)),constrainClass = h))) :: xs),(c2 as Absyn.CLASS(name = name)))
      guard stringEq(name1, name)
      equation
        c = if mergeAST then mergeClasses(c2, c1) else c2;
        Absyn.CLASS(info = info) = c;
      then
        (Absyn.ELEMENTITEM(Absyn.ELEMENT(a,b,io,Absyn.CLASSDEF(e,c),info /* The new CLASS might have update info */,h)) :: xs, true);

    case ((e1 :: xs),c)
      equation
        (res, replaced) = replaceClassInElementitemlist(xs, c, mergeAST);
      then
        (e1 :: res, replaced);

    else ({}, false);

  end match;
end replaceClassInElementitemlist;

protected function addClassInElementitemlist
"This function takes an Element list and a Class and returns a modified
  element list where the class definition of the class is updated or added."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Class inClass;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
protected
  Absyn.Info info;
algorithm
  Absyn.CLASS(info=info) := inClass;
  outAbsynElementItemLst := listAppend(inAbsynElementItemLst,
          {Absyn.ELEMENTITEM(
             Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),Absyn.CLASSDEF(false,inClass),
             info,NONE()))});
end addClassInElementitemlist;

protected function getInnerClass
"This function takes a class name and a class and
  returns the inner class definition having that name."
  input Absyn.Class inClass;
  input Absyn.Ident inIdent;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass,inIdent)
    local
      list<Absyn.ElementItem> publst,prolst;
      Absyn.Class c1,c;
      list<Absyn.ClassPart> parts;
      String name,str,s1;
      Integer handle;

    // class found in public
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),name)
      equation
        publst = getPublicList(parts);
        c1 = getClassFromElementitemlist(publst, name);
      then
        c1;

    // class found in protected
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),name)
      equation
        prolst = getProtectedList(parts);
        c1 = getClassFromElementitemlist(prolst, name);
      then
        c1;

    // class found in public
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),name)
      equation
        publst = getPublicList(parts);
        c1 = getClassFromElementitemlist(publst, name);
      then
        c1;

    // class found in protected
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),name)
      equation
        prolst = getProtectedList(parts);
        c1 = getClassFromElementitemlist(prolst, name);
      then
        c1;

/* Does nothing
    case (c as Absyn.CLASS(),name)
      equation
        handle = Print.saveAndClearBuf();
        Print.printBuf("InteractiveUtil.getInnerClass failed, c:");
        Dump.dump(Absyn.PROGRAM({c},Absyn.TOP()));
        Print.printBuf("name :");
        Print.printBuf(name);
        Print.clear(); // Print.getString();
        Print.restoreBuf(handle);
      then
        fail();
*/
  end matchcontinue;
end getInnerClass;

public function replacePublicList
" This function replaces the ElementItem list in
   the ClassPart list, and returns the updated list.
   If no public list is available, one is created."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst := match (inAbsynClassPartLst,inAbsynElementItemLst)
    local
      list<Absyn.ClassPart> rest_1,rest,ys,xs;
      Absyn.ClassPart lst,x;
      list<Absyn.ElementItem> newpublst,new,newpublist;

    case (((Absyn.PUBLIC()) :: rest),newpublst)
      equation
        rest_1 = deletePublicList(rest);
      then
        (Absyn.PUBLIC(newpublst) :: rest_1);

    case ((x :: xs),new)
      equation
        ys = replacePublicList(xs, new);
      then
        (x :: ys);

    case ({},newpublist) then {Absyn.PUBLIC(newpublist)};

  end match;
end replacePublicList;

public function replaceProtectedList "
  This function replaces the `ElementItem\' list in the `ClassPart\' list,
  and returns the updated list.
  If no protected list is available, one is created.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst := match (inAbsynClassPartLst,inAbsynElementItemLst)
    local
      list<Absyn.ClassPart> rest_1,rest,ys,xs;
      Absyn.ClassPart lst,x;
      list<Absyn.ElementItem> newprotlist,new;

    case (((Absyn.PROTECTED()) :: rest),newprotlist)
      equation
        rest_1 = deleteProtectedList(rest);
      then
        (Absyn.PROTECTED(newprotlist) :: rest_1);

    case ((x :: xs),new)
      equation
        ys = replaceProtectedList(xs, new);
      then
        (x :: ys);

    case ({},newprotlist) then {Absyn.PROTECTED(newprotlist)};

  end match;
end replaceProtectedList;

public function replaceEquationList "
   This function replaces the `EquationItem\' list in the `ClassPart\' list,
   and returns the updated list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  match (inAbsynClassPartLst,inAbsynEquationItemLst)
    local
      Absyn.ClassPart lst,x;
      list<Absyn.ClassPart> rest,ys,xs;
      list<Absyn.EquationItem> newequationlst,new;
    case (((Absyn.EQUATIONS()) :: rest),newequationlst) then (Absyn.EQUATIONS(newequationlst) :: rest);
    case ((x :: xs),new)
      equation
        ys = replaceEquationList(xs, new);
      then
        (x :: ys);
    case ({},_) then {};
  end match;
end replaceEquationList;

protected function deletePublicList "
  Deletes all PULIC classparts from the list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  match (inAbsynClassPartLst)
    local
      list<Absyn.ClassPart> res,xs;
      Absyn.ClassPart x;
    case ({}) then {};
    case ((Absyn.PUBLIC() :: xs))
      equation
        res = deletePublicList(xs);
      then
        res;
    case ((x :: xs))
      equation
        res = deletePublicList(xs);
      then
        (x :: res);
  end match;
end deletePublicList;

protected function deleteProtectedList "
  Deletes all PROTECTED classparts from the list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  match (inAbsynClassPartLst)
    local
      list<Absyn.ClassPart> res,xs;
      Absyn.ClassPart x;
    case ({}) then {};
    case ((Absyn.PROTECTED() :: xs))
      equation
        res = deleteProtectedList(xs);
      then
        res;
    case ((x :: xs))
      equation
        res = deleteProtectedList(xs);
      then
        (x :: res);
  end match;
end deleteProtectedList;

public function getPublicList "
  This function takes a ClassPart List and returns an appended list of
  all public lists.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  match (inAbsynClassPartLst)
    local
      list<Absyn.ElementItem> res2,res,res1,ys;
      list<Absyn.ClassPart> rest,xs;
      Absyn.ClassPart x;
    case ({}) then {};
    case (Absyn.PUBLIC(contents = res1) :: rest)
      equation
        res2 = getPublicList(rest);
        res = listAppend(res1, res2);
      then
        res;
    case ((_ :: xs))
      equation
        ys = getPublicList(xs);
      then
        ys;
  end match;
end getPublicList;

public function getProtectedList "
  This function takes a ClassPart List and returns an appended list of
  all protected lists."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  match (inAbsynClassPartLst)
    local
      list<Absyn.ElementItem> res2,res,res1,ys;
      list<Absyn.ClassPart> rest,xs;
      Absyn.ClassPart x;
    case ({}) then {};
    case (Absyn.PROTECTED(contents = res1) :: rest)
      equation
        res2 = getProtectedList(rest);
        res = listAppend(res1, res2);
      then
        res;
    case ((_ :: xs))
      equation
        ys = getProtectedList(xs);
      then
        ys;
  end match;
end getProtectedList;

public function getEquationList "This function takes a ClassPart List and returns the first EquationItem
  list of the class."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm
  outAbsynEquationItemLst := match (inAbsynClassPartLst)
    local
      list<Absyn.EquationItem> lst,ys;
      list<Absyn.ClassPart> rest,xs;
      Absyn.ClassPart x;
    case (Absyn.EQUATIONS(contents = lst) :: _) then lst;
    case ((_ :: xs))
      equation
        ys = getEquationList(xs);
      then
        ys;
    else fail();
  end match;
end getEquationList;

protected function getClassFromElementitemlist "
  This function takes an ElementItem list and an Ident and returns the
  class definition among the element list having that identifier.
"
  input list<Absyn.ElementItem> inElements;
  input Absyn.Ident inIdent;
  output Absyn.Class outClass;
protected
  Absyn.ElementItem elem;
algorithm
  elem := List.getMemberOnTrue(inIdent, inElements, classElementItemIsNamed);
  Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification =
    Absyn.CLASSDEF(class_ = outClass))) := elem;
end getClassFromElementitemlist;

protected function classInProgram
"This function takes a name and a Program and returns
  true if the name exists as a top class in the program."
  input String name;
  input Absyn.Program p;
  output Boolean b;
algorithm
  b := match p
    local
      String str;
    case Absyn.PROGRAM()
      algorithm
        for cl in p.classes loop
          Absyn.CLASS(name=str) := cl;
          if str == name then
            b := true;
            return;
          end if;
        end for;
      then false;
  end match;
end classInProgram;

public function getPathedClassInProgram
"This function takes a Path and a Program and retrieves the
  class definition referenced by the Path from the Program.
  If enclOnErr is true and such class doesn't exist return enclosing class."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Boolean enclOnErr = false;
  input Boolean showError = false;
  output Absyn.Class outClass;
algorithm
  outClass := matchcontinue ()
    case () then getPathedClassInProgramWork(inPath, inProgram, enclOnErr);
    case () then getPathedClassInProgramWork(inPath, FBuiltin.getInitialFunctions(), enclOnErr);

    else
      algorithm
        if showError then
          Error.addMessage(Error.LOOKUP_ERROR,
            {AbsynUtil.pathString(inPath), "<TOP>"});
        end if;
      then
        fail();

  end matchcontinue;
end getPathedClassInProgram;

protected function getPathedClassInProgramWork
"This function takes a Path and a Program and retrieves the
  class definition referenced by the Path from the Program.
  If enclOnErr is true and such class doesn't exist return enclosing class."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Boolean enclOnErr;
  output Absyn.Class outClass;
algorithm
  outClass := match inPath
    local
      Absyn.Class c;
      String str;
      Absyn.Path path;

    case Absyn.IDENT(name = str)
      then
        getClassInProgram(str, inProgram);

    case Absyn.FULLYQUALIFIED(path)
      then
        getPathedClassInProgram(path, inProgram, enclOnErr);

    case Absyn.QUALIFIED(name = str, path = path)
      equation
        c = getClassInProgram(str, inProgram);
      then
        if enclOnErr then getPathedClassInProgramWorkNoThrow(path, c)
                     else getPathedClassInProgramWorkThrow(path, c);

  end match;
end getPathedClassInProgramWork;

protected function getPathedClassInProgramWorkThrow
"This function takes a Path and a Program and retrieves the
  class definition referenced by the Path from the Program."
  input Absyn.Path inPath;
  input Absyn.Class inClass;
  output Absyn.Class outClass;
algorithm
  outClass := match inPath
    local
      Absyn.Class c;
      String str;
      Absyn.Path path;

    case Absyn.IDENT(name = str)
      then
        getClassInClass(str, inClass);


    case Absyn.FULLYQUALIFIED(path)
      then
        getPathedClassInProgramWorkThrow(path, inClass);

    case Absyn.QUALIFIED(name = str, path = path)
      equation
        c = getClassInClass(str, inClass);
      then
        getPathedClassInProgramWorkThrow(path, c);

  end match;
end getPathedClassInProgramWorkThrow;

protected function getPathedClassInProgramWorkNoThrow
"Retrieves the class definition referenced by the Path from the Class A.
 If such class doesn't exist return Class A."
  input Absyn.Path inPath;
  input Absyn.Class inClass;
  output Absyn.Class outClass;
algorithm
  try
    outClass := match inPath
      local
        Absyn.Class c;
        String str;
        Absyn.Path path;

      case Absyn.IDENT(name = str)
        then
          getClassInClass(str, inClass);

      case Absyn.FULLYQUALIFIED(path)
        then
          getPathedClassInProgramWorkNoThrow(path, inClass);

      case Absyn.QUALIFIED(name = str, path = path)
        equation
          c = getClassInClass(str, inClass);
        then
          getPathedClassInProgramWorkNoThrow(path, c);

    end match;
  else
    outClass := inClass;
  end try;
end getPathedClassInProgramWorkNoThrow;


protected function getClassInClass
" This function takes a Path and a Class
   and returns the class with the name Path.
   If that class does not exist, the function fails"
  input String inString;
  input Absyn.Class inClass;
  output Absyn.Class outClass;
algorithm
  outClass := List.find1(getClassesInClass(inClass), compareClassName, inString);
end getClassInClass;

protected function getClassesInClass
"This function takes a Class definition and returns
  a list of local Class definitions of that class."
  input Absyn.Class inClass;
  output list<Absyn.Class> outAbsynClassLst;
algorithm
  outAbsynClassLst := match inClass
    local
      list<Absyn.Class> res;
      Absyn.Path modelpath,path;
      Absyn.Program p;
      list<Absyn.ClassPart> parts;

    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        res = getClassesInParts(parts);
      then
        res;

    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        res = getClassesInParts(parts);
      then
        res;

    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = Absyn.TPATH(_,_)))
      equation
        /* adrpo 2009-10-27: do not dive into derived classes!
        (cdef,newpath) = lookupClassdef(path, modelpath, p);
        res = getClassesInClass(cdef);
        */
        res = {};
      then
        res;

  end match;
end getClassesInClass;

public function getClassesInParts
"Helper function to getClassesInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.Class> outAbsynClassLst;
algorithm
  outAbsynClassLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.Class> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;

    case {} then {};

    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation
        l1 = getClassesInParts(rest);
        l2 = getClassesInElts(elts);
        res = listAppend(l1, l2);
      then
        res;

    case ((Absyn.PROTECTED(contents = elts) :: rest))
      equation
        l1 = getClassesInParts(rest);
        l2 = getClassesInElts(elts);
        res = listAppend(l1, l2);
      then
        res;

    case ((_ :: rest))
      equation
        res = getClassesInParts(rest);
      then
        res;

  end matchcontinue;
end getClassesInParts;

protected function getClassesInElts
"Helper function to getClassesInParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.Class> outAbsynClassLst;
algorithm
  outAbsynClassLst:=
  match (inAbsynElementItemLst)
    local
      list<Absyn.Class> res;
      Absyn.Class class_;
      list<Absyn.ElementItem> rest;

    case {} then {};

    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = class_))) :: rest))
      equation
        res = getClassesInElts(rest);
      then
        (class_ :: res);

    case ((_ :: rest))
      equation
        res = getClassesInElts(rest);
      then
        res;

  end match;
end getClassesInElts;

public function getClassInProgram
" This function takes a Path and a Program
   and returns the class with the name Path.
   If that class does not exist, the function fails"
  input String inString;
  input Absyn.Program inProgram;
  output Absyn.Class cl;
protected
  list<Absyn.Class> classes;
algorithm
  Absyn.PROGRAM(classes=classes) := inProgram;
  cl := List.find1(classes, compareClassName, inString);
end getClassInProgram;

protected function compareClassName
  input Absyn.Class cl;
  input String str;
  output Boolean b;
algorithm
  b := match (cl,str)
    local
      String c1name;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = c1name)),_)
      then stringEq(str, c1name);
    case (Absyn.CLASS(name = c1name),_)
      then stringEq(str, c1name);
  end match;
end compareClassName;

public function annotationListToAbsyn
"This function takes a list of NamedArg and returns an Absyn.Annotation.
  for instance {annotation = Placement( ...) } is converted to ANNOTATION(Placement(...))"
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Absyn.Annotation outAnnotation;
protected
  list<Absyn.ElementArg> args={};
algorithm
  for arg in inAbsynNamedArgLst loop
    args := match arg
      local
        Absyn.ElementArg eltarg;
        Absyn.Exp e;
        Absyn.Annotation annres;
        Absyn.NamedArg a;
        list<Absyn.NamedArg> al;
        String name;
      case Absyn.NAMEDARG(argName = "annotate",argValue = e)
        equation
          eltarg = recordConstructorToModification(e);
        then eltarg::args;
      case Absyn.NAMEDARG(argName = "comment") then args;
      else args;
    end match;
  end for;
  outAnnotation := Absyn.ANNOTATION(Dangerous.listReverseInPlace(args));
end annotationListToAbsyn;

protected function recordConstructorToModification
" This function takes a record constructor expression and translates
   it into a ElementArg. Since modifications must be named, only named
   arguments are treated in the record constructor."
  input Absyn.Exp inExp;
  output Absyn.ElementArg outElementArg;
algorithm
  outElementArg:=
  matchcontinue (inExp)
    local
      list<Absyn.ElementArg> eltarglst;
      Absyn.ElementArg res,emod;
      Absyn.ComponentRef cr;
      list<Absyn.NamedArg> nargs;
      Absyn.Exp e;
      Absyn.Path p;

    /* Covers the case annotate=Diagram(SOMETHING(x=1,y=2)) */
    case (Absyn.CALL(function_ = cr,functionArgs = Absyn.FUNCTIONARGS(args = {(e as Absyn.CALL())},argNames = nargs)))
      equation
        eltarglst = List.map(nargs, namedargToModification);
        emod = recordConstructorToModification(e);
        p = AbsynUtil.crefToPath(cr);
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),p,SOME(Absyn.CLASSMOD((emod :: eltarglst),Absyn.NOMOD())),NONE(),AbsynUtil.dummyInfo);
      then
        res;
    /* Covers the case annotate=Diagram(x=1,y=2) */
    case (Absyn.CALL(function_ = cr,functionArgs = Absyn.FUNCTIONARGS(args = {},argNames = nargs)))
      equation
        eltarglst = List.map(nargs, namedargToModification);
        p = AbsynUtil.crefToPath(cr);
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),p,SOME(Absyn.CLASSMOD(eltarglst,Absyn.NOMOD())),NONE(),AbsynUtil.dummyInfo);
      then
        res;
    /* Covers the case annotate=Diagram(1) */
    case (Absyn.CALL(function_ = cr,functionArgs = Absyn.FUNCTIONARGS(args = {e}, argNames = {})))
      equation
        p = AbsynUtil.crefToPath(cr);
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),p,SOME(Absyn.CLASSMOD({},Absyn.EQMOD(e,AbsynUtil.dummyInfo))),NONE(),AbsynUtil.dummyInfo);
      then
        res;
    else
      equation
        Print.printBuf("InteractiveUtil.recordConstructorToModification failed, exp=");
        Print.printBuf(Dump.printExpStr(inExp));
        Print.printBuf("\n");
      then
        fail();
  end matchcontinue;
end recordConstructorToModification;

protected function namedargToModification
"This function takes a NamedArg and translates it into a ElementArg."
  input Absyn.NamedArg inNamedArg;
  output Absyn.ElementArg outElementArg;
algorithm
  outElementArg:=
  matchcontinue (inNamedArg)
    local
      list<Absyn.ElementArg> elts;
      Absyn.ComponentRef cr;
      Absyn.ElementArg res;
      String id;
      Absyn.Exp c,e;
      list<Absyn.NamedArg> nargs;
    case (Absyn.NAMEDARG(argName = id,argValue = (c as Absyn.CALL(functionArgs = Absyn.FUNCTIONARGS(args = {})))))
      equation
        Absyn.MODIFICATION(modification = SOME(Absyn.CLASSMOD(elts,_)), comment = NONE()) = recordConstructorToModification(c);
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT(id),SOME(Absyn.CLASSMOD(elts,Absyn.NOMOD())),NONE(),AbsynUtil.dummyInfo);
      then
        res;
    case (Absyn.NAMEDARG(argName = id,argValue = e))
      equation
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT(id),SOME(Absyn.CLASSMOD({},Absyn.EQMOD(e,AbsynUtil.dummyInfo /*Bad*/))),NONE(),AbsynUtil.dummyInfo);
      then
        res;
    else
      equation
        Print.printBuf("- InteractiveUtil.namedargToModification failed\n");
      then
        fail();
  end matchcontinue;
end namedargToModification;

public function getLocalVariables
"Returns the string list of local varibales defined with in the algorithm."
  input Absyn.Class inClass;
  input Boolean inBoolean;
  input GraphicEnvCache inEnv;
  output String outList;
algorithm
  outList := match(inClass, inBoolean, inEnv)
    local
      String strList;
      GraphicEnvCache env;
      Boolean b;
      list<Absyn.ClassPart> parts;
      case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)), b, env)
      equation
        strList = getLocalVariablesInClassParts(parts, b, env);
      then
        strList;
    // check also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)), b, env)
      equation
        strList = getLocalVariablesInClassParts(parts, b, env);
      then
        strList;
  end match;
end getLocalVariables;

protected function getLocalVariablesInClassParts
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Boolean inBoolean;
  input GraphicEnvCache inEnv;
  output String outList;
algorithm
  outList := matchcontinue (inAbsynClassPartLst, inBoolean, inEnv)
    local
      GraphicEnvCache env;
      Boolean b;
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.ClassPart> xs;
      String strList, strList1, strList2;
    case (Absyn.ALGORITHMS(contents = algs) :: xs, b, env)
      equation
        strList1 = getLocalVariablesInAlgorithmsItems(algs, b, env);
        strList = getLocalVariablesInClassParts(xs, b, env);
        strList2 = if strList == "" then strList1 else stringAppendList({strList1, ",", strList});
      then
        strList2;
    case ((_ :: xs), b, env)
      equation
        strList = getLocalVariablesInClassParts(xs, b, env);
      then
        strList;
    case ({}, _, _) then "";
  end matchcontinue;
end getLocalVariablesInClassParts;

protected function getLocalVariablesInAlgorithmsItems
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input Boolean inBoolean;
  input GraphicEnvCache inEnv;
  output String outList;
algorithm
  outList := matchcontinue (inAbsynAlgorithmItemLst, inBoolean, inEnv)
    local
      GraphicEnvCache env;
      Boolean b;
      String strList;
      list<Absyn.AlgorithmItem> xs;
      Absyn.Algorithm alg;
    case (Absyn.ALGORITHMITEM(algorithm_ = alg) :: _, b, env)
      equation
        strList = getLocalVariablesInAlgorithmItem(alg, b, env);
      then
        strList;
    case ((_ :: xs), b, env)
      equation
        strList = getLocalVariablesInAlgorithmsItems(xs, b, env);
      then
        strList;
    case ({}, _, _) then "";
  end matchcontinue;
end getLocalVariablesInAlgorithmsItems;

protected function getLocalVariablesInAlgorithmItem
  input Absyn.Algorithm inAbsynAlgorithmItem;
  input Boolean inBoolean;
  input GraphicEnvCache inEnv;
  output String outList;
algorithm
  outList := match (inAbsynAlgorithmItem, inBoolean, inEnv)
    local
      GraphicEnvCache env;
      Boolean b;
      String strList;
      list<Absyn.ElementItem> elsItems;
      list<Absyn.Element> els;
    case (Absyn.ALG_ASSIGN(value = Absyn.MATCHEXP(localDecls = elsItems)), b, env)
      equation
        els = getComponentsInElementitems(elsItems);
      then
        //Interactive.getComponentsInfo(els, b, "public", env);
        "";
    case (_, _, _) then "";
  end match;
end getLocalVariablesInAlgorithmItem;

protected function getClassnamesInClassList
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  input Boolean inShowProtected;
  input Boolean includeConstants;
  output list<String> outString;
algorithm
  outString:=
  match (inPath,inProgram,inClass,inShowProtected,includeConstants)
    local
      list<String> strlist;
      list<Absyn.ClassPart> parts;
      Absyn.Path inmodel,path;
      Absyn.Program p;
      Boolean b,c;

    case (_,_,Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),b,c)
      equation
        strlist = getClassnamesInParts(parts,b,c);
      then
        strlist;

    case (_,_,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),b,c)
      equation
        strlist = getClassnamesInParts(parts,b,c);
      then strlist;

    case (_,_,Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH())),_,_)
      equation
        //(cdef,newpath) = lookupClassdef(path, inmodel, p);
        //res = getClassnamesInClassList(newpath, p, cdef);
      then
        {};//res;

    case (_,_,Absyn.CLASS(body = Absyn.OVERLOAD()),_,_)
      equation
      then {};

    case (_,_,Absyn.CLASS(body = Absyn.ENUMERATION()),_,_)
      equation
      then {};

    case (_,_,Absyn.CLASS(body = Absyn.PDER()),_,_)
      equation
      then {};

  end match;
end getClassnamesInClassList;

protected function joinPaths
  input String child;
  input Absyn.Path parent;
  output Absyn.Path outPath;
algorithm
  outPath := match (child, parent)
    local
      Absyn.Path r, res;
      String c;
    case (c, r)
      equation
        res = AbsynUtil.joinPaths(r, Absyn.IDENT(c));
      then res;
  end match;
end joinPaths;

public function getClassNamesRecursive
"Returns a string with all the classes for a given path."
  input Option<Absyn.Path> inPath;
  input Absyn.Program inProgram;
  input Boolean inShowProtected;
  input Boolean includeConstants;
  input list<Absyn.Path> inAcc;
  output Option<Absyn.Path> opath;
  output list<Absyn.Path> paths;
algorithm
  (opath,paths) := matchcontinue (inPath,inProgram,inShowProtected,includeConstants,inAcc)
    local
      Absyn.Class cdef;
      String s1;
      list<String> strlst;
      Absyn.Path pp;
      Absyn.Program p;
      list<Absyn.Class> classes;
      list<Option<Absyn.Path>> result_path_lst;
      list<Absyn.Path> acc;
      Boolean b,c;

    case (SOME(pp),p,b,c,acc)
      equation
        acc = pp::acc;
        cdef = getPathedClassInProgram(pp, p);
        strlst = getClassnamesInClassList(pp, p, cdef, b, c);
        result_path_lst = List.map(List.map1(strlst, joinPaths, pp),Util.makeOption);
        (_,acc) = List.map3Fold(result_path_lst, getClassNamesRecursive, p, b, c, acc);
      then (inPath,acc);
    case (NONE(),p as Absyn.PROGRAM(classes=classes),b,c,acc)
      equation
        strlst = List.map(classes, AbsynUtil.getClassName);
        result_path_lst = List.mapMap(strlst, AbsynUtil.makeIdentPathFromString, Util.makeOption);
        (_,acc) = List.map3Fold(result_path_lst, getClassNamesRecursive, p, b, c, acc);
      then (inPath,acc);
    case (SOME(pp),_,_,_,_)
      equation
        s1 = AbsynUtil.pathString(pp);
        Error.addMessage(Error.LOOKUP_ERROR, {s1,"<TOP>"});
      then (inPath,{});
  end matchcontinue;
end getClassNamesRecursive;

public function getAllInheritedClasses
  input Absyn.Path inClassName;
  input Absyn.Program inProgram;
  output list<Absyn.Path> outBaseClassNames;
protected
  GraphicEnvCache genv;
algorithm
  outBaseClassNames :=
  matchcontinue (inClassName,inProgram)
    local
      Absyn.Path p_class;
      list<Absyn.Path> paths, fqpaths, allPaths = {};
      Absyn.Class cdef;
      list<Absyn.ElementSpec> exts;
      Absyn.Program p;
      FGraph.Graph env;

    case (p_class,p)
      algorithm
        cdef := getPathedClassInProgram(p_class, p);
        exts := getExtendsElementspecInClass(cdef);
        paths := List.map(exts, getBaseClassNameFromExtends);
        fqpaths := {};
        try
          genv := createEnvironment(p, NONE(), p_class);
          for pt in paths loop
            fqpaths := qualifyPath(genv, pt) :: fqpaths;
          end for;
          fqpaths := listReverse(fqpaths);
        else
          // print("Bummer: " + AbsynUtil.pathString(p_class) + "\n");
          fqpaths := paths;
        end try;
        allPaths := {};
        for pt in fqpaths loop
          allPaths := List.append_reverse(getAllInheritedClasses(pt, p), allPaths);
        end for;
        allPaths := Dangerous.listReverseInPlace(List.unique(allPaths));
      then
        listAppend(fqpaths, allPaths);

    else {};
  end matchcontinue;
end getAllInheritedClasses;

public function getBaseClassNameFromExtends
"function: getBaseClassNameFromExtends"
  input Absyn.ElementSpec inElementSpec;
  output Absyn.Path outBaseClassPath;
algorithm
  outBaseClassPath := match (inElementSpec)
    local
      Absyn.Path path;

    case (Absyn.EXTENDS(path = path)) then path;
  end match;
end getBaseClassNameFromExtends;

protected function mergeClasses
"@author adrpo
 merge two classes cNew and cOld in the following way:
 1. get all the inner class definitions from cOld that were loaded from a different file than itself
 2. append all elements from step 1 to class cNew public list!"
   input  Absyn.Class cNew;
   input  Absyn.Class cOld;
   output Absyn.Class c;
algorithm
  c := matchcontinue(cNew, cOld)
    local
      list<Absyn.ClassPart> partsC1, partsC2;
      list<Absyn.ElementItem> pubElementsC1, pubElementsC2;
      String file;
      Absyn.Ident n; Boolean p; Boolean f; Boolean e; Absyn.Restriction r; Absyn.Info i;
      list<list<Absyn.ElementItem>> llEls;
      list<String> typeVars1, typeVars2;
      list<Absyn.NamedArg> classAttrs1, classAttr2;
      list<Absyn.Annotation> ann1, ann2;
      Option<String> cmt1, cmt2;


    // if cOld has no parts then just return cNew
    case (_, Absyn.CLASS(body = Absyn.PARTS(classParts = {}))) then cNew;
    case (_, Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = {}))) then cNew;

    // if cNew and cOld has parts, get the foreign elements (loaded from other file) from cOld
    // and append them to the public list of cNew
    case (c as Absyn.CLASS(body=Absyn.PARTS(typeVars1,classAttrs1,partsC1,ann1,cmt1)),
          Absyn.CLASS(body = Absyn.PARTS(classParts = partsC2), info = SOURCEINFO(fileName = file)))
      equation
        pubElementsC2 = getPublicList(partsC2);
        pubElementsC2 = excludeElementsFromFile(file, pubElementsC2);
        pubElementsC1 = getPublicList(partsC1);
        pubElementsC1 = mergeElements(pubElementsC1, pubElementsC2);
        partsC1 = replacePublicList(partsC1, pubElementsC1);
        c.body = Absyn.PARTS(typeVars1,classAttrs1,partsC1,ann1,cmt1);
      then c;

    // TODO! FIXME! handle also CLASS_EXTENDS!
    // if the class cNew or cOld is not containing parts then don't bother, just replace the entire class!
    case (_, _) then cNew;
  end matchcontinue;
end mergeClasses;

function mergeElement
"@author adrpo
 merge the element given as second argument with the element from the first list with same name.
  if no such elements are in the first list, just append it at the end"
  input  list<Absyn.ElementItem> inEls;
  input  Absyn.ElementItem inEl;
  output list<Absyn.ElementItem> outEls;
algorithm
  outEls := matchcontinue(inEls, inEl)
    local
      String n1,n2;
      list<Absyn.ElementItem> rest, filtered;
      Absyn.ElementItem e1,e2;
      Boolean r;
      Boolean f;
      Option<Absyn.RedeclareKeywords> redecl;
      Absyn.InnerOuter innout ;
      String name;
      Absyn.Info i;
      Option<Absyn.ConstrainClass> cc;
      Absyn.Class c1, c2;
    case ({}, _) then inEl::{};
    // not found put it at the end
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(f, redecl, innout, Absyn.CLASSDEF(r, c1 as Absyn.CLASS(name = n1)), i, cc)) :: rest,
          Absyn.ELEMENTITEM(Absyn.ELEMENT(specification = Absyn.CLASSDEF(_,c2 as Absyn.CLASS(name = n2)))))
      equation
        true = stringEqual(n1, n2);
         // element found, merge it!
        c1 = mergeClasses(c1, c2);
      then
        Absyn.ELEMENTITEM(Absyn.ELEMENT(f, redecl, innout, Absyn.CLASSDEF(r, c1), i, cc)) :: rest;
    case (e1 :: rest, e2)
      equation
        // try the second from the first list
        filtered = mergeElement(rest, e2);
      then
         e1::filtered;
  end matchcontinue;
end mergeElement;

function mergeElements
  "@author adrpo see merge element"
   input  list<Absyn.ElementItem> inEls1;
   input  list<Absyn.ElementItem> inEls2;
   output list<Absyn.ElementItem> outEls;
  algorithm
    outEls := matchcontinue(inEls1, inEls2)
    local
      String n1,n2;
      list<Absyn.ElementItem> rest, merged;
      Absyn.ElementItem e1,e2;
      case ({}, _) then inEls2;
      case (_, {}) then inEls1;
      case (_, e2::rest)
        equation
          merged = mergeElement(inEls1, e2);
          merged = mergeElements(merged, rest);
        then merged;
    end matchcontinue;
end mergeElements;

function excludeElementsFromFile
"exclude all elements which are part of the given file"
  input  String inFile;
  input  list<Absyn.ElementItem> inEls;
  output list<Absyn.ElementItem> outEls;
algorithm
  outEls := match (inFile,inEls)
    local
      Absyn.ElementItem e;
      list<Absyn.ElementItem> rest, filtered;
      String f,file,cmt;
      Boolean b = false;

    case (_,{}) then {};
    // elements can come from different files
    case (file,(e as Absyn.ELEMENTITEM(Absyn.ELEMENT(info = SOURCEINFO(fileName = f))))::rest)
      equation
        b = stringEqual(file, f); // not from this file, use it, else discard!
        filtered = excludeElementsFromFile(file, rest);
      then if not b then e::filtered else filtered;
    // lexer comments can only be from this file, exclude
    case (file,(e as Absyn.LEXER_COMMENT(cmt))::rest)
      equation
        filtered = excludeElementsFromFile(file, rest);
      then filtered;
  end match;
end excludeElementsFromFile;

protected function getAllSubtypeOfCandidates
  "Returns a list of all classes that needs to be considered by getAllSubtypeOf"
  input Absyn.Path path;
  input Absyn.Path parentClass;
  input Absyn.Program program;
  input Boolean includePartial;
  input output list<Absyn.Path> candidates;
protected
  Absyn.Class cdef;
  list<String> names;
  list<Absyn.Path> paths;
  Boolean is_parent;
algorithm
  try
    cdef := getPathedClassInProgram(path, program);
  else
    return;
  end try;

  // Only add non-partial classes if includePartial = false.
  if includePartial or AbsynUtil.isNotPartial(cdef) then
    candidates := path :: candidates;

    // Only recurse into packages, unless it's the parent class in which case we
    // also want to include local classes.
    is_parent := AbsynUtil.pathEqual(path, parentClass);
    if AbsynUtil.isPackageRestriction(cdef.restriction) or is_parent then
      names := getClassnamesInClassListNoPartial(path, program, cdef, is_parent, false);
      paths := list(AbsynUtil.suffixPath(path, n) for n in names);
      candidates := List.fold(paths,
        function getAllSubtypeOfCandidates(program = program, parentClass = parentClass, includePartial = includePartial), candidates);
    end if;
  end if;
end getAllSubtypeOfCandidates;

public function getAllSubtypeOf
  "Returns the list of all classes that extend from class_ given a parentClass where the lookup for class_ should start"
  input Absyn.Path inClass;
  input Absyn.Path inParentClass;
  input Absyn.Program inProgram;
  input Boolean qualified;
  input Boolean includePartial;
  input Boolean sort;
  output list<Absyn.Path> paths;
protected
  list<String> strlst;
  Absyn.Path pp, fqpath;
  list<Absyn.Class> classes;
  list<Absyn.Path> result_path_lst;
  list<Absyn.Path> acc, extendPaths, local_paths;
  Boolean b;
  GraphicEnvCache genv;
  Option<Absyn.Path> opt_path;
algorithm
  Absyn.PROGRAM(classes=classes) := inProgram;

  if not includePartial then
    classes := list(c for c guard AbsynUtil.isNotPartial(c) in classes);
  end if;

  strlst := List.map(classes, AbsynUtil.getClassName);
  result_path_lst := list(AbsynUtil.makeIdentPathFromString(str) for str in strlst);
  acc := List.fold(result_path_lst,
    function getAllSubtypeOfCandidates(parentClass = inParentClass, program = inProgram, includePartial = includePartial), {});

  try
    genv := createEnvironment(inProgram, NONE(), inParentClass);
    fqpath := qualifyPath(genv, inClass);
  else
    fqpath := inClass;
  end try;

  paths := {};
  local_paths := {};

  for pt in acc loop
    extendPaths := getAllInheritedClasses(pt, inProgram);

    if List.contains(extendPaths, fqpath, AbsynUtil.pathSuffixOfr) then
      // Put classes declared locally in the parent class first in the list and
      // remove the parent prefix from their name, since they're usually meant
      // to be the default option.
      opt_path := AbsynUtil.removePrefixOpt(inParentClass, pt);

      if isSome(opt_path) then
        SOME(pt) := opt_path;
        local_paths := pt :: local_paths;
      else
        paths := pt :: paths;
      end if;
    end if;
  end for;

  // Also add the class itself if it's a candidate.
  if List.contains(acc, fqpath, AbsynUtil.pathEqual) then
    paths := fqpath :: paths;
  end if;

  paths := List.unique(listAppend(local_paths, paths));

  if sort then
    paths := List.sort(paths, AbsynUtil.pathLt);
  end if;
end getAllSubtypeOf;

public function updateConnectionAnnotation
  "Updates a connection annotation in a model."
  input Absyn.ComponentRef inClass;
  input String inFrom;
  input String inTo;
  input list<Absyn.NamedArg> inAnnotation;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
protected
  Absyn.Path class_path;
  Absyn.Class cls;
  Absyn.Within class_within;
algorithm
  class_path := AbsynUtil.crefToPath(inClass);
  cls := getPathedClassInProgram(class_path, inProgram);
  cls := updateConnectionAnnotationInClass(cls, inFrom, inTo, annotationListToAbsyn(inAnnotation));
  class_within := if AbsynUtil.pathIsIdent(class_path) then
    Absyn.TOP() else Absyn.WITHIN(AbsynUtil.stripLast(class_path));
  outProgram := updateProgram(Absyn.PROGRAM({cls}, class_within), inProgram);
end updateConnectionAnnotation;

public function updateConnectionAnnotationInClass
  "Helper function to updateConnectionAnnotation."
  input Absyn.Class inClass1;
  input String inFrom;
  input String inTo;
  input Absyn.Annotation inAnnotation;
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass1, inFrom, inTo, inAnnotation)
    local
      list<Absyn.EquationItem> eqlst,eqlst_1;
      list<Absyn.ClassPart> parts2,parts;
      String i, bcname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      SourceInfo file_info;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;
      String from, to;
      Absyn.Annotation annotation_;
    /* a class with parts */
    case (outClass as Absyn.CLASS(body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann=ann,comment = cmt)),from,to,annotation_)
      equation
        eqlst = getEquationList(parts);
        eqlst_1 = updateConnectionAnnotationInEqList(eqlst, from, to, annotation_);
        parts2 = replaceEquationList(parts, eqlst_1);
        outClass.body = Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then
        outClass;
    /* an extended class with parts: model extends M end M;  */
    case (outClass as Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications=modif,parts = parts,ann = ann,comment = cmt)),from,to,annotation_)
      equation
        eqlst = getEquationList(parts);
        eqlst_1 = updateConnectionAnnotationInEqList(eqlst, from, to, annotation_);
        parts2 = replaceEquationList(parts, eqlst_1);
        outClass.body = Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann);
      then
        outClass;
  end match;
end updateConnectionAnnotationInClass;

protected function updateConnectionAnnotationInEqList
  "Helper function to updateConnectionAnnotation."
  input list<Absyn.EquationItem> equations;
  input String from;
  input String to;
  input Absyn.Annotation ann;
  output list<Absyn.EquationItem> outEquations = {};
protected
  Absyn.ComponentRef c1, c2;
  String c1_str, c2_str;
  Boolean found = false;
algorithm
  for eq in equations loop
    if not found then
      eq := match eq
        case Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = c1, connector2 = c2))
          algorithm
            c1_str := AbsynUtil.crefString(c1);
            c2_str := AbsynUtil.crefString(c2);

            if (c1_str == from and c2_str == to) then
              found := true;
            end if;
            if not found then
              found := (c1_str == to and c2_str == from);
            end if;
            if found then
              eq.comment := SOME(Absyn.COMMENT(SOME(ann), NONE()));
            end if;
          then
            eq;

        else eq;
      end match;
    end if;

    outEquations := eq :: outEquations;
  end for;

  outEquations := Dangerous.listReverseInPlace(outEquations);
end updateConnectionAnnotationInEqList;

public function updateConnectionNames
  "Updates a connection connector names in a model."
  input Absyn.Path inPath;
  input String inFrom;
  input String inTo;
  input String inFromNew;
  input String inToNew;
  input Absyn.Program inProgram;
  output Boolean outResult;
  output Absyn.Program outProgram;
algorithm
  (outResult, outProgram) := matchcontinue (inPath, inFrom, inTo, inFromNew, inToNew, inProgram)
    local
      Absyn.Path path, modelwithin;
      String from, to, fromNew, toNew;
      Absyn.Class cdef, newcdef;
      Absyn.Program newp, p;

    case (path, from, to, fromNew, toNew, (p as Absyn.PROGRAM()))
      equation
        modelwithin = AbsynUtil.stripLast(path);
        cdef = getPathedClassInProgram(path, p);
        newcdef = updateConnectionNamesInClass(cdef, from, to, fromNew, toNew);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin)), p);
      then
        (true, newp);

    case (path, from, to, fromNew, toNew, (p as Absyn.PROGRAM()))
      equation
        cdef = getPathedClassInProgram(path, p);
        newcdef = updateConnectionNamesInClass(cdef, from, to, fromNew, toNew);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP()), p);
      then
        (true, newp);

    case (_, _, _, _, _, (p as Absyn.PROGRAM())) then (false, p);
  end matchcontinue;
end updateConnectionNames;

protected function updateConnectionNamesInClass
  "Helper function to updateConnectionNames."
  input Absyn.Class inClass1;
  input String inFrom;
  input String inTo;
  input String inFromNew;
  input String inToNew;
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass1, inFrom, inTo, inFromNew, inToNew)
    local
      list<Absyn.EquationItem> eqlst,eqlst_1;
      list<Absyn.ClassPart> parts2,parts;
      String i, bcname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      SourceInfo file_info;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;
      String from, to, fromNew, toNew;
    /* a class with parts */
    case (outClass as Absyn.CLASS(body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann=ann,comment = cmt)),from,to,fromNew,toNew)
      equation
        eqlst = getEquationList(parts);
        eqlst_1 = updateConnectionNamesInEqList(eqlst, from, to, fromNew, toNew);
        parts2 = replaceEquationList(parts, eqlst_1);
        outClass.body = Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then
        outClass;
    /* an extended class with parts: model extends M end M;  */
    case (outClass as Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications=modif,parts = parts,ann = ann,comment = cmt)),from,to,fromNew,toNew)
      equation
        eqlst = getEquationList(parts);
        eqlst_1 = updateConnectionNamesInEqList(eqlst, from, to, fromNew, toNew);
        parts2 = replaceEquationList(parts, eqlst_1);
        outClass.body = Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann);
      then
        outClass;
  end match;
end updateConnectionNamesInClass;

protected function updateConnectionNamesInEqList
  "Helper function to updateConnectionNames."
  input list<Absyn.EquationItem> equations;
  input String from;
  input String to;
  input String fromNew;
  input String toNew;
  output list<Absyn.EquationItem> outEquations = {};
protected
  Absyn.ComponentRef c1, c2;
  String c1_str, c2_str;
  Boolean found = false;

algorithm
  for eq in equations loop
    if not found then
      eq := match eq
        case Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = c1, connector2 = c2))
          algorithm
            c1_str := AbsynUtil.crefString(c1);
            c2_str := AbsynUtil.crefString(c2);

            found := if (c1_str == from and c2_str == to) then true else (c1_str == to and c2_str == from);
            if found then
              eq.equation_ := Absyn.EQ_CONNECT(Parser.stringCref(fromNew), Parser.stringCref(toNew));
            end if;
          then
            eq;

        else eq;
      end match;
    end if;

    outEquations := eq :: outEquations;
  end for;

  outEquations := Dangerous.listReverseInPlace(outEquations);
end updateConnectionNamesInEqList;

protected function getClassnamesInClassListNoPartial
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  input Boolean inShowProtected;
  input Boolean includeConstants;
  output list<String> outString;
algorithm
  if AbsynUtil.isPartial(inClass) then
    outString := {};
    return;
  end if;

  outString:=
  match (inPath,inProgram,inClass,inShowProtected,includeConstants)
    local
      list<String> strlist;
      list<Absyn.ClassPart> parts;
      Absyn.Path inmodel,path;
      Absyn.Program p;
      Boolean b,c;

    case (_,_,Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),b,c)
      equation
        strlist = getClassnamesInPartsNoPartial(parts,b,c);
      then
        strlist;

    case (_,_,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),b,c)
      equation
        strlist = getClassnamesInPartsNoPartial(parts,b,c);
      then strlist;

    case (_,_,Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH())),_,_)
      equation
        //(cdef,newpath) = lookupClassdef(path, inmodel, p);
        //res = getClassnamesInClassListNoPartial(newpath, p, cdef);
      then
        {};//res;

    case (_,_,Absyn.CLASS(body = Absyn.OVERLOAD()),_,_)
      equation
      then {};

    case (_,_,Absyn.CLASS(body = Absyn.ENUMERATION()),_,_)
      equation
      then {};

    case (_,_,Absyn.CLASS(body = Absyn.PDER()),_,_)
      equation
      then {};

  end match;
end getClassnamesInClassListNoPartial;

public function getClassnamesInPartsNoPartial
"Helper function to getClassnamesInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Boolean inShowProtected;
  input Boolean includeConstants;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynClassPartLst,inShowProtected,includeConstants)
    local
      list<String> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
      Boolean b,c;

    case ({},_,_) then {};

    case ((Absyn.PUBLIC(contents = elts) :: rest),b,c)
      equation
        l1 = getClassnamesInEltsNoPartial(elts,c);
        l2 = getClassnamesInPartsNoPartial(rest,b,c);
        res = listAppend(l1, l2);
      then
        res;

    // adeas31 2012-01-25: Also check the protected sections.
    case ((Absyn.PROTECTED(contents = elts) :: rest), true, c)
      equation
        l1 = getClassnamesInEltsNoPartial(elts,c);
        l2 = getClassnamesInPartsNoPartial(rest,true,c);
        res = listAppend(l1, l2);
      then
        res;

    case ((_ :: rest),b,c)
      equation
        res = getClassnamesInPartsNoPartial(rest,b,c);
      then
        res;

  end matchcontinue;
end getClassnamesInPartsNoPartial;

public function getClassnamesInEltsNoPartial
"Helper function to getClassnamesInPartsNoPartial."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Boolean includeConstants;
  output list<String> outStringLst;
protected
  DoubleEnded.MutableList<String> delst;
algorithm
  delst := DoubleEnded.fromList({});
  for elt in inAbsynElementItemLst loop
  _ := match elt
    local
      list<String> res;
      String id;
      list<Absyn.ElementItem> rest;
      Boolean c;
      list<Absyn.ComponentItem> lst;
      list<String> names;

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ =
                 Absyn.CLASS(partialPrefix=false, body = Absyn.CLASS_EXTENDS(baseClassName = id)))))
      algorithm
        DoubleEnded.push_back(delst, id);
      then ();

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ =
                 Absyn.CLASS(partialPrefix=false, name = id))))
      algorithm
        DoubleEnded.push_back(delst, id);
      then ();

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(attributes = Absyn.ATTR(variability = Absyn.CONST()),
                 components = lst))) guard includeConstants
      algorithm
        DoubleEnded.push_list_back(delst, getComponentItemsName(lst,false));
      then ();

    else ();
  end match;
  end for;
  outStringLst := DoubleEnded.toListAndClear(delst);
end getClassnamesInEltsNoPartial;

public function removeInnerClass "
   This function takes two class definitions. The first one is the local
   class that should be removed from the second one.
"
  input Absyn.Class inClass1;
  input Absyn.Class inClass2;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass1,inClass2)
    local
      list<Absyn.ElementItem> publst,publst2,prolst,prolst2;
      list<Absyn.ClassPart> parts2,parts;
      Absyn.Class c1;
      String a,bcname,n;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      SourceInfo file_info;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;

    // a class with parts - class found in public
    case (c1,outClass as Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann = ann, comment = cmt),info = file_info))
      equation
        publst = getPublicList(parts);
        publst2 = removeClassInElementitemlist(publst, c1);
        parts2 = replacePublicList(parts, publst2);
        outClass.body = Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then
        outClass;

    // a class with parts - class found in protected
    case (c1,outClass as Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann = ann, comment = cmt),info = file_info))
      equation
        prolst = getProtectedList(parts);
        prolst2 = removeClassInElementitemlist(prolst, c1);
        parts2 = replaceProtectedList(parts, prolst2);
        outClass.body = Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then
        outClass;

    // an extended class with parts: model extends M end M; - class found in public
    case (c1,outClass as Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,comment = cmt,ann = ann),info = file_info))
      equation
        publst = getPublicList(parts);
        publst2 = removeClassInElementitemlist(publst, c1);
        parts2 = replacePublicList(parts, publst2);
        outClass.body = Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann);
      then
        outClass;

    // an extended class with parts: model extends M end M; - class found in protected
    case (c1,outClass as Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,comment = cmt,ann = ann),info = file_info))
      equation
        prolst = getProtectedList(parts);
        prolst2 = removeClassInElementitemlist(prolst, c1);
        parts2 = replaceProtectedList(parts, prolst2);
        outClass.body = Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann);
      then
        outClass;

    // class not found anywhere!
    case (Absyn.CLASS(name = n),Absyn.CLASS(name = a, info = file_info))
      equation
        Error.addSourceMessage(Error.CLASS_NOT_FOUND, {n, a}, file_info);
      then
        fail();

  end matchcontinue;
end removeInnerClass;

protected function removeClassInElementitemlist
" This function takes an Element list and a Class and returns a modified
   element list where the class definition of the class is removed."
  input list<Absyn.ElementItem> inElements;
  input Absyn.Class inClass;
  output list<Absyn.ElementItem> outElements;
protected
  String name;
algorithm
  Absyn.CLASS(name = name) := inClass;
  outElements := List.deleteMemberOnTrue(name, inElements, classElementItemIsNamed);
end removeClassInElementitemlist;

public function getPathedElementInProgram
  "Looks up an element in the program using the given path."
  input Absyn.Path path;
  input Absyn.Program program;
  output Absyn.Element element;
protected
  Absyn.Class cls;
algorithm
  try
    cls := getClassInProgram(AbsynUtil.pathFirstIdent(path), program);
  else
    cls := getClassInProgram(AbsynUtil.pathFirstIdent(path), FBuiltin.getInitialFunctions());
  end try;

  if AbsynUtil.pathIsIdent(path) then
    // Since the program only stores classes instead of elements we have to
    // create a dummy element if we find a top-level class.
    element := Absyn.Element.ELEMENT(false, NONE(), Absyn.InnerOuter.NOT_INNER_OUTER(),
      Absyn.ElementSpec.CLASSDEF(false, cls), cls.info, NONE());
  else
    SOME(element) := getPathedElementInClass(AbsynUtil.pathRest(path), cls);
  end if;
end getPathedElementInProgram;

protected function getPathedElementInClass
  input Absyn.Path path;
  input Absyn.Class cls;
  output Option<Absyn.Element> element = NONE();
algorithm
  for part in AbsynUtil.getClassPartsInClass(cls) loop
    element := getPathedElementInClassPart(path, part);

    if isSome(element) then
      break;
    end if;
  end for;
end getPathedElementInClass;

protected function getPathedElementInClassPart
  input Absyn.Path path;
  input Absyn.ClassPart part;
  output Option<Absyn.Element> element = NONE();
protected
  Absyn.Element e;
algorithm
  for item in AbsynUtil.getElementItemsInClassPart(part) loop
    if AbsynUtil.isElementItemNamed(AbsynUtil.pathFirstIdent(path), item) then
      Absyn.ElementItem.ELEMENTITEM(element = e) := item;

      if AbsynUtil.pathIsIdent(path) then
        element := SOME(e);
      else
        element := getPathedElementInElement(AbsynUtil.pathRest(path), e);
      end if;

      break;
    end if;
  end for;
end getPathedElementInClassPart;

protected function getPathedElementInElement
  input Absyn.Path path;
  input Absyn.Element element;
  output Option<Absyn.Element> outElement;
protected
  Absyn.Class cls;
algorithm
  outElement := match element
    case Absyn.Element.ELEMENT(specification = Absyn.ElementSpec.CLASSDEF(class_ = cls))
      then getPathedElementInClass(path, cls);
    else NONE();
  end match;
end getPathedElementInElement;

public function getPathedExtendsInProgram
  "Returns the extends clause that matches the fully qualified extends path in
   the given class."
  input Absyn.Path classPath;
  input Absyn.Path extendsPath;
  input Absyn.Program program;
  output Option<Absyn.ElementSpec> extendsSpec;
protected
  Absyn.Class cls;
  GraphicEnvCache env;
algorithm
  try
    cls := getPathedClassInProgram(classPath, program);
    env := Interactive.getClassEnv(program, classPath);

    for ext in getExtendsElementspecInClass(cls) loop
      ext := Interactive.makeExtendsFullyQualified(ext, env);

      if AbsynUtil.pathEqual(extendsPath, AbsynUtil.elementSpecToPath(ext)) then
        extendsSpec := SOME(ext);
        return;
      end if;
    end for;
  else
  end try;

  extendsSpec := NONE();
end getPathedExtendsInProgram;

public function transformPathedElementInList<T>
  input list<T> inList;
  input FuncType inFunc;
  output list<T> outList = {};
  output Option<Absyn.Element> outElement = NONE();
  output Boolean outFound = false;

  partial function FuncType
    input output T t;
          output Option<Absyn.Element> outElement;
          output Boolean outFound;
  end FuncType;
protected
  T e;
  list<T> rest = inList;
algorithm
  while not listEmpty(rest) and not outFound loop
    e :: rest := rest;
    (e, outElement, outFound) := inFunc(e);
    outList := e :: outList;
  end while;

  outList := List.append_reverse(outList, rest);
end transformPathedElementInList;

public function transformPathedElementInProgram
  input Absyn.Path path;
  input Func func;
  input output Absyn.Program program;
        output Option<Absyn.Element> element;
        output Boolean success;

  partial function Func
    input output Absyn.Element element;
  end Func;
protected
  list<Absyn.Class> clss;

  function transform_class
    input Absyn.Path path;
    input Func func;
    input output Absyn.Class cls;
          output Option<Absyn.Element> outElement;
          output Boolean found;
  protected
    Absyn.Element elem;
  algorithm
    // Is this the class we're looking for?
    found := AbsynUtil.pathFirstIdent(path) == cls.name;

    if found then
      if AbsynUtil.pathIsIdent(path) then
        // The path points to a top-level class, temporarily transform it to an
        // element and call the function on it.
        elem := Absyn.Element.ELEMENT(false, NONE(), Absyn.InnerOuter.NOT_INNER_OUTER(),
          Absyn.ElementSpec.CLASSDEF(false, cls), cls.info, NONE());
        elem := func(elem);
        outElement := SOME(elem);
        Absyn.Element.ELEMENT(specification = Absyn.ElementSpec.CLASSDEF(class_ = cls)) := elem;
      else
        // The path points to an element inside the class.
        (cls, outElement, found) := transformPathedElementInClass(AbsynUtil.pathRest(path), func, cls);
      end if;
    else
      outElement := NONE();
    end if;
  end transform_class;
algorithm
  (clss, element, success) := transformPathedElementInList(program.classes, function transform_class(path = path, func = func));

  if success then
    program.classes := clss;
  end if;
end transformPathedElementInProgram;

protected function transformPathedElementInClass
  input Absyn.Path path;
  input Func func;
  input output Absyn.Class cls;
        output Option<Absyn.Element> element;
        output Boolean success;

  partial function Func
    input output Absyn.Element element;
  end Func;
protected
  Absyn.ClassDef def;
algorithm
  (def, element, success) := transformPathedElementInClassDef(path, func, cls.body);

  if success then
    cls.body := def;
  end if;
end transformPathedElementInClass;

protected function transformPathedElementInClassDef
  input Absyn.Path path;
  input Func func;
  input output Absyn.ClassDef def;
        output Option<Absyn.Element> element;
        output Boolean success;

  partial function Func
    input output Absyn.Element element;
  end Func;
protected
  list<Absyn.ClassPart> parts;
algorithm
  success := match def
    case Absyn.ClassDef.PARTS()
      algorithm
        (parts, element, success) := transformPathedElementInList(def.classParts,
          function transformPathedElementInClassPart(path = path, func = func));

        if success then
          def.classParts := parts;
        end if;
      then
        success;

    case Absyn.ClassDef.CLASS_EXTENDS()
      algorithm
        (parts, element, success) := transformPathedElementInList(def.parts,
          function transformPathedElementInClassPart(path = path, func = func));

        if success then
          def.parts := parts;
        end if;
      then
        success;

    else false;
  end match;
end transformPathedElementInClassDef;

protected function transformPathedElementInClassPart
  input Absyn.Path path;
  input Func func;
  input output Absyn.ClassPart part;
        output Option<Absyn.Element> element;
        output Boolean success;

  partial function Func
    input output Absyn.Element element;
  end Func;
protected
  list<Absyn.ElementItem> items;
algorithm
  success := match part
    case Absyn.ClassPart.PUBLIC()
      algorithm
        (items, element, success) := transformPathedElementInList(part.contents,
          function transformPathedElementInElementItem(path = path, func = func));

        if success then
          part.contents := items;
        end if;
      then
        success;

    case Absyn.ClassPart.PROTECTED()
      algorithm
        (items, element, success) := transformPathedElementInList(part.contents,
          function transformPathedElementInElementItem(path = path, func = func));

        if success then
          part.contents := items;
        end if;
      then
        success;

    else false;
  end match;
end transformPathedElementInClassPart;

protected function transformPathedElementInElementItem
  input Absyn.Path path;
  input Func func;
  input output Absyn.ElementItem item;
        output Option<Absyn.Element> outElement;
        output Boolean success;

  partial function Func
    input output Absyn.Element element;
  end Func;
protected
  Absyn.Element element;
algorithm
  success := match item
    case Absyn.ElementItem.ELEMENTITEM()
      guard AbsynUtil.isElementItemNamed(AbsynUtil.pathFirstIdent(path), item)
      algorithm
        if AbsynUtil.pathIsIdent(path) then
          item.element := func(item.element);
          outElement := SOME(item.element);
          success := true;
        else
          (element, outElement, success) := transformPathedElementInElement(AbsynUtil.pathRest(path), func, item.element);

          if success then
            item.element := element;
          end if;
        end if;
      then
        success;

    else false;
  end match;
end transformPathedElementInElementItem;

protected function transformPathedElementInElement
  input Absyn.Path path;
  input Func func;
  input output Absyn.Element element;
        output Option<Absyn.Element> outElement;
        output Boolean success;

  partial function Func
    input output Absyn.Element element;
  end Func;
protected
  Absyn.ElementSpec spec;
algorithm
  success := match element
    case Absyn.Element.ELEMENT()
      algorithm
        (spec, outElement, success) := transformPathedElementInElementSpec(path, func, element.specification);

        if success then
          element.specification := spec;
        end if;
      then
        success;

    else false;
  end match;
end transformPathedElementInElement;

protected function transformPathedElementInElementSpec
  input Absyn.Path path;
  input Func func;
  input output Absyn.ElementSpec spec;
        output Option<Absyn.Element> element;
        output Boolean success;

  partial function Func
    input output Absyn.Element element;
  end Func;
protected
  Absyn.Class cls;
algorithm
  success := match spec
    case Absyn.ElementSpec.CLASSDEF()
      algorithm
        (cls, element, success) := transformPathedElementInClass(path, func, spec.class_);

        if success then
          spec.class_ := cls;
        end if;
      then
        success;

    else false;
  end match;
end transformPathedElementInElementSpec;

public function getPathedClassRestriction
  input Absyn.Path path;
  input Absyn.Program program;
  output Absyn.Restriction restriction;
algorithm
  try
    Absyn.CLASS(restriction = restriction) := getPathedClassInProgram(path, program);
  else
    restriction := Absyn.Restriction.R_UNKNOWN();
  end try;
end getPathedClassRestriction;

public function getPathedSCodeElementInProgram
  input Absyn.Path path;
  input SCode.Program program;
  output SCode.Element element;
protected
  String name;
algorithm
  name := AbsynUtil.pathFirstIdent(path);
  element := List.find(program, function SCodeUtil.isElementNamed(name = name));

  if not AbsynUtil.pathIsIdent(path) then
    element := getPathedSCodeElementInProgram(AbsynUtil.pathRest(path), SCodeUtil.getClassElements(element));
  end if;
end getPathedSCodeElementInProgram;

public function getElementAnnotation
  input Absyn.Path elementPath;
  input Absyn.Program program;
  output String annotationString;
protected
  Absyn.Class cls;
  Absyn.Element elem;
  Option<Absyn.Annotation> ann;
  list<Absyn.ElementArg> eargs;
algorithm
  try
    elem := getPathedElementInProgram(elementPath, program);
    ann := AbsynUtil.getElementAnnotation(elem, AbsynUtil.pathLastIdent(elementPath));

    if isSome(ann) then
      SOME(Absyn.Annotation.ANNOTATION(elementArgs = eargs)) := ann;
      annotationString := List.toString(eargs, Dump.unparseElementArgStr, "", "(", ", ", ")");
    else
      annotationString := "()";
    end if;
  else
    annotationString := "";
  end try;
end getElementAnnotation;

public function setElementAnnotation
  input Absyn.Path elementPath;
  input Absyn.Modification annotationMod;
  input output Absyn.Program program;
        output Boolean success = true;
protected
  Option<Absyn.Annotation> ann;
  String name;
  Option<Absyn.Element> elem_opt;
algorithm
  try
    if listEmpty(annotationMod.elementArgLst) then
      ann := NONE();
    else
      ann := SOME(Absyn.Annotation.ANNOTATION(annotationMod.elementArgLst));
    end if;

    name := AbsynUtil.pathLastIdent(elementPath);
    (program, elem_opt, success) := transformPathedElementInProgram(elementPath,
      function AbsynUtil.setElementAnnotation(name = name, inAnnotation = ann), program);

    if success then
      SymbolTable.setAbsynElement(program, Util.getOption(elem_opt), elementPath);
    end if;
  else
    success := false;
  end try;
end setElementAnnotation;

public function loadClassContentString
  input String content;
  input Absyn.Path classPath;
  input Integer offsetX;
  input Integer offsetY;
  input output Absyn.Program program;
        output Boolean success = true;
protected
  Absyn.ClassDef parsed_body;
algorithm
  try
    Absyn.Program.PROGRAM(classes = {Absyn.Class.CLASS(body = parsed_body)}) :=
      Parser.parsestring(stringAppendList({"model dummy\n", content, "end dummy;\n"}));

    parsed_body := offsetAnnotationsInClassDef(parsed_body, offsetX, offsetY);
    (program, _, success) := transformPathedElementInProgram(classPath,
      function mergeClassContents(newContent = parsed_body), program);
  else
    success := false;
  end try;
end loadClassContentString;

public function mergeClassContents
  input output Absyn.Element element;
  input Absyn.ClassDef newContent;
protected
  Absyn.ElementSpec spec;
  Absyn.Class cls;
  Absyn.ClassDef old_content, new_content;
algorithm
  new_content := resolveMergeContentsConflicts(element, newContent);

  () := match element
    case Absyn.Element.ELEMENT(specification = spec as
           Absyn.ElementSpec.CLASSDEF(class_ = cls as
             Absyn.Class.CLASS(body = old_content)))
      algorithm
        () := match (old_content, new_content)
          case (Absyn.ClassDef.PARTS(), Absyn.ClassDef.PARTS())
            algorithm
              old_content.classParts := mergeClassParts(new_content.classParts, old_content.classParts);
              old_content.ann := mergeAnnotationLists(new_content.ann, old_content.ann);
            then
              ();

          case (Absyn.ClassDef.CLASS_EXTENDS(), Absyn.ClassDef.PARTS())
            algorithm
              old_content.parts := mergeClassParts(new_content.classParts, old_content.parts);
              old_content.ann := mergeAnnotationLists(new_content.ann, old_content.ann);
            then
              ();

        end match;

        cls.body := old_content;
        spec.class_ := cls;
        element.specification := spec;
      then
        ();
  end match;
end mergeClassContents;

protected function mergeClassParts
  "Merges a list of new class parts with a list of old parts."
  input list<Absyn.ClassPart> newParts;
  input list<Absyn.ClassPart> oldParts;
  output list<Absyn.ClassPart> outParts;
protected
  Vector<Absyn.ClassPart> parts;
  Option<Absyn.ClassPart> op;
  Absyn.ClassPart p;
  Integer index;
algorithm
  parts := Vector.fromList(oldParts);

  for part in newParts loop
    () := match part
      case Absyn.ClassPart.PUBLIC()
        algorithm
          // Try to find the last public/protected element section.
          (op, index) := Vector.findLast(parts, AbsynUtil.isElementSection);

          () := match op
            // Compatible public section, append the new elements to the old.
            case SOME(p as Absyn.ClassPart.PUBLIC())
              algorithm
                part.contents := listAppend(p.contents, part.contents);
                Vector.updateNoBounds(parts, index, part);
              then
                ();

            // Otherwise insert the section after any existing element sections.
            else
              algorithm
                Vector.insert(parts, part, max(index + 1, 1));
              then
                ();

          end match;
        then
          ();

      case Absyn.ClassPart.PROTECTED()
        algorithm
          // Try to find the last public/protected element section.
          (op, index) := Vector.findLast(parts, AbsynUtil.isElementSection);

          () := match op
            // Compatible protected section, append the new elements to the old.
            case SOME(p as Absyn.ClassPart.PROTECTED())
              algorithm
                part.contents := listAppend(p.contents, part.contents);
                Vector.updateNoBounds(parts, index, part);
              then
                ();

            // Otherwise insert the section after any existing element sections.
            else
              algorithm
                Vector.insert(parts, part, max(index + 1, 1));
              then
                ();

          end match;
        then
          ();

      case Absyn.ClassPart.EQUATIONS()
        algorithm
          // Try to find the last normal/initial equation section.
          (op, index) := Vector.findLast(parts, AbsynUtil.isEquationSection);

          () := match op
            // Compatible normal equation section, append the new contents to the old.
            case SOME(p as Absyn.ClassPart.EQUATIONS())
              algorithm
                part.contents := listAppend(p.contents, part.contents);
                Vector.updateNoBounds(parts, index, part);
              then
                ();

            // Otherwise insert the new section after any existing element and equation sections.
            else
              algorithm
                if index == -1 then
                  (_, index) := Vector.findLast(parts, AbsynUtil.isElementSection);
                end if;
                Vector.insert(parts, part, max(index + 1, 1));
              then
                ();

          end match;
        then
          ();

      case Absyn.ClassPart.INITIALEQUATIONS()
        algorithm
          // Try to find the last normal/initial equation section.
          (op, index) := Vector.findLast(parts, AbsynUtil.isEquationSection);

          () := match op
            // Compatible initial equation section, append the new contents to the old.
            case SOME(p as Absyn.ClassPart.INITIALEQUATIONS())
              algorithm
                part.contents := listAppend(p.contents, part.contents);
                Vector.updateNoBounds(parts, index, part);
              then
                ();

            // Otherwise insert the new section after any existing element and equation sections.
            else
              algorithm
                if index == -1 then
                  (_, index) := Vector.findLast(parts, AbsynUtil.isElementSection);
                end if;
                Vector.insert(parts, part, max(index + 1, 1));
              then
                ();

          end match;
        then
          ();

      // external section, replace the existing one or add it at the end of the
      // class if none exists.
      case Absyn.ClassPart.EXTERNAL()
        algorithm
          (_, index) := Vector.findLast(parts, AbsynUtil.isExternalPart);

          if index <> -1 then
            Vector.updateNoBounds(parts, index, part);
          else
            Vector.push(parts, part);
          end if;
        then
          ();

      // Anything else, add to the end of the class without merging.
      else
        algorithm
          Vector.push(parts, part);
        then
          ();
    end match;
  end for;

  outParts := Vector.toList(parts);
end mergeClassParts;

function mergeAnnotationLists
  input list<Absyn.Annotation> newAnnotations;
  input list<Absyn.Annotation> oldAnnotations;
  output list<Absyn.Annotation> outAnnotations;
protected
  Absyn.Annotation old_ann;
algorithm
  if listEmpty(oldAnnotations) then
    outAnnotations := newAnnotations;
  else
    old_ann := listHead(oldAnnotations);
    for new_ann in newAnnotations loop
      old_ann := AbsynUtil.mergeAnnotations(old_ann, new_ann);
    end for;
    outAnnotations := old_ann :: listRest(oldAnnotations);
  end if;
end mergeAnnotationLists;

function resolveMergeContentsConflicts
  input Absyn.Element oldElement;
  input output Absyn.ClassDef newContent;
protected
  UnorderedSet<String> old_names;
  UnorderedMap<String, String> rename_map;
  String new_name;
  Integer index;
  list<String> conflicting_names = {};
algorithm
  // Collect the existing names in a hash set.
  old_names := UnorderedSet.new(stringHashDjb2, stringEq);
  for e in AbsynUtil.getElementItemsInElement(oldElement) loop
    for name in AbsynUtil.elementItemNames(e) loop
      UnorderedSet.add(name, old_names);
    end for;
  end for;

  // Go through the names in the new content.
  rename_map := UnorderedMap.new<String>(stringHashDjb2, stringEq);
  for e in AbsynUtil.getElementItemsInClassDef(newContent) loop
    for name in AbsynUtil.elementItemNames(e) loop
      if UnorderedSet.contains(name, old_names) then
        // If the name conflicts with an existing name, save it for later.
        conflicting_names := name :: conflicting_names;
      else
        // If the name doesn't conflict, add it to the set of existing names to
        // take it into account when generating new names for conflicting names.
        UnorderedSet.add(name, old_names);
      end if;
    end for;
  end for;

  if listEmpty(conflicting_names) then
    return;
  end if;

  // Go through the conflicting names and find a non-conflicting name for them.
  for name in listReverse(conflicting_names) loop
    // Try name1, name2, etc. until a non-conflicting name is found.
    index := 1;
    new_name := name + String(index);
    while UnorderedSet.contains(new_name, old_names) loop
      index := index + 1;
      new_name := name + String(index);
    end while;

    // Save the mapping for name->new_name to apply to the class.
    UnorderedMap.add(name, new_name, rename_map);

    // Add the new name to the set of existing names.
    UnorderedSet.add(new_name, old_names);
  end for;

  // Apply the new names to the class definition.
  if not UnorderedMap.isEmpty(rename_map) then
    newContent := renameElementsInClassDef(newContent, rename_map);
  end if;
end resolveMergeContentsConflicts;

function renameElementsInElement
  input output Absyn.Element element;
  input UnorderedMap<String, String> nameMap;
algorithm
  () := match element
    case Absyn.Element.ELEMENT()
      algorithm
        element.specification := renameElementsInElementSpec(element.specification, nameMap, renameElement = true);
        element.constrainClass := renameElementsInConstrainClassOpt(element.constrainClass, nameMap);
      then
        ();

    else ();
  end match;
end renameElementsInElement;

function renameElementsInElementSpec
  input output Absyn.ElementSpec spec;
  input UnorderedMap<String, String> nameMap;
  input Boolean renameElement;
algorithm
  () := match spec
    case Absyn.ElementSpec.CLASSDEF()
      algorithm
        spec.class_ := renameElementsInClass(spec.class_, nameMap, renameElement);
      then
        ();

    case Absyn.ElementSpec.EXTENDS()
      algorithm
        spec.elementArg := list(renameElementsInElementArg(a, nameMap) for a in spec.elementArg);
        spec.annotationOpt := renameElementsInAnnotationOpt(spec.annotationOpt, nameMap);
      then
        ();

    case Absyn.ElementSpec.COMPONENTS()
      algorithm
        spec.attributes := renameElementsInAttributes(spec.attributes, nameMap);
        spec.typeSpec := renameElementsInTypeSpec(spec.typeSpec, nameMap);
        spec.components := list(renameElementsInComponentItem(c, nameMap, renameElement) for c in spec.components);
      then
        ();

    else ();
  end match;
end renameElementsInElementSpec;

function renameElementsInClass
  input output Absyn.Class cls;
  input UnorderedMap<String, String> nameMap;
  input Boolean renameElement;
algorithm
  if renameElement then
    cls.name := renameElementsInIdent(cls.name, nameMap);
  end if;

  cls.body := renameElementsInClassDef(cls.body, nameMap);
end renameElementsInClass;

function renameElementsInClassDef
  input output Absyn.ClassDef classDef;
  input UnorderedMap<String, String> nameMap;
algorithm
  () := match classDef
    case Absyn.ClassDef.PARTS()
      algorithm
        classDef.classParts := list(renameElementsInClassPart(p, nameMap) for p in classDef.classParts);
        classDef.ann := list(renameElementsInAnnotation(a, nameMap) for a in classDef.ann);
      then
        ();

    case Absyn.ClassDef.DERIVED()
      algorithm
        classDef.typeSpec := renameElementsInTypeSpec(classDef.typeSpec, nameMap);
        classDef.attributes := renameElementsInAttributes(classDef.attributes, nameMap);
        classDef.arguments := list(renameElementsInElementArg(a, nameMap) for a in classDef.arguments);
        classDef.comment := renameElementsInCommentOpt(classDef.comment, nameMap);
      then
        ();

    case Absyn.ClassDef.CLASS_EXTENDS()
      algorithm
        classDef.modifications := list(renameElementsInElementArg(a, nameMap) for a in classDef.modifications);
        classDef.parts := list(renameElementsInClassPart(p, nameMap) for p in classDef.parts);
        classDef.ann := list(renameElementsInAnnotation(a, nameMap) for a in classDef.ann);
      then
        ();

    else ();
  end match;
end renameElementsInClassDef;

function renameElementsInClassPart
  input output Absyn.ClassPart part;
  input UnorderedMap<String, String> nameMap;
algorithm
  () := match part
    case Absyn.ClassPart.PUBLIC()
      algorithm
        part.contents := list(renameElementsInElementItem(i, nameMap) for i in part.contents);
      then
        ();

    case Absyn.ClassPart.PROTECTED()
      algorithm
        part.contents := list(renameElementsInElementItem(i, nameMap) for i in part.contents);
      then
        ();

    case Absyn.ClassPart.CONSTRAINTS()
      algorithm
        part.contents := list(renameElementsInExp(e, nameMap) for e in part.contents);
      then
        ();

    case Absyn.ClassPart.EQUATIONS()
      algorithm
        part.contents := renameElementsInEquationItems(part.contents, nameMap);
      then
        ();

    case Absyn.ClassPart.INITIALEQUATIONS()
      algorithm
        part.contents := renameElementsInEquationItems(part.contents, nameMap);
      then
        ();

    case Absyn.ClassPart.ALGORITHMS()
      algorithm
        part.contents := renameElementsInAlgorithmItems(part.contents, nameMap);
      then
        ();

    case Absyn.ClassPart.INITIALALGORITHMS()
      algorithm
        part.contents := renameElementsInAlgorithmItems(part.contents, nameMap);
      then
        ();

    case Absyn.ClassPart.EXTERNAL()
      algorithm
        part.externalDecl := renameElementsInExternalDecl(part.externalDecl, nameMap);
        part.annotation_ := renameElementsInAnnotationOpt(part.annotation_, nameMap);
      then
        ();

    else ();
  end match;
end renameElementsInClassPart;

function renameElementsInElementItem
  input output Absyn.ElementItem item;
  input UnorderedMap<String, String> nameMap;
algorithm
  () := match item
    case Absyn.ElementItem.ELEMENTITEM()
      algorithm
        item.element := renameElementsInElement(item.element, nameMap);
      then
        ();

    else ();
  end match;
end renameElementsInElementItem;

function renameElementsInEquationItems
  input output list<Absyn.EquationItem> items;
  input UnorderedMap<String, String> nameMap;
algorithm
  items := list(renameElementsInEquationItem(i, nameMap) for i in items);
end renameElementsInEquationItems;

function renameElementsInEquationItem
  input output Absyn.EquationItem item;
  input UnorderedMap<String, String> nameMap;
algorithm
  () := match item
    case Absyn.EquationItem.EQUATIONITEM()
      algorithm
        item.equation_ := renameElementsInEquation(item.equation_, nameMap);
        item.comment := renameElementsInCommentOpt(item.comment, nameMap);
      then
        ();

    else ();
  end match;
end renameElementsInEquationItem;

function renameElementsInEquation
  input output Absyn.Equation eq;
  input UnorderedMap<String, String> nameMap;
algorithm
  () := match eq
    case Absyn.Equation.EQ_IF()
      algorithm
        eq.ifExp := AbsynUtil.traverseExp(eq.ifExp, renameElementsInExp, nameMap);
        eq.equationTrueItems := renameElementsInEquationItems(eq.equationTrueItems, nameMap);
        eq.elseIfBranches := list(renameElementsInEquationBranch(b, nameMap) for b in eq.elseIfBranches);
        eq.equationElseItems := renameElementsInEquationItems(eq.equationElseItems, nameMap);
      then
        ();

    case Absyn.Equation.EQ_EQUALS()
      algorithm
        eq.leftSide := AbsynUtil.traverseExp(eq.leftSide, renameElementsInExp, nameMap);
        eq.rightSide := AbsynUtil.traverseExp(eq.rightSide, renameElementsInExp, nameMap);
      then
        ();

    case Absyn.Equation.EQ_PDE()
      algorithm
        eq.leftSide := AbsynUtil.traverseExp(eq.leftSide, renameElementsInExp, nameMap);
        eq.rightSide := AbsynUtil.traverseExp(eq.rightSide, renameElementsInExp, nameMap);
      then
        ();

    case Absyn.Equation.EQ_CONNECT()
      algorithm
        eq.connector1 := renameElementsInCref(eq.connector1, nameMap);
        eq.connector2 := renameElementsInCref(eq.connector2, nameMap);
      then
        ();

    case Absyn.Equation.EQ_FOR()
      algorithm
        eq.iterators := list(renameElementsInIterator(i, nameMap) for i in eq.iterators);
        eq.forEquations := renameElementsInEquationItems(eq.forEquations, nameMap);
      then
        ();

    case Absyn.Equation.EQ_WHEN_E()
      algorithm
        eq.whenExp := AbsynUtil.traverseExp(eq.whenExp, renameElementsInExp, nameMap);
        eq.whenEquations := renameElementsInEquationItems(eq.whenEquations, nameMap);
        eq.elseWhenEquations := list(renameElementsInEquationBranch(b, nameMap) for b in eq.elseWhenEquations);
      then
        ();

    case Absyn.Equation.EQ_NORETCALL()
      algorithm
        eq.functionName := renameElementsInCref(eq.functionName, nameMap);
        eq.functionArgs := AbsynUtil.traverseExpBidirFunctionArgs(eq.functionArgs, renameElementsInExp,
          AbsynUtil.dummyTraverseExp, nameMap);
      then
        ();

    case Absyn.Equation.EQ_FAILURE()
      algorithm
        eq.equ := renameElementsInEquationItem(eq.equ, nameMap);
      then
        ();

    else ();
  end match;
end renameElementsInEquation;

function renameElementsInEquationBranch
  input output tuple<Absyn.Exp, list<Absyn.EquationItem>> branch;
  input UnorderedMap<String, String> nameMap;
protected
  Absyn.Exp cond;
  list<Absyn.EquationItem> body;
algorithm
  (cond, body) := branch;
  cond := AbsynUtil.traverseExp(cond, renameElementsInExp, nameMap);
  body := renameElementsInEquationItems(body, nameMap);
  branch := (cond, body);
end renameElementsInEquationBranch;

function renameElementsInIterator
  input output Absyn.ForIterator iter;
  input UnorderedMap<String, String> nameMap;
algorithm
  if isSome(iter.range) then
    iter.range := SOME(AbsynUtil.traverseExp(Util.getOption(iter.range), renameElementsInExp, nameMap));
  end if;
end renameElementsInIterator;

function renameElementsInAlgorithmItems
  input output list<Absyn.AlgorithmItem> items;
  input UnorderedMap<String, String> nameMap;
algorithm
  items := list(renameElementsInAlgorithmItem(i, nameMap) for i in items);
end renameElementsInAlgorithmItems;

function renameElementsInAlgorithmItem
  input output Absyn.AlgorithmItem item;
  input UnorderedMap<String, String> nameMap;
algorithm
  () := match item
    case Absyn.AlgorithmItem.ALGORITHMITEM()
      algorithm
        item.algorithm_ := renameElementsInAlgorithm(item.algorithm_, nameMap);
        item.comment := renameElementsInCommentOpt(item.comment, nameMap);
      then
        ();

    else ();
  end match;
end renameElementsInAlgorithmItem;

function renameElementsInAlgorithm
  input output Absyn.Algorithm alg;
  input UnorderedMap<String, String> nameMap;
algorithm
  () := match alg
    case Absyn.Algorithm.ALG_ASSIGN()
      algorithm
        alg.assignComponent := AbsynUtil.traverseExp(alg.assignComponent, renameElementsInExp, nameMap);
        alg.value := AbsynUtil.traverseExp(alg.value, renameElementsInExp, nameMap);
      then
        ();

    case Absyn.Algorithm.ALG_IF()
      algorithm
        alg.ifExp := AbsynUtil.traverseExp(alg.ifExp, renameElementsInExp, nameMap);
        alg.trueBranch := renameElementsInAlgorithmItems(alg.trueBranch, nameMap);
        alg.elseIfAlgorithmBranch := list(renameElementsInAlgorithmBranch(b, nameMap) for b in alg.elseIfAlgorithmBranch);
        alg.elseBranch := renameElementsInAlgorithmItems(alg.elseBranch, nameMap);
      then
        ();

    case Absyn.Algorithm.ALG_FOR()
      algorithm
        alg.iterators := list(renameElementsInIterator(i, nameMap) for i in alg.iterators);
        alg.forBody := renameElementsInAlgorithmItems(alg.forBody, nameMap);
      then
        ();

    case Absyn.Algorithm.ALG_PARFOR()
      algorithm
        alg.iterators := list(renameElementsInIterator(i, nameMap) for i in alg.iterators);
        alg.parforBody := renameElementsInAlgorithmItems(alg.parforBody, nameMap);
      then
        ();

    case Absyn.Algorithm.ALG_WHILE()
      algorithm
        alg.boolExpr := AbsynUtil.traverseExp(alg.boolExpr, renameElementsInExp, nameMap);
        alg.whileBody := renameElementsInAlgorithmItems(alg.whileBody, nameMap);
      then
        ();

    case Absyn.Algorithm.ALG_WHEN_A()
      algorithm
        alg.boolExpr := AbsynUtil.traverseExp(alg.boolExpr, renameElementsInExp, nameMap);
        alg.whenBody := renameElementsInAlgorithmItems(alg.whenBody, nameMap);
        alg.elseWhenAlgorithmBranch := list(renameElementsInAlgorithmBranch(b, nameMap) for b in alg.elseWhenAlgorithmBranch);
      then
        ();

    case Absyn.Algorithm.ALG_NORETCALL()
      algorithm
        alg.functionCall := renameElementsInCref(alg.functionCall, nameMap);
        alg.functionArgs := AbsynUtil.traverseExpBidirFunctionArgs(alg.functionArgs, renameElementsInExp,
          AbsynUtil.dummyTraverseExp, nameMap);
      then
        ();

    else ();
  end match;
end renameElementsInAlgorithm;

function renameElementsInAlgorithmBranch
  input output tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> branch;
  input UnorderedMap<String, String> nameMap;
protected
  Absyn.Exp cond;
  list<Absyn.AlgorithmItem> body;
algorithm
  (cond, body) := branch;
  cond := AbsynUtil.traverseExp(cond, renameElementsInExp, nameMap);
  body := renameElementsInAlgorithmItems(body, nameMap);
  branch := (cond, body);
end renameElementsInAlgorithmBranch;

function renameElementsInElementArg
  input output Absyn.ElementArg arg;
  input UnorderedMap<String, String> nameMap;
algorithm
  () := match arg
    case Absyn.ElementArg.MODIFICATION()
      algorithm
        arg.modification := renameElementsInModificationOpt(arg.modification, nameMap);
      then
        ();

    case Absyn.ElementArg.REDECLARATION()
      algorithm
        arg.elementSpec := renameElementsInElementSpec(arg.elementSpec, nameMap, renameElement = false);
        arg.constrainClass := renameElementsInConstrainClassOpt(arg.constrainClass, nameMap);
      then
        ();

    else ();
  end match;
end renameElementsInElementArg;

function renameElementsInConstrainClassOpt
  input output Option<Absyn.ConstrainClass> cc;
  input UnorderedMap<String, String> nameMap;
algorithm
  cc := Util.applyOption(cc, function renameElementsInConstrainClass(nameMap = nameMap));
end renameElementsInConstrainClassOpt;

function renameElementsInConstrainClass
  input output Absyn.ConstrainClass cc;
  input UnorderedMap<String, String> nameMap;
algorithm
  cc.elementSpec := renameElementsInElementSpec(cc.elementSpec, nameMap, renameElement = true);
  cc.comment := renameElementsInCommentOpt(cc.comment, nameMap);
end renameElementsInConstrainClass;

function renameElementsInCommentOpt
  input output Option<Absyn.Comment> comment;
  input UnorderedMap<String, String> nameMap;
algorithm
  comment := Util.applyOption(comment, function renameElementsInComment(nameMap = nameMap));
end renameElementsInCommentOpt;

function renameElementsInComment
  input output Absyn.Comment comment;
  input UnorderedMap<String, String> nameMap;
algorithm
  comment.annotation_ := Util.applyOption(comment.annotation_, function renameElementsInAnnotation(nameMap = nameMap));
end renameElementsInComment;

function renameElementsInAnnotationOpt
  input output Option<Absyn.Annotation> ann;
  input UnorderedMap<String, String> nameMap;
algorithm
  ann := Util.applyOption(ann, function renameElementsInAnnotation(nameMap = nameMap));
end renameElementsInAnnotationOpt;

function renameElementsInAnnotation
  input output Absyn.Annotation ann;
  input UnorderedMap<String, String> nameMap;
algorithm
  ann.elementArgs := list(renameElementsInElementArg(a, nameMap) for a in ann.elementArgs);
end renameElementsInAnnotation;

function renameElementsInModificationOpt
  input output Option<Absyn.Modification> mod;
  input UnorderedMap<String, String> nameMap;
algorithm
  mod := Util.applyOption(mod, function renameElementsInModification(nameMap = nameMap));
end renameElementsInModificationOpt;

function renameElementsInModification
  input output Absyn.Modification mod;
  input UnorderedMap<String, String> nameMap;
algorithm
  mod.elementArgLst := list(renameElementsInElementArg(a, nameMap) for a in mod.elementArgLst);
  mod.eqMod := renameElementsInEqMod(mod.eqMod, nameMap);
end renameElementsInModification;

function renameElementsInEqMod
  input output Absyn.EqMod eqMod;
  input UnorderedMap<String, String> nameMap;
algorithm
  () := match eqMod
    case Absyn.EqMod.EQMOD()
      algorithm
        eqMod.exp := AbsynUtil.traverseExp(eqMod.exp, renameElementsInExp, nameMap);
      then
        ();

    else ();
  end match;
end renameElementsInEqMod;

function renameElementsInExp
  input output Absyn.Exp exp;
  input output UnorderedMap<String, String> nameMap;
algorithm
  () := match exp
    case Absyn.Exp.CREF()
      algorithm
        exp.componentRef := renameElementsInCref(exp.componentRef, nameMap);
      then
        ();

    case Absyn.Exp.CALL()
      algorithm
        exp.function_ := renameElementsInCref(exp.function_, nameMap);
      then
        ();

    case Absyn.Exp.PARTEVALFUNCTION()
      algorithm
        exp.function_ := renameElementsInCref(exp.function_, nameMap);
      then
        ();

    else ();
  end match;
end renameElementsInExp;

function renameElementsInCref
  input output Absyn.ComponentRef cref;
  input UnorderedMap<String, String> nameMap;
  input Boolean onlySubs = false;
algorithm
  () := match cref
    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        if not onlySubs then
          cref.name := renameElementsInIdent(cref.name, nameMap);
        end if;

        cref.subscripts := list(renameElementsInSubscript(s, nameMap) for s in cref.subscripts);
        cref.componentRef := renameElementsInCref(cref.componentRef, nameMap, onlySubs = true);
      then
        ();

    case Absyn.ComponentRef.CREF_IDENT()
      algorithm
        if not onlySubs then
          cref.name := renameElementsInIdent(cref.name, nameMap);
        end if;

        cref.subscripts := list(renameElementsInSubscript(s, nameMap) for s in cref.subscripts);
      then
        ();

    else ();
  end match;
end renameElementsInCref;

function renameElementsInPath
  input output Absyn.Path path;
  input UnorderedMap<String, String> nameMap;
algorithm
  () := match path
    case Absyn.Path.QUALIFIED()
      algorithm
        path.name := renameElementsInIdent(path.name, nameMap);
      then
        ();

    case Absyn.Path.IDENT()
      algorithm
        path.name := renameElementsInIdent(path.name, nameMap);
      then
        ();

    else ();
  end match;
end renameElementsInPath;

function renameElementsInIdent
  input output String ident;
  input UnorderedMap<String, String> nameMap;
algorithm
  ident := UnorderedMap.getOrDefault(ident, nameMap, ident);
end renameElementsInIdent;

function renameElementsInSubscripts
  input output list<Absyn.Subscript> subs;
  input UnorderedMap<String, String> nameMap;
algorithm
  subs := list(renameElementsInSubscript(s, nameMap) for s in subs);
end renameElementsInSubscripts;

function renameElementsInSubscript
  input output Absyn.Subscript sub;
  input UnorderedMap<String, String> nameMap;
algorithm
  () := match sub
    case Absyn.Subscript.SUBSCRIPT()
      algorithm
        sub.subscript := AbsynUtil.traverseExp(sub.subscript, renameElementsInExp, nameMap);
      then
        ();

    else ();
  end match;
end renameElementsInSubscript;

function renameElementsInExternalDecl
  input output Absyn.ExternalDecl extDecl;
  input UnorderedMap<String, String> nameMap;
algorithm
  extDecl.args := list(renameElementsInExp(a, nameMap) for a in extDecl.args);
  extDecl.annotation_ := renameElementsInAnnotationOpt(extDecl.annotation_, nameMap);
end renameElementsInExternalDecl;

function renameElementsInTypeSpec
  input output Absyn.TypeSpec spec;
  input UnorderedMap<String, String> nameMap;
algorithm
  () := match spec
    case Absyn.TypeSpec.TPATH()
      algorithm
        spec.path := renameElementsInPath(spec.path, nameMap);
        spec.arrayDim := Util.applyOption(spec.arrayDim, function renameElementsInSubscripts(nameMap = nameMap));
      then
        ();

    case Absyn.TypeSpec.TCOMPLEX()
      algorithm
        spec.path := renameElementsInPath(spec.path, nameMap);
        spec.arrayDim := Util.applyOption(spec.arrayDim, function renameElementsInSubscripts(nameMap = nameMap));
      then
        ();
  end match;
end renameElementsInTypeSpec;

function renameElementsInAttributes
  input output Absyn.ElementAttributes attrs;
  input UnorderedMap<String, String> nameMap;
algorithm
  attrs.arrayDim := renameElementsInSubscripts(attrs.arrayDim, nameMap);
end renameElementsInAttributes;

function renameElementsInComponentItem
  input output Absyn.ComponentItem component;
  input UnorderedMap<String, String> nameMap;
  input Boolean renameElement;
protected
  Absyn.Exp exp;
algorithm
  component.component := renameElementsInComponent(component.component, nameMap, renameElement);

  if isSome(component.condition) then
    SOME(exp) := component.condition;
    exp := AbsynUtil.traverseExp(exp, renameElementsInExp, nameMap);
    component.condition := SOME(exp);
  end if;

  component.comment := renameElementsInCommentOpt(component.comment, nameMap);
end renameElementsInComponentItem;

function renameElementsInComponent
  input output Absyn.Component component;
  input UnorderedMap<String, String> nameMap;
  input Boolean renameElement;
algorithm
  if renameElement then
    component.name := renameElementsInIdent(component.name, nameMap);
  end if;

  component.arrayDim := renameElementsInSubscripts(component.arrayDim, nameMap);
  component.modification := renameElementsInModificationOpt(component.modification, nameMap);
end renameElementsInComponent;

public function getInheritedAnnotation
  "Returns the modification for a specific annotation in a class, while also
   recursively looking up and merging annotations inherited from extends.
   If there are multiple non-identical inherited annotation only the first one
   is used, and a warning message is optionally emitted."
  input Absyn.Path modelPath;
  input String annotationName;
  input Absyn.Program program;
  input Boolean printConflictWarning = true "Prints a warning if inherited annotations conflict.";
  output Option<Absyn.Modification> outAnnotation = NONE();
protected
  Absyn.Class cls;
  list<Absyn.Path> extends_paths;
  list<Option<Absyn.Modification>> extends_oannl;
  Absyn.Modification cls_ann, extends_ann, extends_ann2;
  Absyn.Path extends_path;
algorithm
  // Look up the annotation in the given model.
  cls := getPathedClassInProgram(modelPath, program);
  outAnnotation := AbsynUtil.lookupClassAnnotation(cls, annotationName);

  // Fetch the named annotation from all inherited classes.
  ErrorExt.setCheckpoint(getInstanceName());
  try
    extends_paths := NFApi.getInheritedClasses(modelPath, program);
  else
    extends_paths := {};
  end try;
  ErrorExt.rollBack(getInstanceName());

  if listEmpty(extends_paths) then
    // No extends.
    return;
  end if;

  extends_oannl := list(getInheritedAnnotation(ep, annotationName, program) for ep in extends_paths);

  while not listEmpty(extends_oannl) loop
    if isSome(listHead(extends_oannl)) then
      // Found an inherited annotation, merge it with the class' annotation if
      // it has one or just return it as it is.
      extends_ann := Util.getOption(listHead(extends_oannl));

      if isSome(outAnnotation) then
        outAnnotation := SOME(AbsynUtil.mergeModifiers(Util.getOption(outAnnotation), extends_ann));
      else
        outAnnotation := SOME(extends_ann);
      end if;

      if printConflictWarning then
        // Check if we have any more inherited annotations.
        extends_path :: extends_paths := extends_paths;
        for a in listRest(extends_oannl) loop
          if isSome(a) then
            SOME(extends_ann2) := a;
            if not valueEq(extends_ann, extends_ann2) then
              // Found an inherited annotation that's not equal to the first one, print a warning.
              Error.addMessage(Error.CONFLICTING_INHERITED_ANNOTATIONS,
                {annotationName, AbsynUtil.pathString(modelPath),
                 Dump.unparseModificationStr(extends_ann), AbsynUtil.pathString(extends_path),
                 Dump.unparseModificationStr(extends_ann2), AbsynUtil.pathString(listHead(extends_paths))});
              break;
            end if;

            extends_paths := listRest(extends_paths);
          end if;
        end for;
      end if;

      // Return the merged annotation.
      return;
    end if;

    extends_oannl := listRest(extends_oannl);
    extends_paths := listRest(extends_paths);
  end while;
end getInheritedAnnotation;

public function setElementType
  input Absyn.Path elementPath;
  input Absyn.ComponentRef className;
  input output Absyn.Program program;
        output Boolean success = true;
protected
  Option<Absyn.Annotation> ann;
  String name;
  Option<Absyn.Element> elem_opt;
  Absyn.TypeSpec ty;
algorithm
  try
    ty := AbsynUtil.crefToTypeSpec(className);
    (program, elem_opt, success) := transformPathedElementInProgram(elementPath,
      function AbsynUtil.setElementType(typeSpec = ty, allowMultipleComponents = false), program);

    if success then
      SymbolTable.setAbsynElement(program, Util.getOption(elem_opt), elementPath);
    end if;
  else
    success := false;
  end try;
end setElementType;

function makeCommentFromArgs
  input Absyn.Exp commentExp;
  input Absyn.Exp annotationExp;
  input Option<Absyn.Comment> oldComment = NONE();
  output Option<Absyn.Comment> comment;
protected
  Option<Absyn.Annotation> ann, old_ann;
  Option<String> cmt, old_cmt;
algorithm
  cmt := match commentExp
    case Absyn.Exp.TUPLE(expressions = {}) then NONE();
    case Absyn.Exp.STRING() then SOME(commentExp.value);
  end match;

  ann := match annotationExp
    case Absyn.Exp.TUPLE(expressions = {}) then NONE();
    else SOME(Absyn.Annotation.ANNOTATION({recordConstructorToModification(annotationExp)}));
  end match;

  if isSome(cmt) or isSome(ann) then
    cmt := if isSome(cmt) then cmt else AbsynUtil.getCommentOptComment(oldComment);
    ann := if isSome(ann) then ann else AbsynUtil.getCommentOptAnnotation(oldComment);
    comment := SOME(Absyn.Comment.COMMENT(ann, cmt));
  else
    comment := oldComment;
  end if;
end makeCommentFromArgs;

function makeModifierFromArgs
  input Absyn.Exp bindingExp;
  input Absyn.Modification modifier;
  input SourceInfo info;
  input Option<Absyn.Modification> oldModifier = NONE();
  output Option<Absyn.Modification> outModifier;
algorithm
  outModifier := match (bindingExp, modifier)
    // No binding, no modifier.
    case (Absyn.Exp.TUPLE(expressions = {}), Absyn.Modification.CLASSMOD(elementArgLst = {})) then oldModifier;
    // Only modifier.
    case (Absyn.Exp.TUPLE(expressions = {}), _) then SOME(modifier);
    // Binding, maybe modifier.
    case (_, Absyn.Modification.CLASSMOD())
      then SOME(Absyn.Modification.CLASSMOD(modifier.elementArgLst,
                  Absyn.EqMod.EQMOD(bindingExp, info)));
  end match;
end makeModifierFromArgs;

public function accessClass
  "Looks up a class and calls the given function on it, while also handling
   Access annotations and the nfAPINoise flag."
  input Absyn.Path classPath;
  input Absyn.Program program;
  input Fn fn;
  input Boolean evaluateParams = false;
  input Boolean graphicsExpMode = false;
  input Access accessLevel = Access.icon;
  output Values.Value result;

  partial function Fn
    input Absyn.Path classPath;
    input Absyn.Program program;
    input Access accessLevel;
    output Values.Value result;
  end Fn;
protected
  Access access;
  Boolean silent, eval_params, graphics_exp_mode;
algorithm
  eval_params := Config.getEvaluateParametersInAnnotations();
  graphics_exp_mode := Config.getGraphicsExpMode();

  try
    access := Interactive.checkAccessAnnotationAndEncryption(classPath, program);

    if access < accessLevel then
      Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
      result := ValuesUtil.makeBoolean(false);
      return;
    end if;

    silent := not Flags.isSet(Flags.NF_API_NOISE);
    if silent then
      ErrorExt.setCheckpoint(getInstanceName());
    end if;

    Config.setEvaluateParametersInAnnotations(evaluateParams);
    Config.setGraphicsExpMode(graphicsExpMode);
    result := fn(classPath, program, access);
  else
    result := ValuesUtil.makeBoolean(false);
  end try;

  if silent then
    ErrorExt.rollBack(getInstanceName());
  end if;

  Config.setGraphicsExpMode(graphics_exp_mode);
  Config.setEvaluateParametersInAnnotations(eval_params);
end accessClass;

function makeAnnotationArrayValue
  "Some of the old functions that handle annotations just dumps the annotations
   to strings, but the new API functions need to return Values. Until those
   functions have been rewritten to create Values instead we can abuse TypeName
   expressions to get the correct output.
   TODO: Rewrite old functions that return strings instead of Values and get
         rid of this hack."
  input list<String> annotations;
  output Values.Value arr;
algorithm
  arr := ValuesUtil.makeArray(list(ValuesUtil.makeCodeTypeNameStr(s) for s in annotations));
end makeAnnotationArrayValue;

function parseWithinPath
  input Absyn.Path path;
  output Absyn.Within outWithin;
algorithm
  outWithin := match path
    case Absyn.Path.IDENT("__OpenModelica_TopLevel") then Absyn.Within.TOP();
    else Absyn.Within.WITHIN(path);
  end match;
end parseWithinPath;

function offsetAnnotationsInClassDef
  input output Absyn.ClassDef cdef;
  input Integer x;
  input Integer y;
algorithm
  if x == 0 and y == 0 then
    return;
  end if;

  () := match cdef
    case Absyn.ClassDef.PARTS()
      algorithm
        cdef.classParts := list(offsetAnnotationsInClassPart(p, x, y) for p in cdef.classParts);
        cdef.ann := list(offsetDiagramAnnotation(a, x, y) for a in cdef.ann);
      then
        ();

    case Absyn.ClassDef.DERIVED()
      algorithm
        cdef.comment := offsetDiagramAnnotationInOptComment(cdef.comment, x, y);
      then
        ();

    case Absyn.ClassDef.ENUMERATION()
      algorithm
        cdef.comment := offsetDiagramAnnotationInOptComment(cdef.comment, x, y);
      then
        ();

    case Absyn.ClassDef.OVERLOAD()
      algorithm
        cdef.comment := offsetDiagramAnnotationInOptComment(cdef.comment, x, y);
      then
        ();

    case Absyn.ClassDef.CLASS_EXTENDS()
      algorithm
        cdef.parts := list(offsetAnnotationsInClassPart(p, x, y) for p in cdef.parts);
        cdef.ann := list(offsetDiagramAnnotation(a, x, y) for a in cdef.ann);
      then
        ();

    case Absyn.ClassDef.PDER()
      algorithm
        cdef.comment := offsetDiagramAnnotationInOptComment(cdef.comment, x, y);
      then
        ();

  end match;
end offsetAnnotationsInClassDef;

function offsetAnnotationsInClassPart
  input output Absyn.ClassPart part;
  input Integer x;
  input Integer y;
algorithm
  () := match part
    case Absyn.ClassPart.PUBLIC()
      algorithm
        part.contents := list(offsetAnnotationsInElementItem(i, x, y) for i in part.contents);
      then
        ();

    case Absyn.ClassPart.PROTECTED()
      algorithm
        part.contents := list(offsetAnnotationsInElementItem(i, x, y) for i in part.contents);
      then
        ();

    case Absyn.ClassPart.EQUATIONS()
      algorithm
        part.contents := list(offsetAnnotationsInEquationItem(e, x, y) for e in part.contents);
      then
        ();

    else ();
  end match;
end offsetAnnotationsInClassPart;

function offsetAnnotationsInElementItem
  input output Absyn.ElementItem item;
  input Integer x;
  input Integer y;
algorithm
  () := match item
    case Absyn.ElementItem.ELEMENTITEM()
      algorithm
        item.element := offsetAnnotationsInElement(item.element, x, y);
      then
        ();

    else ();
  end match;
end offsetAnnotationsInElementItem;

function offsetAnnotationsInElement
  input output Absyn.Element element;
  input Integer x;
  input Integer y;
algorithm
  () := match element
    case Absyn.Element.ELEMENT()
      algorithm
        element.specification := offsetAnnotationsInElementSpec(element.specification, x, y);
      then
        ();

    else ();
  end match;
end offsetAnnotationsInElement;

function offsetAnnotationsInElementSpec
  input output Absyn.ElementSpec spec;
  input Integer x;
  input Integer y;
algorithm
  () := match spec
    case Absyn.ElementSpec.COMPONENTS()
      algorithm
        spec.components := list(offsetAnnotationsInComponentItem(c, x, y) for c in spec.components);
      then
        ();

    else ();
  end match;
end offsetAnnotationsInElementSpec;

constant Absyn.Path PLACEMENT_ORIGIN_PATH =
  Absyn.Path.QUALIFIED("Placement", Absyn.Path.QUALIFIED("transformation", Absyn.Path.IDENT("origin")));
constant Absyn.Path LINE_POINTS_PATH = Absyn.Path.QUALIFIED("Line", Absyn.Path.IDENT("points"));
constant Absyn.Path DIAGRAM_GRAPHICS_PATH = Absyn.Path.QUALIFIED("Diagram", Absyn.Path.IDENT("graphics"));

function offsetAnnotationsInComponentItem
  input output Absyn.ComponentItem item;
  input Integer x;
  input Integer y;
protected
  Option<Absyn.Annotation> oann;
  Absyn.Annotation ann;
algorithm
  oann := AbsynUtil.getCommentOptAnnotation(item.comment);
  ann := if isSome(oann) then Util.getOption(oann) else Absyn.Annotation.ANNOTATION({});
  ann := AbsynUtil.transformAnnotationArg(ann, PLACEMENT_ORIGIN_PATH, function offsetOriginAnnotation(x = x, y = y));
  item := AbsynUtil.setComponentItemAnnotation(item, SOME(ann));
end offsetAnnotationsInComponentItem;

function offsetOriginAnnotation
  input output Absyn.ElementArg arg;
  input Integer x;
  input Integer y;
protected
  Absyn.Modification mod;
  Absyn.EqMod eq_mod;
algorithm
  () := match arg
    case Absyn.ElementArg.MODIFICATION()
      algorithm
        if isSome(arg.modification) then
          SOME(mod) := arg.modification;
        else
          mod := Absyn.Modification.CLASSMOD({}, Absyn.EqMod.NOMOD());
        end if;

        eq_mod := mod.eqMod;
        mod.eqMod := match eq_mod
          case Absyn.EqMod.EQMOD()
            algorithm
              eq_mod.exp := offsetPointExpression(eq_mod.exp, x, y);
            then
              eq_mod;

          else Absyn.EqMod.EQMOD(makeOrigin(x, y), AbsynUtil.dummyInfo);
        end match;

        arg.modification := SOME(mod);
      then
        ();
  end match;
end offsetOriginAnnotation;

function makeOrigin
  input Integer x;
  input Integer y;
  output Absyn.Exp origin = Absyn.Exp.ARRAY({Absyn.Exp.INTEGER(x), Absyn.Exp.INTEGER(y)});
end makeOrigin;

function offsetPointExpression
  input output Absyn.Exp point;
  input Integer x;
  input Integer y;
protected
  Absyn.Exp e1, e2;
algorithm
  point := match point
    case Absyn.Exp.ARRAY(arrayExp = {e1, e2})
      then Absyn.Exp.ARRAY({offsetIntegerExpression(e1, x), offsetIntegerExpression(e2, y)});
    else Absyn.Exp.BINARY(point, Absyn.Operator.ADD(), makeOrigin(x, y));
  end match;
end offsetPointExpression;

function offsetIntegerExpression
  input output Absyn.Exp exp;
  input Integer offset;
protected
  Integer v;
algorithm
  exp := match exp
    case Absyn.Exp.INTEGER() then Absyn.Exp.INTEGER(exp.value + offset);
    case Absyn.Exp.UNARY(op = Absyn.Operator.UPLUS(), exp = Absyn.Exp.INTEGER(v)) then Absyn.Exp.INTEGER(v + offset);
    case Absyn.Exp.UNARY(op = Absyn.Operator.UMINUS(), exp = Absyn.Exp.INTEGER(v)) then Absyn.Exp.INTEGER(-v + offset);
    else if offset > 0 then Absyn.Exp.BINARY(exp, Absyn.Operator.ADD(), Absyn.Exp.INTEGER(offset))
         elseif offset < 0 then Absyn.Exp.BINARY(exp, Absyn.Operator.SUB(), Absyn.Exp.INTEGER(-offset))
         else exp;
  end match;
end offsetIntegerExpression;

function offsetLineExpression
  input output Absyn.Exp line;
  input Integer x;
  input Integer y;
algorithm
  () := match line
    case Absyn.Exp.ARRAY()
      algorithm
        line.arrayExp := list(offsetPointExpression(p, x, y) for p in line.arrayExp);
      then
        ();

    else ();
  end match;
end offsetLineExpression;

function offsetAnnotationsInEquationItem
  input output Absyn.EquationItem item;
  input Integer x;
  input Integer y;
protected
  Absyn.Comment cmt;
  Absyn.Annotation ann;
algorithm
  () := matchcontinue item
    case Absyn.EquationItem.EQUATIONITEM(comment = SOME(cmt as Absyn.COMMENT(annotation_ = SOME(ann))))
      algorithm
        ann := AbsynUtil.transformAnnotationArg(ann, LINE_POINTS_PATH,
          function offsetConnectionLineAnnotation(x = x, y = y), insert = false);
        cmt.annotation_ := SOME(ann);
        item.comment := SOME(cmt);
      then
        ();

    else ();
  end matchcontinue;
end offsetAnnotationsInEquationItem;

function offsetConnectionLineAnnotation
  input output Absyn.ElementArg arg;
  input Integer x;
  input Integer y;
protected
  Absyn.Modification mod;
  Absyn.EqMod eq_mod;
algorithm
  () := match arg
    case Absyn.ElementArg.MODIFICATION(modification = SOME(Absyn.Modification.CLASSMOD(eqMod = eq_mod as Absyn.EqMod.EQMOD())))
      algorithm
        eq_mod.exp := offsetLineExpression(eq_mod.exp, x, y);
        arg.modification := SOME(Absyn.Modification.CLASSMOD({}, eq_mod));
      then
        ();

    else ();
  end match;
end offsetConnectionLineAnnotation;

function offsetDiagramAnnotationInOptComment
  input output Option<Absyn.Comment> cmt;
  input Integer x;
  input Integer y;
protected
  Option<String> cmt_str;
  Absyn.Annotation ann;
algorithm
  () := match cmt
    case SOME(Absyn.Comment.COMMENT(SOME(ann), cmt_str))
      algorithm
        ann := offsetDiagramAnnotation(ann, x, y);
        cmt := SOME(Absyn.Comment.COMMENT(SOME(ann), cmt_str));
      then
        ();

    else ();
  end match;
end offsetDiagramAnnotationInOptComment;

function offsetDiagramAnnotation
  input output Absyn.Annotation ann;
  input Integer x;
  input Integer y;
algorithm
  ann := AbsynUtil.transformAnnotationArg(ann, DIAGRAM_GRAPHICS_PATH,
    function offsetGraphicsAnnotation(x = x, y = y));
end offsetDiagramAnnotation;

function offsetGraphicsAnnotation
  input output Absyn.ElementArg arg;
  input Integer x;
  input Integer y;
protected
  Absyn.Modification mod;
  Absyn.EqMod eq_mod;
algorithm
  () := match arg
    case Absyn.ElementArg.MODIFICATION(modification = SOME(Absyn.Modification.CLASSMOD(eqMod = eq_mod as Absyn.EqMod.EQMOD())))
      algorithm
        eq_mod.exp := offsetGraphicsExpression(eq_mod.exp, x, y);
        arg.modification := SOME(Absyn.Modification.CLASSMOD({}, eq_mod));
      then
        ();

    else ();
  end match;
end offsetGraphicsAnnotation;

function offsetGraphicsExpression
  input output Absyn.Exp graphics;
  input Integer x;
  input Integer y;
algorithm
  () := match graphics
    case Absyn.Exp.ARRAY()
      algorithm
        graphics.arrayExp := list(offsetGraphicsItemExpression(p, x, y) for p in graphics.arrayExp);
      then
        ();

    else ();
  end match;
end offsetGraphicsExpression;

function offsetGraphicsItemExpression
  input output Absyn.Exp item;
  input Integer x;
  input Integer y;
protected
  Absyn.FunctionArgs args;
  list<Absyn.NamedArg> named_args;
  Boolean found;
  Absyn.Exp visible, origin;
  list<Absyn.Exp> rest;

  function offset_named_origin
    input output Absyn.NamedArg arg;
    input Integer x;
    input Integer y;
          output Boolean found;
  algorithm
    found := arg.argName == "origin";

    if found then
      arg.argValue := offsetPointExpression(arg.argValue, x, y);
    end if;
  end offset_named_origin;
algorithm
  () := match item
    case Absyn.Exp.CALL(functionArgs = args as Absyn.FunctionArgs.FUNCTIONARGS())
      algorithm
        if listLength(args.args) >= 2 then
          // If there are two or more positional argument then origin is the second one.
          visible :: origin :: rest := args.args;
          origin := offsetPointExpression(origin, x, y);
          args.args := visible :: origin :: rest;
        else
          // Otherwise try to find and update a named origin argument.
          (named_args, found) := List.findMap(args.argNames, function offset_named_origin(x = x, y = y));

          if found then
            args.argNames := named_args;
          else
            // No origin was found, add it.
            args.argNames := Absyn.NamedArg.NAMEDARG("origin", makeOrigin(x, y)) :: args.argNames;
          end if;
        end if;

        item.functionArgs := args;
      then
        ();

    else ();
  end match;
end offsetGraphicsItemExpression;

annotation(__OpenModelica_Interface="backend");
end InteractiveUtil;
