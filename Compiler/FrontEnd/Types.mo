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

encapsulated package Types
" file:        Types.mo
  package:     Types
  description: Type system


  This file specifies the type system, as defined in the modelica specification.
  It contains an MetaModelica Compiler (MMC) type called Type which defines types.
  It also contains functions for determining subtyping etc.

  There are a few known problems with this module.
  It currently depends on SCode.Attributes, which in turn depends on Absyn.ArrayDim.
  However, the only things used from those modules are constants that could be moved to their own modules.

"

public import ClassInf;
public import Absyn;
public import DAE;
public import InstTypes;
public import Values;
public import SCode;

protected type Binding = DAE.Binding;
protected type Const = DAE.Const;
protected type EqualityConstraint = DAE.EqualityConstraint;
protected type FuncArg = DAE.FuncArg;
protected type Properties = DAE.Properties;
protected type TupleConst = DAE.TupleConst;
protected type Type = DAE.Type;
protected type Var = DAE.Var;
protected type EqMod = DAE.EqMod;

protected import ComponentReference;
protected import Config;
protected import Dump;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import List;
protected import Patternm;
protected import Print;
protected import Util;
protected import System;
protected import ValuesUtil;
protected import DAEUtil;
protected import SCodeDump;
protected import MetaModelica.Dangerous.listReverseInPlace;

public function discreteType "Succeeds for all the discrete types, Integer, String, Boolean and enumeration."
  input DAE.Type inType;
algorithm
  true := isDiscreteType(inType);
end discreteType;

public function isDiscreteType
  input DAE.Type inType;
  output Boolean outIsDiscrete;
algorithm
  outIsDiscrete := match inType
    case DAE.T_INTEGER() then true;
    case DAE.T_STRING() then true;
    case DAE.T_BOOL() then true;
    case DAE.T_CLOCK() then true;
    case DAE.T_ENUMERATION() then true;
    case DAE.T_SUBTYPE_BASIC() then isDiscreteType(inType.complexType);
    else false;
  end match;
end isDiscreteType;

public function propsAnd "Function for merging a list of properties, currently only working on DAE.PROP() and not TUPLE_DAE.PROP()."
  input list<DAE.Properties> inProps;
  output DAE.Properties outProp;
algorithm outProp := matchcontinue(inProps)
  local
    Properties prop,prop2;
    Const c,c2;
    Type ty,ty2;
    list<DAE.Properties> props;

  case(prop::{}) then prop;
  case((DAE.PROP(ty,c))::props)
    equation
      (DAE.PROP(ty2,c2)) = propsAnd(props);
      c = constAnd(c,c2);
      true = equivtypes(ty,ty2);
    then
      DAE.PROP(ty,c);
end matchcontinue;
end propsAnd;

public function makePropsNotConst
"returns the same Properties but with the const flag set to Var"
  input DAE.Properties inProperties;
  output DAE.Properties outProperties;
algorithm outProperties := match (inProperties)
  local
    Type t;
  case(DAE.PROP(type_=t)) then DAE.PROP(t,DAE.C_VAR());
  end match;
end makePropsNotConst;

// stefan
public function getConstList
"retrieves a list of Consts from a list of Properties"
  input list<DAE.Properties> inPropertiesList;
  output list<DAE.Const> outConstList;
algorithm
  outConstList := match(inPropertiesList)
    local
      Const c;
      list<DAE.Const> ccdr;
      list<DAE.Properties> pcdr;
      TupleConst tc;
    case({}) then {};
    case(DAE.PROP(constFlag=c) :: pcdr)
      equation
        ccdr = getConstList(pcdr);
      then
        c :: ccdr;
    case(DAE.PROP_TUPLE(tupleConst=tc) :: pcdr)
      equation
        c = propertiesListToConst2(tc);
        ccdr = getConstList(pcdr);
      then
        c :: ccdr;
  end match;
end getConstList;


public function propertiesListToConst "this function elaborates on a DAE.Properties and return the DAE.Const value."
  input list<DAE.Properties> p;
  output DAE.Const c;
algorithm
  c := match (p)
    local
      Properties p1;
      list<DAE.Properties> pps;
      Const c1,c2;
      TupleConst tc1;

    case({}) then DAE.C_CONST();

    case ((DAE.PROP(_,c1))::pps)
      equation
        c2 = propertiesListToConst(pps);
        c1 = constAnd(c1, c2);
      then
        c1;

    case((DAE.PROP_TUPLE(_,tc1))::pps)
      equation
        c1 = propertiesListToConst2(tc1);
        c2 = propertiesListToConst(pps);
        c1 = constAnd(c1, c2);
      then
        c1;
  end match;
end propertiesListToConst;

protected function propertiesListToConst2 ""
  input DAE.TupleConst t;
  output DAE.Const c;
algorithm
  c := match (t)
    local
      TupleConst p1;
      Const c1,c2;
      list<TupleConst> tcxl;
      TupleConst tc1;

    case (DAE.SINGLE_CONST(c1)) then c1;

    case(DAE.TUPLE_CONST(tc1::tcxl))
      equation
        c1 = propertiesListToConst2(tc1);
        c2 = tupleConstListToConst(tcxl);
        c1 = constAnd(c1, c2);
      then
        c1;
  end match;
end propertiesListToConst2;

public function tupleConstListToConst ""
  input list<DAE.TupleConst> t;
  output DAE.Const c;
algorithm
  c := match (t)
    local
      TupleConst p1;
      Const c1,c2;
      list<TupleConst> tcxl;

    case({}) then DAE.C_CONST();

    case((DAE.SINGLE_CONST(c1))::tcxl)
      equation
        c2 = tupleConstListToConst(tcxl);
        c1 = constAnd(c1, c2);
      then
        c1;

    case((p1 as DAE.TUPLE_CONST(_))::tcxl)
      equation
        c1 = propertiesListToConst2(p1);
        c2 = tupleConstListToConst(tcxl);
        c1 = constAnd(c1, c2);
      then
        c1;
  end match;
end tupleConstListToConst;

public function externalObjectType
"author: PA
 Succeeds if type is ExternalObject"
  input DAE.Type inType;
algorithm
  _ := match (inType)
    case DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_)) then ();
  end match;
end externalObjectType;

public function varName "
Author BZ, 2009-09
Function for getting the name of a DAE.Var"
  input DAE.Var v;
  output String s;
algorithm
  DAE.TYPES_VAR(name = s) := v;
end varName;

public function varBinding
  input DAE.Var inVar;
  output DAE.Binding outBinding;
algorithm
  DAE.TYPES_VAR(binding = outBinding) := inVar;
end varBinding;

public function varEqualName
  input DAE.Var inVar1;
  input DAE.Var inVar2;
  output Boolean outEqual;
protected
  String name1, name2;
algorithm
  DAE.TYPES_VAR(name = name1) := inVar1;
  DAE.TYPES_VAR(name = name2) := inVar2;
  outEqual := name1 == name2;
end varEqualName;

public function externalObjectConstructorType "author: PA
  Succeeds if type is ExternalObject constructor function"
  input DAE.Type inType;
algorithm
  _ := match (inType)
    local Type tp;
    case DAE.T_FUNCTION(funcResultType = tp)
      equation
        externalObjectType(tp);
      then ();
  end match;
end externalObjectConstructorType;

public function simpleType "author: PA
  Succeeds for all the builtin types, Integer, String, Real, Boolean"
  input DAE.Type inType;
algorithm
  true := isSimpleType(inType);
end simpleType;

public function isSimpleType
  "Returns true for all the builtin types, Integer, String, Real, Boolean"
  input DAE.Type inType;
  output Boolean b;
algorithm
  b := match (inType)
    local DAE.Type t;
    case (DAE.T_REAL()) then true;
    case (DAE.T_INTEGER()) then true;
    case (DAE.T_STRING()) then true;
    case (DAE.T_BOOL()) then true;
    // BTH
    case (DAE.T_CLOCK()) then true;
    case (DAE.T_ENUMERATION()) then true;
    case (DAE.T_SUBTYPE_BASIC(complexType = t)) then isSimpleType(t);
    else false;
  end match;
end isSimpleType;

public function isSimpleNumericType
  "Returns true for simple numeric builtin types, Integer and Real"
  input DAE.Type inType;
  output Boolean b;
algorithm
  b := match (inType)
    local DAE.Type t;
    case (DAE.T_REAL()) then true;
    case (DAE.T_INTEGER()) then true;
    case (DAE.T_SUBTYPE_BASIC(complexType = t)) then isSimpleNumericType(t);
    else false;
  end match;
end isSimpleNumericType;

public function isNumericType "This function checks if the element type is Numeric type or array of Numeric type."
  input DAE.Type inType;
  output Boolean outBool;
algorithm
  outBool := match (inType)
    local Type ty;

    case (DAE.T_ARRAY(ty = ty)) then isNumericType(ty);
    case (DAE.T_SUBTYPE_BASIC(complexType = ty)) then isNumericType(ty);
    else isSimpleNumericType(inType);

  end match;
end isNumericType;

public function isConnector
  "Returns true if the given type is a connector type, otherwise false."
  input DAE.Type inType;
  output Boolean outIsConnector;
algorithm
  outIsConnector := match(inType)
    case DAE.T_COMPLEX(complexClassType = ClassInf.CONNECTOR()) then true;
    case DAE.T_SUBTYPE_BASIC(complexClassType = ClassInf.CONNECTOR()) then true;
    else false;
  end match;
end isConnector;

public function isComplexConnector
  "Returns true if the given type is a complex connector type, i.e. a connector
   with components, otherwise false."
  input DAE.Type inType;
  output Boolean outIsComplexConnector;
algorithm
  outIsComplexConnector := match(inType)
    case DAE.T_COMPLEX(complexClassType = ClassInf.CONNECTOR()) then true;
    else false;
  end match;
end isComplexConnector;

public function isComplexExpandableConnector
  "Returns true if the given type is an expandable connector, otherwise false."
  input DAE.Type inType;
  output Boolean outResult;
algorithm
  outResult := match(inType)
    case DAE.T_COMPLEX(complexClassType =
      ClassInf.CONNECTOR(isExpandable = true)) then true;
    case DAE.T_SUBTYPE_BASIC(complexClassType =
      ClassInf.CONNECTOR(isExpandable = true)) then true;
    else false;
  end match;
end isComplexExpandableConnector;

public function isComplexType "
Author: BZ, 2008-11
This function checks wheter a type is complex AND not extending a base type."
  input DAE.Type ity;
  output Boolean b;
algorithm
  b := match(ity)
    local Type ty;
    case (DAE.T_SUBTYPE_BASIC(complexType = ty)) then isComplexType(ty);
    case (DAE.T_COMPLEX(varLst = _::_)) then true; // not derived from baseclass
    else false;
  end match;
end isComplexType;

public function isExternalObject "Returns true if type is COMPLEX and external object (ClassInf)"
  input DAE.Type tp;
  output Boolean b;
algorithm
  b := match(tp)
    case (DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_))) then true;
    else false;
  end match;
end isExternalObject;

public function expTypetoTypesType
" Converts a DAE.Type to a DAE.Type
 NOTE: This function should not be used in general, since it is not recommended to translate DAE.Type into DAE.Type."
  input DAE.Type inType;
  output DAE.Type oType;
algorithm
  oType := matchcontinue(inType)
    local
      Type ty,tty;
      Type at;
      DAE.Dimensions ad;
      DAE.Dimension dim;
      DAE.TypeSource ts;
      Integer ll;
      list<DAE.Var> vars;
      ClassInf.State CIS;
      DAE.EqualityConstraint ec;

    // convert just the array!
    case(DAE.T_ARRAY(at,dim::ad,ts))
      equation
        ll = listLength(ad);
        true = (ll == 0);
        ty = expTypetoTypesType(at);
        tty = DAE.T_ARRAY(ty,{dim},ts);
      then
        tty;
    case(DAE.T_ARRAY(at,dim::ad,ts))
      equation
        ll = listLength(ad);
        true = (ll > 0);
        ty = expTypetoTypesType(DAE.T_ARRAY(at,ad,ts));
        tty = DAE.T_ARRAY(ty,{dim},ts);
      then
        tty;

    case (DAE.T_COMPLEX(CIS, vars, ec, ts))
      equation
        vars = List.map(vars, convertFromExpToTypesVar);
      then
        DAE.T_COMPLEX(CIS, vars, ec, ts);

    case (DAE.T_SUBTYPE_BASIC(CIS, vars, ty, ec, ts))
      equation
        vars = List.map(vars, convertFromExpToTypesVar);
        ty = expTypetoTypesType(ty);
      then
        DAE.T_SUBTYPE_BASIC(CIS, vars, ty, ec, ts);

    case (DAE.T_METABOXED(ty, ts))
      equation
        ty = expTypetoTypesType(ty);
      then
        DAE.T_METABOXED(ty, ts);

    // the rest fall in line!
    else inType;

  end matchcontinue;
end expTypetoTypesType;

protected function convertFromExpToTypesVar ""
  input DAE.Var inVar;
  output DAE.Var outVar;
algorithm
  outVar := matchcontinue(inVar)
    local
      String name;
      Type ty;
      DAE.Attributes attributes;
      Binding binding;
      Option<DAE.Const> constOfForIteratorRange;

    case(DAE.TYPES_VAR(name, attributes, ty, binding, constOfForIteratorRange))
      equation
        ty = expTypetoTypesType(ty);
      then
        DAE.TYPES_VAR(name, attributes, ty, binding, constOfForIteratorRange);

    else equation print("error in Types.convertFromExpToTypesVar\n"); then fail();

  end matchcontinue;
end convertFromExpToTypesVar;

public function isTuple "Returns true if type is TUPLE"
  input DAE.Type tp;
  output Boolean b;
algorithm
  b := match(tp)
    case (DAE.T_TUPLE()) then true;
    else false;
  end match;
end isTuple;

public function isMetaTuple "Returns true if type is TUPLE"
  input DAE.Type tp;
  output Boolean b;
algorithm
  b := match(tp)
    case (DAE.T_METATUPLE()) then true;
    else false;
  end match;
end isMetaTuple;

public function isRecord "Returns true if type is COMPLEX and a record (ClassInf)"
  input DAE.Type tp;
  output Boolean b;
algorithm
  b := match(tp)
    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_))) then true;
    else false;
  end match;
end isRecord;

public function getRecordPath "gets the record path"
  input DAE.Type tp;
  output Absyn.Path p;
algorithm
  p := match(tp)
    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(p)))
      then p;
  end match;
end getRecordPath;

public function isRecordWithOnlyReals "Returns true if type is a record only containing Reals"
  input DAE.Type tp;
  output Boolean b;
algorithm
  b := match (tp)
    local
      list<DAE.Var> varLst;

    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_),varLst = varLst))
      then List.mapAllValueBool(List.map(varLst,getVarType),isReal,true);

    // otherwise false
    else false;
  end match;
end isRecordWithOnlyReals;

public function getVarType "Return the Type of a Var"
  input DAE.Var v;
  output DAE.Type tp;
algorithm
  tp := match (v)
    case(DAE.TYPES_VAR(ty = tp)) then tp;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Types.getVarType failed"});
      then fail();
  end match;
end getVarType;

public function varIsVariable
  input DAE.Var v;
  output Boolean b;
algorithm
  b := match v
    case DAE.TYPES_VAR(attributes=DAE.ATTR(variability=SCode.VAR())) then true;
    case DAE.TYPES_VAR(attributes=DAE.ATTR(variability=SCode.DISCRETE())) then true;
    else false;
  end match;
end varIsVariable;

public function getVarName "Return the name of a Var"
  input DAE.Var v;
  output String name;
algorithm
  name := match (v)
    case(DAE.TYPES_VAR(name = name)) then name;
  end match;
end getVarName;

public function isReal "Returns true if type is Real"
  input DAE.Type tp;
  output Boolean res;
algorithm
  res := isScalarReal(arrayElementType(tp));
end isReal;

public function isScalarReal
  input DAE.Type inType;
  output Boolean outIsScalarReal;
algorithm
  outIsScalarReal := match(inType)
    local
      Type ty;

    case DAE.T_REAL() then true;
    case DAE.T_SUBTYPE_BASIC(complexType = ty) then isScalarReal(ty);
    else false;
  end match;
end isScalarReal;

public function isRealOrSubTypeReal "
Author BZ 2008-05
This function verifies if it is some kind of a Real type we are working with."
  input DAE.Type inType;
  output Boolean b;
protected
  Boolean lb1, lb2;
algorithm
  lb1 := isReal(inType);
  lb2 := equivtypes(inType, DAE.T_REAL_DEFAULT);
  b := lb1 or lb2;
end isRealOrSubTypeReal;

public function isIntegerOrSubTypeInteger "
Author BZ 2009-02
This function verifies if it is some kind of a Integer type we are working with."
  input DAE.Type inType;
  output Boolean b;
protected
  Boolean lb1, lb2;
algorithm
  lb1 := isInteger(inType);
  lb2 := equivtypes(inType, DAE.T_INTEGER_DEFAULT);
  b := lb1 or lb2;
end isIntegerOrSubTypeInteger;

protected function isClockOrSubTypeClock1
  input DAE.Type inType;
  output Boolean b;
protected
  Boolean lb1, lb2, lb3;
algorithm
  lb1 := isClock(inType);
  lb2 := equivtypes(inType, DAE.T_CLOCK_DEFAULT);
  lb3 := not equivtypes(inType, DAE.T_UNKNOWN_DEFAULT);
  b := lb1 or (lb2 and lb3);
end isClockOrSubTypeClock1;

public function isClockOrSubTypeClock
  input DAE.Type inType;
  output Boolean b;
algorithm
  b := match inType
    local
      DAE.Type ty;
    case DAE.T_FUNCTION(funcResultType=ty)
      then isClockOrSubTypeClock1(ty);
    else isClockOrSubTypeClock1(inType);
  end match;
end isClockOrSubTypeClock;

public function isBooleanOrSubTypeBoolean
"@author: adrpo
 This function verifies if it is some kind of a Boolean type we are working with."
  input DAE.Type inType;
  output Boolean b;
protected
  Boolean lb1, lb2;
algorithm
  lb1 := isBoolean(inType);
  lb2 := equivtypes(inType, DAE.T_BOOL_DEFAULT);
  b := lb1 or lb2;
end isBooleanOrSubTypeBoolean;

public function isStringOrSubTypeString
"@author: adrpo
 This function verifies if it is some kind of a String type we are working with."
  input DAE.Type inType;
  output Boolean b;
protected
  Boolean lb1, lb2;
algorithm
  lb1 := isString(inType);
  lb2 := equivtypes(inType, DAE.T_STRING_DEFAULT);
  b := lb1 or lb2;
end isStringOrSubTypeString;

public function isIntegerOrRealOrSubTypeOfEither
  "Checks if a type is either some Integer or Real type."
  input DAE.Type t;
  output Boolean b;
algorithm
  b := match(t)
    case _ guard isRealOrSubTypeReal(t) then true;
    case _ guard isIntegerOrSubTypeInteger(t) then true;
    else false;
  end match;
end isIntegerOrRealOrSubTypeOfEither;

public function isIntegerOrRealOrBooleanOrSubTypeOfEither
  "Checks if a type is either some Integer or Real type."
  input DAE.Type t;
  output Boolean b;
algorithm
  b := match(t)
    case _ guard isRealOrSubTypeReal(t) then true;
    case _ guard isIntegerOrSubTypeInteger(t) then true;
    case _ guard isBooleanOrSubTypeBoolean(t) then true;
    else false;
  end match;
end isIntegerOrRealOrBooleanOrSubTypeOfEither;

public function isClock
  input DAE.Type tp;
  output Boolean res;
algorithm
  res := isScalarClock(arrayElementType(tp));
end isClock;

public function isScalarClock
  input DAE.Type inType;
  output Boolean res;
algorithm
  res := match inType
  local
    Type ty;
  case DAE.T_CLOCK() then true;
  case DAE.T_SUBTYPE_BASIC(complexType = ty) then isScalarClock(ty);
  else false;
  end match;
end isScalarClock;

public function isInteger "Returns true if type is Integer"
  input DAE.Type tp;
  output Boolean res;
algorithm
  res := isScalarInteger(arrayElementType(tp));
end isInteger;

public function isScalarInteger
  input DAE.Type inType;
  output Boolean outIsScalarInteger;
algorithm
  outIsScalarInteger := match(inType)
    local
      Type ty;

    case DAE.T_INTEGER() then true;
    case DAE.T_SUBTYPE_BASIC(complexType = ty) then isScalarInteger(ty);
    else false;
  end match;
end isScalarInteger;

public function isBoolean "Returns true if type is Boolean"
  input DAE.Type tp;
  output Boolean res;
algorithm
  res := isScalarBoolean(arrayElementType(tp));
end isBoolean;

public function isScalarBoolean
  input DAE.Type inType;
  output Boolean outIsScalarBoolean;
algorithm
  outIsScalarBoolean := match(inType)
    local
      Type ty;

    case DAE.T_BOOL() then true;
    case DAE.T_SUBTYPE_BASIC(complexType = ty) then isScalarBoolean(ty);
    else false;
  end match;
end isScalarBoolean;

public function integerOrReal "author: PA
  Succeeds for the builtin types Integer and Real
  (including classes extending the basetype Integer or Real)."
  input DAE.Type inType;
algorithm
  _ := match (inType)
    local Type tp;
    case (DAE.T_REAL()) then ();
    case (DAE.T_INTEGER()) then ();
    case (DAE.T_SUBTYPE_BASIC(complexType = tp))
      equation
        integerOrReal(tp);
      then ();
  end match;
end integerOrReal;

public function isNonscalarArray
  "Returns true if Type is an nonscalar array (array of arrays)."
  input DAE.Type inType;
  input DAE.Dimensions inDims;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inType,inDims)
      local
        Type t;
        list<Type> tys;
        Boolean b;
    // several (at least 2) dimensions means array!
    case (_, _::_::_) then true;
    // if the type is an array, then is an array
    case (DAE.T_ARRAY(),_) then true;
    // if is a type extending basic type
    case (DAE.T_SUBTYPE_BASIC(complexType = t),_) then isNonscalarArray(t, {});
    case (DAE.T_TUPLE(types = tys), _)
      equation
        b = List.applyAndFold1(tys, boolOr, isNonscalarArray, {}, false);
      then
        b;
    else false;
  end matchcontinue;
end isNonscalarArray;

public function isArray
  "Returns true if the given type is an array type."
  input DAE.Type inType;
  output Boolean outIsArray;
algorithm
  outIsArray := match inType
    case DAE.T_ARRAY() then true;
    case DAE.T_SUBTYPE_BASIC() then isArray(inType.complexType);
    case DAE.T_FUNCTION() then isArray(inType.funcResultType);
    else false;
  end match;
end isArray;

public function isEmptyArray
  input DAE.Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inType)
    case DAE.T_ARRAY(dims = {DAE.DIM_INTEGER(0)}) then true;
    else false;
  end match;
end isEmptyArray;

public function isString "Return true if Type is the builtin String type."
  input DAE.Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inType)
    case (DAE.T_STRING()) then true;
    else false;
  end match;
end isString;

public function isEnumeration "Return true if Type is the builtin String type."
  input DAE.Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inType)
    case (DAE.T_ENUMERATION()) then true;
    else false;
  end match;
end isEnumeration;

public function isArrayOrString "Return true if Type is array or the builtin String type."
  input DAE.Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inType)
    local Type ty;
    case ty guard isArray(ty) then true;
    case ty guard isString(ty) then true;
    else false;
  end match;
end isArrayOrString;

public function numberOfDimensions "Return the number of dimensions of a Type."
  input DAE.Type inType;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inType)
    local
      Integer n;
      Type t;
      DAE.Dimensions dims;

    case (DAE.T_ARRAY(ty = t, dims = dims))
      equation
        n = numberOfDimensions(t);
        n = n + listLength(dims);
      then
        n;
    case (DAE.T_SUBTYPE_BASIC(complexType = t))
      equation
        n = numberOfDimensions(t);
      then n;
    else 0;
  end matchcontinue;
end numberOfDimensions;

public function dimensionsKnown
  "Returns true if the dimensions of the type is known."
  input DAE.Type inType;
  output Boolean outRes;
algorithm
  outRes := matchcontinue(inType)
    local
      DAE.Dimension d;
      DAE.Dimensions dims;
      Type tp;
      DAE.TypeSource ts;

    case (DAE.T_ARRAY(dims = d::dims, ty = tp, source = ts))
      equation
        true = Expression.dimensionKnown(d);
        true = dimensionsKnown(DAE.T_ARRAY(tp, dims, ts));
      then
        true;

    case (DAE.T_ARRAY(dims = {}, ty = tp))
      equation
        true = dimensionsKnown(tp);
      then
        true;

    case (DAE.T_ARRAY())
      then false;

    case (DAE.T_SUBTYPE_BASIC(complexType = tp))
      then dimensionsKnown(tp);

    else true;
  end matchcontinue;
end dimensionsKnown;

public function getDimensionSizes "Return the dimension sizes of a Type."
  input DAE.Type inType;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inType)
    local
      list<Integer> res;
      DAE.Dimension d;
      DAE.Dimensions dims;
      Integer i;
      Type tp;
      DAE.TypeSource ts;

    case (DAE.T_ARRAY(dims = d::dims,ty = tp, source = ts))
      equation
        i = Expression.dimensionSize(d);
        res = getDimensionSizes(DAE.T_ARRAY(tp, dims, ts));
      then
        (i :: res);

    case (DAE.T_ARRAY(dims = _::dims, ty = tp, source = ts))
      equation
        res = getDimensionSizes(DAE.T_ARRAY(tp, dims, ts));
      then
        (0 :: res);

    case (DAE.T_ARRAY(dims = {},ty = tp))
      equation
        res = getDimensionSizes(tp);
      then
        res;

    case (DAE.T_SUBTYPE_BASIC(complexType=tp))
      then getDimensionSizes(tp);

    else
      equation
        false = arrayType(inType);
      then
        {};
  end matchcontinue;
end getDimensionSizes;

public function getDimensionProduct "Return the dimension sizes of a Type."
  input DAE.Type inType;
  output Integer sz;
algorithm
  sz := match (inType)
    local
      list<Integer> res;
      DAE.Dimensions dims;
      Integer i;
      Type tp;
      DAE.TypeSource ts;

    case (DAE.T_ARRAY(dims = dims,ty = tp, source = ts))
      then product(Expression.dimensionSize(d) for d in dims) * getDimensionProduct(tp);

    case (DAE.T_SUBTYPE_BASIC(complexType=tp))
      then getDimensionProduct(tp);

    else
      equation
        false = arrayType(inType);
      then 1;
  end match;
end getDimensionProduct;

public function getDimensions
"Returns the dimensions of a Type."
  input DAE.Type inType;
  output DAE.Dimensions outDimensions;
algorithm
  outDimensions := match inType
    case DAE.T_ARRAY() then listAppend(inType.dims, getDimensions(inType.ty));
    case DAE.T_METAARRAY() then DAE.DIM_UNKNOWN() :: getDimensions(inType.ty);
    case DAE.T_SUBTYPE_BASIC() then getDimensions(inType.complexType);
    case DAE.T_METATYPE() then getDimensions(inType.ty);
    else {};
  end match;
end getDimensions;

public function getDimensionNth
  input DAE.Type inType;
  input Integer inDim;
  output DAE.Dimension outDimension;
algorithm
  outDimension := matchcontinue(inType, inDim)
    local
      DAE.Dimension dim;
      DAE.Type t;
      Integer d, dc;
      DAE.Dimensions dims;

    case (DAE.T_ARRAY(dims = dims), d)
      equation
        dim = listGet(dims, d);
      then
        dim;

    case (DAE.T_ARRAY(ty = t, dims = dims), d)
      equation
        dc = listLength(dims);
        true = (d > dc);
      then
        getDimensionNth(t, d - dc);

    case (DAE.T_SUBTYPE_BASIC(complexType = t), d)
      then getDimensionNth(t, d);

  end matchcontinue;
end getDimensionNth;

public function setDimensionNth
  "Sets the nth dimension of an array type to the given dimension."
  input DAE.Type inType;
  input DAE.Dimension inDim;
  input Integer inDimNth;
  output DAE.Type outType;
algorithm
  outType := match(inType, inDim, inDimNth)
    local
      DAE.Dimension dim;
      DAE.Type ty;
      DAE.TypeSource ts;

    case (DAE.T_ARRAY(dims = {_}, ty = ty, source = ts), _, 1)
      then DAE.T_ARRAY(ty, {inDim}, ts);

    case (DAE.T_ARRAY(dims = {dim}, ty = ty, source = ts), _, _)
      equation
        true = inDimNth > 1;
        ty = setDimensionNth(ty, inDim, inDimNth - 1);
      then
        DAE.T_ARRAY(ty, {dim}, ts);

  end match;
end setDimensionNth;

public function printDimensionsStr "Prints dimensions to a string"
  input DAE.Dimensions dims;
  output String res;
algorithm
  res:=stringDelimitList(List.map(dims,ExpressionDump.dimensionString),", ");
end printDimensionsStr;

public function valuesToVars "Translates a list of Values.Value to a Var list, using a list
  of identifiers as component names.
  Used e.g. when retrieving the type of a record value."
  input list<Values.Value> inValuesValueLst;
  input list<DAE.Ident> inExpIdentLst;
  output list<DAE.Var> outVarLst;
algorithm
  outVarLst := matchcontinue (inValuesValueLst,inExpIdentLst)
    local
      Type tp;
      list<DAE.Var> rest;
      Values.Value v;
      list<Values.Value> vs;
      String id;
      list<String> ids;

    case ({},{}) then {};
    case ((v :: vs),(id :: ids))
      equation
        tp = typeOfValue(v);
        rest = valuesToVars(vs, ids);
      then
        (DAE.TYPES_VAR(id, DAE.dummyAttrVar, tp, DAE.UNBOUND(), NONE()) :: rest);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("-values_to_vars failed\n");
      then
        fail();
  end matchcontinue;
end valuesToVars;

public function typeOfValue "author: PA
  Returns the type of a Values.Value.
  Some information is lost in the translation, like attributes
  of the builtin type."
  input Values.Value inValue;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inValue)
    local
      Type tp;
      Integer dim1,index;
      Values.Value w,v;
      list<Values.Value> vs,vl;
      list<DAE.Type> ts;
      list<DAE.Var> vars;
      String str;
      Absyn.Path cname,path,utPath;
      list<String> ids;
      list<DAE.Exp> explist;
      Values.Value valType;


    case Values.EMPTY(ty = valType) then typeOfValue(valType);

    case (Values.INTEGER()) then (DAE.T_INTEGER_DEFAULT);
    case (Values.REAL()) then (DAE.T_REAL_DEFAULT);
    case (Values.STRING()) then (DAE.T_STRING_DEFAULT);
    case (Values.BOOL()) then (DAE.T_BOOL_DEFAULT);
    case (Values.ENUM_LITERAL(name = path, index = index))
      equation
        path = Absyn.pathPrefix(path);
      then
        DAE.T_ENUMERATION(SOME(index), path, {}, {}, {}, DAE.emptyTypeSource);

    case ((Values.ARRAY(valueLst = (v :: vs))))
      equation
        tp = typeOfValue(v);
        dim1 = listLength((v :: vs));
      then
        DAE.T_ARRAY(tp, {DAE.DIM_INTEGER(dim1)}, DAE.emptyTypeSource);

    case ((Values.ARRAY(valueLst = ({}))))
      equation
      then
        DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT, {DAE.DIM_INTEGER(0)}, DAE.emptyTypeSource);

    case ((Values.TUPLE(valueLst = vs)))
      equation
        ts = List.map(vs, typeOfValue);
      then
        DAE.T_TUPLE(ts,NONE(),DAE.emptyTypeSource);

    case Values.RECORD(record_ = cname,orderd = vl,comp = ids, index = -1)
      equation
        vars = valuesToVars(vl, ids);
      then
        DAE.T_COMPLEX(ClassInf.RECORD(cname),vars,NONE(),{cname});

      // MetaModelica Uniontype
    case Values.RECORD(record_ = cname,orderd = vl,comp = ids, index = index)
      equation
        true = index >= 0;
        vars = valuesToVars(vl, ids);
        utPath = Absyn.stripLast(cname);
      then
        DAE.T_METARECORD(utPath, {} /* typeVar? */, index, vars, false /*We simply do not know...*/,{cname});

        // MetaModelica list type
    case Values.LIST(vl)
      equation
        explist = List.map(vl, ValuesUtil.valueExp);
        ts = List.map(vl, typeOfValue);
        (_,tp) = listMatchSuperType(explist, ts, true);
        tp = boxIfUnboxedType(tp);
      then
        DAE.T_METALIST(tp,DAE.emptyTypeSource);

    case Values.OPTION(NONE())
      equation
        tp = DAE.T_METAOPTION(DAE.T_UNKNOWN_DEFAULT,DAE.emptyTypeSource);
      then tp;

    case Values.OPTION(SOME(v))
      equation
        tp = boxIfUnboxedType(typeOfValue(v));
        tp = DAE.T_METAOPTION(tp,DAE.emptyTypeSource);
      then tp;

    case Values.META_TUPLE(valueLst = vs)
      equation
        ts = List.mapMap(vs, typeOfValue, boxIfUnboxedType);
      then
        DAE.T_METATUPLE(ts,DAE.emptyTypeSource);

    case Values.META_BOX(v)
      equation
        tp = typeOfValue(v);
      then boxIfUnboxedType(tp);

    case Values.NORETCALL() then DAE.T_NORETCALL_DEFAULT;

    case Values.CODE(A=Absyn.C_TYPENAME())
      then DAE.T_CODE(DAE.C_TYPENAME(), {});

    case Values.CODE(A=Absyn.C_VARIABLENAME())
      then DAE.T_CODE(DAE.C_VARIABLENAME(), {});

    case Values.CODE(A=Absyn.C_EXPRESSION())
      then DAE.T_CODE(DAE.C_EXPRESSION(), {});

    case Values.CODE(A=Absyn.C_MODIFICATION())
      then DAE.T_CODE(DAE.C_MODIFICATION(), {});

    case (v)
      equation
        str = "- Types.typeOfValue failed: " + ValuesUtil.valString(v);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end matchcontinue;
end typeOfValue;

public function basicType "Test whether a type is one of the builtin types."
  input DAE.Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inType)
    case (DAE.T_INTEGER()) then true;
    case (DAE.T_REAL()) then true;
    case (DAE.T_STRING()) then true;
    case (DAE.T_BOOL()) then true;
    // BTH
    case (DAE.T_CLOCK()) then true;
    case (DAE.T_ENUMERATION()) then true;
    else false;
  end match;
end basicType;

public function extendsBasicType "Test whether a type extends one of the builtin types."
  input DAE.Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inType)
    case DAE.T_SUBTYPE_BASIC() then true;
    else false;
  end match;
end extendsBasicType;

public function derivedBasicType
  "Returns the actual type of a type extending one of the builtin types."
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match(inType)
    case DAE.T_SUBTYPE_BASIC() then derivedBasicType(inType.complexType);
    else inType;
  end match;
end derivedBasicType;

public function arrayType "Test whether a type is an array type."
  input DAE.Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inType)
    case DAE.T_ARRAY() then true;
    else false;
  end match;
end arrayType;

public function setVarInput "Sets a DAE.Var to input"
  input DAE.Var var;
  output DAE.Var outV;
algorithm
  outV := match(var)
    local
      String name;
      SCode.ConnectorType ct;
      SCode.Visibility vis;
      DAE.Type tp;
      DAE.Binding bind;
      SCode.Parallelism prl;
      SCode.Variability v;
      Absyn.InnerOuter io;
      Option<DAE.Const> cnstForRange;

    case DAE.TYPES_VAR(name,DAE.ATTR(ct,prl,v,_,io,vis),tp,bind,cnstForRange)
    then DAE.TYPES_VAR(name,DAE.ATTR(ct,prl,v,Absyn.INPUT(),io,vis),tp,bind,cnstForRange);

  end match;
end setVarInput;

public function setVarDefaultInput "Sets a DAE.Var to input"
  input DAE.Var var;
  output DAE.Var outV;
algorithm
  outV := match(var)
    local
      String name;
      SCode.ConnectorType ct;
      SCode.Visibility vis;
      DAE.Type tp;
      DAE.Binding bind;
      SCode.Parallelism prl;
      SCode.Variability v;
      Absyn.InnerOuter io;
      Option<DAE.Const> cnstForRange;

    case DAE.TYPES_VAR(name,DAE.ATTR(_,prl,_,_,_,_),tp,bind,cnstForRange)
    then DAE.TYPES_VAR(name,DAE.ATTR(SCode.POTENTIAL(),prl,SCode.VAR(),Absyn.INPUT(),Absyn.NOT_INNER_OUTER(),SCode.PUBLIC()),tp,bind,cnstForRange);

  end match;
end setVarDefaultInput;

public function setVarProtected "Sets a DAE.Var to input"
  input DAE.Var var;
  output DAE.Var outV;
algorithm
  outV := match(var)
    local
      String name;
      SCode.ConnectorType ct;
      Absyn.Direction dir;
      DAE.Type tp;
      DAE.Binding bind;
      SCode.Parallelism prl;
      SCode.Variability v;
      Absyn.InnerOuter io;
      Option<DAE.Const> cnstForRange;

    case DAE.TYPES_VAR(name,DAE.ATTR(ct,prl,v,dir,io,_),tp,bind,cnstForRange)
    then DAE.TYPES_VAR(name,DAE.ATTR(ct,prl,v,dir,io,SCode.PROTECTED()),tp,bind,cnstForRange);

  end match;
end setVarProtected;

protected function setVarType "Sets a DAE.Var's type"
  input DAE.Var var;
  input DAE.Type ty;
  output DAE.Var outV = var;
algorithm
  outV := match outV
    case DAE.TYPES_VAR()
      algorithm
        outV.ty := ty;
      then outV;
  end match;
end setVarType;

public function semiEquivTypes
  "This function checks whether two types are semi-equal...
   With 'semi' we mean that they have the same base type, and if both are arrays
   the numbers of dimensions are equal, not necessarily equal dimension-sizes."
  input DAE.Type inType1;
  input DAE.Type inType2;
  output Boolean outEquiv;
protected
  DAE.Type ty1, ty2;
  list<DAE.Dimension> dims1, dims2;
algorithm
  if arrayType(inType1) and arrayType(inType2) then
    (ty1, dims1) := flattenArrayType(inType1);
    (ty2, dims2) := flattenArrayType(inType2);
    outEquiv := equivtypes(inType1, inType2) and listLength(dims1) == listLength(dims2);
  elseif not arrayType(inType1) and not arrayType(inType2) then
    outEquiv := equivtypes(inType1, inType2);
  else
    outEquiv := false;
  end if;
end semiEquivTypes;

public function equivtypes "This is the type equivalence function.  It is defined in terms of
  the subtype function.  Two types are considered equivalent if they
  are subtypes of each other."
  input DAE.Type t1;
  input DAE.Type t2;
  output Boolean outBoolean;
algorithm
  outBoolean := subtype(t1, t2) and subtype(t2, t1);
end equivtypes;

public function equivtypesOrRecordSubtypeOf
  "Like equivtypes but accepts non-typeconverted records as well (for connections)."
  input DAE.Type t1;
  input DAE.Type t2;
  output Boolean outBoolean;
algorithm
  outBoolean := subtype(t1, t2, false /* Allow record names to differ */) and subtype(t2, t1, false);
end equivtypesOrRecordSubtypeOf;

public function subtype "Is the first type a subtype of the second type?
  This function specifies the rules for subtyping in Modelica."
  input DAE.Type inType1;
  input DAE.Type inType2;
  input Boolean requireRecordNamesEqual = true;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inType1, inType2)
    local
      Boolean res, b1, b2;
      String l1,l2;
      list<DAE.Var> els1,els2;
      Absyn.Path p1,p2;
      DAE.Type t1,t2,tp2,tp1;
      ClassInf.State st1,st2;
      list<DAE.Type> type_list1,type_list2,tList1,tList2;
      list<String> names1, names2;
      DAE.Dimension dim1,dim2;
      DAE.Dimensions dlst1, dlst2;
      list<DAE.FuncArg> farg1,farg2;
      DAE.CodeType c1,c2;
      DAE.Exp e1,e2;
      DAE.TypeSource ts;

    case (DAE.T_ANYTYPE(), _) then true;
    case (_, DAE.T_ANYTYPE()) then true;
    case (DAE.T_INTEGER(), DAE.T_INTEGER()) then true;
    case (DAE.T_REAL(), DAE.T_REAL()) then true;
    case (DAE.T_STRING(), DAE.T_STRING()) then true;
    case (DAE.T_BOOL(), DAE.T_BOOL()) then true;
    // BTH
    case (DAE.T_CLOCK(), DAE.T_CLOCK()) then true;

    case (DAE.T_ENUMERATION(names = {}), DAE.T_ENUMERATION()) then true;
    case (DAE.T_ENUMERATION(), DAE.T_ENUMERATION(names = {})) then true;

    case (DAE.T_ENUMERATION(names = names1),
          DAE.T_ENUMERATION(names = names2))
      equation
        res = List.isEqualOnTrue(names1, names2, stringEq);
      then
        res;

    case (DAE.T_ARRAY(dims = dlst1 as _::_::_, ty = t1),
          DAE.T_ARRAY(dims = dlst2 as _::_::_, ty = t2))
      equation
        true = Expression.dimsEqual(dlst1, dlst2);
        true = subtype(t1, t2, requireRecordNamesEqual);
      then
        true;

    // try dims as list vs. dims as tree
    // T_ARRAY(a::b::c) vs. T_ARRAY(a, T_ARRAY(b, T_ARRAY(c)))
    case (DAE.T_ARRAY(dims = {dim1}, ty = t1),
          DAE.T_ARRAY(dims = dim2::(dlst2 as _::_), ty = t2, source = ts))
      equation
        true = Expression.dimensionsEqual(dim1, dim2);
        true = subtype(t1, DAE.T_ARRAY(t2, dlst2, ts), requireRecordNamesEqual);
      then
        true;

    // try subtype of dimension list vs. dimension tree
    case (DAE.T_ARRAY(dims = dim1::(dlst1 as _::_), ty = t1, source = ts),
          DAE.T_ARRAY(dims = {dim2}, ty = t2))
      equation
        true = Expression.dimensionsEqual(dim1, dim2);
        true = subtype(DAE.T_ARRAY(t1, dlst1, ts), t2, requireRecordNamesEqual);
      then
        true;

    case (DAE.T_ARRAY(ty = t1),DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()}, ty = t2))
      equation
        true = subtype(t1, t2, requireRecordNamesEqual);
      then
        true;

    case (DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()}, ty = t1),DAE.T_ARRAY(ty = t2))
      equation
        true = subtype(t1, t2, requireRecordNamesEqual);
      then
        true;

    case (DAE.T_ARRAY(dims = {DAE.DIM_EXP()}, ty = t1),
          DAE.T_ARRAY(dims = {DAE.DIM_EXP()}, ty = t2))
      equation
        /* HUGE TODO: FIXME: After MSL is updated? */
        // true = Expression.expEqual(e1,e2);
        true = subtype(t1, t2, requireRecordNamesEqual);
      then
        true;

    case (DAE.T_ARRAY(ty = t1),
          DAE.T_ARRAY(dims = {DAE.DIM_EXP()}, ty = t2))
      equation
        true = subtype(t1, t2, requireRecordNamesEqual);
      then
        true;

    case (DAE.T_ARRAY(dims = {DAE.DIM_EXP()}, ty = t1),
          DAE.T_ARRAY(ty = t2))
      equation
        true = subtype(t1, t2, requireRecordNamesEqual);
      then
        true;

    // Array
    case (DAE.T_ARRAY(dims = {dim1}, ty = t1),DAE.T_ARRAY(dims = {dim2}, ty = t2))
      equation
        /*
        true = boolOr(Expression.dimensionsKnownAndEqual(dim1, dim2),
                      Expression.dimensionsEqualAllowZero(dim1, dim2));
        */
        true = Expression.dimensionsKnownAndEqual(dim1, dim2);
        true = subtype(t1, t2, requireRecordNamesEqual);
      then
        true;

    // External objects use a nominal type system
    case (DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(p1)),
          DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(p2)))
      then
        Absyn.pathEqual(p1,p2);

    // Complex type
    case (DAE.T_COMPLEX(complexClassType = st1,varLst = els1),
          DAE.T_COMPLEX(complexClassType = st2,varLst = els2))
      equation
        true = classTypeEqualIfRecord(st1, st2) or not requireRecordNamesEqual "We need to add a cast from one record to another";
        true = listLength(els1) == listLength(els2);
        true = subtypeVarlist(els1, els2);
      then
        true;

    // A complex type that extends a basic type is checked against the baseclass basic type
    case (DAE.T_SUBTYPE_BASIC(complexType = tp1),tp2)
      equation
        res = subtype(tp1, tp2, requireRecordNamesEqual);
      then
        res;

    // A complex type that extends a basic type is checked against the baseclass basic type
    case (tp1,DAE.T_SUBTYPE_BASIC(complexType = tp2))
      equation
        res = subtype(tp1, tp2, requireRecordNamesEqual);
      then
        res;

    // Check of tuples, similar to complex. Just that identifier name do not have to be checked. Only types are checked.
    case (DAE.T_TUPLE(types = type_list1),
          DAE.T_TUPLE(types = type_list2))
      equation
        true = subtypeTypelist(type_list1, type_list2, requireRecordNamesEqual);
      then
        true;

    // Part of MetaModelica extension. KS
    case (DAE.T_METALIST(ty = t1),DAE.T_METALIST(ty = t2)) then subtype(t1,t2);
    case (DAE.T_METAARRAY(ty = t1),DAE.T_METAARRAY(ty = t2)) then subtype(t1,t2);
    case (DAE.T_METATUPLE(types = tList1),DAE.T_METATUPLE(types = tList2))
      equation
        res = subtypeTypelist(tList1,tList2,requireRecordNamesEqual);
      then res;
    case (DAE.T_METAOPTION(ty = t1),DAE.T_METAOPTION(ty = t2))
      then subtype(t1,t2,requireRecordNamesEqual);

    case (DAE.T_METABOXED(ty = t1),DAE.T_METABOXED(ty = t2))
      then subtype(t1,t2,requireRecordNamesEqual);
    case (DAE.T_METABOXED(ty = t1),t2) equation true = isBoxedType(t2); then subtype(t1,t2,requireRecordNamesEqual);
    case (t1,DAE.T_METABOXED(ty = t2)) equation true = isBoxedType(t1); then subtype(t1,t2,requireRecordNamesEqual);

    case (DAE.T_METAPOLYMORPHIC(name = l1),DAE.T_METAPOLYMORPHIC(name = l2)) then l1 == l2;
    case (DAE.T_UNKNOWN(_),_) then true;
    case (_,DAE.T_UNKNOWN(_)) then true;
    case (DAE.T_NORETCALL(_),DAE.T_NORETCALL(_)) then true;

    // MM Function Reference
    case (DAE.T_FUNCTION(funcArg = farg1,funcResultType = t1),DAE.T_FUNCTION(funcArg = farg2,funcResultType = t2))
      equation
        tList1 = list(traverseType(funcArgType(t), 1, unboxedTypeTraverseHelper) for t in farg1);
        tList2 = list(traverseType(funcArgType(t), 1, unboxedTypeTraverseHelper) for t in farg2);
        t1 = traverseType(t1, 1, unboxedTypeTraverseHelper);
        t2 = traverseType(t2, 1, unboxedTypeTraverseHelper);
        true = subtypeTypelist(tList1,tList2,requireRecordNamesEqual);
        true = subtype(t1,t2,requireRecordNamesEqual);
      then true;

    case (DAE.T_FUNCTION_REFERENCE_VAR(functionType = t1),DAE.T_FUNCTION_REFERENCE_VAR(functionType = t2))
      then subtype(t1,t2);

    case(DAE.T_METARECORD(source={p1}),DAE.T_METARECORD(source={p2}))
      then Absyn.pathEqual(p1,p2);

    case (DAE.T_METAUNIONTYPE(source = {p1}),DAE.T_METARECORD(utPath=p2))
      then if Absyn.pathEqual(p1,p2) then subtypeTypelist(inType1.typeVars,inType2.typeVars,requireRecordNamesEqual) else false;

    // If the record is the only one in the uniontype, of course their types match
    case (DAE.T_METARECORD(knownSingleton=b1,utPath = p1),DAE.T_METAUNIONTYPE(knownSingleton=b2,source={p2}))
      then if Absyn.pathEqual(p1,p2) and (b1 or b2) /*Values.mo loses knownSingleton information */ then subtypeTypelist(inType1.typeVars,inType2.typeVars,requireRecordNamesEqual) else false;

    // <uniontype> = <uniontype>
    case (DAE.T_METAUNIONTYPE(source = {p1}), DAE.T_METAUNIONTYPE(source = {p2}))
      then if Absyn.pathEqual(p1,p2) then subtypeTypelist(inType1.typeVars,inType2.typeVars,requireRecordNamesEqual) else false;
    case (DAE.T_METAUNIONTYPE(source = {p1}), DAE.T_COMPLEX(complexClassType=ClassInf.META_UNIONTYPE(_), source = {p2}))
      then Absyn.pathEqual(p1,p2); // TODO: Remove?
    case(DAE.T_COMPLEX(complexClassType=ClassInf.META_UNIONTYPE(_), source = {p2}), DAE.T_METAUNIONTYPE(source = {p1}))
      then Absyn.pathEqual(p1,p2); // TODO: Remove?

    case (DAE.T_CODE(ty = c1),DAE.T_CODE(ty = c2)) then valueEq(c1,c2);

    case (DAE.T_METATYPE(ty = t1),DAE.T_METATYPE(ty = t2)) then subtype(t1,t2,requireRecordNamesEqual);
    case (t1,DAE.T_METATYPE(ty = t2)) then subtype(t1,t2,requireRecordNamesEqual);
    case (DAE.T_METATYPE(ty = t1),t2) then subtype(t1,t2,requireRecordNamesEqual);

    else
      equation
        /* Uncomment for debugging
        l1 = unparseType(t1);
        l2 = unparseType(t2);
        l1 = stringAppendList({"- Types.subtype failed:\n  t1=",l1,"\n  t2=",l2});
        print(l1);
        */
      then false;
  end matchcontinue;
end subtype;

protected function subtypeTypelist "PR. function: subtypeTypelist
  This function checks if the both Type lists matches types, element by element."
  input list<DAE.Type> inTypeLst1;
  input list<DAE.Type> inTypeLst2;
  input Boolean requireRecordNamesEqual;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inTypeLst1,inTypeLst2,requireRecordNamesEqual)
    local
      Type t1,t2;
      list<DAE.Type> rest1,rest2;

    case ({},{},_) then true;
    case ((t1 :: rest1),(t2 :: rest2),_)
      equation
        true = subtype(t1, t2, requireRecordNamesEqual);
      then subtypeTypelist(rest1, rest2, requireRecordNamesEqual);
    else false;  /* default */
  end matchcontinue;
end subtypeTypelist;

protected function subtypeVarlist "This function checks if the Var list in the first list is a
  subset of the list in the second argument.  More precisely, it
  checks if, for each Var in the second list there is a Var in
  the first list with a type that is a subtype of the Var in the
  second list."
  input list<DAE.Var> inVarLst1;
  input list<DAE.Var> inVarLst2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inVarLst1,inVarLst2)
    local
      DAE.Type t1,t2;
      list<DAE.Var> l,vs;
      String n;

    case (_,{}) then true;

    case (l,(DAE.TYPES_VAR(name = n,ty = t2) :: vs))
      equation
        DAE.TYPES_VAR(ty = t1) = varlistLookup(l, n);
        true = subtype(t1, t2, false);
      then subtypeVarlist(l, vs);

    else false;  /* default */
  end matchcontinue;
end subtypeVarlist;

public function varlistLookup "Given a list of Var and a name, this function finds any Var with the given name."
  input list<DAE.Var> inVarLst;
  input String inIdent;
  output DAE.Var outVar;
protected
  String name;
algorithm
  for var in inVarLst loop
    DAE.TYPES_VAR(name = name) := var;

    if name == inIdent then
      outVar := var;
      return;
    end if;
  end for;

  fail();
end varlistLookup;

public function lookupComponent "This function finds a subcomponent by name."
  input DAE.Type inType;
  input String inIdent;
  output DAE.Var outVar;
algorithm
  outVar := matchcontinue (inType,inIdent)
    local
      DAE.Var v;
      DAE.Type t,ty,ty_1;
      String n,id;
      ClassInf.State st;
      list<DAE.Var> cs;
      Option<DAE.Type> bc;
      DAE.Attributes attr;
      DAE.Binding bnd;
      DAE.Dimension dim;
      Option<DAE.Const> cnstForRange;

    case (t,n)
      equation
        true = basicType(t);
        v = lookupInBuiltin(t, n);
      then
        v;

    case (DAE.T_COMPLEX(varLst = cs),id)
      equation
        v = lookupComponent2(cs, id);
      then
        v;

    case (DAE.T_SUBTYPE_BASIC(varLst = cs),id)
      equation
        v = lookupComponent2(cs, id);
      then
        v;

    case (DAE.T_ARRAY(dims = {dim},ty = DAE.T_COMPLEX(varLst = cs)),id)
      equation
        DAE.TYPES_VAR(n,attr,ty,bnd,cnstForRange) = lookupComponent2(cs, id);
        ty_1 = DAE.T_ARRAY(ty,{dim},DAE.emptyTypeSource);
      then
        DAE.TYPES_VAR(n,attr,ty_1,bnd,cnstForRange);

    case (DAE.T_ARRAY(dims = {dim},ty = DAE.T_SUBTYPE_BASIC(varLst = cs)),id)
      equation
        DAE.TYPES_VAR(n,attr,ty,bnd,cnstForRange) = lookupComponent2(cs, id);
        ty_1 = DAE.T_ARRAY(ty,{dim},DAE.emptyTypeSource);
      then
        DAE.TYPES_VAR(n,attr,ty_1,bnd,cnstForRange);

    else
      equation
        // Print.printBuf("- Looking up " + id + " in noncomplex type\n");
      then fail();
  end matchcontinue;
end lookupComponent;

protected function lookupInBuiltin "Since builtin types are not represented as DAE.T_COMPLEX, special care
  is needed to be able to lookup the attributes (*start* etc) in
  them.

  This is not a complete solution.  The current way of mapping the
  both the Modelica type Real and the simple type RealType to
  DAE.T_REAL is a bit problematic, since it does not make a
  difference between Real and RealType, which makes the
  translator accept things like x.start.start.start."
  input DAE.Type inType;
  input String inIdent;
  output DAE.Var outVar;
algorithm
  outVar := match (inType,inIdent)
    local
      DAE.Var v;
      list<DAE.Var> cs;
      String id;

    case (DAE.T_REAL(varLst = cs),id) /* Real */
      equation
        v = lookupComponent2(cs, id);
      then
        v;

    case (DAE.T_INTEGER(varLst = cs),id)
      equation
        v = lookupComponent2(cs, id);
      then
        v;

    case (DAE.T_STRING(varLst = cs),id)
      equation
        v = lookupComponent2(cs, id);
      then
        v;

    case (DAE.T_BOOL(varLst = cs),id)
      equation
        v = lookupComponent2(cs, id);
      then
        v;

   case (DAE.T_ENUMERATION(index = SOME(_)),"quantity")
     then DAE.TYPES_VAR("quantity", DAE.dummyAttrParam,DAE.T_STRING_DEFAULT,DAE.VALBOUND(Values.STRING(""),DAE.BINDING_FROM_DEFAULT_VALUE()),NONE());

    // Should be bound to the first element of DAE.T_ENUMERATION list higher up in the call chain
    case (DAE.T_ENUMERATION(index = SOME(_)),"min")
      then DAE.TYPES_VAR("min", DAE.dummyAttrParam,DAE.T_ENUMERATION(SOME(1),Absyn.IDENT(""),{"min,max"},{},{},DAE.emptyTypeSource),DAE.UNBOUND(),NONE());

    // Should be bound to the last element of DAE.T_ENUMERATION list higher up in the call chain
    case (DAE.T_ENUMERATION(index = SOME(_)),"max")
      then DAE.TYPES_VAR("max", DAE.dummyAttrParam,DAE.T_ENUMERATION(SOME(2),Absyn.IDENT(""),{"min,max"},{},{},DAE.emptyTypeSource),DAE.UNBOUND(),NONE());

    // Should be bound to the last element of DAE.T_ENUMERATION list higher up in the call chain
    case (DAE.T_ENUMERATION(index = SOME(_)),"start")
      then DAE.TYPES_VAR("start", DAE.dummyAttrParam,DAE.T_BOOL_DEFAULT,DAE.UNBOUND(),NONE());

    // Needs to be set to true/false higher up the call chain depending on variability of instance
    case (DAE.T_ENUMERATION(index = SOME(_)),"fixed")
      then DAE.TYPES_VAR("fixed", DAE.dummyAttrParam,DAE.T_BOOL_DEFAULT,DAE.UNBOUND(),NONE());
    case (DAE.T_ENUMERATION(index = SOME(_)),"enable") then DAE.TYPES_VAR("enable", DAE.dummyAttrParam,DAE.T_BOOL_DEFAULT,DAE.VALBOUND(Values.BOOL(true),DAE.BINDING_FROM_DEFAULT_VALUE()),NONE());
  end match;
end lookupInBuiltin;

protected function lookupComponent2 "This function finds a named Var in a list of Vars, comparing
  the name against the second argument to this function."
  input list<DAE.Var> inVarLst;
  input String inIdent;
  output DAE.Var outVar;
algorithm
  outVar := matchcontinue (inVarLst,inIdent)
    local
      DAE.Var v;
      String n,m;
      list<DAE.Var> vs;

    case (((v as DAE.TYPES_VAR(name = n)) :: _),m)
      equation
        true = stringEq(n, m);
      then
        v;

    case ((_ :: vs),n)
      equation
        v = lookupComponent2(vs, n);
      then
        v;
  end matchcontinue;
end lookupComponent2;

public function makeArray "This function makes an array type given a Type and an Absyn.ArrayDim"
  input DAE.Type inType;
  input Absyn.ArrayDim inArrayDim;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inType,inArrayDim)
    local
      Type t;
      Integer len;
      list<Absyn.Subscript> l;
    case (t,{}) then t;
    case (t,l)
      equation
        len = listLength(l);
      then
        DAE.T_ARRAY(t,{DAE.DIM_INTEGER(len)},DAE.emptyTypeSource);
  end matchcontinue;
end makeArray;

public function makeArraySubscripts " This function makes an array type given a Type and a list of DAE.Subscript"
  input DAE.Type inType;
  input list<DAE.Subscript> lst;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inType,lst)
    local
      Type t;
      Integer i;
      DAE.Exp e;
      list<DAE.Subscript> rest;
    case (t,{}) then t;
    case (t,DAE.WHOLEDIM()::rest)
      equation
        t = makeArraySubscripts(DAE.T_ARRAY(t,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),rest);
      then
        t;
    case (t,DAE.SLICE(_)::rest)
      equation
        t = makeArraySubscripts(DAE.T_ARRAY(t,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),rest);
      then
        t;
    case (t,DAE.WHOLE_NONEXP(_)::rest)
      equation
        t = makeArraySubscripts(DAE.T_ARRAY(t,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),rest);
      then
        t;

    case (t,DAE.INDEX(DAE.ICONST(i))::rest)
      equation
        t = makeArraySubscripts(DAE.T_ARRAY(t,{DAE.DIM_INTEGER(i)},DAE.emptyTypeSource),rest);
      then
        t;
     case (t,DAE.INDEX(_)::rest)
      equation
        t = makeArraySubscripts(DAE.T_ARRAY(t,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),rest);
      then
        t;
  end matchcontinue;
end makeArraySubscripts;

public function liftArray "This function turns a type into an array of that type.
  If the type already is an array, another dimension is simply added."
  input DAE.Type inType;
  input DAE.Dimension inDimension;
  output DAE.Type outType;
algorithm
  outType := DAE.T_ARRAY(inType, {inDimension}, DAE.emptyTypeSource);
end liftArray;

public function liftList "This function turns a type into a list of that type.
  If the type already is a list, another dimension is simply added."
  input DAE.Type inType;
  input DAE.Dimension inDimension;
  output DAE.Type outType;
algorithm
  outType := DAE.T_METALIST(inType, DAE.emptyTypeSource);
end liftList;

public function liftArrayListDims "
  This function turns a type into an array of that type."
  input DAE.Type inType;
  input DAE.Dimensions inDimensions;
  output DAE.Type outType = inType;
algorithm
  for dim in listReverse(inDimensions) loop
    outType := DAE.T_ARRAY(outType, {dim}, DAE.emptyTypeSource);
  end for;
end liftArrayListDims;

public function liftArrayListDimsReverse
  "Turns a type into an array of that type, with the dimensions in the reverse order."
  input DAE.Type inType;
  input DAE.Dimensions dims;
  output DAE.Type ty = inType;
algorithm
  for dim in dims loop
    ty := DAE.T_ARRAY(ty, {dim}, DAE.emptyTypeSource);
  end for;
end liftArrayListDimsReverse;

public function liftTypeWithDims "
  mahge: This function turns a type into an array of that type
  by appening the new dimension at the end. "
  input DAE.Type inType;
  input DAE.Dimensions inDims;
  output DAE.Type outType;
algorithm
  outType := match inType
    local
      list<DAE.Dimension> dims, dims_;
      DAE.Type ty;
      DAE.TypeSource src;

    case DAE.T_ARRAY(DAE.T_ARRAY(_,_,_), _, _)
      algorithm
        print("Can not handle this yet!!");
      then fail();

    case DAE.T_ARRAY(ty, dims, src)
      algorithm
        dims_ := listAppend(dims, inDims);
      then if referenceEq(dims,dims_) then inType else DAE.T_ARRAY(ty, dims_, src);

    else
      DAE.T_ARRAY(inType, inDims, DAE.emptyTypeSource);

  end match;
end liftTypeWithDims;

public function liftArrayListExp "
  This function turns a type into an array of that type."
  input DAE.Type inType;
  input list<DAE.Exp> inDimensionLst;
  output DAE.Type outType;
algorithm
  outType := match (inType,inDimensionLst)
    local
      Type ty;
      DAE.Exp d;
      list<DAE.Exp> rest;
    case (ty,{}) then ty;
    case (ty,d::rest) then liftArray(liftArrayListExp(ty,rest),DAE.DIM_EXP(d));
  end match;
end liftArrayListExp;

public function liftArrayRight "This function adds an array dimension to *the right* of the passed type."
  input DAE.Type inType;
  input DAE.Dimension inIntegerOption;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inType,inIntegerOption)
    local
      Type ty_1,ty;
      DAE.Dimension dim;
      DAE.TypeSource ts;
      DAE.Dimension d;
      ClassInf.State ci;
      list<DAE.Var> varlst;
      EqualityConstraint ec;
      Type tty;

    case (DAE.T_ARRAY(dims = {dim},ty = ty, source = ts),d)
      equation
        ty_1 = liftArrayRight(ty, d);
      then
        DAE.T_ARRAY(ty_1, {dim}, ts);

    case(DAE.T_SUBTYPE_BASIC(ci,varlst,ty,ec,ts),d)
      equation
        false = listEmpty(getDimensions(ty));
        ty_1 = liftArrayRight(ty,d);
      then
        DAE.T_SUBTYPE_BASIC(ci,varlst,ty_1,ec,ts);

    case (tty,d)
      equation
        ts = getTypeSource(tty);
      then
        DAE.T_ARRAY(tty,{d},ts);
  end matchcontinue;
end liftArrayRight;

public function unliftArray "This function turns an array of a type into that type."
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match (inType)
    local Type ty;
    case (DAE.T_ARRAY(ty = ty)) then ty;
    case (DAE.T_SUBTYPE_BASIC(complexType = ty)) then unliftArray(ty);
    // adrpo: handle also functions returning arrays!
    case (DAE.T_FUNCTION(funcResultType= ty)) then unliftArray(ty);
  end match;
end unliftArray;

public function unliftArrayOrList
  input DAE.Type inType;
  output DAE.Type outType;
  output DAE.Dimension dim;
algorithm
  (outType,dim) := match (inType)
    local
      Type ty;
    case (DAE.T_METALIST(ty = ty)) then (boxIfUnboxedType(ty),DAE.DIM_UNKNOWN());
    case (DAE.T_METAARRAY(ty = ty)) then (boxIfUnboxedType(ty),DAE.DIM_UNKNOWN());
    case (DAE.T_ARRAY(dims = {dim},ty = ty)) then (ty,dim);
    case (DAE.T_SUBTYPE_BASIC(complexType = ty))
      equation
        (ty,dim) = unliftArrayOrList(ty);
      then (ty,dim);
  end match;
end unliftArrayOrList;

public function arrayElementType "This function turns an array into the element type of the array."
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match(inType)
    case DAE.T_ARRAY() then arrayElementType(inType.ty);

    case DAE.T_SUBTYPE_BASIC()
      then if listEmpty(getDimensions(inType.complexType)) then
          inType else arrayElementType(inType.complexType);

    else inType;
  end match;
end arrayElementType;

public function setArrayElementType
  input DAE.Type inType;
  input DAE.Type inBaseType;
  output DAE.Type outType;
algorithm
  outType := match(inType, inBaseType)
    local
      DAE.Type ty;
      DAE.Dimensions dims;
      DAE.TypeSource src;

    case (DAE.T_ARRAY(ty, dims, src), _)
      equation
        ty = setArrayElementType(ty, inBaseType);
      then
        DAE.T_ARRAY(ty, dims, src);

    else inBaseType;

  end match;
end setArrayElementType;

public function unparseEqMod
"prints eqmod to a string"
  input DAE.EqMod eq;
  output String str;
algorithm
  str := match(eq)
    local DAE.Exp e; Absyn.Exp e2;

    case(DAE.TYPED(modifierAsExp = e))
      equation
        str = ExpressionDump.printExpStr(e);
      then
        str;

    case(DAE.UNTYPED(exp=e2))
      equation
        str = Dump.printExpStr(e2);
      then str;
  end match;
end unparseEqMod;

public function unparseOptionEqMod
"prints eqmod to a string"
  input Option<DAE.EqMod> eq;
  output String str;
algorithm
  str := match(eq)
    local
      DAE.EqMod e;
    case NONE() then "NONE()";
    case SOME(e) then unparseEqMod(e);
  end match;
end unparseOptionEqMod;

public function unparseType
"This function prints a Modelica type as a piece of Modelica code."
  input DAE.Type inType;
  output String outString;
algorithm
  outString := match (inType)
    local
      String s1,s2,str,dims,res,vstr,name,st_str,bc_tp_str,paramstr,restypestr,tystr,funcstr;
      list<String> l,vars,paramstrs,tystrs;
      Type ty,bc_tp,restype;
      DAE.Dimensions dimlst;
      list<DAE.Var> vs;
      ClassInf.State ci_state;
      list<DAE.FuncArg> params;
      Absyn.Path path,p;
      list<DAE.Type> tys;
      DAE.CodeType codeType;
      DAE.TypeSource ts;
      Boolean b;

    case (DAE.T_INTEGER(varLst = {})) then "Integer";
    case (DAE.T_REAL(varLst = {})) then "Real";
    case (DAE.T_STRING(varLst = {})) then "String";
    case (DAE.T_BOOL(varLst = {})) then "Boolean";
    // BTH
    case (DAE.T_CLOCK()) then "Clock";

    case (DAE.T_INTEGER(varLst = vs))
      equation
        s1 = stringDelimitList(List.map(vs, unparseVarAttr),", ");
        s2 = "Integer(" + s1 + ")";
      then s2;
    case (DAE.T_REAL(varLst = vs))
      equation
        s1 = stringDelimitList(List.map(vs, unparseVarAttr),", ");
        s2 = "Real(" + s1 + ")";
      then s2;
    case (DAE.T_STRING(varLst = vs))
      equation
        s1 = stringDelimitList(List.map(vs, unparseVarAttr),", ");
        s2 = "String(" + s1 + ")";
      then s2;
    case (DAE.T_BOOL(varLst = vs))
      equation
        s1 = stringDelimitList(List.map(vs, unparseVarAttr),", ");
        s2 = "Boolean(" + s1 + ")";
      then s2;
    case (DAE.T_ENUMERATION(path = path, names = l))
      equation
        s1 = if Config.typeinfo() then " /*" + Absyn.pathString(path) + "*/ (" else "(";
        s2 = stringDelimitList(l, ", ");
        /* s2 = stringAppendList(List.map(vs, unparseVar));
        s2 = if_(s2 == "", "", "(" + s2 + ")"); */
        str = stringAppendList({"enumeration",s1,s2,")"});
      then
        str;

    case (ty as DAE.T_ARRAY())
      equation
        (ty,dimlst) = flattenArrayType(ty);
        tystr = unparseType(ty);
        dims = printDimensionsStr(dimlst);
        res = stringAppendList({tystr,"[",dims,"]"});
      then
        res;

    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_),varLst = vs, source = {path}))
      equation
        name = Absyn.pathStringNoQual(path);
        vars = List.map(vs, unparseVar);
        vstr = stringAppendList(vars);
        res = stringAppendList({"record ",name,"\n",vstr,"end ", name, ";"});
      then
        res;

    case (DAE.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(_, b),varLst = vs, source = {path}))
      equation
        name = Absyn.pathStringNoQual(path);
        vars = List.map(vs, unparseVar);
        vstr = stringAppendList(vars);
        str = if b then "expandable " else "";
        res = stringAppendList({str, "connector ",name,"\n",vstr,"end ", name, ";"});
      then
        res;

    case (DAE.T_SUBTYPE_BASIC(complexClassType = ci_state, complexType = bc_tp))
      equation
        st_str = Absyn.pathString(ClassInf.getStateName(ci_state));
        res = ClassInf.printStateStr(ci_state);
        bc_tp_str = unparseType(bc_tp);
        res = stringAppendList({"(",res," ",st_str," bc:",bc_tp_str,")"});
      then
        res;

    case (DAE.T_COMPLEX(complexClassType = ci_state))
      equation
        st_str = Absyn.pathString(ClassInf.getStateName(ci_state));
        res = ClassInf.printStateStr(ci_state);
        res = stringAppendList({res," ",st_str});
      then
        res;

    case (DAE.T_FUNCTION(funcArg = params, funcResultType = restype, source = ts))
      equation
        funcstr = stringDelimitList(list(Absyn.pathString(pt) for pt in ts), ", ");
        paramstrs = List.map(params, unparseParam);
        paramstr = stringDelimitList(paramstrs, ", ");
        restypestr = unparseType(restype);
        res = stringAppendList({funcstr,"<function>(",paramstr,") => ",restypestr});
      then
        res;

    case (DAE.T_TUPLE(types = tys))
      equation
        tystrs = match inType.names
          local
            list<String> names;
          case SOME(names) then list(unparseType(t) + " " + n threaded for t in tys, n in names);
          else list(unparseType(t) for t in tys);
        end match;
        tystr = stringDelimitList(tystrs, ", ");
        res = stringAppendList({"(",tystr,")"});
      then
        res;

    // MetaModelica tuple
    case (DAE.T_METATUPLE(types = tys))
      equation
        tystrs = List.map(tys, unparseType);
        tystr = stringDelimitList(tystrs, ", ");
        res = stringAppendList({"tuple<",tystr,">"});
      then
        res;

     // MetaModelica list
    case (DAE.T_METALIST(ty = ty))
      equation
        tystr = unparseType(ty);
        res = stringAppendList({"list<",tystr,">"});
      then
        res;

    case (DAE.T_METAARRAY(ty = ty))
      equation
        tystr = unparseType(ty);
        res = stringAppendList({"array<",tystr,">"});
      then
        res;

    // MetaModelica list
    case (DAE.T_METAPOLYMORPHIC(name = tystr))
      equation
        res = stringAppendList({"polymorphic<",tystr,">"});
      then
        res;

     // MetaModelica uniontype
    case (DAE.T_METAUNIONTYPE(source = {p}))
      equation
        res = Absyn.pathStringNoQual(p);
      then if listEmpty(inType.typeVars) then res else (res+"<"+stringDelimitList(list(unparseType(tv) for tv in inType.typeVars), ",")+">");

    // MetaModelica uniontype (but we know which record in the UT it is)
/*
    case (DAE.T_METARECORD(utPath=_, fields = vs, source = {p}))
      equation
        str = Absyn.pathStringNoQual(p);
        vars = List.map(vs, unparseVar);
        vstr = stringAppendList(vars);
        res = stringAppendList({"metarecord ",str,"\n",vstr,"end ", str, ";"});
      then res;
*/
    case (DAE.T_METARECORD(source = {p}))
      then Absyn.pathStringNoQual(p);

    // MetaModelica boxed type
    case (DAE.T_METABOXED(ty = ty))
      equation
        res = unparseType(ty);
        res = "#" /* this is a box */ + res;
      then res;

    // MetaModelica Option type
    case (DAE.T_METAOPTION(ty = DAE.T_UNKNOWN())) then "Option<Any>";
    case (DAE.T_METAOPTION(ty = ty))
      equation
        tystr = unparseType(ty);
        res = stringAppendList({"Option<",tystr,">"});
      then
        res;

    case (DAE.T_METATYPE(ty = ty)) then unparseType(ty);

    case (DAE.T_NORETCALL(_))              then "#NORETCALL#";
    case (DAE.T_UNKNOWN(_))                then "#T_UNKNOWN#";
    case (DAE.T_ANYTYPE()) then "#ANYTYPE#";
    case (DAE.T_CODE(ty = codeType)) then printCodeTypeStr(codeType);
    case (DAE.T_FUNCTION_REFERENCE_VAR(functionType=ty)) then "#FUNCTION_REFERENCE_VAR#" + unparseType(ty);
    case (DAE.T_FUNCTION_REFERENCE_FUNC(functionType=ty)) then "#FUNCTION_REFERENCE_FUNC#" + unparseType(ty);
    else "Internal error Types.unparseType: not implemented yet\n";
  end match;
end unparseType;

public function unparseTypeNoAttr
  "Like unparseType, but doesn't print out builtin attributes."
  input DAE.Type inType;
  output String outString;
protected
  DAE.Type ty;
algorithm
  (ty, _) := stripTypeVars(inType);
  outString := unparseType(ty);
end unparseTypeNoAttr;

public function unparsePropTypeNoAttr
  input DAE.Properties inProps;
  output String outString;
algorithm
  outString := match(inProps)
    local
      DAE.Type ty;

    case DAE.PROP(type_ = ty) then unparseTypeNoAttr(ty);
    case DAE.PROP_TUPLE(type_ = ty) then unparseTypeNoAttr(ty);
  end match;
end unparsePropTypeNoAttr;

public function unparseConst
  input DAE.Const inConst;
  output String outString;
algorithm
  outString := match(inConst)
    case DAE.C_CONST() then "constant";
    case DAE.C_PARAM() then "parameter";
    case DAE.C_VAR() then "";
    case DAE.C_UNKNOWN() then "#UNKNOWN#";
  end match;
end unparseConst;

public function printConstStr
  "This function prints a Const as a string."
  input DAE.Const inConst;
  output String outString;
algorithm
  outString := match (inConst)
    case DAE.C_CONST() then "C_CONST";
    case DAE.C_PARAM() then "C_PARAM";
    case DAE.C_VAR() then "C_VAR";
  end match;
end printConstStr;

public function printTupleConstStr
  "This function prints a Modelica TupleConst as a string."
  input DAE.TupleConst inTupleConst;
  output String outString;
algorithm
  outString := match (inTupleConst)
    local
      String cstr,res,res_1;
      DAE.Const c;
      list<String> strlist;
      list<DAE.TupleConst> constlist;
    case DAE.SINGLE_CONST(const = c)
      equation
        cstr = printConstStr(c);
      then
        cstr;
    case DAE.TUPLE_CONST(tupleConstLst = constlist)
      equation
        strlist = List.map(constlist, printTupleConstStr);
        res = stringDelimitList(strlist, ", ");
        res_1 = stringAppendList({"(",res,")"});
      then
        res_1;
  end match;
end printTupleConstStr;

public function printTypeStr "This function prints a textual description of a Modelica type to a string.
  If the type is not one of the primitive types, it simply prints composite."
  input DAE.Type inType;
  output String str;
algorithm
  str := matchcontinue (inType)
    local
      list<DAE.Var> vars;
      list<String> l;
      ClassInf.State st;
      list<DAE.Dimension> dims;
      Type t,ty,restype;
      list<DAE.FuncArg> params;
      list<DAE.Type> tys;
      String s1,s2,compType;
      Absyn.Path path;
      DAE.TypeSource ts;

    case (DAE.T_INTEGER(varLst = vars))
      equation
        s1 = List.toString(vars, printVarStr, "Integer", "(", ", ", ")", false);
        str = s1 + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_REAL(varLst = vars))
      equation
        s1 = List.toString(vars, printVarStr, "Real", "(", ", ", ")", false);
        str = s1 + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_STRING(varLst = vars))
      equation
        s1 = List.toString(vars, printVarStr, "String", "(", ", ", ")", false);
        str = s1 + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_BOOL(varLst = vars))
      equation
        s1 = List.toString(vars, printVarStr, "Boolean", "(", ", ", ")", false);
        str = s1 + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_CLOCK(varLst = vars))
      equation
        s1 = List.toString(vars, printVarStr, "Clock", "(", ", ", ")", false);
        str = s1 + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_ENUMERATION(literalVarLst = vars))
      equation
        s1 = List.toString(vars, printVarStr, "Enumeration", "(", ", ", ")", false);
        str = s1 + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_SUBTYPE_BASIC(complexClassType = st, complexType = t, varLst = vars))
      equation
        compType = printTypeStr(t);
        s1 = ClassInf.printStateStr(st);
        s2 = stringDelimitList(List.map(vars, printVarStr),", ");
        str = stringAppendList({"composite(",s1,"{",s2,"}, derived from ", compType, ")"});
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_COMPLEX(complexClassType = st,varLst = vars))
      equation
        s1 = ClassInf.printStateStr(st);
        s2 = stringDelimitList(List.map(vars, printVarStr),", ");
        str = stringAppendList({"composite(",s1,"{",s2,"})"});
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_ARRAY(dims = dims,ty = t))
      equation
        s1 = stringDelimitList(List.map(dims, ExpressionDump.dimensionString), ", ");
        s2 = printTypeStr(t);
        str = stringAppendList({"array(",s2,")[",s1,"]"});
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_FUNCTION(funcArg = params,funcResultType = restype))
      equation
        s1 = printParamsStr(params);
        s2 = printTypeStr(restype);
        str = stringAppendList({"function(", s1,") => ",s2});
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_TUPLE(types = tys))
      equation
        s1 = stringDelimitList(List.map(tys, printTypeStr),", ");
        str = stringAppendList({"(",s1,")"});
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // MetaModelica tuple
    case (DAE.T_METATUPLE(types = tys, source = ts))
      equation
        str = printTypeStr(DAE.T_TUPLE(tys,NONE(),ts));
        str = str + printTypeSourceStr(ts);
      then
        str;

    // MetaModelica list
    case (DAE.T_METALIST(ty = ty))
      equation
        s1 = printTypeStr(ty);
        str = stringAppendList({"list<",s1,">"});
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // MetaModelica Option
    case (DAE.T_METAOPTION(ty = ty))
      equation
        s1 = printTypeStr(ty);
        str = stringAppendList({"Option<",s1,">"});
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // MetaModelica Array
    case (DAE.T_METAARRAY(ty = ty))
      equation
        s1 = printTypeStr(ty);
        str = stringAppendList({"array<",s1,">"});
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // MetaModelica Boxed
    case (DAE.T_METABOXED(ty = ty))
      equation
        s1 = printTypeStr(ty);
        str = stringAppendList({"boxed<",s1,">"});
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // MetaModelica polymorphic
    case (DAE.T_METAPOLYMORPHIC(name = s1))
      equation
        str = stringAppendList({"polymorphic<",s1,">"});
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // NoType
    case (DAE.T_UNKNOWN(_))
      equation
        str = "T_UNKNOWN";
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // AnyType of none
    case (DAE.T_ANYTYPE(anyClassType = NONE()))
      equation
        str = "ANYTYPE()";
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;
    // AnyType of some
    case (DAE.T_ANYTYPE(anyClassType = SOME(st)))
      equation
        s1 = ClassInf.printStateStr(st);
        str = "ANYTYPE(" + s1 + ")";
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_NORETCALL(_))
      equation
        str = "()";
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // MetaType
    case (DAE.T_METATYPE(ty = t))
      equation
        s1 = printTypeStr(t);
        str = stringAppendList({"METATYPE(", s1, ")"});
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // Uniontype, Metarecord
    case (t)
      equation
        {path} = getTypeSource(t);
        s1 = Absyn.pathStringNoQual(path);
        str = "#" + s1 + "#";
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // Code
    case (DAE.T_CODE(DAE.C_EXPRESSION(),_)) then "$Code(Expression)";
    case (DAE.T_CODE(DAE.C_EXPRESSION_OR_MODIFICATION(),_)) then "$Code(ExpressionOrModification)";
    case (DAE.T_CODE(DAE.C_TYPENAME(),_)) then "$Code(TypeName)";
    case (DAE.T_CODE(DAE.C_VARIABLENAME(),_)) then "$Code(VariableName)";
    case (DAE.T_CODE(DAE.C_VARIABLENAMES(),_)) then "$Code(VariableName[:])";

    // All the other ones we don't handle
    else
      equation
        str = "Types.printTypeStr failed";
        str = str + printTypeSourceStr(getTypeSource(inType));
      then
        str;

  end matchcontinue;
end printTypeStr;

public function printConnectorTypeStr
"Author BZ, 2009-09
 Print the connector-type-name"
  input DAE.Type it;
  output String s "Connector type";
  output String s2 "Components of connector";
algorithm
  (s,s2) := matchcontinue(it)
    local
      ClassInf.State st;
      Absyn.Path connectorName;
      list<DAE.Var> vars;
      DAE.TypeSource ts;
      list<String> varNames;
      Boolean isExpandable;
      String isExpandableStr;
      Type t;

    case(DAE.T_COMPLEX(complexClassType = (ClassInf.CONNECTOR(connectorName,isExpandable)),varLst = vars))
      equation
        varNames = List.map(vars,varName);
        isExpandableStr = if isExpandable then "/* expandable */ " else "";
        s = isExpandableStr + Absyn.pathString(connectorName);
        s2 = "{" + stringDelimitList(varNames,", ") + "}";
      then
        (s,s2);

    // TODO! check if we can get T_SUBTYPE_BASIC here??!!
    case(DAE.T_SUBTYPE_BASIC(complexClassType = (ClassInf.CONNECTOR(connectorName,isExpandable)), varLst = vars, complexType = t))
      equation
        varNames = List.map(vars,varName);
        isExpandableStr = if isExpandable then "/* expandable */ " else "";
        s = isExpandableStr + Absyn.pathString(connectorName);
        s2 = "{" + stringDelimitList(varNames,", ") + "}" + " subtype of: " + printTypeStr(t);
      then
        (s,s2);

    else ("", unparseType(it));
  end matchcontinue;
end printConnectorTypeStr;

public function printParamsStr "Prints function arguments to a string."
  input list<DAE.FuncArg> inFuncArgLst;
  output String str;
algorithm
  str := matchcontinue (inFuncArgLst)
    local
      String n;
      DAE.Type t;
      list<DAE.FuncArg> params;
      String s1,s2;
    case {} then "";
    case {DAE.FUNCARG(name=n,ty=t)}
      equation
        s1 = printTypeStr(t);
        str = stringAppendList({n," :: ",s1});
      then
        str;
    case (DAE.FUNCARG(name=n,ty=t)::params)
      equation
        s1 = printTypeStr(t);
        s2 = printParamsStr(params);
        str = stringAppendList({n," :: ",s1, " * ",s2});
      then
       str;
  end matchcontinue;
end printParamsStr;

public function unparseVarAttr "
  Prints a variable which is attribute of builtin type to a string, e.g. on the form 'max = 10.0'"
  input DAE.Var inVar;
  output String outString;
algorithm
  outString := matchcontinue (inVar)
    local
      String res,n,bindStr,valStr;
      Values.Value value;
      DAE.Exp e;

    case DAE.TYPES_VAR(name = n, binding = DAE.EQBOUND(exp=e))
      equation
        bindStr = ExpressionDump.printExpStr(e);
        res = stringAppendList({n," = ",bindStr});
      then
        res;
    case DAE.TYPES_VAR(name = n, binding = DAE.VALBOUND(valBound=value))
      equation
        valStr = ValuesUtil.valString(value);
        res = stringAppendList({n," = ",valStr});
      then
        res;
    else "";
  end matchcontinue;
end unparseVarAttr;

public function unparseVar
"Prints a variable to a string."
  input DAE.Var inVar;
  output String outString;
algorithm
  outString := match (inVar)
    local
      String t,res,n, s;
      DAE.Type typ;
      SCode.ConnectorType ct;

    case DAE.TYPES_VAR(name = n,ty = typ,attributes = DAE.ATTR(connectorType = ct))
      equation
        s = connectorTypeStr(ct);
        t = unparseType(typ);
        res = stringAppendList({"  ", s, t," ", n, ";\n"});
      then
        res;

  end match;
end unparseVar;

public function connectorTypeStr
  input SCode.ConnectorType ct;
  output String str;
algorithm
  str := matchcontinue(ct)
    local String s;
    case (_)
      equation
        "" = SCodeDump.connectorTypeStr(ct);
      then
        "";
    else SCodeDump.connectorTypeStr(ct) + " ";
  end matchcontinue;
end connectorTypeStr;

protected function unparseParam "Prints a function argument to a string."
  input DAE.FuncArg inFuncArg;
  output String outString;
algorithm
  outString := match (inFuncArg)
    local
      String tstr,res,id,cstr,estr,pstr;
      DAE.Type ty;
      DAE.Const c;
      DAE.VarParallelism p;
      DAE.Exp exp;
    case DAE.FUNCARG(id,ty,c,p,NONE())
      equation
        tstr = unparseType(ty);
        cstr = DAEUtil.constStrFriendly(c);
        pstr = DAEUtil.dumpVarParallelismStr(p);
        res = stringAppendList({tstr," ",cstr,pstr,id});
      then
        res;
    case DAE.FUNCARG(id,ty,c,p,SOME(exp))
      equation
        tstr = unparseType(ty);
        cstr = DAEUtil.constStrFriendly(c);
        estr = ExpressionDump.printExpStr(exp);
        pstr = DAEUtil.dumpVarParallelismStr(p);
        res = stringAppendList({tstr," ",cstr,pstr,id," := ",estr});
      then
        res;
  end match;
end unparseParam;

public function printVarStr "author: LS
  Prints a Var to the a string."
  input DAE.Var inVar;
  output String str;
algorithm
  str := matchcontinue (inVar)
    local
      String vs,n;
      SCode.Variability var;
      DAE.Type typ;
      DAE.Binding bind;
      String s1,s2;

    case DAE.TYPES_VAR(name = n,attributes = DAE.ATTR(variability = var),ty = typ,binding = bind)
      equation
        s1 = printTypeStr(typ);
        vs = SCodeDump.variabilityString(var);
        s2 = printBindingStr(bind);
        str = stringAppendList({s1," ",n," ",vs," ",s2});
      then
        str;
    case DAE.TYPES_VAR(name = n)
      equation
        str = stringAppendList({n});
      then
        str;
  end matchcontinue;
end printVarStr;

public function printBindingStr "Print a variable binding to a string."
  input DAE.Binding inBinding;
  output String outString;
algorithm
  outString:=
  matchcontinue (inBinding)
    local
      String str,str2,res,v_str,s,str3;
      DAE.Exp exp;
      Const f;
      Values.Value v;
      DAE.BindingSource source;

    case DAE.UNBOUND() then "UNBOUND";
    case DAE.EQBOUND(exp = exp,evaluatedExp = NONE(),constant_ = f,source = source)
      equation
        str = ExpressionDump.printExpStr(exp);
        str2 = printConstStr(f);
        str3 = DAEUtil.printBindingSourceStr(source);
        res = stringAppendList({"DAE.EQBOUND(",str,", NONE(), ",str2,", ",str3,")"});
      then
        res;
    case DAE.EQBOUND(exp = exp,evaluatedExp = SOME(v),constant_ = f,source = source)
      equation
        str = ExpressionDump.printExpStr(exp);
        str2 = printConstStr(f);
        v_str = ValuesUtil.valString(v);
        str3 = DAEUtil.printBindingSourceStr(source);
        res = stringAppendList({"DAE.EQBOUND(",str,", SOME(",v_str,"), ",str2,", ",str3,")"});
      then
        res;
    case DAE.VALBOUND(valBound = v, source = source)
      equation
        s = ValuesUtil.unparseValues({v});
        str3 = DAEUtil.printBindingSourceStr(source);
        res = stringAppendList({"DAE.VALBOUND(",s,", ",str3,")"});
      then
        res;
    else "";
  end matchcontinue;
end printBindingStr;

public function makeFunctionType "author: LS
  Creates a function type from a function name an a list of input and
  output variables."
  input Absyn.Path p;
  input list<DAE.Var> vl;
  input DAE.FunctionAttributes functionAttributes;
  output DAE.Type outType;
protected
  list<DAE.Var> invl,outvl;
  list<DAE.FuncArg> fargs;
  Type rettype;
algorithm
  invl := getInputVars(vl);
  outvl := getOutputVars(vl);
  fargs := makeFargsList(invl);
  rettype := makeReturnType(outvl);
  outType := DAE.T_FUNCTION(fargs,rettype,functionAttributes,{p});
end makeFunctionType;

public function extendsFunctionTypeArgs
 "function: extandFunctionType
  Extends function argument list adding var for element list."
  input DAE.Type inType;
  input list<DAE.Element> inElementLst;
  input list<DAE.Element> inOutputElementLst;
  input list<Boolean> inBooltLst;
  output DAE.Type outType;
protected
  DAE.TypeSource tysrc;
  list<DAE.FuncArg> fargs, fargs1, newfargs;
  DAE.Type rettype;
  DAE.FunctionAttributes functionAttributes;
algorithm
  DAE.T_FUNCTION(fargs,rettype,functionAttributes,tysrc) := inType;
  (fargs1, _) := List.splitOnBoolList(fargs, inBooltLst);
  newfargs := List.threadMap(inElementLst, fargs1, makeElementFarg);
  newfargs := listAppend(fargs, newfargs);
  rettype := makeElementReturnType(inOutputElementLst);
  outType := DAE.T_FUNCTION(newfargs,rettype,functionAttributes,tysrc);
end extendsFunctionTypeArgs;

protected function makeElementReturnType "
  Create a return type from a list of Element output variables.
  Depending on the length of the output variable list, different
  kinds of return types are created."
  input list<DAE.Element> inElementLst;
  output DAE.Type outType;
algorithm
  outType := match(inElementLst)
    local
      Type ty;
      DAE.Element element;
      list<DAE.Element> elements;
      list<Type> types;
      list<String> names;
      Option<list<String>> namesOpt;


    case {} then DAE.T_NORETCALL(DAE.emptyTypeSource);

    case {element}
      equation
        ty = makeElementReturnTypeSingle(element);
      then
        ty;

    case elements
      algorithm
        types := {};
        names := {};
        for element in elements loop
          types := makeElementReturnTypeSingle(element)::types;
          names := DAEUtil.varName(element)::names;
        end for;
      if listEmpty(names) then
        namesOpt := NONE();
      else
        namesOpt := SOME(listReverse(names));
      end if;
      then DAE.T_TUPLE(listReverse(types), namesOpt, DAE.emptyTypeSource);
  end match;
end makeElementReturnType;

protected function makeElementReturnTypeSingle
"Create the return type from an Element for a single return value."
  input DAE.Element inElement;
  output DAE.Type outType;
algorithm
  outType := match (inElement)
    local
      Type ty;

    case DAE.VAR(ty = ty) then ty;
  end match;
end makeElementReturnTypeSingle;

public function makeEnumerationType
  "Creates an enumeration type from a name and an enumeration type containing
  the literal variables."
  input Absyn.Path inPath;
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue(inPath, inType)
    local
      Absyn.Path p;
      list<String> names, attr_names;
      list<DAE.Var> vars, attrs;
      Type ty;
      DAE.TypeSource ts;

    case (_, DAE.T_ENUMERATION(index = NONE(), path = p, names = names, literalVarLst = vars, attributeLst = attrs))
      equation
        vars = makeEnumerationType1(p, vars, names, 1);
        attr_names = List.map(vars, getVarName);
        attrs = makeEnumerationType1(p, attrs, attr_names, 1);
        ts = {inPath};
      then
        (DAE.T_ENUMERATION(NONE(), p, names, vars, attrs, ts));

    case (_, DAE.T_ARRAY(ty = ty))
      then makeEnumerationType(inPath, ty);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Types.makeEnumerationType failed on " + printTypeStr(inType));
      then
        fail();
  end matchcontinue;
end makeEnumerationType;

public function makeEnumerationType1
  "Helper function to makeEnumerationType. Updates a list of enumeration
  literals with the correct index and type."
  input Absyn.Path inPath;
  input list<DAE.Var> inVarLst;
  input list<String> inNames;
  input Integer inIdx;
  output list<DAE.Var> outVarLst;
algorithm
  outVarLst := match (inPath,inVarLst,inNames,inIdx)
    local
      list<String> names;
      Absyn.Path p;
      String name;
      list<DAE.Var> xs,vars;
      DAE.Type t;
      Integer idx;
      DAE.Attributes attributes;
      DAE.Binding binding;
      DAE.Var var;
      Option<DAE.Const> cnstForRange;

    case (p,DAE.TYPES_VAR(name,attributes,_,binding,cnstForRange) :: xs,names,idx)
      equation
        vars = makeEnumerationType1(p, xs, names, idx+1);
        t = DAE.T_ENUMERATION(SOME(idx),p,names,{},{},{p});
        var = DAE.TYPES_VAR(name,attributes,t,binding,cnstForRange);
      then
        (var :: vars);
    case (_,{},_,_) then {};
  end match;
end makeEnumerationType1;

public function printFarg "Prints a function argument to the Print buffer."
  input DAE.FuncArg inFuncArg;
algorithm
  _ := match (inFuncArg)
    local
      String n;
      DAE.Type ty;
    case DAE.FUNCARG(name=n,ty=ty)
      equation
        Print.printErrorBuf(printTypeStr(ty));
        Print.printErrorBuf(" ");
        Print.printErrorBuf(n);
      then
        ();
  end match;
end printFarg;

public function printFargStr "Prints a function argument to a string"
  input DAE.FuncArg inFuncArg;
  output String outString;
algorithm
  outString := match (inFuncArg)
    local
      String s,res,n,cs,ps;
      DAE.Type ty;
      DAE.Const c;
      DAE.VarParallelism p;

    case DAE.FUNCARG(n,ty,c,p,_)
      equation
        s = unparseType(ty);
        cs = DAEUtil.constStrFriendly(c);
        // res = stringAppendList({ps,cs,s," ",n});
        res = stringAppendList({cs,s," ",n});
      then
        res;
  end match;
end printFargStr;

protected function getInputVars "author: LS
  Retrieve all the input variables from a list of variables."
  input list<DAE.Var> vl;
  output list<DAE.Var> vl_1;
algorithm
  vl_1 := List.select(vl, isInputVar);
end getInputVars;

protected function getOutputVars "Retrieve all output variables from a list of variables."
  input list<DAE.Var> vl;
  output list<DAE.Var> vl_1;
algorithm
  vl_1 := List.select(vl, isOutputVar);
end getOutputVars;

public function getFixedVarAttributeParameterOrConstant
"Returns the value of the fixed attribute of a builtin type.
 If there is no fixed in the tyep it returns true"
  input DAE.Type tp;
  output Boolean fix;
algorithm
  try
    // there is a fixed!
    fix := getFixedVarAttribute(tp);
  else
    // there is no fixed!
    fix := true;
  end try;
end getFixedVarAttributeParameterOrConstant;

public function getFixedVarAttribute "Returns the value of the fixed attribute of a builtin type"
  input DAE.Type tp;
  output Boolean fixed;
algorithm
  fixed :=  matchcontinue(tp)
    local
      Type ty;
      Boolean result;
      list<DAE.Var> vars;

    case DAE.T_REAL(varLst = DAE.TYPES_VAR("fixed",binding = DAE.VALBOUND(valBound = Values.BOOL(fixed)))::_) then fixed;
    case DAE.T_REAL(varLst = DAE.TYPES_VAR("fixed",binding = DAE.EQBOUND(evaluatedExp = SOME(Values.BOOL(fixed))))::_) then fixed;
    case DAE.T_REAL(varLst = DAE.TYPES_VAR("fixed",binding = DAE.EQBOUND(exp = DAE.BCONST(fixed)))::_) then fixed;
    case DAE.T_REAL(varLst = _::vars) equation
      fixed = getFixedVarAttribute(DAE.T_REAL(vars,DAE.emptyTypeSource));
    then fixed;

    case DAE.T_INTEGER(varLst = DAE.TYPES_VAR("fixed",binding = DAE.VALBOUND(valBound = Values.BOOL(fixed)))::_) then fixed;
    case DAE.T_INTEGER(varLst = DAE.TYPES_VAR("fixed",binding = DAE.EQBOUND(evaluatedExp = SOME(Values.BOOL(fixed))))::_) then fixed;
    case DAE.T_INTEGER(varLst = DAE.TYPES_VAR("fixed",binding = DAE.EQBOUND(exp = DAE.BCONST(fixed)))::_) then fixed;
    case DAE.T_INTEGER(varLst = _::vars) equation
      fixed = getFixedVarAttribute(DAE.T_INTEGER(vars,DAE.emptyTypeSource));
    then fixed;

    case DAE.T_BOOL(varLst = DAE.TYPES_VAR("fixed",binding = DAE.VALBOUND(valBound = Values.BOOL(fixed)))::_) then fixed;
    case DAE.T_BOOL(varLst = DAE.TYPES_VAR("fixed",binding = DAE.EQBOUND(evaluatedExp = SOME(Values.BOOL(fixed))))::_) then fixed;
    case DAE.T_BOOL(varLst = DAE.TYPES_VAR("fixed",binding = DAE.EQBOUND(exp = DAE.BCONST(fixed)))::_) then fixed;
    case DAE.T_BOOL(varLst = _::vars) equation
      fixed = getFixedVarAttribute(DAE.T_BOOL(vars,DAE.emptyTypeSource));
    then fixed;

    case DAE.T_ARRAY(ty = ty)
      equation
        result = getFixedVarAttribute(ty);
      then
        result;
  end matchcontinue;
end getFixedVarAttribute;

public function getClassname "Return the classname from a type."
  input DAE.Type inType;
  output Absyn.Path outPath;
algorithm
  {outPath} := getTypeSource(inType);
end getClassname;

public function getClassnameOpt "Return the classname as option from a type."
  input DAE.Type inType;
  output Option<Absyn.Path> outPath;
algorithm
  outPath := matchcontinue(inType)
    local Absyn.Path p;
    case _
      equation
        {p} = getTypeSource(inType);
      then SOME(p);
    else NONE();
  end matchcontinue;
end getClassnameOpt;

public function getConnectorVars
  "Returns the list of variables in a connector, or fails if the type is not a
  connector."
  input DAE.Type inType;
  output list<DAE.Var> outVars;
algorithm
  outVars := match(inType)
    local list<DAE.Var> vars;
    case (DAE.T_COMPLEX(
          complexClassType = ClassInf.CONNECTOR(),
          varLst = vars))
      then vars;
  end match;
end getConnectorVars;

public function isInputVar
"Succeds if variable is an input variable."
  input DAE.Var inVar;
  output Boolean b;
algorithm
  b := match (inVar)
    local
      DAE.Attributes attr;

    case DAE.TYPES_VAR(attributes = attr)
      then isInputAttr(attr) and isPublicAttr(attr);
  end match;
end isInputVar;

public function isOutputVar
"Succeds if variable is an output variable."
  input DAE.Var inVar;
  output Boolean b;
algorithm
  b := match (inVar)
    local
      DAE.Attributes attr;

    case DAE.TYPES_VAR(attributes = attr)
      then isOutputAttr(attr) and isPublicAttr(attr);
  end match;
end isOutputVar;

public function isInputAttr "Returns true if the Attributes of a variable indicates
  that the variable is input."
  input DAE.Attributes inAttributes;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inAttributes)
    case DAE.ATTR(direction = Absyn.INPUT()) then true;
    else false;
  end match;
end isInputAttr;

public function isOutputAttr "Returns true if the Attributes of a variable indicates
  that the variable is output."
  input DAE.Attributes inAttributes;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inAttributes)
    case DAE.ATTR(direction = Absyn.OUTPUT()) then true;
    else false;
  end match;
end isOutputAttr;

public function isBidirAttr "Returns true if the Attributes of a variable indicates that the variable
  is bidirectional, i.e. neither input nor output."
  input DAE.Attributes inAttributes;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inAttributes)
    case DAE.ATTR(direction = Absyn.BIDIR()) then true;
    else false;
  end match;
end isBidirAttr;

public function isPublicAttr
  input DAE.Attributes inAttributes;
  output Boolean outIsPublic;
algorithm
  outIsPublic := match(inAttributes)
    case DAE.ATTR(visibility = SCode.PUBLIC()) then true;
    else false;
  end match;
end isPublicAttr;

public function isPublicVar
"true if variable is a public variable."
  input DAE.Var inVar;
  output Boolean b;
algorithm
  b := match (inVar)
    local
      DAE.Attributes attr;

    case DAE.TYPES_VAR(attributes = attr) then isPublicAttr(attr);
  end match;
end isPublicVar;

public function isProtectedVar
"true if variable is a protected variable."
  input DAE.Var inVar;
  output Boolean b;
algorithm
  b := match (inVar)
    local
      DAE.Attributes attr;

    case DAE.TYPES_VAR(attributes = attr) then not isPublicAttr(attr);
  end match;
end isProtectedVar;


public function isModifiableTypesVar
  input DAE.Var inVar;
  output Boolean b;
algorithm
  b := matchcontinue(inVar)
  local
    DAE.Attributes attrs;
    case(DAE.TYPES_VAR(attributes = attrs))
      equation
        false = isPublicAttr(attrs);
      then false;

    case(DAE.TYPES_VAR(attributes = attrs, binding = DAE.UNBOUND()))
      equation
        true = isConstAttr(attrs);
      then true;

    case(DAE.TYPES_VAR(attributes = attrs))
      equation
        true = isConstAttr(attrs);
      then false;

    else true;

  end matchcontinue;
end isModifiableTypesVar;

public function getBindingExp
  input DAE.Var inVar;
  input Absyn.Path inPath;
  output DAE.Exp outExp;
algorithm
  outExp := match(inVar, inPath)
  local
    DAE.Exp exp;
    String str;
    String name;

    case(DAE.TYPES_VAR(binding=DAE.EQBOUND(exp=exp)), _) then exp;
    case(DAE.TYPES_VAR(name=name, binding=DAE.UNBOUND()), _)
      equation
        str = "Record '" + Absyn.pathString(inPath) + "' member '" + name + "' has no default value and is not modifiable by a constructor function.\n";
        Error.addCompilerWarning(str);
      then
        DAE.ICONST(0);
  end match;
end getBindingExp;


public function isConstAttr
  input DAE.Attributes inAttributes;
  output Boolean outIsPublic;
algorithm
  outIsPublic := match(inAttributes)
    case DAE.ATTR(variability = SCode.CONST()) then true;
    else false;
  end match;
end isConstAttr;

public function makeFargsList
  "Makes a function argument list from a list of variables."
  input list<DAE.Var> vars;
  output list<DAE.FuncArg> fargs;
annotation(__OpenModelica_EarlyInline=true);
algorithm
  fargs := List.map(vars,makeFarg);
end makeFargsList;

protected function makeFarg
  "Makes a function argument list from a variable."
  input DAE.Var variable;
  output DAE.FuncArg farg;
algorithm
  farg := match (variable)
    local
      String n;
      DAE.Attributes attr;
      DAE.Type ty;
      DAE.Binding bnd;
      DAE.Const c;
      DAE.VarParallelism p;
      SCode.Variability var;
      SCode.Parallelism par;
      Option<DAE.Exp> oexp;
      Option<SCode.Comment> comment;

    case DAE.TYPES_VAR(name = n,attributes = DAE.ATTR(variability = var, parallelism = par),ty = ty,binding = bnd)
      equation
        c = variabilityToConst(var);
        p = DAEUtil.scodePrlToDaePrl(par);
        oexp = DAEUtil.bindingExp(bnd);
      then DAE.FUNCARG(n,ty,c,p,oexp);
  end match;
end makeFarg;

protected function makeElementFarg
  "Makes a function argument list from a variable."
  input DAE.Element inElement;
  input DAE.FuncArg inFarg;
  output DAE.FuncArg farg;
algorithm
  farg := match (inElement, inFarg)
    local
      String name;
      DAE.VarKind varKind;
      Type ty;
      DAE.Const c;
      Option<DAE.Exp> binding;
      DAE.ComponentRef cref;
      DAE.VarParallelism parallelism;

    case (DAE.VAR(componentRef=cref), _)
      equation
        name = ComponentReference.crefLastIdent(cref);
      then setFuncArgName(inFarg, name);
  end match;
end makeElementFarg;

protected function makeReturnType "author: LS
  Create a return type from a list of output variables.
  Depending on the length of the output variable list, different
  kinds of return types are created."
  input list<DAE.Var> inVarLst;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inVarLst)
    local
      Type ty;
      Var var;
      list<DAE.Type> tys;
      list<DAE.Var> vl;

    case {} then DAE.T_NORETCALL(DAE.emptyTypeSource);

    case {var}
      equation
        ty = makeReturnTypeSingle(var);
      then
        ty;

    case vl
      then DAE.T_TUPLE(
        list(makeReturnTypeSingle(v) for v in vl),
        SOME(list(varName(v) for v in vl)),
        DAE.emptyTypeSource);
  end matchcontinue;
end makeReturnType;

protected function makeReturnTypeSingle "author: LS
  Create the return type for a single return value."
  input DAE.Var inVar;
  output DAE.Type outType;
algorithm
  outType := match (inVar)
    local
      Type ty;

    case DAE.TYPES_VAR(ty = ty) then ty;
  end match;
end makeReturnTypeSingle;

public function isParameterVar "author: LS
  Succeds if a variable is a parameter."
  input DAE.Var inVar;
algorithm
  DAE.TYPES_VAR(attributes = DAE.ATTR(variability = SCode.PARAM(),visibility = SCode.PUBLIC())) := inVar;
end isParameterVar;

public function isConstant
  "Returns true of c is C_CONST."
  input DAE.Const c;
  output Boolean b;
algorithm
  b := match(c)
    case (DAE.C_CONST()) then true;
    else false;
  end match;
end isConstant;

public function isParameter
  "Returns true if c is C_PARAM."
  input DAE.Const c;
  output Boolean b;
algorithm
  b := match(c)
    case DAE.C_PARAM() then true;
    else false;
  end match;
end isParameter;

public function isParameterOrConstant "returns true if Const is PARAM or CONST"
  input DAE.Const c;
  output Boolean b;
algorithm
  b := match(c)
    case(DAE.C_CONST()) then true;
    case(DAE.C_PARAM()) then true;
    else false;
  end match;
end isParameterOrConstant;

public function isVar
  input DAE.Const inConst;
  output Boolean outIsVar;
algorithm
  outIsVar := match(inConst)
    case DAE.C_VAR() then true;
    else false;
  end match;
end isVar;

public function propsContainReal
  "Returns true if any of the given properties contains a Real type."
  input list<DAE.Properties> inProperties;
  output Boolean outHasReal = false;
algorithm
  for prop in inProperties loop
    if isReal(getPropType(prop)) then
      outHasReal := true;
      break;
    end if;
  end for;
end propsContainReal;

public function containReal
  "Returns true if a builtin type, or array-type is Real."
  input list<DAE.Type> inTypes;
  output Boolean outHasReal;
algorithm
  for ty in inTypes loop
    if isReal(ty) then
      outHasReal := true;
      return;
    end if;
  end for;
  outHasReal := false;
end containReal;

public function flattenArrayType
  "Returns the element type of a Type and the dimensions of the type."
  input DAE.Type inType;
  output DAE.Type outType;
  output DAE.Dimensions outDimensions;
algorithm
  (outType, outDimensions) := match inType
    local
      Type ty;
      DAE.Dimensions dims;
      DAE.Dimension dim;

    // Array type
    case DAE.T_ARRAY(dims = {dim})
      equation
        (ty, dims) = flattenArrayType(inType.ty);
      then
        (ty, dim :: dims);

    // Array type
    case DAE.T_ARRAY()
      equation
        (ty, dims) = flattenArrayType(inType.ty);
        dims = listAppend(inType.dims, dims);
      then
        (ty, dims);

    // Complex type extending basetype with equality constraint
    case DAE.T_SUBTYPE_BASIC(equalityConstraint = SOME(_))
      then (inType, {});

    // Complex type extending basetype.
    case DAE.T_SUBTYPE_BASIC()
      then flattenArrayType(inType.complexType);

    // Element type
    else (inType, {});
  end match;
end flattenArrayType;

public function getTypeName "Return the type name of a Type."
  input DAE.Type inType;
  output String outString;
algorithm
  outString := matchcontinue (inType)
    local
      String n,dimstr,tystr,str;
      ClassInf.State st;
      DAE.Type ty,arrayty;
      list<DAE.Dimension> dims;

    case (DAE.T_INTEGER()) then "Integer";
    case (DAE.T_REAL()) then "Real";
    case (DAE.T_STRING()) then "String";
    case (DAE.T_BOOL()) then "Boolean";
    // BTH
    case (DAE.T_CLOCK()) then "Clock";
    case (DAE.T_COMPLEX(complexClassType = st))
      equation
        n = Absyn.pathString(ClassInf.getStateName(st));
      then
        n;
    case (DAE.T_SUBTYPE_BASIC(complexClassType = st))
      equation
        n = Absyn.pathString(ClassInf.getStateName(st));
      then
        n;
    case (arrayty as DAE.T_ARRAY())
      equation
        (ty,dims) = flattenArrayType(arrayty);
        dimstr = ExpressionDump.dimensionsString(dims);
        tystr = getTypeName(ty);
        str = stringAppendList({tystr,"[",dimstr,"]"});
      then
        str;

    // MetaModelica type
    case (DAE.T_METALIST(ty = ty))
      equation
        n = getTypeName(ty);
      then
        n;

    else "Not nameable type or no type";
  end matchcontinue;
end getTypeName;

public function propAllConst "author: LS
  If PROP_TUPLE, returns true if all of the flags are constant."
  input DAE.Properties inProperties;
  output DAE.Const outConst;
algorithm
  outConst := matchcontinue (inProperties)
    local
      DAE.Const c,res;
      DAE.TupleConst constant_;
      String str;
      DAE.Properties prop;
    case DAE.PROP(constFlag = c) then c;
    case DAE.PROP_TUPLE(tupleConst = constant_)
      equation
        res = propTupleAllConst(constant_);
      then
        res;
    case prop
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- prop_all_const failed: ");
        str = printPropStr(prop);
        Debug.traceln(str);
      then
        fail();
  end matchcontinue;
end propAllConst;

public function propAnyConst "author: LS
  If PROP_TUPLE, returns true if any of the flags are true"
  input DAE.Properties inProperties;
  output DAE.Const outConst;
algorithm
  outConst := matchcontinue (inProperties)
    local
      DAE.Const constant_,res;
      String str;
      DAE.Properties prop;
      DAE.TupleConst tconstant_;
    case DAE.PROP(constFlag = constant_) then constant_;
    case DAE.PROP_TUPLE(tupleConst = tconstant_)
      equation
        res = propTupleAnyConst(tconstant_);
      then
        res;
    case prop
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- prop_any_const failed: ");
        str = printPropStr(prop);
        Debug.traceln(str);
      then
        fail();
  end matchcontinue;
end propAnyConst;

protected function propTupleAnyConst "author: LS
  Helper function to prop_any_const."
  input DAE.TupleConst inTupleConst;
  output DAE.Const outConst;
algorithm
  outConst := matchcontinue (inTupleConst)
    local
      DAE.Const c,res;
      DAE.TupleConst first,const;
      list<DAE.TupleConst> rest;
      String str;
    case DAE.SINGLE_CONST(const = c) then c;
    case DAE.TUPLE_CONST(tupleConstLst = (first :: _))
      equation
        DAE.C_CONST() = propTupleAnyConst(first);
      then
        DAE.C_CONST();
    case DAE.TUPLE_CONST(tupleConstLst = (first :: {}))
      equation
        DAE.C_PARAM() = propTupleAnyConst(first);
      then
        DAE.C_PARAM();
    case DAE.TUPLE_CONST(tupleConstLst = (first :: {}))
      equation
        DAE.C_VAR() = propTupleAnyConst(first);
      then
        DAE.C_VAR();
    case DAE.TUPLE_CONST(tupleConstLst = (first :: rest))
      equation
        DAE.C_PARAM() = propTupleAnyConst(first);
        res = propTupleAnyConst(DAE.TUPLE_CONST(rest));
      then
        res;
    case DAE.TUPLE_CONST(tupleConstLst = (first :: rest))
      equation
        DAE.C_VAR() = propTupleAnyConst(first);
        res = propTupleAnyConst(DAE.TUPLE_CONST(rest));
      then
        res;
    case const
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- prop_tuple_any_const failed: ");
        str = printTupleConstStr(const);
        Debug.traceln(str);
      then
        fail();
  end matchcontinue;
end propTupleAnyConst;

public function propTupleAllConst "author: LS
  Helper function to propAllConst."
  input DAE.TupleConst inTupleConst;
  output DAE.Const outConst;
algorithm
  outConst := matchcontinue (inTupleConst)
    local
      DAE.Const c,res;
      DAE.TupleConst first,const;
      list<DAE.TupleConst> rest;
      String str;
    case DAE.SINGLE_CONST(const = c) then c;
    case DAE.TUPLE_CONST(tupleConstLst = (first :: _))
      equation
        DAE.C_PARAM() = propTupleAllConst(first);
      then
        DAE.C_PARAM();
    case DAE.TUPLE_CONST(tupleConstLst = (first :: _))
      equation
        DAE.C_VAR() = propTupleAllConst(first);
      then
        DAE.C_VAR();
    case DAE.TUPLE_CONST(tupleConstLst = (first :: {}))
      equation
        DAE.C_CONST() = propTupleAllConst(first);
      then
        DAE.C_CONST();
    case DAE.TUPLE_CONST(tupleConstLst = (first :: rest))
      equation
        DAE.C_CONST() = propTupleAllConst(first);
        res = propTupleAllConst(DAE.TUPLE_CONST(rest));
      then
        res;
    case const
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- prop_tuple_all_const failed: ");
        str = printTupleConstStr(const);
        Debug.traceln(str);
      then
        fail();
  end matchcontinue;
end propTupleAllConst;

public function isPropTupleArray "This function will check all elements in the tuple if anyone is an array, return true.
As for now it will not check tuple of tuples ie. no recursion."
  input DAE.Properties p;
  output Boolean ob;
protected
  Boolean b1,b2;
algorithm
  b1 := isPropTuple(p);
  b2 := isPropArray(p);
  ob := boolOr(b1,b2);
end isPropTupleArray;

public function isPropTuple
"Checks if Properties is a tuple or not."
  input DAE.Properties p;
  output Boolean b;
algorithm
  b := matchcontinue (p)
    case _
      equation
        DAE.T_TUPLE() = getPropType(p);
      then
        true;
    else false;
  end matchcontinue;
end isPropTuple;

public function isPropArray "Return true if properties contain an array type."
  input DAE.Properties p;
  output Boolean b;
protected
  Type t;
algorithm
  t := getPropType(p);
  b := isArray(t);
end isPropArray;

public function propTupleFirstProp
  "Returns the first property from a tuple's properties or fails."
  input DAE.Properties inTupleProp;
  output DAE.Properties outFirstProp;
protected
  Type ty;
  DAE.Const c;
algorithm
  DAE.PROP_TUPLE(type_ = DAE.T_TUPLE(types = ty :: _),
    tupleConst = DAE.TUPLE_CONST(tupleConstLst = DAE.SINGLE_CONST(const = c) :: _)) := inTupleProp;
  outFirstProp := DAE.PROP(ty, c);
end propTupleFirstProp;

public function propTuplePropList
  "Splits a PROP_TUPLE into a list of PROPs."
  input DAE.Properties prop_tuple;
  output list<DAE.Properties> prop_list;
algorithm
  prop_list := match(prop_tuple)
    local
      list<DAE.Properties> pl;
      list<DAE.Type> tl;
      list<TupleConst> cl;
    case (DAE.PROP_TUPLE(type_ = DAE.T_TUPLE(types = tl),
                         tupleConst = DAE.TUPLE_CONST(tupleConstLst = cl)))
      equation
        pl = propTuplePropList2(tl, cl);
      then
        pl;
  end match;
end propTuplePropList;

protected function propTuplePropList2
  "Helper function to propTuplePropList"
  input list<DAE.Type> tl;
  input list<TupleConst> cl;
  output list<DAE.Properties> pl;
algorithm
  pl := match(tl, cl)
    local
     Type t;
      list<DAE.Type> t_rest;
      Const c;
      list<TupleConst> c_rest;
      list<DAE.Properties> p_rest;
    case ({}, {}) then {};
    case (t :: t_rest, DAE.SINGLE_CONST(c) :: c_rest)
      equation
        p_rest = propTuplePropList2(t_rest, c_rest);
      then
        (DAE.PROP(t, c) :: p_rest);
  end match;
end propTuplePropList2;

public function getPropConst "author: adrpo
  Return the const from Properties (no tuples!)."
  input DAE.Properties inProperties;
  output DAE.Const outConst;
algorithm
   DAE.PROP(constFlag = outConst) := inProperties;
end getPropConst;

public function getPropType "author: LS
  Return the Type from Properties."
  input DAE.Properties inProperties;
  output DAE.Type outType;
algorithm
  outType := match inProperties
    case DAE.PROP() then inProperties.type_;
    case DAE.PROP_TUPLE() then inProperties.type_;
  end match;
end getPropType;

public function setPropType "Set the Type from Properties."
  input DAE.Properties inProperties;
  input DAE.Type ty;
  output DAE.Properties outProperties;
algorithm
  outProperties := match inProperties
    case DAE.PROP() then DAE.PROP(ty, inProperties.constFlag);
    case DAE.PROP_TUPLE() then DAE.PROP_TUPLE(ty, inProperties.tupleConst);
  end match;
end setPropType;

public function createEmptyTypeMemory
"@author: adrpo
  creates an array, with one element for each record in TType!
  Note: This has to be at least 4 larger than the number of records in DAE.Type,
  due to the way bootstrapping indexes records."
  output InstTypes.TypeMemoryEntryListArray tyMemory;
algorithm
  tyMemory := arrayCreate(30, {});
end createEmptyTypeMemory;

public function simplifyType
"@author: adrpo
  simplifies the given type, to be used in an expression or component reference"
  input DAE.Type inType;
  output DAE.Type outExpType;
algorithm
  outExpType := matchcontinue (inType)
    local
      String str;
      Type t;
      DAE.Type t_1;
      DAE.Dimensions dims;
      list<DAE.Type> tys;
      list<DAE.Var> varLst;
      ClassInf.State CIS;
      DAE.EqualityConstraint ec;
      DAE.TypeSource ts;

    case (DAE.T_FUNCTION()) then DAE.T_FUNCTION_REFERENCE_VAR(inType,DAE.emptyTypeSource);

    case (DAE.T_METAUNIONTYPE()) then DAE.T_METATYPE(inType, DAE.emptyTypeSource);
    case (DAE.T_METARECORD()) then DAE.T_METATYPE(inType, DAE.emptyTypeSource);
    case (DAE.T_METAPOLYMORPHIC()) then DAE.T_METATYPE(inType, DAE.emptyTypeSource);
    case (DAE.T_METALIST()) then DAE.T_METATYPE(inType, DAE.emptyTypeSource);
    case (DAE.T_METAARRAY()) then DAE.T_METATYPE(inType, DAE.emptyTypeSource);
    case (DAE.T_METAOPTION()) then DAE.T_METATYPE(inType, DAE.emptyTypeSource);
    case (DAE.T_METATUPLE()) then DAE.T_METATYPE(inType, DAE.emptyTypeSource);

    case (DAE.T_UNKNOWN()) then DAE.T_UNKNOWN_DEFAULT;
    case (DAE.T_ANYTYPE()) then DAE.T_UNKNOWN_DEFAULT;

    case (t as DAE.T_ARRAY())
      equation
        (t,dims) = flattenArrayType(t);
        t_1 = simplifyType(t);
      then
        DAE.T_ARRAY(t_1,dims,DAE.emptyTypeSource);

    // do NOT simplify out equality constraint
    case (DAE.T_SUBTYPE_BASIC(equalityConstraint = SOME(_))) then inType;
    case (DAE.T_SUBTYPE_BASIC(complexType = t)) then simplifyType(t);

    case (DAE.T_INTEGER()) then DAE.T_INTEGER_DEFAULT;
    case (DAE.T_REAL()) then DAE.T_REAL_DEFAULT;
    case (DAE.T_BOOL()) then DAE.T_BOOL_DEFAULT;
    // BTH watch out: Due to simplification some type info is lost here
    case (DAE.T_CLOCK()) then DAE.T_CLOCK_DEFAULT;
    case (DAE.T_STRING()) then DAE.T_STRING_DEFAULT;
    case (DAE.T_NORETCALL()) then DAE.T_NORETCALL_DEFAULT;
    case (DAE.T_TUPLE(types = tys))
      equation
        tys = List.map(tys, simplifyType);
      then DAE.T_TUPLE(tys, inType.names, DAE.emptyTypeSource);

    case (DAE.T_ENUMERATION()) then inType;

    // for metamodelica we need this for some reson!
    case (DAE.T_COMPLEX(CIS, varLst, ec, ts))
      equation
        true = Config.acceptMetaModelicaGrammar();
        varLst = list(simplifyVar(v) for v in varLst);
      then
        DAE.T_COMPLEX(CIS, varLst, ec, ts);

    // do this for records too, otherwise:
    // frame.R = Modelica.Mechanics.MultiBody.Frames.Orientation({const_matrix);
    // does not get expanded into the component equations.
    case (DAE.T_COMPLEX(CIS as ClassInf.RECORD(_), varLst, ec, ts))
      equation
        varLst = list(simplifyVar(v) for v in varLst);
      then
        DAE.T_COMPLEX(CIS, varLst, ec, ts);

    // otherwise just return the same!
    case (DAE.T_COMPLEX(_, _, _, _)) then inType;

    case (DAE.T_METABOXED(ty = t))
      equation
        t_1 = simplifyType(t);
      then
        DAE.T_METABOXED(t_1, DAE.emptyTypeSource);

    // This is the case when the type is currently UNTYPED
    case _
      equation
        /*
        print(" untyped ");
        print(unparseType(inType));
        print("\n");
        */
      then DAE.T_UNKNOWN_DEFAULT;

    else
      equation
        str = "Types.simplifyType failed for: " + unparseType(inType);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end simplifyType;

protected function simplifyVar
  input DAE.Var inVar;
  output DAE.Var outVar = inVar;
algorithm
  outVar := match outVar
    case DAE.TYPES_VAR()
      algorithm
        outVar.ty := simplifyType(outVar.ty);
      then
        outVar;
  end match;
end simplifyVar;

public function complicateType
  "Does the opposite of simplifyType, as far as it's possible."
  input DAE.Type inType;
  output DAE.Type outType = inType;
algorithm
  outType := match outType
    local
      DAE.Type ty;
      list<DAE.Dimension> dims;

    case DAE.T_ARRAY(dims = _ :: _)
      algorithm
        (ty, dims) := flattenArrayType(outType);
      then
        liftArrayListDims(ty, dims);

    case DAE.T_FUNCTION_REFERENCE_VAR() then outType.functionType;
    case DAE.T_METATYPE() then outType.ty;

    case DAE.T_TUPLE()
      algorithm
        outType.types := list(complicateType(t) for t in outType.types);
      then
        outType;

    case DAE.T_COMPLEX()
      algorithm
        if isRecord(inType) or Config.acceptMetaModelicaGrammar() then
          outType.varLst := list(complicateVar(v) for v in outType.varLst);
        end if;
      then
        outType;

    case DAE.T_METABOXED()
      algorithm
        outType.ty := complicateType(outType.ty);
      then
        outType;

    else outType;
  end match;
end complicateType;

protected function complicateVar
  input DAE.Var inVar;
  output DAE.Var outVar = inVar;
algorithm
  outVar := match outVar
    case DAE.TYPES_VAR()
      algorithm
        outVar.ty := complicateType(outVar.ty);
      then
        outVar;
  end match;
end complicateVar;

protected function typeMemoryEntryEq
  input DAE.Type inType1;
  input tuple<DAE.Type, DAE.Type> inType2;
  output Boolean outEq;
protected
  DAE.Type ty2;
algorithm
  (ty2, _) := inType2;
  outEq := typesElabEquivalent(inType1, ty2);
end typeMemoryEntryEq;

public function typesElabEquivalent
  "This function checks if two types will result in the same elaborated type.
  Used by simplifyType to check if a matching elaborated type already exists."
  input DAE.Type inType1;
  input DAE.Type inType2;
  output Boolean isEqual;
algorithm
  try
    isEqual := ttypesElabEquivalent(inType1, inType2);
  else
    isEqual := false;
  end try;
end typesElabEquivalent;

protected function ttypesElabEquivalent
  "Helper function to typesElabEquivalent. Checks if two TType will result in
  the same elaborated type."
  input DAE.Type inType1;
  input DAE.Type inType2;
  output Boolean isEqual;
algorithm
  isEqual := match(inType1, inType2)
    local
      ClassInf.State cty1, cty2;
      list<DAE.Var> vars1, vars2;
      DAE.Dimension ad1, ad2;
      DAE.Type ty1, ty2;
      Absyn.Path p1, p2;
      list<String> names1, names2;
      list<DAE.Type> types1, types2;

    case (DAE.T_COMPLEX(complexClassType = cty1, varLst = vars1),
          DAE.T_COMPLEX(complexClassType = cty2, varLst = vars2))
      equation
        true = Absyn.pathEqual(ClassInf.getStateName(cty1),
                               ClassInf.getStateName(cty2));
        true = List.isEqualOnTrue(vars1, vars2,
          varsElabEquivalent);
      then
        true;

    case (DAE.T_ARRAY(dims = {ad1}, ty = ty1),
          DAE.T_ARRAY(dims = {ad2}, ty = ty2))
      equation
        true = valueEq(ad1, ad2);
        true = typesElabEquivalent(ty1, ty2);
      then
        true;

    case (DAE.T_ENUMERATION(path = p1, names = names1),
          DAE.T_ENUMERATION(path = p2, names = names2))
      equation
        true = Absyn.pathEqual(p1, p2);
        true = List.isEqualOnTrue(names1, names2, stringEqual);
      then
        true;

    case (DAE.T_TUPLE(types = types1),
          DAE.T_TUPLE(types = types2))
      then List.isEqualOnTrue(types1, types2,
          typesElabEquivalent);

    case (DAE.T_METABOXED(ty = ty1),
          DAE.T_METABOXED(ty = ty2))
      then typesElabEquivalent(ty1, ty2);

    else valueEq(inType1, inType2);

  end match;
end ttypesElabEquivalent;

protected function varsElabEquivalent
  "Helper function to ttypesElabEquivalent. Check if two DAE.Var will result in
  the same DAE.Var after elaboration."
  input DAE.Var inVar1;
  input DAE.Var inVar2;
  output Boolean isEqual;
algorithm
  isEqual := matchcontinue(inVar1, inVar2)
    local
      DAE.Ident id1, id2;
      DAE.Type ty1, ty2;

    case (DAE.TYPES_VAR(name = id1, ty = ty1),
          DAE.TYPES_VAR(name = id2, ty = ty2))
      equation
        true = stringEqual(id1, id2);
        true = typesElabEquivalent(ty1, ty2);
      then
        true;

    else false;

  end matchcontinue;
end varsElabEquivalent;

public function matchProp
"This is basically a wrapper aroune matchType.
  It matches an expression with properties with another set of properties.
  If necessary, the expression is modified to match.
  The only relevant property is the type."
  input DAE.Exp inExp;
  input DAE.Properties inActualType;
  input DAE.Properties inExpectedType;
  input Boolean printFailtrace;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outExp,outProperties) := matchcontinue (inExp, inActualType, inExpectedType, printFailtrace)
    local
      DAE.Exp e_1,e;
      Type t_1,gt,et;
      Const c,c1,c2,c_1;
      TupleConst tc,tc1,tc2;
      Properties prop;
    case (e,DAE.PROP(type_ = gt,constFlag = c1),DAE.PROP(type_ = et,constFlag = c2),_)
      equation
        (e_1,t_1) = matchType(e, gt, et, printFailtrace);
        c = constAnd(c1, c2);
      then
        (e_1,DAE.PROP(t_1,c));
    case (e,DAE.PROP_TUPLE(type_ = gt,tupleConst = tc1),DAE.PROP_TUPLE(type_ = et,tupleConst = tc2),_)
      equation
        (e_1,t_1) = matchType(e, gt, et, printFailtrace);
        tc = constTupleAnd(tc1, tc2);
      then
        (e_1,DAE.PROP_TUPLE(t_1,tc));

    // The problem with MetaModelica tuple is that it is a datatype (should use PROP instead of PROP_TUPLE)
    // this case converts a TUPLE to META_TUPLE
    case (e,DAE.PROP_TUPLE(type_ = gt as DAE.T_TUPLE(),tupleConst = tc1), DAE.PROP(type_ = et as DAE.T_METATUPLE(),constFlag = c2),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (e_1,t_1) = matchType(e, gt, et, printFailtrace);
        c_1 = propTupleAllConst(tc1);
        c = constAnd(c_1, c2);
      then
        (e_1,DAE.PROP(t_1,c));
    case (e,DAE.PROP_TUPLE(type_ = gt as DAE.T_TUPLE(),tupleConst = tc1), DAE.PROP(type_ = et as DAE.T_METABOXED(),constFlag = c2),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (e_1,t_1) = matchType(e, gt, et, printFailtrace);
        c_1 = propTupleAllConst(tc1);
        c = constAnd(c_1, c2);
      then
        (e_1,DAE.PROP(t_1,c));

    case (e,DAE.PROP(type_ = gt),DAE.PROP_TUPLE(),_)
      equation
        prop = propTupleFirstProp(inExpectedType);
        (e_1, prop) = matchProp(e, inActualType, prop, printFailtrace);
        gt = simplifyType(gt);
        e_1 = DAE.TSUB(e_1, 1, gt);
      then
        (e_1, prop);

    case (e,DAE.PROP_TUPLE(),DAE.PROP(),_)
      equation
        (prop as DAE.PROP(type_ = gt)) = propTupleFirstProp(inActualType);
        (e_1, prop) = matchProp(e, prop, inExpectedType, printFailtrace);
        gt = simplifyType(gt);
        e_1 = DAE.TSUB(e_1, 1, gt);
      then
        (e_1, prop);

    case(e, _, _, true)
      equation
        // activate on +d=types flag
        true = Flags.isSet(Flags.TYPES);
        Debug.traceln("- Types.matchProp failed on exp: " + ExpressionDump.printExpStr(e));
        Debug.traceln(printPropStr(inActualType) + " != ");
        Debug.traceln(printPropStr(inExpectedType));
      then fail();
  end matchcontinue;
end matchProp;

public function matchTypeList
  input list<DAE.Exp> exps;
  input DAE.Type expType;
  input DAE.Type expectedType;
  input Boolean printFailtrace;
  output list<DAE.Exp> outExp = {};
  output list<DAE.Type> outTypeLst = {};
protected
  list<DAE.Exp> expLstNew = exps;
  DAE.Exp exp, e_1;
  Type tp;
algorithm
  while not listEmpty(expLstNew) loop
    exp::expLstNew := expLstNew;
    (e_1, tp) := matchType(exp, expType, expectedType, printFailtrace);
    outExp := e_1 :: outExp;
    outTypeLst := tp :: outTypeLst;
  end while;
  outExp := listReverseInPlace(outExp);
  outTypeLst := listReverseInPlace(outTypeLst);
end matchTypeList;

public function matchTypeTuple
"Transforms a list of expressions and types into a list of expressions
of the expected types."
  input list<DAE.Exp> inExp1;
  input list<DAE.Type> inTypeLst2;
  input list<DAE.Type> inTypeLst3;
  input Boolean printFailtrace;
  output list<DAE.Exp> outExp;
  output list<DAE.Type> outTypeLst;
algorithm
  (outExp,outTypeLst):=
  matchcontinue (inExp1,inTypeLst2,inTypeLst3,printFailtrace)
    local
      DAE.Exp e,e_1;
      list<DAE.Exp> rest, e_2;
      Type tp,t1,t2;
      list<DAE.Type> res,ts1,ts2;
    case ({},{},{},_) then ({},{});
    case (e::rest,(t1 :: ts1),(t2 :: ts2),_)
      equation
        (e_1,tp) = matchType(e,t1,t2,printFailtrace);
        (e_2,res) = matchTypeTuple(rest,ts1,ts2,printFailtrace);
      then
        (e_1::e_2,(tp :: res));
    case (_,(t1 :: _),(t2 :: _),true)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Types.matchTypeTuple failed:"+Types.unparseType(t1)+" "+Types.unparseType(t2)+"\n");
      then
        fail();
  end matchcontinue;
end matchTypeTuple;

public function matchTypeTupleCall
  input DAE.Exp inExp1;
  input list<DAE.Type> inTypeLst2;
  input list<DAE.Type> inTypeLst3;
algorithm
  _ :=
  matchcontinue (inExp1,inTypeLst2,inTypeLst3)
    local
      DAE.Exp e;
      Type t1,t2;
      list<DAE.Type> ts1,ts2;
    case (_,_,{}) then ();
    case (e,(t1 :: ts1),(t2 :: ts2))
      equation
        // We cannot use matchType here because it does not cast tuple calls properly
        true = subtype(t1, t2);
        /* (oe,_) = matchType(e, t1, t2, true);
        true = Expression.expEqual(e,oe); */
        matchTypeTupleCall(e, ts1, ts2);
      then ();
    case (_,(_ :: _),(_ :: _))
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- matchTypeTupleCall failed\n");
      then
        fail();
  end matchcontinue;
end matchTypeTupleCall;

public function vectorizableType "author: PA
  This function checks if a given type can be (converted and) vectorized to
  a expected type.
  For instance and argument of type Integer{:} can be vectorized to an
  argument type Real, using type coersion and vectorization of one dimension."
  input DAE.Exp inExp;
  input DAE.Type inExpType;
  input DAE.Type inExpectedType;
  input Option<Absyn.Path> fnPath;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output DAE.Dimensions outArrayDimLst;
  output InstTypes.PolymorphicBindings outBindings;
algorithm
  (outExp,outType,outArrayDimLst,outBindings) := vectorizableType2(inExp,inExpType,inExpType,{},inExpectedType,fnPath);
end vectorizableType;

protected function vectorizableType2
  input DAE.Exp inExp;
  input DAE.Type inExpType;
  input DAE.Type inCurrentType;
  input DAE.Dimensions inDims;
  input DAE.Type inExpectedType;
  input Option<Absyn.Path> fnPath;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output DAE.Dimensions outDims;
  output InstTypes.PolymorphicBindings outBindings;
protected
  Type vec_type, cur_type;
  DAE.Dimension dim;
algorithm
  try
    vec_type := liftArrayListDimsReverse(inExpectedType, inDims);
    (outExp, outType, outBindings) :=
      matchTypePolymorphic(inExp, inExpType, vec_type, fnPath, {}, true);
    outDims := listReverse(inDims);
  else
    DAE.T_ARRAY(ty = cur_type, dims = {dim}) := inCurrentType;
    (outExp, outType, outDims, outBindings) :=
      vectorizableType2(inExp, inExpType, cur_type, dim :: inDims, inExpectedType, fnPath);
  end try;
end vectorizableType2;

public function unflattenArrayType
"transforms T_ARRAY(a::b::c) to T_ARRAY(a, T_ARRAY(b, T_ARRAY(c)))
 Always call it with "
  input DAE.Type inTy;
  output DAE.Type outTy;
algorithm
  outTy := unflattenArrayType2(inTy, false);
end unflattenArrayType;

protected function unflattenArrayType2
"transforms T_ARRAY(a::b::c) to T_ARRAY(a, T_ARRAY(b, T_ARRAY(c)))
 Always call it with "
  input DAE.Type inTy;
  input Boolean last;
  output DAE.Type outTy;
algorithm
  outTy := matchcontinue(inTy, last)
    local
      DAE.Type ty, t;
      DAE.TypeSource ts;
      DAE.Dimensions dims;
      DAE.Dimension dim;
      ClassInf.State ci;
      list<DAE.Var> vl;
      EqualityConstraint eqc;

    // subtype basic crap
    case (DAE.T_SUBTYPE_BASIC(ci, vl, ty, eqc, ts), _)
      equation
        ty = unflattenArrayType(ty);
      then
        DAE.T_SUBTYPE_BASIC(ci, vl, ty, eqc, ts);

    // already in the way we want it
    case (DAE.T_ARRAY(t, {dim}, ts), _)
      equation
        t = unflattenArrayType(t);
      then
        DAE.T_ARRAY(t, {dim}, ts);

    // we might get here via true!
    case (DAE.T_ARRAY(t, {}, _), true)
      equation
        t = unflattenArrayType(t);
      then
        t;

    // the usual case
    case (DAE.T_ARRAY(t, dim::dims, ts), _)
      equation
        ty = unflattenArrayType2(DAE.T_ARRAY(t, dims, ts), true);
        ty = DAE.T_ARRAY(ty, {dim}, ts);
      then
        ty;

    case (ty, false) then ty;
  end matchcontinue;
end unflattenArrayType2;

protected function typeConvert
"This functions converts the expression in the first argument to
  the type specified in the third argument.  The current type of the
  expression is given in the second argument.
  If no type conversion is possible, this function fails."
  input DAE.Exp inExp1;
  input DAE.Type actual;
  input DAE.Type expected;
  input Boolean printFailtrace;
  output DAE.Exp outExp;
  output DAE.Type outType;
algorithm
  (outExp,outType):=
  matchcontinue (inExp1,actual,expected,printFailtrace)
    local
      list<DAE.Exp> elist_1,elist,inputs;
      DAE.Type at,t;
      Boolean sc, a;
      Integer nmax, oi;
      DAE.Dimension dim1, dim2, dim11, dim22;
      DAE.Dimensions dims;
      Type ty1,ty2,t1,t2,t_1,t_2,ty0,ty;
      DAE.Exp begin_1,step_1,stop_1,begin,step,stop,e_1,e,exp;
      list<list<DAE.Exp>> ell_1,ell,elist_big;
      list<DAE.Type> tys_1,tys1,tys2;
      String name;
      list<String> l;
      list<DAE.Var> v;
      Absyn.Path path,path1,path2;
      list<Absyn.Path> pathList;
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> crefList;
      list<DAE.Type> expTypes;
      DAE.Type et,ety1;
      list<DAE.MatchCase> cases;
      DAE.MatchType matchTy;
      list<DAE.Element> localDecls;
      DAE.TypeSource ts,ts1,ts2;
      list<DAE.Var> els1,els2;
      Absyn.Path p1,p2,tp;
      list<list<String>> aliases;

    // For the types that cannot be type-converted, but may be subtypes of another type
    case (e, ty1, ty2, _)
      equation
        true = subtype(ty1,ty2);
      then (e, ty2);

    // if we expect notTuple and we get Tuple do DAE.TSUB(e, 1)
    // we try subtype of the first tuple element with the other type!
    case (e, DAE.T_TUPLE(types = ty1::_), ty2, _)
      equation
        false = Config.acceptMetaModelicaGrammar();
        false = isTuple(ty2);
        true = subtype(ty1, ty2);
        e = DAE.TSUB(e, 1, ty2);
        ty = ty2;
      then
        (e, ty);

    // try dims as list T_ARRAY(a::b::c)
    case (e,DAE.T_ARRAY(dims = _::_::_),ty2,_)
      equation
         ty1 = unflattenArrayType(actual);
         ty2 = unflattenArrayType(ty2);
         (e, ty) = typeConvert(e, ty1, ty2, printFailtrace);
      then
        (e, ty);

    // try dims as list T_ARRAY(a::b::c)
    case (e,ty1,DAE.T_ARRAY(dims = _::_::_),_)
      equation
         ty1 = unflattenArrayType(ty1);
         ty2 = unflattenArrayType(expected);
         (e, ty) = typeConvert(e, ty1, ty2, printFailtrace);
      then
        (e, ty);

    // Array expressions: expression dimension [dim1], expected dimension [dim2]
    case (DAE.ARRAY(array = elist),
          DAE.T_ARRAY(dims = {dim1},ty = ty1),
          ty0 as DAE.T_ARRAY(dims = {dim2},ty = ty2,source = ts),
          _)
      equation
        true = Expression.dimensionsKnownAndEqual(dim1, dim2);
        elist_1 = typeConvertArray(elist,ty1,ty2,printFailtrace);
        at = simplifyType(ty0);
        a = isArray(ty2);
        sc = boolNot(a);
      then
        (DAE.ARRAY(at,sc,elist_1),DAE.T_ARRAY(ty2, {dim1}, ts));

    // Array expressions: expression dimension [:], expected dimension [dim2]
    /* ARRAYS HAVE KNOWN DIMENSIONS. WHO WROTE THIS :(
    case (DAE.ARRAY(array = elist),
          (DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()},ty = ty1),_),
          ty0 as (DAE.T_ARRAY(dims = {dim2},ty = ty2),p2),
          printFailtrace)
      equation
        true = Expression.dimensionKnown(dim2);
        elist_1 = typeConvertArray(elist,ty1,ty2,printFailtrace);
        at = simplifyType(ty0);
        a = isArray(ty2);
        sc = boolNot(a);
      then
        (DAE.ARRAY(at,sc,elist_1),(DAE.T_ARRAY(DAE.DIM_UNKNOWN(),ty2),p2));
        */

    // Array expressions: expression dimension [dim1], expected dimension [:]
    case (DAE.ARRAY(array = elist),
          DAE.T_ARRAY(dims = {dim1},ty = ty1),
          DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()}, ty = ty2),
          _)
      equation
        true = Expression.dimensionKnown(dim1);
        elist_1 = typeConvertArray(elist,ty1,ty2,printFailtrace);
        dims = Expression.arrayDimension(simplifyType(ty1));
        a = isArray(ty2);
        sc = boolNot(a);
        dims = dim1 :: dims;
        ty2 = arrayElementType(ty2);
        ety1 = simplifyType(ty2);
        ty2 = liftArrayListDims(ty2, dims);
        //TODO: Verify correctness of return value.
      then
        (DAE.ARRAY(DAE.T_ARRAY(ety1, dims, DAE.emptyTypeSource),sc,elist_1), ty2);

    // Full range expressions, e.g. 1:2:10
    case (DAE.RANGE(start = begin,step = SOME(step),stop = stop),
          DAE.T_ARRAY(dims = {dim1},ty = ty1),
          DAE.T_ARRAY(dims = {dim2}, ty = ty2, source = ts),
          _)
      equation
        true = Expression.dimensionsKnownAndEqual(dim1, dim2);
        (begin_1,_) = typeConvert(begin, ty1, ty2, printFailtrace);
        (step_1,_) = typeConvert(step, ty1, ty2, printFailtrace);
        (stop_1,_) = typeConvert(stop, ty1, ty2, printFailtrace);
        at = simplifyType(ty2);
      then
        (DAE.RANGE(at,begin_1,SOME(step_1),stop_1),DAE.T_ARRAY(ty2,{dim1},ts));

    // Range expressions, e.g. 1:10
    case (DAE.RANGE(start = begin,step = NONE(),stop = stop),
          DAE.T_ARRAY(dims = {dim1}, ty = ty1),
          DAE.T_ARRAY(dims = {dim2}, ty = ty2, source = ts),
          _)
      equation
        true = Expression.dimensionsKnownAndEqual(dim1, dim2);
        (begin_1,_) = typeConvert(begin, ty1, ty2, printFailtrace);
        (stop_1,_) = typeConvert(stop, ty1, ty2, printFailtrace);
        at = simplifyType(ty2);
      then
        (DAE.RANGE(at,begin_1,NONE(),stop_1),DAE.T_ARRAY(ty2,{dim1},ts));

    // Matrix expressions: expression dimension [dim1,dim11], expected dimension [dim2,dim22]
    case (DAE.MATRIX(integer = nmax,matrix = ell),
          DAE.T_ARRAY(dims = {dim1},ty = DAE.T_ARRAY(dims = {dim11},ty = t1)),
          ty0 as DAE.T_ARRAY(dims = {dim2},ty = DAE.T_ARRAY(dims = {dim22},ty = t2,source = ts1), source = ts2),
          _)
      equation
        true = Expression.dimensionsKnownAndEqual(dim1, dim2);
        true = Expression.dimensionsKnownAndEqual(dim11, dim22);
        ell_1 = typeConvertMatrix(ell,t1,t2,printFailtrace);
        at = simplifyType(ty0);
      then
        (DAE.MATRIX(at,nmax,ell_1),DAE.T_ARRAY(DAE.T_ARRAY(t2,{dim11},ts1),{dim1},ts2));

    // Matrix expressions: expression dimension [dim1,dim11] expected dimension [:,dim22]
    case (DAE.MATRIX(integer = nmax,matrix = ell),
          DAE.T_ARRAY(dims = {dim1},ty = DAE.T_ARRAY(dims = {dim11},ty = t1)),
          DAE.T_ARRAY(dims = {dim2},ty = DAE.T_ARRAY(dims = {dim22},ty = t2, source = ts1), source = ts2),
          _)
          guard not Expression.dimensionKnown(dim2)
      equation
        true = Expression.dimensionsKnownAndEqual(dim11, dim22);
        ell_1 = typeConvertMatrix(ell,t1,t2,printFailtrace);
        ty = DAE.T_ARRAY(DAE.T_ARRAY(t2,{dim11},ts1),{dim1},ts2);
        at = simplifyType(ty);
      then
        (DAE.MATRIX(at,nmax,ell_1),ty);

    // Arbitrary expressions, expression dimension [dim1], expected dimension [dim2]
    case (e,
          DAE.T_ARRAY(dims = {dim1},ty = ty1),
          DAE.T_ARRAY(dims = {dim2},ty = ty2,source = ts2),
          _)
      equation
        true = Expression.dimensionsKnownAndEqual(dim1, dim2);
        (e_1,t_1) = typeConvert(e, ty1, ty2, printFailtrace);
        e_1 = liftExpType(e_1,dim1);
        t_2 = DAE.T_ARRAY(t_1,{dim2},ts2);
      then
        (e_1,t_2);

    // Arbitrary expressions,  expression dimension [:],  expected dimension [dim2]
    case (e,
          DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()},ty = ty1),
          DAE.T_ARRAY(dims = {_},ty = ty2,source = ts2),
          _)
      equation
        (e_1,t_1) = typeConvert(e, ty1, ty2, printFailtrace);
        e_1 = liftExpType(e_1,DAE.DIM_UNKNOWN());
      then
        (e_1,DAE.T_ARRAY(t_1,{DAE.DIM_UNKNOWN()},ts2));

    // Arbitrary expression, expression dimension [dim1] expected dimension [:]
    case (e,
          DAE.T_ARRAY(dims = {dim1},ty = ty1),
          DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()},ty = ty2, source = ts2),
          _)
      equation
        (e_1,t_1) = typeConvert(e, ty1, ty2, printFailtrace);
        e_1 = liftExpType(e_1,dim1);
      then
        (e_1,DAE.T_ARRAY(t_1,{dim1},ts2));

    // Arbitrary expressions, expression dimension [:] expected dimension [:]
    case (e,
          DAE.T_ARRAY(dims = {dim1},ty = ty1),
          DAE.T_ARRAY(dims = {dim2},ty = ty2,source = ts2),
          _)
      equation
        false = Expression.dimensionKnown(dim1);
        false = Expression.dimensionKnown(dim2);
        (e_1,t_1) = typeConvert(e, ty1, ty2, printFailtrace);
        e_1 = liftExpType(e_1,DAE.DIM_UNKNOWN());
      then
        (e_1,DAE.T_ARRAY(t_1,{DAE.DIM_UNKNOWN()},ts2));

    // Tuple
    case (DAE.TUPLE(PR = elist),
          DAE.T_TUPLE(types = tys1),
          DAE.T_TUPLE(types = tys2, source = ts2),
          _)
      equation
        (elist_1,tys_1) = typeConvertList(elist, tys1, tys2, printFailtrace);
      then
        (DAE.TUPLE(elist_1),DAE.T_TUPLE(tys_1,expected.names,ts2));

    // Implicit conversion from Integer literal to an enumeration
    // This is not a valid Modelica conversion, but was widely used in the past,
    // by, for instance, Modelica.Electrical.Digital.
    // Enable with +intEnumConversion.
    case (exp as DAE.ICONST(oi),
          DAE.T_INTEGER(),
          t2 as DAE.T_ENUMERATION(path = tp, names = l),
          _)
       equation
        true = Config.intEnumConversion();
        // It would be good to have the source location of exp here, so that we could pass it to typeConvertIntToEnumCheck.
        true = typeConvertIntToEnumCheck(exp, t2); // Will warn or report error depending on whether oi is out of range.
        // select from enum list:
        name = listGet(l, oi);
        tp = Absyn.joinPaths(tp, Absyn.IDENT(name));
      then
        (DAE.ENUM_LITERAL(tp, oi),expected);

    // Implicit conversion from Integer to Real
    case (e,
          DAE.T_INTEGER(),
          DAE.T_REAL(),
          _)
      then
        (DAE.CAST(DAE.T_REAL_DEFAULT,e),expected);

    // Complex type inheriting primitive type
    case (e, DAE.T_SUBTYPE_BASIC(complexType = t1),t2,_) equation
      (e_1,t_1) = typeConvert(e,t1,t2,printFailtrace);
    then (e_1,t_1);
    case (e, t1,DAE.T_SUBTYPE_BASIC(complexType = t2),_) equation
      (e_1,t_1) = typeConvert(e,t1,t2,printFailtrace);
    then (e_1,t_1);

    // Complex types (records) that need a cast
    case (e, DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(p1),varLst = els1), t2 as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(p2),varLst = els2),_)
      equation
        false = Absyn.pathEqual(p1,p2) "We need to add a cast from one record to another";
        true = Flags.isSet(Flags.ALLOW_RECORD_TOO_MANY_FIELDS) or (listLength(els1) == listLength(els2));
        true = subtypeVarlist(els1, els2);
        e = DAE.CAST(t2, e);
      then (e, t2);

    // MetaModelica Option
    case (DAE.META_OPTION(SOME(e)),DAE.T_METAOPTION(ty = t1),DAE.T_METAOPTION(t2,ts2),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (e_1, t_1) = matchType(e,t1,t2,printFailtrace);
      then
        (DAE.META_OPTION(SOME(e_1)),DAE.T_METAOPTION(t_1,ts2));

    case (DAE.META_OPTION(NONE()),_,DAE.T_METAOPTION(t2,ts2),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
      then
        (DAE.META_OPTION(NONE()),DAE.T_METAOPTION(t2,ts2));

    // MetaModelica Tuple
    case (DAE.TUPLE(elist),DAE.T_TUPLE(types = tys1),DAE.T_METATUPLE(tys2,ts2),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        tys2 = List.map(tys2, boxIfUnboxedType);
        (elist_1,tys_1) = matchTypeTuple(elist, tys1, tys2, printFailtrace);
      then
        (DAE.META_TUPLE(elist_1),DAE.T_METATUPLE(tys_1,ts2));

    case (DAE.MATCHEXPRESSION(matchTy,inputs,aliases,localDecls,cases,et),_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        elist = Patternm.resultExps(cases);
        (elist_1,_) = matchTypeList(elist, actual, expected, printFailtrace);
        cases=Patternm.fixCaseReturnTypes2(cases,elist_1,Absyn.dummyInfo);
        et=simplifyType(expected);
      then
        (DAE.MATCHEXPRESSION(matchTy,inputs,aliases,localDecls,cases,et),expected);

    case (DAE.META_TUPLE(elist),DAE.T_METATUPLE(types = tys1),DAE.T_METATUPLE(tys2,ts2),_)
      equation
        tys2 = List.map(tys2, boxIfUnboxedType);
        (elist_1,tys_1) = matchTypeTuple(elist, tys1, tys2, printFailtrace);
      then
        (DAE.META_TUPLE(elist_1),DAE.T_METATUPLE(tys_1,ts2));

    case (DAE.TUPLE(elist),DAE.T_TUPLE(types = tys1),ty2 as DAE.T_METABOXED(ty = DAE.T_UNKNOWN(), source = ts2),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        tys2 = List.fill(ty2, listLength(tys1));
        (elist_1,tys_1) = matchTypeTuple(elist, tys1, tys2, printFailtrace);
       then
        (DAE.META_TUPLE(elist_1),DAE.T_METATUPLE(tys_1,ts2));

    // The automatic type conversion will convert any array that can be
    // const-eval'ed to an DAE.ARRAY or DAE.MATRIX into a list of the same
    // type. The reason is that the syntax for the array and list constructor
    // is the same. However, the compiler can't distinguish between the two
    // cases below because a is expanded earlier in the compilation process:
    //   Integer[3] a;
    //   someListFunction(a); // Is expanded to the line below
    //   someListFunction({a[1],a[2],a[3]});
    //   / sjoelund 2009-08-13
    case (DAE.ARRAY(DAE.T_ARRAY(),_,elist),
          DAE.T_ARRAY(ty=t1),
          DAE.T_METALIST(t2,_),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        t2 = boxIfUnboxedType(t2);
        (elist_1, _) = matchTypeList(elist, t1, t2, printFailtrace);
        e_1 = DAE.LIST(elist_1);
        t2 = DAE.T_METALIST(t2,DAE.emptyTypeSource);
      then (e_1, t2);

    case (DAE.ARRAY(DAE.T_ARRAY(),_,elist),
          DAE.T_ARRAY(ty=t1),
          DAE.T_METABOXED(t2,_),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (elist_1, tys1) = matchTypeList(elist, t1, t2, printFailtrace);
        (elist_1, t2) = listMatchSuperType(elist_1, tys1, printFailtrace);
        t2 = boxIfUnboxedType(t2);
        (elist_1, _) = matchTypeList(elist_1, t1, t2, printFailtrace);
        e_1 = DAE.LIST(elist_1);
        t2 = DAE.T_METALIST(t2,DAE.emptyTypeSource);
      then (e_1, t2);

    case (DAE.MATRIX(DAE.T_ARRAY(),_,elist_big),t1,t2,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (elist,ty2) = typeConvertMatrixToList(elist_big,t1,t2,printFailtrace);
        e_1 = DAE.LIST(elist);
      then (e_1,ty2);

    case (DAE.LIST(elist),DAE.T_METALIST(ty = t1),DAE.T_METALIST(t2,_),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (elist_1, tys1) = matchTypeList(elist, t1, t2, printFailtrace);
        (elist_1, t2) = listMatchSuperType(elist_1, tys1, printFailtrace);
        e_1 = DAE.LIST(elist_1);
        t2 = DAE.T_METALIST(t2,DAE.emptyTypeSource);
      then (e_1, t2);

    case (e, t1 as DAE.T_INTEGER(), DAE.T_METABOXED(ty = t2),_)
      equation
        (e,t1) = matchType(e,t1,unboxedType(t2),printFailtrace);
        t2 = DAE.T_METABOXED(t1,DAE.emptyTypeSource);
        e = Expression.boxExp(e);
      then (e,t2);

    case (e, t1 as DAE.T_BOOL(), DAE.T_METABOXED(ty = t2),_)
      equation
        (e,t1) = matchType(e,t1,unboxedType(t2),printFailtrace);
        t2 = DAE.T_METABOXED(t1,DAE.emptyTypeSource);
        e = Expression.boxExp(e);
      then (e,t2);

    case (e, t1 as DAE.T_REAL(), DAE.T_METABOXED(ty = t2),_)
      equation
        (e,t1) = matchType(e,t1,unboxedType(t2),printFailtrace);
        t2 = DAE.T_METABOXED(t1,DAE.emptyTypeSource);
        e = Expression.boxExp(e);
      then (e,t2);

    case (e, t1 as DAE.T_ENUMERATION(), DAE.T_METABOXED(ty = t2), _)
      equation
        (e, t1) = matchType(e, t1, unboxedType(t2), printFailtrace);
        t2 = DAE.T_METABOXED(t1, DAE.emptyTypeSource);
        e = Expression.boxExp(e);
      then
        (e, t2);

    case (e, t1 as DAE.T_ARRAY(), DAE.T_METABOXED(ty = t2), _)
      equation
        // true = Config.acceptMetaModelicaGrammar();
        (e, t1) = matchType(e, t1, unboxedType(t2), printFailtrace);
        t2 = DAE.T_METABOXED(t1,DAE.emptyTypeSource);
        e = Expression.boxExp(e);
      then
        (e, t2);

    case (DAE.CALL(path = path1, expLst = elist),
          t1 as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), varLst = v, source = {path2}),
          DAE.T_METABOXED(ty = t2),
          _)
      equation
        true = subtype(t1,t2);
        true = Absyn.pathEqual(path1, path2);
        t2 = DAE.T_METABOXED(t1,DAE.emptyTypeSource);
        l = List.map(v, getVarName);
        tys1 = List.map(v, getVarType);
        tys2 = List.map(tys1, boxIfUnboxedType);
        (elist,_) = matchTypeTuple(elist, tys1, tys2, printFailtrace);
        e_1 = DAE.METARECORDCALL(path1, elist, l, -1, {});
      then (e_1,t2);

    case (DAE.RECORD(path = path1, exps = elist),
          t1 as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), varLst = v, source = {path2}),
          DAE.T_METABOXED(ty = t2),
          _)
      equation
        true = subtype(t1,t2);
        true = Absyn.pathEqual(path1, path2);
        t2 = DAE.T_METABOXED(t1,DAE.emptyTypeSource);
        l = List.map(v, getVarName);
        tys1 = List.map(v, getVarType);
        tys2 = List.map(tys1, boxIfUnboxedType);
        (elist,_) = matchTypeTuple(elist, tys1, tys2, printFailtrace);
        e_1 = DAE.METARECORDCALL(path1, elist, l, -1, {});
      then (e_1,t2);

    case (DAE.CREF(cref,_),
          t1 as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), varLst = v, source = {path}),
          DAE.T_METABOXED(ty = t2),_)
      equation
        true = subtype(t1,t2);
        t2 = DAE.T_METABOXED(t1,DAE.emptyTypeSource);
        l = List.map(v, getVarName);
        tys1 = List.map(v, getVarType);
        tys2 = List.map(tys1, boxIfUnboxedType);
        expTypes = List.map(tys1, simplifyType);
        pathList = List.map(l, Absyn.makeIdentPathFromString);
        crefList = List.map(pathList, ComponentReference.pathToCref);
        crefList = List.map1r(crefList, ComponentReference.joinCrefs, cref);
        elist = List.threadMap(crefList, expTypes, Expression.makeCrefExp);
        (elist,_) = matchTypeTuple(elist, tys1, tys2, printFailtrace);
        e_1 = DAE.METARECORDCALL(path, elist, l, -1, {});
      then (e_1,t2);

    case (e,
          DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),
          DAE.T_METABOXED(),_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Not yet implemented: Converting record into boxed records: "+ExpressionDump.printExpStr(e)+"\n");
      then
        fail();

    case (DAE.BOX(e),DAE.T_METABOXED(ty = t1),t2,_)
      equation
        true = subtype(t1,t2);
        (e_1,t2) = matchType(e,t1,t2,printFailtrace);
      then (e_1,t2);

    case (e,DAE.T_METABOXED(ty = t1),t2 as DAE.T_INTEGER(),_)
      equation
        true = subtype(t1,t2);
        (_,_) = matchType(e,t1,t2,printFailtrace);
        t = simplifyType(t2);
      then (DAE.UNBOX(e,t),t2);

    case (e,DAE.T_METABOXED(ty = t1),t2 as DAE.T_REAL(),_)
      equation
        true = subtype(t1,t2);
        (_,_) = matchType(e,t1,t2,printFailtrace);
        t = simplifyType(t2);
      then (DAE.UNBOX(e,t),t2);

    case (e,DAE.T_METABOXED(ty = t1),t2 as DAE.T_BOOL(),_)
      equation
        true = subtype(t1,t2);
        (_,_) = matchType(e,t1,t2,printFailtrace);
        t = simplifyType(t2);
      then (DAE.UNBOX(e,t),t2);

    case (e, DAE.T_METABOXED(ty = t1), t2 as DAE.T_ENUMERATION(), _)
      equation
        true = subtype(t1, t2);
        matchType(e, t1, t2, printFailtrace);
        t = simplifyType(t2);
      then
        (DAE.UNBOX(e, t), t2);

    case (e,DAE.T_METABOXED(ty = t1),t2 as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),_)
      equation
        true = subtype(t1,t2);
        (e_1,_) = matchType(e,t1,t2,printFailtrace);
        t = simplifyType(t2);
      then
        (DAE.CALL(Absyn.IDENT("mmc_unbox_record"),{e_1},DAE.CALL_ATTR(t,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL())),t2);

  end matchcontinue;
end typeConvert;

protected function liftExpType "help funciton to typeConvert. Changes the DAE.Type stored
in expression (which is typically a CAST) by adding a dimension to it, making it into an array
type."
 input DAE.Exp ie;
 input DAE.Dimension dim;
 output DAE.Exp res;
algorithm
  res := matchcontinue(ie,dim)
    local DAE.Type ty,ty1; DAE.Exp e;
    case(DAE.CAST(ty,e),_)
      equation
        ty1 = Expression.liftArrayR(ty,dim);
      then DAE.CAST(ty1,e);

    case(e,_) then e;
  end matchcontinue;
end liftExpType;

public function typeConvertArray
  "Calls typeConvert on a list of expressions."
  input list<DAE.Exp> inArray;
  input DAE.Type inActualType;
  input DAE.Type inExpectedType;
  input Boolean inPrintFailtrace;
  output list<DAE.Exp> outArray;
algorithm
  outArray := match(inArray, inActualType, inExpectedType, inPrintFailtrace)
    local
      DAE.Exp e;
      list<DAE.Exp> expl;

    // Empty array. Create a dummy expression and try to type convert that, to
    // make sure that empty arrays are type checked.
    case ({}, _, _, _)
      equation
        e = makeDummyExpFromType(inActualType);
        (_, _) = typeConvert(e, inActualType, inExpectedType, inPrintFailtrace);
      then
        {};

    else
      equation
        (expl, _) = List.map3_2(inArray, typeConvert, inActualType,
          inExpectedType, inPrintFailtrace);
      then
        expl;

  end match;
end typeConvertArray;

protected function typeConvertMatrix "
  Helper function to type_convert. Handles matrix expressions.
"
  input list<list<DAE.Exp>> inMatrix;
  input DAE.Type inActualType;
  input DAE.Type inExpectedType;
  input Boolean printFailtrace;
  output list<list<DAE.Exp>> outMatrix;
algorithm
  outMatrix := List.map3(inMatrix, typeConvertArray, inActualType,
    inExpectedType, printFailtrace);
end typeConvertMatrix;

protected function typeConvertList "
  Helper function to type_convert.
"
  input list<DAE.Exp> inExpExpLst1;
  input list<DAE.Type> inTypeLst2;
  input list<DAE.Type> inTypeLst3;
  input Boolean printFailtrace;
  output list<DAE.Exp> outExpExpLst;
  output list<DAE.Type> outTypeLst;
algorithm
  (outExpExpLst,outTypeLst):=
  match (inExpExpLst1,inTypeLst2,inTypeLst3,printFailtrace)
    local
      list<DAE.Exp> rest_1,rest;
      list<DAE.Type> tyrest_1,ty1rest,ty2rest;
      DAE.Exp first_1,first;
      Type ty_1,ty1,ty2;
    case ({},_,_,_) then ({},{});
    case ((first :: rest),(ty1 :: ty1rest),(ty2 :: ty2rest),_)
      equation
        (rest_1,tyrest_1) = typeConvertList(rest, ty1rest, ty2rest,printFailtrace);
        (first_1,ty_1) = typeConvert(first, ty1, ty2, printFailtrace);
      then
        ((first_1 :: rest_1),(ty_1 :: tyrest_1));
  end match;
end typeConvertList;

protected function typeConvertMatrixToList
  input list<list<DAE.Exp>> melist;
  input DAE.Type inType;
  input DAE.Type outType;
  input Boolean printFailtrace;
  output list<DAE.Exp> outExp;
  output DAE.Type actualOutType;
algorithm
  (outExp,actualOutType) := matchcontinue (melist,inType,outType,printFailtrace)
    local
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> rest;
      DAE.Type t;
      Type t1,t2;
      DAE.TypeSource ts2;
      DAE.Exp e;

    case ({},_,_,_) then ({},DAE.T_UNKNOWN_DEFAULT);
    case (expl::rest, DAE.T_ARRAY(ty=DAE.T_ARRAY(ty=t1)), DAE.T_METALIST(DAE.T_METALIST(ty=t2),_),_)
      equation
        (e,t1) = typeConvertMatrixRowToList(expl, t1, t2, printFailtrace);
        (expl,_) = typeConvertMatrixToList(rest, inType, outType, printFailtrace);
      then (e::expl,DAE.T_METALIST(t1,DAE.emptyTypeSource));
    else
      equation
        true = Flags.isSet(Flags.TYPES);
        Debug.trace("- typeConvertMatrixToList failed\n");
      then fail();
  end matchcontinue;
end typeConvertMatrixToList;

protected function typeConvertMatrixRowToList
  input list<DAE.Exp> elist;
  input DAE.Type inType;
  input DAE.Type outType;
  input Boolean printFailtrace;
  output DAE.Exp out;
  output DAE.Type t1;
protected
  DAE.Exp exp;
  list<DAE.Exp> elist_1;
  DAE.Type t;
algorithm
  (elist_1,t1::_) := matchTypeList(elist, inType, outType, printFailtrace);
  out := DAE.LIST(elist_1);
  t1 := DAE.T_METALIST(t1,DAE.emptyTypeSource);
end typeConvertMatrixRowToList;

public function matchWithPromote "This function is used for matching expressions in matrix construction,
  where automatic promotion is allowed. This means that array dimensions of
  size one (1) is added from the right to arrays of matrix construction until
  all elements have the same dimension size (with a maximum of 2).
  For instance, {1,{2}} becomes {1,2}.
  The function also has a flag indicating that Integer to Real
  conversion can be used."
  input DAE.Properties inProperties1;
  input DAE.Properties inProperties2;
  input Boolean inBoolean3;
  output DAE.Properties outProperties;
algorithm
  outProperties := matchcontinue (inProperties1,inProperties2,inBoolean3)
    local
      Type t,t1,t2;
      Const c,c1,c2;
      DAE.Dimension dim,dim1,dim2;
      Boolean havereal;
      list<DAE.Var> v;
      Type tt;
      DAE.TypeSource  ts2, ts;

    case (DAE.PROP(DAE.T_SUBTYPE_BASIC(complexType = t1),c1),DAE.PROP(t2,c2),havereal)
      then matchWithPromote(DAE.PROP(t1,c1),DAE.PROP(t2,c2),havereal);

    case (DAE.PROP(t1,c1),DAE.PROP(DAE.T_SUBTYPE_BASIC(complexType = t2),c2),havereal)
      then matchWithPromote(DAE.PROP(t1,c1),DAE.PROP(t2,c2),havereal);

    case (DAE.PROP(type_ = DAE.T_ARRAY(dims = {dim1},ty = t1),constFlag = c1),
          DAE.PROP(type_ = DAE.T_ARRAY(dims = {_},ty = t2, source = ts2),constFlag = c2),
          havereal) // Allow Integer => Real
      equation
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
        dim = dim1;
      then
        DAE.PROP(DAE.T_ARRAY(t,{dim},ts2),c);

    // match integer, second
    case (DAE.PROP(type_ = t1,constFlag = c1),
          DAE.PROP(type_ = DAE.T_ARRAY(dims = {DAE.DIM_INTEGER(1)},ty = t2, source = ts2),constFlag = c2),
          havereal)
      equation
        false = isArray(t1);
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP(DAE.T_ARRAY(t, {DAE.DIM_INTEGER(1)},ts2),c);
    // match enum, second
    case (DAE.PROP(type_ = t1,constFlag = c1),
          DAE.PROP(type_ = DAE.T_ARRAY(dims = {dim as DAE.DIM_ENUM(size=1)},ty = t2, source = ts2),constFlag = c2),
          havereal)
      equation
        false = isArray(t1);
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP(DAE.T_ARRAY(t,{dim},ts2),c);
    // match boolean, second
    case (DAE.PROP(type_ = t1,constFlag = c1),
          DAE.PROP(type_ = DAE.T_ARRAY(dims = {dim as DAE.DIM_BOOLEAN()},ty = t2, source = ts2),constFlag = c2),
          havereal)
      equation
        false = isArray(t1);
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP(DAE.T_ARRAY(t,{dim},ts2),c);
    // match integer, first
    case (DAE.PROP(type_ = DAE.T_ARRAY(dims = {DAE.DIM_INTEGER(1)},ty = t1, source = ts),constFlag = c1),
          DAE.PROP(type_ = t2,constFlag = c2),havereal)
      equation
        false = isArray(t2);
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP(DAE.T_ARRAY(t,{DAE.DIM_INTEGER(1)},ts),c);
    // match enum, first
    case (DAE.PROP(type_ = DAE.T_ARRAY(dims = {dim as DAE.DIM_ENUM(size=1)},ty = t1, source = ts),constFlag = c1),
          DAE.PROP(type_ = t2,constFlag = c2),havereal)
      equation
        false = isArray(t2);
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP(DAE.T_ARRAY(t,{dim},ts),c);
    // match boolean, first
    case (DAE.PROP(type_ = DAE.T_ARRAY(dims = {dim as DAE.DIM_BOOLEAN()},ty = t1, source = ts),constFlag = c1),
          DAE.PROP(type_ = t2,constFlag = c2),havereal)
      equation
        false = isArray(t2);
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP(DAE.T_ARRAY(t,{dim},ts),c);
    // equal types
    case (DAE.PROP(type_ = t1,constFlag = c1),
          DAE.PROP(type_ = t2,constFlag = c2),false)
      equation
        false = isArray(t1);
        false = isArray(t2);
        true = equivtypes(t1,t2);
        c = constAnd(c1, c2);
      then
        DAE.PROP(t1,c);
    // enums
    case (DAE.PROP(type_ = t as DAE.T_ENUMERATION(),constFlag = c1),
          DAE.PROP(type_ = DAE.T_ENUMERATION(source = ts2),constFlag = c2), false)
      equation
        c = constAnd(c1, c2) "Have enum and both Enum" ;
        tt = setTypeSource(t,ts2);
      then
        DAE.PROP(tt,c);
    // reals
    case (DAE.PROP(type_ = DAE.T_REAL(varLst = v),constFlag = c1),
          DAE.PROP(type_ = DAE.T_REAL(source = ts2),constFlag = c2),true)
      equation
        c = constAnd(c1, c2) "Have real and both Real" ;
      then
        DAE.PROP(DAE.T_REAL(v,ts2),c);
    // integer vs. real
    case (DAE.PROP(type_ = DAE.T_INTEGER(),constFlag = c1),
          DAE.PROP(type_ = DAE.T_REAL(varLst = v, source = ts2),constFlag = c2),true)
      equation
        c = constAnd(c1, c2) "Have real and first Integer" ;
      then
        DAE.PROP(DAE.T_REAL(v,ts2),c);
    // real vs. integer
    case (DAE.PROP(type_ = DAE.T_REAL(varLst = v),constFlag = c1),
          DAE.PROP(type_ = DAE.T_INTEGER(source = ts2),constFlag = c2),true)
      equation
        c = constAnd(c1, c2) "Have real and second Integer" ;
      then
        DAE.PROP(DAE.T_REAL(v,ts2),c);
    // both integers
    case (DAE.PROP(type_ = DAE.T_INTEGER(),constFlag = c1),
          DAE.PROP(type_ = DAE.T_INTEGER(),constFlag = c2),true)
      equation
        c = constAnd(c1, c2) "Have real and both Integer" ;
      then
        DAE.PROP(DAE.T_REAL_DEFAULT,c);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Types.matchWithPromote failed on: " +
           "\nprop1: " + printPropStr(inProperties1) +
           "\nprop2: " + printPropStr(inProperties2) +
           "\nhaveReal: " + boolString(inBoolean3));
      then fail();
  end matchcontinue;
end matchWithPromote;

public function constAnd "Returns the *and* operator of two Consts.
  I.e. C_CONST iff. both are C_CONST,
       C_PARAM iff both are C_PARAM (or one of them C_CONST),
       V_VAR otherwise."
  input DAE.Const inConst1;
  input DAE.Const inConst2;
  output DAE.Const outConst;
algorithm
  outConst := match(inConst1,inConst2)
    case (DAE.C_CONST(),DAE.C_CONST()) then DAE.C_CONST();
    case (DAE.C_CONST(),DAE.C_PARAM()) then DAE.C_PARAM();
    case (DAE.C_PARAM(),DAE.C_CONST()) then DAE.C_PARAM();
    case (DAE.C_PARAM(),DAE.C_PARAM()) then DAE.C_PARAM();
    case (DAE.C_UNKNOWN(), _) then DAE.C_UNKNOWN();
    case (_, DAE.C_UNKNOWN()) then DAE.C_UNKNOWN();
    else DAE.C_VAR();
  end match;
end constAnd;

protected function constTupleAnd "Returns the *and* operator of two TupleConsts
  For now, returns first tuple."
  input DAE.TupleConst inTupleConst1;
  input DAE.TupleConst inTupleConst2;
  output DAE.TupleConst outTupleConst;
algorithm
  outTupleConst := match (inTupleConst1,inTupleConst2)
    local TupleConst c1,c2;
    case (c1,_) then c1;
  end match;
end constTupleAnd;

public function constOr "Returns the *or* operator of two Const's.
  I.e. C_CONST if some is C_CONST,
       C_PARAM if none is C_CONST but some is C_PARAM and
       V_VAR otherwise."
  input DAE.Const inConst1;
  input DAE.Const inConst2;
  output DAE.Const outConst;
algorithm
  outConst := match (inConst1,inConst2)
    case (DAE.C_CONST(),_) then DAE.C_CONST();
    case (_,DAE.C_CONST()) then DAE.C_CONST();
    case (DAE.C_PARAM(),_) then DAE.C_PARAM();
    case (_,DAE.C_PARAM()) then DAE.C_PARAM();
    case (DAE.C_UNKNOWN(),_) then DAE.C_UNKNOWN();
    case (_, DAE.C_UNKNOWN()) then DAE.C_UNKNOWN();
    else DAE.C_VAR();
  end match;
end constOr;

public function boolConst "author: PA
  Creates a Const value from a bool.
  if true, C_CONST,
  if false C_VAR
  There is no way to create a C_PARAM using this function."
  input Boolean inBoolean;
  output DAE.Const outConst;
algorithm
  outConst := match (inBoolean)
    case (false) then DAE.C_VAR();
    case (true) then DAE.C_CONST();
  end match;
end boolConst;

public function boolConstSize "author: alleb
  A version of boolConst supposed to be used by Static.elabBuiltinSize.
  Creates a Const value from a bool. If true, C_CONST, if false C_PARAM."
  input Boolean inBoolean;
  output DAE.Const outConst;
algorithm
  outConst := match (inBoolean)
    case (false) then DAE.C_PARAM();
    case (true) then DAE.C_CONST();
  end match;
end boolConstSize;

public function constEqualOrHigher
  input DAE.Const c1;
  input DAE.Const c2;
  output Boolean b;
algorithm
  b := match (c1, c2)
    case (DAE.C_CONST(), _) then true;
    case (_, DAE.C_CONST()) then false;
    case (DAE.C_PARAM(), _) then true;
    case (_, DAE.C_PARAM()) then false;
    else true;
  end match;
end constEqualOrHigher;

public function constEqual
  input DAE.Const c1;
  input DAE.Const c2;
  output Boolean b;
algorithm
  b := matchcontinue(c1, c2)
    case (_, _)
      equation
        equality(c1 = c2);
      then true;
    else false;
  end matchcontinue;
end constEqual;

public function constIsVariable
  "Returns true if Const is C_VAR."
  input DAE.Const c;
  output Boolean b;
algorithm
  b := constEqual(c, DAE.C_VAR());
end constIsVariable;

public function constIsParameter
  "Returns true if Const is C_PARAM."
  input DAE.Const c;
  output Boolean b;
algorithm
  b := constEqual(c, DAE.C_PARAM());
end constIsParameter;

public function constIsConst
  "Returns true if Const is C_CONST."
  input DAE.Const c;
  output Boolean b;
algorithm
  b := constEqual(c, DAE.C_CONST());
end constIsConst;

public function printPropStr "Print the properties to a string."
  input DAE.Properties inProperties;
  output String outString;
algorithm
  outString := match (inProperties)
    local
      String ty_str,const_str,res;
      DAE.Type ty;
      DAE.Const const;
      DAE.TupleConst tconst;
    case DAE.PROP(type_ = ty,constFlag = const)
      equation
        ty_str = unparseType(ty);
        const_str = printConstStr(const);
        res = stringAppendList({"DAE.PROP(",ty_str,", ",const_str,")"});
      then
        res;
    case DAE.PROP_TUPLE(type_ = ty,tupleConst = tconst)
      equation
        ty_str = unparseType(ty);
        const_str = printTupleConstStr(tconst);
        res = stringAppendList({"DAE.PROP_TUPLE(",ty_str,", ",const_str,")"});
      then
        res;
  end match;
end printPropStr;

public function printProp "Print the Properties to the Print buffer."
  input DAE.Properties p;
protected
  String str;
algorithm
  str := printPropStr(p);
  Print.printErrorBuf(str);
end printProp;

public function flowVariables "This function retrieves all variables names that are flow variables, and
  prepends the prefix given as an DAE.ComponentRef"
  input list<DAE.Var> inVarLst;
  input DAE.ComponentRef inComponentRef;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst:=
  matchcontinue (inVarLst,inComponentRef)
    local
      DAE.ComponentRef cr_1,cr;
      list<DAE.ComponentRef> res;
      String id;
      list<DAE.Var> vs;
      DAE.Type ty2,ty;
      DAE.ComponentRef cref_;

    // handle empty case
    case ({},_) then {};

    // we have a flow prefix
    case ((DAE.TYPES_VAR(name = id,attributes = DAE.ATTR(connectorType = SCode.FLOW()),ty = ty) :: vs),cr)
      equation
        ty2 = simplifyType(ty);
        cr_1 = ComponentReference.crefPrependIdent(cr, id,{},ty2);
        // print("\n created: " + ComponentReference.debugPrintComponentRefTypeStr(cr_1) + "\n");
        res = flowVariables(vs, cr);
      then
        (cr_1 :: res);

    // handle the rest
    case ((_ :: vs),cr)
      equation
        res = flowVariables(vs, cr);
      then
        res;
  end matchcontinue;
end flowVariables;

public function streamVariables "This function retrieves all variables names that are stream variables,
  and prepends the prefix given as an DAE.ComponentRef"
  input list<DAE.Var> inVarLst;
  input DAE.ComponentRef inComponentRef;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst:=
  matchcontinue (inVarLst,inComponentRef)
    local
      DAE.ComponentRef cr_1,cr;
      list<DAE.ComponentRef> res;
      String id;
      list<DAE.Var> vs;
      DAE.Type ty2,ty;
      DAE.ComponentRef cref_;

    case ({},_) then {};
    case ((DAE.TYPES_VAR(name = id,attributes = DAE.ATTR(connectorType = SCode.STREAM()),ty = ty) :: vs),cr)
      equation
        ty2 = simplifyType(ty);
        cr_1 = ComponentReference.crefPrependIdent(cr, id, {}, ty2);
        res = streamVariables(vs, cr);
      then
        (cr_1 :: res);
    case ((_ :: vs),cr)
      equation
        res = streamVariables(vs, cr);
      then
        res;
  end matchcontinue;
end streamVariables;

public function getAllExps "This function goes through the Type structure and finds all the
  expressions and returns them in a list"
  input DAE.Type inType;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := getAllExpsTt(inType);
end getAllExps;

protected function getAllExpsTt "This function goes through the TType structure and finds all the
  expressions and returns them in a list"
  input DAE.Type inType;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := matchcontinue (inType)
    local
      list<DAE.Exp> exps,tyexps;
      list<DAE.Var> vars, attrs;
      list<String> strs;
      DAE.Dimension dim;
      Type ty;
      ClassInf.State cinf;
      Option<DAE.Type> bc;
      list<DAE.Type> tys;
      list<list<DAE.Exp>> explists,explist;
      list<DAE.FuncArg> fargs;
      Type tty;
      String str;

    case DAE.T_INTEGER(varLst = vars) then getAllExpsVars(vars);
    case DAE.T_REAL(varLst = vars)    then getAllExpsVars(vars);
    case DAE.T_STRING(varLst = vars)  then getAllExpsVars(vars);
    case DAE.T_BOOL(varLst = vars)    then getAllExpsVars(vars);
    // BTH return empty list for clock since it doesn't have attributes
    case DAE.T_CLOCK() then {};
    case DAE.T_ENUMERATION(literalVarLst = vars, attributeLst = attrs)
      equation
        exps = getAllExpsVars(vars);
        tyexps = getAllExpsVars(attrs);
        exps = listAppend(tyexps, exps);
      then
        exps;
    case DAE.T_ARRAY(ty = ty) then getAllExps(ty);

    case DAE.T_COMPLEX(varLst = vars) then getAllExpsVars(vars);
    case DAE.T_SUBTYPE_BASIC(varLst = vars) then getAllExpsVars(vars);

    case DAE.T_FUNCTION(funcArg = fargs,funcResultType = ty)
      equation
        explists = List.mapMap(fargs, funcArgType, getAllExps);
        tyexps = getAllExps(ty);
        exps = List.flatten((tyexps :: explists));
      then
        exps;

    case DAE.T_TUPLE(types = tys)
      equation
        explist = List.map(tys, getAllExps);
        exps = List.flatten(explist);
      then
        exps;

    case DAE.T_METATUPLE(types = tys)
      equation
        exps = getAllExpsTt(DAE.T_TUPLE(tys, NONE(), DAE.emptyTypeSource));
      then
        exps;

    case DAE.T_METAUNIONTYPE() then {};

    case DAE.T_METAOPTION(ty = ty) then getAllExps(ty);
    case DAE.T_METALIST(ty = ty)     then getAllExps(ty);
    case DAE.T_METAARRAY(ty = ty)          then getAllExps(ty);
    case DAE.T_METABOXED(ty = ty)          then getAllExps(ty);
    case DAE.T_METAPOLYMORPHIC() then {};

    case(DAE.T_UNKNOWN()) then {};
    case(DAE.T_NORETCALL()) then {};

    case tty
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str = unparseType(tty);
        Debug.traceln("-- Types.getAllExpsTt failed " + str);
      then
        fail();
  end matchcontinue;
end getAllExpsTt;

protected function getAllExpsVars "Helper function to getAllExpsTt."
  input list<DAE.Var> vars;
  output list<DAE.Exp> exps;
protected
  list<list<DAE.Exp>> explist;
algorithm
  explist := List.map(vars, getAllExpsVar);
  exps := List.flatten(explist);
end getAllExpsVars;

protected function getAllExpsVar "Helper function to getAllExpsVars."
  input DAE.Var inVar;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := match (inVar)
    local
      list<DAE.Exp> tyexps,bndexp,exps;
      String id;
      DAE.Type ty;
      DAE.Binding bnd;

    case DAE.TYPES_VAR(ty = ty,binding = bnd)
      equation
        tyexps = getAllExps(ty);
        bndexp = getAllExpsBinding(bnd);
        exps = listAppend(tyexps, bndexp);
      then
        exps;
  end match;
end getAllExpsVar;

protected function getAllExpsBinding "Helper function to get_all_exps_var."
  input DAE.Binding inBinding;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := match(inBinding)
    local
      DAE.Exp exp;
      Const cnst;
      Values.Value v;
    case DAE.EQBOUND(exp = exp) then {exp};
    case DAE.UNBOUND() then {};
    case DAE.VALBOUND() then {};
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("-- Types.getAllExpsBinding failed\n");
      then
        fail();
  end match;
end getAllExpsBinding;

public function isBoxedType
  input DAE.Type ty;
  output Boolean b;
algorithm
  b := match ty
    case DAE.T_STRING() then true;
    case DAE.T_METAOPTION() then true;
    case DAE.T_METALIST() then true;
    case DAE.T_METATUPLE() then true;
    case DAE.T_METAUNIONTYPE() then true;
    case DAE.T_METARECORD() then true;
    case DAE.T_METAPOLYMORPHIC() then true;
    case DAE.T_METAARRAY() then true;
    case DAE.T_FUNCTION() then true;
    case DAE.T_METABOXED() then true;
    case DAE.T_ANYTYPE() then true;
    case DAE.T_UNKNOWN() then true;
    case DAE.T_METATYPE() then true;
    case DAE.T_NORETCALL() then true;
    case DAE.T_CODE() then true;
    case DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ()) then true;
    else false;
  end match;
end isBoxedType;

public function isMetaBoxedType
  input DAE.Type inType;
  output Boolean outIsMetaBoxed;
algorithm
  outIsMetaBoxed := match inType
    case DAE.T_METABOXED() then true;
    else false;
  end match;
end isMetaBoxedType;

public function boxIfUnboxedType
  input DAE.Type ty;
  output DAE.Type outType;
algorithm
  outType := matchcontinue ty
    local
      list<DAE.Type> tys;

    case DAE.T_TUPLE()
      equation
        tys = List.map(ty.types, boxIfUnboxedType);
      then DAE.T_METATUPLE(tys,DAE.emptyTypeSource); // TODO?! should now propagate the type source?

    else if isBoxedType(ty) then ty else DAE.T_METABOXED(ty,DAE.emptyTypeSource);

  end matchcontinue;
end boxIfUnboxedType;

public function unboxedType
  input DAE.Type ity;
  output DAE.Type out;
algorithm
  out := match ity
    local
      list<DAE.Type> tys;
      Type ty;

    case DAE.T_METABOXED() then unboxedType(ity.ty);

    case DAE.T_METAOPTION()
      equation
        ty = unboxedType(ity.ty);
        ty = boxIfUnboxedType(ty);
      then DAE.T_METAOPTION(ty,DAE.emptyTypeSource);

    case DAE.T_METALIST()
      equation
        ty = unboxedType(ity.ty);
        ty = boxIfUnboxedType(ty);
      then
        DAE.T_METALIST(ty,DAE.emptyTypeSource);

    case DAE.T_METATUPLE()
      equation
        tys = List.mapMap(ity.types, unboxedType, boxIfUnboxedType);
      then
        DAE.T_METATUPLE(tys,DAE.emptyTypeSource);

    case DAE.T_METAARRAY()
      equation
        ty = unboxedType(ity.ty);
        ty = boxIfUnboxedType(ty);
      then
        DAE.T_METAARRAY(ty,DAE.emptyTypeSource);

    else ity;
  end match;
end unboxedType;

public function listMatchSuperType "Takes lists of Exp,Type and calculates the
supertype of the list, then converts the expressions to this type.
"
  input list<DAE.Exp> ielist;
  input list<DAE.Type> typeList;
  input Boolean printFailtrace;
  output list<DAE.Exp> out;
  output DAE.Type t;
algorithm
  (out,t) := matchcontinue (ielist,typeList,printFailtrace)
    local
      DAE.Exp e;
      Type ty, st;
      list<DAE.Exp> elist;

    case ({},{},_) then ({}, DAE.T_UNKNOWN_DEFAULT);
    case (_ :: _, _ :: _,_)
      equation
        st = List.reduce(typeList, superType);
        st = superType(st,st);
        st = unboxedType(st);
        elist = listMatchSuperType2(ielist,typeList,st,printFailtrace);
      then (elist, st);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Types.listMatchSuperType failed\n");
      then fail();
  end matchcontinue;
end listMatchSuperType;

protected function listMatchSuperType2
  input list<DAE.Exp> elist;
  input list<DAE.Type> typeList;
  input DAE.Type st;
  input Boolean printFailtrace;
  output list<DAE.Exp> out;
algorithm
  out := matchcontinue (elist, typeList, st, printFailtrace)
    local
      DAE.Exp e;
      list<DAE.Exp> erest;
      Type t;
      list<DAE.Type> trest;
      String str;
    case ({},{},_,_) then {};
    case (e::erest, t::trest, _, _)
      equation
        (e,t) = matchType(e,t,st,printFailtrace);
        erest = listMatchSuperType2(erest,trest,st,printFailtrace);
      then (e::erest);
    case (e::_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str = ExpressionDump.printExpStr(e);
        Debug.traceln("- Types.listMatchSuperType2 failed: " + str);
      then fail();
  end matchcontinue;
end listMatchSuperType2;

public function superType "find the supertype of the two types"
  input DAE.Type inType1;
  input DAE.Type inType2;
  output DAE.Type out;
algorithm
  out :=
  matchcontinue (inType1,inType2)
    local
      Type t1,t2,tp;
      list<DAE.Type> type_list1,type_list2;
      Absyn.Path path1,path2;

    case (DAE.T_ANYTYPE(),t2) then t2;
    case (t1,DAE.T_ANYTYPE()) then t1;
    case (DAE.T_UNKNOWN(),t2) then t2;
    case (t1,DAE.T_UNKNOWN()) then t1;
    case (_,t2 as DAE.T_METAPOLYMORPHIC()) then t2;

    case (DAE.T_TUPLE(types = type_list1),DAE.T_TUPLE(types = type_list2))
      equation
        type_list1 = List.map(type_list1, boxIfUnboxedType);
        type_list2 = List.map(type_list2, boxIfUnboxedType);
        type_list1 = List.threadMap(type_list1,type_list2,superType);
      then DAE.T_METATUPLE(type_list1,DAE.emptyTypeSource);

    case (DAE.T_TUPLE(types = type_list1),DAE.T_METATUPLE(types = type_list2))
      equation
        type_list1 = List.map(type_list1, boxIfUnboxedType);
        type_list2 = List.map(type_list2, boxIfUnboxedType);
        type_list1 = List.threadMap(type_list1,type_list2,superType);
      then DAE.T_METATUPLE(type_list1,DAE.emptyTypeSource);

    case (DAE.T_METATUPLE(types = type_list1),DAE.T_TUPLE(types = type_list2))
      equation
        type_list1 = List.map(type_list1, boxIfUnboxedType);
        type_list2 = List.map(type_list2, boxIfUnboxedType);
        type_list1 = List.threadMap(type_list1,type_list2,superType);
      then DAE.T_METATUPLE(type_list1,DAE.emptyTypeSource);

    case (DAE.T_METATUPLE(types = type_list1),DAE.T_METATUPLE(types = type_list2))
      equation
        type_list1 = List.map(type_list1, boxIfUnboxedType);
        type_list2 = List.map(type_list2, boxIfUnboxedType);
        type_list1 = List.threadMap(type_list1,type_list2,superType);
      then DAE.T_METATUPLE(type_list1,DAE.emptyTypeSource);

    case (DAE.T_METALIST(ty = t1),DAE.T_METALIST(ty = t2))
      equation
        t1 = boxIfUnboxedType(t1);
        t2 = boxIfUnboxedType(t2);
        tp = superType(t1,t2);
      then DAE.T_METALIST(tp,DAE.emptyTypeSource);

    case (DAE.T_METAOPTION(ty = t1), DAE.T_METAOPTION(ty = t2))
      equation
        t1 = boxIfUnboxedType(t1);
        t2 = boxIfUnboxedType(t2);
        tp = superType(t1,t2);
      then DAE.T_METAOPTION(tp,DAE.emptyTypeSource);

    case (DAE.T_METAARRAY(ty = t1), DAE.T_METAARRAY(ty = t2))
      equation
        t1 = boxIfUnboxedType(t1);
        t2 = boxIfUnboxedType(t2);
        tp = superType(t1,t2);
      then DAE.T_METAARRAY(tp,DAE.emptyTypeSource);

    case (t1 as DAE.T_METAUNIONTYPE(source = {path1}), DAE.T_METARECORD(utPath=path2))
      equation
        true = Absyn.pathEqual(path1,path2);
      then t1;

    case (DAE.T_METARECORD(knownSingleton=false,utPath = path1), DAE.T_METARECORD(knownSingleton=false,utPath=path2))
      equation
        true = Absyn.pathEqual(path1,path2);
      then DAE.T_METAUNIONTYPE({},inType1.typeVars,false,DAE.NOT_SINGLETON(),{path1});

    case (DAE.T_INTEGER(),DAE.T_REAL())
      then DAE.T_REAL_DEFAULT;

    case (DAE.T_REAL(),DAE.T_INTEGER())
      then DAE.T_REAL_DEFAULT;

    case (t1,t2)
      equation
        true = subtype(t1,t2);
      then t2;

    case (t1,t2)
      equation
        true = subtype(t2,t1);
      then t1;

  end matchcontinue;
end superType;

public function matchTypePolymorphic "Like matchType, except we also
bind polymorphic variabled. Used when elaborating calls."
  input DAE.Exp iexp;
  input DAE.Type iactual;
  input DAE.Type expected;
  input Option<Absyn.Path> envPath "to detect which polymorphic types are recursive";
  input InstTypes.PolymorphicBindings ipolymorphicBindings;
  input Boolean printFailtrace;
  output DAE.Exp exp=iexp;
  output DAE.Type actual=iactual;
  output InstTypes.PolymorphicBindings polymorphicBindings=ipolymorphicBindings;
protected
  constant Boolean debug=false;
algorithm
  if (if not Config.acceptMetaModelicaGrammar() then true else listEmpty(getAllInnerTypesOfType(expected, isPolymorphic))) then
    (exp,actual) := matchType(exp,actual,expected,printFailtrace);
  else
    if debug then print("match type: " + ExpressionDump.printExpStr(exp) + " of " + unparseType(actual) + " with " + unparseType(expected) + "\n"); end if;
    (exp,actual) := matchType(exp,actual,DAE.T_METABOXED(DAE.T_UNKNOWN_DEFAULT,DAE.emptyTypeSource), printFailtrace);
    if debug then print("matched type: " + ExpressionDump.printExpStr(exp) + " of " + unparseType(actual) + " with " + unparseType(expected) + " (boxed)\n"); end if;
    polymorphicBindings := subtypePolymorphic(getUniontypeIfMetarecordReplaceAllSubtypes(actual), getUniontypeIfMetarecordReplaceAllSubtypes(expected), envPath, polymorphicBindings);
    if debug then print("match type: " + ExpressionDump.printExpStr(exp) + " of " + unparseType(actual) + " with " + unparseType(expected) + " and bindings " + polymorphicBindingsStr(polymorphicBindings) + " (OK)\n"); end if;
  end if;
end matchTypePolymorphic;

public function matchTypePolymorphicWithError "Like matchType, except we also
bind polymorphic variabled. Used when elaborating calls."
  input DAE.Exp iexp;
  input DAE.Type iactual;
  input DAE.Type iexpected;
  input Option<Absyn.Path> envPath "to detect which polymorphic types are recursive";
  input InstTypes.PolymorphicBindings ipolymorphicBindings;
  input SourceInfo info;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output InstTypes.PolymorphicBindings outBindings;
algorithm
  (outExp,outType,outBindings):=
  matchcontinue (iexp,iactual,iexpected,envPath,ipolymorphicBindings,info)
    local
      DAE.Exp e,e_1,exp;
      Type e_type,expected_type,e_type_1,actual,expected;
      InstTypes.PolymorphicBindings polymorphicBindings;
      String str1,str2,str3;

    case (exp,actual,expected,_,polymorphicBindings,_)
      equation
        (exp,actual,polymorphicBindings) = matchTypePolymorphic(exp,actual,expected,envPath,polymorphicBindings,false);
      then (exp,actual,polymorphicBindings);
    else
      equation
        str1 = ExpressionDump.printExpStr(iexp);
        str2 = unparseType(iactual);
        str3 = unparseType(iexpected);
        Error.addSourceMessage(Error.EXP_TYPE_MISMATCH, {str1,str3,str2}, info);
      then fail();
  end matchcontinue;
end matchTypePolymorphicWithError;

public function matchType
  "This function matches an expression with an expected type, and converts the
    expression to the expected type if necessary."
  input DAE.Exp inExp;
  input DAE.Type inActualType;
  input DAE.Type inExpectedType;
  input Boolean inPrintFailtrace;
  output DAE.Exp outExp;
  output DAE.Type outType;
algorithm
  if subtype(inExpectedType, inActualType) then
    /* TODO: Don't return ANY as type here; use the most restrictive... Else we get issues... */
    outExp := inExp;
    outType := inActualType;
  else
    try
      false := subtype(inActualType, inExpectedType);
      (outExp, outType) := typeConvert(inExp, inActualType, inExpectedType, inPrintFailtrace);
      outExp := ExpressionSimplify.simplify1(outExp);
    else
      printFailure(Flags.TYPES, "matchType", inExp, inActualType, inExpectedType);
      fail();
    end try;
  end if;
end matchType;

public function matchTypeNoFail
  input DAE.Exp inExp;
  input DAE.Type inActualType;
  input DAE.Type inExpectedType;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output Boolean outMatch;
algorithm
  if subtype(inExpectedType, inActualType) then
    outExp := inExp;
    outType := inActualType;
    outMatch := true;
  else
    try
      (outExp, outType) := typeConvert(inExp, inActualType, inExpectedType, false);
      outExp := ExpressionSimplify.simplify1(outExp);
      outMatch := true;
    else
      outExp := inExp;
      outType := inActualType;
      outMatch := true;
    end try;
  end if;
end matchTypeNoFail;

public function matchTypes
  "matchType, list of actual types, one expected type."
  input list<DAE.Exp> iexps;
  input list<DAE.Type> itys;
  input DAE.Type expected;
  input Boolean printFailtrace;
  output list<DAE.Exp> outExps;
  output list<DAE.Type> outTys;
algorithm
  (outExps, outTys) := matchTypes_tail(iexps, itys, expected, printFailtrace, {}, {});
end matchTypes;

protected function matchTypes_tail
  input list<DAE.Exp> iexps;
  input list<DAE.Type> itys;
  input DAE.Type expected;
  input Boolean printFailtrace;
  input list<DAE.Exp> inAccumExps;
  input list<DAE.Type> inAccumTypes;
  output list<DAE.Exp> outExps;
  output list<DAE.Type> outTys;
algorithm
  (outExps, outTys) :=
  match(iexps, itys, expected, printFailtrace, inAccumExps, inAccumTypes)
    local
      DAE.Exp e;
      list<DAE.Exp> exps;
      DAE.Type ty;
      list<DAE.Type> tys;

    case (e :: exps, ty :: tys, _, _, _, _)
      equation
        (e, ty) = matchTypes2(e, ty, expected, printFailtrace);
        (exps, tys) = matchTypes_tail(exps, tys, expected, printFailtrace,
          e :: inAccumExps, ty :: inAccumTypes);
      then
        (exps, tys);

    case ({}, {}, _, _, _, _)
      then (listReverse(inAccumExps), listReverse(inAccumTypes));

  end match;
end matchTypes_tail;

protected function matchTypes2
  input DAE.Exp inExp;
  input DAE.Type inType;
  input DAE.Type inExpected;
  input Boolean inPrintFailtrace;
  output DAE.Exp outExp;
  output DAE.Type outType;
algorithm
  (outExp, outType) := matchcontinue(inExp, inType, inExpected, inPrintFailtrace)
    local
      DAE.Exp e;
      DAE.Type ty, expected_ty;
      String str;

    case (_, _, _, _)
      equation
        ty = getUniontypeIfMetarecordReplaceAllSubtypes(inType);
        expected_ty = getUniontypeIfMetarecordReplaceAllSubtypes(inExpected);
        (e, ty) = matchType(inExp, ty, expected_ty, inPrintFailtrace);
      then
        (e, ty);

    else
      equation
        str = "- Types.matchTypes failed for " + ExpressionDump.printExpStr(inExp)
           + " from " + unparseType(inType) + " to " + unparseType(inExpected) + "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();

  end matchcontinue;
end matchTypes2;

protected function printFailure
"@author adrpo
 print the message only when flag is on.
 this is to speed up the flattening as we don't
 generate the strings at all."
  input Flags.DebugFlag flag;
  input String source;
  input DAE.Exp e;
  input DAE.Type e_type;
  input DAE.Type expected_type;
algorithm
  if Flags.isSet(flag) then
    Debug.traceln("- Types." + source + " failed on:" + ExpressionDump.printExpStr(e));
    Debug.traceln("  type:" + unparseType(e_type) + " differs from expected\n  type:" + unparseType(expected_type));
  end if;
end printFailure;

protected function polymorphicBindingStr
  input tuple<String,list<DAE.Type>> binding;
  output String str;
protected
  list<DAE.Type> tys;
algorithm
  (str,tys) := binding;
  // Don't bother doing this fast; it's just for error messages
  str := "    " + str + ":\n" + stringDelimitList(List.map1r(List.map(tys, unparseType), stringAppend, "      "), "\n");
end polymorphicBindingStr;

public function polymorphicBindingsStr
  input InstTypes.PolymorphicBindings bindings;
  output String str;
algorithm
  str := stringDelimitList(List.map(bindings, polymorphicBindingStr), "\n");
end polymorphicBindingsStr;

public function fixPolymorphicRestype
"Uses the polymorphic bindings to determine the result type of the function."
  input DAE.Type ty;
  input InstTypes.PolymorphicBindings bindings;
  input SourceInfo info;
  output DAE.Type resType;
algorithm
  //print("Trying to fix restype: " + unparseType(ty) + "\n");
  resType := fixPolymorphicRestype2(ty,"$",bindings,info);
  //print("OK: " + unparseType(resType) + "\n");
end fixPolymorphicRestype;

protected function fixPolymorphicRestype2
  input DAE.Type ty;
  input String prefix;
  input InstTypes.PolymorphicBindings bindings;
  input SourceInfo info;
  output DAE.Type resType;
algorithm
  resType := matchcontinue (ty,prefix,bindings,info)
    local
      String id,bstr,tstr;
      Type t1,t2,ty1;
      list<DAE.Type> tys,tys1;
      list<String> names1;
      list<DAE.FuncArg> args1;
      DAE.FunctionAttributes functionAttributes;
      DAE.TypeSource ts1;
      list<DAE.Const> cs;
      list<DAE.VarParallelism> ps;
      list<Option<DAE.Exp>> oe;
      list<Absyn.Path> paths;
      Boolean knownSingleton;
      DAE.EvaluateSingletonType singletonType;

    case (DAE.T_METAPOLYMORPHIC(name = id),_,_,_)
      equation
        {t1} = polymorphicBindingsLookup(prefix + id, bindings);
        t1 = fixPolymorphicRestype2(t1, "", bindings, info);
      then t1;

    case (DAE.T_METALIST(ty = t1),_,_,_)
      equation
        t2 = fixPolymorphicRestype2(t1, prefix,bindings, info);
        t2 = boxIfUnboxedType(t2);
      then DAE.T_METALIST(t2,DAE.emptyTypeSource);

    case (DAE.T_METAARRAY(ty = t1),_,_,_)
      equation
        t2 = fixPolymorphicRestype2(t1,prefix,bindings, info);
        t2 = boxIfUnboxedType(t2);
      then DAE.T_METAARRAY(t2,DAE.emptyTypeSource);

    case (DAE.T_METAOPTION(ty = t1),_,_,_)
      equation
        t2 = fixPolymorphicRestype2(t1, prefix,bindings, info);
        t2 = boxIfUnboxedType(t2);
      then DAE.T_METAOPTION(t2,DAE.emptyTypeSource);

    case (DAE.T_METAUNIONTYPE(typeVars={}),_,_,_)
      then ty;

    case (DAE.T_METAUNIONTYPE(typeVars=tys),_,_,_)
      equation
        tys = List.map3(tys, fixPolymorphicRestype2, prefix, bindings, info);
        tys = List.map(tys, boxIfUnboxedType);
      then DAE.T_METAUNIONTYPE(ty.paths,tys,ty.knownSingleton,ty.singletonType,ty.source);

    case (DAE.T_METATUPLE(types = tys),_,_,_)
      equation
        tys = List.map3(tys, fixPolymorphicRestype2, prefix, bindings, info);
        tys = List.map(tys, boxIfUnboxedType);
      then DAE.T_METATUPLE(tys,DAE.emptyTypeSource);

    case (t1 as DAE.T_TUPLE(),_,_,_)
      equation
        t1.types = List.map3(t1.types, fixPolymorphicRestype2, prefix, bindings, info);
      then t1;

    case (DAE.T_FUNCTION(args1,ty1,functionAttributes,ts1),_,_,_)
      equation
        tys1 = List.map(args1, funcArgType);
        tys1 = List.map3(tys1, fixPolymorphicRestype2, prefix, bindings, info);
        ty1 = fixPolymorphicRestype2(ty1,prefix,bindings,info);
        args1 = List.threadMap(args1,tys1,setFuncArgType);
        ty1 = DAE.T_FUNCTION(args1,ty1,functionAttributes,ts1);
      then ty1;

    // Add Uniontype, Function reference(?)
    case (_, _, _, _)
      equation
        // failure(isPolymorphic(ty)); Recursive functions like to return polymorphic crap we don't know of
      then ty;

    else
      equation
        tstr = unparseType(ty);
        bstr = polymorphicBindingsStr(bindings);
        id = "Types.fixPolymorphicRestype failed for type: " + tstr + " using bindings: " + bstr;
        Error.addSourceMessage(Error.INTERNAL_ERROR, {id}, info);
      then fail();
  end matchcontinue;
end fixPolymorphicRestype2;

public function polymorphicBindingsLookup
  input String id;
  input InstTypes.PolymorphicBindings bindings;
  output list<DAE.Type> resType;
algorithm
  resType := matchcontinue (id, bindings)
    local
      String id2;
      list<DAE.Type> tys;
      InstTypes.PolymorphicBindings rest;
    case (_, (id2,tys)::_)
      equation
        true = id == id2;
      then List.map(tys, boxIfUnboxedType);
    case (_, _::rest)
      equation
        tys = polymorphicBindingsLookup(id,rest);
      then tys;
  end matchcontinue;
end polymorphicBindingsLookup;

public function getAllInnerTypesOfType
"Traverses all the types the input DAE.Type contains, checks if
they are of the type the given function specifies, then returns
a list of all those types."
  input DAE.Type inType;
  input TypeFn inFn;
  output list<DAE.Type> outTypes;
  partial function TypeFn
    input DAE.Type fnInType;
    output Boolean outMatch;
  end TypeFn;
algorithm
  outTypes := getAllInnerTypes({inType},{},inFn);
end getAllInnerTypesOfType;

protected function getAllInnerTypes
  "Traverses all the types that the input DAE.Type contains, and returns all
   types for which the given function returns true."
  input list<DAE.Type> inTypes;
  input list<DAE.Type> inAccum = {};
  input MatchFunc inFunc;
  output list<DAE.Type> outTypes = inAccum;

  partial function MatchFunc
    input DAE.Type inType;
    output Boolean outMatch;
  end MatchFunc;
protected
  DAE.Type ty;
  list<DAE.Type> tys;
algorithm
  for t in inTypes loop
    // Add the type to the result list if the match function return true.
    if inFunc(t) then
      outTypes := t :: outTypes;
    end if;

    // Get the inner types of the type.
    tys := match(t)
      local
        list<DAE.Var> fields;
        list<DAE.FuncArg> funcArgs;
      case DAE.T_ARRAY(ty = ty) then {ty};
      case DAE.T_METALIST(ty = ty) then {ty};
      case DAE.T_METAARRAY(ty = ty) then {ty};
      case DAE.T_METABOXED(ty = ty) then {ty};
      case DAE.T_METAOPTION(ty = ty) then {ty};
      case DAE.T_TUPLE(types = tys) then tys;
      case DAE.T_METATUPLE(types = tys) then tys;
      case DAE.T_METAUNIONTYPE(typeVars = tys) then tys;
      case DAE.T_METARECORD(typeVars = tys, fields = fields)
        then listAppend(tys, List.map(fields, getVarType));
      case DAE.T_COMPLEX(varLst = fields)
        then List.map(fields, getVarType);
      case DAE.T_SUBTYPE_BASIC(varLst = fields)
        then List.map(fields, getVarType);
      case DAE.T_FUNCTION(funcArg = funcArgs, funcResultType = ty)
        then ty :: List.map(funcArgs, funcArgType);
      else {};
    end match;

    // Call this function recursively to filter out the matching inner types and
    // add them to the result.
    outTypes := getAllInnerTypes(tys, outTypes, inFunc);
  end for;
end getAllInnerTypes;

public function uniontypeFilter
  input DAE.Type ty;
  output Boolean outMatch;
algorithm
  outMatch := match ty
    case DAE.T_METAUNIONTYPE(__) then true;
    else false;
  end match;
end uniontypeFilter;

public function metarecordFilter
  input DAE.Type ty;
  output Boolean outMatch;
algorithm
  outMatch := match ty
    case DAE.T_METARECORD(__) then true;
    else false;
  end match;
end metarecordFilter;

public function getUniontypePaths
  input DAE.Type ty;
  output list<Absyn.Path> outPaths;
algorithm
  outPaths := match ty
    local
      list<Absyn.Path> paths;
    case DAE.T_METAUNIONTYPE(paths=paths) then paths;
  end match;
end getUniontypePaths;

public function makeFunctionPolymorphicReference
"Takes a function reference. If it contains any types that are not boxed, we
return a reference to the function that does take boxed types. Else, we
return a reference to the regular function."
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match (inType)
    local
      list<DAE.FuncArg> funcArgs1,funcArgs2;
      list<String> funcArgNames;
      list<DAE.Type> funcArgTypes1, funcArgTypes2, dummyBoxedTypeList;
      list<DAE.Exp> dummyExpList;
      list<DAE.Const> cs;
      list<DAE.VarParallelism> ps;
      list<Option<DAE.Exp>> oe;
      Type ty2,resType1,resType2;
      Type tty1;
      Absyn.Path path;
      DAE.FunctionAttributes functionAttributes;

    case (DAE.T_FUNCTION(funcArgs1,resType1,functionAttributes,{path}))
      equation
        funcArgTypes1 = List.map(funcArgs1, funcArgType);
        (dummyExpList,dummyBoxedTypeList) = makeDummyExpAndTypeLists(funcArgTypes1);
        (_,funcArgTypes2) = matchTypeTuple(dummyExpList, funcArgTypes1, dummyBoxedTypeList, false);
        funcArgs2 = List.threadMap(funcArgs1,funcArgTypes2,setFuncArgType);
        resType2 = makeFunctionPolymorphicReferenceResType(resType1);
        ty2 = DAE.T_FUNCTION(funcArgs2,resType2,functionAttributes,{path});
      then ty2;

    /* Maybe add this case when standard Modelica gets function references?
    case (ty1 as (tty1 as DAE.T_FUNCTION(funcArgs1,resType),SOME(path)))
      local
        list<Boolean> boolList;
      equation
        funcArgTypes1 = List.map(funcArgs1, Util.tuple22);
        boolList = List.map(funcArgTypes1, isBoxedType);
        true = List.reduce(boolList, boolAnd);
      then ty1; */
    case _
      equation
        // fprintln(Flags.FAILTRACE, "- Types.makeFunctionPolymorphicReference failed");
      then fail();
  end match;
end makeFunctionPolymorphicReference;

protected function makeFunctionPolymorphicReferenceResType
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inType)
    local
      DAE.TypeSource ts;
      DAE.Exp e;
      Type ty,ty1,ty2;
      list<DAE.Type> tys, dummyBoxedTypeList;
      list<DAE.Exp> dummyExpList;

    case (ty as DAE.T_TUPLE(tys))
      equation
        (dummyExpList,dummyBoxedTypeList) = makeDummyExpAndTypeLists(tys);
        (_,tys) = matchTypeTuple(dummyExpList, tys, dummyBoxedTypeList, false);
        ty.types = tys;
      then ty;
    case (ty as DAE.T_NORETCALL()) then ty;
    case ty1
      equation
        ({e},{ty2}) = makeDummyExpAndTypeLists({ty1});
        (_,ty) = matchType(e, ty1, ty2, false);
      then ty;
  end matchcontinue;
end makeFunctionPolymorphicReferenceResType;

protected function makeDummyExpAndTypeLists
  input list<DAE.Type> lst;
  output list<DAE.Exp> outExps;
  output list<DAE.Type> outTypes;
algorithm
  (outExps,outTypes) := match (lst)
    local
      list<DAE.Exp> restExp;
      list<DAE.Type> restType, rest;
      DAE.ComponentRef cref_;
      DAE.Exp crefExp;

    case {} then ({},{});

    case _::rest
      equation
        (restExp,restType) = makeDummyExpAndTypeLists(rest);
        cref_  = ComponentReference.makeCrefIdent("#DummyExp#",DAE.T_UNKNOWN_DEFAULT,{});
        crefExp = Expression.crefExp(cref_);
      then
        (crefExp::restExp,DAE.T_METABOXED(DAE.T_UNKNOWN_DEFAULT,DAE.emptyTypeSource)::restType);
  end match;
end makeDummyExpAndTypeLists;

public function resTypeToListTypes
"Transforms a DAE.T_TUPLE to a list of types. Other types return the same type (as a list)"
  input DAE.Type inType;
  output list<DAE.Type> outType;
algorithm
  outType := match (inType)
    local
      list<DAE.Type> tys;
      Type ty;
    case DAE.T_TUPLE(types = tys) then tys;
    case DAE.T_NORETCALL() then {};
    case ty then {ty};
  end match;
end resTypeToListTypes;

public function getRealOrIntegerDimensions
"If the type is a Real, Integer or an array of Real or Integer, the function returns
list of dimensions; otherwise, it fails."
 input DAE.Type inType;
 output DAE.Dimensions outDims;
algorithm
  outDims := match (inType)
    local
      Type ty;
      DAE.Dimension d;
      DAE.Dimensions dims;

    case (DAE.T_REAL()) then {};
    case (DAE.T_INTEGER()) then {};
    case (DAE.T_SUBTYPE_BASIC(complexType = ty))
      then getRealOrIntegerDimensions(ty);

    case (DAE.T_ARRAY(dims = {d as DAE.DIM_INTEGER(_)}, ty = ty))
      equation
        dims = getRealOrIntegerDimensions(ty);
      then
        d::dims;
  end match;
end getRealOrIntegerDimensions;

protected function isPolymorphic
  input DAE.Type ty;
  output Boolean outMatch;
algorithm
  outMatch := match(ty)
    case DAE.T_METAPOLYMORPHIC(__) then true;
    else false;
  end match;
end isPolymorphic;

protected function polymorphicTypeName
  input DAE.Type ty;
  output String name;
algorithm
  DAE.T_METAPOLYMORPHIC(name = name) := ty;
end polymorphicTypeName;

protected function addPolymorphicBinding
  input String id;
  input DAE.Type ity;
  input InstTypes.PolymorphicBindings bindings;
  output InstTypes.PolymorphicBindings outBindings;
algorithm
  outBindings := matchcontinue (id,ity,bindings)
    local
      String id1,id2;
      list<DAE.Type> tys;
      InstTypes.PolymorphicBindings rest;
      tuple<String,list<DAE.Type>> first;
      Type ty;

    case (_,ty,{})
      equation
        ty = unboxedType(ty);
        ty = boxIfUnboxedType(ty);
      then {(id,{ty})};
    case (id1,ty,(id2,tys)::rest)
      equation
        true = id1 == id2;
        ty = unboxedType(ty);
        ty = boxIfUnboxedType(ty);
      then (id2,ty::tys)::rest;
    case (_,ty,first::rest)
      equation
        rest = addPolymorphicBinding(id,ty,rest);
      then first::rest;
  end matchcontinue;
end addPolymorphicBinding;

public function solvePolymorphicBindings
"Takes a set of polymorphic bindings and tries to solve the constraints
such that each name is bound to a non-polymorphic type.
Solves by doing iterations until a valid state is found (or no change is
possible)."
  input InstTypes.PolymorphicBindings bindings;
  input SourceInfo info;
  input list<Absyn.Path> pathLst;
  output InstTypes.PolymorphicBindings solvedBindings;
protected
  InstTypes.PolymorphicBindings unsolvedBindings;
algorithm
  // print("solvePoly " + polymorphicBindingsStr(bindings) + "\n");
  (solvedBindings,unsolvedBindings) := solvePolymorphicBindingsLoop(bindings, {}, {});
  checkValidBindings(bindings, solvedBindings, unsolvedBindings, info, pathLst);
  // print("solved poly " + polymorphicBindingsStr(solvedBindings) + "\n");
end solvePolymorphicBindings;

protected function checkValidBindings
"Emits an error message if we could not solve the polymorphic types to actual types."
  input InstTypes.PolymorphicBindings bindings;
  input InstTypes.PolymorphicBindings solvedBindings;
  input InstTypes.PolymorphicBindings unsolvedBindings;
  input SourceInfo info;
  input list<Absyn.Path> pathLst;
protected
  String bindingsStr, solvedBindingsStr, unsolvedBindingsStr, pathStr;
  list<DAE.Type> tys;
algorithm
  if not listEmpty(unsolvedBindings) then
    pathStr := stringDelimitList(list(Absyn.pathString(p) for p in pathLst), ", ");
    bindingsStr := polymorphicBindingsStr(bindings);
    solvedBindingsStr := polymorphicBindingsStr(solvedBindings);
    unsolvedBindingsStr := polymorphicBindingsStr(unsolvedBindings);
    Error.addSourceMessage(Error.META_UNSOLVED_POLYMORPHIC_BINDINGS, {pathStr,bindingsStr,solvedBindingsStr,unsolvedBindingsStr},info);
    fail();
  end if;
end checkValidBindings;

protected function solvePolymorphicBindingsLoop
  input InstTypes.PolymorphicBindings ibindings;
  input InstTypes.PolymorphicBindings isolvedBindings;
  input InstTypes.PolymorphicBindings iunsolvedBindings;
  output InstTypes.PolymorphicBindings outSolvedBindings;
  output InstTypes.PolymorphicBindings outUnsolvedBindings;
algorithm
  (outSolvedBindings,outUnsolvedBindings) := matchcontinue (ibindings,isolvedBindings,iunsolvedBindings)
    /* Fail by returning crap :) */
    local
      tuple<String, list<DAE.Type>> first;
      Type ty;
      list<DAE.Type> tys;
      String id;
      Integer len1, len2;
      InstTypes.PolymorphicBindings rest,solvedBindings,unsolvedBindings;

    case ({}, solvedBindings, unsolvedBindings) then (solvedBindings, unsolvedBindings);

    case ((id,{ty})::rest,solvedBindings,unsolvedBindings)
      equation
        ty = Types.boxIfUnboxedType(ty);
        (solvedBindings,unsolvedBindings) = solvePolymorphicBindingsLoop(listAppend(unsolvedBindings,rest),(id,{ty})::solvedBindings,{});
      then (solvedBindings,unsolvedBindings);

      // Replace solved bindings
    case ((id,tys)::rest,solvedBindings,unsolvedBindings)
      algorithm
        tys := replaceSolvedBindings(tys, solvedBindings, false);
        tys := List.unionOnTrue(tys, {}, equivtypes);
        (solvedBindings,unsolvedBindings) := solvePolymorphicBindingsLoop(listAppend((id,tys)::unsolvedBindings,rest),solvedBindings,{});
      then (solvedBindings,unsolvedBindings);

    case ((id,tys)::rest,solvedBindings,unsolvedBindings)
      algorithm
        (tys,solvedBindings) := solveBindings(tys, tys, solvedBindings);
        tys := List.unionOnTrue(tys, {}, equivtypes);
        (solvedBindings,unsolvedBindings) := solvePolymorphicBindingsLoop(listAppend((id,tys)::unsolvedBindings,rest),solvedBindings,{});
      then (solvedBindings,unsolvedBindings);

      // Duplicate types need to be removed
    case ((id,tys)::rest,solvedBindings,unsolvedBindings)
      algorithm
        len1 := listLength(tys);
        true := len1 > 1;
        tys := List.unionOnTrue(tys, {}, equivtypes); // Remove duplicates
        len2 := listLength(tys);
        false := len1 == len2;
        (solvedBindings,unsolvedBindings) := solvePolymorphicBindingsLoop(listAppend((id,tys)::unsolvedBindings,rest),solvedBindings,{});
      then (solvedBindings,unsolvedBindings);

    case (first::rest, solvedBindings, unsolvedBindings)
      equation
        (solvedBindings,unsolvedBindings) = solvePolymorphicBindingsLoop(rest, solvedBindings, first::unsolvedBindings);
      then (solvedBindings, unsolvedBindings);
  end matchcontinue;
end solvePolymorphicBindingsLoop;

protected function solveBindings
"Checks all types against each other to find an unbound polymorphic variable, which will then become bound.
Uses unification to solve the system, but the algorithm is slow (possibly quadratic).
The good news is we don't have functions with many unknown types in the compiler.
Horribly complicated function to keep track of what happens..."
  input list<DAE.Type> itys1;
  input list<DAE.Type> itys2;
  input InstTypes.PolymorphicBindings isolvedBindings;
  output list<DAE.Type> outTys;
  output InstTypes.PolymorphicBindings outSolvedBindings;
algorithm
  (outTys,outSolvedBindings) := matchcontinue (itys1,itys2,isolvedBindings)
    local
      Type ty,ty1,ty2;
      list<DAE.Type> tys,rest,tys1,tys2;
      String id,id1,id2;
      list<String> names1;
      list<DAE.FuncArg> args1,args2;
      DAE.FunctionAttributes functionAttributes1,functionAttributes2;
      DAE.TypeSource ts1;
      Boolean fromOtherFunction;
      list<DAE.Const> cs1;
      list<DAE.VarParallelism> ps1;
      InstTypes.PolymorphicBindings solvedBindings;

    case ((ty1 as DAE.T_METAPOLYMORPHIC(name = id1))::_,(ty2 as DAE.T_METAPOLYMORPHIC(name = id2))::tys2,solvedBindings)
      equation
        false = id1 == id2;
        // If we have $X,Y,..., bind $X = Y instead of Y = $X
        fromOtherFunction = System.stringFind(id1,"$") <> -1;
        id = if fromOtherFunction then id1 else id2;
        ty = if fromOtherFunction then ty2 else ty1; // Lookup from one id to the other type
        failure(_ = polymorphicBindingsLookup(id, solvedBindings));
        solvedBindings = addPolymorphicBinding(id,ty,solvedBindings);
      then (ty::tys2, solvedBindings);

    case ((DAE.T_METAPOLYMORPHIC(name = id))::_,ty2::tys2,solvedBindings)
      equation
        false = isPolymorphic(ty2);
        failure(_ = polymorphicBindingsLookup(id, solvedBindings));
        solvedBindings = addPolymorphicBinding(id,ty2,solvedBindings);
      then (ty2::tys2, solvedBindings);

    case (ty1::_,(DAE.T_METAPOLYMORPHIC(name = id))::tys2,solvedBindings)
      equation
        false = isPolymorphic(ty1);
        failure(_ = polymorphicBindingsLookup(id, solvedBindings));
        solvedBindings = addPolymorphicBinding(id,ty1,solvedBindings);
      then (ty1::tys2, solvedBindings);

    case (DAE.T_METAOPTION(ty = ty1)::_,DAE.T_METAOPTION(ty = ty2)::tys2,solvedBindings)
      equation
        ({ty1},solvedBindings) = solveBindings({ty1},{ty2},solvedBindings);
        ty1 = DAE.T_METAOPTION(ty1,DAE.emptyTypeSource);
      then (ty1::tys2,solvedBindings);

    case (DAE.T_METALIST(ty = ty1)::_,DAE.T_METALIST(ty = ty2)::tys2,solvedBindings)
      equation
        ({ty1},solvedBindings) = solveBindings({ty1},{ty2},solvedBindings);
        ty1 = DAE.T_METALIST(ty1,DAE.emptyTypeSource);
      then (ty1::tys2,solvedBindings);

    case (DAE.T_METAARRAY(ty = ty1)::_,DAE.T_METAARRAY(ty = ty2)::tys2,solvedBindings)
      equation
        ({ty1},solvedBindings) = solveBindings({ty1},{ty2},solvedBindings);
        ty1 = DAE.T_METAARRAY(ty1,DAE.emptyTypeSource);
      then (ty1::tys2,solvedBindings);

    case (DAE.T_METATUPLE(types = tys1)::_,DAE.T_METATUPLE(types = tys2)::rest,solvedBindings)
      equation
        (tys1,solvedBindings) = solveBindingsThread(tys1,tys2,false,solvedBindings);
        ty1 = DAE.T_METATUPLE(tys1,DAE.emptyTypeSource);
      then (ty1::rest,solvedBindings);

    case (DAE.T_FUNCTION(args1,ty1,functionAttributes1,ts1)::_,DAE.T_FUNCTION(args2,ty2,_,_)::rest,solvedBindings)
      equation
        tys1 = List.map(args1, funcArgType);
        tys2 = List.map(args2, funcArgType);
        (ty1::tys1,solvedBindings) = solveBindingsThread(ty1::tys1,ty2::tys2,false,solvedBindings);
        tys1 = List.map(tys1, boxIfUnboxedType);
        args1 = List.threadMap(args1,tys1,setFuncArgType);
        args1 = List.map(args1,clearDefaultBinding);
        ty1 = DAE.T_FUNCTION(args1,ty1,functionAttributes1,ts1);
      then (ty1::rest,solvedBindings);

    case (tys1,ty::tys2,solvedBindings)
      equation
        (tys,solvedBindings) = solveBindings(tys1,tys2,solvedBindings);
      then (ty::tys,solvedBindings);
  end matchcontinue;
end solveBindings;

protected function solveBindingsThread
"Checks all types against each other to find an unbound polymorphic variable, which will then become bound.
Uses unification to solve the system, but the algorithm is slow (possibly quadratic).
The good news is we don't have functions with many unknown types in the compiler.

Horribly complicated function to keep track of what happens..."
  input list<DAE.Type> itys1;
  input list<DAE.Type> itys2;
  input Boolean changed "if true, something changed and the function will succeed";
  input InstTypes.PolymorphicBindings isolvedBindings;
  output list<DAE.Type> outTys;
  output InstTypes.PolymorphicBindings outSolvedBindings;
algorithm
  (outTys,outSolvedBindings) := matchcontinue (itys1,itys2,changed,isolvedBindings)
    local
      Type ty1,ty2;
      InstTypes.PolymorphicBindings solvedBindings;
      list<DAE.Type> tys1, tys2;

    case (ty1::tys1,ty2::tys2,_,solvedBindings)
      equation
        ({ty1},solvedBindings) = solveBindings({ty1},{ty2},solvedBindings);
        (tys2,solvedBindings) = solveBindingsThread(tys1,tys2,true,solvedBindings);
      then (ty1::tys2,solvedBindings);
    case (ty1::tys1,_::tys2,_,solvedBindings)
      equation
        (tys2,solvedBindings) = solveBindingsThread(tys1,tys2,changed,solvedBindings);
      then (ty1::tys2,solvedBindings);
    case ({},{},true,solvedBindings) then ({},solvedBindings);
  end matchcontinue;
end solveBindingsThread;

protected function replaceSolvedBindings
  input list<DAE.Type> itys;
  input InstTypes.PolymorphicBindings isolvedBindings;
  input Boolean changed "if true, something changed and the function will succeed";
  output list<DAE.Type> outTys;
algorithm
  outTys := matchcontinue (itys, isolvedBindings, changed)
    local
      Type ty;
      list<DAE.Type> tys;
      InstTypes.PolymorphicBindings solvedBindings;

    case ({},_,true) then {};
    case (ty::tys,solvedBindings,_)
      equation
        ty = replaceSolvedBinding(ty,solvedBindings);
        tys = replaceSolvedBindings(tys,solvedBindings,true);
      then ty::tys;
    case (ty::tys,solvedBindings,_)
      equation
        tys = replaceSolvedBindings(tys,solvedBindings,changed);
      then ty::tys;
  end matchcontinue;
end replaceSolvedBindings;

protected function replaceSolvedBinding
  input DAE.Type ity;
  input InstTypes.PolymorphicBindings isolvedBindings;
  output DAE.Type outTy;
algorithm
  outTy := match (ity,isolvedBindings)
    local
      list<DAE.FuncArg> args;
      list<DAE.Type> tys;
      String id;
      list<String> names;
      list<DAE.Const> cs;
      list<DAE.VarParallelism> ps;
      DAE.TypeSource ts;
      list<Option<DAE.Exp>> oe;
      DAE.FunctionAttributes functionAttributes;
      DAE.Type ty,resType;
      InstTypes.PolymorphicBindings solvedBindings;

    case (DAE.T_METALIST(ty = ty),solvedBindings)
      equation
        ty = replaceSolvedBinding(ty, solvedBindings);
        ty = DAE.T_METALIST(ty, DAE.emptyTypeSource);
      then ty;

    case (DAE.T_METAARRAY(ty = ty),solvedBindings)
      equation
        ty = replaceSolvedBinding(ty, solvedBindings);
        ty = DAE.T_METAARRAY(ty,DAE.emptyTypeSource);
      then ty;

    case (DAE.T_METAOPTION(ty = ty),solvedBindings)
      equation
        ty = replaceSolvedBinding(ty, solvedBindings);
        ty = DAE.T_METAOPTION(ty,DAE.emptyTypeSource);
      then ty;

    case (DAE.T_METATUPLE(types = tys),solvedBindings)
      equation
        tys = replaceSolvedBindings(tys,solvedBindings,false);
        ty = DAE.T_METATUPLE(tys,DAE.emptyTypeSource);
      then ty;

    case (DAE.T_TUPLE(types = tys),solvedBindings)
      equation
        tys = replaceSolvedBindings(tys,solvedBindings,false);
        ty = DAE.T_TUPLE(tys,ity.names,DAE.emptyTypeSource);
      then ty;

    case (DAE.T_FUNCTION(args,resType,functionAttributes,ts),solvedBindings)
      equation
        tys = List.map(args, funcArgType);
        tys = replaceSolvedBindings(resType::tys,solvedBindings,false);
        tys = List.map(tys, unboxedType);
        ty::tys = List.map(tys, boxIfUnboxedType);
        args = List.threadMap(args,tys,setFuncArgType);
        ty = makeRegularTupleFromMetaTupleOnTrue(isTuple(resType),ty);
        ty = DAE.T_FUNCTION(args,ty,functionAttributes,ts);
      then ty;

    case (DAE.T_METAPOLYMORPHIC(name = id),solvedBindings)
      equation
        {ty} = polymorphicBindingsLookup(id, solvedBindings);
      then ty;
  end match;
end replaceSolvedBinding;

protected function subtypePolymorphic
"A simple subtype() that also binds polymorphic variables.
Only works on the MetaModelica datatypes; the input is assumed to be boxed.
"
  input DAE.Type actual;
  input DAE.Type expected;
  input Option<Absyn.Path> envPath;
  input InstTypes.PolymorphicBindings inBindings;
  output InstTypes.PolymorphicBindings bindings;
algorithm
  bindings := matchcontinue (actual,expected)
    local
      String id,prefix;
      Type ty,ty1,ty2;
      list<DAE.FuncArg> farg1,farg2;
      list<DAE.Type> tList1,tList2,tys;
      Absyn.Path path1,path2;
      list<String> ids,names1,names2;

    case (_,DAE.T_METAPOLYMORPHIC(name = id))
      then addPolymorphicBinding("$" + id,actual,inBindings);

    case (DAE.T_METAPOLYMORPHIC(name = id),_)
      algorithm
        if stringGet(id,1)<>stringCharInt("$") then
          // We allow things like inner type variables of function pointers,
          // but not things like accepting T1 can be tuple<T2,T3>.
          // print("Not adding METAPOLYMORPHIC $$"+id+"="+unparseType(expected)+"\n");
          fail();
        end if;
      then addPolymorphicBinding("$$" + id,expected,inBindings);

    case (DAE.T_METABOXED(ty = ty1),ty2)
      equation
        ty1 = unboxedType(ty1);
      then subtypePolymorphic(ty1,ty2,envPath,inBindings);

    case (ty1,DAE.T_METABOXED(ty = ty2))
      equation
        ty2 = unboxedType(ty2);
      then subtypePolymorphic(ty1,ty2,envPath,inBindings);

    case (DAE.T_NORETCALL(),DAE.T_NORETCALL()) then inBindings;
    case (DAE.T_INTEGER(),DAE.T_INTEGER()) then inBindings;
    case (DAE.T_REAL(),DAE.T_INTEGER()) then inBindings;
    case (DAE.T_STRING(),DAE.T_STRING()) then inBindings;
    case (DAE.T_BOOL(),DAE.T_BOOL()) then inBindings;

    case (DAE.T_ENUMERATION(names = names1),
          DAE.T_ENUMERATION(names = names2))
      equation
        true = List.isEqualOnTrue(names1, names2, stringEq);
      then inBindings;

    case (DAE.T_METAARRAY(ty = ty1),DAE.T_METAARRAY(ty = ty2))
      then subtypePolymorphic(ty1,ty2,envPath,inBindings);
    case (DAE.T_METALIST(ty = ty1),DAE.T_METALIST(ty = ty2))
      then subtypePolymorphic(ty1,ty2,envPath,inBindings);
    case (DAE.T_METAOPTION(ty = ty1),DAE.T_METAOPTION(ty = ty2))
      then subtypePolymorphic(ty1,ty2,envPath,inBindings);
    case (DAE.T_METATUPLE(types = tList1),DAE.T_METATUPLE(types = tList2))
      then subtypePolymorphicList(tList1,tList2,envPath,inBindings);

    case (DAE.T_TUPLE(types = tList1),DAE.T_TUPLE(types = tList2))
      then subtypePolymorphicList(tList1,tList2,envPath,inBindings);

    case (DAE.T_METAUNIONTYPE(source = {path1}),DAE.T_METAUNIONTYPE(source = {path2}))
      equation
        true = Absyn.pathEqual(path1,path2);
      then subtypePolymorphicList(actual.typeVars, expected.typeVars, envPath, inBindings);

    case (DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path1)),DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path2)))
      equation
        true = Absyn.pathEqual(path1,path2);
      then inBindings;

    // MM Function Reference. sjoelund
    case (DAE.T_FUNCTION(farg1,ty1,_,{path1}),DAE.T_FUNCTION(farg2,ty2,_,{_}))
      algorithm
        if Absyn.pathPrefixOf(Util.getOptionOrDefault(envPath,Absyn.IDENT("$TOP$")),path1) then // Don't rename the result type for recursive calls...
          tList1 := List.map(farg1, funcArgType);
          tList2 := List.map(farg2, funcArgType);
          bindings := subtypePolymorphicList(tList1,tList2,envPath,inBindings);
          bindings := subtypePolymorphic(ty1,ty2,envPath,bindings);
        else
          prefix := "$" + Absyn.pathString(path1) + ".";
          (DAE.T_FUNCTION(farg1,ty1,_,_),_) := traverseType(actual, prefix, prefixTraversedPolymorphicType);
          tList1 := List.map(farg1, funcArgType);
          tList2 := List.map(farg2, funcArgType);
          bindings := subtypePolymorphicList(tList1,tList2,envPath,inBindings);
          bindings := subtypePolymorphic(ty1,ty2,envPath,bindings);
        end if;
      then bindings;

    case (DAE.T_UNKNOWN(),ty2)
      equation
        tys = getAllInnerTypesOfType(ty2, isPolymorphic);
        ids = List.map(tys, polymorphicTypeName);
        bindings = List.fold1(ids, addPolymorphicBinding, actual, inBindings);
      then bindings;

    case (DAE.T_ANYTYPE(),ty2)
      equation
        tys = getAllInnerTypesOfType(ty2, isPolymorphic);
        ids = List.map(tys, polymorphicTypeName);
        bindings = List.fold1(ids, addPolymorphicBinding, actual, inBindings);
      then bindings;

    else
      equation
        // print("subtypePolymorphic failed: " + unparseType(actual) + " and " + unparseType(expected) + "\n");
      then fail();

  end matchcontinue;
end subtypePolymorphic;

protected function subtypePolymorphicList
"A simple subtype() that also binds polymorphic variables.
 Only works on the MetaModelica datatypes; the input is assumed to be boxed."
  input list<DAE.Type> actual;
  input list<DAE.Type> expected;
  input Option<Absyn.Path> envPath;
  input InstTypes.PolymorphicBindings ibindings;
  output InstTypes.PolymorphicBindings outBindings;
algorithm
  outBindings := match (actual,expected,envPath,ibindings)
    local
      Type ty1,ty2;
      list<DAE.Type> tList1,tList2;
      InstTypes.PolymorphicBindings bindings;
    case ({},{},_,bindings) then bindings;
    case (ty1::tList1,ty2::tList2,_,bindings)
      equation
        bindings = subtypePolymorphic(ty1,ty2,envPath,bindings);
        bindings = subtypePolymorphicList(tList1,tList2,envPath,bindings);
      then bindings;
  end match;
end subtypePolymorphicList;

public function boxVarLst
  input list<DAE.Var> vars;
  output list<DAE.Var> ovars;
algorithm
  ovars := match vars
    local
      String name;
      DAE.Attributes attributes;
      DAE.Type type_;
      DAE.Binding binding;
      Option<DAE.Const> constOfForIteratorRange;
      list<DAE.Var> rest;

    case {} then {};
    case DAE.TYPES_VAR(name,attributes,type_,binding,constOfForIteratorRange)::rest
      equation
        type_ = boxIfUnboxedType(type_);
        rest = boxVarLst(rest);
      then DAE.TYPES_VAR(name,attributes,type_,binding,constOfForIteratorRange)::rest;

  end match;
end boxVarLst;

public function liftArraySubscript "Lifts a type to an array using DAE.Subscript for dimension in the case of non-expanded arrays"
  input DAE.Type inType;
  input DAE.Subscript inSubscript;
  output DAE.Type outType;
algorithm
  outType := match (inType,inSubscript)
    local
      Type ty;
      Integer i;
      DAE.Exp e;

    // An array with an explicit dimension
    case (ty,DAE.WHOLE_NONEXP(exp=DAE.ICONST(i)))
      then DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(i)}, DAE.emptyTypeSource);

    // An array with parametric dimension
    case (ty,DAE.WHOLE_NONEXP(exp = e))
      then DAE.T_ARRAY(ty,{DAE.DIM_EXP(e)},DAE.emptyTypeSource);

    // All other kinds of subscripts denote an index, so the type stays the same
    case (ty,_)
      then ty;
  end match;
end liftArraySubscript;

public function liftArraySubscriptList "
  Lifts a type using list<DAE.Subscript> to determine dimensions in the case of non-expanded arrays"
  input DAE.Type inType;
  input list<DAE.Subscript> inSubscriptLst;
  output DAE.Type outType;
algorithm
  outType := match (inType,inSubscriptLst)
    local
      Type ty;
      DAE.Subscript sub;
      list<DAE.Subscript> rest;
    case (ty,{}) then ty;
    case (ty,sub::rest) then liftArraySubscript(liftArraySubscriptList(ty,rest),sub);
  end match;
end liftArraySubscriptList;

public function convertTupleToMetaTuple "Needed when pattern-matching"
  input DAE.Exp exp;
  input DAE.Type ty;
  output DAE.Exp oexp;
  output DAE.Type oty;
algorithm
  (oexp,oty) := match (exp,ty)
    case (DAE.TUPLE(_),_)
      equation
        /* So we can verify that the contents of the tuple is boxed */
        (oexp,oty) = matchType(exp,ty,DAE.T_METABOXED_DEFAULT,false);
      then (oexp,oty);
    else (exp,ty);
  end match;
end convertTupleToMetaTuple;

public function isFunctionType
  input DAE.Type ty;
  output Boolean b;
algorithm
  b := match ty
    case DAE.T_FUNCTION() then true;
    else false;
  end match;
end isFunctionType;

protected function prefixTraversedPolymorphicType
  input Type ty;
  input String prefix;
  output Type oty = ty;
  output String str;
algorithm
  (oty,str) := match oty
    case DAE.T_METAPOLYMORPHIC()
      algorithm
        oty.name := prefix + oty.name;
      then (oty,prefix);
    else (ty,prefix);
  end match;
end prefixTraversedPolymorphicType;

public function makeExpDimensionsUnknown
  input DAE.Type ty;
  input Integer dummy;
  output DAE.Type oty = ty;
  output Integer odummy = dummy;
algorithm
  oty := match oty
    case DAE.T_ARRAY(dims={DAE.DIM_EXP()})
      algorithm
        oty.dims := {DAE.DIM_UNKNOWN()};
      then oty;
    else oty;
  end match;
end makeExpDimensionsUnknown;

public function makeKnownDimensionsInteger "In binding equations, [Boolean] and [2] match, so we need to convert them"
  input DAE.Type ty;
  input Integer dummy;
  output DAE.Type oty = ty;
  output Integer odummy = dummy;
algorithm
  oty := match oty
    local
      Integer size;
    case DAE.T_ARRAY(dims={DAE.DIM_BOOLEAN()})
      algorithm
        oty.dims := {DAE.DIM_INTEGER(2)};
      then oty;
    case DAE.T_ARRAY(dims={DAE.DIM_ENUM(size=size)})
      algorithm
        oty.dims := {DAE.DIM_INTEGER(size)};
      then oty;
    case DAE.T_ARRAY(dims={DAE.DIM_EXP(exp=DAE.ICONST(size))})
      algorithm
        oty.dims := {DAE.DIM_INTEGER(size)};
      then oty;
    else oty;
  end match;
end makeKnownDimensionsInteger;

public function traverseType
  input DAE.Type ty;
  input A arg;
  input Func fn;
  output DAE.Type oty;
  output A a = arg;
  replaceable type A subtypeof Any;
  partial function Func
    input DAE.Type ty;
    input A arg;
    output DAE.Type oty;
    output A oarg;
  end Func;
algorithm
  (oty,a) := match ty
    local
      list<DAE.Type> tys;
      Type tyInner;
      DAE.Dimensions ad;
      DAE.TypeSource ts;
      String str;
      Integer index;
      list<DAE.Var> vars;
      Absyn.Path path;
      EqualityConstraint eq;
      ClassInf.State state;
      list<DAE.FuncArg> farg;
      DAE.FunctionAttributes functionAttributes;
      Boolean singleton, b;

    case DAE.T_INTEGER() then (ty,a);
    case DAE.T_REAL() then (ty,a);
    case DAE.T_STRING() then (ty,a);
    case DAE.T_BOOL() then (ty,a);
    case DAE.T_CLOCK() then (ty,a);
    case DAE.T_ENUMERATION() then (ty,a);
    case DAE.T_NORETCALL() then (ty,a);
    case DAE.T_UNKNOWN() then (ty,a);
    case DAE.T_METAUNIONTYPE() then (ty,a);
    case DAE.T_METAPOLYMORPHIC() then (ty,a);
    case DAE.T_CODE() then (ty,a);

    case oty as DAE.T_METABOXED()
      algorithm
        (tyInner,a) := traverseType(oty.ty, a, fn);
        oty.ty := tyInner;
      then (oty,a);
    case oty as DAE.T_ARRAY()
      algorithm
        (tyInner,a) := traverseType(oty.ty, a, fn);
        oty.ty := tyInner;
      then (oty,a);
    case oty as DAE.T_METATYPE()
      algorithm
        (tyInner,a) := traverseType(oty.ty, a, fn);
        oty.ty := tyInner;
      then (oty,a);
    case oty as DAE.T_METALIST()
      algorithm
        (tyInner, a) := traverseType(oty.ty, a, fn);
        oty.ty := tyInner;
      then (oty,a);
    case oty as DAE.T_METAOPTION()
      algorithm
        (tyInner,a) := traverseType(oty.ty, a, fn);
        oty.ty := tyInner;
      then (oty,a);
    case oty as DAE.T_METAARRAY()
      algorithm
        (tyInner,a) := traverseType(oty.ty, a, fn);
        oty.ty := tyInner;
      then (oty,a);
    case oty as DAE.T_FUNCTION_REFERENCE_VAR()
      algorithm
        (tyInner,a) := traverseType(oty.functionType, a, fn);
        oty.functionType := tyInner;
      then (oty,a);
    case oty as DAE.T_FUNCTION_REFERENCE_FUNC()
      algorithm
        (tyInner,a) := traverseType(oty.functionType, a, fn);
        oty.functionType := tyInner;
      then (oty,a);

    case oty as DAE.T_METATUPLE()
      algorithm
        (tys,a) := traverseTupleType(oty.types, a, fn);
        oty.types := tys;
      then (oty,a);
    case oty as DAE.T_TUPLE()
      algorithm
        (tys,a) := traverseTupleType(oty.types, a, fn);
        oty.types := tys;
      then (oty, a);

    case oty as DAE.T_METARECORD()
      algorithm
        (vars, a) := traverseVarTypes(oty.fields, a, fn);
        oty.fields := vars;
      then (oty, a);
    case oty as DAE.T_COMPLEX()
      algorithm
        (vars, a) := traverseVarTypes(oty.varLst, a, fn);
        oty.varLst := vars;
      then (oty, a);

    case oty as DAE.T_SUBTYPE_BASIC()
      algorithm
        (vars, a) := traverseVarTypes(oty.varLst, a, fn);
        (tyInner,a) := traverseType(oty.complexType, a, fn);
        oty.varLst := vars;
        oty.complexType := tyInner;
      then (oty, a);

    case oty as DAE.T_FUNCTION()
      algorithm
        (farg, a) := traverseFuncArg(oty.funcArg, a, fn);
        (tyInner, a) := traverseType(oty.funcResultType, a, fn);
        oty.funcArg := farg;
        oty.funcResultType := tyInner;
      then (oty, a);

    else
      equation
        str = "Types.traverseType not implemented correctly: " + unparseType(ty);
        Error.addMessage(Error.INTERNAL_ERROR,{str});
      then
        fail();
  end match;
  (oty, a) := fn(oty, a);
end traverseType;

protected function traverseTupleType
  input list<DAE.Type> itys;
  input A ia;
  input Func fn;
  output list<DAE.Type> otys;
  output A oa;
  replaceable type A subtypeof Any;
  partial function Func
    input DAE.Type ty;
    input A arg;
    output DAE.Type oty;
    output A oarg;
  end Func;
algorithm
  (otys,oa) := match (itys,ia,fn)
    local
      Type ty;
      list<DAE.Type> tys;
      A a;

    case ({},a,_) then ({},a);
    case (ty::tys,a,_)
      equation
        (ty,a) = traverseType(ty, a, fn);
        (tys,a) = traverseTupleType(tys, a, fn);
      then (ty::tys,a);
  end match;
end traverseTupleType;

protected function traverseVarTypes
  input list<DAE.Var> ivars;
  input A ia;
  input Func fn;
  output list<DAE.Var> ovars;
  output A oa;
  replaceable type A subtypeof Any;
  partial function Func
    input DAE.Type ty;
    input A arg;
    output DAE.Type oty;
    output A oarg;
  end Func;
algorithm
  (ovars,oa) := match (ivars,ia,fn)
    local
      DAE.Var var;
      DAE.Type ty;
      list<DAE.Var> vars;
      A a;

    case ({},a,_) then ({},a);
    case (var::vars,a,_)
      equation
        ty = getVarType(var);
        (ty, a) = traverseType(ty, a, fn);
        var = setVarType(var,ty);
        (vars,a) = traverseVarTypes(vars,a,fn);
      then (var::vars,a);
  end match;
end traverseVarTypes;

protected function traverseFuncArg
  input list<DAE.FuncArg> iargs;
  input A ia;
  input Func fn;
  output list<DAE.FuncArg> oargs;
  output A oa;
  replaceable type A subtypeof Any;
  partial function Func
    input DAE.Type ty;
    input A arg;
    output DAE.Type oty;
    output A oarg;
  end Func;
algorithm
  (oargs,oa) := match (iargs,ia)
    local
      String b;
      DAE.Const c;
      DAE.VarParallelism p;
      Option<DAE.Exp> d;
      list<DAE.FuncArg> args;
      A a;
      DAE.FuncArg arg;
      DAE.Type ty;

    case ({},a) then ({},a);
    case ((arg as DAE.FUNCARG())::args,a)
      equation
        (ty, a) = traverseType(arg.ty, a, fn);
        arg.ty = ty;
        (args,a) = traverseFuncArg(args,a,fn);
      then (arg::args, a);
  end match;
end traverseFuncArg;

public function makeRegularTupleFromMetaTupleOnTrue
  input Boolean b;
  input DAE.Type ty;
  output DAE.Type out;
algorithm
  out := match (b,ty)
    local
      list<DAE.Type> tys;

    case (true,DAE.T_METATUPLE(tys,_))
      equation
        tys = List.mapMap(tys, unboxedType, boxIfUnboxedType);
        tys = List.map(tys, unboxedType); // Yes. Crazy
      then (DAE.T_TUPLE(tys,NONE(),DAE.emptyTypeSource));

    case (false,_) then ty;
  end match;
end makeRegularTupleFromMetaTupleOnTrue;

public function allTuple
  input list<DAE.Type> itys;
  output Boolean b;
algorithm
  b := match itys local list<DAE.Type> tys;
    case {} then true;
    case (DAE.T_TUPLE()::tys) then allTuple(tys);
    else false;
  end match;
end allTuple;

public function unboxedFunctionType "For DAE.PARTEVALFUNC"
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match inType
    local
      list<DAE.FuncArg> args1;
      list<DAE.Type> tys1;
      list<String> names1;
      list<DAE.Const> cs1;
      list<DAE.VarParallelism> ps1;
      list<Option<DAE.Exp>> oe1;
      Type ty1;
      DAE.FunctionAttributes functionAttributes;
      DAE.TypeSource ts;

    case (DAE.T_FUNCTION(args1,ty1,functionAttributes,ts))
      equation
        tys1 = List.mapMap(args1, funcArgType, unboxedType);
        ty1 = unboxedType(ty1);
        args1 = List.threadMap(args1,tys1,setFuncArgType);
      then (DAE.T_FUNCTION(args1,ty1,functionAttributes,ts));
  end match;
end unboxedFunctionType;

public function printCodeTypeStr
  input DAE.CodeType ct;
  output String str;
algorithm
  str := match ct
    case DAE.C_EXPRESSION() then "OpenModelica.Code.Expression";
    case DAE.C_EXPRESSION_OR_MODIFICATION() then "OpenModelica.Code.ExpressionOrModification";
    case DAE.C_MODIFICATION() then "OpenModelica.Code.Modification";
    case DAE.C_TYPENAME() then "OpenModelica.Code.TypeName";
    case DAE.C_VARIABLENAME() then "OpenModelica.Code.VariableName";
    case DAE.C_VARIABLENAMES() then "OpenModelica.Code.VariableNames";
    else "Types.printCodeTypeStr failed";
  end match;
end printCodeTypeStr;

public function varHasMetaRecordType
  input DAE.Var var;
  output Boolean b;
algorithm
  b := match var
    case DAE.TYPES_VAR(ty = DAE.T_METABOXED(ty = DAE.T_METARECORD()))
      then true;
    case DAE.TYPES_VAR(ty = DAE.T_METARECORD())
      then true;
    case DAE.TYPES_VAR(ty = DAE.T_METABOXED(ty = DAE.T_COMPLEX(complexClassType = ClassInf.META_RECORD(_))))
      then true;
    else false;
  end match;
end varHasMetaRecordType;

public function scalarSuperType
  "Checks that the givens types are scalar and that one is subtype of the other (in the case of integers)."
  input DAE.Type ity1;
  input DAE.Type ity2;
  output DAE.Type ty;
algorithm
  ty := match (ity1,ity2)
    local Type ty1, ty2;
    case (DAE.T_INTEGER(),DAE.T_INTEGER()) then DAE.T_INTEGER_DEFAULT;
    case (DAE.T_REAL(),DAE.T_REAL())       then DAE.T_REAL_DEFAULT;
    case (DAE.T_INTEGER(),DAE.T_REAL())    then DAE.T_REAL_DEFAULT;
    case (DAE.T_REAL(),DAE.T_INTEGER())    then DAE.T_REAL_DEFAULT;
    case (DAE.T_SUBTYPE_BASIC(complexType = ty1),ty2)          then scalarSuperType(ty1,ty2);
    case (ty1,DAE.T_SUBTYPE_BASIC(complexType = ty2))          then scalarSuperType(ty1,ty2);

    case (DAE.T_BOOL(),DAE.T_BOOL())       then DAE.T_BOOL_DEFAULT;
    // adrpo: TODO? Why not string here?
    // case (DAE.T_STRING(varLst = _),DAE.T_STRING(varLst = _))   then DAE.T_STRING_DEFAULT;
  end match;
end scalarSuperType;

protected function optInteger
  input Option<Integer> inInt;
  output Integer outInt;
algorithm
  outInt := match(inInt)
    local Integer i;
    case (SOME(i)) then i;
    else -1;
  end match;
end optInteger;

public function typeToValue "This function builds Values.Value out of a type using generated bindings."
  input DAE.Type inType;
  output Values.Value defaultValue;
algorithm
  defaultValue := matchcontinue (inType)
    local
      list<DAE.Var> vars;
      list<String> comp;
      ClassInf.State st;
      Type t;
      list<DAE.Type> tys;
      String s1;
      Absyn.Path path;
      Integer i;
      Option<Integer> iOpt;
      Values.Value v;
      list<Values.Value> valueLst, ordered;

    case (DAE.T_INTEGER()) then Values.INTEGER(0);
    case (DAE.T_REAL()) then Values.REAL(0.0);
    case (DAE.T_STRING()) then Values.STRING("<EMPTY>");
    case (DAE.T_BOOL()) then Values.BOOL(false);
    case (DAE.T_ENUMERATION(index = iOpt, path = path))
      equation
        i = optInteger(iOpt);
      then
        Values.ENUM_LITERAL(path, i);

    case (DAE.T_COMPLEX(complexClassType = st,varLst = vars))
      equation
        (ordered, comp) = varsToValues(vars);
        path = ClassInf.getStateName(st);
      then
        Values.RECORD(path, ordered, comp, -1);

    case (DAE.T_SUBTYPE_BASIC(complexType = t))
      equation
        v = typeToValue(t);
      then
        v;

    case (DAE.T_ARRAY(dims = {DAE.DIM_INTEGER(i)},ty = t))
      equation
        v = typeToValue(t);
        valueLst = List.fill(v, i);
      then
        Values.ARRAY(valueLst, {i});

    case (DAE.T_TUPLE(types = tys))
      equation
        valueLst = List.map(tys, typeToValue);
        v = Values.TUPLE(valueLst);
      then
        v;

    // All the other ones we don't handle
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Types.typeToValue failed on unhandled Type ");
        s1 = printTypeStr(inType);
        Debug.traceln(s1);
      then
        fail();

  end matchcontinue;
end typeToValue;

public function varsToValues "Translates a list of Var list to Values.Value, the
  names of the variables as component names.
  Used e.g. when retrieving the type of a record value."
  input list<DAE.Var> inVarLst;
  output list<Values.Value> outValuesValueLst;
  output list<String> outExpIdentLst;
algorithm
  (outValuesValueLst,outExpIdentLst) := matchcontinue (inVarLst)
    local
      DAE.Type tp;
      list<DAE.Var> rest;
      Values.Value v;
      list<Values.Value> restVals;
      String id;
      list<String> restIds;

    case ({}) then ({}, {});

    case (DAE.TYPES_VAR(name = id,ty = tp)::rest)
      equation
        v = typeToValue(tp);
        (restVals, restIds) = varsToValues(rest);
      then
        (v::restVals, id::restIds);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Types.varsToValues failed\n");
      then
        fail();
  end matchcontinue;
end varsToValues;

public function makeNthDimUnknown
  "Real [3,2,1],3 => Real [3,2,:]"
  input DAE.Type ty;
  input Integer dim;
  output DAE.Type oty;
algorithm
  oty := match (ty,dim)
    local
      DAE.Dimension ad;
      Type ty1;
      DAE.TypeSource ts;

    case (DAE.T_ARRAY(ty1,{_},ts),1) then DAE.T_ARRAY(ty1,{DAE.DIM_UNKNOWN()},ts);
    case (DAE.T_ARRAY(ty1,{ad},ts),_)
      equation
        ty1 = makeNthDimUnknown(ty1,dim-1);
      then
        DAE.T_ARRAY(ty1,{ad},ts);
  end match;
end makeNthDimUnknown;

public function arraySuperType
  "Selects the supertype out of two array-types. Integer may be promoted to Real."
  input DAE.Type ity1;
  input SourceInfo info;
  input DAE.Type ity2;
  output DAE.Type ty;
algorithm
  ty := matchcontinue (ity1,info,ity2)
    local
      String str1,str2;
      Type ty1, ty2;
    case (ty1,_,ty2)
      equation
        true = isInteger(arrayElementType(ty1));
        true = isReal(arrayElementType(ty2));
        ty1 = traverseType(ty1, -1, replaceIntegerTypeWithReal);
        true = subtype(ty1,ty2);
      then ty1;
    case (ty1,_,ty2)
      equation
        true = isInteger(arrayElementType(ty2));
        true = isReal(arrayElementType(ty1));
        ty2 = traverseType(ty2, -1, replaceIntegerTypeWithReal);
        true = subtype(ty1,ty2);
      then ty1;
    case (ty1,_,ty2)
      equation
        true = subtype(ty1,ty2);
      then ty1;
    case (ty1,_,ty2)
      equation
        str1 = unparseType(ty1);
        str2 = unparseType(ty2);
        typeErrorSanityCheck(str1, str2, info);
        Error.addSourceMessage(Error.ARRAY_TYPE_MISMATCH,{str1,str2},info);
      then fail();
  end matchcontinue;
end arraySuperType;

protected function replaceIntegerTypeWithReal
  input Type ty;
  input Integer dummy;
  output Type oty;
  output Integer odummy = dummy;
algorithm
  oty := match ty
    case DAE.T_INTEGER() then DAE.T_REAL_DEFAULT;
    else ty;
  end match;
end replaceIntegerTypeWithReal;

public function isZeroLengthArray
  input DAE.Type ty;
  output Boolean res;
algorithm
  res := match ty
    local
      list<DAE.Dimension> dims;
    case DAE.T_ARRAY(dims = dims)
      equation
        res = List.fold(dims, isZeroDim, false);
      then res;
    else false;
  end match;
end isZeroLengthArray;

protected function isZeroDim "Check dimensions by folding and checking for zeroes"
  input DAE.Dimension dim;
  input Boolean acc;
  output Boolean res;
algorithm
  res := match (dim,acc)
    case (DAE.DIM_INTEGER(integer=0),_) then true;
    case (DAE.DIM_ENUM(size=0),_) then true;
    else acc;
  end match;
end isZeroDim;

public function variabilityToConst "translates an SCode.Variability to a DAE.Const"
  input SCode.Variability variability;
  output DAE.Const const;
algorithm
  const := match(variability)
    case(SCode.VAR())      then DAE.C_VAR();
    case(SCode.DISCRETE()) then DAE.C_VAR();
    case(SCode.PARAM())    then DAE.C_PARAM();
    case(SCode.CONST())    then DAE.C_CONST();
  end match;
end variabilityToConst;

public function varKindToConst "translates an DAE.varKind to a DAE.Const"
  input DAE.VarKind varKind;
  output DAE.Const const;
algorithm
  const := match(varKind)
    case(DAE.VARIABLE()) then DAE.C_VAR();
    case(DAE.DISCRETE()) then DAE.C_VAR();
    case(DAE.PARAM())    then DAE.C_PARAM();
    case(DAE.CONST())    then DAE.C_CONST();
  end match;
end varKindToConst;

public function isValidFunctionVarType
  input DAE.Type inType;
  output Boolean outIsValid;
algorithm
  outIsValid := match(inType)
    local
      Type ty;
      ClassInf.State state;

    case (DAE.T_COMPLEX(complexClassType = state))
      then isValidFunctionVarState(state);

    case (DAE.T_SUBTYPE_BASIC(complexType = ty))
      then isValidFunctionVarType(ty);

    else true;

  end match;
end isValidFunctionVarType;

protected function isValidFunctionVarState
  input ClassInf.State inState;
  output Boolean outIsValid;
algorithm
  outIsValid := match(inState)
    case ClassInf.MODEL() then false;
    case ClassInf.BLOCK() then false;
    case ClassInf.CONNECTOR() then false;
    case ClassInf.OPTIMIZATION() then false;
    case ClassInf.PACKAGE() then false;
    else true;
  end match;
end isValidFunctionVarState;

protected function makeDummyExpFromType
  "Creates a dummy expression from a type. Used by typeConvertArray to handle
  empty arrays."
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := match(inType)
    local
      Absyn.Path p;
      Type ty;
      DAE.Dimension dim;
      Integer idim;
      DAE.Exp exp;
      list<DAE.Exp> expl;
      DAE.Type ety;

    case (DAE.T_INTEGER()) then DAE.ICONST(0);
    case (DAE.T_REAL()) then DAE.RCONST(0.0);
    case (DAE.T_STRING()) then DAE.SCONST("");
    case (DAE.T_BOOL()) then DAE.BCONST(false);
    case (DAE.T_ENUMERATION(path = p)) then DAE.ENUM_LITERAL(p, 1);
    case (DAE.T_ARRAY(ty = ty, dims = {dim}))
      equation
        idim = Expression.dimensionSize(dim);
        exp = makeDummyExpFromType(ty);
        ety = Expression.typeof(exp);
        ety = Expression.liftArrayLeft(ety, dim);
        expl = List.fill(exp, idim);
      then
        DAE.ARRAY(ety, true, expl);

  end match;
end makeDummyExpFromType;

public function printExpTypeStr
  input DAE.Type iet;
  output String str;
algorithm
  str := printTypeStr(expTypetoTypesType(iet));
end printExpTypeStr;

public function isUnknownType
  "Return true if the type is DAE.T_UNKNOWN or DAE.T_ANYTYPE"
  input DAE.Type inType;
  output Boolean b;
algorithm
  b := match(inType)
    case (DAE.T_UNKNOWN()) then true;
    case (DAE.T_ANYTYPE()) then true;
    else false;
  end match;
end isUnknownType;

public function mkTypeSource
  input Option<Absyn.Path> inPathOpt;
  output DAE.TypeSource source;
algorithm
  source := match(inPathOpt)
    local Absyn.Path p;
    case (SOME(p)) then {p};
    case (NONE())  then DAE.emptyTypeSource;
  end match;
end mkTypeSource;

public function getTypeSource
  input DAE.Type inType;
  output DAE.TypeSource outTypeSource;
algorithm
  outTypeSource := match(inType)
    local
      DAE.TypeSource source;

    case (DAE.T_INTEGER(source =  source)) then source;
    case (DAE.T_REAL(source =  source)) then source;
    case (DAE.T_STRING(source =  source)) then source;
    case (DAE.T_BOOL(source =  source)) then source;
    // BTH
    case (DAE.T_CLOCK(source =  source)) then source;
    case (DAE.T_ENUMERATION(source =  source)) then source;

    case (DAE.T_ARRAY(source =  source)) then source;
    case (DAE.T_NORETCALL(source =  source)) then source;
    case (DAE.T_UNKNOWN(source =  source)) then source;
    case (DAE.T_COMPLEX(source =  source)) then source;
    case (DAE.T_SUBTYPE_BASIC(source =  source)) then source;
    case (DAE.T_FUNCTION(source =  source)) then source;
    case (DAE.T_FUNCTION_REFERENCE_VAR(source =  source)) then source;
    case (DAE.T_FUNCTION_REFERENCE_FUNC(source =  source)) then source;
    case (DAE.T_TUPLE(source =  source)) then source;
    case (DAE.T_CODE(source =  source)) then source;
    case (DAE.T_ANYTYPE(source =  source)) then source;

    case (DAE.T_METALIST(source =  source)) then source;
    case (DAE.T_METATUPLE(source =  source)) then source;
    case (DAE.T_METAOPTION(source =  source)) then source;
    case (DAE.T_METAUNIONTYPE(source =  source)) then source;
    case (DAE.T_METARECORD(source =  source)) then source;
    case (DAE.T_METAARRAY(source =  source)) then source;
    case (DAE.T_METABOXED(source =  source)) then source;
    case (DAE.T_METAPOLYMORPHIC(source =  source)) then source;
    case (DAE.T_METATYPE(source =  source)) then source;
  end match;
end getTypeSource;

public function setTypeSource
  input DAE.Type inType;
  input DAE.TypeSource inTypeSource;
  output DAE.Type outType;
algorithm
  outType := matchcontinue(inType, inTypeSource)
    local
      DAE.TypeSource s, ts;
      list<DAE.Var> v, al;
      Option<Integer> oi;
      Integer i;
      Absyn.Path p;
      list<Absyn.Path> ps;
      list<String> n;
      DAE.Dimensions dims;
      DAE.Type t;
      ClassInf.State cis;
      Option<ClassInf.State> ocis;
      DAE.EqualityConstraint ec;
      list<DAE.FuncArg> funcArg ;
      Type funcRType;
      DAE.FunctionAttributes funcAttr;
      Boolean b;
      list<DAE.Type> tys, typeVars;
      DAE.CodeType ct;
      String str;

    case (DAE.T_INTEGER(v, _), ts) then DAE.T_INTEGER(v, ts);
    case (DAE.T_REAL(v, _), ts) then DAE.T_REAL(v, ts);
    case (DAE.T_STRING(v, _), ts) then DAE.T_STRING(v, ts);
    case (DAE.T_BOOL(v, _), ts) then DAE.T_BOOL(v, ts);
    case (DAE.T_ENUMERATION(oi, p, n, v, al, _), ts) then DAE.T_ENUMERATION(oi, p, n, v, al, ts);

    case (DAE.T_ARRAY(t, dims, _), ts) then DAE.T_ARRAY(t, dims, ts);
    case (DAE.T_NORETCALL(_),ts) then DAE.T_NORETCALL(ts);
    case (DAE.T_UNKNOWN(_),ts) then DAE.T_UNKNOWN(ts);
    case (DAE.T_COMPLEX(cis, v, ec, _), ts) then DAE.T_COMPLEX(cis, v, ec, ts);
    case (DAE.T_SUBTYPE_BASIC(cis, v, t, ec, _), ts) then DAE.T_SUBTYPE_BASIC(cis, v, t, ec, ts);
    case (DAE.T_FUNCTION(funcArg, funcRType, funcAttr, _), ts) then DAE.T_FUNCTION(funcArg, funcRType, funcAttr, ts);
    case (DAE.T_FUNCTION_REFERENCE_VAR(t, _), ts) then DAE.T_FUNCTION_REFERENCE_VAR(t, ts);
    case (DAE.T_FUNCTION_REFERENCE_FUNC(b, t, _), ts) then DAE.T_FUNCTION_REFERENCE_FUNC(b, t, ts);
    case (t as DAE.T_TUPLE(), ts)
      algorithm
        t.source := ts;
      then t;
    case (DAE.T_CODE(ct, _), ts) then DAE.T_CODE(ct, ts);
    case (DAE.T_ANYTYPE(ocis, s), _) then DAE.T_ANYTYPE(ocis, s);

    case (DAE.T_METALIST(t, _), ts) then DAE.T_METALIST(t, ts);
    case (DAE.T_METATUPLE(tys, _), ts) then DAE.T_METATUPLE(tys, ts);
    case (DAE.T_METAOPTION(t, _), ts) then DAE.T_METAOPTION(t, ts);
    case (t as DAE.T_METAUNIONTYPE(), ts)
      algorithm
        t.source := ts;
      then t;
    case (DAE.T_METARECORD(p, typeVars, i, v, b, _), ts) then DAE.T_METARECORD(p, typeVars, i, v, b, ts);
    case (DAE.T_METAARRAY(t, _), ts) then DAE.T_METAARRAY(t, ts);
    case (DAE.T_METABOXED(t, _), ts) then DAE.T_METABOXED(t, ts);
    case (DAE.T_METAPOLYMORPHIC(str, _), ts) then DAE.T_METAPOLYMORPHIC(str, ts);
    case (DAE.T_METATYPE(t, _), ts) then DAE.T_METATYPE(t, ts);
    case (t,ts)
      equation
        print("Could not set type source:" + printTypeSourceStr(ts) + " in type: " +
          printTypeStr(t) + "\n");
      then
        t;
  end matchcontinue;
end setTypeSource;

public function printTypeSourceStr
  input DAE.TypeSource tySource;
  output String str;
algorithm
  str := matchcontinue(tySource)
    local DAE.TypeSource ts; String s;
    // no type source
    case ({}) then "";
    // yeha, we have some
    case (ts)
      equation
        s = " origin: " + stringDelimitList(list(Absyn.pathString(t) for t in ts), ", ");
      then
        s;
  end matchcontinue;
end printTypeSourceStr;

public function isOverdeterminedType
  "Returns true if the given type is overdetermined, i.e. a type or record with
   an equalityConstraint function, otherwise false."
  input DAE.Type inType;
  output Boolean outIsOverdetermined;
algorithm
  outIsOverdetermined := match(inType)
    local
      ClassInf.State cct;

    case DAE.T_COMPLEX(complexClassType = cct, equalityConstraint = SOME(_))
      then ClassInf.isTypeOrRecord(cct);

    case DAE.T_SUBTYPE_BASIC(equalityConstraint = SOME(_)) then true;
  end match;
end isOverdeterminedType;

public function hasMetaArray
  input DAE.Type ty;
  output Boolean b;
algorithm
  (_,b) := traverseType(ty, false, hasMetaArrayWork);
end hasMetaArray;

protected function hasMetaArrayWork
  input Type ty;
  input Boolean b;
  output Type oty = ty;
  output Boolean ob = b;
algorithm
  if not b then
    ob := match ty
      case DAE.T_METAARRAY() then true;
      else false;
    end match;
  end if;
end hasMetaArrayWork;

protected function classTypeEqualIfRecord
  input ClassInf.State st1;
  input ClassInf.State st2;
  output Boolean b;
algorithm
  b := match (st1,st2)
    local
      Absyn.Path p1,p2;
    case (ClassInf.RECORD(p1),ClassInf.RECORD(p2)) then Absyn.pathEqual(p1,p2);
    else true;
  end match;
end classTypeEqualIfRecord;

public function ifExpMakeDimsUnknown "If one branch of an if-expression has truly unknown dimensions they both will need to return unknown dimensions for type-checking to work"
  input DAE.Type ty1;
  input DAE.Type ty2;
  output DAE.Type oty1;
  output DAE.Type oty2;
algorithm
  (oty1,oty2) := match (ty1,ty2)
    local
      DAE.Type inner1,inner2;
      DAE.TypeSource ts1,ts2;
      DAE.Dimension d1,d2;
    case (DAE.T_ARRAY(ty=inner1,dims={DAE.DIM_UNKNOWN()},source=ts1),DAE.T_ARRAY(ty=inner2,dims={_},source=ts2))
      equation
        (oty1,oty2) = ifExpMakeDimsUnknown(inner1,inner2);
      then (DAE.T_ARRAY(inner1,DAE.DIM_UNKNOWN()::{},ts1),DAE.T_ARRAY(inner2,DAE.DIM_UNKNOWN()::{},ts2));
    case (DAE.T_ARRAY(ty=inner1,dims={_},source=ts1),DAE.T_ARRAY(ty=inner2,dims={DAE.DIM_UNKNOWN()},source=ts2))
      equation
        (oty1,oty2) = ifExpMakeDimsUnknown(inner1,inner2);
      then (DAE.T_ARRAY(inner1,DAE.DIM_UNKNOWN()::{},ts1),DAE.T_ARRAY(inner2,DAE.DIM_UNKNOWN()::{},ts2));
    case (DAE.T_ARRAY(ty=inner1,dims={d1},source=ts1),DAE.T_ARRAY(ty=inner2,dims={d2},source=ts2))
      equation
        (oty1,oty2) = ifExpMakeDimsUnknown(inner1,inner2);
      then (DAE.T_ARRAY(inner1,{d1},ts1),DAE.T_ARRAY(inner2,{d2},ts2));
    else (ty1,ty2);
  end match;
end ifExpMakeDimsUnknown;

public function isFixedWithNoBinding
"check if the type has bindings for everything
 if is parameter or constant without fixed = false
 specified otherwise"
  input DAE.Type inTy;
  input SCode.Variability inVariability;
  output Boolean outFixed;
algorithm
  outFixed := matchcontinue(inTy, inVariability)
    local
      Boolean b;
      list<DAE.Var> vl;

    case (_, _)
      equation
        // if this function doesn't fail return its value
        b = getFixedVarAttribute(inTy);
      then
        b;

    case (DAE.T_COMPLEX(varLst = vl), _)
      equation
        true = allHaveBindings(vl);
      then
        false;

    // we couldn't get the fixed attribute
    // assume true for constants and parameters
    // false otherwise
    else
      equation
        b = listMember(inVariability, {SCode.PARAM(), SCode.CONST()});
      then
        b;

  end matchcontinue;
end isFixedWithNoBinding;

public function allHaveBindings
  input list<DAE.Var> inVars;
  output Boolean b;
algorithm
  b := matchcontinue(inVars)
    local
      DAE.Var v;
      list<DAE.Var> rest;

    case ({}) then true;

    case (v::_)
      equation
        false = hasBinding(v);
      then
        false;

    case (v::rest)
      equation
        true = hasBinding(v);
        true = allHaveBindings(rest);
      then
        true;

  end matchcontinue;
end allHaveBindings;

public function hasBinding
  input DAE.Var inVar;
  output Boolean b;
algorithm
  b := match (inVar)
    case (DAE.TYPES_VAR(binding = DAE.UNBOUND())) then false;
    else true;
  end match;
end hasBinding;

public function typeErrorSanityCheck
  input String inType1;
  input String inType2;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inType1, inType2, inInfo)
    case (_, _, _)
      equation
        false = stringEq(inType1, inType2);
      then
        ();

    else
      equation
        Error.addSourceMessage(Error.ERRONEOUS_TYPE_ERROR, {inType1}, inInfo);
      then
        fail();

  end matchcontinue;
end typeErrorSanityCheck;

public function dimNotFixed
  input DAE.Dimension dim;
  output Boolean b;
algorithm
  b := match dim
    case DAE.DIM_UNKNOWN() then true;
    case DAE.DIM_EXP() then true;
    else false;
  end match;
end dimNotFixed;

function isArrayWithUnknownDimension
  input DAE.Type ty;
  output Boolean b;
algorithm
  b := match ty
    case DAE.T_ARRAY() then max(
        match d case DAE.DIM_UNKNOWN() then true; else false; end match
      for d in getDimensions(ty));
    else false;
  end match;
end isArrayWithUnknownDimension;

public function stripTypeVars
  "Strips the attribute variables from a type, and returns both the stripped
   type and the attribute variables."
  input DAE.Type inType;
  output DAE.Type outType;
  output list<DAE.Var> outVars;
algorithm
  (outType, outVars) := match(inType)
    local
      list<DAE.Var> vars, sub_vars;
      DAE.TypeSource src;
      DAE.Type ty;
      DAE.Dimensions dims;
      ClassInf.State state;
      EqualityConstraint ec;
      list<DAE.Type> tys;

    case DAE.T_INTEGER(vars, src) then (DAE.T_INTEGER({}, src), vars);
    case DAE.T_REAL(vars, src)    then (DAE.T_REAL({}, src), vars);
    case DAE.T_STRING(vars, src)  then (DAE.T_STRING({}, src), vars);
    case DAE.T_BOOL(vars, src)    then (DAE.T_BOOL({}, src), vars);
    case DAE.T_TUPLE(tys, _, src) then (DAE.T_TUPLE(tys, NONE(), src), {});

    case DAE.T_ARRAY(ty, dims, src)
      equation
        (ty, vars) = stripTypeVars(ty);
      then
        (DAE.T_ARRAY(ty, dims, src), vars);

    case DAE.T_SUBTYPE_BASIC(state, sub_vars, ty, ec, src)
      equation
        (ty, vars) = stripTypeVars(ty);
      then
        (DAE.T_SUBTYPE_BASIC(state, sub_vars, ty, ec, src), vars);

    else (inType, {});

  end match;
end stripTypeVars;

public function setTypeVars
  input DAE.Type inType;
  input list<DAE.Var> inVars;
  output DAE.Type outType;
algorithm
  outType := match(inType, inVars)
    local
      DAE.TypeSource src;
      Option<Integer> i;
      Absyn.Path p;
      list<String> n;
      list<Var> vars;
      DAE.Type ty;
      DAE.Dimensions dims;
      ClassInf.State st;
      DAE.EqualityConstraint ec;

    case (DAE.T_REAL(_, src), _) then DAE.T_REAL(inVars, src);
    case (DAE.T_INTEGER(_, src), _) then DAE.T_INTEGER(inVars, src);
    case (DAE.T_STRING(_, src), _) then DAE.T_STRING(inVars, src);
    case (DAE.T_BOOL(_, src), _) then DAE.T_BOOL(inVars, src);
    // BTH
    case (DAE.T_CLOCK(_, src), _) then DAE.T_CLOCK(inVars, src);
    case (DAE.T_ENUMERATION(i, p, n, vars, _, src), _)
      then DAE.T_ENUMERATION(i, p, n, vars, inVars, src);

    case (DAE.T_ARRAY(ty, dims, src), _)
      equation
        ty = setTypeVars(ty, inVars);
      then
        DAE.T_ARRAY(ty, dims, src);

    case (DAE.T_SUBTYPE_BASIC(st, vars, ty, ec, src), _)
      equation
        ty = setTypeVars(ty, inVars);
      then
        DAE.T_SUBTYPE_BASIC(st, vars, ty, ec, src);

  end match;
end setTypeVars;

public function isEmptyOrNoRetcall
  input DAE.Type ty;
  output Boolean b;
algorithm
  b := match ty
    case DAE.T_TUPLE(types={}) then true;
    case DAE.T_METATUPLE(types={}) then true;
    case DAE.T_NORETCALL() then true;
    else false;
  end match;
end isEmptyOrNoRetcall;

protected function typeConvertIntToEnumCheck "
  Deal with the invalid conversions from Integer to enumeration.
  If the Integer corresponds to the Integer(ENUM) value of some enumeration constant ENUM,
  just give a warning, otherwise report an error.
  Returns false if an error was reported, otherwise true.
"
  input DAE.Exp exp;
  input DAE.Type expected;
  output Boolean conversionOK;
algorithm
  conversionOK := matchcontinue (exp, expected)
    local
      Integer oi;
      Absyn.Path tp;
      list<String> l;
      String pathStr, intStr, enumConst, lengthStr;
    case (DAE.ICONST(oi),
          DAE.T_ENUMERATION(path = tp, names = l))
      equation
        true = (1 <= oi and oi <= listLength(l));
        pathStr = Absyn.pathString(tp);
        intStr = intString(oi);
        enumConst = listGet(l, oi);
        Error.addMessage(Error.INTEGER_ENUMERATION_CONVERSION_WARNING, {intStr, pathStr, enumConst});
      then true;
    case (DAE.ICONST(oi),
          DAE.T_ENUMERATION(path = tp, names = l))
      equation
        pathStr = Absyn.pathString(tp);
        false = stringEq(pathStr, "");
        intStr = intString(oi);
        lengthStr = intString(listLength(l));
        Error.addMessage(Error.INTEGER_ENUMERATION_OUT_OF_RANGE, {pathStr, intStr, lengthStr});
      then false;
    case (DAE.ICONST(oi),
          DAE.T_ENUMERATION(path = tp))
      equation
        pathStr = Absyn.pathString(tp);
        true = stringEq(pathStr, "");
        intStr = intString(oi);
        Error.addMessage(Error.INTEGER_TO_UNKNOWN_ENUMERATION, {intStr});
      then false;
  end matchcontinue;
end typeConvertIntToEnumCheck;

public function findVarIndex
  input String id;
  input list<DAE.Var> vars;
  output Integer index;
algorithm
  index := List.position1OnTrue(vars,selectVar,id)-1 "shift to zero-based index";
end findVarIndex;

protected function selectVar
  input DAE.Var var;
  input String id;
  output Boolean b;
algorithm
  b := match var
    local
      String id1;
    case DAE.TYPES_VAR(name=id1) then stringEq(id,id1);
    else false;
  end match;
end selectVar;

public function getUniontypeIfMetarecord
  input DAE.Type inTy;
  output DAE.Type ty;
algorithm
  ty := match inTy
    local
      Boolean b;
      Absyn.Path p;
    case DAE.T_METARECORD(utPath=p,knownSingleton=b) then DAE.T_METAUNIONTYPE({},inTy.typeVars,b,if b then DAE.EVAL_SINGLETON_KNOWN_TYPE(inTy) else DAE.NOT_SINGLETON(),{p});
    else inTy;
  end match;
end getUniontypeIfMetarecord;

public function getUniontypeIfMetarecordReplaceAllSubtypes
  input DAE.Type inTy;
  output DAE.Type ty;
algorithm
  (ty,_) := traverseType(inTy, 1, getUniontypeIfMetarecordTraverse);
end getUniontypeIfMetarecordReplaceAllSubtypes;

protected function getUniontypeIfMetarecordTraverse
  input DAE.Type ty;
  input Integer dummy;
  output DAE.Type oty;
  output Integer odummy = dummy;
algorithm
  oty := match ty
    case DAE.T_METARECORD() then DAE.T_METAUNIONTYPE({},ty.typeVars,ty.knownSingleton,if ty.knownSingleton then DAE.EVAL_SINGLETON_KNOWN_TYPE(ty) else DAE.NOT_SINGLETON(),{ty.utPath});
    else ty;
  end match;
end getUniontypeIfMetarecordTraverse;

protected function isBuiltin
  input DAE.FunctionBuiltin a;
  output Boolean b;
algorithm
  b := match a
    case DAE.FUNCTION_NOT_BUILTIN() then false;
    else true;
  end match;
end isBuiltin;

public function makeCallAttr
  input DAE.Type ty;
  input DAE.FunctionAttributes attr;
  output DAE.CallAttributes callAttr;
protected
  Boolean isImpure,isT,isB;
  DAE.FunctionBuiltin isbuiltin;
  DAE.InlineType isinline;
algorithm
  DAE.FUNCTION_ATTRIBUTES(isBuiltin=isbuiltin,isImpure=isImpure,inline=isinline) := attr;
  isT := isTuple(ty);
  isB := isBuiltin(isbuiltin);
  callAttr := DAE.CALL_ATTR(ty,isT,isB,isImpure,false,isinline,DAE.NO_TAIL());
end makeCallAttr;

public function getFuncArg
  input DAE.Type ty;
  output list<DAE.FuncArg> args;
algorithm
  DAE.T_FUNCTION(funcArg=args) := ty;
end getFuncArg;

public function isArray1D
  input DAE.Type inType;
  output Boolean b;
algorithm
  b := match inType
    local
      DAE.Type ty;
    case DAE.T_ARRAY(ty = ty) then not arrayType(ty);
    else false;
  end match;
end isArray1D;

public function isArray2D
  input DAE.Type inType;
  output Boolean b;
algorithm
  b := match inType
    local
      DAE.Type ty;
    case DAE.T_ARRAY(ty = DAE.T_ARRAY(ty = ty)) then not arrayType(ty);
    else false;
  end match;
end isArray2D;

public function funcArgName
  input DAE.FuncArg arg;
  output String name;
algorithm
  DAE.FUNCARG(name=name) := arg;
end funcArgName;

public function funcArgType
  input DAE.FuncArg arg;
  output DAE.Type ty;
algorithm
  DAE.FUNCARG(ty=ty) := arg;
end funcArgType;

public function funcArgDefaultBinding
  input DAE.FuncArg arg;
  output Option<DAE.Exp> defaultBinding;
algorithm
  DAE.FUNCARG(defaultBinding=defaultBinding) := arg;
end funcArgDefaultBinding;

public function setFuncArgType
  input DAE.FuncArg arg;
  input DAE.Type ty;
  output DAE.FuncArg outArg;
protected
  String name;
  DAE.Const const;
  DAE.VarParallelism par;
  Option<DAE.Exp> defaultBinding;
algorithm
  DAE.FUNCARG(name,_,const,par,defaultBinding) := arg;
  outArg := DAE.FUNCARG(name,ty,const,par,defaultBinding);
end setFuncArgType;

public function setFuncArgName
  input DAE.FuncArg arg;
  input String name;
  output DAE.FuncArg outArg;
protected
  DAE.Type ty;
  DAE.Const const;
  DAE.VarParallelism par;
  Option<DAE.Exp> defaultBinding;
algorithm
  DAE.FUNCARG(_,ty,const,par,defaultBinding) := arg;
  outArg := DAE.FUNCARG(name,ty,const,par,defaultBinding);
end setFuncArgName;

public function clearDefaultBinding
  input DAE.FuncArg arg;
  output DAE.FuncArg outArg;
protected
  String name;
  DAE.Type ty;
  DAE.Const const;
  DAE.VarParallelism par;
algorithm
  DAE.FUNCARG(name,ty,const,par,_) := arg;
  outArg := DAE.FUNCARG(name,ty,const,par,NONE());
end clearDefaultBinding;

public function makeDefaultFuncArg
  input String name;
  input DAE.Type ty;
  output DAE.FuncArg arg;
algorithm
  arg := DAE.FUNCARG(name,ty,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE());
end makeDefaultFuncArg;

public function setIsFunctionPointer
  input DAE.Type ty;
  input Integer dummy;
  output DAE.Type oty = ty;
  output Integer odummy = dummy;
algorithm
  oty := match oty
    local
      DAE.FunctionAttributes attr;
    case DAE.T_FUNCTION(functionAttributes=attr as DAE.FUNCTION_ATTRIBUTES(isFunctionPointer=false))
      algorithm
        attr.isFunctionPointer := true;
        oty.functionAttributes := attr;
      then oty;
    else oty;
  end match;
end setIsFunctionPointer;

public function isFunctionReferenceVar
  input DAE.Type ty;
  output Boolean b;
algorithm
  b := match ty
    case DAE.T_FUNCTION_REFERENCE_VAR() then true;
    else false;
  end match;
end isFunctionReferenceVar;

public function isFunctionPointer
  input DAE.Type inType;
  output Boolean outIsFunPtr;
algorithm
  outIsFunPtr := match inType
    case DAE.T_FUNCTION(functionAttributes =
      DAE.FUNCTION_ATTRIBUTES(isFunctionPointer = true)) then true;
    else false;
  end match;
end isFunctionPointer;

public function filterRecordComponents
  input list<DAE.Var> inRecordVars;
  input SourceInfo inInfo;
  output list<DAE.Var> outRecordVars;
algorithm
  outRecordVars := list(match v case DAE.TYPES_VAR()
    algorithm
      if not allowedInRecord(v.ty) then
        Error.addSourceMessage(Error.ILLEGAL_RECORD_COMPONENT, {unparseVar(v)}, inInfo);
        fail();
      end if;
    then v;
    end match for v in inRecordVars
  );
end filterRecordComponents;

public function allowedInRecord
  input DAE.Type ty;
  output Boolean yes;
algorithm
  yes := matchcontinue(ty)
    local DAE.Type t;

    // basic types, records or arrays of the same
    case (_)
      equation
        t = arrayElementType(ty);
        true = basicType(t) or isRecord(t) or extendsBasicType(t);
      then
        true;

    // nothing else please!
    else false;

  end matchcontinue;
end allowedInRecord;

public function lookupIndexInMetaRecord
  input list<DAE.Var> vars;
  input String name;
  output Integer index;
algorithm
  index := List.position1OnTrue(vars, DAEUtil.typeVarIdentEqual, name);
end lookupIndexInMetaRecord;

function checkEnumDuplicateLiterals
  input list<String> names;
  input Absyn.Info info;
protected
  list<String> sortedNames;
algorithm
  // Sort+uniq = O(n*log(n)); naive way to check duplicates is O(n*n) but might be faster...
  sortedNames := List.sort(names,Util.strcmpBool);
  if not List.sortedListAllUnique(sortedNames, stringEq) then
    Error.addSourceMessage(Error.ENUM_DUPLICATES, {stringDelimitList(List.sortedUniqueOnlyDuplicates(sortedNames, stringEq), ","), stringDelimitList(names, ",")}, info);
    fail();
  end if;
end checkEnumDuplicateLiterals;

public function checkTypeCompat
  "This function checks that two types are compatible, as per the definition of
   type compatible expressions in the specification. If needed it also does type
   casting to make the expressions compatible. If the types are compatible it
   returns the compatible type, otherwise the type returned is undefined."
  input DAE.Exp inExp1;
  input DAE.Type inType1;
  input DAE.Exp inExp2;
  input DAE.Type inType2;
  input Boolean inAllowUnknown = false;
  output DAE.Exp outExp1 = inExp1;
  output DAE.Exp outExp2 = inExp2;
  output DAE.Type outCompatType;
  output Boolean outCompatible = true;
protected
  DAE.Type ty1, ty2;
algorithm
  // Return true if the references are the same.
  if referenceEq(inType1, inType2) then
    outCompatType := inType1;
    return;
  end if;

  // Check if the types are different kinds of types.
  if valueConstructor(inType1) <> valueConstructor(inType2) then
    if extendsBasicType(inType1) or extendsBasicType(inType2) then
      // If either type extends a basic type, check the basic type instead.
      ty1 := derivedBasicType(inType1);
      ty2 := derivedBasicType(inType2);
      (outExp1, outExp2, outCompatType, outCompatible) :=
      checkTypeCompat(inExp1, ty1, inExp2, ty2);
    else
      // If the types are not of the same kind they might need to be type cast
      // to become compatible.
      (outExp1, outExp2, outCompatType, outCompatible) :=
      checkTypeCompat_cast(inExp1, inType1, inExp2, inType2, inAllowUnknown);
    end if;

    // Regardless of the chosen branch above, we are done here.
    return;
  end if;

  // The types are of the same kind, so we only need to match on one of them
  // (which is a lot more efficient than matching both).
  outCompatType := match(inType1)
    local
      list<DAE.Dimension> dims1, dims2;
      DAE.Type ety1, ety2, ty;
      list<String> names;
      list<DAE.Var> vars;
      list<FuncArg> args;
      list<DAE.Type> tys, tys2;
      String name;
      Absyn.Path p1, p2;

    // Basic types, must be the same.
    case DAE.T_INTEGER() then DAE.T_INTEGER_DEFAULT;
    case DAE.T_REAL() then DAE.T_REAL_DEFAULT;
    case DAE.T_STRING() then DAE.T_STRING_DEFAULT;
    case DAE.T_BOOL() then DAE.T_BOOL_DEFAULT;
    case DAE.T_CLOCK() then DAE.T_CLOCK_DEFAULT;

    case DAE.T_SUBTYPE_BASIC()
      algorithm
        DAE.T_SUBTYPE_BASIC(complexType = ty) := inType2;
        (outExp1, outExp2, outCompatType, outCompatible) :=
          checkTypeCompat(inExp1, inType1.complexType, inExp2, ty);
      then
        outCompatType;

    // Enumerations, check that they have same literals.
    case DAE.T_ENUMERATION()
      algorithm
        DAE.T_ENUMERATION(names = names) := inType2;
        outCompatible := List.isEqualOnTrue(inType1.names, names, stringEq);
      then
        inType1;

    // Arrays, must have compatible element types and dimensions.
    case DAE.T_ARRAY()
      algorithm
        // Check that the element types are compatible.
        ety1 := arrayElementType(inType1);
        ety2 := arrayElementType(inType2);
        (outExp1, outExp2, outCompatType, outCompatible) :=
          checkTypeCompat(inExp1, ety1, inExp2, ety2);

        // If the element types are compatible, check the dimensions too.
        if outCompatible then
          dims1 := getDimensions(inType1);
          dims2 := getDimensions(inType2);

          // The arrays must have the same number of dimensions.
          if listLength(dims1) == listLength(dims2) then
            dims1 := list(if Expression.dimensionsKnownAndEqual(dim1, dim2) then
              dim1 else DAE.DIM_UNKNOWN() threaded for dim1 in dims1, dim2 in dims2);
            outCompatType := liftArrayListDims(outCompatType, dims1);
          else
            outCompatible := false;
          end if;
        end if;
      then
        outCompatType;

    // Records, must have the same components.
    case DAE.T_COMPLEX(complexClassType = ClassInf.RECORD())
      algorithm
        DAE.T_COMPLEX(varLst = vars) := inType2;
        // TODO: Implement type casting for records with the same components but
        // in different order.
        outCompatible := List.isEqualOnTrue(inType1.varLst, vars, varEqualName);
      then
        inType1;

    case DAE.T_FUNCTION()
      algorithm
        DAE.T_FUNCTION(funcResultType = ty, funcArg = args) := inType2;
        (outExp1, outExp2, outCompatType, outCompatible) :=
          checkTypeCompat(inExp1, inType1.funcResultType, inExp2, ty);

        if outCompatible then
          tys := list(funcArgType(arg) for arg in inType1.funcArg);
          tys2 := list(funcArgType(arg) for arg in args);
          (_, outCompatible) := checkTypeCompatList(inExp1, tys, inExp2, tys2);
        end if;
      then
        inType1;

    case DAE.T_TUPLE()
      algorithm
        DAE.T_TUPLE(types = tys) := inType2;
        (tys, outCompatible) :=
          checkTypeCompatList(inExp1, inType1.types, inExp2, tys);
      then
        DAE.T_TUPLE(tys, inType1.names, inType1.source);

    // MetaModelica types.
    case DAE.T_METALIST()
      algorithm
        DAE.T_METALIST(ty = ty) := inType2;
        //print("List(" + anyString(inType1.ty) + "), List(" + anyString(ty) + ")\n");
        (outExp1, outExp2, outCompatType, outCompatible) :=
          checkTypeCompat(inExp1, inType1.ty, inExp2, ty, true);
      then
        DAE.T_METALIST(outCompatType, inType1.source);

    case DAE.T_METAARRAY()
      algorithm
        DAE.T_METAARRAY(ty = ty) := inType2;
        (outExp1, outExp2, outCompatType, outCompatible) :=
          checkTypeCompat(inExp1, inType1.ty, inExp2, ty, true);
      then
        DAE.T_METAARRAY(outCompatType, inType1.source);

    case DAE.T_METAOPTION()
      algorithm
        DAE.T_METAOPTION(ty = ty) := inType2;
        (outExp1, outExp2, outCompatType, outCompatible) :=
          checkTypeCompat(inExp1, inType1.ty, inExp2, ty, true);
      then
        DAE.T_METAOPTION(outCompatType, inType1.source);

    case DAE.T_METATUPLE()
      algorithm
        DAE.T_METATUPLE(types = tys) := inType2;
        (tys, outCompatible) :=
          checkTypeCompatList(inExp1, inType1.types, inExp2, tys);
      then
        DAE.T_METATUPLE(tys, inType1.source);

    case DAE.T_METABOXED()
      algorithm
        DAE.T_METABOXED(ty = ty) := inType2;
        (outExp1, outExp2, outCompatType, outCompatible) :=
          checkTypeCompat(inExp1, inType1.ty, inExp2, ty);
      then
        DAE.T_METABOXED(outCompatType, inType1.source);

    case DAE.T_METAPOLYMORPHIC()
      algorithm
        DAE.T_METAPOLYMORPHIC(name = name) := inType2;
        outCompatible := inType1.name == name;
      then
        inType1;

    case DAE.T_METAUNIONTYPE(source = {p1})
      algorithm
        DAE.T_METAUNIONTYPE(source = {p2}) := inType2;
        outCompatible := Absyn.pathEqual(p1, p2);
      then
        inType1;

    case DAE.T_METARECORD(utPath = p1)
      algorithm
        DAE.T_METARECORD(utPath = p2) := inType2;
        outCompatible := Absyn.pathEqual(p1, p2);
      then
        inType1;

    case DAE.T_FUNCTION_REFERENCE_VAR()
      algorithm
        DAE.T_FUNCTION_REFERENCE_VAR(functionType = ty) := inType2;
        (outExp1, outExp2, outCompatType, outCompatible) :=
          checkTypeCompat(inExp1, inType1.functionType, inExp2, ty);
      then
        DAE.T_FUNCTION_REFERENCE_VAR(outCompatType, inType1.source);

    else
      algorithm
        outCompatible := false;
      then
        DAE.T_UNKNOWN_DEFAULT;

  end match;
end checkTypeCompat;

protected function checkTypeCompatList
  "Checks that two lists of types are compatible using checkTypeCompat."
  input DAE.Exp inExp1;
  input list<DAE.Type> inTypes1;
  input DAE.Exp inExp2;
  input list<DAE.Type> inTypes2;
  output list<DAE.Type> outCompatibleTypes = {};
  output Boolean outCompatible = true;
protected
  DAE.Type ty2;
  list<DAE.Type> rest_ty2 = inTypes2;
  Boolean compat;
algorithm
  if listLength(inTypes1) <> listLength(inTypes2) then
    outCompatible := false;
    return;
  end if;

  for ty1 in inTypes1 loop
    ty2 :: rest_ty2 := rest_ty2;
    // Ignore the returned expressions. This function is used for tuples, and
    // it's not clear how tuples should be type converted. So we only check that
    // the types are compatible and hope for the best.
    (_, _, ty2, compat) := checkTypeCompat(inExp1, ty1, inExp2, ty2);

    if not compat then
      outCompatible := false;
      return;
    end if;

    outCompatibleTypes := ty2 :: outCompatibleTypes;
  end for;

  outCompatibleTypes := listReverse(outCompatibleTypes);
end checkTypeCompatList;

protected function checkTypeCompat_cast
  "Helper function to checkTypeCompat. Tries to type cast one of the given
   expressions so that they become type compatible."
  input DAE.Exp inExp1;
  input DAE.Type inType1;
  input DAE.Exp inExp2;
  input DAE.Type inType2;
  input Boolean inAllowUnknown;
  output DAE.Exp outExp1 = inExp1;
  output DAE.Exp outExp2 = inExp2;
  output DAE.Type outCompatType;
  output Boolean outCompatible = true;
protected
  DAE.Type ty1, ty2;
  Absyn.Path path;
algorithm
  ty1 := derivedBasicType(inType1);
  ty2 := derivedBasicType(inType2);

  outCompatType := match(ty1, ty2)
    // Real <-> Integer
    case (DAE.T_REAL(), DAE.T_INTEGER())
      algorithm
        outExp2 := Expression.typeCastElements(inExp2, DAE.T_REAL_DEFAULT);
      then
        DAE.T_REAL_DEFAULT;

    case (DAE.T_INTEGER(), DAE.T_REAL())
      algorithm
        outExp1 := Expression.typeCastElements(inExp1, DAE.T_REAL_DEFAULT);
      then
        DAE.T_REAL_DEFAULT;

    // If one of the expressions is boxed, unbox it.
    case (DAE.T_METABOXED(), _)
      algorithm
        (outExp1, outExp2, outCompatType, outCompatible) :=
          checkTypeCompat(inExp1, ty1.ty, inExp2, ty2, inAllowUnknown);
        outExp1 := if isBoxedType(ty2) then outExp1 else DAE.UNBOX(outExp1, outCompatType);
      then
        ty2;

    case (_, DAE.T_METABOXED())
      algorithm
        (outExp1, outExp2, outCompatType, outCompatible) :=
          checkTypeCompat(inExp1, ty1, inExp2, ty2.ty, inAllowUnknown);
        outExp2 := if isBoxedType(ty1) then outExp2 else DAE.UNBOX(outExp2, outCompatType);
      then
        ty1;

    // Expressions such as Absyn.IDENT gets the type T_METARECORD(Absyn.Path.IDENT)
    // instead of UNIONTYPE(Absyn.Path), but e.g. a function returning an
    // Absyn.PATH has the type UNIONTYPE(Absyn.PATH). So we'll just pretend that
    // metarecords actually have uniontype type.
    case (DAE.T_METARECORD(), DAE.T_METAUNIONTYPE(source = {path}))
      algorithm
        outCompatible := Absyn.pathEqual(ty1.utPath, path);
      then
        ty2;

    case (DAE.T_METAUNIONTYPE(source = {path}), DAE.T_METARECORD())
      algorithm
        outCompatible := Absyn.pathEqual(path, ty2.utPath);
      then
        ty1;

    // Allow unknown types in some cases, e.g. () has type T_METALIST(T_UNKNOWN)
    case (DAE.T_UNKNOWN(), _)
      algorithm
        outCompatible := inAllowUnknown;
      then
        ty2;

    case (_, DAE.T_UNKNOWN())
      algorithm
        //print("Unknown(" + boolString(inAllowUnknown) + ")\n");
        outCompatible := inAllowUnknown;
      then
        ty1;

    // Anything else is not compatible.
    else
      algorithm
        outCompatible := false;
      then
        DAE.T_UNKNOWN_DEFAULT;

  end match;
end checkTypeCompat_cast;

public function arrayHasUnknownDims
  "Checks if an array type has dimensions which are unknown."
  input DAE.Type inType;
  output Boolean outUnknownDims;
algorithm
  outUnknownDims := match(inType)
    case DAE.T_ARRAY()
      then List.exist(inType.dims, Expression.dimensionUnknown) or
           arrayHasUnknownDims(inType.ty);

    else false;
  end match;
end arrayHasUnknownDims;

public function metaArrayElementType
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match inType
    case DAE.T_METAARRAY() then inType.ty;
    case DAE.T_METATYPE() then metaArrayElementType(inType.ty);
  end match;
end metaArrayElementType;

public function isMetaArray
  input DAE.Type inType;
  output Boolean b;
algorithm
  b := match inType
    case DAE.T_METAARRAY() then true;
    case DAE.T_METATYPE() then isMetaArray(inType.ty);
    else false;
  end match;
end isMetaArray;

public function getAttributes
  input DAE.Type inType;
  output list<DAE.Var> outAttributes;
algorithm
  outAttributes := match inType
    case DAE.T_REAL() then inType.varLst;
    case DAE.T_INTEGER() then inType.varLst;
    case DAE.T_STRING() then inType.varLst;
    case DAE.T_BOOL() then inType.varLst;
    case DAE.T_ENUMERATION() then inType.attributeLst;
    case DAE.T_SUBTYPE_BASIC() then getAttributes(inType.complexType);
    else {};
  end match;
end getAttributes;

public function lookupAttributeValue
  input list<DAE.Var> inAttributes;
  input String inName;
  output Option<Values.Value> outValue = NONE();
algorithm
  for attr in inAttributes loop
    if inName == varName(attr) then
      outValue := DAEUtil.bindingValue(varBinding(attr));
      break;
    end if;
  end for;
end lookupAttributeValue;

public function lookupAttributeExp
  input list<DAE.Var> inAttributes;
  input String inName;
  output Option<DAE.Exp> outExp = NONE();
algorithm
  for attr in inAttributes loop
    if inName == varName(attr) then
      outExp := DAEUtil.bindingExp(varBinding(attr));
      break;
    end if;
  end for;
end lookupAttributeExp;

protected function unboxedTypeTraverseHelper<T>
  input DAE.Type ty;
  input T dummy;
  output DAE.Type oty = unboxedType(ty);
  output T odummy = dummy;
end unboxedTypeTraverseHelper;

public function getMetaRecordFields
  input DAE.Type ty;
  output list<DAE.Var> fields;
algorithm
  fields := match ty
    local
      DAE.EvaluateSingletonTypeFunction fun;
    case DAE.T_METARECORD(fields=fields) then fields;
    case DAE.T_METAUNIONTYPE(knownSingleton=false)
      algorithm
        Error.addInternalError(getInstanceName() + " called on a non-singleton uniontype: " + unparseType(ty), sourceInfo());
      then fail();
    case DAE.T_METAUNIONTYPE(singletonType=DAE.EVAL_SINGLETON_KNOWN_TYPE(ty=DAE.T_METARECORD(fields=fields))) then fields;
    case DAE.T_METAUNIONTYPE(singletonType=DAE.EVAL_SINGLETON_TYPE_FUNCTION(fun=fun))
      algorithm
        DAE.T_METARECORD(fields=fields) := fun();
      then fields;
    else
      algorithm
        Error.addInternalError(getInstanceName() + " called on a non-singleton uniontype: " + unparseType(ty), sourceInfo());
      then fail();
  end match;
end getMetaRecordFields;

public function getMetaRecordIfSingleton
  input DAE.Type ty;
  output DAE.Type oty;
algorithm
  oty := match ty
    local
      DAE.EvaluateSingletonTypeFunction fun;
    case DAE.T_METAUNIONTYPE(knownSingleton=false) then ty;
    case DAE.T_METAUNIONTYPE(singletonType=DAE.EVAL_SINGLETON_KNOWN_TYPE(ty=oty)) then oty;
    case DAE.T_METAUNIONTYPE(singletonType=DAE.EVAL_SINGLETON_TYPE_FUNCTION(fun=fun))
      algorithm
        oty := fun();
      then oty;
    else ty;
  end match;
end getMetaRecordIfSingleton;

public function setTypeVariables
  input DAE.Type ty;
  input list<DAE.Type> typeVars;
  output DAE.Type oty;
algorithm
  oty := match ty
    case oty as DAE.T_METAUNIONTYPE()
      algorithm
        oty.typeVars := typeVars;
      then oty;
    case oty as DAE.T_METARECORD()
      algorithm
        oty.typeVars := typeVars;
      then oty;
    else ty;
  end match;
end setTypeVariables;

public function isExpandableConnector
"@author: adrpo
  this function checks if the given type is an expandable connector"
  input DAE.Type ty;
  output Boolean isExpandable;
algorithm
  isExpandable := match (ty)
    case (DAE.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(_,true))) then true;
    // TODO! check if subtype is needed here
    case (DAE.T_SUBTYPE_BASIC(complexClassType = ClassInf.CONNECTOR(_,true))) then true;
    else false;
  end match;
end isExpandableConnector;

annotation(__OpenModelica_Interface="frontend");
end Types;
