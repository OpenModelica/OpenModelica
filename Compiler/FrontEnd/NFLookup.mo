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
" file:        NFLookup.mo
  package:     NFLookup
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
protected import System;

public type Env = NFEnv.Env;
public type Entry = NFEnv.Entry;
public type EntryOrigin = NFEnv.EntryOrigin;
public type Modifier = NFInstTypes.Modifier;
public type ModTable = NFMod.ModTable;

protected constant Entry REAL_TYPE_ENTRY = NFEnv.ENTRY(
    "Real", NFBuiltin.BUILTIN_REAL, {NFEnv.BUILTIN_ORIGIN()});
protected constant Entry INT_TYPE_ENTRY = NFEnv.ENTRY(
    "Integer", NFBuiltin.BUILTIN_INTEGER, {NFEnv.BUILTIN_ORIGIN()});
protected constant Entry BOOL_TYPE_ENTRY = NFEnv.ENTRY(
    "Boolean", NFBuiltin.BUILTIN_BOOLEAN, {NFEnv.BUILTIN_ORIGIN()});
protected constant Entry STRING_TYPE_ENTRY = NFEnv.ENTRY(
    "String", NFBuiltin.BUILTIN_STRING, {NFEnv.BUILTIN_ORIGIN()});

protected uniontype LookupState
  "LookupState is used by the name lookup to keep track of what state it's in,
   so that the rules for composite name lookup can be enforced. See nextState."
  record STATE_BEGIN "The start state." end STATE_BEGIN;
  record STATE_COMP "Found name is component." end STATE_COMP;
  record STATE_COMP_COMP "Found name is component found in component." end STATE_COMP_COMP;
  record STATE_COMP_CLASS "Found name is class found in component." end STATE_COMP_CLASS;
  record STATE_COMP_FUNC "Found name is function found in component." end STATE_COMP_FUNC;
  record STATE_PACKAGE "Found name is package." end STATE_PACKAGE;
  record STATE_CLASS "Found name is class." end STATE_CLASS;
  record STATE_FUNC "Found name is function." end STATE_FUNC;
end LookupState;

public function lookupNameSilent
  "Looks up a name, but doesn't print an error message if it fails."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv, _) := lookupName(inName, inEnv, STATE_BEGIN(), inInfo, NONE());
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
      LookupState state;

    case (Absyn.IDENT(name = name), _, _)
      equation
        (entry, env) = lookupBuiltinType(name, inEnv);
      then
        (entry, env);

    else
      equation
        (entry, env, state) = lookupName(inName, inEnv, STATE_BEGIN(), inInfo, SOME(Error.LOOKUP_ERROR));
        validateEndState(state, STATE_CLASS(), inName, inInfo);
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
      Env env;
      Entry entry;
      LookupState state;

    // Normal baseclass.
    case (_, _, _)
      equation
        (entry, env, state) = lookupName(inName, inEnv, STATE_BEGIN(), inInfo,
          SOME(Error.LOOKUP_BASECLASS_ERROR));
        validateEndState(state, STATE_CLASS(), inName, inInfo);
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
protected
  LookupState state;
algorithm
  (outEntry, outEnv, state) := lookupName(inName, inEnv, STATE_BEGIN(), inInfo,
    SOME(Error.LOOKUP_VARIABLE_ERROR));
  validateEndState(state, STATE_COMP(), inName, inInfo);
end lookupVariableName;

public function lookupFunctionName
  "Calls lookupName with the 'Function not found' error message."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Entry outEntry;
  output Env outEnv;
protected
  LookupState state;
algorithm
  (outEntry, outEnv, state) := lookupName(inName, inEnv, STATE_BEGIN(), inInfo,
    SOME(Error.LOOKUP_FUNCTION_ERROR));
  validateEndState(state, STATE_FUNC(), inName, inInfo);
end lookupFunctionName;

public function lookupLocalName
  input Absyn.Path inName;
  input Env inEnv;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv, _) := lookupNameInPackage(inName, inEnv, STATE_BEGIN());
end lookupLocalName;

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
        (entry, env, _) = lookupFullyQualified(inPath, inEnv);
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
        entry = NFEnv.makeEntry(cls);
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
  input LookupState inState;
  input Absyn.Info inInfo;
  input Option<Error.Message> inErrorType;
  output Entry outEntry;
  output Env outEnv;
  output LookupState outState;
algorithm
  (outEntry, outEnv, outState) := matchcontinue(inName, inEnv, inState, inInfo, inErrorType)
    local
      String name;
      Absyn.Path path;
      Entry entry;
      Env env;
      Error.Message error_id;
      String name_str, env_str;
      LookupState state;

    case (Absyn.IDENT(name = name), _, _, _, _)
      equation
        (entry, env) = lookupSimpleName(name, inEnv);
        state = nextState(entry, inState, inEnv);
      then
        (entry, env, state);

    case (Absyn.QUALIFIED(name = name, path = path), _, _, _, _)
      equation
        (entry, env) = lookupSimpleName(name, inEnv);
        checkPartial(entry);
        state = nextState(entry, inState, inEnv);
        (entry, env, state) = lookupNameInEntry(path, entry, env, state);
      then
        (entry, env, state);

    case (Absyn.FULLYQUALIFIED(path = path), _, _, _, _)
      equation
        (entry, env, state) = lookupFullyQualified(path, inEnv);
      then
        (entry, env, state);

    case (_, _, _, _, SOME(error_id))
      equation
        name_str = Absyn.pathString(inName);
        env_str = NFEnv.printEnvPathStr(inEnv);
        Error.addSourceMessage(error_id, {name_str, env_str}, inInfo);
      then
        fail();

  end matchcontinue;
end lookupName;
  
protected function checkPartial
  "Checks that a found entry isn't partial. and prints an error if it is."
  input Entry inEntry;
algorithm
  _ := matchcontinue(inEntry)
    local
      String name;
      Absyn.Info info;

    case (_)
      equation
        false = SCode.isPartial(NFEnv.entryElement(inEntry));
      then
        ();

    else
      equation
        (name, info) = SCode.elementNameInfo(NFEnv.entryElement(inEntry));
        Error.addSourceMessage(Error.LOOKUP_IN_PARTIAL_CLASS, {name}, info);
      then
        fail();

  end matchcontinue;
end checkPartial;

protected function validateEndState
  "This function checks that the final state of a name lookup is valid.
   inExpectedState is expected to be one of STATE_COMP, STATE_CLASS or
   STATE_FUNC, and represents the kind of element we expected to find."
  input LookupState inEndState;
  input LookupState inExpectedState;
  input Absyn.Path inName;
  input Absyn.Info inInfo;
algorithm
  _ := match(inEndState, inExpectedState, inName, inInfo)
    local
      String name, found_str, expected_str;

    // Found the expected kind of element.
    case (STATE_COMP(),      STATE_COMP(), _, _) then ();
    case (STATE_COMP_COMP(), STATE_COMP(), _, _) then ();
    case (STATE_PACKAGE(),   STATE_CLASS(), _, _) then ();
    case (STATE_CLASS(),     STATE_CLASS(), _, _) then ();
    case (STATE_FUNC(),      STATE_FUNC(), _, _) then ();
    case (STATE_COMP_FUNC(), STATE_FUNC(), _, _) then ();
    
    // Found a class via a component, but expected a function.
    case (STATE_COMP_CLASS(), STATE_FUNC(), _, _)
      equation
        printFoundWrongTypeError(inEndState, inExpectedState, inName, inInfo);
      then
        fail();

    // Found a function via a component, but didn't expect a function.
    case (STATE_COMP_FUNC(), _, _, _)
      equation
        name = Absyn.pathString(inName);
        Error.addSourceMessage(Error.FOUND_FUNC_NAME_VIA_COMP_NONCALL, {name}, inInfo);
      then
        fail();

    // Found a class via a component. Only component and functions are allowed
    // to be looked up via a component.
    case (STATE_COMP_CLASS(), _, _, _)
      equation
        name = Absyn.pathString(inName);
        Error.addSourceMessage(Error.FOUND_CLASS_NAME_VIA_COMPONENT, {name}, inInfo);
      then
        fail();

    // Found the wrong kind of element.
    else
      equation
        printFoundWrongTypeError(inEndState, inExpectedState, inName, inInfo);
      then
        fail();

  end match;
end validateEndState;

protected function lookupStateString
  "Returns the string representation of a LookupState, with translation."
  input LookupState inState;
  output String outString;
algorithm
  outString := match(inState)
    case STATE_BEGIN() then "<begin>";
    case STATE_COMP() then System.gettext("component");
    case STATE_COMP_COMP() then System.gettext("component");
    case STATE_COMP_CLASS() then System.gettext("class");
    case STATE_COMP_FUNC() then System.gettext("function");
    case STATE_PACKAGE() then System.gettext("package");
    case STATE_CLASS() then System.gettext("class");
    case STATE_FUNC() then System.gettext("function");
  end match;
end lookupStateString;

protected function printFoundWrongTypeError
  "Helper function to validateEndState, prints out an error when the wrong kind
   of element was found."
  input LookupState inFoundState;
  input LookupState inExpectedState;
  input Absyn.Path inName;
  input Absyn.Info inInfo;
protected
  String name, found_str, expected_str;
algorithm
  name := Absyn.pathString(inName);
  found_str := lookupStateString(inFoundState);
  expected_str := lookupStateString(inExpectedState);
  Error.addSourceMessage(Error.LOOKUP_FOUND_WRONG_TYPE,
    {name, expected_str, found_str}, inInfo);
end printFoundWrongTypeError;
    
protected function nextState
  "Checks that the found name is allowed to be looked up given the current state
   of the name lookup, and returns the new state if it is. Otherwise it will
   print a (hopefully relevant) error message and fail."
  input Entry inEntry;
  input LookupState inCurrentState;
  input Env inEnv;
  output LookupState outNextState;
protected
  LookupState entry_ty;
  SCode.Element el;
algorithm
  el := NFEnv.entryElement(inEntry);
  // Check that the element is allowed to be accessed given its visibility.
  checkProtection(el, inCurrentState);
  // Check that we're allowed to look in the current scope.
  checkPackageLikeAccess(inCurrentState, el, inEnv);
  // Get the state for the found element, and check that the transition to the
  // new state is valid.
  entry_ty := elementState(el);
  outNextState := nextState2(entry_ty, inCurrentState, el);
end nextState;

protected function checkProtection
  "Checks if a found element is protected during lookup, and prints an error if
   the element was not the first part of a name while being protected.
   I.e. P.a is allowed if P is protected, but not e.g. a.P or a.P.b."
  input SCode.Element inElement;
  input LookupState inCurrentState;
algorithm
  _ := matchcontinue(inElement, inCurrentState)
    local
      String name;
      Absyn.Info info;

    // The first part of a name is allowed to be protected, i.e. when accessing
    // protected elements locally.
    case (_, STATE_BEGIN()) then ();

    // Public elements are ok.
    case (_, _)
      equation
        false = SCode.isElementProtected(inElement);
      then
        ();

    // Protected names generate an error.
    else
      equation
        (name, info) = SCode.elementNameInfo(inElement);
        Error.addSourceMessage(Error.PROTECTED_ACCESS, {name}, info);
      then
        fail();

  end matchcontinue;
end checkProtection;

protected function elementState
  "Returns the lookup state of a given element."
  input SCode.Element inElement;
  output LookupState outState;
algorithm
  outState := match(inElement)
    case SCode.COMPONENT(name = _) then STATE_COMP();
    case SCode.CLASS(restriction = SCode.R_PACKAGE()) then STATE_PACKAGE();
    case SCode.CLASS(restriction = SCode.R_FUNCTION(_)) then STATE_FUNC();
    case SCode.CLASS(restriction = _) then STATE_CLASS();
  end match;
end elementState;
  
protected function nextState2
 "This function implements the state machine that checks which transitions are
  valid during composite name lookup, as defined in section 5.3.2 of the
  specification. inElementState is expected to be one of STATE_COMP,
  STATE_CLASS, STATE_FUNC or STATE_PACKAGE, indicating what type the found
  element is. The state machine looks like this flow diagram (nodes in
  [brackets] are nodes with an edge to themselves):
            
     BEGIN----------------+-----------------+-------------+
                          |(COMP)           |(PACKAGE)    |(CLASS/FUNC)
                          v                 v             v
         +---------------COMP------+----[PACKAGE]<->[CLASS/FUNC]
         |(CLASS|PACKAGE) |(FUNC)  |(COMP)                |(COMP) 
         |                |        |                      |only if
         v                |        v                      |package-like
    [COMP_CLASS]          |   [COMP_COMP]<----------------+
         ^(CLASS|PACKAGE) |     
         |                |      
         v(FUNC)          |
    [COMP_FUNC]<----------+
"
  input LookupState inElementState;
  input LookupState inCurrentState;
  input SCode.Element inElement;
  output LookupState outNextState;
algorithm
  outNextState := match(inElementState, inCurrentState, inElement)
    local
      String name;
      Absyn.Info info;

    // Transitions from BEGIN.
    case (_,               STATE_BEGIN(), _)      then inElementState;

    // Transitions from COMP.
    case (STATE_COMP(),    STATE_COMP(), _)       then STATE_COMP_COMP();
    case (STATE_FUNC(),    STATE_COMP(), _)       then STATE_COMP_FUNC();
    case (_,               STATE_COMP(), _)       then STATE_COMP_CLASS();
    
    // Transitions from COMP_COMP.
    case (STATE_COMP(),    STATE_COMP_COMP(), _)  then STATE_COMP_COMP();

    // Transitions from PACKAGE.
    case (STATE_COMP(),    STATE_PACKAGE(), _)    then STATE_COMP_COMP();
    case (_,               STATE_PACKAGE(), _)    then inElementState;

    // Transitions from CLASS/FUNC.
    // nextState has already checked that the found element is encapsulated or
    // the class/func looks like a package, so any transition is fine here.
    case (STATE_COMP(),    STATE_CLASS(), _)      then STATE_COMP_COMP();
    case (_,               STATE_CLASS(), _)      then inElementState;
    case (STATE_COMP(),    STATE_FUNC(), _)       then STATE_COMP_COMP();
    case (_,               STATE_FUNC(), _)       then inElementState;

    // Transitions from COMP_CLASS.
    case (STATE_FUNC(),    STATE_COMP_CLASS(), _) then STATE_COMP_FUNC();
    case (STATE_CLASS(),   STATE_COMP_CLASS(), _) then STATE_COMP_CLASS();
    case (STATE_PACKAGE(), STATE_COMP_CLASS(), _) then STATE_COMP_CLASS();

    // Transitions from COMP_FUNC.
    case (STATE_FUNC(),    STATE_COMP_FUNC(), _)  then STATE_COMP_FUNC();
    case (STATE_CLASS(),   STATE_COMP_FUNC(), _)  then STATE_COMP_CLASS();
    case (STATE_PACKAGE(), STATE_COMP_FUNC(), _)  then STATE_COMP_CLASS();

    // When looking for a function in a component the only valid form is
    // c.M1..MN.f, where M1..Mn are classes, but we found a component instead.
    case (STATE_COMP(), _, _)
      equation
        (name, info) = SCode.elementNameInfo(inElement);
        Error.addSourceMessage(Error.NON_CLASS_IN_COMP_FUNC_NAME, {name}, info);
      then
        fail();
        
    // We found a class when only components are allowed, i.e. when not looking
    // for a function via a component.
    case (_,               STATE_COMP_COMP(), _)
      equation
        (name, info) = SCode.elementNameInfo(inElement);
        Error.addSourceMessage(Error.CLASS_IN_COMPOSITE_COMP_NAME, {name}, info);
      then
        fail();

  end match;
end nextState2;

protected function checkPackageLikeAccess
  "Checks that the found is element is allowed to be looked up in the current
   scope. In particular it checks that only encapsulated elements are allowed to
   be looked up in classes which does not satisfy the requirements for a package."
  input LookupState inCurrentState;
  input SCode.Element inElement;
  input Env inEnv;
algorithm
  _ := matchcontinue(inCurrentState, inElement, inEnv)
    local
      String name, env_str;
      Absyn.Info info;

    // Nothing to check in packages or components.
    case (STATE_BEGIN(), _, _) then ();
    case (STATE_PACKAGE(), _, _) then ();
    case (STATE_COMP(), _, _) then ();
    case (STATE_COMP_COMP(), _, _) then ();

    // Check if the found element is encapsulated, then it's ok to look it up in
    // a non-package.
    case (_, _, _)
      equation
        true = SCode.isElementEncapsulated(inElement);
      then
        ();

    // If the found element is not encapsulated, check if the current scope
    // satisfies the requirements for a package, i.e. only contains classes and
    // constants.
    case (_, _, _)
      equation
        _ = NFEnv.mapScope(inEnv, isValidPackageElement);
      then
        ();

    // If the found element isn't encapsulated and the current scope doesn't
    // satisfy the requirements for a package, print an error.
    else
      equation
        (name, info) = SCode.elementNameInfo(inElement);
        env_str = NFEnv.printEnvPathStr(inEnv);
        Error.addSourceMessage(Error.NON_ENCAPSULATED_CLASS_ACCESS,
          {env_str, name}, info);
      then
        fail();
        
  end matchcontinue;
end checkPackageLikeAccess;
      
protected function isValidPackageElement
  "Helper function to checkPackageLikeAccess, checks that a given entry is a
   valid package element (a constant or class)."
  input Entry inEntry;
  output Entry outEntry;
protected
  SCode.Element el;
algorithm
  el := NFEnv.entryElement(inEntry);
  true := SCode.isValidPackageElement(el);
  outEntry := inEntry;
end isValidPackageElement;

protected function lookupSimpleName
  input String inName;
  input Env inEnv;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv) := lookupSimpleName_impl(inName, inEnv);
  (outEntry, outEnv) := NFEnv.resolveEntry(outEntry, outEnv);
end lookupSimpleName;

protected function lookupSimpleName_impl
  input String inName;
  input Env inEnv;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv) := matchcontinue(inName, inEnv)
    local
      Entry entry;
      Env env;

    // Check the local scope.
    case (_, _)
      equation
        entry = NFEnv.lookupEntry(inName, inEnv);
      then
        (entry, inEnv);
        
    // If not found in the local scope and the current frame isn't encapsulated,
    // check the next frame.
    case (_, _)
      equation
        false = NFEnv.isScopeEncapsulated(inEnv);
        env = NFEnv.exitScope(inEnv);
        (entry, env) = lookupSimpleName_impl(inName, env);
      then
        (entry, env);

    // If the current frame is encapsulated, check the builtin scope.
    else
      equation
        true = NFEnv.isScopeEncapsulated(inEnv);
        false = NFEnv.isBuiltinScope(inEnv);
        env = NFEnv.builtinScope(inEnv);
        (entry, env) = lookupSimpleName_impl(inName, env);
      then
        (entry, env);

  end matchcontinue;
end lookupSimpleName_impl;

protected function lookupFullyQualified
  input Absyn.Path inName;
  input Env inEnv;
  output Entry outEntry;
  output Env outEnv;
  output LookupState outState;
protected
  Env env;
algorithm
  env := NFEnv.topScope(inEnv);
  (outEntry, outEnv, outState) := lookupNameInPackage(inName, inEnv, STATE_BEGIN());
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
  (outEntry, outEnv) := NFEnv.resolveEntry(entry, inEnv);
end lookupInLocalScope;

protected function lookupNameInPackage
  input Absyn.Path inName;
  input Env inEnv;
  input LookupState inState;
  output Entry outEntry;
  output Env outEnv;
  output LookupState outState;
algorithm
  (outEntry, outEnv, outState) := match(inName, inEnv, inState)
    local
      String name;
      Absyn.Path path;
      Entry entry;
      Env env;
      LookupState state;

    case (Absyn.IDENT(name = name), _, _)
      equation
        (entry, env) = lookupInLocalScope(name, inEnv);
        state = nextState(entry, inState, inEnv);
      then
        (entry, env, state);

    case (Absyn.QUALIFIED(name = name, path = path), _, _)
      equation
        (entry, env) = lookupInLocalScope(name, inEnv);
        checkPartial(entry);
        state = nextState(entry, inState, inEnv);
        (entry, env, state) = lookupNameInEntry(path, entry, env, state);
      then
        (entry, env, state);

  end match;
end lookupNameInPackage;

protected function lookupNameInEntry
  input Absyn.Path inName;
  input Entry inEntry;
  input Env inEnv;
  input LookupState inState;
  output Entry outEntry;
  output Env outEnv;
  output LookupState outState;
algorithm
  (outEntry, outEnv, outState) := match(inName, inEntry, inEnv, inState)
    local
      Entry entry;
      Env env;
      LookupState state;

    case (_, _, _, _)
      equation
        env = enterEntryScope(inEntry, NFMod.emptyModTable, inEnv);
        (entry, env, state) = lookupNameInPackage(inName, env, inState);
      then
        (entry, env, state);

  end match;
end lookupNameInEntry;

public function isNameGlobal
  "Returns whether a simple name is global or not, as well as it's entry and
   environment. Global in this case means a name not defined in the local scope."
  input String inName;
  input Env inEnv;
  output Boolean outIsGlobal;
  output Entry outEntry;
  output Env outEnv;
protected
  Boolean is_local;
  Env env;
algorithm
  // Look up the name unresolved and check if it's a local name.
  (outEntry, env) := lookupSimpleName_impl(inName, inEnv);  
  outIsGlobal := not referenceEq(env, inEnv);
  // Then resolve the entry and check if it refers to a class.
  (outEntry, outEnv) := NFEnv.resolveEntry(outEntry, env);
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
  outEnv := NFEnv.openClassScope(name, ep, inEnv);
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
        env = populateEnvWithExtends(exts, inOrigins, inMods, env, env);
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
        env = NFEnv.openClassScope(bc_name, SCode.NOT_ENCAPSULATED(), inFoundEnv);
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
