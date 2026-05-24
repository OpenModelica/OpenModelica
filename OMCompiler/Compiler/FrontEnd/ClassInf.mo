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

encapsulated package ClassInf
" file:        ClassInf.mo
  package:     ClassInf
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
    list<String> typeVars;
  end META_UNIONTYPE;

  record META_ARRAY
    Absyn.Path path;
  end META_ARRAY;

  record META_POLYMORPHIC
    Absyn.Path path;
  end META_POLYMORPHIC;
  /*---------------------*/
end State;

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

annotation(__OpenModelica_Interface="frontend_types");
end ClassInf;
