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

encapsulated package Builtin
" file:        Builtin.mo
  package:     Builtin
  description: Builting tyepes and variables

  RCS: $Id$

  This module defines the builtin types, variables and functions in Modelica.

  There are several builtin attributes defined in the builtin types, such as unit, start, etc."

public import Absyn;
public import DAE;
public import Env;
public import Error;
public import SCode;
public import FCore;
public import FGraph;

// protected imports
protected import ClassInf;
protected import Config;
protected import Flags;
protected import FGraphBuild;
protected import Global;
protected import List;
protected import Parser;
protected import SCodeUtil;
protected import Settings;
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
protected constant DAE.Type T_REAL_ARRAY_DEFAULT   = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()},   DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_1_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(1)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_2_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(2)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_3_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(3)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_4_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(4)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_5_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(5)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_6_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(6)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_7_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(7)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_8_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(8)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_9_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(9)}, DAE.emptyTypeSource);

// Integer arrays
protected constant DAE.Type T_INT_ARRAY_1_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(1)}, DAE.emptyTypeSource);
protected constant DAE.Type T_INT_ARRAY_2_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(2)}, DAE.emptyTypeSource);
protected constant DAE.Type T_INT_ARRAY_3_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(3)}, DAE.emptyTypeSource);
protected constant DAE.Type T_INT_ARRAY_4_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(4)}, DAE.emptyTypeSource);
protected constant DAE.Type T_INT_ARRAY_5_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(5)}, DAE.emptyTypeSource);
protected constant DAE.Type T_INT_ARRAY_6_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(6)}, DAE.emptyTypeSource);
protected constant DAE.Type T_INT_ARRAY_7_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(7)}, DAE.emptyTypeSource);
protected constant DAE.Type T_INT_ARRAY_8_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(8)}, DAE.emptyTypeSource);
protected constant DAE.Type T_INT_ARRAY_9_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(9)}, DAE.emptyTypeSource);

// Boolean array
protected constant DAE.Type T_BOOL_ARRAY_1_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(1)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_2_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(2)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_3_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(3)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_4_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(4)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_5_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(5)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_6_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(6)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_7_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(7)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_8_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(8)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_9_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(9)}, DAE.emptyTypeSource);

// String arrays
protected constant DAE.Type T_STRING_ARRAY_1_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(1)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_2_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(2)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_3_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(3)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_4_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(4)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_5_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(5)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_6_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(6)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_7_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(7)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_8_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(8)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_9_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(9)}, DAE.emptyTypeSource);

protected constant DAE.Type T_UNKNOWN_ARRAY_1_DEFAULT = DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT, {DAE.DIM_INTEGER(1)}, DAE.emptyTypeSource);

protected constant SCode.Prefixes commonPrefixes =
  SCode.PREFIXES(
    SCode.PUBLIC(),
    SCode.NOT_REDECLARE(),
    SCode.FINAL(), // make everything here final!
    Absyn.NOT_INNER_OUTER(),
    SCode.NOT_REPLACEABLE());

protected constant SCode.Prefixes commonPrefixesNotFinal =
  SCode.PREFIXES(
    SCode.PUBLIC(),
    SCode.NOT_REDECLARE(),
    SCode.NOT_FINAL(), // make everything here final!
    Absyn.NOT_INNER_OUTER(),
    SCode.NOT_REPLACEABLE());

protected
constant SCode.Attributes attrConst = SCode.ATTR({},SCode.POTENTIAL(),SCode.NON_PARALLEL(),SCode.CONST(),Absyn.BIDIR());
constant SCode.Attributes attrParam = SCode.ATTR({},SCode.POTENTIAL(),SCode.NON_PARALLEL(),SCode.PARAM(),Absyn.BIDIR());
constant SCode.Attributes attrParamVectorNoDim = SCode.ATTR({Absyn.NOSUB()},SCode.POTENTIAL(),SCode.NON_PARALLEL(),SCode.PARAM(),Absyn.BIDIR());

//
// The primitive types
// These are the primitive types that are used to build the types
// Real, Integer etc.
protected constant SCode.Element rlType = SCode.CLASS("RealType",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_REAL(),
          SCode.PARTS({},{},{},{},{},{},{},NONE()),SCode.noComment,Absyn.dummyInfo) " real type ";

protected constant SCode.Element intType = SCode.CLASS("IntegerType",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_INTEGER(),
          SCode.PARTS({},{},{},{},{},{},{},NONE()),SCode.noComment,Absyn.dummyInfo);

protected constant SCode.Element strType = SCode.CLASS("StringType",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_STRING(),
          SCode.PARTS({},{},{},{},{},{},{},NONE()),SCode.noComment,Absyn.dummyInfo);

protected constant SCode.Element boolType = SCode.CLASS("BooleanType",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_BOOLEAN(),
          SCode.PARTS({},{},{},{},{},{},{},NONE()),SCode.noComment,Absyn.dummyInfo);

protected constant SCode.Element enumType = SCode.CLASS("EnumType",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_ENUMERATION(),
          SCode.PARTS({},{},{},{},{},{},{},NONE()),SCode.noComment,Absyn.dummyInfo);

protected constant SCode.Element unit = SCode.COMPONENT("unit",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.STRING(""),false)), Absyn.dummyInfo),SCode.noComment,NONE(),Absyn.dummyInfo) "This `unit\' component is used in several places below, and it is
  declared once here to make the definitions below easier to read." ;

protected constant SCode.Element quantity = SCode.COMPONENT("quantity",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.STRING(""),false)), Absyn.dummyInfo),SCode.noComment,NONE(),Absyn.dummyInfo);

protected constant SCode.Element displayUnit = SCode.COMPONENT("displayUnit",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.STRING(""),false)), Absyn.dummyInfo),SCode.noComment,NONE(),Absyn.dummyInfo);

protected constant SCode.Element min = SCode.COMPONENT("min",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.REAL("-1e+099"),false)), Absyn.dummyInfo),SCode.noComment,NONE(),Absyn.dummyInfo);

protected constant SCode.Element max = SCode.COMPONENT("max",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.REAL("1e+099"),false)), Absyn.dummyInfo),SCode.noComment,NONE(),Absyn.dummyInfo);

protected constant SCode.Element startOrigin = SCode.COMPONENT("startOrigin",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.STRING("undefined"),false)), Absyn.dummyInfo),SCode.noComment,NONE(),Absyn.dummyInfo);

protected constant SCode.Element realStart = SCode.COMPONENT("start",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.REAL("0.0"),false)), Absyn.dummyInfo),SCode.noComment,NONE(),Absyn.dummyInfo);

protected constant SCode.Element integerStart = SCode.COMPONENT("start",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("IntegerType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.INTEGER(0),false)), Absyn.dummyInfo),SCode.noComment,NONE(),Absyn.dummyInfo);

protected constant SCode.Element stringStart = SCode.COMPONENT("start",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.STRING(""),false)), Absyn.dummyInfo),SCode.noComment,NONE(),Absyn.dummyInfo);

protected constant SCode.Element booleanStart = SCode.COMPONENT("start",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("BooleanType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.BOOL(false),false)), Absyn.dummyInfo),SCode.noComment,NONE(),Absyn.dummyInfo);

protected constant SCode.Element fixed = SCode.COMPONENT("fixed",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("BooleanType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.BOOL(false),false)), Absyn.dummyInfo),SCode.noComment,NONE(),Absyn.dummyInfo) "Should be true for variables" ;

protected constant SCode.Element nominal = SCode.COMPONENT("nominal",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},NONE(), Absyn.dummyInfo),SCode.noComment,NONE(),Absyn.dummyInfo);

protected constant SCode.Element stateSelect = SCode.COMPONENT("stateSelect",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StateSelect"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},
          SOME((
          Absyn.CREF(
          Absyn.CREF_QUAL("StateSelect",{},Absyn.CREF_IDENT("default",{}))),false)), Absyn.dummyInfo),SCode.noComment,NONE(),Absyn.dummyInfo);

// Extensions for uncertainties
protected constant SCode.Element uncertainty=SCode.COMPONENT("uncertain",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("Uncertainty"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},
          SOME((Absyn.CREF(Absyn.CREF_QUAL("Uncertainty",{},Absyn.CREF_IDENT("given",{}))),false)),Absyn.dummyInfo),SCode.noComment,NONE(),Absyn.dummyInfo);

protected constant SCode.Element distribution = SCode.COMPONENT("distribution",commonPrefixes,attrParam,Absyn.TPATH(Absyn.IDENT("Distribution"),NONE()),
          SCode.NOMOD(),SCode.noComment,NONE(),Absyn.dummyInfo); // Distribution is declared in ModelicaBuiltin.mo
// END Extensions for uncertainties

protected constant list<SCode.Element> stateSelectComps = {
          SCode.COMPONENT("never",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),SCode.noComment,NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("avoid",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),SCode.noComment,NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("default",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),SCode.noComment,NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("prefer",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),SCode.noComment,NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("always",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),SCode.noComment,NONE(),Absyn.dummyInfo)} "The StateSelect enumeration" ;

protected constant list<SCode.Element> uncertaintyComps = {
          SCode.COMPONENT("given",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),SCode.noComment,NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("sought",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),SCode.noComment,NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("refine",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),SCode.noComment,NONE(),Absyn.dummyInfo)} "The Uncertainty enumeration" ;

protected constant SCode.Element stateSelectType = SCode.CLASS("StateSelect",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_ENUMERATION(),
          SCode.PARTS(stateSelectComps,{},{},{},{},{},{},NONE()),SCode.noComment,Absyn.dummyInfo) "The State Select Type";

protected constant SCode.Element uncertaintyType = SCode.CLASS("Uncertainty",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_ENUMERATION(),
          SCode.PARTS(uncertaintyComps,{},{},{},{},{},{},NONE()),SCode.noComment,Absyn.dummyInfo) "The Uncertainty Type";

protected constant SCode.Element ExternalObjectType = SCode.CLASS("ExternalObject",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_CLASS(),
          SCode.PARTS({},{},{},{},{},{},{},NONE()),SCode.noComment,Absyn.dummyInfo) "ExternalObject type" ;

// The Real type
protected constant SCode.Element realType = SCode.CLASS("Real",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_REAL(),
          SCode.PARTS({unit,quantity,displayUnit,min,max,realStart,fixed,nominal,
          stateSelect,uncertainty,distribution,startOrigin},{},{},{},{},{},{},NONE()),SCode.noComment,Absyn.dummyInfo) "- The `Real\' type" ;

// The Integer type
protected constant SCode.Element integerType = SCode.CLASS("Integer",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_INTEGER(),
          SCode.PARTS({quantity,min,max,integerStart,fixed,uncertainty,distribution,startOrigin},{},{},{},{},{},{},NONE()),SCode.noComment,Absyn.dummyInfo) "- The `Integer\' type" ;

// The String type
protected constant SCode.Element stringType = SCode.CLASS("String",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_STRING(),
          SCode.PARTS({quantity,stringStart,startOrigin},{},{},{},{},{},{},NONE()),SCode.noComment,Absyn.dummyInfo) "- The `String\' type" ;

// The Boolean type
protected constant SCode.Element booleanType = SCode.CLASS("Boolean",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_BOOLEAN(),
          SCode.PARTS({quantity,booleanStart,fixed,startOrigin},{},{},{},{},{},{},NONE()),SCode.noComment,Absyn.dummyInfo) "- The `Boolean\' type" ;

// The builtin variable time. See also variableIsBuiltin
protected constant DAE.Var timeVar = DAE.TYPES_VAR("time",
          DAE.dummyAttrInput,
          DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE());

/* Optimica Extensions. Theses variables are considered builtin for Optimica: startTime, finalTime, objectiveIntegrand and objective */
/* Optimica Extensions. The builtin variable startTime. */
protected constant DAE.Var startTimeVar = DAE.TYPES_VAR("startTime",
          DAE.dummyAttrInput,
          DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()) "- The `startTime\' variable" ;

/* Optimica Extensions. The builtin variable finalTime. */
protected constant DAE.Var finalTimeVar = DAE.TYPES_VAR("finalTime",
          DAE.dummyAttrInput,
          DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()) "- The `finalTime\' variable" ;

/* Optimica Extensions. The builtin variable objectiveIntegrand. */
protected constant DAE.Var objectiveIntegrandVar = DAE.TYPES_VAR("objectiveIntegrand",
          DAE.dummyAttrInput,
          DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()) "- The `finalTime\' variable" ;

/* Optimica Extensions. The builtin variable objective. */
protected constant DAE.Var objectiveVar = DAE.TYPES_VAR("objective",
          DAE.dummyAttrInput,
          DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()) "- The `objective\' variable" ;


protected constant DAE.Type stringIntInt2string =
          DAE.T_FUNCTION(
              {
              DAE.FUNCARG("x",DAE.T_STRING_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
              DAE.FUNCARG("y",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
              DAE.FUNCARG("z",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())
              },
              DAE.T_STRING_DEFAULT,
              DAE.FUNCTION_ATTRIBUTES_BUILTIN,
              DAE.emptyTypeSource);

protected constant DAE.Type real2real =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_REAL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type realReal2real =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
             DAE.FUNCARG("y",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_REAL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type int2int =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type int2bool =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_BOOL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type enumeration2int =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_ENUMERATION(NONE(), Absyn.IDENT(""), {}, {}, {}, DAE.emptyTypeSource),DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type intInt2int =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
             DAE.FUNCARG("y",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type intInt2bool =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
             DAE.FUNCARG("y",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_BOOL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type bool2bool =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_BOOL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_BOOL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type real2bool =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_BOOL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type realReal2bool =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
             DAE.FUNCARG("y",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_BOOL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type realRealReal2Real =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
             DAE.FUNCARG("y",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
             DAE.FUNCARG("z",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_REAL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type anyNonExpandableConnector2int =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x", DAE.T_ANYTYPE(SOME(ClassInf.CONNECTOR(Absyn.IDENT("$dummy$"),false)),DAE.emptyTypeSource),DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type anyExpandableConnector2int =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_ANYTYPE(SOME(ClassInf.CONNECTOR(Absyn.IDENT("$dummy$"),true)),DAE.emptyTypeSource),DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type vectorVector2int =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",T_INT_ARRAY_1_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
             DAE.FUNCARG("y",T_INT_ARRAY_1_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type vectorVector2real =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x", T_REAL_ARRAY_1_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
             DAE.FUNCARG("y", T_REAL_ARRAY_1_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_REAL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type intInt2vectorreal =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
             DAE.FUNCARG("y",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            T_REAL_ARRAY_1_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type realRealInt2vectorreal =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
             DAE.FUNCARG("y",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
             DAE.FUNCARG("n",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            T_REAL_ARRAY_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type array2real =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",T_INT_ARRAY_1_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource) "T_ARRAY is appearently not constant. To bad!" ;

protected constant DAE.Type int2boxed =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("index",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_METABOXED_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type string2string =
          DAE.T_FUNCTION(
            {DAE.FUNCARG("x",DAE.T_STRING_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
            DAE.T_STRING_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type array1dimrealarray1dimrealarray1dimreal2array1dimreal =
          DAE.T_FUNCTION(
            {
            DAE.FUNCARG("x",T_REAL_ARRAY_1_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
            DAE.FUNCARG("y",T_REAL_ARRAY_1_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
            DAE.FUNCARG("z",T_REAL_ARRAY_1_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())
            },
            T_REAL_ARRAY_1_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type realrealreal2real =
          DAE.T_FUNCTION(
            {
            DAE.FUNCARG("x",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
            DAE.FUNCARG("y",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
            DAE.FUNCARG("z",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())
            },
            DAE.T_REAL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant SCode.Element timeComp =
          SCode.COMPONENT(
            "time",
            SCode.defaultPrefixes,
            SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.INPUT()),
            Absyn.TPATH(Absyn.IDENT("Real"), NONE()), SCode.NOMOD(),
            SCode.noComment, NONE(), Absyn.dummyInfo);

protected constant SCode.Element startTimeComp =
          SCode.COMPONENT(
            "startTime",
            SCode.defaultPrefixes,
            SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.INPUT()),
            Absyn.TPATH(Absyn.IDENT("Real"), NONE()), SCode.NOMOD(),
            SCode.noComment, NONE(), Absyn.dummyInfo);

protected constant SCode.Element finalTimeComp =
          SCode.COMPONENT(
            "finalTime",
            SCode.defaultPrefixes,
            SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.INPUT()),
            Absyn.TPATH(Absyn.IDENT("Real"), NONE()), SCode.NOMOD(),
            SCode.noComment, NONE(), Absyn.dummyInfo);

protected constant SCode.Element objectiveIntegrandComp =
          SCode.COMPONENT(
            "objectiveIntegrand",
            SCode.defaultPrefixes,
            SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.INPUT()),
            Absyn.TPATH(Absyn.IDENT("Real"), NONE()), SCode.NOMOD(),
            SCode.noComment, NONE(), Absyn.dummyInfo);

protected constant SCode.Element objectiveVarComp =
          SCode.COMPONENT(
            "objectiveVar",
            SCode.defaultPrefixes,
            SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.INPUT()),
            Absyn.TPATH(Absyn.IDENT("Real"), NONE()), SCode.NOMOD(),
            SCode.noComment, NONE(), Absyn.dummyInfo);

public function variableIsBuiltin
 "Returns true if cref is a builtin variable.
  Currently only 'time' is a builtin variable."
  input DAE.ComponentRef cref;
  input Boolean useOptimica;
  output Boolean b;
algorithm
  b := match (cref, useOptimica)
    case(DAE.CREF_IDENT(ident="time"),_) then true;
    case(_,false) then false;

    //If accepting Optimica then these variabels are also builtin
    case(DAE.CREF_IDENT(ident="startTime"),true) then true;
    case(DAE.CREF_IDENT(ident="finalTime"),true) then true;
    case(DAE.CREF_IDENT(ident="objective"),true) then true;
    case(DAE.CREF_IDENT(ident="objectiveIntegrand"),true) then true;

    else false;
  end match;
end variableIsBuiltin;

public function isDer
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    local Absyn.Path path;
    case (Absyn.IDENT(name = "der")) then ();
    case (Absyn.FULLYQUALIFIED(path)) equation isDer(path); then ();
  end match;
end isDer;

public function initialEnv
"The initial environment where instantiation takes place is built
  up using this function.  It creates an empty environment and adds
  all the built-in definitions to it.
  NOTE:
    The following built in operators can not be described in
    the type system, since they e.g. have arbitrary arguments, etc.
  - fill
  - cat
    These operators are catched in the elabBuiltinHandler, along with all
    others."
  input Env.Cache inCache;
  output Env.Cache outCache;
  output Env.Env env;
protected
  Env.Cache cache;
algorithm
  (outCache,env) := matchcontinue(inCache)
    local
      list<Absyn.Class> initialClasses;
      SCode.Program initialProgram;

    // First look for cached version
    case (cache) equation
      env = Env.getCachedInitialEnv(cache);
    then (cache,env);

    // then look in the global roots[builtinEnvIndex]
    case (cache)
      equation
        env = getSetInitialEnv(NONE());
      then
        (cache, env);

    // if no cached version found create initial env.
    case (cache) equation
      env = Env.openScope(Env.emptyEnv, SCode.NOT_ENCAPSULATED(), NONE(), NONE());
      env = Env.extendFrameClasses(env,
              {rlType,
               intType,
               strType,
               boolType,
               enumType,
               ExternalObjectType,
               realType,
               integerType,
               stringType,
               booleanType,
               stateSelectType,
               uncertaintyType},
               SOME(Env.BASIC_TYPE()));

      env = Env.extendFrameV(
              env,
              timeVar,
              timeComp,
              DAE.NOMOD(),
              Env.VAR_UNTYPED(),
              {});

      //If Optimica add the startTime,finalTime,objectiveIntegrand and objective "builtin" variables.
      env = Util.if_(Config.acceptOptimicaGrammar(),
                     Env.extendFrameV(
                       env,
                       objectiveVar,
                       objectiveVarComp,
                       DAE.NOMOD(),
                       Env.VAR_UNTYPED(),
                       {}),
                     env);

      env = Util.if_(Config.acceptOptimicaGrammar(),
                     Env.extendFrameV(
                       env,
                       objectiveIntegrandVar,
                       objectiveIntegrandComp,
                       DAE.NOMOD(),
                       Env.VAR_UNTYPED(),
                       {}),
                     env);

      env = Util.if_(Config.acceptOptimicaGrammar(),
                     Env.extendFrameV(
                       env,
                       startTimeVar,
                       startTimeComp,
                       DAE.NOMOD(),
                       Env.VAR_UNTYPED(),
                       {}),
                     env);

      env = Util.if_(Config.acceptOptimicaGrammar(),
                     Env.extendFrameV(
                       env,
                       finalTimeVar,
                       finalTimeComp,
                       DAE.NOMOD(),
                       Env.VAR_UNTYPED(),
                       {}),
                     env);

      env = Env.extendFrameT(env, "cardinality", anyNonExpandableConnector2int);
      env = Env.extendFrameT(env, "cardinality", anyExpandableConnector2int);
      env = Env.extendFrameT(env, "Integer", enumeration2int);
      env = Env.extendFrameT(env, "EnumToInteger", enumeration2int);
      env = Env.extendFrameT(env, "noEvent", real2real);
      env = Env.extendFrameT(env, "constrain", realrealreal2real);
      env = Env.extendFrameT(env, "constrain", array1dimrealarray1dimrealarray1dimreal2array1dimreal);
      env = Env.extendFrameT(env, "actualStream", real2real);
      env = Env.extendFrameT(env, "inStream", real2real);
      env = Env.extendFrameT(env, "constrain", array1dimrealarray1dimrealarray1dimreal2array1dimreal);

      env = initialEnvMetaModelica(env);

      // add the builtin classes from ModelicaBuiltin.mo and MetaModelicaBuiltin.mo
      Absyn.PROGRAM(classes=initialClasses) = getInitialFunctions();
      env = Env.extendFrameClasses(env, listReverse(List.fold(initialClasses, SCodeUtil.translate2, {})), SOME(Env.BUILTIN()));
      cache = Env.setCachedInitialEnv(cache,env);
      _ = getSetInitialEnv(SOME(env));
    then
      (cache,env);

  end matchcontinue;
end initialEnv;

protected function initialEnvMetaModelica
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(inEnv)
    local
      Env.Env env;
    case (env)
      equation
        true = Config.acceptMetaModelicaGrammar();
        // getGlobalRoot can not be represented by a regular function...
        env = Env.extendFrameT(env, "getGlobalRoot", int2boxed);
        env = Env.extendFrameT(env, "getLocalRoot", int2boxed);
      then env;
    case env then env;
  end matchcontinue;
end initialEnvMetaModelica;

public function getInitialFunctions
"Fetches the Absyn.Program representation of the functions (and other classes) in the initial environment"
  output Absyn.Program initialProgram;
algorithm
  initialProgram := matchcontinue ()
    local
      String fileModelica,fileMetaModelica,fileParModelica;
      list<tuple<Integer,Absyn.Program>> assocLst;
      list<Absyn.Class> classes,classes1,classes2;
    case ()
      equation
        failure(_ = getGlobalRoot(Global.builtinIndex));
        setGlobalRoot(Global.builtinIndex,{});
      then fail();
    case ()
      equation
        assocLst = getGlobalRoot(Global.builtinIndex);
      then Util.assoc(Flags.getConfigEnum(Flags.GRAMMAR), assocLst);
    case ()
      equation
        true = intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.METAMODELICA);
        fileModelica = Settings.getInstallationDirectoryPath() +& "/lib/omc/ModelicaBuiltin.mo";
        fileMetaModelica = Settings.getInstallationDirectoryPath() +& "/lib/omc/MetaModelicaBuiltin.mo";
        Error.assertionOrAddSourceMessage(System.regularFileExists(fileModelica),Error.FILE_NOT_FOUND_ERROR,{fileModelica},Absyn.dummyInfo);
        Error.assertionOrAddSourceMessage(System.regularFileExists(fileMetaModelica),Error.FILE_NOT_FOUND_ERROR,{fileMetaModelica},Absyn.dummyInfo);
        Absyn.PROGRAM(classes=classes1,within_=Absyn.TOP()) = Parser.parsebuiltin(fileModelica,"UTF-8");
        Absyn.PROGRAM(classes=classes2,within_=Absyn.TOP()) = Parser.parsebuiltin(fileMetaModelica,"UTF-8");
        classes = listAppend(classes1,classes2);
        initialProgram = Absyn.PROGRAM(classes,Absyn.TOP(),Absyn.dummyTimeStamp);
        assocLst = getGlobalRoot(Global.builtinIndex);
        setGlobalRoot(Global.builtinIndex, (Flags.METAMODELICA,initialProgram)::assocLst);
      then initialProgram;
    case ()
      equation
        true = intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.PARMODELICA);
        fileModelica = Settings.getInstallationDirectoryPath() +& "/lib/omc/ModelicaBuiltin.mo";
        fileParModelica = Settings.getInstallationDirectoryPath() +& "/lib/omc/ParModelicaBuiltin.mo";
        Error.assertionOrAddSourceMessage(System.regularFileExists(fileModelica),Error.FILE_NOT_FOUND_ERROR,{fileModelica},Absyn.dummyInfo);
        Error.assertionOrAddSourceMessage(System.regularFileExists(fileParModelica),Error.FILE_NOT_FOUND_ERROR,{fileParModelica},Absyn.dummyInfo);
        Absyn.PROGRAM(classes=classes1,within_=Absyn.TOP()) = Parser.parsebuiltin(fileModelica,"UTF-8");
        Absyn.PROGRAM(classes=classes2,within_=Absyn.TOP()) = Parser.parsebuiltin(fileParModelica,"UTF-8");
        classes = listAppend(classes1,classes2);
        initialProgram = Absyn.PROGRAM(classes,Absyn.TOP(),Absyn.dummyTimeStamp);
        assocLst = getGlobalRoot(Global.builtinIndex);
        setGlobalRoot(Global.builtinIndex, (Flags.PARMODELICA,initialProgram)::assocLst);
      then initialProgram;
    case ()
      equation
        true = intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.MODELICA) or intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.OPTIMICA);
        fileModelica = Settings.getInstallationDirectoryPath() +& "/lib/omc/ModelicaBuiltin.mo";
        Error.assertionOrAddSourceMessage(System.regularFileExists(fileModelica),Error.FILE_NOT_FOUND_ERROR,{fileModelica},Absyn.dummyInfo);
        initialProgram = Parser.parsebuiltin(fileModelica,"UTF-8");
        assocLst = getGlobalRoot(Global.builtinIndex);
        setGlobalRoot(Global.builtinIndex, (Flags.MODELICA,initialProgram)::assocLst);
      then initialProgram;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Builtin.getInitialFunctions failed."});
      then fail();
  end matchcontinue;
end getInitialFunctions;

protected function getSetInitialEnv
"gets/sets the initial environment depending on grammar flags"
  input Option<Env.Env> inEnvOpt;
  output Env.Env initialEnv;
algorithm
  initialEnv := matchcontinue (inEnvOpt)
    local
      list<tuple<Integer,Env.Env>> assocLst;
      Env.Env env;

    // nothing there
    case (_)
      equation
        failure(_ = getGlobalRoot(Global.builtinEnvIndex));
        setGlobalRoot(Global.builtinEnvIndex,{});
      then
        fail();

    // return the correct env depending on flags
    case (NONE())
      equation
        assocLst = getGlobalRoot(Global.builtinEnvIndex);
      then
        Util.assoc(Flags.getConfigEnum(Flags.GRAMMAR), assocLst);

    case (SOME(env))
      equation
        true = intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.METAMODELICA);
        assocLst = getGlobalRoot(Global.builtinEnvIndex);
        setGlobalRoot(Global.builtinEnvIndex, (Flags.METAMODELICA,env)::assocLst);
      then
        env;

    case (SOME(env))
      equation
        true = intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.PARMODELICA);
        assocLst = getGlobalRoot(Global.builtinEnvIndex);
        setGlobalRoot(Global.builtinEnvIndex, (Flags.PARMODELICA,env)::assocLst);
      then
        env;

    case (SOME(env))
      equation
        true = intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.MODELICA) or intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.OPTIMICA);
        assocLst = getGlobalRoot(Global.builtinEnvIndex);
        setGlobalRoot(Global.builtinEnvIndex, (Flags.MODELICA,env)::assocLst);
      then
        env;
  end matchcontinue;
end getSetInitialEnv;

public function initialFGraph
"The initial environment where instantiation takes place is built
  up using this function.  It creates an empty environment and adds
  all the built-in definitions to it.
  NOTE:
    The following built in operators can not be described in
    the type system, since they e.g. have arbitrary arguments, etc.
  - fill
  - cat
    These operators are catched in the elabBuiltinHandler, along with all
    others."
  input Env.Cache inCache;
  output Env.Cache outCache;
  output FGraph.Graph graph;
protected
  Env.Cache cache;
algorithm
  (outCache, graph) := match(inCache)
    local
      list<Absyn.Class> initialClasses;
      SCode.Program initialProgram;

    /*/ First look for cached version
    case (cache) equation
      graph = Graph.getCachedInitialFGraph(cache);
    then (cache,graph);

    // then look in the global roots[builtinEnvIndex]
    case (cache)
      equation
        graph = getSetInitialFGraph(NONE());
      then
        (cache, graph);*/

    // if no cached version found create initial graph.
    case (cache)
      equation
        graph = FGraph.new(FCore.dummyTopModel);
        graph = FGraphBuild.mkProgramGraph(
        {rlType,
         intType,
         strType,
         boolType,
         enumType,
         ExternalObjectType,
         realType,
         integerType,
         stringType,
         booleanType,
         stateSelectType,
         uncertaintyType},
         FCore.BASIC_TYPE(),
         graph);


      graph = FGraphBuild.mkCompNode(timeComp, FGraph.top(graph), FCore.BUILTIN(), graph);

      graph = initialFGraphOptimica(graph);

      graph = initialFGraphMetaModelica(graph);

      Absyn.PROGRAM(classes=initialClasses) = getInitialFunctions();
      initialProgram = listReverse(List.fold(initialClasses, SCodeUtil.translate2, {}));
      // add the ModelicaBuiltin/MetaModelicaBuiltin classes in the initial graph
      graph = FGraphBuild.mkProgramGraph(initialProgram, FCore.BUILTIN(), graph);

      graph = FGraphBuild.mkTypeNode(
               {anyNonExpandableConnector2int,
                anyExpandableConnector2int},
               "cardinality", graph);
      graph = FGraphBuild.mkTypeNode({enumeration2int}, "Integer", graph);
      graph = FGraphBuild.mkTypeNode({enumeration2int}, "EnumToInteger", graph);
      graph = FGraphBuild.mkTypeNode({real2real}, "noEvent", graph);
      graph = FGraphBuild.mkTypeNode({real2real}, "actualStream", graph);
      graph = FGraphBuild.mkTypeNode({real2real}, "inStream", graph);
      graph = FGraphBuild.mkTypeNode({realrealreal2real,
                                  array1dimrealarray1dimrealarray1dimreal2array1dimreal,
                                  array1dimrealarray1dimrealarray1dimreal2array1dimreal},
                                 "constrain", graph);
    then
      (cache,graph);

  end match;
end initialFGraph;

protected function getSetInitialFGraph
"gets/sets the initial environment depending on grammar flags"
  input Option<FGraph.Graph> inEnvOpt;
  output FGraph.Graph initialEnv;
algorithm
  initialEnv := matchcontinue (inEnvOpt)
    local
      list<tuple<Integer,FGraph.Graph>> assocLst;
      FGraph.Graph graph;

    // nothing there
    case (_)
      equation
        failure(_ = getGlobalRoot(Global.builtinFGraphIndex));
        setGlobalRoot(Global.builtinFGraphIndex,FGraph.new(FCore.dummyTopModel));
      then
        fail();

    // return the correct graph depending on flags
    case (NONE())
      equation
        assocLst = getGlobalRoot(Global.builtinFGraphIndex);
      then
        Util.assoc(Flags.getConfigEnum(Flags.GRAMMAR), assocLst);

    case (SOME(graph))
      equation
        true = intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.METAMODELICA);
        assocLst = getGlobalRoot(Global.builtinFGraphIndex);
        setGlobalRoot(Global.builtinFGraphIndex, (Flags.METAMODELICA,graph)::assocLst);
      then
        graph;

    case (SOME(graph))
      equation
        true = intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.PARMODELICA);
        assocLst = getGlobalRoot(Global.builtinFGraphIndex);
        setGlobalRoot(Global.builtinFGraphIndex, (Flags.PARMODELICA,graph)::assocLst);
      then
        graph;

    case (SOME(graph))
      equation
        true = intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.MODELICA) or intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.OPTIMICA);
        assocLst = getGlobalRoot(Global.builtinFGraphIndex);
        setGlobalRoot(Global.builtinFGraphIndex, (Flags.MODELICA,graph)::assocLst);
      then
        graph;
  end matchcontinue;
end getSetInitialFGraph;

protected function initialFGraphMetaModelica
  input FGraph.Graph inEnv;
  output FGraph.Graph outEnv;
algorithm
  outEnv := matchcontinue(inEnv)
    local
      FGraph.Graph graph;

    case (graph)
      equation
        true = Config.acceptMetaModelicaGrammar();
        // getGlobalRoot can not be represented by a regular function...
        graph = FGraphBuild.mkTypeNode({int2boxed}, "getGlobalRoot", graph);
      then
        graph;

    case graph then graph;

  end matchcontinue;
end initialFGraphMetaModelica;

protected function initialFGraphOptimica
  input FGraph.Graph inEnv;
  output FGraph.Graph outEnv;
algorithm
  outEnv := matchcontinue(inEnv)
    local
      FGraph.Graph graph;

    case (graph)
      equation
        //If Optimica add the startTime,finalTime,objectiveIntegrand and objective "builtin" variables.
        true = Config.acceptOptimicaGrammar();
        graph = FGraphBuild.mkCompNode(objectiveVarComp, FGraph.top(graph), FCore.BUILTIN(), graph);
        graph = FGraphBuild.mkCompNode(objectiveIntegrandComp, FGraph.top(graph), FCore.BUILTIN(), graph);
        graph = FGraphBuild.mkCompNode(startTimeComp, FGraph.top(graph), FCore.BUILTIN(), graph);
        graph = FGraphBuild.mkCompNode(finalTimeComp, FGraph.top(graph), FCore.BUILTIN(), graph);
      then
        graph;

    case graph then graph;

  end matchcontinue;
end initialFGraphOptimica;

end Builtin;

