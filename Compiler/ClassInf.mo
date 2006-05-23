package ClassInf "
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

 Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

 Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  
  file:	 ClassInf.rml
  module:      ClassInf
  description: Class restrictions
 
  RCS:	 $Id$
 
  This module deals with class inference, i.e. determining if a
  class definition adhers to one of the class restrictions, and, if
  specifically declared in a restrictied form, if it breaks that
  restriction.
 
  The inference is implemented as a finite state machine.  The
  function `start\' initializes a new machine, and the function
  `trans\' signals transitions in the machine.  Finally, the state
  can be checked agains a restriction with the `valid\' function.
  
"

public import OpenModelica.Compiler.SCode;
public import OpenModelica.Compiler.Absyn;

public 
uniontype State "- Machine states, the string contains the classname."
  record UNKNOWN
    String string;
  end UNKNOWN;

  record MODEL
    String string;
  end MODEL;

  record RECORD
    String string;
  end RECORD;

  record BLOCK
    String string;
  end BLOCK;

  record CONNECTOR
    String string;
  end CONNECTOR;

  record TYPE
    String string;
  end TYPE;

  record PACKAGE
    String string;
  end PACKAGE;

  record FUNCTION
    String string;
  end FUNCTION;

  record ENUMERATION
    String string;
  end ENUMERATION;

  record HAS_EQUATIONS
    String string;
  end HAS_EQUATIONS;

  record IS_NEW
    String string;
  end IS_NEW;

  record TYPE_INTEGER
    String string;
  end TYPE_INTEGER;

  record TYPE_REAL
    String string;
  end TYPE_REAL;

  record TYPE_STRING
    String string;
  end TYPE_STRING;

  record TYPE_BOOL
    String string;
  end TYPE_BOOL;

  record TYPE_ENUM
    String string;
  end TYPE_ENUM;

	record EXTERNAL_OBJ
	  Absyn.Path fullClassName;
	end EXTERNAL_OBJ;
end State;

public 
uniontype Event "- Events"
  record FOUND_EQUATION "There are definitions inside the current definition" end FOUND_EQUATION;

  record NEWDEF "This is not a derived class The `Event\' type contains the different events during" end NEWDEF;

end Event;

protected import OpenModelica.Compiler.Print;

protected import OpenModelica.Compiler.Error;

public function printStateStr "adrpo -- not used
with \"Absyn.rml\"

  - Printing
  
  Some functions for printing error and debug information about the
  state machine.
 
  The code is excluded from the report.
"
  input State inState;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inState)
    local String s;
    case UNKNOWN(string = s) then "unknown"; 
    case MODEL(string = s) then "model"; 
    case RECORD(string = s) then "record"; 
    case BLOCK(string = s) then "block"; 
    case CONNECTOR(string = s) then "connector"; 
    case TYPE(string = s) then "type"; 
    case PACKAGE(string = s) then "package"; 
    case FUNCTION(string = s) then "function"; 
    case TYPE_INTEGER(string = s) then "Integer"; 
    case TYPE_REAL(string = s) then "Real"; 
    case TYPE_STRING(string = s) then "String"; 
    case TYPE_BOOL(string = s) then "Boolean"; 
    case IS_NEW(string = s) then "new def"; 
    case HAS_EQUATIONS(string = s) then "has eqn"; 
    case EXTERNAL_OBJ(_) then "ExternalObject"; 
  end matchcontinue;
end printStateStr;

public function printState
  input State inState;
algorithm 
  _:=
  matchcontinue (inState)
    local String s;
    case UNKNOWN(string = s)
      equation 
        Print.printBuf("UNKNOWN ");
        Print.printBuf(s);
      then
        ();
    case MODEL(string = s)
      equation 
        Print.printBuf("MODEL ");
        Print.printBuf(s);
      then
        ();
    case RECORD(string = s)
      equation 
        Print.printBuf("RECORD ");
        Print.printBuf(s);
      then
        ();
    case BLOCK(string = s)
      equation 
        Print.printBuf("BLOCK ");
        Print.printBuf(s);
      then
        ();
    case CONNECTOR(string = s)
      equation 
        Print.printBuf("CONNECTOR ");
        Print.printBuf(s);
      then
        ();
    case TYPE(string = s)
      equation 
        Print.printBuf("TYPE ");
        Print.printBuf(s);
      then
        ();
    case PACKAGE(string = s)
      equation 
        Print.printBuf("PACKAGE ");
        Print.printBuf(s);
      then
        ();
    case FUNCTION(string = s)
      equation 
        Print.printBuf("FUNCTION ");
        Print.printBuf(s);
      then
        ();
    case TYPE_INTEGER(string = s)
      equation 
        Print.printBuf("TYPE_INTEGER ");
        Print.printBuf(s);
      then
        ();
    case TYPE_REAL(string = s)
      equation 
        Print.printBuf("TYPE_REAL ");
        Print.printBuf(s);
      then
        ();
    case TYPE_STRING(string = s)
      equation 
        Print.printBuf("TYPE_STRING ");
        Print.printBuf(s);
      then
        ();
    case TYPE_BOOL(string = s)
      equation 
        Print.printBuf("TYPE_BOOL ");
        Print.printBuf(s);
      then
        ();
    case IS_NEW(string = s)
      equation 
        Print.printBuf("IS_NEW ");
        Print.printBuf(s);
      then
        ();
    case HAS_EQUATIONS(string = s)
      equation 
        Print.printBuf("HAS_EQUATIONS ");
        Print.printBuf(s);
      then
        ();
  end matchcontinue;
end printState;

public function getStateName "function: getStateName
  
  Returns the classname of the state.
"
  input State inState;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inState)
    local String s;
      Absyn.Path path;
    case UNKNOWN(string = s) then s; 
    case MODEL(string = s) then s; 
    case RECORD(string = s) then s; 
    case BLOCK(string = s) then s; 
    case CONNECTOR(string = s) then s; 
    case TYPE(string = s) then s; 
    case PACKAGE(string = s) then s; 
    case FUNCTION(string = s) then s; 
    case TYPE_INTEGER(string = s) then s; 
    case TYPE_REAL(string = s) then s; 
    case TYPE_STRING(string = s) then s; 
    case TYPE_BOOL(string = s) then s; 
    case IS_NEW(string = s) then s; 
    case HAS_EQUATIONS(string = s) then s; 
    case EXTERNAL_OBJ(path) then Absyn.pathString(path); 
  end matchcontinue;
end getStateName;

protected function printEvent "function: printEvent"
  input Event inEvent;
algorithm 
  _:=
  matchcontinue (inEvent)
    case FOUND_EQUATION()
      equation 
        Print.printBuf("FOUND_EQUATION");
      then
        ();
    case NEWDEF()
      equation 
        Print.printBuf("NEWDEF");
      then
        ();
  end matchcontinue;
end printEvent;

public function start "!includecode
  - Transitions
  
  This is the state machine initialization function.
"
  input SCode.Restriction inRestriction;
  input String inString;
  output State outState;
algorithm 
  outState:=
  matchcontinue (inRestriction,inString)
    local String s;
    case (SCode.R_CLASS(),s) then UNKNOWN(s); 
    case (SCode.R_MODEL(),s) then MODEL(s); 
    case (SCode.R_RECORD(),s) then RECORD(s); 
    case (SCode.R_BLOCK(),s) then BLOCK(s); 
    case (SCode.R_CONNECTOR(),s) then CONNECTOR(s); 
    case (SCode.R_TYPE(),s) then TYPE(s); 
    case (SCode.R_PACKAGE(),s) then PACKAGE(s); 
    case (SCode.R_FUNCTION(),s) then FUNCTION(s); 
    case (SCode.R_EXT_FUNCTION(),s) then FUNCTION(s); 
    case (SCode.R_ENUMERATION(),s) then ENUMERATION(s); 
    case (SCode.R_PREDEFINED_INT(),s) then TYPE_INTEGER(s); 
    case (SCode.R_PREDEFINED_REAL(),s) then TYPE_REAL(s); 
    case (SCode.R_PREDEFINED_STRING(),s) then TYPE_STRING(s); 
    case (SCode.R_PREDEFINED_BOOL(),s) then TYPE_BOOL(s); 
    case (SCode.R_PREDEFINED_ENUM(),s) then TYPE_ENUM(s); 
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
      String s;
      State st;
      Event ev;
    case (UNKNOWN(string = s),NEWDEF()) then IS_NEW(s);  /* Event `NEWDEF\' */ 
    case (MODEL(string = s),NEWDEF()) then MODEL(s); 
    case (RECORD(string = s),NEWDEF()) then RECORD(s); 
    case (BLOCK(string = s),NEWDEF()) then BLOCK(s); 
    case (CONNECTOR(string = s),NEWDEF()) then CONNECTOR(s); 
    case (TYPE(string = s),NEWDEF())
      equation 
        Error.addMessage(Error.TYPE_NOT_FROM_PREDEFINED, {s});
      then
        fail();
    case (PACKAGE(string = s),NEWDEF()) then PACKAGE(s); 
    case (FUNCTION(string = s),NEWDEF()) then FUNCTION(s); 
    case (ENUMERATION(string = s),NEWDEF()) then ENUMERATION(s); 
    case (IS_NEW(string = s),NEWDEF()) then IS_NEW(s); 
    case (TYPE_INTEGER(string = s),NEWDEF()) then TYPE_INTEGER(s); 
    case (TYPE_REAL(string = s),NEWDEF()) then TYPE_REAL(s); 
    case (TYPE_STRING(string = s),NEWDEF()) then TYPE_STRING(s); 
    case (TYPE_BOOL(string = s),NEWDEF()) then TYPE_BOOL(s); 
    case (TYPE_ENUM(string = s),NEWDEF()) then TYPE_ENUM(s);  /* Event `FOUND_EQUATION\' */ 
    case (UNKNOWN(string = s),FOUND_EQUATION()) then HAS_EQUATIONS(s); 
    case (IS_NEW(string = s),FOUND_EQUATION()) then HAS_EQUATIONS(s); 
    case (MODEL(string = s),FOUND_EQUATION()) then MODEL(s); 
    case (RECORD(string = s),FOUND_EQUATION())
      equation 
        Error.addMessage(Error.EQUATION_IN_RECORD, {s});
      then
        fail();
    case (BLOCK(string = s),FOUND_EQUATION()) then BLOCK(s); 
    case (CONNECTOR(string = s),FOUND_EQUATION())
      equation 
        Error.addMessage(Error.EQUATION_IN_CONNECTOR, {s});
      then
        fail();
    case (TYPE(string = s),FOUND_EQUATION()) then fail(); 
    case (PACKAGE(string = s),FOUND_EQUATION()) then fail();  /* CORRECT? */ 
    case (FUNCTION(string = s),FOUND_EQUATION()) then fail(); 
    case (HAS_EQUATIONS(string = s),FOUND_EQUATION()) then HAS_EQUATIONS(s); 
    case (st,ev)
      equation 
        Print.printBuf("- trans failed: ");
        printState(st);
        Print.printBuf(", ");
        printEvent(ev);
        Print.printBuf("\n");
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
  _:=
  matchcontinue (inState,inRestriction)
    local String s;
    case (UNKNOWN(string = s),_) then (); 
    case (IS_NEW(string = s),SCode.R_CLASS()) then (); 
    case (HAS_EQUATIONS(string = s),SCode.R_CLASS()) then (); 
    case (MODEL(string = s),SCode.R_MODEL()) then (); 
    case (IS_NEW(string = s),SCode.R_MODEL()) then (); 
    case (HAS_EQUATIONS(string = s),SCode.R_MODEL()) then (); 
    case (RECORD(string = s),SCode.R_RECORD()) then (); 
    case (IS_NEW(string = s),SCode.R_RECORD()) then (); 
    case (BLOCK(string = s),SCode.R_BLOCK()) then (); 
    case (HAS_EQUATIONS(string = s),SCode.R_BLOCK()) then (); 
    case (CONNECTOR(string = _),SCode.R_CONNECTOR()) then (); 
    case (IS_NEW(string = _),SCode.R_CONNECTOR()) then (); 
    case (TYPE_INTEGER(string = _),SCode.R_CONNECTOR()) then (); 
    case (TYPE_REAL(string = _),SCode.R_CONNECTOR()) then (); 
    case (TYPE_STRING(string = _),SCode.R_CONNECTOR()) then (); 
    case (TYPE_BOOL(string = _),SCode.R_CONNECTOR()) then (); 
    case (TYPE(string = s),SCode.R_TYPE()) then (); 
    case (TYPE_INTEGER(string = s),SCode.R_TYPE()) then (); 
    case (TYPE_REAL(string = s),SCode.R_TYPE()) then (); 
    case (TYPE_STRING(string = s),SCode.R_TYPE()) then (); 
    case (TYPE_BOOL(string = s),SCode.R_TYPE()) then (); 
    case (IS_NEW(string = s),SCode.R_PACKAGE()) then (); 
    case (PACKAGE(string = s),SCode.R_PACKAGE()) then (); 
    case (IS_NEW(string = s),SCode.R_FUNCTION()) then (); 
    case (FUNCTION(string = s),SCode.R_FUNCTION()) then (); 
  end matchcontinue;
end valid;

public function assertValid "function: assertValid
 
  This function has the same semantical meaning as the function
  `valid\'.  However, it prints an error message when it fails.
"
  input State inState;
  input SCode.Restriction inRestriction;
algorithm 
  _:=
  matchcontinue (inState,inRestriction)
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
        str = getStateName(st);
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
    case (UNKNOWN(string = _),(UNKNOWN(string = _) :: rest)) then true; 
    case (MODEL(string = _),(MODEL(string = _) :: rest)) then true; 
    case (RECORD(string = _),(RECORD(string = _) :: rest)) then true; 
    case (BLOCK(string = _),(BLOCK(string = _) :: rest)) then true; 
    case (CONNECTOR(string = _),(CONNECTOR(string = _) :: rest)) then true; 
    case (TYPE(string = _),(TYPE(string = _) :: rest)) then true; 
    case (PACKAGE(string = _),(PACKAGE(string = _) :: rest)) then true; 
    case (FUNCTION(string = _),(FUNCTION(string = _) :: rest)) then true; 
    case (ENUMERATION(string = _),(ENUMERATION(string = _) :: rest)) then true; 
    case (HAS_EQUATIONS(string = _),(HAS_EQUATIONS(string = _) :: rest)) then true; 
    case (IS_NEW(string = _),(IS_NEW(string = _) :: rest)) then true; 
    case (TYPE_INTEGER(string = _),(TYPE_INTEGER(string = _) :: rest)) then true; 
    case (TYPE_REAL(string = _),(TYPE_REAL(string = _) :: rest)) then true; 
    case (TYPE_STRING(string = _),(TYPE_STRING(string = _) :: rest)) then true; 
    case (TYPE_BOOL(string = _),(TYPE_BOOL(string = _) :: rest)) then true; 
    case (TYPE_ENUM(string = _),(TYPE_ENUM(string = _) :: rest)) then true; 
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
    case FUNCTION(string = _) then (); 
  end matchcontinue;
end isFunction;

public function isConnector "function: isConnector
 
  Fails for states that are not CONNECTOR.
"
  input State inState;
algorithm 
  _:=
  matchcontinue (inState)
    case CONNECTOR(string = _) then (); 
  end matchcontinue;
end isConnector;
end ClassInf;

