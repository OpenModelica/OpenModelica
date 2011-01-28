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

protected import Debug;
protected import Error;
protected import RTOpts;
protected import SCodeLookup;
protected import SCodeUtil;
protected import Util;


public type Import = Absyn.Import;

public uniontype ImportTable
  record IMPORT_TABLE
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
    list<SCode.Class> classExtends;
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
  end FRAME;
end Frame;

public uniontype Item
  record VAR
    SCode.Element var;
  end VAR;

  record CLASS
    SCode.Class cls;
    Env env;
  end CLASS;

  record BUILTIN
    String name;
  end BUILTIN;
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
  outElement := matchcontinue(inElement, inEnv)
    local
      SCode.Ident name, name2;
      Absyn.Ident id;
      Boolean fp, rp, pp, ep;
      Option<Absyn.ConstrainClass> cc;
      Option<Absyn.ArrayDim> ad;
      Absyn.Path path;
      SCode.Mod mods;
      Absyn.ElementAttributes eattr;
      Option<SCode.Comment> cmt;
      Env env;
      SCode.Restriction res;
      Absyn.Info info;
      Absyn.InnerOuter io;
      SCode.Attributes attr;
      Option<Absyn.Exp> cond;
      Option<Absyn.ArrayDim> array_dim;

    case (SCode.CLASSDEF(
          name = name, 
          finalPrefix = fp, 
          replaceablePrefix = rp,
          classDef = SCode.CLASS(
            name = name2,
            partialPrefix = pp,
            encapsulatedPrefix = ep,
            restriction = res,
            classDef = SCode.DERIVED(
              typeSpec = Absyn.TPATH(path, ad),
              modifications = mods, 
              attributes = eattr, 
              comment = cmt),
            info = info),
          cc = cc), _)
      equation
        path = qualifyPath(path, inEnv, info);
      then
        SCode.CLASSDEF(name, fp, rp, 
          SCode.CLASS(name2, pp, ep, res,
            SCode.DERIVED(Absyn.TPATH(path, ad), mods, eattr, cmt),
            info), cc);

    case (SCode.COMPONENT(name, io, fp, rp, pp, attr, 
        Absyn.TPATH(path, array_dim), mods, cmt, cond, info, cc), _)
      equation
        path = qualifyPath(path, inEnv, info);
      then
        SCode.COMPONENT(name, io, fp, rp, pp, attr, 
          Absyn.TPATH(path, array_dim), mods, cmt, cond, info, cc);

    else
      equation
        true = RTOpts.debugFlag("failtrace");
        print("- SCodeFlatten.qualifyRedeclare failed on " +&
          SCode.printElementStr(inElement) +& " in " +&
          Absyn.pathString(getEnvPath(inEnv)) +& "\n");
      then
        fail();
  end matchcontinue;
end qualifyRedeclare;

protected function qualifyPath
  input Absyn.Path inPath;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Absyn.Path outPath;
protected
  Absyn.Path path;
  Env env;
algorithm
  (_, path, SOME(env)) := SCodeLookup.lookupClassName(inPath, inEnv, inInfo);
  outPath := mergePathWithEnvPath(path, env);
end qualifyPath;

protected function mergePathWithEnvPath
  input Absyn.Path inPath;
  input Env inEnv;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inPath, inEnv)
    local
      Absyn.Path path;
      Absyn.Ident id;

    case (_, _)
      equation
        id = Absyn.pathLastIdent(inPath);
        path = Absyn.joinPaths(getEnvPath(inEnv), Absyn.IDENT(id));
      then
        path;

    else then inPath;
  end matchcontinue;
end mergePathWithEnvPath;

public function joinPaths
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  output Absyn.Path outPath;
algorithm
  outPath := match(inPath1, inPath2)
    local
      Absyn.Ident id;
      Absyn.Path path;

    case (_, Absyn.FULLYQUALIFIED(path = _)) then inPath2;
    case (Absyn.IDENT(name = id), _) then Absyn.QUALIFIED(id, inPath2);
    case (Absyn.QUALIFIED(name = id, path = path), _)
      equation
        path = joinPaths(path, inPath2);
      then
        Absyn.QUALIFIED(id, path);

    case (Absyn.FULLYQUALIFIED(path = path), _)
      equation
        path = joinPaths(path, inPath2);
      then
        Absyn.FULLYQUALIFIED(path);
  end match;
end joinPaths;

public function newEnvironment
  input Option<SCode.Ident> inName;
  output Env outEnv;
protected
  Frame new_frame;
algorithm
  new_frame := newFrame(inName, NORMAL_SCOPE());
  outEnv := {new_frame};
end newEnvironment;

protected function openScope
  input Env inEnv;
  input SCode.Class inClass;
  output Env outEnv;
protected
  String name;
  Boolean encapsulated_prefix;
  Frame new_frame;
algorithm
  SCode.CLASS(name = name, encapsulatedPrefix = encapsulated_prefix) := inClass;
  new_frame := newFrame(SOME(name), getFrameType(encapsulated_prefix));
  outEnv := new_frame :: inEnv;
end openScope;

public function enterScope
  input Env inEnv;
  input SCode.Ident inName;
  output Env outEnv;
protected
  Frame cls_env;
  AvlTree cls_and_vars;
algorithm
  FRAME(clsAndVars = cls_and_vars) :: _ := inEnv;
  CLASS(env = {cls_env}) := avlTreeGet(cls_and_vars, inName);
  outEnv := cls_env :: inEnv;
end enterScope;

public function getEnvTopScope
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
  input Boolean isEncapsulated;
  output FrameType outType;
algorithm
  outType := match(isEncapsulated)
    case true then ENCAPSULATED_SCOPE();
    else then NORMAL_SCOPE();
  end match;
end getFrameType;

protected function newFrame
  input Option<String> inName;
  input FrameType inType;
  output Frame outFrame;
protected
  AvlTree tree;
  ExtendsTable exts;
  ImportTable imps;
algorithm
  tree := avlTreeNew();
  exts := newExtendsTable();
  imps := newImportTable();
  outFrame := FRAME(inName, inType, tree, exts, imps);
end newFrame;

protected function newImportTable
  output ImportTable outImports;
algorithm
  outImports := IMPORT_TABLE({}, {});
end newImportTable;

protected function newExtendsTable
  output ExtendsTable outExtends;
algorithm
  outExtends := EXTENDS_TABLE({}, {});
end newExtendsTable;

public function extendEnvWithClasses
  input list<SCode.Class> inClasses;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := Util.listFold(inClasses, extendEnvWithClass, inEnv);
end extendEnvWithClasses;

protected function extendEnvWithClass
  input SCode.Class inClass;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inClass, inEnv)
    local
      String cls_name;
      Env class_env, env;
      SCode.ClassDef cdef;
      Absyn.Path cls_path;

    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = _)), _)
      then addClassExtendsToEnvExtendsTable(inClass, inEnv);

    case (SCode.CLASS(name = cls_name, classDef = cdef), _)
      equation
        class_env = newEnvironment(SOME(cls_name));
        class_env = extendEnvWithClassComponents(cls_name, cdef, class_env);
        env = extendEnvWithItem(CLASS(inClass, class_env), inEnv, cls_name);
      then
        env;
  end match;
end extendEnvWithClass;

public function removeExtendsFromLocalScope
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  ExtendsTable exts;
  Env rest;
algorithm
  FRAME(name = name, frameType = ty, clsAndVars = tree, importTable = imps) 
    :: rest := inEnv;
  exts := newExtendsTable();
  outEnv := FRAME(name, ty, tree, exts, imps) :: rest;
end removeExtendsFromLocalScope;
  
protected function extendEnvWithClassDef
  input SCode.Element inClassDefElement;
  input Env inEnv;
  output Env outEnv;
protected
  SCode.Class cls;
algorithm
  SCode.CLASSDEF(classDef = cls) := inClassDefElement;
  outEnv := extendEnvWithClass(cls, inEnv);
end extendEnvWithClassDef;

protected function extendEnvWithVar
  input SCode.Element inVar;
  input Env inEnv;
  output Env outEnv;
protected
  String var_name;
algorithm
  SCode.COMPONENT(component = var_name) := inVar; 
  outEnv := extendEnvWithItem(VAR(inVar), inEnv, var_name);
end extendEnvWithVar;

protected function extendEnvWithItem
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
algorithm
  FRAME(name, ty, tree, exts, imps) :: rest := inEnv;
  tree := avlTreeAdd(tree, inItemName, inItem);
  outEnv := FRAME(name, ty, tree, exts, imps) :: rest;
end extendEnvWithItem;

protected function extendEnvWithImport
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

    // Unqualified imports
    case (SCode.IMPORT(imp = imp as Absyn.UNQUAL_IMPORT(path = _)), 
        FRAME(name, ty, tree, exts, IMPORT_TABLE(qual_imps, unqual_imps)) :: rest)
      equation
        unqual_imps = imp :: unqual_imps;
      then
        FRAME(name, ty, tree, exts, IMPORT_TABLE(qual_imps, unqual_imps)) :: rest;

    // Qualified imports
    case (SCode.IMPORT(imp = imp, info = info), 
        FRAME(name, ty, tree, exts, IMPORT_TABLE(qual_imps, unqual_imps)) :: rest)
      equation
        imp = translateQualifiedImportToNamed(imp);
        checkUniqueQualifiedImport(imp, qual_imps, info);
        qual_imps = imp :: qual_imps;
      then
        FRAME(name, ty, tree, exts, IMPORT_TABLE(qual_imps, unqual_imps)) :: rest;
  end match;
end extendEnvWithImport;

protected function translateQualifiedImportToNamed
  input Import inImport;
  output Import outImport;
algorithm
  outImport := match(inImport)
    local
      Absyn.Ident name;
      Absyn.Path path;

    case Absyn.NAMED_IMPORT(name = _) then inImport;

    case Absyn.QUAL_IMPORT(path = path)
      equation
        name = Absyn.pathLastIdent(path);
      then
        Absyn.NAMED_IMPORT(name, path);
  end match;
end translateQualifiedImportToNamed;

protected function extendEnvWithExtends
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
      SCode.Class cls;
      Env env;
      Frame item_env;

    case (_, VAR(var = _), _, _) then (inItem, inTypeEnv);
    case (_, BUILTIN(name = _), _, _) then (inItem, inTypeEnv);

    case (_, CLASS(cls = cls, env = {item_env}), _, _)
      equation
        redeclares = Util.listMap1(inRedeclares, qualifyRedeclare, inVarEnv);
        // Merge the types environment with it's enclosing scopes to get the
        // enclosing scopes of the classes we need to replace.
        env = item_env :: inTypeEnv;
        env = Util.listFold(redeclares, replaceRedeclaredElementInEnv, env);
        item_env :: env = env;
      then
        (CLASS(cls, {item_env}), env);

    else
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- SCodeFlatten.replaceRedeclaredClassesInEnv failed!");
      then
        fail();
  end matchcontinue;
end replaceRedeclaredClassesInEnv;

public function extractRedeclaresFromModifier
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
  input SCode.SubMod inMod;
  input list<SCode.Element> inRedeclares;
  output list<SCode.Element> outRedeclares;
algorithm
  outRedeclares := match(inMod, inRedeclares)
    local
      SCode.Element redecl;

    case (SCode.NAMEMOD(A = SCode.REDECL(elementLst = 
        {redecl as SCode.CLASSDEF(name = _)})), _)
      then redecl :: inRedeclares;

    case (SCode.NAMEMOD(A = SCode.REDECL(elementLst =
        {redecl as SCode.COMPONENT(component = _)})), _)
      then redecl :: inRedeclares;

    else then inRedeclares;
  end match;
end extractRedeclareFromSubMod;

protected function addExtendsToEnvExtendsTable
  input Extends inExtends;
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  list<Extends> exts;
  list<SCode.Class> ce;
  Env rest_env;
algorithm
  FRAME(name, ty, tree, EXTENDS_TABLE(exts, ce), imps) :: rest_env := inEnv;
  exts := inExtends :: exts;
  outEnv := FRAME(name, ty, tree, EXTENDS_TABLE(exts, ce), imps) :: rest_env;
end addExtendsToEnvExtendsTable;

protected function addClassExtendsToEnvExtendsTable
  input SCode.Class inClassExtends;
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  list<Extends> exts;
  list<SCode.Class> ce;
  Env rest_env;
algorithm
  FRAME(name, ty, tree, EXTENDS_TABLE(exts, ce), imps) :: rest_env := inEnv;
  ce := inClassExtends :: ce;
  outEnv := FRAME(name, ty, tree, EXTENDS_TABLE(exts, ce), imps) :: rest_env;
end addClassExtendsToEnvExtendsTable;

protected function extendEnvWithClassComponents
  input String inClassName;
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inClassName, inClassDef, inEnv)
    local
      list<SCode.Element> el;
      list<SCode.Enum> enums;
      Absyn.TypeSpec enum_type;
      Env env;
      Absyn.Path path;

    case (_, SCode.PARTS(elementLst = el), _)
      equation
        env = Util.listFold(el, extendEnvWithElement, inEnv);
      then
        env;

    case (_, SCode.DERIVED(typeSpec = Absyn.TPATH(path = path)), _)
      equation
        env = extendEnvWithExtends(SCode.EXTENDS(path, SCode.NOMOD(), NONE(),
          Absyn.dummyInfo), inEnv);
      then
        env;

    case (_, SCode.ENUMERATION(enumLst = enums), _)
      equation
        enum_type = Absyn.TPATH(Absyn.IDENT(inClassName), NONE());
        env = Util.listFold1(enums, extendEnvWithEnum, enum_type, inEnv);
      then
        env;

    else then inEnv;
  end match;
end extendEnvWithClassComponents;

protected function extendEnvWithElement
  input SCode.Element inElement;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inElement, inEnv)
    local
      Env env;

    case (SCode.COMPONENT(component = _), _)
      equation
        env = extendEnvWithVar(inElement, inEnv);
      then
        env;

    case (SCode.CLASSDEF(classDef = _), _)
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

  end match;
end extendEnvWithElement;

protected function checkUniqueQualifiedImport
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
  input SCode.Enum inEnum;
  input Absyn.TypeSpec inEnumType;
  input Env inEnv;
  output Env outEnv;
protected
  SCode.Element enum_lit;
  SCode.Ident lit_name;
algorithm
  SCode.ENUM(literal = lit_name) := inEnum;
  enum_lit := SCode.COMPONENT(lit_name, Absyn.UNSPECIFIED(), 
    false, false, false, 
    SCode.ATTR({}, false, false, SCode.RO(), SCode.CONST(), Absyn.BIDIR()),
    inEnumType, SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo, NONE());
  outEnv := extendEnvWithElement(enum_lit, inEnv);
end extendEnvWithEnum;

public function extendEnvWithIterators
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
  input tuple<Absyn.Ident, Option<Absyn.Exp>> inIterator;
  input Env inEnv;
  output Env outEnv;
protected
  Absyn.Ident iter_name;
  SCode.Element iter;
algorithm
  (iter_name, _) := inIterator;
  iter := SCode.COMPONENT(iter_name, Absyn.UNSPECIFIED(),
    false, false, false,
    SCode.ATTR({}, false, false, SCode.RO(), SCode.CONST(), Absyn.BIDIR()),
    Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
    NONE(), NONE(), Absyn.dummyInfo, NONE());
  outEnv := extendEnvWithElement(iter, inEnv);
end extendEnvWithIterator;

public function extendEnvWithMatch
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
        el = SCodeUtil.translateElement(element, true);
        env = Util.listFold(el, extendEnvWithElement, inEnv);
      then 
        env;

    else then inEnv;
  end match;
end extendEnvWithElementItem;

public function insertClassExtendsIntoEnv
  input Env inEnv;
  output Env outEnv;
protected
  Env env, rest_env;
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  list<Extends> bcl;
  list<SCode.Class> ce;
  ImportTable imps;
algorithm
  FRAME(extendsTable = EXTENDS_TABLE(classExtends = ce)) :: _ := inEnv;
  env := Util.listFold(ce, extendEnvWithClassExtends, inEnv);
  FRAME(name, ty, tree, EXTENDS_TABLE(bcl, _), imps) :: rest_env := env;
  SOME(tree) := insertClassExtendsIntoClassEnv(SOME(tree), inEnv);
  outEnv := FRAME(name, ty, tree, EXTENDS_TABLE(bcl, {}), imps) :: rest_env;
end insertClassExtendsIntoEnv;

protected function insertClassExtendsIntoClassEnv
  input Option<AvlTree> inTree;
  input Env inEnv;
  output Option<AvlTree> outTree;
algorithm
  outTree := match(inTree, inEnv)
    local
      String name;
      Integer h;
      Option<AvlTree> left, right;
      Env rest_env;
      SCode.Class cls;
      Frame class_frame;
      Option<AvlTreeValue> value;

    case (NONE(), _) then inTree;

    case (SOME(AVLTREENODE(value = SOME(AVLTREEVALUE(
          key = name, value = CLASS(cls = cls, env = {class_frame}))),
        height = h, left = left, right = right)), _)
      equation
        class_frame :: rest_env = insertClassExtendsIntoEnv(class_frame :: inEnv);
        left = insertClassExtendsIntoClassEnv(left, inEnv);
        right = insertClassExtendsIntoClassEnv(right, inEnv);
      then
        SOME(AVLTREENODE(SOME(AVLTREEVALUE(name, CLASS(cls, {class_frame}))), h,
          left, right)); 

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
  input SCode.Element inRedeclare;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inRedeclare, inEnv)
    local
      SCode.Ident name;
      SCode.Class cls;
      Env env;
      Absyn.Path path;
      Option<Env> opt_env;
      Absyn.Info info;

    case (SCode.CLASSDEF(name = name, classDef = 
        cls as SCode.CLASS(info = info)), _)
      equation
        (_, path, SOME(env)) = 
          SCodeLookup.lookupClassName(Absyn.IDENT(name), inEnv, info);
        path = joinPaths(getEnvPath(env), path);
        env = replaceElementInEnv(path, inRedeclare, inEnv);
      then
        env;

    case (SCode.COMPONENT(component = name, info = info), _)
      equation
        (_, path, SOME(env)) = 
          SCodeLookup.lookupVariableName(Absyn.IDENT(name), inEnv, info);
        path = joinPaths(getEnvPath(env), path);
        env = replaceElementInEnv(path, inRedeclare, inEnv);
      then
        env;

    else then inEnv;
  end match;
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
protected
algorithm
  outEnv := match(inElementName, inElement, inEnv)
    local
      Option<String> name;
      FrameType ty;
      AvlTree tree;
      ExtendsTable exts;
      ImportTable imps;
      Env env, class_env;
      SCode.ClassDef cdef;
      SCode.Class cls;

    case (_, SCode.CLASSDEF(classDef = cls as SCode.CLASS(classDef = cdef)), 
        FRAME(name, ty, tree, exts, imps) :: env)
      equation
        class_env = newEnvironment(SOME(inElementName));
        class_env = extendEnvWithClassComponents(inElementName, cdef, class_env);
        tree = avlTreeReplace(tree, inElementName, CLASS(cls, class_env));
      then
        FRAME(name, ty, tree, exts, imps) :: env;

    case (_, SCode.COMPONENT(component = _),
        FRAME(name, ty, tree, exts, imps) :: env)
      equation
        tree = avlTreeReplace(tree, inElementName, VAR(inElement));
      then
        FRAME(name, ty, tree, exts, imps) :: env;

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
      SCode.Class cls;

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
        FRAME(frame_name, ty, tree, exts, imps) :: rest_env)
      equation
        CLASS(cls = cls, env = class_env) = avlTreeGet(tree, name);
        class_env = replaceElementInClassEnv(path, inElement, class_env);
        tree = avlTreeReplace(tree, name, CLASS(cls, class_env)); 
      then
        FRAME(frame_name, ty, tree, exts, imps) :: rest_env;

  end match;
end replaceElementInClassEnv;

protected function extendEnvWithClassExtends
  input SCode.Class inClassExtends;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inClassExtends, inEnv)
    local
      SCode.Ident bc;
      list<SCode.Element> el;
      Absyn.Path path;
      Boolean pp, ep;
      SCode.Restriction res;
      Absyn.Info info;
      Env env;
      SCode.Mod mods;

    // When a 'redeclare class extends X' is encountered we insert a 'class X
    // extends BaseClass.X' into the environment, with the same elements as the
    // class extends clause. BaseClass is the class that class X is inherited
    // from. This allows use to look up elements in class extends, because
    // lookup can handle normal extends.
    case (SCode.CLASS(
        partialPrefix = pp,
        encapsulatedPrefix = ep,
        restriction = res,
        classDef = SCode.CLASS_EXTENDS(
          baseClassName = bc, 
          modifications = mods,
          elementLst = el),
        info = info), _)
      equation
        // Look up which extends the base class comes from and add it to the
        // base class name.
        path = SCodeLookup.lookupBaseClass(bc, inEnv, info);
        path = Absyn.joinPaths(path, Absyn.IDENT(bc));
        // Insert a 'class bc extends path' into the environment.
        el = SCode.EXTENDS(path, mods, NONE(), info) :: el;
        env = extendEnvWithClass(SCode.CLASS(bc, pp, ep, res, 
          SCode.PARTS(el, {}, {}, {}, {}, NONE(), {}, NONE()), info), inEnv);
      then env;

    else then inEnv;
  end match;
end extendEnvWithClassExtends;

public function getEnvName
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
  input Env inEnv;
  output Absyn.Path outPath;
algorithm
  outPath := match(inEnv)
    local
      String name;
      Absyn.Path path;
      Env rest;

    case (FRAME(frameType = IMPLICIT_SCOPE) :: rest)
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

public function buildInitialEnv
  output Env outInitialEnv;
public
  AvlTree tree;
  ExtendsTable exts;
  ImportTable imps;
algorithm
  tree := avlTreeNew();
  exts := newExtendsTable();
  imps := newImportTable();

  tree := avlTreeAdd(tree, "time", VAR(
    SCode.COMPONENT("time", Absyn.UNSPECIFIED(), false, false, false,
    SCode.ATTR({}, false, false, SCode.RO(), SCode.VAR(), Absyn.INPUT()),
    Absyn.TPATH(Absyn.IDENT("Real"), NONE()), SCode.NOMOD(),
    NONE(), NONE(), Absyn.dummyInfo, NONE())));

  tree := avlTreeAdd(tree, "String", CLASS(
    SCode.CLASS("String", false, false, SCode.R_FUNCTION(),
      SCode.PARTS({}, {}, {}, {}, {}, NONE(), {}, NONE()), Absyn.dummyInfo),
    emptyEnv));

  tree := avlTreeAdd(tree, "Integer", CLASS(
    SCode.CLASS("Integer", false, false, SCode.R_FUNCTION(),
      SCode.PARTS({}, {}, {}, {}, {}, NONE(), {}, NONE()), Absyn.dummyInfo),
    emptyEnv));

  // Modelica.Fluid.Pipes.BaseClasses.HeatTransfer.LocalPipeFlowHeatTransfer
  // tries to call a function called spliceFunction. This seems to be a built-in
  // Dymola function, so until this has been fixed we'll just pretend that we
  // also have it.
  tree := avlTreeAdd(tree, "spliceFunction", CLASS(
    SCode.CLASS("spliceFunction", false, false, SCode.R_FUNCTION(),
      SCode.PARTS({}, {}, {}, {}, {}, NONE(), {}, NONE()), Absyn.dummyInfo),
    emptyEnv));

  outInitialEnv := {FRAME(NONE(), NORMAL_SCOPE(), tree, exts, imps)};
end buildInitialEnv;

// AVL Tree implementation
public type AvlKey = String;
public type AvlValue = Item;

public uniontype AvlTree 
  "The binary tree data structure"
  record AVLTREENODE
    Option<AvlTreeValue> value "Value";
    Integer height "heigth of tree, used for balancing";
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
  FRAME(name, ty, tree, exts, imps) := inFrame;
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
    case NORMAL_SCOPE then "Normal";
    case ENCAPSULATED_SCOPE then "Encapsulated";
    case IMPLICIT_SCOPE then "Implicit";
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

protected function printAvlValueStr
  input AvlTreeValue inValue;
  output String outString;
algorithm
  outString := match(inValue)
    local
      String key_str, value_str;

    case (AVLTREEVALUE(key = key_str, value = CLASS(cls = _)))
      then "\t\tClass " +& key_str +& "\n";

    case (AVLTREEVALUE(key = key_str, value = VAR(var = _)))
      then "\t\tVar " +& key_str +& "\n";

    case (AVLTREEVALUE(key = key_str, value = BUILTIN(name = _)))
      then "\t\tBuiltin " +& key_str +& "\n";
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
  IMPORT_TABLE(qual_imps, unqual_imps) := inImports;
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

protected function getItemInfo
  input Item inItem;
  output Absyn.Info outInfo;
algorithm
  outInfo := match(inItem)
    local
      Absyn.Info info;

    case (VAR(var = SCode.COMPONENT(info = info))) then info;
    case (CLASS(cls = SCode.CLASS(info = info))) then info;
    case (BUILTIN(name = _)) then Absyn.dummyInfo;
  end match;
end getItemInfo;

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
