uniontype abc
  record ABC
    Integer a,b,c;
  end ABC;
  record AB
    list<T> a;
    list<list<Integer>> b;
    replaceable type T subtypeof Any;
  end AB;
end abc;

function abcIdent
  input abc value;
  output abc res;
algorithm
  res := value;
end abcIdent;

function TakesAnyList
  input list<T> i;
  output String s;
  replaceable type T subtypeof Any;
algorithm
  s := "Test";
end TakesAnyList;

function NestedFunction
  input T i;
  output T out;
  type T = Integer;
  function Nested
    output Integer out;
  algorithm
    out := 2;
  end Nested;
algorithm
  out := Nested();
end NestedFunction;

function TakesOption
  input Option<Integer> i;
  output String s;
algorithm
  s := "Test";
end TakesOption;

function TakesTuple
  input tuple<Integer,Integer> i;
  output String s;
algorithm
  s := "Test";
end TakesTuple;

function TakesAny
  input T i;
  output String s;
  replaceable type T subtypeof Any;
algorithm
  s := "TakesAny";
end TakesAny;

package Util

public function if_
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

public function listMap
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
  outTypeBLst := listMap_impl_2(inTypeALst,{},inFuncTypeTypeAToTypeB);  
end listMap;

function listMap_impl_2 
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

public function listMap0
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

function ident
  replaceable type TypeA subtypeof Any;
  input TypeA i;
  output TypeA out;
algorithm
  out := i;
end ident;

end Util;
