/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package Builtin
" file:	 Builtin.mo
  package:      Builtin
  description: Builting tyepes and variables

  RCS: $Id$

  This module defines the builtin types, variables and functions in
  Modelica.  The only exported functions are `initial_env\' and
  simple_initial_env.
  
  There are several builtin attributes defined in the builtin types, such as
  unit, start, etc. 
  
"

public import Absyn;
public import SCode;
public import Env;

/* protected imports */
protected import Types;
protected import ClassInf;

/*
- The primitive types 
  These are the primitive types that are used to build the types
  `Real\', `Integer\' etc. 
*/
public constant SCode.Class rlType=SCode.CLASS("RealType",false,false,SCode.R_PREDEFINED_REAL(),
          SCode.PARTS({},{},{},{},{},NONE)) " real type ";

public constant SCode.Class intType=SCode.CLASS("IntegerType",false,false,SCode.R_PREDEFINED_INT(),
          SCode.PARTS({},{},{},{},{},NONE));

public constant SCode.Class strType=SCode.CLASS("StringType",false,false,SCode.R_PREDEFINED_STRING(),
          SCode.PARTS({},{},{},{},{},NONE));

public constant SCode.Class boolType=SCode.CLASS("BooleanType",false,false,SCode.R_PREDEFINED_BOOL(),
          SCode.PARTS({},{},{},{},{},NONE));

protected constant SCode.Class enumType=SCode.CLASS("EnumType",false,false,SCode.R_PREDEFINED_ENUM(),
          SCode.PARTS({},{},{},{},{},NONE));

protected constant SCode.Element unit=SCode.COMPONENT("unit",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("StringType"),NONE),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.STRING(""),false))),NONE,NONE,NONE,NONE) "This `unit\' component is used in several places below, and it is
  declared once here to make the definitions below easier to read." ;

protected constant SCode.Element quantity=SCode.COMPONENT("quantity",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("StringType"),NONE),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.STRING(""),false))),NONE,NONE,NONE,NONE);

protected constant SCode.Element displayUnit=SCode.COMPONENT("displayUnit",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("StringType"),NONE),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.STRING(""),false))),NONE,NONE,NONE,NONE);

protected constant SCode.Element min=SCode.COMPONENT("min",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("RealType"),NONE),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.REAL(-1e+099),false))),NONE,NONE,NONE,NONE);

protected constant SCode.Element max=SCode.COMPONENT("max",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("RealType"),NONE),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.REAL(1e+099),false))),NONE,NONE,NONE,NONE);

protected constant SCode.Element realStart=SCode.COMPONENT("start",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("RealType"),NONE),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.REAL(0.0),false))),NONE,NONE,NONE,NONE);

protected constant SCode.Element integerStart=SCode.COMPONENT("start",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("IntegerType"),NONE),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.INTEGER(0),false))),NONE,NONE,NONE,NONE);

protected constant SCode.Element stringStart=SCode.COMPONENT("start",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("StringType"),NONE),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.STRING(""),false))),NONE,NONE,NONE,NONE);

protected constant SCode.Element booleanStart=SCode.COMPONENT("start",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("BooleanType"),NONE),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.BOOL(false),false))),NONE,NONE,NONE,NONE);

protected constant SCode.Element fixed=SCode.COMPONENT("fixed",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("BooleanType"),NONE),
          SCode.MOD(false,Absyn.NON_EACH(),{},SOME((Absyn.BOOL(false),false))),NONE,NONE,NONE,NONE) "Should be true for variables" ;

protected constant SCode.Element nominal=SCode.COMPONENT("nominal",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("RealType"),NONE),
          SCode.MOD(false,Absyn.NON_EACH(),{},NONE),NONE,NONE,NONE,NONE);

protected constant SCode.Element stateSelect=SCode.COMPONENT("stateSelect",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("StateSelect"),NONE),
          SCode.MOD(false,Absyn.NON_EACH(),{},
          SOME((
          Absyn.CREF(
          Absyn.CREF_QUAL("StateSelect",{},Absyn.CREF_IDENT("default",{}))),false))),NONE,NONE,NONE,NONE);

protected constant list<SCode.Element> stateSelectComps={
          SCode.COMPONENT("never",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("EnumType"),NONE),SCode.NOMOD(),NONE,NONE,NONE,NONE),
          SCode.COMPONENT("avoid",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("EnumType"),NONE),SCode.NOMOD(),NONE,NONE,NONE,NONE),
          SCode.COMPONENT("default",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("EnumType"),NONE),SCode.NOMOD(),NONE,NONE,NONE,NONE),
          SCode.COMPONENT("prefer",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("EnumType"),NONE),SCode.NOMOD(),NONE,NONE,NONE,NONE),
          SCode.COMPONENT("always",Absyn.UNSPECIFIED(),true,false,false,
          SCode.ATTR({},false,false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),Absyn.TPATH(Absyn.IDENT("EnumType"),NONE),SCode.NOMOD(),NONE,NONE,NONE,NONE)} "The StateSelect enumeration" ;

protected constant SCode.Class stateSelectType=SCode.CLASS("StateSelect",false,false,SCode.R_ENUMERATION(),
          SCode.PARTS(stateSelectComps,{},{},{},{},NONE)) "The State Select Type" ;

public constant SCode.Class ExternalObjectType=SCode.CLASS("ExternalObject",false,false,SCode.R_CLASS(),
          SCode.PARTS(
          {},{},{},{},{},NONE)) "ExternalObject type" ;

public constant SCode.Class realType=SCode.CLASS("Real",false,false,SCode.R_PREDEFINED_REAL(),
          SCode.PARTS(
          {unit,quantity,displayUnit,min,max,realStart,fixed,nominal,
          stateSelect},{},{},{},{},NONE)) "- The `Real\' type" ;

protected constant SCode.Class integerType=SCode.CLASS("Integer",false,false,SCode.R_PREDEFINED_INT(),
          SCode.PARTS({quantity,min,max,integerStart,fixed},{},{},{},{},NONE)) "- The `Integer\' type" ;

protected constant SCode.Class stringType=SCode.CLASS("String",false,false,SCode.R_PREDEFINED_STRING(),
          SCode.PARTS({quantity,stringStart},{},{},{},{},NONE)) "- The `String\' type" ;

protected constant SCode.Class booleanType=SCode.CLASS("Boolean",false,false,SCode.R_PREDEFINED_BOOL(),
          SCode.PARTS({quantity,booleanStart,fixed},{},{},{},{},NONE)) "- The `Boolean\' type" ;

protected constant Types.Var timeVar=Types.VAR("time",
          Types.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,(Types.T_REAL({}),NONE),Types.UNBOUND()) "- The `time\' variable" ;

protected 
replaceable type Type_a subtypeof Any;
constant tuple<Types.TType, Option<Type_a>> nil2real=(Types.T_FUNCTION({},(Types.T_REAL({}),NONE)),NONE) "- Some assorted function types" ;

protected constant tuple<Types.TType, Option<Type_a>> nil2bool=(Types.T_FUNCTION({},(Types.T_REAL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> record2str=(Types.T_FUNCTION({("x",(Types.T_COMPLEX(ClassInf.UNKNOWN(""),{},NONE()),NONE))},(Types.T_STRING({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> strStr2bool=(Types.T_FUNCTION({("x",(Types.T_STRING({}),NONE)),("y",(Types.T_STRING({}),NONE))},(Types.T_BOOL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> real2string=(
          Types.T_FUNCTION({("x",(Types.T_REAL({}),NONE))},(Types.T_STRING({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> int2string =(
          Types.T_FUNCTION({("x",(Types.T_INTEGER({}),NONE))},(Types.T_STRING({}),NONE)),NONE);
          
protected constant tuple<Types.TType, Option<Type_a>> bool2string =(
          Types.T_FUNCTION({("x",(Types.T_BOOL({}),NONE))},(Types.T_STRING({}),NONE)),NONE);          
          
protected constant tuple<Types.TType, Option<Type_a>> real2real=(
          Types.T_FUNCTION({("x",(Types.T_REAL({}),NONE))},(Types.T_REAL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> real2int=(
          Types.T_FUNCTION({("x",(Types.T_REAL({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> int2real=(
          Types.T_FUNCTION({("x",(Types.T_INTEGER({}),NONE))},(Types.T_REAL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> realReal2real=(
          Types.T_FUNCTION(
          {("x",(Types.T_REAL({}),NONE)),("y",(Types.T_REAL({}),NONE))},(Types.T_REAL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> int2int=(
          Types.T_FUNCTION({("x",(Types.T_INTEGER({}),NONE))},
          (Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> intInt2int=(
          Types.T_FUNCTION(
          {("x",(Types.T_INTEGER({}),NONE)),
          ("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> bool2bool=(
          Types.T_FUNCTION({("x",(Types.T_BOOL({}),NONE))},(Types.T_BOOL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> string2string=(
          Types.T_FUNCTION({("x",(Types.T_STRING({}),NONE))},(Types.T_STRING({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> real2bool=(
          Types.T_FUNCTION({("x",(Types.T_REAL({}),NONE))},(Types.T_BOOL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> realReal2bool=(
          Types.T_FUNCTION(
          {("x",(Types.T_REAL({}),NONE)),("y",(Types.T_REAL({}),NONE))},(Types.T_BOOL({}),NONE)),NONE);

// for semiLinear and delay
protected constant tuple<Types.TType, Option<Type_a>> realRealReal2real=(
          Types.T_FUNCTION(
          {("x",(Types.T_REAL({}),NONE)),
           ("y",(Types.T_REAL({}),NONE)),
           ("z",(Types.T_REAL({}),NONE))},
          (Types.T_REAL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> realRealReal2Real=(
          Types.T_FUNCTION(
          {("x",(Types.T_REAL({}),NONE)),("y",(Types.T_REAL({}),NONE)),("z",(Types.T_REAL({}),NONE))},(Types.T_REAL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> anyconnector2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ANYTYPE(SOME(ClassInf.CONNECTOR("$dummy$"))),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimint2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimint2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimint2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_INTEGER({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimint2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_INTEGER({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimint2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_INTEGER({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimint2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_INTEGER({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimint2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_INTEGER({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimint2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_INTEGER({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimreal2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimreal2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimreal2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimreal2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimreal2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimreal2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimreal2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimreal2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimreal2real=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_REAL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimreal2real=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_REAL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimreal2real=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_REAL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimreal2real=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_REAL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimreal2real=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_REAL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimreal2real=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_REAL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimreal2real=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_REAL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimreal2real=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_REAL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimstring2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimstring2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimstring2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimstring2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimstring2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimstring2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimstring2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimstring2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimstring2string=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_STRING({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimstring2string=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_STRING({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimstring2string=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_STRING({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimstring2string=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_STRING({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimstring2string=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_STRING({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimstring2string=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_STRING({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimstring2string=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_STRING({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimstring2string=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_STRING({}),NONE)),NONE))},(Types.T_STRING({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimbool2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimbool2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimbool2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimbool2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimbool2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimbool2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimbool2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimbool2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimbool2bool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_BOOL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimbool2bool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_BOOL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimbool2bool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_BOOL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimbool2bool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_BOOL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimbool2bool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_BOOL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimbool2bool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_BOOL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimbool2bool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_BOOL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimbool2bool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_BOOL({}),NONE)),
          NONE))},(Types.T_BOOL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimintInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimintInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimintInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_INTEGER({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimintInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_INTEGER({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimintInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_INTEGER({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimintInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_INTEGER({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimintInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_INTEGER({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimintInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_INTEGER({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimrealInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimrealInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimrealInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_REAL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimrealInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_REAL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimrealInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_REAL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimrealInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_REAL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimrealInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_REAL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimrealInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_REAL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimstringInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimstringInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimstringInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_STRING({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimstringInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_STRING({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimstringInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_STRING({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimstringInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_STRING({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimstringInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_STRING({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimstringInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_STRING({}),NONE)),NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimboolInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimboolInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimboolInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_BOOL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimboolInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_BOOL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimboolInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_BOOL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimboolInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_BOOL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimboolInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_BOOL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimboolInt2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_BOOL({}),NONE)),
          NONE)),("y",(Types.T_INTEGER({}),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimint2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimint2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimint2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimint2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimint2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimint2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimint2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimint2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimint2matrixint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimint2matrixint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimint2matrixint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimint2matrixint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimint2matrixint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimint2matrixint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimint2matrixint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimint2matrixint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimint2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimint2array2dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimint2array3dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimint2array4dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimint2array5dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimint2array6dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimint2array7dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimint2array8dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimreal2array1dimreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimreal2array2dimreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimreal2array3dimreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimreal2array4dimreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimreal2array5dimreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimreal2array6dimreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimreal2array7dimreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimreal2array8dimreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimstring2array1dimstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimstring2array2dimstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimstring2array3dimstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimstring2array4dimstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimstring2array5dimstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimstring2array6dimstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimstring2array7dimstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimstring2array8dimstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimbool2array1dimbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimbool2array2dimbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimbool2array3dimbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimbool2array4dimbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimbool2array5dimbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimbool2array6dimbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimbool2array7dimbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimbool2array8dimbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimreal2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimreal2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimreal2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimreal2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimreal2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimreal2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimreal2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimreal2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimreal2vectorreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimreal2vectorreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimreal2vectorreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimreal2vectorreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimreal2vectorreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimreal2vectorreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimreal2vectorreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimreal2vectorreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimreal2matrixreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimreal2matrixreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimreal2matrixreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimreal2matrixreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimreal2matrixreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimreal2matrixreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimreal2matrixreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimreal2matrixreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimstring2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimstring2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimstring2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimstring2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimstring2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimstring2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimstring2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimstring2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimstring2vectorstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimstring2vectorstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimstring2vectorstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimstring2vectorstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimstring2vectorstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimstring2vectorstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimstring2vectorstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimstring2vectorstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimstring2matrixstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimstring2matrixstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimstring2matrixstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimstring2matrixstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimstring2matrixstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimstring2matrixstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimstring2matrixstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimstring2matrixstring=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimbool2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimbool2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimbool2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimbool2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimbool2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimbool2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimbool2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimbool2vectorint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimbool2vectorbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimbool2vectorbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimbool2vectorbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimbool2vectorbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimbool2vectorbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimbool2vectorbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimbool2vectorbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimbool2vectorbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimbool2matrixbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimbool2matrixbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimbool2matrixbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimbool2matrixbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimbool2matrixbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimbool2matrixbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimbool2matrixbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimbool2matrixbool=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> int2matrixint=(
          Types.T_FUNCTION({("x",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> real2matrixreal=(
          Types.T_FUNCTION({("x",(Types.T_REAL({}),NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> string2matrixstring=(
          Types.T_FUNCTION({("x",(Types.T_STRING({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> bool2matrixbool=(
          Types.T_FUNCTION({("x",(Types.T_BOOL({}),NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> vectorVector2int=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),
          ("y",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> vectorVector2real=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE)),
          ("y",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE))},(Types.T_REAL({}),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> int2array1dimint=(
          Types.T_FUNCTION({("x",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> int2array2dimint=(
          Types.T_FUNCTION({("x",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> int2array3dimint=(
          Types.T_FUNCTION({("x",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> int2array4dimint=(
          Types.T_FUNCTION({("x",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> int2array5dimint=(
          Types.T_FUNCTION({("x",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> int2array6dimint=(
          Types.T_FUNCTION({("x",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> int2array7dimint=(
          Types.T_FUNCTION({("x",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> int2array8dimint=(
          Types.T_FUNCTION({("x",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n1int2arrayint=(
          Types.T_FUNCTION({("x1",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n2int2arrayint=(
          Types.T_FUNCTION(
          {("x1",(Types.T_INTEGER({}),NONE)),
          ("x2",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n3int2arrayint=(
          Types.T_FUNCTION(
          {("x1",(Types.T_INTEGER({}),NONE)),
          ("x2",(Types.T_INTEGER({}),NONE)),("x3",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n4int2arrayint=(
          Types.T_FUNCTION(
          {("x1",(Types.T_INTEGER({}),NONE)),
          ("x2",(Types.T_INTEGER({}),NONE)),("x3",(Types.T_INTEGER({}),NONE)),("x4",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n5int2arrayint=(
          Types.T_FUNCTION(
          {("x1",(Types.T_INTEGER({}),NONE)),
          ("x2",(Types.T_INTEGER({}),NONE)),("x3",(Types.T_INTEGER({}),NONE)),("x4",(Types.T_INTEGER({}),NONE)),
          ("x5",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n6int2arrayint=(
          Types.T_FUNCTION(
          {("x1",(Types.T_INTEGER({}),NONE)),
          ("x2",(Types.T_INTEGER({}),NONE)),("x3",(Types.T_INTEGER({}),NONE)),("x4",(Types.T_INTEGER({}),NONE)),
          ("x5",(Types.T_INTEGER({}),NONE)),("x6",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n7int2arrayint=(
          Types.T_FUNCTION(
          {("x1",(Types.T_INTEGER({}),NONE)),
          ("x2",(Types.T_INTEGER({}),NONE)),("x3",(Types.T_INTEGER({}),NONE)),("x4",(Types.T_INTEGER({}),NONE)),
          ("x5",(Types.T_INTEGER({}),NONE)),("x6",(Types.T_INTEGER({}),NONE)),("x7",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n8int2arrayint=(
          Types.T_FUNCTION(
          {("x1",(Types.T_INTEGER({}),NONE)),
          ("x2",(Types.T_INTEGER({}),NONE)),("x3",(Types.T_INTEGER({}),NONE)),("x4",(Types.T_INTEGER({}),NONE)),
          ("x5",(Types.T_INTEGER({}),NONE)),("x6",(Types.T_INTEGER({}),NONE)),("x7",(Types.T_INTEGER({}),NONE)),
          ("x8",(Types.T_INTEGER({}),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n1real2arrayreal=(
          Types.T_FUNCTION({("x1",(Types.T_REAL({}),NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n2real2arrayreal=(
          Types.T_FUNCTION(
          {("x1",(Types.T_REAL({}),NONE)),
          ("x2",(Types.T_REAL({}),NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n3real2arrayreal=(
          Types.T_FUNCTION(
          {("x1",(Types.T_REAL({}),NONE)),
          ("x2",(Types.T_REAL({}),NONE)),("x3",(Types.T_REAL({}),NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n4real2arrayreal=(
          Types.T_FUNCTION(
          {("x1",(Types.T_REAL({}),NONE)),
          ("x2",(Types.T_REAL({}),NONE)),("x3",(Types.T_REAL({}),NONE)),("x4",(Types.T_REAL({}),NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n5real2arrayreal=(
          Types.T_FUNCTION(
          {("x1",(Types.T_REAL({}),NONE)),
          ("x2",(Types.T_REAL({}),NONE)),("x3",(Types.T_REAL({}),NONE)),("x4",(Types.T_REAL({}),NONE)),
          ("x5",(Types.T_REAL({}),NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n6real2arrayreal=(
          Types.T_FUNCTION(
          {("x1",(Types.T_REAL({}),NONE)),
          ("x2",(Types.T_REAL({}),NONE)),("x3",(Types.T_REAL({}),NONE)),("x4",(Types.T_REAL({}),NONE)),
          ("x5",(Types.T_REAL({}),NONE)),("x6",(Types.T_REAL({}),NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n7real2arrayreal=(
          Types.T_FUNCTION(
          {("x1",(Types.T_REAL({}),NONE)),
          ("x2",(Types.T_REAL({}),NONE)),("x3",(Types.T_REAL({}),NONE)),("x4",(Types.T_REAL({}),NONE)),
          ("x5",(Types.T_REAL({}),NONE)),("x6",(Types.T_REAL({}),NONE)),("x7",(Types.T_REAL({}),NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> n8real2arrayreal=(
          Types.T_FUNCTION(
          {("x1",(Types.T_REAL({}),NONE)),
          ("x2",(Types.T_REAL({}),NONE)),("x3",(Types.T_REAL({}),NONE)),("x4",(Types.T_REAL({}),NONE)),
          ("x5",(Types.T_REAL({}),NONE)),("x6",(Types.T_REAL({}),NONE)),("x7",(Types.T_REAL({}),NONE)),
          ("x8",(Types.T_REAL({}),NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> intInt2vectorreal=(
          Types.T_FUNCTION(
          {("x",(Types.T_INTEGER({}),NONE)),
          ("y",(Types.T_INTEGER({}),NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimint2array3dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimreal2array3dimreal=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE))},
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_REAL({}),NONE)),
          NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2real=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE))},(Types.T_INTEGER({}),NONE)),NONE) "T_ARRAY is appearently not constant. To bad!" ;

protected constant tuple<Types.TType, Option<Type_a>> array2dimint2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE) "Legal syntax: val array2one= (Types.T_FUNCTION({(\"x\",(Types.T_ARRAY(1,(Types.T_REAL({}),NONE)),NONE))}, TYPES.T_INTEGER)
For size(A) to transpose A
val array1dimint2array1dimint = ... already defined" ;

protected constant tuple<Types.TType, Option<Type_a>> array3dimint2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimint2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimint2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimint2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimint2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimint2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array9dimint2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(9)),(Types.T_INTEGER({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimreal2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimreal2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimreal2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimreal2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimreal2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimreal2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimreal2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimreal2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array9dimreal2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(9)),(Types.T_REAL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimstring2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimstring2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimstring2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimstring2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimstring2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimstring2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimstring2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimstring2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array9dimstring2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (
          Types.T_ARRAY(Types.DIM(SOME(9)),(Types.T_STRING({}),NONE)),NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array1dimbool2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array2dimbool2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(2)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array3dimbool2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(3)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array4dimbool2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(4)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array5dimbool2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(5)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array6dimbool2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(6)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array7dimbool2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(7)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array8dimbool2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(8)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

protected constant tuple<Types.TType, Option<Type_a>> array9dimbool2array1dimint=(
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_ARRAY(Types.DIM(SOME(9)),(Types.T_BOOL({}),NONE)),
          NONE))},
          (
          Types.T_ARRAY(Types.DIM(SOME(1)),(Types.T_INTEGER({}),NONE)),NONE)),NONE);

// MetaModelica extension. KS
protected constant tuple<Types.TType, Option<Type_a>> list2list=(
          Types.T_FUNCTION({("x",(Types.T_LIST((Types.T_NOTYPE(),NONE)),NONE))},(Types.T_LIST((Types.T_NOTYPE(),NONE)),NONE)),NONE);








protected constant tuple<Types.TType, Option<Type_a>> list2boolean=(
          Types.T_FUNCTION({("x",(Types.T_LIST((Types.T_NOTYPE(),NONE)),NONE))},(Types.T_BOOL({}),NONE)),NONE);









protected constant tuple<Types.TType, Option<Type_a>> option2boolean=(
          Types.T_FUNCTION({("x",(Types.T_METAOPTION((Types.T_NOTYPE(),NONE)),NONE))},(Types.T_BOOL({}),NONE)),NONE);









protected constant tuple<Types.TType, Option<Type_a>> anyInteger2any=(
          Types.T_FUNCTION({("x1",(Types.T_NOTYPE(),NONE)),("x2",(Types.T_INTEGER({}),NONE))},(Types.T_NOTYPE(),NONE)),NONE);
//----

public function isTanh
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "tanh")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "tanh")))) then (); 
    case (Absyn.FULLYQUALIFIED(inPath)) equation isTanh(inPath); then ();
  end matchcontinue;
end isTanh;

public function isCosh
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "cosh")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "cosh")))) then (); 
    case (Absyn.FULLYQUALIFIED(inPath)) equation isCosh(inPath); then ();
  end matchcontinue;
end isCosh;

public function isACos
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "arccos")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "acos")))) then (); 
    case (Absyn.FULLYQUALIFIED(inPath)) equation isACos(inPath); then ();
  end matchcontinue;
end isACos;

public function isASin
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "arcsin")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "asin")))) then (); 
    case (Absyn.FULLYQUALIFIED(inPath)) equation isASin(inPath); then ();
  end matchcontinue;
end isASin;

public function isATan
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "arctan")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "atan")))) then (); 
    case (Absyn.FULLYQUALIFIED(inPath)) equation isATan(inPath); then ();
  end matchcontinue;
end isATan;

public function isATan2
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "arctan2")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "atan2")))) then (); 
    case (Absyn.FULLYQUALIFIED(inPath)) equation isATan2(inPath); then ();
  end matchcontinue;
end isATan2;

public function isSinh
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "sinh")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "sinh")))) then (); 
    case (Absyn.FULLYQUALIFIED(inPath)) equation isSinh(inPath); then ();
  end matchcontinue;
end isSinh;

public function isSin
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "sin")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "sin")))) then (); 
    case (Absyn.FULLYQUALIFIED(inPath)) equation isSin(inPath); then ();
  end matchcontinue;
end isSin;

public function isCos ""
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "cos")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "cos")))) then (); 
    case (Absyn.FULLYQUALIFIED(inPath)) equation isCos(inPath); then ();
  end matchcontinue;
end isCos;

public function isExp ""
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath) 
    case (Absyn.IDENT(name = "exp")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "exp")))) then (); 
    case (Absyn.FULLYQUALIFIED(inPath)) equation isExp(inPath);  then ();
  end matchcontinue;
end isExp;

public function isLog ""
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "log")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "log")))) then ();    
    case (Absyn.FULLYQUALIFIED(inPath)) equation isLog(inPath); then ();  
  end matchcontinue;
end isLog;

public function isLog10 ""
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "log10")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "log10")))) then (); 
    case (Absyn.FULLYQUALIFIED(inPath)) equation isLog10(inPath); then ();    
  end matchcontinue;
end isLog10;

public function isSqrt ""
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "sqrt")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "sqrt")))) then (); 
    case (Absyn.FULLYQUALIFIED(inPath)) equation isSqrt(inPath); then ();
  end matchcontinue;
end isSqrt;

public function isTan ""
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "tan")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "tan")))) then (); 
    case (Absyn.FULLYQUALIFIED(inPath)) equation isTan(inPath); then ();
  end matchcontinue;
end isTan;



public function simpleInitialEnv "
val array2array=  (Types.T_FUNCTION({(\"x\",(Types.T_ARRAY)},
				      (Types.T_ARRAY),NONE)
val array_array2array=
val int2array= (Types.T_FUNCTION(\"x\",(Types.T_ARRAY(1,_)),NONE)
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
  env := Env.openScope(Env.emptyEnv, false, NONE) "Debug.fprint (\"insttr\",\"Creating initial env.\\n\") &" ;
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
  list<Env.Frame> envb;
  Env.Cache cache;
algorithm 
  env := matchcontinue(cache) 
  	
  	// First look for cached version
    case (cache) equation
      env = Env.getCachedInitialEnv(cache);
    then (cache,env);
    // if no cached version found create initial env.
    case (cache) equation
      env = Env.openScope(Env.emptyEnv, false, NONE);
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
      env = Env.extendFrameV(env, timeVar, NONE, Env.VAR_UNTYPED(), {});

      // MetaModelica extension
      env = Env.extendFrameT(env, "listCar", list2list); // Should be list2any; easier this way. See also rule in Types.subType.
      env = Env.extendFrameT(env, "listCdr", list2list);
      env = Env.extendFrameT(env, "emptyListTest", list2boolean);
      env = Env.extendFrameT(env, "emptyOptionTest", option2boolean);
      env = Env.extendFrameT(env, "metaMGetField", anyInteger2any);
      //----

      env = Env.extendFrameT(env, "initial", nil2real) "non-functions" ;
      env = Env.extendFrameT(env, "terminal", nil2real);
      env = Env.extendFrameT(env, "event", bool2bool);
      env = Env.extendFrameT(env, "switch", bool2bool);
      env = Env.extendFrameT(env, "timeEvent", realReal2bool);
      env = Env.extendFrameT(env, "sample", realReal2bool);
      env = Env.extendFrameT(env, "semiLinear", realRealReal2Real);      
      env = Env.extendFrameT(env, "change", real2bool);
      env = Env.extendFrameT(env, "edge", bool2bool);
      env = Env.extendFrameT(env, "der", real2real);
      /* Removed due to handling in static.mo
      env = Env.extendFrameT(env, "delay", realReal2real);
      env = Env.extendFrameT(env, "delay", realRealReal2Real);
      */      
      env = Env.extendFrameT(env, "cardinality", anyconnector2int);
      env = Env.extendFrameT(env, "div", realReal2real) "non-differentiable functions" ;
      env = Env.extendFrameT(env, "rem", realReal2real);
      env = Env.extendFrameT(env, "ceil", real2int);
      envb = Env.extendFrameT(env, "floor", real2int);
      env = Env.extendFrameT(envb, "integer", real2int);
      env = Env.extendFrameT(env, "abs", real2real) "differentiable functions" ;
      env = Env.extendFrameT(env, "sign", real2real);
      env = Env.extendFrameT(env, "sin", real2real) "Not in the report" ;
      env = Env.extendFrameT(env, "cos", real2real);
      env = Env.extendFrameT(env, "tan", real2real);
      env = Env.extendFrameT(env, "tanh", real2real);      
      env = Env.extendFrameT(env, "sinh", real2real);
      env = Env.extendFrameT(env, "cosh", real2real);      
      env = Env.extendFrameT(env, "arcsin", real2real);
      env = Env.extendFrameT(env, "arccos", real2real);
      env = Env.extendFrameT(env, "arctan", real2real);
      env = Env.extendFrameT(env, "asin", real2real);
      env = Env.extendFrameT(env, "acos", real2real);
      env = Env.extendFrameT(env, "atan", real2real);
      env = Env.extendFrameT(env, "exp", real2real);
      env = Env.extendFrameT(env, "log", real2real);
      env = Env.extendFrameT(env, "ln", real2real);      
      env = Env.extendFrameT(env, "log10", real2real);
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
      env = Env.extendFrameT(env, "identity", int2array1dimint);
      env = Env.extendFrameT(env, "identity", int2array2dimint);
      env = Env.extendFrameT(env, "identity", int2array3dimint);
      env = Env.extendFrameT(env, "identity", int2array4dimint);
      env = Env.extendFrameT(env, "identity", int2array5dimint);
      env = Env.extendFrameT(env, "identity", int2array6dimint);
      env = Env.extendFrameT(env, "identity", int2array7dimint);
      env = Env.extendFrameT(env, "identity", int2array8dimint);
      env = Env.extendFrameT(env, "initial", nil2bool);
      env = Env.extendFrameT(env, "terminal", nil2bool);
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
      env = Env.extendFrameT(env, "linspace", intInt2vectorreal);
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
      env = Env.extendFrameT(env, "cross", array1dimint2array1dimint);
      env = Env.extendFrameT(env, "cross", array1dimreal2array1dimreal);
      env = Env.extendFrameT(env, "skew", array1dimint2array3dimint);
      env = Env.extendFrameT(env, "skew", array1dimreal2array3dimreal);
      env = Env.extendFrameT(env, "sqrt", int2real);
      env = Env.extendFrameT(env, "sqrt", real2real);
      env = Env.extendFrameT(env, "mod", intInt2int); 
      env = Env.extendFrameT(env, "mod", realReal2real);
      /*
      env = Env.extendFrameT(env, "semiLinear", realRealReal2real);
      env = Env.extendFrameT(env, "delay", realReal2real);
      env = Env.extendFrameT(env, "delay", realRealReal2real);
      */
      cache = Env.setCachedInitialEnv(cache,env);
    then (cache,env);
  end matchcontinue;
end initialEnv;
end Builtin;

