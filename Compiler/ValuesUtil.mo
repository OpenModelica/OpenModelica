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

package ValuesUtil
" file:        ValuesUtil.mo
  package:     ValuesUtil
  description: Evaluated expression values

  RCS: $Id$

  The package Values contains utility functions for handling evaluated
  expression values."

public import DAE;
public import Values;

public type Value = Values.Value;
public type IntRealOp = Values.IntRealOp;

protected import Absyn;
protected import Debug;
protected import Dump;
protected import Error;
protected import Exp;
protected import Print;
protected import System;
protected import Util;
protected import RTOpts;
protected import ClassInf;

public function typeConvert "function: typeConvert
  Apply type conversion on a list of Values"
  input DAE.ExpType inType1;
  input DAE.ExpType inType2;
  input list<Value> inValueLst3;
  output list<Value> outValueLst;
algorithm
  outValueLst := matchcontinue (inType1,inType2,inValueLst3)
    local
      list<Value> vallst,vrest,vallst2,vals;
      Real rval,r;
      DAE.ExpType from,to;
      Integer i,ival;
      list<Integer> dims;
    case (_,_,{}) then {};
    case ((from as DAE.ET_INT()),(to as DAE.ET_REAL()),(Values.INTEGER(integer = i) :: vrest))
      equation
        vallst = typeConvert(from, to, vrest);
        rval = intReal(i);
      then
        (Values.REAL(rval) :: vallst);
    case ((from as DAE.ET_REAL()),(to as DAE.ET_INT()),(Values.REAL(real = r) :: vrest))
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
  end matchcontinue;
end typeConvert;

public function valueExpType "creates a DAE.ExpType from a Value"
  input Value inValue;
  output DAE.ExpType tp;
algorithm
  tp := matchcontinue(inValue)
  local Absyn.Path path; Integer indx; list<String> nameLst; DAE.ExpType eltTp;
    list<Option<Integer>> dimsOpt;
    list<Values.Value> valLst;
    list<DAE.ExpType> eltTps;
    list<DAE.ExpVar> varLst;
    list<Integer> dims;
    
    case(Values.INTEGER(_)) then DAE.ET_INT();
    case(Values.REAL(_)) then DAE.ET_REAL();
    case(Values.BOOL(_)) then DAE.ET_BOOL();
    case(Values.STRING(_)) then DAE.ET_STRING();
    case(Values.ENUM(indx,path,nameLst)) then DAE.ET_ENUMERATION(SOME(indx),path,nameLst,{});
    case(Values.ARRAY(valLst,dims)) equation
      eltTp=valueExpType(Util.listFirst(valLst));
      dimsOpt = Util.listMap(dims,Util.makeOption);
    then DAE.ET_ARRAY(eltTp,dimsOpt);
    
    case(Values.RECORD(path,valLst,nameLst,indx)) equation
      eltTps = Util.listMap(valLst,valueExpType);
      varLst = Util.listThreadMap(eltTps,nameLst,valueExpTypeExpVar);
    then DAE.ET_COMPLEX(path,varLst,ClassInf.RECORD(path));
    
    case(inValue)
      equation
        print("valueExpType on "+&valString(inValue) +& " not implemented yet\n");
      then fail();
  end matchcontinue;  
end valueExpType;

protected function valueExpTypeExpVar "help function to valueExpType"
  input DAE.ExpType etp;
  input String name;
  output DAE.ExpVar expVar;
algorithm
  expVar := DAE.COMPLEX_VAR(name,etp);
end valueExpTypeExpVar;
   
public function isZero "Returns true if value is zero"
  input Value inValue;
  output Boolean isZero;
algorithm
  isZero := matchcontinue(inValue)
  local Real rval; Integer ival;
    case(Values.REAL(rval)) equation
      isZero = rval ==. 0.0;
      then isZero;
    case(Values.INTEGER(ival)) equation
      isZero = ival == 0;
      then isZero;
    case(_) then false;
  end matchcontinue;
end isZero;


public function isArray "function: isArray
  Return true if Value is an array."
  input Value inValue;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inValue)
    case (Values.INTEGER(integer = _)) then false;
    case (Values.REAL(real = _)) then false;
    case (Values.STRING(string = _)) then false;
    case (Values.BOOL(boolean = _)) then false;
    case (Values.TUPLE(valueLst = _)) then false;
    case (Values.META_TUPLE(valueLst = _)) then false;
    case (Values.RECORD(orderd = _)) then false;
    case (Values.ARRAY(valueLst = _)) then true;
    case (Values.LIST(_)) then false; //MetaModelica list
  end matchcontinue;
end isArray;

public function isRecord "function: isArray
  Return true if Value is an array."
  input Value inValue;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inValue)
    case (Values.INTEGER(integer = _)) then false;
    case (Values.REAL(real = _)) then false;
    case (Values.STRING(string = _)) then false;
    case (Values.BOOL(boolean = _)) then false;
    case (Values.TUPLE(valueLst = _)) then false;
    case (Values.META_TUPLE(valueLst = _)) then false;
    case (Values.ARRAY(valueLst = _)) then false;
    case (Values.LIST(_)) then false; //MetaModelica list
    case (Values.RECORD(orderd = _)) then true;
  end matchcontinue;
end isRecord;

public function nthArrayelt "function: nthArrayelt
  author: PA

  Return the nth value of an array, indexed from 1..n
"
  input Value inValue;
  input Integer inInteger;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inValue,inInteger)
    local
      Integer n_1,n;
      Value res;
      list<Value> vlst;
    case (Values.ARRAY(valueLst = vlst),n)
      equation
        n_1 = n - 1;
        res = listNth(vlst, n_1);
      then
        res;
  end matchcontinue;
end nthArrayelt;

public function unparseValues "function: unparseValues

  Prints a list of Value to a string.
"
  input list<Value> inValueLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inValueLst)
    local
      String s1,s2,s3,str;
      Value v;
      list<Value> vallst;
    case ((v :: vallst))
      equation
        s1 = unparseDescription({v});
        s2 = unparseValueNumbers({v});
        s3 = unparseValues(vallst);
        str = Util.stringAppendList({s1,s2,"\n",s3});
      then
        str;
    case ({}) then "";
  end matchcontinue;
end unparseValues;

protected function unparseValueNumbers "function: unparseValueNumbers

  Helper function to unparse_values.
  Prints all the numbers of the values.
"
  input list<Value> inValueLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inValueLst)
    local
      String s1,s2,res,istr,sval;
      list<Value> lst,xs;
      Integer i;
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
    case ((Values.REAL(real = i) :: xs))
      local Real i;
      equation
        s1 = unparseValueNumbers(xs);
        istr = realString(i);
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
  end matchcontinue;
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
	input Value val1;
	input Value val2;
	input IntRealOp op;
	output Value outv;
algorithm
  outv := matchcontinue(val1, val2, op)
    local
      Real rv1,rv2,rv3;
      Integer iv1, iv2,iv3;
      DAE.Exp e;
      //MUL
    case (Values.INTEGER(iv1),Values.INTEGER(iv2), Values.MULOP)
      equation
        e = Exp.safeIntOp(iv1,iv2,Exp.MULOP);
        outv = expValue(e);
      then
        outv;
    case (Values.REAL(rv1),Values.INTEGER(iv2), Values.MULOP)
      equation
        rv2 = intReal(iv2);
        rv3 = rv1 *. rv2;
      then
        Values.REAL(rv3);
    case (Values.INTEGER(iv1), Values.REAL(rv2), Values.MULOP)
      equation
        rv1 = intReal(iv1);
        rv3 = rv1 *. rv2;
      then
        Values.REAL(rv3);
    case (Values.REAL(rv1), Values.REAL(rv2), Values.MULOP)
      equation
        rv3 = rv1 *. rv2;
      then
        Values.REAL(rv3);
        //DIV
    case (Values.INTEGER(iv1),Values.INTEGER(iv2), Values.DIVOP)
      equation
        e = Exp.safeIntOp(iv1,iv2,Exp.DIVOP);
        outv = expValue(e);
      then
        outv;
    case (Values.REAL(rv1),Values.INTEGER(iv2), Values.DIVOP)
      equation
        rv2 = intReal(iv2);
        rv3 = rv1 /. rv2;
      then
        Values.REAL(rv3);
    case (Values.INTEGER(iv1), Values.REAL(rv2), Values.DIVOP)
      equation
        rv1 = intReal(iv1);
        rv3 = rv1 /. rv2;
      then
        Values.REAL(rv3);
    case (Values.REAL(rv1), Values.REAL(rv2), Values.DIVOP)
      equation
        rv3 = rv1 /. rv2;
      then
        Values.REAL(rv3);
        //POW
    case (Values.INTEGER(iv1),Values.INTEGER(iv2), Values.POWOP) // this means indirect that we are dealing with decimal numbers (a^(-b)) = 1/a^b
      equation
        true = (iv2 < 0);
        rv1 = intReal(iv1);
        rv2 = intReal(iv2);
        rv3 = realPow(rv1, rv2);
      then
        Values.REAL(rv3);
    case (Values.INTEGER(iv1),Values.INTEGER(iv2), Values.POWOP)
      equation
        e = Exp.safeIntOp(iv1,iv2,Exp.POWOP);
        outv = expValue(e);
      then
        outv;
    case (Values.REAL(rv1),Values.INTEGER(iv2), Values.POWOP)
      equation
        rv2 = intReal(iv2);
        rv3 = realPow(rv1, rv2);
      then
        Values.REAL(rv3);
    case (Values.INTEGER(iv1), Values.REAL(rv2), Values.POWOP)
      equation
        iv2 = realInt(rv2);
        e = Exp.safeIntOp(iv1,iv2,Exp.POWOP);
        outv = expValue(e);
      then
        outv;
    case (Values.INTEGER(iv1), Values.REAL(rv2), Values.POWOP)
      equation
        rv1 = intReal(iv1);
        rv3 = realPow(rv1, rv2);
      then
        Values.REAL(rv3);
    case (Values.REAL(rv1), Values.REAL(rv2), Values.POWOP)
      equation
        rv3 = realPow(rv1, rv2);
      then
        Values.REAL(rv3);
        //ADD
    case (Values.INTEGER(iv1),Values.INTEGER(iv2), Values.ADDOP)
      equation
        e = Exp.safeIntOp(iv1,iv2,Exp.ADDOP);
        outv = expValue(e);
      then
        outv;
    case (Values.REAL(rv1),Values.INTEGER(iv2), Values.ADDOP)
      equation
        rv2 = intReal(iv2);
        rv3 = rv1 +. rv2;
      then
        Values.REAL(rv3);
    case (Values.INTEGER(iv1), Values.REAL(rv2), Values.ADDOP)
      equation
        rv1 = intReal(iv1);
        rv3 = rv1 +. rv2;
      then
        Values.REAL(rv3);
    case (Values.REAL(rv1), Values.REAL(rv2), Values.ADDOP)
      equation
        rv3 = rv1 +. rv2;
      then
        Values.REAL(rv3);
        //SUB
    case (Values.INTEGER(iv1),Values.INTEGER(iv2), Values.SUBOP)
      equation
        e = Exp.safeIntOp(iv1,iv2,Exp.SUBOP);
        outv = expValue(e);
      then
        outv;
    case (Values.REAL(rv1),Values.INTEGER(iv2), Values.SUBOP)
      equation
        rv2 = intReal(iv2);
        rv3 = rv1 -. rv2;
      then
        Values.REAL(rv3);
    case (Values.INTEGER(iv1), Values.REAL(rv2), Values.SUBOP)
      equation
        rv1 = intReal(iv1);
        rv3 = rv1 -. rv2;
      then
        Values.REAL(rv3);
    case (Values.REAL(rv1), Values.REAL(rv2), Values.SUBOP)
      equation
        rv3 = rv1 -. rv2;
      then
        Values.REAL(rv3);
  end matchcontinue;
end safeIntRealOp;

public function safeLessEq
	"Checks if val1 is less or equal to val2. Val1 or val2 can
	 be integers or reals.
	"
	input Value val1;
	input Value val2;
	output Boolean outv;
algorithm
  outv :=
  	matchcontinue(val1, val2)
  		local
  		  Real rv1,rv2;
  		  Integer iv1,iv2;
  		  case (Values.INTEGER(iv1),Values.INTEGER(iv2))
  		    equation
  		      outv = (iv1 <= iv2);
  		  then
  		    	outv;
  		  case (Values.REAL(rv1),Values.INTEGER(iv2))
  		    equation
  		      rv2 = intReal(iv2);
  		      outv = (rv1 <=. rv2);
  		  then
  		    	outv;
  		  case (Values.INTEGER(iv1), Values.REAL(rv2))
  		    equation
  		      rv1 = intReal(iv1);
  		      outv = (rv1 <=. rv2);
  		  then
  		    	outv;
  		  case (Values.REAL(rv1), Values.REAL(rv2))
  		    equation
  		      outv = (rv1 <=. rv2);
  		  then
  		    	outv;
		end matchcontinue;
end safeLessEq;

protected function unparseDescription "function: unparseDescription

  Helper function to unparse_values. Creates a description string
  for the type of the value.
"
  input list<Value> inValueLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inValueLst)
    local
      String s1,str,slenstr,sval,s2,s4;
      list<Value> xs,vallst;
      Integer slen;
    case ((Values.INTEGER(integer = _) :: xs))
      equation
        s1 = unparseDescription(xs);
        str = stringAppend("# i!\n", s1);
      then
        str;
    case ((Values.REAL(real = _) :: xs))
      equation
        s1 = unparseDescription(xs);
        str = stringAppend("# r!\n", s1);
      then
        str;
    case ((Values.STRING(string = sval) :: xs))
      equation
        s1 = unparseDescription(xs);
        slen = stringLength(sval);
        slenstr = intString(slen);
        str = Util.stringAppendList({"# s! 1 ",slenstr,"\n"});
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
  end matchcontinue;
end unparseDescription;

protected function unparseArrayDescription "function: unparseArrayDescription

  Helper function to unparse_description.
"
  input list<Value> lst;
  output String str;
  String pt,s1,s2,s3,s4,s5,s6;
  Integer i1;
algorithm
  pt := unparsePrimType(lst);
  s1 := stringAppend("# ", pt);
  s2 := stringAppend(s1, "[");
  i1 := unparseNumDims(lst);
  s3 := intString(i1);
  s4 := stringAppend(s2, s3);
  s5 := stringAppend(s4, " ");
  s6 := unparseDimSizes(lst);
  str := stringAppend(s5, s6);
end unparseArrayDescription;

protected function unparsePrimType "function: unparsePrimType

  Helper function to unparse_array_description.
"
  input list<Value> inValueLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inValueLst)
    local
      String res;
      list<Value> elts;
    case ((Values.ARRAY(valueLst = elts) :: _))
      equation
        res = unparsePrimType(elts);
      then
        res;
    case ((Values.INTEGER(integer = _) :: _)) then "i";
    case ((Values.REAL(real = _) :: _)) then "r";
    case ((Values.STRING(string = _) :: _)) then "s";
    case ((Values.BOOL(boolean = _) :: _)) then "b";
    case ({}) then "{}";
    case (_) then "error";
  end matchcontinue;
end unparsePrimType;

protected function unparseNumDims "function: unparseNumDims

  Helper function to unparse_array_description.
"
  input list<Value> inValueLst;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inValueLst)
    local
      Integer i1;
      list<Value> vals;
    case ((Values.ARRAY(valueLst = vals) :: _))
      equation
        i1 = unparseNumDims(vals);
      then
        i1 + 1;
    case (_) then 1;
  end matchcontinue;
end unparseNumDims;

protected function unparseDimSizes "function: unparseDimSizes

  Helper function to unparse_array_description.
"
  input list<Value> inValueLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inValueLst)
    local
      Integer i1,len;
      String s1,s2,s3,res;
      list<Value> lst,vals;
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

public function writeToFileAsArgs "function: writeToFileAsArgs

  Write a list of Values to a file. This function is used when
  writing the formal input arguments of a function call to a file before
  executing the function.
"
  input list<Value> vallst;
  input String filename;
  String str;
algorithm
  str := unparseValues(vallst);
  System.writeFile(filename, str);
end writeToFileAsArgs;

public function addElementwiseArrayelt "function: addElementwiseArrayelt

  Perform elementwise addition of two arrays.
"
  input list<Value> inValueLst1;
  input list<Value> inValueLst2;
  output list<Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValueLst1,inValueLst2)
    local
      list<Value> reslst,res2,v1lst,rest1,v2lst,rest2;
      Integer res,v1,v2;
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
    case ((Values.REAL(real = v1) :: rest1),(Values.REAL(real = v2) :: rest2))
      local Real res,v1,v2;
      equation
        res = v1 +. v2;
        res2 = addElementwiseArrayelt(rest1, rest2);
      then
        (Values.REAL(res) :: res2);
    case ((Values.STRING(string = v1) :: rest1),(Values.STRING(string = v2) :: rest2))
      local String res,v1,v2;
      equation
        res = stringAppend(v1, v2);
        res2 = addElementwiseArrayelt(rest1, rest2) "Addition of strings is string concatenation" ;
      then
        (Values.STRING(res) :: res2);
    case ({},{}) then {};
  end matchcontinue;
end addElementwiseArrayelt;

public function subElementwiseArrayelt "function: subElementwiseArrayelt

  Perform element subtraction of two arrays of values
"
  input list<Value> inValueLst1;
  input list<Value> inValueLst2;
  output list<Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValueLst1,inValueLst2)
    local
      list<Value> reslst,res2,v1lst,rest1,v2lst,rest2;
      Integer res,v1,v2;
      list<Integer> dims;
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
    case ((Values.REAL(real = v1) :: rest1),(Values.REAL(real = v2) :: rest2))
      local Real res,v1,v2;
      equation
        res = v1 -. v2;
        res2 = subElementwiseArrayelt(rest1, rest2);
      then
        (Values.REAL(res) :: res2);
    case ({},{}) then {};
  end matchcontinue;
end subElementwiseArrayelt;

public function mulElementwiseArrayelt "function: mulElementwiseArrayelt

  Perform elementwise multiplication of two arrays of values
"
  input list<Value> inValueLst1;
  input list<Value> inValueLst2;
  output list<Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValueLst1,inValueLst2)
    local
      list<Value> reslst,res2,v1lst,rest1,v2lst,rest2;
      Integer res,v1,v2;
      list<Integer> dims;
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
    case ((Values.REAL(real = v1) :: rest1),(Values.REAL(real = v2) :: rest2))
      local Real res,v1,v2;
      equation
        res = v1 *. v2;
        res2 = mulElementwiseArrayelt(rest1, rest2);
      then
        (Values.REAL(res) :: res2);
    case ({},{}) then {};
  end matchcontinue;
end mulElementwiseArrayelt;

public function divElementwiseArrayelt "function: divElementwiseArrayelt

  Perform elementwise division of two arrays of values
"
  input list<Value> inValueLst1;
  input list<Value> inValueLst2;
  output list<Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValueLst1,inValueLst2)
    local
      list<Value> reslst,res2,v1lst,rest1,v2lst,rest2;
      Real res;
      Integer v1,v2;
      list<Integer> dims;
    case ((Values.ARRAY(valueLst = v1lst, dimLst = dims) :: rest1),(Values.ARRAY(valueLst = v2lst) :: rest2))
      equation
        reslst = divElementwiseArrayelt(v1lst, v2lst);
        res2 = divElementwiseArrayelt(rest1, rest2);
      then
        (Values.ARRAY(reslst,dims) :: res2);
    case ((Values.INTEGER(integer = v1) :: rest1),(Values.INTEGER(integer = v2) :: rest2))
      local Real v1_1,v2_1;
      equation
        v1_1=intReal(v1);
        v2_1=intReal(v2);
        res = v1_1 /. v2_1;
        res2 = divElementwiseArrayelt(rest1, rest2);
      then
        (Values.REAL(res) :: res2);
    case ((Values.REAL(real = v1) :: rest1),(Values.REAL(real = v2) :: rest2))
      local Real res,v1,v2;
      equation
        res = v1 /. v2;
        res2 = divElementwiseArrayelt(rest1, rest2);
      then
        (Values.REAL(res) :: res2);
    case ({},{}) then {};
  end matchcontinue;
end divElementwiseArrayelt;

public function powElementwiseArrayelt "function: powElementwiseArrayelt

  Computes elementwise powers of two arrays of values
"
  input list<Value> inValueLst1;
  input list<Value> inValueLst2;
  output list<Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValueLst1,inValueLst2)
    local
      list<Value> reslst,res2,v1lst,rest1,v2lst,rest2;
      Integer v1,v2;
      Real res;
      list<Integer> dims;
    case ((Values.ARRAY(valueLst = v1lst, dimLst = dims) :: rest1),(Values.ARRAY(valueLst = v2lst) :: rest2))
      equation
        reslst = powElementwiseArrayelt(v1lst, v2lst);
        res2 = powElementwiseArrayelt(rest1, rest2);
      then
        (Values.ARRAY(reslst,dims) :: res2);
    case ((Values.INTEGER(integer = v1) :: rest1),(Values.INTEGER(integer = v2) :: rest2))
      local Real v1_1,v2_1;
      equation
        v1_1=intReal(v1);
        v2_1=intReal(v2);
        res = v1_1 ^. v2_1;
        res2 = powElementwiseArrayelt(rest1, rest2);
      then
        (Values.REAL(res) :: res2);
    case ((Values.REAL(real = v1) :: rest1),(Values.REAL(real = v2) :: rest2))
      local Real res,v1,v2;
      equation
        res = v1 ^. v2;
        res2 = powElementwiseArrayelt(rest1, rest2);
      then
        (Values.REAL(res) :: res2);
    case ({},{}) then {};
  end matchcontinue;
end powElementwiseArrayelt;

public function expValue "function: expValue

  Returns the value of constant expressions in DAE.Exp
"
  input DAE.Exp inExp;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inExp)
    local
      Integer i;
      Real r;
      Boolean b;
      String s;
    case DAE.ICONST(integer = i) then Values.INTEGER(i);
    case DAE.RCONST(real = r) then Values.REAL(r);
    case DAE.SCONST(string = s) then Values.STRING(s);
    case DAE.BCONST(bool = b) then Values.BOOL(b);
  end matchcontinue;
end expValue;


public function valueReal "function: valueReal

  Return the real value of a Value. If the value is an integer,
  it is cast to a real.
"
  input Value inValue;
  output Real outReal;
algorithm
  outReal:=
  matchcontinue (inValue)
    local
      Real r;
      Integer i;
    case (Values.REAL(real = r)) then r;
    case (Values.INTEGER(integer = i))
      equation
        r = intReal(i);
      then
        r;
  end matchcontinue;
end valueReal;

public function valueIntegerMinusOne "To be able to use listNth"
  input Value inValue;
  output Integer outInt;
algorithm
  outInt := matchcontinue (inValue)
    local
      Integer i;
    case (Values.INTEGER(integer = i)) then i-1;
  end matchcontinue;
end valueIntegerMinusOne;

public function valueBool "function: valueReal
Author: BZ, 2008-09
  Return the bool value of a Value.
"
  input Value inValue;
  output Boolean outBool;
algorithm outReal:= matchcontinue (inValue)
    case (Values.BOOL(outBool)) then outBool;
  end matchcontinue;
end valueBool;

public function valueReals "function: valueReals

  Return the real value of a Value. If the value is an integer,
  it is cast to a real.
"
  input list<Value> inValue;
  output list<Real> outReal;
algorithm
  outReal:=
  matchcontinue (inValue)
    local
      Real r;
      list<Value> rest;
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

public function valueNeg "function: valueNeg
  author: PA

  Negates a Value
"
  input Value inValue;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inValue)
    local
      Real r_1,r;
      Integer i_1,i;
      list<Value> vlst_1,vlst;
      list<Integer> dims;
    case (Values.REAL(real = r))
      equation
        r_1 = -.r;
      then
        Values.REAL(r_1);
    case (Values.INTEGER(integer = i))
      equation
        i_1 = -i;
      then
        Values.INTEGER(i_1);
    case Values.ARRAY(valueLst = vlst, dimLst = dims)
      equation
        vlst_1 = Util.listMap(vlst, valueNeg);
      then
        Values.ARRAY(vlst_1,dims);
  end matchcontinue;
end valueNeg;

public function sumArrayelt "function: sumArrayelt

  Calculate the sum of a list of Values.
"
  input list<Value> inValueLst;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inValueLst)
    local
      Integer v1,v3,v2;
      list<Value> xs,arr;
      list<Integer> dims;
    case ({Values.INTEGER(integer = v1)}) then Values.INTEGER(v1);
    case ({Values.REAL(real = v1)})
      local Real v1;
      then
        Values.REAL(v1);
    case ({Values.ARRAY(valueLst = v1, dimLst = dims)})
      local list<Value> v1;
      then
        Values.ARRAY(v1,dims);
    case ((Values.INTEGER(integer = v2) :: xs))
      equation
        Values.INTEGER(v1) = sumArrayelt(xs);
        v3 = v1 + v2;
      then
        Values.INTEGER(v3);
    case ((Values.REAL(real = v2) :: xs))
      local Real v1,v3,v2;
      equation
        Values.REAL(v1) = sumArrayelt(xs);
        v3 = v1 +. v2;
      then
        Values.REAL(v3);
    case ((arr as (Values.ARRAY(valueLst = v2) :: _)))
      local list<Value> v1,v3,v2;
      equation
        Values.ARRAY(v1,dims) = sumArrayelt(arr);
        v3 = addElementwiseArrayelt(v1, v2);
      then
        Values.ARRAY(v3,dims);
  end matchcontinue;
end sumArrayelt;

public function multScalarArrayelt "function: multScalarArrayelt

  Multiply a scalar with an list of Values, i.e. array.
"
  input Value inValue;
  input list<Value> inValueLst;
  output list<Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValue,inValueLst)
    local
      list<Value> r1,r2,vals,rest;
      Value sval;
      Integer v1,v2;
      Real v2_1,v1_1;
      list<Integer> dims;
    case (sval,(Values.ARRAY(valueLst = vals, dimLst = dims) :: rest))
      equation
        r1 = multScalarArrayelt(sval, vals);
        r2 = multScalarArrayelt(sval, rest);
      then
        (Values.ARRAY(r1,dims) :: r2);
    case ((sval as Values.INTEGER(integer = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Integer r1;
      equation
        r1 = v1*v2;
        r2 = multScalarArrayelt(sval, rest);
      then
        (Values.INTEGER(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Real r1,v1;
      equation
        v2_1 = intReal(v2);
        r1 = v1*.v2_1;
        r2 = multScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.INTEGER(integer = v1)),(Values.REAL(real = v2) :: rest))
      local Real r1,v2;
      equation
        v1_1 = intReal(v1);
        r1 = v1_1*.v2;
        r2 = multScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.REAL(real = v2) :: rest))
      local Real r1,v1,v2;
      equation
        r1 = v1*.v2;
        r2 = multScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case (_,{}) then {};
  end matchcontinue;
end multScalarArrayelt;

public function addScalarArrayelt "function: addScalarArrayelt

  Adds a scalar to an list of Values, i.e. array.
"
  input Value inValue;
  input list<Value> inValueLst;
  output list<Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValue,inValueLst)
    local
      list<Value> r1,r2,vals,rest;
      Value sval;
      Integer v1,v2;
      Real v2_1,v1_1;
      list<Integer> dims;
    case (sval,(Values.ARRAY(valueLst = vals, dimLst = dims) :: rest))
      equation
        r1 = addScalarArrayelt(sval, vals);
        r2 = addScalarArrayelt(sval, rest);
      then
        (Values.ARRAY(r1,dims) :: r2);
    case ((sval as Values.INTEGER(integer = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Integer r1;
      equation
        r1 = v1+v2;
        r2 = addScalarArrayelt(sval, rest);
      then
        (Values.INTEGER(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Real r1,v1;
      equation
        v2_1 = intReal(v2);
        r1 = v1+.v2_1;
        r2 = addScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.INTEGER(integer = v1)),(Values.REAL(real = v2) :: rest))
      local Real r1,v2;
      equation
        v1_1 = intReal(v1);
        r1 = v1_1+.v2;
        r2 = addScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.REAL(real = v2) :: rest))
      local Real r1,v1,v2;
      equation
        r1 = v1+.v2;
        r2 = addScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.STRING(string = v1)),(Values.STRING(string = v2) :: rest))
      local String r1,v1,v2;
      equation
        r1 = v1+&v2;
        r2 = addScalarArrayelt(sval, rest);
      then
        (Values.STRING(r1) :: r2);
    case (_,{}) then {};
  end matchcontinue;
end addScalarArrayelt;

public function divScalarArrayelt "function: divScalarArrayelt

  Divide a scalar with an list of Values, i.e. array.
"
  input Value inValue;
  input list<Value> inValueLst;
  output list<Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValue,inValueLst)
    local
      list<Value> r1,r2,vals,rest;
      Value sval;
      Integer v1,v2;
      Real v2_1,v1_1;
      String s2;
      list<Integer> dims;
    case (sval,(Values.ARRAY(valueLst = vals, dimLst = dims) :: rest))
      equation
        r1 = divScalarArrayelt(sval, vals);
        r2 = divScalarArrayelt(sval, rest);
      then
        (Values.ARRAY(r1,dims) :: r2);
    case (sval ,(Values.INTEGER(integer = v2) :: rest))
      equation
        equality(v2 = 0);
        s2 = valString(sval);
        Error.addMessage(Error.DIVISION_BY_ZERO, {"0",s2});
      then
        fail();
    case (sval ,(Values.REAL(real = v2_1) :: rest))
      equation
        equality(v2_1 = 0.0);
        s2 = valString(sval);
        Error.addMessage(Error.DIVISION_BY_ZERO, {"0.0",s2});
      then
        fail();
    case ((sval as Values.INTEGER(integer = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Real r1;
      equation
        v1_1=intReal(v1);
        v2_1=intReal(v2);
        r1 = v1_1/.v2_1;
        r2 = divScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Real r1,v1;
      equation
        v2_1 = intReal(v2);
        r1 = v1/.v2_1;
        r2 = divScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.INTEGER(integer = v1)),(Values.REAL(real = v2) :: rest))
      local Real r1,v2;
      equation
        v1_1 = intReal(v1);
        r1 = v1_1/.v2;
        r2 = divScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.REAL(real = v2) :: rest))
      local Real r1,v1,v2;
      equation
        r1 = v1/.v2;
        r2 = divScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case (_,{}) then {};
  end matchcontinue;
end divScalarArrayelt;

public function subScalarArrayelt "function: subScalarArrayelt

  subtracts a list of Values, i.e. array, from a scalar.
"
  input Value inValue;
  input list<Value> inValueLst;
  output list<Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValue,inValueLst)
    local
      list<Value> r1,r2,vals,rest;
      Value sval;
      Integer v1,v2;
      Real v2_1,v1_1;
      list<Integer> dims;
    case (sval,(Values.ARRAY(valueLst = vals, dimLst = dims) :: rest))
      equation
        r1 = subScalarArrayelt(sval, vals);
        r2 = subScalarArrayelt(sval, rest);
      then
        (Values.ARRAY(r1,dims) :: r2);
    case ((sval as Values.INTEGER(integer = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Integer r1;
      equation
        r1 = v1-v2;
        r2 = subScalarArrayelt(sval, rest);
      then
        (Values.INTEGER(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Real r1,v1;
      equation
        v2_1 = intReal(v2);
        r1 = v1-.v2_1;
        r2 = subScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.INTEGER(integer = v1)),(Values.REAL(real = v2) :: rest))
      local Real r1,v2;
      equation
        v1_1 = intReal(v1);
        r1 = v1_1-.v2;
        r2 = subScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.REAL(real = v2) :: rest))
      local Real r1,v1,v2;
      equation
        r1 = v1-.v2;
        r2 = subScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case (_,{}) then {};
  end matchcontinue;
end subScalarArrayelt;

public function powScalarArrayelt "function: powScalarArrayelt

  Takes a power of a scalar with an list of Values, i.e. array.
"
  input Value inValue;
  input list<Value> inValueLst;
  output list<Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValue,inValueLst)
    local
      list<Value> r1,r2,vals,rest;
      Value sval;
      Integer v1,v2;
      Real v2_1,v1_1;
      list<Integer> dims;
    case (sval,(Values.ARRAY(valueLst = vals, dimLst = dims) :: rest))
      equation
        r1 = powScalarArrayelt(sval, vals);
        r2 = powScalarArrayelt(sval, rest);
      then
        (Values.ARRAY(r1,dims) :: r2);
    case ((sval as Values.INTEGER(integer = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Real r1;
      equation
        v1_1=intReal(v1);
        v2_1=intReal(v2);
        r1 = v1_1^.v2_1;
        r2 = powScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Real r1,v1;
      equation
        v2_1 = intReal(v2);
        r1 = v1^.v2_1;
        r2 = powScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.INTEGER(integer = v1)),(Values.REAL(real = v2) :: rest))
      local Real r1,v2;
      equation
        v1_1 = intReal(v1);
        r1 = v1_1^.v2;
        r2 = powScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.REAL(real = v2) :: rest))
      local Real r1,v1,v2;
      equation
        r1 = v1^.v2;
        r2 = powScalarArrayelt(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case (_,{}) then {};
  end matchcontinue;
end powScalarArrayelt;

public function subArrayeltScalar "function: subArrayeltScalar

  subtracts a scalar from a list of Values, i.e. array.
"
  input Value inValue;
  input list<Value> inValueLst;
  output list<Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValue,inValueLst)
    local
      list<Value> r1,r2,vals,rest;
      Value sval;
      Integer v1,v2;
      Real v2_1,v1_1;
      list<Integer> dims;
    case (sval,(Values.ARRAY(valueLst = vals, dimLst = dims) :: rest))
      equation
        r1 = subArrayeltScalar(sval, vals);
        r2 = subArrayeltScalar(sval, rest);
      then
        (Values.ARRAY(r1,dims) :: r2);
    case ((sval as Values.INTEGER(integer = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Integer r1;
      equation
        r1 = v2-v1;
        r2 = subArrayeltScalar(sval, rest);
      then
        (Values.INTEGER(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Real r1,v1;
      equation
        v2_1 = intReal(v2);
        r1 = v2_1-.v1;
        r2 = subArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.INTEGER(integer = v1)),(Values.REAL(real = v2) :: rest))
      local Real r1,v2;
      equation
        v1_1 = intReal(v1);
        r1 = v2-.v1_1;
        r2 = subArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.REAL(real = v2) :: rest))
      local Real r1,v1,v2;
      equation
        r1 = v2-.v1;
        r2 = subArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case (_,{}) then {};
  end matchcontinue;
end subArrayeltScalar;

public function powArrayeltScalar "function: powArrayeltScalar

  Takes a power of a list of Values, i.e. array, with a scalar.
"
  input Value inValue;
  input list<Value> inValueLst;
  output list<Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValue,inValueLst)
    local
      list<Value> r1,r2,vals,rest;
      Value sval;
      Integer v1,v2;
      Real v2_1,v1_1;
      list<Integer> dims;
    case (sval,(Values.ARRAY(valueLst = vals, dimLst = dims) :: rest))
      equation
        r1 = powArrayeltScalar(sval, vals);
        r2 = powArrayeltScalar(sval, rest);
      then
        (Values.ARRAY(r1,dims) :: r2);
    case ((sval as Values.INTEGER(integer = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Real r1;
      equation
        v1_1=intReal(v1);
        v2_1=intReal(v2);
        r1 = v2_1^.v1_1;
        r2 = powArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Real r1,v1;
      equation
        v2_1 = intReal(v2);
        r1 = v2_1^.v1;
        r2 = powArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.INTEGER(integer = v1)),(Values.REAL(real = v2) :: rest))
      local Real r1,v2;
      equation
        v1_1 = intReal(v1);
        r1 = v2^.v1_1;
        r2 = powArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.REAL(real = v2) :: rest))
      local Real r1,v1,v2;
      equation
        r1 = v2^.v1;
        r2 = powArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case (_,{}) then {};
  end matchcontinue;
end powArrayeltScalar;

public function multScalarProduct "function: multScalarProduct

  Calculate the scalar product of two vectors / arrays.
"
  input list<Value> inValueLst1;
  input list<Value> inValueLst2;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inValueLst1,inValueLst2)
    local
      Integer r1,r2,res,v1,v2,len,len2,dim;
      list<Value> v1lst,v2lst,vres,rest,vlst,col,mat_1,vals,mat,lst1,lst2;
      Value sres,v;
      String lenstr,len2str;
      list<Integer> dims;
    case ((Values.INTEGER(integer = v1) :: (v1lst as (_ :: _))),(Values.INTEGER(integer = v2) :: (v2lst as (_ :: _))))
      equation
        r1 = v1*v2;
        Values.INTEGER(r2) = multScalarProduct(v1lst, v2lst);
        res = r1 + r2;
      then
        Values.INTEGER(res);
    case ({Values.INTEGER(integer = v1)},{Values.INTEGER(integer = v2)})
      equation
        res = v1*v2;
      then
        Values.INTEGER(res);
    case ((Values.REAL(real = v1) :: (v1lst as (_ :: _))),(Values.REAL(real = v2) :: (v2lst as (_ :: _))))
      local Real r1,r2,res,v1,v2;
      equation
        r1 = v1*.v2;
        Values.REAL(r2) = multScalarProduct(v1lst, v2lst);
        res = r1 +. r2;
      then
        Values.REAL(res);
    case ({Values.REAL(real = v1)},{Values.REAL(real = v2)})
      local Real res,v1,v2;
      equation
        res = v1*.v2;
      then
        Values.REAL(res);
    case ((Values.ARRAY(valueLst = v2lst) :: rest),(vlst as (Values.INTEGER(integer = _) :: _)))
      equation
        sres = multScalarProduct(v2lst, vlst);
        Values.ARRAY(vres,dim::dims) = multScalarProduct(rest, vlst);
        dim = dim+1;
      then
        Values.ARRAY(sres :: vres, dim::dims);
    case ({},(Values.INTEGER(integer = _) :: _)) then makeArray({});
    case ((Values.ARRAY(valueLst = v2lst) :: rest),(vlst as (Values.REAL(real = _) :: _)))
      equation
        sres = multScalarProduct(v2lst, vlst);
        Values.ARRAY(vres,dim::dims) = multScalarProduct(rest, vlst);
        dim = dim+1;
      then
        Values.ARRAY(sres :: vres,dim::dims);
    case ({},(Values.REAL(real = _) :: _)) then makeArray({});
    case ((vlst as (Values.INTEGER(integer = _) :: _)),(mat as (Values.ARRAY(valueLst = (_ :: (_ :: _))) :: _)))
      equation
        (Values.ARRAY(valueLst = col),mat_1) = matrixStripFirstColumn(mat);
        v = multScalarProduct(vlst, col);
        Values.ARRAY(vals,dim::dims) = multScalarProduct(vlst, mat_1);
      then
        Values.ARRAY(v :: vals, dim::dims);
    case ((vlst as (Values.INTEGER(integer = _) :: _)),(mat as (Values.ARRAY(valueLst = {_}) :: _)))
      local Integer v;
      equation
        (Values.ARRAY(valueLst = col),mat_1) = matrixStripFirstColumn(mat);
        Values.INTEGER(v) = multScalarProduct(vlst, col);
      then
        makeArray({Values.INTEGER(v)});
    case ((vlst as (Values.REAL(real = _) :: _)),(mat as (Values.ARRAY(valueLst = (_ :: (_ :: _))) :: _)))
      equation
        (Values.ARRAY(valueLst = col),mat_1) = matrixStripFirstColumn(mat);
        v = multScalarProduct(vlst, col);
        Values.ARRAY(valueLst = vals, dimLst = dim::dims) = multScalarProduct(vlst, mat_1);
        dim = dim+1;
      then
        Values.ARRAY(v :: vals, dim::dims);
    case ((vlst as (Values.REAL(real = _) :: _)),(mat as (Values.ARRAY(valueLst = {_}) :: _)))
      local Real v;
      equation
        (Values.ARRAY(valueLst = col),mat_1) = matrixStripFirstColumn(mat);
        Values.REAL(v) = multScalarProduct(vlst, col);
      then
        makeArray({Values.REAL(v)});
    case (lst1,lst2)
      equation
        Debug.fprintln("failtrace", "Values.multScalarProduct failed");
      then
        fail();
  end matchcontinue;
end multScalarProduct;

public function crossProduct "
  Calculate the cross product of two vectors.
  x,y => {x[2]*y[3]-x[3]*y[2],x[3]*y[1]-x[1]*y[3],x[1]*y[2]-x[2]*y[1]}
"
  input list<Value> inValueLst1;
  input list<Value> inValueLst2;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inValueLst1,inValueLst2)
    case ({Values.REAL(x1),Values.REAL(x2),Values.REAL(x3)},
          {Values.REAL(y1),Values.REAL(y2),Values.REAL(y3)})
      local
        Real x1,x2,x3,y1,y2,y3,z1,z2,z3;
      equation
        z1 = realSub(realMul(x2,y3),realMul(x3,y2));
        z2 = realSub(realMul(x3,y1),realMul(x1,y3));
        z3 = realSub(realMul(x1,y2),realMul(x2,y1));
      then
        makeArray({Values.REAL(z1),Values.REAL(z2),Values.REAL(z3)});
    case ({Values.INTEGER(x1),Values.INTEGER(x2),Values.INTEGER(x3)},
          {Values.INTEGER(y1),Values.INTEGER(y2),Values.INTEGER(y3)})
      local
        Integer x1,x2,x3,y1,y2,y3,z1,z2,z3;
      equation
        z1 = intSub(intMul(x2,y3),intMul(x3,y2));
        z2 = intSub(intMul(x3,y1),intMul(x1,y3));
        z3 = intSub(intMul(x1,y2),intMul(x2,y1));
      then
        makeArray({Values.INTEGER(z1),Values.INTEGER(z2),Values.INTEGER(z3)});
    case (_,_)
      equation
        Debug.fprintln("failtrace", "- ValuesUtil.crossProduct failed");
      then
        fail();
  end matchcontinue;
end crossProduct;

public function multMatrix "function: multMatrix

  Calculate a matrix multiplication of two matrices, i.e. two dimensional
  arrays.
"
  input list<Value> inValueLst1;
  input list<Value> inValueLst2;
  output list<Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValueLst1,inValueLst2)
    local
      Value res1;
      list<Value> res2,m1,v1lst,rest1,m2;
    case ((m1 as (Values.ARRAY(valueLst = v1lst) :: rest1)),(m2 as (Values.ARRAY(valueLst = _) :: _)))
      equation
        res1 = multScalarProduct(v1lst, m2);
        res2 = multMatrix(rest1, m2);
      then
        (res1 :: res2);
    case ({},_) then {};
  end matchcontinue;
end multMatrix;

public function divArrayeltScalar
"function: divArrayeltScalar
  Divide each array element with a scalar."
  input Value inValue;
  input list<Value> inValueLst;
  output list<Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValue,inValueLst)
    local
      String s2;
      Value sval;
      Real v1,v2_1,v1_1;
      list<Value> vlst,r1,r2,vals,rest;
      Integer v2;
      list<Integer> dims;
    case ((sval as Values.REAL(real = v1)),vlst)
      equation
        equality(v1 = 0.0);
        s2 = unparseValues(vlst);
        Error.addMessage(Error.DIVISION_BY_ZERO, {"0.0",s2});
      then
        fail();
    case ((sval as Values.INTEGER(integer = v1)),vlst)
      local Integer v1;
      equation
        equality(v1 = 0);
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
    case ((sval as Values.INTEGER(integer = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Integer r1,v1;
      equation
        r1 = v2/v1;
        r2 = divArrayeltScalar(sval, rest);
      then
        (Values.INTEGER(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.INTEGER(integer = v2) :: rest))
      local Real r1;
      equation
        v2_1 = intReal(v2);
        r1 = v2_1/.v1;
        r2 = divArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.INTEGER(integer = v1)),(Values.REAL(real = v2) :: rest))
      local
        Real r1,v2;
        Integer v1;
      equation
        v1_1 = intReal(v1);
        r1 = v2/.v1_1;
        r2 = divArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case ((sval as Values.REAL(real = v1)),(Values.REAL(real = v2) :: rest))
      local Real r1,v2;
      equation
        r1 = v2/.v1;
        r2 = divArrayeltScalar(sval, rest);
      then
        (Values.REAL(r1) :: r2);
    case (_,{}) then {};
  end matchcontinue;
end divArrayeltScalar;

protected function matrixStripFirstColumn "function: matrixStripFirstColumn

  This function takes a Value list representing a matrix and strips the
  first column of the matrix, i.e. for each sub list it removes the first
  element. Returning both the stripped column and the resulting matrix.
"
  input list<Value> inValueLst;
  output Value outValue;
  output list<Value> outValueLst;
algorithm
  (outValue,outValueLst):=
  matchcontinue (inValueLst)
    local
      list<Value> resl,resl2,vrest,rest;
      Value v1;
      Integer i;
      list<Integer> dims;
      Integer dim;
    case ((Values.ARRAY(valueLst = (v1 :: vrest), dimLst = {dim}) :: rest))
      equation
        (Values.ARRAY(resl,{i}),resl2) = matrixStripFirstColumn(rest);
        i = i+1;
        dim = dim - 1;
      then
        (Values.ARRAY((v1 :: resl),{i}),(Values.ARRAY(vrest,{dim}) :: resl2));
    case ({}) then (Values.ARRAY({},{0}),{});
  end matchcontinue;
end matrixStripFirstColumn;

public function intlistToValue "function: intlistToValue

  Takes a list of integers and builds a Value from it, i.e. an
  array of integers.
"
  input list<Integer> inIntegerLst;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inIntegerLst)
    local
      list<Value> res;
      Integer i,len;
      list<Integer> lst;
    case ({}) then Values.ARRAY({},{0});
    case ((i :: lst))
      equation
        Values.ARRAY(res,{len}) = intlistToValue(lst);
        len = len+1;
      then
        Values.ARRAY((Values.INTEGER(i) :: res),{len});
  end matchcontinue;
end intlistToValue;

public function arrayValues "function: arrayValues

  Return the values of an array.
"
  input Value inValue;
  output list<Value> outValueLst;
algorithm
  outValueLst:=
  matchcontinue (inValue)
    local list<Value> v_lst;
    case (Values.ARRAY(valueLst = v_lst)) then v_lst;
  end matchcontinue;
end arrayValues;

public function makeReal "Creates a real value "
  input Real r;
  output Value v;
algorithm
  v := Values.REAL(r);
end makeReal;

public function makeArray "function: makeArray

  Construct an array of a list of Values.
"
  input list<Value> inValueLst;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inValueLst)
    local
      Integer i1;
      list<Integer> il;
      list<Value> vlst;
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

public function valString "function: valString

  This function returns a textual representation of a value.
"
  input Value inValue;
  output String outString;
protected
  String oldBuffer;
algorithm
  oldBuffer := Print.getString();
  Print.clearBuf();
  valString2(inValue);
  outString := Print.getString();
  Print.clearBuf();
  Print.printBuf(oldBuffer);
end valString;

public function valString2 "function: valString

  This function returns a textual representation of a value.
  Uses an external buffer to store intermediate results.
"
  input Value inValue;
algorithm
  outString:=
  matchcontinue (inValue)
    local
      String s,s_1,s_2,res,res_1;
      Integer n;
      Real x;
      list<Value> vs;
      Value r;
      Absyn.CodeNode c;
      DAE.ComponentRef cr;
      Absyn.Path p;

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
        s_1 = Util.stringAppendList({"\"",s,"\""});
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
    case Values.ARRAY(valueLst = vs)
      equation
        Print.printBuf("{");
        valListString(vs);
        Print.printBuf("}");
      then
        ();
    case Values.TUPLE(valueLst = vs)
      equation
        Print.printBuf("(");
        valListString(vs);
        Print.printBuf(")");
      then
        ();
    case Values.META_TUPLE(valueLst = vs)
      equation
        Print.printBuf("(");
        valListString(vs);
        Print.printBuf(")");
      then
        ();
    case ((r as Values.RECORD(record_ = recordPath, orderd = xs, comp = ids)))
      local
        Absyn.Path recordPath;
        String recordName;
        list<Value> xs;
        list<String> ids;
      equation
        recordName = Absyn.pathString(recordPath);
        
        Print.printBuf("record " +& recordName +& "\n");
        valRecordString(xs,ids);
        Print.printBuf("end " +& recordName +& ";");
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
    case (Values.ENUM(index = n, path=p))
      equation
//      s = Exp.printComponentRefStr(cr);
        s = intString(n) +& " /* ENUM: " +& Absyn.pathString(p) +& " */";
        Print.printBuf(s);
      then
        ();
    case(Values.NORETCALL) then ();
    case _
      equation
        Debug.fprintln("failtrace", "- ValuesUtil.valString2 failed");
      then
        fail();
  end matchcontinue;
end valString2;

protected function valRecordString
"function: valRecordString
  This function returns a textual representation of a record,
 separating each value with a comma."
  input list<Value> xs;
  input list<String> ids;
algorithm
  outString := matchcontinue (xs,ids)
    local
      Absyn.Path cname;
      String s1,s2,res,id;
      Value x;
      
      Integer ix;
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
  end matchcontinue;
end valRecordString;

protected function valListString "function: valListString

  This function returns a textual representation of a list of
  values, separating each value with a comman.
"
  input list<Value> inValueLst;
algorithm
  outString:=
  matchcontinue (inValueLst)
    local
      Value v;
      list<Value> vs;
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
    case _
      equation
        Debug.fprintln("failtrace", "- ValuesUtil.valListString failed");
      then
        fail();
  end matchcontinue;
end valListString;

public function writePtolemyplotDataset "function: writePtolemyplotDataset

  This function writes a data set in the pltolemy plot format to a file.
  The first column of the dataset matrix should be the time variable.
  The message string will be displayed in the plot window of ptplot.
"
  input String inString1;
  input Value inValue2;
  input list<String> inStringLst3;
  input String inString4;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inString1,inValue2,inStringLst3,inString4)
    local
      String datasets,str,filename,timevar,message,oldBuf;
      Value time;
      list<Value> rest;
      list<String> varnames;
    case (filename,Values.ARRAY(valueLst = (time :: rest)),(timevar :: varnames),message) /* filename values Variable names message string */
      equation
        oldBuf = Print.getString();
        Print.clearBuf();

        Print.printBuf("#Ptolemy Plot generated by OpenModelica\nTitleText: ");
        Print.printBuf(message);
        Print.printBuf("\n");
        unparsePtolemyValues(time, rest, varnames);
        
        str = Print.getString();
        Print.clearBuf();
        Print.printBuf(oldBuf);

        System.writeFile(filename, str);
      then
        0;
  end matchcontinue;
end writePtolemyplotDataset;

public function sendPtolemyplotDataset "function: sendPtolemyplotDataset
  This function writes a data set in the pltolemy plot format to a file.
  The first column of the dataset matrix should be the time variable.
  The message string will be displayed in the plot window of ptplot."
  input Value inValue2;
  input list<String> inStringLst3;
  input String inString4;
  input String interpolation;
  input String title;
  input Boolean legend;
  input Boolean grid;
  input Boolean logX;
  input Boolean logY;
  input String xLabel;
  input String yLabel;
  input Boolean points;
  input String xRange;
  input String yRange;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inValue2,inStringLst3,inString4, interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange)
    local
      String datasets,str,filename,timevar,message, interpolation2, title2, xLabel2, yLabel2, xRange2, yRange2, oldBuf;
      Boolean legend2, logX2, logY2, grid2, points2;
      Value time;
      list<Value> rest;
      list<String> varnames;
    case (Values.ARRAY(valueLst = (time :: rest)),(timevar :: varnames),message, interpolation2, title2, legend2, grid2, logX2, logY2, xLabel2, yLabel2, points2, xRange2, yRange2) /* filename values Variable names message string */
      equation
        oldBuf = Print.getString();
        Print.clearBuf();

        Print.printBuf("#Ptolemy Plot generated by OpenModelica\nTitleText: ");
        Print.printBuf(message);
        Print.printBuf("\n");
        unparsePtolemyValues(time, rest, varnames);
        
        str = Print.getString();
        Print.clearBuf();
        Print.printBuf(oldBuf);

        System.sendData(str, interpolation2, title2, legend2, grid2, logX2, logY2, xLabel2, yLabel2, points2, xRange2 +& " " +& yRange2);
      then
        0;
  end matchcontinue;
end sendPtolemyplotDataset;

public function sendPtolemyplotDataset2 "function: sendPtolemyplotDataset2
  This function writes a data set in the pltolemy plot format to a file.
  The first column of the dataset matrix should be the time variable.
  The message string will be displayed in the plot window of ptplot."
  input Value inValue2;
  input list<String> inStringLst3;
  input String visInfo;
  input String inString4;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inValue2,inStringLst3,visInfo,inString4)
    local
      String datasets,str,filename,timevar,info,message,oldBuf;
      Value time;
      list<Value> rest;
      list<String> varnames;
    case (Values.ARRAY(valueLst = (time :: rest)),(timevar :: varnames),info,message) /* filename values Variable names message string */
      equation
        oldBuf = Print.getString();
        Print.clearBuf();

        Print.printBuf("#Ptolemy Plot generated by OpenModelica\nTitleText: ");
        Print.printBuf(message);
        Print.printBuf("\n");
        unparsePtolemyValues(time, rest, varnames);
        
        str = Print.getString();
        Print.clearBuf();
        Print.printBuf(oldBuf);

        System.sendData2(info, str);
      then
        0;
  end matchcontinue;
end sendPtolemyplotDataset2;

protected function unparsePtolemyValues "function: unparsePtolemyValues
  Helper function to writePtolemyplotDataset."
  input Value inValue;
  input list<Value> inValueLst;
  input list<String> inStringLst;
algorithm
  outString := matchcontinue (inValue,inValueLst,inStringLst)
    local
      String str,str2,res,v1;
      Value time,s1;
      list<Value> xs;
      list<String> vs;

    case (_,{},_) then ();
    case (time,(s1 :: xs),(v1 :: vs))
      equation
        unparsePtolemySet(time, s1, v1);
        unparsePtolemyValues(time, xs, vs);
      then
        ();
  end matchcontinue;
end unparsePtolemyValues;

protected function unparsePtolemySet "function: unparsePtolemySet
  Helper function to unparsePtolemyValues."
  input Value v1;
  input Value v2;
  input String varname;
algorithm
  Print.printBuf(Util.stringAppendList({"DataSet: ",varname,"\n"}));
  unparsePtolemySet2(v1, v2);
end unparsePtolemySet;

protected function unparsePtolemySet2 "function: unparsePtolemySet2
  Helper function to unparsePtolemySet"
  input Value inValue1;
  input Value inValue2;
algorithm
  outString := matchcontinue (inValue1,inValue2)
    local
      String s1,s2,res,res_1;
      Value v1,v2;
      list<Value> v1s,v2s;
      list<Integer> dims1,dims2;

    case (Values.ARRAY(valueLst = {}),Values.ARRAY(valueLst = {})) then ();
    // adrpo: ignore dimenstions here as we're just printing! otherwise it fails.
    //        TODO! FIXME! see why the dimension list is wrong!
    case (Values.ARRAY(valueLst = (v1 :: v1s), dimLst = _),Values.ARRAY(valueLst = (v2 :: v2s), dimLst = _))
      equation
        valString2(v1);
        Print.printBuf(",");
        valString2(v2);
        Print.printBuf("\n");
        unparsePtolemySet2(Values.ARRAY(v1s,{}), Values.ARRAY(v2s,{}));
      then
        ();
    case (v1, v2)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- ValuesUtil.unparsePtolemySet2 failed on v1: " +&
          printValStr(v1) +& " and v2: " +& printValStr(v1));
      then
        fail();
  end matchcontinue;
end unparsePtolemySet2;

public function reverseMatrix "function: reverseMatrix
  Reverses each line and each row of a matrix.
  Implementation reverses all dimensions..."
  input Value inValue;
  output Value outValue;
algorithm
  outValue := matchcontinue (inValue)
    local
      list<Value> lst_1,lst_2,lst;
      Value value;
      list<Integer> dims;
    case (Values.ARRAY(valueLst = lst, dimLst = dims))
      equation
        lst_1 = Util.listMap(lst, reverseMatrix);
        lst_2 = listReverse(lst_1);
      then
        Values.ARRAY(lst_2,dims);
    case (value) then value;
  end matchcontinue;
end reverseMatrix;

public function printVal "function: printVal
  This function prints a value."
  input Value v;
  String s;
algorithm
  s := valString(v);
  Print.printBuf(s);
end printVal;

public function printValStr "
more correct naming then valString"
  input Value v;
  output String s;
algorithm
  s := valString(v);
end printValStr;

public function nthnthArrayelt "function: nthArrayelt
  author: BZ

  Return the nth nth....nth value of an array, indexed from 1..n
"
  input list<Value> inLst;
  input Value inValue;
  input Value lastValue;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inLst, inValue,lastValue)
    local
      Integer n_1,n;
      Value res,preRes;
      list<Value> vlst,vlst2;
      case({},_, preRes) then preRes;

    case (((res as Values.INTEGER(integer=n))::vlst2),Values.ARRAY(valueLst = vlst),preRes)
      equation
        n_1 = n - 1;
        res = listNth(vlst, n_1);
        res = nthnthArrayelt(vlst2,res,res);
      then
        res;
    case(_,_,_) then fail();
  end matchcontinue;
end nthnthArrayelt;

end ValuesUtil;
