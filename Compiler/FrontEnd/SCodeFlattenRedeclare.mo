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
  outEnv := matchcontinue(inClassExtends, inEnv)
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

    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = bc), info = info), _)
      equation
        Error.addSourceMessage(Error.INVALID_REDECLARATION_OF_CLASS,
          {bc}, info);
      then
        fail();

  end matchcontinue;
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

    case (_, _, _)
      equation
        basename = inName +& SCodeEnv.BASE_CLASS_SUFFIX;
        (path, item) = SCodeLookup.lookupBaseClass(basename, inEnv, inInfo);
        path = Absyn.joinPaths(path, Absyn.IDENT(basename));
      then
        (path, item);

    // The previous case might fail if we try to class extend from a
    // non-replaceable class which doesn't have have an alias. To get the
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
    
    // TODO! is this correct??
    case (SCodeEnv.PROCESSED_MODIFIER(_), _)
      then
        inRedeclare;

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
  input list<SCodeEnv.Redeclaration> inRedeclares;
  input Absyn.Path inBaseClassName;
  input Item inBaseClassItem;
  input Env inBaseClassEnv;
  input Env inEnv;
  input SCodeLookup.RedeclareReplaceStrategy inReplaceRedeclares;
  output Option<Item> outItem;
  output Option<Env> outEnv;
algorithm
  (outItem, outEnv) := matchcontinue(inRedeclares, inBaseClassName, inBaseClassItem,
      inBaseClassEnv, inEnv, inReplaceRedeclares)
    local
      Item item;
      Env env;
      Absyn.Path bc;

    case (_, _, _, _, _, SCodeLookup.IGNORE_REDECLARES()) 
      then (SOME(inBaseClassItem), SOME(inEnv));

    case (_, bc, _, _, _, SCodeLookup.INSERT_REDECLARES())
      equation
        (item, env) = replaceRedeclaredElementsInEnv(inRedeclares,
          inBaseClassItem, inBaseClassEnv, inEnv);
      then
        (SOME(item), SOME(env));

    else (NONE(), NONE());
  end matchcontinue;
end replaceRedeclares;

public function replaceRedeclaredElementsInEnv
  "If a variable has modifications that redeclare classes in it's instance we
  need to replace those classes in the environment so that the lookup finds the
  right classes. This function takes a list of redeclares from a variables
  modifications and applies them to the environment of the variables type."
  input list<SCodeEnv.Redeclaration> inRedeclares "The redeclares from the modifications.";
  input Item inItem "The type of the variable.";
  input Env inTypeEnv "The enclosing scopes of the type.";
  input Env inVarEnv "The environment in which the variable was declared.";
  output Item outItem;
  output Env outEnv;
algorithm
  (outItem, outEnv) := matchcontinue(inRedeclares, inItem, inTypeEnv, inVarEnv)
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
        redecls = List.map1(inRedeclares, qualifyRedeclare, inVarEnv);
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
          " item: " +& SCodeEnv.getItemName(inItem) +& " in scope:" +& SCodeEnv.getEnvName(inVarEnv));
      then
        fail();
  end matchcontinue;
end replaceRedeclaredElementsInEnv;

public function extractRedeclaresFromModifier
  "Returns a list of redeclare elements given a redeclaration modifier."
  input SCode.Mod inMod;
  input Env inEnv;
  output list<SCodeEnv.Redeclaration> outRedeclares;
algorithm
  outRedeclares := match(inMod, inEnv)
    local
      list<SCode.SubMod> sub_mods;
      list<SCodeEnv.Redeclaration> redeclares;
    
    case (SCode.MOD(subModLst = sub_mods), _)
      equation
        redeclares = List.fold1(sub_mods, extractRedeclareFromSubMod, inEnv, {});
      then
        redeclares;

    else then {};
  end match;
end extractRedeclaresFromModifier;

protected function extractRedeclareFromSubMod
  "Checks a submodifier and adds the redeclare element to the list of redeclares
  if the modifier is a redeclaration modifier."
  input SCode.SubMod inMod;
  input Env inEnv;
  input list<SCodeEnv.Redeclaration> inRedeclares;
  output list<SCodeEnv.Redeclaration> outRedeclares;
algorithm
  outRedeclares := match(inMod, inEnv, inRedeclares)
    local
      SCode.Element el;
      SCodeEnv.Redeclaration redecl; 

    // Redeclaration of a class definition.
    case (SCode.NAMEMOD(A = SCode.REDECL(elementLst = 
        {el as SCode.CLASS(name = _)})), _, _)
      equation
        redecl = SCodeEnv.RAW_MODIFIER(el);
        SCodeCheck.checkDuplicateRedeclarations(redecl, inRedeclares);
      then 
        redecl :: inRedeclares;

    // Redeclaration of a component.
    case (SCode.NAMEMOD(A = SCode.REDECL(elementLst =
        {el as SCode.COMPONENT(name = _)})), _, _)
      equation
        redecl = SCodeEnv.RAW_MODIFIER(el);
        SCodeCheck.checkDuplicateRedeclarations(redecl, inRedeclares);
      then 
        redecl :: inRedeclares;

    // Not a redeclaration.
    else then inRedeclares;
  end match;
end extractRedeclareFromSubMod;

protected function replaceRedeclaredElementInEnv
  "Replaces a redeclared element in the environment."
  input SCodeEnv.Redeclaration inRedeclare;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inRedeclare, inEnv)
    local
      SCode.Ident name;
      SCode.Element e;
      Env env, class_env;
      Absyn.Path path;
      Option<Env> opt_env;
      Absyn.Info info;
      Item item, replacement;
      SCodeEnv.Redeclaration redecl;

    // A processed redeclared class definition.
    case (SCodeEnv.PROCESSED_MODIFIER(modifier = replacement as SCodeEnv.CLASS(
        cls = SCode.CLASS(name = name, info = info))), _)
      equation
        (item, path, env) =
          SCodeLookup.lookupClassName(Absyn.IDENT(name), inEnv, info);
        SCodeCheck.checkRedeclaredElementPrefix(item, info);
        path = SCodeEnv.joinPaths(SCodeEnv.getEnvPath(env), path);
        env = replaceElementInEnv(path, replacement, inEnv);
      then
        env;

    // A processed redeclared component.
    case (SCodeEnv.PROCESSED_MODIFIER(modifier = replacement as SCodeEnv.VAR(
        var = SCode.COMPONENT(name = name, info = info))), _)
      equation
        (item, path, env) =
          SCodeLookup.lookupVariableName(Absyn.IDENT(name), inEnv, info);
        SCodeCheck.checkRedeclaredElementPrefix(item, info);
        path = SCodeEnv.joinPaths(SCodeEnv.getEnvPath(env), path);
        env = replaceElementInEnv(path, replacement, inEnv);
      then
        env;
        
    // An unprocessed redeclaration.
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

protected function replaceElementInEnv
  "Replaces an element in the environment with another element, which is needed
  for redeclare. There are two cases here: either the element we want to replace
  is in the current path or it's somewhere else in the environment. If it's in
  the current path we can just go through the frames until we find the right
  frame to replace the element in. If it's not we need to look up the correct
  class in the environment and continue into the class's environment."
  input Absyn.Path inPath;
  input SCodeEnv.Item inElement;
  input Env inEnv;
  output Env outEnv;
protected
  Env env;
  Boolean next_scope_available;
  SCodeEnv.Frame f;
algorithm
  // Reverse the frame order so that the frames are in the same order as the path.
  env := listReverse(inEnv);
  // Make the redeclare in both the current environment and the global.
  // TODO: do this in a better way.
  f :: env := replaceElementInEnv2(inPath, inElement, env);
  {f} := replaceElementInEnv2(inPath, inElement, {f});
  outEnv := listReverse(f :: env);
end replaceElementInEnv;

protected function checkNextScopeAvailability
  "Checks if the next scope in the environment is the scope we are looking for
  next. If the first identifier in the path has the same name as the next scope
  it returns true, otherwise false."
  input Absyn.Path inPath;
  input Env inEnv;
  output Boolean isAvailable;
algorithm
  isAvailable := match(inPath, inEnv)
    local
      String name, scope_name;

    case (Absyn.QUALIFIED(name = name), 
        _ :: SCodeEnv.FRAME(name = SOME(scope_name)) :: _)
      then stringEqual(name, scope_name);

    else then false;
  end match;
end checkNextScopeAvailability;

protected function replaceElementInEnv2
  "Helper function to replaceClassInEnv."
  input Absyn.Path inPath;
  input SCodeEnv.Item inElement;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := replaceElementInEnv3(inPath, inElement, inEnv,
    checkNextScopeAvailability(inPath, inEnv));
end replaceElementInEnv2;

protected function replaceElementInEnv3
  "Helper function to replaceClassInEnv."
  input Absyn.Path inPath;
  input SCodeEnv.Item inElement;
  input Env inEnv;
  input Boolean inNextScopeAvailable;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inPath, inElement, inEnv, inNextScopeAvailable)
    local
      String name, scope_name;
      Absyn.Path path;
      Env env, rest_env;
      SCodeEnv.Frame f;

    // A simple identifier means that the element should be replaced in the
    // current scope.
    case (Absyn.IDENT(name = name), _, _, _)
      equation
        env = replaceElementInScope(name, inElement, inEnv);
      then
        env;

    // If the next frame is the next scope we want to reach we can just continue
    // into it.
    case (Absyn.QUALIFIED(path = path), _, f :: rest_env, true)
      equation
        rest_env = replaceElementInEnv2(path, inElement, rest_env);
        env = f :: rest_env;
      then
        env;

    // If there are no more scopes available in the environment we need to start
    // going into classes in the environment instead.
    case (Absyn.QUALIFIED(name = name, path = path), _, _, false)
      equation
        env = replaceElementInClassEnv(inPath, inElement, inEnv);
      then
        env;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- SCodeFlattenRedeclare.replaceElementInEnv3 failed for ");
        Debug.trace(Absyn.pathString(inPath));
        Debug.trace(" in ");
        Debug.traceln(SCodeEnv.getEnvName(inEnv));
      then
        fail();

  end matchcontinue;
end replaceElementInEnv3;

protected function replaceElementInScope
  "Replaces an element in the current scope."
  input SCode.Ident inElementName;
  input SCodeEnv.Item inElement;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inElementName, inElement, inEnv)
    local
      Option<String> name;
      SCodeEnv.FrameType ty;
      SCodeEnv.AvlTree tree;
      SCodeEnv.ExtendsTable exts;
      SCodeEnv.ImportTable imps;
      Env env, class_env;
      Util.StatefulBoolean is_used;
      Item old_item, new_item;

    case (_, SCodeEnv.CLASS(cls = _), 
        SCodeEnv.FRAME(name, ty, tree, exts, imps, is_used) :: env)
      equation
        old_item = SCodeEnv.avlTreeGet(tree, inElementName);
        new_item = SCodeEnv.linkItemUsage(old_item, inElement);
        tree = SCodeEnv.avlTreeReplace(tree, inElementName, new_item);
      then
        SCodeEnv.FRAME(name, ty, tree, exts, imps, is_used) :: env;

    case (_, SCodeEnv.VAR(var = _),
        SCodeEnv.FRAME(name, ty, tree, exts, imps, is_used) :: env)
      equation
        tree = SCodeEnv.avlTreeReplace(tree, inElementName, inElement);
      then
        SCodeEnv.FRAME(name, ty, tree, exts, imps, is_used) :: env;

  end match;
end replaceElementInScope;

protected function replaceElementInClassEnv
  "Replaces an element in the environment of a class."
  input Absyn.Path inClassPath;
  input SCodeEnv.Item inElement;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inClassPath, inElement, inEnv)
    local
      Option<String> frame_name;
      SCodeEnv.FrameType ty;
      SCodeEnv.AvlTree tree;
      SCodeEnv.ExtendsTable exts;
      SCodeEnv.ImportTable imps;
      Env rest_env, class_env, env;
      Item item;
      String name;
      Absyn.Path path;
      SCode.Element cls;
      Util.StatefulBoolean is_used;
      SCodeEnv.ClassType cls_ty;

    // A simple identifier means that we have reached the environment in which
    // the element should be replaced.
    case (Absyn.IDENT(name = name), _, _)
      equation
        env = replaceElementInScope(name, inElement, inEnv);
      then
        env;

    // A qualified path means that we should look up the first identifier and
    // continue into the found class's environment.
    case (Absyn.QUALIFIED(name = name, path = path), _,
        SCodeEnv.FRAME(frame_name, ty, tree, exts, imps, is_used) :: rest_env)
      equation
        item = SCodeEnv.avlTreeGet(tree, name);
        (name, SCodeEnv.CLASS(cls = cls, env = class_env, classType = cls_ty)) = 
          replaceElementInClassEnv2(name, item, tree);
        class_env = replaceElementInClassEnv(path, inElement, class_env);
        tree = SCodeEnv.avlTreeReplace(tree, name, 
          SCodeEnv.newClassItem(cls, class_env, cls_ty));
      then
        SCodeEnv.FRAME(frame_name, ty, tree, exts, imps, is_used) :: rest_env;

  end matchcontinue;
end replaceElementInClassEnv;

protected function replaceElementInClassEnv2
  "Helper function to replaceElementInClassEnv. Makes sure that the replacement
  is done in the correct class with regards to aliases."
  input String inName;
  input SCodeEnv.Item inItem;
  input SCodeEnv.AvlTree inTree;
  output String outName;
  output SCodeEnv.Item outItem;
algorithm
  (outName, outItem) := match(inName, inItem, inTree)
    local
      String name;
      SCodeEnv.Item item;

    // An alias. Resolve it and return the correct name of the aliased class.
    case (_, SCodeEnv.ALIAS(path = Absyn.IDENT(name)), _)
      equation
        item = SCodeEnv.avlTreeGet(inTree, name);
        (name, item) = replaceElementInClassEnv2(name, item, inTree);
      then
        (name, item);

    else (inName, inItem);

  end match;
end replaceElementInClassEnv2;

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

end SCodeFlattenRedeclare;
