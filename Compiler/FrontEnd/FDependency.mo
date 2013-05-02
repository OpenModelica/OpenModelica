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

encapsulated package FDependency
" file:  FDependency.mo
  package:     FDependency
  description: SCode dependency analysis.

  RCS: $Id: FDependency.mo 14085 2012-11-27 12:12:40Z adrpo $

  Dependency analysis for SCode.
"

public import Absyn;
public import SCode;
public import Env;

protected import Debug;
protected import Error;
protected import Flags;
protected import NFInstTypes;
protected import List;
protected import FSCodeCheck;
protected import FFlattenRedeclare;
protected import FLookup;
protected import System;
protected import Util;
protected import FEnv;
protected import Builtin;

protected type Item = Env.Item;
protected type Extends = Env.Extends;
protected type FrameType = Env.FrameType;
protected type ScopeType = Env.ScopeType;
protected type CSetsType = Env.CSetsType;
protected type AvlTree = Env.AvlTree;
protected type AvlTreeValue = Env.AvlTreeValue;
protected type ExtendsTable = Env.ExtendsTable;
protected type ImportTable = Env.ImportTable;
protected type Import = Absyn.Import;

public function analyse
  "This is the entry point of the dependency analysis. The dependency analysis
  is done in three steps: first it analyses the program and marks each element in
  the program that's used. The it goes through the used classes and checks if
  they contain any class extends, and if so it checks of those class extends are
  used or not. Finally it collects the used elements and builds a new program
  and environment that only contains those elements."
  input Absyn.Path inClassName;
  input Env.Env inEnv;
  input SCode.Program inProgram;
  output SCode.Program outProgram;
  output Env.Env outEnv;
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
  input Env.Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inClassName, inEnv, inInfo)
    local
      Item item;
      Env.Env env;

    case (_, _, _)
      equation
  (item, env) = lookupClass(inClassName, inEnv, inInfo,
    SOME(Error.LOOKUP_ERROR));
  checkItemIsClass(item);
  analyseItem(item, env);
      then
  ();

    else
      equation
  true = Flags.isSet(Flags.FAILTRACE);
  Debug.traceln("- FDependency.analyseClass failed for " +&
    Absyn.pathString(inClassName) +& " in " +&
    FEnv.getEnvName(inEnv));
      then
  fail();

  end matchcontinue;
end analyseClass;

protected function lookupClass
  "Lookup a class in the environment. The reason why SCodeLookup is not used
  directly is because we need to look up each part of the class path and mark
  them as used."
  input Absyn.Path inPath;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
  input Option<Error.Message> inErrorType;
  output Item outItem;
  output Env.Env outEnv;
algorithm
  (outItem, outEnv) := matchcontinue(inPath, inEnv, inInfo, inErrorType)
    local
      Item item;
      Env.Env env;
      String name_str, env_str;
      Error.Message error_id;

    case (_, _, _, _)
      equation
  (item, env) = lookupClass2(inPath, inEnv, inInfo, inErrorType);
  (item, env, _) = FEnv.resolveRedeclaredItem(item, env);
      then
  (item, env);

    case (_, _, _, SOME(error_id))
      equation
  name_str = Absyn.pathString(inPath);
  env_str = FEnv.getEnvName(inEnv);
  Error.addSourceMessage(error_id, {name_str, env_str}, inInfo);
      then
  fail();
  end matchcontinue;
end lookupClass;

protected function lookupClass2
  "Help function to lookupClass, does the actual look up."
  input Absyn.Path inPath;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
  input Option<Error.Message> inErrorType;
  output Item outItem;
  output Env.Env outEnv;
algorithm
  (outItem, outEnv) := match(inPath, inEnv, inInfo, inErrorType)
    local
      Item item;
      Env.Env env;
      String id;
      Absyn.Path rest_path;

    case (Absyn.IDENT(name = _), _, _, _)
      equation
  (item, _, env, _) =
    FLookup.lookupNameSilent(inPath, inEnv, inInfo);
      then
  (item, env);

    // Special case for the baseclass of a class extends. Should be looked up
    // among the inherited elements of the enclosing class.
    case (Absyn.QUALIFIED(name = "$ce", path = Absyn.IDENT(name = id)), _ :: env, _, _)
      equation
  (item, env) = FLookup.lookupInheritedName(id, env);
      then
  (item, env);

    case (Absyn.QUALIFIED(name = id, path = rest_path), _, _, _)
      equation
  (item, _, env, _) =
    FLookup.lookupNameSilent(Absyn.IDENT(id), inEnv, inInfo);
  (item, env, _) = FEnv.resolveRedeclaredItem(item, env);
  analyseItem(item, env);
  (item, env) = lookupNameInItem(rest_path, item, env, inErrorType);
      then
  (item, env);

    case (Absyn.FULLYQUALIFIED(path = rest_path), _, _, _)
      equation
  env = FEnv.getEnvTopScope(inEnv);
  (item, env) = lookupClass2(rest_path, env, inInfo, inErrorType);
      then
  (item, env);

  end match;
end lookupClass2;

protected function lookupNameInItem
  input Absyn.Path inName;
  input Item inItem;
  input Env.Env inEnv;
  input Option<Error.Message> inErrorType;
  output Item outItem;
  output Env.Env outEnv;
algorithm
  (outItem, outEnv) := match(inName, inItem, inEnv, inErrorType)
    local
      Absyn.Path type_path;
      SCode.Mod mods;
      Absyn.Info info;
      Env.Env env, type_env;
      Env.Frame class_env;
      list<Env.Redeclaration> redeclares;
      Item item;

    case (_, _, {}, _) then (inItem, inEnv);

    case (_, Env.VAR(var = SCode.COMPONENT(typeSpec =
      Absyn.TPATH(path = type_path), modifications = mods, info = info)), _, _)
      equation
  (item, type_env) = lookupClass(type_path, inEnv, info, inErrorType);
  redeclares = FFlattenRedeclare.extractRedeclaresFromModifier(mods);
  (item, type_env, _) = FFlattenRedeclare.replaceRedeclaredElementsInEnv(
    redeclares, item, type_env, inEnv, NFInstTypes.emptyPrefix);
  (item, env) = lookupNameInItem(inName, item, type_env, inErrorType);
      then
  (item, env);

    case (_, Env.CLASS(cls = SCode.CLASS(info = info), env = {class_env}), _, _)
      equation
  env = FEnv.enterFrame(class_env, inEnv);
  (item, env) = lookupClass(inName, env, info, inErrorType);
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
      Absyn.Info info;

    case Env.CLASS(cls = _) then ();

    // We found a component instead, which might happen if the user tries to use
    // a variable name as a type.
    case Env.VAR(var = SCode.COMPONENT(name = name, info = info))
      equation
  Error.addSourceMessage(Error.LOOKUP_TYPE_FOUND_COMP, {name}, info);
      then
  fail();
  end match;
end checkItemIsClass;

protected function analyseItem
  "Analyses an item."
  input Item inItem;
  input Env.Env inEnv;
algorithm
  _ := matchcontinue(inItem, inEnv)
    local
      SCode.ClassDef cdef;
      Env.Frame cls_env;
      Env.Env env;
      Absyn.Info info;
      SCode.Restriction res;
      SCode.Element cls;
      SCode.Comment cmt;

    // Check if the item is already marked as used, then we can stop here.
    case (_, _)
      equation
  true = FEnv.isItemUsed(inItem);
      then
  ();

    // A component, mark it and it's environment as used.
    case (Env.VAR(var = _), env)
      equation
  markItemAsUsed(inItem, env);
      then
  ();

    // A basic type, nothing to be done.
    case (Env.CLASS(classType = Env.BASIC_TYPE()), _) then ();

    // A normal class, mark it and its environment as used, and recursively
    // analyse it's contents.
    case (Env.CLASS(cls = cls as SCode.CLASS(classDef = cdef,
  restriction = res, info = info, cmt = cmt), env = {cls_env}), env)
      equation
  markItemAsUsed(inItem, env);
  env = FEnv.enterFrame(cls_env, env);
  analyseClassDef(cdef, res, env, false, info);
  analyseMetaType(res, env, info);
  analyseComment(cmt, env, info);
  _ :: env = env;
  analyseRedeclaredClass(cls, env);
      then
  ();

    case (Env.CLASS(cls = SCode.CLASS(name = "time")), _) then ();

    else
      equation
  true = Flags.isSet(Flags.FAILTRACE);
  Debug.traceln("- FDependency.analyseItem failed on " +&
    FEnv.getItemName(inItem) +& " in " +&
    FEnv.getEnvName(inEnv));
      then
  fail();

  end matchcontinue;
end analyseItem;

protected function markItemAsUsed
  "Marks an item and it's environment as used."
  input Item inItem;
  input Env.Env inEnv;
algorithm
  _ := match(inItem, inEnv)
    local
      Env.Frame cls_env;
      Util.StatefulBoolean is_used;
      String name;

    case (Env.VAR(isUsed = SOME(is_used)), _)
      equation
  Util.setStatefulBoolean(is_used, true);
  markEnvAsUsed(inEnv);
      then
  ();

    case (Env.VAR(isUsed = NONE()), _) then ();

    case (Env.CLASS(env = {cls_env}, cls = SCode.CLASS(name = name)), _)
      equation
  markFrameAsUsed(cls_env);
  markEnvAsUsed(inEnv);
      then
  ();
  end match;
end markItemAsUsed;

protected function markFrameAsUsed
  "Marks a single frame as used."
  input Env.Frame inFrame;
algorithm
  _ := match(inFrame)
    local
      Util.StatefulBoolean is_used;

    case Env.FRAME(isUsed = SOME(is_used))
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
  input Env.Env inEnv;
algorithm
  _ := matchcontinue(inEnv)
    local
      Util.StatefulBoolean is_used;
      Env.Env rest_env;
      Env.Frame f;

    case ((f as Env.FRAME(isUsed = SOME(is_used))) :: rest_env)
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
  input Env.Frame inFrame;
  input Env.Env inEnv;
algorithm
  _ := match(inFrame, inEnv)
    local
      String name;

    case (Env.FRAME(frameType = Env.IMPLICIT_SCOPE(iterIndex=_)), _) then ();

    case (Env.FRAME(name = SOME(name)), _)
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
  input Env.Env inEnv;
  input Boolean inInModifierScope;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inClassDef, inRestriction, inEnv, inInModifierScope, inInfo)
    local
      list<SCode.Element> el;
      Absyn.Ident bc;
      SCode.Mod mods;
      Absyn.TypeSpec ty;
      list<SCode.Equation> nel, iel;
      list<SCode.AlgorithmSection> nal, ial;
      Option<SCode.Comment> cmt;
      list<SCode.Annotation> annl;
      Option<SCode.ExternalDecl> ext_decl;
      Env.Env ty_env, env;
      Item ty_item;
      SCode.Attributes attr;
      list<Absyn.Path> paths;

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
      then ();

    // The previous case failed, which might happen for an external object.
    // Check if the class definition is an external object and analyse it if
    // that's the case.
    case (SCode.PARTS(elementLst = el), _, _, _, _)
      equation
  isExternalObject(el, inEnv, inInfo);
  analyseClass(Absyn.IDENT("constructor"), inEnv, inInfo);
  analyseClass(Absyn.IDENT("destructor"), inEnv, inInfo);
      then ();

    // A class extends.
    case (SCode.CLASS_EXTENDS(baseClassName = bc), _, _, _, _)
      equation
  Error.addSourceMessage(Error.INTERNAL_ERROR,
    {"FDependency.analyseClassDef failed on CLASS_EXTENDS"}, inInfo);
      then
  fail();

    // A derived class definition.
    case (SCode.DERIVED(typeSpec = ty, modifications = mods, attributes = attr),
  _, _ :: env, _, _)
      equation
  env = Util.if_(inInModifierScope, inEnv, env);
  analyseTypeSpec(ty, env, inInfo);
  (ty_item, _, ty_env) = FLookup.lookupTypeSpec(ty, env, inInfo);
  (ty_item, ty_env, _) = FEnv.resolveRedeclaredItem(ty_item, ty_env);
  ty_env = FEnv.mergeItemEnv(ty_item, ty_env);
  // TODO! Analyse array dimensions from attributes!
  analyseModifier(mods, inEnv, ty_env, inInfo);
      then ();

    // Other cases which doesn't need to be analysed.
    case (SCode.ENUMERATION(enumLst = _), _, _, _, _) then ();
    case (SCode.OVERLOAD(pathLst = paths), _, _, _, _)
      equation
  List.map2_0(paths,analyseClass,inEnv,inInfo);
      then ();
    case (SCode.PDER(functionPath = _), _, _, _, _) then ();

  end matchcontinue;
end analyseClassDef;

protected function isExternalObject
  "Checks if a class definition is an external object."
  input list<SCode.Element> inElements;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
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
  el_names := List.map(el, SCode.elementName);
  checkExternalObject(el_names, inEnv, inInfo);
end isExternalObject;

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
  input Env.Env inEnv;
  input Absyn.Info inInfo;
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
  env_str = FEnv.getEnvName(inEnv);
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
  input Absyn.Info inInfo;
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
  el_str = "contains invalid elements: " +& el_str;
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
  input Env.Env inEnv;
  input Absyn.Info inInfo;
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
  input Env.Env inEnv;
algorithm
  _ := matchcontinue(inClass, inEnv)
    local
      Item item;
      String name;

    case (SCode.CLASS(name = _), _)
      equation
  false = SCode.isElementRedeclare(inClass);
      then ();

    case (SCode.CLASS(name = name), _)
      equation
  item = Env.CLASS(inClass, Env.emptyEnv, Env.USERDEFINED());
  analyseRedeclaredClass2(item, inEnv);
      then
  ();

  end matchcontinue;
end analyseRedeclaredClass;

protected function analyseRedeclaredClass2
  input Item inItem;
  input Env.Env inEnv;
algorithm
  _ := matchcontinue(inItem, inEnv)
    local
      String name;
      Item item;
      Env.Env env;
      SCode.Element cls;
      Absyn.Info info;

    case (Env.CLASS(cls = cls as SCode.CLASS(name = name, info = info)), _)
      equation
  (item, env) = FLookup.lookupRedeclaredClassByItem(inItem, inEnv, info);
  markItemAsUsed(item, env);
      then
  ();

    else
      equation
  true = Flags.isSet(Flags.FAILTRACE);
  Debug.traceln("- FDependency.analyseRedeclaredClass2 failed for " +&
    FEnv.getItemName(inItem) +& " in " +&
    FEnv.getEnvName(inEnv));
      then
  fail();

  end matchcontinue;
end analyseRedeclaredClass2;

protected function analyseElements
  input list<SCode.Element> inElements;
  input Env.Env inEnv;
  input SCode.Restriction inClassRestriction;
protected
  list<Extends> exts;
algorithm
  exts := FEnv.getEnvExtendsFromTable(inEnv);
  analyseElements2(inElements, inEnv, exts, inClassRestriction);
end analyseElements;

protected function analyseElements2
  input list<SCode.Element> inElements;
  input Env.Env inEnv;
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
  input Env.Env inEnv;
  input list<Extends> inExtends;
  input SCode.Restriction inClassRestriction;
  output list<Extends> outExtends;
algorithm
  outExtends := match(inElement, inEnv, inExtends, inClassRestriction)
    local
      Absyn.Path bc, bc2;
      SCode.Mod mods;
      Absyn.TypeSpec ty;
      Absyn.Info info;
      SCode.Attributes attr;
      Option<Absyn.Exp> cond_exp;
      Item ty_item;
      Env.Env ty_env, env;
      SCode.Ident name;
      SCode.Prefixes prefixes;
      SCode.Restriction res;
      String errorMessage;
      list<Extends> exts;
      Absyn.InnerOuter io;

    // Fail on 'extends ExternalObject' so we can handle it as a special case in
    // analyseClassDef.
    case (SCode.EXTENDS(baseClassPath = Absyn.IDENT("ExternalObject")), _, _, _)
      then fail();

    // An extends-clause.
    case (SCode.EXTENDS(baseClassPath = bc2, modifications = mods, info = info), _,
  Env.EXTENDS(baseClass = bc) :: exts, _)
      equation
  //print("bc = " +& Absyn.pathString(bc) +& "\n");
  //print("bc2 = " +& Absyn.pathString(bc2) +& "\n");
  (ty_item, _, ty_env) =
    FLookup.lookupBaseClassName(bc, inEnv, info);
  analyseExtends(bc, inEnv, info);
  ty_env = FEnv.mergeItemEnv(ty_item, ty_env);
  analyseModifier(mods, inEnv, ty_env, info);
      then
  exts;

    // A component.
    case (SCode.COMPONENT(name = name, attributes = attr, typeSpec = ty,
  modifications = mods, condition = cond_exp, prefixes = prefixes, info = info), _, _, _)
      equation
  markAsUsedOnRestriction(name, inClassRestriction, inEnv, info);
  analyseAttributes(attr, inEnv, info);
  analyseTypeSpec(ty, inEnv, info);
  (ty_item, _, ty_env) = FLookup.lookupTypeSpec(ty, inEnv, info);
  (ty_item, ty_env, _) = FEnv.resolveRedeclaredItem(ty_item, ty_env);
  ty_env = FEnv.mergeItemEnv(ty_item, ty_env);
  FSCodeCheck.checkRecursiveComponentDeclaration(name, info, ty_env,
    ty_item, inEnv);
  analyseModifier(mods, inEnv, ty_env, info);
  analyseOptExp(cond_exp, inEnv, info);
  analyseConstrainClass(SCode.replaceableOptConstraint(SCode.prefixesReplaceable(prefixes)), inEnv, info);
      then
  inExtends;

    //operators in operator record might be used later.
    case (SCode.CLASS(name = name, restriction=SCode.R_OPERATOR(), info = info), _, _, SCode.R_OPERATOR_RECORD())
      equation
  analyseClass(Absyn.IDENT(name), inEnv, info);
      then
  inExtends;

    //operators in any other class type are error.
    case (SCode.CLASS(name = name, restriction=SCode.R_OPERATOR(), info = info), _, _, _)
      equation
  //mahge: FIX HERE.
  errorMessage = "operators are allowed in OPERATOR RECORD only. Error on:" +& name;
  Error.addSourceMessage(Error.LOOKUP_ERROR, {errorMessage, name}, info);
      then
  fail();

    //operator functions in operator record might be used later.
    case (SCode.CLASS(name = name, restriction=SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION()), info = info), _, _, SCode.R_OPERATOR_RECORD())
      equation
  analyseClass(Absyn.IDENT(name), inEnv, info);
      then
  inExtends;

     //operators functions in any other class type are error.
    case (SCode.CLASS(name = name, restriction=SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION()), info = info), _, _, _)
      equation
  //mahge: FIX HERE.
  errorMessage = "Operator functions are allowed in OPERATOR RECORD only. Error on:" +& name;
  Error.addSourceMessage(Error.LOOKUP_ERROR, {errorMessage, name}, info);
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
  //mahge: FIX HERE.
  errorMessage = "Operators can only contain functions. Error on:" +& name;
  Error.addSourceMessage(Error.LOOKUP_ERROR, {errorMessage, name}, info);
      then
  fail();

    // equalityConstraints may not be explicitly used but might be needed anyway
    // (if the record is used in a connect for example), so always mark it as used.
    case (SCode.CLASS(name = name as "equalityConstraint", info = info), _, _, _)
      equation
  analyseClass(Absyn.IDENT(name), inEnv, info);
      then
  inExtends;

    case (SCode.CLASS(name = name, info = info, classDef=SCode.CLASS_EXTENDS(baseClassName = _)), _, _, _)
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

protected function markAsUsedOnRestriction
  input SCode.Ident inName;
  input SCode.Restriction inRestriction;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inName, inRestriction, inEnv, inInfo)
    local
      AvlTree cls_and_vars;
      Util.StatefulBoolean is_used;

    case (_, _, Env.FRAME(clsAndVars = cls_and_vars) :: _, _)
      equation
  true = markAsUsedOnRestriction2(inRestriction);
  Env.VAR(isUsed = SOME(is_used)) =
    Env.avlTreeGet(cls_and_vars, inName);
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
    case SCode.R_CONNECTOR(isExpandable = _) then true;
    case SCode.R_RECORD() then true;
    else false;
  end match;
end markAsUsedOnRestriction2;

protected function analyseExtends
  "Analyses an extends-clause."
  input Absyn.Path inClassName;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
protected
  Item item;
  Env.Env env;
algorithm
  (item, env) := lookupClass(inClassName, inEnv, inInfo, NONE());
  analyseItem(item, env);
end analyseExtends;

protected function analyseAttributes
  "Analyses a components attributes (actually only the array dimensions)."
  input SCode.Attributes inAttributes;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
protected
  Absyn.ArrayDim ad;
algorithm
  SCode.ATTR(arrayDims = ad) := inAttributes;
  List.map2_0(ad, analyseSubscript, inEnv, inInfo);
end analyseAttributes;

protected function analyseModifier
  "Analyses a modifier."
  input SCode.Mod inModifier;
  input Env.Env inEnv;
  input Env.Env inTypeEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inModifier, inEnv, inTypeEnv, inInfo)
    local
      SCode.Element el;
      list<SCode.SubMod> sub_mods;
      Option<tuple<Absyn.Exp, Boolean>> bind_exp;

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
  input Env.Env inEnv;
  input Env.Env inTypeEnv;
algorithm
  _ := match(inElement, inEnv, inTypeEnv)
    local
      SCode.ClassDef cdef;
      Absyn.Info info;
      SCode.Restriction restr;
      SCode.Prefixes prefixes;

    // Class definitions are not analysed in analyseElement but are needed here
    // in case a class is redeclared.
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
  end match;
end analyseRedeclareModifier;

protected function analyseConstrainClass
  "Analyses a constrain class, i.e. given by constrainedby."
  input Option<SCode.ConstrainClass> inCC;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inCC, inEnv, inInfo)
    local
      Absyn.Path path;
      SCode.Mod mod;
      Env.Env env;

    case (SOME(SCode.CONSTRAINCLASS(constrainingClass = path, modifier = mod)), _, _)
      equation
  analyseClass(path, inEnv, inInfo);
  (_, env) = lookupClass(path, inEnv, inInfo, SOME(Error.LOOKUP_ERROR));
  analyseModifier(mod, inEnv, env, inInfo);
      then
  ();

    else ();
  end match;
end analyseConstrainClass;

protected function analyseSubMod
  "Analyses a submodifier."
  input SCode.SubMod inSubMod;
  input tuple<Env.Env, Env.Env> inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inSubMod, inEnv, inInfo)
    local
      SCode.Ident ident;
      SCode.Mod m;
      list<SCode.Subscript> subs;
      Env.Env env, ty_env;

    case (SCode.NAMEMOD(ident = ident, A = m), (env, ty_env), _)
      equation
  analyseNameMod(ident, env, ty_env, m, inInfo);
      then
  ();

  end match;
end analyseSubMod;

protected function analyseNameMod
  input SCode.Ident inIdent;
  input Env.Env inEnv;
  input Env.Env inTypeEnv;
  input SCode.Mod inMod;
  input Absyn.Info inInfo;
protected
  Option<Item> item;
  Option<Env.Env> env;
algorithm
  (item, env) := lookupNameMod(Absyn.IDENT(inIdent), inTypeEnv, inInfo);
  analyseNameMod2(inIdent, item, env, inEnv, inTypeEnv, inMod, inInfo);
end analyseNameMod;

protected function analyseNameMod2
  input SCode.Ident inIdent;
  input Option<Item> inItem;
  input Option<Env.Env> inItemEnv;
  input Env.Env inEnv;
  input Env.Env inTypeEnv;
  input SCode.Mod inModifier;
  input Absyn.Info inInfo;
algorithm
  _ := match(inIdent, inItem, inItemEnv, inEnv, inTypeEnv, inModifier, inInfo)
    local
      Item item;
      Env.Env env;

    case (_, SOME(item), SOME(env), _, _, _, _)
      equation
  FSCodeCheck.checkModifierIfRedeclare(item, inModifier, inInfo);
  analyseItem(item, env);
  env = FEnv.mergeItemEnv(item, env);
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
  input Env.Env inEnv;
  input Absyn.Info inInfo;
  output Option<Item> outItem;
  output Option<Env.Env> outEnv;
algorithm
  (outItem, outEnv) := matchcontinue(inPath, inEnv, inInfo)
    local
      Item item;
      Env.Env env;

    case (_, _, _)
      equation
  (item, _, env, _) = FLookup.lookupNameSilent(inPath, inEnv, inInfo);
  (item, env, _) = FEnv.resolveRedeclaredItem(item, env);
      then
  (SOME(item), SOME(env));

    else (NONE(), NONE());
  end matchcontinue;
end lookupNameMod;

protected function analyseSubscript
  "Analyses a subscript."
  input SCode.Subscript inSubscript;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
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
  input Option<tuple<Absyn.Exp, Boolean>> inBinding;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inBinding, inEnv, inInfo)
    local
      Absyn.Exp bind_exp;

    case (NONE(), _, _) then ();

    case (SOME((bind_exp, _)), _, _)
      equation
  analyseExp(bind_exp, inEnv, inInfo);
      then
  ();
  end match;
end analyseModBinding;

protected function analyseTypeSpec
  "Analyses a type specificer."
  input Absyn.TypeSpec inTypeSpec;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inTypeSpec, inEnv, inInfo)
    local
      Absyn.Path type_path;
      list<Absyn.TypeSpec> tys;

    // A normal type.
    case (Absyn.TPATH(path = type_path), _, _)
      equation
  analyseClass(type_path, inEnv, inInfo);
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

protected function analyseExternalDecl
  "Analyses an external declaration."
  input Option<SCode.ExternalDecl> inExtDecl;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inExtDecl, inEnv, inInfo)
    local
      SCode.Annotation ann;
      list<Absyn.Exp> args;

    // An external declaration might have an annotation that we need to analyse.
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
  input Env.Env inEnv;
  input Absyn.Info inInfo;
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
  input Env.Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inAnnotation, inEnv, inInfo)
    local
      SCode.Mod mods;
      list<SCode.SubMod> sub_mods;

    case (SCode.ANNOTATION(modification = mods as SCode.MOD(subModLst = sub_mods)),
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
  input Env.Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inMod, inEnv, inInfo)
    local
      SCode.Mod mods;
      String id;

    // derivative is a bit special since it's not a builtin function, so just
    // analyse it's modifier to make sure that we get the derivation function.
    case (SCode.NAMEMOD(ident = "derivative", A = mods), _, _)
      equation
  analyseModifier(mods, inEnv, Env.emptyEnv, inInfo);
      then
  ();

    // Otherwise, try to analyse the modifier name, and if that succeeds also
    // try and analyse the rest of the modification. This is needed for example
    // for the graphical annotations such as Icon.
    case (SCode.NAMEMOD(ident = id, A = mods), _, _)
      equation
  analyseAnnotationName(id, inEnv, inInfo);
  analyseModifier(mods, inEnv, Env.emptyEnv, inInfo);
      then
  ();

    else ();
  end matchcontinue;
end analyseAnnotationMod;

protected function analyseAnnotationName
  "Analyses an annotation name, such as Icon or Line."
  input SCode.Ident inName;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
protected
  Item item;
  Env.Env env;
algorithm
  (item, _, env, _) :=
    FLookup.lookupNameSilent(Absyn.IDENT(inName), inEnv, inInfo);
  (item, env, _) := FEnv.resolveRedeclaredItem(item, env);
  analyseItem(item, env);
end analyseAnnotationName;

protected function analyseExp
  "Recursively analyses an expression."
  input Absyn.Exp inExp;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
algorithm
  (_, _) := Absyn.traverseExpBidir(inExp, (analyseExpTraverserEnter,
    analyseExpTraverserExit, (inEnv, inInfo)));
end analyseExp;

protected function analyseOptExp
  "Recursively analyses an optional expression."
  input Option<Absyn.Exp> inExp;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
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
  input tuple<Absyn.Exp, tuple<Env.Env, Absyn.Info>> inTuple;
  output tuple<Absyn.Exp, tuple<Env.Env, Absyn.Info>> outTuple;
protected
  Absyn.Exp exp;
  Env.Env env;
  Absyn.Info info;
algorithm
  (exp, (env, info)) := inTuple;
  env := analyseExp2(exp, env, info);
  outTuple := (exp, (env, info));
end analyseExpTraverserEnter;

protected function analyseExp2
  "Helper function to analyseExp, does the actual work."
  input Absyn.Exp inExp;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
  output Env.Env outEnv;
algorithm
  outEnv := match(inExp, inEnv, inInfo)
    local
      Absyn.ComponentRef cref;
      Absyn.FunctionArgs args;
      Absyn.ForIterators iters;
      Env.Env env;

    case (Absyn.CREF(componentRef = cref), _, _)
      equation
  analyseCref(cref, inEnv, inInfo);
      then
  inEnv;

    case (Absyn.CALL(functionArgs = Absyn.FOR_ITER_FARG(iterators = iters)), _, _)
      equation
  env = FEnv.extendEnvWithIterators(iters, System.tmpTickIndex(Env.tmpTickIndex), inEnv);
      then
  env;

    case (Absyn.CALL(function_ = cref, functionArgs = args), _, _)
      equation
  analyseCref(cref, inEnv, inInfo);
      then
  inEnv;

    case (Absyn.PARTEVALFUNCTION(function_ = cref, functionArgs = args), _, _)
      equation
  analyseCref(cref, inEnv, inInfo);
      then
  inEnv;

    case (Absyn.MATCHEXP(matchTy = _), _, _)
      equation
  env = FEnv.extendEnvWithMatch(inExp, System.tmpTickIndex(Env.tmpTickIndex), inEnv);
      then
  env;

    else inEnv;
  end match;
end analyseExp2;

protected function analyseCref
  "Analyses a component reference."
  input Absyn.ComponentRef inCref;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inCref, inEnv, inInfo)
    local
      Absyn.Path path;
      Item item;
      Env.Env env;

    case (Absyn.WILD(), _, _) then ();

    case (_, _, _)
      equation
  // We want to use lookupClass since we need the item and environment, and
  // we don't care about any subscripts, so convert the cref to a path.
  path = Absyn.crefToPathIgnoreSubs(inCref);
  (item, env) = lookupClass(path, inEnv, inInfo, NONE());
  analyseItem(item, env);
      then
  ();

    else ();

  end matchcontinue;
end analyseCref;

protected function analyseExpTraverserExit
  "Traversal exit function for use in analyseExp."
  input tuple<Absyn.Exp, tuple<Env.Env, Absyn.Info>> inTuple;
  output tuple<Absyn.Exp, tuple<Env.Env, Absyn.Info>> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      Absyn.Exp e;
      Env.Env env;
      Absyn.Info info;

    // Remove any scopes added by the enter function.

    case ((e as Absyn.CALL(functionArgs = Absyn.FOR_ITER_FARG(iterators = _)),
  (Env.FRAME(frameType = Env.IMPLICIT_SCOPE(iterIndex=_)) :: env, info)))
      then
  ((e, (env, info)));

    case ((e as Absyn.MATCHEXP(matchTy = _),
  (Env.FRAME(frameType = Env.IMPLICIT_SCOPE(iterIndex=_)) :: env, info)))
      then
  ((e, (env, info)));

    else inTuple;
  end match;
end analyseExpTraverserExit;

protected function analyseEquation
  "Analyses an equation."
  input SCode.Equation inEquation;
  input Env.Env inEnv;
protected
  SCode.EEquation equ;
algorithm
  SCode.EQUATION(equ) := inEquation;
  (_, _) := SCode.traverseEEquations(equ, (analyseEEquationTraverser, inEnv));
end analyseEquation;

protected function analyseEEquationTraverser
  "Traversal function for use in analyseEquation."
  input tuple<SCode.EEquation, Env.Env> inTuple;
  output tuple<SCode.EEquation, Env.Env> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      SCode.EEquation equ;
      SCode.Ident iter_name;
      Env.Env env;
      Absyn.Info info;
      Absyn.ComponentRef cref1;

    case ((equ as SCode.EQ_FOR(index = iter_name, info = info), env))
      equation
  env = FEnv.extendEnvWithIterators({Absyn.ITERATOR(iter_name, NONE(), NONE())}, System.tmpTickIndex(Env.tmpTickIndex), env);
  (equ, _) = SCode.traverseEEquationExps(equ, (traverseExp, (env, info)));
      then
  ((equ, env));

    case ((equ as SCode.EQ_REINIT(cref = cref1, info = info), env))
      equation
  analyseCref(cref1, env, info);
  (equ, _) = SCode.traverseEEquationExps(equ, (traverseExp, (env, info)));
      then
  ((equ, env));

    case ((equ, env))
      equation
  info = SCode.getEEquationInfo(equ);
  (equ, _) = SCode.traverseEEquationExps(equ, (traverseExp, (env, info)));
      then
  ((equ, env));

  end match;
end analyseEEquationTraverser;

protected function traverseExp
  "Traversal function used by analyseEEquationTraverser and
  analyseStatementTraverser."
  input tuple<Absyn.Exp, tuple<Env.Env, Absyn.Info>> inTuple;
  output tuple<Absyn.Exp, tuple<Env.Env, Absyn.Info>> outTuple;
protected
  Absyn.Exp exp;
  Env.Env env;
  Absyn.Info info;
algorithm
  (exp, (env, info)) := inTuple;
  (exp, (_, _, (env, info))) := Absyn.traverseExpBidir(exp,
    (analyseExpTraverserEnter, analyseExpTraverserExit, (env, info)));
  outTuple := (exp, (env, info));
end traverseExp;

protected function analyseAlgorithm
  "Analyses an algorithm."
  input SCode.AlgorithmSection inAlgorithm;
  input Env.Env inEnv;
protected
  list<SCode.Statement> stmts;
algorithm
  SCode.ALGORITHM(stmts) := inAlgorithm;
  List.map1_0(stmts, analyseStatement, inEnv);
end analyseAlgorithm;

protected function analyseStatement
  "Analyses a statement in an algorithm."
  input SCode.Statement inStatement;
  input Env.Env inEnv;
algorithm
  (_, _) := SCode.traverseStatements(inStatement,
    (analyseStatementTraverser, inEnv));
end analyseStatement;

protected function analyseStatementTraverser
  "Traversal function used by analyseStatement."
  input tuple<SCode.Statement, Env.Env> inTuple;
  output tuple<SCode.Statement, Env.Env> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      Env.Env env;
      SCode.Statement stmt;
      Absyn.Info info;
      list<SCode.Statement> parforBody;
      String iter_name;

    case ((stmt as SCode.ALG_FOR(index = iter_name, info = info), env))
      equation
  env = FEnv.extendEnvWithIterators({Absyn.ITERATOR(iter_name, NONE(), NONE())}, System.tmpTickIndex(Env.tmpTickIndex), env);
  (_, _) = SCode.traverseStatementExps(stmt, (traverseExp, (env, info)));
      then
  ((stmt, env));

    case ((stmt as SCode.ALG_PARFOR(index = iter_name, parforBody = parforBody, info = info), env))
      equation
  env = FEnv.extendEnvWithIterators({Absyn.ITERATOR(iter_name, NONE(), NONE())}, System.tmpTickIndex(Env.tmpTickIndex), env);
  (_, _) = SCode.traverseStatementExps(stmt, (traverseExp, (env, info)));
      then
  ((stmt, env));

    case ((stmt, env))
      equation
  info = SCode.getStatementInfo(stmt);
  (_, _) = SCode.traverseStatementExps(stmt, (traverseExp, (env, info)));
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
  input Env.Env inEnv;
protected
  AvlTree tree;
algorithm
  Env.FRAME(clsAndVars = tree) :: _ := inEnv;
  analyseAvlTree(SOME(tree), inEnv);
end analyseClassExtends;

protected function analyseAvlTree
  "Helper function to analyseClassExtends. Goes through the nodes in an
  AvlTree."
  input Option<AvlTree> inTree;
  input Env.Env inEnv;
algorithm
  _ := match(inTree, inEnv)
    local
      Option<AvlTree> left, right;
      AvlTreeValue value;

    case (NONE(), _) then ();
    case (SOME(Env.AVLTREENODE(value = NONE())), _) then ();
    case (SOME(Env.AVLTREENODE(value = SOME(value), left = left, right = right)), _)
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
  input AvlTreeValue inValue;
  input Env.Env inEnv;
algorithm
  _ := matchcontinue(inValue, inEnv)
    local
      String key_str;
      Env.Frame cls_env;
      Env.Env env;
      SCode.Element cls;
      Env.ClassType cls_ty;
      Util.StatefulBoolean is_used;

    // Check if the current environment is not used, we can quit here if that's
    // the case.
    case (_, Env.FRAME(name = SOME(_), isUsed = SOME(is_used)) :: _)
      equation
  false = Util.getStatefulBoolean(is_used);
      then
  ();

    case (Env.AVLTREEVALUE(key = key_str, value = Env.CLASS(cls = cls,
  env = {cls_env}, classType = cls_ty)), _)
      equation
  env = FEnv.enterFrame(cls_env, inEnv);
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
  input Env.ClassType inClassType;
  input Env.Env inEnv;
algorithm
  _ := matchcontinue(inClass, inClassType, inEnv)
    local
      Item item;
      Absyn.Info info;
      Absyn.Path bc;
      String cls_name;
      Env.Env env;

    case (SCode.CLASS(name = cls_name, classDef =
    SCode.PARTS(elementLst = SCode.EXTENDS(baseClassPath = bc) :: _),
    info = info), Env.CLASS_EXTENDS(), _)
      equation
  // Look up the base class of the class extends, and check if it's used.
  (item, _, _) = FLookup.lookupBaseClassName(bc, inEnv, info);
  true = FEnv.isItemUsed(item);
  // Ok, the base is used, analyse the class extends to mark it and it's
  // dependencies as used.
  _ :: env = inEnv;
  analyseClass(Absyn.IDENT(cls_name), env, info);
      then
  ();

    case (SCode.CLASS(name = cls_name, info = info), Env.USERDEFINED(), _)
      equation
  true = SCode.isElementRedeclare(inClass);
  _ :: env = inEnv;
  item = Env.CLASS(inClass, Env.emptyEnv, inClassType);
  (item, _) = FLookup.lookupRedeclaredClassByItem(item, env, info);
  true = FEnv.isItemUsed(item);
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
  input Env.Env inEnv;
  input SCode.Program inProgram;
  input Absyn.Path inClassName;
  output Env.Env outEnv;
  output SCode.Program outProgram;
protected
  Env.Env env;
  AvlTree cls_and_vars;
algorithm
  (_, env) := Builtin.initialEnv(Env.emptyCache());
  Env.FRAME(clsAndVars = cls_and_vars) :: _ := inEnv;
  (outProgram, outEnv) :=
    collectUsedProgram2(cls_and_vars, inEnv, inProgram, inClassName, env);
end collectUsedProgram;

protected function collectUsedProgram2
  "Helper function to collectUsedProgram2. Goes through each top-level class in
  the program and collects them if they are used. This is to preserve the order
  of the classes in the new program. Another alternative would have been to just
  traverse the environment and collect the used classes, which would have been a
  bit faster but would not have preserved the order of the program."
  input AvlTree clsAndVars;
  input Env.Env inEnv;
  input SCode.Program inProgram;
  input Absyn.Path inClassName;
  input Env.Env inAccumEnv;
  output SCode.Program outProgram;
  output Env.Env outAccumEnv;
algorithm
  (outProgram, outAccumEnv) :=
  matchcontinue(clsAndVars, inEnv, inProgram, inClassName, inAccumEnv)
    local
      SCode.Element cls_el;
      SCode.Element cls;
      SCode.Program rest_prog;
      String name;
      Env.Env env;

    // We're done!
    case (_, _, {}, _, _) then (inProgram, inAccumEnv);

    // Try to collect the first class in the list.
    case (_, _, (cls as SCode.CLASS(name = name)) :: rest_prog, _, env)
      equation
  cls_el = cls;
  (cls_el, env) = collectUsedClass(cls_el, inEnv, clsAndVars,
    inClassName, env, Absyn.IDENT(name));
  SCode.CLASS(name = _) = cls_el;
  cls = cls_el;
  (rest_prog, env) =
    collectUsedProgram2(clsAndVars, inEnv, rest_prog, inClassName, env);
      then
  (cls :: rest_prog, env);

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
  input Env.Env inEnv;
  input AvlTree inClsAndVars;
  input Absyn.Path inClassName;
  input Env.Env inAccumEnv;
  input Absyn.Path inAccumPath;
  output SCode.Element outClass;
  output Env.Env outAccumEnv;
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
      Absyn.Info info;
      Item item, resolved_item;
      Env.Frame class_frame;
      Env.Env class_env, env, enclosing_env;
      Option<SCode.ConstrainClass> cc;
      SCode.Element cls;
      SCode.Comment cmt;

    case (SCode.CLASS(name, prefixes as SCode.PREFIXES(replaceablePrefix =
  SCode.REPLACEABLE(cc)), ep, pp, res, cdef, cmt, info), _, _, _, _, _)
      equation
  /*********************************************************************/
  // TODO: Fix the usage of alias items in this case.
  /*********************************************************************/
  // Check if the class is used.
  item = Env.avlTreeGet(inClsAndVars, name);
  (resolved_item, _) = FLookup.resolveAlias(item, inEnv);
  true = checkClassUsed(resolved_item, cdef);
  // The class is used, recursively collect its contents.
  {class_frame} = FEnv.getItemEnv(resolved_item);
  enclosing_env = FEnv.enterScope(inEnv, name);
  (cdef, class_env) =
    collectUsedClassDef(cdef, enclosing_env, class_frame, inClassName, inAccumPath);

  //Fix operator record restriction to record
  res = fixRestrictionOfOperatorRecord(res);
  cls = SCode.CLASS(name, prefixes, ep, pp, res, cdef, cmt, info);
  resolved_item = updateItemEnv(resolved_item, cls, class_env);
  basename = name +& Env.BASE_CLASS_SUFFIX;
  env = FEnv.extendEnvWithItem(resolved_item, inAccumEnv, basename);
  env = FEnv.extendEnvWithItem(item, env, name);
      then
  (cls, env);

    case (SCode.CLASS(name, prefixes, ep, pp, res, cdef, cmt, info), _, _, _, _, _)
      equation
  // TODO! FIXME! add cc to the used classes!
  cc = SCode.replaceableOptConstraint(SCode.prefixesReplaceable(prefixes));
  // Check if the class is used.
  item = Env.avlTreeGet(inClsAndVars, name);
  true = checkClassUsed(item, cdef);
  // The class is used, recursively collect it's contents.
  {class_frame} = FEnv.getItemEnv(item);
  enclosing_env = FEnv.enterScope(inEnv, name);
  (cdef, class_env) =
    collectUsedClassDef(cdef, enclosing_env, class_frame, inClassName, inAccumPath);
  //Fix operator record restriction to record
  res = fixRestrictionOfOperatorRecord(res);
  // Add the class to the new environment.
  cls = SCode.CLASS(name, prefixes, ep, pp, res, cdef, cmt, info);
  item = updateItemEnv(item, cls, class_env);
  env = FEnv.extendEnvWithItem(item, inAccumEnv, name);
      then
  (cls, env);

  end match;
end collectUsedClass;

protected function fixRestrictionOfOperatorRecord
  input SCode.Restriction inRes;
  output SCode.Restriction outRes;
algorithm
  outRes := match(inRes)
  case (SCode.R_OPERATOR_RECORD())
      then SCode.R_RECORD();

  else inRes;
  end match;
end fixRestrictionOfOperatorRecord;

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
    case (Env.CLASS(cls = SCode.CLASS(name = "GraphicalAnnotationsProgram____")), _)
      then true;
    // Otherwise, use the environment item to determine if the class is used or
    // not.
    else FEnv.isItemUsed(inItem);
  end match;
end checkClassUsed;

protected function updateItemEnv
  "Replaces the class and environment in an environment item, preserving the
  item's type."
  input Item inItem;
  input SCode.Element inClass;
  input Env.Env inEnv;
  output Item outItem;
algorithm
  outItem := match(inItem, inClass, inEnv)
    local
      Env.ClassType cls_ty;

    case (Env.CLASS(classType = cls_ty), _, _)
      then Env.CLASS(inClass, inEnv, cls_ty);

  end match;
end updateItemEnv;

protected function collectUsedClassDef
  "Collects the contents of a class definition."
  input SCode.ClassDef inClassDef;
  input Env.Env inEnv;
  input Env.Frame inClassEnv;
  input Absyn.Path inClassName;
  input Absyn.Path inAccumPath;
  output SCode.ClassDef outClass;
  output Env.Env outEnv;
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
      Env.Env env;
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

    case (SCode.ENUMERATION(enumLst = _), _, _, _, _)
      then (inClassDef, {inClassEnv});

    else (inClassDef, {inClassEnv});
  end match;
end collectUsedClassDef;

protected function collectUsedElements
  "Collects a class definition's elements."
  input list<SCode.Element> inElements;
  input Env.Env inEnv;
  input Env.Frame inClassEnv;
  input Absyn.Path inClassName;
  input Absyn.Path inAccumPath;
  output list<SCode.Element> outUsedElements;
  output Env.Env outNewEnv;
protected
  Env.Frame empty_class_env;
  AvlTree cls_and_vars;
  Boolean collect_constants;
algorithm
  // Create a new class environment that preserves the imports and extends.
  (empty_class_env, cls_and_vars) :=
    FEnv.removeClsAndVarsFromFrame(inClassEnv);
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
  input Env.Env inEnclosingEnv;
  input AvlTree inClsAndVars;
  input list<SCode.Element> inAccumElements;
  input Env.Env inAccumEnv;
  input Absyn.Path inClassName;
  input Absyn.Path inAccumPath;
  input Boolean inCollectConstants;
  output list<SCode.Element> outAccumElements;
  output Env.Env outAccumEnv;
algorithm
  (outAccumElements, outAccumEnv) :=
  matchcontinue(inElements, inEnclosingEnv, inClsAndVars, inAccumElements,
      inAccumEnv, inClassName, inAccumPath, inCollectConstants)
    local
      SCode.Element el;
      list<SCode.Element> rest_el, accum_el;
      Env.Env accum_env;

    // Tail recursive function, reverse the result list.
    case ({}, _, _, _, _, _, _, _)
      then (listReverse(inAccumElements), inAccumEnv);

    case (el :: rest_el, _, _, accum_el, accum_env, _, _, _)
      equation
  (el, accum_env) = collectUsedElement(el, inEnclosingEnv, inClsAndVars,
    accum_env, inClassName, inAccumPath, inCollectConstants);
  accum_el = el :: accum_el;
  (accum_el, accum_env) = collectUsedElements2(rest_el, inEnclosingEnv,
    inClsAndVars, accum_el, accum_env, inClassName, inAccumPath, inCollectConstants);
      then
  (accum_el, accum_env);

    case (_ :: rest_el, _, _, accum_el, accum_env, _, _, _)
      equation
  (accum_el, accum_env) = collectUsedElements2(rest_el,
    inEnclosingEnv, inClsAndVars, accum_el, accum_env, inClassName,
    inAccumPath, inCollectConstants);
      then
  (accum_el, accum_env);

  end matchcontinue;
end collectUsedElements2;

protected function collectUsedElement
  "Collects a class element."
  input SCode.Element inElement;
  input Env.Env inEnclosingEnv;
  input AvlTree inClsAndVars;
  input Env.Env inAccumEnv;
  input Absyn.Path inClassName;
  input Absyn.Path inAccumPath;
  input Boolean inCollectConstants;
  output SCode.Element outElement;
  output Env.Env outAccumEnv;
algorithm
  (outElement, outAccumEnv) :=
  match(inElement, inEnclosingEnv, inClsAndVars, inAccumEnv, inClassName,
      inAccumPath, inCollectConstants)
    local
      SCode.Ident name;
      SCode.Element cls;
      Env.Env env;
      Item item;
      Absyn.Path cls_path, const_path;

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
  item = Env.avlTreeGet(inClsAndVars, name);
  true = inCollectConstants or FEnv.isItemUsed(item);
  env = FEnv.extendEnvWithItem(item, inAccumEnv, name);
      then
  (inElement, env);

    // Class components are always collected, regardless of whether they are
    // used or not.
    case (SCode.COMPONENT(name = name), _, _, _, _, _, _)
      equation
  item = FEnv.newVarItem(inElement, true);
  env = FEnv.extendEnvWithItem(item, inAccumEnv, name);
      then
  (inElement, env);

    else (inElement, inAccumEnv);

  end match;
end collectUsedElement;

protected function removeUnusedRedeclares
  "An unused element might be redeclared, but it's still not actually used. This
   function removes such redeclares from extends clauses, so that it's safe to
   remove those elements."
  input Env.Env inEnv;
  input Env.Env inTotalEnv;
  output Env.Env outEnv;
protected
  Option<String> name;
  Option<ScopeType> st;
  FrameType ty;
  AvlTree cv;
  AvlTree tys;
  CSetsType cs;
  list<SCode.Element> du;
  ExtendsTable exts;
  ImportTable imps;
  Option<Util.StatefulBoolean> is_used;
  list<Env.Extends> bcl;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
  Env.Env env;
algorithm
  {Env.FRAME(name, st, ty, cv, tys, cs, du, Env.EXTENDS_TABLE(bcl, re, cei),
    imps, is_used)} := inEnv;
  env := FEnv.removeRedeclaresFromLocalScope(inTotalEnv);
  bcl := List.map1(bcl, removeUnusedRedeclares2, env);
  outEnv := {Env.FRAME(name, st, ty, cv, tys, cs, du,
    Env.EXTENDS_TABLE(bcl, re, cei), imps, is_used)};
end removeUnusedRedeclares;

protected function removeUnusedRedeclares2
  input Env.Extends inExtends;
  input Env.Env inEnv;
  output Env.Extends outExtends;
protected
  Absyn.Path bc;
  list<Env.Redeclaration> redeclares;
  Integer index;
  Absyn.Info info;
  Env.Env env;
algorithm
  Env.EXTENDS(bc, redeclares, index, info) := inExtends;
  redeclares := List.filter1(redeclares, removeUnusedRedeclares3, inEnv);
  outExtends := Env.EXTENDS(bc, redeclares, index, info);
end removeUnusedRedeclares2;

protected function removeUnusedRedeclares3
  input Env.Redeclaration inRedeclare;
  input Env.Env inEnv;
protected
  String name;
  Item item;
algorithm
  (name, _) := FEnv.getRedeclarationNameInfo(inRedeclare);
  (item, _, _) := FLookup.lookupSimpleName(name, inEnv);
  true := FEnv.isItemUsed(item);
end removeUnusedRedeclares3;

end FDependency;
