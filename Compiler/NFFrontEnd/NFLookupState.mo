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

protected
import Dump;
import Error;
import System;

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
  record STATE_BEGIN "The start state." end STATE_BEGIN;
  record STATE_COMP "A component." end STATE_COMP;
  record STATE_COMP_COMP "A component found in component." end STATE_COMP_COMP;
  record STATE_COMP_CLASS "A class found in component." end STATE_COMP_CLASS;
  record STATE_COMP_FUNC "A function found in component." end STATE_COMP_FUNC;
  record STATE_PACKAGE "A package." end STATE_PACKAGE;
  record STATE_CLASS "A class." end STATE_CLASS;
  record STATE_FUNC "A function." end STATE_FUNC;
  record STATE_PREDEF_COMP "A predefined component." end STATE_PREDEF_COMP;
  record STATE_PREDEF_CLASS "A predefined class." end STATE_PREDEF_CLASS;
  record STATE_ERROR "An error occured during lookup."
    LookupState errorState;
  end STATE_ERROR;

  function assertClass
    input LookupState endState;
    input InstNode node;
    input Absyn.Path name;
    input SourceInfo info;
  algorithm
    assertState(endState, LookupState.STATE_CLASS(), node,
      LookupStateName.PATH(name), info);
  end assertClass;

  function assertFunction
    input LookupState endState;
    input InstNode node;
    input Absyn.ComponentRef name;
    input SourceInfo info;
  algorithm
    assertState(endState, LookupState.STATE_FUNC(), node,
      LookupStateName.CREF(name), info);
  end assertFunction;

  function assertComponent
    input LookupState endState;
    input InstNode node;
    input Absyn.ComponentRef name;
    input SourceInfo info;
  algorithm
    assertState(endState, LookupState.STATE_COMP(), node,
      LookupStateName.CREF(name), info);
  end assertComponent;

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
      case (STATE_COMP(),         STATE_COMP()) then ();
      case (STATE_COMP_COMP(),    STATE_COMP()) then ();
      case (STATE_PREDEF_COMP(),  STATE_COMP()) then ();
      case (STATE_PACKAGE(),      STATE_CLASS()) then ();
      case (STATE_CLASS(),        STATE_CLASS()) then ();
      case (STATE_PREDEF_CLASS(), STATE_CLASS()) then ();
      case (STATE_FUNC(),         STATE_CLASS()) then ();
      case (STATE_FUNC(),         STATE_FUNC()) then ();
      case (STATE_COMP_FUNC(),    STATE_FUNC()) then ();

      // Found a class via a component, but expected a function.
      case (STATE_COMP_CLASS(), STATE_FUNC())
        algorithm
          printFoundWrongTypeError(endState, expectedState, name, info);
        then
          fail();

      // Found a function via a component, but didn't expect a function.
      case (STATE_COMP_FUNC(), _)
        algorithm
          name_str := LookupStateName.toString(name);
          Error.addSourceMessage(Error.FOUND_FUNC_NAME_VIA_COMP_NONCALL, {name_str}, info);
        then
          fail();

      // Found a class via a component. Only components and functions are
      // allowed to be lookup up via a component.
      case (STATE_COMP_CLASS(), _)
        algorithm
          Error.addSourceMessage(Error.FOUND_CLASS_NAME_VIA_COMPONENT,
            {LookupStateName.toString(name)}, info);
        then
          fail();

      // Invalid form when looking for a function via a component, only
      // c.C1...Cn.f is allowed.
      case (STATE_ERROR(errorState = STATE_COMP_FUNC()), STATE_FUNC())
        algorithm
          name_str := InstNode.name(node);
          info2 := InstNode.info(node);
          Error.addSourceMessage(Error.NON_CLASS_IN_COMP_FUNC_NAME, {name_str}, info2);
        then
          fail();

      // Found class when looking up a composite component name.
      case (STATE_ERROR(errorState = STATE_COMP_FUNC()), STATE_COMP())
        algorithm
          name_str := InstNode.name(node);
          Error.addSourceMessage(Error.CLASS_IN_COMPOSITE_COMP_NAME,
            {name_str, LookupStateName.toString(name)}, info);
        then
          fail();

      // Found class via composite component name when actually looking for a class.
      case (STATE_ERROR(errorState = STATE_COMP_FUNC()), _)
        algorithm
          name_str := InstNode.name(node);
          Error.addSourceMessage(Error.LOOKUP_CLASS_VIA_COMP_COMP,
            {name_str, LookupStateName.toString(name)}, info);
        then
          fail();

      // Found class when looking up a composite component name.
      case (STATE_ERROR(errorState = STATE_COMP_COMP()), STATE_COMP())
        algorithm
          name_str := InstNode.name(node);
          Error.addSourceMessage(Error.CLASS_IN_COMPOSITE_COMP_NAME,
            {name_str, LookupStateName.toString(name)}, info);
        then
          fail();

      // Found class via composite component name when actually looking for a class.
      case (STATE_ERROR(errorState = STATE_COMP_COMP()), _)
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
      case STATE_ERROR() then true;
      else false;
    end match;
  end isError;

  function lookupStateString
    "Returns the string representation of a LookupState, with translation."
    input LookupState state;
    output String str;
  algorithm
    str := match(state)
      case STATE_BEGIN() then "<begin>";
      case STATE_COMP() then System.gettext("component");
      case STATE_COMP_COMP() then System.gettext("component");
      case STATE_COMP_CLASS() then System.gettext("class");
      case STATE_COMP_FUNC() then System.gettext("function");
      case STATE_PACKAGE() then System.gettext("package");
      case STATE_CLASS() then System.gettext("class");
      case STATE_FUNC() then System.gettext("function");
      case STATE_PREDEF_COMP() then System.gettext("component");
      case STATE_PREDEF_CLASS() then System.gettext("class");
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
    output LookupState nextState;
  protected
    LookupState entry_ty;
    SCode.Element el;
  algorithm
    el := InstNode.definition(node);
    // Check that the element is allowed to be accessed given its visibility.
    checkProtection(el, currentState);
    // Check that we're allowed to look in the current scope.
    //checkPackageLikeAccess(inCurrentState, el, inEnv);
    // Get the state for the found element, and check that the transition to the
    // new state is valid.
    entry_ty := elementState(el);
    nextState := next2(entry_ty, currentState, el);
  end next;

  function checkProtection
    "Checks if a found element is protected during lookup, and prints an error if
     the element was not the first part of a name while being protected.
     I.e. P.a is allowed if P is protected, but not e.g. a.P or a.P.b."
    input SCode.Element element;
    input LookupState currentState;
  algorithm
    () := match currentState
      local
        String name;
        SourceInfo info;

      // The first part of a name is allowed to be protected, it's only
      // accessing a protected element via dot-notation that's illegal.
      case STATE_BEGIN() then ();

      else
        algorithm
          // A protected element generates an error.
          if SCode.isElementProtected(element) then
            (name, info) := SCode.elementNameInfo(element);
            Error.addSourceMessage(Error.PROTECTED_ACCESS, {name}, info);
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
    state := elementState(InstNode.definition(node));
  end nodeState;

  function elementState
    "Returns the lookup state of a given element."
    input SCode.Element element;
    output LookupState state;
  algorithm
    state := match element
      case SCode.COMPONENT() then STATE_COMP();
      case SCode.CLASS(restriction = SCode.R_PACKAGE()) then STATE_PACKAGE();
      case SCode.CLASS(restriction = SCode.R_FUNCTION()) then STATE_FUNC();
      case SCode.CLASS() then STATE_CLASS();
    end match;
  end elementState;

  function next2
   "This function implements the state machine that checks which transitions are
    valid during composite name lookup, as defined in section 5.3.2 of the
    specification. elementState is expected to be one of STATE_COMP,
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

    There's also STATE_PREDEF_COMP and STATE_PREDEF_CLASS for the predefined types
    and components, e.g. Real, time, etc., which are handled as special cases in
    lookupName and bypasses this state machine.
    "
    input LookupState elementState;
    input LookupState currentState;
    input SCode.Element element;
    output LookupState nextState;
  algorithm
    nextState := match (elementState, currentState)
      local
        String str;

      // Transitions from BEGIN.
      case (_,               STATE_BEGIN())      then elementState;

      // Transitions from COMP.
      case (STATE_COMP(),    STATE_COMP())       then STATE_COMP_COMP();
      case (STATE_FUNC(),    STATE_COMP())       then STATE_COMP_FUNC();
      case (_,               STATE_COMP())       then STATE_COMP_CLASS();

      // Transitions from COMP_COMP.
      case (STATE_COMP(),    STATE_COMP_COMP())  then STATE_COMP_COMP();

      // Transitions from PACKAGE.
      case (STATE_COMP(),    STATE_PACKAGE())    then STATE_COMP_COMP();
      case (_,               STATE_PACKAGE())    then elementState;

      // Transitions from CLASS/FUNC.
      // next has already checked that the found element is encapsulated or
      // the class/func looks like a package, so any transition is fine here.
      case (STATE_COMP(),    STATE_CLASS())      then STATE_COMP_COMP();
      case (_,               STATE_CLASS())      then elementState;
      case (STATE_COMP(),    STATE_FUNC())       then STATE_COMP_COMP();
      case (_,               STATE_FUNC())       then elementState;

      // Transitions from COMP_CLASS.
      case (STATE_FUNC(),    STATE_COMP_CLASS()) then STATE_COMP_FUNC();
      case (STATE_CLASS(),   STATE_COMP_CLASS()) then STATE_COMP_CLASS();
      case (STATE_PACKAGE(), STATE_COMP_CLASS()) then STATE_COMP_CLASS();

      // Transitions from COMP_FUNC.
      case (STATE_FUNC(),    STATE_COMP_FUNC())  then STATE_COMP_FUNC();
      case (STATE_CLASS(),   STATE_COMP_FUNC())  then STATE_COMP_CLASS();
      case (STATE_PACKAGE(), STATE_COMP_FUNC())  then STATE_COMP_CLASS();

      // When looking for a function in a component the only valid form is
      // c.M1..Mn.f, where M1..Mn are classes, but we found a component instead.
      case (STATE_COMP(), _)
        then STATE_ERROR(STATE_COMP_FUNC());

      // We found a class when only components are allowed, i.e. when not looking
      // for a function via a component.
      case (_,               STATE_COMP_COMP())
        then STATE_ERROR(STATE_COMP_COMP());

      else
        algorithm
          assert(false, getInstanceName() + " failed on unknown transition for element "
            + SCode.elementName(element));
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
  //    case (STATE_BEGIN(), _, _) then ();
  //    case (STATE_PACKAGE(), _, _) then ();
  //    case (STATE_COMP(), _, _) then ();
  //    case (STATE_COMP_COMP(), _, _) then ();

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
