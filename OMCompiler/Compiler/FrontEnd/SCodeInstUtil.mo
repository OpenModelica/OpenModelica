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

encapsulated package SCodeInstUtil
" file:        SCodeInstUtil.mo
  package:     SCodeInstUtil
  description: Utility functions for the SCode intermediate form for calling from the frontend"

import Absyn;
import SCode;

protected

import List;
import SCodeDump;
import SCodeUtil;

protected function constantBindingOrNone
"@author: adrpo
 keeps the constant binding and if not returns none"
  input Option<Absyn.Exp> inBinding;
  output Option<Absyn.Exp> outBinding;
algorithm
  outBinding := match (inBinding)
    local
      Absyn.Exp e;

    // keep it
    case SOME(e)
      then if listEmpty(AbsynUtil.getCrefFromExp(e, true, true)) then inBinding else NONE();
    // else
    else NONE();
  end match;
end constantBindingOrNone;

public function removeNonConstantBindingsKeepRedeclares
"@author: adrpo
 keeps the redeclares and removes all non-constant bindings!
 if onlyRedeclare is true then bindings are removed completely!"
  input SCode.Mod inMod;
  input Boolean onlyRedeclares;
  output SCode.Mod outMod;
algorithm
  outMod := match (inMod, onlyRedeclares)
    local
      list<SCode.SubMod> sl;
      SCode.Final fp;
      SCode.Each ep;
      SourceInfo i;
      Option<Absyn.Exp> binding;
      Option<String> cmt;

    case (SCode.MOD(fp, ep, sl, binding, cmt, i), _)
      equation
        binding = if onlyRedeclares then NONE() else constantBindingOrNone(binding);
        sl = removeNonConstantBindingsKeepRedeclaresFromSubMod(sl, onlyRedeclares);
      then
        SCode.MOD(fp, ep, sl, binding, cmt, i);

    case (SCode.REDECL(), _) then inMod;

    else inMod;

  end match;
end removeNonConstantBindingsKeepRedeclares;

protected function removeNonConstantBindingsKeepRedeclaresFromSubMod
"@author: adrpo
 removes the non-constant bindings in submods and keeps the redeclares"
  input list<SCode.SubMod> inSl;
  input Boolean onlyRedeclares;
  output list<SCode.SubMod> outSl;
algorithm
  outSl := match(inSl, onlyRedeclares)
    local
      String n;
      list<SCode.SubMod> sl,rest;
      SCode.Mod m;
      list<SCode.Subscript> ssl;

    case ({}, _) then {};

    case (SCode.NAMEMOD(n, m)::rest, _)
      equation
        m = removeNonConstantBindingsKeepRedeclares(m, onlyRedeclares);
        sl = removeNonConstantBindingsKeepRedeclaresFromSubMod(rest, onlyRedeclares);
      then
        SCode.NAMEMOD(n, m)::sl;

  end match;
end removeNonConstantBindingsKeepRedeclaresFromSubMod;

public function addRedeclareAsElementsToExtends
"add the redeclare-as-element elements to extends"
  input list<SCode.Element> inElements;
  input list<SCode.Element> redeclareElements;
  output list<SCode.Element> outExtendsElements;
algorithm
  outExtendsElements := match (inElements, redeclareElements)
    local
      SCode.Element el;
      list<SCode.Element> redecls, rest, out;
      Absyn.Path baseClassPath;
      SCode.Visibility visibility;
      SCode.Mod mod;
      Option<SCode.Annotation> ann "the extends annotation";
      SourceInfo info;
      SCode.Mod redeclareMod;
      list<SCode.SubMod> submods;

    // empty, return the same
    case (_, {}) then inElements;

    // empty elements
    case ({}, _) then {};

    // we got some
    case (SCode.EXTENDS(baseClassPath, visibility, mod, ann, info)::rest, redecls)
      equation
        submods = makeElementsIntoSubMods(SCode.NOT_FINAL(), SCode.NOT_EACH(), redecls);
        redeclareMod = SCode.MOD(SCode.NOT_FINAL(), SCode.NOT_EACH(), submods, NONE(), NONE(), info);
        mod = SCodeUtil.mergeSCodeMods(redeclareMod, mod);
        out = addRedeclareAsElementsToExtends(rest, redecls);
      then
        SCode.EXTENDS(baseClassPath, visibility, mod, ann, info)::out;

    // ignore non-extends
    case (el::rest, redecls)
      equation
        out = addRedeclareAsElementsToExtends(rest, redecls);
      then
        el::out;

  end match;
end addRedeclareAsElementsToExtends;

protected function makeElementsIntoSubMods
"transform elements into submods with named mods"
  input SCode.Final inFinal;
  input SCode.Each inEach;
  input list<SCode.Element> inElements;
  output list<SCode.SubMod> outSubMods;
algorithm
  outSubMods := match (inFinal, inEach, inElements)
    local
      SCode.Element el;
      list<SCode.Element> rest;
      SCode.Final f;
      SCode.Each e;
      SCode.Ident n;
      list<SCode.SubMod> newSubMods;

    // empty
    case (_, _, {}) then {};

    // class extends, error!
    case (f, e, (el as SCode.CLASS(classDef = SCode.CLASS_EXTENDS()))::rest)
      equation
        // print an error here
        print("- AbsynToSCode.makeElementsIntoSubMods ignoring class-extends redeclare-as-element: " + SCodeDump.unparseElementStr(el,SCodeDump.defaultOptions) + "\n");
        // recurse
        newSubMods = makeElementsIntoSubMods(f, e, rest);
      then
        newSubMods;

    // component
    case (f, e, (el as SCode.COMPONENT(name = n))::rest)
      equation
        // recurse
        newSubMods = makeElementsIntoSubMods(f, e, rest);
      then
        SCode.NAMEMOD(n,SCode.REDECL(f,e,el))::newSubMods;

    // class
    case (f, e, (el as SCode.CLASS(name = n))::rest)
      equation
        // recurse
        newSubMods = makeElementsIntoSubMods(f, e, rest);
      then
        SCode.NAMEMOD(n,SCode.REDECL(f,e,el))::newSubMods;

    // rest
    case (f, e, el::rest)
      equation
        // print an error here
        print("- AbsynToSCode.makeElementsIntoSubMods ignoring redeclare-as-element redeclaration: " + SCodeDump.unparseElementStr(el,SCodeDump.defaultOptions) + "\n");
        // recurse
        newSubMods = makeElementsIntoSubMods(f, e, rest);
      then
        newSubMods;
  end match;
end makeElementsIntoSubMods;

protected function removeReferenceInBinding
"@author: adrpo
 remove the binding that contains a cref"
  input Option<Absyn.Exp> inBinding;
  input Absyn.ComponentRef inCref;
  output Option<Absyn.Exp> outBinding;
algorithm
  outBinding := match inBinding
    local
      Absyn.Exp e;
      list<Absyn.ComponentRef> crlst1, crlst2;

    // if cref is not present keep the binding!
    case SOME(e)
      equation
        crlst1 = AbsynUtil.getCrefFromExp(e, true, true);
        crlst2 = AbsynUtil.removeCrefFromCrefs(crlst1, inCref);
      then if intEq(listLength(crlst1), listLength(crlst2)) then inBinding else NONE();
    // else
    else NONE();
  end match;
end removeReferenceInBinding;

public function removeSelfReferenceFromMod
"@author: adrpo
 remove the self reference from mod!"
  input SCode.Mod inMod;
  input Absyn.ComponentRef inCref;
  output SCode.Mod outMod;
algorithm
  outMod := match (inMod, inCref)
    local
      list<SCode.SubMod> sl;
      SCode.Final fp;
      SCode.Each ep;
      SourceInfo i;
      Option<Absyn.Exp> binding;
      Option<String> cmt;

    case (SCode.MOD(fp, ep, sl, binding, cmt, i), _)
      equation
        binding = removeReferenceInBinding(binding, inCref);
        sl = removeSelfReferenceFromSubMod(sl, inCref);
      then
        SCode.MOD(fp, ep, sl, binding, cmt, i);

    case (SCode.REDECL(), _) then inMod;

    else inMod;

  end match;
end removeSelfReferenceFromMod;

protected function removeSelfReferenceFromSubMod
"@author: adrpo
 removes the self references from a submod"
  input list<SCode.SubMod> inSl;
  input Absyn.ComponentRef inCref;
  output list<SCode.SubMod> outSl;
algorithm
  outSl := match(inSl, inCref)
    local
      String n;
      list<SCode.SubMod> sl,rest;
      SCode.Mod m;
      list<SCode.Subscript> ssl;

    case ({}, _) then {};

    case (SCode.NAMEMOD(n, m)::rest, _)
      equation
        m = removeSelfReferenceFromMod(m, inCref);
        sl = removeSelfReferenceFromSubMod(rest, inCref);
      then
        SCode.NAMEMOD(n, m)::sl;

  end match;
end removeSelfReferenceFromSubMod;

protected function expandEnumerationSubMod
  input SCode.SubMod inSubMod;
  input Boolean inChanged;
  output SCode.SubMod outSubMod;
  output Boolean outChanged;
algorithm
  (outSubMod, outChanged) := match inSubMod
    local
      SCode.Mod mod, mod1;
      SCode.Ident ident;
    case SCode.NAMEMOD(ident=ident, mod=mod)
      equation
        mod1 = expandEnumerationMod(mod);
      then
        if referenceEq(mod, mod1) then (inSubMod, inChanged) else (SCode.NAMEMOD(ident, mod1), true);
    else
      (inSubMod, inChanged);
  end match;
end expandEnumerationSubMod;

public function expandEnumerationMod
  input SCode.Mod inMod;
  output SCode.Mod outMod;
protected
  SCode.Final f;
  SCode.Each e;
  SCode.Element el, el1;
  list<SCode.SubMod> submod;
  Option<Absyn.Exp> binding;
  SourceInfo info;
  Boolean changed;
  Option<String> cmt;
algorithm
  outMod := match inMod
    case SCode.REDECL(f, e, el)
      equation
        el1 = expandEnumerationClass(el);
      then
        if referenceEq(el, el1) then inMod else SCode.REDECL(f, e, el1);

    case SCode.MOD(f, e, submod, binding, cmt, info)
      equation
        (submod, changed) = List.mapFold(submod, expandEnumerationSubMod, false);
      then if changed then SCode.MOD(f, e, submod, binding, cmt, info) else inMod;

    else inMod;
  end match;
end expandEnumerationMod;

public function expandEnumerationClass
"@author: PA, adrpo
 this function expands the enumeration from a list into a class with components
 if the class is not an enumeration is kept as it is"
  input SCode.Element inElement;
  output SCode.Element outElement;
algorithm
  outElement := match(inElement)
    local
      SCode.Ident n;
      list<SCode.Enum> l;
      SCode.Comment cmt;
      SourceInfo info;
      SCode.Element c;
      SCode.Prefixes prefixes;
      SCode.Mod m, m1;
      Absyn.Path p;
      SCode.Visibility v;
      Option<SCode.Annotation> ann;

    case SCode.CLASS(name = n,restriction = SCode.R_TYPE(), prefixes = prefixes,
                     classDef = SCode.ENUMERATION(enumLst=l),cmt=cmt,info = info)
      equation
        c = expandEnumeration(n, l, prefixes, cmt, info);
      then
        c;

    case SCode.EXTENDS(baseClassPath = p, visibility = v, modifications = m, ann = ann, info = info)
      equation

        m1 = expandEnumerationMod(m);
      then
        if referenceEq(m, m1) then inElement else SCode.EXTENDS(p, v, m1, ann, info);

    else inElement;

  end match;
end expandEnumerationClass;

public function expandEnumeration
"author: PA
  This function takes an Ident and list of strings, and returns an enumeration class."
  input SCode.Ident n;
  input list<SCode.Enum> l;
  input SCode.Prefixes prefixes;
  input SCode.Comment cmt;
  input SourceInfo info;
  output SCode.Element outClass;
algorithm
  outClass :=
    SCode.CLASS(
     n,
     prefixes,
     SCode.NOT_ENCAPSULATED(),
     SCode.NOT_PARTIAL(),
     SCode.R_ENUMERATION(),
     makeEnumParts(l, info),
     cmt,
     info);
end expandEnumeration;

protected function makeEnumParts
  input list<SCode.Enum> inEnumLst;
  input SourceInfo info;
  output SCode.ClassDef classDef;
algorithm
  classDef := SCode.PARTS(makeEnumComponents(inEnumLst, info),{},{},{},{},{},{},NONE());
end makeEnumParts;

protected function makeEnumComponents
  "Translates a list of Enums to a list of elements of type EnumType."
  input list<SCode.Enum> inEnumLst;
  input SourceInfo info;
  output list<SCode.Element> outSCodeElementLst;
algorithm
  outSCodeElementLst := list(SCodeUtil.makeEnumType(e,info) for e in inEnumLst);
end makeEnumComponents;

annotation(__OpenModelica_Interface="frontend");
end SCodeInstUtil;
