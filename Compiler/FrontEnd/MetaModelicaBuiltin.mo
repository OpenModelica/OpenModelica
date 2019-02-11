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

function boolAnd
  "Logically combine two Booleans with 'and' operator"
  input Boolean b1;
  input Boolean b2;
  output Boolean b;
algorithm
  b := b1 and b2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end boolAnd;

function boolOr
  "Logically combine two Booleans with 'or' operator"
  input Boolean b1;
  input Boolean b2;
  output Boolean b;
algorithm
  b := b1 or b2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end boolOr;

function boolNot
  "Logically invert Boolean value using 'not' operator"
  input Boolean b;
  output Boolean nb;
algorithm
  nb := not b;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end boolNot;

function boolEq
  "Compares two Booleans"
  input Boolean b1;
  input Boolean b2;
  output Boolean b;
algorithm
  b := b1 == b2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end boolEq;

function boolString
  "Returns \"true\" or \"false\" string"
  input Boolean b;
  output String str;
algorithm
  str := if b then "true" else "false";
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end boolString;

function intAdd
  "Adds two Integer values"
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := i1 + i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intAdd;

function intSub
  "Subtracts two Integer values"
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := i1 - i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intSub;

function intMul
  "Multiplies two Integer values"
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := i1 * i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intMul;

function intDiv
  "Divides two Integer values"
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := div(i1,i2);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intDiv;

function intMod
  "Calculates remainder of Integer division i1/i2"
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := mod(i1,i2);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intMod;

function intMax
  "Returns the bigger one of two Integer values"
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := max(i1,i2);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intMax;

function intMin
  "Returns the smaller one of two Integer values"
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := min(i1,i2);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intMin;

function intAbs
  "Returns the absolute value of Integer i"
  input Integer i;
  output Integer oi;
algorithm
  oi := abs(i);
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intAbs;

function intNeg
  "Returns negative value of Integer i"
  input Integer i;
  output Integer oi;
algorithm
  oi := -i;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intNeg;

function intLt
  "Returns whether Integer i1 is smaller than Integer i2"
  input Integer i1;
  input Integer i2;
  output Boolean b;
algorithm
  b := i1 < i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intLt;

function intLe
  "Returns whether Integer i1 is smaller than or equal to Integer i2"
  input Integer i1;
  input Integer i2;
  output Boolean b;
algorithm
  b := i1 <= i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intLe;

function intEq
  "Returns whether Integer i1 is equal to Integer i2"
  input Integer i1;
  input Integer i2;
  output Boolean b;
algorithm
  b := i1 == i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intEq;

function intNe
  "Returns whether Integer i1 is not equal to Integer i2"
  input Integer i1;
  input Integer i2;
  output Boolean b;
algorithm
  b := i1 <> i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intNe;

function intGe
  "Returns whether Integer i1 is greater than or equal to Integer i2"
  input Integer i1;
  input Integer i2;
  output Boolean b;
algorithm
  b := i1 >= i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intGe;

function intGt
  "Returns whether Integer i1 is greater than Integer i2"
  input Integer i1;
  input Integer i2;
  output Boolean b;
algorithm
  b := i1 > i2;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intGt;

function intBitNot
  "Returns bitwise inverted Integer number of i"
  input Integer i;
  output Integer o;
external "builtin";
annotation(Documentation(info="<html>
<p>Bitwise not (like C, ~i).</p>
</html>"));
end intBitNot;

function intBitAnd
  "Returns bitwise 'and' of Integers i1 and i2"
  input Integer i1;
  input Integer i2;
  output Integer o;
external "builtin";
annotation(Documentation(info="<html>
<p>Bitwise and (like C, i1 &amp; i2).</p>
</html>"));
end intBitAnd;

function intBitOr
  "Returns bitwise 'or' of Integers i1 and i2"
  input Integer i1;
  input Integer i2;
  output Integer o;
external "builtin";
annotation(Documentation(info="<html>
<p>Bitwise or (like C, i1 | i2).</p>
</html>"));
end intBitOr;

function intBitXor
  "Returns bitwise 'xor' of Integers i1 and i2"
  input Integer i1;
  input Integer i2;
  output Integer o;
external "builtin";
annotation(Documentation(info="<html>
<p>Bitwise exclusive or (like C, i1 ^ i2).</p>
</html>"));
end intBitXor;

function intBitLShift
  "Returns bitwise left shift of Integer i by s bits"
  input Integer i;
  input Integer s;
  output Integer o;
external "builtin";
annotation(Documentation(info="<html>
<p>Bitwise left shift (like C, i << s).</p>
</html>"));
end intBitLShift;

function intBitRShift
  "Returns bitwise right shift of Integer i by s bits"
  input Integer i;
  input Integer s;
  output Integer o;
external "builtin";
annotation(Documentation(info="<html>
<p>Bitwise right shift (like C, i >> s).</p>
</html>"));
end intBitRShift;

function intReal
  "Converts Integer to Real"
  input Integer i;
  output Real r;
algorithm
  r := i;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end intReal;

function intString
  "Converts Integer to String"
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

function stringEmpty "O(1)"
  input String str;
  output Boolean isEmpty;
algorithm
  isEmpty := stringLength(str) == 0;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end stringEmpty;

function stringGet "O(1)"
  input String str;
  input Integer index;
  output Integer ch;
external "builtin";
end stringGet;

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

function substring
  input String str;
  input Integer start "start index, first character is 1";
  input Integer stop "stop index, first character is 1";
  output String out "Length is stop-start";
external "builtin";
end substring;

function listAppend<A> "O(length(lst1)), O(1) if either list is empty"
  input List<A> lst1;
  input List<A> lst2 = {};
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
  input Integer index "one-based index";
  output A element;
external "builtin";
end listGet;

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
  input Integer index "one-based index" ;
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
  input List<A> inLst = {};
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

function arrayEmpty<A> "O(1)"
  input array<A> arr;
  output Boolean isEmpty;
algorithm
  isEmpty := arrayLength(arr) == 0;
  annotation(__OpenModelica_EarlyInline = true, __OpenModelica_BuiltinPtr = true);
end arrayEmpty;

function arrayGet<A> "O(1)"
  input array<A> arr;
  input Integer index;
  output A value;
external "builtin";
end arrayGet;

impure function arrayCreate<A>
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

impure function listArray<A>
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

function arrayAppend<A>
  "Appends arr2 to arr1. O(length(arr1) + length(arr2)).
   Note that this operation is *not* destructive, i.e. a new array is created."
  input array<A> arr1;
  input array<A> arr2;
  output array<A> arr;
external "builtin";
end arrayAppend;

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
  "Sets the index of the root variable with index 9..1023, or thread-local root variable with index 0..8.
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

function valueCompare<A>
  "a1 > a2?"
  input A a1;
  input A a2;
  output Integer i "-1, 0, 1";
external "builtin";
end valueCompare;

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

function isSome<A> "Returns true if the input is SOME()"
  input Option<A> opt;
  output Boolean some;
external "builtin";
end isSome;

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

function isPresent<T>
  input T ident;
  output Boolean b;
algorithm
  b:=true;
annotation(__OpenModelica_EarlyInline=true, __OpenModelica_BuiltinPtr = true, Documentation(info="<html>
<p>From Modelica 2.x:</p>
<p>Returns true if the formal <strike>input or</strike> output argument <i>ident</i>
is present as an actual argument of the function call. If the argument is not
present, isPresent(ident) may return false [but may also return true e.g. for
implementations that always compute all results]. isPresent() should be used for
optimisation only and should not influence the results of outputs that are present
in the output list. It can only be used in functions.</p>
<p>OpenModelica returns false for other output formal parameters that are
not present in the function call (except the first output, which is always
considered present).</p>
<p>OpenModelica gives a compile-time error if the variable is not an input or output formal parameter.</p>
</html>"));
end isPresent;

package MetaModelica
package Dangerous "Functions that skip bounds checking"

function arrayGetNoBoundsChecking<A> "O(1)"
  input array<A> arr;
  input Integer index;
  output A value;
external "builtin";
end arrayGetNoBoundsChecking;

function arrayUpdateNoBoundsChecking<A> "O(1)"
  input array<A> arr;
  input Integer index;
  input A newValue;
  output array<A> newArray;
external "builtin";
end arrayUpdateNoBoundsChecking;

impure function arrayCreateNoInit<A>
  "Creates a new array where the elements are *not* initialized!. Any attempt to
   access an uninitialized elements may cause segmentation faults if you're
   lucky, and pretty much anything else if you're not. Do not use unless you will
   immediately fill the whole array with data. The dummy variable is used to fix
   the type of the array."
  input Integer size;
  input A dummy;
  output array<A> arr;
external "builtin";
end arrayCreateNoInit;

function stringGetNoBoundsChecking "O(1)"
  input String str;
  input Integer index;
  output Integer ch;
external "builtin";
end stringGetNoBoundsChecking;

function listReverseInPlace<A> "O(n). A destructive listReverse. May cause segmentation faults if the list contains *any* non-NIL element that was allocated in a constant data segment. Will cause all other points to the head or within this list to now point to another list. Do not use unless you are really certain the compiler cannot optimise any part of the list into a constant data segment."
  input list<A> inList;
  output list<A> outList;
external "builtin";
end listReverseInPlace;

function listSetFirst<A> "O(1). A destructive operation changing the \"first\" part of a cons-cell."
  input list<A> inConsCell "A non-empty list";
  input A inNewContent;
external "builtin";
end listSetFirst;

function listSetRest<A> "O(1). A destructive operation changing the \"rest\" part of a cons-cell.
NOTE: Make sure you do NOT create cycles as infinite lists are not handled well in the compiler."
  input list<A> inConsCell "A non-empty list";
  input list<A> inNewRest;
external "builtin";
end listSetRest;

function listArrayLiteral<A>
  "O(n)"
  input list<A> lst;
  output array<A> arr;
external "builtin";
end listArrayLiteral;

end Dangerous;

end MetaModelica;

uniontype SourceInfo "The Info attribute provides location information for elements and classes."
  record SOURCEINFO
    String fileName "fileName where the class is defined in";
    Boolean isReadOnly "isReadOnly : (true|false). Should be true for libraries";
    Integer lineNumberStart "lineNumberStart";
    Integer columnNumberStart "columnNumberStart";
    Integer lineNumberEnd "lineNumberEnd";
    Integer columnNumberEnd "columnNumberEnd";
    Real lastModification "mtime in stat(2), stored as a double for increased precision on 32-bit platforms";
  end SOURCEINFO;
end SourceInfo;

function sourceInfo
  output SourceInfo info;
external "builtin";
end sourceInfo;
