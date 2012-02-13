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

encapsulated package SCodeFlattenRedeclare
" file:        SCodeFlattenRedeclare.mo
  package:     SCodeFlattenRedeclare
  description: SCode flattening

  RCS: $Id$

  This module contains redeclare-specific functions used by SCodeFlatten to
  handle redeclares. There are three different types of redeclares that are
  handled: redeclare modifiers, element redeclares and class extends.

  REDECLARE MODIFIERS:
  Redeclare modifiers are redeclarations given as modifiers on an extends
  clause. When an extends clause is added to the environment with
  SCodeEnv.extendEnvWithExtends these modifiers are extracted with
  extractRedeclareFromModifier as a list of elements, and then stored in the
  SCodeEnv.EXTENDS representation. When SCodeLookup.lookupInBaseClasses is used
  to search for an identifier in a base class, these elements are replaced in
  the environment prior to searching in it by the replaceRedeclares function.

  ELEMENT REDECLARES:
  Element redeclares are similar to redeclare modifiers, but they are declared
  as standalone elements that redeclare an inherited element. When the
  environment is built they are initially added to a list of elements in the
  extends tables by SCodeEnv.addElementRedeclarationToEnvExtendsTable. When the
  environment is complete and SCodeEnv.updateExtendsInEnv is used to update the
  extends these redeclares are handled by addElementRedeclarationsToEnv, which
  looks up which base class each redeclare is redeclaring in. The element
  redeclares are then added to the list of redeclarations in the correct
  SCodeEnv.EXTENDS, and handled in the same way as redeclare modifiers.

  CLASS EXTENDS:
  Class extends are handled by adding them to the environment with
  extendEnvWithClassExtends. This function adds the given class as a normal
  class to the environment, and sets the class extends information field in
  the class's environment. This information is the base class and modifiers of
  the class extends. This information is later used when extends are updated
  with SCodeEnv.updateExtendsInEnv, and updateClassExtends is called.
  updateClassExtends looks up the full path to the base class of the class
  extends, and adds an extends clause to the class that extends from the base
  class. 
  
  However, since it's possible to redeclare the base class of a class
  extends it's possible that the base class is replaced with a class that
  extends from it. If the base class were to be replaced with this class it
  would mean that the class extends itself, causing a loop. To avoid this an
  alias for the base class is added instead, and the base class itself is added
  with the BASE_CLASS_SUFFIX defined in SCodeEnv. The alias can then be safely
  redeclared while preserving the base class for the class extends to extend
  from. It's somewhat difficult to only add aliases for classes that are used by
  class extends though, so an alias is added for all replaceable classes in
  SCodeEnv.extendEnvWithClassDef for simplicity's sake. The function
  SCodeEnv.resolveAlias is then used to resolve any alias items to the real
  items whenever an item is looked up in the environment.
  
  Class extends on the form 'redeclare class extends X' are thus
  translated to 'class X extends BaseClass.X$base', and then mostly handled like a
  normal class. Some care is needed in the dependency analysis to make sure
  that nothing important is removed, see comment in
  SCodeDependency.analyseClassExtends.  
"

public import Absyn;
public import SCode;
public import SCodeEnv;
public import SCodeLookup;

public type Env = SCodeEnv.Env;
public type Item = SCodeEnv.Item;
public type Extends = SCodeEnv.Extends;

protected import Debug;
protected import Error;
protected import Flags;
protected import List;
protected import SCodeCheck;
protected import Util;
protected import SCodeDump;

public function extendEnvWithClassExtends
  input SCode.Element inClassExtends;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inClassExtends, inEnv)
    local
      SCode.Ident bc, cls_name;
      list<SCode.Element> el;
      Absyn.Path path;
      SCode.Partial pp;
      SCode.Encapsulated ep;
      SCode.Restriction res;
      SCode.Prefixes prefixes;
      Absyn.Info info;
      Env env, cls_env;
      SCode.Mod mods;
      Option<SCode.ExternalDecl> ext_decl;
      list<SCode.Annotation> annl;
      Option<SCode.Comment> cmt;
      list<SCode.Equation> nel, iel;
      list<SCode.AlgorithmSection> nal, ial;
      Option<Absyn.ConstrainClass> cc;
      SCode.ClassDef cdef;
      SCode.Element cls, ext;
      String el_str, env_str, err_msg;

    // When a 'redeclare class extends X' is encountered we insert a 'class X
    // extends BaseClass.X' into the environment, with the same elements as the
    // class extends clause. BaseClass is the class that class X is inherited
    // from. This allows us to look up elements in class extends, because
    // lookup can handle normal extends. This is the first phase where the
    // CLASS_EXTENDS is converted to a PARTS and added to the environment, and
    // the extends is added to the class environment's extends table. The
    // proper base class will be looked up in the second phase, in
    // updateClassExtends
    case (SCode.CLASS(
        prefixes = prefixes,
        encapsulatedPrefix = ep,
        partialPrefix = pp,
        restriction = res,
        classDef = SCode.CLASS_EXTENDS(
          baseClassName = bc, 
          modifications = mods,
          composition = SCode.PARTS(
            elementLst = el,
            normalEquationLst = nel,
            initialEquationLst = iel,
            normalAlgorithmLst = nal,
            initialAlgorithmLst = ial,
            externalDecl = ext_decl,
            annotationLst = annl,
            comment = cmt)),
        info = info), _)
      equation
        // Construct a PARTS from the CLASS_EXTENDS.
        cdef = SCode.PARTS(el, nel, iel, nal, ial, ext_decl, annl, cmt);
        cls = SCode.CLASS(bc, prefixes, ep, pp, res, cdef, info);

        // Construct the class environment and add the new extends to it.
        cls_env = SCodeEnv.makeClassEnvironment(cls, false);
        ext = SCode.EXTENDS(Absyn.IDENT(bc), SCode.PUBLIC(), mods, NONE(), info);
        cls_env = addClassExtendsInfoToEnv(ext, cls_env);

        // Finally add the class to the environment.
        env = SCodeEnv.extendEnvWithItem(
          SCodeEnv.newClassItem(cls, cls_env, SCodeEnv.CLASS_EXTENDS()), inEnv, bc);
      then env;

    case (_, _)
      equation
        info = SCode.elementInfo(inClassExtends);
        el_str = SCodeDump.printElementStr(inClassExtends);
        env_str = SCodeEnv.getEnvName(inEnv);
        err_msg = "SCodeFlattenRedeclare.extendEnvWithClassExtends failed on unknown element " +& 
          el_str +& " in " +& env_str;
        Error.addSourceMessage(Error.INTERNAL_ERROR, {err_msg}, info);
      then
        fail();

  end match;
end extendEnvWithClassExtends;
  
protected function addClassExtendsInfoToEnv
  "Adds a class extends to the environment."
  input SCode.Element inClassExtends;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inClassExtends, inEnv)
    local
      list<Extends> bcl;
      list<SCode.Element> re;
      String estr;
      SCodeEnv.ExtendsTable ext;

    case (_, _)
      equation
        SCodeEnv.EXTENDS_TABLE(bcl, re, NONE()) = 
          SCodeEnv.getEnvExtendsTable(inEnv);
        ext = SCodeEnv.EXTENDS_TABLE(bcl, re, SOME(inClassExtends));
      then
        SCodeEnv.setEnvExtendsTable(ext, inEnv);

    else
      equation
        estr = "- SCodeFlattenRedeclare.addClassExtendsInfoToEnv: Trying to overwrite " +& 
               "existing class extends information, this should not happen!.";
        Error.addMessage(Error.INTERNAL_ERROR, {estr});
      then
        fail();

  end matchcontinue;
end addClassExtendsInfoToEnv;

public function updateClassExtends
  input SCode.Element inClass;
  input Env inEnv;
  input SCodeEnv.ClassType inClassType;
  output SCode.Element outClass;
  output Env outEnv;
algorithm
  (outClass, outEnv) := match(inClass, inEnv, inClassType)
    local
      String name;
      Env env;
      Absyn.Path bc;
      SCode.Mod mods;
      Absyn.Info info;
      SCodeEnv.Frame cls_env;
      SCode.Element cls, ext;

    case (_, SCodeEnv.FRAME(name = SOME(name), 
        extendsTable = SCodeEnv.EXTENDS_TABLE(classExtendsInfo = SOME(ext))) :: _,
        SCodeEnv.CLASS_EXTENDS())
      equation
        SCode.EXTENDS(modifications = mods, info = info) = ext;
        (cls, env) = updateClassExtends2(inClass, name, mods, info, inEnv);
      then
        (cls, env);

    else (inClass, inEnv);
  end match;
end updateClassExtends;

protected function updateClassExtends2
  input SCode.Element inClass;
  input String inName;
  input SCode.Mod inMods;
  input Absyn.Info inInfo;
  input Env inEnv;
  output SCode.Element outClass;
  output Env outEnv;
algorithm
  (outClass, outEnv) := match(inClass, inName, inMods, inInfo, inEnv)
    local
      Absyn.Path path;
      SCode.Element ext;
      SCodeEnv.Frame cls_frame;
      Env env;
      SCode.Element cls;
      Item item;
      Absyn.Path info, p;
      String n;

    case (_, _, _, _, cls_frame :: env)
      equation
        (path, item) = lookupClassExtendsBaseClass(inName, env, inInfo);
        SCodeCheck.checkClassExtendsReplaceability(item, Absyn.dummyInfo);
        path = Absyn.pathReplaceIdent(path, inName +& SCodeEnv.BASE_CLASS_SUFFIX);
        ext = SCode.EXTENDS(path, SCode.PUBLIC(), inMods, NONE(), inInfo);
        {cls_frame} = SCodeEnv.extendEnvWithExtends(ext, {cls_frame});
        cls = SCode.addElementToClass(ext, inClass);
      then
        (cls, cls_frame :: env);

  end match;
end updateClassExtends2;

protected function lookupClassExtendsBaseClass
  "This function takes the name of a base class and looks up that name suffixed
   with the base class suffix defined in SCodeEnv. I.e. it looks up the real base
   class of a class extends, and not the alias introduced when adding replaceable
   classes to the environment in SCodeEnv.extendEnvWithClassDef. It returns the
   fully qualified path and the item for that base class."
  input String inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Absyn.Path outPath;
  output Item outItem;
algorithm
  (outPath, outItem) := matchcontinue(inName, inEnv, inInfo)
    local
      Absyn.Path path;
      Item item;
      String basename;

    // Add the base class suffix to the name and try to look it up.
    case (_, _, _)
      equation
        basename = inName +& SCodeEnv.BASE_CLASS_SUFFIX;
        (path, item) = SCodeLookup.lookupBaseClass(basename, inEnv, inInfo);
        path = Absyn.joinPaths(path, Absyn.IDENT(basename));
      then
        (path, item);

    // The previous case will fail if we try to class extend a
    // non-replaceable class, because they don't have aliases. To get the
    // correct error message later we look the class up via the non-alias name
    // instead and return that result if found.
    case (_, _, _)
      equation
        (path, item) = SCodeLookup.lookupBaseClass(inName, inEnv, inInfo);
        path = Absyn.joinPaths(path, Absyn.IDENT(inName));
      then
        (path, item);
        
    else
      equation
        Error.addSourceMessage(Error.INVALID_REDECLARATION_OF_CLASS,
          {inName}, inInfo);
      then
        fail();

  end matchcontinue;
end lookupClassExtendsBaseClass;

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
      Absyn.Path path;
      Env env, class_env;
      Item base_item, item;
      SCode.Element redecl;

    // redeclare-as-element class
    case (redecl as SCode.CLASS(name = cls_name, info = info), _)
      equation
        (path, base_item) = SCodeLookup.lookupBaseClass(cls_name, inEnv, info);
        class_env = SCodeEnv.makeClassEnvironment(redecl, true);
        item = SCodeEnv.newClassItem(inRedeclare, class_env, SCodeEnv.USERDEFINED());
        item = SCodeEnv.linkItemUsage(base_item, item);
        env = addRedeclareToEnvExtendsTable(item, path, inEnv, info);
      then
        env;

    // redeclare-as-element component
    case (redecl as SCode.COMPONENT(name = name, info = info), _)
      equation
        (path, base_item) = SCodeLookup.lookupBaseClass(name, inEnv, info);
        item = SCodeEnv.newVarItem(redecl, true);
        item = SCodeEnv.linkItemUsage(base_item, item);
        env = addRedeclareToEnvExtendsTable(item, path, inEnv, info);
      then
        env;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- SCodeFlattenRedeclare.addElementRedeclarationsToEnv failed for " +&
          SCode.elementName(inRedeclare) +& " in " +& 
          SCodeEnv.getEnvName(inEnv) +& "\n");
      then
        fail();
  end matchcontinue;
end addElementRedeclarationsToEnv2;

protected function addRedeclareToEnvExtendsTable
  input Item inRedeclaredElement;
  input Absyn.Path inBaseClass;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Env outEnv;
protected
  list<Extends> bcl;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
algorithm
  SCodeEnv.EXTENDS_TABLE(bcl, re, cei) := SCodeEnv.getEnvExtendsTable(inEnv);
  bcl := addRedeclareToEnvExtendsTable2(inRedeclaredElement, inBaseClass, bcl);
  outEnv := SCodeEnv.setEnvExtendsTable(SCodeEnv.EXTENDS_TABLE(bcl, re, cei), inEnv);
end addRedeclareToEnvExtendsTable;

protected function addRedeclareToEnvExtendsTable2
  input Item inRedeclaredElement;
  input Absyn.Path inBaseClass;
  input list<Extends> inExtends;
  output list<Extends> outExtends;
algorithm
  outExtends := matchcontinue(inRedeclaredElement, inBaseClass, inExtends)
    local
      Extends ex;
      list<Extends> exl;
      Absyn.Path bc;
      list<SCodeEnv.Redeclaration> el;
      Absyn.Info info;
      SCode.Ident name;
      SCodeEnv.Redeclaration redecl;

    // redeclare-as-class 
    case (SCodeEnv.CLASS(cls = _), _, SCodeEnv.EXTENDS(bc, el, info) :: exl)
      equation
        true = Absyn.pathEqual(inBaseClass, bc);
        redecl = SCodeEnv.PROCESSED_MODIFIER(inRedeclaredElement);
        SCodeCheck.checkDuplicateRedeclarations(redecl, el);
        ex = SCodeEnv.EXTENDS(bc, redecl :: el, info);
      then
        ex :: exl;

    // redeclare-as-element component
    case (SCodeEnv.VAR(var = _), _, SCodeEnv.EXTENDS(bc, el, info) :: exl)
      equation
        true = Absyn.pathEqual(inBaseClass, bc);
        redecl = SCodeEnv.PROCESSED_MODIFIER(inRedeclaredElement);
        SCodeCheck.checkDuplicateRedeclarations(redecl, el);
        ex = SCodeEnv.EXTENDS(bc, redecl :: el, info);
      then
        ex :: exl;

    case (_, _, ex :: exl)
      equation
        exl = addRedeclareToEnvExtendsTable2(inRedeclaredElement, inBaseClass, exl);
      then
        ex :: exl;
    
  end matchcontinue;
end addRedeclareToEnvExtendsTable2;

public function qualifyRedeclare
  "Since a modifier might redeclare an element in a variable with a type that
  is not reachable from the component type we need to fully qualify the element. 
    Ex:
      A a(redeclare package P = P1)
  where P1 is not reachable from A."
  input SCodeEnv.Redeclaration inRedeclare;
  input Env inEnv;
  output SCodeEnv.Redeclaration outRedeclare;
algorithm
  outRedeclare := match(inRedeclare, inEnv)
    local
      SCode.Ident name;
      SCode.Partial pp;
      SCode.Encapsulated ep;
      SCode.Prefixes prefixes;
      Option<Absyn.ArrayDim> ad;
      Absyn.Path path;
      SCode.Mod mods;
      Option<SCode.Comment> cmt;
      SCode.Restriction res;
      Absyn.Info info;
      SCode.Attributes attr;
      Option<Absyn.Exp> cond;
      Option<Absyn.ArrayDim> array_dim;

    case (SCodeEnv.RAW_MODIFIER(SCode.CLASS(
          name = name,
          prefixes = prefixes,
          encapsulatedPrefix = ep, 
          partialPrefix = pp,
          restriction = res,
          classDef = SCode.DERIVED(
              typeSpec = Absyn.TPATH(path, ad),
              modifications = mods, 
              attributes = attr, 
              comment = cmt),
            info = info
          )), _)
      equation
        path = SCodeLookup.qualifyPath(path, inEnv, info, SOME(Error.LOOKUP_ERROR));
        prefixes = SCode.prefixesSetRedeclare(prefixes, SCode.NOT_REDECLARE());
      then
        SCodeEnv.RAW_MODIFIER(SCode.CLASS(name, prefixes, ep, pp, res,
            SCode.DERIVED(Absyn.TPATH(path, ad), mods, attr, cmt),
            info));

    case (SCodeEnv.RAW_MODIFIER(SCode.CLASS(name = _)), _) then inRedeclare;

    case (SCodeEnv.RAW_MODIFIER(SCode.COMPONENT(name, prefixes, attr, 
        Absyn.TPATH(path, array_dim), mods, cmt, cond, info)), _)
      equation
        path = SCodeLookup.qualifyPath(path, inEnv, info, SOME(Error.LOOKUP_ERROR));
      then
        SCodeEnv.RAW_MODIFIER(SCode.COMPONENT(name, prefixes, attr, 
          Absyn.TPATH(path, array_dim), mods, cmt, cond, info));
    
    case (SCodeEnv.PROCESSED_MODIFIER(modifier = _), _) then inRedeclare;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- SCodeFlattenRedeclare.qualifyRedeclare failed on " +&
          SCodeDump.printElementStr(SCodeEnv.getRedeclarationElement(inRedeclare)) +& 
          " in " +& Absyn.pathString(SCodeEnv.getEnvPath(inEnv)));
      then
        fail();
  end match;
end qualifyRedeclare;

public function replaceRedeclares
  "Replaces redeclares in the environment. This function takes a list of
   redeclares, the item and environment of the class in which they should be
   redeclared, and the environment in which the modified element was declared
   (used to qualify the redeclares). The redeclares are then either replaced if
   they can be found in the immediate local environment of the class, or pushed
   into the correct extends clauses if they are inherited." 
  input list<SCodeEnv.Redeclaration> inRedeclares;
  input Item inClassItem "The item of the class to be modified.";
  input Env inClassEnv "The environment of the class to be modified.";
  input Env inElementEnv "The environment in which the modified element was declared.";
  input SCodeLookup.RedeclareReplaceStrategy inReplaceRedeclares;
  output Option<Item> outItem;
  output Option<Env> outEnv;
algorithm
  (outItem, outEnv) := matchcontinue(inRedeclares, inClassItem, inClassEnv,
      inElementEnv, inReplaceRedeclares)
    local
      Item item;
      Env env;

    case (_, _, _, _, SCodeLookup.IGNORE_REDECLARES()) 
      then (SOME(inClassItem), SOME(inClassEnv));

    case (_, _, _, _, SCodeLookup.INSERT_REDECLARES())
      equation
        (item, env) = replaceRedeclaredElementsInEnv(inRedeclares,
          inClassItem, inClassEnv, inElementEnv);
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
  input list<SCodeEnv.Redeclaration> inRedeclares "The redeclares from the modifications.";
  input Item inItem "The type of the element.";
  input Env inTypeEnv "The enclosing scopes of the type.";
  input Env inElementEnv "The environment in which the element was declared.";
  output Item outItem;
  output Env outEnv;
algorithm
  (outItem, outEnv) := matchcontinue(inRedeclares, inItem, inTypeEnv, inElementEnv)
    local
      SCode.Element cls;
      Env env;
      SCodeEnv.Frame item_env;
      SCodeEnv.ClassType cls_ty;
      list<SCodeEnv.Redeclaration> redecls;

    // no redeclares!
    case ({}, _, _, _) then (inItem, inTypeEnv);

    case (_, SCodeEnv.VAR(var = _), _, _) then (inItem, inTypeEnv);

    case (_, SCodeEnv.CLASS(cls = cls, env = {item_env}, classType = cls_ty), _, _)
      equation
        // Merge the types environment with it's enclosing scopes to get the
        // enclosing scopes of the classes we need to replace.
        env = SCodeEnv.enterFrame(item_env, inTypeEnv);
        // Fully qualify the redeclares to make sure they can be found.
        redecls = List.map1(inRedeclares, qualifyRedeclare, inElementEnv);
        env = List.fold(redecls, replaceRedeclaredElementInEnv, env);
        item_env :: env = env;
      then
        (SCodeEnv.CLASS(cls, {item_env}, cls_ty), env);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv failed for: ");
        Debug.traceln("redeclares: " +& 
          stringDelimitList(List.map(inRedeclares, SCodeEnv.printRedeclarationStr), "\n---------\n") +&  
          " item: " +& SCodeEnv.getItemName(inItem) +& " in scope:" +& SCodeEnv.getEnvName(inElementEnv));
      then
        fail();
  end matchcontinue;
end replaceRedeclaredElementsInEnv;

public function extractRedeclaresFromModifier
  "Returns a list of redeclare elements given a redeclaration modifier."
  input SCode.Mod inMod;
  output list<SCodeEnv.Redeclaration> outRedeclares;
algorithm
  outRedeclares := match(inMod)
    local
      list<SCode.SubMod> sub_mods;
      list<SCodeEnv.Redeclaration> redeclares;
    
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
  input list<SCodeEnv.Redeclaration> inRedeclares;
  output list<SCodeEnv.Redeclaration> outRedeclares;
algorithm
  outRedeclares := match(inMod, inRedeclares)
    local
      SCode.Element el;
      SCodeEnv.Redeclaration redecl; 

    case (SCode.NAMEMOD(A = SCode.REDECL(element = el)), _)
      equation
        redecl = SCodeEnv.RAW_MODIFIER(el);
        SCodeCheck.checkDuplicateRedeclarations(redecl, inRedeclares);
      then
        redecl :: inRedeclares;

    // Skip modifiers that are not redeclarations.
    else then inRedeclares;
  end match;
end extractRedeclareFromSubMod;

protected function replaceRedeclaredElementInEnv
  "Replaces a redeclaration in the environment."
  input SCodeEnv.Redeclaration inRedeclare;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inRedeclare, inEnv)
    local
      SCode.Ident name;
      Item item;
      Absyn.Info info;
      Absyn.Path path;
      SCodeEnv.Redeclaration redecl;

    // Try to redeclare this element in the current scope.
    case (SCodeEnv.PROCESSED_MODIFIER(modifier = item), _)
      equation
        name = SCodeEnv.getItemName(item);
      then  
        replaceElementInScope(name, item, inEnv);
        
    // If the previous case failed, see if we can find the redeclared element in
    // any of the base classes. If so, push the redeclare into those base
    // classes instead, i.e. add them to the list of redeclares in the
    // appropriate extends in the extends table.
    case (SCodeEnv.PROCESSED_MODIFIER(modifier = item), _)
      equation
        name = SCodeEnv.getItemName(item);
        info = SCodeEnv.getItemInfo(item);
        (path, _) = SCodeLookup.lookupBaseClass(name, inEnv, info);
      then
        pushRedeclareIntoExtends(item, path, inEnv);
        
    // A raw modifier, process it first.
    case (SCodeEnv.RAW_MODIFIER(modifier = _), _)
      equation
        redecl = processRedeclaration(inRedeclare);
      then
        replaceRedeclaredElementInEnv(redecl, inEnv);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- SCodeEnv.replaceRedeclaredElementInEnv failed on " +&
          SCode.elementName(SCodeEnv.getRedeclarationElement(inRedeclare)) +& 
          " in " +& SCodeEnv.getEnvName(inEnv));
      then
        fail();
  end matchcontinue;
end replaceRedeclaredElementInEnv;

protected function pushRedeclareIntoExtends
  "Pushes a redeclare into the given extends in the environment."
  input Item inRedeclare;
  input Absyn.Path inBaseClass;
  input Env inEnv;
  output Env outEnv;
protected
  list<SCodeEnv.Extends> exts;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
  SCodeEnv.ExtendsTable et;
  String name;
algorithm
  SCodeEnv.FRAME(extendsTable = SCodeEnv.EXTENDS_TABLE(exts, re, cei)) :: _ := inEnv;
  name := SCodeEnv.getItemName(inRedeclare);
  exts := pushRedeclareIntoExtends2(inRedeclare, name, inBaseClass, exts);
  et := SCodeEnv.EXTENDS_TABLE(exts, re, cei);
  outEnv := SCodeEnv.setEnvExtendsTable(et, inEnv);
end pushRedeclareIntoExtends;

protected function pushRedeclareIntoExtends2
  "Given the name of a base class, find that extends in the given list of
   extends, and add the given redeclare to it's list of redeclares."
  input Item inRedeclare;
  input String inName;
  input Absyn.Path inBaseClass;
  input list<SCodeEnv.Extends> inExtends;
  output list<SCodeEnv.Extends> outExtends;
algorithm
  outExtends := matchcontinue(inRedeclare, inName, inBaseClass, inExtends)
    local
      Absyn.Path bc;
      list<SCodeEnv.Redeclaration> redecls;
      Absyn.Info info;
      list<SCodeEnv.Extends> rest_exts;
      SCodeEnv.Extends ext;
      String bc_str, err_msg;

    case (_, _, _, SCodeEnv.EXTENDS(bc, redecls, info) :: rest_exts)
      equation
        true = Absyn.pathEqual(bc, inBaseClass);
        redecls = pushRedeclareIntoExtends3(inRedeclare, inName, redecls);
      then
        SCodeEnv.EXTENDS(bc, redecls, info) :: rest_exts;

    case (_, _, _, ext :: rest_exts)
      equation
        rest_exts = pushRedeclareIntoExtends2(inRedeclare, inName, inBaseClass,
          rest_exts);
      then
        ext :: rest_exts;

    case (_, _, _, {})
      equation
        bc_str = Absyn.pathString(inBaseClass);
        err_msg = "SCodeFlattenRedeclare.pushRedeclareIntoExtends2 couldn't find the base class " +& 
           bc_str +& " for " +& inName +& "\n";
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
  input list<SCodeEnv.Redeclaration> inRedeclares;
  output list<SCodeEnv.Redeclaration> outRedeclares;
algorithm
  outRedeclares := matchcontinue(inRedeclare, inName, inRedeclares)
    local
      Item item;
      SCodeEnv.Redeclaration redecl;
      list<SCodeEnv.Redeclaration> rest_redecls;
      String name;

    case (_, _, SCodeEnv.PROCESSED_MODIFIER(modifier = item) :: rest_redecls)
      equation
        name = SCodeEnv.getItemName(item);
        true = stringEqual(name, inName);
      then
        SCodeEnv.PROCESSED_MODIFIER(item) :: rest_redecls;

    case (_, _, redecl :: rest_redecls)
      equation
        rest_redecls = pushRedeclareIntoExtends3(inRedeclare, inName, rest_redecls);
      then
        redecl :: rest_redecls;

    case (_, _, {}) then {SCodeEnv.PROCESSED_MODIFIER(inRedeclare)};

  end matchcontinue;
end pushRedeclareIntoExtends3;
        
protected function replaceElementInScope
  "Replaces an element in the current scope."
  input SCode.Ident inElementName;
  input Item inElement;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inElementName, inElement, inEnv)
    local
      SCodeEnv.AvlTree tree;
      Item old_item, new_item;

    case (_, _, SCodeEnv.FRAME(clsAndVars = tree) :: _)
      equation
        old_item = SCodeEnv.avlTreeGet(tree, inElementName);
        //print("Replacing " +& inElementName +& " in " +& SCodeEnv.getEnvName(inEnv) +& "\n");
        new_item = propagateItemPrefixes(old_item, inElement);
        new_item = SCodeEnv.linkItemUsage(old_item, new_item);
        tree = SCodeEnv.avlTreeReplace(tree, inElementName, new_item);
      then
        SCodeEnv.setEnvClsAndVars(tree, inEnv);

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
      SCodeEnv.ClassType ty1, ty2;
      String name, res_str;
      Absyn.Info info1, info2;
      SCode.Restriction res;

    case (SCodeEnv.VAR(var = el1, isUsed = iu1), 
          SCodeEnv.VAR(var = el2, isUsed = iu2))
      equation
        el2 = propagateAttributesVar(el1, el2);
      then
        SCodeEnv.VAR(el2, iu2);

    case (SCodeEnv.CLASS(cls = el1, env = env1, classType = ty1),
          SCodeEnv.CLASS(cls = el2, env = env2, classType = ty2))
      equation
        el2 = propagateAttributesClass(el1, el2);
      then
        SCodeEnv.CLASS(el2, env2, ty2);

    case (SCodeEnv.ALIAS(path = _), _) then inNewItem;

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"SCodeFlattenRedeclare.propagateAttributes failed on unknown item."});
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
  Option<SCode.Comment> cmt;
  Option<Absyn.Exp> cond;
  Absyn.Info info;
algorithm
  SCode.COMPONENT(prefixes = pref1, attributes = attr1) := inOriginalVar;
  SCode.COMPONENT(name, pref2, attr2, ty, mod, cmt, cond, info) := inNewVar;
  pref2 := propagatePrefixes(pref1, pref2);
  attr2 := propagateAttributes(attr1, attr2);
  outNewVar := SCode.COMPONENT(name, pref2, attr2, ty, mod, cmt, cond, info);
end propagateAttributesVar;

protected function propagateAttributesClass
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
  Absyn.Info info;
algorithm
  SCode.CLASS(prefixes = pref1) := inOriginalClass;
  SCode.CLASS(name, pref2, ep, pp, res, cdef, info) := inNewClass;
  pref2 := propagatePrefixes(pref1, pref2);
  outNewClass := SCode.CLASS(name, pref2, ep, pp, res, cdef, info);
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
  SCode.Flow fp1, fp2;
  SCode.Stream sp1, sp2;
  SCode.Parallelism prl1,prl2;
  SCode.Variability var1, var2;
  Absyn.Direction dir1, dir2;
algorithm
  SCode.ATTR(dims1, fp1, sp1, prl1, var1, dir1) := inOriginalAttributes;
  SCode.ATTR(dims2, fp2, sp2, prl2, var2, dir2) := inNewAttributes;
  dims2 := propagateArrayDimensions(dims1, dims2);
  fp2 := propagateFlowPrefix(fp1, fp2);
  sp2 := propagateStreamPrefix(sp1, sp2);
  prl2 := propagateParallelism(prl1,prl2);
  var2 := propagateVariability(var1, var2);
  dir2 := propagateDirection(dir1, dir2);
  outNewAttributes := SCode.ATTR(dims2, fp2, sp2, prl2, var2, dir2);
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

protected function propagateFlowPrefix
  input SCode.Flow inOriginalFlow;
  input SCode.Flow inNewFlow;
  output SCode.Flow outNewFlow;
algorithm
  outNewFlow := match(inOriginalFlow, inNewFlow)
    case (_, SCode.NOT_FLOW()) then inOriginalFlow;
    else inNewFlow;
  end match;
end propagateFlowPrefix;

protected function propagateStreamPrefix
  input SCode.Stream inOriginalStream;
  input SCode.Stream inNewStream;
  output SCode.Stream outNewStream;
algorithm
  outNewStream := match(inOriginalStream, inNewStream)
    case (_, SCode.NOT_STREAM()) then inOriginalStream;
    else inNewStream;
  end match;
end propagateStreamPrefix;

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

protected function processRedeclaration
  input SCodeEnv.Redeclaration inRedeclare;
  output SCodeEnv.Redeclaration outRedeclare;
algorithm
  outRedeclare := match(inRedeclare)
    local
      Env class_env;
      Item item;
      SCode.Element e;

    case SCodeEnv.RAW_MODIFIER(modifier = e as SCode.CLASS(name = _))
      equation
        class_env = SCodeEnv.makeClassEnvironment(e, true);
        item = SCodeEnv.newClassItem(e, class_env, SCodeEnv.USERDEFINED());
      then
        SCodeEnv.PROCESSED_MODIFIER(item);

    case SCodeEnv.RAW_MODIFIER(modifier = e as SCode.COMPONENT(name = _))
      equation
        item = SCodeEnv.newVarItem(e, false);
      then
        SCodeEnv.PROCESSED_MODIFIER(item);

    else inRedeclare;
  end match;
end processRedeclaration;

public function lookupExtendsRedeclaresInTable
  input Absyn.Path inExtendsName;
  input SCodeEnv.ExtendsTable inTable;
  output list<SCodeEnv.Redeclaration> outRedeclares;
algorithm
  outRedeclares := matchcontinue(inExtendsName, inTable)
    local
      list<SCodeEnv.Extends> bcl;
      list<SCodeEnv.Redeclaration> redecls;
      String err_str;

    case (_, SCodeEnv.EXTENDS_TABLE(baseClasses = bcl))
      equation
        SCodeEnv.EXTENDS(redeclareModifiers = redecls) =
          List.getMemberOnTrue(inExtendsName, bcl, matchExtendsPath);
      then
        redecls;

    else
      equation
        err_str = Absyn.pathString(inExtendsName);
        err_str = "SCodeFlattenRedeclare.lookupExtendsRedeclaresInTable failed on " +& err_str +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {err_str});
      then
        {};
  end matchcontinue;
end lookupExtendsRedeclaresInTable;

protected function matchExtendsPath
  input Absyn.Path inPath;
  input SCodeEnv.Extends inExtends;
  output Boolean outMatches;
protected
  Absyn.Path path;
algorithm
  SCodeEnv.EXTENDS(baseClass = path) := inExtends;
  outMatches := Absyn.pathEqual(inPath, path);
end matchExtendsPath;

end SCodeFlattenRedeclare;
