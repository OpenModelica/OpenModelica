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

package ClassInf
" file:	 ClassInf.mo
  package:      ClassInf
  description: Class restrictions

  RCS:	 $Id$

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

public
uniontype State "- Machine states, the string contains the classname."
  record UNKNOWN
    Absyn.Path path;
  end UNKNOWN;

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
  end FUNCTION;

  record ENUMERATION
    Absyn.Path path;
  end ENUMERATION;

  record HAS_EQUATIONS
    Absyn.Path path;
  end HAS_EQUATIONS;

  record IS_NEW
    Absyn.Path path;
  end IS_NEW;

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

  record UNIONTYPE
    Absyn.Path path;
  end UNIONTYPE;

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

  record NEWDEF "A definition with elements, i.e. a long definition" end NEWDEF;

  record FOUND_COMPONENT " A Definition that contains components"
    String name "name of the component";
  end FOUND_COMPONENT;

end Event;

protected import Debug;
protected import Print;
protected import Error;
protected import RTOpts;

public function printStateStr "- Printing

  Some functions for printing error and debug information about the
  state machine.

  The code is excluded from the report.
"
  input State inState;
  output String outString;
algorithm
  outString:=
  matchcontinue (inState)
    local Absyn.Path p;
    case UNKNOWN(path = p) then "unknown";
    case MODEL(path = p) then "model";
    case RECORD(path = p) then "record";
    case BLOCK(path = p) then "block";
    case CONNECTOR(path = p) then "connector";
    case TYPE(path = p) then "type";
    case PACKAGE(path = p) then "package";
    case FUNCTION(path = p) then "function";
    case TYPE_INTEGER(path = p) then "Integer";
    case TYPE_REAL(path = p) then "Real";
    case TYPE_STRING(path = p) then "String";
    case TYPE_BOOL(path = p) then "Boolean";
    case IS_NEW(path = p) then "new def";
    case HAS_EQUATIONS(path = p) then "has eqn";
    case EXTERNAL_OBJ(_) then "ExternalObject";
    case META_TUPLE(p) then "tuple";
    case META_LIST(p) then "list";
    case META_OPTION(p) then "Option";
    case META_RECORD(p) then "meta_record";
    case META_POLYMORPHIC(p) then "polymorphic";
    case META_ARRAY(p) then "meta_array";
    case UNIONTYPE(p) then "uniontype";
    case _ then "#printStateStr failed#";
  end matchcontinue;
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
    case IS_NEW(path = p)
      equation
        Print.printBuf("IS_NEW ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
    case HAS_EQUATIONS(path = p)
      equation
        Print.printBuf("HAS_EQUATIONS ");
        Print.printBuf(Absyn.pathString(p));
      then
        ();
  end matchcontinue;
end printState;

public function getStateName "function: getStateName

  Returns the classname of the state.
"
  input State inState;
  output Absyn.Path outPath;
algorithm
  outPath :=
  matchcontinue (inState)
    local String s;
      Absyn.Path p;
    case UNKNOWN(path = p) then p;
    case MODEL(path = p) then p;
    case RECORD(path = p) then p;
    case BLOCK(path = p) then p;
    case CONNECTOR(path = p) then p;
    case TYPE(path = p) then p;
    case PACKAGE(path = p) then p;
    case FUNCTION(path = p) then p;
    case ENUMERATION(path = p) then p;
      
    case HAS_EQUATIONS(path = p) then p;
    case IS_NEW(path = p) then p;
            
    case TYPE_INTEGER(path = p) then p;
    case TYPE_REAL(path = p) then p;
    case TYPE_STRING(path = p) then p;
    case TYPE_BOOL(path = p) then p;
    case TYPE_ENUM(path = p) then p;
      
    case EXTERNAL_OBJ(p) then p;
    
    case META_TUPLE(p) then p;
    case META_LIST(p) then p;
    case META_OPTION(p) then p;
    case META_RECORD(p) then p;
    case UNIONTYPE(p) then p;
    case META_ARRAY(p) then p;      
    case META_POLYMORPHIC(p) then p;
      
    case _ then Absyn.IDENT("#getStateName failed#");
  end matchcontinue;
end getStateName;

protected function printEventStr
  input Event inEvent;
  output String str;
algorithm
  str := matchcontinue (inEvent)
    local
      String name;
    case FOUND_EQUATION() then "FOUND_EQUATION";
    case NEWDEF() then "NEWDEF";
    case FOUND_COMPONENT(name) then "FOUND_COMPONENT(" +& name +& ")";
  end matchcontinue;
end printEventStr;

public function start "!includecode
  - Transitions

  This is the state machine initialization function.
"
  input SCode.Restriction inRestriction;
  input Absyn.Path inPath;
  output State outState;
algorithm
  outState:=
  matchcontinue (inRestriction,inPath)
    local Absyn.Path p; Boolean isExpandable;
    case (SCode.R_CLASS(),p) then UNKNOWN(p);
    case (SCode.R_MODEL(),p) then MODEL(p);
    case (SCode.R_RECORD(),p) then RECORD(p);
    case (SCode.R_BLOCK(),p) then BLOCK(p);
    case (SCode.R_CONNECTOR(isExpandable),p) then CONNECTOR(p,isExpandable);
    case (SCode.R_TYPE(),p) then TYPE(p);
    case (SCode.R_PACKAGE(),p) then PACKAGE(p);
    case (SCode.R_FUNCTION(),p) then FUNCTION(p);
    case (SCode.R_EXT_FUNCTION(),p) then FUNCTION(p);
    case (SCode.R_ENUMERATION(),p) then ENUMERATION(p);
    case (SCode.R_PREDEFINED_INT(),p) then TYPE_INTEGER(p);
    case (SCode.R_PREDEFINED_REAL(),p) then TYPE_REAL(p);
    case (SCode.R_PREDEFINED_STRING(),p) then TYPE_STRING(p);
    case (SCode.R_PREDEFINED_BOOL(),p) then TYPE_BOOL(p);
    case (SCode.R_PREDEFINED_ENUM(),p) then TYPE_ENUM(p);
     /* Meta Modelica extensions */
    case (SCode.R_UNIONTYPE(),p) then UNIONTYPE(p);
    case (SCode.R_METARECORD(_, _),p) then META_RECORD(p);
  end matchcontinue;
end start;

public function trans "function: trans

  This is the state machine transition function.  It describes the
  transitions between states at different events.
"
  input State inState;
  input Event inEvent;
  output State outState;
algorithm
  outState:=
  matchcontinue (inState,inEvent)
    local
      Absyn.Path p;
      State st;
      Event ev;
      Boolean isExpandable;
      String s;
    case (UNKNOWN(path = p),NEWDEF()) then IS_NEW(p);  /* Event `NEWDEF\' */
    case (MODEL(path = p),NEWDEF()) then MODEL(p);
    case (RECORD(path = p),NEWDEF()) then RECORD(p);
    case (BLOCK(path = p),NEWDEF()) then BLOCK(p);
    case (CONNECTOR(path = p,isExpandable=isExpandable),NEWDEF()) then CONNECTOR(p,isExpandable);
    case (TYPE(path = p),NEWDEF()) then TYPE(p); // A type can be constructed with long definition
     case (PACKAGE(path = p),NEWDEF()) then PACKAGE(p);
    case (FUNCTION(path = p),NEWDEF()) then FUNCTION(p);
    case (ENUMERATION(path = p),NEWDEF()) then ENUMERATION(p);
    case (IS_NEW(path = p),NEWDEF()) then IS_NEW(p);
    case (TYPE_INTEGER(path = p),NEWDEF()) then TYPE_INTEGER(p);
    case (TYPE_REAL(path = p),NEWDEF()) then TYPE_REAL(p);
    case (TYPE_STRING(path = p),NEWDEF()) then TYPE_STRING(p);
    case (TYPE_BOOL(path = p),NEWDEF()) then TYPE_BOOL(p);
    case (TYPE_ENUM(path = p),NEWDEF()) then TYPE_ENUM(p);  /* Event `FOUND_EQUATION\' */
    case (UNIONTYPE(path = p),NEWDEF()) then UNIONTYPE(p);  // Added 2009-05-11. sjoelund
    case (META_RECORD(path = p),NEWDEF()) then META_RECORD(p);  // Added 2009-08-18. sjoelund

   /* Event 'FOUND_COMPONENT' */
    case (UNKNOWN(path = p),FOUND_COMPONENT(name = _)) then IS_NEW(p);  /* Event `NEWDEF\' */
    case (MODEL(path = p),FOUND_COMPONENT(name = _)) then MODEL(p);
    case (RECORD(path = p),FOUND_COMPONENT(name = _)) then RECORD(p);
    case (BLOCK(path = p),FOUND_COMPONENT(name = _)) then BLOCK(p);
    case (CONNECTOR(path = p,isExpandable = isExpandable),FOUND_COMPONENT(name = _)) then CONNECTOR(p,isExpandable);
    case (TYPE(path = p),FOUND_COMPONENT(name = s))
      equation
        true = isBasicTypeComponentName(s);
      then TYPE(p);
    case (TYPE(path = p),FOUND_COMPONENT(name = _))  // A type can not contain new components
      equation
        s = Absyn.pathString(p);
        Error.addMessage(Error.TYPE_NOT_FROM_PREDEFINED, {s});
      then
        fail();
    /* adrpo 2009-05-15: type Orientation can contain equalityConstraint function! */
    //case (TYPE(path = p),FOUND_COMPONENT()) then TYPE(p);
    case (PACKAGE(path = p),FOUND_COMPONENT(name = _)) then PACKAGE(p);
    case (FUNCTION(path = p),FOUND_COMPONENT(name = _)) then FUNCTION(p);
    case (ENUMERATION(path = p),FOUND_COMPONENT(name = _)) then ENUMERATION(p);
    case (IS_NEW(path = p),FOUND_COMPONENT(name = _)) then IS_NEW(p);
    case (TYPE_INTEGER(path = p),FOUND_COMPONENT(name = _)) then TYPE_INTEGER(p);
    case (TYPE_REAL(path = p),FOUND_COMPONENT(name = _)) then TYPE_REAL(p);
    case (TYPE_STRING(path = p),FOUND_COMPONENT(name = _)) then TYPE_STRING(p);
    case (TYPE_BOOL(path = p),FOUND_COMPONENT(name = _)) then TYPE_BOOL(p);
    case (TYPE_ENUM(path = p),FOUND_COMPONENT(name = _)) then TYPE_ENUM(p);
    case (META_RECORD(path = p),FOUND_COMPONENT(name = _)) then META_RECORD(p);  // Added 2009-08-19. sjoelund

   /* Event `FOUND_EQUATION\' */
    case (UNKNOWN(path = p),FOUND_EQUATION()) then HAS_EQUATIONS(p);
    case (IS_NEW(path = p),FOUND_EQUATION()) then HAS_EQUATIONS(p);
    case (MODEL(path = p),FOUND_EQUATION()) then MODEL(p);
    case (RECORD(path = p),FOUND_EQUATION())
      equation
        s = Absyn.pathString(p);
        Error.addMessage(Error.EQUATION_IN_RECORD, {s});
      then
        fail();
    case (BLOCK(path = p),FOUND_EQUATION()) then BLOCK(p);
    case (CONNECTOR(path = p,isExpandable = isExpandable),FOUND_EQUATION())
      equation
        s = Absyn.pathString(p);
        Error.addMessage(Error.EQUATION_IN_CONNECTOR, {s});
      then
        fail();
    case (TYPE(path = p),FOUND_EQUATION()) then fail();
    case (PACKAGE(path = p),FOUND_EQUATION()) then fail();
    case (FUNCTION(path = p),FOUND_EQUATION()) then fail();
    case (HAS_EQUATIONS(path = p),FOUND_EQUATION()) then HAS_EQUATIONS(p);
    case (st,ev)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- ClassInf.trans failed: " +& printStateStr(st) +& ", " +& printEventStr(ev));
      then
        fail();
  end matchcontinue;
end trans;

public function valid "function: valid

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
  _ := matchcontinue (inState,inRestriction)
    local Absyn.Path p;
    
    case (UNKNOWN(path = p),_) then ();
    
    case (IS_NEW(path = p),SCode.R_CLASS()) then ();
    case (HAS_EQUATIONS(path = p),SCode.R_CLASS()) then ();
    
    case (MODEL(path = p),SCode.R_MODEL()) then ();
    case (IS_NEW(path = p),SCode.R_MODEL()) then ();
    case (HAS_EQUATIONS(path = p),SCode.R_MODEL()) then ();
    
    case (RECORD(path = p),SCode.R_RECORD()) then ();
    case (IS_NEW(path = p),SCode.R_RECORD()) then ();
    
    case (BLOCK(path = p),SCode.R_BLOCK()) then ();
    case (HAS_EQUATIONS(path = p),SCode.R_BLOCK()) then ();
    
    case (CONNECTOR(path = _,isExpandable=false),SCode.R_CONNECTOR(false)) then ();
    case (CONNECTOR(path = _,isExpandable=true),SCode.R_CONNECTOR(true)) then ();    
    case (IS_NEW(path = _),SCode.R_CONNECTOR(_)) then ();
    case (TYPE_INTEGER(path = _),SCode.R_CONNECTOR(_)) then ();
    case (TYPE_REAL(path = _),SCode.R_CONNECTOR(_)) then ();
    case (TYPE_STRING(path = _),SCode.R_CONNECTOR(_)) then ();
    case (TYPE_BOOL(path = _),SCode.R_CONNECTOR(_)) then ();
    case (TYPE_ENUM(path = _),SCode.R_CONNECTOR(_)) then (); // used in Modelica.Electrical.Digital where we have an enum as a connector
    case (ENUMERATION(p),SCode.R_CONNECTOR(_)) then ();      // used in Modelica.Electrical.Digital where we have an enum as a connector
    
    case (TYPE(path = p),SCode.R_TYPE()) then ();
    case (TYPE_INTEGER(path = p),SCode.R_TYPE()) then ();
    case (TYPE_REAL(path = p),SCode.R_TYPE()) then ();
    case (TYPE_STRING(path = p),SCode.R_TYPE()) then ();
    case (TYPE_BOOL(path = p),SCode.R_TYPE()) then ();
    case (TYPE_ENUM(path = p),SCode.R_TYPE()) then ();
    case (ENUMERATION(p),SCode.R_TYPE()) then ();
    
    case (IS_NEW(path = p),SCode.R_PACKAGE()) then ();
    case (PACKAGE(path = p),SCode.R_PACKAGE()) then ();
    case (IS_NEW(path = p),SCode.R_FUNCTION()) then ();
    case (FUNCTION(path = p),SCode.R_FUNCTION()) then ();
    case (META_TUPLE(p),SCode.R_TYPE()) then ();
    case (META_LIST(p),SCode.R_TYPE()) then ();
    case (META_OPTION(p),SCode.R_TYPE()) then ();
    case (META_RECORD(p),SCode.R_TYPE()) then ();
    case (UNIONTYPE(p),SCode.R_TYPE()) then ();    

  end matchcontinue;
end valid;

public function assertValid "function: assertValid
  This function has the same semantical meaning as the function
  `valid\'.  However, it prints an error message when it fails."
  input State inState;
  input SCode.Restriction inRestriction;
algorithm
  _ := matchcontinue (inState,inRestriction)
    local
      State st;
      SCode.Restriction re;
      String str;
    case (st,re)
      equation
        valid(st, re);
      then
        ();
    case (st,re)
      equation
        Print.printErrorBuf("# Restriction violation: ");
        str = Absyn.pathString(getStateName(st));
        Print.printErrorBuf(str);
        Print.printErrorBuf(" is not a ");
        str = SCode.restrString(re);
        Print.printErrorBuf(str);
        Print.printErrorBuf("\n");
      then
        fail();
  end matchcontinue;
end assertValid;

public function matchingState "function: matchingState

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
    case (st,{}) then false;
    case (UNKNOWN(path = _),(UNKNOWN(path = _) :: rest)) then true;
    case (MODEL(path = _),(MODEL(path = _) :: rest)) then true;
    case (RECORD(path = _),(RECORD(path = _) :: rest)) then true;
    case (BLOCK(path = _),(BLOCK(path = _) :: rest)) then true;
    case (CONNECTOR(path = _),(CONNECTOR(path = _) :: rest)) then true;
    case (TYPE(path = _),(TYPE(path = _) :: rest)) then true;
    case (PACKAGE(path = _),(PACKAGE(path = _) :: rest)) then true;
    case (FUNCTION(path = _),(FUNCTION(path = _) :: rest)) then true;
    case (ENUMERATION(path = _),(ENUMERATION(path = _) :: rest)) then true;
    case (HAS_EQUATIONS(path = _),(HAS_EQUATIONS(path = _) :: rest)) then true;
    case (IS_NEW(path = _),(IS_NEW(path = _) :: rest)) then true;
    case (TYPE_INTEGER(path = _),(TYPE_INTEGER(path = _) :: rest)) then true;
    case (TYPE_REAL(path = _),(TYPE_REAL(path = _) :: rest)) then true;
    case (TYPE_STRING(path = _),(TYPE_STRING(path = _) :: rest)) then true;
    case (TYPE_BOOL(path = _),(TYPE_BOOL(path = _) :: rest)) then true;
    case (TYPE_ENUM(path = _),(TYPE_ENUM(path = _) :: rest)) then true;
    case (st,(first :: rest))
      equation
        res = matchingState(st, rest);
      then
        res;
  end matchcontinue;
end matchingState;

public function isFunction "function: isFunction

  Fails for states that are not FUNCTION.
"
  input State inState;
algorithm
  _:=
  matchcontinue (inState)
    case FUNCTION(path = _) then ();
  end matchcontinue;
end isFunction;

public function isConnector "function: isConnector

  Fails for states that are not CONNECTOR.
"
  input State inState;
algorithm
  _:=
  matchcontinue (inState)
    case CONNECTOR(path = _) then ();
  end matchcontinue;
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
  "stateSelect"  
};

public function isBasicTypeComponentName
"Returns true if the name can be a component of a builtin type"
  input String name;
  output Boolean res;
algorithm
  res := listMember(name,basicTypeMods);
end isBasicTypeComponentName;

end ClassInf;

