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

encapsulated package List
" file:        List.mo
  package:     List
  description: List functions

  RCS: $Id$

  This package contains all functions that operate on the List type, such as
  mapping and filtering functions.

  Most of the functions in this package follows a naming convention that looks
  like (? means zero or one, + means one or more, * means zero or more):

    (operation(n)?(_m)?(prefix)*)+

  operation: The operation that the function does, i.e. mapping, folding, etc.
          n: The number of extra arguments that the function takes.
          m: The number of lists created.
     prefix: One of the following prefixes:
       AllValue: Checks that all elements of the list matches a given value.
           Bool: Returns true or false, instead of succeeding or failing.
            Elt: Takes a single element instead of a list.
              F: Will fail instead of returning the input list when
                 appropriate.
           Flat: An operator function that would normally return an
                 element, such as in map, will return a list instead. The
                 returned lists are flattened into a single list.
           IntN: A special version for integers between 1 and N.
           Last: Operates on the tail of the list.
           List: Operates on a list of lists.
              N: Returns a list of N elements.
         OnBool: Decides which operation to do based on a given boolean value.
      OnSuccess: Takes an operation function that succeeds or fails.
         OnTrue: Takes an operation function that returns true or false.
         Option: Operates on options.
              r: Takes an operation function with the arguments reversed.
        Reverse: Returns the processed list in reverse order.
         Sorted: Expects the given list(s) to be sorted.
          Tuple: Operates on tuples, either by expecting tuple types as
                 input or by returning tuples instead of multiple lists.

  All operator functions has the same parameter order as the types defined
  below, i.e. ValueType before ElementType, and so on. Some types are
  bidirectional, in which case they appear commented out in the outputs list
  below just to show the order. The r prefix changes this order by either moving
  FoldType to the top if FoldType is used, otherwise moving the ElementType to the
  bottom.

  The n and m numbers define the number of extra arguments or lists created, and
  is only used when they deviate from the expected values. I.e. map should be
  called map_1 according to the convention, since it creates one list. But this
  is the expected number of lists, so the _1 is omitted.

  An example of this convention:

  fold2 is a fold function, and as such it takes at least a list, a fold
  function and a fold argument, and returns the updated fold argument. The 2
  after it's name means that it also takes two extra arguments. Following the
  ordering of the types below we get that the order of it's signature is:

  (elementlist, fold function, extra arg 1, extra arg 2, fold arg) -> fold arg

  and the signature of the fold function that it takes is:

  (element, extra arg 1, extra arg 2, fold arg) -> fold arg
"

protected import Debug;
protected import Flags;
protected import Error;
protected import Util;

public replaceable type ValueType subtypeof Any;

replaceable type ElementType subtypeof Any;
replaceable type ElementType1 subtypeof Any;
replaceable type ElementType2 subtypeof Any;
replaceable type ElementType3 subtypeof Any;
replaceable type ElementType4 subtypeof Any;
replaceable type ElementType5 subtypeof Any;
replaceable type ElementInType subtypeof Any;

// partial function FuncType  "Do not remove, see package comment."

replaceable type ArgType1 subtypeof Any;
replaceable type ArgType2 subtypeof Any;
replaceable type ArgType3 subtypeof Any;
replaceable type ArgType4 subtypeof Any;
replaceable type ArgType5 subtypeof Any;
replaceable type ArgType6 subtypeof Any;
replaceable type ArgType7 subtypeof Any;
replaceable type ArgType8 subtypeof Any;
replaceable type ArgType9 subtypeof Any;

replaceable type FoldType subtypeof Any;
replaceable type FoldType1 subtypeof Any;
replaceable type FoldType2 subtypeof Any;
replaceable type FoldType3 subtypeof Any;


// Output types:
//replaceable type ElementType subtypeof Any;  "Do not remove, see package comment."
replaceable type ElementOutType subtypeof Any;
replaceable type ElementOutType1 subtypeof Any;
replaceable type ElementOutType2 subtypeof Any;
replaceable type ElementOutType3 subtypeof Any;

//replaceable type FoldType subtypeof Any;  "Do not remove, see package comment."

public function create
  "Creates a list from an element."
  input ElementType inElement;
  output list<ElementType> outList;
algorithm
  outList := {inElement};
end create;

public function create2
  "Creates a list from two elements."
  input ElementType inElement1;
  input ElementType inElement2;
  output list<ElementType> outList;
algorithm
  outList := {inElement1, inElement2};
end create2;

public function fill
  "Returns a list of n element.
     Example: fill(2, 3) => {2, 2, 2}"
  input ElementType inElement;
  input Integer inCount;
  output list<ElementType> outList;
algorithm
  outList := matchcontinue(inElement, inCount)
    case (_, _)
      equation
        true = inCount >= 0;
      then
        fill_tail(inElement, inCount, {});

    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "- List.fill failed with negative value "
          +& intString(inCount));
      then
        fail();

  end matchcontinue;
end fill;

protected function fill_tail
  "Tail recursive implementation of fill."
  input ElementType inElement;
  input Integer inCount;
  input list<ElementType> inAccumList;
  output list<ElementType> outList;
algorithm
  outList := match(inElement, inCount, inAccumList)
    case (_, 0, _) then inAccumList;

    else fill_tail(inElement, inCount - 1, inElement :: inAccumList);
  end match;
end fill_tail;

public function intRange
  "Returns a list of n integers from 1 to inStop.
     Example: listIntRange(3) => {1,2,3}"
  input Integer inStop;
  output list<Integer> outRange;
algorithm
  outRange := intRange_tail(1, 1, inStop);
end intRange;

public function intRange2
  "Returns a list of integers from inStart to inStop.
     Example listIntRange2(3,5) => {3,4,5}"
  input Integer inStart;
  input Integer inStop;
  output list<Integer> outRange;
protected
  Integer step;
algorithm
  step := Util.if_(intLt(inStart, inStop), 1, -1);
  outRange := intRange_tail(inStart, step, inStop);
end intRange2;

public function intRange3
  "Returns a list of integers from inStart to inStop with step inStep.
     Example: listIntRange2(3,9,2) => {3,5,7,9}"
  input Integer inStart;
  input Integer inStep;
  input Integer inStop;
  output list<Integer> outRange;
algorithm
  outRange := intRange_tail(inStart, inStep, inStop);
end intRange3;

protected function intRange_tail
  "Tail recursive implementation of list range."
  input Integer inStart;
  input Integer inStep;
  input Integer inStop;
  output list<Integer> outResult;
algorithm
  outResult := matchcontinue(inStart, inStep, inStop)
    local
      String error_str;
      Boolean is_done;

    case (_, 0, _)
      equation
        error_str = stringDelimitList(
          map({inStart, inStep, inStop}, intString), ":");
        Error.addMessage(Error.ZERO_STEP_IN_ARRAY_CONSTRUCTOR, {error_str});
      then
        fail();

    case (_, _, _)
      equation
        false = intEq(inStep, 0);
        true = (inStart == inStop);
      then
        {inStart};

    case (_, _, _)
      equation
        false = intEq(inStep, 0);
        true = (inStep > 0);
        is_done = (inStart > inStop);
      then
        intRange_tail2(inStart, inStep, inStop, intGt, is_done, {});

    case (_, _, _)
      equation
        false = intEq(inStep, 0);
        true = (inStep < 0);
        is_done = (inStart < inStop);
      then
        intRange_tail2(inStart, inStep, inStop, intLt, is_done, {});

  end matchcontinue;
end intRange_tail;

protected function intRange_tail2
  "Helper function to intRange_tail."
  input Integer inStart;
  input Integer inStep;
  input Integer inStop;
  input CompFunc compFunc;
  input Boolean isDone;
  input list<Integer> inValues;
  output list<Integer> outValues;

  partial function CompFunc
    input Integer inValue1;
    input Integer inValue2;
    output Boolean outRes;
  end CompFunc;
algorithm
  outValues := match(inStart, inStep, inStop, compFunc, isDone, inValues)
    local
      Integer next;
      list<Integer> vals;
      Boolean is_done;

    case (_, _, _, _, true, _)
      then listReverse(inValues);

    else
      equation
        next = inStart + inStep;
        vals = inStart :: inValues;
        is_done = compFunc(next, inStop);
      then
        intRange_tail2(next, inStep, inStop, compFunc, is_done, vals);

  end match;
end intRange_tail2;

public function toOption
  "Returns an option of the element in a list if the list contains exactly one
   element, NONE() if the list is empty and fails if the list contains more than
   one element."
  input list<ElementType> inList;
  output Option<ElementType> outOption;
algorithm
  outOption := match(inList)
    local
      ElementType e;

    case {} then NONE();
    case {e} then SOME(e);
  end match;
end toOption;

public function fromOption
  "Returns an empty list for NONE() and a list containing the element for
   SOME(element)."
  input Option<ElementType> inElement;
  output list<ElementType> outList;
algorithm
  outList := match(inElement)
    local
      ElementType e;

    case SOME(e) then {e};
    case NONE() then {};
  end match;
end fromOption;

public function isEmpty
  "Returns true if the given list is empty, otherwise false."
  input list<ElementType> inList;
  output Boolean outIsEmpty;
algorithm
  outIsEmpty := match(inList)
    case ({}) then true;
    else false;
  end match;
end isEmpty;

public function isNotEmpty
  "Returns true if the given list is not empty, otherwise false."
  input list<ElementType> inList;
  output Boolean outIsNotEmpty;
algorithm
  outIsNotEmpty := match(inList)
    case ({}) then false;
    else true;
  end match;
end isNotEmpty;

public function assertIsEmpty
  "Fails if the given list is not empty."
  input list<ElementType> inList;
algorithm
  {} := inList;
end assertIsEmpty;

public function isEqual
  "Checks if two lists are equal. If inEqualLength is true the lists are assumed
   to be of equal length, and if it is false they can be of different lengths (in
   which case only the overlapping parts of the lists are checked)."
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  input Boolean inEqualLength;
  output Boolean outIsEqual;
algorithm
  outIsEqual := matchcontinue(inList1, inList2, inEqualLength)
    local
      ElementType e1, e2;
      list<ElementType> rest1, rest2;

    case ({}, {}, _) then true;
    case ({}, _, false) then true;
    case (_, {}, false) then true;
    case (e1 :: rest1, e2 :: rest2, _)
      equation
        equality(e1 = e2);
      then
        isEqual(rest1, rest2, inEqualLength);

    else false;
  end matchcontinue;
end isEqual;

public function isEqualOnTrue
  "Takes two lists and an equality function, and returns whether the lists are
   equal or not."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input CompFunc inCompFunc;
  output Boolean outIsEqual;

  partial function CompFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outIsEqual := matchcontinue(inList1, inList2, inCompFunc)
    local
      ElementType1 e1;
      ElementType2 e2;
      list<ElementType1> rest1;
      list<ElementType2> rest2;

    case ({}, {}, _) then true;
    case (e1 :: rest1, e2 :: rest2, _)
      equation
        true = inCompFunc(e1, e2);
      then
        isEqualOnTrue(rest1, rest2, inCompFunc);

    else false;
  end matchcontinue;
end isEqualOnTrue;

public function isPrefixOnTrue
  "Checks if the first list is a prefix of the second list, i.e. that all
   elements in the first list is equal to the corresponding elements in the
   second list."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input CompFunc inCompFunc;
  output Boolean outIsPrefix;

  partial function CompFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outIsPrefix := matchcontinue(inList1, inList2, inCompFunc)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;

    case ({}, _, _) then true;
    case (e1 :: rest1, e2 :: rest2, _)
      equation
        true = inCompFunc(e1, e2);
      then
        isPrefixOnTrue(rest1, rest2, inCompFunc);

    else false;
  end matchcontinue;
end isPrefixOnTrue;

public function consr
  "The same as the builtin cons operator, but with the order of the arguments
  swapped."
  input list<ElementType> inList;
  input ElementType inElement;
  output list<ElementType> outList;
algorithm
  outList := inElement :: inList;
end consr;

public function consOnTrue
  "Adds the element to the front of the list if the condition is true."
  input Boolean inCondition;
  input ElementType inElement;
  input list<ElementType> inList;
  output list<ElementType> outList;
algorithm
  outList := match(inCondition, inElement, inList)
    case (true, _, _) then inElement :: inList;
    else inList;
  end match;
end consOnTrue;

public function consOnSuccess
  "Adds the element to the front of the list if the predicate succeeds."
  input ElementType inElement;
  input list<ElementType> inList;
  input Predicate inPredicate;
  output list<ElementType> outList;

  partial function Predicate
    input ElementType inElement;
  end Predicate;
algorithm
  outList := matchcontinue(inElement, inList, inPredicate)
    case (_, _, _)
      equation
        inPredicate(inElement);
      then
        inElement :: inList;

    else inList;
  end matchcontinue;
end consOnSuccess;

public function consOption
  "Adds an optional element to the front of the list, or returns the list if the
   element is none."
  input Option<ElementType> inElement;
  input list<ElementType> inList;
  output list<ElementType> outList;
algorithm
  outList := match(inElement, inList)
    local
      ElementType e;

    case (SOME(e), _) then e :: inList;
    else inList;
  end match;
end consOption;

public function consOnBool
  "Adds an element to one of two lists, depending on the given boolean value."
  input Boolean inValue;
  input ElementType inElement;
  input list<ElementType> inTrueList;
  input list<ElementType> inFalseList;
  output list<ElementType> outTrueList;
  output list<ElementType> outFalseList;
algorithm
  (outTrueList, outFalseList) :=
  match(inValue, inElement, inTrueList, inFalseList)
    local
      list<ElementType> lst;

    case (true, _, _, _)
      equation
        lst = inElement :: inTrueList;
      then
        (lst, inFalseList);

    else
      equation
        lst = inElement :: inFalseList;
      then
        (inTrueList, lst);
  end match;
end consOnBool;

public function consN
  "concate n time inElement to the list:
  n = 5, inElement=1, list={1,2} -> list={1,1,1,1,1,1,2}"
  input Integer size;
  input ElementType inElement;
  input list<ElementType> inList;
  output list<ElementType> outList;
algorithm
  outList := matchcontinue(size,inElement,inList)
    case(0,_,_) then inList;
    case(_,_,_)
      equation
        true = intGt(size,0);
      then
        consN_impl(size,inElement,inList);
    else then inList;
  end matchcontinue;
end consN;

protected function consN_impl
  "concate n time inElement to the list:
  n = 5, inElement=1, list={1,2} -> list={1,1,1,1,1,1,2}"
  input Integer size;
  input ElementType inElement;
  input list<ElementType> inList;
  output list<ElementType> outList;
algorithm
  outList := match(size,inElement,inList)
    case(0,_,_) then inList;
    else then consN(size-1,inElement,inElement::inList);
  end match;
end consN_impl;

public function appendNoCopy
  "This function handles special cases such as empty lists so it does not copy
   if any of the arguments are empty lists."
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  output list<ElementType> outList;
algorithm
  outList := match(inList1, inList2)
    case ({}, _) then inList2;
    case (_, {}) then inList1;
    else listAppend(inList1, inList2);
  end match;
end appendNoCopy;

public function appendr
  "Appends two lists in reverse order compared to listAppend."
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  output list<ElementType> outList;
algorithm
  outList := listAppend(inList2, inList1);
end appendr;

public function appendElt
  "Appends an element to the end of the list. Note that this is very
   inefficient, so try to avoid using this function."
  input ElementType inElement;
  input list<ElementType> inList;
  output list<ElementType> outList;
algorithm
  outList := listAppend(inList, {inElement});
end appendElt;

public function appendLastList
  "Appends a list to the last list in a list of lists."
  input list<list<ElementType>> inListList;
  input list<ElementType> inList;
  output list<list<ElementType>> outListList;
algorithm
  outListList := match(inListList, inList)
    local
      list<ElementType> l;
      list<list<ElementType>> ll;

    case ({}, _) then {inList};

    case ({l}, _)
      equation
        l = listAppend(l, inList);
      then
        {l};

    case (l :: ll, _)
      equation
        ll = appendLastList(ll, inList);
      then
        l :: ll;
  end match;
end appendLastList;

public function insert
 "Inserts an element at a position
  example: insert({2,1,4,2},2,3) => {2,3,1,4,2} "
  input list<ElementType> inList;
  input Integer inN;
  input ElementType inElement;
  output list<ElementType> outList;
protected
  list<ElementType> lst1, lst2;
algorithm
  true := (inN > 0);
  (lst1, lst2) := split(inList, inN-1);
  outList := listAppend(listAppend(lst1,{inElement}),lst2);
end insert;

public function set
 "set an element at a position
  example: insert({2,1,4,2},2,3) => {2,3,4,2} "
  input list<ElementType> inList;
  input Integer inN;
  input ElementType inElement;
  output list<ElementType> outList;
protected
  list<ElementType> lst1, lst2;
algorithm
  true := (inN > 0);
  (lst1, lst2) := split(inList, inN-1);
  lst2 := stripFirst(lst2);
  outList := listAppend(listAppend(lst1,{inElement}),lst2);
end set;

public function first
  "Returns the first element of a list. Fails if the list is empty."
  input list<ElementType> inList;
  output ElementType outFirst;
algorithm
  outFirst := listGet(inList, 1);
end first;

public function firstOrEmpty
  "Returns the first element of a list as a list, or an empty list if the given
   list is empty."
  input list<ElementType> inList;
  output list<ElementType> outList;
algorithm
  outList := match(inList)
    local
      ElementType e;

    case e :: _ then {e};
    else {};
  end match;
end firstOrEmpty;

public function second
  "Returns the second element of a list. Fails if the list is empty."
  input list<ElementType> inList;
  output ElementType outSecond;
algorithm
  outSecond := listGet(inList, 2);
end second;

public function last
  "Returns the last element of a list. Fails if the list is empty."
  input list<ElementType> inList;
  output ElementType outLast;
algorithm
  outLast := match(inList)
    local
      ElementType e;
      list<ElementType> rest;

    case {e} then e;
    case (_ :: rest) then last(rest);
  end match;
end last;

public function secondLast
  "Returns the second last element of a list, or fails if such an element does
   not exist."
  input list<ElementType> inList;
  output ElementType outSecondLast;
algorithm
  _ :: outSecondLast :: _ := listReverse(inList);
end secondLast;

public function lastN
  "Returns the last N elements of a list."
  input list<ElementType> inList;
  input Integer inN;
  output list<ElementType> outList;
protected
  Integer len;
algorithm
  true := inN >= 0;
  len := listLength(inList);
  outList := stripN(inList, len - inN);
end lastN;

public function rest
  "Returns all elements except for the first in a list."
  input list<ElementType> inList;
  output list<ElementType> outList;
algorithm
  _ :: outList := inList;
end rest;

public function restCond
  "Returns all elements except for the first in a list."
  input Boolean cond;
  input list<ElementType> inList;
  output list<ElementType> outList;
algorithm
  outList := match (cond,inList)
    case (true,_::outList) then outList;
    case (false,_) then inList;
  end match;
end restCond;

public function restOrEmpty
  "Returns all elements except for the first in a list, or the empty list of the
   list is empty."
  input list<ElementType> inList;
  output list<ElementType> outList;
algorithm
  outList := match(inList)
    local
      list<ElementType> r;

    case {} then {};
    case _ :: r then r;

  end match;
end restOrEmpty;

public function getIndexFirst
  input Integer index;
  input list<ElementType> inList;
  output ElementType element;
algorithm
 element := listGet(inList, index);
end getIndexFirst;

public function firstN
  "Returns the first N elements of a list, or fails if there are not enough
   elements in the list."
  input list<ElementType> inList;
  input Integer inN;
  output list<ElementType> outList;
algorithm
  true := (inN >= 0);
  outList := firstN_tail(inList, inN, {});
  outList := listReverse(outList);
end firstN;

protected function firstN_tail
  "Tail recursive implementation of firstN."
  input list<ElementType> inList;
  input Integer inN;
  input list<ElementType> inAccum;
  output list<ElementType> outList;
algorithm
  outList := match(inList, inN, inAccum)
    local
      ElementType e;
      list<ElementType> rest;
      Integer n;

      case (_, 0, _) then inAccum;

      case (e :: rest, n, _)
        equation
          n = n - 1;
        then
          firstN_tail(rest, n, e :: inAccum);

  end match;
end firstN_tail;

public function stripFirst
  "Removes the first element of a list, but returns the empty list if the given
   list is empty."
  input list<ElementType> inList;
  output list<ElementType> outList;
algorithm
  outList := match(inList)
    local
      list<ElementType> rest;

    case {} then {};
    case _ :: rest then rest;
  end match;
end stripFirst;

public function stripLast
  "Removes the last element of a list. If the list is the empty list, the
   function returns the empty list."
  input list<ElementType> inList;
  output list<ElementType> outList;
algorithm
  outList := stripLast_tail(inList, {});
end stripLast;

protected function stripLast_tail
  "Tail recursive implementation of stripLast."
  input list<ElementType> inList;
  input list<ElementType> inAccum;
  output list<ElementType> outList;
algorithm
  outList := match(inList, inAccum)
    local
      ElementType e;
      list<ElementType> rest;

    case ({}, _) then {};
    case ({_}, _) then listReverse(inAccum);
    case (e :: rest, _) then stripLast_tail(rest, e :: inAccum);
  end match;
end stripLast_tail;

public function stripN
  "Strips the N first elements from a list. Fails if the list contains less than
   N elements, or if N is negative."
  input list<ElementType> inList;
  input Integer inN;
  output list<ElementType> outList;
algorithm
  true := inN >= 0;
  outList := stripN_impl(inList, inN);
end stripN;

public function stripN_impl
  "Implementation function for stripN."
  input list<ElementType> inList;
  input Integer inN;
  output list<ElementType> outList;
algorithm
  outList := match(inList, inN)
    local
      list<ElementType> rest;

    case (_, 0) then inList;

    case (_ :: rest, _)
      then stripN_impl(rest, inN - 1);

  end match;
end stripN_impl;

public function sort
  "Sorts a list given an ordering function with the mergesort algorithm.
    Example:
      sort({2, 1, 3}, intGt) => {1, 2, 3}
      sort({2, 1, 3}, intLt) => {3, 2, 1}"
  input list<ElementType> inList;
  input CompareFunc inCompFunc;
  output list<ElementType> outList;

  partial function CompareFunc
    input ElementType inElement1;
    input ElementType inElement2;
    output Boolean inRes;
  end CompareFunc;
algorithm
  outList := match(inList, inCompFunc)
    local
      ElementType e;
      list<ElementType> left, right;
      Integer middle;

    case ({}, _) then {};
    case ({e}, _) then {e};
    else
      equation
        middle = intDiv(listLength(inList), 2);
        (left, right) = split(inList, middle);
        left = sort(left, inCompFunc);
        right = sort(right, inCompFunc);
      then merge(left, right, inCompFunc, {});

  end match;
end sort;

public function sortedFilterDuplicates
  "Checks if the list has any duplicates in it"
  input list<ElementType> inList;
  input CompareFunc inCompFunc "Equality comparator";
  output list<ElementType> duplicates;

  partial function CompareFunc
    input ElementType inElement1;
    input ElementType inElement2;
    output Boolean outRes;
  end CompareFunc;
algorithm
  duplicates := sortedFilterDuplicatesWork(inList,inCompFunc,{});
end sortedFilterDuplicates;

protected function sortedFilterDuplicatesWork
  "Checks if the list has any duplicates in it"
  input list<ElementType> inList;
  input CompareFunc inCompFunc "Equality comparator";
  input list<ElementType> inAcc;
  output list<ElementType> duplicates;

  partial function CompareFunc
    input ElementType inElement1;
    input ElementType inElement2;
    output Boolean outRes;
  end CompareFunc;
algorithm
  duplicates := match(inList, inCompFunc, inAcc)
    local
      ElementType e1,e2;
      list<ElementType> rest;
      Boolean b;

    case ({}, _, _) then listReverse(inAcc);
    case (_::{}, _, _) then listReverse(inAcc);
    case (e1::(rest as e2::_), _, _)
      equation
        b = inCompFunc(e1,e2);
      then sortedFilterDuplicatesWork(rest, inCompFunc, consOnTrue(b, e1, inAcc));
  end match;
end sortedFilterDuplicatesWork;

public function sortedUnique
  "Takes a list of elements and returns a list with duplicates removed, so that each element in the new list is unique. Assumes that the input is sorted."
  input list<ElementType> inList;
  input CompareFunc inCompFunc "Equality comparator";
  output list<ElementType> duplicates;

  partial function CompareFunc
    input ElementType inElement1;
    input ElementType inElement2;
    output Boolean outRes;
  end CompareFunc;
algorithm
  duplicates := sortedUniqueWork(inList,inCompFunc,{});
end sortedUnique;

protected function sortedUniqueWork
  "Checks if the list has any duplicates in it"
  input list<ElementType> inList;
  input CompareFunc inCompFunc "Equality comparator";
  input list<ElementType> inAcc;
  output list<ElementType> duplicates;

  partial function CompareFunc
    input ElementType inElement1;
    input ElementType inElement2;
    output Boolean outRes;
  end CompareFunc;
algorithm
  duplicates := match(inList, inCompFunc, inAcc)
    local
      ElementType e1,e2;
      list<ElementType> rest;
      Boolean b;

    case ({}, _, _) then listReverse(inAcc);
    case (e1::{}, _, _) then listReverse(e1::inAcc);
    case (e1::(rest as e2::_), _, _)
      equation
        b = inCompFunc(e1,e2);
      then sortedUniqueWork(rest, inCompFunc, consOnTrue(not b, e1, inAcc));
  end match;
end sortedUniqueWork;

protected function merge
  "Helper function to sort, merges two sorted lists."
  input list<ElementType> inLeft;
  input list<ElementType> inRight;
  input CompareFunc inCompFunc;
  input list<ElementType> acc;
  output list<ElementType> outList;

  partial function CompareFunc
    input ElementType inElement1;
    input ElementType inElement2;
    output Boolean outRes;
  end CompareFunc;
algorithm
  outList := match (inLeft, inRight, inCompFunc, acc)
    local
      Boolean b;
      ElementType l, r, el;
      list<ElementType> l_rest, r_rest, res;

    /* Tail recursive version */
    case (l :: l_rest, r :: r_rest, _, _)
      equation
        b = inCompFunc(r, l);
        l_rest = Util.if_(b,l_rest,inLeft);
        r_rest = Util.if_(not b,r_rest,inRight);
        el = Util.if_(b, listGet(inLeft, 1), listGet(inRight, 1));
        res = merge(l_rest, r_rest, inCompFunc, el::acc);
      then res;

    case ({}, {}, _, _) then listReverse(acc);
    case ({}, _, _, _) then listAppend(listReverse(acc),inRight);
    case (_, {}, _, _) then listAppend(listReverse(acc),inLeft);

  end match;
end merge;

public function mergeSorted
  "This function merges two sorted lists into one sorted list. It takes a
  comparison function that defines a strict weak ordering of the elements, i.e.
  that returns true if the first element should be placed before the second
  element in the sorted list."
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  input CompFunc inCompFunc;
  output list<ElementType> outList;

  partial function CompFunc
    input ElementType inElement1;
    input ElementType inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outList := matchcontinue(inList1, inList2, inCompFunc)
    local
      ElementType e1, e2;
      list<ElementType> l1, l2, res;
    case ({}, l2, _) then l2;
    case (l1, {}, _) then l1;
    case (e1 :: l1, l2 as (e2 :: _), _)
      equation
        true = inCompFunc(e1, e2);
        res = mergeSorted(l1, l2, inCompFunc);
      then
        e1 :: res;
    case (l1, e2 :: l2, _)
      equation
        res = mergeSorted(l1, l2, inCompFunc);
      then
        e2 :: res;
  end matchcontinue;
end mergeSorted;

public function sortIntN
  "Provides same functionality as sort, but for integer values between 1
   and N. The complexity in this case is O(n)"
  input list<Integer> inList;
  input Integer inN;
  output list<Integer> outSorted;
protected
  array<Boolean> a1;
algorithm
  a1 := arrayCreate(inN, false);
  a1 := fold1r(inList,arrayUpdate,true,a1);
  outSorted := sortIntN1(a1, inN, {});
end sortIntN;

protected function sortIntN1
  input array<Boolean> a1;
  input Integer index;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := match(a1,index,iAcc)
    local
      list<Integer> acc;
    case(_,0,_)
      then
        iAcc;
    else
      equation
        acc = consOnTrue(a1[index], index, iAcc);
      then
        sortIntN1(a1,index-1,acc);
  end match;
end sortIntN1;

public function unique
  "Takes a list of elements and returns a list with duplicates removed, so that
   each element in the new list is unique."
  input list<ElementType> inList;
  output list<ElementType> outList;
algorithm
  outList := union_tail({}, inList, {});
end unique;

public function uniqueIntN
  "Takes a list of integes and returns a list with duplicates removed, so that
   each element in the new list is unique. O(listLength(inList))"
  input list<Integer> inList;
  input Integer N;
  output list<Integer> outList;
protected
  array<Boolean> arr;
algorithm
  arr := arrayCreate(N,true);
  outList := uniqueIntN_work(inList, arr, {});
end uniqueIntN;

protected function uniqueIntN_work
  input list<Integer> inList;
  input array<Boolean> arr;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := match(inList,arr,iAcc)
    local
      Integer i;
      list<Integer> ilst,acc;
    case ({},_,_) then iAcc;
    case (i::ilst,_,_)
      equation
        acc = consOnTrue(arr[i],i,iAcc);
        _= arrayUpdate(arr,i,false);
      then
        uniqueIntN_work(ilst,arr,acc);
  end match;
end uniqueIntN_work;

public function uniqueIntNArr
  "Takes a list of integes and returns a list with duplicates removed, so that
   each element in the new list is unique. O(listLength(inList)). The function
   also takes an array of Integer of size N+1 to mark the already selected entries <= N.
   The last entrie of the array is used for the mark index. It will be updated after
   each call"
  input list<Integer> inList;
  input array<Integer> markarr;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := matchcontinue(inList,markarr,iAcc)
    local
      Integer len,mark;
      list<Integer> acc;
    case ({},_,_)
      then iAcc;
    case (_,_,_)
      equation
       len = arrayLength(markarr);
       mark = markarr[len];
       _=arrayUpdate(markarr,len,mark+1);
       acc = uniqueIntNArr1(inList,len,mark+1,markarr,iAcc);
     then
        acc;
    else
      equation
        print("List.uniqueIntNArr failed entry to large\n");
      then
        fail();
  end matchcontinue;
end uniqueIntNArr;

protected function uniqueIntNArr1
  "helpfer for uniqueIntNArr1"
  input list<Integer> inList;
  input Integer len;
  input Integer mark;
  input array<Integer> markarr;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := matchcontinue(inList,len,mark,markarr,iAcc)
    local
      Integer i;
      list<Integer> ilst,acc;
    case ({},_,_,_,_) then iAcc;
    case (i::ilst,_,_,_,_)
      equation
        true = intLt(i,len);
        acc = consOnTrue(intNe(markarr[i],mark),i,iAcc);
        _=arrayUpdate(markarr,i,mark);
      then
        uniqueIntNArr1(ilst,len,mark,markarr,acc);
    else
      equation
        print("List.uniqueIntNArr failed entrie to large\n");
      then
        fail();
  end matchcontinue;
end uniqueIntNArr1;

public function uniqueOnTrue
  "Takes a list of elements and a comparison function over two elements of the
   list and returns a list with duplicates removed, so that each element in the
   new list is unique."
  input list<ElementType> inList;
  input CompFunc inCompFunc;
  output list<ElementType> outList;

  partial function CompFunc
    input ElementType inElement1;
    input ElementType inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outList := unionOnTrue_tail({}, inList, inCompFunc, {});
end uniqueOnTrue;

public function reverseList
  "Takes a list of lists and reverses it at both levels, i.e. both the list
   itself and each sublist.
     Example:
       reverseList({{1, 2}, {3, 4, 5}, {6}}) => {{6}, {5, 4, 3}, {2, 1}}"
  input list<list<ElementType>> inList;
  output list<list<ElementType>> outList;
algorithm
  outList := map(inList, listReverse);
  outList := listReverse(outList);
end reverseList;

public function split
  "Takes a list and a position, and splits the list the position given.
    Example: split({1, 2, 5, 7}, 2) => ({1, 2}, {5, 7})"
  input list<ElementType> inList;
  input Integer inPosition;
  output list<ElementType> outList1;
  output list<ElementType> outList2;
algorithm
  (outList1, outList2) := matchcontinue(inList, inPosition)
    local
      list<ElementType> list1, list2;

    case (_, 0) then ({}, inList);
    case (_, _)
      equation
        (inPosition >= 0) = true;
        (list1, list2) = split2(inList, {}, inPosition);
      then
        (list2, list1);

    else
      equation
        (inPosition < 0) = true;
        print("Index out of bounds (less than zero) in relation List.split\n");
      then
        fail();
  end matchcontinue;
end split;

public function split2
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  input Integer inPosition;
  output list<ElementType> outList1;
  output list<ElementType> outList2;
algorithm
  (outList1, outList2) := match (inList1, inList2, inPosition)
    local
      ElementType e;
      list<ElementType> rest, list1, list2;
      Integer new_pos;

    case (_, _, 0) then (inList1, listReverse(inList2));

    case (e :: rest, _, _)
      equation
        new_pos = inPosition - 1;
        (list1, list2) = split2(rest, e :: inList2, new_pos);
      then
        (list1, list2);

    case ({}, _, _)
      equation
        print("Index out of bounds (greater than list length) in relation List.split\n");
      then
        fail();
  end match;
end split2;

public function splitOnTrue
  "Splits a list into two sublists depending on predicate function."
  input list<ElementType> inList;
  input PredicateFunc inFunc;
  output list<ElementType> outTrueList;
  output list<ElementType> outFalseList;

  partial function PredicateFunc
    input ElementType inElement;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  (outTrueList, outFalseList) :=
    splitOnTrue_tail(inList, inFunc, {}, {});
end splitOnTrue;

protected function splitOnTrue_tail
  "Tail recursive implementation of splitOnTrue."
  input list<ElementType> inList;
  input PredicateFunc inFunc;
  input list<ElementType> inTrueList;
  input list<ElementType> inFalseList;
  output list<ElementType> outTrueList;
  output list<ElementType> outFalseList;

  partial function PredicateFunc
    input ElementType inElement;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  (outTrueList, outFalseList) :=
  match(inList, inFunc, inTrueList, inFalseList)
    local
      ElementType e;
      list<ElementType> rest_e, tl, fl;
      Boolean pred;

    case ({}, _, tl, fl)
      then (listReverse(tl), listReverse(fl));

    case (e :: rest_e, _, tl, fl)
      equation
        pred = inFunc(e);
        (tl, fl) = consOnBool(pred, e, tl, fl);
        (tl, fl) = splitOnTrue_tail(rest_e, inFunc, tl, fl);
      then
        (tl, fl);
  end match;
end splitOnTrue_tail;

public function split1OnTrue
  "Splits a list into two sublists depending on predicate function."
  input list<ElementType> inList;
  input PredicateFunc inFunc;
  input ArgType1 inArg1;
  output list<ElementType> outTrueList;
  output list<ElementType> outFalseList;

  partial function PredicateFunc
    input ElementType inElement;
    input ArgType1 inArg1;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  (outTrueList, outFalseList) :=
    split1OnTrue_tail(inList, inFunc, inArg1, {}, {});
end split1OnTrue;

protected function split1OnTrue_tail
  "Tail recursive implementation of split1OnTrue."
  input list<ElementType> inList;
  input PredicateFunc inFunc;
  input ArgType1 inArg1;
  input list<ElementType> inTrueList;
  input list<ElementType> inFalseList;
  output list<ElementType> outTrueList;
  output list<ElementType> outFalseList;

  partial function PredicateFunc
    input ElementType inElement;
    input ArgType1 inArg1;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  (outTrueList, outFalseList) :=
  match(inList, inFunc, inArg1, inTrueList, inFalseList)
    local
      ElementType e;
      list<ElementType> rest_e, tl, fl;
      Boolean pred;

    case ({}, _, _, tl, fl)
      then (listReverse(tl), listReverse(fl));

    case (e :: rest_e, _, _, tl, fl)
      equation
        pred = inFunc(e, inArg1);
        (tl, fl) = consOnBool(pred, e, tl, fl);
        (tl, fl) = split1OnTrue_tail(rest_e, inFunc, inArg1, tl, fl);
      then
        (tl, fl);
  end match;
end split1OnTrue_tail;

public function split2OnTrue
  "Splits a list into two sublists depending on predicate function."
  input list<ElementType> inList;
  input PredicateFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  output list<ElementType> outTrueList;
  output list<ElementType> outFalseList;

  partial function PredicateFunc
    input ElementType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  (outTrueList, outFalseList) :=
    split2OnTrue_tail(inList, inFunc, inArg1, inArg2, {}, {});
end split2OnTrue;

protected function split2OnTrue_tail
  "Tail recursive implementation of split2OnTrue."
  input list<ElementType> inList;
  input PredicateFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input list<ElementType> inTrueList;
  input list<ElementType> inFalseList;
  output list<ElementType> outTrueList;
  output list<ElementType> outFalseList;

  partial function PredicateFunc
    input ElementType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  (outTrueList, outFalseList) :=
  match(inList, inFunc, inArg1, inArg2, inTrueList, inFalseList)
    local
      ElementType e;
      list<ElementType> rest_e, tl, fl;
      Boolean pred;

    case ({}, _, _, _, tl, fl)
      then (listReverse(tl), listReverse(fl));

    case (e :: rest_e, _, _, _, tl, fl)
      equation
        pred = inFunc(e, inArg1, inArg2);
        (tl, fl) = consOnBool(pred, e, tl, fl);
        (tl, fl) = split2OnTrue_tail(rest_e, inFunc, inArg1, inArg2, tl, fl);
      then
        (tl, fl);
  end match;
end split2OnTrue_tail;

public function splitOnFirstMatch
  "Splits a list when the given function first finds a matching element.
     Example: splitOnFirstMatch({1, 2, 3, 4, 5}, isThree) => ({1, 2}, {3, 4, 5})"
  input list<ElementType> inList;
  input CompFunc inFunc;
  output list<ElementType> outList1;
  output list<ElementType> outList2;

  partial function CompFunc
    input ElementType inElement;
  end CompFunc;
algorithm
  (outList1, outList2) := matchcontinue(inList, inFunc)
    local
      list<ElementType> l1, l2;

    case (_, _)
      equation
        (l1, l2) = splitOnFirstMatch_tail(inList, inFunc, {});
      then
        (l1, l2);

    else (inList, {});
  end matchcontinue;
end splitOnFirstMatch;

public function splitOnFirstMatch_tail
  "Tail recursive implementation of splitOnFirstMatch."
  input list<ElementType> inList;
  input CompFunc inFunc;
  input list<ElementType> inAccumList1;
  output list<ElementType> outList1;
  output list<ElementType> outList2;

  partial function CompFunc
    input ElementType inElement;
  end CompFunc;
algorithm
  (outList1, outList2) := matchcontinue(inList, inFunc, inAccumList1)
    local
      ElementType e;
      list<ElementType> rest, l1, l2;

    case (e :: _, _, _)
      equation
        inFunc(e);
      then
        (listReverse(inAccumList1), inList);

    case (e :: rest, _, _)
      equation
        (l1, l2) = splitOnFirstMatch_tail(rest, inFunc, e :: inAccumList1);
      then
        (l1, l2);

  end matchcontinue;
end splitOnFirstMatch_tail;

public function splitFirst
  "Returns the first element of a list and the rest of the list. Fails if the
   list is empty."
  input list<ElementType> inList;
  output ElementType outFirst;
  output list<ElementType> outRest;
algorithm
  outFirst :: outRest := inList;
end splitFirst;

public function splitFirstOption
  "Returns the first element of a list as an option, and the rest of the list.
   Returns NONE and {} if the list is empty."
  input list<ElementType> inList;
  output Option<ElementType> outFirst;
  output list<ElementType> outRest;
algorithm
  (outFirst, outRest) := match(inList)
    local
      ElementType el;
      list<ElementType> rest;

    case (el :: rest) then (SOME(el), rest);
    else (NONE(), {});

  end match;
end splitFirstOption;

public function splitLast
  "Returns the last element of a list and a list of all previous elements. If
   the list is the empty list, the function fails.
     Example: splitLast({3, 5, 7, 11, 13}) => (13, {3, 5, 7, 11})"
  input list<ElementType> inList;
  output ElementType outLast;
  output list<ElementType> outRest;
algorithm
  (outLast, outRest) := splitLast_tail(inList, {});
end splitLast;

public function splitLast_tail
  "Tail recursive implementation of splitLast."
  input list<ElementType> inList;
  input list<ElementType> inAccum;
  output ElementType outLast;
  output list<ElementType> outRest;
algorithm
  (outLast, outRest) := match(inList, inAccum)
    local
      ElementType e;
      list<ElementType> rest;

    case ({e}, _) then (e, listReverse(inAccum));

    case (e :: rest, _)
      equation
        (e, rest) = splitLast_tail(rest, e :: inAccum);
      then
        (e, rest);
  end match;
end splitLast_tail;

public function splitEqualParts
  "Splits a list into n equally sized parts.
     Example: splitEqualParts({1, 2, 3, 4, 5, 6, 7, 8}, 4) =>
              {{1, 2}, {3, 4}, {5, 6}, {7, 8}}"
  input list<ElementType> inList;
  input Integer inParts;
  output list<list<ElementType>> outParts;
algorithm
  outParts := matchcontinue(inList, inParts)
    local
      Integer length, partsize;

    case (_, 0) then {};
    case (_, _)
      equation
        length = listLength(inList);
        0 = intMod(length, inParts);
        partsize = intDiv(length, inParts);
      then
        partition(inList, partsize);

    else
      equation
        true = intMod(listLength(inList), inParts) > 0;
        print("- List.splitEqualParts: split into non-integer size not possible.\n");
      then
        fail();
  end matchcontinue;
end splitEqualParts;

public function splitOnBoolList
  "Splits a list into two sublists depending on a second list of bools."
  input list<ElementType> inList;
  input list<Boolean> inBools;
  output list<ElementType> outTrueList;
  output list<ElementType> outFalseList;
algorithm
  (outTrueList, outFalseList) := splitOnBoolList_tail(inList, inBools, {}, {});
end splitOnBoolList;

public function splitOnBoolList_tail
  "Tail recursive implementation of splitOnBoolList."
  input list<ElementType> inList;
  input list<Boolean> inBools;
  input list<ElementType> inTrueAccum;
  input list<ElementType> inFalseAccum;
  output list<ElementType> outTrueList;
  output list<ElementType> outFalseList;
algorithm
  (outTrueList, outFalseList) :=
  match(inList, inBools, inTrueAccum, inFalseAccum)
    local
      ElementType e;
      list<ElementType> rest, fl, tl;
      list<Boolean> brest;

    case ({}, {}, _, _)
      then (listReverse(inTrueAccum), listReverse(inFalseAccum));

    case (e :: rest, true :: brest, _, _)
      equation
        (tl, fl) = splitOnBoolList_tail(rest, brest, e :: inTrueAccum, inFalseAccum);
      then
        (tl, fl);

    case (e :: rest, false :: brest, _, _)
      equation
        (tl, fl) = splitOnBoolList_tail(rest, brest, inTrueAccum, e :: inFalseAccum);
      then
        (tl, fl);

  end match;
end splitOnBoolList_tail;

public function partition
  "Partitions a list of elements into sublists of length n.
     Example: partition({1, 2, 3, 4, 5}, 2) => {{1, 2}, {3, 4}, {5}}"
  input list<ElementType> inList;
  input Integer inPartitionLength;
  output list<list<ElementType>> outPartitions;
algorithm
  outPartitions := matchcontinue(inList, inPartitionLength)
    local
      list<ElementType> rest, pt;
      list<list<ElementType>> res;

    case ({}, _) then {};
    case (_, _)
      equation
        true = inPartitionLength > listLength(inList);
      then
        {inList};

    else
      equation
        (pt, rest) = split(inList, inPartitionLength);
        res = partition(rest, inPartitionLength);
      then
        pt :: res;

  end matchcontinue;
end partition;

public function sublist
  "Returns a sublist determined by an offset and length.
     Example: sublist({1,2,3,4,5}, 2, 3) => {2,3,4}"
  input list<ElementType> inList;
  input Integer inOffset;
  input Integer inLength;
  output list<ElementType> outList;
algorithm
  outList := sublist_tail(inList, inOffset, inLength, {});
end sublist;

public function sublist_tail
  "Tail recursive implementation of sublist."
  input list<ElementType> inList;
  input Integer inOffset;
  input Integer inLength;
  input list<ElementType> accumList;
  output list<ElementType> outList;
algorithm
  outList := matchcontinue(inList, inOffset, inLength, accumList)
    local
      ElementType e;
      list<ElementType> rest_e;

    case ({}, _, _, _) then listReverse(accumList);
    case (_, _, 0, _) then listReverse(accumList);
    case (e :: rest_e, _, _, _)
      equation
        (inOffset > 1) = true;
        rest_e = sublist_tail(rest_e, inOffset - 1, inLength, accumList);
      then
        rest_e;
    case (e :: rest_e, _, _, _)
      equation
        (inLength > 0) = true;
        rest_e = sublist_tail(rest_e, 1, inLength - 1, accumList);
      then
        e :: rest_e;
  end matchcontinue;
end sublist_tail;

public function productMap
  "Given two lists and a function, forms the cartesian product of the lists and
   applies the function to each resulting pair.
     Example: productMap({1, 2}, {3, 4}, intMul) = {1*3, 1*4, 2*3, 2*4}"
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  output list<ElementOutType> outResult;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    output ElementOutType outResult;
  end MapFunc;
protected
  list<ElementType1> list1;
  list<ElementType2> list2;
algorithm
  list1 := listReverse(inList1);
  list2 := listReverse(inList2);
  outResult := productMap_tail(list1, list2, inMapFunc, {});
end productMap;

protected function productMap_tail
  "Tail-recursive implementation of productMap."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outResult;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    output ElementOutType outResult;
  end MapFunc;
algorithm
  outResult := match(inList1, inList2, inMapFunc, inAccumList)
    local
      ElementType1 e;
      list<ElementType1> rest;
      list<ElementOutType> result;

    case ({}, _, _, _) then inAccumList;

    case (e :: rest, _, _, _)
      equation
        result = map1r_tail(inList2, inMapFunc, e, inAccumList);
        result = productMap_tail(rest, inList2, inMapFunc, result);
      then
        result;

  end match;
end productMap_tail;

public function product
  "Given 2 lists, generate the product of them.
     Example:
       list1 = {{1}, {2}}, list2 = {{1}, {3}, {3}}
       result = {{1, 1}, {1, 2}, {1, 3}, {2, 1}, {2, 2}, {2, 3}}"
  input list<list<ElementType>> inList1;
  input list<list<ElementType>> inList2;
  output list<list<ElementType>> outProduct;
algorithm
  outProduct := product_impl(inList1, inList2, {});
end product;

public function product_impl
  "Implementation of product."
  input list<list<ElementType>> inList1;
  input list<list<ElementType>> inList2;
  input list<list<ElementType>> inAccum;
  output list<list<ElementType>> outProduct;
algorithm
  outProduct := matchcontinue(inList1, inList2, inAccum)
    local
      list<ElementType> head;
      list<list<ElementType>> rest, res1, res2, res;

    case ({head}, {}, _) then map(head, create);

    case ({}, _, _) then inAccum;

    case (head :: rest, _, _)
      equation
        res1 = map1(inList2, listAppend, head);
        res2 = product_impl(rest, inList2, res1);
        res = listAppend(res1, res2);
        res = listAppend(inAccum, res);
      then
        res;

  end matchcontinue;
end product_impl;

public function transposeList
  "Transposes a list of lists. Example:
     transposeList({{1, 2, 3}, {4, 5, 6}}) => {{1, 4}, {2, 5}, {3, 6}}"
  input list<list<ElementType>> inList;
  output list<list<ElementType>> outList;
algorithm
  outList := transposeList_tail(inList, {});
end transposeList;

protected function transposeList_tail
  "Tail recursive implementation of transposeList."
  input list<list<ElementType>> inList;
  input list<list<ElementType>> inAccum;
  output list<list<ElementType>> outList;
algorithm
  outList := match(inList, inAccum)
    local
      list<ElementType> firstl;
      list<list<ElementType>> restl;

    case ({}, _) then listReverse(inAccum);
    case ({} :: _, _) then listReverse(inAccum);
    else
      equation
        (firstl, restl) = map_2(inList, splitFirst);
      then
        transposeList_tail(restl, firstl :: inAccum);

  end match;
end transposeList_tail;

public function setEqualOnTrue
  "Takes two lists and a comparison function over two elements of the lists.
   It returns true if the two sets are equal, false otherwise."
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  input CompFunc inCompFunc;
  output Boolean outIsEqual;

  partial function CompFunc
    input ElementType inElement1;
    input ElementType inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outIsEqual := matchcontinue(inList1, inList2, inCompFunc)
    local
      list<ElementType> lst;
      Integer lst_size;

    case (_, _, _)
      equation
        lst = intersectionOnTrue(inList1, inList2, inCompFunc);
        lst_size = listLength(lst);
        true = intEq(lst_size, listLength(inList1));
        true = intEq(lst_size, listLength(inList2));
      then
        true;

    else false;
  end matchcontinue;
end setEqualOnTrue;

public function intersectionIntN
  "Provides same functionality as listIntersection, but for integer values
   between 1 and N. The complexity in this case is O(n)."
  input list<Integer> inList1;
  input list<Integer> inList2;
  input Integer inN;
  output list<Integer> outResult;
algorithm
  outResult := matchcontinue(inList1,inList2,inN)
    local
      array<Integer> a;
    case (_,_,_)
      equation
        true = intGt(inN,0);
        a = arrayCreate(inN, 0);
        a = addPos(inList1, a, 1);
        a = addPos(inList2, a, 1);
      then
        intersectionIntVec(a, inN, {});
    else then {};
 end matchcontinue;
end intersectionIntN;

protected function intersectionIntVec
  "Helper function to intersectionIntN."
  input array<Integer> inArray;
  input Integer inIndex;
  input list<Integer> iAcc;
  output list<Integer> outResult;
algorithm
  outResult := match(inArray, inIndex, iAcc)
    local
      list<Integer> acc;

    case(_, 0, _)
      then
        iAcc;

    case(_, _, _)
      equation
        acc = consOnTrue(intEq(inArray[inIndex],2),inIndex,iAcc);
      then
        intersectionIntVec(inArray, inIndex - 1, acc);
  end match;
end intersectionIntVec;

protected function addPos
  "Helper function to intersectionIntN."
  input list<Integer> inList;
  input array<Integer> inArray;
  input Integer inIndex;
  output array<Integer> outArray;
algorithm
  outArray := matchcontinue(inList, inArray, inIndex)
    local
      Integer i;
      list<Integer> irest;
      array<Integer> arr;

    case({}, _, _) then inArray;

    case(i :: irest, _, _)
      equation
        arr = arrayUpdate(inArray, i, intAdd(inArray[i],inIndex));
        arr = addPos(irest, inArray, inIndex);
      then
        arr;

    case(i :: _, _, _)
      equation
        failure(_ = arrayUpdate(inArray, i, intAdd(inArray[i],inIndex)));
        print("Internal error in List.addPos, index = " +& intString(i) +&
          " but array size is " +& intString(arrayLength(inArray)) +& "\n");
      then
        fail();
  end matchcontinue;
end addPos;

public function intersectionOnTrue
  "Takes two lists and a comparison function over two elements of the lists. It
   returns the intersection of the two lists, using the comparison function
   passed as argument to determine identity between two elements.
     Example:
       intersectionOnTrue({1, 4, 2}, {5, 2, 4, 6}, intEq) => {4, 2}"
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  input CompFunc inCompFunc;
  output list<ElementType> outIntersection;

  partial function CompFunc
    input ElementType inElement1;
    input ElementType inElement2;
     output Boolean outIsEqual;
  end CompFunc;
algorithm
  outIntersection := matchcontinue(inList1, inList2, inCompFunc)
    local
      ElementType e;
      list<ElementType> rest;

    case ({}, _, _) then {};
    case (e :: rest, _, _)
      equation
        _ = getMemberOnTrue(e, inList2, inCompFunc);
        rest = intersectionOnTrue(rest, inList2, inCompFunc);
      then
        e :: rest;

    case (e :: rest, _, _)
      then intersectionOnTrue(rest, inList2, inCompFunc);

  end matchcontinue;
end intersectionOnTrue;

public function intersection1OnTrue
  "Takes two lists and a comparison function over two elements of the lists. It
   returns the intersection of the two lists, using the comparison function
   passed as argument to determine identity between two elements. This function
   also returns a list of the elements from list 1 which is not in list 2 and a
   list of the elements from list 2 which is not in list 1."
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  input CompFunc inCompFunc;
  output list<ElementType> outIntersection;
  output list<ElementType> outList1Rest;
  output list<ElementType> outList2Rest;

  partial function CompFunc
    input ElementType inElement1;
    input ElementType inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  (outIntersection, outList1Rest) :=
    intersection1OnTrue_help(inList1, inList2, inCompFunc);
  outList2Rest := setDifferenceOnTrue(inList2, outIntersection, inCompFunc);
end intersection1OnTrue;

protected function intersection1OnTrue_help
  "Helper function to intersection1OnTrue."
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  input CompFunc inCompFunc;
  output list<ElementType> outIntersection;
  output list<ElementType> outList1Rest;

  partial function CompFunc
    input ElementType inElement1;
    input ElementType inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  (outIntersection, outList1Rest) := matchcontinue(inList1, inList2, inCompFunc)
    local
      ElementType e;
      list<ElementType> rest, rest1;

    case ({}, _, _) then ({}, {});

    case (e :: rest, _, _)
      equation
        _ = getMemberOnTrue(e, inList2, inCompFunc);
        (rest, rest1) = intersection1OnTrue_help(rest, inList2, inCompFunc);
      then
        (e :: rest, rest1);

    case (e :: rest, _, _)
      equation
        (rest, rest1) = intersection1OnTrue_help(rest, inList2, inCompFunc);
      then
        (rest, e :: rest1);
  end matchcontinue;
end intersection1OnTrue_help;

public function setDifferenceIntN
  "Provides same functionality as setDifference, but for integer values
   between 1 and N. The complexity in this case is O(n)"
  input list<Integer> inList1;
  input list<Integer> inList2;
  input Integer inN;
  output list<Integer> outDifference;
algorithm
  outDifference := matchcontinue(inList1,inList2,inN)
    local
      array<Integer> a;
    case (_,_,_)
      equation
        true = intGt(inN,0);
        a = arrayCreate(inN, 0);
        a = addPos(inList1, a, 1);
        a = addPos(inList2, a, 1);
      then
        setDifferenceIntVec(a, inN, {});
    else then {};
 end matchcontinue;
end setDifferenceIntN;

protected function setDifferenceIntVec
  "Helper function to intersectionIntN."
  input array<Integer> inArray;
  input Integer inIndex;
  input list<Integer> iAcc;
  output list<Integer> outDifference;
algorithm
  outDifference := match(inArray, inIndex, iAcc)
    local
      list<Integer> acc;

    case(_, 0, _)
      then
        iAcc;

    case(_, _, _)
      equation
        acc = consOnTrue(intEq(inArray[inIndex],1),inIndex,iAcc);
      then
        setDifferenceIntVec(inArray, inIndex - 1, acc);
  end match;
end setDifferenceIntVec;

public function setDifferenceOnTrue
  "Takes two lists and a comparison function over two elements of the lists. It
   returns the set difference of the two lists A-B, using the comparison
   function passed as argument to determine identity between two elements.
     Example:
       setDifferenceOnTrue({1, 2, 3}, {1, 3}, intEq) => {2}"
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  input CompFunc inCompFunc;
  output list<ElementType> outDifference;

  partial function CompFunc
    input ElementType inElement1;
    input ElementType inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outDifference := match (inList1, inList2, inCompFunc)
    local
      ElementType e;
      list<ElementType> rest, rest1;

    // Empty - B = Empty
    case ({}, _, _) then {};

    case (_, {}, _) then inList1;

    case (_, e :: rest, _)
      equation
        (rest1, _) = deleteMemberOnTrue(e, inList1, inCompFunc);
      then
        setDifferenceOnTrue(rest1, rest, inCompFunc);

  end match;
end setDifferenceOnTrue;

public function setDifference
  "Takes two lists and returns the set difference of two lists A - B.
     Example:
       setDifferenceOnTrue({1, 2, 3}, {1, 3}, intEq) => {2}"
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  output list<ElementType> outDifference;
algorithm
  outDifference := matchcontinue(inList1, inList2)
    local
      ElementType e;
      list<ElementType> rest, rest1;

    case ({}, _) then {};
    case (_, {}) then inList1;
    case (_, e :: rest)
      equation
        rest1 = deleteMember(inList1, e);
      then
        setDifference(rest1, rest);

    else
      equation
        print("- List.setDifference failed\n");
      then
        fail();

  end matchcontinue;
end setDifference;

public function unionIntN
  "Provides same functionality as listUnion, but for integer values between 1
   and N. The complexity in this case is O(n)"
  input list<Integer> inList1;
  input list<Integer> inList2;
  input Integer inN;
  output list<Integer> outUnion;
algorithm
  outUnion := matchcontinue(inList1,inList2,inN)
    local
      array<Integer> a;
    case (_,_,_)
      equation
        true = intGt(inN,0);
        a = arrayCreate(inN, 0);
        a = addPos(inList1, a, 1);
        a = addPos(inList2, a, 1);
      then
        unionIntVec(a, inN, {});
    else then {};
 end matchcontinue;
end unionIntN;

protected function unionIntVec
  "Helper function to listIntersectionIntN."
  input array<Integer> inArray;
  input Integer inIndex;
  input list<Integer> iAcc;
  output list<Integer> outUnion;
algorithm
  outUnion := match(inArray, inIndex, iAcc)
    local
      list<Integer> acc;

    case(_, 0, _)
      then
        iAcc;

    case(_, _, _)
      equation
        acc = consOnTrue(intGt(inArray[inIndex],0),inIndex,iAcc);
      then
        unionIntVec(inArray, inIndex - 1, acc);
  end match;
end unionIntVec;

public function unionElt
  "Takes a value and a list of values and inserts the value into the list if it
   is not already in the list. If it is in the list it is not inserted.
    Example:
      unionElt(1, {2, 3}) => {1, 2, 3}
      unionElt(0, {0, 1, 2}) => {0, 1, 2}"
  input ElementType inElement;
  input list<ElementType> inList;
  output list<ElementType> outList;
algorithm
  outList := consOnTrue(not listMember(inElement, inList), inElement, inList);
end unionElt;

public function unionEltOnTrue
  "Works as unionElt, but with a compare function."
  input ElementType inElement;
  input list<ElementType> inList;
  input CompFunc inCompFunc;
  output list<ElementType> outList;

  partial function CompFunc
    input ElementType inElement1;
    input ElementType inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outList := consOnTrue(not isMemberOnTrue(inElement, inList, inCompFunc),
    inElement, inList);
end unionEltOnTrue;

public function union
  "Takes two lists and returns the union of the two lists, i.e. a list of all
   elements combined without duplicates. Example:
     union({0, 1}, {2, 1}) => {0, 1, 2}"
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  output list<ElementType> outUnion;
algorithm
  outUnion := union_tail(inList1, inList2, {});
end union;

public function union_tail
  "Tail recursive implementation of union."
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  input list<ElementType> inAccumList;
  output list<ElementType> outUnion;
algorithm
  outUnion := match(inList1, inList2, inAccumList)
    local
      ElementType e;
      list<ElementType> rest, accum;

    case ({}, {}, _) then listReverse(inAccumList);
    case ({}, e :: rest, _)
      equation
        accum = unionElt(e, inAccumList);
      then
        union_tail({}, rest, accum);

    case (e :: rest, _, _)
      equation
        accum = unionElt(e, inAccumList);
      then
        union_tail(rest, inList2, accum);

  end match;
end union_tail;


public function unionAppendonUnion
  "As union but this function assume that List1 is already union.
   i.e. a list of all elements combined without duplicates.
   Example:
     union({0, 1}, {2, 1}) => {0, 1, 2}"
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  output list<ElementType> outUnion;
algorithm
  outUnion := unionAppendonUnion_tail(inList2, inList1);
end unionAppendonUnion;

public function unionAppendonUnion_tail
  "Tail recursive implementation of unionAppendNonUnion."
  input list<ElementType> inList2;
  input list<ElementType> inAccumList;
  output list<ElementType> outUnion;
algorithm
  outUnion := match(inList2, inAccumList)
    local
      ElementType e;
      list<ElementType> rest, accum;

    case ({}, _) then listReverse(inAccumList);
    case (e :: rest, _)
      equation
        accum = unionElt(e, inAccumList);
      then
        unionAppendonUnion_tail(rest, accum);
  end match;
end unionAppendonUnion_tail;

public function unionOnTrue
  "Takes two lists an a comparison function over two elements of the lists. It
   returns the union of the two lists, using the comparison function passed as
   argument to determine identity between two elements. Example:
     unionOnTrue({1, 2}, {2, 3}, intEq) => {1, 2, 3}"
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  input CompFunc inCompFunc;
  output list<ElementType> outUnion;

  partial function CompFunc
    input ElementType inList1;
    input ElementType inList2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outUnion := unionOnTrue_tail(inList1, inList2, inCompFunc, {});
end unionOnTrue;

protected function unionOnTrue_tail
  "Tail recursive implementation of unionOnTrue."
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  input CompFunc inCompFunc;
  input list<ElementType> inAccumList;
  output list<ElementType> outUnion;

  partial function CompFunc
    input ElementType inList1;
    input ElementType inList2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outUnion := match(inList1, inList2, inCompFunc, inAccumList)
    local
      ElementType e;
      list<ElementType> rest,  accum;

    case ({}, {}, _, _) then listReverse(inAccumList);
    case ({}, e :: rest, _, _)
      equation
        accum = unionEltOnTrue(e, inAccumList, inCompFunc);
      then
        unionOnTrue_tail({}, rest, inCompFunc, accum);

    case (e :: rest, _, _, _)
      equation
        accum = unionEltOnTrue(e, inAccumList, inCompFunc);
      then
        unionOnTrue_tail(rest, inList2, inCompFunc, accum);

  end match;
end unionOnTrue_tail;

public function unionList
  "Takes a list of lists and returns the union of the sublists.
     Example: unionList({1}, {1, 2}, {3, 4}, {5}}) => {1, 2, 3, 4, 5}"
  input list<list<ElementType>> inList;
  output list<ElementType> outUnion;
algorithm
  outUnion := match(inList)
    case {} then {};
    else reduce(inList, union);
  end match;
end unionList;

public function unionOnTrueList
  "Takes a list of lists and a comparison function over two elements of the
   lists. It returns the union of all sublists using the comparison function
   for identity.
     Example:
       unionOnTrueList({{1}, {1, 2}, {3, 4}}, intEq) => {1, 2, 3, 4}"
  input list<list<ElementType>> inList;
  input CompFunc inCompFunc;
  output list<ElementType> outUnion;

  partial function CompFunc
    input ElementType inElement1;
    input ElementType inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outUnion := match(inList, inCompFunc)
    case ({}, _) then {};
    else reduce1(inList, unionOnTrue, inCompFunc);
  end match;
end unionOnTrueList;

public function map
  "Takes a list and a function, and creates a new list by applying the function
   to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(map_tail(inList, inFunc, {}));
end map;

public function mapReverse
  "Takes a list and a function, and creates a new list by applying the function
   to each element of the list. The created list will be reversed compared to
   the given list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := map_tail(inList, inFunc, {});
end mapReverse;

protected function map_tail
  "Tail-recursive implementation of map."
  input  list<ElementInType> inList;
  input  MapFunc inFunc;
  input  list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<ElementInType> rest;
      list<ElementOutType> accum;

    case ({}, _, _) then inAccumList;

    case (head :: rest, _, _)
      equation
        new_head = inFunc(head);
        accum = map_tail(rest, inFunc, new_head :: inAccumList);
      then
        accum;
  end match;
end map_tail;

public function map_2
  "Takes a list and a function, and creates two new lists by applying the
   function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;

  partial function MapFunc
    input ElementInType inElement;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
  end MapFunc;
algorithm
  (outList1, outList2) := map_2_tail(inList, inFunc, {}, {});
  outList1 := listReverse(outList1);
  outList2 := listReverse(outList2);
end map_2;

protected function map_2_tail
  "Tail-recursive implementation of map_2"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input list<ElementOutType1> inAccumList1;
  input list<ElementOutType2> inAccumList2;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;

  partial function MapFunc
    input ElementInType inElement;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
  end MapFunc;
algorithm
  (outList1, outList2) :=
  match(inList, inFunc, inAccumList1, inAccumList2)
    local
      ElementInType head;
      ElementOutType1 new_head1;
      ElementOutType2 new_head2;
      list<ElementInType> rest;
      list<ElementOutType1> accum1;
      list<ElementOutType2> accum2;

    case ({}, _, _, _) then (inAccumList1, inAccumList2);

    case (head :: rest, _, _, _)
      equation
        (new_head1, new_head2) = inFunc(head);
        (accum1, accum2) = map_2_tail(rest, inFunc,
          new_head1 :: inAccumList1, new_head2 :: inAccumList2);
      then
        (accum1, accum2);
  end match;
end map_2_tail;

public function map_3
  "Takes a list and a function, and creates three new lists by applying the
   function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;
  output list<ElementOutType3> outList3;

  partial function MapFunc
    input ElementInType inElement;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
    output ElementOutType3 outElement3;
  end MapFunc;
algorithm
  (outList1, outList2, outList3) := map_3_tail(inList, inFunc, {}, {}, {});
  outList1 := listReverse(outList1);
  outList2 := listReverse(outList2);
  outList3 := listReverse(outList3);
end map_3;

protected function map_3_tail
  "Tail-recursive implementation of map_3"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input list<ElementOutType1> inAccumList1;
  input list<ElementOutType2> inAccumList2;
  input list<ElementOutType3> inAccumList3;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;
  output list<ElementOutType3> outList3;

  partial function MapFunc
    input ElementInType inElement;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
    output ElementOutType3 outElement3;
  end MapFunc;
algorithm
  (outList1, outList2, outList3) :=
  match(inList, inFunc, inAccumList1, inAccumList2, inAccumList3)
    local
      ElementInType head;
      ElementOutType1 new_head1;
      ElementOutType2 new_head2;
      ElementOutType3 new_head3;
      list<ElementInType> rest;
      list<ElementOutType1> accum1;
      list<ElementOutType2> accum2;
      list<ElementOutType3> accum3;

    case ({}, _, _, _, _) then (inAccumList1, inAccumList2, inAccumList3);

    case (head :: rest, _, _, _, _)
      equation
        (new_head1, new_head2, new_head3) = inFunc(head);
        (accum1, accum2, accum3) = map_3_tail(rest, inFunc,
          new_head1 :: inAccumList1, new_head2 :: inAccumList2, new_head3 :: inAccumList3);
      then
        (accum1, accum2, accum3);
  end match;
end map_3_tail;

public function mapOption
  "The same as map(map(inList, getOption), inMapFunc), but is more efficient and
   it strips out NONE() instead of failing on them."
  input list<Option<ElementInType>> inList;
  input MapFunc inFunc;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(mapOption_tail(inList, inFunc, {}));
end mapOption;

protected function mapOption_tail
  "Tail-recursive implementation of mapOption."
  input list<Option<ElementInType>> inList;
  input MapFunc inFunc;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<Option<ElementInType>> rest;

    case ({}, _, _) then inAccumList;

    case (SOME(head) :: rest, _, _)
      equation
        new_head = inFunc(head);
      then
        mapOption_tail(rest, inFunc, new_head :: inAccumList);

    case (NONE() :: rest, _, _)
      then mapOption_tail(rest, inFunc, inAccumList);
  end match;
end mapOption_tail;

public function map1Option
  "The same as map1(map(inList, getOption), inMapFunc), but is more efficient and
   it strips out NONE() instead of failing on them."
  input list<Option<ElementInType>> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(map1Option_tail(inList, inFunc, inArg1, {}));
end map1Option;

protected function map1Option_tail
  "Tail-recursive implementation of map1Option."
  input list<Option<ElementInType>> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<Option<ElementInType>> rest;

    case ({}, _, _, _) then inAccumList;

    case (SOME(head) :: rest, _, _, _)
      equation
        new_head = inFunc(head, inArg1);
      then
        map1Option_tail(rest, inFunc, inArg1, new_head :: inAccumList);

    case (NONE() :: rest, _, _, _)
      then map1Option_tail(rest, inFunc, inArg1, inAccumList);
  end match;
end map1Option_tail;

public function map2Option
  "The same as map2(map(inList, getOption), inMapFunc), but is more efficient and
   it strips out NONE() instead of failing on them."
  input list<Option<ElementInType>> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType1 inArg2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(map2Option_tail(inList, inFunc, inArg1, inArg2, {}));
end map2Option;

protected function map2Option_tail
  "Tail-recursive implementation of map2Option."
  input list<Option<ElementInType>> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType1 inArg2;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType1 inArg2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inArg2, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<Option<ElementInType>> rest;

    case ({}, _, _, _, _) then inAccumList;

    case (SOME(head) :: rest, _, _, _, _)
      equation
        new_head = inFunc(head, inArg1, inArg2);
      then
        map2Option_tail(rest, inFunc, inArg1, inArg2, new_head :: inAccumList);

    case (NONE() :: rest, _, _, _, _)
      then map2Option_tail(rest, inFunc, inArg1, inArg2, inAccumList);
  
  end match;
end map2Option_tail;

public function map_0
  "Takes a list and a function which does not return a value. The function is
   probably a function with side effects, like print."
  input list<ElementInType> inList;
  input MapFunc inFunc;

  partial function MapFunc
    input ElementInType inElement;
  end MapFunc;
algorithm
  _ := match(inList, inFunc)
    local
      ElementInType head;
      list<ElementInType> rest;

    case ({}, _) then ();
    case (head :: rest, _)
      equation
        inFunc(head);
        map_0(rest, inFunc);
      then
        ();
  end match;
end map_0;

public function map1
  "Takes a list, a function and one extra argument, and creates a new list
   by applying the function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(map1_tail(inList, inFunc, inArg1, {}));
end map1;

public function map1Reverse
  "Takes a list, a function and one extra argument, and creates a new list
   by applying the function to each element of the list. The created list will
   be reversed compared to the given list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := map1_tail(inList, inFunc, inArg1, {});
end map1Reverse;

protected function map1_tail
  "Tail-recursive implementation of map1"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<ElementInType> rest;
      list<ElementOutType> accum;

    case ({}, _, _, _) then inAccumList;

    case (head :: rest, _, _, _)
      equation
        new_head = inFunc(head, inArg1);
        accum = map1_tail(rest, inFunc, inArg1, new_head :: inAccumList);
      then
        accum;
  end match;
end map1_tail;

public function map1r
  "Takes a list, a function and one extra argument, and creates a new list
   by applying the function to each element of the list. The given map
   function has it's arguments reversed compared to map1."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ArgType1 inArg1;
    input ElementInType inElement;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(map1r_tail(inList, inFunc, inArg1, {}));
end map1r;

public function map1r_tail
  "Tail-recursive implementation of map1r"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<ElementInType> rest;
      list<ElementOutType> accum;

    case ({}, _, _, _) then inAccumList;

    case (head :: rest, _, _, _)
      equation
        new_head = inFunc(inArg1, head);
        accum = map1r_tail(rest, inFunc, inArg1, new_head :: inAccumList);
      then
        accum;
  end match;
end map1r_tail;

public function map1_0
  "Takes a list, a function and one extra argument, and applies the functions to
   each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
  end MapFunc;
algorithm
  _ := match(inList, inFunc, inArg1)
    local
      ElementInType head;
      list<ElementInType> rest;

    case ({}, _, _) then ();
    case (head :: rest, _, _)
      equation
        inFunc(head, inArg1);
        map1_0(rest, inFunc, inArg1);
      then
        ();
  end match;
end map1_0;

public function map1_2
  "Takes a list, a function and one extra argument, and creates two new lists
   by applying the function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
  end MapFunc;
algorithm
  (outList1, outList2) := map1_2_tail(inList, inFunc, inArg1, {}, {});
  outList1 := listReverse(outList1);
  outList2 := listReverse(outList2);
end map1_2;

protected function map1_2_tail
  "Tail-recursive implementation of map1_2"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input list<ElementOutType1> inAccumList1;
  input list<ElementOutType2> inAccumList2;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
  end MapFunc;
algorithm
  (outList1, outList2) :=
  match(inList, inFunc, inArg1, inAccumList1, inAccumList2)
    local
      ElementInType head;
      ElementOutType1 new_head1;
      ElementOutType2 new_head2;
      list<ElementInType> rest;
      list<ElementOutType1> accum1;
      list<ElementOutType2> accum2;

    case ({}, _, _, _, _) then (inAccumList1, inAccumList2);

    case (head :: rest, _, _, _, _)
      equation
        (new_head1, new_head2) = inFunc(head, inArg1);
        (accum1, accum2) = map1_2_tail(rest, inFunc, inArg1,
          new_head1 :: inAccumList1, new_head2 :: inAccumList2);
      then
        (accum1, accum2);
  end match;
end map1_2_tail;

public function map1_3
  "Takes a list, a function and one extra argument, and creates three new
   lists by applying the function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;
  output list<ElementOutType3> outList3;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
    output ElementOutType3 outElement3;
  end MapFunc;
algorithm
  (outList1, outList2, outList3) := map1_3_tail(inList, inFunc, inArg1, {}, {}, {});
  outList1 := listReverse(outList1);
  outList2 := listReverse(outList2);
  outList3 := listReverse(outList3);
end map1_3;

protected function map1_3_tail
  "Tail-recursive implementation of map1_3"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input list<ElementOutType1> inAccumList1;
  input list<ElementOutType2> inAccumList2;
  input list<ElementOutType3> inAccumList3;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;
  output list<ElementOutType3> outList3;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
    output ElementOutType3 outElement3;
  end MapFunc;
algorithm
  (outList1, outList2, outList3) :=
  match(inList, inFunc, inArg1, inAccumList1, inAccumList2, inAccumList3)
    local
      ElementInType head;
      ElementOutType1 new_head1;
      ElementOutType2 new_head2;
      ElementOutType3 new_head3;
      list<ElementInType> rest;
      list<ElementOutType1> accum1;
      list<ElementOutType2> accum2;
      list<ElementOutType3> accum3;

    case ({}, _, _, _, _, _) then (inAccumList1, inAccumList2, inAccumList3);

    case (head :: rest, _, _, _, _, _)
      equation
        (new_head1, new_head2, new_head3) = inFunc(head, inArg1);
        (accum1, accum2, accum3) = map1_3_tail(rest, inFunc, inArg1,
          new_head1 :: inAccumList1, new_head2 :: inAccumList2,
          new_head3 :: inAccumList3);
      then
        (accum1, accum2, accum3);
  end match;
end map1_3_tail;

public function map2
  "Takes a list, a function and two extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(map2_tail(inList, inFunc, inArg1, inArg2, {}));
end map2;

public function map2Reverse
  "Takes a list, a function and two extra arguments, and creates a new list
   by applying the function to each element of the list. The created list will
   be reversed compared to the given list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := map2_tail(inList, inFunc, inArg1, inArg2, {});
end map2Reverse;

public function map2_tail
  "Tail-recursive implementation of map2"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inArg2, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<ElementInType> rest;
      list<ElementOutType> accum;

    case ({}, _, _, _, _) then inAccumList;

    case (head :: rest, _, _, _, _)
      equation
        new_head = inFunc(head, inArg1, inArg2);
        accum = map2_tail(rest, inFunc, inArg1, inArg2, new_head :: inAccumList);
      then
        accum;
  end match;
end map2_tail;

public function map2r
  "Takes a list, a function and two extra argument, and creates a new list
   by applying the function to each element of the list. The given map
   function has it's arguments reversed compared to map2."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ElementInType inElement;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(map2r_tail(inList, inFunc, inArg1, inArg2, {}));
end map2r;

protected function map2r_tail
  "Tail-recursive implementation of map2r"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inArg2, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<ElementInType> rest;
      list<ElementOutType> accum;

    case ({}, _, _, _, _) then inAccumList;

    case (head :: rest, _, _, _, _)
      equation
        new_head = inFunc(inArg1, inArg2, head);
        accum = map2r_tail(rest, inFunc, inArg1, inArg2, new_head :: inAccumList);
      then
        accum;
  end match;
end map2r_tail;

public function map2_0
  "Takes a list, a function and two extra argument, and applies the functions to
   each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
  end MapFunc;
algorithm
  _ := match(inList, inFunc, inArg1, inArg2)
    local
      ElementInType head;
      list<ElementInType> rest;

    case ({}, _, _, _) then ();
    case (head :: rest, _, _, _)
      equation
        inFunc(head, inArg1, inArg2);
        map2_0(rest, inFunc, inArg1, inArg2);
      then
        ();
  end match;
end map2_0;

public function map2_2
  "Takes a list, a function and two extra argument, and creates two new lists
   by applying the function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
  end MapFunc;
algorithm
  (outList1, outList2) := map2_2_tail(inList, inFunc, inArg1, inArg2, {}, {});
  outList1 := listReverse(outList1);
  outList2 := listReverse(outList2);
end map2_2;

protected function map2_2_tail
  "Tail-recursive implementation of map2_2"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input list<ElementOutType1> inAccumList1;
  input list<ElementOutType2> inAccumList2;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
  end MapFunc;
algorithm
  (outList1, outList2) :=
  match(inList, inFunc, inArg1, inArg2, inAccumList1, inAccumList2)
    local
      ElementInType head;
      ElementOutType1 new_head1;
      ElementOutType2 new_head2;
      list<ElementInType> rest;
      list<ElementOutType1> accum1;
      list<ElementOutType2> accum2;

    case ({}, _, _, _, _, _) then (inAccumList1, inAccumList2);

    case (head :: rest, _, _, _, _, _)
      equation
        (new_head1, new_head2) = inFunc(head, inArg1, inArg2);
        (accum1, accum2) = map2_2_tail(rest, inFunc, inArg1, inArg2,
          new_head1 :: inAccumList1, new_head2 :: inAccumList2);
      then
        (accum1, accum2);
  end match;
end map2_2_tail;

public function map3
  "Takes a list, a function and three extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(map3_tail(inList, inFunc, inArg1, inArg2, inArg3, {}));
end map3;

protected function map3_tail
  "Tail-recursive implementation of map3"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inArg2, inArg3, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<ElementInType> rest;
      list<ElementOutType> accum;

    case ({}, _, _, _, _, _) then inAccumList;

    case (head :: rest, _, _, _, _, _)
      equation
        new_head = inFunc(head, inArg1, inArg2, inArg3);
        accum = map3_tail(rest, inFunc, inArg1, inArg2, inArg3, new_head :: inAccumList);
      then
        accum;
  end match;
end map3_tail;

public function map3r
  "Takes a list, a function and three extra argument, and creates a new list
   by applying the function to each element of the list. The given map
   function has it's arguments reversed compared to map3."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ElementInType inElement;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(map3r_tail(inList, inFunc, inArg1, inArg2, inArg3, {}));
end map3r;

protected function map3r_tail
  "Tail-recursive implementation of map3r"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inArg2, inArg3, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<ElementInType> rest;
      list<ElementOutType> accum;

    case ({}, _, _, _, _, _) then inAccumList;

    case (head :: rest, _, _, _, _, _)
      equation
        new_head = inFunc(inArg1, inArg2, inArg3, head);
        accum = map3r_tail(rest, inFunc, inArg1, inArg2, inArg3, new_head :: inAccumList);
      then
        accum;
  end match;
end map3r_tail;

public function map3_0
  "Takes a list, a function and three extra argument, and applies the functions to
   each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
  end MapFunc;
algorithm
  _ := match(inList, inFunc, inArg1, inArg2, inArg3)
    local
      ElementInType head;
      list<ElementInType> rest;

    case ({}, _, _, _, _) then ();
    case (head :: rest, _, _, _, _)
      equation
        inFunc(head, inArg1, inArg2, inArg3);
        map3_0(rest, inFunc, inArg1, inArg2, inArg3);
      then
        ();
  end match;
end map3_0;

public function map3_2
  "Takes a list, a function and three extra argument, and creates two new lists
   by applying the function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
  end MapFunc;
algorithm
  (outList1, outList2) :=
    map3_2_tail(inList, inFunc, inArg1, inArg2, inArg3, {}, {});
  outList1 := listReverse(outList1);
  outList2 := listReverse(outList2);
end map3_2;

protected function map3_2_tail
  "Tail-recursive implementation of map3_2"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input list<ElementOutType1> inAccumList1;
  input list<ElementOutType2> inAccumList2;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
  end MapFunc;
algorithm
  (outList1, outList2) :=
  match(inList, inFunc, inArg1, inArg2, inArg3, inAccumList1, inAccumList2)
    local
      ElementInType head;
      ElementOutType1 new_head1;
      ElementOutType2 new_head2;
      list<ElementInType> rest;
      list<ElementOutType1> accum1;
      list<ElementOutType2> accum2;

    case ({}, _, _, _, _, _, _) then (inAccumList1, inAccumList2);

    case (head :: rest, _, _, _, _, _, _)
      equation
        (new_head1, new_head2) = inFunc(head, inArg1, inArg2, inArg3);
        (accum1, accum2) = map3_2_tail(rest, inFunc, inArg1, inArg2, inArg3,
          new_head1 :: inAccumList1, new_head2 :: inAccumList2);
      then
        (accum1, accum2);
  end match;
end map3_2_tail;

public function map4
  "Takes a list, a function and four extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ArgType4 inArg4;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(map4_tail(inList, inFunc, inArg1, inArg2, inArg3, inArg4, {}));
end map4;

protected function map4_tail
  "Tail-recursive implementation of map4"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ArgType4 inArg4;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inArg2, inArg3, inArg4, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<ElementInType> rest;
      list<ElementOutType> accum;

    case ({}, _, _, _, _, _, _) then inAccumList;

    case (head :: rest, _, _, _, _, _, _)
      equation
        new_head = inFunc(head, inArg1, inArg2, inArg3, inArg4);
        accum = map4_tail(rest, inFunc, inArg1, inArg2, inArg3, inArg4, new_head :: inAccumList);
      then
        accum;
  end match;
end map4_tail;

public function map4_0
  "Takes a list, a function and four extra argument, and applies the functions to
   each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ArgType4 inArg4;
  end MapFunc;
algorithm
  _ := match(inList, inFunc, inArg1, inArg2, inArg3, inArg4)
    local
      ElementInType head;
      list<ElementInType> rest;

    case ({}, _, _, _, _, _) then ();
    case (head :: rest, _, _, _, _, _)
      equation
        inFunc(head, inArg1, inArg2, inArg3, inArg4);
        map4_0(rest, inFunc, inArg1, inArg2, inArg3, inArg4);
      then
        ();
  end match;
end map4_0;

public function map4_2
  "Takes a list, a function and four extra argument, and creates two new lists
   by applying the function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ArgType4 inArg4;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
  end MapFunc;
algorithm
  (outList1, outList2) :=
    map4_2_tail(inList, inFunc, inArg1, inArg2, inArg3, inArg4, {}, {});
  outList1 := listReverse(outList1);
  outList2 := listReverse(outList2);
end map4_2;

protected function map4_2_tail
  "Tail-recursive implementation of map4_2"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;
  input list<ElementOutType1> inAccumList1;
  input list<ElementOutType2> inAccumList2;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ArgType4 inArg4;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
  end MapFunc;
algorithm
  (outList1, outList2) :=
  match(inList, inFunc, inArg1, inArg2, inArg3, inArg4, inAccumList1, inAccumList2)
    local
      ElementInType head;
      ElementOutType1 new_head1;
      ElementOutType2 new_head2;
      list<ElementInType> rest;
      list<ElementOutType1> accum1;
      list<ElementOutType2> accum2;

    case ({}, _, _, _, _, _, _, _) then (inAccumList1, inAccumList2);

    case (head :: rest, _, _, _, _, _, _, _)
      equation
        (new_head1, new_head2) = inFunc(head, inArg1, inArg2, inArg3, inArg4);
        (accum1, accum2) = map4_2_tail(rest, inFunc, inArg1, inArg2, inArg3,
          inArg4, new_head1 :: inAccumList1, new_head2 :: inAccumList2);
      then
        (accum1, accum2);
  end match;
end map4_2_tail;

public function map5
  "Takes a list, a function and five extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;
  input ArgType5 inArg5;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ArgType4 inArg4;
    input ArgType5 inArg5;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(map5_tail(inList, inFunc, inArg1, inArg2, inArg3, inArg4, inArg5, {}));
end map5;

protected function map5_tail
  "Tail-recursive implementation of map5"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;
  input ArgType5 inArg5;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ArgType4 inArg4;
    input ArgType5 inArg5;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inArg2, inArg3, inArg4, inArg5, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<ElementInType> rest;
      list<ElementOutType> accum;

    case ({}, _, _, _, _, _, _, _) then inAccumList;

    case (head :: rest, _, _, _, _, _, _, _)
      equation
        new_head = inFunc(head, inArg1, inArg2, inArg3, inArg4, inArg5);
        accum = map5_tail(rest, inFunc, inArg1, inArg2, inArg3, inArg4, inArg5, new_head :: inAccumList);
      then
        accum;
  end match;
end map5_tail;

public function map6
  "Takes a list, a function and six extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;
  input ArgType5 inArg5;
  input ArgType6 inArg6;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ArgType4 inArg4;
    input ArgType5 inArg5;
    input ArgType6 inArg6;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(map6_tail(inList, inFunc, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, {}));
end map6;

protected function map6_tail
  "Tail-recursive implementation of map6"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;
  input ArgType5 inArg5;
  input ArgType6 inArg6;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ArgType4 inArg4;
    input ArgType5 inArg5;
    input ArgType6 inArg6;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<ElementInType> rest;
      list<ElementOutType> accum;

    case ({}, _, _, _, _, _, _, _, _) then inAccumList;

    case (head :: rest, _, _, _, _, _, _, _, _)
      equation
        new_head = inFunc(head, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6);
        accum = map6_tail(rest, inFunc, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, new_head :: inAccumList);
      then
        accum;
  end match;
end map6_tail;

public function map7
  "Takes a list, a function and seven extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;
  input ArgType5 inArg5;
  input ArgType6 inArg6;
  input ArgType7 inArg7;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ArgType4 inArg4;
    input ArgType5 inArg5;
    input ArgType6 inArg6;
    input ArgType7 inArg7;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(map7_tail(inList, inFunc, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7, {}));
end map7;

protected function map7_tail
  "Tail-recursive implementation of map7"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;
  input ArgType5 inArg5;
  input ArgType6 inArg6;
  input ArgType7 inArg7;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ArgType4 inArg4;
    input ArgType5 inArg5;
    input ArgType6 inArg6;
    input ArgType7 inArg7;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<ElementInType> rest;
      list<ElementOutType> accum;

    case ({}, _, _, _, _, _, _, _, _, _) then inAccumList;

    case (head :: rest, _, _, _, _, _, _, _, _, _)
      equation
        new_head = inFunc(head, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7);
        accum = map7_tail(rest, inFunc, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7, new_head :: inAccumList);
      then
        accum;
  end match;
end map7_tail;

public function map8
  "Takes a list, a function and eight extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;
  input ArgType5 inArg5;
  input ArgType6 inArg6;
  input ArgType7 inArg7;
  input ArgType8 inArg8;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ArgType4 inArg4;
    input ArgType5 inArg5;
    input ArgType6 inArg6;
    input ArgType7 inArg7;
    input ArgType8 inArg8;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(map8_tail(inList, inFunc, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7, inArg8, {}));
end map8;

protected function map8_tail
  "Tail-recursive implementation of map8"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;
  input ArgType5 inArg5;
  input ArgType6 inArg6;
  input ArgType7 inArg7;
  input ArgType8 inArg8;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ArgType4 inArg4;
    input ArgType5 inArg5;
    input ArgType6 inArg6;
    input ArgType7 inArg7;
    input ArgType8 inArg8;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7, inArg8, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<ElementInType> rest;
      list<ElementOutType> accum;

    case ({}, _, _, _, _, _, _, _, _, _, _) then inAccumList;

    case (head :: rest, _, _, _, _, _, _, _, _, _, _)
      equation
        new_head = inFunc(head, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7, inArg8);
        accum = map8_tail(rest, inFunc, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7, inArg8, new_head :: inAccumList);
      then
        accum;
  end match;
end map8_tail;

public function map9
  "Takes a list, a function and eight extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;
  input ArgType5 inArg5;
  input ArgType6 inArg6;
  input ArgType7 inArg7;
  input ArgType8 inArg8;
  input ArgType9 inArg9;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ArgType4 inArg4;
    input ArgType5 inArg5;
    input ArgType6 inArg6;
    input ArgType7 inArg7;
    input ArgType8 inArg8;
    input ArgType9 inArg9;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(map9_tail(inList, inFunc, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7, inArg8, inArg9, {}));
end map9;

protected function map9_tail
  "Tail-recursive implementation of map8"
  input list<ElementInType> inList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;
  input ArgType5 inArg5;
  input ArgType6 inArg6;
  input ArgType7 inArg7;
  input ArgType8 inArg8;
  input ArgType9 inArg9;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input ArgType4 inArg4;
    input ArgType5 inArg5;
    input ArgType6 inArg6;
    input ArgType7 inArg7;
    input ArgType8 inArg8;
    input ArgType9 inArg9;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7, inArg8, inArg9, inAccumList)
    local
      ElementInType head;
      ElementOutType new_head;
      list<ElementInType> rest;
      list<ElementOutType> accum;

    case ({}, _, _, _, _, _, _, _, _, _, _, _) then inAccumList;

    case (head :: rest, _, _, _, _, _, _, _, _, _, _, _)
      equation
        new_head = inFunc(head, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7, inArg8, inArg9);
        accum = map9_tail(rest, inFunc, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7, inArg8, inArg9, new_head :: inAccumList);
      then
        accum;
  end match;
end map9_tail;

public function mapFlat
  "Takes a list and a function that maps elements to lists, which are flattened
   into one list. Example (fill2(n) = {n, n}):
     mapFlat({1, 2, 3}, fill2) => {1, 1, 2, 2, 3, 3}"
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    output list<ElementOutType> outList;
  end MapFunc;
algorithm
  outList := listReverse(mapFlat_tail(inList, inMapFunc, {}));
end mapFlat;

public function mapFlatReverse
  "Takes a list and a function that maps elements to lists, which are flattened
   into one list. Returns the values in reverse order as the input.
     Example (fill2(n) = {n, n}):
       mapFlat({1, 2, 3}, fill2) => {3, 3, 2, 2, 1, 1}"
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    output list<ElementOutType> outList;
  end MapFunc;
algorithm
  outList := mapFlat_tail(inList, inMapFunc, {});
end mapFlatReverse;

public function mapFlat_tail
  "Tail recursive implementation of mapFlat."
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input list<ElementOutType> inAccum;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    output list<ElementOutType> outList;
  end MapFunc;
algorithm
  outList := match(inList, inMapFunc, inAccum)
    local
      ElementInType e;
      list<ElementInType> rest;
      list<ElementOutType> res;

    case ({}, _, _) then inAccum;

    case (e :: rest, _, _)
      equation
        res = inMapFunc(e);
        res = listAppend(res, inAccum);
      then
        mapFlat_tail(rest, inMapFunc, res);

  end match;
end mapFlat_tail;

public function map1Flat
  "Takes a list and a function that maps elements to lists, which are flattened
   into one list. This function also takes an extra arguments that are passed
   to the mapping function."
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output list<ElementOutType> outList;
  end MapFunc;
algorithm
  outList := map1Flat_tail(inList, inMapFunc, inArg1, {});
end map1Flat;

public function map1Flat_tail
  "Tail recursive implementation of map1Flat."
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  input list<ElementOutType> inAccum;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output list<ElementOutType> outList;
  end MapFunc;
algorithm
  outList := match(inList, inMapFunc, inArg1, inAccum)
    local
      ElementInType e;
      list<ElementInType> rest;
      list<ElementOutType> res;

    case ({}, _, _, _) then listReverse(inAccum);

    case (e :: rest, _, _, _)
      equation
        res = inMapFunc(e, inArg1);
        res = listAppend(res, inAccum);
      then
        map1Flat_tail(rest, inMapFunc, inArg1, res);

  end match;
end map1Flat_tail;

public function map2Flat
  "Takes a list and a function that maps elements to lists, which are flattened
   into one list. This function also takes two extra arguments that are passed
   to the mapping function."
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output list<ElementOutType> outList;
  end MapFunc;
algorithm
  outList := map2Flat_tail(inList, inMapFunc, inArg1, inArg2, {});
end map2Flat;

public function map2Flat_tail
  "Tail recursive implementation of map2Flat."
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input list<ElementOutType> inAccum;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output list<ElementOutType> outList;
  end MapFunc;
algorithm
  outList := match(inList, inMapFunc, inArg1, inArg2, inAccum)
    local
      ElementInType e;
      list<ElementInType> rest;
      list<ElementOutType> res;

    case ({}, _, _, _, _) then listReverse(inAccum);

    case (e :: rest, _, _, _, _)
      equation
        res = inMapFunc(e, inArg1, inArg2);
        res = listAppend(res, inAccum);
      then
        map2Flat_tail(rest, inMapFunc, inArg1, inArg2, res);

  end match;
end map2Flat_tail;

public function mapMap
  "More efficient than: map(map(inList, inMapFunc1), inMapFunc2)"
  input list<ElementInType> inList;
  input MapFunc1 inMapFunc1;
  input MapFunc2 inMapFunc2;
  output list<ElementOutType2> outList;

  partial function MapFunc1
    input ElementInType inElement;
    output ElementOutType1 outElement;
  end MapFunc1;

  partial function MapFunc2
    input ElementOutType1 inElement;
    output ElementOutType2 outElement;
  end MapFunc2;
algorithm
  outList := mapMap_tail(inList, inMapFunc1, inMapFunc2, {});
end mapMap;

protected function mapMap_tail
  "Tail recursive implementation of mapMap."
  input list<ElementInType> inList;
  input MapFunc1 inMapFunc1;
  input MapFunc2 inMapFunc2;
  input list<ElementOutType2> inAccum;
  output list<ElementOutType2> outList;

  partial function MapFunc1
    input ElementInType inElement;
    output ElementOutType1 outElement;
  end MapFunc1;

  partial function MapFunc2
    input ElementOutType1 inElement;
    output ElementOutType2 outElement;
  end MapFunc2;
algorithm
  outList := match(inList, inMapFunc1, inMapFunc2, inAccum)
    local
      ElementInType a;
      ElementOutType1 b;
      ElementOutType2 c;
      list<ElementInType> xs;

    case ({}, _, _, _) then listReverse(inAccum);

    case (a::xs, _, _, _)
      equation
        b = inMapFunc1(a);
        c = inMapFunc2(b);
      then
        mapMap_tail(xs, inMapFunc1, inMapFunc2, c :: inAccum);
  end match;
end mapMap_tail;

protected function mapMap_0
  "More efficient than map_0(map(inList, inMapFunc1), inMapFunc2),"
  input list<ElementInType> inList;
  input MapFunc1 inMapFunc1;
  input MapFunc2 inMapFunc2;

  partial function MapFunc1
    input ElementInType inElement;
    output ElementOutType outElement;
  end MapFunc1;

  partial function MapFunc2
    input ElementOutType inElement;
  end MapFunc2;
algorithm
  _ := match(inList, inMapFunc1, inMapFunc2)
    local
      ElementInType a;
      ElementOutType b;
      list<ElementInType> xs;

    case ({}, _, _) then ();

    case (a::xs, _, _)
      equation
        b = inMapFunc1(a);
        inMapFunc2(b);
        mapMap_0(xs, inMapFunc1, inMapFunc2);
      then
        ();
  end match;
end mapMap_0;

public function mapAllValue
  "Applies a function to all elements in the lists, and fails if not all
   elements are equal to the given value."
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input ValueType inValue;

  partial function MapFunc
    input ElementInType inElement;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  _ := match(inList, inMapFunc, inValue)
    local
      ElementInType head;
      list<ElementInType> rest;
      ElementOutType new_head;

    case ({}, _, _) then ();

    case (head :: rest, _, _)
      equation
        new_head = inMapFunc(head);
        equality(new_head = inValue);
        mapAllValue(rest, inMapFunc, inValue);
      then
        ();
  end match;
end mapAllValue;

public function mapAllValueBool
  "Same as mapAllValue, but returns true or false instead of succeeding or
  failing."
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input ValueType inValue;
  output Boolean outAllValue;

  partial function MapFunc
    input ElementInType inElement;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outAllValue := matchcontinue(inList, inMapFunc, inValue)
    case (_, _, _)
      equation
        mapAllValue(inList, inMapFunc, inValue);
      then
        true;
    else false;
  end matchcontinue;
end mapAllValueBool;

public function map1AllValue
  "Applies a function to all elements in the lists, and fails if not all
   elements are equal to the given value. This function also takes an extra
   argument that are passed to the mapping function."
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input ValueType inValue;
  input ArgType1 inArg1;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  _ := match(inList, inMapFunc, inValue, inArg1)
    local
      ElementInType head;
      list<ElementInType> rest;
      ElementOutType new_head;

    case ({}, _, _, _) then ();

    case (head :: rest, _, _, _)
      equation
        new_head = inMapFunc(head, inArg1);
        equality(new_head = inValue);
        map1AllValue(rest, inMapFunc, inValue, inArg1);
      then
        ();
  end match;
end map1AllValue;

public function map1rAllValue
  "Applies a function to all elements in the lists, and fails if not all
   elements are equal to the given value. This function also takes an extra
   argument that are passed to the mapping function."
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input ValueType inValue;
  input ArgType1 inArg1;

  partial function MapFunc
    input ArgType1 inArg1;
    input ElementInType inElement;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  _ := match(inList, inMapFunc, inValue, inArg1)
    local
      ElementInType head;
      list<ElementInType> rest;
      ElementOutType new_head;

    case ({}, _, _, _) then ();

    case (head :: rest, _, _, _)
      equation
        new_head = inMapFunc(inArg1,head);
        equality(new_head = inValue);
        map1rAllValue(rest, inMapFunc, inValue, inArg1);
      then
        ();
  end match;
end map1rAllValue;

public function map2AllValue
  "Applies a function to all elements in the lists, and fails if not all
   elements are equal to the given value. This function also takes two extra
   arguments that are passed to the mapping function."
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input ValueType inValue;
  input ArgType1 inArg1;
  input ArgType2 inArg2;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  _ := match(inList, inMapFunc, inValue, inArg1, inArg2)
    local
      ElementInType head;
      list<ElementInType> rest;
      ElementOutType new_head;

    case ({}, _, _, _, _) then ();

    case (head :: rest, _, _, _, _)
      equation
        new_head = inMapFunc(head, inArg1, inArg2);
        equality(new_head = inValue);
        map2AllValue(rest, inMapFunc, inValue, inArg1, inArg2);
      then
        ();
  end match;
end map2AllValue;

public function mapListAllValueBool
  "Same as mapAllValue, but returns true or false instead of succeeding or
  failing."
  input list<list<ElementInType>> inList;
  input MapFunc inMapFunc;
  input ValueType inValue;
  output Boolean outAllValue;

  partial function MapFunc
    input ElementInType inElement;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outAllValue := matchcontinue(inList, inMapFunc, inValue)
    local
      list<ElementInType> lst;
      list<list<ElementInType>> rest;
    case ({},_,_) then true;
    case (lst::rest, _, _)
      equation
        mapAllValue(lst, inMapFunc, inValue);
      then
        mapListAllValueBool(rest, inMapFunc, inValue);
    else false;
  end matchcontinue;
end mapListAllValueBool;

public function foldAllValue
  "Applies a function to all elements in the lists, and fails if not all
   elements are equal to the given value. This function also takes an extra
   argument that are passed to the mapping function and updated"
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input ValueType inValue;
  input ArgType1 inArg1;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output ElementOutType outElement;
    output ArgType1 outArg1;
  end MapFunc;
algorithm
  _ := match(inList, inMapFunc, inValue, inArg1)
    local
      ElementInType head;
      list<ElementInType> rest;
      ElementOutType new_head;
      ArgType1 arg;

    case ({}, _, _, _) then ();

    case (head :: rest, _, _, _)
      equation
        (new_head,arg) = inMapFunc(head, inArg1);
        equality(new_head = inValue);
        foldAllValue(rest, inMapFunc, inValue, arg);
      then
        ();
  end match;
end foldAllValue;

public function applyAndFold
  "fold(map(inList, inApplyFunc), inFoldFunc, inFoldArg), but is more
   memory-efficient."
  input list<ElementInType> inList;
  input FoldFunc inFoldFunc;
  input ApplyFunc inApplyFunc;
  input FoldType inFoldArg;
  output FoldType outResult;

  partial function ApplyFunc
    input ElementInType inElement;
    output ElementOutType1 outElement;
  end ApplyFunc;

  partial function FoldFunc
    input ElementOutType1 inElement;
    input FoldType inAccumulator;
    output FoldType outResult;
  end FoldFunc;
algorithm
  outResult := match(inList, inFoldFunc, inApplyFunc, inFoldArg)
    local
      list<ElementInType> rest;
      ElementInType head;
      ElementOutType1 res;
      FoldType fold_res;

    case ({}, _, _, _) then inFoldArg;

    case (head :: rest, _, _, _)
      equation
        res = inApplyFunc(head);
        fold_res = inFoldFunc(res, inFoldArg);
        fold_res = applyAndFold(rest, inFoldFunc, inApplyFunc, fold_res);
      then
        fold_res;

  end match;
end applyAndFold;

public function applyAndFold1
  "fold(map(inList, inApplyFunc(inExtraArg)), inFoldFunc, inFoldArg), but is more
   memory-efficient."
  input list<ElementInType> inList;
  input FoldFunc inFoldFunc;
  input ApplyFunc inApplyFunc;
  input ArgType1 inExtraArg;
  input FoldType inFoldArg;
  output FoldType outResult;

  partial function ApplyFunc
    input ElementInType inElement1;
    input ArgType1 inElement2;
    output ElementOutType1 outElement;
  end ApplyFunc;

  partial function FoldFunc
    input ElementOutType1 inElement;
    input FoldType inAccumulator;
    output FoldType outResult;
  end FoldFunc;
algorithm
  outResult := match(inList, inFoldFunc, inApplyFunc, inExtraArg, inFoldArg)
    local
      list<ElementInType> rest;
      ElementInType head;
      ElementOutType1 res;
      FoldType fold_res;

    case ({}, _, _, _, _) then inFoldArg;

    case (head :: rest, _, _, _, _)
      equation
        res = inApplyFunc(head, inExtraArg);
        fold_res = inFoldFunc(res, inFoldArg);
        fold_res = applyAndFold1(rest, inFoldFunc, inApplyFunc, inExtraArg, fold_res);
      then
        fold_res;

  end match;
end applyAndFold1;

public function mapList
  "Takes a list of lists and a functions, and creates a new list of lists by
   applying the function to all elements in  the list of lists.
     Example: mapList({{1, 2},{3},{4}}, intString) =>
                      {{\"1\", \"2\"}, {\"3\"}, {\"4\"}}"
  input list<list<ElementInType>> inListList;
  input MapFunc inFunc;
  output list<list<ElementOutType>> outListList;

  partial function MapFunc
    input ElementInType inElement;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outListList := map1(inListList, map, inFunc);
end mapList;

public function mapList0
  "Takes a list of lists and a functions, and applying
  the function to all elements in  the list of lists.
     Example: mapList0({{1, 2},{3},{4}}, print)"

  input list<list<ElementInType>> inListList;
  input MapFunc inFunc;

  partial function MapFunc
    input ElementInType inElement;
  end MapFunc;
algorithm
  map1_0(inListList, map_0, inFunc);
end mapList0;

public function mapList1_0
  "Takes a list of lists and a functions, and applying
  the function to all elements in  the list of lists.
     Example: mapList1_0({{1, 2},{3},{4}}, costomPrint, inArg1)"

  input list<list<ElementInType>> inListList;
  input MapFunc inFunc;
  input ArgType1 inArg1;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
  end MapFunc;
algorithm
  map2_0(inListList, map1_0, inFunc, inArg1);
end mapList1_0;

public function mapList2_0
  "Takes a list of lists and a functions, and applying
  the function to all elements in  the list of lists.
     Example: mapList1_0({{1, 2},{3},{4}}, costomPrint, inArg1, inArg2)"

  input list<list<ElementInType>> inListList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType1 inArg2;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType1 inArg2;
  end MapFunc;
algorithm
  map3_0(inListList, map2_0, inFunc, inArg1, inArg2);
end mapList2_0;

public function mapList1_1
  "Takes a list of lists and a functions, and applying
  the function to all elements in  the list of lists.
     Example: mapList1_0({{1, 2},{3},{4}}, costomPrint, inArg1)"

  input list<list<ElementInType>> inListList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  output list<list<ElementOutType>> outListList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outListList := map2(inListList, map1, inFunc, inArg1);
end mapList1_1;

public function mapListReverse
  "Takes a list of lists and a functions, and creates a new list of lists by
   applying the function to all elements in  the list of lists. The order of the
   elements in the inner lists will be reversed compared to mapList.
     Example: mapListReverse({{1, 2}, {3}, {4}}, intString) =>
                             {{\"4\"}, {\"3\"}, {\"2\", \"1\"}}"
  input list<list<ElementInType>> inListList;
  input MapFunc inFunc;
  output list<list<ElementOutType>> outListList;

  partial function MapFunc
    input ElementInType inElement;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outListList := map1(inListList, mapReverse, inFunc);
end mapListReverse;

public function map1List
  "Similar to mapList but with a mapping function that takes an extra argument."
  input list<list<ElementInType>> inListList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  output list<list<ElementOutType>> outListList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outListList := map2(inListList, map1, inFunc, inArg1);
end map1List;

public function map2List
  "Similar to mapList but with a mapping function that takes two extra arguments."
  input list<list<ElementInType>> inListList;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  output list<list<ElementOutType>> outListList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outListList := map3(inListList, map2, inFunc, inArg1, inArg2);
end map2List;

public function fold
  "Takes a list and a function operating on list elements having an extra
   argument that is 'updated', thus returned from the function. fold will call
   the function for each element in a sequence, updating the start value.
     Example: fold({1, 2, 3}, intAdd, 2) => 8
              intAdd(1, 2) => 3, intAdd(2, 3) => 5, intAdd(3, 5) => 8"
  input list<ElementType> inList;
  input FoldFunc inFoldFunc;
  input FoldType inStartValue;
  output FoldType outResult;

  partial function FoldFunc
    input ElementType inElement;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outResult := match(inList, inFoldFunc, inStartValue)
    local
      ElementType e;
      list<ElementType> rest;
      FoldType arg;

    case ({}, _, _) then inStartValue;

    case (e :: rest, _, _)
      equation
        arg = inFoldFunc(e, inStartValue);
      then
        fold(rest, inFoldFunc, arg);

  end match;
end fold;

public function foldr
  "Same as fold, but with reversed order on the fold function arguments."
  input list<ElementType> inList;
  input FoldFunc inFoldFunc;
  input FoldType inStartValue;
  output FoldType outResult;

  partial function FoldFunc
    input FoldType inFoldArg;
    input ElementType inElement;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outResult := match(inList, inFoldFunc, inStartValue)
    local
      ElementType e;
      list<ElementType> rest;
      FoldType arg;

    case ({}, _, _) then inStartValue;

    case (e :: rest, _, _)
      equation
        arg = inFoldFunc(inStartValue, e);
      then
        foldr(rest, inFoldFunc, arg);

  end match;
end foldr;

public function fold1
  "Takes a list and a function operating on list elements having an extra
   argument that is 'updated', thus returned from the function, and a constant
   argument that is not updated. fold will call the function for each element in
   a sequence, updating the start value."
  input list<ElementType> inList;
  input FoldFunc inFoldFunc;
  input ArgType1 inExtraArg;
  input FoldType inStartValue;
  output FoldType outResult;

  partial function FoldFunc
    input ElementType inElement;
    input ArgType1 inConstantArg;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outResult := match(inList, inFoldFunc, inExtraArg, inStartValue)
    local
      ElementType e;
      list<ElementType> rest;
      FoldType arg;

    case ({}, _, _, _) then inStartValue;

    case (e :: rest, _, _, _)
      equation
        arg = inFoldFunc(e, inExtraArg, inStartValue);
      then
        fold1(rest, inFoldFunc, inExtraArg, arg);

  end match;
end fold1;

public function fold1r
  "Same as fold1, but with reversed order on the fold function arguments."
  input list<ElementType> inList;
  input FoldFunc inFoldFunc;
  input ArgType1 inExtraArg;
  input FoldType inStartValue;
  output FoldType outResult;

  partial function FoldFunc
    input FoldType inFoldArg;
    input ElementType inElement;
    input ArgType1 inConstantArg;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outResult := match(inList, inFoldFunc, inExtraArg, inStartValue)
    local
      ElementType e;
      list<ElementType> rest;
      FoldType arg;

    case ({}, _, _, _) then inStartValue;

    case (e :: rest, _, _, _)
      equation
        arg = inFoldFunc(inStartValue, e, inExtraArg);
      then
        fold1r(rest, inFoldFunc, inExtraArg, arg);

  end match;
end fold1r;

public function fold2
  "Takes a list and a function operating on list elements having an extra
   argument that is 'updated', thus returned from the function, and two constant
   arguments that is not updated. fold will call the function for each element in
   a sequence, updating the start value."
  input list<ElementType> inList;
  input FoldFunc inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input FoldType inStartValue;
  output FoldType outResult;

  partial function FoldFunc
    input ElementType inElement;
    input ArgType1 inConstantArg1;
    input ArgType2 inConstantArg2;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outResult := match(inList, inFoldFunc, inExtraArg1, inExtraArg2, inStartValue)
    local
      ElementType e;
      list<ElementType> rest;
      FoldType arg;

    case ({}, _, _, _, _) then inStartValue;

    case (e :: rest, _, _, _, _)
      equation
        arg = inFoldFunc(e, inExtraArg1, inExtraArg2, inStartValue);
      then
        fold2(rest, inFoldFunc, inExtraArg1, inExtraArg2, arg);

  end match;
end fold2;

public function foldList2
  "Takes a list and a function operating on list elements having an extra
   argument that is 'updated', thus returned from the function, and two constant
   arguments that is not updated. fold will call the function for each element in
   a sequence, updating the start value."
  input list<list<ElementType>> inList;
  input FoldFunc inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input FoldType inStartValue;
  output FoldType outResult;

  partial function FoldFunc
    input ElementType inElement;
    input ArgType1 inConstantArg1;
    input ArgType2 inConstantArg2;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outResult := match(inList, inFoldFunc, inExtraArg1, inExtraArg2, inStartValue)
    local
      list<ElementType> e;
      list<list<ElementType>> rest;
      FoldType arg;

    case ({}, _, _, _, _) then inStartValue;

    case (e :: rest, _, _, _, _)
      equation
        arg = fold2(e, inFoldFunc, inExtraArg1, inExtraArg2, inStartValue);
      then 
        foldList2(rest, inFoldFunc, inExtraArg1, inExtraArg2, arg);

  end match;
end foldList2;

public function fold2r
  "Same as fold2, but with reversed order on the fold function arguments."
  input list<ElementType> inList;
  input FoldFunc inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input FoldType inStartValue;
  output FoldType outResult;

  partial function FoldFunc
    input FoldType inFoldArg;
    input ElementType inElement;
    input ArgType1 inConstantArg1;
    input ArgType2 inConstantArg2;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outResult := match(inList, inFoldFunc, inExtraArg1, inExtraArg2, inStartValue)
    local
      ElementType e;
      list<ElementType> rest;
      FoldType arg;

    case ({}, _, _, _, _) then inStartValue;

    case (e :: rest, _, _, _, _)
      equation
        arg = inFoldFunc(inStartValue, e, inExtraArg1, inExtraArg2);
      then
        fold2r(rest, inFoldFunc, inExtraArg1, inExtraArg2, arg);

  end match;
end fold2r;

public function fold3
  "Takes a list and a function operating on list elements having an extra
   argument that is 'updated', thus returned from the function, and three constant
   arguments that are not updated. fold will call the function for each element in
   a sequence, updating the start value."
  input list<ElementType> inList;
  input FoldFunc inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input ArgType3 inExtraArg3;
  input FoldType inStartValue;
  output FoldType outResult;

  partial function FoldFunc
    input ElementType inElement;
    input ArgType1 inConstantArg1;
    input ArgType2 inConstantArg2;
    input ArgType3 inConstantArg3;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outResult := match(inList, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inStartValue)
    local
      ElementType e;
      list<ElementType> rest;
      FoldType arg;

    case ({}, _, _, _, _, _) then inStartValue;

    case (e :: rest, _, _, _, _, _)
      equation
        arg = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, inStartValue);
      then
        fold3(rest, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, arg);

  end match;
end fold3;

public function fold4
  "Takes a list and a function operating on list elements having an extra
   argument that is 'updated', thus returned from the function, and four constant
   arguments that are not updated. fold will call the function for each element in
   a sequence, updating the start value."
  input list<ElementType> inList;
  input FoldFunc inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input ArgType3 inExtraArg3;
  input ArgType4 inExtraArg4;
  input FoldType inStartValue;
  output FoldType outResult;

  partial function FoldFunc
    input ElementType inElement;
    input ArgType1 inConstantArg1;
    input ArgType2 inConstantArg2;
    input ArgType3 inConstantArg3;
    input ArgType4 inConstantArg4;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outResult := match(inList, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inStartValue)
    local
      ElementType e;
      list<ElementType> rest;
      FoldType arg;

    case ({}, _, _, _, _, _, _) then inStartValue;

    case (e :: rest, _, _, _, _, _, _)
      equation
        arg = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inStartValue);
      then
        fold4(rest, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, arg);

  end match;
end fold4;

public function fold43
  "Takes a list and a function operating on list elements having an extra
   argument that is 'updated', thus returned from the function, and three constant
   arguments that are not updated. fold will call the function for each element in
   a sequence, updating the start value."
  input list<ElementType> inList;
  input FoldFunc inFoldFunc;
  input ArgType1 inExtraArg1;
  input ArgType2 inExtraArg2;
  input ArgType3 inExtraArg3;
  input ArgType4 inExtraArg4;
  input FoldType1 inStartValue1;
  input FoldType2 inStartValue2;
  input FoldType3 inStartValue3;
  output FoldType1 outResult1;
  output FoldType2 outResult2;
  output FoldType3 outResult3;

  partial function FoldFunc
    input ElementType inElement;
    input ArgType1 inConstantArg1;
    input ArgType2 inConstantArg2;
    input ArgType3 inConstantArg3;
    input ArgType4 inConstantArg4;
    input FoldType1 inFoldArg1;
    input FoldType2 inFoldArg2;
    input FoldType3 inFoldArg3;
    output FoldType1 outFoldArg1;
    output FoldType2 outFoldArg2;
    output FoldType3 outFoldArg3;
  end FoldFunc;
algorithm
  (outResult1, outResult2, outResult3) := match(inList, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inStartValue1, inStartValue2, inStartValue3)
    local
      ElementType e;
      list<ElementType> rest;
      FoldType1 arg1;
      FoldType2 arg2;
      FoldType3 arg3;

    case ({}, _, _, _, _, _, _, _, _) then (inStartValue1, inStartValue2, inStartValue3);

    case (e :: rest, _, _, _, _, _, _, _, _)
      equation
        (arg1, arg2, arg3) = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inStartValue1, inStartValue2, inStartValue3);
        (outResult1, outResult2, outResult3) = fold43(rest, inFoldFunc, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, arg1, arg2, arg3);
      then
        (outResult1, outResult2, outResult3);

  end match;
end fold43;

public function mapFold
  "Takes a list, an extra argument and a function. The function will be applied
  to each element in the list, and the extra argument will be passed to the
  function and updated."
  input list<ElementInType> inList;
  input FuncType inFunc;
  input FoldType inArg;
  output list<ElementOutType> outList;
  output FoldType outArg;

  partial function FuncType
    input ElementInType inElem;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outList, outArg) := mapFold_tail(inList, inFunc, inArg, {});
end mapFold;

public function mapFold_tail
  "Tail recursive implementation of mapFold."
  input list<ElementInType> inList;
  input FuncType inFunc;
  input FoldType inArg;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;
  output FoldType outArg;

  partial function FuncType
    input ElementInType inElem;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outList, outArg) := match(inList, inFunc, inArg, inAccumList)
    local
      ElementInType e1;
      list<ElementInType> rest_e1;
      ElementOutType res;
      list<ElementOutType> rest_res, acc;
      FoldType arg;

    case ({}, _, _, _) then (listReverse(inAccumList), inArg);

    case (e1 :: rest_e1, _, _, _)
      equation
        (res, arg) = inFunc(e1, inArg);
        acc = res :: inAccumList;
        (rest_res, arg) = mapFold_tail(rest_e1, inFunc, arg, acc);
      then
        (rest_res, arg);

  end match;
end mapFold_tail;

public function map1Fold
  "Takes a list, an extra argument, an extra constant argument, and a function.
  The function will be applied to each element in the list, and the extra
  argument will be passed to the function and updated."
  input list<ElementInType> inList;
  input FuncType inFunc;
  input ArgType1 inConstArg;
  input FoldType inArg;
  output list<ElementOutType> outList;
  output FoldType outArg;

  partial function FuncType
    input ElementInType inElem;
    input ArgType1 inConstArg;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outList, outArg) := map1Fold_tail(inList, inFunc, inConstArg, inArg, {});
end map1Fold;

protected function map1Fold_tail
  "Tail recursive implementation of map1Fold."
  input list<ElementInType> inList;
  input FuncType inFunc;
  input ArgType1 inConstArg;
  input FoldType inArg;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;
  output FoldType outArg;

  partial function FuncType
    input ElementInType inElem;
    input ArgType1 inConstArg;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outList, outArg) := match(inList, inFunc, inConstArg, inArg, inAccumList)
    local
      ElementInType e1;
      list<ElementInType> rest_e1;
      ElementOutType res;
      list<ElementOutType> rest_res, acc;
      FoldType arg;

    case ({}, _, _, _, _) then (listReverse(inAccumList), inArg);
    case (e1 :: rest_e1, _, _, _, _)
      equation
        (res, arg) = inFunc(e1, inConstArg, inArg);
        acc = res :: inAccumList;
        (rest_res, arg) = map1Fold_tail(rest_e1, inFunc, inConstArg, arg, acc);
      then
        (rest_res, arg);
  end match;
end map1Fold_tail;

public function map2Fold
  "Takes a list, two extra constant arguments, an extra argument, and a function.
  The function will be applied to each element in the list, and the extra
  argument will be passed to the function and updated."
  input list<ElementInType> inList;
  input FuncType inFunc;
  input ArgType1 inConstArg;
  input ArgType2 inConstArg2;
  input FoldType inArg;
  output list<ElementOutType> outList;
  output FoldType outArg;

  partial function FuncType
    input ElementInType inElem;
    input ArgType1 inConstArg;
    input ArgType2 inConstArg2;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outList, outArg) := map2Fold_tail(inList, inFunc, inConstArg, inConstArg2, inArg, {});
end map2Fold;

public function map2Fold_tail
  "Tail recursive implementation of map2Fold."
  input list<ElementInType> inList;
  input FuncType inFunc;
  input ArgType1 inConstArg;
  input ArgType2 inConstArg2;
  input FoldType inArg;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;
  output FoldType outArg;

  partial function FuncType
    input ElementInType inElem;
    input ArgType1 inConstArg;
    input ArgType2 inConstArg2;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outList, outArg) := match(inList, inFunc, inConstArg, inConstArg2, inArg, inAccumList)
    local
      ElementInType e1;
      list<ElementInType> rest_e1;
      ElementOutType res;
      list<ElementOutType> rest_res, acc;
      FoldType arg;

    case ({}, _, _, _, _, _) then (listReverse(inAccumList), inArg);
    case (e1 :: rest_e1, _, _, _, _, _)
      equation
        (res, arg) = inFunc(e1, inConstArg, inConstArg2, inArg);
        acc = res :: inAccumList;
        (rest_res, arg) = map2Fold_tail(rest_e1, inFunc, inConstArg, inConstArg2, arg, acc);
      then
        (rest_res, arg);
  end match;
end map2Fold_tail;

public function map3Fold
  "Takes a list, three extra constant arguments, an extra argument, and a function.
  The function will be applied to each element in the list, and the extra
  argument will be passed to the function and updated."
  input list<ElementInType> inList;
  input FuncType inFunc;
  input ArgType1 inConstArg;
  input ArgType2 inConstArg2;
  input ArgType3 inConstArg3;
  input FoldType inArg;
  output list<ElementOutType> outList;
  output FoldType outArg;

  partial function FuncType
    input ElementInType inElem;
    input ArgType1 inConstArg;
    input ArgType2 inConstArg2;
    input ArgType3 inConstArg3;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outList, outArg) := map3Fold_tail(inList, inFunc, inConstArg, inConstArg2, inConstArg3, inArg, {});
end map3Fold;

public function map3Fold_tail
  "Tail recursive implementation of map3Fold."
  input list<ElementInType> inList;
  input FuncType inFunc;
  input ArgType1 inConstArg;
  input ArgType2 inConstArg2;
  input ArgType3 inConstArg3;
  input FoldType inArg;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;
  output FoldType outArg;

  partial function FuncType
    input ElementInType inElem;
    input ArgType1 inConstArg;
    input ArgType2 inConstArg2;
    input ArgType3 inConstArg3;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outList, outArg) := match(inList, inFunc, inConstArg, inConstArg2, inConstArg3, inArg, inAccumList)
    local
      ElementInType e1;
      list<ElementInType> rest_e1;
      ElementOutType res;
      list<ElementOutType> rest_res, acc;
      FoldType arg;

    case ({}, _, _, _, _, _, _) then (listReverse(inAccumList), inArg);
    case (e1 :: rest_e1, _, _, _, _, _, _)
      equation
        (res, arg) = inFunc(e1, inConstArg, inConstArg2, inConstArg3, inArg);
        acc = res :: inAccumList;
        (rest_res, arg) = map3Fold_tail(rest_e1, inFunc, inConstArg, inConstArg2, inConstArg3, arg, acc);
      then
        (rest_res, arg);
  end match;
end map3Fold_tail;

public function map4Fold
  "Takes a list, four extra constant arguments, an extra argument, and a function.
  The function will be applied to each element in the list, and the extra
  argument will be passed to the function and updated."
  input list<ElementInType> inList;
  input FuncType inFunc;
  input ArgType1 inConstArg;
  input ArgType2 inConstArg2;
  input ArgType3 inConstArg3;
  input ArgType4 inConstArg4;
  input FoldType inArg;
  output list<ElementOutType> outList;
  output FoldType outArg;

  partial function FuncType
    input ElementInType inElem;
    input ArgType1 inConstArg;
    input ArgType2 inConstArg2;
    input ArgType3 inConstArg3;
    input ArgType4 inConstArg4;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outList, outArg) := map4Fold_tail(inList, inFunc, inConstArg, inConstArg2, inConstArg3, inConstArg4, inArg, {});
end map4Fold;

public function map4Fold_tail
  "Tail recursive implementation of map4Fold."
  input list<ElementInType> inList;
  input FuncType inFunc;
  input ArgType1 inConstArg;
  input ArgType2 inConstArg2;
  input ArgType3 inConstArg3;
  input ArgType4 inConstArg4;
  input FoldType inArg;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;
  output FoldType outArg;

  partial function FuncType
    input ElementInType inElem;
    input ArgType1 inConstArg;
    input ArgType2 inConstArg2;
    input ArgType3 inConstArg3;
    input ArgType4 inConstArg4;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outList, outArg) := match(inList, inFunc, inConstArg, inConstArg2, inConstArg3, inConstArg4, inArg, inAccumList)
    local
      ElementInType e1;
      list<ElementInType> rest_e1;
      ElementOutType res;
      list<ElementOutType> rest_res, acc;
      FoldType arg;

    case ({}, _, _, _, _, _, _, _) then (listReverse(inAccumList), inArg);
    case (e1 :: rest_e1, _, _, _, _, _, _, _)
      equation
        (res, arg) = inFunc(e1, inConstArg, inConstArg2, inConstArg3, inConstArg4, inArg);
        acc = res :: inAccumList;
        (rest_res, arg) = map4Fold_tail(rest_e1, inFunc, inConstArg, inConstArg2, inConstArg3, inConstArg4, arg, acc);
      then
        (rest_res, arg);
  end match;
end map4Fold_tail;

public function mapFoldTuple
  "Takes a list, an extra argument and a function. The function will be applied
  to each element in the list, and the extra argument will be passed to the
  function and updated. The input and outputs of the function are joined as
  tuples."
  input list<ElementInType> inList;
  input FuncType inFunc;
  input FoldType inArg;
  output list<ElementOutType> outList;
  output FoldType outArg;

  partial function FuncType
    input tuple<ElementInType, FoldType> inTuple;
    output tuple<ElementOutType, FoldType> outTuple;
  end FuncType;
algorithm
  (outList, outArg) := mapFoldTuple_tail(inList, inFunc, inArg, {});
end mapFoldTuple;

public function mapFoldTuple_tail
  "Tail recursive implementation of mapFoldTuple."
  input list<ElementInType> inList;
  input FuncType inFunc;
  input FoldType inArg;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;
  output FoldType outArg;

  partial function FuncType
    input tuple<ElementInType, FoldType> inTuple;
    output tuple<ElementOutType, FoldType> outTuple;
  end FuncType;
algorithm
  (outList, outArg) := match(inList, inFunc, inArg, inAccumList)
    local
      ElementInType e1;
      list<ElementInType> rest_e1;
      ElementOutType res;
      list<ElementOutType> rest_res, acc;
      FoldType arg;

    case ({}, _, _, _) then (listReverse(inAccumList), inArg);

    case (e1 :: rest_e1, _, _, _)
      equation
        ((res, arg)) = inFunc((e1, inArg));
        acc = res :: inAccumList;
        (rest_res, arg) =
          mapFoldTuple_tail(rest_e1, inFunc, arg, acc);
      then
        (rest_res, arg);

  end match;
end mapFoldTuple_tail;

public function mapFoldList
  "Takes a list of lists, an extra argument, and a function.  The function will
  be applied to each element in the list, and the extra argument will be passed
  to the function and updated for each element."
  input list<list<ElementInType>> inListList;
  input FuncType inFunc;
  input FoldType inArg;
  output list<list<ElementOutType>> outListList;
  output FoldType outArg;

  partial function FuncType
    input ElementInType inElem;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outListList, outArg) := mapFoldList_tail(inListList, inFunc, inArg, {});
end mapFoldList;

protected function mapFoldList_tail
  "Tail recursive implementation of mapFoldList."
  input list<list<ElementInType>> inListList;
  input FuncType inFunc;
  input FoldType inArg;
  input list<list<ElementOutType>> inAccumList;
  output list<list<ElementOutType>> outListList;
  output FoldType outArg;

  partial function FuncType
    input ElementInType inElem;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outListList, outArg) := match(inListList, inFunc, inArg, inAccumList)
    local
      list<ElementInType> lst;
      list<list<ElementInType>> rest_lst;
      list<ElementOutType> res;
      list<list<ElementOutType>> rest_res, accum;
      FoldType arg;

    case ({}, _, _, _) then (listReverse(inAccumList), inArg);
    case (lst :: rest_lst, _, _, _)
      equation
        (res, arg) = mapFold(lst, inFunc, inArg);
        accum = res :: inAccumList;
        (rest_res, arg) = mapFoldList_tail(rest_lst, inFunc, arg, accum);
      then
        (rest_res, arg);
  end match;
end mapFoldList_tail;

public function map3FoldList
  "Takes a list of lists, an extra argument, and a function.  The function will
  be applied to each element in the list, and the extra argument will be passed
  to the function and updated for each element."
  input list<list<ElementInType>> inListList;
  input FuncType inFunc;
  input ArgType1 inConstArg;
  input ArgType2 inConstArg2;
  input ArgType3 inConstArg3;
  input FoldType inArg;
  output list<list<ElementOutType>> outListList;
  output FoldType outArg;

  partial function FuncType
    input ElementInType inElem;
    input ArgType1 inConstArg;
    input ArgType2 inConstArg2;
    input ArgType3 inConstArg3;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outListList, outArg) := map3FoldList_tail(inListList, inFunc, inConstArg, inConstArg2, inConstArg3, inArg, {});
end map3FoldList;

protected function map3FoldList_tail
  "Tail recursive implementation of mapFoldList."
  input list<list<ElementInType>> inListList;
  input FuncType inFunc;
  input ArgType1 inConstArg;
  input ArgType2 inConstArg2;
  input ArgType3 inConstArg3;
  input FoldType inArg;
  input list<list<ElementOutType>> inAccumList;
  output list<list<ElementOutType>> outListList;
  output FoldType outArg;

  partial function FuncType
    input ElementInType inElem;
    input ArgType1 inConstArg;
    input ArgType2 inConstArg2;
    input ArgType3 inConstArg3;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outListList, outArg) := match(inListList, inFunc, inConstArg, inConstArg2, inConstArg3, inArg, inAccumList)
    local
      list<ElementInType> lst;
      list<list<ElementInType>> rest_lst;
      list<ElementOutType> res;
      list<list<ElementOutType>> rest_res, accum;
      FoldType arg;

    case ({}, _, _, _, _, _, _) then (listReverse(inAccumList), inArg);
    case (lst :: rest_lst, _, _, _, _, _, _)
      equation
        (res, arg) = map3Fold(lst, inFunc, inConstArg, inConstArg2, inConstArg3, inArg);
        accum = res :: inAccumList;
        (rest_res, arg) = map3FoldList_tail(rest_lst, inFunc, inConstArg, inConstArg2, inConstArg3, arg, accum);
      then
        (rest_res, arg);
  end match;
end map3FoldList_tail;

public function mapFoldListTuple
  "Takes a list of lists, an extra argument and a function. The function will be
  applied to each element in the list, and the extra argument will be passed to
  the function and updated. The input and outputs of the function are joined as
  tuples."
  input list<list<ElementInType>> inListList;
  input FuncType inFunc;
  input FoldType inFoldArg;
  output list<list<ElementOutType>> outListList;
  output FoldType outFoldArg;

  partial function FuncType
    input tuple<ElementInType, FoldType> inTuple;
    output tuple<ElementOutType, FoldType> outTuple;
  end FuncType;
algorithm
  (outListList, outFoldArg) :=
    mapFoldListTuple_tail(inListList, inFunc, inFoldArg, {});
end mapFoldListTuple;

public function mapFoldListTuple_tail
  "Tail recursive implementation of mapFoldListTuple."
  input list<list<ElementInType>> inListList;
  input FuncType inFunc;
  input FoldType inFoldArg;
  input list<list<ElementOutType>> inAccumList;
  output list<list<ElementOutType>> outListList;
  output FoldType outFoldArg;

  partial function FuncType
    input tuple<ElementInType, FoldType> inTuple;
    output tuple<ElementOutType, FoldType> outTuple;
  end FuncType;
algorithm
(outListList, outFoldArg) := match(inListList, inFunc, inFoldArg, inAccumList)
  local
    list<ElementInType> lst;
    list<list<ElementInType>> rest_lst;
    list<ElementOutType> res;
    list<list<ElementOutType>> rest_res, accum;
    FoldType arg;

  case ({}, _, _, _) then (listReverse(inAccumList), inFoldArg);
  case (lst :: rest_lst, _, _, _)
    equation
      (res, arg) = mapFoldTuple(lst, inFunc, inFoldArg);
      accum = res :: inAccumList;
      (rest_res, arg) = mapFoldListTuple_tail(rest_lst, inFunc, arg, accum);
    then
      (rest_res, arg);
  end match;
end mapFoldListTuple_tail;

public function foldcallN
  "Takes a value and a function operating on the value n times.
     Example: foldcallN(1, intAdd, 4) => 4"
  input Integer n;
  input FoldFunc inFoldFunc;
  input FoldType inStartValue;
  output FoldType outResult;

  partial function FoldFunc
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outResult := match(n, inFoldFunc, inStartValue)
    local
      FoldType arg;

    case (0, _, _) then inStartValue;

    case (_ , _, _)
      equation
        arg = inFoldFunc(inStartValue);
      then
        foldcallN(n-1, inFoldFunc, arg);

  end match;
end foldcallN;

public function reduce
  "Takes a list and a function operating on two elements of the list.
   The function performs a reduction of the list to a single value using the
   function. Example:
     reduce({1, 2, 3}, intAdd) => 6"
  input list<ElementType> inList;
  input ReduceFunc inReduceFunc;
  output ElementType outResult;

  partial function ReduceFunc
    input ElementType inElement1;
    input ElementType inElement2;
    output ElementType outElement;
  end ReduceFunc;
algorithm
  outResult := match(inList, inReduceFunc)
    local
      ElementType e1, e2, res;
      list<ElementType> rest;

    case ({e1}, _) then e1;
    case ({e1, e2}, _)
      equation
        res = inReduceFunc(e1, e2);
      then
        res;

    case (e1 :: e2 :: (rest as _ :: _), _)
      equation
        res = inReduceFunc(e1, e2);
      then
        reduce(res :: rest, inReduceFunc);

    case ({}, _)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- Util.listReduce failed on empty list!\n");
      then
        fail();
  end match;
end reduce;

public function reduce1
  "Takes a list and a function operating on two elements of the list.
   The function performs a reduction of the list to a single value using the
   function. This function also takes an extra argument that is sent to the
   reduction function."
  input list<ElementType> inList;
  input ReduceFunc inReduceFunc;
  input ArgType1 inExtraArg1;
  output ElementType outResult;

  partial function ReduceFunc
    input ElementType inElement1;
    input ElementType inElement2;
    input ArgType1 inExtraArg1;
    output ElementType outElement;
  end ReduceFunc;
algorithm
  outResult := match(inList, inReduceFunc, inExtraArg1)
    local
      ElementType e1, e2, res;
      list<ElementType> rest;

    case ({e1}, _, _) then e1;
    case ({e1, e2}, _, _)
      equation
        res = inReduceFunc(e1, e2, inExtraArg1);
      then
        res;

    case (e1 :: e2 :: (rest as _ :: _), _, _)
      equation
        res = inReduceFunc(e1, e2, inExtraArg1);
      then
        reduce1(res :: rest, inReduceFunc, inExtraArg1);

    case ({}, _, _)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- Util.listReduce failed on empty list!\n");
      then
        fail();
  end match;
end reduce1;

public function flatten
  "Takes a list of lists and flattens it out, producing one list of all elements
   of the sublists. O(len(outList))
     Example: flatten({{1, 2}, {3, 4, 5}, {6}, {}}) => {1, 2, 3, 4, 5, 6}"
  input list<list<ElementType>> inList;
  output list<ElementType> outList;
algorithm
  outList := flatten_tail(listReverse(inList), {});
end flatten;

protected function flatten_tail
  "Tail recursive implementation of flatten."
  input list<list<ElementType>> inList;
  input list<ElementType> inAccumList;
  output list<ElementType> outList;
algorithm
  outList := match(inList, inAccumList)
    local
      list<ElementType> e, res;
      list<list<ElementType>> rest;

    case ({}, _) then inAccumList;
    case (e :: rest, _)
      equation
        res = listAppend(e,inAccumList);
      then
        flatten_tail(rest, res);

  end match;
end flatten_tail;

public function thread
  "Takes two lists of the same type and threads (interleaves) them together.
     Example: thread({1, 2, 3}, {4, 5, 6}) => {4, 1, 5, 2, 6, 3}"
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  output list<ElementType> outList;
algorithm
  outList := thread_tail(inList1, inList2, {});
end thread;

public function thread_tail
  "Tail recursive implementation of thread."
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  input list<ElementType> inAccum;
  output list<ElementType> outList;
algorithm
  outList := match(inList1, inList2, inAccum)
    local
      ElementType e1, e2;
      list<ElementType> rest1, rest2;

    case ({}, {}, _) then listReverse(inAccum);

    case (e1 :: rest1, e2 :: rest2, _)
      then thread_tail(rest1, rest2, e1 :: e2 :: inAccum);
  end match;
end thread_tail;

public function thread3
  "Takes three lists of the same type and threads (interleaves) them together.
     Example: thread({1, 2, 3}, {4, 5, 6}, {7, 8, 9}) =>
             {7, 4, 1, 8, 5, 2, 9, 6, 3}"
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  input list<ElementType> inList3;
  output list<ElementType> outList;
algorithm
  outList := thread3_tail(inList1, inList2, inList3, {});
end thread3;

public function thread3_tail
  "Tail recursive implementation of thread3."
  input list<ElementType> inList1;
  input list<ElementType> inList2;
  input list<ElementType> inList3;
  input list<ElementType> inAccum;
  output list<ElementType> outList;
algorithm
  outList := match(inList1, inList2, inList3, inAccum)
    local
      ElementType e1, e2, e3;
      list<ElementType> rest1, rest2, rest3;

    case ({}, {}, {}, _) then listReverse(inAccum);

    case (e1 :: rest1, e2 :: rest2, e3 :: rest3, _)
      then thread3_tail(rest1, rest2, rest3, e1 :: e2 :: e3 :: inAccum);
  end match;
end thread3_tail;

public function threadTuple
  "Takes two lists and threads (interleaves) the arguments into a list of tuples
   consisting of the two element types.
     Example: threadTuple({1, 2, 3}, {true, false, true}) =>
              {(1, true), (2, false), (3, true)}"
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  output list<tuple<ElementType1, ElementType2>> outTuples;
algorithm
  outTuples := threadTuple_tail(inList1, inList2, {});
end threadTuple;

protected function threadTuple_tail
  "Tail recursive implementation of threadTuple."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input list<tuple<ElementType1, ElementType2>> inAccum;
  output list<tuple<ElementType1, ElementType2>> outTuples;
algorithm
  outTuples := match(inList1, inList2, inAccum)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;

    case ({}, {}, _) then listReverse(inAccum);
    case (e1 :: rest1, e2 :: rest2, _)
      then threadTuple_tail(rest1, rest2, (e1, e2) :: inAccum);

  end match;
end threadTuple_tail;

public function thread3Tuple
  "Takes three lists and threads (interleaves) the arguments into a list of tuples
   consisting of the three element types."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input list<ElementType3> inList3;
  output list<tuple<ElementType1, ElementType2, ElementType3>> outTuples;
algorithm
  outTuples := thread3Tuple_tail(inList1, inList2, inList3, {});
end thread3Tuple;

protected function thread3Tuple_tail
  "Tail recursive implementation of thread3Tuple."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input list<ElementType3> inList3;
  input list<tuple<ElementType1, ElementType2, ElementType3>> inAccum;
  output list<tuple<ElementType1, ElementType2, ElementType3>> outTuples;
algorithm
  outTuples := match(inList1, inList2, inList3, inAccum)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      ElementType3 e3;
      list<ElementType3> rest3;

    case ({}, {}, {}, _) then listReverse(inAccum);
    case (e1 :: rest1, e2 :: rest2, e3 :: rest3, _)
      then thread3Tuple_tail(rest1, rest2, rest3, (e1, e2, e3) :: inAccum);

  end match;
end thread3Tuple_tail;

public function thread4Tuple
  "Takes four lists and threads (interleaves) the arguments into a list of tuples
   consisting of the four element types."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input list<ElementType3> inList3;
  input list<ElementType4> inList4;
  output list<tuple<ElementType1, ElementType2, ElementType3, ElementType4>> outTuples;
algorithm
  outTuples := thread4Tuple_tail(inList1, inList2, inList3, inList4, {});
end thread4Tuple;

protected function thread4Tuple_tail
  "Tail recursive implementation of thread4Tuple."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input list<ElementType3> inList3;
  input list<ElementType4> inList4;
  input list<tuple<ElementType1, ElementType2, ElementType3, ElementType4>> inAccum;
  output list<tuple<ElementType1, ElementType2, ElementType3, ElementType4>> outTuples;
algorithm
  outTuples := match(inList1, inList2, inList3, inList4, inAccum)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      ElementType3 e3;
      list<ElementType3> rest3;
      ElementType4 e4;
      list<ElementType4> rest4;

    case ({}, {}, {}, {}, _) then listReverse(inAccum);
    case (e1 :: rest1, e2 :: rest2, e3 :: rest3, e4 :: rest4, _)
      then thread4Tuple_tail(rest1, rest2, rest3, rest4, (e1, e2, e3, e4) :: inAccum);

  end match;
end thread4Tuple_tail;

public function thread5Tuple
  "Takes five lists and threads (interleaves) the arguments into a list of tuples
   consisting of the four element types."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input list<ElementType3> inList3;
  input list<ElementType4> inList4;
  input list<ElementType5> inList5;
  output list<tuple<ElementType1, ElementType2, ElementType3, ElementType4, ElementType5>> outTuples;
algorithm
  outTuples := thread5Tuple_tail(inList1, inList2, inList3, inList4, inList5, {});
end thread5Tuple;

protected function thread5Tuple_tail
  "Tail recursive implementation of thread5Tuple."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input list<ElementType3> inList3;
  input list<ElementType4> inList4;
  input list<ElementType5> inList5;
  input list<tuple<ElementType1, ElementType2, ElementType3, ElementType4, ElementType5>> inAccum;
  output list<tuple<ElementType1, ElementType2, ElementType3, ElementType4, ElementType5>> outTuples;
algorithm
  outTuples := match(inList1, inList2, inList3, inList4, inList5, inAccum)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      ElementType3 e3;
      list<ElementType3> rest3;
      ElementType4 e4;
      list<ElementType4> rest4;
      ElementType5 e5;
      list<ElementType5> rest5;

    case ({}, {}, {}, {}, {}, _) then listReverse(inAccum);
    case (e1 :: rest1, e2 :: rest2, e3 :: rest3, e4 :: rest4, e5 :: rest5, _)
      then thread5Tuple_tail(rest1, rest2, rest3, rest4, rest5, (e1, e2, e3, e4, e5) :: inAccum);

  end match;
end thread5Tuple_tail;

public function threadMap
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list.
     Example: threadMap({1, 2}, {3, 4}, intAdd) => {1+3, 2+4}"
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(threadMap_tail(inList1, inList2, inMapFunc, {}));
end threadMap;

public function threadMapReverse
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. The order of the result list
   will be reversed compared to the input lists.
     Example: threadMap({1, 2}, {3, 4}, intAdd) => {2+4, 1+3}"
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := threadMap_tail(inList1, inList2, inMapFunc, {});
end threadMapReverse;

public function threadMap_tail
  "Tail recursive implementation of threadMap."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input list<ElementOutType> inAccum;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList1, inList2, inMapFunc, inAccum)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      ElementOutType res;

    case ({}, {}, _, _) then inAccum;
    case (e1 :: rest1, e2 :: rest2, _, _)
      equation
        res = inMapFunc(e1, e2);
      then
        threadMap_tail(rest1, rest2, inMapFunc, res :: inAccum);
  end match;
end threadMap_tail;

public function threadMapList
  "Takes two lists of lists and a function and threads (interleaves) and maps
   the elements of the two lists, creating a new list.
     Example: threadMapList({{1, 2}}, {{3, 4}}, intAdd) => {{1 + 3, 2 + 4}}"
  input list<list<ElementType1>> inList1;
  input list<list<ElementType2>> inList2;
  input MapFunc inMapFunc;
  output list<list<ElementOutType>> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := threadMap1(inList1, inList2, threadMap, inMapFunc);
end threadMapList;

public function threadTupleList
  "Takes two lists of lists as arguments and produces a list of lists of a two
  tuple of the element types of each list.
  Example: threadTupleList({1}, {2, 3}}, {{'a'}, {'b', 'c'}}) =>
             {{(1, 'a')}, {(2, 'b'), (3, 'c')}}"
  input list<list<ElementType1>> inList1;
  input list<list<ElementType2>> inList2;
  output list<list<tuple<ElementType1, ElementType2>>> outList;
algorithm
  outList := threadMap(inList1, inList2, threadTuple);
end threadTupleList;

public function threadMapAllValue
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, and checks if the result is the same as the given
   value.
     Example: threadMapAllValue({true, true}, {false, true}, boolAnd, true) =>
              fail"
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input ValueType inValue;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  _ := match(inList1, inList2, inMapFunc, inValue)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      ElementOutType res;

    case ({}, {}, _, _) then ();
    case (e1 :: rest1, e2 :: rest2, _, _)
      equation
        res = inMapFunc(e1, e2);
        equality(res = inValue);
        threadMapAllValue(rest1, rest2, inMapFunc, inValue);
      then
        ();
  end match;
end threadMapAllValue;

public function threadMap1
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes an
   extra arguments that are passed to the mapping function."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := listReverse(threadMap1_tail(inList1, inList2, inMapFunc, inArg1, {}));
end threadMap1;

public function threadMap1Reverse
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes an
   extra arguments that are passed to the mapping function. The order of the
   result list will be reversed compared to the input lists."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := threadMap1_tail(inList1, inList2, inMapFunc, inArg1, {});
end threadMap1Reverse;

public function threadMap1_tail
  "Tail recursive implementation of threadMap1."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  input list<ElementOutType> inAccum;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList1, inList2, inMapFunc, inArg1, inAccum)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      ElementOutType res;

    case ({}, {}, _, _, _) then inAccum;
    case (e1 :: rest1, e2 :: rest2, _, _, _)
      equation
        res = inMapFunc(e1, e2, inArg1);
      then
        threadMap1_tail(rest1, rest2, inMapFunc, inArg1, res :: inAccum);
  end match;
end threadMap1_tail;

public function threadMap1_0
  "Takes two lists and a function, and applies the function to each element of
   the lists in a pairwise fashion. This function also takes an extra argument
   which is passed to the mapping function, but returns no result."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
  end MapFunc;
algorithm
  _ := match(inList1, inList2, inMapFunc, inArg1)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;

    case ({}, {}, _, _) then ();
    case (e1 :: rest1, e2 :: rest2, _, _)
      equation
        inMapFunc(e1, e2, inArg1);
        threadMap1_0(rest1, rest2, inMapFunc, inArg1);
      then
        ();
  end match;
end threadMap1_0;


public function threadMap2
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes two
   extra arguments that are passed to the mapping function."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := threadMap2_tail(inList1, inList2, inMapFunc, inArg1, inArg2, {});
  outList := listReverse(outList);
end threadMap2;

public function threadMap2Reverse
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes two
   extra arguments that are passed to the mapping function. The order of the
   result list will be reversed compared to the input lists."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := threadMap2_tail(inList1, inList2, inMapFunc, inArg1, inArg2, {});
end threadMap2Reverse;

public function threadMap2_tail
  "Tail recursive implementation of threadMap2."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input list<ElementOutType> inAccum;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList1, inList2, inMapFunc, inArg1, inArg2, inAccum)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      ElementOutType res;

    case ({}, {}, _, _, _, _) then inAccum;
    case (e1 :: rest1, e2 :: rest2, _, _, _, _)
      equation
        res = inMapFunc(e1, e2, inArg1, inArg2);
      then
        threadMap2_tail(rest1, rest2, inMapFunc, inArg1, inArg2, res :: inAccum);
  end match;
end threadMap2_tail;

public function threadMap2ReverseFold
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes two
   extra arguments and a fold argument that are passed to the mapping function.
   The order of the result list will be reversed compared to the input lists."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input FoldType inFoldArg;
  output list<ElementOutType> outList;
  output FoldType outFoldArg;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input FoldType inFoldArg;
    output ElementOutType outElement;
    output FoldType outFoldArg;
  end MapFunc;
algorithm
  (outList,outFoldArg) := threadMap2Fold_tail(inList1, inList2, inMapFunc, inArg1, inArg2, inFoldArg, {});
end threadMap2ReverseFold;

public function threadMap2Fold_tail
  "Tail recursive implementation of threadMap2Fold."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input FoldType inFoldArg;
  input list<ElementOutType> inAccum;
  output list<ElementOutType> outList;
  output FoldType outFoldArg;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input FoldType inFoldArg;
    output ElementOutType outElement;
    output FoldType outFoldArg;
  end MapFunc;
algorithm
  (outList,outFoldArg) := match(inList1, inList2, inMapFunc, inArg1, inArg2, inFoldArg, inAccum)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      ElementOutType res;
      FoldType foldArg;

    case ({}, {}, _, _, _, _, _) then (inAccum,inFoldArg);
    case (e1 :: rest1, e2 :: rest2, _, _, _, foldArg, _)
      equation
        (res,foldArg) = inMapFunc(e1, e2, inArg1, inArg2, foldArg);
        (outList,foldArg) = threadMap2Fold_tail(rest1, rest2, inMapFunc, inArg1, inArg2, foldArg, res :: inAccum);
      then
        (outList,foldArg);
  end match;
end threadMap2Fold_tail;

public function threadMap3
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes three
   extra arguments that are passed to the mapping function."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := threadMap3_tail(inList1, inList2, inMapFunc, inArg1, inArg2, inArg3, {});
  outList := listReverse(outList);
end threadMap3;

public function threadMap3Reverse
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes three
   extra arguments that are passed to the mapping function."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := threadMap3_tail(inList1, inList2, inMapFunc, inArg1, inArg2, inArg3, {});
end threadMap3Reverse;

public function threadMap3_tail
  "Tail recursive implementation of threadMap3."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input list<ElementOutType> inAccum;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList1, inList2, inMapFunc, inArg1, inArg2, inArg3, inAccum)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      ElementOutType res;

    case ({}, {}, _, _, _, _, _) then inAccum;
    case (e1 :: rest1, e2 :: rest2, _, _, _, _, _)
      equation
        res = inMapFunc(e1, e2, inArg1, inArg2, inArg3);
      then
        threadMap3_tail(rest1, rest2, inMapFunc, inArg1, inArg2, inArg3, res :: inAccum);
  end match;
end threadMap3_tail;

public function thread3Map
  "Takes three lists and a function, and threads (interleaves) and maps the
   elements of the three lists, creating a new list.
     Example: thread3Map({1, 2}, {3, 4}, {5, 6}, intAdd3) => {1+3+5, 2+4+6}"
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input list<ElementType3> inList3;
  input MapFunc inFunc;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ElementType3 inElement3;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := thread3Map_tail(inList1, inList2, inList3, inFunc, {});
end thread3Map;

public function thread3Map_tail
  "Tail recursive implementation of thread3Map."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input list<ElementType3> inList3;
  input MapFunc inFunc;
  input list<ElementOutType> inAccum;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ElementType3 inElement3;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := match(inList1, inList2, inList3, inFunc, inAccum)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      ElementType3 e3;
      list<ElementType3> rest3;
      ElementOutType res;

    case ({}, {}, {}, _, _) then listReverse(inAccum);

    case (e1 :: rest1, e2 :: rest2, e3 :: rest3, _, _)
      equation
        res = inFunc(e1, e2, e3);
      then
        thread3Map_tail(rest1, rest2, rest3, inFunc, res :: inAccum);
  end match;
end thread3Map_tail;

public function threadMap3ReverseFold
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes three
   extra arguments and a fold argument that are passed to the mapping function.
   The order of the result list will be reversed compared to the input lists."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input FoldType inFoldArg;
  output list<ElementOutType> outList;
  output FoldType outFoldArg;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input FoldType inFoldArg;
    output ElementOutType outElement;
    output FoldType outFoldArg;
  end MapFunc;
algorithm
  (outList,outFoldArg) := threadMap3Fold_tail(inList1, inList2, inMapFunc, inArg1, inArg2, inArg3, inFoldArg, {});
end threadMap3ReverseFold;

public function threadMap3Fold_tail
  "Tail recursive implementation of threadMap3Fold."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input MapFunc inMapFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input FoldType inFoldArg;
  input list<ElementOutType> inAccum;
  output list<ElementOutType> outList;
  output FoldType outFoldArg;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input FoldType inFoldArg;
    output ElementOutType outElement;
    output FoldType outFoldArg;
  end MapFunc;
algorithm
  (outList,outFoldArg) := match(inList1, inList2, inMapFunc, inArg1, inArg2, inArg3, inFoldArg, inAccum)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      ElementOutType res;
      FoldType foldArg;

    case ({}, {}, _, _, _, _, _, _) then (inAccum,inFoldArg);
    case (e1 :: rest1, e2 :: rest2, _, _, _, _, foldArg, _)
      equation
        (res,foldArg) = inMapFunc(e1, e2, inArg1, inArg2, inArg3, foldArg);
        (outList,foldArg) = threadMap3Fold_tail(rest1, rest2, inMapFunc, inArg1, inArg2, inArg3, foldArg, res :: inAccum);
      then
        (outList,foldArg);
  end match;
end threadMap3Fold_tail;

public function thread3Map_2
  "Takes three lists and a function, and threads (interleaves) and maps the
   elements of the three lists, creating two new list.
     Example: thread3Map({1, 2}, {3, 4}, {5, 6}, intAddSub3) =>
              ({1+3+5, 2+4+6}, {1-3-5, 2-4-6})"
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input list<ElementType3> inList3;
  input MapFunc inFunc;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ElementType3 inElement3;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
  end MapFunc;
algorithm
  (outList1, outList2) :=
    thread3Map_2_tail(inList1, inList2, inList3, inFunc, {}, {});
end thread3Map_2;

public function thread3Map_2_tail
  "Tail recursive implementation of thread3Map_2."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input list<ElementType3> inList3;
  input MapFunc inFunc;
  input list<ElementOutType1> inAccum1;
  input list<ElementOutType2> inAccum2;
  output list<ElementOutType1> outList1;
  output list<ElementOutType2> outList2;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ElementType3 inElement3;
    output ElementOutType1 outElement1;
    output ElementOutType2 outElement2;
  end MapFunc;
algorithm
  (outList1, outList2) :=
  match(inList1, inList2, inList3, inFunc, inAccum1, inAccum2)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      ElementType3 e3;
      list<ElementType3> rest3;
      ElementOutType1 res1;
      ElementOutType2 res2;
      list<ElementOutType1> resl1;
      list<ElementOutType2> resl2;

    case ({}, {}, {}, _, _, _)
      then (listReverse(inAccum1), listReverse(inAccum2));

    case (e1 :: rest1, e2 :: rest2, e3 :: rest3, _, _, _)
      equation
        (res1, res2) = inFunc(e1, e2, e3);
        (resl1, resl2) = thread3Map_2_tail(rest1, rest2, rest3, inFunc,
          res1 :: inAccum1, res2 :: inAccum2);
      then
        (resl1, resl2);
  end match;
end thread3Map_2_tail;

public function thread3MapFold
  "Takes three lists and a function, and threads (interleaves) and maps the
   elements of the three lists, creating a new list. This function also takes
   one extra argument which are passed to the mapping function and fold."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input list<ElementType3> inList3;
  input MapFunc inFunc;
  input ArgType1 inArg;
  output list<ElementOutType> outList;
  output ArgType1 outArg;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ElementType3 inElement3;
    input ArgType1 inArg;
    output ElementOutType outElement;
    output ArgType1 outArg;
  end MapFunc;
algorithm
  (outList,outArg) := thread3MapFold_tail(inList1, inList2, inList3, inFunc,
    inArg, {});
end thread3MapFold;

public function thread3MapFold_tail
  "Tail recursive implementation of thread3MapFold."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input list<ElementType3> inList3;
  input MapFunc inFunc;
  input ArgType1 inArg;
  input list<ElementOutType> inAccum;
  output list<ElementOutType> outList;
  output ArgType1 outArg;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ElementType3 inElement3;
    input ArgType1 inArg;
    output ElementOutType outElement;
    output ArgType1 outArg;
  end MapFunc;
algorithm
  (outList,outArg) :=
  match(inList1, inList2, inList3, inFunc, inArg, inAccum)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      ElementType3 e3;
      list<ElementType3> rest3;
      ElementOutType res;
      list<ElementOutType> reslst;
      ArgType1 arg;

    case ({}, {}, {}, _, _, _) then (listReverse(inAccum),inArg);

    case (e1 :: rest1, e2 :: rest2, e3 :: rest3, _, _, _)
      equation
        (res,arg) = inFunc(e1, e2, e3, inArg);
        (reslst,arg) = thread3MapFold_tail(rest1, rest2, rest3, inFunc,
          arg, res :: inAccum);
      then
        (reslst,arg);
  end match;
end thread3MapFold_tail;

public function thread3Map3
  "Takes three lists and a function, and threads (interleaves) and maps the
   elements of the three lists, creating a new list. This function also takes
   three extra arguments which are passed to the mapping function."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input list<ElementType3> inList3;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ElementType3 inElement3;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList := thread3Map3_tail(inList1, inList2, inList3, inFunc,
    inArg1, inArg2, inArg3, {});
end thread3Map3;

public function thread3Map3_tail
  "Tail recursive implementation of thread3Map3."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input list<ElementType3> inList3;
  input MapFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input list<ElementOutType> inAccum;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ElementType3 inElement3;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outList :=
  match(inList1, inList2, inList3, inFunc, inArg1, inArg2, inArg3, inAccum)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      ElementType3 e3;
      list<ElementType3> rest3;
      ElementOutType res;

    case ({}, {}, {}, _, _, _, _, _) then listReverse(inAccum);

    case (e1 :: rest1, e2 :: rest2, e3 :: rest3, _, _, _, _, _)
      equation
        res = inFunc(e1, e2, e3, inArg1, inArg2, inArg3);
      then
        thread3Map3_tail(rest1, rest2, rest3, inFunc,
          inArg1, inArg2, inArg3, res :: inAccum);
  end match;
end thread3Map3_tail;

public function threadFold1
  "This is a combination of thread and fold that applies a function to the head
   of two lists with an extra argument that is updated and passed on. This
   function also takes an extra constant argument that is passed to the function."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input FoldFunc inFoldFunc;
  input ArgType1 inArg1;
  input FoldType inFoldArg;
  output FoldType outFoldArg;

  partial function FoldFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outFoldArg := match(inList1, inList2, inFoldFunc, inArg1, inFoldArg)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      FoldType res;

    case ({}, {}, _, _, _) then inFoldArg;

    case (e1 :: rest1, e2 :: rest2, _, _, _)
      equation
        res = inFoldFunc(e1, e2, inArg1, inFoldArg);
      then
        threadFold1(rest1, rest2, inFoldFunc, inArg1, res);

  end match;
end threadFold1;

public function threadFold2
  "This is a combination of thread and fold that applies a function to the head
   of two lists with an extra argument that is updated and passed on. This
   function also takes two extra constant arguments that is passed to the function."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input FoldFunc inFoldFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input FoldType inFoldArg;
  output FoldType outFoldArg;

  partial function FoldFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outFoldArg := match(inList1, inList2, inFoldFunc, inArg1, inArg2, inFoldArg)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      FoldType res;

    case ({}, {}, _, _, _, _) then inFoldArg;

    case (e1 :: rest1, e2 :: rest2, _, _, _, _)
      equation
        res = inFoldFunc(e1, e2, inArg1, inArg2, inFoldArg);
      then
        threadFold2(rest1, rest2, inFoldFunc, inArg1, inArg2, res);

  end match;
end threadFold2;

public function threadFold3
  "This is a combination of thread and fold that applies a function to the head
   of two lists with an extra argument that is updated and passed on. This
   function also takes three extra constant arguments that is passed to the function."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input FoldFunc inFoldFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input FoldType inFoldArg;
  output FoldType outFoldArg;

  partial function FoldFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outFoldArg := match(inList1, inList2, inFoldFunc, inArg1, inArg2, inArg3, inFoldArg)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      FoldType res;

    case ({}, {}, _, _, _, _, _) then inFoldArg;

    case (e1 :: rest1, e2 :: rest2, _, _, _, _, _)
      equation
        res = inFoldFunc(e1, e2, inArg1, inArg2, inArg3, inFoldArg);
      then
        threadFold3(rest1, rest2, inFoldFunc, inArg1, inArg2, inArg3, res);

  end match;
end threadFold3;

public function threadFold
  "This is a combination of thread and fold that applies a function to the head
   of two lists with an extra argument that is updated and passed on."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input FoldFunc inFoldFunc;
  input FoldType inFoldArg;
  output FoldType outFoldArg;

  partial function FoldFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    input FoldType inFoldArg;
    output FoldType outFoldArg;
  end FoldFunc;
algorithm
  outFoldArg := match(inList1, inList2, inFoldFunc, inFoldArg)
    local
      ElementType1 e1;
      list<ElementType1> rest1;
      ElementType2 e2;
      list<ElementType2> rest2;
      FoldType res;

    case ({}, {}, _, _) then inFoldArg;

    case (e1 :: rest1, e2 :: rest2, _, _)
      equation
        res = inFoldFunc(e1, e2, inFoldArg);
      then
        threadFold(rest1, rest2, inFoldFunc, res);

  end match;
end threadFold;

public function threadMapFold
  "Takes a list, an extra argument and a function. The function will be applied
  to each element in the list, and the extra argument will be passed to the
  function and updated."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input FuncType inFunc;
  input FoldType inArg;
  output list<ElementOutType> outList;
  output FoldType outArg;

  partial function FuncType
    input ElementType1 inElem1;
    input ElementType2 inElem2;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outList, outArg) := threadMapFold_tail(inList1, inList2, inFunc, inArg, {});
end threadMapFold;

public function threadMapFold_tail
  "Tail recursive implementation of mapFold."
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input FuncType inFunc;
  input FoldType inArg;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;
  output FoldType outArg;

  partial function FuncType
    input ElementType1 inElem1;
    input ElementType2 inElem2;
    input FoldType inArg;
    output ElementOutType outResult;
    output FoldType outArg;
  end FuncType;
algorithm
  (outList, outArg) := match(inList1, inList2, inFunc, inArg, inAccumList)
    local
      ElementType1 e1;
      ElementType2 e2;
      list<ElementType1> rest_e1;
      list<ElementType2> rest_e2;
      ElementOutType res;
      list<ElementOutType> rest_res, acc;
      FoldType arg;

    case ({}, {}, _, _, _) then (listReverse(inAccumList), inArg);

    case (e1 :: rest_e1, e2 :: rest_e2, _, _, _)
      equation
        (res, arg) = inFunc(e1, e2, inArg);
        acc = res :: inAccumList;
        (rest_res, arg) = threadMapFold_tail(rest_e1, rest_e2, inFunc, arg, acc);
      then
        (rest_res, arg);

  end match;
end threadMapFold_tail;

public function position
  "Takes a value and a list, and returns the position of the first list element
  that whose value is equal to the given value. The index starts at zero.
    Example: position(2, {0, 1, 2, 3}) => 2"
  input ElementType inElement;
  input list<ElementType> inList;
  output Integer outPosition;
algorithm
  outPosition := position_impl(inElement, inList, 0);
end position;

protected function position_impl
  "Implementation of position."
  input ElementType inElement;
  input list<ElementType> inList;
  input Integer inPosition;
  output Integer outPosition;
algorithm
  outPosition := matchcontinue(inElement, inList, inPosition)
    local
      ElementType head;
      list<ElementType> rest;

    case (_, head :: _, _)
      equation
        equality(head = inElement);
      then
        inPosition;

    case (_, _ :: rest, _)
      then position_impl(inElement, rest, inPosition + 1);

  end matchcontinue;
end position_impl;

public function positionOnTrue
  "Takes a value and a list, and returns the position of the first list element
  that whose value is equal to the given value. The index starts at zero.
    Example: position(2, {0, 1, 2, 3}) => 2"
  input ValueType inValue;
  input list<ElementType> inList;
  input CompFunc inCompFunc;
  output Integer outPosition;

  partial function CompFunc
    input ValueType inValue;
    input ElementType inElement;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outPosition := positionOnTrue2(inValue, inList, inCompFunc, 0);
end positionOnTrue;

protected function positionOnTrue2
  "Helper function to positionOnTrue."
  input ElementType inValue;
  input list<ElementType> inList;
  input CompFunc inCompFunc;
  input Integer inPosition;
  output Integer outPosition;

  partial function CompFunc
    input ValueType inValue;
    input ElementType inElement;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outPosition := matchcontinue(inValue, inList, inCompFunc, inPosition)
    local
      ElementType head;
      list<ElementType> rest;

    case (_, head :: _, _, _)
      equation
        true = inCompFunc(inValue, head);
      then
        inPosition;

    case (_, _ :: rest, _, _)
      then positionOnTrue2(inValue, rest, inCompFunc, inPosition + 1);

  end matchcontinue;
end positionOnTrue2;

public function positionList
  "Takes a value and a list of lists, and returns the position of the value.
   outListIndex is the index of the list the value was found in, and outPosition
   is the position in that list. Indices start from 0.
     Example: positionList(3, {{4, 2}, {6, 4, 3, 1}}) => (1, 2)"
  input ElementType inElement;
  input list<list<ElementType>> inList;
  output Integer outListIndex;
  output Integer outPosition;
algorithm
  (outListIndex, outPosition) := positionList_impl(inElement, inList, 0);
end positionList;

protected function positionList_impl
  "Implementation of positionList."
  input ElementType inElement;
  input list<list<ElementType>> inList;
  input Integer inListIndex;
  output Integer outListIndex;
  output Integer outPosition;
algorithm
  (outListIndex, outPosition) :=
  matchcontinue (inElement, inList, inListIndex)
    local
      list<ElementType> e;
      list<list<ElementType>> rest;
      Integer index, pos;

    case (_, e :: rest, _)
      equation
        pos = position(inElement, e);
      then
        (inListIndex, pos);

    case (_, _ :: rest, _)
      equation
        (index, pos) = positionList_impl(inElement, rest, inListIndex + 1);
      then
        (index, pos);

  end matchcontinue;
end positionList_impl;

protected function listPos2 "helper function to listlistPos"
  input ElementType inTypeA;
  input list<ElementType> inTypeALst;
  output Boolean outInteger;
algorithm
  outInteger := matchcontinue (inTypeA,inTypeALst)
    local
      ElementType x,y;
      list<ElementType> ys;
      Boolean a;
    case (_,{}) then false;
    case (x,(y :: ys))
      equation
        equality(x = y);
      then
        true;
    case (x,(y :: ys))
      equation
        failure(equality(x = y));
        a = listPos2(x, ys);
      then
        a;
  end matchcontinue;
end listPos2;

public function getMember
  "Takes a value and a list, and returns the value if it's present in the list.
   If not present the function will fail.
     Example: listGetMember(0, {1, 2, 3}) => fail
              listGetMember(1, {1, 2, 3}) => 1"
  input ElementType inElement;
  input list<ElementType> inList;
  output ElementType outElement;
protected
  ElementType e, res;
  list<ElementType> rest;
algorithm
  e :: rest := inList;
  outElement := Debug.bcallret2(not valueEq(inElement, e),
    getMember, inElement, rest, e);
end getMember;

public function getMemberOnTrue
  "Takes a value and a list of values and a comparison function over two values.
   If the value is present in the list (using the comparison function returning
   true) the value is returned, otherwise the function fails.
   Example:
     function equalLength(string,string) returns true if the strings are of same length
     getMemberOnTrue(\"a\",{\"bb\",\"b\",\"ccc\"},equalLength) => \"b\""
  input ValueType inValue;
  input list<ElementType> inList;
  input CompFunc inCompFunc;
  output ElementType outElement;

  partial function CompFunc
    input ValueType inValue;
    input ElementType inElement;
    output Boolean outIsEqual;
  end CompFunc;
protected
  ElementType e;
  list<ElementType> rest;
  Boolean b;
algorithm
  e :: rest := inList;
  b := inCompFunc(inValue, e);
  outElement := Debug.bcallret3(boolNot(b), getMemberOnTrue, inValue, rest, inCompFunc, e);
end getMemberOnTrue;

public function notMember
  "Returns true if a list does not contain the given element, otherwise false."
  input ElementType inElement;
  input list<ElementType> inList;
  output Boolean outIsNotMember;
algorithm
  outIsNotMember := not listMember(inElement, inList);
end notMember;

public function isMemberOnTrue
  "Returns true if the given value is a member of the list, as determined by the
  comparison function given."
  input ValueType inValue;
  input list<ElementType> inList;
  input CompFunc inCompFunc;
  output Boolean outIsMember;

  partial function CompFunc
    input ValueType inValue;
    input ElementType inElement;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outIsMember := matchcontinue(inValue, inList, inCompFunc)
    case (_, _, _)
      equation
        _ = getMemberOnTrue(inValue, inList, inCompFunc);
      then
        true;

    else false;
  end matchcontinue;
end isMemberOnTrue;

public function exist
  "Returns true if the and element is found on the list using a function. Example
       filter({1,2}, isEven) => true
       filter({1,3,5,7}, isEven) => false"
  input list<ElementType> inList;
  input FindFunc inFindFunc;
  output Boolean outList;

  partial function FindFunc
    input ElementType inElement;
    output Boolean out;
  end FindFunc;
algorithm
  outList := exist_work(false,inList,inFindFunc);
end exist;

protected function exist_work
  "Returns true if the and element is found on the list using a function. Example
       filter({1,2}, isEven) => true
       filter({1,3,5,7}, isEven) => false"
  input Boolean found;
  input list<ElementType> inList;
  input FindFunc inFindFunc;
  output Boolean outList;

  partial function FindFunc
    input ElementType inElement;
    output Boolean out;
  end FindFunc;
algorithm
  outList := match (found,inList,inFindFunc)
    local
      list<ElementType> t;
      ElementType h;
      Boolean ret,b;
    case(true,_,_) then true;
    case(_,{},_) then false;
    case(_,h::t,_)
      equation
        b = inFindFunc(h);
      then exist_work(b, t, inFindFunc);
  end match;
end exist_work;

public function exist1
  "Returns true if the and element is found on the list using a function and an extra argument."
  input list<ElementType1> inList;
  input FindFunc inFindFunc;
  input ElementType2 inExtraArg;
  output Boolean outList;

  partial function FindFunc
    input ElementType1 inElement;
    input ElementType2 inExtraArg;
    output Boolean out;
  end FindFunc;
algorithm
  outList := exist1_work(false,inList,inFindFunc,inExtraArg);
end exist1;

protected function exist1_work
  "Returns true if the and element is found on the list using a function and an extra argument."
  input Boolean found;
  input list<ElementType1> inList;
  input FindFunc inFindFunc;
  input ElementType2 inExtraArg;
  output Boolean outList;

  partial function FindFunc
    input ElementType1 inElement;
    input ElementType2 inExtraArg;
    output Boolean out;
  end FindFunc;
algorithm
  outList := match (found,inList,inFindFunc,inExtraArg)
    local
      list<ElementType1> t;
      ElementType1 h;
      Boolean ret,b;
    case(true,_,_,_) then true;
    case(_,{},_,_) then false;
    case(_,h::t,_,_)
      equation
        b = inFindFunc(h, inExtraArg);
      then exist1_work(b, t, inFindFunc, inExtraArg);
  end match;
end exist1_work;

public function exist2
  "Returns true if the and element is found on the list using a function and an extra argument."
  input list<ElementType1> inList;
  input FindFunc inFindFunc;
  input ElementType2 inExtraArg1;
  input ElementType3 inExtraArg2;
  output Boolean outList;

  partial function FindFunc
    input ElementType1 inElement;
    input ElementType2 inExtraArg1;
    input ElementType3 inExtraArg2;
    output Boolean out;
  end FindFunc;
algorithm
  outList := exist2_work(false,inList,inFindFunc,inExtraArg1,inExtraArg2);
end exist2;

protected function exist2_work
  "Returns true if the and element is found on the list using a function and an extra argument."
  input Boolean found;
  input list<ElementType1> inList;
  input FindFunc inFindFunc;
  input ElementType2 inExtraArg1;
  input ElementType3 inExtraArg2;
  output Boolean outList;

  partial function FindFunc
    input ElementType1 inElement;
    input ElementType2 inExtraArg1;
    input ElementType3 inExtraArg2;
    output Boolean out;
  end FindFunc;
algorithm
  outList := match (found,inList,inFindFunc,inExtraArg1,inExtraArg2)
    local
      list<ElementType1> t;
      ElementType1 h;
      Boolean ret,b;
    case(true,_,_,_,_) then true;
    case(_,{},_,_,_) then false;
    case(_,h::t,_,_,_)
      equation
        b = inFindFunc(h, inExtraArg1, inExtraArg2);
      then exist2_work(b, t, inFindFunc, inExtraArg1, inExtraArg2);
  end match;
end exist2_work;

public function extractOnTrue
  "Takes a list of values and a filter function over the values and returns a
   two lists. one of values for which the matching function returns true and the
   other containing the remaining elements.
   N.B. The original list is lost in here. Will fix if I comeup with something more efficient.
     Example:
       extractOnTrue({1, 2, 3, 4, 5}, isEven) => {2, 4}, {1, 3, 5}"
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  output list<ElementType> outExtractedList;
  output list<ElementType> outRemainingList;

  partial function FilterFunc
    input ElementType inElement;
    output Boolean outResult;
  end FilterFunc;
algorithm
  (outExtractedList, outRemainingList) := extractOnTrue_tail(inList, inFilterFunc, {}, {});
  outExtractedList := listReverse(outExtractedList);
  outRemainingList := listReverse(outRemainingList);
end extractOnTrue;

protected function extractOnTrue_tail
  "Tail recursive implementation of extractOnTrue."
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  input list<ElementType> inExtractedList;
  input list<ElementType> inRemainingList;
  output list<ElementType> outExtractedList;
  output list<ElementType> outRemainingList;

  partial function FilterFunc
    input ElementType inElement;
    output Boolean outResult;
  end FilterFunc;
algorithm
  (outExtractedList, outRemainingList) := matchcontinue(inList, inFilterFunc, inExtractedList, inRemainingList)
    local
      ElementType e;
      list<ElementType> rest;
      list<ElementType> exted;
      list<ElementType> remain;

    case ({}, _, _, _) then (inExtractedList, inRemainingList);

    // Add to front of extracted list if the condition works.
    case (e :: rest, _, _, _)
      equation
        true = inFilterFunc(e);
        (exted, remain) = extractOnTrue_tail(rest, inFilterFunc, e :: inExtractedList, inRemainingList);
      then
        (exted, remain);

    // Add to front of remaining list if the condition doesn't work.
    case (e :: rest, _, _, _)
      equation
        (exted, remain) = extractOnTrue_tail(rest, inFilterFunc, inExtractedList, e :: inRemainingList);
      then
        (exted, remain);

  end matchcontinue;
end extractOnTrue_tail;

public function extract1OnTrue
  "Takes a list of values and a filter function over the values and an extra argument and returns
   two lists. one of values for which the matching function returns true and the
   other containing the remaining elements.
   N.B. The original list is lost in here. Will fix if I comeup with something more efficient.
     Example:
       extractOnTrue({1, 2, 3, 4, 5}, isEven) => {2, 4}, {1, 3, 5}"
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  input ArgType1 inArg;
  output list<ElementType> outExtractedList;
  output list<ElementType> outRemainingList;

  partial function FilterFunc
    input ElementType inElement;
    input ArgType1 inArg;
    output Boolean outResult;
  end FilterFunc;
algorithm
  (outExtractedList, outRemainingList) := extract1OnTrue_tail(inList, inFilterFunc, inArg, {}, {});
  outExtractedList := listReverse(outExtractedList);
  outRemainingList := listReverse(outRemainingList);
end extract1OnTrue;

protected function extract1OnTrue_tail
  "Tail recursive implementation of extractOnTrue."
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  input ArgType1 inArg;
  input list<ElementType> inExtractedList;
  input list<ElementType> inRemainingList;
  output list<ElementType> outExtractedList;
  output list<ElementType> outRemainingList;

  partial function FilterFunc
    input ElementType inElement;
    input ArgType1 inArg;
    output Boolean outResult;
  end FilterFunc;
algorithm
  (outExtractedList, outRemainingList) := matchcontinue(inList, inFilterFunc, inArg, inExtractedList, inRemainingList)
    local
      ElementType e;
      list<ElementType> rest;
      list<ElementType> exted;
      list<ElementType> remain;

    case ({}, _, _, _, _) then (inExtractedList, inRemainingList);

    // Add to front of extracted list if the condition works.
    case (e :: rest, _, _, _, _)
      equation
        true = inFilterFunc(e,inArg);
        (exted, remain) = extract1OnTrue_tail(rest, inFilterFunc, inArg, e :: inExtractedList, inRemainingList);
      then
        (exted, remain);

    // Add to front of remaining list if the condition doesn't work.
    case (e :: rest, _, _, _, _)
      equation
        (exted, remain) = extract1OnTrue_tail(rest, inFilterFunc, inArg, inExtractedList, e :: inRemainingList);
      then
        (exted, remain);

  end matchcontinue;
end extract1OnTrue_tail;

public function filter
  "Takes a list of values and a filter function over the values and returns a
   sub list of values for which the matching function succeeds.
     Example:
       filter({1, 2, 3, 4, 5}, isEven) => {2, 4}"
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  output list<ElementType> outList;

  partial function FilterFunc
    input ElementType inElement;
  end FilterFunc;
algorithm
  outList := filter_tail(inList, inFilterFunc, {});
end filter;

protected function filter_tail
  "Tail recursive implementation of filter."
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  input list<ElementType> inAccumList;
  output list<ElementType> outList;

  partial function FilterFunc
    input ElementType inElement;
  end FilterFunc;
algorithm
  outList := matchcontinue(inList, inFilterFunc, inAccumList)
    local
      ElementType e;
      list<ElementType> rest;

    // Reverse at the end.
    case ({}, _, _) then listReverse(inAccumList);

    // Add to front if the condition works.
    case (e :: rest, _, _)
      equation
        inFilterFunc(e);
      then
        filter_tail(rest, inFilterFunc, e :: inAccumList);

    // Filter out and move along.
    case (_ :: rest, _, _)
      then filter_tail(rest, inFilterFunc, inAccumList);

  end matchcontinue;
end filter_tail;

public function filterMap
  "Applies a function to each element in the given list, but also filters out
   all elements for which the function fails."
  input list<ElementInType> inList;
  input FilterMapFunc inFilterMapFunc;
  output list<ElementOutType> outList;

  partial function FilterMapFunc
    input ElementInType inElement;
    output ElementOutType outElement;
  end FilterMapFunc;
algorithm
  outList := listReverse(filterMap_tail(inList, inFilterMapFunc, {}));
end filterMap;

protected function filterMap_tail
  "Tail recursive implementation of filterMap."
  input list<ElementInType> inList;
  input FilterMapFunc inFilterMapFunc;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function FilterMapFunc
    input ElementInType inElement;
    output ElementOutType outElement;
  end FilterMapFunc;
algorithm
  outList := matchcontinue(inList, inFilterMapFunc, inAccumList)
    local
      ElementInType ie;
      list<ElementInType> rest;
      ElementOutType oe;

    case (ie :: rest, _, _)
      equation
        oe = inFilterMapFunc(ie);
      then
        filterMap_tail(rest, inFilterMapFunc, oe :: inAccumList);

    case (_ :: rest, _, _)
      then filterMap_tail(rest, inFilterMapFunc, inAccumList);

    case ({}, _, _) then inAccumList;

  end matchcontinue;
end filterMap_tail;

public function filterMap1
  "Applies a function to each element in the given list, but also filters out
   all elements for which the function fails."
  input list<ElementInType> inList;
  input FilterMapFunc inFilterMapFunc;
  input ElementType1 inExtraArg;
  output list<ElementOutType> outList;

  partial function FilterMapFunc
    input ElementInType inElement;
    input ElementType1 inExtraArg;
    output ElementOutType outElement;
  end FilterMapFunc;
algorithm
  outList := listReverse(filterMap1_tail(inList, inFilterMapFunc, inExtraArg, {}));
end filterMap1;

protected function filterMap1_tail
  "Tail recursive implementation of filterMap."
  input list<ElementInType> inList;
  input FilterMapFunc inFilterMapFunc;
  input ElementType1 inExtraArg;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function FilterMapFunc
    input ElementInType inElement;
    input ElementType1 inExtraArg;
    output ElementOutType outElement;
  end FilterMapFunc;
algorithm
  outList := matchcontinue(inList, inFilterMapFunc, inExtraArg, inAccumList)
    local
      ElementInType ie;
      list<ElementInType> rest;
      ElementOutType oe;

    case (ie :: rest, _, _, _)
      equation
        oe = inFilterMapFunc(ie,inExtraArg);
      then
        filterMap1_tail(rest, inFilterMapFunc, inExtraArg, oe :: inAccumList);

    case (_ :: rest, _, _, _)
      then filterMap1_tail(rest, inFilterMapFunc, inExtraArg, inAccumList);

    case ({}, _, _, _) then inAccumList;

  end matchcontinue;
end filterMap1_tail;

public function filterOnTrue
  "Takes a list of values and a filter function over the values and returns a
   sub list of values for which the matching function returns true.
     Example:
       filter({1, 2, 3, 4, 5}, isEven) => {2, 4}"
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  output list<ElementType> outList;

  partial function FilterFunc
    input ElementType inElement;
    output Boolean outResult;
  end FilterFunc;
algorithm
  outList := listReverse(filterOnTrue_tail(inList, inFilterFunc, {}));
end filterOnTrue;

public function filter1OnTrueSync
  "like filterOnTrue but performs the same filtering synchronously on a second list.
  Takes 2 list of values and a filter function and an extra argument over the values of the first list and returns a
   sub list of values for both lists for which the matching function returns true for the first list.
     Example:
       filter({1, 2, 3, 4, 5}, isEven) => {2, 4}"
  input list<ElementType1> inList;
  input FilterFunc inFilterFunc;
  input ArgType1 inArg1;
  input list<ElementType2> inSyncList;
  output list<ElementType1> outList_a;
  output list<ElementType2> outList_b;

  partial function FilterFunc
    input ElementType1 inElement;
    input ArgType1 inArg1;
    output Boolean outResult;
  end FilterFunc;
algorithm
  (outList_a,outList_b) := matchcontinue(inList,inFilterFunc,inArg1,inSyncList)
    local
      list<ElementType1> lst1;
      list<ElementType2> lst2;
    case(_,_,_,_)
      equation
        true = intEq(listLength(inList),listLength(inSyncList));
        (lst1,lst2) = filter1OnTrueSync_tail(inList, inFilterFunc, inArg1, inSyncList, {}, {});
        lst1 = listReverse(lst1);
        lst2 = listReverse(lst2);
      then
        (lst1,lst2);
    else
      equation
        print("filterOnTrueSync failed");
      then
        fail();
  end matchcontinue;
end filter1OnTrueSync;

public function filterOnTrueSync
  "like filterOnTrue but performs the same filtering synchronously on a second list.
  Takes 2 list of values and a filter function over the values of the first list and returns a
   sub list of values for both lists for which the matching function returns true for the first list.
     Example:
       filter({1, 2, 3, 4, 5}, isEven) => {2, 4}"
  input list<ElementType1> inList;
  input FilterFunc inFilterFunc;
  input list<ElementType2> inSyncList;
  output list<ElementType1> outList_a;
  output list<ElementType2> outList_b;

  partial function FilterFunc
    input ElementType1 inElement;
    output Boolean outResult;
  end FilterFunc;
algorithm
  (outList_a,outList_b) := matchcontinue(inList,inFilterFunc,inSyncList)
    local
      list<ElementType1> lst1;
      list<ElementType2> lst2;
    case(_,_,_)
      equation
        true = intEq(listLength(inList),listLength(inSyncList));
        (lst1,lst2) = filterOnTrueSync_tail(inList, inFilterFunc, inSyncList, {}, {});
        lst1 = listReverse(lst1);
        lst2 = listReverse(lst2);
      then
        (lst1,lst2);
    else
      equation
        print("filterOnTrueSync failed");
      then
        fail();
  end matchcontinue;
end filterOnTrueSync;

public function filterOnTrueReverse
  "Takes a list of values and a filter function over the values and returns a
   sub list of values in reverse order for which the matching function returns true.
     Example:
       filter({1, 2, 3, 4, 5}, isEven) => {4, 2}"
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  output list<ElementType> outList;

  partial function FilterFunc
    input ElementType inElement;
    output Boolean outResult;
  end FilterFunc;
algorithm
  outList := filterOnTrue_tail(inList, inFilterFunc, {});
end filterOnTrueReverse;

protected function filterOnTrue_tail
  "Tail recursive implementation of filter."
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  input list<ElementType> inAccumList;
  output list<ElementType> outList;

  partial function FilterFunc
    input ElementType inElement;
    output Boolean outResult;
  end FilterFunc;
algorithm
  outList := matchcontinue(inList, inFilterFunc, inAccumList)
    local
      ElementType e;
      list<ElementType> rest;

    case ({}, _, _) then inAccumList;

    // Add to front if the condition works.
    case (e :: rest, _, _)
      equation
        true = inFilterFunc(e);
      then
        filterOnTrue_tail(rest, inFilterFunc, e :: inAccumList);

    // Filter out and move along.
    case (e :: rest, _, _)
      then filterOnTrue_tail(rest, inFilterFunc, inAccumList);

  end matchcontinue;
end filterOnTrue_tail;

protected function filterOnTrueSync_tail
  "Tail recursive implementation of filter."
  input list<ElementType1> inList;
  input FilterFunc inFilterFunc;
  input list<ElementType2> inSyncLst;
  input list<ElementType1> inAccumList;
  input list<ElementType2> inAccumSyncList;
  output list<ElementType1> outList;
  output list<ElementType2> outSyncList;

  partial function FilterFunc
    input ElementType1 inElement;
    output Boolean outResult;
  end FilterFunc;
algorithm
  (outList,outSyncList) := matchcontinue(inList, inFilterFunc, inSyncLst, inAccumList, inAccumSyncList)
    local
      ElementType1 e;
      ElementType2 f;
      list<ElementType1> rest,lst1;
      list<ElementType2> restf,lst2;
    case ({}, _, _, _, _) then (inAccumList, inAccumSyncList);

    // Add to front if the condition works.
    case (e :: rest, _, f :: restf, _, _)
      equation
        true = inFilterFunc(e);
        (lst1,lst2) = filterOnTrueSync_tail(rest, inFilterFunc, restf, e :: inAccumList, f :: inAccumSyncList);
      then
        (lst1,lst2);

    // Filter out and move along.
    case (e :: rest, _, f :: restf, _, _)
      equation

      (lst1,lst2) = filterOnTrueSync_tail(rest, inFilterFunc, restf, inAccumList, inAccumSyncList);
     then
      (lst1,lst2);

  end matchcontinue;
end filterOnTrueSync_tail;

protected function filter1OnTrueSync_tail
  "Tail recursive implementation of filter."
  input list<ElementType1> inList;
  input FilterFunc inFilterFunc;
  input ArgType1 inArg1;
  input list<ElementType2> inSyncLst;
  input list<ElementType1> inAccumList;
  input list<ElementType2> inAccumSyncList;
  output list<ElementType1> outList;
  output list<ElementType2> outSyncList;

  partial function FilterFunc
    input ElementType1 inElement;
    input ArgType1 inArg1;
    output Boolean outResult;
  end FilterFunc;
algorithm
  (outList,outSyncList) := matchcontinue(inList, inFilterFunc, inArg1, inSyncLst, inAccumList, inAccumSyncList)
    local
      ElementType1 e;
      ElementType2 f;
      list<ElementType1> rest,lst1;
      list<ElementType2> restf,lst2;
    case ({}, _, _, _, _, _) then (inAccumList, inAccumSyncList);

    // Add to front if the condition works.
    case (e :: rest, _, _, f :: restf, _, _)
      equation
        true = inFilterFunc(e,inArg1);
        (lst1,lst2) = filter1OnTrueSync_tail(rest, inFilterFunc, inArg1, restf, e :: inAccumList, f :: inAccumSyncList);
      then
        (lst1,lst2);

    // Filter out and move along.
    case (e :: rest, _, _, f :: restf, _, _)
      equation
      (lst1,lst2) = filter1OnTrueSync_tail(rest, inFilterFunc, inArg1, restf, inAccumList, inAccumSyncList);
     then
      (lst1,lst2);

  end matchcontinue;
end filter1OnTrueSync_tail;


public function filter1
  "Takes a list of values, a filter function over the values and an extra
   argument, and returns a sub list of values for which the matching function
   succeeds.
     Example:
       filter({1, 2, 3, 4, 5}, isEven) => {2, 4}"
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  input ArgType1 inArg1;
  output list<ElementType> outList;

  partial function FilterFunc
    input ElementType inElement;
    input ArgType1 inArg1;
  end FilterFunc;
algorithm
  outList := filter1_tail(inList, inFilterFunc, inArg1, {});
end filter1;

protected function filter1_tail
  "Tail recursive implementation of filter1."
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  input ArgType1 inArg1;
  input list<ElementType> inAccumList;
  output list<ElementType> outList;

  partial function FilterFunc
    input ElementType inElement;
    input ArgType1 inArg1;
  end FilterFunc;
algorithm
  outList := matchcontinue(inList, inFilterFunc, inArg1, inAccumList)
    local
      ElementType e;
      list<ElementType> rest;

    // Reverse at the end.
    case ({}, _, _, _) then listReverse(inAccumList);

    // Add to front if the condition works.
    case (e :: rest, _, _, _)
      equation
        inFilterFunc(e, inArg1);
      then
        filter1_tail(rest, inFilterFunc, inArg1, e :: inAccumList);

    // Filter out and move along.
    case (_ :: rest, _, _, _)
      then filter1_tail(rest, inFilterFunc, inArg1, inAccumList);

  end matchcontinue;
end filter1_tail;

public function filter1OnTrue
  "Takes a list of values and a filter function over the values and returns a
   sub list of values for which the matching function returns true.
     Example:
       filter1OnTrue({1, 2, 3, 1, 5}, intEq, 1) => {1, 1}"
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  input ArgType1 inArg1;
  output list<ElementType> outList;

  partial function FilterFunc
    input ElementType inElement;
    input ArgType1 inArg1;
    output Boolean outResult;
  end FilterFunc;
algorithm
  outList := filter1OnTrue_tail(inList, inFilterFunc, inArg1, {});
end filter1OnTrue;

protected function filter1OnTrue_tail
  "Tail recursive implementation of filter1OnTrue."
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  input ArgType1 inArg1;
  input list<ElementType> inAccumList;
  output list<ElementType> outList;

  partial function FilterFunc
    input ElementType inElement;
    input ArgType1 inArg1;
    output Boolean outResult;
  end FilterFunc;
algorithm
  outList := match(inList, inFilterFunc, inArg1, inAccumList)
    local
      ElementType e;
      list<ElementType> rest, accum;
      Boolean filter;

    // Reverse at the end.
    case ({}, _, _, _) then listReverse(inAccumList);

    case (e :: rest, _, _, _)
      equation
        filter = inFilterFunc(e, inArg1);
        accum = consOnTrue(filter, e, inAccumList);
      then
        filter1OnTrue_tail(rest, inFilterFunc, inArg1, accum);

  end match;
end filter1OnTrue_tail;

public function filter1rOnTrue
  "Takes a list of values and a filter function over the values and returns a
   sub list of values for which the matching function returns true.
     Example:
       filter1rOnTrue({1, 2, 3, 1, 5}, intEq, 1) => {1, 1}"
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  input ArgType1 inArg1;
  output list<ElementType> outList;

  partial function FilterFunc
    input ArgType1 inArg1;
    input ElementType inElement;
    output Boolean outResult;
  end FilterFunc;
algorithm
  outList := filter1rOnTrue_tail(inList, inFilterFunc, inArg1, {});
end filter1rOnTrue;

protected function filter1rOnTrue_tail
  "Tail recursive implementation of filter1rOnTrue."
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  input ArgType1 inArg1;
  input list<ElementType> inAccumList;
  output list<ElementType> outList;

  partial function FilterFunc
    input ArgType1 inArg1;
    input ElementType inElement;
    output Boolean outResult;
  end FilterFunc;
algorithm
  outList := match(inList, inFilterFunc, inArg1, inAccumList)
    local
      ElementType e;
      list<ElementType> rest, accum;
      Boolean filter;

    // Reverse at the end.
    case ({}, _, _, _) then listReverse(inAccumList);

    case (e :: rest, _, _, _)
      equation
        filter = inFilterFunc(inArg1, e);
        accum = consOnTrue(filter, e, inAccumList);
      then
        filter1rOnTrue_tail(rest, inFilterFunc, inArg1, accum);

  end match;
end filter1rOnTrue_tail;

public function filter2OnTrue
  "Takes a list of values and a filter function over the values and returns a
   sub list of values for which the matching function returns true."
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  output list<ElementType> outList;

  partial function FilterFunc
    input ElementType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output Boolean outResult;
  end FilterFunc;
algorithm
  outList := filter2OnTrue_tail(inList, inFilterFunc, inArg1, inArg2, {});
end filter2OnTrue;

protected function filter2OnTrue_tail
  "Tail recursive implementation of filter1OnTrue."
  input list<ElementType> inList;
  input FilterFunc inFilterFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input list<ElementType> inAccumList;
  output list<ElementType> outList;

  partial function FilterFunc
    input ElementType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output Boolean outResult;
  end FilterFunc;
algorithm
  outList := match(inList, inFilterFunc, inArg1, inArg2, inAccumList)
    local
      ElementType e;
      list<ElementType> rest, accum;
      Boolean filter;

    // Reverse at the end.
    case ({}, _, _, _, _) then listReverse(inAccumList);

    case (e :: rest, _, _, _, _)
      equation
        filter = inFilterFunc(e, inArg1, inArg2);
        accum = consOnTrue(filter, e, inAccumList);
      then
        filter2OnTrue_tail(rest, inFilterFunc, inArg1, inArg2, accum);

  end match;
end filter2OnTrue_tail;

public function removeOnTrue
  "Goes through a list and removes all elements which are equal to the given
   value, using the given comparison function."
  input ValueType inValue;
  input CompFunc inCompFunc;
  input list<ElementType> inList;
  output list<ElementType> outList;

  partial function CompFunc
    input ValueType inValue;
    input ElementType inElement;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outList := removeOnTrue_tail(inValue, inCompFunc, inList, {});
end removeOnTrue;

public function removeOnTrue_tail
  "Tail recursive implementation of removeOnTrue."
  input ValueType inValue;
  input CompFunc inCompFunc;
  input list<ElementType> inList;
  input list<ElementType> inAccumList;
  output list<ElementType> outList;

  partial function CompFunc
    input ValueType inValue;
    input ElementType inElement;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outList := match(inValue, inCompFunc, inList, inAccumList)
    local
      ElementType e;
      list<ElementType> rest, accum;
      Boolean is_equal;

    case (_, _, {}, _) then listReverse(inAccumList);

    case (_, _, e :: rest, _)
      equation
        is_equal = inCompFunc(inValue, e);
        accum = consOnTrue(not is_equal, e, inAccumList);
      then
        removeOnTrue_tail(inValue, inCompFunc, rest, accum);

  end match;
end removeOnTrue_tail;

public function select
  "This function retrieves all elements of a list for which the given function
   evaluates to true. The elements that evaluates to false are thus removed
   from the list."
  input list<ElementType> inList;
  input SelectFunc inFunc;
  output list<ElementType> outList;

  partial function SelectFunc
    input ElementType inElement;
    output Boolean outSelect;
  end SelectFunc;
algorithm
  outList := select_tail(inList, inFunc, {});
end select;

public function select_tail
  "Tail recursive implementation of select."
  input list<ElementType> inList;
  input SelectFunc inFunc;
  input list<ElementType> inAccum;
  output list<ElementType> outList;

  partial function SelectFunc
    input ElementType inElement;
    output Boolean outSelect;
  end SelectFunc;
algorithm
  outList := match(inList, inFunc, inAccum)
    local
      ElementType e;
      list<ElementType> rest;
      Boolean res;

    case ({}, _, _) then listReverse(inAccum);

    case (e :: rest, _, _)
      equation
        res = inFunc(e);
      then
        select_tail(rest, inFunc, consOnTrue(res, e , inAccum));
  end match;
end select_tail;

public function selectFirst
  "This function retrieves the first element of a list for which the passed
   function evaluates to true."
  input list<ElementType> inList;
  input SelectFunc inFunc;
  output ElementType outElement;

  partial function SelectFunc
    input ElementType inElement;
    output Boolean outSelect;
  end SelectFunc;
algorithm
  outElement := match (inList, inFunc)
    local
      ElementType e;
      list<ElementType> rest;
      Boolean b;

    case (e :: rest, _)
      equation
        b = inFunc(e);
        e = Debug.bcallret2(not b,selectFirst,rest,inFunc,e);
      then e;

  end match;
end selectFirst;

public function selectFirst1
  "This function retrieves the first element of a list for which the passed
   function evaluates to true."
  input list<ElementType> inList;
  input SelectFunc inFunc;
  input ArgType1 arg1;
  output ElementType outElement;

  partial function SelectFunc
    input ElementType inElement;
    input ArgType1 arg;
    output Boolean outSelect;
  end SelectFunc;
algorithm
  outElement := match (inList, inFunc, arg1)
    local
      ElementType e;
      list<ElementType> rest;
      Boolean b;

    case (e :: rest, _, _)
      equation
        b = inFunc(e,arg1);
        e = Debug.bcallret3(not b,selectFirst1,rest,inFunc,arg1,e);
      then e;

  end match;
end selectFirst1;

public function select1
  "This function retrieves all elements of a list for which the given function
   evaluates to true. The elements that evaluates to false are thus removed
   from the list. This function has an extra argument to the testing function."
  input list<ElementType> inList;
  input SelectFunc inFunc;
  input ArgType1 inArg1;
  output list<ElementType> outList;

  partial function SelectFunc
    input ElementType inElement;
    input ArgType1 inArg1;
    output Boolean outSelect;
  end SelectFunc;
algorithm
  outList := select1_tail(inList, inFunc, inArg1, {});
end select1;

public function select1_tail
  "Tail recursive implementation of select1."
  input list<ElementType> inList;
  input SelectFunc inFunc;
  input ArgType1 inArg1;
  input list<ElementType> inAccum;
  output list<ElementType> outList;

  partial function SelectFunc
    input ElementType inElement;
    input ArgType1 inArg1;
    output Boolean outSelect;
  end SelectFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inAccum)
    local
      ElementType e;
      list<ElementType> rest;
      Boolean res;

    case ({}, _, _, _) then listReverse(inAccum);

    case (e :: rest, _, _, _)
      equation
        res = inFunc(e, inArg1);
      then
        select1_tail(rest, inFunc, inArg1, consOnTrue(res, e ,inAccum));
  end match;
end select1_tail;

public function select1r
  "Same as select1, but with swapped arguments."
  input list<ElementType> inList;
  input SelectFunc inFunc;
  input ArgType1 inArg1;
  output list<ElementType> outList;

  partial function SelectFunc
    input ArgType1 inArg1;
    input ElementType inElement;
    output Boolean outSelect;
  end SelectFunc;
algorithm
  outList := select1r_tail(inList, inFunc, inArg1, {});
end select1r;

public function select1r_tail
  "Tail recursive implementation of select1r."
  input list<ElementType> inList;
  input SelectFunc inFunc;
  input ArgType1 inArg1;
  input list<ElementType> inAccum;
  output list<ElementType> outList;

  partial function SelectFunc
    input ArgType1 inArg1;
    input ElementType inElement;
    output Boolean outSelect;
  end SelectFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inAccum)
    local
      ElementType e;
      list<ElementType> rest;
      Boolean res;

    case ({}, _, _, _) then listReverse(inAccum);

    case (e :: rest, _, _, _)
      equation
        res = inFunc(inArg1, e);
      then
        select1r_tail(rest, inFunc, inArg1, consOnTrue(res, e, inAccum));
  end match;
end select1r_tail;

public function select2
  "This function retrieves all elements of a list for which the given function
   evaluates to true. The elements that evaluates to false are thus removed
   from the list. This function has two extra arguments to the testing function."
  input list<ElementType> inList;
  input SelectFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  output list<ElementType> outList;

  partial function SelectFunc
    input ElementType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output Boolean outSelect;
  end SelectFunc;
algorithm
  outList := select2_tail(inList, inFunc, inArg1, inArg2, {});
end select2;

public function select2_tail
  "Tail recursive implementation of select2."
  input list<ElementType> inList;
  input SelectFunc inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input list<ElementType> inAccum;
  output list<ElementType> outList;

  partial function SelectFunc
    input ElementType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output Boolean outSelect;
  end SelectFunc;
algorithm
  outList := match(inList, inFunc, inArg1, inArg2, inAccum)
    local
      ElementType e;
      list<ElementType> rest;
      Boolean res;

    case ({}, _, _, _, _) then listReverse(inAccum);

    case (e :: rest, _, _, _, _)
      equation
        res = inFunc(e, inArg1, inArg2);
      then
        select2_tail(rest, inFunc, inArg1, inArg2,
          consOnTrue(res, e, inAccum));
  end match;
end select2_tail;

public function deleteMember
  "Takes a list and a value, and deletes the first occurence of the value in the
   list. Example: deleteMember({1, 2, 3, 2}, 2) => {1, 3, 2}"
  input list<ElementType> inList;
  input ElementType inElement;
  output list<ElementType> outList;
algorithm
  outList := matchcontinue(inList, inElement)

    case (_, _) then listDelete(inList, position(inElement, inList));
    else inList;

  end matchcontinue;
end deleteMember;

public function deleteMemberF
  "Same as deleteMember, but fails if the element isn't present in the list."
  input list<ElementType> inList;
  input ElementType inElement;
  output list<ElementType> outList;
algorithm
  outList := listDelete(inList, position(inElement, inList));
end deleteMemberF;

public function deleteMemberOnTrue
  "Takes a list and a value and a comparison function and deletes the first
  occurence of the value in the list for which the function returns true. It
  returns the new list and the deleted element, or only the original list if
  no element was removed.
    Example: deleteMemberOnTrue({1,2,3,2},2,intEq) => {1,3,2}"
  input ValueType inValue;
  input list<ElementType> inList;
  input CompareFunc inCompareFunc;
  output list<ElementType> outList;
  output Option<ElementType> outDeletedElement;

  partial function CompareFunc
    input ValueType inValue;
    input ElementType inElement;
    output Boolean outIsEqual;
  end CompareFunc;
algorithm
  (outList, outDeletedElement) := matchcontinue(inValue, inList, inCompareFunc)
    local
      ElementType e;
      list<ElementType> el;
      Boolean is_equal;

    case (_, e :: _, _)
      equation
        is_equal = inCompareFunc(inValue, e);
        (el, e) = deleteMemberOnTrue_tail(inValue, inList, inCompareFunc,
          {}, is_equal);
      then
        (el, SOME(e));

    else then (inList, NONE());
  end matchcontinue;
end deleteMemberOnTrue;

public function deleteMemberOnTrue_tail
  input ValueType inValue;
  input list<ElementType> inList;
  input CompareFunc inCompareFunc;
  input list<ElementType> inAccumList;
  input Boolean inIsEqual;
  output list<ElementType> outList;
  output ElementType outDeletedElement;

  partial function CompareFunc
    input ValueType inValue;
    input ElementType inElement;
    output Boolean outIsEqual;
  end CompareFunc;
algorithm
  (outList, outDeletedElement) :=
  match(inValue, inList, inCompareFunc, inAccumList, inIsEqual)
    local
      ElementType e, e2;
      list<ElementType> el, accum_el;
      Boolean is_equal;

    case (_, e :: el, _, _, true)
      then (listAppend(listReverse(inAccumList), el), e);

    case (_, e :: (el as e2 :: _), _, _, _)
      equation
        accum_el = e :: inAccumList;
        is_equal = inCompareFunc(inValue, e2);
        (el, e) = deleteMemberOnTrue_tail(inValue, el, inCompareFunc,
          accum_el, is_equal);
      then
        (el, e);
  end match;
end deleteMemberOnTrue_tail;

public function deletePositions
  "Takes a list and a list of positions, and deletes the positions from the
   list. Note that positions are indexed from 0.
     Example: deletePositions({1, 2, 3, 4, 5}, {2, 0, 3}) => {2, 5}"
  input list<ElementType> inList;
  input list<Integer> inPositions;
  output list<ElementType> outList;
protected
  list<Integer> sorted_pos;
algorithm
  sorted_pos := sort(inPositions, intGt);
  outList := deletePositionsSorted2(inList, sorted_pos, 0, {});
end deletePositions;

public function deletePositionsSorted
  "Takes a list and a sorted list of positions (smallest index first), and
   deletes the positions from the list. Note that positions are indexed from 0.
     Example: deletePositionsSorted({1, 2, 3, 4, 5}, {0, 2, 3}) => {2, 5}"
  input list<ElementType> inList;
  input list<Integer> inPositions;
  output list<ElementType> outList;
algorithm
  outList := deletePositionsSorted2(inList, inPositions, 0, {});
end deletePositionsSorted;

protected function deletePositionsSorted2
  "Helper function to deletePositionsSorted."
  input list<ElementType> inList;
  input list<Integer> inPositions;
  input Integer inIndex;
  input list<ElementType> inAccumList;
  output list<ElementType> outList;
algorithm
  outList := matchcontinue(inList, inPositions, inIndex, inAccumList)
    local
      ElementType e;
      list<ElementType> rest;
      Integer pos;
      list<Integer> rest_pos;

    case (_, {}, _, _) then listAppend(listReverse(inAccumList), inList);
    case (e :: rest, pos :: rest_pos, _, _)
      equation
        // Matching index, remove.
        true = pos == inIndex;
        // Allows duplicate position elements.
        rest_pos = removeMatchesFirst(rest_pos, inIndex);
      then
        deletePositionsSorted2(rest, rest_pos, inIndex + 1, inAccumList);

     case (e :: rest, _, _, _)
       then deletePositionsSorted2(rest, inPositions, inIndex + 1, e :: inAccumList);

  end matchcontinue;
end deletePositionsSorted2;

public function removeMatchesFirst
  "Removes all matching integers that occur first in a list. If the first
   element doesn't match it returns the list."
  input list<Integer> inList;
  input Integer inN;
  output list<Integer> outList;
algorithm
  outList := matchcontinue(inList, inN)
    local
      Integer n;
      list<Integer> rest;

    case (n :: rest, _)
      equation
        true = n == inN;
        rest = removeMatchesFirst(rest, inN);
      then
        rest;

    else inList;
  end matchcontinue;
end removeMatchesFirst;

public function replaceAt
  "Takes an element, a position and a list, and replaces the value at the given
   position in the list. Position is an integer between 0 and n - 1 for a list of
   n elements.
     Example: replaceAt('A', 2, {'a', 'b', 'c'}) => {'a', 'b', 'A'}"
  input ElementType inElement;
  input Integer inPosition;
  input list<ElementType> inList;
  output list<ElementType> outList;
algorithm
  outList := match(inElement, inPosition, inList)
    local
      ElementType e;
      list<ElementType> rest;

    case (_, 0, e :: rest) then inElement :: rest;
    case (_, _, e :: rest)
      equation
        (inPosition >= 1) = true;
        rest = replaceAt(inElement, inPosition - 1, rest);
      then
        e :: rest;
  end match;
end replaceAt;

public function replaceAtWithList
  "Takes an list, a position and a list, and replaces the element at the given
  position with the first list in the second list. Position is an integer
  between 0 and n - 1 for a list of n elements.
     Example: replaceAt({'A', 'B'}, 1, {'a', 'b', 'c'}) => {'a', 'A', 'B', 'c'}"
  input list<ElementType> inReplacementList;
  input Integer inPosition;
  input list<ElementType> inList;
  output list<ElementType> outList;
algorithm
  outList := match(inReplacementList, inPosition, inList)
    local
      ElementType e;
      list<ElementType> rest;

    case (_, 0, e :: rest) then listAppend(inReplacementList, rest);
    case (_, _, e :: rest)
      equation
        (inPosition >= 1) = true;
        rest = replaceAtWithList(inReplacementList, inPosition - 1, rest);
      then
        e :: rest;
  end match;
end replaceAtWithList;

public function replaceAtWithFill
  "Takes
   - an element,
   - a position
   - a list and
   - a fill value
   The function replaces the value at the given position in the list, if the
   given position is out of range, the fill value is used to padd the list up to
   that element position and then insert the value at the position
     Example: replaceAtWithFill(\"A\", 5, {\"a\",\"b\",\"c\"},\"dummy\") =>
              {\"a\",\"b\",\"c\",\"dummy\",\"A\"}"
  input ElementType inElement;
  input Integer inPosition;
  input list<ElementType> inList;
  input ElementType inFillValue;
  output list<ElementType> outList;
algorithm
  outList:= matchcontinue (inElement, inPosition, inList, inFillValue)
    local
      ElementType x, fillv, y;
      list<ElementType> ys, res, res_1;
      Integer numfills_1,numfills,nn,n,p;
      String pos;

    case (x, 0, {}, fillv) then {x};
    case (x, 0, (y :: ys), fillv) then (x :: ys);
    case (x, 1, {}, fillv) then {fillv, x};

    case (x, numfills, {}, fillv)
      equation
        (numfills > 1) = true;
        numfills_1 = numfills - 1;
        res = fill_tail(fillv, numfills_1, {});
        res_1 = listReverse(x :: res);
      then
        res_1;

    case (x, n, (y :: ys), fillv)
      equation
        (n >= 1) = true;
        nn = n - 1;
        res = replaceAtWithFill(x, nn, ys, fillv);
      then
        (y :: res);

    case (_,p,_,_)
      equation
        print("- List.replaceAtWithFill failed row: ");
        pos = intString(p);
        print(pos);
        print("\n");
      then
        fail();

  end matchcontinue;
end replaceAtWithFill;

public function toString
  "Creates a string from a list and a function that maps a list element to a
   string. It also takes several parameters that determine the formatting of
   the string. Ex:
     toString({1, 2, 3}, intString, 'nums', '{', ';', '}, true) =>
     'nums{1;2;3}'
  "
  input list<ElementType> inList;
  input FuncType inPrintFunc;
  input String inListNameStr "The name of the list.";
  input String inBeginStr "The start of the list";
  input String inDelimitStr "The delimiter between list elements.";
  input String inEndStr "The end of the list.";
  input Boolean inPrintEmpty "If false, don't output begin and end if the list is empty.";
  output String outString;

  replaceable type ElementType subtypeof Any;

  partial function FuncType
    input ElementType inElement;
    output String outString;
  end FuncType;
algorithm
  outString := match(inList, inPrintFunc, inListNameStr, inBeginStr,
      inDelimitStr, inEndStr, inPrintEmpty)
    local
      String str;

    // Empty list and inPrintEmpty true => concatenate the list name, begin
    // string and end string.
    case ({}, _, _, _, _, _, true)
      then stringAppendList({inListNameStr, inBeginStr, inEndStr});

    // Empty list and inPrintEmpty false => output only list name.
    case ({}, _, _, _, _, _, false)
      then inListNameStr;

    else
      equation
        str = stringDelimitList(map(inList, inPrintFunc), inDelimitStr);
        str = stringAppendList({inListNameStr, inBeginStr, str, inEndStr});
      then
        str;

  end match;
end toString;

public function hasOneElement
"@author:adrpo
 returns true if the list has exactly one element, otherwise false"
  input list<ElementType> inList;
  output Boolean b;
algorithm
  b := match(inList)
    local ElementType x;
    case ({x}) then true;
    case (_) then false;
  end match;
end hasOneElement;

public function hasSeveralElements
"author:waurich
 returns true if the list has more than one element, otherwise false"
  input list<ElementType> inList;
  output Boolean b;
algorithm
  b := match(inList)
    local ElementType x;
    case ({x}) then false;
    case ({}) then false;
    else then true;
  end match;
end hasSeveralElements;

public function lengthListElements
  input list<list<Type_a>> inListList;
  output Integer outLength;
  replaceable type Type_a subtypeof Any;
algorithm
  outLength := lengthListElementsHelp(inListList, 0);
end lengthListElements;

public function lengthListElementsHelp
  input list<list<Type_a>> inListList;
  input Integer inLength;
  output Integer outLength;
  replaceable type Type_a subtypeof Any;
algorithm
  outLength := match(inListList, inLength)
  local
    list<list<Type_a>> rest;
    list<Type_a> a;
    Integer i;
    case({},_) then inLength;
    case(a::rest, _)
      equation
        i = inLength+listLength(a);
        outLength = lengthListElementsHelp(rest, i);
      then outLength;
  end match;
end lengthListElementsHelp;

public function generate
  "This function generates a list by calling the given function with the given
   argument. The elements generated by the function are accumulated in a list
   until the function returns false as the last return value."
  input ArgType1 inArg;
  input GenerateFunc inFunc;
  output list<ElementType> outList;

  partial function GenerateFunc
    input ArgType1 inArg;
    output ArgType1 outArg;
    output ElementType outElement;
    output Boolean outContinue;
  end GenerateFunc;
algorithm
  outList := listReverse(generate_tail(inArg, inFunc, {}));
end generate;

public function generateReverse
  "This function generates a list by calling the given function with the given
   argument. The elements generated by the function are accumulated in a list
   until the function returns false as the last return value. This function
   returns the generated list reversed."
  input ArgType1 inArg;
  input GenerateFunc inFunc;
  output list<ElementType> outList;

  partial function GenerateFunc
    input ArgType1 inArg;
    output ArgType1 outArg;
    output ElementType outElement;
    output Boolean outContinue;
  end GenerateFunc;
algorithm
  outList := generate_tail(inArg, inFunc, {});
end generateReverse;

protected function generate_tail
  input ArgType1 inArg;
  input GenerateFunc inFunc;
  input list<ElementType> inAccumList;
  output list<ElementType> outList;

  partial function GenerateFunc
    input ArgType1 inArg;
    output ArgType1 outArg;
    output ElementType outElement;
    output Boolean outContinue;
  end GenerateFunc;
protected
  ArgType1 arg;
  ElementType el;
  Boolean cont;
algorithm
  (arg, el, cont) := inFunc(inArg);
  outList := generate_tail2(arg, inFunc, el, cont, inAccumList);
end generate_tail;

protected function generate_tail2
  input ArgType1 inArg;
  input GenerateFunc inFunc;
  input ElementType inElement;
  input Boolean inContinue;
  input list<ElementType> inAccumList;
  output list<ElementType> outList;

  partial function GenerateFunc
    input ArgType1 inArg;
    output ArgType1 outArg;
    output ElementType outElement;
    output Boolean outContinue;
  end GenerateFunc;
algorithm
  outList := match(inArg, inFunc, inElement, inContinue, inAccumList)
    case (_, _, _, true, _)
      then generate_tail(inArg, inFunc, inElement :: inAccumList);

    else inAccumList;
  end match;
end generate_tail2;

public function mapFoldSplit
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input FoldFunc inFoldFunc;
  input FoldType inStartValue;
  output list<ElementOutType> outList;
  output FoldType outResult;

  partial function MapFunc
    input ElementInType inElem;
    output ElementOutType outElem;
    output FoldType outResult;
  end MapFunc;

  partial function FoldFunc
    input FoldType inNewValue;
    input FoldType inOldValue;
    output FoldType outFoldedValue;
  end FoldFunc;
algorithm
  (outList, outResult) :=
    mapFoldSplit_tail(inList, inMapFunc, inFoldFunc, inStartValue, {});
end mapFoldSplit;

public function mapFoldSplit_tail
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input FoldFunc inFoldFunc;
  input FoldType inStartValue;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;
  output FoldType outResult;

  partial function MapFunc
    input ElementInType inElem;
    output ElementOutType outElem;
    output FoldType outResult;
  end MapFunc;

  partial function FoldFunc
    input FoldType inNewValue;
    input FoldType inOldValue;
    output FoldType outFoldedValue;
  end FoldFunc;
algorithm
  (outList, outResult) :=
  match(inList, inMapFunc, inFoldFunc, inStartValue, inAccumList)
    local
      ElementInType ie1;
      list<ElementInType> rest_ie1;
      ElementOutType oe1;
      list<ElementOutType> rest_oe1, acc;
      FoldType res;

    case (ie1 :: rest_ie1, _, _, _, acc)
      equation
        (oe1, res) = inMapFunc(ie1);
        res = inFoldFunc(res, inStartValue);
        acc = oe1 :: acc;
        (acc, res) = mapFoldSplit_tail(rest_ie1, inMapFunc, inFoldFunc, res, acc);
      then
        (acc, res);

    case ({}, _, _, _, _) then (listReverse(inAccumList), inStartValue);

  end match;
end mapFoldSplit_tail;

public function map1FoldSplit
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input FoldFunc inFoldFunc;
  input ArgType1 inConstArg;
  input FoldType inStartValue;
  output list<ElementOutType> outList;
  output FoldType outResult;

  partial function MapFunc
    input ElementInType inElem;
    input ArgType1 inConstArg;
    output ElementOutType outElem;
    output FoldType outResult;
  end MapFunc;

  partial function FoldFunc
    input FoldType inNewValue;
    input FoldType inOldValue;
    output FoldType outFoldedValue;
  end FoldFunc;
algorithm
  (outList, outResult) :=
    map1FoldSplit_tail(inList, inMapFunc, inFoldFunc, inConstArg, inStartValue, {});
end map1FoldSplit;

public function map1FoldSplit_tail
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input FoldFunc inFoldFunc;
  input ArgType1 inConstArg;
  input FoldType inStartValue;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;
  output FoldType outResult;

  partial function MapFunc
    input ElementInType inElem;
    input ArgType1 inConstArg;
    output ElementOutType outElem;
    output FoldType outResult;
  end MapFunc;

  partial function FoldFunc
    input FoldType inNewValue;
    input FoldType inOldValue;
    output FoldType outFoldedValue;
  end FoldFunc;
algorithm
  (outList, outResult) :=
  match(inList, inMapFunc, inFoldFunc, inConstArg, inStartValue, inAccumList)
    local
      ElementInType ie1;
      list<ElementInType> rest_ie1;
      ElementOutType oe1;
      list<ElementOutType> rest_oe1, acc;
      FoldType res;

    case (ie1 :: rest_ie1, _, _, _, _, acc)
      equation
        (oe1, res) = inMapFunc(ie1, inConstArg);
        res = inFoldFunc(res, inStartValue);
        acc = oe1 :: acc;
        (acc, res) =
          map1FoldSplit_tail(rest_ie1, inMapFunc, inFoldFunc, inConstArg, res, acc);
      then
        (acc, res);

    case ({}, _, _, _, _, _) then (listReverse(inAccumList), inStartValue);

  end match;
end map1FoldSplit_tail;

public function accumulateMap
  "Takes a list and a function. The function is applied to each element in the
   list, and the function is itself responsible for adding elements to the
   result list."
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input list<ElementOutType> inAccumList;
    output list<ElementOutType> outList;
  end MapFunc;
algorithm
  outList := listReverse(accumulateMapAccum(inList, inMapFunc, {}));
end accumulateMap;

public function accumulateMapReverse
  "Takes a list and a function. The function is applied to each element in the
   list, and the function is itself responsible for adding elements to the
   result list."
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input list<ElementOutType> inAccumList;
    output list<ElementOutType> outList;
  end MapFunc;
algorithm
  outList := accumulateMapAccum(inList, inMapFunc, {});
end accumulateMapReverse;

public function accumulateMapAccum
  "Takes a list, a function and a result list. The function is applied to each
   element of the list, and the function is itself responsible for adding
   elements to the result list."
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input list<ElementOutType> inAccumList;
    output list<ElementOutType> outList;
  end MapFunc;
algorithm
  outList := match(inList, inMapFunc, inAccumList)
    local
      ElementInType e;
      list<ElementInType> rest_e;
      list<ElementOutType> accum;

    case (e :: rest_e, _, accum)
      equation
        accum = inMapFunc(e, accum);
      then
        accumulateMapAccum(rest_e, inMapFunc, accum);

    case ({}, _, _) then inAccumList;
  end match;
end accumulateMapAccum;

public function accumulateMapAccum1
  "Takes a list, a function, an extra argument, and a result list. The function
   is applied to each element of the list, and the function is itself responsible
   for adding elements to the result list."
  input list<ElementInType> inList;
  input MapFunc inMapFunc;
  input ArgType1 inArg;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;

  partial function MapFunc
    input ElementInType inElement;
    input ArgType1 inArg;
    input list<ElementOutType> inAccumList;
    output list<ElementOutType> outList;
  end MapFunc;
algorithm
  outList := match(inList, inMapFunc, inArg, inAccumList)
    local
      ElementInType e;
      list<ElementInType> rest_e;
      list<ElementOutType> accum;

    case (e :: rest_e, _, _, accum)
      equation
        accum = inMapFunc(e, inArg, accum);
      then
        accumulateMapAccum1(rest_e, inMapFunc, inArg, accum);

    case ({}, _, _, _) then inAccumList;
  end match;
end accumulateMapAccum1;

public function accumulateMapFold
  input list<ElementInType> inList;
  input FuncType inFunc;
  input FoldType inFoldArg;
  output list<ElementOutType> outList;
  output FoldType outFoldArg;

  partial function FuncType
    input ElementInType inElement;
    input FoldType inFoldArg;
    input list<ElementOutType> inAccumList;
    output list<ElementOutType> outList;
    output FoldType outFoldArg;
  end FuncType;
algorithm
  (outList, outFoldArg) := accumulateMapFoldAccum(inList, inFunc, inFoldArg, {});
end accumulateMapFold;

public function accumulateMapFoldAccum
  input list<ElementInType> inList;
  input FuncType inFunc;
  input FoldType inFoldArg;
  input list<ElementOutType> inAccumList;
  output list<ElementOutType> outList;
  output FoldType outFoldArg;

  partial function FuncType
    input ElementInType inElement;
    input FoldType inFoldArg;
    input list<ElementOutType> inAccumList;
    output list<ElementOutType> outList;
    output FoldType outFoldArg;
  end FuncType;
algorithm
  (outList, outFoldArg) := match(inList, inFunc, inFoldArg, inAccumList)
    local
      ElementInType e;
      list<ElementInType> rest_e;
      list<ElementOutType> accum;
      FoldType fold_arg;

    case (e :: rest_e, _, _, accum)
      equation
        (accum, fold_arg) = inFunc(e, inFoldArg, accum);
        (accum, fold_arg) = accumulateMapFoldAccum(rest_e, inFunc, fold_arg, accum);
      then
        (accum, fold_arg);

    case ({}, _, _, _) then (inAccumList, inFoldArg);

  end match;
end accumulateMapFoldAccum;

public function first2FromTuple3
  input tuple<ElementInType, ElementInType, ElementType> inTuple;
  output list<ElementInType> outList;
protected
  ElementInType a, b;
algorithm
  (a, b, _) := inTuple;
  outList := {a,b};
end first2FromTuple3;

public function findMap
  "Same as map, but stops when it find a certain element as indicated by the
   mapping function. Returns the new list, and whether the element was found or
   not."
  input list<ElementType> inList;
  input FuncType inFunc;
  output list<ElementType> outList;
  output Boolean outFound;

  partial function FuncType
    input ElementType inElement;
    output ElementType outElement;
    output Boolean outFound;
  end FuncType;
algorithm
  (outList, outFound) := findMap_tail(false, inList, inFunc, {});
end findMap;

public function findMap_tail
  input Boolean inFound;
  input list<ElementType> inList;
  input FuncType inFunc;
  input list<ElementType> inAccum;
  output list<ElementType> outList;
  output Boolean outFound;

  partial function FuncType
    input ElementType inElement;
    output ElementType outElement;
    output Boolean outFound;
  end FuncType;
algorithm
  (outList, outFound) := match(inFound, inList, inFunc, inAccum)
    local
      ElementType head;
      list<ElementType> rest, accum;
      Boolean found;

    case (false, head :: rest, _, accum)
      equation
        (head, found) = inFunc(head);
        (accum, found) = findMap_tail(found, rest, inFunc, head :: accum);
      then
        (accum, found);

    case (true, _, _, _) then (listAppend(listReverse(inAccum), inList), true);
    case (_, {}, _, _) then (listReverse(inAccum), false);

  end match;
end findMap_tail;

public function findMap1
  "Same as map1, but stops when it find a certain element as indicated by the
   mapping function. Returns the new list, and whether the element was found or
   not."
  input list<ElementType> inList;
  input FuncType inFunc;
  input ArgType1 inArg1;
  output list<ElementType> outList;
  output Boolean outFound;

  partial function FuncType
    input ElementType inElement;
    input ArgType1 inArg1;
    output ElementType outElement;
    output Boolean outFound;
  end FuncType;
algorithm
  (outList, outFound) := findMap1_tail(false, inList, inFunc, inArg1, {});
end findMap1;

public function findMap1_tail
  input Boolean inFound;
  input list<ElementType> inList;
  input FuncType inFunc;
  input ArgType1 inArg1;
  input list<ElementType> inAccum;
  output list<ElementType> outList;
  output Boolean outFound;

  partial function FuncType
    input ElementType inElement;
    input ArgType1 inArg1;
    output ElementType outElement;
    output Boolean outFound;
  end FuncType;
algorithm
  (outList, outFound) := match(inFound, inList, inFunc, inArg1, inAccum)
    local
      ElementType head;
      list<ElementType> rest, accum;
      Boolean found;

    case (false, head :: rest, _, _, accum)
      equation
        (head, found) = inFunc(head, inArg1);
        (accum, found) = findMap1_tail(found, rest, inFunc, inArg1, head :: accum);
      then
        (accum, found);

    case (true, _, _, _, _) then (listAppend(listReverse(inAccum), inList), true);
    case (_, {}, _, _, _) then (listReverse(inAccum), false);

  end match;
end findMap1_tail;

public function findMap2
  "Same as map2, but stops when it find a certain element as indicated by the
   mapping function. Returns the new list, and whether the element was found or
   not."
  input list<ElementType> inList;
  input FuncType inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  output list<ElementType> outList;
  output Boolean outFound;

  partial function FuncType
    input ElementType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output ElementType outElement;
    output Boolean outFound;
  end FuncType;
algorithm
  (outList, outFound) := findMap2_tail(false, inList, inFunc, inArg1, inArg2, {});
end findMap2;

public function findMap2_tail
  input Boolean inFound;
  input list<ElementType> inList;
  input FuncType inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input list<ElementType> inAccum;
  output list<ElementType> outList;
  output Boolean outFound;

  partial function FuncType
    input ElementType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    output ElementType outElement;
    output Boolean outFound;
  end FuncType;
algorithm
  (outList, outFound) := match(inFound, inList, inFunc, inArg1, inArg2, inAccum)
    local
      ElementType head;
      list<ElementType> rest, accum;
      Boolean found;

    case (false, head :: rest, _, _, _, accum)
      equation
        (head, found) = inFunc(head, inArg1, inArg2);
        (accum, found) = findMap2_tail(found, rest, inFunc, inArg1, inArg2, head :: accum);
      then
        (accum, found);

    case (true, _, _, _, _, _) then (listAppend(listReverse(inAccum), inList), true);
    case (_, {}, _, _, _, _) then (listReverse(inAccum), false);

  end match;
end findMap2_tail;

public function findMap3
  "Same as map3, but stops when it find a certain element as indicated by the
   mapping function. Returns the new list, and whether the element was found or
   not."
  input list<ElementType> inList;
  input FuncType inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  output list<ElementType> outList;
  output Boolean outFound;

  partial function FuncType
    input ElementType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    output ElementType outElement;
    output Boolean outFound;
  end FuncType;
algorithm
  (outList, outFound) := findMap3_tail(false, inList, inFunc, inArg1, inArg2, inArg3, {});
end findMap3;

public function findMap3_tail
  input Boolean inFound;
  input list<ElementType> inList;
  input FuncType inFunc;
  input ArgType1 inArg1;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input list<ElementType> inAccum;
  output list<ElementType> outList;
  output Boolean outFound;

  partial function FuncType
    input ElementType inElement;
    input ArgType1 inArg1;
    input ArgType2 inArg2;
    input ArgType3 inArg3;
    output ElementType outElement;
    output Boolean outFound;
  end FuncType;
algorithm
  (outList, outFound) := match(inFound, inList, inFunc, inArg1, inArg2, inArg3, inAccum)
    local
      ElementType head;
      list<ElementType> rest, accum;
      Boolean found;

    case (false, head :: rest, _, _, _, _, accum)
      equation
        (head, found) = inFunc(head, inArg1, inArg2, inArg3);
        (accum, found) = findMap3_tail(found, rest, inFunc, inArg1, inArg2, inArg3, head :: accum);
      then
        (accum, found);

    case (true, _, _, _, _, _, _) then (listAppend(listReverse(inAccum), inList), true);
    case (_, {}, _, _, _, _, _) then (listReverse(inAccum), false);

  end match;
end findMap3_tail;

public function splitEqualPrefix
  input list<ElementType1> inFullList;
  input list<ElementType2> inPrefixList;
  input EqFunc inEqFunc;
  output list<ElementType1> outPrefix;
  output list<ElementType1> outRest;

  partial function EqFunc
    input ElementType1 inElem1;
    input ElementType2 inElem2;
    output Boolean outIsEqual;
  end EqFunc;
algorithm
  (outPrefix, outRest) :=
    splitEqualPrefix_tail(inFullList, inPrefixList, inEqFunc, {});
end splitEqualPrefix;

public function splitEqualPrefix_tail
  input list<ElementType1> inFullList;
  input list<ElementType2> inPrefixList;
  input EqFunc inEqFunc;
  input list<ElementType1> inAccum;
  output list<ElementType1> outPrefix;
  output list<ElementType1> outRest;

  partial function EqFunc
    input ElementType1 inElem1;
    input ElementType2 inElem2;
    output Boolean outIsEqual;
  end EqFunc;
algorithm
  (outPrefix, outRest) := matchcontinue(inFullList, inPrefixList, inEqFunc, inAccum)
    local
      ElementType1 e1;
      ElementType2 e2;
      list<ElementType1> rest_e1, prefix, rest;
      list<ElementType2> rest_e2;

    case (e1 :: rest_e1, e2 :: rest_e2, _, _)
      equation
        true = inEqFunc(e1, e2);
        (prefix, rest) = splitEqualPrefix_tail(rest_e1, rest_e2, inEqFunc, e1 :: inAccum);
      then
        (prefix, rest);

    else (listReverse(inAccum), inFullList);

  end matchcontinue;
end splitEqualPrefix_tail;

public function combinationMap
  "Takes a two-dimensional list and calls the given function on the combinations
   given by the cartesian product of the sublists.

    Ex: combinationMap({{1, 2}, {3}, {4, 5}}, func) =>
      {func({1, 3, 4}), func({1, 3, 5}), func({2, 3, 4}), func({2, 3, 5})}
  "
  input list<list<ElementInType>> inElements;
  input MapFunc inMapFunc;
  output list<ElementOutType> outElements;

  partial function MapFunc
    input list<ElementInType> inElements;
    output ElementOutType outElement;
  end MapFunc;
protected
  list<list<ElementInType>> elems;
algorithm
  elems := listReverse(inElements);
  outElements := combinationMap_tail(elems, inMapFunc, {}, {});
end combinationMap;

protected function combinationMap_tail
  input list<list<ElementInType>> inElements;
  input MapFunc inMapFunc;
  input list<ElementInType> inCombination;
  input list<ElementOutType> inAccumElems;
  output list<ElementOutType> outElements;
 
  partial function MapFunc
    input list<ElementInType> inElements;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outElements := match(inElements, inMapFunc, inCombination, inAccumElems)
    local
      ElementOutType elem;
      list<ElementInType> head;
      list<list<ElementInType>> rest;

    case ({}, _, _, _)
      equation
        elem = inMapFunc(inCombination);
      then
        elem :: inAccumElems;

    case (head :: rest, _, _, _)
      then combinationMap_tail2(head, rest, inMapFunc, inCombination, inAccumElems);

  end match;
end combinationMap_tail;

protected function combinationMap_tail2
  input list<ElementInType> inHead;
  input list<list<ElementInType>> inRest;
  input MapFunc inMapFunc;
  input list<ElementInType> inCombination;
  input list<ElementOutType> inAccumElems;
  output list<ElementOutType> outElements;

  partial function MapFunc
    input list<ElementInType> inElements;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outElements := match(inHead, inRest, inMapFunc, inCombination, inAccumElems)
    local
      ElementInType head;
      list<ElementInType> rest, comb;
      list<ElementOutType> accum;

    case (head :: rest, _, _, comb, accum)
      equation
        accum = combinationMap_tail(inRest, inMapFunc, head :: comb, accum);
        accum = combinationMap_tail2(rest, inRest, inMapFunc, comb, accum);
      then
        accum;

    case ({}, _, _, _, _)
      then inAccumElems;
        
  end match;
end combinationMap_tail2;

public function combinationMap1
  "Takes a two-dimensional list and calls the given function on the combinations
   given by the cartesian product of the sublists. Also takes an extra constant
   argument that is sent to the function.

   Ex: combinationMap({{1, 2}, {3}, {4, 5}}, func, x) =>
   {func({1, 3, 4}, x), func({1, 3, 5}, x), func({2, 3, 4}, x), func({2, 3, 5}, x)}
  "
  input list<list<ElementInType>> inElements;
  input MapFunc inMapFunc;
  input ArgType1 inArg;
  output list<ElementOutType> outElements;

  partial function MapFunc
    input list<ElementInType> inElements;
    input ArgType1 inArg;
    output ElementOutType outElement;
  end MapFunc;
protected
  list<list<ElementInType>> elems;
algorithm
  elems := listReverse(inElements);
  outElements := combinationMap1_tail(elems, inMapFunc, inArg, {}, {});
end combinationMap1;

protected function combinationMap1_tail
  input list<list<ElementInType>> inElements;
  input MapFunc inMapFunc;
  input ArgType1 inArg;
  input list<ElementInType> inCombination;
  input list<ElementOutType> inAccumElems;
  output list<ElementOutType> outElements;
 
  partial function MapFunc
    input list<ElementInType> inElements;
    input ArgType1 inArg;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outElements := match(inElements, inMapFunc, inArg, inCombination, inAccumElems)
    local
      ElementOutType elem;
      list<ElementInType> head;
      list<list<ElementInType>> rest;

    case ({}, _, _, _, _)
      equation
        elem = inMapFunc(inCombination, inArg);
      then
        elem :: inAccumElems;

    case (head :: rest, _, _, _, _)
      then combinationMap1_tail2(head, rest, inMapFunc, inArg, inCombination, inAccumElems);

  end match;
end combinationMap1_tail;

protected function combinationMap1_tail2
  input list<ElementInType> inHead;
  input list<list<ElementInType>> inRest;
  input MapFunc inMapFunc;
  input ArgType1 inArg;
  input list<ElementInType> inCombination;
  input list<ElementOutType> inAccumElems;
  output list<ElementOutType> outElements;

  partial function MapFunc
    input list<ElementInType> inElements;
    input ArgType1 inArg;
    output ElementOutType outElement;
  end MapFunc;
algorithm
  outElements := match(inHead, inRest, inMapFunc, inArg, inCombination, inAccumElems)
    local
      ElementInType head;
      list<ElementInType> rest, comb;
      list<ElementOutType> accum;

    case (head :: rest, _, _, _, comb, accum)
      equation
        accum = combinationMap1_tail(inRest, inMapFunc, inArg, head :: comb, accum);
        accum = combinationMap1_tail2(rest, inRest, inMapFunc, inArg, comb, accum);
      then
        accum;

    case ({}, _, _, _, _, _)
      then inAccumElems;
        
  end match;
end combinationMap1_tail2;

public function allReferenceEq "Checks if all elements in the lists have equal references"
  input list<ElementInType> lst1;
  input list<ElementInType> lst2;
  output Boolean b;
algorithm
  b := match (lst1,lst2)
    local
      ElementInType el1,el2;
      list<ElementInType> rest1,rest2;
    case ({},{}) then true;
    case (el1::rest1,el2::rest2) then referenceEq(el1,el2) and allReferenceEq(rest1,rest2);
    else false;
  end match;
end allReferenceEq;

public function removeEqualPrefix
  "Takes two lists and a comparison function and removes the heads from both
   lists as long as they are equal. Ex:
     removeEqualPrefix({1, 2, 3, 5, 7}, {1, 2, 3, 9, 7}) => ({5, 7}, {9, 7})"
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input CompFunc inCompFunc;
  output list<ElementType1> outList1;
  output list<ElementType2> outList2;

  partial function CompFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  (outList1, outList2) := match(inList1, inList2, inCompFunc)
    local
      ElementType1 e1;
      ElementType2 e2;
      Boolean is_eq;
      list<ElementType1> res1;
      list<ElementType2> res2;

    case (e1 :: _, e2 :: _, _)
      equation
        is_eq = inCompFunc(e1, e2);
        (res1, res2) = removeEqualPrefix2(is_eq, inList1, inList2, inCompFunc);
      then
        (res1, res2);

    else (inList1, inList2);

  end match;
end removeEqualPrefix;

public function removeEqualPrefix2
  "Helper function to removeEqualPrefix."
  input Boolean inIsEqual;
  input list<ElementType1> inList1;
  input list<ElementType2> inList2;
  input CompFunc inCompFunc;
  output list<ElementType1> outList1;
  output list<ElementType2> outList2;

  partial function CompFunc
    input ElementType1 inElement1;
    input ElementType2 inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  (outList1, outList2) := match(inIsEqual, inList1, inList2, inCompFunc)
    local
      ElementType1 e1;
      ElementType2 e2;
      list<ElementType1> rest_e1;
      list<ElementType2> rest_e2;

    case (true, _ :: rest_e1, _ :: rest_e2, _)
      equation
        (rest_e1, rest_e2) = removeEqualPrefix(rest_e1, rest_e2, inCompFunc);
      then
        (rest_e1, rest_e2);

    else (inList1, inList2);

  end match;
end removeEqualPrefix2;

public function listIsLonger  "outputs true if the lst1 is longer than lst2"
  input list<ElementType> lst1;
  input list<ElementType> lst2;
  output Boolean isLonger;
algorithm
  isLonger := intGt(listLength(lst1),listLength(lst2));
end listIsLonger;

public function toListWithPositions
  input list<ElementType> inList;
  input Integer curPos;
  input list<tuple<ElementType,Integer>> acc;
  output list<tuple<ElementType,Integer>> outList;
algorithm
  outList := match (inList,curPos,acc)
    local
      ElementType el;
      list<ElementType> rest;
    case ({},_,_) then listReverse(acc);
    case (el::rest,_,_) then toListWithPositions(rest,curPos+1,(el,curPos)::acc);
  end match;
end toListWithPositions;

public function mkOption
"@author: adrpo
 make NONE() if the list is empty
 make SOME(list) if the list is not empty"
  input list<ElementType> inList;
  output Option<list<ElementType>> outOption;
algorithm
  outOption := match(inList)
    case ({}) then NONE();
    case (_) then SOME(inList);
  end match;
end mkOption;

end List;
