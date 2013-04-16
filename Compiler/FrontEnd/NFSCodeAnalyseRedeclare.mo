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

encapsulated package NFSCodeAnalyseRedeclare
" file:        NFSCodeAnalyseRedeclare.mo
  package:     NFSCodeAnalyseRedeclare
  description: SCode analysis of redeclares

  RCS: $Id: NFSCodeAnalyseRedeclare.mo 13614 2012-10-25 00:03:02Z perost $

  This module will do a dryrun of instantiation and find out
  where the redeclares are applied. This information is used
  by SCodeApplyRedeclare to apply the redeclares to the SCode.
"

public import Absyn;
public import DAE;
public import NFInstTypes;
public import NFInstTypesOld;
public import SCode;
public import NFSCodeEnv;
public import NFSCodeFlattenRedeclare;

protected import ClassInf;
protected import Debug;
protected import Error;
protected import Flags;
protected import NFInstUtil;
protected import List;
protected import NFSCodeCheck;
protected import SCodeDump;
protected import NFSCodeLookup;
protected import NFSCodeMod;
protected import Util;
protected import System;

public type Binding = NFInstTypesOld.Binding;
public type Dimension = NFInstTypes.Dimension;
public type Element = SCode.Element;
public type Program = SCode.Program;
public type Env = NFSCodeEnv.Env;
public type Modifier = NFInstTypesOld.Modifier;
public type ParamType = NFInstTypes.ParamType;
public type Prefix = NFInstTypes.Prefix;
public type Scope = Absyn.Within;
public type Item = NFSCodeEnv.Item;
public type Redeclarations = list<NFSCodeEnv.Redeclaration>;
public type Replacements = NFSCodeFlattenRedeclare.Replacements;
public type Replacement = NFSCodeFlattenRedeclare.Replacement;

public type InstStack = list<Absyn.Path>;
public constant InstStack emptyInstStack = {};

public constant Integer tmpTickIndex = 3;

public uniontype Info

  record RP "redeclare info"
    Replacements replacements;
  end RP;

  record RI "redeclared info, previous item before redeclare"
    Item item "previous item";
    Env env "the env where we looked it up";
  end RI;

  record EI "iscope info"
    Element element;
    Env env;
  end EI;

end Info;

type Infos = list<Info>;

public uniontype Kind
  record CL "class node"
    Absyn.Path name;
  end CL;

  record CO "component node"
    Prefix prefix;
    Absyn.Path scope;
  end CO;

  record EX "extends node"
    Absyn.Path name;
  end EX;

  record RE "redeclared node"
    Absyn.Path name;
  end RE;
end Kind;

public
uniontype IScope

  record IS
    Kind kind;
    Infos infos;
    IScopes parts;
  end IS;

end IScope;

public type IScopes = list<IScope>;

public constant IScopes emptyIScopes = {};

public function analyse
"analysis of where the redeclares are applied"
  input Absyn.Path inClassPath;
  input Env inEnv;
  output IScopes outIScopes;
algorithm
  outIScopes := matchcontinue(inClassPath, inEnv)
    local
      IScopes islist;
      String name;
      Env env;
      Item item;
      Absyn.Path path;

    case (_, _)
      equation
        //print("Starting the new redeclare analysis phase ...\n");
        name = Absyn.pathLastIdent(inClassPath);

        (item, path, env) = NFSCodeLookup.lookupClassName(inClassPath, inEnv, Absyn.dummyInfo);

        (islist, _) = analyseItem(
                       item,
                       env,
                       NFInstTypesOld.NOMOD(),
                       NFInstTypes.EMPTY_PREFIX(SOME(path)),
                       emptyIScopes,
                       emptyInstStack);

        // sort so classes are first in the childs
        islist = sortParts(islist);

        //print("Number of IScopes: " +& intString(iScopeSize(islist)) +& "\n");
        //print("Max Inst Scope: " +& intString(instScopesDepth(islist)) +& "\n");

        islist = filterRedeclareIScopes(islist, {});

        //print("Filtered Number of IScopes: " +& intString(iScopeSize(islist)) +& "\n");
        //print("Filtered Max Inst Scope: " +& intString(instScopesDepth(islist)) +& "\n");

        islist = collapseDerivedClassChain(islist, {});

        //print("After derived colapse Number of IScopes: " +& intString(iScopeSize(islist)) +& "\n");
        //print("After derived colapse Filtered Max Inst Scope: " +& intString(instScopesDepth(islist)) +& "\n");

        islist = fixpointCleanRedeclareIScopes(islist);

        //print("After fixpoint clean Number of IScopes: " +& intString(iScopeSize(islist)) +& "\n");
        //print("After fixpoint clean Filtered Max Inst Scope: " +& intString(instScopesDepth(islist)) +& "\n");

        printIScopes(islist);
      then
        islist;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        name = Absyn.pathString(inClassPath);
        Debug.traceln("NFSCodeAnalyseRedeclare.analyse failed on: " +& name);
      then
        fail();

  end matchcontinue;
end analyse;

protected function analyseItem
  input Item inItem;
  input Env inEnv;
  input Modifier inMod;
  input Prefix inPrefix;
  input IScopes inIScopesAcc;
  input InstStack inInstStack;
  output IScopes outIScopes;
  output InstStack outInstStack;
algorithm
  (outIScopes, outInstStack) :=
  matchcontinue(inItem, inEnv, inMod, inPrefix, inIScopesAcc, inInstStack)
    local
      list<Element> el;
      list<tuple<Element, Modifier>> mel;
      Absyn.TypeSpec dty, ts, tsFull;
      Item item;
      Env env, envDerived;
      Absyn.Info info;
      SCode.Mod smod;
      Modifier mod;
      NFSCodeEnv.AvlTree cls_and_vars;
      String name;
      Absyn.ArrayDim dims;
      Element scls;
      Integer dim_count;
      list<NFSCodeEnv.Extends> exts;
      SCode.Restriction res;
      SCode.Attributes attr;
      Option<SCode.Comment> cmt;
      InstStack ii;
      IScopes islist;
      IScope is;
      list<NFSCodeEnv.Redeclaration> redeclares;
      Replacements replacements;
      list<tuple<Item, Env>> previousItem;
      Infos infos;
      Absyn.Path fullName;

    // filter out some classes!
    case (NFSCodeEnv.CLASS(
            cls = scls as SCode.CLASS(name = name, restriction = res),
            env = env),
          _, _, _, _, _)
      equation
        true = listMember(name, {"equalityConstraint", "Orientation"});
        //is = mkIScope(CL(Absyn.IDENT(name)), {EI(scls, env)}, {});
        //islist = is::inIScopesAcc;
        islist = inIScopesAcc;
      then
        (islist, inInstStack);

    // filter out operators
    case (NFSCodeEnv.CLASS(
            cls = scls as SCode.CLASS(name = name, restriction = res),
            env = env),
          _, _, _, _, _)
      equation
        true = boolOr(SCode.isOperator(scls),
                      stringEq(name, "Complex"));
        islist = inIScopesAcc;
      then
        (islist, inInstStack);

    // extending basic type
    case (NFSCodeEnv.CLASS(
            cls = SCode.CLASS(name = name),
            classType = NFSCodeEnv.BASIC_TYPE()),
          _, _, _, _, _)
      equation
        //is = mkIScope(CL(Absyn.IDENT(name)),{}, {});
        //islist = is::inIScopesAcc;
        islist = inIScopesAcc;
      then
        (islist, inInstStack);

    // enumerations
    case (NFSCodeEnv.CLASS(
            cls = SCode.CLASS(name = name, classDef = SCode.ENUMERATION(enumLst = _))),
          _, _, _, _, _)
      equation
        //is = mkIScope(CL(Absyn.IDENT(name)),{}, {});
        //islist = is::inIScopesAcc;
        islist = inIScopesAcc;
      then
        (islist, inInstStack);

    // a derived class from basic type.
    case (NFSCodeEnv.CLASS(
            cls = scls as SCode.CLASS(name = name, classDef = SCode.DERIVED(dty, smod, attr, cmt), info = info)),
          _, _, _, _, _)
      equation
        // Look up the inherited class.
        (item as NFSCodeEnv.CLASS(classType = NFSCodeEnv.BASIC_TYPE()), _, env) =
          NFSCodeLookup.lookupTypeSpec(dty, inEnv, info);

        //is = mkIScope(CL(Absyn.IDENT(name)),{EI(scls, env)}, {});
        //islist = is::inIScopesAcc;
        islist = inIScopesAcc;
      then
        (islist, inInstStack);

    // a derived class, look up the inherited class and instantiate it.
    case (NFSCodeEnv.CLASS(
            cls = scls as SCode.CLASS(name = name, classDef = SCode.DERIVED(dty, smod, attr, cmt), info = info),
            env = envDerived),
          _, _, _, _, _)
      equation
        // Look up the inherited class.
        (item, ts, env) = NFSCodeLookup.lookupTypeSpec(dty, inEnv, info);
        tsFull = NFSCodeEnv.mergeTypeSpecWithEnvPath(ts, env);
        (item, env, previousItem) = NFSCodeEnv.resolveRedeclaredItem(item, env);

        // Merge the modifiers and instantiate the inherited class.
        dims = Absyn.typeSpecDimensions(dty);
        dim_count = listLength(dims);
        mod = NFSCodeMod.translateMod(smod, "", dim_count, inPrefix, inEnv);
        mod = NFSCodeMod.mergeMod(inMod, mod);

        // Apply the redeclarations from the derived environment!!!!
        // print("getting redeclares: item: " +& NFSCodeEnv.itemStr(item) +& "\n");
        redeclares = listAppend(
          NFSCodeEnv.getDerivedClassRedeclares(name, ts, envDerived),
          NFSCodeFlattenRedeclare.extractRedeclaresFromModifier(smod));
        (item, env, replacements) = NFSCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redeclares, item, env, inEnv, inPrefix);

        (islist, ii) = analyseItem(item, env, mod, inPrefix, emptyIScopes, inInstStack);

        scls = SCode.setDerivedTypeSpec(scls, tsFull);
        infos = mkInfos(previousItem, {RP(replacements), EI(scls, env)});

        fullName = NFSCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv);
        is = mkIScope(CL(fullName), infos, islist);
        islist = is::inIScopesAcc;
      then
        (islist, ii);

    // a class with parts, instantiate all elements in it.
    case (NFSCodeEnv.CLASS(
            cls = scls as SCode.CLASS(name = name, classDef = SCode.PARTS(elementLst = el), info = info),
            env = {NFSCodeEnv.FRAME(clsAndVars = cls_and_vars)}),
          _, _, _, _, _)
      equation

        // Enter the class scope and look up all class elements.
        env = NFSCodeEnv.mergeItemEnv(inItem, inEnv);

        // Apply modifications to the elements and instantiate them.
        mel = NFSCodeMod.applyModifications(inMod, el, inPrefix, env);
        exts = NFSCodeEnv.getEnvExtendsFromTable(env);

        (islist, ii) = analyseElementList(mel, exts, env, inPrefix, emptyIScopes, inInstStack);

        fullName = NFSCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv);

        is = mkIScope(CL(fullName), {EI(scls, inEnv)}, islist);
        islist = is::inIScopesAcc;
      then
        (islist, ii);

    // a class extends
    case (NFSCodeEnv.CLASS(
            cls = scls as SCode.CLASS(name = name), classType = NFSCodeEnv.CLASS_EXTENDS(), env = env),
          _, _, _, _, _)
      equation
        //(islist, ii) = analyseClassExtends(scls, inMod, env, inEnv, inPrefix, inIScopesAcc/*emptyIScopes*/, inInstStack);

        //fullName = NFSCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv);
        //is = mkIScope(CL(fullName), {EI(scls, env)}, islist);
        //islist = is::inIScopesAcc;
        islist = inIScopesAcc;
        ii = inInstStack;
      then
        (islist, ii);

    // a redeclared item
    case (NFSCodeEnv.REDECLARED_ITEM(item = item, declaredEnv = env), _, _, _, _, _)
      equation
        name = NFSCodeEnv.getItemName(item);
        (islist, ii) = analyseItem(item, env, inMod, inPrefix, emptyIScopes, inInstStack);

        fullName = NFSCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), env);
        is = mkIScope(RE(fullName), {RI(item, inEnv)}, islist);
        islist = is::inIScopesAcc;
      then
        (islist, ii);

    // failure
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("NFSCodeAnalyseRedeclare.instClassItem failed on unknown class.\n");
      then
        fail();

  end matchcontinue;
end analyseItem;

protected function analyseElementList
"Helper function to analyseItem."
  input list<tuple<Element, Modifier>> inElements;
  input list<NFSCodeEnv.Extends> inExtends;
  input Env inEnv;
  input Prefix inPrefix;
  input IScopes inIScopesAcc;
  input InstStack inInstStack;
  output IScopes outIScopes;
  output InstStack outInstStack;
algorithm
  (outIScopes, outInstStack) :=
  match(inElements, inExtends, inEnv, inPrefix, inIScopesAcc, inInstStack)
    local
      tuple<Element, Modifier> elem, new_elem;
      list<tuple<Element, Modifier>> rest_el;
      list<NFSCodeEnv.Extends> exts;
      InstStack ii;
      Env env;
      IScopes islist;
      String str;
      list<tuple<Item, Env>> previousItem;
      Modifier orig_mod;

    case (elem :: rest_el, exts, _, _, islist, _)
      equation
        (new_elem, orig_mod, env, previousItem) = resolveRedeclaredElement(elem, inEnv, inPrefix);
        (islist, exts, ii) = analyseElement_dispatch(new_elem, elem, orig_mod, exts, env, inPrefix, islist, inInstStack, previousItem);
        (islist, ii) = analyseElementList(rest_el, exts, inEnv, inPrefix, islist, ii);
      then
        (islist, ii);

    case ({}, {}, _, _, _, _) then (inIScopesAcc, inInstStack);

    // analyseElementList takes a list of Extends, which contains the extends
    // information from the environment. We should have one Extends element for
    // each extends clause, so if we have any left when we've run out of
    // elements something has gone very wrong.
    case ({}, _ :: _, _, _, _, _)
      equation
        str = "NFSCodeAnalyseRedeclare.analyseElementList has extends left! \n\t" +&
              stringDelimitList(List.map(inExtends, NFSCodeEnv.printExtendsStr), "\n\t");
        Error.addMessage(Error.INTERNAL_ERROR, {str});
        print(str);
      then
        fail();

  end match;
end analyseElementList;

public function resolveRedeclaredElement
  "This function makes sure that an element is up-to-date in case it has been
   redeclared. This is achieved by looking the element up in the environment. In
   the case that the element has been redeclared, the environment where it should
   be instantiated is returned, otherwise the old environment."
  input tuple<SCode.Element, Modifier> inElement;
  input Env inEnv;
  input Prefix inPrefix;
  output tuple<SCode.Element, Modifier> outElement;
  output Modifier outOriginalMod;
  output Env outEnv;
  output list<tuple<NFSCodeEnv.Item, Env>> outPreviousItem;
algorithm
  (outElement, outOriginalMod, outEnv, outPreviousItem) := match(inElement, inEnv, inPrefix)
    local
      Modifier mod, omod;
      String name;
      Item item;
      SCode.Element orig_el, new_el;
      Env env;
      list<tuple<NFSCodeEnv.Item, Env>> previousItem;

    // Only components which are actually replaceable needs to be looked up,
    // since non-replaceable components can't have been replaced.
    case ((orig_el as SCode.COMPONENT(name = name, prefixes =
        SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(_))), mod), _, _)
      equation
        (item, _) = NFSCodeLookup.lookupInClass(name, inEnv);
        (NFSCodeEnv.VAR(var = new_el), env, previousItem) = NFSCodeEnv.resolveRedeclaredItem(item, inEnv);
        omod = getOriginalMod(orig_el, inEnv, inPrefix);
      then
        ((new_el, mod), omod, env, previousItem);

    // Other elements doesn't need to be looked up. Extends may not be
    // replaceable, and classes are looked up in the environment anyway. The
    // exception is packages with constants, but those are handled in
    // instPackageConstants.
    else (inElement, NFInstTypesOld.NOMOD(), inEnv, {});

  end match;
end resolveRedeclaredElement;

protected function getOriginalMod
  input SCode.Element inOriginalElement;
  input Env inEnv;
  input Prefix inPrefix;
  output Modifier outModifier;
algorithm
  outModifier := match(inOriginalElement, inEnv, inPrefix)
    local
      SCode.Ident name;
      Absyn.ArrayDim ad;
      Integer dim_count;
      SCode.Mod smod;
      Modifier mod;

    case (SCode.COMPONENT(modifications = SCode.NOMOD()), _, _)
      then NFInstTypesOld.NOMOD();

    case (SCode.COMPONENT(name = name, attributes = SCode.ATTR(arrayDims = ad),
        modifications = smod), _, _)
      equation
        dim_count = listLength(ad);
        mod = NFSCodeMod.translateMod(smod, name, dim_count, inPrefix, inEnv);
      then
        mod;

  end match;
end getOriginalMod;

protected function analyseElement_dispatch
"Helper function to analyseElementList.
 Dispatches the given element to the correct function for transformation."
  input tuple<Element, Modifier> inElement;
  input tuple<Element, Modifier> inOriginalElement;
  input Modifier inOriginalMod;
  input list<NFSCodeEnv.Extends> inExtends;
  input Env inEnv;
  input Prefix inPrefix;
  input IScopes inIScopesAcc;
  input InstStack inInstStack;
  input list<tuple<Item, Env>> inPreviousItem;
  output IScopes outIScopes;
  output list<NFSCodeEnv.Extends> outExtends;
  output InstStack outInstStack;
algorithm
  (outIScopes, outExtends, outInstStack) :=
  matchcontinue(inElement, inOriginalElement, inOriginalMod, inExtends, inEnv, inPrefix, inIScopesAcc, inInstStack, inPreviousItem)
    local
      Element elem,  orig;
      Modifier mod;
      Redeclarations redecls;
      list<NFSCodeEnv.Extends> rest_exts;
      InstStack ii;
      IScopes islist;

    // A component
    case ((elem as SCode.COMPONENT(name = _), mod), (orig, _), _, _, _, _, _, _, _)
      equation
        (islist, ii) = analyseElement(elem, mod, orig, inOriginalMod, inEnv, inPrefix, inIScopesAcc, inInstStack, inPreviousItem);
      then
        (islist, inExtends, ii);

    // A class
    case ((elem as SCode.CLASS(name = _), mod), (orig, _), _, _, _, _, _, _, _)
      equation
        (islist, ii) = analyseElement(elem, mod, orig, inOriginalMod, inEnv, inPrefix, inIScopesAcc, inInstStack, inPreviousItem);
      then
        (islist, inExtends, ii);

    // An extends clause. Transform it it together with the next Extends element from the environment.
    case ((elem as SCode.EXTENDS(baseClassPath = _), mod), (orig, _), _,
          NFSCodeEnv.EXTENDS(redeclareModifiers = redecls) :: rest_exts, _, _, _, _, _)
      equation
        (islist, ii) = analyseExtends(elem, mod, redecls, inEnv, inPrefix, inIScopesAcc, inInstStack);
      then
        (islist, rest_exts, ii);

    // We should have one Extends element for each extends clause in the class.
    // If we get an extends clause but don't have any Extends elements left,
    // something has gone very wrong.
    case ((SCode.EXTENDS(baseClassPath = _), _), _, _, _, {}, _, _, _, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"NFSCodeAnalyseRedeclare.analyseElement_dispatch ran out of extends!."});
      then
        fail();

    // Ignore any other kind of elements (class definitions, etc.).
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        (elem, _) = inElement;
        print("Ignoring: " +& SCodeDump.unparseElementStr(elem) +& "\n\t" +&
        "in env: " +& NFSCodeEnv.getEnvName(inEnv) +& "\n\t" +&
        "inst stack: " +& stringDelimitList(List.map(inInstStack, Absyn.pathString), "\n\t") +& "\n\t" +&
        "prefix:" +& Absyn.pathString(NFInstUtil.prefixToPath(inPrefix)) +& "\n");
      then
        (inIScopesAcc, inExtends, inInstStack);
  end matchcontinue;
end analyseElement_dispatch;

protected function analyseElement
  input Element inElement;
  input Modifier inClassMod;
  input Element inOrigElement;
  input Modifier inOriginalMod;
  input Env inEnv;
  input Prefix inPrefix;
  input IScopes inIScopesAcc;
  input InstStack inInstStack;
  input list<tuple<Item, Env>> inPreviousItem;
  output IScopes outIScopes;
  output InstStack outInstStack;
algorithm
  (outIScopes, outInstStack) :=
  matchcontinue(inElement, inClassMod, inOrigElement, inOriginalMod, inEnv, inPrefix, inIScopesAcc, inInstStack, inPreviousItem)
    local
      Absyn.Info info;
      Absyn.Path  tpath;
      Element comp, orig;
      Env env;
      Item item;
      Redeclarations redecls;
      Prefix prefix;
      SCode.Mod smod;
      Modifier mod;
      String name;
      InstStack ii;
      Option<Absyn.ArrayDim> ad;
      IScopes islist;
      IScope is;
      NFSCodeFlattenRedeclare.Replacements replacements;
      list<tuple<Item, Env>> previousItem;
      Infos infos;
      Absyn.Path fullName;
      SCode.Restriction res;

    // A component, look up it's type and instantiate that class.
    case (SCode.COMPONENT(
            name = name,
            typeSpec = Absyn.TPATH(tpath, ad),
            modifications = smod,
            info = info), _, orig, _, _, _, _, _, _)
      equation
        // Look up the class of the component.
        // print("Looking up: " +& Absyn.pathString(tpath) +& " for component: " +& name +& "\n");
        (item, tpath, env) = NFSCodeLookup.lookupClassName(tpath, inEnv, info);
        tpath = NFSCodeEnv.mergePathWithEnvPath(tpath, env);
        false = List.applyAndFold1(inInstStack, boolOr, Absyn.pathEqual, tpath, false);

        // add it
        ii = tpath::inInstStack;

        (item, env, previousItem) = NFSCodeEnv.resolveRedeclaredItem(item, env);

        prefix = NFInstUtil.addPrefix(name, {}, inPrefix);

        // Check that it's legal to instantiate the class.
        NFSCodeCheck.checkInstanceRestriction(item, prefix, info);

        // Merge the class modifications with this element's modifications.
        mod = NFSCodeMod.translateMod(smod, name, 0, inPrefix, inEnv);
        mod = NFSCodeMod.mergeMod(inOriginalMod, mod);
        mod = NFSCodeMod.mergeMod(inClassMod, mod);

        // Apply redeclarations to the class definition and instantiate it.
        redecls = NFSCodeFlattenRedeclare.extractRedeclaresFromModifier(smod);
        (item, env, replacements) = NFSCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redecls, item, env, inEnv, inPrefix);

        (islist, ii) = analyseItem(item, env, mod, prefix, emptyIScopes, ii);

        // remove it
        ii = inInstStack;

        comp = inElement;
        comp = SCode.setComponentTypeSpec(comp, Absyn.TPATH(tpath, ad));
        comp = mergeComponentModifiers(comp, orig);
        infos = mkInfos(List.union(previousItem,inPreviousItem), {RP(replacements), EI(comp, env)});

        fullName = NFSCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv);

        is = mkIScope(CO(prefix,fullName), infos, islist);
        islist = Util.if_(List.isEmpty(islist),inIScopesAcc, is::inIScopesAcc);
      then
        (islist, ii);

    // ignore class extends
    case (SCode.CLASS(
            name = name,
            info = info,
            classDef = SCode.CLASS_EXTENDS(baseClassName = _)
            ), _, _, _, _, _, _, _, _)
      equation
      then
        (inIScopesAcc,inInstStack);

    // ignore operators
    case (SCode.CLASS(
            name = name,
            info = info,
            restriction = res
            ), _, _, _, _, _, _, _, _)
      equation
        true = boolOr(SCode.isOperator(inElement), stringEq(name, "Complex"));
      then
        (inIScopesAcc,inInstStack);

    // only replaceable?? functions, packages, classes
    case (SCode.CLASS(
            name = name,
            info = info,
            prefixes = SCode.PREFIXES(replaceablePrefix = _ /*SCode.REPLACEABLE(_)*/)),
            _, _, _, _, _, _, _, _)
      equation
        fullName = NFSCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv);
        // print("Looking up CLASS: " +& Absyn.pathString(fullName) +& "\n");
        false = List.applyAndFold1(inInstStack, boolOr, Absyn.pathEqual, fullName, false);
        // add it
        ii = fullName::inInstStack;

        (item, env) = NFSCodeLookup.lookupInClass(name, inEnv);
        (item, env, previousItem) = NFSCodeEnv.resolveRedeclaredItem(item, env);

        (islist, ii) = analyseItem(item, env, inClassMod, inPrefix, {}, ii);

        // remove it
        ii = inInstStack;

        infos = mkInfos(List.union(previousItem,inPreviousItem), {EI(inElement, env)});

        // for debugging
        // fullName = Absyn.joinPaths(fullName, Absyn.IDENT("$local"));
        is = mkIScope(CL(fullName), infos, islist);
        islist = is::inIScopesAcc;
      then
        (islist, ii);

   // for debugging
   case (_, _, _, _, _, _, _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("NFSCodeAnalyseRedeclare.instElement ignored element:" +& SCodeDump.unparseElementStr(inElement) +& "\n");
      then
        fail();

    else (inIScopesAcc, inInstStack);

  end matchcontinue;
end analyseElement;

protected function analyseExtends
  input Element inExtends;
  input Modifier inClassMod;
  input Redeclarations inRedeclares;
  input Env inEnv;
  input Prefix inPrefix;
  input IScopes inIScopesAcc;
  input InstStack inInstStack;
  output IScopes outIScopes;
  output InstStack outInstStack;
algorithm
  (outIScopes, outInstStack) :=
  match(inExtends, inClassMod, inRedeclares, inEnv, inPrefix, inIScopesAcc, inInstStack)
    local
      Absyn.Path path;
      SCode.Mod smod;
      Absyn.Info info;
      Item item, itemOld;
      Env env;
      Modifier mod;
      SCode.Visibility visibility;
      Option<SCode.Annotation> ann;
      InstStack ii;
      IScopes islist;
      IScope is;
      Replacements replacements;
      Infos infos;

    case (SCode.EXTENDS(path, visibility, smod, ann, info),
          _, _, _, _, _, _)
      equation
        // Look up the base class in the environment.
        (item, path, env) = NFSCodeLookup.lookupBaseClassName(path, inEnv, info);
        itemOld = item;

        path = NFSCodeEnv.mergePathWithEnvPath(path, env);
        checkRecursiveExtends(path, inEnv, info);

        // Instantiate the class.
        mod = NFSCodeMod.translateMod(smod, "", 0, inPrefix, inEnv);
        mod = NFSCodeMod.mergeMod(inClassMod, mod);

        // Apply the redeclarations.
        (item, env, replacements) = NFSCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(inRedeclares, item, env, inEnv, inPrefix);

        (islist, ii) = analyseItem(item, env, mod, inPrefix, emptyInstStack, inInstStack);

        infos = mkInfos({}, {RP(replacements),EI(inExtends, inEnv)});
        is = mkIScope(EX(path), infos, islist);
        islist = is::inIScopesAcc;
      then
        (islist, ii);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("NFSCodeAnalyseRedeclare.instExtends failed on unknown element.\n");
      then
        fail();

  end match;
end analyseExtends;

public function checkRecursiveExtends
  input Absyn.Path inExtendedClass;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inExtendedClass, inEnv, inInfo)
    local
      Absyn.Path env_path;
      String  path_str;

    case (_, _, _)
      equation
        env_path = NFSCodeEnv.getEnvPath(inEnv);
        false = Absyn.pathPrefixOf(inExtendedClass, env_path);
      then
        ();

    else
      equation
        path_str = Absyn.pathString(inExtendedClass);
        Error.addSourceMessage(Error.RECURSIVE_EXTENDS, {path_str}, inInfo);
      then
        fail();

  end matchcontinue;
end checkRecursiveExtends;

protected function analyseClassExtends
  input Element inClassExtends;
  input Modifier inMod;
  input Env inClassEnv;
  input Env inEnv;
  input Prefix inPrefix;
  input IScopes inIScopesAcc;
  input InstStack inInstStack;
  output IScopes outIScopes;
  output InstStack outInstStack;
algorithm
  (outIScopes, outInstStack) :=
  matchcontinue(inClassExtends, inMod, inClassEnv, inEnv, inPrefix, inIScopesAcc, inInstStack)
    local
      SCode.ClassDef cdef;
      SCode.Mod mod;
      Element scls, ext;
      Absyn.Path bc_path, fullName;
      Absyn.Info info;
      String name;
      Item item;
      Env base_env, ext_env;
      Element base_cls, ext_cls, comp_cls;
      list<Element> classes;
      InstStack ii;
      IScopes islist;
      IScope is;

    case (SCode.CLASS(
            name = name,
            classDef = SCode.CLASS_EXTENDS(modifications = mod,composition = cdef)),
          _, _, _, _, _, _)
      equation
        (bc_path, info) = getClassExtendsBaseClass(inClassEnv);
        ext = SCode.EXTENDS(bc_path, SCode.PUBLIC(), mod, NONE(), info);
        cdef = SCode.addElementToCompositeClassDef(ext, cdef);
        scls = SCode.setElementClassDefinition(cdef, inClassExtends);
        item = NFSCodeEnv.CLASS(scls, inClassEnv, NFSCodeEnv.CLASS_EXTENDS());
        (islist, ii) = analyseItem(item, inEnv, inMod, inPrefix, emptyIScopes, inInstStack);

        fullName = NFSCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv);
        is = mkIScope(CL(fullName), {EI(scls, inEnv)}, islist);
        islist = is::inIScopesAcc;
      then
        (islist, ii);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        name = SCode.elementName(inClassExtends);
        Debug.traceln("NFSCodeAnalyseRedeclare.instClassExtends failed on " +& name);
      then
        fail();

  end matchcontinue;
end analyseClassExtends;

protected function getClassExtendsBaseClass
  input Env inClassEnv;
  output Absyn.Path outPath;
  output Absyn.Info outInfo;
algorithm
  (outPath, outInfo) := matchcontinue(inClassEnv)
    local
      Absyn.Path bc;
      Absyn.Info info;
      String name;

    case (NFSCodeEnv.FRAME(extendsTable = NFSCodeEnv.EXTENDS_TABLE(
            baseClasses = NFSCodeEnv.EXTENDS(baseClass = bc, info = info) :: _)) :: _)
      then (bc, info);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        name = NFSCodeEnv.getEnvName(inClassEnv);
        Debug.traceln("NFSCodeAnalyseRedeclare.getClassExtendsBaseClass failed on " +& name);
      then
        fail();

  end matchcontinue;
end getClassExtendsBaseClass;

protected function mkInfos
  input list<tuple<Item, Env>> inPreviousItems;
  input Infos inInfosAcc;
  output Infos outInfos;
algorithm
  outInfos := match(inPreviousItems, inInfosAcc)
    local
      list<tuple<Item, Env>> rest;
      Item i; Env e;

    case ({}, _) then filterInfos(inInfosAcc, {});

    case ((i, e)::rest, _) then mkInfos(rest, RI(i, e)::inInfosAcc);

  end match;
end mkInfos;

protected function filterInfos
"remove  RP({})"
  input Infos inInfos;
  input Infos inInfosAcc;
  output Infos outInfos;
algorithm
  outInfos := matchcontinue(inInfos, inInfosAcc)
    local
      Infos rest;
      Info i;

    case ({}, _) then inInfosAcc;

    case (RP({})::rest, _)
      then filterInfos(rest, inInfosAcc);

    case (i::rest, _)
      then filterInfos(rest, i::inInfosAcc);

  end matchcontinue;
end filterInfos;

public function cleanRedeclareIScopes
  input IScopes inIScopes;
  input IScopes inIScopesAcc;
  output IScopes outIScopes;
  output Boolean hasChanged;
algorithm
  (outIScopes, hasChanged) := matchcontinue(inIScopes, inIScopesAcc)
    local
      IScope s;
      Kind k;
      Infos i, i1, i2;
      IScopes p, rest, acc,  p2;
      Boolean b, b1, b2;
      Absyn.Path n1, n2;
      Element c, e;
      Env env;
      Absyn.TypeSpec ts;
      SCode.Mod mNew, mOld, m;
      
    
    case ({}, _) then (listReverse(inIScopesAcc), false);

    // extends with no kids has no meaning
    case (IS(kind = EX(_), parts = {})::rest, acc)
      equation
        (acc, b) = cleanRedeclareIScopes(rest, acc);
      then
        (acc, true);

    // component targeting a local replaceable derived class
    // replaceable HeatTransfer = Blah.Blah.IdealHeatTransfer;
    // HeatTransfer heatTransfer(redeclare Medium = Medium)
    case (IS(k as CO(_,n1), i1, {IS(CL(n2), i2, p2)})::rest, acc)
      equation
        // same scope!
        //n1 = Absyn.stripLast(n1);
        //n2 = Absyn.stripLast(n2);
        //true = Absyn.pathEqual(n1, n2);
        EI(e, env) = getEIFromInfos(i1);
        EI(c, _) = getEIFromInfos(i2);
        ts = SCode.getDerivedTypeSpec(c);
        mNew = SCode.getDerivedMod(c);
        mOld = SCode.getComponentMod(e);
        // in this case we merge component modifiers as NEW
        // and type modifiers as OLD
        m = mergeModifiers(mOld, mNew);
        e = SCode.setComponentTypeSpec(e, ts);
        e = SCode.setComponentMod(e, m);
        i1 = listAppend(i1, i2);
        i1 = {EI(e, env)}; //::i1;
        s = IS(k, i1, p2);
        (acc, b) = cleanRedeclareIScopes(rest, s::acc);
      then
        (acc, true);

    // components with no kids, check the redeclares
    case (IS(k as CO(_,_), i, {})::rest, acc)
      equation
        i = replaceCompEIwithRI(i);
        (acc, b) = cleanRedeclareIScopes(rest, IS(k, i, {})::acc);
      then
        (acc, b);

    // class with no kids, check the redeclares
    case (IS(k as CL(_), i, {})::rest, acc)
      equation
        i = replaceClassEIwithRI(i);
        (acc, b) = cleanRedeclareIScopes(rest, IS(k, i, {})::acc);
      then
        (acc, b);

    // the kids got cleaned, try the parent again
    case (IS(k, i, p)::rest, acc)
      equation
        (p, b1) = cleanRedeclareIScopes(p, {});
        s = IS(k, i, p);
        (acc, b2) = cleanRedeclareIScopes(rest, s::acc);
        b = boolOr(b1, b2);
      then
        (acc, b);

  end matchcontinue;
end cleanRedeclareIScopes;

public function fixpointCleanRedeclareIScopes
  input IScopes inIScopes;
  output IScopes outIScopes;
algorithm
  outIScopes := matchcontinue(inIScopes)
    local IScopes i;

    // no more changes
    case (_)
      equation
        (i, false) = cleanRedeclareIScopes(inIScopes, {});
      then
        i;

    // some changes, try again
    case (_)
      equation
        (i, true) = cleanRedeclareIScopes(inIScopes, {});
        i = fixpointCleanRedeclareIScopes(i);
      then
        i;

  end matchcontinue;
end fixpointCleanRedeclareIScopes;

public function replaceCompEIwithRI
  input Infos inInfos;
  output Infos outInfos;
algorithm
  outInfos := matchcontinue(inInfos)
    local
      Infos infos;
      Env env, denv;
      Element e,c,o;
      Absyn.TypeSpec ts;
      SCode.Mod mNew, mOld, m;
    // use the component from the redeclare
    case (_)
      equation
        EI(o, env) = getEIFromInfos(inInfos);
        RI(NFSCodeEnv.REDECLARED_ITEM(NFSCodeEnv.VAR(e, _), denv), env) = getRIFromInfos(inInfos);
        e = mergeComponentModifiers(e, o);
        infos = EI(e, env)::inInfos;
      then
        infos;

    // use the type from the redeclare
    case (_)
      equation
        EI(e, env) = getEIFromInfos(inInfos);
        RI(NFSCodeEnv.REDECLARED_ITEM(NFSCodeEnv.CLASS(c, _, _), denv), _) = getRIFromInfos(inInfos);
        
        ts = SCode.getDerivedTypeSpec(c);
        
        (_, ts, denv) = NFSCodeLookup.lookupTypeSpec(ts, denv, SCode.elementInfo(e));
        ts = NFSCodeEnv.mergeTypeSpecWithEnvPath(ts, denv);
        
        mNew = SCode.getDerivedMod(c);
        mOld = SCode.getComponentMod(e);
        // in this case we merge component modifiers as NEW
        // and type modifiers as OLD
        m = mergeModifiers(mOld, mNew);
        
        e = SCode.setComponentTypeSpec(e, ts);
        e = SCode.setComponentMod(e, m);
        
        infos = EI(e, env)::inInfos;
      then
        infos;

  end matchcontinue;
end replaceCompEIwithRI;

protected function mergeComponentModifiers
  input SCode.Element inNewComp;
  input SCode.Element inOldComp;
  output SCode.Element outComp;
algorithm
  outComp := match(inNewComp, inOldComp)
    local
      SCode.Ident n1,n2;
      SCode.Prefixes p1,p2;
      SCode.Attributes a1,a2;
      Absyn.TypeSpec t1,t2;
      SCode.Mod m1,m2,m;
      Option<SCode.Comment> c1,c2;
      Option<Absyn.Exp> cnd1,cnd2;
      Absyn.Info i1,i2;
      SCode.Element c;

    case (SCode.COMPONENT(n1, p1, a1, t1, m1, c1, cnd1, i1),
          SCode.COMPONENT(n2, p2, a2, t2, m2, c2, cnd2, i2))
      equation
        m = mergeModifiers(m1, m2);
        c = SCode.COMPONENT(n1, p1, a1, t1, m, c1, cnd1, i1);
      then
        c;

  end match;
end mergeComponentModifiers;

protected function mergeModifiers
  input SCode.Mod inNewMod;
  input SCode.Mod inOldMod;
  output SCode.Mod outMod;
algorithm
  outMod := matchcontinue(inNewMod, inOldMod)
    local
      SCode.Final f1, f2;
      SCode.Each e1, e2;
      list<SCode.SubMod> sl1, sl2, sl;
      Option<tuple<Absyn.Exp, Boolean>> b1, b2, b;
      Absyn.Info i1, i2;
      SCode.Mod m;

    case (SCode.NOMOD(), _) then inOldMod;
    case (_, SCode.NOMOD()) then inNewMod;
    case (SCode.REDECL(element = _), _) then inNewMod;

    case (SCode.MOD(f1, e1, sl1, b1, i1),
          SCode.MOD(f2, e2, sl2, b2, i2))
      equation
        b = mergeBindings(b1, b2);
        sl = mergeSubMods(sl1, sl2);
        m = SCode.MOD(f1, e1, sl, b1, i1);
      then
        m;

    else inNewMod;

  end matchcontinue;
end mergeModifiers;

protected function mergeBindings
  input Option<tuple<Absyn.Exp, Boolean>> inNew;
  input Option<tuple<Absyn.Exp, Boolean>> inOld;
  output Option<tuple<Absyn.Exp, Boolean>> outBnd;
algorithm
  outBnd := match(inNew, inOld)
    case (SOME(_), _) then inNew;
    case (NONE(), _) then inOld;
  end match;
end mergeBindings;

protected function mergeSubMods
  input list<SCode.SubMod> inNew;
  input list<SCode.SubMod> inOld;
  output list<SCode.SubMod> outSubs;
algorithm
  outSubs := matchcontinue(inNew, inOld)
    local
      list<SCode.SubMod> sl, rest, old;
      SCode.SubMod s;

    case ({}, _) then inOld;

    case (s::rest, _)
      equation
        old = removeSub(s, inOld);
        sl = mergeSubMods(rest, old);
      then
        s::sl;

     else inNew;
  end matchcontinue;
end mergeSubMods;

protected function removeSub
  input SCode.SubMod inSub;
  input list<SCode.SubMod> inOld;
  output list<SCode.SubMod> outSubs;
algorithm
  outSubs := matchcontinue(inSub, inOld)
    local
      list<SCode.SubMod>  rest;
      SCode.Ident id1, id2;
      list<SCode.Subscript> idxs1, idxs2;
      SCode.SubMod s;

    case (_, {}) then {};

    case (SCode.NAMEMOD(id1, _), SCode.NAMEMOD(id2, _)::rest)
      equation
        true = stringEqual(id1, id2);
      then
        rest;

    case (_, s::rest)
      equation
        rest = removeSub(inSub, rest);
      then
        s::rest;
  end matchcontinue;
end removeSub;

public function replaceClassEIwithRI
  input Infos inInfos;
  output Infos outInfos;
algorithm
  outInfos := matchcontinue(inInfos)
    local
      Infos infos;
      Env env, denv;
      Element e;
      SCode.Prefixes p;
      Absyn.TypeSpec ts;

    // use the class from the redeclare, fully qualify derived
    case (_)
      equation
        EI(e, env) = getEIFromInfos(inInfos);
        RI(NFSCodeEnv.REDECLARED_ITEM(NFSCodeEnv.CLASS(e, _, _), denv), env) = getRIFromInfos(inInfos);
        true = SCode.isDerivedClass(e);
        ts = SCode.getDerivedTypeSpec(e);
        (_, ts, denv) = NFSCodeLookup.lookupTypeSpec(ts, denv, SCode.elementInfo(e));
        ts = NFSCodeEnv.mergeTypeSpecWithEnvPath(ts, denv);
        e = SCode.setDerivedTypeSpec(e, ts);
        p = SCode.elementPrefixes(e);
        p = SCode.prefixesSetRedeclare(p, SCode.NOT_REDECLARE());
        e = SCode.setClassPrefixes(p, e);
        infos = EI(e, env)::inInfos;
      then
        infos;

    // use the class from the redeclare
    case (_)
      equation
        EI(e, env) = getEIFromInfos(inInfos);
        RI(NFSCodeEnv.REDECLARED_ITEM(NFSCodeEnv.CLASS(e, denv, _), _), env) = getRIFromInfos(inInfos);
        p = SCode.elementPrefixes(e);
        p = SCode.prefixesSetRedeclare(p, SCode.NOT_REDECLARE());
        e = SCode.setClassPrefixes(p, e);
        infos = EI(e, env)::inInfos;
      then
        infos;

  end matchcontinue;
end replaceClassEIwithRI;

public function filterRedeclareIScopes
  input IScopes inIScopes;
  input IScopes inIScopesAcc;
  output IScopes outIScopes;
algorithm
  outIScopes := match(inIScopes, inIScopesAcc)
    local
      IScope s;
      Kind k;
      Infos i;
      IScopes p, rest, acc;

    case ({}, _) then listReverse(inIScopesAcc);

    case (IS(k, i, p)::rest, acc)
      equation
        // maybe we should keep all childrens if there is a redeclare on the path?
        p = filterRedeclareIScopes(p, {});
        s = IS(k, i, p);
        acc = Util.if_(hasRedeclares(s), s::acc, acc);
        acc = filterRedeclareIScopes(rest, acc);
      then
        acc;

  end match;
end filterRedeclareIScopes;

public function hasRedeclares
  input IScope inIScope;
  output Boolean hasRedecl;
algorithm
  hasRedecl := matchcontinue(inIScope)
    local
      Boolean b, b1, b2;
      IScopes p;
      Absyn.Path n;
      Infos infos;

    case (IS(kind = RE(_))) then true;
    case (IS(kind = EX(n)))
      equation
        true = intNe(System.stringFind(Absyn.pathLastIdent(n), "$base"), -1);
      then
        true;
    case (IS(parts = p, infos = infos))
      equation
        b1 = hasRedeclareInfos(infos);
        b2 = List.applyAndFold(p, boolOr, hasRedeclares, false);
        b = boolOr(b1, b2);
      then
        b;

    else false;

  end matchcontinue;
end hasRedeclares;

protected function hasRedeclareInfos
"searches for RP(_) or RI(_)"
  input Infos inInfos;
  output Boolean hasRedeclares;
algorithm
  hasRedeclares := matchcontinue(inInfos)
    local
      Infos rest;

    case ({}) then false;

    case (RP(_::_)::rest) then true;
    case (RI(_,_)::rest) then true;

    case (_::rest)
      then hasRedeclareInfos(rest);

  end matchcontinue;
end hasRedeclareInfos;

public function collapseDerivedClassChain
"@author:adrpo
 CL(replaceable X = X)
  CL(redeclare X = X)
   CL(redeclare X = Y)
    CL(Y class with parts)
 is collapsed to:
 CL(X=Y) and element prefixes are merged"
  input IScopes inIScopes;
  input IScopes inIScopesAcc;
  output IScopes outIScopes;
algorithm
  outIScopes := matchcontinue(inIScopes, inIScopesAcc)
    local
      IScope s;
      Kind k;
      Infos i;
      IScopes p, rest, acc;

    case ({}, _) then listReverse(inIScopesAcc);

    case ((s as IS(k, i, p))::rest, acc)
      equation
        true = SCode.isDerivedClass(getElementFromIScope(s));
        s = mergeDerivedClasses(s::p);
        acc = collapseDerivedClassChain(rest, s::acc);
      then
        acc;

    case ((s as IS(k, i, p))::rest, acc)
      equation
        p = collapseDerivedClassChain(p, {});
        acc = collapseDerivedClassChain(rest, IS(k, i, p)::acc);
      then
        acc;

  end matchcontinue;
end collapseDerivedClassChain;

public function mergeDerivedClasses
  input IScopes inIScopes;
  output IScope outIScope;
algorithm
  outIScope := match(inIScopes)
    local
      IScope s, last;
      Element e, eLast;
      IScopes ilist, p, rest;
      Kind k;
      Infos i, ni;
      Env env, envLast;

    case ((s as IS(k, i, p))::rest)
      equation
        EI(e, env) = getEIFromIScope(s);
        true = SCode.isDerivedClass(e);
        // at least one
        (ilist as _::_) = getDerivedIScopes(rest, {});
        // start with original and fold derived prefixes on to it.
        e = List.applyAndFold(ilist, NFSCodeFlattenRedeclare.propagateAttributesClass, getElementFromIScope, e);
        e = List.applyAndFold(ilist, propagateModifiersAndArrayDims, getElementFromIScope, e);
        last = List.last(ilist);
        EI(eLast,envLast) = getEIFromIScope(last);
        // a = a, a = c, c = d, d = e -> a = e
        // TODO FIXME do we need to merge also mods and array dims??!!
        e = SCode.setDerivedTypeSpec(e, SCode.getDerivedTypeSpec(eLast));
        e = removeRedeclareMods(e);
        ni = List.applyAndFold(ilist, listAppend, iScopeInfos, i);
        ni = listReverse(ni);
        ni = EI(e, env)::ni;
        // replace parts with the last one
        p = iScopeParts(last);
        p = collapseDerivedClassChain(p, {});
        s = IS(k, ni, p);
      then
        s;

  end match;
end mergeDerivedClasses;

public function propagateModifiersAndArrayDims
  input SCode.Element inOriginalClass;
  input SCode.Element inNewClass;
  output SCode.Element outNewClass;
protected
  SCode.Ident name;
  SCode.Prefixes pref1, pref2;
  SCode.Encapsulated ep;
  SCode.Partial pp;
  SCode.Restriction res;
  SCode.ClassDef cdef1, cdef2, cdef;
  Absyn.Info info;
algorithm
  SCode.CLASS(classDef=cdef1) := inOriginalClass;
  SCode.CLASS(name, pref2, ep, pp, res, cdef2, info) := inNewClass;
  cdef := mergeCdefs(cdef1, cdef2);
  outNewClass := SCode.CLASS(name, pref2, ep, pp, res, cdef, info);
end propagateModifiersAndArrayDims;

public function mergeCdefs
"@auhtor: adrpo
 merge two derived classdefs first onto second"
  input SCode.ClassDef inOldCd1;
  input SCode.ClassDef inNewCd2;
  output SCode.ClassDef outCd;
algorithm
  outCd := match(inOldCd1, inNewCd2)
    local
      SCode.Attributes atr1, atr2;
      SCode.ClassDef   cd;
      Absyn.TypeSpec ts1, ts2;
      Option<SCode.Comment> cmt1, cmt2;
      SCode.Mod m1, m2;

    case (SCode.DERIVED(ts1, m1, atr1, cmt1), SCode.DERIVED(ts2, m2, atr2, cmt2))
      equation
        m2 = mergeModifiers(m2, m1);
        cd = SCode.DERIVED(ts2, m2, atr2, cmt2);
      then
        cd;

  end match;
end mergeCdefs;

public function removeRedeclareMods
  input Element inElement;
  output Element outElement;
algorithm
  outElement := match(inElement)
    local
      Element e;
      String n;
      SCode.Prefixes p;
      SCode.Encapsulated ep;
      SCode.Partial pp;
      SCode.Restriction rp;
      SCode.ClassDef cd;
      Absyn.Info i;
      SCode.Attributes a;
      Absyn.TypeSpec t;
      SCode.Mod m;
      Option<SCode.Comment> cmt;
      Option<Absyn.Exp> cnd;
      SCode.Visibility v;
      Option<SCode.Annotation> ann;
      Absyn.Path bcp;

    case (SCode.CLASS(n, p, ep, pp, rp, cd, i))
      equation
        //p = SCode.prefixesSetRedeclare(p, SCode.NOT_REDECLARE());
        //p = SCode.prefixesSetReplaceable(p, SCode.NOT_REPLACEABLE());
        cd = removeRedeclareModsFromClassDef(cd);
        e = SCode.CLASS(n, p, ep, pp, rp, cd, i);
      then
        e;

    case (SCode.COMPONENT(n, p, a, t, m, cmt, cnd, i))
      equation
        p = SCode.prefixesSetRedeclare(p, SCode.NOT_REDECLARE());
        //p = SCode.prefixesSetReplaceable(p, SCode.NOT_REPLACEABLE());
        m = NFSCodeMod.removeRedeclaresFromMod(m);
        e = SCode.COMPONENT(n, p, a, t, m, cmt, cnd, i);
      then
        e;

    case (SCode.EXTENDS(bcp, v, m, ann, i))
      equation
        m = NFSCodeMod.removeRedeclaresFromMod(m);
        e = SCode.EXTENDS(bcp, v, m, ann, i);
      then
        e;

  end match;
end removeRedeclareMods;

protected function removeRedeclareModsFromClassDef
  input SCode.ClassDef inClassDef;
  output SCode.ClassDef outClassDef;
algorithm
  outClassDef := match(inClassDef)
    local
      list<Element> el;
      list<SCode.Equation> eq;
      list<SCode.Equation> ieq;
      list<SCode.AlgorithmSection> alg;
      list<SCode.AlgorithmSection> ialg;
      list<SCode.ConstraintSection> cs;
      list<Absyn.NamedArg> clsattr;
      Option<SCode.ExternalDecl> ed;
      list<SCode.Annotation> al;
      Option<SCode.Comment> cmt;
      SCode.ClassDef cd;
      Absyn.TypeSpec t;
      SCode.Mod m;
      SCode.Attributes a;
      String n;

    case (SCode.PARTS(el, eq, ieq, alg, ialg, cs, clsattr, ed, al, cmt))
      equation
        cd = SCode.PARTS(el, eq, ieq, alg, ialg, cs, clsattr, ed, al, cmt);
      then
        cd;

    case (SCode.CLASS_EXTENDS(n, m, cd))
      equation
        m = NFSCodeMod.removeRedeclaresFromMod(m);
        cd = removeRedeclareModsFromClassDef(cd);
        cd = SCode.CLASS_EXTENDS(n, m, cd);
      then
        cd;

    case (SCode.DERIVED(t, m, a, cmt))
      equation
        m = NFSCodeMod.removeRedeclaresFromMod(m);
        cd = SCode.DERIVED(t, m, a, cmt);
      then
        cd;

    case (cd as SCode.ENUMERATION(enumLst = _))
      then
        cd;

    case (cd as SCode.OVERLOAD(pathLst = _))
      then
        cd;

    case (cd as SCode.PDER(functionPath = _))
      then
        cd;
  end match;
end removeRedeclareModsFromClassDef;

public function getDerivedIScopes
  input IScopes inIScopes;
  input IScopes inIScopesAcc;
  output IScopes outIScopes;
algorithm
  outIScopes := matchcontinue(inIScopes, inIScopesAcc)
    local
      IScope s;
      Element e;
      IScopes  acc;

    // this might be an error!
    case ({}, _) then listReverse(inIScopesAcc);

    case ({s}, acc)
      equation
        e = getElementFromIScope(s);
        true = SCode.isDerivedClass(e);
        acc = getDerivedIScopes(iScopeParts(s), s::acc);
      then
        acc;

    case ({s}, _)
      equation
        e = getElementFromIScope(s);
        false = SCode.isDerivedClass(e);
      then
        listReverse(inIScopesAcc);

    else inIScopes;

  end matchcontinue;
end getDerivedIScopes;

public function iScopeInfos
  input IScope inIScope;
  output Infos outInfos;
algorithm
  outInfos := match(inIScope)
    local Infos infos;
    case (IS(infos = infos)) then infos;
  end match;
end iScopeInfos;

public function iScopeParts
  input IScope inIScope;
  output IScopes outIScopes;
algorithm
  outIScopes := match(inIScope)
    local IScopes parts;
    case (IS(parts = parts)) then parts;
  end match;
end iScopeParts;

public function iScopeKind
  input IScope inIScope;
  output Kind outKind;
algorithm
  outKind := match(inIScope)
    local Kind kind;
    case (IS(kind = kind)) then kind;
  end match;
end iScopeKind;

protected function printIScopes
  input IScopes inIScopes;
algorithm
  _ := matchcontinue(inIScopes)
    local
      IScopes rest;
      IScope is;


    case (_)
      equation
        false = Flags.isSet(Flags.SHOW_REDECLARE_ANALYSIS);
      then ();

    case ({})
      equation
        print("\n");
      then ();

    case (is::rest)
      equation
        printIScopeIndent(is, 1);
        printIScopes(rest);
      then
        ();

    else equation
      print("Left: " +& intString(listLength(inIScopes)) +& "\n");
    then ();

  end matchcontinue;
end printIScopes;

public function iScopesStrNoParts
  input IScopes inIScopes;
  output String outStr;
algorithm
  outStr := stringDelimitList(List.map(inIScopes, iScopeStrNoParts), ".");
end iScopesStrNoParts;

protected function iScopeStrNoParts
  input IScope inIScope;
  output String outStr;
algorithm
  outStr := matchcontinue(inIScope)
    local
      Infos i;
      Kind k;
      IScopes p;
      String si, sk, ski, s, str;

    case (IS(k, i, p))
      equation
        {sk, ski} = kindStr(k);
        str = sk +& "(" +& ski +& ")";
      then
        str;

  end matchcontinue;
end iScopeStrNoParts;

public function kindStr
  input Kind inKind;
  output list<String> outStrings;
algorithm
  outStrings := match(inKind)
    local
      Absyn.Path n;
      Prefix p;
      String s;

    case (CL(n))
      equation
        s = Absyn.pathString(n);
      then {"CL",s};

    case (CO(p,n))
      equation
        s = NFInstUtil.prefixToStrNoEmpty(p) +& "/" +& Absyn.pathString(n);
      then {"CO",s};

    case (EX(n))
      equation
        s = Absyn.pathString(n);
      then
        {"EX",s};

    case (RE(n))
      equation
        s = Absyn.pathString(n);
      then {"RE",s};

  end match;
end kindStr;

public function iScopeStr
  input IScope inIScope;
  output String outStr;
algorithm
  outStr := match(inIScope)
    local
      Infos i;
      Kind k;
      IScopes p;
      String si, sk, ski,  str;

    case (IS(k, i, p))
      equation
        si = infosStr(i);
        si = Util.if_(stringEq(si, ""), "", ", " +& si);
        {sk, ski} = kindStr(k);
        str = sk +& "(" +& ski +& si +& ")\n\t";
        str = str +& stringDelimitList(List.map(p, iScopeStr), "\n\t");
      then
        str;

  end match;
end iScopeStr;

protected function iScopeStrIndent
  input IScope inIScope;
  input Integer inIncrement;
  output String outStr;
algorithm
  outStr := matchcontinue(inIScope, inIncrement)
    local
      Infos i;
      Kind k;
      IScopes p;
      String si, sk, ski, indent, str;

    case (IS(k, i, p as {}), _)
      equation
        indent = stringAppendList(List.fill(" ", inIncrement));
        si = infosStr(i);
        si = Util.if_(stringEq(si, ""), "", ", " +& si);
        {sk, ski} = kindStr(k);
        str = indent +& sk +& "(" +& ski +& si +& ")";
      then
        str;

    case (IS(k, i, p), _)
      equation
        indent = stringAppendList(List.fill(" ", inIncrement));
        si = infosStr(i);
        si = Util.if_(stringEq(si, ""), "", ", " +& si);
        {sk, ski} = kindStr(k);
        str = indent +& sk +& "(" +& ski +& si +& ")" +& "\n" +& indent +&
              stringDelimitList(
                List.map1(p, iScopeStrIndent, inIncrement + 1),
                "\n" +& indent);
      then
        str;

  end matchcontinue;
end iScopeStrIndent;

public function infosStr
  input Infos inInfos;
  output String outStr;
algorithm
  outStr := matchcontinue(inInfos)
    local
      Infos rest;
      String str;
      Replacements replacements;
      Env env;
      Element e;
      Item i;

    case ({}) then "";
    case (RP(replacements as _::_)::rest)
      equation
        str = stringDelimitList(List.map(replacements, replacementStr), "/") +& " ";
        str = str +& infosStr(rest);
      then
        str;
    case (EI(e, env)::rest)
      equation
        // str = "EI(" +& NFSCodeEnv.getEnvName(env) +& "/" +& SCodeDump.unparseElementStr(e) +& ") ";
        str = "EI(" +& NFSCodeEnv.getEnvName(env) +& "/" +& SCodeDump.shortElementStr(e) +& ") ";
        str = str +& infosStr(rest);
      then
        str;
    case (RI(i, env)::rest)
      equation
        str = redeclareInfoStr(i, env) +& " ";
        str = str +& infosStr(rest);
      then
        str;
    case (_::rest) then infosStr(rest);

  end matchcontinue;
end infosStr;

public function getElementFromInfos
  input Infos inInfos;
  output Element outElement;
algorithm
  outElement := matchcontinue(inInfos)
    local
      Infos rest;
      Element e;

    case (EI(e, _)::rest) then e;
    case (_::rest) then getElementFromInfos(rest);

  end matchcontinue;
end getElementFromInfos;

public function getElementFromIScope
  input IScope inScope;
  output Element outElement;
algorithm
  outElement := getElementFromInfos(iScopeInfos(inScope));
end getElementFromIScope;

public function getEnvFromIScope
  input IScope inScope;
  output Env outEnv;
algorithm
  outEnv := getEnvFromInfos(iScopeInfos(inScope));
end getEnvFromIScope;

public function getEnvFromInfos
  input Infos inInfos;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inInfos)
    local
      Infos rest;
      Env e;

    case (EI(_, e)::rest) then e;
    case (_::rest) then getEnvFromInfos(rest);

  end matchcontinue;
end getEnvFromInfos;

public function getEIFromIScope
  input IScope inScope;
  output Info outInfo;
algorithm
  outInfo := getEIFromInfos(iScopeInfos(inScope));
end getEIFromIScope;

public function getEIFromInfos
  input Infos inInfos;
  output Info outInfo;
algorithm
  outInfo := matchcontinue(inInfos)
    local
      Infos rest;
      Info i;

    case ((i as EI(env = _))::rest) then i;
    case (_::rest) then getEIFromInfos(rest);

  end matchcontinue;
end getEIFromInfos;

public function getEIsFromInfos
  input Infos inInfos;
  input Infos inInfosAcc;
  output Infos outInfos;
algorithm
  outInfos := matchcontinue(inInfos, inInfosAcc)
    local
      Infos rest, infos;
      Info i;

    case ({}, _) then listReverse(inInfosAcc);

    case ((i as EI(env = _))::rest, _)
      equation
        infos = getEIsFromInfos(rest, i::inInfosAcc);
      then
        infos;

    case (_::rest, _)
      then getEIsFromInfos(rest, inInfosAcc);

  end matchcontinue;
end getEIsFromInfos;

public function getRIsFromInfos
  input Infos inInfos;
  input Infos inInfosAcc;
  output Infos outInfos;
algorithm
  outInfos := matchcontinue(inInfos, inInfosAcc)
    local
      Infos rest, infos;
      Info i;

    case ({}, _) then listReverse(inInfosAcc);

    case ((i as RI(env = _))::rest, _)
      equation
        infos = getRIsFromInfos(rest, i::inInfosAcc);
      then
        infos;

    case (_::rest, _)
      then getRIsFromInfos(rest, inInfosAcc);

  end matchcontinue;
end getRIsFromInfos;

public function getRIFromIScope
  input IScope inScope;
  output Info outInfo;
algorithm
  outInfo := getRIFromInfos(iScopeInfos(inScope));
end getRIFromIScope;

public function getRIFromInfos
  input Infos inInfos;
  output Info outInfo;
algorithm
  outInfo := matchcontinue(inInfos)
    local
      Infos rest;
      Info i;

    case ((i as RI(env = _))::rest) then i;
    case (_::rest) then getRIFromInfos(rest);

  end matchcontinue;
end getRIFromInfos;

public function getOriginalFromInfos
  input Infos inInfos;
  output Info outInfo;
algorithm
  outInfo := matchcontinue(inInfos)
    local
      Infos rest;
      Info i;

    case ((i as RI(item = NFSCodeEnv.VAR(var = _)))::rest) then i;
    case (_::rest) then getRIFromInfos(rest);

  end matchcontinue;
end getOriginalFromInfos;

protected function replacementStr
  input Replacement inReplacement;
  output String outStr;
algorithm
  outStr := match(inReplacement)
    local
      SCode.Ident nm;
      Item o;
      Item n;
      Env e;
      list<Absyn.Path> bc;
      NFSCodeEnv.ExtendsTable eto;
      NFSCodeEnv.ExtendsTable etn;
      String str;

    case (NFSCodeFlattenRedeclare.REPLACED(nm, o, n, e))
      equation
        str = "E(" +& NFSCodeEnv.getEnvName(e) +& ")." +&
              "Old(" +& itemShortStr(o) +& ").E(" +& NFSCodeEnv.getEnvName(NFSCodeEnv.getItemEnvNoFail(o)) +& ")/" +&
              "New(" +& itemShortStr(n) +& ").E(" +& NFSCodeEnv.getEnvName(NFSCodeEnv.getItemEnvNoFail(n)) +& ")";
      then
        str;

    case (NFSCodeFlattenRedeclare.PUSHED(nm, n, bc, eto, etn, e))
      equation
        str = "New(" +& itemShortStr(n) +& ").E(" +& NFSCodeEnv.getEnvName(NFSCodeEnv.getItemEnvNoFail(n)) +& ")." +&
              "BC(" +& stringDelimitList(List.map(bc, Absyn.pathString), "|") +& ").E(" +& NFSCodeEnv.getEnvName(e) +& ")";
      then
        str;

  end match;
end replacementStr;

protected function redeclareInfoStr
  input Item inItem;
  input Env inEnv;
  output String outStr;
algorithm
  outStr := matchcontinue(inItem, inEnv)
    local
      Item i;
      Env de;
      String str;

    case (NFSCodeEnv.REDECLARED_ITEM(i, de), _)
      equation
        str = "RED(" +& itemShortStr(i) +& ").DENV(" +& NFSCodeEnv.getEnvName(de) +& ")." +&
              "LENV(" +& NFSCodeEnv.getEnvName(inEnv) +& ")";
      then
        str;

    case (i, _)
      equation
        str = "PRE(" +& itemShortStr(i) +& ").LENV(" +& NFSCodeEnv.getEnvName(inEnv) +& ")";
      then
        str;

  end matchcontinue;
end redeclareInfoStr;

public function itemShortStr
"Returns more info on an environment item."
  input Item inItem;
  output String outName;
algorithm
  outName := matchcontinue(inItem)
    local
      String name, alias_str;
      SCode.Element el;
      Absyn.Path path;
      Item item;

    case NFSCodeEnv.VAR(var = el)
      then List.first(System.strtok(SCodeDump.unparseElementStr(el), "\n"));
    case NFSCodeEnv.CLASS(cls = el)
      then List.first(System.strtok(SCodeDump.unparseElementStr(el), "\n"));
    case NFSCodeEnv.ALIAS(name = name, path = SOME(path))
      equation
        alias_str = Absyn.pathString(path);
      then
        "alias " +& name +& " -> (" +& alias_str +& "." +& name +& ")";
    case NFSCodeEnv.ALIAS(name = name, path = NONE())
      then "alias " +& name +& " -> ()";
    case NFSCodeEnv.REDECLARED_ITEM(item = item)
      equation
        name = itemShortStr(item);
      then
        "redeclared " +& name;

    else "UNHANDLED ITEM";

  end matchcontinue;
end itemShortStr;

public function mkIScope
  input Kind k;
  input Infos i;
  input IScopes p;
  output IScope iscope;
algorithm
  iscope := IS(k, i, p);
end mkIScope;

public function instScopesDepth
  input IScopes inIScopes;
  output Integer depth;
algorithm
  depth := List.applyAndFold(inIScopes, intMax, iScopeDepth, 0);
end instScopesDepth;

public function iScopeDepth
  input IScope inIScope;
  output Integer depth;
algorithm
  depth := match(inIScope)
    local
      IScopes p;
      Integer n;

    case (IS(parts = {})) then 0;
    case (IS(parts = p))
      equation
        n = 1 + List.applyAndFold(p, intMax, iScopeDepth, 0);
      then
        n;
  end match;
end iScopeDepth;

public function iScopeSize
  input IScopes inIScopes;
  output Integer depth;
algorithm
  depth := match(inIScopes)
    local
      IScopes p, rest;
      Integer n;

    case ({}) then 1;
    case (IS(parts = p)::rest)
      equation
        n = iScopeSize(p) + iScopeSize(rest);
      then
        n;
  end match;
end iScopeSize;

protected function printIScopeIndent
  input IScope inIScope;
  input Integer inIncrement;
algorithm
  _ := matchcontinue(inIScope, inIncrement)
    local
      Infos i;
      Kind k;
      IScopes p;
      String si, sk, ski, indent, str;

    case (IS(k, i, p as {}), _)
      equation
        indent = stringAppendList(List.fill(" ", inIncrement));
        si = infosStr(i);
        si = Util.if_(stringEq(si, ""), "", ", " +& si);
        {sk, ski} = kindStr(k);
        str = indent +& sk +& "(" +& ski +& si +& ")";
        print(str);
      then
        ();

    case (IS(k, i, p), _)
      equation
        indent = stringAppendList(List.fill(" ", inIncrement));
        si = infosStr(i);
        si = Util.if_(stringEq(si, ""), "", ", " +& si);
        {sk, ski} = kindStr(k);
        str = indent +& sk +& "(" +& ski +& si +& ")" +& "\n" +& indent;
        print(str);
        printIScopesIndent(p, inIncrement + 1, "\n" +& indent);
      then
        ();

  end matchcontinue;
end printIScopeIndent;

protected function printIScopesIndent
  input IScopes inIScopes;
  input Integer inIncrement;
  input String delimiter;
algorithm
  _ := matchcontinue(inIScopes, inIncrement, delimiter)
    local
      IScopes p;
      IScope s;

    case ({}, _, _) then ();

    case ({s}, _, _)
      equation
        printIScopeIndent(s, inIncrement);
      then ();

    case (s::p, _, _)
      equation
        printIScopeIndent(s, inIncrement);
        print(delimiter);
        printIScopesIndent(p, inIncrement, delimiter);
      then
        ();

  end matchcontinue;
end printIScopesIndent;

protected function sortParts
  input IScopes inScopes;
  output IScopes outScopes;
protected
  IScopes cl, co, ex;
algorithm
  (cl, co, ex) := splitParts(inScopes, {}, {}, {});
  outScopes := listAppend(cl, listAppend(co, ex));
end sortParts;

protected function splitParts
  input IScopes inScopes;
  input IScopes inScopesAccCL;
  input IScopes inScopesAccCO;
  input IScopes inScopesAccEX;
  output IScopes outScopesCL;
  output IScopes outScopesCO;
  output IScopes outScopesEX;
algorithm
  (outScopesCL, outScopesCO, outScopesEX) := match(inScopes, inScopesAccCL, inScopesAccCO, inScopesAccEX)
    local
      IScopes rest, cl, co, ex;
      IScope i;

    case ({}, _, _, _) then (listReverse(inScopesAccCL), listReverse(inScopesAccCO), listReverse(inScopesAccEX));

    // class put it in CL list
    case ((i as IS(kind = CL(_)))::rest, _, _, _)
      equation
        (cl, co, ex) = splitParts(rest, i::inScopesAccCL, inScopesAccCO, inScopesAccEX);
      then
        (cl, co, ex);

    // component put it co list
    case ((i as IS(kind = CO(_,_)))::rest, _, _, _)
      equation
        (cl, co, ex) = splitParts(rest, inScopesAccCL, i::inScopesAccCO, inScopesAccEX);
      then
        (cl, co, ex);

    // extend sput it in ex list
    case ((i as IS(kind = EX(_)))::rest, _, _, _)
      equation
        (cl, co, ex) = splitParts(rest, inScopesAccCL, inScopesAccCO, i::inScopesAccEX);
      then
        (cl, co, ex);
  end match;
end splitParts;

public function isLocal
  input IScopes inParentIScopes;
  output Boolean isL;
algorithm
  isL := match(inParentIScopes)
    // if parent scope is a class then the declaration is local
    case ({_}) then false;
    case (_::IS(kind = CL(_))::_) then true;
    else false;
  end match;
end isLocal;

public function isReferenced
"true if the scope is referenced from extends or component type"
  input IScopes inParentIScopes;
  output Boolean isRef;
algorithm
  isRef := match(inParentIScopes)
    // if parent scope is a component or extends
    case ({_}) then true;
    case (_::IS(kind = CO(_,_))::_) then true;
    case (_::IS(kind = EX(_))::_) then true;
    else false;
  end match;
end isReferenced;

end NFSCodeAnalyseRedeclare;
