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

package Builtin
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

/*
- The primitive types
  These are the primitive types that are used to build the types
  `Real\', `Integer\' etc.
*/
public constant SCode.Class rlType=SCode.CLASS("RealType",false,false,SCode.R_PREDEFINED_REAL(),
          SCode.PARTS({},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) " real type ";

public constant SCode.Class intType=SCode.CLASS("IntegerType",false,false,SCode.R_PREDEFINED_INTEGER(),
          SCode.PARTS({},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo);

public constant SCode.Class strType=SCode.CLASS("StringType",false,false,SCode.R_PREDEFINED_STRING(),
          SCode.PARTS({},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo);

public constant SCode.Class boolType=SCode.CLASS("BooleanType",false,false,SCode.R_PREDEFINED_BOOLEAN(),
          SCode.PARTS({},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo);

protected constant SCode.Class enumType=SCode.CLASS("EnumType",false,false,SCode.R_PREDEFINED_ENUMERATION(),
          SCode.PARTS({},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo);

protected constant SCode.Element unit=SCode.COMPONENT("unit",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.STRING(""),false))),NONE(),NONE(),NONE(),NONE()) "This `unit\' component is used in several places below, and it is
  declared once here to make the definitions below easier to read." ;

protected constant SCode.Element quantity=SCode.COMPONENT("quantity",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.STRING(""),false))),NONE(),NONE(),NONE(),NONE());

protected constant SCode.Element displayUnit=SCode.COMPONENT("displayUnit",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.STRING(""),false))),NONE(),NONE(),NONE(),NONE());

protected constant SCode.Element min=SCode.COMPONENT("min",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.REAL(-1e+099),false))),NONE(),NONE(),NONE(),NONE());

protected constant SCode.Element max=SCode.COMPONENT("max",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.REAL(1e+099),false))),NONE(),NONE(),NONE(),NONE());

protected constant SCode.Element realStart=SCode.COMPONENT("start",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.REAL(0.0),false))),NONE(),NONE(),NONE(),NONE());

protected constant SCode.Element integerStart=SCode.COMPONENT("start",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("IntegerType"),NONE()),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.INTEGER(0),false))),NONE(),NONE(),NONE(),NONE());

protected constant SCode.Element stringStart=SCode.COMPONENT("start",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.STRING(""),false))),NONE(),NONE(),NONE(),NONE());

protected constant SCode.Element booleanStart=SCode.COMPONENT("start",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("BooleanType"),NONE()),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.BOOL(false),false))),NONE(),NONE(),NONE(),NONE());

protected constant SCode.Element fixed=SCode.COMPONENT("fixed",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("BooleanType"),NONE()),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.BOOL(false),false))),NONE(),NONE(),NONE(),NONE()) "Should be true for variables" ;

protected constant SCode.Element nominal=SCode.COMPONENT("nominal",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(false,Absyn.NON_EACH(),{},NONE()),NONE(),NONE(),NONE(),NONE());

protected constant SCode.Element stateSelect=SCode.COMPONENT("stateSelect",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("StateSelect"),NONE()),
          SCode.MOD(false,Absyn.NON_EACH(),{},
          SOME((
          Absyn.CREF(
          Absyn.CREF_QUAL("StateSelect",{},Absyn.CREF_IDENT("default",{}))),false))),NONE(),NONE(),NONE(),NONE());

protected constant list<SCode.Element> stateSelectComps={
          SCode.COMPONENT("never",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),NONE(),NONE()),
          SCode.COMPONENT("avoid",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),NONE(),NONE()),
          SCode.COMPONENT("default",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),NONE(),NONE()),
          SCode.COMPONENT("prefer",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),NONE(),NONE()),
          SCode.COMPONENT("always",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),NONE(),NONE())} "The StateSelect enumeration" ;

protected constant SCode.Class stateSelectType=SCode.CLASS("StateSelect",false,false,SCode.R_ENUMERATION(),
          SCode.PARTS(stateSelectComps,{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "The State Select Type";

public constant SCode.Class ExternalObjectType=SCode.CLASS("ExternalObject",false,false,SCode.R_CLASS(),
          SCode.PARTS({},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "ExternalObject type" ;

public constant SCode.Class realType=SCode.CLASS("Real",false,false,SCode.R_PREDEFINED_REAL(),
          SCode.PARTS({unit,quantity,displayUnit,min,max,realStart,fixed,nominal,
          stateSelect},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "- The `Real\' type" ;

protected constant SCode.Class integerType=SCode.CLASS("Integer",false,false,SCode.R_PREDEFINED_INTEGER(),
          SCode.PARTS({quantity,min,max,integerStart,fixed},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "- The `Integer\' type" ;

protected constant SCode.Class stringType=SCode.CLASS("String",false,false,SCode.R_PREDEFINED_STRING(),
          SCode.PARTS({quantity,stringStart},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "- The `String\' type" ;

protected constant SCode.Class booleanType=SCode.CLASS("Boolean",false,false,SCode.R_PREDEFINED_BOOLEAN(),
          SCode.PARTS({quantity,booleanStart,fixed},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "- The `Boolean\' type" ;

/* The builtin variable time. See also variableIsBuiltin */
protected constant DAE.Var timeVar=DAE.TYPES_VAR("time",
          DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()) "- The `time\' variable" ;

protected constant DAE.Type stringIntInt2string=(
          DAE.T_FUNCTION(
              {
              ("x",DAE.T_STRING_DEFAULT),
              ("y",DAE.T_INTEGER_DEFAULT),
              ("z",DAE.T_INTEGER_DEFAULT)
              },
              DAE.T_STRING_DEFAULT,
              DAE.FUNCTION_ATTRIBUTES_DEFAULT),
              NONE());

protected constant DAE.Type real2real=(
          DAE.T_FUNCTION({("x",DAE.T_REAL_DEFAULT)},DAE.T_REAL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type realReal2real=(
          DAE.T_FUNCTION(
          {("x",DAE.T_REAL_DEFAULT),("y",DAE.T_REAL_DEFAULT)},DAE.T_REAL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type int2int=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type int2bool=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          DAE.T_BOOL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type enumeration2int=(
          DAE.T_FUNCTION({("x",(DAE.T_ENUMERATION(NONE(), Absyn.IDENT(""), {}, {}, {}),NONE()))},
          DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type intInt2int=(
          DAE.T_FUNCTION(
          {("x",DAE.T_INTEGER_DEFAULT),
          ("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type intInt2bool=(
          DAE.T_FUNCTION(
          {("x",DAE.T_INTEGER_DEFAULT),
          ("y",DAE.T_INTEGER_DEFAULT)},DAE.T_BOOL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type bool2bool=(
          DAE.T_FUNCTION({("x",DAE.T_BOOL_DEFAULT)},DAE.T_BOOL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type real2bool=(
          DAE.T_FUNCTION({("x",DAE.T_REAL_DEFAULT)},DAE.T_BOOL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type realReal2bool=(
          DAE.T_FUNCTION(
          {("x",DAE.T_REAL_DEFAULT),("y",DAE.T_REAL_DEFAULT)},DAE.T_BOOL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type realRealReal2Real=(
          DAE.T_FUNCTION(
          {("x",DAE.T_REAL_DEFAULT),("y",DAE.T_REAL_DEFAULT),("z",DAE.T_REAL_DEFAULT)},DAE.T_REAL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type anyNonExpandableConnector2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          (DAE.T_ANYTYPE(SOME(ClassInf.CONNECTOR(Absyn.IDENT("$dummy$"),false))),NONE()))},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type anyExpandableConnector2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          (DAE.T_ANYTYPE(SOME(ClassInf.CONNECTOR(Absyn.IDENT("$dummy$"),true))),NONE()))},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimint2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_1_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimint2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_2_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimint2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_3_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimint2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_4_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimint2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_5_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimint2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_6_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimint2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_7_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimint2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_8_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimreal2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_1_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimreal2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_2_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimreal2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_3_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimreal2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_4_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimreal2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_5_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimreal2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_6_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimreal2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_7_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimreal2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_8_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimreal2real=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_1_DEFAULT)}, DAE.T_REAL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimreal2real=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_2_DEFAULT)}, DAE.T_REAL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimreal2real=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_3_DEFAULT)}, DAE.T_REAL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimreal2real=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_4_DEFAULT)}, DAE.T_REAL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimreal2real=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_5_DEFAULT)}, DAE.T_REAL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimreal2real=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_6_DEFAULT)}, DAE.T_REAL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimreal2real=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_7_DEFAULT)}, DAE.T_REAL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimreal2real=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_8_DEFAULT)}, DAE.T_REAL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimstring2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_1_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimstring2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_2_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimstring2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_3_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimstring2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_4_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimstring2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_5_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimstring2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_6_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimstring2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_7_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimstring2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_8_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimstring2string=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_1_DEFAULT)},DAE.T_STRING_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimstring2string=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_2_DEFAULT)},DAE.T_STRING_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimstring2string=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_3_DEFAULT)},DAE.T_STRING_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimstring2string=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_4_DEFAULT)},DAE.T_STRING_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimstring2string=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_5_DEFAULT)},DAE.T_STRING_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimstring2string=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_6_DEFAULT)},DAE.T_STRING_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimstring2string=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_7_DEFAULT)},DAE.T_STRING_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimstring2string=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_8_DEFAULT)},DAE.T_STRING_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimbool2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_1_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimbool2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_2_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimbool2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_3_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimbool2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_4_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimbool2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_5_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimbool2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_6_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimbool2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_7_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimbool2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_8_DEFAULT)}, DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimbool2bool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_1_DEFAULT)}, DAE.T_BOOL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimbool2bool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_2_DEFAULT)}, DAE.T_BOOL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimbool2bool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_3_DEFAULT)}, DAE.T_BOOL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimbool2bool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_4_DEFAULT)}, DAE.T_BOOL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimbool2bool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_5_DEFAULT)}, DAE.T_BOOL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimbool2bool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_6_DEFAULT)}, DAE.T_BOOL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimbool2bool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_7_DEFAULT)}, DAE.T_BOOL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimbool2bool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_8_DEFAULT)}, DAE.T_BOOL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimintInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_1_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimintInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_2_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimintInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_3_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimintInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_4_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimintInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_5_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimintInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_6_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimintInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_7_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimintInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_8_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimrealInt2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_1_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimrealInt2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_2_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimrealInt2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_3_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimrealInt2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_4_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimrealInt2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_5_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimrealInt2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_6_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimrealInt2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_7_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimrealInt2int=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_8_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimstringInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_1_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimstringInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_2_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimstringInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_3_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimstringInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_4_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimstringInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_5_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimstringInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_6_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimstringInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_7_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimstringInt2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_8_DEFAULT),("y",DAE.T_INTEGER_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimboolInt2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_1_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimboolInt2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_2_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimboolInt2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_3_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimboolInt2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_4_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimboolInt2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_5_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimboolInt2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_6_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimboolInt2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_7_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimboolInt2int=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_8_DEFAULT), ("y",DAE.T_INTEGER_DEFAULT)}, 
            DAE.T_INTEGER_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimint2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_1_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimint2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_2_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimint2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_3_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimint2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_4_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimint2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_5_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimint2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_6_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimint2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_7_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimint2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_8_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimint2matrixint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_1_DEFAULT)},
          T_INT_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimint2matrixint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_2_DEFAULT)},
          T_INT_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimint2matrixint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_3_DEFAULT)},
          T_INT_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimint2matrixint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_4_DEFAULT)},
          T_INT_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimint2matrixint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_5_DEFAULT)},
          T_INT_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimint2matrixint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_6_DEFAULT)},
          T_INT_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimint2matrixint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_7_DEFAULT)},
          T_INT_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimint2matrixint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_8_DEFAULT)},
          T_INT_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_1_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimint2array2dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_2_DEFAULT)},
          T_INT_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimint2array3dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_3_DEFAULT)},
          T_INT_ARRAY_3_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimint2array4dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_4_DEFAULT)},
          T_INT_ARRAY_4_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimint2array5dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_5_DEFAULT)},
          T_INT_ARRAY_5_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimint2array6dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_6_DEFAULT)},
          T_INT_ARRAY_6_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimint2array7dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_7_DEFAULT)},
          T_INT_ARRAY_7_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimint2array8dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_8_DEFAULT)},
          T_INT_ARRAY_8_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimreal2array1dimreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_1_DEFAULT)}, T_REAL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimreal2array2dimreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_2_DEFAULT)}, T_REAL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimreal2array3dimreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_3_DEFAULT)}, T_REAL_ARRAY_3_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimreal2array4dimreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_4_DEFAULT)}, T_REAL_ARRAY_4_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimreal2array5dimreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_5_DEFAULT)}, T_REAL_ARRAY_5_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimreal2array6dimreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_6_DEFAULT)}, T_REAL_ARRAY_6_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimreal2array7dimreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_7_DEFAULT)}, T_REAL_ARRAY_7_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimreal2array8dimreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_8_DEFAULT)}, T_REAL_ARRAY_8_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimstring2array1dimstring=(
          DAE.T_FUNCTION({("x", T_STRING_ARRAY_1_DEFAULT)}, T_STRING_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimstring2array2dimstring=(
          DAE.T_FUNCTION({("x", T_STRING_ARRAY_2_DEFAULT)}, T_STRING_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimstring2array3dimstring=(
          DAE.T_FUNCTION({("x", T_STRING_ARRAY_3_DEFAULT)}, T_STRING_ARRAY_3_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimstring2array4dimstring=(
          DAE.T_FUNCTION({("x", T_STRING_ARRAY_4_DEFAULT)}, T_STRING_ARRAY_4_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimstring2array5dimstring=(
          DAE.T_FUNCTION({("x", T_STRING_ARRAY_5_DEFAULT)}, T_STRING_ARRAY_5_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimstring2array6dimstring=(
          DAE.T_FUNCTION({("x", T_STRING_ARRAY_6_DEFAULT)}, T_STRING_ARRAY_6_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimstring2array7dimstring=(
          DAE.T_FUNCTION({("x", T_STRING_ARRAY_7_DEFAULT)}, T_STRING_ARRAY_7_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimstring2array8dimstring=(
          DAE.T_FUNCTION({("x", T_STRING_ARRAY_8_DEFAULT)}, T_STRING_ARRAY_8_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimbool2array1dimbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_1_DEFAULT)}, T_BOOL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimbool2array2dimbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_2_DEFAULT)}, T_BOOL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimbool2array3dimbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_3_DEFAULT)}, T_BOOL_ARRAY_3_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimbool2array4dimbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_4_DEFAULT)}, T_BOOL_ARRAY_4_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimbool2array5dimbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_5_DEFAULT)}, T_BOOL_ARRAY_5_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimbool2array6dimbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_6_DEFAULT)}, T_BOOL_ARRAY_6_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimbool2array7dimbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_7_DEFAULT)}, T_BOOL_ARRAY_7_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimbool2array8dimbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_8_DEFAULT)}, T_BOOL_ARRAY_8_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimreal2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_1_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimreal2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_2_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimreal2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_3_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimreal2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_4_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimreal2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_5_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimreal2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_6_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimreal2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_7_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimreal2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_8_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimreal2vectorreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_1_DEFAULT)},
            T_REAL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimreal2vectorreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_2_DEFAULT)},
            T_REAL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimreal2vectorreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_3_DEFAULT)},
            T_REAL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimreal2vectorreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_4_DEFAULT)},
            T_REAL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimreal2vectorreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_5_DEFAULT)},
            T_REAL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimreal2vectorreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_6_DEFAULT)},
            T_REAL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimreal2vectorreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_7_DEFAULT)},
            T_REAL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimreal2vectorreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_8_DEFAULT)},
            T_REAL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimreal2matrixreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_1_DEFAULT)},
            T_REAL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimreal2matrixreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_2_DEFAULT)},
            T_REAL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimreal2matrixreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_3_DEFAULT)},
            T_REAL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimreal2matrixreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_4_DEFAULT)},
            T_REAL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimreal2matrixreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_5_DEFAULT)},
            T_REAL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimreal2matrixreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_6_DEFAULT)},
            T_REAL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimreal2matrixreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_7_DEFAULT)},
            T_REAL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimreal2matrixreal=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_8_DEFAULT)},
            T_REAL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimstring2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_1_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimstring2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_2_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimstring2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_3_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimstring2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_4_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimstring2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_5_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimstring2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_6_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimstring2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_7_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimstring2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_8_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimstring2vectorstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_1_DEFAULT)},
          T_STRING_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimstring2vectorstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_2_DEFAULT)},
          T_STRING_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimstring2vectorstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_3_DEFAULT)},
          T_STRING_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimstring2vectorstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_4_DEFAULT)},
          T_STRING_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimstring2vectorstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_5_DEFAULT)},
          T_STRING_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimstring2vectorstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_6_DEFAULT)},
          T_STRING_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimstring2vectorstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_7_DEFAULT)},
          T_STRING_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimstring2vectorstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_8_DEFAULT)},
          T_STRING_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimstring2matrixstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_1_DEFAULT)},
          T_STRING_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimstring2matrixstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_2_DEFAULT)},
          T_STRING_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimstring2matrixstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_3_DEFAULT)},
          T_STRING_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimstring2matrixstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_4_DEFAULT)},
          T_STRING_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimstring2matrixstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_5_DEFAULT)},
          T_STRING_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimstring2matrixstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_6_DEFAULT)},
          T_STRING_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimstring2matrixstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_7_DEFAULT)},
          T_STRING_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimstring2matrixstring=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_8_DEFAULT)},
          T_STRING_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimbool2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_1_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimbool2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_2_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimbool2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_3_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimbool2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_4_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimbool2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_5_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimbool2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_6_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimbool2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_7_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimbool2vectorint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_8_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimbool2vectorbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_1_DEFAULT)},
            T_BOOL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimbool2vectorbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_2_DEFAULT)},
            T_BOOL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimbool2vectorbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_3_DEFAULT)},
            T_BOOL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimbool2vectorbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_4_DEFAULT)},
            T_BOOL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimbool2vectorbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_5_DEFAULT)},
            T_BOOL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimbool2vectorbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_6_DEFAULT)},
            T_BOOL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimbool2vectorbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_7_DEFAULT)},
            T_BOOL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimbool2vectorbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_8_DEFAULT)},
            T_BOOL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimbool2matrixbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_1_DEFAULT)},
            T_BOOL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimbool2matrixbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_2_DEFAULT)},
            T_BOOL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimbool2matrixbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_3_DEFAULT)},
            T_BOOL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimbool2matrixbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_4_DEFAULT)},
            T_BOOL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimbool2matrixbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_5_DEFAULT)},
            T_BOOL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimbool2matrixbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_6_DEFAULT)},
            T_BOOL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimbool2matrixbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_7_DEFAULT)},
            T_BOOL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimbool2matrixbool=(
          DAE.T_FUNCTION({("x", T_BOOL_ARRAY_8_DEFAULT)},
            T_BOOL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type int2matrixint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
            T_INT_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type real2matrixreal=(
          DAE.T_FUNCTION({("x",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type string2matrixstring=(
          DAE.T_FUNCTION({("x",DAE.T_STRING_DEFAULT)},
          T_STRING_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type bool2matrixbool=(
          DAE.T_FUNCTION({("x",DAE.T_BOOL_DEFAULT)},
            T_BOOL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type vectorVector2int=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_1_DEFAULT),
          ("y",
          T_INT_ARRAY_1_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type vectorVector2real=(
          DAE.T_FUNCTION({("x", T_REAL_ARRAY_1_DEFAULT), ("y", T_REAL_ARRAY_1_DEFAULT)}, 
            DAE.T_REAL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type int2array1dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type int2array2dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type int2array3dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_3_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type int2array4dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_4_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type int2array5dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_5_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type int2array6dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_6_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type int2array7dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_7_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type int2array8dimint=(
          DAE.T_FUNCTION({("x",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_8_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n1int2arrayint=(
          DAE.T_FUNCTION({("x1",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n2int2arrayint=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_INTEGER_DEFAULT),
          ("x2",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_2_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n3int2arrayint=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_INTEGER_DEFAULT),
          ("x2",DAE.T_INTEGER_DEFAULT),("x3",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_3_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n4int2arrayint=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_INTEGER_DEFAULT),
          ("x2",DAE.T_INTEGER_DEFAULT),("x3",DAE.T_INTEGER_DEFAULT),("x4",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_4_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n5int2arrayint=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_INTEGER_DEFAULT),
          ("x2",DAE.T_INTEGER_DEFAULT),("x3",DAE.T_INTEGER_DEFAULT),("x4",DAE.T_INTEGER_DEFAULT),
          ("x5",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_5_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n6int2arrayint=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_INTEGER_DEFAULT),
          ("x2",DAE.T_INTEGER_DEFAULT),("x3",DAE.T_INTEGER_DEFAULT),("x4",DAE.T_INTEGER_DEFAULT),
          ("x5",DAE.T_INTEGER_DEFAULT),("x6",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_6_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n7int2arrayint=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_INTEGER_DEFAULT),
          ("x2",DAE.T_INTEGER_DEFAULT),("x3",DAE.T_INTEGER_DEFAULT),("x4",DAE.T_INTEGER_DEFAULT),
          ("x5",DAE.T_INTEGER_DEFAULT),("x6",DAE.T_INTEGER_DEFAULT),("x7",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_7_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n8int2arrayint=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_INTEGER_DEFAULT),
          ("x2",DAE.T_INTEGER_DEFAULT),("x3",DAE.T_INTEGER_DEFAULT),("x4",DAE.T_INTEGER_DEFAULT),
          ("x5",DAE.T_INTEGER_DEFAULT),("x6",DAE.T_INTEGER_DEFAULT),("x7",DAE.T_INTEGER_DEFAULT),
          ("x8",DAE.T_INTEGER_DEFAULT)},
          T_INT_ARRAY_8_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n1real2arrayreal=(
          DAE.T_FUNCTION({("x1",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n2real2arrayreal=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_REAL_DEFAULT),
          ("x2",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_2_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n3real2arrayreal=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_REAL_DEFAULT),
          ("x2",DAE.T_REAL_DEFAULT),("x3",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_3_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n4real2arrayreal=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_REAL_DEFAULT),
          ("x2",DAE.T_REAL_DEFAULT),("x3",DAE.T_REAL_DEFAULT),("x4",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_4_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n5real2arrayreal=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_REAL_DEFAULT),
          ("x2",DAE.T_REAL_DEFAULT),("x3",DAE.T_REAL_DEFAULT),("x4",DAE.T_REAL_DEFAULT),
          ("x5",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_5_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n6real2arrayreal=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_REAL_DEFAULT),
          ("x2",DAE.T_REAL_DEFAULT),("x3",DAE.T_REAL_DEFAULT),("x4",DAE.T_REAL_DEFAULT),
          ("x5",DAE.T_REAL_DEFAULT),("x6",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_6_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n7real2arrayreal=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_REAL_DEFAULT),
          ("x2",DAE.T_REAL_DEFAULT),("x3",DAE.T_REAL_DEFAULT),("x4",DAE.T_REAL_DEFAULT),
          ("x5",DAE.T_REAL_DEFAULT),("x6",DAE.T_REAL_DEFAULT),("x7",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_7_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type n8real2arrayreal=(
          DAE.T_FUNCTION(
          {("x1",DAE.T_REAL_DEFAULT),
          ("x2",DAE.T_REAL_DEFAULT),("x3",DAE.T_REAL_DEFAULT),("x4",DAE.T_REAL_DEFAULT),
          ("x5",DAE.T_REAL_DEFAULT),("x6",DAE.T_REAL_DEFAULT),("x7",DAE.T_REAL_DEFAULT),
          ("x8",DAE.T_REAL_DEFAULT)},
            T_REAL_ARRAY_8_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type intInt2vectorreal=(
          DAE.T_FUNCTION(
          {("x",DAE.T_INTEGER_DEFAULT),
          ("y",DAE.T_INTEGER_DEFAULT)},
            T_REAL_ARRAY_1_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type realRealInt2vectorreal=(
          DAE.T_FUNCTION(
          {("x",DAE.T_REAL_DEFAULT),
          ("y",DAE.T_REAL_DEFAULT),
          ("n",DAE.T_INTEGER_DEFAULT)},
          T_REAL_ARRAY_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimint2array3dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_1_DEFAULT)},
          T_INT_ARRAY_3_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimreal2array3dimreal=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_1_DEFAULT)},
            T_REAL_ARRAY_3_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimrealArray3dimreal2array3dimreal = (
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_3_DEFAULT),
          ("y",
          T_REAL_ARRAY_3_DEFAULT)},
            T_REAL_ARRAY_3_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2real=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_1_DEFAULT)},DAE.T_INTEGER_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE()) "T_ARRAY is appearently not constant. To bad!" ;

protected constant DAE.Type array2dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_2_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE()) "Legal syntax: val array2one= (DAE.T_FUNCTION({(\"x\",(DAE.T_ARRAY(1,DAE.T_REAL_DEFAULT),NONE()))}, TYPES.T_INTEGER)
For size(A) to transpose A
val array1dimint2array1dimint = ... already defined" ;

protected constant DAE.Type array3dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_3_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_4_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_5_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_6_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_7_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_8_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array9dimint2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_INT_ARRAY_9_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_1_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_2_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_3_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_4_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_5_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_6_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_7_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_8_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array9dimreal2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_REAL_ARRAY_9_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_1_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_2_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_3_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_4_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_5_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_6_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_7_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_8_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array9dimstring2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_STRING_ARRAY_9_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_1_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array2dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_2_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array3dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_3_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array4dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_4_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array5dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_5_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array6dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_6_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array7dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_7_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array8dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_8_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array9dimbool2array1dimint=(
          DAE.T_FUNCTION(
          {
          ("x",
          T_BOOL_ARRAY_9_DEFAULT)},
          T_INT_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type int2boxed = (
          DAE.T_FUNCTION({("index",DAE.T_INTEGER_DEFAULT)},DAE.T_BOXED_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type string2string=(
          DAE.T_FUNCTION({("x",DAE.T_STRING_DEFAULT)},DAE.T_STRING_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

protected constant DAE.Type array1dimrealarray1dimrealarray1dimreal2real=(
          DAE.T_FUNCTION(
          {
          ("x",T_REAL_ARRAY_1_DEFAULT),
          ("y",T_REAL_ARRAY_1_DEFAULT),
          ("z",T_REAL_ARRAY_1_DEFAULT)
          },
          DAE.T_REAL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());
protected constant DAE.Type array1dimrealarray1dimrealarray1dimreal2array1dimreal=(
          DAE.T_FUNCTION(
          {
          ("x",T_REAL_ARRAY_1_DEFAULT),
          ("y",T_REAL_ARRAY_1_DEFAULT),
          ("z",T_REAL_ARRAY_1_DEFAULT)
          },
          T_REAL_ARRAY_1_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());
protected constant DAE.Type realrealreal2real=(
          DAE.T_FUNCTION(
          {
          ("x",DAE.T_REAL_DEFAULT),
          ("y",DAE.T_REAL_DEFAULT),
          ("z",DAE.T_REAL_DEFAULT)
          },DAE.T_REAL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT),NONE());

public function variableIsBuiltin "Returns true if cref is a builtin variable.
Currently only 'time' is a builtin variable.
"
input DAE.ComponentRef cref;
output Boolean b;
algorithm
  b := matchcontinue(cref)
    case(DAE.CREF_IDENT(ident="time")) then true;
    case(_) then false;  
  end matchcontinue;
end variableIsBuiltin;


public function isTanh
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "tanh")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "tanh")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isTanh(inPath); then ();
  end match;
end isTanh;

public function isCosh
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "cosh")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "cosh")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isCosh(inPath); then ();
  end match;
end isCosh;

public function isACos
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "acos")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "acos")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isACos(inPath); then ();
  end match;
end isACos;

public function isASin
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "asin")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "asin")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isASin(inPath); then ();
  end match;
end isASin;

public function isATan
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "atan")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "atan")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isATan(inPath); then ();
  end match;
end isATan;

public function isATan2
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "atan2")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "atan2")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isATan2(inPath); then ();
  end match;
end isATan2;

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

public function isSinh
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "sinh")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "sinh")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isSinh(inPath); then ();
  end match;
end isSinh;

public function isSin
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "sin")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "sin")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isSin(inPath); then ();
  end match;
end isSin;

public function isCos ""
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "cos")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "cos")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isCos(inPath); then ();
  end match;
end isCos;

public function isExp ""
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "exp")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "exp")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isExp(inPath);  then ();
  end match;
end isExp;

public function isLog ""
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "log")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "log")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isLog(inPath); then ();
  end match;
end isLog;

public function isLog10 ""
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "log10")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "log10")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isLog10(inPath); then ();
  end match;
end isLog10;

public function isSqrt ""
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "sqrt")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "sqrt")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isSqrt(inPath); then ();
  end match;
end isSqrt;

public function isTan ""
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "tan")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "tan")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isTan(inPath); then ();
  end match;
end isTan;

public function isCross ""
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "cross")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "cross")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isCross(inPath); then ();
  end match;
end isCross;

public function isMax
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "max")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "max")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isMax(inPath); then ();
  end match;
end isMax;

public function isMin
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "min")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "min")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isMin(inPath); then ();
  end match;
end isMin;

public function isTranspose
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "transpose")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "transpose")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isTranspose(inPath); then ();
  end match;
end isTranspose;

public function isSkew
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "skew")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "skew")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isSkew(inPath); then ();
  end matchcontinue;
end isSkew;

public function isAbs
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "abs")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "abs")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isAbs(inPath); then ();
  end match;
end isAbs;

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
      env = Env.openScope(Env.emptyEnv, false,NONE(),NONE());
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
      env = Env.extendFrameV(env, timeVar,NONE(), Env.VAR_UNTYPED(), {}) "see also variableIsBuiltin";

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
      env = Env.extendFrameT(env, "ndims", array1dimint2int) "PR. Add the built in array functions here. Also do it for real, string and bool" ;
      env = Env.extendFrameT(env, "ndims", array2dimint2int);
      env = Env.extendFrameT(env, "ndims", array3dimint2int);
      env = Env.extendFrameT(env, "ndims", array4dimint2int);
      env = Env.extendFrameT(env, "ndims", array5dimint2int);
      env = Env.extendFrameT(env, "ndims", array6dimint2int);
      env = Env.extendFrameT(env, "ndims", array7dimint2int);
      env = Env.extendFrameT(env, "ndims", array8dimint2int);
      env = Env.extendFrameT(env, "ndims", array1dimreal2int);
      env = Env.extendFrameT(env, "ndims", array2dimreal2int);
      env = Env.extendFrameT(env, "ndims", array3dimreal2int);
      env = Env.extendFrameT(env, "ndims", array4dimreal2int);
      env = Env.extendFrameT(env, "ndims", array5dimreal2int);
      env = Env.extendFrameT(env, "ndims", array6dimreal2int);
      env = Env.extendFrameT(env, "ndims", array7dimreal2int);
      env = Env.extendFrameT(env, "ndims", array8dimreal2int);
      env = Env.extendFrameT(env, "ndims", array1dimstring2int);
      env = Env.extendFrameT(env, "ndims", array2dimstring2int);
      env = Env.extendFrameT(env, "ndims", array3dimstring2int);
      env = Env.extendFrameT(env, "ndims", array4dimstring2int);
      env = Env.extendFrameT(env, "ndims", array5dimstring2int);
      env = Env.extendFrameT(env, "ndims", array6dimstring2int);
      env = Env.extendFrameT(env, "ndims", array7dimstring2int);
      env = Env.extendFrameT(env, "ndims", array8dimstring2int);
      env = Env.extendFrameT(env, "ndims", array1dimbool2int);
      env = Env.extendFrameT(env, "ndims", array2dimbool2int);
      env = Env.extendFrameT(env, "ndims", array3dimbool2int);
      env = Env.extendFrameT(env, "ndims", array4dimbool2int);
      env = Env.extendFrameT(env, "ndims", array5dimbool2int);
      env = Env.extendFrameT(env, "ndims", array6dimbool2int);
      env = Env.extendFrameT(env, "ndims", array7dimbool2int);
      env = Env.extendFrameT(env, "ndims", array8dimbool2int);
      env = Env.extendFrameT(env, "size", array1dimintInt2int);
      env = Env.extendFrameT(env, "size", array2dimintInt2int);
      env = Env.extendFrameT(env, "size", array3dimintInt2int);
      env = Env.extendFrameT(env, "size", array4dimintInt2int);
      env = Env.extendFrameT(env, "size", array5dimintInt2int);
      env = Env.extendFrameT(env, "size", array6dimintInt2int);
      env = Env.extendFrameT(env, "size", array7dimintInt2int);
      env = Env.extendFrameT(env, "size", array8dimintInt2int);
      env = Env.extendFrameT(env, "size", array1dimrealInt2int);
      env = Env.extendFrameT(env, "size", array2dimrealInt2int);
      env = Env.extendFrameT(env, "size", array3dimrealInt2int);
      env = Env.extendFrameT(env, "size", array4dimrealInt2int);
      env = Env.extendFrameT(env, "size", array5dimrealInt2int);
      env = Env.extendFrameT(env, "size", array6dimrealInt2int);
      env = Env.extendFrameT(env, "size", array7dimrealInt2int);
      env = Env.extendFrameT(env, "size", array8dimrealInt2int);
      env = Env.extendFrameT(env, "size", array1dimstringInt2int);
      env = Env.extendFrameT(env, "size", array2dimstringInt2int);
      env = Env.extendFrameT(env, "size", array3dimstringInt2int);
      env = Env.extendFrameT(env, "size", array4dimstringInt2int);
      env = Env.extendFrameT(env, "size", array5dimstringInt2int);
      env = Env.extendFrameT(env, "size", array6dimstringInt2int);
      env = Env.extendFrameT(env, "size", array7dimstringInt2int);
      env = Env.extendFrameT(env, "size", array8dimstringInt2int);
      env = Env.extendFrameT(env, "size", array1dimboolInt2int);
      env = Env.extendFrameT(env, "size", array2dimboolInt2int);
      env = Env.extendFrameT(env, "size", array3dimboolInt2int);
      env = Env.extendFrameT(env, "size", array4dimboolInt2int);
      env = Env.extendFrameT(env, "size", array5dimboolInt2int);
      env = Env.extendFrameT(env, "size", array6dimboolInt2int);
      env = Env.extendFrameT(env, "size", array7dimboolInt2int);
      env = Env.extendFrameT(env, "size", array8dimboolInt2int);
      env = Env.extendFrameT(env, "size", array1dimint2vectorint);
      env = Env.extendFrameT(env, "size", array2dimint2vectorint);
      env = Env.extendFrameT(env, "size", array3dimint2vectorint);
      env = Env.extendFrameT(env, "size", array4dimint2vectorint);
      env = Env.extendFrameT(env, "size", array5dimint2vectorint);
      env = Env.extendFrameT(env, "size", array6dimint2vectorint);
      env = Env.extendFrameT(env, "size", array7dimint2vectorint);
      env = Env.extendFrameT(env, "size", array8dimint2vectorint);
      env = Env.extendFrameT(env, "size", array1dimreal2vectorint);
      env = Env.extendFrameT(env, "size", array2dimreal2vectorint);
      env = Env.extendFrameT(env, "size", array3dimreal2vectorint);
      env = Env.extendFrameT(env, "size", array4dimreal2vectorint);
      env = Env.extendFrameT(env, "size", array5dimreal2vectorint);
      env = Env.extendFrameT(env, "size", array6dimreal2vectorint);
      env = Env.extendFrameT(env, "size", array7dimreal2vectorint);
      env = Env.extendFrameT(env, "size", array8dimreal2vectorint);
      env = Env.extendFrameT(env, "size", array1dimstring2vectorint);
      env = Env.extendFrameT(env, "size", array2dimstring2vectorint);
      env = Env.extendFrameT(env, "size", array3dimstring2vectorint);
      env = Env.extendFrameT(env, "size", array4dimstring2vectorint);
      env = Env.extendFrameT(env, "size", array5dimstring2vectorint);
      env = Env.extendFrameT(env, "size", array6dimstring2vectorint);
      env = Env.extendFrameT(env, "size", array7dimstring2vectorint);
      env = Env.extendFrameT(env, "size", array8dimstring2vectorint);
      env = Env.extendFrameT(env, "size", array1dimbool2vectorint);
      env = Env.extendFrameT(env, "size", array2dimbool2vectorint);
      env = Env.extendFrameT(env, "size", array3dimbool2vectorint);
      env = Env.extendFrameT(env, "size", array4dimbool2vectorint);
      env = Env.extendFrameT(env, "size", array5dimbool2vectorint);
      env = Env.extendFrameT(env, "size", array6dimbool2vectorint);
      env = Env.extendFrameT(env, "size", array7dimbool2vectorint);
      env = Env.extendFrameT(env, "size", array8dimbool2vectorint);
      env = Env.extendFrameT(env, "size", array1dimint2array1dimint) "size(A)" ;
      env = Env.extendFrameT(env, "size", array2dimint2array1dimint);
      env = Env.extendFrameT(env, "size", array3dimint2array1dimint);
      env = Env.extendFrameT(env, "size", array4dimint2array1dimint);
      env = Env.extendFrameT(env, "size", array5dimint2array1dimint);
      env = Env.extendFrameT(env, "size", array6dimint2array1dimint);
      env = Env.extendFrameT(env, "size", array7dimint2array1dimint);
      env = Env.extendFrameT(env, "size", array8dimint2array1dimint);
      env = Env.extendFrameT(env, "size", array9dimint2array1dimint);
      env = Env.extendFrameT(env, "size", array1dimreal2array1dimint);
      env = Env.extendFrameT(env, "size", array2dimreal2array1dimint);
      env = Env.extendFrameT(env, "size", array3dimreal2array1dimint);
      env = Env.extendFrameT(env, "size", array4dimreal2array1dimint);
      env = Env.extendFrameT(env, "size", array5dimreal2array1dimint);
      env = Env.extendFrameT(env, "size", array6dimreal2array1dimint);
      env = Env.extendFrameT(env, "size", array7dimreal2array1dimint);
      env = Env.extendFrameT(env, "size", array8dimreal2array1dimint);
      env = Env.extendFrameT(env, "size", array9dimreal2array1dimint);
      env = Env.extendFrameT(env, "size", array1dimstring2array1dimint);
      env = Env.extendFrameT(env, "size", array2dimstring2array1dimint);
      env = Env.extendFrameT(env, "size", array3dimstring2array1dimint);
      env = Env.extendFrameT(env, "size", array4dimstring2array1dimint);
      env = Env.extendFrameT(env, "size", array5dimstring2array1dimint);
      env = Env.extendFrameT(env, "size", array6dimstring2array1dimint);
      env = Env.extendFrameT(env, "size", array7dimstring2array1dimint);
      env = Env.extendFrameT(env, "size", array8dimstring2array1dimint);
      env = Env.extendFrameT(env, "size", array9dimstring2array1dimint);
      env = Env.extendFrameT(env, "size", array1dimbool2array1dimint);
      env = Env.extendFrameT(env, "size", array2dimbool2array1dimint);
      env = Env.extendFrameT(env, "size", array3dimbool2array1dimint);
      env = Env.extendFrameT(env, "size", array4dimbool2array1dimint);
      env = Env.extendFrameT(env, "size", array5dimbool2array1dimint);
      env = Env.extendFrameT(env, "size", array6dimbool2array1dimint);
      env = Env.extendFrameT(env, "size", array7dimbool2array1dimint);
      env = Env.extendFrameT(env, "size", array8dimbool2array1dimint);
      env = Env.extendFrameT(env, "size", array9dimbool2array1dimint);
      env = Env.extendFrameT(env, "scalar", array1dimint2int);
      env = Env.extendFrameT(env, "scalar", array2dimint2int);
      env = Env.extendFrameT(env, "scalar", array3dimint2int);
      env = Env.extendFrameT(env, "scalar", array4dimint2int);
      env = Env.extendFrameT(env, "scalar", array5dimint2int);
      env = Env.extendFrameT(env, "scalar", array6dimint2int);
      env = Env.extendFrameT(env, "scalar", array7dimint2int);
      env = Env.extendFrameT(env, "scalar", array8dimint2int);
      env = Env.extendFrameT(env, "scalar", array1dimreal2real);
      env = Env.extendFrameT(env, "scalar", array2dimreal2real);
      env = Env.extendFrameT(env, "scalar", array3dimreal2real);
      env = Env.extendFrameT(env, "scalar", array4dimreal2real);
      env = Env.extendFrameT(env, "scalar", array5dimreal2real);
      env = Env.extendFrameT(env, "scalar", array6dimreal2real);
      env = Env.extendFrameT(env, "scalar", array7dimreal2real);
      env = Env.extendFrameT(env, "scalar", array8dimreal2real);
      env = Env.extendFrameT(env, "scalar", array1dimbool2bool);
      env = Env.extendFrameT(env, "scalar", array2dimbool2bool);
      env = Env.extendFrameT(env, "scalar", array3dimbool2bool);
      env = Env.extendFrameT(env, "scalar", array4dimbool2bool);
      env = Env.extendFrameT(env, "scalar", array5dimbool2bool);
      env = Env.extendFrameT(env, "scalar", array6dimbool2bool);
      env = Env.extendFrameT(env, "scalar", array7dimbool2bool);
      env = Env.extendFrameT(env, "scalar", array8dimbool2bool);
      env = Env.extendFrameT(env, "scalar", array1dimstring2string);
      env = Env.extendFrameT(env, "scalar", array2dimstring2string);
      env = Env.extendFrameT(env, "scalar", array3dimstring2string);
      env = Env.extendFrameT(env, "scalar", array4dimstring2string);
      env = Env.extendFrameT(env, "scalar", array5dimstring2string);
      env = Env.extendFrameT(env, "scalar", array6dimstring2string);
      env = Env.extendFrameT(env, "scalar", array7dimstring2string);
      env = Env.extendFrameT(env, "scalar", array8dimstring2string);
      env = Env.extendFrameT(env, "vector", array1dimint2vectorint) "PR. 991024 Continue here." ;
      env = Env.extendFrameT(env, "vector", array2dimint2vectorint);
      env = Env.extendFrameT(env, "vector", array3dimint2vectorint);
      env = Env.extendFrameT(env, "vector", array4dimint2vectorint);
      env = Env.extendFrameT(env, "vector", array5dimint2vectorint);
      env = Env.extendFrameT(env, "vector", array6dimint2vectorint);
      env = Env.extendFrameT(env, "vector", array7dimint2vectorint);
      env = Env.extendFrameT(env, "vector", array8dimint2vectorint);
      env = Env.extendFrameT(env, "vector", array1dimreal2vectorreal);
      env = Env.extendFrameT(env, "vector", array2dimreal2vectorreal);
      env = Env.extendFrameT(env, "vector", array3dimreal2vectorreal);
      env = Env.extendFrameT(env, "vector", array4dimreal2vectorreal);
      env = Env.extendFrameT(env, "vector", array5dimreal2vectorreal);
      env = Env.extendFrameT(env, "vector", array6dimreal2vectorreal);
      env = Env.extendFrameT(env, "vector", array7dimreal2vectorreal);
      env = Env.extendFrameT(env, "vector", array8dimreal2vectorreal);
      env = Env.extendFrameT(env, "vector", array1dimbool2vectorbool);
      env = Env.extendFrameT(env, "vector", array2dimbool2vectorbool);
      env = Env.extendFrameT(env, "vector", array3dimbool2vectorbool);
      env = Env.extendFrameT(env, "vector", array4dimbool2vectorbool);
      env = Env.extendFrameT(env, "vector", array5dimbool2vectorbool);
      env = Env.extendFrameT(env, "vector", array6dimbool2vectorbool);
      env = Env.extendFrameT(env, "vector", array7dimbool2vectorbool);
      env = Env.extendFrameT(env, "vector", array8dimbool2vectorbool);
      env = Env.extendFrameT(env, "vector", array1dimstring2vectorstring);
      env = Env.extendFrameT(env, "vector", array2dimstring2vectorstring);
      env = Env.extendFrameT(env, "vector", array3dimstring2vectorstring);
      env = Env.extendFrameT(env, "vector", array4dimstring2vectorstring);
      env = Env.extendFrameT(env, "vector", array5dimstring2vectorstring);
      env = Env.extendFrameT(env, "vector", array6dimstring2vectorstring);
      env = Env.extendFrameT(env, "vector", array7dimstring2vectorstring);
      env = Env.extendFrameT(env, "vector", array8dimstring2vectorstring);
      env = Env.extendFrameT(env, "matrix", int2matrixint);
      env = Env.extendFrameT(env, "matrix", real2matrixreal);
      env = Env.extendFrameT(env, "matrix", string2matrixstring);
      env = Env.extendFrameT(env, "matrix", bool2matrixbool);
      env = Env.extendFrameT(env, "matrix", array1dimint2matrixint);
      env = Env.extendFrameT(env, "matrix", array2dimint2matrixint);
      env = Env.extendFrameT(env, "matrix", array3dimint2matrixint);
      env = Env.extendFrameT(env, "matrix", array4dimint2matrixint);
      env = Env.extendFrameT(env, "matrix", array5dimint2matrixint);
      env = Env.extendFrameT(env, "matrix", array6dimint2matrixint);
      env = Env.extendFrameT(env, "matrix", array7dimint2matrixint);
      env = Env.extendFrameT(env, "matrix", array8dimint2matrixint);
      env = Env.extendFrameT(env, "matrix", array1dimreal2matrixreal);
      env = Env.extendFrameT(env, "matrix", array2dimreal2matrixreal);
      env = Env.extendFrameT(env, "matrix", array3dimreal2matrixreal);
      env = Env.extendFrameT(env, "matrix", array4dimreal2matrixreal);
      env = Env.extendFrameT(env, "matrix", array5dimreal2matrixreal);
      env = Env.extendFrameT(env, "matrix", array6dimreal2matrixreal);
      env = Env.extendFrameT(env, "matrix", array7dimreal2matrixreal);
      env = Env.extendFrameT(env, "matrix", array8dimreal2matrixreal);
      env = Env.extendFrameT(env, "matrix", array1dimbool2matrixbool);
      env = Env.extendFrameT(env, "matrix", array2dimbool2matrixbool);
      env = Env.extendFrameT(env, "matrix", array3dimbool2matrixbool);
      env = Env.extendFrameT(env, "matrix", array4dimbool2matrixbool);
      env = Env.extendFrameT(env, "matrix", array5dimbool2matrixbool);
      env = Env.extendFrameT(env, "matrix", array6dimbool2matrixbool);
      env = Env.extendFrameT(env, "matrix", array7dimbool2matrixbool);
      env = Env.extendFrameT(env, "matrix", array8dimbool2matrixbool);
      env = Env.extendFrameT(env, "matrix", array1dimstring2matrixstring);
      env = Env.extendFrameT(env, "matrix", array2dimstring2matrixstring);
      env = Env.extendFrameT(env, "matrix", array3dimstring2matrixstring);
      env = Env.extendFrameT(env, "matrix", array4dimstring2matrixstring);
      env = Env.extendFrameT(env, "matrix", array5dimstring2matrixstring);
      env = Env.extendFrameT(env, "matrix", array6dimstring2matrixstring);
      env = Env.extendFrameT(env, "matrix", array7dimstring2matrixstring);
      env = Env.extendFrameT(env, "matrix", array8dimstring2matrixstring);
      env = Env.extendFrameT(env, "transpose", array2dimint2matrixint);
      env = Env.extendFrameT(env, "transpose", array3dimint2matrixint);
      env = Env.extendFrameT(env, "transpose", array4dimint2matrixint);
      env = Env.extendFrameT(env, "transpose", array5dimint2matrixint);
      env = Env.extendFrameT(env, "transpose", array6dimint2matrixint);
      env = Env.extendFrameT(env, "transpose", array2dimreal2matrixreal);
      env = Env.extendFrameT(env, "transpose", array3dimreal2matrixreal);
      env = Env.extendFrameT(env, "transpose", array4dimreal2matrixreal);
      env = Env.extendFrameT(env, "transpose", array5dimreal2matrixreal);
      env = Env.extendFrameT(env, "transpose", array6dimreal2matrixreal);
      env = Env.extendFrameT(env, "transpose", array2dimbool2matrixbool);
      env = Env.extendFrameT(env, "transpose", array3dimbool2matrixbool);
      env = Env.extendFrameT(env, "transpose", array4dimbool2matrixbool);
      env = Env.extendFrameT(env, "transpose", array5dimbool2matrixbool);
      env = Env.extendFrameT(env, "transpose", array6dimbool2matrixbool);
      env = Env.extendFrameT(env, "transpose", array2dimstring2matrixstring);
      env = Env.extendFrameT(env, "transpose", array3dimstring2matrixstring);
      env = Env.extendFrameT(env, "transpose", array4dimstring2matrixstring);
      env = Env.extendFrameT(env, "transpose", array5dimstring2matrixstring);
      env = Env.extendFrameT(env, "transpose", array6dimstring2matrixstring);
      env = Env.extendFrameT(env, "outerproduct", vectorVector2int) "Only real and int makes sense here. And maybe bool." ;
      env = Env.extendFrameT(env, "outerproduct", vectorVector2real);
      env = Env.extendFrameT(env, "diagonal", array1dimint2matrixint);
      env = Env.extendFrameT(env, "diagonal", array1dimreal2matrixreal);
      env = Env.extendFrameT(env, "diagonal", array1dimbool2matrixbool);
      env = Env.extendFrameT(env, "diagonal", array1dimstring2matrixstring);
      env = Env.extendFrameT(env, "zeros", n1int2arrayint) "There is a problem to represents these functions where you do not
 know how many arguments they will take. In this implementation up to 8 arguments are supported." ;
      env = Env.extendFrameT(env, "zeros", n2int2arrayint);
      env = Env.extendFrameT(env, "zeros", n3int2arrayint);
      env = Env.extendFrameT(env, "zeros", n4int2arrayint);
      env = Env.extendFrameT(env, "zeros", n5int2arrayint);
      env = Env.extendFrameT(env, "zeros", n6int2arrayint);
      env = Env.extendFrameT(env, "zeros", n7int2arrayint);
      env = Env.extendFrameT(env, "zeros", n8int2arrayint);
      env = Env.extendFrameT(env, "ones", n1int2arrayint);
      env = Env.extendFrameT(env, "ones", n2int2arrayint);
      env = Env.extendFrameT(env, "ones", n3int2arrayint);
      env = Env.extendFrameT(env, "ones", n4int2arrayint);
      env = Env.extendFrameT(env, "ones", n5int2arrayint);
      env = Env.extendFrameT(env, "ones", n6int2arrayint);
      env = Env.extendFrameT(env, "ones", n7int2arrayint);
      env = Env.extendFrameT(env, "ones", n8int2arrayint);
      env = Env.extendFrameT(env, "array", n1int2arrayint);
      env = Env.extendFrameT(env, "array", n2int2arrayint);
      env = Env.extendFrameT(env, "array", n3int2arrayint);
      env = Env.extendFrameT(env, "array", n4int2arrayint);
      env = Env.extendFrameT(env, "array", n5int2arrayint);
      env = Env.extendFrameT(env, "array", n6int2arrayint);
      env = Env.extendFrameT(env, "array", n7int2arrayint);
      env = Env.extendFrameT(env, "array", n8int2arrayint);
      env = Env.extendFrameT(env, "array", n1real2arrayreal);
      env = Env.extendFrameT(env, "array", n2real2arrayreal);
      env = Env.extendFrameT(env, "array", n3real2arrayreal);
      env = Env.extendFrameT(env, "array", n4real2arrayreal);
      env = Env.extendFrameT(env, "array", n5real2arrayreal);
      env = Env.extendFrameT(env, "array", n6real2arrayreal);
      env = Env.extendFrameT(env, "array", n7real2arrayreal);
      env = Env.extendFrameT(env, "array", n8real2arrayreal);
      env = Env.extendFrameT(env, "linspace", realRealInt2vectorreal);
      env = Env.extendFrameT(env, "min", intInt2int);
      env = Env.extendFrameT(env, "min", realReal2real);
      env = Env.extendFrameT(env, "min", array1dimint2int);
      env = Env.extendFrameT(env, "min", array2dimint2int);
      env = Env.extendFrameT(env, "min", array3dimint2int);
      env = Env.extendFrameT(env, "min", array4dimint2int);
      env = Env.extendFrameT(env, "min", array5dimint2int);
      env = Env.extendFrameT(env, "min", array6dimint2int);
      env = Env.extendFrameT(env, "min", array7dimint2int);
      env = Env.extendFrameT(env, "min", array8dimint2int);
      env = Env.extendFrameT(env, "min", array1dimreal2real);
      env = Env.extendFrameT(env, "min", array2dimreal2real);
      env = Env.extendFrameT(env, "min", array3dimreal2real);
      env = Env.extendFrameT(env, "min", array4dimreal2real);
      env = Env.extendFrameT(env, "min", array5dimreal2real);
      env = Env.extendFrameT(env, "min", array6dimreal2real);
      env = Env.extendFrameT(env, "min", array7dimreal2real);
      env = Env.extendFrameT(env, "min", array8dimreal2real);
      env = Env.extendFrameT(env, "max", intInt2int);
      env = Env.extendFrameT(env, "max", realReal2real);
      env = Env.extendFrameT(env, "max", array1dimint2int);
      env = Env.extendFrameT(env, "max", array2dimint2int);
      env = Env.extendFrameT(env, "max", array3dimint2int);
      env = Env.extendFrameT(env, "max", array4dimint2int);
      env = Env.extendFrameT(env, "max", array5dimint2int);
      env = Env.extendFrameT(env, "max", array6dimint2int);
      env = Env.extendFrameT(env, "max", array7dimint2int);
      env = Env.extendFrameT(env, "max", array8dimint2int);
      env = Env.extendFrameT(env, "max", array1dimreal2real);
      env = Env.extendFrameT(env, "max", array2dimreal2real);
      env = Env.extendFrameT(env, "max", array3dimreal2real);
      env = Env.extendFrameT(env, "max", array4dimreal2real);
      env = Env.extendFrameT(env, "max", array5dimreal2real);
      env = Env.extendFrameT(env, "max", array6dimreal2real);
      env = Env.extendFrameT(env, "max", array7dimreal2real);
      env = Env.extendFrameT(env, "max", array8dimreal2real);
      env = Env.extendFrameT(env, "noEvent", real2real);
      env = Env.extendFrameT(env, "sum", array1dimint2int);
      env = Env.extendFrameT(env, "sum", array2dimint2int);
      env = Env.extendFrameT(env, "sum", array3dimint2int);
      env = Env.extendFrameT(env, "sum", array4dimint2int);
      env = Env.extendFrameT(env, "sum", array5dimint2int);
      env = Env.extendFrameT(env, "sum", array6dimint2int);
      env = Env.extendFrameT(env, "sum", array7dimint2int);
      env = Env.extendFrameT(env, "sum", array8dimint2int);
      env = Env.extendFrameT(env, "sum", array1dimreal2real);
      env = Env.extendFrameT(env, "sum", array2dimreal2real);
      env = Env.extendFrameT(env, "sum", array3dimreal2real);
      env = Env.extendFrameT(env, "sum", array4dimreal2real);
      env = Env.extendFrameT(env, "sum", array5dimreal2real);
      env = Env.extendFrameT(env, "sum", array6dimreal2real);
      env = Env.extendFrameT(env, "sum", array7dimreal2real);
      env = Env.extendFrameT(env, "sum", array8dimreal2real);
      env = Env.extendFrameT(env, "product", array1dimint2int);
      env = Env.extendFrameT(env, "product", array2dimint2int);
      env = Env.extendFrameT(env, "product", array3dimint2int);
      env = Env.extendFrameT(env, "product", array4dimint2int);
      env = Env.extendFrameT(env, "product", array5dimint2int);
      env = Env.extendFrameT(env, "product", array6dimint2int);
      env = Env.extendFrameT(env, "product", array7dimint2int);
      env = Env.extendFrameT(env, "product", array8dimint2int);
      env = Env.extendFrameT(env, "product", array1dimreal2real);
      env = Env.extendFrameT(env, "product", array2dimreal2real);
      env = Env.extendFrameT(env, "product", array3dimreal2real);
      env = Env.extendFrameT(env, "product", array4dimreal2real);
      env = Env.extendFrameT(env, "product", array5dimreal2real);
      env = Env.extendFrameT(env, "product", array6dimreal2real);
      env = Env.extendFrameT(env, "product", array7dimreal2real);
      env = Env.extendFrameT(env, "product", array8dimreal2real);
      env = Env.extendFrameT(env, "pre", real2real);
      env = Env.extendFrameT(env, "pre", int2int);
      env = Env.extendFrameT(env, "pre", bool2bool);
      env = Env.extendFrameT(env, "pre", string2string);
      env = Env.extendFrameT(env, "symmetric", array1dimint2array1dimint);
      env = Env.extendFrameT(env, "symmetric", array2dimint2array2dimint);
      env = Env.extendFrameT(env, "symmetric", array3dimint2array3dimint);
      env = Env.extendFrameT(env, "symmetric", array4dimint2array4dimint);
      env = Env.extendFrameT(env, "symmetric", array5dimint2array5dimint);
      env = Env.extendFrameT(env, "symmetric", array6dimint2array6dimint);
      env = Env.extendFrameT(env, "symmetric", array7dimint2array7dimint);
      env = Env.extendFrameT(env, "symmetric", array8dimint2array8dimint);
      env = Env.extendFrameT(env, "symmetric", array1dimreal2array1dimreal);
      env = Env.extendFrameT(env, "symmetric", array2dimreal2array2dimreal);
      env = Env.extendFrameT(env, "symmetric", array3dimreal2array3dimreal);
      env = Env.extendFrameT(env, "symmetric", array4dimreal2array4dimreal);
      env = Env.extendFrameT(env, "symmetric", array5dimreal2array5dimreal);
      env = Env.extendFrameT(env, "symmetric", array6dimreal2array6dimreal);
      env = Env.extendFrameT(env, "symmetric", array7dimreal2array7dimreal);
      env = Env.extendFrameT(env, "symmetric", array8dimreal2array8dimreal);
      env = Env.extendFrameT(env, "symmetric", array1dimstring2array1dimstring);
      env = Env.extendFrameT(env, "symmetric", array2dimstring2array2dimstring);
      env = Env.extendFrameT(env, "symmetric", array3dimstring2array3dimstring);
      env = Env.extendFrameT(env, "symmetric", array4dimstring2array4dimstring);
      env = Env.extendFrameT(env, "symmetric", array5dimstring2array5dimstring);
      env = Env.extendFrameT(env, "symmetric", array6dimstring2array6dimstring);
      env = Env.extendFrameT(env, "symmetric", array7dimstring2array7dimstring);
      env = Env.extendFrameT(env, "symmetric", array8dimstring2array8dimstring);
      env = Env.extendFrameT(env, "symmetric", array1dimbool2array1dimbool);
      env = Env.extendFrameT(env, "symmetric", array2dimbool2array2dimbool);
      env = Env.extendFrameT(env, "symmetric", array3dimbool2array3dimbool);
      env = Env.extendFrameT(env, "symmetric", array4dimbool2array4dimbool);
      env = Env.extendFrameT(env, "symmetric", array5dimbool2array5dimbool);
      env = Env.extendFrameT(env, "symmetric", array6dimbool2array6dimbool);
      env = Env.extendFrameT(env, "symmetric", array7dimbool2array7dimbool);
      env = Env.extendFrameT(env, "symmetric", array8dimbool2array8dimbool);
      env = Env.extendFrameT(env, "cross", array3dimrealArray3dimreal2array3dimreal);
      env = Env.extendFrameT(env, "skew", array1dimint2array3dimint);
      env = Env.extendFrameT(env, "skew", array1dimreal2array3dimreal);
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
      imports = getInitialImports();        
      env = Util.listFoldR(imports, Env.extendFrameI, env);
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
        (initialProgram,msg) = Parser.parsestring(initialFunctionStr +& initialFunctionStrMM);
        Error.assertion(msg ==& "Ok", msg, Absyn.dummyInfo);
        assocLst = getGlobalRoot(memoryIndex);
        setGlobalRoot(memoryIndex, (b,initialProgram)::assocLst);
      then initialProgram;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Builtin.getInitialFunctions failed."});
      then fail();
  end matchcontinue;
end getInitialFunctions;

public function getInitialImports
"Fetches the list of imports that are implicitly added in the initial environment.
Most of these are renaming imports, e.g. import arccos = acos."
  output list<Absyn.Import> imports;
algorithm
  imports := matchcontinue ()
    local
      Absyn.Program initialProgram;
      list<Absyn.ElementItem> eitems;
      String str;
    case ()
      equation
        false = RTOpts.acceptMetaModelicaGrammar();
      then {};
    case ()
      equation
        str = Settings.getInstallationDirectoryPath() +& "/lib/omc/MetaModelicaBuiltinImports.mo";
        initialProgram = Parser.parse(str);
        Absyn.PROGRAM(classes = {Absyn.CLASS(name = "MetaModelicaBuiltinImports", body = Absyn.PARTS(classParts = {Absyn.PUBLIC(eitems)}))}) = initialProgram;
      then Util.listMap(SCodeUtil.translateEitemlist(eitems,false), SCodeUtil.getImportFromElement);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Failed to get initial imports"});
      then fail();
  end matchcontinue;
end getInitialImports;

end Builtin;

