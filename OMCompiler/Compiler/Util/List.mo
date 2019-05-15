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

encapsulated package List
" file:        List.mo
  package:     List
  description: List functions


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

protected
import Array;
import MetaModelica.Dangerous.{listReverseInPlace, arrayGetNoBoundsChecking, arrayUpdateNoBoundsChecking, arrayCreateNoInit};
import MetaModelica.Dangerous;
import DoubleEndedList;
import GC;

public function create<T>
  "Creates a list from an element."
  input T inElement;
  output list<T> outList = {inElement};
end create;

public function create2<T>
  "Creates a list from two elements."
  input T inElement1;
  input T inElement2;
  output list<T> outList = {inElement1, inElement2};
end create2;

public function fill<T>
  "Returns a list of n element.
     Example: fill(2, 3) => {2, 2, 2}"
  input T inElement;
  input Integer inCount;
  output list<T> outList = {};
protected
  Integer i = 0;
algorithm
  while i < inCount loop
    outList := inElement :: outList;
    i := i + 1;
  end while;
end fill;

public function intRange
  "Returns a list of n integers from 1 to inStop.
     Example: listIntRange(3) => {1,2,3}"
  input Integer inStop;
  output list<Integer> outRange = {};
protected
  Integer i = inStop;
algorithm
  while i > 0 loop
    outRange := i :: outRange;
    i := i - 1;
  end while;
end intRange;

public function intRange2
  "Returns a list of integers from inStart to inStop.
     Example listIntRange2(3,5) => {3,4,5}"
  input Integer inStart;
  input Integer inStop;
  output list<Integer> outRange = {};
protected
  Integer i = inStop;
algorithm
  if inStart < inStop then
    while i >= inStart loop
      outRange := i :: outRange;
      i := i - 1;
    end while;
  else
    while i <= inStart loop
      outRange := i :: outRange;
      i := i + 1;
    end while;
  end if;
end intRange2;

public function intRange3
  "Returns a list of integers from inStart to inStop with step inStep.
     Example: listIntRange2(3,2,9) => {3,5,7,9}"
  input Integer inStart;
  input Integer inStep;
  input Integer inStop;
  output list<Integer> outRange;
algorithm
  if inStep == 0 then fail(); end if;
  outRange := list(i for i in inStart:inStep:inStop);
end intRange3;

public function toOption<T>
  "Returns an option of the element in a list if the list contains exactly one
   element, NONE() if the list is empty and fails if the list contains more than
   one element."
  input list<T> inList;
  output Option<T> outOption;
algorithm
  outOption := match(inList)
    local
      T e;

    case {} then NONE();
    case {e} then SOME(e);
  end match;
end toOption;

public function fromOption<T>
  "Returns an empty list for NONE() and a list containing the element for
   SOME(element)."
  input Option<T> inElement;
  output list<T> outList;
algorithm
  outList := match(inElement)
    local
      T e;

    case SOME(e) then {e};
    else {};
  end match;
end fromOption;

public function assertIsEmpty<T>
  "Fails if the given list is not empty."
  input list<T> inList;
algorithm
  {} := inList;
end assertIsEmpty;

public function isEqual<T>
  "Checks if two lists are equal. If inEqualLength is true the lists are assumed
   to be of equal length, and if it is false they can be of different lengths (in
   which case only the overlapping parts of the lists are checked)."
  input list<T> inList1;
  input list<T> inList2;
  input Boolean inEqualLength;
  output Boolean outIsEqual;
algorithm
  outIsEqual := match(inList1, inList2, inEqualLength)
    local
      T e1, e2;
      list<T> rest1, rest2;

    case (e1 :: rest1, e2 :: rest2, _) guard(valueEq(e1, e2))
      then isEqual(rest1, rest2, inEqualLength);

    case ({}, {}, _) then true;
    case ({}, _, false) then true;
    case (_, {}, false) then true;
    else false;
  end match;
end isEqual;

public function isEqualOnTrue<T1, T2>
  "Takes two lists and an equality function, and returns whether the lists are
   equal or not."
  input list<T1> inList1;
  input list<T2> inList2;
  input CompFunc inCompFunc;
  output Boolean outIsEqual;

  partial function CompFunc
    input T1 inElement1;
    input T2 inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outIsEqual := match(inList1, inList2)
    local
      T1 e1;
      T2 e2;
      list<T1> rest1;
      list<T2> rest2;

    case (e1 :: rest1, e2 :: rest2) guard(inCompFunc(e1, e2))
      then isEqualOnTrue(rest1, rest2, inCompFunc);

    case ({}, {}) then true;
    else false;
  end match;
end isEqualOnTrue;

public function isPrefixOnTrue<T1, T2>
  "Checks if the first list is a prefix of the second list, i.e. that all
   elements in the first list is equal to the corresponding elements in the
   second list."
  input list<T1> inList1;
  input list<T2> inList2;
  input CompFunc inCompFunc;
  output Boolean outIsPrefix;

  partial function CompFunc
    input T1 inElement1;
    input T2 inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outIsPrefix := match(inList1, inList2)
    local
      T1 e1;
      list<T1> rest1;
      T2 e2;
      list<T2> rest2;

    case (e1 :: rest1, e2 :: rest2) guard(inCompFunc(e1, e2))
      then isPrefixOnTrue(rest1, rest2, inCompFunc);

    case ({}, _) then true;
    else false;
  end match;
end isPrefixOnTrue;

public function consr<T>
  "The same as the builtin cons operator, but with the order of the arguments
  swapped."
  input list<T> inList;
  input T inElement;
  output list<T> outList;
algorithm
  outList := inElement :: inList;
end consr;

public function consOnTrue<T>
  "Adds the element to the front of the list if the condition is true."
  input Boolean inCondition;
  input T inElement;
  input list<T> inList;
  output list<T> outList;
algorithm
  outList := if inCondition then inElement :: inList else inList;
end consOnTrue;

public function consOnSuccess<T>
  "Adds the element to the front of the list if the predicate succeeds.
   Prefer using consOnTrue instead of this function, it's more efficient."
  input T inElement;
  input list<T> inList;
  input Predicate inPredicate;
  output list<T> outList;

  partial function Predicate
    input T inElement;
  end Predicate;
algorithm
  try
    inPredicate(inElement);
    outList := inElement :: inList;
  else
    outList := inList;
  end try;
end consOnSuccess;

public function consOption<T>
  "Adds an optional element to the front of the list, or returns the list if the
   element is none."
  input Option<T> inElement;
  input list<T> inList;
  output list<T> outList;
algorithm
  outList := match(inElement)
    local
      T e;

    case SOME(e) then e :: inList;
    else inList;
  end match;
end consOption;

public function consOnBool<T>
  "Adds an element to one of two lists, depending on the given boolean value."
  input Boolean inValue;
  input T inElement;
  input output list<T> trueList;
  input output list<T> falseList;
algorithm
  if inValue then
    trueList := inElement :: trueList;
  else
    falseList := inElement :: falseList;
  end if;
end consOnBool;

public function consN<T>
  "concate n time inElement to the list:
  n = 5, inElement=1, list={1,2} -> list={1,1,1,1,1,1,2}"
  input Integer size;
  input T inElement;
  input output list<T> inList;
algorithm
  for i in 1:size loop
    inList := inElement :: inList;
  end for;
end consN;

public function append_reverse<T>
  "Appends the elements from list1 in reverse order to list2."
  input list<T> inList1;
  input list<T> inList2;
  output list<T> outList=inList2;
algorithm
  // Do not optimize the case listEmpty(inList2) and listLength(inList1)==1
  // since we use listReverseInPlace together with this function.
  // An alternative would be to keep both (and rename this append_reverse_always_copy)
  for e in inList1 loop
    outList := e::outList;
  end for;
end append_reverse;

public function append_reverser<T>
  "Appends the elements from list2 in reverse order to list1."
  input list<T> inList1;
  input list<T> inList2;
  output list<T> outList=inList1;
algorithm
  // Do not optimize the case listEmpty(inList2) and listLength(inList1)==1
  // since we use listReverseInPlace together with this function.
  // An alternative would be to keep both (and rename this append_reverse_always_copy)
  for e in inList2 loop
    outList := e::outList;
  end for;
end append_reverser;

public function appendr<T>
  "Appends two lists in reverse order compared to listAppend."
  input list<T> inList1;
  input list<T> inList2;
  output list<T> outList;
algorithm
  outList := listAppend(inList2, inList1);
end appendr;

public function appendElt<T>
  "Appends an element to the end of the list. Note that this is very
   inefficient, so try to avoid using this function."
  input T inElement;
  input list<T> inList;
  output list<T> outList;
algorithm
  outList := listAppend(inList, {inElement});
end appendElt;

public function appendLastList<T>
  "Appends a list to the last list in a list of lists."
  input list<list<T>> inListList;
  input list<T> inList;
  output list<list<T>> outListList;
algorithm
  outListList := match(inListList, inList)
    local
      list<T> l;
      list<list<T>> ll;
      list<list<T>> ol = {};

    case ({}, _) then {inList};

    case ({l}, _)
      then {listAppend(l, inList)};

    case (l :: ll, _)
      algorithm
        while not listEmpty(ll) loop
          ol := l::ol;
          l::ll := ll;
        end while;
        ol := listAppend(l, inList) :: ol;
        ol := listReverseInPlace(ol);
      then ol;

  end match;
end appendLastList;

public function insert<T>
 "Inserts an element at a position
  example: insert({2,1,4,2},2,3) => {2,3,1,4,2} "
  input list<T> inList;
  input Integer inN;
  input T inElement;
  output list<T> outList;
protected
  list<T> lst1, lst2;
algorithm
  true := (inN > 0);
  (lst1, lst2) := splitr(inList, inN-1);
  outList := append_reverse(lst1,inElement::lst2);
end insert;

public function insertListSorted<T>
 "Inserts an sorted list into another sorted list. O(n)
  example: insertListSorted({1,2,4,5},{3,4,8},intGt) => {1,2,3,4,4,5,8}"
  input list<T> inList;
  input list<T> inList2;
  input CompareFunc inCompFunc;
  output list<T> outList;

  partial function CompareFunc
    input T inElement1;
    input T inElement2;
    output Boolean inRes;
  end CompareFunc;
algorithm
  outList := listReverseInPlace(insertListSorted1(inList, inList2, inCompFunc, {}));
end insertListSorted;

protected function insertListSorted1<T>
 "Iterate over the first given list and add it to the result list if the comparison function with the head of the second list returns true.
  The result is a sorted list in reverse order."
  input list<T> inList;
  input list<T> inList2;
  input CompareFunc inCompFunc;
  input list<T> inResultList;
  output list<T> outResultList;

  partial function CompareFunc
    input T inElement1;
    input T inElement2;
    output Boolean inRes;
  end CompareFunc;
protected
  list<T> listRest, listRest2, tmpResultList;
  T listHead, listHead2;
  T elem;
algorithm
  outResultList := match(inList, inList2, inCompFunc, inResultList)
    case({},{},_,_)
      then inResultList;
    case({},_,_,_)
      then append_reverse(inList2, inResultList);
    case(_,{},_,_)
      then append_reverse(inList, inResultList);
    case(listHead::listRest, listHead2::listRest2,_,_)
      equation
        if(inCompFunc(listHead, listHead2)) then
          tmpResultList = listHead::inResultList;
          tmpResultList = insertListSorted1(listRest, inList2, inCompFunc, tmpResultList);
        else
          tmpResultList = listHead2::inResultList;
          tmpResultList = insertListSorted1(inList, listRest2, inCompFunc, tmpResultList);
        end if;
      then tmpResultList;
  end match;
end insertListSorted1;

public function set<T>
 "set an element at a position
  example: set({2,1,4,2},2,3) => {2,3,4,2} "
  input list<T> inList;
  input Integer inN;
  input T inElement;
  output list<T> outList;
protected
  list<T> lst1, lst2;
algorithm
  true := (inN > 0);
  (lst1, lst2) := splitr(inList, inN-1);
  lst2 := stripFirst(lst2);
  outList := append_reverse(lst1,inElement::lst2);
end set;

public function first<T>
  "Returns the first element of a list. Fails if the list is empty."
  input list<T> inList;
  output T out;
algorithm
  out := match(inList)
    local
      T e;
    case e :: _ then e;
  end match;
end first;

public function firstOrEmpty<T>
  "Returns the first element of a list as a list, or an empty list if the given
   list is empty."
  input list<T> inList;
  output list<T> outList;
algorithm
  outList := match(inList)
    local
      T e;

    case e :: _ then {e};
    else {};
  end match;
end firstOrEmpty;

public function second<T>
  "Returns the second element of a list. Fails if the list is empty."
  input list<T> inList;
  output T outSecond;
algorithm
  outSecond := listGet(inList, 2);
end second;

public function last<T>
  "Returns the last element of a list. Fails if the list is empty."
  input list<T> inList;
  output T outLast;
protected
  list<T> rest;
algorithm
  outLast::rest := inList;
  for e in rest loop
    outLast := e;
  end for;
end last;

public function lastElement<T>
  "Returns the last cons-cell of a list. Fails if the list is empty. Also returns the list length."
  input list<T> inList;
  output list<T> lst;
  output Integer listLength=0;
protected
  list<T> rest=inList;
algorithm
  false := listEmpty(rest);
  while not listEmpty(rest) loop
    (lst as (_::rest)) := rest;
    listLength := listLength+1;
  end while;
end lastElement;

public function lastListOrEmpty<T>
  "Returns the last element(list) of a list of lists. Returns empty list
  if the outer list is empty."
  input list<list<T>> inListList;
  output list<T> outLastList = {};
algorithm
  for e in inListList loop
    outLastList := e;
  end for;
end lastListOrEmpty;

public function secondLast<T>
  "Returns the second last element of a list, or fails if such an element does
   not exist."
  input list<T> inList;
  output T outSecondLast;
algorithm
  _ :: outSecondLast :: _ := listReverse(inList);
end secondLast;

public function lastN<T>
  "Returns the last N elements of a list."
  input list<T> inList;
  input Integer inN;
  output list<T> outList;
protected
  Integer len;
algorithm
  true := inN >= 0;
  len := listLength(inList);
  outList := stripN(inList, len - inN);
end lastN;

public function rest<T>
  "Returns all elements except for the first in a list."
  input list<T> inList;
  output list<T> outList;
algorithm
  _ :: outList := inList;
end rest;

public function restCond<T>
  "Returns all elements except for the first in a list."
  input Boolean cond;
  input list<T> inList;
  output list<T> outList;
algorithm
  outList := if cond then listRest(inList) else inList;
end restCond;

public function restOrEmpty<T>
  "Returns all elements except for the first in a list, or the empty list of the
   list is empty."
  input list<T> inList;
  output list<T> outList;
algorithm
  outList := if listEmpty(inList) then inList else listRest(inList);
end restOrEmpty;

public function getIndexFirst<T>
  input Integer index;
  input list<T> inList;
  output T element;
algorithm
 element := listGet(inList, index);
end getIndexFirst;

public function firstN<T>
  "Returns the first N elements of a list, or fails if there are not enough
   elements in the list."
  input list<T> inList;
  input Integer inN;
  output list<T> outList = {};
protected
  T e;
  list<T> rest;
algorithm
  true := (inN >= 0);
  rest := inList;

  for i in 1:inN loop
    e :: rest := rest;
    outList := e :: outList;
  end for;

  outList := listReverseInPlace(outList);
end firstN;

public function stripFirst<T>
  "Removes the first element of a list, but returns the empty list if the given
   list is empty."
  input list<T> inList;
  output list<T> outList;
algorithm
  if listEmpty(inList) then
    outList := {};
  else
    _::outList := inList;
  end if;
end stripFirst;

public function stripLast<T>
  "Removes the last element of a list. If the list is the empty list, the
   function returns the empty list."
  input list<T> inList;
  output list<T> outList;
algorithm
  if listEmpty(inList) then
    outList := {};
  else
    _ :: outList := listReverse(inList);
    outList := listReverseInPlace(outList);
  end if;
end stripLast;

public function stripN<T>
  "Strips the N first elements from a list. Fails if the list contains less than
   N elements, or if N is negative."
  input list<T> inList;
  input Integer inN;
  output list<T> outList = inList;
algorithm
  true := inN >= 0;

  for i in 1:inN loop
    _ :: outList := outList;
  end for;
end stripN;

public function heapSortIntList
  input output list<Integer> lst;
algorithm
  lst := match lst
      case {} then lst;
      case {_} then lst;
    else arrayList(Array.heapSort(listArray(lst)));
    end match;
end heapSortIntList;

public function sort<T>
  "Sorts a list given an ordering function with the mergesort algorithm.
    Example:
      sort({2, 1, 3}, intGt) => {1, 2, 3}
      sort({2, 1, 3}, intLt) => {3, 2, 1}"
  input list<T> inList;
  input CompareFunc inCompFunc;
  output list<T> outList= {};

  partial function CompareFunc
    input T inElement1;
    input T inElement2;
    output Boolean inRes;
  end CompareFunc;
protected
  list<T> rest = inList;
  T e1, e2;
  list<T> left, right;
  Integer middle;
algorithm
  if not listEmpty(rest) then
    e1 :: rest := rest;
    if listEmpty(rest) then
      outList := inList;
    else
      e2 :: rest := rest;
      if listEmpty(rest) then
        outList := if inCompFunc(e2, e1) then inList else {e2,e1};
      else
        middle := intDiv(listLength(inList), 2);
        (left, right) := split(inList, middle);
        left := sort(left, inCompFunc);
        right := sort(right, inCompFunc);
        outList := merge(left, right, inCompFunc, {});
      end if;
    end if;
  end if;
end sort;

public function sortedDuplicates<T>
  "Returns a list of all duplicates in a sorted list, using the given comparison
   function to check for equality."
  input list<T> inList;
  input CompareFunc inCompFunc "Equality comparator";
  output list<T> outDuplicates = {};

  partial function CompareFunc
    input T inElement1;
    input T inElement2;
    output Boolean outEqual;
  end CompareFunc;
protected
  T e;
  list<T> rest = inList;
algorithm
  while not listEmpty(rest) loop
    e :: rest := rest;

    if not listEmpty(rest) and inCompFunc(e, listHead(rest)) then
      outDuplicates := e :: outDuplicates;
    end if;
  end while;

  outDuplicates := listReverseInPlace(outDuplicates);
end sortedDuplicates;

public function sortedListAllUnique<T>
  "The input is a sorted list. The functions checks if all elements are unique."
  input list<T> lst;
  input CompareFunc compare;
  output Boolean allUnique = false;

  partial function CompareFunc
    input T inElement1;
    input T inElement2;
    output Boolean outEqual;
  end CompareFunc;
protected
  T e;
  list<T> rest = lst;
algorithm
  while not listEmpty(rest) loop
    rest := match rest
      local
        T e1,e2;
      case {_} then {};
      case e1::(rest as e2::_)
        algorithm
          if compare(e1,e2) then
            return;
          end if;
        then rest;
    end match;
  end while;
  allUnique := true;
end sortedListAllUnique;

public function sortedUnique<T>
  "Returns a list of unique elements in a sorted list, using the given
   comparison function to check for equality."
  input list<T> inList;
  input CompareFunc inCompFunc;
  output list<T> outUniqueElements = {};

  partial function CompareFunc
    input T inElement1;
    input T inElement2;
    output Boolean outEqual;
  end CompareFunc;
protected
  T e;
  list<T> rest = inList;
algorithm
  while not listEmpty(rest) loop
    e :: rest := rest;

    if listEmpty(rest) or not inCompFunc(e, listHead(rest)) then
      outUniqueElements := e :: outUniqueElements;
    end if;
  end while;

  outUniqueElements := listReverseInPlace(outUniqueElements);
end sortedUnique;

public function sortedUniqueAndDuplicates<T>
  "Returns a list with all duplicate elements removed, as well as a list of the
   removed elements, using the given comparison function to check for equality."
  input list<T> inList;
  input CompareFunc inCompFunc;
  output list<T> outUniqueElements = {};
  output list<T> outDuplicateElements = {};

  partial function CompareFunc
    input T inElement1;
    input T inElement2;
    output Boolean outEqual;
  end CompareFunc;
protected
  T e;
  list<T> rest = inList;
algorithm
  while not listEmpty(rest) loop
    e :: rest := rest;

    if not listEmpty(rest) and inCompFunc(e, listHead(rest)) then
      outDuplicateElements := e :: outDuplicateElements;
    else
      outUniqueElements := e :: outUniqueElements;
    end if;
  end while;

  outUniqueElements := listReverseInPlace(outUniqueElements);
  outDuplicateElements := listReverseInPlace(outDuplicateElements);
end sortedUniqueAndDuplicates;

public function sortedUniqueOnlyDuplicates<T>
  "Returns a list with all duplicate elements removed, as well as a list of the
   removed elements, using the given comparison function to check for equality."
  input list<T> inList;
  input CompareFunc inCompFunc;
  output list<T> outDuplicateElements = {};

  partial function CompareFunc
    input T inElement1;
    input T inElement2;
    output Boolean outEqual;
  end CompareFunc;
protected
  T e;
  list<T> rest = inList;
algorithm
  while not listEmpty(rest) loop
    e :: rest := rest;

    if not listEmpty(rest) and inCompFunc(e, listHead(rest)) then
      outDuplicateElements := e :: outDuplicateElements;
    end if;
  end while;

  outDuplicateElements := listReverseInPlace(outDuplicateElements);
end sortedUniqueOnlyDuplicates;

protected function merge<T>
  "Helper function to sort, merges two sorted lists."
  input list<T> inLeft;
  input list<T> inRight;
  input CompareFunc inCompFunc;
  input list<T> acc;
  output list<T> outList;

  partial function CompareFunc
    input T inElement1;
    input T inElement2;
    output Boolean outRes;
  end CompareFunc;
algorithm
  outList := match (inLeft, inRight)
    local
      Boolean b;
      T l, r, el;
      list<T> l_rest, r_rest, res;

    /* Tail recursive version */
    case (l :: l_rest, r :: r_rest)
      algorithm
        if inCompFunc(r, l) then
          r_rest := inRight;
          el := l;
        else
          l_rest := inLeft;
          el := r;
        end if;
      then
        merge(l_rest, r_rest, inCompFunc, el :: acc);

    case ({}, {}) then listReverseInPlace(acc);
    case ({}, _) then append_reverse(acc,inRight);
    case (_, {}) then append_reverse(acc,inLeft);

  end match;
end merge;

public function mergeSorted<T>
  "This function merges two sorted lists into one sorted list. It takes a
  comparison function that defines a strict weak ordering of the elements, i.e.
  that returns true if the first element should be placed before the second
  element in the sorted list."
  input list<T> inList1;
  input list<T> inList2;
  input CompFunc inCompFunc;
  output list<T> outList = {};

  partial function CompFunc
    input T inElement1;
    input T inElement2;
    output Boolean outIsEqual;
  end CompFunc;
protected
  list<T> l1, l2;
  T e1, e2;
algorithm
  l1 := inList1;
  l2 := inList2;

  // While both lists contain elements.
  while not listEmpty(l1) and not listEmpty(l2) loop
    e1 :: _ := l1;
    e2 :: _ := l2;

    // Move the smallest head from either list to accumulator.
    if inCompFunc(e1, e2) then
      outList := e1 :: outList;
      _ :: l1 := l1;
    else
      outList := e2 :: outList;
      _ :: l2 := l2;
    end if;
  end while;

  // Reverse accumulator and append the remaining elements.
  l1 := if listEmpty(l1) then l2 else l1;
  outList := append_reverse(outList, l1);
end mergeSorted;

public function sortIntN
  "Provides same functionality as sort, but for integer values between 1
   and N. The complexity in this case is O(n)"
  input list<Integer> inList;
  input Integer inN;
  output list<Integer> outSorted = {};
protected
  array<Boolean> a1;
algorithm
  a1 := arrayCreate(inN, false);
  a1 := fold1r(inList,arrayUpdate,true,a1);

  for i in inN:-1:1 loop
    if a1[i] then
      outSorted := i :: outSorted;
    end if;
  end for;
  GC.free(a1);
end sortIntN;

public function unique<T>
  "Takes a list of elements and returns a list with duplicates removed, so that
   each element in the new list is unique."
  input list<T> inList;
  output list<T> outList = {};
algorithm
  for e in inList loop
    if not listMember(e, outList) then
      outList := e :: outList;
    end if;
  end for;
  outList := listReverseInPlace(outList);
end unique;

public function uniqueIntN
  "Takes a list of integes and returns a list with duplicates removed, so that
   each element in the new list is unique. O(listLength(inList))"
  input list<Integer> inList;
  input Integer inN;
  output list<Integer> outList = {};
protected
  array<Boolean> arr;
algorithm
  arr := arrayCreate(inN, true);

  for i in inList loop
    if arrayGet(arr, i) then
      outList := i :: outList;
    end if;

    arrayUpdate(arr, i, false);
  end for;
  GC.free(arr);
end uniqueIntN;

public function uniqueIntNArr
  "Takes a list of integes and returns a list with duplicates removed, so that
   each element in the new list is unique. O(listLength(inList)). The function
   also takes an array of Integer of size N+1 to mark the already selected entries <= N.
   The last entrie of the array is used for the mark index. It will be updated after
   each call"
  input list<Integer> inList;
  input array<Integer> inMarkArray;
  input list<Integer> inAccum;
  output list<Integer> outAccum;
protected
  Integer len, mark;
algorithm
  if listEmpty(inList) then
    outAccum := inAccum;
  else
    len := arrayLength(inMarkArray);
    mark := inMarkArray[len];
    arrayUpdate(inMarkArray, len, mark + 1);
    outAccum := uniqueIntNArr1(inList, len, mark + 1, inMarkArray, inAccum);
  end if;
end uniqueIntNArr;

protected function uniqueIntNArr1
  "Helper for uniqueIntNArr1."
  input list<Integer> inList;
  input Integer inLength;
  input Integer inMark;
  input array<Integer> inMarkArray;
  input list<Integer> inAccum;
  output list<Integer> outAccum = inAccum;
algorithm
  for i in inList loop
    if i >= inLength then
      fail();
    end if;

    if arrayGet(inMarkArray, i) <> inMark then
      outAccum := i :: outAccum;
      _ := arrayUpdate(inMarkArray, i, inMark);
    end if;
  end for;
end uniqueIntNArr1;

public function uniqueOnTrue<T>
  "Takes a list of elements and a comparison function over two elements of the
   list and returns a list with duplicates removed, so that each element in the
   new list is unique."
  input list<T> inList;
  input CompFunc inCompFunc;
  output list<T> outList = {};

  partial function CompFunc
    input T inElement1;
    input T inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  for e in inList loop
    if not isMemberOnTrue(e, outList, inCompFunc) then
      outList := e :: outList;
    end if;
  end for;
  outList := listReverseInPlace(outList);
end uniqueOnTrue;

public function reverseList<T>
  "Takes a list of lists and reverses it at both levels, i.e. both the list
   itself and each sublist.
     Example:
       reverseList({{1, 2}, {3, 4, 5}, {6}}) => {{6}, {5, 4, 3}, {2, 1}}"
  input list<list<T>> inList;
  output list<list<T>> outList;
algorithm
  outList := listReverse(listReverse(e) for e in inList);
end reverseList;

public function split<T>
  "Takes a list and a position, and splits the list at the position given.
    Example: split({1, 2, 5, 7}, 2) => ({1, 2}, {5, 7})"
  input list<T> inList;
  input Integer inPosition;
  output list<T> outList1;
  output list<T> outList2;
protected
  Integer pos;
  list<T> l1 = {}, l2 = inList;
  T e;
algorithm
  true := inPosition >= 0;
  pos := inPosition;

  // Move elements from l2 to l1 until we reach the split position.
  for i in 1:pos loop
    e :: l2 := l2;
    l1 := e :: l1;
  end for;

  outList1 := listReverseInPlace(l1);
  outList2 := l2;
end split;

public function splitr<T>
  "Takes a list and a position, and splits the list at the position given. The first list is returned in reverse order.
    Example: split({1, 2, 5, 7}, 2) => ({2, 1}, {5, 7})"
  input list<T> inList;
  input Integer inPosition;
  output list<T> outList1;
  output list<T> outList2;
protected
  Integer pos;
  list<T> l1 = {}, l2 = inList;
  T e;
algorithm
  true := inPosition >= 0;
  pos := inPosition;

  // Move elements from l2 to l1 until we reach the split position.
  for i in 1:pos loop
    e :: l2 := l2;
    l1 := e :: l1;
  end for;

  outList1 := l1;
  outList2 := l2;
end splitr;

public function splitOnTrue<T>
  "Splits a list into two sublists depending on predicate function."
  input list<T> inList;
  input PredicateFunc inFunc;
  output list<T> outTrueList = {};
  output list<T> outFalseList = {};

  partial function PredicateFunc
    input T inElement;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  for e in inList loop
    if inFunc(e) then
      outTrueList := e :: outTrueList;
    else
      outFalseList := e :: outFalseList;
    end if;
  end for;

  outTrueList := listReverseInPlace(outTrueList);
  outFalseList := listReverseInPlace(outFalseList);
end splitOnTrue;

public function split1OnTrue<T, ArgT1>
  "Splits a list into two sublists depending on predicate function."
  input list<T> inList;
  input PredicateFunc inFunc;
  input ArgT1 inArg1;
  output list<T> outTrueList = {};
  output list<T> outFalseList = {};

  partial function PredicateFunc
    input T inElement;
    input ArgT1 inArg1;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  for e in inList loop
    if inFunc(e, inArg1) then
      outTrueList := e :: outTrueList;
    else
      outFalseList := e :: outFalseList;
    end if;
  end for;

  outTrueList := listReverseInPlace(outTrueList);
  outFalseList := listReverseInPlace(outFalseList);
end split1OnTrue;

public function split2OnTrue<T, ArgT1, ArgT2>
  "Splits a list into two sublists depending on predicate function."
  input list<T> inList;
  input PredicateFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  output list<T> outTrueList = {};
  output list<T> outFalseList = {};

  partial function PredicateFunc
    input T inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  for e in inList loop
    if inFunc(e, inArg1, inArg2) then
      outTrueList := e :: outTrueList;
    else
      outFalseList := e :: outFalseList;
    end if;
  end for;

  outTrueList := listReverseInPlace(outTrueList);
  outFalseList := listReverseInPlace(outFalseList);
end split2OnTrue;

public function splitOnFirstMatch<T>
  "Splits a list when the given function first finds a matching element.
     Example: splitOnFirstMatch({1, 2, 3, 4, 5}, isThree) => ({1, 2}, {3, 4, 5})"
  input list<T> inList;
  input CompFunc inFunc;
  output list<T> outList1 = {};
  output list<T> outList2 = inList;

  partial function CompFunc
    input T inElement;
    output Boolean outMatch;
  end CompFunc;
protected
  T e;
algorithm
  // Shuffle elements from outList2 to outList1 until we find a match.
  while not listEmpty(outList2) loop
    e :: outList2 := outList2;

    if inFunc(e) then
      outList2 := e :: outList2;
      break;
    end if;

    outList1 := e :: outList1;
  end while;
  outList1 := listReverseInPlace(outList1);
end splitOnFirstMatch;

public function splitFirst<T>
  "Returns the first element of a list and the rest of the list. Fails if the
   list is empty."
  input list<T> inList;
  output T outFirst;
  output list<T> outRest;
algorithm
  outFirst :: outRest := inList;
end splitFirst;

public function splitFirstOption<T>
  "Returns the first element of a list as an option, and the rest of the list.
   Returns NONE and {} if the list is empty."
  input list<T> inList;
  output Option<T> outFirst;
  output list<T> outRest;
algorithm
  (outFirst, outRest) := match(inList)
    local
      T el;
      list<T> rest;

    case (el :: rest) then (SOME(el), rest);
    else (NONE(), {});

  end match;
end splitFirstOption;

public function splitLast<T>
  "Returns the last element of a list and a list of all previous elements. If
   the list is the empty list, the function fails.
     Example: splitLast({3, 5, 7, 11, 13}) => (13, {3, 5, 7, 11})"
  input list<T> inList;
  output T outLast;
  output list<T> outRest;
algorithm
  outLast :: outRest := listReverse(inList);
  outRest := listReverseInPlace(outRest);
end splitLast;

public function splitEqualParts<T>
  "Splits a list into n equally sized parts.
     Example: splitEqualParts({1, 2, 3, 4, 5, 6, 7, 8}, 4) =>
              {{1, 2}, {3, 4}, {5, 6}, {7, 8}}"
  input list<T> inList;
  input Integer inParts;
  output list<list<T>> outParts;
protected
  Integer length;
algorithm
  if inParts == 0 then
    outParts := {};
  else
    length := listLength(inList);
    0 := intMod(length, inParts);
    outParts := partition(inList, intDiv(length, inParts));
  end if;
end splitEqualParts;

public function splitOnBoolList<T>
  "Splits a list into two sublists depending on a second list of bools."
  input list<T> inList;
  input list<Boolean> inBools;
  output list<T> outTrueList = {};
  output list<T> outFalseList = {};
protected
  T e;
  list<T> rest_e = inList;
  Boolean b;
  list<Boolean> rest_b = inBools;
algorithm
  while not listEmpty(rest_e) loop
    e :: rest_e := rest_e;
    b :: rest_b := rest_b;

    if b then
      outTrueList := e :: outTrueList;
    elseif isPresent(outFalseList) then
      outFalseList := e :: outFalseList;
    end if;
  end while;

  outTrueList := listReverseInPlace(outTrueList);
  outFalseList := listReverseInPlace(outFalseList);
end splitOnBoolList;

public function partition<T>
  "Partitions a list of elements into sublists of length n.
     Example: partition({1, 2, 3, 4, 5}, 2) => {{1, 2}, {3, 4}, {5}}"
  input list<T> inList;
  input Integer inPartitionLength;
  output list<list<T>> outPartitions = {};
protected
  list<T> lst = inList, part;
  Integer length;
algorithm
  true := inPartitionLength > 0;
  length := listLength(inList);

  if length == 0 then
    return;
  elseif inPartitionLength >= length then
    outPartitions := {inList};
    return;
  end if;

  // Split the list into partitions.
  for i in 1:div(length, inPartitionLength) loop
    (part, lst) := split(lst, inPartitionLength);
    outPartitions := part :: outPartitions;
  end for;

  // Append the remainder of the list.
  if not listEmpty(lst) then
    outPartitions := lst :: outPartitions;
  end if;

  outPartitions := listReverseInPlace(outPartitions);
end partition;

public function balancedPartition<T>
  "Partitions a list of elements into even sublists of maximum length n.
     Example: partition({1, 2, 3, 4, 5}, 2) => {{1, 2}, {3, 4}, {5}}
   The number of partitions is the same as partition(), but chosen to be
   as balanced in length as possible.
  "
  input list<T> lst;
  input Integer maxLength;
  output list<list<T>> outPartitions;
protected
  Integer length, n;
algorithm
  true := maxLength > 0;
  if listEmpty(lst) then
    outPartitions := {};
    return;
  end if;
  length := listLength(lst);
  n := intDiv(length-1, maxLength)+1;
  outPartitions := partition(lst, intDiv(length-1, n)+1);
end balancedPartition;

public function sublist<T>
  "Returns a sublist determined by an offset and length.
     Example: sublist({1,2,3,4,5}, 2, 3) => {2,3,4}"
  input list<T> inList;
  input Integer inOffset;
  input Integer inLength;
  output list<T> outList = {};
protected
  T e;
  list<T> rest = inList, res;
algorithm
  true := inOffset > 0;
  true := inLength >= 0;

  // Remove elements until we reach the offset position.
  for i in 2:inOffset loop
    _ :: rest := rest;
  end for;

  // Accumulate the given number of elements.
  for i in 1:inLength loop
    e :: rest := rest;
    outList := e :: outList;
  end for;

  outList := listReverseInPlace(outList);
end sublist;

public function productMap<T1, T2, TO>
  "Given two lists and a function, forms the cartesian product of the lists and
   applies the function to each resulting pair.
     Example: productMap({1, 2}, {3, 4}, intMul) = {1*3, 1*4, 2*3, 2*4}"
  input list<T1> inList1;
  input list<T2> inList2;
  input MapFunc inMapFunc;
  output list<TO> outResult = {};

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    output TO outResult;
  end MapFunc;
algorithm
  for e1 in listReverse(inList1), e2 in listReverse(inList2) loop
    outResult := inMapFunc(e1, e2) :: outResult;
  end for;
end productMap;

public function product<T>
  "Given 2 lists, generate the product of them.
     Example:
       list1 = {{1}, {2}}, list2 = {{1}, {3}, {4}}
       result = {{1, 1}, {1, 3}, {1, 4}, {2, 1}, {2, 3}, {2, 4}}"
  input list<list<T>> inList1;
  input list<list<T>> inList2;
  output list<list<T>> outProduct = {};
algorithm
  for e1 in inList1, e2 in inList2 loop
    outProduct := listAppend(e1, e2) :: outProduct;
  end for;
end product;

public function transposeList<T>
  "Transposes a list of lists. Example:
     transposeList({{1, 2, 3}, {4, 5, 6}}) => {{1, 4}, {2, 5}, {3, 6}}"
  input list<list<T>> inList;
  output list<list<T>> outList = {};
protected
  array<array<T>> arr;
  array<T> arr_row;
  list<T> new_row;
  Integer c_len, r_len;
algorithm
  if listEmpty(inList) then
    return;
  end if;

  // Convert the list into an array, it's a lot more efficient than fiddling
  // around with lists.
  arr := listArray(list(listArray(lst) for lst in inList));

  // Get the dimensions of the array.
  c_len := arrayLength(arr);
  r_len := arrayLength(arrayGet(arr, 1));

  // Loop through the array in reverse order so we can create the new lists
  // in the correct order without having to reverse them.
  for i in r_len:-1:1 loop
    new_row := {};

    for j in c_len:-1:1 loop
      new_row := arrayGetNoBoundsChecking(arrayGet(arr, j), i) :: new_row;
    end for;

    outList := new_row :: outList;
  end for;
end transposeList;

public function listArrayReverse<T>
  input list<T> inLst;
  output array<T> outArr;
protected
  Integer len;
  T defaultValue;
algorithm
  if listEmpty(inLst) then
    outArr := listArray(inLst);
    return;
  end if;
  len := listLength(inLst);
  defaultValue::_ := inLst;
  outArr := arrayCreateNoInit(len,defaultValue);
  for e in inLst loop
    arrayUpdateNoBoundsChecking(outArr, len, e);
    len := len-1;
  end for;
end listArrayReverse;

public function setEqualOnTrue<T>
  "Takes two lists and a comparison function over two elements of the lists.
   It returns true if the two sets are equal, false otherwise."
  input list<T> inList1;
  input list<T> inList2;
  input CompFunc inCompFunc;
  output Boolean outIsEqual;

  partial function CompFunc
    input T inElement1;
    input T inElement2;
    output Boolean outIsEqual;
  end CompFunc;
protected
  list<T> lst;
  Integer lst_size;
algorithm
  lst := intersectionOnTrue(inList1, inList2, inCompFunc);
  lst_size := listLength(lst);
  outIsEqual := intEq(lst_size, listLength(inList1)) and
                intEq(lst_size, listLength(inList2));
end setEqualOnTrue;

public function intersectionIntSorted
  "Provides same functionality as listIntersection, but for integer values
   in sorted lists. The complexity in this case is O(n)."
  input list<Integer> inList1;
  input list<Integer> inList2;
  output list<Integer> outResult = {};
protected
  Integer i1, i2;
  Integer o1, o2;
  list<Integer> l1 = inList1, l2 = inList2;
algorithm
  if listEmpty(inList1) or listEmpty(inList2) then
    return;
  end if;
  i1::l1 := l1;
  i2::l2 := l2;
  o1:=i1;o2:=i2;
  while true loop
    if i1 > i2 then
      if listEmpty(l2) then
        break;
      end if;
      i2::l2 := l2;
      if o2 > i2 then fail();end if; o2:=i2;
    elseif i1 < i2 then
      if listEmpty(l1) then
        break;
      end if;
      i1::l1 := l1;
      if o1 > i1 then fail();end if; o1:=i1;
    else
      outResult := i1::outResult;
      if listEmpty(l1) or listEmpty(l2) then
        break;
      end if;
      i1::l1 := l1;
      i2::l2 := l2;
      if o1 > i1 then fail();end if; o1:=i1;
      if o2 > i2 then fail();end if; o2:=i2;
    end if;
  end while;
  outResult := listReverseInPlace(outResult);
end intersectionIntSorted;

public function intersectionIntN
  "Provides same functionality as listIntersection, but for integer values
   between 1 and N. The complexity in this case is O(n)."
  input list<Integer> inList1;
  input list<Integer> inList2;
  input Integer inN;
  output list<Integer> outResult;
protected
  array<Integer> a;
algorithm
  if inN > 0 then
    a := arrayCreate(inN, 0);
    a := addPos(inList1, a, 1);
    a := addPos(inList2, a, 1);
    outResult := intersectionIntVec(a, inList1);
    GC.free(a);
  else
    outResult := {};
  end if;
end intersectionIntN;

protected function intersectionIntVec
  "Helper function to intersectionIntN."
  input array<Integer> inArray;
  input list<Integer> inList1;
  output list<Integer> outResult = {};
algorithm
  for i in inList1 loop
    if arrayGet(inArray,i) == 2 then
      outResult := i :: outResult;
    end if;
  end for;
end intersectionIntVec;

protected function addPos
  "Helper function to intersectionIntN."
  input list<Integer> inList;
  input array<Integer> inArray;
  input Integer inIndex;
  output array<Integer> outArray;
algorithm
  for i in inList loop
    _ := arrayUpdate(inArray, i, intAdd(arrayGet(inArray, i), inIndex));
  end for;

  outArray := inArray;
end addPos;

public function intersectionOnTrue<T>
  "Takes two lists and a comparison function over two elements of the lists. It
   returns the intersection of the two lists, using the comparison function
   passed as argument to determine identity between two elements.
     Example:
       intersectionOnTrue({1, 4, 2}, {5, 2, 4, 6}, intEq) => {4, 2}"
  input list<T> inList1;
  input list<T> inList2;
  input CompFunc inCompFunc;
  output list<T> outIntersection = {};

  partial function CompFunc
    input T inElement1;
    input T inElement2;
     output Boolean outIsEqual;
  end CompFunc;
algorithm
  for e in inList1 loop
    if isMemberOnTrue(e, inList2, inCompFunc) then
      outIntersection := e :: outIntersection;
    end if;
  end for;

  outIntersection := listReverseInPlace(outIntersection);
end intersectionOnTrue;

public function intersection1OnTrue<T>
  "Takes two lists and a comparison function over two elements of the lists. It
   returns the intersection of the two lists, using the comparison function
   passed as argument to determine identity between two elements. This function
   also returns a list of the elements from list 1 which is not in list 2 and a
   list of the elements from list 2 which is not in list 1."
  input list<T> inList1;
  input list<T> inList2;
  input CompFunc inCompFunc;
  output list<T> outIntersection = {};
  output list<T> outList1Rest = {};
  output list<T> outList2Rest = inList2;

  partial function CompFunc
    input T inElement1;
    input T inElement2;
    output Boolean outIsEqual;
  end CompFunc;
protected
  Option<T> oe;
algorithm
  if listEmpty(inList1) then
    return;
  end if;
  if listEmpty(inList2) then
    outList1Rest := inList1;
    return;
  end if;
  for e in inList1 loop
    if isMemberOnTrue(e, inList2, inCompFunc) then
      outIntersection := e :: outIntersection;
    elseif isPresent(outList1Rest) then
      outList1Rest := e :: outList1Rest;
    end if;
  end for;

  outIntersection := listReverseInPlace(outIntersection);
  outList1Rest := if isPresent(outList1Rest) then listReverseInPlace(outList1Rest) else {};
  outList2Rest := if isPresent(outList2Rest) then setDifferenceOnTrue(inList2, outIntersection, inCompFunc) else {};
end intersection1OnTrue;

public function setDifferenceIntN
  "Provides same functionality as setDifference, but for integer values
   between 1 and N. The complexity in this case is O(n)"
  input list<Integer> inList1;
  input list<Integer> inList2;
  input Integer inN;
  output list<Integer> outDifference = {};
protected
  array<Integer> a;
algorithm
  if inN > 0 then
    a := arrayCreate(inN, 0);
    a := addPos(inList1, a, 1);
    a := addPos(inList2, a, 1);

    for i in inN:-1:1 loop
      if arrayGet(a, i) == 1 then
        outDifference := i :: outDifference;
      end if;
    end for;
    GC.free(a);
  end if;
end setDifferenceIntN;

public function setDifferenceOnTrue<T>
  "Takes two lists and a comparison function over two elements of the lists. It
   returns the set difference of the two lists A-B, using the comparison
   function passed as argument to determine identity between two elements.
     Example:
       setDifferenceOnTrue({1, 2, 3}, {1, 3}, intEq) => {2}"
  input list<T> inList1;
  input list<T> inList2;
  input CompFunc inCompFunc;
  output list<T> outDifference = inList1;

  partial function CompFunc
    input T inElement1;
    input T inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  // Empty - B = Empty
  if listEmpty(inList1) then
    return;
  end if;

  for e in inList2 loop
    (outDifference, _) := deleteMemberOnTrue(e, outDifference, inCompFunc);
  end for;
end setDifferenceOnTrue;

public function setDifference<T>
  "Takes two lists and returns the set difference of two lists A - B.
     Example:
       setDifference({1, 2, 3}, {1, 3}) => {2}"
  input list<T> inList1;
  input list<T> inList2;
  output list<T> outDifference = inList1;
algorithm
  if listEmpty(inList1) then
    return;
  end if;

  for e in inList2 loop
    outDifference := deleteMember(outDifference, e);
  end for;
end setDifference;

public function unionIntN
  "Provides same functionality as listUnion, but for integer values between 1
   and N. The complexity in this case is O(n)"
  input list<Integer> inList1;
  input list<Integer> inList2;
  input Integer inN;
  output list<Integer> outUnion = {};
protected
  array<Integer> a;
algorithm
  if inN > 0 then
    a := arrayCreate(inN, 0);
    a := addPos(inList1, a, 1);
    a := addPos(inList2, a, 1);

    for i in inN:-1:1 loop
      if arrayGet(a, i) > 0 then
        outUnion := i :: outUnion;
      end if;
    end for;
    GC.free(a);
  end if;
end unionIntN;

public function unionElt<T>
  "Takes a value and a list of values and inserts the value into the list if it
   is not already in the list. If it is in the list it is not inserted.
    Example:
      unionElt(1, {2, 3}) => {1, 2, 3}
      unionElt(0, {0, 1, 2}) => {0, 1, 2}"
  input T inElement;
  input list<T> inList;
  output list<T> outList;
algorithm
  outList := consOnTrue(not listMember(inElement, inList), inElement, inList);
end unionElt;

public function unionEltOnTrue<T>
  "Works as unionElt, but with a compare function."
  input T inElement;
  input list<T> inList;
  input CompFunc inCompFunc;
  output list<T> outList;

  partial function CompFunc
    input T inElement1;
    input T inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outList := consOnTrue(not isMemberOnTrue(inElement, inList, inCompFunc),
    inElement, inList);
end unionEltOnTrue;

public function union<T>
  "Takes two lists and returns the union of the two lists, i.e. a list of all
   elements combined without duplicates. Example:
     union({0, 1}, {2, 1}) => {0, 1, 2}"
  input list<T> inList1;
  input list<T> inList2;
  output list<T> outUnion = {};
algorithm
  for e in inList1 loop
    outUnion := unionElt(e, outUnion);
  end for;

  for e in inList2 loop
    outUnion := unionElt(e, outUnion);
  end for;

  outUnion := listReverseInPlace(outUnion);
end union;

public function unionAppendonUnion<T>
  "As union but this function assume that List1 is already union.
   i.e. a list of all elements combined without duplicates.
   Example:
     union({0, 1}, {2, 1}) => {0, 1, 2}"
  input list<T> inList1;
  input list<T> inList2;
  output list<T> outUnion;
algorithm
  outUnion := listReverse(inList1);

  for e in inList2 loop
    outUnion := unionElt(e, outUnion);
  end for;

  outUnion := listReverseInPlace(outUnion);
end unionAppendonUnion;

public function unionOnTrue<T>
  "Takes two lists an a comparison function over two elements of the lists. It
   returns the union of the two lists, using the comparison function passed as
   argument to determine identity between two elements. Example:
     unionOnTrue({1, 2}, {2, 3}, intEq) => {1, 2, 3}"
  input list<T> inList1;
  input list<T> inList2;
  input CompFunc inCompFunc;
  output list<T> outUnion = {};

  partial function CompFunc
    input T inList1;
    input T inList2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  for e in inList1 loop
    outUnion := unionEltOnTrue(e, outUnion, inCompFunc);
  end for;

  for e in inList2 loop
    outUnion := unionEltOnTrue(e, outUnion, inCompFunc);
  end for;

  outUnion := listReverseInPlace(outUnion);
end unionOnTrue;

public function unionAppendListOnTrue<T>
  input list<T> inList;
  input list<T> inUnion;
  input CompFunc inCompFunc;
  output list<T> outUnion;

  partial function CompFunc
    input T inElement1;
    input T inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outUnion := fold(inList, function unionEltOnTrue(inCompFunc = inCompFunc), inUnion);
end unionAppendListOnTrue;

public function unionList<T>
  "Takes a list of lists and returns the union of the sublists.
     Example: unionList({1}, {1, 2}, {3, 4}, {5}}) => {1, 2, 3, 4, 5}"
  input list<list<T>> inList;
  output list<T> outUnion;
algorithm
  outUnion := if listEmpty(inList) then {} else reduce(inList, union);
end unionList;

public function unionOnTrueList<T>
  "Takes a list of lists and a comparison function over two elements of the
   lists. It returns the union of all sublists using the comparison function
   for identity.
     Example:
       unionOnTrueList({{1}, {1, 2}, {3, 4}}, intEq) => {1, 2, 3, 4}"
  input list<list<T>> inList;
  input CompFunc inCompFunc;
  output list<T> outUnion;

  partial function CompFunc
    input T inElement1;
    input T inElement2;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outUnion := if listEmpty(inList) then {}
              else reduce1(inList, unionOnTrue, inCompFunc);
end unionOnTrueList;

public function map<TI, TO>
  "Takes a list and a function, and creates a new list by applying the function
   to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  output list<TO> outList;

  partial function MapFunc
    input TI inElement;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inFunc(e) for e in inList);
end map;

public function mapCheckReferenceEq<TI>
  "Takes a list and a function, and creates a new list by applying the function
   to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  output list<TI> outList;

  partial function MapFunc
    input TI inElement;
    output TI outElement;
  end MapFunc;
protected
  Boolean allEq=true;
  DoubleEndedList<TI> delst;
  Integer n=0;
  TI e1;
algorithm
  for e in inList loop
    e1 := inFunc(e);
    // Preserve reference equality without any allocation if nothing changed
    if (if allEq then not referenceEq(e, e1) else false) then
      allEq:=false;
      delst := DoubleEndedList.empty(e1);
      for elt in inList loop
        if n < 1 then
          break;
        end if;
        DoubleEndedList.push_back(delst, elt);
        n := n-1;
      end for;
    end if;
    if allEq then
      n := n + 1;
    else
      DoubleEndedList.push_back(delst, e1);
    end if;
  end for;
  outList := if allEq then inList else DoubleEndedList.toListAndClear(delst);
end mapCheckReferenceEq;

public function mapReverse<TI, TO>
  "Takes a list and a function, and creates a new list by applying the function
   to each element of the list. The created list will be reversed compared to
   the given list."
  input list<TI> inList;
  input MapFunc inFunc;
  output list<TO> outList;

  partial function MapFunc
    input TI inElement;
    output TO outElement;
  end MapFunc;
algorithm
  outList := listReverse(inFunc(e) for e in inList);
end mapReverse;

public function map_2<TI, TO1, TO2>
  "Takes a list and a function, and creates two new lists by applying the
   function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  output list<TO1> outList1 = {};
  output list<TO2> outList2 = {};

  partial function MapFunc
    input TI inElement;
    output TO1 outElement1;
    output TO2 outElement2;
  end MapFunc;
protected
  TO1 e1;
  TO2 e2;
algorithm
  for e in inList loop
    (e1, e2) := inFunc(e);
    outList1 := e1 :: outList1;
    if isPresent(outList2) then
      outList2 := e2 :: outList2;
    end if;
  end for;

  outList1 := listReverseInPlace(outList1);
  if isPresent(outList2) then
    outList2 := listReverseInPlace(outList2);
  end if;
end map_2;

public function map_3<TI, TO1, TO2, TO3>
  "Takes a list and a function, and creates three new lists by applying the
   function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  output list<TO1> outList1 = {};
  output list<TO2> outList2 = {};
  output list<TO3> outList3 = {};

  partial function MapFunc
    input TI inElement;
    output TO1 outElement1;
    output TO2 outElement2;
    output TO3 outElement3;
  end MapFunc;
protected
  TO1 e1;
  TO2 e2;
  TO3 e3;
algorithm
  for e in inList loop
    (e1, e2, e3) := inFunc(e);
    outList1 := e1 :: outList1;
    if isPresent(outList2) then
      outList2 := e2 :: outList2;
    end if;
    if isPresent(outList3) then
      outList3 := e3 :: outList3;
    end if;
  end for;

  outList1 := listReverseInPlace(outList1);
  if isPresent(outList2) then
    outList2 := listReverseInPlace(outList2);
  end if;
  if isPresent(outList3) then
    outList3 := listReverseInPlace(outList3);
  end if;
end map_3;

public function mapOption<TI, TO>
  "The same as map(map(inList, getOption), inMapFunc), but is more efficient and
   it strips out NONE() instead of failing on them."
  input list<Option<TI>> inList;
  input MapFunc inFunc;
  output list<TO> outList = {};

  partial function MapFunc
    input TI inElement;
    output TO outElement;
  end MapFunc;
protected
  TI ei;
  TO eo;
algorithm
  for oe in inList loop
    if not isNone(oe) then
      SOME(ei) := oe;
      eo := inFunc(ei);
      outList := eo :: outList;
    end if;
  end for;

  outList := listReverseInPlace(outList);
end mapOption;

public function map1Option<TI, TO, ArgT>
  "The same as map1(map(inList, getOption), inMapFunc), but is more efficient and
   it strips out NONE() instead of failing on them."
  input list<Option<TI>> inList;
  input MapFunc inFunc;
  input ArgT inArg1;
  output list<TO> outList = {};

  partial function MapFunc
    input TI inElement;
    input ArgT inArg1;
    output TO outElement;
  end MapFunc;
protected
  TI ei;
  TO eo;
algorithm
  for oe in inList loop
    if not isNone(oe) then
      SOME(ei) := oe;
      eo := inFunc(ei, inArg1);
      outList := eo :: outList;
    end if;
  end for;

  outList := listReverseInPlace(outList);
end map1Option;

public function map2Option<TI, TO, ArgT1, ArgT2>
  "The same as map2(map(inList, getOption), inMapFunc), but is more efficient and
   it strips out NONE() instead of failing on them."
  input list<Option<TI>> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  output list<TO> outList = {};

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    output TO outElement;
  end MapFunc;
protected
  TI ei;
  TO eo;
algorithm
  for oe in inList loop
    if isSome(oe) then
      SOME(ei) := oe;
      eo := inFunc(ei, inArg1, inArg2);
      outList := eo :: outList;
    end if;
  end for;

  outList := listReverseInPlace(outList);
end map2Option;

public function map_0<T>
  "Takes a list and a function which does not return a value. The function is
   probably a function with side effects, like print."
  input list<T> inList;
  input MapFunc inFunc;

  partial function MapFunc
    input T inElement;
  end MapFunc;
algorithm
  for e in inList loop
    inFunc(e);
  end for;
end map_0;

public function map1<TI, TO, ArgT1>
  "Takes a list, a function and one extra argument, and creates a new list
   by applying the function to each element of the list."
  input list<TI> inList;
  input MapFunc inMapFunc;
  input ArgT1 inArg1;
  output list<TO> outList;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inMapFunc(e, inArg1) for e in inList);
end map1;

public function map1Reverse<TI, TO, ArgT1>
  "Takes a list, a function and one extra argument, and creates a new list
   by applying the function to each element of the list. The created list will
   be reversed compared to the given list."
  input list<TI> inList;
  input MapFunc inMapFunc;
  input ArgT1 inArg1;
  output list<TO> outList;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    output TO outElement;
  end MapFunc;
algorithm
  outList := listReverse(inMapFunc(e, inArg1) for e in inList);
end map1Reverse;

public function map1r<TI, TO, ArgT1>
  "Takes a list, a function and one extra argument, and creates a new list
   by applying the function to each element of the list. The given map
   function has it's arguments reversed compared to map1."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  output list<TO> outList;

  partial function MapFunc
    input ArgT1 inArg1;
    input TI inElement;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inFunc(inArg1, e) for e in inList);
end map1r;

public function map1_0<TI, ArgT1>
  "Takes a list, a function and one extra argument, and applies the functions to
   each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
  end MapFunc;
algorithm
  for e in inList loop
    inFunc(e, inArg1);
  end for;
end map1_0;

public function map1_2<TI, TO1, TO2, ArgT1>
  "Takes a list and a function, and creates two new lists by applying the
   function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  output list<TO1> outList1 = {};
  output list<TO2> outList2 = {};

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    output TO1 outElement1;
    output TO2 outElement2;
  end MapFunc;
protected
  TO1 e1;
  TO2 e2;
algorithm
  for e in inList loop
    (e1, e2) := inFunc(e, inArg1);
    outList1 := e1 :: outList1;
    outList2 := e2 :: outList2;
  end for;

  outList1 := listReverseInPlace(outList1);
  outList2 := listReverseInPlace(outList2);
end map1_2;

public function map1_3<TI, TO1, TO2, TO3, ArgT1>
  "Takes a list and a function, and creates three new lists by applying the
   function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  output list<TO1> outList1 = {};
  output list<TO2> outList2 = {};
  output list<TO3> outList3 = {};

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    output TO1 outElement1;
    output TO2 outElement2;
    output TO3 outElement3;
  end MapFunc;
protected
  TO1 e1;
  TO2 e2;
  TO3 e3;
algorithm
  for e in inList loop
    (e1, e2, e3) := inFunc(e, inArg1);
    outList1 := e1 :: outList1;
    outList2 := e2 :: outList2;
    outList3 := e3 :: outList3;
  end for;

  outList1 := listReverseInPlace(outList1);
  outList2 := listReverseInPlace(outList2);
  outList3 := listReverseInPlace(outList3);
end map1_3;

public function map2<TI, TO, ArgT1, ArgT2>
  "Takes a list, a function and two extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  output list<TO> outList;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inFunc(e, inArg1, inArg2) for e in inList);
end map2;

public function map2Reverse<TI, TO, ArgT1, ArgT2>
  "Takes a list, a function and two extra arguments, and creates a new list
   by applying the function to each element of the list. The created list will
   be reversed compared to the given list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  output list<TO> outList;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    output TO outElement;
  end MapFunc;
algorithm
  outList := listReverse(inFunc(e, inArg1, inArg2) for e in inList);
end map2Reverse;

public function map2rm<TI, TO, ArgT1, ArgT2>
  "Takes a list, a function and two extra argument, and creates a new list
   by applying the function to each element of the list. The given map
   function has it's arguments in another order compared to map2 and map2r."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  output list<TO> outList;

  partial function MapFunc
    input ArgT1 inArg1;
    input TI inElement;
    input ArgT2 inArg2;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inFunc(inArg1, e, inArg2) for e in inList);
end map2rm;

public function map2r<TI, TO, ArgT1, ArgT2>
  "Takes a list, a function and two extra argument, and creates a new list
   by applying the function to each element of the list. The given map
   function has it's arguments reversed compared to map2."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  output list<TO> outList;

  partial function MapFunc
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input TI inElement;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inFunc(inArg1, inArg2, e) for e in inList);
end map2r;

public function map2_0<TI, ArgT1, ArgT2>
  "Takes a list, a function and two extra argument, and applies the functions to
   each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
  end MapFunc;
algorithm
  for e in inList loop
    inFunc(e, inArg1, inArg2);
  end for;
end map2_0;

public function map2_2<TI, TO1, TO2, ArgT1, ArgT2>
  "Takes a list, a function and two extra argument, and creates two new lists
   by applying the function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  output list<TO1> outList1 = {};
  output list<TO2> outList2 = {};

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    output TO1 outElement1;
    output TO2 outElement2;
  end MapFunc;
protected
  TO1 e1;
  TO2 e2;
algorithm
  for e in inList loop
    (e1, e2) := inFunc(e, inArg1, inArg2);
    outList1 := e1 :: outList1;
    outList2 := e2 :: outList2;
  end for;

  outList1 := listReverseInPlace(outList1);
  outList2 := listReverseInPlace(outList2);
end map2_2;

public function map2_3<TI, TO1, TO2, TO3, ArgT1, ArgT2>
  "Takes a list, a function and two extra argument, and creates three new lists
   by applying the function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  output list<TO1> outList1 = {};
  output list<TO2> outList2 = {};
  output list<TO3> outList3 = {};

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    output TO1 outElement1;
    output TO2 outElement2;
    output TO3 outElement3;
  end MapFunc;
protected
  TO1 e1;
  TO2 e2;
  TO3 e3;
algorithm
  for e in inList loop
    (e1, e2, e3) := inFunc(e, inArg1, inArg2);
    outList1 := e1 :: outList1;
    outList2 := e2 :: outList2;
    outList3 := e3 :: outList3;
  end for;

  outList1 := listReverseInPlace(outList1);
  outList2 := listReverseInPlace(outList2);
  outList3 := listReverseInPlace(outList3);
end map2_3;

public function map3<TI, TO, ArgT1, ArgT2, ArgT3>
  "Takes a list, a function and three extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  output list<TO> outList;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inFunc(e, inArg1, inArg2, inArg3) for e in inList);
end map3;

public function map3r<TI, TO, ArgT1, ArgT2, ArgT3>
  "Takes a list, a function and three extra argument, and creates a new list
   by applying the function to each element of the list. The given map
   function has it's arguments reversed compared to map3."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  output list<TO> outList;

  partial function MapFunc
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    input TI inElement;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inFunc(inArg1, inArg2, inArg3, e) for e in inList);
end map3r;

public function map3_0<TI, ArgT1, ArgT2, ArgT3>
  "Takes a list, a function and three extra argument, and applies the functions to
   each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
  end MapFunc;
algorithm
  for e in inList loop
    inFunc(e, inArg1, inArg2, inArg3);
  end for;
end map3_0;

public function map3_2<TI, TO1, TO2, ArgT1, ArgT2, ArgT3>
  "Takes a list, a function and three extra argument, and creates two new lists
   by applying the function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  output list<TO1> outList1 = {};
  output list<TO2> outList2 = {};

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    output TO1 outElement1;
    output TO2 outElement2;
  end MapFunc;
protected
  TO1 e1;
  TO2 e2;
algorithm
  for e in inList loop
    (e1, e2) := inFunc(e, inArg1, inArg2, inArg3);
    outList1 := e1 :: outList1;
    outList2 := e2 :: outList2;
  end for;

  outList1 := listReverseInPlace(outList1);
  outList2 := listReverseInPlace(outList2);
end map3_2;

public function map4<TI, TO, ArgT1, ArgT2, ArgT3, ArgT4>
  "Takes a list, a function and four extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  input ArgT4 inArg4;
  output list<TO> outList;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    input ArgT4 inArg4;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inFunc(e, inArg1, inArg2, inArg3, inArg4) for e in inList);
end map4;

public function map4_0<TI, ArgT1, ArgT2, ArgT3, ArgT4>
  "Takes a list, a function and four extra arguments, and applies the functions to
   each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  input ArgT4 inArg4;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    input ArgT4 inArg4;
  end MapFunc;
algorithm
  for e in inList loop
    inFunc(e, inArg1, inArg2, inArg3, inArg4);
  end for;
end map4_0;

public function map4_2<TI, TO1, TO2, ArgT1, ArgT2, ArgT3, ArgT4>
  "Takes a list, a function and three extra argument, and creates two new lists
   by applying the function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  input ArgT4 inArg4;
  output list<TO1> outList1 = {};
  output list<TO2> outList2 = {};

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    input ArgT4 inArg4;
    output TO1 outElement1;
    output TO2 outElement2;
  end MapFunc;
protected
  TO1 e1;
  TO2 e2;
algorithm
  for e in inList loop
    (e1, e2) := inFunc(e, inArg1, inArg2, inArg3, inArg4);
    outList1 := e1 :: outList1;
    outList2 := e2 :: outList2;
  end for;

  outList1 := listReverseInPlace(outList1);
  outList2 := listReverseInPlace(outList2);
end map4_2;

public function map5<TI, TO, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5>
  "Takes a list, a function and five extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  input ArgT4 inArg4;
  input ArgT5 inArg5;
  output list<TO> outList;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    input ArgT4 inArg4;
    input ArgT5 inArg5;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5) for e in inList);
end map5;

public function map6<TI, TO, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5, ArgT6>
  "Takes a list, a function and six extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  input ArgT4 inArg4;
  input ArgT5 inArg5;
  input ArgT6 inArg6;
  output list<TO> outList;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    input ArgT4 inArg4;
    input ArgT5 inArg5;
    input ArgT6 inArg6;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6) for e in inList);
end map6;

public function map7<TI, TO, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5, ArgT6, ArgT7>
  "Takes a list, a function and seven extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  input ArgT4 inArg4;
  input ArgT5 inArg5;
  input ArgT6 inArg6;
  input ArgT7 inArg7;
  output list<TO> outList;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    input ArgT4 inArg4;
    input ArgT5 inArg5;
    input ArgT6 inArg6;
    input ArgT7 inArg7;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6,
    inArg7) for e in inList);
end map7;

public function map8<TI, TO, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5, ArgT6, ArgT7, ArgT8>
  "Takes a list, a function and eight extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  input ArgT4 inArg4;
  input ArgT5 inArg5;
  input ArgT6 inArg6;
  input ArgT7 inArg7;
  input ArgT8 inArg8;
  output list<TO> outList;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    input ArgT4 inArg4;
    input ArgT5 inArg5;
    input ArgT6 inArg6;
    input ArgT7 inArg7;
    input ArgT8 inArg8;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6,
    inArg7, inArg8) for e in inList);
end map8;

public function map9<TI, TO, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5, ArgT6, ArgT7, ArgT8, ArgT9>
  "Takes a list, a function and nine extra arguments, and creates a new list
   by applying the function to each element of the list."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  input ArgT4 inArg4;
  input ArgT5 inArg5;
  input ArgT6 inArg6;
  input ArgT7 inArg7;
  input ArgT8 inArg8;
  input ArgT9 inArg9;
  output list<TO> outList;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    input ArgT4 inArg4;
    input ArgT5 inArg5;
    input ArgT6 inArg6;
    input ArgT7 inArg7;
    input ArgT8 inArg8;
    input ArgT9 inArg9;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6,
    inArg7, inArg8, inArg9) for e in inList);
end map9;

public function mapFlat<TI, TO>
  "Takes a list and a function that maps elements to lists, which are flattened
   into one list. Example (fill2(n) = {n, n}):
     mapFlat({1, 2, 3}, fill2) => {1, 1, 2, 2, 3, 3}"
  input list<TI> inList;
  input MapFunc inMapFunc;
  output list<TO> outList;

  partial function MapFunc
    input TI inElement;
    output list<TO> outList;
  end MapFunc;
algorithm
  outList := listReverse(mapFlatReverse(inList, inMapFunc));
end mapFlat;

public function mapFlatReverse<TI, TO>
  "Takes a list and a function that maps elements to lists, which are flattened
   into one list. Returns the values in reverse order as the input.
     Example (fill2(n) = {n, n}):
       mapFlat({1, 2, 3}, fill2) => {3, 3, 2, 2, 1, 1}"
  input list<TI> inList;
  input MapFunc inMapFunc;
  output list<TO> outList = {};

  partial function MapFunc
    input TI inElement;
    output list<TO> outList;
  end MapFunc;
algorithm
  for e in inList loop
    outList := listAppend(inMapFunc(e), outList);
  end for;
end mapFlatReverse;

public function map1Flat<TI, TO, ArgT1>
  "Takes a list and a function that maps elements to lists, which are flattened
   into one list. This function also takes an extra argument that is passed to
   the mapping function."
  input list<TI> inList;
  input MapFunc inMapFunc;
  input ArgT1 inArg1;
  output list<TO> outList = {};

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    output list<TO> outList;
  end MapFunc;
algorithm
  for e in inList loop
    outList := listAppend(inMapFunc(e, inArg1), outList);
  end for;
  outList := listReverseInPlace(outList);
end map1Flat;

public function map2Flat<TI, TO, ArgT1, ArgT2>
  "Takes a list and a function that maps elements to lists, which are flattened
   into one list. This function also takes two extra arguments that are passed
   to the mapping function."
  input list<TI> inList;
  input MapFunc inMapFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  output list<TO> outList = {};

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    output list<TO> outList;
  end MapFunc;
algorithm
  for e in inList loop
    outList := listAppend(inMapFunc(e, inArg1, inArg2), outList);
  end for;
  outList := listReverseInPlace(outList);
end map2Flat;

public function mapMap<TI, TO1, TO2>
  "More efficient than: map(map(inList, inMapFunc1), inMapFunc2)"
  input list<TI> inList;
  input MapFunc1 inMapFunc1;
  input MapFunc2 inMapFunc2;
  output list<TO2> outList;

  partial function MapFunc1
    input TI inElement;
    output TO1 outElement;
  end MapFunc1;

  partial function MapFunc2
    input TO1 inElement;
    output TO2 outElement;
  end MapFunc2;
algorithm
  outList := list(inMapFunc2(inMapFunc1(e)) for e in inList);
end mapMap;

public function mapMap_0<TI, TO>
  "More efficient than map_0(map(inList, inMapFunc1), inMapFunc2),"
  input list<TI> inList;
  input MapFunc1 inMapFunc1;
  input MapFunc2 inMapFunc2;

  partial function MapFunc1
    input TI inElement;
    output TO outElement;
  end MapFunc1;

  partial function MapFunc2
    input TO inElement;
  end MapFunc2;
algorithm
  for e in inList loop
    inMapFunc2(inMapFunc1(e));
  end for;
end mapMap_0;

public function mapAllValue<TI, TO, VT>
  "Applies a function to all elements in the lists, and fails if not all
   elements are equal to the given value."
  input list<TI> inList;
  input MapFunc inMapFunc;
  input VT inValue;

  partial function MapFunc
    input TI inElement;
    output TO outElement;
  end MapFunc;
protected
  TO eo;
algorithm
  for e in inList loop
    eo := inMapFunc(e);
    true := valueEq(eo, inValue);
  end for;
end mapAllValue;

public function mapAllValueBool<TI, TO, VT>
  "Same as mapAllValue, but returns true or false instead of succeeding or
  failing."
  input list<TI> inList;
  input MapFunc inMapFunc;
  input VT inValue;
  output Boolean outAllValue;

  partial function MapFunc
    input TI inElement;
    output TO outElement;
  end MapFunc;
algorithm
  try
    mapAllValue(inList, inMapFunc, inValue);
    outAllValue := true;
  else
    outAllValue := false;
  end try;
end mapAllValueBool;

public function map1AllValueBool<TI, TO, VT, ArgT1>
  "Same as mapAllValueBool, but takes one extra argument."
  input list<TI> inList;
  input MapFunc inMapFunc;
  input VT inValue;
  input ArgT1 inArg1;
  output Boolean outAllValue;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    output TO outElement;
  end MapFunc;
algorithm
  try
    map1AllValue(inList, inMapFunc, inValue, inArg1);
    outAllValue := true;
  else
    outAllValue := false;
  end try;
end map1AllValueBool;

public function map1AllValue<TI, TO, VT, ArgT1>
  "Applies a function to all elements in the lists, and fails if not all
   elements are equal to the given value. This function also takes an extra
   argument that are passed to the mapping function."
  input list<TI> inList;
  input MapFunc inMapFunc;
  input VT inValue;
  input ArgT1 inArg1;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    output TO outElement;
  end MapFunc;
protected
  TO eo;
algorithm
  for e in inList loop
    eo := inMapFunc(e, inArg1);
    true := valueEq(eo, inValue);
  end for;
end map1AllValue;

public function map1rAllValue<TI, TO, VT, ArgT1>
  "Applies a function to all elements in the lists, and fails if not all
   elements are equal to the given value. This function also takes an extra
   argument that are passed to the mapping function."
  input list<TI> inList;
  input MapFunc inMapFunc;
  input VT inValue;
  input ArgT1 inArg1;

  partial function MapFunc
    input ArgT1 inArg1;
    input TI inElement;
    output TO outElement;
  end MapFunc;
protected
  TO eo;
algorithm
  for e in inList loop
    eo := inMapFunc(inArg1, e);
    true := valueEq(eo, inValue);
  end for;
end map1rAllValue;

public function map2AllValue<TI, TO, VT, ArgT1, ArgT2>
  "Applies a function to all elements in the lists, and fails if not all
   elements are equal to the given value. This function also takes two extra
   arguments that are passed to the mapping function."
  input list<TI> inList;
  input MapFunc inMapFunc;
  input VT inValue;
  input ArgT1 inArg1;
  input ArgT2 inArg2;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    output TO outElement;
  end MapFunc;
protected
  TO eo;
algorithm
  for e in inList loop
    eo := inMapFunc(e, inArg1, inArg2);
    true := valueEq(eo, inValue);
  end for;
end map2AllValue;

public function mapListAllValueBool<TI, TO, VT>
  "Same as mapAllValue, but returns true or false instead of succeeding or
  failing."
  input list<list<TI>> inList;
  input MapFunc inMapFunc;
  input VT inValue;
  output Boolean outAllValue = true;

  partial function MapFunc
    input TI inElement;
    output TO outElement;
  end MapFunc;
algorithm
  for lst in inList loop
    if not mapAllValueBool(lst, inMapFunc, inValue) then
      outAllValue := false;
      return;
    end if;
  end for;
end mapListAllValueBool;

public function map1ListAllValueBool<TI, TO, VT, ArgT1>
  "Same as mapListAllValueBool, but takes one extra argument."
  input list<list<TI>> inList;
  input MapFunc inMapFunc;
  input VT inValue;
  input ArgT1 inArg1;
  output Boolean outAllValue = true;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    output TO outElement;
  end MapFunc;
algorithm
  for lst in inList loop
    if not map1AllValueBool(lst, inMapFunc, inValue, inArg1) then
      outAllValue := false;
      return;
    end if;
  end for;
end map1ListAllValueBool;

public function foldAllValue<TI, TO, ArgT1>
  "Applies a function to all elements in the lists, and fails if not all
   elements are equal to the given value. This function also takes an extra
   argument that are passed to the mapping function and updated"
  input list<TI> inList;
  input MapFunc inMapFunc;
  input TO inValue;
  input ArgT1 inArg1;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    output TO outElement;
    output ArgT1 outArg1;
  end MapFunc;
protected
  ArgT1 arg = inArg1;
  TO eo;
algorithm
  for e in inList loop
    (eo, arg) := inMapFunc(e, arg);
    true := valueEq(eo, inValue);
  end for;
end foldAllValue;

public function applyAndFold<TI, TO, FT>
  "fold(map(inList, inApplyFunc), inFoldFunc, inFoldArg), but is more
   memory-efficient."
  input list<TI> inList;
  input FoldFunc inFoldFunc;
  input ApplyFunc inApplyFunc;
  input FT inFoldArg;
  output FT outResult = inFoldArg;

  partial function ApplyFunc
    input TI inElement;
    output TO outElement;
  end ApplyFunc;

  partial function FoldFunc
    input TO inElement;
    input FT inAccumulator;
    output FT outResult;
  end FoldFunc;
algorithm
  for e in inList loop
    outResult := inFoldFunc(inApplyFunc(e), outResult);
  end for;
end applyAndFold;

public function applyAndFold1<TI, TO, FT, ArgT1>
  "fold(map(inList, inApplyFunc(inExtraArg)), inFoldFunc, inFoldArg), but is more
   memory-efficient."
  input list<TI> inList;
  input FoldFunc inFoldFunc;
  input ApplyFunc inApplyFunc;
  input ArgT1 inExtraArg;
  input FT inFoldArg;
  output FT outResult = inFoldArg;

  partial function ApplyFunc
    input TI inElement1;
    input ArgT1 inElement2;
    output TO outElement;
  end ApplyFunc;

  partial function FoldFunc
    input TO inElement;
    input FT inAccumulator;
    output FT outResult;
  end FoldFunc;
algorithm
  for e in inList loop
    outResult := inFoldFunc(inApplyFunc(e, inExtraArg), outResult);
  end for;
end applyAndFold1;

public function mapBoolOr<TI, ArgT1>
  "Maps each element of a inList to Boolean type with inFunc. Stops mapping at first occurrence of true return value."
  input list<TI> inList;
  input MapFunc inFunc;
  output Boolean res = false;

  partial function MapFunc
    input TI inElement;
    output Boolean outBool;
  end MapFunc;
algorithm
  for e in inList loop
    if inFunc(e) then
      res := true;
      return;
    end if;
  end for;
end mapBoolOr;

public function mapBoolAnd<TI>
  "Maps each element of a inList to Boolean type with inFunc. Stops mapping at first occurrence of true return value."
  input list<TI> inList;
  input MapFunc inFunc;
  output Boolean res = false;

  partial function MapFunc
    input TI inElement;
    output Boolean outBool;
  end MapFunc;
algorithm
  for e in inList loop
    if not inFunc(e) then
      return;
    end if;
  end for;
  res := true;
end mapBoolAnd;

public function mapMapBoolAnd<TI,TI2>
  "Maps each element of a inList to Boolean type with inFunc. Stops mapping at first occurrence of true return value."
  input list<TI> inList;
  input MapFunc inFunc;
  input MapBFunc inBFunc;
  output Boolean res = false;

  partial function MapBFunc
    input TI2 inElement;
    output Boolean outBool;
  end MapBFunc;
  partial function MapFunc
    input TI inElement;
    output TI2 outElement;
  end MapFunc;
algorithm
  for e in inList loop
    if not inBFunc(inFunc(e)) then
      return;
    end if;
  end for;
  res := true;
end mapMapBoolAnd;


public function map1BoolOr<TI, ArgT1>
  "Maps each element of a inList to Boolean type with inFunc. Stops mapping at first occurrence of true return value.
  inFunc takes one additional argument."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  output Boolean res = false;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    output Boolean outBool;
  end MapFunc;
algorithm
  for e in inList loop
    if inFunc(e, inArg1) then
      res := true;
      return;
    end if;
  end for;
end map1BoolOr;


public function map1BoolAnd<TI, ArgT1>
  "Maps each element of a inList to Boolean type with inFunc. Stops mapping at first occurrence of false return value.
  inFunc takes one additional argument."
  input list<TI> inList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  output Boolean res = false;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    output Boolean outBool;
  end MapFunc;
algorithm
  for e in inList loop
    if not inFunc(e, inArg1) then
      return;
    end if;
  end for;
  res := true;
end map1BoolAnd;


public function map1ListBoolOr<TI, ArgT1>
  "Maps each element of a inList to Boolean type with inFunc. Stops mapping at first occurrence of true return value.
  inFunc takes one additional argument."
  input list<list<TI>> inListList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  output Boolean res = false;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    output Boolean outBool;
  end MapFunc;
algorithm
  for el in inListList loop
    for e in el loop
      if inFunc(e, inArg1) then
        res := true;
        return;
      end if;
    end for;
  end for;
end map1ListBoolOr;


public function mapList<TI, TO>
  "Takes a list of lists and a functions, and creates a new list of lists by
   applying the function to all elements in  the list of lists.
     Example: mapList({{1, 2},{3},{4}}, intString) =>
                      {{\"1\", \"2\"}, {\"3\"}, {\"4\"}}"
  input list<list<TI>> inListList;
  input MapFunc inFunc;
  output list<list<TO>> outListList;

  partial function MapFunc
    input TI inElement;
    output TO outElement;
  end MapFunc;
algorithm
  outListList := list(list(inFunc(e) for e in lst) for lst in inListList);
end mapList;

public function mapList0<TI>
  "Takes a list of lists and a functions, and applying
  the function to all elements in  the list of lists.
     Example: mapList0({{1, 2},{3},{4}}, print)"

  input list<list<TI>> inListList;
  input MapFunc inFunc;

  partial function MapFunc
    input TI inElement;
  end MapFunc;
algorithm
  map1_0(inListList, map_0, inFunc);
end mapList0;

public function mapList1_0<TI, ArgT1>
  "Takes a list of lists and a functions, and applying
  the function to all elements in  the list of lists.
     Example: mapList1_0({{1, 2},{3},{4}}, costomPrint, inArg1)"

  input list<list<TI>> inListList;
  input MapFunc inFunc;
  input ArgT1 inArg1;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
  end MapFunc;
algorithm
  map2_0(inListList, map1_0, inFunc, inArg1);
end mapList1_0;

public function mapList2_0<TI, ArgT1, ArgT2>
  "Takes a list of lists and a functions, and applying
  the function to all elements in  the list of lists.
     Example: mapList1_0({{1, 2},{3},{4}}, costomPrint, inArg1, inArg2)"

  input list<list<TI>> inListList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
  end MapFunc;
algorithm
  map3_0(inListList, map2_0, inFunc, inArg1, inArg2);
end mapList2_0;

public function mapList1_1<TI, TO, ArgT1>
  "Takes a list of lists and a functions, and applying
  the function to all elements in  the list of lists.
     Example: mapList1_0({{1, 2},{3},{4}}, customPrint, inArg1)"

  input list<list<TI>> inListList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  output list<list<TO>> outListList;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    output TO outElement;
  end MapFunc;
algorithm
  outListList := list(list(inFunc(e, inArg1) for e in lst) for lst in inListList);
end mapList1_1;

public function mapListReverse<TI, TO>
  "Takes a list of lists and a functions, and creates a new list of lists by
   applying the function to all elements in  the list of lists. The order of the
   elements in the inner lists will be reversed compared to mapList.
     Example: mapListReverse({{1, 2}, {3}, {4}}, intString) =>
                             {{\"4\"}, {\"3\"}, {\"2\", \"1\"}}"
  input list<list<TI>> inListList;
  input MapFunc inFunc;
  output list<list<TO>> outListList;

  partial function MapFunc
    input TI inElement;
    output TO outElement;
  end MapFunc;
algorithm
  outListList := list(listReverse(inFunc(e) for e in lst) for lst in inListList);
end mapListReverse;

public function map1List<TI, TO, ArgT1>
  "Similar to mapList but with a mapping function that takes an extra argument."
  input list<list<TI>> inListList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  output list<list<TO>> outListList;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    output TO outElement;
  end MapFunc;
algorithm
  outListList := list(list(inFunc(e, inArg1) for e in lst) for lst in inListList);
end map1List;

public function map2List<TI, TO, ArgT1, ArgT2>
  "Similar to mapList but with a mapping function that takes two extra arguments."
  input list<list<TI>> inListList;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  output list<list<TO>> outListList;

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    output TO outElement;
  end MapFunc;
algorithm
  outListList := list(list(inFunc(e, inArg1, inArg2) for e in lst) for lst in inListList);
end map2List;

public function fold<T, FT>
  "Takes a list and a function operating on list elements having an extra
   argument that is 'updated', thus returned from the function. fold will call
   the function for each element in a sequence, updating the start value.
     Example: fold({1, 2, 3}, intAdd, 2) => 8
              intAdd(1, 2) => 3, intAdd(2, 3) => 5, intAdd(3, 5) => 8"
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  for e in inList loop
    outResult := inFoldFunc(e, outResult);
  end for;
end fold;

public function foldr<T, FT>
  "Same as fold, but with reversed order on the fold function arguments."
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input FT inFoldArg;
    input T inElement;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  for e in inList loop
    outResult := inFoldFunc(outResult, e);
  end for;
end foldr;

public function fold1<T, FT, ArgT1>
  "Takes a list and a function operating on list elements having an extra
   argument that is 'updated', thus returned from the function, and a constant
   argument that is not updated. fold will call the function for each element in
   a sequence, updating the start value."
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input ArgT1 inExtraArg;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inArg;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  for e in inList loop
    outResult := inFoldFunc(e, inExtraArg, outResult);
  end for;
end fold1;

public function fold1r<T, FT, ArgT1>
  "Same as fold1, but with reversed order on the fold function arguments."
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input ArgT1 inExtraArg;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input FT inFoldArg;
    input T inElement;
    input ArgT1 inArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  for e in inList loop
    outResult := inFoldFunc(outResult, e, inExtraArg);
  end for;
end fold1r;

public function fold2<T, FT, ArgT1, ArgT2>
  "Takes a list and a function operating on list elements having an extra
   argument that is 'updated', thus returned from the function, and two constant
   arguments that is not updated. fold will call the function for each element in
   a sequence, updating the start value."
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input ArgT1 inExtraArg1;
  input ArgT2 inExtraArg2;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  for e in inList loop
    outResult := inFoldFunc(e, inExtraArg1, inExtraArg2, outResult);
  end for;
end fold2;

public function fold22<T, FT1, FT2, ArgT1, ArgT2>
  "Takes a list and a function operating on list elements having three extra
   arguments that is 'updated', thus returned from the function, and three constant
   arguments that are not updated. fold will call the function for each element in
   a sequence, updating the start values."
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input ArgT1 inExtraArg1;
  input ArgT2 inExtraArg2;
  input FT1 inStartValue1;
  input FT2 inStartValue2;
  output FT1 outResult1 = inStartValue1;
  output FT2 outResult2 = inStartValue2;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inConstantArg1;
    input ArgT2 inConstantArg2;
    input FT1 inFoldArg1;
    input FT2 inFoldArg2;
    output FT1 outFoldArg1;
    output FT2 outFoldArg2;
  end FoldFunc;
algorithm
  for e in inList loop
    (outResult1, outResult2) := inFoldFunc(e, inExtraArg1, inExtraArg2, outResult1, outResult2);
  end for;
end fold22;

public function foldList<T, FT>
  input list<list<T>> inList;
  input FoldFunc inFoldFunc;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  for lst in inList loop
    for e in lst loop
      outResult := inFoldFunc(e, outResult);
    end for;
  end for;
end foldList;

public function foldList1<T, FT, ArgT1>
  input list<list<T>> inList;
  input FoldFunc inFoldFunc;
  input ArgT1 inExtraArg1;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inConstantArg1;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  for lst in inList loop
    for e in lst loop
      outResult := inFoldFunc(e, inExtraArg1, outResult);
    end for;
  end for;
end foldList1;

public function foldList2<T, FT, ArgT1, ArgT2>
  "Takes a list and a function operating on list elements having an extra
   argument that is 'updated', thus returned from the function, and two constant
   arguments that is not updated. fold will call the function for each element in
   a sequence, updating the start value."
  input list<list<T>> inList;
  input FoldFunc inFoldFunc;
  input ArgT1 inExtraArg1;
  input ArgT2 inExtraArg2;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inConstantArg1;
    input ArgT2 inConstantArg2;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  for lst in inList loop
    for e in lst loop
      outResult := inFoldFunc(e, inExtraArg1, inExtraArg2, outResult);
    end for;
  end for;
end foldList2;

public function fold2r<T, FT, ArgT1, ArgT2>
  "Same as fold2, but with reversed order on the fold function arguments."
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input ArgT1 inExtraArg1;
  input ArgT2 inExtraArg2;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input FT inFoldArg;
    input T inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  for e in inList loop
    outResult := inFoldFunc(outResult, e, inExtraArg1, inExtraArg2);
  end for;
end fold2r;

public function fold3<T, FT, ArgT1, ArgT2, ArgT3>
  "Takes a list and a function operating on list elements having an extra
   argument that is 'updated', thus returned from the function, and three constant
   arguments that is not updated. fold will call the function for each element in
   a sequence, updating the start value."
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input ArgT1 inExtraArg1;
  input ArgT2 inExtraArg2;
  input ArgT3 inExtraArg3;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  for e in inList loop
    outResult := inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, outResult);
  end for;
end fold3;

public function fold3r<T, FT, ArgT1, ArgT2, ArgT3>
  "Same as fold3, but with reversed order on the fold function arguments."
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input ArgT1 inExtraArg1;
  input ArgT2 inExtraArg2;
  input ArgT3 inExtraArg3;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input FT inFoldArg;
    input T inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  for e in inList loop
    outResult := inFoldFunc(outResult, e, inExtraArg1, inExtraArg2, inExtraArg3);
  end for;
end fold3r;

public function fold4<T, FT, ArgT1, ArgT2, ArgT3, ArgT4>
  "Takes a list and a function operating on list elements having an extra
   argument that is 'updated', thus returned from the function, and four constant
   arguments that is not updated. fold will call the function for each element in
   a sequence, updating the start value."
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input ArgT1 inExtraArg1;
  input ArgT2 inExtraArg2;
  input ArgT3 inExtraArg3;
  input ArgT4 inExtraArg4;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    input ArgT4 inArg4;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  for e in inList loop
    outResult := inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3,
        inExtraArg4, outResult);
  end for;
end fold4;

public function fold43<T, FT1, FT2, FT3, ArgT1, ArgT2, ArgT3, ArgT4>
  "Takes a list and a function operating on list elements having three extra
   arguments that is 'updated', thus returned from the function, and three constant
   arguments that are not updated. fold will call the function for each element in
   a sequence, updating the start values."
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input ArgT1 inExtraArg1;
  input ArgT2 inExtraArg2;
  input ArgT3 inExtraArg3;
  input ArgT4 inExtraArg4;
  input FT1 inStartValue1;
  input FT2 inStartValue2;
  input FT3 inStartValue3;
  output FT1 outResult1 = inStartValue1;
  output FT2 outResult2 = inStartValue2;
  output FT3 outResult3 = inStartValue3;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inConstantArg1;
    input ArgT2 inConstantArg2;
    input ArgT3 inConstantArg3;
    input ArgT4 inConstantArg4;
    input FT1 inFoldArg1;
    input FT2 inFoldArg2;
    input FT3 inFoldArg3;
    output FT1 outFoldArg1;
    output FT2 outFoldArg2;
    output FT3 outFoldArg3;
  end FoldFunc;
algorithm
  for e in inList loop
    (outResult1, outResult2, outResult3) := inFoldFunc(e, inExtraArg1,
        inExtraArg2, inExtraArg3, inExtraArg4, outResult1, outResult2, outResult3);
  end for;
end fold43;

public function fold20<T, FT1, FT2>
  "Takes a list and a function operating on list elements having two extra
   arguments that are 'updated', thus returned from the function. fold will call
   the function for each element in a sequence, updating the start value."
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input FT1 inStartValue1;
  input FT2 inStartValue2;
  output FT1 outResult1 = inStartValue1;
  output FT2 outResult2 = inStartValue2;

  partial function FoldFunc
    input T inElement;
    input FT1 inFoldArg1;
    input FT2 inFoldArg2;
    output FT1 outFoldArg1;
    output FT2 outFoldArg2;
  end FoldFunc;
algorithm
  for e in inList loop
    (outResult1, outResult2) := inFoldFunc(e, outResult1,outResult2);
  end for;
end fold20;

public function fold30<T, FT1, FT2, FT3>
  "Takes a list and a function operating on list elements having three extra
   arguments that are 'updated', thus returned from the function. fold will call
   the function for each element in a sequence, updating the start value."
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input FT1 inStartValue1;
  input FT2 inStartValue2;
  input FT3 inStartValue3;
  output FT1 outResult1 = inStartValue1;
  output FT2 outResult2 = inStartValue2;
  output FT3 outResult3 = inStartValue3;

  partial function FoldFunc
    input T inElement;
    input FT1 inFoldArg1;
    input FT2 inFoldArg2;
    input FT3 inFoldArg3;
    output FT1 outFoldArg1;
    output FT2 outFoldArg2;
    output FT3 outFoldArg3;
  end FoldFunc;
algorithm
  for e in inList loop
    (outResult1, outResult2, outResult3) := inFoldFunc(e, outResult1,outResult2,outResult3);
  end for;
end fold30;

public function fold21<T, FT1, FT2, ArgT1>
 "Takes a list and a function operating on list elements having two extra
   argument that are 'updated', thus returned from the function, and one constant
   argument that is not updated. fold will call the function for each element in
   a sequence, updating the start value."
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input ArgT1 inExtraArg1;
  input FT1 inStartValue1;
  input FT2 inStartValue2;
  output FT1 outResult1 = inStartValue1;
  output FT2 outResult2 = inStartValue2;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inExtraArg1;
    input FT1 inFoldArg1;
    input FT2 inFoldArg2;
    output FT1 outFoldArg1;
    output FT2 outFoldArg2;
  end FoldFunc;
algorithm
  for e in inList loop
    (outResult1, outResult2) := inFoldFunc(e, inExtraArg1, outResult1,outResult2);
  end for;
end fold21;

public function fold31<T, FT1, FT2, FT3, ArgT1>
 "Takes a list and a function operating on list elements having three extra
   argument that are 'updated', thus returned from the function, and one constant
   argument that is not updated. fold will call the function for each element in
   a sequence, updating the start value."
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input ArgT1 inExtraArg1;
  input FT1 inStartValue1;
  input FT2 inStartValue2;
  input FT3 inStartValue3;
  output FT1 outResult1 = inStartValue1;
  output FT2 outResult2 = inStartValue2;
  output FT3 outResult3 = inStartValue3;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inExtraArg1;
    input output FT1 inFoldArg1;
    input output FT2 inFoldArg2;
    input output FT3 inFoldArg3;
  end FoldFunc;
algorithm
  for e in inList loop
    (outResult1, outResult2, outResult3) := inFoldFunc(e, inExtraArg1, outResult1, outResult2, outResult3);
  end for;
end fold31;


public function fold5<T, FT, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5>
  "Takes a list and a function operating on list elements having an extra
   argument that is 'updated', thus returned from the function, and five constant
   arguments that is not updated. fold will call the function for each element in
   a sequence, updating the start value."
  input list<T> inList;
  input FoldFunc inFoldFunc;
  input ArgT1 inExtraArg1;
  input ArgT2 inExtraArg2;
  input ArgT3 inExtraArg3;
  input ArgT4 inExtraArg4;
  input ArgT5 inExtraArg5;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    input ArgT4 inArg4;
    input ArgT5 inArg5;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  for e in inList loop
    outResult := inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3,
        inExtraArg4, inExtraArg5, outResult);
  end for;
end fold5;

public function mapFold<TI, TO, FT>
  "Takes a list, an extra argument and a function. The function will be applied
  to each element in the list, and the extra argument will be passed to the
  function and updated."
  input list<TI> inList;
  input FuncType inFunc;
  input FT inArg;
  output list<TO> outList = {};
  output FT outArg = inArg;

  partial function FuncType
    input TI inElem;
    input FT inArg;
    output TO outResult;
    output FT outArg;
  end FuncType;
protected
  TO res;
algorithm
  for e in inList loop
    (res, outArg) := inFunc(e, outArg);
    outList := res :: outList;
  end for;
  outList := listReverseInPlace(outList);
end mapFold;

public function mapFold2<TI, TO, FT1, FT2>
  "Takes a list, a function, and two extra arguments. The function will be applied
  to each element in the list, and the extra arguments will be passed to the
  function and updated."
  input list<TI> inList;
  input FuncType inFunc;
  input FT1 inArg1;
  input FT2 inArg2;
  output list<TO> outList = {};
  output FT1 outArg1 = inArg1;
  output FT2 outArg2 = inArg2;

  partial function FuncType
    input TI inElem;
    input FT1 inArg1;
    input FT2 inArg2;
    output TO outResult;
    output FT1 outArg1;
    output FT2 outArg2;
  end FuncType;
protected
  TO res;
algorithm
  for e in inList loop
    (res, outArg1, outArg2) := inFunc(e, outArg1, outArg2);
    outList := res::outList;
  end for;
  outList := listReverseInPlace(outList);
end mapFold2;

public function mapFold3<TI, TO, FT1, FT2, FT3>
  "Takes a list, a function, and three extra arguments. The function will be applied
  to each element in the list, and the extra arguments will be passed to the
  function and updated."
  input list<TI> inList;
  input FuncType inFunc;
  output list<TO> outList = {};
  input output FT1 inArg1;
  input output FT2 inArg2;
  input output FT3 inArg3;

  partial function FuncType
    input TI inElem;
    output TO outResult;
    input output FT1 inArg1;
    input output FT2 inArg2;
    input output FT3 inArg3;
  end FuncType;
protected
  TO res;
algorithm
  for e in inList loop
    (res, inArg1, inArg2, inArg3) := inFunc(e, inArg1, inArg2, inArg3);
    outList := res::outList;
  end for;
  outList := listReverseInPlace(outList);
end mapFold3;

public function mapFold4<TI, TO, FT1, FT2, FT3, FT4>
  "Takes a list, a function, and four extra arguments. The function will be applied
  to each element in the list, and the extra arguments will be passed to the
  function and updated."
  input list<TI> inList;
  input FuncType inFunc;
  output list<TO> outList = {};
  input output FT1 inArg1;
  input output FT2 inArg2;
  input output FT3 inArg3;
  input output FT4 inArg4;

  partial function FuncType
    input TI inElem;
    output TO outResult;
    input output FT1 inArg1;
    input output FT2 inArg2;
    input output FT3 inArg3;
    input output FT4 inArg4;
  end FuncType;
protected
  TO res;
algorithm
  for e in inList loop
    (res, inArg1, inArg2, inArg3, inArg4) := inFunc(e, inArg1, inArg2, inArg3, inArg4);
    outList := res::outList;
  end for;
  outList := listReverseInPlace(outList);
end mapFold4;

public function mapFold5<TI, TO, FT1, FT2, FT3, FT4, FT5>
  "Takes a list, a function, and five extra arguments. The function will be applied
  to each element in the list, and the extra arguments will be passed to the
  function and updated."
  input list<TI> inList;
  input FuncType inFunc;
  output list<TO> outList = {};
  input output FT1 inArg1;
  input output FT2 inArg2;
  input output FT3 inArg3;
  input output FT4 inArg4;
  input output FT5 inArg5;

  partial function FuncType
    input TI inElem;
    output TO outResult;
    input output FT1 inArg1;
    input output FT2 inArg2;
    input output FT3 inArg3;
    input output FT4 inArg4;
    input output FT5 inArg5;
  end FuncType;
protected
  TO res;
algorithm
  for e in inList loop
    (res, inArg1, inArg2, inArg3, inArg4, inArg5) := inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5);
    outList := res::outList;
  end for;
  outList := listReverseInPlace(outList);
end mapFold5;

public function map1Fold<TI, TO, FT, ArgT1>
  "Takes a list, an extra argument, an extra constant argument, and a function.
  The function will be applied to each element in the list, and the extra
  argument will be passed to the function and updated."
  input list<TI> inList;
  input FuncType inFunc;
  input ArgT1 inConstArg;
  input FT inArg;
  output list<TO> outList = {};
  output FT outArg = inArg;

  partial function FuncType
    input TI inElem;
    input ArgT1 inConstArg;
    input FT inArg;
    output TO outResult;
    output FT outArg;
  end FuncType;
protected
  TO res;
algorithm
  for e in inList loop
    (res, outArg) := inFunc(e, inConstArg, outArg);
    outList := res :: outList;
  end for;
  outList := listReverseInPlace(outList);
end map1Fold;

public function map2Fold<TI, TO, FT, ArgT1, ArgT2>
  "Takes a list, two extra constant arguments, an extra argument, and a function.
  The function will be applied to each element in the list, and the extra
  argument will be passed to the function and updated."
  input list<TI> inList;
  input FuncType inFunc;
  input ArgT1 inConstArg;
  input ArgT2 inConstArg2;
  input FT inArg;
  input list<TO> inAccum = {};
  output list<TO> outList = inAccum;
  output FT outArg = inArg;

  partial function FuncType
    input TI inElem;
    input ArgT1 inConstArg;
    input ArgT2 inConstArg2;
    input FT inArg;
    output TO outResult;
    output FT outArg;
  end FuncType;
protected
  TO res;
algorithm
  for e in inList loop
    (res, outArg) := inFunc(e, inConstArg, inConstArg2, outArg);
    outList := res :: outList;
  end for;
  outList := listReverseInPlace(outList);
end map2Fold;

public function map2FoldCheckReferenceEq<TIO, FT, ArgT1, ArgT2>
  "Takes a list, two extra constant arguments, an extra argument, and a function.
  The function will be applied to each element in the list, and the extra
  argument will be passed to the function and updated."
  input list<TIO> inList;
  input FuncType inFunc;
  input ArgT1 inConstArg;
  input ArgT2 inConstArg2;
  input FT inArg;
  output list<TIO> outList;
  output FT outArg = inArg;

  partial function FuncType
    input TIO inElem;
    input ArgT1 inConstArg;
    input ArgT2 inConstArg2;
    input FT inArg;
    output TIO outResult;
    output FT outArg;
  end FuncType;
protected
  TIO res;
  Boolean allEq=true;
  DoubleEndedList<TIO> delst;
  Integer n=0;
algorithm
  for e in inList loop
    (res, outArg) := inFunc(e, inConstArg, inConstArg2, outArg);
    if (if allEq then not referenceEq(e, res) else false) then
      allEq:=false;
      delst := DoubleEndedList.empty(res);
      for elt in inList loop
        if n < 1 then
          break;
        end if;
        DoubleEndedList.push_back(delst, elt);
        n := n-1;
      end for;
    end if;
    if allEq then
      n := n + 1;
    else
      DoubleEndedList.push_back(delst, res);
    end if;
  end for;
  outList := if allEq then inList else DoubleEndedList.toListAndClear(delst);
end map2FoldCheckReferenceEq;

public function map3Fold<TI, TO, FT, ArgT1, ArgT2, ArgT3>
  "Takes a list, three extra constant arguments, an extra argument, and a function.
  The function will be applied to each element in the list, and the extra
  argument will be passed to the function and updated."
  input list<TI> inList;
  input FuncType inFunc;
  input ArgT1 inConstArg;
  input ArgT2 inConstArg2;
  input ArgT3 inConstArg3;
  input FT inArg;
  output list<TO> outList = {};
  output FT outArg = inArg;

  partial function FuncType
    input TI inElem;
    input ArgT1 inConstArg;
    input ArgT2 inConstArg2;
    input ArgT3 inConstArg3;
    input FT inArg;
    output TO outResult;
    output FT outArg;
  end FuncType;
protected
  TO res;
algorithm
  for e in inList loop
    (res, outArg) := inFunc(e, inConstArg, inConstArg2, inConstArg3, outArg);
    outList := res :: outList;
  end for;
  outList := listReverseInPlace(outList);
end map3Fold;

public function map4Fold<TI, TO, FT, ArgT1, ArgT2, ArgT3, ArgT4>
  "Takes a list, four extra constant arguments, an extra argument, and a function.
  The function will be applied to each element in the list, and the extra
  argument will be passed to the function and updated."
  input list<TI> inList;
  input FuncType inFunc;
  input ArgT1 inConstArg;
  input ArgT2 inConstArg2;
  input ArgT3 inConstArg3;
  input ArgT4 inConstArg4;
  input FT inArg;
  output list<TO> outList = {};
  output FT outArg = inArg;

  partial function FuncType
    input TI inElem;
    input ArgT1 inConstArg;
    input ArgT2 inConstArg2;
    input ArgT3 inConstArg3;
    input ArgT4 inConstArg4;
    input FT inArg;
    output TO outResult;
    output FT outArg;
  end FuncType;
protected
  TO res;
algorithm
  for e in inList loop
    (res, outArg) := inFunc(e, inConstArg, inConstArg2, inConstArg3,
        inConstArg4, outArg);
    outList := res :: outList;
  end for;
  outList := listReverseInPlace(outList);
end map4Fold;

public function mapFoldTuple<TI, TO, FT>
  "Takes a list, an extra argument and a function. The function will be applied
  to each element in the list, and the extra argument will be passed to the
  function and updated. The input and outputs of the function are joined as
  tuples."
  input list<TI> inList;
  input FuncType inFunc;
  input FT inArg;
  output list<TO> outList = {};
  output FT outArg = inArg;

  partial function FuncType
    input tuple<TI, FT> inTuple;
    output tuple<TO, FT> outTuple;
  end FuncType;
protected
  TO res;
algorithm
  for e in inList loop
    ((res, outArg)) := inFunc((e, outArg));
    outList := res :: outList;
  end for;
  outList := listReverseInPlace(outList);
end mapFoldTuple;

public function mapFoldList<TI, TO, FT>
  "Takes a list of lists, an extra argument, and a function.  The function will
  be applied to each element in the list, and the extra argument will be passed
  to the function and updated for each element."
  input list<list<TI>> inListList;
  input FuncType inFunc;
  input FT inArg;
  output list<list<TO>> outListList = {};
  output FT outArg = inArg;

  partial function FuncType
    input TI inElem;
    input FT inArg;
    output TO outResult;
    output FT outArg;
  end FuncType;
protected
  list<TO> res;
algorithm
  for lst in inListList loop
    (res, outArg) := mapFold(lst, inFunc, outArg);
    outListList := res :: outListList;
  end for;
  outListList := listReverseInPlace(outListList);
end mapFoldList;

public function map3FoldList<TI, TO, FT, ArgT1, ArgT2, ArgT3>
  "Takes a list of lists, an extra argument, and a function.  The function will
  be applied to each element in the list, and the extra argument will be passed
  to the function and updated for each element."
  input list<list<TI>> inListList;
  input FuncType inFunc;
  input ArgT1 inConstArg1;
  input ArgT2 inConstArg2;
  input ArgT3 inConstArg3;
  input FT inArg;
  output list<list<TO>> outListList = {};
  output FT outArg = inArg;

  partial function FuncType
    input TI inElem;
    input ArgT1 inConstArg1;
    input ArgT2 inConstArg2;
    input ArgT3 inConstArg3;
    input FT inArg;
    output TO outResult;
    output FT outArg;
  end FuncType;
protected
  list<TO> res;
algorithm
  for lst in inListList loop
    (res, outArg) := map3Fold(lst, inFunc, inConstArg1, inConstArg2, inConstArg3, inArg);
    outListList := res :: outListList;
  end for;
  outListList := listReverseInPlace(outListList);
end map3FoldList;

public function mapFoldListTuple<TI, TO, FT>
  "Takes a list of lists, an extra argument and a function. The function will be
  applied to each element in the list, and the extra argument will be passed to
  the function and updated. The input and outputs of the function are joined as
  tuples."
  input list<list<TI>> inListList;
  input FuncType inFunc;
  input TO inFoldArg;
  output list<list<TO>> outListList = {};
  output TO outFoldArg = inFoldArg;

  partial function FuncType
    input tuple<TI, FT> inTuple;
    output tuple<TO, FT> outTuple;
  end FuncType;
protected
  list<TO> res;
algorithm
  for lst in inListList loop
    (res, outFoldArg) := mapFoldTuple(lst, inFunc, outFoldArg);
    outListList := res :: outListList;
  end for;
  outListList := listReverseInPlace(outListList);
end mapFoldListTuple;

public function foldcallN<FT>
  "Takes a value and a function operating on the value n times.
     Example: foldcallN(1, intAdd, 4) => 4"
  input Integer n;
  input FoldFunc inFoldFunc;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  for i in 1:n loop
    outResult := inFoldFunc(outResult);
  end for;
end foldcallN;

public function reduce<T>
  "Takes a list and a function operating on two elements of the list.
   The function performs a reduction of the list to a single value using the
   function. Example:
     reduce({1, 2, 3}, intAdd) => 6"
  input list<T> inList;
  input ReduceFunc inReduceFunc;
  output T outResult;

  partial function ReduceFunc
    input T inElement1;
    input T inElement2;
    output T outElement;
  end ReduceFunc;
protected
  list<T> rest;
algorithm
  outResult :: rest := inList;
  for e in rest loop
    outResult := inReduceFunc(outResult, e);
  end for;
end reduce;

public function reduce1<T, ArgT1>
  "Takes a list and a function operating on two elements of the list.
   The function performs a reduction of the list to a single value using the
   function. This function also takes an extra argument that is sent to the
   reduction function."
  input list<T> inList;
  input ReduceFunc inReduceFunc;
  input ArgT1 inExtraArg1;
  output T outResult;

  partial function ReduceFunc
    input T inElement1;
    input T inElement2;
    input ArgT1 inExtraArg1;
    output T outElement;
  end ReduceFunc;
protected
  list<T> rest;
algorithm
  outResult :: rest := inList;
  for e in rest loop
    outResult := inReduceFunc(outResult, e, inExtraArg1);
  end for;
end reduce1;

public function flatten<T>
  "Takes a list of lists and flattens it out, producing one list of all elements
   of the sublists. O(len(outList))
     Example: flatten({{1, 2}, {3, 4, 5}, {6}, {}}) => {1, 2, 3, 4, 5, 6}"
  input list<list<T>> inList;
  output list<T> outList = listAppend(lst for lst in listReverse(inList));
end flatten;

public function flattenReverse<T>
  input list<list<T>> inList;
  output list<T> outList = listAppend(lst for lst in inList);
end flattenReverse;

public function thread<T>
  "Takes two lists of the same type and threads (interleaves) them together.
     Example: thread({1, 2, 3}, {4, 5, 6}) => {4, 1, 5, 2, 6, 3}"
  input list<T> inList1;
  input list<T> inList2;
  input list<T> inAccum = {};
  output list<T> outList = {};
protected
  T e2;
  list<T> rest_e2 = inList2;
algorithm
  for e1 in inList1 loop
    e2 :: rest_e2 := rest_e2;

    outList := e1 :: e2 :: outList;
  end for;

  true := listEmpty(rest_e2);
  outList := listReverseInPlace(outList);
end thread;

public function thread3<T>
  "Takes three lists of the same type and threads (interleaves) them together.
     Example: thread({1, 2, 3}, {4, 5, 6}, {7, 8, 9}) =>
             {7, 4, 1, 8, 5, 2, 9, 6, 3}"
  input list<T> inList1;
  input list<T> inList2;
  input list<T> inList3;
  output list<T> outList = {};
protected
  T e2, e3;
  list<T> rest_e2 = inList2, rest_e3 = inList3;
algorithm
  for e1 in inList1 loop
    e2 :: rest_e2 := rest_e2;
    e3 :: rest_e3 := rest_e3;

    outList := e1 :: e2 :: e3 :: outList;
  end for;

  true := listEmpty(rest_e2);
  true := listEmpty(rest_e3);
  outList := listReverseInPlace(outList);
end thread3;

public function threadTuple<T1, T2>
  "Takes two lists and threads (interleaves) the arguments into a list of tuples
   consisting of the two element types.
     Example: threadTuple({1, 2, 3}, {true, false, true}) =>
              {(1, true), (2, false), (3, true)}"
  input list<T1> inList1;
  input list<T2> inList2;
  output list<tuple<T1, T2>> outTuples;
algorithm
  outTuples := list((e1, e2) threaded for e1 in inList1, e2 in inList2);
end threadTuple;

public function unzip<T1, T2>
  "Takes a list of two-element tuples and splits the tuples into two separate
   lists. Example: unzip({(1, 2), (3, 4)}) => ({1, 3}, {2, 4})"
  input list<tuple<T1, T2>> inTuples;
  output list<T1> outList1 = {};
  output list<T2> outList2 = {};
protected
  T1 e1;
  T2 e2;
algorithm
  for tpl in inTuples loop
    (e1, e2) := tpl;
    outList1 := e1 :: outList1;
    outList2 := e2 :: outList2;
  end for;
  outList1 := listReverseInPlace(outList1);
  outList2 := listReverseInPlace(outList2);
end unzip;

public function unzipReverse<T1, T2>
  "Like unzip, but returns the lists in reverse order."
  input list<tuple<T1, T2>> inTuples;
  output list<T1> outList1 = {};
  output list<T2> outList2 = {};
protected
  T1 e1;
  T2 e2;
algorithm
  for tpl in inTuples loop
    (e1, e2) := tpl;
    outList1 := e1 :: outList1;
    outList2 := e2 :: outList2;
  end for;
end unzipReverse;

public function unzipFirst<T1, T2>
  "Takes a list of two-element tuples and creates a list from the first element
   of each tuple. Example: unzipFirst({(1, 2), (3, 4)}) => {1, 3}"
  input list<tuple<T1, T2>> inTuples;
  output list<T1> outList = {};
protected
  T1 e;
algorithm
  for tpl in inTuples loop
    (e, _) := tpl;
    outList := e :: outList;
  end for;
  outList := listReverseInPlace(outList);
end unzipFirst;

public function unzipSecond<T1, T2>
  "Takes a list of two-element tuples and creates a list from the second element
   of each tuple. Example: unzipFirst({(1, 2), (3, 4)}) => {2, 4}"
  input list<tuple<T1, T2>> inTuples;
  output list<T2> outList = {};
protected
  T2 e;
algorithm
  for tpl in inTuples loop
    (_, e) := tpl;
    outList := e :: outList;
  end for;
  outList := listReverseInPlace(outList);
end unzipSecond;

public function thread3Tuple<T1, T2, T3>
  "Takes three lists and threads (interleaves) the arguments into a list of tuples
   consisting of the three element types."
  input list<T1> inList1;
  input list<T2> inList2;
  input list<T3> inList3;
  output list<tuple<T1, T2, T3>> outTuples;
algorithm
  outTuples := list((e1, e2, e3) threaded for e1 in inList1, e2 in inList2, e3 in inList3);
end thread3Tuple;

public function thread4Tuple<T1, T2, T3, T4>
  "Takes three lists and threads (interleaves) the arguments into a list of tuples
   consisting of the four element types."
  input list<T1> inList1;
  input list<T2> inList2;
  input list<T3> inList3;
  input list<T4> inList4;
  output list<tuple<T1, T2, T3, T4>> outTuples;
algorithm
  outTuples := list((e1, e2, e3, e4) threaded for e1 in inList1, e2 in inList2,
      e3 in inList3, e4 in inList4);
end thread4Tuple;

public function thread5Tuple<T1, T2, T3, T4, T5>
  "Takes three lists and threads (interleaves) the arguments into a list of tuples
   consisting of the five element types."
  input list<T1> inList1;
  input list<T2> inList2;
  input list<T3> inList3;
  input list<T4> inList4;
  input list<T5> inList5;
  output list<tuple<T1, T2, T3, T4, T5>> outTuples;
algorithm
  outTuples := list((e1, e2, e3, e4, e5) threaded for e1 in inList1, e2 in inList2,
      e3 in inList3, e4 in inList4, e5 in inList5);
end thread5Tuple;

public function threadMap<T1, T2, TO>
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list.
     Example: threadMap({1, 2}, {3, 4}, intAdd) => {1+3, 2+4}"
  input list<T1> inList1;
  input list<T2> inList2;
  input MapFunc inMapFunc;
  output list<TO> outList;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inMapFunc(e1, e2) threaded for e1 in inList1, e2 in inList2);
end threadMap;

public function threadMapReverse<T1, T2, TO>
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. The order of the result list
   will be reversed compared to the input lists.
     Example: threadMap({1, 2}, {3, 4}, intAdd) => {2+4, 1+3}"
  input list<T1> inList1;
  input list<T2> inList2;
  input MapFunc inMapFunc;
  output list<TO> outList;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    output TO outElement;
  end MapFunc;
algorithm
  outList := listReverse(inMapFunc(e1, e2) threaded for e1 in inList1, e2 in inList2);
end threadMapReverse;

public function threadMap_2<T1, T2, TO1, TO2>
  "Like threadMap, but returns two lists instead of one."
  input list<T1> inList1;
  input list<T2> inList2;
  input MapFunc inMapFunc;
  output list<TO1> outList1 = {};
  output list<TO2> outList2 = {};

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    output TO1 outElement1;
    output TO2 outElement2;
  end MapFunc;
protected
  T2 e2;
  list<T2> rest_e2 = inList2;
  TO1 ret1;
  TO2 ret2;
algorithm
  for e1 in inList1 loop
    e2 :: rest_e2 := rest_e2;
    (ret1, ret2) := inMapFunc(e1, e2);
    outList1 := ret1 :: outList1;
    outList2 := ret2 :: outList2;
  end for;

  outList1 := listReverseInPlace(outList1);
  outList2 := listReverseInPlace(outList2);
end threadMap_2;

public function threadMapList<T1, T2, TO>
  "Takes two lists of lists and a function and threads (interleaves) and maps
   the elements of the two lists, creating a new list.
     Example: threadMapList({{1, 2}}, {{3, 4}}, intAdd) => {{1 + 3, 2 + 4}}"
  input list<list<T1>> inList1;
  input list<list<T2>> inList2;
  input MapFunc inMapFunc;
  output list<list<TO>> outList;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(threadMap(lst1, lst2, inMapFunc) threaded for lst1 in inList1,
      lst2 in inList2);
end threadMapList;

public function threadMapList_2<T1, T2, TO1, TO2>
  "Like threadMapList, but returns two lists instead of one."
  input list<list<T1>> inList1;
  input list<list<T2>> inList2;
  input MapFunc inMapFunc;
  output list<list<TO1>> outList1 = {};
  output list<list<TO2>> outList2 = {};

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    output TO1 outElement1;
    output TO2 outElement2;
  end MapFunc;
protected
  list<T2> l2;
  list<list<T2>> rest_l2 = inList2;
  list<TO1> ret1;
  list<TO2> ret2;
algorithm
  for l1 in inList1 loop
    l2 :: rest_l2 := rest_l2;
    (ret1, ret2) := threadMap_2(l1, l2, inMapFunc);
    outList1 := ret1 :: outList1;
    outList2 := ret2 :: outList2;
  end for;

  outList1 := listReverseInPlace(outList1);
  outList2 := listReverseInPlace(outList2);
end threadMapList_2;

public function threadTupleList<T1, T2>
  "Takes two lists of lists as arguments and produces a list of lists of a two
  tuple of the element types of each list.
  Example: threadTupleList({{1}, {2, 3}}, {{'a'}, {'b', 'c'}}) =>
             {{(1, 'a')}, {(2, 'b'), (3, 'c')}}"
  input list<list<T1>> inList1;
  input list<list<T2>> inList2;
  output list<list<tuple<T1, T2>>> outList;
algorithm
  outList := list(threadTuple(lst1, lst2) threaded for lst1 in inList1, lst2 in inList2);
end threadTupleList;

public function threadMapAllValue<T1, T2, TO, VT>
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, and checks if the result is the same as the given
   value.
     Example: threadMapAllValue({true, true}, {false, true}, boolAnd, true) =>
              fail"
  input list<T1> inList1;
  input list<T2> inList2;
  input MapFunc inMapFunc;
  input VT inValue;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    output TO outElement;
  end MapFunc;
algorithm
  _ := match(inList1, inList2)
    local
      T1 e1;
      list<T1> rest1;
      T2 e2;
      list<T2> rest2;
      TO res;

    case (e1 :: rest1, e2 :: rest2)
      equation
        res = inMapFunc(e1, e2);
        equality(res = inValue);
        threadMapAllValue(rest1, rest2, inMapFunc, inValue);
      then
        ();

    case ({}, {}) then ();
  end match;
end threadMapAllValue;

public function threadMap1<T1, T2, TO, ArgT1>
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes an
   extra arguments that are passed to the mapping function."
  input list<T1> inList1;
  input list<T2> inList2;
  input MapFunc inMapFunc;
  input ArgT1 inArg1;
  output list<TO> outList;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    input ArgT1 inArg1;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inMapFunc(e1, e2, inArg1) threaded for e1 in inList1, e2 in inList2);
end threadMap1;

public function threadMap1Reverse<T1, T2, TO, ArgT1>
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes an
   extra arguments that are passed to the mapping function. The order of the
   result list will be reversed compared to the input lists."
  input list<T1> inList1;
  input list<T2> inList2;
  input MapFunc inMapFunc;
  input ArgT1 inArg1;
  output list<TO> outList;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    input ArgT1 inArg1;
    output TO outElement;
  end MapFunc;
algorithm
  outList := listReverse(inMapFunc(e1, e2, inArg1) threaded for e1 in inList1, e2 in inList2);
end threadMap1Reverse;

public function threadMap1_0<T1, T2, ArgT1>
  "Takes two lists and a function, and applies the function to each element of
   the lists in a pairwise fashion. This function also takes an extra argument
   which is passed to the mapping function, but returns no result."
  input list<T1> inList1;
  input list<T2> inList2;
  input MapFunc inMapFunc;
  input ArgT1 inArg1;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    input ArgT1 inArg1;
  end MapFunc;
algorithm
  _ := match(inList1, inList2, inMapFunc, inArg1)
    local
      T1 e1;
      list<T1> rest1;
      T2 e2;
      list<T2> rest2;

    case ({}, {}, _, _) then ();
    case (e1 :: rest1, e2 :: rest2, _, _)
      equation
        inMapFunc(e1, e2, inArg1);
        threadMap1_0(rest1, rest2, inMapFunc, inArg1);
      then
        ();
  end match;
end threadMap1_0;

public function threadMap2<T1, T2, TO, ArgT1, ArgT2>
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes two
   extra arguments that are passed to the mapping function."
  input list<T1> inList1;
  input list<T2> inList2;
  input MapFunc inMapFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  output list<TO> outList;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inMapFunc(e1, e2, inArg1, inArg2) threaded for e1 in inList1, e2 in inList2);
end threadMap2;

public function threadMap2Reverse<T1, T2, TO, ArgT1, ArgT2>
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes two
   extra arguments that are passed to the mapping function. The order of the
   result list will be reversed compared to the input lists."
  input list<T1> inList1;
  input list<T2> inList2;
  input MapFunc inMapFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  output list<TO> outList;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    output TO outElement;
  end MapFunc;
algorithm
  outList := listReverse(inMapFunc(e1, e2, inArg1, inArg2) threaded for e1 in inList1, e2 in inList2);
end threadMap2Reverse;

public function threadMap2ReverseFold<T1, T2, TO, FT, ArgT1, ArgT2>
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes two
   extra arguments and a fold argument that are passed to the mapping function.
   The order of the result list will be reversed compared to the input lists."
  input list<T1> inList1;
  input list<T2> inList2;
  input MapFunc inMapFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input FT inFoldArg;
  input list<TO> inAccum = {};
  output list<TO> outList;
  output FT outFoldArg;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input FT inFoldArg;
    output TO outElement;
    output FT outFoldArg;
  end MapFunc;
algorithm
  (outList,outFoldArg) := match(inList1, inList2)
    local
      T1 e1;
      list<T1> rest1;
      T2 e2;
      list<T2> rest2;
      TO res;
      FT foldArg;

    case ({}, {}) then (inAccum, inFoldArg);
    case (e1 :: rest1, e2 :: rest2)
      equation
        (res, foldArg) = inMapFunc(e1, e2, inArg1, inArg2, inFoldArg);
        (outList, foldArg) = threadMap2ReverseFold(rest1, rest2, inMapFunc,
            inArg1, inArg2, foldArg, res :: inAccum);
      then
        (outList, foldArg);
  end match;
end threadMap2ReverseFold;

public function threadMap3<T1, T2, TO, ArgT1, ArgT2, ArgT3>
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes three
   extra arguments that are passed to the mapping function."
  input list<T1> inList1;
  input list<T2> inList2;
  input MapFunc inMapFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  output list<TO> outList;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inMapFunc(e1, e2, inArg1, inArg2, inArg3)
      threaded for e1 in inList1, e2 in inList2);
end threadMap3;

public function threadMap3Reverse<T1, T2, TO, ArgT1, ArgT2, ArgT3>
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes three
   extra arguments that are passed to the mapping function."
  input list<T1> inList1;
  input list<T2> inList2;
  input MapFunc inMapFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  output list<TO> outList;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    output TO outElement;
  end MapFunc;
algorithm
  outList := listReverse(inMapFunc(e1, e2, inArg1, inArg2, inArg3)
      threaded for e1 in inList1, e2 in inList2);
end threadMap3Reverse;

public function thread3Map<T1, T2, T3, TO>
  "Takes three lists and a function, and threads (interleaves) and maps the
   elements of the three lists, creating a new list.
     Example: thread3Map({1, 2}, {3, 4}, {5, 6}, intAdd3) => {1+3+5, 2+4+6}"
  input list<T1> inList1;
  input list<T2> inList2;
  input list<T3> inList3;
  input MapFunc inFunc;
  output list<TO> outList;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    input T3 inElement3;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inFunc(e1, e2, e3) threaded for e1 in inList1, e2 in inList2, e3 in inList3);
end thread3Map;

public function threadMap3ReverseFold<T1, T2, TO, FT, ArgT1, ArgT2, ArgT3>
  "Takes two lists and a function and threads (interleaves) and maps the
   elements of two lists, creating a new list. This function also takes three
   extra arguments and a fold argument that are passed to the mapping function.
   The order of the result list will be reversed compared to the input lists."
  input list<T1> inList1;
  input list<T2> inList2;
  input MapFunc inMapFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  input FT inFoldArg;
  input list<TO> inAccum = {};
  output list<TO> outList;
  output FT outFoldArg;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    input FT inFoldArg;
    output TO outElement;
    output FT outFoldArg;
  end MapFunc;
algorithm
  (outList,outFoldArg) := match(inList1, inList2)
    local
      T1 e1;
      list<T1> rest1;
      T2 e2;
      list<T2> rest2;
      TO res;
      FT foldArg;

    case (e1 :: rest1, e2 :: rest2)
      equation
        (res,foldArg) = inMapFunc(e1, e2, inArg1, inArg2, inArg3, inFoldArg);
        (outList,foldArg) = threadMap3ReverseFold(rest1, rest2, inMapFunc,
            inArg1, inArg2, inArg3, foldArg, res :: inAccum);
      then
        (outList,foldArg);

    case ({}, {}) then (inAccum, inFoldArg);
  end match;
end threadMap3ReverseFold;

public function thread3Map_2<T1, T2, T3, TO1, TO2>
  "Takes three lists and a function, and threads (interleaves) and maps the
   elements of the three lists, creating two new list.
     Example: thread3Map({1, 2}, {3, 4}, {5, 6}, intAddSub3) =>
              ({1+3+5, 2+4+6}, {1-3-5, 2-4-6})"
  input list<T1> inList1;
  input list<T2> inList2;
  input list<T3> inList3;
  input MapFunc inFunc;
  output list<TO1> outList1 = {};
  output list<TO2> outList2 = {};

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    input T3 inElement3;
    output TO1 outElement1;
    output TO2 outElement2;
  end MapFunc;
protected
  T2 e2;
  list<T2> rest_e2 = inList2;
  T3 e3;
  list<T3> rest_e3 = inList3;
  TO1 res1;
  TO2 res2;
algorithm
  for e1 in inList1 loop
    e2 :: rest_e2 := rest_e2;
    e3 :: rest_e3 := rest_e3;
    (res1, res2) := inFunc(e1, e2, e3);
    outList1 := res1 :: outList1;
    outList2 := res2 :: outList2;
  end for;

  true := listEmpty(rest_e2);
  true := listEmpty(rest_e3);
  outList1 := listReverseInPlace(outList1);
  outList2 := listReverseInPlace(outList2);
end thread3Map_2;

public function thread3MapFold<T1, T2, T3, TO, ArgT1>
  "Takes three lists and a function, and threads (interleaves) and maps the
   elements of the three lists, creating a new list. This function also takes
   one extra argument which are passed to the mapping function and fold."
  input list<T1> inList1;
  input list<T2> inList2;
  input list<T3> inList3;
  input MapFunc inFunc;
  input ArgT1 inArg;
  output list<TO> outList = {};
  output ArgT1 outArg = inArg;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    input T3 inElement3;
    input ArgT1 inArg;
    output TO outElement;
    output ArgT1 outArg;
  end MapFunc;
protected
  T2 e2;
  list<T2> rest_e2 = inList2;
  T3 e3;
  list<T3> rest_e3 = inList3;
  TO res;
algorithm
  for e1 in inList1 loop
    e2 :: rest_e2 := rest_e2;
    e3 :: rest_e3 := rest_e3;
    (res, outArg) := inFunc(e1, e2, e3, outArg);
    outList := res :: outList;
  end for;

  true := listEmpty(rest_e2);
  true := listEmpty(rest_e3);
  outList := listReverseInPlace(outList);
end thread3MapFold;

public function thread3Map3<T1, T2, T3, TO, ArgT1, ArgT2, ArgT3>
  "Takes three lists and a function, and threads (interleaves) and maps the
   elements of the three lists, creating a new list. This function also takes
   three extra arguments which are passed to the mapping function."
  input list<T1> inList1;
  input list<T2> inList2;
  input list<T3> inList3;
  input MapFunc inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  output list<TO> outList;

  partial function MapFunc
    input T1 inElement1;
    input T2 inElement2;
    input T3 inElement3;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    output TO outElement;
  end MapFunc;
algorithm
  outList := list(inFunc(e1, e2, e3, inArg1, inArg2, inArg3) threaded for
      e1 in inList1, e2 in inList2, e3 in inList3);
end thread3Map3;

public function threadFold1<T1, T2, FT, ArgT1>
  "This is a combination of thread and fold that applies a function to the head
   of two lists with an extra argument that is updated and passed on. This
   function also takes an extra constant argument that is passed to the function."
  input list<T1> inList1;
  input list<T2> inList2;
  input FoldFunc inFoldFunc;
  input ArgT1 inArg1;
  input FT inFoldArg;
  output FT outFoldArg;

  partial function FoldFunc
    input T1 inElement1;
    input T2 inElement2;
    input ArgT1 inArg1;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  outFoldArg := match(inList1, inList2)
    local
      T1 e1;
      list<T1> rest1;
      T2 e2;
      list<T2> rest2;
      FT res;

    case (e1 :: rest1, e2 :: rest2)
      equation
        res = inFoldFunc(e1, e2, inArg1, inFoldArg);
      then
        threadFold1(rest1, rest2, inFoldFunc, inArg1, res);

    case ({}, {}) then inFoldArg;

  end match;
end threadFold1;

public function threadFold2<T1, T2, FT, ArgT1, ArgT2>
  "This is a combination of thread and fold that applies a function to the head
   of two lists with an extra argument that is updated and passed on. This
   function also takes two extra constant arguments that is passed to the function."
  input list<T1> inList1;
  input list<T2> inList2;
  input FoldFunc inFoldFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input FT inFoldArg;
  output FT outFoldArg;

  partial function FoldFunc
    input T1 inElement1;
    input T2 inElement2;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  outFoldArg := match(inList1, inList2)
    local
      T1 e1;
      list<T1> rest1;
      T2 e2;
      list<T2> rest2;
      FT res;

    case (e1 :: rest1, e2 :: rest2)
      equation
        res = inFoldFunc(e1, e2, inArg1, inArg2, inFoldArg);
      then
        threadFold2(rest1, rest2, inFoldFunc, inArg1, inArg2, res);

    case ({}, {}) then inFoldArg;

  end match;
end threadFold2;

public function threadFold3<T1, T2, FT, ArgT1, ArgT2, ArgT3>
  "This is a combination of thread and fold that applies a function to the head
   of two lists with an extra argument that is updated and passed on. This
   function also takes three extra constant arguments that is passed to the function."
  input list<T1> inList1;
  input list<T2> inList2;
  input FoldFunc inFoldFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  input FT inFoldArg;
  output FT outFoldArg;

  partial function FoldFunc
    input T1 inElement1;
    input T2 inElement2;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  outFoldArg := match(inList1, inList2)
    local
      T1 e1;
      list<T1> rest1;
      T2 e2;
      list<T2> rest2;
      FT res;

    case (e1 :: rest1, e2 :: rest2)
      equation
        res = inFoldFunc(e1, e2, inArg1, inArg2, inArg3, inFoldArg);
      then
        threadFold3(rest1, rest2, inFoldFunc, inArg1, inArg2, inArg3, res);

    case ({}, {}) then inFoldArg;

  end match;
end threadFold3;

public function threadFold4<T1, T2, FT, ArgT1, ArgT2, ArgT3, ArgT4>
  "This is a combination of thread and fold that applies a function to the head
   of two lists with an extra argument that is updated and passed on. This
   function also takes four extra constant arguments that is passed to the function."
  input list<T1> inList1;
  input list<T2> inList2;
  input FoldFunc inFoldFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  input ArgT4 inArg4;
  input FT inFoldArg;
  output FT outFoldArg;

  partial function FoldFunc
    input T1 inElement1;
    input T2 inElement2;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    input ArgT4 inArg4;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  outFoldArg := match(inList1, inList2)
    local
      T1 e1;
      list<T1> rest1;
      T2 e2;
      list<T2> rest2;
      FT res;

    case (e1 :: rest1, e2 :: rest2)
      equation
        res = inFoldFunc(e1, e2, inArg1, inArg2, inArg3, inArg4, inFoldArg);
      then
        threadFold4(rest1, rest2, inFoldFunc, inArg1, inArg2, inArg3, inArg4, res);

    case ({}, {}) then inFoldArg;

  end match;
end threadFold4;

public function threadFold<T1, T2, FT>
  "This is a combination of thread and fold that applies a function to the head
   of two lists with an extra argument that is updated and passed on."
  input list<T1> inList1;
  input list<T2> inList2;
  input FoldFunc inFoldFunc;
  input FT inFoldArg;
  output FT outFoldArg;

  partial function FoldFunc
    input T1 inElement1;
    input T2 inElement2;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  outFoldArg := match(inList1, inList2)
    local
      T1 e1;
      list<T1> rest1;
      T2 e2;
      list<T2> rest2;
      FT res;

    case (e1 :: rest1, e2 :: rest2)
      equation
        res = inFoldFunc(e1, e2, inFoldArg);
      then
        threadFold(rest1, rest2, inFoldFunc, res);

    case ({}, {}) then inFoldArg;

  end match;
end threadFold;

public function threadMapFold<T1, T2, TO, FT>
  "Takes a list, an extra argument and a function. The function will be applied
  to each element in the list, and the extra argument will be passed to the
  function and updated."
  input list<T1> inList1;
  input list<T2> inList2;
  input FuncType inFunc;
  input FT inArg;
  output list<TO> outList = {};
  output FT outArg = inArg;

  partial function FuncType
    input T1 inElem1;
    input T2 inElem2;
    input FT inArg;
    output TO outResult;
    output FT outArg;
  end FuncType;
protected
  T2 e2;
  list<T2> rest_e2 = inList2;
  TO res;
algorithm
  for e1 in inList1 loop
    e2 :: rest_e2 := rest_e2;
    (res, outArg) := inFunc(e1, e2, outArg);
    outList := res :: outList;
  end for;

  true := listEmpty(rest_e2);
  outList := listReverseInPlace(outList);
end threadMapFold;

public function position<T>
  "Takes a value and a list, and returns the position of the first list element
  that whose value is equal to the given value.
    Example: position(2, {0, 1, 2, 3}) => 3"
  input T inElement;
  input list<T> inList;
  output Integer outPosition = 1 "one-based index";
algorithm
  for e in inList loop
    if valueEq(e, inElement) then
      return;
    end if;
    outPosition := outPosition + 1;
  end for;
  fail();
end position;

public function positionOnTrue<T>
  "Takes a list and a predicate function, and returns the index of the first
   element for which the function returns true, or -1 if no match is found."
  input list<T> inList;
  input PredFunc inPredFunc;
  output Integer outPosition = 1;

  partial function PredFunc
    input T inElement;
    output Boolean outMatch;
  end PredFunc;
algorithm
  for e in inList loop
    if inPredFunc(e) then
      return;
    end if;

    outPosition := outPosition + 1;
  end for;

  outPosition := -1;
end positionOnTrue;

public function position1OnTrue<T, ArgT>
  "Takes a list, a predicate function and an extra argument, and return the
   index of the first element for which the function returns true, or -1 if no
   match is found. The extra argument is passed to the predicate function for
   each call."
  input list<T> inList;
  input PredFunc inPredFunc;
  input ArgT inArg;
  output Integer outPosition = 1;

  partial function PredFunc
    input T inElement;
    input ArgT inArg;
    output Boolean outMatch;
  end PredFunc;
algorithm
  for e in inList loop
    if inPredFunc(e, inArg) then
      return;
    end if;

    outPosition := outPosition + 1;
  end for;

  outPosition := -1;
end position1OnTrue;

public function positionList<T>
  "Takes a value and a list of lists, and returns the position of the value.
   outListIndex is the index of the list the value was found in, and outPosition
   is the position in that list.
     Example: positionList(3, {{4, 2}, {6, 4, 3, 1}}) => (2, 3)"
  input T inElement;
  input list<list<T>> inList;
  output Integer outListIndex = 1 "one-based index";
  output Integer outPosition "one-based index";
algorithm
  for lst in inList loop
    outPosition := 1;

    for e in lst loop
      if valueEq(e, inElement) then
        return;
      end if;

      outPosition := outPosition + 1;
    end for;

    outListIndex := outListIndex + 1;
  end for;

  fail();
end positionList;

public function getMember<T>
  "Takes a value and a list, and returns the value if it's present in the list.
   If not present the function will fail.
     Example: listGetMember(0, {1, 2, 3}) => fail
              listGetMember(1, {1, 2, 3}) => 1"
  input T inElement;
  input list<T> inList;
  output T outElement;
protected
  T e, res;
  list<T> rest;
algorithm
  for e in inList loop
    if valueEq(inElement, e) then
      outElement := e;
      return;
    end if;
  end for;
  fail();
end getMember;

public function getMemberOnTrue<T, VT>
  "Takes a value and a list of values and a comparison function over two values.
   If the value is present in the list (using the comparison function returning
   true) the value is returned, otherwise the function fails.
   Example:
     function equalLength(string,string) returns true if the strings are of same length
     getMemberOnTrue(\"a\",{\"bb\",\"b\",\"ccc\"},equalLength) => \"b\""
  input VT inValue;
  input list<T> inList;
  input CompFunc inCompFunc;
  output T outElement;

  partial function CompFunc
    input VT inValue;
    input T inElement;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  for e in inList loop
    if inCompFunc(inValue, e) then
      outElement := e;
      return;
    end if;
  end for;
  fail();
end getMemberOnTrue;

public function notMember<T>
  "Returns true if a list does not contain the given element, otherwise false."
  input T inElement;
  input list<T> inList;
  output Boolean outIsNotMember;
algorithm
  outIsNotMember := not listMember(inElement, inList);
end notMember;

public function isMemberOnTrue<T, VT>
  "Returns true if the given value is a member of the list, as determined by the
  comparison function given."
  input VT inValue;
  input list<T> inList;
  input CompFunc inCompFunc;
  output Boolean outIsMember;

  partial function CompFunc
    input VT inValue;
    input T inElement;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  for e in inList loop
    if inCompFunc(inValue, e) then
      outIsMember := true;
      return;
    end if;
  end for;

  outIsMember := false;
end isMemberOnTrue;

public function exist<T>
  "Returns true if a certain element exists in the given list as indicated by
   the given predicate function.
     Example:
       exist({1,2}, isEven) => true
       exist({1,3,5,7}, isEven) => false"
  input list<T> inList;
  input FindFunc inFindFunc;
  output Boolean outExists;

  partial function FindFunc
    input T inElement;
    output Boolean outFound;
  end FindFunc;
algorithm
  for e in inList loop
    if inFindFunc(e) then
      outExists := true;
      return;
    end if;
  end for;

  outExists := false;
end exist;

public function exist1<T, ArgT1>
  "Returns true if a certain element exists in the given list as indicated by
   the given predicate function. Also takes an extra argument that is passed to
   the predicate function."
  input list<T> inList;
  input FindFunc inFindFunc;
  input ArgT1 inExtraArg;
  output Boolean outExists;

  partial function FindFunc
    input T inElement;
    input ArgT1 inExtraArg;
    output Boolean outFound;
  end FindFunc;
algorithm
  for e in inList loop
    if inFindFunc(e, inExtraArg) then
      outExists := true;
      return;
    end if;
  end for;

  outExists := false;
end exist1;

public function exist2<T, ArgT1, ArgT2>
  "Returns true if a certain element exists in the given list as indicated by
   the given predicate function. Also takes two extra arguments that is passed
   to the predicate function."
  input list<T> inList;
  input FindFunc inFindFunc;
  input ArgT1 inExtraArg1;
  input ArgT2 inExtraArg2;
  output Boolean outExists;

  partial function FindFunc
    input T inElement;
    input ArgT1 inExtraArg1;
    input ArgT2 inExtraArg2;
    output Boolean outFound;
  end FindFunc;
algorithm
  for e in inList loop
    if inFindFunc(e, inExtraArg1, inExtraArg2) then
      outExists := true;
      return;
    end if;
  end for;

  outExists := false;
end exist2;

public function extractOnTrue<T>
  "Takes a list of values and a filter function over the values and returns
   two lists. One of values for which the matching function returns true and the
   other containing the remaining elements.
     Example:
       extractOnTrue({1, 2, 3, 4, 5}, isEven) => {2, 4}, {1, 3, 5}"
  input list<T> inList;
  input FilterFunc inFilterFunc;
  output list<T> outExtractedList = {};
  output list<T> outRemainingList = {};

  partial function FilterFunc
    input T inElement;
    output Boolean outResult;
  end FilterFunc;
algorithm
  for e in inList loop
    if inFilterFunc(e) then
      outExtractedList := e :: outExtractedList;
    else
      outRemainingList := e :: outRemainingList;
    end if;
  end for;

  outExtractedList := listReverseInPlace(outExtractedList);
  outRemainingList := listReverseInPlace(outRemainingList);
end extractOnTrue;

public function extract1OnTrue<T, ArgT1>
  "Takes a list of values and a filter function over the values and an extra
   argument and returns two lists. One of values for which the matching function
   returns true and the other containing the remaining elements."
  input list<T> inList;
  input FilterFunc inFilterFunc;
  input ArgT1 inArg;
  output list<T> outExtractedList = {};
  output list<T> outRemainingList = {};

  partial function FilterFunc
    input T inElement;
    input ArgT1 inArg;
    output Boolean outResult;
  end FilterFunc;
algorithm
  for e in inList loop
    if inFilterFunc(e, inArg) then
      outExtractedList := e :: outExtractedList;
    else
      outRemainingList := e :: outRemainingList;
    end if;
  end for;

  outExtractedList := listReverseInPlace(outExtractedList);
  outRemainingList := listReverseInPlace(outRemainingList);
end extract1OnTrue;

public function filter<T>
  "Takes a list of values and a filter function over the values and returns a
   sub list of values for which the matching function succeeds.
     Example:
       filter({1, 2, 3, 4, 5}, isEven) => {2, 4}"
  input list<T> inList;
  input FilterFunc inFilterFunc;
  output list<T> outList = {};

  partial function FilterFunc
    input T inElement;
  end FilterFunc;
algorithm
  for e in inList loop
    try
      inFilterFunc(e);
      outList := e :: outList;
    else
    end try;
  end for;

  outList := listReverseInPlace(outList);
end filter;

public function filterMap<TI, TO>
  "Applies a function to each element in the given list, but also filters out
   all elements for which the function fails."
  input list<TI> inList;
  input FilterMapFunc inFilterMapFunc;
  output list<TO> outList = {};

  partial function FilterMapFunc
    input TI inElement;
    output TO outElement;
  end FilterMapFunc;
protected
  TO oe;
algorithm
  for e in inList loop
    try
      oe := inFilterMapFunc(e);
      outList := oe :: outList;
    else
    end try;
  end for;

  outList := listReverseInPlace(outList);
end filterMap;

public function filterMap1<TI, TO, ArgT1>
  "Applies a function to each element in the given list, but also filters out
   all elements for which the function fails."
  input list<TI> inList;
  input FilterMapFunc inFilterMapFunc;
  input ArgT1 inExtraArg;
  output list<TO> outList = {};

  partial function FilterMapFunc
    input TI inElement;
    input ArgT1 inExtraArg;
    output TO outElement;
  end FilterMapFunc;
protected
  TO oe;
algorithm
  for e in inList loop
    try
      oe := inFilterMapFunc(e, inExtraArg);
      outList := oe :: outList;
    else
    end try;
  end for;

  outList := listReverseInPlace(outList);
end filterMap1;

public function filterOnTrue<T>
  "Takes a list of values and a filter function over the values and returns a
   sub list of values for which the matching function returns true.
     Example:
       filter({1, 2, 3, 4, 5}, isEven) => {2, 4}"
  input list<T> inList;
  input FilterFunc inFilterFunc;
  output list<T> outList;

  partial function FilterFunc
    input T inElement;
    output Boolean outResult;
  end FilterFunc;
algorithm
  outList := list(e for e guard(inFilterFunc(e)) in inList);
end filterOnTrue;

public function filterOnFalse<T>
  "Takes a list of values and a filter function over the values and returns a
   sub list of values for which the matching function returns false.
     Example:
       filterOnFalse({1, 2, 3, 1, 5}, isEven) => {1, 3, 1, 5}"
  input list<T> inList;
  input FilterFunc inFilterFunc;
  output list<T> outList;

  partial function FilterFunc
    input T inElement;
    output Boolean outResult;
  end FilterFunc;
algorithm
  outList := list(e for e guard(boolNot(inFilterFunc(e))) in inList);
end filterOnFalse;

public function filter1OnTrueSync<T1, T2, ArgT1>
  "like filterOnTrue but performs the same filtering synchronously on a second list.
  Takes 2 list of values and a filter function and an extra argument over the values of the first list and returns a
   sub list of values for both lists for which the matching function returns true for the first list.
     Example:
       filter({1, 2, 3, 4, 5}, isEven) => {2, 4}"
  input list<T1> inList;
  input FilterFunc inFilterFunc;
  input ArgT1 inArg1;
  input list<T2> inSyncList;
  output list<T1> outList_a = {};
  output list<T2> outList_b = {};

  partial function FilterFunc
    input T1 inElement;
    input ArgT1 inArg1;
    output Boolean outResult;
  end FilterFunc;
protected
  T2 e2;
  list<T2> rest2 = inSyncList;
algorithm
  for e1 in inList loop
    e2 :: rest2 := rest2;

    if inFilterFunc(e1, inArg1) then
      outList_a := e1 :: outList_a;
      outList_b := e2 :: outList_b;
    end if;
  end for;

  outList_a := listReverseInPlace(outList_a);
  outList_b := listReverseInPlace(outList_b);
end filter1OnTrueSync;

public function filterOnTrueSync<T1, T2>
  "Like filterOnTrue but performs the same filtering synchronously on a second list.
   Takes 2 list of values and a filter function over the values of the first
   list and returns a sub list of values for both lists for which the matching
   function returns true for the first list."
  input list<T1> inList;
  input FilterFunc inFilterFunc;
  input list<T2> inSyncList;
  output list<T1> outList_a = {};
  output list<T2> outList_b = {};

  partial function FilterFunc
    input T1 inElement;
    output Boolean outResult;
  end FilterFunc;
protected
  T2 e2;
  list<T2> rest2 = inSyncList;
algorithm
  true := listLength(inList) == listLength(inSyncList);

  for e1 in inList loop
    e2 :: rest2 := rest2;

    if inFilterFunc(e1) then
      outList_a := e1 :: outList_a;
      outList_b := e2 :: outList_b;
    end if;
  end for;

  outList_a := listReverseInPlace(outList_a);
  outList_b := listReverseInPlace(outList_b);
end filterOnTrueSync;

public function filterOnTrueReverse<T>
  "Takes a list of values and a filter function over the values and returns a
   sub list of values in reverse order for which the matching function returns true.
     Example:
       filter({1, 2, 3, 4, 5}, isEven) => {4, 2}"
  input list<T> inList;
  input FilterFunc inFilterFunc;
  output list<T> outList;

  partial function FilterFunc
    input T inElement;
    output Boolean outResult;
  end FilterFunc;
algorithm
  outList := listReverse(e for e guard(inFilterFunc(e)) in inList);
end filterOnTrueReverse;

public function filter1<T, ArgT1>
  "Takes a list of values, a filter function over the values and an extra
   argument, and returns a sub list of values for which the matching function
   succeeds.
     Example:
       filter({1, 2, 3, 4, 5}, isEven) => {2, 4}"
  input list<T> inList;
  input FilterFunc inFilterFunc;
  input ArgT1 inArg1;
  output list<T> outList = {};

  partial function FilterFunc
    input T inElement;
    input ArgT1 inArg1;
  end FilterFunc;
algorithm
  for e in inList loop
    try
      inFilterFunc(e, inArg1);
      outList := e :: outList;
    else
    end try;
  end for;

  outList := listReverseInPlace(outList);
end filter1;

public function filter1OnTrue<T, ArgT1>
  "Takes a list of values and a filter function over the values and returns a
   sub list of values for which the matching function returns true.
     Example:
       filter1OnTrue({1, 2, 3, 1, 5}, intEq, 1) => {1, 1}"
  input list<T> inList;
  input FilterFunc inFilterFunc;
  input ArgT1 inArg1;
  output list<T> outList;

  partial function FilterFunc
    input T inElement;
    input ArgT1 inArg1;
    output Boolean outResult;
  end FilterFunc;
algorithm
  outList := list(e for e guard(inFilterFunc(e, inArg1)) in inList);
end filter1OnTrue;

public function filter1rOnTrue<T, ArgT1>
  "Takes a list of values and a filter function over the values and returns a
   sub list of values for which the matching function returns true.
     Example:
       filter1rOnTrue({1, 2, 3, 1, 5}, intEq, 1) => {1, 1}"
  input list<T> inList;
  input FilterFunc inFilterFunc;
  input ArgT1 inArg1;
  output list<T> outList;

  partial function FilterFunc
    input ArgT1 inArg1;
    input T inElement;
    output Boolean outResult;
  end FilterFunc;
algorithm
  outList := list(e for e guard(inFilterFunc(inArg1, e)) in inList);
end filter1rOnTrue;

public function filter2OnTrue<T, ArgT1, ArgT2>
  "Takes a list of values and a filter function over the values and returns a
   sub list of values for which the matching function returns true."
  input list<T> inList;
  input FilterFunc inFilterFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  output list<T> outList;

  partial function FilterFunc
    input T inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    output Boolean outResult;
  end FilterFunc;
algorithm
  outList := list(e for e guard(inFilterFunc(e, inArg1, inArg2)) in inList);
end filter2OnTrue;

public function removeOnTrue<T, VT>
  "Goes through a list and removes all elements which are equal to the given
   value, using the given comparison function."
  input VT inValue;
  input CompFunc inCompFunc;
  input list<T> inList;
  output list<T> outList;

  partial function CompFunc
    input VT inValue;
    input T inElement;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  outList := list(e for e guard(not inCompFunc(inValue, e)) in inList);
end removeOnTrue;

public function select = filterOnTrue;
public function select1 = filter1OnTrue;
public function select1r = filter1rOnTrue;
public function select2 = filter2OnTrue;

public function find<T>
  "This function retrieves the first element of a list for which the passed
   function evaluates to true."
  input list<T> inList;
  input SelectFunc inFunc;
  output T outElement;

  partial function SelectFunc
    input T inElement;
    output Boolean outSelect;
  end SelectFunc;
algorithm
  for e in inList loop
    if inFunc(e) then
      outElement := e;
      return;
    end if;
  end for;
  fail();
end find;

public function find1<T, ArgT1>
  "This function retrieves the first element of a list for which the passed
   function evaluates to true."
  input list<T> inList;
  input SelectFunc inFunc;
  input ArgT1 arg1;
  output T outElement;

  partial function SelectFunc
    input T inElement;
    input ArgT1 arg;
    output Boolean outSelect;
  end SelectFunc;
algorithm
  for e in inList loop
    if inFunc(e, arg1) then
      outElement := e;
      return;
    end if;
  end for;
  fail();
end find1;

public function findAndRemove<T>
  "This function retrieves the first element of a list for which the passed
   function evaluates to true. And returns the list with the element removed."
  input list<T> inList;
  input SelectFunc inFunc;
  output T outElement;
  output list<T> rest;

  partial function SelectFunc
    input T inElement;
    output Boolean outSelect;
  end SelectFunc;
protected
  Integer i=0;
  DoubleEndedList<T> delst;
  T t;
algorithm
  for e in inList loop
    if inFunc(e) then
      outElement := e;
      delst := DoubleEndedList.fromList({});
      rest := inList;
      for i in 1:i loop
        t::rest := rest;
        DoubleEndedList.push_back(delst, t);
      end for;
      _::rest := rest;
      rest := DoubleEndedList.toListAndClear(delst, prependToList=rest);
      return;
    end if;
    i := i + 1;
  end for;
  fail();
end findAndRemove;


public function findAndRemove1<T, ArgT1>
  "This function retrieves the first element of a list for which the passed
   function evaluates to true. And returns the list with the element removed."
  input list<T> inList;
  input SelectFunc inFunc;
  input ArgT1 arg1;
  output T outElement;
  output list<T> rest;

  partial function SelectFunc
    input T inElement;
    input ArgT1 arg;
    output Boolean outSelect;
  end SelectFunc;
protected
  Integer i=0;
  DoubleEndedList<T> delst;
  T t;
algorithm
  for e in inList loop
    if inFunc(e, arg1) then
      outElement := e;
      delst := DoubleEndedList.fromList({});
      rest := inList;
      for i in 1:i loop
        t::rest := rest;
        DoubleEndedList.push_back(delst, t);
      end for;
      _::rest := rest;
      rest := DoubleEndedList.toListAndClear(delst, prependToList=rest);
      return;
    end if;
    i := i + 1;
  end for;
  fail();
end findAndRemove1;

public function findBoolList<T>
  "This function returns the first value in the given list for which the
   corresponding element in the boolean list is true."
  input list<Boolean> inBooleans;
  input list<T> inList;
  input T inFalseValue;
  output T outElement;
protected
  T e;
  list<T> rest = inList;
algorithm
  for b in inBooleans loop
    e :: rest := rest;

    if b then
      outElement := e;
      return;
    end if;
  end for;
  outElement := inFalseValue;
end findBoolList;

public function deleteMember<T>
  "Takes a list and a value, and deletes the first occurence of the value in the
   list. Example: deleteMember({1, 2, 3, 2}, 2) => {1, 3, 2}"
  input list<T> inList;
  input T inElement;
  output list<T> outList = {};
protected
  T e;
  list<T> rest = inList;
algorithm
  while not listEmpty(rest) loop
    e :: rest := rest;

    if valueEq(e, inElement) then
      outList := append_reverse(outList, rest);
      return;
    end if;

    outList := e :: outList;
  end while;
  outList := inList;
end deleteMember;

public function deleteMemberF<T>
  "Same as deleteMember, but fails if the element isn't present in the list."
  input list<T> inList;
  input T inElement;
  output list<T> outList;
algorithm
  outList := deleteMember(inList, inElement);
  if referenceEq(outList, inList) then fail(); end if;
end deleteMemberF;

public function deleteMemberOnTrue<T, VT>
  "Takes a list and a value and a comparison function and deletes the first
  occurence of the value in the list for which the function returns true. It
  returns the new list and the deleted element, or only the original list if
  no element was removed.
    Example: deleteMemberOnTrue({1,2,3,2},2,intEq) => {1,3,2}"
  input VT inValue;
  input list<T> inList;
  input CompareFunc inCompareFunc;
  output list<T> outList = inList;
  output Option<T> outDeletedElement = NONE();

  partial function CompareFunc
    input VT inValue;
    input T inElement;
    output Boolean outIsEqual;
  end CompareFunc;
protected
  T e;
  list<T> rest = inList, acc = {};
algorithm
  while not listEmpty(rest) loop
    e :: rest := rest;

    if inCompareFunc(inValue, e) then
      outList := append_reverse(acc, rest);
      outDeletedElement := SOME(e);
      return;
    end if;

    acc := e :: acc;
  end while;
end deleteMemberOnTrue;

public function deletePositions<T>
  "Takes a list and a list of positions, and deletes the positions from the
   list. Note that positions are indexed from 0.
     Example: deletePositions({1, 2, 3, 4, 5}, {2, 0, 3}) => {2, 5}"
  input list<T> inList;
  input list<Integer> inPositions;
  output list<T> outList;
protected
  list<Integer> sorted_pos;
algorithm
  sorted_pos := sortedUnique(sort(inPositions, intGt), intEq);
  outList := deletePositionsSorted(inList, sorted_pos);
end deletePositions;

public function deletePositionsSorted<T>
  "Takes a list and a sorted list of positions (smallest index first), and
   deletes the positions from the list. Note that positions are indexed from 0.
     Example: deletePositionsSorted({1, 2, 3, 4, 5}, {0, 2, 3}) => {2, 5}"
  input list<T> inList;
  input list<Integer> inPositions;
  output list<T> outList = {};
protected
  Integer i = 0;
  T e;
  list<T> rest = inList;
algorithm
  for pos in inPositions loop
    while i <> pos loop
      e :: rest := rest;
      outList := e :: outList;
      i := i + 1;
    end while;

    _ :: rest := rest;
    i := i + 1;
  end for;

  outList := append_reverse(outList, rest);
end deletePositionsSorted;

public function removeMatchesFirst
  "Removes all matching integers that occur first in a list. If the first
   element doesn't match it returns the list."
  input list<Integer> inList;
  input Integer inN;
  output list<Integer> outList = inList;
algorithm
  for e in inList loop
    if e <> inN then
      break;
    end if;

    _ :: outList := outList;
  end for;
end removeMatchesFirst;

public function replaceAt<T>
  "Takes an element, a position and a list, and replaces the value at the given
   position in the list. Position is an integer between 1 and n for a list of
   n elements.
     Example: replaceAt('A', 2, {'a', 'b', 'c'}) => {'a', 'A', 'c'}"
  input T inElement;
  input Integer inPosition "one-based index" ;
  input list<T> inList;
  output list<T> outList;
protected
  T e;
  list<T> rest = inList;
  DoubleEndedList<T> delst;
algorithm
  true := inPosition >= 1;
  delst := DoubleEndedList.fromList({});

  // Shuffle elements from inList to outList until the position is reached.
  for i in 1:inPosition-1 loop
    e :: rest := rest;
    DoubleEndedList.push_back(delst, e);
  end for;

  // Replace the element at the position and append the remaining elements.
  _ :: rest := rest;
  outList := DoubleEndedList.toListAndClear(delst, prependToList=inElement::rest);
end replaceAt;

public function replaceOnTrue<T>
  "Applies the function to each element of the list until the function returns
   true, and then replaces that element with the replacement.
     Example: replaceOnTrue(4, {1, 2, 3}, isTwo) => {1, 4, 3}."
  input T inReplacement;
  input list<T> inList;
  input FuncType inFunc;
  output list<T> outList = {};
  output Boolean outReplaced = false;

  partial function FuncType
    input T inElement;
    output Boolean outReplace;
  end FuncType;
protected
  T e;
  list<T> rest = inList;
algorithm
  while not listEmpty(rest) loop
    e :: rest := rest;

    if inFunc(e) then
      outReplaced := true;
      outList := append_reverse(outList, inReplacement :: rest);
      return;
    end if;

    outList := e :: outList;
  end while;

  outList := inList;
end replaceOnTrue;

public function replaceAtIndexFirst<T>
  "Takes an element, a position and a list, and replaces the value at the given
   position in the list. Position is an integer between 1 and n for a list of
   n elements.
     Example: replaceAtIndexFirst(2, 'A', {'a', 'b', 'c'}) => {'a', 'A', 'c'}"
  input Integer inPosition "one-based index" ;
  input T inElement;
  input list<T> inList;
  output list<T> outList;
algorithm
  outList := replaceAt(inElement, inPosition, inList);
end replaceAtIndexFirst;

public function replaceAtWithList<T>
  "Takes an list, a position and a list, and replaces the element at the given
  position with the first list in the second list. Position is an integer
  between 0 and n - 1 for a list of n elements.
     Example: replaceAt({'A', 'B'}, 1, {'a', 'b', 'c'}) => {'a', 'A', 'B', 'c'}"
  input list<T> inReplacementList;
  input Integer inPosition;
  input list<T> inList;
  output list<T> outList = {};
protected
  T e;
  list<T> rest = inList;
algorithm
  true := inPosition >= 0;

  // Shuffle elements from inList to outList until the position is reached.
  for i in 0:inPosition-1 loop
    e :: rest := rest;
    outList := e :: outList;
  end for;

  // Replace the element at the position and append the remaining elements.
  _ :: rest := rest;
  rest := listAppend(inReplacementList, rest);
  outList := append_reverse(outList, rest);
end replaceAtWithList;

public function replaceAtWithFill<T>
  "Takes
   - an element,
   - a position (indexed from 1)
   - a list and
   - a fill value
   The function replaces the value at the given position in the list, if the
   given position is out of range, the fill value is used to padd the list up to
   that element position and then insert the value at the position
     Example: replaceAtWithFill(\"A\", 5, {\"a\",\"b\",\"c\"},\"dummy\") =>
              {\"a\",\"b\",\"c\",\"dummy\",\"A\"}"
  input T inElement;
  input Integer inPosition;
  input list<T> inList;
  input T inFillValue;
  output list<T> outList;
protected
  Integer len;
  list<T> fill_lst;
algorithm
  true := inPosition >= 0;
  len := listLength(inList);

  if inPosition <= len then
    outList := replaceAt(inElement, inPosition, inList);
  else
    fill_lst := {inElement};
    for i in 2:(inPosition - len) loop
      fill_lst := inFillValue :: fill_lst;
    end for;

    outList := listAppend(inList, fill_lst);
  end if;
end replaceAtWithFill;

public function toString<T>
  "Creates a string from a list and a function that maps a list element to a
   string. It also takes several parameters that determine the formatting of
   the string. Ex:
     toString({1, 2, 3}, intString, 'nums', '{', ';', '}, true) =>
     'nums{1;2;3}'
  "
  input list<T> inList;
  input FuncType inPrintFunc;
  input String inListNameStr "The name of the list.";
  input String inBeginStr "The start of the list";
  input String inDelimitStr "The delimiter between list elements.";
  input String inEndStr "The end of the list.";
  input Boolean inPrintEmpty "If false, don't output begin and end if the list is empty.";
  output String outString;

  partial function FuncType
    input T inElement;
    output String outString;
  end FuncType;
algorithm
  outString := match(inList, inPrintEmpty)
    local
      String str;

    // Empty list and inPrintEmpty true => concatenate the list name, begin
    // string and end string.
    case ({}, true)
      then stringAppendList({inListNameStr, inBeginStr, inEndStr});

    // Empty list and inPrintEmpty false => output only list name.
    case ({}, false)
      then inListNameStr;

    else
      equation
        str = stringDelimitList(map(inList, inPrintFunc), inDelimitStr);
        str = stringAppendList({inListNameStr, inBeginStr, str, inEndStr});
      then
        str;

  end match;
end toString;

public function hasOneElement<T>
  "@author:adrpo
   returns true if the list has exactly one element, otherwise false"
  input list<T> inList;
  output Boolean b;
algorithm
  b := match(inList)
    case {_} then true;
    else false;
  end match;
end hasOneElement;

public function hasSeveralElements<T>
"author:waurich
 returns true if the list has more than one element, otherwise false"
  input list<T> inList;
  output Boolean b;
algorithm
  b := match(inList)
    case {_} then false;
    case {} then false;
    else true;
  end match;
end hasSeveralElements;

public function lengthListElements<T>
  input list<list<T>> inListList;
  output Integer outLength;
algorithm
  outLength := sum(listLength(lst) for lst in inListList);
end lengthListElements;

public function generate<T, ArgT1>
  "This function generates a list by calling the given function with the given
   argument. The elements generated by the function are accumulated in a list
   until the function returns false as the last return value."
  input ArgT1 inArg;
  input GenerateFunc inFunc;
  output list<T> outList;

  partial function GenerateFunc
    input ArgT1 inArg;
    output ArgT1 outArg;
    output T outElement;
    output Boolean outContinue;
  end GenerateFunc;
algorithm
  outList := listReverseInPlace(generateReverse(inArg, inFunc));
end generate;

public function generateReverse<T, ArgT1>
  "This function generates a list by calling the given function with the given
   argument. The elements generated by the function are accumulated in a list
   until the function returns false as the last return value. This function
   returns the generated list reversed."
  input ArgT1 inArg;
  input GenerateFunc inFunc;
  output list<T> outList = {};

  partial function GenerateFunc
    input ArgT1 inArg;
    output ArgT1 outArg;
    output T outElement;
    output Boolean outContinue;
  end GenerateFunc;
protected
  Boolean cont;
  ArgT1 arg = inArg;
  T e;
algorithm
  while true loop
    (arg, e, cont) := inFunc(arg);
    if not cont then break; end if;
    outList := e :: outList;
  end while;
end generateReverse;

public function mapFoldSplit<TI, TO, FT>
  "Like mapFold, but with the function split into a map and a fold function."
  input list<TI> inList;
  input MapFunc inMapFunc;
  input FoldFunc inFoldFunc;
  input FT inStartValue;
  output list<TO> outList = {};
  output FT outResult = inStartValue;

  partial function MapFunc
    input TI inElem;
    output TO outElem;
    output FT outResult;
  end MapFunc;

  partial function FoldFunc
    input FT inNewValue;
    input FT inOldValue;
    output FT outFoldedValue;
  end FoldFunc;
protected
  TO eo;
  FT res;
algorithm
  for e in inList loop
    (eo, res) := inMapFunc(e);
    outResult := inFoldFunc(res, outResult);
    outList := eo :: outList;
  end for;
  outList := listReverseInPlace(outList);
end mapFoldSplit;

public function map1FoldSplit<TI, TO, FT, ArgT1>
  "Like map1Fold, but with the function split into a map and a fold function."
  input list<TI> inList;
  input MapFunc inMapFunc;
  input FoldFunc inFoldFunc;
  input ArgT1 inConstArg;
  input FT inStartValue;
  output list<TO> outList = {};
  output FT outResult = inStartValue;

  partial function MapFunc
    input TI inElem;
    input ArgT1 inConstArg;
    output TO outElem;
    output FT outResult;
  end MapFunc;

  partial function FoldFunc
    input FT inNewValue;
    input FT inOldValue;
    output FT outFoldedValue;
  end FoldFunc;
protected
  TO eo;
  FT res;
algorithm
  for e in inList loop
    (eo, res) := inMapFunc(e, inConstArg);
    outResult := inFoldFunc(res, outResult);
    outList := eo :: outList;
  end for;
  outList := listReverseInPlace(outList);
end map1FoldSplit;

public function accumulateMap = accumulateMapAccum;

public function accumulateMapReverse<TI, TO>
  "Takes a list and a function. The function is applied to each element in the
   list, and the function is itself responsible for adding elements to the
   result list."
  input list<TI> inList;
  input MapFunc inMapFunc;
  output list<TO> outList = {};

  partial function MapFunc
    input TI inElement;
    input list<TO> inAccumList;
    output list<TO> outList;
  end MapFunc;
algorithm
  for e in inList loop
    outList := inMapFunc(e, outList);
  end for;
end accumulateMapReverse;

public function accumulateMapAccum<TI, TO>
  "Takes a list, a function and a result list. The function is applied to each
   element of the list, and the function is itself responsible for adding
   elements to the result list."
  input list<TI> inList;
  input MapFunc inMapFunc;
  output list<TO> outList = {};

  partial function MapFunc
    input TI inElement;
    input list<TO> inAccumList;
    output list<TO> outList;
  end MapFunc;
algorithm
  for e in inList loop
    outList := inMapFunc(e, outList);
  end for;
  outList := listReverse(outList);
end accumulateMapAccum;

public function accumulateMapAccum1<TI, TO, ArgT1>
  "Takes a list, a function, an extra argument, and a result list. The function
   is applied to each element of the list, and the function is itself responsible
   for adding elements to the result list."
  input list<TI> inList;
  input MapFunc inMapFunc;
  input ArgT1 inArg;
  output list<TO> outList = {};

  partial function MapFunc
    input TI inElement;
    input ArgT1 inArg;
    input list<TO> inAccumList;
    output list<TO> outList;
  end MapFunc;
algorithm
  for e in inList loop
    outList := inMapFunc(e, inArg, outList);
  end for;
  outList := listReverse(outList);
end accumulateMapAccum1;

public function accumulateMapFold = accumulateMapFoldAccum;

public function accumulateMapFoldAccum<TI, TO, FT>
  input list<TI> inList;
  input FuncType inFunc;
  input FT inFoldArg;
  output list<TO> outList = {};
  output FT outFoldArg = inFoldArg;

  partial function FuncType
    input TI inElement;
    input FT inFoldArg;
    input list<TO> inAccumList;
    output list<TO> outList;
    output FT outFoldArg;
  end FuncType;
algorithm
  for e in inList loop
    (outList, outFoldArg) := inFunc(e, outFoldArg, outList);
  end for;
  outList := listReverse(outList);
end accumulateMapFoldAccum;

public function first2FromTuple3<T>
  input tuple<T, T, T> inTuple;
  output list<T> outList;
protected
  T a, b;
algorithm
  (a, b, _) := inTuple;
  outList := {a, b};
end first2FromTuple3;

public function findMap<T>
  "Same as map, but stops when it find a certain element as indicated by the
   mapping function. Returns the new list, and whether the element was found or
   not."
  input list<T> inList;
  input FuncType inFunc;
  output list<T> outList = {};
  output Boolean outFound = false;

  partial function FuncType
    input T inElement;
    output T outElement;
    output Boolean outFound;
  end FuncType;
protected
  T e;
  list<T> rest = inList;
algorithm
  while not listEmpty(rest) and not outFound loop
    e :: rest := rest;
    (e, outFound) := inFunc(e);
    outList := e :: outList;
  end while;

  outList := append_reverse(outList, rest);
end findMap;

public function findMap1<T, ArgT1>
  "Same as map1, but stops when it find a certain element as indicated by the
   mapping function. Returns the new list, and whether the element was found or
   not."
  input list<T> inList;
  input FuncType inFunc;
  input ArgT1 inArg1;
  output list<T> outList = {};
  output Boolean outFound = false;

  partial function FuncType
    input T inElement;
    input ArgT1 inArg1;
    output T outElement;
    output Boolean outFound;
  end FuncType;
protected
  T e;
  list<T> rest = inList;
algorithm
  while not listEmpty(rest) and not outFound loop
    e :: rest := rest;
    (e, outFound) := inFunc(e, inArg1);
    outList := e :: outList;
  end while;

  outList := append_reverse(outList, rest);
end findMap1;

public function findMap2<T, ArgT1, ArgT2>
  "Same as map2, but stops when it find a certain element as indicated by the
   mapping function. Returns the new list, and whether the element was found or
   not."
  input list<T> inList;
  input FuncType inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  output list<T> outList = {};
  output Boolean outFound = false;

  partial function FuncType
    input T inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    output T outElement;
    output Boolean outFound;
  end FuncType;
protected
  T e;
  list<T> rest = inList;
algorithm
  while not listEmpty(rest) and not outFound loop
    e :: rest := rest;
    (e, outFound) := inFunc(e, inArg1, inArg2);
    outList := e :: outList;
  end while;

  outList := append_reverse(outList, rest);
end findMap2;

public function findMap3<T, ArgT1, ArgT2, ArgT3>
  "Same as map3, but stops when it find a certain element as indicated by the
   mapping function. Returns the new list, and whether the element was found or
   not."
  input list<T> inList;
  input FuncType inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  output list<T> outList = {};
  output Boolean outFound = false;

  partial function FuncType
    input T inElement;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    input ArgT3 inArg3;
    output T outElement;
    output Boolean outFound;
  end FuncType;
protected
  T e;
  list<T> rest = inList;
algorithm
  while not listEmpty(rest) and not outFound loop
    e :: rest := rest;
    (e, outFound) := inFunc(e, inArg1, inArg2, inArg3);
    outList := e :: outList;
  end while;

  outList := append_reverse(outList, rest);
end findMap3;

public function findSome<T1,T2>
  "Applies the given function over the list and returns first returned value that is not NONE()."
  input list<T1> inList;
  input FuncType inFunc;
  output T2 outVal;

  partial function FuncType
    input T1 inElement;
    output Option<T2> outValOpt;
  end FuncType;
protected
  Option<T2> retOpt = NONE();
  T1 e;
  list<T1> rest = inList;
algorithm
  while isNone(retOpt)/*not listEmpty(rest) and not outFound*/ loop
    e :: rest := rest;
    retOpt := inFunc(e);
  end while;
  outVal := match retOpt
    case SOME(outVal)
      then outVal;
    end match;
end findSome;

public function findSome1<T1,T2,Arg>
  "Applies the given function with one extra argument over the list and returns first returned value that is not NONE()."
  input list<T1> inList;
  input FuncType inFunc;
  input Arg inArg;
  output T2 outVal;

  partial function FuncType
    input T1 inElement;
    input Arg inArg;
    output Option<T2> outValOpt;
  end FuncType;
protected
  Option<T2> retOpt = NONE();
  T1 e;
  list<T1> rest = inList;
algorithm
  while isNone(retOpt)/*not listEmpty(rest) and not outFound*/ loop
    e :: rest := rest;
    retOpt := inFunc(e,inArg);
  end while;
  outVal := match retOpt
    case SOME(outVal)
      then outVal;
    end match;
end findSome1;

public function splitEqualPrefix<T1, T2>
  input list<T1> inFullList;
  input list<T2> inPrefixList;
  input EqFunc inEqFunc;
  input list<T1> inAccum = {};
  output list<T1> outPrefix = {};
  output list<T1> outRest;

  partial function EqFunc
    input T1 inElem1;
    input T2 inElem2;
    output Boolean outIsEqual;
  end EqFunc;
protected
  T1 e1;
  T2 e2;
  list<T1> rest_e1 = inFullList;
  list<T2> rest_e2 = inPrefixList;
algorithm
  while true loop
    if listEmpty(rest_e1) or listEmpty(rest_e2) then
      break;
    end if;

    e1 :: rest_e1 := rest_e1;
    e2 :: rest_e2 := rest_e2;

    if not inEqFunc(e1, e2) then
      break;
    end if;

    outPrefix := e1 :: outPrefix;
  end while;

  outPrefix := listReverseInPlace(outPrefix);
  outRest := rest_e1;
end splitEqualPrefix;

public function combination<TI>
  "Takes a two-dimensional list and creates a list combinations
   given by the cartesian product of the sublists.

    Ex: combination({{1, 2}, {3}, {4, 5}}) =>
      {{1, 3, 4}, {1, 3, 5}, {2, 3, 4}, {2, 3, 5}}
  "
  input list<list<TI>> inElements;
  output list<list<TI>> outElements;
protected
  list<list<TI>> elems;
algorithm
  if listEmpty(inElements) then
    outElements := {};
  else
    elems := combination_tail(inElements, {}, {});
    outElements := listReverse(elems);
  end if;
end combination;

protected function combination_tail<TI>
  input list<list<TI>> inElements;
  input list<TI> inCombination;
  input list<list<TI>> inAccumElems;
  output list<list<TI>> outElements;
algorithm
  outElements := match(inElements)
    local
      list<TI> head;
      list<list<TI>> rest;
      list<list<TI>> acc;

    case head :: rest
      algorithm
        acc := inAccumElems;
        for e in head loop
          acc := combination_tail(rest, e :: inCombination, acc);
        end for;
      then
        acc;

    else listReverse(inCombination) :: inAccumElems;

  end match;
end combination_tail;

public function combinationMap<TI, TO>
  "Takes a two-dimensional list and calls the given function on the combinations
   given by the cartesian product of the sublists.

    Ex: combinationMap({{1, 2}, {3}, {4, 5}}, func) =>
      {func({1, 3, 4}), func({1, 3, 5}), func({2, 3, 4}), func({2, 3, 5})}
  "
  input list<list<TI>> inElements;
  input MapFunc inMapFunc;
  output list<TO> outElements;

  partial function MapFunc
    input list<TI> inElements;
    output TO outElement;
  end MapFunc;
protected
  list<TO> elems;
algorithm
  elems := combinationMap_tail(inElements, inMapFunc, {}, {});
  outElements  := listReverse(elems);
end combinationMap;

protected function combinationMap_tail<TI, TO>
  input list<list<TI>> inElements;
  input MapFunc inMapFunc;
  input list<TI> inCombination;
  input list<TO> inAccumElems;
  output list<TO> outElements;

  partial function MapFunc
    input list<TI> inElements;
    output TO outElement;
  end MapFunc;
algorithm
  outElements := match(inElements)
    local
      list<TI> head;
      list<list<TI>> rest;
      list<TO> acc;

    case head :: rest
      algorithm
        acc := inAccumElems;
        for e in head loop
          acc := combinationMap_tail(rest, inMapFunc, e :: inCombination, acc);
        end for;
      then
        acc;

    else inMapFunc(listReverse(inCombination)) :: inAccumElems;

  end match;
end combinationMap_tail;

public function combinationMap1<TI, TO, ArgT1>
  "Takes a two-dimensional list and calls the given function on the combinations
   given by the cartesian product of the sublists. Also takes an extra constant
   argument that is sent to the function.

   Ex: combinationMap({{1, 2}, {3}, {4, 5}}, func, x) =>
   {func({1, 3, 4}, x), func({1, 3, 5}, x), func({2, 3, 4}, x), func({2, 3, 5}, x)}
  "
  input list<list<TI>> inElements;
  input MapFunc inMapFunc;
  input ArgT1 inArg;
  output list<TO> outElements;

  partial function MapFunc
    input list<TI> inElements;
    input ArgT1 inArg;
    output TO outElement;
  end MapFunc;
protected
  list<TO> elems;
algorithm
  elems := combinationMap1_tail(inElements, inMapFunc, inArg, {}, {});
  outElements := listReverse(elems);
end combinationMap1;

protected function combinationMap1_tail<TI, TO, ArgT1>
  input list<list<TI>> inElements;
  input MapFunc inMapFunc;
  input ArgT1 inArg;
  input list<TI> inCombination;
  input list<TO> inAccumElems;
  output list<TO> outElements;

  partial function MapFunc
    input list<TI> inElements;
    input ArgT1 inArg;
    output TO outElement;
  end MapFunc;
algorithm
  outElements := match(inElements)
    local
      list<TI> head;
      list<list<TI>> rest;
      list<TO> acc;

    case head :: rest
      algorithm
        acc := inAccumElems;
        for e in head loop
          acc := combinationMap1_tail(rest, inMapFunc, inArg, e :: inCombination, acc);
        end for;
      then
        acc;

    else inMapFunc(listReverse(inCombination), inArg) :: inAccumElems;

  end match;
end combinationMap1_tail;

protected function combinationMap1_tail2<TI, TO, ArgT1>
  input list<TI> inHead;
  input list<list<TI>> inRest;
  input MapFunc inMapFunc;
  input ArgT1 inArg;
  input list<TI> inCombination;
  input list<TO> inAccumElems;
  output list<TO> outElements;

  partial function MapFunc
    input list<TI> inElements;
    input ArgT1 inArg;
    output TO outElement;
  end MapFunc;
algorithm
  outElements := match(inHead, inCombination, inAccumElems)
    local
      TI head;
      list<TI> rest, comb;
      list<TO> accum;

    case (head :: rest, comb, accum)
      equation
        accum = combinationMap1_tail(inRest, inMapFunc, inArg, head :: comb, accum);
      then
        combinationMap1_tail2(rest, inRest, inMapFunc, inArg, comb, accum);

    else inAccumElems;

  end match;
end combinationMap1_tail2;

public function allReferenceEq<T>
  "Checks if all elements in the lists have equal references"
  input list<T> inList1;
  input list<T> inList2;
  output Boolean outEqual;
algorithm
  outEqual := match(inList1, inList2)
    local
      T el1,el2;
      list<T> rest1,rest2;

    case (el1 :: rest1, el2 :: rest2)
      then if referenceEq(el1,el2) then allReferenceEq(rest1,rest2) else false;

    case ({},{}) then true;
    else false;
  end match;
end allReferenceEq;

public function removeEqualPrefix<T1, T2>
  "Takes two lists and a comparison function and removes the heads from both
   lists as long as they are equal. Ex:
     removeEqualPrefix({1, 2, 3, 5, 7}, {1, 2, 3, 9, 7}) => ({5, 7}, {9, 7})"
  input list<T1> inList1;
  input list<T2> inList2;
  input CompFunc inCompFunc;
  output list<T1> outList1 = inList1;
  output list<T2> outList2 = inList2;

  partial function CompFunc
    input T1 inElement1;
    input T2 inElement2;
    output Boolean outIsEqual;
  end CompFunc;
protected
  T1 e1;
  T2 e2;
algorithm
  while not (listEmpty(outList1) or listEmpty(outList2)) loop
    e1 := listHead(outList1);
    e2 := listHead(outList2);
    if not inCompFunc(e1, e2) then break; end if;
    outList1 := listRest(outList1);
    outList2 := listRest(outList2);
  end while;
end removeEqualPrefix;

public function listIsLonger<T>
  "Returns true if inList1 is longer than inList2, otherwise false."
  input list<T> inList1;
  input list<T> inList2;
  output Boolean isLonger;
algorithm
  isLonger := intGt(listLength(inList1), listLength(inList2));
end listIsLonger;

public function toListWithPositions<T>
  input list<T> inList;
  output list<tuple<T, Integer>> outList = {};
protected
  Integer pos = 1;
algorithm
  for e in inList loop
    outList := (e, pos) :: outList;
    pos := pos + 1;
  end for;
  outList := listReverseInPlace(outList);
end toListWithPositions;

public function mkOption<T>
  "@author: adrpo
   make NONE() if the list is empty
   make SOME(list) if the list is not empty"
  input list<T> inList;
  output Option<list<T>> outOption;
algorithm
  outOption := if listEmpty(inList) then NONE() else SOME(inList);
end mkOption;

public function all<T>
  "Returns true if the given predicate function returns true for all elements in
   the given list."
  input list<T> inList;
  input PredFunc inFunc;
  output Boolean outResult;

  partial function PredFunc
    input T inElement;
    output Boolean outMatch;
  end PredFunc;
algorithm
  for e in inList loop
    if not inFunc(e) then
      outResult := false;
      return;
    end if;
  end for;

  outResult := true;
end all;

public function separateOnTrue<T>
  "Takes a list of values and a filter function over the values and returns 2
   sub lists of values for which the matching function returns true and false."
  input list<T> inList;
  input FilterFunc inFilterFunc;
  output list<T> outListTrue = {};
  output list<T> outListFalse = {};

  partial function FilterFunc
    input T inElement;
    output Boolean outResult;
  end FilterFunc;
algorithm
  for e in inList loop
    if inFilterFunc(e) then
      outListTrue := e::outListTrue;
    else
      outListFalse := e::outListFalse;
    end if;
  end for;
end separateOnTrue;

public function separate1OnTrue<T, ArgT1>
  "Takes a list of values and a filter function over the values and returns 2
   sub lists of values for which the matching function returns true and false."
  input list<T> inList;
  input FilterFunc inFilterFunc;
  input ArgT1 inArg1;
  output list<T> outListTrue = {};
  output list<T> outListFalse = {};

  partial function FilterFunc
    input T inElement;
    input ArgT1 inArg1;
    output Boolean outResult;
  end FilterFunc;
algorithm
  for e in inList loop
    if inFilterFunc(e, inArg1) then
      outListTrue := e::outListTrue;
    else
      outListFalse := e::outListFalse;
    end if;
  end for;
end separate1OnTrue;

public function mapFirst<TI, TO>
  input list<TI> inList;
  input FindMapFunc inFunc;
  output TO outElement;

  partial function FindMapFunc
    input TI inElement;
    output TO outElement;
    output Boolean outFound;
  end FindMapFunc;
protected
  Boolean found;
algorithm
  for e in inList loop
    (outElement, found) := inFunc(e);

    if found then
      return;
    end if;
  end for;
  fail();
end mapFirst;

public function isSorted<T>
  input list<T> inList;
  input Comp inFunc;
  output Boolean b=true;

  partial function Comp
    input T a,b;
    output Boolean c;
  end Comp;
protected
  Boolean found;
  T prev;
algorithm
  if listEmpty(inList) then
    return;
  end if;
  prev::_ := inList;
  for e in listRest(inList) loop
    if not inFunc(prev,e) then
      b := false;
      return;
    end if;
  end for;
end isSorted;

function mapIndices<T>
  "Applies a function to only the elements given by the sorted list of indices."
  input list<T> inList;
  input list<Integer> indices;
  input MapFunc func;
  output list<T> outList;

  partial function MapFunc
    input output T e;
  end MapFunc;
protected
  Integer i = 1, idx;
  list<Integer> rest_idx;
  T e;
  list<T> rest_lst;
algorithm
  if listEmpty(indices) then
    outList := inList;
    return;
  end if;

  idx :: rest_idx := indices;
  rest_lst := inList;
  outList := {};

  while not listEmpty(rest_lst) loop
    e :: rest_lst := rest_lst;

    if i == idx then
      outList := func(e) :: outList;

      if listEmpty(rest_idx) then
        outList := append_reverse(rest_lst, outList);
        break;
      else
        idx :: rest_idx := rest_idx;
      end if;
    else
      outList := e :: outList;
    end if;

    i := i + 1;
  end while;

  outList := listReverseInPlace(outList);
end mapIndices;

annotation(__OpenModelica_Interface="util");
end List;
