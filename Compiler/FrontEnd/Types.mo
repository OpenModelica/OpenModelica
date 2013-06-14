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

encapsulated package Types
" file:        Types.mo
  package:     Types
  description: Type system

  RCS: $Id$

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
public import Values;
public import SCode;

public type Attributes = DAE.Attributes;
public type Binding = DAE.Binding;
public type Const = DAE.Const;
public type EqualityConstraint = DAE.EqualityConstraint;
public type FuncArg = DAE.FuncArg;
public type Ident = String;
public type PolymorphicBindings = list<tuple<String,list<Type>>>;
public type Properties = DAE.Properties;
public type TupleConst = DAE.TupleConst;
public type Type = DAE.Type;
public type Var = DAE.Var;
public type EqMod = DAE.EqMod;

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

public function discreteType
"function: discreteType
  author: PA
  Succeeds for all the discrete types, Integer, String, Boolean and enumeration."
  input Type inType;
algorithm
  _ := match (inType)
    local Type ty;
    case (DAE.T_INTEGER(varLst = _)) then ();
    case (DAE.T_STRING(varLst = _)) then ();
    case (DAE.T_BOOL(varLst = _)) then ();
    case (DAE.T_ENUMERATION(names = _)) then ();
    case (DAE.T_SUBTYPE_BASIC(complexType = ty))
      equation
        discreteType(ty);
      then ();
  end match;
end discreteType;

public function propsAnd "
Author BZ, 2008-09
Function for merging a list of properties, currently only working on DAE.PROP() and not TUPLE_DAE.PROP()."
  input list<Properties> inProps;
  output Properties outProp;
algorithm outProp := matchcontinue(inProps)
  local
    Properties prop,prop2;
    Const c,c2;
    Type ty,ty2;
    list<Properties> props;

  case(prop::{}) then prop;
  case((prop as DAE.PROP(ty,c))::props)
    equation
      (prop2 as DAE.PROP(ty2,c2)) = propsAnd(props);
      c = constAnd(c,c2);
      true = equivtypes(ty,ty2);
    then
      DAE.PROP(ty,c);
end matchcontinue;
end propsAnd;

// stefan
public function makePropsNotConst
"function: makePropsNotConst
  returns the same Properties but with the const flag set to Var"
  input Properties inProperties;
  output Properties outProperties;
algorithm outProperties := matchcontinue (inProperties)
  local
    Type t;
  case(DAE.PROP(type_=t,constFlag=_)) then DAE.PROP(t,DAE.C_VAR());
  end matchcontinue;
end makePropsNotConst;

// stefan
public function setTypeInProps
"function: setTypeInProps
  sets the Type in a Properties record"
  input DAE.Type inType;
  input DAE.Properties inProperties;
  output DAE.Properties outProperties;
algorithm
  outProperties := match(inType,inProperties)
    local
      DAE.Const cf;
      DAE.TupleConst tc;
      DAE.Type ty;
    case(ty,DAE.PROP(_,cf)) then DAE.PROP(ty,cf);
    case(ty,DAE.PROP_TUPLE(_,tc)) then DAE.PROP_TUPLE(ty,tc);
  end match;
end setTypeInProps;

// stefan
public function getConstList
"function: getConstList
  retrieves a list of Consts from a list of Properties"
  input list<Properties> inPropertiesList;
  output list<Const> outConstList;
algorithm
  outConstList := match(inPropertiesList)
    local
      Const c;
      list<Const> ccdr;
      list<Properties> pcdr;
      TupleConst tc;
    case({}) then {};
    case(DAE.PROP(type_=_,constFlag=c) :: pcdr)
      equation
        ccdr = getConstList(pcdr);
      then
        c :: ccdr;
    case(DAE.PROP_TUPLE(type_=_,tupleConst=tc) :: pcdr)
      equation
        c = propertiesListToConst2(tc);
        ccdr = getConstList(pcdr);
      then
        c :: ccdr;
  end match;
end getConstList;


public function propertiesListToConst " function propertiesListToConst
this function elaborates on a DAE.Properties and return the DAE.Const value."
  input list<Properties> p;
  output Const c;
algorithm
  c := match (p)
    local
      Properties p1;
      list<Properties> pps;
      Const c1,c2;
      TupleConst tc1;

    case({}) then DAE.C_CONST();

    case ((p1 as DAE.PROP(_,c1))::pps)
      equation
        c2 = propertiesListToConst(pps);
        c1 = constAnd(c1, c2);
      then
        c1;

    case((p1 as DAE.PROP_TUPLE(_,tc1))::pps)
      equation
        c1 = propertiesListToConst2(tc1);
        c2 = propertiesListToConst(pps);
        c1 = constAnd(c1, c2);
      then
        c1;
  end match;
end propertiesListToConst;

protected function propertiesListToConst2 ""
  input TupleConst t;
  output Const c;
algorithm
  c := match (t)
    local
      TupleConst p1;
      Const c1,c2;
      list<TupleConst> tcxl;
      TupleConst tc1;

    case (p1 as DAE.SINGLE_CONST(c1)) then c1;

    case(p1 as DAE.TUPLE_CONST(tc1::tcxl))
      equation
        c1 = propertiesListToConst2(tc1);
        c2 = propertiesListToConst3(tcxl);
        c1 = constAnd(c1, c2);
      then
        c1;
  end match;
end propertiesListToConst2;

protected function propertiesListToConst3 ""
  input list<TupleConst> t;
  output Const c;
algorithm
  c := match (t)
    local
      TupleConst p1;
      Const c1,c2;
      list<TupleConst> tcxl;

    case({}) then DAE.C_CONST();

    case((p1 as DAE.SINGLE_CONST(c1))::tcxl)
      equation
        c2 = propertiesListToConst3(tcxl);
        c1 = constAnd(c1, c2);
      then
        c1;

    case((p1 as DAE.TUPLE_CONST(_))::tcxl)
      equation
        c1 = propertiesListToConst2(p1);
        c2 = propertiesListToConst3(tcxl);
        c1 = constAnd(c1, c2);
      then
        c1;
  end match;
end propertiesListToConst3;

public function externalObjectType
"author: PA
 Succeeds if type is ExternalObject"
  input Type inType;
algorithm
  _ := match (inType)
    case DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_)) then ();
  end match;
end externalObjectType;

public function varName "
Author BZ, 2009-09
Function for getting the name of a DAE.Var"
  input Var v;
  output String s;
algorithm
  s := match(v)
    case(DAE.TYPES_VAR(name = s)) then s;
  end match;
end varName;

public function externalObjectConstructorType "author: PA
  Succeeds if type is ExternalObject constructor function"
  input Type inType;
algorithm
  _ := match (inType)
    local Type tp;
    case DAE.T_FUNCTION(funcResultType = tp)
      equation
        externalObjectType(tp);
      then ();
  end match;
end externalObjectConstructorType;

public function simpleType "function: simpleType
  author: PA
  Succeeds for all the builtin types, Integer, String, Real, Boolean"
  input Type inType;
algorithm
  true := isSimpleType(inType);
end simpleType;

public function isSimpleType
  "Returns true for all the builtin types, Integer, String, Real, Boolean"
  input Type inType;
  output Boolean b;
algorithm
  b := match (inType)
    case (DAE.T_REAL(varLst = _)) then true;
    case (DAE.T_INTEGER(varLst = _)) then true;
    case (DAE.T_STRING(varLst = _)) then true;
    case (DAE.T_BOOL(varLst = _)) then true;
    case (DAE.T_ENUMERATION(path = _)) then true;
    else false;
  end match;
end isSimpleType;

public function isSimpleNumericType
  "Returns true for simple numeric builtin types, Integer and Real"
  input Type inType;
  output Boolean b;
algorithm
  b := match (inType)
    case (DAE.T_REAL(varLst = _)) then true;
    case (DAE.T_INTEGER(varLst = _)) then true;
    else false;
  end match;
end isSimpleNumericType;

public function isNumericType "function: isSimpleNumericArray
  This function checks if the element type is Numeric type or array of Numeric type."
  input Type inType;
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
  input Type inType;
  output Boolean outIsConnector;
algorithm
  outIsConnector := match(inType)
    case DAE.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(path = _)) then true;
    case DAE.T_SUBTYPE_BASIC(complexClassType = ClassInf.CONNECTOR(path = _)) then true;
    else false;
  end match;
end isConnector;

public function isComplexConnector
  "Returns true if the given type is a complex connector type, i.e. a connector
   with components, otherwise false."
  input Type inType;
  output Boolean outIsComplexConnector;
algorithm
  outIsComplexConnector := match(inType)
    case DAE.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(path = _)) then true;
    else false;
  end match;
end isComplexConnector;

public function isComplexExpandableConnector
  "Returns true if the given type is an expandable connector, otherwise false."
  input Type inType;
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
  input Type ity;
  output Boolean b;
algorithm
  b := matchcontinue(ity)
    local Type ty;
    case (DAE.T_SUBTYPE_BASIC(complexType = ty)) then isComplexType(ty);
    case (DAE.T_COMPLEX(varLst = _::_)) then true; // not derived from baseclass
    case(_) then false;
  end matchcontinue;
end isComplexType;

public function isExternalObject "Returns true if type is COMPLEX and external object (ClassInf)"
  input Type tp;
  output Boolean b;
algorithm
  b := matchcontinue(tp)
    case (DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_))) then true;
    case (_) then false;
  end matchcontinue;
end isExternalObject;

public function expTypetoTypesType
"function: expTypetoTypesType
 Converts a DAE.Type to a DAE.Type
 NOTE: This function should not be used in general, since it is not recommended to translate DAE.Type into DAE.Type."
  input Type inType;
  output Type oType;
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
    case _ then inType;

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
      Option<Const> constOfForIteratorRange;

    case(DAE.TYPES_VAR(name, attributes, ty, binding, constOfForIteratorRange))
      equation
        ty = expTypetoTypesType(ty);
      then
        DAE.TYPES_VAR(name, attributes, ty, binding, constOfForIteratorRange);

    case(_) equation print("error in Types.convertFromExpToTypesVar\n"); then fail();

  end matchcontinue;
end convertFromExpToTypesVar;

public function isTuple "Returns true if type is TUPLE"
  input Type tp;
  output Boolean b;
algorithm
  b := matchcontinue(tp)
    case (DAE.T_TUPLE(tupleType = _)) then true;
    case (_) then false;
  end matchcontinue;
end isTuple;

public function isRecord "Returns true if type is COMPLEX and a record (ClassInf)"
  input Type tp;
  output Boolean b;
algorithm
  b := matchcontinue(tp)
    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_))) then true;
    case (_) then false;
  end matchcontinue;
end isRecord;

public function isRecordWithOnlyReals "Returns true if type is a record only containing Reals"
  input Type tp;
  output Boolean b;
algorithm
  b := match (tp)
    local
      list<Var> varLst;

    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_),varLst = varLst))
      then List.mapAllValueBool(List.map(varLst,getVarType),isReal,true);

    // otherwise false
    else false;
  end match;
end isRecordWithOnlyReals;

public function getVarType "Return the Type of a Var"
  input Var v;
  output Type tp;
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
  input Var v;
  output Boolean b;
algorithm
  b := match v
    case DAE.TYPES_VAR(attributes=DAE.ATTR(variability=SCode.VAR())) then true;
    case DAE.TYPES_VAR(attributes=DAE.ATTR(variability=SCode.DISCRETE())) then true;
    else false;
  end match;
end varIsVariable;

public function getVarName "Return the name of a Var"
  input Var v;
  output String name;
algorithm
  name := match (v)
    case(DAE.TYPES_VAR(name = name)) then name;
  end match;
end getVarName;

public function isReal "Returns true if type is Real"
input Type tp;
output Boolean res;
algorithm
 res := matchcontinue(tp)
   case _
     equation
       DAE.T_REAL(varLst = _) = arrayElementType(tp);
     then true;
   case(_) then false;
 end matchcontinue;
end isReal;

public function isScalarReal
  input Type inType;
  output Boolean outIsScalarReal;
algorithm
  outIsScalarReal := match(inType)
    local
      Type ty;

    case DAE.T_REAL(varLst = _) then true;
    case DAE.T_SUBTYPE_BASIC(complexType = ty) then isScalarReal(ty);
    else false;
  end match;
end isScalarReal;

public function isRealOrSubTypeReal "
Author BZ 2008-05
This function verifies if it is some kind of a Real type we are working with."
  input Type inType;
  output Boolean b;
algorithm
  b := matchcontinue(inType)
    local Type ty; Boolean lb1,lb2,lb3;
    case(ty)
      equation
        lb1 = isReal(ty);
        lb2 = subtype(ty, DAE.T_REAL_DEFAULT);
        lb3 = subtype(DAE.T_REAL_DEFAULT,ty);
        lb1 = boolOr(lb1,boolAnd(lb2,lb3));
    then lb1;

    case(_) then false;

  end matchcontinue;
end isRealOrSubTypeReal;

public function isIntegerOrSubTypeInteger "
Author BZ 2009-02
This function verifies if it is some kind of a Integer type we are working with."
  input Type inType;
  output Boolean b;
algorithm
  b := matchcontinue(inType)
    local Type ty; Boolean lb1,lb2,lb3;
    case(ty)
      equation
        lb1 = isInteger(ty);
        lb2 = subtype(ty, DAE.T_INTEGER_DEFAULT);
        lb3 = subtype(DAE.T_INTEGER_DEFAULT,ty);
        lb1 = boolOr(lb1,boolAnd(lb2,lb3));
        //lb1 = boolOr(lb1,lb2);
      then lb1;
    case(_) then false;
end matchcontinue;
end isIntegerOrSubTypeInteger;

public function isBooleanOrSubTypeBoolean
"@author: adrpo
 This function verifies if it is some kind of a Boolean type we are working with."
  input Type inType;
  output Boolean b;
algorithm
  b := matchcontinue(inType)
    local Type ty; Boolean lb1,lb2,lb3;
    case(ty)
      equation
        lb1 = isBoolean(ty);
        lb2 = subtype(ty, DAE.T_BOOL_DEFAULT);
        lb3 = subtype(DAE.T_BOOL_DEFAULT, ty);
        lb1 = boolOr(lb1,boolAnd(lb2,lb3));
      then lb1;
    case(_) then false;
  end matchcontinue;
end isBooleanOrSubTypeBoolean;

public function isStringOrSubTypeString
"@author: adrpo
 This function verifies if it is some kind of a String type we are working with."
  input Type inType;
  output Boolean b;
algorithm
  b := matchcontinue(inType)
    local Type ty; Boolean lb1,lb2,lb3;
    case(ty)
      equation
        lb1 = isString(ty);
        lb2 = subtype(ty, DAE.T_STRING_DEFAULT);
        lb3 = subtype(DAE.T_STRING_DEFAULT, ty);
        lb1 = boolOr(lb1,boolAnd(lb2,lb3));
      then lb1;
    case(_) then false;
  end matchcontinue;
end isStringOrSubTypeString;

public function isIntegerOrRealOrSubTypeOfEither
  "Checks if a type is either some Integer or Real type."
  input Type t;
  output Boolean b;
algorithm
  b := matchcontinue(t)
    case(_) equation true = isRealOrSubTypeReal(t); then true;
    case(_) equation true = isIntegerOrSubTypeInteger(t); then true;
    case(_) then false;
  end matchcontinue;
end isIntegerOrRealOrSubTypeOfEither;

public function isIntegerOrRealOrBooleanOrSubTypeOfEither
  "Checks if a type is either some Integer or Real type."
  input Type t;
  output Boolean b;
algorithm
  b := matchcontinue(t)
    case(_) equation true = isRealOrSubTypeReal(t); then true;
    case(_) equation true = isIntegerOrSubTypeInteger(t); then true;
    case(_) equation true = isBooleanOrSubTypeBoolean(t); then true;
    case(_) then false;
  end matchcontinue;
end isIntegerOrRealOrBooleanOrSubTypeOfEither;

public function isInteger "Returns true if type is Integer"
  input Type tp;
  output Boolean res;
algorithm
 res := matchcontinue(tp)
   case _
     equation
       DAE.T_INTEGER(varLst = _) = arrayElementType(tp);
     then true;

   case(_) then false;

 end matchcontinue;
end isInteger;

public function isBoolean "Returns true if type is Boolean"
  input Type tp;
  output Boolean res;
algorithm
 res := matchcontinue(tp)
   case _
     equation
       DAE.T_BOOL(varLst = _) = arrayElementType(tp);
      then true;

   case(_) then false;
 end matchcontinue;
end isBoolean;

public function integerOrReal "function: integerOrReal
  author: PA
  Succeeds for the builtin types Integer and Real
  (including classes extending the basetype Integer or Real)."
  input Type inType;
algorithm
  _ := match (inType)
    local Type tp;
    case (DAE.T_REAL(varLst = _)) then ();
    case (DAE.T_INTEGER(varLst = _)) then ();
    case (DAE.T_SUBTYPE_BASIC(complexType = tp))
      equation
        integerOrReal(tp);
      then ();
  end match;
end integerOrReal;

public function isArray "function: isArray
  Returns true if Type is an array."
  input Type inType;
  input DAE.Dimensions inDims;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inType,inDims)
      local Type t;
    // several (at least 2) dimensions means array!
    case (_, _::_::_) then true;
    // if the type is an array, then is an array
    case (DAE.T_ARRAY(ty = _),_) then true;
    // if is a type extending basic type
    case (DAE.T_SUBTYPE_BASIC(complexType = t),_) then isArray(t, {});
    case (_,_) then false;
  end matchcontinue;
end isArray;

public function isEmptyArray
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inType)
    case DAE.T_ARRAY(dims = {DAE.DIM_INTEGER(0)}) then true;
    case _ then false;
  end matchcontinue;
end isEmptyArray;

public function isString "function: isString
  Return true if Type is the builtin String type."
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inType)
    case (DAE.T_STRING(varLst = _)) then true;
    case (_) then false;
  end matchcontinue;
end isString;

public function isEnumeration "function: isEnumeration
  Return true if Type is the builtin String type."
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inType)
    case (DAE.T_ENUMERATION(index = _)) then true;
    case (_) then false;
  end matchcontinue;
end isEnumeration;

public function isArrayOrString "function: isArrayOrString
  Return true if Type is array or the builtin String type."
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inType)
    local Type ty;
    case ty
      equation
        true = isArray(ty, {});
      then
        true;
    case ty
      equation
        true = isString(ty);
      then
        true;
    case _ then false;
  end matchcontinue;
end isArrayOrString;

public function numberOfDimensions "function: ndims
  Return the number of dimensions of a Type."
  input Type inType;
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
  input Type inType;
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

    case (DAE.T_ARRAY(dims = {}, ty = tp, source = ts))
      equation
        true = dimensionsKnown(tp);
      then
        true;

    case (DAE.T_ARRAY(dims = _))
      then false;

    case (DAE.T_SUBTYPE_BASIC(complexType = tp))
      then dimensionsKnown(tp);

    case _ then true;
  end matchcontinue;
end dimensionsKnown;

public function getDimensionSizes "function: getDimensionSizes
  Return the dimension sizes of a Type."
  input Type inType;
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

    case (DAE.T_ARRAY(dims = d::dims, ty = tp, source = ts))
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

    case (_)
      equation
        false = arrayType(inType);
      then
        {};
  end matchcontinue;
end getDimensionSizes;

public function getDimensions
"Returns the dimensions of a Type."
  input Type inType;
  output DAE.Dimensions outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inType)
    local
      DAE.Dimensions res;
      Type tp;
      DAE.Dimensions dims;

    case (DAE.T_ARRAY(dims = dims,ty = tp))
      equation
        res = getDimensions(tp);
        res = listAppend(dims, res);
      then
        res;

    case (DAE.T_METAARRAY(ty = tp))
      equation
        res = getDimensions(tp);
      then
        (DAE.DIM_UNKNOWN() :: res);

    case (DAE.T_SUBTYPE_BASIC(complexType =tp))
      then
        getDimensions(tp);

    else {};
  end matchcontinue;
end getDimensions;

public function getDimensionNth
  input Type inType;
  input Integer inDim;
  output DAE.Dimension outDimension;
algorithm
  outDimension := matchcontinue(inType, inDim)
    local
      DAE.Dimension dim;
      DAE.Type t;
      Integer d;
      DAE.Dimensions dims;

    case (DAE.T_ARRAY(dims = dims), d)
      equation
        dim = listNth(dims, d - 1);
      then
        dim;

    case (DAE.T_ARRAY(ty = t), d)
      equation
        true = (d > 1);
      then
        getDimensionNth(t, d - 1);

    case (DAE.T_SUBTYPE_BASIC(complexType = t), d)
      then getDimensionNth(t, d);

  end matchcontinue;
end getDimensionNth;

public function setDimensionNth
  "Sets the nth dimension of an array type to the given dimension."
  input Type inType;
  input DAE.Dimension inDim;
  input Integer inDimNth;
  output Type outType;
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

public function valuesToVars "function valuesToVars
  Translates a list of Values.Value to a Var list, using a list
  of identifiers as component names.
  Used e.g. when retrieving the type of a record value."
  input list<Values.Value> inValuesValueLst;
  input list<DAE.Ident> inExpIdentLst;
  output list<Var> outVarLst;
algorithm
  outVarLst := matchcontinue (inValuesValueLst,inExpIdentLst)
    local
      Type tp;
      list<Var> rest;
      Values.Value v;
      list<Values.Value> vs;
      String id;
      list<Ident> ids;

    case ({},{}) then {};
    case ((v :: vs),(id :: ids))
      equation
        tp = typeOfValue(v);
        rest = valuesToVars(vs, ids);
      then
        (DAE.TYPES_VAR(id, DAE.dummyAttrVar, tp, DAE.UNBOUND(), NONE()) :: rest);

    case (_,_)
      equation
        Debug.fprint(Flags.FAILTRACE, "-values_to_vars failed\n");
      then
        fail();
  end matchcontinue;
end valuesToVars;

public function typeOfValue "function: typeOfValue
  author: PA
  Returns the type of a Values.Value.
  Some information is lost in the translation, like attributes
  of the builtin type."
  input Values.Value inValue;
  output Type outType;
algorithm
  outType := matchcontinue (inValue)
    local
      Type tp;
      Integer dim1,index;
      Values.Value w,v;
      list<Values.Value> vs,vl;
      list<Type> ts;
      list<Var> vars;
      String str;
      Absyn.Path cname,path,utPath;
      list<Ident> ids;
      list<DAE.Exp> explist;
      Values.Value valType;


    case Values.EMPTY(ty = valType) then typeOfValue(valType);

    case (Values.INTEGER(integer = _)) then (DAE.T_INTEGER_DEFAULT);
    case (Values.REAL(real = _)) then (DAE.T_REAL_DEFAULT);
    case (Values.STRING(string = _)) then (DAE.T_STRING_DEFAULT);
    case (Values.BOOL(boolean = _)) then (DAE.T_BOOL_DEFAULT);
    case (Values.ENUM_LITERAL(name = path, index = index))
      equation
        path = Absyn.pathPrefix(path);
      then
        DAE.T_ENUMERATION(SOME(index), path, {}, {}, {}, DAE.emptyTypeSource);

    case ((w as Values.ARRAY(valueLst = (v :: vs))))
      equation
        tp = typeOfValue(v);
        dim1 = listLength((v :: vs));
      then
        DAE.T_ARRAY(tp, {DAE.DIM_INTEGER(dim1)}, DAE.emptyTypeSource);

    case ((w as Values.ARRAY(valueLst = ({}))))
      equation
      then
        DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT, {DAE.DIM_INTEGER(0)}, DAE.emptyTypeSource);

    case ((w as Values.TUPLE(valueLst = vs)))
      equation
        ts = List.map(vs, typeOfValue);
      then
        DAE.T_TUPLE(ts,DAE.emptyTypeSource);

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
        DAE.T_METARECORD(utPath, index, vars, false /*We simply do not know...*/,{cname});

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
        ts = List.map(vs, typeOfValue);
        ts = List.map(ts, boxIfUnboxedType);
      then
        DAE.T_METATUPLE(ts,DAE.emptyTypeSource);

    case Values.META_BOX(v)
      equation
        tp = typeOfValue(v);
      then boxIfUnboxedType(tp);

    case Values.NORETCALL() then DAE.T_NORETCALL_DEFAULT;

    case Values.CODE(A=Absyn.C_TYPENAME(path=_))
      then DAE.T_CODE(DAE.C_TYPENAME(), {});

    case Values.CODE(A=Absyn.C_EXPRESSION(exp=_))
      then DAE.T_CODE(DAE.C_EXPRESSION(), {});

    case (v)
      equation
        str = "- Types.typeOfValue failed: " +& ValuesUtil.valString(v);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end matchcontinue;
end typeOfValue;

public function basicType "function: basicType
  Test whether a type is one of the builtin types."
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inType)
    case (DAE.T_INTEGER(source = _)) then true;
    case (DAE.T_REAL(source = _)) then true;
    case (DAE.T_STRING(source = _)) then true;
    case (DAE.T_BOOL(source = _)) then true;
    case (DAE.T_ENUMERATION(source = _)) then true;
    case (_) then false;
  end match;
end basicType;

public function extendsBasicType "function: basicType
  Test whether a type extends one of the builtin types."
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inType)
    case DAE.T_SUBTYPE_BASIC(complexType = _) then true;
    case (_) then false;
  end matchcontinue;
end extendsBasicType;

public function derivedBasicType
  "Returns the actual type of a type extending one of the builtin types."
  input Type inType;
  output Type outType;
algorithm
  outType := match(inType)
    local
      Type ty;

    case DAE.T_SUBTYPE_BASIC(complexType = ty) then ty;
    else inType;
  end match;
end derivedBasicType;

public function arrayType "function: arrayType
  Test whether a type is an array type."
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inType)
    case (DAE.T_ARRAY(dims = _)) then true;
    else false;
  end matchcontinue;
end arrayType;

public function setVarInput "Sets a DAE.Var to input"
  input Var var;
  output Var outV;
algorithm
  outV := matchcontinue(var)
    local
      Ident name;
      SCode.ConnectorType ct;
      SCode.Visibility vis;
      Type tp;
      Binding bind;
      SCode.Parallelism prl;
      SCode.Variability v;
      Absyn.InnerOuter io;
      Option<DAE.Const> cnstForRange;

    case DAE.TYPES_VAR(name,DAE.ATTR(ct,prl,v,_,io,vis),tp,bind,cnstForRange)
    then DAE.TYPES_VAR(name,DAE.ATTR(ct,prl,v,Absyn.INPUT(),io,vis),tp,bind,cnstForRange);

  end matchcontinue;
end setVarInput;

public function setVarDefaultInput "Sets a DAE.Var to input"
  input Var var;
  output Var outV;
algorithm
  outV := match(var)
    local
      Ident name;
      SCode.ConnectorType ct;
      SCode.Visibility vis;
      Type tp;
      Binding bind;
      SCode.Parallelism prl;
      SCode.Variability v;
      Absyn.InnerOuter io;
      Option<DAE.Const> cnstForRange;

    case DAE.TYPES_VAR(name,DAE.ATTR(ct,prl,v,_,io,vis),tp,bind,cnstForRange)
    then DAE.TYPES_VAR(name,DAE.ATTR(SCode.POTENTIAL(),prl,SCode.VAR(),Absyn.INPUT(),Absyn.NOT_INNER_OUTER(),SCode.PUBLIC()),tp,bind,cnstForRange);

  end match;
end setVarDefaultInput;

public function setVarProtected "Sets a DAE.Var to input"
  input Var var;
  output Var outV;
algorithm
  outV := match(var)
    local
      Ident name;
      SCode.ConnectorType ct;
      Absyn.Direction dir;
      Type tp;
      Binding bind;
      SCode.Parallelism prl;
      SCode.Variability v;
      Absyn.InnerOuter io;
      Option<DAE.Const> cnstForRange;

    case DAE.TYPES_VAR(name,DAE.ATTR(ct,prl,v,dir,io,_),tp,bind,cnstForRange)
    then DAE.TYPES_VAR(name,DAE.ATTR(ct,prl,v,dir,io,SCode.PROTECTED()),tp,bind,cnstForRange);

  end match;
end setVarProtected;

protected function setVarType "Sets a DAE.Var's type"
  input Var var;
  input Type ty;
  output Var outV;
algorithm
  outV := match(var,ty)
    local
      Ident name;
      Type tp;
      Binding bind;
      Option<DAE.Const> cnstForRange;
      DAE.Attributes attr;

    case (DAE.TYPES_VAR(name,attr,tp,bind,cnstForRange),_)
    then DAE.TYPES_VAR(name,attr,ty,bind,cnstForRange);

  end match;
end setVarType;

public function semiEquivTypes " function semiEquivTypes
This function checks whether two types are semi-equal...
With 'semi' we mean that they have the same base type,
and if both are arrays the numbers of dimensions are equal, not necessarily equal dimension-sizes."
  input Type inType1;
  input Type inType2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inType1,inType2)
    local
      Type t1,t2,tf1,tf2;
      Boolean b1;
      list<Integer> il1,il2;
      Integer ll1,ll2;
    case (t1,t2)
      equation
        true = arrayType(t1);
        true = arrayType(t2);
        (tf1,il1) = flattenArrayType(t1);
        (tf2,il2) = flattenArrayType(t2);
        true = subtype(tf1, tf2);
        true = subtype(tf2, tf1);
        ll1 = listLength(il1);
        ll2 = listLength(il2);
        true = (ll1 == ll2);
      then
        true;
    case(t1,t2)
      equation
        false = arrayType(t1);
        false = arrayType(t2);
        b1 = equivtypes(t1,t2);
        then
          b1;
    case (t1,t2) then false;  /* default */
  end matchcontinue;
end semiEquivTypes;


public function equivtypes "function: equivtypes
  This is the type equivalence function.  It is defined in terms of
  the subtype function.  Two types are considered equivalent if they
  are subtypes of each other."
  input Type t1;
  input Type t2;
  output Boolean outBoolean;
algorithm
  outBoolean := subtype(t1, t2) and subtype(t2, t1);
end equivtypes;

public function equivtypesOrRecordSubtypeOf
  "Like equivtypes but accepts non-typeconverted records as well (for connections)."
  input Type t1;
  input Type t2;
  output Boolean outBoolean;
algorithm
  outBoolean := subtype2(t1, t2, false /* Allow record names to differ */) and subtype2(t2, t1, false);
end equivtypesOrRecordSubtypeOf;

public function subtype "function: subtype
  Is the first type a subtype of the second type?
  This function specifies the rules for subtyping in Modelica."
  input Type inType1;
  input Type inType2;
  output Boolean outBoolean;
algorithm
  outBoolean := subtype2(inType1,inType2,true);
end subtype;

protected function subtype2 "function: subtype
  Is the first type a subtype of the second type?
  This function specifies the rules for subtyping in Modelica."
  input Type inType1;
  input Type inType2;
  input Boolean requireRecordNamesEqual;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inType1,inType2,requireRecordNamesEqual)
    local
      Boolean res;
      Ident l1,l2;
      list<Var> els1,els2;
      Absyn.Path p1,p2;
      Type t1,t2,tp2,tp1;
      ClassInf.State st1,st2;
      list<Type> type_list1,type_list2,tList1,tList2;
      list<String> names1, names2;
      DAE.Dimension dim1,dim2;
      DAE.Dimensions dlst1, dlst2;
      list<FuncArg> farg1,farg2;
      DAE.CodeType c1,c2;
      DAE.Exp e1,e2;
      DAE.TypeSource ts;

    case (DAE.T_ANYTYPE(anyClassType = _),_,_) then true;
    case (_,DAE.T_ANYTYPE(anyClassType = _),_) then true;
    case (DAE.T_INTEGER(varLst = _),DAE.T_INTEGER(varLst = _),_) then true;
    case (DAE.T_REAL(varLst = _),DAE.T_REAL(varLst = _),_) then true;
    case (DAE.T_STRING(varLst = _),DAE.T_STRING(varLst = _),_) then true;
    case (DAE.T_BOOL(varLst = _),DAE.T_BOOL(varLst = _),_) then true;

    case (DAE.T_ENUMERATION(names = {}),DAE.T_ENUMERATION(names = _),_) then true;
    case (DAE.T_ENUMERATION(names = _),DAE.T_ENUMERATION(names = {}),_) then true;

    case (DAE.T_ENUMERATION(names = names1),
          DAE.T_ENUMERATION(names = names2),_)
      equation
        res = List.isEqualOnTrue(names1, names2, stringEq);
      then
        res;

    case (DAE.T_ARRAY(dims = dlst1 as _::_::_, ty = t1),
          DAE.T_ARRAY(dims = dlst2 as _::_::_, ty = t2),_)
      equation
        true = Expression.dimsEqual(dlst1, dlst2);
        true = subtype2(t1, t2, requireRecordNamesEqual);
      then
        true;

    // try dims as list vs. dims as tree
    // T_ARRAY(a::b::c) vs. T_ARRAY(a, T_ARRAY(b, T_ARRAY(c)))
    case (DAE.T_ARRAY(dims = {dim1}, ty = t1),
          DAE.T_ARRAY(dims = dim2::(dlst2 as _::_), ty = t2, source = ts),_)
      equation
        true = Expression.dimensionsEqual(dim1, dim2);
        true = subtype2(t1, DAE.T_ARRAY(t2, dlst2, ts), requireRecordNamesEqual);
      then
        true;

    // try subtype of dimension list vs. dimension tree
    case (DAE.T_ARRAY(dims = dim1::(dlst1 as _::_), ty = t1, source = ts),
          DAE.T_ARRAY(dims = {dim2}, ty = t2),_)
      equation
        true = Expression.dimensionsEqual(dim1, dim2);
        true = subtype2(DAE.T_ARRAY(t1, dlst1, ts), t2, requireRecordNamesEqual);
      then
        true;

    case (DAE.T_ARRAY(ty = t1),DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()}, ty = t2), _)
      equation
        true = subtype2(t1, t2, requireRecordNamesEqual);
      then
        true;

    case (DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()}, ty = t1),DAE.T_ARRAY(ty = t2), _)
      equation
        true = subtype2(t1, t2, requireRecordNamesEqual);
      then
        true;

    case (DAE.T_ARRAY(dims = {DAE.DIM_EXP(exp = e1)}, ty = t1),
          DAE.T_ARRAY(dims = {DAE.DIM_EXP(exp = e2)}, ty = t2), _)
      equation
        /* HUGE TODO: FIXME: After MSL is updated? */
        // true = Expression.expEqual(e1,e2);
        true = subtype2(t1, t2, requireRecordNamesEqual);
      then
        true;

    case (DAE.T_ARRAY(ty = t1),
          DAE.T_ARRAY(dims = {DAE.DIM_EXP(exp = _)}, ty = t2), _)
      equation
        true = subtype2(t1, t2, requireRecordNamesEqual);
      then
        true;

    case (DAE.T_ARRAY(dims = {DAE.DIM_EXP(exp = _)}, ty = t1),
          DAE.T_ARRAY(ty = t2), _)
      equation
        true = subtype2(t1, t2, requireRecordNamesEqual);
      then
        true;

    // Array
    case (DAE.T_ARRAY(dims = {dim1}, ty = t1),DAE.T_ARRAY(dims = {dim2}, ty = t2), _)
      equation
        /*
        true = boolOr(Expression.dimensionsKnownAndEqual(dim1, dim2),
                      Expression.dimensionsEqualAllowZero(dim1, dim2));
        */
        true = Expression.dimensionsKnownAndEqual(dim1, dim2);
        true = subtype2(t1, t2, requireRecordNamesEqual);
      then
        true;

    // External objects use a nominal type system
    case (DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(p1)),
          DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(p2)), _)
      then
        Absyn.pathEqual(p1,p2);

    // Complex type
    case (DAE.T_COMPLEX(complexClassType = st1,varLst = els1),
          DAE.T_COMPLEX(complexClassType = st2,varLst = els2), _)
      equation
        true = classTypeEqualIfRecord(st1, st2) or not requireRecordNamesEqual "We need to add a cast from one record to another";
        true = subtypeVarlist(els1, els2);
      then
        true;

    // A complex type that extends a basic type is checked against the baseclass basic type
    case (DAE.T_SUBTYPE_BASIC(complexClassType = st1,varLst = els1,complexType = tp1),tp2,_)
      equation
        res = subtype2(tp1, tp2, requireRecordNamesEqual);
      then
        res;

    // A complex type that extends a basic type is checked against the baseclass basic type
    case (tp1,DAE.T_SUBTYPE_BASIC(complexClassType = st1,varLst = els1,complexType = tp2),_)
      equation
        res = subtype2(tp1, tp2, requireRecordNamesEqual);
      then
        res;

    // Check of tuples, similar to complex. Just that identifier name do not have to be checked. Only types are checked.
    case (DAE.T_TUPLE(tupleType = type_list1),
          DAE.T_TUPLE(tupleType = type_list2),_)
      equation
        true = subtypeTypelist(type_list1, type_list2, requireRecordNamesEqual);
      then
        true;

    // Part of MetaModelica extension. KS
    case (DAE.T_METALIST(listType = t1),DAE.T_METALIST(listType = t2),_) then subtype(t1,t2);
    case (DAE.T_METAARRAY(ty = t1),DAE.T_METAARRAY(ty = t2),_) then subtype(t1,t2);
    case (DAE.T_METATUPLE(types = tList1),DAE.T_METATUPLE(types = tList2),_)
      equation
        res = subtypeTypelist(tList1,tList2,requireRecordNamesEqual);
      then res;
    case (DAE.T_METAOPTION(optionType = t1),DAE.T_METAOPTION(optionType = t2),_)
      then subtype2(t1,t2,requireRecordNamesEqual);

    case (DAE.T_METABOXED(ty = t1),DAE.T_METABOXED(ty = t2),_) then subtype2(t1,t2,requireRecordNamesEqual);
    case (DAE.T_METABOXED(ty = t1),t2,_) equation true = isBoxedType(t2); then subtype2(t1,t2,requireRecordNamesEqual);
    case (t1,DAE.T_METABOXED(ty = t2),_) equation true = isBoxedType(t1); then subtype2(t1,t2,requireRecordNamesEqual);

    case (DAE.T_METAPOLYMORPHIC(name = l1),DAE.T_METAPOLYMORPHIC(name = l2),_) then l1 ==& l2;
    case (DAE.T_UNKNOWN(_),t2,_) then true;
    case (t1,DAE.T_UNKNOWN(_),_) then true;
    case (DAE.T_NORETCALL(_),DAE.T_NORETCALL(_),_) then true;

    // MM Function Reference
    case (DAE.T_FUNCTION(funcArg = farg1,funcResultType = t1),DAE.T_FUNCTION(funcArg = farg2,funcResultType = t2),_)
      equation
        tList1 = List.map(farg1, Util.tuple42);
        tList2 = List.map(farg2, Util.tuple42);
        true = subtypeTypelist(tList1,tList2,requireRecordNamesEqual);
        true = subtype2(t1,t2,requireRecordNamesEqual);
      then true;

    case(DAE.T_METARECORD(utPath=p1),DAE.T_METARECORD(utPath=p2),_)
      then Absyn.pathEqual(p1,p2);

    case (DAE.T_METAUNIONTYPE(paths = _, source = {p1}),DAE.T_METARECORD(utPath=p2),_)
      then Absyn.pathEqual(p1,p2);

    case (DAE.T_METARECORD(utPath=p1),DAE.T_METAUNIONTYPE(paths = _, source = {p2}),_)
      then Absyn.pathEqual(p1,p2);

    // <uniontype> = <uniontype>
    case (DAE.T_METAUNIONTYPE(paths = _, source = {p1}), DAE.T_METAUNIONTYPE(paths = _, source = {p2}),_)
      then Absyn.pathEqual(p1,p2);
    case (DAE.T_METAUNIONTYPE(paths = _, source = {p1}), DAE.T_COMPLEX(complexClassType=ClassInf.META_UNIONTYPE(_), source = {p2}),_)
      then Absyn.pathEqual(p1,p2);
    case(DAE.T_COMPLEX(complexClassType=ClassInf.META_UNIONTYPE(_), source = {p2}), DAE.T_METAUNIONTYPE(paths = _, source = {p1}),_)
      then Absyn.pathEqual(p1,p2);

    case (DAE.T_CODE(ty = c1),DAE.T_CODE(ty = c2),_) then valueEq(c1,c2);

    case (DAE.T_METATYPE(ty = t1),DAE.T_METATYPE(ty = t2),_) then subtype2(t1,t2,requireRecordNamesEqual);
    case (t1,DAE.T_METATYPE(ty = t2),_) then subtype2(t1,t2,requireRecordNamesEqual);
    case (DAE.T_METATYPE(ty = t1),t2,_) then subtype2(t1,t2,requireRecordNamesEqual);

    case (t1,t2,_)
      equation
        /* Uncomment for debugging
        l1 = unparseType(t1);
        l2 = unparseType(t2);
        l1 = stringAppendList({"- Types.subtype failed:\n  t1=",l1,"\n  t2=",l2});
        print(l1);
        */
      then false;
  end matchcontinue;
end subtype2;

protected function subtypeTypelist "PR. function: subtypeTypelist
  This function checks if the both Type lists matches types, element by element."
  input list<Type> inTypeLst1;
  input list<Type> inTypeLst2;
  input Boolean requireRecordNamesEqual;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inTypeLst1,inTypeLst2,requireRecordNamesEqual)
    local
      Type t1,t2;
      list<Type> rest1,rest2;

    case ({},{},_) then true;
    case ((t1 :: rest1),(t2 :: rest2),_)
      equation
        true = subtype2(t1, t2, requireRecordNamesEqual);
      then subtypeTypelist(rest1, rest2, requireRecordNamesEqual);
    else false;  /* default */
  end matchcontinue;
end subtypeTypelist;

protected function subtypeVarlist "function: subtypeVarlist
  This function checks if the Var list in the first list is a
  subset of the list in the second argument.  More precisely, it
  checks if, for each Var in the second list there is a Var in
  the first list with a type that is a subtype of the Var in the
  second list."
  input list<Var> inVarLst1;
  input list<Var> inVarLst2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inVarLst1,inVarLst2)
    local
      Type t1,t2;
      list<Var> l,vs;
      Ident n;

    case (_,{}) then true;

    case (l,(DAE.TYPES_VAR(name = n,ty = t2) :: vs))
      equation
        DAE.TYPES_VAR(ty = t1) = varlistLookup(l, n);
        true = subtype2(t1, t2, false);
      then subtypeVarlist(l, vs);

    else false;  /* default */
  end matchcontinue;
end subtypeVarlist;

public function varlistLookup "function: varlistLookup
  Given a list of Var and a name, this function finds any Var with the given name."
  input list<Var> inVarLst;
  input Ident inIdent;
  output Var outVar;
algorithm
  outVar := matchcontinue (inVarLst,inIdent)
    local
      Var v;
      Ident n,name;
      list<Var> vs;

    case (((v as DAE.TYPES_VAR(name = n)) :: _),name)
      equation
        true = stringEq(n, name);
      then
        v;

    case ((v :: vs),name)
      equation
        v = varlistLookup(vs, name);
      then
        v;
  end matchcontinue;
end varlistLookup;

public function lookupComponent "function: lookupComponent
  This function finds a subcomponent by name."
  input Type inType;
  input Ident inIdent;
  output Var outVar;
algorithm
  outVar := matchcontinue (inType,inIdent)
    local
      Var v;
      Type t,ty,ty_1;
      Ident n,id;
      ClassInf.State st;
      list<Var> cs;
      Option<Type> bc;
      Attributes attr;
      Binding bnd;
      DAE.Dimension dim;
      Option<DAE.Const> cnstForRange;

    case (t,n)
      equation
        true = basicType(t);
        v = lookupInBuiltin(t, n);
      then
        v;

    case (DAE.T_COMPLEX(complexClassType = st,varLst = cs),id)
      equation
        v = lookupComponent2(cs, id);
      then
        v;

    case (DAE.T_SUBTYPE_BASIC(complexClassType = st,varLst = cs),id)
      equation
        v = lookupComponent2(cs, id);
      then
        v;

    case (DAE.T_ARRAY(dims = {dim},ty = DAE.T_COMPLEX(complexClassType = st,varLst = cs)),id)
      equation
        DAE.TYPES_VAR(n,attr,ty,bnd,cnstForRange) = lookupComponent2(cs, id);
        ty_1 = DAE.T_ARRAY(ty,{dim},DAE.emptyTypeSource);
      then
        DAE.TYPES_VAR(n,attr,ty_1,bnd,cnstForRange);

    case (DAE.T_ARRAY(dims = {dim},ty = DAE.T_SUBTYPE_BASIC(complexClassType = st,varLst = cs)),id)
      equation
        DAE.TYPES_VAR(n,attr,ty,bnd,cnstForRange) = lookupComponent2(cs, id);
        ty_1 = DAE.T_ARRAY(ty,{dim},DAE.emptyTypeSource);
      then
        DAE.TYPES_VAR(n,attr,ty_1,bnd,cnstForRange);

    case (_,id)
      equation
        // Print.printBuf("- Looking up " +& id +& " in noncomplex type\n");
      then fail();
  end matchcontinue;
end lookupComponent;

protected function lookupInBuiltin "function: lookupInBuiltin
  Since builtin types are not represented as DAE.T_COMPLEX, special care
  is needed to be able to lookup the attributes (*start* etc) in
  them.

  This is not a complete solution.  The current way of mapping the
  both the Modelica type Real and the simple type RealType to
  DAE.T_REAL is a bit problematic, since it does not make a
  difference between Real and RealType, which makes the
  translator accept things like x.start.start.start."
  input Type inType;
  input Ident inIdent;
  output Var outVar;
algorithm
  outVar := matchcontinue (inType,inIdent)
    local
      Var v;
      list<Var> cs;
      Ident id;

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
  end matchcontinue;
end lookupInBuiltin;

protected function lookupComponent2 "function: lookupComponent2
  This function finds a named Var in a list of Vars, comparing
  the name against the second argument to this function."
  input list<Var> inVarLst;
  input Ident inIdent;
  output Var outVar;
algorithm
  outVar := matchcontinue (inVarLst,inIdent)
    local
      Var v;
      Ident n,m;
      list<Var> vs;

    case (((v as DAE.TYPES_VAR(name = n)) :: _),m)
      equation
        true = stringEq(n, m);
      then
        v;

    case ((v :: vs),n)
      equation
        v = lookupComponent2(vs, n);
      then
        v;
  end matchcontinue;
end lookupComponent2;

public function makeArray "function: makeArray
  This function makes an array type given a Type and an Absyn.ArrayDim"
  input Type inType;
  input Absyn.ArrayDim inArrayDim;
  output Type outType;
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

public function makeArraySubscripts "function: makeArray
   This function makes an array type given a Type and a list of DAE.Subscript"
  input Type inType;
  input list<DAE.Subscript> lst;
  output Type outType;
algorithm
  outType := matchcontinue (inType,lst)
    local
      Type t;
      Integer i;
      DAE.Exp e;
    case (t,{}) then t;
    case (t,DAE.WHOLEDIM()::lst)
      equation
        t = makeArraySubscripts(DAE.T_ARRAY(t,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),lst);
      then
        t;
    case (t,DAE.SLICE(e)::lst)
      equation
        t = makeArraySubscripts(DAE.T_ARRAY(t,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),lst);
      then
        t;
    case (t,DAE.WHOLE_NONEXP(e)::lst)
      equation
        t = makeArraySubscripts(DAE.T_ARRAY(t,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),lst);
      then
        t;

    case (t,DAE.INDEX(DAE.ICONST(i))::lst)
      equation
        t = makeArraySubscripts(DAE.T_ARRAY(t,{DAE.DIM_INTEGER(i)},DAE.emptyTypeSource),lst);
      then
        t;
     case (t,DAE.INDEX(_)::lst)
      equation
        t = makeArraySubscripts(DAE.T_ARRAY(t,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),lst);
      then
        t;
  end matchcontinue;
end makeArraySubscripts;

public function liftArray "function: liftArray
  This function turns a type into an array of that type.
  If the type already is an array, another dimension is simply added."
  input Type inType;
  input DAE.Dimension inDimension;
  output Type outType;
algorithm
  outType := DAE.T_ARRAY(inType, {inDimension}, DAE.emptyTypeSource);
end liftArray;

public function liftArrayListDims "
  This function turns a type into an array of that type."
  input Type inType;
  input DAE.Dimensions inDimensionLst;
  output Type outType;
algorithm
  outType := match (inType,inDimensionLst)
    local
      Type ty;
      DAE.Dimension d;
      DAE.Dimensions rest;
    case (ty,{}) then ty;
    case (ty,d::rest) then liftArray(liftArrayListDims(ty,rest),d);
  end match;
end liftArrayListDims;

public function liftArrayRight "function: liftArrayRight
  This function adds an array dimension to *the right* of the passed type."
  input Type inType;
  input DAE.Dimension inIntegerOption;
  output Type outType;
algorithm
  outType := matchcontinue (inType,inIntegerOption)
    local
      Type ty_1,ty;
      DAE.Dimension dim;
      DAE.TypeSource ts;
      DAE.Dimension d;
      ClassInf.State ci;
      list<Var> varlst;
      EqualityConstraint ec;
      Type tty;

    case (DAE.T_ARRAY(dims = {dim},ty = ty, source = ts),d)
      equation
        ty_1 = liftArrayRight(ty, d);
      then
        DAE.T_ARRAY(ty_1, {dim}, ts);

    case(DAE.T_SUBTYPE_BASIC(ci,varlst,ty,ec,ts),d)
      equation
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

public function unliftArray "function: unliftArray
  This function turns an array of a type into that type."
  input Type inType;
  output Type outType;
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
  input Type inType;
  output Type outType;
  output DAE.Dimension dim;
algorithm
  (outType,dim) := match (inType)
    local
      Type ty;
    case (DAE.T_METALIST(listType = ty)) then (boxIfUnboxedType(ty),DAE.DIM_UNKNOWN());
    case (DAE.T_ARRAY(dims = {dim},ty = ty)) then (ty,dim);
    case (DAE.T_SUBTYPE_BASIC(complexType = ty))
      equation
        (ty,dim) = unliftArrayOrList(ty);
      then (ty,dim);
  end match;
end unliftArrayOrList;

protected function typeArraydim "function: typeArraydim
  If type is an array, return it array dimension"
  input Type inType;
  output DAE.Dimension outArrayDim;
algorithm
  outArrayDim := matchcontinue (inType)
    local DAE.Dimension dim;
    case (DAE.T_ARRAY(dims = {dim})) then dim;
  end matchcontinue;
end typeArraydim;

public function arrayElementType "function: arrayElementType
  This function turns an array into the element type of the array."
  input Type inType;
  output Type outType;
algorithm
  outType := match (inType)
    local Type ty;

    case (DAE.T_ARRAY(ty = ty)) then arrayElementType(ty);
    case (DAE.T_SUBTYPE_BASIC(complexType = ty)) then arrayElementType(ty);
    else inType;

  end match;
end arrayElementType;

public function setArrayElementType
  input Type inType;
  input Type inBaseType;
  output Type outType;
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
  input EqMod eq;
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
  input Option<EqMod> eq;
  output String str;
algorithm
  str := match(eq)
    local EqMod e;
    case NONE() then "NONE()";
    case SOME(e) then unparseEqMod(e);
  end match;
end unparseOptionEqMod;

public function unparseType
"function: unparseType
  This function prints a Modelica type as a piece of Modelica code."
  input Type inType;
  output String outString;
algorithm
  outString := match (inType)
    local
      Ident s1,s2,str,dims,res,vstr,name,st_str,bc_tp_str,paramstr,restypestr,tystr,funcstr;
      list<Ident> l,vars,paramstrs,tystrs;
      Type ty,bc_tp,restype;
      DAE.Dimensions dimlst;
      list<Var> vs;
      ClassInf.State ci_state;
      list<FuncArg> params;
      Absyn.Path path,p;
      list<Type> tys;
      DAE.CodeType codeType;
      DAE.TypeSource ts;

    case (DAE.T_INTEGER(varLst = {})) then "Integer";
    case (DAE.T_REAL(varLst = {})) then "Real";
    case (DAE.T_STRING(varLst = {})) then "String";
    case (DAE.T_BOOL(varLst = {})) then "Boolean";

    case (DAE.T_INTEGER(varLst = vs))
      equation
        s1 = stringDelimitList(List.map(vs, unparseVarAttr),", ");
        s2 = "Integer(" +& s1 +& ")";
      then s2;
    case (DAE.T_REAL(varLst = vs))
      equation
        s1 = stringDelimitList(List.map(vs, unparseVarAttr),", ");
        s2 = "Real(" +& s1 +& ")";
      then s2;
    case (DAE.T_STRING(varLst = vs))
      equation
        s1 = stringDelimitList(List.map(vs, unparseVarAttr),", ");
        s2 = "String(" +& s1 +& ")";
      then s2;
    case (DAE.T_BOOL(varLst = vs))
      equation
        s1 = stringDelimitList(List.map(vs, unparseVarAttr),", ");
        s2 = "Boolean(" +& s1 +& ")";
      then s2;
    case (DAE.T_ENUMERATION(path = path, names = l, literalVarLst=vs))
      equation
        s1 = Util.if_(Config.typeinfo(), " /*" +& Absyn.pathString(path) +& "*/ (", "(");
        s2 = stringDelimitList(l, ", ");
        /* s2 = stringAppendList(List.map(vs, unparseVar));
        s2 = Util.if_(s2 ==& "", "", "(" +& s2 +& ")"); */
        str = stringAppendList({"enumeration",s1,s2,")"});
      then
        str;

    case (ty as DAE.T_ARRAY(ty = _))
      equation
        (ty,dimlst) = flattenArrayTypeOpt(ty);
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

    case (DAE.T_SUBTYPE_BASIC(complexClassType = ci_state, varLst = vs, complexType = bc_tp))
      equation
        res = Absyn.pathString(ClassInf.getStateName(ci_state));
        st_str = ClassInf.printStateStr(ci_state);
        bc_tp_str = unparseType(bc_tp);
        res = stringAppendList({"(",res," ",st_str," bc:",bc_tp_str,")"});
      then
        res;

    case (DAE.T_COMPLEX(complexClassType = ci_state,varLst = vs))
      equation
        res = Absyn.pathString(ClassInf.getStateName(ci_state));
        st_str = ClassInf.printStateStr(ci_state);
        res = stringAppendList({res," ",st_str});
      then
        res;

    case (DAE.T_FUNCTION(funcArg = params, funcResultType = restype, source = ts))
      equation
        funcstr = stringDelimitList(List.map(ts, Absyn.pathString), ", ");
        paramstrs = List.map(params, unparseParam);
        paramstr = stringDelimitList(paramstrs, ", ");
        restypestr = unparseType(restype);
        res = stringAppendList({funcstr,"<function>(",paramstr,") => ",restypestr});
      then
        res;

    case (DAE.T_TUPLE(tupleType = tys))
      equation
        tystrs = List.map(tys, unparseType);
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
    case (DAE.T_METALIST(listType = ty))
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
    case (DAE.T_METAUNIONTYPE(paths=_, source = {p}))
      equation
        res = Absyn.pathStringNoQual(p);
      then
        res;

    // MetaModelica uniontype (but we know which record in the UT it is)
    case (DAE.T_METARECORD(utPath=_, fields = vs, source = {p}))
      equation
        str = Absyn.pathStringNoQual(p);
        vars = List.map(vs, unparseVar);
        vstr = stringAppendList(vars);
        res = stringAppendList({"metarecord ",str,"\n",vstr,"end ", str, ";"});
      then res;

    // MetaModelica boxed type
    case (DAE.T_METABOXED(ty = ty))
      equation
        res = unparseType(ty);
        res = "#" /* this is a box */ +& res;
      then res;

    // MetaModelica Option type
    case (DAE.T_METAOPTION(optionType = DAE.T_UNKNOWN(_))) then "Option<Any>";
    case (DAE.T_METAOPTION(optionType = ty))
      equation
        tystr = unparseType(ty);
        res = stringAppendList({"Option<",tystr,">"});
      then
        res;

    case (DAE.T_METATYPE(ty = ty)) then unparseType(ty);

    case (DAE.T_NORETCALL(_))              then "#NORETCALL#";
    case (DAE.T_UNKNOWN(_))                then "#T_UNKNOWN#";
    case (DAE.T_ANYTYPE(anyClassType = _)) then "#ANYTYPE#";
    case (DAE.T_CODE(ty = codeType)) then printCodeTypeStr(codeType);
    case (DAE.T_FUNCTION_REFERENCE_VAR(functionType=ty)) then "#FUNCTION_REFERENCE_VAR#" +& unparseType(ty);
    case (DAE.T_FUNCTION_REFERENCE_FUNC(functionType=ty)) then "#FUNCTION_REFERENCE_FUNC#" +& unparseType(ty);
    case (ty) then "Internal error Types.unparseType: not implemented yet\n";
  end match;
end unparseType;

public function unparseConst
  input Const inConst;
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
  input Const inConst;
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
  input TupleConst inTupleConst;
  output String outString;
algorithm
  outString := match (inTupleConst)
    local
      Ident cstr,res,res_1;
      Const c;
      list<Ident> strlist;
      list<TupleConst> constlist;
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

public function printTypeStr "function: printTypeStr
  This function prints a textual description of a Modelica type to a string.
  If the type is not one of the primitive types, it simply prints composite."
  input Type inType;
  output String str;
algorithm
  str := matchcontinue (inType)
    local
      list<Var> vars;
      list<Ident> l;
      ClassInf.State st;
      list<DAE.Dimension> dims;
      Type t,ty,restype;
      list<FuncArg> params;
      list<Type> tys;
      String s1,s2,compType;
      Absyn.Path path;
      DAE.TypeSource ts;

    case (DAE.T_INTEGER(varLst = vars))
      equation
        s1 = List.toString(vars, printVarStr, "Integer", "(", ", ", ")", false);
        str = s1 +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_REAL(varLst = vars))
      equation
        s1 = List.toString(vars, printVarStr, "Real", "(", ", ", ")", false);
        str = s1 +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_STRING(varLst = vars))
      equation
        s1 = List.toString(vars, printVarStr, "String", "(", ", ", ")", false);
        str = s1 +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_BOOL(varLst = vars))
      equation
        s1 = List.toString(vars, printVarStr, "Boolean", "(", ", ", ")", false);
        str = s1 +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_ENUMERATION(names = l, literalVarLst = vars))
      equation
        s1 = List.toString(vars, printVarStr, "Enumeration", "(", ", ", ")", false);
        str = s1 +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_SUBTYPE_BASIC(complexClassType = st, complexType = t, varLst = vars))
      equation
        compType = printTypeStr(t);
        s1 = ClassInf.printStateStr(st);
        s2 = stringDelimitList(List.map(vars, printVarStr),", ");
        str = stringAppendList({"composite(",s1,"{",s2,"} derived from ", compType});
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_COMPLEX(complexClassType = st,varLst = vars))
      equation
        s1 = ClassInf.printStateStr(st);
        s2 = stringDelimitList(List.map(vars, printVarStr),", ");
        str = stringAppendList({"composite(",s1,"{",s2,"})"});
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_ARRAY(dims = dims,ty = t))
      equation
        s1 = stringDelimitList(List.map(dims, ExpressionDump.dimensionString), ", ");
        s2 = printTypeStr(t);
        str = stringAppendList({s2,"[",s1,"]"});
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_FUNCTION(funcArg = params,funcResultType = restype))
      equation
        s1 = printParamsStr(params);
        s2 = printTypeStr(restype);
        str = stringAppendList({"function(", s1,") => ",s2});
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_TUPLE(tupleType = tys))
      equation
        s1 = stringDelimitList(List.map(tys, printTypeStr),", ");
        str = stringAppendList({"(",s1,")"});
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // MetaModelica tuple
    case (DAE.T_METATUPLE(types = tys, source = ts))
      equation
        str = printTypeStr(DAE.T_TUPLE(tys,ts));
        str = str +& printTypeSourceStr(ts);
      then
        str;

    // MetaModelica list
    case (DAE.T_METALIST(listType = ty))
      equation
        s1 = printTypeStr(ty);
        str = stringAppendList({"list<",s1,">"});
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // MetaModelica Option
    case (DAE.T_METAOPTION(optionType = ty))
      equation
        s1 = printTypeStr(ty);
        str = stringAppendList({"Option<",s1,">"});
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // MetaModelica Array
    case (DAE.T_METAARRAY(ty = ty))
      equation
        s1 = printTypeStr(ty);
        str = stringAppendList({"array<",s1,">"});
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // MetaModelica Boxed
    case (DAE.T_METABOXED(ty = ty))
      equation
        s1 = printTypeStr(ty);
        str = stringAppendList({"boxed<",s1,">"});
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // MetaModelica polymorphic
    case (DAE.T_METAPOLYMORPHIC(name = s1))
      equation
        str = stringAppendList({"polymorphic<",s1,">"});
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // NoType
    case (DAE.T_UNKNOWN(ts))
      equation
        str = "T_UNKNOWN";
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // AnyType of none
    case (DAE.T_ANYTYPE(anyClassType = NONE()))
      equation
        str = "ANYTYPE()";
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;
    // AnyType of some
    case (DAE.T_ANYTYPE(anyClassType = SOME(st)))
      equation
        s1 = ClassInf.printStateStr(st);
        str = "ANYTYPE(" +& s1 +& ")";
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    case (DAE.T_NORETCALL(_))
      equation
        str = "()";
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // MetaType
    case (DAE.T_METATYPE(ty = t))
      equation
        s1 = printTypeStr(t);
        str = stringAppendList({"METATYPE(", s1, ")"});
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // Uniontype, Metarecord
    case (t)
      equation
        {path} = getTypeSource(t);
        s1 = Absyn.pathStringNoQual(path);
        str = "#" +& s1 +& "#";
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

    // Code
    case (DAE.T_CODE(DAE.C_EXPRESSION(),_)) then "$Code(Expression)";
    case (DAE.T_CODE(DAE.C_TYPENAME(),_)) then "$Code(TypeName)";
    case (DAE.T_CODE(DAE.C_VARIABLENAME(),_)) then "$Code(VariableName)";
    case (DAE.T_CODE(DAE.C_VARIABLENAMES(),_)) then "$Code(VariableName[:])";

    // All the other ones we don't handle
    case (_)
      equation
        str = "Types.printTypeStr failed";
        str = str +& printTypeSourceStr(getTypeSource(inType));
      then
        str;

  end matchcontinue;
end printTypeStr;

public function printConnectorTypeStr
"Author BZ, 2009-09
 Print the connector-type-name"
  input Type it;
  output String s "Connector type";
  output String s2 "Components of connector";
algorithm
  (s,s2) := matchcontinue(it)
    local
      ClassInf.State st;
      Absyn.Path connectorName;
      list<Var> vars;
      DAE.TypeSource ts;
      list<String> varNames;
      Boolean isExpandable;
      String isExpandableStr;
      Type t;

    case(DAE.T_COMPLEX(complexClassType = (st as ClassInf.CONNECTOR(connectorName,isExpandable)),varLst = vars, source = ts))
      equation
        varNames = List.map(vars,varName);
        isExpandableStr = Util.if_(isExpandable,"/* expandable */ ", "");
        s = isExpandableStr +& Absyn.pathString(connectorName);
        s2 = "{" +& stringDelimitList(varNames,", ") +& "}";
      then
        (s,s2);

    // TODO! check if we can get T_SUBTYPE_BASIC here??!!
    case(DAE.T_SUBTYPE_BASIC(complexClassType = (st as ClassInf.CONNECTOR(connectorName,isExpandable)), varLst = vars, complexType = t, source = ts))
      equation
        varNames = List.map(vars,varName);
        isExpandableStr = Util.if_(isExpandable,"/* expandable */ ", "");
        s = isExpandableStr +& Absyn.pathString(connectorName);
        s2 = "{" +& stringDelimitList(varNames,", ") +& "}" +& " subtype of: " +& printTypeStr(t);
      then
        (s,s2);

    case (_) then ("", unparseType(it));
  end matchcontinue;
end printConnectorTypeStr;

public function printParamsStr "function: printParams
  Prints function arguments to a string."
  input list<FuncArg> inFuncArgLst;
  output String str;
algorithm
  str := matchcontinue (inFuncArgLst)
    local
      Ident n;
      Type t;
      list<FuncArg> params;
      String s1,s2;
    case {} then "";
    case {(n,t,_,_)}
      equation
        s1 = printTypeStr(t);
        str = stringAppendList({n," :: ",s1});
      then
        str;
    case (((n,t,_,_) :: params))
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
  input Var inVar;
  output String outString;
algorithm
  outString := matchcontinue (inVar)
    local
      Ident res,n,bindStr,valStr;
      Values.Value value;
      DAE.Exp e;

    case DAE.TYPES_VAR(name = n, binding = DAE.EQBOUND(exp=e))
      equation
        bindStr = ExpressionDump.printExpStr(e);
        res = stringAppendList({n,"=",bindStr});
      then
        res;
    case DAE.TYPES_VAR(name = n, binding = DAE.VALBOUND(valBound=value))
      equation
        valStr = ValuesUtil.valString(value);
        res = stringAppendList({n,"=",valStr});
      then
        res;
    case(_) then "";
  end matchcontinue;
end unparseVarAttr;

public function unparseVar
"function: unparseVar
  Prints a variable to a string."
  input Var inVar;
  output String outString;
algorithm
  outString := match (inVar)
    local
      Ident t,res,n;
      Type typ;

    case DAE.TYPES_VAR(name = n,ty = typ)
      equation
        t = unparseType(typ);
        res = stringAppendList({t," ",n,";\n"});
      then
        res;
  end match;
end unparseVar;

protected function unparseParam "function: unparseParam
  Prints a function argument to a string."
  input FuncArg inFuncArg;
  output String outString;
algorithm
  outString := match (inFuncArg)
    local
      Ident tstr,res,id,cstr,estr;
      Type ty;
      DAE.Const c;
      DAE.Exp exp;
    case ((id,ty,c,NONE()))
      equation
        tstr = unparseType(ty);
        cstr = DAEUtil.constStrFriendly(c);
        res = stringAppendList({tstr," ",cstr,id});
      then
        res;
    case ((id,ty,c,SOME(exp)))
      equation
        tstr = unparseType(ty);
        cstr = DAEUtil.constStrFriendly(c);
        estr = ExpressionDump.printExpStr(exp);
        res = stringAppendList({tstr," ",cstr,id," := ",estr});
      then
        res;
  end match;
end unparseParam;

public function printVarStr "function: printVar
  author: LS
  Prints a Var to the a string."
  input Var inVar;
  output String str;
algorithm
  str := matchcontinue (inVar)
    local
      Ident vs,n;
      SCode.Variability var;
      Type typ;
      Binding bind;
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

public function printBindingStr "function: print_binding_str
  Print a variable binding to a string."
  input Binding inBinding;
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
    case(_) then "";
  end matchcontinue;
end printBindingStr;

public function makeFunctionType "function: makeFunctionType
  author: LS
  Creates a function type from a function name an a list of input and
  output variables."
  input Absyn.Path p;
  input list<Var> vl;
  input DAE.FunctionAttributes functionAttributes;
  output Type outType;
protected
  list<Var> invl,outvl;
  list<FuncArg> fargs;
  Type rettype;
algorithm
  invl := getInputVars(vl);
  outvl := getOutputVars(vl);
  fargs := makeFargsList(invl);
  rettype := makeReturnType(outvl);
  outType := DAE.T_FUNCTION(fargs,rettype,functionAttributes,{p});
end makeFunctionType;

public function makeEnumerationType
  "Creates an enumeration type from a name and an enumeration type containing
  the literal variables."
  input Absyn.Path inPath;
  input Type inType;
  output Type outType;
algorithm
  outType := matchcontinue(inPath, inType)
    local
      Absyn.Path p;
      list<Ident> names, attr_names;
      list<Var> vars, attrs;
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

    case (_, _)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- Types.makeEnumerationType failed on " +& printTypeStr(inType));
      then
        fail();
  end matchcontinue;
end makeEnumerationType;

public function makeEnumerationType1
  "Helper function to makeEnumerationType. Updates a list of enumeration
  literals with the correct index and type."
  input Absyn.Path inPath;
  input list<Var> inVarLst;
  input list<Ident> inNames;
  input Integer inIdx;
  output list<Var> outVarLst;
algorithm
  outVarLst := match (inPath,inVarLst,inNames,inIdx)
    local
      list<Ident> names;
      Absyn.Path p;
      Ident name;
      list<Var> xs,vars;
      Type t;
      Integer idx;
      Attributes attributes;
      Binding binding;
      Var var;
      Option<DAE.Const> cnstForRange;

    case (p,DAE.TYPES_VAR(name,attributes,_,binding,cnstForRange) :: xs,names,idx)
      equation
        vars = makeEnumerationType1(p, xs, names, idx+1);
        t = DAE.T_ENUMERATION(SOME(idx),p,names,{},{},{p});
        var = DAE.TYPES_VAR(name,attributes,t,binding,cnstForRange);
      then
        (var :: vars);
    case (p,{},names,_) then {};
  end match;
end makeEnumerationType1;

public function printFarg "function: printFarg
  Prints a function argument to the Print buffer."
  input FuncArg inFuncArg;
algorithm
  _ := matchcontinue (inFuncArg)
    local
      Ident n;
      Type ty;
    case ((n,ty,_,_))
      equation
        Print.printErrorBuf(printTypeStr(ty));
        Print.printErrorBuf(" ");
        Print.printErrorBuf(n);
      then
        ();
  end matchcontinue;
end printFarg;

public function printFargStr "function: printFargStr
  Prints a function argument to a string"
  input FuncArg inFuncArg;
  output String outString;
algorithm
  outString := match (inFuncArg)
    local
      Ident s,res,n,cs;
      Type ty;
      DAE.Const c;
    case ((n,ty,c,_))
      equation
        s = unparseType(ty);
        cs = DAEUtil.constStrFriendly(c);
        res = stringAppendList({cs,s," ",n});
      then
        res;
  end match;
end printFargStr;

protected function getInputVars "function: getInputVars
  author: LS
  Retrieve all the input variables from a list of variables."
  input list<Var> vl;
  output list<Var> vl_1;
algorithm
  vl_1 := getVars(vl, isInputVar);
end getInputVars;

protected function getOutputVars "function: getOutputVars
  author: LS
  Retrieve all output variables from a list of variables."
  input list<Var> vl;
  output list<Var> vl_1;
algorithm
  vl_1 := getVars(vl, isOutputVar);
end getOutputVars;

public function getFixedVarAttribute "Returns the value of the fixed attribute of a builtin type"
  input Type tp;
  output Boolean fixed;
algorithm
  fixed :=  matchcontinue(tp)
    local
      Type ty;
      Boolean result;
      list<Var> vars;

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

public function getClassname "function: getClassname
  Return the classname from a type."
  input Type inType;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue (inType)
    local Absyn.Path p;
    case (inType)
      equation
        {p} = getTypeSource(inType);
      then p;
  end matchcontinue;
end getClassname;

public function getClassnameOpt "function: getClassname
  Return the classname as option from a type."
  input Type inType;
  output Option<Absyn.Path> outPath;
algorithm
  outPath := matchcontinue(inType)
    local Absyn.Path p;
    case _
      equation
        {p} = getTypeSource(inType);
      then SOME(p);
    case _ then NONE();
  end matchcontinue;
end getClassnameOpt;

public function getVars "function getVars
  author: LS
  Select the variables from the list for which the
  condition function given as second argument succeeds."
  input list<Var> inVarLst;
  input FuncTypeVarTo inFuncTypeVarTo;
  output list<Var> outVarLst;
  partial function FuncTypeVarTo
    input Var inVar;
  end FuncTypeVarTo;
algorithm
  outVarLst := matchcontinue (inVarLst,inFuncTypeVarTo)
    local
      list<Var> vl_1,vl;
      Var v;
      FuncTypeVarTo cond;
    case ({},_) then {};
    case ((v :: vl),cond)
      equation
        cond(v);
        vl_1 = getVars(vl, cond);
      then
        (v :: vl_1);
    case ((v :: vl),cond)
      equation
        failure(cond(v));
        vl_1 = getVars(vl, cond);
      then
        vl_1;
  end matchcontinue;
end getVars;

public function getConnectorVars
  "Returns the list of variables in a connector, or fails if the type is not a
  connector."
  input Type inType;
  output list<Var> outVars;
algorithm
  outVars := match(inType)
    local list<Var> vars;
    case (DAE.T_COMPLEX(
          complexClassType = ClassInf.CONNECTOR(path = _),
          varLst = vars))
      then vars;
  end match;
end getConnectorVars;

public function isInputVar
"Succeds if variable is an input variable."
  input Var inVar;
algorithm
  _ := match (inVar)
    local
      Attributes attr;

    case DAE.TYPES_VAR(attributes = attr)
      equation
        true = isInputAttr(attr);
        true = isPublicAttr(attr);
      then
        ();
  end match;
end isInputVar;

public function isOutputVar
"Succeds if variable is an output variable."
  input Var inVar;
algorithm
  _ := match (inVar)
    local
      Attributes attr;

    case DAE.TYPES_VAR(attributes = attr)
      equation
        true = isOutputAttr(attr);
        true = isPublicAttr(attr);
      then
        ();
  end match;
end isOutputVar;

public function isInputAttr "function: isInputAttr
  Returns true if the Attributes of a variable indicates
  that the variable is input."
  input Attributes inAttributes;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inAttributes)
    case DAE.ATTR(direction = Absyn.INPUT()) then true;
    case _ then false;
  end matchcontinue;
end isInputAttr;

public function isOutputAttr "function: isOutputAttr
  Returns true if the Attributes of a variable indicates
  that the variable is output."
  input Attributes inAttributes;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inAttributes)
    case DAE.ATTR(direction = Absyn.OUTPUT()) then true;
    case _ then false;
  end matchcontinue;
end isOutputAttr;

public function isBidirAttr "function: isBidirAttr
  Returns true if the Attributes of a variable indicates that the variable
  is bidirectional, i.e. neither input nor output."
  input Attributes inAttributes;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inAttributes)
    case DAE.ATTR(direction = Absyn.BIDIR()) then true;
    case _ then false;
  end matchcontinue;
end isBidirAttr;

public function isPublicAttr
  input Attributes inAttributes;
  output Boolean outIsPublic;
algorithm
  outIsPublic := match(inAttributes)
    case DAE.ATTR(visibility = SCode.PUBLIC()) then true;
    else false;
  end match;
end isPublicAttr;

public function isPublicVar
"true if variable is a public variable."
  input Var inVar;
  output Boolean b;
algorithm
  b := match (inVar)
    local
      Attributes attr;

    case DAE.TYPES_VAR(attributes = attr) then isPublicAttr(attr);
  end match;
end isPublicVar;

public function isProtectedVar
"true if variable is a protected variable."
  input Var inVar;
  output Boolean b;
algorithm
  b := match (inVar)
    local
      Attributes attr;

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
     /*
    case(DAE.TYPES_VAR(attributes = attrs))
      equation
        true = Types.isConstAttr(attrs);
      then false;
       */
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
    Ident name;

    case(DAE.TYPES_VAR(binding=DAE.EQBOUND(exp=exp)), _) then exp;
    case(DAE.TYPES_VAR(name=name, binding=DAE.UNBOUND()), _)
      equation
        str = "Record '" +& Absyn.pathString(inPath) +& "' member '" +& name +& "' has no default value and is not modifiable by a constructor function.\n";
        Error.addCompilerWarning(str);
      then
        DAE.ICONST(0);
  end match;
end getBindingExp;


public function isConstAttr
  input Attributes inAttributes;
  output Boolean outIsPublic;
algorithm
  outIsPublic := match(inAttributes)
    case DAE.ATTR(variability = SCode.CONST()) then true;
    else false;
  end match;
end isConstAttr;

public function makeFargsList
  "Makes a function argument list from a list of variables."
  input list<Var> vars;
  output list<FuncArg> fargs;
annotation(__OpenModelica_EarlyInline=true);
algorithm
  fargs := List.map(vars,makeFarg);
end makeFargsList;

protected function makeFarg
  "Makes a function argument list from a variable."
  input Var variable;
  output FuncArg farg;
algorithm
  farg := match (variable)
    local
      Ident n;
      Attributes attr;
      Type ty;
      Binding bnd;
      DAE.Const c;
      SCode.Variability var;
      Option<DAE.Exp> oexp;

    case DAE.TYPES_VAR(name = n,attributes = attr as DAE.ATTR(variability = var),ty = ty,binding = bnd)
      equation
        c = variabilityToConst(var);
        oexp = DAEUtil.bindingExp(bnd);
      then ((n,ty,c,oexp));
  end match;
end makeFarg;

protected function makeReturnType "function: makeReturnType
  author: LS
  Create a return type from a list of output variables.
  Depending on the length of the output variable list, different
  kinds of return types are created."
  input list<Var> inVarLst;
  output Type outType;
algorithm
  outType := matchcontinue (inVarLst)
    local
      Type ty;
      Var var;
      list<Type> tys;
      list<Var> vl;

    case {} then DAE.T_NORETCALL(DAE.emptyTypeSource);

    case {var}
      equation
        ty = makeReturnTypeSingle(var);
      then
        ty;

    case vl
      equation
        tys = makeReturnTypeTuple(vl);
      then
        DAE.T_TUPLE(tys,DAE.emptyTypeSource);
  end matchcontinue;
end makeReturnType;

protected function makeReturnTypeSingle "function: makeReturnTypeSingle
  author: LS
  Create the return type for a single return value."
  input Var inVar;
  output Type outType;
algorithm
  outType := match (inVar)
    local
      Type ty;

    case DAE.TYPES_VAR(ty = ty) then ty;
  end match;
end makeReturnTypeSingle;

protected function makeReturnTypeTuple "function: makeReturnTypeTuple
  author: LS
  Create the return type for a tuple, i.e. a function returning several
  values."
  input list<Var> inVarLst;
  output list<Type> outTypeLst;
algorithm
  outTypeLst := match (inVarLst)
    local
      list<Type> tys;
      Type ty;
      list<Var> vl;

    case {} then {};

    case (DAE.TYPES_VAR(ty = ty) :: vl)
      equation
        tys = makeReturnTypeTuple(vl);
      then
        (ty :: tys);
  end match;
end makeReturnTypeTuple;

public function isParameterVar "function: isParameter
  author: LS
  Succeds if a variable is a parameter."
  input Var inVar;
algorithm
  DAE.TYPES_VAR(attributes = DAE.ATTR(variability = SCode.PARAM(),visibility = SCode.PUBLIC())) := inVar;
end isParameterVar;

public function isConstant
  "Returns true of c is C_CONST."
  input Const c;
  output Boolean b;
algorithm
  b := match(c)
    case (DAE.C_CONST()) then true;
    else false;
  end match;
end isConstant;

public function isParameter
  "Returns true if c is C_PARAM."
  input Const c;
  output Boolean b;
algorithm
  b := match(c)
    case DAE.C_PARAM() then true;
    else false;
  end match;
end isParameter;

public function isParameterOrConstant "returns true if Const is PARAM or CONST"
  input Const c;
  output Boolean b;
algorithm
  b := match(c)
    case(DAE.C_CONST()) then true;
    case(DAE.C_PARAM()) then true;
    else false;
  end match;
end isParameterOrConstant;

public function isVar
  input Const inConst;
  output Boolean outIsVar;
algorithm
  outIsVar := match(inConst)
    case DAE.C_VAR() then true;
    else false;
  end match;
end isVar;

public function containReal "function: containReal
  Returns true if a builtin type, or array-type is Real."
  input list<Type> inTypeLst;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inTypeLst)
    local
      Boolean r1,r2,res;
      Type tp;
      list<Type> xs;

    case (DAE.T_ARRAY(ty = tp) :: xs)
      equation
        r1 = containReal({tp});
        r2 = containReal(xs);
        res = boolOr(r1, r2);
      then
        res;

    case (DAE.T_SUBTYPE_BASIC(complexType = tp)::xs)
      equation
        r1 = containReal({tp});
        r2 = containReal(xs);
        res = boolOr(r1,r2);
      then res;

    case (DAE.T_REAL(varLst = _) :: _) then true;

    case (_ :: xs)
      equation
        res = containReal(xs);
      then
        res;

    case (_) then false;
  end matchcontinue;
end containReal;

public function flattenArrayType "function: flattenArrayType
   Returns the element type of a Type and the list of dimensions of the type.
   The dimensions are in a backwards order ex:
   a[4,5] will give {5,4} in return value."
  input Type inType;
  output Type outType;
  output list<Integer> outIntegerLst;
algorithm
  (outType,outIntegerLst) := matchcontinue (inType)
    local
      Type ty_1,ty;
      list<Integer> dimlist_1,dimlist;
      Integer dim;
      DAE.Dimension d;

    case (DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()},ty = ty))
      equation
        (ty_1,dimlist_1) = flattenArrayType(ty);
      then
        (ty_1,dimlist_1);

    case (DAE.T_ARRAY(dims = {d},ty = ty))
      equation
        dim = Expression.dimensionSize(d);
        (ty_1,dimlist) = flattenArrayType(ty);
        dimlist_1 = listAppend(dimlist, {dim});
      then
        (ty_1,dimlist_1);
    // Complex type extending basetype.
    case (DAE.T_SUBTYPE_BASIC(complexType = ty))
      equation
        (ty_1,dimlist) = flattenArrayType(ty);
      then
        (ty_1,dimlist);

    case ty then (ty,{});

  end matchcontinue;
end flattenArrayType;

public function flattenArrayTypeOpt "function: flattenArrayTypeOpt
  Returns the element type of a Type and the list of dimensions of the type."
  input Type inType;
  output Type outType;
  output DAE.Dimensions outDimensionLst;
algorithm
  (outType,outDimensionLst) := matchcontinue (inType)
    local
      Type ty_1,ty;
      DAE.Dimensions dimlist, dims;
      DAE.Dimension dim;

    // Array type
    case (DAE.T_ARRAY(dims = {dim}, ty = ty))
      equation
        (ty_1,dimlist) = flattenArrayTypeOpt(ty);
      then
        (ty_1, dim :: dimlist);

    // Array type
    case (DAE.T_ARRAY(dims = dims, ty = ty))
      equation
        (ty_1,dimlist) = flattenArrayTypeOpt(ty);
        dimlist = listAppend(dims, dimlist);
      then
        (ty_1, dimlist);

    // Complex type extending basetype.
    case (DAE.T_SUBTYPE_BASIC(complexType = ty))
      equation
        (ty_1,dimlist) = flattenArrayTypeOpt(ty);
      then
        (ty_1,dimlist);

    // Element type
    case ty then (ty,{});
  end matchcontinue;
end flattenArrayTypeOpt;

public function getTypeName "function: getTypeName
  Return the type name of a Type."
  input Type inType;
  output String outString;
algorithm
  outString := matchcontinue (inType)
    local
      Ident n,dimstr,tystr,str;
      ClassInf.State st;
      Type ty,arrayty;
      list<Integer> dims;
      list<Ident> dimstrs;
    case (DAE.T_INTEGER(varLst = _)) then "Integer";
    case (DAE.T_REAL(varLst = _)) then "Real";
    case (DAE.T_STRING(varLst = _)) then "String";
    case (DAE.T_BOOL(varLst = _)) then "Boolean";
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
    case (arrayty as DAE.T_ARRAY(ty = _))
      equation
        (ty,dims) = flattenArrayType(arrayty);
        dimstrs = List.map(dims, intString);
        dimstr = stringDelimitList(dimstrs, ", ");
        tystr = getTypeName(ty);
        str = stringAppendList({tystr,"[",dimstr,"]"});
      then
        str;

    // MetaModelica type
    case (DAE.T_METALIST(listType = ty))
      equation
        n = getTypeName(ty);
      then
        n;

    case (_) then "Not nameable type or no type";
  end matchcontinue;
end getTypeName;

public function propAllConst "function: propAllConst
  author: LS
  If PROP_TUPLE, returns true if all of the flags are constant."
  input Properties inProperties;
  output Const outConst;
algorithm
  outConst := matchcontinue (inProperties)
    local
      Const c,res;
      TupleConst constant_;
      Ident str;
      Properties prop;
    case DAE.PROP(constFlag = c) then c;
    case DAE.PROP_TUPLE(tupleConst = constant_)
      equation
        res = propTupleAllConst(constant_);
      then
        res;
    case prop
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprint(Flags.FAILTRACE, "- prop_all_const failed: ");
        str = printPropStr(prop);
        Debug.fprintln(Flags.FAILTRACE, str);
      then
        fail();
  end matchcontinue;
end propAllConst;

public function propAnyConst "function: propAnyConst
  author: LS
  If PROP_TUPLE, returns true if any of the flags are true"
  input Properties inProperties;
  output Const outConst;
algorithm
  outConst := matchcontinue (inProperties)
    local
      Const constant_,res;
      Ident str;
      Properties prop;
      TupleConst tconstant_;
    case DAE.PROP(constFlag = constant_) then constant_;
    case DAE.PROP_TUPLE(tupleConst = tconstant_)
      equation
        res = propTupleAnyConst(tconstant_);
      then
        res;
    case prop
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprint(Flags.FAILTRACE, "- prop_any_const failed: ");
        str = printPropStr(prop);
        Debug.fprintln(Flags.FAILTRACE, str);
      then
        fail();
  end matchcontinue;
end propAnyConst;

protected function propTupleAnyConst "function: propTupleAnyConst
  author: LS
  Helper function to prop_any_const."
  input TupleConst inTupleConst;
  output Const outConst;
algorithm
  outConst := matchcontinue (inTupleConst)
    local
      Const c,res;
      TupleConst first,const;
      list<TupleConst> rest;
      Ident str;
    case DAE.SINGLE_CONST(const = c) then c;
    case DAE.TUPLE_CONST(tupleConstLst = (first :: rest))
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
        Debug.fprint(Flags.FAILTRACE, "- prop_tuple_any_const failed: ");
        str = printTupleConstStr(const);
        Debug.fprintln(Flags.FAILTRACE, str);
      then
        fail();
  end matchcontinue;
end propTupleAnyConst;

public function propTupleAllConst "function: propTupleAllConst
  author: LS
  Helper function to propAllConst."
  input TupleConst inTupleConst;
  output Const outConst;
algorithm
  outConst := matchcontinue (inTupleConst)
    local
      Const c,res;
      TupleConst first,const;
      list<TupleConst> rest;
      Ident str;
    case DAE.SINGLE_CONST(const = c) then c;
    case DAE.TUPLE_CONST(tupleConstLst = (first :: rest))
      equation
        DAE.C_PARAM() = propTupleAllConst(first);
      then
        DAE.C_PARAM();
    case DAE.TUPLE_CONST(tupleConstLst = (first :: rest))
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
        Debug.fprint(Flags.FAILTRACE, "- prop_tuple_all_const failed: ");
        str = printTupleConstStr(const);
        Debug.fprintln(Flags.FAILTRACE, str);
      then
        fail();
  end matchcontinue;
end propTupleAllConst;

public function isPropTupleArray "function: isPropTupleArray
This function will check all elements in the tuple if anyone is an array, return true.
As for now it will not check tuple of tuples ie. no recursion."
  input Properties p;
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
  input Properties p;
  output Boolean b;
algorithm
  b := matchcontinue (p)
    case _
      equation
        DAE.T_TUPLE(source = _) = getPropType(p);
      then
        true;
    case(_) then false;
  end matchcontinue;
end isPropTuple;

public function isPropArray "function: isPropArray
 Return true if properties contain an array type."
  input Properties p;
  output Boolean b;
protected
  Type t;
algorithm
  t := getPropType(p);
  b := isArray(t, {});
end isPropArray;

public function propTupleFirstProp
  "Returns the first property from a tuple's properties or fails."
  input Properties inTupleProp;
  output Properties outFirstProp;
protected
  Type ty;
  DAE.Const c;
algorithm
  DAE.PROP_TUPLE(type_ = DAE.T_TUPLE(tupleType = ty :: _),
    tupleConst = DAE.TUPLE_CONST(tupleConstLst = DAE.SINGLE_CONST(const = c) :: _)) := inTupleProp;
  outFirstProp := DAE.PROP(ty, c);
end propTupleFirstProp;

public function propTuplePropList
  "Splits a PROP_TUPLE into a list of PROPs."
  input Properties prop_tuple;
  output list<Properties> prop_list;
algorithm
  prop_list := match(prop_tuple)
    local
      list<Properties> pl;
      list<Type> tl;
      list<TupleConst> cl;
    case (DAE.PROP_TUPLE(type_ = DAE.T_TUPLE(tupleType = tl),
                         tupleConst = DAE.TUPLE_CONST(tupleConstLst = cl)))
      equation
        pl = propTuplePropList2(tl, cl);
      then
        pl;
  end match;
end propTuplePropList;

protected function propTuplePropList2
  "Helper function to propTuplePropList"
  input list<Type> tl;
  input list<TupleConst> cl;
  output list<Properties> pl;
algorithm
  pl := match(tl, cl)
    local
     Type t;
      list<Type> t_rest;
      Const c;
      list<TupleConst> c_rest;
      list<Properties> p_rest;
    case ({}, {}) then {};
    case (t :: t_rest, DAE.SINGLE_CONST(c) :: c_rest)
      equation
        p_rest = propTuplePropList2(t_rest, c_rest);
      then
        (DAE.PROP(t, c) :: p_rest);
  end match;
end propTuplePropList2;

public function getPropConst "function: getPropConst
  author: adrpo
  Return the const from Properties (no tuples!)."
  input Properties inProperties;
  output Const outConst;
algorithm
   DAE.PROP(constFlag = outConst) := inProperties;
end getPropConst;

public function getPropType "function: getPropType
  author: LS
  Return the Type from Properties."
  input Properties inProperties;
  output Type outType;
algorithm
  outType := match (inProperties)
    local Type ty;
    case DAE.PROP(type_ = ty) then ty;
    case DAE.PROP_TUPLE(type_ = ty) then ty;
  end match;
end getPropType;

public function setPropType "Set the Type from Properties."
  input Properties inProperties;
  input Type ty;
  output Properties outProperties;
algorithm
  outProperties := match (inProperties,ty)
    local
      DAE.Const constFlag;
      DAE.TupleConst tupleConst;
    case (DAE.PROP(constFlag = constFlag),_) then DAE.PROP(ty,constFlag);
    case (DAE.PROP_TUPLE(tupleConst = tupleConst),_) then DAE.PROP_TUPLE(ty,tupleConst);
  end match;
end setPropType;

public
 type TypeMemoryEntry = tuple<DAE.Type, DAE.Type>;
 type TypeMemoryEntryList = list<TypeMemoryEntry>;
 type TypeMemoryEntryListArray = array<TypeMemoryEntryList>;

public function createEmptyTypeMemory
"@author: adrpo
  creates an array, with one element for each record in TType!
  Note: This has to be at least 4 larger than the number of records in DAE.Type,
  due to the way bootstrapping indexes records."
  output TypeMemoryEntryListArray tyMemory;
algorithm
  tyMemory := arrayCreate(30, {});
end createEmptyTypeMemory;

public function simplifyType
"@author: adrpo
  simplifies the given type, to be used in an expression or component reference"
  input Type inType;
  output DAE.Type outExpType;
algorithm
  outExpType := matchcontinue (inType)
    local
      String str;
      Type t;
      DAE.Type t_1;
      DAE.Dimensions dims;
      list<DAE.Type> tys;
      list<Var> varLst;
      ClassInf.State CIS;
      DAE.EqualityConstraint ec;
      DAE.TypeSource ts;

    case (DAE.T_FUNCTION(source = _)) then DAE.T_FUNCTION_REFERENCE_VAR(inType,DAE.emptyTypeSource);

    case (DAE.T_METAUNIONTYPE(source = _)) then DAE.T_METATYPE(inType, DAE.emptyTypeSource);
    case (DAE.T_METARECORD(source = _)) then DAE.T_METATYPE(inType, DAE.emptyTypeSource);
    case (DAE.T_METAPOLYMORPHIC(source = _)) then DAE.T_METATYPE(inType, DAE.emptyTypeSource);
    case (DAE.T_METALIST(source = _)) then DAE.T_METATYPE(inType, DAE.emptyTypeSource);
    case (DAE.T_METAARRAY(source = _)) then DAE.T_METATYPE(inType, DAE.emptyTypeSource);
    case (DAE.T_METAOPTION(source = _)) then DAE.T_METATYPE(inType, DAE.emptyTypeSource);
    case (DAE.T_METATUPLE(source = _)) then DAE.T_METATYPE(inType, DAE.emptyTypeSource);

    case (DAE.T_UNKNOWN(source = _)) then DAE.T_UNKNOWN_DEFAULT;
    case (DAE.T_ANYTYPE(source = _)) then DAE.T_UNKNOWN_DEFAULT;

    case (t as DAE.T_ARRAY(source = _))
      equation
        (_,dims) = flattenArrayTypeOpt(t);
        t = arrayElementType(t);
        t_1 = simplifyType(t);
      then
        DAE.T_ARRAY(t_1,dims,DAE.emptyTypeSource);

    case (DAE.T_SUBTYPE_BASIC(complexType = t)) then simplifyType(t);

    case (DAE.T_INTEGER(source = _)) then DAE.T_INTEGER_DEFAULT;
    case (DAE.T_REAL(source = _)) then DAE.T_REAL_DEFAULT;
    case (DAE.T_BOOL(source = _)) then DAE.T_BOOL_DEFAULT;
    case (DAE.T_STRING(source = _)) then DAE.T_STRING_DEFAULT;
    case (DAE.T_NORETCALL(source = _)) then DAE.T_NORETCALL_DEFAULT;
    case (DAE.T_TUPLE(tupleType = tys))
      equation
        tys = List.map(tys, simplifyType);
      then DAE.T_TUPLE(tys, DAE.emptyTypeSource);

    case (DAE.T_ENUMERATION(source = _)) then inType;

    // for metamodelica we need this for some reson!
    case (DAE.T_COMPLEX(CIS, varLst, ec, ts))
      equation
        true = Config.acceptMetaModelicaGrammar();
        varLst = simplifyVars(varLst);
      then
        DAE.T_COMPLEX(CIS, varLst, ec, ts);

    // do this for records too, otherwise:
    // frame.R = Modelica.Mechanics.MultiBody.Frames.Orientation({const_matrix);
    // does not get expanded into the component equations.
    case (DAE.T_COMPLEX(CIS as ClassInf.RECORD(_), varLst, ec, ts))
      equation
        varLst = simplifyVars(varLst);
      then
        DAE.T_COMPLEX(CIS, varLst, ec, ts);

    // otherwise just return the same!
    case (DAE.T_COMPLEX(CIS, varLst, ec, ts)) then inType;

    case (DAE.T_METABOXED(ty = t))
      equation
        t_1 = simplifyType(t);
      then
        DAE.T_METABOXED(t_1, DAE.emptyTypeSource);

    // This is the case when the type is currently UNTYPED
    case (_)
      equation
        /*
        print(" untyped ");
        print(unparseType(inType));
        print("\n");
        */
      then DAE.T_UNKNOWN_DEFAULT;

    else
      equation
        str = "Types.simplifyType failed for: " +& unparseType(inType);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end simplifyType;

protected function simplifyVars
  input list<DAE.Var> inVars;
  output list<DAE.Var> outVars;
algorithm
  outVars := match(inVars)
    local
      String name;
      DAE.Attributes attributes;
      Type ty "type";
      DAE.Binding binding "binding ; equation modification";
      Option<Const> constOfForIteratorRange "the constant-ness of the range if this is a for iterator, NONE() if is NOT a for iterator";
      list<DAE.Var> rest;

    case ({}) then {};

    case (DAE.TYPES_VAR(name, attributes, ty, binding, constOfForIteratorRange)::rest)
      equation
        rest = simplifyVars(rest);
        ty = simplifyType(ty);
      then
        DAE.TYPES_VAR(name, attributes, ty, binding, constOfForIteratorRange)::rest;
  end match;
end simplifyVars;

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
  isEqual := matchcontinue(inType1, inType2)
    local
      DAE.Type ty1, ty2;

    case (ty1, ty2)
      then ttypesElabEquivalent(ty1, ty2);

    else false;
  end matchcontinue;
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

    case (DAE.T_TUPLE(tupleType = types1),
          DAE.T_TUPLE(tupleType = types2))
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
"function: matchProp
  This is basically a wrapper aroune matchType.
  It matches an expression with properties with another set of properties.
  If necessary, the expression is modified to match.
  The only relevant property is the type."
  input DAE.Exp inExp;
  input Properties inActualType;
  input Properties inExpectedType;
  input Boolean printFailtrace;
  output DAE.Exp outExp;
  output Properties outProperties;
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
    case (e,DAE.PROP_TUPLE(type_ = gt as DAE.T_TUPLE(source = _),tupleConst = tc1), DAE.PROP(type_ = et as DAE.T_METATUPLE(source = _),constFlag = c2),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (e_1,t_1) = matchType(e, gt, et, printFailtrace);
        c_1 = propTupleAllConst(tc1);
        c = constAnd(c_1, c2);
      then
        (e_1,DAE.PROP(t_1,c));
    case (e,DAE.PROP_TUPLE(type_ = gt as DAE.T_TUPLE(source = _),tupleConst = tc1), DAE.PROP(type_ = et as DAE.T_METABOXED(source = _),constFlag = c2),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (e_1,t_1) = matchType(e, gt, et, printFailtrace);
        c_1 = propTupleAllConst(tc1);
        c = constAnd(c_1, c2);
      then
        (e_1,DAE.PROP(t_1,c));

    case (e,DAE.PROP(type_ = gt,constFlag = c1),DAE.PROP_TUPLE(type_ = _),_)
      equation
        prop = propTupleFirstProp(inExpectedType);
        (e_1, prop) = matchProp(e, inActualType, prop, printFailtrace);
        gt = simplifyType(gt);
        e_1 = DAE.TSUB(e_1, 1, gt);
      then
        (e_1, prop);

    case (e,DAE.PROP_TUPLE(type_ = _),DAE.PROP(type_ = _),_)
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
        Debug.traceln("- Types.matchProp failed on exp: " +& ExpressionDump.printExpStr(e));
        Debug.traceln(printPropStr(inActualType) +& " != ");
        Debug.traceln(printPropStr(inExpectedType));
      then fail();
  end matchcontinue;
end matchProp;

public function matchTypeList
  input list<DAE.Exp> exps;
  input Type expType;
  input Type expectedType;
  input Boolean printFailtrace;
  output list<DAE.Exp> outExp;
  output list<Type> outTypeLst;
algorithm
  (outExp,outTypeLst):=
  matchcontinue (exps,expType,expectedType,printFailtrace)
    local
      DAE.Exp e,e_1;
      list<DAE.Exp> e_2, rest;
      Type tp,t1,t2;
      list<Type> res;
    case ({},_,_,_) then ({},{});
    case (e::rest,t1,t2,_)
      equation
        (e_1,tp) = matchType(e,t1,t2,printFailtrace);
        (e_2,res) = matchTypeList(rest,t1,t2,printFailtrace);
      then
        (e_1::e_2,(tp :: res));
    case (_,_,_,true)
      equation
        Debug.fprint(Flags.TYPES, "- matchTypeList failed\n");
      then
        fail();
  end matchcontinue;
end matchTypeList;

public function matchTypeTuple
"Transforms a list of expressions and types into a list of expressions
of the expected types."
  input list<DAE.Exp> inExp1;
  input list<Type> inTypeLst2;
  input list<Type> inTypeLst3;
  input Boolean printFailtrace;
  output list<DAE.Exp> outExp;
  output list<Type> outTypeLst;
algorithm
  (outExp,outTypeLst):=
  matchcontinue (inExp1,inTypeLst2,inTypeLst3,printFailtrace)
    local
      DAE.Exp e,e_1;
      list<DAE.Exp> rest, e_2;
      Type tp,t1,t2;
      list<Type> res,ts1,ts2;
    case ({},{},{},_) then ({},{});
    case (e::rest,(t1 :: ts1),(t2 :: ts2),_)
      equation
        (e_1,tp) = matchType(e,t1,t2,printFailtrace);
        (e_2,res) = matchTypeTuple(rest,ts1,ts2,printFailtrace);
      then
        (e_1::e_2,(tp :: res));
    case (_,(t1 :: ts1),(t2 :: ts2),true)
      equation
        Debug.fprint(Flags.FAILTRACE, "- Types.matchTypeTuple failed\n");
      then
        fail();
  end matchcontinue;
end matchTypeTuple;

public function matchTypeTupleCall
  input DAE.Exp inExp1;
  input list<Type> inTypeLst2;
  input list<Type> inTypeLst3;
algorithm
  _ :=
  matchcontinue (inExp1,inTypeLst2,inTypeLst3)
    local
      DAE.Exp e;
      Type t1,t2;
      list<Type> ts1,ts2;
    case (_,_,{}) then ();
    case (e,(t1 :: ts1),(t2 :: ts2))
      equation
        // We cannot use matchType here because it does not cast tuple calls properly
        true = subtype(t1, t2);
        /* (oe,_) = matchType(e, t1, t2, true);
        true = Expression.expEqual(e,oe); */
        matchTypeTupleCall(e, ts1, ts2);
      then ();
    case (_,(t1 :: ts1),(t2 :: ts2))
      equation
        Debug.fprint(Flags.FAILTRACE, "- matchTypeTupleCall failed\n");
      then
        fail();
  end matchcontinue;
end matchTypeTupleCall;

public function vectorizableType "function: vectorizableType
  author: PA
  This function checks if a given type can be (converted and) vectorized to
  a expected type.
  For instance and argument of type Integer{:} can be vectorized to an
  argument type Real, using type coersion and vectorization of one dimension."
  input DAE.Exp inExp;
  input Type inExpType;
  input Type inExpectedType;
  input Option<Absyn.Path> fnPath;
  output DAE.Exp outExp;
  output Type outType;
  output DAE.Dimensions outArrayDimLst;
  output PolymorphicBindings outBindings;
algorithm
  (outExp,outType,outArrayDimLst,outBindings) := vectorizableType2(inExp,inExpType,inExpType,{},inExpectedType,fnPath);
end vectorizableType;

protected function vectorizableType2
  input DAE.Exp inExp;
  input Type inExpType;
  input Type inCurrentType;
  input DAE.Dimensions inArrayDimLst;
  input Type inExpectedType;
  input Option<Absyn.Path> fnPath;
  output DAE.Exp outExp;
  output Type outType;
  output DAE.Dimensions outArrayDimLst;
  output PolymorphicBindings outBindings;
algorithm
  (outExp,outType,outArrayDimLst,outBindings) := matchcontinue (inExp,inExpType,inCurrentType,inArrayDimLst,inExpectedType,fnPath)
    local
      DAE.Exp e_1,e;
      Type e_type_1,e_type,expected_type,expected_type_vectorized,current_type;
      PolymorphicBindings polymorphicBindings;
      DAE.Dimension dim;
      DAE.Dimensions dims;
    case (e,e_type,current_type,dims,expected_type,_)
      equation
        expected_type_vectorized = liftArrayListDims(expected_type, dims);
        (e_1,e_type_1,polymorphicBindings) = matchTypePolymorphic(e, e_type, expected_type_vectorized, fnPath, {}, true);
      then
        (e_1,e_type_1,dims,polymorphicBindings);
    case (e,e_type,DAE.T_ARRAY(ty = current_type, dims = {dim}),dims,expected_type,_)
      equation
        dims = listAppend(dims, {dim});
        (e_1,e_type_1,dims,polymorphicBindings) = vectorizableType2(e, e_type, current_type, dims, expected_type, fnPath);
      then
        (e_1,e_type_1,dims,polymorphicBindings);
  end matchcontinue;
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
    case (DAE.T_ARRAY(t, {}, ts), true)
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
"function: typeConvert
  This functions converts the expression in the first argument to
  the type specified in the third argument.  The current type of the
  expression is given in the second argument.
  If no type conversion is possible, this function fails."
  input DAE.Exp inExp1;
  input Type actual;
  input Type expected;
  input Boolean printFailtrace;
  output DAE.Exp outExp;
  output Type outType;
algorithm
  (outExp,outType):=
  matchcontinue (inExp1,actual,expected,printFailtrace)
    local
      list<DAE.Exp> elist_1,elist,inputs;
      DAE.Type at,t;
      Boolean sc, a;
      Integer nmax;
      DAE.Dimension dim1, dim2, dim11, dim22;
      DAE.Dimensions dims;
      Type ty1,ty2,t1,t2,t_1,t_2,ty0,ty;
      DAE.Exp begin_1,step_1,stop_1,begin,step,stop,e_1,e,exp;
      list<list<DAE.Exp>> ell_1,ell,elist_big;
      list<Type> tys_1,tys1,tys2;
      list<Ident> l;
      list<Var> v;
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
      list<Var> els1,els2;
      Absyn.Path p1,p2;

    // if we expect notTuple and we get Tuple do DAE.TSUB(e, 1)
    // we try subtype of the first tuple element with the other type!
    case (e, DAE.T_TUPLE(tupleType = ty1::_), ty2, _)
      equation
        false = Config.acceptMetaModelicaGrammar();
        false = isTuple(ty2);
        true = subtype(ty1, ty2);
        e = DAE.TSUB(e, 1, ty2);
        ty = ty2;
      then
        (e, ty);

    // try dims as list T_ARRAY(a::b::c)
    case (e,
          ty1 as DAE.T_ARRAY(dims = _::_::_),
          ty2,
          _)
      equation
         ty1 = unflattenArrayType(ty1);
         ty2 = unflattenArrayType(ty2);
         (e, ty) = typeConvert(e, ty1, ty2, printFailtrace);
      then
        (e, ty);

    // try dims as list T_ARRAY(a::b::c)
    case (e,
          ty1,
          ty2 as DAE.T_ARRAY(dims = _::_::_),
          _)
      equation
         ty1 = unflattenArrayType(ty1);
         ty2 = unflattenArrayType(ty2);
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
        a = isArray(ty2, {});
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
          ty0 as DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()}, ty = ty2, source = ts),
          _)
      equation
        true = Expression.dimensionKnown(dim1);
        elist_1 = typeConvertArray(elist,ty1,ty2,printFailtrace);
        dims = Expression.arrayDimension(simplifyType(ty1));
        a = isArray(ty2,{});
        sc = boolNot(a);
        dims = dim1 :: dims;
        ty2 = arrayElementType(ty2);
        ety1 = simplifyType(ty2);
        ty2 = liftArrayListDims(ty2, dims);
        exp = DAE.ARRAY(DAE.T_ARRAY(ety1, dims, DAE.emptyTypeSource), sc, elist_1);
        //TODO: Verify correctness of return value.
      then
        (DAE.ARRAY(DAE.T_ARRAY(ety1, dims, DAE.emptyTypeSource),sc,elist_1), ty2);

    // Full range expressions, e.g. 1:2:10
    case (DAE.RANGE(ty = t,start = begin,step = SOME(step),stop = stop),
          DAE.T_ARRAY(dims = {dim1},ty = ty1),
          ty0 as DAE.T_ARRAY(dims = {dim2}, ty = ty2, source = ts),
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
    case (DAE.RANGE(ty = t,start = begin,step = NONE(),stop = stop),
          DAE.T_ARRAY(dims = {dim1}, ty = ty1),
          ty0 as DAE.T_ARRAY(dims = {dim2}, ty = ty2, source = ts),
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
          ty0 as DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()},ty = DAE.T_ARRAY(dims = {dim22},ty = t2, source = ts1), source = ts2),
          _)
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
          ty0 as DAE.T_ARRAY(dims = {dim2},ty = ty2,source = ts2),
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
          DAE.T_ARRAY(dims = {dim2},ty = ty2,source = ts2),
          _)
      equation
        (e_1,t_1) = typeConvert(e, ty1, ty2, printFailtrace);
        e_1 = liftExpType(e_1,DAE.DIM_UNKNOWN());
      then
        (e_1,DAE.T_ARRAY(t_1,{DAE.DIM_UNKNOWN()},ts2));

    // Arbitrary expressions, expression dimension [:] expected dimension [:]
    case (e,
          DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()},ty = ty1),
          DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()},ty = ty2,source = ts2),
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

    // Tuple
    case (DAE.TUPLE(PR = elist),
          DAE.T_TUPLE(tupleType = tys1),
          DAE.T_TUPLE(tupleType = tys2, source = ts2),
          _)
      equation
        (elist_1,tys_1) = typeConvertList(elist, tys1, tys2, printFailtrace);
      then
        (DAE.TUPLE(elist_1),DAE.T_TUPLE(tys_1,ts2));

    // Convert an integer literal to an enumeration
    // This is widely used in Modelica.Electrical.Digital
    /* Commented out for when someone complains...
    case (exp as DAE.ICONST(oi),
          DAE.T_INTEGER(varLst = _),
          DAE.T_ENUMERATION(index=_, path=tp, names = l, source = ts2),
          printFailtrace)
      equation
        // TODO! FIXME! check boundaries if the integer literal is not outside the enum range
        // select from enum list:
        name = listNth(l, oi-1); // listNth indexes from 0
        tp = Absyn.joinPaths(tp, Absyn.IDENT(name));
      then
        (DAE.ENUM_LITERAL(tp, oi),expected);
    */

    // Implicit conversion from Integer to Real
    case (e,
          DAE.T_INTEGER(varLst = v),
          DAE.T_REAL(varLst = _),
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
        true = subtypeVarlist(els1, els2);
        e = DAE.CAST(t2, e);
      then (e, t2);

    // MetaModelica Option
    case (DAE.META_OPTION(SOME(e)),DAE.T_METAOPTION(optionType = t1),DAE.T_METAOPTION(t2,ts2),_)
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
    case (DAE.TUPLE(elist),DAE.T_TUPLE(tupleType = tys1),DAE.T_METATUPLE(tys2,ts2),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        tys2 = List.map(tys2, boxIfUnboxedType);
        (elist_1,tys_1) = matchTypeTuple(elist, tys1, tys2, printFailtrace);
      then
        (DAE.META_TUPLE(elist_1),DAE.T_METATUPLE(tys_1,ts2));

    case (DAE.MATCHEXPRESSION(matchTy,inputs,localDecls,cases,et),_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        elist = Patternm.resultExps(cases);
        (elist_1,tys_1) = matchTypeList(elist, actual, expected, printFailtrace);
        cases=Patternm.fixCaseReturnTypes2(cases,elist_1,Absyn.dummyInfo);
        et=simplifyType(expected);
      then
        (DAE.MATCHEXPRESSION(matchTy,inputs,localDecls,cases,et),expected);

    case (DAE.META_TUPLE(elist),DAE.T_METATUPLE(types = tys1),DAE.T_METATUPLE(tys2,ts2),_)
      equation
        tys2 = List.map(tys2, boxIfUnboxedType);
        (elist_1,tys_1) = matchTypeTuple(elist, tys1, tys2, printFailtrace);
      then
        (DAE.META_TUPLE(elist_1),DAE.T_METATUPLE(tys_1,ts2));

    case (DAE.TUPLE(elist),DAE.T_TUPLE(tupleType = tys1),ty2 as DAE.T_METABOXED(ty = DAE.T_UNKNOWN(source =_), source = ts2),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        e_1 = DAE.META_TUPLE(elist);
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
    case (e as DAE.ARRAY(DAE.T_ARRAY(ty = t),_,elist),
          DAE.T_ARRAY(ty=t1),
          DAE.T_METALIST(t2,ts2),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        t2 = boxIfUnboxedType(t2);
        (elist_1, _) = matchTypeList(elist, t1, t2, printFailtrace);
        e_1 = DAE.LIST(elist_1);
        t2 = DAE.T_METALIST(t2,DAE.emptyTypeSource);
      then (e_1, t2);

    case (e as DAE.ARRAY(DAE.T_ARRAY(ty = t),_,elist),
          DAE.T_ARRAY(ty=t1),
          DAE.T_METABOXED(t2,ts2),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (elist_1, tys1) = matchTypeList(elist, t1, t2, printFailtrace);
        (elist_1, t2) = listMatchSuperType(elist_1, tys1, printFailtrace);
        t2 = boxIfUnboxedType(t2);
        (elist_1, _) = matchTypeList(elist_1, t1, t2, printFailtrace);
        e_1 = DAE.LIST(elist_1);
        t2 = DAE.T_METALIST(t2,DAE.emptyTypeSource);
      then (e_1, t2);

    case (e as DAE.MATRIX(DAE.T_ARRAY(ty = t),_,elist_big),t1,t2,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (elist,ty2) = typeConvertMatrixToList(elist_big,t1,t2,printFailtrace);
        e_1 = DAE.LIST(elist);
      then (e_1,ty2);

    case (e as DAE.LIST(elist),DAE.T_METALIST(listType = t1),DAE.T_METALIST(t2,ts2),_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (elist_1, tys1) = matchTypeList(elist, t1, t2, printFailtrace);
        (elist_1, t2) = listMatchSuperType(elist_1, tys1, printFailtrace);
        e_1 = DAE.LIST(elist_1);
        t2 = DAE.T_METALIST(t2,DAE.emptyTypeSource);
      then (e_1, t2);

    case (e, t1 as DAE.T_INTEGER(varLst = _), DAE.T_METABOXED(ty = t2),_)
      equation
        (e,t1) = matchType(e,t1,unboxedType(t2),printFailtrace);
        t2 = DAE.T_METABOXED(t1,DAE.emptyTypeSource);
        t = simplifyType(t2);
        e = Expression.boxExp(e);
      then (e,t2);

    case (e, t1 as DAE.T_BOOL(varLst = _), DAE.T_METABOXED(ty = t2),_)
      equation
        (e,t1) = matchType(e,t1,unboxedType(t2),printFailtrace);
        t2 = DAE.T_METABOXED(t1,DAE.emptyTypeSource);
        t = simplifyType(t2);
        e = Expression.boxExp(e);
      then (e,t2);

    case (e, t1 as DAE.T_REAL(varLst = _), DAE.T_METABOXED(ty = t2),_)
      equation
        (e,t1) = matchType(e,t1,unboxedType(t2),printFailtrace);
        t2 = DAE.T_METABOXED(t1,DAE.emptyTypeSource);
        t = simplifyType(t2);
        e = Expression.boxExp(e);
      then (e,t2);

    case (e, t1 as DAE.T_ARRAY(ty = _), DAE.T_METABOXED(ty = t2), _)
      equation
        // true = Config.acceptMetaModelicaGrammar();
        (e, t1) = matchType(e, t1, unboxedType(t2), printFailtrace);
        t2 = DAE.T_METABOXED(t1,DAE.emptyTypeSource);
        t = simplifyType(t2);
        e = Expression.boxExp(e);
      then
        (e, t2);

    case (e as DAE.CALL(path = path1, expLst = elist),
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
        e_1 = DAE.METARECORDCALL(path1, elist, l, -1);
      then (e_1,t2);

    case (e as DAE.CALL(path = _),
          t1 as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), varLst = v),
          DAE.T_METABOXED(ty = t2),_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- Not yet implemented: Converting record calls (not constructor) into boxed records");
      then
        fail();

    case (e as DAE.CREF(cref,_),
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
        e_1 = DAE.METARECORDCALL(path, elist, l, -1);
      then (e_1,t2);

    case (DAE.BOX(e),DAE.T_METABOXED(ty = t1),t2,_)
      equation
        true = subtype(t1,t2);
        (e_1,t2) = matchType(e,t1,t2,printFailtrace);
      then (e_1,t2);

    case (e,DAE.T_METABOXED(ty = t1),t2 as DAE.T_INTEGER(varLst = _),_)
      equation
        true = subtype(t1,t2);
        (e_1,_) = matchType(e,t1,t2,printFailtrace);
        t = simplifyType(t2);
      then (DAE.UNBOX(e,t),t2);

    case (e,DAE.T_METABOXED(ty = t1),t2 as DAE.T_REAL(varLst = _),_)
      equation
        true = subtype(t1,t2);
        (e_1,_) = matchType(e,t1,t2,printFailtrace);
        t = simplifyType(t2);
      then (DAE.UNBOX(e,t),t2);

    case (e,DAE.T_METABOXED(ty = t1),t2 as DAE.T_BOOL(varLst = _),_)
      equation
        true = subtype(t1,t2);
        (e_1,_) = matchType(e,t1,t2,printFailtrace);
        t = simplifyType(t2);
      then (DAE.UNBOX(e,t),t2);

    case (e,DAE.T_METABOXED(ty = t1),t2 as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), varLst = v),_)
      equation
        true = subtype(t1,t2);
        (e_1,_) = matchType(e,t1,t2,printFailtrace);
        t = simplifyType(t2);
      then
        (DAE.CALL(Absyn.IDENT("mmc_unbox_record"),{e_1},DAE.CALL_ATTR(t,false,true,false,DAE.NO_INLINE(),DAE.NO_TAIL())),t2);

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
  input Type inActualType;
  input Type inExpectedType;
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

protected function typeConvertMatrix "function: typeConvertMatrix

  Helper function to type_convert. Handles matrix expressions.
"
  input list<list<DAE.Exp>> inTplExpExpBooleanLstLst1;
  input Type inType2;
  input Type inType3;
  input Boolean printFailtrace;
  output list<list<DAE.Exp>> outTplExpExpBooleanLstLst;
algorithm
  outTplExpExpBooleanLstLst :=
  match (inTplExpExpBooleanLstLst1,inType2,inType3,printFailtrace)
    local
      list<list<DAE.Exp>> rest_1,rest;
      list<DAE.Exp> first_1,first;
      Type ty1,ty2;
    case ({},_,_,_) then {};
    case ((first :: rest),ty1,ty2,_)
      equation
        rest_1 = typeConvertMatrix(rest,ty1,ty2,printFailtrace);
        first_1 = typeConvertArray(first,ty1,ty2,printFailtrace);
      then (first_1 :: rest_1);
  end match;
end typeConvertMatrix;

protected function typeConvertList "function: typeConvertList

  Helper function to type_convert.
"
  input list<DAE.Exp> inExpExpLst1;
  input list<Type> inTypeLst2;
  input list<Type> inTypeLst3;
  input Boolean printFailtrace;
  output list<DAE.Exp> outExpExpLst;
  output list<Type> outTypeLst;
algorithm
  (outExpExpLst,outTypeLst):=
  match (inExpExpLst1,inTypeLst2,inTypeLst3,printFailtrace)
    local
      list<DAE.Exp> rest_1,rest;
      list<Type> tyrest_1,ty1rest,ty2rest;
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
  input Type inType;
  input Type outType;
  input Boolean printFailtrace;
  output list<DAE.Exp> outExp;
  output Type actualOutType;
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
    case (expl::rest, DAE.T_ARRAY(ty=DAE.T_ARRAY(ty=t1)), DAE.T_METALIST(DAE.T_METALIST(listType=t2),ts2),_)
      equation
        (e,t1) = typeConvertMatrixRowToList(expl, t1, t2, printFailtrace);
        t = simplifyType(t1);
        (expl,_) = typeConvertMatrixToList(rest, inType, outType, printFailtrace);
      then (e::expl,DAE.T_METALIST(t1,DAE.emptyTypeSource));
    case (_,_,_,_)
      equation
        Debug.fprintln(Flags.TYPES, "- typeConvertMatrixToList failed");
      then fail();
  end matchcontinue;
end typeConvertMatrixToList;

protected function typeConvertMatrixRowToList
  input list<DAE.Exp> elist;
  input Type inType;
  input Type outType;
  input Boolean printFailtrace;
  output DAE.Exp out;
  output Type t1;
protected
  DAE.Exp exp;
  list<DAE.Exp> elist_1;
  DAE.Type t;
algorithm
  (elist_1,t1::_) := matchTypeList(elist, inType, outType, printFailtrace);
  out := DAE.LIST(elist_1);
  t1 := DAE.T_METALIST(t1,DAE.emptyTypeSource);
end typeConvertMatrixRowToList;

public function matchWithPromote "function: matchWithPromote
  This function is used for matching expressions in matrix construction,
  where automatic promotion is allowed. This means that array dimensions of
  size one (1) is added from the right to arrays of matrix construction until
  all elements have the same dimension size (with a maximum of 2).
  For instance, {1,{2}} becomes {1,2}.
  The function also has a flag indicating that Integer to Real
  conversion can be used."
  input Properties inProperties1;
  input Properties inProperties2;
  input Boolean inBoolean3;
  output Properties outProperties;
algorithm
  outProperties := matchcontinue (inProperties1,inProperties2,inBoolean3)
    local
      Type t,t1,t2;
      Const c,c1,c2;
      DAE.Dimension dim,dim1,dim2;
      Boolean havereal;
      list<Var> v;
      Type tt;
      DAE.TypeSource  ts2, ts;

    case (DAE.PROP(DAE.T_SUBTYPE_BASIC(complexType = t1),c1),DAE.PROP(t2,c2),havereal)
      then matchWithPromote(DAE.PROP(t1,c1),DAE.PROP(t2,c2),havereal);

    case (DAE.PROP(t1,c1),DAE.PROP(DAE.T_SUBTYPE_BASIC(complexType = t2),c2),havereal)
      then matchWithPromote(DAE.PROP(t1,c1),DAE.PROP(t2,c2),havereal);

    case (DAE.PROP(type_ = DAE.T_ARRAY(dims = {dim1},ty = t1),constFlag = c1),
          DAE.PROP(type_ = DAE.T_ARRAY(dims = {dim2},ty = t2, source = ts2),constFlag = c2),
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
        false = isArray(t1,{});
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP(DAE.T_ARRAY(t, {DAE.DIM_INTEGER(1)},ts2),c);
    // match enum, second
    case (DAE.PROP(type_ = t1,constFlag = c1),
          DAE.PROP(type_ = DAE.T_ARRAY(dims = {dim as DAE.DIM_ENUM(size=1)},ty = t2, source = ts2),constFlag = c2),
          havereal)
      equation
        false = isArray(t1,{});
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP(DAE.T_ARRAY(t,{dim},ts2),c);
    // match boolean, second
    case (DAE.PROP(type_ = t1,constFlag = c1),
          DAE.PROP(type_ = DAE.T_ARRAY(dims = {dim as DAE.DIM_BOOLEAN()},ty = t2, source = ts2),constFlag = c2),
          havereal)
      equation
        false = isArray(t1,{});
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP(DAE.T_ARRAY(t,{dim},ts2),c);
    // match integer, first
    case (DAE.PROP(type_ = DAE.T_ARRAY(dims = {DAE.DIM_INTEGER(1)},ty = t1, source = ts),constFlag = c1),
          DAE.PROP(type_ = t2,constFlag = c2),havereal)
      equation
        false = isArray(t2,{});
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP(DAE.T_ARRAY(t,{DAE.DIM_INTEGER(1)},ts),c);
    // match enum, first
    case (DAE.PROP(type_ = DAE.T_ARRAY(dims = {dim as DAE.DIM_ENUM(size=1)},ty = t1, source = ts),constFlag = c1),
          DAE.PROP(type_ = t2,constFlag = c2),havereal)
      equation
        false = isArray(t2,{});
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP(DAE.T_ARRAY(t,{dim},ts),c);
    // match boolean, first
    case (DAE.PROP(type_ = DAE.T_ARRAY(dims = {dim as DAE.DIM_BOOLEAN()},ty = t1, source = ts),constFlag = c1),
          DAE.PROP(type_ = t2,constFlag = c2),havereal)
      equation
        false = isArray(t2,{});
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP(DAE.T_ARRAY(t,{dim},ts),c);
    // equal types
    case (DAE.PROP(type_ = t1,constFlag = c1),
          DAE.PROP(type_ = t2,constFlag = c2),false)
      equation
        false = isArray(t1,{});
        false = isArray(t2,{});
        equality(t1 = t2);
        c = constAnd(c1, c2);
      then
        DAE.PROP(t1,c);
    // enums
    case (DAE.PROP(type_ = tt as DAE.T_ENUMERATION(literalVarLst = v),constFlag = c1),
          DAE.PROP(type_ = DAE.T_ENUMERATION(index = _, source = ts2),constFlag = c2), false)
      equation
        c = constAnd(c1, c2) "Have enum and both Enum" ;
        tt = setTypeSource(tt,ts2);
      then
        DAE.PROP(tt,c);
    // reals
    case (DAE.PROP(type_ = DAE.T_REAL(varLst = v),constFlag = c1),
          DAE.PROP(type_ = DAE.T_REAL(varLst = _, source = ts2),constFlag = c2),true)
      equation
        c = constAnd(c1, c2) "Have real and both Real" ;
      then
        DAE.PROP(DAE.T_REAL(v,ts2),c);
    // integer vs. real
    case (DAE.PROP(type_ = DAE.T_INTEGER(varLst = _),constFlag = c1),
          DAE.PROP(type_ = DAE.T_REAL(varLst = v, source = ts2),constFlag = c2),true)
      equation
        c = constAnd(c1, c2) "Have real and first Integer" ;
      then
        DAE.PROP(DAE.T_REAL(v,ts2),c);
    // real vs. integer
    case (DAE.PROP(type_ = DAE.T_REAL(varLst = v),constFlag = c1),
          DAE.PROP(type_ = DAE.T_INTEGER(varLst = _, source = ts2),constFlag = c2),true)
      equation
        c = constAnd(c1, c2) "Have real and second Integer" ;
      then
        DAE.PROP(DAE.T_REAL(v,ts2),c);
    // both integers
    case (DAE.PROP(type_ = DAE.T_INTEGER(varLst = _),constFlag = c1),
          DAE.PROP(type_ = DAE.T_INTEGER(varLst = _, source = ts2),constFlag = c2),true)
      equation
        c = constAnd(c1, c2) "Have real and both Integer" ;
      then
        DAE.PROP(DAE.T_REAL_DEFAULT,c);

    case(_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE,"- Types.matchWithPromote failed on: " +&
           "\nprop1: " +& printPropStr(inProperties1) +&
           "\nprop2: " +& printPropStr(inProperties2) +&
           "\nhaveReal: " +& Util.if_(inBoolean3, "true", "false"));
      then fail();
  end matchcontinue;
end matchWithPromote;

public function constAnd "function: constAnd
  Returns the *and* operator of two Consts.
  I.e. C_CONST iff. both are C_CONST,
       C_PARAM iff both are C_PARAM (or one of them C_CONST),
       V_VAR otherwise."
  input Const inConst1;
  input Const inConst2;
  output Const outConst;
algorithm
  outConst := matchcontinue (inConst1,inConst2)
    case (DAE.C_CONST(),DAE.C_CONST()) then DAE.C_CONST();
    case (DAE.C_CONST(),DAE.C_PARAM()) then DAE.C_PARAM();
    case (DAE.C_PARAM(),DAE.C_CONST()) then DAE.C_PARAM();
    case (DAE.C_PARAM(),DAE.C_PARAM()) then DAE.C_PARAM();
    case (DAE.C_UNKNOWN(), _) then DAE.C_UNKNOWN();
    case (_, DAE.C_UNKNOWN()) then DAE.C_UNKNOWN();
    case (_,_) then DAE.C_VAR();
  end matchcontinue;
end constAnd;

protected function constTupleAnd "function: constTupleAnd
  Returns the *and* operator of two TupleConsts
  For now, returns first tuple."
  input TupleConst inTupleConst1;
  input TupleConst inTupleConst2;
  output TupleConst outTupleConst;
algorithm
  outTupleConst := match (inTupleConst1,inTupleConst2)
    local TupleConst c1,c2;
    case (c1,c2) then c1;
  end match;
end constTupleAnd;

public function constOr "function: constOr
  Returns the *or* operator of two Const's.
  I.e. C_CONST if some is C_CONST,
       C_PARAM if none is C_CONST but some is C_PARAM and
       V_VAR otherwise."
  input Const inConst1;
  input Const inConst2;
  output Const outConst;
algorithm
  outConst := matchcontinue (inConst1,inConst2)
    case (DAE.C_CONST(),_) then DAE.C_CONST();
    case (_,DAE.C_CONST()) then DAE.C_CONST();
    case (DAE.C_PARAM(),_) then DAE.C_PARAM();
    case (_,DAE.C_PARAM()) then DAE.C_PARAM();
    case (DAE.C_UNKNOWN(),_) then DAE.C_UNKNOWN();
    case (_, DAE.C_UNKNOWN()) then DAE.C_UNKNOWN();
    case (_,_) then DAE.C_VAR();
  end matchcontinue;
end constOr;

public function boolConst "function: boolConst
  author: PA
  Creates a Const value from a bool.
  if true, C_CONST,
  if false C_VAR
  There is no way to create a C_PARAM using this function."
  input Boolean inBoolean;
  output Const outConst;
algorithm
  outConst := match (inBoolean)
    case (false) then DAE.C_VAR();
    case (true) then DAE.C_CONST();
  end match;
end boolConst;

public function boolConstSize "function: boolConstSize
  author: alleb
  A version of boolConst supposed to be used by Static.elabBuiltinSize.
  Creates a Const value from a bool. If true, C_CONST, if false C_PARAM."
  input Boolean inBoolean;
  output Const outConst;
algorithm
  outConst := match (inBoolean)
    case (false) then DAE.C_PARAM();
    case (true) then DAE.C_CONST();
  end match;
end boolConstSize;

public function constEqualOrHigher
  input Const c1;
  input Const c2;
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
  input Const c1;
  input Const c2;
  output Boolean b;
algorithm
  b := matchcontinue(c1, c2)
    case (_, _)
      equation
        equality(c1 = c2);
      then
        true;
    case (_, _) then false;
  end matchcontinue;
end constEqual;

public function constIsVariable
  "Returns true if Const is C_VAR."
  input Const c;
  output Boolean b;
algorithm
  b := constEqual(c, DAE.C_VAR());
end constIsVariable;

public function constIsParameter
  "Returns true if Const is C_PARAM."
  input Const c;
  output Boolean b;
algorithm
  b := constEqual(c, DAE.C_PARAM());
end constIsParameter;

public function constIsConst
  "Returns true if Const is C_CONST."
  input Const c;
  output Boolean b;
algorithm
  b := constEqual(c, DAE.C_CONST());
end constIsConst;

public function printPropStr "function: printPropStr
  Print the properties to a string."
  input Properties inProperties;
  output String outString;
algorithm
  outString := match (inProperties)
    local
      Ident ty_str,const_str,res;
      Type ty;
      Const const;
      TupleConst tconst;
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

public function printProp "function: printProp
  Print the Properties to the Print buffer."
  input Properties p;
  Ident str;
algorithm
  str := printPropStr(p);
  Print.printErrorBuf(str);
end printProp;

public function flowVariables "function: flowVariables
  This function retrieves all variables names that are flow variables, and
  prepends the prefix given as an DAE.ComponentRef"
  input list<Var> inVarLst;
  input DAE.ComponentRef inComponentRef;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst:=
  matchcontinue (inVarLst,inComponentRef)
    local
      DAE.ComponentRef cr_1,cr;
      list<DAE.ComponentRef> res;
      Ident id;
      list<Var> vs;
      DAE.Type ty2;
      Type ty;
      DAE.ComponentRef cref_;

    // handle empty case
    case ({},_) then {};

    // we have a flow prefix
    case ((DAE.TYPES_VAR(name = id,attributes = DAE.ATTR(connectorType = SCode.FLOW()),ty = ty) :: vs),cr)
      equation
        ty2 = simplifyType(ty);
        cr_1 = ComponentReference.crefPrependIdent(cr, id,{},ty2);
        // print("\n created: " +& ComponentReference.debugPrintComponentRefTypeStr(cr_1) +& "\n");
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

public function streamVariables "function: streamVariables
  This function retrieves all variables names that are stream variables,
  and prepends the prefix given as an DAE.ComponentRef"
  input list<Var> inVarLst;
  input DAE.ComponentRef inComponentRef;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst:=
  matchcontinue (inVarLst,inComponentRef)
    local
      DAE.ComponentRef cr_1,cr;
      list<DAE.ComponentRef> res;
      Ident id;
      list<Var> vs;
      DAE.Type ty2;
      Type ty;
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

public function getAllExps "function: getAllExps
  This function goes through the Type structure and finds all the
  expressions and returns them in a list"
  input Type inType;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := getAllExpsTt(inType);
end getAllExps;

protected function getAllExpsTt "function: getAllExpsTt
  This function goes through the TType structure and finds all the
  expressions and returns them in a list"
  input Type inType;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := matchcontinue (inType)
    local
      list<DAE.Exp> exps,tyexps;
      list<Var> vars, attrs;
      list<Ident> strs;
      DAE.Dimension dim;
      Type ty;
      ClassInf.State cinf;
      Option<Type> bc;
      list<Type> tys;
      list<list<DAE.Exp>> explists,explist;
      list<FuncArg> fargs;
      Type tty;
      String str;

    case DAE.T_INTEGER(varLst = vars) then getAllExpsVars(vars);
    case DAE.T_REAL(varLst = vars)    then getAllExpsVars(vars);
    case DAE.T_STRING(varLst = vars)  then getAllExpsVars(vars);
    case DAE.T_BOOL(varLst = vars)    then getAllExpsVars(vars);
    case DAE.T_ENUMERATION(names = strs, literalVarLst = vars, attributeLst = attrs)
      equation
        exps = getAllExpsVars(vars);
        tyexps = getAllExpsVars(attrs);
        exps = listAppend(exps, tyexps);
      then
        exps;
    case DAE.T_ARRAY(ty = ty) then getAllExps(ty);

    case DAE.T_COMPLEX(varLst = vars) then getAllExpsVars(vars);
    case DAE.T_SUBTYPE_BASIC(varLst = vars) then getAllExpsVars(vars);

    case DAE.T_FUNCTION(funcArg = fargs,funcResultType = ty)
      equation
        tys = List.map(fargs, Util.tuple42);
        explists = List.map(tys, getAllExps);
        tyexps = getAllExps(ty);
        exps = List.flatten((tyexps :: explists));
      then
        exps;

    case DAE.T_TUPLE(tupleType = tys)
      equation
        explist = List.map(tys, getAllExps);
        exps = List.flatten(explist);
      then
        exps;

    case DAE.T_METATUPLE(types = tys)
      equation
        exps = getAllExpsTt(DAE.T_TUPLE(tys, DAE.emptyTypeSource));
      then
        exps;

    case DAE.T_METAUNIONTYPE(paths=_) then {};

    case DAE.T_METAOPTION(optionType = ty) then getAllExps(ty);
    case DAE.T_METALIST(listType = ty)     then getAllExps(ty);
    case DAE.T_METAARRAY(ty = ty)          then getAllExps(ty);
    case DAE.T_METABOXED(ty = ty)          then getAllExps(ty);
    case DAE.T_METAPOLYMORPHIC(name = _) then {};

    case(DAE.T_UNKNOWN(source = _)) then {};
    case(DAE.T_NORETCALL(source = _)) then {};

    case tty
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str = unparseType(tty);
        Debug.fprintln(Flags.FAILTRACE, "-- Types.getAllExpsTt failed " +& str);
      then
        fail();
  end matchcontinue;
end getAllExpsTt;

protected function getAllExpsVars "function: getAllExpsVars
  Helper function to getAllExpsTt."
  input list<Var> vars;
  output list<DAE.Exp> exps;
protected
  list<list<DAE.Exp>> explist;
algorithm
  explist := List.map(vars, getAllExpsVar);
  exps := List.flatten(explist);
end getAllExpsVars;

protected function getAllExpsVar "function: getAllExpsVar
  Helper function to getAllExpsVars."
  input Var inVar;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := matchcontinue (inVar)
    local
      list<DAE.Exp> tyexps,bndexp,exps;
      Ident id;
      Type ty;
      Binding bnd;

    case DAE.TYPES_VAR(name = id,ty = ty,binding = bnd)
      equation
        tyexps = getAllExps(ty);
        bndexp = getAllExpsBinding(bnd);
        exps = listAppend(tyexps, bndexp);
      then
        exps;
  end matchcontinue;
end getAllExpsVar;

protected function getAllExpsBinding "function: getAllExpsBinding
  Helper function to get_all_exps_var."
  input Binding inBinding;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := matchcontinue (inBinding)
    local
      DAE.Exp exp;
      Const cnst;
      Values.Value v;
    case DAE.EQBOUND(exp = exp,constant_ = cnst) then {exp};
    case DAE.UNBOUND() then {};
    case DAE.VALBOUND(valBound = v) then {};
    case _
      equation
        Debug.fprintln(Flags.FAILTRACE, "-- Types.getAllExpsBinding failed");
      then
        fail();
  end matchcontinue;
end getAllExpsBinding;

public function isBoxedType
  input Type ty;
  output Boolean b;
algorithm
  b := matchcontinue (ty)
    case (DAE.T_STRING(varLst = _)) then true;
    case (DAE.T_METAOPTION(optionType = _)) then true;
    case (DAE.T_METALIST(listType = _)) then true;
    case (DAE.T_METATUPLE(types = _)) then true;
    case (DAE.T_METAUNIONTYPE(paths=_)) then true;
    case (DAE.T_METARECORD(utPath=_)) then true;
    case (DAE.T_METAPOLYMORPHIC(name = _)) then true;
    case (DAE.T_METAARRAY(ty = _)) then true;
    case (DAE.T_FUNCTION(funcArg = _)) then true;
    case (DAE.T_METABOXED(ty = _)) then true;
    case (DAE.T_ANYTYPE(anyClassType = _)) then true;
    case (DAE.T_UNKNOWN(_)) then true;
    case (DAE.T_METATYPE(ty = _)) then true;
    case (DAE.T_NORETCALL(source = _)) then true;
    case _ then false;
  end matchcontinue;
end isBoxedType;

public function boxIfUnboxedType
  input Type ty;
  output Type outType;
algorithm
  outType := matchcontinue ty
    local
      list<Type> tys;

    case (DAE.T_TUPLE(tupleType = tys))
      equation
        tys = List.map(tys, boxIfUnboxedType);
      then DAE.T_METATUPLE(tys,DAE.emptyTypeSource); // TODO?! should now propagate the type source?

    case _ then Util.if_(isBoxedType(ty), ty, DAE.T_METABOXED(ty,DAE.emptyTypeSource));

  end matchcontinue;
end boxIfUnboxedType;

public function unboxedType
  input Type ity;
  output Type out;
algorithm
  out := matchcontinue (ity)
    local
      list<Type> tys;
      Type ty;

    case DAE.T_METABOXED(ty = ty) then unboxedType(ty);

    case DAE.T_METAOPTION(optionType = ty)
      equation
        ty = unboxedType(ty);
        ty = boxIfUnboxedType(ty);
      then DAE.T_METAOPTION(ty,DAE.emptyTypeSource);

    case DAE.T_METALIST(listType = ty)
      equation
        ty = unboxedType(ty);
        ty = boxIfUnboxedType(ty);
      then
        DAE.T_METALIST(ty,DAE.emptyTypeSource);

    case DAE.T_METATUPLE(types = tys)
      equation
        tys = List.map(tys, unboxedType);
        tys = List.map(tys, boxIfUnboxedType);
      then
        DAE.T_METATUPLE(tys,DAE.emptyTypeSource);

    case DAE.T_METAARRAY(ty = ty)
      equation
        ty = unboxedType(ty);
        ty = boxIfUnboxedType(ty);
      then
        DAE.T_METAARRAY(ty,DAE.emptyTypeSource);

    case ty then ty;
  end matchcontinue;
end unboxedType;

public function listMatchSuperType "Takes lists of Exp,Type and calculates the
supertype of the list, then converts the expressions to this type.
"
  input list<DAE.Exp> ielist;
  input list<Type> typeList;
  input Boolean printFailtrace;
  output list<DAE.Exp> out;
  output Type t;
algorithm
  (out,t) := matchcontinue (ielist,typeList,printFailtrace)
    local
      DAE.Exp e;
      Type ty, st;
      list<DAE.Exp> elist;

    case ({},{},_) then ({}, DAE.T_UNKNOWN_DEFAULT);
    case (e :: _, ty :: _,_)
      equation
        st = List.reduce(typeList, superType);
        st = superType(st,st);
        st = unboxedType(st);
        elist = listMatchSuperType2(ielist,typeList,st,printFailtrace);
      then (elist, st);
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- Types.listMatchSuperType failed");
      then fail();
  end matchcontinue;
end listMatchSuperType;

protected function listMatchSuperType2
  input list<DAE.Exp> elist;
  input list<Type> typeList;
  input Type st;
  input Boolean printFailtrace;
  output list<DAE.Exp> out;
algorithm
  out := matchcontinue (elist, typeList, st, printFailtrace)
    local
      DAE.Exp e;
      list<DAE.Exp> erest;
      Type t;
      list<Type> trest;
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
        Debug.fprintln(Flags.FAILTRACE, "- Types.listMatchSuperType2 failed: " +& str);
      then fail();
  end matchcontinue;
end listMatchSuperType2;

public function superType "find the supertype of the two types"
  input Type inType1;
  input Type inType2;
  output Type out;
algorithm
  out :=
  matchcontinue (inType1,inType2)
    local
      Type t1,t2,tp;
      list<Type> type_list1,type_list2;
      Absyn.Path path1,path2;

    case (DAE.T_ANYTYPE(source = _),t2) then t2;
    case (t1,DAE.T_ANYTYPE(source = _)) then t1;
    case (DAE.T_UNKNOWN(source = _),t2) then t2;
    case (t1,DAE.T_UNKNOWN(source = _)) then t1;
    case (t1,t2 as DAE.T_METAPOLYMORPHIC(source = _)) then t2;

    case (DAE.T_TUPLE(tupleType = type_list1),DAE.T_TUPLE(tupleType = type_list2))
      equation
        type_list1 = List.map(type_list1, boxIfUnboxedType);
        type_list2 = List.map(type_list2, boxIfUnboxedType);
        type_list1 = List.threadMap(type_list1,type_list2,superType);
      then DAE.T_METATUPLE(type_list1,DAE.emptyTypeSource);

    case (DAE.T_TUPLE(tupleType = type_list1),DAE.T_METATUPLE(types = type_list2))
      equation
        type_list1 = List.map(type_list1, boxIfUnboxedType);
        type_list2 = List.map(type_list2, boxIfUnboxedType);
        type_list1 = List.threadMap(type_list1,type_list2,superType);
      then DAE.T_METATUPLE(type_list1,DAE.emptyTypeSource);

    case (DAE.T_METATUPLE(types = type_list1),DAE.T_TUPLE(tupleType = type_list2))
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

    case (DAE.T_METALIST(listType = t1),DAE.T_METALIST(listType = t2))
      equation
        t1 = boxIfUnboxedType(t1);
        t2 = boxIfUnboxedType(t2);
        tp = superType(t1,t2);
      then DAE.T_METALIST(tp,DAE.emptyTypeSource);

    case (DAE.T_METAOPTION(optionType = t1), DAE.T_METAOPTION(optionType = t2))
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

    case (DAE.T_INTEGER(source = _),DAE.T_REAL(source = _))
      then DAE.T_REAL_DEFAULT;

    case (DAE.T_REAL(source = _),DAE.T_INTEGER(source = _))
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
  input Type iactual;
  input Type iexpected;
  input Option<Absyn.Path> envPath "to detect which polymorphic types are recursive";
  input PolymorphicBindings ipolymorphicBindings;
  input Boolean printFailtrace;
  output DAE.Exp outExp;
  output Type outType;
  output PolymorphicBindings outBindings;
algorithm
  (outExp,outType,outBindings):=
  matchcontinue (iexp,iactual,iexpected,envPath,ipolymorphicBindings,printFailtrace)
    local
      DAE.Exp e,e_1,exp;
      Type e_type,expected_type,e_type_1,actual,expected;
      PolymorphicBindings polymorphicBindings;

    case (exp,actual,expected,_,polymorphicBindings,_)
      equation
        false = Config.acceptMetaModelicaGrammar();
        (e_1,e_type_1) = matchType(exp,actual,expected,printFailtrace);
      then
        (e_1,e_type_1,polymorphicBindings);
    case (exp,actual,expected,_,polymorphicBindings,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        {} = getAllInnerTypesOfType(expected, isPolymorphic);
        (e_1,e_type_1) = matchType(exp,actual,expected,printFailtrace);
      then
        (e_1,e_type_1,polymorphicBindings);
    case (exp,actual,expected,_,polymorphicBindings,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        // print("match type: " +& ExpressionDump.printExpStr(exp) +& " of " +& unparseType(actual) +& " with " +& unparseType(expected) +& "\n");
        _::_ = getAllInnerTypesOfType(expected, isPolymorphic);
        (exp,actual) = matchType(exp,actual,DAE.T_METABOXED(DAE.T_UNKNOWN_DEFAULT,DAE.emptyTypeSource),printFailtrace);
        // print("match type: " +& ExpressionDump.printExpStr(exp) +& " of " +& unparseType(actual) +& " with " +& unparseType(expected) +& " (boxed)\n");
        polymorphicBindings = subtypePolymorphic(actual,expected,envPath,polymorphicBindings);
        // print("match type: " +& ExpressionDump.printExpStr(exp) +& " of " +& unparseType(actual) +& " with " +& unparseType(expected) +& " and bindings " +& polymorphicBindingsStr(polymorphicBindings) +& " (OK)\n");
      then
        (exp,actual,polymorphicBindings);
    case (e,e_type,expected_type,_,_,true)
      equation
        printFailure(Flags.TYPES, "matchTypePolymorphic", e, e_type, expected_type);
      then fail();
  end matchcontinue;
end matchTypePolymorphic;

public function matchType "function: matchType
  This function matches an expression with an expected type, and
  converts the expression to the expected type if necessary."
  input DAE.Exp exp;
  input Type actual;
  input Type expected;
  input Boolean printFailtrace;
  output DAE.Exp outExp;
  output Type outType;
algorithm
  (outExp,outType) := matchcontinue (exp,actual,expected,printFailtrace)
    local
      DAE.Exp e,e_1;
      Type e_type,expected_type,e_type_1;
    case (e,e_type,expected_type,_)
      equation
        true = subtype(e_type, expected_type);
        /* TODO: Don't return ANY as type here; use the most restrictive... Else we get issues... */
      then
        (e,e_type);
    case (e,e_type,expected_type,_)
      equation
        false = subtype(e_type, expected_type);
        (e_1,e_type_1) = typeConvert(e,e_type,expected_type,printFailtrace);
        (e_1,_) = ExpressionSimplify.simplify1(e_1);
      then
        (e_1,e_type_1);
    case (e,e_type,expected_type,true)
      equation
        printFailure(Flags.TYPES, "matchType", e, e_type, expected_type);
      then fail();
  end matchcontinue;
end matchType;

public function matchTypes
"matchType, list of actual types, one  expected type."
  input list<DAE.Exp> iexps;
  input list<Type> itys;
  input Type expected;
  input Boolean printFailtrace;
  output list<DAE.Exp> outExps;
  output list<Type> outTys;
algorithm
  (outExps,outTys) := matchcontinue (iexps,itys,expected,printFailtrace)
    local
      DAE.Type ty;
      list<DAE.Type> otys,tys;
      DAE.Exp e;
      list<DAE.Exp> exps;

    case ({},{},_,_) then ({},{});
    case (e::exps,ty::tys,_,_)
      equation
        (e,ty) = matchType(e,ty,expected,printFailtrace);
        (exps,otys) = matchTypes(exps,tys,expected,printFailtrace);
      then
        (e::exps,ty::otys);
    case (e::_,ty::_,_,true)
      equation
        print("- Types.matchTypes failed for " +& ExpressionDump.printExpStr(e) +& " from " +& unparseType(ty) +& " to " +& unparseType(expected) +& "\n");
      then fail();
  end matchcontinue;
end matchTypes;

protected function printFailure
"@author adrpo
 print the message only when flag is on.
 this is to speed up the flattening as we don't
 generate the strings at all."
  input Flags.DebugFlag flag;
  input String source;
  input DAE.Exp e;
  input Type e_type;
  input Type expected_type;
algorithm
  _ := matchcontinue (flag, source, e, e_type, expected_type)
    case (_, _, _, _, _)
      equation
        true = Flags.isSet(flag);
        Debug.traceln("- Types." +& source +& " failed on:" +& ExpressionDump.printExpStr(e));
        Debug.traceln("  type:" +& unparseType(e_type) +& " differs from expected\n  type:" +& unparseType(expected_type));
      then ();
    case (_, _, _, _, _)
      equation
        false = Flags.isSet(flag);
      then ();
  end matchcontinue;
end printFailure;

protected function polymorphicBindingStr
  input tuple<String,list<Type>> binding;
  output String str;
protected
  list<Type> tys;
algorithm
  (str,tys) := binding;
  // Don't bother doing this fast; it's just for error messages
  str := "    " +& str +& ":\n" +& stringDelimitList(List.map1r(List.map(tys, unparseType), stringAppend, "      "), "\n");
end polymorphicBindingStr;

public function polymorphicBindingsStr
  input PolymorphicBindings bindings;
  output String str;
algorithm
  str := stringDelimitList(List.map(bindings, polymorphicBindingStr), "\n");
end polymorphicBindingsStr;

public function fixPolymorphicRestype
"Uses the polymorphic bindings to determine the result type of the function."
  input Type ty;
  input PolymorphicBindings bindings;
  input Absyn.Info info;
  output Type resType;
algorithm
  //print("Trying to fix restype: " +& unparseType(ty) +& "\n");
  resType := fixPolymorphicRestype2(ty,"$",bindings,info);
  //print("OK: " +& unparseType(resType) +& "\n");
end fixPolymorphicRestype;

protected function fixPolymorphicRestype2
  input Type ty;
  input String prefix;
  input PolymorphicBindings bindings;
  input Absyn.Info info;
  output Type resType;
algorithm
  resType := matchcontinue (ty,prefix,bindings,info)
    local
      String id,bstr,tstr;
      Type t1,t2,ty1;
      list<Type> tys,tys1;
      list<String> names1;
      list<DAE.FuncArg> args1;
      DAE.FunctionAttributes functionAttributes;
      DAE.TypeSource ts1;
      list<DAE.Const> cs;
      list<Option<DAE.Exp>> oe;

    case (DAE.T_METAPOLYMORPHIC(name = id),_,_,_)
      equation
        {t1} = polymorphicBindingsLookup(prefix +& id, bindings);
        t1 = fixPolymorphicRestype2(t1, "", bindings, info);
      then t1;

    case (DAE.T_METALIST(listType = t1),_,_,_)
      equation
        t2 = fixPolymorphicRestype2(t1, prefix,bindings, info);
        t2 = boxIfUnboxedType(t2);
      then DAE.T_METALIST(t2,DAE.emptyTypeSource);

    case (DAE.T_METAARRAY(ty = t1),_,_,_)
      equation
        t2 = fixPolymorphicRestype2(t1,prefix,bindings, info);
        t2 = boxIfUnboxedType(t2);
      then DAE.T_METAARRAY(t2,DAE.emptyTypeSource);

    case (DAE.T_METAOPTION(optionType = t1),_,_,_)
      equation
        t2 = fixPolymorphicRestype2(t1, prefix,bindings, info);
        t2 = boxIfUnboxedType(t2);
      then DAE.T_METAOPTION(t2,DAE.emptyTypeSource);

    case (DAE.T_METATUPLE(types = tys),_,_,_)
      equation
        tys = List.map3(tys, fixPolymorphicRestype2, prefix, bindings, info);
        tys = List.map(tys, boxIfUnboxedType);
      then DAE.T_METATUPLE(tys,DAE.emptyTypeSource);

    case (DAE.T_TUPLE(tupleType = tys),_,_,_)
      equation
        tys = List.map3(tys, fixPolymorphicRestype2, prefix, bindings, info);
      then DAE.T_TUPLE(tys,DAE.emptyTypeSource);

    case (DAE.T_FUNCTION(args1,ty1,functionAttributes,ts1),_,_,_)
      equation
        names1 = List.map(args1, Util.tuple41);
        tys1 = List.map(args1, Util.tuple42);
        cs = List.map(args1, Util.tuple43);
        oe = List.map(args1, Util.tuple44);
        tys1 = List.map3(tys1, fixPolymorphicRestype2, prefix, bindings, info);
        ty1 = fixPolymorphicRestype2(ty1,prefix,bindings,info);
        args1 = List.thread4Tuple(names1,tys1,cs,oe);
        ty1 = DAE.T_FUNCTION(args1,ty1,functionAttributes,ts1);
      then ty1;

    // Add Uniontype, Function reference(?)
    case (_,_,_,_)
      equation
        // failure(isPolymorphic(ty)); Recursive functions like to return polymorphic crap we don't know of
      then ty;

    case (_,_,_,_)
      equation
        tstr = unparseType(ty);
        bstr = polymorphicBindingsStr(bindings);
        id = "Types.fixPolymorphicRestype failed for type: " +& tstr +& " using bindings: " +& bstr;
        Error.addSourceMessage(Error.INTERNAL_ERROR, {id}, info);
      then fail();
  end matchcontinue;
end fixPolymorphicRestype2;

public function polymorphicBindingsLookup
  input String id;
  input PolymorphicBindings bindings;
  output list<Type> resType;
algorithm
  resType := matchcontinue (id, bindings)
    local
      String id2;
      list<Type> tys;
      PolymorphicBindings rest;
    case (_, (id2,tys)::_)
      equation
        true = id ==& id2;
      then List.map(tys, boxIfUnboxedType);
    case (_, _::rest)
      equation
        tys = polymorphicBindingsLookup(id,rest);
      then tys;
  end matchcontinue;
end polymorphicBindingsLookup;

public function getAllInnerTypesOfType
"Traverses all the types the input Type contains, checks if
they are of the type the given function specifies, then returns
a list of all those types."
  input Type inType;
  input TypeFn inFn;
  output list<Type> outTypes;
  partial function TypeFn
    input Type fnInType;
  end TypeFn;
algorithm
  outTypes := getAllInnerTypes({inType},{},inFn);
end getAllInnerTypesOfType;

protected function getAllInnerTypes
"Traverses all the types the input Type contains."
  input list<Type> inTypes;
  input list<Type> inAcc;
  input TypeFn fn;
  output list<Type> outTypes;
  partial function TypeFn
    input Type fnInType;
  end TypeFn;
algorithm
  outTypes := matchcontinue (inTypes,inAcc,fn)
    local
      Type ty,first;
      list<Type> tys,rest,acc;
      list<Var> fields;
      list<FuncArg> funcArgs;

    case ({},_,_) then inAcc;

    case ((first as DAE.T_ARRAY(ty = ty))::rest,acc,_)
      then getAllInnerTypes(ty::rest,List.consOnSuccess(first,acc,fn),fn);

    case ((first as DAE.T_METALIST(listType = ty))::rest,acc,_)
      then getAllInnerTypes(ty::rest,List.consOnSuccess(first,acc,fn),fn);

    case ((first as DAE.T_METAARRAY(ty = ty))::rest,acc,_)
      then getAllInnerTypes(ty::rest,List.consOnSuccess(first,acc,fn),fn);

    case ((first as DAE.T_METABOXED(ty = ty))::rest,acc,_)
      then getAllInnerTypes(ty::rest,List.consOnSuccess(first,acc,fn),fn);

    case ((first as DAE.T_METAOPTION(optionType = ty))::rest,acc,_)
      then getAllInnerTypes(ty::rest,List.consOnSuccess(first,acc,fn),fn);

    case ((first as DAE.T_TUPLE(tupleType = tys))::rest,acc,_)
      equation
        acc = getAllInnerTypes(tys,List.consOnSuccess(first,acc,fn),fn);
      then getAllInnerTypes(rest,acc,fn);

    case ((first as DAE.T_METATUPLE(types = tys))::rest,acc,_)
      equation
        acc = getAllInnerTypes(tys,List.consOnSuccess(first,acc,fn),fn);
      then getAllInnerTypes(rest,acc,fn);

    case ((first as DAE.T_METARECORD(fields = fields))::rest,acc,_)
      equation
        tys = List.map(fields, getVarType);
        acc = getAllInnerTypes(tys,List.consOnSuccess(first,acc,fn),fn);
      then getAllInnerTypes(rest,acc,fn);

    case ((first as DAE.T_COMPLEX(varLst = fields))::rest,acc,_)
      equation
        tys = List.map(fields, getVarType);
        acc = getAllInnerTypes(tys,List.consOnSuccess(first,acc,fn),fn);
      then getAllInnerTypes(rest,acc,fn);

    case ((first as DAE.T_SUBTYPE_BASIC(varLst = fields))::rest,acc,_)
      equation
        tys = List.map(fields, getVarType);
        acc = getAllInnerTypes(tys,List.consOnSuccess(first,acc,fn),fn);
      then getAllInnerTypes(rest,acc,fn);

    case ((first as DAE.T_FUNCTION(funcArgs,ty,_,_))::rest,acc,_)
      equation
        tys = List.map(funcArgs, Util.tuple42);
        acc = getAllInnerTypes(tys,List.consOnSuccess(first,acc,fn),fn);
      then getAllInnerTypes(ty::rest,acc,fn);

    case (first::rest,acc,_)
      then getAllInnerTypes(rest,List.consOnSuccess(first,acc,fn),fn);
  end matchcontinue;
end getAllInnerTypes;

public function uniontypeFilter
  input Type ty;
algorithm
  _ := match ty
    case DAE.T_METAUNIONTYPE(paths = _) then ();
  end match;
end uniontypeFilter;

public function metarecordFilter
  input Type ty;
algorithm
  _ := matchcontinue ty
    case DAE.T_METARECORD(utPath = _) then ();
  end matchcontinue;
end metarecordFilter;

public function getUniontypePaths
  input Type ty;
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
  input Type inType;
  output Type outType;
algorithm
  outType := match (inType)
    local
      list<FuncArg> funcArgs1,funcArgs2;
      list<String> funcArgNames;
      list<Type> funcArgTypes1, funcArgTypes2, dummyBoxedTypeList;
      list<DAE.Exp> dummyExpList;
      list<DAE.Const> cs;
      list<Option<DAE.Exp>> oe;
      Type ty2,resType1,resType2;
      Type tty1;
      Absyn.Path path;
      DAE.FunctionAttributes functionAttributes;

    case (tty1 as DAE.T_FUNCTION(funcArgs1,resType1,functionAttributes,{path}))
      equation
        funcArgNames = List.map(funcArgs1, Util.tuple41);
        funcArgTypes1 = List.map(funcArgs1, Util.tuple42);
        cs = List.map(funcArgs1, Util.tuple43);
        oe = List.map(funcArgs1, Util.tuple44);
        (dummyExpList,dummyBoxedTypeList) = makeDummyExpAndTypeLists(funcArgTypes1);
        (_,funcArgTypes2) = matchTypeTuple(dummyExpList, funcArgTypes1, dummyBoxedTypeList, false);
        funcArgs2 = List.thread4Tuple(funcArgNames,funcArgTypes2,cs,oe);
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
        // Debug.fprintln(Flags.FAILTRACE, "- Types.makeFunctionPolymorphicReference failed");
      then fail();
  end match;
end makeFunctionPolymorphicReference;

protected function makeFunctionPolymorphicReferenceResType
  input Type inType;
  output Type outType;
algorithm
  outType := matchcontinue (inType)
    local
      DAE.TypeSource ts;
      DAE.Exp e;
      Type ty,ty1,ty2;
      list<Type> tys, dummyBoxedTypeList;
      list<DAE.Exp> dummyExpList;

    case DAE.T_TUPLE(tys,ts)
      equation
        (dummyExpList,dummyBoxedTypeList) = makeDummyExpAndTypeLists(tys);
        (_,tys) = matchTypeTuple(dummyExpList, tys, dummyBoxedTypeList, false);
      then DAE.T_TUPLE(tys,ts);
    case (ty as DAE.T_NORETCALL(source = _)) then ty;
    case ty1
      equation
        ({e},{ty2}) = makeDummyExpAndTypeLists({ty1});
        (_,ty) = matchType(e, ty1, ty2, false);
      then ty;
  end matchcontinue;
end makeFunctionPolymorphicReferenceResType;

protected function makeDummyExpAndTypeLists
  input list<Type> lst;
  output list<DAE.Exp> outExps;
  output list<Type> outTypes;
algorithm
  (outExps,outTypes) := match (lst)
    local
      list<DAE.Exp> restExp;
      list<Type> restType, rest;
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
  input Type inType;
  output list<Type> outType;
algorithm
  outType := matchcontinue (inType)
    local
      list<Type> tys;
      Type ty;
    case DAE.T_TUPLE(tupleType = tys) then tys;
    case DAE.T_NORETCALL(source = _) then {};
    case ty then {ty};
  end matchcontinue;
end resTypeToListTypes;

public function getRealOrIntegerDimensions
"If the type is a Real, Integer or an array of Real or Integer, the function returns
list of dimensions; otherwise, it fails."
 input Type inType;
 output DAE.Dimensions outDims;
algorithm
  outDims := match (inType)
    local
      Type ty;
      DAE.Dimension d;
      DAE.Dimensions dims;

    case (DAE.T_REAL(source = _)) then {};
    case (DAE.T_INTEGER(source = _)) then {};
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
  input Type ty;
algorithm
  DAE.T_METAPOLYMORPHIC(name = _) := ty;
end isPolymorphic;

protected function polymorphicTypeName
  input Type ty;
  output String name;
algorithm
  DAE.T_METAPOLYMORPHIC(name = name) := ty;
end polymorphicTypeName;

protected function addPolymorphicBinding
  input String id;
  input Type ity;
  input PolymorphicBindings bindings;
  output PolymorphicBindings outBindings;
algorithm
  outBindings := matchcontinue (id,ity,bindings)
    local
      String id1,id2;
      list<Type> tys;
      PolymorphicBindings rest;
      tuple<String,list<Type>> first;
      Type ty;

    case (_,ty,{})
      equation
        ty = unboxedType(ty);
        ty = boxIfUnboxedType(ty);
      then {(id,{ty})};
    case (id1,ty,(id2,tys)::rest)
      equation
        true = id1 ==& id2;
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
  input PolymorphicBindings bindings;
  input Absyn.Info info;
  input list<Absyn.Path> pathLst;
  output PolymorphicBindings solvedBindings;
protected
  PolymorphicBindings unsolvedBindings;
algorithm
  // print("solvePoly " +& Absyn.optPathString(path) +& " " +& polymorphicBindingsStr(bindings) +& "\n");
  (solvedBindings,unsolvedBindings) := solvePolymorphicBindingsLoop(bindings, {}, {});
  checkValidBindings(bindings, solvedBindings, unsolvedBindings, info, pathLst);
end solvePolymorphicBindings;

protected function checkValidBindings
"Emits an error message if we could not solve the polymorphic types to actual types."
  input PolymorphicBindings bindings;
  input PolymorphicBindings solvedBindings;
  input PolymorphicBindings unsolvedBindings;
  input Absyn.Info info;
  input list<Absyn.Path> pathLst;
algorithm
  _ := matchcontinue (bindings, solvedBindings, unsolvedBindings, info, pathLst)
    local
      String bindingsStr, solvedBindingsStr, unsolvedBindingsStr, pathStr;

    case (_,_,{},_,_) then ();

    case (_, _, _, _, _)
      equation
        pathStr = stringDelimitList(List.map(pathLst, Absyn.pathString), ", ");
        bindingsStr = polymorphicBindingsStr(bindings);
        solvedBindingsStr = polymorphicBindingsStr(solvedBindings);
        unsolvedBindingsStr = polymorphicBindingsStr(unsolvedBindings);
        Error.addSourceMessage(Error.META_UNSOLVED_POLYMORPHIC_BINDINGS, {pathStr,bindingsStr,solvedBindingsStr,unsolvedBindingsStr},info);
      then fail();
  end matchcontinue;
end checkValidBindings;

protected function solvePolymorphicBindingsLoop
  input PolymorphicBindings ibindings;
  input PolymorphicBindings isolvedBindings;
  input PolymorphicBindings iunsolvedBindings;
  output PolymorphicBindings outSolvedBindings;
  output PolymorphicBindings outUnsolvedBindings;
algorithm
  (outSolvedBindings,outUnsolvedBindings) := matchcontinue (ibindings,isolvedBindings,iunsolvedBindings)
    /* Fail by returning crap :) */
    local
      tuple<String, list<Type>> first;
      PolymorphicBindings rest;
      Type ty;
      list<Type> tys;
      String id;
      Integer len1, len2;
      PolymorphicBindings solvedBindings,unsolvedBindings;

    case ({}, solvedBindings, unsolvedBindings) then (solvedBindings, unsolvedBindings);

    case ((id,{ty})::rest,solvedBindings,unsolvedBindings)
      equation
        (solvedBindings,unsolvedBindings) = solvePolymorphicBindingsLoop(listAppend(unsolvedBindings,rest),(id,{ty})::solvedBindings,{});
      then (solvedBindings,unsolvedBindings);

      // Replace solved bindings
    case ((id,tys)::rest,solvedBindings,unsolvedBindings)
      equation
        tys = replaceSolvedBindings(tys, solvedBindings, false);
        tys = List.unionOnTrue(tys, {}, equivtypes);
        (solvedBindings,unsolvedBindings) = solvePolymorphicBindingsLoop(listAppend((id,tys)::unsolvedBindings,rest),solvedBindings,{});
      then (solvedBindings,unsolvedBindings);

    case ((id,tys)::rest,solvedBindings,unsolvedBindings)
      equation
        (tys,solvedBindings) = solveBindings(tys, tys, solvedBindings);
        tys = List.unionOnTrue(tys, {}, equivtypes);
        (solvedBindings,unsolvedBindings) = solvePolymorphicBindingsLoop(listAppend((id,tys)::unsolvedBindings,rest),solvedBindings,{});
      then (solvedBindings,unsolvedBindings);

      // Duplicate types need to be removed
    case ((id,tys)::rest,solvedBindings,unsolvedBindings)
      equation
        len1 = listLength(tys);
        true = len1 > 1;
        tys = List.unionOnTrue(tys, {}, equivtypes); // Remove duplicates
        len2 = listLength(tys);
        false = len1 == len2;
        (solvedBindings,unsolvedBindings) = solvePolymorphicBindingsLoop(listAppend((id,tys)::unsolvedBindings,rest),solvedBindings,{});
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
  input list<Type> itys1;
  input list<Type> itys2;
  input PolymorphicBindings isolvedBindings;
  output list<Type> outTys;
  output PolymorphicBindings outSolvedBindings;
algorithm
  (outTys,outSolvedBindings) := matchcontinue (itys1,itys2,isolvedBindings)
    local
      Type ty,ty1,ty2;
      list<Type> tys,rest,tys1,tys2;
      String id,id1,id2;
      list<String> names1;
      list<DAE.FuncArg> args1,args2;
      DAE.FunctionAttributes functionAttributes1,functionAttributes2;
      DAE.TypeSource ts1;
      Boolean fromOtherFunction;
      list<DAE.Const> cs1;
      PolymorphicBindings solvedBindings;

    case ((ty1 as DAE.T_METAPOLYMORPHIC(name = id1))::tys1,(ty2 as DAE.T_METAPOLYMORPHIC(name = id2))::tys2,solvedBindings)
      equation
        false = id1 ==& id2;
        // If we have $X,Y,..., bind $X = Y instead of Y = $X
        fromOtherFunction = System.stringFind(id1,"$") <> -1;
        id = Util.if_(fromOtherFunction, id1, id2);
        ty = Util.if_(fromOtherFunction, ty2, ty1); // Lookup from one id to the other type
        failure(_ = polymorphicBindingsLookup(id, solvedBindings));
        solvedBindings = addPolymorphicBinding(id,ty,solvedBindings);
      then (ty::tys2, solvedBindings);

    case ((ty1 as DAE.T_METAPOLYMORPHIC(name = id))::tys1,ty2::tys2,solvedBindings)
      equation
        failure(isPolymorphic(ty2));
        failure(_ = polymorphicBindingsLookup(id, solvedBindings));
        solvedBindings = addPolymorphicBinding(id,ty2,solvedBindings);
      then (ty2::tys2, solvedBindings);

    case (ty1::tys1,(ty2 as DAE.T_METAPOLYMORPHIC(name = id))::tys2,solvedBindings)
      equation
        failure(isPolymorphic(ty1));
        failure(_ = polymorphicBindingsLookup(id, solvedBindings));
        solvedBindings = addPolymorphicBinding(id,ty1,solvedBindings);
      then (ty1::tys2, solvedBindings);

    case (DAE.T_METAOPTION(optionType = ty1)::tys1,DAE.T_METAOPTION(optionType = ty2)::tys2,solvedBindings)
      equation
        ({ty1},solvedBindings) = solveBindings({ty1},{ty2},solvedBindings);
        ty1 = DAE.T_METAOPTION(ty1,DAE.emptyTypeSource);
      then (ty1::tys2,solvedBindings);

    case (DAE.T_METALIST(listType = ty1)::tys1,DAE.T_METALIST(listType = ty2)::tys2,solvedBindings)
      equation
        ({ty1},solvedBindings) = solveBindings({ty1},{ty2},solvedBindings);
        ty1 = DAE.T_METALIST(ty1,DAE.emptyTypeSource);
      then (ty1::tys2,solvedBindings);

    case (DAE.T_METAARRAY(ty = ty1)::tys1,DAE.T_METAARRAY(ty = ty2)::tys2,solvedBindings)
      equation
        ({ty1},solvedBindings) = solveBindings({ty1},{ty2},solvedBindings);
        ty1 = DAE.T_METAARRAY(ty1,DAE.emptyTypeSource);
      then (ty1::tys2,solvedBindings);

    case (DAE.T_METATUPLE(types = tys1)::_,DAE.T_METATUPLE(types = tys2)::rest,solvedBindings)
      equation
        (tys1,solvedBindings) = solveBindingsThread(tys1,tys2,false,solvedBindings);
        ty1 = DAE.T_METATUPLE(tys1,DAE.emptyTypeSource);
      then (ty1::rest,solvedBindings);

    case (DAE.T_FUNCTION(args1,ty1,functionAttributes1,ts1)::_,DAE.T_FUNCTION(args2,ty2,functionAttributes2,_)::rest,solvedBindings)
      equation
        names1 = List.map(args1, Util.tuple41);
        cs1 = List.map(args1, Util.tuple43);
        tys1 = List.map(args1, Util.tuple42);
        tys2 = List.map(args2, Util.tuple42);
        (ty1::tys1,solvedBindings) = solveBindingsThread(ty1::tys1,ty2::tys2,false,solvedBindings);
        tys1 = List.map(tys1, boxIfUnboxedType);
        args1 = List.thread4Tuple(names1,tys1,cs1,List.fill(NONE(),listLength(names1)));
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
  input list<Type> itys1;
  input list<Type> itys2;
  input Boolean changed "if true, something changed and the function will succeed";
  input PolymorphicBindings isolvedBindings;
  output list<Type> outTys;
  output PolymorphicBindings outSolvedBindings;
algorithm
  (outTys,outSolvedBindings) := matchcontinue (itys1,itys2,changed,isolvedBindings)
    local
      Type ty1,ty2;
      PolymorphicBindings solvedBindings;
      list<Type> tys1, tys2;

    case (ty1::tys1,ty2::tys2,_,solvedBindings)
      equation
        ({ty1},solvedBindings) = solveBindings({ty1},{ty2},solvedBindings);
        (tys2,solvedBindings) = solveBindingsThread(tys1,tys2,true,solvedBindings);
      then (ty1::tys2,solvedBindings);
    case (ty1::tys1,ty2::tys2,_,solvedBindings)
      equation
        (tys2,solvedBindings) = solveBindingsThread(tys1,tys2,changed,solvedBindings);
      then (ty1::tys2,solvedBindings);
    case ({},{},true,solvedBindings) then ({},solvedBindings);
  end matchcontinue;
end solveBindingsThread;

protected function replaceSolvedBindings
  input list<Type> itys;
  input PolymorphicBindings isolvedBindings;
  input Boolean changed "if true, something changed and the function will succeed";
  output list<Type> outTys;
algorithm
  outTys := matchcontinue (itys, isolvedBindings, changed)
    local
      Type ty;
      list<Type> tys;
      PolymorphicBindings solvedBindings;

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
  input Type ity;
  input PolymorphicBindings isolvedBindings;
  output Type outTy;
algorithm
  outTy := match (ity,isolvedBindings)
    local
      list<DAE.FuncArg> args;
      list<Type> tys;
      String id;
      list<String> names;
      list<DAE.Const> cs;
      DAE.TypeSource ts;
      list<Option<DAE.Exp>> oe;
      DAE.FunctionAttributes functionAttributes;
      DAE.Type ty;
      PolymorphicBindings solvedBindings;

    case (DAE.T_METALIST(listType = ty),solvedBindings)
      equation
        ty = replaceSolvedBinding(ty, solvedBindings);
        ty = DAE.T_METALIST(ty, DAE.emptyTypeSource);
      then ty;

    case (DAE.T_METAARRAY(ty = ty),solvedBindings)
      equation
        ty = replaceSolvedBinding(ty, solvedBindings);
        ty = DAE.T_METAARRAY(ty,DAE.emptyTypeSource);
      then ty;

    case (DAE.T_METAOPTION(optionType = ty),solvedBindings)
      equation
        ty = replaceSolvedBinding(ty, solvedBindings);
        ty = DAE.T_METAOPTION(ty,DAE.emptyTypeSource);
      then ty;

    case (DAE.T_METATUPLE(types = tys),solvedBindings)
      equation
        tys = replaceSolvedBindings(tys,solvedBindings,false);
        ty = DAE.T_METATUPLE(tys,DAE.emptyTypeSource);
      then ty;

    case (DAE.T_FUNCTION(args,ty,functionAttributes,ts),solvedBindings)
      equation
        tys = List.map(args, Util.tuple42);
        tys = replaceSolvedBindings(ty::tys,solvedBindings,false);
        tys = List.map(tys, unboxedType);
        ty::tys = List.map(tys, boxIfUnboxedType);
        names = List.map(args, Util.tuple41);
        cs = List.map(args, Util.tuple43);
        oe = List.map(args, Util.tuple44);
        args = List.thread4Tuple(names,tys,cs,oe);
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
  input Type actual;
  input Type expected;
  input Option<Absyn.Path> envPath;
  input PolymorphicBindings ibindings;
  output PolymorphicBindings outBindings;
algorithm
  outBindings := matchcontinue (actual,expected,envPath,ibindings)
    local
      String id,prefix;
      Type ty,ty1,ty2;
      list<FuncArg> farg1,farg2;
      list<Type> tList1,tList2,tys;
      Absyn.Path path1,path2;
      list<String> ids;
      PolymorphicBindings bindings;

    case (_,DAE.T_METAPOLYMORPHIC(name = id),_,bindings)
      then addPolymorphicBinding("$" +& id,actual,bindings);

    case (DAE.T_METAPOLYMORPHIC(name = id),_,_,bindings)
      then addPolymorphicBinding("$$" +& id,expected,bindings);

    case (DAE.T_METABOXED(ty = ty1),ty2,_,bindings)
      equation
        ty1 = unboxedType(ty1);
      then subtypePolymorphic(ty1,ty2,envPath,bindings);

    case (ty1,DAE.T_METABOXED(ty = ty2),_,bindings)
      equation
        ty2 = unboxedType(ty2);
      then subtypePolymorphic(ty1,ty2,envPath,bindings);

    case (DAE.T_NORETCALL(source = _),DAE.T_NORETCALL(source = _),_,bindings) then bindings;
    case (DAE.T_INTEGER(source = _),DAE.T_INTEGER(source = _),_,bindings) then bindings;
    case (DAE.T_REAL(source = _),DAE.T_INTEGER(source = _),_,bindings) then bindings;
    case (DAE.T_STRING(source = _),DAE.T_STRING(source = _),_,bindings) then bindings;
    case (DAE.T_BOOL(source = _),DAE.T_BOOL(source = _),_,bindings) then bindings;

    case (DAE.T_METAARRAY(ty = ty1),DAE.T_METAARRAY(ty = ty2),_,bindings)
      then subtypePolymorphic(ty1,ty2,envPath,bindings);
    case (DAE.T_METALIST(listType = ty1),DAE.T_METALIST(listType = ty2),_,bindings)
      then subtypePolymorphic(ty1,ty2,envPath,bindings);
    case (DAE.T_METAOPTION(optionType = ty1),DAE.T_METAOPTION(optionType = ty2),_,bindings)
      then subtypePolymorphic(ty1,ty2,envPath,bindings);
    case (DAE.T_METATUPLE(types = tList1),DAE.T_METATUPLE(types = tList2),_,bindings)
      then subtypePolymorphicList(tList1,tList2,envPath,bindings);

    case (DAE.T_TUPLE(tupleType = tList1),DAE.T_TUPLE(tupleType = tList2),_,bindings)
      then subtypePolymorphicList(tList1,tList2,envPath,bindings);

    case (DAE.T_METAUNIONTYPE(source = {path1}),DAE.T_METAUNIONTYPE(source = {path2}),_,bindings)
      equation
        true = Absyn.pathEqual(path1,path2);
      then bindings;

    // MM Function Reference. sjoelund
    case (DAE.T_FUNCTION(farg1,ty1,_,{path1}),DAE.T_FUNCTION(farg2,ty2,_,{path2}),_,bindings)
      equation
        true = Absyn.pathPrefixOf(Util.getOptionOrDefault(envPath,Absyn.IDENT("$TOP$")),path1); // Don't rename the result type for recursive calls...
        tList1 = List.map(farg1, Util.tuple42);
        tList2 = List.map(farg2, Util.tuple42);
        bindings = subtypePolymorphicList(tList1,tList2,envPath,bindings);
        bindings = subtypePolymorphic(ty1,ty2,envPath,bindings);
      then bindings;

    case (DAE.T_FUNCTION(source = {path1}),DAE.T_FUNCTION(farg2,ty2,_,{path2}),_,bindings)
      equation
        false = Absyn.pathPrefixOf(Util.getOptionOrDefault(envPath,Absyn.IDENT("$TOP$")),path1);
        prefix = "$" +& Absyn.pathString(path1) +& ".";
        ((ty as DAE.T_FUNCTION(farg1,ty1,_,_),_)) = traverseType((actual,prefix),prefixTraversedPolymorphicType);
        tList1 = List.map(farg1, Util.tuple42);
        tList2 = List.map(farg2, Util.tuple42);
        bindings = subtypePolymorphicList(tList1,tList2,envPath,bindings);
        bindings = subtypePolymorphic(ty1,ty2,envPath,bindings);
      then bindings;

    case (DAE.T_UNKNOWN(source = _),ty2,_,bindings)
      equation
        tys = getAllInnerTypesOfType(ty2, isPolymorphic);
        ids = List.map(tys, polymorphicTypeName);
        bindings = List.fold1(ids, addPolymorphicBinding, actual, bindings);
      then bindings;

    case (DAE.T_ANYTYPE(source = _),ty2,_,bindings)
      equation
        tys = getAllInnerTypesOfType(ty2, isPolymorphic);
        ids = List.map(tys, polymorphicTypeName);
        bindings = List.fold1(ids, addPolymorphicBinding, actual, bindings);
      then bindings;

    case (_,_,_,_)
      equation
        // print("subtypePolymorphic failed: " +& unparseType(actual) +& " and " +& unparseType(expected) +& "\n");
      then fail();

  end matchcontinue;
end subtypePolymorphic;

protected function subtypePolymorphicList
"A simple subtype() that also binds polymorphic variables.
 Only works on the MetaModelica datatypes; the input is assumed to be boxed."
  input list<Type> actual;
  input list<Type> expected;
  input Option<Absyn.Path> envPath;
  input PolymorphicBindings ibindings;
  output PolymorphicBindings outBindings;
algorithm
  outBindings := match (actual,expected,envPath,ibindings)
    local
      Type ty1,ty2;
      list<Type> tList1,tList2;
      PolymorphicBindings bindings;
    case ({},{},_,bindings) then bindings;
    case (ty1::tList1,ty2::tList2,_,bindings)
      equation
        bindings = subtypePolymorphic(ty1,ty2,envPath,bindings);
        bindings = subtypePolymorphicList(tList1,tList2,envPath,bindings);
      then bindings;
  end match;
end subtypePolymorphicList;

public function boxVarLst
  input list<Var> vars;
  output list<Var> ovars;
algorithm
  ovars := match vars
    local
      Ident name;
      Attributes attributes;
      Type type_;
      Binding binding;
      Option<Const> constOfForIteratorRange;
      list<Var> rest;

    case {} then {};
    case DAE.TYPES_VAR(name,attributes,type_,binding,constOfForIteratorRange)::rest
      equation
        type_ = boxIfUnboxedType(type_);
        rest = boxVarLst(rest);
      then DAE.TYPES_VAR(name,attributes,type_,binding,constOfForIteratorRange)::rest;

  end match;
end boxVarLst;

public function liftArraySubscript "function: liftArraySubscript
Lifts a type to an array using DAE.Subscript for dimension in the case of non-expanded arrays"
  input Type inType;
  input DAE.Subscript inSubscript;
  output Type outType;
algorithm
  outType := matchcontinue (inType,inSubscript)
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
  end matchcontinue;
end liftArraySubscript;

public function liftArraySubscriptList "
  Lifts a type using list<DAE.Subscript> to determine dimensions in the case of non-expanded arrays"
  input Type inType;
  input list<DAE.Subscript> inSubscriptLst;
  output Type outType;
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
  input Type ty;
  output DAE.Exp oexp;
  output Type oty;
algorithm
  (oexp,oty) := match (exp,ty)
    case (DAE.TUPLE(_),_)
      equation
        /* So we can verify that the contents of the tuple is boxed */
        (oexp,oty) = matchType(exp,ty,DAE.T_METABOXED_DEFAULT,false);
      then (oexp,oty);
    case (_,_) then (exp,ty);
  end match;
end convertTupleToMetaTuple;

public function isFunctionType
  input Type ty;
  output Boolean b;
algorithm
  b := match ty
    case DAE.T_FUNCTION(funcArg = _) then true;
    else false;
  end match;
end isFunctionType;

protected function prefixTraversedPolymorphicType
  input tuple<Type,String> tpl;
  output tuple<Type,String> otpl;
algorithm
  otpl := match tpl
    local
      String id,prefix;
      DAE.TypeSource ts;

    case ((DAE.T_METAPOLYMORPHIC(id,ts),prefix))
      equation
        id = prefix +& id;
      then
        ((DAE.T_METAPOLYMORPHIC(id,DAE.emptyTypeSource),prefix)); // TODO! FIXME! should not propagate the ts here?

    else tpl;

  end match;
end prefixTraversedPolymorphicType;

public function makeExpDimensionsUnknown
  input tuple<Type,Integer/*dummy*/> tpl;
  output tuple<Type,Integer/*dummy*/> otpl;
algorithm
  otpl := match tpl
    local
      Type ty;
      DAE.TypeSource ts;

    case ((DAE.T_ARRAY(ty,{DAE.DIM_EXP(exp=_)},ts),_))
      then ((DAE.T_ARRAY(ty,{DAE.DIM_UNKNOWN()},ts),1));

    else tpl;

  end match;
end makeExpDimensionsUnknown;

public function traverseType
  input tuple<Type,A> itpl;
  input Func fn;
  output tuple<Type,A> otpl;
  replaceable type A subtypeof Any;
  partial function Func
    input tuple<Type,A> itpl;
    output tuple<Type,A> otpl;
  end Func;
algorithm
  otpl := match (itpl,fn)
    local
      list<Type> tys;
      Type ty;
      DAE.Dimensions ad;
      A a;
      DAE.TypeSource ts;
      String str;
      Integer index;
      list<Var> vars;
      Absyn.Path path;
      EqualityConstraint eq;
      ClassInf.State state;
      list<DAE.FuncArg> farg;
      DAE.FunctionAttributes functionAttributes;
      Boolean singleton;
      tuple<Type,A> tpl;

    case ((DAE.T_INTEGER(source = _),_),_) equation tpl = fn(itpl); then tpl;
    case ((DAE.T_REAL(source = _),_),_) equation tpl = fn(itpl); then tpl;
    case ((DAE.T_STRING(source = _),_),_) equation tpl = fn(itpl); then tpl;
    case ((DAE.T_BOOL(source = _),_),_) equation tpl = fn(itpl); then tpl;
    case ((DAE.T_ENUMERATION(source = _),_),_) equation tpl = fn(itpl); then tpl;

    case ((DAE.T_NORETCALL(source = _),_),_) equation tpl = fn(itpl); then tpl;
    case ((DAE.T_UNKNOWN(source = _),_),_) equation tpl = fn(itpl); then tpl;
    case ((DAE.T_ANYTYPE(source = _),_),_) equation tpl = fn(itpl); then tpl;
    case ((DAE.T_METAUNIONTYPE(source = _),_),_) equation tpl = fn(itpl); then tpl;
    case ((DAE.T_METABOXED(source = _),_),_) equation tpl = fn(itpl); then tpl;
    case ((DAE.T_METAPOLYMORPHIC(source = _),_),_) equation tpl = fn(itpl); then tpl;

    case ((DAE.T_ARRAY(ty,ad,ts),a),_)
      equation
        ((ty,a)) = traverseType((ty,a),fn);
        ty = DAE.T_ARRAY(ty,ad,ts);
        tpl = fn((ty,a));
      then tpl;

    case ((DAE.T_METATYPE(ty,ts),a),_)
      equation
        ((ty,a)) = traverseType((ty,a),fn);
        ty = DAE.T_METATYPE(ty,ts);
        tpl = fn((ty,a));
      then tpl;

    case ((DAE.T_METALIST(ty,ts),a),_)
      equation
        ((ty,a)) = traverseType((ty,a),fn);
        ty = DAE.T_METALIST(ty,ts);
        tpl = fn((ty,a));
      then tpl;

    case ((DAE.T_METAOPTION(ty,ts),a),_)
      equation
        ((ty,a)) = traverseType((ty,a),fn);
        ty = DAE.T_METAOPTION(ty,ts);
        tpl = fn((ty,a));
      then tpl;

    case ((DAE.T_METAARRAY(ty,ts),a),_)
      equation
        ((ty,a)) = traverseType((ty,a),fn);
        ty = DAE.T_METAARRAY(ty,ts);
        tpl = fn((ty,a));
      then tpl;

    case ((DAE.T_METATUPLE(tys,ts),a),_)
      equation
        (tys,a) = traverseTupleType(tys,a,fn);
        ty = DAE.T_METATUPLE(tys,ts);
        tpl = fn((ty,a));
      then tpl;

    case ((DAE.T_TUPLE(tys,ts),a),_)
      equation
        (tys,a) = traverseTupleType(tys,a,fn);
        ty = DAE.T_TUPLE(tys,ts);
        tpl = fn((ty,a));
      then tpl;

    case ((DAE.T_METARECORD(path,index,vars,singleton,ts),a),_)
      equation
        (vars,a) = traverseVarTypes(vars,a,fn);
        ty = DAE.T_METARECORD(path,index,vars,singleton,ts);
        tpl = fn((ty,a));
      then tpl;

    case ((DAE.T_COMPLEX(state,vars,eq,ts),a),_)
      equation
        (vars,a) = traverseVarTypes(vars,a,fn);
        ty = DAE.T_COMPLEX(state,vars,eq,ts);
        tpl = fn((ty,a));
      then tpl;
    case ((DAE.T_SUBTYPE_BASIC(state,vars,ty,eq,ts),a),_)
      equation
        (vars,a) = traverseVarTypes(vars,a,fn);
        ((ty,a)) = traverseType((ty,a),fn);
        ty = DAE.T_SUBTYPE_BASIC(state,vars,ty,eq,ts);
        tpl = fn((ty,a));
      then tpl;

    case ((DAE.T_FUNCTION(farg,ty,functionAttributes,ts),a),_)
      equation
        (farg,a) = traverseFuncArg(farg,a,fn);
        ((ty,a)) = traverseType((ty,a),fn);
        ty = DAE.T_FUNCTION(farg,ty,functionAttributes,ts);
        tpl = fn((ty,a));
      then tpl;

    case (tpl as (DAE.T_CODE(source = _),_),_)
      equation
        tpl = fn(tpl);
      then tpl;

    case ((ty,_),_)
      equation
        str = "Types.traverseType not implemented correctly: " +& unparseType(ty);
        Error.addMessage(Error.INTERNAL_ERROR,{str});
      then
        fail();
  end match;
end traverseType;

protected function traverseTupleType
  input list<Type> itys;
  input A ia;
  input Func fn;
  output list<Type> otys;
  output A oa;
  replaceable type A subtypeof Any;
  partial function Func
    input tuple<Type,A> tpl;
    output tuple<Type,A> otpl;
  end Func;
algorithm
  (otys,oa) := match (itys,ia,fn)
    local
      Type ty;
      list<Type> tys;
      A a;

    case ({},a,_) then ({},a);
    case (ty::tys,a,_)
      equation
        ((ty,a)) = traverseType((ty,a),fn);
        (tys,a) = traverseTupleType(tys,a,fn);
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
    input tuple<Type,A> tpl;
    output tuple<Type,A> otpl;
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
        ((ty,a)) = traverseType((ty,a),fn);
        var = setVarType(var,ty);
        (vars,a) = traverseVarTypes(vars,a,fn);
      then (var::vars,a);
  end match;
end traverseVarTypes;

protected function traverseFuncArg
  input list<tuple<String,Type,DAE.Const,Option<DAE.Exp>>> iargs;
  input A ia;
  input Func fn;
  output list<tuple<String,Type,DAE.Const,Option<DAE.Exp>>> oargs;
  output A oa;
  replaceable type A subtypeof Any;
  partial function Func
    input tuple<Type,A> tpl;
    output tuple<Type,A> otpl;
  end Func;
algorithm
  (oargs,oa) := match (iargs,ia,fn)
    local
      DAE.Type ty;
      String b;
      DAE.Const c;
      Option<DAE.Exp> d;
      list<tuple<String,Type,DAE.Const,Option<DAE.Exp>>> args;
      A a;

    case ({},a,_) then ({},a);
    case ((b,ty,c,d)::args,a,_)
      equation
        ((ty,a)) = traverseType((ty,a),fn);
        (args,a) = traverseFuncArg(args,a,fn);
      then ((b,ty,c,d)::args,a);
  end match;
end traverseFuncArg;

public function makeRegularTupleFromMetaTupleOnTrue
  input Boolean b;
  input Type ty;
  output Type out;
algorithm
  out := match (b,ty)
    local
      list<Type> tys;

    case (true,DAE.T_METATUPLE(tys,_))
      equation
        tys = List.map(tys, unboxedType);
        tys = List.map(tys, boxIfUnboxedType);
        tys = List.map(tys, unboxedType); // Yes. Crazy
      then (DAE.T_TUPLE(tys,DAE.emptyTypeSource));

    case (false,_) then ty;
  end match;
end makeRegularTupleFromMetaTupleOnTrue;

public function allTuple
  input list<Type> itys;
  output Boolean b;
algorithm
  b := match itys local list<Type> tys;
    case {} then true;
    case (DAE.T_TUPLE(tupleType = _)::tys) then allTuple(tys);
    else false;
  end match;
end allTuple;

public function unboxedFunctionType "For DAE.PARTEVALFUNC"
  input Type inType;
  output Type outType;
algorithm
  outType := match inType
    local
      list<DAE.FuncArg> args1;
      list<Type> tys1;
      list<String> names1;
      list<DAE.Const> cs1;
      list<Option<DAE.Exp>> oe1;
      Type ty1;
      DAE.FunctionAttributes functionAttributes;
      DAE.TypeSource ts;

    case (DAE.T_FUNCTION(args1,ty1,functionAttributes,ts))
      equation
        names1 = List.map(args1, Util.tuple41);
        tys1 = List.map(args1, Util.tuple42);
        cs1 = List.map(args1, Util.tuple43);
        oe1 = List.map(args1, Util.tuple44);
        tys1 = List.map(tys1, unboxedType);
        ty1 = unboxedType(ty1);
        args1 = List.thread4Tuple(names1,tys1,cs1,oe1);
      then (DAE.T_FUNCTION(args1,ty1,functionAttributes,ts));
  end match;
end unboxedFunctionType;

public function printCodeTypeStr
  input DAE.CodeType ct;
  output String str;
algorithm
  str := match ct
    case DAE.C_EXPRESSION() then "OpenModelica.Code.Expression";
    case DAE.C_TYPENAME() then "OpenModelica.Code.TypeName";
    case DAE.C_VARIABLENAME() then "OpenModelica.Code.VariableName";
    case DAE.C_VARIABLENAMES() then "OpenModelica.Code.VariableNames";
    else "Types.printCodeTypeStr failed";
  end match;
end printCodeTypeStr;

public function varHasMetaRecordType
  input Var var;
  output Boolean b;
algorithm
  b := match var
    case DAE.TYPES_VAR(ty = DAE.T_METABOXED(ty = DAE.T_METARECORD(utPath=_)))
      then true;
    case DAE.TYPES_VAR(ty = DAE.T_METARECORD(utPath = _))
      then true;
    case DAE.TYPES_VAR(ty = DAE.T_METABOXED(ty = DAE.T_COMPLEX(complexClassType = ClassInf.META_RECORD(_))))
      then true;
    else false;
  end match;
end varHasMetaRecordType;

public function scalarSuperType
  "Checks that the givens types are scalar and that one is subtype of the other (in the case of integers)."
  input Type ity1;
  input Type ity2;
  output Type ty;
algorithm
  ty := matchcontinue (ity1,ity2)
    local Type ty1, ty2;
    case (DAE.T_INTEGER(varLst = _),DAE.T_INTEGER(varLst = _)) then DAE.T_INTEGER_DEFAULT;
    case (DAE.T_REAL(varLst = _),DAE.T_REAL(varLst = _))       then DAE.T_REAL_DEFAULT;
    case (DAE.T_INTEGER(varLst = _),DAE.T_REAL(varLst = _))    then DAE.T_REAL_DEFAULT;
    case (DAE.T_REAL(varLst = _),DAE.T_INTEGER(varLst = _))    then DAE.T_REAL_DEFAULT;
    case (DAE.T_SUBTYPE_BASIC(complexType = ty1),ty2)          then scalarSuperType(ty1,ty2);
    case (ty1,DAE.T_SUBTYPE_BASIC(complexType = ty2))          then scalarSuperType(ty1,ty2);

    case (DAE.T_BOOL(varLst = _),DAE.T_BOOL(varLst = _))       then DAE.T_BOOL_DEFAULT;
    // adrpo: TODO? Why not string here?
    // case (DAE.T_STRING(varLst = _),DAE.T_STRING(varLst = _))   then DAE.T_STRING_DEFAULT;
  end matchcontinue;
end scalarSuperType;

protected function optInteger
  input Option<Integer> inInt;
  output Integer outInt;
algorithm
  outInt := match(inInt)
    local Integer i;
    case (SOME(i)) then i;
    case _ then -1;
  end match;
end optInteger;

public function typeToValue "function: typeToValue
  This function builds Values.Value out of a type using generated bindings."
  input Type inType;
  output Values.Value defaultValue;
algorithm
  defaultValue := matchcontinue (inType)
    local
      list<Var> vars;
      list<Ident> comp;
      ClassInf.State st;
      Type t;
      list<Type> tys;
      String s1;
      Absyn.Path path;
      Integer i;
      Option<Integer> iOpt;
      Values.Value v;
      list<Values.Value> valueLst, ordered;

    case (DAE.T_INTEGER(varLst = vars)) then Values.INTEGER(0);
    case (DAE.T_REAL(varLst = vars)) then Values.REAL(0.0);
    case (DAE.T_STRING(varLst = vars)) then Values.STRING("<EMPTY>");
    case (DAE.T_BOOL(varLst = vars)) then Values.BOOL(false);
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

    case (DAE.T_TUPLE(tupleType = tys))
      equation
        valueLst = List.map(tys, typeToValue);
        v = Values.TUPLE(valueLst);
      then
        v;

    // All the other ones we don't handle
    case (_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Types.typeToValue failed on unhandled Type ");
        s1 = printTypeStr(inType);
        Debug.traceln(s1);
      then
        fail();

  end matchcontinue;
end typeToValue;

public function varsToValues "function varsToValues
  Translates a list of Var list to Values.Value, the
  names of the variables as component names.
  Used e.g. when retrieving the type of a record value."
  input list<Var> inVarLst;
  output list<Values.Value> outValuesValueLst;
  output list<String> outExpIdentLst;
algorithm
  (outValuesValueLst,outExpIdentLst) := matchcontinue (inVarLst)
    local
      Type tp;
      list<Var> rest;
      Values.Value v;
      list<Values.Value> restVals;
      Ident id;
      list<Ident> restIds;

    case ({}) then ({}, {});

    case (DAE.TYPES_VAR(name = id,ty = tp)::rest)
      equation
        v = typeToValue(tp);
        (restVals, restIds) = varsToValues(rest);
      then
        (v::restVals, id::restIds);

    case (_)
      equation
        Debug.fprint(Flags.FAILTRACE, "- Types.varsToValues failed\n");
      then
        fail();
  end matchcontinue;
end varsToValues;

public function makeNthDimUnknown
  "Real [3,2,1],3 => Real [3,2,:]"
  input Type ty;
  input Integer dim;
  output Type oty;
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
  input Type ity1;
  input Absyn.Info info;
  input Type ity2;
  output Type ty;
algorithm
  ty := matchcontinue (ity1,info,ity2)
    local
      String str1,str2;
      Type ty1, ty2;
    case (ty1,_,ty2)
      equation
        true = isInteger(arrayElementType(ty1));
        true = isReal(arrayElementType(ty2));
        ((ty1,_)) = traverseType((ty1,-1),replaceIntegerTypeWithReal);
        true = subtype(ty1,ty2);
      then ty1;
    case (ty1,_,ty2)
      equation
        true = isInteger(arrayElementType(ty2));
        true = isReal(arrayElementType(ty1));
        ((ty2,_)) = traverseType((ty2,-1),replaceIntegerTypeWithReal);
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
  input tuple<Type,Integer> tpl;
  output tuple<Type,Integer> oty;
algorithm
  oty := match tpl
    case ((DAE.T_INTEGER(varLst = _),_)) then ((DAE.T_REAL_DEFAULT,1));
    else tpl;
  end match;
end replaceIntegerTypeWithReal;

public function isZeroLengthArray
  input Type ty;
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

public function isValidFunctionVarType
  input Type inType;
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
    case ClassInf.MODEL(path = _) then false;
    case ClassInf.BLOCK(path = _) then false;
    case ClassInf.CONNECTOR(path = _) then false;
    case ClassInf.OPTIMIZATION(path = _) then false;
    case ClassInf.PACKAGE(path = _) then false;
    else true;
  end match;
end isValidFunctionVarState;

protected function makeDummyExpFromType
  "Creates a dummy expression from a type. Used by typeConvertArray to handle
  empty arrays."
  input Type inType;
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

    case (DAE.T_INTEGER(varLst = _)) then DAE.ICONST(0);
    case (DAE.T_REAL(varLst = _)) then DAE.RCONST(0.0);
    case (DAE.T_STRING(varLst = _)) then DAE.SCONST("");
    case (DAE.T_BOOL(varLst = _)) then DAE.BCONST(false);
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
  input Type inType;
  output Boolean b;
algorithm
  b := match(inType)
    case (DAE.T_UNKNOWN(source = _)) then true;
    case (DAE.T_ANYTYPE(source = _)) then true;
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
  input Type inType;
  output DAE.TypeSource outTypeSource;
algorithm
  outTypeSource := match(inType)
    local
      DAE.TypeSource source;

    case (DAE.T_INTEGER(source =  source)) then source;
    case (DAE.T_REAL(source =  source)) then source;
    case (DAE.T_STRING(source =  source)) then source;
    case (DAE.T_BOOL(source =  source)) then source;
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
  input Type inType;
  input DAE.TypeSource inTypeSource;
  output Type outType;
algorithm
  outType := matchcontinue(inType, inTypeSource)
    local
      DAE.TypeSource s, ts;
      list<Var> v, al;
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
      list<DAE.Type> tys;
      DAE.CodeType ct;
      String str;

    case (DAE.T_INTEGER(v, s), ts) then DAE.T_INTEGER(v, ts);
    case (DAE.T_REAL(v, s), ts) then DAE.T_REAL(v, ts);
    case (DAE.T_STRING(v, s), ts) then DAE.T_STRING(v, ts);
    case (DAE.T_BOOL(v, s), ts) then DAE.T_BOOL(v, ts);
    case (DAE.T_ENUMERATION(oi, p, n, v, al, s), ts) then DAE.T_ENUMERATION(oi, p, n, v, al, ts);

    case (DAE.T_ARRAY(t, dims, s), ts) then DAE.T_ARRAY(t, dims, ts);
    case (DAE.T_NORETCALL(s),ts) then DAE.T_NORETCALL(ts);
    case (DAE.T_UNKNOWN(s),ts) then DAE.T_UNKNOWN(ts);
    case (DAE.T_COMPLEX(cis, v, ec, s), ts) then DAE.T_COMPLEX(cis, v, ec, ts);
    case (DAE.T_SUBTYPE_BASIC(cis, v, t, ec, s), ts) then DAE.T_SUBTYPE_BASIC(cis, v, t, ec, ts);
    case (DAE.T_FUNCTION(funcArg, funcRType, funcAttr, s), ts) then DAE.T_FUNCTION(funcArg, funcRType, funcAttr, ts);
    case (DAE.T_FUNCTION_REFERENCE_VAR(t, s), ts) then DAE.T_FUNCTION_REFERENCE_VAR(t, ts);
    case (DAE.T_FUNCTION_REFERENCE_FUNC(b, t, s), ts) then DAE.T_FUNCTION_REFERENCE_FUNC(b, t, ts);
    case (DAE.T_TUPLE(tys, s), ts) then DAE.T_TUPLE(tys, ts);
    case (DAE.T_CODE(ct, s), ts) then DAE.T_CODE(ct, ts);
    case (DAE.T_ANYTYPE(ocis, s), ts) then DAE.T_ANYTYPE(ocis, s);

    case (DAE.T_METALIST(t, s), ts) then DAE.T_METALIST(t, ts);
    case (DAE.T_METATUPLE(tys, s), ts) then DAE.T_METATUPLE(tys, ts);
    case (DAE.T_METAOPTION(t, s), ts) then DAE.T_METAOPTION(t, ts);
    case (DAE.T_METAUNIONTYPE(ps, b, s), ts) then DAE.T_METAUNIONTYPE(ps, b, ts);
    case (DAE.T_METARECORD(p, i, v, b, s), ts) then DAE.T_METARECORD(p, i, v, b, ts);
    case (DAE.T_METAARRAY(t, s), ts) then DAE.T_METAARRAY(t, ts);
    case (DAE.T_METABOXED(t, s), ts) then DAE.T_METABOXED(t, ts);
    case (DAE.T_METAPOLYMORPHIC(str, s), ts) then DAE.T_METAPOLYMORPHIC(str, ts);
    case (DAE.T_METATYPE(t, s), ts) then DAE.T_METATYPE(t, ts);
    case (t,ts)
      equation
        print("Could not set type source:" +& printTypeSourceStr(ts) +& " in type: " +&
          printTypeStr(t) +& "\n");
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
    case (ts as {}) then "";
    // yeha, we have some
    case (ts)
      equation
        s = " origin: " +& stringDelimitList(List.map(ts, Absyn.pathString), ", ");
      then
        s;
  end matchcontinue;
end printTypeSourceStr;

public function isOverdeterminedType
  "Returns true if the given type is overdetermined, i.e. a type or record with
   an equalityConstraint function, otherwise false."
  input Type inType;
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
  input Type ty;
  output Boolean b;
algorithm
  ((_,b)) := traverseType((ty,false),hasMetaArrayWork);
end hasMetaArray;

protected function hasMetaArrayWork
  input tuple<Type,Boolean> inTpl;
  output tuple<Type,Boolean> outTpl;
algorithm
  outTpl := match inTpl
    local
      Type ty;
    case ((ty as DAE.T_METAARRAY(ty=_), false)) then ((ty,true));
    else inTpl;
  end match;
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
    case (_, _)
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

    case (v::rest)
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
  b := matchcontinue(inVar)
    case (DAE.TYPES_VAR(binding = DAE.UNBOUND())) then false;
    else true;
  end matchcontinue;
end hasBinding;

public function typeErrorSanityCheck
  input String inType1;
  input String inType2;
  input Absyn.Info inInfo;
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

end Types;
