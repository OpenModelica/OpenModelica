package Types "
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

  
  file:	 Types.rml
  module:      Types
  description: Type system
 
  RCS: $Id$
 
  This file specifies the type system, as defined in the modelica
  specification. It contains an RML type called `Type\' which 
  defines types. It also contains functions for
  determining subtyping etc.
 
  There are a few known problems with this module.  It currently
  depends on `SCode.Attributes\', which in turn depends on
  `Absyn.ArrayDim\'.  However, the only things used from those
  modules are constants that could be moved to their own modules.
"

public import OpenModelica.Compiler.ClassInf;

public import OpenModelica.Compiler.Absyn;

public import OpenModelica.Compiler.Exp;

public import OpenModelica.Compiler.Values;

public import OpenModelica.Compiler.SCode;

public 
type Ident = String "- Identifiers" ;

public 
uniontype Var "- Variables"
  record VAR
    Ident name "name" ;
    Attributes attributes "attributes" ;
    Boolean protected_ "protected" ;
    Type type_ "type" ;
    Binding binding "binding ; equation modification" ;
  end VAR;

end Var;

public 
uniontype Attributes "- Attributes"
  record ATTR
    Boolean flow_ "flow" ;
    SCode.Accessibility accessibility "accessibility" ;
    SCode.Variability parameter_ "parameter" ;
    Absyn.Direction direction "direction" ;
  end ATTR;

end Attributes;

public 
uniontype Binding "- Binding"
  record UNBOUND end UNBOUND;

  record EQBOUND
    Exp.Exp exp "exp" ;
    Option<Values.Value> evaluatedExp "evaluatedExp; evaluated exp" ;
    Const constant_ "constant" ;
  end EQBOUND;

  record VALBOUND
    Values.Value valBound "valBound" ;
  end VALBOUND;

end Binding;

public 
type Type = tuple<TType, Option<Absyn.Path>> "
     A Type is a tuple of a TType (containing the actual type) and a optional classname
     for the class where the type originates from.

- Type" ;

public 
uniontype TType "-TType contains the actual type"
  record T_INTEGER
    list<Var> varLstInt "varLstInt" ;
  end T_INTEGER;

  record T_REAL
    list<Var> varLstReal "varLstReal" ;
  end T_REAL;

  record T_STRING
    list<Var> varLstString "varLstString" ;
  end T_STRING;

  record T_BOOL
    list<Var> varLstBool "varLstBool" ;
  end T_BOOL;

  record T_ENUM end T_ENUM;

  record T_ENUMERATION
    list<String> names "names" ;
    list<Var> varLst "varLst" ;
  end T_ENUMERATION;

  record T_ARRAY
    ArrayDim arrayDim "arrayDim" ;
    Type arrayType "arrayType" ;
  end T_ARRAY;

  record T_COMPLEX
    ClassInf.State complexClassType "complexClassType ; The type of. a class" ;
    list<Var> complexVarLst "complexVarLst ; The variables of a complex type" ;
    Option<Type> complexTypeOption "complexTypeOption ; A complex type can be a subtype of another (primitive) type (through extends). In that case the varlist is empty" ;
  end T_COMPLEX;

  record T_FUNCTION
    list<FuncArg> funcArg "funcArg" ;
    Type funcResultType "funcResultType ; Only single-result" ;
  end T_FUNCTION;

  record T_TUPLE
    list<Type> tupleType "tupleType ; For functions returning multiple values. Used when type is not yet determined" ;
  end T_TUPLE;

  record T_NOTYPE end T_NOTYPE;

  record T_ANYTYPE
    Option<ClassInf.State> anyClassType "anyClassType - used for generic types. When class state present the type is assumed to be a complex type which has that restriction." ;
  end T_ANYTYPE;

end TType;

public 
uniontype ArrayDim "- Array Dimensions"
  record DIM
    Option<Integer> integerOption;
  end DIM;

end ArrayDim;

public 
type FuncArg = tuple<Ident, Type> "- Function Argument" ;

public 
uniontype Const "The degree of constantness of an expression is determined by the Const 
    datatype. Variables declared as \'constant\' will get C_CONST constantness.
    Variables declared as \'parameter\' will get C_PARAM constantness and
    all other variables are not constant and will get C_VAR constantness.

  - Variable properties"
  record C_CONST end C_CONST;

  record C_PARAM "\'constant\'s, should always be evaluated" end C_PARAM;

  record C_VAR "\'parameter\'s, evaluated if structural not constants, never evaluated" end C_VAR;

end Const;

public 
uniontype TupleConst "A tuple is added to the Types. This is used by functions whom returns multiple arguments.
  Used by split_props
  - Tuple constants"
  record CONST
    Const const;
  end CONST;

  record TUPLE_CONST
    list<TupleConst> tupleConstLst "tupleConstLst" ;
  end TUPLE_CONST;

end TupleConst;

public 
uniontype Properties "P.R 1.1 for multiple return arguments from functions, 
    one constant flag for each return argument. 

  The datatype `Properties\' contain information about an
    expression.  The properties are created by analyzing the
    expressions.
  - Expression properties"
  record PROP
    Type type_ "type" ;
    Const constFlag "constFlag; if the type is a tuple, each element 
				          have a const flag." ;
  end PROP;

  record PROP_TUPLE
    Type type_;
    TupleConst tupleConst "tupleConst; The elements might be 
							    tuple themselfs." ;
  end PROP_TUPLE;

end Properties;

public 
uniontype EqMod "To generate the correct set of equations, the translator has to
  differentiate between the primitive types `Real\', `Integer\',
  `String\', `Boolean\' and types directly derived from then from
  other, complex types.  For arrays and matrices the type
  `T_ARRAY\' is used, with the first argument being the number of
  dimensions, and the second being the type of the objects in the
  array.  The `Type\' type is used to store
  information about whether a class is derived from a primitive
  type, and whether a variable is of one of these types.
  - Modification datatype, was originally in Mod"
  record TYPED
    Exp.Exp modifierAsExp "modifierAsExp ; modifier as expression" ;
    Option<Values.Value> modifierAsValue "modifierAsValue ; modifier as Value option" ;
    Properties properties "properties" ;
  end TYPED;

  record UNTYPED
    Absyn.Exp exp;
  end UNTYPED;

end EqMod;

public 
uniontype SubMod "-Sub Modification"
  record NAMEMOD
    Ident ident;
    Mod mod;
  end NAMEMOD;

  record IDXMOD
    list<Integer> integerLst;
    Mod mod;
  end IDXMOD;

end SubMod;

public 
uniontype Mod "Modification"
  record MOD
    Boolean final_ "final" ;
    Absyn.Each each_;
    list<SubMod> subModLst;
    Option<EqMod> eqModOption;
  end MOD;

  record REDECL
    Boolean final_ "final" ;
    list<tuple<SCode.Element, Mod>> tplSCodeElementModLst;
  end REDECL;

  record NOMOD end NOMOD;

end Mod;

protected import OpenModelica.Compiler.Dump;

protected import OpenModelica.Compiler.Debug;

protected import OpenModelica.Compiler.Print;

protected import OpenModelica.Compiler.Util;

protected import OpenModelica.Compiler.Static;

public function discreteType "function: discreteType
  author: PA
  
  Succeeds for all the discrete types, Integer, String, Boolean and 
  enumeration.
"
  input Type inType;
algorithm 
  _:=
  matchcontinue (inType)
    case ((T_INTEGER(varLstInt = _),_)) then (); 
    case ((T_STRING(varLstString = _),_)) then (); 
    case ((T_BOOL(varLstBool = _),_)) then (); 
    case ((T_ENUMERATION(names = _),_)) then (); 
  end matchcontinue;
end discreteType;

public function externalObjectType "author: PA
  
  Succeeds if type is ExternalObject
"
  input Type inType;
algorithm 
  _:=
  matchcontinue (inType)
    case ((T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_)),_)) then (); 
  end matchcontinue;
end externalObjectType;

public function externalObjectConstructorType "author: PA
  
  Succeeds if type is ExternalObject constructor function
"
  input Type inType;
algorithm 
  _:=
  matchcontinue (inType)
    case ((T_FUNCTION(funcResultType = tp),_)) 
      local Type tp;
      equation
        externalObjectType(tp);
      then (); 
  end matchcontinue;
end externalObjectConstructorType;


public function simpleType "function: simpleType
  author: PA
  
  Succeeds for all the builtin types, Integer, String, Real, Boolean
"
  input Type inType;
algorithm 
  _:=
  matchcontinue (inType)
    case ((T_REAL(varLstReal = _),_)) then (); 
    case ((T_INTEGER(varLstInt = _),_)) then (); 
    case ((T_STRING(varLstString = _),_)) then (); 
    case ((T_BOOL(varLstBool = _),_)) then (); 
  end matchcontinue;
end simpleType;

public function integerOrReal "function: integerOrReal 
  author: PA
  
  Succeeds for the builtin types Integer and Real.
"
  input Type inType;
algorithm 
  _:=
  matchcontinue (inType)
    case ((T_REAL(varLstReal = _),_)) then (); 
    case ((T_INTEGER(varLstInt = _),_)) then (); 
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
    case ((T_ARRAY(arrayDim = _),_)) then true; 
    case ((_,_)) then false; 
  end matchcontinue;
end isArray;

public function isString "function: isString
 
  Return true if Type is the builtin String type.
"
  input Type inType;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inType)
    case ((T_STRING(varLstString = _),_)) then true; 
    case ((_,_)) then false; 
  end matchcontinue;
end isString;

public function isArrayOrString "function: isArrayOrString
 
  Return true if Type is array or the builtin String type.
"
  input Type inType;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inType)
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
    case ((T_ARRAY(arrayType = t),_))
      equation 
        n = ndims(t);
      then
        n + 1;
    case ((_,_)) then 0; 
  end matchcontinue;
end ndims;

public function dimensionsKnown "function: dimensionsKnown
 
  Returns true of the dimensions of the type is known.
"
  input Type inType;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inType)
    local Type tp;
    case (tp)
      equation 
        {} = getDimensionSizes(tp);
      then
        false;
    case (tp)
      equation 
        _ = getDimensionSizes(tp);
      then
        true;
  end matchcontinue;
end dimensionsKnown;

public function stripSubmod "function: stripSubmod
  author: PA
  
  Removes the sub modifiers of a modifier.
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
    case (MOD(final_ = f,each_ = each_,subModLst = subs,eqModOption = eq)) then MOD(f,each_,{},eq); 
    case (m) then m; 
  end matchcontinue;
end stripSubmod;
  
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
      Integer i;
      Type tp;
    case ((T_ARRAY(arrayDim = DIM(integerOption = SOME(i)),arrayType = tp),_))
      equation 
        res = getDimensionSizes(tp);
      then
        (i :: res);
    case ((_,_)) then {}; 
  end matchcontinue;
end getDimensionSizes;

public function valuesToMods "function: valuesToMods
  author: PA
 
  This function takes a list of values and convert into a Modification.
   Used for record construction evaluation. PersonRecord(\"name\",45) has a value list 
  { \"name\",45 } that needs to be converted into a modifier for the record class
   PersonRecord (\"name,45)
   FIXME: How about other value types, e.g. array, enum etc 
"
  input list<Values.Value> inValuesValueLst;
  input list<Ident> inIdentLst;
  output Mod outMod;
algorithm 
  outMod:=
  matchcontinue (inValuesValueLst,inIdentLst)
    local
      list<SubMod> res;
      Integer i;
      list<Values.Value> rest,vals;
      Ident id,s,cname_str,vs;
      list<Ident> ids,val_names;
      Real r;
      Boolean b;
      Exp.Exp rec_call;
      list<Var> varlst;
      Absyn.Path cname;
      Values.Value v;
    case ({},_) then MOD(false,Absyn.NON_EACH(),{},NONE); 
    case ((Values.INTEGER(integer = i) :: rest),(id :: ids))
      equation 
        MOD(_,_,res,_) = valuesToMods(rest, ids);
      then
        MOD(false,Absyn.NON_EACH(),
          (NAMEMOD(id,
          MOD(false,Absyn.NON_EACH(),{},
          SOME(
          TYPED(Exp.ICONST(i),SOME(Values.INTEGER(i)),
          PROP((T_INTEGER({}),NONE),C_VAR()))))) :: res),NONE);
    case ((Values.REAL(real = r) :: rest),(id :: ids))
      equation 
        MOD(_,_,res,_) = valuesToMods(rest, ids);
      then
        MOD(false,Absyn.NON_EACH(),
          (NAMEMOD(id,
          MOD(false,Absyn.NON_EACH(),{},
          SOME(
          TYPED(Exp.RCONST(r),SOME(Values.REAL(r)),
          PROP((T_REAL({}),NONE),C_VAR()))))) :: res),NONE);
    case ((Values.STRING(string = s) :: rest),(id :: ids))
      equation 
        MOD(_,_,res,_) = valuesToMods(rest, ids);
      then
        MOD(false,Absyn.NON_EACH(),
          (NAMEMOD(id,
          MOD(false,Absyn.NON_EACH(),{},
          SOME(
          TYPED(Exp.SCONST(s),SOME(Values.STRING(s)),
          PROP((T_STRING({}),NONE),C_VAR()))))) :: res),NONE);
    case ((Values.BOOL(boolean = b) :: rest),(id :: ids))
      equation 
        MOD(_,_,res,_) = valuesToMods(rest, ids);
      then
        MOD(false,Absyn.NON_EACH(),
          (NAMEMOD(id,
          MOD(false,Absyn.NON_EACH(),{},
          SOME(
          TYPED(Exp.BCONST(b),SOME(Values.BOOL(b)),
          PROP((T_BOOL({}),NONE),C_VAR()))))) :: res),NONE);
    case ((Values.RECORD(record_ = cname,orderd = vals,comp = val_names) :: rest),(id :: ids))
      equation 
        MOD(_,_,res,_) = valuesToMods(rest, ids);
        rec_call = valuesToRecordConstructorCall(cname, vals);
        varlst = valuesToVars(vals, val_names);
        cname_str = Absyn.pathString(cname);
      then
        MOD(false,Absyn.NON_EACH(),
          (NAMEMOD(id,
          MOD(false,Absyn.NON_EACH(),{},
          SOME(
          TYPED(rec_call,SOME(Values.RECORD(cname,vals,val_names)),
          PROP((T_COMPLEX(ClassInf.RECORD(cname_str),varlst,NONE),NONE),
          C_VAR()))))) :: res),NONE);
    case ((v :: _),_)
      equation 
        Debug.fprint("failtrace", "-values_to_mods failed for value: ");
        vs = Values.valString(v);
        Debug.fprint("failtrace", vs);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end valuesToMods;

protected function valuesToRecordConstructorCall "function: valuesToRecordConstructorCall
  
  This function transforms a list of values and an Absyn.Path to a function call
  to a record constructor.
"
  input Absyn.Path funcname;
  input list<Values.Value> values;
  output Exp.Exp outExp;
  list<Exp.Exp> expl;
algorithm 
  expl := Util.listMap(values, Static.valueExp);
  outExp := Exp.CALL(funcname,expl,false,false);
end valuesToRecordConstructorCall;

public function valuesToVars "function valuesToVars
  
  Translates a list of Values.Value to a Var list, using a list
  of identifiers as component names.
  Used e.g. when retrieving the type of a record value.
"
  input list<Values.Value> inValuesValueLst;
  input list<Exp.Ident> inExpIdentLst;
  output list<Var> outVarLst;
algorithm 
  outVarLst:=
  matchcontinue (inValuesValueLst,inExpIdentLst)
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
        (VAR(id,ATTR(false,SCode.RW(),SCode.VAR(),Absyn.BIDIR()),false,
          tp,UNBOUND()) :: rest);
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
  of the builtin type.
"
  input Values.Value inValue;
  output Type outType;
algorithm 
  outType:=
  matchcontinue (inValue)
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
    case (Values.INTEGER(integer = _)) then ((T_INTEGER({}),NONE)); 
    case (Values.REAL(real = _)) then ((T_REAL({}),NONE)); 
    case (Values.STRING(string = _)) then ((T_STRING({}),NONE)); 
    case (Values.BOOL(boolean = _)) then ((T_BOOL({}),NONE)); 
    case (Values.ENUM(string = _)) then ((T_ENUM(),NONE)); 
    case ((w as Values.ARRAY(valueLst = (v :: vs))))
      equation 
        tp = typeOfValue(v);
        dim1 = listLength((v :: vs));
      then
        ((T_ARRAY(DIM(SOME(dim1)),tp),NONE));
    case ((w as Values.TUPLE(valueLst = vs)))
      equation 
        ts = Util.listMap(vs, typeOfValue);
      then
        ((T_TUPLE(ts),NONE));
    case Values.RECORD(record_ = cname,orderd = vl,comp = ids)
      equation 
        vars = valuesToVars(vl, ids);
        cname_str = Absyn.pathString(cname);
      then
        ((T_COMPLEX(ClassInf.RECORD(cname_str),vars,NONE),NONE));
    case (v)
      local Ident vs;
      equation 
        Debug.fprint("failtrace", "-type_of_values failed: ");
        vs = Values.valString(v);
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
  outBoolean:=
  matchcontinue (inType)
    case ((T_INTEGER(varLstInt = _),_)) then true; 
    case ((T_REAL(varLstReal = _),_)) then true; 
    case ((T_STRING(varLstString = _),_)) then true; 
    case ((T_BOOL(varLstBool = _),_)) then true; 
    case ((T_ENUM(),_)) then true; 
    case ((T_ARRAY(arrayDim = _),_)) then false; 
    case ((T_COMPLEX(complexClassType = _),_)) then false; 
    case ((T_ENUMERATION(names = _),_)) then false; 
  end matchcontinue;
end basicType;

public function arrayType "function: arrayType
 
  Test whether a type is an array type.
"
  input Type inType;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inType)
    case ((T_ARRAY(arrayDim = _),_)) then true; 
    case (_) then false; 
  end matchcontinue;
end arrayType;

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
 
  Is the first type a subtype of the second type?  This function
  specifies the rules for subtyping in Modelica.
"
  input Type inType1;
  input Type inType2;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inType1,inType2)
    local
      Boolean res;
      Ident l1,l2;
      list<Ident> rest1,rest2;
      list<Var> vl1,vl2,els1,els2;
      Option<Absyn.Path> p1,p2;
      Type t1,t2,tp,tp2,tp1;
      Integer i1,i2;
      ClassInf.State st1,st2;
      Option<Type> bc1,bc2;
      list<Type> type_list1,type_list2;
    case ((T_INTEGER(varLstInt = _),_),(T_INTEGER(varLstInt = _),_)) then true; 
    case ((T_REAL(varLstReal = _),_),(T_REAL(varLstReal = _),_)) then true; 
    case ((T_STRING(varLstString = _),_),(T_STRING(varLstString = _),_)) then true; 
    case ((T_BOOL(varLstBool = _),_),(T_BOOL(varLstBool = _),_)) then true; 
    case ((T_ENUM(),_),(T_ENUM(),_)) then true; 
    case ((T_ENUMERATION(names = (l1 :: rest1),varLst = vl1),p1),(T_ENUMERATION(names = (l2 :: rest2),varLst = vl2),p2))
      equation 
        equality(l2 = l1);
        res = subtype((T_ENUMERATION(rest1,vl1),p1), 
          (T_ENUMERATION(rest2,vl2),p2));
      then
        res;
    case ((T_ENUMERATION(names = {}),_),(T_ENUMERATION(names = _),_)) then true; 
    case ((T_ARRAY(arrayType = t1),_),(T_ARRAY(arrayDim = DIM(integerOption = NONE),arrayType = t2),_))
      equation 
        true = subtype(t1, t2);
      then
        true;
    case ((T_ARRAY(arrayDim = DIM(integerOption = NONE),arrayType = t1),_),(T_ARRAY(arrayType = t2),_))
      equation 
        true = subtype(t1, t2);
      then
        true;
    case ((T_ARRAY(arrayDim = DIM(integerOption = SOME(i1)),arrayType = t1),_),(T_ARRAY(arrayDim = DIM(integerOption = SOME(i2)),arrayType = t2),_))
      equation 
        equality(i1 = i2);
        true = subtype(t1, t2);
      then
        true;
    case ((T_COMPLEX(complexClassType = st1,complexVarLst = els1,complexTypeOption = bc1),_),(T_COMPLEX(complexClassType = st2,complexVarLst = els2,complexTypeOption = bc2),_))
      equation 
        true = subtypeVarlist(els1, els2);
      then
        true;
    case ((T_COMPLEX(complexClassType = st1,complexVarLst = els1,complexTypeOption = SOME(tp)),_),tp2) /* A complex type that extends a basic type is checked 
	    against the baseclass basic type */ 
      equation 
        res = subtype(tp, tp2);
      then
        res;
    case (tp1,(T_COMPLEX(complexClassType = st1,complexVarLst = els1,complexTypeOption = SOME(tp2)),_)) /* A complex type that extends a basic type is checked 
	    against the baseclass basic type */ 
      equation 
        res = subtype(tp1, tp2);
      then
        res;
    case ((T_TUPLE(tupleType = type_list1),_),(T_TUPLE(tupleType = type_list2),_)) /* PR. Check of tuples, similar to complex. Just that
	     identifier name do not have to be checked. Only types are
	 checked. */ 
      equation 
        true = subtypeTypelist(type_list1, type_list2);
      then
        true;
    case (t1,t2) then false;  /* What? If not subtye should return false. Doesn\'t mean no matching rule
  rule	Debug.fprint (\"tytr\", \"subtype: no matching subtype rule.\\n\") &
	Debug.fcall (\"tytr\", print_type, t1) &
	Debug.fprint (\"tytr\", \" <> \") &
	Debug.fcall (\"tytr\", print_type, t2) &
	Debug.fprint (\"tytr\", \"\\n\")
	-----------------------------------
	subtype(t1,t2) => false
 */ 
  end matchcontinue;
end subtype;

protected function subtypeTypelist "PR. function: subtypeTypelist
 
  This function checks if the both `Type\' lists matches types, element
  by element.
"
  input list<Type> inTypeLst1;
  input list<Type> inTypeLst2;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inTypeLst1,inTypeLst2)
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
 
  This function checks if the `Var\' list in the first list is a
  subset of the list in the second argument.  More precisely, it
  checks if, for each `Var\' in the second list there is a `Var\' in
  the first list with a type that is a subtype of the `Var\' in the
  second list.
"
  input list<Var> inVarLst1;
  input list<Var> inVarLst2;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVarLst1,inVarLst2)
    local
      Type t1,t2;
      list<Var> l,vs;
      Ident n;
    case (_,{}) then true; 
    case (l,(VAR(name = n,type_ = t2) :: vs))
      equation 
        VAR(_,_,_,t1,_) = varlistLookup(l, n);
        true = subtype(t1, t2);
        true = subtypeVarlist(l, vs);
      then
        true;
    case (_,_) then false;  /* default */ 
  end matchcontinue;
end subtypeVarlist;

protected function varlistLookup "function: varlistLookup
 
  Given a list of `Var\' and a name, this function finds any `Var\'
  with the given name.
"
  input list<Var> inVarLst;
  input Ident inIdent;
  output Var outVar;
algorithm 
  outVar:=
  matchcontinue (inVarLst,inIdent)
    local
      Var v;
      Ident n,name;
      list<Var> vs;
    case (((v as VAR(name = n)) :: _),name)
      equation 
        equality(n = name);
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
 
  This function finds a subcomponent by name.
"
  input Type inType;
  input Ident inIdent;
  output Var outVar;
algorithm 
  outVar:=
  matchcontinue (inType,inIdent)
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
      ArrayDim dim;
    case (t,n)
      equation 
        true = basicType(t);
        v = lookupInBuiltin(t, n);
      then
        v;
    case ((T_COMPLEX(complexClassType = st,complexVarLst = cs,complexTypeOption = bc),_),id)
      equation 
        v = lookupComponent2(cs, id);
      then
        v;
    case ((T_ARRAY(arrayDim = dim,arrayType = (T_COMPLEX(complexClassType = st,complexVarLst = cs,complexTypeOption = bc),_)),_),id)
      equation 
        VAR(n,attr,prot,ty,bnd) = lookupComponent2(cs, id);
        ty_1 = (T_ARRAY(dim,ty),NONE);
      then
        VAR(n,attr,prot,ty_1,bnd);
    case (_,id) /* Print.print_buf \"- Looking up \" &
	Print.print_buf id &
	Print.print_buf \" in noncomplex type\\n\" */  then fail(); 
  end matchcontinue;
end lookupComponent;

protected function lookupInBuiltin "function: lookupInBuiltin
 
  Since builtin types are not represented as T_COMPLEX, special care
  is needed to be able to lookup the attributes (`start\' etc) in
  them.
 
  This is not a complete solution.  The current way of mapping the
  both the Modelica type `Real\' and the simple type `RealType\' to
  `T_REAL\' is a bit problematic, since it doesn\'t make a
  difference between `Real\' and `RealType\', which makes the
  translator accept things like `x.start.start.start\'.
"
  input Type inType;
  input Ident inIdent;
  output Var outVar;
algorithm 
  outVar:=
  matchcontinue (inType,inIdent)
    local
      Var v;
      list<Var> cs;
      Ident id;
    case ((T_REAL(varLstReal = cs),_),id) /* Real */ 
      equation 
        v = lookupComponent2(cs, id);
      then
        v;
    case ((T_INTEGER(varLstInt = cs),_),id)
      equation 
        v = lookupComponent2(cs, id);
      then
        v;
    case ((T_STRING(varLstString = cs),_),id)
      equation 
        v = lookupComponent2(cs, id);
      then
        v;
    case ((T_BOOL(varLstBool = cs),_),id)
      equation 
        v = lookupComponent2(cs, id);
      then
        v;
    case ((T_ENUM(),_),"quantity") then VAR("quantity",
          ATTR(false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),false,(T_STRING({}),NONE),VALBOUND(Values.STRING("")));  /* axiom	lookup_in_builtin(T_REAL,\"quantity\")
	  => VAR(\"quantity\",
		 ATTR(false, SCode.RW, SCode.PARAM, Absyn.BIDIR),
		 false, T_STRING, VALBOUND(Values.STRING(\"\")))

  axiom	lookup_in_builtin(T_REAL,\"unit\")
	  => VAR(\"unit\",
		 ATTR(false, SCode.RW, SCode.PARAM, Absyn.BIDIR),
		 false, T_STRING, VALBOUND(Values.STRING(\"\")))

  axiom	lookup_in_builtin(T_REAL,\"displayUnit\")
	  => VAR(\"displayUnit\",
		 ATTR(false, SCode.RW, SCode.PARAM, Absyn.BIDIR),
		 false, T_STRING, VALBOUND(Values.STRING(\"\")))

  axiom	lookup_in_builtin(T_REAL,\"min\")
	  => VAR(\"min\",
		 ATTR(false, SCode.RW, SCode.PARAM, Absyn.BIDIR),
		 false, T_REAL, UNBOUND)

  axiom	lookup_in_builtin(T_REAL,\"max\")
	  => VAR(\"max\",
		 ATTR(false, SCode.RW, SCode.PARAM, Absyn.BIDIR),
		 false, T_REAL, UNBOUND)

  axiom	lookup_in_builtin(T_REAL,\"start\")
	  => VAR(\"start\",
		 ATTR(false, SCode.RW, SCode.PARAM, Absyn.BIDIR),
		 false, T_REAL, VALBOUND(Values.REAL(0.0)))

  axiom	lookup_in_builtin(T_REAL,\"fixed\")
	  => VAR(\"fixed\",
		 ATTR(false, SCode.RW, SCode.PARAM, Absyn.BIDIR),
		 false, T_BOOL, UNBOUND) ( Needs to be set to true/false higher up the call chain
					  depending on variability of instance))

  axiom	lookup_in_builtin((T_REAL(_),_),\"enable\")
	  => VAR(\"enable\",
		 ATTR(false, SCode.RW, SCode.PARAM, Absyn.BIDIR),
		 false, (T_BOOL({}),NONE), VALBOUND(Values.BOOL(true)))

  axiom	lookup_in_builtin((T_REAL(_),_),\"nominal\")
	  => VAR(\"nominal\",
		 ATTR(false, SCode.RW, SCode.PARAM, Absyn.BIDIR),
		 false, (T_REAL({}),NONE), UNBOUND)

 ( optimized away looking up the builtin enumeration type \'stateSelect\' ))
  axiom	lookup_in_builtin((T_REAL(_),_),\"stateSelect\")
	  => VAR(\"stateSelect\",
		 ATTR(false, SCode.RW, SCode.PARAM, Absyn.BIDIR),
		 false, (T_ENUMERATION({\"never\",\"avoid\",\"default\",\"prefer\",\"always\"}),NONE),
		 VALBOUND(Values.ENUM(\"default\")))

	( Integer ))
  axiom	lookup_in_builtin((T_INTEGER(_),_),\"quantity\")
	  => VAR(\"quantity\",
		 ATTR(false, SCode.RW, SCode.PARAM, Absyn.BIDIR) Enumeration ( type E in spec) */ 
    case ((T_ENUM(),_),"min") then VAR("min",ATTR(false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),
          false,(T_ENUM(),NONE),UNBOUND());  /* Should be bound to the first element of
  T_ENUMERATION list higher up in the call chain */ 
    case ((T_ENUM(),_),"max") then VAR("max",ATTR(false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),
          false,(T_ENUM(),NONE),UNBOUND());  /* Should be bound to the last element of 
  T_ENUMERATION list higher up in the call chain */ 
    case ((T_ENUM(),_),"start") then VAR("start",ATTR(false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),
          false,(T_BOOL({}),NONE),UNBOUND());  /* Should be bound to the last element of 
  T_ENUMERATION list higher up in the call chain */ 
    case ((T_ENUM(),_),"fixed") then VAR("fixed",ATTR(false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),
          false,(T_BOOL({}),NONE),UNBOUND());  /* Needs to be set to true/false higher up the call chain
  depending on variability of instance */ 
    case ((T_ENUM(),_),"enable") then VAR("enable",
          ATTR(false,SCode.RW(),SCode.PARAM(),Absyn.BIDIR()),false,(T_BOOL({}),NONE),VALBOUND(Values.BOOL(true))); 
  end matchcontinue;
end lookupInBuiltin;

protected function lookupComponent2 "function: lookupComponent2
 
  This function finds a named `Var\' in a list of `Var\'s, comparing
  the name against the second argument to this function.
"
  input list<Var> inVarLst;
  input Ident inIdent;
  output Var outVar;
algorithm 
  outVar:=
  matchcontinue (inVarLst,inIdent)
    local
      Var v;
      Ident n,m;
      list<Var> vs;
    case (((v as VAR(name = n)) :: _),m)
      equation 
        equality(n = m);
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
   This function makes an array type given a Type and an Absyn.ArrayDim
"
  input Type inType;
  input Absyn.ArrayDim inArrayDim;
  output Type outType;
algorithm 
  outType:=
  matchcontinue (inType,inArrayDim)
    local
      Type t;
      Integer len;
      list<Absyn.Subscript> l;
    case (t,{}) then t; 
    case (t,l)
      equation 
        len = listLength(l);
      then
        ((T_ARRAY(DIM(SOME(len)),t),NONE));
  end matchcontinue;
end makeArray;

public function liftArray "function: liftArray
 
  This function turns a type into an array of that type.  If the
  type already is an array, aonther dimension is simply added.
"
  input Type inType;
  input Option<Integer> inIntegerOption;
  output Type outType;
algorithm 
  outType:=
  matchcontinue (inType,inIntegerOption)
    local
      Type ty;
      Option<Integer> i;
    case (ty,i) /* print(\"\\nDebug: lifts the array.\") */  then ((T_ARRAY(DIM(i),ty),NONE));  /* PR  axiom	lift_array (ty,i) => T_ARRAY(DIM(i),ty) */ 
  end matchcontinue;
end liftArray;

public function liftArrayRight "function: liftArrayRight
 
  This function adds an array dimension to \"the right\" of the passed type.
"
  input Type inType;
  input Option<Integer> inIntegerOption;
  output Type outType;
algorithm 
  outType:=
  matchcontinue (inType,inIntegerOption)
    local
      Type ty_1,ty;
      ArrayDim dim;
      Option<Absyn.Path> path;
      Option<Integer> i;
    case ((T_ARRAY(arrayDim = dim,arrayType = ty),path),i)
      equation 
        ty_1 = liftArrayRight(ty, i);
      then
        ((T_ARRAY(dim,ty_1),path));
    case ((ty,path),i)
      local TType ty;
      then
        ((T_ARRAY(DIM(i),(ty,NONE)),path));
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
    case ((T_ARRAY(arrayDim = DIM(integerOption = _),arrayType = ty),_)) then ty; 
  end matchcontinue;
end unliftArray;

protected function typeArraydim "function: typeArraydim
 
  If type is an array, return it array dimension
"
  input Type inType;
  output ArrayDim outArrayDim;
algorithm 
  outArrayDim:=
  matchcontinue (inType)
    local ArrayDim dim;
    case ((T_ARRAY(arrayDim = dim),_)) then dim; 
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
    case ((T_ARRAY(arrayDim = DIM(integerOption = _),arrayType = ty),_))
      equation 
        ty_1 = arrayElementType(ty);
      then
        ty_1;
    case t then t; 
  end matchcontinue;
end arrayElementType;

public function unparseType "function: unparseType
 
  This function prints a Modelica type as a piece of Modelica code.
"
  input Type inType;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inType)
    local
      Ident s1,str,tys,dims,res,vstr,name,st_str,bc_tp_str,paramstr,restypestr,tystr;
      list<Ident> l,dimlststr,dimlststr_1,vars,paramstrs,tystrs;
      Type ty,t,bc_tp,restype;
      list<Option<Integer>> dimlst;
      list<Var> vs;
      Option<Type> bc;
      ClassInf.State ci_state;
      list<FuncArg> params;
    case ((T_INTEGER(varLstInt = _),_)) then "Integer"; 
    case ((T_REAL(varLstReal = _),_)) then "Real"; 
    case ((T_STRING(varLstString = _),_)) then "String"; 
    case ((T_BOOL(varLstBool = _),_)) then "Boolean"; 
    case ((T_ENUMERATION(names = l),_))
      equation 
        s1 = Util.stringDelimitList(l, ",");
        str = Util.stringAppendList({"enumeration(",s1,")"});
      then
        str;
    case ((t as (T_ARRAY(arrayDim = _),_)))
      equation 
        (ty,dimlst) = flattenArrayTypeOpt(t);
        dimlststr = Util.listMap2(dimlst, Dump.getOptionStrDefault, int_string, ":");
        dimlststr_1 = listReverse(dimlststr);
        tys = unparseType(ty);
        dims = Util.stringDelimitList(dimlststr_1, ", ");
        res = Util.stringAppendList({tys,"[",dims,"]"});
      then
        res;
    case (((t as T_COMPLEX(complexClassType = ClassInf.RECORD(string = name),complexVarLst = vs,complexTypeOption = bc)),_))
      local TType t;
      equation 
        vars = Util.listMap(vs, unparseVar);
        vstr = Util.stringAppendList(vars);
        res = Util.stringAppendList({"record ",name,"\n",vstr,"end record;"});
      then
        res;
    case ((T_COMPLEX(complexClassType = ci_state,complexVarLst = vs,complexTypeOption = SOME(bc_tp)),_))
      equation 
        res = ClassInf.getStateName(ci_state);
        st_str = ClassInf.printStateStr(ci_state);
        bc_tp_str = unparseType(bc_tp);
        res = Util.stringAppendList({res," ",st_str," bc:",bc_tp_str});
      then
        res;
    case ((T_COMPLEX(complexClassType = ci_state,complexVarLst = vs,complexTypeOption = NONE),_))
      equation 
        res = ClassInf.getStateName(ci_state);
        st_str = ClassInf.printStateStr(ci_state);
        res = Util.stringAppendList({res," ",st_str});
      then
        res;
    case ((T_FUNCTION(funcArg = params,funcResultType = restype),_))
      equation 
        paramstrs = Util.listMap(params, unparseParam);
        paramstr = Util.stringDelimitList(paramstrs, ", ");
        restypestr = unparseType(restype);
        res = Util.stringAppendList({"function(",paramstr,") => ",restypestr});
      then
        res;
    case ((T_TUPLE(tupleType = tys),_))
      local list<Type> tys;
      equation 
        tystrs = Util.listMap(tys, unparseType);
        tystr = Util.stringDelimitList(tystrs, ", ");
        res = Util.stringAppendList({"(",tystr,")"});
      then
        res;
    case ((T_NOTYPE(),_)) then "#NOTYPE#"; 
    case ((T_ANYTYPE(anyClassType = _),_)) then "#ANYTYPE#"; 
    case (ty) then "Internal error unparse_type: not implemented yet\n"; 
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
    case C_CONST() then "C_CONST"; 
    case C_PARAM() then "C_PARAM"; 
    case C_VAR() then "C_VAR"; 
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
    case CONST(const = c)
      equation 
        cstr = unparseConst(c);
      then
        cstr;
    case TUPLE_CONST(tupleConstLst = constlist)
      equation 
        strlist = Util.listMap(constlist, unparseTupleconst);
        res = Util.stringDelimitList(strlist, ", ");
        res_1 = Util.stringAppendList({"(",res,")"});
      then
        res_1;
  end matchcontinue;
end unparseTupleconst;

public function printType "function: printType
 
  This function prints a textual description of a Modelica type.  If
  the type is not one of the primitive types, it simply prints
  `composite\'.  The actual code is expluded from the report.
"
  input Type inType;
algorithm 
  _:=
  matchcontinue (inType)
    local
      list<Var> vars;
      list<Ident> l;
      ClassInf.State st;
      Option<Type> bc;
      ArrayDim dim;
      Type t,restype;
      list<FuncArg> params;
      list<Type> tys;
    case ((T_INTEGER(varLstInt = vars),_))
      equation 
        Print.printErrorBuf("Integer");
        Print.printErrorBuf(" (");
        Dump.printList(vars, printVar, ", ");
        Print.printErrorBuf(")");
      then
        ();
    case ((T_REAL(varLstReal = vars),_))
      equation 
        Print.printErrorBuf("Real");
        Print.printErrorBuf(" (");
        Dump.printList(vars, printVar, ", ");
        Print.printErrorBuf(")");
      then
        ();
    case ((T_STRING(varLstString = vars),_))
      equation 
        Print.printErrorBuf("String");
        Print.printErrorBuf(" (");
        Dump.printList(vars, printVar, ", ");
        Print.printErrorBuf(")");
      then
        ();
    case ((T_BOOL(varLstBool = vars),_))
      equation 
        Print.printErrorBuf("Boolean");
        Print.printErrorBuf(" (");
        Dump.printList(vars, printVar, ", ");
        Print.printErrorBuf(")");
      then
        ();
    case ((T_ENUM(),_))
      equation 
        Print.printErrorBuf("EnumType");
      then
        ();
    case ((T_ENUMERATION(names = l,varLst = vars),_))
      equation 
        Print.printErrorBuf("enumeration((");
        Dump.printList(l, print, ", ");
        Print.printErrorBuf(") ");
        Print.printErrorBuf(", (");
        Dump.printList(vars, printVar, ", ");
        Print.printErrorBuf(")");
      then
        ();
    case ((T_COMPLEX(complexClassType = st,complexVarLst = vars,complexTypeOption = bc),_))
      equation 
        Print.printErrorBuf("composite(");
        Print.printErrorBuf(", (");
        ClassInf.printState(st);
        Print.printErrorBuf(", (");
        Dump.printList(vars, printVar, ", ");
        Print.printErrorBuf(")");
      then
        ();
    case ((T_ARRAY(arrayDim = dim,arrayType = t),_))
      equation 
        Print.printErrorBuf("array[");
        printArraydim(dim);
        Print.printErrorBuf("] of ");
        printType(t);
        Print.printErrorBuf(")");
      then
        ();
    case ((T_FUNCTION(funcArg = params,funcResultType = restype),_))
      equation 
        Print.printErrorBuf("function(");
        printParams(params);
        Print.printErrorBuf(" => ");
        printType(restype);
        Print.printErrorBuf(")");
      then
        ();
    case ((T_TUPLE(tupleType = tys),_))
      equation 
        Print.printErrorBuf("(");
        Dump.printList(tys, printType, ", ");
        Print.printErrorBuf(")");
      then
        ();
    case ((T_NOTYPE(),_))
      equation 
        Print.printErrorBuf("#NOTYPE#");
      then
        ();
    case ((T_ANYTYPE(anyClassType = _),_))
      equation 
        Print.printErrorBuf("#T_ANYTYPE#");
      then
        ();
    case ((_,_))
      equation 
        Print.printErrorBuf("print_type failed!\n");
      then
        ();
  end matchcontinue;
end printType;

protected function printArraydim "function: printArraydim
 
  Prints an ArrayDim to the Print buffer.
"
  input ArrayDim ad;
  Ident s;
algorithm 
  s := getArraydimStr(ad);
  Print.printErrorBuf(s);
end printArraydim;

public function getArraydimStr "function: getArraydimStr
 
  Prints ArrayDim to a string.
"
  input ArrayDim inArrayDim;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inArrayDim)
    local
      Ident s;
      Integer i;
    case DIM(integerOption = NONE) then ":"; 
    case DIM(integerOption = SOME(i))
      equation 
        s = intString(i);
      then
        s;
    case _ then "#STRANGE#"; 
  end matchcontinue;
end getArraydimStr;

public function arraydimInt "function: arraydimInt
 
  Return the dimension of an ArrayDim
"
  input ArrayDim inArrayDim;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inArrayDim)
    local Integer i;
    case DIM(integerOption = SOME(i)) then i; 
  end matchcontinue;
end arraydimInt;

public function printParams "function: printParams
  
  Prints function arguments to the Print buffer.
"
  input list<FuncArg> inFuncArgLst;
algorithm 
  _:=
  matchcontinue (inFuncArgLst)
    local
      Ident n;
      Type t;
      list<FuncArg> params;
    case {} then (); 
    case {(n,t)}
      equation 
        Print.printErrorBuf(n);
        Print.printErrorBuf(" :: ");
        printType(t);
      then
        ();
    case (((n,t) :: params))
      equation 
        Print.printErrorBuf(n);
        Print.printErrorBuf(" :: ");
        printType(t);
        Print.printErrorBuf(" * ");
        printParams(params);
      then
        ();
  end matchcontinue;
end printParams;

public function unparseVar "function: unparseVar
 
  Prints a variable to a string.
"
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
    case VAR(name = n,attributes = attr,protected_ = prot,type_ = typ,binding = bind)
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

public function printVar "function: printVar
  author: LS
 
  Prints a Var to the Print buffer.
"
  input Var inVar;
algorithm 
  _:=
  matchcontinue (inVar)
    local
      Ident vs,n;
      SCode.Variability var;
      Boolean prot;
      Type typ;
      Binding bind;
    case VAR(name = n,attributes = ATTR(parameter_ = var),protected_ = prot,type_ = typ,binding = bind)
      equation 
        printType(typ);
        Print.printErrorBuf(" ");
        Print.printErrorBuf(n);
        Print.printErrorBuf(" ");
        vs = SCode.variabilityString(var);
        Print.printErrorBuf(vs);
        Print.printErrorBuf(" ");
        printBinding(bind);
      then
        ();
  end matchcontinue;
end printVar;

public function printBinding "function: printBinding
  author: LS
 
  Print a variable binding to the Print buffer.
"
  input Binding inBinding;
algorithm 
  _:=
  matchcontinue (inBinding)
    local
      Ident str;
      Exp.Exp exp;
      Const f;
      Values.Value v;
    case UNBOUND()
      equation 
        Print.printErrorBuf("UNBOUND");
      then
        ();
    case EQBOUND(exp = exp,constant_ = f)
      equation 
        Print.printErrorBuf("EQBOUND: ");
        Exp.printExp(exp);
        str = unparseConst(f);
        Print.printErrorBuf(str);
      then
        ();
    case VALBOUND(valBound = v)
      equation 
        Print.printErrorBuf("VALBOUND: ");
        Values.printVal(v);
      then
        ();
  end matchcontinue;
end printBinding;

public function printBindingStr "function: pritn_binding_str
 
  Print a variable binding to a string.
"
  input Binding inBinding;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inBinding)
    local
      Ident str,str2,res,v_str,s;
      Exp.Exp exp;
      Const f;
      Values.Value v;
    case UNBOUND() then "UNBOUND"; 
    case EQBOUND(exp = exp,evaluatedExp = NONE,constant_ = f)
      equation 
        str = Exp.printExpStr(exp);
        str2 = unparseConst(f);
        res = Util.stringAppendList({"EQBOUND(",str,",NONE ",str2,")"});
      then
        res;
    case EQBOUND(exp = exp,evaluatedExp = SOME(v),constant_ = f)
      equation 
        str = Exp.printExpStr(exp);
        str2 = unparseConst(f);
        v_str = Values.valString(v);
        res = Util.stringAppendList({"EQBOUND(",str,",SOME(",v_str,"), ",str2,")"});
      then
        res;
    case VALBOUND(valBound = v)
      equation 
        s = Values.unparseValues({v});
        res = Util.stringAppendList({"VALBOUND(",s,")"});
      then
        res;
  end matchcontinue;
end printBindingStr;

public function makeFunctionType "function: makeFunctionType
  author: LS 
 
  Creates a function type from a function name an a list of input and
  output variables.
"
  input Absyn.Path p;
  input list<Var> vl;
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
  outType := (T_FUNCTION(fargs,rettype),SOME(p));
end makeFunctionType;

public function makeEnumerationType "function: makeEnumerationType
 
  Creates an enumeration type from a name and a list of variables.
"
  input Absyn.Path inPath;
  input list<Var> inVarLst;
  output Type outType;
algorithm 
  outType:=
  matchcontinue (inPath,inVarLst)
    local
      list<Ident> strs;
      Absyn.Path p;
      Ident name;
      list<Var> xs;
    case (p,(VAR(name = name) :: xs))
      equation 
        ((T_ENUMERATION(strs,{}),_)) = makeEnumerationType(p, xs);
      then
        ((T_ENUMERATION((name :: strs),{}),SOME(p)));
    case (p,{}) then ((T_ENUMERATION({},{}),SOME(p))); 
  end matchcontinue;
end makeEnumerationType;

public function printFarg "function: printFarg
 
  Prints a function argument to the Print buffer.
"
  input FuncArg inFuncArg;
algorithm 
  _:=
  matchcontinue (inFuncArg)
    local
      Ident n;
      Type ty;
    case ((n,ty))
      equation 
        printType(ty);
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

public function getVars "function getVars
  author: LS 
  
  Select the variables from the list for which the condition function given
  as second argument succeeds.
"
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
    case VAR(name = n,attributes = attr,protected_ = false,type_ = ty,binding = bnd) /* LS: false means not protected, hence we ignore protected variables */ 
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
    case VAR(name = n,attributes = attr,protected_ = false,type_ = ty,binding = bnd) /* LS: false means not protected, hence we ignore protected variables */ 
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
    case ATTR(direction = Absyn.INPUT()) then true; 
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
    case ATTR(direction = Absyn.OUTPUT()) then true; 
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
    case ATTR(direction = Absyn.BIDIR()) then true; 
  end matchcontinue;
end isBidirAttr;

protected function makeFargsList "function: makeFargsList
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
    case ((VAR(name = n,attributes = attr,protected_ = pr,type_ = ty,binding = bnd) :: vl))
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
    case {} then ((T_NOTYPE(),NONE)); 
    case {var}
      equation 
        ty = makeReturnTypeSingle(var);
      then
        ty;
    case vl
      equation 
        tys = makeReturnTypeTuple(vl);
      then
        ((T_TUPLE(tys),NONE));
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
    case VAR(name = n,attributes = attr,protected_ = pr,type_ = ty,binding = bnd) then ty; 
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
    case (VAR(name = n,attributes = attr,protected_ = pr,type_ = ty,binding = bnd) :: vl)
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
      Boolean fl;
      SCode.Accessibility ac;
      Absyn.Direction dir;
      Type ty;
      Binding bnd;
    case VAR(name = n,attributes = ATTR(flow_ = fl,accessibility = ac,parameter_ = SCode.PARAM(),direction = dir),protected_ = false,type_ = ty,binding = bnd) then ();  /* LS: false means not protected, hence we ignore protected variables */ 
  end matchcontinue;
end isParameter;

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
      ArrayDim d;
      Type tp;
      list<Type> xs;
    case (((T_ARRAY(arrayDim = d,arrayType = tp),_) :: xs))
      equation 
        r1 = containReal({tp});
        r2 = containReal(xs);
        res = boolOr(r1, r2);
      then
        res;
    case (((T_REAL(varLstReal = _),_) :: _)) then true; 
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
    case ((T_ARRAY(arrayDim = DIM(integerOption = NONE),arrayType = ty),_))
      equation 
        (ty_1,dimlist_1) = flattenArrayType(ty);
      then
        (ty_1,dimlist_1);
    case ((T_ARRAY(arrayDim = DIM(integerOption = SOME(dim)),arrayType = ty),_))
      equation 
        (ty_1,dimlist) = flattenArrayType(ty);
        dimlist_1 = listAppend(dimlist, {dim});
      then
        (ty_1,dimlist_1);
    case ty then (ty,{}); 
  end matchcontinue;
end flattenArrayType;

protected function flattenArrayTypeOpt "function: flattenArrayTypeOpt
 
  Returns the element type of a Type and the list of dimensions of the type.
  If dimension is \':\' NONE is returned.
"
  input Type inType;
  output Type outType;
  output list<Option<Integer>> outIntegerOptionLst;
algorithm 
  (outType,outIntegerOptionLst):=
  matchcontinue (inType)
    local
      Type ty_1,ty;
      list<Option<Integer>> dimlist_1,dimlist;
      Integer dim;
    case ((T_ARRAY(arrayDim = DIM(integerOption = NONE),arrayType = ty),_))
      equation 
        (ty_1,dimlist_1) = flattenArrayTypeOpt(ty);
      then
        (ty_1,(NONE :: dimlist_1));
    case ((T_ARRAY(arrayDim = DIM(integerOption = SOME(dim)),arrayType = ty),_))
      equation 
        (ty_1,dimlist) = flattenArrayTypeOpt(ty);
        dimlist_1 = listAppend(dimlist, {SOME(dim)});
      then
        (ty_1,dimlist_1);
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
    case ((T_INTEGER(varLstInt = _),_)) then "Integer"; 
    case ((T_REAL(varLstReal = _),_)) then "Real"; 
    case ((T_STRING(varLstString = _),_)) then "String"; 
    case ((T_BOOL(varLstBool = _),_)) then "Boolean"; 
    case ((T_COMPLEX(complexClassType = st),_))
      equation 
        n = ClassInf.getStateName(st);
      then
        n;
    case ((arrayty as (T_ARRAY(arrayDim = _),_)))
      equation 
        (ty,dims) = flattenArrayType(arrayty);
        dimstrs = Util.listMap(dims, int_string);
        dimstr = Util.stringDelimitList(dimstrs, ", ");
        tystr = getTypeName(ty);
        str = Util.stringAppendList({tystr,"[",dimstr,"]"});
      then
        str;
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
    case PROP(constFlag = c) then c; 
    case PROP_TUPLE(tupleConst = constant_)
      equation 
        res = propTupleAllConst(constant_);
      then
        res;
    case prop
      equation 
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
    case PROP(constFlag = constant_) then constant_; 
    case PROP_TUPLE(tupleConst = constant_)
      local TupleConst constant_;
      equation 
        res = propTupleAnyConst(constant_);
      then
        res;
    case prop
      equation 
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
    case CONST(const = c) then c; 
    case TUPLE_CONST(tupleConstLst = (first :: rest))
      equation 
        C_CONST() = propTupleAnyConst(first);
      then
        C_CONST();
    case TUPLE_CONST(tupleConstLst = (first :: {}))
      equation 
        C_PARAM() = propTupleAnyConst(first);
      then
        C_PARAM();
    case TUPLE_CONST(tupleConstLst = (first :: {}))
      equation 
        C_VAR() = propTupleAnyConst(first);
      then
        C_VAR();
    case TUPLE_CONST(tupleConstLst = (first :: rest))
      equation 
        C_PARAM() = propTupleAnyConst(first);
        res = propTupleAnyConst(TUPLE_CONST(rest));
      then
        res;
    case TUPLE_CONST(tupleConstLst = (first :: rest))
      equation 
        C_VAR() = propTupleAnyConst(first);
        res = propTupleAnyConst(TUPLE_CONST(rest));
      then
        res;
    case const
      equation 
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
    case CONST(const = c) then c; 
    case TUPLE_CONST(tupleConstLst = (first :: rest))
      equation 
        C_PARAM() = propTupleAllConst(first);
      then
        C_PARAM();
    case TUPLE_CONST(tupleConstLst = (first :: rest))
      equation 
        C_VAR() = propTupleAllConst(first);
      then
        C_VAR();
    case TUPLE_CONST(tupleConstLst = (first :: {}))
      equation 
        C_CONST() = propTupleAllConst(first);
      then
        C_CONST();
    case TUPLE_CONST(tupleConstLst = (first :: rest))
      equation 
        C_CONST() = propTupleAllConst(first);
        res = propTupleAllConst(TUPLE_CONST(rest));
      then
        res;
    case const
      equation 
        Debug.fprint("failtrace", "- prop_tuple_all_const failed: ");
        str = unparseTupleconst(const);
        Debug.fprintln("failtrace", str);
      then
        fail();
  end matchcontinue;
end propTupleAllConst;

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
    case PROP(type_ = ty) then ty; 
    case PROP_TUPLE(type_ = ty) then ty; 
  end matchcontinue;
end getPropType;

public function elabType "function: elabType
  author: ??
 
  Elaborates a type
"
  input Type inType;
  output Exp.Type outType;
algorithm 
  outType:=
  matchcontinue (inType)
    local
      Type et,t;
      Exp.Type t_1;
      list<Integer> dims;
    case ((T_INTEGER(varLstInt = _),_)) then Exp.INT(); 
    case ((T_REAL(varLstReal = _),_)) then Exp.REAL(); 
    case ((T_BOOL(varLstBool = _),_)) then Exp.BOOL(); 
    case ((T_STRING(varLstString = _),_)) then Exp.STRING(); 
    case ((T_ENUM(),_)) then Exp.ENUM(); 
    case ((t as (T_ARRAY(arrayDim = _),_)))
      equation 
        et = arrayElementType(t);
        t_1 = elabType(et);
        dims = getDimensionSizes(t);
      then
        Exp.T_ARRAY(t_1,dims);
    case ((_,_)) then Exp.OTHER(); 
  end matchcontinue;
end elabType;

public function matchProp "function: matchProp
 
  This is basically a wrapper aroune `match_type\'.  It matches an
  expression with properties with another set of properties.  If
  necessary, the expression is modified to match.  The only relevant
  property is the type.
 
"
  input Exp.Exp inExp1;
  input Properties inProperties2;
  input Properties inProperties3;
  output Exp.Exp outExp;
  output Properties outProperties;
algorithm 
  (outExp,outProperties):=
  matchcontinue (inExp1,inProperties2,inProperties3)
    local
      Exp.Exp e_1,e;
      Type t_1,gt,et;
      Const c,c1,c2;
    case (e,PROP(type_ = gt,constFlag = c1),PROP(type_ = et,constFlag = c2))
      equation 
        Debug.print("Debug: match prop.");
        (e_1,t_1) = matchType(e, gt, et);
        c = constAnd(c1, c2);
      then
        (e_1,PROP(t_1,c));
    case (e,PROP_TUPLE(type_ = gt,tupleConst = c1),PROP_TUPLE(type_ = et,tupleConst = c2))
      local TupleConst c,c1,c2;
      equation 
        Debug.print("\nDebug: match prop (PROP TUPLE). ");
        (e_1,t_1) = matchType(e, gt, et);
        c = constTupleAnd(c1, c2);
      then
        (e_1,PROP_TUPLE(t_1,c));
  end matchcontinue;
end matchProp;

public function matchType "function: matchType
 
  This function matches an expression with an expected type, and
  converts the expression to the expected type if necessary.
  inputs : (exp: Exp.Exp, exp_type: Type, expected: Type)
  outputs: (Exp.Exp, Type)
"
  input Exp.Exp inExp1;
  input Type inType2;
  input Type inType3;
  output Exp.Exp outExp;
  output Type outType;
algorithm 
  (outExp,outType):=
  matchcontinue (inExp1,inType2,inType3)
    local
      Exp.Exp e,e_1;
      Type e_type,expected_type,e_type_1;
    case (e,e_type,expected_type)
      equation 
        true = subtype(e_type, expected_type);
      then
        (e,e_type);
    case (e,e_type,expected_type)
      equation 
        false = subtype(e_type, expected_type);
        (e_1,e_type_1) = typeConvert(e, e_type, expected_type) "Debug.fprint(\"sei\", \"trying type convert\\n\") &" ;
         /* Debug.fprint(\"sei\", \"trying type convert\\n\") & & Debug.fprint(\"sei\", \"Type convert succeded\\n\") */ 
      then
        (e_1,e_type_1);
  end matchcontinue;
end matchType;

public function matchTypeList "function: matchTypeList
 
  This function matches a list of types, with a list of other types.
  Type conversion is disredaded, but an expression is given 
  (the rhs of a tuple assignment) if such conversions should be implemented
"
  input Exp.Exp inExp1;
  input list<Type> inTypeLst2;
  input list<Type> inTypeLst3;
  output Exp.Exp outExp;
  output list<Type> outTypeLst;
algorithm 
  (outExp,outTypeLst):=
  matchcontinue (inExp1,inTypeLst2,inTypeLst3)
    local
      Exp.Exp e,e_1,e_2;
      Type tp,t1,t2;
      list<Type> res,ts1,ts2;
    case (e,{},{}) then (e,{}); 
    case (e,(t1 :: ts1),(t2 :: ts2))
      equation 
        (e_1,tp) = matchType(e, t1, t2);
        (e_2,res) = matchTypeList(e_1, ts1, ts2);
      then
        (e_1,(tp :: res));
    case (e,(t1 :: ts1),(t2 :: ts2))
      equation 
        Debug.fprint("failtrace", "- match_type_list failed\n");
      then
        fail();
  end matchcontinue;
end matchTypeList;

public function vectorizableType "function: vectorizableType
  author: PA
 
  This function checks if a given type can be (converted and) vectorized to 
  a expected type.
  For instance and argument of type Integer{:} can be vectorized to an
  argument type Real, using type coersion and vectorization of one dimension.
  inputs:  (exp: Exp.Exp, exp_type: Type, expected: Type) 
  outputs: (Exp.Exp, Type, ArrayDim list) 
"
  input Exp.Exp inExp1;
  input Type inType2;
  input Type inType3;
  output Exp.Exp outExp;
  output Type outType;
  output list<ArrayDim> outArrayDimLst;
algorithm 
  (outExp,outType,outArrayDimLst):=
  matchcontinue (inExp1,inType2,inType3)
    local
      Exp.Exp e_1,e;
      Type e_type_1,e_type,expected_type,e_type_elt;
      list<ArrayDim> ds;
      ArrayDim ad;
    case (e,e_type,expected_type)
      equation 
        (e_1,e_type_1) = matchType(e, e_type, expected_type);
      then
        (e_1,e_type_1,{});
    case (e,e_type,expected_type)
      equation 
        e_type_elt = unliftArray(e_type);
        (e_1,e_type_1,ds) = vectorizableType(e, e_type_elt, expected_type);
        ad = typeArraydim(e_type);
      then
        (e_1,e_type_1,(ad :: ds));
  end matchcontinue;
end vectorizableType;

public function typeConvert "function: typeConvert
 
  This functions converts the expression in the first argument to
  the type specified in the third argument.  The current type of the
  expression is given in the second argument.
 
  If no type conversion is possible, this function fails.
"
  input Exp.Exp inExp1;
  input Type inType2;
  input Type inType3;
  output Exp.Exp outExp;
  output Type outType;
algorithm 
  (outExp,outType):=
  matchcontinue (inExp1,inType2,inType3)
    local
      list<Exp.Exp> elist_1,elist;
      Exp.Type at,t;
      Boolean a;
      Integer dim1,dim2,nmax,dim11,dim22;
      Type ty1,ty2,t1,t2,t_1;
      Option<Absyn.Path> p,p1,p2;
      Exp.Exp begin_1,step_1,stop_1,begin,step,stop,e_1,e,exp;
      list<list<tuple<Exp.Exp, Boolean>>> ell_1,ell;
      list<Type> tys_1,tys1,tys2;
      list<Ident> l;
      list<Var> v;
      String str;
    case (Exp.ARRAY(array = elist),(T_ARRAY(arrayDim = DIM(integerOption = SOME(dim1)),arrayType = ty1),_),(T_ARRAY(arrayDim = DIM(integerOption = SOME(dim2)),arrayType = ty2),p))
      equation 
        (dim1 == dim2) = true "Array expressions" ;
        elist_1 = typeConvertArray(elist, ty1, ty2);
        at = elabType(ty2);
        a = isArray(ty2);
      then
        (Exp.ARRAY(at,a,elist_1),(T_ARRAY(DIM(SOME(dim1)),ty2),p));
    case (Exp.RANGE(ty = t,exp = begin,expOption = SOME(step),range = stop),(T_ARRAY(arrayDim = DIM(integerOption = SOME(dim1)),arrayType = ty1),_),(T_ARRAY(arrayDim = DIM(integerOption = SOME(dim2)),arrayType = ty2),p))
      equation 
        (dim1 == dim2) = true "Range expressions" ;
        (begin_1,_) = typeConvert(begin, ty1, ty2);
        (step_1,_) = typeConvert(step, ty1, ty2);
        (stop_1,_) = typeConvert(stop, ty1, ty2);
        at = elabType(ty2);
        a = isArray(ty2);
      then
        (Exp.RANGE(at,begin_1,SOME(step_1),stop_1),(T_ARRAY(DIM(SOME(dim1)),ty2),p));
    case (Exp.RANGE(ty = t,exp = begin,expOption = NONE,range = stop),(T_ARRAY(arrayDim = DIM(integerOption = SOME(dim1)),arrayType = ty1),_),(T_ARRAY(arrayDim = DIM(integerOption = SOME(dim2)),arrayType = ty2),p))
      equation 
        (dim1 == dim2) = true "Range expressions" ;
        (begin_1,_) = typeConvert(begin, ty1, ty2);
        (stop_1,_) = typeConvert(stop, ty1, ty2);
        at = elabType(ty2);
        a = isArray(ty2);
      then
        (Exp.RANGE(at,begin_1,NONE,stop_1),(T_ARRAY(DIM(SOME(dim1)),ty2),p));
    case (Exp.MATRIX(integer = nmax,scalar = ell),(T_ARRAY(arrayDim = DIM(integerOption = SOME(dim1)),arrayType = (T_ARRAY(arrayDim = DIM(integerOption = SOME(dim11)),arrayType = t1),_)),_),(T_ARRAY(arrayDim = DIM(integerOption = SOME(dim2)),arrayType = (T_ARRAY(arrayDim = DIM(integerOption = SOME(dim22)),arrayType = t2),p1)),p2))
      equation 
        (dim1 == dim2) = true "Matrix expressions" ;
        (dim11 == dim22) = true;
        ell_1 = typeConvertMatrix(ell, t1, t2);
        at = elabType(t2);
      then
        (Exp.MATRIX(at,nmax,ell_1),(T_ARRAY(DIM(SOME(dim1)),(T_ARRAY(DIM(SOME(dim11)),t2),p1)),
          p2));
    case (Exp.MATRIX(integer = nmax,scalar = ell),(T_ARRAY(arrayDim = DIM(integerOption = SOME(dim1)),arrayType = (T_ARRAY(arrayDim = DIM(integerOption = SOME(dim11)),arrayType = t1),_)),_),(T_ARRAY(arrayDim = DIM(integerOption = NONE),arrayType = (T_ARRAY(arrayDim = DIM(integerOption = SOME(dim22)),arrayType = t2),p1)),p2))
      equation 
        (dim11 == dim22) = true "Matrix expressions" ;
        ell_1 = typeConvertMatrix(ell, t1, t2);
        at = elabType(t2);
      then
        (Exp.MATRIX(at,nmax,ell_1),(T_ARRAY(DIM(SOME(dim1)),(T_ARRAY(DIM(SOME(dim11)),t2),p1)),
          p2));
    case (Exp.ARRAY(array = elist),(T_ARRAY(arrayDim = DIM(integerOption = NONE),arrayType = ty1),_),(T_ARRAY(arrayDim = DIM(integerOption = SOME(dim2)),arrayType = ty2),p2))
      equation 
        (elist_1) = typeConvertArray(elist, ty1, ty2) "Array expressions This rule is used to ensure that casts are made on each element, instead of on the whole array" ;
        at = elabType(ty2);
        a = isArray(ty2);
      then
        (Exp.ARRAY(at,a,elist_1),(T_ARRAY(DIM(NONE),ty2),p2));
    case (Exp.ARRAY(array = elist),(T_ARRAY(arrayDim = DIM(integerOption = SOME(dim1)),arrayType = ty1),_),(T_ARRAY(arrayDim = DIM(integerOption = NONE),arrayType = ty2),p2))
      equation 
        (elist_1) = typeConvertArray(elist, ty1, ty2) "Array expressions This rule is used to ensure that casts are made on each element, instead of on the whole array" ;
        at = elabType(ty2);
        a = isArray(ty2);
      then
        (Exp.ARRAY(at,a,elist_1),(T_ARRAY(DIM(SOME(dim1)),ty2),p2));
    case (e,(T_ARRAY(arrayDim = DIM(integerOption = SOME(dim1)),arrayType = ty1),_),(T_ARRAY(arrayDim = DIM(integerOption = SOME(dim2)),arrayType = ty2),p2))
      equation 
        (dim1 == dim2) = true "Arbitrary expressions, 
	  first dimension {dim1}, 
	  second dimension {dim2}" ;
        (e_1,t_1) = typeConvert(e, ty1, ty2);
      then
        (e_1,(T_ARRAY(DIM(SOME(dim2)),t_1),p2));
    case (e,(T_ARRAY(arrayDim = DIM(integerOption = NONE),arrayType = ty1),_),(T_ARRAY(arrayDim = DIM(integerOption = SOME(dim2)),arrayType = ty2),p2))
      equation 
        (e_1,t_1) = typeConvert(e, ty1, ty2) "Arbitrary expressions, 
	  first dimension {:}, 
	  second dimension {dim2}" ;
      then
        (e_1,(T_ARRAY(DIM(NONE),t_1),p2));
    case (e,(T_ARRAY(arrayDim = DIM(integerOption = NONE),arrayType = ty1),_),(T_ARRAY(arrayDim = DIM(integerOption = NONE),arrayType = ty2),p2))
      equation 
        (e_1,t_1) = typeConvert(e, ty1, ty2) "Arbitrary expressions 
	  first dimension {:}
	  second dimension {:}
	" ;
      then
        (e_1,(T_ARRAY(DIM(NONE),t_1),p2));
    case (e,(T_ARRAY(arrayDim = DIM(integerOption = SOME(dim1)),arrayType = ty1),_),(T_ARRAY(arrayDim = DIM(integerOption = NONE),arrayType = ty2),p2))
      equation 
        (e_1,t_1) = typeConvert(e, ty1, ty2) "Arbitrary expression 
	  first dimension {dim1}
	  second dimension {:}
	" ;
      then
        (e_1,(T_ARRAY(DIM(SOME(dim1)),t_1),p2));
    case (Exp.TUPLE(PR = elist),(T_TUPLE(tupleType = tys1),_),(T_TUPLE(tupleType = tys2),p2))
      equation 
        (elist_1,tys_1) = typeConvertList(elist, tys1, tys2);
      then
        (Exp.TUPLE(elist_1),(T_TUPLE(tys_1),p2));
    case (exp,(T_ENUM(),_),(T_ENUMERATION(names = l,varLst = v),p2)) then (exp,(T_ENUMERATION(l,v),p2)); 
    case (e,(T_INTEGER(varLstInt = v),_),(T_REAL(varLstReal = _),p)) then (Exp.CAST(Exp.REAL(),e),(T_REAL(v),p)); 
    case (exp,t1,t2)
      equation 
        Debug.fprint("tcvt", "- type conversion failed: ");
         str = Exp.printExpStr(exp);
        Debug.fprint("tcvt", str);
        Debug.fprint("tcvt", "  ");
         Debug.fcall("tcvt", printType, t1);
        Debug.fprint("tcvt", ", ");
        Debug.fcall("tcvt", printType, t2);
        Debug.fprint("tcvt", "\n");
      then
        fail();
  end matchcontinue;
end typeConvert;

public function typeConvertArray "function: typeConvertArray
 
  Helper function to type_convert. Handles array expressions.
"
  input list<Exp.Exp> inExpExpLst1;
  input Type inType2;
  input Type inType3;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inExpExpLst1,inType2,inType3)
    local
      list<Exp.Exp> rest_1,rest;
      Exp.Exp first_1,first;
      Type ty1,ty2;
    case ({},_,_) then {}; 
    case ((first :: rest),ty1,ty2) /* rule	Print.printErrorBuf \"- type conversion of array failed exp=\" &
	Exp.print_exp e &
	Print.printErrorBuf \"t1 = \" &
	print_type t1 & 
	Print.printErrorBuf \" t2 = \" &
	print_type t2 &
	Print.printErrorBuf \"\\n\" 
	-------------------------------
	type_convert_array (e::_,t1,t2) => fail */ 
      equation 
        rest_1 = typeConvertArray(rest, ty1, ty2);
        (first_1,_) = typeConvert(first, ty1, ty2);
      then
        (first_1 :: rest_1);
  end matchcontinue;
end typeConvertArray;

protected function typeConvertMatrix "function: typeConvertMatrix
 
  Helper function to type_convert. Handles matrix expressions.
"
  input list<list<tuple<Exp.Exp, Boolean>>> inTplExpExpBooleanLstLst1;
  input Type inType2;
  input Type inType3;
  output list<list<tuple<Exp.Exp, Boolean>>> outTplExpExpBooleanLstLst;
algorithm 
  outTplExpExpBooleanLstLst:=
  matchcontinue (inTplExpExpBooleanLstLst1,inType2,inType3)
    local
      list<list<tuple<Exp.Exp, Boolean>>> rest_1,rest;
      list<tuple<Exp.Exp, Boolean>> first_1,first;
      Type ty1,ty2;
    case ({},_,_) then {}; 
    case ((first :: rest),ty1,ty2) /* rule	Print.printErrorBuf \"- type conversion of matrix failed\" &
	Print.printErrorBuf \"t1 = \" &
	print_type t1 & 
	Print.printErrorBuf \" t2 = \" &
	print_type t2 &
	Print.printErrorBuf \"\\n\" 
	-------------------------------
	type_convert_matrix (e::_,t1,t2) => fail */ 
      equation 
        rest_1 = typeConvertMatrix(rest, ty1, ty2);
        first_1 = typeConvertMatrixRow(first, ty1, ty2);
      then
        (first_1 :: rest_1);
  end matchcontinue;
end typeConvertMatrix;

protected function typeConvertMatrixRow "function: typeConvertMatrixRow
 
  Helper function to type_convert_matrix.
"
  input list<tuple<Exp.Exp, Boolean>> inTplExpExpBooleanLst1;
  input Type inType2;
  input Type inType3;
  output list<tuple<Exp.Exp, Boolean>> outTplExpExpBooleanLst;
algorithm 
  outTplExpExpBooleanLst:=
  matchcontinue (inTplExpExpBooleanLst1,inType2,inType3)
    local
      list<tuple<Exp.Exp, Boolean>> rest;
      Exp.Exp exp_1,exp;
      Type newt,t1,t2;
      Boolean a;
    case ({},_,_) then {}; 
    case (((exp,_) :: rest),t1,t2)
      equation 
        rest = typeConvertMatrixRow(rest, t1, t2);
        (exp_1,newt) = typeConvert(exp, t1, t2);
        a = isArray(t2);
      then
        ((exp_1,a) :: rest);
  end matchcontinue;
end typeConvertMatrixRow;

protected function typeConvertList "function: typeConvertList
 
  Helper function to type_convert.
"
  input list<Exp.Exp> inExpExpLst1;
  input list<Type> inTypeLst2;
  input list<Type> inTypeLst3;
  output list<Exp.Exp> outExpExpLst;
  output list<Type> outTypeLst;
algorithm 
  (outExpExpLst,outTypeLst):=
  matchcontinue (inExpExpLst1,inTypeLst2,inTypeLst3)
    local
      list<Exp.Exp> rest_1,rest;
      list<Type> tyrest_1,ty1rest,ty2rest;
      Exp.Exp first_1,first;
      Type ty_1,ty1,ty2;
    case ({},_,_) then ({},{}); 
    case ((first :: rest),(ty1 :: ty1rest),(ty2 :: ty2rest))
      equation 
        (rest_1,tyrest_1) = typeConvertList(rest, ty1rest, ty2rest);
        (first_1,ty_1) = typeConvert(first, ty1, ty2);
      then
        ((first_1 :: rest_1),(ty_1 :: tyrest_1));
  end matchcontinue;
end typeConvertList;

public function matchWithPromote "function: matchWithPromote
 
  This function is used for matching expressions in matrix construction, 
  where automatic promotion is allowed. This means that array dimensions of 
  size one (1) is added from the right to arrays of matrix construction until
  all elements have the same dimension size (with a maximum of 2).
  For instance, {1,{2}} becomes {1,2}.
  The function also has a flag indicating that Integer to Real 
  conversion can be used.
"
  input Properties inProperties1;
  input Properties inProperties2;
  input Boolean inBoolean3;
  output Properties outProperties;
algorithm 
  outProperties:=
  matchcontinue (inProperties1,inProperties2,inBoolean3)
    local
      Type t,t1,t2;
      Const c,c1,c2;
      ArrayDim dim,dim1,dim2;
      Option<Absyn.Path> p2,p;
      Boolean havereal;
      list<Var> v;
    case (PROP(type_ = (T_ARRAY(arrayDim = dim1,arrayType = t1),_),constFlag = c1),PROP(type_ = (T_ARRAY(arrayDim = dim2,arrayType = t2),p2),constFlag = c2),havereal) /* Allow Integer => Real */ 
      equation 
        PROP(t,c) = matchWithPromote(PROP(t1,c1), PROP(t2,c2), havereal);
        dim = dim1;
      then
        PROP((T_ARRAY(dim,t),p2),c);
    case (PROP(type_ = t1,constFlag = c1),PROP(type_ = (T_ARRAY(arrayDim = DIM(integerOption = SOME(1)),arrayType = t2),p2),constFlag = c2),havereal)
      equation 
        false = isArray(t1);
        PROP(t,c) = matchWithPromote(PROP(t1,c1), PROP(t2,c2), havereal);
      then
        PROP((T_ARRAY(DIM(SOME(1)),t),p2),c);
    case (PROP(type_ = (T_ARRAY(arrayDim = DIM(integerOption = SOME(1)),arrayType = t1),p),constFlag = c1),PROP(type_ = t2,constFlag = c2),havereal)
      equation 
        false = isArray(t2);
        PROP(t,c) = matchWithPromote(PROP(t1,c1), PROP(t2,c2), havereal);
      then
        PROP((T_ARRAY(DIM(SOME(1)),t),p),c);
    case (PROP(type_ = t1,constFlag = c1),PROP(type_ = t2,constFlag = c2),false)
      equation 
        false = isArray(t1);
        false = isArray(t2);
        equality(t1 = t2);
        t = t1;
        c = constAnd(c1, c2);
      then
        PROP(t,c);
    case (PROP(type_ = (T_REAL(varLstReal = v),_),constFlag = c1),PROP(type_ = (T_REAL(varLstReal = _),p2),constFlag = c2),true)
      equation 
        c = constAnd(c1, c2) "Have real and both Real" ;
      then
        PROP((T_REAL(v),p2),c);
    case (PROP(type_ = (T_INTEGER(varLstInt = _),_),constFlag = c1),PROP(type_ = (T_REAL(varLstReal = v),p2),constFlag = c2),true)
      equation 
        c = constAnd(c1, c2) "Have real and first Integer" ;
      then
        PROP((T_REAL(v),p2),c);
    case (PROP(type_ = (T_REAL(varLstReal = v),_),constFlag = c1),PROP(type_ = (T_INTEGER(varLstInt = _),p2),constFlag = c2),true)
      equation 
        c = constAnd(c1, c2) "Have real and second Integer" ;
      then
        PROP((T_REAL(v),p2),c);
    case (PROP(type_ = (T_INTEGER(varLstInt = _),_),constFlag = c1),PROP(type_ = (T_INTEGER(varLstInt = _),p2),constFlag = c2),true)
      equation 
        c = constAnd(c1, c2) "Have real and both Integer" ;
      then
        PROP((T_REAL({}),p2),c);
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
    case (C_CONST(),C_CONST()) then C_CONST(); 
    case (C_CONST(),C_PARAM()) then C_PARAM(); 
    case (C_PARAM(),C_CONST()) then C_PARAM(); 
    case (C_PARAM(),C_PARAM()) then C_PARAM(); 
    case (_,_) then C_VAR(); 
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
    case (C_CONST(),_) then C_CONST(); 
    case (_,C_CONST()) then C_CONST(); 
    case (C_PARAM(),_) then C_PARAM(); 
    case (_,C_PARAM()) then C_PARAM(); 
    case (_,_) then C_VAR(); 
  end matchcontinue;
end constOr;

public function boolConst "function: boolConst
  author: PA
 
  Creates a Const value from a bool. If true, C_CONST,
  if false C_VAR, i.e. there is no way to create a C_PARAM using this 
  function.
"
  input Boolean inBoolean;
  output Const outConst;
algorithm 
  outConst:=
  matchcontinue (inBoolean)
    case (false) then C_VAR(); 
    case (true) then C_CONST(); 
  end matchcontinue;
end boolConst;

public function printPropStr "function: printPropStr
 
  Print the properties to a string.
"
  input Properties inProperties;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inProperties)
    local
      Ident ty_str,const_str,res;
      Type ty;
      Const const;
    case PROP(type_ = ty,constFlag = const)
      equation 
        ty_str = unparseType(ty);
        const_str = unparseConst(const);
        res = Util.stringAppendList({"PROP(",ty_str,const_str,")"});
      then
        res;
    case PROP_TUPLE(type_ = ty,tupleConst = const)
      local TupleConst const;
      equation 
        ty_str = unparseType(ty);
        const_str = unparseTupleconst(const);
        res = Util.stringAppendList({"PROP_TUPLE(",ty_str,", ",const_str,")"});
      then
        res;
  end matchcontinue;
end printPropStr;

public function printProp "function: printProp
 
  Print the Properties to the Print buffer.
"
  input Properties p;
  Ident str;
algorithm 
  str := printPropStr(p);
  Print.printErrorBuf(str);
end printProp;

public function flowVariables "function: flowVariables
 
  This function retrieves all variables names that are flow variables, and 
  prepends the prefix given as an \'Exp.ComponentRef\'
"
  input list<Var> inVarLst;
  input Exp.ComponentRef inComponentRef;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inVarLst,inComponentRef)
    local
      Exp.ComponentRef cr_1,cr;
      list<Exp.ComponentRef> res;
      Ident id;
      list<Var> vs;
    case ({},_) then {}; 
    case ((VAR(name = id,attributes = ATTR(flow_ = true)) :: vs),cr)
      equation 
        cr_1 = Exp.joinCrefs(cr, Exp.CREF_IDENT(id,{}));
        res = flowVariables(vs, cr);
      then
        (cr_1 :: res);
    case ((_ :: vs),cr)
      equation 
        res = flowVariables(vs, cr);
      then
        res;
  end matchcontinue;
end flowVariables;

public function getAllExps "function: getAllExps
  
  This function goes through the Type structure and finds all the
  expressions and returns them in a list
"
  input Type inType;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inType)
    local
      list<Exp.Exp> exps;
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
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inTType)
    local
      list<Exp.Exp> exps,tyexps;
      list<Var> vars;
      list<Ident> strs;
      ArrayDim dim;
      Type ty;
      ClassInf.State cinf;
      Option<Type> bc;
      list<Type> tys;
      list<list<Exp.Exp>> explists,explist;
      list<FuncArg> fargs;
    case T_INTEGER(varLstInt = vars)
      equation 
        exps = getAllExpsVars(vars);
      then
        exps;
    case T_REAL(varLstReal = vars)
      equation 
        exps = getAllExpsVars(vars);
      then
        exps;
    case T_STRING(varLstString = vars)
      equation 
        exps = getAllExpsVars(vars);
      then
        exps;
    case T_BOOL(varLstBool = vars)
      equation 
        exps = getAllExpsVars(vars);
      then
        exps;
    case T_ENUMERATION(names = strs,varLst = vars)
      equation 
        exps = getAllExpsVars(vars);
      then
        exps;
    case T_ARRAY(arrayDim = dim,arrayType = ty)
      equation 
        exps = getAllExps(ty);
      then
        exps;
    case T_COMPLEX(complexClassType = cinf,complexVarLst = vars,complexTypeOption = bc)
      equation 
        exps = getAllExpsVars(vars);
      then
        exps;
    case T_FUNCTION(funcArg = fargs,funcResultType = ty)
      equation 
        tys = Util.listMap(fargs, getFuncargType);
        explists = Util.listMap(tys, getAllExps);
        tyexps = getAllExps(ty);
        exps = Util.listFlatten((tyexps :: explists));
      then
        exps;
    case T_TUPLE(tupleType = tys)
      equation 
        explist = Util.listMap(tys, getAllExps);
        exps = Util.listFlatten(explist);
      then
        exps;
    case _
      equation 
        Debug.fprintln("failtrace", "-- get_all_exps_tt failed");
      then
        fail();
  end matchcontinue;
end getAllExpsTt;

protected function getAllExpsVars "function: getAllExpsVars
 
  Helper function to get_all_exps_tt.
"
  input list<Var> vars;
  output list<Exp.Exp> exps;
  list<list<Exp.Exp>> explist;
algorithm 
  explist := Util.listMap(vars, getAllExpsVar);
  exps := Util.listFlatten(explist);
end getAllExpsVars;

protected function getAllExpsVar "function: getAllExpsVar
 
  Helper function to get_all_exps_vars.
"
  input Var inVar;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inVar)
    local
      list<Exp.Exp> tyexps,bndexp,exps;
      Ident id;
      Attributes attr;
      Boolean prot;
      Type ty;
      Binding bnd;
    case VAR(name = id,attributes = attr,protected_ = prot,type_ = ty,binding = bnd)
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
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inBinding)
    local
      Exp.Exp exp;
      Const cnst;
      Values.Value v;
    case EQBOUND(exp = exp,constant_ = cnst) then {exp}; 
    case UNBOUND() then {}; 
    case VALBOUND(valBound = v) then {}; 
    case _
      equation 
        Debug.fprintln("failtrace", "-- get_all_exps_binding failed");
      then
        fail();
  end matchcontinue;
end getAllExpsBinding;

protected function getFuncargType "function: getFuncargType
 
  Retrieve the type from a function argument.
"
  input FuncArg inFuncArg;
  output Type outType;
algorithm 
  outType:=
  matchcontinue (inFuncArg)
    local
      Ident id;
      Type ty;
    case ((id,ty)) then ty; 
  end matchcontinue;
end getFuncargType;
end Types;

