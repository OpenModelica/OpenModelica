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
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := b1 and b2;
end boolAnd;

function boolOr
  input Boolean b1;
  input Boolean b2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := b1 or b2;
end boolOr;

function boolNot
  input Boolean b;
  output Boolean nb;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  nb := not b;
end boolNot;

function boolEq
  input Boolean b1;
  input Boolean b2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := b1 == b2;
end boolEq;

function boolString
  input Boolean b;
  output String str;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  str := if b then "true" else "false";
end boolString;

function intAdd
  input Integer i1;
  input Integer i2;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  i := i1 + i2;
end intAdd;

function intSub
  input Integer i1;
  input Integer i2;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  i := i1 - i2;
end intSub;

function intMul
  input Integer i1;
  input Integer i2;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  i := i1 * i2;
end intMul;

function intDiv
  input Integer i1;
  input Integer i2;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  i := div(i1,i2);
end intDiv;

function intMod
  input Integer i1;
  input Integer i2;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  i := mod(i1,i2);
end intMod;

function intMax
  input Integer i1;
  input Integer i2;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  i := max(i1,i2);
end intMax;

function intMin
  input Integer i1;
  input Integer i2;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  i := min(i1,i2);
end intMin;

function intAbs
  input Integer i;
  output Integer oi;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  oi := abs(i);
end intAbs;

function intNeg
  input Integer i;
  output Integer oi;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  oi := -i;
end intNeg;

function intLt
  input Integer i1;
  input Integer i2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := i1 < i2;
end intLt;

function intLe
  input Integer i1;
  input Integer i2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := i1 <= i2;
end intLe;

function intEq
  input Integer i1;
  input Integer i2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := i1 == i2;
end intEq;

function intNe
  input Integer i1;
  input Integer i2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := i1 <> i2;
end intNe;

function intGe
  input Integer i1;
  input Integer i2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := i1 >= i2;
end intGe;

function intGt
  input Integer i1;
  input Integer i2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := i1 > i2;
end intGt;

function intReal
  input Integer i;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  r := i;
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
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  r := r1+r2;
end realAdd;

function realSub
  input Real r1;
  input Real r2;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  r := r1-r2;
end realSub;

function realMul
  input Real r1;
  input Real r2;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  r := r1*r2;
end realMul;

function realDiv
  input Real r1;
  input Real r2;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  r := r1/r2;
end realDiv;

function realMod
  input Real r1;
  input Real r2;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  r := mod(r1,r2);
end realMod;

function realPow
  input Real r1;
  input Real r2;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  r := r1^r2;
end realPow;

function realMax
  input Real r1;
  input Real r2;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  r := max(r1,r2);
end realMax;

function realMin
  input Real r1;
  input Real r2;
  output Real r;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  r := min(r1,r2);
end realMin;

function realAbs
  input Real x;
  output Real y;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  y := abs(x);
end realAbs;

function realNeg
  input Real x;
  output Real y;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  y := -x;
end realNeg;

function realLt
  input Real x1;
  input Real x2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := x1 < x2;
end realLt;

function realLe
  input Real x1;
  input Real x2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := x1 <= x2;
end realLe;

function realEq
  input Real x1;
  input Real x2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := x1 == x2;
end realEq;

function realNe
  input Real x1;
  input Real x2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := x1 <> x2;
end realNe;

function realGe
  input Real x1;
  input Real x2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := x1 >= x2;
end realGe;

function realGt
  input Real x1;
  input Real x2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := x1 > x2;
end realGt;

function realInt
  input Real r;
  output Integer i;
  annotation(__OpenModelica_EarlyInline = true);
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

function stringListStringChar
  input String str;
  output list<String> chars;
external "builtin";
end stringListStringChar;

function stringAppendList
  input list<String> strs;
  output String str;
external "builtin";
end stringAppendList;

function stringLength
  input String str;
  output Integer i;
external "builtin";
end stringLength;

function stringGetStringChar
  input String str;
  input Integer index;
  output String ch;
external "builtin";
end stringGetStringChar;

function stringUpdateStringChar
  input String str;
  input String newch;
  input Integer index;
  output String news;
external "builtin";
end stringUpdateStringChar;

function stringAppend
  input String s1;
  input String s2;
  output String s;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  s := s1 + s2;
end stringAppend;

function stringEq
  input String s1;
  input String s2;
  output Boolean b;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  b := s1 == s2;
end stringEq;

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

function stringHashSdbm
  input String str;
  output Integer hash;
external "builtin";
end stringHashSdbm;

function listAppend
  input list<TypeA> lst1;
  input list<TypeA> lst2;
  output list<TypeA> lst;
  replaceable type TypeA subtypeof Any;
external "builtin";
end listAppend;
  
function listReverse
  input list<TypeA> inLst;
  output list<TypeA> outLst;
  replaceable type TypeA subtypeof Any;
external "builtin";
end listReverse;

function listLength
  input list<TypeA> lst;
  output Integer length;
  replaceable type TypeA subtypeof Any;
external "builtin";
end listLength;

function listMember
  input TypeA element;
  input list<TypeA> lst;
  output Boolean isMember;
  replaceable type TypeA subtypeof Any;
external "builtin";
end listMember;

function listGet
  input list<TypeA> lst;
  input Integer index;
  output TypeA element;
  replaceable type TypeA subtypeof Any;
external "builtin";
end listGet;

function listNth
  input list<TypeA> lst;
  input Integer index;
  output TypeA element;
  replaceable type TypeA subtypeof Any;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  element := listGet(lst,index+1);
end listNth;

function listRest
  input list<TypeA> lst;
  output list<TypeA> rest;
  replaceable type TypeA subtypeof Any;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  (_::rest) := lst;
end listRest;

function listHead
  input list<TypeA> lst;
  output TypeA head;
  replaceable type TypeA subtypeof Any;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  (head::_) := lst;
end listHead;

function listDelete
  input list<TypeA> inLst;
  input Integer index;
  output list<TypeA> outLst;
  replaceable type TypeA subtypeof Any;
external "builtin";
end listDelete;

function listEmpty
  input list<TypeA> lst;
  output Boolean isEmpty;
  replaceable type TypeA subtypeof Any;
external "builtin";
end listEmpty;
  
function cons
  input TypeA element;
  input list<TypeA> inLst;
  output list<TypeA> outLst;
  replaceable type TypeA subtypeof Any;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outLst := element::inLst;
end cons;

function arrayLength
  input array<TypeA> arr;
  output Integer length;
  replaceable type TypeA subtypeof Any;
external "builtin";
end arrayLength;

function arrayGet
  input array<TypeA> arr;
  input Integer index;
  output TypeA value;
  replaceable type TypeA subtypeof Any;
external "builtin";
end arrayGet;

function arrayNth
  input array<TypeA> arr;
  input Integer index;
  output TypeA value;
  replaceable type TypeA subtypeof Any;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  value := arrayGet(arr,index+1);
end arrayNth;

function arrayCreate
  input Integer size;
  input TypeA initialValue;
  output array<TypeA> arr;
  replaceable type TypeA subtypeof Any;
external "builtin";
end arrayCreate;

function arrayList
  input array<TypeA> arr;
  output list<TypeA> lst;
  replaceable type TypeA subtypeof Any;
external "builtin";
end arrayList;

function listArray
  input list<TypeA> lst;
  output array<TypeA> arr;
  replaceable type TypeA subtypeof Any;
external "builtin";
end listArray;

function arrayUpdate
  input array<TypeA> arr;
  input Integer index;
  input TypeA newValue;
  output array<TypeA> newArray "same as the input array; not really needed here";
  replaceable type TypeA subtypeof Any;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end arrayUpdate;

function arrayCopy
  input array<TypeA> arr;
  output array<TypeA> copy;
  replaceable type TypeA subtypeof Any;
external "builtin";
end arrayCopy;

function arrayAdd "An arrayAppend operation would be more useful; this is very slow if used improperly!"
  input array<TypeA> arr;
  input TypeA a;
  output array<TypeA> copy;
  replaceable type TypeA subtypeof Any;
external "builtin";
end arrayAdd;

function anyString
  "Returns the string representation of any value."
  input TypeA a;
  output String str;
  replaceable type TypeA subtypeof Any;
external "builtin";
end anyString;

function printAny
  input TypeA a;
  replaceable type TypeA subtypeof Any;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end printAny;

function debug_print
  input String str;
  input TypeA a;
  replaceable type TypeA subtypeof Any;
  annotation(__OpenModelica_Impure = true);
algorithm
  print(str);
  print(anyString(a));
end debug_print;

function tick
  output Integer t;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end tick;

function equality
  input TypeA a1;
  input TypeA a2;
  replaceable type TypeA subtypeof Any;
external "builtin";
end equality;

function setGlobalRoot
  "Sets the index of the root variable with index 0..1023. This is a global mutable
  value and should be used sparingly.
  "
  input Integer index;
  input TypeA value;
  replaceable type TypeA subtypeof Any;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end setGlobalRoot;

function valueConstructor
  input TypeA value;
  output Integer ctor;
  replaceable type TypeA subtypeof Any;
external "builtin";
end valueConstructor;

function valueSlots
  input TypeA value;
  output Integer slots;
  replaceable type TypeA subtypeof Any;
external "builtin";
end valueSlots;

function valueEq
  input TypeA a1;
  input TypeA a2;
  output Boolean b;
  replaceable type TypeA subtypeof Any;
external "builtin";
end valueEq;

function referenceEq
  "This is a very fast comparison of two values.
  It only checks if the pointers are equal."
  input TypeA a1;
  input TypeA a2;
  output Boolean b;
  replaceable type TypeA subtypeof Any;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end referenceEq;

function clock
  "Use the diff to compare two time samples to each other. Not very accurate."
  output Real t;
  annotation(__OpenModelica_Impure = true);
external "builtin";
end clock;

function optionNone "Returns true if the input is NONE()"
  input Option<TypeA> opt;
  output Boolean isNone;
external "builtin";
end optionNone;