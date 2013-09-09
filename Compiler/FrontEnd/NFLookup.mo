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

encapsulated package NFLookup
" file:        NFEnv.mo
  package:     NFEnv
  description: Lookup functions for NFEnv

  RCS: $Id$

"

public import Absyn;
public import Error;
public import NFEnv;
public import NFInstTypes;
public import NFMod;
public import SCode;

protected import List;
protected import NFBuiltin;
protected import NFRedeclare;

public type Env = NFEnv.Env;
public type Entry = NFEnv.Entry;
public type EntryOrigin = NFEnv.EntryOrigin;
public type Modifier = NFInstTypes.Modifier;
public type ModTable = NFMod.ModTable;

protected constant Entry REAL_TYPE_ENTRY = NFEnv.ENTRY(
    "Real", NFBuiltin.BUILTIN_REAL, 0, {NFEnv.BUILTIN_ORIGIN()});
protected constant Entry INT_TYPE_ENTRY = NFEnv.ENTRY(
    "Integer", NFBuiltin.BUILTIN_INTEGER, 0, {NFEnv.BUILTIN_ORIGIN()});
protected constant Entry BOOL_TYPE_ENTRY = NFEnv.ENTRY(
    "Boolean", NFBuiltin.BUILTIN_BOOLEAN, 0, {NFEnv.BUILTIN_ORIGIN()});
protected constant Entry STRING_TYPE_ENTRY = NFEnv.ENTRY(
    "String", NFBuiltin.BUILTIN_BOOLEAN, 0, {NFEnv.BUILTIN_ORIGIN()});

public function lookupNameSilent
  "Looks up a name, but doesn't print an error message if it fails."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv) := lookupName(inName, inEnv, inInfo, NONE());
end lookupNameSilent;

public function lookupClassName
  "Calls lookupName with the 'Class not found' error message."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv) := matchcontinue(inName, inEnv, inInfo)
    local
      Entry entry;
      Env env;
      String name;

    case (Absyn.IDENT(name = name), _, _)
      equation
        (entry, env) = lookupBuiltinType(name, inEnv);
      then
        (entry, env);

    else
      equation
        (entry, env) = lookupName(inName, inEnv, inInfo, SOME(Error.LOOKUP_ERROR));
        checkEntryIsClass(entry, inInfo);
      then
        (entry, env);

  end matchcontinue;
end lookupClassName;

protected function checkEntryIsClass
  input Entry inEntry;
  input Absyn.Info inInfo;
algorithm
  _ := match(inEntry, inInfo)
    local
      String name;
      Absyn.Info info;

    case (NFEnv.ENTRY(element = SCode.CLASS(name = _)), _) then ();

    case (NFEnv.ENTRY(element = SCode.COMPONENT(name = name, info = info)), _)
      equation
        Error.addMultiSourceMessage(Error.LOOKUP_TYPE_FOUND_COMP,
          {name}, {info, inInfo});
      then
        fail();

  end match;
end checkEntryIsClass;

public function lookupBaseClassName
  "Calls lookupName with the 'Baseclass not found' error message."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv) := match(inName, inEnv, inInfo)
    local
      Env env;
      Entry entry;

    // Normal baseclass.
    case (_, _, _)
      equation
        (entry, env) = lookupName(inName, inEnv, inInfo,
          SOME(Error.LOOKUP_BASECLASS_ERROR));
      then
        (entry, env);

  end match;
end lookupBaseClassName;

public function lookupVariableName
  "Calls lookupName with the 'Variable not found' error message."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv) := lookupName(inName, inEnv, inInfo,
    SOME(Error.LOOKUP_VARIABLE_ERROR));
end lookupVariableName;

protected function checkEntryIsVar
  input Entry inEntry;
  input Absyn.Info inInfo;
algorithm
  _ := match(inEntry, inInfo)
    local
      String name;
      Absyn.Info info;

    case (NFEnv.ENTRY(element = SCode.COMPONENT(name = _)), _) then ();

    case (NFEnv.ENTRY(element = SCode.CLASS(name = name, info = info)), _)
      equation
        Error.addMultiSourceMessage(Error.LOOKUP_COMP_FOUND_TYPE,
          {name}, {info, inInfo});
      then
        fail();

  end match;
end checkEntryIsVar;

public function lookupFunctionName
  "Calls lookupName with the 'Function not found' error message."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv) := lookupName(inName, inEnv, inInfo,
    SOME(Error.LOOKUP_FUNCTION_ERROR));
end lookupFunctionName;

public function lookupImportPath
  input Absyn.Path inPath;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv) := matchcontinue(inPath, inEnv, inInfo)
    local
      Entry entry;
      Env env;
      String path_str, env_str;

    case (_, _, _)
      equation
        (entry, env) = lookupFullyQualified(inPath, inEnv);
      then
        (entry, env);

    else
      equation
        path_str = Absyn.pathString(inPath);
        env_str = NFEnv.printEnvPathStr(inEnv);
        Error.addSourceMessage(Error.LOOKUP_IMPORT_ERROR,
          {path_str, env_str}, inInfo);
      then
        fail();

  end matchcontinue;
end lookupImportPath;

public function lookupTypeSpec
  "Looks up a type specification and returns the environment entry and enclosing
   scopes of the type."
  input Absyn.TypeSpec inTypeSpec;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv) := match(inTypeSpec, inEnv, inInfo)
    local
      Absyn.Path path;
      Absyn.Ident name;
      Entry entry;
      Env env;
      SCode.Element cls;

    // A normal type.
    case (Absyn.TPATH(path = path), _, _)
      equation
        (entry, env) = lookupClassName(path, inEnv, inInfo);
      then
        (entry, env);

    // A MetaModelica type such as list or tuple.
    case (Absyn.TCOMPLEX(path = Absyn.IDENT(name = name)), _, _)
      equation
        cls = makeDummyMetaType(name);
        entry = NFEnv.makeEntry(cls, NFEnv.emptyEnv);
      then
        (entry, NFEnv.emptyEnv);

  end match;
end lookupTypeSpec;

protected function makeDummyMetaType
  input String inTypeName;
  output SCode.Element outClass;
algorithm
  outClass :=
  SCode.CLASS(
    inTypeName,
    SCode.defaultPrefixes,
    SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()), SCode.noComment, Absyn.dummyInfo);
end makeDummyMetaType;

protected function lookupUnresolvedSimpleName
  "Looks up a name and returns the unresolved entry from the environment."
  input String inName;
  input Env inEnv;
  output Entry outEntry;
algorithm
  outEntry := matchcontinue(inName, inEnv)
    local
      Entry entry;
      Env env;

    case (_, _)
      equation
        entry = NFEnv.lookupEntry(inName, inEnv);
      then
        entry;

    else
      equation
        true = NFEnv.isScopeEncapsulated(inEnv);
        env = NFEnv.builtinScope(inEnv);
        entry = lookupUnresolvedSimpleName(inName, env);
      then
        entry;

  end matchcontinue;
end lookupUnresolvedSimpleName;

protected function lookupBuiltinType
  input String inName;
  input Env inEnv;
  output Entry outEntry;
  output Env outEnv;
algorithm
  outEntry := lookupBuiltinType2(inName);
  outEnv := NFEnv.builtinScope(inEnv);
end lookupBuiltinType;

protected function lookupBuiltinType2
  input String inName;
  output Entry outEntry;
algorithm
  outEntry := match(inName)
    case "Real" then REAL_TYPE_ENTRY;
    case "Integer" then INT_TYPE_ENTRY;
    case "Boolean" then BOOL_TYPE_ENTRY;
    case "String" then STRING_TYPE_ENTRY;
  end match;
end lookupBuiltinType2;

protected function lookupName
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  input Option<Error.Message> inErrorType;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv) := matchcontinue(inName, inEnv, inInfo, inErrorType)
    local
      String name;
      Absyn.Path path;
      Entry entry;
      Env env;
      Error.Message error_id;
      String name_str, env_str;

    case (Absyn.IDENT(name = name), _, _, _)
      equation
        (entry, env) = lookupSimpleName(name, inEnv);
      then
        (entry, env);

    case (Absyn.QUALIFIED(name = name, path = path), _, _, _)
      equation
        (entry, env) = lookupSimpleName(name, inEnv);
        (entry, env) = lookupNameInEntry(path, entry, env);
      then
        (entry, env);

    case (Absyn.FULLYQUALIFIED(path = path), _, _, _)
      equation
        (entry, env) = lookupFullyQualified(path, inEnv);
      then
        (entry, env);

    case (_, _, _, SOME(error_id))
      equation
        name_str = Absyn.pathString(inName);
        env_str = NFEnv.printEnvPathStr(inEnv);
        Error.addSourceMessage(error_id, {name_str, env_str}, inInfo);
      then
        fail();

  end matchcontinue;
end lookupName;

protected function lookupSimpleName
  input String inName;
  input Env inEnv;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv) := matchcontinue(inName, inEnv)
    local
      Entry entry;
      Env env;

    case (_, _)
      equation
        entry = NFEnv.lookupEntry(inName, inEnv);
        (entry, env) = NFEnv.resolveEntry(entry, inEnv);
        env = NFEnv.entryEnv(entry, env);
      then
        (entry, env);

    else
      equation
        true = NFEnv.isScopeEncapsulated(inEnv);
        env = NFEnv.builtinScope(inEnv);
        (entry, env) = lookupSimpleName(inName, inEnv);
      then
        (entry, env);

  end matchcontinue;
end lookupSimpleName;

protected function lookupFullyQualified
  input Absyn.Path inName;
  input Env inEnv;
  output Entry outEntry;
  output Env outEnv;
protected
  Env env;
algorithm
  env := NFEnv.topScope(inEnv);
  (outEntry, outEnv) := lookupNameInPackage(inName, inEnv);
end lookupFullyQualified;

public function lookupInLocalScope
  input String inName;
  input Env inEnv;
  output Entry outEntry;
  output Env outEnv;
protected
  Env env;
  Entry entry;
algorithm
  entry := NFEnv.lookupEntry(inName, inEnv);
  true := NFEnv.isLocalScopeEntry(entry, inEnv);
  (outEntry, env) := NFEnv.resolveEntry(entry, inEnv);
  outEnv := NFEnv.entryEnv(outEntry, env);
end lookupInLocalScope;

public function lookupNameInPackage
  input Absyn.Path inName;
  input Env inEnv;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv) := match(inName, inEnv)
    local
      String name;
      Absyn.Path path;
      Entry entry;
      Env env;

    case (Absyn.IDENT(name = name), _)
      equation
        (entry, env) = lookupInLocalScope(name, inEnv);
      then
        (entry, env);

    case (Absyn.QUALIFIED(name = name, path = path), _)
      equation
        (entry, env) = lookupInLocalScope(name, inEnv);
        (entry, env) = lookupNameInEntry(path, entry, env);
      then
        (entry, env);

  end match;
end lookupNameInPackage;

protected function lookupNameInEntry
  input Absyn.Path inName;
  input Entry inEntry;
  input Env inEnv;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv) := match(inName, inEntry, inEnv)
    local
      Entry entry;
      Env env;

    case (_, _, _)
      equation
        env = enterEntryScope(inEntry, NFMod.emptyModTable, inEnv);
        (entry, env) = lookupNameInPackage(inName, env);
      then
        (entry, env);

  end match;
end lookupNameInEntry;

public function isNameGlobal
  "Returns whether a simple name is global or not, as well as it's entry and
   environment. Global in this case means a non-local class."
  input String inName;
  input Env inEnv;
  output Boolean outIsGlobal;
  output Entry outEntry;
  output Env outEnv;
protected
  Boolean is_local, is_class;
algorithm
  // Look up the name unresolved and check if it's a local name.
  outEntry := lookupUnresolvedSimpleName(inName, inEnv);
  is_local := NFEnv.isLocalScopeEntry(outEntry, inEnv);
  // Then resolve the entry and check if it refers to a class.
  (outEntry, outEnv) := NFEnv.resolveEntry(outEntry, inEnv);
  is_class := NFEnv.isClassEntry(outEntry);
  outEnv := NFEnv.entryEnv(outEntry, outEnv);
  outIsGlobal := not is_local and is_class;
end isNameGlobal;

public function enterEntryScope
  input Entry inEntry;
  input ModTable inMods;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inEntry, inMods, inEnv)
    local
      Env env;
      SCode.ClassDef cdef;
      Absyn.Info info;
      Absyn.TypeSpec ty;
      Entry entry;

    case (NFEnv.ENTRY(element = SCode.CLASS(classDef = cdef, info = info)), _, _)
      equation
        env = openClassEntryScope(inEntry, inEnv);
        env = populateEnvWithClassDef(cdef, inMods, SCode.PUBLIC(), {}, env,
          elementSplitterRegular, info, env);
      then
        env;

    case (NFEnv.ENTRY(element = SCode.COMPONENT(typeSpec = ty, info = info)), _, _)
      equation
        (entry, env) = lookupTypeSpec(ty, inEnv, info);
        env = enterEntryScope(entry, NFMod.emptyModTable, env);
      then
        env;

  end match;
end enterEntryScope;

protected function openClassEntryScope
  input Entry inClass;
  input Env inEnv;
  output Env outEnv;
protected
  String name;
  SCode.Encapsulated ep;
algorithm
  SCode.CLASS(name = name, encapsulatedPrefix = ep) := NFEnv.entryElement(inClass);
  outEnv := NFEnv.openScope(SOME(name), ep, inEnv);
end openClassEntryScope;

protected function elementSplitterRegular
  input SCode.Element inElement;
  input list<SCode.Element> inClsAndVars;
  input list<SCode.Element> inExtends;
  input list<SCode.Element> inImports;
  output list<SCode.Element> outClsAndVars;
  output list<SCode.Element> outExtends;
  output list<SCode.Element> outImports;
algorithm
  (outClsAndVars, outExtends, outImports) :=
  match(inElement, inClsAndVars, inExtends, inImports)
    case (SCode.COMPONENT(name = _), _, _, _)
      then (inElement :: inClsAndVars, inExtends, inImports);

    case (SCode.CLASS(name = _), _, _, _)
      then (inElement :: inClsAndVars, inExtends, inImports);

    case (SCode.EXTENDS(baseClassPath = _), _, _, _)
      then (inClsAndVars, inElement :: inExtends, inImports);

    case (SCode.IMPORT(imp = _), _, _, _)
      then (inClsAndVars, inExtends, inElement :: inImports);

    else (inClsAndVars, inExtends, inImports);

  end match;
end elementSplitterRegular;

partial function SplitFunc
  input SCode.Element inElement;
  input list<SCode.Element> inClsAndVars;
  input list<SCode.Element> inExtends;
  input list<SCode.Element> inImports;
  output list<SCode.Element> outClsAndVars;
  output list<SCode.Element> outExtends;
  output list<SCode.Element> outImports;
end SplitFunc;

protected function populateEnvWithClassDef
  input SCode.ClassDef inClassDef;
  input ModTable inMods;
  input SCode.Visibility inVisibility;
  input list<EntryOrigin> inOrigins;
  input Env inEnv;
  input SplitFunc inSplitFunc;
  input Absyn.Info inInfo;
  input Env inAccumEnv;
  output Env outAccumEnv;
algorithm
  outAccumEnv := match(inClassDef, inMods, inVisibility, inOrigins, inEnv,
      inSplitFunc, inInfo, inAccumEnv)
    local
      list<SCode.Element> elems, cls_vars, exts, imps;
      Env env;
      list<EntryOrigin> origin;
      Entry entry;
      list<SCode.Enum> enums;
      Absyn.Path path;
      SCode.ClassDef cdef;
      Absyn.TypeSpec ty;

    case (SCode.PARTS(elementLst = elems), _, _, _, _, _, _, env)
      equation
        (cls_vars, exts, imps) =
          populateEnvWithClassDef2(elems, inSplitFunc, {}, {}, {});
        cls_vars = applyVisibilityToElements(cls_vars, inVisibility);
        exts = applyVisibilityToElements(exts, inVisibility);

        origin = NFEnv.collapseInheritedOrigins(inOrigins);
        // Add classes, component and imports first, so that extends can be found.
        env = populateEnvWithElements(cls_vars, origin, env);
        env = NFRedeclare.applyRedeclares(inMods, env);
        env = populateEnvWithImports(imps, env, false);
        env = populateEnvWithExtends(exts, inOrigins, inMods, inEnv, env);
      then
        env;

    case (SCode.CLASS_EXTENDS(composition = cdef), _, _, _, _, _, _, _)
      then populateEnvWithClassDef(cdef, inMods, inVisibility, inOrigins, inEnv,
        inSplitFunc, inInfo, inAccumEnv);

    case (SCode.DERIVED(typeSpec = ty), _, _, _, _, _, _, _)
      equation
        (entry, env) = lookupTypeSpec(ty, inEnv, inInfo);
        SCode.CLASS(classDef = cdef) = NFEnv.entryElement(entry);
        // TODO: Only create this environment if needed, i.e. if the cdef
        // contains extends.
        env = openClassEntryScope(entry, env);
        env = populateEnvWithClassDef(cdef, NFMod.emptyModTable, inVisibility, inOrigins, env,
          elementSplitterExtends, inInfo, inAccumEnv);
        env = populateEnvWithClassDef(cdef, NFMod.emptyModTable, inVisibility, inOrigins, env,
          inSplitFunc, inInfo, inAccumEnv);
      then
        env;

    case (SCode.ENUMERATION(enumLst = enums), _, _, _, _, _, _, env)
      equation
        path = NFEnv.envPath(inEnv);
        env = insertEnumLiterals(enums, path, 1, env);
      then
        env;

  end match;
end populateEnvWithClassDef;

protected function applyVisibilityToElements
  input list<SCode.Element> inElements;
  input SCode.Visibility inVisibility;
  output list<SCode.Element> outElements;
algorithm
  outElements := match(inElements, inVisibility)
    case (_, SCode.PUBLIC()) then inElements;
    else List.map1(inElements, SCode.setElementVisibility, inVisibility);
  end match;
end applyVisibilityToElements;

protected function populateEnvWithClassDef2
  input list<SCode.Element> inElements;
  input SplitFunc inSplitFunc;
  input list<SCode.Element> inClsAndVars;
  input list<SCode.Element> inExtends;
  input list<SCode.Element> inImports;
  output list<SCode.Element> outClsAndVars;
  output list<SCode.Element> outExtends;
  output list<SCode.Element> outImports;
algorithm
  (outClsAndVars, outExtends, outImports) :=
  match(inElements, inSplitFunc, inClsAndVars, inExtends, inImports)
    local
      SCode.Element el;
      list<SCode.Element> rest_el, cls_vars, exts, imps;

    case (el :: rest_el, _, cls_vars, exts, imps)
      equation
        (cls_vars, exts, imps) = inSplitFunc(el, cls_vars, exts, imps);
        (cls_vars, exts, imps) =
          populateEnvWithClassDef2(rest_el, inSplitFunc, cls_vars, exts, imps);
      then
        (cls_vars, exts, imps);

    case ({}, _, _, _, _) then (inClsAndVars, inExtends, inImports);

  end match;
end populateEnvWithClassDef2;

protected function insertEnumLiterals
  input list<SCode.Enum> inEnum;
  input Absyn.Path inEnumPath;
  input Integer inNextValue;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inEnum, inEnumPath, inNextValue, inEnv)
    local
      SCode.Enum lit;
      list<SCode.Enum> rest_lits;
      Env env;

    case (lit :: rest_lits, _, _, _)
      equation
        env = insertEnumLiteral(lit, inEnumPath, inNextValue, inEnv);
      then
        insertEnumLiterals(rest_lits, inEnumPath, inNextValue + 1, env);

    case ({}, _, _, _) then inEnv;

  end match;
end insertEnumLiterals;

protected function insertEnumLiteral
  "Extends the environment with an enumeration."
  input SCode.Enum inEnum;
  input Absyn.Path inEnumPath;
  input Integer inValue;
  input Env inEnv;
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
    SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.CONST(), Absyn.BIDIR()), ty,
    SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);
  outEnv := NFEnv.insertElement(enum_lit, inEnv);
end insertEnumLiteral;

protected function populateEnvWithElements
  input list<SCode.Element> inElements;
  input list<EntryOrigin> inOrigin;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := List.fold1(inElements, NFEnv.insertElementWithOrigin, inOrigin, inEnv);
end populateEnvWithElements;

protected function populateEnvWithImports
  input list<SCode.Element> inImports;
  input Env inEnv;
  input Boolean inIsExtended;
  output Env outEnv;
algorithm
  outEnv := match(inImports, inEnv, inIsExtended)
    local
      Env top_env, env;

    case (_, _, true) then inEnv;
    case ({}, _, _) then inEnv;

    else
      equation
        top_env = NFEnv.topScope(inEnv);
        env = List.fold1(inImports, populateEnvWithImport, top_env, inEnv);
      then
        env;

  end match;
end populateEnvWithImports;

protected function populateEnvWithImport
  input SCode.Element inImport;
  input Env inTopScope;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inImport, inTopScope, inEnv)
    local
      Absyn.Import imp;
      Absyn.Info info;
      Absyn.Path path;
      Entry entry;
      Env env;
      EntryOrigin origin;

    case (SCode.IMPORT(imp = imp, info = info), _, _)
      equation
        // Look up the import name.
        path = Absyn.importPath(imp);
        (entry, env) = lookupImportPath(path, inTopScope, info);
        // Convert the entry to an entry imported into the given environment.
        origin = NFEnv.makeImportedOrigin(inImport, env);
        entry = NFEnv.changeEntryOrigin(entry, {origin}, inEnv);
        // Add the imported entry to the environment.
        env = populateEnvWithImport2(imp, entry, env, info, inEnv);
      then
        env;

  end match;
end populateEnvWithImport;

protected function populateEnvWithImport2
  input Absyn.Import inImport;
  input Entry inEntry;
  input Env inEnv;
  input Absyn.Info inInfo;
  input Env inAccumEnv;
  output Env outAccumEnv;
algorithm
  outAccumEnv := match(inImport, inEntry, inEnv, inInfo, inAccumEnv)
    local
      String name;
      Env env;
      Entry entry;
      SCode.ClassDef cdef;
      list<EntryOrigin> origins;

    // A renaming import, 'import D = A.B.C'.
    case (Absyn.NAMED_IMPORT(name = name), _, _, _, _)
      equation
        entry = NFEnv.renameEntry(inEntry, name);
        env = NFEnv.insertEntry(entry, inAccumEnv);
      then
        env;

    // A qualified import, 'import A.B.C'.
    case (Absyn.QUAL_IMPORT(path = _), _, _, _, _)
      equation
        env = NFEnv.insertEntry(inEntry, inAccumEnv);
      then
        env;

    // An unqualified import, 'import A.B.*'.
    case (Absyn.UNQUAL_IMPORT(path = _),
        NFEnv.ENTRY(element = SCode.CLASS(classDef = cdef), origins = origins), _, _, _)
      equation
        env = populateEnvWithClassDef(cdef, NFMod.emptyModTable, SCode.PUBLIC(),
          origins, inEnv, elementSplitterRegular, inInfo, inAccumEnv);
      then
        env;

    // This should not happen, group imports are split into separate imports by
    // SCodeUtil.translateImports.
    case (Absyn.GROUP_IMPORT(prefix = _), _, _, _, _)
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR,
          {"NFEnv.populateEnvWithImport2 got unhandled group import!\n"}, inInfo);
      then
        inEnv;

  end match;
end populateEnvWithImport2;

protected function populateEnvWithExtends
  input list<SCode.Element> inExtends;
  input list<EntryOrigin> inOrigins;
  input ModTable inMods;
  input Env inEnv;
  input Env inAccumEnv;
  output Env outAccumEnv;
algorithm
  outAccumEnv := List.fold3(inExtends, populateEnvWithExtend, inOrigins, inMods,
    inEnv, inAccumEnv);
end populateEnvWithExtends;

protected function populateEnvWithExtend
  input SCode.Element inExtends;
  input list<EntryOrigin> inOrigins;
  input ModTable inMods;
  input Env inEnv;
  input Env inAccumEnv;
  output Env outAccumEnv;
algorithm
  outAccumEnv := match(inExtends, inOrigins, inMods, inEnv, inAccumEnv)
    local
      Entry entry;
      Env env, accum_env;
      SCode.ClassDef cdef;
      EntryOrigin origin;
      list<EntryOrigin> origins;
      Absyn.Path bc;
      Absyn.Info info;
      SCode.Visibility vis;
      SCode.Mod smod;
      Modifier mod;
      ModTable mods;

    case (SCode.EXTENDS(baseClassPath = bc, visibility = vis,
        modifications = smod, info = info), _, _, _, _)
      equation
        // Look up the base class and check that it's a valid base class.
        (entry, env) = lookupBaseClassName(bc, inEnv, info);
        checkRecursiveExtends(bc, env, inEnv, info);

        // Check entry: not var, not replaceable
        // Create an environment for the base class if needed.
        SCode.CLASS(classDef = cdef) = NFEnv.entryElement(entry);
        mod = NFMod.translateMod(smod, "", 0, NFInstTypes.emptyPrefix, inEnv);
        mods = NFMod.addClassModToTable(mod, inMods);

        env = openClassEntryScope(entry, env);
        env = populateEnvWithClassDef(cdef, mods, SCode.PUBLIC(), {}, env,
          elementSplitterExtends, info, env);
        // Populate the accumulated environment with the inherited elements.
        origin = NFEnv.makeInheritedOrigin(inExtends, env);
        origins = origin :: inOrigins;
        accum_env = populateEnvWithClassDef(cdef, mods, vis, origins, env,
          elementSplitterInherited, info, inAccumEnv);
      then
        accum_env;

  end match;
end populateEnvWithExtend;

protected function checkRecursiveExtends
  input Absyn.Path inExtendedClass;
  input Env inFoundEnv;
  input Env inOriginEnv;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inExtendedClass, inFoundEnv, inOriginEnv, inInfo)
    local
      String bc_name, path_str;
      Env env;

    case (_, _, _, _)
      equation
        bc_name = Absyn.pathLastIdent(inExtendedClass);
        env = NFEnv.openScope(SOME(bc_name), SCode.NOT_ENCAPSULATED(), inFoundEnv);
        false = NFEnv.isPrefix(env, inOriginEnv);
      then
        ();

    else
      equation
        path_str = Absyn.pathString(inExtendedClass);
        Error.addSourceMessage(Error.RECURSIVE_EXTENDS, {path_str}, inInfo);
      then
        fail();

  end matchcontinue;
end checkRecursiveExtends;

protected function elementSplitterExtends
  input SCode.Element inElement;
  input list<SCode.Element> inClsAndVars;
  input list<SCode.Element> inExtends;
  input list<SCode.Element> inImports;
  output list<SCode.Element> outClsAndVars;
  output list<SCode.Element> outExtends;
  output list<SCode.Element> outImports;
algorithm
  (outClsAndVars, outExtends, outImports) :=
  match(inElement, inClsAndVars, inExtends, inImports)
    case (SCode.COMPONENT(name = _), _, _, _)
      then (inElement :: inClsAndVars, inExtends, inImports);

    case (SCode.CLASS(name = _), _, _, _)
      then (inElement :: inClsAndVars, inExtends, inImports);

    case (SCode.IMPORT(imp = _), _, _, _)
      then (inClsAndVars, inExtends, inElement :: inImports);

    else (inClsAndVars, inExtends, inImports);

  end match;
end elementSplitterExtends;

protected function elementSplitterInherited
  input SCode.Element inElement;
  input list<SCode.Element> inClsAndVars;
  input list<SCode.Element> inExtends;
  input list<SCode.Element> inImports;
  output list<SCode.Element> outClsAndVars;
  output list<SCode.Element> outExtends;
  output list<SCode.Element> outImports;
algorithm
  (outClsAndVars, outExtends, outImports) :=
  match(inElement, inClsAndVars, inExtends, inImports)
    case (SCode.COMPONENT(name = _), _, _, _)
      then (inElement :: inClsAndVars, inExtends, inImports);

    case (SCode.CLASS(name = _), _, _, _)
      then (inElement :: inClsAndVars, inExtends, inImports);

    case (SCode.EXTENDS(baseClassPath = _), _, _, _)
      then (inClsAndVars, inElement :: inExtends, inImports);

    else (inClsAndVars, inExtends, inImports);

  end match;
end elementSplitterInherited;

end NFLookup;
