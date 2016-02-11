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


encapsulated package NFBuiltin
" file:        NFBuiltin.mo
  package:     NFBuiltin
  description: Builtin definitions.


  Definitions for various builtin Modelica types and variables that can't be
  defined by ModelicaBuiltin.mo.
  "

public import Absyn;
public import DAE;
public import SCode;

// Default parts of the declarations for builtin elements and types:
public constant SCode.Prefixes BUILTIN_PREFIXES = SCode.PREFIXES(
  SCode.PUBLIC(), SCode.NOT_REDECLARE(), SCode.NOT_FINAL(),
  Absyn.NOT_INNER_OUTER(), SCode.NOT_REPLACEABLE());

public constant SCode.Attributes BUILTIN_ATTRIBUTES = SCode.ATTR(
  {}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.BIDIR());

public constant SCode.Attributes BUILTIN_CONST_ATTRIBUTES = SCode.ATTR(
  {}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.CONST(), Absyn.BIDIR());

public constant SCode.ClassDef BUILTIN_EMPTY_CLASS = SCode.PARTS(
  {}, {}, {}, {}, {}, {}, {}, NONE());


// Metatypes used to define the builtin types:
public constant Absyn.TypeSpec BUILTIN_REALTYPE_SPEC =
  Absyn.TPATH(Absyn.IDENT("$RealType"), NONE());
public constant Absyn.TypeSpec BUILTIN_INTEGERTYPE_SPEC =
  Absyn.TPATH(Absyn.IDENT("$IntegerType"), NONE());
public constant Absyn.TypeSpec BUILTIN_BOOLEANTYPE_SPEC =
  Absyn.TPATH(Absyn.IDENT("$BooleanType"), NONE());
public constant Absyn.TypeSpec BUILTIN_STRINGTYPE_SPEC =
  Absyn.TPATH(Absyn.IDENT("$StringType"), NONE());
public constant Absyn.TypeSpec BUILTIN_ENUMTYPE_SPEC =
  Absyn.TPATH(Absyn.IDENT("$EnumType"), NONE());
public constant Absyn.TypeSpec BUILTIN_STATESELECT_SPEC =
  Absyn.TPATH(Absyn.IDENT("StateSelect"), NONE());


// Builtin type attributes.
// Generic elements:
public constant SCode.Element BUILTIN_ATTR_QUANTITY = SCode.COMPONENT(
  "quantity", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_STRINGTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_ATTR_UNIT = SCode.COMPONENT(
  "unit", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_STRINGTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_ATTR_DISPLAYUNIT = SCode.COMPONENT(
  "displayUnit", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_STRINGTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_ATTR_FIXED = SCode.COMPONENT(
  "fixed", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_BOOLEANTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_ATTR_STATESELECT = SCode.COMPONENT(
  "stateSelect", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_STATESELECT_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

// Real-specific elements:
public constant SCode.Element BUILTIN_REAL_MIN = SCode.COMPONENT(
  "min", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_REALTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_REAL_MAX = SCode.COMPONENT(
  "max", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_REALTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_REAL_START = SCode.COMPONENT(
  "start", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_REALTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_REAL_NOMINAL = SCode.COMPONENT(
  "nominal", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_REALTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

// Integer-specific elements:
public constant SCode.Element BUILTIN_INTEGER_MIN = SCode.COMPONENT(
  "min", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_INTEGERTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_INTEGER_MAX = SCode.COMPONENT(
  "max", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_INTEGERTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_INTEGER_START = SCode.COMPONENT(
  "start", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_INTEGERTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

// Boolean-specific elements:
public constant SCode.Element BUILTIN_BOOLEAN_START = SCode.COMPONENT(
  "start", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_BOOLEANTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

// String-specific elements:
public constant SCode.Element BUILTIN_STRING_START = SCode.COMPONENT(
  "start", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_STRINGTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

// StateSelect-specific elements:
public constant SCode.Element BUILTIN_ENUM_MIN = SCode.COMPONENT(
  "min", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_ENUM_MAX = SCode.COMPONENT(
  "max", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_ENUM_START = SCode.COMPONENT(
  "start", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_STATESELECT_NEVER = SCode.COMPONENT(
  "never", BUILTIN_PREFIXES, BUILTIN_CONST_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_STATESELECT_AVOID = SCode.COMPONENT(
  "avoid", BUILTIN_PREFIXES, BUILTIN_CONST_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_STATESELECT_DEFAULT = SCode.COMPONENT(
  "default", BUILTIN_PREFIXES, BUILTIN_CONST_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_STATESELECT_PREFER = SCode.COMPONENT(
  "prefer", BUILTIN_PREFIXES, BUILTIN_CONST_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_STATESELECT_ALWAYS = SCode.COMPONENT(
  "always", BUILTIN_PREFIXES, BUILTIN_CONST_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);


// The builtin types:
public constant list<SCode.Element> BUILTIN_REAL_ATTRIBUTES = {
  BUILTIN_ATTR_QUANTITY,
  BUILTIN_ATTR_UNIT,
  BUILTIN_ATTR_DISPLAYUNIT,
  BUILTIN_REAL_MIN,
  BUILTIN_REAL_MAX,
  BUILTIN_REAL_START,
  BUILTIN_ATTR_FIXED,
  BUILTIN_REAL_NOMINAL,
  BUILTIN_ATTR_STATESELECT
};

public constant SCode.Element BUILTIN_REAL = SCode.CLASS("Real",
  SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
  SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
  SCode.noComment,Absyn.dummyInfo);


public constant list<SCode.Element> BUILTIN_INTEGER_ATTRIBUTES = {
  BUILTIN_ATTR_QUANTITY,
  BUILTIN_INTEGER_MIN,
  BUILTIN_INTEGER_MAX,
  BUILTIN_INTEGER_START,
  BUILTIN_ATTR_FIXED
};

public constant SCode.Element BUILTIN_INTEGER = SCode.CLASS("Integer",
  SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
  SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
  SCode.noComment,Absyn.dummyInfo);


public constant list<SCode.Element> BUILTIN_BOOLEAN_ATTRIBUTES = {
  BUILTIN_ATTR_QUANTITY,
  BUILTIN_BOOLEAN_START,
  BUILTIN_ATTR_FIXED
};

public constant SCode.Element BUILTIN_BOOLEAN = SCode.CLASS("Boolean",
  SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
  SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
  SCode.noComment,Absyn.dummyInfo);


public constant list<SCode.Element> BUILTIN_STRING_ATTRIBUTES = {
  BUILTIN_ATTR_QUANTITY,
  BUILTIN_STRING_START
};

public constant SCode.Element BUILTIN_STRING = SCode.CLASS("String",
  SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
  SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
  SCode.noComment,Absyn.dummyInfo);


public constant SCode.Element BUILTIN_STATESELECT = SCode.CLASS("StateSelect",
  SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
  SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
  SCode.noComment, Absyn.dummyInfo);

// Builtin variable time:
public constant SCode.Element BUILTIN_TIME = SCode.COMPONENT("time", SCode.defaultPrefixes,
    SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.INPUT()),
    Absyn.TPATH(Absyn.IDENT("Real"), NONE()), SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);


public constant DAE.Type BUILTIN_TYPE_STATE_SELECT = DAE.T_ENUMERATION(
  NONE(),
  Absyn.IDENT("StateSelect"),
  {"never", "avoid", "default", "prefer", "always"}, {}, {},
  DAE.emptyTypeSource
);

annotation(__OpenModelica_Interface="frontend");
end NFBuiltin;
