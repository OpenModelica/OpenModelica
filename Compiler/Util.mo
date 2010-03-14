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

package Util
" file:	       Util.mo
  package:     Util
  description: Miscellanous MetaModelica Compiler (MMC) utilities

  RCS: $Id$

  This package contains various MetaModelica Compiler (MMC) utilities sigh, mostly
  related to lists.
  It is used pretty much everywhere. The difference between this
  module and the ModUtil module is that ModUtil contains modelica
  related utilities. The Util module only contains *low-level*
  MetaModelica Compiler (MMC) utilities, for example finding elements in lists.

  This modules contains many functions that use *type variables* in MetaModelica Compiler (MMC).
  A type variable is exactly what it sounds like, a type bound to a variable.
  It is used for higher order functions, i.e. in MetaModelica Compiler (MMC) the possibility to pass a
  \"pointer\" to a function into another function. But it can also be used for
  generic data types, like in  C++ templates.

  A type variable in MetaModelica Compiler (MMC) is written as:
  replaceable type TyVar subtypeof Any;
  For instance,
  function listFill
    replaceable type TyVar subtypeof Any;
  	input TyVar in;
  	input Integer i;
  	output list<TyVar>
  ...
  end listFill;
  the type variable TyVar is here used as a generic type for the function listFill,
  which returns a list of n elements of a certain type."

public uniontype ReplacePattern
  record REPLACEPATTERN
    String from "from string (ie \".\"" ;
    String to "to string (ie \"$p\") ))" ;
  end REPLACEPATTERN;
end ReplacePattern;


protected import System;
protected import Print;
protected import Debug;
protected import OptManager;
protected import DAELow;

protected constant list<ReplacePattern> replaceStringPatterns=
         {REPLACEPATTERN(".",DAELow.pointStr),
          REPLACEPATTERN("[",DAELow.leftBraketStr),REPLACEPATTERN("]",DAELow.rightBraketStr),
          REPLACEPATTERN("(",DAELow.leftParStr),REPLACEPATTERN(")",DAELow.rightParStr),
          REPLACEPATTERN(",",DAELow.commaStr)};


public function sort "sorts a list given an ordering function.

Uses the mergesort algorithm.
"
  input list<Type_a> lst;
  input greaterThanFunc greaterThan;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
  partial function greaterThanFunc
    input Type_a a;
    input Type_a b;
    output Boolean res;
  end greaterThanFunc;
algorithm
  outLst := matchcontinue(lst,greaterThan)
  local Type_a elt; Integer middle; list<Type_a> left,right;
    case({},_) then {};
    case ({elt},greaterThan) then {elt};
    case(lst,greaterThan) equation
      middle = listLength(lst) / 2;
      (left,right) = listSplit(lst,middle);
      left = sort(left,greaterThan);
      right = sort(right,greaterThan);
      outLst = merge(left,right,greaterThan);
   then outLst;
  end matchcontinue;
end sort;

public function isIntGreater "Author: BZ"
input Integer lhs;
input Integer rhs;
output Boolean b;
algorithm b := lhs>rhs;
end isIntGreater;

public function isRealGreater "Author: BZ"
input Real lhs;
input Real rhs;
output Boolean b;
algorithm b := lhs>.rhs;
end isRealGreater;

protected function merge "help function to sort, merges two sorted lists"
  input list<Type_a> left;
  input list<Type_a> right;
  input greaterThanFunc greaterThan;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
  partial function greaterThanFunc
    input Type_a a;
    input Type_a b;
    output Boolean res;
  end greaterThanFunc;
algorithm
  outLst := matchcontinue(left,right,greaterThan)
  local Type_a l,r;
    case({},{},greaterThan) then {};

    case(l::left,right as (r::_),greaterThan) equation
      true = greaterThan(r,l);
      outLst =  merge(left,right,greaterThan);
    then l::outLst;

    case(left as (l::_), r::right,greaterThan) equation
      false = greaterThan(r,l);
      outLst =  merge(left,right,greaterThan);
    then r::outLst;
    case({},right,greaterThan) then right;
    case(left,{},greaterThan) then left;
  end matchcontinue;
end merge;

public function linuxDotSlash "If operating system is Linux/Unix, return a './', otherwise return empty string"
  output String str;
algorithm
  str := matchcontinue()
    case() equation
      "linux" = System.os();
    then "./";
    case() then "";
  end matchcontinue;
end linuxDotSlash;


public function flagValue "function flagValue
  author: x02lucpo
  Extracts the flagvalue from an argument list:
  flagValue('-s',{'-d','hej','-s','file'}) => 'file'"
  input String flag;
  input list<String> arguments;
  output String flagVal;
algorithm
  flagVal :=
   matchcontinue(flag,arguments)
   local
      String flag,arg,value;
      list<String> args;
   case(flag,{}) then "";
   case(flag,arg::{})
      equation
        0 = System.strcmp(flag,arg);
      then
        "";
   case(flag,arg::value::args)
      equation
        0 = System.strcmp(flag,arg);
      then
        value;
   case(flag,arg::args)
      equation
        value = flagValue(flag,args);
      then
        value;
   case(_,_)
      equation
       print("- Util.flagValue failed\n");
      then
       fail();
   end matchcontinue;
end flagValue;

public function listFill "function: listFill
  Returns a list of n elements of variable type: replaceable type X subtypeof Any.
  Example: listFill(\"foo\",3) => {\"foo\",\"foo\",\"foo\"}"
  input Type_a inTypeA;
  input Integer inInteger;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:= listFill_tail(inTypeA, inInteger, {});
end listFill;

public function isEqual "Function: isEqual
this function does equal(e1,e2) and returns true if it succedes.
"
  input Type_a input1;
  input Type_a input2;
  output Boolean isequal;
  replaceable type Type_a subtypeof Any;
algorithm isequal := matchcontinue(input1,input2)
  case(input1,input2)
    equation
      equality(input1 = input2);
      then true;
  case(_,_) then false;
  end matchcontinue;
end isEqual;

public function isListEqual "Function: isEqual
this function does equal(e1,e2) and returns true if it succedes.
"
  input list<Type_a> input1;
  input list<Type_a> input2;
  input Boolean equalLength;
  output Boolean isequal;
  replaceable type Type_a subtypeof Any;
algorithm isequal := matchcontinue(input1,input2,equalLength)
  local
    Type_a a,b;
    list<Type_a> al,bl;
    case({},{},_) then true;
  case({},_,false) then true;
  case(_,{},false) then true;
  case(a::al,b::bl,equalLength)
    equation
      true = isEqual(a,b);
      true = isListEqual(al,bl,equalLength);
    then true;
  case(_,_,_) then false;
  end matchcontinue;
end isListEqual;

public function isListNotEmpty
  input list<Type_a> input1;
  output Boolean isempty;
  replaceable type Type_a subtypeof Any;
algorithm isempty := matchcontinue(input1)
  case({}) then false;
  case(_) then true;
  end matchcontinue;
end isListNotEmpty;

public function assertListEmpty
  input list<Type_a> input1;
  replaceable type Type_a subtypeof Any;
algorithm
  _ := matchcontinue(input1)
    case({}) then ();
  end matchcontinue;
end assertListEmpty;

public function listFindWithCompareFunc "
Author BZ 2009-04
Search list for a provided element using the provided function.
Return the index of the element if found, otherwise fail.
"
  input list<Type_a> input1;
  input Type_a input2;
  input compareFunc cmpFunc;
  output Integer isequal;
  partial function compareFunc
    input Type_a inp1;
    input Type_a inp2;
    output Boolean resFunc;
  end compareFunc;
  replaceable type Type_a subtypeof Any;
algorithm isequal := matchcontinue(input1,input2,cmpFunc)
  local
    Type_a a,b;
    list<Type_a> al,bl;
    case({},_,_) equation print("listFindWithCompareFunc failed - end of list\n"); then fail();
    case(a::al,b,cmpFunc)
      equation
        true = cmpFunc(a,b);
        then
          0;
    case(a::al,b,cmpFunc)
      equation
        false = cmpFunc(a,b);
        then
          1+listFindWithCompareFunc(al,b,cmpFunc);
    case(_,_,_) equation print(" generic-failure in listFindWithCompareFunc\n"); then fail();
end matchcontinue;
end listFindWithCompareFunc;

public function selectAndRemoveNth "
Author BZ 2009-04
Extracts N'th element and keeping rest of list intact.
For readability a third position argument has to be passed along.
"
input list<Type_a> inList;
input Integer elemPos;
input Integer curPos;
output Type_a selected;
output list<Type_a> rest;
replaceable type Type_a subtypeof Any;
algorithm (selected,rest) := matchcontinue(inList,elemPos,curPos)
  local
    list<Type_a> al,al2;
    Type_a a,a2;
  case(a::al,elemPos,curPos)
    equation
      true = intEq(elemPos,curPos);
      then
        (a,al);
  case(a::al,elemPos,curPos)
    equation
      false = intEq(elemPos,curPos);
      (a2,al2) = selectAndRemoveNth(al,elemPos,curPos+1);
      then
        (a2,a::al2);
  end matchcontinue;
end selectAndRemoveNth;

public function isListEqualWithCompareFunc "
Author BZ 2009-01
Compares the elements of two lists using provided compare function.
"
input list<Type_a> input1;
input list<Type_a> input2;
input compareFunc cmpFunc;
output Boolean isequal;
partial function compareFunc
  input Type_a inp1;
  input Type_a inp2;
  output Boolean resFunc;
end compareFunc;
replaceable type Type_a subtypeof Any;
algorithm isequal := matchcontinue(input1,input2,cmpFunc)
  local
    Type_a a,b;
    list<Type_a> al,bl;
    case({},{},_) then true;
  case({},_,_) then false;
  case(_,{},_) then false;
  case(a::al,b::bl,cmpFunc)
    equation
      true = cmpFunc(a,b);
      true = isListEqualWithCompareFunc(al,bl,cmpFunc);
    then true;
  case(_,_,_) then false;
  end matchcontinue;
end isListEqualWithCompareFunc;

public function listFill_tail
"function: listFill_tail
 @author adrpo
 tail recursive implementation for listFill"
  input Type_a inTypeA;
  input Integer inInteger;
  input list<Type_a> accumulator;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeA,inInteger, accumulator)
    local
      Type_a a;
      Integer n_1,n;
      list<Type_a> res;
    case(a,n,_)
      equation
        true = n < 0;
        print("Internal Error, negative value to Util.listFill_tail\n");
      then {};
    case (a,0,accumulator) then accumulator;
    case (a,n,accumulator)
      equation
        n_1 = n - 1;
        accumulator = a::accumulator;
        res = listFill_tail(a, n_1, accumulator);
      then
        res;
  end matchcontinue;
end listFill_tail;

public function listMake2 "function listMake2
  Takes two arguments of same type and returns a list containing the two."
  input Type_a inTypeA1;
  input Type_a inTypeA2;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst := {inTypeA1, inTypeA2};
end listMake2;

public function listIntRange2 "
Returns a list of integers from n to m. Only works if n < m.
Example listIntRange2(3,5) => {3,4,5}
"
  input Integer n;
  input Integer m;
  output list<Integer> res;
algorithm
res := listIntRangeHelp(n,m);
end listIntRange2;

public function listIntRange "function: listIntRange
  Returns a list of n integers from 1 to N.
  Example: listIntRange(3) => {1,2,3}"
  input Integer n;
  output list<Integer> res;
algorithm
  res := listIntRangeHelp(1,n); /* listIntRange_tail(1, n, {}); */
end listIntRange;

protected function listIntRange_tail
  input Integer startInt;
  input Integer endInt;
  input list<Integer> accIntegerLst;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (startInt,endInt,accIntegerLst)
    local
      Integer i_1,i,n,hd;
      list<Integer> res;
    case (i,n,accIntegerLst)
      equation
        (i < n) = true;
        i_1 = i + 1;
        hd = n-i+1;
        accIntegerLst = hd::accIntegerLst;
        res = listIntRange_tail(i_1, n, accIntegerLst);
      then
        res;
    case (i,n,accIntegerLst)
      equation
        hd = n-i+1;
      then hd::accIntegerLst;
  end matchcontinue;
end listIntRange_tail;

protected function listIntRangeHelp
  input Integer inInteger1;
  input Integer inInteger2;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inInteger1,inInteger2)
    local
      Integer i_1,i,n;
      list<Integer> res;
    case (i,n)
      equation
        (i < n) = true;
        i_1 = i + 1;

        res = listIntRangeHelp(i_1, n);
      then
        (i :: res);
    case (i,n) then {i};
  end matchcontinue;
end listIntRangeHelp;

public function listFirst "function: listFirst
  Returns the first element of a list
  Example: listFirst({3,5,7,11,13}) => 3"
  input list<Type_a> inTypeALst;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeA:= listNth(inTypeALst, 0);
end listFirst;

public function listFirstOrEmpty "
Author BZ, 2008-09
Same as listFirst, but returns a list of the first element, or empty list if there is no element.
"
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm outTypeA:= matchcontinue(inTypeALst)
  local Type_a aa;
  case({}) then {};
  case(aa::_) then {aa};
end matchcontinue;
end listFirstOrEmpty;

public function list2nd "
  Returns the second element of a list
  Example: listFirst({3,5,7,11,13}) => 5"
  input list<Type_a> inTypeALst;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeA:= listNth(inTypeALst, 1);
end list2nd;

public function listRest "function: listRest
  Returns the rest of a list.
  Example: listRest({3,5,7,11,13}) => {5,7,11,13}"
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst)
    local list<Type_a> x;
    case ((_ :: x)) then x;
  end matchcontinue;
end listRest;

public function listRestOrEmpty "
Author BZ, 2008-09
Same as listRest, but it can return a empty list.
"
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst)
    local list<Type_a> x;
    case ((_ :: x)) then x;
    case({}) then {};
  end matchcontinue;
end listRestOrEmpty;

public function listLast "function: listLast
  Returns the last element of a list. If the list is the empty list, the function fails.
  Example:
    listLast({3,5,7,11,13}) => 13
    listLast({}) => fail"
  input list<Type_a> inTypeALst;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeA:=
  matchcontinue (inTypeALst)
    local
      Type_a a;
      list<Type_a> rest;
    case {} then fail();
    case {a} then a;
    case ((_ :: rest))
      equation
        a = listLast(rest);
      then
        a;
  end matchcontinue;
end listLast;

public function listCons "function: listCons
  Performs the cons operation, i.e. elt::list."
  input list<Type_a> inTypeALst;
  input Type_a inTypeA;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:= (inTypeA::inTypeALst);
end listCons;

public function listCreate "function: listCreate
  Create a list from an element."
  input Type_a inTypeA;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:= {inTypeA};
end listCreate;

public function listStripLast "function: listStripLast
  Remove the last element of a list. If the list is the empty list, the function
  returns empty list
  Example:
    listStripLast({3,5,7,11,13}) => {3,5,7,11}
    listStripLast({}) => {}"
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst)
    local
      Type_a a;
      list<Type_a> lstTmp,lst;
    case {} then {};
    case {a} then {};
    case a::lst
      equation
        lstTmp = listStripLast(lst);
      then
        a::lstTmp;
  end matchcontinue;
end listStripLast;

public function listContains "function: listContains
Checks wheter a list contains a value or not.
"
  input Type_a ele;
  input list<Type_a> elems;
  output Boolean contains;
  replaceable type Type_a subtypeof Any;
algorithm
  contains:=
  matchcontinue (ele,elems)
    local
      Type_a a,b;
      list<Type_a> rest;
      Boolean bool;
    case (_,{}) then false;
    case (a,b::rest)
      equation
        equality(a = b);
      then
        true;
    case (a,_::rest)
      equation
        bool = listContains(a,rest);
      then
        bool;
  end matchcontinue;
end listContains;

public function listNotContains "function: listNotContains
Checks wheter a list contains a value or not.
"
  input Type_a ele;
  input list<Type_a> elems;
  output Boolean contains;
  replaceable type Type_a subtypeof Any;
algorithm
  contains:=
  matchcontinue (ele,elems)
    local
      Type_a a,b;
      list<Type_a> rest;
      Boolean bool;
    case (_,{}) then true;
    case (a,b::rest)
      equation
        equality(a = b);
      then
        false;
    case (a,_::rest)
      equation
        bool = listNotContains(a,rest);
      then
        bool;
  end matchcontinue;
end listNotContains;

public function listContainsWithCompareFunc "function: listContains
Checks wheter a list contains a value or not.
"
  input Type_a ele;
  input list<Type_a> elems;
  input compareFunc f;
  partial function compareFunc
    input Type_a inTypeA;
    input Type_a inTypeA;
    output Boolean outTypeB;
  end compareFunc;
  output Boolean contains;
  replaceable type Type_a subtypeof Any;
algorithm
  contains:=
  matchcontinue (ele,elems,f)
    local
      Type_a a,b;
      list<Type_a> rest;
      Boolean bool;
    case (_,{},_) then false;
    case (a,b::rest,f)
      equation
        true = f(a,b);
      then
        true;
    case (a,_::rest,f)
      equation
        bool = listContainsWithCompareFunc(a,rest,f);
      then
        bool;
  end matchcontinue;
end listContainsWithCompareFunc;

public function listStripFirst "function: listStripLast
  Remove the last element of a list. If the list is the empty list, the function
  returns empty list
  Example:
    listStripLast({3,5,7,11,13}) => {3,5,7,11}
    listStripLast({}) => {}"
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst)
    local
      Type_a a;
      list<Type_a> lstTmp,lst;
    case {} then {};
    case {a} then {};
    case a::lst
      then
        lst;
  end matchcontinue;
end listStripFirst;

public function listFlatten "function: listFlatten
  Takes a list of lists and flattens it out,
  producing one list of all elements of the sublists.
  Example: listFlatten({ {1,2},{3,4,5},{6},{} }) => {1,2,3,4,5,6}"
  input list<list<Type_a>> inTypeALstLst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:= listFlatten_tail(inTypeALstLst, {});
end listFlatten;


public function listFlatten_tail
"function: listFlatten_tail
 tail recursive helper to listFlatten"
  input list<list<Type_a>> inTypeALstLst;
  input list<Type_a> accTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALstLst, accTypeALst)
    local
      list<Type_a> r_1,l,f;
      list<list<Type_a>> r;
    case ({},accTypeALst) then accTypeALst;
    case (f :: r,accTypeALst)
      equation
        r_1 = listAppend(accTypeALst, f);
        l = listFlatten_tail(r, r_1);
      then
        l;
  end matchcontinue;
end listFlatten_tail;


public function listAppendElt "function: listAppendElt
  This function adds an element last to the list
  Example: listAppendElt(1,{2,3}) => {2,3,1}"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:= listAppend(inTypeALst, {inTypeA});
  /*
  matchcontinue (inTypeA,inTypeALst)
    local
      Type_a elt,x;
      list<Type_a> xs_1,xs;
    case (elt,{}) then {elt};
    case (elt,(x :: xs))
      equation
        xs_1 = listAppendElt(elt, xs);
      then
        (x :: xs_1);
  end matchcontinue;
  */
end listAppendElt;

public function applyAndAppend
"@author adrpo
 fun f(x) => y
 fun applyAndAppend(x,f,a) => a @ {(f x)})"
  input Type_a element;
  input FuncTypeType_aToType_b f;
  input list<Type_b> accLst;
  output list<Type_b> outLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
  end FuncTypeType_aToType_b;
algorithm
  outLst := matchcontinue(element, f, accLst)
    case(element, f, accLst)
      local Type_b result;
      equation
        result = f(element);
        accLst = listAppend(accLst, {result});
      then accLst;
  end matchcontinue;
end applyAndAppend;


public function applyAndCons
"@author adrpo
 fun f(x) => y
 fun applyAndCons(x,f,a) => (f x)::a)"
  input Type_a element;
  input FuncTypeType_aToType_b f;
  input list<Type_b> accLst;
  output list<Type_b> outLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
  end FuncTypeType_aToType_b;
algorithm
  outLst := matchcontinue(element, f, accLst)
    case(element, f, accLst)
      local Type_b result;
      equation
        result = f(element);
      then result::accLst;
  end matchcontinue;
end applyAndCons;


public function listApplyAndFold
"@author adrpo
 listApplyAndFold(list<'a>, apply:(x,f,a) => (f x)::a, f:a=>b, accumulator) => list<'b>"
  input list<Type_a> lst;
  input FoldFunc foldFunc;
  input FuncType_a2Type_b typeA2typeB;
  input list<Type_b> accumulator;
  output list<Type_b> result;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FoldFunc
    input Type_a inElement;
    input FuncType_a2Type_b typeA2typeB;
    input list<Type_b> accumulator;
    output list<Type_b> outLst;
    partial function FuncType_a2Type_b
      input Type_a inElement;
      output Type_b outElement;
    end FuncType_a2Type_b;
  end FoldFunc;
  partial function FuncType_a2Type_b
    input Type_a inElement;
    output Type_b outElement;
  end FuncType_a2Type_b;
algorithm
  result :=
  matchcontinue (lst,foldFunc,typeA2typeB,accumulator)
    local
      list<Type_b> foldArg1, foldArg2;
      list<Type_a> rest;
      Type_a hd;
    case ({},_,_,accumulator) then accumulator;
    case (hd :: rest,foldFunc,typeA2typeB,accumulator)
      equation
        foldArg1 = foldFunc(hd,typeA2typeB,accumulator);
        foldArg2 = listApplyAndFold(rest, foldFunc, typeA2typeB, foldArg1);
      then
        foldArg2;
  end matchcontinue;
end listApplyAndFold;


public function listMap "function: listMap
  Takes a list and a function over the elements of the lists, which is applied
  for each element, producing a new list.
  Example: listMap({1,2,3}, intString) => { \"1\", \"2\", \"3\"}"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  output list<Type_b> outTypeBLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aToType_b;
  replaceable type Type_b subtypeof Any;
algorithm
  /* Fastest impl. on large lists, 10M elts takes about 3 seconds */
  outTypeBLst := listMap_impl_2(inTypeALst,{},inFuncTypeTypeAToTypeB);
end listMap;

function listMap_impl_2
"@author adrpo
 this will work in O(2n) due to listReverse"
  replaceable type TypeA subtypeof Any;
  replaceable type TypeB subtypeof Any;
  input  list<TypeA> inLst;
  input  list<TypeB> accumulator;
  input  FuncTypeTypeVarToTypeVar fn;
  output list<TypeB> outLst;
  partial function FuncTypeTypeVarToTypeVar
    input TypeA inTypeA;
    output TypeB outTypeB;
    replaceable type TypeA subtypeof Any;
    replaceable type TypeB subtypeof Any;
  end FuncTypeTypeVarToTypeVar;
algorithm
  outLst := matchcontinue(inLst, accumulator, fn)
    local
      TypeA hd;
      TypeB hdChanged;
      list<TypeA> rest;
      list<TypeB> l, result;
    case ({}, l, _) then listReverse(l);
    case (hd::rest, l, fn)
      equation
        hdChanged = fn(hd);
        l = hdChanged::l;
        result = listMap_impl_2(rest, l, fn);
    then
        result;
  end matchcontinue;
end listMap_impl_2;

public function listMap_2 "function listMap_2
  Takes a list and a function over the elements returning a tuple of
  two types, which is applied for each element producing two new lists.
  Example:
    function split_real_string (real) => (string,string)  returns the string value at
    each side of the decimal point.
    listMap_2({1.5,2.01,3.1415}, split_real_string) => ({\"1\",\"2\",\"3\"},{\"5\",\"01\",\"1415\"})"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToType_bType_c inFuncTypeTypeAToTypeBTypeC;
  output list<Type_b> outTypeBLst;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToType_bType_c
    input Type_a inTypeA;
    output Type_b outTypeB;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aToType_bType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  /* adrpo - tail recursive fast implementation */
  (outTypeBLst,outTypeCLst):= listMap_2_tail(inTypeALst,inFuncTypeTypeAToTypeBTypeC, {}, {});
  /*
  (outTypeBLst,outTypeCLst):=
  matchcontinue (inTypeALst,inFuncTypeTypeAToTypeBTypeC)
    local
      Type_b f1_1;
      Type_c f2_1;
      list<Type_b> r1_1;
      list<Type_c> r2_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aToType_bType_c fn;
    case ({},_) then ({},{});
    case ((f :: r),fn)
      equation
        (f1_1,f2_1) = fn(f);
        (r1_1,r2_1) = listMap_2(r, fn);
      then
        ((f1_1 :: r1_1),(f2_1 :: r2_1));
  end matchcontinue;
  */
end listMap_2;

function listMap_2_tail
"@author adrpo
 this will work in O(2n) due to listReverse"
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  input  list<Type_a> inLst;
  input FuncTypeType_aToType_bType_c fn;
  input  list<Type_b> accumulator1;
  input  list<Type_c> accumulator2;
  output list<Type_b> outTypeBLst;
  output list<Type_c> outTypeCLst;
  partial function FuncTypeType_aToType_bType_c
    input Type_a inTypeA;
    output Type_b outTypeB;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aToType_bType_c;
algorithm
  outLst := matchcontinue(inLst, fn, accumulator1, accumulator2)
    local
      Type_a hd; Type_b hdChanged1; Type_c hdChanged2;
      list<Type_a> rest;  list<Type_b> l1, result1; list<Type_c> l2, result2;
    case ({}, _, l1, l2) then (listReverse(l1), listReverse(l2));
    case (hd::rest, fn, l1, l2)
      equation
        (hdChanged1, hdChanged2) = fn(hd);
        l1 = hdChanged1::l1;
        l2 = hdChanged2::l2;
        (result1, result2) = listMap_2_tail(rest, fn, l1, l2);
    then
        (result1, result2);
  end matchcontinue;
end listMap_2_tail;

public function listMap1_2 "
  Takes a list and a function over the elements and an additional argument returning a tuple of
  two types, which is applied for each element producing two new lists.
  See also listMap_2.
  "
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToType_bType_c inFuncTypeTypeAToTypeBTypeC;
  input Type_d extraArg;
  output list<Type_b> outTypeBLst;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_d subtypeof Any;
  partial function FuncTypeType_aToType_bType_c
    input Type_a inTypeA;
    input Type_d extraArg;
    output Type_b outTypeB;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aToType_bType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  (outTypeBLst,outTypeCLst):=
  matchcontinue (inTypeALst,inFuncTypeTypeAToTypeBTypeC,extraArg)
    local
      Type_b f1_1;
      Type_c f2_1;
      list<Type_b> r1_1;
      list<Type_c> r2_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aToType_bType_c fn;
    case ({},_,_) then ({},{});
    case ((f :: r),fn,extraArg)
      equation
        (f1_1,f2_1) = fn(f,extraArg);
        (r1_1,r2_1) = listMap1_2(r, fn,extraArg);
      then
        ((f1_1 :: r1_1),(f2_1 :: r2_1));
  end matchcontinue;
end listMap1_2;

public function listMap1_3 "
  Takes a list and a function over the elements and an additional argument returning a tuple of
  three types, which is applied for each element producing two new lists.
  See also listMap_2 and listMap1_2.
  "
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToType_bType_c inFuncTypeTypeAToTypeBTypeC;
  input Type_d extraArg;
  output list<Type_b> outTypeBLst;
  output list<Type_c> outTypeCLst;
  output list<Type_e> outTypeELst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_d subtypeof Any;
  partial function FuncTypeType_aToType_bType_c
    input Type_a inTypeA;
    input Type_d extraArg;
    output Type_b outTypeB;
    output Type_c outTypeC;
    output Type_e outTypeE;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aToType_bType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  (outTypeBLst,outTypeCLst,outTypeELst):=
  matchcontinue (inTypeALst,inFuncTypeTypeAToTypeBTypeC,extraArg)
    local
      Type_b f1_1;
      Type_c f2_1;
      Type_e f3_1;
      list<Type_b> r1_1;
      list<Type_c> r2_1;
      list<Type_c> r3_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aToType_bType_c fn;
    case ({},_,_) then ({},{},{});
    case ((f :: r),fn,extraArg)
      equation
        (f1_1,f2_1,f3_1) = fn(f,extraArg);
        (r1_1,r2_1,r3_1) = listMap1_3(r, fn,extraArg);
      then
        ((f1_1 :: r1_1),(f2_1 :: r2_1),(f3_1::r3_1));
  end matchcontinue;
end listMap1_3;

public function listAppendr "
Appends two lists in reverseorder
"
  input list<Type_a> inl1;
  input list<Type_a> inl2;
  output list<Type_a> outl;
  replaceable type Type_a subtypeof Any;
algorithm
  outl := listAppend(inl2,inl1);
end listAppendr;

public function listMap1 "function listMap1
  Takes a list and a function over the list plus an extra argument sent to the function.
  The function produces a new value which is used for creating a new list.
  Example: listMap1({1,2,3},intAdd,2) => {3,4,5}"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_b inTypeB;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeCLst:= listMap1_tail(inTypeALst,inFuncTypeTypeATypeBToTypeC,inTypeB,{});
  /*
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBToTypeC,inTypeB)
    local
      Type_c f_1;
      list<Type_c> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bToType_c fn;
      Type_b extraarg;
    case ({},_,_) then {};
    case ((f :: r),fn,extraarg)
      equation
        f_1 = fn(f, extraarg);
        r_1 = listMap1(r, fn, extraarg);
      then
        (f_1 :: r_1);
  end matchcontinue;
  */
end listMap1;

public function listMap1_tail
"function listMap1_tail
 tail recurstive implmentation of listMap1"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_b inTypeB;
  input list<Type_c> accTypeCLst;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeCLst:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBToTypeC,inTypeB,accTypeCLst)
    local
      Type_c f_1;
      list<Type_c> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bToType_c fn;
      Type_b extraarg;
    /* case ({},_,_,accTypeCLst) then listReverse(accTypeCLst); */
    case ({},_,_,accTypeCLst) then accTypeCLst;
    case ((f :: r),fn,extraarg,accTypeCLst)
      equation
        f_1 = fn(f, extraarg);
/*        accTypeCLst = f_1::accTypeCLst; */
        accTypeCLst = listAppend(accTypeCLst, {f_1});
        r_1 = listMap1_tail(r, fn, extraarg, accTypeCLst);
      then
        r_1;
  end matchcontinue;
end listMap1_tail;

public function listMap1r "function listMap1r
  Same as listMap1 but swapped arguments on function."
  input list<Type_a> inTypeALst;
  input FuncTypeType_bType_aToType_c inFuncTypeTypeBTypeAToTypeC;
  input Type_b inTypeB;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_bType_aToType_c
    input Type_b inTypeB;
    input Type_a inTypeA;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_bType_aToType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeCLst:= listMap1r_tail(inTypeALst,inFuncTypeTypeBTypeAToTypeC,inTypeB,{});
  /*
  matchcontinue (inTypeALst,inFuncTypeTypeBTypeAToTypeC,inTypeB)
    local
      Type_c f_1;
      list<Type_c> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_bType_aToType_c fn;
      Type_b extraarg;
    case ({},_,_) then {};
    case ((f :: r),fn,extraarg)
      equation
        f_1 = fn(extraarg, f);
        r_1 = listMap1r(r, fn, extraarg);
      then
        (f_1 :: r_1);
  end matchcontinue;
  */
end listMap1r;

public function listMap1r_tail
"function listMap1r
 tail recursive implementation of listMap1r"
  input list<Type_a> inTypeALst;
  input FuncTypeType_bType_aToType_c inFuncTypeTypeBTypeAToTypeC;
  input Type_b inTypeB;
  input list<Type_c> accTypeCLst;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_bType_aToType_c
    input Type_b inTypeB;
    input Type_a inTypeA;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_bType_aToType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeCLst:=
  matchcontinue (inTypeALst,inFuncTypeTypeBTypeAToTypeC,inTypeB,accTypeCLst)
    local
      Type_c f_1;
      list<Type_c> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_bType_aToType_c fn;
      Type_b extraarg;
/*    case ({},_,_,accTypeCLst) then listReverse(accTypeCLst);*/
    case ({},_,_,accTypeCLst) then accTypeCLst;
    case ((f :: r),fn,extraarg,accTypeCLst)
      equation
        f_1 = fn(extraarg, f);
/*        accTypeCLst = f_1::accTypeCLst;*/
        accTypeCLst = listAppend(accTypeCLst, {f_1});
        r_1 = listMap1r_tail(r, fn, extraarg, accTypeCLst);
      then
        (r_1);
  end matchcontinue;
end listMap1r_tail;


public function listMap2 "function listMap2
  Takes a list and a function and two extra arguments passed to the function.
  The function produces one new value which is used for creating a new list.
  Example:
    replaceable type Type_a subtypeof Any;
    function select:(Boolean,Type_a,Type_a) => Type_a
    listMap2({true,false,false},1,0,select) => {1,0,0}"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cToType_d inFuncTypeTypeATypeBTypeCToTypeD;
  input Type_b inTypeB;
  input Type_c inTypeC;
  output list<Type_d> outTypeDLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cToType_d
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output Type_d outTypeD;
  end FuncTypeType_aType_bType_cToType_d;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm
  outTypeDLst:= listMap2_tail(inTypeALst,inFuncTypeTypeATypeBTypeCToTypeD,inTypeB,inTypeC, {});
end listMap2;

function listMap2_tail
"@author adrpo
 this will work in O(2n) due to listReverse"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cToType_d fn;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input  list<Type_d> accumulator;
  output list<Type_d> outTypeDLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cToType_d
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output Type_d outTypeD;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
    replaceable type Type_d subtypeof Any;
  end FuncTypeType_aType_bType_cToType_d;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm
  outLst := matchcontinue(inTypeALst, fn, inTypeB, inTypeC, accumulator)
    local
      Type_a hd; Type_d hdChanged;
      list<Type_a> rest;  list<Type_d> l, result;
      Type_b extraarg1;
      Type_c extraarg2;
    case ({}, _, _, _, l) then listReverse(l);
    case (hd::rest, fn, extraarg1, extraarg2, l)
      equation
        hdChanged = fn(hd, extraarg1, extraarg2);
        l = hdChanged::l;
        result = listMap2_tail(rest, fn, extraarg1, extraarg2, l);
    then
        result;
  end matchcontinue;
end listMap2_tail;

public function listMap2r "function listMap2r
  Similar to listMap2 but iterating over last argument instead."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cToType_d inFuncTypeTypeATypeBTypeCToTypeD;
  input Type_b inTypeB;
  input Type_c inTypeC;
  output list<Type_d> outTypeDLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cToType_d
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_a inTypeA;
    output Type_d outTypeD;
  end FuncTypeType_aType_bType_cToType_d;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm
  outTypeDLst:= listMap2r_tail(inTypeALst,inFuncTypeTypeATypeBTypeCToTypeD,inTypeB,inTypeC, {});
end listMap2r;

function listMap2r_tail
""
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cToType_d fn;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input  list<Type_d> accumulator;
  output list<Type_d> outTypeDLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cToType_d
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_a inTypeA;
    output Type_d outTypeD;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
    replaceable type Type_d subtypeof Any;
  end FuncTypeType_aType_bType_cToType_d;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm
  outLst := matchcontinue(inTypeALst, fn, inTypeB, inTypeC, accumulator)
    local
      Type_a hd; Type_d hdChanged;
      list<Type_a> rest;  list<Type_d> l, result;
      Type_b extraarg1;
      Type_c extraarg2;
    case ({}, _, _, _, l) then listReverse(l);
    case (hd::rest, fn, extraarg1, extraarg2, l)
      equation
        hdChanged = fn(extraarg1, extraarg2,hd);
        l = hdChanged::l;
        result = listMap2r_tail(rest, fn, extraarg1, extraarg2, l);
    then
        result;
  end matchcontinue;
end listMap2r_tail;

public function listMap3 "function listMap3
  Takes a list and a function and three extra arguments passed to the function.
  The function produces one new value which is used for creating a new list."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cType_dToType_e inFuncTypeTypeATypeBTypeCTypeDToTypeE;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input Type_d inTypeD;
  output list<Type_e> outTypeELst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cType_dToType_e
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    output Type_e outTypeE;
  end FuncTypeType_aType_bType_cType_dToType_e;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  outTypeELst:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBTypeCTypeDToTypeE,inTypeB,inTypeC,inTypeD)
    local
      Type_e f_1;
      list<Type_e> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bType_cType_dToType_e fn;
      Type_b extraarg1;
      Type_c extraarg2;
      Type_d extraarg3;
    case ({},_,_,_,_) then {};
    case ((f :: r),fn,extraarg1,extraarg2,extraarg3)
      equation
        f_1 = fn(f, extraarg1, extraarg2, extraarg3);
        r_1 = listMap3(r, fn, extraarg1, extraarg2, extraarg3);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listMap3;

public function listMap4 "function listMap4
  Takes a list and a function and four extra arguments passed to the function.
  The function produces one new value which is used for creating a new list."
  input list<Type_a> inTypeALst;
  input mapFunc f;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input Type_d inTypeD;
  input Type_e inTypeE;
  output list<Type_f> outTypeELst;
  replaceable type Type_a subtypeof Any;
  partial function mapFunc
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_e inTypeE;
    output Type_f outTypeF;
  end mapFunc;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
algorithm
  outTypeELst:=
  matchcontinue (inTypeALst,f,inTypeB,inTypeC,inTypeD,inTypeE)
    local
      Type_e f_1;
      list<Type_e> r_1;
      Type_a f;
      list<Type_a> r;
      mapFunc fn;
      Type_b extraarg1;
      Type_c extraarg2;
      Type_d extraarg3;
      Type_e extraarg4;
    case ({},_,_,_,_,_) then {};
    case ((f :: r),fn,extraarg1,extraarg2,extraarg3,extraarg4)
      equation
        f_1 = fn(f, extraarg1, extraarg2, extraarg3,extraarg4);
        r_1 = listMap4(r, fn, extraarg1, extraarg2, extraarg3,extraarg4);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listMap4;

public function listMap5 "function listMap5
  Takes a list and a function and five extra arguments passed to the function.
  The function produces one new value which is used for creating a new list."
  input list<Type_a> lst;
  input listMap7Func func;
  input Type_b a1;
  input Type_c a2;
  input Type_d a3;
  input Type_e a4;
  input Type_f a5;
  output list<Type_i> outLst;
  replaceable type Type_a subtypeof Any;
  partial function listMap7Func
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_e inTypeE;
    input Type_f inTypeF;
    output Type_i outTypeI;
  end listMap7Func;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
  replaceable type Type_g subtypeof Any;
  replaceable type Type_i subtypeof Any;
algorithm
  outLst:=
  matchcontinue (lst,func,a1,a2,a3,a4,a5)
    local
      Type_e f_1;
      list<Type_e> r_1;
      Type_a f;
      list<Type_a> r;

    case ({},_,_,_,_,_,_) then {};
    case ((f :: r),func,a1,a2,a3,a4,a5)
      equation
        f_1 = func(f, a1,a2,a3,a4,a5);
        r_1 = listMap5(r, func, a1,a2,a3,a4,a5);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listMap5;

public function listMap6 "function listMap6
  Takes a list and a function and six extra arguments passed to the function.
  The function produces one new value which is used for creating a new list."
  input list<Type_a> lst;
  input listMap7Func func;
  input Type_b a1;
  input Type_c a2;
  input Type_d a3;
  input Type_e a4;
  input Type_f a5;
  input Type_g a6;
  output list<Type_i> outLst;
  partial function listMap7Func
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_e inTypeE;
    input Type_f inTypeF;
    input Type_g inTypeG;
    output Type_i outTypeI;
  end listMap7Func;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
  replaceable type Type_g subtypeof Any;
  replaceable type Type_h subtypeof Any;
  replaceable type Type_i subtypeof Any;
algorithm
  outLst:=
  matchcontinue (lst,func,a1,a2,a3,a4,a5,a6)
    local
      Type_e f_1;
      list<Type_e> r_1;
      Type_a f;
      list<Type_a> r;

    case ({},_,_,_,_,_,_,_) then {};
    case ((f :: r),func,a1,a2,a3,a4,a5,a6)
      equation
        f_1 = func(f, a1,a2,a3,a4,a5,a6);
        r_1 = listMap6(r, func, a1,a2,a3,a4,a5,a6);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listMap6;

/* TODO: listMap9 ... listMapN can also be created upon request... */
public function listMap7 "function listMap7
  Takes a list and a function and seven extra arguments passed to the function.
  The function produces one new value which is used for creating a new list."
  input list<Type_a> lst;
  input listMap7Func func;
  input Type_b a1;
  input Type_c a2;
  input Type_d a3;
  input Type_e a4;
  input Type_f a5;
  input Type_g a6;
  input Type_h a7;
  output list<Type_i> outLst;
  replaceable type Type_a subtypeof Any;
  partial function listMap7Func
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_e inTypeE;
    input Type_f inTypeF;
    input Type_g inTypeG;
    input Type_h inTypeH;
    output Type_i outTypeI;
  end listMap7Func;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
  replaceable type Type_g subtypeof Any;
  replaceable type Type_h subtypeof Any;
  replaceable type Type_i subtypeof Any;
algorithm
  outLst:=
  matchcontinue (lst,func,a1,a2,a3,a4,a5,a6,a7)
    local
      Type_e f_1;
      list<Type_e> r_1;
      Type_a f;
      list<Type_a> r;

    case ({},_,_,_,_,_,_,_,_) then {};
    case ((f :: r),func,a1,a2,a3,a4,a5,a6,a7)
      equation
        f_1 = func(f, a1,a2,a3,a4,a5,a6,a7);
        r_1 = listMap7(r, func, a1,a2,a3,a4,a5,a6,a7);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listMap7;

public function listMap8 "
Author BZ
  Takes a list and a function and seven extra arguments passed to the function.
  The function produces one new value which is used for creating a new list."
  input list<Type_a> lst;
  input listMap8Func func;
  input Type_b a1;
  input Type_c a2;
  input Type_d a3;
  input Type_e a4;
  input Type_f a5;
  input Type_g a6;
  input Type_h a7;
  input Type_j a8;
  output list<Type_i> outLst;
  replaceable type Type_a subtypeof Any;
  partial function listMap8Func
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_e inTypeE;
    input Type_f inTypeF;
    input Type_g inTypeG;
    input Type_h inTypeH;
    input Type_j inTypeJ;
    output Type_i outTypeI;
  end listMap8Func;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
  replaceable type Type_g subtypeof Any;
  replaceable type Type_h subtypeof Any;
  replaceable type Type_i subtypeof Any;
  replaceable type Type_j subtypeof Any;
algorithm
  outLst:=
  matchcontinue (lst,func,a1,a2,a3,a4,a5,a6,a7,a8)
    local
      Type_e f_1;
      list<Type_e> r_1;
      Type_a f;
      list<Type_a> r;

    case ({},_,_,_,_,_,_,_,_,_) then {};
    case ((f :: r),func,a1,a2,a3,a4,a5,a6,a7,a8)
      equation
        f_1 = func(f, a1,a2,a3,a4,a5,a6,a7,a8);
        r_1 = listMap8(r, func, a1,a2,a3,a4,a5,a6,a7,a8);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listMap8;
public function listMap32 "function listMap32
  Takes a list and a function and three extra arguments passed to the function.
  The function produces two values which is used for creating two new lists."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cType_dToType_eType_f inFuncTypeTypeATypeBTypeCTypeDToTypeETypeF;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input Type_d inTypeD;
  output list<Type_e> outTypeELst;
  output list<Type_f> outTypeFLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cType_dToType_eType_f
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    output Type_e outTypeE;
    output Type_f outTypeF;
  end FuncTypeType_aType_bType_cType_dToType_eType_f;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
algorithm
  (outTypeELst,outTypeFLst):=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBTypeCTypeDToTypeETypeF,inTypeB,inTypeC,inTypeD)
    local
      Type_e f1_1;
      Type_f f2_1;
      list<Type_e> r1_1;
      list<Type_f> r2_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bType_cType_dToType_eType_f fn;
      Type_b extraarg1;
      Type_c extraarg2;
      Type_d extraarg3;
    case ({},_,_,_,_) then ({},{});
    case ((f :: r),fn,extraarg1,extraarg2,extraarg3)
      equation
        (f1_1,f2_1) = fn(f, extraarg1, extraarg2, extraarg3);
        (r1_1,r2_1) = listMap32(r, fn, extraarg1, extraarg2, extraarg3);
      then
        ((f1_1 :: r1_1),(f2_1 :: r2_1));
  end matchcontinue;
end listMap32;

public function listMap42 "function listMap32
  Takes a list and a function and three extra arguments passed to the function.
  The function produces two values which is used for creating two new lists."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cType_dToType_eType_f inFuncTypeTypeATypeBTypeCTypeDToTypeETypeF;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input Type_d inTypeD;
  input Type_de inTypeDE;
  output list<Type_e> outTypeELst;
  output list<Type_f> outTypeFLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cType_dToType_eType_f
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_de inTypeDE;
    output Type_e outTypeE;
    output Type_f outTypeF;
  end FuncTypeType_aType_bType_cType_dToType_eType_f;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_de subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
algorithm
  (outTypeELst,outTypeFLst):=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBTypeCTypeDToTypeETypeF,inTypeB,inTypeC,inTypeD,inTypeDE)
    local
      Type_e f1_1;
      Type_f f2_1;
      list<Type_e> r1_1;
      list<Type_f> r2_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bType_cType_dToType_eType_f fn;
      Type_b extraarg1;
      Type_c extraarg2;
      Type_d extraarg3;
      Type_de extraarg4;
    case ({},_,_,_,_,_) then ({},{});
    case ((f :: r),fn,extraarg1,extraarg2,extraarg3,extraarg4)
      equation
        (f1_1,f2_1) = fn(f, extraarg1, extraarg2, extraarg3, extraarg4);
        (r1_1,r2_1) = listMap42(r, fn, extraarg1, extraarg2, extraarg3, extraarg4);
      then
        ((f1_1 :: r1_1),(f2_1 :: r2_1));
  end matchcontinue;
end listMap42;

public function listMap12 "function: listMap12
  Takes a list and a function with one extra arguments passed to the function.
  The function returns a tuple of two values which are used for creating
  two new lists."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bToType_cType_d inFuncTypeTypeATypeBToTypeCTypeD;
  input Type_b inTypeB;
  output list<Type_c> outTypeCLst;
  output list<Type_d> outTypeDLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bToType_cType_d
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    output Type_d outTypeD;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
    replaceable type Type_d subtypeof Any;
  end FuncTypeType_aType_bToType_cType_d;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm
  (outTypeCLst,outTypeDLst):=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBToTypeCTypeD,inTypeB)
    local
      Type_c f1;
      Type_d f2;
      list<Type_c> r1;
      list<Type_d> r2;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bToType_cType_d fn;
      Type_b extraarg1;
    case ({},_,_) then ({},{});
    case ((f :: r),fn,extraarg1)
      equation
        (f1,f2) = fn(f, extraarg1);
        (r1,r2) = listMap12(r, fn, extraarg1);
      then
        ((f1 :: r1),(f2 :: r2));
  end matchcontinue;
end listMap12;

public function listMap22 "function: listMap22
  Takes a list and a function with two extra arguments passed to the function.
  The function returns a tuple of two values which are used for creating two new lists
  Example:
    function foo(int,string,string) => (string,string)
      concatenates each string with itself n times. foo(2,\"a\",b\") => (\"aa\",\"bb\")
    listMap22 ({2,3},foo,\"a\",\"b\") => {(\"aa\",\"bb\"),(\"aa\",\"bbb\")}"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cToType_dType_e inFuncTypeTypeATypeBTypeCToTypeDTypeE;
  input Type_b inTypeB;
  input Type_c inTypeC;
  //output list<tuple<Type_d, Type_e>> outTplTypeDTypeELst;
  output list<Type_d> outTypeDLst;
  output list<Type_e> outTypeELst;
  partial function FuncTypeType_aType_bType_cToType_dType_e
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output Type_d outTypeD;
    output Type_e outTypeE;
  end FuncTypeType_aType_bType_cToType_dType_e;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  (outTypeDLst,outTypeELst):=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBTypeCToTypeDTypeE,inTypeB,inTypeC)
    local
      Type_d f1;
      Type_e f2;
      list<Type_d> r_1;
      list<Type_e> r_2;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bType_cToType_dType_e fn;
      Type_b extraarg1;
      Type_c extraarg2;
    case ({},_,_,_) then ({},{});
    case ((f :: r),fn,extraarg1,extraarg2)
      equation
        (f1,f2) = fn(f, extraarg1, extraarg2);
        (r_1,r_2) = listMap22(r, fn, extraarg1, extraarg2);
      then
        (f1::r_1,f2::r_2);
  end matchcontinue;
end listMap22;

public function listMap0 "function: listMap0
  Takes a list and a function which does not return a value
  The function is probably a function with side effects, like print.
  Example: listMap0({\"a\",\"b\",\"c\"},print) => ()"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm
  _:=
  matchcontinue (inTypeALst,inFuncTypeTypeATo)
    local
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aTo fn;
    case ({},_) then ();
    case ((f :: r),fn)
      equation
        fn(f);
        listMap0(r, fn);
      then
        ();
  end matchcontinue;
end listMap0;

public function listMap01 "
  See listMap0
"
  input list<Type_a> inTypeALst;
  input Type_b b;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
    input Type_b b;
  end FuncTypeType_aTo;
algorithm
  _:=
  matchcontinue (inTypeALst,b,inFuncTypeTypeATo)
    local
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aTo fn;
    case ({},_,_) then ();
    case ((f :: r),b,fn)
      equation
        fn(f,b);
        listMap01(r, b,fn);
      then
        ();
  end matchcontinue;
end listMap01;

public function listListAppendLast "appends to the last element of a list of list of elements"
  input list<list<Type_a>> llst;
  input list<Type_a> lst;
  output list<list<Type_a>> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := matchcontinue(llst,lst)
  local list<Type_a> lst1;
    case({},lst) then {lst};
    case({lst1},lst) equation
      lst1 = listAppend(lst1,lst);
    then {lst1};
    case (lst1::llst,lst) equation
      llst = listListAppendLast(llst,lst);
    then lst1::llst;
  end matchcontinue;
end listListAppendLast;

public function listListMap "function: listListMap
  Takes a list of lists and a function producing one value.
  The function is applied to each element of the lists resulting
  in a new list of lists.
  Example: listListMap({ {1,2},{3},{4}},int_string) => { {\"1\",\"2\"},{\"3\"},{\"4\"} }"
  input list<list<Type_a>> inTypeALstLst;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  output list<list<Type_b>> outTypeBLstLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aToType_b;
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeBLstLst:=
  matchcontinue (inTypeALstLst,inFuncTypeTypeAToTypeB)
    local
      list<Type_b> f_1;
      list<list<Type_b>> r_1;
      list<Type_a> f;
      list<list<Type_a>> r;
      FuncTypeType_aToType_b fn;
    case ({},_) then {};
    case ((f :: r),fn)
      equation
        f_1 = listMap(f, fn);
        r_1 = listListMap(r, fn);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listListMap;

public function listListMap1 "function listListMap1
  author: PA
  similar to listListMap but for functions taking two arguments.
  The second argument is passed as an extra argument."
  input list<list<Type_a>> inTypeALstLst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_b inTypeB;
  output list<list<Type_c>> outTypeCLstLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeCLstLst:=
  matchcontinue (inTypeALstLst,inFuncTypeTypeATypeBToTypeC,inTypeB)
    local
      list<Type_c> f_1;
      list<list<Type_c>> r_1;
      list<Type_a> f;
      list<list<Type_a>> r;
      FuncTypeType_aType_bToType_c fn;
      Type_b e;
    case ({},_,_) then {};
    case ((f :: r),fn,e)
      equation
        f_1 = listMap1(f, fn, e);
        r_1 = listListMap1(r, fn, e);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listListMap1;

public function listListMap2 "function listListMap1
  author: BZ
  similar to listListMap but for functions taking three arguments.
  The second and third argument is passed as an extra argument."
  input list<list<Type_a>> inTypeALstLst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_b inTypeB;
  input Type_e inTypeE;
  output list<list<Type_c>> outTypeCLstLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_e inTypeE;
    output Type_c outTypeC;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  outTypeCLstLst:=
  matchcontinue (inTypeALstLst,inFuncTypeTypeATypeBToTypeC,inTypeB,inTypeE)
    local
      list<Type_c> f_1;
      list<list<Type_c>> r_1;
      list<Type_a> f;
      list<list<Type_a>> r;
      FuncTypeType_aType_bToType_c fn;
      Type_b e;
      Type_e d;
    case ({},_,_,_) then {};
    case ((f :: r),fn,e,d)
      equation
        f_1 = listMap2(f, fn, e, d);
        r_1 = listListMap2(r, fn, e, d);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listListMap2;

public function listFoldList "
Author BZ
apply a function on the heads of two equally length list of generic type.
"
input list<Type_a> lst1;
input list<Type_a> lst2;
input listAddFunc func;
output list<Type_a> mergedList;
  partial function listAddFunc
    input Type_a ia1;
    input Type_a ia2;
    output Type_a oa1;
  end listAddFunc;
  replaceable type Type_a subtypeof Any;
  algorithm
    mergedList := matchcontinue(lst1,lst2,func)
    local
      Type_a a1,a2,aRes;
      case({},{},_) then {};
      case(a1::lst1,a2::lst2,func)
        equation
          aRes = func(a1,a2);
          mergedList = listFoldList(lst1,lst2,func);
          then
            aRes::mergedList; 
      end matchcontinue;
end listFoldList;

public function listFold "function: listFold 
  Takes a list and a function operating on list elements having an extra argument that is \'updated\'
  thus returned from the function. The third argument is the startvalue for the updated value.
  listFold will call the function for each element in a sequence, updating the startvalue
  Example:
    listFold({1,2,3},intAdd,2) =>  8
    intAdd(1,2) => 3, intAdd(2,3) => 5, intAdd(3,5) => 8"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bToType_b inFuncTypeTypeATypeBToTypeB;
  input Type_b inTypeB;
  output Type_b outTypeB;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bToType_b
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_b outTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aType_bToType_b;
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeB:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBToTypeB,inTypeB)
    local
      FuncTypeType_aType_bToType_b r;
      Type_b b,b_1,b_2;
      Type_a l;
      list<Type_a> lst;
    case ({},r,b) then b;
    case ((l :: lst),r,b)
      equation
        b_1 = r(l, b);
        b_2 = listFold(lst, r, b_1);
      then
        b_2;
  end matchcontinue;
end listFold;

public function listFoldR "function: listFoldR
  Similar to listFold but reversed argument order in function."
  input list<Type_a> lst;
  input FoldFunc foldFunc;
  input Type_b foldArg;
  output Type_b res;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FoldFunc
    input Type_b foldArg;
    input Type_a iterated;
    output Type_b foldArg;
  end FoldFunc;
algorithm
  res:=
  matchcontinue (lst,foldFunc,foldArg)
    local
      Type_b foldArg1,foldArg2;
      Type_a l;
      list<Type_a> lst;
    case ({},foldFunc,foldArg) then foldArg;
    case ((l :: lst),foldFunc,foldArg)
      equation
        foldArg1 = foldFunc(foldArg,l);
        foldArg2 = listFoldR(lst, foldFunc,foldArg1);
      then
        foldArg2;
  end matchcontinue;
end listFoldR;

public function listFold_2 "function: listFold_2
  Similar to listFold but relation takes three arguments.
  The first argument is folded (i.e. passed through each relation)
  The second argument is constant (given as argument)
  The third argument is iterated over list."
  input list<Type_a> lst;
  input FoldFunc foldFunc;
  input Type_b foldArg;
  input Type_c extraArg;
  output Type_b res;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  partial function FoldFunc
    input Type_b foldArg;
    input Type_c extraArg;
    input Type_a iterated;
    output Type_b foldArg;
  end FoldFunc;
algorithm
  res:=
  matchcontinue (lst,foldFunc,foldArg,extraArg)
    local
      Type_b foldArg1,foldArg2;
      Type_a l;
      list<Type_a> lst;
    case ({},foldFunc,foldArg,extraArg) then foldArg;
    case ((l :: lst),foldFunc,foldArg,extraArg)
      equation
        foldArg1 = foldFunc(foldArg,extraArg,l);
        foldArg2 = listFold_2(lst, foldFunc,foldArg1, extraArg);
      then
        foldArg2;
  end matchcontinue;
end listFold_2;

public function listFold_2r "function: listFold_2
  Similar to listFold_2 but reversed argument order in function."
  input list<Type_a> lst;
  input FoldFunc foldFunc;
  input Type_b foldArg;
  input Type_c extraArg;
  output Type_b res;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  partial function FoldFunc
    input Type_b foldArg;
    input Type_a iterated;
    input Type_c extraArg;
    output Type_b foldArg;
  end FoldFunc;
algorithm
  res:=
  matchcontinue (lst,foldFunc,foldArg,extraArg)
    local
      Type_b foldArg1,foldArg2;
      Type_a l;
      list<Type_a> lst;
    case ({},foldFunc,foldArg,extraArg) then foldArg;
    case ((l :: lst),foldFunc,foldArg,extraArg)
      equation
        foldArg1 = foldFunc(foldArg,l,extraArg);
        foldArg2 = listFold_2r(lst, foldFunc,foldArg1, extraArg);
      then
        foldArg2;
  end matchcontinue;
end listFold_2r;

public function listFold_3 "function: listFold_3
  Similar to listFold but relation takes four arguments.
  The first argument is folded (i.e. passed through each relation)
  The second argument is constant (given as argument)
  The third argument is iterated over list."
  input list<Type_a> lst;
  input FoldFunc foldFunc;
  input Type_b foldArg;
  input Type_c extraArg;
  input Type_d extraArg2;
  output Type_b res;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  partial function FoldFunc
    input Type_b foldArg;
    input Type_a iterated;
    input Type_c extraArg;
    input Type_d extraArg2;
    output Type_b foldArg;
  end FoldFunc;
algorithm
  res:=
  matchcontinue (lst,foldFunc,foldArg,extraArg,extraArg2)
    local
      Type_b foldArg1,foldArg2;
      Type_a l;
      list<Type_a> lst;
    case ({},foldFunc,foldArg,extraArg,extraArg2) then foldArg;
    case ((l :: lst),foldFunc,foldArg,extraArg,extraArg2)
      equation
        foldArg1 = foldFunc(foldArg,l,extraArg,extraArg2);
        foldArg2 = listFold_3(lst, foldFunc,foldArg1, extraArg, extraArg2);
      then
        foldArg2;
  end matchcontinue;
end listFold_3;

public function listlistFoldMap "function: listlistFoldMap
  For example see Interactive.traverseExp."
  input list<list<Type_a>> inTypeALst;
  input FuncTypeTplType_aType_bToTplType_aType_b inFuncTypeTplTypeATypeBToTplTypeATypeB;
  input Type_b inTypeB;
  output list<list<Type_a>> outTypeALst;
  output Type_b outTypeB;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeTplType_aType_bToTplType_aType_b
    input tuple<Type_a, Type_b> inTplTypeATypeB;
    output tuple<Type_a, Type_b> outTplTypeATypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeTplType_aType_bToTplType_aType_b;
  replaceable type Type_b subtypeof Any;
algorithm
  (outTypeALst,outTypeB):=
  matchcontinue (inTypeALst,inFuncTypeTplTypeATypeBToTplTypeATypeB,inTypeB)
    local
      FuncTypeTplType_aType_bToTplType_aType_b rel;
      Type_b e_arg,b_1,b_2,b;
      list<Type_a> elt_1,elt;
      list<list<Type_a>> elts_1,elts;
    case ({},rel,e_arg) then ({},e_arg);
    case ((elt :: elts),rel,b)
      equation
        (elt_1,b_1) = listFoldMap(elt,rel,b);
        (elts_1,b_2) = listlistFoldMap(elts, rel, b_1);
      then
        ((elt_1 :: elts_1),b_2);
  end matchcontinue;
end listlistFoldMap;

public function listFoldMap "function: listFoldMap
  author: PA
  For example see Exp.traverseExp."
  input list<Type_a> inTypeALst;
  input FuncTypeTplType_aType_bToTplType_aType_b inFuncTypeTplTypeATypeBToTplTypeATypeB;
  input Type_b inTypeB;
  output list<Type_a> outTypeALst;
  output Type_b outTypeB;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeTplType_aType_bToTplType_aType_b
    input tuple<Type_a, Type_b> inTplTypeATypeB;
    output tuple<Type_a, Type_b> outTplTypeATypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeTplType_aType_bToTplType_aType_b;
  replaceable type Type_b subtypeof Any;
algorithm
  (outTypeALst,outTypeB):=
  matchcontinue (inTypeALst,inFuncTypeTplTypeATypeBToTplTypeATypeB,inTypeB)
    local
      FuncTypeTplType_aType_bToTplType_aType_b rel;
      Type_b e_arg,b_1,b_2,b;
      Type_a elt_1,elt;
      list<Type_a> elts_1,elts;
    case ({},rel,e_arg) then ({},e_arg);
    case ((elt :: elts),rel,b)
      equation
        ((elt_1,b_1)) = rel((elt,b));
        (elts_1,b_2) = listFoldMap(elts, rel, b_1);
      then
        ((elt_1 :: elts_1),b_2);
  end matchcontinue;
end listFoldMap;

public function listListReverse "function: listListReverse
  Takes a list of lists and reverses it at both
  levels, i.e. both the list itself and each sublist
  Example: listListReverse({{1,2},{3,4,5},{6} }) => { {6}, {5,4,3}, {2,1} }"
  input list<list<Type_a>> lsts;
  output list<list<Type_a>> lsts_2;
  replaceable type Type_a subtypeof Any;
  list<list<Type_a>> lsts_1,lsts_2;
algorithm
  lsts_1 := listMap(lsts, listReverse);
  lsts_2 := listReverse(lsts_1);
end listListReverse;

public function listThread "function: listThread
  Takes two lists of the same type and threads (interleaves) them togheter.
  Example: listThread({1,2,3},{4,5,6}) => {4,1,5,2,6,3}"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst1,inTypeALst2)
    local
      list<Type_a> r_1,c,d,ra,rb;
      Type_a fa,fb;
    case ({},{}) then {};
    case ((fa :: ra),(fb :: rb))
      equation
        r_1 = listThread(ra, rb);
        c = (fb :: r_1);
        d = (fa :: c);
      then
        d;
  end matchcontinue;
end listThread;

public function listThread3 "function: listThread
  Takes three lists of the same type and threads (interleaves) them togheter.
  Example: listThread3({1,2,3},{4,5,6},{7,8,9}) => {7,4,1,8,5,2,9,6,3}"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input list<Type_a> inTypeALst3;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst1,inTypeALst2,inTypeALst3)
    local
      list<Type_a> r_1,c,d,ra,rb,rc;
      Type_a fa,fb,fc;
    case ({},{},{}) then {};
    case ((fa :: ra),(fb :: rb),fc::rc)
      equation
        r_1 = listThread3(ra, rb,rc);
      then
        fa::fb::fc::r_1;
  end matchcontinue;
end listThread3;

public function listThreadMap "function: listThreadMap
  Takes two lists and a function and threads (interleaves) and maps the elements of the two lists
  creating a new list.
  Example: listThreadMap({1,2},{3,4},intAdd) => {1+3, 2+4}"
  input list<Type_a> inTypeALst;
  input list<Type_b> inTypeBLst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeCLst:=
  matchcontinue (inTypeALst,inTypeBLst,inFuncTypeTypeATypeBToTypeC)
    local
      Type_c fr;
      list<Type_c> res;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
      FuncTypeType_aType_bToType_c fn;
    case ({},{},_) then {};
    case ((fa :: ra),(fb :: rb),fn)
      equation
        fr = fn(fa, fb);
        res = listThreadMap(ra, rb, fn);
      then
        (fr :: res);
  end matchcontinue;
end listThreadMap;

public function listThreadMap32 "function: listThreadMap32
  Takes three lists and a function and threads (interleaves) and maps the elements of the three lists
  creating two new lists.
  Example: listThreadMap({1,2},{3,4},{5,6},intAddSub3) => ({1+3+5, 2+4+6},{1-3-5, 2-4-6})"
  input list<Type_a> inTypeALst;
  input list<Type_b> inTypeBLst;
  input list<Type_c> inTypeCLst;
  input FuncTypeType_aType_bType_cToType_dType_e inFuncTypeTypeATypeBTypeCToTypeDTypeE;
  output list<Type_d> outTypeDLst;
  output list<Type_e> outTypeELst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  partial function FuncTypeType_aType_bType_cToType_dType_e
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output Type_d outTypeD;
    output Type_e outTypeE;
  end FuncTypeType_aType_bType_cToType_dType_e;
algorithm
  outTypeCLst:=
  matchcontinue (inTypeALst,inTypeBLst,inTypeCLst,inFuncTypeTypeATypeBTypeCToTypeDTypeE)
    local
      Type_d fr_d;
      Type_e fr_e;
      list<Type_d> res_d;
      list<Type_e> res_e;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
      Type_c fc;
      list<Type_c> rc;
      FuncTypeType_aType_bType_cToType_dType_e fn;
    case ({},{},{},_) then ({},{});
    case ((fa :: ra),(fb :: rb),(fc :: rc),fn)
      equation
        (fr_d,fr_e) = fn(fa, fb, fc);
        (res_d,res_e) = listThreadMap32(ra, rb, rc, fn);
      then
        (fr_d :: res_d, fr_e :: res_e);
  end matchcontinue;
end listThreadMap32;

public function listListThreadMap "function: listListThreadMap
  Takes two lists of lists and a function and threads (interleaves)
  and maps the elements  of the elements of the two lists creating a new list.
  Example: listListThreadMap({{1,2}},{{3,4}},int_add) => {{1+3, 2+4}}"
  input list<list<Type_a>> inTypeALst;
  input list<list<Type_b>> inTypeBLst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  output list<list<Type_c>> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeCLst:=
  matchcontinue (inTypeALst,inTypeBLst,inFuncTypeTypeATypeBToTypeC)
    local
      Type_c fr;
      list<Type_c> res;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
      FuncTypeType_aType_bToType_c fn;
    case ({},{},_) then {};
    case ((fa :: ra),(fb :: rb),fn)
      equation
        fr = listThreadMap(fa,fb,fn);
        res = listListThreadMap(ra, rb, fn);
      then
        (fr :: res);
  end matchcontinue;
end listListThreadMap;

public function listThreadTuple "function: listThreadTuple
  Takes two lists and threads (interleaves) the arguments into
  a list of tuples consisting of the two element types.
  Example: listThreadTuple({1,2,3},{true,false,true}) => {(1,true),(2,false),(3,true)}"
  input list<Type_a> inTypeALst;
  input list<Type_b> inTypeBLst;
  output list<tuple<Type_a, Type_b>> outTplTypeATypeBLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  outTplTypeATypeBLst:=
  matchcontinue (inTypeALst,inTypeBLst)
    local
      list<tuple<Type_a, Type_b>> r;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
    case ({},{}) then {};
    case ((fa :: ra),(fb :: rb))
      equation
        r = listThreadTuple(ra, rb);
      then
        ((fa,fb) :: r);
  end matchcontinue;
end listThreadTuple;

public function listThread3Tuple "
  Takes three lists and threads (interleaves) the arguments into
  a list of tuples consisting of the three element types.
  Example: listThreadTuple({1,2,3},{true,false,true},{3,4,5}) => {(1,true,3),(2,false,4),(3,true,5)}"
  input list<Type_a> lst1;
  input list<Type_b> lst2;
  input list<Type_c> lst3;
  output list<tuple<Type_a, Type_b,Type_c>> outLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outLst :=
  matchcontinue (lst1,lst2,lst3)
    local
      list<tuple<Type_a, Type_b,Type_c>> r;
      Type_a fa;
      list<Type_a> ra;
      Type_b fb;
      list<Type_b> rb;
      list<Type_c> rc;
      Type_c fc;
    case ({},{},{}) then {};
    case ((fa :: ra),(fb :: rb),(fc::rc))
      equation
        r = listThread3Tuple(ra, rb,rc);
      then
        ((fa,fb,fc) :: r);
  end matchcontinue;
end listThread3Tuple;

public function listListThreadTuple "function: listListThreadTuple
  Takes two list of lists as arguments and produces a list of
  lists of a two tuple of the element types of each list.
  Example:
    listListThreadTuple({{1},{2,3}},{{\"a\"},{\"b\",\"c\"}}) => { {(1,\"a\")},{(2,\"b\"),(3,\"c\")} }"
  input list<list<Type_a>> inTypeALstLst;
  input list<list<Type_b>> inTypeBLstLst;
  output list<list<tuple<Type_a, Type_b>>> outTplTypeATypeBLstLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  outTplTypeATypeBLstLst:=
  matchcontinue (inTypeALstLst,inTypeBLstLst)
    local
      list<tuple<Type_a, Type_b>> f;
      list<list<tuple<Type_a, Type_b>>> r;
      list<Type_a> fa;
      list<list<Type_a>> ra;
      list<Type_b> fb;
      list<list<Type_b>> rb;
    case ({},{}) then {};
    case ((fa :: ra),(fb :: rb))
      equation
        f = listThreadTuple(fa, fb);
        r = listListThreadTuple(ra, rb);
      then
        (f :: r);
  end matchcontinue;
end listListThreadTuple;

public function selectFirstNonEmptyString "Selects the first non-empty string from a list of strings.
If all strings a empty or empty list return empty string.
"
input list<String> slst;
output String res;
algorithm
  res := matchcontinue(slst)
  local String s;
    case(s::slst) equation
      true = (s ==& "");
      res = selectFirstNonEmptyString(slst);
    then res;
    case(s::slst) equation
      false= (s ==& "");
    then s;
    case({}) then "";
  end matchcontinue;
end selectFirstNonEmptyString;

public function listSelect "function: listSelect
  This function retrieves all elements of a list for which
  the passed function evaluates to true. The elements that
  evaluates to false are thus removed from the list."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToBoolean inFuncTypeTypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToBoolean
    input Type_a inTypeA;
    output Boolean outBoolean;
  end FuncTypeType_aToBoolean;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst,inFuncTypeTypeAToBoolean)
    local
      list<Type_a> xs_1,xs;
      Type_a x;
      FuncTypeType_aToBoolean cond;
    case ({},_) then {};
    case ((x :: xs),cond)
      equation
        true = cond(x);
        xs_1 = listSelect(xs, cond);
      then
        (x :: xs_1);
    case ((x :: xs),cond)
      equation
        false = cond(x);
        xs_1 = listSelect(xs, cond);
      then
        xs_1;
  end matchcontinue;
end listSelect;

public function listSelect1 "function listSelect1
  Same as listSelect above, but with extra argument to testing function."
  input list<Type_a> inTypeALst;
  input Type_b inTypeB;
  input FuncTypeType_aType_bToBoolean inFuncTypeTypeATypeBToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aType_bToBoolean
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Boolean outBoolean;
  end FuncTypeType_aType_bToBoolean;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst,inTypeB,inFuncTypeTypeATypeBToBoolean)
    local
      Type_b arg;
      list<Type_a> xs_1,xs;
      Type_a x;
      FuncTypeType_aType_bToBoolean cond;
    case ({},arg,_) then {};
    case ((x :: xs),arg,cond)
      equation
        true = cond(x, arg);
        xs_1 = listSelect1(xs, arg, cond);
      then
        (x :: xs_1);
    case ((x :: xs),arg,cond)
      equation
        false = cond(x, arg);
        xs_1 = listSelect1(xs, arg, cond);
      then
        xs_1;
  end matchcontinue;
end listSelect1;

public function listSelect2 "function listSelect1
  Same as listSelect above, but with extra argument to testing function."
  input list<Type_a> inTypeALst;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input FuncTypeType_aType_bToBoolean inFuncTypeTypeATypeBToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  partial function FuncTypeType_aType_bToBoolean
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeB;
    output Boolean outBoolean;
  end FuncTypeType_aType_bToBoolean;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst,inTypeB,inTypeC,inFuncTypeTypeATypeBToBoolean)
    local
      Type_b arg1; Type_c arg2;
      list<Type_a> xs_1,xs;
      Type_a x;
      FuncTypeType_aType_bToBoolean cond;
    case ({},arg1,arg2,_) then {};
    case ((x :: xs),arg1,arg2,cond)
      equation
        true = cond(x, arg1,arg2);
        xs_1 = listSelect2(xs, arg1,arg2, cond);
      then
        (x :: xs_1);
    case ((x :: xs),arg1,arg2,cond)
      equation
        false = cond(x, arg1,arg2);
        xs_1 = listSelect2(xs, arg1,arg2, cond);
      then
        xs_1;
  end matchcontinue;
end listSelect2;

public function listSelect1R "function listSelect1R
  Same as listSelect1 above, but with swapped arguments."
  input list<Type_a> inTypeALst;
  input Type_b inTypeB;
  input FuncTypeType_bType_aToBoolean inFuncTypeTypeBTypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_bType_aToBoolean
    input Type_b inTypeB;
    input Type_a inTypeA;
    output Boolean outBoolean;
  end FuncTypeType_bType_aToBoolean;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst,inTypeB,inFuncTypeTypeBTypeAToBoolean)
    local
      Type_b arg;
      list<Type_a> xs_1,xs;
      Type_a x;
      FuncTypeType_bType_aToBoolean cond;
    case ({},arg,_) then {};
    case ((x :: xs),arg,cond)
      equation
        true = cond(arg, x);
        xs_1 = listSelect1R(xs, arg, cond);
      then
        (x :: xs_1);
    case ((x :: xs),arg,cond)
      equation
        false = cond(arg, x);
        xs_1 = listSelect1R(xs, arg, cond);
      then
        xs_1;
  end matchcontinue;
end listSelect1R;

public function listPosition "function: listPosition
  Takes a value and a list of values and returns the (first) position
  the value has in the list. Position index start at zero, such that
  listNth can be used on the resulting position directly.
  Example: listPosition(2,{0,1,2,3}) => 2"
  input Type_a x;
  input list<Type_a> ys;
  output Integer n;
  replaceable type Type_a subtypeof Any;
algorithm
  n := listPos(x, ys, 0);
end listPosition;

protected function listPos "helper function to listPosition"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  input Integer inInteger;
  output Integer outInteger;
  replaceable type Type_a subtypeof Any;
algorithm
  outInteger:=
  matchcontinue (inTypeA,inTypeALst,inInteger)
    local
      Type_a x,y,i;
      list<Type_a> ys;
      Integer i_1,n;
    case (x,(y :: ys),i)
      equation
        equality(x = y);
      then
        i;
    case (x,(y :: ys),i)
      local Integer i;
      equation
        failure(equality(x = y));
        i_1 = i + 1;
        n = listPos(x, ys, i_1);
      then
        n;
  end matchcontinue;
end listPos;

public function listGetMember "function: listGetMember
  Takes a value and a list of values and returns the value
  if present in the list. If not present, the function will fail.
  Example:
    listGetMember(0,{1,2,3}) => fail
    listGetMember(1,{1,2,3}) => 1"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeA:=
  matchcontinue (inTypeA,inTypeALst)
    local
      Type_a x,y,res;
      list<Type_a> ys;
    case (_,{}) then fail();
    case (x,(y :: ys))
      equation
        equality(x = y);
      then
        y;
    case (x,(y :: ys))
      equation
        failure(equality(x = y));
        res = listGetMember(x, ys);
      then
        res;
  end matchcontinue;
end listGetMember;

public function listDeletePositionsSorted "more efficient implemtation of deleting positions if the position list is sorted
in ascending order. Then it can be done in one traversal => O(n)"
  input list<Type_a> lst;
  input list<Integer> positions;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := listDeletePositionsSorted2(lst,positions,0);
end listDeletePositionsSorted;

public function listDeletePositionsSorted2 "Help function to listDeletePositionsSorted"
  input list<Type_a> lst;
  input list<Integer> positions;
  input Integer n;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := matchcontinue(lst,positions,n)
  local Type_a l; Integer p;
    case(lst,{},n) then lst;
    case(l::lst,p::positions,n) equation
      true = p == n "remove";
      positions = removeMatchesFirst(positions,n) "allows duplicate position elements";
      lst = listDeletePositionsSorted2(lst,positions,n+1);
    then lst;
    case(l::lst,positions as (p::_),n) equation
      false = p == n "keep";
      lst = listDeletePositionsSorted2(lst,positions,n+1);
    then l::lst;
  end matchcontinue;
end listDeletePositionsSorted2;

protected function removeMatchesFirst "removes all matching elements that occur first in list. If first element doesn't match, return"
input list<Integer> lst;
input Integer n;
output list<Integer> outLst;
algorithm
  outLst := matchcontinue(lst,n)
  local Integer l;
    case(l::lst,n) equation
      true = l == n;
      lst=removeMatchesFirst(lst,n);
    then lst;
    case(lst,n) then lst;
  end matchcontinue;
end removeMatchesFirst;

public function listDeletePositions "Takes a list and a list of positions and deletes the positions from the list.
Note that positions are indexed from 0..n-1

For example listDeletePositions({1,2,3,4,5},{2,0,3}) => {2,5}
"
  input list<Type_a> lst;
  input list<Integer> positions;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := listDeletePositions2(0,lst,positions);
end listDeletePositions;

protected function listDeletePositions2 "help function to listDeletePositions"
  input Integer p;
  input list<Type_a> lst;
  input list<Integer> positions;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := matchcontinue(p,lst,positions)
  local Type_a el;
    case(p,lst,{}) then lst;
    case(p,{},positions) then {};
    case(p,el::lst,positions) equation
      positions = listDeleteMemberF(positions,p);
      lst = listDeletePositions2(p+1,lst,positions);
    then lst;
    case(p,el::lst,positions) equation
        lst = listDeletePositions2(p+1,lst,positions);
    then el::lst;
  end matchcontinue;
end listDeletePositions2;

public function listDeleteMember "function: listDeleteMember
  Takes a list and a value and deletes the first occurence of the value in the list
  Example: listDeleteMember({1,2,3,2},2) => {1,3,2}"
  input list<Type_a> inTypeALst;
  input Type_a inTypeA;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst,inTypeA)
    local
      Integer pos;
      list<Type_a> lst_1,lst;
      Type_a elt;
    case (lst,elt)
      equation
        pos = listPosition(elt, lst);
        lst_1 = listDelete(lst, pos);
      then
        lst_1;
    case (lst,_) then lst;
  end matchcontinue;
end listDeleteMember;

public function listDeleteMemberF "
  Similar to listDeleteMember but fails if element is not present"
  input list<Type_a> inTypeALst;
  input Type_a inTypeA;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst,inTypeA)
    local
      Integer pos;
      list<Type_a> lst_1,lst;
      Type_a elt;
    case (lst,elt)
      equation
        pos = listPosition(elt, lst);
        lst_1 = listDelete(lst, pos);
      then
        lst_1;
  end matchcontinue;
end listDeleteMemberF;

public function listDeleteMemberOnTrue "function: listDeleteMemberOnTrue
  Takes a list and a value and a comparison function and deletes the first
  occurence of the value in the list for which the function returns true.
  Example: listDeleteMemberOnTrue({1,2,3,2},2,intEq) => {1,3,2}"
  input list<Type_a> inTypeALst;
  input Type_a inTypeA;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst,inTypeA,inFuncTypeTypeATypeAToBoolean)
    local
      Type_a elt_1,elt;
      Integer pos;
      list<Type_a> lst_1,lst;
      FuncTypeType_aType_aToBoolean cond;
    case (lst,elt,cond)
      equation
        elt_1 = listGetMemberOnTrue(elt, lst, cond) "A bit ugly" ;
        pos = listPosition(elt_1, lst);
        lst_1 = listDelete(lst, pos);
      then
        lst_1;
    case (lst,_,_) then lst;
  end matchcontinue;
end listDeleteMemberOnTrue;

public function listGetMemberOnTrue "function listGetmemberOnTrue
  Takes a value and a list of values and a comparison function over two values.
  If the value is present in the list (using the comparison function returning true)
  the value is returned, otherwise the function fails.
  Example:
    function equalLength(string,string) returns true if the strings are of same length
    listGetMemberOnTrue(\"a\",{\"bb\",\"b\",\"ccc\"},equalLength) => \"b\""
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm
  outTypeA:=
  matchcontinue (inTypeA,inTypeALst,inFuncTypeTypeATypeAToBoolean)
    local
      FuncTypeType_aType_aToBoolean p;
      Type_a x,y,res;
      list<Type_a> ys;
    case (_,{},p) then fail();
    case (x,(y :: ys),p)
      equation
        true = p(x, y);
      then
        y;
    case (x,(y :: ys),p)
      equation
        false = p(x, y);
        res = listGetMemberOnTrue(x, ys, p);
      then
        res;
  end matchcontinue;
end listGetMemberOnTrue;

public function listUnionElt "function: listUnionElt
  Takes a value and a list of values and inserts the
  value into the list if it is not already in the list.
  If it is in the list it is not inserted.
  Example:
    listUnionElt(1,{2,3}) => {1,2,3}
    listUnionElt(0,{0,1,2}) => {0,1,2}"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeA,inTypeALst)
    local
      Type_a x;
      list<Type_a> lst;
    case (x,lst)
      equation
        _ = listGetMember(x, lst);
      then
        lst;
    case (x,lst)
      equation
        failure(_ = listGetMember(x, lst));
      then
        (x :: lst);
  end matchcontinue;
end listUnionElt;

public function listUnion "function listUnion
  Takes two lists and returns the union of the two lists,
  i.e. a list of all elements combined without duplicates.
  Example: listUnion({0,1},{2,1}) => {0,1,2}"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst1,inTypeALst2)
    local
      list<Type_a> res,r1,xs,lst2;
      Type_a x;
    case ({},{}) then {};
    case ({},x::xs) then listUnionElt(x,listUnion({},xs));
    case ((x :: xs),lst2)
      equation
        r1 = listUnionElt(x, lst2);
        res = listUnion(xs, r1);
      then
        res;
  end matchcontinue;
end listUnion;

public function listListUnion "function: listListUnion
  Takes a list of lists and returns the union of the sublists
  Example: listListUnion({{1},{1,2},{3,4},{5}}) => {1,2,3,4,5}"
  input list<list<Type_a>> inTypeALstLst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALstLst)
    local
      list<Type_a> x,r1,res,x1,x2;
      list<list<Type_a>> rest;
    case ({}) then {};
    case ({x}) then x;
    case ((x1 :: (x2 :: rest)))
      equation
        r1 = listUnion(x1, x2);
        res = listListUnion((r1 :: rest));
      then
        res;
  end matchcontinue;
end listListUnion;

public function listUnionEltOnTrue "function: listUnionEltOnTrue
  Takes an elemement and a list and a comparison function over the two values.
  It returns the list with the element inserted if not already present in the
  list, according to the comparison function.
  Example: listUnionEltOnTrue(1,{2,3},intEq) => {1,2,3}"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm
  outTypeALst:=
  matchcontinue (inTypeA,inTypeALst,inFuncTypeTypeATypeAToBoolean)
    local
      Type_a x;
      list<Type_a> lst;
      FuncTypeType_aType_aToBoolean p;
    case (x,lst,p)
      equation
        _ = listGetMemberOnTrue(x, lst, p);
      then
        lst;
    case (x,lst,p)
      equation
        failure(_ = listGetMemberOnTrue(x, lst, p));
      then
        (x :: lst);
  end matchcontinue;
end listUnionEltOnTrue;

public function equal "
This function is intended to be a replacement for equality,
when sending function as an input argument.
"
  input Type_a arg1;
  input Type_a arg2;
  output Boolean b;
  replaceable type Type_a subtypeof Any;
algorithm b := matchcontinue(arg1,arg2)
  case(arg1,arg2)
    equation
      equality(arg1 = arg2);
    then
      true;
  case(_,_) then false;
end matchcontinue;
end equal;

public function listlistFunc "Function: listlistFunc
If we have one list to apply function over several lists we can use this function.
it takes list A and list<list B a function and an extra argument(maby make extra argument optional).
It uses function(a,b[x],extarg)
Ex:
listlistFunc({1,2,3},{{3,4,5},{3,6,7}},listUnionOntrue,equal);
will act as
listUnionOnTrue({1,2,3},{3,4,5},equal); => {1,2,3,4,5}
then; listUnionOnTrue({1,2,3,4,5},{3,6,7},equal); => {1,2,3,4,5,6,7}
"
  input list<Type_a> inTypeALst1;
  input list<list<Type_a>> inTypeALst2;
  input FuncTypeType_aType_aToType_b inFunc;
  input Type_c extArg;
  output list<Type_a> outTypeALst;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_a subtypeof Any;
    partial function FuncTypeType_aType_aToType_b
    input list<Type_a> inTypeA1;
    input list<Type_a> inTypeA2;
    input Type_c inTypeA2;
    output list<Type_a> outTypeA;
  end FuncTypeType_aType_aToType_b;
algorithm outTypeALst := matchcontinue(inTypeALst1,inTypeALst2,inFunc,extArg)
  local
    list<Type_a> out1;
    list<Type_a> out2;
    list<list<Type_a>> blocks;
    list<Type_a> block_;
  case(inTypeALst1,{},inFunc,extArg) then inTypeALst1;
  case(inTypeALst1, ((block_ as (_::(_)))::blocks) ,inFunc,extArg)
    equation
      out1 = inFunc(inTypeALst1,block_,extArg);
      out2 = listlistFunc(out1,blocks,inFunc,extArg);
      then
        out2;
  case(inTypeALst1, ((block_ as {}) :: blocks) ,inFunc,extArg)
    equation
      out2 = listlistFunc(inTypeALst1,blocks,inFunc,extArg);
    then
      out2;
  case(inTypeALst1, ((block_ as _) :: blocks) ,inFunc,extArg)
    equation
      out1 = inFunc(inTypeALst1,block_,extArg);
      out2 = listlistFunc(out1,blocks,inFunc,extArg);
    then
      out2;
end matchcontinue;
end listlistFunc;

public function listUnionOnTrue "function: listUnionOnTrue
  Takes two lists and a comparison function over two elements of the list.
  It returns the union of the two lists, using the comparison function passed
  as argument to determine identity between two elements.
  Example:
    given the function equalLength(string,string) returning true if the strings are of same length
    listUnionOnTrue({\"a\",\"aa\"},{\"b\",\"bbb\"},equalLength) => {\"a\",\"aa\",\"bbb\"}"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean3;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst1,inTypeALst2,inFuncTypeTypeATypeAToBoolean3)
    local
      list<Type_a> res,r1,xs,lst2;
      FuncTypeType_aType_aToBoolean p;
      Type_a x;
    case ({},res,p) then res;
    case ((x :: xs),lst2,p)
      equation
        r1 = listUnionEltOnTrue(x, lst2, p);
        res = listUnionOnTrue(xs, r1, p);
      then
        res;
  end matchcontinue;
end listUnionOnTrue;

// stefan
public function listRemoveNth
"function: listRemoveNth
	removes the Nth element of a list, starting with index 0
	listRemove({1,2,3,4,5},2) ==> {1,2,4,5}"
	input list<TypeA> inList;
	input Integer inPos;
	output list<TypeA> outList;
	replaceable type TypeA subtypeof Any;
algorithm
  outList := matchcontinue(inList,inPos)
    local
      list<TypeA> lst,res,tmp1,tmp2;
      Integer pos;
    case(lst,pos)
      equation
        true = pos == listLength(lst) - 1;
        res = listStripLast(lst);
      then
        res;
    case(lst,pos)
      equation
        true = pos < listLength(lst) - 1;
        (tmp1,_) = listSplit(lst,pos);
        (_,tmp2) = listSplit(lst,pos + 1);
        res = listAppend(tmp1,tmp2);
      then
        res;
    case(_,_) then fail();
  end matchcontinue;
end listRemoveNth;

public function listRemoveOnTrue "
Go trough a list and when function is true, remove that element.
"
  input Type_a inTypeALst1;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean3;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst1,inTypeALst2,inFuncTypeTypeATypeAToBoolean3)
    local
      list<Type_a> res,r1,xs,lst2;
      FuncTypeType_aType_aToBoolean p;
      Type_a x,y;
    case (x,{},p) then {};
    case (x,y::xs,p)
      equation
         true = p(x,y);
         res = listRemoveOnTrue(x, xs, p);
      then
        res;
    case (x,y::xs,p)
      equation
        false = p(x,y);
        res = listRemoveOnTrue(x, xs, p);
      then
        y::res;
  end matchcontinue;
end listRemoveOnTrue;

public function listIntersectionIntN "provides same functionality as listIntersection, but for integer values between 1 and N
The complexity in this case is O(n)"
  input list<Integer> s1;
  input list<Integer> s2;
  input Integer N;
  output list<Integer> res;
protected Integer[:] a1,a2;
algorithm
  a1:= arrayCreate(N,0);
  a2:= arrayCreate(N,0);
  a1 := listSetPos(s1,a1,1);
  a2 := listSetPos(s2,a2,1);
  res := listIntersectionIntVec(a1,a2,1);
end listIntersectionIntN;

protected function listIntersectionIntVec " help function to listIntersectionIntN"
  input Integer[:] a1;
  input Integer[:] a2;
  input Integer indx;
  output list<Integer> res;
algorithm
  res := matchcontinue(a1,a2,indx)
    case(a1,a2,indx) equation
      true = indx > arrayLength(a1) or indx > arrayLength(a2);
    then {};
    case(a1,a2,indx) equation
      true = a1[indx]==1 and a2[indx]==1;
      res = listIntersectionIntVec(a1,a2,indx+1);
    then indx::res;
    case(a1,a2,indx) equation
      false = a1[indx]==1 and a2[indx]==1;
      res = listIntersectionIntVec(a1,a2,indx+1);
    then res;
  end matchcontinue;
end listIntersectionIntVec;

protected function listSetPos "Help function to listIntersectionIntN"
  input list<Integer> intLst;
  input Integer[:] arr;
  input Integer v;
  output Integer[:] outArr;
algorithm
  outArr := matchcontinue(intLst,arr,v)
  local Integer i;
    case({},arr,v) then arr;
    case(i::intLst,arr,v) equation
      arr = arrayUpdate(arr,i,v);
      arr = listSetPos(intLst,arr,v);
    then arr;
    case(i::_,arr,v) equation
      failure(_ = arrayUpdate(arr,i,1));
      print("Internal error in listSetPos, index = "+&intString(i)+&" but array size is "+&intString(arrayLength(arr))+&"\n");
    then fail();
  end matchcontinue;
end listSetPos;

public function listUnionIntN "provides same functionality as listUnion, but for integer values between 1 and N
The complexity in this case is O(n)"
  input list<Integer> s1;
  input list<Integer> s2;
  input Integer N;
  output list<Integer> res;
protected Integer[:] a1,a2;
algorithm
  a1:= arrayCreate(N,0);
  a2:= arrayCreate(N,0);
  a1 := listSetPos(s1,a1,1);
  a2 := listSetPos(s2,a2,1);
  res := listUnionIntVec(a1,a2,1);
end listUnionIntN;

protected function listUnionIntVec " help function to listIntersectionIntN"
  input Integer[:] a1;
  input Integer[:] a2;
  input Integer indx;
  output list<Integer> res;
algorithm
  res := matchcontinue(a1,a2,indx)
    case(a1,a2,indx) equation
      true = indx > arrayLength(a1) or indx > arrayLength(a2);
    then {};
    case(a1,a2,indx) equation
      true = a1[indx]==1 or a2[indx]==1;
      res = listUnionIntVec(a1,a2,indx+1);
    then indx::res;
    case(a1,a2,indx) equation
      false = a1[indx]==1 or a2[indx]==1;
      res = listUnionIntVec(a1,a2,indx+1);
    then res;
  end matchcontinue;
end listUnionIntVec;

public function listSetDifferenceIntN "provides same functionality as listSetDifference, but for integer values between 1 and N
The complexity in this case is O(n)"
  input list<Integer> s1;
  input list<Integer> s2;
  input Integer N;
  output list<Integer> res;
protected Integer[:] a1,a2;
algorithm
  a1:= arrayCreate(N,0);
  a2:= arrayCreate(N,0);
  a1 := listSetPos(s1,a1,1);
  a2 := listSetPos(s2,a2,1);
  res := listSetDifferenceIntVec(a1,a2,1);
end listSetDifferenceIntN;

protected function listSetDifferenceIntVec " help function to listIntersectionIntN"
  input Integer[:] a1;
  input Integer[:] a2;
  input Integer indx;
  output list<Integer> res;
algorithm
  res := matchcontinue(a1,a2,indx)
    case(a1,a2,indx) equation
      true = indx > arrayLength(a1) or indx > arrayLength(a2);
    then {};
    case(a1,a2,indx) equation
      true = a1[indx] - a2[indx] <> 0;
      res = listSetDifferenceIntVec(a1,a2,indx+1);
    then indx::res;
    case(a1,a2,indx) equation
      false = a1[indx] - a2[indx] <> 0;
      res = listSetDifferenceIntVec(a1,a2,indx+1);
    then res;
  end matchcontinue;
end listSetDifferenceIntVec;

public function listIntersectionOnTrue "function: listIntersectionOnTrue
  Takes two lists and a comparison function over two elements of the list.
  It returns the intersection of the two lists, using the comparison function passed as
  argument to determine identity between two elements.
  Example:
    given the function stringEqual(string,string) returning true if the strings are equal
    listIntersectionOnTrue({\"a\",\"aa\"},{\"b\",\"aa\"},stringEqual) => {\"aa\"}"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean3;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst1,inTypeALst2,inFuncTypeTypeATypeAToBoolean3)
    local
      list<Type_a> res,xs1,xs2;
      Type_a x1;
      FuncTypeType_aType_aToBoolean cond;
    case ({},_,_) then {};
    case ((x1 :: xs1),xs2,cond)
      equation
        _ = listGetMemberOnTrue(x1, xs2, cond);
        res = listIntersectionOnTrue(xs1, xs2, cond);
      then
        (x1 :: res);
    case ((x1 :: xs1),xs2,cond)
      equation
        res = listIntersectionOnTrue(xs1, xs2, cond) "not list_getmember_p(x1,xs2,cond) => _" ;
      then
        res;
  end matchcontinue;
end listIntersectionOnTrue;

public function listSetEqualOnTrue "function: listSetEqualOnTrue
  Takes two lists and a comparison function over two elements of the list.
  It returns true if the two sets are equal, false otherwise."
  input list<Type_a> lst1;
  input list<Type_a> lst2;
  input CompareFunc compare;
  output Boolean equal;
  replaceable type Type_a subtypeof Any;
  partial function CompareFunc
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end CompareFunc;
algorithm
   equal := matchcontinue(lst1,lst2,compare)
     case (lst1,lst2,compare)
       local list<Type_a> lst;
       equation
       	lst = listIntersectionOnTrue(lst1,lst2,compare);
       	true = intEq(listLength(lst), listLength(lst1));
       	true = intEq(listLength(lst), listLength(lst2));
       then true;
     case (_,_,_) then false;
  end matchcontinue;
end listSetEqualOnTrue;

public function listSetDifferenceOnTrue "function: listSetDifferenceOnTrue
  Takes two lists and a comparison function over two elements of the list.
  It returns the set difference of the two lists A-B, using the comparison
  function passed as argument to determine identity between two elements.
  Example:
    given the function string_equal(string,string) returning true if the strings are equal
    listSetDifferenceOnTrue({\"a\",\"b\",\"c\"},{\"a\",\"c\"},string_equal) => {\"b\"}"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean3;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst1,inTypeALst2,inFuncTypeTypeATypeAToBoolean3)
    local
      list<Type_a> a,a_1,a_2,xs;
      FuncTypeType_aType_aToBoolean cond;
      Type_a x1;
    case (a,{},cond) then a;  /* A B */
    case (a,(x1 :: xs),cond)
      equation
        a_1 = listDeleteMemberOnTrue(a, x1, cond);
        a_2 = listSetDifferenceOnTrue(a_1, xs, cond);
      then
        a_2;
    case (_,_,_)
      equation
        print("- Util.listSetDifferenceOnTrue failed\n");
      then
        fail();
  end matchcontinue;
end listSetDifferenceOnTrue;

public function listSetDifference "
  Takes two lists and returns the set difference of the two lists A-B.
  Example:
    listSetDifferenceOnTrue({\"a\",\"b\",\"c\"},{\"a\",\"c\"}) => {\"b\"}
    comparisons is done using the builtin equality mechanism.
    "
  input list<Type_a> A;
  input list<Type_a> B;

  output list<Type_a> res;
  replaceable type Type_a subtypeof Any;
algorithm
  res :=
  matchcontinue (A,B)
    local
      list<Type_a> a,a_1,a_2,xs;
      Type_a x1;
    case (a,{}) then a;  /* A B */
    case (a,(x1 :: xs))
      equation
        a_1 = listDeleteMember(a, x1);
        a_2 = listSetDifference(a_1, xs);
      then
        a_2;
    case (_,_)
      equation
        print("- Util.listSetDifference failed\n");
      then
        fail();
  end matchcontinue;
end listSetDifference;

public function listListUnionOnTrue "function: listListUnionOnTrue
  Takes a list of lists and a comparison function over two elements of the lists.
  It returns the union of all sublists using the comparison function for identity.
  Example: listListUnionOnTrue({{1},{1,2},{3,4}},intEq) => {1,2,3,4}"
  input list<list<Type_a>> inTypeALstLst;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToBoolean
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Boolean outBoolean;
  end FuncTypeType_aType_aToBoolean;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALstLst,inFuncTypeTypeATypeAToBoolean)
    local
      FuncTypeType_aType_aToBoolean p;
      list<Type_a> x,r1,res,x1,x2;
      list<list<Type_a>> rest;
    case ({},p) then {};
    case ({x},p) then x;
    case ((x1 :: (x2 :: rest)),p)
      equation
        r1 = listUnionOnTrue(x1, x2, p);
        res = listListUnionOnTrue((r1 :: rest), p);
      then
        res;
  end matchcontinue;
end listListUnionOnTrue;

// stefan
public function listReplaceAtWithList
"function: listReplaceAtWithList
	Takes a list, a position, and a list to replace that position
	Replaces the element at the position with the given list
	Example: listReplaceAt({\"A\",\"B\"},1,{\"foo\",\"bar\",\"baz\"}) => {\"foo\",\"A\",\"B\",\"baz\"}"
	input list<Type_a> inReplacementList;
	input Integer inPosition;
	input list<Type_a> inList;
	output list<Type_a> outList;
	replaceable type Type_a subtypeof Any;
algorithm
  outList := matchcontinue (inReplacementList,inPosition,inList)
    local
      list<Type_a> rlst,olst,split1,split2,res,res_1;
      Integer n,n_1;
      Type_a foo;
    case(rlst,0,foo :: olst)
      equation
        res = listAppend(rlst,olst);
      then res;
    case(rlst,n,olst)
      equation
        (split1,_) = listSplit(olst,n);
        n_1 = n + 1;
        (_,split2) = listSplit(olst,n_1);
        res = listAppend(split1,rlst);
        res_1 = listAppend(res,split2);
      then
        res_1;
  end matchcontinue;
end listReplaceAtWithList;

public function listReplaceAt "function: listReplaceAt
  Takes an element, a position and a list and replaces the value at the given position in
  the list. Position is an integer between 0 and n-1 for a list of n elements
  Example: listReplaceAt(\"A\", 2, {\"a\",\"b\",\"c\"}) => {\"a\",\"b\",\"A\"}"
  input Type_a inTypeA;
  input Integer inInteger;
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeA,inInteger,inTypeALst)
    local
      Type_a x,y;
      list<Type_a> ys,res;
      Integer nn,n;
    case (x,0,(y :: ys)) then (x :: ys);
    case (x,n,(y :: ys))
      equation
        (n >= 1) = true;
        nn = n - 1;
        res = listReplaceAt(x, nn, ys);
      then
        (y :: res);
  end matchcontinue;
end listReplaceAt;

public function listReplaceAtWithFill "function: listReplaceatWithFill
  Takes
  - an element,
  - a position
  - a list and
  - a fill value
  The function replaces the value at the given position in the list, if the given position is
  out of range, the fill value is used to padd the list up to that element position and then
  insert the value at the position
  Example: listReplaceAtWithFill(\"A\", 5, {\"a\",\"b\",\"c\"},\"dummy\") => {\"a\",\"b\",\"c\",\"dummy\",\"A\"}"
  input Type_a inTypeA1;
  input Integer inInteger2;
  input list<Type_a> inTypeALst3;
  input Type_a inTypeA4;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeA1,inInteger2,inTypeALst3,inTypeA4)
    local
      Type_a x,fillv,y;
      list<Type_a> ys,res,res_1;
      Integer numfills_1,numfills,nn,n,p;
      String pos;
    case (x,0,{},fillv) then {x};
    case (x,0,(y :: ys),fillv) then (x :: ys);
    case (x,1,{},fillv) then {fillv,x};
    case (x,numfills,{},fillv)
      equation
        (numfills > 1) = true;
        numfills_1 = numfills - 1;
        res = listFill(fillv, numfills_1);
        res_1 = listAppend(res, {x});
      then
        res_1;
    case (x,n,(y :: ys),fillv)
      equation
        (n >= 1) = true;
        nn = n - 1;
        res = listReplaceAtWithFill(x, nn, ys, fillv);
      then
        (y :: res);
    case (_,p,_,_)
      equation
        print("- Util.listReplaceAtWithFill failed row: ");
        pos = intString(p);
        print(pos);
        print("\n");
      then
        fail();
  end matchcontinue;
end listReplaceAtWithFill;

public function listReduce "function: listReduce
  Takes a list and a function operating on two elements of the list.
  The function performs a reduction of the lists to a single value using the function.
  Example: listReduce({1,2,3},int_add) => 6"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_aToType_a inFuncTypeTypeATypeAToTypeA;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToType_a
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Type_a outTypeA;
  end FuncTypeType_aType_aToType_a;
algorithm
  outTypeA := matchcontinue (inTypeALst,inFuncTypeTypeATypeAToTypeA)
    local
      Type_a e,res,a,b,res1,res2;
      FuncTypeType_aType_aToType_a r;
      list<Type_a> xs;
    case ({e},r) then e;
    case ({a,b},r)
      equation
        res = r(a, b);
      then
        res;
    case ((a :: (b :: (xs as (_ :: _)))),r)
      equation
        res1 = r(a, b);
        // res = listReduce_tail(xs, r, res1);
        res = listReduce(res1::xs, r);
      then
        res;
    // failure, we can't reduce an empty list!
    case ({},r)
      equation
        Debug.fprintln("failtrace", "- Util.listReduce failed on empty list!");
      then fail();
  end matchcontinue;
end listReduce;

public function listReduce_tail
"function: listReduce_tail
 Takes a list and a function operating on two elements of the list and an accumulator value.
 The function performs a reduction of the lists to a single value using the function.
 Example: listReduce_tail({1,2,3},int_add, 0) => 6"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_aToType_a inFuncTypeTypeATypeAToTypeA;
  input Type_a accumulator;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_aToType_a
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Type_a outTypeA;
  end FuncTypeType_aType_aToType_a;
algorithm
  outTypeA:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeAToTypeA,accumulator)
    local
      Type_a e,res,a,b,res1,res2;
      FuncTypeType_aType_aToType_a r;
      list<Type_a> xs;
    case ({},r,accumulator) then accumulator;
    case ({a},r,accumulator)
      equation
        res = r(accumulator, a);
      then
        res;
    case (a::xs,r,accumulator)
      equation
        res1 = r(accumulator, a);
        res = listReduce_tail(xs, r, res1);
      then
        res;
  end matchcontinue;
end listReduce_tail;


public function arrayReplaceAtWithFill "
  Takes
  - an element,
  - a position (1..n)
  - an array and
  - a fill value
  The function replaces the value at the given position in the array, if the given position is
  out of range, the fill value is used to padd the array up to that element position and then
  insert the value at the position.
  Example:
    arrayReplaceAtWithFill(\"A\", 5, {\"a\",\"b\",\"c\"},\"dummy\") => {\"a\",\"b\",\"c\",\"dummy\",\"A\"}"
  input Type_a inTypeA1;
  input Integer inInteger2;
  input Type_a[:] inTypeAArray3;
  input Type_a inTypeA4;
  output Type_a[:] outTypeAArray;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeAArray:=
  matchcontinue (inTypeA1,inInteger2,inTypeAArray3,inTypeA4)
    local
      Integer alen,pos,pos_1;
      Type_a[:] res,arr,newarr,res_1;
      Type_a x,fillv;
    case (x,pos,arr,fillv)
      equation
        alen = arrayLength(arr) "Replacing element with index in range of the array" ;
        (pos < alen) = true;
        res = arrayUpdate(arr, pos , x);
      then
        res;
    case (x,pos,arr,fillv)
      equation
        pos_1 = pos + 1 "Replacing element out of range of array, create new array, and copy elts." ;
        newarr = fill(fillv, pos_1);
        res = arrayCopy(arr, newarr);
        res_1 = arrayUpdate(res, pos , x);
      then
        res_1;
    case (_,_,_,_)
      equation
        print("- Util.arrayReplaceAtWithFill failed\n");
      then
        fail();
  end matchcontinue;
end arrayReplaceAtWithFill;

public function arrayExpand "function: arrayExpand
  Increases the number of elements of a list with n.
  Each of the new elements have the value v."
  input Integer n;
  input Type_a[:] arr;
  input Type_a v;
  output Type_a[:] newarr_1;
  replaceable type Type_a subtypeof Any;
  Integer len,newlen;
  Type_a[:] newarr,newarr_1;
algorithm
  len := arrayLength(arr);
  newlen := n + len;
  newarr := fill(v, newlen);
  newarr_1 := arrayCopy(arr, newarr);
end arrayExpand;

public function arrayNCopy "function arrayNCopy
  Copeis n elements in src array into dest array
  The function fails if all elements can not be fit into dest array."
  input Type_a[:] src;
  input Type_a[:] dst;
  input Integer n;
  output Type_a[:] dst_1;
  replaceable type Type_a subtypeof Any;
  Integer n_1;
  Type_a[:] dst_1;
algorithm
  n_1 := n - 1;
  dst_1 := arrayCopy2(src, dst, n_1);
end arrayNCopy;

public function arrayAppend "Function: arrayAppend
function for appending two arrays"
  input Type_a[:] arr1;
  input Type_a[:] arr2;
  output Type_a[:] out;
  replaceable type Type_a subtypeof Any;
  list<Type_a> l1,l2,l3;
algorithm
  l1 := arrayList(arr1);
  l2 := arrayList(arr2);
  l3 := listAppend(l1,l2);
  out := listArray(l3);
end arrayAppend;

public function arrayCopy "function: arrayCopy
  copies all values in src array into dest array.
  The function fails if all elements can not be fit into dest array."
  input Type_a[:] inTypeAArray1;
  input Type_a[:] inTypeAArray2;
  output Type_a[:] outTypeAArray;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeAArray:=
  matchcontinue (inTypeAArray1,inTypeAArray2)
    local
      Integer srclen,dstlen;
      Type_a[:] src,dst,dst_1;
    case (src,dst) /* src dst */
      equation
        srclen = arrayLength(src);
        dstlen = arrayLength(dst);
        (srclen > dstlen) = true;
        print(
          "- Util.arrayCopy failed. Can not fit elements into dest array\n");
      then
        fail();
    case (src,dst)
      equation
        srclen = arrayLength(src);
        srclen = srclen - 1;
        dst_1 = arrayCopy2(src, dst, srclen);
      then
        dst_1;
  end matchcontinue;
end arrayCopy;

protected function arrayCopy2
  input Type_a[:] inTypeAArray1;
  input Type_a[:] inTypeAArray2;
  input Integer inInteger3;
  output Type_a[:] outTypeAArray;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeAArray:=
  matchcontinue (inTypeAArray1,inTypeAArray2,inInteger3)
    local
      Type_a[:] src,dst,dst_1,dst_2;
      Type_a elt;
      Integer pos;
    case (src,dst,-1) then dst;  /* src dst current pos */
    case (src,dst,pos)
      equation
        elt = src[pos + 1];
        dst_1 = arrayUpdate(dst, pos + 1, elt);
        pos = pos - 1;
        dst_2 = arrayCopy2(src, dst_1, pos);
      then
        dst_2;
  end matchcontinue;
end arrayCopy2;

public function makeTuple "
Author BZ: 2008-11
Create a tuple list from two lists
"
input list<Type_a> t1;
input list<Type_b> t2;
output list<tuple<Type_a,Type_b>> ot;
replaceable type Type_a subtypeof Any;
replaceable type Type_b subtypeof Any;
algorithm ot := matchcontinue(t1,t2)
  local
    Type_a a;
    Type_b b;
  case({},{}) then {}; // enforce equal length of lists
  case(a::t1,b::t2)
    equation
      ot = makeTuple(t1,t2);
      then
        (a,b)::ot;
  case(_,_) equation print(" failure in makeTuple \n"); then fail();
end matchcontinue;
end makeTuple;

public function tuple21 "function: tuple21
  Takes a tuple of two values and returns the first value.
  Example: tuple21((\"a\",1)) => \"a\""
  input tuple<Type_a, Type_b> inTplTypeATypeB;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeA:=
  matchcontinue (inTplTypeATypeB)
    local Type_a a;
    case ((a,_)) then a;
  end matchcontinue;
end tuple21;

public function tuple22 "function: tuple22
  Takes a tuple of two values and returns the second value.
  Example: tuple22((\"a\",1)) => 1"
  input tuple<Type_a, Type_b> inTplTypeATypeB;
  output Type_b outTypeB;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeB:=
  matchcontinue (inTplTypeATypeB)
    local Type_b b;
    case ((_,b)) then b;
  end matchcontinue;
end tuple22;

public function tuple31 "
  Takes a tuple of three values and returns the first value.
  Example: tuple31((\"a\",1,2)) => \"a\""
  input tuple<Type_a, Type_b,Type_c> tpl;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeA:=
  matchcontinue (tpl)
    local Type_a a;
    case ((a,_,_)) then a;
  end matchcontinue;
end tuple31;

public function tuple32 "
  Takes a tuple of three values and returns the second value.
  Example: tuple32((\"a\",1,2)) => 1 "
  input tuple<Type_a, Type_b,Type_c> tpl;
  output Type_b outTypeB;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeB:=
  matchcontinue (tpl)
    local Type_b b;
    case ((_,b,_)) then b;
  end matchcontinue;
end tuple32;

public function tuple33 "
  Takes a tuple of three values and returns the third value.
  Example: tuple33((\"a\",1,2)) => 2 "
  input tuple<Type_a, Type_b,Type_c> tpl;
  output Type_c outTypeC;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeC:=
  matchcontinue (tpl)
    local Type_c c;
    case ((_,_,c)) then c;
  end matchcontinue;
end tuple33;

public function splitTuple2List "function: splitTuple2List
  Takes a list of two-tuples and splits it into two lists.
  Example: splitTuple2List({(\"a\",1),(\"b\",2),(\"c\",3)}) => ({\"a\",\"b\",\"c\"}, {1,2,3})"
  input list<tuple<Type_a, Type_b>> inTplTypeATypeBLst;
  output list<Type_a> outTypeALst;
  output list<Type_b> outTypeBLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  (outTypeALst,outTypeBLst):=
  matchcontinue (inTplTypeATypeBLst)
    local
      list<Type_a> xs;
      list<Type_b> ys;
      Type_a x;
      Type_b y;
      list<tuple<Type_a, Type_b>> rest;
    case ({}) then ({},{});
    case (((x,y) :: rest))
      equation
        (xs,ys) = splitTuple2List(rest);
      then
        ((x :: xs),(y :: ys));
  end matchcontinue;
end splitTuple2List;

public function filterList "
Author BZ
Taking a list of a generic type and a integer list which are the positions
we are sopposed to remove. The final position is the offset, where to start from(normal = 0 ).
"
  input list<Type_a> lst;
  input list<Integer> positions;
  input Integer pos;
  output list<Type_a> outList;
  replaceable type Type_a subtypeof Any;
algorithm outList := matchcontinue(lst,positions,pos)
  local
    list<Type_a> tail,res;
    Type_a head;
    Integer x;
    list<Integer> xs;
  case({},_,_) then {};
  case(lst,{},_) then lst;
  case(head::tail,x::xs,pos)
    equation
    equality(x=pos);
    res = filterList(tail,xs,pos+1);
    then
      res;
  case(head::tail,x::xs,pos)
    equation
    res = filterList(tail,x::xs,pos+1);
    then
      head::res;
end matchcontinue;
end filterList;

public function if_ "function: if_
  Takes a boolean and two values.
  Returns the first value (second argument) if the boolean value is
  true, otherwise the second value (third argument) is returned.
  Example: if_(true,\"a\",\"b\") => \"a\"
"
  input Boolean inBoolean1;
  input Type_a inTypeA2;
  input Type_a inTypeA3;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeA:=
  matchcontinue (inBoolean1,inTypeA2,inTypeA3)
    local Type_a r;
    case (true,r,_) then r;
    case (false,_,r) then r;
  end matchcontinue;
end if_;

// stefan
public function if_t
"function: if_t
	as with if_, but can return one of two different types of values"
	input Boolean inBoolean;
	input TypeA inTypeA;
	input TypeB inTypeB;
	output tuple<Option<TypeA>, Option<TypeB>> outTuple;
	replaceable type TypeA subtypeof Any;
	replaceable type TypeB subtypeof Any;
algorithm
  outTuple := matchcontinue(inBoolean,inTypeA,inTypeB)
    local
      TypeA resA;
      TypeB resB;
    case(true,resA,_) then ((SOME(resA),NONE));
    case(false,_,resB) then ((NONE,SOME(resB)));
  end matchcontinue;
end if_t;

public function stringContainsChar "Returns true if a string contains a specified character"
  input String str;
  input String char;
  output Boolean res;
algorithm
  res := matchcontinue(str,char)
    case(str,char) equation
      _::_::_ = stringSplitAtChar(str,char);
      then true;
    case(str,char) then false;
  end matchcontinue;
end stringContainsChar;

public function stringAppendList "function stringAppendList
  Takes a list of strings and appends them.
  Example: stringAppendList({\"foo\", \" \", \"bar\"}) => \"foo bar\""
  input list<String> inStringLst;
  output String outString;
algorithm
  outString:= stringAppendList_tail(inStringLst, "");
  /*
  outString:=
  matchcontinue (inStringLst)
    local
      String f,r_1,str;
      list<String> r;
    case {} then "";
    case {f} then f;
    case (f :: r)
      equation
        r_1 = stringAppendList(r);
        str = stringAppend(f, r_1);
      then
        str;
  end matchcontinue;
  */
end stringAppendList;

public function stringAppendList_tail "
@author adrpo
 tail recursive implmentation for stringAppendList"
  input list<String> inStringLst;
  input String accumulator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inStringLst, accumulator)
    local
      String f,str,a;
      list<String> r;
    case ({}, a) then a;
    case (f :: r, a)
      equation
        a = stringAppend(a, f);
        str = stringAppendList_tail(r, a);
      then
        str;
  end matchcontinue;
end stringAppendList_tail;

public function stringDelimitList "function stringDelimitList
  Takes a list of strings and a string delimiter and appends all
  list elements with the string delimiter inserted between elements.
  Example: stringDelimitList({\"x\",\"y\",\"z\"}, \", \") => \"x, y, z\""
  input list<String> inStringLst;
  input String inString;
  output String outString;
algorithm
  outString:=
  matchcontinue (inStringLst,inString)
    local
      String f,delim,str1,str2,str;
      list<String> r;
    case ({},_) then "";
    case ({f},delim) then f;
    case ((f :: r),delim)
      equation
        str1 = stringDelimitList(r, delim);
        str2 = stringAppend(f, delim);
        str = stringAppend(str2, str1);
      then
        str;
  end matchcontinue;
end stringDelimitList;

public function stringDelimitListPrintBuf "
Author: BZ, 2009-11
Same funcitonality as stringDelimitListPrint, but writes to print buffer instead of string variable.
Usefull for heavy string operations(causes malloc error on some models when generating init file).
"
  input list<String> inStringLst;
  input String inString;
algorithm
  _:=
  matchcontinue (inStringLst,inString)
    local
      String f,delim,str1,str2,str;
      list<String> r;
    case ({},_) then ();
    case ({f},delim) equation Print.printBuf(f); then ();
    case ((f :: r),delim)
      equation
        stringDelimitListPrintBuf(r, delim);
        Print.printBuf(f);
        Print.printBuf(delim);

      then
        ();
  end matchcontinue;
end stringDelimitListPrintBuf;

public function stringDelimitListAndSeparate "function: stringDelimitListAndSeparate
  author: PA
  This function is similar to stringDelimitList, i.e it inserts string delimiters between
  consecutive strings in a list. But it also count the lists and inserts a second string delimiter
  when the counter is reached. This can be used when for instance outputting large lists of values
  and a newline is needed after ten or so items."
  input list<String> str;
  input String sep1;
  input String sep2;
  input Integer n;
  output String res;
protected String tmpBuf;
algorithm
  tmpBuf := Print.getString();
  Print.clearBuf();
  stringDelimitListAndSeparate2(str, sep1, sep2, n, 0);
  res := Print.getString();
  Print.clearBuf();
  Print.printBuf(tmpBuf);
end stringDelimitListAndSeparate;

protected function stringDelimitListAndSeparate2 "function: stringDelimitListAndSeparate2
  author: PA
  Helper function to stringDelimitListAndSeparate"
  input list<String> inStringLst1;
  input String inString2;
  input String inString3;
  input Integer inInteger4;
  input Integer inInteger5;
algorithm
  outString:=
  matchcontinue (inStringLst1,inString2,inString3,inInteger4,inInteger5)
    local
      String s,str1,str,f,sep1,sep2;
      list<String> r;
      Integer n,iter_1,iter;
    case ({},_,_,_,_) then ();  /* iterator */
    case ({s},_,_,_,_) equation
      Print.printBuf(s);
    then ();
    case ((f :: r),sep1,sep2,n,0)
      equation
        Print.printBuf(f);Print.printBuf(sep1);
        stringDelimitListAndSeparate2(r, sep1, sep2, n, 1) "special case for first element" ;
      then
        ();
    case ((f :: r),sep1,sep2,n,iter)
      equation
        0 = intMod(iter, n) "insert second delimiter" ;
        iter_1 = iter + 1;
        Print.printBuf(f);Print.printBuf(sep1);Print.printBuf(sep2);
        stringDelimitListAndSeparate2(r, sep1, sep2, n, iter_1);
      then
        ();
    case ((f :: r),sep1,sep2,n,iter)
      equation
        iter_1 = iter + 1 "not inserting second delimiter" ;
        Print.printBuf(f);Print.printBuf(sep1);
        stringDelimitListAndSeparate2(r, sep1, sep2, n, iter_1);
      then
        ();
    case (_,_,_,_,_)
      equation
        print("- Util.stringDelimitListAndSeparate2 failed\n");
      then
        fail();
  end matchcontinue;
end stringDelimitListAndSeparate2;

public function stringDelimitListNonEmptyElts "function stringDelimitListNonEmptyElts
  Takes a list of strings and a string delimiter and appends all list elements with
  the string delimiter inserted between those elements that are not empty.
  Example: stringDelimitListNonEmptyElts({\"x\",\"\",\"z\"}, \", \") => \"x, z\""
  input list<String> lst;
  input String delim;
  output String str;
  list<String> lst1;
algorithm
  lst1 := listSelect(lst, isNotEmptyString);
  str := stringDelimitList(lst1, delim);
end stringDelimitListNonEmptyElts;

public function stringReplaceChar "function stringReplaceChar
  Takes a string and two chars and replaces the first char with the second char:
  Example: string_replace_char(\"hej.b.c\",\".\",\"_\") => \"hej_b_c\"
  2007-11-26 BZ: Now it is possible to replace chars with emptychar, and
                 replace a char with a string
  Example: string_replace_char(\"hej.b.c\",\".\",\"_dot_\") => \"hej_dot_b_dot_c\"
  "
  input String inString1;
  input String inString2;
  input String inString3;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString1,inString2,inString3)
    local
      list<String> strList,resList;
      String res,str;
      String fromChar,toChar;
    case (str,fromChar,toChar)
      equation
        strList = string_list_string_char(str);
        resList = stringReplaceChar2(strList, fromChar, toChar);
        res = string_char_list_string(resList);
      then
        res;
    case (strList,_,_)
      local String strList;
      equation
        print("- Util.stringReplaceChar failed\n");
      then
        strList;
  end matchcontinue;
end stringReplaceChar;

protected function stringReplaceChar2
  input list<String> inStringLst1;
  input String inString2;
  input String inString3;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inStringLst1,inString2,inString3)
    local
      list<String> res,rest,strList, charList2;
      String firstChar,fromChar,toChar;
    case ({},_,_) then {};
    case ((firstChar :: rest),fromChar,"") // added special case for removal of char.
      equation
        equality(firstChar = fromChar);
        res = stringReplaceChar2(rest, fromChar, "");
      then
        (res);
    case ((firstChar :: rest),fromChar,toChar)
      equation
        equality(firstChar = fromChar);
        res = stringReplaceChar2(rest, fromChar, toChar);
        charList2 = string_list_string_char(toChar);
        res = listAppend(charList2,res);
      then
        res;

    case ((firstChar :: rest),fromChar,toChar)
      equation
        failure(equality(firstChar = fromChar));
        res = stringReplaceChar2(rest, fromChar, toChar);
      then
        (firstChar :: res);
    case (strList,_,_)
      equation
        print("- Util.stringReplaceChar2 failed\n");
      then
        strList;
  end matchcontinue;
end stringReplaceChar2;

public function stringSplitAtChar "function stringSplitAtChar
  Takes a string and a char and split the string at the char returning the list of components.
  Example: stringSplitAtChar(\"hej.b.c\",\".\") => {\"hej,\"b\",\"c\"}"
  input String inString1;
  input String inString2;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inString1,inString2)
    local
      list<String> chrList;
      list<String> stringList;
      String str,strList;
      String chr;
    case (str,chr)
      equation
        chrList = string_list_string_char(str);
        stringList = stringSplitAtChar2(chrList, chr, {}) "listString(resList) => res" ;
      then
        stringList;
    case (strList,_) then {strList};
  end matchcontinue;
end stringSplitAtChar;

protected function stringSplitAtChar2
  input list<String> inStringLst1;
  input String inString2;
  input list<String> inStringLst3;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inStringLst1,inString2,inStringLst3)
    local
      list<String> chr_rest_1,chr_rest,chrList,rest,strList;
      String res;
      list<String> res_str;
      String firstChar,chr;
    case ({},_,chr_rest)
      equation
        chr_rest_1 = listReverse(chr_rest);
        res = string_char_list_string(chr_rest_1);
      then
        {res};
    case ((firstChar :: rest),chr,chr_rest)
      equation
        equality(firstChar = chr);
        chrList = listReverse(chr_rest) "this is needed because it returns the reversed list" ;
        res = string_char_list_string(chrList);
        res_str = stringSplitAtChar2(rest, chr, {});
      then
        (res :: res_str);
    case ((firstChar :: rest),chr,chr_rest)
      local list<String> res;
      equation
        failure(equality(firstChar = chr));
        res = stringSplitAtChar2(rest, chr, (firstChar :: chr_rest));
      then
        res;
    case (strList,_,_)
      equation
        print("- Util.stringSplitAtChar2 failed\n");
      then
        fail();
  end matchcontinue;
end stringSplitAtChar2;

public function modelicaStringToCStr "function modelicaStringToCStr
 this replaces symbols that are illegal in C to legal symbols
 see replaceStringPatterns to see the format. (example: \".\" becomes \"$P\")
  author: x02lucpo"
  input String str;
  input Boolean changeDerCall "if true, first change 'DER(v)' to $derivativev";
  output String res_str;
algorithm

  res_str := matchcontinue(str,changeDerCall)
    case(str,false) // BoschRexroth specifics
      equation
        false = OptManager.getOption("translateDAEString");
        then
          str;
    case(str,false)
      equation
        res_str = "$"+& modelicaStringToCStr1(str, replaceStringPatterns);
        // debug_print("prefix$", res_str);
      then res_str;
    case(str,true) equation
      str = modelicaStringToCStr2(str);
    then str;
  end matchcontinue;
end modelicaStringToCStr;

protected function modelicaStringToCStr2 "help function to modelicaStringToCStr,
first  changes name 'der(v)' to $derivativev and 'pre(v)' to 'pre(v)' with applied rules for v"
  input String derName;
  output String outDerName;
algorithm
  outDerName := matchcontinue(derName)
  local
    String name;
    list<String> names;
    case(derName) equation
      0 = System.strncmp(derName,"der(",4);
      // adrpo: 2009-09-08
      // the commented text: _::name::_ = listLast(System.strtok(derName,"()"));
      // is wrong as der(der(x)) ends up beeing translated to $der$der instead
      // of $der$der$x. Changed to the following 2 lines below!
      _::names = (System.strtok(derName,"()"));
      names = listMap1(names, modelicaStringToCStr, false);
      name = DAELow.derivativeNamePrefix +& stringAppendList(names);
    then name;
    case(derName) equation
      0 = System.strncmp(derName,"pre(",4);
      _::name::_= System.strtok(derName,"()");
      name = "pre(" +& modelicaStringToCStr(name,false) +& ")";
    then name;
    case(derName) then modelicaStringToCStr(derName,false);
  end matchcontinue;
end modelicaStringToCStr2;

protected function modelicaStringToCStr1 ""
  input String inString;
  input list<ReplacePattern> inReplacePatternLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString,inReplacePatternLst)
    local
      String str,str_1,res_str,from,to;
      list<ReplacePattern> res;
    case (str,{}) then str;
    case (str,(REPLACEPATTERN(from = from,to = to) :: res))
      equation
        str_1 = modelicaStringToCStr1(str, res);
        res_str = System.stringReplace(str_1, from, to);
      then
        res_str;
    case (str,_)
      equation
        print("- Util.modelicaStringToCStr1 failed for str:"+&str+&"\n");
      then
        fail();
  end matchcontinue;
end modelicaStringToCStr1;

public function cStrToModelicaString "function cStrToModelicaString
 this replaces symbols that have been replace to correct value for modelica string
 see replaceStringPatterns to see the format. (example: \"$p\" becomes \".\")
  author: x02lucpo"
  input String str;
  output String res_str;
algorithm
  res_str := cStrToModelicaString1(str, replaceStringPatterns);
end cStrToModelicaString;

protected function cStrToModelicaString1
  input String inString;
  input list<ReplacePattern> inReplacePatternLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString,inReplacePatternLst)
    local
      String str,str_1,res_str,from,to;
      list<ReplacePattern> res;
    case (str,{}) then str;
    case (str,(REPLACEPATTERN(from = from,to = to) :: res))
      equation
        str_1 = cStrToModelicaString1(str, res);
        res_str = System.stringReplace(str_1, to, from);
      then
        res_str;
  end matchcontinue;
end cStrToModelicaString1;

public function boolOrList "function boolOrList
  Takes a list of boolean values and applies the boolean OR operator  to the list elements
  Example:
    boolOrList({true,false,false})  => true
    boolOrList({false,false,false}) => false"
  input list<Boolean> inBooleanLst;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inBooleanLst)
    local
      Boolean b,res;
      list<Boolean> rest;
    case({}) then false;
    case ({b}) then b;
    case ((true :: rest))  then true;
    case ((false :: rest)) then boolOrList(rest);
  end matchcontinue;
end boolOrList;

public function boolAndList "function: boolAndList
  Takes a list of boolean values and applies the boolean AND operator on the elements
  Example:
  boolAndList({}) => true
  boolAndList({true, true}) => true
  boolAndList({false,false,true}) => false"
  input list<Boolean> inBooleanLst;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inBooleanLst)
    local
      Boolean b,res;
      list<Boolean> rest;
    case({}) then true;
    case ({b}) then b;
    case ((false :: rest)) then false;
    case ((true :: rest))  then boolAndList(rest);
  end matchcontinue;
end boolAndList;

public function boolString "function: boolString
  Takes a boolean value and returns a string representation of the boolean value.
  Example: boolString(true) => \"true\""
  input Boolean inBoolean;
  output String outString;
algorithm
  outString:=
  matchcontinue (inBoolean)
    case true  then "true";
    case false then "false";
  end matchcontinue;
end boolString;

public function boolEqual "Returns true if two booleans are equal, false otherwise"
	input Boolean b1;
	input Boolean b2;
	output Boolean res;
algorithm
  res := matchcontinue(b1,b2)
    case (true,  true)  then true;
    case (false, false) then true;
    case (_,_) then false;
  end matchcontinue;
end boolEqual;

/*
adrpo - 2007-02-19 this function already exists in MMC/RML
public function stringEqual "function: stringEqual
  Takes two strings and returns true if the strings are equal
  Example: stringEqual(\"a\",\"a\") => true"
  input String inString1;
  input String inString2;
  output Boolean outBoolean;
algorithm
  outBoolean:= inString1 ==& intString2;
end stringEqual;
*/

public function listFilter
"function: listFilter
  Takes a list of values and a filter function over the values and
  returns a sub list of values for which the matching function succeeds.
  Example:
    given function is_numeric(string) => ()  which succeeds if the string is numeric.
    listFilter({\"foo\",\"1\",\"bar\",\"4\"},is_numeric) => {\"1\",\"4\"}"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm
  outTypeALst:= listFilter_tail(inTypeALst, inFuncTypeTypeATo, {});
  /*
  matchcontinue (inTypeALst,inFuncTypeTypeATo)
    local
      list<Type_a> vl_1,vl;
      Type_a v;
      FuncTypeType_aTo cond;
    case ({},_) then {};
    case ((v :: vl),cond)
      equation
        cond(v);
        vl_1 = listFilter(vl, cond);
      then
        (v :: vl_1);
    case ((v :: vl),cond)
      equation
        failure(cond(v));
        vl_1 = listFilter(vl, cond);
      then
        vl_1;
  end matchcontinue;
  */
end listFilter;

public function listFilter1
"Author BZ
  Same as listFilter, but with an extra argument
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input Type_b extraArg;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
    input Type_b inTypeB;
  end FuncTypeType_aTo;
algorithm outTypeALst:= listFilter1_tail(inTypeALst, inFuncTypeTypeATo, {},extraArg);
end listFilter1;

public function listAddElementFirst "
Author: BZ, 2008-07 Adds an element first to a list.
"
input Type_a inElem;
input list<Type_a> inList;
output list<Type_a> outList;
replaceable type Type_a subtypeof Any;
algorithm outList := inElem::inList;
end listAddElementFirst;

public function listFilter_tail
"function: listFilter_tail
 @author adrpo
 tail recursive implementation of listFilter"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input list<Type_a> accTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst,inFuncTypeTypeATo,accTypeALst)
    local
      list<Type_a> vl_1,vl;
      Type_a v;
      FuncTypeType_aTo cond;
    case ({},_,accTypeALst) then accTypeALst;
    case ((v :: vl), cond, accTypeALst)
      equation
        cond(v);
        accTypeALst = listAppend(accTypeALst, {v});
        vl_1 = listFilter_tail(vl, cond, accTypeALst);
      then
        (vl_1);
    case ((v :: vl),cond, accTypeALst)
      equation
        failure(cond(v));
        vl_1 = listFilter_tail(vl, cond, accTypeALst);
      then
        vl_1;
  end matchcontinue;
end listFilter_tail;

public function listFilter1_tail
"function: listFilter_tail
 @author bz
 tail recursive implementation of listFilter"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input list<Type_a> accTypeALst;
  input Type_b extraArg;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
    input Type_b inTypeB;
  end FuncTypeType_aTo;
algorithm outTypeALst := matchcontinue (inTypeALst,inFuncTypeTypeATo,accTypeALst,extraArg)
    local
      list<Type_a> vl_1,vl;
      Type_a v;
      FuncTypeType_aTo cond;
    case ({},_,accTypeALst,extraArg) then accTypeALst;
    case ((v :: vl), cond, accTypeALst,extraArg)
      equation
        cond(v,extraArg);
        accTypeALst = listAppend(accTypeALst, {v});
        vl_1 = listFilter1_tail(vl, cond, accTypeALst,extraArg);
      then
        (vl_1);
    case ((v :: vl),cond, accTypeALst,extraArg)
      equation
        failure(cond(v,extraArg));
        vl_1 = listFilter1_tail(vl, cond, accTypeALst,extraArg);
      then
        vl_1;
  end matchcontinue;
end listFilter1_tail;

public function listFilterBoolean
"function: listFilterBoolean
 @author adrpo
  Takes a list of values and a filter function over the values and
  returns a sub list of values for which the matching function returns true.
  Example:
    given function is_numeric(string) => Boolean  which returns true if the string is numeric.
    listFilter({\"foo\",\"1\",\"bar\",\"4\"},is_numeric) => {\"1\",\"4\"}"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToBoolean inFuncTypeTypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToBoolean
    input Type_a inTypeA;
    output Boolean result;
  end FuncTypeType_aToBoolean;
algorithm
  outTypeALst:= listFilterBoolean_tail(inTypeALst, inFuncTypeTypeAToBoolean, {});
end listFilterBoolean;

public function listFilterBoolean_tail
"function: listFilter_tail
 @author adrpo
 tail recursive implementation of listFilterBoolean"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToBoolean inFuncTypeTypeAToBoolean;
  input list<Type_a> accTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToBoolean
    input Type_a inTypeA;
    output Boolean result;
  end FuncTypeType_aToBoolean;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst,inFuncTypeTypeAToBoolean,accTypeALst)
    local
      list<Type_a> vl_1,vl;
      Type_a v;
      FuncTypeType_aToBoolean cond;
    case ({}, _, accTypeALst) then accTypeALst;
    case ((v :: vl), cond, accTypeALst)
      equation
        true = cond(v);
        accTypeALst = listAppend(accTypeALst, {v});
        vl_1 = listFilterBoolean_tail(vl, cond, accTypeALst);
      then
        (vl_1);
    case ((v :: vl), cond, accTypeALst)
      equation
        false = cond(v);
        vl_1 = listFilterBoolean_tail(vl, cond, accTypeALst);
      then
        vl_1;
  end matchcontinue;
end listFilterBoolean_tail;

public function applyOption "function: applyOption
  Takes an option value and a function over the value.
  It returns in another option value, resulting
  from the application of the function on the value.
  Example:
    applyOption(SOME(1), intString) => SOME(\"1\")
    applyOption(NONE,    intString) => NONE"
  input Option<Type_a> inTypeAOption;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  output Option<Type_b> outTypeBOption;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aToType_b;
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeBOption:=
  matchcontinue (inTypeAOption,inFuncTypeTypeAToTypeB)
    local
      Type_b b;
      Type_a a;
      FuncTypeType_aToType_b rel;
    case (NONE,_) then NONE;
    case (SOME(a),rel)
      equation
        b = rel(a);
      then
        SOME(b);
  end matchcontinue;
end applyOption;

public function makeOption "function makeOption
  Makes a value into value option, using SOME(value)"
  input Type_a inTypeA;
  output Option<Type_a> outTypeAOption;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeAOption:= SOME(inTypeA);
end makeOption;

public function stringOption "function: stringOption
  author: PA
  Returns string value or empty string from string option."
  input Option<String> inStringOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inStringOption)
    local String s;
    case (NONE) then "";
    case (SOME(s)) then s;
  end matchcontinue;
end stringOption;

public function getOption "
  author: PA
  Returns an option value if SOME, otherwise fails"
  input Option<Type_a> inOption;
  output Type_a unOption;
  replaceable type Type_a subtypeof Any;
algorithm
  unOption:=
  matchcontinue (inOption)
    local Type_a item;
    case (SOME(item)) then item;
  end matchcontinue;
end getOption;

public function getOptionOrDefault
"Returns an option value if SOME, otherwise the default"
  input Option<Type_a> inOption;
  input Type_a default;
  output Type_a unOption;
  replaceable type Type_a subtypeof Any;
algorithm
  unOption := matchcontinue (inOption,default)
    local Type_a item;
    case (SOME(item),_) then item;
    case (_,default) then default;
  end matchcontinue;
end getOptionOrDefault;

public function genericOption "function: genericOption
  author: BZ
  Returns a list with single value or an empty list if there is no optional value."
  input Option<Type_a> inOption;
  output list<Type_a> unOption;
  replaceable type Type_a subtypeof Any;
algorithm unOption := matchcontinue (inOption)
    local Type_a item;
    case (NONE) then {};
    case (SOME(item)) then {item};
  end matchcontinue;
end genericOption;

public function makeOptIfNonEmptyList "function: stringOption
  author: BZ
  Construct a Option<Type_a> if the list contains one and only one element. If more, error. On empty=>NONE"
  input list<Type_a> unOption;
  output Option<Type_a> inOption;
  replaceable type Type_a subtypeof Any;
algorithm inOption := matchcontinue (unOption)
    local Type_a item;
    case ({}) then NONE;
    case ({item}) then SOME(item);
  end matchcontinue;
end makeOptIfNonEmptyList;

public function listSplitOnTrue "Splits a list into two sublists depending on predicate function"
  input list<Type_a> lst;
  input predicateFunc f;
  output list<Type_a> tlst;
  output list<Type_a> flst;

  replaceable type Type_a subtypeof Any;
  partial function predicateFunc
    input Type_a inTypeA1;
    output Boolean outBoolean;
  end predicateFunc;
algorithm
  (tlst,flst) := matchcontinue(lst,f)
  local Type_a l;
    case({},f) then ({},{});

    case(l::lst,f) equation
      true = f(l);
      (tlst,flst) = listSplitOnTrue(lst,f);
    then (l::tlst,flst);

    case(l::lst,f) equation
      false = f(l);
      (tlst,flst) = listSplitOnTrue(lst,f);
    then (tlst,l::flst);
  end matchcontinue;
end listSplitOnTrue;

public function listSplitOnTrue1 "Splits a list into two sublists depending on predicate function
which takes one extra argument "
  input list<Type_a> lst;
  input predicateFunc f;
  input Type_b b;
  output list<Type_a> tlst;
  output list<Type_a> flst;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function predicateFunc
    input Type_a inTypeA1;
    input Type_b inTypeb;
    output Boolean outBoolean;
  end predicateFunc;
algorithm
  (tlst,flst) := matchcontinue(lst,f,b)
  local Type_a l;
    case({},f,b) then ({},{});

    case(l::lst,f,b) equation
      true = f(l,b);
      (tlst,flst) = listSplitOnTrue1(lst,f,b);
    then (l::tlst,flst);

    case(l::lst,f,b) equation
      false = f(l,b);
      (tlst,flst) = listSplitOnTrue1(lst,f,b);
    then (tlst,l::flst);
  end matchcontinue;
end listSplitOnTrue1;

public function listSplitOnTrue2 "Splits a list into two sublists depending on predicate function
which takes two extra arguments "
  input list<Type_a> lst;
  input predicateFunc f;
  input Type_b b;
  input Type_c c;
  output list<Type_a> tlst;
  output list<Type_a> flst;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  partial function predicateFunc
    input Type_a inTypeA1;
    input Type_b inTypeb;
    input Type_c inTypec;
    output Boolean outBoolean;
  end predicateFunc;
algorithm
  (tlst,flst) := matchcontinue(lst,f,b,c)
  local Type_a l;
    case({},f,b,c) then ({},{});

    case(l::lst,f,b,c) equation
      true = f(l,b,c);
      (tlst,flst) = listSplitOnTrue2(lst,f,b,c);
    then (l::tlst,flst);

    case(l::lst,f,b,c) equation
      false = f(l,b,c);
      (tlst,flst) = listSplitOnTrue2(lst,f,b,c);
    then (tlst,l::flst);
  end matchcontinue;
end listSplitOnTrue2;

public function listSplitEqualParts "function: listSplitEqualParts
  Takes a list of values and an position value.
  The function returns the list splitted into two lists at the position given as argument.
  Example: listSplit({1,2,5,7},2) => ({1,2},{5,7})"
  input list<Type_a> inTypeALst;
  input Integer inInteger;
  output list<list<Type_a>> outTypeALst1;
  replaceable type Type_a subtypeof Any;
algorithm
  (outTypeALst1,outTypeALst2):=
  matchcontinue (inTypeALst,inInteger)
    local
      list<Type_a> a,b,c;
      Integer length,index,divider,splitLength;
    case (a,0) then {};
    case(a,divider)
      equation
        0 = intMod(listLength(a),divider);
        splitLength = listLength(a) / divider;
        outTypeALst1 = listSplitEqualParts2(a,splitLength);
        then
          outTypeALst1;
    case(a,divider)
      equation
        true = (intMod(listLength(a),divider) > 0);
        print(" split list into non integersize not possible(call to listSplitEqualParts)\n");
      then
        fail();
  end matchcontinue;
end listSplitEqualParts;

protected function listSplitEqualParts2 "function: listSplitEqualParts
  Takes a list of values and an position value.
  The function returns the list splitted into two lists at the position given as argument.
  Example: listSplit({1,2,5,7},2) => ({1,2},{5,7})"
  input list<Type_a> inTypeALst;
  input Integer inInteger;
  output list<list<Type_a>> outTypeALst1;
  replaceable type Type_a subtypeof Any;
algorithm
  (outTypeALst1,outTypeALst2):=
  matchcontinue (inTypeALst,inInteger)
    local
      list<Type_a> a,b,c;
      Integer index,divider,splitLength;
      list<list<Type_a>> rec;
    case ({},_) then {};
    case(a,divider)
      equation
        (c,b) = listSplit2(a, {}, divider);
        rec = listSplitEqualParts2(c,divider);
        rec = listAppend({b},rec);
        then
          rec;
  end matchcontinue;
end listSplitEqualParts2;

public function listSplit "function: listSplit
  Takes a list of values and an position value.
  The function returns the list splitted into two lists at the position given as argument.
  Example: listSplit({1,2,5,7},2) => ({1,2},{5,7})"
  input list<Type_a> inTypeALst;
  input Integer inInteger;
  output list<Type_a> outTypeALst1;
  output list<Type_a> outTypeALst2;
  replaceable type Type_a subtypeof Any;
algorithm
  (outTypeALst1,outTypeALst2):=
  matchcontinue (inTypeALst,inInteger)
    local
      list<Type_a> a,b,c;
      Integer length,index;
    case (a,0) then ({},a);
    case (a,index)
      equation
        length = listLength(a);
        (index > length) = true;
        print("Index out of bounds (greater than list length) in relation listSplit\n");
      then
        fail();
    case (a,index)
      equation
        (index < 0) = true;
        print("Index out of bounds (less than zero) in relation listSplit\n");
      then
        fail();
    case (a,index)
      equation
        (index >= 0) = true;
        length = listLength(a);
        (index <= length) = true;
        (b,c) = listSplit2(a, {}, index);
      then
        (c,b);
  end matchcontinue;
end listSplit;

protected function listSplit2 "helper function to listSplit"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input Integer inInteger3;
  output list<Type_a> outTypeALst1;
  output list<Type_a> outTypeALst2;
  replaceable type Type_a subtypeof Any;
algorithm
  (outTypeALst1,outTypeALst2):=
  matchcontinue (inTypeALst1,inTypeALst2,inInteger3)
    local
      list<Type_a> a,b,c,d,rest;
      Integer index,new_index;
    case (a,b,index)
      equation
        (index == 0) = true;
      then
        (a,b);
    case ((a :: rest),b,index)
      local Type_a a;
      equation
        new_index = index - 1;
        c = listAppend(b, {a});
        (c,d) = listSplit2(rest, c, new_index);
      then
        (c,d);
    case (_,_,_)
      equation
        print("- Util.listSplit2 failed\n");
      then
        fail();
  end matchcontinue;
end listSplit2;

public function intPositive "function: intPositive
  Returns true if integer value is positive (>= 0)"
  input Integer v;
  output Boolean res;
algorithm
  res := (v >= 0);
end intPositive;

public function optionToList "function: optionToList
  Returns an empty list for NONE and a list containing
  the element for SOME(element). To use with listAppend"
  input Option<Type_a> inTypeAOption;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeAOption)
    local Type_a e;
    case NONE then {};
    case SOME(e) then {e};
  end matchcontinue;
end optionToList;

public function flattenOption "function: flattenOption
  Returns the second argument if NONE or the element in SOME(element)"
  input Option<Type_a> inTypeAOption;
  input Type_a inTypeA;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeA := matchcontinue (inTypeAOption,inTypeA)
    local Type_a n,c;
    case (NONE,n) then n;
    case (SOME(c),n) then c;
  end matchcontinue;
end flattenOption;

public function isEmptyArray " isArrayEmpty"
  input list<Type_a> lst;
  replaceable type Type_a subtypeof Any;
  output Boolean b;
algorithm
  b := matchcontinue(lst)
    case({}) then true;
    case(_::_) then false;
  end matchcontinue;
end isEmptyArray;

public function isEmptyString "function: isEmptyString
  Returns true if string is the empty string."
  input String inString;
  output Boolean outBoolean;
algorithm
  outBoolean := stringEqual(inString, "");
end isEmptyString;

public function isNotEmptyString "function: isNotEmptyString
  Returns true if string is not the empty string."
  input String inString;
  output Boolean outBoolean;
algorithm
  outBoolean := boolNot(stringEqual(inString, ""));
end isNotEmptyString;

public function writeFileOrErrorMsg "function: writeFileOrErrorMsg
  This function tries to write to a file and if it fails then it
  outputs \"# Cannot write to file: <filename>.\" to errorBuf"
  input String inString1;
  input String inString2;
algorithm
  _:=
  matchcontinue (inString1,inString2)
    local String filename,str,error_str;
    case (filename,str) /* filename the string to be written */
      equation
        System.writeFile(filename, str);
      then
        ();
    case (filename,str)
      equation
        error_str = stringAppendList({"# Cannot write to file: ",filename,"."});
        Print.printErrorBuf(error_str);
      then
        ();
  end matchcontinue;
end writeFileOrErrorMsg;

public function systemCallWithErrorMsg "
  This function executes a command with System.systemCall
  if System.systemCall does not return 0 then the msg
  is outputed to errorBuf and the function fails."
  input String inString1;
  input String inString2;
algorithm
  _:=
  matchcontinue (inString1,inString2)
    local String s_call,e_msg;
    case (s_call,_) /* command errorMsg to errorBuf if fail */
      equation
        0 = System.systemCall(s_call);
      then
        ();
    case (_,e_msg)
      equation
        Print.printErrorBuf(e_msg);
      then
        fail();
  end matchcontinue;
end systemCallWithErrorMsg;

/* adrpo - 2007-02-19 - not used anymore
public function charListCompare "function: charListCompare
  Compares two char lists up to the nth
  position and returns true if they are equal."
  input list<String> inStringLst1;
  input list<String> inStringLst2;
  input Integer inInteger3;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inStringLst1,inStringLst2,inInteger3)
    local
      String a,b;
      Integer n1,n;
      list<String> l1,l2;
    case ((a :: _),(b :: _),1) then stringEqual(a, b);
    case ((a :: l1),(b :: l2),n)
      equation
        n1 = n - 1;
        true = stringEqual(a, b);
        true = charListCompare(l1, l2, n1);
      then
        true;
    case (_,_,_) then false;
  end matchcontinue;
end charListCompare;
*/
public function strncmp "function: strncmp
  Compare two strings up to the nth character
  Returns true if they are equal."
  input String inString1;
  input String inString2;
  input Integer inInteger3;
  output Boolean outBoolean;
algorithm
  outBoolean := (0==System.strncmp(inString1,inString2,inInteger3));
  /*
  matchcontinue (inString1,inString2,inInteger3)
    local
      list<String> clst1,clst2;
      Integer s1len,s2len,n;
      String s1,s2;
    case (s1,s2,n)
      equation
        clst1 = string_list_string_char(s1);
        clst2 = string_list_string_char(s2);
        s1len = stringLength(s1);
        s2len = stringLength(s2);
        (s1len >= n) = true;
        (s2len >= n) = true;
        true = charListCompare(clst1, clst2, n);
      then
        true;
    case (_,_,_) then false;
  end matchcontinue;
  */
end strncmp;

public function tickStr "function: tickStr
  author: PA
  Returns tick as a string, i.e. an unique number."
  output String s;
algorithm
  s := intString(tick());
end tickStr;

protected function replaceSlashWithPathDelimiter "function replaceSlashWithPathDelimiter
  author: x02lucpo
  replace the / with the system-pathdelimiter.
  On Windows must be \\ so that the function getAbsoluteDirectoryAndFile works"
  input String str;
  output String ret_string;
  String pd;
algorithm
  pd := System.pathDelimiter();
  ret_string := System.stringReplace(str, "/", pd);
end replaceSlashWithPathDelimiter;

public function getAbsoluteDirectoryAndFile "function getAbsoluteDirectoryAndFile
  author: x02lucpo
  splits the filepath in directory and filename
  (\"c:\\programs\\file.mo\") => (\"c:\\programs\",\"file.mo\")
  (\"..\\work\\file.mo\") => (\"c:\\openmodelica123\\work\", \"file.mo\")"
  input String inString;
  output String outString1;
  output String outString2;
algorithm
  (outString1,outString2):=
  matchcontinue (inString)
    local
      String file,pd,list_path,res,file_1,file_path,dir_path,current_dir,name;
      String pd_chr;
      list<String> list_path_1;
    case (file_1)
      equation
        file = replaceSlashWithPathDelimiter(file_1);
        pd = System.pathDelimiter();
        /* (pd_chr :: {}) = string_list_string_char(pd); */
        (list_path :: {}) = stringSplitAtChar(file, pd) "same dir only filename as param" ;
        res = System.pwd();
      then
        (res,list_path);
    case (file_1)
      local list<String> list_path;
      equation
        file = replaceSlashWithPathDelimiter(file_1);
        pd = System.pathDelimiter();
        /* (pd_chr :: {}) = string_list_string_char(pd); */
        list_path = stringSplitAtChar(file, pd);
        file_path = listLast(list_path);
        list_path_1 = listStripLast(list_path);
        dir_path = stringDelimitList(list_path_1, pd);
        current_dir = System.pwd();
        0 = System.cd(dir_path);
        res = System.pwd();
        0 = System.cd(current_dir);
      then
        (res,file_path);
    case (name)
      equation
        Debug.fprint("failtrace", "- Util.getAbsoluteDirectoryAndFile failed");
      then
        fail();
  end matchcontinue;
end getAbsoluteDirectoryAndFile;


public function rawStringToInputString "function: rawStringToInputString
  author: x02lucpo
  replace the double-backslash with backslash"
  input String inString;
  output String s;
algorithm
  (s) :=
  matchcontinue (inString)
    local
      String retString,rawString;
    case (rawString)
      equation
         retString = System.stringReplace(rawString, "\\\"", "\"") "change backslash-double-quote to double-quote ";
         retString = System.stringReplace(retString, "\\\\", "\\") "double-backslash with backslash ";
      then
        (retString);
  end matchcontinue;
end  rawStringToInputString;

public function listProduct
"@author adrpo
 given 2 lists, generate a product out of them.
 Example:
  lst1 = {{1}, {2}}, lst2 = {{1}, {2}, {3}}
  result = { {1, 1}, {1, 2}, {1, 3}, {2, 1}, {2, 2}, {2, 3} }"
  input  list<list<Type_a>> inTypeALstLst1;
  input  list<list<Type_a>> inTypeALstLst2;
  output list<list<Type_a>> outTypeALstLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALstlst := matchcontinue (inTypeALstLst1, inTypeALstLst2)
    local
      list<list<Type_a>> out;
    case (inTypeALstLst1, inTypeALstLst2)
      equation
        out = listProduct_acc(inTypeALstLst1, inTypeALstLst2, {});
      then
        out;
  end matchcontinue;
end listProduct;

public function listProduct_acc
"@author adrpo
 given 2 lists, generate a product out of them in the empty accumulator given as input.
 Example1:
  lst1 = {{1}, {2}}, lst2 = {{1}, {2}, {3}}
  result = { {1, 1}, {1, 2}, {1, 3}, {2, 1}, {2, 2}, {2, 3} }
 Example2:
  lst1 = {{1}, {2}}, lst2 = {}
  result = { {1}, {2}, {3} }"
  input  list<list<Type_a>> inTypeALst1;
  input  list<list<Type_a>> inTypeALst2;
  input  list<list<Type_a>> inTypeALstLst;
  output list<list<Type_a>> outTypeALstLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst:=
  matchcontinue (inTypeALst1, inTypeALst2, inTypeALstLst)
    local
      list<list<Type_a>> out, out1, out2, tail1, tail2;
      list<Type_a> hd1, hd2, res;
    case (hd1::{}, {}, inTypeALstLst)
      equation
        out = listMap(hd1, listCreate);
      then
        out;

    case ({}, _, inTypeALstLst)
      equation
         //debug_print("1 - inTypeALstLst", inTypeALstLst);
      then
        inTypeALstLst;

    case (hd1::tail1, inTypeALst2, inTypeALstLst)
      equation
        //debug_print("2 - hd1", hd1);
        //debug_print("2 - tail1", tail1);
        //debug_print("2 - inTypeALst2", inTypeALst2);
        //debug_print("2 - inTypeALstLst", inTypeALstLst);
        // append each element from inTypeALst2 to hd1 => { {hd1, el21}, {hd1, el22} ... }
        out1  = listMap1(inTypeALst2, listAppend, hd1);
        // do the same for the rest of the elements in the list
        out2  = listProduct_acc(tail1, inTypeALst2, out1);
        out   = listAppend(out1, out2);
        out   = listAppend(inTypeALstLst, out);
      then
        out;
  end matchcontinue;
end listProduct_acc;

public function escapeModelicaStringToCString
  input String modelicaString;
  output String cString;
algorithm
  cString := matchcontinue (modelicaString)
    local
      String s, sOut;
    case (s)
      equation
        sOut = System.stringReplace(s, "\n", "\\n");
      then
        sOut;
  end matchcontinue;
end escapeModelicaStringToCString;


public function listlistTranspose "{{1,2,3}{4,5,6}} => {{1,4},{2,5},{3,6}}"
  input list<list<Type_a>> inLst;
  output list<list<Type_a>> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := matchcontinue (inLst)
    local
      list<Type_a> first;
      list<list<Type_a>> rest;
      list<list<Type_a>> res;
      list<Boolean> boolLst;
    case {} then {{}};
    case (inLst)
      equation
        first = listMap(inLst, listFirst);
        rest = listMap(inLst, listRest);
        res = listlistTranspose(rest);
      then first :: res;
    case (inLst)
      equation
        boolLst = listMap(inLst, isListNotEmpty);
        false = listReduce(boolLst, boolOr);
      then {};
  end matchcontinue;
end listlistTranspose;

public function makeTuple2
  input Type_a a;
  input Type_b b;
  output tuple<Type_a,Type_b> out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  out := (a,b);
end makeTuple2;

public function makeTupleList
  input list<Type_a> al;
  input list<Type_b> bl;
  output list<tuple<Type_a,Type_b>> out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  out := matchcontinue(al,bl)
    local
      Type_a a;
      Type_b b;
    case({},_) then {};
    case(a::al,b::bl)
      equation
      out = makeTupleList(al,bl);
    then
      (a,b)::out;
  end matchcontinue;
end makeTupleList;

public function listAppendNoCopy
"author: adrpo
 this function handles special cases
 such as empty lists so it does no
 copy if any of the arguments are
 empty lists"
  input  list<Type_a> inLst1;
  input  list<Type_a> inLst2;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := matchcontinue(inLst1, inLst2)
    case ({},{}) then {};
    case (inLst1, {}) then inLst1;
    case ({}, inLst2) then inLst2;
    case (inLst1, inLst2) then listAppend(inLst1,inLst2);
  end matchcontinue;
end listAppendNoCopy;

public function mulListIntegerOpt
  input list<Option<Integer>> ad;
  input Integer acc "accumulator, should be given 1";
  output Integer i;
algorithm
  i := matchcontinue(ad, acc)
    local
      Integer ii, iii;
      list<Option<Integer>> rest;
    case ({}, acc) then acc;
    case (SOME(ii)::rest, acc)
      equation
        acc = ii * acc;
        iii = mulListIntegerOpt(rest, acc);
      then iii;
    case (NONE()::rest, acc)
      equation
        iii = mulListIntegerOpt(rest, acc);
      then iii;
  end matchcontinue;
end mulListIntegerOpt;

public type StatefulBoolean = Boolean[:] "A single boolean value that can be updated (a destructive operation)";

public function makeStatefulBoolean
  input Boolean b;
  output Boolean[:] sb;
algorithm
  sb := arrayCreate(1, b);
end makeStatefulBoolean;

public function getStatefulBoolean
  input Boolean[:] sb;
  output Boolean b;
algorithm
  b := sb[1];
end getStatefulBoolean;

public function setStatefulBoolean
  input Boolean[:] sb;
  input Boolean b;
algorithm
  _ := arrayUpdate(sb,1,b);
end setStatefulBoolean;


end Util;

