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

package Types
" file:         Types.mo
  package:     Types
  description: Type system

  RCS: $Id$

  This file specifies the type system, as defined in the modelica
  specification. It contains an MetaModelica Compiler (MMC) type called `Type\' which
  defines types. It also contains functions for
  determining subtyping etc.

  There are a few known problems with this module.  It currently
  depends on SCode.Attributes, which in turn depends on
  Absyn.ArrayDim.  However, the only things used from those
  modules are constants that could be moved to their own modules."

public import ClassInf;
public import Absyn;
public import DAE;
public import Values;
public import SCode;

public type Attributes = DAE.Attributes;
public type Binding = DAE.Binding;
public type Const = DAE.Const;
public type EqualityConstraint = DAE.EqualityConstraint;
public type EqMod = DAE.EqMod;
public type FuncArg = DAE.FuncArg;
public type Ident = String;
public type Mod = DAE.Mod;
public type PolymorphicBindings = list<tuple<String,Type>>;
public type Properties = DAE.Properties;
public type SubMod = DAE.SubMod;
public type TType = DAE.TType;
public type TupleConst = DAE.TupleConst;
public type Type = DAE.Type;
public type Var = DAE.Var;

protected import Dump;
protected import Debug;
protected import Exp;
protected import Print;
protected import Util;
protected import RTOpts;
protected import ValuesUtil;
protected import DAEUtil;
protected import OptManager;

public function discreteType
"function: discreteType
  author: PA
  Succeeds for all the discrete types, Integer, String, Boolean and enumeration."
  input Type inType;
algorithm
  _ := matchcontinue (inType)
    case ((DAE.T_INTEGER(varLstInt = _),_)) then ();
    case ((DAE.T_STRING(varLstString = _),_)) then ();
    case ((DAE.T_BOOL(varLstBool = _),_)) then ();
    case ((DAE.T_ENUMERATION(names = _),_)) then ();
  end matchcontinue;
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

  case(prop::{}) then prop;
  case((prop as DAE.PROP(ty,c))::inProps)
    equation
      (prop2 as DAE.PROP(ty2,c2)) = propsAnd(inProps);
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
  outProperties := matchcontinue(inType,inProperties)
    local
      DAE.Const cf;
      DAE.TupleConst tc;
      DAE.Type ty;
    case(ty,DAE.PROP(_,cf)) then DAE.PROP(ty,cf);
    case(ty,DAE.PROP_TUPLE(_,tc)) then DAE.PROP_TUPLE(ty,tc);
  end matchcontinue;
end setTypeInProps;

// stefan
public function getConstList
"function: getConstList
  retrieves a list of Consts from a list of Properties"
  input list<Properties> inPropertiesList;
  output list<Const> outConstList;
algorithm
  outConstList := matchcontinue(inPropertiesList)
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
        c = elabTypePropToConst2(tc);
        ccdr = getConstList(pcdr);
      then
        c :: ccdr;
  end matchcontinue;
end getConstList;


public function elabTypePropToConst " function elabTypePropToConst
this function elaborates on a DAE.Properties and return the DAE.Const value.
"
input list<Properties> p;
output Const c;
algorithm
  c :=
  matchcontinue (p)
      local
        Properties p1;
        list<Properties> pps;
        Const c1,c2;
        TupleConst tc1;
    case({}) then DAE.C_CONST();
    case ((p1 as DAE.PROP(_,c1))::pps)
      equation
        c2 = elabTypePropToConst(pps);
        c1 = constAnd(c1, c2);
      then
        c1;
    case((p1 as DAE.PROP_TUPLE(_,tc1))::pps)
      equation
        c1 = elabTypePropToConst2(tc1);
        c2 = elabTypePropToConst(pps);
        c1 = constAnd(c1, c2);
      then
        c1;
  end matchcontinue;
end elabTypePropToConst;

protected function elabTypePropToConst2 ""
input TupleConst t;
output Const c;
algorithm
  c :=
  matchcontinue (t)
      local
        TupleConst p1;
        Const c1,c2;
        list<TupleConst> tcxl;
        TupleConst tc1;

    case (p1 as DAE.SINGLE_CONST(c1))
      then
        c1;
      case(p1 as DAE.TUPLE_CONST(tc1::tcxl))
        equation
          c1 = elabTypePropToConst2(tc1);
          c2 = elabTypePropToConst3(tcxl);
          c1 = constAnd(c1, c2);
          then
            c1;
  end matchcontinue;
end elabTypePropToConst2;

protected function elabTypePropToConst3 ""
input list<TupleConst> t;
output Const c;
algorithm
  c :=
  matchcontinue (t)
      local
        TupleConst p1;
        Const c1,c2;
        list<TupleConst> tcxl;
        TupleConst tc1;
    case({}) then DAE.C_CONST();
    case((p1 as DAE.SINGLE_CONST(c1))::tcxl)
      equation
        c2 = elabTypePropToConst3(tcxl);
        c1 = constAnd(c1, c2);
      then
        c1;
      case((p1 as DAE.TUPLE_CONST(_))::tcxl)
        equation
          c1 = elabTypePropToConst2(p1);
          c2 = elabTypePropToConst3(tcxl);
          c1 = constAnd(c1, c2);
          then
            c1;
  end matchcontinue;
end elabTypePropToConst3;

public function externalObjectType "author: PA

  Succeeds if type is ExternalObject
"
  input Type inType;
algorithm
  _:=
  matchcontinue (inType)
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_)),_)) then ();
  end matchcontinue;
end externalObjectType;

public function varName "
Author BZ, 2009-09
Function for getting the name of a DAE.Var"
  input Var v;
  output String s;
algorithm 
  s := matchcontinue(v)
    case(DAE.TYPES_VAR(name = s)) then s;
  end matchcontinue;
end varName;

public function externalObjectConstructorType "author: PA
  Succeeds if type is ExternalObject constructor function"
  input Type inType;
algorithm
  _ := matchcontinue (inType)
    local Type tp;  
    case ((DAE.T_FUNCTION(funcResultType = tp),_))
      equation
        externalObjectType(tp);
      then ();
  end matchcontinue;
end externalObjectConstructorType;

public function simpleType "function: simpleType
  author: PA  
  Succeeds for all the builtin types, Integer, String, Real, Boolean"
  input Type inType;
algorithm
  _ := matchcontinue (inType)
    case ((DAE.T_REAL(varLstReal = _),_)) then ();
    case ((DAE.T_INTEGER(varLstInt = _),_)) then ();
    case ((DAE.T_STRING(varLstString = _),_)) then ();
    case ((DAE.T_BOOL(varLstBool = _),_)) then ();
    case ((DAE.T_ENUMERATION(path = _), _)) then ();
  end matchcontinue;
end simpleType;

public function isComplexConnector ""
  input Type t;
  output Boolean b;
algorithm b := matchcontinue(t)
  case((DAE.T_COMPLEX(ClassInf.CONNECTOR(_,_),_,_,_),_)) then true;
  case(_) then false;
  end matchcontinue;
end isComplexConnector;

public function isComplexType "
Author: BZ, 2008-11
This function checks wheter a type is complex AND not extending a base type."
  input Type ty;
  output Boolean b;
algorithm b := matchcontinue(ty)
  case((DAE.T_COMPLEX(_,_::_,_,_),_)) then true; // not derived from baseclass
  case(_) then false;
  end matchcontinue;
end isComplexType;

public function isExternalObject "Returns true if type is COMPLEX and external object (ClassInf)"
  input Type tp;
  output Boolean b;
algorithm
  b := matchcontinue(tp)
    case((DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_)),_)) then true;
    case(_) then false;
  end matchcontinue;
end isExternalObject;

public function expTypetoTypesType "Function: expTypetoTypesType Converts a DAE.ExpType to a DAE.Type
NOTE: This function should not be used in general,
since it is not recommended to translate DAE.ExpType into DAE.Type."
input DAE.ExpType inexp;
output Type oType;
algorithm
  oType := matchcontinue(inexp)
  local Type ty,ty2;
    case(DAE.ET_INT)
      equation
        ty = DAE.T_INTEGER_DEFAULT;
        then ty;
    case(DAE.ET_REAL)
      equation
        ty = DAE.T_REAL_DEFAULT;
        then ty;
    case(DAE.ET_BOOL)
      equation
        ty = DAE.T_BOOL_DEFAULT;
        then ty;
    case(DAE.ET_STRING)
      equation
        ty = DAE.T_STRING_DEFAULT;
        then ty;
    case(DAE.ET_ENUMERATION(path,names,evars))
      local
        Absyn.Path path;
        list<String> names;
        list<DAE.ExpVar> evars;
        list<Var> tvars;
      equation
        tvars = Util.listMap(evars, convertFromExpToTypesVar);
        ty = (DAE.T_ENUMERATION(NONE,path,names,tvars,{}),NONE());
        then ty;
    case(DAE.ET_ARRAY(at,dim::ad))
      local DAE.ExpType at;
        list<DAE.Dimension> ad;
        DAE.Dimension dim;
        Integer ll;
        Integer currDim;
        TType tty;
        equation
          ll = listLength(ad);
          true = (ll == 0);
          ty = expTypetoTypesType(at);
          tty = DAE.T_ARRAY(dim,ty);
          ty2 = (tty,NONE);
          then
            ty2;
    case(DAE.ET_ARRAY(at,dim::ad))
      local DAE.ExpType at;
        list<DAE.Dimension> ad;
        DAE.Dimension dim;
        Integer ll;
        Integer currDim;
        TType tty;
        equation
          ll = listLength(ad);
          true = (ll > 0);
          ty = expTypetoTypesType(DAE.ET_ARRAY(at,ad));
          tty = DAE.T_ARRAY(dim,ty);
          ty2 = (tty,NONE);
          then
            ty2;
    case(DAE.ET_COMPLEX(complexClassType = complexClassType, varLst = evars)) //record COMPLEX "Complex types, currently only used for records "
      local
        list<DAE.ExpVar> evars;
        list<Var> tvars;
        ClassInf.State complexClassType;
      equation
        tvars = Util.listMap(evars, convertFromExpToTypesVar);
        ty = (DAE.T_COMPLEX(complexClassType,tvars,NONE,NONE),NONE);
      then
        ty;
    case(DAE.ET_UNIONTYPE()) then ((DAE.T_UNIONTYPE({}),NONE));
    case(DAE.ET_BOXED(at))
      local DAE.ExpType at;
      equation
        ty = expTypetoTypesType(at);
        ty2 = (DAE.T_BOXED(ty),NONE);
      then ty2;
    case(DAE.ET_LIST(at))
      local DAE.ExpType at;
      equation
        ty = expTypetoTypesType(at);
        ty2 = (DAE.T_LIST(ty),NONE);
      then ty2;
    case(_)
      equation
        Debug.fprint("failtrace", "-Types.expTypetoTypesType Conversion of all Exp types not yet implemented\n");
      then
        fail();
  end matchcontinue;
end expTypetoTypesType;

protected function convertFromExpToTypesVar ""
input DAE.ExpVar inVars;
output Var outVars;
algorithm outVars := matchcontinue(inVars)
local
  String name;
  DAE.ExpType tp;
  Type ty;
  DAE.ExpVar ev;
  Var tv;
  case(ev as DAE.COMPLEX_VAR(name,tp))
    equation
      ty = expTypetoTypesType(tp);
      tv = DAE.TYPES_VAR(name,DAE.ATTR(false,false,SCode.RW, SCode.VAR, Absyn.BIDIR, Absyn.UNSPECIFIED),false,ty,DAE.UNBOUND(),NONE());
      then
        tv;
  case(_) equation print("error in convertFromExpToTypesVar\n"); then fail();
  end matchcontinue;
end convertFromExpToTypesVar;

protected function convertFromTypesToExpVar ""
input Var inVars;
output DAE.ExpVar outVars;
algorithm outVars := matchcontinue(inVars)
local
  String tname;
  DAE.ExpType tp;
  Type ty;
  Var ev;
  DAE.ExpVar tv;
  case(ev as DAE.TYPES_VAR(name=tname,type_=ty))
    equation
      tp = elabType(ty);
      tv = DAE.COMPLEX_VAR(tname,tp);
      then
        tv;
  case(_)
    equation
      print("-Types.convertFromTypesToExpVar failed\n");
      Debug.fprint("failtrace", "-Types.convertFromTypesToExpVar failed\n");
    then fail();
end matchcontinue;
end convertFromTypesToExpVar;

public function isTuple "Returns true if type is TUPLE"
  input Type tp;
  output Boolean b;
algorithm
  b := matchcontinue(tp)
    case((DAE.T_TUPLE(_),_)) then true;
    case(_) then false;
  end matchcontinue;
end isTuple;

public function isRecord "Returns true if type is COMPLEX and a record (ClassInf)"
  input Type tp;
  output Boolean b;
algorithm
  b := matchcontinue(tp)
    case((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),_)) then true;
    case(_) then false;
  end matchcontinue;
end isRecord;

public function isRecordWithOnlyReals "Returns true if type is a record only containing Reals"
  input Type tp;
  output Boolean b;
algorithm
  b := matchcontinue(tp)
  local list<Boolean> bLst;
    list<Var> varLst;
    case((DAE.T_COMPLEX(ClassInf.RECORD(_),varLst,_,_),_)) equation
        bLst = Util.listMap(Util.listMap(varLst,getVarType),isReal);
        b = Util.boolAndList(bLst);
    then b;
    case(_) then false;
  end matchcontinue;
end isRecordWithOnlyReals;

public function getVarType "Return the Type of a Var"
  input Var v;
  output Type tp;
algorithm
  tp := matchcontinue(v)
    case(DAE.TYPES_VAR(type_ = tp)) then tp;
  end matchcontinue;
end getVarType;

public function getVarName "Return the name of a Var"
  input Var v;
  output String name;
algorithm
  name := matchcontinue(v)
    case(DAE.TYPES_VAR(name = name)) then name;
  end matchcontinue;
end getVarName;

public function isReal "Returns true if type is Real"
input Type tp;
output Boolean res;
algorithm
 res := matchcontinue(tp)
   case(tp) equation
      ((DAE.T_REAL(_),_)) = arrayElementType(tp);
     then true;
   case(_) then false;
 end matchcontinue;
end isReal;

public function isRealOrSubTypeReal "
Author BZ 2008-05
This function verifies if it is some kind of a Real type we are working with.
"
  input Type inType;
  output Boolean b;
algorithm b := matchcontinue(inType)
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
This function verifies if it is some kind of a Integer type we are working with.
"
  input Type inType;
  output Boolean b;
algorithm b := matchcontinue(inType)
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

public function isInteger "Returns true if type is Integer"
input Type tp;
output Boolean res;
algorithm
 res := matchcontinue(tp)
   case(tp) equation
      ((DAE.T_INTEGER(_),_)) = arrayElementType(tp);
     then true;
   case(_) then false;
 end matchcontinue;
end isInteger;

public function isBoolean "Returns true if type is Boolean"
input Type tp;
output Boolean res;
algorithm
 res := matchcontinue(tp)
   case(tp) equation
      ((DAE.T_BOOL(_),_)) = arrayElementType(tp);
     then true;
   case(_) then false;
 end matchcontinue;
end isBoolean;

public function integerOrReal "function: integerOrReal
  author: PA

  Succeeds for the builtin types Integer and Real (including classes extending the basetype Integer or Real).
"
  input Type inType;
algorithm
  _:=
  matchcontinue (inType)
      local Type tp;
    case ((DAE.T_REAL(varLstReal = _),_)) then ();
    case ((DAE.T_INTEGER(varLstInt = _),_)) then ();
    case ((DAE.T_COMPLEX( complexTypeOption=SOME(tp)),_))
      equation integerOrReal(tp);
    then ();
  end matchcontinue;
end integerOrReal;

public function isArray "function: isArray

  Returns true if Type is an array.
"
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inType)
      local Type t;
    case ((DAE.T_ARRAY(arrayDim = _),_)) then true;
    case ((DAE.T_COMPLEX(_,_,SOME(t),_),_)) then isArray(t);
    case ((_,_)) then false;
  end matchcontinue;
end isArray;

public function isEmptyArray
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inType)
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM_INTEGER(0)), _)) then true;
    case _ then false;
  end matchcontinue;
end isEmptyArray;

public function isString "function: isString

  Return true if Type is the builtin String type.
"
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inType)
    case ((DAE.T_STRING(varLstString = _),_)) then true;
    case ((_,_)) then false;
  end matchcontinue;
end isString;

public function isEnumeration "function: isEnumeration

  Return true if Type is the builtin String type.
"
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inType)
    case ((DAE.T_ENUMERATION(index = _),_)) then true;
    case ((_,_)) then false;
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
        true = isArray(ty);
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

public function ndims "function: ndims

  Return the number of dimensions of a Type.
"
  input Type inType;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inType)
    local
      Integer n;
      Type t;
    case ((DAE.T_ARRAY(arrayType = t),_))
      equation
        n = ndims(t);
      then
        n + 1;
    case ((DAE.T_COMPLEX(_,_,SOME(t),_),_)) equation
        n = ndims(t);
    then n;
    case ((_,_)) then 0;
  end matchcontinue;
end ndims;

public function dimensionsKnown
  "Returns true if the dimensions of the type is known."
  input Type inType;
  output Boolean outRes;
algorithm
  outRes := matchcontinue(inType)
    local
      DAE.Dimension d;
      Type tp;
    case ((DAE.T_ARRAY(arrayDim = d, arrayType = tp), _))
      equation
        true = Exp.dimensionKnown(d);
        true = dimensionsKnown(tp);
      then
        true;
    case ((DAE.T_ARRAY(arrayDim = _), _)) 
      then false;
    case ((DAE.T_COMPLEX(complexTypeOption = SOME(tp)), _))
      then dimensionsKnown(tp);
    case _ then true;
  end matchcontinue;
end dimensionsKnown;

public function stripSubmod
"function: stripSubmod
  author: PA
  Removes the sub modifiers of a modifier."
  input Mod inMod;
  output Mod outMod;
algorithm
  outMod := matchcontinue (inMod)
    local
      Boolean f;
      Absyn.Each each_;
      list<SubMod> subs;
      Option<EqMod> eq;
      Mod m;
    case (DAE.MOD(finalPrefix = f,each_ = each_,subModLst = subs,eqModOption = eq)) then DAE.MOD(f,each_,{},eq);
    case (m) then m;
  end matchcontinue;
end stripSubmod;

public function removeFirstSubsRedecl "
Author: BZ, 2009-08
Removed REDECLARE() statements at first level of SubMods
"
  input Mod inMod;
  output Mod outMod;
algorithm
  outMod:=
  matchcontinue (inMod)
    local
      Boolean f;
      Absyn.Each each_;
      list<SubMod> subs;
      Option<EqMod> eq;
      Mod m;
    case (DAE.MOD(finalPrefix = f,each_ = each_,subModLst = {},eqModOption = eq)) then DAE.MOD(f,each_,{},eq);
    case (DAE.MOD(finalPrefix = f,each_ = each_,subModLst = subs,eqModOption = NONE))
      equation
         {} = removeRedecl(subs);
      then
        DAE.NOMOD();
    case (DAE.MOD(finalPrefix = f,each_ = each_,subModLst = subs,eqModOption = eq))
      equation
         subs = removeRedecl(subs);
      then
        DAE.MOD(f,each_,subs,eq);
    case (m) then m;
  end matchcontinue;
end removeFirstSubsRedecl;

protected function removeRedecl "
Author BZ
helper function for removeFirstSubsRedecl
"
input list<SubMod> subs;
output list<SubMod> osubs;
algorithm osubs := matchcontinue(subs)
  local
    SubMod sm;
    String s;
  case({}) then {};
  case(DAE.NAMEMOD(s,DAE.REDECL(_,_))::subs)
    equation
       then removeRedecl(subs);
  case(sm::subs)
    equation
      osubs = removeRedecl(subs);
      then
        sm::osubs;
  end matchcontinue;
end removeRedecl;

public function removeModList "
Author BZ, 2009-07
Delete a list of named modifiers
"
input Mod inMod;
input list<String> remStrings;
output Mod outMod;
String s;
algorithm outMod := matchcontinue(inMod,remStrings)
  case(inMod,{}) then inMod;
  case(inMod, s::remStrings)
    equation
      inMod = removeMod(inMod,s);
      then removeModList(inMod,remStrings);
  end matchcontinue;
end removeModList;

public function removeMod "
Author: BZ, 2009-05
Remove a modifier(/s) on a specified component.
TODO: implement IDXMOD and a better support for redeclare.
"
  input Mod inmod;
  input String componentModified;
  output Mod outmod;
algorithm outmod := matchcontinue(inmod,componentModified)
  local
    Boolean b;
    Absyn.Each e;
    list<SubMod> subs;
    Option<EqMod> oem;
    list<tuple<SCode.Element, Mod>> redecls;
  case(DAE.NOMOD(),_) then DAE.NOMOD();
  case((inmod as DAE.REDECL(b,redecls)),componentModified)
    equation
      redecls = removeRedeclareMods(redecls,componentModified);
      outmod = Util.if_(listLength(redecls) > 0,DAE.REDECL(b,redecls), DAE.NOMOD());
    then
      outmod;

  case(DAE.MOD(b,e,subs,oem),componentModified)
    equation
      subs = removeModInSubs(subs,componentModified);
    then
      DAE.MOD(b,e,subs,oem);
end matchcontinue;
end removeMod;

protected function removeRedeclareMods "
"
input list<tuple<SCode.Element, Mod>> inLst;
input String currComp;
output list<tuple<SCode.Element, Mod>> outLst;
algorithm outLst := matchcontinue(inLst,currComp)
  local
    SCode.Element comp;
    Mod mod;
    String s1;
  case({},_) then {};
  case((comp,mod)::inLst,currComp)
    equation
      outLst = removeRedeclareMods(inLst,currComp);
      s1 = SCode.elementName(comp);
      true = stringEqual(s1,currComp);
    then
      outLst;
  case((comp,mod)::inLst,currComp)
    equation
      outLst = removeRedeclareMods(inLst,currComp);
    then
      (comp,mod)::outLst;
  case(_,_) equation print("removeRedeclareMods failed\n"); then fail();
  end matchcontinue;
end removeRedeclareMods;

protected function removeModInSubs "
Author BZ, 2009-05
Helper function for removeMod, removes modifiers in submods;
"
  input list<SubMod> insubs;
  input String componentName;
  output list<SubMod> outsubs;
algorithm outsubs := matchcontinue(insubs,componentName)
  local
    Mod m1,m2;
    list<SubMod> subs1,subs2;
    String s1;
    SubMod sub;
  case({},_) then {};
  case((sub as DAE.NAMEMOD(s1,m1))::insubs,componentName)
    equation
      subs1 = Util.if_(stringEqual(s1,componentName),{},{DAE.NAMEMOD(s1,m1)});
      subs2 = removeModInSubs(insubs,componentName) "check for multiple mod on same comp";
      outsubs = listAppend(subs1,subs2);
    then
      outsubs;
  case((sub as DAE.IDXMOD(_,m1))::insubs,componentName)
    equation
      //TODO: implement check for idxmod?
      subs2 = removeModInSubs(insubs,componentName);
    then
      sub::subs2;
end matchcontinue;
end removeModInSubs;

public function getDimensionSizes "function: getDimensionSizes

  Return the dimension sizes of a Type.
"
  input Type inType;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inType)
    local
      list<Integer> res;
      DAE.Dimension d;
      Integer i;
      Type tp;
    case ((DAE.T_ARRAY(arrayDim = d,arrayType = tp),_))
      equation
        i = Exp.dimensionSize(d);
        res = getDimensionSizes(tp);
      then
        (i :: res);
    case ((DAE.T_ARRAY(arrayDim = d, arrayType = tp), _))
      equation
        res = getDimensionSizes(tp);
      then
        (-1 :: res);
    case ((DAE.T_COMPLEX(_,_,SOME(tp),_),_))
      then getDimensionSizes(tp);
    case ((_,_))
      equation
        false = arrayType(inType);
      then
        {};
  end matchcontinue;
end getDimensionSizes;

public 
public function getDimensions
"Returns the dimensions of a Type."
  input Type inType;
  output list<DAE.Dimension> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inType)
    local
      list<DAE.Dimension> res;
      DAE.Dimension d;
      Type tp;
    case ((DAE.T_ARRAY(arrayDim = d,arrayType = tp),_))
      equation
        res = getDimensions(tp);
      then
        (d :: res);
    case ((DAE.T_COMPLEX(_,_,SOME(tp),_),_))
      then getDimensions(tp);
    case ((_,_)) then {};
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
    case ((DAE.T_ARRAY(arrayDim = dim), _), 1) then dim;
    case ((DAE.T_ARRAY(arrayType = t), _), d)
      equation
        true = (d > 1);
      then
        getDimensionNth(t, d - 1);
    case ((DAE.T_COMPLEX(complexTypeOption = SOME(t)), _), d)
      then getDimensionNth(t, d);
  end matchcontinue;
end getDimensionNth;

public function printDimensionsStr "Prints dimensions to a string"
  input list<DAE.Dimension> dims;
  output String res;
algorithm
  res:=Util.stringDelimitList(Util.listMap(dims,Exp.dimensionString),", ");
end printDimensionsStr;

public function valuesToMods
"function: valuesToMods
  author: PA

  This function takes a list of values and convert into a Modification.
   Used for record construction evaluation. PersonRecord(\"name\",45) has a value list
  { \"name\",45 } that needs to be converted into a modifier for the record class
   PersonRecord (\"name,45)
   FIXME: How about other value types, e.g. array, enum etc"
  input list<Values.Value> inValuesValueLst;
  input list<Ident> inIdentLst;
  output Mod outMod;
algorithm
  outMod:=
  matchcontinue (inValuesValueLst,inIdentLst)
    local
      list<SubMod> res,arrRes;
      Integer i,len;
      list<Values.Value> rest,vals;
      Ident id,s,cname_str,vs;
      list<Ident> ids,val_names;
      Real r;
      Boolean b;
      DAE.Exp rec_call, exp;
      list<DAE.Exp> exps;
      list<Var> varlst;
      Absyn.Path cname;
      Values.Value v;
      list<Ident> dummyIds;
      Type ty;
      DAE.ComponentRef cref;
      Absyn.Exp absynExp;

    // adrpo: TODO! why not use typeOfValue everywhere here??!!

    case ({},_) then DAE.MOD(false,Absyn.NON_EACH(),{},NONE);

    case ((Values.INTEGER(integer = i) :: rest),(id :: ids))
      equation
        DAE.MOD(_,_,res,_) = valuesToMods(rest, ids);
      then
        DAE.MOD(false,Absyn.NON_EACH(),
          (DAE.NAMEMOD(id,
          DAE.MOD(false,Absyn.NON_EACH(),{},
          SOME(
          DAE.TYPED(DAE.ICONST(i),SOME(Values.INTEGER(i)),
          DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_VAR()),SOME(Absyn.INTEGER(i)))))) :: res),NONE);

    case ((Values.REAL(real = r) :: rest),(id :: ids))
      equation
        DAE.MOD(_,_,res,_) = valuesToMods(rest, ids);
      then
        DAE.MOD(false,Absyn.NON_EACH(),
          (DAE.NAMEMOD(id,
          DAE.MOD(false,Absyn.NON_EACH(),{},
          SOME(
          DAE.TYPED(DAE.RCONST(r),SOME(Values.REAL(r)),
          DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()),SOME(Absyn.REAL(r)))))) :: res),NONE);

    case ((Values.STRING(string = s) :: rest),(id :: ids))
      equation
        DAE.MOD(_,_,res,_) = valuesToMods(rest, ids);
      then
        DAE.MOD(false,Absyn.NON_EACH(),
          (DAE.NAMEMOD(id,
          DAE.MOD(false,Absyn.NON_EACH(),{},
          SOME(
          DAE.TYPED(DAE.SCONST(s),SOME(Values.STRING(s)),
          DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(Absyn.STRING(s)))))) :: res),NONE);

    case ((Values.BOOL(boolean = b) :: rest),(id :: ids))
      equation
        DAE.MOD(_,_,res,_) = valuesToMods(rest, ids);
      then
        DAE.MOD(false,Absyn.NON_EACH(),
          (DAE.NAMEMOD(id,
          DAE.MOD(false,Absyn.NON_EACH(),{},
          SOME(
          DAE.TYPED(DAE.BCONST(b),SOME(Values.BOOL(b)),
          DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(Absyn.BOOL(b)))))) :: res),NONE);
    case (((v as Values.RECORD(index=_)) :: rest),(id :: ids))
      equation
        ty = typeOfValue(v);
        exp = ValuesUtil.valueExp(v);
        DAE.MOD(_,_,res,_) = valuesToMods(rest, ids);
      then
        DAE.MOD(false,Absyn.NON_EACH(),
          (DAE.NAMEMOD(id,
          DAE.MOD(false,Absyn.NON_EACH(),{},
          SOME(DAE.TYPED(exp,SOME(v),DAE.PROP(ty,DAE.C_VAR()),NONE())))) :: res),NONE);

    case ((v as Values.ENUM_LITERAL(index = _)) :: rest,(id :: ids))
      equation
        ty = typeOfValue(v);
        exp = ValuesUtil.valueExp(v);
        DAE.MOD(_,_,res,_) = valuesToMods(rest, ids);
      then
        DAE.MOD(false,Absyn.NON_EACH(),
          (DAE.NAMEMOD(id,
          DAE.MOD(false,Absyn.NON_EACH(),{},
          SOME(
          DAE.TYPED(exp,SOME(v),
          DAE.PROP(ty,DAE.C_CONST()),NONE())))) :: res),NONE);

    case ((v as Values.ARRAY(valueLst = vals)) :: rest,(id :: ids))
      equation
        exp = ValuesUtil.valueExp(v);
        ty = typeOfValue(v);
        DAE.MOD(_,_,res,_) = valuesToMods(rest, ids);
      then
        DAE.MOD(false,Absyn.NON_EACH(),
          (DAE.NAMEMOD(id,DAE.MOD(false,Absyn.NON_EACH(),{},
                   SOME(DAE.TYPED(exp, SOME(v),DAE.PROP(ty,DAE.C_CONST()),NONE())))) :: res),NONE);

    case ((v :: _),_)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "Types.valuesToMods failed for value: ");
        vs = ValuesUtil.valString(v);
        Debug.fprint("failtrace", vs);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end valuesToMods;

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
      Ident id;
      list<Ident> ids;

    case ({},{}) then {}; 
    case ((v :: vs),(id :: ids))
      equation
        tp = typeOfValue(v);
        rest = valuesToVars(vs, ids);
      then
        (DAE.TYPES_VAR(id,DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
                       false,tp,DAE.UNBOUND(),
                       NONE()) :: rest);
    case (_,_)
      equation
        Debug.fprint("failtrace", "-values_to_vars failed\n");
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
      Integer dim1;
      Values.Value w,v;
      list<Values.Value> vs,vl;
      list<Type> ts;
      list<Var> vars;
      Ident cname_str;
      Absyn.Path cname;
      list<Ident> ids;

    case (Values.INTEGER(integer = _)) then (DAE.T_INTEGER_DEFAULT); 
    case (Values.REAL(real = _)) then (DAE.T_REAL_DEFAULT); 
    case (Values.STRING(string = _)) then (DAE.T_STRING_DEFAULT); 
    case (Values.BOOL(boolean = _)) then (DAE.T_BOOL_DEFAULT); 
    case (Values.ENUM_LITERAL(name = path, index = index))
      local
        Integer index;
        Absyn.Path path;
      equation
        path = Absyn.pathPrefix(path); 
      then
        ((DAE.T_ENUMERATION(SOME(index), path, {}, {}, {}), NONE));
    case ((w as Values.ARRAY(valueLst = (v :: vs))))
      equation
        tp = typeOfValue(v);
        dim1 = listLength((v :: vs));
      then
        ((DAE.T_ARRAY(DAE.DIM_INTEGER(dim1),tp),NONE));
    case ((w as Values.ARRAY(valueLst = ({}))))
      equation
      then
        ((DAE.T_ARRAY(DAE.DIM_INTEGER(0),(DAE.T_NOTYPE(),NONE)),NONE));
    case ((w as Values.TUPLE(valueLst = vs)))
      equation
        ts = Util.listMap(vs, typeOfValue);
      then
        ((DAE.T_TUPLE(ts),NONE));
    case Values.RECORD(record_ = cname,orderd = vl,comp = ids, index = -1)
      equation
        vars = valuesToVars(vl, ids);
      then
        ((DAE.T_COMPLEX(ClassInf.RECORD(cname),vars,NONE,NONE),SOME(cname)));

      // MetaModelica Uniontype
    case Values.RECORD(record_ = cname,orderd = vl,comp = ids, index = index)
      local Integer index; String ident;
      equation
        true = index >= 0;
        vars = valuesToVars(vl, ids);
      then
        ((DAE.T_METARECORD(index, vars),SOME(cname)));

        // MetaModelica list type
    case Values.LIST(vl)
      local
        list<DAE.Exp> explist;
      equation
        explist = Util.listMap(vl, ValuesUtil.valueExp);
        ts = Util.listMap(vl, typeOfValue);
        (_,tp,_) = listMatchSuperType(explist, ts, {}, matchTypeRegular, true);
      then
        ((DAE.T_LIST(tp),NONE));

    case Values.OPTION(NONE)
      equation
        tp = (DAE.T_METAOPTION((DAE.T_NOTYPE,NONE)),NONE);
      then tp;
    case Values.OPTION(SOME(v))
      equation
        tp = typeOfValue(v);
        tp = (DAE.T_METAOPTION(tp),NONE);
      then tp;
    case Values.META_TUPLE(valueLst = vs)
      equation
        ts = Util.listMap(vs, typeOfValue);
      then
        ((DAE.T_METATUPLE(ts),NONE));

    case (v)
      local Ident vs;
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- Types.typeOfValue failed: ");
        vs = ValuesUtil.valString(v);
        Debug.fprintln("failtrace", vs);
      then
        fail();
  end matchcontinue;
end typeOfValue;

public function basicType "function: basicType

  Test whether a type is one of the builtin types.
"
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inType)
    case ((DAE.T_INTEGER(varLstInt = _),_)) then true;
    case ((DAE.T_REAL(varLstReal = _),_)) then true;
    case ((DAE.T_STRING(varLstString = _),_)) then true;
    case ((DAE.T_BOOL(varLstBool = _),_)) then true;
    case ((DAE.T_ENUMERATION(index = _),_)) then true;
    case ((DAE.T_ARRAY(arrayDim = _),_)) then false;
    case ((DAE.T_COMPLEX(complexClassType = _),_)) then false;
    case ((DAE.T_LIST(_),_)) then false;  // MetaModelica list type
    case ((DAE.T_METAOPTION(_),_)) then false;  // MetaModelica option type
    case ((DAE.T_METATUPLE(_),_)) then false;  // MetaModelica tuple type
  end matchcontinue;
end basicType;

public function extendsBasicType "function: basicType
  Test whether a type extends one of the builtin types."
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inType)
    case ((DAE.T_COMPLEX(complexTypeOption=SOME(_)),_)) then true;
    case (_) then false;
  end matchcontinue;
end extendsBasicType;

public function arrayType "function: arrayType
  Test whether a type is an array type."
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inType)
    case ((DAE.T_ARRAY(arrayDim = _),_)) then true;
    case (_) then false;
  end matchcontinue;
end arrayType;

public function setVarInput "Sets a DAE.Var to input"
  input Var v;
  output Var outV;
algorithm
  outV := matchcontinue(v)
  local Ident name;
    Boolean f,p,streamPrefix;
    Type tp;
    Binding bind;
    SCode.Accessibility a;
    SCode.Variability v;
    Absyn.InnerOuter io;
    Option<DAE.Const> cnstForRange;
    
    case DAE.TYPES_VAR(name,DAE.ATTR(f,streamPrefix,a,v,_,io),p,tp,bind,cnstForRange)
    then DAE.TYPES_VAR(name,DAE.ATTR(f,streamPrefix,a,v,Absyn.INPUT(),io),p,tp,bind,cnstForRange);

  end matchcontinue;
end setVarInput;

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
  are subtypes of each other.
"
  input Type inType1;
  input Type inType2;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inType1,inType2)
    local Type t1,t2;
    case (t1,t2)
      equation
        true = subtype(t1, t2);
        true = subtype(t2, t1);
      then
        true;
    case (t1,t2) then false;  /* default */
  end matchcontinue;
end equivtypes;

public function subtype "function: subtype
  Is the first type a subtype of the second type?  
  This function specifies the rules for subtyping in Modelica."
  input Type inType1;
  input Type inType2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inType1,inType2)
    local
      Boolean res;
      Ident l1,l2;
      list<Var> vl1,vl2,els1,els2;
      Option<Absyn.Path> op1,op2;
      Absyn.Path p1,p2;
      Type t1,t2,tp,tp2,tp1;
      Integer i1,i2;
      ClassInf.State st1,st2;
      Option<Type> bc1,bc2;
      list<Type> type_list1,type_list2;
    
    case ((DAE.T_ANYTYPE(_),_),(_,_)) then true;
    case ((_,_),(DAE.T_ANYTYPE(_),_)) then true;
    case ((DAE.T_INTEGER(varLstInt = _),_),(DAE.T_INTEGER(varLstInt = _),_)) then true;
    case ((DAE.T_REAL(varLstReal = _),_),(DAE.T_REAL(varLstReal = _),_)) then true;
    case ((DAE.T_STRING(varLstString = _),_),(DAE.T_STRING(varLstString = _),_)) then true;
    case ((DAE.T_BOOL(varLstBool = _),_),(DAE.T_BOOL(varLstBool = _),_)) then true;
    
    case ((DAE.T_ENUMERATION(names = {}),_),(DAE.T_ENUMERATION(names = _),_)) then true;
    case ((DAE.T_ENUMERATION(names = _),_),(DAE.T_ENUMERATION(names = {}),_)) then true;
      
    case ((DAE.T_ENUMERATION(names = names1),_),
          (DAE.T_ENUMERATION(names = names2),_))
      local
        list<String> names1, names2;
      equation
        res = Util.isPrefixListComp(names1, names2, stringEqual);
      then
        res;
    
    case ((DAE.T_ARRAY(arrayType = t1),_),(DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN,arrayType = t2),_))
      equation
        true = subtype(t1, t2);
      then
        true;
    
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN,arrayType = t1),_),(DAE.T_ARRAY(arrayType = t2),_))
      equation
        true = subtype(t1, t2);
      then
        true;
        
    case ((DAE.T_ARRAY(arrayType = t1), _), (DAE.T_ARRAY(arrayDim = DAE.DIM_EXP(exp = _), arrayType = t2), _))
      equation
        true = OptManager.getOption("checkModel");
        true = subtype(t1, t2);
      then
        true;
        
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM_EXP(exp = _), arrayType = t1), _), (DAE.T_ARRAY(arrayType = t2), _))
      equation
        true = OptManager.getOption("checkModel");
        true = subtype(t1, t2);
      then
        true;
    
    // Array
    case ((DAE.T_ARRAY(arrayDim = dim1,arrayType = t1),_),(DAE.T_ARRAY(arrayDim = dim2,arrayType = t2),_))
      local DAE.Dimension dim1, dim2;
      equation
        true = Exp.dimensionsKnownAndEqual(dim1, dim2);
        true = subtype(t1, t2);
      then
        true;
        
    // Complex type
    case ((DAE.T_COMPLEX(complexClassType = st1,complexVarLst = els1,complexTypeOption = bc1),_),(DAE.T_COMPLEX(complexClassType = st2,complexVarLst = els2,complexTypeOption = bc2),_))
      equation
        true = subtypeVarlist(els1, els2);
      then
        true;
    
    // A complex type that extends a basic type is checked against the baseclass basic type         
    case ((DAE.T_COMPLEX(complexClassType = st1,complexVarLst = els1,complexTypeOption = SOME(tp)),_),tp2) 
      equation 
        res = subtype(tp, tp2);
      then
        res;
    
    // A complex type that extends a basic type is checked against the baseclass basic type         
    case (tp1,(DAE.T_COMPLEX(complexClassType = st1,complexVarLst = els1,complexTypeOption = SOME(tp2)),_)) 
      equation 
        res = subtype(tp1, tp2);
      then
        res;
    
    // Check of tuples, similar to complex. Just that identifier name do not have to be checked. Only types are checked. 
    case ((DAE.T_TUPLE(tupleType = type_list1),_),(DAE.T_TUPLE(tupleType = type_list2),_)) 
      equation 
        true = subtypeTypelist(type_list1, type_list2);
      then
        true;
    
    // Part of MetaModelica extension. KS
    case ((DAE.T_LIST((DAE.T_NOTYPE(),_)),_),(DAE.T_LIST(_),_)) then true; // The empty list is represented with NO_TYPE()
    case ((DAE.T_LIST(_),_),(DAE.T_LIST((DAE.T_NOTYPE(),_)),_)) then true;
    case ((DAE.T_LIST(t1),_),(DAE.T_LIST(t2),_)) then subtype(t1,t2);
    case ((DAE.T_META_ARRAY(t1),_),(DAE.T_META_ARRAY(t2),_)) then subtype(t1,t2);
    case ((DAE.T_METATUPLE(tList1),_),(DAE.T_METATUPLE(tList2),_))
      local list<Type> tList1,tList2; Boolean ret; 
      equation
        ret = subtypeTypelist(tList1,tList2);
      then ret;
    case ((DAE.T_METAOPTION((DAE.T_NOTYPE(),_)),_),(DAE.T_METAOPTION(_),_)) then true;
    case ((DAE.T_METAOPTION(t1),_),(DAE.T_METAOPTION(t2),_))
      equation
        failure((DAE.T_NOTYPE(),_) = t2);
      then subtype(t1,t2);
    
    case ((DAE.T_BOXED(t1),_),(DAE.T_BOXED(t2),_)) then subtype(t1,t2);
    case ((DAE.T_BOXED(t1),_),t2) equation true = isBoxedType(t2); then subtype(t1,t2);
    case (t1,(DAE.T_BOXED(t2),_)) equation true = isBoxedType(t1); then subtype(t1,t2);
    
    case ((DAE.T_POLYMORPHIC(l1),_),(DAE.T_POLYMORPHIC(l2),_)) then l1 ==& l2;
    case ((DAE.T_NOTYPE(),_),_) then true;
    case (_,(DAE.T_NOTYPE(),_)) then true;
    case ((DAE.T_NORETCALL(),_),(DAE.T_NORETCALL(),_)) then true;
    
    // MM Function Reference. sjoelund
    case ((DAE.T_FUNCTION(farg1,t1,_),_),(DAE.T_FUNCTION(farg2,t2,_),_))
      local list<FuncArg> farg1,farg2; list<Type> tList1,tList2;
      equation
        tList1 = Util.listMap(farg1, Util.tuple22);
        tList2 = Util.listMap(farg2, Util.tuple22);
        true = subtypeTypelist(tList1,tList2);
        true = subtype(t1,t2);
      then true;
    
    case(t1 as (DAE.T_METARECORD(_,_),_), t2 as (DAE.T_METARECORD(_,_),_))
      equation
        equality(t1 = t2);
      then true;
    
    // <uniontype> = <uniontype>
    case((DAE.T_UNIONTYPE(_),SOME(p1)),(DAE.T_UNIONTYPE(_),SOME(p2)))
      then Absyn.pathEqual(p1,p2);
    case((DAE.T_UNIONTYPE(_),SOME(p1)),(DAE.T_COMPLEX(complexClassType=ClassInf.UNIONTYPE(_)),SOME(p2)))
      then Absyn.pathEqual(p1,p2);
    case((DAE.T_UNIONTYPE(_),SOME(p1)),(DAE.T_COMPLEX(complexClassType=ClassInf.UNIONTYPE(_)),SOME(p2)))
      then Absyn.pathEqual(p1,p2);

    case (t1,t2)
      equation
        /* Uncomment for debugging
        l1 = unparseType(t1);
        l2 = unparseType(t2);
        l1 = Util.stringAppendList({"- Types.subtype failed:\n  t1=",l1,"\n  t2=",l2});
        Debug.fprintln("failtrace", l1);
        */
      then false;
  end matchcontinue;
end subtype;

protected function subtypeTypelist "PR. function: subtypeTypelist
  This function checks if the both Type lists matches types, element by element."
  input list<Type> inTypeLst1;
  input list<Type> inTypeLst2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inTypeLst1,inTypeLst2)
    local
      Type t1,t2;
      list<Type> rest1,rest2;
    
    case ({},{}) then true;
    case ((t1 :: rest1),(t2 :: rest2))
      equation
        true = subtype(t1, t2);
        true = subtypeTypelist(rest1, rest2);
      then
        true;
    case (_,_) then false;  /* default */
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
    
    case (l,(DAE.TYPES_VAR(name = n,type_ = t2) :: vs))
      equation
        DAE.TYPES_VAR(_,_,_,t1,_,_) = varlistLookup(l, n);
        true = subtype(t1, t2);
        true = subtypeVarlist(l, vs);
      then
        true;
    
    case (_,_) then false;  /* default */ 
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
        true = stringEqual(n, name);
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
      Boolean prot;
      Binding bnd;
      DAE.Dimension dim;
      Option<DAE.Const> cnstForRange;      
    
    case (t,n)
      equation
        true = basicType(t);
        v = lookupInBuiltin(t, n);
      then
        v;
    
    case ((DAE.T_COMPLEX(complexClassType = st,complexVarLst = cs,complexTypeOption = bc),_),id)
      equation
        v = lookupComponent2(cs, id);
      then
        v;
    
    case ((DAE.T_ARRAY(arrayDim = dim,arrayType = (DAE.T_COMPLEX(complexClassType = st,complexVarLst = cs,complexTypeOption = bc),_)),_),id)
      equation
        DAE.TYPES_VAR(n,attr,prot,ty,bnd,cnstForRange) = lookupComponent2(cs, id);
        ty_1 = (DAE.T_ARRAY(dim,ty),NONE);
      then
        DAE.TYPES_VAR(n,attr,prot,ty_1,bnd,cnstForRange);
    
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

    case ((DAE.T_REAL(varLstReal = cs),_),id) /* Real */ 
      equation 
        v = lookupComponent2(cs, id);
      then
        v;

    case ((DAE.T_INTEGER(varLstInt = cs),_),id)
      equation
        v = lookupComponent2(cs, id);
      then
        v;

    case ((DAE.T_STRING(varLstString = cs),_),id)
      equation
        v = lookupComponent2(cs, id);
      then
        v;

    case ((DAE.T_BOOL(varLstBool = cs),_),id)
      equation
        v = lookupComponent2(cs, id);
      then
        v;

   case ((DAE.T_ENUMERATION(index = SOME(_)),_),"quantity") 
     then DAE.TYPES_VAR("quantity",
          DAE.ATTR(false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
          false,DAE.T_STRING_DEFAULT,DAE.VALBOUND(Values.STRING(""),DAE.BINDING_FROM_DEFAULT_VALUE()),NONE());  

    // Should be bound to the first element of DAE.T_ENUMERATION list higher up in the call chain
    case ((DAE.T_ENUMERATION(index = SOME(_)),_),"min")       
      then DAE.TYPES_VAR("min",DAE.ATTR(false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
          false,(DAE.T_ENUMERATION(SOME(1),Absyn.IDENT(""),{"min,max"},{},{}),NONE),DAE.UNBOUND(),NONE());   

    // Should be bound to the last element of DAE.T_ENUMERATION list higher up in the call chain 
    case ((DAE.T_ENUMERATION(index = SOME(_)),_),"max") 
      then DAE.TYPES_VAR("max",DAE.ATTR(false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
          false,(DAE.T_ENUMERATION(SOME(2),Absyn.IDENT(""),{"min,max"},{},{}),NONE),DAE.UNBOUND(),NONE());  

    // Should be bound to the last element of DAE.T_ENUMERATION list higher up in the call chain 
    case ((DAE.T_ENUMERATION(index = SOME(_)),_),"start") 
      then DAE.TYPES_VAR("start",DAE.ATTR(false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
          false,DAE.T_BOOL_DEFAULT,DAE.UNBOUND(),NONE());   

    // Needs to be set to true/false higher up the call chain depending on variability of instance 
    case ((DAE.T_ENUMERATION(index = SOME(_)),_),"fixed") 
      then DAE.TYPES_VAR("fixed",DAE.ATTR(false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
          false,DAE.T_BOOL_DEFAULT,DAE.UNBOUND(),NONE());  
    case ((DAE.T_ENUMERATION(index = SOME(_)),_),"enable") then DAE.TYPES_VAR("enable",
          DAE.ATTR(false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
          false,DAE.T_BOOL_DEFAULT,DAE.VALBOUND(Values.BOOL(true),DAE.BINDING_FROM_DEFAULT_VALUE()),NONE()); 
        
//    case ((DAE.T_ENUM(),_),"quantity") then DAE.TYPES_VAR("quantity",
//          DAE.ATTR(false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_STRING_DEFAULT,DAE.VALBOUND(Values.STRING("")));

//    case ((DAE.T_ENUM(),_),"min") then DAE.TYPES_VAR("min",DAE.ATTR(false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
//          false,(DAE.T_ENUM(),NONE),DAE.UNBOUND(),NONE());  /* Should be bound to the first element of
//  DAE.T_ENUMERATION list higher up in the call chain */
//    case ((DAE.T_ENUM(),_),"max") then DAE.TYPES_VAR("max",DAE.ATTR(false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
//          false,(DAE.T_ENUM(),NONE),DAE.UNBOUND(),NONE());  /* Should be bound to the last element of 
//  DAE.T_ENUMERATION list higher up in the call chain */ 
//    case ((DAE.T_ENUM(),_),"start") then DAE.TYPES_VAR("start",DAE.ATTR(false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
//          false,DAE.T_BOOL_DEFAULT,DAE.UNBOUND(),NONE());  /* Should be bound to the last element of 
//  DAE.T_ENUMERATION list higher up in the call chain */ 
//    case ((DAE.T_ENUM(),_),"fixed") then DAE.TYPES_VAR("fixed",DAE.ATTR(false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
//          false,DAE.T_BOOL_DEFAULT,DAE.UNBOUND(),NONE());  /* Needs to be set to true/false higher up the call chain
//  depending on variability of instance */
//    case ((DAE.T_ENUM(),_),"enable") then DAE.TYPES_VAR("enable",
//          DAE.ATTR(false,false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_BOOL_DEFAULT,DAE.VALBOUND(Values.BOOL(true)));
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
        true = stringEqual(n, m);
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
        ((DAE.T_ARRAY(DAE.DIM_INTEGER(len),t),NONE));
  end matchcontinue;
end makeArray;

public function makeArraySubscripts "function: makeArray
   This function makes an array type given a Type and a list of DAE.Subscript
"
  input Type inType;
  input list<DAE.Subscript> lst;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inType,lst)
    local
      Type t;
      Integer i;
      DAE.Exp e;
    case (t,{}) then t;
    case (t,DAE.WHOLEDIM::lst)
      equation
        t = makeArraySubscripts((DAE.T_ARRAY(DAE.DIM_UNKNOWN,t),NONE),lst);
      then
        t;
    case (t,DAE.SLICE(e)::lst)
      equation
        t = makeArraySubscripts((DAE.T_ARRAY(DAE.DIM_UNKNOWN,t),NONE),lst);
      then
        t;

    case (t,DAE.INDEX(DAE.ICONST(i))::lst)
      equation
        t = makeArraySubscripts((DAE.T_ARRAY(DAE.DIM_INTEGER(i),t),NONE),lst);
      then
        t;
     case (t,DAE.INDEX(_)::lst)
      equation
        t = makeArraySubscripts((DAE.T_ARRAY(DAE.DIM_UNKNOWN,t),NONE),lst);
      then
        t;
  end matchcontinue;
end makeArraySubscripts;

public function liftArray "function: liftArray

  This function turns a type into an array of that type.  If the
  type already is an array, another dimension is simply added.
"
  input Type inType;
  input DAE.Dimension inDimension;
  output Type outType;
algorithm
  outType := (DAE.T_ARRAY(inDimension, inType), NONE);
end liftArray;

public function liftArrayListDims "
  This function turns a type into an array of that type.
"
  input Type inType;
  input list<DAE.Dimension> inDimensionLst;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inType,inDimensionLst)
    local
      Type ty;
      DAE.Dimension d;
      list<DAE.Dimension> rest;
    case (ty,{}) then ty;
    case (ty,d::rest) then liftArray(liftArrayListDims(ty,rest),d);
  end matchcontinue;
end liftArrayListDims;

public function liftArrayRight "function: liftArrayRight

  This function adds an array dimension to \"the right\" of the passed type.
"
  input Type inType;
  input DAE.Dimension inIntegerOption;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inType,inIntegerOption)
    local
      Type ty_1,ty;
      DAE.Dimension dim;
      Option<Absyn.Path> path;
      DAE.Dimension d;
      ClassInf.State ci;
      list<Var> varlst;
      EqualityConstraint ec;
    case ((DAE.T_ARRAY(arrayDim = dim,arrayType = ty),path),d)
      equation
        ty_1 = liftArrayRight(ty, d);
      then
        ((DAE.T_ARRAY(dim,ty_1),path));
    case((DAE.T_COMPLEX(ci,varlst,SOME(ty),ec),path),d)
      equation
        ty_1 = liftArrayRight(ty,d);
        then ((DAE.T_COMPLEX(ci,varlst,SOME(ty_1),ec),path));
    case ((ty,path),d)
      local TType ty;
      then
        ((DAE.T_ARRAY(d,(ty,NONE)),path));
  end matchcontinue;
end liftArrayRight;

public function unliftArray "function: unliftArray

  This function turns an array of a type into that type.
"
  input Type inType;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inType)
    local Type ty;
    case ((DAE.T_ARRAY(arrayType = ty),_)) then ty;
    case ((DAE.T_COMPLEX(_,_,SOME(ty),_),_)) then unliftArray(ty);
    /* adrpo: handle also functions returning arrays! */
    case ((DAE.T_FUNCTION(_,ty,_),_)) then unliftArray(ty);
  end matchcontinue;
end unliftArray;

protected function typeArraydim "function: typeArraydim

  If type is an array, return it array dimension
"
  input Type inType;
  output DAE.Dimension outArrayDim;
algorithm
  outArrayDim:=
  matchcontinue (inType)
    local DAE.Dimension dim;
    case ((DAE.T_ARRAY(arrayDim = dim),_)) then dim;
  end matchcontinue;
end typeArraydim;

public function arrayElementType "function: arrayElementType

  This function turns an array into the element type
  of the array.
"
  input Type inType;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inType)
    local Type ty_1,ty,t;
    case ((DAE.T_ARRAY(arrayType = ty),_))
      equation
        ty_1 = arrayElementType(ty);
      then
        ty_1;
    case t then t;
  end matchcontinue;
end arrayElementType;

public function unparseEqMod
"prints eqmod to a string"
  input EqMod eq;
  output String str;
algorithm
  str := matchcontinue(eq)
  local DAE.Exp e; Absyn.Exp e2;
    case(DAE.TYPED(e,_,_,_)) equation
      str =Exp.printExpStr(e);
    then str;
    case(DAE.UNTYPED(e2)) equation
      str = Dump.printExpStr(e2);
    then str;
  end matchcontinue;
end unparseEqMod;

public function unparseOptionEqMod
"prints eqmod to a string"
  input Option<EqMod> eq;
  output String str;
algorithm
  str := matchcontinue(eq)
    local EqMod e;
    case NONE() then "NONE()";
    case SOME(e) then unparseEqMod(e);
  end matchcontinue;
end unparseOptionEqMod;

public function unparseType
"function: unparseType
  This function prints a Modelica type as a piece of Modelica code."
  input Type inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inType)
    local
      Ident s1,s2,str,tys,dims,res,vstr,name,st_str,bc_tp_str,paramstr,restypestr,tystr;
      list<Ident> l,vars,paramstrs,tystrs;
      Type ty,t,bc_tp,restype;
      list<DAE.Dimension> dimlst;
      list<Var> vs;
      Option<Type> bc;
      ClassInf.State ci_state;
      list<FuncArg> params;

    case ((DAE.T_INTEGER(varLstInt = {}),_)) then "Integer";
    case ((DAE.T_REAL(varLstReal = {}),_)) then "Real";
    case ((DAE.T_STRING(varLstString = {}),_)) then "String";
    case ((DAE.T_BOOL(varLstBool = {}),_)) then "Boolean";

    case ((DAE.T_INTEGER(varLstInt = vs),_)) 
      equation
        s1 = Util.stringDelimitList(Util.listMap(vs, unparseVarAttr),", ");
        s2 = "Integer(" +& s1 +& ")";
      then s2;
    case ((DAE.T_REAL(varLstReal = vs),_)) 
      equation
        s1 = Util.stringDelimitList(Util.listMap(vs, unparseVarAttr),", ");
        s2 = "Real(" +& s1 +& ")";
      then s2;
    case ((DAE.T_STRING(varLstString = vs),_)) 
      equation
        s1 = Util.stringDelimitList(Util.listMap(vs, unparseVarAttr),", ");
        s2 = "String(" +& s1 +& ")";
      then s2;
    case ((DAE.T_BOOL(varLstBool = vs),_)) 
      equation
        s1 = Util.stringDelimitList(Util.listMap(vs, unparseVarAttr),", ");
        s2 = "Boolean(" +& s1 +& ")";
      then s2;
    case ((DAE.T_ENUMERATION(names = l, literalVarLst=vs),_))
      local String s2;
      equation
        s1 = Util.stringDelimitList(l, ", ");
        s2 = Util.stringAppendList(Util.listMap(vs, unparseVar));
        s2 = Util.if_(s2 ==& "", "", "(" +& s2 +& ")");
        str = Util.stringAppendList({"enumeration(",s1,")"});
      then
        str;
    case ((t as (DAE.T_ARRAY(arrayDim = _),_)))
      equation
        (ty,dimlst) = flattenArrayTypeOpt(t);
        tys = unparseType(ty);
        dims = printDimensionsStr(dimlst);
        res = Util.stringAppendList({tys,"[",dims,"]"});
      then
        res;
    case (((t as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_),complexVarLst = vs,complexTypeOption = bc)),SOME(path)))
      local TType t; Absyn.Path path;
      equation
        name = Absyn.pathString(path);
        vars = Util.listMap(vs, unparseVar);
        vstr = Util.stringAppendList(vars);
        res = Util.stringAppendList({"record ",name,"\n",vstr,"end ", name, ";"});
      then
        res;
    case ((DAE.T_COMPLEX(complexClassType = ci_state,complexVarLst = vs,complexTypeOption = SOME(bc_tp)),_))
      equation
        res = Absyn.pathString(ClassInf.getStateName(ci_state));
        st_str = ClassInf.printStateStr(ci_state);
        bc_tp_str = unparseType(bc_tp);
        res = Util.stringAppendList({"(",res," ",st_str," bc:",bc_tp_str,")"});
      then
        res;
    case ((DAE.T_COMPLEX(complexClassType = ci_state,complexVarLst = vs,complexTypeOption = NONE),_))
      equation
        res = Absyn.pathString(ClassInf.getStateName(ci_state));
        st_str = ClassInf.printStateStr(ci_state);
        res = Util.stringAppendList({res," ",st_str});
      then
        res;
    case ((DAE.T_FUNCTION(funcArg = params,funcResultType = restype),_))
      equation
        paramstrs = Util.listMap(params, unparseParam);
        paramstr = Util.stringDelimitList(paramstrs, ", ");
        restypestr = unparseType(restype);
        res = Util.stringAppendList({"function(",paramstr,") => ",restypestr});
      then
        res;
    case ((DAE.T_TUPLE(tupleType = tys),_))
      local list<Type> tys;
      equation
        tystrs = Util.listMap(tys, unparseType);
        tystr = Util.stringDelimitList(tystrs, ", ");
        res = Util.stringAppendList({"(",tystr,")"});
      then
        res;

      /* MetaModelica tuple */
    case ((DAE.T_METATUPLE(types = tys),_))
      local list<Type> tys;
      equation
        res = unparseType((DAE.T_TUPLE(tys),NONE));
      then
        res;

        /* MetaModelica list */
    case ((DAE.T_LIST(listType = ty),_))
      equation
        tystr = unparseType(ty);
        res = Util.stringAppendList({"list<",tystr,">"});
      then
        res;

    case ((DAE.T_META_ARRAY(ty),_))
      equation
        tystr = unparseType(ty);
        res = Util.stringAppendList({"array<",tystr,">"});
      then
        res;

        /* MetaModelica list */
    case ((DAE.T_POLYMORPHIC(tystr),_))
      equation
        res = Util.stringAppendList({"polymorphic<",tystr,">"});
      then
        res;

        /* MetaModelica uniontype */
    case ((DAE.T_UNIONTYPE(_),SOME(p)))
      local Absyn.Path p;
      equation
        str = Absyn.pathString(p);
        res = Util.stringAppendList({"#uniontype ",str,"#"});
      then
        res;

        /* MetaModelica uniontype (but we know which record in the UT it is) */
    case ((DAE.T_METARECORD(_,vs),SOME(p)))
      local Absyn.Path p;
      equation
        str = Absyn.pathString(p);
        vars = Util.listMap(vs, unparseVar);
        vstr = Util.stringAppendList(vars);
        res = Util.stringAppendList({"metarecord ",str,"\n",vstr,"end ", str, ";"});
      then res;

        /* MetaModelica boxed type */
    case ((DAE.T_BOXED(ty),_))
      equation
        res = unparseType(ty);
        res = Util.stringAppendList({"#boxed(",res,")#"});
      then
        res;

        /* MetaModelica Option type */
    case ((DAE.T_METAOPTION((DAE.T_NOTYPE(),_)),_)) then "Option<Any>";
    case ((DAE.T_METAOPTION(ty),_))
      equation
        tystr = unparseType(ty);
        res = Util.stringAppendList({"Option<",tystr,">"});
      then
        res;

    case ((DAE.T_NORETCALL(),_)) then "#NORETCALL#";
    case ((DAE.T_NOTYPE(),_)) then "#NOTYPE#";
    case ((DAE.T_ANYTYPE(anyClassType = _),_)) then "#ANYTYPE#";
//    case ((DAE.T_ENUM(),_)) then "#DAE.T_ENUM#";
    case (ty) then "Internal error Types.unparseType: not implemented yet\n";
  end matchcontinue;
end unparseType;

public function unparseConst "function: unparseConst

  This function prints a Const as a string.
"
  input Const inConst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inConst)
    case DAE.C_CONST() then "C_CONST";
    case DAE.C_PARAM() then "C_PARAM";
    case DAE.C_VAR() then "C_VAR";
  end matchcontinue;
end unparseConst;

public function unparseTupleconst "function: unparseTupleconst

  This function prints a Modelica TupleConst as a string.
"
  input TupleConst inTupleConst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inTupleConst)
    local
      Ident cstr,res,res_1;
      Const c;
      list<Ident> strlist;
      list<TupleConst> constlist;
    case DAE.SINGLE_CONST(const = c)
      equation
        cstr = unparseConst(c);
      then
        cstr;
    case DAE.TUPLE_CONST(tupleConstLst = constlist)
      equation
        strlist = Util.listMap(constlist, unparseTupleconst);
        res = Util.stringDelimitList(strlist, ", ");
        res_1 = Util.stringAppendList({"(",res,")"});
      then
        res_1;
  end matchcontinue;
end unparseTupleconst;

public function printTypeStr "function: printType

  This function prints a textual description of a Modelica type to a string.  If
  the type is not one of the primitive types, it simply prints
  `composite\'.
"
  input Type inType;
  output String str;
algorithm
  str :=
  matchcontinue (inType)
    local
      list<Var> vars;
      list<Ident> l;
      ClassInf.State st;
      Option<Type> bc;
      DAE.Dimension dim;
      Type t,restype;
      list<FuncArg> params;
      list<Type> tys;
      String s1,s2;
    case ((DAE.T_INTEGER(varLstInt = vars),_))
      equation
        s1 = Util.stringDelimitList(Util.listMap(vars, printVarStr),", ");
        str = Util.stringAppendList({"Integer(",s1,")"});
      then
        str;
    case ((DAE.T_REAL(varLstReal = vars),_))
      equation
        s1 = Util.stringDelimitList(Util.listMap(vars, printVarStr),", ");
        str = Util.stringAppendList({"Real(",s1,")"});
      then
        str;
    case ((DAE.T_STRING(varLstString = vars),_))
      equation
      s1 = Util.stringDelimitList(Util.listMap(vars, printVarStr),", ");
      str = Util.stringAppendList({"String(",s1,")"});
      then
        str;
    case ((DAE.T_BOOL(varLstBool = vars),_))
      equation
        s1 = Util.stringDelimitList(Util.listMap(vars, printVarStr),", ");
        str = Util.stringAppendList({"Boolean(",s1,")"});
      then
       str;
    case ((DAE.T_ENUMERATION(names = l, literalVarLst = vars),_))
      equation
       s1 = Util.stringDelimitList(Util.listMap(vars, printVarStr),", ");
       str = Util.stringAppendList({"Enumeration(",s1,")"});
      then
        str;
    case ((DAE.T_COMPLEX(complexClassType = st,complexVarLst = vars,complexTypeOption = bc),_))
      local String compType;
      equation
        compType = Util.stringDelimitList( Util.listMap(Util.genericOption(bc),printTypeStr), ", ");
       s1 = Util.stringDelimitList(Util.listMap(vars, printVarStr),", ");
       compType = Util.if_(stringLength(compType)>0, "::derived From::" +& compType,"");
       str = Util.stringAppendList({"composite(",s1,") ", compType});
      then
        str;
    case ((DAE.T_ARRAY(arrayDim = dim,arrayType = t),_))
      equation
        s1 = Exp.dimensionString(dim);
        s2 = printTypeStr(t);
        str = Util.stringAppendList({"array[", s1,", of type ",s2,"]"});
      then
        str;
    case ((DAE.T_FUNCTION(funcArg = params,funcResultType = restype),_))
      equation
        s1 = printParamsStr(params);
        s2 = printTypeStr(restype);
        str = Util.stringAppendList({"function(", s1,") => ",s2});
      then
        str;
    case ((DAE.T_TUPLE(tupleType = tys),_))
      equation
        s1 = Util.stringDelimitList(Util.listMap(tys, printTypeStr),", ");
         str = Util.stringAppendList({"(",s1,")"});        
      then
        str;

        /* MetaModelica tuple */
    case ((DAE.T_METATUPLE(types = tys),_))
      equation
        str = printTypeStr((DAE.T_TUPLE(tys),NONE));
      then
        str;
        /* MetaModelica list */
    case ((DAE.T_LIST(listType = ty),_))
      local Type ty;
      equation
        s1 = printTypeStr(ty);
         str = Util.stringAppendList({"list<",s1,">"});
      then
        str;

        /* MetaModelica Option */
    case ((DAE.T_METAOPTION(optionType = ty),_))
      local Type ty;
      equation
        s1 = printTypeStr(ty);
         str = Util.stringAppendList({"Option<",s1,">"});
      then
        str;

    case ((DAE.T_META_ARRAY(ty),_))
      local Type ty;
      equation
        s1 = printTypeStr(ty);
         str = Util.stringAppendList({"array<",s1,">"});
      then
        str;

    case ((DAE.T_BOXED(ty),_))
      local Type ty;
      equation
        s1 = printTypeStr(ty);
         str = Util.stringAppendList({"boxed<",s1,">"});
      then
        str;

    case ((DAE.T_POLYMORPHIC(s1),_))
      equation
         str = Util.stringAppendList({"polymorphic<",s1,">"});
      then
        str;

    case ((DAE.T_NOTYPE(),_))
      then
        "NOTYPE";
    case ((DAE.T_ANYTYPE(anyClassType = _),_))
      equation
      then
        "ANYTYPE";

       /* Uniontype, Metarecord */
    case ((_,SOME(path)))
      local Absyn.Path path;
      equation
         s1 = Absyn.pathString(path);
         str = "#" +& s1 +& "#";
      then
        str;

    case ((_,_))
    then "printTypeStr failed";
  end matchcontinue;
end printTypeStr;

public function printConnectorTypeStr "
Author BZ, 2009-09
  Print the connector-type-name
"
input Type t;
output String s "Connector type";
output String s2 "Components of connector";
algorithm (s,s2) := matchcontinue(t)
  local
    ClassInf.State st;
    Absyn.Path connectorName;
    list<Var> vars;
    Option<Type> bc;
    Option<Absyn.Path> op;
    list<String> varNames;
    Boolean isExpandable;
    String isExpandableStr;

  case((DAE.T_COMPLEX(complexClassType = (st as ClassInf.CONNECTOR(connectorName,isExpandable)),complexVarLst = vars,complexTypeOption = bc),op))
    equation
      varNames = Util.listMap(vars,varName);
      isExpandableStr = Util.if_(isExpandable,"/* expandable */ ", "");
      s = isExpandableStr +& Absyn.pathString(connectorName);
      s2 = "{" +& Util.stringDelimitList(varNames,", ") +& "}";
      then
        (s,s2);
  case(_) then ("","");
  end matchcontinue;
end printConnectorTypeStr;

public function printParamsStr "function: printParams

  Prints function arguments to a string.
"
  input list<FuncArg> inFuncArgLst;
  output String str;
algorithm
  str :=
  matchcontinue (inFuncArgLst)
    local
      Ident n;
      Type t;
      list<FuncArg> params;
      String s1,s2;
    case {} then "";
    case {(n,t)}
      equation
        s1 = printTypeStr(t);
        str = Util.stringAppendList({n," :: ",s1});
      then
        str;
    case (((n,t) :: params))
      equation
        s1 = printTypeStr(t);
        s2 = printParamsStr(params);
        str = Util.stringAppendList({n," :: ",s1, " * ",s2});
      then
       str;
  end matchcontinue;
end printParamsStr;

public function unparseVarAttr "
  Prints a variable which is attribute of builtin type to a string, e.g. on the form 'max = 10.0'
"
  input Var inVar;
  output String outString;
algorithm
  outString:=
  matchcontinue (inVar)
    local
      Ident t,res,n,bindStr,valStr;
      Attributes attr;
      Boolean prot;
      Type typ;
      Binding bind;
      Values.Value value;
      DAE.Exp e;
    case DAE.TYPES_VAR(name = n,attributes = attr,protected_ = prot,type_ = typ,binding = DAE.EQBOUND(exp=e))
      equation
        bindStr = Exp.printExpStr(e);
        res = Util.stringAppendList({n,"=",bindStr});
      then
        res;
    case DAE.TYPES_VAR(name = n,attributes = attr,protected_ = prot,type_ = typ,binding = DAE.VALBOUND(valBound=value))
      equation
        valStr = ValuesUtil.valString(value);
        res = Util.stringAppendList({n,"=",valStr});
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
  outString:=
  matchcontinue (inVar)
    local
      Ident t,res,n;
      Attributes attr;
      Boolean prot;
      Type typ;
      Binding bind;
    case DAE.TYPES_VAR(name = n,attributes = attr,protected_ = prot,type_ = typ,binding = bind)
      equation
        t = unparseType(typ);
        res = Util.stringAppendList({t," ",n,";\n"});
      then
        res;
  end matchcontinue;
end unparseVar;

protected function unparseParam "function: unparseParam

  Prints a function argument to a string.
"
  input FuncArg inFuncArg;
  output String outString;
algorithm
  outString:=
  matchcontinue (inFuncArg)
    local
      Ident tstr,res,id;
      Type ty;
    case ((id,ty))
      equation
        tstr = unparseType(ty);
        res = Util.stringAppendList({id,":",tstr});
      then
        res;
  end matchcontinue;
end unparseParam;

public function printVarStr "function: printVar
  author: LS

  Prints a Var to the a string.
"
  input Var inVar;
  output String str;
algorithm
  str :=
  matchcontinue (inVar)
    local
      Ident vs,n;
      SCode.Variability var;
      Boolean prot;
      Type typ;
      Binding bind;
      String s1,s2,s3;
    case DAE.TYPES_VAR(name = n,attributes = DAE.ATTR(parameter_ = var),protected_ = prot,type_ = typ,binding = bind)
      equation
        s1 = printTypeStr(typ);
        vs = SCode.variabilityString(var);
        s2 = printBindingStr(bind);
        str = Util.stringAppendList({s1," ",n," ",vs," ",s2});
      then
        str;
   case DAE.TYPES_VAR(name = n,attributes = DAE.ATTR(parameter_ = var),protected_ = prot,type_ = typ,binding = bind)
      equation
      str = Util.stringAppendList({n});
      then
        str;
  end matchcontinue;
end printVarStr;

public function printBindingStr "function: pritn_binding_str

  Print a variable binding to a string.
"
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
    case DAE.EQBOUND(exp = exp,evaluatedExp = NONE,constant_ = f,source = source)
      equation
        str = Exp.printExpStr(exp);
        str2 = unparseConst(f);
        str3 = DAEUtil.printBindingSourceStr(source);
        res = Util.stringAppendList({"DAE.EQBOUND(",str,", NONE(), ",str2,", ",str3,")"});
      then
        res;
    case DAE.EQBOUND(exp = exp,evaluatedExp = SOME(v),constant_ = f,source = source)
      equation
        str = Exp.printExpStr(exp);
        str2 = unparseConst(f);
        v_str = ValuesUtil.valString(v);
        str3 = DAEUtil.printBindingSourceStr(source);
        res = Util.stringAppendList({"DAE.EQBOUND(",str,", SOME(",v_str,"), ",str2,", ",str3,")"});
      then
        res;
    case DAE.VALBOUND(valBound = v, source = source)
      equation
        s = ValuesUtil.unparseValues({v});
        str3 = DAEUtil.printBindingSourceStr(source);
        res = Util.stringAppendList({"DAE.VALBOUND(",s,", ",str3,")"});
      then
        res;
    case(_) then "";
  end matchcontinue;
end printBindingStr;

public function makeFunctionType "function: makeFunctionType
  author: LS

  Creates a function type from a function name an a list of input and
  output variables.
"
  input Absyn.Path p;
  input list<Var> vl;
  input DAE.InlineType isInline;
  output Type outType;
  list<Var> invl,outvl;
  list<FuncArg> fargs;
  Type rettype;
algorithm
  invl := getInputVars(vl);
  outvl := getOutputVars(vl);
  fargs := makeFargsList(invl);
  rettype := makeReturnType(outvl) "	& Debug.fprint (\"ft\", \" <fargs: \") &
	Debug.fprint_list (\"ft\", fargs, print_farg, \", \") &
	Debug.fprint (\"ft\", \" >\") &

	Debug.fprint (\"ft\", \" <rettype: \") &
	Debug.fcall (\"ft\", print_type, rettype) &
	Debug.fprint (\"ft\", \" >\")
" ;
  outType := (DAE.T_FUNCTION(fargs,rettype,isInline),SOME(p));
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
    case (_, (DAE.T_ENUMERATION(index = NONE, path = p, names = names,
            literalVarLst = vars, attributeLst = attrs), _))
      equation
        vars = makeEnumerationType1(p, vars, names, 1);
        attr_names = Util.listMap(vars, getVarName);
        attrs = makeEnumerationType1(p, attrs, attr_names, 1);
      then
        ((DAE.T_ENUMERATION(NONE, p, names, vars, attrs), SOME(inPath)));
    case (_, (DAE.T_ARRAY(arrayType = ty), _))
      then makeEnumerationType(inPath, ty);
    case (_, _)
      equation
        Debug.fprintln("failtrace", "- Types.makeEnumerationType failed on " +&
            printTypeStr(inType));
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
  outVarLst:=
  matchcontinue (inPath,inVarLst,inNames,inIdx)
    local
      list<Ident> names;
      Absyn.Path p;
      Ident name;
      list<Var> xs,vars;
      Type t;
      Integer idx;
      Attributes attributes;
      Boolean protected_;
      Binding binding;
      Var var;
      Option<DAE.Const> cnstForRange;
      
    case (p,DAE.TYPES_VAR(name,attributes,protected_,_,binding,cnstForRange) :: xs,names,idx)
      equation
        vars = makeEnumerationType1(p, xs, names, idx+1);
        t = (DAE.T_ENUMERATION(SOME(idx),p,names,{},{}),SOME(p));
        var = DAE.TYPES_VAR(name,attributes,protected_,t,binding,cnstForRange);
      then
        (var :: vars);
    case (p,{},names,_) then {};
  end matchcontinue;
end makeEnumerationType1;

public function printFarg "function: printFarg
  Prints a function argument to the Print buffer."
  input FuncArg inFuncArg;
algorithm
  _:=
  matchcontinue (inFuncArg)
    local
      Ident n;
      Type ty;
    case ((n,ty))
      equation
        Print.printErrorBuf(printTypeStr(ty));
        Print.printErrorBuf(" ");
        Print.printErrorBuf(n);
      then
        ();
  end matchcontinue;
end printFarg;

public function printFargStr "function: printFargStr

  Prints a function argument to a string
"
  input FuncArg inFuncArg;
  output String outString;
algorithm
  outString:=
  matchcontinue (inFuncArg)
    local
      Ident s,res,n;
      Type ty;
    case ((n,ty))
      equation
        s = unparseType(ty);
        res = Util.stringAppendList({s," ",n});
      then
        res;
  end matchcontinue;
end printFargStr;

protected function getInputVars "function: getInputVars
  author: LS

  Retrieve all the input variables from a list of variables.
"
  input list<Var> vl;
  output list<Var> vl_1;
  list<Var> vl_1;
algorithm
  vl_1 := getVars(vl, isInputVar);
end getInputVars;

protected function getOutputVars "function: getOutputVars
  author: LS

  Retrieve all output variables from a list of variables.
"
  input list<Var> vl;
  output list<Var> vl_1;
  list<Var> vl_1;
algorithm
  vl_1 := getVars(vl, isOutputVar);
end getOutputVars;

public function getFixedVarAttribute "Returns the value of the fixed attribute of a builtin type"
  input Type tp;
  output Boolean fixed;
algorithm
  fixed :=  matchcontinue(tp)
  local list<Var> vars;
    case((DAE.T_REAL(DAE.TYPES_VAR("fixed",binding = DAE.VALBOUND(valBound = Values.BOOL(fixed)))::_),_)) then fixed;
    case((DAE.T_REAL(DAE.TYPES_VAR("fixed",binding = DAE.EQBOUND(evaluatedExp = SOME(Values.BOOL(fixed))))::_),_)) then fixed;
    case((DAE.T_REAL(DAE.TYPES_VAR("fixed",binding = DAE.EQBOUND(exp = DAE.BCONST(fixed)))::_),_)) then fixed;
    case((DAE.T_REAL(_::vars),_)) equation
      fixed = getFixedVarAttribute((DAE.T_REAL(vars),NONE));
    then fixed;

    case((DAE.T_INTEGER(DAE.TYPES_VAR("fixed",binding = DAE.VALBOUND(valBound = Values.BOOL(fixed)))::_),_)) then fixed;
    case((DAE.T_INTEGER(DAE.TYPES_VAR("fixed",binding = DAE.EQBOUND(evaluatedExp = SOME(Values.BOOL(fixed))))::_),_)) then fixed;
    case((DAE.T_INTEGER(DAE.TYPES_VAR("fixed",binding = DAE.EQBOUND(exp = DAE.BCONST(fixed)))::_),_)) then fixed;
    case((DAE.T_INTEGER(_::vars),_)) equation
      fixed = getFixedVarAttribute((DAE.T_INTEGER(vars),NONE));
    then fixed;

    case((DAE.T_BOOL(DAE.TYPES_VAR("fixed",binding = DAE.VALBOUND(valBound = Values.BOOL(fixed)))::_),_)) then fixed;
    case((DAE.T_BOOL(DAE.TYPES_VAR("fixed",binding = DAE.EQBOUND(evaluatedExp = SOME(Values.BOOL(fixed))))::_),_)) then fixed;
    case((DAE.T_BOOL(DAE.TYPES_VAR("fixed",binding = DAE.EQBOUND(exp = DAE.BCONST(fixed)))::_),_)) then fixed;
    case((DAE.T_BOOL(_::vars),_)) equation
      fixed = getFixedVarAttribute((DAE.T_BOOL(vars),NONE));
    then fixed;
      
    case((DAE.T_ARRAY(arrayType = ty), _))
      local
        Type ty;
        Boolean result;
      equation
        result = getFixedVarAttribute(ty);
      then 
        result;  
  end matchcontinue;
end getFixedVarAttribute;

public function getClassname "function: getClassname

  Return the classname from a type.
"
  input Type inType;
  output Absyn.Path outPath;
algorithm
  outPath:=
  matchcontinue (inType)
    local Absyn.Path p;
    case ((_,SOME(p))) then p;
  end matchcontinue;
end getClassname;

public function getClassnameOpt "function: getClassname
  Return the classname as option from a type."
  input Type inType;
  output Option<Absyn.Path> outPath;
algorithm
  outPath:=
  matchcontinue (inType)
    local Option<Absyn.Path> p;
    case ((_,p)) then p;
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
  outVarLst:=
  matchcontinue (inVarLst,inFuncTypeVarTo)
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

protected function isInputVar "function: isInputVar
  author: LS

  Succeds if variable is an input variable.
"
  input Var inVar;
algorithm
  _:=
  matchcontinue (inVar)
    local
      Ident n;
      Attributes attr;
      Type ty;
      Binding bnd;
    case DAE.TYPES_VAR(name = n,attributes = attr,protected_ = false,type_ = ty,binding = bnd) /* LS: false means not protected, hence we ignore protected variables */
      equation
        true = isInputAttr(attr);
      then
        ();
  end matchcontinue;
end isInputVar;

protected function isOutputVar "function: isOutputVar
  author: LS

  Succeds if variable is an output variable.
"
  input Var inVar;
algorithm
  _:=
  matchcontinue (inVar)
    local
      Ident n;
      Attributes attr;
      Type ty;
      Binding bnd;
    case DAE.TYPES_VAR(name = n,attributes = attr,protected_ = false,type_ = ty,binding = bnd) /* LS: false means not protected, hence we ignore protected variables */
      equation
        true = isOutputAttr(attr);
      then
        ();
  end matchcontinue;
end isOutputVar;

public function isInputAttr "function: isInputAttr

  Returns true if the Attributes of a variable indicates
  that the variable is input.
"
  input Attributes inAttributes;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inAttributes)
    case DAE.ATTR(direction = Absyn.INPUT()) then true;
    case _ then false;
  end matchcontinue;
end isInputAttr;

public function isOutputAttr "function: isOutputAttr

  Returns true if the Attributes of a variable indicates
  that the variable is output.
"
  input Attributes inAttributes;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inAttributes)
    case DAE.ATTR(direction = Absyn.OUTPUT()) then true;
    case _ then false;
  end matchcontinue;
end isOutputAttr;

public function isBidirAttr "function: isBidirAttr

  Returns true if the Attributes of a variable indicates that the variable
  is bidirectional, i.e. neither input nor output.
"
  input Attributes inAttributes;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inAttributes)
    case DAE.ATTR(direction = Absyn.BIDIR()) then true;
    case _ then false;
  end matchcontinue;
end isBidirAttr;

public function makeFargsList "function: makeFargsList
  author: LS

  Makes a function argument list from a list of variables.
"
  input list<Var> inVarLst;
  output list<FuncArg> outFuncArgLst;
algorithm
  outFuncArgLst:=
  matchcontinue (inVarLst)
    local
      list<FuncArg> fargl;
      Ident n;
      Attributes attr;
      Boolean pr;
      Type ty;
      Binding bnd;
      list<Var> vl;
    case {} then {};
    case ((DAE.TYPES_VAR(name = n,attributes = attr,protected_ = pr,type_ = ty,binding = bnd) :: vl))
      equation
        fargl = makeFargsList(vl);
      then
        ((n,ty) :: fargl);
  end matchcontinue;
end makeFargsList;

protected function makeReturnType "function: makeReturnType
  author: LS

  Create a return type from a list of output variables.
  Depending on the length of the output variable list, different
  kinds of return types are created.
"
  input list<Var> inVarLst;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inVarLst)
    local
      Type ty;
      Var var;
      list<Type> tys;
      list<Var> vl;
    case {} then ((DAE.T_NORETCALL(),NONE));
    case {var}
      equation
        ty = makeReturnTypeSingle(var);
      then
        ty;
    case vl
      equation
        tys = makeReturnTypeTuple(vl);
      then
        ((DAE.T_TUPLE(tys),NONE));
  end matchcontinue;
end makeReturnType;

protected function makeReturnTypeSingle "function: makeReturnTypeSingle
  author: LS

  Create the return type for a single return value.
"
  input Var inVar;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inVar)
    local
      Ident n;
      Attributes attr;
      Boolean pr;
      Type ty;
      Binding bnd;
    case DAE.TYPES_VAR(name = n,attributes = attr,protected_ = pr,type_ = ty,binding = bnd) then ty;
  end matchcontinue;
end makeReturnTypeSingle;

protected function makeReturnTypeTuple "function: makeReturnTypeTuple
  author: LS

  Create the return type for a tuple, i.e. a function returning several
  values.
"
  input list<Var> inVarLst;
  output list<Type> outTypeLst;
algorithm
  outTypeLst:=
  matchcontinue (inVarLst)
    local
      list<Type> tys;
      Ident n;
      Attributes attr;
      Boolean pr;
      Type ty;
      Binding bnd;
      list<Var> vl;
    case {} then {};
    case (DAE.TYPES_VAR(name = n,attributes = attr,protected_ = pr,type_ = ty,binding = bnd) :: vl)
      equation
        tys = makeReturnTypeTuple(vl);
      then
        (ty :: tys);
  end matchcontinue;
end makeReturnTypeTuple;

public function isParameter "function: isParameter
  author: LS

  Succeds if a variable is a parameter.
"
  input Var inVar;
algorithm
  _:=
  matchcontinue (inVar)
    local
      Ident n;
      Boolean fl,st;
      SCode.Accessibility ac;
      Absyn.Direction dir;
      Type ty;
      Binding bnd;
    case DAE.TYPES_VAR(name = n,
             attributes = DAE.ATTR(flowPrefix = fl,streamPrefix=st,accessibility = ac,parameter_ = SCode.PARAM(),direction = dir),
             protected_ = false,type_ = ty,binding = bnd)
    then ();  /* LS: false means not protected, hence we ignore protected variables */
  end matchcontinue;
end isParameter;

public function isParameterOrConstant "returns true if Const is PARAM or CONST"
  input Const c;
  output Boolean b;
algorithm
  b := matchcontinue(c)
    case(DAE.C_CONST()) then true;
    case(DAE.C_PARAM()) then true;
    case(_) then false;
  end matchcontinue;
end isParameterOrConstant;

public function containReal "function: containReal

  Returns true if a buitlin type, or array-type is Real.
"
  input list<Type> inTypeLst;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inTypeLst)
    local
      Boolean r1,r2,res;
      Type tp;
      list<Type> xs;
    case (((DAE.T_ARRAY(arrayType = tp),_) :: xs))
      equation
        r1 = containReal({tp});
        r2 = containReal(xs);
        res = boolOr(r1, r2);
      then
        res;

    case ((DAE.T_COMPLEX(_,_,SOME(tp),_),_)::xs)
      equation
        r1 = containReal({tp});
        r2 = containReal(xs);
        res = boolOr(r1,r2);
      then res;

    case (((DAE.T_REAL(varLstReal = _),_) :: _)) then true;
    case ((_ :: xs))
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
   a[4,5] will give {5,4} in return value.
"
  input Type inType;
  output Type outType;
  output list<Integer> outIntegerLst;
algorithm
  (outType,outIntegerLst):=
  matchcontinue (inType)
    local
      Type ty_1,ty;
      list<Integer> dimlist_1,dimlist;
      Integer dim;
      DAE.Dimension d;
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN,arrayType = ty),_))
      equation
        (ty_1,dimlist_1) = flattenArrayType(ty);
      then
        (ty_1,dimlist_1);
    case ((DAE.T_ARRAY(arrayDim = d,arrayType = ty),_))
      equation
        dim = Exp.dimensionSize(d); 
        (ty_1,dimlist) = flattenArrayType(ty);
        dimlist_1 = listAppend(dimlist, {dim});
      then
        (ty_1,dimlist_1);
        // Complex type extending basetype.
    case ((DAE.T_COMPLEX(_,_,SOME(ty),_),_)) equation
      (ty_1,dimlist) = flattenArrayType(ty);
    then (ty_1,dimlist);
    case ty then (ty,{});
  end matchcontinue;
end flattenArrayType;

public function flattenArrayTypeOpt "function: flattenArrayTypeOpt

  Returns the element type of a Type and the list of dimensions of the type.
"
  input Type inType;
  output Type outType;
  output list<DAE.Dimension> outDimensionLst;
algorithm
  (outType,outDimensionLst):=
  matchcontinue (inType)
    local
      Type ty_1,ty;
      list<DAE.Dimension> dimlist;
      DAE.Dimension dim;

    // Array type
    case ((DAE.T_ARRAY(arrayDim = dim,arrayType = ty),_))
      equation
        (ty_1,dimlist) = flattenArrayTypeOpt(ty);
      then
        (ty_1, dim :: dimlist);

    // Complex type extending basetype.
    case ((DAE.T_COMPLEX(_,_,SOME(ty),_),_)) 
      equation
        (ty_1,dimlist) = flattenArrayTypeOpt(ty);
      then 
        (ty_1,dimlist);

    // Element type
    case ty then (ty,{});
  end matchcontinue;
end flattenArrayTypeOpt;

public function getTypeName "function: getTypeName

  Return the type name of a Type.
"
  input Type inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inType)
    local
      Ident n,dimstr,tystr,str;
      ClassInf.State st;
      Type ty,arrayty;
      list<Integer> dims;
      list<Ident> dimstrs;
    case ((DAE.T_INTEGER(varLstInt = _),_)) then "Integer";
    case ((DAE.T_REAL(varLstReal = _),_)) then "Real";
    case ((DAE.T_STRING(varLstString = _),_)) then "String";
    case ((DAE.T_BOOL(varLstBool = _),_)) then "Boolean";
    case ((DAE.T_COMPLEX(complexClassType = st),_))
      equation
        n = Absyn.pathString(ClassInf.getStateName(st));
      then
        n;
    case ((arrayty as (DAE.T_ARRAY(arrayDim = _),_)))
      equation
        (ty,dims) = flattenArrayType(arrayty);
        dimstrs = Util.listMap(dims, intString);
        dimstr = Util.stringDelimitList(dimstrs, ", ");
        tystr = getTypeName(ty);
        str = Util.stringAppendList({tystr,"[",dimstr,"]"});
      then
        str;

        /* MetaModelica type */
    case ((DAE.T_LIST(ty),_))
      equation
        n = getTypeName(ty);
      then
        n;

    case ((_,_)) then "Not nameable type or no type";
  end matchcontinue;
end getTypeName;

public function propAllConst "function: propAllConst
  author: LS

  If PROP_TUPLE, returns true if all of the flags are constant.
"
  input Properties inProperties;
  output Const outConst;
algorithm
  outConst:=
  matchcontinue (inProperties)
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
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- prop_all_const failed: ");
        str = printPropStr(prop);
        Debug.fprintln("failtrace", str);
      then
        fail();
  end matchcontinue;
end propAllConst;

public function propAnyConst "function: propAnyConst
  author: LS

  If PROP_TUPLE, returns true if any of the flags are true
"
  input Properties inProperties;
  output Const outConst;
algorithm
  outConst:=
  matchcontinue (inProperties)
    local
      Const constant_,res;
      Ident str;
      Properties prop;
    case DAE.PROP(constFlag = constant_) then constant_;
    case DAE.PROP_TUPLE(tupleConst = constant_)
      local TupleConst constant_;
      equation
        res = propTupleAnyConst(constant_);
      then
        res;
    case prop
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- prop_any_const failed: ");
        str = printPropStr(prop);
        Debug.fprintln("failtrace", str);
      then
        fail();
  end matchcontinue;
end propAnyConst;

protected function propTupleAnyConst "function: propTupleAnyConst
  author: LS

  Helper function to prop_any_const.
"
  input TupleConst inTupleConst;
  output Const outConst;
algorithm
  outConst:=
  matchcontinue (inTupleConst)
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
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- prop_tuple_any_const failed: ");
        str = unparseTupleconst(const);
        Debug.fprintln("failtrace", str);
      then
        fail();
  end matchcontinue;
end propTupleAnyConst;

protected function propTupleAllConst "function: propTupleAllConst
  author: LS

  Helper function to prop_all_const.
"
  input TupleConst inTupleConst;
  output Const outConst;
algorithm
  outConst:=
  matchcontinue (inTupleConst)
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
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- prop_tuple_all_const failed: ");
        str = unparseTupleconst(const);
        Debug.fprintln("failtrace", str);
      then
        fail();
  end matchcontinue;
end propTupleAllConst;

public function isPropTupleArray "function: isPropTupleArray
This function will check all elements in the tuple if anyone is an array, return true.
As for now it will not check tuple of tuples ie. no recursion.
"
  input Properties p;
  output Boolean ob;
  Boolean b1,b2;
algorithm
  b1 := isPropTuple(p);
  b2 := isPropArray(p);
  ob := boolOr(b1,b2);
end isPropTupleArray;

public function isPropTuple "
Checks if Properties is a tuple or not.
"
  input Properties p;
  output Boolean b;
algorithm
  b := matchcontinue (p)
    case(p)
      equation
        (( DAE.T_TUPLE(_),_)) = getPropType(p);
      then
        true;
    case(_) then false;
  end matchcontinue;
end isPropTuple;

public function isPropArray "function: isPropArray

  Return true if properties contain an array type.
"
  input Properties p;
  output Boolean b;
  Type t;
algorithm
  t := getPropType(p);
  b := isArray(t);
end isPropArray;

public function propTuplePropList
  "Splits a PROP_TUPLE into a list of PROPs."
  input Properties prop_tuple;
  output list<Properties> prop_list;
algorithm
  prop_list := matchcontinue(prop_tuple)
    case (DAE.PROP_TUPLE(type_ = (DAE.T_TUPLE(tupleType = tl), _),
                         tupleConst = DAE.TUPLE_CONST(tupleConstLst = cl)))
      local
        list<Properties> pl;
        list<Type> tl;
        list<TupleConst> cl;
      equation
        pl = propTuplePropList2(tl, cl);
      then
        pl;
  end matchcontinue;
end propTuplePropList;

protected function propTuplePropList2
  "Helper function to propTuplePropList"
  input list<Type> tl;
  input list<TupleConst> cl;
  output list<Properties> pl;
algorithm
  pl := matchcontinue(tl, cl)
    case ({}, {}) then {};
    case (t :: t_rest, DAE.SINGLE_CONST(c) :: c_rest)
      local
        Type t;
        list<Type> t_rest;
        Const c;
        list<TupleConst> c_rest;
        list<Properties> p_rest;
      equation
        p_rest = propTuplePropList2(t_rest, c_rest);
      then
        (DAE.PROP(t, c) :: p_rest);
  end matchcontinue;
end propTuplePropList2;

public function getPropType "function: getPropType
  author: LS

  Return the Type from Properties.
"
  input Properties inProperties;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inProperties)
    local Type ty;
    case DAE.PROP(type_ = ty) then ty;
    case DAE.PROP_TUPLE(type_ = ty) then ty;
  end matchcontinue;
end getPropType;

public function elabType "function: elabType
  Elaborates a type
"
  input Type inType;
  output DAE.ExpType outType;
algorithm
  outType:=
  matchcontinue (inType)
    local
      Type et,t;
      DAE.ExpType t_1;
      list<DAE.Dimension> dims;
    case ((DAE.T_INTEGER(varLstInt = _),_)) then DAE.ET_INT();
    case ((DAE.T_REAL(varLstReal = _),_)) then DAE.ET_REAL();
    case ((DAE.T_BOOL(varLstBool = _),_)) then DAE.ET_BOOL();
    case ((DAE.T_STRING(varLstString = _),_)) then DAE.ET_STRING();
    case ((DAE.T_ENUMERATION(path = path, names = names, literalVarLst = varLst),_))
      local
        Absyn.Path path;
        list<String> names;
        list<Var> varLst;
        list<DAE.ExpVar> ecvl;
      equation
        ecvl = Util.listMap(varLst,convertFromTypesToExpVar);
      then
        DAE.ET_ENUMERATION(path,names,ecvl);
    case ((t as (DAE.T_ARRAY(arrayDim = _),_)))
      equation
        et = arrayElementType(t);
        t_1 = elabType(et);
        (_,dims) = flattenArrayTypeOpt(t);
      then
        DAE.ET_ARRAY(t_1,dims);

    case ( (DAE.T_COMPLEX(_,_,SOME(t),_),_))
      then elabType(t);

    case ((DAE.T_NORETCALL(),_)) then DAE.ET_NORETCALL();

    case ((DAE.T_COMPLEX(CIS,tcvl,_,_),_))
      local
        list<Var> tcvl;
        ClassInf.State CIS;
        list<DAE.ExpVar> ecvl;
        Absyn.Path name;
      equation
        ecvl = Util.listMap(tcvl,convertFromTypesToExpVar);
        name = ClassInf.getStateName(CIS);
        t_1 = DAE.ET_COMPLEX(name,ecvl,CIS);
      then
        t_1;

        // MetaModelica extension
    case ((DAE.T_LIST(t),_))
      equation
        t_1 = elabType(t);
      then DAE.ET_LIST(t_1);

    case ((DAE.T_META_ARRAY(t),_))
      equation
        t_1 = elabType(t);
      then DAE.ET_LIST(t_1);

    case ((DAE.T_FUNCTION(_,_,_),_)) "Ceval.ceval might need more info? Don't know how that part of the compiler works. sjoelund"
      then DAE.ET_FUNCTION_REFERENCE_VAR();

    case ((DAE.T_METAOPTION(t),_))
      equation
        t_1 = elabType(t);
      then DAE.ET_METAOPTION(t_1);

    case ((DAE.T_METATUPLE(t_l),_))
      local
        list<DAE.ExpType> t_l2;
        list<Type> t_l;
      equation
        t_l2 = Util.listMap(t_l,elabType);
      then DAE.ET_METATUPLE(t_l2);

    case ((DAE.T_BOXED(t),_)) equation t_1 = elabType(t); then DAE.ET_BOXED(t_1);

    case ((DAE.T_UNIONTYPE(_),_)) then DAE.ET_UNIONTYPE();

    case ((DAE.T_METARECORD(_,_),_)) then DAE.ET_UNIONTYPE();

    case ((DAE.T_POLYMORPHIC(_),_)) then DAE.ET_POLYMORPHIC();

        /* This is the case when the type is currently UNTYPED */
    case ((_,_))
      equation
        /*
        print(" untyped ");
        print(unparseType(inType));
        print("\n");
        */
      then DAE.ET_OTHER();
  end matchcontinue;
end elabType;

public function matchProp
"function: matchProp
  This is basically a wrapper aroune `match_type\'.  It matches an
  expression with properties with another set of properties.  If
  necessary, the expression is modified to match.  The only relevant
  property is the type."
  input DAE.Exp inExp1;
  input Properties inProperties2;
  input Properties inProperties3;
  input Boolean printFailtrace;
  output DAE.Exp outExp;
  output Properties outProperties;
algorithm
  (outExp,outProperties):=
  matchcontinue (inExp1,inProperties2,inProperties3,printFailtrace)
    local
      DAE.Exp e_1,e;
      Type t_1,gt,et;
      Const c,c1,c2;
    case (e,DAE.PROP(type_ = gt,constFlag = c1),DAE.PROP(type_ = et,constFlag = c2),printFailtrace)
      equation
        (e_1,t_1) = matchType(e, gt, et, printFailtrace);
        c = constAnd(c1, c2);
      then
        (e_1,DAE.PROP(t_1,c));
    case (e,DAE.PROP_TUPLE(type_ = gt,tupleConst = c1),DAE.PROP_TUPLE(type_ = et,tupleConst = c2),printFailtrace)
      local TupleConst c,c1,c2;
      equation
        (e_1,t_1) = matchType(e, gt, et, printFailtrace);
        c = constTupleAnd(c1, c2);
      then
        (e_1,DAE.PROP_TUPLE(t_1,c));
        
        /* The problem with MetaModelica tuple is that it is a datatype (should use PROP instead of PROP_TUPLE)
         * this case converts a TUPLE to META_TUPLE */
    case (e,DAE.PROP_TUPLE(type_ = (gt as (DAE.T_TUPLE(_),_)),tupleConst = c1), DAE.PROP(type_ = (et as (DAE.T_METATUPLE(_),_)),constFlag = c2),printFailtrace)
      local TupleConst c1; Const c_1;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (e_1,t_1) = matchType(e, gt, et, printFailtrace);
        c_1 = propTupleAllConst(c1);
        c = constAnd(c_1, c2);
      then
        (e_1,DAE.PROP(t_1,c));

    case(e,inProperties2,inProperties3,true)
      equation
        // activate on +d=types flag
        true = RTOpts.debugFlag("types");
        Debug.traceln("- Types.matchProp failed on exp: " +& Exp.printExpStr(e));
        Debug.traceln(printPropStr(inProperties2) +& " != ");
        Debug.traceln(printPropStr(inProperties3));
      then fail();
  end matchcontinue;
end matchProp;

public function matchType "function: matchType
  This function matches an expression with an expected type, and
  converts the expression to the expected type if necessary.
  inputs : (exp: DAE.Exp, exp_type: Type, expected: Type)
  outputs: (DAE.Exp, Type)"
  input DAE.Exp exp;
  input Type expType;
  input Type expectedType;
  input Boolean printFailtrace;
  output DAE.Exp outExp;
  output Type outType;
algorithm
  (outExp,outType,_) := matchTypeRegular(exp, expType, expectedType, {}, printFailtrace);
end matchType;

protected function matchTypeList
  input list<DAE.Exp> exps;
  input Type expType;
  input Type expectedType;
  input PolymorphicBindings polymorphicBindings;
  input MatchTypeFunc matchFunc;
  input Boolean printFailtrace;
  output list<DAE.Exp> outExp;
  output list<Type> outTypeLst;
  output PolymorphicBindings outBindings;

	partial function MatchTypeFunc
	  input DAE.Exp inExp1;
	  input Type inType2;
	  input Type inType3;
	  input PolymorphicBindings polymorphicBindings;
    input Boolean printFailtrace;
    output DAE.Exp outExp;
    output Type outType;
    output PolymorphicBindings outBindings;
  end MatchTypeFunc;
algorithm
  (outExp,outTypeLst,outBindings):=
  matchcontinue (exps,expType,expectedType,polymorphicBindings,matchFunc,printFailtrace)
    local
      DAE.Exp e,e_1,e_2;
      list<DAE.Exp> e_2, rest;
      Type tp,t1,t2;
      list<Type> res;
    case ({},_,_,polymorphicBindings,_,_) then ({},{},polymorphicBindings);
    case (e::rest,t1,t2,polymorphicBindings,matchFunc,printFailtrace)
      equation
        (e_1,tp,polymorphicBindings) = matchFunc(e,t1,t2,polymorphicBindings,printFailtrace);
        (e_2,res,polymorphicBindings) = matchTypeList(rest,t1,t2,polymorphicBindings,matchFunc,printFailtrace);
      then
        (e_1::e_2,(tp :: res),polymorphicBindings);
    case (_,_,_,_,_,true)
      equation
        Debug.fprint("types", "- matchTypeList failed\n");
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
  input PolymorphicBindings polymorphicBindings;
  input MatchTypeFunc matchFunc;
  input Boolean printFailtrace;
  output list<DAE.Exp> outExp;
  output list<Type> outTypeLst;
  output PolymorphicBindings outBindings;

	partial function MatchTypeFunc
	  input DAE.Exp inExp1;
	  input Type inType2;
	  input Type inType3;
	  input PolymorphicBindings polymorphicBindings;
	  input Boolean printFailtrace;
	  output DAE.Exp outExp;
	  output Type outType;
	  output PolymorphicBindings outBindings;
	end MatchTypeFunc;
algorithm
  (outExp,outTypeLst,outBindings):=
  matchcontinue (inExp1,inTypeLst2,inTypeLst3,polymorphicBindings,matchFunc,printFailtrace)
    local
      DAE.Exp e,e_1;
      list<DAE.Exp> rest, e_2;
      Type tp,t1,t2;
      list<Type> res,ts1,ts2;
    case ({},{},{},polymorphicBindings,_,_) then ({},{},polymorphicBindings);
    case (e::rest,(t1 :: ts1),(t2 :: ts2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        (e_1,tp,polymorphicBindings) = matchFunc(e,t1,t2,polymorphicBindings,printFailtrace);
        (e_2,res,polymorphicBindings) = matchTypeTuple(rest,ts1,ts2,polymorphicBindings,matchFunc,printFailtrace);
      then
        (e_1::e_2,(tp :: res),polymorphicBindings);
    case (_,(t1 :: ts1),(t2 :: ts2),_,_,true)
      equation
        Debug.fprint("failtrace", "- Types.matchTypeTuple failed\n");
      then
        fail();
  end matchcontinue;
end matchTypeTuple;

public function matchTypeTupleCall
  input DAE.Exp inExp1;
  input list<Type> inTypeLst2;
  input list<Type> inTypeLst3;
algorithm
  (outExp,outTypeLst) :=
  matchcontinue (inExp1,inTypeLst2,inTypeLst3)
    local
      DAE.Exp e,e_1,e_2;
      Type tp,t1,t2;
      list<Type> res,ts1,ts2;
    case (_,_,{}) then ();
    case (e,(t1 :: ts1),(t2 :: ts2))
      equation
        (_,_) = matchType(e, t1, t2, true);
        matchTypeTupleCall(e, ts1, ts2);
      then ();
    case (_,(t1 :: ts1),(t2 :: ts2))
      equation
        Debug.fprint("failtrace", "- matchTypeTupleCall failed\n");
      then
        fail();
  end matchcontinue;
end matchTypeTupleCall;

public function vectorizableType "function: vectorizableType
  author: PA

  This function checks if a given type can be (converted and) vectorized to
  a expected type.
  For instance and argument of type Integer{:} can be vectorized to an
  argument type Real, using type coersion and vectorization of one dimension.
"
  input DAE.Exp inExp;
  input Type inExpType;
  input Type inExpectedType;
  output DAE.Exp outExp;
  output Type outType;
  output list<DAE.Dimension> outArrayDimLst;
  output PolymorphicBindings outBindings;
algorithm
  (outExp,outType,outArrayDimLst,outBindings) := vectorizableType2(inExp,inExpType,inExpType,{},inExpectedType);
end vectorizableType;

protected function vectorizableType2
  input DAE.Exp inExp;
  input Type inExpType;
  input Type inCurrentType;
  input list<DAE.Dimension> inArrayDimLst;
  input Type inExpectedType;
  output DAE.Exp outExp;
  output Type outType;
  output list<DAE.Dimension> outArrayDimLst;
  output PolymorphicBindings outBindings;
algorithm
  (outExp,outType,outArrayDimLst,outBindings) := matchcontinue (inExp,inExpType,inCurrentType,inArrayDimLst,inExpectedType)
    local
      DAE.Exp e_1,e;
      Type e_type_1,e_type,expected_type,expected_type_vectorized,e_type_elt,current_type;
      list<DAE.Dimension> ds;
      PolymorphicBindings polymorphicBindings;
      DAE.Dimension dim;
      list<DAE.Dimension> dims;
      Option<Integer> iOpt;
      list<Option<Integer>> iOptLst;
    case (e,e_type,current_type,dims,expected_type)
      equation
        expected_type_vectorized = liftArrayListDims(expected_type, dims);
        (e_1,e_type_1,polymorphicBindings) = matchTypePolymorphic(e, e_type, expected_type_vectorized, {}, true);
      then
        (e_1,e_type_1,dims,polymorphicBindings);
    case (e,e_type,(DAE.T_ARRAY(arrayType = current_type, arrayDim = dim),_),dims,expected_type)
      equation
        dims = listAppend(dims, {dim});
        (e_1,e_type_1,dims,polymorphicBindings) = vectorizableType2(e, e_type, current_type, dims, expected_type);
      then
        (e_1,e_type_1,dims,polymorphicBindings);
  end matchcontinue;
end vectorizableType2;

protected function typeConvert "function: typeConvert
  This functions converts the expression in the first argument to
  the type specified in the third argument.  The current type of the
  expression is given in the second argument.

  If no type conversion is possible, this function fails."
  input DAE.Exp inExp1;
  input Type inType2;
  input Type inType3;
  input PolymorphicBindings polymorphicBindings;
  input MatchTypeFunc matchFunc;
  input Boolean printFailtrace;
  output DAE.Exp outExp;
  output Type outType;
  output PolymorphicBindings outBindings;

  partial function MatchTypeFunc
    input DAE.Exp inExp1;
    input Type inType2;
    input Type inType3;
    input PolymorphicBindings polymorphicBindings;
    input Boolean printFailtrace;
    output DAE.Exp outExp;
    output Type outType;
    output PolymorphicBindings outBindings;
  end MatchTypeFunc;
algorithm
  (outExp,outType,outBindings):=
  matchcontinue (inExp1,inType2,inType3,polymorphicBindings,matchFunc,printFailtrace)
    local
      list<DAE.Exp> elist_1,elist;
      DAE.ExpType at,t;
      Boolean a,sc;
      Integer nmax;
      DAE.Dimension dim1, dim2, dim11, dim22;
      //Integer dim1,dim2,nmax,dim11,dim22;
      Type ty1,ty2,t1,t2,t_1,t_2,ty0;
      Option<Absyn.Path> p,p1,p2;
      DAE.Exp begin_1,step_1,stop_1,begin,step,stop,e_1,e,exp;
      list<list<tuple<DAE.Exp, Boolean>>> ell_1,ell;
      list<Type> tys_1,tys1,tys2;
      list<Ident> l;
      list<Var> v, al;
      String str;

      /* Array expressions: expression dimension [dim1], expected dimension [dim2] */
    case (DAE.ARRAY(array = elist),
          (DAE.T_ARRAY(arrayDim = dim1,arrayType = ty1),_),
          ty0 as (DAE.T_ARRAY(arrayDim = dim2,arrayType = ty2),p),
          polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = Exp.dimensionsKnownAndEqual(dim1, dim2);
        (elist_1,polymorphicBindings) = typeConvertArray(elist, ty1, ty2,dim1,polymorphicBindings,matchFunc,printFailtrace);
        at = elabType(ty0);
        a = isArray(ty2);
        sc = boolNot(a);
      then
        (DAE.ARRAY(at,sc,elist_1),(DAE.T_ARRAY(dim1,ty2),p),polymorphicBindings);

     /* Array expressions: expression dimension [:], expected dimension [dim2] */
    case (DAE.ARRAY(array = elist),
          (DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN,arrayType = ty1),_),
          ty0 as (DAE.T_ARRAY(arrayDim = dim2,arrayType = ty2),p2),
          polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = Exp.dimensionKnown(dim2);
        (elist_1,polymorphicBindings) = typeConvertArray(elist, ty1, ty2,dim2,polymorphicBindings,matchFunc,printFailtrace);
        at = elabType(ty0);
        a = isArray(ty2);
        sc = boolNot(a);
      then
        (DAE.ARRAY(at,sc,elist_1),(DAE.T_ARRAY(DAE.DIM_UNKNOWN,ty2),p2),polymorphicBindings);

        /* Array expressions: expression dimension [dim1], expected dimension [:] */
    case (DAE.ARRAY(array = elist),(DAE.T_ARRAY(arrayDim = dim1,arrayType = ty1),_),
        ty0 as (DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN,arrayType = ty2),p2),polymorphicBindings,matchFunc,printFailtrace)
        local
          DAE.ExpType ety1;
      equation
        true = Exp.dimensionKnown(dim1);
        (elist_1,polymorphicBindings) = typeConvertArray(elist, ty1, ty2, dim1,polymorphicBindings,matchFunc,printFailtrace);
        ety1 = elabType(ty2);
        at = elabType(ty0);
        a = isArray(ty2);
        sc = boolNot(a);
        //TODO: Verify correctness of return value.
      then
        (DAE.ARRAY(DAE.ET_ARRAY(ety1,{dim1}),sc,elist_1),(DAE.T_ARRAY(dim1,ty2),p2),polymorphicBindings);
        //(DAE.ARRAY(at,sc,elist_1),(DAE.T_ARRAY(DAE.DIM(SOME(dim1)),ty2),p2));

        /* Range expressions, e.g. 1:2:10 */
    case (DAE.RANGE(ty = t,exp = begin,expOption = SOME(step),range = stop),(DAE.T_ARRAY(arrayDim = dim1,arrayType = ty1),_),
      ty0 as (DAE.T_ARRAY(arrayDim = dim2,arrayType = ty2),p),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = Exp.dimensionsKnownAndEqual(dim1, dim2);
        (begin_1,_,polymorphicBindings) = typeConvert(begin, ty1, ty2, polymorphicBindings,matchFunc,printFailtrace);
        (step_1,_,polymorphicBindings) = typeConvert(step, ty1, ty2, polymorphicBindings,matchFunc,printFailtrace);
        (stop_1,_,polymorphicBindings) = typeConvert(stop, ty1, ty2, polymorphicBindings,matchFunc,printFailtrace);
        at = elabType(ty0);
      then
        (DAE.RANGE(at,begin_1,SOME(step_1),stop_1),(DAE.T_ARRAY(dim1,ty2),p),polymorphicBindings);

        /* Range expressions, e.g. 1:10 */
    case (DAE.RANGE(ty = t,exp = begin,expOption = NONE,range = stop),(DAE.T_ARRAY(arrayDim = dim1,arrayType = ty1),_),
      ty0 as (DAE.T_ARRAY(arrayDim = dim2,arrayType = ty2),p),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = Exp.dimensionsKnownAndEqual(dim1, dim2);
        (begin_1,_,polymorphicBindings) = typeConvert(begin, ty1, ty2, polymorphicBindings,matchFunc,printFailtrace);
        (stop_1,_,polymorphicBindings) = typeConvert(stop, ty1, ty2, polymorphicBindings,matchFunc,printFailtrace);
        at = elabType(ty0);
      then
        (DAE.RANGE(at,begin_1,NONE,stop_1),(DAE.T_ARRAY(dim1,ty2),p),polymorphicBindings);

        /* Matrix expressions: expression dimension [dim1,dim11], expected dimension [dim2,dim22] */
    case (DAE.MATRIX(integer = nmax,scalar = ell),(DAE.T_ARRAY(arrayDim = dim1,arrayType = (DAE.T_ARRAY(arrayDim = dim11,arrayType = t1),_)),_),
      ty0 as (DAE.T_ARRAY(arrayDim = dim2,arrayType = (DAE.T_ARRAY(arrayDim = dim22,arrayType = t2),p1)),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = Exp.dimensionsKnownAndEqual(dim1, dim2);
        true = Exp.dimensionsKnownAndEqual(dim11, dim22);
        (ell_1,polymorphicBindings) = typeConvertMatrix(ell, t1, t2,dim1,dim2,polymorphicBindings,matchFunc,printFailtrace);
        at = elabType(ty0);
      then
        (DAE.MATRIX(at,nmax,ell_1),(DAE.T_ARRAY(dim1,(DAE.T_ARRAY(dim11,t2),p1)),
          p2),polymorphicBindings);

        /* Matrix expressions: expression dimension [dim1,dim11] expected dimension [:,dim22] */
    case (DAE.MATRIX(integer = nmax,scalar = ell),(DAE.T_ARRAY(arrayDim = dim1,arrayType = (DAE.T_ARRAY(arrayDim = dim11,arrayType = t1),_)),_),
      ty0 as (DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN,arrayType = (DAE.T_ARRAY(arrayDim = dim22,arrayType = t2),p1)),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = Exp.dimensionsKnownAndEqual(dim11, dim22);
        (ell_1,polymorphicBindings) = typeConvertMatrix(ell, t1, t2,dim1,dim11,polymorphicBindings,matchFunc,printFailtrace);
        at = elabType(ty0);
      then
        (DAE.MATRIX(at,nmax,ell_1),(DAE.T_ARRAY(dim1,(DAE.T_ARRAY(dim11,t2),p1)),
          p2),polymorphicBindings);

        /* Arbitrary expressions, expression dimension [dim1], expected dimension [dim2] */
    case (e,(DAE.T_ARRAY(arrayDim = dim1,arrayType = ty1),_),
        ty0 as (DAE.T_ARRAY(arrayDim = dim2,arrayType = ty2),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = Exp.dimensionsKnownAndEqual(dim1, dim2);
        (e_1,t_1,polymorphicBindings) = typeConvert(e, ty1, ty2, polymorphicBindings,matchFunc,printFailtrace);
        e_1 = liftExpType(e_1,dim1);
        t_2 = (DAE.T_ARRAY(dim2,t_1),p2);
      then
        (e_1,t_2,polymorphicBindings);

        /* Arbitrary expressions,  expression dimension [:],  expected dimension [dim2]*/
    case (e,(DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN,arrayType = ty1),_),
        (DAE.T_ARRAY(arrayDim = dim2,arrayType = ty2),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        (e_1,t_1,polymorphicBindings) = typeConvert(e, ty1, ty2, polymorphicBindings,matchFunc,printFailtrace);
        e_1 = liftExpType(e_1,DAE.DIM_UNKNOWN);
      then
        (e_1,(DAE.T_ARRAY(DAE.DIM_UNKNOWN,t_1),p2),polymorphicBindings);

        /* Arbitrary expressions, expression dimension [:] expected dimension [:] */
    case (e,(DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN,arrayType = ty1),_),
      (DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN,arrayType = ty2),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        (e_1,t_1,polymorphicBindings) = typeConvert(e, ty1, ty2, polymorphicBindings,matchFunc,printFailtrace);
        e_1 = liftExpType(e_1,DAE.DIM_UNKNOWN);
      then
        (e_1,(DAE.T_ARRAY(DAE.DIM_UNKNOWN,t_1),p2),polymorphicBindings);

        /* Arbitrary expression, expression dimension [dim1] expected dimension [:]*/
    case (e,(DAE.T_ARRAY(arrayDim = dim1,arrayType = ty1),_),
        (DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN,arrayType = ty2),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        (e_1,t_1,polymorphicBindings) = typeConvert(e, ty1, ty2, polymorphicBindings,matchFunc,printFailtrace);
        e_1 = liftExpType(e_1,dim1);
      then
        (e_1,(DAE.T_ARRAY(dim1,t_1),p2),polymorphicBindings);

        /* Tuple */
    case (DAE.TUPLE(PR = elist),(DAE.T_TUPLE(tupleType = tys1),_),(DAE.T_TUPLE(tupleType = tys2),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        (elist_1,tys_1,polymorphicBindings) = typeConvertList(elist, tys1, tys2, polymorphicBindings,matchFunc,printFailtrace);
      then
        (DAE.TUPLE(elist_1),(DAE.T_TUPLE(tys_1),p2),polymorphicBindings);

    // Convert an integer literal to an enumeration
    // This is widely used in Modelica.Electrical.Digital
    case (exp as DAE.ICONST(oi),
              (DAE.T_INTEGER(_),_),
              (DAE.T_ENUMERATION(index=_, path=tp, names = l),p2),
              polymorphicBindings,matchFunc,printFailtrace)
      local        
        Absyn.Path tp;
        String name;
        Integer oi;
      equation
        // TODO! FIXME! check boundaries if the integer literal is not outside the enum range
        // select from enum list:
        name = listNth(l, oi-1); // listNth indexes from 0
        tp = Absyn.joinPaths(tp, Absyn.IDENT(name));
      then 
        (DAE.ENUM_LITERAL(tp, oi),inType3,polymorphicBindings);        

    /* Implicit conversion from Integer to Real */
    case (e,(DAE.T_INTEGER(varLstInt = v),_),(DAE.T_REAL(varLstReal = _),_),polymorphicBindings,matchFunc,printFailtrace)
      then (DAE.CAST(DAE.ET_REAL(),e),inType3,polymorphicBindings);

    /* Implicit conversion from Integer to enumeration. */
    case (e,(DAE.T_INTEGER(varLstInt = _),_),(DAE.T_ENUMERATION(index = _), _),_,_,_)
      equation
        t = elabType(inType3);
      then (DAE.CAST(t, e), inType3, polymorphicBindings);
      
    /* Implicit conversion from enumeration literal to Real */
    case (e, (DAE.T_ENUMERATION(index = _), _), (DAE.T_REAL(varLstReal = _), p), _, _, _)
      then (DAE.CAST(DAE.ET_REAL(),e),(DAE.T_REAL({}),p),polymorphicBindings);

    /* Complex type inheriting primitive type */
    case (e, (DAE.T_COMPLEX(complexTypeOption = SOME(t1)),_),t2,polymorphicBindings,matchFunc,printFailtrace) equation
      (e_1,t_1,polymorphicBindings) = typeConvert(e,t1,t2,polymorphicBindings,matchFunc,printFailtrace);
    then (e_1,t_1,polymorphicBindings);
    case (e, t1,(DAE.T_COMPLEX(complexTypeOption = SOME(t2)),_),polymorphicBindings,matchFunc,printFailtrace) equation
      (e_1,t_1,polymorphicBindings) = typeConvert(e,t1,t2,polymorphicBindings,matchFunc,printFailtrace);
    then (e_1,t_1,polymorphicBindings);

        /* MetaModelica Option */
    case (DAE.META_OPTION(SOME(e)),(DAE.T_METAOPTION(t1),_),(DAE.T_METAOPTION(t2),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (e_1, t_1, polymorphicBindings) = matchFunc(e,t1,t2,polymorphicBindings,printFailtrace);
      then
        (DAE.META_OPTION(SOME(e_1)),(DAE.T_METAOPTION(t_1),p2),polymorphicBindings);
    case (DAE.META_OPTION(NONE),_,(DAE.T_METAOPTION(t2),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
      then
        (DAE.META_OPTION(NONE),(DAE.T_METAOPTION(t2),p2),polymorphicBindings);

        //Part of metamodelica extension, added by, simbj
        // <uniontype> = <metarecord>
    case(e,(DAE.T_METARECORD(_,_),SOME(path)),t2 as (DAE.T_UNIONTYPE(lst),_),polymorphicBindings,matchFunc,printFailtrace)
      local
        list<Absyn.Path> lst;
        Absyn.Path path;
      equation
        true = listMember(path, lst);
      then (e,t2,polymorphicBindings);

        /* MetaModelica Tuple */
    case (DAE.TUPLE(elist),(DAE.T_TUPLE(tupleType = tys1),_),(DAE.T_METATUPLE(tys2),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (elist_1,tys_1,polymorphicBindings) = matchTypeTuple(elist, tys1, tys2, polymorphicBindings,matchFunc,printFailtrace);
      then
        (DAE.META_TUPLE(elist_1),(DAE.T_METATUPLE(tys_1),p2),polymorphicBindings);
    case (DAE.META_TUPLE(elist),(DAE.T_METATUPLE(tys1),_),(DAE.T_METATUPLE(tys2),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        (elist_1,tys_1,polymorphicBindings) = matchTypeTuple(elist, tys1, tys2, polymorphicBindings,matchFunc,printFailtrace);
      then
        (DAE.META_TUPLE(elist_1),(DAE.T_METATUPLE(tys_1),p2),polymorphicBindings);
      /*
         The automatic type conversion will convert any array that can be
         const-eval'ed to an DAE.ARRAY or DAE.MATRIX into a list of the same
         type. The reason is that the syntax for the array and list constructor
         is the same. However, the compiler can't distinguish between the two
         cases below because a is expanded earlier in the compilation process:
           Integer[3] a;
           someListFunction(a); // Is expanded to the line below
           someListFunction({a[1],a[2],a[3]});
         / sjoelund 2009-08-13
       */
    case (e as DAE.ARRAY(DAE.ET_ARRAY(ty = t),_,elist),(DAE.T_ARRAY(arrayType=t1),_),(DAE.T_LIST(t2),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (elist_1, tys1, polymorphicBindings) = matchTypeList(elist, t1, t2, polymorphicBindings,matchFunc,printFailtrace);
        (elist_1, t2, polymorphicBindings) = listMatchSuperType(elist_1, tys1, polymorphicBindings,matchFunc,printFailtrace);
        t = elabType(t2);
        e_1 = DAE.LIST(t,elist_1);
        t2 = (DAE.T_LIST(t2),NONE);
      then (e_1, t2, polymorphicBindings);
    case (e as DAE.ARRAY(DAE.ET_ARRAY(ty = t),_,elist),(DAE.T_ARRAY(arrayType=t1),_),(DAE.T_BOXED(t2),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (elist_1, tys1, polymorphicBindings) = matchTypeList(elist, t1, t2, polymorphicBindings,matchFunc,printFailtrace);
        (elist_1, t2, polymorphicBindings) = listMatchSuperType(elist_1, tys1, polymorphicBindings,matchFunc,printFailtrace);
        t = elabType(t2);
        e_1 = DAE.LIST(t,elist_1);
        t2 = (DAE.T_LIST(t2),NONE);
      then (e_1, t2, polymorphicBindings);
    case (e as DAE.MATRIX(DAE.ET_ARRAY(ty = t),_,melist),t1,t2,polymorphicBindings,matchFunc,printFailtrace)
      local
        list<list<tuple<DAE.Exp,Boolean>>> melist;
        list<list<DAE.Exp>> elist_big, elist_big_1;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        elist_big = Util.listListMap(melist, Util.tuple21);
        (elist,ty2,polymorphicBindings) = typeConvertMatrixToList(elist_big,t1,t2,polymorphicBindings,matchFunc,printFailtrace);
        t = elabType(ty2);
        e_1 = DAE.LIST(t,elist);
      then (e_1,ty2,polymorphicBindings);
    case (e as DAE.LIST(_,elist),(DAE.T_LIST(t1),_),(DAE.T_LIST(t2),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (elist_1, tys1, polymorphicBindings) = matchTypeList(elist, t1, t2, polymorphicBindings,matchFunc,printFailtrace);
        (elist_1, t2, polymorphicBindings) = listMatchSuperType(elist_1, tys1, polymorphicBindings,matchFunc,printFailtrace);
        t = elabType(t2);
        e_1 = DAE.LIST(t,elist_1);
        t2 = (DAE.T_LIST(t2),NONE);
      then (e_1, t2, polymorphicBindings);

    case (e,(DAE.T_LIST(t1),_),(DAE.T_LIST(t2),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (_, ty2, polymorphicBindings) = matchFunc(e,t1,t2,polymorphicBindings,printFailtrace);
      then (e, (DAE.T_LIST(ty2),p2), polymorphicBindings);

    case (e,(DAE.T_META_ARRAY(t1),_),(DAE.T_META_ARRAY(t2),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (_, ty2, polymorphicBindings) = matchFunc(e,t1,t2,polymorphicBindings,printFailtrace);
      then (e, (DAE.T_META_ARRAY(ty2),p2), polymorphicBindings);

    case (e, t1 as (DAE.T_INTEGER(_),_), (DAE.T_BOXED(t2),_),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = subtype(t1,t2);
        t2 = (DAE.T_BOXED(t1),NONE);
        t = elabType(t2);
      then (DAE.CALL(Absyn.IDENT("mmc_mk_icon"),{e},false,true,t,DAE.NO_INLINE),t2,polymorphicBindings);

    case (e, t1 as (DAE.T_BOOL(_),_), (DAE.T_BOXED(t2),_),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = subtype(t1,t2);
        t2 = (DAE.T_BOXED(t1),NONE);
        t = elabType(t2);
      then (DAE.CALL(Absyn.IDENT("mmc_mk_icon"),{e},false,true,t,DAE.NO_INLINE),t2,polymorphicBindings);

    case (e, t1 as (DAE.T_REAL(_),_), (DAE.T_BOXED(t2),_),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = subtype(t1,t2);
        t2 = (DAE.T_BOXED(t1),NONE);
        t = elabType(t2);
      then (DAE.CALL(Absyn.IDENT("mmc_mk_rcon"),{e},false,true,t,DAE.NO_INLINE),t2,polymorphicBindings);

    case (e, t1 as (DAE.T_STRING(_),_), (DAE.T_BOXED(t2),_),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = subtype(t1,t2);
        t2 = (DAE.T_BOXED(t1),NONE);
        t = elabType(t2);
      then (DAE.CALL(Absyn.IDENT("mmc_mk_scon"),{e},false,true,t,DAE.NO_INLINE),t2,polymorphicBindings);

    case (e as DAE.CALL(path = path1, expLst = elist), t1 as (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), complexVarLst = v),SOME(path2)), (DAE.T_BOXED(t2),_),polymorphicBindings,matchFunc,printFailtrace)
      local Absyn.Path path1,path2;
      equation
        true = subtype(t1,t2);
        true = Absyn.pathEqual(path1, path2);
        t2 = (DAE.T_BOXED(t1),NONE);
        l = Util.listMap(v, getVarName);
        tys1 = Util.listMap(v, getVarType);
        tys2 = Util.listMap(tys1, boxIfUnboxedType);
        (elist,_,polymorphicBindings) = matchTypeTuple(elist, tys1, tys2, polymorphicBindings,matchFunc,printFailtrace);
        e_1 = DAE.METARECORDCALL(path1, elist, l, 0);
      then (e_1,t2,polymorphicBindings);

    case (e as DAE.CALL(path = _), t1 as (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), complexVarLst = v),_), (DAE.T_BOXED(t2),_),polymorphicBindings,matchFunc,printFailtrace)
      equation
        Debug.fprintln("failtrace", "- Not yet implemented: Converting record calls (not constructor) into boxed records");
      then fail();

    case (e as DAE.CREF(cref,_), t1 as (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), complexVarLst = v),SOME(path)), (DAE.T_BOXED(t2),_),polymorphicBindings,matchFunc,printFailtrace)
      local
        Absyn.Path path;
        list<Absyn.Path> pathList;
        DAE.ComponentRef cref;
        list<DAE.ComponentRef> crefList;
        list<DAE.ExpType> expTypes;
      equation
        true = subtype(t1,t2);
        t2 = (DAE.T_BOXED(t1),NONE);
        l = Util.listMap(v, getVarName);
        tys1 = Util.listMap(v, getVarType);
        tys2 = Util.listMap(tys1, boxIfUnboxedType);
        expTypes = Util.listMap(tys1, elabType);
        pathList = Util.listMap(l, Absyn.makeIdentPathFromString);
        crefList = Util.listMap(pathList, Exp.pathToCref);
        crefList = Util.listMap1r(crefList, Exp.joinCrefs, cref);
        elist = Util.listThreadMap(crefList, expTypes, Exp.makeCrefExp);
        (elist,_,polymorphicBindings) = matchTypeTuple(elist, tys1, tys2, polymorphicBindings,matchFunc,printFailtrace);
        e_1 = DAE.METARECORDCALL(path, elist, l, 0);
      then (e_1,t2,polymorphicBindings);

    case (e,(DAE.T_BOXED(t1),_),t2 as (DAE.T_INTEGER(_),_),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = subtype(t1,t2);
        (e_1,_,polymorphicBindings) = matchFunc(e,t1,t2,polymorphicBindings,printFailtrace);
      then
        (DAE.CALL(Absyn.IDENT("mmc_unbox_integer"),{e_1},false,true,DAE.ET_INT,DAE.NO_INLINE),t2,polymorphicBindings);
    case (e,(DAE.T_BOXED(t1),_),t2 as (DAE.T_REAL(_),_),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = subtype(t1,t2);
        (e_1,_,polymorphicBindings) = matchFunc(e,t1,t2,polymorphicBindings,printFailtrace);
      then
        (DAE.CALL(Absyn.IDENT("mmc_unbox_real"),{e_1},false,true,DAE.ET_REAL,DAE.NO_INLINE),t2,polymorphicBindings);
    case (e,(DAE.T_BOXED(t1),_),t2 as (DAE.T_BOOL(_),_),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = subtype(t1,t2);
        (e_1,_,polymorphicBindings) = matchFunc(e,t1,t2,polymorphicBindings,printFailtrace);
      then
        (DAE.CALL(Absyn.IDENT("mmc_unbox_integer"),{e_1},false,true,DAE.ET_BOOL,DAE.NO_INLINE),t2,polymorphicBindings);
    case (e,(DAE.T_BOXED(t1),_),t2 as (DAE.T_STRING(_),_),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = subtype(t1,t2);
        (e_1,_,polymorphicBindings) = matchFunc(e,t1,t2,polymorphicBindings,printFailtrace);
      then
        (DAE.CALL(Absyn.IDENT("mmc_unbox_string"),{e_1},false,true,DAE.ET_STRING,DAE.NO_INLINE),t2,polymorphicBindings);
    case (e,(DAE.T_BOXED(t1),_),t2 as (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), complexVarLst = v),_),polymorphicBindings,matchFunc,printFailtrace)
      equation
        true = subtype(t1,t2);
        (e_1,t2,polymorphicBindings) = matchFunc(e,t1,t2,polymorphicBindings,printFailtrace);
        t = elabType(t2);
      then
        (DAE.CALL(Absyn.IDENT("mmc_unbox_record"),{e_1},false,true,t,DAE.NO_INLINE),t2,polymorphicBindings);

    // MM Function Reference. sjoelund
    case (e as DAE.CREF(_,_),(DAE.T_FUNCTION(farg1,t1,_),p1),(DAE.T_FUNCTION(farg2,t2,_),_),polymorphicBindings,matchFunc,printFailtrace)
      local
        list<FuncArg> farg,farg1,farg2;
        list<Type> tList1,tList2;
        list<Ident> fargId1;
        list<DAE.Exp> exps;
      equation
        tList1 = Util.listMap(farg1, Util.tuple22);
        tList2 = Util.listMap(farg2, Util.tuple22);
        fargId1 = Util.listMap(farg1, Util.tuple21);
        exps = Util.listFill(e, listLength(farg1));
        (_,tys1,polymorphicBindings) = matchTypeTuple(exps,tList1,tList2,polymorphicBindings,matchFunc,printFailtrace);
        (_,ty1,polymorphicBindings) = matchFunc(e,t1,t2,polymorphicBindings,printFailtrace);
        farg = Util.listThreadMap(fargId1,tys1,Util.makeTuple2);
        ty2 = (DAE.T_FUNCTION(farg,ty1,DAE.NO_INLINE),p1);
      then (e,ty2,polymorphicBindings);

      /* See printFailure()
    case (exp,t1,t2,polymorphicBindings,matchFunc,printFailtrace)
      equation
        Debug.fprint("tcvt", "- type conversion failed: ");
        str = Exp.printExpStr(exp);
        Debug.fprint("tcvt", str);
        Debug.fprint("tcvt", "  ");
        str = unparseType(t1);
        Debug.fprint("tcvt", str);
        Debug.fprint("tcvt", ", ");
        str = unparseType(t2);
        Debug.fprint("tcvt", str);
        Debug.fprint("tcvt", "\n");
      then
        fail();
      */
  end matchcontinue;
end typeConvert;

protected function liftExpType "help funciton to typeConvert. Changes the DAE.ExpType stored
in expression (which is typically a CAST) by adding a dimension to it, making it into an array
type."
 input DAE.Exp e;
 input DAE.Dimension dim;
 output DAE.Exp res;
algorithm
  res := matchcontinue(e,dim)
  local DAE.ExpType ty,ty1;
    case(DAE.CAST(ty,e),dim)
      equation
        ty1 = Exp.liftArrayR(ty,dim);

      then DAE.CAST(ty1,e);

    case(e,dim) then e;
  end matchcontinue;
end liftExpType;

public function typeConvertArray "function: typeConvertArray

  Helper function to type_convert. Handles array expressions.
"
  input list<DAE.Exp> inExpExpLst1;
  input Type inType2;
  input Type inType3;
  input DAE.Dimension dim;
  input PolymorphicBindings polymorphicBindings;
  input MatchTypeFunc matchFunc;
  input Boolean printFailtrace;
  output list<DAE.Exp> outExpExpLst;
  output PolymorphicBindings outBindings;

  partial function MatchTypeFunc
    input DAE.Exp inExp1;
    input Type inType2;
    input Type inType3;
    input PolymorphicBindings polymorphicBindings;
    input Boolean printFailtrace;
    output DAE.Exp outExp;
    output Type outType;
    output PolymorphicBindings outBindings;
  end MatchTypeFunc;
algorithm
  (outExpExpLst,outBindings) :=
  matchcontinue (inExpExpLst1,inType2,inType3,dim,polymorphicBindings,matchFunc,printFailtrace)
    local
      list<DAE.Exp> rest_1,rest;
      DAE.Exp first_1,first;
      Type ty1,ty2;
    case ({},_,_,_,polymorphicBindings,_,_) then ({},polymorphicBindings);
    case ((first :: rest),ty1,ty2,dim,polymorphicBindings,matchFunc,printFailtrace)
      equation
        (rest_1,polymorphicBindings) = typeConvertArray(rest,ty1,ty2,dim,polymorphicBindings,matchFunc,printFailtrace);
        (first_1,_,polymorphicBindings) = typeConvert(first,ty1,ty2,polymorphicBindings,matchFunc,printFailtrace);
         //first_1 = liftExpType(first_1,dim);
      then
        ((first_1 :: rest_1),polymorphicBindings);
  end matchcontinue;
end typeConvertArray;

protected function typeConvertMatrix "function: typeConvertMatrix

  Helper function to type_convert. Handles matrix expressions.
"
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst1;
  input Type inType2;
  input Type inType3;
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  input PolymorphicBindings polymorphicBindings;
  input MatchTypeFunc matchFunc;
  input Boolean printFailtrace;
  output list<list<tuple<DAE.Exp, Boolean>>> outTplExpExpBooleanLstLst;
  output PolymorphicBindings outBindings;

	partial function MatchTypeFunc
	  input DAE.Exp inExp1;
	  input Type inType2;
	  input Type inType3;
	  input PolymorphicBindings polymorphicBindings;
    input Boolean printFailtrace;
    output DAE.Exp outExp;
    output Type outType;
    output PolymorphicBindings outBindings;
  end MatchTypeFunc;
algorithm
  (outTplExpExpBooleanLstLst,outBindings) :=
  matchcontinue (inTplExpExpBooleanLstLst1,inType2,inType3,dim1,dim2,polymorphicBindings,matchFunc,printFailtrace)
    local
      list<list<tuple<DAE.Exp, Boolean>>> rest_1,rest;
      list<tuple<DAE.Exp, Boolean>> first_1,first;
      Type ty1,ty2;
    case ({},_,_,_,_,polymorphicBindings,_,_) then ({},polymorphicBindings);
    case ((first :: rest),ty1,ty2,dim1,dim2,polymorphicBindings,matchFunc,printFailtrace)
      equation
        (rest_1,polymorphicBindings) = typeConvertMatrix(rest, ty1, ty2,dim1,dim2,polymorphicBindings,matchFunc,printFailtrace);
        (first_1,polymorphicBindings) = typeConvertMatrixRow(first, ty1, ty2,dim1,dim2,polymorphicBindings,matchFunc,printFailtrace);
      then
        ((first_1 :: rest_1),polymorphicBindings);
  end matchcontinue;
end typeConvertMatrix;

protected function typeConvertMatrixRow "function: typeConvertMatrixRow

  Helper function to type_convert_matrix.
"
  input list<tuple<DAE.Exp, Boolean>> inTplExpExpBooleanLst1;
  input Type inType2;
  input Type inType3;
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  input PolymorphicBindings polymorphicBindings;
  input MatchTypeFunc matchFunc;
  input Boolean printFailtrace;
  output list<tuple<DAE.Exp, Boolean>> outTplExpExpBooleanLst;
  output PolymorphicBindings outBindings;

	partial function MatchTypeFunc
	  input DAE.Exp inExp1;
	  input Type inType2;
	  input Type inType3;
	  input PolymorphicBindings polymorphicBindings;
    input Boolean printFailtrace;
    output DAE.Exp outExp;
    output Type outType;
    output PolymorphicBindings outBindings;
  end MatchTypeFunc;
algorithm
  (outTplExpExpBooleanLst,outBindings) :=
  matchcontinue (inTplExpExpBooleanLst1,inType2,inType3,dim1,dim2,polymorphicBindings,matchFunc,printFailtrace)
    local
      list<tuple<DAE.Exp, Boolean>> rest;
      DAE.Exp exp_1,exp;
      Type newt,t1,t2;
      Boolean a,sc;
    case ({},_,_,_,_,polymorphicBindings,_,_) then ({},polymorphicBindings);
    case (((exp,_) :: rest),t1,t2,dim1,dim2,polymorphicBindings,matchFunc,printFailtrace)
      equation
        (rest,polymorphicBindings) = typeConvertMatrixRow(rest, t1, t2,dim1,dim2,polymorphicBindings,matchFunc,printFailtrace);
        (exp_1,newt,polymorphicBindings) = typeConvert(exp, t1, t2,polymorphicBindings,matchFunc,printFailtrace);
        //exp_1 = liftExpType(exp_1,dim1);
        //exp_1 = liftExpType(exp_1,dim2);
        a = isArray(t2);
        sc = boolNot(a);
      then
        (((exp_1,sc) :: rest),polymorphicBindings);
  end matchcontinue;
end typeConvertMatrixRow;

protected function typeConvertList "function: typeConvertList

  Helper function to type_convert.
"
  input list<DAE.Exp> inExpExpLst1;
  input list<Type> inTypeLst2;
  input list<Type> inTypeLst3;
  input PolymorphicBindings polymorphicBindings;
  input MatchTypeFunc matchFunc;
  input Boolean printFailtrace;
  output list<DAE.Exp> outExpExpLst;
  output list<Type> outTypeLst;
  output PolymorphicBindings outBindings;

	partial function MatchTypeFunc
	  input DAE.Exp inExp1;
	  input Type inType2;
	  input Type inType3;
	  input PolymorphicBindings polymorphicBindings;
    input Boolean printFailtrace;
    output DAE.Exp outExp;
    output Type outType;
    output PolymorphicBindings outBindings;
  end MatchTypeFunc;
algorithm
  (outExpExpLst,outTypeLst,outBindings):=
  matchcontinue (inExpExpLst1,inTypeLst2,inTypeLst3,polymorphicBindings,matchFunc,printFailtrace)
    local
      list<DAE.Exp> rest_1,rest;
      list<Type> tyrest_1,ty1rest,ty2rest;
      DAE.Exp first_1,first;
      Type ty_1,ty1,ty2;
    case ({},_,_,polymorphicBindings,_,_) then ({},{},polymorphicBindings);
    case ((first :: rest),(ty1 :: ty1rest),(ty2 :: ty2rest),polymorphicBindings,matchFunc,printFailtrace)
      equation
        (rest_1,tyrest_1,polymorphicBindings) = typeConvertList(rest, ty1rest, ty2rest,polymorphicBindings,matchFunc,printFailtrace);
        (first_1,ty_1,polymorphicBindings) = typeConvert(first, ty1, ty2, polymorphicBindings,matchFunc,printFailtrace);
      then
        ((first_1 :: rest_1),(ty_1 :: tyrest_1),polymorphicBindings);
  end matchcontinue;
end typeConvertList;

protected function typeConvertMatrixToList
  input list<list<DAE.Exp>> melist;
  input Type inType;
  input Type outType;
  input PolymorphicBindings polymorphicBindings;
  input MatchTypeFunc matchFunc;
  input Boolean printFailtrace;
  output list<DAE.Exp> outExp;
  output Type outType;
  output PolymorphicBindings outBindings;

	partial function MatchTypeFunc
	  input DAE.Exp inExp1;
	  input Type inType2;
	  input Type inType3;
	  input PolymorphicBindings polymorphicBindings;
	  input Boolean printFailtrace;
	  output DAE.Exp outExp;
	  output Type outType;
	  output PolymorphicBindings outBindings;
	end MatchTypeFunc;
algorithm
  (outExp,outType,outBindings) := matchcontinue (melist,inType,outType,polymorphicBindings,matchFunc,printFailtrace)
    local
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> rest, elist, elist_1;
      DAE.ExpType t;
      list<DAE.ExpType> tlist;
      Type t1,t2,t_1;
      list<Type> tys1;
      Option<Absyn.Path> p2;
      DAE.Exp e,e_1;
    case ({},_,_,polymorphicBindings,_,_) then ({},(DAE.T_NOTYPE,NONE),polymorphicBindings);
    case (expl::rest, (DAE.T_ARRAY(arrayType=(DAE.T_ARRAY(arrayType=t1),_)),_), (DAE.T_LIST((DAE.T_LIST(t2),_)),p2),polymorphicBindings,matchFunc,printFailtrace)
      equation
        (e,t1,polymorphicBindings) = typeConvertMatrixRowToList(expl, t1, t2, polymorphicBindings,matchFunc,printFailtrace);
        t = elabType(t1);
        (expl,_,polymorphicBindings) = typeConvertMatrixToList(rest, inType, outType, polymorphicBindings,matchFunc,printFailtrace);
      then (e::expl,(DAE.T_LIST(t1),NONE),polymorphicBindings);
    case (_, _, _, _, _, _)
      equation
        Debug.fprintln("types", "- typeConvertMatrixToList failed");
      then fail();
  end matchcontinue;
end typeConvertMatrixToList;

protected function typeConvertMatrixRowToList
  input list<DAE.Exp> elist;
  input Type inType;
  input Type outType;
  input PolymorphicBindings polymorphicBindings;
  input MatchTypeFunc matchFunc;
  input Boolean printFailtrace;
  output DAE.Exp out;
  output Type t1;
  output PolymorphicBindings outBindings;
  partial function MatchTypeFunc
    input DAE.Exp inExp1;
    input Type inType2;
    input Type inType3;
    input PolymorphicBindings polymorphicBindings;
    input Boolean printFailtrace;
    output DAE.Exp outExp;
    output Type outType;
    output PolymorphicBindings outBindings;
  end MatchTypeFunc;
  DAE.Exp exp;
  list<DAE.Exp> elist_1;
  DAE.ExpType t;
algorithm
  (elist_1,t1::_,outBindings) := matchTypeList(elist, inType, outType, polymorphicBindings,matchFunc,printFailtrace);
  t := elabType(t1);
  out := DAE.LIST(t, elist_1);
  t1 := (DAE.T_LIST(t1),NONE);
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
      Option<Absyn.Path> p2,p;
      Boolean havereal;
      list<Var> v;
      TType tt;

    case (DAE.PROP((DAE.T_COMPLEX(_,_,SOME(t1),_),_),c1),DAE.PROP(t2,c2),havereal)
      then matchWithPromote(DAE.PROP(t1,c1),DAE.PROP(t2,c2),havereal);

    case (DAE.PROP(t1,c1),DAE.PROP((DAE.T_COMPLEX(_,_,SOME(t2),_),_),c2),havereal)
      then matchWithPromote(DAE.PROP(t1,c1),DAE.PROP(t2,c2),havereal);

    case (DAE.PROP(type_ = (DAE.T_ARRAY(arrayDim = dim1,arrayType = t1),_),constFlag = c1),
          DAE.PROP(type_ = (DAE.T_ARRAY(arrayDim = dim2,arrayType = t2),p2),constFlag = c2),
          havereal) // Allow Integer => Real
      equation
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
        dim = dim1;
      then
        DAE.PROP((DAE.T_ARRAY(dim,t),p2),c);
    // match integer, second
    case (DAE.PROP(type_ = t1,constFlag = c1),
          DAE.PROP(type_ = (DAE.T_ARRAY(arrayDim = DAE.DIM_INTEGER(1),arrayType = t2),p2),constFlag = c2),
          havereal)
      equation
        false = isArray(t1);
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP((DAE.T_ARRAY(DAE.DIM_INTEGER(1),t),p2),c);
    // match enum, second
    case (DAE.PROP(type_ = t1,constFlag = c1),
          DAE.PROP(type_ = (DAE.T_ARRAY(arrayDim = dim as DAE.DIM_ENUM(size=1),arrayType = t2),p2),constFlag = c2),
          havereal)
      equation
        false = isArray(t1);
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP((DAE.T_ARRAY(dim,t),p2),c);
    // match integer, first
    case (DAE.PROP(type_ = (DAE.T_ARRAY(arrayDim = DAE.DIM_INTEGER(1),arrayType = t1),p),constFlag = c1),
          DAE.PROP(type_ = t2,constFlag = c2),havereal)
      equation
        false = isArray(t2);
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP((DAE.T_ARRAY(DAE.DIM_INTEGER(1),t),p),c);
    // match enum, first
    case (DAE.PROP(type_ = (DAE.T_ARRAY(arrayDim = dim as DAE.DIM_ENUM(size=1),arrayType = t1),p),constFlag = c1),
          DAE.PROP(type_ = t2,constFlag = c2),havereal)
      equation
        false = isArray(t2);
        DAE.PROP(t,c) = matchWithPromote(DAE.PROP(t1,c1), DAE.PROP(t2,c2), havereal);
      then
        DAE.PROP((DAE.T_ARRAY(dim,t),p),c);
    // equal types
    case (DAE.PROP(type_ = t1,constFlag = c1),
          DAE.PROP(type_ = t2,constFlag = c2),false)
      equation
        false = isArray(t1);
        false = isArray(t2);
        equality(t1 = t2);
        c = constAnd(c1, c2);
      then
        DAE.PROP(t1,c);
    // enums
    case (DAE.PROP(type_ = (tt as DAE.T_ENUMERATION(literalVarLst = v),_),constFlag = c1),
          DAE.PROP(type_ = (DAE.T_ENUMERATION(index = _),p2),constFlag = c2), false)
      equation
        c = constAnd(c1, c2) "Have enum and both Enum" ;
      then
        DAE.PROP((tt,p2),c);
    // reals
    case (DAE.PROP(type_ = (DAE.T_REAL(varLstReal = v),_),constFlag = c1),
          DAE.PROP(type_ = (DAE.T_REAL(varLstReal = _),p2),constFlag = c2),true)
      equation
        c = constAnd(c1, c2) "Have real and both Real" ;
      then
        DAE.PROP((DAE.T_REAL(v),p2),c);
    // integer vs. real
    case (DAE.PROP(type_ = (DAE.T_INTEGER(varLstInt = _),_),constFlag = c1),
          DAE.PROP(type_ = (DAE.T_REAL(varLstReal = v),p2),constFlag = c2),true)
      equation
        c = constAnd(c1, c2) "Have real and first Integer" ;
      then
        DAE.PROP((DAE.T_REAL(v),p2),c);
    // real vs. integer
    case (DAE.PROP(type_ = (DAE.T_REAL(varLstReal = v),_),constFlag = c1),
          DAE.PROP(type_ = (DAE.T_INTEGER(varLstInt = _),p2),constFlag = c2),true)
      equation
        c = constAnd(c1, c2) "Have real and second Integer" ;
      then
        DAE.PROP((DAE.T_REAL(v),p2),c);
    // both integers
    case (DAE.PROP(type_ = (DAE.T_INTEGER(varLstInt = _),_),constFlag = c1),
          DAE.PROP(type_ = (DAE.T_INTEGER(varLstInt = _),p2),constFlag = c2),true)
      equation
        c = constAnd(c1, c2) "Have real and both Integer" ;
      then
        DAE.PROP(DAE.T_REAL_DEFAULT,c);
  
    case(inProperties1,inProperties2,inBoolean3) 
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace","- Types.matchWithPromote failed on: " +& 
           "\nprop1: " +& printPropStr(inProperties1) +&
           "\nprop2: " +& printPropStr(inProperties2) +&
           "\nhaveReal: " +& Util.if_(inBoolean3, "true", "false"));
      then fail();
  end matchcontinue;
end matchWithPromote;

public function constAnd "function: constAnd

  Returns the \'and\' operator of two Const\'s. I.e. C_CONST iff. both are
  C_CONST, C_PARAM iff both are C_PARAM (or one of them C_CONST),
  V_VAR otherwise.
"
  input Const inConst1;
  input Const inConst2;
  output Const outConst;
algorithm
  outConst:=
  matchcontinue (inConst1,inConst2)
    case (DAE.C_CONST(),DAE.C_CONST()) then DAE.C_CONST();
    case (DAE.C_CONST(),DAE.C_PARAM()) then DAE.C_PARAM();
    case (DAE.C_PARAM(),DAE.C_CONST()) then DAE.C_PARAM();
    case (DAE.C_PARAM(),DAE.C_PARAM()) then DAE.C_PARAM();
    case (_,_) then DAE.C_VAR();
  end matchcontinue;
end constAnd;

protected function constTupleAnd "function: constTupleAnd

  Returns the \'and\' operator of two TupleConst\'s
  For now, returns first tuple.
"
  input TupleConst inTupleConst1;
  input TupleConst inTupleConst2;
  output TupleConst outTupleConst;
algorithm
  outTupleConst:=
  matchcontinue (inTupleConst1,inTupleConst2)
    local TupleConst c1,c2;
    case (c1,c2) then c1;
  end matchcontinue;
end constTupleAnd;

public function constOr "function: constOr

  Returns the \'or\' operator of two Const\'s. I.e. C_CONST if some is
  C_CONST, C_PARAM if none is C_CONST but some is C_PARAM and
  V_VAR otherwise.
"
  input Const inConst1;
  input Const inConst2;
  output Const outConst;
algorithm
  outConst:=
  matchcontinue (inConst1,inConst2)
    case (DAE.C_CONST(),_) then DAE.C_CONST();
    case (_,DAE.C_CONST()) then DAE.C_CONST();
    case (DAE.C_PARAM(),_) then DAE.C_PARAM();
    case (_,DAE.C_PARAM()) then DAE.C_PARAM();
    case (_,_) then DAE.C_VAR();
  end matchcontinue;
end constOr;

public function boolConst "function: boolConst
  author: PA

  Creates a Const value from a bool. If true, C_CONST,
  if false C_VAR, i.e. there is no way to create a C_PARAM using this
  function."
  input Boolean inBoolean;
  output Const outConst;
algorithm
  outConst:=
  matchcontinue (inBoolean)
    case (false) then DAE.C_VAR();
    case (true) then DAE.C_CONST();
  end matchcontinue;
end boolConst;

public function boolConstSize "function: boolConstSize
  author: alleb
  
  A version of boolConst supposed to be used by Static.elabBuiltinSize.
  Creates a Const value from a bool. If true, C_CONST,
  if false C_PARAM."
  input Boolean inBoolean;
  output Const outConst;
algorithm
  outConst:=
  matchcontinue (inBoolean)
    case (false) then DAE.C_PARAM();
    case (true) then DAE.C_CONST();
  end matchcontinue;
end boolConstSize;

public function printPropStr "function: printPropStr
  Print the properties to a string."
  input Properties inProperties;
  output String outString;
algorithm
  outString := matchcontinue (inProperties)
    local
      Ident ty_str,const_str,res;
      Type ty;
      Const const;
    case DAE.PROP(type_ = ty,constFlag = const)
      equation
        ty_str = unparseType(ty);
        const_str = unparseConst(const);
        res = Util.stringAppendList({"DAE.PROP(",ty_str,", ",const_str,")"});
      then
        res;
    case DAE.PROP_TUPLE(type_ = ty,tupleConst = const)
      local TupleConst const;
      equation
        ty_str = unparseType(ty);
        const_str = unparseTupleconst(const);
        res = Util.stringAppendList({"DAE.PROP_TUPLE(",ty_str,", ",const_str,")"});
      then
        res;
  end matchcontinue;
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
      DAE.ExpType ty2;
      Type ty;
    
    // handle empty case
    case ({},_) then {};
    
    // we have a flow prefix
    case ((DAE.TYPES_VAR(name = id,attributes = DAE.ATTR(flowPrefix = true),type_ = ty) :: vs),cr)
      equation
        ty2 = elabType(ty);
        cr_1 = Exp.joinCrefs(cr, DAE.CREF_IDENT(id,ty2,{}));
        // print("\n created: " +& Exp.debugPrintComponentRefTypeStr(cr_1) +& "\n");
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
      DAE.ExpType ty2;
      Type ty;

    case ({},_) then {};
    case ((DAE.TYPES_VAR(name = id,attributes = DAE.ATTR(streamPrefix = true),type_ = ty) :: vs),cr)
      equation
        ty2 = elabType(ty);
        cr_1 = Exp.joinCrefs(cr, DAE.CREF_IDENT(id,ty2,{}));
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
  expressions and returns them in a list
"
  input Type inType;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inType)
    local
      list<DAE.Exp> exps;
      TType ttype;
      Option<Absyn.Path> pathopt;
    case ((ttype,pathopt))
      equation
        exps = getAllExpsTt(ttype);
      then
        exps;
  end matchcontinue;
end getAllExps;

protected function getAllExpsTt "function: getAllExpsTt

  This function goes through the TType structure and finds all the
  expressions and returns them in a list
"
  input TType inTType;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inTType)
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
    case DAE.T_INTEGER(varLstInt = vars)
      equation
        exps = getAllExpsVars(vars);
      then
        exps;
    case DAE.T_REAL(varLstReal = vars)
      equation
        exps = getAllExpsVars(vars);
      then
        exps;
    case DAE.T_STRING(varLstString = vars)
      equation
        exps = getAllExpsVars(vars);
      then
        exps;
    case DAE.T_BOOL(varLstBool = vars)
      equation
        exps = getAllExpsVars(vars);
      then
        exps;
    case DAE.T_ENUMERATION(names = strs, literalVarLst = vars, attributeLst = attrs)
      equation
        exps = getAllExpsVars(vars);
        tyexps = getAllExpsVars(attrs);
        exps = listAppend(exps, tyexps);
      then
        exps;
    case DAE.T_ARRAY(arrayDim = dim,arrayType = ty)
      equation
        exps = getAllExps(ty);
      then
        exps;
    case DAE.T_COMPLEX(complexClassType = cinf,complexVarLst = vars,complexTypeOption = bc)
      equation
        exps = getAllExpsVars(vars);
      then
        exps;
    case DAE.T_FUNCTION(funcArg = fargs,funcResultType = ty)
      equation
        tys = Util.listMap(fargs, Util.tuple22);
        explists = Util.listMap(tys, getAllExps);
        tyexps = getAllExps(ty);
        exps = Util.listFlatten((tyexps :: explists));
      then
        exps;
    case DAE.T_TUPLE(tupleType = tys)
      equation
        explist = Util.listMap(tys, getAllExps);
        exps = Util.listFlatten(explist);
      then
        exps;
    case DAE.T_METATUPLE(types = tys)
      equation
        exps = getAllExpsTt(DAE.T_TUPLE(tys));
      then
        exps;
    case DAE.T_UNIONTYPE(_) then {};
    case DAE.T_METAOPTION(ty)
      equation
        exps = getAllExps(ty);
      then
        exps;
    case DAE.T_LIST(ty)
      equation
        exps = getAllExps(ty);
      then exps;
    case DAE.T_META_ARRAY(ty)
      equation
        exps = getAllExps(ty);
      then exps;
    case DAE.T_BOXED(ty)
      equation
        exps = getAllExps(ty);
      then exps;
    case DAE.T_POLYMORPHIC(_) then {};

    case(DAE.T_NOTYPE()) then {};
    case(DAE.T_NORETCALL()) then {};

    case tty
      local
        TType tty;
        String str;
      equation
        true = RTOpts.debugFlag("failtrace");
        str = unparseType((tty,NONE));
        Debug.fprintln("failtrace", "-- Types.getAllExpsTt failed " +& str);
      then
        fail();
  end matchcontinue;
end getAllExpsTt;

protected function getAllExpsVars "function: getAllExpsVars

  Helper function to get_all_exps_tt.
"
  input list<Var> vars;
  output list<DAE.Exp> exps;
  list<list<DAE.Exp>> explist;
algorithm
  explist := Util.listMap(vars, getAllExpsVar);
  exps := Util.listFlatten(explist);
end getAllExpsVars;

protected function getAllExpsVar "function: getAllExpsVar

  Helper function to get_all_exps_vars.
"
  input Var inVar;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inVar)
    local
      list<DAE.Exp> tyexps,bndexp,exps;
      Ident id;
      Attributes attr;
      Boolean prot;
      Type ty;
      Binding bnd;
    case DAE.TYPES_VAR(name = id,attributes = attr,protected_ = prot,type_ = ty,binding = bnd)
      equation
        tyexps = getAllExps(ty);
        bndexp = getAllExpsBinding(bnd);
        exps = listAppend(tyexps, bndexp);
      then
        exps;
  end matchcontinue;
end getAllExpsVar;

protected function getAllExpsBinding "function: getAllExpsBinding

  Helper function to get_all_exps_var.
"
  input Binding inBinding;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inBinding)
    local
      DAE.Exp exp;
      Const cnst;
      Values.Value v;
    case DAE.EQBOUND(exp = exp,constant_ = cnst) then {exp};
    case DAE.UNBOUND() then {};
    case DAE.VALBOUND(valBound = v) then {};
    case _
      equation
        Debug.fprintln("failtrace", "-- Types.getAllExpsBinding failed");
      then
        fail();
  end matchcontinue;
end getAllExpsBinding;

public function isBoxedType
  input Type ty;
  output Boolean b;
algorithm
  b := matchcontinue (ty)
    case ((DAE.T_METAOPTION(_),_)) then true;
    case ((DAE.T_LIST(_),_)) then true;
    case ((DAE.T_METATUPLE(_),_)) then true;
    case ((DAE.T_UNIONTYPE(_),_)) then true;
    case ((DAE.T_POLYMORPHIC(_),_)) then true;
    case ((DAE.T_META_ARRAY(_),_)) then true;
    case ((DAE.T_FUNCTION(_,_,_),_)) then true;
    case ((DAE.T_BOXED(_),_)) then true;
    case _ then false;
  end matchcontinue;
end isBoxedType;

public function boxIfUnboxedType
  input Type ty;
  output Type outType;
algorithm
  outType := Util.if_(isBoxedType(ty), ty, (DAE.T_BOXED(ty),NONE));
end boxIfUnboxedType;

public function unboxedType
  input Type ty;
  output Type out;
algorithm
  out := matchcontinue (ty)
    case ((DAE.T_METAOPTION(_),_)) then ty;
    case ((DAE.T_LIST(_),_)) then ty;
    case ((DAE.T_METATUPLE(_),_)) then ty;
    case ((DAE.T_UNIONTYPE(_),_)) then ty;
    case ((DAE.T_POLYMORPHIC(_),_)) then ty;
    case ((DAE.T_META_ARRAY(_),_)) then ty;
    case ((DAE.T_BOXED(ty),_)) then ty;
    case ty then ty;
  end matchcontinue;
end unboxedType;

public function listMatchSuperType "Takes lists of Exp,Type and calculates the
supertype of the list, then converts the expressions to this type. /sjoelund
"
  input list<DAE.Exp> elist;
  input list<Type> typeList;
  input PolymorphicBindings polymorphicBindings;
  input MatchTypeFunc matchFunc;
  input Boolean printFailtrace;
  output list<DAE.Exp> out;
  output Type t;
  output PolymorphicBindings outBindings;
  partial function MatchTypeFunc
    input DAE.Exp inExp1;
    input Type inType2;
    input Type inType3;
    input PolymorphicBindings polymorphicBindings;
    input Boolean printFailtrace;
    output DAE.Exp outExp;
    output Type outType;
    output PolymorphicBindings outBindings;
  end MatchTypeFunc;
algorithm
  (out,t,outBindings) := matchcontinue (elist,typeList,polymorphicBindings,matchFunc,printFailtrace)
    local
      DAE.Exp e;
      Type ty, superType;
    case ({},{},polymorphicBindings,_,_) then ({}, (DAE.T_NOTYPE,NONE),polymorphicBindings);
    case (e :: _, ty :: _,polymorphicBindings,matchFunc,printFailtrace)
      equation
        superType = Util.listReduce(typeList, superType);
        (elist,polymorphicBindings) = listMatchSuperType2(elist,typeList,superType,polymorphicBindings,matchFunc,printFailtrace);
      then (elist, superType, polymorphicBindings);
    case (_, _, _, _, _)
      equation
        Debug.fprintln("failtrace", "- Types.listMatchSuperType failed");
      then fail();
  end matchcontinue;
end listMatchSuperType;

protected function listMatchSuperType2
  input list<DAE.Exp> elist;
  input list<Type> typeList;
  input Type superType;
  input PolymorphicBindings polymorphicBindings;
  input MatchTypeFunc matchFunc;
  input Boolean printFailtrace;
  output list<DAE.Exp> out;
  output PolymorphicBindings outBindings;
  partial function MatchTypeFunc
    input DAE.Exp inExp1;
    input Type inType2;
    input Type inType3;
    input PolymorphicBindings polymorphicBindings;
    input Boolean printFailtrace;
    output DAE.Exp outExp;
    output Type outType;
    output PolymorphicBindings outBindings;
  end MatchTypeFunc;
algorithm
  (out,outBindings) := matchcontinue (elist, typeList, superType, polymorphicBindings, matchFunc, printFailtrace)
    local
      DAE.Exp e;
      list<DAE.Exp> erest;
      Type t;
      list<Type> trest;
    case ({},{},_,polymorphicBindings,_,_) then ({},polymorphicBindings);
    case (e::erest, t::trest, superType, polymorphicBindings, matchFunc, printFailtrace)
      equation
        (e,t,polymorphicBindings) = matchFunc(e,t,superType,polymorphicBindings,printFailtrace);
        (erest,polymorphicBindings) = listMatchSuperType2(erest,trest,superType,polymorphicBindings,matchFunc,printFailtrace);
      then (e::erest,polymorphicBindings);
    case (e::_, _, _, _, _, _)
      local String str;
      equation
        true = RTOpts.debugFlag("failtrace");
        str = Exp.printExpStr(e);
        Debug.fprintln("failtrace", "- Types.listMatchSuperType2 failed: " +& str);
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
      Type t1,t2,tp,tp2,tp1;
      list<Type> type_list1,type_list2;
    case ((DAE.T_ANYTYPE(_),_),t2) then t2;
    case (t1,(DAE.T_ANYTYPE(_),_)) then t1;
    case ((DAE.T_NOTYPE(),_),t2) then t2;
    case (t1,(DAE.T_NOTYPE(),_)) then t1;
    case (t1,t2 as (DAE.T_POLYMORPHIC(_),_)) then t2;

    case ((DAE.T_TUPLE(type_list1),_),(DAE.T_TUPLE(type_list2),_))
      equation
        type_list1 = Util.listThreadMap(type_list1,type_list2,superType);
      then ((DAE.T_TUPLE(type_list1),NONE));
    case ((DAE.T_TUPLE(type_list1),_),(DAE.T_METATUPLE(type_list2),_))
      equation
        type_list1 = Util.listThreadMap(type_list1,type_list2,superType);
      then ((DAE.T_METATUPLE(type_list1),NONE));
    case ((DAE.T_METATUPLE(type_list1),_),(DAE.T_TUPLE(type_list2),_))
      equation
        type_list1 = Util.listThreadMap(type_list1,type_list2,superType);
      then ((DAE.T_METATUPLE(type_list1),NONE));
    case ((DAE.T_METATUPLE(type_list1),_),(DAE.T_METATUPLE(type_list2),_))
      equation
        type_list1 = Util.listThreadMap(type_list1,type_list2,superType);
      then ((DAE.T_METATUPLE(type_list1),NONE));

    case ((DAE.T_LIST(t1),_),(DAE.T_LIST(t2),_))
      equation
        tp = superType(t1,t2);
      then ((DAE.T_LIST(tp),NONE));
    case ((DAE.T_METAOPTION(t1),_),(DAE.T_METAOPTION(t2),_))
      equation
        tp = superType(t1,t2);
      then ((DAE.T_METAOPTION(tp),NONE));
    case ((DAE.T_META_ARRAY(t1),_),(DAE.T_META_ARRAY(t2),_))
      equation
        tp = superType(t1,t2);
      then ((DAE.T_META_ARRAY(tp),NONE));

    case (t1 as (DAE.T_UNIONTYPE(lst),_),(DAE.T_METARECORD(_,_),SOME(path)))
      local
        list<Absyn.Path> lst;
        Absyn.Path path;
      equation
        true = listMember(path, lst);
      then t1;

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
bind polymorphic variabled. Used when elaborating calls.
TODO: We should probably just match types and then walk the type to
detect and verify any polymorphism."
  input DAE.Exp inExp1;
  input Type inType2;
  input Type inType3;
  input PolymorphicBindings polymorphicBindings;
  input Boolean printFailtrace;
  output DAE.Exp outExp;
  output Type outType;
  output PolymorphicBindings outBindings;
algorithm
  (outExp,outType,outBindings):=
  matchcontinue (inExp1,inType2,inType3,polymorphicBindings,printFailtrace)
    local
      DAE.Exp e,e_1;
      DAE.ExpType et;
      Type e_type,expected_type,e_type_1;
      String id;
    case (e,e_type,(DAE.T_POLYMORPHIC(id),_),polymorphicBindings,printFailtrace)
      equation
        (e_1,e_type_1) = matchType(e,e_type,(DAE.T_BOXED((DAE.T_NOTYPE,NONE)),NONE),printFailtrace);
      then (e_1,e_type_1,(id,e_type_1)::polymorphicBindings);
    case (e,e_type,expected_type,polymorphicBindings,_)
      equation
        true = subtype(e_type, expected_type);
      then
        (e,e_type,polymorphicBindings);
    case (e,e_type,expected_type,polymorphicBindings,printFailtrace)
      equation
        false = subtype(e_type, expected_type);
        (e_1,e_type_1,polymorphicBindings) = typeConvert(e, e_type, expected_type, polymorphicBindings, matchTypePolymorphic, printFailtrace);
      then
        (e_1,e_type_1,polymorphicBindings);
    case (e,e_type,expected_type,_,true)
      equation
        printFailure("types", "matchTypePolymorphic", e, e_type, expected_type);
      then fail();
  end matchcontinue;
end matchTypePolymorphic;

public function matchTypeRegular "function: matchType

  This function matches an expression with an expected type, and
  converts the expression to the expected type if necessary.
  inputs : (exp: DAE.Exp, exp_type: Type, expected: Type)
  outputs: (DAE.Exp, Type)"
  input DAE.Exp inExp1;
  input Type inType2;
  input Type inType3;
  input PolymorphicBindings polymorphicBindings;
  input Boolean printFailtrace;
  output DAE.Exp outExp;
  output Type outType;
  output PolymorphicBindings outBindings;
algorithm
  (outExp,outType,polymorphicBindings):=
  matchcontinue (inExp1,inType2,inType3,polymorphicBindings,printFailtrace)
    local
      DAE.Exp e,e_1;
      DAE.ExpType et;
      Type e_type,expected_type,e_type_1;
    case (e,e_type,expected_type,polymorphicBindings,printFailtrace)
      equation
        true = subtype(e_type, expected_type);
      then
        (e,e_type,polymorphicBindings);
    case (e,e_type,expected_type,polymorphicBindings,printFailtrace)
      equation
        false = subtype(e_type, expected_type);
        (e_1,e_type_1,polymorphicBindings) = typeConvert(e,e_type,expected_type,polymorphicBindings,matchTypeRegular,printFailtrace);
      then
        (e_1,e_type_1,polymorphicBindings);
    case (e,e_type,expected_type,_,true)
      equation
        printFailure("types", "matchTypeRegular", e, e_type, expected_type);
      then fail();
  end matchcontinue;
end matchTypeRegular;

protected function printFailure
"@author adrpo
 print the message only when flag is on.
 this is to speed up the flattening as we don't
 generate the strings at all."
  input String flag;
  input String source;
  input DAE.Exp e;
  input Type e_type;
  input Type expected_type;
algorithm
  _ := matchcontinue (flag, source, e, e_type, expected_type)
    case (flag, source, e, e_type, expected_type)
      equation
        true = RTOpts.debugFlag(flag);
        Debug.traceln("- Types." +& source +& " failed on:" +& Exp.printExpStr(e));
        Debug.traceln("  type:" +& unparseType(e_type) +& " differs from expected\n  type:" +& unparseType(expected_type));
      then ();
    case (flag, source, e, e_type, expected_type)
      equation
        false = RTOpts.debugFlag(flag);
      then ();
  end matchcontinue;
end printFailure;

public function fixPolymorphicRestype "TODO: This needs to be more generic so for example list<polymorphic<X>> is also translated"
  input Type ty;
  input PolymorphicBindings bindings;
  output Type resType;
algorithm
  resType := matchcontinue (ty, bindings)
    local
      String id;
      Type t1,t2;
      list<Type> tys;
    case ((DAE.T_POLYMORPHIC(id),_),bindings)
      then polymorphicBindingsLookup(id, bindings);
    case ((DAE.T_LIST(t1),_),bindings)
      equation
        t2 = fixPolymorphicRestype(t1, bindings);
        t2 = unboxedType(t2);
      then ((DAE.T_LIST(t2),NONE));
    case ((DAE.T_META_ARRAY(t1),_),bindings)
      equation
        t2 = fixPolymorphicRestype(t1, bindings);
        t2 = unboxedType(t2);
      then ((DAE.T_META_ARRAY(t2),NONE));
    case ((DAE.T_METAOPTION(t1),_),bindings)
      equation
        t2 = fixPolymorphicRestype(t1, bindings);
        t2 = unboxedType(t2);
      then ((DAE.T_METAOPTION(t2),NONE));
    case ((DAE.T_METATUPLE(tys),_),bindings)
      equation
        tys = Util.listMap1(tys, fixPolymorphicRestype, bindings);
        tys = Util.listMap(tys, unboxedType);
      then ((DAE.T_METATUPLE(tys),NONE));
    // Add Uniontype, Function reference(?)
    case (ty, bindings) then ty;
  end matchcontinue;
end fixPolymorphicRestype;

public function polymorphicBindingsLookup
  input String id;
  input PolymorphicBindings bindings;
  output Type resType;
algorithm
  resType := matchcontinue (id, bindings)
    local
      String id,id2;
      Type ty;
      PolymorphicBindings rest;
    case (id, (id2,ty)::_)
      equation
        true = id ==& id2;
        ty = Util.if_(isBoxedType(ty),ty,(DAE.T_BOXED(ty),NONE));
      then ty;
    case (id, _::rest)
      equation
        ty = polymorphicBindingsLookup(id,rest);
      then ty;
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
  outTypes := getAllInnerTypes(inType);
  outTypes := inType :: outTypes;
  outTypes := Util.listFilter(outTypes, inFn);
end getAllInnerTypesOfType;

public function getAllInnerTypes
"Traverses all the types the input Type contains."
  input Type inType;
  output list<Type> outTypes;
algorithm
  outTypes := matchcontinue inType
    local
      Type ty;
      list<Type> tys,res,res1,res2;
      list<list<Type>> resMap;
      list<Var> fields;
      list<FuncArg> funcArgs;
    case ((DAE.T_ARRAY(arrayType = ty),_)) equation res = getAllInnerTypes(ty); then inType::res;
    case ((DAE.T_LIST(ty),_)) equation res = getAllInnerTypes(ty); then inType::res;
    case ((DAE.T_BOXED(ty),_)) equation res = getAllInnerTypes(ty); then inType::res;
    case ((DAE.T_METAOPTION(ty),_)) equation res = getAllInnerTypes(ty); then inType::res;

    case ((DAE.T_TUPLE(tys),_))
      equation
        resMap = Util.listMap(tys, getAllInnerTypes);
        res = Util.listFlatten(resMap);
        res = inType::res;
      then res;
    case ((DAE.T_METATUPLE(tys),_))
      equation
        resMap = Util.listMap(tys, getAllInnerTypes);
        res = Util.listFlatten(resMap);
        res = inType::res;
      then res;

    case ((DAE.T_METARECORD(fields = fields),_))
      equation
        tys = Util.listMap(fields, getVarType);
        resMap = Util.listMap(tys, getAllInnerTypes);
        res = Util.listFlatten(resMap);
        res = inType::res;
      then res;
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_),complexVarLst = fields),_))
     equation
        tys = Util.listMap(fields, getVarType);
        resMap = Util.listMap(tys, getAllInnerTypes);
        res = Util.listFlatten(resMap);
        res = inType::res;
      then res;

    case ((DAE.T_FUNCTION(funcArgs,ty,_),_))
      equation
        tys = Util.listMap(funcArgs, Util.tuple22);
        resMap = Util.listMap(tys, getAllInnerTypes);
        res1 = Util.listFlatten(resMap);
        res1 = inType::res1;
        res2 = getAllInnerTypes(ty);
        res = listAppend(res1, ty::res2);
      then res;

    case ty then {ty};
  end matchcontinue;
end getAllInnerTypes;

public function uniontypeFilter
  input Type ty;
algorithm
  _ := matchcontinue ty
    case ((DAE.T_UNIONTYPE(_),_)) then ();
  end matchcontinue;
end uniontypeFilter;

public function metarecordFilter
  input Type ty;
algorithm
  _ := matchcontinue ty
    case ((DAE.T_METARECORD(_,_),_)) then ();
  end matchcontinue;
end metarecordFilter;

public function getUniontypePaths
  input Type ty;
  output list<Absyn.Path> outPaths;
algorithm
  outPaths := matchcontinue ty
    local
      list<Absyn.Path> paths;
    case ((DAE.T_UNIONTYPE(paths),_)) then paths;
  end matchcontinue;
end getUniontypePaths;

public function makeFunctionPolymorphicReference
"Takes a function reference. If it contains any types that are not boxed, we
return a reference to the function that does take boxed types. Else, we
return a reference to the regular function."
  input Type inType;
  output Type outType;
algorithm
  outType := matchcontinue (inType)
    local
      list<FuncArg> funcArgs1,funcArgs2;
      list<String> funcArgNames;
      list<Type> funcArgTypes1, funcArgTypes2, dummyBoxedTypeList;
      list<DAE.Exp> dummyExpList;
      Type ty1,ty2,resType1,resType2;
      TType tty1,tty2;
      Absyn.Path path;
    case (((tty1 as DAE.T_FUNCTION(funcArgs1,resType1,_)),SOME(path)))
      equation
        funcArgNames = Util.listMap(funcArgs1, Util.tuple21);
        funcArgTypes1 = Util.listMap(funcArgs1, Util.tuple22);
        (dummyExpList,dummyBoxedTypeList) = makeDummyExpAndTypeLists(funcArgTypes1);
        (_,funcArgTypes2,_) = matchTypeTuple(dummyExpList, funcArgTypes1, dummyBoxedTypeList, {}, matchTypeRegular, false);
        funcArgs2 = Util.listThreadTuple(funcArgNames,funcArgTypes2);
        resType2 = makeFunctionPolymorphicReferenceResType(resType1);
        tty2 = DAE.T_FUNCTION(funcArgs2,resType2,DAE.NO_INLINE);
        ty2 = (tty2,SOME(path));
      then ty2;
      /* Maybe add this case when standard Modelica gets function references?
    case (ty1 as (tty1 as DAE.T_FUNCTION(funcArgs1,resType),SOME(path)))
      local
        list<Boolean> boolList;
      equation
        funcArgTypes1 = Util.listMap(funcArgs1, Util.tuple22);
        boolList = Util.listMap(funcArgTypes1, isBoxedType);
        true = Util.listReduce(boolList, boolAnd);
      then ty1; */
    case _
      equation
        // Debug.fprintln("failtrace", "- Types.makeFunctionPolymorphicReference failed");
      then fail();
  end matchcontinue;
end makeFunctionPolymorphicReference;

protected function makeFunctionPolymorphicReferenceResType
  input Type inType;
  output Type outType;
algorithm
  outType := matchcontinue (inType)
    local
      Option<Absyn.Path> optPath;
      DAE.Exp e;
      Type ty,ty1,ty2;
      list<Type> tys, dummyBoxedTypeList;
      list<DAE.Exp> dummyExpList;
    case ((DAE.T_TUPLE(tys),optPath))
      equation
        (dummyExpList,dummyBoxedTypeList) = makeDummyExpAndTypeLists(tys);
        (_,tys,_) = matchTypeTuple(dummyExpList, tys, dummyBoxedTypeList, {}, matchTypeRegular, false);
      then ((DAE.T_TUPLE(tys),optPath));
    case (ty as (DAE.T_NORETCALL,_)) then ty;
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
  (outExps,outTypes) := matchcontinue (lst)
    local
      list<DAE.Exp> restExp;
      list<Type> restType, rest;
    case {} then ({},{});
    case _::rest
      equation
        (restExp,restType) = makeDummyExpAndTypeLists(rest);
      then (DAE.CREF(DAE.CREF_IDENT("#DummyExp#",DAE.ET_OTHER,{}),DAE.ET_OTHER)::restExp,(DAE.T_BOXED((DAE.T_NOTYPE,NONE)),NONE)::restType);
  end matchcontinue;
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
    case ((DAE.T_TUPLE(tys),_)) then tys;
    case ((DAE.T_NORETCALL,_)) then {};
    case ty then {ty};
  end matchcontinue;
end resTypeToListTypes;

public function getRealOrIntegerDimensions 
"If the type is a Real, Integer or an array of Real or Integer, the function returns 
list of dimensions; otherwise, it fails."
 input Type inType;
 output list<DAE.Dimension> outDims;
algorithm
  outType := matchcontinue (inType)
    local
      Type ty;
      DAE.Dimension d;
      list<DAE.Dimension> dims;
 
    case ((DAE.T_REAL(varLstReal=_),_))
      then
        {};
    case ((DAE.T_INTEGER(varLstInt=_),_))
      then
        {};
    case ((DAE.T_COMPLEX(_,_,SOME(ty),_),_))
      then getRealOrIntegerDimensions(ty);
    case ((DAE.T_ARRAY(arrayDim = d as DAE.DIM_INTEGER(integer = _),arrayType=ty),_))
      equation
        dims = getRealOrIntegerDimensions(ty);
      then
        d::dims;           
  end matchcontinue;
end getRealOrIntegerDimensions;

end Types;
