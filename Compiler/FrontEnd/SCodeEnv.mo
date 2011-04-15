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

encapsulated package SCodeEnv
" file:        SCodeEnv.mo
  package:     SCodeEnv
  description: SCode flattening

  RCS: $Id$

  This module flattens the SCode representation by removing all extends, imports
  and redeclares, and fully qualifying class names.
"

public import Absyn;
public import SCode;
public import Util;

protected import Debug;
protected import Error;
protected import RTOpts;
protected import SCodeLookup;
protected import SCodeUtil;


public type Import = Absyn.Import;

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

public uniontype Extends
  record EXTENDS
    Absyn.Path baseClass;
    list<SCode.Element> redeclareModifiers;
    Absyn.Info info;
  end EXTENDS;
end Extends;

public uniontype ExtendsTable
  record EXTENDS_TABLE
    list<Extends> baseClasses;
    list<SCode.Element> classExtends;
  end EXTENDS_TABLE;
end ExtendsTable;

public uniontype FrameType
  record NORMAL_SCOPE end NORMAL_SCOPE;
  record ENCAPSULATED_SCOPE end ENCAPSULATED_SCOPE;
  record IMPLICIT_SCOPE end IMPLICIT_SCOPE;
end FrameType;

public uniontype Frame
  record FRAME
    Option<String> name;
    FrameType frameType;
    AvlTree clsAndVars;
    ExtendsTable extendsTable;
    ImportTable importTable;
    Util.StatefulBoolean isUsed "Used by SCodeDependency.";
  end FRAME;
end Frame;

public uniontype ClassType
  record USERDEFINED end USERDEFINED;
  record BUILTIN end BUILTIN;
  record CLASS_EXTENDS end CLASS_EXTENDS;
end ClassType;

public uniontype Item
  record VAR
    SCode.Element var;
    Util.StatefulBoolean isUsed "Used by SCodeDependency.";
  end VAR;

  record CLASS
    SCode.Element cls;
    Env env;
    ClassType classType;
  end CLASS;
end Item;

public type Env = list<Frame>;
public constant Env emptyEnv = {};

protected function qualifyRedeclare
  "Since a modifier might redeclare an element in a variable with a type that
  is not reachable from the component type we need to fully qualify the element. 
    Ex:
      A a(redeclare package P = P1)
  where P1 is not reachable from A."
  input SCode.Element inElement;
  input Env inEnv;
  output SCode.Element outElement;
algorithm
  outElement := match(inElement, inEnv)
    local
      SCode.Ident name, name2;
      Absyn.Ident id;
      SCode.Partial pp;
      SCode.Encapsulated ep;
      SCode.Prefixes prefixes;
      Option<Absyn.ConstrainClass> cc;
      Option<Absyn.ArrayDim> ad;
      Absyn.Path path;
      SCode.Mod mods;
      Option<SCode.Comment> cmt;
      Env env;
      SCode.Restriction res;
      Absyn.Info info;
      Absyn.InnerOuter io;
      SCode.Attributes attr;
      Option<Absyn.Exp> cond;
      Option<Absyn.ArrayDim> array_dim;

    case (SCode.CLASS(
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
          ), _)
      equation
        path = qualifyPath(path, inEnv, info, SOME(Error.LOOKUP_ERROR));
      then
        SCode.CLASS(name, prefixes, ep, pp, res,
            SCode.DERIVED(Absyn.TPATH(path, ad), mods, attr, cmt),
            info);

    case (SCode.CLASS(name = _), _) then inElement;

    case (SCode.COMPONENT(name, prefixes, attr, 
        Absyn.TPATH(path, array_dim), mods, cmt, cond, info), _)
      equation
        path = qualifyPath(path, inEnv, info, SOME(Error.LOOKUP_ERROR));
      then
        SCode.COMPONENT(name, prefixes, attr, 
          Absyn.TPATH(path, array_dim), mods, cmt, cond, info);

    else
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- SCodeFlatten.qualifyRedeclare failed on " +&
          SCode.printElementStr(inElement) +& " in " +&
          Absyn.pathString(getEnvPath(inEnv)));
      then
        fail();
  end match;
end qualifyRedeclare;

protected function qualifyPath
  "Qualifies a path by looking up a path in the environment, and merging the
  resulting path with it's environment."
  input Absyn.Path inPath;
  input Env inEnv;
  input Absyn.Info inInfo;
  input Option<Error.ErrorID> inErrorType;
  output Absyn.Path outPath;
protected
algorithm
  outPath := matchcontinue(inPath, inEnv, inInfo, inErrorType)
    local
      Absyn.Path path;
      Env env;

    case (_, _, _, _)
      equation
        (_, path, env) = SCodeLookup.lookupName(inPath, inEnv, inInfo,
          inErrorType);
        path = mergePathWithEnvPath(path, env);
      then
        path;

    else
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- SCodeFlatten.qualifyPath failed on " +&
          Absyn.pathString(inPath) +& " in " +&
          getEnvName(inEnv));
      then
        fail();
  end matchcontinue;
end qualifyPath;

protected function mergePathWithEnvPath
  "Merges a path with the environment path."
  input Absyn.Path inPath;
  input Env inEnv;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inPath, inEnv)
    local
      Absyn.Path path;
      Absyn.Ident id;

    // Try to merge the last identifier in the path with the environment path.
    case (_, _)
      equation
        id = Absyn.pathLastIdent(inPath);
        path = Absyn.joinPaths(getEnvPath(inEnv), Absyn.IDENT(id));
      then
        path;

    // If the previous case failed (which will happen at the top-scope when
    // getEnvPath fails), just return the path as it is.
    else then inPath;
  end matchcontinue;
end mergePathWithEnvPath;

public function joinPaths
  "Joins two paths. This functions is similar to Absyn.joinPaths, but with
  different semantics for fully qualified paths."
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  output Absyn.Path outPath;
algorithm
  outPath := match(inPath1, inPath2)
    local
      Absyn.Ident id;
      Absyn.Path path;

    // The second path is fully qualified, return only that path.
    case (_, Absyn.FULLYQUALIFIED(path = _)) then inPath2;
    case (Absyn.IDENT(name = id), _) then Absyn.QUALIFIED(id, inPath2);
    case (Absyn.QUALIFIED(name = id, path = path), _)
      equation
        path = joinPaths(path, inPath2);
      then
        Absyn.QUALIFIED(id, path);

    // The first path is fully qualified, merge it with the second path.
    case (Absyn.FULLYQUALIFIED(path = path), _)
      equation
        path = joinPaths(path, inPath2);
      then
        Absyn.FULLYQUALIFIED(path);
  end match;
end joinPaths;

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
protected
  Frame cls_env;
  AvlTree cls_and_vars;
  Item item;
algorithm
  FRAME(clsAndVars = cls_and_vars) :: _ := inEnv;
  item := avlTreeGet(cls_and_vars, inName);
  {cls_env} := getItemEnv(item);
  outEnv := enterFrame(cls_env, inEnv);
end enterScope;

public function enterFrame
  input Frame inFrame;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := inFrame :: inEnv;
end enterFrame;
  
protected function qualifyExtends
  input Extends inExtends;
  input Env inEnv;
  output Extends outExtends;
algorithm
  outExtends := matchcontinue(inExtends, inEnv)
    local
      Absyn.Path bc;
      list<SCode.Element> redecl;
      Absyn.Info info;
      Env env;
      Absyn.Ident id;

    case (EXTENDS(baseClass = Absyn.FULLYQUALIFIED(path = _)), _)
      then inExtends;

    case (EXTENDS(Absyn.IDENT(name = id), _, _), _)
      equation
        _ = SCodeLookup.lookupBuiltinType(id);
      then
        inExtends;

    case (EXTENDS(bc, redecl, info), _)
      equation
        bc = qualifyExtends2(bc, info, inEnv);
        bc = Absyn.FULLYQUALIFIED(bc);
      then
        EXTENDS(bc, redecl, info);

    case (EXTENDS(baseClass = bc), _)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- SCodeFlatten.qualifyExtends failed on " +&
          Absyn.pathString(bc) +& " in " +&
          getEnvName(inEnv));
      then
        fail();

    else inExtends;
  end matchcontinue;
end qualifyExtends;

protected function qualifyExtends2
  input Absyn.Path inBaseClass;
  input Absyn.Info inInfo;
  input Env inEnv;
  output Absyn.Path outBaseClass;
algorithm
  outBaseClass := matchcontinue(inBaseClass, inInfo, inEnv)
    local
      Absyn.Path bc;
      Absyn.Info info;
      Env env;

    case (_, _, _)
      equation
        (_, bc, env) = SCodeLookup.lookupNameInPackage(inBaseClass, inEnv);
        bc = mergePathWithEnvPath(bc, env);
      then
        bc;

    case (_, _, _)
      equation
        bc = Absyn.removePartialPrefix(getEnvPath(inEnv), inBaseClass);
        bc = qualifyPath(bc, inEnv, inInfo, NONE());
      then
        bc;
  end matchcontinue;
end qualifyExtends2;

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
    else then NORMAL_SCOPE();
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
  outFrame := FRAME(inName, inType, tree, exts, imps, is_used);
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
  outExtends := EXTENDS_TABLE({}, {});
end newExtendsTable;

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
  outVarItem := VAR(inVar, is_used);
end newVarItem;

public function extendEnvWithClasses
  "Extends the environment with a list of classes."
  input list<SCode.Element> inClasses;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := Util.listFold(inClasses, extendEnvWithClass, inEnv);
end extendEnvWithClasses;

protected function extendEnvWithClass
  "Extends the environment with a class."
  input SCode.Element inClass;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := extendEnvWithClassDef(inClass, inEnv);
end extendEnvWithClass;

protected function getClassType
  "Returns a class's type."
  input SCode.ClassDef inClassDef;
  output ClassType outType;
algorithm
  outType := match(inClassDef)
    // A builtin class.
    case (SCode.PARTS(externalDecl = SOME(Absyn.EXTERNALDECL(
        lang = SOME("builtin"))))) 
      then BUILTIN();
    // A class added by extendEnvWithClassExtends.
    case (SCode.PARTS(externalDecl = SOME(Absyn.EXTERNALDECL(
        lang = SOME("class_extends")))))
      then CLASS_EXTENDS();
    // A user-defined class (i.e. not builtin).
    else then USERDEFINED();
  end match;
end getClassType;

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
  Util.StatefulBoolean is_used;
algorithm
  FRAME(name = name, frameType = ty, clsAndVars = tree, importTable = imps,
    isUsed = is_used) :: rest := inEnv;
  exts := newExtendsTable();
  outEnv := FRAME(name, ty, tree, exts, imps, is_used) :: rest;
end removeExtendsFromLocalScope;
  
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
  Util.StatefulBoolean is_used;
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
  Util.StatefulBoolean is_used;
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

    else then inItem;
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

    case CLASS(env = {FRAME(isUsed = is_used)})
      then Util.getStatefulBoolean(is_used);

    case VAR(isUsed = is_used)
      then Util.getStatefulBoolean(is_used);

    else false;
  end match;
end isItemUsed;

protected function extendEnvWithClassDef
  "Extends the environment with a class definition."
  input SCode.Element inClassDefElement;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inClassDefElement, inEnv)
    local
      String cls_name;
      Env class_env, env;
      SCode.ClassDef cdef;
      Absyn.Path cls_path;
      Option<Absyn.ExternalDecl> ext_decl;
      ClassType cls_type;

    // Class extends are added to the extends table for later use.
    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = _)), _)
      then addClassExtendsToEnvExtendsTable(inClassDefElement, inEnv);

    // A normal class.
    case (SCode.CLASS(name = cls_name, classDef = cdef), _)
      equation
        // Create a new environment and add the class's components to it.
        class_env = makeClassEnvironment(inClassDefElement);
        cls_type = getClassType(cdef);
        // Add the class with it's environment to the environment.
        env = extendEnvWithItem(newClassItem(inClassDefElement, class_env, cls_type), 
          inEnv, cls_name);
      then
        env;
  end match;
end extendEnvWithClassDef;

protected function makeClassEnvironment
  input SCode.Element inClassDefElement;
  output Env outClassEnv;
protected
  SCode.ClassDef cdef;
  SCode.Element cls;
  String cls_name;
  Env env;
  Absyn.Info info;
algorithm
  SCode.CLASS(name = cls_name, classDef = cdef, info = info) := inClassDefElement;
  env := openScope(emptyEnv, inClassDefElement);
  outClassEnv := extendEnvWithClassComponents(cls_name, cdef, env, info);
end makeClassEnvironment;

protected function extendEnvWithVar
  "Extends the environment with a variable."
  input SCode.Element inVar;
  input Env inEnv;
  output Env outEnv;
protected
  String var_name;
  Util.StatefulBoolean is_used;
algorithm
  SCode.COMPONENT(name = var_name) := inVar;
  is_used := Util.makeStatefulBoolean(false);
  outEnv := extendEnvWithItem(VAR(inVar, is_used), inEnv, var_name);
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
  Util.StatefulBoolean is_used;
algorithm
  FRAME(name, ty, tree, exts, imps, is_used) :: rest := inEnv;
  tree := avlTreeAdd(tree, inItemName, inItem);
  outEnv := FRAME(name, ty, tree, exts, imps, is_used) :: rest;
end extendEnvWithItem;

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
      Absyn.Info info;
      Boolean hidden;
      Util.StatefulBoolean is_used;

    // Unqualified imports
    case (SCode.IMPORT(imp = imp as Absyn.UNQUAL_IMPORT(path = _)), 
        FRAME(name, ty, tree, exts, 
          IMPORT_TABLE(hidden, qual_imps, unqual_imps), is_used) :: rest)
      equation
        unqual_imps = imp :: unqual_imps;
      then
        FRAME(name, ty, tree, exts, 
          IMPORT_TABLE(hidden, qual_imps, unqual_imps), is_used) :: rest;

    // Qualified imports
    case (SCode.IMPORT(imp = imp, info = info), FRAME(name, ty, tree, exts,
        IMPORT_TABLE(hidden, qual_imps, unqual_imps), is_used) :: rest)
      equation
        imp = translateQualifiedImportToNamed(imp);
        checkUniqueQualifiedImport(imp, qual_imps, info);
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
    case Absyn.NAMED_IMPORT(name = _) then inImport;

    // Get the last identifier from the import and use that as the name.
    case Absyn.QUAL_IMPORT(path = path)
      equation
        name = Absyn.pathLastIdent(path);
      then
        Absyn.NAMED_IMPORT(name, path);
  end match;
end translateQualifiedImportToNamed;

protected function extendEnvWithExtends
  "Extends the environment with an extends-clause."
  input SCode.Element inExtends;
  input Env inEnv;
  output Env outEnv;
protected
  Absyn.Path bc;
  SCode.Mod mods;
  list<SCode.Element> redecls;
  Absyn.Info info;
algorithm
  SCode.EXTENDS(baseClassPath = bc, modifications = mods, info = info) := 
    inExtends;
  redecls := extractRedeclaresFromModifier(mods);
  outEnv := addExtendsToEnvExtendsTable(EXTENDS(bc, redecls, info), inEnv);
end extendEnvWithExtends;

public function replaceRedeclaredClassesInEnv
  "If a variable has modifications that redeclare classes in it's instance we
  need to replace those classes in the environment so that the lookup finds the
  right classes. This function takes a list of redeclares from a variables
  modifications and applies them to the environment of the variables type."
  input list<SCode.Element> inRedeclares "The redeclares from the modifications.";
  input Item inItem "The type of the variable.";
  input Env inTypeEnv "The enclosing scopes of the type.";
  input Env inVarEnv "The environment in which the variable was declared.";
  output Item outItem;
  output Env outEnv;
algorithm
  (outItem, outEnv) := matchcontinue(inRedeclares, inItem, inTypeEnv, inVarEnv)
    local
      list<SCode.Element> redeclares;
      SCode.Element cls;
      Env env;
      Frame item_env;
      ClassType cls_ty;

    case (_, VAR(var = _), _, _) then (inItem, inTypeEnv);

    case (_, CLASS(cls = cls, env = {item_env}, classType = cls_ty), _, _)
      equation
        redeclares = Util.listMap1(inRedeclares, qualifyRedeclare, inVarEnv);
        // Merge the types environment with it's enclosing scopes to get the
        // enclosing scopes of the classes we need to replace.
        env = enterFrame(item_env, inTypeEnv);
        env = Util.listFold(redeclares, replaceRedeclaredElementInEnv, env);
        item_env :: env = env;
      then
        (CLASS(cls, {item_env}, cls_ty), env);

    else
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.trace("- SCodeFlatten.replaceRedeclaredClassesInEnv failed for ");
        Debug.traceln(getItemName(inItem) +& " in " +& getEnvName(inVarEnv));
      then
        fail();
  end matchcontinue;
end replaceRedeclaredClassesInEnv;

public function extractRedeclaresFromModifier
  "Returns a list of redeclare elements given a redeclaration modifier."
  input SCode.Mod inMod;
  output list<SCode.Element> outRedeclares;
algorithm
  outRedeclares := match(inMod)
    local
      list<SCode.SubMod> sub_mods;
      list<SCode.Element> redeclares;
    
    case (SCode.MOD(subModLst = sub_mods))
      equation
        redeclares = Util.listFold(sub_mods, extractRedeclareFromSubMod, {});
      then
        redeclares;

    else then {};
  end match;
end extractRedeclaresFromModifier;

protected function extractRedeclareFromSubMod
  "Checks a submodifier and adds the redeclare element to the list of redeclares
  if the modifier is a redeclaration modifier."
  input SCode.SubMod inMod;
  input list<SCode.Element> inRedeclares;
  output list<SCode.Element> outRedeclares;
algorithm
  outRedeclares := match(inMod, inRedeclares)
    local
      SCode.Element redecl;

    // Redeclaration of a class definition.
    case (SCode.NAMEMOD(A = SCode.REDECL(elementLst = 
        {redecl as SCode.CLASS(name = _)})), _)
      then redecl :: inRedeclares;

    // Redeclaration of a component.
    case (SCode.NAMEMOD(A = SCode.REDECL(elementLst =
        {redecl as SCode.COMPONENT(name = _)})), _)
      then redecl :: inRedeclares;

    // Not a redeclaration.
    else then inRedeclares;
  end match;
end extractRedeclareFromSubMod;

protected function addExtendsToEnvExtendsTable
  "Adds an Extents to the environment."
  input Extends inExtends;
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  list<Extends> exts;
  list<SCode.Element> ce;
  Env rest_env;
  Util.StatefulBoolean is_used;
algorithm
  FRAME(name, ty, tree, EXTENDS_TABLE(exts, ce), imps, is_used) :: rest_env := inEnv;
  exts := inExtends :: exts;
  outEnv := FRAME(name, ty, tree, EXTENDS_TABLE(exts, ce), imps, is_used) :: rest_env;
end addExtendsToEnvExtendsTable;

protected function addClassExtendsToEnvExtendsTable
  "Adds a class extends to the environment."
  input SCode.Element inClassExtends;
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  list<Extends> exts;
  list<SCode.Element> ce;
  Env rest_env;
  Util.StatefulBoolean is_used;
algorithm
  FRAME(name, ty, tree, EXTENDS_TABLE(exts, ce), imps, is_used) :: rest_env := inEnv;
  ce := inClassExtends :: ce;
  outEnv := FRAME(name, ty, tree, EXTENDS_TABLE(exts, ce), imps, is_used) :: rest_env;
end addClassExtendsToEnvExtendsTable;

protected function extendEnvWithClassComponents
  "Extends the environment with a class's components."
  input String inClassName;
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Env outEnv;
algorithm
  outEnv := match(inClassName, inClassDef, inEnv, inInfo)
    local
      list<SCode.Element> el;
      list<SCode.Enum> enums;
      Absyn.TypeSpec enum_type;
      Env env;
      Absyn.Path path;
      SCode.Mod mods;
      Absyn.TypeSpec ty;

    case (_, SCode.PARTS(elementLst = el), _, _)
      equation
        env = Util.listFold(el, extendEnvWithElement, inEnv);
      then
        env;

    case (_, SCode.DERIVED(typeSpec = ty as Absyn.TPATH(path = path),
        modifications = mods), _, _)
      equation
        env = extendEnvWithExtends(SCode.EXTENDS(path, SCode.PUBLIC(), mods, NONE(),
          inInfo), inEnv);
      then
        env;

    case (_, SCode.ENUMERATION(enumLst = enums), _, _)
      equation
        enum_type = Absyn.TPATH(Absyn.IDENT(inClassName), NONE());
        env = Util.listFold1(enums, extendEnvWithEnum, enum_type, inEnv);
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
      SCode.Element cls;

    case (SCode.COMPONENT(name = _), _)
      equation
        env = extendEnvWithVar(inElement, inEnv);
      then
        env;

    case (SCode.CLASS(name = name, prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE())), _)
      equation
        false = isClassExtends(inElement);
        env = addClassExtendsToEnvExtendsTable(inElement, inEnv);
        env = extendEnvWithClassDef(inElement, env);
      then
        env;

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

protected function isClassExtends
  input SCode.Element inClass;
  output Boolean outResult;
algorithm
  outResult := match(inClass)
    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = _))) 
      then true;

    else false;
  end match;
end isClassExtends;

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
        false = Util.listContainsWithCompareFunc(inImport, inImports,
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
protected
  Absyn.Ident name1, name2;
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

protected function extendEnvWithEnum
  "Extends the environment with an enumeration."
  input SCode.Enum inEnum;
  input Absyn.TypeSpec inEnumType;
  input Env inEnv;
  output Env outEnv;
protected
  SCode.Element enum_lit;
  SCode.Ident lit_name;
algorithm
  SCode.ENUM(literal = lit_name) := inEnum;
  enum_lit := SCode.COMPONENT(lit_name, SCode.defaultPrefixes,
    SCode.ATTR({}, SCode.NOT_FLOW(), SCode.NOT_STREAM(), SCode.RO(), SCode.CONST(), Absyn.BIDIR()),
    inEnumType, SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);
  outEnv := extendEnvWithElement(enum_lit, inEnv);
end extendEnvWithEnum;

public function extendEnvWithIterators
  "Extends the environment with a new scope and adds a list of iterators to it."
  input Absyn.ForIterators inIterators;
  input Env inEnv;
  output Env outEnv;
protected
  Frame frame;
algorithm
  frame := newFrame(SOME("$for$"), IMPLICIT_SCOPE());
  outEnv := Util.listFold(inIterators, extendEnvWithIterator, frame :: inEnv);
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
    SCode.ATTR({}, SCode.NOT_FLOW(), SCode.NOT_STREAM(), SCode.RO(), SCode.CONST(), Absyn.BIDIR()),
    Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
    NONE(), NONE(), Absyn.dummyInfo);
  outEnv := extendEnvWithElement(iter, inEnv);
end extendEnvWithIterator;

public function extendEnvWithMatch
  "Extends the environment with a match-expression, i.e. opens a new scope and
  adds the local declarations in the match to it."
  input Absyn.Exp inMatchExp;
  input Env inEnv;
  output Env outEnv;
protected
  Frame frame;
  list<Absyn.ElementItem> local_decls;
algorithm
  frame := newFrame(SOME("$match$"), IMPLICIT_SCOPE());
  Absyn.MATCHEXP(localDecls = local_decls) := inMatchExp;
  outEnv := Util.listFold(local_decls, extendEnvWithElementItem, 
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
        env = Util.listFold(el, extendEnvWithElement, inEnv);
      then 
        env;

    else then inEnv;
  end match;
end extendEnvWithElementItem;

public function updateExtendsInEnv
  "While building the environment we store all class extends in the extends
  table. This function will go through the environment and insert all class
  extends into the environment instead. This is done because we need to know
  which class is extended (see comment in extendsEnvWithClassExtends), which
  means we need a complete environment to be able to do look up before this can
  be done."
  input Env inEnv;
  output Env outEnv;
protected
  Env env, rest_env;
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  list<Extends> bcl;
  list<SCode.Element> ce;
  ImportTable imps;
  Util.StatefulBoolean is_used;
  ExtendsTable ex;
algorithm
  FRAME(extendsTable = EXTENDS_TABLE(classExtends = ce)) :: _ := inEnv;
  env := Util.listFold(ce, extendEnvWithClassExtends, inEnv);
  FRAME(name, ty, tree, EXTENDS_TABLE(bcl, _), imps, is_used) :: rest_env := env;
  ex := newExtendsTable();
  env := enterFrame(FRAME(name, ty, tree, ex, imps, is_used), rest_env);
  bcl := Util.listMap1(bcl, qualifyExtends, env);
  SOME(tree) := insertClassExtendsIntoClassEnv(SOME(tree), inEnv);
  outEnv := FRAME(name, ty, tree, EXTENDS_TABLE(bcl, {}), imps, is_used) :: rest_env;
end updateExtendsInEnv;

protected function insertClassExtendsIntoClassEnv
  "Helper function to insertClassExtendsIntoEnv. Recurses through the class tree
  and insert class extends into the environment with insertClassExtendsIntoEnv."
  input Option<AvlTree> inTree;
  input Env inEnv;
  output Option<AvlTree> outTree;
algorithm
  outTree := match(inTree, inEnv)
    local
      String name;
      Integer h;
      Option<AvlTree> left, right;
      Env rest_env, env;
      SCode.Element cls;
      Frame class_frame;
      Option<AvlTreeValue> value;
      Item item;
      ClassType cls_ty;

    case (NONE(), _) then inTree;

    case (SOME(AVLTREENODE(value = SOME(AVLTREEVALUE(
        key = name, value = CLASS(cls = cls, env = {class_frame}, 
          classType = cls_ty))),
        height = h, left = left, right = right)), _)
      equation
        env = enterFrame(class_frame, inEnv);
        class_frame :: rest_env = updateExtendsInEnv(env);
        left = insertClassExtendsIntoClassEnv(left, inEnv);
        right = insertClassExtendsIntoClassEnv(right, inEnv);
        item = CLASS(cls, {class_frame}, cls_ty);
      then
        SOME(AVLTREENODE(SOME(AVLTREEVALUE(name, item)), h, left, right));

    case (SOME(AVLTREENODE(value = value, height = h, 
        left = left, right = right)), _)
      equation
        left = insertClassExtendsIntoClassEnv(left, inEnv);
        right = insertClassExtendsIntoClassEnv(right, inEnv);
      then
        SOME(AVLTREENODE(value, h, left, right));
  end match;
end insertClassExtendsIntoClassEnv;

protected function replaceRedeclaredElementInEnv
  "Replaces a redeclared element in the environment."
  input SCode.Element inRedeclare;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inRedeclare, inEnv)
    local
      SCode.Ident name;
      SCode.Element cls;
      Env env;
      Absyn.Path path;
      Option<Env> opt_env;
      Absyn.Info info;

    // A redeclared class definition.
    case (SCode.CLASS(name = name, info = info), _)
      equation
        (_, path, env) = 
          SCodeLookup.lookupClassName(Absyn.IDENT(name), inEnv, info);
        path = joinPaths(getEnvPath(env), path);
        env = replaceElementInEnv(path, inRedeclare, inEnv);
      then
        env;

    // A redeclared component.
    case (SCode.COMPONENT(name = name, info = info), _)
      equation
        (_, path, env) = 
          SCodeLookup.lookupVariableName(Absyn.IDENT(name), inEnv, info);
        path = joinPaths(getEnvPath(env), path);
        env = replaceElementInEnv(path, inRedeclare, inEnv);
      then
        env;

    else
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- SCodeEnv.replaceRedeclaredElementInEnv failed on " +&
          SCode.elementName(inRedeclare) +& " in " +& getEnvName(inEnv));
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
  input SCode.Element inElement;
  input Env inEnv;
  output Env outEnv;
protected
  Env env;
  Boolean next_scope_available;
  Frame f;
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

    case (Absyn.QUALIFIED(name = name), _ :: FRAME(name = SOME(scope_name)) :: _)
      then stringEqual(name, scope_name);

    else then false;
  end match;
end checkNextScopeAvailability;

protected function replaceElementInEnv2
  "Helper function to replaceClassInEnv."
  input Absyn.Path inPath;
  input SCode.Element inElement;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := replaceElementInEnv3(inPath, inElement, inEnv,
    checkNextScopeAvailability(inPath, inEnv));
end replaceElementInEnv2;

protected function replaceElementInEnv3
  "Helper function to replaceClassInEnv."
  input Absyn.Path inPath;
  input SCode.Element inElement;
  input Env inEnv;
  input Boolean inNextScopeAvailable;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inPath, inElement, inEnv, inNextScopeAvailable)
    local
      String name, scope_name;
      Absyn.Path path;
      Env env, rest_env;
      Frame f;

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
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- SCodeFlatten.replaceElementInEnv3 failed.");
      then
        fail();

  end matchcontinue;
end replaceElementInEnv3;

protected function replaceElementInScope
  "Replaces an element in the current scope."
  input SCode.Ident inElementName;
  input SCode.Element inElement;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inElementName, inElement, inEnv)
    local
      Option<String> name;
      FrameType ty;
      AvlTree tree;
      ExtendsTable exts;
      ImportTable imps;
      Env env, class_env;
      Util.StatefulBoolean is_used;

    case (_, SCode.CLASS(name = _), 
        FRAME(name, ty, tree, exts, imps, is_used) :: env)
      equation
        class_env = makeClassEnvironment(inElement);
        tree = avlTreeReplace(tree, inElementName, 
          newClassItem(inElement, class_env, USERDEFINED()));
      then
        FRAME(name, ty, tree, exts, imps, is_used) :: env;

    case (_, SCode.COMPONENT(name = _),
        FRAME(name, ty, tree, exts, imps, is_used) :: env)
      equation
        tree = avlTreeReplace(tree, inElementName, newVarItem(inElement, false));
      then
        FRAME(name, ty, tree, exts, imps, is_used) :: env;

  end match;
end replaceElementInScope;

protected function replaceElementInClassEnv
  "Replaces an element in the environment of a class."
  input Absyn.Path inClassPath;
  input SCode.Element inElement;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inClassPath, inElement, inEnv)
    local
      Option<String> frame_name;
      FrameType ty;
      AvlTree tree;
      ExtendsTable exts;
      ImportTable imps;
      Env rest_env, class_env, env;
      Item item;
      String name;
      Absyn.Path path;
      SCode.Element cls;
      Util.StatefulBoolean is_used;
      ClassType cls_ty;

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
        FRAME(frame_name, ty, tree, exts, imps, is_used) :: rest_env)
      equation
        CLASS(cls = cls, env = class_env, classType = cls_ty) = 
          avlTreeGet(tree, name);
        class_env = replaceElementInClassEnv(path, inElement, class_env);
        tree = avlTreeReplace(tree, name, CLASS(cls, class_env, cls_ty));
      then
        FRAME(frame_name, ty, tree, exts, imps, is_used) :: rest_env;

  end match;
end replaceElementInClassEnv;

protected function extendEnvWithClassExtends
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
      Env env;
      SCode.Mod mods;
      Option<Absyn.ExternalDecl> ext_decl;
      list<SCode.Equation> nel, iel;
      list<SCode.AlgorithmSection> nal, ial;

    // When a 'redeclare class extends X' is encountered we insert a 'class X
    // extends BaseClass.X' into the environment, with the same elements as the
    // class extends clause. BaseClass is the class that class X is inherited
    // from. This allows use to look up elements in class extends, because
    // lookup can handle normal extends. To be able to differentiate between
    // normal classes and classes added by this function we mark them as
    // 'external "class_extends"'.
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
          initialAlgorithmLst = ial)),
        info = info), _)
      equation
        // Look up which extends the base class comes from and add it to the
        // base class name.
        path = SCodeLookup.lookupBaseClass(bc, inEnv, info);
        path = Absyn.joinPaths(path, Absyn.IDENT(bc));
        // Insert a 'class bc extends path' into the environment.
        el = SCode.EXTENDS(path, SCode.PUBLIC(), mods, NONE(), info) :: el;
        ext_decl = SOME(Absyn.EXTERNALDECL(NONE(), SOME("class_extends"), 
          NONE(), {}, NONE()));
        env = extendEnvWithClass(SCode.CLASS(bc, prefixes, ep, pp, res, 
          SCode.PARTS(el, nel, iel, nal, ial, ext_decl, {}, NONE()), info), inEnv);
      then env;

    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = bc), info = info), _)
      equation
        Error.addSourceMessage(Error.INVALID_REDECLARATION_OF_CLASS,
          {bc}, info);
      then
        fail();

    case (SCode.CLASS(name = cls_name, info = info), _)
      equation
        path = SCodeLookup.lookupBaseClass(cls_name, inEnv, info);
        env = addRedeclareToEnvExtendsTable(inClassExtends, path, inEnv, info);
      then
        env;

  end matchcontinue;
end extendEnvWithClassExtends;

protected function addRedeclareToEnvExtendsTable
  input SCode.Element inClass;
  input Absyn.Path inBaseClass;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  Util.StatefulBoolean iu;
  list<Extends> bcl;
  list<SCode.Element> ce;
  Env rest_env;
algorithm
  FRAME(name, ty, tree, EXTENDS_TABLE(bcl, ce), imps, iu) :: rest_env := inEnv;
  bcl := addRedeclareToEnvExtendsTable2(inClass, inBaseClass, bcl);
  outEnv := FRAME(name, ty, tree, EXTENDS_TABLE(bcl, ce), imps, iu) :: rest_env;
end addRedeclareToEnvExtendsTable;

protected function addRedeclareToEnvExtendsTable2
  input SCode.Element inClass;
  input Absyn.Path inBaseClass;
  input list<Extends> inExtends;
  output list<Extends> outExtends;
algorithm
  outExtends := matchcontinue(inClass, inBaseClass, inExtends)
    local
      Extends ex;
      list<Extends> exl;
      Absyn.Path bc;
      list<SCode.Element> el;
      Absyn.Info info;
      SCode.Ident cls_name;

    case (SCode.CLASS(name = cls_name), _, (ex as EXTENDS(bc, el, info)) :: exl)
      equation
        true = Absyn.pathEqual(inBaseClass, bc);
        ex = EXTENDS(bc, inClass :: el, info);
      then
        ex :: exl;

    case (_, _, ex :: exl)
      equation
        exl = addRedeclareToEnvExtendsTable2(inClass, inBaseClass, exl);
      then
        ex :: exl;
    
  end matchcontinue;
end addRedeclareToEnvExtendsTable2;

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

    else then "";
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

protected function getItemInfo
  "Returns the Absyn.Info of an environment item."
  input Item inItem;
  output Absyn.Info outInfo;
algorithm
  outInfo := match(inItem)
    local
      Absyn.Info info;

    case VAR(var = SCode.COMPONENT(info = info)) then info;
    case CLASS(cls = SCode.CLASS(info = info)) then info;
  end match;
end getItemInfo;

protected function getItemName
  "Returns the name of an environment item."
  input Item inItem;
  output String outName;
algorithm
  outName := match(inItem)
    local String name;

    case VAR(var = SCode.COMPONENT(name = name)) then name;
    case CLASS(cls = SCode.CLASS(name = name)) then name;
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

    case (CLASS(env = env)) then env;
  end match;
end getItemEnv;

public function mergeItemEnv
  "Merges an environment item's environment with the given environment."
  input Item inItem;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inItem, inEnv)
    local
      Frame cls_env;

    case (CLASS(env = {cls_env}), _) then enterFrame(cls_env, inEnv);
    else then inEnv;
  end match;
end mergeItemEnv;

public function buildInitialEnv
  "Build a new environment that contains some things that can't be represented
  in ModelicaBuiltin or MetaModelicaBuiltin."
  output Env outInitialEnv;
public
  AvlTree tree;
  ExtendsTable exts;
  ImportTable imps;
  Util.StatefulBoolean is_used;
algorithm
  tree := avlTreeNew();
  exts := newExtendsTable();
  imps := newImportTable();
  is_used := Util.makeStatefulBoolean(false);

  tree := addDummyClassToTree("time", tree);
  tree := addDummyClassToTree("String", tree);
  tree := addDummyClassToTree("Integer", tree);
  tree := addDummyClassToTree("spliceFunction", tree);

  outInitialEnv := {FRAME(NONE(), NORMAL_SCOPE(), tree, exts, imps, is_used)};
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
    SCode.PARTS({}, {}, {}, {}, {}, NONE(), {}, NONE()), Absyn.dummyInfo);
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
  outString := Util.stringDelimitList(Util.listMap(env, printFrameStr), "\n");
end printEnvStr;

protected function printFrameStr
  input Frame inFrame;
  output String outString;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ExtendsTable exts;
  ImportTable imps;
  String name_str, ty_str, tree_str, ext_str, imp_str;
algorithm
  FRAME(name, ty, tree, exts, imps, _) := inFrame;
  name_str := printFrameNameStr(name);
  ty_str := printFrameTypeStr(ty);
  tree_str := printAvlTreeStr(SOME(tree));
  ext_str := printExtendsTableStr(exts);
  imp_str := printImportTableStr(imps);
  name_str := "<<<" +& ty_str +& " frame " +& name_str +& ">>>\n";
  outString := name_str +& 
    "\tImports:\n" +& imp_str +&
    "\n\tExtends:\n" +& ext_str +&
    "\n\tComponents:\n" +& tree_str +& "\n";
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

    case (NONE()) then "";
    case (SOME(AVLTREENODE(value = NONE()))) then "";
    case (SOME(AVLTREENODE(value = SOME(value), left = left, right = right)))
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
      String key_str;

    case (AVLTREEVALUE(key = key_str, value = CLASS(cls = _)))
      then "\t\tClass " +& key_str +& "\n";

    case (AVLTREEVALUE(key = key_str, value = VAR(var = _)))
      then "\t\tVar " +& key_str +& "\n";

  end match;
end printAvlValueStr;

protected function printExtendsTableStr
  input ExtendsTable inExtendsTable;
  output String outString;
protected
  list<Extends> bcl;
algorithm
  EXTENDS_TABLE(baseClasses = bcl) := inExtendsTable;
  outString := Util.stringDelimitList(Util.listMap(bcl, printExtendsStr), "\n");
end printExtendsTableStr;

protected function printExtendsStr
  input Extends inExtends;
  output String outString;
protected
  Absyn.Path bc;
  list<SCode.Element> mods;
  String mods_str;
algorithm
  EXTENDS(baseClass = bc, redeclareModifiers = mods) := inExtends;
  mods_str := Util.stringDelimitList(
    Util.listMap(mods, SCode.printElementStr), "\n");
  outString := "\t\t" +& Absyn.pathString(bc) +& "(" +& mods_str +& ")";
end printExtendsStr;

protected function printImportTableStr
  input ImportTable inImports;
  output String outString;
protected
  list<Import> qual_imps, unqual_imps;
  String qual_str, unqual_str;
algorithm
  IMPORT_TABLE(qualifiedImports = qual_imps, unqualifiedImports = unqual_imps) 
    := inImports;
  qual_str := Util.stringDelimitList(
    Util.listMap(qual_imps, Absyn.printImportString), "\n\t\t");
  unqual_str := Util.stringDelimitList(
    Util.listMap(unqual_imps, Absyn.printImportString), "\n\t\t");
  outString := "\t\t" +& qual_str +& unqual_str;
end printImportTableStr;

protected function avlTreeAdd
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
      Absyn.Info info;

    // Don't allow replacing of nodes.
    case (_, 0, key, _)
      equation
        info = getItemInfo(inValue);
        Error.addSourceMessage(Error.DOUBLE_DECLARATION_OF_ELEMENTS,
          {inKey}, info);
      then
        fail();

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

protected function avlTreeReplace
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
        Error.addMessage(Error.INTERNAL_ERROR, {"Env.avlTreeAdd failed"});
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
      AvlKey key, rkey;
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
    /* d < -1 or d > 1 */
    else then doBalance2(difference, bt);
  end match;
end doBalance;

protected function doBalance2 
"help function to doBalance"
  input Integer difference;
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(difference,bt)
    case(difference,bt) 
      equation
        true = difference < 0;
        bt = doBalance3(bt);
        bt = rotateLeft(bt);
      then bt;
    case(difference,bt) 
      equation
        true = difference > 0;
        bt = doBalance4(bt);
        bt = rotateRight(bt);
      then bt;
    else then bt;
  end matchcontinue;
end doBalance2;

protected function doBalance3 
  "help function to doBalance2"
  input AvlTree bt;
  output AvlTree outBt;
protected
  AvlTree rr;
algorithm
  true := differenceInHeight(Util.getOption(rightNode(bt))) > 0;
  rr := rotateRight(Util.getOption(rightNode(bt)));
  outBt := setRight(bt,SOME(rr));
end doBalance3;

protected function doBalance4 
  "help function to doBalance2"
  input AvlTree bt;
  output AvlTree outBt;
protected
  AvlTree rl;
algorithm
  true := differenceInHeight(Util.getOption(leftNode(bt))) < 0;
  rl := rotateLeft(Util.getOption(leftNode(bt)));
  outBt := setLeft(bt,SOME(rl));
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
  "compute the heigth of the AvlTree and store in the node info"
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

end SCodeEnv;
