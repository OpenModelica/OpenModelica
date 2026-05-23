/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package ClassInfUtil
" file:        ClassInfUtil.mo
  package:     ClassInfUtil
  description: Class restrictions


  This module deals with class inference, i.e. determining if a
  class definition adhers to one of the class restrictions, and, if
  specifically declared in a restrictied form, if it breaks that
  restriction.

  The inference is implemented as a finite state machine.  The
  function `start\' initializes a new machine, and the function
  `trans\' signals transitions in the machine.  Finally, the state
  can be checked agains a restriction with the `valid\' function. "


import Absyn;
import ClassInf;
import SCode;

protected import Config;
protected import Debug;
protected import Error;
protected import Flags;
protected import Print;
protected import SCodeDump;
protected import SCodeUtil;

public function printStateStr "- Printing

  Some functions for printing error and debug information about the
  state machine.

  The code is excluded from the report.
"
  input ClassInf.State inState;
  output String outString;
algorithm
  outString:=
  match (inState)
    local
      Absyn.Path p;
      Boolean b1,b2,b3;
    case ClassInf.UNKNOWN() then "unknown";
    case ClassInf.OPTIMIZATION() then "optimization";
    case ClassInf.MODEL() then "model";
    case ClassInf.RECORD() then "record";
    case ClassInf.BLOCK() then "block";
    case ClassInf.CONNECTOR() then "connector";
    case ClassInf.TYPE() then "type";
    case ClassInf.PACKAGE() then "package";
    case ClassInf.FUNCTION(isImpure = true) then "impure function";
    case ClassInf.FUNCTION() then "function";
    case ClassInf.TYPE_INTEGER() then "Integer";
    case ClassInf.TYPE_REAL() then "Real";
    case ClassInf.TYPE_STRING() then "String";
    case ClassInf.TYPE_BOOL() then "Boolean";
    // BTH
    case ClassInf.TYPE_CLOCK() then "Clock";
    case ClassInf.HAS_RESTRICTIONS(hasEquations = false, hasAlgorithms = false, hasConstraints = false) then "new def";
    case ClassInf.HAS_RESTRICTIONS(hasEquations = b1, hasAlgorithms = b2)
      then "has" + (if b1 then " equations" else "") + (if b2 then " algorithms" else "") + (if b1 then " constraints" else "");
    case ClassInf.EXTERNAL_OBJ() then "ExternalObject";
    case ClassInf.META_TUPLE() then "tuple";
    case ClassInf.META_LIST() then "list";
    case ClassInf.META_OPTION() then "Option";
    case ClassInf.META_RECORD() then "meta_record";
    case ClassInf.META_POLYMORPHIC() then "polymorphic";
    case ClassInf.META_ARRAY() then "meta_array";
    case ClassInf.META_UNIONTYPE() then "uniontype";
    else "#printStateStr failed#";
  end match;
end printStateStr;

public function printState
  input ClassInf.State inState;
algorithm
  _:=
  match (inState)
    local Absyn.Path p;

    case ClassInf.UNKNOWN(path = p)
      algorithm
        Print.printBuf("UNKNOWN ");
        Print.printBuf(AbsynUtil.pathString(p));
      then
        ();
    case ClassInf.OPTIMIZATION(path = p)
      algorithm
        Print.printBuf("OPTIMIZATION ");
        Print.printBuf(AbsynUtil.pathString(p));
      then
        ();
    case ClassInf.MODEL(path = p)
      algorithm
        Print.printBuf("MODEL ");
        Print.printBuf(AbsynUtil.pathString(p));
      then
        ();
    case ClassInf.RECORD(path = p)
      algorithm
        Print.printBuf("RECORD ");
        Print.printBuf(AbsynUtil.pathString(p));
      then
        ();
    case ClassInf.BLOCK(path = p)
      algorithm
        Print.printBuf("BLOCK ");
        Print.printBuf(AbsynUtil.pathString(p));
      then
        ();
    case ClassInf.CONNECTOR(path = p)
      algorithm
        Print.printBuf("CONNECTOR ");
        Print.printBuf(AbsynUtil.pathString(p));
      then
        ();
    case ClassInf.TYPE(path = p)
      algorithm
        Print.printBuf("TYPE ");
        Print.printBuf(AbsynUtil.pathString(p));
      then
        ();
    case ClassInf.PACKAGE(path = p)
      algorithm
        Print.printBuf("PACKAGE ");
        Print.printBuf(AbsynUtil.pathString(p));
      then
        ();
    case ClassInf.FUNCTION(path = p, isImpure = true)
      algorithm
        Print.printBuf("IMPURE FUNCTION ");
        Print.printBuf(AbsynUtil.pathString(p));
      then
        ();
    case ClassInf.FUNCTION(path = p)
      algorithm
        Print.printBuf("FUNCTION ");
        Print.printBuf(AbsynUtil.pathString(p));
      then
        ();
    case ClassInf.TYPE_INTEGER(path = p)
      algorithm
        Print.printBuf("TYPE_INTEGER ");
        Print.printBuf(AbsynUtil.pathString(p));
      then
        ();
    case ClassInf.TYPE_REAL(path = p)
      algorithm
        Print.printBuf("TYPE_REAL ");
        Print.printBuf(AbsynUtil.pathString(p));
      then
        ();
    case ClassInf.TYPE_STRING(path = p)
      algorithm
        Print.printBuf("TYPE_STRING ");
        Print.printBuf(AbsynUtil.pathString(p));
      then
        ();
    case ClassInf.TYPE_BOOL(path = p)
      algorithm
        Print.printBuf("TYPE_BOOL ");
        Print.printBuf(AbsynUtil.pathString(p));
      then
        ();
    // BTH
    case ClassInf.TYPE_CLOCK(path = p)
      algorithm
        Print.printBuf("TYPE_CLOCK ");
        Print.printBuf(AbsynUtil.pathString(p));
      then
        ();
    case ClassInf.HAS_RESTRICTIONS(path = p)
      algorithm
        Print.printBuf("HAS_RESTRICTIONS ");
        Print.printBuf(AbsynUtil.pathString(p));
        Print.printBuf(printStateStr(inState));
      then ();
  end match;
end printState;

public function getStateName "Returns the classname of the state."
  input ClassInf.State inState;
  output Absyn.Path outPath;
algorithm
  outPath := match (inState)
    local
      Absyn.Path p;
    case ClassInf.UNKNOWN(path = p) then p;
    case ClassInf.OPTIMIZATION(path = p) then p;
    case ClassInf.MODEL(path = p) then p;
    case ClassInf.RECORD(path = p) then p;
    case ClassInf.BLOCK(path = p) then p;
    case ClassInf.CONNECTOR(path = p) then p;
    case ClassInf.TYPE(path = p) then p;
    case ClassInf.PACKAGE(path = p) then p;
    case ClassInf.FUNCTION(path = p) then p;
    case ClassInf.ENUMERATION(path = p) then p;
    case ClassInf.HAS_RESTRICTIONS(path = p) then p;
    case ClassInf.TYPE_INTEGER(path = p) then p;
    case ClassInf.TYPE_REAL(path = p) then p;
    case ClassInf.TYPE_STRING(path = p) then p;
    case ClassInf.TYPE_BOOL(path = p) then p;
    // BTH
    case ClassInf.TYPE_CLOCK(path = p) then p;
    case ClassInf.TYPE_ENUM(path = p) then p;

    case ClassInf.EXTERNAL_OBJ(p) then p;

    case ClassInf.META_TUPLE(p) then p;
    case ClassInf.META_LIST(p) then p;
    case ClassInf.META_OPTION(p) then p;
    case ClassInf.META_RECORD(p) then p;
    case ClassInf.META_UNIONTYPE(p) then p;
    case ClassInf.META_ARRAY(p) then p;
    case ClassInf.META_POLYMORPHIC(p) then p;

    else Absyn.IDENT("#getStateName failed#");
  end match;
end getStateName;

protected function printEventStr
  input ClassInf.Event inEvent;
  output String str;
algorithm
  str := match (inEvent)
    local
      String name;
    case ClassInf.FOUND_EQUATION() then "equation";
    case ClassInf.FOUND_CONSTRAINT() then "constraint";
    case ClassInf.NEWDEF() then "new definition";
    case ClassInf.FOUND_COMPONENT(name) then "component " + name;
    case ClassInf.FOUND_EXT_DECL() then "external function declaration";
    else "Unknown event";
  end match;
end printEventStr;

public function start "
  This is the state machine initialization function."
  input SCode.Restriction inRestriction;
  input Absyn.Path inPath;
  output ClassInf.State outState;
algorithm
  outState := start_dispatch(inRestriction, AbsynUtil.makeFullyQualified(inPath));
end start;

// Transitions
protected function start_dispatch "
  This is the state machine initialization function."
  input SCode.Restriction inRestriction;
  input Absyn.Path inPath;
  output ClassInf.State outState;
algorithm
  outState:=
  match (inRestriction,inPath)
    local Absyn.Path p; Boolean isExpandable, isImpure;
    case (SCode.R_CLASS(),p) then ClassInf.UNKNOWN(p);
    case (SCode.R_OPTIMIZATION(),p) then ClassInf.OPTIMIZATION(p);
    case (SCode.R_MODEL(),p) then ClassInf.MODEL(p);
    case (SCode.R_RECORD(_),p) then ClassInf.RECORD(p);
    case (SCode.R_BLOCK(),p) then ClassInf.BLOCK(p);
    case (SCode.R_CONNECTOR(isExpandable),p) then ClassInf.CONNECTOR(p,isExpandable);
    case (SCode.R_TYPE(),p) then ClassInf.TYPE(p);
    case (SCode.R_PACKAGE(),p) then ClassInf.PACKAGE(p);
    case (SCode.R_FUNCTION(),p) then ClassInf.FUNCTION(p, SCodeUtil.isRestrictionImpure(inRestriction, true));
    case (SCode.R_OPERATOR(),p) then ClassInf.FUNCTION(p, false);
    case (SCode.R_ENUMERATION(),p) then ClassInf.ENUMERATION(p);
    case (SCode.R_PREDEFINED_INTEGER(),p) then ClassInf.TYPE_INTEGER(p);
    case (SCode.R_PREDEFINED_REAL(),p) then ClassInf.TYPE_REAL(p);
    case (SCode.R_PREDEFINED_STRING(),p) then ClassInf.TYPE_STRING(p);
    case (SCode.R_PREDEFINED_BOOLEAN(),p) then ClassInf.TYPE_BOOL(p);
    // BTH
    case (SCode.R_PREDEFINED_CLOCK(),p)
      algorithm
        true := Config.synchronousFeaturesAllowed();
      then ClassInf.TYPE_CLOCK(p);
    case (SCode.R_PREDEFINED_ENUMERATION(),p) then ClassInf.TYPE_ENUM(p);
     /* Meta Modelica extensions */
    case (SCode.R_UNIONTYPE(),p) then ClassInf.META_UNIONTYPE(p, inRestriction.typeVars);
    case (SCode.R_METARECORD(),p) then ClassInf.META_RECORD(p);
  end match;
end start_dispatch;

public function trans "
  This is the state machine transition function.  It describes the
  transitions between states at different events.
"
  input ClassInf.State inState;
  input ClassInf.Event inEvent;
  output ClassInf.State outState;
algorithm
  outState := match (inState,inEvent)
    local
      Absyn.Path p;
      ClassInf.State st;
      ClassInf.Event ev;
      Boolean isExpandable,b,b1,b2,b3,isImpure;
      String s;
      list<String> msg;
    case (ClassInf.UNKNOWN(path = p),ClassInf.NEWDEF()) then ClassInf.HAS_RESTRICTIONS(p,false,false,false);  /* Event `NEWDEF\' */
    case (ClassInf.OPTIMIZATION(),ClassInf.NEWDEF()) then inState;
    case (ClassInf.MODEL(),ClassInf.NEWDEF()) then inState;
    case (ClassInf.RECORD(),ClassInf.NEWDEF()) then inState;
    case (ClassInf.BLOCK(),ClassInf.NEWDEF()) then inState;
    case (ClassInf.CONNECTOR(),ClassInf.NEWDEF()) then inState;
    case (ClassInf.TYPE(path = p),ClassInf.NEWDEF()) then ClassInf.TYPE(p); // A type can be constructed with long definition
    case (ClassInf.PACKAGE(path = p),ClassInf.NEWDEF()) then ClassInf.PACKAGE(p);
    case (ClassInf.FUNCTION(),ClassInf.NEWDEF()) then inState;
    case (ClassInf.ENUMERATION(),ClassInf.NEWDEF()) then inState;
    case (ClassInf.TYPE_INTEGER(),ClassInf.NEWDEF()) then inState;
    case (ClassInf.TYPE_REAL(),ClassInf.NEWDEF()) then inState;
    case (ClassInf.TYPE_STRING(),ClassInf.NEWDEF()) then inState;
    case (ClassInf.TYPE_BOOL(),ClassInf.NEWDEF()) then inState;
    // BTH
    case (ClassInf.TYPE_CLOCK(),ClassInf.NEWDEF()) then inState;
    case (ClassInf.TYPE_ENUM(),ClassInf.NEWDEF()) then inState;
    case (ClassInf.META_UNIONTYPE(),ClassInf.NEWDEF()) then inState;  // Added 2009-05-11. sjoelund
    case (ClassInf.META_RECORD(),ClassInf.NEWDEF()) then inState;  // Added 2009-08-18. sjoelund

   /* Event 'FOUND_COMPONENT' */
    case (ClassInf.UNKNOWN(path = p),ClassInf.FOUND_COMPONENT()) then ClassInf.HAS_RESTRICTIONS(p,false,false,false);  /* Event `NEWDEF\' */
    case (ClassInf.OPTIMIZATION(),ClassInf.FOUND_COMPONENT()) then inState;
    case (ClassInf.MODEL(),ClassInf.FOUND_COMPONENT()) then inState;
    case (ClassInf.RECORD(),ClassInf.FOUND_COMPONENT()) then inState;
    case (ClassInf.BLOCK(),ClassInf.FOUND_COMPONENT()) then inState;
    case (ClassInf.CONNECTOR(),ClassInf.FOUND_COMPONENT()) then inState;
    case (ClassInf.TYPE(path = p),ClassInf.FOUND_COMPONENT(name = s)) // A type can not contain new components
      algorithm
        if not isBasicTypeComponentName(s) then
          Error.addMessage(Error.TYPE_NOT_FROM_PREDEFINED, {AbsynUtil.pathString(p)});
          fail();
        end if;
      then ClassInf.TYPE(p);
    /* adrpo 2009-05-15: type Orientation can contain equalityConstraint function! */
    //case (ClassInf.TYPE(path = p),ClassInf.FOUND_COMPONENT()) then ClassInf.TYPE(p);
    case (ClassInf.PACKAGE(),ClassInf.FOUND_COMPONENT()) then inState;
    case (ClassInf.FUNCTION(),ClassInf.FOUND_COMPONENT()) then inState;
    case (ClassInf.ENUMERATION(),ClassInf.FOUND_COMPONENT()) then inState;
    case (ClassInf.HAS_RESTRICTIONS(),ClassInf.FOUND_COMPONENT()) then inState;
    case (ClassInf.TYPE_INTEGER(),ClassInf.FOUND_COMPONENT()) then inState;
    case (ClassInf.TYPE_REAL(),ClassInf.FOUND_COMPONENT()) then inState;
    case (ClassInf.TYPE_STRING(),ClassInf.FOUND_COMPONENT()) then inState;
    case (ClassInf.TYPE_BOOL(),ClassInf.FOUND_COMPONENT()) then inState;
    case (ClassInf.TYPE_CLOCK(),ClassInf.FOUND_COMPONENT()) then inState;
    case (ClassInf.TYPE_ENUM(),ClassInf.FOUND_COMPONENT()) then inState;
    case (ClassInf.META_RECORD(),ClassInf.FOUND_COMPONENT()) then inState;  // Added 2009-08-19. sjoelund
    case (ClassInf.META_UNIONTYPE(), ClassInf.FOUND_COMPONENT()) then inState;

   /* Event `FOUND_EQUATION\' */
    case (ClassInf.UNKNOWN(path = p),ClassInf.FOUND_EQUATION()) then ClassInf.HAS_RESTRICTIONS(p,true,false,false);
    case (ClassInf.OPTIMIZATION(),ClassInf.FOUND_EQUATION()) then inState;
    case (ClassInf.OPTIMIZATION(),ClassInf.FOUND_CONSTRAINT()) then inState;
    case (ClassInf.OPTIMIZATION(),ClassInf.FOUND_ALGORITHM()) then inState;

    case (ClassInf.MODEL(),ClassInf.FOUND_EQUATION()) then inState;
    case (ClassInf.BLOCK(),ClassInf.FOUND_EQUATION()) then inState;

    case (ClassInf.MODEL(),ClassInf.FOUND_ALGORITHM()) then inState;
    case (ClassInf.BLOCK(),ClassInf.FOUND_ALGORITHM()) then inState;
    case (ClassInf.FUNCTION(),ClassInf.FOUND_ALGORITHM()) then inState;

    case (ClassInf.HAS_RESTRICTIONS(path=p,hasAlgorithms=b2,hasConstraints=b3),ClassInf.FOUND_EQUATION()) then ClassInf.HAS_RESTRICTIONS(p,true,b2,b3);
    case (ClassInf.HAS_RESTRICTIONS(path=p,hasEquations=b1,hasAlgorithms=b2),ClassInf.FOUND_CONSTRAINT()) then ClassInf.HAS_RESTRICTIONS(p,b1,b2,true);
    case (ClassInf.HAS_RESTRICTIONS(path=p,hasEquations=b1,hasConstraints=b3),ClassInf.FOUND_ALGORITHM()) then ClassInf.HAS_RESTRICTIONS(p,b1,true,b3);

    case (ClassInf.FUNCTION(),ClassInf.FOUND_EXT_DECL()) then inState;
    case (_,ClassInf.FOUND_EXT_DECL()) then fail();

    case (_,ClassInf.FOUND_EQUATION()) then fail();
    case (_,ClassInf.FOUND_CONSTRAINT()) then fail();

    case (st,ev)
      algorithm
        true := Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- ClassInfUtil.trans failed: " + printStateStr(st) + ", " + printEventStr(ev));
      then
        fail();
  end match;
end trans;

public function valid "
  This is the validity function which determines if a state is valid
  according to one of the restrictions.  This means, that if a class
  definition is to be used as, say, a connector, the state of the
  state machine is checked against the `SCode.R_CONNECTOR\'
  restriction using this function to find out if it is an error to
  use this class definition as a connector.
"
  input ClassInf.State inState;
  input SCode.Restriction inRestriction;
algorithm
  _ := match (inState,inRestriction)
    local Absyn.Path p;

    case (ClassInf.UNKNOWN(),_) then ();

    case (ClassInf.HAS_RESTRICTIONS(),SCode.R_CLASS()) then ();
    case (ClassInf.HAS_RESTRICTIONS(),SCode.R_MODEL()) then ();
    case (ClassInf.HAS_RESTRICTIONS(),SCode.R_OPTIMIZATION()) then ();
    case (ClassInf.MODEL(),SCode.R_MODEL()) then ();


    case (ClassInf.RECORD(),SCode.R_RECORD(_)) then ();
    case (ClassInf.RECORD(),SCode.R_CONNECTOR(_)) then ();
    case (ClassInf.HAS_RESTRICTIONS(hasEquations=false,hasConstraints=false,hasAlgorithms=false),SCode.R_RECORD(_)) then ();

    case (ClassInf.BLOCK(),SCode.R_BLOCK()) then ();
    case (ClassInf.MODEL(),SCode.R_MODEL()) then ();

    case (ClassInf.CONNECTOR(),SCode.R_TYPE()) then ();
    case (ClassInf.CONNECTOR(isExpandable=false),SCode.R_CONNECTOR(false)) then ();
    case (ClassInf.CONNECTOR(isExpandable=true),SCode.R_CONNECTOR(true)) then ();
    case (ClassInf.HAS_RESTRICTIONS(hasEquations=false,hasConstraints=false,hasAlgorithms=false),SCode.R_CONNECTOR(_)) then ();
    case (ClassInf.TYPE_INTEGER(),SCode.R_CONNECTOR(_)) then ();
    case (ClassInf.TYPE_REAL(),SCode.R_CONNECTOR(_)) then ();
    case (ClassInf.TYPE_STRING(),SCode.R_CONNECTOR(_)) then ();
    case (ClassInf.TYPE_BOOL(),SCode.R_CONNECTOR(_)) then ();
    // BTH
    case (ClassInf.TYPE_CLOCK(),SCode.R_CONNECTOR(_)) then ();
    case (ClassInf.TYPE_ENUM(),SCode.R_CONNECTOR(_)) then (); // used in Modelica.Electrical.Digital where we have an enum as a connector
    case (ClassInf.ENUMERATION(),SCode.R_CONNECTOR(_)) then ();      // used in Modelica.Electrical.Digital where we have an enum as a connector
    case (ClassInf.TYPE(),SCode.R_CONNECTOR()) then (); // Note: Only allowed in some cases (outputs, etc). Happens when the base class is type T extends Real; end T;

    case (ClassInf.TYPE(),SCode.R_TYPE()) then ();
    case (ClassInf.TYPE_INTEGER(),SCode.R_TYPE()) then ();
    case (ClassInf.TYPE_REAL(),SCode.R_TYPE()) then ();
    case (ClassInf.TYPE_STRING(),SCode.R_TYPE()) then ();
    case (ClassInf.TYPE_BOOL(),SCode.R_TYPE()) then ();
    // BTH
    case (ClassInf.TYPE_CLOCK(),SCode.R_TYPE()) then ();
    case (ClassInf.TYPE_ENUM(),SCode.R_TYPE()) then ();
    case (ClassInf.ENUMERATION(),SCode.R_TYPE()) then ();

    case (ClassInf.PACKAGE(),SCode.R_PACKAGE()) then ();
    case (ClassInf.HAS_RESTRICTIONS(hasEquations=false,hasConstraints=false,hasAlgorithms=false),SCode.R_PACKAGE()) then ();

    case (ClassInf.FUNCTION(),SCode.R_FUNCTION(_)) then ();
    case (ClassInf.HAS_RESTRICTIONS(hasEquations=false,hasConstraints=false),SCode.R_FUNCTION(_)) then ();
    case (ClassInf.META_TUPLE(),SCode.R_TYPE()) then ();
    case (ClassInf.META_LIST(),SCode.R_TYPE()) then ();
    case (ClassInf.META_OPTION(),SCode.R_TYPE()) then ();
    case (ClassInf.META_RECORD(),SCode.R_TYPE()) then ();
    case (ClassInf.META_ARRAY(),SCode.R_TYPE()) then ();
    case (ClassInf.META_UNIONTYPE(),SCode.R_TYPE()) then ();

  end match;
end valid;

public function assertValid "This function has the same semantical meaning as the function
  `valid\'.  However, it prints an error message when it fails."
  input ClassInf.State inState;
  input SCode.Restriction inRestriction;
  input SourceInfo info;
algorithm
  _ := matchcontinue (inState,inRestriction,info)
    local
      ClassInf.State st;
      SCode.Restriction re;
      String str1,str2,str3;
    case (st,re,_)
      algorithm
        valid(st, re);
      then
        ();
    case (st,re,_)
      algorithm
        str1 := AbsynUtil.pathString(getStateName(st));
        str2 := printStateStr(st);
        str3 := SCodeDump.restrictionStringPP(re);
        Error.addSourceMessage(Error.RESTRICTION_VIOLATION, {str1,str2,str3}, info);
      then
        fail();
  end matchcontinue;
end assertValid;

public function assertTrans "This function has the same semantical meaning as the function
  `trans\'.  However, it prints an error message when it fails."
  input ClassInf.State inState;
  input ClassInf.Event event;
  input SourceInfo info;
  output ClassInf.State outState;
algorithm
  outState := matchcontinue (inState,event,info)
    local
      ClassInf.State st;
      String str1,str2,str3;
    case (st,_,_)
      then trans(st, event);
    case (st,_,_)
      algorithm
        str1 := AbsynUtil.pathString(getStateName(st));
        str2 := printStateStr(st);
        str3 := printEventStr(event);
        Error.addSourceMessage(Error.TRANS_VIOLATION, {str1,str2,str3}, info);
      then
        fail();
  end matchcontinue;
end assertTrans;

public function matchingState "
  Finds a State in the list that matches the state given as first argument.
  NOTE: Currently not used anywhere.
"
  input ClassInf.State inState;
  input list<ClassInf.State> inStateLst;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inState,inStateLst)
    local
      list<ClassInf.State> rest;
      Boolean res;
    case (_,{}) then false;
    case (ClassInf.UNKNOWN(),(ClassInf.UNKNOWN() :: _)) then true;
    case (ClassInf.MODEL(),(ClassInf.MODEL() :: _)) then true;
    case (ClassInf.RECORD(),(ClassInf.RECORD() :: _)) then true;
    case (ClassInf.BLOCK(),(ClassInf.BLOCK() :: _)) then true;
    case (ClassInf.CONNECTOR(),(ClassInf.CONNECTOR() :: _)) then true;
    case (ClassInf.TYPE(),(ClassInf.TYPE() :: _)) then true;
    case (ClassInf.PACKAGE(),(ClassInf.PACKAGE() :: _)) then true;
    case (ClassInf.FUNCTION(),(ClassInf.FUNCTION() :: _)) then true;
    case (ClassInf.ENUMERATION(),(ClassInf.ENUMERATION() :: _)) then true;
    case (ClassInf.TYPE_INTEGER(),(ClassInf.TYPE_INTEGER() :: _)) then true;
    case (ClassInf.TYPE_REAL(),(ClassInf.TYPE_REAL() :: _)) then true;
    case (ClassInf.TYPE_STRING(),(ClassInf.TYPE_STRING() :: _)) then true;
    case (ClassInf.TYPE_BOOL(),(ClassInf.TYPE_BOOL() :: _)) then true;
    // BTH
    case (ClassInf.TYPE_CLOCK(),(ClassInf.TYPE_CLOCK() :: _)) then true;
    case (ClassInf.TYPE_ENUM(),(ClassInf.TYPE_ENUM() :: _)) then true;
    case (_,(_ :: rest))
      algorithm
        res := matchingState(inState, rest);
      then
        res;
  end match;
end matchingState;

public function isFunction
"returns true if state is FUNCTION."
  input ClassInf.State inState;
  output Boolean b;
algorithm
  b := match (inState)
    case ClassInf.FUNCTION() then true;
    else false;
  end match;
end isFunction;

public function isFunctionOrRecord "Fails for states that are not FUNCTION or RECORD."
  input ClassInf.State inState;
  output Boolean b;
algorithm
  b := match (inState)
    case ClassInf.FUNCTION() then true;
    case ClassInf.RECORD() then true;
    else false;
  end match;
end isFunctionOrRecord;

public function isConnector "
  Fails for states that are not CONNECTOR.
"
  input ClassInf.State inState;
algorithm
  _:=
  match (inState)
    case ClassInf.CONNECTOR() then ();
  end match;
end isConnector;

protected constant list<String> basicTypeMods = {
  "quantity",
  "unit",
  "displayUnit",
  "min",
  "max",
  "start",
  "fixed",
  "nominal",
  "stateSelect",
  "uncertain",    // extension for uncertainties
  "distribution"  // extension for uncertainties
};

public function isBasicTypeComponentName
"Returns true if the name can be a component of a builtin type"
  input String name;
  output Boolean res;
algorithm
  res := listMember(name,basicTypeMods);
end isBasicTypeComponentName;

public function isTypeOrRecord
  input ClassInf.State inState;
  output Boolean outIsTypeOrRecord;
algorithm
  outIsTypeOrRecord := match(inState)
    case ClassInf.TYPE() then true;
    case ClassInf.RECORD() then true;
    else false;
  end match;
end isTypeOrRecord;

public function isRecord
  input ClassInf.State inState;
  output Boolean outIsRecord;
algorithm
  outIsRecord := match inState
    case ClassInf.RECORD() then true;
    else false;
  end match;
end isRecord;

public function isMetaRecord
  input ClassInf.State inState;
  output Boolean outIsRecord;
algorithm
  outIsRecord := match inState
    case ClassInf.META_RECORD() then true;
    else false;
  end match;
end isMetaRecord;

annotation(__OpenModelica_Interface="frontend_dump");
end ClassInfUtil;
