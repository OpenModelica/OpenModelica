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

encapsulated package Util
" file:        Util.mo
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

public uniontype Status "Used to signal success or failure of a function call"
  record SUCCESS end SUCCESS;
  record FAILURE end FAILURE;
end Status;

public uniontype DateTime
  record DATETIME
    Integer sec;
    Integer min;
    Integer hour;
    Integer mday;
    Integer mon;
    Integer year;
  end DATETIME;
end DateTime;

public import Absyn;
protected import Config;
protected import Debug;
protected import Error;
protected import Flags;
protected import Global;
protected import List;
protected import Print;
protected import System;

public constant String derivativeNamePrefix="$DER";
public constant String pointStr = "$P";
public constant String leftBraketStr = "$lB";
public constant String rightBraketStr = "$rB";
public constant String leftParStr = "$lP";
public constant String rightParStr = "$rP";
public constant String commaStr = "$c";

protected constant list<ReplacePattern> replaceStringPatterns=
         {REPLACEPATTERN(".",pointStr),
          REPLACEPATTERN("[",leftBraketStr),REPLACEPATTERN("]",rightBraketStr),
          REPLACEPATTERN("(",leftParStr),REPLACEPATTERN(")",rightParStr),
          REPLACEPATTERN(",",commaStr)};

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
algorithm b := lhs>. rhs;
end isRealGreater;

public function linuxDotSlash "If operating system is Linux/Unix, return a './', otherwise return empty string"
  output String str;
algorithm
  str := matchcontinue()
    case()
      equation
        str = System.os();
        true = ("linux" ==& str) or ("OSX" ==& str);
      then "./";
    case() then "";
  end matchcontinue;
end linuxDotSlash;


public function flagValue "author: x02lucpo
  Extracts the flagvalue from an argument list:
  flagValue('-s',{'-d','hej','-s','file'}) => 'file'"
  input String flag;
  input list<String> arguments;
  output String flagVal;
algorithm
  flagVal :=
   matchcontinue(flag,arguments)
   local
      String arg,value;
      list<String> args;
   case (_,{}) then "";
   case(_,arg::{})
      equation
        0 = stringCompare(flag,arg);
      then
        "";
   case(_,arg::value::_)
      equation
        0 = stringCompare(flag,arg);
      then
        value;
   case(_,_::args)
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

public function isEqual "this function does equal(e1,e2) and returns true if it succedes."
  input Type_a input1;
  input Type_a input2;
  output Boolean isequal;
  replaceable type Type_a subtypeof Any;
algorithm isequal := matchcontinue(input1,input2)
  case(_,_)
    equation
      equality(input1 = input2);
      then true;
  case(_,_) then false;
  end matchcontinue;
end isEqual;

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
protected
  Type_b result;
algorithm
  result := f(element);
  outLst := listAppend(accLst, {result});
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
protected
  Type_b e;
algorithm
  e := f(element);
  outLst := e :: accLst;
end applyAndCons;

public function arrayMapNoCopy "Takes an array and a function over the elements of the array, which is applied for each element.
Since it will update the array values the returned array must have the same type, and thus the applied function must also return
the same type.

See also listMap, arrayMap
  "
  input array<Type_a> array;
  input FuncType func;
  output array<Type_a> outArray;
  replaceable type Type_a subtypeof Any;
  partial function FuncType
    input Type_a x;
    output Type_a y;
  end FuncType;
algorithm
  outArray := arrayMapNoCopyHelp1(array,func,1,arrayLength(array));
end arrayMapNoCopy;

protected function arrayMapNoCopyHelp1 "help function to arrayMap"
  input array<Type_a> array;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  output array<Type_a> outArray;
  replaceable type Type_a subtypeof Any;
  partial function FuncType
    input Type_a x;
    output Type_a y;
  end FuncType;
algorithm
  outArray := matchcontinue(array,func,pos,len)
    local
      Type_a newElt;

    case (_,_,_,_)
      equation
        true = pos > len;
      then array;

    case (_,_,_,_)
      equation
        newElt = func(array[pos]);
        _ = arrayUpdate(array,pos,newElt);
        _ = arrayMapNoCopyHelp1(array,func,pos+1,len);
      then array;
  end matchcontinue;
end arrayMapNoCopyHelp1;

public function arrayMapNoCopy_1 "
same as arrayMapcopy but with additional argument

See also listMap, arrayMap
  "
  input array<Type_a> array;
  input FuncType func;
  input Type_b inArg;
  output array<Type_a> outArray;
  output Type_b outArg;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input tuple<Type_a,Type_b> inTpl;
    output tuple<Type_a,Type_b> outTpl;
  end FuncType;
algorithm
  (outArray,outArg) := arrayMapNoCopyHelp1_1(array,func,1,arrayLength(array),inArg);
end arrayMapNoCopy_1;

protected function arrayMapNoCopyHelp1_1 "help function to arrayMap"
  input array<Type_a> inArray;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  input Type_b inArg;
  output array<Type_a> outArray;
  output Type_b outArg;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input tuple<Type_a,Type_b> inTpl;
    output tuple<Type_a,Type_b> outTpl;
  end FuncType;
algorithm
  (outArray,outArg) := matchcontinue(inArray,func,pos,len,inArg)
    local
      array<Type_a> a,a1;
      Type_a newElt;
      Type_b extarg,extarg1;

    case(_,_,_,_,_)
      equation
        true = pos > len;
      then (inArray,inArg);

    else
      equation
        ((newElt,extarg)) = func((inArray[pos],inArg));
        a = arrayUpdate(inArray,pos,newElt);
        (a1,extarg1) = arrayMapNoCopyHelp1_1(a,func,pos+1,len,extarg);
      then (a1,extarg1);
  end matchcontinue;
end arrayMapNoCopyHelp1_1;

public function arrayFindFirstOnTrue "finds the first element in the array that the predicate function returns true on"
  replaceable type Type_a subtypeof Any;
  input array<Type_a> array;
  input ArrayPredFunc func;
  partial function ArrayPredFunc
    input Type_a elt;
    output Boolean res;
  end ArrayPredFunc;

  output Option<Type_a> elt;
algorithm
  elt :=arrayFindFirstOnTrue2(array,func,1);
end arrayFindFirstOnTrue;

protected function arrayFindFirstOnTrue2 "help function"
  input array<Type_a> array;
  input ArrayPredFunc func;
  input Integer pos;
  replaceable type Type_a subtypeof Any;
  partial function ArrayPredFunc
    input Type_a elt;
    output Boolean res;
  end ArrayPredFunc;

  output Option<Type_a> elt;
algorithm
  elt := matchcontinue(array,func,pos)
  local
    Type_a e;

    case(_,_,_) equation
      true = pos > arrayLength(array);
    then NONE();
    case(_,_,_) equation
      e = array[pos];
      true = func(e);
    then SOME(e);
    case (_,_,_) then  arrayFindFirstOnTrue2(array,func,pos+1);
  end matchcontinue;
end arrayFindFirstOnTrue2;

public function arraySelect
"Takes an array and a list with index and output a new array with the indexed elements.
 Since it will update the array values the returned array must not have the same type,
 the array will first be initialized with the result of the first call.
 assume the Indecies are in range 1,arrayLength(array)."
  input array<Type_a> array;
  input list<Integer> lst;
  output array<Type_a> outArray;
  replaceable type Type_a subtypeof Any;
algorithm
  outArray := arrayCreate(listLength(lst),array[1]);
  outArray := arraySelectHelp(array,lst,outArray,1);
end arraySelect;

protected function arraySelectHelp "help function to arrayMap"
  input array<Type_a> array;
  input list<Integer> posistions;
  input array<Type_a> inArray;
  input Integer lstpos;
  output array<Type_a> outArray;
  replaceable type Type_a subtypeof Any;
algorithm
  outArray := matchcontinue(array,posistions,inArray,lstpos)
    local
    Integer pos,i;
    list<Integer> rest;
    Type_a elmt;
    case(_,{},_,_) then inArray;
    case(_,pos::rest,_,i) equation
      elmt = array[pos];
      outArray = arrayUpdate(inArray,i,elmt);
      outArray = arraySelectHelp(array,rest,inArray,i+1);
    then outArray;
    case(_,_,_,i) equation
      print("arraySelectHelp failed\n for i : " +& intString(i));
    then fail();
  end matchcontinue;
end arraySelectHelp;

public function arrayMap
"@author: unkwnown, adrpo
  Takes an array and a function over the elements of the array, which is applied for each element.
  Since it will update the array values the returned array must not have the same type, the array
  will first be initialized with the result of the first call if it exists.
  If the input array is empty use listArray->listMap->arrayList way.
  See also listMap, arrayMapNoCopy"
  input array<Type_a> array;
  input FuncType func;
  output array<Type_b> outArray;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Type_a x;
    output Type_b y;
  end FuncType;
protected
  Type_b initElt;
algorithm
  outArray := matchcontinue(array, func)
    // if the array is empty, use list transformations to fix the types!
    case (_, _)
      equation
        true = intEq(0, arrayLength(array));
        outArray = listArray({});
      then
        outArray;
    // otherwise, use the first element to create the new array
    case (_, _)
      equation
        false = intEq(0, arrayLength(array));
        initElt = func(array[1]);
        outArray = arrayMapHelp(array,arrayCreate(arrayLength(array),initElt),func,1,arrayLength(array));
      then
        outArray;

  end matchcontinue;
end arrayMap;

protected function arrayMapHelp "help function to arrayMap"
  input array<Type_a> array;
  input array<Type_b> inNewArray;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  output array<Type_b> outArray;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Type_a x;
    output Type_b y;
  end FuncType;
algorithm
  outArray := matchcontinue(array,inNewArray,func,pos,len)
    local
      Type_b newElt;
      array<Type_b> newArray;

    case(_,newArray,_,_,_) equation
      true = pos > len;
    then newArray;

    case(_,newArray,_,_,_) equation
      newElt = func(array[pos]);
      newArray = arrayUpdate(newArray,pos,newElt);
      newArray = arrayMapHelp(array,newArray,func,pos+1,len);
    then newArray;
    case(_,_,_,_,_) equation
      print("arrayMapHelp failed\n");
    then fail();
  end matchcontinue;
end arrayMapHelp;

public function arrayMap1
"@author: Frenkel TUD
  Takes an array and a function and an extra argument over the elements of the array, which is applied for each element.
  Since it will update the array values the returned array must not have the same type, the array
  will first be initialized with the result of the first call if it exists.
  If the input array is empty use listArray->listMap->arrayList way.
  See also listMap, arrayMapNoCopy"
  input array<Type_a> array;
  input FuncType func;
  input Type_arg1 arg1;
  output array<Type_b> outArray;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_arg1 subtypeof Any;
  partial function FuncType
    input Type_a x;
    input Type_arg1 arg1;
    output Type_b y;
  end FuncType;
algorithm
  outArray := matchcontinue(array, func, arg1)
    local
      Type_b initElt;
    // if the array is empty, use list transformations to fix the types!
    case (_, _, _)
      equation
        true = intEq(0, arrayLength(array));
        outArray = listArray({});
      then
        outArray;
    // otherwise, use the first element to create the new array
    case (_, _, _)
      equation
        false = intEq(0, arrayLength(array));
        initElt = func(array[1], arg1);
        outArray = arrayMapHelp1(array,arrayCreate(arrayLength(array),initElt),func,1,arrayLength(array),arg1);
      then
        outArray;
  end matchcontinue;
end arrayMap1;

protected function arrayMapHelp1 "help function to arrayMap"
  input array<Type_a> array;
  input array<Type_b> inNewArray;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  input Type_arg1 arg1;
  output array<Type_b> outArray;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_arg1 subtypeof Any;
  partial function FuncType
    input Type_a x;
    input Type_arg1 arg1;
    output Type_b y;
  end FuncType;
algorithm
  outArray := matchcontinue(array,inNewArray,func,pos,len,arg1)
    local
      Type_b newElt;
      array<Type_b> newArray;

    case(_,newArray,_,_,_,_) equation
      true = pos > len;
    then newArray;

    case(_,newArray,_,_,_,_) equation
      newElt = func(array[pos],arg1);
      newArray = arrayUpdate(newArray,pos,newElt);
      newArray = arrayMapHelp1(array,newArray,func,pos+1,len,arg1);
    then newArray;
    case(_,_,_,_,_,_) equation
      print("arrayMapHelp1 failed\n");
    then fail();
  end matchcontinue;
end arrayMapHelp1;

public function arrayMap0
  input array<Type_a> array;
  input FuncType func;
  replaceable type Type_a subtypeof Any;
  partial function FuncType
    input Type_a x;
  end FuncType;
algorithm
  arrayMap0work(arrayLength(array),array,func);
end arrayMap0;

public function arrayMap0work
  ""
  input Integer ix;
  input array<Type_a> array;
  input FuncType func;
  replaceable type Type_a subtypeof Any;
  partial function FuncType
    input Type_a x;
  end FuncType;
algorithm
  _ := match (ix,array,func)
    local
      Integer i;
    case (0,_,_) then ();
    case (_,_,_)
      equation
        i = arrayLength(array)-ix+1;
        func(array[i]);
        arrayMap0work(ix-1,array,func);
      then ();
  end match;
end arrayMap0work;

public function arrayFold
  "Takes an array, a function, and a start value. The function is applied to
   each array element, and the start value is passed to the function and
   updated."
  input array<ElementType> inArray;
  input FoldFunc inFoldFunc;
  input FoldType inStartValue;
  output FoldType outResult;

  replaceable type ElementType subtypeof Any;
  replaceable type FoldType subtypeof Any;

  partial function FoldFunc
    input ElementType inElement;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outResult := arrayFold_impl(1 > arrayLength(inArray), inArray, inFoldFunc, inStartValue, 1, arrayLength(inArray));
end arrayFold;

public function arrayFold_impl
  "Implementation of arrayFold."
  input Boolean stopCond;
  input array<ElementType> inArray;
  input FoldFunc inFoldFunc;
  input FoldType inFoldValue;
  input Integer inIndex;
  input Integer inArraySize;
  output FoldType outResult;

  replaceable type ElementType subtypeof Any;
  replaceable type FoldType subtypeof Any;

  partial function FoldFunc
    input ElementType inElement;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outResult := match (stopCond, inArray, inFoldFunc, inFoldValue, inIndex, inArraySize)
    local
      ElementType e;
      FoldType res;

    case (true, _, _, _, _, _)
      then
        inFoldValue;

    else
      equation
        e = arrayGet(inArray, inIndex);
        res = inFoldFunc(e, inFoldValue);
      then
        arrayFold_impl(inIndex + 1 > inArraySize, inArray, inFoldFunc, res, inIndex + 1, inArraySize);

  end match;
end arrayFold_impl;

public function arrayFold1
  "Takes an array, a function, one constant parameters and a start value. The function is applied to
   each array element, and the start value is passed to the function and
   updated."
  input array<ElementType> inArray;
  input FoldFunc1 inFoldFunc;
  input ArgType1 inExtraArg1;
  input FoldType inStartValue;
  output FoldType outResult;

  replaceable type ElementType subtypeof Any;
  replaceable type FoldType subtypeof Any;
  replaceable type ArgType1 subtypeof Any;
  replaceable type ArgType2 subtypeof Any;

  partial function FoldFunc1
    input ElementType inElement;
    input ArgType1 _inExtraArg1;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc1;
algorithm
  outResult := arrayFold1_impl(1 > arrayLength(inArray), inArray, inFoldFunc, inExtraArg1, inStartValue, 1, arrayLength(inArray));
end arrayFold1;

public function arrayFold1_impl
  "Implementation of arrayFold1."
  input Boolean stopCond;
  input array<ElementType> inArray;
  input FoldFunc1 inFoldFunc;
  input ArgType1 inExtraArg1;
  input FoldType inFoldValue;
  input Integer inIndex;
  input Integer inArraySize;
  output FoldType outResult;

  replaceable type ElementType subtypeof Any;
  replaceable type FoldType subtypeof Any;
  replaceable type ArgType1 subtypeof Any;
  replaceable type ArgType2 subtypeof Any;

  partial function FoldFunc1
    input ElementType inElement;
    input ArgType1 _inExtraArg1;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc1;
algorithm
  outResult :=
  match(stopCond, inArray, inFoldFunc, inExtraArg1, inFoldValue, inIndex, inArraySize)
    local
      ElementType e;
      FoldType res;

    case (true, _, _, _, _, _, _)
      then
        inFoldValue;

    else
      equation
        e = arrayGet(inArray, inIndex);
        res = inFoldFunc(e, inExtraArg1, inFoldValue);
      then
        arrayFold1_impl(inIndex + 1 > inArraySize, inArray, inFoldFunc, inExtraArg1, res, inIndex + 1, inArraySize);

  end match;
end arrayFold1_impl;

public function arrayFold2
  "Takes an array, a function, two constant parameters and a start value. The function is applied to
   each array element, and the start value is passed to the function and
   updated."
  input array<ElementType> inArray;
  input FoldFunc2 inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input FoldType inStartValue;
  output FoldType outResult;

  replaceable type ElementType subtypeof Any;
  replaceable type FoldType subtypeof Any;
  replaceable type ArgType1 subtypeof Any;
  replaceable type ArgType2 subtypeof Any;

  partial function FoldFunc2
    input ElementType inElement;
    input ArgType1 _inExtraArg1;
    input ArgType2 _inExtraArg2;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc2;
algorithm
  outResult := arrayFold2_impl(1 > arrayLength(inArray), inArray, inFoldFunc, inExtraArg1, inExtraArg2, inStartValue, 1, arrayLength(inArray));
end arrayFold2;

public function arrayFold2_impl
  "Implementation of arrayFold2."
  input Boolean stopCond;
  input array<ElementType> inArray;
  input FoldFunc2 inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input FoldType inFoldValue;
  input Integer inIndex;
  input Integer inArraySize;
  output FoldType outResult;

  replaceable type ElementType subtypeof Any;
  replaceable type FoldType subtypeof Any;
  replaceable type ArgType1 subtypeof Any;
  replaceable type ArgType2 subtypeof Any;

  partial function FoldFunc2
    input ElementType inElement;
    input ArgType1 _inExtraArg1;
    input ArgType2 _inExtraArg2;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc2;
algorithm
  outResult :=
  match (stopCond, inArray, inFoldFunc, inExtraArg1, inExtraArg2, inFoldValue, inIndex, inArraySize)
    local
      ElementType e;
      FoldType res;

    case (true, _, _, _, _, _, _, _)
      then
        inFoldValue;

    else
      equation
        e = arrayGet(inArray, inIndex);
        res = inFoldFunc(e, inExtraArg1, inExtraArg2, inFoldValue);
      then
        arrayFold2_impl(inIndex + 1 > inArraySize, inArray, inFoldFunc, inExtraArg1, inExtraArg2, res, inIndex + 1, inArraySize);

  end match;
end arrayFold2_impl;

public function arrayFold3
  "Takes an array, a function, three constant parameters and a start value. The function is applied to
   each array element, and the start value is passed to the function and
   updated."
  input array<ElementType> inArray;
  input FoldFunc3 inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input ArgType3 inExtraArg3;
  input FoldType inStartValue;
  output FoldType outResult;

  replaceable type ElementType subtypeof Any;
  replaceable type FoldType subtypeof Any;
  replaceable type ArgType1 subtypeof Any;
  replaceable type ArgType2 subtypeof Any;
  replaceable type ArgType3 subtypeof Any;

  partial function FoldFunc3
    input ElementType inElement;
    input ArgType1 _inExtraArg1;
    input ArgType2 _inExtraArg2;
    input ArgType3 _inExtraArg3;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc3;
algorithm
  outResult := arrayFold3_impl(1 > arrayLength(inArray), inArray, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inStartValue, 1, arrayLength(inArray));
end arrayFold3;

public function arrayFold3_impl
  "Implementation of arrayFold3."
  input Boolean stopCond;
  input array<ElementType> inArray;
  input FoldFunc3 inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input ArgType3 inExtraArg3;
  input FoldType inFoldValue;
  input Integer inIndex;
  input Integer inArraySize;
  output FoldType outResult;

  replaceable type ElementType subtypeof Any;
  replaceable type FoldType subtypeof Any;
  replaceable type ArgType1 subtypeof Any;
  replaceable type ArgType2 subtypeof Any;
  replaceable type ArgType3 subtypeof Any;

  partial function FoldFunc3
    input ElementType inElement;
    input ArgType1 _inExtraArg1;
    input ArgType2 _inExtraArg2;
    input ArgType3 _inExtraArg3;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc3;
algorithm
  outResult :=
  match(stopCond, inArray, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inFoldValue, inIndex, inArraySize)
    local
      ElementType e;
      FoldType res;

    case (true, _, _, _, _, _, _, _, _)
      then
        inFoldValue;

    else
      equation
        e = arrayGet(inArray, inIndex);
        res = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, inFoldValue);
      then
        arrayFold3_impl(inIndex + 1 > inArraySize, inArray, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, res, inIndex + 1, inArraySize);

  end match;
end arrayFold3_impl;

public function arrayFold4
  "Takes an array, a function, four constant parameters and a start value. The function is applied to
   each array element, and the start value is passed to the function and
   updated."
  input array<ElementType> inArray;
  input FoldFunc4 inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input ArgType3 inExtraArg3;
  input ArgType4 inExtraArg4;
  input FoldType inStartValue;
  output FoldType outResult;

  replaceable type ElementType subtypeof Any;
  replaceable type FoldType subtypeof Any;
  replaceable type ArgType1 subtypeof Any;
  replaceable type ArgType2 subtypeof Any;
  replaceable type ArgType3 subtypeof Any;
  replaceable type ArgType4 subtypeof Any;

  partial function FoldFunc4
    input ElementType inElement;
    input ArgType1 _inExtraArg1;
    input ArgType2 _inExtraArg2;
    input ArgType3 _inExtraArg3;
    input ArgType4 _inExtraArg4;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc4;
algorithm
  outResult := arrayFold4_impl(1 > arrayLength(inArray), inArray, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inStartValue, 1,
    arrayLength(inArray));
end arrayFold4;

public function arrayFold4_impl
  "Implementation of arrayFold4."
  input Boolean stopCond;
  input array<ElementType> inArray;
  input FoldFunc4 inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input ArgType3 inExtraArg3;
  input ArgType4 inExtraArg4;
  input FoldType inFoldValue;
  input Integer inIndex;
  input Integer inArraySize;
  output FoldType outResult;

  replaceable type ElementType subtypeof Any;
  replaceable type FoldType subtypeof Any;
  replaceable type ArgType1 subtypeof Any;
  replaceable type ArgType2 subtypeof Any;
  replaceable type ArgType3 subtypeof Any;
  replaceable type ArgType4 subtypeof Any;

  partial function FoldFunc4
    input ElementType inElement;
    input ArgType1 _inExtraArg1;
    input ArgType2 _inExtraArg2;
    input ArgType3 _inExtraArg3;
    input ArgType4 _inExtraArg4;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc4;
algorithm
  outResult :=
  match(stopCond, inArray, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inFoldValue, inIndex, inArraySize)
    local
      ElementType e;
      FoldType res;

    case (true, _, _, _, _, _, _, _, _, _)
      then
        inFoldValue;

    else
      equation
        e = arrayGet(inArray, inIndex);
        res = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inFoldValue);
      then
        arrayFold4_impl(inIndex + 1 > inArraySize, inArray, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, res, inIndex + 1, inArraySize);

  end match;
end arrayFold4_impl;

public function arrayFold5
  "Takes an array, a function, five constant parameters and a start value. The function is applied to
   each array element, and the start value is passed to the function and
   updated."
  input array<ElementType> inArray;
  input FoldFunc5 inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input ArgType3 inExtraArg3;
  input ArgType4 inExtraArg4;
  input ArgType5 inExtraArg5;
  input FoldType inStartValue;
  output FoldType outResult;

  replaceable type ElementType subtypeof Any;
  replaceable type FoldType subtypeof Any;
  replaceable type ArgType1 subtypeof Any;
  replaceable type ArgType2 subtypeof Any;
  replaceable type ArgType3 subtypeof Any;
  replaceable type ArgType4 subtypeof Any;
  replaceable type ArgType5 subtypeof Any;
  
  partial function FoldFunc5
    input ElementType inElement;
    input ArgType1 _inExtraArg1;
    input ArgType2 _inExtraArg2;
    input ArgType3 _inExtraArg3;
    input ArgType4 _inExtraArg4;
    input ArgType5 _inExtraArg5;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc5;
algorithm
  outResult := arrayFold5_impl(1 > arrayLength(inArray), inArray, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inExtraArg5, inStartValue, 1,
    arrayLength(inArray));
end arrayFold5;

public function arrayFold5_impl
  "Implementation of arrayFold5."
  input Boolean stopCond;
  input array<ElementType> inArray;
  input FoldFunc5 inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input ArgType3 inExtraArg3;
  input ArgType4 inExtraArg4;
  input ArgType4 inExtraArg5;
  input FoldType inFoldValue;
  input Integer inIndex;
  input Integer inArraySize;
  output FoldType outResult;

  replaceable type ElementType subtypeof Any;
  replaceable type FoldType subtypeof Any;
  replaceable type ArgType1 subtypeof Any;
  replaceable type ArgType2 subtypeof Any;
  replaceable type ArgType3 subtypeof Any;
  replaceable type ArgType4 subtypeof Any;
  replaceable type ArgType5 subtypeof Any;

  partial function FoldFunc5
    input ElementType inElement;
    input ArgType1 _inExtraArg1;
    input ArgType2 _inExtraArg2;
    input ArgType3 _inExtraArg3;
    input ArgType4 _inExtraArg4;
    input ArgType5 _inExtraArg5;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc5;
algorithm
  outResult :=
  match(stopCond, inArray, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inExtraArg5, inFoldValue, inIndex, inArraySize)
    local
      ElementType e;
      FoldType res;

    case (true, _, _, _, _, _, _, _, _, _, _)
      then
        inFoldValue;

    else
      equation
        e = arrayGet(inArray, inIndex);
        res = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inExtraArg5, inFoldValue);
      then
        arrayFold5_impl(inIndex + 1 > inArraySize, inArray, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inExtraArg5, res, inIndex + 1, inArraySize);

  end match;
end arrayFold5_impl;

public function arrayFold6
  "Takes an array, a function, six constant parameters and a start value. The function is applied to
   each array element, and the start value is passed to the function and
   updated."
  input array<ElementType> inArray;
  input FoldFunc6 inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input ArgType3 inExtraArg3;
  input ArgType4 inExtraArg4;
  input ArgType5 inExtraArg5;
  input ArgType6 inExtraArg6;
  input FoldType inStartValue;
  output FoldType outResult;

  replaceable type ElementType subtypeof Any;
  replaceable type FoldType subtypeof Any;
  replaceable type ArgType1 subtypeof Any;
  replaceable type ArgType2 subtypeof Any;
  replaceable type ArgType3 subtypeof Any;
  replaceable type ArgType4 subtypeof Any;
  replaceable type ArgType5 subtypeof Any;
  replaceable type ArgType6 subtypeof Any;
  
  partial function FoldFunc6
    input ElementType inElement;
    input ArgType1 _inExtraArg1;
    input ArgType2 _inExtraArg2;
    input ArgType3 _inExtraArg3;
    input ArgType4 _inExtraArg4;
    input ArgType5 _inExtraArg5;
    input ArgType6 _inExtraArg6;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc6;
algorithm
  outResult := arrayFold6_impl(1 > arrayLength(inArray), inArray, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inExtraArg5, inExtraArg6, inStartValue, 1,
    arrayLength(inArray));
end arrayFold6;

public function arrayFold6_impl
  "Implementation of arrayFold6."
  input Boolean stopCond;
  input array<ElementType> inArray;
  input FoldFunc6 inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input ArgType3 inExtraArg3;
  input ArgType4 inExtraArg4;
  input ArgType5 inExtraArg5;
  input ArgType6 inExtraArg6;
  input FoldType inFoldValue;
  input Integer inIndex;
  input Integer inArraySize;
  output FoldType outResult;

  replaceable type ElementType subtypeof Any;
  replaceable type FoldType subtypeof Any;
  replaceable type ArgType1 subtypeof Any;
  replaceable type ArgType2 subtypeof Any;
  replaceable type ArgType3 subtypeof Any;
  replaceable type ArgType4 subtypeof Any;
  replaceable type ArgType5 subtypeof Any;
  replaceable type ArgType6 subtypeof Any;

  partial function FoldFunc6
    input ElementType inElement;
    input ArgType1 _inExtraArg1;
    input ArgType2 _inExtraArg2;
    input ArgType3 _inExtraArg3;
    input ArgType4 _inExtraArg4;
    input ArgType5 _inExtraArg5;
    input ArgType6 _inExtraArg6;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc6;
algorithm
  outResult :=
  match(stopCond, inArray, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inExtraArg5, inExtraArg6, inFoldValue, inIndex, inArraySize)
    local
      ElementType e;
      FoldType res;

    case (true, _, _, _, _, _, _, _, _, _, _, _)
      then
        inFoldValue;

    else
      equation
        e = arrayGet(inArray, inIndex);
        res = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inExtraArg5, inExtraArg6, inFoldValue);
      then
        arrayFold6_impl(inIndex + 1 > inArraySize, inArray, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inExtraArg5, inExtraArg6, res, inIndex + 1, inArraySize);

  end match;
end arrayFold6_impl;

public function arrayUpdateIndexFirst
" author: wbraun
Perfoms an array update with arrayUpdate,
but index is the first argument so it's
usable with List.map..."
  input Integer inIndex;
  input ElementType value;
  input array<ElementType> inArrayA;
  //output array<ElementType> outArrayA;
  replaceable type ElementType subtypeof Any;

algorithm
  _ := arrayUpdate(inArrayA, inIndex, value);
end arrayUpdateIndexFirst;

public function arrayUpdatewithArrayIndexFirst
" author: wbraun
Perfoms an array update with arrayUpdate,
but index is the first argument so it's
usable with List.map..."
  input Integer inIndex;
  input array<ElementType> inArrayA;
  input array<ElementType> inArrayB;
  //output array<ElementType> outArrayA;
  replaceable type ElementType subtypeof Any;

protected
  ElementType value;
algorithm
  value := arrayGet(inArrayA, inIndex);
  _ := arrayUpdate(inArrayB, inIndex, value);
end arrayUpdatewithArrayIndexFirst;

public function arrayUpdatewithListIndexFirst
" author: wbraun
Perfoms an array update with arrayUpdate,
but index is the first argument so it's
usable with List.map..."
  input list<Integer> inListA;
  input Integer inStartListLength;
  input array<ElementType> inArrayA;
  input array<ElementType> inArrayB;
  //output array<ElementType> outArrayA;
  replaceable type ElementType subtypeof Any;

algorithm
  _ := match(inListA, inStartListLength, inArrayA, inArrayB)
    local
      list<Integer> rest;
    case ({}, _, _, _) then ();
    case (_::rest, _, _, _)
      equation
        arrayUpdatewithArrayIndexFirst(inStartListLength, inArrayA, inArrayB);
        arrayUpdatewithListIndexFirst(rest, inStartListLength+1, inArrayA, inArrayB);
    then ();
   end match;
end arrayUpdatewithListIndexFirst;

public function arrayUpdateElementListUnion
" author: wbraun
Perfoms an array update with arrayUpdate,
but index is the first argument so it's
usable with List.map..."
  input Integer inIndex;
  input list<ElementType> inValue;
  input array<list<ElementType>> inArrayA;
  //output array<ElementType> outArrayA;
  replaceable type ElementType subtypeof Any;

protected
 list<ElementType> value;
algorithm
  value := arrayGet(inArrayA, inIndex);
  value := List.unionAppendonUnion(value, inValue);
  _ := arrayUpdate(inArrayA, inIndex, value);
end arrayUpdateElementListUnion;

public function arrayUpdateElementListAppend
" author: wbraun
Perfoms an array update with arrayUpdate,
but index is the first argument so it's
usable with List.map..."
  input Integer inIndex;
  input list<ElementType> inValue;
  input array<list<ElementType>> inArrayA;
  //output array<ElementType> outArrayA;
  replaceable type ElementType subtypeof Any;

protected
 list<ElementType> value;
algorithm
  value := arrayGet(inArrayA, inIndex);
  value := listAppend(value, inValue);
  _ := arrayUpdate(inArrayA, inIndex, value);
end arrayUpdateElementListAppend;

public function arrayGetIndexFirst
" author: wbraun
Perfoms an array get with arrayGet,
but index is the first argument so it's
usable with List.map..."
  input Integer inIndex;
  input array<ElementType> inArrayA;
  output ElementType outElement;

  replaceable type ElementType subtypeof Any;
algorithm
  outElement := arrayGet(inArrayA, inIndex);
end arrayGetIndexFirst;

public function selectFirstNonEmptyString "Selects the first non-empty string from a list of strings.
If all strings a empty or empty list return empty string.
"
  input list<String> slst;
  output String res;
algorithm
  res := matchcontinue(slst)
    local
      String s;
      list<String> rest;
    case (s::rest)
      equation
        true = (s ==& "");
        res = selectFirstNonEmptyString(rest);
      then res;
    case (s::_)
      equation
        false = stringEq(s,"");
      then s;
    case {} then "";
  end matchcontinue;
end selectFirstNonEmptyString;

public function equal "
This function is intended to be a replacement for equality,
when sending function as an input argument."
  input Type_a arg1;
  input Type_a arg2;
  output Boolean b;
  replaceable type Type_a subtypeof Any;
algorithm b := matchcontinue(arg1,arg2)
  case(_,_)
    equation
      equality(arg1 = arg2);
    then
      true;
  case(_,_) then false;
end matchcontinue;
end equal;

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
  input Integer inPos;
  input Type_a inTypeReplace;
  input Type_a inTypeFill;
  input array<Type_a> inTypeAArray;
  output array<Type_a> outTypeAArray;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeAArray:=
  matchcontinue (inPos,inTypeReplace,inTypeFill,inTypeAArray)
    local
      Integer alen,pos;
      array<Type_a> res,arr,newarr,res_1;
      Type_a x,fillv;
    case (pos,x,_,arr)
      equation
        alen = arrayLength(arr) "Replacing element with index in range of the array" ;
        (pos <= alen) = true;
        res = arrayUpdate(arr, pos, x);
      then
        res;
    case (pos,x,fillv,arr)
      equation
        //Replacing element out of range of array, create new array, and copy elts.
        newarr = arrayCreate(pos, fillv);
        res = arrayCopy(arr, newarr);
        res_1 = arrayUpdate(res, pos, x);
      then
        res_1;
    case (_,_,_,_)
      equation
        print("- Util.arrayReplaceAtWithFill failed\n");
      then
        fail();
  end matchcontinue;
end arrayReplaceAtWithFill;

public function arrayExpand "Increases the number of elements of a list with n.
  Each of the new elements have the value v."
  input Integer n;
  input array<Type_a> arr;
  input Type_a v;
  output array<Type_a> newarr_1;
  replaceable type Type_a subtypeof Any;
algorithm
  newarr_1 := matchcontinue(n,arr,v)
    local
      Integer len,newlen;
      array<Type_a> newarr;
    case (_,_,_)
      equation
        // do nothing if n is negative or zero
        true = intLt(n,1);
      then
        arr;
    case (_,_,_)
      equation
       len = arrayLength(arr);
       newlen = n + len;
       newarr = arrayCreate(newlen, v);
       newarr_1 = arrayCopy(arr, newarr);
      then
       newarr_1;
    else
      equation
        print("Util.arrayExpand failed!\n");
        print("OldSize: " +& intString(arrayLength(arr)) +& " additional elements: " +& intString(n) +& "\n");
      then
        fail();
  end matchcontinue;
end arrayExpand;

public function arrayExpandOnDemand
  "Resizes an array if needed."
  input Integer inNewSize "The number of elements that should fit in the array.";
  input array<ElementType> inArray "The array to resize.";
  input Real inExpansionFactor "The factor to resize the array with.";
  input ElementType inFillValue "The value to fill the new part of the array.";
  output array<ElementType> outArray "The resulting array.";

  replaceable type ElementType subtypeof Any;
algorithm
  outArray :=
  matchcontinue(inNewSize, inArray, inExpansionFactor, inFillValue)
    local
      Integer new_size;
      array<ElementType> new_arr;

    // Space left in the array, do nothing.
    case (_, _, _, _)
      equation
        true = inNewSize <= arrayLength(inArray);
      then
        inArray;

    // Otherwise, resize the array.
    else
      equation
        new_size = realInt(intReal(arrayLength(inArray)) *. inExpansionFactor);
        new_arr = arrayCreate(new_size, inFillValue);
        new_arr = arrayCopy(inArray, new_arr);
      then
        new_arr;

  end matchcontinue;
end arrayExpandOnDemand;

public function arrayNCopy "The function fails if all elements can not be fit into dest array."
  input array<Type_a> src;
  input array<Type_a> dst;
  input Integer n;
  output array<Type_a> dst_1;
  replaceable type Type_a subtypeof Any;
protected
  Integer n_1;
algorithm
  n_1 := n - 1;
  dst_1 := arrayCopy2(src, dst, n_1);
end arrayNCopy;

public function arrayAppend "Function: arrayAppend
function for appending two arrays"
  input array<Type_a> arr1;
  input array<Type_a> arr2;
  output array<Type_a> out;
  replaceable type Type_a subtypeof Any;
protected
  list<Type_a> l1,l2,l3;
algorithm
  l1 := arrayList(arr1);
  l2 := arrayList(arr2);
  l3 := listAppend(l1,l2);
  out := listArray(l3);
end arrayAppend;

public function arrayCons
"function for concate an element on an array of list"
  input Integer index;
  input Type_a element;
  input array<list<Type_a>> arr;
  output array<list<Type_a>> out;
replaceable type Type_a subtypeof Any;
protected
  list<Type_a> l;
algorithm
  l := arr[index];
  out := arrayUpdate(arr,index,element::l);
end arrayCons;

public function arrayListAppend
"function for listAppend an list on an array of list"
  input Integer index;
  input list<Type_a> elements;
  input array<list<Type_a>> arr;
  output array<list<Type_a>> out;
replaceable type Type_a subtypeof Any;
protected
  list<Type_a> l;
algorithm
  l := arr[index];
  l := listAppend(l,elements);
  out := arrayUpdate(arr,index,l);
end arrayListAppend;

public function arrayCopy "copies all values in src array into dest array.
  The function fails if all elements can not be fit into dest array."
  input array<Type_a> inTypeAArray1;
  input array<Type_a> inTypeAArray2;
  output array<Type_a> outTypeAArray;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeAArray:=
  matchcontinue (inTypeAArray1,inTypeAArray2)
    local
      Integer srclen,dstlen;
      array<Type_a> src,dst,dst_1;
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
  input array<Type_a> inTypeAArray1;
  input array<Type_a> inTypeAArray2;
  input Integer inInteger3;
  output array<Type_a> outTypeAArray;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeAArray:=
  match (inTypeAArray1,inTypeAArray2,inInteger3)
    local
      array<Type_a> src,dst,dst_1,dst_2;
      Type_a elt;
      Integer pos;
    case (_,dst,-1) then dst;  /* src dst current pos */
    case (src,dst,pos)
      equation
        elt = src[pos + 1];
        dst_1 = arrayUpdate(dst, pos + 1, elt);
        pos = pos - 1;
        dst_2 = arrayCopy2(src, dst_1, pos);
      then
        dst_2;
  end match;
end arrayCopy2;

public function arraySet "Sets from position start to position end_ the value v."
  input Integer start;
  input Integer end_;
  input array<Type_a> arr;
  input Type_a v;
  output array<Type_a> oarr;
  replaceable type Type_a subtypeof Any;
algorithm
  oarr := matchcontinue(start,end_,arr,v)
    local
      array<Type_a> newarr;
    case (_,_,_,_)
      equation
        // do nothing if start is grather than end_
        true = intGt(start,end_);
      then
        arr;
    case (_,_,_,_)
      equation
        false = intGt(start,end_);
        newarr = arrayUpdate(arr, start, v);
      then
        arraySet(start+1,end_,newarr,v);
    else
      equation
        print("Util.arraySet failed!\n");
        print("Size: " +& intString(arrayLength(arr)) +& " start: " +& intString(start) +& " end: " +& intString(end_) +& "\n");
      then
        fail();
  end matchcontinue;
end arraySet;

public function compareTuple2IntGt
"  Function could used with List.sort to sort a
  List as list< tuple<Type_a,Integer> > by second argument.
  "
  input tuple<Type_a,Integer> inTplA;
  input tuple<Type_a,Integer> inTplB;
  output Boolean res;
  replaceable type Type_a subtypeof Any;
protected
  Integer a,b;
algorithm
  (_, a) := inTplA;
  (_, b) := inTplB;
  res := intGt(a,b);
end compareTuple2IntGt;

public function compareTuple2IntLt
"  Function could used with List.sort to sort a
  List as list< tuple<Type_a,Integer> > by second argument.
  "
  input tuple<Type_a,Integer> inTplA;
  input tuple<Type_a,Integer> inTplB;
  output Boolean res;
  replaceable type Type_a subtypeof Any;
protected
  Integer a,b;
algorithm
  (_, a) := inTplA;
  (_, b) := inTplB;
  res := intLt(a,b);
end compareTuple2IntLt;

public function tuple21 "Takes a tuple of two values and returns the first value.
  Example: tuple21((\"a\",1)) => \"a\""
  input tuple<Type_a, Type_b> inTplTypeATypeB;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeA:=match (inTplTypeATypeB)
    local Type_a a;
    case ((a,_)) then a;
  end match;
end tuple21;

public function tuple22 "Takes a tuple of two values and returns the second value.
  Example: tuple22((\"a\",1)) => 1"
  input tuple<Type_a, Type_b> inTplTypeATypeB;
  output Type_b outTypeB;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeB:=
  match (inTplTypeATypeB)
    local Type_b b;
    case ((_,b)) then b;
  end match;
end tuple22;

public function optTuple22 "Takes an option tuple of two values and returns the second value.
  Example: optTuple22(SOME(\"a\",1)) => 1"
  input Option<tuple<Type_a, Type_b>> inTplTypeATypeB;
  output Type_b outTypeB;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  SOME((_,outTypeB)) := inTplTypeATypeB;
end optTuple22;

public function tuple312 "
  Takes a tuple of three values and returns the tuple of the two first values.
  Example: tuple312((\"a\",1,2)) => (\"a\",1)"
  input tuple<Type_a, Type_b,Type_c> tpl;
  output tuple<Type_a, Type_b> outTypeA;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outTypeA:=
  match (tpl)
    local
      Type_a a;
      Type_b b;
    case ((a,b,_)) then ((a,b));
  end match;
end tuple312;

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
  match (tpl)
    local Type_a a;
    case ((a,_,_)) then a;
  end match;
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
  match (tpl)
    local Type_b b;
    case ((_,b,_)) then b;
  end match;
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
  match (tpl)
    local Type_c c;
    case ((_,_,c)) then c;
  end match;
end tuple33;

public function tuple41
  input tuple<Type_a,Type_b,Type_c,Type_d> tpl;
  output Type_a out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm
  (out,_,_,_) := tpl;
end tuple41;

public function tuple42
  input tuple<Type_a,Type_b,Type_c,Type_d> tpl;
  output Type_b out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm
  (_,out,_,_) := tpl;
end tuple42;

public function tuple43
  input tuple<Type_a,Type_b,Type_c,Type_d> tpl;
  output Type_c out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm
  (_,_,out,_) := tpl;
end tuple43;

public function tuple44
  input tuple<Type_a,Type_b,Type_c,Type_d> tpl;
  output Type_d out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm
  (_,_,_,out) := tpl;
end tuple44;

public function tuple51
  input tuple<Type_a,Type_b,Type_c,Type_d,Type_e> tpl;
  output Type_a out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  (out,_,_,_,_) := tpl;
end tuple51;

public function tuple52
  input tuple<Type_a,Type_b,Type_c,Type_d,Type_e> tpl;
  output Type_b out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  (_,out,_,_,_) := tpl;
end tuple52;

public function tuple53
  input tuple<Type_a,Type_b,Type_c,Type_d,Type_e> tpl;
  output Type_c out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  (_,_,out,_,_) := tpl;
end tuple53;

public function tuple54
  input tuple<Type_a,Type_b,Type_c,Type_d,Type_e> tpl;
  output Type_d out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  (_,_,_,out,_) := tpl;
end tuple54;

public function tuple55
  input tuple<Type_a,Type_b,Type_c,Type_d,Type_e> tpl;
  output Type_e out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  (_,_,_,_,out) := tpl;
end tuple55;

public function tuple61
  input tuple<Type_a,Type_b,Type_c,Type_d,Type_e,Type_f> tpl;
  output Type_a out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
algorithm
  (out,_,_,_,_,_) := tpl;
end tuple61;

public function tuple62
  input tuple<Type_a,Type_b,Type_c,Type_d,Type_e,Type_f> tpl;
  output Type_b out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
algorithm
  (_,out,_,_,_,_) := tpl;
end tuple62;

public function splitTuple2List "Takes a list of two-tuples and splits it into two lists.
  Example: splitTuple2List({(\"a\",1),(\"b\",2),(\"c\",3)}) => ({\"a\",\"b\",\"c\"}, {1,2,3})"
  input list<tuple<Type_a, Type_b>> inTplTypeATypeBLst;
  output list<Type_a> outTypeALst;
  output list<Type_b> outTypeBLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  (outTypeALst,outTypeBLst):=
  match (inTplTypeATypeBLst)
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
  end match;
end splitTuple2List;

public function splitTuple211List
"Takes a list of two-tuples and outputs the first one."
  input list<tuple<Type_a, Type_b>> inTplTypeATypeBLst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  (outTypeALst):=
  match (inTplTypeATypeBLst)
    local
      list<Type_a> xs;
      Type_a x;
      list<tuple<Type_a, Type_b>> rest;
    case ({}) then ({});
    case (((x,_) :: rest))
      equation
        (xs) = splitTuple211List(rest);
      then
        ((x :: xs));
  end match;
end splitTuple211List;

public function splitTuple212List
 "Takes a list of two-tuples and outputs the second one."
  input list<tuple<Type_a, Type_b>> inTplTypeATypeBLst;
  output list<Type_b> outTypeBLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  (outTypeBLst):=
  match (inTplTypeATypeBLst)
    local
      list<Type_b> xs;
      Type_b x;
      list<tuple<Type_a, Type_b>> rest;
    case ({}) then ({});
    case (((_,x) :: rest))
      equation
        (xs) = splitTuple212List(rest);
      then
        ((x :: xs));
  end match;
end splitTuple212List;


public function filterList "
Author BZ
Taking a list of a generic type and a integer list which are the positions
we are supposed to remove. The final position is the offset, where to start from(normal = 0 )."
  input list<Type_a> lst;
  input list<Integer> positions;
  input Integer pos;
  output list<Type_a> outList;
  replaceable type Type_a subtypeof Any;
algorithm
  outList := matchcontinue(lst,positions,pos)
    local
      list<Type_a> tail,res;
      Type_a head;
      Integer x;
      list<Integer> xs;
    case ({},_,_) then {};
    case (_,{},_) then lst;
    case (_::tail,x::xs,_)
      equation
        true = intEq(x, pos); // equality(x=pos);
        res = filterList(tail,xs,pos+1);
      then
        res;
    case (head::tail,x::xs,_)
      equation
        res = filterList(tail,x::xs,pos+1);
      then
        head::res;
  end matchcontinue;
end filterList;

public function if_ "Takes a boolean and two values.
  Returns the first value (second argument) if the boolean value is
  true, otherwise the second value (third argument) is returned.
  Example: if_(true,\"a\",\"b\") => \"a\""
  input Boolean cond;
  input Type_a valTrue;
  input Type_a valFalse;
  output Type_a outVal;
  replaceable type Type_a subtypeof Any;
  // annotation(__OpenModelica_EarlyInline = true);
algorithm
  outVal := match (cond,valTrue,valFalse)
    case (true,_,_) then valTrue;
    else valFalse;
  end match;
end if_;

public function stringContainsChar "Returns true if a string contains a specified character"
  input String str;
  input String char;
  output Boolean res;
algorithm
  res := matchcontinue(str,char)
    case (_,_)
      equation
        _::_::_ = stringSplitAtChar(str,char);
      then true;
    else false;
  end matchcontinue;
end stringContainsChar;

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
    case ({f},_) equation Print.printBuf(f); then ();
    case ((f :: r),delim)
      equation
        stringDelimitListPrintBuf(r, delim);
        Print.printBuf(f);
        Print.printBuf(delim);

      then
        ();
  end matchcontinue;
end stringDelimitListPrintBuf;

public function stringDelimitListAndSeparate "author: PA
  This function is similar to stringDelimitList, i.e it inserts string delimiters between
  consecutive strings in a list. But it also count the lists and inserts a second string delimiter
  when the counter is reached. This can be used when for instance outputting large lists of values
  and a newline is needed after ten or so items."
  input list<String> str;
  input String sep1;
  input String sep2;
  input Integer n;
  output String res;
protected
  Integer handle;
algorithm
  handle := Print.saveAndClearBuf();
  stringDelimitListAndSeparate2(str, sep1, sep2, n, 0);
  res := Print.getString();
  Print.restoreBuf(handle);
end stringDelimitListAndSeparate;

protected function stringDelimitListAndSeparate2 "author: PA
  Helper function to stringDelimitListAndSeparate"
  input list<String> inStringLst1;
  input String inString2;
  input String inString3;
  input Integer inInteger4;
  input Integer inInteger5;
algorithm
  _ := matchcontinue (inStringLst1,inString2,inString3,inInteger4,inInteger5)
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
        print("- stringDelimitListAndSeparate2 failed\n");
      then
        fail();
  end matchcontinue;
end stringDelimitListAndSeparate2;

public function stringDelimitListNonEmptyElts "the string delimiter inserted between those elements that are not empty.
  Example: stringDelimitListNonEmptyElts({\"x\",\"\",\"z\"}, \", \") => \"x, z\""
  input list<String> lst;
  input String delim;
  output String str;
protected
  list<String> lst1;
algorithm
  lst1 := List.select(lst, isNotEmptyString);
  str := stringDelimitList(lst1, delim);
end stringDelimitListNonEmptyElts;

public function stringReplaceChar "Takes a string and two chars and replaces the first char with the second char:
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
  outString := System.stringReplace(inString1, inString2, inString3);
  /*
  matchcontinue (inString1,inString2,inString3)
    local
      list<String> strList,resList;
      String res,str;
      String fromChar,toChar;
    case (str,fromChar,toChar)
      equation
        strList = stringListStringChar(str);
        resList = stringReplaceChar2(strList, fromChar, toChar);
        res = stringCharListString(resList);
      then
        res;
    case (_,_,_)
      equation
        print("- Util.stringReplaceChar failed\n");
      then
        fail();
  end matchcontinue;
  */
end stringReplaceChar;

protected function stringReplaceChar2
  input list<String> inStringLst1;
  input String inString2;
  input String inString3;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inStringLst1,inString2,inString3)
    local
      list<String> res,rest,strList, charList2;
      String firstChar,fromChar,toChar;

    case ({},_,_) then {};
    case ((firstChar :: rest),fromChar,"") // added special case for removal of char.
      equation
        true = stringEq(firstChar, fromChar);
        res = stringReplaceChar2(rest, fromChar, "");
      then
        (res);

    case ((firstChar :: rest),fromChar,toChar)
      equation
        true = stringEq(firstChar, fromChar);
        res = stringReplaceChar2(rest, fromChar, toChar);
        charList2 = stringListStringChar(toChar);
        res = listAppend(charList2,res);
      then
        res;

    case ((firstChar :: rest),fromChar,toChar)
      equation
        false = stringEq(firstChar, fromChar);
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

public function stringSplitAtChar "Takes a string and a char and split the string at the char returning the list of components.
  Example: stringSplitAtChar(\"hej.b.c\",\".\") => {\"hej,\"b\",\"c\"}"
  input String inString1;
  input String inString2;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inString1,inString2)
    local
      list<String> chrList;
      list<String> stringList;
      String str,strList;
      String chr;
    case (str,chr)
      equation
        chrList = stringListStringChar(str);
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
  outStringLst := matchcontinue (inStringLst1,inString2,inStringLst3)
    local
      list<String> chr_rest_1,chr_rest,chrList,rest,res;
      String firstChar,chr,str;

    case ({},_,chr_rest)
      equation
        chr_rest_1 = listReverse(chr_rest);
        str = stringCharListString(chr_rest_1);
      then
        {str};

    case ((firstChar :: rest),chr,chr_rest)
      equation
        true = stringEq(firstChar, chr);
        chrList = listReverse(chr_rest) "this is needed because it returns the reversed list" ;
        str = stringCharListString(chrList);
        res = stringSplitAtChar2(rest, chr, {});
      then
        (str :: res);
    case ((firstChar :: rest),chr,chr_rest)
      equation
        false = stringEq(firstChar, chr);
        res = stringSplitAtChar2(rest, chr, (firstChar :: chr_rest));
      then
        res;
    case (_,_,_)
      equation
        print("- Util.stringSplitAtChar2 failed\n");
      then
        fail();
  end matchcontinue;
end stringSplitAtChar2;

public function modelicaStringToCStr " this replaces symbols that are illegal in C to legal symbols
 see replaceStringPatterns to see the format. (example: \".\" becomes \"$P\")
  author: x02lucpo

  NOTE: This function should not be used in OMC, since the OMC backend no longer
    uses stringified components. It is still used by MathCore though."
  input String str;
  input Boolean changeDerCall "if true, first change 'DER(v)' to $derivativev";
  output String res_str;
algorithm
  res_str := matchcontinue(str,changeDerCall)
    local String s;
    case(s,false) // BoschRexroth specifics
      equation
        false = Flags.getConfigBool(Flags.TRANSLATE_DAE_STRING);
        then
          s;
    case(_,false)
      equation
        res_str = "$"+& modelicaStringToCStr1(str, replaceStringPatterns);
        // debug_print("prefix$", res_str);
      then res_str;
    case(s,true) equation
      s = modelicaStringToCStr2(s);
    then s;
  end matchcontinue;
end modelicaStringToCStr;

protected function modelicaStringToCStr2 "help function to modelicaStringToCStr,
first  changes name 'der(v)' to $derivativev and 'pre(v)' to 'pre(v)' with applied rules for v"
  input String inDerName;
  output String outDerName;
algorithm
  outDerName := matchcontinue(inDerName)
    local
      String name, derName;
      list<String> names;

    case(derName) equation
      0 = System.strncmp(derName,"der(",4);
      // adrpo: 2009-09-08
      // the commented text: _::name::_ = listLast(System.strtok(derName,"()"));
      // is wrong as der(der(x)) ends up beeing translated to $der$der instead
      // of $der$der$x. Changed to the following 2 lines below!
      _::names = (System.strtok(derName,"()"));
      names = List.map1(names, modelicaStringToCStr, false);
      name = derivativeNamePrefix +& stringAppendList(names);
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

public function cStrToModelicaString " this replaces symbols that have been replace to correct value for modelica string
 see replaceStringPatterns to see the format. (example: \"$p\" becomes \".\")
  author: x02lucpo

  NOTE: This function should not be used in OMC, since the OMC backend no longer
    uses stringified components. It is still used by MathCore though."
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
  outString := match (inString,inReplacePatternLst)
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
  end match;
end cStrToModelicaString1;

public function boolOrList "Example:
    boolOrList({true,false,false})  => true
    boolOrList({false,false,false}) => false"
  input list<Boolean> inBooleanLst;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inBooleanLst)
    local
      Boolean b;
      list<Boolean> rest;
    case({}) then false;
    case ({b}) then b;
    case ((true :: _))  then true;
    case ((false :: rest)) then boolOrList(rest);
  end match;
end boolOrList;

public function boolAndList "Takes a list of boolean values and applies the boolean AND operator on the elements
  Example:
  boolAndList({}) => true
  boolAndList({true, true}) => true
  boolAndList({false,false,true}) => false"
  input list<Boolean> inBooleanLst;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inBooleanLst)
    local
      Boolean b;
      list<Boolean> rest;
    case({}) then true;
    case ({b}) then b;
    case ((false :: _)) then false;
    case ((true :: rest))  then boolAndList(rest);
  end match;
end boolAndList;

public function applyOption
  "Takes an option value and a function over the value. It returns in another
   option value, resulting from the application of the function on the value.

   Example:
     applyOption(SOME(1), intString) => SOME(\"1\")
     applyOption(NONE(),  intString) => NONE()
  "
  input Option<InType> inOption;
  input FuncType inFunc;
  output Option<OutType> outOption;

  partial function FuncType
    input InType inArg;
    output OutType outArg;
  end FuncType;

  replaceable type InType subtypeof Any;
  replaceable type OutType subtypeof Any;
algorithm
  outOption := match(inOption, inFunc)
    local
      InType ival;
      OutType oval;

    case (SOME(ival), _)
      equation
        oval = inFunc(ival);
      then
        SOME(oval);

    else NONE();
  end match;
end applyOption;

public function applyOption1 "Like applyOption but takes an additional argument"
  input Option<Type_a> ao;
  input Func func;
  input Type_b b;
  output Option<Type_c> co;
  partial function Func
    input Type_a a;
    input Type_b b;
    output Type_c c;
  end Func;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  co := match (ao,func,b)
    local
      Type_a a;
      Type_c c;
    case (NONE(),_,_) then NONE();
    case (SOME(a),_,_)
      equation
        c = func(a,b);
      then SOME(c);
  end match;
end applyOption1;

public function applyOptionOrDefault
  "Takes an optional value, a function and an extra value. If the optional value
   is SOME, applies the function on that value and returns the result.
   Otherwise returns the extra value."
  input Option<Type_a> inValue;
  input FuncType inFunc;
  input Type_b inDefaultValue;
  output Type_b outValue;

  partial function FuncType
    input Type_a inValue;
    output Type_b outValue;
  end FuncType;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  outValue := match(inValue, inFunc, inDefaultValue)
    local
      Type_a value;
      Type_b res;

    case (SOME(value), _, _)
      equation
        res = inFunc(value);
      then
        res;

    else inDefaultValue;

  end match;
end applyOptionOrDefault;

public function applyOptionOrDefault1
  "Takes an optional value, a function, an extra argument and an extra value.
   If the optional value is SOME, applies the function on that value and the
   extra argument and returns the result. Otherwise returns the extra value."
  input Option<Type_a> inValue;
  input FuncType inFunc;
  input Type_c inArg;
  input Type_b inDefaultValue;
  output Type_b outValue;

  partial function FuncType
    input Type_a inValue;
    input Type_c inArg;
    output Type_b outValue;
  end FuncType;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outValue := match(inValue, inFunc, inArg, inDefaultValue)
    local
      Type_a value;
      Type_b res;

    case (SOME(value), _, _, _)
      equation
        res = inFunc(value, inArg);
      then
        res;

    else inDefaultValue;

  end match;
end applyOptionOrDefault1;

public function applyOptionOrDefault2
  input Option<InType> inValue;
  input FuncType inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input OutType inDefault;
  output OutType outValue;

  partial function FuncType
    input InType inValue;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output OutType outValue;
  end FuncType;

  replaceable type InType subtypeof Any;
  replaceable type ArgType1 subtypeof Any;
  replaceable type ArgType2 subtypeof Any;
  replaceable type OutType subtypeof Any;
algorithm
  outValue := match(inValue, inFunc, inArg1, inArg2, inDefault)
    local
      InType value;
      OutType res;

    case (SOME(value), _, _, _, _)
      equation
        res = inFunc(value, inArg1, inArg2);
      then
        res;

    else inDefault;
  end match;
end applyOptionOrDefault2;

public function makeOption "Makes a value into value option, using SOME(value)"
  input Type_a inTypeA;
  output Option<Type_a> outTypeAOption;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeAOption:= SOME(inTypeA);
end makeOption;

public function makeOptionOnTrue
  input Boolean inCondition;
  input ArgType inArg;
  output Option<ArgType> outArg;
  replaceable type ArgType subtypeof Any;
algorithm
  outArg := match(inCondition, inArg)
    case (true, _) then SOME(inArg);
    else NONE();
  end match;
end makeOptionOnTrue;

public function stringOption "author: PA
  Returns string value or empty string from string option."
  input Option<String> inStringOption;
  output String outString;
algorithm
  outString:= match(inStringOption)
    local
      String s;

    case SOME(s) then s;
    else "";
  end match;
end stringOption;

public function getOption "
  author: PA
  Returns an option value if SOME, otherwise fails"
  input Option<Type_a> inOption;
  output Type_a unOption;
  replaceable type Type_a subtypeof Any;
algorithm
  SOME(unOption) := inOption;
end getOption;

public function getOptionOrDefault
"Returns an option value if SOME, otherwise the default"
  input Option<Type_a> inOption;
  input Type_a inDefault;
  output Type_a outOption;
  replaceable type Type_a subtypeof Any;
algorithm
  outOption := match(inOption, inDefault)
    local
      Type_a item;

    case (SOME(item), _) then item;
    else inDefault;
  end match;
end getOptionOrDefault;

public function genericOption "author: BZ
  Returns a list with single value or an empty list if there is no optional value."
  input Option<Type_a> inOption;
  output list<Type_a> outOption;
  replaceable type Type_a subtypeof Any;
algorithm
  outOption := match(inOption)
    local
      Type_a item;

    case SOME(item) then {item};
    else {};
  end match;
end genericOption;

public function isNone
"
  function: isNone
  Author: DH, 2010-03
"
  input Option<Type_a> inOption;
  output Boolean out;
  replaceable type Type_a subtypeof Any;
algorithm
  out := match (inOption)
    case (NONE()) then true;
    else false;
  end match;
end isNone;

public function isSome
"
  function: isSome
  Author: DH, 2010-03
"
  input Option<Type_a> inOption;
  output Boolean out;
  replaceable type Type_a subtypeof Any;
algorithm
  out := match (inOption)
    case NONE() then false;
    else true;
  end match;
end isSome;

public function intPositive "Returns true if integer value is positive (>= 0)"
  input Integer v;
  output Boolean res;
algorithm
  res := (v >= 0);
end intPositive;

public function intNegative "Returns true if integer value is negative (< 0)"
  input Integer v;
  output Boolean res;
algorithm
  res := (v < 0);
end intNegative;

public function intSign
  input Integer i;
  output Integer o;
algorithm
  o := match i local Integer j;
    case 0 then 0;
    case _
      equation
        j = if_(i>0,1,-1);
      then j;
  end match;
end intSign;

public function intCompare
  "Compares two integers and return -1 if the first is smallest, 1 if the second
   is smallest, or 0 if they are equal."
  input Integer inN;
  input Integer inM;
  output Integer outResult;
algorithm
  outResult := matchcontinue(inN, inM)
    case (_, _) equation true = intLt(inN, inM); then -1;
    case (_, _) equation true = intGt(inN, inM); then 1;
    else 0;
  end matchcontinue;
end intCompare;

public function flattenOption "Returns the second argument if NONE() or the element in SOME(element)"
  input Option<Type_a> inTypeAOption;
  input Type_a inTypeA;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeA := match (inTypeAOption,inTypeA)
    local Type_a n,c;
    case (NONE(),n) then n;
    case (SOME(c),_) then c;
  end match;
end flattenOption;

public function isEmptyString "Returns true if string is the empty string."
  input String inString;
  output Boolean outBoolean;
algorithm
  outBoolean := stringEq(inString, "");
end isEmptyString;

public function isNotEmptyString "Returns true if string is not the empty string."
  input String inString;
  output Boolean outBoolean;
algorithm
  outBoolean := boolNot(stringEq(inString, ""));
end isNotEmptyString;

public function writeFileOrErrorMsg "This function tries to write to a file and if it fails then it
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
    case (filename,_)
      equation
        error_str = stringAppendList({"# Cannot write to file: ",filename,"."});
        Print.printErrorBuf(error_str);
      then
        ();
  end matchcontinue;
end writeFileOrErrorMsg;

public function strncmp "Compare two strings up to the nth character
  Returns true if they are equal."
  input String inString1;
  input String inString2;
  input Integer inInteger3;
  output Boolean outBoolean;
algorithm
  outBoolean := (0==System.strncmp(inString1,inString2,inInteger3));
end strncmp;

public function notStrncmp
  input String inString1;
  input String inString2;
  input Integer inInteger3;
  output Boolean outBoolean;
algorithm
  outBoolean := not strncmp(inString1,inString2,inInteger3);
end notStrncmp;

public function tickStr "author: PA
  Returns tick as a string, i.e. an unique number."
  output String s;
algorithm
  s := intString(tick());
end tickStr;

public function replaceWindowsBackSlashWithPathDelimiter
"@author: adrpo
 replace \\ with path delimiter only in Windows!"
  input String inPath;
  output String outPath;
algorithm
  outPath := matchcontinue(inPath)
    local
      String pd;

    case _
      equation
        true = stringEq("Windows_NT", System.os());
        pd = System.pathDelimiter();
        outPath = System.stringReplace(inPath, "\\", pd);
      then
        outPath;

    else inPath;

 end matchcontinue;
end replaceWindowsBackSlashWithPathDelimiter;

public function getAbsoluteDirectoryAndFile "author: x02lucpo
  splits the filepath in directory and filename
  (\"c:\\programs\\file.mo\") => (\"c:\\programs\",\"file.mo\")
  (\"..\\work\\file.mo\") => (\"c:\\openmodelica123\\work\", \"file.mo\")"
  input String filename;
  output String dirname;
  output String basename;
protected
  String realpath;
algorithm
  realpath := System.realpath(filename);
  dirname := System.dirname(realpath);
  basename := System.basename(realpath);
  dirname := replaceWindowsBackSlashWithPathDelimiter(dirname);
end getAbsoluteDirectoryAndFile;

public function rawStringToInputString "author: x02lucpo
  replace the double-backslash with backslash"
  input String inString;
  output String s;
algorithm
  (s) :=
  match (inString)
    local
      String retString,rawString;
    case (rawString)
      equation
         retString = System.stringReplace(rawString, "\\\"", "\"") "change backslash-double-quote to double-quote ";
         retString = System.stringReplace(retString, "\\\\", "\\") "double-backslash with backslash ";
      then
        (retString);
  end match;
end  rawStringToInputString;

public function escapeModelicaStringToCString
  input String modelicaString;
  output String cString;
algorithm
  // C cannot handle newline in string constants
  cString := System.escapedString(modelicaString,true);
end escapeModelicaStringToCString;

public function escapeModelicaStringToXmlString
  input String modelicaString;
  output String xmlString;
algorithm
  // C cannot handle newline in string constants
  xmlString := System.stringReplace(modelicaString, "&", "&amp;");
  xmlString := System.stringReplace(xmlString, "\"", "&quot;");
  xmlString := System.stringReplace(xmlString, "<", "&lt;");
  xmlString := System.stringReplace(xmlString, ">", "&gt;");
  // TODO! FIXME!, we have issues with accented chars in comments
  // that end up in the Model_init.xml file and makes it not well
  // formed but the line below does not work if the xmlString is
  // already UTF-8. We should somehow detect the encoding.
  // xmlString := System.iconv(xmlString, "", "UTF-8");
end escapeModelicaStringToXmlString;

public function makeTuple
  input Type_a a;
  input Type_b b;
  output tuple<Type_a,Type_b> out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  out := (a,b);
end makeTuple;


public function makeTupleR
  input Type_a a;
  input Type_b b;
  output tuple<Type_b,Type_a> out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  out := (b,a);
end makeTupleR;


public function make3Tuple
  input Type_a a;
  input Type_b b;
  input Type_c c;
  output tuple<Type_a,Type_b,Type_c> out;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  out := (a,b,c);
end make3Tuple;

public function mulListIntegerOpt
  input list<Option<Integer>> ad;
  input Integer acc "accumulator, should be given 1";
  output Integer i;
algorithm
  i := match(ad, acc)
    local
      Integer ii, iii;
      list<Option<Integer>> rest;
    case ({}, _) then acc;
    case (SOME(ii)::rest, _)
      equation
        iii = mulListIntegerOpt(rest, ii * acc);
      then iii;
    case (NONE()::rest, _)
      equation
        iii = mulListIntegerOpt(rest, acc);
      then iii;
  end match;
end mulListIntegerOpt;

public type StatefulBoolean = array<Boolean> "A single boolean value that can be updated (a destructive operation)";

public function makeStatefulBoolean
"Create a boolean with state (that is, it is mutable)"
  input Boolean b;
  output StatefulBoolean sb;
algorithm
  sb := arrayCreate(1, b);
end makeStatefulBoolean;

public function getStatefulBoolean
"Create a boolean with state (that is, it is mutable)"
  input StatefulBoolean sb;
  output Boolean b;
algorithm
  b := sb[1];
end getStatefulBoolean;

public function setStatefulBoolean
"Update the state of a mutable boolean"
  input StatefulBoolean sb;
  input Boolean b;
algorithm
  _ := arrayUpdate(sb,1,b);
end setStatefulBoolean;

public function optionEqual "
Takes two options and a function to compare the type."
  input Option<Type_a> inOpt1;
  input Option<Type_a> inOpt2;
  input CompareFunc inFunc;
  output Boolean outBool;

  replaceable type Type_a subtypeof Any;
  partial function CompareFunc
    input Type_a inType_a1;
    input Type_a inType_a2;
    output Boolean outBool;
  end CompareFunc;
algorithm
  outBool := matchcontinue(inOpt1,inOpt2,inFunc)
  local
    Type_a a1,a2;
    Boolean b;
    CompareFunc fn;

    case (NONE(),NONE(),_) then true;
    case (SOME(a1),SOME(a2),fn)
      equation
        b = fn(a1,a2);
      then
        b;
    case (_,_,_) then false;
  end matchcontinue;
end optionEqual;

public function makeValueOrDefault
"Returns the value if the function call succeeds, otherwise the default"
  input FuncAToB inFunc;
  input Type_a inArg;
  input Type_b default;
  output Type_b res;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncAToB
    input Type_a inTypeA;
    output Type_b outTypeB;
  end FuncAToB;
algorithm
  res := matchcontinue (inFunc,inArg,default)
    local
      FuncAToB fn;
    case (fn,_,_)
      equation
        res = fn(inArg);
      then res;
    case (_,_,_) then default;
  end matchcontinue;
end makeValueOrDefault;

public function xmlEscape "Escapes a String so that it can be used in xml"
  input String s1;
  output String s2;
algorithm
  s2 := stringReplaceChar(s1,"&","&amp;");
  s2 := stringReplaceChar(s2,"<","&lt;");
  s2 := stringReplaceChar(s2,">","&gt;");
  s2 := stringReplaceChar(s2,"\"","&quot;");
end xmlEscape;

public function strcmpBool "As strcmp, but has Boolean output as is expected by the sort function"
  input String s1;
  input String s2;
  output Boolean b;
algorithm
  b := if_(stringCompare(s1,s2) > 0, true, false);
end strcmpBool;

public function stringAppendReverse
"@author: adrpo
 This function will append the first string to the second string"
  input String str1;
  input String str2;
  output String str;
algorithm
  str := stringAppend(str2, str1);
end stringAppendReverse;

public function stringAppendNonEmpty
  input String inString1;
  input String inString2;
  output String outString;
algorithm
  outString := match(inString1, inString2)
    case (_, "") then inString2;
    else stringAppend(inString1, inString2);
  end match;
end stringAppendNonEmpty;

// moved from Inst.
public function selectList
"Author BZ, 2008-09
  This utility function selects one of two objects depending on a list of boolean variables.
  Used to constant evaluate if-equations."
  input list<Boolean> inBools;
  input list<Type_a> inList;
  input Type_a inFalse;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeA:=
  match (inBools,inList,inFalse)
    local
      Type_a x,head;
      list<Boolean> bools;
      list<Type_a> lst;

    case({},{},x) then x;
    case (true::_,head::_,_) then head;
    case (false::bools,_::lst,x)
      equation
        head = selectList(bools,lst,x);
      then head;
  end match;
end selectList;

public function getCurrentDateTime
  output DateTime dt;
protected
  Integer sec;
  Integer min;
  Integer hour;
  Integer mday;
  Integer mon;
  Integer year;
algorithm
  (sec,min,hour,mday,mon,year) := System.getCurrentDateTime();
  dt := DATETIME(sec,min,hour,mday,mon,year);
end getCurrentDateTime;

public function isSuccess
  input Status status;
  output Boolean bool;
algorithm
  bool := match status
    case SUCCESS() then true;
    case FAILURE() then false;
  end match;
end isSuccess;

public function id
  input A a;
  output A oa;
  replaceable type A subtypeof Any;
algorithm
  oa := a;
end id;

public function absIntegerList
"@author: adrpo
  Applies absolute value to all entries in the given list."
  input list<Integer> inLst;
  output list<Integer> outLst;
algorithm
  outLst := List.map(inLst, intAbs);
end absIntegerList;

/*
public function arrayMap "Takes a list and a function over the elements of the array, which is applied
  for each element, producing a new array.
  Example: arrayMap({1,2,3}, intString) => { \"1\", \"2\", \"3\"}"
  input array<Type_a> inTypeAArr;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  output array<Type_b> outTypeBArr;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aToType_b;
  replaceable type Type_b subtypeof Any;
protected
  array<Type_b> outTypeBArr;
  Type_b elB;
  Type_a elA;
  Integer sizeOfArr;
algorithm
  // get the size
  sizeOfArr := arrayLength(inTypeAArr);
  // get the first elment of the input array
  elA := arrayGet(inTypeAArr, 1);
  // apply the function and transform it to Type_b
  elB := inFuncTypeTypeAToTypeB(elA);
  // create an array populated with the first element trasformed
  outTypeBArr := arrayCreate(sizeOfArr, elA);
  // set all the other elements on the array!
  outTypeBArr := arrayMapDispatch(inTypeAArr,inFuncTypeTypeAToTypeB,1,sizeOfArr,outTypeBArr);
end arrayMap;

protected function arrayMapDispatch
"@author: adrpo
  Calculates the incidence matrix as an array of list of integers"
  input array<Type_a> inTypeAArr;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  input Integer index;
  input Integer sizeOfArr;
  input array<Type_b> accTypeBArr;
  output array<Type_b> outTypeBArr;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aToType_b;
  replaceable type Type_b subtypeof Any;
algorithm
  outIncidenceArray := matchcontinue (inTypeAArr, inFuncTypeAToTypeB, index, sizeOfArr, accTypeBArr)
    local
      array<Type_a> aArr;
      array<Type_b> bArr;
      Integer i,n;
      Type_a elA;
      Type_b elB;

    // i = n (we reach the end)
    case (aArr, inFuncTypeAToTypeB, i, n, bArr)
      equation
        false = intLt(i, n);
      then
        bArr;

    // i < n
    case (aArr, inFuncTypeAToTypeB, i, n, bArr)
      equation
        true = intLt(i, n);
        // get the element from the input array
        elA = arrayGet(aArr, i + 1);
        // transform the element
        elB = inFuncTypeAToTypeB(elA);
        // put it in the array
        iArr = arrayUpdate(bArr, i+1, elB);
        iArr = arrayMapDispatch(iArr, inFuncTypeAToTypeB, i + 1, n, bArr);
      then
        iArr;

    // failure!
    case (aArr, inFuncTypeAToTypeB, i, n, bArr)
      equation
        print("- Util.arrayMapDispatch failed\n");
      then
        fail();
  end matchcontinue;
end arrayMapDispatch;
*/

public function buildMapStr "Takes two lists of the same type and builds a string like x = val1, y = val2, ....
  Example: listThread({1,2,3},{4,5,6},'=',',') => 1=4, 2=5, 3=6"
  input list<String> inLst1;
  input list<String> inLst2;
  input String inMiddleDelimiter;
  input String inEndDelimiter;
  output String outStr;
algorithm
  outStr := matchcontinue (inLst1,inLst2, inMiddleDelimiter, inEndDelimiter)
    local
      list<String> ra,rb;
      String fa,fb, md, ed, str;

    case ({},{}, _, _) then "";

    case ({fa},{fb}, md, _)
      equation
        str = stringAppendList({fa, md, fb});
      then
        str;

    case (fa :: ra,fb :: rb, md, ed)
      equation
        str = buildMapStr(ra, rb, md, ed);
        str = stringAppendList({fa, md, fb, ed, str});
      then
        str;
  end matchcontinue;
end buildMapStr;

public function splitUniqueOnBool
"Takes a sorted list and returns two sorted lists:
  * The first is the input with all duplicate elements removed
  * The second is the removed elements
"
  input list<TypeA> sorted;
  input Comp comp;
  output list<TypeA> uniqueLst;
  output list<TypeA> duplicateLst;
  replaceable type TypeA subtypeof Any;
  partial function Comp
    input TypeA a1;
    input TypeA a2;
    output Boolean b;
  end Comp;
algorithm
  (uniqueLst,duplicateLst) := splitUniqueOnBoolWork(sorted,comp,{},{});
end splitUniqueOnBool;


protected function splitUniqueOnBoolWork
"Takes a sorted list and returns two sorted lists:
  * The first is the input with all duplicate elements removed
  * The second is the removed elements
"
  input list<TypeA> sorted;
  input Comp comp;
  input list<TypeA> inUniqueAcc;
  input list<TypeA> inDuplicateAcc;
  output list<TypeA> uniqueLst;
  output list<TypeA> duplicateLst;
  replaceable type TypeA subtypeof Any;
  partial function Comp
    input TypeA a1;
    input TypeA a2;
    output Boolean b;
  end Comp;
algorithm
  (uniqueLst,duplicateLst) := match (sorted,comp,inUniqueAcc,inDuplicateAcc)
    local
      TypeA a1,a2;
      list<TypeA> rest, uniqueAcc, duplicateAcc;
      Boolean b;


    case ({},_,uniqueAcc,duplicateAcc)
      equation
        uniqueAcc = listReverse(uniqueAcc);
        duplicateAcc = listReverse(duplicateAcc);
      then (uniqueAcc,duplicateAcc);
    case ({a1},_,uniqueAcc,duplicateAcc)
      equation
        uniqueAcc = listReverse(a1::uniqueAcc);
        duplicateAcc = listReverse(duplicateAcc);
      then (uniqueAcc,duplicateAcc);
    case (a1::a2::rest,_,uniqueAcc,duplicateAcc)
      equation
        b = comp(a1,a2);
        (uniqueAcc,duplicateAcc) = splitUniqueOnBoolWork(a2::rest,comp,if_(b,uniqueAcc,a1::uniqueAcc),if_(b,a1::duplicateAcc,duplicateAcc));
      then (uniqueAcc,duplicateAcc);
  end match;
end splitUniqueOnBoolWork;

public function assoc
"assoc(key,lst) => value, where lst is a tuple of (key,value) pairs.
Does linear search using equality(). This means it is slow for large
inputs (many elements or large elements); if you have large inputs, you
should use a hash-table instead."
  input Key key;
  input list<tuple<Key,Val>> lst;
  output Val val;
  replaceable type Key subtypeof Any;
  replaceable type Val subtypeof Any;
algorithm
  val := match (key,lst)
    local
      Key k1,k2;
      Val v;
      list<tuple<Key,Val>> rest;

    case (k1,(k2,v)::rest) then Debug.bcallret2(not valueEq(k1,k2), assoc, k1, rest, v);
  end match;
end assoc;

//public function transposeList
//  "Transposes a 2-dimensional rectangular list"
//  input list<list<A>> lst;
//  output list<list<A>> olst;
//  replaceable type A subtypeof Any;
//algorithm
//  olst := transposeList2(lst,{});
//end transposeList;
//
//protected function transposeList2
//  "Transposes a 2-dimensional rectangular list"
//  input list<list<A>> lst;
//  input list<list<A>> acc;
//  output list<list<A>> olst;
//  replaceable type A subtypeof Any;
//algorithm
//  olst := match (lst,acc)
//    local
//      list<A> a;
//    case ({},_) then listReverse(acc);
//    case ({}::_,_) then listReverse(acc);
//    case (lst,acc)
//      equation
//        a = List.map(lst,List.first);
//        lst = List.map(lst,List.rest);
//      then transposeList2(lst,a::acc);
//  end match;
//end transposeList2;

public function allCombinations
  "{{1,2,3},{4,5},{6}} => {{1,4,6},{1,5,6},{2,4,6},...}.
  The output is a 2-dim list with lengths (len1*len2*...*lenN)) and N.

  This function screams WARNING I USE COMBINATORIAL EXPLOSION.
  So there are flags that limit the size of the set it works on."
  input list<list<Type_a>> lst;
  input Option<Integer> maxTotalSize;
  input Absyn.Info info;
  output list<list<Type_a>> out;
  replaceable type Type_a subtypeof Any;
algorithm
  out := matchcontinue (lst,maxTotalSize,info)
    local
      Integer sz,maxSz;
    case (_,SOME(maxSz),_)
      equation
        sz = intMul(listLength(lst),List.fold(List.map(lst,listLength),intMul,1));
        true = (sz <= maxSz);
      then allCombinations2(lst);

    case (_,NONE(),_) then allCombinations2(lst);

    case (_,SOME(_),_)
      equation
        Error.addSourceMessage(Error.COMPILER_NOTIFICATION, {"Util.allCombinations failed because the input was too large"}, info);
      then fail();
  end matchcontinue;
end allCombinations;

protected function allCombinations2
  "{{1,2,3},{4,5},{6}} => {{1,4,6},{1,5,6},{2,4,6},...}.
  The output is a 2-dim list with lengths (len1*len2*...*lenN)) and N.

  This function screams WARNING I USE COMBINATORIAL EXPLOSION."
  input list<list<Type_a>> ilst;
  output list<list<Type_a>> out;
  replaceable type Type_a subtypeof Any;
algorithm
  out := match (ilst)
    local
      list<Type_a> x;
      list<list<Type_a>> lst;

    case {} then {};
    case (x::lst)
      equation
        lst = allCombinations2(lst);
        lst = allCombinations3(x, lst, {});
      then lst;
  end match;
end allCombinations2;

protected function allCombinations3
  input list<Type_a> ilst1;
  input list<list<Type_a>> ilst2;
  input list<list<Type_a>> iacc;
  output list<list<Type_a>> out;
  replaceable type Type_a subtypeof Any;
algorithm
  out := match (ilst1,ilst2,iacc)
    local
      Type_a x;
      list<Type_a> lst1;
      list<list<Type_a>> lst2;
      list<list<Type_a>> acc;


    case ({},_,acc) then listReverse(acc);
    case (x::lst1,lst2,acc)
      equation
        acc = allCombinations4(x, lst2, acc);
        acc = allCombinations3(lst1, lst2, acc);
      then acc;
  end match;
end allCombinations3;

protected function allCombinations4
  input Type_a x;
  input list<list<Type_a>> ilst;
  input list<list<Type_a>> iacc;
  output list<list<Type_a>> out;
  replaceable type Type_a subtypeof Any;
algorithm
  out := match (x,ilst,iacc)
    local
      list<Type_a> l;
      list<list<Type_a>> lst;
      list<list<Type_a>> acc;

    case (_,{},acc) then {x}::acc;
    case (_,{l},acc) then (x::l)::acc;
    case (_,l::lst,acc)
      equation
        acc = allCombinations4(x, lst, (x::l)::acc);
      then acc;
  end match;
end allCombinations4;

public function arrayMember
"returns the index if found or 0 if not found.
 considers array indexed from 1"
  input array<Option<Type_a>> inArr;
  input Integer inFilledSize "the filled size of the array, it might be less than arrayLength";
  input Option<Type_a> inElement;
  output Integer index;
protected
  replaceable type Type_a subtypeof Any;
algorithm
  index := matchcontinue(inArr, inFilledSize, inElement)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;

    // array is empty
    case (_, _, _)
      equation
        true = intEq(0, inFilledSize);
      then 0;

    // array is not empty
    case (arr, _, _)
      equation
        i = arrayMemberLoop(arr, inElement, 1, inFilledSize);
      then i;
  end matchcontinue;
end arrayMember;


public function arrayMemberNoOpt
"returns the index if found or 0 if not found.
 considers array indexed from 1"
  input array<Type_a> inArr;
  input Integer inFilledSize "the filled size of the array, it might be less than arrayLength";
  input Type_a inElement;
  output Integer index;
  replaceable type Type_a subtypeof Any;
algorithm
  index := matchcontinue(inArr, inFilledSize, inElement)
    local
      array<Type_a> arr;
      Integer i, len, pos;
    // array is empty
    case (_, _, _)
      equation
        true = intEq(0, inFilledSize);
      then 0;
    // array is not empty
    case (arr, _, _)
      equation
        i = arrayMemberLoopNoOpt(arr, inElement, 1, inFilledSize);
      then i;
  end matchcontinue;
end arrayMemberNoOpt;


protected function arrayMemberLoopNoOpt
"returns the index if found or 0 if not found.The array has no Option like in arrayMember
 considers array indexed from 1"
  input array<Type_a> inArr;
  input Type_a inElement;
  input Integer currentIndex;
  input Integer length;
  output Integer index;
protected
  replaceable type Type_a subtypeof Any;
algorithm
  index := matchcontinue(inArr, inElement, currentIndex, length)
    local
      array<Type_a> arr;
      Integer i, len, pos;
      Type_a e;

    // we're at the end
    case (_, _, i, len)
      equation
        true = intEq(i, len);
      then 0;

    // not at the end, see if we find it
    case (arr, _, i, _)
      equation
        e = arrayGet(arr, i);
        true = valueEq(e, inElement);
      then i;

    // not at the end, see if we find it
    case (arr, _, i, len)
      equation
        e = arrayGet(arr, i);
        false = valueEq(e, inElement);
        i = arrayMemberLoopNoOpt(arr, inElement, i + 1, len);
      then i;
  end matchcontinue;
end arrayMemberLoopNoOpt;


protected function arrayMemberLoop
"returns the index if found or 0 if not found.
 considers array indexed from 1"
  input array<Option<Type_a>> inArr;
  input Option<Type_a> inElement;
  input Integer currentIndex;
  input Integer length;
  output Integer index;
protected
  replaceable type Type_a subtypeof Any;
algorithm
  index := matchcontinue(inArr, inElement, currentIndex, length)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;
      Option<Type_a> e;

    // we're at the end
    case (_, _, i, len)
      equation
        true = intEq(i, len);
      then 0;

    // not at the end, see if we find it
    case (arr, _, i, _)
      equation
        e = arrayGet(arr, i);
        true = valueEq(e, inElement);
      then i;

    // not at the end, see if we find it
    case (arr, _, i, len)
      equation
        e = arrayGet(arr, i);
        false = valueEq(e, inElement);
        i = arrayMemberLoop(arr, inElement, i + 1, len);
      then i;
  end matchcontinue;
end arrayMemberLoop;

public function arrayFind
"returns the index if found or 0 if not found.
 considers array indexed from 1"
  input array<Option<Type_a>> inArr;
  input Integer inFilledSize "the filled size of the array, it might be less than arrayLength";
  input FuncType inFunc;
  input Type_b inExtra;
  output Integer index;
protected
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Type_a inElement;
    input Type_b inExtra;
    output Boolean isMatch;
  end FuncType;
algorithm
  index := matchcontinue(inArr, inFilledSize, inFunc, inExtra)
    local
      Integer i, len, pos;

    // array is empty
    case (_, _, _, _)
      equation
        true = intEq(0, inFilledSize);
      then 0;

    // array is not empty
    case (_, _, _, _)
      equation
        i = arrayFindLoop(inArr, inFunc, inExtra, 1, inFilledSize);
      then i;
  end matchcontinue;
end arrayFind;

protected function arrayFindLoop
"returns the index if found or 0 if not found.
 considers array indexed from 1"
  input array<Option<Type_a>> inArr;
  input FuncType inFunc;
  input Type_b inExtra;
  input Integer currentIndex;
  input Integer length;
  output Integer index;
protected
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Type_a inElement;
    input Type_b inExtra;
    output Boolean isMatch;
  end FuncType;
algorithm
  index := matchcontinue(inArr, inFunc, inExtra, currentIndex, length)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;
      Type_a e;

    // we're at the end
    case (_, _, _, i, len)
      equation
        true = intEq(i, len);
      then
        0;

    // not at the end, see if we find it
    case (arr, _, _, i, _)
      equation
        SOME(e) = arrayGet(arr, i);
        true = inFunc(e, inExtra);
      then
        i;

    // not at the end, see if we find it
    case (arr, _, _, i, len)
      equation
        SOME(e) = arrayGet(arr, i);
        false = inFunc(e, inExtra);
        i = arrayFindLoop(arr, inFunc, inExtra, i + 1, len);
      then
        i;

    // not at the end, see if we find it
    case (arr, _, _, i, len)
      equation
        NONE() = arrayGet(arr, i);
        i = arrayFindLoop(arr, inFunc, inExtra, i + 1, len);
      then
        i;
  end matchcontinue;
end arrayFindLoop;

public function arrayApply
"apply a function to each element of the array"
  input array<Option<Type_a>> inArr;
  input Integer inFilledSize "the filled size of the array, it might be less than arrayLength";
  input FuncType inFunc;
  input Type_b inExtra;
  output array<Option<Type_a>> outArr;
protected
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Option<Type_a> inElement;
    input Type_b inExtra;
  end FuncType;
algorithm
  outArr := matchcontinue(inArr, inFilledSize, inFunc, inExtra)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;

    // array is empty
    case (arr, _, _, _)
      equation
        true = intEq(0, inFilledSize);
      then arr;

    // array is not empty
    case (arr, _, _, _)
      equation
        arr = arrayApplyLoop(arr, inFunc, inExtra, 1, inFilledSize);
      then arr;
  end matchcontinue;
end arrayApply;

protected function arrayApplyLoop
"returns the index if found or 0 if not found.
 considers array indexed from 1"
  input array<Option<Type_a>> inArr;
  input FuncType inFunc;
  input Type_b inExtra;
  input Integer currentIndex;
  input Integer length;
  output array<Option<Type_a>> outArr;
protected
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Option<Type_a> inElement;
    input Type_b inExtra;
  end FuncType;
algorithm
  outArr := matchcontinue(inArr, inFunc, inExtra, currentIndex, length)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;
      Option<Type_a> e;

    // we're at the end
    case (arr, _, _, i, len)
      equation
        true = intEq(i, len);
      then
        arr;

    // not at the end, see if we find it
    case (arr, _, _, i, len)
      equation
        e = arrayGet(arr, i);
        inFunc(e, inExtra);
        arr = arrayApplyLoop(arr, inFunc, inExtra, i + 1, len);
      then arr;
  end matchcontinue;
end arrayApplyLoop;

public function arrayApplyR
"apply a function to each element of the array;
 the extra is the first argument in the apply function"
  input array<Option<Type_a>> inArr;
  input Integer inFilledSize "the filled size of the array, it might be less than arrayLength";
  input FuncType inFunc;
  input Type_b inExtra;
  output array<Option<Type_a>> outArr;
protected
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Type_b inExtra;
    input Option<Type_a> inElement;
  end FuncType;
algorithm
  outArr := matchcontinue(inArr, inFilledSize, inFunc, inExtra)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;

    // array is empty
    case (arr, _, _, _)
      equation
        true = intEq(0, inFilledSize);
      then arr;

    // array is not empty
    case (arr, _, _, _)
      equation
        arr = arrayApplyRLoop(arr, inFunc, inExtra, 1, inFilledSize);
      then arr;
  end matchcontinue;
end arrayApplyR;

protected function arrayApplyRLoop
"returns the index if found or 0 if not found.
 considers array indexed from 1"
  input array<Option<Type_a>> inArr;
  input FuncType inFunc;
  input Type_b inExtra;
  input Integer currentIndex;
  input Integer length;
  output array<Option<Type_a>> outArr;
protected
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncType
    input Type_b inExtra;
    input Option<Type_a> inElement;
  end FuncType;
algorithm
  outArr := matchcontinue(inArr, inFunc, inExtra, currentIndex, length)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;
      Option<Type_a> e;

    // we're at the end
    case (arr, _, _, i, len)
      equation
        true = intEq(i, len);
      then
        arr;

    // not at the end, see if we find it
    case (arr, _, _, i, len)
      equation
        e = arrayGet(arr, i);
        inFunc(inExtra, e);
        arr = arrayApplyRLoop(arr, inFunc, inExtra, i + 1, len);
      then arr;
  end matchcontinue;
end arrayApplyRLoop;

public function arrayMemberEqualityFunc
"returns the index if found or 0 if not found.
 considers array indexed from 1.
 it gets an equality check function!"
  input array<Option<Type_a>> inArr;
  input Integer inFilledSize "the filled size of the array, it might be less than arrayLength";
  input Option<Type_a> inElement;
  input FuncTypeEquality inEqualityCheckFunction;
  output Integer index;
protected
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeEquality
    input Option<Type_a> inElOld;
    input Option<Type_a> inElNew;
    output Boolean isEqual;
  end FuncTypeEquality;
algorithm
  index := matchcontinue(inArr, inFilledSize, inElement, inEqualityCheckFunction)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;

    // array is empty
    case (_, _, _, _)
      equation
        true = intEq(0, inFilledSize);
      then
        0;

    // array is not empty
    case (arr, _, _, _)
      equation
        i = arrayMemberEqualityFuncLoop(arr, inElement, inEqualityCheckFunction, 1, inFilledSize);
      then
        i;
  end matchcontinue;
end arrayMemberEqualityFunc;

protected function arrayMemberEqualityFuncLoop
"returns the index if found or 0 if not found.
 considers array indexed from 1"
  input array<Option<Type_a>> inArr;
  input Option<Type_a> inElement;
  input FuncTypeEquality inEqualityCheckFunction;
  input Integer currentIndex;
  input Integer length;
  output Integer index;
protected
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeEquality
    input Option<Type_a> inElOld;
    input Option<Type_a> inElNew;
    output Boolean isEqual;
  end FuncTypeEquality;
algorithm
  index := matchcontinue(inArr, inElement, inEqualityCheckFunction, currentIndex, length)
    local
      array<Option<Type_a>> arr;
      Integer i, len, pos;
      Option<Type_a> e;

    // we're at the end
    case (_, _, _, i, len)
      equation
        true = intEq(i, len);
      then 0;

    // not at the end, see if we find it
    case (arr, _, _, i, _)
      equation
        e = arrayGet(arr, i);
        true = inEqualityCheckFunction(e, inElement);
      then i;

    // not at the end, see if we find it
    case (arr, _, _, i, len)
      equation
        e = arrayGet(arr, i);
        false = inEqualityCheckFunction(e, inElement);
        i = arrayMemberEqualityFuncLoop(arr, inElement, inEqualityCheckFunction, i + 1, len);
      then i;
  end matchcontinue;
end arrayMemberEqualityFuncLoop;

public function arrayGetMemberOnTrue
  input ValueType inValue;
  input array<ElementType> inArray;
  input CompFunc inCompFunc;
  output ElementType outElement;
  output Integer outIndex;

  partial function CompFunc
    input ValueType inValue;
    input ElementType inElement;
    output Boolean outIsEqual;
  end CompFunc;

  replaceable type ValueType subtypeof Any;
  replaceable type ElementType subtypeof Any;
algorithm
  ((outElement, outIndex)) :=
    arrayGetMemberOnTrue2(inValue, inArray, inCompFunc, 1);
end arrayGetMemberOnTrue;

protected function arrayGetMemberOnTrue2
  input ValueType inValue;
  input array<ElementType> inArray;
  input CompFunc inCompFunc;
  input Integer inIndex;
  output tuple<ElementType, Integer> outTuple;

  partial function CompFunc
    input ValueType inValue;
    input ElementType inElement;
    output Boolean outIsEqual;
  end CompFunc;

  replaceable type ValueType subtypeof Any;
  replaceable type ElementType subtypeof Any;
protected
  ElementType e;
  Boolean b;
algorithm
  true := inIndex <= arrayLength(inArray);
  e := arrayGet(inArray, inIndex);
  b := inCompFunc(inValue, e);
  outTuple := Debug.bcallret4(boolNot(b), arrayGetMemberOnTrue2,
    inValue, inArray, inCompFunc, inIndex + 1, (e, inIndex));
end arrayGetMemberOnTrue2;

public function boolInt
  "Returns 1 if the given boolean is true, otherwise 0."
  input Boolean inBoolean;
  output Integer outInteger;
algorithm
  outInteger := match(inBoolean)
    case true then 1;
    else 0;
  end match;
end boolInt;

public function intBool
  "Returns true if the given integer is larger than 0, otherwise false."
  input Integer inInteger;
  output Boolean outBoolean;
algorithm
  outBoolean := inInteger > 0;
end intBool;

public function stringBool
  "Converts a string to a boolean value. true and yes is converted to true,
  false and no is converted to false. The function is case-insensitive."
  input String inString;
  output Boolean outBoolean;
algorithm
  outBoolean := stringBool2(System.tolower(inString));
end stringBool;

protected function stringBool2
  "Helper function to stringBool."
  input String inString;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inString)
    case "true" then true;
    case "false" then false;
    case "yes" then true;
    case "no" then false;
  end match;
end stringBool2;

public function optionList
"@author: adrpo
 SOME(a) => {a}
 NONE()  => {}"
  input Option<Type_a> inOption;
  output list<Type_a> outLst;
  replaceable type Type_a subtypeof Any;
algorithm
  outLst := match(inOption)
    local Type_a a;
    case SOME(a) then {a};
    case NONE() then {};
  end match;
end optionList;

public function stringPadRight
  "Pads a string with the given padding so that the resulting string is as long
   as the given width. If the string is already longer nothing is done to it.
   Note that the length of the padding is assumed to be one, i.e. a single char."
  input String inString;
  input Integer inPadWidth;
  input String inPadString;
  output String outString;
algorithm
  outString := matchcontinue(inString, inPadWidth, inPadString)
    local
      Integer pad_length;
      String pad_str;

    case (_, _, _)
      equation
        pad_length = inPadWidth - stringLength(inString);
        true = pad_length > 0;
        pad_str = stringAppendList(List.fill(inPadString, pad_length));
      then
        inString +& pad_str;

    else inString;
  end matchcontinue;
end stringPadRight;

public function stringPadLeft
  "Pads a string with the given padding so that the resulting string is as long
   as the given width. If the string is already longer nothing is done to it.
   Note that the length of the padding is assumed to be one, i.e. a single char."
  input String inString;
  input Integer inPadWidth;
  input String inPadString;
  output String outString;
algorithm
  outString := matchcontinue(inString, inPadWidth, inPadString)
    local
      Integer pad_length;
      String pad_str;

    case (_, _, _)
      equation
        pad_length = inPadWidth - stringLength(inString);
        true = pad_length > 0;
        pad_str = stringAppendList(List.fill(inPadString, pad_length));
      then
        pad_str +& inString;

    else inString;
  end matchcontinue;
end stringPadLeft;

public function stringWrap
  "Breaks the given string into multiple parts which are no longer than the
   given wrap length. The string is broken at word boundaries, i.e. at spaces, so
   that words are not split. The delimiter is prefixed to all result strings
   except for the first one. Example:
    stringWrap('this is a somewhat long string', 12, '\n  ') =>
      {'this is a', '\n  somewhat', '\n  long string'}"
  input String inString;
  input Integer inWrapLength;
  input String inDelimiter;
  output list<String> outStrings;
protected
  list<String> str;
  Integer dl;
algorithm
  str := stringListStringChar(inString);
  dl := stringLength(inDelimiter);
  outStrings := stringWrap2(str, inWrapLength, inDelimiter, dl, {}, 0, {});
end stringWrap;

protected function stringWrap2
  "Helper function to stringWrap."
  input list<String> inString;
  input Integer inWrapLength;
  input String inDelimiter;
  input Integer inDelimiterLength;
  input list<String> inAccumString;
  input Integer inStringLength;
  input list<String> inAccumStrings;
  output list<String> outStrings;
algorithm
  outStrings := matchcontinue(inString, inWrapLength, inDelimiter,
      inDelimiterLength, inAccumString, inStringLength, inAccumStrings)
    local
      String char, str, delim;
      list<String> rest_str, acc_strl, acc_str;
      Integer wl, sl, dl, pos;

    // The case when the given string is a multiple of the wraplength, i.e. both
    // the string and the accumulated string is empty.
    case ({}, _, _, _, _, 0, _) then listReverse(inAccumStrings);

    // Wrap on newline (the newline will be thrown away).
    case ("\n" :: rest_str, wl, delim, dl, acc_str, _, acc_strl)
      equation
        // The delimiter should not be applied to the first string.
        delim = if_(List.isEmpty(acc_strl), "", delim);
        str = delim +& stringAppendList(listReverse(acc_str));
        acc_strl = str :: acc_strl;
      then
        stringWrap2(rest_str, wl, inDelimiter, dl, {}, 0, acc_strl);

    // The string is empty, assemble the accumulated string and return the
    // wrapped strings.
    case ({}, _, delim, _, acc_str, _, acc_strl)
      equation
        // The delimiter should not be applied to the first string.
        delim = if_(List.isEmpty(acc_strl), "", delim);
        str = delim +& stringAppendList(listReverse(acc_str));
        acc_strl = str :: acc_strl;
      then
        listReverse(acc_strl);

    // The length of the accumulated string is equal to the wrap length, time to
    // assemble it and start accumulate a new string.
    case (_, wl, delim, dl, acc_str, sl, acc_strl)
      equation
        // The delimiter should not be applied to the first string.
        ((delim, dl)) = if_(List.isEmpty(acc_strl), ("", 0), (delim, dl));
        true = sl + dl >= wl;
        // Split the string at the first space (will be the last since the
        // string is reversed). The first part before the space will be the new
        // accumulated string, while the rest is added to the list of result
        // strings.
        pos = List.position(" ", acc_str);
        (acc_str, rest_str) = List.split(acc_str, pos);
        sl = listLength(acc_str);
        str = delim +& stringAppendList(listReverse(rest_str));
      then
        stringWrap2(inString, wl, inDelimiter, inDelimiterLength, acc_str,
          sl, str :: acc_strl);

    // None of the above cases matches, add the first character to the
    // accumulated string and continue with the rest of the string.
    case (char :: rest_str, wl, delim, dl, acc_str, sl, acc_strl)
      then stringWrap2(rest_str, wl, delim, dl, char :: acc_str, sl + 1, acc_strl);

  end matchcontinue;
end stringWrap2;

public function stringRest
  "Returns all but the first character of a string."
  input String inString;
  output String outRest;
protected
  Integer len;
algorithm
  len := stringLength(inString);
  outRest := System.substring(inString, 2, len);
end stringRest;

public function intProduct
  input list<Integer> lst;
  output Integer i;
algorithm
  i := List.fold(lst,intMul,1);
end intProduct;

public function nextPrime
  "Given a positive integer, returns the closest prime number that is equal or
   larger. This algorithm checks every odd number larger than the given number
   until it finds a prime, but since the distance between primes is relatively
   small (the largest gap between primes up to 32 bit is only around 300) it's
   still reasonably fast. It's useful for e.g. determining a good size for a
   hash table with a known number of elements."
  input Integer inN;
  output Integer outNextPrime;
algorithm
  outNextPrime := matchcontinue(inN)
    local

    // If the given number is larger than 2, round it up to the nearest odd
    // number and call nextPrime2.
    case _
      equation
        true = inN > 2;
      then
        nextPrime2(inN + intMod(inN + 1, 2));

    // Cases for number 0, 1 and 2.
    case 0 then 2;
    case 1 then 2;
    case 2 then 2;

    // Anything else must be negative.
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Util.nextPrime called with negative number."});
      then
        fail();

  end matchcontinue;
end nextPrime;

protected function nextPrime2
  "Helper function to nextPrime2, does the actual work of finding the next
   prime."
  input Integer inN;
  output Integer outNextPrime;
algorithm
  outNextPrime := matchcontinue(inN)
    // Return the given number if it's a prime.
    case _
      equation
        true = nextPrime_isPrime(inN);
      then
        inN;

    // Otherwise, check the next possible prime.
    else nextPrime2(inN + 2);
  end matchcontinue;
end nextPrime2;

protected function nextPrime_isPrime
  "Helper function to nextPrime2, checks if a given number is a prime or not.
   Note that this function is not a general prime checker, it only works for
   positive odd numbers."
  input Integer inN;
  output Boolean outIsPrime;
algorithm
  outIsPrime := nextPrime_isPrime2(inN, 3, intDiv(inN, 3));
end nextPrime_isPrime;

protected function nextPrime_isPrime2
  "Checks if a number is a prime or not, by checking for divisibility."
  input Integer inN;
  input Integer inI;
  input Integer inQ;
  output Boolean outIsPrime;
algorithm
  outIsPrime := matchcontinue(inN, inI, inQ)
    local
      Integer i, q;

    // Stop when all factors up to sqrt(inN) has been checked.
    case (_, _, _)
      equation
        true = inQ < inI;
      then
        true;

    // The number is divisible by a factor => not a prime.
    case (_, _, _)
      equation
        true = (inN == inQ * inI);
      then
        false;

    // Continue checking factors.
    else
      equation
        i = inI + 2;
        q = intDiv(inN, i);
      then
        nextPrime_isPrime2(inN, i, q);

  end matchcontinue;
end nextPrime_isPrime2;

public function anyToEmptyString "Useful if you do not want to write an unparser"
  input A a;
  output String empty;
  replaceable type A subtypeof Any;
algorithm
  empty := "";
end anyToEmptyString;

public uniontype TranslatableContent
  record gettext "Used to mark messages as targets for translation"
    String msgid;
  end gettext;
  record notrans "String cannot be translated; used for too generic messages"
    String str;
  end notrans;
end TranslatableContent;

public function translateContent "Translate content to a string"
  input TranslatableContent msg;
  output String str;
algorithm
  str := match msg
    case gettext(str)
      equation
        str = System.gettext(str);
      then str;
    case notrans(str) then str;
  end match;
end translateContent;

public function removeLast3Char
  input String str;
  output String outStr;
algorithm
  outStr := System.substring(str,1,stringLength(str)-3);
end removeLast3Char;

public function stringNotEqual
  input String str1;
  input String str2;
  output Boolean b;
algorithm
  b := not stringEq(str1,str2);
end stringNotEqual;

public function swap
  input Boolean cond;
  input A in1;
  input A in2;
  output A out1;
  output A out2;
  replaceable type A subtypeof Any;
algorithm
  (out1,out2) := match (cond,in1,in2)
    case (true, _, _) then (in2, in1);
    else (in1, in2);
  end match;
end swap;

public function realRangeSize
  "Calculates the size of a Real range given the start, step and stop values."
  input Real inStart;
  input Real inStep;
  input Real inStop;
  output Integer outSize;
algorithm
  outSize := realInt(realFloor(((inStop -. inStart) /. inStep) +. 5e-15)) + 1;
  outSize := intMax(outSize, 0);
end realRangeSize;

public function addInternalError
  input Boolean shouldShow;
  input String message;
algorithm
  _ := match(shouldShow, message)
    case (false, _) then ();
    case (true, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{message});
      then
        ();
  end match;
end addInternalError;

public function testsuiteFriendly "Testsuite friendly name (start after testsuite/ or build/)"
  input String name;
  output String friendly;
algorithm
  friendly := testsuiteFriendly2(Config.getRunningTestsuite(),Config.getRunningWSMTestsuite(),name);
end testsuiteFriendly;

protected function testsuiteFriendly2 "Testsuite friendly name (start after testsuite/ or build/)"
  input Boolean cond;
  input Boolean wsmTestsuite;
  input String name;
  output String friendly;
algorithm
  friendly := match (cond,wsmTestsuite,name)
    local
      Integer i;
      list<String> strs;
      String newName;
    case (_,true,_) then System.basename(name);

    case (true,_,_)
      equation
        newName = Debug.bcallret3("Windows_NT" ==& System.os(), System.stringReplace, name, "\\", "/", name);
        (i,strs) = System.regex(newName, "^(.*/testsuite/)?(.*/lib/omlibrary/)?(.*/build/)?(.*)$", 5, true, false);
        friendly = listGet(strs,i);
      then friendly;

    else name;
  end match;
end testsuiteFriendly2;

public function testsuiteFriendlyPath
"Adds ../ in front of a relative file path if we're running
 the testsuite, to compensate for tests being sandboxed.
 adrpo: only when running with partest the tests are sandboxed!"
  input String inPath;
  output String outPath;
algorithm
  outPath := matchcontinue(inPath)
    local
      String path;

    case _
      equation
        // we're running the testsuite
        true = Config.getRunningTestsuite();
        // directory or file does not exist in this directory
        false = System.directoryExists(inPath);
        false = System.regularFileExists(inPath);
        // prefix the path
        path = "../" +& inPath;
        true = System.directoryExists(path) or System.regularFileExists(path);
      then
        path;

    else inPath;
  end matchcontinue;
end testsuiteFriendlyPath;

protected function createDirectoryTreeH
  input String inString;
  input String parentDir;
  input Boolean parentDirExists;
  output Boolean outBool;
algorithm
  outBool := matchcontinue(inString,parentDir,parentDirExists)
    local
      Boolean b;

    case (_, _, _)
      equation
        true = stringEqual(parentDir, System.dirname(parentDir));
        b = System.createDirectory(inString);
    then b;

    case (_, _, true)
      equation
        b = System.createDirectory(inString);
    then b;

    case (_, _, false)
      equation
        true = createDirectoryTree(parentDir);
        b = System.createDirectory(inString);
    then b;

    else false;
  end matchcontinue;
end createDirectoryTreeH;

public function createDirectoryTree
  input String inString;
  output Boolean outBool;
protected
  String parentDir;
  Boolean parentDirExists;
algorithm
  parentDir := System.dirname(inString);
  parentDirExists := System.directoryExists(parentDir);
  outBool := createDirectoryTreeH(inString,parentDir,parentDirExists);
end createDirectoryTree;

public function nextPowerOf2
  "Rounds up to the nearest power of 2"
  input Integer i;
  output Integer v;
algorithm
  v := i-1;
  v := intBitOr(v, intBitLShift(v, 1));
  v := intBitOr(v, intBitLShift(v, 2));
  v := intBitOr(v, intBitLShift(v, 4));
  v := intBitOr(v, intBitLShift(v, 8));
  v := intBitOr(v, intBitLShift(v, 16));
  v := v + 1;
end nextPowerOf2;

public function endsWith
  input String str;
  input String suffix;
  output Boolean b;
algorithm
  b := match (str,suffix)
    local
      String strSuffix;
    case ("",_) then false;
    case (_,_)
      equation
        strSuffix = System.substring(str, if_(stringLength(str) > stringLength(suffix)+1, stringLength(str) - stringLength(suffix) + 1, 1), stringLength(str));
      then stringEq(strSuffix,suffix);
  end match;
end endsWith;

public function isCIdentifier
  input String str;
  output Boolean b;
protected
  Integer i;
algorithm
  (i,_) := System.regex(str, "^[][_A-Za-z0-9]*$", 0, true, false);
  b := i == 1;
end isCIdentifier;

public function stringTrunc
"@author:adrpo
 if the string is bigger than len keep only until len
 if not, return the same string"
  input String str;
  input Integer len;
  output String truncatedStr;
algorithm
  truncatedStr := matchcontinue(str, len)
    case (_, _)
      equation
        true = stringLength(str) <= len;
      then
        str;

    case (_, _)
      equation
        true = stringLength(str) > len;
        truncatedStr = System.substring(str, 0, len);
      then
        truncatedStr;
  end matchcontinue;
end stringTrunc;

public function getTempVariableIndex "Create an iterator or the like with a unique name"
  output String name;
algorithm
  name := stringAppend("$tmpVar",intString(System.tmpTickIndex(Global.tmpVariableIndex)));
end getTempVariableIndex;

public function anyReturnTrue
  input Type_a a;
  output Boolean b;
  replaceable type Type_a subtypeof Any;
algorithm
  b := true;
end anyReturnTrue;

end Util;
