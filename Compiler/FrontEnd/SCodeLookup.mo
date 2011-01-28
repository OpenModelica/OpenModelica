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

encapsulated package SCodeLookup
" file:        SCodeLookup.mo
  package:     SCodeLookup
  description: SCode flattening

  RCS: $Id$

  This module flattens the SCode representation by removing all extends, imports
  and redeclares, and fully qualifying class names.
"

public import Absyn;
public import Error;
public import SCode;
public import SCodeEnv;

public type Env = SCodeEnv.Env;
public type Item = SCodeEnv.Item;
public type Extends = SCodeEnv.Extends;
public type Frame = SCodeEnv.Frame;
public type FrameType = SCodeEnv.FrameType;
public type AvlTree = SCodeEnv.AvlTree;
public type Import = Absyn.Import;

protected import SCodeFlattenImports;

public function lookupSimpleName
  input Absyn.Ident inName;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Env outEnv;
algorithm
  (SOME(outItem), SOME(outPath), SOME(outEnv)) := 
    lookupSimpleName2(inName, inEnv);
end lookupSimpleName;

public function lookupSimpleName2
  input Absyn.Ident inName;
  input Env inEnv;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) := matchcontinue(inName, inEnv)
    local
      FrameType frame_type;
      Env rest_env;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;
      Option<Env> opt_env;

    case (_, _)
      equation
        (opt_item, opt_path, opt_env) = lookupInLocalScope(inName, inEnv);
      then
        (opt_item, opt_path, opt_env);

    case (_, SCodeEnv.FRAME(frameType = frame_type) :: rest_env)
      equation
        frameNotEncapsulated(frame_type);
        (opt_item, opt_path, opt_env) = lookupSimpleName2(inName, rest_env);
      then
        (opt_item, opt_path, opt_env);

  end matchcontinue;
end lookupSimpleName2;

public function frameNotEncapsulated
  input FrameType frameType;
algorithm
  _ := match(frameType)
    case SCodeEnv.ENCAPSULATED_SCOPE() then fail();
    else then ();
  end match;
end frameNotEncapsulated;

public function lookupInLocalScope
  "Looks up a simple identifier in the environment. Returns SOME(item) if an
  item is found, NONE() if a partial match was found (for example when the name
  matches the import name of an import, but the imported class couldn't be
  found), or fails if no match is found."
  input Absyn.Ident inName;
  input Env inEnv;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) := matchcontinue(inName, inEnv)
    local
      AvlTree cls_and_vars;
      Env rest_env, env;
      Item item;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;
      list<Import> imps;
      FrameType frame_type;
      Absyn.Path path;
      Option<Env> opt_env;

    // Look among the locally declared components.
    case (_, SCodeEnv.FRAME(clsAndVars = cls_and_vars) :: _)
      equation
        item = SCodeEnv.avlTreeGet(cls_and_vars, inName);
      then
        (SOME(item), SOME(Absyn.IDENT(inName)), SOME(inEnv));

    // Look among the inherited components.
    case (_, _)
      equation
        (item, path, _, env) = lookupInBaseClasses(inName, inEnv);
      then
        (SOME(item), SOME(path), SOME(env));

    // Look among the qualified imports.
    case (_, SCodeEnv.FRAME(importTable = SCodeEnv.IMPORT_TABLE(qualifiedImports = imps)) :: _)
      equation
        (opt_item, opt_path, opt_env) = 
          lookupInQualifiedImports(inName, imps, inEnv);
      then
        (opt_item, opt_path, opt_env);

    // Look among the unqualified imports.
    case (_, SCodeEnv.FRAME(importTable = SCodeEnv.IMPORT_TABLE(unqualifiedImports = imps)) :: _)
      equation
        (opt_item, opt_path, opt_env) = 
          lookupInUnqualifiedImports(inName, imps, inEnv);
      then
        (opt_item, opt_path, opt_env);

    // Look in the next scope only if the current scope is an implicit scope
    // created by a for loop.
    case (_, SCodeEnv.FRAME(frameType = SCodeEnv.IMPLICIT_SCOPE()) :: rest_env)
      equation
        (opt_item, opt_path, opt_env) = lookupInLocalScope(inName, rest_env);
      then
        (opt_item, opt_path, opt_env);

  end matchcontinue;
end lookupInLocalScope;

public function lookupInBaseClasses
  "Looks up an identifier by following the extends clauses in a scope."
  input Absyn.Ident inName;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Absyn.Path outBaseClass;
  output Env outEnv;

  Env env;
  list<Extends> bcl;
algorithm
  SCodeEnv.FRAME(extendsTable = SCodeEnv.EXTENDS_TABLE(baseClasses = bcl as _ :: _)) :: _ := inEnv;
  // We need to remove the extends from the current scope, because the names of
  // extended classes should not be found by lookup through the extends-clauses
  // (Modelica Specification 3.2, section 5.6.1.).
  env := SCodeEnv.removeExtendsFromLocalScope(inEnv);
  (outItem, outPath, outBaseClass, outEnv) := 
    lookupInBaseClasses2(inName, bcl, env);
end lookupInBaseClasses;

public function lookupInBaseClasses2
  input Absyn.Ident inName;
  input list<Extends> inBaseClasses;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Absyn.Path outBaseClass;
  output Env outEnv;
algorithm
  (outItem, outPath, outBaseClass, outEnv) := 
  matchcontinue(inName, inBaseClasses, inEnv)
    local
      Absyn.Path bc, path;
      list<Extends> rest_bc;
      Item item;
      Env env;
      list<SCode.Element> redecls;
      Absyn.Info info;

    // Look in the first base class.
    case (_, SCodeEnv.EXTENDS(baseClass = bc, redeclareModifiers = redecls, 
        info = info) :: _, inEnv)
      equation
        (item, _, SOME(env)) = lookupBaseClassName(bc, inEnv, info);
        (item, env) = SCodeEnv.replaceRedeclaredClassesInEnv(redecls, item, env, inEnv);
        (item, path, env) = lookupNameInItem(Absyn.IDENT(inName), item, env);
      then
        (item, path, bc, env);

    // No match, check the rest of the base classes.
    case (_, _ :: rest_bc, _)
      equation
        (item, path, bc, env) = lookupInBaseClasses2(inName, rest_bc, inEnv);
      then
        (item, path, bc, env);

  end matchcontinue;
end lookupInBaseClasses2;

public function lookupInQualifiedImports
  input Absyn.Ident inName;
  input list<Import> inImports;
  input Env inEnv;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) := matchcontinue(inName, inImports, inEnv)
    local
      Absyn.Ident name;
      Absyn.Path path;
      Item item;
      list<Import> rest_imps;
      Import imp;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;
      Option<Env> opt_env;
      Env env;

    // No match, search the rest of the list of imports.
    case (_, Absyn.NAMED_IMPORT(name = name) :: rest_imps, _)
      equation
        false = stringEqual(inName, name);
        (opt_item, opt_path, opt_env) = 
          lookupInQualifiedImports(inName, rest_imps, inEnv);
      then
        (opt_item, opt_path, opt_env);

    // Match, look up the fully qualified import path.
    case (_, Absyn.NAMED_IMPORT(name = name, path = path) :: _, _)
      equation
        true = stringEqual(inName, name);
        (item, path, env) = lookupFullyQualified(path, inEnv);  
      then
        (SOME(item), SOME(path), SOME(env));

    // Partial match, return NONE(). This is when only part of the import path
    // can be found, in which case we should stop looking further.
    case (_, Absyn.NAMED_IMPORT(name = name, path = path) :: _, _)
      equation
        true = stringEqual(inName, name);
      then
        (NONE(), NONE(), NONE());

  end matchcontinue;
end lookupInQualifiedImports;

public function lookupInUnqualifiedImports
  input Absyn.Ident inName;
  input list<Import> inImports;
  input Env inEnv;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) := matchcontinue(inName, inImports, inEnv)
    local
      Item item;
      Absyn.Path path, path2;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;
      list<Import> rest_imps;
      Env env;
      Option<Env> opt_env;

    // For each unqualified import we have to look up the package the import
    // points to, and then look among the public member of the package for the
    // name we are looking for.
    case (_, Absyn.UNQUAL_IMPORT(path = path) :: _, _)
      equation
        // Look up the import path.
        (item, path, env) = lookupFullyQualified(path, inEnv);
        // Look up the name among the public member of the found package.
        (item, path2, env) = lookupNameInItem(Absyn.IDENT(inName), item, env);
        // Combine the paths for the name and the package it was found in.
        path = SCodeEnv.joinPaths(path, path2);
      then
        (SOME(item), SOME(path), SOME(env));

    // No match, continue with the rest of the imports.
    case (_, _ :: rest_imps, _)
      equation
        (opt_item, opt_path, opt_env) = 
          lookupInUnqualifiedImports(inName, rest_imps, inEnv);
      then
        (opt_item, opt_path, opt_env);
  end matchcontinue;
end lookupInUnqualifiedImports;

public function lookupFullyQualified
  input Absyn.Path inName;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Env outEnv;
public
  Env env;
  Frame top_scope;
  Absyn.Path path, path2;
  Option<Absyn.Path> opt_path;
algorithm
  env := SCodeEnv.getEnvTopScope(inEnv);
  (outItem, outPath, outEnv) := lookupNameInPackage(inName, env);
  outPath := Absyn.FULLYQUALIFIED(outPath);
end lookupFullyQualified;

public function lookupNameInPackage
  input Absyn.Path inName;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Env outEnv;
algorithm
  (outItem, outPath, outEnv) := match(inName, inEnv)
    local
      Absyn.Ident name;
      Absyn.Path path, new_path;
      AvlTree cls_and_vars;
      Frame top_scope;
      Env rest_env, env;
      Item item;

    case (Absyn.IDENT(name = name), _)
      equation
        (SOME(item), SOME(path), SOME(env)) = lookupInLocalScope(name, inEnv);
      then
        (item, path, env);

    case (Absyn.QUALIFIED(name = name, path = path), top_scope :: _)
      equation
        (SOME(item), SOME(new_path), SOME(env)) = lookupInLocalScope(name, inEnv); 
        (item, path, env) = lookupNameInItem(path, item, env);
        path = SCodeEnv.joinPaths(new_path, path);
      then
        (item, path, env);

  end match;
end lookupNameInPackage;

public function lookupCrefInPackage
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  output Item outItem;
  output Absyn.ComponentRef outCref;
algorithm
  (outItem, outCref) := match(inCref, inEnv)
    local
      Absyn.Ident name;
      Absyn.Path new_path;
      list<Absyn.Subscript> subs;
      Absyn.ComponentRef cref, cref_rest;
      Item item;
      Frame top_scope;
      Env env;
     
    case (Absyn.CREF_IDENT(name = name, subscripts = subs), _)
      equation
        (SOME(item), SOME(new_path), _) = lookupInLocalScope(name, inEnv);
        cref = Absyn.pathToCrefWithSubs(new_path, subs);
      then
        (item, cref);

    case (Absyn.CREF_QUAL(name = name, subScripts = subs, 
        componentRef = cref_rest), _)
      equation
        (SOME(item), SOME(new_path), SOME(env)) = 
          lookupInLocalScope(name, inEnv);
        (item, cref_rest) = lookupCrefInItem(cref_rest, item, env);
        cref = Absyn.pathToCrefWithSubs(new_path, subs);
        cref = Absyn.joinCrefs(cref, cref_rest);
      then
        (item, cref);

  end match;
end lookupCrefInPackage;

public function lookupNameInItem
  input Absyn.Path inName;
  input Item inItem;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Env outEnv;
algorithm
  (outItem, outPath, outEnv) := match(inName, inItem, inEnv)
    local
      SCode.Element var;
      Item item;
      Absyn.Path path;
      Frame class_env;
      Env env, type_env;
      Absyn.TypeSpec type_spec;
      SCode.Mod mods;
      list<SCode.Element> redeclares;
      Absyn.Info info;

    case (_, SCodeEnv.VAR(var = SCode.COMPONENT(typeSpec = type_spec, 
        modifications = mods, info = info)), _)
      equation
        (item, type_env) = lookupTypeSpec(type_spec, inEnv, info);
        redeclares = SCodeEnv.extractRedeclaresFromModifier(mods);
        (item, type_env) = 
          SCodeEnv.replaceRedeclaredClassesInEnv(redeclares, item, type_env, inEnv);
        (item, path, env) = lookupNameInItem(inName, item, type_env);
      then
        (item, path, env);

    case (_, SCodeEnv.CLASS(env = {class_env}), _) 
      equation
        env = class_env :: inEnv;
        (item, path, env) = lookupNameInPackage(inName, env);
      then
        (item, path, env);

  end match;
end lookupNameInItem;

public function lookupCrefInItem
  input Absyn.ComponentRef inCref;
  input Item inItem;
  input Env inEnv;
  output Item outItem;
  output Absyn.ComponentRef outCref;
algorithm
  (outItem, outCref) := match(inCref, inItem, inEnv)
    local
      Item item;
      Absyn.ComponentRef cref;
      Frame class_env;
      Env env, type_env;
      Absyn.TypeSpec type_spec;
      SCode.Mod mods;
      list<SCode.Element> redeclares;
      Absyn.Info info;

    case (_, SCodeEnv.VAR(var = SCode.COMPONENT(typeSpec = type_spec, 
        modifications = mods, info = info)), _)
      equation
        (item, type_env) = lookupTypeSpec(type_spec, inEnv, info);
        redeclares = SCodeEnv.extractRedeclaresFromModifier(mods);
        (item, type_env) = SCodeEnv.replaceRedeclaredClassesInEnv(redeclares, item, type_env, inEnv);
        (item, cref) = lookupCrefInItem(inCref, item, type_env);
      then
        (item, cref);

    case (_, SCodeEnv.CLASS(env = {class_env}), _)
      equation
        env = class_env :: inEnv;
        (item, cref) = lookupCrefInPackage(inCref, env);
      then
        (item, cref);

  end match;
end lookupCrefInItem;

public function lookupBaseClass
  "Looks up from which base class a certain class is inherited from by searching
  the extends in the local scope."
  input SCode.Ident inClass;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Absyn.Path outBaseClass;
algorithm
  outBaseClass := matchcontinue(inClass, inEnv, inInfo)
    local
      Absyn.Path bc;

    case (_, _, _)
      equation
        (_, _, bc, _) = lookupInBaseClasses(inClass, inEnv);
      then
        bc;

    else
      equation
        print("- SCodeFlatten.lookupBaseClass: Could not find "
        +& inClass +& " among the inherited classes.\n");
      then
        fail();
  end matchcontinue;
end lookupBaseClass;

public function lookupBuiltinType
  input Absyn.Ident inName;
  output Item outItem;
algorithm
  outItem := match(inName)
    case "Real" then SCodeEnv.BUILTIN_REAL;
    case "Integer" then SCodeEnv.BUILTIN_INTEGER;
    case "Boolean" then SCodeEnv.BUILTIN_BOOLEAN;
    case "String" then SCodeEnv.BUILTIN_STRING;
    case "StateSelect" then SCodeEnv.BUILTIN_STATESELECT;
    case "ExternalObject" then SCodeEnv.BUILTIN_EXTERNALOBJECT;
  end match;
end lookupBuiltinType;

protected function lookupName
  "Looks up a simple or qualified name in the environment and returns the
  environment item corresponding to the name, the fully qualified path for the
  name and optionally the enclosing scope of the name if the name references a
  class. This function doesn't know what kind of thing the name references, so
  to get meaningful error messages you should use one of the lookup****Name
  below instead."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  input Error.ErrorID inErrorType;
  output Item outItem;
  output Absyn.Path outName;
  output Option<Env> outEnv;
algorithm
  (outItem, outName, outEnv) := 
  matchcontinue(inName, inEnv, inInfo, inErrorType)
    local
      Absyn.Ident id;
      Item item;
      Absyn.Path path, new_path;
      Env env;
      Option<Env> item_env;
      String name_str, env_str;

    case (Absyn.IDENT(name = id), _, _, _)
      equation
        item = lookupBuiltinType(id);
      then
        (item, inName, SOME(SCodeEnv.emptyEnv));

    // Simple name.
    case (Absyn.IDENT(name = id), _, _, _)
      equation
        (item, new_path, env) = lookupSimpleName(id, inEnv);
      then
        (item, new_path, SOME(env));

    // Qualified name.
    case (Absyn.QUALIFIED(name = id, path = path), _, _, _)
      equation
        // Look up the first identifier.
        (item, new_path, env) = lookupSimpleName(id, inEnv);
        // Look up the rest of the name in the environment of the first
        // identifier.
        (item, path, env) = lookupNameInItem(path, item, env);
        path = SCodeEnv.joinPaths(new_path, path);
      then
        (item, path, SOME(env));
      
    else
      equation
        name_str = Absyn.pathString(inName);
        env_str = SCodeEnv.getEnvName(inEnv);
        Error.addSourceMessage(inErrorType, {name_str, env_str}, inInfo);
      then
        fail();
        
  end matchcontinue;
end lookupName;

public function lookupClassName
  "Calls lookupName with the 'Class not found' error message."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Item outItem;
  output Absyn.Path outName;
  output Option<Env> outEnv;
algorithm
  (outItem, outName, outEnv) := lookupName(inName, inEnv, inInfo,
    Error.LOOKUP_ERROR);
end lookupClassName;

public function lookupBaseClassName
  "Calls lookupName with the 'Baseclass not found' error message."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Item outItem;
  output Absyn.Path outName;
  output Option<Env> outEnv;
algorithm
  (outItem, outName, outEnv) := lookupName(inName, inEnv, inInfo,
    Error.LOOKUP_BASECLASS_ERROR);
end lookupBaseClassName;

public function lookupVariableName
  "Calls lookupName with the 'Variable not found' error message."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Item outItem;
  output Absyn.Path outName;
  output Option<Env> outEnv;
algorithm
  (outItem, outName, outEnv) := lookupName(inName, inEnv, inInfo,
    Error.LOOKUP_VARIABLE_ERROR);
end lookupVariableName;

public function lookupComponentRef
  "Look up a component reference in the environment and returns it fully
  qualified."
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Absyn.ComponentRef outCref;

algorithm
  outCref := matchcontinue(inCref, inEnv, inInfo)
    local
      Absyn.ComponentRef cref;
      String cref_str, env_str;

    case (Absyn.CREF_QUAL(name = "StateSelect", subScripts = {}, 
        componentRef = Absyn.CREF_IDENT(name = _)), _, _)
      then inCref;

    case (Absyn.WILD(), _, _) then inCref;

    case (_, _, _)
      equation
        // First look up all subscripts, because all subscripts should be found
        // in the enclosing scope of the component reference.
        cref = SCodeFlattenImports.flattenComponentRefSubs(inCref, inEnv, inInfo);
        // Then look up the component reference itself.
        cref = lookupComponentRef2(cref, inEnv);
      then
        cref;

    else
      equation
        cref_str = Absyn.printComponentRefStr(inCref);
        env_str = SCodeEnv.getEnvName(inEnv);
        Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR, 
          {cref_str, env_str}, inInfo);
      then
        fail();

  end matchcontinue;
end lookupComponentRef;

public function lookupComponentRef2
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := match(inCref, inEnv)
    local
      Absyn.ComponentRef cref, rest_cref;
      Absyn.Ident name;
      list<Absyn.Subscript> subs;
      Absyn.Path path, new_path;
      Env env;
      Item item;

    case (Absyn.CREF_IDENT(name, subs), _)
      equation
        (_, path, _) = lookupSimpleName(name, inEnv);
        cref = Absyn.pathToCrefWithSubs(path, subs);
      then
        cref;

    case (Absyn.CREF_QUAL(name, subs, rest_cref), _)
      equation
        // Lookup the first identifier.
        (item, new_path, env) = lookupSimpleName(name, inEnv);
        cref = Absyn.pathToCrefWithSubs(new_path, subs);

        // Lookup the rest of the cref in the enclosing scope of the first
        // identifier.
        (item, rest_cref) = lookupCrefInItem(rest_cref, item, env);
        cref = joinCrefs(cref, rest_cref); 
      then
        cref;

    case (Absyn.CREF_FULLYQUALIFIED(componentRef = cref), _)
      equation
        cref = lookupComponentRef2(cref, inEnv);
      then
        Absyn.CREF_FULLYQUALIFIED(cref);

  end match;
end lookupComponentRef2;

public function joinCrefs
  input Absyn.ComponentRef inCref1;
  input Absyn.ComponentRef inCref2;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := match(inCref1, inCref2)
    case (_, Absyn.CREF_FULLYQUALIFIED(componentRef = _)) then inCref2;
    else then Absyn.joinCrefs(inCref1, inCref2);
  end match;
end joinCrefs;

public function lookupTypeSpec
  input Absyn.TypeSpec inTypeSpec;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Item outItem;
  output Env outTypeEnv;
algorithm
  (outItem, outTypeEnv) := match(inTypeSpec, inEnv, inInfo)
    local
      Absyn.Path path;
      Absyn.Ident name;
      Item item;
      Env env;

    case (Absyn.TPATH(path = path), _, _)
      equation
        (item, _, SOME(env)) = lookupClassName(path, inEnv, inInfo);
      then
        (item, env);

    case (Absyn.TCOMPLEX(path = Absyn.IDENT(name = name)), _, _)
      then (SCodeEnv.BUILTIN(name), SCodeEnv.emptyEnv);
         
  end match;
end lookupTypeSpec;
   
end SCodeLookup;
