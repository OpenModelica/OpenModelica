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

encapsulated package FEnv
" file:  FEnv.mo
  package:     FEnv
  description: SCode flattening

  RCS: $Id: FEnv.mo 14085 2012-11-27 12:12:40Z adrpo $

  This module flattens the SCode representation by removing all extends, imports
  and redeclares, and fully qualifying class names.
"

public import Absyn;
public import SCode;
public import Util;
public import Env;
public import DAE;

public type Item = Env.Item;
public type AvlTree = .Env.AvlTree;
public type AvlTreeValue = .Env.AvlTreeValue;
public type ImportTable = .Env.ImportTable;
public type ExtendsTable = .Env.ExtendsTable;
public type Frame = .Env.Frame;
public type Redeclaration = .Env.Redeclaration;
public type Extends = .Env.Extends;
public type ClassType = .Env.ClassType;
public type FrameType = .Env.FrameType;
public type CSetsType = .Env.CSetsType;
public type ScopeType = .Env.ScopeType;
public type Import = .Env.Import;
public type Ident = Absyn.Ident;

protected import FEnvExtends;
protected import Error;
protected import List;
protected import SCodeDump;
protected import FFlattenRedeclare;
protected import FLookup;
protected import FSCodeCheck;
protected import SCodeUtil;
protected import System;
protected import DAEUtil;

public function newEnvironment
  "Returns a new environment with only one frame."
  input Option<SCode.Ident> inName;
  output Env.Env outEnv;
protected
  Frame new_frame;
algorithm
  new_frame := Env.newFrame(inName, NONE(), Env.NORMAL_SCOPE());
  outEnv := {new_frame};
end newEnvironment;

protected function openScope
  "Open a new class scope in the environment by adding a new frame for the given
  class."
  input Env.Env inEnv;
  input SCode.Element inClass;
  output Env.Env outEnv;
protected
  String name;
  SCode.Encapsulated encapsulatedPrefix;
  Frame new_frame;
algorithm
  SCode.CLASS(name = name, encapsulatedPrefix = encapsulatedPrefix) := inClass;
  new_frame := Env.newFrame(SOME(name), NONE(), getFrameType(encapsulatedPrefix));
  outEnv := new_frame :: inEnv;
end openScope;

public function enterScope
  "Enters a new scope in the environment by looking up an item in the
  environment and appending it's frame to the environment."
  input Env.Env inEnv;
  input SCode.Ident inName;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(inEnv, inName)
    local
      Frame cls_env;
      AvlTree cls_and_vars;
      Item item;

    case (_, _)
      equation
  /*********************************************************************/
  // TODO: Should we use the environment returned by lookupInClass?
  /*********************************************************************/
  (item, _) = FLookup.lookupInClass(inName, inEnv);
  {cls_env} = getItemEnv(item);
  outEnv = enterFrame(cls_env, inEnv);
      then
  outEnv;

    case (_, _)
      equation
  print("Failed to enterScope: " +& inName +& " in env: " +& Env.printEnvStr(inEnv) +& "\n");
      then
  fail();
  end matchcontinue;
end enterScope;

public function enterScopePath
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Env outEnv;
algorithm
  outEnv := match(inEnv, inPath)
    local
      Absyn.Ident name;
      Absyn.Path path;
      Env.Env env;

    case (_, Absyn.QUALIFIED(name = name, path = path))
      equation
  env = enterScope(inEnv, name);
      then
  enterScopePath(env, path);

    case (_, Absyn.IDENT(name = name))
      then enterScope(inEnv, name);

    case (_, Absyn.FULLYQUALIFIED(path = path))
      equation
  env = getEnvTopScope(inEnv);
      then
  enterScopePath(env, path);

  end match;
end enterScopePath;

public function enterFrame
  input Frame inFrame;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := inFrame :: inEnv;
end enterFrame;

public function getEnvTopScope
  "Returns the top scope, i.e. last frame in the environment."
  input Env.Env inEnv;
  output Env.Env outEnv;
protected
  Frame top_scope;
  Env.Env env;
algorithm
  env := listReverse(inEnv);
  top_scope :: _ := env;
  outEnv := {top_scope};
end getEnvTopScope;

protected function getFrameType
  "Returns a new FrameType given if the frame should be encapsulated or not."
  input SCode.Encapsulated encapsulatedPrefix;
  output FrameType outType;
algorithm
  outType := match(encapsulatedPrefix)
    case SCode.ENCAPSULATED() then Env.ENCAPSULATED_SCOPE();
    else then Env.NORMAL_SCOPE();
  end match;
end getFrameType;

public function newItem
  input SCode.Element inElement;
  output Item outItem;
algorithm
  outItem := match(inElement)
    local
      Env.Env class_env;
      Item item;

    case SCode.CLASS(name = _)
      equation
  class_env = makeClassEnvironment(inElement, true);
  item = newClassItem(inElement, class_env, Env.USERDEFINED());
      then
  item;

    case SCode.COMPONENT(name = _) then newVarItem(inElement, false);

  end match;
end newItem;

public function newClassItem
  "Creates a new class environment item."
  input SCode.Element inClass;
  input Env.Env inEnv;
  input ClassType inClassType;
  output Item outClassItem;
algorithm
  outClassItem := Env.CLASS(inClass, inEnv, inClassType);
end newClassItem;

public function newVarItem
  "Creates a new variable environment item."
  input SCode.Element inVar;
  input Boolean inIsUsed;
  output Item outVarItem;
protected
  Util.StatefulBoolean is_used;
  DAE.Var daeVar;
algorithm
  is_used := Util.makeStatefulBoolean(inIsUsed);
  daeVar := DAEUtil.mkEmptyVar(SCode.elementName(inVar));
  outVarItem := Env.VAR(daeVar, inVar, DAE.NOMOD(), Env.VAR_UNTYPED(), {}, SOME(is_used));
end newVarItem;

public function extendEnvWithClasses
  "Extends the environment with a list of classes."
  input list<SCode.Element> inClasses;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := List.fold(inClasses, extendEnvWithClass, inEnv);
end extendEnvWithClasses;

protected function extendEnvWithClass
  "Extends the environment with a class."
  input SCode.Element inClass;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := extendEnvWithClassDef(inClass, inEnv);
end extendEnvWithClass;

public function getClassType
  "Returns a class's type."
  input SCode.ClassDef inClassDef;
  output ClassType outType;
algorithm
  outType := match(inClassDef)
    // A builtin class.
    case (SCode.PARTS(externalDecl = SOME(SCode.EXTERNALDECL(
  lang = SOME("builtin")))))
      then Env.BUILTIN();
    // A user-defined class (i.e. not builtin).
    else then Env.USERDEFINED();
  end match;
end getClassType;

public function printClassType
  input ClassType inClassType;
  output String outString;
algorithm
  outString := match(inClassType)
    case Env.BUILTIN() then "BUILTIN";
    case Env.CLASS_EXTENDS() then "CLASS_EXTENDS";
    case Env.USERDEFINED() then "USERDEFINED";
    case Env.BASIC_TYPE() then "BASIC_TYPE";
  end match;
end printClassType;

public function removeExtendsFromLocalScope
  "Removes all extends from the local scope, i.e. inserts a new empty
  extends-table into the first frame."
  input Env.Env inEnv;
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
  Env.Env rest;
algorithm
  Env.FRAME(name, st, ty, cv, tys, cs, du, exts, imps, is_used) :: rest := inEnv;
  exts := Env.newExtendsTable();
  outEnv := Env.FRAME(name, st, ty, cv, tys, cs, du, exts, imps, is_used) :: rest;
end removeExtendsFromLocalScope;

public function removeExtendFromLocalScope
  "Removes a given extends clause from the local scope."
  input Absyn.Path inExtend;
  input Env.Env inEnv;
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
  Option<Util.StatefulBoolean> iu;
  Env.Env rest;
  list<Extends> bcl;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
algorithm
  Env.FRAME(name, st, ty, cv, tys, cs, du,
    Env.EXTENDS_TABLE(baseClasses = bcl, redeclaredElements = re, classExtendsInfo = cei),
    imps, iu) :: rest := inEnv;
  (bcl, _) := List.deleteMemberOnTrue(inExtend, bcl, isExtendNamed);
  outEnv := Env.FRAME(name, st, ty, cv, tys, cs, du, Env.EXTENDS_TABLE(bcl, re, cei), imps, iu) :: rest;
end removeExtendFromLocalScope;

protected function isExtendNamed
  input Absyn.Path inName;
  input Extends inExtends;
  output Boolean outIsNamed;
protected
  Absyn.Path bc;
algorithm
  Env.EXTENDS(baseClass = bc) := inExtends;
  outIsNamed := Absyn.pathEqual(inName, bc);
end isExtendNamed;

public function removeRedeclaresFromLocalScope
  input Env.Env inEnv;
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
  Env.Env rest;
  list<Extends> bc;
  Option<SCode.Element> cei;
algorithm
  Env.FRAME(name, st, ty, cv, tys, cs, du,
    Env.EXTENDS_TABLE(baseClasses = bc, classExtendsInfo = cei),
    imps, is_used) :: rest := inEnv;
  bc := List.map(bc, removeRedeclaresFromExtend);
  exts := Env.EXTENDS_TABLE(bc, {}, cei);
  outEnv := Env.FRAME(name, st, ty, cv, tys, cs, du, exts, imps, is_used) :: rest;
end removeRedeclaresFromLocalScope;

protected function removeRedeclaresFromExtend
  input Extends inExtend;
  output Extends outExtend;
protected
  Absyn.Path bc;
  Integer index;
  Absyn.Info info;
algorithm
  Env.EXTENDS(bc, _, index, info) := inExtend;
  outExtend := Env.EXTENDS(bc, {}, index, info);
end removeRedeclaresFromExtend;

public function removeClsAndVarsFromFrame
  "Removes the classes variables from a frame."
  input Frame inFrame;
  output Frame outFrame;
  output AvlTree outClsAndVars;
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
algorithm
  Env.FRAME(name, st, ty, cv, tys, cs, du, exts, imps, is_used) := inFrame;
  outClsAndVars := cv;
  cv := Env.avlTreeNew();
  outFrame := Env.FRAME(name, st, ty, cv, tys, cs, du, exts, imps, is_used);
end removeClsAndVarsFromFrame;

public function setImportTableHidden
  "Sets the 'hidden' flag in the import table in the local scope of the given
  environment."
  input Env.Env inEnv;
  input Boolean inHidden;
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
  Env.Env rest;
  list<Import> qi, uqi;
algorithm
  Env.FRAME(name, st, ty, cv, tys, cs, du, exts,
      Env.IMPORT_TABLE(_, qi, uqi),
      is_used) :: rest := inEnv;
  outEnv := Env.FRAME(
        name, st, ty, cv, tys, cs, du, exts,
        Env.IMPORT_TABLE(inHidden, qi, uqi),
        is_used) :: rest;
end setImportTableHidden;

public function setImportsInItemHidden
  "Sets the 'hidden' flag in the import table for the given items environment if
  the item is a class. Otherwise does nothing."
  input Item inItem;
  input Boolean inHidden;
  output Item outItem;
algorithm
  outItem := match(inItem, inHidden)
    local
      SCode.Element cls;
      Env.Env env;
      ClassType cls_ty;

    case (Env.CLASS(cls = cls, env = env, classType = cls_ty), _)
      equation
  env = setImportTableHidden(env, inHidden);
      then
  Env.CLASS(cls, env, cls_ty);

    else inItem;
  end match;
end setImportsInItemHidden;

public function isItemUsed
  "Checks if an item is used or not."
  input Item inItem;
  output Boolean isUsed;
algorithm
  isUsed := match(inItem)
    local
      Util.StatefulBoolean is_used;
      Item item;

    case Env.CLASS(env = {Env.FRAME(isUsed = SOME(is_used))})
      then Util.getStatefulBoolean(is_used);

    case Env.VAR(isUsed = SOME(is_used))
      then Util.getStatefulBoolean(is_used);

    case Env.ALIAS(name = _) then true;

    case Env.REDECLARED_ITEM(item = item) then isItemUsed(item);

    else false;
  end match;
end isItemUsed;

public function linkItemUsage
"'Links' two items to each other, by making them share the same isUsed variable."
  input Item inSrcItem;
  input Item inDestItem;
  output Item outDestItem;
algorithm
  outDestItem := match(inSrcItem, inDestItem)
    local
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
      SCode.Element elem;
      DAE.Var daeVar;
      ClassType cls_ty;
      Env.Env env;
      Item item;

    case (Env.VAR(isUsed = is_used), Env.VAR(var = elem))
      equation
  daeVar = DAEUtil.mkEmptyVar(SCode.elementName(elem));
      then
  Env.VAR(daeVar, elem, DAE.NOMOD(), Env.VAR_UNTYPED(), {}, is_used);

    case (Env.CLASS(env = {Env.FRAME(isUsed = is_used)}),
  Env.CLASS(cls = elem, classType = cls_ty, env =
    {Env.FRAME(name, st, ty, cv, tys, cs, du, exts, imps, _)}))
      then
  Env.CLASS(
    elem,
    {Env.FRAME(name, st, ty, cv, tys, cs, du, exts, imps, is_used)},
    cls_ty);

    case (_, Env.REDECLARED_ITEM(item, env))
      equation
  item = linkItemUsage(inSrcItem, item);
      then
  Env.REDECLARED_ITEM(item, env);

    else inDestItem;
  end match;
end linkItemUsage;

public function isClassItem
  input Item inItem;
  output Boolean outIsClass;
algorithm
  outIsClass := match(inItem)
    local
      Item item;

    case Env.CLASS(cls = _) then true;
    case Env.REDECLARED_ITEM(item = item) then isClassItem(item);
    else false;
  end match;
end isClassItem;

public function isVarItem
  input Item inItem;
  output Boolean outIsVar;
algorithm
  outIsVar := match(inItem)
    local Item item;
    case Env.VAR(var = _) then true;
    case Env.REDECLARED_ITEM(item = item) then isVarItem(item);
    else false;
  end match;
end isVarItem;

public function isClassExtendsItem
  input Item inItem;
  output Boolean outIsClassExtends;
algorithm
  outIsClassExtends := match(inItem)
    local Item item;
    case Env.CLASS(classType = Env.CLASS_EXTENDS()) then true;
    case Env.REDECLARED_ITEM(item = item) then isClassExtendsItem(item);
    else false;
  end match;
end isClassExtendsItem;

protected function extendEnvWithClassDef
  "Extends the environment with a class definition."
  input SCode.Element inClassDefElement;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := match(inClassDefElement, inEnv)
    local
      String cls_name, alias_name;
      Env.Env class_env, env;
      SCode.ClassDef cdef;
      ClassType cls_type;
      Absyn.Info info;

    // A class extends.
    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = _)), _)
      then
  FEnvExtends.extendEnvWithClassExtends(inClassDefElement, inEnv);

    case (SCode.CLASS(name = cls_name, classDef = cdef, prefixes = SCode.PREFIXES(
  replaceablePrefix = SCode.REPLACEABLE(_)), info = info), _)
      equation
  class_env = makeClassEnvironment(inClassDefElement, false);
  cls_type = getClassType(cdef);
  alias_name = cls_name +& Env.BASE_CLASS_SUFFIX;
  env = extendEnvWithItem(newClassItem(inClassDefElement, class_env, cls_type),
    inEnv, alias_name);
  env = extendEnvWithItem(Env.ALIAS(alias_name, NONE(), info), env, cls_name);
      then
  env;

    // A normal class.
    case (SCode.CLASS(name = cls_name, classDef = cdef), _)
      equation
  // Create a new environment and add the class's components to it.
  class_env = makeClassEnvironment(inClassDefElement, false);
  cls_type = getClassType(cdef);
  // Add the class with it's environment to the environment.
  env = extendEnvWithItem(newClassItem(inClassDefElement, class_env, cls_type),
    inEnv, cls_name);
      then
  env;
  end match;
end extendEnvWithClassDef;

public function makeClassEnvironment
  input SCode.Element inClassDefElement;
  input Boolean inInModifierScope;
  output Env.Env outClassEnv;
protected
  SCode.ClassDef cdef;
  SCode.Element cls;
  String cls_name;
  Env.Env env, enclosing_env;
  Absyn.Info info;
algorithm
  SCode.CLASS(name = cls_name, classDef = cdef, info = info) := inClassDefElement;
  env := openScope(Env.emptyEnv, inClassDefElement);
  enclosing_env := Util.if_(inInModifierScope, Env.emptyEnv, env);
  outClassEnv := extendEnvWithClassComponents(cls_name, cdef, env, enclosing_env, info);
end makeClassEnvironment;

protected function extendEnvWithVar
  "Extends the environment with a variable."
  input SCode.Element inVar;
  input Env.Env inEnv;
  output Env.Env outEnv;
protected
  String var_name;
  Util.StatefulBoolean is_used;
  DAE.Var daeVar;
algorithm
  SCode.COMPONENT(name = var_name) := inVar;
  daeVar := DAEUtil.mkEmptyVar(var_name);
  is_used := Util.makeStatefulBoolean(false);
  outEnv := extendEnvWithItem(
    Env.VAR(
      daeVar,
      inVar,
      DAE.NOMOD(),
      Env.VAR_UNTYPED(),
      {},
      SOME(is_used)),
    inEnv, var_name);
end extendEnvWithVar;

public function extendEnvWithItem
  "Extends the environment with an environment item."
  input Item inItem;
  input Env.Env inEnv;
  input String inItemName;
  output Env.Env outEnv;
protected
  Option<String> name;
  Option<ScopeType> st;
  FrameType ty;
  AvlTree clsAndVars;
  AvlTree tys;
  CSetsType cs;
  list<SCode.Element> du;
  ExtendsTable exts;
  ImportTable imps;
  Option<Util.StatefulBoolean> is_used;
  Env.Env rest;
algorithm
  Env.FRAME(name, st, ty, clsAndVars, tys, cs, du, exts, imps, is_used) :: rest := inEnv;
  clsAndVars := Env.avlTreeAdd(clsAndVars, inItemName, inItem);
  outEnv := Env.FRAME(name, st, ty, clsAndVars, tys, cs, du, exts, imps, is_used) :: rest;
end extendEnvWithItem;

public function updateItemInEnv
  "Updates an item in the environment by replacing an existing item."
  input Item inItem;
  input Env.Env inEnv;
  input String inItemName;
  output Env.Env outEnv;
protected
  Option<String> name;
  Option<ScopeType> st;
  FrameType ty;
  AvlTree clsAndVars;
  AvlTree tys;
  CSetsType cs;
  list<SCode.Element> du;
  ExtendsTable exts;
  ImportTable imps;
  Option<Util.StatefulBoolean> is_used;
  Env.Env rest;
algorithm
  Env.FRAME(name, st, ty, clsAndVars, tys, cs, du, exts, imps, is_used) :: rest := inEnv;
  clsAndVars := Env.avlTreeReplace(clsAndVars, inItemName, inItem);
  outEnv := Env.FRAME(name, st, ty, clsAndVars, tys, cs, du, exts, imps, is_used) :: rest;
end updateItemInEnv;

public function extendEnvWithImport
  "Extends the environment with an import element."
  input SCode.Element inImport;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := match(inImport, inEnv)
    local
      Option<Ident> id;
      Option<ScopeType> st;
      FrameType ft;
      AvlTree clsAndVars,tys;
      CSetsType crs;
      list<SCode.Element> du;
      ExtendsTable et;
      Option<Util.StatefulBoolean> iu;
      Env.Env rest;
      Import imp;
      list<Import> qual_imps, unqual_imps;
      Absyn.Info info;
      Boolean hidden;

    // Unqualified imports
    case (SCode.IMPORT(imp = imp as Absyn.UNQUAL_IMPORT(path = _)),
    Env.FRAME(id,st,ft,clsAndVars,tys,crs,du,et,
      Env.IMPORT_TABLE(hidden, qual_imps, unqual_imps),
      iu) :: rest)
      equation
  unqual_imps = imp :: unqual_imps;
      then
  Env.FRAME(id,st,ft,clsAndVars,tys,crs,du,et,
    Env.IMPORT_TABLE(hidden, qual_imps, unqual_imps), iu) :: rest;

    // Qualified imports
    case (SCode.IMPORT(imp = imp, info = info),
    Env.FRAME(id,st,ft,clsAndVars,tys,crs,du,et,
      Env.IMPORT_TABLE(hidden, qual_imps, unqual_imps),
      iu) :: rest)
      equation
  imp = translateQualifiedImportToNamed(imp);
  checkUniqueQualifiedImport(imp, qual_imps, info);
  qual_imps = imp :: qual_imps;
      then
  Env.FRAME(id,st,ft,clsAndVars,tys,crs,du,et,
    Env.IMPORT_TABLE(hidden, qual_imps, unqual_imps), iu) :: rest;
  end match;
end extendEnvWithImport;

protected function translateQualifiedImportToNamed
  "Translates a qualified import to a named import."
  input Import inImport;
  output Import outImport;
algorithm
  outImport := match(inImport)
    local
      Absyn.Ident name;
      Absyn.Path path;

    // Already named.
    case Absyn.NAMED_IMPORT(name = _) then inImport;

    // Get the last identifier from the import and use that as the name.
    case Absyn.QUAL_IMPORT(path = path)
      equation
  name = Absyn.pathLastIdent(path);
      then
  Absyn.NAMED_IMPORT(name, path);
  end match;
end translateQualifiedImportToNamed;

public function extendEnvWithExtends
  "Extends the environment with an extends-clause."
  input SCode.Element inExtends;
  input Env.Env inEnv;
  output Env.Env outEnv;
protected
  Absyn.Path bc;
  SCode.Mod mods;
  list<Redeclaration> redecls;
  Absyn.Info info;
  Env.Env env;
  Integer index;
algorithm
  SCode.EXTENDS(baseClassPath = bc, modifications = mods, info = info) :=
    inExtends;
  redecls := FFlattenRedeclare.extractRedeclaresFromModifier(mods);
  index := System.tmpTickIndex(Env.extendsTickIndex);
  outEnv := addExtendsToEnvExtendsTable(Env.EXTENDS(bc, redecls, index, info), inEnv);
end extendEnvWithExtends;

protected function addExtendsToEnvExtendsTable
  "Adds an Extents to the environment."
  input Extends inExtends;
  input Env.Env inEnv;
  output Env.Env outEnv;
protected
  list<Extends> exts;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
algorithm
  Env.EXTENDS_TABLE(exts, re, cei) := getEnvExtendsTable(inEnv);
  exts := inExtends :: exts;
  outEnv := setEnvExtendsTable(Env.EXTENDS_TABLE(exts, re, cei), inEnv);
end addExtendsToEnvExtendsTable;

protected function addElementRedeclarationToEnvExtendsTable
  input SCode.Element inRedeclare;
  input Env.Env inEnv;
  output Env.Env outEnv;
protected
  list<Extends> exts;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
algorithm
  Env.EXTENDS_TABLE(exts, re, cei) := getEnvExtendsTable(inEnv);
  re := inRedeclare :: re;
  outEnv := setEnvExtendsTable(Env.EXTENDS_TABLE(exts, re, cei), inEnv);
end addElementRedeclarationToEnvExtendsTable;

protected function extendEnvWithClassComponents
  "Extends the environment with a class's components."
  input String inClassName;
  input SCode.ClassDef inClassDef;
  input Env.Env inEnv;
  input Env.Env inEnclosingScope;
  input Absyn.Info inInfo;
  output Env.Env outEnv;
algorithm
  outEnv := match(inClassName, inClassDef, inEnv, inEnclosingScope, inInfo)
    local
      list<SCode.Element> el;
      list<SCode.Enum> enums;
      Absyn.TypeSpec ty;
      Env.Env env;
      SCode.Mod mods;
      Absyn.Path path;

    case (_, SCode.PARTS(elementLst = el), _, _, _)
      equation
  env = List.fold(el, extendEnvWithElement, inEnv);
      then
  env;

    case (_, SCode.DERIVED(typeSpec = ty as Absyn.TPATH(path = path),
  modifications = mods), _, _, _)
      equation
  FSCodeCheck.checkRecursiveShortDefinition(ty, inClassName,
    inEnclosingScope, inInfo);
  env = extendEnvWithExtends(SCode.EXTENDS(path, SCode.PUBLIC(), mods,
    NONE(), inInfo), inEnv);
      then
  env;

    case (_, SCode.ENUMERATION(enumLst = enums), _, _, _)
      equation
  path = Absyn.IDENT(inClassName);
  env = extendEnvWithEnumLiterals(enums, path, 1, inEnv);
      then
  env;

    else inEnv;
  end match;
end extendEnvWithClassComponents;

protected function extendEnvWithElement
  "Extends the environment with a class element."
  input SCode.Element inElement;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(inElement, inEnv)
    local
      Env.Env env;
      SCode.Ident name;

    // redeclare-as-element component
    case (SCode.COMPONENT(name = _, prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE())), _)
      equation
  env = addElementRedeclarationToEnvExtendsTable(inElement, inEnv);
  env = extendEnvWithVar(inElement, env);
      then
  env;

    // normal component
    case (SCode.COMPONENT(name = _), _)
      equation
  env = extendEnvWithVar(inElement, inEnv);
      then
  env;

    // redeclare-as-element class
    case (SCode.CLASS(name = name, prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE())), _)
      equation
  env = addElementRedeclarationToEnvExtendsTable(inElement, inEnv);
  env = extendEnvWithClassDef(inElement, env);
      then
  env;

    // normal class
    case (SCode.CLASS(name = _), _)
      equation
  env = extendEnvWithClassDef(inElement, inEnv);
      then
  env;

    case (SCode.EXTENDS(baseClassPath = _), _)
      equation
  env = extendEnvWithExtends(inElement, inEnv);
      then
  env;

    case (SCode.IMPORT(imp = _), _)
      equation
  env = extendEnvWithImport(inElement, inEnv);
      then
  env;

    case (SCode.DEFINEUNIT(name = _), _)
      then inEnv;

  end matchcontinue;
end extendEnvWithElement;

protected function checkUniqueQualifiedImport
  "Checks that a qualified import is unique, because it's not allowed to have
  qualified imports with the same name."
  input Import inImport;
  input list<Import> inImports;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inImport, inImports, inInfo)
    local
      Absyn.Ident name;

    case (_, _, _)
      equation
  false = List.isMemberOnTrue(inImport, inImports,
    compareQualifiedImportNames);
      then
  ();

    case (Absyn.NAMED_IMPORT(name = name), _, _)
      equation
  Error.addSourceMessage(Error.MULTIPLE_QUALIFIED_IMPORTS_WITH_SAME_NAME,
    {name}, inInfo);
      then
  fail();

  end matchcontinue;
end checkUniqueQualifiedImport;

protected function compareQualifiedImportNames
  "Compares two qualified imports, returning true if they have the same import
  name, otherwise false."
  input Import inImport1;
  input Import inImport2;
  output Boolean outEqual;
algorithm
  outEqual := matchcontinue(inImport1, inImport2)
    local
      Absyn.Ident name1, name2;

    case (Absyn.NAMED_IMPORT(name = name1), Absyn.NAMED_IMPORT(name = name2))
      equation
  true = stringEqual(name1, name2);
      then
  true;

    else then false;
  end matchcontinue;
end compareQualifiedImportNames;

protected function extendEnvWithEnumLiterals
  input list<SCode.Enum> inEnum;
  input Absyn.Path inEnumPath;
  input Integer inNextValue;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := match(inEnum, inEnumPath, inNextValue, inEnv)
    local
      SCode.Enum lit;
      list<SCode.Enum> rest_lits;
      Env.Env env;

    case (lit :: rest_lits, _, _, _)
      equation
  env = extendEnvWithEnum(lit, inEnumPath, inNextValue, inEnv);
      then
  extendEnvWithEnumLiterals(rest_lits, inEnumPath, inNextValue + 1, env);

    case ({}, _, _, _) then inEnv;

  end match;
end extendEnvWithEnumLiterals;

protected function extendEnvWithEnum
  "Extends the environment with an enumeration."
  input SCode.Enum inEnum;
  input Absyn.Path inEnumPath;
  input Integer inValue;
  input Env.Env inEnv;
  output Env.Env outEnv;
protected
  SCode.Element enum_lit;
  SCode.Ident lit_name;
  Absyn.TypeSpec ty;
  String index;
algorithm
  SCode.ENUM(literal = lit_name) := inEnum;
  index := intString(inValue);
  ty := Absyn.TPATH(Absyn.QUALIFIED("$EnumType",
    Absyn.QUALIFIED(index, inEnumPath)), NONE());
  enum_lit := SCode.COMPONENT(lit_name, SCode.defaultPrefixes, SCode.ATTR({},
    SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.CONST(), Absyn.BIDIR()), ty,
    SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);
  outEnv := extendEnvWithElement(enum_lit, inEnv);
end extendEnvWithEnum;

public function extendEnvWithIterators
  "Extends the environment with a new scope and adds a list of iterators to it."
  input Absyn.ForIterators inIterators;
  input Integer iterIndex;
  input Env.Env inEnv;
  output Env.Env outEnv;
protected
  Frame frame;
algorithm
  frame := Env.newFrame(SOME("$for$"), NONE(), Env.IMPLICIT_SCOPE(iterIndex));
  outEnv := List.fold(inIterators, extendEnvWithIterator, frame :: inEnv);
end extendEnvWithIterators;

protected function extendEnvWithIterator
  "Extends the environment with an iterator."
  input Absyn.ForIterator inIterator;
  input Env.Env inEnv;
  output Env.Env outEnv;
protected
  Absyn.Ident iter_name;
  SCode.Element iter;
algorithm
  Absyn.ITERATOR(name=iter_name) := inIterator;
  iter := SCode.COMPONENT(iter_name, SCode.defaultPrefixes,
    SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.CONST(), Absyn.BIDIR()),
    Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
    SCode.noComment, NONE(), Absyn.dummyInfo);
  outEnv := extendEnvWithElement(iter, inEnv);
end extendEnvWithIterator;

public function extendEnvWithMatch
  "Extends the environment with a match-expression, i.e. opens a new scope and
  adds the local declarations in the match to it."
  input Absyn.Exp inMatchExp;
  input Integer iterIndex;
  input Env.Env inEnv;
  output Env.Env outEnv;
protected
  Frame frame;
  list<Absyn.ElementItem> local_decls;
algorithm
  frame := Env.newFrame(SOME("$match$"), NONE(), Env.IMPLICIT_SCOPE(iterIndex));
  Absyn.MATCHEXP(localDecls = local_decls) := inMatchExp;
  outEnv := List.fold(local_decls, extendEnvWithElementItem,
    frame :: inEnv);
end extendEnvWithMatch;

protected function extendEnvWithElementItem
  "Extends the environment with an Absyn.ElementItem."
  input Absyn.ElementItem inElementItem;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := match(inElementItem, inEnv)
    local
      Absyn.Element element;
      list<SCode.Element> el;
      Env.Env env;

    case (Absyn.ELEMENTITEM(element = element), _)
      equation
  // Translate the element item to a SCode element.
  el = SCodeUtil.translateElement(element, SCode.PROTECTED());
  env = List.fold(el, extendEnvWithElement, inEnv);
      then
  env;

    else then inEnv;
  end match;
end extendEnvWithElementItem;

public function getEnvName
  "Returns the environment path as a string."
  input Env.Env inEnv;
  output String outString;
algorithm
  outString := matchcontinue(inEnv)
    local
      String str;

    case _
      equation
  str = Absyn.pathString(getEnvPath(inEnv));
      then
  str;

    else then "";
  end matchcontinue;
end getEnvName;

public function getEnvPath
  "Returns the environment path. Fails for an empty environment or the top
  scope, which can't be represented as an Absyn.Path."
  input Env.Env inEnv;
  output Absyn.Path outPath;
algorithm
  outPath := match(inEnv)
    local
      String name;
      Absyn.Path path;
      Env.Env rest;

    case (Env.FRAME(frameType = Env.IMPLICIT_SCOPE(iterIndex=_)) :: rest)
      then getEnvPath(rest);

    case ({Env.FRAME(name = SOME(name))})
      then Absyn.IDENT(name);

    case ({Env.FRAME(name = SOME(name)), Env.FRAME(name = NONE())})
      then Absyn.IDENT(name);

    case (Env.FRAME(name = SOME(name)) :: rest)
      equation
  path = getEnvPath(rest);
  path = Absyn.joinPaths(path, Absyn.IDENT(name));
      then
  path;
  end match;
end getEnvPath;

public function getScopeName
  "Returns the name of the innermost that has a name."
  input Env.Env inEnv;
  output String outString;
algorithm
  outString := match(inEnv)
    local
      String name;
      Env.Env rest;

    case Env.FRAME(name = SOME(name)) :: _ then name;
    case _ :: rest then getScopeName(rest);

  end match;
end getScopeName;

public function envPrefixOf
  input Env.Env inPrefixEnv;
  input Env.Env inEnv;
  output Boolean outIsPrefix;
algorithm
  outIsPrefix := envPrefixOf2(listReverse(inPrefixEnv), listReverse(inEnv));
end envPrefixOf;

public function envPrefixOf2
  "Checks if one environment is a prefix of another."
  input Env.Env inPrefixEnv;
  input Env.Env inEnv;
  output Boolean outIsPrefix;
algorithm
  outIsPrefix := matchcontinue(inPrefixEnv, inEnv)
    local
      String n1, n2;
      Env.Env rest1, rest2;

    case ({}, _) then true;

    case (Env.FRAME(name = NONE()) :: rest1, Env.FRAME(name = NONE()) :: rest2)
      then envPrefixOf2(rest1, rest2);

    case (Env.FRAME(name = SOME(n1)) :: rest1, Env.FRAME(name = SOME(n2)) :: rest2)
      equation
  true = stringEqual(n1, n2);
      then
  envPrefixOf2(rest1, rest2);

    else false;
  end matchcontinue;
end envPrefixOf2;

public function envScopeNames
  input Env.Env inEnv;
  output list<String> outNames;
algorithm
  outNames := envScopeNames2(inEnv, {});
end envScopeNames;

public function envScopeNames2
  input Env.Env inEnv;
  input list<String> inAccumNames;
  output list<String> outNames;
algorithm
  outNames := match(inEnv, inAccumNames)
    local
      String name;
      Env.Env rest_env;
      list<String> names;

    case (Env.FRAME(name = SOME(name)) :: rest_env, _)
      equation
  names = envScopeNames2(rest_env, name :: inAccumNames);
      then
  names;

    case (Env.FRAME(name = NONE()) :: rest_env, _)
      then envScopeNames2(rest_env, inAccumNames);

    case ({}, _) then inAccumNames;

  end match;
end envScopeNames2;

public function envEqualPrefix
  input Env.Env inEnv1;
  input Env.Env inEnv2;
  output Env.Env outPrefix;
algorithm
  outPrefix := envEqualPrefix2(listReverse(inEnv1), listReverse(inEnv2), {});
end envEqualPrefix;

public function envEqualPrefix2
  input Env.Env inEnv1;
  input Env.Env inEnv2;
  input Env.Env inAccumEnv;
  output Env.Env outPrefix;
algorithm
  outPrefix := matchcontinue(inEnv1, inEnv2, inAccumEnv)
    local
      String name1, name2;
      Env.Env env, rest_env1, rest_env2;
      Frame frame;

    case ((frame as Env.FRAME(name = SOME(name1))) :: rest_env1,
    Env.FRAME(name = SOME(name2)) :: rest_env2, _)
      equation
  true = stringEq(name1, name2);
  env = envEqualPrefix2(rest_env1, rest_env2, frame :: inAccumEnv);
      then
  env;

    case (Env.FRAME(name = NONE()) :: rest_env1, Env.FRAME(name = NONE()) :: rest_env2, _)
      then envEqualPrefix2(rest_env1, rest_env2, inAccumEnv);

    else inAccumEnv;

  end matchcontinue;
end envEqualPrefix2;

public function getItemInfo
  "Returns the Absyn.Info of an environment item."
  input Item inItem;
  output Absyn.Info outInfo;
algorithm
  outInfo := match(inItem)
    local Absyn.Info info; Item item;
    case Env.VAR(var = SCode.COMPONENT(info = info)) then info;
    case Env.CLASS(cls = SCode.CLASS(info = info)) then info;
    case Env.ALIAS(info = info) then info;
    case Env.REDECLARED_ITEM(item = item) then getItemInfo(item);
    case Env.TYPE(tys = _) then Absyn.dummyInfo;
  end match;
end getItemInfo;

public function itemStr
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

    case Env.VAR(var = el)
      then SCodeDump.unparseElementStr(el);
    case Env.CLASS(cls = el)
      then SCodeDump.unparseElementStr(el);
    case Env.ALIAS(name = name, path = SOME(path))
      equation
  alias_str = Absyn.pathString(path);
      then
  "alias " +& name +& " -> (" +& alias_str +& "." +& name +& ")";
    case Env.ALIAS(name = name, path = NONE())
      then "alias " +& name +& " -> ()";
    case Env.REDECLARED_ITEM(item = item)
      equation
  name = itemStr(item);
      then
  "redeclared " +& name;

    else "UNHANDLED ITEM";


  end matchcontinue;
end itemStr;

public function getItemName
  "Returns the name of an environment item."
  input Item inItem;
  output String outName;
algorithm
  outName := match(inItem)
    local
      String name;
      Item item;

    case Env.VAR(var = SCode.COMPONENT(name = name)) then name;
    case Env.CLASS(cls = SCode.CLASS(name = name)) then name;
    case Env.ALIAS(name = name) then name;
    case Env.REDECLARED_ITEM(item = item) then getItemName(item);

  end match;
end getItemName;

public function getItemEnv
  "Returns the environment in an environment item."
  input Item inItem;
  output Env.Env outEnv;
algorithm
  outEnv := match(inItem)
    local
      Env.Env env;
      Item item;

    case Env.CLASS(env = env) then env;
    case Env.REDECLARED_ITEM(item = item) then getItemEnv(item);

  end match;
end getItemEnv;

public function getItemEnvNoFail
  "Returns the environment in an environment item."
  input Item inItem;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(inItem)
    local
      Env.Env env;
      Item item;
      String str;
      Frame f;

    case Env.CLASS(env = env) then env;
    case Env.REDECLARED_ITEM(item = item) then getItemEnvNoFail(item);
    else
      equation
  str = "NO ENV FOR ITEM: " +& getItemName(inItem);
  f = Env.newFrame(SOME(str), NONE(), Env.ENCAPSULATED_SCOPE());
  env = {f};
      then
  env;

  end matchcontinue;
end getItemEnvNoFail;

public function setItemEnv
  "Sets the environment in an environment item."
  input Item inItem;
  input Env.Env inNewEnv;
  output Item outItem;
algorithm
  outItem := match(inItem, inNewEnv)
    local
      Env.Env env;
      Item item;
      SCode.Element cls;
      ClassType ct;

    case (Env.CLASS(cls, env, ct), _)
      then Env.CLASS(cls, inNewEnv, ct);
    case (Env.REDECLARED_ITEM(item = item), _)
      then setItemEnv(item, inNewEnv);
  end match;
end setItemEnv;

public function mergeItemEnv
  "Merges an environment item's environment with the given environment."
  input Item inItem;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := match(inItem, inEnv)
    local
      Frame cls_env;
      Item item;

    case (Env.CLASS(env = {cls_env}), _) then enterFrame(cls_env, inEnv);
    case (Env.REDECLARED_ITEM(item = item), _) then mergeItemEnv(item, inEnv);
    else inEnv;
  end match;
end mergeItemEnv;

public function getItemPrefixes
  input Item inItem;
  output SCode.Prefixes outPrefixes;
algorithm
  outPrefixes := match(inItem)
    local
      SCode.Prefixes pf;
      Item item;

    case Env.CLASS(cls = SCode.CLASS(prefixes = pf)) then pf;
    case Env.VAR(var = SCode.COMPONENT(prefixes = pf)) then pf;
    case Env.REDECLARED_ITEM(item = item) then getItemPrefixes(item);

  end match;
end getItemPrefixes;

public function resolveRedeclaredItem
  input Item inItem;
  input Env.Env inEnv;
  output Item outItem;
  output Env.Env outEnv;
  output list<tuple<Item, Env.Env>> outPreviousItem;
algorithm
  (outItem, outEnv, outPreviousItem) := match(inItem, inEnv)
    local
      Item item;
      Env.Env env;

    case (Env.REDECLARED_ITEM(item = item, declaredEnv = env), _) then (item, env, {(inItem, inEnv)});

    else (inItem, inEnv, {});

  end match;
end resolveRedeclaredItem;

public function getEnvExtendsTable
  input Env.Env inEnv;
  output ExtendsTable outExtendsTable;
algorithm
  Env.FRAME(extendsTable = outExtendsTable) :: _ := inEnv;
end getEnvExtendsTable;

public function getEnvExtendsFromTable
  input Env.Env inEnv;
  output list<Extends> outExtends;
algorithm
  Env.EXTENDS_TABLE(baseClasses = outExtends) := getEnvExtendsTable(inEnv);
end getEnvExtendsFromTable;

public function getDerivedClassRedeclares
"@author: adrpo
 returns the redeclares inside the extends table for the given class.
 The derived class should have only 1 extends"
 input SCode.Ident inDerivedName;
 input Absyn.TypeSpec inTypeSpec;
 input Env.Env inEnv;
 output list<Redeclaration> outRedeclarations;
algorithm
  outRedeclarations := matchcontinue(inDerivedName, inTypeSpec, inEnv)
    local
      Absyn.Path bc, path;
      list<Redeclaration> rm;
      Absyn.Info i;

    // only one extends!
    case (_, Absyn.TPATH(path, _), _)
      equation
  {Env.EXTENDS(baseClass = bc, redeclareModifiers = rm)} =
    getEnvExtendsFromTable(inEnv);
  true = Absyn.pathSuffixOf(path, bc);
      then
  rm;

    case (_, Absyn.TPATH(path, _), _)
      equation
  {Env.EXTENDS(baseClass = bc, redeclareModifiers = rm)} =
    getEnvExtendsFromTable(inEnv);
  false = Absyn.pathSuffixOf(path, bc);
  print("Derived paths are not the same: " +& Absyn.pathString(path) +& " != " +& Absyn.pathString(bc) +& "\n");
      then
  rm;

    // else nothing
    else then {};

  end matchcontinue;
end getDerivedClassRedeclares;

public function setEnvExtendsTable
  input ExtendsTable inExtendsTable;
  input Env.Env inEnv;
  output Env.Env outEnv;
protected
  Option<String> name;
  Option<ScopeType> st;
  FrameType ty;
  AvlTree clsAndVars;
  AvlTree tys;
  CSetsType cs;
  list<SCode.Element> du;
  ExtendsTable exts;
  ImportTable imps;
  Option<Util.StatefulBoolean> is_used;
  Env.Env rest_env;
algorithm
  Env.FRAME(name, st, ty, clsAndVars, tys, cs, du, exts, imps, is_used) :: rest_env := inEnv;
  outEnv := Env.FRAME(name, st, ty, clsAndVars, tys, cs, du, inExtendsTable, imps, is_used) :: rest_env;
end setEnvExtendsTable;

public function setEnvClsAndVars
  input AvlTree inTree;
  input Env.Env inEnv;
  output Env.Env outEnv;
protected
  Option<String> name;
  Option<ScopeType> st;
  FrameType ty;
  AvlTree clsAndVars;
  AvlTree tys;
  CSetsType cs;
  list<SCode.Element> du;
  ExtendsTable exts;
  ImportTable imps;
  Option<Util.StatefulBoolean> is_used;
  Env.Env rest_env;
algorithm
  Env.FRAME(name, st, ty, _, tys, cs, du, exts, imps, is_used) :: rest_env := inEnv;
  outEnv := Env.FRAME(name, st, ty, inTree, tys, cs, du, exts, imps, is_used) :: rest_env;
end setEnvClsAndVars;

public function mergePathWithEnvPath
  "Merges a path with the environment path."
  input Absyn.Path inPath;
  input Env.Env inEnv;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inPath, inEnv)
    local
      Absyn.Path env_path;
      Absyn.Ident id;

    // Try to merge the last identifier in the path with the environment path.
    case (_, _)
      equation
  env_path = getEnvPath(inEnv);
  id = Absyn.pathLastIdent(inPath);
      then
  Absyn.joinPaths(env_path, Absyn.IDENT(id));

    // If the previous case failed (which will happen at the top-scope when
    // getEnvPath fails), just return the path as it is.
    else inPath;
  end matchcontinue;
end mergePathWithEnvPath;

public function mergeTypeSpecWithEnvPath
  "Merges a path with the environment path."
  input Absyn.TypeSpec inTS;
  input Env.Env inEnv;
  output Absyn.TypeSpec outTS;
algorithm
  outTS := matchcontinue(inTS, inEnv)
    local
      Absyn.Path path;
      Absyn.Ident id;
      Option<Absyn.ArrayDim> ad;

    // Try to merge the last identifier in the path with the environment path.
    case (Absyn.TPATH(path, ad), _)
      equation
  id = Absyn.pathLastIdent(path);
  path = Absyn.joinPaths(getEnvPath(inEnv), Absyn.IDENT(id));
      then
  Absyn.TPATH(path, ad);

    // If the previous case failed (which will happen at the top-scope when
    // getEnvPath fails), just return the path as it is.
    else then inTS;

  end matchcontinue;
end mergeTypeSpecWithEnvPath;

public function prefixIdentWithEnv
  input String inIdent;
  input Env.Env inEnv;
  output Absyn.Path outPath;
algorithm
  outPath := match(inIdent, inEnv)
    local
      Absyn.Path path;

    case (_, {Env.FRAME(name = NONE())}) then Absyn.IDENT(inIdent);
    else
      equation
  path = getEnvPath(inEnv);
  path = Absyn.suffixPath(path, inIdent);
      then
  path;

  end match;
end prefixIdentWithEnv;

public function getRedeclarationElement
  input Redeclaration inRedeclare;
  output SCode.Element outElement;
algorithm
  outElement := match(inRedeclare)
    local
      SCode.Element e;
      Item item;

    case Env.RAW_MODIFIER(modifier = e) then e;
    case Env.PROCESSED_MODIFIER(modifier = Env.CLASS(cls = e)) then e;
    case Env.PROCESSED_MODIFIER(modifier = Env.VAR(var = e)) then e;
    case Env.PROCESSED_MODIFIER(modifier = Env.REDECLARED_ITEM(item = item))
      then getRedeclarationElement(Env.PROCESSED_MODIFIER(item));

  end match;
end getRedeclarationElement;

public function getRedeclarationNameInfo
  input Redeclaration inRedeclare;
  output String outName;
  output Absyn.Info outInfo;
algorithm
  (outName, outInfo) := match(inRedeclare)
    local
      SCode.Element el;
      String name;
      Absyn.Info info;

    case Env.PROCESSED_MODIFIER(modifier = Env.ALIAS(name = name, info = info))
      then (name, info);

    else
      equation
  el = getRedeclarationElement(inRedeclare);
  (name, info) = SCode.elementNameInfo(el);
      then
  (name, info);

  end match;
end getRedeclarationNameInfo;

public function printEnvStr
  input Env.Env inEnv;
  output String outString;
protected
  Env.Env env;
algorithm
  env := listReverse(inEnv);
  outString := stringDelimitList(List.map(env, printFrameStr), "\n");
end printEnvStr;

protected function printFrameStr
  input Frame inFrame;
  output String outString;
algorithm
  outString := match(inFrame)
    local
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
      String name_str, ty_str, tree_str, ext_str, imp_str, out;

    case (Env.FRAME(name, st, ty, cv, tys, cs, du, exts, imps, _))
      equation
  name_str = printFrameNameStr(name);
  ty_str = printFrameTypeStr(ty);
  tree_str = printAvlTreeStr(SOME(cv));
  ext_str = printExtendsTableStr(exts);
  imp_str = printImportTableStr(imps);
  name_str = "<<<" +& ty_str +& " frame " +& name_str +& ">>>\n";
  out = name_str +&
        "\tImports:\n" +& imp_str +&
        "\n\tExtends:\n" +& ext_str +&
        "\n\tComponents:\n" +& tree_str +& "\n";
      then
  out;

  end match;
end printFrameStr;

protected function printFrameNameStr
  input Option<String> inFrame;
  output String outString;
algorithm
  outString := match(inFrame)
    local String name;
    case NONE() then "global";
    case SOME(name) then name;
  end match;
end printFrameNameStr;

protected function printFrameTypeStr
  input FrameType inFrame;
  output String outString;
algorithm
  outString := match(inFrame)
    case Env.NORMAL_SCOPE() then "Normal";
    case Env.ENCAPSULATED_SCOPE() then "Encapsulated";
    case Env.IMPLICIT_SCOPE(iterIndex=_) then "Implicit";
  end match;
end printFrameTypeStr;

protected function printAvlTreeStr
  input Option<AvlTree> inTree;
  output String outString;
algorithm
  outString := match(inTree)
    local
      Option<AvlTree> left, right;
      AvlTreeValue value;
      String left_str, right_str, value_str;
      Integer height;

    case (NONE()) then "";
    case (SOME(Env.AVLTREENODE(value = NONE()))) then "";
    case (SOME(Env.AVLTREENODE(value = SOME(value), height = height, left = left, right = right)))
      equation
  left_str = printAvlTreeStr(left);
  right_str = printAvlTreeStr(right);
  value_str = printAvlValueStr(value);
  value_str = value_str +& left_str +& right_str;
      then
  value_str;
  end match;
end printAvlTreeStr;

public function printAvlValueStr
  input AvlTreeValue inValue;
  output String outString;
algorithm
  outString := match(inValue)
    local
      String key_str, alias_str, name;
      Absyn.Path path;
      Item i;

    case (Env.AVLTREEVALUE(key = key_str, value = Env.CLASS(cls = _)))
      then "\t\tClass " +& key_str +& "\n";

    case (Env.AVLTREEVALUE(key = key_str, value = Env.VAR(var = _)))
      then "\t\tVar " +& key_str +& "\n";

    case (Env.AVLTREEVALUE(key = key_str, value = Env.ALIAS(name = name, path = SOME(path))))
      equation
  alias_str = Absyn.pathString(path) +& "." +& name;
      then
  "\t\tAlias " +& key_str +& " -> " +& alias_str +& "\n";

    case (Env.AVLTREEVALUE(key = key_str, value = Env.ALIAS(name = name)))
      then "\t\tAlias " +& key_str +& " -> " +& name +& "\n";

    case (Env.AVLTREEVALUE(key = key_str, value = Env.REDECLARED_ITEM(item = i)))
      then "\t\tRedeclare " +& key_str +& " -> " +& getItemName(i) +& "\n";

  end match;
end printAvlValueStr;

public function printExtendsTableStr
  input ExtendsTable inExtendsTable;
  output String outString;
protected
  list<Extends> bcl;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
algorithm
  Env.EXTENDS_TABLE(baseClasses = bcl, redeclaredElements = re, classExtendsInfo = cei) := inExtendsTable;
  outString := stringDelimitList(List.map(bcl, printExtendsStr), "\n") +&
    "\n\t\tRedeclare elements:\n\t\t\t" +&
    stringDelimitList(List.map(re, SCodeDump.unparseElementStr), "\n\t\t\t") +&
    "\n\t\tClass extends:\n\t\t\t" +&
    Util.stringOption(Util.applyOption(cei, SCodeDump.unparseElementStr));
end printExtendsTableStr;

public function printExtendsStr
  input Extends inExtends;
  output String outString;
protected
  Absyn.Path bc;
  list<Redeclaration> mods;
  String mods_str;
algorithm
  Env.EXTENDS(baseClass = bc, redeclareModifiers = mods) := inExtends;
  mods_str := stringDelimitList(
    List.map(mods, printRedeclarationStr), "\n");
  outString := "\t\t" +& Absyn.pathString(bc) +& "(" +& mods_str +& ")";
end printExtendsStr;

public function printRedeclarationStr
  input Redeclaration inRedeclare;
  output String outString;
algorithm
  outString := matchcontinue(inRedeclare)
    local String name; Absyn.Path p;
    case (Env.PROCESSED_MODIFIER(modifier = Env.ALIAS(name = name, path = SOME(p))))
      then "ALIAS(" +& Absyn.pathString(p) +& "." +& name +& ")";
    case (Env.PROCESSED_MODIFIER(modifier = Env.ALIAS(name = name)))
      then "ALIAS(" +& name +& ")";
    case _ then SCodeDump.unparseElementStr(getRedeclarationElement(inRedeclare));
  end matchcontinue;
end printRedeclarationStr;

protected function printImportTableStr
  input ImportTable inImports;
  output String outString;
protected
  list<Import> qual_imps, unqual_imps;
  String qual_str, unqual_str;
algorithm
  Env.IMPORT_TABLE(qualifiedImports = qual_imps, unqualifiedImports = unqual_imps)
    := inImports;
  qual_str := stringDelimitList(
    List.map(qual_imps, Absyn.printImportString), "\n\t\t");
  unqual_str := stringDelimitList(
    List.map(unqual_imps, Absyn.printImportString), "\n\t\t");
  outString := "\t\t" +& qual_str +& unqual_str;
end printImportTableStr;

end FEnv;
