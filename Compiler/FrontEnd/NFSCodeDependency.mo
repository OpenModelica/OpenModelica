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

encapsulated package NFSCodeDependency
" file:        NFSCodeDependency.mo
  package:     NFSCodeDependency
  description: SCode dependency analysis.

  RCS: $Id$

  Dependency analysis for SCode.
"

public import Absyn;
public import SCode;
public import NFInstPrefix;
public import NFSCodeEnv;

public type Env = NFSCodeEnv.Env;

protected import Debug;
protected import Error;
protected import Flags;
protected import List;
protected import NFSCodeCheck;
protected import NFSCodeFlattenRedeclare;
protected import NFSCodeLookup;
protected import SCodeDump;
protected import System;
protected import Util;

protected type Item = NFSCodeEnv.Item;
protected type Extends = NFSCodeEnv.Extends;
protected type FrameType = NFSCodeEnv.FrameType;
protected type Import = Absyn.Import;

public function analyse
  "This is the entry point of the dependency analysis. The dependency analysis
  is done in three steps: first it analyses the program and marks each element in
  the program that's used. The it goes through the used classes and checks if
  they contain any class extends, and if so it checks of those class extends are
  used or not. Finally it collects the used elements and builds a new program
  and environment that only contains those elements."
  input Absyn.Path inClassName;
  input Env inEnv;
  input SCode.Program inProgram;
  output SCode.Program outProgram;
  output Env outEnv;
algorithm
  analyseClass(inClassName, inEnv, Absyn.dummyInfo);
  analyseClassExtends(inEnv);
  (outEnv, outProgram) :=
    collectUsedProgram(inEnv, inProgram, inClassName);
end analyse;

protected function analyseClass
  "Analyses a class by looking up the class, marking it as used and recursively
  analysing it's contents."
  input Absyn.Path inClassName;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inClassName, inEnv, inInfo)
    local
      Item item;
      Env env;

    case (_, _, _)
      equation
        (item, env) = lookupClass(inClassName, inEnv, true, inInfo,
          SOME(Error.LOOKUP_ERROR));
        checkItemIsClass(item);
        analyseItem(item, env);
      then
        ();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFSCodeDependency.analyseClass failed for " +
          Absyn.pathString(inClassName) + " in " +
          NFSCodeEnv.getEnvName(inEnv));
      then
        fail();

  end matchcontinue;
end analyseClass;

protected function lookupClass
  "Lookup a class in the environment. The reason why SCodeLookup is not used
  directly is because we need to look up each part of the class path and mark
  them as used."
  input Absyn.Path inPath;
  input Env inEnv;
  input Boolean inBuiltinPossible "True if the path can be a builtin, otherwise false.";
  input SourceInfo inInfo;
  input Option<Error.Message> inErrorType;
  output Item outItem;
  output Env outEnv;
algorithm
  (outItem, outEnv) := matchcontinue(inPath, inEnv, inBuiltinPossible, inInfo, inErrorType)
    local
      Item item;
      Env env;
      String name_str, env_str;
      Error.Message error_id;

    case (_, _, _, _, _)
      equation
        (item, env) = lookupClass2(inPath, inEnv, inBuiltinPossible, inInfo, inErrorType);
        (item, env, _) = NFSCodeEnv.resolveRedeclaredItem(item, env);
      then
        (item, env);

    case (_, _, _, _, SOME(error_id))
      equation
        name_str = Absyn.pathString(inPath);
        env_str = NFSCodeEnv.getEnvName(inEnv);
        Error.addSourceMessage(error_id, {name_str, env_str}, inInfo);
      then
        fail();
  end matchcontinue;
end lookupClass;

protected function lookupClass2
  "Help function to lookupClass, does the actual look up."
  input Absyn.Path inPath;
  input Env inEnv;
  input Boolean inBuiltinPossible;
  input SourceInfo inInfo;
  input Option<Error.Message> inErrorType;
  output Item outItem;
  output Env outEnv;
algorithm
  (outItem, outEnv) := match(inPath, inEnv, inBuiltinPossible, inInfo, inErrorType)
    local
      Item item;
      Env env;
      String id;
      Absyn.Path rest_path;

    case (Absyn.IDENT(), _, true, _, _)
      equation
        (item, _, env) =
          NFSCodeLookup.lookupNameSilent(inPath, inEnv, inInfo);
      then
        (item, env);

    case (Absyn.IDENT(), _, false, _, _)
      equation
        (item, _, env) =
          NFSCodeLookup.lookupNameSilentNoBuiltin(inPath, inEnv, inInfo);
      then
        (item, env);

    // Special case for the baseclass of a class extends. Should be looked up
    // among the inherited elements of the enclosing class.
    case (Absyn.QUALIFIED(name = "$ce", path = Absyn.IDENT(name = id)), _ :: env, _, _, _)
      equation
        (item, env) = NFSCodeLookup.lookupInheritedName(id, env);
      then
        (item, env);

    case (Absyn.QUALIFIED(name = id, path = rest_path), _, _, _, _)
      equation
        (item, _, env) =
          NFSCodeLookup.lookupNameSilent(Absyn.IDENT(id), inEnv, inInfo);
        (item, env, _) = NFSCodeEnv.resolveRedeclaredItem(item, env);
        analyseItem(item, env);
        (item, env) = lookupNameInItem(rest_path, item, env, inErrorType);
      then
        (item, env);

    case (Absyn.FULLYQUALIFIED(path = rest_path), _, _, _, _)
      equation
        env = NFSCodeEnv.getEnvTopScope(inEnv);
        (item, env) = lookupClass2(rest_path, env, false, inInfo, inErrorType);
      then
        (item, env);

  end match;
end lookupClass2;

protected function lookupNameInItem
  input Absyn.Path inName;
  input Item inItem;
  input Env inEnv;
  input Option<Error.Message> inErrorType;
  output Item outItem;
  output Env outEnv;
algorithm
  (outItem, outEnv) := match(inName, inItem, inEnv, inErrorType)
    local
      Absyn.Path type_path;
      SCode.Mod mods;
      SourceInfo info;
      Env env, type_env;
      NFSCodeEnv.Frame class_env;
      list<NFSCodeEnv.Redeclaration> redeclares;
      Item item;

    case (_, _, {}, _) then (inItem, inEnv);

    case (_, NFSCodeEnv.VAR(var = SCode.COMPONENT(typeSpec =
      Absyn.TPATH(path = type_path), modifications = mods, info = info)), _, _)
      equation
        (item, type_env) = lookupClass(type_path, inEnv, true, info, inErrorType);
        true = NFSCodeEnv.isClassItem(item);
        redeclares = NFSCodeFlattenRedeclare.extractRedeclaresFromModifier(mods);
        (item, type_env, _) = NFSCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(
          redeclares, item, type_env, inEnv, NFInstPrefix.emptyPrefix);
        (item, env) = lookupNameInItem(inName, item, type_env, inErrorType);
      then
        (item, env);

    case (_, NFSCodeEnv.CLASS(cls = SCode.CLASS(info = info), env = {class_env}), _, _)
      equation
        env = NFSCodeEnv.enterFrame(class_env, inEnv);
        (item, env) = lookupClass(inName, env, false, info, inErrorType);
      then
        (item, env);

  end match;
end lookupNameInItem;

protected function checkItemIsClass
  "Checks that the found item really is a class, otherwise prints an error
  message."
  input Item inItem;
algorithm
  _ := match(inItem)
    local
      String name;
      SourceInfo info;

    case NFSCodeEnv.CLASS() then ();

    // We found a component instead, which might happen if the user tries to use
    // a variable name as a type.
    case NFSCodeEnv.VAR(var = SCode.COMPONENT(name = name, info = info))
      equation
        Error.addSourceMessage(Error.LOOKUP_TYPE_FOUND_COMP, {name}, info);
      then
        fail();
  end match;
end checkItemIsClass;

protected function analyseItem
  "Analyses an item."
  input Item inItem;
  input Env inEnv;
algorithm
  _ := matchcontinue(inItem, inEnv)
    local
      SCode.ClassDef cdef;
      NFSCodeEnv.Frame cls_env;
      Env env;
      SourceInfo info;
      SCode.Restriction res;
      SCode.Element cls;
      SCode.Comment cmt;

    // Check if the item is already marked as used, then we can stop here.
    case (_, _)
      equation
        true = NFSCodeEnv.isItemUsed(inItem);
      then
        ();

    // A component, mark it and it's environment as used.
    case (NFSCodeEnv.VAR(), env)
      equation
        markItemAsUsed(inItem, env);
      then
        ();

    // A basic type, nothing to be done.
    case (NFSCodeEnv.CLASS(classType = NFSCodeEnv.BASIC_TYPE()), _) then ();

    // A normal class, mark it and it's environment as used, and recursively
    // analyse its contents.
    case (NFSCodeEnv.CLASS(cls = cls as SCode.CLASS(classDef = cdef,
        restriction = res, info = info, cmt = cmt), env = {cls_env}), env)
      equation
        markItemAsUsed(inItem, env);
        env = NFSCodeEnv.enterFrame(cls_env, env);
        analyseClassDef(cdef, res, env, false, info);
        analyseMetaType(res, env, info);
        analyseComment(cmt, env, info);
        _ :: env = env;
        analyseRedeclaredClass(cls, env);
      then
        ();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFSCodeDependency.analyseItem failed on " +
          NFSCodeEnv.getItemName(inItem) + " in " +
          NFSCodeEnv.getEnvName(inEnv));
      then
        fail();

  end matchcontinue;
end analyseItem;

protected function analyseItemIfRedeclares
"Analyses an item again if there were some redeclares applied to the environment"
  input NFSCodeFlattenRedeclare.Replacements inRepls;
  input Item inItem;
  input Env inEnv;
algorithm
  _ := matchcontinue(inRepls, inItem, inEnv)
    local
      Item i;
      NFSCodeEnv.Frame cls_frm;
      Env env;
    // no replacements happened on the environemnt! do nothing
    case ({}, _,  _) then ();
    case (_, _, _)
      equation
        _::env = inEnv;
        //i = NFSCodeEnv.setItemEnv(inItem, {cls_frm});
        analyseItemNoStopOnUsed(inItem, env);
      then ();
  end matchcontinue;
end analyseItemIfRedeclares;

protected function analyseItemNoStopOnUsed
  "Analyses an item."
  input Item inItem;
  input Env inEnv;
algorithm
  _ := matchcontinue(inItem, inEnv)
    local
      SCode.ClassDef cdef;
      NFSCodeEnv.Frame cls_env;
      Env env;
      SourceInfo info;
      SCode.Restriction res;
      SCode.Element cls;
      SCode.Comment cmt;

    // A component, mark it and it's environment as used.
    case (NFSCodeEnv.VAR(), env)
      equation
        markItemAsUsed(inItem, env);
      then
        ();

    // A basic type, nothing to be done.
    case (NFSCodeEnv.CLASS(classType = NFSCodeEnv.BASIC_TYPE()), _) then ();

    // A normal class, mark it and it's environment as used, and recursively
    // analyse it's contents.
    case (NFSCodeEnv.CLASS(cls = cls as SCode.CLASS(classDef = cdef,
        restriction = res, info = info, cmt = cmt), env = {cls_env}), env)
      equation
        markItemAsUsed(inItem, env);
        env = NFSCodeEnv.enterFrame(cls_env, env);
        analyseClassDef(cdef, res, env, false, info);
        analyseMetaType(res, env, info);
        analyseComment(cmt, env, info);
        _ :: env = env;
        analyseRedeclaredClass(cls, env);
      then
        ();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFSCodeDependency.analyseItemNoStopOnUsed failed on " +
          NFSCodeEnv.getItemName(inItem) + " in " +
          NFSCodeEnv.getEnvName(inEnv));
      then
        fail();

  end matchcontinue;
end analyseItemNoStopOnUsed;

protected function markItemAsUsed
  "Marks an item and it's environment as used."
  input Item inItem;
  input Env inEnv;
algorithm
  _ := match(inItem, inEnv)
    local
      NFSCodeEnv.Frame cls_env;
      Util.StatefulBoolean is_used;
      String name;

    case (NFSCodeEnv.VAR(isUsed = SOME(is_used)), _)
      equation
        Util.setStatefulBoolean(is_used, true);
        markEnvAsUsed(inEnv);
      then
        ();

    case (NFSCodeEnv.VAR(isUsed = NONE()), _) then ();

    case (NFSCodeEnv.CLASS(env = {cls_env}, cls = SCode.CLASS()), _)
      equation
        markFrameAsUsed(cls_env);
        markEnvAsUsed(inEnv);
      then
        ();
  end match;
end markItemAsUsed;

protected function markFrameAsUsed
  "Marks a single frame as used."
  input NFSCodeEnv.Frame inFrame;
algorithm
  _ := match(inFrame)
    local
      Util.StatefulBoolean is_used;

    case NFSCodeEnv.FRAME(isUsed = SOME(is_used))
      equation
        Util.setStatefulBoolean(is_used, true);
      then
        ();

    else ();
  end match;
end markFrameAsUsed;

protected function markEnvAsUsed
  "Marks an environment as used. This is done by marking each frame as used, and
  for each frame we also analyse the class it represents to make sure we don't
  miss anything in the enclosing scopes of an item."
  input Env inEnv;
algorithm
  _ := matchcontinue(inEnv)
    local
      Util.StatefulBoolean is_used;
      Env rest_env;
      NFSCodeEnv.Frame f;

    case ((f as NFSCodeEnv.FRAME(isUsed = SOME(is_used))) :: rest_env)
      equation
        false = Util.getStatefulBoolean(is_used);
        markEnvAsUsed2(f, rest_env);
        Util.setStatefulBoolean(is_used, true);
        markEnvAsUsed(rest_env);
      then
        ();

    else ();
  end matchcontinue;
end markEnvAsUsed;

protected function markEnvAsUsed2
  "Helper function to markEnvAsUsed. Checks if the given frame belongs to a
  class, and if that's the case calls analyseClass on that class."
  input NFSCodeEnv.Frame inFrame;
  input NFSCodeEnv.Env inEnv;
algorithm
  _ := match(inFrame, inEnv)
    local
      String name;

    case (NFSCodeEnv.FRAME(frameType = NFSCodeEnv.IMPLICIT_SCOPE()), _) then ();

    case (NFSCodeEnv.FRAME(name = SOME(name)), _)
      equation
        analyseClass(Absyn.IDENT(name), inEnv, Absyn.dummyInfo);
      then
        ();
  end match;
end markEnvAsUsed2;

protected function analyseClassDef
  "Analyses the contents of a class definition."
  input SCode.ClassDef inClassDef;
  input SCode.Restriction inRestriction;
  input Env inEnv;
  input Boolean inInModifierScope;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inClassDef, inRestriction, inEnv, inInModifierScope, inInfo)
    local
      list<SCode.Element> el;
      Absyn.Ident bc;
      SCode.Mod mods;
      Absyn.TypeSpec ty;
      list<SCode.Equation> nel, iel;
      list<SCode.AlgorithmSection> nal, ial;
      SCode.Comment cmt;
      list<SCode.Annotation> annl;
      Option<SCode.ExternalDecl> ext_decl;
      Env ty_env, env, nore_env;
      Item ty_item;
      SCode.Attributes attr;
      list<Absyn.Path> paths;
      list<NFSCodeEnv.Redeclaration> redecls;
      NFSCodeFlattenRedeclare.Replacements repls;

    // A class made of parts, analyse elements, equation, algorithms, etc.
    case (SCode.PARTS(elementLst = el, normalEquationLst = nel,
        initialEquationLst = iel, normalAlgorithmLst = nal,
        initialAlgorithmLst = ial, externalDecl = ext_decl), _, _, _, _)
      equation
        analyseElements(el, inEnv, inRestriction);
        List.map1_0(nel, analyseEquation, inEnv);
        List.map1_0(iel, analyseEquation, inEnv);
        List.map1_0(nal, analyseAlgorithm, inEnv);
        List.map1_0(ial, analyseAlgorithm, inEnv);
        analyseExternalDecl(ext_decl, inEnv, inInfo);
      then
        ();

    // The previous case failed, which might happen for an external object.
    // Check if the class definition is an external object and analyse it if
    // that's the case.
    case (SCode.PARTS(elementLst = el), _, _, _, _)
      equation
        isExternalObject(el, inEnv, inInfo);
        analyseClass(Absyn.IDENT("constructor"), inEnv, inInfo);
        analyseClass(Absyn.IDENT("destructor"), inEnv, inInfo);
      then
        ();

    // A class extends.
    case (SCode.CLASS_EXTENDS(), _, _, _, _)
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR,
          {"NFSCodeDependency.analyseClassDef failed on CLASS_EXTENDS"}, inInfo);
      then
        fail();

    // A derived class definition.
    case (SCode.DERIVED(typeSpec = ty, modifications = mods),
        _, _ :: env, _, _)
      equation
        env = if inInModifierScope then inEnv else env;
        nore_env = NFSCodeEnv.removeRedeclaresFromLocalScope(env);
        analyseTypeSpec(ty, nore_env, inInfo);
        (ty_item, _, ty_env) = NFSCodeLookup.lookupTypeSpec(ty, env, inInfo);
        (ty_item, ty_env, _) = NFSCodeEnv.resolveRedeclaredItem(ty_item, ty_env);
        ty_env = NFSCodeEnv.mergeItemEnv(ty_item, ty_env);
        redecls = NFSCodeFlattenRedeclare.extractRedeclaresFromModifier(mods);
        (ty_item, ty_env, repls) =
        NFSCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redecls, ty_item, ty_env, inEnv, NFInstPrefix.emptyPrefix);
        analyseItemIfRedeclares(repls, ty_item, ty_env);
        analyseModifier(mods, inEnv, ty_env, inInfo);
      then
        ();

    // Other cases which doesn't need to be analysed.
    case (SCode.ENUMERATION(), _, _, _, _) then ();
    case (SCode.OVERLOAD(pathLst = paths), _, _, _, _)
      equation
        List.map2_0(paths,analyseClass,inEnv,inInfo);
      then ();
    case (SCode.PDER(), _, _, _, _) then ();

  end matchcontinue;
end analyseClassDef;

protected function isExternalObject
  "Checks if a class definition is an external object."
  input list<SCode.Element> inElements;
  input Env inEnv;
  input SourceInfo inInfo;
protected
  list<SCode.Element> el;
  list<String> el_names;
algorithm
  // Remove all 'extends ExternalObject'.
  el := List.filter(inElements, isNotExternalObject);
  // Check if length of the new list is different to the old, i.e. if we
  // actually found and removed any 'extends ExternalObject'.
  false := (listLength(el) == listLength(inElements));
  // Ok, we have an external object, check that it's valid.
  el_names := List.filterMap(el, elementName);
  checkExternalObject(el_names, inEnv, inInfo);
end isExternalObject;

protected function elementName
  input SCode.Element inElement;
  output String outString;
algorithm
  outString := match(inElement)
    local
      String name;
      Absyn.Path bc;

    case SCode.COMPONENT(name = name) then name;
    case SCode.CLASS(name = name) then name;
    case SCode.DEFINEUNIT(name = name) then name;

    case SCode.EXTENDS(baseClassPath = bc)
      equation
        name = Absyn.pathString(bc);
        name = "extends " + name;
      then
        name;

  end match;
end elementName;

protected function isNotExternalObject
  "Fails on 'extends ExternalObject', otherwise succeeds."
  input SCode.Element inElement;
algorithm
  _ := match(inElement)
    case SCode.EXTENDS(baseClassPath = Absyn.IDENT("ExternalObject")) then fail();
    else ();
  end match;
end isNotExternalObject;

protected function checkExternalObject
  "Checks that an external object is valid, i.e. has exactly one constructor and
  one destructor."
  input list<String> inElements;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := match(inElements, inEnv, inInfo)
    local
      String env_str;
      Boolean has_con, has_des;

    // Ok, we have both a constructor and a destructor.
    case ({"constructor", "destructor"}, _, _) then ();
    case ({"destructor", "constructor"}, _, _) then ();

    // Otherwise it's not valid, so print an error message.
    else
      equation
        has_con = List.isMemberOnTrue(
          "constructor", inElements, stringEqual);
        has_des = List.isMemberOnTrue(
          "destructor", inElements, stringEqual);
        env_str = NFSCodeEnv.getEnvName(inEnv);
        checkExternalObject2(inElements, has_con, has_des, env_str, inInfo);
      then
        fail();

  end match;
end checkExternalObject;

protected function checkExternalObject2
  "Helper function to checkExternalObject. Prints an error message depending on
  what the external object contained."
  input list<String> inElements;
  input Boolean inHasConstructor;
  input Boolean inHasDestructor;
  input String inObjectName;
  input SourceInfo inInfo;
algorithm
  _ := match(inElements, inHasConstructor, inHasDestructor, inObjectName, inInfo)
    local
      list<String> el;
      String el_str;

    // The external object contains both a constructor and a destructor, so it
    // has to also contain some invalid elements.
    case (el, true, true, _, _)
      equation
        // Remove the constructor and destructor from the list of elements.
        (el, _) = List.deleteMemberOnTrue("constructor", el, stringEqual);
        (el, _) = List.deleteMemberOnTrue("destructor", el, stringEqual);
        // Print an error message with the rest of the elements.
        el_str = stringDelimitList(el, ", ");
        el_str = "contains invalid elements: " + el_str;
        Error.addSourceMessage(Error.INVALID_EXTERNAL_OBJECT,
          {inObjectName, el_str}, inInfo);
      then
        ();

    // The external object is missing a constructor.
    case (_, false, true, _, _)
      equation
        Error.addSourceMessage(Error.INVALID_EXTERNAL_OBJECT,
          {inObjectName, "missing constructor"}, inInfo);
      then
        ();

    // The external object is missing a destructor.
    case (_, true, false, _, _)
      equation
        Error.addSourceMessage(Error.INVALID_EXTERNAL_OBJECT,
          {inObjectName, "missing destructor"}, inInfo);
      then
        ();

    // The external object is missing both a constructor and a destructor.
    case (_, false, false, _, _)
      equation
        Error.addSourceMessage(Error.INVALID_EXTERNAL_OBJECT,
          {inObjectName, "missing both constructor and destructor"}, inInfo);
      then
        ();
  end match;
end checkExternalObject2;

protected function analyseMetaType
  "If a metarecord is analysed we need to also analyse it's parent uniontype."
  input SCode.Restriction inRestriction;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := match(inRestriction, inEnv, inInfo)
    local
      Absyn.Path union_name;

    case (SCode.R_METARECORD(name = union_name), _, _)
      equation
        analyseClass(union_name, inEnv, inInfo);
      then
        ();

    else ();
  end match;
end analyseMetaType;

protected function analyseRedeclaredClass
  "If a class is a redeclaration of an inherited class we need to also analyse
  the inherited class."
  input SCode.Element inClass;
  input Env inEnv;
algorithm
  _ := matchcontinue(inClass, inEnv)
    local
      Item item;
      String name;

    case (SCode.CLASS(), _)
      equation
        false = SCode.isElementRedeclare(inClass);
      then ();

    case (SCode.CLASS(), _)
      equation
        item = NFSCodeEnv.CLASS(inClass, NFSCodeEnv.emptyEnv, NFSCodeEnv.USERDEFINED());
        analyseRedeclaredClass2(item, inEnv);
      then
        ();

  end matchcontinue;
end analyseRedeclaredClass;

protected function analyseRedeclaredClass2
  input Item inItem;
  input Env inEnv;
algorithm
  _ := matchcontinue(inItem, inEnv)
    local
      String name;
      Item item;
      Env env;
      SCode.Element cls;
      SourceInfo info;

    case (NFSCodeEnv.CLASS(cls=SCode.CLASS( info = info)), _)
      equation
        (item, env) = NFSCodeLookup.lookupRedeclaredClassByItem(inItem, inEnv, info);
        analyseItem(item, env);
      then
        ();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFSCodeDependency.analyseRedeclaredClass2 failed for " +
          NFSCodeEnv.getItemName(inItem) + " in " +
          NFSCodeEnv.getEnvName(inEnv));
      then
        fail();

  end matchcontinue;
end analyseRedeclaredClass2;

protected function analyseElements
  input list<SCode.Element> inElements;
  input Env inEnv;
  input SCode.Restriction inClassRestriction;
protected
  list<Extends> exts;
algorithm
  exts := NFSCodeEnv.getEnvExtendsFromTable(inEnv);
  analyseElements2(inElements, inEnv, exts, inClassRestriction);
end analyseElements;

protected function analyseElements2
  input list<SCode.Element> inElements;
  input Env inEnv;
  input list<Extends> inExtends;
  input SCode.Restriction inClassRestriction;
algorithm
  _ := match(inElements, inEnv, inExtends, inClassRestriction)
    local
      SCode.Element el;
      list<SCode.Element> rest_el;
      list<Extends> exts;

    case (el :: rest_el, _, _, _)
      equation
        exts = analyseElement(el, inEnv, inExtends, inClassRestriction);
        analyseElements2(rest_el, inEnv, exts, inClassRestriction);
      then
        ();

    case ({}, _, _, _) then ();

  end match;
end analyseElements2;

protected function analyseElement
  "Analyses an element."
  input SCode.Element inElement;
  input Env inEnv;
  input list<Extends> inExtends;
  input SCode.Restriction inClassRestriction;
  output list<Extends> outExtends;
algorithm
  outExtends := match(inElement, inEnv, inExtends, inClassRestriction)
    local
      Absyn.Path bc, bc2;
      SCode.Mod mods;
      Absyn.TypeSpec ty;
      SourceInfo info;
      SCode.Attributes attr;
      Option<Absyn.Exp> cond_exp;
      Item ty_item;
      Env ty_env;
      SCode.Ident name;
      SCode.Prefixes prefixes;
      SCode.Restriction res;
      String str;
      list<Extends> exts;
      list<NFSCodeEnv.Redeclaration> redecls;
      NFSCodeFlattenRedeclare.Replacements repls;

    // Fail on 'extends ExternalObject' so we can handle it as a special case in
    // analyseClassDef.
    case (SCode.EXTENDS(baseClassPath = Absyn.IDENT("ExternalObject")), _, _, _)
      then fail();

    // An extends-clause.
    case (SCode.EXTENDS(modifications = mods, info = info), _,
        NFSCodeEnv.EXTENDS(baseClass = bc) :: exts, _)
      equation
        //print("bc = " + Absyn.pathString(bc) + "\n");
        //print("bc2 = " + Absyn.pathString(bc2) + "\n");
        (ty_item, _, ty_env) =
          NFSCodeLookup.lookupBaseClassName(bc, inEnv, info);
        analyseExtends(bc, inEnv, info);
        ty_env = NFSCodeEnv.mergeItemEnv(ty_item, ty_env);
        analyseModifier(mods, inEnv, ty_env, info);
      then
        exts;

    // A component.
    case (SCode.COMPONENT(name = name, attributes = attr, typeSpec = ty,
        modifications = mods, condition = cond_exp, prefixes = prefixes, info = info), _, _, _)
      equation
        // *always* keep constants and parameters!
        // markAsUsedOnConstant(name, attr, inEnv, info);
        markAsUsedOnRestriction(name, inClassRestriction, inEnv, info);
        analyseAttributes(attr, inEnv, info);
        analyseTypeSpec(ty, inEnv, info);
        (ty_item, _, ty_env) = NFSCodeLookup.lookupTypeSpec(ty, inEnv, info);
        (ty_item, ty_env, _) = NFSCodeEnv.resolveRedeclaredItem(ty_item, ty_env);
        ty_env = NFSCodeEnv.mergeItemEnv(ty_item, ty_env);
        NFSCodeCheck.checkRecursiveComponentDeclaration(name, info, ty_env, ty_item, inEnv);
        redecls = NFSCodeFlattenRedeclare.extractRedeclaresFromModifier(mods);
        (ty_item, ty_env,_) =
        NFSCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redecls, ty_item, ty_env, inEnv, NFInstPrefix.emptyPrefix);
        // analyseItemIfRedeclares(repls, ty_item, ty_env);
        analyseModifier(mods, inEnv, ty_env, info);
        analyseOptExp(cond_exp, inEnv, info);
        analyseConstrainClass(SCode.replaceableOptConstraint(SCode.prefixesReplaceable(prefixes)), inEnv, info);
      then
        inExtends;

    //operators in operator record might be used later.
    case (SCode.CLASS(name = name, restriction=SCode.R_OPERATOR(), info = info), _, _, SCode.R_RECORD(true))
      equation
        analyseClass(Absyn.IDENT(name), inEnv, info);
      then
        inExtends;


    //operators in any other class type are error.
    case (SCode.CLASS(name = name, restriction=SCode.R_OPERATOR(), info = info), _, _, _)
      equation
        str = SCodeDump.restrString(inClassRestriction);
        Error.addSourceMessage(Error.OPERATOR_FUNCTION_NOT_EXPECTED, {name, str}, info);
      then fail();

    //operator functions in operator record might be used later.
    case (SCode.CLASS(name = name, restriction=SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION()), info = info), _, _, SCode.R_RECORD(true))
      equation
        analyseClass(Absyn.IDENT(name), inEnv, info);
      then
        inExtends;

     //operators functions in any other class type are error.
    case (SCode.CLASS(name = name, restriction=SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION()), info = info), _, _, _)
      equation
        str = SCodeDump.restrString(inClassRestriction);
        Error.addSourceMessage(Error.OPERATOR_FUNCTION_NOT_EXPECTED, {name, str}, info);
      then
        fail();

    //functions in operator might be used later.
    case (SCode.CLASS(name = name, restriction=res, info = info), _, _, SCode.R_OPERATOR())
      equation
        // Allowing external functions to be used operator functions
        true = SCode.isFunctionOrExtFunctionRestriction(res);
        analyseClass(Absyn.IDENT(name), inEnv, info);
      then
        inExtends;

    //operators should only contain function definitions
    case (SCode.CLASS(name = name, restriction = res, info = info), _, _, SCode.R_OPERATOR())
      equation
        false = SCode.isFunctionOrExtFunctionRestriction(res);
        str = SCodeDump.restrString(res);
        Error.addSourceMessage(Error.OPERATOR_FUNCTION_EXPECTED, {name, str}, info);
      then
        fail();

    // equalityConstraints may not be explicitly used but might be needed anyway
    // (if the record is used in a connect for example), so always mark it as used.
    case (SCode.CLASS(name = name as "equalityConstraint", info = info), _, _, _)
      equation
        analyseClass(Absyn.IDENT(name), inEnv, info);
      then
        inExtends;

    case (SCode.CLASS(name = name, info = info, classDef=SCode.CLASS_EXTENDS()), _, _, _)
      equation
        analyseClass(Absyn.IDENT(name), inEnv, info);
      then
        inExtends;

    // inner/innerouter classes may not be explicitly used but might be needed anyway
    case (SCode.CLASS(name = name, prefixes = SCode.PREFIXES(innerOuter = Absyn.INNER()), info = info), _, _, _)
      equation
        analyseClass(Absyn.IDENT(name), inEnv, info);
      then
        inExtends;

    // inner/innerouter classes may not be explicitly used but might be needed anyway
    case (SCode.CLASS(name = name, prefixes = SCode.PREFIXES(innerOuter = Absyn.INNER_OUTER()), info = info), _, _, _)
      equation
        analyseClass(Absyn.IDENT(name), inEnv, info);
      then
        inExtends;

    else inExtends;
  end match;
end analyseElement;

protected function markAsUsedOnConstant
  input SCode.Ident inName;
  input SCode.Attributes inAttr;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inName, inAttr, inEnv, inInfo)
    local
      NFSCodeEnv.AvlTree cls_and_vars;
      Util.StatefulBoolean is_used;
      SCode.Variability var;

    case (_, SCode.ATTR(variability = var), NFSCodeEnv.FRAME(clsAndVars = cls_and_vars) :: _, _)
      equation
        true = SCode.isParameterOrConst(var);
        NFSCodeEnv.VAR(isUsed = SOME(is_used)) =
          NFSCodeEnv.avlTreeGet(cls_and_vars, inName);
        Util.setStatefulBoolean(is_used, true);
      then
        ();

    else ();
  end matchcontinue;
end markAsUsedOnConstant;

protected function markAsUsedOnRestriction
  input SCode.Ident inName;
  input SCode.Restriction inRestriction;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inName, inRestriction, inEnv, inInfo)
    local
      NFSCodeEnv.AvlTree cls_and_vars;
      Util.StatefulBoolean is_used;

    case (_, _, NFSCodeEnv.FRAME(clsAndVars = cls_and_vars) :: _, _)
      equation
        true = markAsUsedOnRestriction2(inRestriction);
        NFSCodeEnv.VAR(isUsed = SOME(is_used)) =
          NFSCodeEnv.avlTreeGet(cls_and_vars, inName);
        Util.setStatefulBoolean(is_used, true);
      then
        ();

    else ();
  end matchcontinue;
end markAsUsedOnRestriction;

protected function markAsUsedOnRestriction2
  input SCode.Restriction inRestriction;
  output Boolean isRestricted;
algorithm
  isRestricted := match(inRestriction)
    case SCode.R_CONNECTOR() then true;
    case SCode.R_RECORD(_) then true;
    else false;
  end match;
end markAsUsedOnRestriction2;

protected function analyseExtends
  "Analyses an extends-clause."
  input Absyn.Path inClassName;
  input Env inEnv;
  input SourceInfo inInfo;
protected
  Item item;
  Env env;
algorithm
  (item, env) := lookupClass(inClassName, inEnv, true, inInfo, NONE());
  analyseItem(item, env);
end analyseExtends;

protected function analyseAttributes
  "Analyses a components attributes (actually only the array dimensions)."
  input SCode.Attributes inAttributes;
  input Env inEnv;
  input SourceInfo inInfo;
protected
  Absyn.ArrayDim ad;
algorithm
  SCode.ATTR(arrayDims = ad) := inAttributes;
  List.map2_0(ad, analyseSubscript, inEnv, inInfo);
end analyseAttributes;

protected function analyseModifier
  "Analyses a modifier."
  input SCode.Mod inModifier;
  input Env inEnv;
  input Env inTypeEnv;
  input SourceInfo inInfo;
algorithm
  _ := match(inModifier, inEnv, inTypeEnv, inInfo)
    local
      SCode.Element el;
      list<SCode.SubMod> sub_mods;
      Option<Absyn.Exp> bind_exp;

    // No modifier.
    case (SCode.NOMOD(), _, _, _) then ();

    // A normal modifier, analyse it's submodifiers and optional binding.
    case (SCode.MOD(subModLst = sub_mods, binding = bind_exp), _, _, _)
      equation
        List.map2_0(sub_mods, analyseSubMod, (inEnv, inTypeEnv), inInfo);
        analyseModBinding(bind_exp, inEnv, inInfo);
      then
        ();

    // A redeclaration modifier, analyse the redeclaration.
    case (SCode.REDECL(element = el), _, _, _)
      equation
        analyseRedeclareModifier(el, inEnv, inTypeEnv);
      then
        ();
  end match;
end analyseModifier;

protected function analyseRedeclareModifier
  "Analyses a redeclaration modifier element."
  input SCode.Element inElement;
  input Env inEnv;
  input Env inTypeEnv;
algorithm
  _ := matchcontinue(inElement, inEnv, inTypeEnv)
    local
      SCode.ClassDef cdef;
      SourceInfo info;
      SCode.Restriction restr;
      SCode.Prefixes prefixes;
      Absyn.TypeSpec ts;
      Item item;
      Env env;

    // call analyseClassDef
    case (SCode.CLASS(prefixes = prefixes, classDef = cdef,
        restriction = restr, info = info), _, _)
      equation
        analyseClassDef(cdef, restr, inEnv, true, info);
        analyseConstrainClass(SCode.replaceableOptConstraint(SCode.prefixesReplaceable(prefixes)), inEnv, info);
      then
        ();

    // Otherwise we can just use analyseElements.
    else
      equation
        _ = analyseElement(inElement, inEnv, {}, SCode.R_CLASS());
      then
        ();
  end matchcontinue;
end analyseRedeclareModifier;

protected function analyseConstrainClass
  "Analyses a constrain class, i.e. given by constrainedby."
  input Option<SCode.ConstrainClass> inCC;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := match(inCC, inEnv, inInfo)
    local
      Absyn.Path path;
      SCode.Mod mod;
      Env env;

    case (SOME(SCode.CONSTRAINCLASS(constrainingClass = path, modifier = mod)), _, _)
      equation
        analyseClass(path, inEnv, inInfo);
        (_, env) = lookupClass(path, inEnv, true, inInfo, SOME(Error.LOOKUP_ERROR));
        analyseModifier(mod, inEnv, env, inInfo);
      then
        ();

    else ();
  end match;
end analyseConstrainClass;

protected function analyseSubMod
  "Analyses a submodifier."
  input SCode.SubMod inSubMod;
  input tuple<Env, Env> inEnv;
  input SourceInfo inInfo;
algorithm
  _ := match(inSubMod, inEnv, inInfo)
    local
      SCode.Ident ident;
      SCode.Mod m;
      list<SCode.Subscript> subs;
      Env env,  ty_env;

    case (SCode.NAMEMOD(ident = ident, mod = m), (env, ty_env), _)
      equation
        analyseNameMod(ident, env, ty_env, m, inInfo);
      then
        ();

  end match;
end analyseSubMod;

protected function analyseNameMod
  input SCode.Ident inIdent;
  input Env inEnv;
  input Env inTypeEnv;
  input SCode.Mod inMod;
  input SourceInfo inInfo;
protected
  Option<Item> item;
  Option<Env> env;
algorithm
  (item, env) := lookupNameMod(Absyn.IDENT(inIdent), inTypeEnv, inInfo);
  analyseNameMod2(inIdent, item, env, inEnv, inTypeEnv, inMod, inInfo);
end analyseNameMod;

protected function analyseNameMod2
  input SCode.Ident inIdent;
  input Option<Item> inItem;
  input Option<Env> inItemEnv;
  input Env inEnv;
  input Env inTypeEnv;
  input SCode.Mod inModifier;
  input SourceInfo inInfo;
algorithm
  _ := match(inIdent, inItem, inItemEnv, inEnv, inTypeEnv, inModifier, inInfo)
    local
      Item item;
      Env env;

    case (_, SOME(item), SOME(env), _, _, _, _)
      equation
        NFSCodeCheck.checkModifierIfRedeclare(item, inModifier, inInfo);
        analyseItem(item, env);
        env = NFSCodeEnv.mergeItemEnv(item, env);
        analyseModifier(inModifier, inEnv, env, inInfo);
      then
        ();

    else
      equation
        analyseModifier(inModifier, inEnv, inTypeEnv, inInfo);
      then
        ();
  end match;
end analyseNameMod2;

protected function lookupNameMod
  input Absyn.Path inPath;
  input Env inEnv;
  input SourceInfo inInfo;
  output Option<Item> outItem;
  output Option<Env> outEnv;
algorithm
  (outItem, outEnv) := matchcontinue(inPath, inEnv, inInfo)
    local
      Item item;
      Env env;

    case (_, _, _)
      equation
        (item, _, env) = NFSCodeLookup.lookupNameSilent(inPath, inEnv, inInfo);
        (item, env, _) = NFSCodeEnv.resolveRedeclaredItem(item, env);
      then
        (SOME(item), SOME(env));

    else (NONE(), NONE());
  end matchcontinue;
end lookupNameMod;

protected function analyseSubscript
  "Analyses a subscript."
  input SCode.Subscript inSubscript;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := match(inSubscript, inEnv, inInfo)
    local
      Absyn.Exp sub_exp;

    case (Absyn.NOSUB(), _, _) then ();

    case (Absyn.SUBSCRIPT(sub_exp), _, _)
      equation
        analyseExp(sub_exp, inEnv, inInfo);
      then
        ();
  end match;
end analyseSubscript;

protected function analyseModBinding
  "Analyses an optional modifier binding."
  input Option<Absyn.Exp> inBinding;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := match inBinding
    local
      Absyn.Exp bind_exp;

    case NONE() then ();

    case SOME(bind_exp)
      equation
        analyseExp(bind_exp, inEnv, inInfo);
      then
        ();
  end match;
end analyseModBinding;

protected function analyseTypeSpec
  "Analyses a type specificer."
  input Absyn.TypeSpec inTypeSpec;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := match(inTypeSpec, inEnv, inInfo)
    local
      Absyn.Path type_path;
      list<Absyn.TypeSpec> tys;
      Option<Absyn.ArrayDim> ad;

    // A normal type.
    case (Absyn.TPATH(path = type_path, arrayDim = ad), _, _)
      equation
        analyseClass(type_path, inEnv, inInfo);
        analyseTypeSpecDims(ad, inEnv, inInfo);
      then
        ();

    // A polymorphic type, i.e. replaceable type Type subtypeof Any.
    case (Absyn.TCOMPLEX(path = Absyn.IDENT("polymorphic")), _, _)
      then ();

    // A MetaModelica type such as list or tuple.
    case (Absyn.TCOMPLEX(typeSpecs = tys), _, _)
      equation
        List.map2_0(tys, analyseTypeSpec, inEnv, inInfo);
      then
        ();

  end match;
end analyseTypeSpec;

protected function analyseTypeSpecDims
  input Option<Absyn.ArrayDim> inDims;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := match(inDims, inEnv, inInfo)
    local
      Absyn.ArrayDim dims;

    case (SOME(dims), _, _)
      equation
        List.map2_0(dims, analyseTypeSpecDim, inEnv, inInfo);
      then
        ();

    else ();
  end match;
end analyseTypeSpecDims;

protected function analyseTypeSpecDim
  input Absyn.Subscript inDim;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := match(inDim, inEnv, inInfo)
    local
      Absyn.Exp dim;

    case (Absyn.NOSUB(), _, _) then ();

    case (Absyn.SUBSCRIPT(subscript = dim), _, _)
      equation
        analyseExp(dim, inEnv, inInfo);
      then
        ();

  end match;
end analyseTypeSpecDim;

protected function analyseExternalDecl
  "Analyses an external declaration."
  input Option<SCode.ExternalDecl> inExtDecl;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := match(inExtDecl, inEnv, inInfo)
    local
      SCode.Annotation ann;
      list<Absyn.Exp> args;

    // An external declaration might have arguments that we need to analyse.
    case (SOME(SCode.EXTERNALDECL(args = args, annotation_ = NONE())), _, _)
      equation
        List.map2_0(args, analyseExp, inEnv, inInfo);
      then
        ();

    // An external declaration might have arguments and an annotation that we need to analyse.
    case (SOME(SCode.EXTERNALDECL(args = args, annotation_ = SOME(ann))), _, _)
      equation
        List.map2_0(args, analyseExp, inEnv, inInfo);
        analyseAnnotation(ann, inEnv, inInfo);
      then
        ();

    else ();
  end match;
end analyseExternalDecl;

protected function analyseComment
  "Analyses an optional comment."
  input SCode.Comment inComment;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := match(inComment, inEnv, inInfo)
    local
      SCode.Annotation ann;

    // A comment might have an annotation that we need to analyse.
    case (SCode.COMMENT(annotation_ = SOME(ann)), _, _)
      equation
        analyseAnnotation(ann, inEnv, inInfo);
      then
        ();

    else ();
  end match;
end analyseComment;

protected function analyseAnnotation
  "Analyses an annotation."
  input SCode.Annotation inAnnotation;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := match(inAnnotation, inEnv, inInfo)
    local
      SCode.Mod mods;
      list<SCode.SubMod> sub_mods;

    case (SCode.ANNOTATION(modification = SCode.MOD(subModLst = sub_mods)),
        _, _)
      equation
        List.map2_0(sub_mods, analyseAnnotationMod, inEnv, inInfo);
      then
        ();

  end match;
end analyseAnnotation;

protected function analyseAnnotationMod
  "Analyses an annotation modifier."
  input SCode.SubMod inMod;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inMod, inEnv, inInfo)
    local
      SCode.Mod mods;
      String id;

    // derivative is a bit special since it's not a builtin function, so just
    // analyse it's modifier to make sure that we get the derivation function.
    case (SCode.NAMEMOD(ident = "derivative", mod = mods), _, _)
      equation
        analyseModifier(mods, inEnv, NFSCodeEnv.emptyEnv, inInfo);
      then
        ();

    // Otherwise, try to analyse the modifier name, and if that succeeds also
    // try and analyse the rest of the modification. This is needed for example
    // for the graphical annotations such as Icon.
    case (SCode.NAMEMOD(ident = id, mod = mods), _, _)
      equation
        analyseAnnotationName(id, inEnv, inInfo);
        analyseModifier(mods, inEnv, NFSCodeEnv.emptyEnv, inInfo);
      then
        ();

    else ();
  end matchcontinue;
end analyseAnnotationMod;

protected function analyseAnnotationName
  "Analyses an annotation name, such as Icon or Line."
  input SCode.Ident inName;
  input Env inEnv;
  input SourceInfo inInfo;
protected
  Item item;
  Env env;
algorithm
  (item, _, env) :=
    NFSCodeLookup.lookupNameSilent(Absyn.IDENT(inName), inEnv, inInfo);
  (item, env, _) := NFSCodeEnv.resolveRedeclaredItem(item, env);
  analyseItem(item, env);
end analyseAnnotationName;

protected function analyseExp
  "Recursively analyses an expression."
  input Absyn.Exp inExp;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  (_, _) := Absyn.traverseExpBidir(inExp, analyseExpTraverserEnter, analyseExpTraverserExit, (inEnv, inInfo));
end analyseExp;

protected function analyseOptExp
  "Recursively analyses an optional expression."
  input Option<Absyn.Exp> inExp;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := match(inExp, inEnv, inInfo)
    local
      Absyn.Exp exp;

    case (SOME(exp), _, _)
      equation
        analyseExp(exp, inEnv, inInfo);
      then
        ();

    else ();
  end match;
end analyseOptExp;

protected function analyseExpTraverserEnter
  "Traversal enter function for use in analyseExp."
  input Absyn.Exp inExp;
  input tuple<Env, SourceInfo> inTuple;
  output Absyn.Exp outExp;
  output tuple<Env, SourceInfo> outTuple;
protected
  Env env;
  SourceInfo info;
algorithm
  (env, info) := inTuple;
  env := analyseExp2(inExp, env, info);
  outExp := inExp;
  outTuple := (env, info);
end analyseExpTraverserEnter;

protected function analyseExp2
  "Helper function to analyseExp, does the actual work."
  input Absyn.Exp inExp;
  input Env inEnv;
  input SourceInfo inInfo;
  output Env outEnv;
algorithm
  outEnv := match(inExp, inEnv, inInfo)
    local
      Absyn.ComponentRef cref;
      Absyn.FunctionArgs args;
      Absyn.ForIterators iters;
      Env env;

    case (Absyn.CREF(componentRef = cref), _, _)
      equation
        analyseCref(cref, inEnv, inInfo);
      then
        inEnv;

    case (Absyn.CALL(function_ = cref, functionArgs = Absyn.FOR_ITER_FARG(iterators = iters)), _, _)
      equation
        analyseCref(cref, inEnv, inInfo); // For user-defined reductions
        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
      then
        env;

    case (Absyn.CALL(function_ = cref), _, _)
      equation
        analyseCref(cref, inEnv, inInfo);
      then
        inEnv;

    case (Absyn.PARTEVALFUNCTION(function_ = cref), _, _)
      equation
        analyseCref(cref, inEnv, inInfo);
      then
        inEnv;

    case (Absyn.MATCHEXP(), _, _)
      equation
        env = NFSCodeEnv.extendEnvWithMatch(inExp, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
      then
        env;

    else inEnv;
  end match;
end analyseExp2;

protected function analyseCref
  "Analyses a component reference."
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inCref, inEnv, inInfo)
    local
      Absyn.Path path;
      Item item;
      Env env;

    case (Absyn.WILD(), _, _) then ();

    case (_, _, _)
      equation
        // We want to use lookupClass since we need the item and environment, and
        // we don't care about any subscripts, so convert the cref to a path.
        path = Absyn.crefToPathIgnoreSubs(inCref);
        (item, env) = lookupClass(path, inEnv, true, inInfo, NONE());
        analyseItem(item, env);
      then
        ();

    else ();

  end matchcontinue;
end analyseCref;

protected function analyseExpTraverserExit
  "Traversal exit function for use in analyseExp."
  input Absyn.Exp inExp;
  input tuple<Env, SourceInfo> inTuple;
  output Absyn.Exp outExp;
  output tuple<Env, SourceInfo> outTuple;
algorithm
  (outExp,outTuple) := match(inExp,inTuple)
    local
      Absyn.Exp e;
      Env env;
      SourceInfo info;

    // Remove any scopes added by the enter function.

    case (Absyn.CALL(functionArgs = Absyn.FOR_ITER_FARG()),(NFSCodeEnv.FRAME(frameType = NFSCodeEnv.IMPLICIT_SCOPE()) :: env, info))
      then
        (inExp, (env, info));

    case (Absyn.MATCHEXP(),(NFSCodeEnv.FRAME(frameType = NFSCodeEnv.IMPLICIT_SCOPE()) :: env, info))
      then
        (inExp, (env, info));

    else (inExp, inTuple);
  end match;
end analyseExpTraverserExit;

protected function analyseEquation
  "Analyses an equation."
  input SCode.Equation inEquation;
  input Env inEnv;
protected
  SCode.EEquation equ;
algorithm
  SCode.EQUATION(equ) := inEquation;
  (_, _) := SCode.traverseEEquations(equ, (analyseEEquationTraverser, inEnv));
end analyseEquation;

protected function analyseEEquationTraverser
  "Traversal function for use in analyseEquation."
  input tuple<SCode.EEquation, Env> inTuple;
  output tuple<SCode.EEquation, Env> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      SCode.EEquation equ;
      SCode.Ident iter_name;
      Env env;
      SourceInfo info;
      Absyn.ComponentRef cref1;

    case ((equ as SCode.EQ_FOR(index = iter_name, info = info), env))
      equation
        env = NFSCodeEnv.extendEnvWithIterators({Absyn.ITERATOR(iter_name, NONE(), NONE())}, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), env);
        (equ, _) = SCode.traverseEEquationExps(equ, traverseExp, (env, info));
      then
        ((equ, env));

    case ((equ as SCode.EQ_REINIT(cref = cref1, info = info), env))
      equation
        analyseCref(cref1, env, info);
        (equ, _) = SCode.traverseEEquationExps(equ, traverseExp, (env, info));
      then
        ((equ, env));

    case ((equ, env))
      equation
        info = SCode.getEEquationInfo(equ);
        (equ, _) = SCode.traverseEEquationExps(equ, traverseExp, (env, info));
      then
        ((equ, env));

  end match;
end analyseEEquationTraverser;

protected function traverseExp
  "Traversal function used by analyseEEquationTraverser and
  analyseStatementTraverser."
  input Absyn.Exp inExp;
  input tuple<Env, SourceInfo> inTuple;
  output Absyn.Exp outExp;
  output tuple<Env, SourceInfo> outTuple;
algorithm
  (outExp, outTuple) := Absyn.traverseExpBidir(inExp, analyseExpTraverserEnter, analyseExpTraverserExit, inTuple);
end traverseExp;

protected function analyseAlgorithm
  "Analyses an algorithm."
  input SCode.AlgorithmSection inAlgorithm;
  input Env inEnv;
protected
  list<SCode.Statement> stmts;
algorithm
  SCode.ALGORITHM(stmts) := inAlgorithm;
  List.map1_0(stmts, analyseStatement, inEnv);
end analyseAlgorithm;

protected function analyseStatement
  "Analyses a statement in an algorithm."
  input SCode.Statement inStatement;
  input Env inEnv;
algorithm
  (_, _) := SCode.traverseStatements(inStatement,
    (analyseStatementTraverser, inEnv));
end analyseStatement;

protected function analyseStatementTraverser
  "Traversal function used by analyseStatement."
  input tuple<SCode.Statement, Env> inTuple;
  output tuple<SCode.Statement, Env> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      Env env;
      SCode.Statement stmt;
      SourceInfo info;
      list<SCode.Statement> parforBody;
      String iter_name;

    case ((stmt as SCode.ALG_FOR(index = iter_name, info = info), env))
      equation
        env = NFSCodeEnv.extendEnvWithIterators({Absyn.ITERATOR(iter_name, NONE(), NONE())}, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), env);
        (_, _) = SCode.traverseStatementExps(stmt, traverseExp, (env, info));
      then
        ((stmt, env));

     case ((stmt as SCode.ALG_PARFOR(index = iter_name,  info = info), env))
      equation
        env = NFSCodeEnv.extendEnvWithIterators({Absyn.ITERATOR(iter_name, NONE(), NONE())}, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), env);
        (_, _) = SCode.traverseStatementExps(stmt, traverseExp, (env, info));
      then
        ((stmt, env));

    case ((stmt, env))
      equation
        info = SCode.getStatementInfo(stmt);
        (_, _) = SCode.traverseStatementExps(stmt, traverseExp, (env, info));
      then
        ((stmt, env));

  end match;
end analyseStatementTraverser;

protected function analyseClassExtends
  "Goes through the environment and checks if class extends are used or not.
  This is done since class extends are sometimes implicitly used (see for
  example the test case mofiles/ClassExtends3.mo), so only going through the
  first phase of the dependency analysis is not enough to find all class extends
  that are used. Adding all class extends would also be problematic, since we
  would have to make sure that any class extend and it's dependencies are marked
  as used.

  This phase goes through all used classes, and if it finds a class extends in
  one of them it sets the use flag to the same as the base class. This is not a
  perfect solution since it means that all class extends that extend a certain
  base class will be marked as used, even if only one of them actually use the
  base class. So we might get some extra dependencies that are actually not
  used, but it's still better then marking all class extends in the program as
  used."
  input Env inEnv;
protected
  NFSCodeEnv.AvlTree tree;
algorithm
  NFSCodeEnv.FRAME(clsAndVars = tree) :: _ := inEnv;
  analyseAvlTree(SOME(tree), inEnv);
end analyseClassExtends;

protected function analyseAvlTree
  "Helper function to analyseClassExtends. Goes through the nodes in an
  AvlTree."
  input Option<NFSCodeEnv.AvlTree> inTree;
  input Env inEnv;
algorithm
  _ := match(inTree, inEnv)
    local
      Option<NFSCodeEnv.AvlTree> left, right;
      NFSCodeEnv.AvlTreeValue value;

    case (NONE(), _) then ();
    case (SOME(NFSCodeEnv.AVLTREENODE(value = NONE())), _) then ();
    case (SOME(NFSCodeEnv.AVLTREENODE(value = SOME(value), left = left, right = right)), _)
      equation
        analyseAvlTree(left, inEnv);
        analyseAvlTree(right, inEnv);
        analyseAvlValue(value, inEnv);
      then
        ();

  end match;
end analyseAvlTree;

protected function analyseAvlValue
  "Helper function to analyseClassExtends. Analyses a value in the AvlTree."
  input NFSCodeEnv.AvlTreeValue inValue;
  input Env inEnv;
algorithm
  _ := matchcontinue(inValue, inEnv)
    local
      String key_str;
      NFSCodeEnv.Frame cls_env;
      Env env;
      SCode.Element cls;
      NFSCodeEnv.ClassType cls_ty;
      Util.StatefulBoolean is_used;

    // Check if the current environment is not used, we can quit here if that's
    // the case.
    case (_, NFSCodeEnv.FRAME(name = SOME(_), isUsed = SOME(is_used)) :: _)
      equation
        false = Util.getStatefulBoolean(is_used);
      then
        ();

    case (NFSCodeEnv.AVLTREEVALUE(value = NFSCodeEnv.CLASS(cls = cls,
        env = {cls_env}, classType = cls_ty)), _)
      equation
        env = NFSCodeEnv.enterFrame(cls_env, inEnv);
        analyseClassExtendsDef(cls, cls_ty, env);
        // Check all classes inside of this class too.
        analyseClassExtends(env);
      then
        ();

    else ();
  end matchcontinue;
end analyseAvlValue;

protected function analyseClassExtendsDef
  "Analyses a class extends definition."
  input SCode.Element inClass;
  input NFSCodeEnv.ClassType inClassType;
  input Env inEnv;
algorithm
  _ := matchcontinue(inClass, inClassType, inEnv)
    local
      Item item;
      SourceInfo info;
      Absyn.Path bc;
      String cls_name;
      Env env;

    case (SCode.CLASS(name = cls_name, classDef =
          SCode.PARTS(elementLst = SCode.EXTENDS(baseClassPath = bc) :: _),
          info = info), NFSCodeEnv.CLASS_EXTENDS(), _)
      equation
        // Look up the base class of the class extends, and check if it's used.
        (item, _, env) = NFSCodeLookup.lookupBaseClassName(bc, inEnv, info);
        true = NFSCodeEnv.isItemUsed(item);
        // Ok, the base is used, analyse the class extends to mark it and it's
        // dependencies as used.
        _ :: env = inEnv;
        analyseClass(Absyn.IDENT(cls_name), env, info);
      then
        ();

    case (SCode.CLASS(name = cls_name, info = info), NFSCodeEnv.USERDEFINED(), _)
      equation
        true = SCode.isElementRedeclare(inClass);
        _ :: env = inEnv;
        item = NFSCodeEnv.CLASS(inClass, NFSCodeEnv.emptyEnv, inClassType);
        (item, _) = NFSCodeLookup.lookupRedeclaredClassByItem(item, env, info);
        true = NFSCodeEnv.isItemUsed(item);
        analyseClass(Absyn.IDENT(cls_name), env, info);
      then
        ();

    else ();

  end matchcontinue;
end analyseClassExtendsDef;

protected function collectUsedProgram
  "Entry point for the second phase in the dependency analysis. Goes through the
   environment and collects the used elements in a new program and environment.
   Also returns a list of all global constants."
  input Env inEnv;
  input SCode.Program inProgram;
  input Absyn.Path inClassName;
  output Env outEnv;
  output SCode.Program outProgram;
protected
  Env env;
  NFSCodeEnv.AvlTree cls_and_vars;
algorithm
  env := NFSCodeEnv.buildInitialEnv();
  NFSCodeEnv.FRAME(clsAndVars = cls_and_vars) :: _ := inEnv;
  (outProgram, outEnv) :=
    collectUsedProgram2(cls_and_vars, inEnv, inProgram, inClassName, env);
end collectUsedProgram;

protected function collectUsedProgram2
  "Helper function to collectUsedProgram2. Goes through each top-level class in
  the program and collects them if they are used. This is to preserve the order
  of the classes in the new program. Another alternative would have been to just
  traverse the environment and collect the used classes, which would have been a
  bit faster but would not have preserved the order of the program."
  input NFSCodeEnv.AvlTree clsAndVars;
  input Env inEnv;
  input SCode.Program inProgram;
  input Absyn.Path inClassName;
  input Env inAccumEnv;
  output SCode.Program outProgram;
  output Env outAccumEnv;
algorithm
  (outProgram, outAccumEnv) :=
  matchcontinue(clsAndVars, inEnv, inProgram, inClassName, inAccumEnv)
    local
      SCode.Element cls_el;
      SCode.Element cls;
      SCode.Program rest_prog;
      String name;
      Env env;

    // We're done!
    case (_, _, {}, _, _) then (inProgram, inAccumEnv);

    // Try to collect the first class in the list.
    case (_, _, (cls as SCode.CLASS(name = name)) :: rest_prog, _, env)
      equation
        (cls_el as SCode.CLASS(), env) = collectUsedClass(cls, inEnv, clsAndVars,
          inClassName, env, Absyn.IDENT(name));
        (rest_prog, env) =
          collectUsedProgram2(clsAndVars, inEnv, rest_prog, inClassName, env);
      then
        (cls_el :: rest_prog, env);

    // Could not collect the class (i.e. it's not used), continue with the rest.
    case (_, _, _ :: rest_prog, _, env)
      equation
        (rest_prog, env) =
          collectUsedProgram2(clsAndVars, inEnv, rest_prog, inClassName, env);
      then
        (rest_prog, env);

  end matchcontinue;
end collectUsedProgram2;

protected function collectUsedClass
  "Checks if the given class is used in the program, and if that's the case it
  adds the class to the accumulated environment. Otherwise it just fails."
  input SCode.Element inClass;
  input Env inEnv;
  input NFSCodeEnv.AvlTree inClsAndVars;
  input Absyn.Path inClassName;
  input Env inAccumEnv;
  input Absyn.Path inAccumPath;
  output SCode.Element outClass;
  output Env outAccumEnv;
algorithm
  (outClass, outAccumEnv) :=
  match(inClass, inEnv, inClsAndVars, inClassName, inAccumEnv, inAccumPath)
    local
      SCode.Ident name, basename;
      SCode.Prefixes prefixes;
      SCode.Restriction res;
      SCode.ClassDef cdef;
      SCode.Encapsulated ep;
      SCode.Partial pp;
      SourceInfo info;
      Item item, resolved_item;
      NFSCodeEnv.Frame class_frame;
      Env class_env, env, enclosing_env;
      Option<SCode.ConstrainClass> cc;
      SCode.Element cls;
      SCode.Comment cmt;

    case (SCode.CLASS(name, prefixes as SCode.PREFIXES(replaceablePrefix =
        SCode.REPLACEABLE(_)), ep, pp, res, cdef, cmt, info), _, _, _, _, _)
      equation
        /*********************************************************************/
        // TODO: Fix the usage of alias items in this case.
        /*********************************************************************/
        // Check if the class is used.
        item = NFSCodeEnv.avlTreeGet(inClsAndVars, name);
        (resolved_item, _) = NFSCodeLookup.resolveAlias(item, inEnv);
        true = checkClassUsed(resolved_item, cdef);
        // The class is used, recursively collect its contents.
        {class_frame} = NFSCodeEnv.getItemEnv(resolved_item);
        enclosing_env = NFSCodeEnv.enterScope(inEnv, name);
        (cdef, class_env) =
          collectUsedClassDef(cdef, enclosing_env, class_frame, inClassName, inAccumPath);

        cls = SCode.CLASS(name, prefixes, ep, pp, res, cdef, cmt, info);
        resolved_item = updateItemEnv(resolved_item, cls, class_env);
        basename = name + NFSCodeEnv.BASE_CLASS_SUFFIX;
        env = NFSCodeEnv.extendEnvWithItem(resolved_item, inAccumEnv, basename);
        env = NFSCodeEnv.extendEnvWithItem(item, env, name);
      then
        (cls, env);

    case (SCode.CLASS(name, prefixes, ep, pp, res, cdef, cmt, info), _, _, _, _, _)
      equation
        // TODO! FIXME! add cc to the used classes!
        _ = SCode.replaceableOptConstraint(SCode.prefixesReplaceable(prefixes));
        // Check if the class is used.
        item = NFSCodeEnv.avlTreeGet(inClsAndVars, name);
        true = checkClassUsed(item, cdef);
        // The class is used, recursively collect it's contents.
        {class_frame} = NFSCodeEnv.getItemEnv(item);
        enclosing_env = NFSCodeEnv.enterScope(inEnv, name);
        (cdef, class_env) =
          collectUsedClassDef(cdef, enclosing_env, class_frame, inClassName, inAccumPath);
        // Add the class to the new environment.
        cls = SCode.CLASS(name, prefixes, ep, pp, res, cdef, cmt, info);
        item = updateItemEnv(item, cls, class_env);
        env = NFSCodeEnv.extendEnvWithItem(item, inAccumEnv, name);
      then
        (cls, env);

  end match;
end collectUsedClass;

protected function checkClassUsed
  "Given the environment item and definition for a class, returns whether the
  class is used or not."
  input Item inItem;
  input SCode.ClassDef inClassDef;
  output Boolean isUsed;
algorithm
  isUsed := match(inItem, inClassDef)
    // GraphicalAnnotationsProgram____ is a special case, since it's not used by
    // anything, but needed during instantiation.
    case (NFSCodeEnv.CLASS(cls = SCode.CLASS(name = "GraphicalAnnotationsProgram____")), _)
      then true;
    // Otherwise, use the environment item to determine if the class is used or
    // not.
    else NFSCodeEnv.isItemUsed(inItem);
  end match;
end checkClassUsed;

protected function updateItemEnv
  "Replaces the class and environment in an environment item, preserving the
  item's type."
  input Item inItem;
  input SCode.Element inClass;
  input Env inEnv;
  output Item outItem;
algorithm
  outItem := match(inItem, inClass, inEnv)
    local
      NFSCodeEnv.ClassType cls_ty;

    case (NFSCodeEnv.CLASS(classType = cls_ty), _, _)
      then NFSCodeEnv.CLASS(inClass, inEnv, cls_ty);

  end match;
end updateItemEnv;

protected function collectUsedClassDef
  "Collects the contents of a class definition."
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  input NFSCodeEnv.Frame inClassEnv;
  input Absyn.Path inClassName;
  input Absyn.Path inAccumPath;
  output SCode.ClassDef outClass;
  output Env outEnv;
algorithm
  (outClass, outEnv) :=
  match(inClassDef, inEnv, inClassEnv, inClassName, inAccumPath)
    local
      list<SCode.Element> el;
      list<SCode.Equation> neq, ieq;
      list<SCode.AlgorithmSection> nal, ial;
      list<SCode.ConstraintSection> nco;
      Option<SCode.ExternalDecl> ext_decl;
      list<SCode.Annotation> annl;
      Option<SCode.Comment> cmt;
      SCode.Ident bc;
      SCode.Mod mods;
      Env env;
      list<Absyn.NamedArg> clats;

    case (SCode.PARTS(el, neq, ieq, nal, ial, nco, clats, ext_decl), _, _, _, _)
      equation
        (el, env) =
          collectUsedElements(el, inEnv, inClassEnv, inClassName, inAccumPath);
      then
        (SCode.PARTS(el, neq, ieq, nal, ial, nco, clats, ext_decl), env);

    case (SCode.CLASS_EXTENDS(bc, mods,
        SCode.PARTS(el, neq, ieq, nal, ial, nco, clats, ext_decl)), _, _, _, _)
      equation
        (el, env) =
          collectUsedElements(el, inEnv, inClassEnv, inClassName, inAccumPath);
      then
        (SCode.CLASS_EXTENDS(bc, mods,
          SCode.PARTS(el, neq, ieq, nal, ial, nco, clats, ext_decl)), env);

    case (SCode.ENUMERATION(), _, _, _, _)
      then (inClassDef, {inClassEnv});

    else (inClassDef, {inClassEnv});
  end match;
end collectUsedClassDef;

protected function collectUsedElements
  "Collects a class definition's elements."
  input list<SCode.Element> inElements;
  input Env inEnv;
  input NFSCodeEnv.Frame inClassEnv;
  input Absyn.Path inClassName;
  input Absyn.Path inAccumPath;
  output list<SCode.Element> outUsedElements;
  output Env outNewEnv;
protected
  NFSCodeEnv.Frame empty_class_env;
  NFSCodeEnv.AvlTree cls_and_vars;
  Boolean collect_constants;
algorithm
  // Create a new class environment that preserves the imports and extends.
  (empty_class_env, cls_and_vars) :=
    NFSCodeEnv.removeClsAndVarsFromFrame(inClassEnv);
  // Collect all constants in the top class, even if they're not used.
  // This makes it easier to write test cases.
  collect_constants := Absyn.pathEqual(inClassName, inAccumPath);
  (outUsedElements, outNewEnv) :=
    collectUsedElements2(inElements, inEnv, cls_and_vars, {}, {empty_class_env},
      inClassName, inAccumPath, collect_constants);
  outNewEnv := removeUnusedRedeclares(outNewEnv, inEnv);
end collectUsedElements;

protected function collectUsedElements2
  "Helper function to collectUsedElements2. Goes through the given list of
  elements and tries to collect them."
  input list<SCode.Element> inElements;
  input Env inEnclosingEnv;
  input NFSCodeEnv.AvlTree inClsAndVars;
  input list<SCode.Element> inAccumElements;
  input Env inAccumEnv;
  input Absyn.Path inClassName;
  input Absyn.Path inAccumPath;
  input Boolean inCollectConstants;
  output list<SCode.Element> outAccumElements = {};
  output Env accum_env = inAccumEnv;
protected
  SCode.Element accum_el;
algorithm
  for el in inElements loop
    try
      (accum_el, accum_env) := collectUsedElement(el, inEnclosingEnv, inClsAndVars, accum_env, inClassName, inAccumPath, inCollectConstants);
      outAccumElements := accum_el::outAccumElements;
    else
      // Skip this element
    end try;
  end for;
  outAccumElements := listReverse(outAccumElements);
end collectUsedElements2;

protected function collectUsedElement
  "Collects a class element."
  input SCode.Element inElement;
  input Env inEnclosingEnv;
  input NFSCodeEnv.AvlTree inClsAndVars;
  input Env inAccumEnv;
  input Absyn.Path inClassName;
  input Absyn.Path inAccumPath;
  input Boolean inCollectConstants;
  output SCode.Element outElement;
  output Env outAccumEnv;
algorithm
  (outElement, outAccumEnv) :=
  match(inElement, inEnclosingEnv, inClsAndVars, inAccumEnv, inClassName,
      inAccumPath, inCollectConstants)
    local
      SCode.Ident name;
      SCode.Element cls;
      Env env;
      Item item;
      Absyn.Path cls_path;

    // A class definition, just use collectUsedClass.
    case (SCode.CLASS(name = name), _, _, env, _, _, _)
      equation
        cls_path = Absyn.joinPaths(inAccumPath, Absyn.IDENT(name));
        (cls, env) =
          collectUsedClass(inElement, inEnclosingEnv, inClsAndVars,
            inClassName,env, cls_path);
      then
        (cls, env);

    // A constant.
    case (SCode.COMPONENT(name = name,
      attributes = SCode.ATTR(variability = SCode.CONST())), _, _, _, _, _, _)
      equation
        item = NFSCodeEnv.avlTreeGet(inClsAndVars, name);
        true = inCollectConstants or NFSCodeEnv.isItemUsed(item);
        env = NFSCodeEnv.extendEnvWithItem(item, inAccumEnv, name);
      then
        (inElement, env);

    // Class components are always collected, regardless of whether they are
    // used or not.
    case (SCode.COMPONENT(name = name), _, _, _, _, _, _)
      equation
        item = NFSCodeEnv.newVarItem(inElement, true);
        env = NFSCodeEnv.extendEnvWithItem(item, inAccumEnv, name);
      then
        (inElement, env);

    else (inElement, inAccumEnv);

  end match;
end collectUsedElement;

protected function removeUnusedRedeclares
  "An unused element might be redeclared, but it's still not actually used. This
   function removes such redeclares from extends clauses, so that it's safe to
   remove those elements."
  input Env inEnv;
  input Env inTotalEnv;
  output Env outEnv;
protected
  Option<String> name;
  NFSCodeEnv.FrameType ty;
  NFSCodeEnv.AvlTree cls_and_vars;
  list<NFSCodeEnv.Extends> bcl;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
  NFSCodeEnv.ImportTable imps;
  Option<Util.StatefulBoolean> is_used;
  Env env;
algorithm
  {NFSCodeEnv.FRAME(name, ty, cls_and_vars, NFSCodeEnv.EXTENDS_TABLE(bcl, re, cei),
    imps, is_used)} := inEnv;
  env := NFSCodeEnv.removeRedeclaresFromLocalScope(inTotalEnv);
  bcl := List.map1(bcl, removeUnusedRedeclares2, env);
  outEnv := {NFSCodeEnv.FRAME(name, ty, cls_and_vars,
    NFSCodeEnv.EXTENDS_TABLE(bcl, re, cei), imps, is_used)};
end removeUnusedRedeclares;

protected function removeUnusedRedeclares2
  input NFSCodeEnv.Extends inExtends;
  input Env inEnv;
  output NFSCodeEnv.Extends outExtends;
protected
  Absyn.Path bc;
  list<NFSCodeEnv.Redeclaration> redeclares;
  Integer index;
  SourceInfo info;
  Env env;
algorithm
  NFSCodeEnv.EXTENDS(bc, redeclares, index, info) := inExtends;
  redeclares := List.filter1(redeclares, removeUnusedRedeclares3, inEnv);
  outExtends := NFSCodeEnv.EXTENDS(bc, redeclares, index, info);
end removeUnusedRedeclares2;

protected function removeUnusedRedeclares3
  input NFSCodeEnv.Redeclaration inRedeclare;
  input Env inEnv;
protected
  String name;
  Item item;
algorithm
  (name, _) := NFSCodeEnv.getRedeclarationNameInfo(inRedeclare);
  (item, _, _) := NFSCodeLookup.lookupSimpleName(name, inEnv);
  true := NFSCodeEnv.isItemUsed(item);
end removeUnusedRedeclares3;

annotation(__OpenModelica_Interface="frontend");
end NFSCodeDependency;
