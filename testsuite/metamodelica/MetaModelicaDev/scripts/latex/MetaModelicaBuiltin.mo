function boolAnd
  input Boolean b1;
  input Boolean b2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := b1 and b2;
end boolAnd;

function boolOr
  input Boolean b1;
  input Boolean b2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := b1 or b2;
end boolOr;

function boolNot
  input Boolean b;
  output Boolean nb;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  nb := not b;
end boolNot;

function boolEq
  input Boolean b1;
  input Boolean b2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := b1 == b2;
end boolEq;

function boolString
  input Boolean b;
  output String str;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  str := if b then "true" else "false";
end boolString;

function intAdd
  input Integer i1;
  input Integer i2;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  i := i1 + i2;
end intAdd;

function intSub
  input Integer i1;
  input Integer i2;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  i := i1 - i2;
end intSub;

function intMul
  input Integer i1;
  input Integer i2;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  i := i1 * i2;
end intMul;

function intDiv
  input Integer i1;
  input Integer i2;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  i := div(i1,i2);
end intDiv;

function intMod
  input Integer i1;
  input Integer i2;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  i := mod(i1,i2);
end intMod;

function intMax
  input Integer i1;
  input Integer i2;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  i := max(i1,i2);
end intMax;

function intMin
  input Integer i1;
  input Integer i2;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  i := min(i1,i2);
end intMin;

function intAbs
  input Integer i;
  output Integer oi;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  oi := abs(i);
end intAbs;

function intNeg
  input Integer i;
  output Integer oi;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  oi := -i;
end intNeg;

function intLt
  input Integer i1;
  input Integer i2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := i1 < i2;
end intLt;

function intLe
  input Integer i1;
  input Integer i2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := i1 <= i2;
end intLe;

function intEq
  input Integer i1;
  input Integer i2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := i1 == i2;
end intEq;

function intNe
  input Integer i1;
  input Integer i2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := i1 <> i2;
end intNe;

function intGe
  input Integer i1;
  input Integer i2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := i1 >= i2;
end intGe;

function intGt
  input Integer i1;
  input Integer i2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := i1 > i2;
end intGt;

function intReal
  input Integer i;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  r := i;
end intReal;

function intString
  input Integer i;
  output String s;
  external "builtin";
end intString;


function realAdd
  input Real r1;
  input Real r2;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  r := r1+r2;
end realAdd;

function realSub
  input Real r1;
  input Real r2;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  r := r1-r2;
end realSub;

function realMul
  input Real r1;
  input Real r2;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  r := r1*r2;
end realMul;

function realDiv
  input Real r1;
  input Real r2;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  r := r1/r2;
end realDiv;

function realMod
  input Real r1;
  input Real r2;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  r := mod(r1,r2);
end realMod;

function realPow
  input Real r1;
  input Real r2;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  r := r1^r2;
end realPow;

function realMax
  input Real r1;
  input Real r2;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  r := max(r1,r2);
end realMax;

function realMin
  input Real r1;
  input Real r2;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  r := min(r1,r2);
end realMin;

function realAbs
  input Real x;
  output Real y;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  y := abs(x);
end realAbs;

function realNeg
  input Real x;
  output Real y;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  y := -x;
end realNeg;

function realLt
  input Real x1;
  input Real x2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := x1 < x2;
end realLt;

function realLe
  input Real x1;
  input Real x2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := x1 <= x2;
end realLe;

function realEq
  input Real x1;
  input Real x2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := x1 == x2;
end realEq;

function realNe
  input Real x1;
  input Real x2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := x1 <> x2;
end realNe;

function realGe
  input Real x1;
  input Real x2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := x1 >= x2;
end realGe;

function realGt
  input Real x1;
  input Real x2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := x1 > x2;
end realGt;

function realInt
  input Real r;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  i := integer(r);
end realInt;

function realString
  input Real r;
  output String str;
external "builtin";
end realString;

function stringCharInt
  input String ch;
  output Integer i;
external "builtin";
end stringCharInt;

function intStringChar
  input Integer i;
  output String ch;
external "builtin";
end intStringChar;

function stringInt
  input String str;
  output Integer i;
external "builtin";
end stringInt;

function stringReal
"This function fails unless the whole string can be consumed by strtod without
setting errno. For more details, see man 3 strtod"
  input String str;
  output Real r;
external "builtin";
end stringReal;

function stringListStringChar "O(str)"
  input String str;
  output List<String> chars;
external "builtin";
end stringListStringChar;

function stringAppendList "O(str)"
  input List<String> strs;
  output String str;
external "builtin";
end stringAppendList;

function stringDelimitList
  "O(str)
  Takes a list of strings and a string delimiter and appends all
  list elements with the string delimiter inserted between elements.
  Example: stringDelimitList({\"x\",\"y\",\"z\"}, \", \") => \"x, y, z\""
  input List<String> strs;
  input String delimiter;
  output String str;
external "builtin";
end stringDelimitList;

function stringLength "O(1)"
  input String str;
  output Integer i;
external "builtin";
end stringLength;

function stringGetStringChar "O(1)"
  input String str;
  input Integer index;
  output String ch;
external "builtin";
end stringGetStringChar;

function stringUpdateStringChar "O(n)"
  input String str;
  input String newch;
  input Integer index;
  output String news;
external "builtin";
end stringUpdateStringChar;

function stringAppend "O(s1+s2)"
  input String s1;
  input String s2;
  output String s;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  s := s1 + s2;
end stringAppend;

function stringEq
  input String s1;
  input String s2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := s1 == s2;
end stringEq;

function stringEqual
  input String s1;
  input String s2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  b := s1 == s2;
end stringEqual;

function stringCompare
  input String s1;
  input String s2;
  output Integer cmp;
external "builtin";
end stringCompare;

function stringHash
  input String str;
  output Integer hash;
external "builtin";
end stringHash;

function stringHashDjb2
  input String str;
  output Integer hash;
external "builtin";
end stringHashDjb2;

function stringHashDjb2Mod "Does hashing+modulo without intermediate results."
  input String str;
  input Integer mod;
  output Integer hash;
external "builtin";
end stringHashDjb2Mod;

function stringHashSdbm
  input String str;
  output Integer hash;
external "builtin";
end stringHashSdbm;

function listAppend<A> "O(length(lst1)), O(1) if either list is empty"
  input List<A> lst1;
  input List<A> lst2;
  output List<A> lst;
external "builtin";
end listAppend;

function listReverse<A> "O(n)"
  input List<A> inLst;
  output List<A> outLst;
external "builtin";
end listReverse;

function listLength<A> "O(n)"
  input List<A> lst;
  output Integer length;
external "builtin";
end listLength;

function listMember<A> "O(n)"
  input A element;
  input List<A> lst;
  output Boolean isMember;
external "builtin";
end listMember;

function listGet<A> "O(index)"
  input List<A> lst;
  input Integer index;
  output A element;
external "builtin";
end listGet;

function listNth<A> "index from 0; this function is deprecated"
  input List<A> lst;
  input Integer index;
  output A element;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  element := listGet(lst,index+1);
end listNth;

function listRest<A> "O(1)"
  input List<A> lst;
  output List<A> rest;
external "builtin";
end listRest;

function listHead<A> "O(1)"
  input List<A> lst;
  output A head;
external "builtin";
end listHead;

function listDelete<A> "O(index)"
  input List<A> inLst;
  input Integer index;
  output List<A> outLst;
external "builtin";
end listDelete;

function listEmpty<A> "O(1)"
  input List<A> lst;
  output Boolean isEmpty;
external "builtin";
end listEmpty;

function cons<A> "O(1)"
  input A element;
  input List<A> inLst;
  output List<A> outLst;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  outLst := element::inLst;
end cons;

function arrayLength<A> "O(1)"
  input array<A> arr;
  output Integer length;
external "builtin";
end arrayLength;

function arrayGet<A> "O(1)"
  input array<A> arr;
  input Integer index;
  output A value;
external "builtin";
end arrayGet;

function arrayNth<A> "index from 0 is depreceated; use arrayGet"
  input array<A> arr;
  input Integer index;
  output A value;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
algorithm
  value := arrayGet(arr,index+1);
end arrayNth;

function arrayCreate<A>
  "O(size)"
  input Integer size;
  input A initialValue;
  output array<A> arr;
external "builtin";
end arrayCreate;

function arrayList<A>
  "O(n)"
  input array<A> arr;
  output List<A> lst;
external "builtin";
end arrayList;

function listArray<A>
  "O(n)"
  input List<A> lst;
  output array<A> arr;
external "builtin";
end listArray;

function arrayUpdate<A>
  "O(1)"
  input array<A> arr;
  input Integer index;
  input A newValue;
  output array<A> newArray "same as the input array; used for folding";
  annotation(__OpenModelica_Impure = true);
external "builtin";
end arrayUpdate;

function arrayCopy<A>
  "O(n)"
  input array<A> arr;
  output array<A> copy;
external "builtin";
end arrayCopy;

function arrayAdd<A> "An arrayAppend operation would be more useful; O(n) per addition."
  input array<A> arr;
  input A a;
  output array<A> copy;
external "builtin";
end arrayAdd;

function anyString<A>
  "Returns the string representation of any value.
  Rather slow; only use this for debugging!"
  input A a;
  output String str;
external "builtin";
end anyString;

function printAny<A>
  "print(anyString(a)), but to stderr"
  input A a;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end printAny;

function debug_print<A>
  "For RML compatibility"
  input String str;
  input A a;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end debug_print;

function tick
  output Integer t;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end tick;

function equality<A>
  input A a1;
  input A a2;
external "builtin";
end equality;

function setGlobalRoot<A>
  "Sets the index of the root variable with index 0..1023.
  This is a global mutable value and should be used sparingly.
  "
  input Integer index;
  input A value;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end setGlobalRoot;

function valueConstructor<A>
  "The return-value is compiler-dependent on the runtime implementation of
  boxed values. The number of bits reserved for the constructor is generally
  between 6 and 8 bits."
  input A value;
  output Integer ctor;
external "builtin";
end valueConstructor;

function valueSlots<A>
  "The number of slots a boxed value has. This is dependent on sizeof(void*)
  on the architecture in question."
  input A value;
  output Integer slots;
external "builtin";
end valueSlots;

function valueEq<A>
  "Structural equality"
  input A a1;
  input A a2;
  output Boolean b;
external "builtin";
end valueEq;

function valueHashMod<A>
  input A value;
  input Integer mod;
  output Integer hash;
external "builtin";
end valueHashMod;

function referenceEq<A>
  "This is a very fast comparison of two values.
  It only checks if the pointers are equal."
  input A a1;
  input A a2;
  output Boolean b;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end referenceEq;

function clock
  "Use the diff to compare two time samples to each other. Not very accurate."
  output Real t;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end clock;

function isNone<A> "Returns true if the input is NONE()"
  input Option<A> opt;
  output Boolean none;
external "builtin";
end isNone;

type NONE end NONE;
type SOME end SOME;

function listStringCharString
  input List<String> strs;
  output String str;
external "builtin" str=stringAppendList(strs);
end listStringCharString;

function stringCharListString
  input List<String> strs;
  output String str;
external "builtin" str=stringAppendList(strs);
end stringCharListString;

function realCos
  input Real x;
  output Real y;
external "builtin" y=cos(x);
end realCos;

function realCosh
  input Real x;
  output Real y;
external "builtin" y=cosh(x);
end realCosh;

function realAcos
  input Real x;
  output Real y;
external "builtin" y=acos(x);
end realAcos;

function realSin
  input Real x;
  output Real y;
external "builtin" y=sin(x);
end realSin;

function realSinh
  input Real x;
  output Real y;
external "builtin" y=sinh(x);
end realSinh;

function realAsin
  input Real x;
  output Real y;
external "builtin" y=asin(x);
end realAsin;

function realAtan
  input Real x;
  output Real y;
external "builtin" y=atan(x);
end realAtan;

function realAtan2
  input Real x1;
  input Real x2;
  output Real y;
external "builtin" y=atan2(x1,x2);
end realAtan2;

function realTanh
  input Real x;
  output Real y;
external "builtin" y=tanh(x);
end realTanh;

function realExp
  input Real x(unit = "1");
  output Real y(unit = "1");
external "builtin" y=exp(x);
end realExp;

function realLn
  input Real x(unit = "1");
  output Real y(unit = "1");
external "builtin" y=log(x);
end realLn;

function realLog10
  input Real x(unit = "1");
  output Real y(unit = "1");
external "builtin" y=log10(x);
end realLog10;

function realCeil
  input Real x;
  output Real y;
external "builtin" y=ceil(x);
end realCeil;

function realFloor
  input Real x;
  output Real y;
external "builtin" y=floor(x);
end realFloor;

function realSqrt
  input Real x(unit = "'p");
  output Real y(unit = "'p(1/2)");
external "builtin" y=sqrt(x);
end realSqrt;

function fail
  external "builtin";
end fail;
