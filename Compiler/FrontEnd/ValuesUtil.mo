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

encapsulated package ValuesUtil
" file:        ValuesUtil.mo
  package:     ValuesUtil
  description: Evaluated expression values


  The package Values contains utility functions for handling evaluated
  expression values."

public import Absyn;
public import DAE;
public import Values;

protected import Debug;
protected import Dump;
protected import Error;
protected import Expression;
protected import ExpressionSimplify;
protected import ExpressionSimplifyTypes;
protected import Flags;
protected import List;
protected import Print;
protected import System;
protected import ClassInf;
protected import Types;

public function typeConvert "Apply type conversion on a list of Values"
  input DAE.Type inType1;
  input DAE.Type inType2;
  input list<Values.Value> inValueLst3;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst := match (inType1,inType2,inValueLst3)
    local
      list<Values.Value> vallst,vrest,vallst2,vals;
      Real rval,r;
      DAE.Type from,to;
      Integer i,ival;
      list<Integer> dims;

    case (_,_,{}) then {};

    case (from as DAE.T_INTEGER(),to as DAE.T_REAL(),(Values.INTEGER(integer = i) :: vrest))
      equation
        vallst = typeConvert(from, to, vrest);
        rval = intReal(i);
      then
        (Values.REAL(rval) :: vallst);

    case (from as DAE.T_REAL(),to as DAE.T_INTEGER(),(Values.REAL(real = r) :: vrest))
      equation
        vallst = typeConvert(from, to, vrest);
        ival = realInt(r);
      then
        (Values.INTEGER(ival) :: vallst);

    case (from,to,(Values.ARRAY(valueLst = vals, dimLst = dims) :: vrest))
      equation
        vallst = typeConvert(from, to, vals);
        vallst2 = typeConvert(from, to, vrest);
      then
        (Values.ARRAY(vallst,dims) :: vallst2);
  end match;
end typeConvert;

public function valueExpType "creates a DAE.Type from a Value"
  input Values.Value inValue;
  output DAE.Type tp;
algorithm
  tp := matchcontinue(inValue)
  local
    Absyn.Path path;
    Integer indx;
    list<String> nameLst;
    DAE.Type eltTp;
    list<Values.Value> valLst;
    list<DAE.Type> eltTps;
    list<DAE.Var> varLst;
    list<Integer> int_dims;
    DAE.Dimensions dims;

    case(Values.INTEGER(_)) then DAE.T_INTEGER_DEFAULT;
    case(Values.REAL(_)) then DAE.T_REAL_DEFAULT;
    case(Values.BOOL(_)) then DAE.T_BOOL_DEFAULT;
    case(Values.STRING(_)) then DAE.T_STRING_DEFAULT;
    case(Values.ENUM_LITERAL(name = path))
      equation
        path = Absyn.pathPrefix(path);
      then DAE.T_ENUMERATION(NONE(),path,{},{},{},DAE.emptyTypeSource);
    case(Values.ARRAY(valLst,int_dims)) equation
      eltTp=valueExpType(listHead(valLst));
      dims = List.map(int_dims, Expression.intDimension);
    then DAE.T_ARRAY(eltTp,dims,DAE.emptyTypeSource);

    case(Values.RECORD(path,valLst,nameLst,_)) equation
      eltTps = List.map(valLst,valueExpType);
      varLst = List.threadMap(eltTps,nameLst,valueExpTypeExpVar);
    then DAE.T_COMPLEX(ClassInf.RECORD(path),varLst,NONE(),DAE.emptyTypeSource);

    case _
      equation
        print("valueExpType on "+valString(inValue) + " not implemented yet\n");
      then fail();
  end matchcontinue;
end valueExpType;

protected function valueExpTypeExpVar "help function to valueExpType"
  input DAE.Type etp;
  input String name;
  output DAE.Var expVar;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  expVar := DAE.TYPES_VAR(name, DAE.dummyAttrVar, etp, DAE.UNBOUND(), NONE());
end valueExpTypeExpVar;

public function isZero "Returns true if value is zero"
  input Values.Value inValue;
  output Boolean isZero;
algorithm
  isZero := match(inValue)
    local
      Real rval;
      Integer ival;

    case Values.REAL(rval) then realEq(rval, 0.0);
    case Values.INTEGER(ival) then intEq(ival, 0);
    else false;
  end match;
end isZero;

public function makeZero "Returns a zero value based on a DAE.Type"
  input DAE.Type ty;
  output Values.Value zero;
algorithm
  zero := match ty
    case DAE.T_REAL() then Values.REAL(0.0);
    case DAE.T_INTEGER() then Values.INTEGER(0);
  end match;
end makeZero;

public function isArray "Return true if Value is an array."
  input Values.Value inValue;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inValue)
    case (Values.ARRAY()) then true;
    else false;
  end match;
end isArray;

public function isRecord "Return true if Value is an array."
  input Values.Value inValue;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inValue)
    case (Values.RECORD()) then true;
    else false;
  end match;
end isRecord;

public function nthArrayelt "author: PA
  Return the nth value of an array, indexed from 1..n"
  input Values.Value inValue;
  input Integer inInteger;
  output Values.Value outValue;
protected
  list<Values.Value> vlst;
algorithm
  Values.ARRAY(valueLst=vlst) := inValue;
  outValue := listGet(vlst, inInteger);
end nthArrayelt;

public function unparseValues "Prints a list of Value to a string."
  input list<Values.Value> inValueLst;
  output String outString;
algorithm
  outString := match (inValueLst)
    local
      String s1,s2,s3,str;
      Values.Value v;
      list<Values.Value> vallst;
    case ((v :: vallst))
      equation
        s1 = unparseDescription({v});
        s2 = unparseValueNumbers({v});
        s3 = unparseValues(vallst);
        str = stringAppendList({s1,s2,"\n",s3});
      then
        str;
    case ({}) then "";
  end match;
end unparseValues;

protected function unparseValueNumbers "Helper function to unparse_values.
  Prints all the numbers of the values."
  input list<Values.Value> inValueLst;
  output String outString;
algorithm
  outString := match (inValueLst)
    local
      String s1,s2,res,istr,sval;
      list<Values.Value> lst,xs;
      Integer i;
      Real r;
    case ((Values.TUPLE(valueLst = lst) :: xs))
      equation
        s1 = unparseValueNumbers(lst);
        s2 = unparseValueNumbers(xs);
        res = stringAppend(s1, s2);
      then
        res;
    case ((Values.META_TUPLE(valueLst = lst) :: xs))
      equation
        s1 = unparseValueNumbers(lst);
        s2 = unparseValueNumbers(xs);
        res = stringAppend(s1, s2);
      then
        res;
    case ((Values.ARRAY(valueLst = lst) :: xs))
      equation
        s1 = unparseValueNumbers(lst);
        s2 = unparseValueNumbers(xs);
        res = stringAppend(s1, s2);
      then
        res;
    case ((Values.INTEGER(integer = i) :: xs))
      equation
        s1 = unparseValueNumbers(xs);
        istr = intString(i);
        s2 = stringAppend(istr, " ");
        res = stringAppend(s2, s1);
      then
        res;
    case ((Values.REAL(real = r) :: xs))
      equation
        s1 = unparseValueNumbers(xs);
        istr = realString(r);
        s2 = stringAppend(istr, " ");
        res = stringAppend(s2, s1);
      then
        res;
    case ((Values.STRING(string = sval) :: xs))
      equation
        s1 = unparseValueNumbers(xs);
        s2 = stringAppend(sval, " ");
        res = stringAppend(s2, s1);
      then
        res;
    case ({}) then "";
  end match;
end unparseValueNumbers;

public function safeIntRealOp
  "Performs mul, div, sub, add and pow on integers and reals.
   If for example an integer multiplication does not fit in a
   integer, a real is returned instead. The is not the ideal way of
   handling this, since the types are decided in run-time. Currently,
   this is the simplest and best alternative for the moment though.

   In the future, we should introduce BIG-INTS, or maybe throw exceptions
   (when exceptions are available in the language).
  "
  input Values.Value val1;
  input Values.Value val2;
  input Values.IntRealOp op;
  output Values.Value outv;
algorithm
  outv := matchcontinue(val1, val2, op)
    local
      Real rv1,rv2,rv3;
      Integer iv1, iv2;
      DAE.Exp e;
      //MUL
    case (Values.INTEGER(iv1),Values.INTEGER(iv2), Values.MULOP())
      equation
        e = ExpressionSimplify.safeIntOp(iv1,iv2,ExpressionSimplifyTypes.MULOP());
        outv = expValue(e);
      then
        outv;
    case (Values.REAL(rv1),Values.INTEGER(iv2), Values.MULOP())
      equation
        rv2 = intReal(iv2);
        rv3 = rv1 * rv2;
      then
        Values.REAL(rv3);
    case (Values.INTEGER(iv1), Values.REAL(rv2), Values.MULOP())
      equation
        rv1 = intReal(iv1);
        rv3 = rv1 * rv2;
      then
        Values.REAL(rv3);
    case (Values.REAL(rv1), Values.REAL(rv2), Values.MULOP())
      equation
        rv3 = rv1 * rv2;
      then
        Values.REAL(rv3);
        //DIV
    case (Values.INTEGER(iv1),Values.INTEGER(iv2), Values.DIVOP())
      equation
        e = ExpressionSimplify.safeIntOp(iv1,iv2,ExpressionSimplifyTypes.DIVOP());
        outv = expValue(e);
      then
        outv;
    case (Values.REAL(rv1),Values.INTEGER(iv2), Values.DIVOP())
      equation
        rv2 = intReal(iv2);
        rv3 = rv1 / rv2;
      then
        Values.REAL(rv3);
    case (Values.INTEGER(iv1), Values.REAL(rv2), Values.DIVOP())
      equation
        rv1 = intReal(iv1);
        rv3 = rv1 / rv2;
      then
        Values.REAL(rv3);
    case (Values.REAL(rv1), Values.REAL(rv2), Values.DIVOP())
      equation
        rv3 = rv1 / rv2;
      then
        Values.REAL(rv3);
        //POW
    case (Values.INTEGER(iv1),Values.INTEGER(iv2), Values.POWOP()) // this means indirect that we are dealing with decimal numbers (a^(-b)) = 1/a^b
      equation
        true = (iv2 < 0);
        rv1 = intReal(iv1);
        rv2 = intReal(iv2);
        rv3 = realPow(rv1, rv2);
      then
        Values.REAL(rv3);
    case (Values.INTEGER(iv1),Values.INTEGER(iv2), Values.POWOP())
      equation
        e = ExpressionSimplify.safeIntOp(iv1,iv2,ExpressionSimplifyTypes.POWOP());
        outv = expValue(e);
      then
        outv;
    case (Values.REAL(rv1),Values.INTEGER(iv2), Values.POWOP())
      equation
        rv2 = intReal(iv2);
        rv3 = realPow(rv1, rv2);
      then
        Values.REAL(rv3);
    case (Values.INTEGER(iv1), Values.REAL(rv2), Values.POWOP())
      equation
        iv2 = realInt(rv2);
        e = ExpressionSimplify.safeIntOp(iv1,iv2,ExpressionSimplifyTypes.POWOP());
        outv = expValue(e);
      then
        outv;
    case (Values.INTEGER(iv1), Values.REAL(rv2), Values.POWOP())
      equation
        rv1 = intReal(iv1);
        rv3 = realPow(rv1, rv2);
      then
        Values.REAL(rv3);
    case (Values.REAL(rv1), Values.REAL(rv2), Values.POWOP())
      equation
        rv3 = realPow(rv1, rv2);
      then
        Values.REAL(rv3);
        //ADD
    case (Values.INTEGER(iv1),Values.INTEGER(iv2), Values.ADDOP())
      equation
        e = ExpressionSimplify.safeIntOp(iv1,iv2,ExpressionSimplifyTypes.ADDOP());
        outv = expValue(e);
      then
        outv;
    case (Values.REAL(rv1),Values.INTEGER(iv2), Values.ADDOP())
      equation
        rv2 = intReal(iv2);
        rv3 = rv1 + rv2;
      then
        Values.REAL(rv3);
    case (Values.INTEGER(iv1), Values.REAL(rv2), Values.ADDOP())
      equation
        rv1 = intReal(iv1);
        rv3 = rv1 + rv2;
      then
        Values.REAL(rv3);
    case (Values.REAL(rv1), Values.REAL(rv2), Values.ADDOP())
      equation
        rv3 = rv1 + rv2;
      then
        Values.REAL(rv3);
        //SUB
    case (Values.INTEGER(iv1),Values.INTEGER(iv2), Values.SUBOP())
      equation
        e = ExpressionSimplify.safeIntOp(iv1,iv2,ExpressionSimplifyTypes.SUBOP());
        outv = expValue(e);
      then
        outv;
    case (Values.REAL(rv1),Values.INTEGER(iv2), Values.SUBOP())
      equation
        rv2 = intReal(iv2);
        rv3 = rv1 - rv2;
      then
        Values.REAL(rv3);
    case (Values.INTEGER(iv1), Values.REAL(rv2), Values.SUBOP())
      equation
        rv1 = intReal(iv1);
        rv3 = rv1 - rv2;
      then
        Values.REAL(rv3);
    case (Values.REAL(rv1), Values.REAL(rv2), Values.SUBOP())
      equation
        rv3 = rv1 - rv2;
      then
        Values.REAL(rv3);
  end matchcontinue;
end safeIntRealOp;

public function safeLessEq
  "Checks if val1 is less or equal to val2. Val1 or val2 can be integers (or
  something that can be converted to integer) or reals."
  input Values.Value val1;
  input Values.Value val2;
  output Boolean outv;
algorithm
  outv := match(val1, val2)
    local
      Real r1, r2;
      Integer i1, i2;

    case (Values.REAL(r1), Values.REAL(r2))
      then (r1 <= r2);

    case (Values.REAL(r1), _)
      equation
        r2 = intReal(valueInteger(val2));
      then (r1 <= r2);

    case (_, Values.REAL(r2))
      equation
        r1 = intReal(valueInteger(val1));
      then (r1 <= r2);

    case (_, _)
      equation
        i1 = valueInteger(val1);
        i2 = valueInteger(val2);
      then
        (i1 <= i2);
  end match;
end safeLessEq;

protected function unparseDescription "
  Helper function to unparse_values. Creates a description string
  for the type of the value.
"
  input list<Values.Value> inValueLst;
  output String outString;
algorithm
  outString:=
  match (inValueLst)
    local
      String s1,str,slenstr,sval,s2,s4;
      list<Values.Value> xs,vallst;
      Integer slen;
    case ((Values.INTEGER() :: xs))
      equation
        s1 = unparseDescription(xs);
        str = stringAppend("# i!\n", s1);
      then
        str;
    case ((Values.REAL() :: xs))
      equation
        s1 = unparseDescription(xs);
        str = stringAppend("# r!\n", s1);
      then
        str;
    case ((Values.STRING(string = sval) :: xs))
      equation
        _ = unparseDescription(xs);
        slen = stringLength(sval);
        slenstr = intString(slen);
        str = stringAppendList({"# s! 1 ",slenstr,"\n"});
      then
        str;
    case ((Values.ARRAY(valueLst = vallst) :: xs))
      equation
        s1 = unparseDescription(xs);
        s2 = unparseArrayDescription(vallst);
        s4 = stringAppend(s2, s1);
        str = stringAppend(s4, " \n");
      then
        str;
    case ({}) then "";
  end match;
end unparseDescription;

protected function unparseArrayDescription "
  Helper function to unparse_description.
"
  input list<Values.Value> lst;
  output String str;
protected
  String pt,s1,s2,s3,s4,s5,s6;
  Integer i1;
algorithm
  pt := unparsePrimType(lst);
  s1 := stringAppend("# ", pt);
  s2 := stringAppend(s1, "[");
  i1 := unparseNumDims(lst,0);
  s3 := intString(i1);
  s4 := stringAppend(s2, s3);
  s5 := stringAppend(s4, " ");
  s6 := unparseDimSizes(lst);
  str := stringAppend(s5, s6);
end unparseArrayDescription;

protected function unparsePrimType "
  Helper function to unparse_array_description.
"
  input list<Values.Value> inValueLst;
  output String outString;
algorithm
  outString:=
  match (inValueLst)
    local
      String res;
      list<Values.Value> elts;
    case ((Values.ARRAY(valueLst = elts) :: _))
      equation
        res = unparsePrimType(elts);
      then
        res;
    case ((Values.INTEGER() :: _)) then "i";
    case ((Values.REAL() :: _)) then "r";
    case ((Values.STRING() :: _)) then "s";
    case ((Values.BOOL() :: _)) then "b";
    case ({}) then "{}";
    else "error";
  end match;
end unparsePrimType;

protected function unparseNumDims "
  Helper function to unparse_array_description.
"
  input list<Values.Value> inValueLst;
  input Integer inInteger;
  output Integer outInteger;
algorithm
  outInteger:=
  match (inValueLst)
    local
      Integer i1;
      list<Values.Value> vals;
    case ((Values.ARRAY(valueLst = vals) :: _))
      then
        unparseNumDims(vals, inInteger + 1);
    else inInteger + 1;
  end match;
end unparseNumDims;

protected function unparseDimSizes "
  Helper function to unparse_array_description.
"
  input list<Values.Value> inValueLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inValueLst)
    local
      Integer i1,len;
      String s1,s2,s3,res;
      list<Values.Value> lst,vals;
    case ((lst as (Values.ARRAY(valueLst = vals) :: _)))
      equation
        i1 = listLength(lst);
        s1 = intString(i1);
        s2 = stringAppend(s1, " ");
        s3 = unparseDimSizes(vals);
        res = stringAppend(s2, s3);
      then
        res;
    case (lst)
      equation
        len = listLength(lst);
        res = intString(len);
      then
        res;
  end matchcontinue;
end unparseDimSizes;

public function writeToFileAsArgs "
  Write a list of Values to a file. This function is used when
  writing the formal input arguments of a function call to a file before
  executing the function.
"
  input list<Values.Value> vallst;
  input String filename;
protected
  String str;
algorithm
  str := unparseValues(vallst);
  System.writeFile(filename, str);
end writeToFileAsArgs;

public function addElementwiseArrayelt "
  Perform elementwise addition of two arrays.
"
  input list<Values.Value> inValueLst1;
  input list<Values.Value> inValueLst2;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst:=
  match (inValueLst1,inValueLst2)
    local
      list<Values.Value> reslst,res2,v1lst,rest1,v2lst,rest2;
      Integer res,v1,v2;
      Real r1,r2,rres;
      String s1,s2,sres;
      list<Integer> dims;
    case ((Values.ARRAY(valueLst = v1lst, dimLst = dims) :: rest1),(Values.ARRAY(valueLst = v2lst) :: rest2))
      equation
        reslst = addElementwiseArrayelt(v1lst, v2lst);
        res2 = addElementwiseArrayelt(rest1, rest2);
      then
        (Values.ARRAY(reslst,dims) :: res2);
    case ((Values.INTEGER(integer = v1) :: rest1),(Values.INTEGER(integer = v2) :: rest2))
      equation
        res = v1 + v2;
        res2 = addElementwiseArrayelt(rest1, rest2);
      then
        (Values.INTEGER(res) :: res2);
    case ((Values.REAL(real = r1) :: rest1),(Values.REAL(real = r2) :: rest2))
      equation
        rres = r1 + r2;
        res2 = addElementwiseArrayelt(rest1, rest2);
      then
        (Values.REAL(rres) :: res2);
    case ((Values.STRING(string = s1) :: rest1),(Values.STRING(string = s2) :: rest2))
      equation
        sres = stringAppend(s1, s2);
        res2 = addElementwiseArrayelt(rest1, rest2) "Addition of strings is string concatenation" ;
      then
        (Values.STRING(sres) :: res2);
    case ({},{}) then {};
  end match;
end addElementwiseArrayelt;

public function subElementwiseArrayelt "
  Perform element subtraction of two arrays of values
"
  input list<Values.Value> inValueLst1;
  input list<Values.Value> inValueLst2;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst:=
  match (inValueLst1,inValueLst2)
    local
      list<Values.Value> reslst,res2,v1lst,rest1,v2lst,rest2;
      Integer res,v1,v2;
      list<Integer> dims;
      Real r1,r2,rres;
    case ((Values.ARRAY(valueLst = v1lst, dimLst = dims) :: rest1),(Values.ARRAY(valueLst = v2lst) :: rest2))
      equation
        reslst = subElementwiseArrayelt(v1lst, v2lst);
        res2 = subElementwiseArrayelt(rest1, rest2);
      then
        (Values.ARRAY(reslst,dims) :: res2);
    case ((Values.INTEGER(integer = v1) :: rest1),(Values.INTEGER(integer = v2) :: rest2))
      equation
        res = v1 - v2;
        res2 = subElementwiseArrayelt(rest1, rest2);
      then
        (Values.INTEGER(res) :: res2);
    case ((Values.REAL(real = r1) :: rest1),(Values.REAL(real = r2) :: rest2))
      equation
        rres = r1 - r2;
        res2 = subElementwiseArrayelt(rest1, rest2);
      then
        (Values.REAL(rres) :: res2);
    case ({},{}) then {};
  end match;
end subElementwiseArrayelt;

public function mulElementwiseArrayelt "
  Perform elementwise multiplication of two arrays of values
"
  input list<Values.Value> inValueLst1;
  input list<Values.Value> inValueLst2;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst:=
  match (inValueLst1,inValueLst2)
    local
      list<Values.Value> reslst,res2,v1lst,rest1,v2lst,rest2;
      Integer res,v1,v2;
      list<Integer> dims;
      Real rres,r1,r2;
    case ((Values.ARRAY(valueLst = v1lst, dimLst = dims) :: rest1),(Values.ARRAY(valueLst = v2lst) :: rest2))
      equation
        reslst = mulElementwiseArrayelt(v1lst, v2lst);
        res2 = mulElementwiseArrayelt(rest1, rest2);
      then
        (Values.ARRAY(reslst,dims) :: res2);
    case ((Values.INTEGER(integer = v1) :: rest1),(Values.INTEGER(integer = v2) :: rest2))
      equation
        res = v1 * v2;
        res2 = mulElementwiseArrayelt(rest1, rest2);
      then
        (Values.INTEGER(res) :: res2);
    case ((Values.REAL(real = r1) :: rest1),(Values.REAL(real = r2) :: rest2))
      equation
        rres = r1 * r2;
        res2 = mulElementwiseArrayelt(rest1, rest2);
      then
        (Values.REAL(rres) :: res2);
    case ({},{}) then {};
  end match;
end mulElementwiseArrayelt;

public function divElementwiseArrayelt "
  Perform elementwise division of two arrays of values
"
  input list<Values.Value> inValueLst1;
  input list<Values.Value> inValueLst2;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst:=
  match (inValueLst1,inValueLst2)
    local
      list<Values.Value> reslst,res2,v1lst,rest1,v2lst,rest2;
      Real res,r1,r2;
      Integer i1,i2;
      list<Integer> dims;
    case ((Values.ARRAY(valueLst = v1lst, dimLst = dims) :: rest1),(Values.ARRAY(valueLst = v2lst) :: rest2))
      equation
        reslst = divElementwiseArrayelt(v1lst, v2lst);
        res2 = divElementwiseArrayelt(rest1, rest2);
      then
        (Values.ARRAY(reslst,dims) :: res2);
    case ((Values.INTEGER(integer = i1) :: rest1),(Values.INTEGER(integer = i2) :: rest2))
      equation
        r1=intReal(i1);
        r2=intReal(i2);
        res = r1 / r2;
        res2 = divElementwiseArrayelt(rest1, rest2);
      then
        (Values.REAL(res) :: res2);
    case ((Values.REAL(real = r1) :: rest1),(Values.REAL(real = r2) :: rest2))
      equation
        res = r1 / r2;
        res2 = divElementwiseArrayelt(rest1, rest2);
      then
        (Values.REAL(res) :: res2);
    case ({},{}) then {};
  end match;
end divElementwiseArrayelt;

public function powElementwiseArrayelt "
  Computes elementwise powers of two arrays of values
"
  input list<Values.Value> inValueLst1;
  input list<Values.Value> inValueLst2;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst:=
  match (inValueLst1,inValueLst2)
    local
      list<Values.Value> reslst,res2,v1lst,rest1,v2lst,rest2;
      Integer i1,i2;
      Real res,r1,r2;
      list<Integer> dims;
    case ((Values.ARRAY(valueLst = v1lst, dimLst = dims) :: rest1),(Values.ARRAY(valueLst = v2lst) :: rest2))
      equation
        reslst = powElementwiseArrayelt(v1lst, v2lst);
        res2 = powElementwiseArrayelt(rest1, rest2);
      then
        (Values.ARRAY(reslst,dims) :: res2);
    case ((Values.INTEGER(integer = i1) :: rest1),(Values.INTEGER(integer = i2) :: rest2))
      equation
        r1=intReal(i1);
        r2=intReal(i2);
        res = r1 ^ r2;
        res2 = powElementwiseArrayelt(rest1, rest2);
      then
        (Values.REAL(res) :: res2);
    case ((Values.REAL(real = r1) :: rest1),(Values.REAL(real = r2) :: rest2))
      equation
        res = r1 ^ r2;
        res2 = powElementwiseArrayelt(rest1, rest2);
      then
        (Values.REAL(res) :: res2);
    case ({},{}) then {};
  end match;
end powElementwiseArrayelt;

public function expValue "Returns the value of constant expressions in DAE.Exp"
  input DAE.Exp inExp;
  output Values.Value outValue;
algorithm
  outValue := match (inExp)
    local
      Integer i;
      Real r;
      Boolean b;
      String s;
    case DAE.ICONST(integer = i) then Values.INTEGER(i);
    case DAE.RCONST(real = r) then Values.REAL(r);
    case DAE.SCONST(string = s) then Values.STRING(s);
    case DAE.BCONST(bool = b) then Values.BOOL(b);
  end match;
end expValue;

public function valueExp "Transforms a Value into an Exp"
  input Values.Value inValue;
  output DAE.Exp outExp;
algorithm
  outExp := match (inValue)
    local
      Integer dim;
      list<DAE.Exp> explist;
      DAE.Type vt;
      DAE.Type t;
      DAE.Exp e;
      Values.Value v;
      list<Values.Value> xs,xs2,vallist;
      list<DAE.Type> typelist;
      list<Integer> int_dims;
      DAE.Dimensions dims;
      Integer i;
      Real r;
      String s, scope, name, tyStr;
      Boolean b;
      list<DAE.Exp> expl;
      list<DAE.Type> tpl;
      list<String> namelst;
      list<DAE.Var> varlst;
      Integer ix;
      Absyn.Path path;
      Absyn.CodeNode code;
      Values.Value valType;
      DAE.Type ety;

    case (Values.INTEGER(integer = i)) then DAE.ICONST(i);
    case (Values.REAL(real = r))       then DAE.RCONST(r);
    case (Values.STRING(string = s))   then DAE.SCONST(s);
    case (Values.BOOL(boolean = b))    then DAE.BCONST(b);
    case (Values.ENUM_LITERAL(name = path, index = i)) then DAE.ENUM_LITERAL(path, i);

    case (Values.ARRAY(valueLst = vallist, dimLst = int_dims)) then valueExpArray(vallist,int_dims);

    case (Values.TUPLE(valueLst = vallist))
      equation
        explist = List.map(vallist, valueExp);
      then
        DAE.TUPLE(explist);

    case(Values.RECORD(path,vallist,namelst,-1))
      equation
        expl = List.map(vallist,valueExp);
        tpl = List.map(expl,Expression.typeof);
        varlst = List.threadMap(namelst,tpl,Expression.makeVar);
        t = DAE.T_COMPLEX(ClassInf.RECORD(path),varlst,NONE(),DAE.emptyTypeSource);
      then DAE.RECORD(path,expl,namelst,t);

    case(Values.ENUM_LITERAL(name = path, index = ix))
      then DAE.ENUM_LITERAL(path, ix);

    case (Values.TUPLE(vallist))
      equation
        explist = List.map(vallist, valueExp);
      then DAE.TUPLE(explist);

    /* MetaModelica types */
    case (Values.OPTION(SOME(v)))
      equation
        e = valueExp(v);
        (e,_) = Types.matchType(e, Types.typeOfValue(v), DAE.T_METABOXED_DEFAULT, true);
      then DAE.META_OPTION(SOME(e));

    case (Values.OPTION(NONE())) then DAE.META_OPTION(NONE());

    case (Values.META_TUPLE(vallist))
      equation
        explist = List.map(vallist, valueExp);
        typelist = List.map(vallist, Types.typeOfValue);
        (explist,_) = Types.matchTypeTuple(explist, typelist, List.map(typelist, Types.boxIfUnboxedType), true);
      then DAE.META_TUPLE(explist);

    case (Values.LIST({})) then DAE.LIST({});

    case (Values.LIST(vallist))
      equation
        explist = List.map(vallist, valueExp);
        typelist = List.map(vallist, Types.typeOfValue);
        vt = Types.boxIfUnboxedType(List.reduce(typelist,Types.superType));
        (explist,_) = Types.matchTypes(explist, typelist, vt, true);
      then DAE.LIST(explist);

      /* MetaRecord */
    case (Values.RECORD(path,vallist,namelst,ix))
      equation
        true = ix >= 0;
        explist = List.map(vallist, valueExp);
        typelist = List.map(vallist, Types.typeOfValue);
        (explist,_) = Types.matchTypeTuple(explist, typelist, List.map(typelist, Types.boxIfUnboxedType), true);
      then DAE.METARECORDCALL(path,explist,namelst,ix,{});

    case (Values.META_FAIL())
      then DAE.CALL(Absyn.IDENT("fail"),{},DAE.callAttrBuiltinOther);

    case (Values.META_BOX(v))
      equation
        e = valueExp(v);
      then DAE.BOX(e);

    case (Values.CODE(A=code))
      then DAE.CODE(code,DAE.T_UNKNOWN_DEFAULT);

    case (Values.EMPTY(scope = scope, name = name, tyStr = tyStr, ty = valType))
      equation
        ety = Types.simplifyType(Types.typeOfValue(valType));
      then
        DAE.EMPTY(scope, DAE.CREF_IDENT(name, ety, {}), ety, tyStr);

    case (Values.NORETCALL())
      then DAE.TUPLE({});

    case (v)
      equation
        s = "ValuesUtil.valueExp failed for " + valString(v);
        Error.addMessage(Error.INTERNAL_ERROR, {s});
      then
        fail();
  end match;
end valueExp;

protected function valueExpArray
  input list<Values.Value> values;
  input list<Integer> inDims;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (values,inDims)
    local
      Values.Value v;
      list<Values.Value> xs,xs2;
      list<DAE.Exp> explist;
      DAE.Dimensions dims;
      list<Integer> int_dims;
      DAE.Type t,vt;
      Integer dim,i;
      Boolean b;
      list<list<DAE.Exp>> mexpl;
    case ({},{}) then DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT,false,{});
    case ({},_)
      equation
        dims = List.map(inDims, Expression.intDimension);
      then DAE.ARRAY(DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT, dims, DAE.emptyTypeSource),false,{});

    // Matrix
    case(Values.ARRAY(valueLst=v::xs)::xs2,dim::int_dims)
      equation
        failure(Values.ARRAY() = v);
        explist = List.map((v :: xs), valueExp);
        DAE.MATRIX(t,_,mexpl) = valueExp(Values.ARRAY(xs2,int_dims));
        t = Expression.arrayDimensionSetFirst(t, DAE.DIM_INTEGER(dim));
      then
        DAE.MATRIX(t,dim,explist::mexpl);

    // Matrix last row
    case({Values.ARRAY(valueLst=v::xs)},_)
      equation
        failure(Values.ARRAY() = v);
        dim = listLength(v::xs);
        explist = List.map((v :: xs), valueExp);
        vt = Types.typeOfValue(v);
        t = Types.simplifyType(vt);
        dim = listLength(v::xs);
        t = Expression.liftArrayR(t,DAE.DIM_INTEGER(dim));
        t = Expression.liftArrayR(t,DAE.DIM_INTEGER(1));
      then
        DAE.MATRIX(t,dim,{explist});

    // Generic array
    case (v :: xs,_)
      equation
        explist = List.map((v :: xs), valueExp);
        vt = Types.typeOfValue(v);
        t = Types.simplifyType(vt);
        dim = listLength(v::xs);
        t = Expression.liftArrayR(t,DAE.DIM_INTEGER(dim));
        b = Types.isArray(vt);
        b = boolNot(b);
      then DAE.ARRAY(t,b,explist);
  end matchcontinue;
end valueExpArray;

public function valueReal "
  Return the real value of a Value. If the value is an integer,
  it is cast to a real.
"
  input Values.Value inValue;
  output Real outReal;
algorithm
  outReal:=
  match (inValue)
    local
      Real r;
      Integer i;
    case (Values.REAL(real = r)) then r;
    case (Values.INTEGER(integer = i))
      equation
        r = intReal(i);
      then
        r;
  end match;
end valueReal;

public function valueBool "Author: BZ, 2008-09
  Return the bool value of a Value.
"
  input Values.Value inValue;
  output Boolean outBool;
algorithm
  outBool:= match (inValue)
    case (Values.BOOL(outBool)) then outBool;
  end match;
end valueBool;

public function valueReals "
  Return the real value of a Value. If the value is an integer,
  it is cast to a real.
"
  input list<Values.Value> inValue;
  output list<Real> outReal;
algorithm
  outReal:=
  matchcontinue (inValue)
    local
      Real r;
      list<Values.Value> rest;
      list<Real> res;
      Integer i;
    case ({}) then {};
    case (Values.REAL(real = r)::rest)
      equation
        res = valueReals(rest);
       then
         r::res;
    case (Values.INTEGER(integer = i)::rest)
      equation
        r = intReal(i);
        res = valueReals(rest);
      then
        r::res;
    case (_::rest)
      equation
        res = valueReals(rest);
      then
        res;
  end matchcontinue;
end valueReals;

public function arrayValueInts
  "Returns the integer values of a Values array."
  input Values.Value inValue;
  output list<Integer> outReal;
protected
  list<Values.Value> vals;
algorithm
  Values.ARRAY(valueLst=vals) := inValue;
  outReal := List.map(vals, valueInteger);
end arrayValueInts;

public function arrayValueReals "
  Return the real value of a Value. If the value is an integer,
  it is cast to a real.
"
  input Values.Value inValue;
  output list<Real> outReal;
protected
  list<Values.Value> vals;
algorithm
  Values.ARRAY(valueLst=vals) := inValue;
  outReal := valueReals(vals);
end arrayValueReals;

public function matrixValueReals
  "Returns the real values of a Values matrix."
  input Values.Value inValue;
  output list<list<Real>> outReals;
algorithm
  outReals := matchcontinue(inValue)
    local
      list<Values.Value> vals;
      list<Real> reals;

    // A matrix.
    case Values.ARRAY(valueLst = vals)
      then List.map(vals, arrayValueReals);

    // A 1-dimensional array.
    case Values.ARRAY(valueLst = vals)
      equation
        reals = valueReals(vals);
      then
        List.map(reals, List.create);

  end matchcontinue;
end matrixValueReals;

public function valueNeg "author: PA

  Negates a Value
"
  input Values.Value inValue;
  output Values.Value outValue;
algorithm
  outValue:=
  match (inValue)
    local
      Real r_1,r;
      Integer i_1,i;
      list<Values.Value> vlst_1,vlst;
      list<Integer> dims;
    case (Values.REAL(real = r))
      equation
        r_1 = - r;
      then
        Values.REAL(r_1);
    case (Values.INTEGER(integer = i))
      equation
        i_1 = -i;
      then
        Values.INTEGER(i_1);
    case Values.ARRAY(valueLst = vlst, dimLst = dims)
      equation
        vlst_1 = List.map(vlst, valueNeg);
      then
        Values.ARRAY(vlst_1,dims);
  end match;
end valueNeg;

public function sumArrayelt "
  Calculate the sum of a list of Values.
"
  input list<Values.Value> inValueLst;
  output Values.Value outValue;
algorithm
  outValue:=
  matchcontinue (inValueLst)
    local
      Integer i1,i2,i3;
      Real r1,r2,r3;
      list<Values.Value> v1,v2,v3;
      list<Values.Value> xs,arr;
      list<Integer> dims;
    case ({Values.INTEGER(integer = i1)}) then Values.INTEGER(i1);
    case ({Values.REAL(real = r1)}) then Values.REAL(r1);
    case ({Values.ARRAY(valueLst = v1, dimLst = dims)}) then Values.ARRAY(v1,dims);
    case ((Values.INTEGER(integer = i2) :: xs))
      equation
        Values.INTEGER(i1) = sumArrayelt(xs);
        i3 = i1 + i2;
      then
        Values.INTEGER(i3);
    case ((Values.REAL(real = r2) :: xs))
      equation
        Values.REAL(r1) = sumArrayelt(xs);
        r3 = r1 + r2;
      then
        Values.REAL(r3);
    case ((arr as (Values.ARRAY(valueLst = v2) :: _)))
      equation
        Values.ARRAY(v1,dims) = sumArrayelt(arr);
        v3 = addElementwiseArrayelt(v1, v2);
      then
        Values.ARRAY(v3,dims);
  end matchcontinue;
end sumArrayelt;

public function multScalarArrayelt "
  Multiply a scalar with an list of Values, i.e. array.
"
  input Values.Value inValue;
  input list<Values.Value> inValueLst;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst:=
  match (inValue,inValueLst)
    local
      list<Values.Value> v1,v2,vals,rest;
      Values.Value sval;
      Integer i1,i2;
      Real r1,r2;
      list<Integer> dims;
    case (sval,(Values.ARRAY(valueLst = vals, dimLst = dims) :: rest))
      equation
        v1 = multScalarArrayelt(sval, vals);
        v2 = multScalarArrayelt(sval, rest);
      then
        (Values.ARRAY(v1,dims) :: v2);
    case ((sval as Values.INTEGER(integer = i1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        i1 = i1*i2;
        v2 = multScalarArrayelt(sval, rest);
      then
        (Values.INTEGER(i1) :: v2);
    case ((sval as Values.REAL(real = r1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        r2 = intReal(i2);
        r1 = r1 * r2;
        v2 = multScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.INTEGER(integer = i1)),(Values.REAL(real = r2) :: rest))
      equation
        r1 = intReal(i1);
        r1 = r1 * r2;
        v2 = multScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.REAL(real = r1)),(Values.REAL(real = r2) :: rest))
      equation
        r1 = r1 * r2;
        v2 = multScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case (_,{}) then {};
  end match;
end multScalarArrayelt;

public function addScalarArrayelt "
  Adds a scalar to an list of Values, i.e. array.
"
  input Values.Value inValue;
  input list<Values.Value> inValueLst;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst:=
  match (inValue,inValueLst)
    local
      list<Values.Value> v1,v2,vals,rest;
      Values.Value sval;
      Integer i1,i2;
      Real r1,r2;
      String s1,s2;
      list<Integer> dims;
    case (sval,(Values.ARRAY(valueLst = vals, dimLst = dims) :: rest))
      equation
        v1 = addScalarArrayelt(sval, vals);
        v2 = addScalarArrayelt(sval, rest);
      then
        (Values.ARRAY(v1,dims) :: v2);
    case ((sval as Values.INTEGER(integer = i1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        i1 = i1+i2;
        v2 = addScalarArrayelt(sval, rest);
      then
        (Values.INTEGER(i1) :: v2);
    case ((sval as Values.REAL(real = r1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        r2 = intReal(i2);
        r1 = r1 + r2;
        v2 = addScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.INTEGER(integer = i1)),(Values.REAL(real = r2) :: rest))
      equation
        r1 = intReal(i1);
        r1 = r1 + r2;
        v2 = addScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.REAL(real = r1)),(Values.REAL(real = r2) :: rest))
      equation
        r1 = r1 + r2;
        v2 = addScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.STRING(string = s1)),(Values.STRING(string = s2) :: rest))
      equation
        s1 = s1+s2;
        v2 = addScalarArrayelt(sval, rest);
      then
        (Values.STRING(s1) :: v2);
    case (_,{}) then {};
  end match;
end addScalarArrayelt;

public function divScalarArrayelt "
  Divide a scalar with an list of Values, i.e. array.
"
  input Values.Value inValue;
  input list<Values.Value> inValueLst;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValue,inValueLst)
    local
      list<Values.Value> v1,v2,vals,rest;
      Values.Value sval;
      Integer i1,i2;
      Real r1,r2;
      String s2;
      list<Integer> dims;
    case (sval,(Values.ARRAY(valueLst = vals, dimLst = dims) :: rest))
      equation
        v1 = divScalarArrayelt(sval, vals);
        v2 = divScalarArrayelt(sval, rest);
      then
        (Values.ARRAY(v1,dims) :: v2);
    case (sval ,(Values.INTEGER(integer = i2) :: _))
      equation
        true = intEq(i2, 0);
        s2 = valString(sval);
        Error.addMessage(Error.DIVISION_BY_ZERO, {"0",s2});
      then
        fail();
    case (sval ,(Values.REAL(real = r2) :: _))
      equation
        true = realEq(r2, 0.0);
        s2 = valString(sval);
        Error.addMessage(Error.DIVISION_BY_ZERO, {"0.0",s2});
      then
        fail();
    case ((sval as Values.INTEGER(integer = i1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        r1 = intReal(i1);
        r2 = intReal(i2);
        r1 = r1 / r2;
        v2 = divScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.REAL(real = r1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        r2 = intReal(i2);
        r1 = r1 / r2;
        v2 = divScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.INTEGER(integer = i1)),(Values.REAL(real = r2) :: rest))
      equation
        r1 = intReal(i1);
        r1 = r1 / r2;
        v2 = divScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.REAL(real = r1)),(Values.REAL(real = r2) :: rest))
      equation
        r1 = r1 / r2;
        v2 = divScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case (_,{}) then {};
  end matchcontinue;
end divScalarArrayelt;

public function subScalarArrayelt "
  subtracts a list of Values, i.e. array, from a scalar.
"
  input Values.Value inValue;
  input list<Values.Value> inValueLst;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst:=
  match (inValue,inValueLst)
    local
      list<Values.Value> v1,v2,vals,rest;
      Values.Value sval;
      Integer i1,i2;
      Real r1,r2;
      list<Integer> dims;
    case (sval,(Values.ARRAY(valueLst = vals, dimLst = dims) :: rest))
      equation
        v1 = subScalarArrayelt(sval, vals);
        v2 = subScalarArrayelt(sval, rest);
      then
        (Values.ARRAY(v1,dims) :: v2);
    case ((sval as Values.INTEGER(integer = i1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        i1 = i1-i2;
        v2 = subScalarArrayelt(sval, rest);
      then
        (Values.INTEGER(i1) :: v2);
    case ((sval as Values.REAL(real = r1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        r2 = intReal(i2);
        r1 = r1 - r2;
        v2 = subScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.INTEGER(integer = i1)),(Values.REAL(real = r2) :: rest))
      equation
        r1 = intReal(i1);
        r1 = r1 - r2;
        v2 = subScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.REAL(real = r1)),(Values.REAL(real = r2) :: rest))
      equation
        r1 = r1 - r2;
        v2 = subScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case (_,{}) then {};
  end match;
end subScalarArrayelt;

public function powScalarArrayelt "
  Takes a power of a scalar with an list of Values, i.e. array.
"
  input Values.Value inValue;
  input list<Values.Value> inValueLst;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst:=
  match (inValue,inValueLst)
    local
      list<Values.Value> v1,v2,vals,rest;
      Values.Value sval;
      Integer i1,i2;
      Real r2,r1;
      list<Integer> dims;
    case (sval,(Values.ARRAY(valueLst = vals, dimLst = dims) :: rest))
      equation
        v1 = powScalarArrayelt(sval, vals);
        v2 = powScalarArrayelt(sval, rest);
      then
        (Values.ARRAY(v1,dims) :: v2);
    case ((sval as Values.INTEGER(integer = i1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        r1=intReal(i1);
        r2=intReal(i2);
        r1 = r1 ^ r2;
        v2 = powScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.REAL(real = r1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        r2 = intReal(i2);
        r1 = r1 ^ r2;
        v2 = powScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.INTEGER(integer = i1)),(Values.REAL(real = r2) :: rest))
      equation
        r1 = intReal(i1);
        r1 = r1 ^ r2;
        v2 = powScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.REAL(real = r1)),(Values.REAL(real = r2) :: rest))
      equation
        r1 = r1 ^ r2;
        v2 = powScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case (_,{}) then {};
  end match;
end powScalarArrayelt;

public function subArrayeltScalar "
  subtracts a scalar from a list of Values, i.e. array.
"
  input Values.Value inValue;
  input list<Values.Value> inValueLst;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst:=
  match (inValue,inValueLst)
    local
      list<Values.Value> v1,v2,vals,rest;
      Values.Value sval;
      Integer i1,i2;
      Real r1,r2;
      list<Integer> dims;
    case (sval,(Values.ARRAY(valueLst = vals, dimLst = dims) :: rest))
      equation
        v1 = subArrayeltScalar(sval, vals);
        v2 = subArrayeltScalar(sval, rest);
      then
        (Values.ARRAY(v1,dims) :: v2);
    case ((sval as Values.INTEGER(integer = i1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        i1 = i2-i1;
        v2 = subArrayeltScalar(sval, rest);
      then
        (Values.INTEGER(i1) :: v2);
    case ((sval as Values.REAL(real = r1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        r2 = intReal(i2);
        r1 = r2 - r1;
        v2 = subArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.INTEGER(integer = i1)),(Values.REAL(real = r2) :: rest))
      equation
        r1 = intReal(i1);
        r1 = r2 - r1;
        v2 = subArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.REAL(real = r1)),(Values.REAL(real = r2) :: rest))
      equation
        r1 = r2 - r1;
        v2 = subArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case (_,{}) then {};
  end match;
end subArrayeltScalar;

public function powArrayeltScalar "
  Takes a power of a list of Values, i.e. array, with a scalar.
"
  input Values.Value inValue;
  input list<Values.Value> inValueLst;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst:=
  match (inValue,inValueLst)
    local
      list<Values.Value> v1,v2,vals,rest;
      Values.Value sval;
      Integer i1,i2;
      Real r1,r2;
      list<Integer> dims;
    case (sval,(Values.ARRAY(valueLst = vals, dimLst = dims) :: rest))
      equation
        v1 = powArrayeltScalar(sval, vals);
        v2 = powArrayeltScalar(sval, rest);
      then
        (Values.ARRAY(v1,dims) :: v2);
    case ((sval as Values.INTEGER(integer = i1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        r1=intReal(i1);
        r2=intReal(i2);
        r1 = r2 ^ r1;
        v2 = powArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.REAL(real = r1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        r2 = intReal(i2);
        r1 = r2 ^ r1;
        v2 = powArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.INTEGER(integer = i1)),(Values.REAL(real = r2) :: rest))
      equation
        r1 = intReal(i1);
        r1 = r2 ^ r1;
        v2 = powArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case ((sval as Values.REAL(real = r1)),(Values.REAL(real = r2) :: rest))
      equation
        r1 = r2 ^ r1;
        v2 = powArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: v2);
    case (_,{}) then {};
  end match;
end powArrayeltScalar;

public function multScalarProduct "
  Calculate the scalar product of two vectors / arrays.
"
  input list<Values.Value> inValueLst1;
  input list<Values.Value> inValueLst2;
  output Values.Value outValue;
algorithm
  outValue:=
  matchcontinue (inValueLst1,inValueLst2)
    local
      Integer i1,i2,res,v1,v2,dim;
      list<Values.Value> v1lst,v2lst,vres,rest,vlst,col,mat_1,vals,mat,lst1,lst2;
      Values.Value sres,v;
      list<Integer> dims;
      Real r1,r2,rres;
    case ((Values.INTEGER(integer = i1) :: (v1lst as (_ :: _))),(Values.INTEGER(integer = i2) :: (v2lst as (_ :: _))))
      equation
        i1 = i1*i2;
        Values.INTEGER(i2) = multScalarProduct(v1lst, v2lst);
        res = i1 + i2;
      then
        Values.INTEGER(res);
    case ({Values.INTEGER(integer = v1)},{Values.INTEGER(integer = v2)})
      equation
        res = v1*v2;
      then
        Values.INTEGER(res);
    case ((Values.REAL(real = r1) :: (v1lst as (_ :: _))),(Values.REAL(real = r2) :: (v2lst as (_ :: _))))
      equation
        r1 = r1 * r2;
        Values.REAL(r2) = multScalarProduct(v1lst, v2lst);
        rres = r1 + r2;
      then
        Values.REAL(rres);
    case ({Values.REAL(real = r1)},{Values.REAL(real = r2)})
      equation
        rres = r1 * r2;
      then
        Values.REAL(rres);
    case ((Values.ARRAY(valueLst = v2lst) :: rest),(vlst as (Values.INTEGER() :: _)))
      equation
        sres = multScalarProduct(v2lst, vlst);
        Values.ARRAY(vres,dim::dims) = multScalarProduct(rest, vlst);
        dim = dim+1;
      then
        Values.ARRAY(sres :: vres, dim::dims);
    case ({},(Values.INTEGER() :: _)) then makeArray({});
    case ((Values.ARRAY(valueLst = v2lst) :: rest),(vlst as (Values.REAL() :: _)))
      equation
        sres = multScalarProduct(v2lst, vlst);
        Values.ARRAY(vres,dim::dims) = multScalarProduct(rest, vlst);
        dim = dim+1;
      then
        Values.ARRAY(sres :: vres,dim::dims);
    case ({},(Values.REAL() :: _)) then makeArray({});
    case ((vlst as (Values.INTEGER() :: _)),(mat as (Values.ARRAY(valueLst = (_ :: (_ :: _))) :: _)))
      equation
        (Values.ARRAY(valueLst = col),mat_1) = matrixStripFirstColumn(mat);
        v = multScalarProduct(vlst, col);
        Values.ARRAY(vals,dim::dims) = multScalarProduct(vlst, mat_1);
      then
        Values.ARRAY(v :: vals, dim::dims);
    case ((vlst as (Values.INTEGER() :: _)),(mat as (Values.ARRAY(valueLst = {_}) :: _)))
      equation
        (Values.ARRAY(valueLst = col),_) = matrixStripFirstColumn(mat);
        Values.INTEGER(i1) = multScalarProduct(vlst, col);
      then
        makeArray({Values.INTEGER(i1)});
    case ((vlst as (Values.REAL() :: _)),(mat as (Values.ARRAY(valueLst = (_ :: (_ :: _))) :: _)))
      equation
        (Values.ARRAY(valueLst = col),mat_1) = matrixStripFirstColumn(mat);
        v = multScalarProduct(vlst, col);
        Values.ARRAY(valueLst = vals, dimLst = dim::dims) = multScalarProduct(vlst, mat_1);
        dim = dim+1;
      then
        Values.ARRAY(v :: vals, dim::dims);
    case ((vlst as (Values.REAL() :: _)),(mat as (Values.ARRAY(valueLst = {_}) :: _)))
      equation
        (Values.ARRAY(valueLst = col),_) = matrixStripFirstColumn(mat);
        Values.REAL(r1) = multScalarProduct(vlst, col);
      then
        makeArray({Values.REAL(r1)});
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("Values.multScalarProduct failed\n");
      then
        fail();
  end matchcontinue;
end multScalarProduct;

public function crossProduct "
  Calculate the cross product of two vectors.
  x,y => {x[2]*y[3]-x[3]*y[2],x[3]*y[1]-x[1]*y[3],x[1]*y[2]-x[2]*y[1]}
"
  input list<Values.Value> inValueLst1;
  input list<Values.Value> inValueLst2;
  output Values.Value outValue;
algorithm
  outValue := match(inValueLst1,inValueLst2)
    local
      Integer ix1,ix2,ix3,iy1,iy2,iy3,iz1,iz2,iz3;
      Real x1,x2,x3,y1,y2,y3,z1,z2,z3;
    case ({Values.REAL(x1),Values.REAL(x2),Values.REAL(x3)},
          {Values.REAL(y1),Values.REAL(y2),Values.REAL(y3)})
      equation
        z1 = realSub(realMul(x2,y3),realMul(x3,y2));
        z2 = realSub(realMul(x3,y1),realMul(x1,y3));
        z3 = realSub(realMul(x1,y2),realMul(x2,y1));
      then
        makeArray({Values.REAL(z1),Values.REAL(z2),Values.REAL(z3)});
    case ({Values.INTEGER(ix1),Values.INTEGER(ix2),Values.INTEGER(ix3)},
          {Values.INTEGER(iy1),Values.INTEGER(iy2),Values.INTEGER(iy3)})
      equation
        iz1 = intSub(intMul(ix2,iy3),intMul(ix3,iy2));
        iz2 = intSub(intMul(ix3,iy1),intMul(ix1,iy3));
        iz3 = intSub(intMul(ix1,iy2),intMul(ix2,iy1));
      then
        makeArray({Values.INTEGER(iz1),Values.INTEGER(iz2),Values.INTEGER(iz3)});
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"ValuesUtil.crossProduct failed"});
      then
        fail();
  end match;
end crossProduct;

public function multMatrix "
  Calculate a matrix multiplication of two matrices, i.e. two dimensional
  arrays.
"
  input list<Values.Value> inValueLst1;
  input list<Values.Value> inValueLst2;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst:=
  match (inValueLst1,inValueLst2)
    local
      Values.Value res1;
      list<Values.Value> res2,m1,v1lst,rest1,m2;
    case (((Values.ARRAY(valueLst = v1lst) :: rest1)),(m2 as (Values.ARRAY() :: _)))
      equation
        res1 = multScalarProduct(v1lst, m2);
        res2 = multMatrix(rest1, m2);
      then
        (res1 :: res2);
    case ({},_) then {};
  end match;
end multMatrix;

public function divArrayeltScalar
"Divide each array element with a scalar."
  input Values.Value inValue;
  input list<Values.Value> inValueLst;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValue,inValueLst)
    local
      String s2;
      Values.Value sval;
      Integer i1,i2;
      Real v1,v2_1,v1_1,v2;
      list<Values.Value> vlst,r1,r2,vals,rest;
      list<Integer> dims;
    case ((Values.REAL(real = v1)),vlst)
      equation
        true = realEq(v1, 0.0);
        s2 = unparseValues(vlst);
        Error.addMessage(Error.DIVISION_BY_ZERO, {"0.0",s2});
      then
        fail();
    case ((Values.INTEGER(integer = i1)),vlst)
      equation
        true = intEq(i1, 0);
        s2 = unparseValues(vlst);
        Error.addMessage(Error.DIVISION_BY_ZERO, {"0",s2});
      then
        fail();
    case (sval,(Values.ARRAY(valueLst = vals, dimLst = dims) :: rest))
      equation
        r1 = divArrayeltScalar(sval, vals);
        r2 = divArrayeltScalar(sval, rest);
      then
        (Values.ARRAY(r1,dims) :: r2);
    case ((sval as Values.INTEGER(integer = i1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        i1 = intDiv(i2,i1);
        r2 = divArrayeltScalar(sval, rest);
      then
        (Values.INTEGER(i1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.INTEGER(integer = i2) :: rest))
      equation
        v2_1 = intReal(i2);
        v1 = v2_1 / v1;
        r2 = divArrayeltScalar(sval, rest);
      then
        (Values.REAL(v1) :: r2);
    case ((sval as Values.INTEGER(integer = i1)),(Values.REAL(real = v2) :: rest))
      equation
        v1_1 = intReal(i1);
        v1 = v2 / v1_1;
        r2 = divArrayeltScalar(sval, rest);
      then
        (Values.REAL(v1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.REAL(real = v2) :: rest))
      equation
        v1 = v2 / v1;
        r2 = divArrayeltScalar(sval, rest);
      then
        (Values.REAL(v1) :: r2);
    case (_,{}) then {};
  end matchcontinue;
end divArrayeltScalar;

protected function matrixStripFirstColumn "This function takes a Value list representing a matrix and strips the
  first column of the matrix, i.e. for each sub list it removes the first
  element. Returning both the stripped column and the resulting matrix."
  input list<Values.Value> inValueLst;
  output Values.Value outValue;
  output list<Values.Value> outValueLst;
algorithm
  (outValue,outValueLst) := match (inValueLst)
    local
      list<Values.Value> resl,resl2,vrest,rest;
      Values.Value v1;
      Integer i;
      Integer dim;
    case ((Values.ARRAY(valueLst = (v1 :: vrest), dimLst = {dim}) :: rest))
      equation
        (Values.ARRAY(resl,{i}),resl2) = matrixStripFirstColumn(rest);
        i = i+1;
        dim = dim - 1;
      then
        (Values.ARRAY((v1 :: resl),{i}),(Values.ARRAY(vrest,{dim}) :: resl2));

    case ({}) then (Values.ARRAY({},{0}),{});
  end match;
end matrixStripFirstColumn;

public function intlistToValue "
  Takes a list of integers and builds a Value from it, i.e. an
  array of integers.
"
  input list<Integer> inIntegerLst;
  output Values.Value outValue;
algorithm
  outValue:=
  match (inIntegerLst)
    local
      list<Values.Value> res;
      Integer i,len;
      list<Integer> lst;
    case ({}) then Values.ARRAY({},{0});
    case ((i :: lst))
      equation
        Values.ARRAY(res,{len}) = intlistToValue(lst);
        len = len+1;
      then
        Values.ARRAY((Values.INTEGER(i) :: res),{len});
  end match;
end intlistToValue;

public function arrayValues "
  Return the values of an array.
"
  input Values.Value inValue;
  output list<Values.Value> outValueLst;
algorithm
  outValueLst:=
  match (inValue)
    local list<Values.Value> v_lst;
    case (Values.ARRAY(valueLst = v_lst)) then v_lst;
  end match;
end arrayValues;

public function arrayScalar
  "If an array contains only one value, returns that value. Otherwise fails."
  input Values.Value inValue;
  output Values.Value outValue;
algorithm
  Values.ARRAY(valueLst = {outValue}) := inValue;
end arrayScalar;

public function makeBoolean
  input Boolean b;
  output Values.Value v;
algorithm
  v := Values.BOOL(b);
end makeBoolean;

public function makeReal "Creates a real value "
  input Real r;
  output Values.Value v;
algorithm
  v := Values.REAL(r);
end makeReal;

public function makeInteger "Creates an integer value "
  input Integer i;
  output Values.Value v;
algorithm
  v := Values.INTEGER(i);
end makeInteger;

public function makeString "Creates a string value "
  input String s;
  output Values.Value v;
algorithm
  v := Values.STRING(s);
end makeString;

public function makeTuple "Construct a tuple of a list of Values."
  input list<Values.Value> inValueLst;
  output Values.Value outValue;
algorithm
  outValue := Values.TUPLE(inValueLst);
end makeTuple;

public function makeList "Construct a list from a list of Values."
  input list<Values.Value> inValueLst;
  output Values.Value outValue;
algorithm
  outValue := Values.LIST(inValueLst);
end makeList;

public function makeArray "
  Construct an array of a list of Values.
"
  input list<Values.Value> inValueLst;
  output Values.Value outValue;
algorithm
  outValue:=
  matchcontinue (inValueLst)
    local
      Integer i1;
      list<Integer> il;
      list<Values.Value> vlst;
    case (vlst as (Values.ARRAY(dimLst = il)::_))
      equation
        i1 = listLength(vlst);
      then Values.ARRAY(vlst,i1::il);
    case (vlst)
      equation
        i1 = listLength(vlst);
      then Values.ARRAY(vlst,{i1});
  end matchcontinue;
end makeArray;

public function makeIntArray
  "Creates a Value.ARRAY from a list of integers."
  input list<Integer> inInts;
  output Values.Value outArray;
algorithm
  outArray := makeArray(List.map(inInts, makeInteger));
end makeIntArray;

public function makeRealArray
  "Creates a Values.ARRAY from a list of reals."
  input list<Real> inReals;
  output Values.Value outArray;
algorithm
  outArray := makeArray(List.map(inReals, makeReal));
end makeRealArray;

public function makeRealMatrix
  "Creates a matrix (ARRAY of ARRAY) from a list of list of reals."
  input list<list<Real>> inReals;
  output Values.Value outArray;
algorithm
  outArray := makeArray(List.map(inReals, makeRealArray));
end makeRealMatrix;

public function valString "This function returns a textual representation of a value."
  input Values.Value inValue;
  output String outString;
protected
  Integer handle;
algorithm
  handle := Print.saveAndClearBuf();
  valString2(inValue);
  outString := Print.getString();
  Print.restoreBuf(handle);
end valString;

public function valString2 "This function returns a textual representation of a value.
  Uses an external buffer to store intermediate results."
  input Values.Value inValue;
algorithm
  _ := matchcontinue (inValue)
    local
      String s, s_1, recordName, tyStr, scope, name;
      Integer n;
      Real x;
      list<Values.Value> xs,vs;
      Values.Value r;
      Absyn.CodeNode c;
      Absyn.Path p, recordPath;
      list<String> ids;
      Absyn.ComponentRef cr;
      Absyn.Path path;

    case Values.INTEGER(integer = n)
      equation
        s = intString(n);
        Print.printBuf(s);
      then
        ();
    case Values.REAL(real = x)
      equation
        s = realString(x);
        Print.printBuf(s);
      then
        ();
    case Values.STRING(string = s)
      equation
        s = System.escapedString(s,false);
        s_1 = stringAppendList({"\"",s,"\""});
        Print.printBuf(s_1);
      then
        ();
    case Values.BOOL(boolean = false)
      equation
        Print.printBuf("false");
      then
        ();
    case Values.BOOL(boolean = true)
      equation
        Print.printBuf("true");
      then
        ();
    case Values.ENUM_LITERAL(name = p)
      equation
        s = Absyn.pathString(p);
        Print.printBuf(s);
      then
        ();
    case Values.ARRAY(valueLst = vs)
      equation
        Print.printBuf("{");
        valListString(vs);
        Print.printBuf("}");
      then
        ();
    case Values.TUPLE(valueLst = {})
      then ();
    case Values.TUPLE(valueLst = vs)
      equation
        Print.printBuf("(");
        valListString(vs);
        Print.printBuf(")");
      then
        ();
    case Values.META_TUPLE(valueLst = {})
      then ();
    case Values.META_TUPLE(valueLst = vs)
      equation
        Print.printBuf("(");
        valListString(vs);
        Print.printBuf(")");
      then
        ();

    case ((Values.RECORD(record_ = Absyn.IDENT("SimulationResult"), orderd = xs, comp = ids)))
      equation
        Print.printBuf("record SimulationResult\n");
        (xs,ids) = filterSimulationResults(Flags.isSet(Flags.SHORT_OUTPUT),xs,ids,{},{});
        valRecordString(xs,ids);
        Print.printBuf("end SimulationResult;");
      then
        ();

    case ((Values.RECORD(record_ = recordPath, orderd = xs, comp = ids)))
      equation
        recordName = Absyn.pathStringNoQual(recordPath);

        Print.printBuf("record " + recordName + "\n");
        valRecordString(xs,ids);
        Print.printBuf("end " + recordName + ";");
      then
        ();

    case ((Values.OPTION(SOME(r))))
      equation
        Print.printBuf("SOME(");
        valString2(r);
        Print.printBuf(")");
      then
        ();
    case ((Values.OPTION(NONE())))
      equation
        Print.printBuf("NONE()");
      then
        ();

    case ((Values.META_BOX(r)))
      equation
        Print.printBuf("#(");
        valString2(r);
        Print.printBuf(")");
      then
        ();

    case (Values.CODE(A = Absyn.C_TYPENAME(path)))
      equation
        Print.printBuf(Absyn.pathString(path));
      then
        ();

    case (Values.CODE(A = Absyn.C_VARIABLENAME(cr)))
      equation
        Print.printBuf(Absyn.printComponentRefStr(cr));
      then
        ();

    case (Values.CODE(A = c))
      equation
        Print.printBuf("Code(");
        Print.printBuf(Dump.printCodeStr(c));
        Print.printBuf(")");
      then
        ();

    // MetaModelica list
    case Values.LIST(valueLst = vs)
      equation
        Print.printBuf("{");
        valListString(vs);
        Print.printBuf("}");
      then
        ();

    // MetaModelica array
    case Values.META_ARRAY(valueLst = vs)
      equation
        Print.printBuf("meta_array(");
        valListString(vs);
        Print.printBuf(")");
      then
        ();

    /* Until is it no able to get from an string Enumeration the C-Enumeration use the index value */
    /* Example: This is yet not possible Enum.e1 \\ PEnum   ->  1 \\ PEnum  with enum Enum(e1,e2), Enum PEnum; */
    case (Values.ENUM_LITERAL(index = n, name=p))
      equation
        s = intString(n) + " /* ENUM: " + Absyn.pathString(p) + " */";
        Print.printBuf(s);
      then
        ();

    case (Values.NORETCALL())
      then ();

    case (Values.META_FAIL())
      equation
        Print.printBuf("fail()");
      then ();

    case (Values.EMPTY(scope = scope, name = name, tyStr = tyStr))
      equation
        Print.printBuf("/* <EMPTY(scope: " + scope + ", name: " + name + ", ty: " + tyStr + ")> */");
      then ();

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"ValuesUtil.valString2 failed"});
      then
        fail();
  end matchcontinue;
end valString2;

protected function filterSimulationResults
  input Boolean filter;
  input list<Values.Value> inValues;
  input list<String> inIds;
  input list<Values.Value> valacc;
  input list<String> idacc;
  output list<Values.Value> outValues;
  output list<String> outIds;
algorithm
  (outValues,outIds) := match (filter,inValues,inIds,valacc,idacc)
    local
      Values.Value v;
      list<Values.Value> vrest;
      String id,str;
      list<String> idrest;
    case (_,{},{},_,_) then (listReverse(valacc),listReverse(idacc));
    case (true,v::vrest,(id as "messages")::idrest,_,_)
      equation
        (outValues,outIds) = filterSimulationResults(filter,vrest,idrest,v::valacc,id::idacc);
      then (outValues,outIds);
    case (true,Values.STRING(str)::vrest,(id as "resultFile")::idrest,_,_)
      equation
        str = System.basename(str);
        (outValues,outIds) = filterSimulationResults(filter,vrest,idrest,Values.STRING(str)::valacc,id::idacc);
      then (outValues,outIds);
    case (true,_::vrest,_::idrest,_,_)
      equation
        (outValues,outIds) = filterSimulationResults(filter,vrest,idrest,valacc,idacc);
      then (outValues,outIds);
    case (false,_,_,_,_) then (inValues,inIds);
  end match;
end filterSimulationResults;

protected function valRecordString
"This function returns a textual representation of a record,
 separating each value with a comma."
  input list<Values.Value> inValues;
  input list<String> inIds;
algorithm
  _ := matchcontinue (inValues,inIds)
    local
      String id;
      Values.Value x;
      list<Values.Value> xs;
      list<String> ids;

    case ({},{}) then ();

    case (x :: (xs as (_ :: _)),id :: (ids as (_ :: _)))
      equation
        Print.printBuf("    ");
        Print.printBuf(id);
        Print.printBuf(" = ");
        valString2(x);
        Print.printBuf(",\n");
        valRecordString(xs,ids);
      then
        ();

    case (x :: {},id :: {})
      equation
        Print.printBuf("    ");
        Print.printBuf(id);
        Print.printBuf(" = ");
        valString2(x);
        Print.printBuf("\n");
      then
        ();

    case (xs,ids)
      equation
        print("ValuesUtil.valRecordString failed:\nids: "+ stringDelimitList(ids, ", ") +
        "\nvals: " + stringDelimitList(List.map(xs, valString), ", ") + "\n");
      then
        fail();

  end matchcontinue;
end valRecordString;

protected function valListString "
  This function returns a textual representation of a list of
  values, separating each value with a comman.
"
  input list<Values.Value> inValueLst;
algorithm
  _ := match (inValueLst)
    local
      Values.Value v;
      list<Values.Value> vs;
    case {} then ();
    case {v}
      equation
        valString2(v);
      then
        ();
    case (v :: vs)
      equation
        valString2(v);
        Print.printBuf(",");
        valListString(vs);
      then
        ();
  end match;
end valListString;

public function writePtolemyplotDataset "
  This function writes a data set in the pltolemy plot format to a file.
  The first column of the dataset matrix should be the time variable.
  The message string will be displayed in the plot window of ptplot.
"
  input String inString1;
  input Values.Value inValue2;
  input list<String> inStringLst3;
  input String inString4;
  output Integer outInteger;
algorithm
  outInteger:=
  match (inString1,inValue2,inStringLst3,inString4)
    local
      String str,filename,timevar,message;
      Values.Value t;
      list<Values.Value> rest;
      list<String> varnames;
      Integer handle;

    case (filename,Values.ARRAY(valueLst = (t :: rest)),(_ :: varnames),message) /* filename values Variable names message string */
      equation
        handle = Print.saveAndClearBuf();

        Print.printBuf("#Ptolemy Plot generated by OpenModelica\nTitleText: ");
        Print.printBuf(message);
        Print.printBuf("\n");
        unparsePtolemyValues(t, rest, varnames);

        str = Print.getString();
        Print.restoreBuf(handle);

        System.writeFile(filename, str);
      then
        0;
  end match;
end writePtolemyplotDataset;

protected function unparsePtolemyValues "Helper function to writePtolemyplotDataset."
  input Values.Value inValue;
  input list<Values.Value> inValueLst;
  input list<String> inStringLst;
algorithm
  _ := match (inValue,inValueLst,inStringLst)
    local
      String v1;
      Values.Value t,s1;
      list<Values.Value> xs;
      list<String> vs;

    case (_,{},_) then ();
    case (t,(s1 :: xs),(v1 :: vs))
      equation
        unparsePtolemySet(t, s1, v1);
        unparsePtolemyValues(t, xs, vs);
      then
        ();
  end match;
end unparsePtolemyValues;

protected function unparsePtolemySet "Helper function to unparsePtolemyValues."
  input Values.Value v1;
  input Values.Value v2;
  input String varname;
algorithm
  Print.printBuf(stringAppendList({"DataSet: ",varname,"\n"}));
  unparsePtolemySet2(v1, v2);
end unparsePtolemySet;

protected function unparsePtolemySet2 "Helper function to unparsePtolemySet"
  input Values.Value inValue1;
  input Values.Value inValue2;
algorithm
  _ := matchcontinue (inValue1,inValue2)
    local
      Values.Value v1,v2;
      list<Values.Value> v1s,v2s;

    case (Values.ARRAY(valueLst = {}),Values.ARRAY(valueLst = {})) then ();
    // adrpo: ignore dimenstions here as we're just printing! otherwise it fails.
    //        TODO! FIXME! see why the dimension list is wrong!
    case (Values.ARRAY(valueLst = (v1 :: v1s)),Values.ARRAY(valueLst = (v2 :: v2s)))
      equation
        valString2(v1);
        Print.printBuf(",");
        valString2(v2);
        Print.printBuf("\n");
        unparsePtolemySet2(Values.ARRAY(v1s,{}), Values.ARRAY(v2s,{}));
      then
        ();
    case (v1, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- ValuesUtil.unparsePtolemySet2 failed on v1: " +
          printValStr(v1) + " and v2: " + printValStr(v1));
      then
        fail();
  end matchcontinue;
end unparsePtolemySet2;

public function reverseMatrix "Reverses each line and each row of a matrix.
  Implementation reverses all dimensions..."
  input Values.Value inValue;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue (inValue)
    local
      list<Values.Value> lst_1,lst_2,lst;
      Values.Value value;
      list<Integer> dims;
    case (Values.ARRAY(valueLst = lst, dimLst = dims))
      equation
        lst_1 = List.map(lst, reverseMatrix);
        lst_2 = listReverse(lst_1);
      then
        Values.ARRAY(lst_2,dims);
    case (value) then value;
  end matchcontinue;
end reverseMatrix;

public function printVal "This function prints a value."
  input Values.Value v;
protected
  String s;
algorithm
  s := valString(v);
  Print.printBuf(s);
end printVal;

public function printValStr "
more correct naming then valString"
  input Values.Value v;
  output String s;
algorithm
  s := valString(v);
end printValStr;

public function nthnthArrayelt "author: BZ

  Return the nth nth....nth value of an array, indexed from 1..n
"
  input list<Values.Value> inLst;
  input Values.Value inValue;
  input Values.Value lastValue;
  output Values.Value outValue;
algorithm
  outValue:=
  match (inLst, inValue,lastValue)
    local
      Integer n;
      Values.Value res,preRes;
      list<Values.Value> vlst,vlst2;

    case({},_, preRes) then preRes;
    case (((Values.INTEGER(integer=n))::vlst2),Values.ARRAY(valueLst = vlst),_)
      equation
        res = listGet(vlst, n);
        res = nthnthArrayelt(vlst2,res,res);
      then res;
  end match;
end nthnthArrayelt;

public function valueInteger
  "Converts a value to an Integer, or fails if that is not possible."
  input Values.Value inValue;
  output Integer outInteger;
algorithm
  outInteger := match(inValue)
    local
      Integer i;
    case Values.INTEGER(integer = i) then i;
    case Values.ENUM_LITERAL(index = i) then i;
    case Values.BOOL(boolean = true) then 1;
    case Values.BOOL(boolean = false) then 0;
  end match;
end valueInteger;

public function valueDimensions
  "Returns the dimensions of a value."
  input Values.Value inValue;
  output list<Integer> outDimensions;
algorithm
  outDimensions := match(inValue)
    local
      list<Integer> dims;
    case Values.ARRAY(dimLst = dims) then dims;
    else {};
  end match;
end valueDimensions;

public function extractValueString
  input Values.Value val;
  output String str;
algorithm
  Values.STRING(str) := val;
end extractValueString;

public function makeCodeTypeName
  input Absyn.Path path;
  output Values.Value val;
algorithm
  val := Values.CODE(Absyn.C_TYPENAME(path));
end makeCodeTypeName;

public function getCode
  input Values.Value val;
  output Absyn.CodeNode code;
algorithm
  Values.CODE(code) := val;
end getCode;

public function getPath
  input Values.Value val;
  output Absyn.Path path;
protected
  Absyn.CodeNode code;
algorithm
  Values.CODE(code) := val;
  Absyn.C_TYPENAME(path) := code;
end getPath;

public function printCodeVariableName
  input Values.Value val;
  output String str;
algorithm
  str := match val
    local
      Absyn.ComponentRef cr;
      Absyn.Exp exp;
      // der(x)
    case Values.CODE(Absyn.C_EXPRESSION(exp)) then Dump.printExpStr(exp);
      // x
    case Values.CODE(Absyn.C_VARIABLENAME(cr))
      then Dump.printComponentRefStr(cr);
  end match;
end printCodeVariableName;

public function boxIfUnboxedVal
  input Values.Value v;
  output Values.Value ov;
algorithm
  ov := match v
    case Values.INTEGER(_) then Values.META_BOX(v);
    case Values.REAL(_) then Values.META_BOX(v);
    case Values.BOOL(_) then Values.META_BOX(v);
    else v;
  end match;
end boxIfUnboxedVal;

public function unboxIfBoxedVal
  input Values.Value iv;
  output Values.Value ov;
algorithm
  ov := match iv local Values.Value v;
    case Values.META_BOX(v) then v;
    else iv;
  end match;
end unboxIfBoxedVal;

public function arrayOrListVals
  input Values.Value v;
  input Boolean boxIfUnboxed;
  output list<Values.Value> vals;
algorithm
  vals := match (v,boxIfUnboxed)
    case (Values.ARRAY(valueLst = vals),_) then vals;
    case (Values.LIST(vals),true) then List.map(vals,boxIfUnboxedVal);
    case (Values.LIST(vals),_) then vals;
  end match;
end arrayOrListVals;

public function containsEmpty
  input Values.Value inValue;
  output Option<Values.Value> outEmptyVal;
algorithm
  outEmptyVal := match inValue
    case Values.EMPTY() then SOME(inValue);
    case Values.ARRAY() then arrayContainsEmpty(inValue.valueLst);
    case Values.RECORD() then arrayContainsEmpty(inValue.orderd);
    case Values.TUPLE() then arrayContainsEmpty(inValue.valueLst);
    else NONE();
  end match;
end containsEmpty;

public function arrayContainsEmpty
  "Searches for an EMPTY value in a list, and returns SOME(value) if found,
   otherwise NONE()."
  input list<Values.Value> inValues;
  output Option<Values.Value> outOptValue = NONE();
algorithm
  for val in inValues loop
    outOptValue := containsEmpty(val);

    if isSome(outOptValue) then
      break;
    end if;
  end for;
end arrayContainsEmpty;

public function liftValueList
  input Values.Value inValue;
  input list<DAE.Dimension> inDimensions;
  output Values.Value outValue = inValue;
algorithm
  for dim in listReverse(inDimensions) loop
    outValue := makeArray(List.fill(outValue, Expression.dimensionSize(dim)));
  end for;
end liftValueList;

public function isEmpty
  input Values.Value inValue;
  output Boolean outIsEmpty;
algorithm
  outIsEmpty := match inValue
    case Values.EMPTY() then true;
    else false;
  end match;
end isEmpty;

public function typeConvertRecord
  "Converts the component values of a record to the correct types."
  input Values.Value inValue;
  input DAE.Type inType;
  output Values.Value outValue = inValue;
algorithm
  outValue := match (outValue, inType)
    local
      DAE.Type ty;

    case (Values.RECORD(), DAE.T_COMPLEX())
      algorithm
        outValue.orderd := list(typeConvertRecord(val, Types.getVarType(var))
          threaded for val in outValue.orderd, var in inType.varLst);
      then
        outValue;

    case (Values.INTEGER(), DAE.T_REAL())
      then Values.REAL(intReal(outValue.integer));

    case (Values.ARRAY(), DAE.T_ARRAY())
      algorithm
        ty := Expression.unliftArray(inType);
        outValue.valueLst := list(typeConvertRecord(v, ty) for v in outValue.valueLst);
      then
        outValue;

    else outValue;
  end match;
end typeConvertRecord;

annotation(__OpenModelica_Interface="frontend");
end ValuesUtil;
