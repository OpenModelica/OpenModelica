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

encapsulated package ClassInf
" file:        ClassInf.mo
  package:     ClassInf
  description: Class restrictions

  RCS:   $Id$

  This module deals with class inference, i.e. determining if a
  class definition adhers to one of the class restrictions, and, if
  specifically declared in a restrictied form, if it breaks that
  restriction.

  The inference is implemented as a finite state machine.  The
  function `start\' initializes a new machine, and the function
  `trans\' signals transitions in the machine.  Finally, the state
  can be checked agains a restriction with the `valid\' function. "


public import SCode;
public import Absyn;

protected import Debug;
protected import Error;
protected import Flags;
protected import Print;
protected import SCodeDump;

public
uniontype State "- Machine states, the string contains the classname."
  record UNKNOWN
    Absyn.Path path;
  end UNKNOWN;

   record OPTIMIZATION
    Absyn.Path path;
   end OPTIMIZATION;

  record MODEL
    Absyn.Path path;
  end MODEL;

  record RECORD
    Absyn.Path path;
  end RECORD;

  record BLOCK
    Absyn.Path path;
  end BLOCK;

  record CONNECTOR
    Absyn.Path path;
    Boolean isExpandable;
  end CONNECTOR;

  record TYPE
    Absyn.Path path;
  end TYPE;

  record PACKAGE
    Absyn.Path path;
  end PACKAGE;

  record FUNCTION
    Absyn.Path path;
    Boolean isImpure;
  end FUNCTION;

  record ENUMERATION
    Absyn.Path path;
  end ENUMERATION;

  record HAS_RESTRICTIONS
    Absyn.Path path;
    Boolean hasEquations;
    Boolean hasAlgorithms;
    Boolean hasConstraints;
  end HAS_RESTRICTIONS;

  record TYPE_INTEGER
    Absyn.Path path;
  end TYPE_INTEGER;

  record TYPE_REAL
    Absyn.Path path;
  end TYPE_REAL;

  record TYPE_STRING
    Absyn.Path path;
  end TYPE_STRING;

  record TYPE_BOOL
    Absyn.Path path;
  end TYPE_BOOL;
  // BTH
  record TYPE_CLOCK
    Absyn.Path path;
  end TYPE_CLOCK;

  record TYPE_ENUM
    Absyn.Path path;
  end TYPE_ENUM;

  record EXTERNAL_OBJ
    Absyn.Path path;
  end EXTERNAL_OBJ;

  /* MetaModelica extension */
  record META_TUPLE
    Absyn.Path path;
  end META_TUPLE;

  record META_LIST
    Absyn.Path path;
  end META_LIST;

  record META_OPTION
    Absyn.Path path;
  end META_OPTION;

  record META_RECORD
    Absyn.Path path;
  end META_RECORD;

  record META_UNIONTYPE
    Absyn.Path path;
  end META_UNIONTYPE;

  record META_ARRAY
    Absyn.Path path;
  end META_ARRAY;

  record META_POLYMORPHIC
    Absyn.Path path;
  end META_POLYMORPHIC;
  /*---------------------*/
end State;

public
uniontype Event "- Events"
  record FOUND_EQUATION "There are equations inside the current definition" end FOUND_EQUATION;

  record FOUND_ALGORITHM "There are algorithms inside the current definition" end FOUND_ALGORITHM;

  record FOUND_CONSTRAINT "There are constranit (equations) inside the current definition" end FOUND_CONSTRAINT;

  record FOUND_EXT_DECL "There is an external declaration inside the current definition" end FOUND_EXT_DECL;

  record NEWDEF "A definition with elements, i.e. a long definition" end NEWDEF;

  record FOUND_COMPONENT " A Definition that contains components"
    String name "name of the component";
  end FOUND_COMPONENT;

end Event;

public function printStateStr "- Printing

  Some functions for printing error and debug information about the
  state machine.

  The code is excluded from the report.
"
  input State inState;
  output String outString;
algorithm
  outString:=
  match (inState)
    local
      Absyn.Path p;
      Boolean b1,b2,b3;
    case UNKNOWN() then "unknown";
    case OPTIMIZATION() then "optimization";
    case MODEL() then "model";
    case RECORD() then "record";
    case BLOCK() then "block";
    case CONNECTOR() then "connector";
    case TYPE() then "type";
    case PACKAGE() then "package";
    case FUNCTION(isImpure = true) then "impure function";
    case FUNCTION() then "function";
    case TYPE_INTEGER() then "Integer";
    case TYPE_REAL() then "Real";
    case TYPE_STRING() then "String";
    case TYPE_BOOL() then "Boolean";
    // BTH
    case TYPE_CLOCK() then "Clock";
    case HAS_RESTRICTIONS(hasEquations = false, hasAlgorithms = false, hasConstraints = false) then "new def";
    case HAS_RESTRICTIONS(hasEquations = b1, hasAlgorithms = b2)
      then "has" + (if b1 then " equations" else "") + (if b2 then " algorithms" else "") + (if b1 then " constraints" else "");
    case EXTERNAL_OBJ() then "ExternalObject";
    case META_TUPLE() then "tuple";
    case META_LIST() then "list";
    case META_OPTION() then "Option";
    case META_RECORD() then "meta_record";
    case META_POLYMORPHIC() then "polymorphic";
    case META_ARRAY() then "meta_array";
    case META_UNIONTYPE() then "uniontype";
    else "#printStateStr failed#";
  end match;
end printStateStr;

public function printState
  input State inState;
algorithm
  _:=
  matchcontinue (inState)
    local Absyn.Path p;

    case UNKNOWN(path = p)
      equation
        Print.printBuf("UNKNOWN ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    case OPTIMIZATION(path = p)
      equation
        Print.printBuf("OPTIMIZATION ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    case MODEL(path = p)
      equation
        Print.printBuf("MODEL ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    case RECORD(path = p)
      equation
        Print.printBuf("RECORD ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    case BLOCK(path = p)
      equation
        Print.printBuf("BLOCK ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    case CONNECTOR(path = p)
      equation
        Print.printBuf("CONNECTOR ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    case TYPE(path = p)
      equation
        Print.printBuf("TYPE ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    case PACKAGE(path = p)
      equation
        Print.printBuf("PACKAGE ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    case FUNCTION(path = p, isImpure = true)
      equation
        Print.printBuf("IMPURE FUNCTION ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    case FUNCTION(path = p)
      equation
        Print.printBuf("FUNCTION ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    case TYPE_INTEGER(path = p)
      equation
        Print.printBuf("TYPE_INTEGER ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    case TYPE_REAL(path = p)
      equation
        Print.printBuf("TYPE_REAL ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    case TYPE_STRING(path = p)
      equation
        Print.printBuf("TYPE_STRING ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    case TYPE_BOOL(path = p)
      equation
        Print.printBuf("TYPE_BOOL ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    // BTH
    case TYPE_CLOCK(path = p)
      equation
        Print.printBuf("TYPE_CLOCK ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    case HAS_RESTRICTIONS(path = p)
      equation
        Print.printBuf("HAS_RESTRICTIONS ");
        Print.printBuf(Absyn.pathString(p));
        Print.printBuf(printStateStr(inState));
      then ();
  end matchcontinue;
end printState;

public function getStateName "Returns the classname of the state."
  input State inState;
  output Absyn.Path outPath;
algorithm
  outPath := match (inState)
    local
      Absyn.Path p;
    case UNKNOWN(path = p) then p;
    case OPTIMIZATION(path = p) then p;
    case MODEL(path = p) then p;
    case RECORD(path = p) then p;
    case BLOCK(path = p) then p;
    case CONNECTOR(path = p) then p;
    case TYPE(path = p) then p;
    case PACKAGE(path = p) then p;
    case FUNCTION(path = p) then p;
    case ENUMERATION(path = p) then p;
    case HAS_RESTRICTIONS(path = p) then p;
    case TYPE_INTEGER(path = p) then p;
    case TYPE_REAL(path = p) then p;
    case TYPE_STRING(path = p) then p;
    case TYPE_BOOL(path = p) then p;
    // BTH
    case TYPE_CLOCK(path = p) then p;
    case TYPE_ENUM(path = p) then p;

    case EXTERNAL_OBJ(p) then p;

    case META_TUPLE(p) then p;
    case META_LIST(p) then p;
    case META_OPTION(p) then p;
    case META_RECORD(p) then p;
    case META_UNIONTYPE(p) then p;
    case META_ARRAY(p) then p;
    case META_POLYMORPHIC(p) then p;

    else Absyn.IDENT("#getStateName failed#");
  end match;
end getStateName;

protected function printEventStr
  input Event inEvent;
  output String str;
algorithm
  str := match (inEvent)
    local
      String name;
    case FOUND_EQUATION() then "equation";
    case FOUND_CONSTRAINT() then "constraint";
    case NEWDEF() then "new definition";
    case FOUND_COMPONENT(name) then "component " + name;
    case FOUND_EXT_DECL() then "external function declaration";
    else "Unknown event";
  end match;
end printEventStr;

public function start "
  This is the state machine initialization function."
  input SCode.Restriction inRestriction;
  input Absyn.Path inPath;
  output State outState;
algorithm
  outState := start_dispatch(inRestriction, Absyn.makeFullyQualified(inPath));
end start;

// Transitions
protected function start_dispatch "
  This is the state machine initialization function."
  input SCode.Restriction inRestriction;
  input Absyn.Path inPath;
  output State outState;
algorithm
  outState:=
  match (inRestriction,inPath)
    local Absyn.Path p; Boolean isExpandable, isImpure;
    case (SCode.R_CLASS(),p) then UNKNOWN(p);
    case (SCode.R_OPTIMIZATION(),p) then OPTIMIZATION(p);
    case (SCode.R_MODEL(),p) then MODEL(p);
    case (SCode.R_RECORD(_),p) then RECORD(p);
    case (SCode.R_BLOCK(),p) then BLOCK(p);
    case (SCode.R_CONNECTOR(isExpandable),p) then CONNECTOR(p,isExpandable);
    case (SCode.R_TYPE(),p) then TYPE(p);
    case (SCode.R_PACKAGE(),p) then PACKAGE(p);
    case (SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(isImpure)),p) then FUNCTION(p, isImpure);
    case (SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(isImpure)),p) then FUNCTION(p, isImpure);
    case (SCode.R_FUNCTION(_),p) then FUNCTION(p, false);
    case (SCode.R_OPERATOR(),p) then FUNCTION(p, false);
    case (SCode.R_ENUMERATION(),p) then ENUMERATION(p);
    case (SCode.R_PREDEFINED_INTEGER(),p) then TYPE_INTEGER(p);
    case (SCode.R_PREDEFINED_REAL(),p) then TYPE_REAL(p);
    case (SCode.R_PREDEFINED_STRING(),p) then TYPE_STRING(p);
    case (SCode.R_PREDEFINED_BOOLEAN(),p) then TYPE_BOOL(p);
    // BTH
    case (SCode.R_PREDEFINED_CLOCK(),p)
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then TYPE_CLOCK(p);
    case (SCode.R_PREDEFINED_ENUMERATION(),p) then TYPE_ENUM(p);
     /* Meta Modelica extensions */
    case (SCode.R_UNIONTYPE(),p) then META_UNIONTYPE(p);
    case (SCode.R_METARECORD(),p) then META_RECORD(p);
  end match;
end start_dispatch;

public function trans "
  This is the state machine transition function.  It describes the
  transitions between states at different events.
"
  input State inState;
  input Event inEvent;
  output State outState;
algorithm
  outState := match (inState,inEvent)
    local
      Absyn.Path p;
      State st;
      Event ev;
      Boolean isExpandable,b,b1,b2,b3,isImpure;
      String s;
      list<String> msg;
    case (UNKNOWN(path = p),NEWDEF()) then HAS_RESTRICTIONS(p,false,false,false);  /* Event `NEWDEF\' */
    case (OPTIMIZATION(),NEWDEF()) then inState;
    case (MODEL(),NEWDEF()) then inState;
    case (RECORD(),NEWDEF()) then inState;
    case (BLOCK(),NEWDEF()) then inState;
    case (CONNECTOR(),NEWDEF()) then inState;
    case (TYPE(path = p),NEWDEF()) then TYPE(p); // A type can be constructed with long definition
    case (PACKAGE(path = p),NEWDEF()) then PACKAGE(p);
    case (FUNCTION(),NEWDEF()) then inState;
    case (ENUMERATION(),NEWDEF()) then inState;
    case (TYPE_INTEGER(),NEWDEF()) then inState;
    case (TYPE_REAL(),NEWDEF()) then inState;
    case (TYPE_STRING(),NEWDEF()) then inState;
    case (TYPE_BOOL(),NEWDEF()) then inState;
    // BTH
    case (TYPE_CLOCK(),NEWDEF()) then inState;
    case (TYPE_ENUM(),NEWDEF()) then inState;
    case (META_UNIONTYPE(),NEWDEF()) then inState;  // Added 2009-05-11. sjoelund
    case (META_RECORD(),NEWDEF()) then inState;  // Added 2009-08-18. sjoelund

   /* Event 'FOUND_COMPONENT' */
    case (UNKNOWN(path = p),FOUND_COMPONENT()) then HAS_RESTRICTIONS(p,false,false,false);  /* Event `NEWDEF\' */
    case (OPTIMIZATION(),FOUND_COMPONENT()) then inState;
    case (MODEL(),FOUND_COMPONENT()) then inState;
    case (RECORD(),FOUND_COMPONENT()) then inState;
    case (BLOCK(),FOUND_COMPONENT()) then inState;
    case (CONNECTOR(),FOUND_COMPONENT()) then inState;
    case (TYPE(path = p),FOUND_COMPONENT(name = s)) // A type can not contain new components
      equation
        if not isBasicTypeComponentName(s) then
          Error.addMessage(Error.TYPE_NOT_FROM_PREDEFINED, {Absyn.pathString(p)});
          fail();
        end if;
      then TYPE(p);
    /* adrpo 2009-05-15: type Orientation can contain equalityConstraint function! */
    //case (TYPE(path = p),FOUND_COMPONENT()) then TYPE(p);
    case (PACKAGE(),FOUND_COMPONENT()) then inState;
    case (FUNCTION(),FOUND_COMPONENT()) then inState;
    case (ENUMERATION(),FOUND_COMPONENT()) then inState;
    case (HAS_RESTRICTIONS(),FOUND_COMPONENT()) then inState;
    case (TYPE_INTEGER(),FOUND_COMPONENT()) then inState;
    case (TYPE_REAL(),FOUND_COMPONENT()) then inState;
    case (TYPE_STRING(),FOUND_COMPONENT()) then inState;
    case (TYPE_BOOL(),FOUND_COMPONENT()) then inState;
    case (TYPE_CLOCK(),FOUND_COMPONENT()) then inState;
    case (TYPE_ENUM(),FOUND_COMPONENT()) then inState;
    case (META_RECORD(),FOUND_COMPONENT()) then inState;  // Added 2009-08-19. sjoelund

   /* Event `FOUND_EQUATION\' */
    case (UNKNOWN(path = p),FOUND_EQUATION()) then HAS_RESTRICTIONS(p,true,false,false);
    case (OPTIMIZATION(),FOUND_EQUATION()) then inState;
    case (OPTIMIZATION(),FOUND_CONSTRAINT()) then inState;
    case (OPTIMIZATION(),FOUND_ALGORITHM()) then inState;

    case (MODEL(),FOUND_EQUATION()) then inState;
    case (BLOCK(),FOUND_EQUATION()) then inState;

    case (MODEL(),FOUND_ALGORITHM()) then inState;
    case (BLOCK(),FOUND_ALGORITHM()) then inState;
    case (FUNCTION(),FOUND_ALGORITHM()) then inState;

    case (HAS_RESTRICTIONS(path=p,hasAlgorithms=b2,hasConstraints=b3),FOUND_EQUATION()) then HAS_RESTRICTIONS(p,true,b2,b3);
    case (HAS_RESTRICTIONS(path=p,hasEquations=b1,hasAlgorithms=b2),FOUND_CONSTRAINT()) then HAS_RESTRICTIONS(p,b1,b2,true);
    case (HAS_RESTRICTIONS(path=p,hasEquations=b1,hasConstraints=b3),FOUND_ALGORITHM()) then HAS_RESTRICTIONS(p,b1,true,b3);

    case (FUNCTION(),FOUND_EXT_DECL()) then inState;
    case (_,FOUND_EXT_DECL()) then fail();

    case (_,FOUND_EQUATION()) then fail();
    case (_,FOUND_CONSTRAINT()) then fail();

    case (st,ev)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- ClassInf.trans failed: " + printStateStr(st) + ", " + printEventStr(ev));
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
  input State inState;
  input SCode.Restriction inRestriction;
algorithm
  _ := match (inState,inRestriction)
    local Absyn.Path p;

    case (UNKNOWN(),_) then ();

    case (HAS_RESTRICTIONS(),SCode.R_CLASS()) then ();
    case (HAS_RESTRICTIONS(),SCode.R_MODEL()) then ();
    case (HAS_RESTRICTIONS(),SCode.R_OPTIMIZATION()) then ();
    case (MODEL(),SCode.R_MODEL()) then ();


    case (RECORD(),SCode.R_RECORD(_)) then ();
    case (RECORD(),SCode.R_CONNECTOR(_)) then ();
    case (HAS_RESTRICTIONS(hasEquations=false,hasConstraints=false,hasAlgorithms=false),SCode.R_RECORD(_)) then ();

    case (BLOCK(),SCode.R_BLOCK()) then ();
    case (MODEL(),SCode.R_MODEL()) then ();

    case (CONNECTOR(isExpandable=false),SCode.R_CONNECTOR(false)) then ();
    case (CONNECTOR(isExpandable=true),SCode.R_CONNECTOR(true)) then ();
    case (HAS_RESTRICTIONS(hasEquations=false,hasConstraints=false,hasAlgorithms=false),SCode.R_CONNECTOR(_)) then ();
    case (TYPE_INTEGER(),SCode.R_CONNECTOR(_)) then ();
    case (TYPE_REAL(),SCode.R_CONNECTOR(_)) then ();
    case (TYPE_STRING(),SCode.R_CONNECTOR(_)) then ();
    case (TYPE_BOOL(),SCode.R_CONNECTOR(_)) then ();
    // BTH
    case (TYPE_CLOCK(),SCode.R_CONNECTOR(_)) then ();
    case (TYPE_ENUM(),SCode.R_CONNECTOR(_)) then (); // used in Modelica.Electrical.Digital where we have an enum as a connector
    case (ENUMERATION(),SCode.R_CONNECTOR(_)) then ();      // used in Modelica.Electrical.Digital where we have an enum as a connector

    case (TYPE(),SCode.R_TYPE()) then ();
    case (TYPE_INTEGER(),SCode.R_TYPE()) then ();
    case (TYPE_REAL(),SCode.R_TYPE()) then ();
    case (TYPE_STRING(),SCode.R_TYPE()) then ();
    case (TYPE_BOOL(),SCode.R_TYPE()) then ();
    // BTH
    case (TYPE_CLOCK(),SCode.R_TYPE()) then ();
    case (TYPE_ENUM(),SCode.R_TYPE()) then ();
    case (ENUMERATION(),SCode.R_TYPE()) then ();

    case (PACKAGE(),SCode.R_PACKAGE()) then ();
    case (HAS_RESTRICTIONS(hasEquations=false,hasConstraints=false,hasAlgorithms=false),SCode.R_PACKAGE()) then ();

    case (FUNCTION(),SCode.R_FUNCTION(_)) then ();
    case (HAS_RESTRICTIONS(hasEquations=false,hasConstraints=false),SCode.R_FUNCTION(_)) then ();
    case (META_TUPLE(),SCode.R_TYPE()) then ();
    case (META_LIST(),SCode.R_TYPE()) then ();
    case (META_OPTION(),SCode.R_TYPE()) then ();
    case (META_RECORD(),SCode.R_TYPE()) then ();
    case (META_ARRAY(),SCode.R_TYPE()) then ();
    case (META_UNIONTYPE(),SCode.R_TYPE()) then ();

  end match;
end valid;

public function assertValid "This function has the same semantical meaning as the function
  `valid\'.  However, it prints an error message when it fails."
  input State inState;
  input SCode.Restriction inRestriction;
  input SourceInfo info;
algorithm
  _ := matchcontinue (inState,inRestriction,info)
    local
      State st;
      SCode.Restriction re;
      String str1,str2,str3;
    case (st,re,_)
      equation
        valid(st, re);
      then
        ();
    case (st,re,_)
      equation
        str1 = Absyn.pathString(getStateName(st));
        str2 = printStateStr(st);
        str3 = SCodeDump.restrictionStringPP(re);
        Error.addSourceMessage(Error.RESTRICTION_VIOLATION, {str1,str2,str3}, info);
      then
        fail();
  end matchcontinue;
end assertValid;

public function assertTrans "This function has the same semantical meaning as the function
  `trans\'.  However, it prints an error message when it fails."
  input State inState;
  input Event event;
  input SourceInfo info;
  output State outState;
algorithm
  outState := matchcontinue (inState,event,info)
    local
      State st;
      String str1,str2,str3;
    case (st,_,_)
      then trans(st, event);
    case (st,_,_)
      equation
        str1 = Absyn.pathString(getStateName(st));
        str2 = printStateStr(st);
        str3 = printEventStr(event);
        Error.addSourceMessage(Error.TRANS_VIOLATION, {str1,str2,str3}, info);
      then
        fail();
  end matchcontinue;
end assertTrans;

public function matchingState "
  Finds a State in the list that matches the state given as first argument.
  NOTE: Currently not used anywhere.
"
  input State inState;
  input list<State> inStateLst;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inState,inStateLst)
    local
      State st,first;
      list<State> rest;
      Boolean res;
    case (_,{}) then false;
    case (UNKNOWN(),(UNKNOWN() :: _)) then true;
    case (MODEL(),(MODEL() :: _)) then true;
    case (RECORD(),(RECORD() :: _)) then true;
    case (BLOCK(),(BLOCK() :: _)) then true;
    case (CONNECTOR(),(CONNECTOR() :: _)) then true;
    case (TYPE(),(TYPE() :: _)) then true;
    case (PACKAGE(),(PACKAGE() :: _)) then true;
    case (FUNCTION(),(FUNCTION() :: _)) then true;
    case (ENUMERATION(),(ENUMERATION() :: _)) then true;
    case (TYPE_INTEGER(),(TYPE_INTEGER() :: _)) then true;
    case (TYPE_REAL(),(TYPE_REAL() :: _)) then true;
    case (TYPE_STRING(),(TYPE_STRING() :: _)) then true;
    case (TYPE_BOOL(),(TYPE_BOOL() :: _)) then true;
    // BTH
    case (TYPE_CLOCK(),(TYPE_CLOCK() :: _)) then true;
    case (TYPE_ENUM(),(TYPE_ENUM() :: _)) then true;
    case (st,(_ :: rest))
      equation
        res = matchingState(st, rest);
      then
        res;
  end matchcontinue;
end matchingState;

public function isFunction
"returns true if state is FUNCTION."
  input State inState;
  output Boolean b;
algorithm
  b := match (inState)
    case FUNCTION() then true;
    else false;
  end match;
end isFunction;

public function isFunctionOrRecord "Fails for states that are not FUNCTION or RECORD."
  input State inState;
  output Boolean b;
algorithm
  b := match (inState)
    case FUNCTION() then true;
    case RECORD() then true;
    else false;
  end match;
end isFunctionOrRecord;

public function isConnector "
  Fails for states that are not CONNECTOR.
"
  input State inState;
algorithm
  _:=
  match (inState)
    case CONNECTOR() then ();
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
  input State inState;
  output Boolean outIsTypeOrRecord;
algorithm
  outIsTypeOrRecord := match(inState)
    case TYPE() then true;
    case RECORD() then true;
    else false;
  end match;
end isTypeOrRecord;

public function isRecord
  input State inState;
  output Boolean outIsRecord;
algorithm
  outIsRecord := match inState
    case RECORD() then true;
    else false;
  end match;
end isRecord;

public function stateToSCodeRestriction
"@author: adrpo
 ClassInf.State -> SCode.Restriction"
  input State inState;
  output SCode.Restriction outRestriction;
  output Absyn.Path outPath;
algorithm
  (outRestriction, outPath) := match (inState)
    local Absyn.Path p; Boolean isExpandable, isImpure;

    case UNKNOWN(p) then (SCode.R_CLASS(),p);
    case OPTIMIZATION(p) then (SCode.R_OPTIMIZATION(),p);
    case MODEL(p) then (SCode.R_MODEL(),p);
      // mahge: TODO ClassInf.RECORD should contain isOperator.
    case RECORD(p) then (SCode.R_RECORD(false),p);
    case BLOCK(p) then (SCode.R_BLOCK(),p) ;
    case CONNECTOR(p,isExpandable) then (SCode.R_CONNECTOR(isExpandable),p);
    case TYPE(p) then (SCode.R_TYPE(),p);
    case PACKAGE(p) then (SCode.R_PACKAGE(),p) ;
    case FUNCTION(p,isImpure) then (SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(isImpure)),p);
    case ENUMERATION(p) then (SCode.R_ENUMERATION(),p);
    case TYPE_INTEGER(p) then (SCode.R_PREDEFINED_INTEGER(),p);
    case TYPE_REAL(p) then (SCode.R_PREDEFINED_REAL(),p);
    case TYPE_STRING(p) then (SCode.R_PREDEFINED_STRING(),p);
    case TYPE_BOOL(p) then (SCode.R_PREDEFINED_BOOLEAN(),p);
    // BTH
    case TYPE_CLOCK(p) then (SCode.R_PREDEFINED_CLOCK(),p);
    case TYPE_ENUM(p) then (SCode.R_PREDEFINED_ENUMERATION(),p);
     /* Meta Modelica extensions */
    case META_UNIONTYPE(p) then (SCode.R_UNIONTYPE(),p);
    case  META_RECORD(p) then (SCode.R_METARECORD(p, 0, false, false),p);
  end match;
end stateToSCodeRestriction;

annotation(__OpenModelica_Interface="frontend");
end ClassInf;

