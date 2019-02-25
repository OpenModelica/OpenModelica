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

encapsulated package NFLookupState

import Absyn;
import SCode;
import NFInstNode.InstNode;
import NFComponent.Component;

protected
import Dump;
import Error;
import System;
import NFClass.Class;

public
uniontype LookupStateName
  record PATH
    Absyn.Path path;
  end PATH;

  record CREF
    Absyn.ComponentRef cref;
  end CREF;

  function toString
    input LookupStateName name;
    output String str;
  algorithm
    str := match name
      case PATH() then Absyn.pathString(name.path);
      case CREF() then Dump.printComponentRefStr(name.cref);
    end match;
  end toString;

  function firstIdent
    input LookupStateName name;
    output String id;
  algorithm
    id := match name
      case PATH() then Absyn.pathFirstIdent(name.path);
      case CREF() then Absyn.crefFirstIdent(name.cref);
    end match;
  end firstIdent;

  function secondIdent
    input LookupStateName name;
    output String id;
  algorithm
    id := match name
      case PATH() then Absyn.pathSecondIdent(name.path);
      case CREF() then Absyn.crefSecondIdent(name.cref);
    end match;
  end secondIdent;
end LookupStateName;

uniontype LookupState

  "LookupState is used by the lookup to keep track of what state it's in so that
  the rules for composite name lookup can be enforced."
  record BEGIN "The start state." end BEGIN;
  record COMP "A component." end COMP;
  record COMP_COMP "A component found in component." end COMP_COMP;
  record COMP_CLASS "A class found in component." end COMP_CLASS;
  record COMP_FUNC "A function found in component." end COMP_FUNC;
  record PACKAGE "A package." end PACKAGE;
  record CLASS "A class." end CLASS;
  record FUNC "A function." end FUNC;
  record PREDEF_COMP "A predefined component." end PREDEF_COMP;
  record PREDEF_CLASS "A predefined class." end PREDEF_CLASS;
  record ERROR "An error occured during lookup."
    LookupState errorState;
  end ERROR;

  function assertClass
    input LookupState endState;
    input InstNode node;
    input Absyn.Path name;
    input SourceInfo info;
  algorithm
    assertState(endState, LookupState.CLASS(), node,
      LookupStateName.PATH(name), info);
  end assertClass;

  function assertFunction
    input LookupState endState;
    input InstNode node;
    input Absyn.ComponentRef name;
    input SourceInfo info;
  algorithm
    assertState(endState, LookupState.FUNC(), node,
      LookupStateName.CREF(name), info);
  end assertFunction;

  function assertComponent
    input LookupState endState;
    input InstNode node;
    input Absyn.ComponentRef name;
    input SourceInfo info;
  algorithm
    assertState(endState, LookupState.COMP(), node,
      LookupStateName.CREF(name), info);
  end assertComponent;

  function isCallableType
    input InstNode node;
    output Boolean callable;
  protected
    SCode.Element def = InstNode.definition(node);
  algorithm
    callable := SCode.isRecord(def) or SCode.isOperator(def);
  end isCallableType;

  function isCallableComponent
    input InstNode node;
    output Boolean callable;
  algorithm
    callable := Class.isFunction(InstNode.getClass(node));
  end isCallableComponent;

  function isFunction
    input LookupState state;
    input InstNode node;
    output Boolean isFunction;
  algorithm
    isFunction := match state
      case FUNC() then true;
      case COMP_FUNC() then true;
      case CLASS() then isCallableType(node);
      case COMP() then isCallableComponent(node);
      case COMP_COMP() then isCallableComponent(node);
      else false;
    end match;
  end isFunction;

  function isClass
    input LookupState state;
    output Boolean isClass;
  algorithm
    isClass := match state
      case COMP_CLASS() then true;
      case CLASS() then true;
      case PREDEF_CLASS() then true;
      else false;
    end match;
  end isClass;

  function assertState
    input LookupState endState;
    input LookupState expectedState;
    input InstNode node;
    input LookupStateName name;
    input SourceInfo info;
  algorithm
    () := match (endState, expectedState)
      local
        String name_str;
        SourceInfo info2;

      // Found the expected kind of element.
      case (COMP(),         COMP())  then ();
      case (COMP_COMP(),    COMP())  then ();
      case (PREDEF_COMP(),  COMP())  then ();
      case (FUNC(),         COMP())  then ();
      case (COMP_FUNC(),    COMP())  then ();
      case (PACKAGE(),      CLASS()) then ();
      case (CLASS(),        CLASS()) then ();
      case (PREDEF_CLASS(), CLASS()) then ();
      case (FUNC(),         CLASS()) then ();
      case (FUNC(),         FUNC())  then ();
      case (COMP_FUNC(),    FUNC())  then ();

      case (CLASS(), FUNC())     guard isCallableType(node) then ();
      case (COMP(),  FUNC())     guard isCallableComponent(node) then ();
      case (COMP_COMP(), FUNC()) guard isCallableComponent(node) then ();

      // Found a class via a component, but expected a function.
      case (COMP_CLASS(), FUNC())
        algorithm
          printFoundWrongTypeError(endState, expectedState, name, info);
        then
          fail();

      // Found a function via a component, but didn't expect a function.
      case (COMP_FUNC(), _)
        algorithm
          name_str := LookupStateName.toString(name);
          Error.addSourceMessage(Error.FOUND_FUNC_NAME_VIA_COMP_NONCALL, {name_str}, info);
        then
          fail();

      // Found a class via a component. Only components and functions are
      // allowed to be lookup up via a component.
      case (COMP_CLASS(), _)
        algorithm
          Error.addSourceMessage(Error.FOUND_CLASS_NAME_VIA_COMPONENT,
            {LookupStateName.toString(name)}, info);
        then
          fail();

      // Invalid form when looking for a function via a component, only
      // c.C1...Cn.f is allowed.
      case (ERROR(errorState = COMP_FUNC()), FUNC())
        algorithm
          name_str := InstNode.name(node);
          info2 := InstNode.info(node);
          Error.addSourceMessage(Error.NON_CLASS_IN_COMP_FUNC_NAME, {name_str}, info2);
        then
          fail();

      // Found class when looking up a composite component name.
      case (ERROR(errorState = COMP_FUNC()), COMP())
        algorithm
          name_str := InstNode.name(node);
          Error.addSourceMessage(Error.CLASS_IN_COMPOSITE_COMP_NAME,
            {name_str, LookupStateName.toString(name)}, info);
        then
          fail();

      // Found class via composite component name when actually looking for a class.
      case (ERROR(errorState = COMP_FUNC()), _)
        algorithm
          name_str := InstNode.name(node);
          Error.addSourceMessage(Error.LOOKUP_CLASS_VIA_COMP_COMP,
            {name_str, LookupStateName.toString(name)}, info);
        then
          fail();

      // Found class when looking up a composite component name.
      case (ERROR(errorState = COMP_COMP()), COMP())
        algorithm
          name_str := InstNode.name(node);
          Error.addSourceMessage(Error.CLASS_IN_COMPOSITE_COMP_NAME,
            {name_str, LookupStateName.toString(name)}, info);
        then
          fail();

      // Found class via composite component name when actually looking for a class.
      case (ERROR(errorState = COMP_COMP()), _)
        algorithm
          name_str := InstNode.name(node);
          Error.addSourceMessage(Error.LOOKUP_CLASS_VIA_COMP_COMP,
            {name_str, LookupStateName.toString(name)}, info);
        then
          fail();

      // Found the wrong kind of element.
      else
        algorithm
          printFoundWrongTypeError(endState, expectedState, name, info);
        then
          fail();

    end match;
  end assertState;

  function isError
    input LookupState state;
    output Boolean isError;
  algorithm
    isError := match state
      case ERROR() then true;
      else false;
    end match;
  end isError;

  function lookupStateString
    "Returns the string representation of a LookupState, with translation."
    input LookupState state;
    output String str;
  algorithm
    str := match(state)
      case BEGIN() then "<begin>";
      case COMP() then System.gettext("component");
      case COMP_COMP() then System.gettext("component");
      case COMP_CLASS() then System.gettext("class");
      case COMP_FUNC() then System.gettext("function");
      case PACKAGE() then System.gettext("package");
      case CLASS() then System.gettext("class");
      case FUNC() then System.gettext("function");
      case PREDEF_COMP() then System.gettext("component");
      case PREDEF_CLASS() then System.gettext("class");
    end match;
  end lookupStateString;

  function printFoundWrongTypeError
    "Helper function to assertState, prints out an error when the wrong kind
     of element was found."
    input LookupState foundState;
    input LookupState expectedState;
    input LookupStateName name;
    input SourceInfo info;
  protected
    String name_str, found_str, expected_str;
  algorithm
    name_str := LookupStateName.toString(name);
    found_str := lookupStateString(foundState);
    expected_str := lookupStateString(expectedState);
    Error.addSourceMessage(Error.LOOKUP_FOUND_WRONG_TYPE,
      {name_str, expected_str, found_str}, info);
  end printFoundWrongTypeError;

  function next
    "Checks that the found name is allowed to be looked up given the current state
     of the name lookup, and returns the new state if it is. Otherwise it will
     print a (hopefully relevant) error message and fail."
    input InstNode node;
    input LookupState currentState;
    input Boolean checkAccessViolations = true;
    output LookupState nextState;
  protected
    LookupState entry_ty;
    SCode.Element el;
  algorithm
    if checkAccessViolations then
      // Check that the element is allowed to be accessed given its visibility.
      checkProtection(node, currentState);
      // Check that we're allowed to look in the current scope.
      //checkPackageLikeAccess(inCurrentState, el, inEnv);
    end if;

    // Get the state for the found element, and check that the transition to the
    // new state is valid.
    entry_ty := nodeState(node);
    nextState := next2(entry_ty, currentState, node);
  end next;

  function checkProtection
    "Checks if a found element is protected during lookup, and prints an error if
     the element was not the first part of a name while being protected.
     I.e. P.a is allowed if P is protected, but not e.g. a.P or a.P.b."
    input InstNode node;
    input LookupState currentState;
  algorithm
    () := match currentState
      // The first part of a name is allowed to be protected, it's only
      // accessing a protected element via dot-notation that's illegal.
      case BEGIN() then ();

      else
        algorithm
          // A protected element generates an error.
          if InstNode.isProtected(node) then
            Error.addSourceMessage(Error.PROTECTED_ACCESS,
              {InstNode.name(node)}, InstNode.info(node));
            fail();
          end if;
        then
          ();

    end match;
  end checkProtection;

  function nodeState
    input InstNode node;
    output LookupState state;
  algorithm
    if InstNode.isComponent(node) or InstNode.isName(node) then
      state := COMP();
    else
      state := elementState(InstNode.definition(node));
    end if;
  end nodeState;

  function elementState
    "Returns the lookup state of a given element."
    input SCode.Element element;
    output LookupState state;
  algorithm
    state := match element
      case SCode.CLASS(restriction = SCode.R_PACKAGE()) then PACKAGE();
      case SCode.CLASS(restriction = SCode.R_FUNCTION()) then FUNC();
      case SCode.CLASS() then CLASS();
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown element.", sourceInfo());
        then
          fail();
    end match;
  end elementState;

  function next2
   "This function implements the state machine that checks which transitions are
    valid during composite name lookup, as defined in section 5.3.2 of the
    specification. elementState is expected to be one of COMP,
    CLASS, FUNC or PACKAGE, indicating what type the found
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

    There's also PREDEF_COMP and PREDEF_CLASS for the predefined types
    and components, e.g. Real, time, etc., which are handled as special cases in
    lookupName and bypasses this state machine.
    "
    input LookupState elementState;
    input LookupState currentState;
    input InstNode node;
    output LookupState nextState;
  algorithm
    nextState := match (elementState, currentState)
      local
        String str;

      // Transitions from BEGIN.
      case (_,         BEGIN())      then elementState;

      // Transitions from COMP.
      case (COMP(),    COMP())       then COMP_COMP();
      case (FUNC(),    COMP())       then COMP_FUNC();
      case (_,         COMP())       then COMP_CLASS();

      // Transitions from COMP_COMP.
      case (COMP(),    COMP_COMP())  then COMP_COMP();

      // Transitions from PACKAGE.
      case (COMP(),    PACKAGE())    then COMP_COMP();
      case (_,         PACKAGE())    then elementState;

      // Transitions from CLASS/FUNC.
      // next has already checked that the found element is encapsulated or
      // the class/func looks like a package, so any transition is fine here.
      case (COMP(),    CLASS())      then COMP_COMP();
      case (_,         CLASS())      then elementState;
      case (COMP(),    FUNC())       then COMP_COMP();
      case (_,         FUNC())       then elementState;

      // Transitions from COMP_CLASS.
      case (FUNC(),    COMP_CLASS()) then COMP_FUNC();
      case (CLASS(),   COMP_CLASS()) then COMP_CLASS();
      case (PACKAGE(), COMP_CLASS()) then COMP_CLASS();

      // Transitions from COMP_FUNC.
      case (FUNC(),    COMP_FUNC())  then COMP_FUNC();
      case (CLASS(),   COMP_FUNC())  then COMP_CLASS();
      case (PACKAGE(), COMP_FUNC())  then COMP_CLASS();

      // When looking for a function in a component the only valid form is
      // c.M1..Mn.f, where M1..Mn are classes, but we found a component instead.
      case (COMP(), _)
        then ERROR(COMP_FUNC());

      // We found a class when only components are allowed, i.e. when not looking
      // for a function via a component.
      case (_,         COMP_COMP())
        then ERROR(COMP_COMP());

      else
        algorithm
          Error.assertion(false, getInstanceName() + " failed on unknown transition for element " + InstNode.name(node), sourceInfo());
        then
          fail();

    end match;
  end next2;

  //function checkPackageLikeAccess
  //  "Checks that the found is element is allowed to be looked up in the current
  //   scope. In particular it checks that only encapsulated elements are allowed to
  //   be looked up in classes which does not satisfy the requirements for a package."
  //  input LookupState inCurrentState;
  //  input SCode.Element inElement;
  //  input Env inEnv;
  //algorithm
  //  () := matchcontinue(inCurrentState, inElement, inEnv)
  //    local
  //      String name, env_str;
  //      SourceInfo info;

  //    // Nothing to check in packages or components.
  //    case (BEGIN(), _, _) then ();
  //    case (PACKAGE(), _, _) then ();
  //    case (COMP(), _, _) then ();
  //    case (COMP_COMP(), _, _) then ();

  //    // Check if the found element is encapsulated, then it's ok to look it up in
  //    // a non-package.
  //    case (_, _, _)
  //      equation
  //        true = SCode.isElementEncapsulated(inElement);
  //      then
  //        ();

  //    // If the found element is not encapsulated, check if the current scope
  //    // satisfies the requirements for a package, i.e. only contains classes and
  //    // constants.
  //    case (_, _, _)
  //      equation
  //        _ = NFEnv.mapScope(inEnv, isValidPackageElement);
  //      then
  //        ();

  //    // If the found element isn't encapsulated and the current scope doesn't
  //    // satisfy the requirements for a package, print an error.
  //    else
  //      equation
  //        (name, info) = SCode.elementNameInfo(inElement);
  //        env_str = NFEnv.printEnvPathStr(inEnv);
  //        Error.addSourceMessage(Error.NON_ENCAPSULATED_CLASS_ACCESS,
  //          {env_str, name}, info);
  //      then
  //        fail();

  //  end matchcontinue;
  //end checkPackageLikeAccess;

  //function isValidPackageElement
  //  "Helper function to checkPackageLikeAccess, checks that a given entry is a
  //   valid package element (a constant or class)."
  //  input Entry inEntry;
  //  output Entry outEntry;
  //protected
  //  SCode.Element el;
  //algorithm
  //  /* TODO: A component might be a constant due to a class prefix. */
  //  /* TODO: Return the found invalid element to improve the error message. */
  //  el := NFEnv.entryElement(inEntry);
  //  true := SCode.isValidPackageElement(el);
  //  outEntry := inEntry;
  //end isValidPackageElement;
end LookupState;

annotation(__OpenModelica_Interface="frontend");
end NFLookupState;
