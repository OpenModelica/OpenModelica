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

encapsulated package NFSCodeEnv
" file:        NFSCodeEnv.mo
  package:     NFSCodeEnv
  description: SCode flattening

  RCS: $Id: NFSCodeEnv.mo 25211 2015-03-23 09:47:31Z jansilar $

  This module flattens the SCode representation by removing all extends, imports
  and redeclares, and fully qualifying class names.
"

public import Absyn;
public import SCode;
public import Util;

protected import NFEnvExtends;
protected import Error;
protected import List;
protected import SCodeDump;
protected import NFSCodeFlattenRedeclare;
protected import NFSCodeLookup;
protected import NFSCodeCheck;
protected import SCodeUtil;
protected import System;
protected import Builtin;

public type Import = Absyn.Import;

public constant Integer tmpTickIndex = 2;
public constant Integer extendsTickIndex = 3;

public uniontype ImportTable
  record IMPORT_TABLE
    // Imports should not be inherited, but removing them from the environment
    // when doing lookup through extends causes problems for the lookup later
    // on, because for example components may have types that depends on
    // imports.  The hidden flag allows the lookup to 'hide' the imports
    // temporarily, without actually removing them.
    Boolean hidden "If true means that the imports are hidden.";
    list<Import> qualifiedImports;
    list<Import> unqualifiedImports;
  end IMPORT_TABLE;
end ImportTable;

public uniontype Redeclaration
  "This uniontype stores a redeclare modifier (which might be derived from an
  element redeclare). The RAW_MODIFIER stores a 'raw' modifier, i.e. the raw
  element stored in the SCode representation. These are processed when they are
  used, i.e. when replacements are done, and converted into PROCESSED_MODIFIERs
  which are environment items ready to be replaced in the environment."

  record RAW_MODIFIER
    SCode.Element modifier;
  end RAW_MODIFIER;

  record PROCESSED_MODIFIER
    Item modifier;
  end PROCESSED_MODIFIER;
end Redeclaration;

public uniontype Extends
  record EXTENDS
    Absyn.Path baseClass;
    list<Redeclaration> redeclareModifiers;
    Integer index;
    SourceInfo info;
  end EXTENDS;
end Extends;

public uniontype ExtendsTable
  record EXTENDS_TABLE
    list<Extends> baseClasses;
    list<SCode.Element> redeclaredElements;
    Option<SCode.Element> classExtendsInfo;
  end EXTENDS_TABLE;
end ExtendsTable;

public uniontype FrameType
  record NORMAL_SCOPE end NORMAL_SCOPE;
  record ENCAPSULATED_SCOPE end ENCAPSULATED_SCOPE;
  record IMPLICIT_SCOPE "This scope contains one or more iterators; they are made unique by the following index (plus their name)" Integer iterIndex; end IMPLICIT_SCOPE;
end FrameType;

public uniontype Frame
  record FRAME
    Option<String> name;
    FrameType frameType;
    AvlTree clsAndVars;
    ExtendsTable extendsTable;
    ImportTable importTable;
    Option<Util.StatefulBoolean> isUsed "Used by SCodeDependency.";
  end FRAME;
end Frame;

public uniontype ClassType
  record USERDEFINED end USERDEFINED;
  record BUILTIN end BUILTIN;
  record CLASS_EXTENDS end CLASS_EXTENDS;
  record BASIC_TYPE end BASIC_TYPE;
end ClassType;

public uniontype Item
  record VAR
    SCode.Element var;
    Option<Util.StatefulBoolean> isUsed "Used by SCodeDependency.";
  end VAR;

  record CLASS
    SCode.Element cls;
    Env env;
    ClassType classType;
  end CLASS;

  record ALIAS
    "An alias for another Item, see comment in SCodeFlattenRedeclare package."
    String name;
    Option<Absyn.Path> path;
    SourceInfo info;
  end ALIAS;

  record REDECLARED_ITEM
    Item item;
    Env declaredEnv;
  end REDECLARED_ITEM;
end Item;

public type Env = list<Frame>;
public constant Env emptyEnv = {};
public constant String BASE_CLASS_SUFFIX = "$base";

public function newEnvironment
  "Returns a new environment with only one frame."
  input Option<SCode.Ident> inName;
  output Env outEnv;
protected
  Frame new_frame;
algorithm
  new_frame := newFrame(inName, NORMAL_SCOPE());
  outEnv := {new_frame};
end newEnvironment;

protected function openScope
  "Open a new class scope in the environment by adding a new frame for the given
  class."
  input Env inEnv;
  input SCode.Element inClass;
  output Env outEnv;
protected
  String name;
  SCode.Encapsulated encapsulatedPrefix;
  Frame new_frame;
algorithm
  SCode.CLASS(name = name, encapsulatedPrefix = encapsulatedPrefix) := inClass;
  new_frame := newFrame(SOME(name), getFrameType(encapsulatedPrefix));
  outEnv := new_frame :: inEnv;
end openScope;

public function enterScope
  "Enters a new scope in the environment by looking up an item in the
  environment and appending it's frame to the environment."
  input Env inEnv;
  input SCode.Ident inName;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inEnv, inName)
    local
      Frame cls_env;
      Item item;

    case (_, _)
      equation
        /*********************************************************************/
        // TODO: Should we use the environment returned by lookupInClass?
        /*********************************************************************/
        (item, _) = NFSCodeLookup.lookupInClass(inName, inEnv);
        {cls_env} = getItemEnv(item);
        outEnv = enterFrame(cls_env, inEnv);
      then
        outEnv;

    case (_, _)
      equation
        print("Failed to enterScope: " + inName + " in env: " + printEnvStr(inEnv) + "\n");
      then
        fail();
  end matchcontinue;
end enterScope;

public function enterScopePath
  input Env inEnv;
  input Absyn.Path inPath;
  output Env outEnv;
algorithm
  outEnv := match(inEnv, inPath)
    local
      Absyn.Ident name;
      Absyn.Path path;
      Env env;

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
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := inFrame :: inEnv;
end enterFrame;

public function getEnvTopScope
  "Returns the top scope, i.e. last frame in the environment."
  input Env inEnv;
  output Env outEnv;
protected
  Frame top_scope;
  Env env;
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
    case SCode.ENCAPSULATED() then ENCAPSULATED_SCOPE();
    else NORMAL_SCOPE();
  end match;
end getFrameType;

protected function newFrame
  "Creates a new frame with an optional name and a frame type."
  input Option<String> inName;
  input FrameType inType;
  output Frame outFrame;
protected
  AvlTree tree;
  ExtendsTable exts;
  ImportTable imps;
  Util.StatefulBoolean is_used;
algorithm
  tree := avlTreeNew();
  exts := newExtendsTable();
  imps := newImportTable();
  is_used := Util.makeStatefulBoolean(false);
  outFrame := FRAME(inName, inType, tree, exts, imps, SOME(is_used));
end newFrame;

protected function newImportTable
  "Creates a new import table."
  output ImportTable outImports;
algorithm
  outImports := IMPORT_TABLE(false, {}, {});
end newImportTable;

protected function newExtendsTable
  "Creates a new extends table."
  output ExtendsTable outExtends;
algorithm
  outExtends := EXTENDS_TABLE({}, {}, NONE());
end newExtendsTable;

public function newItem
  input SCode.Element inElement;
  output Item outItem;
algorithm
  outItem := match(inElement)
    local
      Env class_env;
      Item item;

    case SCode.CLASS()
      equation
        class_env = makeClassEnvironment(inElement, true);
        item = newClassItem(inElement, class_env, USERDEFINED());
      then
        item;

    case SCode.COMPONENT() then newVarItem(inElement, false);

  end match;
end newItem;

public function newClassItem
  "Creates a new class environment item."
  input SCode.Element inClass;
  input Env inEnv;
  input ClassType inClassType;
  output Item outClassItem;
algorithm
  outClassItem := CLASS(inClass, inEnv, inClassType);
end newClassItem;

public function newVarItem
  "Creates a new variable environment item."
  input SCode.Element inVar;
  input Boolean inIsUsed;
  output Item outVarItem;
protected
  Util.StatefulBoolean is_used;
algorithm
  is_used := Util.makeStatefulBoolean(inIsUsed);
  outVarItem := VAR(inVar, SOME(is_used));
end newVarItem;

public function extendEnvWithClasses
  "Extends the environment with a list of classes."
  input list<SCode.Element> inClasses;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := List.fold(inClasses, extendEnvWithClass, inEnv);
end extendEnvWithClasses;

protected function extendEnvWithClass
  "Extends the environment with a class."
  input SCode.Element inClass;
  input Env inEnv;
  output Env outEnv;
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
      then BUILTIN();
    // A user-defined class (i.e. not builtin).
    else USERDEFINED();
  end match;
end getClassType;

public function printClassType
  input ClassType inClassType;
  output String outString;
algorithm
  outString := match(inClassType)
    case BUILTIN() then "BUILTIN";
    case CLASS_EXTENDS() then "CLASS_EXTENDS";
    case USERDEFINED() then "USERDEFINED";
    case BASIC_TYPE() then "BASIC_TYPE";
  end match;
end printClassType;

public function removeExtendsFromLocalScope
  "Removes all extends from the local scope, i.e. inserts a new empty
  extends-table into the first frame."
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  ExtendsTable exts;
  Env rest;
  Option<Util.StatefulBoolean> is_used;
algorithm
  FRAME(name = name, frameType = ty, clsAndVars = tree, importTable = imps,
    isUsed = is_used) :: rest := inEnv;
  exts := newExtendsTable();
  outEnv := FRAME(name, ty, tree, exts, imps, is_used) :: rest;
end removeExtendsFromLocalScope;

public function removeExtendFromLocalScope
  "Removes a given extends clause from the local scope."
  input Absyn.Path inExtend;
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  Env rest;
  Option<Util.StatefulBoolean> iu;
  list<Extends> bcl;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
algorithm
  FRAME(name = name, frameType = ty, clsAndVars = tree, extendsTable =
    EXTENDS_TABLE(baseClasses = bcl, redeclaredElements = re, classExtendsInfo = cei),
    importTable = imps, isUsed = iu) :: rest := inEnv;
  (bcl, _) := List.deleteMemberOnTrue(inExtend, bcl, isExtendNamed);
  outEnv := FRAME(name, ty, tree, EXTENDS_TABLE(bcl, re, cei), imps, iu) :: rest;
end removeExtendFromLocalScope;

protected function isExtendNamed
  input Absyn.Path inName;
  input Extends inExtends;
  output Boolean outIsNamed;
protected
  Absyn.Path bc;
algorithm
  EXTENDS(baseClass = bc) := inExtends;
  outIsNamed := Absyn.pathEqual(inName, bc);
end isExtendNamed;

public function removeRedeclaresFromLocalScope
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  ExtendsTable exts;
  Env rest;
  Option<Util.StatefulBoolean> is_used;
  list<Extends> bc;
  Option<SCode.Element> cei;
algorithm
  FRAME(name = name, frameType = ty, clsAndVars = tree, extendsTable =
    EXTENDS_TABLE(baseClasses = bc, classExtendsInfo = cei), importTable = imps,
    isUsed = is_used) :: rest := inEnv;
  bc := List.map(bc, removeRedeclaresFromExtend);
  exts := EXTENDS_TABLE(bc, {}, cei);
  outEnv := FRAME(name, ty, tree, exts, imps, is_used) :: rest;
end removeRedeclaresFromLocalScope;

protected function removeRedeclaresFromExtend
  input Extends inExtend;
  output Extends outExtend;
protected
  Absyn.Path bc;
  Integer index;
  SourceInfo info;
algorithm
  EXTENDS(bc, _, index, info) := inExtend;
  outExtend := EXTENDS(bc, {}, index, info);
end removeRedeclaresFromExtend;

public function removeClsAndVarsFromFrame
  "Removes the classes variables from a frame."
  input Frame inFrame;
  output Frame outFrame;
  output AvlTree outClsAndVars;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  ExtendsTable exts;
  Option<Util.StatefulBoolean> is_used;
algorithm
  FRAME(name = name, frameType = ty, clsAndVars = outClsAndVars,
    extendsTable = exts, importTable = imps, isUsed = is_used) := inFrame;
  tree := avlTreeNew();
  outFrame := FRAME(name, ty, tree, exts, imps, is_used);
end removeClsAndVarsFromFrame;

public function setImportTableHidden
  "Sets the 'hidden' flag in the import table in the local scope of the given
  environment."
  input Env inEnv;
  input Boolean inHidden;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  ExtendsTable exts;
  Env rest;
  list<Import> qi, uqi;
  Option<Util.StatefulBoolean> is_used;
algorithm
  FRAME(name = name, frameType = ty, clsAndVars = tree, extendsTable = exts,
    importTable = IMPORT_TABLE(qualifiedImports = qi, unqualifiedImports = uqi),
    isUsed = is_used) :: rest := inEnv;
  outEnv := FRAME(name, ty, tree, exts, IMPORT_TABLE(inHidden, qi, uqi), is_used) :: rest;
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
      Env env;
      ClassType cls_ty;

    case (CLASS(cls = cls, env = env, classType = cls_ty), _)
      equation
        env = setImportTableHidden(env, inHidden);
      then
        CLASS(cls, env, cls_ty);

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

    case CLASS(env = {FRAME(isUsed = SOME(is_used))})
      then Util.getStatefulBoolean(is_used);

    case VAR(isUsed = SOME(is_used))
      then Util.getStatefulBoolean(is_used);

    case ALIAS() then true;

    case REDECLARED_ITEM(item = item) then isItemUsed(item);

    else false;
  end match;
end isItemUsed;

public function linkItemUsage
  "'Links' two items to each other, by making them share the same isUsed
  variable."
  input Item inSrcItem;
  input Item inDestItem;
  output Item outDestItem;
algorithm
  outDestItem := match(inSrcItem, inDestItem)
    local
      Option<Util.StatefulBoolean> is_used;
      SCode.Element elem;
      ClassType cls_ty;
      Option<String> name;
      FrameType ft;
      AvlTree cv;
      ExtendsTable exts;
      ImportTable imps;
      Item item;
      Env env;

    case (VAR(isUsed = is_used), VAR(var = elem))
      then VAR(elem, is_used);

    case (CLASS(env = {FRAME(isUsed = is_used)}),
        CLASS(cls = elem, classType = cls_ty, env =
          {FRAME(name, ft, cv, exts, imps, _)}))
      then CLASS(elem, {FRAME(name, ft, cv, exts, imps, is_used)}, cls_ty);

    case (_, REDECLARED_ITEM(item, env))
      equation
        item = linkItemUsage(inSrcItem, item);
      then
        REDECLARED_ITEM(item, env);

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

    case CLASS() then true;
    case REDECLARED_ITEM(item = item) then isClassItem(item);
    else false;
  end match;
end isClassItem;

public function isVarItem
  input Item inItem;
  output Boolean outIsVar;
algorithm
  outIsVar := match(inItem)
    local
      Item item;

    case VAR() then true;
    case REDECLARED_ITEM(item = item) then isVarItem(item);
    else false;
  end match;
end isVarItem;

public function isClassExtendsItem
  input Item inItem;
  output Boolean outIsClassExtends;
algorithm
  outIsClassExtends := match(inItem)
    local
      Item item;

    case CLASS(classType = CLASS_EXTENDS()) then true;
    case REDECLARED_ITEM(item = item) then isClassExtendsItem(item);
    else false;
  end match;
end isClassExtendsItem;

protected function extendEnvWithClassDef
  "Extends the environment with a class definition."
  input SCode.Element inClassDefElement;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inClassDefElement, inEnv)
    local
      String cls_name, alias_name;
      Env class_env, env;
      SCode.ClassDef cdef;
      ClassType cls_type;
      SourceInfo info;

    // A class extends.
    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS()), _)
      then
        NFEnvExtends.extendEnvWithClassExtends(inClassDefElement, inEnv);

    case (SCode.CLASS(name = cls_name, classDef = cdef, prefixes = SCode.PREFIXES(
        replaceablePrefix = SCode.REPLACEABLE(_)), info = info), _)
      equation
        class_env = makeClassEnvironment(inClassDefElement, false);
        cls_type = getClassType(cdef);
        alias_name = cls_name + BASE_CLASS_SUFFIX;
        env = extendEnvWithItem(newClassItem(inClassDefElement, class_env, cls_type),
          inEnv, alias_name);
        env = extendEnvWithItem(ALIAS(alias_name, NONE(), info), env, cls_name);
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
  output Env outClassEnv;
protected
  SCode.ClassDef cdef;
  SCode.Element cls;
  String cls_name;
  Env env, enclosing_env;
  SourceInfo info;
algorithm
  SCode.CLASS(name = cls_name, classDef = cdef, info = info) := inClassDefElement;
  env := openScope(emptyEnv, inClassDefElement);
  enclosing_env := if inInModifierScope then emptyEnv else env;
  outClassEnv :=
    extendEnvWithClassComponents(cls_name, cdef, env, enclosing_env, info);
end makeClassEnvironment;

protected function extendEnvWithVar
  "Extends the environment with a variable."
  input SCode.Element inVar;
  input Env inEnv;
  output Env outEnv;
protected
  String var_name;
  Util.StatefulBoolean is_used;
  Absyn.TypeSpec ty;
  SourceInfo info;
algorithm
  SCode.COMPONENT(name = var_name, typeSpec = ty, info = info) := inVar;
  is_used := Util.makeStatefulBoolean(false);
  outEnv := extendEnvWithItem(VAR(inVar, SOME(is_used)), inEnv, var_name);
end extendEnvWithVar;

public function extendEnvWithItem
  "Extends the environment with an environment item."
  input Item inItem;
  input Env inEnv;
  input String inItemName;
  output Env outEnv;
protected
  Option<String> name;
  AvlTree tree;
  ExtendsTable exts;
  ImportTable imps;
  FrameType ty;
  Env rest;
  Option<Util.StatefulBoolean> is_used;
algorithm
  FRAME(name, ty, tree, exts, imps, is_used) :: rest := inEnv;
  tree := avlTreeAdd(tree, inItemName, inItem);
  outEnv := FRAME(name, ty, tree, exts, imps, is_used) :: rest;
end extendEnvWithItem;

public function updateItemInEnv
  "Updates an item in the environment by replacing an existing item."
  input Item inItem;
  input Env inEnv;
  input String inItemName;
  output Env outEnv;
protected
  Option<String> name;
  AvlTree tree;
  ExtendsTable exts;
  ImportTable imps;
  FrameType ty;
  Env rest;
  Option<Util.StatefulBoolean> is_used;
algorithm
  FRAME(name, ty, tree, exts, imps, is_used) :: rest := inEnv;
  tree := avlTreeReplace(tree, inItemName, inItem);
  outEnv := FRAME(name, ty, tree, exts, imps, is_used) :: rest;
end updateItemInEnv;

protected function extendEnvWithImport
  "Extends the environment with an import element."
  input SCode.Element inImport;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inImport, inEnv)
    local
      Import imp;
      Option<String> name;
      AvlTree tree;
      ExtendsTable exts;
      list<Import> qual_imps, unqual_imps;
      FrameType ty;
      Env rest;
      SourceInfo info;
      Boolean hidden;
      Option<Util.StatefulBoolean> is_used;

    // Unqualified imports
    case (SCode.IMPORT(imp = imp as Absyn.UNQUAL_IMPORT()),
        FRAME(name, ty, tree, exts,
          IMPORT_TABLE(hidden, qual_imps, unqual_imps), is_used) :: rest)
      equation
        unqual_imps = imp :: unqual_imps;
      then
        FRAME(name, ty, tree, exts,
          IMPORT_TABLE(hidden, qual_imps, unqual_imps), is_used) :: rest;

    // Qualified imports
    case (SCode.IMPORT(imp = imp), FRAME(name, ty, tree, exts,
        IMPORT_TABLE(hidden, qual_imps, unqual_imps), is_used) :: rest)
      equation
        imp = translateQualifiedImportToNamed(imp);
        qual_imps = imp :: qual_imps;
      then
        FRAME(name, ty, tree, exts,
          IMPORT_TABLE(hidden, qual_imps, unqual_imps), is_used) :: rest;
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
    case Absyn.NAMED_IMPORT() then inImport;

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
  input Env inEnv;
  output Env outEnv;
protected
  Absyn.Path bc;
  SCode.Mod mods;
  list<Redeclaration> redecls;
  SourceInfo info;
  Env env;
  Integer index;
algorithm
  SCode.EXTENDS(baseClassPath = bc, modifications = mods, info = info) :=
    inExtends;
  redecls := NFSCodeFlattenRedeclare.extractRedeclaresFromModifier(mods);
  index := System.tmpTickIndex(extendsTickIndex);
  outEnv := addExtendsToEnvExtendsTable(EXTENDS(bc, redecls, index, info), inEnv);
end extendEnvWithExtends;

protected function addExtendsToEnvExtendsTable
  "Adds an Extents to the environment."
  input Extends inExtends;
  input Env inEnv;
  output Env outEnv;
protected
  list<Extends> exts;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
algorithm
  EXTENDS_TABLE(exts, re, cei) := getEnvExtendsTable(inEnv);
  exts := inExtends :: exts;
  outEnv := setEnvExtendsTable(EXTENDS_TABLE(exts, re, cei), inEnv);
end addExtendsToEnvExtendsTable;

protected function addElementRedeclarationToEnvExtendsTable
  input SCode.Element inRedeclare;
  input Env inEnv;
  output Env outEnv;
protected
  list<Extends> exts;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
algorithm
  EXTENDS_TABLE(exts, re, cei) := getEnvExtendsTable(inEnv);
  re := inRedeclare :: re;
  outEnv := setEnvExtendsTable(EXTENDS_TABLE(exts, re, cei), inEnv);
end addElementRedeclarationToEnvExtendsTable;

protected function extendEnvWithClassComponents
  "Extends the environment with a class's components."
  input String inClassName;
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  input Env inEnclosingScope;
  input SourceInfo inInfo;
  output Env outEnv;
algorithm
  outEnv := match(inClassName, inClassDef, inEnv, inEnclosingScope, inInfo)
    local
      list<SCode.Element> el;
      list<SCode.Enum> enums;
      Absyn.TypeSpec ty;
      Env env;
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
        NFSCodeCheck.checkRecursiveShortDefinition(ty, inClassName,
          inEnclosingScope, inInfo);
        env = extendEnvWithExtends(SCode.EXTENDS(path, SCode.PUBLIC(), mods,
          NONE(), inInfo), inEnv);
      then
        env;

    case (_, SCode.ENUMERATION(enumLst = enums), _, _, _)
      equation
        path = Absyn.IDENT(inClassName);
        env = extendEnvWithEnumLiterals(enums, path, 1, inEnv, inInfo);
      then
        env;

    else inEnv;
  end match;
end extendEnvWithClassComponents;

protected function extendEnvWithElement
  "Extends the environment with a class element."
  input SCode.Element inElement;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inElement, inEnv)
    local
      Env env;
      SCode.Ident name;

    // redeclare-as-element component
    case (SCode.COMPONENT(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE())), _)
      equation
        env = addElementRedeclarationToEnvExtendsTable(inElement, inEnv);
        env = extendEnvWithVar(inElement, env);
      then
        env;

    // normal component
    case (SCode.COMPONENT(), _)
      equation
        env = extendEnvWithVar(inElement, inEnv);
      then
        env;

    // redeclare-as-element class
    case (SCode.CLASS( prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE())), _)
      equation
        env = addElementRedeclarationToEnvExtendsTable(inElement, inEnv);
        env = extendEnvWithClassDef(inElement, env);
      then
        env;

    // normal class
    case (SCode.CLASS(), _)
      equation
        env = extendEnvWithClassDef(inElement, inEnv);
      then
        env;

    case (SCode.EXTENDS(), _)
      equation
        env = extendEnvWithExtends(inElement, inEnv);
      then
        env;

    case (SCode.IMPORT(), _)
      equation
        env = extendEnvWithImport(inElement, inEnv);
      then
        env;

    case (SCode.DEFINEUNIT(), _)
      then inEnv;

  end matchcontinue;
end extendEnvWithElement;

public function checkUniqueQualifiedImport
  "Checks that a qualified import is unique, because it's not allowed to have
  qualified imports with the same name."
  input Import inImport;
  input list<Import> inImports;
  input SourceInfo inInfo;
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

    else false;
  end matchcontinue;
end compareQualifiedImportNames;

protected function extendEnvWithEnumLiterals
  input list<SCode.Enum> inEnum;
  input Absyn.Path inEnumPath;
  input Integer inNextValue;
  input Env inEnv;
  input SourceInfo inInfo;
  output Env outEnv;
algorithm
  outEnv := match(inEnum, inEnumPath, inNextValue, inEnv, inInfo)
    local
      SCode.Enum lit;
      list<SCode.Enum> rest_lits;
      Env env;

    case (lit :: rest_lits, _, _, _, _)
      equation
        env = extendEnvWithEnum(lit, inEnumPath, inNextValue, inEnv, inInfo);
      then
        extendEnvWithEnumLiterals(rest_lits, inEnumPath, inNextValue + 1, env, inInfo);

    case ({}, _, _, _, _) then inEnv;

  end match;
end extendEnvWithEnumLiterals;

protected function extendEnvWithEnum
  "Extends the environment with an enumeration."
  input SCode.Enum inEnum;
  input Absyn.Path inEnumPath;
  input Integer inValue;
  input Env inEnv;
  input SourceInfo inInfo;
  output Env outEnv;
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
    SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.CONST(), Absyn.BIDIR(),Absyn.NONFIELD()), ty,
    SCode.NOMOD(), SCode.noComment, NONE(), inInfo);
  outEnv := extendEnvWithElement(enum_lit, inEnv);
end extendEnvWithEnum;

public function extendEnvWithIterators
  "Extends the environment with a new scope and adds a list of iterators to it."
  input Absyn.ForIterators inIterators;
  input Integer iterIndex;
  input Env inEnv;
  output Env outEnv;
protected
  Frame frame;
algorithm
  frame := newFrame(SOME("$for$"), IMPLICIT_SCOPE(iterIndex));
  outEnv := List.fold(inIterators, extendEnvWithIterator, frame :: inEnv);
end extendEnvWithIterators;

protected function extendEnvWithIterator
  "Extends the environment with an iterator."
  input Absyn.ForIterator inIterator;
  input Env inEnv;
  output Env outEnv;
protected
  Absyn.Ident iter_name;
  SCode.Element iter;
algorithm
  Absyn.ITERATOR(name=iter_name) := inIterator;
  iter := SCode.COMPONENT(iter_name, SCode.defaultPrefixes,
    SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.CONST(), Absyn.BIDIR(), Absyn.NONFIELD()),
    Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
    SCode.noComment, NONE(), Absyn.dummyInfo);
  outEnv := extendEnvWithElement(iter, inEnv);
end extendEnvWithIterator;

public function extendEnvWithMatch
  "Extends the environment with a match-expression, i.e. opens a new scope and
  adds the local declarations in the match to it."
  input Absyn.Exp inMatchExp;
  input Integer iterIndex;
  input Env inEnv;
  output Env outEnv;
protected
  Frame frame;
  list<Absyn.ElementItem> local_decls;
algorithm
  frame := newFrame(SOME("$match$"), IMPLICIT_SCOPE(iterIndex));
  Absyn.MATCHEXP(localDecls = local_decls) := inMatchExp;
  outEnv := List.fold(local_decls, extendEnvWithElementItem,
    frame :: inEnv);
end extendEnvWithMatch;

protected function extendEnvWithElementItem
  "Extends the environment with an Absyn.ElementItem."
  input Absyn.ElementItem inElementItem;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inElementItem, inEnv)
    local
      Absyn.Element element;
      list<SCode.Element> el;
      Env env;

    case (Absyn.ELEMENTITEM(element = element), _)
      equation
        // Translate the element item to a SCode element.
        el = SCodeUtil.translateElement(element, SCode.PROTECTED());
        env = List.fold(el, extendEnvWithElement, inEnv);
      then
        env;

    else inEnv;
  end match;
end extendEnvWithElementItem;

public function getEnvName
  "Returns the environment path as a string."
  input Env inEnv;
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

    else "";
  end matchcontinue;
end getEnvName;

public function getEnvPath
  "Returns the environment path. Fails for an empty environment or the top
  scope, which can't be represented as an Absyn.Path."
  input Env inEnv;
  output Absyn.Path outPath;
algorithm
  outPath := match(inEnv)
    local
      String name;
      Absyn.Path path;
      Env rest;

    case (FRAME(frameType = IMPLICIT_SCOPE()) :: rest)
      then getEnvPath(rest);

    case ({FRAME(name = SOME(name))})
      then Absyn.IDENT(name);

    case ({FRAME(name = SOME(name)), FRAME(name = NONE())})
      then Absyn.IDENT(name);

    case (FRAME(name = SOME(name)) :: rest)
      equation
        path = getEnvPath(rest);
        path = Absyn.joinPaths(path, Absyn.IDENT(name));
      then
        path;
  end match;
end getEnvPath;

public function getScopeName
  "Returns the name of the innermost that has a name."
  input Env inEnv;
  output String outString;
algorithm
  outString := match(inEnv)
    local
      String name;
      Env rest;

    case FRAME(name = SOME(name)) :: _ then name;
    case _ :: rest then getScopeName(rest);

  end match;
end getScopeName;

public function envPrefixOf
  input Env inPrefixEnv;
  input Env inEnv;
  output Boolean outIsPrefix;
algorithm
  outIsPrefix := envPrefixOf2(listReverse(inPrefixEnv), listReverse(inEnv));
end envPrefixOf;

public function envPrefixOf2
  "Checks if one environment is a prefix of another."
  input Env inPrefixEnv;
  input Env inEnv;
  output Boolean outIsPrefix;
algorithm
  outIsPrefix := matchcontinue(inPrefixEnv, inEnv)
    local
      String n1, n2;
      Env rest1, rest2;

    case ({}, _) then true;

    case (FRAME(name = NONE()) :: rest1, FRAME(name = NONE()) :: rest2)
      then envPrefixOf2(rest1, rest2);

    case (FRAME(name = SOME(n1)) :: rest1, FRAME(name = SOME(n2)) :: rest2)
      equation
        true = stringEqual(n1, n2);
      then
        envPrefixOf2(rest1, rest2);

    else false;
  end matchcontinue;
end envPrefixOf2;

public function envScopeNames
  input Env inEnv;
  output list<String> outNames;
algorithm
  outNames := envScopeNames2(inEnv, {});
end envScopeNames;

public function envScopeNames2
  input Env inEnv;
  input list<String> inAccumNames;
  output list<String> outNames;
algorithm
  outNames := match(inEnv, inAccumNames)
    local
      String name;
      Env rest_env;
      list<String> names;

    case (FRAME(name = SOME(name)) :: rest_env, _)
      equation
        names = envScopeNames2(rest_env, name :: inAccumNames);
      then
        names;

    case (FRAME(name = NONE()) :: rest_env, _)
      then envScopeNames2(rest_env, inAccumNames);

    case ({}, _) then inAccumNames;

  end match;
end envScopeNames2;

public function envEqualPrefix
  input Env inEnv1;
  input Env inEnv2;
  output Env outPrefix;
algorithm
  outPrefix := envEqualPrefix2(listReverse(inEnv1), listReverse(inEnv2), {});
end envEqualPrefix;

public function envEqualPrefix2
  input Env inEnv1;
  input Env inEnv2;
  input Env inAccumEnv;
  output Env outPrefix;
algorithm
  outPrefix := matchcontinue(inEnv1, inEnv2, inAccumEnv)
    local
      String name1, name2;
      Env env, rest_env1, rest_env2;
      Frame frame;

    case ((frame as FRAME(name = SOME(name1))) :: rest_env1,
          FRAME(name = SOME(name2)) :: rest_env2, _)
      equation
        true = stringEq(name1, name2);
        env = envEqualPrefix2(rest_env1, rest_env2, frame :: inAccumEnv);
      then
        env;

    case (FRAME(name = NONE()) :: rest_env1, FRAME(name = NONE()) :: rest_env2, _)
      then envEqualPrefix2(rest_env1, rest_env2, inAccumEnv);

    else inAccumEnv;

  end matchcontinue;
end envEqualPrefix2;

public function getItemInfo
  "Returns the SourceInfo of an environment item."
  input Item inItem;
  output SourceInfo outInfo;
algorithm
  outInfo := match(inItem)
    local
      SourceInfo info;
      Item item;

    case VAR(var = SCode.COMPONENT(info = info)) then info;
    case CLASS(cls = SCode.CLASS(info = info)) then info;
    case ALIAS(info = info) then info;
    case REDECLARED_ITEM(item = item) then getItemInfo(item);
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

    case VAR(var = el)
      then SCodeDump.unparseElementStr(el,SCodeDump.defaultOptions);
    case CLASS(cls = el)
      then SCodeDump.unparseElementStr(el,SCodeDump.defaultOptions);
    case ALIAS(name = name, path = SOME(path))
      equation
        alias_str = Absyn.pathString(path);
      then
        "alias " + name + " -> (" + alias_str + "." + name + ")";
    case ALIAS(name = name, path = NONE())
      then "alias " + name + " -> ()";
    case REDECLARED_ITEM(item = item)
      equation
        name = itemStr(item);
      then
        "redeclared " + name;

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

    case VAR(var = SCode.COMPONENT(name = name)) then name;
    case CLASS(cls = SCode.CLASS(name = name)) then name;
    case ALIAS(name = name) then name;
    case REDECLARED_ITEM(item = item) then getItemName(item);
  end match;
end getItemName;

public function getItemEnv
  "Returns the environment in an environment item."
  input Item inItem;
  output Env outEnv;
algorithm
  outEnv := match(inItem)
    local
      Env env;
      Item item;

    case CLASS(env = env) then env;
    case REDECLARED_ITEM(item = item) then getItemEnv(item);

  end match;
end getItemEnv;

public function getItemEnvNoFail
  "Returns the environment in an environment item."
  input Item inItem;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inItem)
    local
      Env env;
      Item item;
      String str;
      Frame f;

    case CLASS(env = env) then env;
    case REDECLARED_ITEM(item = item) then getItemEnvNoFail(item);
    else
      equation
        str = "NO ENV FOR ITEM: " + getItemName(inItem);
        f = newFrame(SOME(str), ENCAPSULATED_SCOPE());
        env = {f};
      then
        env;

  end matchcontinue;
end getItemEnvNoFail;

public function setItemEnv
  "Sets the environment in an environment item."
  input Item inItem;
  input Env inNewEnv;
  output Item outItem;
algorithm
  outItem := match(inItem, inNewEnv)
    local
      Env env;
      Item item;
      SCode.Element cls;
      ClassType ct;

    case (CLASS(cls, _, ct), _)
      then CLASS(cls, inNewEnv, ct);
    case (REDECLARED_ITEM(item = item), _)
      then setItemEnv(item, inNewEnv);
  end match;
end setItemEnv;

public function mergeItemEnv
  "Merges an environment item's environment with the given environment."
  input Item inItem;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inItem, inEnv)
    local
      Frame cls_env;
      Item item;

    case (CLASS(env = {cls_env}), _) then enterFrame(cls_env, inEnv);
    case (REDECLARED_ITEM(item = item), _) then mergeItemEnv(item, inEnv);
    else inEnv;
  end match;
end mergeItemEnv;

public function unmergeItemEnv
  "Merges an environment item's environment with the given environment."
  input Item inItem;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inItem, inEnv)
    local
      Item item;
      Env env;

    case (_, _::env) then env;
    else inEnv;
  end match;
end unmergeItemEnv;

public function getItemPrefixes
  input Item inItem;
  output SCode.Prefixes outPrefixes;
algorithm
  outPrefixes := match(inItem)
    local
      SCode.Prefixes pf;
      Item item;

    case CLASS(cls = SCode.CLASS(prefixes = pf)) then pf;
    case VAR(var = SCode.COMPONENT(prefixes = pf)) then pf;
    case REDECLARED_ITEM(item = item) then getItemPrefixes(item);
  end match;
end getItemPrefixes;

public function resolveRedeclaredItem
  input Item inItem;
  input Env inEnv;
  output Item outItem;
  output Env outEnv;
  output list<tuple<Item, Env>> outPreviousItem;
algorithm
  (outItem, outEnv, outPreviousItem) := match(inItem, inEnv)
    local
      Item item;
      Env env;

    case (REDECLARED_ITEM(item = item, declaredEnv = env), _) then (item, env, {(inItem, inEnv)});

    else (inItem, inEnv, {});

  end match;
end resolveRedeclaredItem;

public function getEnvExtendsTable
  input Env inEnv;
  output ExtendsTable outExtendsTable;
algorithm
  FRAME(extendsTable = outExtendsTable) :: _ := inEnv;
end getEnvExtendsTable;

public function getEnvExtendsFromTable
  input Env inEnv;
  output list<Extends> outExtends;
algorithm
  EXTENDS_TABLE(baseClasses = outExtends) := getEnvExtendsTable(inEnv);
end getEnvExtendsFromTable;

public function getDerivedClassRedeclares
"@author: adrpo
 returns the redeclares inside the extends table for the given class.
 The derived class should have only 1 extends"
 input SCode.Ident inDerivedName;
 input Absyn.TypeSpec inTypeSpec;
 input Env inEnv;
 output list<Redeclaration> outRedeclarations;
algorithm
  outRedeclarations := matchcontinue(inDerivedName, inTypeSpec, inEnv)
    local
      Absyn.Path bc, path;
      list<Redeclaration> rm;

    // only one extends!
    case (_, Absyn.TPATH(path, _), _)
      equation
        {EXTENDS(baseClass = bc, redeclareModifiers = rm)} =
          getEnvExtendsFromTable(inEnv);
        true = Absyn.pathSuffixOf(path, bc);
      then
        rm;

    case (_, Absyn.TPATH(path, _), _)
      equation
        {EXTENDS(baseClass = bc, redeclareModifiers = rm)} =
          getEnvExtendsFromTable(inEnv);
        false = Absyn.pathSuffixOf(path, bc);
        print("Derived paths are not the same: " + Absyn.pathString(path) + " != " + Absyn.pathString(bc) + "\n");
      then
        rm;

    // else nothing
    else {};

  end matchcontinue;
end getDerivedClassRedeclares;

public function setEnvExtendsTable
  input ExtendsTable inExtendsTable;
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  Option<Util.StatefulBoolean> is_used;
  Env rest_env;
algorithm
  FRAME(name, ty, tree, _, imps, is_used) :: rest_env := inEnv;
  outEnv := FRAME(name, ty, tree, inExtendsTable, imps, is_used) :: rest_env;
end setEnvExtendsTable;

public function setEnvClsAndVars
  input AvlTree inTree;
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  ExtendsTable ext;
  ImportTable imps;
  Option<Util.StatefulBoolean> is_used;
  Env rest_env;
algorithm
  FRAME(name, ty, _, ext, imps, is_used) :: rest_env := inEnv;
  outEnv := FRAME(name, ty, inTree, ext, imps, is_used) :: rest_env;
end setEnvClsAndVars;

public function mergePathWithEnvPath
  "Merges a path with the environment path."
  input Absyn.Path inPath;
  input Env inEnv;
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
  input Env inEnv;
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
    else inTS;

  end matchcontinue;
end mergeTypeSpecWithEnvPath;

public function prefixIdentWithEnv
  input String inIdent;
  input Env inEnv;
  output Absyn.Path outPath;
algorithm
  outPath := match(inIdent, inEnv)
    local
      Absyn.Path path;

    case (_, {FRAME(name = NONE())}) then Absyn.IDENT(inIdent);
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

    case RAW_MODIFIER(modifier = e) then e;
    case PROCESSED_MODIFIER(modifier = CLASS(cls = e)) then e;
    case PROCESSED_MODIFIER(modifier = VAR(var = e)) then e;
    case PROCESSED_MODIFIER(modifier = REDECLARED_ITEM(item = item))
      then getRedeclarationElement(PROCESSED_MODIFIER(item));
  end match;
end getRedeclarationElement;

public function getRedeclarationNameInfo
  input Redeclaration inRedeclare;
  output String outName;
  output SourceInfo outInfo;
algorithm
  (outName, outInfo) := match(inRedeclare)
    local
      SCode.Element el;
      String name;
      SourceInfo info;

    case PROCESSED_MODIFIER(modifier = ALIAS(name = name, info = info))
      then (name, info);

    else
      equation
        el = getRedeclarationElement(inRedeclare);
        (name, info) = SCode.elementNameInfo(el);
      then
        (name, info);

  end match;
end getRedeclarationNameInfo;

public function buildInitialEnv
  "Build a new environment that contains some things that can't be represented
  in ModelicaBuiltin or MetaModelicaBuiltin."
  output Env outInitialEnv;
protected
  AvlTree tree;
  ExtendsTable exts;
  ImportTable imps;
  Util.StatefulBoolean is_used;
  SCode.Program p;
  list<Absyn.Class> initialClasses;
algorithm
  tree := avlTreeNew();
  exts := newExtendsTable();
  imps := newImportTable();
  is_used := Util.makeStatefulBoolean(false);

  tree := addDummyClassToTree("String", tree);
  tree := addDummyClassToTree("Integer", tree);
  tree := addDummyClassToTree("spliceFunction", tree);

  outInitialEnv := {FRAME(NONE(), NORMAL_SCOPE(), tree, exts, imps, SOME(is_used))};

  // add the builtin classes from ModelicaBuiltin.mo and MetaModelicaBuiltin.mo
  (_,p) := Builtin.getInitialFunctions();
  outInitialEnv := extendEnvWithClasses(p, outInitialEnv);
end buildInitialEnv;

protected function addDummyClassToTree
  "Insert a dummy class into the AvlTree."
  input String inName;
  input AvlTree inTree;
  output AvlTree outTree;
protected
  SCode.Element cls;
algorithm
  cls := SCode.CLASS(inName, SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_CLASS(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()), SCode.noComment, Absyn.dummyInfo);
  outTree := avlTreeAdd(inTree, inName, CLASS(cls, emptyEnv, BUILTIN()));
end addDummyClassToTree;

// AVL Tree implementation
public type AvlKey = String;
public type AvlValue = Item;

public uniontype AvlTree
  "The binary tree data structure"
  record AVLTREENODE
    Option<AvlTreeValue> value "Value";
    Integer height "height of tree, used for balancing";
    Option<AvlTree> left "left subtree";
    Option<AvlTree> right "right subtree";
  end AVLTREENODE;
end AvlTree;

public uniontype AvlTreeValue
  "Each node in the binary tree can have a value associated with it."
  record AVLTREEVALUE
    AvlKey key "Key" ;
    AvlValue value "Value" ;
  end AVLTREEVALUE;
end AvlTreeValue;

protected function avlTreeNew
  "Return an empty tree"
  output AvlTree tree;
algorithm
  tree := AVLTREENODE(NONE(),0,NONE(),NONE());
end avlTreeNew;

public function printEnvStr
  input Env inEnv;
  output String outString;
protected
  Env env;
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
      FrameType ty;
      AvlTree tree;
      ExtendsTable exts;
      ImportTable imps;
      String name_str, ty_str, tree_str, ext_str, imp_str, out;

    case (FRAME(name, ty, tree, exts, imps, _))
      equation
        name_str = printFrameNameStr(name);
        ty_str = printFrameTypeStr(ty);
        tree_str = printAvlTreeStr(SOME(tree));
        ext_str = printExtendsTableStr(exts);
        imp_str = printImportTableStr(imps);
        name_str = "<<<" + ty_str + " frame " + name_str + ">>>\n";
        out = name_str +
              "\tImports:\n" + imp_str +
              "\n\tExtends:\n" + ext_str +
              "\n\tComponents:\n" + tree_str + "\n";
      then
        out;
  end match;
end printFrameStr;

protected function printFrameNameStr
  input Option<String> inFrame;
  output String outString;
algorithm
  outString := match(inFrame)
    local
      String name;

    case NONE() then "global";
    case SOME(name) then name;
  end match;
end printFrameNameStr;

protected function printFrameTypeStr
  input FrameType inFrame;
  output String outString;
algorithm
  outString := match(inFrame)
    case NORMAL_SCOPE() then "Normal";
    case ENCAPSULATED_SCOPE() then "Encapsulated";
    case IMPLICIT_SCOPE() then "Implicit";
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
    case (SOME(AVLTREENODE(value = NONE()))) then "";
    case (SOME(AVLTREENODE(value = SOME(value),  left = left, right = right)))
      equation
        left_str = printAvlTreeStr(left);
        right_str = printAvlTreeStr(right);
        value_str = printAvlValueStr(value);
        value_str = value_str + left_str + right_str;
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

    case (AVLTREEVALUE(key = key_str, value = CLASS()))
      then "\t\tClass " + key_str + "\n";

    case (AVLTREEVALUE(key = key_str, value = VAR()))
      then "\t\tVar " + key_str + "\n";

    case (AVLTREEVALUE(key = key_str, value = ALIAS(name = name, path = SOME(path))))
      equation
        alias_str = Absyn.pathString(path) + "." + name;
      then
        "\t\tAlias " + key_str + " -> " + alias_str + "\n";

    case (AVLTREEVALUE(key = key_str, value = ALIAS(name = name)))
      then "\t\tAlias " + key_str + " -> " + name + "\n";

    case (AVLTREEVALUE(key = key_str, value = REDECLARED_ITEM(item = i)))
      then "\t\tRedeclare " + key_str + " -> " + getItemName(i) + "\n";

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
  EXTENDS_TABLE(baseClasses = bcl, redeclaredElements = re, classExtendsInfo = cei) := inExtendsTable;
  outString := stringDelimitList(List.map(bcl, printExtendsStr), "\n") +
    "\n\t\tRedeclare elements:\n\t\t\t" +
    stringDelimitList(List.map1(re, SCodeDump.unparseElementStr, SCodeDump.defaultOptions), "\n\t\t\t") +
    "\n\t\tClass extends:\n\t\t\t" +
    Util.stringOption(Util.applyOption1(cei, SCodeDump.unparseElementStr, SCodeDump.defaultOptions));
end printExtendsTableStr;

public function printExtendsStr
  input Extends inExtends;
  output String outString;
protected
  Absyn.Path bc;
  list<Redeclaration> mods;
  String mods_str;
algorithm
  EXTENDS(baseClass = bc, redeclareModifiers = mods) := inExtends;
  mods_str := stringDelimitList(
    List.map(mods, printRedeclarationStr), "\n");
  outString := "\t\t" + Absyn.pathString(bc) + "(" + mods_str + ")";
end printExtendsStr;

public function printRedeclarationStr
  input Redeclaration inRedeclare;
  output String outString;
algorithm
  outString := matchcontinue(inRedeclare)
    local String name; Absyn.Path p;
    case (PROCESSED_MODIFIER(modifier = ALIAS(name = name, path = SOME(p))))
      then "ALIAS(" + Absyn.pathString(p) + "." + name + ")";
    case (PROCESSED_MODIFIER(modifier = ALIAS(name = name)))
      then "ALIAS(" + name + ")";
    else SCodeDump.unparseElementStr(getRedeclarationElement(inRedeclare),SCodeDump.defaultOptions);
  end matchcontinue;
end printRedeclarationStr;

protected function printImportTableStr
  input ImportTable inImports;
  output String outString;
protected
  list<Import> qual_imps, unqual_imps;
  String qual_str, unqual_str;
algorithm
  IMPORT_TABLE(qualifiedImports = qual_imps, unqualifiedImports = unqual_imps)
    := inImports;
  qual_str := stringDelimitList(
    List.map(qual_imps, Absyn.printImportString), "\n\t\t");
  unqual_str := stringDelimitList(
    List.map(unqual_imps, Absyn.printImportString), "\n\t\t");
  outString := "\t\t" + qual_str + unqual_str;
end printImportTableStr;

public function avlTreeAdd
  "Inserts a new value into the tree."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKey, inValue)
    local
      AvlKey key, rkey;
      AvlValue value;

    // empty tree
    case (AVLTREENODE(value = NONE(), left = NONE(), right = NONE()), _, _)
      then AVLTREENODE(SOME(AVLTREEVALUE(inKey, inValue)), 1, NONE(), NONE());

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))), key, value)
      then balance(avlTreeAdd2(inAvlTree, stringCompare(key, rkey), key, value));

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Env.avlTreeAdd failed"});
      then fail();

  end match;
end avlTreeAdd;

protected function avlTreeAdd2
  "Helper function to avlTreeAdd."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKeyComp, inKey, inValue)
    local
      AvlKey key;
      AvlValue value;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;
      SourceInfo info;

    // Don't allow replacing of nodes.
    case (_, 0, _, _) then inAvlTree;

    // Insert into right subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        1, key, value)
      equation
        t = createEmptyAvlIfNone(right);
        t = avlTreeAdd(t, key, value);
      then
        AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        -1, key, value)
      equation
        t = createEmptyAvlIfNone(left);
        t = avlTreeAdd(t, key, value);
      then
        AVLTREENODE(oval, h, SOME(t), right);
  end match;
end avlTreeAdd2;

public function avlTreeGet
  "Get a value from the binary tree given a key."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  output AvlValue outValue;
protected
  AvlKey rkey;
algorithm
  AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))) := inAvlTree;
  outValue := avlTreeGet2(inAvlTree, stringCompare(inKey, rkey), inKey);
end avlTreeGet;

protected function avlTreeGet2
  "Helper function to avlTreeGet."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  output AvlValue outValue;
algorithm
  outValue := match(inAvlTree, inKeyComp, inKey)
    local
      AvlKey key;
      AvlValue rval;
      AvlTree left, right;

    // Found match.
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(value = rval))), 0, _)
      then rval;

    // Search to the right.
    case (AVLTREENODE(right = SOME(right)), 1, key)
      then avlTreeGet(right, key);

    // Search to the left.
    case (AVLTREENODE(left = SOME(left)), -1, key)
      then avlTreeGet(left, key);
  end match;
end avlTreeGet2;

public function avlTreeReplace
  "Replaces the value of an already existing node in the tree with a new value."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKey, inValue)
    local
      AvlKey key, rkey;
      AvlValue value;

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))), key, value)
      then avlTreeReplace2(inAvlTree, stringCompare(key, rkey), key, value);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Env.avlTreeReplace failed"});
      then fail();

  end match;
end avlTreeReplace;

protected function avlTreeReplace2
  "Helper function to avlTreeReplace."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKeyComp, inKey, inValue)
    local
      AvlKey key;
      AvlValue value;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;

    // Replace this node.
    case (AVLTREENODE(value = SOME(_), height = h, left = left, right = right),
        0, key, value)
      then AVLTREENODE(SOME(AVLTREEVALUE(key, value)), h, left, right);

    // Insert into right subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        1, key, value)
      equation
        t = createEmptyAvlIfNone(right);
        t = avlTreeReplace(t, key, value);
      then
        AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        -1, key, value)
      equation
        t = createEmptyAvlIfNone(left);
        t = avlTreeReplace(t, key, value);
      then
        AVLTREENODE(oval, h, SOME(t), right);
  end match;
end avlTreeReplace2;

protected function createEmptyAvlIfNone
  "Help function to AvlTreeAdd"
    input Option<AvlTree> t;
    output AvlTree outT;
algorithm
  outT := match(t)
    case (NONE()) then avlTreeNew();
    case (SOME(outT)) then outT;
  end match;
end createEmptyAvlIfNone;

protected function balance
  "Balances an AvlTree"
  input AvlTree bt;
  output AvlTree outBt;
protected
  Integer d;
algorithm
  d := differenceInHeight(bt);
  outBt := doBalance(d, bt);
end balance;

protected function doBalance
  "Performs balance if difference is > 1 or < -1"
  input Integer difference;
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := match(difference, bt)
    case(-1, _) then computeHeight(bt);
    case( 0, _) then computeHeight(bt);
    case( 1, _) then computeHeight(bt);
    // d < -1 or d > 1
    else doBalance2(difference < 0, bt);
  end match;
end doBalance;

protected function doBalance2
"help function to doBalance"
  input Boolean inDiffIsNegative;
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := match(inDiffIsNegative,inBt)
    local AvlTree bt;
    case(true,bt)
      equation
        bt = doBalance3(bt);
        bt = rotateLeft(bt);
      then bt;
    case(false,bt)
      equation
        bt = doBalance4(bt);
        bt = rotateRight(bt);
      then bt;
  end match;
end doBalance2;

protected function doBalance3 "help function to doBalance2"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
    local
      AvlTree rr,bt;
    case(bt)
      equation
        true = differenceInHeight(Util.getOption(rightNode(bt))) > 0;
        rr = rotateRight(Util.getOption(rightNode(bt)));
        bt = setRight(bt,SOME(rr));
      then bt;
    else inBt;
  end matchcontinue;
end doBalance3;

protected function doBalance4 "help function to doBalance2"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
    local
      AvlTree rl,bt;
    case (bt)
      equation
        true = differenceInHeight(Util.getOption(leftNode(bt))) < 0;
        rl = rotateLeft(Util.getOption(leftNode(bt)));
        bt = setLeft(bt,SOME(rl));
      then bt;
    else inBt;
  end matchcontinue;
end doBalance4;

protected function setRight
  "set right treenode"
  input AvlTree node;
  input Option<AvlTree> right;
  output AvlTree outNode;
protected
  Option<AvlTreeValue> value;
  Option<AvlTree> l;
  Integer height;
algorithm
  AVLTREENODE(value, height, l, _) := node;
  outNode := AVLTREENODE(value, height, l, right);
end setRight;

protected function setLeft
  "set left treenode"
  input AvlTree node;
  input Option<AvlTree> left;
  output AvlTree outNode;
protected
  Option<AvlTreeValue> value;
  Option<AvlTree> r;
  Integer height;
algorithm
  AVLTREENODE(value, height, _, r) := node;
  outNode := AVLTREENODE(value, height, left, r);
end setLeft;

protected function leftNode
  "Retrieve the left subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  AVLTREENODE(left = subNode) := node;
end leftNode;

protected function rightNode
  "Retrieve the right subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  AVLTREENODE(right = subNode) := node;
end rightNode;

protected function exchangeLeft
  "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
protected
  AvlTree parent, node;
algorithm
  parent := setRight(inParent, leftNode(inNode));
  parent := balance(parent);
  node := setLeft(inNode, SOME(parent));
  outParent := balance(node);
end exchangeLeft;

protected function exchangeRight
  "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
protected
  AvlTree parent, node;
algorithm
  parent := setLeft(inParent, rightNode(inNode));
  parent := balance(parent);
  node := setRight(inNode, SOME(parent));
  outParent := balance(node);
end exchangeRight;

protected function rotateLeft
  "help function to balance"
  input AvlTree node;
  output AvlTree outNode "updated node";
algorithm
  outNode := exchangeLeft(Util.getOption(rightNode(node)), node);
end rotateLeft;

protected function rotateRight
  "help function to balance"
  input AvlTree node;
  output AvlTree outNode "updated node";
algorithm
  outNode := exchangeRight(Util.getOption(leftNode(node)), node);
end rotateRight;

protected function differenceInHeight
  "help function to balance, calculates the difference in height between left
  and right child"
  input AvlTree node;
  output Integer diff;
protected
  Option<AvlTree> l, r;
algorithm
  AVLTREENODE(left = l, right = r) := node;
  diff := getHeight(l) - getHeight(r);
end differenceInHeight;

protected function computeHeight
  "Compute the height of the AvlTree and store in the node info."
  input AvlTree bt;
  output AvlTree outBt;
protected
  Option<AvlTree> l,r;
  Option<AvlTreeValue> v;
  AvlValue val;
  Integer hl,hr,height;
algorithm
  AVLTREENODE(value = v as SOME(AVLTREEVALUE(value = val)),
    left = l, right = r) := bt;
  hl := getHeight(l);
  hr := getHeight(r);
  height := intMax(hl, hr) + 1;
  outBt := AVLTREENODE(v, height, l, r);
end computeHeight;

protected function getHeight
  "Retrieve the height of a node"
  input Option<AvlTree> bt;
  output Integer height;
algorithm
  height := match(bt)
    case(NONE()) then 0;
    case(SOME(AVLTREENODE(height = height))) then height;
  end match;
end getHeight;

public function printAvlTreeStrPP
  input AvlTree inTree;
  output String outString;
algorithm
  outString := printAvlTreeStrPP2(SOME(inTree), "");
end printAvlTreeStrPP;

protected function printAvlTreeStrPP2
  input Option<AvlTree> inTree;
  input String inIndent;
  output String outString;
algorithm
  outString := match(inTree, inIndent)
    local
      AvlKey rkey;
      Option<AvlTree> l, r;
      String s1, s2, res, indent;

    case (NONE(), _) then "";

    case (SOME(AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey)), left = l, right = r)), _)
      equation
        indent = inIndent + "  ";
        s1 = printAvlTreeStrPP2(l, indent);
        s2 = printAvlTreeStrPP2(r, indent);
        res = "\n" + inIndent + rkey + s1 + s2;
      then
        res;

    case (SOME(AVLTREENODE(value = NONE(), left = l, right = r)), _)
      equation
        indent = inIndent + "  ";
        s1 = printAvlTreeStrPP2(l, indent);
        s2 = printAvlTreeStrPP2(r, indent);
        res = "\n" + s1 + s2;
      then
        res;
  end match;
end printAvlTreeStrPP2;

annotation(__OpenModelica_Interface="frontend");
end NFSCodeEnv;
