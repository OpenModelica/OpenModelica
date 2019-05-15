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

encapsulated package FMod
" file:        FMod.mo
  package:     FMod
  description: Utilities for Modifier handling


  This module contains functions for modifier handling
"

// public imports
public
import Absyn;
import SCode;
import FCore;

// protected imports
protected
import List;
import Error;

public
type Name = FCore.Name;
type Id = FCore.Id;
type Seq = FCore.Seq;
type Next = FCore.Next;
type Node = FCore.Node;
type Data = FCore.Data;
type Kind = FCore.Kind;
type Ref = FCore.Ref;
type Refs = FCore.Refs;
type Children = FCore.Children;
type Parents = FCore.Parents;
type Scope = FCore.Scope;
type ImportTable = FCore.ImportTable;
type Graph = FCore.Graph;
type Extra = FCore.Extra;
type Visited = FCore.Visited;
type Import = FCore.Import;
type AvlTree = FCore.CAvlTree;
type AvlKey = FCore.CAvlKey;
type AvlValue = FCore.CAvlValue;
type AvlTreeValue = FCore.CAvlTreeValue;
type ModScope = FCore.ModScope;


public function merge
"@author: adrpo
 merge 2 modifiers, one outer one inner"
  input Ref inParentRef;
  input Ref inOuterModRef;
  input Ref inInnerModRef;
  input Graph inGraph;
  output Graph outGraph;
  output Ref outMergedModRef;
algorithm
  (outGraph, outMergedModRef) := match(inParentRef, inOuterModRef, inInnerModRef, inGraph)
    local
      Ref r;
      Graph g;
    case (r, _, _, g)
      equation
      then
        (g, r);
  end match;
end merge;

public function apply
"@author: adrpo
 apply the modifier to the given target"
  input Ref inTargetRef;
  input Ref inModRef;
  input Graph inGraph;
  output Graph outGraph;
  output Ref outNodeRef;
algorithm
  (outGraph, outNodeRef) := match(inTargetRef, inModRef, inGraph)
    local
      Ref r;
      Graph g;
    case (r, _, g)
      equation
      then
        (g, r);
  end match;
end apply;

public function compactSubMods
  "This function merges the submodifiers in a modifier so that each submodifier
    only occurs once. Ex:

    compactMod({x.start = 2.0, y = 4.0, x(min = 1.0, max = 3.0)}) =>
      {x(start = 2.0, min = 1.0, max = 3.0), y = 4.0}

  "
  input list<SCode.SubMod> inSubMods;
  input ModScope inModScope;
  output list<SCode.SubMod> outSubMods;
protected
  list<SCode.SubMod> submods;
algorithm
  submods := List.fold2(inSubMods, compactSubMod, inModScope, {}, {});
  outSubMods := listReverse(submods);
end compactSubMods;

protected function compactSubMod
  "Helper function to compactSubMods. Tries to merge the given modifier with an
   existing modifier in the accumulation list. If a matching modifier is not
   found in the list it's added instead."
  input SCode.SubMod inSubMod;
  input ModScope inModScope;
  input list<String> inName;
  input list<SCode.SubMod> inAccumMods;
  output list<SCode.SubMod> outSubMods;
protected
  String name;
  list<SCode.SubMod> submods;
  Boolean found;
algorithm
  SCode.NAMEMOD(name, _) := inSubMod;
  (submods, found) := List.findMap3(inAccumMods, compactSubMod2, inSubMod, inModScope, inName);
  outSubMods := List.consOnTrue(not found, inSubMod, submods);
end compactSubMod;

protected function compactSubMod2
  "Helper function to compactSubMod. Merges the given modifier with the existing
    modifier if they have the same name, otherwise does nothing."
  input SCode.SubMod inExistingMod;
  input SCode.SubMod inNewMod;
  input ModScope inModScope;
  input list<String> inName;
  output SCode.SubMod outMod;
  output Boolean outFound;
algorithm
  (outMod, outFound) := matchcontinue(inExistingMod, inNewMod, inModScope, inName)
    local
      String name1, name2;
      SCode.SubMod submod;

    case (SCode.NAMEMOD(ident = name1), SCode.NAMEMOD(ident = name2), _, _)
      equation
        false = stringEqual(name1, name2);
      then
        (inExistingMod, false);

    case (SCode.NAMEMOD(ident = name1), _, _, _)
      equation
        submod = mergeSubModsInSameScope(inExistingMod, inNewMod, name1 :: inName, inModScope);
      then
        (submod, true);

  end matchcontinue;
end compactSubMod2;

protected function mergeSubModsInSameScope
  "Merges two submodifiers in the same scope, i.e. they have the same priority.
   It's thus an error if the modifiers modify the same element."
  input SCode.SubMod inMod1;
  input SCode.SubMod inMod2;
  input list<String> inElementName;
  input ModScope inModScope;
  output SCode.SubMod outMod;
algorithm
  outMod := match(inMod1, inMod2, inElementName, inModScope)
    local
      String id, scope, name;
      SCode.Final fp;
      SCode.Each ep;
      list<SCode.SubMod> submods1, submods2;
      Option<Absyn.Exp> binding;
      SourceInfo info1, info2;
      SCode.Mod mod1, mod2;

    // The second modifier has no binding, use the binding from the first.
    case (SCode.NAMEMOD(id, SCode.MOD(fp, ep, submods1, binding, info1)),
          SCode.NAMEMOD(mod = SCode.MOD(subModLst = submods2, binding = NONE())), _, _)
      equation
        submods1 = List.fold2(submods1, compactSubMod, inModScope,
          inElementName, submods2);
      then
        SCode.NAMEMOD(id, SCode.MOD(fp, ep, submods1, binding, info1));

    // The first modifier has no binding, use the binding from the second.
    case (SCode.NAMEMOD(mod = SCode.MOD(subModLst = submods1, binding = NONE())),
          SCode.NAMEMOD(id, SCode.MOD(fp, ep, submods2, binding, info2)), _, _)
      equation
        submods1 = List.fold2(submods1, compactSubMod, inModScope,
          inElementName, submods2);
      then
        SCode.NAMEMOD(id, SCode.MOD(fp, ep, submods1, binding, info2));

    // The first modifier has no binding, use the binding from the second.
    case (SCode.NAMEMOD(mod = mod1), SCode.NAMEMOD(mod = mod2), _, _)
      equation
        info1 = SCode.getModifierInfo(mod1);
        info2 = SCode.getModifierInfo(mod2);
        scope = printModScope(inModScope);
        name = stringDelimitList(listReverse(inElementName), ".");
        Error.addMultiSourceMessage(Error.DUPLICATE_MODIFICATIONS,
          {name, scope}, {info2, info1});
      then
        fail();

  end match;
end mergeSubModsInSameScope;

protected function printModScope
  input ModScope inModScope;
  output String outString;
algorithm
  outString := match(inModScope)
    local
      String name;
      Absyn.Path path;

    case FCore.MS_COMPONENT(name = name) then "component " + name;
    case FCore.MS_EXTENDS(path = path) then "extends " + Absyn.pathString(path);
    case FCore.MS_DERIVED(path = path) then "inherited class " + Absyn.pathString(path);
    case FCore.MS_CLASS_EXTENDS(name = name) then "class extends class " + name;
    case FCore.MS_CONSTRAINEDBY(path = path) then "constrainedby class " + Absyn.pathString(path);

  end match;
end printModScope;

annotation(__OpenModelica_Interface="frontend");
end FMod;
