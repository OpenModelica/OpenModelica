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

encapsulated package FFlattenRedeclare
" file:  FFlattenRedeclare.mo
  package:     FFlattenRedeclare
  description: SCode flattening

  RCS: $Id: FFlattenRedeclare.mo 14085 2012-11-27 12:12:40Z adrpo $

  This module contains redeclare-specific functions used by SCodeFlatten to
  handle redeclares. Redeclares can be either modifiers or elements.

  REDECLARE MODIFIERS:
  Redeclare modifiers are redeclarations given as modifiers on e.g. extends
  clauses. The redeclares are usually extracted from modifiers with the
  extractRedeclaresFromModifier function, like in FEnv.extendEnvWithExtends.
  The redeclares are in the form of raw modifiers, which are simply
  SCode.Elements. They are then replaced when needed with the replaceRedeclares
  function, which use the function processRedeclare to turn the into Items ready
  to be inserted in the environment. The replaced items are of the type
  Env.REDECLARED_ITEM, which contains the new item and the environment it
  was declared in. The function FEnv.resolveRedeclaredItem may then be used
  to resolve a redeclared item to get the actual item and it's environment,
  which is important to make sure that e.g. redeclared elements are instantiated
  in the environment where they were declared.

  ELEMENT REDECLARES:
  Element redeclares are similar to redeclare modifiers, but they are declared
  as standalone elements that redeclare an inherited element. When the
  environment is built they are initially added to a list of elements in the
  extends tables by FEnv.addElementRedeclarationToEnvExtendsTable. When the
  environment is complete and NFEnvExtends.update is used to update the extends
  these redeclares are handled by addElementRedeclarationsToEnv, which looks up
  which base classes the redeclared elements should be applied to. The element
  redeclares are then added to the list of redeclarations in the correct
  Env.EXTENDS, and handled in the same way as redeclare modifiers.
"

public import Absyn;
public import SCode;
public import DAE;
public import Env;
public import NFInstTypes;
public import FLookup;

public type Env = Env.Env;
public type Item = Env.Item;
public type Extends = Env.Extends;
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
    Env.ExtendsTable old;
    Env.ExtendsTable new;
    Env env;
  end PUSHED;
end Replacement;

public type Replacements = list<Replacement>;
public constant Replacements emptyReplacements = {};

protected import Debug;
protected import Error;
protected import Flags;
protected import List;
protected import FSCodeCheck;
protected import Util;
protected import SCodeDump;
protected import FEnv;

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
      SCode.Ident cls_name, name;
      Absyn.Info info;
      Absyn.Path env_path;
      list<Absyn.Path> ext_pathl;
      Env env;
      Item base_item, item;
      SCode.Element redecl;

    case (_, _)
      equation
  name = SCode.elementName(inRedeclare);
  info = SCode.elementInfo(inRedeclare);
  ext_pathl = lookupElementRedeclaration(name, inEnv, info);
  env_path = FEnv.getEnvPath(inEnv);
  item = Env.ALIAS(name, SOME(env_path), info);
  env = addRedeclareToEnvExtendsTable(item, ext_pathl, inEnv, info);
      then
  env;

    else
      equation
  true = Flags.isSet(Flags.FAILTRACE);
  Debug.traceln("- FFlattenRedeclare.addElementRedeclarationsToEnv failed for " +&
    SCode.elementName(inRedeclare) +& " in " +&
    FEnv.getEnvName(inEnv) +& "\n");
      then
  fail();
  end matchcontinue;
end addElementRedeclarationsToEnv2;

protected function lookupElementRedeclaration
  input SCode.Ident inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output list<Absyn.Path> outPaths;
algorithm
  outPaths := matchcontinue(inName, inEnv, inInfo)
    local
      list<Absyn.Path> paths;

    case (_, _, _)
      equation
  paths = FLookup.lookupBaseClasses(inName, inEnv);
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
  input Absyn.Info inInfo;
  output Env outEnv;
protected
  list<Extends> bcl;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
algorithm
  Env.EXTENDS_TABLE(bcl, re, cei) := FEnv.getEnvExtendsTable(inEnv);
  bcl := addRedeclareToEnvExtendsTable2(inRedeclaredElement, inBaseClasses, bcl);
  outEnv := FEnv.setEnvExtendsTable(Env.EXTENDS_TABLE(bcl, re, cei), inEnv);
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
      list<Env.Redeclaration> el;
      Integer index;
      Absyn.Info info;
      Env.Redeclaration redecl;

    case (_, bc1 :: rest_bc, Env.EXTENDS(bc2, el, index, info) :: exl)
      equation
  true = Absyn.pathEqual(bc1, bc2);
  redecl = Env.PROCESSED_MODIFIER(inRedeclaredElement);
  FSCodeCheck.checkDuplicateRedeclarations(redecl, el);
  ex = Env.EXTENDS(bc2, redecl :: el, index, info);
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
  input Env.Redeclaration inRedeclare;
  input Env inEnv;
  input NFInstTypes.Prefix inPrefix;
  output Env.Redeclaration outRedeclare;
algorithm
  outRedeclare := matchcontinue(inRedeclare, inEnv, inPrefix)
    local
      SCode.Ident name;
      SCode.Partial pp;
      SCode.Encapsulated ep;
      SCode.Prefixes prefixes;
      Absyn.Path path;
      SCode.Mod mod;
      Option<SCode.Comment> cmt;
      SCode.Restriction res;
      Absyn.Info info;
      SCode.Attributes attr;
      Option<Absyn.Exp> cond;
      Option<Absyn.ArrayDim> ad;

      Item el_item, redecl_item;
      SCode.Element el;
      Env cls_env, env;

   case (Env.RAW_MODIFIER(modifier = el as SCode.CLASS(name = _)), _, _)
      equation
  cls_env = FEnv.makeClassEnvironment(el, true);
  el_item = FEnv.newClassItem(el, cls_env, Env.USERDEFINED());
  redecl_item = Env.REDECLARED_ITEM(el_item, inEnv);
      then
  Env.PROCESSED_MODIFIER(redecl_item);

    case (Env.RAW_MODIFIER(modifier = el as SCode.COMPONENT(name = _)), _, _)
      equation
  el_item = FEnv.newVarItem(el, true);
  redecl_item = Env.REDECLARED_ITEM(el_item, inEnv);
      then
  Env.PROCESSED_MODIFIER(redecl_item);

    case (Env.PROCESSED_MODIFIER(modifier = _), _, _) then inRedeclare;

    else
      equation
  true = Flags.isSet(Flags.FAILTRACE);
  Debug.traceln("- FFlattenRedeclare.processRedeclare failed on " +&
    SCodeDump.printElementStr(FEnv.getRedeclarationElement(inRedeclare)) +&
    " in " +& Absyn.pathString(FEnv.getEnvPath(inEnv)));
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
  input list<Env.Redeclaration> inRedeclares;
  input Item inClassItem "The item of the class to be modified.";
  input Env inClassEnv "The environment of the class to be modified.";
  input Env inElementEnv "The environment in which the modified element was declared.";
  input FLookup.RedeclareReplaceStrategy inReplaceRedeclares;
  output Option<Item> outItem;
  output Option<Env> outEnv;
algorithm
  (outItem, outEnv) := matchcontinue(inRedeclares, inClassItem, inClassEnv,
      inElementEnv, inReplaceRedeclares)
    local
      Item item;
      Env env;

    case (_, _, _, _, FLookup.IGNORE_REDECLARES())
      then (SOME(inClassItem), SOME(inClassEnv));

    case (_, _, _, _, FLookup.INSERT_REDECLARES())
      equation
  (item, env, _) = replaceRedeclaredElementsInEnv(inRedeclares,
    inClassItem, inClassEnv, inElementEnv, NFInstTypes.emptyPrefix);
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
  input list<Env.Redeclaration> inRedeclares "The redeclares from the modifications.";
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
      FEnv.Frame item_env;
      Env.ClassType cls_ty;
      list<Env.Redeclaration> redecls;
      Replacements repl;
      Item item;

    // No redeclares!
    case ({}, _, _, _, _) then (inItem, inTypeEnv, {});

    case (_, Env.CLASS(cls = cls, env = {item_env}, classType = cls_ty), _, _, _)
      equation
  // Merge the types environment with it's enclosing scopes to get the
  // enclosing scopes of the classes we need to replace.
  env = FEnv.enterFrame(item_env, inTypeEnv);
  redecls = List.map2(inRedeclares, processRedeclare, inElementEnv, inPrefix);
  ((env, repl)) = List.fold(redecls, replaceRedeclaredElementInEnv, ((env, emptyReplacements)));
  item_env :: env = env;
      then
  (Env.CLASS(cls, {item_env}, cls_ty), env, repl);

    else
      equation
  true = Flags.isSet(Flags.FAILTRACE);
  Debug.trace("- FFlattenRedeclare.replaceRedeclaredElementsInEnv failed for:\n\t");
  Debug.traceln("redeclares: " +&
    stringDelimitList(List.map(inRedeclares, FEnv.printRedeclarationStr), "\n---------\n") +&
    "\n\titem: " +& FEnv.itemStr(inItem) +& "\n\tin scope:" +& FEnv.getEnvName(inElementEnv));
      then
  fail();
  end matchcontinue;
end replaceRedeclaredElementsInEnv;

public function extractRedeclaresFromModifier
  "Returns a list of redeclare elements given a redeclaration modifier."
  input SCode.Mod inMod;
  output list<Env.Redeclaration> outRedeclares;
algorithm
  outRedeclares := match(inMod)
    local
      list<SCode.SubMod> sub_mods;
      list<Env.Redeclaration> redeclares;

    case SCode.MOD(subModLst = sub_mods)
      equation
  redeclares = List.fold(sub_mods, extractRedeclareFromSubMod, {});
      then
  redeclares;

    else then {};
  end match;
end extractRedeclaresFromModifier;

protected function extractRedeclareFromSubMod
  "Checks a submodifier and adds the redeclare element to the list of redeclares
  if the modifier is a redeclaration modifier."
  input SCode.SubMod inMod;
  input list<Env.Redeclaration> inRedeclares;
  output list<Env.Redeclaration> outRedeclares;
algorithm
  outRedeclares := match(inMod, inRedeclares)
    local
      SCode.Element el;
      Env.Redeclaration redecl;

    case (SCode.NAMEMOD(A = SCode.REDECL(element = el)), _)
      equation
  redecl = Env.RAW_MODIFIER(el);
  FSCodeCheck.checkDuplicateRedeclarations(redecl, inRedeclares);
      then
  redecl :: inRedeclares;

    // Skip modifiers that are not redeclarations.
    else inRedeclares;
  end match;
end extractRedeclareFromSubMod;

protected function replaceRedeclaredElementInEnv
  "Replaces a redeclaration in the environment."
  input Env.Redeclaration inRedeclare;
  input tuple<Env, Replacements> inEnv;
  output tuple<Env, Replacements> outEnv;
algorithm
  outEnv := matchcontinue(inRedeclare, inEnv)
    local
      SCode.Ident name, scope_name;
      Item item;
      Absyn.Info info;
      list<Absyn.Path> bcl;
      list<String> bcl_str;
      Env env;
      tuple<Env, Replacements> envRpl;

    // Try to redeclare this element in the current scope.
    case (Env.PROCESSED_MODIFIER(modifier = item), _)
      equation
  name = FEnv.getItemName(item);
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
    case (Env.PROCESSED_MODIFIER(modifier = item), _)
      equation
  name = FEnv.getItemName(item);
  bcl = FLookup.lookupBaseClasses(name, Util.tuple21(inEnv));
      then
  pushRedeclareIntoExtends(name, item, bcl, inEnv);

    // The redeclared element could not be found, show an error.
    case (Env.PROCESSED_MODIFIER(modifier = item), _)
      equation
  scope_name = FEnv.getScopeName(Util.tuple21(inEnv));
  name = FEnv.getItemName(item);
  info = FEnv.getItemInfo(item);
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
      SCode.Ident name, scope_name;
      Item item;
      Absyn.Info info;
      list<Absyn.Path> bcl;
      list<String> bcl_str;
      Env env;
      tuple<Env, Replacements> envRpl;

    case (_, _, _)
      equation
  bcl = FLookup.lookupBaseClasses(inName, Util.tuple21(inEnv));
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
  list<Env.Extends> exts;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
  Env.ExtendsTable etNew, etOld;
  String name;
  Env env;
  Replacements repl;
algorithm
  (env, repl) := inEnv;

  Env.FRAME(extendsTable = etOld as Env.EXTENDS_TABLE(exts, re, cei)) :: _ := env;
  exts := pushRedeclareIntoExtends2(inName, inRedeclare, inBaseClasses, exts);
  etNew := Env.EXTENDS_TABLE(exts, re, cei);

  env := FEnv.setEnvExtendsTable(etNew, env);
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
  input list<Env.Extends> inExtends;
  output list<Env.Extends> outExtends;
algorithm
  outExtends := matchcontinue(inName, inRedeclare, inBaseClasses, inExtends)
    local
      Absyn.Path bc1, bc2;
      list<Absyn.Path> rest_bc;
      Env.Extends ext;
      list<Env.Extends> rest_exts;
      list<Env.Redeclaration> redecls;
      Integer index;
      Absyn.Info info;
      list<String> bc_strl;
      String bcl_str, err_msg;

    // See if the first base class path matches the first extends. Push the
    // redeclare into that extends if so.
    case (_, _, bc1 :: rest_bc, Env.EXTENDS(bc2, redecls, index, info) :: rest_exts)
      equation
  true = Absyn.pathEqual(bc1, bc2);
  redecls = pushRedeclareIntoExtends3(inRedeclare, inName, redecls);
  rest_exts = pushRedeclareIntoExtends2(inName, inRedeclare, rest_bc, rest_exts);
      then
  Env.EXTENDS(bc2, redecls, index, info) :: rest_exts;

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
  bc_strl = List.map(inBaseClasses, Absyn.pathString);
  bcl_str = stringDelimitList(bc_strl, ", ");
  err_msg = "FFlattenRedeclare.pushRedeclareIntoExtends2 couldn't find the base classes {"
    +& bcl_str +& "} for " +& inName;
  Error.addMessage(Error.INTERNAL_ERROR, {err_msg});
      then
  fail();

  end matchcontinue;
end pushRedeclareIntoExtends2;

protected function pushRedeclareIntoExtends3
  "Given the item and name of a redeclare, try to find the redeclare in the
   given list of redeclares. If found, replace the redeclare in the list.
   Otherwise, add a new redeclare to the list."
  input Item inRedeclare;
  input String inName;
  input list<Env.Redeclaration> inRedeclares;
  output list<Env.Redeclaration> outRedeclares;
algorithm
  outRedeclares := matchcontinue(inRedeclare, inName, inRedeclares)
    local
      Item item;
      Env.Redeclaration redecl;
      list<Env.Redeclaration> rest_redecls;
      String name;

    case (_, _, Env.PROCESSED_MODIFIER(modifier = item) :: rest_redecls)
      equation
  name = FEnv.getItemName(item);
  true = stringEqual(name, inName);
      then
  Env.PROCESSED_MODIFIER(inRedeclare) :: rest_redecls;

    case (_, _, redecl :: rest_redecls)
      equation
  rest_redecls = pushRedeclareIntoExtends3(inRedeclare, inName, rest_redecls);
      then
  redecl :: rest_redecls;

    case (_, _, {}) then {Env.PROCESSED_MODIFIER(inRedeclare)};

  end matchcontinue;
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
      Env.AvlTree tree;
      Item old_item, new_item;
      Env env;
      Replacements repl;

    case (_, _, (env as Env.FRAME(clsAndVars = tree) :: _, repl))
      equation
  old_item = Env.avlTreeGet(tree, inElementName);
  /*********************************************************************/
  // TODO: Check if this is actually needed
  /*********************************************************************/
  new_item = propagateItemPrefixes(old_item, inElement);
  new_item = FEnv.linkItemUsage(old_item, new_item);
  tree = Env.avlTreeReplace(tree, inElementName, new_item);
  env = FEnv.setEnvClsAndVars(tree, env);
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
      DAE.Var daeVar1, daeVar2;
      Env.InstStatus is1, is2;
      SCode.Element el1, el2;
      DAE.Mod m1, m2;
      Option<Util.StatefulBoolean> iu1, iu2;
      Env env1, env2, cenv1, cenv2;
      Env.ClassType ty1, ty2;
      Item item;

    case (Env.VAR(daeVar1, el1, m1, is1, cenv1, iu1),
    Env.VAR(daeVar2, el2, m2, is2, cenv2, iu2))
      equation
  el2 = propagateAttributesVar(el1, el2);
      then
  Env.VAR(daeVar2, el2, m2, is2, cenv2, iu2);

    case (Env.CLASS(cls = el1, env = env1, classType = ty1),
    Env.CLASS(cls = el2, env = env2, classType = ty2))
      equation
  el2 = propagateAttributesClass(el1, el2);
      then
  Env.CLASS(el2, env2, ty2);

    /*************************************************************************/
    // TODO: Attributes should probably be propagated for alias items too. If
    // the original is an alias, look up the referenced item and use those
    // attributes. If the new item is an alias, look up the referenced item and
    // apply the attributes to it.
    /*************************************************************************/
    case (Env.ALIAS(path = _), _) then inNewItem;
    case (_, Env.ALIAS(path = _)) then inNewItem;

    case (Env.REDECLARED_ITEM(item = item), _)
      then propagateItemPrefixes(item, inNewItem);

    case (_, Env.REDECLARED_ITEM(item = item, declaredEnv = env1))
      equation
  item = propagateItemPrefixes(inOriginalItem, item);
      then
      Env.REDECLARED_ITEM(item, env1);

    else
      equation
  Error.addMessage(Error.INTERNAL_ERROR,
    {"FFlattenRedeclare.propagateAttributes failed on unknown item."});
      then
  fail();
  end match;
end propagateItemPrefixes;

protected function propagateAttributesVar
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
  Absyn.Info info;
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
  SCode.Comment cmt;
  Absyn.Info info;
algorithm
  SCode.CLASS(prefixes = pref1) := inOriginalClass;
  SCode.CLASS(name, pref2, ep, pp, res, cdef, cmt, info) := inNewClass;
  pref2 := propagatePrefixes(pref1, pref2);
  outNewClass := SCode.CLASS(name, pref2, ep, pp, res, cdef, cmt, info);
end propagateAttributesClass;

public function propagatePrefixes
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

public function propagateAttributes
  input SCode.Attributes inOriginalAttributes;
  input SCode.Attributes inNewAttributes;
  output SCode.Attributes outNewAttributes;
protected
  Absyn.ArrayDim dims1, dims2;
  SCode.ConnectorType ct1, ct2;
  SCode.Parallelism prl1,prl2;
  SCode.Variability var1, var2;
  Absyn.Direction dir1, dir2;
algorithm
  SCode.ATTR(dims1, ct1, prl1, var1, dir1) := inOriginalAttributes;
  SCode.ATTR(dims2, ct2, prl2, var2, dir2) := inNewAttributes;
  dims2 := propagateArrayDimensions(dims1, dims2);
  ct2 := propagateConnectorType(ct1, ct2);
  prl2 := propagateParallelism(prl1,prl2);
  var2 := propagateVariability(var1, var2);
  dir2 := propagateDirection(dir1, dir2);
  outNewAttributes := SCode.ATTR(dims2, ct2, prl2, var2, dir2);
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
  print("replacing element: " +& inElementName +& " env: " +& FEnv.getEnvName(inEnv) +& "\n\t");
  print("Old Element:" +& FEnv.itemStr(inOldItem) +&
        " env: " +& FEnv.getEnvName(FEnv.getItemEnvNoFail(inOldItem)) +& "\n\t");
  print("New Element:" +& FEnv.itemStr(inNewItem) +&
        " env: " +& FEnv.getEnvName(FEnv.getItemEnvNoFail(inNewItem)) +&
        "\n===============\n");
      then ();

    else
      equation
  print("traceReplaceElementInScope failed on element: " +& inElementName +& "\n");
      then ();
  end matchcontinue;
end traceReplaceElementInScope;

protected function tracePushRedeclareIntoExtends
"@author: adrpo
 good for debugging redeclares.
 uncomment it in pushRedeclareIntoExtends to activate it"
  input SCode.Ident inName;
  input FEnv.Item inRedeclare;
  input list<Absyn.Path> inBaseClasses;
  input Env inEnv;
  input Env.ExtendsTable inEtNew;
  input Env.ExtendsTable inEtOld;
algorithm
  _ := matchcontinue(inName, inRedeclare, inBaseClasses, inEnv, inEtNew, inEtOld)
    case (_, _, _, _, _, _)
      equation
  print("pushing: " +& inName +& " redeclare: " +& FEnv.itemStr(inRedeclare) +& "\n\t");
  print("into baseclases: " +& stringDelimitList(List.map(inBaseClasses, Absyn.pathString), ", ") +& "\n\t");
  print("called from env: " +& FEnv.getEnvName(inEnv) +& "\n");
  print("-----------------\n");
      then ();

    else
      equation
  print("tracePushRedeclareIntoExtends failed on element: " +& inName +& "\n");
      then ();

  end matchcontinue;
end tracePushRedeclareIntoExtends;

end FFlattenRedeclare;
