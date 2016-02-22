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

encapsulated package NFSCodeFlattenRedeclare
" file:        NFSCodeFlattenRedeclare.mo
  package:     NFSCodeFlattenRedeclare
  description: SCode flattening


  This module contains redeclare-specific functions used by SCodeFlatten to
  handle redeclares. Redeclares can be either modifiers or elements.

  REDECLARE MODIFIERS:
  Redeclare modifiers are redeclarations given as modifiers on e.g. extends
  clauses. The redeclares are usually extracted from modifiers with the
  extractRedeclaresFromModifier function, like in NFSCodeEnv.extendEnvWithExtends.
  The redeclares are in the form of raw modifiers, which are simply
  SCode.Elements. They are then replaced when needed with the replaceRedeclares
  function, which use the function processRedeclare to turn the into Items ready
  to be inserted in the environment. The replaced items are of the type
  NFSCodeEnv.REDECLARED_ITEM, which contains the new item and the environment it
  was declared in. The function NFSCodeEnv.resolveRedeclaredItem may then be used
  to resolve a redeclared item to get the actual item and it's environment,
  which is important to make sure that e.g. redeclared elements are instantiated
  in the environment where they were declared.

  ELEMENT REDECLARES:
  Element redeclares are similar to redeclare modifiers, but they are declared
  as standalone elements that redeclare an inherited element. When the
  environment is built they are initially added to a list of elements in the
  extends tables by NFSCodeEnv.addElementRedeclarationToEnvExtendsTable. When the
  environment is complete and NFEnvExtends.update is used to update the extends
  these redeclares are handled by addElementRedeclarationsToEnv, which looks up
  which base classes the redeclared elements should be applied to. The element
  redeclares are then added to the list of redeclarations in the correct
  NFSCodeEnv.EXTENDS, and handled in the same way as redeclare modifiers.
"

public import Absyn;
public import SCode;
public import NFSCodeEnv;
public import NFInstPrefix;
public import NFInstTypes;
public import NFSCodeLookup;

public type Env = NFSCodeEnv.Env;
public type Item = NFSCodeEnv.Item;
public type Extends = NFSCodeEnv.Extends;
public type Prefix = NFInstTypes.Prefix;

public uniontype Replacement
  record REPLACED "an item got replaced"
    SCode.Ident name;
    Item old;
    Item new;
    Env env;
  end REPLACED;

  record PUSHED "the redeclares got pushed into the extends of the base classes"
    SCode.Ident name;
    Item redeclaredItem;
    list<Absyn.Path> baseClasses;
    NFSCodeEnv.ExtendsTable old;
    NFSCodeEnv.ExtendsTable new;
    Env env;
  end PUSHED;
end Replacement;

public type Replacements = list<Replacement>;
public constant Replacements emptyReplacements = {};

protected import Debug;
protected import Error;
protected import Flags;
protected import List;
protected import NFSCodeCheck;
protected import Util;
protected import SCodeDump;

public function addElementRedeclarationsToEnv
  input list<SCode.Element> inRedeclares;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := List.fold(inRedeclares, addElementRedeclarationsToEnv2, inEnv);
end addElementRedeclarationsToEnv;

protected function addElementRedeclarationsToEnv2
  input SCode.Element inRedeclare;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inRedeclare, inEnv)
    local
      SCode.Ident  name;
      SourceInfo info;
      Absyn.Path env_path;
      list<Absyn.Path> ext_pathl;
      Env env;
      Item  item;

    case (_, _)
      equation
        name = SCode.elementName(inRedeclare);
        info = SCode.elementInfo(inRedeclare);
        ext_pathl = lookupElementRedeclaration(name, inEnv, info);
        env_path = NFSCodeEnv.getEnvPath(inEnv);
        item = NFSCodeEnv.ALIAS(name, SOME(env_path), info);
        env = addRedeclareToEnvExtendsTable(item, ext_pathl, inEnv, info);
      then
        env;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFSCodeFlattenRedeclare.addElementRedeclarationsToEnv failed for " +
          SCode.elementName(inRedeclare) + " in " +
          NFSCodeEnv.getEnvName(inEnv) + "\n");
      then
        fail();
  end matchcontinue;
end addElementRedeclarationsToEnv2;

protected function lookupElementRedeclaration
  input SCode.Ident inName;
  input Env inEnv;
  input SourceInfo inInfo;
  output list<Absyn.Path> outPaths;
algorithm
  outPaths := matchcontinue(inName, inEnv, inInfo)
    local
      list<Absyn.Path> paths;

    case (_, _, _)
      equation
        paths = NFSCodeLookup.lookupBaseClasses(inName, inEnv);
      then
        paths;

    else
      equation
        Error.addSourceMessage(Error.REDECLARE_NONEXISTING_ELEMENT,
          {inName}, inInfo);
      then
        fail();

  end matchcontinue;
end lookupElementRedeclaration;

protected function addRedeclareToEnvExtendsTable
  input Item inRedeclaredElement;
  input list<Absyn.Path> inBaseClasses;
  input Env inEnv;
  input SourceInfo inInfo;
  output Env outEnv;
protected
  list<Extends> bcl;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
algorithm
  NFSCodeEnv.EXTENDS_TABLE(bcl, re, cei) := NFSCodeEnv.getEnvExtendsTable(inEnv);
  bcl := addRedeclareToEnvExtendsTable2(inRedeclaredElement, inBaseClasses, bcl);
  outEnv := NFSCodeEnv.setEnvExtendsTable(NFSCodeEnv.EXTENDS_TABLE(bcl, re, cei), inEnv);
end addRedeclareToEnvExtendsTable;

protected function addRedeclareToEnvExtendsTable2
  input Item inRedeclaredElement;
  input list<Absyn.Path> inBaseClasses;
  input list<Extends> inExtends;
  output list<Extends> outExtends;
algorithm
  outExtends := matchcontinue(inRedeclaredElement, inBaseClasses, inExtends)
    local
      Extends ex;
      list<Extends> exl;
      Absyn.Path bc1, bc2;
      list<Absyn.Path> rest_bc;
      list<NFSCodeEnv.Redeclaration> el;
      Integer index;
      SourceInfo info;
      NFSCodeEnv.Redeclaration redecl;

    case (_, bc1 :: rest_bc, NFSCodeEnv.EXTENDS(bc2, el, index, info) :: exl)
      equation
        true = Absyn.pathEqual(bc1, bc2);
        redecl = NFSCodeEnv.PROCESSED_MODIFIER(inRedeclaredElement);
        NFSCodeCheck.checkDuplicateRedeclarations(redecl, el);
        ex = NFSCodeEnv.EXTENDS(bc2, redecl :: el, index, info);
        exl = addRedeclareToEnvExtendsTable2(inRedeclaredElement, rest_bc, exl);
      then
        ex :: exl;

    case (_, {}, _) then inExtends;

    case (_, _, ex :: exl)
      equation
        exl = addRedeclareToEnvExtendsTable2(inRedeclaredElement, inBaseClasses, exl);
      then
        ex :: exl;

  end matchcontinue;
end addRedeclareToEnvExtendsTable2;

public function processRedeclare
  "Processes a raw redeclare modifier into a processed form."
  input NFSCodeEnv.Redeclaration inRedeclare;
  input Env inEnv;
  input NFInstTypes.Prefix inPrefix;
  output NFSCodeEnv.Redeclaration outRedeclare;
algorithm
  outRedeclare := matchcontinue(inRedeclare, inEnv, inPrefix)
    local

      Item el_item, redecl_item;
      SCode.Element el;
      Env cls_env;

   case (NFSCodeEnv.RAW_MODIFIER(modifier = el as SCode.CLASS()), _, _)
      equation
        cls_env = NFSCodeEnv.makeClassEnvironment(el, true);
        el_item = NFSCodeEnv.newClassItem(el, cls_env, NFSCodeEnv.USERDEFINED());
        redecl_item = NFSCodeEnv.REDECLARED_ITEM(el_item, inEnv);
      then
        NFSCodeEnv.PROCESSED_MODIFIER(redecl_item);

    case (NFSCodeEnv.RAW_MODIFIER(modifier = el as SCode.COMPONENT()), _, _)
      equation
        el_item = NFSCodeEnv.newVarItem(el, true);
        redecl_item = NFSCodeEnv.REDECLARED_ITEM(el_item, inEnv);
      then
        NFSCodeEnv.PROCESSED_MODIFIER(redecl_item);

    case (NFSCodeEnv.PROCESSED_MODIFIER(), _, _) then inRedeclare;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFSCodeFlattenRedeclare.processRedeclare failed on " +
          SCodeDump.unparseElementStr(NFSCodeEnv.getRedeclarationElement(inRedeclare),SCodeDump.defaultOptions) +
          " in " + Absyn.pathString(NFSCodeEnv.getEnvPath(inEnv)));
      then
        fail();
  end matchcontinue;
end processRedeclare;

public function replaceRedeclares
  "Replaces redeclares in the environment. This function takes a list of
   redeclares, the item and environment of the class in which they should be
   redeclared, and the environment in which the modified element was declared
   (used to qualify the redeclares). The redeclares are then either replaced if
   they can be found in the immediate local environment of the class, or pushed
   into the correct extends clauses if they are inherited."
  input list<NFSCodeEnv.Redeclaration> inRedeclares;
  input Item inClassItem "The item of the class to be modified.";
  input Env inClassEnv "The environment of the class to be modified.";
  input Env inElementEnv "The environment in which the modified element was declared.";
  input NFSCodeLookup.RedeclareReplaceStrategy inReplaceRedeclares;
  output Option<Item> outItem;
  output Option<Env> outEnv;
algorithm
  (outItem, outEnv) := matchcontinue(inRedeclares, inClassItem, inClassEnv,
      inElementEnv, inReplaceRedeclares)
    local
      Item item;
      Env env;

    case (_, _, _, _, NFSCodeLookup.IGNORE_REDECLARES())
      then (SOME(inClassItem), SOME(inClassEnv));

    case (_, _, _, _, NFSCodeLookup.INSERT_REDECLARES())
      equation
        (item, env, _) = replaceRedeclaredElementsInEnv(inRedeclares,
          inClassItem, inClassEnv, inElementEnv, NFInstPrefix.emptyPrefix);
      then
        (SOME(item), SOME(env));

    else (NONE(), NONE());
  end matchcontinue;
end replaceRedeclares;

public function replaceRedeclaredElementsInEnv
  "If a variable or extends clause has modifications that redeclare classes in
   it's instance we need to replace those classes in the environment so that the
   lookup finds the right classes. This function takes a list of redeclares from
   an elements' modifications and applies them to the environment of the
   elements type."
  input list<NFSCodeEnv.Redeclaration> inRedeclares "The redeclares from the modifications.";
  input Item inItem "The type of the element.";
  input Env inTypeEnv "The enclosing scopes of the type.";
  input Env inElementEnv "The environment in which the element was declared.";
  input NFInstTypes.Prefix inPrefix;
  output Item outItem;
  output Env outEnv;
  output Replacements outReplacements "what replacements where performed if any";
algorithm
  (outItem, outEnv, outReplacements) :=
  matchcontinue(inRedeclares, inItem, inTypeEnv, inElementEnv, inPrefix)
    local
      SCode.Element cls;
      Env env;
      NFSCodeEnv.Frame item_env;
      NFSCodeEnv.ClassType cls_ty;
      list<NFSCodeEnv.Redeclaration> redecls;
      Replacements repl;

    // No redeclares!
    case ({}, _, _, _, _) then (inItem, inTypeEnv, {});

    case (_, NFSCodeEnv.CLASS(cls = cls, env = {item_env}, classType = cls_ty), _, _, _)
      equation
        // Merge the types environment with it's enclosing scopes to get the
        // enclosing scopes of the classes we need to replace.
        env = NFSCodeEnv.enterFrame(item_env, inTypeEnv);
        redecls = List.map2(inRedeclares, processRedeclare, inElementEnv, inPrefix);
        ((env, repl)) = List.fold(redecls, replaceRedeclaredElementInEnv, ((env, emptyReplacements)));
        item_env :: env = env;
      then
        (NFSCodeEnv.CLASS(cls, {item_env}, cls_ty), env, repl);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- NFSCodeFlattenRedeclare.replaceRedeclaredElementsInEnv failed for:\n\t");
        Debug.traceln("redeclares: " +
          stringDelimitList(List.map(inRedeclares, NFSCodeEnv.printRedeclarationStr), "\n---------\n") +
          "\n\titem: " + NFSCodeEnv.itemStr(inItem) + "\n\tin scope:" + NFSCodeEnv.getEnvName(inElementEnv));
      then
        fail();
  end matchcontinue;
end replaceRedeclaredElementsInEnv;

public function extractRedeclaresFromModifier
  "Returns a list of redeclare elements given a redeclaration modifier."
  input SCode.Mod inMod;
  output list<NFSCodeEnv.Redeclaration> outRedeclares;
algorithm
  outRedeclares := match(inMod)
    local
      list<SCode.SubMod> sub_mods;
      list<NFSCodeEnv.Redeclaration> redeclares;

    case SCode.MOD(subModLst = sub_mods)
      equation
        redeclares = List.fold(sub_mods, extractRedeclareFromSubMod, {});
      then
        redeclares;

    else {};
  end match;
end extractRedeclaresFromModifier;

protected function extractRedeclareFromSubMod
  "Checks a submodifier and adds the redeclare element to the list of redeclares
  if the modifier is a redeclaration modifier."
  input SCode.SubMod inMod;
  input list<NFSCodeEnv.Redeclaration> inRedeclares;
  output list<NFSCodeEnv.Redeclaration> outRedeclares;
algorithm
  outRedeclares := match(inMod, inRedeclares)
    local
      SCode.Element el;
      NFSCodeEnv.Redeclaration redecl;

    case (SCode.NAMEMOD(mod = SCode.REDECL(element = el)), _)
      equation
        redecl = NFSCodeEnv.RAW_MODIFIER(el);
        NFSCodeCheck.checkDuplicateRedeclarations(redecl, inRedeclares);
      then
        redecl :: inRedeclares;

    // Skip modifiers that are not redeclarations.
    else inRedeclares;
  end match;
end extractRedeclareFromSubMod;

protected function replaceRedeclaredElementInEnv
  "Replaces a redeclaration in the environment."
  input NFSCodeEnv.Redeclaration inRedeclare;
  input tuple<Env, Replacements> inEnv;
  output tuple<Env, Replacements> outEnv;
algorithm
  outEnv := matchcontinue(inRedeclare, inEnv)
    local
      SCode.Ident name, scope_name;
      Item item;
      SourceInfo info;
      list<Absyn.Path> bcl;
      tuple<Env, Replacements> envRpl;

    // Try to redeclare this element in the current scope.
    case (NFSCodeEnv.PROCESSED_MODIFIER(modifier = item), _)
      equation
        name = NFSCodeEnv.getItemName(item);
        // do not asume the story ends here
        // you have to push into extends again
        // even if you find it in the local scope!
        envRpl = pushRedeclareIntoExtendsNoFail(name, item, inEnv);
      then
        replaceElementInScope(name, item, envRpl);

    // If the previous case failed, see if we can find the redeclared element in
    // any of the base classes. If so, push the redeclare into those base
    // classes instead, i.e. add them to the list of redeclares in the
    // appropriate extends in the extends table.
    case (NFSCodeEnv.PROCESSED_MODIFIER(modifier = item), _)
      equation
        name = NFSCodeEnv.getItemName(item);
        bcl = NFSCodeLookup.lookupBaseClasses(name, Util.tuple21(inEnv));
      then
        pushRedeclareIntoExtends(name, item, bcl, inEnv);

    // The redeclared element could not be found, show an error.
    case (NFSCodeEnv.PROCESSED_MODIFIER(modifier = item), _)
      equation
        scope_name = NFSCodeEnv.getScopeName(Util.tuple21(inEnv));
        name = NFSCodeEnv.getItemName(item);
        info = NFSCodeEnv.getItemInfo(item);
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {name, scope_name}, info);
      then
        fail();

  end matchcontinue;
end replaceRedeclaredElementInEnv;

protected function pushRedeclareIntoExtendsNoFail
"Pushes a redeclare into the given extends in the environment if it can.
 if not just returns the same tuple<env, repl>"
  input SCode.Ident inName;
  input Item inRedeclare;
  input tuple<Env, Replacements> inEnv;
  output tuple<Env, Replacements> outEnv;
algorithm
  outEnv := matchcontinue(inName, inRedeclare, inEnv)
    local
      list<Absyn.Path> bcl;
      tuple<Env, Replacements> envRpl;

    case (_, _, _)
      equation
        bcl = NFSCodeLookup.lookupBaseClasses(inName, Util.tuple21(inEnv));
        (envRpl) = pushRedeclareIntoExtends(inName, inRedeclare, bcl, inEnv);
      then
        envRpl;

    else inEnv;
  end matchcontinue;
end pushRedeclareIntoExtendsNoFail;

protected function pushRedeclareIntoExtends
  "Pushes a redeclare into the given extends in the environment."
  input SCode.Ident inName;
  input Item inRedeclare;
  input list<Absyn.Path> inBaseClasses;
  input tuple<Env, Replacements> inEnv;
  output tuple<Env, Replacements> outEnv;
protected
  list<NFSCodeEnv.Extends> exts;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
  NFSCodeEnv.ExtendsTable etNew, etOld;
  String name;
  Env env;
  Replacements repl;
algorithm
  (env, repl) := inEnv;

  NFSCodeEnv.FRAME(extendsTable = etOld as NFSCodeEnv.EXTENDS_TABLE(exts, re, cei)) :: _ := env;
  exts := pushRedeclareIntoExtends2(inName, inRedeclare, inBaseClasses, exts);
  etNew := NFSCodeEnv.EXTENDS_TABLE(exts, re, cei);

  env := NFSCodeEnv.setEnvExtendsTable(etNew, env);
  repl := PUSHED(inName, inRedeclare, inBaseClasses, etOld, etNew, env)::repl;

  outEnv := (env, repl);
  // tracePushRedeclareIntoExtends(inName, inRedeclare, inBaseClasses, env, etOld, etNew);
end pushRedeclareIntoExtends;

protected function pushRedeclareIntoExtends2
  "This function takes a redeclare item and a list of base class paths that the
   redeclare item should be added to. It goes through the given list of
   extends and pushes the redeclare into each one that's in the list of the
   base class paths. It assumes that the list of base class paths and extends
   are sorted in the same order."
  input String inName;
  input Item inRedeclare;
  input list<Absyn.Path> inBaseClasses;
  input list<NFSCodeEnv.Extends> inExtends;
  output list<NFSCodeEnv.Extends> outExtends;
algorithm
  outExtends := match(inName, inRedeclare, inBaseClasses, inExtends)
    local
      Absyn.Path bc1, bc2;
      list<Absyn.Path> rest_bc;
      NFSCodeEnv.Extends ext;
      list<NFSCodeEnv.Extends> rest_exts;
      list<NFSCodeEnv.Redeclaration> redecls;
      Integer index;
      SourceInfo info;
      list<String> bc_strl;
      String bcl_str, err_msg;

    // See if the first base class path matches the first extends. Push the
    // redeclare into that extends if so.
    case (_, _, bc1 :: rest_bc, NFSCodeEnv.EXTENDS(bc2, redecls, index, info) :: rest_exts)
        guard Absyn.pathEqual(bc1, bc2)
      equation
        redecls = pushRedeclareIntoExtends3(inRedeclare, inName, redecls, {});
        rest_exts = pushRedeclareIntoExtends2(inName, inRedeclare, rest_bc, rest_exts);
      then
        NFSCodeEnv.EXTENDS(bc2, redecls, index, info) :: rest_exts;

    // The extends didn't match, continue with the rest of them.
    case (_, _, rest_bc, ext :: rest_exts)
      equation
        rest_exts = pushRedeclareIntoExtends2(inName, inRedeclare, rest_bc, rest_exts);
      then
        ext :: rest_exts;

    // No more base class paths to match means we're done.
    case (_, _, {}, _) then inExtends;

    // No more extends means that we couldn't find all the base classes. This
    // shouldn't happen.
    case (_, _, _, {})
      equation
        bc_strl = list(Absyn.pathString(p) for p in inBaseClasses);
        bcl_str = stringDelimitList(bc_strl, ", ");
        err_msg = "NFSCodeFlattenRedeclare.pushRedeclareIntoExtends2 couldn't find the base classes {"
          + bcl_str + "} for " + inName;
        Error.addMessage(Error.INTERNAL_ERROR, {err_msg});
      then
        fail();

  end match;
end pushRedeclareIntoExtends2;

protected function pushRedeclareIntoExtends3
  "Given the item and name of a redeclare, try to find the redeclare in the
   given list of redeclares. If found, replace the redeclare in the list.
   Otherwise, add a new redeclare to the list."
  input Item inRedeclare;
  input String inName;
  input list<NFSCodeEnv.Redeclaration> inRedeclares;
  input list<NFSCodeEnv.Redeclaration> inOutRedeclares;
  output list<NFSCodeEnv.Redeclaration> outRedeclares;
algorithm
  outRedeclares := match(inRedeclare, inName, inRedeclares)
    local
      Item item;
      NFSCodeEnv.Redeclaration redecl;
      list<NFSCodeEnv.Redeclaration> rest_redecls;
      String name;

    case (_, _, NFSCodeEnv.PROCESSED_MODIFIER(modifier = item) :: rest_redecls)
        guard stringEqual(NFSCodeEnv.getItemName(item), inName)
      then
        List.append_reverse(inOutRedeclares, NFSCodeEnv.PROCESSED_MODIFIER(inRedeclare) :: rest_redecls);

    case (_, _, redecl :: rest_redecls)
      then
        pushRedeclareIntoExtends3(inRedeclare, inName, rest_redecls, redecl :: inOutRedeclares);

    case (_, _, {}) then listReverse(NFSCodeEnv.PROCESSED_MODIFIER(inRedeclare) :: inOutRedeclares);

  end match;
end pushRedeclareIntoExtends3;

public function replaceElementInScope
  "Replaces an element in the current scope."
  input SCode.Ident inElementName;
  input Item inElement;
  input tuple<Env, Replacements> inEnv;
  output tuple<Env, Replacements> outEnv;
algorithm
  outEnv := match(inElementName, inElement, inEnv)
    local
      NFSCodeEnv.AvlTree tree;
      Item old_item, new_item;
      Env env;
      Replacements repl;

    case (_, _, (env as NFSCodeEnv.FRAME(clsAndVars = tree) :: _, repl))
      equation
        old_item = NFSCodeEnv.avlTreeGet(tree, inElementName);
        /*********************************************************************/
        // TODO: Check if this is actually needed
        /*********************************************************************/
        new_item = propagateItemPrefixes(old_item, inElement);
        new_item = NFSCodeEnv.linkItemUsage(old_item, new_item);
        tree = NFSCodeEnv.avlTreeReplace(tree, inElementName, new_item);
        env = NFSCodeEnv.setEnvClsAndVars(tree, env);
        repl = REPLACED(inElementName, old_item, new_item, env)::repl;
        // traceReplaceElementInScope(inElementName, old_item, new_item, env);
      then
        ((env, repl));

  end match;
end replaceElementInScope;

protected function propagateItemPrefixes
  input Item inOriginalItem;
  input Item inNewItem;
  output Item outNewItem;
algorithm
  outNewItem := match(inOriginalItem, inNewItem)
    local
      SCode.Element el1, el2;
      Option<Util.StatefulBoolean> iu1, iu2;
      Env env1, env2;
      NFSCodeEnv.ClassType ty1, ty2;
      Item item;

    case (NFSCodeEnv.VAR(var = el1),
          NFSCodeEnv.VAR(var = el2, isUsed = iu2))
      equation
        el2 = propagateAttributesVar(el1, el2);
      then
        NFSCodeEnv.VAR(el2, iu2);

    case (NFSCodeEnv.CLASS(cls = el1),
          NFSCodeEnv.CLASS(cls = el2, env = env2, classType = ty2))
      equation
        el2 = propagateAttributesClass(el1, el2);
      then
        NFSCodeEnv.CLASS(el2, env2, ty2);

    /*************************************************************************/
    // TODO: Attributes should probably be propagated for alias items too. If
    // the original is an alias, look up the referenced item and use those
    // attributes. If the new item is an alias, look up the referenced item and
    // apply the attributes to it.
    /*************************************************************************/
    case (NFSCodeEnv.ALIAS(), _) then inNewItem;
    case (_, NFSCodeEnv.ALIAS()) then inNewItem;

    case (NFSCodeEnv.REDECLARED_ITEM(item = item), _)
      then propagateItemPrefixes(item, inNewItem);

    case (_, NFSCodeEnv.REDECLARED_ITEM(item = item, declaredEnv = env1))
      equation
        item = propagateItemPrefixes(inOriginalItem, item);
      then
      NFSCodeEnv.REDECLARED_ITEM(item, env1);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"NFSCodeFlattenRedeclare.propagateAttributes failed on unknown item."});
      then
        fail();
  end match;
end propagateItemPrefixes;

public function propagateAttributesVar
  input SCode.Element inOriginalVar;
  input SCode.Element inNewVar;
  output SCode.Element outNewVar;
protected
  SCode.Ident name;
  SCode.Prefixes pref1, pref2;
  SCode.Attributes attr1, attr2;
  Absyn.TypeSpec ty;
  SCode.Mod mod;
  SCode.Comment cmt;
  Option<Absyn.Exp> cond;
  SourceInfo info;
algorithm
  SCode.COMPONENT(prefixes = pref1, attributes = attr1) := inOriginalVar;
  SCode.COMPONENT(name, pref2, attr2, ty, mod, cmt, cond, info) := inNewVar;
  pref2 := propagatePrefixes(pref1, pref2);
  attr2 := propagateAttributes(attr1, attr2);
  outNewVar := SCode.COMPONENT(name, pref2, attr2, ty, mod, cmt, cond, info);
end propagateAttributesVar;

public function propagateAttributesClass
  input SCode.Element inOriginalClass;
  input SCode.Element inNewClass;
  output SCode.Element outNewClass;
protected
  SCode.Ident name;
  SCode.Prefixes pref1, pref2;
  SCode.Encapsulated ep;
  SCode.Partial pp;
  SCode.Restriction res;
  SCode.ClassDef cdef;
  SourceInfo info;
  SCode.Comment cmt;
algorithm
  SCode.CLASS(prefixes = pref1) := inOriginalClass;
  SCode.CLASS(name, pref2, ep, pp, res, cdef, cmt, info) := inNewClass;
  pref2 := propagatePrefixes(pref1, pref2);
  outNewClass := SCode.CLASS(name, pref2, ep, pp, res, cdef, cmt, info);
end propagateAttributesClass;

protected function propagatePrefixes
  input SCode.Prefixes inOriginalPrefixes;
  input SCode.Prefixes inNewPrefixes;
  output SCode.Prefixes outNewPrefixes;
protected
  SCode.Visibility vis1, vis2;
  Absyn.InnerOuter io1, io2;
  SCode.Redeclare rdp;
  SCode.Final fp;
  SCode.Replaceable rpp;
algorithm
  SCode.PREFIXES(visibility = vis1, innerOuter = io1) := inOriginalPrefixes;
  SCode.PREFIXES(vis2, rdp, fp, io2, rpp) := inNewPrefixes;
  io2 := propagatePrefixInnerOuter(io1, io2);
  outNewPrefixes := SCode.PREFIXES(vis2, rdp, fp, io2, rpp);
end propagatePrefixes;

protected function propagatePrefixInnerOuter
  input Absyn.InnerOuter inOriginalIO;
  input Absyn.InnerOuter inIO;
  output Absyn.InnerOuter outIO;
algorithm
  outIO := match(inOriginalIO, inIO)
    case (_, Absyn.NOT_INNER_OUTER()) then inOriginalIO;
    else inIO;
  end match;
end propagatePrefixInnerOuter;

protected function propagateAttributes
  input SCode.Attributes inOriginalAttributes;
  input SCode.Attributes inNewAttributes;
  output SCode.Attributes outNewAttributes;
protected
  Absyn.ArrayDim dims1, dims2;
  SCode.ConnectorType ct1, ct2;
  SCode.Parallelism prl1,prl2;
  SCode.Variability var1, var2;
  Absyn.Direction dir1, dir2;
  Absyn.IsField isf1, isf2;
algorithm
  SCode.ATTR(dims1, ct1, prl1, var1, dir1, isf1) := inOriginalAttributes;
  SCode.ATTR(dims2, ct2, prl2, var2, dir2, isf2) := inNewAttributes;
  dims2 := propagateArrayDimensions(dims1, dims2);
  ct2 := propagateConnectorType(ct1, ct2);
  prl2 := propagateParallelism(prl1,prl2);
  var2 := propagateVariability(var1, var2);
  dir2 := propagateDirection(dir1, dir2);
  isf2 := propagateIsField(isf1, isf2);
  outNewAttributes := SCode.ATTR(dims2, ct2, prl2, var2, dir2, isf2);
end propagateAttributes;

protected function propagateArrayDimensions
  input Absyn.ArrayDim inOriginalDims;
  input Absyn.ArrayDim inNewDims;
  output Absyn.ArrayDim outNewDims;
algorithm
  outNewDims := match(inOriginalDims, inNewDims)
    case (_, {}) then inOriginalDims;
    else inNewDims;
  end match;
end propagateArrayDimensions;

protected function propagateConnectorType
  input SCode.ConnectorType inOriginalConnectorType;
  input SCode.ConnectorType inNewConnectorType;
  output SCode.ConnectorType outNewConnectorType;
algorithm
  outNewConnectorType := match(inOriginalConnectorType, inNewConnectorType)
    case (_, SCode.POTENTIAL()) then inOriginalConnectorType;
    else inNewConnectorType;
  end match;
end propagateConnectorType;

protected function propagateParallelism
  input SCode.Parallelism inOriginalParallelism;
  input SCode.Parallelism inNewParallelism;
  output SCode.Parallelism outNewParallelism;
algorithm
  outNewParallelism := match(inOriginalParallelism, inNewParallelism)
    case (_, SCode.NON_PARALLEL()) then inOriginalParallelism;
    else inNewParallelism;
  end match;
end propagateParallelism;

protected function propagateVariability
  input SCode.Variability inOriginalVariability;
  input SCode.Variability inNewVariability;
  output SCode.Variability outNewVariability;
algorithm
  outNewVariability := match(inOriginalVariability, inNewVariability)
    case (_, SCode.VAR()) then inOriginalVariability;
    else inNewVariability;
  end match;
end propagateVariability;

protected function propagateDirection
  input Absyn.Direction inOriginalDirection;
  input Absyn.Direction inNewDirection;
  output Absyn.Direction outNewDirection;
algorithm
  outNewDirection := match(inOriginalDirection, inNewDirection)
    case (_, Absyn.BIDIR()) then inOriginalDirection;
    else inNewDirection;
  end match;
end propagateDirection;

protected function propagateIsField
  input Absyn.IsField inOriginalIsField;
  input Absyn.IsField inNewIsField;
  output Absyn.IsField outNewIsField;
algorithm
  outNewIsField := match(inOriginalIsField, inNewIsField)
    case (_, Absyn.NONFIELD()) then inOriginalIsField;
    else inNewIsField;
  end match;
end propagateIsField;

protected function traceReplaceElementInScope
"@author: adrpo
 good for debugging redeclares.
 uncomment it in replaceElementInScope to activate it"
  input SCode.Ident inElementName;
  input Item inOldItem;
  input Item inNewItem;
  input Env inEnv;
algorithm
  _ := matchcontinue(inElementName, inOldItem, inNewItem, inEnv)
    case (_, _, _, _)
      equation
        print("replacing element: " + inElementName + " env: " + NFSCodeEnv.getEnvName(inEnv) + "\n\t");
        print("Old Element:" + NFSCodeEnv.itemStr(inOldItem) +
              " env: " + NFSCodeEnv.getEnvName(NFSCodeEnv.getItemEnvNoFail(inOldItem)) + "\n\t");
        print("New Element:" + NFSCodeEnv.itemStr(inNewItem) +
              " env: " + NFSCodeEnv.getEnvName(NFSCodeEnv.getItemEnvNoFail(inNewItem)) +
              "\n===============\n");
      then ();

    else
      equation
        print("traceReplaceElementInScope failed on element: " + inElementName + "\n");
      then ();
  end matchcontinue;
end traceReplaceElementInScope;

protected function tracePushRedeclareIntoExtends
"@author: adrpo
 good for debugging redeclares.
 uncomment it in pushRedeclareIntoExtends to activate it"
  input SCode.Ident inName;
  input NFSCodeEnv.Item inRedeclare;
  input list<Absyn.Path> inBaseClasses;
  input Env inEnv;
  input NFSCodeEnv.ExtendsTable inEtNew;
  input NFSCodeEnv.ExtendsTable inEtOld;
algorithm
  _ := matchcontinue(inName, inRedeclare, inBaseClasses, inEnv, inEtNew, inEtOld)
    case (_, _, _, _, _, _)
      equation
        print("pushing: " + inName + " redeclare: " + NFSCodeEnv.itemStr(inRedeclare) + "\n\t");
        print("into baseclases: " + stringDelimitList(list(Absyn.pathString(p) for p in inBaseClasses), ", ") + "\n\t");
        print("called from env: " + NFSCodeEnv.getEnvName(inEnv) + "\n");
        print("-----------------\n");
      then ();

    else
      equation
        print("tracePushRedeclareIntoExtends failed on element: " + inName + "\n");
      then ();

  end matchcontinue;
end tracePushRedeclareIntoExtends;

annotation(__OpenModelica_Interface="frontend");
end NFSCodeFlattenRedeclare;
