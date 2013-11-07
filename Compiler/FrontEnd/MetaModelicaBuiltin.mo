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

function boolAnd
  input Boolean b1;
  input Boolean b2;
  output Boolean b;
algorithm
  b := b1 and b2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end boolAnd;

function boolOr
  input Boolean b1;
  input Boolean b2;
  output Boolean b;
algorithm
  b := b1 or b2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end boolOr;

function boolNot
  input Boolean b;
  output Boolean nb;
algorithm
  nb := not b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end boolNot;

function boolEq
  input Boolean b1;
  input Boolean b2;
  output Boolean b;
algorithm
  b := b1 == b2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end boolEq;

function boolString
  input Boolean b;
  output String str;
algorithm
  str := if b then "true" else "false";
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end boolString;

function intAdd
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := i1 + i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intAdd;

function intSub
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := i1 - i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intSub;

function intMul
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := i1 * i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intMul;

function intDiv
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := div(i1,i2);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intDiv;

function intMod
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := mod(i1,i2);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intMod;

function intMax
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := max(i1,i2);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intMax;

function intMin
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := min(i1,i2);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intMin;

function intAbs
  input Integer i;
  output Integer oi;
algorithm
  oi := abs(i);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intAbs;

function intNeg
  input Integer i;
  output Integer oi;
algorithm
  oi := -i;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intNeg;

function intLt
  input Integer i1;
  input Integer i2;
  output Boolean b;
algorithm
  b := i1 < i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intLt;

function intLe
  input Integer i1;
  input Integer i2;
  output Boolean b;
algorithm
  b := i1 <= i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intLe;

function intEq
  input Integer i1;
  input Integer i2;
  output Boolean b;
algorithm
  b := i1 == i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intEq;

function intNe
  input Integer i1;
  input Integer i2;
  output Boolean b;
algorithm
  b := i1 <> i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intNe;

function intGe
  input Integer i1;
  input Integer i2;
  output Boolean b;
algorithm
  b := i1 >= i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intGe;

function intGt
  input Integer i1;
  input Integer i2;
  output Boolean b;
algorithm
  b := i1 > i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intGt;

function intBitNot
  input Integer i;
  output Integer o;
external "builtin";
annotation(Documentation(info="<html>
<p>Bit-wise and (like C, ~i).</p>
</html>"));
end intBitNot;

function intBitAnd
  input Integer i1;
  input Integer i2;
  output Integer o;
external "builtin";
annotation(Documentation(info="<html>
<p>Bit-wise and (like C, i1 &amp; i2).</p>
</html>"));
end intBitAnd;

function intBitOr
  input Integer i1;
  input Integer i2;
  output Integer o;
external "builtin";
annotation(Documentation(info="<html>
<p>Bit-wise or (like C, i1 | i2).</p>
</html>"));
end intBitOr;

function intBitXor
  input Integer i1;
  input Integer i2;
  output Integer o;
external "builtin";
annotation(Documentation(info="<html>
<p>Bit-wise exclusive or (like C, i1 ^ i2).</p>
</html>"));
end intBitXor;

function intBitLShift
  input Integer i;
  input Integer s;
  output Integer o;
external "builtin";
annotation(Documentation(info="<html>
<p>Bit-wise left shift (like C, i << s).</p>
</html>"));
end intBitLShift;

function intBitRShift
  input Integer i;
  input Integer s;
  output Integer o;
external "builtin";
annotation(Documentation(info="<html>
<p>Bit-wise right shift (like C, i << s).</p>
</html>"));
end intBitRShift;

function intReal
  input Integer i;
  output Real r;
algorithm
  r := i;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intReal;

function intString
  input Integer i;
  output String s;
  external "builtin";
end intString;

/* Real functions */
function realAdd
  input Real r1;
  input Real r2;
  output Real r;
algorithm
  r := r1+r2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realAdd;

function realSub
  input Real r1;
  input Real r2;
  output Real r;
algorithm
  r := r1-r2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realSub;

function realMul
  input Real r1;
  input Real r2;
  output Real r;
algorithm
  r := r1*r2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realMul;

function realDiv
  input Real r1;
  input Real r2;
  output Real r;
algorithm
  r := r1/r2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realDiv;

function realMod
  input Real r1;
  input Real r2;
  output Real r;
algorithm
  r := mod(r1,r2);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realMod;

function realPow
  input Real r1;
  input Real r2;
  output Real r;
algorithm
  r := r1^r2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realPow;

function realMax
  input Real r1;
  input Real r2;
  output Real r;
algorithm
  r := max(r1,r2);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realMax;

function realMin
  input Real r1;
  input Real r2;
  output Real r;
algorithm
  r := min(r1,r2);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realMin;

function realAbs
  input Real x;
  output Real y;
algorithm
  y := abs(x);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realAbs;

function realNeg
  input Real x;
  output Real y;
algorithm
  y := -x;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realNeg;

function realLt
  input Real x1;
  input Real x2;
  output Boolean b;
algorithm
  b := x1 < x2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realLt;

function realLe
  input Real x1;
  input Real x2;
  output Boolean b;
algorithm
  b := x1 <= x2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realLe;

function realEq
  input Real x1;
  input Real x2;
  output Boolean b;
algorithm
  b := x1 == x2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realEq;

function realNe
  input Real x1;
  input Real x2;
  output Boolean b;
algorithm
  b := x1 <> x2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realNe;

function realGe
  input Real x1;
  input Real x2;
  output Boolean b;
algorithm
  b := x1 >= x2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realGe;

function realGt
  input Real x1;
  input Real x2;
  output Boolean b;
algorithm
  b := x1 > x2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end realGt;

function realInt
  input Real r;
  output Integer i;
algorithm
  i := integer(r);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
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
algorithm
  s := s1 + s2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end stringAppend;

function stringEq
  input String s1;
  input String s2;
  output Boolean b;
algorithm
  b := s1 == s2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end stringEq;

function stringEqual
  input String s1;
  input String s2;
  output Boolean b;
algorithm
  b := s1 == s2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
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
algorithm
  element := listGet(lst,index+1);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
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
algorithm
  outLst := element::inLst;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
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
algorithm
  value := arrayGet(arr,index+1);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
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
external "builtin";
  annotation(__OpenModelica_Impure = true);
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
external "builtin";
  annotation(__OpenModelica_Impure = true);
end printAny;

function debug_print<A>
  "For RML compatibility"
  input String str;
  input A a;
external "builtin";
  annotation(__OpenModelica_Impure = true);
end debug_print;

function tick
  output Integer t;
external "builtin";
  annotation(__OpenModelica_Impure = true);
end tick;

function equality<A>
  input A a1;
  input A a2;
external "builtin";
end equality;

function setGlobalRoot<A>
  "Sets the index of the root variable with index 0..1023.
  This is a global mutable value and should be used sparingly.

  You are recommended not to use 0 or false since the runtime system may treat these values as uninitialized and fail getGlobalRoot later on.
  "
  input Integer index;
  input A value;
external "builtin";
  annotation(__OpenModelica_Impure = true);
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
  "This is a very fast comparison of two values which only checks if the pointers are equal."
  input A a1;
  input A a2;
  output Boolean b;
external "builtin";
  annotation(__OpenModelica_Impure = true, Documentation(info="<html>
<p>This is a very fast comparison of two values which only checks if the pointers are equal.</p>
<p>The intended way of using the function is to speed up comparisons.</p>
<p>If you know that all occurances of REC(1.5) are the same pointer (e.g. if you made a pass on your datastructure that replaced all occurances with a single one),
you can use referenceEq instead of structural equality (<a href=\"modelica://MetaModelica.valueEq\">valueEq</a> or a user-provided comparison).</p>
<p>You can also use the function to speed up comparsions if the rate of success is expected to be high or the cost of structural equality is high. But then you need to do a structural equality check after to make sure nothing is wrong.</p>
<p>You can use the function to avoid reconstructing an identical datastructure on traversals, which saves memory and time spent on garbage collection: case rec as REC(x) equation nx = f(x); then if referenceEq(x,nx) then rec else REC(nx);</p>
</html>"));
end referenceEq;

function clock
  "Use the diff to compare two time samples to each other. Not very accurate."
  output Real t;
external "builtin";
  annotation(__OpenModelica_Impure = true);
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

function setStackOverflowSignal
  "Sets the stack overflow signal to the given value and returns the old one"
  input Boolean inSignal;
  output Boolean outSignal;
algorithm
  outSignal := inSignal;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end setStackOverflowSignal;

function referenceDebugString<A>
  input A functionSymbol;
  output String name;
  external "builtin" annotation(Documentation(info="<html>
<p>Takes any function pointer as input and returns its symbol name in the C-code (for debugging function pointers).</p>
<p>Is only useful on good operating systems.</p>
</html>"));
end referenceDebugString;
