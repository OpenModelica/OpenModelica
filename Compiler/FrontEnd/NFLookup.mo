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
public import SCode;

protected import NFBuiltin;

public type Env = NFEnv.Env;
public type Entry = NFEnv.Entry;

protected constant Entry REAL_TYPE_ENTRY = NFEnv.ENTRY(
    "Real", NFBuiltin.BUILTIN_REAL, 0);
protected constant Entry INT_TYPE_ENTRY = NFEnv.ENTRY(
    "Integer", NFBuiltin.BUILTIN_INTEGER, 0);
protected constant Entry BOOL_TYPE_ENTRY = NFEnv.ENTRY(
    "Boolean", NFBuiltin.BUILTIN_BOOLEAN, 0);
protected constant Entry STRING_TYPE_ENTRY = NFEnv.ENTRY(
    "String", NFBuiltin.BUILTIN_BOOLEAN, 0);

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
      then
        (entry, env);

  end matchcontinue;
end lookupClassName;

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
      Absyn.Ident id;
      Env env;
      Entry entry;
      Absyn.Path path;

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
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE(), {}, NONE()), Absyn.dummyInfo);
end makeDummyMetaType;

public function lookupUnresolvedSimpleName
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
        (entry, env) = NFEnv.resolveImportedEntry(entry, inEnv);
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
  (outEntry, env) := NFEnv.resolveImportedEntry(entry, inEnv);
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
        env = NFEnv.enterEntryScope(inEntry, inEnv);
        (entry, env) = lookupNameInPackage(inName, env);
      then
        (entry, env);

  end match;
end lookupNameInEntry;

end NFLookup;
