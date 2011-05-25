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

encapsulated package Builtin
" file:         Builtin.mo
  package:     Builtin
  description: Builting tyepes and variables

  RCS: $Id$

  This module defines the builtin types, variables and functions in
  Modelica.  The only exported functions are Builtin.initialEnv and
  Builtin.simpleInitialEnv.

  There are several builtin attributes defined in the builtin types, 
  such as unit, start, etc."

public import Absyn;
public import DAE;
public import Env;
public import Error;
public import RTOpts;
public import SCode;

// protected imports
protected import ClassInf;
protected import Debug;
protected import Parser;
protected import Settings;
protected import SCodeUtil;
protected import System;
protected import Util;

/* These imports were used in e.g. MSL 1.6. They should not be here anymore...
   If you need them, add them to the initial environment and recompile; they are not standard Modelica.
  import arcsin = asin;
  import arccos = acos;
  import arctan = atan;
  import ln = log;
*/

// Predefined DAE.Types
// Real arrays
protected constant DAE.Type T_REAL_ARRAY_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_UNKNOWN(), DAE.T_REAL_DEFAULT),NONE());
protected constant DAE.Type T_REAL_ARRAY_1_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(1), DAE.T_REAL_DEFAULT),NONE());
protected constant DAE.Type T_REAL_ARRAY_2_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(2), DAE.T_REAL_DEFAULT),NONE());
protected constant DAE.Type T_REAL_ARRAY_3_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(3), DAE.T_REAL_DEFAULT),NONE());
protected constant DAE.Type T_REAL_ARRAY_4_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(4), DAE.T_REAL_DEFAULT),NONE());
protected constant DAE.Type T_REAL_ARRAY_5_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(5), DAE.T_REAL_DEFAULT),NONE());
protected constant DAE.Type T_REAL_ARRAY_6_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(6), DAE.T_REAL_DEFAULT),NONE());
protected constant DAE.Type T_REAL_ARRAY_7_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(7), DAE.T_REAL_DEFAULT),NONE());
protected constant DAE.Type T_REAL_ARRAY_8_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(8), DAE.T_REAL_DEFAULT),NONE());
protected constant DAE.Type T_REAL_ARRAY_9_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(9), DAE.T_REAL_DEFAULT),NONE());

// Integer arrays
protected constant DAE.Type T_INT_ARRAY_1_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(1), DAE.T_INTEGER_DEFAULT),NONE());
protected constant DAE.Type T_INT_ARRAY_2_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(2), DAE.T_INTEGER_DEFAULT),NONE());
protected constant DAE.Type T_INT_ARRAY_3_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(3), DAE.T_INTEGER_DEFAULT),NONE());
protected constant DAE.Type T_INT_ARRAY_4_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(4), DAE.T_INTEGER_DEFAULT),NONE());
protected constant DAE.Type T_INT_ARRAY_5_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(5), DAE.T_INTEGER_DEFAULT),NONE());
protected constant DAE.Type T_INT_ARRAY_6_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(6), DAE.T_INTEGER_DEFAULT),NONE());
protected constant DAE.Type T_INT_ARRAY_7_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(7), DAE.T_INTEGER_DEFAULT),NONE());
protected constant DAE.Type T_INT_ARRAY_8_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(8), DAE.T_INTEGER_DEFAULT),NONE());
protected constant DAE.Type T_INT_ARRAY_9_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(9), DAE.T_INTEGER_DEFAULT),NONE());

// Boolean array
protected constant DAE.Type T_BOOL_ARRAY_1_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(1), DAE.T_BOOL_DEFAULT),NONE());
protected constant DAE.Type T_BOOL_ARRAY_2_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(2), DAE.T_BOOL_DEFAULT),NONE());
protected constant DAE.Type T_BOOL_ARRAY_3_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(3), DAE.T_BOOL_DEFAULT),NONE());
protected constant DAE.Type T_BOOL_ARRAY_4_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(4), DAE.T_BOOL_DEFAULT),NONE());
protected constant DAE.Type T_BOOL_ARRAY_5_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(5), DAE.T_BOOL_DEFAULT),NONE());
protected constant DAE.Type T_BOOL_ARRAY_6_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(6), DAE.T_BOOL_DEFAULT),NONE());
protected constant DAE.Type T_BOOL_ARRAY_7_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(7), DAE.T_BOOL_DEFAULT),NONE());
protected constant DAE.Type T_BOOL_ARRAY_8_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(8), DAE.T_BOOL_DEFAULT),NONE());
protected constant DAE.Type T_BOOL_ARRAY_9_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(9), DAE.T_BOOL_DEFAULT),NONE());

// String arrays
protected constant DAE.Type T_STRING_ARRAY_1_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(1), DAE.T_STRING_DEFAULT),NONE());
protected constant DAE.Type T_STRING_ARRAY_2_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(2), DAE.T_STRING_DEFAULT),NONE());
protected constant DAE.Type T_STRING_ARRAY_3_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(3), DAE.T_STRING_DEFAULT),NONE());
protected constant DAE.Type T_STRING_ARRAY_4_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(4), DAE.T_STRING_DEFAULT),NONE());
protected constant DAE.Type T_STRING_ARRAY_5_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(5), DAE.T_STRING_DEFAULT),NONE());
protected constant DAE.Type T_STRING_ARRAY_6_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(6), DAE.T_STRING_DEFAULT),NONE());
protected constant DAE.Type T_STRING_ARRAY_7_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(7), DAE.T_STRING_DEFAULT),NONE());
protected constant DAE.Type T_STRING_ARRAY_8_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(8), DAE.T_STRING_DEFAULT),NONE());
protected constant DAE.Type T_STRING_ARRAY_9_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(9), DAE.T_STRING_DEFAULT),NONE());

protected constant DAE.Type T_NOTYPE_ARRAY_1_DEFAULT =
  (DAE.T_ARRAY(DAE.DIM_INTEGER(1), (DAE.T_NOTYPE(),NONE())),NONE());


public constant SCode.Prefixes commonPrefixes = 
  SCode.PREFIXES(
    SCode.PUBLIC(), 
    SCode.NOT_REDECLARE(), 
    SCode.FINAL(), /* make everything here final! */
    Absyn.NOT_INNER_OUTER(), 
    SCode.NOT_REPLACEABLE()); 

protected
constant SCode.Attributes attrConst = SCode.ATTR({},SCode.NOT_FLOW(),SCode.NOT_STREAM(),SCode.CONST(),Absyn.BIDIR()); 
constant SCode.Attributes attrParam = SCode.ATTR({},SCode.NOT_FLOW(),SCode.NOT_STREAM(),SCode.PARAM(),Absyn.BIDIR());

/*
- The primitive types
  These are the primitive types that are used to build the types
  `Real\', `Integer\' etc.
*/
public constant SCode.Element rlType=SCode.CLASS("RealType",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_REAL(),
          SCode.PARTS({},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) " real type ";

public constant SCode.Element intType=SCode.CLASS("IntegerType",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_INTEGER(),
          SCode.PARTS({},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo);

public constant SCode.Element strType=SCode.CLASS("StringType",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_STRING(),
          SCode.PARTS({},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo);

public constant SCode.Element boolType=SCode.CLASS("BooleanType",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_BOOLEAN(),
          SCode.PARTS({},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo);

protected constant SCode.Element enumType=SCode.CLASS("EnumType",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_ENUMERATION(),
          SCode.PARTS({},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo);

protected constant SCode.Element unit=SCode.COMPONENT("unit",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.STRING(""),false))),NONE(),NONE(),Absyn.dummyInfo) "This `unit\' component is used in several places below, and it is
  declared once here to make the definitions below easier to read." ;

protected constant SCode.Element quantity=SCode.COMPONENT("quantity",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.STRING(""),false))),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element displayUnit=SCode.COMPONENT("displayUnit",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.STRING(""),false))),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element min=SCode.COMPONENT("min",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.REAL(-1e+099),false))),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element max=SCode.COMPONENT("max",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.REAL(1e+099),false))),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element realStart=SCode.COMPONENT("start",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.REAL(0.0),false))),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element integerStart=SCode.COMPONENT("start",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("IntegerType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.INTEGER(0),false))),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element stringStart=SCode.COMPONENT("start",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.STRING(""),false))),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element booleanStart=SCode.COMPONENT("start",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("BooleanType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.BOOL(false),false))),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element fixed=SCode.COMPONENT("fixed",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("BooleanType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.BOOL(false),false))),NONE(),NONE(),Absyn.dummyInfo) "Should be true for variables" ;

protected constant SCode.Element nominal=SCode.COMPONENT("nominal",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},NONE()),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element stateSelect=SCode.COMPONENT("stateSelect",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StateSelect"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},
          SOME((
          Absyn.CREF(
          Absyn.CREF_QUAL("StateSelect",{},Absyn.CREF_IDENT("default",{}))),false))),NONE(),NONE(),Absyn.dummyInfo);

protected constant list<SCode.Element> stateSelectComps={
          SCode.COMPONENT("never",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("avoid",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("default",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("prefer",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("always",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),Absyn.dummyInfo)} "The StateSelect enumeration" ;

protected constant SCode.Element stateSelectType=SCode.CLASS("StateSelect",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_ENUMERATION(),
          SCode.PARTS(stateSelectComps,{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "The State Select Type";

public constant SCode.Element ExternalObjectType=SCode.CLASS("ExternalObject",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_CLASS(),
          SCode.PARTS({},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "ExternalObject type" ;

public constant SCode.Element realType=SCode.CLASS("Real",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_REAL(),
          SCode.PARTS({unit,quantity,displayUnit,min,max,realStart,fixed,nominal,
          stateSelect},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "- The `Real\' type" ;

protected constant SCode.Element integerType=SCode.CLASS("Integer",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_INTEGER(),
          SCode.PARTS({quantity,min,max,integerStart,fixed},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "- The `Integer\' type" ;

protected constant SCode.Element stringType=SCode.CLASS("String",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_STRING(),
          SCode.PARTS({quantity,stringStart},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "- The `String\' type" ;

protected constant SCode.Element booleanType=SCode.CLASS("Boolean",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_BOOLEAN(),
          SCode.PARTS({quantity,booleanStart,fixed},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "- The `Boolean\' type" ;

/* The builtin variable time. See also variableIsBuiltin */
protected constant DAE.Var timeVar=DAE.TYPES_VAR("time",
          DAE.ATTR(SCode.NOT_FLOW(),SCode.NOT_STREAM(),SCode.VAR(),Absyn.INPUT(),Absyn.NOT_INNER_OUTER()),
          SCode.PUBLIC(),DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()) "- The `time\' variable" ;

protected constant DAE.Type stringIntInt2string=(
          DAE.T_FUNCTION(
              {
              ("x",DAE.T_STRING_DEFAULT),
              ("y",DAE.T_INTEGER_DEFAULT),
              ("z",DAE.T_INTEGER_DEFAULT)
              },
              DAE.T_STRING_DEFAULT,
              DAE.FUNCTION_ATTRIBUTES_BUILTIN),
              NONE());

protected constant DAE.Type real2real=(
          DAE.T_FUNCTION({("x",DAE.T_REAL_DEFAULT)},DAE.T_REAL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type realReal2real=(
          DAE.T_FUNCTION(
          {("x",DAE.T_REAL_DEFAULT),("y",DAE.T_REAL_DEFAULT)},DAE.T_REAL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type int2int=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type int2bool=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          DAE.T_BOOL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type enumeration2int=(
          DAE.T_FUNCTION({("x",(DAE.T_ENUMERATION(NONE(), Absyn.IDENT(""), {}, {}, {}),NONE()))},
          DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type intInt2int=(
          DAE.T_FUNCTION(
          {("x",DAE.T_INTEGER_DEFAULT),
          ("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type intInt2bool=(
          DAE.T_FUNCTION(
          {("x",DAE.T_INTEGER_DEFAULT),
          ("y",DAE.T_INTEGER_DEFAULT)},DAE.T_BOOL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type bool2bool=(
          DAE.T_FUNCTION({("x",DAE.T_BOOL_DEFAULT)},DAE.T_BOOL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type real2bool=(
          DAE.T_FUNCTION({("x",DAE.T_REAL_DEFAULT)},DAE.T_BOOL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type realReal2bool=(
          DAE.T_FUNCTION(
          {("x",DAE.T_REAL_DEFAULT),("y",DAE.T_REAL_DEFAULT)},DAE.T_BOOL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type realRealReal2Real=(
          DAE.T_FUNCTION(
          {("x",DAE.T_REAL_DEFAULT),("y",DAE.T_REAL_DEFAULT),("z",DAE.T_REAL_DEFAULT)},DAE.T_REAL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type anyNonExpandableConnector2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          (DAE.T_ANYTYPE(SOME(ClassInf.CONNECTOR(Absyn.IDENT("$dummy$"),false))),NONE()))},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type anyExpandableConnector2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          (DAE.T_ANYTYPE(SOME(ClassInf.CONNECTOR(Absyn.IDENT("$dummy$"),true))),NONE()))},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type vectorVector2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_1_DEFAULT),
          ("y",
          T_INT_ARRAY_1_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type vectorVector2real=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_1_DEFAULT), ("y", T_REAL_ARRAY_1_DEFAULT)}, 
            DAE.T_REAL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type int2array1dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type int2array2dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type int2array3dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_3_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type int2array4dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_4_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type int2array5dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_5_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type int2array6dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_6_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type int2array7dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_7_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type int2array8dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_8_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n1int2arrayint=(
          DAE.T_FUNCTION({("x1",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n2int2arrayint=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_INTEGER_DEFAULT),
          ("x2",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n3int2arrayint=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_INTEGER_DEFAULT),
          ("x2",DAE.T_INTEGER_DEFAULT),("x3",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_3_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n4int2arrayint=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_INTEGER_DEFAULT),
          ("x2",DAE.T_INTEGER_DEFAULT),("x3",DAE.T_INTEGER_DEFAULT),("x4",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_4_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n5int2arrayint=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_INTEGER_DEFAULT),
          ("x2",DAE.T_INTEGER_DEFAULT),("x3",DAE.T_INTEGER_DEFAULT),("x4",DAE.T_INTEGER_DEFAULT),
          ("x5",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_5_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n6int2arrayint=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_INTEGER_DEFAULT),
          ("x2",DAE.T_INTEGER_DEFAULT),("x3",DAE.T_INTEGER_DEFAULT),("x4",DAE.T_INTEGER_DEFAULT),
          ("x5",DAE.T_INTEGER_DEFAULT),("x6",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_6_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n7int2arrayint=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_INTEGER_DEFAULT),
          ("x2",DAE.T_INTEGER_DEFAULT),("x3",DAE.T_INTEGER_DEFAULT),("x4",DAE.T_INTEGER_DEFAULT),
          ("x5",DAE.T_INTEGER_DEFAULT),("x6",DAE.T_INTEGER_DEFAULT),("x7",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_7_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n8int2arrayint=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_INTEGER_DEFAULT),
          ("x2",DAE.T_INTEGER_DEFAULT),("x3",DAE.T_INTEGER_DEFAULT),("x4",DAE.T_INTEGER_DEFAULT),
          ("x5",DAE.T_INTEGER_DEFAULT),("x6",DAE.T_INTEGER_DEFAULT),("x7",DAE.T_INTEGER_DEFAULT),
          ("x8",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_8_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n1real2arrayreal=(
          DAE.T_FUNCTION({("x1",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n2real2arrayreal=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_REAL_DEFAULT),
          ("x2",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n3real2arrayreal=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_REAL_DEFAULT),
          ("x2",DAE.T_REAL_DEFAULT),("x3",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_3_DEFAULT, DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n4real2arrayreal=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_REAL_DEFAULT),
          ("x2",DAE.T_REAL_DEFAULT),("x3",DAE.T_REAL_DEFAULT),("x4",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_4_DEFAULT, DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n5real2arrayreal=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_REAL_DEFAULT),
          ("x2",DAE.T_REAL_DEFAULT),("x3",DAE.T_REAL_DEFAULT),("x4",DAE.T_REAL_DEFAULT),
          ("x5",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_5_DEFAULT, DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n6real2arrayreal=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_REAL_DEFAULT),
          ("x2",DAE.T_REAL_DEFAULT),("x3",DAE.T_REAL_DEFAULT),("x4",DAE.T_REAL_DEFAULT),
          ("x5",DAE.T_REAL_DEFAULT),("x6",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_6_DEFAULT, DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n7real2arrayreal=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_REAL_DEFAULT),
          ("x2",DAE.T_REAL_DEFAULT),("x3",DAE.T_REAL_DEFAULT),("x4",DAE.T_REAL_DEFAULT),
          ("x5",DAE.T_REAL_DEFAULT),("x6",DAE.T_REAL_DEFAULT),("x7",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_7_DEFAULT, DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type n8real2arrayreal=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_REAL_DEFAULT),
          ("x2",DAE.T_REAL_DEFAULT),("x3",DAE.T_REAL_DEFAULT),("x4",DAE.T_REAL_DEFAULT),
          ("x5",DAE.T_REAL_DEFAULT),("x6",DAE.T_REAL_DEFAULT),("x7",DAE.T_REAL_DEFAULT),
          ("x8",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_8_DEFAULT, DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type intInt2vectorreal=(
          DAE.T_FUNCTION(
          {("x",DAE.T_INTEGER_DEFAULT),
          ("y",DAE.T_INTEGER_DEFAULT)},
            T_REAL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type realRealInt2vectorreal=(
          DAE.T_FUNCTION(
          {("x",DAE.T_REAL_DEFAULT),
          ("y",DAE.T_REAL_DEFAULT),
          ("n",DAE.T_INTEGER_DEFAULT)},
          T_REAL_ARRAY_DEFAULT, DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array1dimint2array3dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_1_DEFAULT)},
          T_INT_ARRAY_3_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array1dimreal2array3dimreal=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_1_DEFAULT)},
            T_REAL_ARRAY_3_DEFAULT, DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array3dimrealArray3dimreal2array3dimreal = (
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_3_DEFAULT),
          ("y",
          T_REAL_ARRAY_3_DEFAULT)},
            T_REAL_ARRAY_3_DEFAULT, DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array2real=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_1_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE()) "T_ARRAY is appearently not constant. To bad!" ;

protected constant DAE.Type array2dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_2_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE()) "Legal syntax: val array2one= (DAE.T_FUNCTION({(\"x\",(DAE.T_ARRAY(1,DAE.T_REAL_DEFAULT),NONE()))}, TYPES.T_INTEGER)
For size(A) to transpose A
val array1dimint2array1dimint = ... already defined" ;

protected constant DAE.Type array3dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_3_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array4dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_4_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array5dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_5_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array6dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_6_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array7dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_7_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array8dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_8_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array9dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_9_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array1dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_1_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array2dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_2_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array3dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_3_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array4dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_4_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array5dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_5_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array6dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_6_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array7dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_7_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array8dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_8_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array9dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_9_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array1dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_1_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array2dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_2_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array3dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_3_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array4dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_4_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array5dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_5_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array6dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_6_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array7dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_7_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array8dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_8_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array9dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_9_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array1dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_1_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array2dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_2_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array3dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_3_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array4dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_4_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array5dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_5_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array6dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_6_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array7dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_7_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array8dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_8_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array9dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_9_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type int2boxed = (
          DAE.T_FUNCTION({("index",DAE.T_INTEGER_DEFAULT)},DAE.T_BOXED_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type string2string=(
          DAE.T_FUNCTION({("x",DAE.T_STRING_DEFAULT)},DAE.T_STRING_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

protected constant DAE.Type array1dimrealarray1dimrealarray1dimreal2real=(
          DAE.T_FUNCTION(
          {
          ("x",T_REAL_ARRAY_1_DEFAULT),
          ("y",T_REAL_ARRAY_1_DEFAULT),
          ("z",T_REAL_ARRAY_1_DEFAULT)
          },
          DAE.T_REAL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());
protected constant DAE.Type array1dimrealarray1dimrealarray1dimreal2array1dimreal=(
          DAE.T_FUNCTION(
          {
          ("x",T_REAL_ARRAY_1_DEFAULT),
          ("y",T_REAL_ARRAY_1_DEFAULT),
          ("z",T_REAL_ARRAY_1_DEFAULT)
          },
          T_REAL_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());
protected constant DAE.Type realrealreal2real=(
          DAE.T_FUNCTION(
          {
          ("x",DAE.T_REAL_DEFAULT),
          ("y",DAE.T_REAL_DEFAULT),
          ("z",DAE.T_REAL_DEFAULT)
          },DAE.T_REAL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_BUILTIN),NONE());

public function variableIsBuiltin "Returns true if cref is a builtin variable.
Currently only 'time' is a builtin variable.
"
input DAE.ComponentRef cref;
output Boolean b;
algorithm
  b := match (cref)
    case(DAE.CREF_IDENT(ident="time")) then true;
    else false;
  end match;
end variableIsBuiltin;

public function isSubstring
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "substring")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Utilities", path = Absyn.QUALIFIED(name = "Strings",path = Absyn.IDENT(name = "substring"))))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isSubstring(inPath); then ();
  end match;
end isSubstring;

public function isDer
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "der")) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isDer(inPath); then ();
  end match;
end isDer;


public function simpleInitialEnv "
val array2array=  (DAE.T_FUNCTION({(\"x\",(DAE.T_ARRAY)},
              (DAE.T_ARRAY),NONE())
val array_array2array=
val int2array= (DAE.T_FUNCTION(\"x\",(DAE.T_ARRAY(1,_)),NONE())
  Specifierar en vector, array of dimension one
  zeroes, ones, fill?

val real_real_int2array
val array2real
val array_array2int

  - Initial environment
  function: simpleInitialEnv

  The initial environment where instantiation takes place is built
  up using this function.  It creates an empty environment and adds
  all the built-in types to it.

  This only creates a minimal environment, useful for debugging purposes.
"
  output list<Env.Frame> env;
algorithm
  env := Env.newEnvironment() "Debug.fprint (\"insttr\",\"Creating initial env.\\n\") &" ;
  env := Env.extendFrameC(env, rlType);
  env := Env.extendFrameC(env, intType);
  env := Env.extendFrameC(env, strType);
  env := Env.extendFrameC(env, boolType);
  env := Env.extendFrameC(env, enumType);
  env := Env.extendFrameC(env, ExternalObjectType);
  env := Env.extendFrameC(env, realType);
  env := Env.extendFrameC(env, integerType);
  env := Env.extendFrameC(env, stringType);
  env := Env.extendFrameC(env, booleanType);
  env := Env.extendFrameC(env, stateSelectType);
end simpleInitialEnv;

public function initialEnv "function: initialEnv

  The initial environment where instantiation takes place is built
  up using this function.  It creates an empty environment and adds
  all the built-in definitions to it.
  NOTE:
    The following built in operators can not be described in
    the type system, since they e.g. have arbitrary arguments, etc.
  - fill
  - cat
    These operators are catched in the elabBuiltinHandler, along with all
    others.
"
  input Env.Cache inCache;
  output Env.Cache outCache;
  output list<Env.Frame> env;
protected
  Env.Cache cache;
algorithm
  (outCache,env) := matchcontinue(inCache)
    local
      list<Absyn.Class> initialClasses;
      list<Absyn.Import> imports;

    // First look for cached version
    case (cache) equation
      env = Env.getCachedInitialEnv(cache);
    then (cache,env);
    // if no cached version found create initial env.
    case (cache) equation
      env = Env.openScope(Env.emptyEnv, SCode.NOT_ENCAPSULATED(), NONE(), NONE());
      env = Env.extendFrameC(env, rlType);
      env = Env.extendFrameC(env, intType);
      env = Env.extendFrameC(env, strType);
      env = Env.extendFrameC(env, boolType);
      env = Env.extendFrameC(env, enumType);
      env = Env.extendFrameC(env, ExternalObjectType);
      env = Env.extendFrameC(env, realType);
      env = Env.extendFrameC(env, integerType);
      env = Env.extendFrameC(env, stringType);
      env = Env.extendFrameC(env, booleanType);
      env = Env.extendFrameC(env, stateSelectType);
      env = Env.extendFrameV(env, timeVar, NONE(), Env.VAR_UNTYPED(), {}) "see also variableIsBuiltin";

      env = Env.extendFrameT(env, "change", real2bool);
      env = Env.extendFrameT(env, "cardinality", anyNonExpandableConnector2int);
      env = Env.extendFrameT(env, "cardinality", anyExpandableConnector2int);
      env = Env.extendFrameT(env, "div", realReal2real) "non-differentiable functions" ;
      env = Env.extendFrameT(env, "div", intInt2int) "non-differentiable functions" ;
      env = Env.extendFrameT(env, "rem", realReal2real);
      env = Env.extendFrameT(env, "rem", intInt2int);
      env = Env.extendFrameT(env, "boolean", bool2bool);
      env = Env.extendFrameT(env, "boolean", real2bool);
      env = Env.extendFrameT(env, "boolean", int2bool);
      env = Env.extendFrameT(env, "Integer", enumeration2int);
      env = Env.extendFrameT(env, "abs", real2real) "differentiable functions" ;
      env = Env.extendFrameT(env, "abs", int2int) "differentiable functions" ;
      env = Env.extendFrameT(env, "substring", stringIntInt2string);
      env = Env.extendFrameT(env, "outerproduct", vectorVector2int) "Only real and int makes sense here. And maybe bool." ;
      env = Env.extendFrameT(env, "outerproduct", vectorVector2real);
      env = Env.extendFrameT(env, "linspace", realRealInt2vectorreal);
      env = Env.extendFrameT(env, "noEvent", real2real);
      env = Env.extendFrameT(env, "mod", realReal2real);
      env = Env.extendFrameT(env, "mod", intInt2int);
      env = Env.extendFrameT(env, "constrain", realrealreal2real);
      env = Env.extendFrameT(env, "constrain", array1dimrealarray1dimrealarray1dimreal2array1dimreal);
      env = Env.extendFrameT(env, "actualStream", real2real);
      env = Env.extendFrameT(env, "inStream", real2real);
      env = Env.extendFrameT(env, "constrain", array1dimrealarray1dimrealarray1dimreal2array1dimreal);

      env = initialEnvMetaModelica(env);
      
      Absyn.PROGRAM(classes=initialClasses) = getInitialFunctions();
      env = Env.extendFrameClasses(env, listReverse(Util.listFold(initialClasses, SCodeUtil.translate2, {}))) "Add classes in the initial env";
      cache = Env.setCachedInitialEnv(cache,env);
    then (cache,env);
  end matchcontinue;
end initialEnv;

protected function initialEnvMetaModelica
  input list<Env.Frame> inEnv;
  output list<Env.Frame> outEnv;
algorithm
  outEnv := matchcontinue(inEnv)
    local
      list<Env.Frame> env;
    case (env)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        // getGlobalRoot can not be represented by a regular function...
        env = Env.extendFrameT(env, "getGlobalRoot", int2boxed);
      then env;
    case env then env;
  end matchcontinue;
end initialEnvMetaModelica;

protected constant Integer memoryIndex = 3;

public function getInitialFunctions
"Fetches the Absyn.Program representation of the functions (and other classes) in the initial environment"
  output Absyn.Program initialProgram;
algorithm
  initialProgram := matchcontinue ()
    local
      Boolean b;
      String msg,fileModelica,fileMetaModelica,initialFunctionStr,initialFunctionStrMM;
      list<tuple<Boolean,Absyn.Program>> assocLst;
      Option<Absyn.Program> optProgram;
    case ()
      equation
        failure(_ = getGlobalRoot(memoryIndex));
        setGlobalRoot(memoryIndex,{});
      then fail();
    case ()
      equation
        assocLst = getGlobalRoot(memoryIndex);
      then Util.assoc(RTOpts.acceptMetaModelicaGrammar(), assocLst);
    case ()
      equation
        b = RTOpts.acceptMetaModelicaGrammar();
        fileModelica = Settings.getInstallationDirectoryPath() +& "/lib/omc/ModelicaBuiltin.mo";
        fileMetaModelica = Settings.getInstallationDirectoryPath() +& "/lib/omc/MetaModelicaBuiltin.mo";
        initialFunctionStr = System.readFile(fileModelica);
        initialFunctionStrMM = Debug.bcallret1(b, System.readFile, fileMetaModelica, "");
        initialProgram = Parser.parsestring(initialFunctionStr +& initialFunctionStrMM, fileModelica);
        assocLst = getGlobalRoot(memoryIndex);
        setGlobalRoot(memoryIndex, (b,initialProgram)::assocLst);
      then initialProgram;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Builtin.getInitialFunctions failed."});
      then fail();
  end matchcontinue;
end getInitialFunctions;

end Builtin;

