package Util "
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

  
  file:	 Util.rml
  module:      Util
  description: Miscellanous RML utilities
 
  RCS: $Id$
  
  This module contains various RML utilities sigh, mosly 
  related to lists.
  It is used pretty much everywhere. The difference between this 
  module and the ModUtil module is that ModUtil contains modelica 
  related utilities. The Util module only contains \"low-level\" 
  rml utilities, for example finding elements in lists.
  
  This modules contains many functions that uses \'type variables\' in RML.
  A type variable is exactly what it sounds like, a type bound to a variable.
  It is used for higher order functions, i.e. in RML the possibility to pass a 
  \"pointer\" to a function into another function. But it can also be used for 
  generic data types, like in  C++ templates.

  A type variable in RML is written as \'a
  For instance,
  function list_fill (\'a,int) => \'a list
  the type variable \'a is here used as a generic type for the function list_fill, 
  which returns a list of n elements of a certain type.
"

public 
uniontype ReplacePattern
  record REPLACEPATTERN
    String from "from string (ie \".\"" ;
    String to "to string (ie \"$p\") ))" ;
  end REPLACEPATTERN;

end ReplacePattern;

protected constant list<ReplacePattern> replaceStringPatterns={REPLACEPATTERN(".","$point"),
          REPLACEPATTERN("[","$leftBracket"),REPLACEPATTERN("]","$rightBracket"),
          REPLACEPATTERN("(","$leftParanthesis"),REPLACEPATTERN(")","$rightParanthesis"),
          REPLACEPATTERN(",","$comma")};

protected import OpenModelica.Compiler.System;

protected import OpenModelica.Compiler.Print;

protected import OpenModelica.Compiler.Debug;

public function flagValue "function flagValue
  author: x02lucpo
  Extracts the flagvalue from an argument list:
  flagvalue('-s',{'-d','hej','-s','file'}) => 'file'

"

  input String flag;
  input list<String> arguments;
  output String flagVal;
algorithm
  flagVal :=
   matchcontinue(flag,arguments)
   local 
      String flag,arg,value;
      list<String> args;
   case(flag,[]) then "";
   case(flag,arg::[])
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
       print("-flagValue failed\n");
      then
       fail();
   end matchcontinue;
end flagValue;

public function listFill "function: listFill
  Returns a list of n elements of type \'a.
  For example,
  list_fill(\"foo\",3) => {\"foo\",\"foo\",\"foo\"}
"
  input Type_a inTypeA;
  input Integer inInteger;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeA,inInteger)
    local
      Type_a a;
      Integer n_1,n;
      list<Type_a> res;
    case (a,1) then {a}; 
    case (a,n)
      equation 
        n_1 = n - 1;
        res = listFill(a, n_1);
      then
        (a :: res);
  end matchcontinue;
end listFill;

public function listMake2 "function listMake2
 
  Takes two arguments of same type and returns a list containing the two.
"
  input Type_a inTypeA1;
  input Type_a inTypeA2;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeA1,inTypeA2)
    local Type_a a,b;
    case (a,b) then {a,b}; 
  end matchcontinue;
end listMake2;

public function listIntRange "function: listIntRange
  Returns a list of n integers from 1 to N.
  For example,
  list_int_range(3) => {1,2,3}
"
  input Integer n;
  output list<Integer> res;
algorithm 
  res := listIntRange2(1, n);
end listIntRange;

protected function listIntRange2
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
        res = listIntRange2(i_1, n);
      then
        (i :: res);
    case (i,n) then {i}; 
  end matchcontinue;
end listIntRange2;

public function listFirst "function: listFirst 
  Returns the first element of a list
  For example,
  list_first({3,5,7,11,13}) => 3
"
  input list<Type_a> inTypeALst;
  output Type_a outTypeA;
  replaceable type Type_a;
algorithm 
  outTypeA:=
  matchcontinue (inTypeALst)
    local Type_a x;
    case ((x :: _)) then x; 
  end matchcontinue;
end listFirst;

public function listRest "function: listRest
  Returns the rest of a list.
  For example,
  list_rest({3,5,7,11,13}) => {5,7,11,13}
"
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst)
    local list<Type_a> x;
    case ((_ :: x)) then x; 
  end matchcontinue;
end listRest;

public function listLast "function: listLast
  Returns the last element of a list. If the list is the empty list, the function 
  fails.
  For example,
  list_last({3,5,7,11,13}) => 13
  list_last({}) => fail
"
  input list<Type_a> inTypeALst;
  output Type_a outTypeA;
  replaceable type Type_a;
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
 
  Performs the cons operation, i.e. elt::list.
"
  input list<Type_a> inTypeALst;
  input Type_a inTypeA;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst,inTypeA)
    local
      list<Type_a> lst;
      Type_a elt;
    case (lst,elt) then (elt :: lst); 
  end matchcontinue;
end listCons;

public function listCreate "function: listCreate
 
  Create a list from an element.
"
  input Type_a inTypeA;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeA)
    local Type_a a;
    case (a) then {a}; 
  end matchcontinue;
end listCreate;

public function listStripLast "function: listStripLast
  Remove the last element of a list. If the list is the empty list, the function 
  returns empty list
  For example,
  list_strip_last({3,5,7,11,13}) => {3,5,7,11}
  list_strip_last({}) => {}
"
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst)
    local
      Type_a a,b;
      list<Type_a> rev_lst,lst;
    case {} then {}; 
    case {a} then {}; 
    case (lst)
      local list<Type_a> a;
      equation 
        (b :: rev_lst) = listReverse(lst);
        a = listReverse(rev_lst);
      then
        a;
  end matchcontinue;
end listStripLast;

public function listFlatten "function: listFlatten
  Takes a list of lists and flattens it out, producing one list of all 
  elements of the sublists.
  For example
  list_flatten({ {1,2},{3,4,5},{6},{} }) => {1,2,3,4,5,6}
"
  input list<list<Type_a>> inTypeALstLst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALstLst)
    local
      list<Type_a> r_1,l,f;
      list<list<Type_a>> r;
    case {} then {}; 
    case (f :: r)
      equation 
        r_1 = listFlatten(r);
        l = listAppend(f, r_1);
      then
        l;
  end matchcontinue;
end listFlatten;

public function listAppendElt "function: listAppendElt
  This function adds an element last to the list
  For example
  list_append_elt(1,{2,3}) => {2,3,1}
"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
algorithm 
  outTypeALst:=
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
end listAppendElt;

public function listMap "function: listMap
  Takes a list and a function over the elements of the lists, which is applied
  for each element, producing a new list.
  For example
  list_map({1,2,3}, int_string) => { \"1\", \"2\", \"3\"}
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  output list<Type_b> outTypeBLst;
  replaceable type Type_a;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b;
  end FuncTypeType_aToType_b;
  replaceable type Type_b;
algorithm 
  outTypeBLst:=
  matchcontinue (inTypeALst,inFuncTypeTypeAToTypeB)
    local
      Type_b f_1;
      list<Type_b> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aToType_b fn;
    case ({},_) then {}; 
    case ((f :: r),fn)
      equation 
        f_1 = fn(f);
        r_1 = listMap(r, fn);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listMap;

public function listMap_2 "function listMap_2
  Takes a list and a function over the elements returning a tuple of two types,
  which is applied for each element producing two new lists.
  For example
  function split_real_string (real) => (string,string)  returns the string value at 
  each side of the decimal point.
  list_map__2({1.5,2.01,3.1415}, split_real_string) => ({\"1\",\"2\",\"3\"},{\"5\",\"01\",\"1415\"})
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToType_bType_c inFuncTypeTypeAToTypeBTypeC;
  output list<Type_b> outTypeBLst;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a;
  partial function FuncTypeType_aToType_bType_c
    input Type_a inTypeA;
    output Type_b outTypeB;
    output Type_c outTypeC;
    replaceable type Type_b;
    replaceable type Type_c;
  end FuncTypeType_aToType_bType_c;
  replaceable type Type_b;
  replaceable type Type_c;
algorithm 
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
end listMap_2;

public function listMap1 "function listMap1
  Takes a list and a function over the list plus an extra argument sent to the function.
  The function produces a new value which is used for creating a new list.
  For example,
  list_map_1({1,2,3},int_add,2) => {3,4,5}
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_b inTypeB;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    replaceable type Type_b;
    replaceable type Type_c;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_b;
  replaceable type Type_c;
algorithm 
  outTypeCLst:=
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
end listMap1;

public function listMap1r "function listMap1r
  Same as list_map_1 but swapped arguments on function.
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_bType_aToType_c inFuncTypeTypeBTypeAToTypeC;
  input Type_b inTypeB;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a;
  partial function FuncTypeType_bType_aToType_c
    input Type_b inTypeB;
    input Type_a inTypeA;
    output Type_c outTypeC;
    replaceable type Type_b;
    replaceable type Type_c;
  end FuncTypeType_bType_aToType_c;
  replaceable type Type_b;
  replaceable type Type_c;
algorithm 
  outTypeCLst:=
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
end listMap1r;

public function listMap2 "function listMap2
  Takes a list and a function and two extra arguments passed to the function.
  The function produces one new value which is used for creating a new list.
  For example,
  function if:(bool,\'a,\'a) => \'a
  list_map_2({true,false,false},1,0,if) => {1,0,0}
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cToType_d inFuncTypeTypeATypeBTypeCToTypeD;
  input Type_b inTypeB;
  input Type_c inTypeC;
  output list<Type_d> outTypeDLst;
  replaceable type Type_a;
  partial function FuncTypeType_aType_bType_cToType_d
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output Type_d outTypeD;
    replaceable type Type_b;
    replaceable type Type_c;
    replaceable type Type_d;
  end FuncTypeType_aType_bType_cToType_d;
  replaceable type Type_b;
  replaceable type Type_c;
  replaceable type Type_d;
algorithm 
  outTypeDLst:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBTypeCToTypeD,inTypeB,inTypeC)
    local
      Type_d f_1;
      list<Type_d> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bType_cToType_d fn;
      Type_b extraarg1;
      Type_c extraarg2;
    case ({},_,_,_) then {}; 
    case ((f :: r),fn,extraarg1,extraarg2)
      equation 
        f_1 = fn(f, extraarg1, extraarg2);
        r_1 = listMap2(r, fn, extraarg1, extraarg2);
      then
        (f_1 :: r_1);
  end matchcontinue;
end listMap2;

public function listMap3 "function listMap3
  Takes a list and a function and three extra arguments passed to the function.
  The function produces one new value which is used for creating a new list.
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cType_dToType_e inFuncTypeTypeATypeBTypeCTypeDToTypeE;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input Type_d inTypeD;
  output list<Type_e> outTypeELst;
  replaceable type Type_a;
  partial function FuncTypeType_aType_bType_cType_dToType_e
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    output Type_e outTypeE;
    replaceable type Type_b;
    replaceable type Type_c;
    replaceable type Type_d;
    replaceable type Type_e;
  end FuncTypeType_aType_bType_cType_dToType_e;
  replaceable type Type_b;
  replaceable type Type_c;
  replaceable type Type_d;
  replaceable type Type_e;
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

public function listMap32 "function listMap32
  Takes a list and a function and three extra arguments passed to the function.
  The function produces two values which is used for creating two new lists.
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cType_dToType_eType_f inFuncTypeTypeATypeBTypeCTypeDToTypeETypeF;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input Type_d inTypeD;
  output list<Type_e> outTypeELst;
  output list<Type_f> outTypeFLst;
  replaceable type Type_a;
  partial function FuncTypeType_aType_bType_cType_dToType_eType_f
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    output Type_e outTypeE;
    output Type_f outTypeF;
    replaceable type Type_b;
    replaceable type Type_c;
    replaceable type Type_d;
    replaceable type Type_e;
    replaceable type Type_f;
  end FuncTypeType_aType_bType_cType_dToType_eType_f;
  replaceable type Type_b;
  replaceable type Type_c;
  replaceable type Type_d;
  replaceable type Type_e;
  replaceable type Type_f;
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

public function listMap12 "function: listMap12
  Takes a list and a function with one extra arguments passed to the function.
  The function returns a tuple of two values which are used for creating 
  two new lists
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bToType_cType_d inFuncTypeTypeATypeBToTypeCTypeD;
  input Type_b inTypeB;
  output list<Type_c> outTypeCLst;
  output list<Type_d> outTypeDLst;
  replaceable type Type_a;
  partial function FuncTypeType_aType_bToType_cType_d
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    output Type_d outTypeD;
    replaceable type Type_b;
    replaceable type Type_c;
    replaceable type Type_d;
  end FuncTypeType_aType_bToType_cType_d;
  replaceable type Type_b;
  replaceable type Type_c;
  replaceable type Type_d;
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
  For example,
  function foo(int,string,string) => (string,string) concatenates each string with 
  itself n times. foo(2,\"a\",b\") => (\"aa\",\"bb\")
  list_map_2_2 ({2,3},foo,\"a\",\"b\") => {(\"aa\",\"bb\"),(\"aa\",\"bbb\")}
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cToType_dType_e inFuncTypeTypeATypeBTypeCToTypeDTypeE;
  input Type_b inTypeB;
  input Type_c inTypeC;
  output list<tuple<Type_d, Type_e>> outTplTypeDTypeELst;
  replaceable type Type_a;
  partial function FuncTypeType_aType_bType_cToType_dType_e
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output Type_d outTypeD;
    output Type_e outTypeE;
    replaceable type Type_b;
    replaceable type Type_c;
    replaceable type Type_d;
    replaceable type Type_e;
  end FuncTypeType_aType_bType_cToType_dType_e;
  replaceable type Type_b;
  replaceable type Type_c;
  replaceable type Type_d;
  replaceable type Type_e;
algorithm 
  outTplTypeDTypeELst:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBTypeCToTypeDTypeE,inTypeB,inTypeC)
    local
      Type_d f1;
      Type_e f2;
      list<tuple<Type_d, Type_e>> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bType_cToType_dType_e fn;
      Type_b extraarg1;
      Type_c extraarg2;
    case ({},_,_,_) then {}; 
    case ((f :: r),fn,extraarg1,extraarg2)
      equation 
        (f1,f2) = fn(f, extraarg1, extraarg2);
        r_1 = listMap22(r, fn, extraarg1, extraarg2);
      then
        ((f1,f2) :: r_1);
  end matchcontinue;
end listMap22;

public function listMap0 "function: listMap0
  Takes a list and a function which does not return a value
  The function is probably a function with side effects, like print.
  For example,
  list_map_0({\"a\",\"b\",\"c\"},print) => ()
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  replaceable type Type_a;
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

public function listListMap "function: listListMap 
  Takes a list of lists and a function producing one value.
  The function is applied to each element of the lists resulting
  in a new list of lists.
  For example,
  list_list_map({ {1,2},{3},{4}},int_string) => { {\"1\",\"2\"},{\"3\"},{\"4\"} }
"
  input list<list<Type_a>> inTypeALstLst;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  output list<list<Type_b>> outTypeBLstLst;
  replaceable type Type_a;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b;
  end FuncTypeType_aToType_b;
  replaceable type Type_b;
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
  similar to list_list_map but for functions taking two arguments.
  The second argument is passed as an extra argument.
"
  input list<list<Type_a>> inTypeALstLst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  input Type_b inTypeB;
  output list<list<Type_c>> outTypeCLstLst;
  replaceable type Type_a;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    replaceable type Type_b;
    replaceable type Type_c;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_b;
  replaceable type Type_c;
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

public function listFold "function: listFold
  Takes a list and a function operating on list elements having an extra argument that is \'updated\'
  thus returned from the function. The third argument is the startvalue for the updated value.
  list_fold will call the function for each element in a sequence, updating the startvalue 
  For example,
  list_fold({1,2,3},int_add,2) =>  8
  int_add(1,2) => 3, int_add(2,3) => 5, int_add(3,5) => 8 
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bToType_b inFuncTypeTypeATypeBToTypeB;
  input Type_b inTypeB;
  output Type_b outTypeB;
  replaceable type Type_a;
  partial function FuncTypeType_aType_bToType_b
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_b outTypeB;
    replaceable type Type_b;
  end FuncTypeType_aType_bToType_b;
  replaceable type Type_b;
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

public function listFoldMap "function: listFoldMap
  author: PA
 
  For example see Exp.traverse_exp.
"
  input list<Type_a> inTypeALst;
  input FuncTypeTplType_aType_bToTplType_aType_b inFuncTypeTplTypeATypeBToTplTypeATypeB;
  input Type_b inTypeB;
  output list<Type_a> outTypeALst;
  output Type_b outTypeB;
  replaceable type Type_a;
  partial function FuncTypeTplType_aType_bToTplType_aType_b
    input tuple<Type_a, Type_b> inTplTypeATypeB;
    output tuple<Type_a, Type_b> outTplTypeATypeB;
    replaceable type Type_b;
  end FuncTypeTplType_aType_bToTplType_aType_b;
  replaceable type Type_b;
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
  Takes a list of lists and reverses it at both levels, i.e. both the list itself
  and each sublist
  For example,
  list_list_reverse({{1,2},{3,4,5},{6} }) => { {6}, {5,4,3}, {2,1} }
"
  input list<list<Type_a>> lsts;
  output list<list<Type_a>> lsts_2;
  replaceable type Type_a;
  list<list<Type_a>> lsts_1,lsts_2;
algorithm 
  lsts_1 := listMap(lsts, list_reverse);
  lsts_2 := listReverse(lsts_1);
end listListReverse;

public function listThread "function: listThread
  Takes two lists of the same type and threads them togheter.
  For eample,
  list_thread({1,2,3},{4,5,6}) => {4,1,5,2,6,3}
"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
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

public function listThreadMap "function: listThreadMap
  Takes two lists and a function and threads and maps the elements of the two lists
  creating a new list.
  For example,
  list_thread_map({1,2},{3,4},int_add) => {1+3, 2+4}
"
  input list<Type_a> inTypeALst;
  input list<Type_b> inTypeBLst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a;
  replaceable type Type_b;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    replaceable type Type_c;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_c;
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

public function listListThreadMap "function: listListThreadMap
  Takes two lists of lists and a function and threads and maps the elements  of the elements of the 
  two lists creating a new list.
  For example,
  listListThreadMap({{1,2}},{{3,4}},int_add) => {{1+3, 2+4}}
"
  input list<list<Type_a>> inTypeALst;
  input list<list<Type_b>> inTypeBLst;
  input FuncTypeType_aType_bToType_c inFuncTypeTypeATypeBToTypeC;
  output list<list<Type_c>> outTypeCLst;
  replaceable type Type_a;
  replaceable type Type_b;
  partial function FuncTypeType_aType_bToType_c
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    replaceable type Type_c;
  end FuncTypeType_aType_bToType_c;
  replaceable type Type_c;
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
  Takes two lists and threads the arguments into a list of tuples
  consisting of the two element types.
  For example,
  list_thread_tuple({1,2,3},{true,false,true}) => {(1,true),(2,false),(3,true)}
"
  input list<Type_a> inTypeALst;
  input list<Type_b> inTypeBLst;
  output list<tuple<Type_a, Type_b>> outTplTypeATypeBLst;
  replaceable type Type_a;
  replaceable type Type_b;
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

public function listListThreadTuple "function: listListThreadTuple
  Takes two list of lists as arguments and produces a list of lists of a two tuple
  of the element types of each list.
  For example,
  list_list_thread_tuple({{1},{2,3}},{{\"a\"},{\"b\",\"c\"}}) => { {(1,\"a\")},{(2,\"b\"),(3,\"c\")} }
"
  input list<list<Type_a>> inTypeALstLst;
  input list<list<Type_b>> inTypeBLstLst;
  output list<list<tuple<Type_a, Type_b>>> outTplTypeATypeBLstLst;
  replaceable type Type_a;
  replaceable type Type_b;
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

public function listSelect "function: listSelect
  This function retrieves all elements of a list for which
  the passed function evaluates to true. The elements that evaluates to false 
  are thus removed from the list.
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToBoolean inFuncTypeTypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
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
  Same as list_select above, but with extra argument to testing function.
"
  input list<Type_a> inTypeALst;
  input Type_b inTypeB;
  input FuncTypeType_aType_bToBoolean inFuncTypeTypeATypeBToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
  replaceable type Type_b;
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

public function listSelect1R "function listSelect1R
  Same as list_select_1 above, but with swapped arguments.
"
  input list<Type_a> inTypeALst;
  input Type_b inTypeB;
  input FuncTypeType_bType_aToBoolean inFuncTypeTypeBTypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
  replaceable type Type_b;
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
  the value has in the list. Position index start at zero, such that list_nth can
  be used on the resulting position directly.
  For example,
  list_position(2,{0,1,2,3}) => 2
"
  input Type_a x;
  input list<Type_a> ys;
  output Integer n;
  replaceable type Type_a;
algorithm 
  n := listPos(x, ys, 0);
end listPosition;

protected function listPos "helper function to listPosition"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  input Integer inInteger;
  output Integer outInteger;
  replaceable type Type_a;
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

public function listGetmember "function: listGetmember
  Takes a value and a list of values and returns the value 
  if present in the list. If not present, the function will fail.
  For example,
  list_getmember(0,{1,2,3}) => fail
  list_getmember(1,{1,2,3}) => 1
"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  output Type_a outTypeA;
  replaceable type Type_a;
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
        res = listGetmember(x, ys);
      then
        res;
  end matchcontinue;
end listGetmember;

public function listDeletemember "function: listDeletemember
  Takes a list and a value and deletes the first occurence of the value in the list
  For example,
  list_deletemember({1,2,3,2},2) => {1,3,2}
"
  input list<Type_a> inTypeALst;
  input Type_a inTypeA;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
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
end listDeletemember;

public function listDeletememberP "function: listDeletememberP
  Takes a list and a value and a comparison function and deletes the first occurence of 
  the value in the list
  For example,
  list_deletemember({1,2,3,2},2,int_eq) => {1,3,2}
"
  input list<Type_a> inTypeALst;
  input Type_a inTypeA;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
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
        elt_1 = listGetmemberP(elt, lst, cond) "A bit ugly" ;
        pos = listPosition(elt_1, lst);
        lst_1 = listDelete(lst, pos);
      then
        lst_1;
    case (lst,_,_) then lst; 
  end matchcontinue;
end listDeletememberP;

public function listGetmemberP "function listGetmemberP
  Takes a value and a list of values and a comparison function over two values.
  If the value is present in the list (using the comparison function returning true)
  the value is returned, otherwise the function fails.
  For example,
  function equal_lenght(string,string) returns true if the strings are of same length
  list_getmember_p(\"a\",{\"bb\",\"b\",\"ccc\"},equal_length) => \"b\"
"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean;
  output Type_a outTypeA;
  replaceable type Type_a;
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
        res = listGetmemberP(x, ys, p);
      then
        res;
  end matchcontinue;
end listGetmemberP;

public function listUnionElt "function: listUnionElt
  Takes a value and a list of values and inserts the value into the list if 
  it is not already in the list.
  If it is in the list it is not inserted.
  For example,
  list_union_elt(1,{2,3}) => {1,2,3}
  list_union_elt(0,{0,1,2}) => {0,1,2}
"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeA,inTypeALst)
    local
      Type_a x;
      list<Type_a> lst;
    case (x,lst)
      equation 
        _ = listGetmember(x, lst);
      then
        lst;
    case (x,lst)
      equation 
        failure(_ = listGetmember(x, lst));
      then
        (x :: lst);
  end matchcontinue;
end listUnionElt;

public function listUnion "function listUnion
  Takes two lists and returns the union of the two lists, i.e. a list of all elements combined
  without duplicates.
  For example,
  list_union({0,1},{2,1}) => {0,1,2}
"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
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
  For example,
  list_list_union({{1},{1,2},{3,4},{5}}) => {1,2,3,4,5}
"
  input list<list<Type_a>> inTypeALstLst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
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

public function listUnionEltP "function: listUnionEltP
  Takes an elemement and a list and a comparison function over the two values.
  It returns the list with the element inserted if not already present in the
  list, according to the comparison function.
  For example,
  list_union_elt_p(1,{2,3},int_eq) => {1,2,3}
"
  input Type_a inTypeA;
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
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
        _ = listGetmemberP(x, lst, p);
      then
        lst;
    case (x,lst,p)
      equation 
        failure(_ = listGetmemberP(x, lst, p));
      then
        (x :: lst);
  end matchcontinue;
end listUnionEltP;

public function listUnionP "function: listUnionP
  Takes two lists and a comparison function over two elements of the list.
  It returns the union of the two lists, using the comparison function passed as argument
  to determine identity between two elements.
  For example
  given the function equal_lenght(string,string) returning true if the strings are of same length
  list_union_p({\"a\",\"aa\"},{\"b\",\"bbb\"},equal_length) => {\"a\",\"aa\",\"bbb\"}
"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean3;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
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
        r1 = listUnionEltP(x, lst2, p);
        res = listUnionP(xs, r1, p);
      then
        res;
  end matchcontinue;
end listUnionP;

public function listIntersectionP "function: listIntersectionP
  Takes two lists and a comparison function over two elements of the list.
  It returns the intersection of the two lists, using the comparison function passed as 
  argument to determine identity between two elements.
  For example
  given the function string_equal(string,string) returning true if the strings are equal
  list_intersection_p({\"a\",\"aa\"},{\"b\",\"aa\"},string_equal) => {\"aa\"}
"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean3;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
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
        _ = listGetmemberP(x1, xs2, cond);
        res = listIntersectionP(xs1, xs2, cond);
      then
        (x1 :: res);
    case ((x1 :: xs1),xs2,cond)
      equation 
        res = listIntersectionP(xs1, xs2, cond) "not list_getmember_p(x1,xs2,cond) => _" ;
      then
        res;
  end matchcontinue;
end listIntersectionP;

public function listSetEqualP "function: listSetEqualP
  Takes two lists and a comparison function over two elements of the list.
  It returns true if the two sets are equal, false otherwise.
"
  input list<Type_a> lst1;
  input list<Type_a> lst2;
  input CompareFunc compare;
  output Boolean equal;
  replaceable type Type_a;
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
       	lst = listIntersectionP(lst1,lst2,compare);
       	true = intEq(listLength(lst), listLength(lst1));
       	true = intEq(listLength(lst), listLength(lst2));
       then true;
     case (_,_,_) then false;
  end matchcontinue;
end listSetEqualP;

public function listSetdifferenceP "function: listSetdifferenceP
  Takes two lists and a comparison function over two elements of the list.
  It returns the set difference of the two lists A-B, using the comparison function passed as 
  argument to determine identity between two elements.
  For example
  given the function string_equal(string,string) returning true if the strings are equal
  list_setdifference_p({\"a\",\"b\",\"c\"},{\"a\",\"c\"},string_equal) => {\"b\"}
"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean3;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
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
        a_1 = listDeletememberP(a, x1, cond);
        a_2 = listSetdifferenceP(a_1, xs, cond);
      then
        a_2;
    case (_,_,_)
      equation 
        print("-list_setdifference_p failed\n");
      then
        fail();
  end matchcontinue;
end listSetdifferenceP;

public function listListUnionP "function: listListUnionP
  Takes a list of lists and a comparison function over two elements of the lists.
  It returns the union of all sublists using the comparison function for identity.
  For example,
  list_list_union_p({{1},{1,2},{3,4}},int_eq) => {1,2,3,4}
"
  input list<list<Type_a>> inTypeALstLst;
  input FuncTypeType_aType_aToBoolean inFuncTypeTypeATypeAToBoolean;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
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
        r1 = listUnionP(x1, x2, p);
        res = listListUnionP((r1 :: rest), p);
      then
        res;
  end matchcontinue;
end listListUnionP;

public function listReplaceat "function: listReplaceat
  Takes an element, a position and a list and replaces the value at the given position in 
  the list. Position is an integer between 0 and n-1 for a list of n elements
  For example,
  list_replaceat(\"A\", 2, {\"a\",\"b\",\"c\"}) => {\"a\",\"b\",\"A\"}
"
  input Type_a inTypeA;
  input Integer inInteger;
  input list<Type_a> inTypeALst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeA,inInteger,inTypeALst)
    local
      Type_a x,y;
      list<Type_a> ys,res;
      Integer nn,n;
    case (x,0,(y :: ys)) then (x :: ys);  /* axiom list_replaceat(x,-1,{}) => {} */ 
    case (x,n,(y :: ys)) /* rule	print \"-list_replaceat failed\\n\" 
	-----------------------
	list_replaceat(_,_,_) => fail */ 
      equation 
        (n >= 1) = true;
        nn = n - 1;
        res = listReplaceat(x, nn, ys);
      then
        (y :: res);
  end matchcontinue;
end listReplaceat;

public function listReplaceatWithFill "function: listReplaceatWithFill
  Takes 
  - an element, 
  - a position 
  - a list and 
  - a fill value 
  The function replaces the value at the given position in the list, if the given position is 
  out of range, the fill value is used to padd the list up to that element position and then
  insert the value at the position
  
  For example,
  list_replaceat_withfill(\"A\", 5, {\"a\",\"b\",\"c\"},\"dummy\") => {\"a\",\"b\",\"c\",\"dummy\",\"A\"}
"
  input Type_a inTypeA1;
  input Integer inInteger2;
  input list<Type_a> inTypeALst3;
  input Type_a inTypeA4;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
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
        res = listReplaceatWithFill(x, nn, ys, fillv);
      then
        (y :: res);
    case (_,p,_,_)
      equation 
        print("-list_replaceat_with_fill failed row: ");
        pos = intString(p);
        print(pos);
        print("\n");
      then
        fail();
  end matchcontinue;
end listReplaceatWithFill;

public function listReduce "function: listReduce
  Takes a list and a function operating on two elements of the list.
  The function performs a reduction of the lists to a single value using the function.
  For example,
  list_reduce({1,2,3},int_add) => 6
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_aToType_a inFuncTypeTypeATypeAToTypeA;
  output Type_a outTypeA;
  replaceable type Type_a;
  partial function FuncTypeType_aType_aToType_a
    input Type_a inTypeA1;
    input Type_a inTypeA2;
    output Type_a outTypeA;
  end FuncTypeType_aType_aToType_a;
algorithm 
  outTypeA:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeAToTypeA)
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
        res2 = listReduce(xs, r);
        res = r(res1, res2);
      then
        res;
  end matchcontinue;
end listReduce;

public function arrayReplaceatWithFill "function: arrayReplaceatWithFill
  Takes 
  - an element, 
  - a position 
  - an array and 
  - a fill value 
  The function replaces the value at the given position in the array, if the given position is 
  out of range, the fill value is used to padd the array up to that element position and then
  insert the value at the position
  
  For example,
  array_replaceat_withfill(\"A\", 5, {\"a\",\"b\",\"c\"},\"dummy\") => {\"a\",\"b\",\"c\",\"dummy\",\"A\"}
"
  input Type_a inTypeA1;
  input Integer inInteger2;
  input Type_a[:] inTypeAArray3;
  input Type_a inTypeA4;
  output Type_a[:] outTypeAArray;
  replaceable type Type_a;
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
        res = arrayUpdate(arr, pos + 1, x);
      then
        res;
    case (x,pos,arr,fillv)
      equation 
        pos_1 = pos + 1 "Replacing element out of range of array, create new array, and copy elts." ;
        newarr = fill(fillv, pos_1);
        res = arrayCopy(arr, newarr);
        res_1 = arrayUpdate(res, pos + 1, x);
      then
        res_1;
    case (_,_,_,_)
      equation 
        print("-array_replaceat_with_fill failed\n");
      then
        fail();
  end matchcontinue;
end arrayReplaceatWithFill;

public function arrayExpand "function: arrayExpand
  Increases the number of elements of a list with n.
  Each of the new elements have the value v.
"
  input Integer n;
  input Type_a[:] arr;
  input Type_a v;
  output Type_a[:] newarr_1;
  replaceable type Type_a;
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
  The function fails if all elements can not be fit into dest array.
"
  input Type_a[:] src;
  input Type_a[:] dst;
  input Integer n;
  output Type_a[:] dst_1;
  replaceable type Type_a;
  Integer n_1;
  Type_a[:] dst_1;
algorithm 
  n_1 := n - 1;
  dst_1 := arrayCopy2(src, dst, n_1);
end arrayNCopy;

public function arrayCopy "function: arrayCopy
  copies all values in src array into dest array.
  The function fails if all elements can not be fit into dest array.
"
  input Type_a[:] inTypeAArray1;
  input Type_a[:] inTypeAArray2;
  output Type_a[:] outTypeAArray;
  replaceable type Type_a;
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
          "-array_copy failed. Can not fit elements into dest array\n");
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
  replaceable type Type_a;
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

public function tuple21 "function: tuple21
  Takes a tuple of two values and returns the first value.
  For example,
  tuple2_1((\"a\",1)) => \"a\"
"
  input tuple<Type_a, Type_b> inTplTypeATypeB;
  output Type_a outTypeA;
  replaceable type Type_a;
  replaceable type Type_b;
algorithm 
  outTypeA:=
  matchcontinue (inTplTypeATypeB)
    local Type_a a;
    case ((a,_)) then a; 
  end matchcontinue;
end tuple21;

public function tuple22 "function: tuple22
  Takes a tuple of two values and returns the second value.
  For example,
  tuple2_2((\"a\",1)) => 1
"
  input tuple<Type_a, Type_b> inTplTypeATypeB;
  output Type_b outTypeB;
  replaceable type Type_a;
  replaceable type Type_b;
algorithm 
  outTypeB:=
  matchcontinue (inTplTypeATypeB)
    local Type_b b;
    case ((_,b)) then b; 
  end matchcontinue;
end tuple22;

public function splitTuple2List "function: splitTuple2List
  Takes a list of two-tuples and splits it into two lists.
  For example,
  split_tuple2_list({(\"a\",1),(\"b\",2),(\"c\",3)}) => ({\"a\",\"b\",\"c\"}, {1,2,3})
"
  input list<tuple<Type_a, Type_b>> inTplTypeATypeBLst;
  output list<Type_a> outTypeALst;
  output list<Type_b> outTypeBLst;
  replaceable type Type_a;
  replaceable type Type_b;
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

public function if_ "function: if
  Takes a boolean and two values.
  Returns the first value (second argument) if the boolean value is true, otherwise 
  the second value (third argument) is returned.
  For example,
  if(true,\"a\",\"b\") => \"a\"
"
  input Boolean inBoolean1;
  input Type_a inTypeA2;
  input Type_a inTypeA3;
  output Type_a outTypeA;
  replaceable type Type_a;
algorithm 
  outTypeA:=
  matchcontinue (inBoolean1,inTypeA2,inTypeA3)
    local Type_a r;
    case (true,r,_) then r; 
    case (false,_,r) then r; 
  end matchcontinue;
end if_;

public function stringAppendList "function stringAppendList
  Takes a list of strings and appends them.
  For example,
  string_append_list({\"foo\", \" \", \"bar\"}) => \"foo bar\"
"
  input list<String> inStringLst;
  output String outString;
algorithm 
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
end stringAppendList;

public function stringDelimitList "function stringDelimitList
  Takes a list of strings and a string delimiter and appends all list elements with
  the string delimiter inserted between elements.
  For example,
  string_delimit_list({\"x\",\"y\",\"z\"}, \", \") => \"x, y, z\"
"
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

public function stringDelimitList2sep "function: stringDelimitList2sep
  author: PA
 
  This function is similar to string_delimit_list, i.e it inserts string delimiters between 
  consecutive strings in a list. But it also count the lists and inserts a second string delimiter
  when the counter is reached. This can be used when for instance outputting large lists of values
  and a newline is needed after ten or so items.
"
  input list<String> str;
  input String sep1;
  input String sep2;
  input Integer n;
  output String res;
algorithm 
  res := stringDelimitList2sep2(str, sep1, sep2, n, 0);
end stringDelimitList2sep;

protected function stringDelimitList2sep2 "function: stringDelimitList2sep2
  author: PA
 
  Helper function to string_delimit_list_2sep
"
  input list<String> inStringLst1;
  input String inString2;
  input String inString3;
  input Integer inInteger4;
  input Integer inInteger5;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStringLst1,inString2,inString3,inInteger4,inInteger5)
    local
      String s,str1,str,f,sep1,sep2;
      list<String> r;
      Integer n,iter_1,iter;
    case ({},_,_,_,_) then "";  /* iterator */ 
    case ({s},_,_,_,_) then s; 
    case ((f :: r),sep1,sep2,n,0)
      equation 
        str1 = stringDelimitList2sep2(r, sep1, sep2, n, 1) "special case for first element" ;
        str = stringAppendList({f,sep1,str1});
      then
        str;
    case ((f :: r),sep1,sep2,n,iter)
      equation 
        0 = intMod(iter, n) "insert second delimiter" ;
        iter_1 = iter + 1;
        str1 = stringDelimitList2sep2(r, sep1, sep2, n, iter_1);
        str = stringAppendList({f,sep1,sep2,str1});
      then
        str;
    case ((f :: r),sep1,sep2,n,iter)
      equation 
        iter_1 = iter + 1 "not inserting second delimiter" ;
        str1 = stringDelimitList2sep2(r, sep1, sep2, n, iter_1);
        str = stringAppendList({f,sep1,str1});
      then
        str;
    case (_,_,_,_,_)
      equation 
        print("string_delimit_list_2sep2 failed\n");
      then
        fail();
  end matchcontinue;
end stringDelimitList2sep2;

public function stringDelimitListNoEmpty "function stringDelimitListNoEmpty
  Takes a list of strings and a string delimiter and appends all list elements with
  the string delimiter inserted between elements.
  For example,
  string_delimit_list({\"x\",\"y\",\"z\"}, \", \") => \"x, y, z\"
"
  input list<String> lst;
  input String delim;
  output String str;
  list<String> lst1;
algorithm 
  lst1 := listSelect(lst, isNotEmptyString);
  str := stringDelimitList(lst1, delim);
end stringDelimitListNoEmpty;

public function stringReplaceChar "function stringReplaceChar
  Takes a string and two chars and replaces the first char to 
  second char:
  example: string_replace_char(\"hej.b.c\",#\".\",#\"_\") => \"hej_b_c\"
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
        print("string_replace_char failed\n");
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
      list<String> res,rest,strList;
      String firstChar,fromChar,toChar;
    case ({},_,_) then {}; 
    case ((firstChar :: rest),fromChar,toChar)
      equation 
        equality(firstChar = fromChar);
        res = stringReplaceChar2(rest, fromChar, toChar);
      then
        (toChar :: res);
    case ((firstChar :: rest),fromChar,toChar)
      equation 
        failure(equality(firstChar = fromChar));
        res = stringReplaceChar2(rest, fromChar, toChar);
      then
        (firstChar :: res);
    case (strList,_,_)
      equation 
        print("string_replace_char2 failed\n");
      then
        strList;
  end matchcontinue;
end stringReplaceChar2;

public function stringSplitAtChar "function stringSplitAtChar
  Takes a string and a char and split the string at the char
  example: string_split_at_char(\"hej.b.c\",#\".\") => {\"hej,\"b\",\"c\"}
"
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
        stringList = stringSplitAtChar2(chrList, chr, {}) "list_string(resList) => res" ;
      then
        stringList;
    case (strList,_) /* print \"string_split_at_char failed\\n\" */  then {strList}; 
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
        print("string_split_at_char2 failed\n");
      then
        fail();
  end matchcontinue;
end stringSplitAtChar2;

public function modelicaStringToCStr "function modelicaStringToCStr
 this replaces symbols that are illegal in C to legal symbols
 see replaceStringPatterns to see the format. (example: \".\" becomes \"$p\")
  author: x02lucpo
"
  input String str;
  output String res_str;
algorithm 
  res_str := modelicaStringToCStr1(str, replaceStringPatterns);
end modelicaStringToCStr;

protected function modelicaStringToCStr1
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
    case (_,_)
      equation 
        print("-modelica_string_to_c_str1 failed\n");
      then
        fail();
  end matchcontinue;
end modelicaStringToCStr1;

public function cStrToModelicaString "function cStrToModelicaString
 this replaces symbols that have been replace to correct value for modelica string
 see replaceStringPatterns to see the format. (example: \"$p\" becomes \".\")
  author: x02lucpo
"
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
  Takes a list of boolean values and applies the boolean \'or\' operator  to the list elements
  For example
  bool_or_list({true,false,false}) => true
  bool_or_list({false,false,false}) => false
"
  input list<Boolean> inBooleanLst;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inBooleanLst)
    local
      Boolean b,res;
      list<Boolean> rest;
    case ({b}) then b; 
    case ((b :: rest))
      equation 
        equality(b = true);
      then
        true;
    case ((b :: rest))
      equation 
        equality(b = false);
        res = boolOrList(rest);
      then
        res;
  end matchcontinue;
end boolOrList;

public function boolAndList "function: boolAndList
  Takes a list of boolean values and applies the boolean \'and\' operator on the elements
  For example,
  boolAndList({}) => true
  boolAndList({true, true}) => true
  boolAndList({false,false,true}) => false
"
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
    case ((b :: rest))
      equation 
        equality(b = false);
      then
        false;
    case ((b :: rest))
      equation 
        equality(b = true);
        res = boolAndList(rest);
      then
        res;
  end matchcontinue;
end boolAndList;

public function boolString "function: boolString
  Takes a boolean value and returns a string representation of the boolean value.
  For example,
  bool_string(true) => \"true\"
"
  input Boolean inBoolean;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inBoolean)
    case true then "true"; 
    case false then "false"; 
  end matchcontinue;
end boolString;

public function boolEqual "Returns true if two booleans are equal, false otherwise"
	input Boolean b1;
	input Boolean b2;
	output Boolean res;
algorithm
  res := matchcontinue(b1,b2)
    case (true,true) then true;
    case (false,false) then true;
    case (_,_) then false;
  end matchcontinue;
end boolEqual;

public function stringEqual "function: stringEqual
  Takes two strings and returns true if the strings are equal
  For example,
  string_equal(\"a\",\"a\") => true
"
  input String inString1;
  input String inString2;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inString1,inString2)
    local String a,b;
    case (a,b)
      equation 
        equality(a = b);
      then
        true;
    case (_,_) then false; 
  end matchcontinue;
end stringEqual;

public function listMatching "function: listMatching
  For example,
  Takes a list of values and a matching function over the values and returns a
  sub list of values for which the matching function succeeds.
  For example,
  given function is_numeric(string) => ()  which succeeds if the string is numeric.
  list_matching({\"foo\",\"1\",\"bar\",\"4\"},is_numeric) => {\"1\",\"4\"}
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeALst,inFuncTypeTypeATo)
    local
      list<Type_a> vl_1,vl;
      Type_a v;
      FuncTypeType_aTo cond;
    case ({},_) then {}; 
    case ((v :: vl),cond)
      equation 
        cond(v);
        vl_1 = listMatching(vl, cond);
      then
        (v :: vl_1);
    case ((v :: vl),cond)
      equation 
        failure(cond(v));
        vl_1 = listMatching(vl, cond);
      then
        vl_1;
  end matchcontinue;
end listMatching;

public function applyOption "function: applyOption
  Takes an option value and a function over the value. 
  It returns in another option value, resulting 
  from the application of the function on the value.
  For example,
  apply_option(SOME(1), int_string) => SOME(\"1\")
  apply_option(NONE, int_string) => NONE
"
  input Option<Type_a> inTypeAOption;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  output Option<Type_b> outTypeBOption;
  replaceable type Type_a;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b;
  end FuncTypeType_aToType_b;
  replaceable type Type_b;
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
  Makes a value into value option, using SOME(value) 
"
  input Type_a inTypeA;
  output Option<Type_a> outTypeAOption;
  replaceable type Type_a;
algorithm 
  outTypeAOption:=
  matchcontinue (inTypeA)
    local Type_a v;
    case (v) then SOME(v); 
  end matchcontinue;
end makeOption;

public function stringOption "function: stringOption
  author: PA
 
  Returns string value or empty string from string option.
"
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

public function listSplit "function: listSplit
  Takes a list of values and an position value.
  The function returns the list splitted into two lists at the position given as argument.
  For example,
  list_split({1,2,5,7},2) => ({1,2},{5,7})
"
  input list<Type_a> inTypeALst;
  input Integer inInteger;
  output list<Type_a> outTypeALst1;
  output list<Type_a> outTypeALst2;
  replaceable type Type_a;
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
        print(
          "Index out of bounds (greater than list length) in relation list_split\n");
      then
        fail();
    case (a,index)
      equation 
        (index < 0) = true;
        print(
          "Index out of bounds (less than zero) in relation list_split\n");
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

protected function listSplit2 "helper function to list_split
"
  input list<Type_a> inTypeALst1;
  input list<Type_a> inTypeALst2;
  input Integer inInteger3;
  output list<Type_a> outTypeALst1;
  output list<Type_a> outTypeALst2;
  replaceable type Type_a;
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
        print("list_split2 failed\n");
      then
        fail();
  end matchcontinue;
end listSplit2;

public function intPositive "function: intPositive
  Returns true if integer value is positive (>= 0)
 
"
  input Integer v;
  output Boolean res;
algorithm 
  res := (v >= 0);
end intPositive;

public function optionToList "function: optionToList
  Returns an empty list for NONE and a list containing
  the one element for SOME. To use with list_append
"
  input Option<Type_a> inTypeAOption;
  output list<Type_a> outTypeALst;
  replaceable type Type_a;
algorithm 
  outTypeALst:=
  matchcontinue (inTypeAOption)
    local Type_a e;
    case NONE then {}; 
    case SOME(e) then {e}; 
  end matchcontinue;
end optionToList;

public function flattenOption "function: flattenOption
  Returns the second argument if NONE and
  the contents of SOME if SOME
"
  input Option<Type_a> inTypeAOption;
  input Type_a inTypeA;
  output Type_a outTypeA;
  replaceable type Type_a;
algorithm 
  outTypeA:=
  matchcontinue (inTypeAOption,inTypeA)
    local Type_a n,c;
    case (NONE,n) then n; 
    case (SOME(c),n) then c; 
  end matchcontinue;
end flattenOption;

public function isEmptyString "function: isEmptyString
 
  Returns true if string is the empty string.
"
  input String inString;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inString)
    case "" then true; 
    case _ then false; 
  end matchcontinue;
end isEmptyString;

public function isNotEmptyString "function: isNotEmptyString
 
  Returns true if string is not the empty string.
"
  input String inString;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inString)
    case "" then false; 
    case _ then true; 
  end matchcontinue;
end isNotEmptyString;

public function writeFileOrErrorMsg "function: writeFileOrErrorMsg
 
  This function tries to write to a file and if it
  fails then it outputs \"# Cannot write to file: <filename>.\" to 
  errorbuf
"
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

public function systemCallWithErrorMsg "this function executes a command with System.systemCall 
  if System.systemCall does not return 0 then the msg is outputed to
  error_buf and the function fails
"
  input String inString1;
  input String inString2;
algorithm 
  _:=
  matchcontinue (inString1,inString2)
    local String s_call,e_msg;
    case (s_call,_) /* command error_msg to error_buf if fail */ 
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

public function charlistcompare "function: charlistcompare
 
  Compares two char lists up to the nth potision and
  returns true if they are equal.
"
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
    case ((a :: _),(b :: _),1)
      equation 
        equality(a = b);
      then
        true;
    case ((a :: _),(b :: _),1)
      equation 
        failure(equality(a = b));
      then
        false;
    case ((a :: l1),(b :: l2),n)
      equation 
        n1 = n - 1;
        equality(a = b);
        true = charlistcompare(l1, l2, n1);
      then
        true;
    case (_,_,_) then false; 
  end matchcontinue;
end charlistcompare;

public function strncmp "function: strncmp
 
  Comparse two strings up to the nth character
  Returns true if they are equal.
"
  input String inString1;
  input String inString2;
  input Integer inInteger3;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
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
        true = charlistcompare(clst1, clst2, n);
      then
        true;
    case (_,_,_) then false; 
  end matchcontinue;
end strncmp;

public function tickStr "function: tickStr
  author: PA
 
  Returns tick as a string, i.e. an unique number.
"
  output String s;
  Integer i;
algorithm 
  i := tick();
  s := intString(i);
end tickStr;

protected function replaceSlashWithPathDelimiter "function replaceSlashWithPathDelimiter
  author: x02lucpo
  
  replace the \"/\" with the system-pathdelimiter.
  On window must be \\ so that the get_absolute_directory_and_file works
"
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
  (\"..\\work\\file.mo\") => (\"c:\\openmodelica123\\work\", \"file.mo\")
"
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
        (pd_chr :: {}) = string_list_string_char(pd);
        (list_path :: {}) = stringSplitAtChar(file, pd_chr) "same dir only filename as param" ;
        res = System.pwd();
      then
        (res,list_path);
    case (file_1)
      local list<String> list_path;
      equation 
        file = replaceSlashWithPathDelimiter(file_1);
        pd = System.pathDelimiter();
        (pd_chr :: {}) = string_list_string_char(pd);
        list_path = stringSplitAtChar(file, pd_chr);
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
        Debug.fprint("failtrace", "-get_absolute_directory_and_file  failed");
      then
        fail();
  end matchcontinue;
end getAbsoluteDirectoryAndFile;


public function rawStringToInputString "function: rawStringToInputString
  author: x02lucpo
 
  replace the double-backslash with backslash
"
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



end Util;

