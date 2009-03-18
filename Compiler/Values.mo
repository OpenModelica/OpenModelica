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

package Values
" file:        Values.mo
  package:     Values
  description: Evaluated expression values
 
  RCS: $Id$
  
  The package Values contains data structures for representing
  constant Modelica values.  These include integer, real, string and
  boolean values, and also arrays of any dimensionality and type.
  Multidimensional arrays are represented as arrays of arrays.
 
  The code is excluded from the report, since they convey no
  semantic information."

public import Exp;
public import Absyn;

public 
uniontype Value 
  record INTEGER
    Integer integer;
  end INTEGER;

  record REAL
    Real real;
  end REAL;

  record STRING
    String string;
  end STRING;

  record BOOL
    Boolean boolean;
  end BOOL;

  record ENUM
    Exp.ComponentRef value;
  end ENUM;

  record ARRAY
    list<Value> valueLst;
  end ARRAY;

  record LIST "MetaModelica list"
    list<Value> valueLst;
  end LIST;

  record TUPLE
    list<Value> valueLst;
  end TUPLE;

  record RECORD
    Absyn.Path record_ "record name" ;
    list<Value> orderd "orderd set of values" ;
    list<Exp.Ident> comp "comp names for each value" ;
  end RECORD;

  record CODE
    Absyn.CodeNode A "A record consist of value  Ident pairs" ;
  end CODE;

end Value;

protected import Print;
protected import System;
protected import Util;
protected import Dump;
protected import Error;

public function typeConvert "function: typeConvert
 
  Apply type conversion on a list of Values
"
  input Exp.Type inType1;
  input Exp.Type inType2;
  input list<Value> inValueLst3;
  output list<Value> outValueLst;
algorithm 
  outValueLst:=
  matchcontinue (inType1,inType2,inValueLst3)
    local
      list<Value> vallst,vrest,vallst2,vals;
      Real rval,r;
      Exp.Type from,to;
      Integer i,ival;
    case (_,_,{}) then {}; 
    case ((from as Exp.INT()),(to as Exp.REAL()),(INTEGER(integer = i) :: vrest))
      equation 
        vallst = typeConvert(from, to, vrest);
        rval = intReal(i);
      then
        (REAL(rval) :: vallst);
    case ((from as Exp.REAL()),(to as Exp.INT()),(REAL(real = r) :: vrest))
      equation 
        vallst = typeConvert(from, to, vrest);
        ival = realInt(r);
      then
        (INTEGER(ival) :: vallst);
    case (from,to,(ARRAY(valueLst = vals) :: vrest))
      equation 
        vallst = typeConvert(from, to, vals);
        vallst2 = typeConvert(from, to, vrest);
      then
        (ARRAY(vallst) :: vallst2);
  end matchcontinue;
end typeConvert;

public function isZero "Returns true if value is zero"
  input Value inValue;
  output Boolean isZero;
algorithm
  isZero := matchcontinue(inValue)
  local Real rval; Integer ival;
    case(REAL(rval)) equation
      isZero = rval ==. 0.0;
      then isZero;
    case(INTEGER(ival)) equation
      isZero = ival == 0;
      then isZero;
    case(_) then false;
  end matchcontinue;
end isZero;


public function isArray "function: isArray
 
  Return true if Value is an array.
"
  input Value inValue;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inValue)
    case (INTEGER(integer = _)) then false; 
    case (REAL(real = _)) then false; 
    case (STRING(string = _)) then false; 
    case (BOOL(boolean = _)) then false; 
    case (TUPLE(valueLst = _)) then false; 
    case (ARRAY(valueLst = _)) then true; 
    case (LIST(_)) then false; //MetaModelica list
  end matchcontinue;
end isArray;

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
    case (ARRAY(valueLst = vlst),n)
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
    case ((TUPLE(valueLst = lst) :: xs))
      equation 
        s1 = unparseValueNumbers(lst);
        s2 = unparseValueNumbers(xs);
        res = stringAppend(s1, s2);
      then
        res;
    case ((ARRAY(valueLst = lst) :: xs))
      equation 
        s1 = unparseValueNumbers(lst);
        s2 = unparseValueNumbers(xs);
        res = stringAppend(s1, s2);
      then
        res;
    case ((INTEGER(integer = i) :: xs))
      equation 
        s1 = unparseValueNumbers(xs);
        istr = intString(i);
        s2 = stringAppend(istr, " ");
        res = stringAppend(s2, s1);
      then
        res;
    case ((REAL(real = i) :: xs))
      local Real i;
      equation 
        s1 = unparseValueNumbers(xs);
        istr = realString(i);
        s2 = stringAppend(istr, " ");
        res = stringAppend(s2, s1);
      then
        res;
    case ((STRING(string = sval) :: xs))
      equation 
        s1 = unparseValueNumbers(xs);
        s2 = stringAppend(sval, " ");
        res = stringAppend(s2, s1);
      then
        res;
    case ({}) then ""; 
  end matchcontinue;
end unparseValueNumbers;


public uniontype IntRealOp
  record MULOP end MULOP;
  record DIVOP end DIVOP;
  record ADDOP end ADDOP;
  record SUBOP end SUBOP;
  record POWOP end POWOP;
  record LESSEQOP end LESSEQOP;
end IntRealOp;
 
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
  outv :=
  	matchcontinue(val1, val2, op)
  		local
  		  Real rv1,rv2,rv3;
  		  Integer iv1, iv2,iv3;
  		  Exp.Exp e;
  		  //MUL
  		  case (INTEGER(iv1),INTEGER(iv2), MULOP)
  		    equation
  		      e = Exp.safeIntOp(iv1,iv2,Exp.MULOP);
  		      outv = expValue(e);
  		  then 
  		    	outv;  		  
  		  case (REAL(rv1),INTEGER(iv2), MULOP)
  		    equation
  		      rv2 = intReal(iv2);
  		      rv3 = rv1 *. rv2;
  		  then 
  		    	REAL(rv3);  
  		  case (INTEGER(iv1), REAL(rv2), MULOP)
  		    equation
  		      rv1 = intReal(iv1);
  		      rv3 = rv1 *. rv2;
  		  then 
  		    	REAL(rv3);  
  		  case (REAL(rv1), REAL(rv2), MULOP)
  		    equation
  		      rv3 = rv1 *. rv2;
  		  then 
  		    	REAL(rv3);    		    			  
  		  //DIV 
  		  case (INTEGER(iv1),INTEGER(iv2), DIVOP)
  		    equation
  		      e = Exp.safeIntOp(iv1,iv2,Exp.DIVOP);
  		      outv = expValue(e);
  		  then 
  		    	outv;  		  
  		  case (REAL(rv1),INTEGER(iv2), DIVOP)
  		    equation
  		      rv2 = intReal(iv2);
  		      rv3 = rv1 /. rv2;
  		  then 
  		    	REAL(rv3);  
  		  case (INTEGER(iv1), REAL(rv2), DIVOP)
  		    equation
  		      rv1 = intReal(iv1);
  		      rv3 = rv1 /. rv2;
  		  then 
  		    	REAL(rv3);  
  		  case (REAL(rv1), REAL(rv2), DIVOP)
  		    equation
  		      rv3 = rv1 /. rv2;
  		  then 
  		    	REAL(rv3);    		    			  
  		  //POW
  		   case (INTEGER(iv1),INTEGER(iv2), POWOP) // this means indirect that we are dealing with decimal numbers (a^(-b)) = 1/a^b
  		    equation
  		      true = (iv2 < 0);
  		      rv1 = intReal(iv1);
  		      rv2 = intReal(iv2);
  		      rv3 = realPow(rv1, rv2);
  		  then 
  		    	REAL(rv3); 
  		  case (INTEGER(iv1),INTEGER(iv2), POWOP)
  		    equation
  		      e = Exp.safeIntOp(iv1,iv2,Exp.POWOP);
  		      outv = expValue(e);
  		  then 
  		    	outv;  		  
  		  case (REAL(rv1),INTEGER(iv2), POWOP)
  		    equation
  		      rv2 = intReal(iv2);
  		      rv3 = realPow(rv1, rv2);
  		  then 
  		    	REAL(rv3);  
  		  case (INTEGER(iv1), REAL(rv2), POWOP)
  		    equation
  		      iv2 = realInt(rv2);
  		      e = Exp.safeIntOp(iv1,iv2,Exp.POWOP);
  		      outv = expValue(e);
  		  then 
						outv;   
  		  case (INTEGER(iv1), REAL(rv2), POWOP)
  		    equation
  		      rv1 = intReal(iv1);
  		      rv3 = realPow(rv1, rv2);
  		  then 
  		    	REAL(rv3);  
  		  case (REAL(rv1), REAL(rv2), POWOP)
  		    equation
  		      rv3 = realPow(rv1, rv2);
  		  then 
  		    	REAL(rv3);    		    			  
  		  //ADD
  		  case (INTEGER(iv1),INTEGER(iv2), ADDOP)
  		    equation
  		      e = Exp.safeIntOp(iv1,iv2,Exp.ADDOP);
  		      outv = expValue(e);
  		  then 
  		    	outv;  		  
  		  case (REAL(rv1),INTEGER(iv2), ADDOP)
  		    equation
  		      rv2 = intReal(iv2);
  		      rv3 = rv1 +. rv2;
  		  then 
  		    	REAL(rv3);  
  		  case (INTEGER(iv1), REAL(rv2), ADDOP)
  		    equation
  		      rv1 = intReal(iv1);
  		      rv3 = rv1 +. rv2;
  		  then 
  		    	REAL(rv3);  
  		  case (REAL(rv1), REAL(rv2), ADDOP)
  		    equation
  		      rv3 = rv1 +. rv2;
  		  then 
  		    	REAL(rv3);    		    			  
  		  //SUB
  		  case (INTEGER(iv1),INTEGER(iv2), SUBOP)
  		    equation
  		      e = Exp.safeIntOp(iv1,iv2,Exp.SUBOP);
  		      outv = expValue(e);
  		  then 
  		    	outv;  		  
  		  case (REAL(rv1),INTEGER(iv2), SUBOP)
  		    equation
  		      rv2 = intReal(iv2);
  		      rv3 = rv1 -. rv2;
  		  then 
  		    	REAL(rv3);  
  		  case (INTEGER(iv1), REAL(rv2), SUBOP)
  		    equation
  		      rv1 = intReal(iv1);
  		      rv3 = rv1 -. rv2;
  		  then 
  		    	REAL(rv3);  
  		  case (REAL(rv1), REAL(rv2), SUBOP)
  		    equation
  		      rv3 = rv1 -. rv2;
  		  then 
  		    	REAL(rv3);    		    			  
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
  		  case (INTEGER(iv1),INTEGER(iv2))
  		    equation
  		      outv = (iv1 <= iv2);
  		  then 
  		    	outv;  		  
  		  case (REAL(rv1),INTEGER(iv2))
  		    equation
  		      rv2 = intReal(iv2);
  		      outv = (rv1 <=. rv2);
  		  then 
  		    	outv;  
  		  case (INTEGER(iv1), REAL(rv2))
  		    equation
  		      rv1 = intReal(iv1);
  		      outv = (rv1 <=. rv2);
  		  then 
  		    	outv;  
  		  case (REAL(rv1), REAL(rv2))
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
    case ((INTEGER(integer = _) :: xs))
      equation 
        s1 = unparseDescription(xs);
        str = stringAppend("# i!\n", s1);
      then
        str;
    case ((REAL(real = _) :: xs))
      equation 
        s1 = unparseDescription(xs);
        str = stringAppend("# r!\n", s1);
      then
        str;
    case ((STRING(string = sval) :: xs))
      equation 
        s1 = unparseDescription(xs);
        slen = stringLength(sval);
        slenstr = intString(slen);
        str = Util.stringAppendList({"# s! 1 ",slenstr,"\n"});
      then
        str;
    case ((ARRAY(valueLst = vallst) :: xs))
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
    case ((ARRAY(valueLst = elts) :: _))
      equation 
        res = unparsePrimType(elts);
      then
        res;
    case ((INTEGER(integer = _) :: _)) then "i"; 
    case ((REAL(real = _) :: _)) then "r"; 
    case ((STRING(string = _) :: _)) then "s"; 
    case ((BOOL(boolean = _) :: _)) then "b"; 
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
    case ((ARRAY(valueLst = vals) :: _))
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
    case ((lst as (ARRAY(valueLst = vals) :: _)))
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
    case ((ARRAY(valueLst = v1lst) :: rest1),(ARRAY(valueLst = v2lst) :: rest2))
      equation 
        reslst = addElementwiseArrayelt(v1lst, v2lst);
        res2 = addElementwiseArrayelt(rest1, rest2);
      then
        (ARRAY(reslst) :: res2);
    case ((INTEGER(integer = v1) :: rest1),(INTEGER(integer = v2) :: rest2))
      equation 
        res = v1 + v2;
        res2 = addElementwiseArrayelt(rest1, rest2);
      then
        (INTEGER(res) :: res2);
    case ((REAL(real = v1) :: rest1),(REAL(real = v2) :: rest2))
      local Real res,v1,v2;
      equation 
        res = v1 +. v2;
        res2 = addElementwiseArrayelt(rest1, rest2);
      then
        (REAL(res) :: res2);
    case ((STRING(string = v1) :: rest1),(STRING(string = v2) :: rest2))
      local String res,v1,v2;
      equation 
        res = stringAppend(v1, v2);
        res2 = addElementwiseArrayelt(rest1, rest2) "Addition of strings is string concatenation" ;
      then
        (STRING(res) :: res2);
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
    case ((ARRAY(valueLst = v1lst) :: rest1),(ARRAY(valueLst = v2lst) :: rest2))
      equation 
        reslst = subElementwiseArrayelt(v1lst, v2lst);
        res2 = subElementwiseArrayelt(rest1, rest2);
      then
        (ARRAY(reslst) :: res2);
    case ((INTEGER(integer = v1) :: rest1),(INTEGER(integer = v2) :: rest2))
      equation 
        res = v1 - v2;
        res2 = subElementwiseArrayelt(rest1, rest2);
      then
        (INTEGER(res) :: res2);
    case ((REAL(real = v1) :: rest1),(REAL(real = v2) :: rest2))
      local Real res,v1,v2;
      equation 
        res = v1 -. v2;
        res2 = subElementwiseArrayelt(rest1, rest2);
      then
        (REAL(res) :: res2);
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
    case ((ARRAY(valueLst = v1lst) :: rest1),(ARRAY(valueLst = v2lst) :: rest2))
      equation 
        reslst = mulElementwiseArrayelt(v1lst, v2lst);
        res2 = mulElementwiseArrayelt(rest1, rest2);
      then
        (ARRAY(reslst) :: res2);
    case ((INTEGER(integer = v1) :: rest1),(INTEGER(integer = v2) :: rest2))
      equation 
        res = v1 * v2;
        res2 = mulElementwiseArrayelt(rest1, rest2);
      then
        (INTEGER(res) :: res2);
    case ((REAL(real = v1) :: rest1),(REAL(real = v2) :: rest2))
      local Real res,v1,v2;
      equation 
        res = v1 *. v2;
        res2 = mulElementwiseArrayelt(rest1, rest2);
      then
        (REAL(res) :: res2);
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
    case ((ARRAY(valueLst = v1lst) :: rest1),(ARRAY(valueLst = v2lst) :: rest2))
      equation 
        reslst = divElementwiseArrayelt(v1lst, v2lst);
        res2 = divElementwiseArrayelt(rest1, rest2);
      then
        (ARRAY(reslst) :: res2);
    case ((INTEGER(integer = v1) :: rest1),(INTEGER(integer = v2) :: rest2))
      local Real v1_1,v2_1;
      equation 
        v1_1=intReal(v1);
        v2_1=intReal(v2);
        res = v1_1 /. v2_1;
        res2 = divElementwiseArrayelt(rest1, rest2);
      then
        (REAL(res) :: res2);
    case ((REAL(real = v1) :: rest1),(REAL(real = v2) :: rest2))
      local Real res,v1,v2;
      equation 
        res = v1 /. v2;
        res2 = divElementwiseArrayelt(rest1, rest2);
      then
        (REAL(res) :: res2);
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
    case ((ARRAY(valueLst = v1lst) :: rest1),(ARRAY(valueLst = v2lst) :: rest2))
      equation 
        reslst = powElementwiseArrayelt(v1lst, v2lst);
        res2 = powElementwiseArrayelt(rest1, rest2);
      then
        (ARRAY(reslst) :: res2);
    case ((INTEGER(integer = v1) :: rest1),(INTEGER(integer = v2) :: rest2))
      local Real v1_1,v2_1;
      equation 
        v1_1=intReal(v1);
        v2_1=intReal(v2);
        res = v1_1 ^. v2_1;
        res2 = powElementwiseArrayelt(rest1, rest2);
      then
        (REAL(res) :: res2);
    case ((REAL(real = v1) :: rest1),(REAL(real = v2) :: rest2))
      local Real res,v1,v2;
      equation 
        res = v1 ^. v2;
        res2 = powElementwiseArrayelt(rest1, rest2);
      then
        (REAL(res) :: res2);
    case ({},{}) then {}; 
  end matchcontinue;
end powElementwiseArrayelt;

public function expValue "function: expValue
 
  Returns the value of constant expressions in Exp.Exp
"
  input Exp.Exp inExp;
  output Value outValue;
algorithm 
  outValue:=
  matchcontinue (inExp)
    local Integer i;
    case Exp.ICONST(integer = i) then INTEGER(i); 
    case Exp.RCONST(real = i)
      local Real i;
      then
        REAL(i);
    case Exp.SCONST(string = i)
      local String i;
      then
        STRING(i);
    case Exp.BCONST(bool = i)
      local Boolean i;
      then
        BOOL(i);
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
    case (REAL(real = r)) then r; 
    case (INTEGER(integer = i))
      equation 
        r = intReal(i);
      then
        r;
  end matchcontinue;
end valueReal;

public function valueBool "function: valueReal
Author: BZ, 2008-09
  Return the bool value of a Value. 
"
  input Value inValue;
  output Boolean outBool;
algorithm outReal:= matchcontinue (inValue)
    case (BOOL(outBool)) then outBool; 
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
    case (REAL(real = r)::rest) 
      equation
        res = valueReals(rest); 
       then
         r::res;
    case (INTEGER(integer = i)::rest)
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
    case (REAL(real = r))
      equation 
        r_1 = -.r;
      then
        REAL(r_1);
    case (INTEGER(integer = i))
      equation 
        i_1 = -i;
      then
        INTEGER(i_1);
    case ARRAY(valueLst = vlst)
      equation 
        vlst_1 = Util.listMap(vlst, valueNeg);
      then
        ARRAY(vlst);
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
    case ({INTEGER(integer = v1)}) then INTEGER(v1); 
    case ({REAL(real = v1)})
      local Real v1;
      then
        REAL(v1);
    case ({ARRAY(valueLst = v1)})
      local list<Value> v1;
      then
        ARRAY(v1);
    case ((INTEGER(integer = v2) :: xs))
      equation 
        INTEGER(v1) = sumArrayelt(xs);
        v3 = v1 + v2;
      then
        INTEGER(v3);
    case ((REAL(real = v2) :: xs))
      local Real v1,v3,v2;
      equation 
        REAL(v1) = sumArrayelt(xs);
        v3 = v1 +. v2;
      then
        REAL(v3);
    case ((arr as (ARRAY(valueLst = v2) :: _)))
      local list<Value> v1,v3,v2;
      equation 
        ARRAY(v1) = sumArrayelt(arr);
        v3 = addElementwiseArrayelt(v1, v2);
      then
        ARRAY(v3);
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
    case (sval,(ARRAY(valueLst = vals) :: rest))
      equation 
        r1 = multScalarArrayelt(sval, vals);
        r2 = multScalarArrayelt(sval, rest);
      then
        (ARRAY(r1) :: r2);
    case ((sval as INTEGER(integer = v1)),(INTEGER(integer = v2) :: rest))
      local Integer r1;
      equation 
        r1 = v1*v2;
        r2 = multScalarArrayelt(sval, rest);
      then
        (INTEGER(r1) :: r2);
    case ((sval as REAL(real = v1)),(INTEGER(integer = v2) :: rest))
      local Real r1,v1;
      equation 
        v2_1 = intReal(v2);
        r1 = v1*.v2_1;
        r2 = multScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as INTEGER(integer = v1)),(REAL(real = v2) :: rest))
      local Real r1,v2;
      equation 
        v1_1 = intReal(v1);
        r1 = v1_1*.v2;
        r2 = multScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as REAL(real = v1)),(REAL(real = v2) :: rest))
      local Real r1,v1,v2;
      equation 
        r1 = v1*.v2;
        r2 = multScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
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
    case (sval,(ARRAY(valueLst = vals) :: rest))
      equation 
        r1 = addScalarArrayelt(sval, vals);
        r2 = addScalarArrayelt(sval, rest);
      then
        (ARRAY(r1) :: r2);
    case ((sval as INTEGER(integer = v1)),(INTEGER(integer = v2) :: rest))
      local Integer r1;
      equation 
        r1 = v1+v2;
        r2 = addScalarArrayelt(sval, rest);
      then
        (INTEGER(r1) :: r2);
    case ((sval as REAL(real = v1)),(INTEGER(integer = v2) :: rest))
      local Real r1,v1;
      equation 
        v2_1 = intReal(v2);
        r1 = v1+.v2_1;
        r2 = addScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as INTEGER(integer = v1)),(REAL(real = v2) :: rest))
      local Real r1,v2;
      equation 
        v1_1 = intReal(v1);
        r1 = v1_1+.v2;
        r2 = addScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as REAL(real = v1)),(REAL(real = v2) :: rest))
      local Real r1,v1,v2;
      equation 
        r1 = v1+.v2;
        r2 = addScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as STRING(string = v1)),(STRING(string = v2) :: rest))
      local String r1,v1,v2;
      equation 
        r1 = v1+&v2;
        r2 = addScalarArrayelt(sval, rest);
      then
        (STRING(r1) :: r2);
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
    case (sval,(ARRAY(valueLst = vals) :: rest))
      equation 
        r1 = divScalarArrayelt(sval, vals);
        r2 = divScalarArrayelt(sval, rest);
      then
        (ARRAY(r1) :: r2);
    case (sval ,(INTEGER(integer = v2) :: rest))
      equation 
        equality(v2 = 0);
        s2 = valString(sval);
        Error.addMessage(Error.DIVISION_BY_ZERO, {"0",s2});
      then
        fail();
    case (sval ,(REAL(real = v2_1) :: rest))
      equation 
        equality(v2_1 = 0.0);
        s2 = valString(sval);
        Error.addMessage(Error.DIVISION_BY_ZERO, {"0.0",s2});
      then
        fail();
    case ((sval as INTEGER(integer = v1)),(INTEGER(integer = v2) :: rest))
      local Real r1;
      equation
        v1_1=intReal(v1);
        v2_1=intReal(v2); 
        r1 = v1_1/.v2_1;
        r2 = divScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as REAL(real = v1)),(INTEGER(integer = v2) :: rest))
      local Real r1,v1;
      equation 
        v2_1 = intReal(v2);
        r1 = v1/.v2_1;
        r2 = divScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as INTEGER(integer = v1)),(REAL(real = v2) :: rest))
      local Real r1,v2;
      equation 
        v1_1 = intReal(v1);
        r1 = v1_1/.v2;
        r2 = divScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as REAL(real = v1)),(REAL(real = v2) :: rest))
      local Real r1,v1,v2;
      equation 
        r1 = v1/.v2;
        r2 = divScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
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
    case (sval,(ARRAY(valueLst = vals) :: rest))
      equation 
        r1 = subScalarArrayelt(sval, vals);
        r2 = subScalarArrayelt(sval, rest);
      then
        (ARRAY(r1) :: r2);
    case ((sval as INTEGER(integer = v1)),(INTEGER(integer = v2) :: rest))
      local Integer r1;
      equation 
        r1 = v1-v2;
        r2 = subScalarArrayelt(sval, rest);
      then
        (INTEGER(r1) :: r2);
    case ((sval as REAL(real = v1)),(INTEGER(integer = v2) :: rest))
      local Real r1,v1;
      equation 
        v2_1 = intReal(v2);
        r1 = v1-.v2_1;
        r2 = subScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as INTEGER(integer = v1)),(REAL(real = v2) :: rest))
      local Real r1,v2;
      equation 
        v1_1 = intReal(v1);
        r1 = v1_1-.v2;
        r2 = subScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as REAL(real = v1)),(REAL(real = v2) :: rest))
      local Real r1,v1,v2;
      equation 
        r1 = v1-.v2;
        r2 = subScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
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
    case (sval,(ARRAY(valueLst = vals) :: rest))
      equation 
        r1 = powScalarArrayelt(sval, vals);
        r2 = powScalarArrayelt(sval, rest);
      then
        (ARRAY(r1) :: r2);
    case ((sval as INTEGER(integer = v1)),(INTEGER(integer = v2) :: rest))
      local Real r1;
      equation
        v1_1=intReal(v1);
        v2_1=intReal(v2); 
        r1 = v1_1^.v2_1;
        r2 = powScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as REAL(real = v1)),(INTEGER(integer = v2) :: rest))
      local Real r1,v1;
      equation 
        v2_1 = intReal(v2);
        r1 = v1^.v2_1;
        r2 = powScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as INTEGER(integer = v1)),(REAL(real = v2) :: rest))
      local Real r1,v2;
      equation 
        v1_1 = intReal(v1);
        r1 = v1_1^.v2;
        r2 = powScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as REAL(real = v1)),(REAL(real = v2) :: rest))
      local Real r1,v1,v2;
      equation 
        r1 = v1^.v2;
        r2 = powScalarArrayelt(sval, rest);
      then
        (REAL(r1) :: r2);
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
    case (sval,(ARRAY(valueLst = vals) :: rest))
      equation 
        r1 = subArrayeltScalar(sval, vals);
        r2 = subArrayeltScalar(sval, rest);
      then
        (ARRAY(r1) :: r2);
    case ((sval as INTEGER(integer = v1)),(INTEGER(integer = v2) :: rest))
      local Integer r1;
      equation 
        r1 = v2-v1;
        r2 = subArrayeltScalar(sval, rest);
      then
        (INTEGER(r1) :: r2);
    case ((sval as REAL(real = v1)),(INTEGER(integer = v2) :: rest))
      local Real r1,v1;
      equation 
        v2_1 = intReal(v2);
        r1 = v2_1-.v1;
        r2 = subArrayeltScalar(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as INTEGER(integer = v1)),(REAL(real = v2) :: rest))
      local Real r1,v2;
      equation 
        v1_1 = intReal(v1);
        r1 = v2-.v1_1;
        r2 = subArrayeltScalar(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as REAL(real = v1)),(REAL(real = v2) :: rest))
      local Real r1,v1,v2;
      equation 
        r1 = v2-.v1;
        r2 = subArrayeltScalar(sval, rest);
      then
        (REAL(r1) :: r2);
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
    case (sval,(ARRAY(valueLst = vals) :: rest))
      equation 
        r1 = powArrayeltScalar(sval, vals);
        r2 = powArrayeltScalar(sval, rest);
      then
        (ARRAY(r1) :: r2);
    case ((sval as INTEGER(integer = v1)),(INTEGER(integer = v2) :: rest))
      local Real r1;
      equation
        v1_1=intReal(v1);
        v2_1=intReal(v2); 
        r1 = v2_1^.v1_1;
        r2 = powArrayeltScalar(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as REAL(real = v1)),(INTEGER(integer = v2) :: rest))
      local Real r1,v1;
      equation 
        v2_1 = intReal(v2);
        r1 = v2_1^.v1;
        r2 = powArrayeltScalar(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as INTEGER(integer = v1)),(REAL(real = v2) :: rest))
      local Real r1,v2;
      equation 
        v1_1 = intReal(v1);
        r1 = v2^.v1_1;
        r2 = powArrayeltScalar(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as REAL(real = v1)),(REAL(real = v2) :: rest))
      local Real r1,v1,v2;
      equation 
        r1 = v2^.v1;
        r2 = powArrayeltScalar(sval, rest);
      then
        (REAL(r1) :: r2);
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
      Integer r1,r2,res,v1,v2,len,len2;
      list<Value> v1lst,v2lst,vres,rest,vlst,col,mat_1,vals,mat,lst1,lst2;
      Value sres,v;
      String lenstr,len2str;
    case ((INTEGER(integer = v1) :: (v1lst as (_ :: _))),(INTEGER(integer = v2) :: (v2lst as (_ :: _))))
      equation 
        r1 = v1*v2;
        INTEGER(r2) = multScalarProduct(v1lst, v2lst);
        res = r1 + r2;
      then
        INTEGER(res);
    case ({INTEGER(integer = v1)},{INTEGER(integer = v2)})
      equation 
        res = v1*v2;
      then
        INTEGER(res);
    case ((REAL(real = v1) :: (v1lst as (_ :: _))),(REAL(real = v2) :: (v2lst as (_ :: _))))
      local Real r1,r2,res,v1,v2;
      equation 
        r1 = v1*.v2;
        REAL(r2) = multScalarProduct(v1lst, v2lst);
        res = r1 +. r2;
      then
        REAL(res);
    case ({REAL(real = v1)},{REAL(real = v2)})
      local Real res,v1,v2;
      equation 
        res = v1*.v2;
      then
        REAL(res);
    case ((ARRAY(valueLst = v2lst) :: rest),(vlst as (INTEGER(integer = _) :: _)))
      equation 
        sres = multScalarProduct(v2lst, vlst);
        ARRAY(vres) = multScalarProduct(rest, vlst);
      then
        ARRAY((sres :: vres));
    case ({},(INTEGER(integer = _) :: _)) then ARRAY({}); 
    case ((ARRAY(valueLst = v2lst) :: rest),(vlst as (REAL(real = _) :: _)))
      equation 
        sres = multScalarProduct(v2lst, vlst);
        ARRAY(vres) = multScalarProduct(rest, vlst);
      then
        ARRAY((sres :: vres));
    case ({},(REAL(real = _) :: _)) then ARRAY({}); 
    case ((vlst as (INTEGER(integer = _) :: _)),(mat as (ARRAY(valueLst = (_ :: (_ :: _))) :: _)))
      equation 
        (ARRAY(col),mat_1) = matrixStripFirstColumn(mat);
        v = multScalarProduct(vlst, col);
        ARRAY(vals) = multScalarProduct(vlst, mat_1);
      then
        ARRAY((v :: vals));
    case ((vlst as (INTEGER(integer = _) :: _)),(mat as (ARRAY(valueLst = {_}) :: _)))
      local Integer v;
      equation 
        (ARRAY(col),mat_1) = matrixStripFirstColumn(mat);
        INTEGER(v) = multScalarProduct(vlst, col);
      then
        ARRAY({INTEGER(v)});
    case ((vlst as (REAL(real = _) :: _)),(mat as (ARRAY(valueLst = (_ :: (_ :: _))) :: _)))
      equation 
        (ARRAY(col),mat_1) = matrixStripFirstColumn(mat);
        v = multScalarProduct(vlst, col);
        ARRAY(vals) = multScalarProduct(vlst, mat_1);
      then
        ARRAY((v :: vals));
    case ((vlst as (REAL(real = _) :: _)),(mat as (ARRAY(valueLst = {_}) :: _)))
      local Real v;
      equation 
        (ARRAY(col),mat_1) = matrixStripFirstColumn(mat);
        REAL(v) = multScalarProduct(vlst, col);
      then
        ARRAY({REAL(v)});
    case (lst1,lst2)
      equation 
        Print.printBuf("mult_scalar_product failed\n lst1 len:");
        len = listLength(lst1);
        lenstr = intString(len);
        Print.printBuf(lenstr);
        Print.printBuf("lst2 len:");
        len2 = listLength(lst2);
        len2str = intString(len2);
        Print.printBuf(len2str);
        Print.printBuf("\n");
      then
        fail();
  end matchcontinue;
end multScalarProduct;

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
    case ((m1 as (ARRAY(valueLst = v1lst) :: rest1)),(m2 as (ARRAY(valueLst = _) :: _)))
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
    case ((sval as REAL(real = v1)),vlst)
      equation 
        equality(v1 = 0.0);
        s2 = unparseValues(vlst);
        Error.addMessage(Error.DIVISION_BY_ZERO, {"0.0",s2});
      then
        fail();
    case ((sval as INTEGER(integer = v1)),vlst)
      local Integer v1;
      equation 
        equality(v1 = 0);
        s2 = unparseValues(vlst);
        Error.addMessage(Error.DIVISION_BY_ZERO, {"0",s2});
      then
        fail();
    case (sval,(ARRAY(valueLst = vals) :: rest))
      equation 
        r1 = divArrayeltScalar(sval, vals);
        r2 = divArrayeltScalar(sval, rest);
      then
        (ARRAY(r1) :: r2);
    case ((sval as INTEGER(integer = v1)),(INTEGER(integer = v2) :: rest))
      local Integer r1,v1;
      equation 
        r1 = v2/v1;
        r2 = divArrayeltScalar(sval, rest);
      then
        (INTEGER(r1) :: r2);
    case ((sval as REAL(real = v1)),(INTEGER(integer = v2) :: rest))
      local Real r1;
      equation 
        v2_1 = intReal(v2);
        r1 = v2_1/.v1;
        r2 = divArrayeltScalar(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as INTEGER(integer = v1)),(REAL(real = v2) :: rest))
      local
        Real r1,v2;
        Integer v1;
      equation 
        v1_1 = intReal(v1);
        r1 = v2/.v1_1;
        r2 = divArrayeltScalar(sval, rest);
      then
        (REAL(r1) :: r2);
    case ((sval as REAL(real = v1)),(REAL(real = v2) :: rest))
      local Real r1,v2;
      equation 
        r1 = v2/.v1;
        r2 = divArrayeltScalar(sval, rest);
      then
        (REAL(r1) :: r2);
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
    case ((ARRAY(valueLst = (v1 :: vrest)) :: rest))
      equation 
        (ARRAY(resl),resl2) = matrixStripFirstColumn(rest);
      then
        (ARRAY((v1 :: resl)),(ARRAY(vrest) :: resl2));
    case ({}) then (ARRAY({}),{}); 
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
      Integer i;
      list<Integer> lst;
    case ({}) then ARRAY({}); 
    case ((i :: lst))
      equation 
        ARRAY(res) = intlistToValue(lst);
      then
        ARRAY((INTEGER(i) :: res));
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
    case (ARRAY(valueLst = v_lst)) then v_lst; 
  end matchcontinue;
end arrayValues;

public function makeReal "Creates a real value "
  input Real r;
  output Value v;
algorithm
  v := REAL(r);
end makeReal;

public function makeArray "function: makeArray
 
  Construct an array of a list of Values.
"
  input list<Value> inValueLst;
  output Value outValue;
algorithm 
  outValue:=
  matchcontinue (inValueLst)
    local list<Value> vlst;
    case (vlst) then ARRAY(vlst); 
  end matchcontinue;
end makeArray;

public function valString "function: valString
 
  This function returns a textual representation of a value.
"
  input Value inValue;
  output String outString;
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
      Exp.ComponentRef cr;
    case INTEGER(integer = n)
      equation 
        s = intString(n);
      then
        s;
    case REAL(real = x)
      equation 
        s = realString(x);
      then
        s;
    case STRING(string = s)
      equation 
        s_1 = Util.stringAppendList({"\"",s,"\""});
      then
        s_1;
    case BOOL(boolean = false) then "false"; 
    case BOOL(boolean = true) then "true"; 
    case ARRAY(valueLst = vs)
      equation 
        s = valListString(vs);
        s_1 = stringAppend("{", s);
        s_2 = stringAppend(s_1, "}");
      then
        s_2;
    case TUPLE(valueLst = vs)
      equation 
        s = valListString(vs);
        s_1 = stringAppend("(", s);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;
    case ((r as RECORD(record_ = recordPath)))
      local Absyn.Path recordPath; String recordName;
      equation
        recordName = Absyn.pathString(recordPath);
        s = valRecordString(r);
        res = Util.stringAppendList({"record ", recordName, "\n", s,"end ", recordName, ";"});
      then
        res;
        
    case (CODE(A = c))
      equation 
        res = Dump.printCodeStr(c);
        res_1 = Util.stringAppendList({"Code(",res,")"});
      then
        res_1;

        // MetaModelica list
    case LIST(valueLst = vs)
      equation
        s = valListString(vs);
        s_1 = stringAppend("{", s);
        s_2 = stringAppend(s_1, "}");
      then
        s_2;
    case(ENUM(cr)) equation
      s = "enumerationValue("+&Exp.printComponentRefStr(cr)+&")";
    then s;
    case _
      equation 
       print("- val_string failed\n");
      then
        fail();
  end matchcontinue;
end valString;



protected function valRecordString 
"function: valRecordString 
  This function returns a textual representation of a record,
 separating each value with a comma."
  input Value inValue;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inValue)
    local
      Absyn.Path cname;
      String s1,s2,res,id;
      Value x;
      list<Value> xs;
      list<String> ids;
    case (RECORD(record_ = cname,orderd = {},comp = {})) then ""; 
    case (RECORD(record_ = cname,orderd = (x :: (xs as (_ :: _))),comp = (id :: (ids as (_ :: _)))))
      equation 
        s1 = valString(x);
        s2 = valRecordString(RECORD(cname,xs,ids));
        res = Util.stringAppendList({"    ",id," = ",s1,",\n",s2});
      then
        res;
    case (RECORD(record_ = cname,orderd = (x :: xs),comp = (id :: ids)))
      equation 
        s1 = valString(x);
        s2 = valRecordString(RECORD(cname,xs,ids));
        res = Util.stringAppendList({"    ",id," = ",s1,"\n",s2});
      then
        res;
    case(RECORD(orderd=xs,comp=ids)) equation 
        /*print("-valRecordString failed. vals="+&Util.stringDelimitList(Util.listMap(xs,valString),",")
        +&" comps="+&Util.stringDelimitList(ids,",")+&"\n");*/ 
    then fail();
  end matchcontinue;
end valRecordString;

protected function valListString "function: valListString
 
  This function returns a textual representation of a list of
  values, separating each value with a comman.
"
  input list<Value> inValueLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inValueLst)
    local
      String s,s_1,s_2,s_3;
      Value v;
      list<Value> vs;
    case {} then ""; 
    case {v}
      equation 
        s = valString(v);
      then
        s;
    case (v :: vs)
      equation 
        s = valString(v);
        s_1 = valListString(vs);
        s_2 = stringAppend(s, ",");
        s_3 = stringAppend(s_2, s_1);
      then
        s_3;
    case _
      equation 
        Print.printBuf("- val_list_string failed\n");
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
      String datasets,str,filename,timevar,message;
      Value time;
      list<Value> rest;
      list<String> varnames;
    case (filename,ARRAY(valueLst = (time :: rest)),(timevar :: varnames),message) /* filename values Variable names message string */ 
      equation 
        datasets = unparsePtolemyValues(time, rest, varnames);
        str = Util.stringAppendList(
          {"#Ptolemy Plot generated by OpenModelica\n","TitleText: ",
          message,"\n",datasets});
        System.writeFile(filename, str);
      then
        0;
  end matchcontinue;
end writePtolemyplotDataset;

public function sendPtolemyplotDataset "function: sendPtolemyplotDataset

  This function writes a data set in the pltolemy plot format to a file.
  The first column of the dataset matrix should be the time variable.
  The message string will be displayed in the plot window of ptplot.
"
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
  outInteger:=
  matchcontinue (inValue2,inStringLst3,inString4, interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange)
    local
      String datasets,str,filename,timevar,message, interpolation2, title2, xLabel2, yLabel2, xRange2, yRange2;
      Boolean legend2, logX2, logY2, grid2, points2;
      Value time;
      list<Value> rest;
      list<String> varnames;
    case (ARRAY(valueLst = (time :: rest)),(timevar :: varnames),message, interpolation2, title2, legend2, grid2, logX2, logY2, xLabel2, yLabel2, points2, xRange2, yRange2) /* filename values Variable names message string */
      equation
        datasets = unparsePtolemyValues(time, rest, varnames);
        str = Util.stringAppendList(
          {"#Ptolemy Plot generated by OpenModelica\n","TitleText: ",
          message,"\n",datasets});

        System.sendData(str, interpolation2, title2, legend2, grid2, logX2, logY2, xLabel2, yLabel2, points2, xRange2 +& " " +& yRange2);
      then
        0;
  end matchcontinue;
end sendPtolemyplotDataset;
protected function unparsePtolemyValues "function: unparsePtolemyValues
 
  Helper function to write_ptolemyplot_dataset.
"
  input Value inValue;
  input list<Value> inValueLst;
  input list<String> inStringLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inValue,inValueLst,inStringLst)
    local
      String str,str2,res,v1;
      Value time,s1;
      list<Value> xs;
      list<String> vs;
    case (_,{},_) then ""; 
    case (time,(s1 :: xs),(v1 :: vs))
      equation 
        str = unparsePtolemySet(time, s1, v1);
        str2 = unparsePtolemyValues(time, xs, vs);
        res = stringAppend(str, str2);
      then
        res;
  end matchcontinue;
end unparsePtolemyValues;

protected function unparsePtolemySet "function: unparsePtolemySet
 
  Helper function to unparse_ptolemy_values.
"
  input Value v1;
  input Value v2;
  input String varname;
  output String res;
  String str;
algorithm 
  str := unparsePtolemySet2(v1, v2);
  res := Util.stringAppendList({"DataSet: ",varname,"\n",str});
end unparsePtolemySet;

protected function unparsePtolemySet2 "function: unparsePtolemySet2
  
  Helper function to unparse_ptolemy_set
"
  input Value inValue1;
  input Value inValue2;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inValue1,inValue2)
    local
      String s1,s2,res,res_1;
      Value v1,v2;
      list<Value> v1s,v2s;
    case (ARRAY(valueLst = {}),ARRAY(valueLst = {})) then ""; 
    case (ARRAY(valueLst = (v1 :: v1s)),ARRAY(valueLst = (v2 :: v2s)))
      equation 
        s1 = valString(v1);
        s2 = valString(v2);
        res = unparsePtolemySet2(ARRAY(v1s), ARRAY(v2s));
        res_1 = Util.stringAppendList({s1,",",s2,"\n",res});
      then
        res_1;
  end matchcontinue;
end unparsePtolemySet2;

public function reverseMatrix "function: reverseMatrix
  
  Reverses each line and each row of a matrix.
  Implementation reverses all dimensions...
"
  input Value inValue;
  output Value outValue;
algorithm 
  outValue:=
  matchcontinue (inValue)
    local
      list<Value> lst_1,lst_2,lst;
      Value value;
    case (ARRAY(valueLst = lst))
      equation 
        lst_1 = Util.listMap(lst, reverseMatrix);
        lst_2 = listReverse(lst_1);
      then
        ARRAY(lst_2);
    case (value) then value; 
  end matchcontinue;
end reverseMatrix;

public function printVal "function: printVal
 
  This function prints a value.
"
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

public function sendPtolemyplotDataset2 "function: sendPtolemyplotDataset2

  This function writes a data set in the pltolemy plot format to a file.
  The first column of the dataset matrix should be the time variable.
  The message string will be displayed in the plot window of ptplot.
"
  input Value inValue2;
  input list<String> inStringLst3;
  input String visInfo;
  input String inString4;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inValue2,inStringLst3,visInfo,inString4)
    local
      String datasets,str,filename,timevar,info,message;
      Value time;
      list<Value> rest;
      list<String> varnames;
    case (ARRAY(valueLst = (time :: rest)),(timevar :: varnames),info,message) /* filename values Variable names message string */
      equation
//        print("+++\n");
//  		  print(Util.stringAppendList(varnames));
//  			print("+++\n");
        datasets = unparsePtolemyValues(time, rest, varnames);
//        print("+++\n");
//  		  print(Util.stringAppendList(varnames));
//  			print("+++\n");

        str = Util.stringAppendList(
          {"#Ptolemy Plot generated by OpenModelica\n","TitleText: ",
          message,"\n",datasets});

				//print("till send:\n" +& str +& "\n");

        System.sendData2(info, str);
      then
        0;
  end matchcontinue;
end sendPtolemyplotDataset2;

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
        
    case (((res as INTEGER(integer=n))::vlst2),ARRAY(valueLst = vlst),preRes)
      equation 
        n_1 = n - 1;
        res = listNth(vlst, n_1);
        res = nthnthArrayelt(vlst2,res,res);
      then
        res;
    case(_,_,_) then fail();
  end matchcontinue;
end nthnthArrayelt;
end Values;

