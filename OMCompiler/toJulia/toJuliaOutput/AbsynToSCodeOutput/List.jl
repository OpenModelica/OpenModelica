module List


using MetaModelica

#= Alias neeeded to not confuse Julia =#
Lst = MetaModelica.List

CompFunc = Function


Predicate = Function

CompareFunc = Function

CompFunc = Function

CompFunc = Function

PredicateFunc = Function

PredicateFunc = Function

PredicateFunc = Function

CompFunc = Function

MapFunc = Function

CompFunc = Function

MapFunc = Function


MapFunc1 = Function
MapFunc2 = Function

MapFunc1 = Function
MapFunc2 = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

ApplyFunc = Function
FoldFunc = Function

ApplyFunc = Function
FoldFunc = Function

MapFunc = Function

MapFunc = Function

MapBFunc = Function
MapFunc = Function

MapFunc = Function

FoldFunc = Function

FoldFunc = Function

FoldFunc = Function

FuncType = Function

FuncType = Function

FuncType = Function

FuncType = Function

FuncType = Function

FuncType = Function

FuncType = Function

FuncType = Function

FuncType = Function

FuncType = Function

FuncType = Function

FuncType = Function

FuncType = Function

FuncType = Function

FoldFunc = Function

ReduceFunc = Function

ReduceFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

FoldFunc = Function

FoldFunc = Function

FoldFunc = Function

FoldFunc = Function

FoldFunc = Function

FuncType = Function

PredFunc = Function

PredFunc = Function

CompFunc = Function

CompFunc = Function

FindFunc = Function

FindFunc = Function

FindFunc = Function

FilterFunc = Function

FilterFunc = Function

FilterFunc = Function

FilterMapFunc = Function

FilterMapFunc = Function

FilterFunc = Function

FilterFunc = Function

FilterFunc = Function

FilterFunc = Function

FilterFunc = Function

FilterFunc = Function

FilterFunc = Function

FilterFunc = Function
UpdateFunc = Function

FilterFunc = Function

FilterFunc = Function

CompFunc = Function

SelectFunc = Function

SelectFunc = Function

SelectFunc = Function

SelectFunc = Function

CompareFunc = Function

FuncType = Function

FuncType = Function

GenerateFunc = Function

GenerateFunc = Function

MapFunc = Function
FoldFunc = Function

MapFunc = Function
FoldFunc = Function

MapFunc = Function

FuncType = Function


EqFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

CompFunc = Function

PredFunc = Function

FilterFunc = Function

FilterFunc = Function

FindMapFunc = Function

Comp = Function

MapFunc = Function


FT3 = Any

FT4 = Any

FT5 = Any

FT6 = Any

FT7 = Any

FT8 = Any




#= /*
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
* from the URLs: http:www.ida.liu.se/projects/OpenModelica or
* http:www.openmodelica.org, and in the OpenModelica distribution.
* GNU version 3 is obtained from: http:www.gnu.org/copyleft/gpl.html.
*
* This program is distributed WITHOUT ANY WARRANTY; without
* even the implied warranty of  MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
* IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
*
* See the full OSMC Public License conditions for more details.
*
*/ =#

using MetaModelica.Dangerous
import MetaModelica.Dangerous

#= Creates a list from an element. =#
T = Any
function create(inElement::T)::Lst
  local outLst::Lst = list(inElement)
  outLst
end

#= Creates a list from two elements. =#
function create2(inElement1::T, inElement2::T)::Lst
  T = Any
  local outLst::Lst = list(inElement1, inElement2)
  outLst
end

#= Returns a list of n element.
Example: fill(2, 3) => {2, 2, 2} =#
function fill(inElement::T, inCount::ModelicaInteger)::Lst
  T = Any
  local outLst::Lst = list()

  local i::ModelicaInteger = 0

  while i < inCount
    outLst = inElement <| outLst
    i = i + 1
  end
  outLst
end

#= Returns a list of n integers from 1 to inStop.
Example: listIntRange(3) => {1,2,3} =#
function intRange(inStop::ModelicaInteger)::Lst
  local outRange::Lst = list()

  local i::ModelicaInteger = inStop

  while i > 0
    outRange = i <| outRange
    i = i - 1
  end
  outRange
end

#= Returns a list of integers from inStart to inStop.
Example listIntRange2(3,5) => {3,4,5} =#
function intRange2(inStart::ModelicaInteger, inStop::ModelicaInteger)::Lst
  local outRange::Lst = list()

  local i::ModelicaInteger = inStop

  if inStart < inStop
    while i >= inStart
      outRange = i <| outRange
      i = i - 1
    end
  else
    while i <= inStart
      outRange = i <| outRange
      i = i + 1
    end
  end
  outRange
end

#= Returns a list of integers from inStart to inStop with step inStep.
Example: listIntRange2(3,2,9) => {3,5,7,9} =#
function intRange3(inStart::ModelicaInteger, inStep::ModelicaInteger, inStop::ModelicaInteger)::Lst
  local outRange::Lst

  if inStep == 0
    fail()
  end
  outRange = list(i for i in inStart:inStep:inStop)
  outRange
end

#= Returns an option of the element in a list if the list contains exactly one
element, NONE() if the list is empty and fails if the list contains more than
one element. =#
function toOption(inLst)::Option
  local outOption::Option

  outOption = begin
    local e
    @match inLst begin
      nil()  => begin
        NONE()
      end

      e <|  nil()  => begin
        SOME(e)
      end
    end
  end
  outOption
end

#= Returns an empty list for NONE() and a list containing the element for
SOME(element). =#
function fromOption(inElement::Option)::Lst
  T = Any
  local outLst::Lst

  outLst = begin
    local e::T
    @match inElement begin
      SOME(e)  => begin
        list(e)
      end

      _  => begin
        list()
      end
    end
  end
  outLst
end

#= Fails if the given list is not empty. =#
function assertIsEmpty(inLst::Lst)
  T = Any
  @assert list() == (inLst)
end

#= Checks if two lists are equal. If inEqualLength is true the lists are assumed
to be of equal length, and if it is false they can be of different lengths (in
which case only the overlapping parts of the lists are checked). =#
function isEqual(inLst1::Lst, inLst2::Lst, inEqualLength::Bool)::Bool
  T = Any
  local outIsEqual::Bool

  outIsEqual = begin
    local e1::T
    local e2::T
    local rest1::Lst
    local rest2::Lst
    @match inLst1, inLst2, inEqualLength begin
      (e1 <| rest1, e2 <| rest2, _) where valueEq(e1, e2)  => begin
        isEqual(rest1, rest2, inEqualLength)
      end

      ( nil(),  nil(), _)  => begin
        true
      end

      ( nil(), _, false)  => begin
        true
      end

      (_,  nil(), false)  => begin
        true
      end

      _  => begin
        false
      end
    end
  end
  outIsEqual
end

#= Takes two lists and an equality function, and returns whether the lists are
equal or not. =#
function isEqualOnTrue(inLst1::Lst, inLst2::Lst, inCompFunc::CompFunc)::Bool
  T1 = Any ,T2 = Any
  local outIsEqual::Bool

  outIsEqual = begin
    local e1::T1
    local e2::T2
    local rest1::Lst
    local rest2::Lst
    @match inLst1, inLst2 begin
      (e1 <| rest1, e2 <| rest2) where inCompFunc(e1, e2)  => begin
        isEqualOnTrue(rest1, rest2, inCompFunc)
      end

      ( nil(),  nil())  => begin
        true
      end

      _  => begin
        false
      end
    end
  end
  outIsEqual
end

#= Checks if the first list is a prefix of the second list, i.e. that all
elements in the first list is equal to the corresponding elements in the
second list. =#
function isPrefixOnTrue(inLst1::Lst, inLst2::Lst, inCompFunc::CompFunc)::Bool
  T1 = Any ,T2 = Any
  local outIsPrefix::Bool

  outIsPrefix = begin
    local e1::T1
    local rest1::Lst
    local e2::T2
    local rest2::Lst
    @match inLst1, inLst2 begin
      (e1 <| rest1, e2 <| rest2) where inCompFunc(e1, e2)  => begin
        isPrefixOnTrue(rest1, rest2, inCompFunc)
      end

      ( nil(), _)  => begin
        true
      end

      _  => begin
        false
      end
    end
  end
  outIsPrefix
end

#= The same as the builtin cons operator, but with the order of the arguments
swapped. =#
function consr(inLst::Lst, inElement::T)::Lst
  T = Any
  local outLst::Lst

  outLst = inElement <| inLst
  outLst
end

#= Adds the element to the front of the list if the condition is true. =#
function consOnTrue(inCondition::Bool, inElement::T, inLst::Lst)::Lst
  T = Any
  local outLst::Lst

  outLst = if inCondition inElement <| inLst
  else
    inLst
  end
  outLst
end

#= Adds the element to the front of the list if the predicate succeeds.
Prefer using consOnTrue instead of this function, it's more efficient. =#
function consOnSuccess(inElement::T, inLst::Lst, inPredicate::Predicate)::Lst
  T = Any
  local outLst::Lst

  try
    inPredicate(inElement)
    outLst = inElement <| inLst
  catch
    outLst = inLst
  end
  outLst
end

#= Adds an optional element to the front of the list, or returns the list if the
element is none. =#
function consOption(inElement::Option, inLst::Lst)::Lst
  T = Any
  local outLst::Lst

  outLst = begin
    local e::T
    @match inElement begin
      SOME(e)  => begin
        e <| inLst
      end

      _  => begin
        inLst
      end
    end
  end
  outLst
end

#= Adds an element to one of two lists, depending on the given boolean value. =#
function consOnBool(inValue::Bool, inElement::T, trueLst::Lst, falseLst::Lst)::Tuple{Lst, Lst}
  T = Any



  if inValue
    trueLst = inElement <| trueLst
  else
    falseLst = inElement <| falseLst
  end
  (falseLst, trueLst)
end

#= concate n time inElement to the list:
n = 5, inElement=1, list={1,2} -> list={1,1,1,1,1,1,2} =#
function consN(size::ModelicaInteger, inElement::T, inLst::Lst)::Lst
  T = Any


  for i in 1:size
    inLst = inElement <| inLst
  end
  inLst
end

#= Appends the elements from list1 in reverse order to list2. =#
function append_reverse(inLst1::Lst, inLst2::Lst)::Lst
  T = Any
  local outLst::Lst = inLst2

  #=  Do not optimize the case listEmpty(inLst2) and listLength(inLst1)==1
  =#
  #=  since we use listReverseInPlace together with this function.
  =#
  #=  An alternative would be to keep both (and rename this append_reverse_always_copy)
  =#
  for e in inLst1
    outLst = e <| outLst
  end
  outLst
end

#= Appends the elements from list2 in reverse order to list1. =#
function append_reverser(inLst1::Lst, inLst2::Lst)::Lst
  T = Any
  local outLst::Lst = inLst1

  #=  Do not optimize the case listEmpty(inLst2) and listLength(inLst1)==1
  =#
  #=  since we use listReverseInPlace together with this function.
  =#
  #=  An alternative would be to keep both (and rename this append_reverse_always_copy)
  =#
  for e in inLst2
    outLst = e <| outLst
  end
  outLst
end

#= Appends two lists in reverse order compared to listAppend. =#
function appendr(inLst1::Lst, inLst2::Lst)::Lst
  T = Any
  local outLst::Lst

  outLst = listAppend(inLst2, inLst1)
  outLst
end

#= Appends an element to the end of the list. Note that this is very
inefficient, so try to avoid using this function. =#
function appendElt(inElement::T, inLst::Lst)::Lst
  T = Any
  local outLst::Lst

  outLst = listAppend(inLst, list(inElement))
  outLst
end

#= Appends a list to the last list in a list of lists. =#
function appendLastLst(inLstLst::Lst, inLst::Lst)::Lst
  T = Any
  local outLstLst::Lst

  outLstLst = begin
    local l::Lst
    local ll::Lst
    local ol::Lst = list()
    @match inLstLst, inLst begin
      ( nil(), _)  => begin
        list(inLst)
      end

      (l <|  nil(), _)  => begin
        list(listAppend(l, inLst))
      end

      (l <| ll, _)  => begin
        while ! listEmpty(ll)
          ol = l <| ol
          l, ll = listHead(ll), listRest(ll)
        end
        ol = listAppend(l, inLst) <| ol
        ol = listReverseInPlace(ol)
        ol
      end
    end
  end
  outLstLst
end

#= Inserts an element at a position
example: insert({2,1,4,2},2,3) => {2,3,1,4,2}  =#
function insert(inLst::Lst, inN::ModelicaInteger, inElement::T)::Lst
  T = Any
  local outLst::Lst

  local lst1::Lst
  local lst2::Lst

  @assert true == (inN > 0)
  lst1, lst2 = splitr(inLst, inN - 1)
  outLst = append_reverse(lst1, inElement <| lst2)
  outLst
end

#= Inserts an sorted list into another sorted list. O(n)
example: insertLstSorted({1,2,4,5},{3,4,8},intGt) => {1,2,3,4,4,5,8} =#
function insertLstSorted(inLst::Lst, inLst2::Lst, inCompFunc::CompareFunc)::Lst
  T = Any
  local outLst::Lst

  outLst = listReverseInPlace(insertLstSorted1(inLst, inLst2, inCompFunc, list()))
  outLst
end

#= Iterate over the first given list and add it to the result list if the comparison function with the head of the second list returns true.
The result is a sorted list in reverse order. =#
function insertLstSorted1(inLst::Lst, inLst2::Lst, inCompFunc::CompareFunc, inResultLst::Lst)::Lst
  T = Any
  local outResultLst::Lst

  local listRest::Lst
  local listRest2::Lst
  local tmpResultLst::Lst
  local listHead::T
  local listHead2::T
  local elem::T

  outResultLst = begin
    @match inLst, inLst2, inCompFunc, inResultLst begin
      ( nil(),  nil(), _, _)  => begin
        inResultLst
      end

      ( nil(), _, _, _)  => begin
        append_reverse(inLst2, inResultLst)
      end

      (_,  nil(), _, _)  => begin
        append_reverse(inLst, inResultLst)
      end

      (listHead <| listRest, listHead2 <| listRest2, _, _)  => begin
        if inCompFunc(listHead, listHead2)
          tmpResultLst = listHead <| inResultLst
          tmpResultLst = insertLstSorted1(listRest, inLst2, inCompFunc, tmpResultLst)
        else
          tmpResultLst = listHead2 <| inResultLst
          tmpResultLst = insertLstSorted1(inLst, listRest2, inCompFunc, tmpResultLst)
        end
        tmpResultLst
      end
    end
  end
  outResultLst
end

#= set an element at a position
example: set({2,1,4,2},2,3) => {2,3,4,2}  =#
function set(inLst::Lst, inN::ModelicaInteger, inElement::T)::Lst
  T = Any
  local outLst::Lst

  local lst1::Lst
  local lst2::Lst

  @assert true == (inN > 0)
  lst1, lst2 = splitr(inLst, inN - 1)
  lst2 = stripFirst(lst2)
  outLst = append_reverse(lst1, inElement <| lst2)
  outLst
end

#= Returns the first element of a list. Fails if the list is empty. =#
function first(inLst::Lst)::T
  T = Any
  local out::T

  out = begin
    local e::T
    @match inLst begin
      e <| _  => begin
        e
      end
    end
  end
  out
end

#= Returns the first element of a list as a list, or an empty list if the given
list is empty. =#
function firstOrEmpty(inLst::Lst)::Lst
  T = Any
  local outLst::Lst

  outLst = begin
    local e::T
    @match inLst begin
      e <| _  => begin
        list(e)
      end

      _  => begin
        list()
      end
    end
  end
  outLst
end

#= Returns the second element of a list. Fails if the list is empty. =#
function second(inLst::Lst)::T
  T = Any
  local outSecond::T

  outSecond = listGet(inLst, 2)
  outSecond
end

#= Returns the last element of a list. Fails if the list is empty. =#
function last(inLst::Lst)::T
  T = Any
  local outLast::T

  local rest::Lst

  outLast, rest = listHead(inLst), listRest(inLst)
  for e in rest
    outLast = e
  end
  outLast
end

#= Returns the last cons-cell of a list. Fails if the list is empty. Also returns the list length. =#
function lastElement(inLst::Lst)::Tuple{ModelicaInteger, Lst}
  T = Any
  local listLength::ModelicaInteger = 0
  local lst::Lst

  local rest::Lst = inLst

  @assert false == (listEmpty(rest))
  while ! listEmpty(rest)
    listLength = listLength + 1
  end
  (listLength, lst)
end

#= Returns the last element(list) of a list of lists. Returns empty list
if the outer list is empty. =#
function lastLstOrEmpty(inLstLst::Lst)::Lst
  T = Any
  local outLastLst::Lst = list()

  for e in inLstLst
    outLastLst = e
  end
  outLastLst
end

#= Returns the second last element of a list, or fails if such an element does
not exist. =#
function secondLast(inLst::Lst)::T
  T = Any
  local outSecondLast::T

  _, outSecondLast, _ = listHead(listReverse(inLst)), listRest(listReverse(inLst))
  outSecondLast
end

#= Returns the last N elements of a list. =#
function lastN(inLst::Lst, inN::ModelicaInteger)::Lst
  T = Any
  local outLst::Lst

  local len::ModelicaInteger

  @assert true == (inN >= 0)
  len = listLength(inLst)
  outLst = stripN(inLst, len - inN)
  outLst
end

#= Returns all elements except for the first in a list. =#
function rest(inLst::Lst)::Lst
  T = Any
  local outLst::Lst

  _, outLst = listHead(inLst), listRest(inLst)
  outLst
end

#= Returns all elements except for the first in a list. =#
function restCond(cond::Bool, inLst::Lst)::Lst
  T = Any
  local outLst::Lst

  outLst = if cond listRest(inLst)
  else
    inLst
  end
  outLst
end

#= Returns all elements except for the first in a list, or the empty list of the
list is empty. =#
function restOrEmpty(inLst::Lst)::Lst
  T = Any
  local outLst::Lst

  outLst = if listEmpty(inLst) inLst
  else
    listRest(inLst)
  end
  outLst
end

function getIndexFirst(index::ModelicaInteger, inLst::Lst)::T
  T = Any
  local element::T

  element = listGet(inLst, index)
  element
end

#= Returns the first N elements of a list, or fails if there are not enough
elements in the list. =#
function firstN(inLst::Lst, inN::ModelicaInteger)::Lst
  T = Any
  local outLst::Lst = list()

  local e::T
  local rest::Lst

  @assert true == (inN >= 0)
  rest = inLst
  for i in 1:inN
    e, rest = listHead(rest), listRest(rest)
    outLst = e <| outLst
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= Removes the first element of a list, but returns the empty list if the given
list is empty. =#
function stripFirst(inLst::Lst)::Lst
  T = Any
  local outLst::Lst

  if listEmpty(inLst)
    outLst = list()
  else
    _, outLst = listHead(inLst), listRest(inLst)
  end
  outLst
end

#= Removes the last element of a list. If the list is the empty list, the
function returns the empty list. =#
function stripLast(inLst::Lst)::Lst
  T = Any
  local outLst::Lst

  if listEmpty(inLst)
    outLst = list()
  else
    _, outLst = listHead(listReverse(inLst)), listRest(listReverse(inLst))
    outLst = listReverseInPlace(outLst)
  end
  outLst
end

#= Strips the N first elements from a list. Fails if the list contains less than
N elements, or if N is negative. =#
function stripN(inLst::Lst, inN::ModelicaInteger)::Lst
  T = Any
  local outLst::Lst = inLst

  @assert true == (inN >= 0)
  for i in 1:inN
    _, outLst = listHead(outLst), listRest(outLst)
  end
  outLst
end

function heapSortIntLst(lst::Lst)::Lst
  println("I AM A STUB")
  lst
end

#= Sorts a list given an ordering function with the mergesort algorithm.
Example:
sort({2, 1, 3}, intGt) => {1, 2, 3}
sort({2, 1, 3}, intLt) => {3, 2, 1} =#
function sort(inLst::Lst, inCompFunc::CompareFunc)::Lst
  T = Any
  local outLst::Lst = list()

  local rest::Lst = inLst
  local e1::T
  local e2::T
  local left::Lst
  local right::Lst
  local middle::ModelicaInteger

  if ! listEmpty(rest)
    e1, rest = listHead(rest), listRest(rest)
    if listEmpty(rest)
      outLst = inLst
    else
      e2, rest = listHead(rest), listRest(rest)
      if listEmpty(rest)
        outLst = if inCompFunc(e2, e1) inLst
        else
          list(e2, e1)
        end
      else
        middle = intDiv(listLength(inLst), 2)
        left, right = split(inLst, middle)
        left = sort(left, inCompFunc)
        right = sort(right, inCompFunc)
        outLst = merge(left, right, inCompFunc, list())
      end
    end
  end
  outLst
end

#= Returns a list of all duplicates in a sorted list, using the given comparison
function to check for equality. =#
function sortedDuplicates(inLst::Lst, inCompFunc #= Equality comparator =#::CompareFunc)::Lst
  T = Any
  local outDuplicates::Lst = list()

  local e::T
  local rest::Lst = inLst

  while ! listEmpty(rest)
    e, rest = listHead(rest), listRest(rest)
    if ! listEmpty(rest) && inCompFunc(e, listHead(rest))
      outDuplicates = e <| outDuplicates
    end
  end
  outDuplicates = listReverseInPlace(outDuplicates)
  outDuplicates
end

#= The input is a sorted list. The functions checks if all elements are unique. =#
function sortedLstAllUnique(lst::Lst, compare::CompareFunc)::Bool
  allUnique = true
end

#= Returns a list of unique elements in a sorted list, using the given
comparison function to check for equality. =#
function sortedUnique(inLst::Lst, inCompFunc::CompareFunc)::Lst
  println("sortedUnique I am not implemented :(")
  outUniqueElements = listReverseInPlace(outUniqueElements)
  outUniqueElements
end

#= Returns a list with all duplicate elements removed, as well as a list of the
removed elements, using the given comparison function to check for equality. =#
function sortedUniqueAndDuplicates(inLst::Lst, inCompFunc::CompareFunc)::Tuple{Lst, Lst}
  T = Any
  local outDuplicateElements::Lst = list()
  local outUniqueElements::Lst = list()

  local e::T
  local rest::Lst = inLst

  while ! listEmpty(rest)
    e, rest = listHead(rest), listRest(rest)
    if ! listEmpty(rest) && inCompFunc(e, listHead(rest))
      outDuplicateElements = e <| outDuplicateElements
    else
      outUniqueElements = e <| outUniqueElements
    end
  end
  outUniqueElements = listReverseInPlace(outUniqueElements)
  outDuplicateElements = listReverseInPlace(outDuplicateElements)
  (outDuplicateElements, outUniqueElements)
end

#= Returns a list with all duplicate elements removed, as well as a list of the
removed elements, using the given comparison function to check for equality. =#
function sortedUniqueOnlyDuplicates(inLst::Lst, inCompFunc::CompareFunc)::Lst
  T = Any
  local outDuplicateElements::Lst = list()

  local e::T
  local rest::Lst = inLst

  while ! listEmpty(rest)
    e, rest = listHead(rest), listRest(rest)
    if ! listEmpty(rest) && inCompFunc(e, listHead(rest))
      outDuplicateElements = e <| outDuplicateElements
    end
  end
  outDuplicateElements = listReverseInPlace(outDuplicateElements)
  outDuplicateElements
end

#= Helper function to sort, merges two sorted lists. =#
function merge(inLeft::Lst, inRight::Lst, inCompFunc::CompareFunc, acc::Lst)::Lst
  T = Any
  local outLst::Lst

  outLst = begin
    local b::Bool
    local l::T
    local r::T
    local el::T
    local l_rest::Lst
    local r_rest::Lst
    local res::Lst
    #= /* Tail recursive version */ =#
    @match inLeft, inRight begin
      (l <| l_rest, r <| r_rest)  => begin
        if inCompFunc(r, l)
          r_rest = inRight
          el = l
        else
          l_rest = inLeft
          el = r
        end
        merge(l_rest, r_rest, inCompFunc, el <| acc)
      end

      ( nil(),  nil())  => begin
        listReverseInPlace(acc)
      end

      ( nil(), _)  => begin
        append_reverse(acc, inRight)
      end

      (_,  nil())  => begin
        append_reverse(acc, inLeft)
      end
    end
  end
  outLst
end

#= This function merges two sorted lists into one sorted list. It takes a
comparison function that defines a strict weak ordering of the elements, i.e.
that returns true if the first element should be placed before the second
element in the sorted list. =#
function mergeSorted(inLst1::Lst, inLst2::Lst, inCompFunc::CompFunc)::Lst
  T = Any
  local outLst::Lst = list()

  local l1::Lst
  local l2::Lst
  local e1::T
  local e2::T

  l1 = inLst1
  l2 = inLst2
  #=  While both lists contain elements.
  =#
  while ! listEmpty(l1) && ! listEmpty(l2)
    e1, _ = listHead(l1), listRest(l1)
    e2, _ = listHead(l2), listRest(l2)
    if inCompFunc(e1, e2)
      outLst = e1 <| outLst
      _, l1 = listHead(l1), listRest(l1)
    else
      outLst = e2 <| outLst
      _, l2 = listHead(l2), listRest(l2)
    end
  end
  #=  Move the smallest head from either list to accumulator.
  =#
  #=  Reverse accumulator and append the remaining elements.
  =#
  l1 = if listEmpty(l1) l2
  else
    l1
  end
  outLst = append_reverse(outLst, l1)
  outLst
end

#= Provides same functionality as sort, but for integer values between 1
and N. The complexity in this case is O(n) =#
function sortIntN(inLst::Lst, inN::ModelicaInteger)::Lst
  local outSorted::Lst = list()

  local a1::Array

  a1 = arrayCreate(inN, false)
  a1 = fold1r(inLst, arrayUpdate, true, a1)
  for i in inN:(-1):1
    if a1[i]
      outSorted = i <| outSorted
    end
  end
  outSorted
end

#= Takes a list of elements and returns a list with duplicates removed, so that
each element in the new list is unique. =#
function unique(inLst::Lst)::Lst
  T = Any
  local outLst::Lst = list()

  for e in inLst
    if ! listMember(e, outLst)
      outLst = e <| outLst
    end
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= Takes a list of integes and returns a list with duplicates removed, so that
each element in the new list is unique. O(listLength(inLst)) =#
function uniqueIntN(inLst::Lst, inN::ModelicaInteger)::Lst
  local outLst::Lst = list()

  local arr::Array

  arr = arrayCreate(inN, true)
  for i in inLst
    if arrayGet(arr, i)
      outLst = i <| outLst
    end
    arrayUpdate(arr, i, false)
  end
  outLst
end

#= Takes a list of integes and returns a list with duplicates removed, so that
each element in the new list is unique. O(listLength(inLst)). The function
also takes an array of Integer of size N+1 to mark the already selected entries <= N.
The last entrie of the array is used for the mark index. It will be updated after
each call =#
function uniqueIntNArr(inLst::Lst, inMarkArray::Array, inAccum::Lst)::Lst
  local outAccum::Lst

  local len::ModelicaInteger
  local mark::ModelicaInteger

  if listEmpty(inLst)
    outAccum = inAccum
  else
    len = arrayLength(inMarkArray)
    mark = inMarkArray[len]
    arrayUpdate(inMarkArray, len, mark + 1)
    outAccum = uniqueIntNArr1(inLst, len, mark + 1, inMarkArray, inAccum)
  end
  outAccum
end

#= Helper for uniqueIntNArr1. =#
function uniqueIntNArr1(inLst::Lst, inLength::ModelicaInteger, inMark::ModelicaInteger, inMarkArray::Array, inAccum::Lst)::Lst
  local outAccum::Lst = inAccum

  for i in inLst
    if i >= inLength
      fail()
    end
    if arrayGet(inMarkArray, i) != inMark
      outAccum = i <| outAccum
      _ = arrayUpdate(inMarkArray, i, inMark)
    end
  end
  outAccum
end

#= Takes a list of elements and a comparison function over two elements of the
list and returns a list with duplicates removed, so that each element in the
new list is unique. =#
function uniqueOnTrue(inLst::Lst, inCompFunc::CompFunc)::Lst
  T = Any
  local outLst::Lst = list()

  for e in inLst
    if ! isMemberOnTrue(e, outLst, inCompFunc)
      outLst = e <| outLst
    end
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= Takes a list of lists and reverses it at both levels, i.e. both the list
itself and each sublist.
Example:
reverseLst({{1, 2}, {3, 4, 5}, {6}}) => {{6}, {5, 4, 3}, {2, 1}} =#
function reverseLst(inLst::Lst)::Lst
  T = Any
  local outLst::Lst

  outLst = listReverse(listReverse(e) for e in inLst)
  outLst
end

#= Takes a list and a position, and splits the list at the position given.
Example: split({1, 2, 5, 7}, 2) => ({1, 2}, {5, 7}) =#
function split(inLst::Lst, inPosition::ModelicaInteger)::Tuple{Lst, Lst}
  T = Any
  local outLst2::Lst
  local outLst1::Lst

  local pos::ModelicaInteger
  local l1::Lst = list()
  local l2::Lst = inLst
  local e::T

  @assert true == (inPosition >= 0)
  pos = inPosition
  #=  Move elements from l2 to l1 until we reach the split position.
  =#
  for i in 1:pos
    e, l2 = listHead(l2), listRest(l2)
    l1 = e <| l1
  end
  outLst1 = listReverseInPlace(l1)
  outLst2 = l2
  (outLst2, outLst1)
end

#= Takes a list and a position, and splits the list at the position given. The first list is returned in reverse order.
Example: split({1, 2, 5, 7}, 2) => ({2, 1}, {5, 7}) =#
function splitr(inLst::Lst, inPosition::ModelicaInteger)::Tuple{Lst, Lst}
  T = Any
  local outLst2::Lst
  local outLst1::Lst

  local pos::ModelicaInteger
  local l1::Lst = list()
  local l2::Lst = inLst
  local e::T

  @assert true == (inPosition >= 0)
  pos = inPosition
  #=  Move elements from l2 to l1 until we reach the split position.
  =#
  for i in 1:pos
    e, l2 = listHead(l2), listRest(l2)
    l1 = e <| l1
  end
  outLst1 = l1
  outLst2 = l2
  (outLst2, outLst1)
end

#= Splits a list into two sublists depending on predicate function. =#
function splitOnTrue(inLst::Lst, inFunc::PredicateFunc)::Tuple{Lst, Lst}
  T = Any
  local outFalseLst::Lst = list()
  local outTrueLst::Lst = list()

  for e in inLst
    if inFunc(e)
      outTrueLst = e <| outTrueLst
    else
      outFalseLst = e <| outFalseLst
    end
  end
  outTrueLst = listReverseInPlace(outTrueLst)
  outFalseLst = listReverseInPlace(outFalseLst)
  (outFalseLst, outTrueLst)
end

#= Splits a list into two sublists depending on predicate function. =#
T = Any
ArgT1 = Any
function split1OnTrue(inLst::Lst, inFunc::PredicateFunc, inArg1::ArgT1)::Tuple{Lst, Lst}
  local outFalseLst::Lst = list()
  local outTrueLst::Lst = list()

  for e in inLst
    if inFunc(e, inArg1)
      outTrueLst = e <| outTrueLst
    else
      outFalseLst = e <| outFalseLst
    end
  end
  outTrueLst = listReverseInPlace(outTrueLst)
  outFalseLst = listReverseInPlace(outFalseLst)
  (outFalseLst, outTrueLst)
end

T = Any
ArgT1 = Any
ArgT2 = Any
#= Splits a list into two sublists depending on predicate function. =#
function split2OnTrue(inLst::Lst, inFunc::PredicateFunc, inArg1::ArgT1, inArg2::ArgT2)::Tuple{Lst, Lst}
  local outFalseLst::Lst = list()
  local outTrueLst::Lst = list()

  for e in inLst
    if inFunc(e, inArg1, inArg2)
      outTrueLst = e <| outTrueLst
    else
      outFalseLst = e <| outFalseLst
    end
  end
  outTrueLst = listReverseInPlace(outTrueLst)
  outFalseLst = listReverseInPlace(outFalseLst)
  (outFalseLst, outTrueLst)
end

#= Splits a list when the given function first finds a matching element.
Example: splitOnFirstMatch({1, 2, 3, 4, 5}, isThree) => ({1, 2}, {3, 4, 5}) =#
function splitOnFirstMatch(inLst::Lst, inFunc::CompFunc)::Tuple{Lst, Lst}
  T = Any
  local outLst2::Lst = inLst
  local outLst1::Lst = list()

  local e::T

  #=  Shuffle elements from outLst2 to outLst1 until we find a match.
  =#
  while ! listEmpty(outLst2)
    e, outLst2 = listHead(outLst2), listRest(outLst2)
    if inFunc(e)
      outLst2 = e <| outLst2
      break
    end
    outLst1 = e <| outLst1
  end
  outLst1 = listReverseInPlace(outLst1)
  (outLst2, outLst1)
end

#= Returns the first element of a list and the rest of the list. Fails if the
list is empty. =#
function splitFirst(inLst::Lst)::Tuple{Lst, T}
  T = Any
  local outRest::Lst
  local outFirst::T

  outFirst, outRest = listHead(inLst), listRest(inLst)
  (outRest, outFirst)
end

#= Returns the first element of a list as an option, and the rest of the list.
Returns NONE and {} if the list is empty. =#
function splitFirstOption(inLst::Lst)::Tuple{Lst, Option}
  T = Any
  local outRest::Lst
  local outFirst::Option

  outFirst, outRest = begin
    local el::T
    local rest::Lst
    @match inLst begin
      el <| rest  => begin
        SOME(el), rest
      end

      _  => begin
        NONE(), list()
      end
    end
  end
  (outRest, outFirst)
end

#= Returns the last element of a list and a list of all previous elements. If
the list is the empty list, the function fails.
Example: splitLast({3, 5, 7, 11, 13}) => (13, {3, 5, 7, 11}) =#
function splitLast(inLst::Lst)::Tuple{Lst, T}
  T = Any
  local outRest::Lst
  local outLast::T

  outLast, outRest = listHead(listReverse(inLst)), listRest(listReverse(inLst))
  outRest = listReverseInPlace(outRest)
  (outRest, outLast)
end

#= Splits a list into n equally sized parts.
Example: splitEqualParts({1, 2, 3, 4, 5, 6, 7, 8}, 4) =>
{{1, 2}, {3, 4}, {5, 6}, {7, 8}} =#
function splitEqualParts(inLst::Lst, inParts::ModelicaInteger)::Lst
  T = Any
  local outParts::Lst

  local length::ModelicaInteger

  if inParts == 0
    outParts = list()
  else
    length = listLength(inLst)
    @assert 0 == (intMod(length, inParts))
    outParts = partition(inLst, intDiv(length, inParts))
  end
  outParts
end

#= Splits a list into two sublists depending on a second list of bools. =#
function splitOnBoolLst(inLst::Lst, inBools::Lst)::Tuple{Lst, Lst}
  T = Any
  local outFalseLst::Lst = list()
  local outTrueLst::Lst = list()

  local e::T
  local rest_e::Lst = inLst
  local b::Bool
  local rest_b::Lst = inBools

  while ! listEmpty(rest_e)
    e, rest_e = listHead(rest_e), listRest(rest_e)
    b, rest_b = listHead(rest_b), listRest(rest_b)
    if b
      outTrueLst = e <| outTrueLst
    elseif isPresent(outFalseLst)
      outFalseLst = e <| outFalseLst
    end
  end
  outTrueLst = listReverseInPlace(outTrueLst)
  outFalseLst = listReverseInPlace(outFalseLst)
  (outFalseLst, outTrueLst)
end

#= Partitions a list of elements into sublists of length n.
Example: partition({1, 2, 3, 4, 5}, 2) => {{1, 2}, {3, 4}, {5}} =#
function partition(inLst::Lst, inPartitionLength::ModelicaInteger)::Lst
  T = Any
  local outPartitions::Lst = list()

  local lst::Lst = inLst
  local part::Lst
  local length::ModelicaInteger

  @assert true == (inPartitionLength > 0)
  length = listLength(inLst)
  if length == 0
    return outPartitions
  elseif inPartitionLength >= length
    outPartitions = list(inLst)
    return outPartitions
  end
  #=  Split the list into partitions.
  =#
  for i in 1:div(length, inPartitionLength)
    part, lst = split(lst, inPartitionLength)
    outPartitions = part <| outPartitions
  end
  #=  Append the remainder of the list.
  =#
  if ! listEmpty(lst)
    outPartitions = lst <| outPartitions
  end
  outPartitions = listReverseInPlace(outPartitions)
  outPartitions
end

#= Partitions a list of elements into even sublists of maximum length n.
Example: partition({1, 2, 3, 4, 5}, 2) => {{1, 2}, {3, 4}, {5}}
The number of partitions is the same as partition(), but chosen to be
as balanced in length as possible.
=#
function balancedPartition(lst::Lst, maxLength::ModelicaInteger)::Lst
  T = Any
  local outPartitions::Lst

  local length::ModelicaInteger
  local n::ModelicaInteger

  @assert true == (maxLength > 0)
  if listEmpty(lst)
    outPartitions = list()
    return outPartitions
  end
  length = listLength(lst)
  n = intDiv(length - 1, maxLength) + 1
  outPartitions = partition(lst, intDiv(length - 1, n) + 1)
  outPartitions
end

#= Returns a sublist determined by an offset and length.
Example: sublist({1,2,3,4,5}, 2, 3) => {2,3,4} =#
function sublist(inLst::Lst, inOffset::ModelicaInteger, inLength::ModelicaInteger)::Lst
  T = Any
  local outLst::Lst = list()

  local e::T
  local rest::Lst = inLst
  local res::Lst

  @assert true == (inOffset > 0)
  @assert true == (inLength >= 0)
  #=  Remove elements until we reach the offset position.
  =#
  for i in 2:inOffset
    _, rest = listHead(rest), listRest(rest)
  end
  #=  Accumulate the given number of elements.
  =#
  for i in 1:inLength
    e, rest = listHead(rest), listRest(rest)
    outLst = e <| outLst
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= Given two lists and a function, forms the cartesian product of the lists and
applies the function to each resulting pair.
Example: productMap({1, 2}, {3, 4}, intMul) = {1*3, 1*4, 2*3, 2*4} =#
function productMap(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc)::Lst
  T1 = Any ,T2 = Any ,TO = Any
  local outResult::Lst = list()

  for e1 in listReverse(inLst1), e2 in listReverse(inLst2)
    outResult = inMapFunc(e1, e2) <| outResult
  end
  outResult
end

#= Given 2 lists, generate the product of them.
Example:
list1 = {{1}, {2}}, list2 = {{1}, {3}, {4}}
result = {{1, 1}, {1, 3}, {1, 4}, {2, 1}, {2, 3}, {2, 4}} =#
function product(inLst1::Lst, inLst2::Lst)::Lst
  T = Any
  local outProduct::Lst = list()

  for e1 in inLst1, e2 in inLst2
    outProduct = listAppend(e1, e2) <| outProduct
  end
  outProduct
end

#= Transposes a list of lists. Example:
transposeLst({{1, 2, 3}, {4, 5, 6}}) => {{1, 4}, {2, 5}, {3, 6}} =#
function transposeLst(inLst::Lst)::Lst
  T = Any
  local outLst::Lst = list()

  local arr::Array
  local arr_row::Array
  local new_row::Lst
  local c_len::ModelicaInteger
  local r_len::ModelicaInteger

  if listEmpty(inLst)
    return outLst
  end
  #=  Convert the list into an array, it's a lot more efficient than fiddling
  =#
  #=  around with lists.
  =#
  arr = listArray(list(listArray(lst) for lst in inLst))
  #=  Get the dimensions of the array.
  =#
  c_len = arrayLength(arr)
  r_len = arrayLength(arrayGet(arr, 1))
  #=  Loop through the array in reverse order so we can create the new lists
  =#
  #=  in the correct order without having to reverse them.
  =#
  for i in r_len:(-1):1
    new_row = list()
    for j in c_len:(-1):1
      new_row = arrayGetNoBoundsChecking(arrayGet(arr, j), i) <| new_row
    end
    outLst = new_row <| outLst
  end
  outLst
end

function listArrayReverse(inLst::Lst)::Array
  T = Any
  local outArr::Array

  local len::ModelicaInteger
  local defaultValue::T

  if listEmpty(inLst)
    outArr = listArray(inLst)
    return outArr
  end
  len = listLength(inLst)
  defaultValue, _ = listHead(inLst), listRest(inLst)
  outArr = arrayCreateNoInit(len, defaultValue)
  for e in inLst
    arrayUpdateNoBoundsChecking(outArr, len, e)
    len = len - 1
  end
  outArr
end

#= Takes two lists and a comparison function over two elements of the lists.
It returns true if the two sets are equal, false otherwise. =#
function setEqualOnTrue(inLst1::Lst, inLst2::Lst, inCompFunc::CompFunc)::Bool
  T = Any
  local outIsEqual::Bool

  local lst::Lst
  local lst_size::ModelicaInteger

  lst = intersectionOnTrue(inLst1, inLst2, inCompFunc)
  lst_size = listLength(lst)
  outIsEqual = intEq(lst_size, listLength(inLst1)) && intEq(lst_size, listLength(inLst2))
  outIsEqual
end

#= Provides same functionality as listIntersection, but for integer values
in sorted lists. The complexity in this case is O(n). =#
function intersectionIntSorted(inLst1::Lst, inLst2::Lst)::Lst
  local outResult::Lst = list()

  local i1::ModelicaInteger
  local i2::ModelicaInteger
  local o1::ModelicaInteger
  local o2::ModelicaInteger
  local l1::Lst = inLst1
  local l2::Lst = inLst2

  if listEmpty(inLst1) || listEmpty(inLst2)
    return outResult
  end
  i1, l1 = listHead(l1), listRest(l1)
  i2, l2 = listHead(l2), listRest(l2)
  o1 = i1
  o2 = i2
  while true
    if i1 > i2
      if listEmpty(l2)
        break
      end
      i2, l2 = listHead(l2), listRest(l2)
      if o2 > i2
        fail()
      end
      o2 = i2
    elseif i1 < i2
      if listEmpty(l1)
        break
      end
      i1, l1 = listHead(l1), listRest(l1)
      if o1 > i1
        fail()
      end
      o1 = i1
    else
      outResult = i1 <| outResult
      if listEmpty(l1) || listEmpty(l2)
        break
      end
      i1, l1 = listHead(l1), listRest(l1)
      i2, l2 = listHead(l2), listRest(l2)
      if o1 > i1
        fail()
      end
      o1 = i1
      if o2 > i2
        fail()
      end
      o2 = i2
    end
  end
  outResult = listReverseInPlace(outResult)
  outResult
end

#= Provides same functionality as listIntersection, but for integer values
between 1 and N. The complexity in this case is O(n). =#
function intersectionIntN(inLst1::Lst, inLst2::Lst, inN::ModelicaInteger)::Lst
  local outResult::Lst

  local a::Array

  if inN > 0
    a = arrayCreate(inN, 0)
    a = addPos(inLst1, a, 1)
    a = addPos(inLst2, a, 1)
    outResult = intersectionIntVec(a, inLst1)
  else
    outResult = list()
  end
  outResult
end

#= Helper function to intersectionIntN. =#
function intersectionIntVec(inArray::Array, inLst1::Lst)::Lst
  local outResult::Lst = list()

  for i in inLst1
    if arrayGet(inArray, i) == 2
      outResult = i <| outResult
    end
  end
  outResult
end

#= Helper function to intersectionIntN. =#
function addPos(inLst::Lst, inArray::Array, inIndex::ModelicaInteger)::Array
  local outArray::Array

  for i in inLst
    _ = arrayUpdate(inArray, i, intAdd(arrayGet(inArray, i), inIndex))
  end
  outArray = inArray
  outArray
end

#= Takes two lists and a comparison function over two elements of the lists. It
returns the intersection of the two lists, using the comparison function
passed as argument to determine identity between two elements.
Example:
intersectionOnTrue({1, 4, 2}, {5, 2, 4, 6}, intEq) => {4, 2} =#
function intersectionOnTrue(inLst1::Lst, inLst2::Lst, inCompFunc::CompFunc)::Lst
  T = Any
  local outIntersection::Lst = list()

  for e in inLst1
    if isMemberOnTrue(e, inLst2, inCompFunc)
      outIntersection = e <| outIntersection
    end
  end
  outIntersection = listReverseInPlace(outIntersection)
  outIntersection
end

#= Takes two lists and a comparison function over two elements of the lists. It
returns the intersection of the two lists, using the comparison function
passed as argument to determine identity between two elements. This function
also returns a list of the elements from list 1 which is not in list 2 and a
list of the elements from list 2 which is not in list 1. =#
function intersection1OnTrue(inLst1::Lst, inLst2::Lst, inCompFunc::CompFunc)::Tuple{Lst, Lst, Lst}
  T = Any
  local outLst2Rest::Lst = inLst2
  local outLst1Rest::Lst = list()
  local outIntersection::Lst = list()

  local oe::Option

  if listEmpty(inLst1)
    return (outLst2Rest, outLst1Rest, outIntersection)
  end
  if listEmpty(inLst2)
    outLst1Rest = inLst1
    return (outLst2Rest, outLst1Rest, outIntersection)
  end
  for e in inLst1
    if isMemberOnTrue(e, inLst2, inCompFunc)
      outIntersection = e <| outIntersection
    elseif isPresent(outLst1Rest)
      outLst1Rest = e <| outLst1Rest
    end
  end
  outIntersection = listReverseInPlace(outIntersection)
  outLst1Rest = if isPresent(outLst1Rest) listReverseInPlace(outLst1Rest)
  else
    list()
  end
  outLst2Rest = if isPresent(outLst2Rest) setDifferenceOnTrue(inLst2, outIntersection, inCompFunc)
  else
    list()
  end
  (outLst2Rest, outLst1Rest, outIntersection)
end

#= Provides same functionality as setDifference, but for integer values
between 1 and N. The complexity in this case is O(n) =#
function setDifferenceIntN(inLst1::Lst, inLst2::Lst, inN::ModelicaInteger)::Lst
  local outDifference::Lst = list()

  local a::Array

  if inN > 0
    a = arrayCreate(inN, 0)
    a = addPos(inLst1, a, 1)
    a = addPos(inLst2, a, 1)
    for i in inN:(-1):1
      if arrayGet(a, i) == 1
        outDifference = i <| outDifference
      end
    end
  end
  outDifference
end

#= Takes two lists and a comparison function over two elements of the lists. It
returns the set difference of the two lists A-B, using the comparison
function passed as argument to determine identity between two elements.
Example:
setDifferenceOnTrue({1, 2, 3}, {1, 3}, intEq) => {2} =#
function setDifferenceOnTrue(inLst1::Lst, inLst2::Lst, inCompFunc::CompFunc)::Lst
  T = Any
  local outDifference::Lst = inLst1

  #=  Empty - B = Empty
  =#
  if listEmpty(inLst1)
    return outDifference
  end
  for e in inLst2
    outDifference, _ = deleteMemberOnTrue(e, outDifference, inCompFunc)
  end
  outDifference
end

#= Takes two lists and returns the set difference of two lists A - B.
Example:
setDifference({1, 2, 3}, {1, 3}) => {2} =#
function setDifference(inLst1::Lst, inLst2::Lst)::Lst
  T = Any
  local outDifference::Lst = inLst1

  if listEmpty(inLst1)
    return outDifference
  end
  for e in inLst2
    outDifference = deleteMember(outDifference, e)
  end
  outDifference
end

#= Provides same functionality as listUnion, but for integer values between 1
and N. The complexity in this case is O(n) =#
function unionIntN(inLst1::Lst, inLst2::Lst, inN::ModelicaInteger)::Lst
  local outUnion::Lst = list()

  local a::Array

  if inN > 0
    a = arrayCreate(inN, 0)
    a = addPos(inLst1, a, 1)
    a = addPos(inLst2, a, 1)
    for i in inN:(-1):1
      if arrayGet(a, i) > 0
        outUnion = i <| outUnion
      end
    end
  end
  outUnion
end

#= Takes a value and a list of values and inserts the value into the list if it
is not already in the list. If it is in the list it is not inserted.
Example:
unionElt(1, {2, 3}) => {1, 2, 3}
unionElt(0, {0, 1, 2}) => {0, 1, 2} =#
function unionElt(inElement::T, inLst::Lst)::Lst
  T = Any
  local outLst::Lst

  outLst = consOnTrue(! listMember(inElement, inLst), inElement, inLst)
  outLst
end

#= Works as unionElt, but with a compare function. =#
function unionEltOnTrue(inElement::T, inLst::Lst, inCompFunc::CompFunc)::Lst
  T = Any
  local outLst::Lst

  outLst = consOnTrue(! isMemberOnTrue(inElement, inLst, inCompFunc), inElement, inLst)
  outLst
end

#= Takes two lists and returns the union of the two lists, i.e. a list of all
elements combined without duplicates. Example:
union({0, 1}, {2, 1}) => {0, 1, 2} =#
function union(inLst1::Lst, inLst2::Lst)::Lst
  T = Any
  local outUnion::Lst = list()

  for e in inLst1
    outUnion = unionElt(e, outUnion)
  end
  for e in inLst2
    outUnion = unionElt(e, outUnion)
  end
  outUnion = listReverseInPlace(outUnion)
  outUnion
end

#= As union but this function assume that Lst1 is already union.
i.e. a list of all elements combined without duplicates.
Example:
union({0, 1}, {2, 1}) => {0, 1, 2} =#
function unionAppendonUnion(inLst1::Lst, inLst2::Lst)::Lst
  T = Any
  local outUnion::Lst

  outUnion = listReverse(inLst1)
  for e in inLst2
    outUnion = unionElt(e, outUnion)
  end
  outUnion = listReverseInPlace(outUnion)
  outUnion
end

#= Takes two lists an a comparison function over two elements of the lists. It
returns the union of the two lists, using the comparison function passed as
argument to determine identity between two elements. Example:
unionOnTrue({1, 2}, {2, 3}, intEq) => {1, 2, 3} =#
function unionOnTrue(inLst1::Lst, inLst2::Lst, inCompFunc::CompFunc)::Lst
  T = Any
  local outUnion::Lst = list()

  for e in inLst1
    outUnion = unionEltOnTrue(e, outUnion, inCompFunc)
  end
  for e in inLst2
    outUnion = unionEltOnTrue(e, outUnion, inCompFunc)
  end
  outUnion = listReverseInPlace(outUnion)
  outUnion
end

function unionAppendLstOnTrue(inLst::Lst, inUnion::Lst, inCompFunc::CompFunc)::Lst
  println("unionAppendLstOnTrue not implemented")
end

#= Takes a list of lists and returns the union of the sublists.
Example: unionLst({1}, {1, 2}, {3, 4}, {5}}) => {1, 2, 3, 4, 5} =#
function unionLst(inLst::Lst)::Lst
  T = Any
  local outUnion::Lst

  outUnion = if listEmpty(inLst) list()
  else
    reduce(inLst, union)
  end
  outUnion
end

#= Takes a list of lists and a comparison function over two elements of the
lists. It returns the union of all sublists using the comparison function
for identity.
Example:
unionOnTrueLst({{1}, {1, 2}, {3, 4}}, intEq) => {1, 2, 3, 4} =#
function unionOnTrueLst(inLst::Lst, inCompFunc::CompFunc)::Lst
  T = Any
  local outUnion::Lst

  outUnion = if listEmpty(inLst) list()
  else
    reduce1(inLst, unionOnTrue, inCompFunc)
  end
  outUnion
end

#= Takes a list and a function, and creates a new list by applying the function
to each element of the list. =#
function map(inLst::Lst, inFunc::MapFunc)::Lst
  TI = Any ,TO = Any
  local outLst::Lst

  outLst = list(inFunc(e) for e in inLst)
  outLst
end

#= Takes a list and a function, and creates a new list by applying the function
to each element of the list. =#
function mapCheckReferenceEq(inLst::Lst, inFunc::MapFunc)::Lst
  TI = Any
  local outLst::Lst

  local allEq::Bool = true
  local delst::DoubleEndedLst
  local n::ModelicaInteger = 0
  local e1::TI

  for e in inLst
    e1 = inFunc(e)
    if if allEq ! referenceEq(e, e1)
    else
      false
    end
      allEq = false
      delst = DoubleEndedLst.empty(e1)
      for elt in inLst
        if n < 1
          break
        end
        DoubleEndedLst.push_back(delst, elt)
        n = n - 1
      end
    end
    if allEq
      n = n + 1
    else
      DoubleEndedLst.push_back(delst, e1)
    end
  end
  #=  Preserve reference equality without any allocation if nothing changed
  =#
  outLst = if allEq inLst
  else
    DoubleEndedLst.toLstAndClear(delst)
  end
  outLst
end

#= Takes a list and a function, and creates a new list by applying the function
to each element of the list. The created list will be reversed compared to
the given list. =#
function mapReverse(inLst::Lst, inFunc::MapFunc)::Lst
  TI = Any ,TO = Any
  local outLst::Lst

  outLst = listReverse(inFunc(e) for e in inLst)
  outLst
end

#= Takes a list and a function, and creates two new lists by applying the
function to each element of the list. =#
function map_2(inLst::Lst, inFunc::MapFunc)::Tuple{Lst, Lst}
  TI = Any ,TO1 = Any ,TO2 = Any
  local outLst2::Lst = list()
  local outLst1::Lst = list()

  local e1::TO1
  local e2::TO2

  for e in inLst
    e1, e2 = inFunc(e)
    outLst1 = e1 <| outLst1
    if isPresent(outLst2)
      outLst2 = e2 <| outLst2
    end
  end
  outLst1 = listReverseInPlace(outLst1)
  if isPresent(outLst2)
    outLst2 = listReverseInPlace(outLst2)
  end
  (outLst2, outLst1)
end

#= Takes a list and a function, and creates three new lists by applying the
function to each element of the list. =#
function map_3(inLst::Lst, inFunc::MapFunc)::Tuple{Lst, Lst, Lst}
  TI = Any ,TO1 = Any ,TO2 = Any ,TO3 = Any
  local outLst3::Lst = list()
  local outLst2::Lst = list()
  local outLst1::Lst = list()

  local e1::TO1
  local e2::TO2
  local e3::TO3

  for e in inLst
    e1, e2, e3 = inFunc(e)
    outLst1 = e1 <| outLst1
    if isPresent(outLst2)
      outLst2 = e2 <| outLst2
    end
    if isPresent(outLst3)
      outLst3 = e3 <| outLst3
    end
  end
  outLst1 = listReverseInPlace(outLst1)
  if isPresent(outLst2)
    outLst2 = listReverseInPlace(outLst2)
  end
  if isPresent(outLst3)
    outLst3 = listReverseInPlace(outLst3)
  end
  (outLst3, outLst2, outLst1)
end

#= The same as map(map(inLst, getOption), inMapFunc), but is more efficient and
it strips out NONE() instead of failing on them. =#
function mapOption(inLst::Lst, inFunc::MapFunc)::Lst
  TI = Any ,TO = Any
  local outLst::Lst = list()

  local ei::TI
  local eo::TO

  for oe in inLst
    if ! isNone(oe)
      SOME(ei) = oe
      eo = inFunc(ei)
      outLst = eo <| outLst
    end
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= The same as map1(map(inLst, getOption), inMapFunc), but is more efficient and
it strips out NONE() instead of failing on them. =#
TI = Any
TO = Any
ArgT = Any
function map1Option(inLst::Lst, inFunc::MapFunc, inArg1::ArgT)::Lst
  local outLst::Lst = list()

  local ei::TI
  local eo::TO

  for oe in inLst
    if ! isNone(oe)
      SOME(ei) = oe
      eo = inFunc(ei, inArg1)
      outLst = eo <| outLst
    end
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= The same as map2(map(inLst, getOption), inMapFunc), but is more efficient and
it strips out NONE() instead of failing on them. =#
function map2Option(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any ,ArgT2 = Any
  local outLst::Lst = list()

  local ei::TI
  local eo::TO

  for oe in inLst
    if isSome(oe)
      SOME(ei) = oe
      eo = inFunc(ei, inArg1, inArg2)
      outLst = eo <| outLst
    end
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= Takes a list and a function which does not return a value. The function is
probably a function with side effects, like print. =#
function map_0(inLst::Lst, inFunc::MapFunc)
  T = Any
  for e in inLst
    inFunc(e)
  end
end

#= Takes a list, a function and one extra argument, and creates a new list
by applying the function to each element of the list. =#
function map1(inLst::Lst, inMapFunc::MapFunc, inArg1::ArgT1)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any
  local outLst::Lst

  outLst = list(inMapFunc(e, inArg1) for e in inLst)
  outLst
end

#= Takes a list, a function and one extra argument, and creates a new list
by applying the function to each element of the list. The created list will
be reversed compared to the given list. =#
function map1Reverse(inLst::Lst, inMapFunc::MapFunc, inArg1::ArgT1)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any
  local outLst::Lst

  outLst = listReverse(inMapFunc(e, inArg1) for e in inLst)
  outLst
end

#= Takes a list, a function and one extra argument, and creates a new list
by applying the function to each element of the list. The given map
function has it's arguments reversed compared to map1. =#
function map1r(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any
  local outLst::Lst

  outLst = list(inFunc(inArg1, e) for e in inLst)
  outLst
end

#= Takes a list, a function and one extra argument, and applies the functions to
each element of the list. =#
function map1_0(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1)
  TI = Any ,ArgT1 = Any
  for e in inLst
    inFunc(e, inArg1)
  end
end

#= Takes a list and a function, and creates two new lists by applying the
function to each element of the list. =#
function map1_2(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1)::Tuple{Lst, Lst}
  TI = Any ,TO1 = Any ,TO2 = Any ,ArgT1 = Any
  local outLst2::Lst = list()
  local outLst1::Lst = list()

  local e1::TO1
  local e2::TO2

  for e in inLst
    e1, e2 = inFunc(e, inArg1)
    outLst1 = e1 <| outLst1
    outLst2 = e2 <| outLst2
  end
  outLst1 = listReverseInPlace(outLst1)
  outLst2 = listReverseInPlace(outLst2)
  (outLst2, outLst1)
end

#= Takes a list and a function, and creates three new lists by applying the
function to each element of the list. =#
function map1_3(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1)::Tuple{Lst, Lst, Lst}
  TI = Any ,TO1 = Any ,TO2 = Any ,TO3 = Any ,ArgT1 = Any
  local outLst3::Lst = list()
  local outLst2::Lst = list()
  local outLst1::Lst = list()

  local e1::TO1
  local e2::TO2
  local e3::TO3

  for e in inLst
    e1, e2, e3 = inFunc(e, inArg1)
    outLst1 = e1 <| outLst1
    outLst2 = e2 <| outLst2
    outLst3 = e3 <| outLst3
  end
  outLst1 = listReverseInPlace(outLst1)
  outLst2 = listReverseInPlace(outLst2)
  outLst3 = listReverseInPlace(outLst3)
  (outLst3, outLst2, outLst1)
end

#= Takes a list, a function and two extra arguments, and creates a new list
by applying the function to each element of the list. =#
function map2(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any ,ArgT2 = Any
  local outLst::Lst

  outLst = list(inFunc(e, inArg1, inArg2) for e in inLst)
  outLst
end

#= Takes a list, a function and two extra arguments, and creates a new list
by applying the function to each element of the list. The created list will
be reversed compared to the given list. =#
function map2Reverse(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any ,ArgT2 = Any
  local outLst::Lst

  outLst = listReverse(inFunc(e, inArg1, inArg2) for e in inLst)
  outLst
end

#= Takes a list, a function and two extra argument, and creates a new list
by applying the function to each element of the list. The given map
function has it's arguments in another order compared to map2 and map2r. =#
function map2rm(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any ,ArgT2 = Any
  local outLst::Lst

  outLst = list(inFunc(inArg1, e, inArg2) for e in inLst)
  outLst
end

#= Takes a list, a function and two extra argument, and creates a new list
by applying the function to each element of the list. The given map
function has it's arguments reversed compared to map2. =#
function map2r(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any ,ArgT2 = Any
  local outLst::Lst

  outLst = list(inFunc(inArg1, inArg2, e) for e in inLst)
  outLst
end

#= Takes a list, a function and two extra argument, and applies the functions to
each element of the list. =#
function map2_0(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)
  TI = Any ,ArgT1 = Any ,ArgT2 = Any
  for e in inLst
    inFunc(e, inArg1, inArg2)
  end
end

#= Takes a list, a function and two extra argument, and creates two new lists
by applying the function to each element of the list. =#
function map2_2(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)::Tuple{Lst, Lst}
  TI = Any ,TO1 = Any ,TO2 = Any ,ArgT1 = Any ,ArgT2 = Any
  local outLst2::Lst = list()
  local outLst1::Lst = list()

  local e1::TO1
  local e2::TO2

  for e in inLst
    e1, e2 = inFunc(e, inArg1, inArg2)
    outLst1 = e1 <| outLst1
    outLst2 = e2 <| outLst2
  end
  outLst1 = listReverseInPlace(outLst1)
  outLst2 = listReverseInPlace(outLst2)
  (outLst2, outLst1)
end

#= Takes a list, a function and two extra argument, and creates three new lists
by applying the function to each element of the list. =#
function map2_3(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)::Tuple{Lst, Lst, Lst}
  TI = Any ,TO1 = Any ,TO2 = Any ,TO3 = Any ,ArgT1 = Any ,ArgT2 = Any
  local outLst3::Lst = list()
  local outLst2::Lst = list()
  local outLst1::Lst = list()

  local e1::TO1
  local e2::TO2
  local e3::TO3

  for e in inLst
    e1, e2, e3 = inFunc(e, inArg1, inArg2)
    outLst1 = e1 <| outLst1
    outLst2 = e2 <| outLst2
    outLst3 = e3 <| outLst3
  end
  outLst1 = listReverseInPlace(outLst1)
  outLst2 = listReverseInPlace(outLst2)
  outLst3 = listReverseInPlace(outLst3)
  (outLst3, outLst2, outLst1)
end

#= Takes a list, a function and three extra arguments, and creates a new list
by applying the function to each element of the list. =#
TI = Any
TO = Any
ArgT1 = Any
ArgT2 = Any
ArgT3 = Any
function map3(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)::Lst
  local outLst::Lst

  outLst = list(inFunc(e, inArg1, inArg2, inArg3) for e in inLst)
  outLst
end

#= Takes a list, a function and three extra argument, and creates a new list
by applying the function to each element of the list. The given map
function has it's arguments reversed compared to map3. =#
function map3r(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any ,ArgT2 = Any ,ArgT3 = Any
  local outLst::Lst

  outLst = list(inFunc(inArg1, inArg2, inArg3, e) for e in inLst)
  outLst
end

#= Takes a list, a function and three extra argument, and applies the functions to
each element of the list. =#
function map3_0(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)
  TI = Any ,ArgT1 = Any ,ArgT2 = Any ,ArgT3 = Any
  for e in inLst
    inFunc(e, inArg1, inArg2, inArg3)
  end
end

#= Takes a list, a function and three extra argument, and creates two new lists
by applying the function to each element of the list. =#
function map3_2(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)::Tuple{Lst, Lst}
  TI = Any ,TO1 = Any ,TO2 = Any ,ArgT1 = Any ,ArgT2 = Any ,ArgT3 = Any
  local outLst2::Lst = list()
  local outLst1::Lst = list()

  local e1::TO1
  local e2::TO2

  for e in inLst
    e1, e2 = inFunc(e, inArg1, inArg2, inArg3)
    outLst1 = e1 <| outLst1
    outLst2 = e2 <| outLst2
  end
  outLst1 = listReverseInPlace(outLst1)
  outLst2 = listReverseInPlace(outLst2)
  (outLst2, outLst1)
end

#= Takes a list, a function and four extra arguments, and creates a new list
by applying the function to each element of the list. =#
ArgT4 = Any
function map4(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4)::Lst
  local outLst::Lst

  outLst = list(inFunc(e, inArg1, inArg2, inArg3, inArg4) for e in inLst)
  outLst
end

#= Takes a list, a function and four extra arguments, and applies the functions to
each element of the list. =#
function map4_0(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4)
  TI = Any ,ArgT1 = Any ,ArgT2 = Any ,ArgT3 = Any ,ArgT4 = Any
  for e in inLst
    inFunc(e, inArg1, inArg2, inArg3, inArg4)
  end
end

#= Takes a list, a function and three extra argument, and creates two new lists
by applying the function to each element of the list. =#
function map4_2(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4)::Tuple{Lst, Lst}
  TI = Any ,TO1 = Any ,TO2 = Any ,ArgT1 = Any ,ArgT2 = Any ,ArgT3 = Any ,ArgT4 = Any
  local outLst2::Lst = list()
  local outLst1::Lst = list()

  local e1::TO1
  local e2::TO2

  for e in inLst
    e1, e2 = inFunc(e, inArg1, inArg2, inArg3, inArg4)
    outLst1 = e1 <| outLst1
    outLst2 = e2 <| outLst2
  end
  outLst1 = listReverseInPlace(outLst1)
  outLst2 = listReverseInPlace(outLst2)
  (outLst2, outLst1)
end

#= Takes a list, a function and five extra arguments, and creates a new list
by applying the function to each element of the list. =#
ArgT5 = Any
function map5(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inArg5::ArgT5)::Lst

  local outLst::Lst

  outLst = list(inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5) for e in inLst)
  outLst
end
ArgT6 = Any
#= Takes a list, a function and six extra arguments, and creates a new list
by applying the function to each element of the list. =#
function map6(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inArg5::ArgT5, inArg6::ArgT6)::Lst
  local outLst::Lst

  outLst = list(inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6) for e in inLst)
  outLst
end
ArgT7 = Any
#= Takes a list, a function and seven extra arguments, and creates a new list
by applying the function to each element of the list. =#
function map7(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inArg5::ArgT5, inArg6::ArgT6, inArg7::ArgT7)::Lst
  local outLst::Lst

  outLst = list(inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7) for e in inLst)
  outLst
end

ArgT8 = Any
#= Takes a list, a function and eight extra arguments, and creates a new list
by applying the function to each element of the list. =#
function map8(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inArg5::ArgT5, inArg6::ArgT6, inArg7::ArgT7, inArg8::ArgT8)::Lst

  local outLst::Lst

  outLst = list(inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7, inArg8) for e in inLst)
  outLst
end

ArgT9 = Any
#= Takes a list, a function and nine extra arguments, and creates a new list
by applying the function to each element of the list. =#
function map9(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inArg5::ArgT5, inArg6::ArgT6, inArg7::ArgT7, inArg8::ArgT8, inArg9::ArgT9)::Lst

  local outLst::Lst

  outLst = list(inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7, inArg8, inArg9) for e in inLst)
  outLst
end

#= Takes a list and a function that maps elements to lists, which are flattened
into one list. Example (fill2(n) = {n, n}):
mapFlat({1, 2, 3}, fill2) => {1, 1, 2, 2, 3, 3} =#
function mapFlat(inLst::Lst, inMapFunc::MapFunc)::Lst
  TI = Any ,TO = Any
  local outLst::Lst

  outLst = listReverse(mapFlatReverse(inLst, inMapFunc))
  outLst
end

#= Takes a list and a function that maps elements to lists, which are flattened
into one list. Returns the values in reverse order as the input.
Example (fill2(n) = {n, n}):
mapFlat({1, 2, 3}, fill2) => {3, 3, 2, 2, 1, 1} =#
function mapFlatReverse(inLst::Lst, inMapFunc::MapFunc)::Lst
  TI = Any ,TO = Any
  local outLst::Lst = list()

  for e in inLst
    outLst = listAppend(inMapFunc(e), outLst)
  end
  outLst
end

#= Takes a list and a function that maps elements to lists, which are flattened
into one list. This function also takes an extra argument that is passed to
the mapping function. =#
function map1Flat(inLst::Lst, inMapFunc::MapFunc, inArg1::ArgT1)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any
  local outLst::Lst = list()

  for e in inLst
    outLst = listAppend(inMapFunc(e, inArg1), outLst)
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= Takes a list and a function that maps elements to lists, which are flattened
into one list. This function also takes two extra arguments that are passed
to the mapping function. =#
function map2Flat(inLst::Lst, inMapFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any ,ArgT2 = Any
  local outLst::Lst = list()

  for e in inLst
    outLst = listAppend(inMapFunc(e, inArg1, inArg2), outLst)
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= More efficient than: map(map(inLst, inMapFunc1), inMapFunc2) =#
function mapMap(inLst::Lst, inMapFunc1::MapFunc1, inMapFunc2::MapFunc2)::Lst
  TI = Any ,TO1 = Any ,TO2 = Any
  local outLst::Lst

  outLst = list(inMapFunc2(inMapFunc1(e)) for e in inLst)
  outLst
end

#= More efficient than map_0(map(inLst, inMapFunc1), inMapFunc2), =#
function mapMap_0(inLst::Lst, inMapFunc1::MapFunc1, inMapFunc2::MapFunc2)
  TI = Any ,TO = Any
  for e in inLst
    inMapFunc2(inMapFunc1(e))
  end
end

#= Applies a function to all elements in the lists, and fails if not all
elements are equal to the given value. =#
VT = Any
function mapAllValue(inLst::Lst, inMapFunc::MapFunc, inValue::VT)
  local eo::TO

  for e in inLst
    eo = inMapFunc(e)
    @assert true == (valueEq(eo, inValue))
  end
end

#= Same as mapAllValue, but returns true or false instead of succeeding or
failing. =#
function mapAllValueBool(inLst::Lst, inMapFunc::MapFunc, inValue::VT)::Bool
  TI = Any ,TO = Any ,VT = Any
  local outAllValue::Bool

  try
    mapAllValue(inLst, inMapFunc, inValue)
    outAllValue = true
  catch
    outAllValue = false
  end
  outAllValue
end

#= Same as mapAllValueBool, but takes one extra argument. =#
function map1AllValueBool(inLst::Lst, inMapFunc::MapFunc, inValue::VT, inArg1::ArgT1)::Bool
  TI = Any ,TO = Any ,VT = Any ,ArgT1 = Any
  local outAllValue::Bool

  try
    map1AllValue(inLst, inMapFunc, inValue, inArg1)
    outAllValue = true
  catch
    outAllValue = false
  end
  outAllValue
end

#= Applies a function to all elements in the lists, and fails if not all
elements are equal to the given value. This function also takes an extra
argument that are passed to the mapping function. =#
function map1AllValue(inLst::Lst, inMapFunc::MapFunc, inValue::VT, inArg1::ArgT1)
  TI = Any ,TO = Any ,VT = Any ,ArgT1 = Any
  local eo::TO

  for e in inLst
    eo = inMapFunc(e, inArg1)
    @assert true == (valueEq(eo, inValue))
  end
end

#= Applies a function to all elements in the lists, and fails if not all
elements are equal to the given value. This function also takes an extra
argument that are passed to the mapping function. =#
function map1rAllValue(inLst::Lst, inMapFunc::MapFunc, inValue::VT, inArg1::ArgT1)
  TI = Any ,TO = Any ,VT = Any ,ArgT1 = Any
  local eo::TO

  for e in inLst
    eo = inMapFunc(inArg1, e)
    @assert true == (valueEq(eo, inValue))
  end
end

#= Applies a function to all elements in the lists, and fails if not all
elements are equal to the given value. This function also takes two extra
arguments that are passed to the mapping function. =#
function map2AllValue(inLst::Lst, inMapFunc::MapFunc, inValue::VT, inArg1::ArgT1, inArg2::ArgT2)
  TI = Any ,TO = Any ,VT = Any ,ArgT1 = Any ,ArgT2 = Any
  local eo::TO

  for e in inLst
    eo = inMapFunc(e, inArg1, inArg2)
    @assert true == (valueEq(eo, inValue))
  end
end

#= Same as mapAllValue, but returns true or false instead of succeeding or
failing. =#
function mapLstAllValueBool(inLst::Lst, inMapFunc::MapFunc, inValue::VT)::Bool
  TI = Any ,TO = Any ,VT = Any
  local outAllValue::Bool = true

  for lst in inLst
    if ! mapAllValueBool(lst, inMapFunc, inValue)
      outAllValue = false
      return outAllValue
    end
  end
  outAllValue
end

#= Same as mapLstAllValueBool, but takes one extra argument. =#
function map1LstAllValueBool(inLst::Lst, inMapFunc::MapFunc, inValue::VT, inArg1::ArgT1)::Bool
  TI = Any ,TO = Any ,VT = Any ,ArgT1 = Any
  local outAllValue::Bool = true

  for lst in inLst
    if ! map1AllValueBool(lst, inMapFunc, inValue, inArg1)
      outAllValue = false
      return outAllValue
    end
  end
  outAllValue
end

#= Applies a function to all elements in the lists, and fails if not all
elements are equal to the given value. This function also takes an extra
argument that are passed to the mapping function and updated =#
function foldAllValue(inLst::Lst, inMapFunc::MapFunc, inValue::TO, inArg1::ArgT1)
  TI = Any ,TO = Any ,ArgT1 = Any
  local arg::ArgT1 = inArg1
  local eo::TO

  for e in inLst
    eo, arg = inMapFunc(e, arg)
    @assert true == (valueEq(eo, inValue))
  end
end

#= fold(map(inLst, inApplyFunc), inFoldFunc, inFoldArg), but is more
memory-efficient. =#
FT = Any
function applyAndFold(inLst::Lst, inFoldFunc::FoldFunc, inApplyFunc::ApplyFunc, inFoldArg::FT)::FT
  local outResult::FT = inFoldArg

  for e in inLst
    outResult = inFoldFunc(inApplyFunc(e), outResult)
  end
  outResult
end

#= fold(map(inLst, inApplyFunc(inExtraArg)), inFoldFunc, inFoldArg), but is more
memory-efficient. =#
function applyAndFold1(inLst::Lst, inFoldFunc::FoldFunc, inApplyFunc::ApplyFunc, inExtraArg::ArgT1, inFoldArg::FT)::FT
  TI = Any ,TO = Any ,FT = Any ,ArgT1 = Any
  local outResult::FT = inFoldArg

  for e in inLst
    outResult = inFoldFunc(inApplyFunc(e, inExtraArg), outResult)
  end
  outResult
end

#= Maps each element of a inLst to Boolean type with inFunc. Stops mapping at first occurrence of true return value. =#
function mapBoolOr(inLst::Lst, inFunc::MapFunc)::Bool
  TI = Any ,ArgT1 = Any
  local res::Bool = false

  for e in inLst
    if inFunc(e)
      res = true
      return res
    end
  end
  res
end

#= Maps each element of a inLst to Boolean type with inFunc. Stops mapping at first occurrence of true return value. =#
function mapBoolAnd(inLst::Lst, inFunc::MapFunc)::Bool
  TI = Any
  local res::Bool = false

  for e in inLst
    if ! inFunc(e)
      return res
    end
  end
  res = true
  res
end

#= Maps each element of a inLst to Boolean type with inFunc. Stops mapping at first occurrence of true return value. =#
function mapMapBoolAnd(inLst::Lst, inFunc::MapFunc, inBFunc::MapBFunc)::Bool
  TI = Any ,TI2 = Any
  local res::Bool = false

  for e in inLst
    if ! inBFunc(inFunc(e))
      return res
    end
  end
  res = true
  res
end

#= Maps each element of a inLst to Boolean type with inFunc. Stops mapping at first occurrence of true return value.
inFunc takes one additional argument. =#
function map1BoolOr(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1)::Bool
  TI = Any ,ArgT1 = Any
  local res::Bool = false

  for e in inLst
    if inFunc(e, inArg1)
      res = true
      return res
    end
  end
  res
end

#= Maps each element of a inLst to Boolean type with inFunc. Stops mapping at first occurrence of false return value.
inFunc takes one additional argument. =#
function map1BoolAnd(inLst::Lst, inFunc::MapFunc, inArg1::ArgT1)::Bool
  TI = Any ,ArgT1 = Any
  local res::Bool = false

  for e in inLst
    if ! inFunc(e, inArg1)
      return res
    end
  end
  res = true
  res
end

#= Maps each element of a inLst to Boolean type with inFunc. Stops mapping at first occurrence of true return value.
inFunc takes one additional argument. =#
function map1LstBoolOr(inLstLst::Lst, inFunc::MapFunc, inArg1::ArgT1)::Bool
  TI = Any ,ArgT1 = Any
  local res::Bool = false

  for el in inLstLst
    for e in el
      if inFunc(e, inArg1)
        res = true
        return res
      end
    end
  end
  res
end

#= Takes a list of lists and a functions, and creates a new list of lists by
applying the function to all elements in  the list of lists.
Example: mapLst({{1, 2},{3},{4}}, intString) =>
{{\\\"1\\\", \\\"2\\\"}, {\\\"3\\\"}, {\\\"4\\\"}} =#
function mapLst(inLstLst::Lst, inFunc::MapFunc)::Lst
  TI = Any ,TO = Any
  local outLstLst::Lst

  outLstLst = list(list(inFunc(e) for e in lst) for lst in inLstLst)
  outLstLst
end

#= Takes a list of lists and a functions, and applying
the function to all elements in  the list of lists.
Example: mapLst0({{1, 2},{3},{4}}, print) =#
function mapLst0(inLstLst::Lst, inFunc::MapFunc)
  TI = Any
  map1_0(inLstLst, map_0, inFunc)
end

#= Takes a list of lists and a functions, and applying
the function to all elements in  the list of lists.
Example: mapLst1_0({{1, 2},{3},{4}}, costomPrint, inArg1) =#
function mapLst1_0(inLstLst::Lst, inFunc::MapFunc, inArg1::ArgT1)
  TI = Any ,ArgT1 = Any
  map2_0(inLstLst, map1_0, inFunc, inArg1)
end

#= Takes a list of lists and a functions, and applying
the function to all elements in  the list of lists.
Example: mapLst1_0({{1, 2},{3},{4}}, costomPrint, inArg1, inArg2) =#
function mapLst2_0(inLstLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)
  TI = Any ,ArgT1 = Any ,ArgT2 = Any
  map3_0(inLstLst, map2_0, inFunc, inArg1, inArg2)
end

#= Takes a list of lists and a functions, and applying
the function to all elements in  the list of lists.
Example: mapLst1_0({{1, 2},{3},{4}}, customPrint, inArg1) =#
function mapLst1_1(inLstLst::Lst, inFunc::MapFunc, inArg1::ArgT1)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any
  local outLstLst::Lst

  outLstLst = list(list(inFunc(e, inArg1) for e in lst) for lst in inLstLst)
  outLstLst
end

#= Takes a list of lists and a functions, and creates a new list of lists by
applying the function to all elements in  the list of lists. The order of the
elements in the inner lists will be reversed compared to mapLst.
Example: mapLstReverse({{1, 2}, {3}, {4}}, intString) =>
{{\\\"4\\\"}, {\\\"3\\\"}, {\\\"2\\\", \\\"1\\\"}} =#
function mapLstReverse(inLstLst::Lst, inFunc::MapFunc)::Lst
  TI = Any ,TO = Any
  local outLstLst::Lst

  outLstLst = list(listReverse(inFunc(e) for e in lst) for lst in inLstLst)
  outLstLst
end

#= Similar to mapLst but with a mapping function that takes an extra argument. =#
function map1Lst(inLstLst::Lst, inFunc::MapFunc, inArg1::ArgT1)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any
  local outLstLst::Lst

  outLstLst = list(list(inFunc(e, inArg1) for e in lst) for lst in inLstLst)
  outLstLst
end

#= Similar to mapLst but with a mapping function that takes two extra arguments. =#
function map2Lst(inLstLst::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any ,ArgT2 = Any
  local outLstLst::Lst

  outLstLst = list(list(inFunc(e, inArg1, inArg2) for e in lst) for lst in inLstLst)
  outLstLst
end

#= Takes a list and a function operating on list elements having an extra
argument that is 'updated', thus returned from the function. fold will call
the function for each element in a sequence, updating the start value.
Example: fold({1, 2, 3}, intAdd, 2) => 8
intAdd(1, 2) => 3, intAdd(2, 3) => 5, intAdd(3, 5) => 8 =#
function fold(inLst::Lst, inFoldFunc::FoldFunc, inStartValue::FT)::FT
  T = Any ,FT = Any
  local outResult::FT = inStartValue

  for e in inLst
    outResult = inFoldFunc(e, outResult)
  end
  outResult
end

#= Same as fold, but with reversed order on the fold function arguments. =#
function foldr(inLst::Lst, inFoldFunc::FoldFunc, inStartValue::FT)::FT
  T = Any ,FT = Any
  local outResult::FT = inStartValue

  for e in inLst
    outResult = inFoldFunc(outResult, e)
  end
  outResult
end

#= Takes a list and a function operating on list elements having an extra
argument that is 'updated', thus returned from the function, and a constant
argument that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#
function fold1(inLst::Lst, inFoldFunc::FoldFunc, inExtraArg::ArgT1, inStartValue::FT)::FT
  T = Any ,FT = Any ,ArgT1 = Any
  local outResult::FT = inStartValue

  for e in inLst
    outResult = inFoldFunc(e, inExtraArg, outResult)
  end
  outResult
end

#= Same as fold1, but with reversed order on the fold function arguments. =#
function fold1r(inLst::Lst, inFoldFunc::FoldFunc, inExtraArg::ArgT1, inStartValue::FT)::FT
  T = Any ,FT = Any ,ArgT1 = Any
  local outResult::FT = inStartValue

  for e in inLst
    outResult = inFoldFunc(outResult, e, inExtraArg)
  end
  outResult
end

#= Takes a list and a function operating on list elements having an extra
argument that is 'updated', thus returned from the function, and two constant
arguments that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#
function fold2(inLst::Lst, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inStartValue::FT)::FT
  T = Any ,FT = Any ,ArgT1 = Any ,ArgT2 = Any
  local outResult::FT = inStartValue

  for e in inLst
    outResult = inFoldFunc(e, inExtraArg1, inExtraArg2, outResult)
  end
  outResult
end

#= Takes a list and a function operating on list elements having three extra
arguments that is 'updated', thus returned from the function, and three constant
arguments that are not updated. fold will call the function for each element in
a sequence, updating the start values. =#
FT1 = Any
FT2 = Any
function fold22(inLst::Lst, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inStartValue1::FT1, inStartValue2::FT2)::Tuple{FT2, FT1}
  local outResult2::FT2 = inStartValue2
  local outResult1::FT1 = inStartValue1

  for e in inLst
    outResult1, outResult2 = inFoldFunc(e, inExtraArg1, inExtraArg2, outResult1, outResult2)
  end
  (outResult2, outResult1)
end

function foldLst(inLst::Lst, inFoldFunc::FoldFunc, inStartValue::FT)::FT
  local outResult::FT = inStartValue

  for lst in inLst
    for e in lst
      outResult = inFoldFunc(e, outResult)
    end
  end
  outResult
end

function foldLst1(inLst::Lst, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inStartValue::FT)::FT
  local outResult::FT = inStartValue

  for lst in inLst
    for e in lst
      outResult = inFoldFunc(e, inExtraArg1, outResult)
    end
  end
  outResult
end

#= Takes a list and a function operating on list elements having an extra
argument that is 'updated', thus returned from the function, and two constant
arguments that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#
function foldLst2(inLst::Lst, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inStartValue::FT)::FT
  local outResult::FT = inStartValue

  for lst in inLst
    for e in lst
      outResult = inFoldFunc(e, inExtraArg1, inExtraArg2, outResult)
    end
  end
  outResult
end

#= Same as fold2, but with reversed order on the fold function arguments. =#
function fold2r(inLst::Lst, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inStartValue::FT)::FT
  local outResult::FT = inStartValue

  for e in inLst
    outResult = inFoldFunc(outResult, e, inExtraArg1, inExtraArg2)
  end
  outResult
end

#= Takes a list and a function operating on list elements having an extra
argument that is 'updated', thus returned from the function, and three constant
arguments that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#
function fold3(inLst::Lst, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inExtraArg3::ArgT3, inStartValue::FT)::FT
  local outResult::FT = inStartValue

  for e in inLst
    outResult = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, outResult)
  end
  outResult
end

#= Same as fold3, but with reversed order on the fold function arguments. =#
function fold3r(inLst::Lst, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inExtraArg3::ArgT3, inStartValue::FT)::FT
  local outResult::FT = inStartValue

  for e in inLst
    outResult = inFoldFunc(outResult, e, inExtraArg1, inExtraArg2, inExtraArg3)
  end
  outResult
end

#= Takes a list and a function operating on list elements having an extra
argument that is 'updated', thus returned from the function, and four constant
arguments that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#
function fold4(inLst::Lst, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inExtraArg3::ArgT3, inExtraArg4::ArgT4, inStartValue::FT)::FT
  local outResult::FT = inStartValue
  for e in inLst
    outResult = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, outResult)
  end
  outResult
end

#= Takes a list and a function operating on list elements having three extra
arguments that is 'updated', thus returned from the function, and three constant
arguments that are not updated. fold will call the function for each element in
a sequence, updating the start values. =#
function fold43(inLst::Lst, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inExtraArg3::ArgT3, inExtraArg4::ArgT4, inStartValue1::FT1, inStartValue2::FT2, inStartValue3::FT3)::Tuple{FT3, FT2, FT1}
  local outResult3::FT3 = inStartValue3
  local outResult2::FT2 = inStartValue2
  local outResult1::FT1 = inStartValue1

  for e in inLst
    outResult1, outResult2, outResult3 = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, outResult1, outResult2, outResult3)
  end
  (outResult3, outResult2, outResult1)
end

#= Takes a list and a function operating on list elements having two extra
arguments that are 'updated', thus returned from the function. fold will call
the function for each element in a sequence, updating the start value. =#
function fold20(inLst::Lst, inFoldFunc::FoldFunc, inStartValue1::FT1, inStartValue2::FT2)::Tuple{FT2, FT1}
  local outResult2::FT2 = inStartValue2
  local outResult1::FT1 = inStartValue1

  for e in inLst
    outResult1, outResult2 = inFoldFunc(e, outResult1, outResult2)
  end
  (outResult2, outResult1)
end

#= Takes a list and a function operating on list elements having three extra
arguments that are 'updated', thus returned from the function. fold will call
the function for each element in a sequence, updating the start value. =#

function fold30(inLst::Lst, inFoldFunc::FoldFunc, inStartValue1::FT1, inStartValue2::FT2, inStartValue3::FT3)::Tuple{FT3, FT2, FT1}
  local outResult3::FT3 = inStartValue3
  local outResult2::FT2 = inStartValue2
  local outResult1::FT1 = inStartValue1

  for e in inLst
    outResult1, outResult2, outResult3 = inFoldFunc(e, outResult1, outResult2, outResult3)
  end
  (outResult3, outResult2, outResult1)
end

#= Takes a list and a function operating on list elements having two extra
argument that are 'updated', thus returned from the function, and one constant
argument that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#
function fold21(inLst::Lst, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inStartValue1::FT1, inStartValue2::FT2)::Tuple{FT2, FT1}
  local outResult2::FT2 = inStartValue2
  local outResult1::FT1 = inStartValue1

  for e in inLst
    outResult1, outResult2 = inFoldFunc(e, inExtraArg1, outResult1, outResult2)
  end
  (outResult2, outResult1)
end

#= Takes a list and a function operating on list elements having three extra
argument that are 'updated', thus returned from the function, and one constant
argument that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#

function fold31(inLst::Lst, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inStartValue1::FT1, inStartValue2::FT2, inStartValue3::FT3)::Tuple{FT3, FT2, FT1}
  local outResult3::FT3 = inStartValue3
  local outResult2::FT2 = inStartValue2
  local outResult1::FT1 = inStartValue1

  for e in inLst
    outResult1, outResult2, outResult3 = inFoldFunc(e, inExtraArg1, outResult1, outResult2, outResult3)
  end
  (outResult3, outResult2, outResult1)
end

#= Takes a list and a function operating on list elements having an extra
argument that is 'updated', thus returned from the function, and five constant
arguments that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#

function fold5(inLst::Lst, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inExtraArg3::ArgT3, inExtraArg4::ArgT4, inExtraArg5::ArgT5, inStartValue::FT)::FT
  local outResult::FT = inStartValue

  for e in inLst
    outResult = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inExtraArg5, outResult)
  end
  outResult
end

#= Takes a list, an extra argument and a function. The function will be applied
to each element in the list, and the extra argument will be passed to the
function and updated. =#

function mapFold(inLst::Lst, inFunc::FuncType, inArg::FT)::Tuple{FT, Lst}
  local outArg::FT = inArg
  local outLst::Lst = list()

  local res::TO

  for e in inLst
    res, outArg = inFunc(e, outArg)
    outLst = res <| outLst
  end
  outLst = listReverseInPlace(outLst)
  (outArg, outLst)
end

#= Takes a list, a function, and two extra arguments. The function will be applied
to each element in the list, and the extra arguments will be passed to the
function and updated. =#

function mapFold2(inLst::Lst, inFunc::FuncType, inArg1::FT1, inArg2::FT2)::Tuple{FT2, FT1, Lst}
  local outArg2::FT2 = inArg2
  local outArg1::FT1 = inArg1
  local outLst::Lst = list()

  local res::TO

  for e in inLst
    res, outArg1, outArg2 = inFunc(e, outArg1, outArg2)
    outLst = res <| outLst
  end
  outLst = listReverseInPlace(outLst)
  (outArg2, outArg1, outLst)
end

#= Takes a list, a function, and three extra arguments. The function will be applied
to each element in the list, and the extra arguments will be passed to the
function and updated. =#
function mapFold3(inLst::Lst, inFunc::FuncType, inArg1::FT1, inArg2::FT2, inArg3::FT3)::Tuple{FT3, FT2, FT1, Lst}
  local outLst::Lst = list()

  local res::TO

  for e in inLst
    res, inArg1, inArg2, inArg3 = inFunc(e, inArg1, inArg2, inArg3)
    outLst = res <| outLst
  end
  outLst = listReverseInPlace(outLst)
  (inArg3, inArg2, inArg1, outLst)
end

#= Takes a list, a function, and four extra arguments. The function will be applied
to each element in the list, and the extra arguments will be passed to the
function and updated. =#
function mapFold4(inLst::Lst, inFunc::FuncType, inArg1::FT1, inArg2::FT2, inArg3::FT3, inArg4::FT4)::Tuple{FT4, FT3, FT2, FT1, Lst}
  local outLst::Lst = list()
  local res::TO
  for e in inLst
    res, inArg1, inArg2, inArg3, inArg4 = inFunc(e, inArg1, inArg2, inArg3, inArg4)
    outLst = res <| outLst
  end
  outLst = listReverseInPlace(outLst)
  (inArg4, inArg3, inArg2, inArg1, outLst)
end

#= Takes a list, a function, and five extra arguments. The function will be applied
to each element in the list, and the extra arguments will be passed to the
function and updated. =#
function mapFold5(inLst::Lst, inFunc::FuncType, inArg1::FT1, inArg2::FT2, inArg3::FT3, inArg4::FT4, inArg5::FT5)::Tuple{FT5, FT4, FT3, FT2, FT1, Lst}
  local outLst::Lst = list()
  local res::TO
  for e in inLst
    res, inArg1, inArg2, inArg3, inArg4, inArg5 = inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5)
    outLst = res <| outLst
  end
  outLst = listReverseInPlace(outLst)
  (inArg5, inArg4, inArg3, inArg2, inArg1, outLst)
end

#= Takes a list, an extra argument, an extra constant argument, and a function.
The function will be applied to each element in the list, and the extra
argument will be passed to the function and updated. =#
function map1Fold(inLst::Lst, inFunc::FuncType, inConstArg::ArgT1, inArg::FT)::Tuple{FT, Lst}
  TI = Any ,TO = Any ,FT = Any ,ArgT1 = Any
  local outArg::FT = inArg
  local outLst::Lst = list()

  local res::TO

  for e in inLst
    res, outArg = inFunc(e, inConstArg, outArg)
    outLst = res <| outLst
  end
  outLst = listReverseInPlace(outLst)
  (outArg, outLst)
end

#= Takes a list, two extra constant arguments, an extra argument, and a function.
The function will be applied to each element in the list, and the extra
argument will be passed to the function and updated. =#
function map2Fold(inLst::Lst, inFunc::FuncType, inConstArg::ArgT1, inConstArg2::ArgT2, inArg::FT, inAccum::Lst)::Tuple{FT, Lst}
  local outArg::FT = inArg
  local outLst::Lst = inAccum
  local res::TO
  for e in inLst
    res, outArg = inFunc(e, inConstArg, inConstArg2, outArg)
    outLst = res <| outLst
  end
  outLst = listReverseInPlace(outLst)
  (outArg, outLst)
end

#= Takes a list, two extra constant arguments, an extra argument, and a function.
The function will be applied to each element in the list, and the extra
argument will be passed to the function and updated. =#
function map2FoldCheckReferenceEq(inLst::Lst, inFunc::FuncType, inConstArg::ArgT1, inConstArg2::ArgT2, inArg::FT)::Tuple{FT, Lst}
  local outArg::FT = inArg
  local outLst::Lst
  local res::TIO
  local allEq::Bool = true
  local delst::DoubleEndedLst
  local n::ModelicaInteger = 0
  for e in inLst
    res, outArg = inFunc(e, inConstArg, inConstArg2, outArg)
    if if allEq ! referenceEq(e, res)
    else
      false
    end
      allEq = false
      delst = DoubleEndedLst.empty(res)
      for elt in inLst
        if n < 1
          break
        end
        DoubleEndedLst.push_back(delst, elt)
        n = n - 1
      end
    end
    if allEq
      n = n + 1
    else
      DoubleEndedLst.push_back(delst, res)
    end
  end
  outLst = if allEq inLst
  else
    DoubleEndedLst.toLstAndClear(delst)
  end
  (outArg, outLst)
end

#= Takes a list, three extra constant arguments, an extra argument, and a function.
The function will be applied to each element in the list, and the extra
argument will be passed to the function and updated. =#
function map3Fold(inLst::Lst, inFunc::FuncType, inConstArg::ArgT1, inConstArg2::ArgT2, inConstArg3::ArgT3, inArg::FT)::Tuple{FT, Lst}
  local outArg::FT = inArg
  local outLst::Lst = list()

  local res::TO

  for e in inLst
    res, outArg = inFunc(e, inConstArg, inConstArg2, inConstArg3, outArg)
    outLst = res <| outLst
  end
  outLst = listReverseInPlace(outLst)
  (outArg, outLst)
end

#= Takes a list, four extra constant arguments, an extra argument, and a function.
The function will be applied to each element in the list, and the extra
argument will be passed to the function and updated. =#
function map4Fold(inLst::Lst, inFunc::FuncType, inConstArg::ArgT1, inConstArg2::ArgT2, inConstArg3::ArgT3, inConstArg4::ArgT4, inArg::FT)::Tuple{FT, Lst}
  local outArg::FT = inArg
  local outLst::Lst = list()

  local res::TO

  for e in inLst
    res, outArg = inFunc(e, inConstArg, inConstArg2, inConstArg3, inConstArg4, outArg)
    outLst = res <| outLst
  end
  outLst = listReverseInPlace(outLst)
  (outArg, outLst)
end

#= Takes a list, an extra argument and a function. The function will be applied
to each element in the list, and the extra argument will be passed to the
function and updated. The input and outputs of the function are joined as
tuples. =#
function mapFoldTuple(inLst::Lst, inFunc::FuncType, inArg::FT)::Tuple{FT, Lst}
  TI = Any ,TO = Any ,FT = Any
  local outArg::FT = inArg
  local outLst::Lst = list()

  local res::TO

  for e in inLst
    res, outArg = inFunc(e, outArg)
    outLst = res <| outLst
  end
  outLst = listReverseInPlace(outLst)
  (outArg, outLst)
end

#= Takes a list of lists, an extra argument, and a function.  The function will
be applied to each element in the list, and the extra argument will be passed
to the function and updated for each element. =#
function mapFoldLst(inLstLst::Lst, inFunc::FuncType, inArg::FT)::Tuple{FT, Lst}
  TI = Any ,TO = Any ,FT = Any
  local outArg::FT = inArg
  local outLstLst::Lst = list()

  local res::Lst

  for lst in inLstLst
    res, outArg = mapFold(lst, inFunc, outArg)
    outLstLst = res <| outLstLst
  end
  outLstLst = listReverseInPlace(outLstLst)
  (outArg, outLstLst)
end

#= Takes a list of lists, an extra argument, and a function.  The function will
be applied to each element in the list, and the extra argument will be passed
to the function and updated for each element. =#
function map3FoldLst(inLstLst::Lst, inFunc::FuncType, inConstArg1::ArgT1, inConstArg2::ArgT2, inConstArg3::ArgT3, inArg::FT)::Tuple{FT, Lst}
  TI = Any ,TO = Any ,FT = Any ,ArgT1 = Any ,ArgT2 = Any ,ArgT3 = Any
  local outArg::FT = inArg
  local outLstLst::Lst = list()

  local res::Lst

  for lst in inLstLst
    res, outArg = map3Fold(lst, inFunc, inConstArg1, inConstArg2, inConstArg3, inArg)
    outLstLst = res <| outLstLst
  end
  outLstLst = listReverseInPlace(outLstLst)
  (outArg, outLstLst)
end

#= Takes a list of lists, an extra argument and a function. The function will be
applied to each element in the list, and the extra argument will be passed to
the function and updated. The input and outputs of the function are joined as
tuples. =#
function mapFoldLstTuple(inLstLst::Lst, inFunc::FuncType, inFoldArg::TO)::Tuple{TO, Lst}
  TI = Any ,TO = Any ,FT = Any
  local outFoldArg::TO = inFoldArg
  local outLstLst::Lst = list()

  local res::Lst

  for lst in inLstLst
    res, outFoldArg = mapFoldTuple(lst, inFunc, outFoldArg)
    outLstLst = res <| outLstLst
  end
  outLstLst = listReverseInPlace(outLstLst)
  (outFoldArg, outLstLst)
end

#= Takes a value and a function operating on the value n times.
Example: foldcallN(1, intAdd, 4) => 4 =#
function foldcallN(n::ModelicaInteger, inFoldFunc::FoldFunc, inStartValue::FT)::FT
  FT = Any
  local outResult::FT = inStartValue

  for i in 1:n
    outResult = inFoldFunc(outResult)
  end
  outResult
end

#= Takes a list and a function operating on two elements of the list.
The function performs a reduction of the list to a single value using the
function. Example:
reduce({1, 2, 3}, intAdd) => 6 =#
function reduce(inLst::Lst, inReduceFunc::ReduceFunc)::T
  T = Any
  local outResult::T

  local rest::Lst

  outResult, rest = listHead(inLst), listRest(inLst)
  for e in rest
    outResult = inReduceFunc(outResult, e)
  end
  outResult
end

#= Takes a list and a function operating on two elements of the list.
The function performs a reduction of the list to a single value using the
function. This function also takes an extra argument that is sent to the
reduction function. =#
function reduce1(inLst::Lst, inReduceFunc::ReduceFunc, inExtraArg1::ArgT1)::T
  T = Any ,ArgT1 = Any
  local outResult::T

  local rest::Lst

  outResult, rest = listHead(inLst), listRest(inLst)
  for e in rest
    outResult = inReduceFunc(outResult, e, inExtraArg1)
  end
  outResult
end

#= Takes a list of lists and flattens it out, producing one list of all elements
of the sublists. O(len(outLst))
Example: flatten({{1, 2}, {3, 4, 5}, {6}, {}}) => {1, 2, 3, 4, 5, 6} =#
function flatten(inLst::Lst)::Lst
  T = Any
  local outLst::Lst = listAppend(lst for lst in listReverse(inLst))
  outLst
end

function flattenReverse(inLst::Lst)::Lst
  T = Any
  local outLst::Lst = listAppend(lst for lst in inLst)
  outLst
end

#= Takes two lists of the same type and threads (interleaves) them together.
Example: thread({1, 2, 3}, {4, 5, 6}) => {4, 1, 5, 2, 6, 3} =#
function thread(inLst1::Lst, inLst2::Lst, inAccum::Lst)::Lst
  T = Any
  local outLst::Lst = list()

  local e2::T
  local rest_e2::Lst = inLst2

  for e1 in inLst1
    e2, rest_e2 = listHead(rest_e2), listRest(rest_e2)
    outLst = e1 <| e2 <| outLst
  end
  @assert true == (listEmpty(rest_e2))
  outLst = listReverseInPlace(outLst)
  outLst
end

#= Takes three lists of the same type and threads (interleaves) them together.
Example: thread({1, 2, 3}, {4, 5, 6}, {7, 8, 9}) =>
{7, 4, 1, 8, 5, 2, 9, 6, 3} =#
function thread3(inLst1::Lst, inLst2::Lst, inLst3::Lst)::Lst
  T = Any
  local outLst::Lst = list()

  local e2::T
  local e3::T
  local rest_e2::Lst = inLst2
  local rest_e3::Lst = inLst3

  for e1 in inLst1
    e2, rest_e2 = listHead(rest_e2), listRest(rest_e2)
    e3, rest_e3 = listHead(rest_e3), listRest(rest_e3)
    outLst = e1 <| e2 <| e3 <| outLst
  end
  @assert true == (listEmpty(rest_e2))
  @assert true == (listEmpty(rest_e3))
  outLst = listReverseInPlace(outLst)
  outLst
end

#= Takes two lists and threads (interleaves) the arguments into a list of tuples
consisting of the two element types.
Example: threadTuple({1, 2, 3}, {true, false, true}) =>
{(1, true), (2, false), (3, true)} =#
function threadTuple(inLst1::Lst, inLst2::Lst)::Lst
  T1 = Any ,T2 = Any
  local outTuples::Lst

  outTuples = list(@do_threaded_for e1, e2 (e1, e2) (inLst1, inLst2))
  outTuples
end

#= Takes a list of two-element tuples and splits the tuples into two separate
lists. Example: unzip({(1, 2), (3, 4)}) => ({1, 3}, {2, 4}) =#
function unzip(inTuples::Lst)::Tuple{Lst, Lst}
  T1 = Any ,T2 = Any
  local outLst2::Lst = list()
  local outLst1::Lst = list()

  local e1::T1
  local e2::T2

  for tpl in inTuples
    e1, e2 = tpl
    outLst1 = e1 <| outLst1
    outLst2 = e2 <| outLst2
  end
  outLst1 = listReverseInPlace(outLst1)
  outLst2 = listReverseInPlace(outLst2)
  (outLst2, outLst1)
end

#= Like unzip, but returns the lists in reverse order. =#
function unzipReverse(inTuples::Lst)::Tuple{Lst, Lst}
  T1 = Any ,T2 = Any
  local outLst2::Lst = list()
  local outLst1::Lst = list()

  local e1::T1
  local e2::T2

  for tpl in inTuples
    e1, e2 = tpl
    outLst1 = e1 <| outLst1
    outLst2 = e2 <| outLst2
  end
  (outLst2, outLst1)
end

#= Takes a list of two-element tuples and creates a list from the first element
of each tuple. Example: unzipFirst({(1, 2), (3, 4)}) => {1, 3} =#
function unzipFirst(inTuples::Lst)::Lst
  T1 = Any ,T2 = Any
  local outLst::Lst = list()

  local e::T1

  for tpl in inTuples
    e, _ = tpl
    outLst = e <| outLst
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= Takes a list of two-element tuples and creates a list from the second element
of each tuple. Example: unzipFirst({(1, 2), (3, 4)}) => {2, 4} =#
function unzipSecond(inTuples::Lst)::Lst
  T1 = Any ,T2 = Any
  local outLst::Lst = list()

  local e::T2

  for tpl in inTuples
    _, e = tpl
    outLst = e <| outLst
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= Takes three lists and threads (interleaves) the arguments into a list of tuples
consisting of the three element types. =#
function thread3Tuple(inLst1::Lst, inLst2::Lst, inLst3::Lst)::Lst
  T1 = Any ,T2 = Any ,T3 = Any
  local outTuples::Lst

  outTuples = list(@do_threaded_for e1, e2, e3 (e1, e2, e3) (inLst1, inLst2, inLst3))
  outTuples
end

#= Takes three lists and threads (interleaves) the arguments into a list of tuples
consisting of the four element types. =#
function thread4Tuple(inLst1::Lst, inLst2::Lst, inLst3::Lst, inLst4::Lst)::Lst
  T1 = Any ,T2 = Any ,T3 = Any ,T4 = Any
  local outTuples::Lst

  outTuples = list(@do_threaded_for e1, e2, e3, e4 (e1, e2, e3, e4) (inLst1, inLst2, inLst3, inLst4))
  outTuples
end

#= Takes three lists and threads (interleaves) the arguments into a list of tuples
consisting of the five element types. =#
function thread5Tuple(inLst1::Lst, inLst2::Lst, inLst3::Lst, inLst4::Lst, inLst5::Lst)::Lst
  T1 = Any ,T2 = Any ,T3 = Any ,T4 = Any ,T5 = Any
  local outTuples::Lst

  outTuples = list(@do_threaded_for e1, e2, e3, e4, e5 (e1, e2, e3, e4, e5) (inLst1, inLst2, inLst3, inLst4, inLst5))
  outTuples
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list.
Example: threadMap({1, 2}, {3, 4}, intAdd) => {1+3, 2+4} =#
function threadMap(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc)::Lst
  T1 = Any ,T2 = Any ,TO = Any
  local outLst::Lst

  outLst = list(@do_threaded_for inMapFunc(e1, e2) (e1, e2) (inLst1, inLst2))
  outLst
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. The order of the result list
will be reversed compared to the input lists.
Example: threadMap({1, 2}, {3, 4}, intAdd) => {2+4, 1+3} =#
function threadMapReverse(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc)::Lst
  T1 = Any ,T2 = Any ,TO = Any
  local outLst::Lst

  outLst = listReverse(@do_threaded_for inMapFunc(e1, e2) (e1, e2) (inLst1, inLst2))
  outLst
end

#= Like threadMap, but returns two lists instead of one. =#
function threadMap_2(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc)::Tuple{Lst, Lst}
  T1 = Any ,T2 = Any ,TO1 = Any ,TO2 = Any
  local outLst2::Lst = list()
  local outLst1::Lst = list()

  local e2::T2
  local rest_e2::Lst = inLst2
  local ret1::TO1
  local ret2::TO2

  for e1 in inLst1
    e2, rest_e2 = listHead(rest_e2), listRest(rest_e2)
    ret1, ret2 = inMapFunc(e1, e2)
    outLst1 = ret1 <| outLst1
    outLst2 = ret2 <| outLst2
  end
  outLst1 = listReverseInPlace(outLst1)
  outLst2 = listReverseInPlace(outLst2)
  (outLst2, outLst1)
end

#= Takes two lists of lists and a function and threads (interleaves) and maps
the elements of the two lists, creating a new list.
Example: threadMapLst({{1, 2}}, {{3, 4}}, intAdd) => {{1 + 3, 2 + 4}} =#
function threadMapLst(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc)::Lst
  T1 = Any ,T2 = Any ,TO = Any
  local outLst::Lst

  outLst = list(@do_threaded_for threadMap(lst1, lst2, inMapFunc) (lst1, lst2) (inLst1, inLst2))
  outLst
end

#= Like threadMapLst, but returns two lists instead of one. =#
function threadMapLst_2(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc)::Tuple{Lst, Lst}
  T1 = Any ,T2 = Any ,TO1 = Any ,TO2 = Any
  local outLst2::Lst = list()
  local outLst1::Lst = list()

  local l2::Lst
  local rest_l2::Lst = inLst2
  local ret1::Lst
  local ret2::Lst

  for l1 in inLst1
    l2, rest_l2 = listHead(rest_l2), listRest(rest_l2)
    ret1, ret2 = threadMap_2(l1, l2, inMapFunc)
    outLst1 = ret1 <| outLst1
    outLst2 = ret2 <| outLst2
  end
  outLst1 = listReverseInPlace(outLst1)
  outLst2 = listReverseInPlace(outLst2)
  (outLst2, outLst1)
end

#= Takes two lists of lists as arguments and produces a list of lists of a two
tuple of the element types of each list.
Example: threadTupleLst({{1}, {2, 3}}, {{'a'}, {'b', 'c'}}) =>
{{(1, 'a')}, {(2, 'b'), (3, 'c')}} =#
function threadTupleLst(inLst1::Lst, inLst2::Lst)::Lst
  T1 = Any ,T2 = Any
  local outLst::Lst

  outLst = list(@do_threaded_for threadTuple(lst1, lst2) (lst1, lst2) (inLst1, inLst2))
  outLst
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, and checks if the result is the same as the given
value.
Example: threadMapAllValue({true, true}, {false, true}, boolAnd, true) =>
fail =#
function threadMapAllValue(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc, inValue::VT)
  T1 = Any ,T2 = Any ,TO = Any ,VT = Any
  println("threadMapAllValue Fixme..")
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes an
extra arguments that are passed to the mapping function. =#
function threadMap1(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc, inArg1::ArgT1)::Lst
  T1 = Any ,T2 = Any ,TO = Any ,ArgT1 = Any
  local outLst::Lst

  outLst = list(@do_threaded_for inMapFunc(e1, e2, inArg1) (e1, e2) (inLst1, inLst2))
  outLst
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes an
extra arguments that are passed to the mapping function. The order of the
result list will be reversed compared to the input lists. =#
function threadMap1Reverse(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc, inArg1::ArgT1)::Lst
  T1 = Any ,T2 = Any ,TO = Any ,ArgT1 = Any
  local outLst::Lst

  outLst = listReverse(@do_threaded_for inMapFunc(e1, e2, inArg1) (e1, e2) (inLst1, inLst2))
  outLst
end

#= Takes two lists and a function, and applies the function to each element of
the lists in a pairwise fashion. This function also takes an extra argument
which is passed to the mapping function, but returns no result. =#
function threadMap1_0(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc, inArg1::ArgT1)
  printl("threadMap1_0, fixme")
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes two
extra arguments that are passed to the mapping function. =#
function threadMap2(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)::Lst
  T1 = Any ,T2 = Any ,TO = Any ,ArgT1 = Any ,ArgT2 = Any
  local outLst::Lst

  outLst = list(@do_threaded_for inMapFunc(e1, e2, inArg1, inArg2) (e1, e2) (inLst1, inLst2))
  outLst
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes two
extra arguments that are passed to the mapping function. The order of the
result list will be reversed compared to the input lists. =#
function threadMap2Reverse(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)::Lst
  T1 = Any ,T2 = Any ,TO = Any ,ArgT1 = Any ,ArgT2 = Any
  local outLst::Lst

  outLst = listReverse(@do_threaded_for inMapFunc(e1, e2, inArg1, inArg2) (e1, e2) (inLst1, inLst2))
  outLst
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes two
extra arguments and a fold argument that are passed to the mapping function.
The order of the result list will be reversed compared to the input lists. =#
function threadMap2ReverseFold(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inFoldArg::FT, inAccum::Lst)::Tuple{FT, Lst}
  T1 = Any ,T2 = Any ,TO = Any ,FT = Any ,ArgT1 = Any ,ArgT2 = Any
  local outFoldArg::FT
  local outLst::Lst

  outLst, outFoldArg = begin
    local e1::T1
    local rest1::Lst
    local e2::T2
    local rest2::Lst
    local res::TO
    local foldArg::FT
    @match inLst1, inLst2 begin
      ( nil(),  nil())  => begin
        inAccum, inFoldArg
      end

      (e1 <| rest1, e2 <| rest2)  => begin
        res, foldArg = inMapFunc(e1, e2, inArg1, inArg2, inFoldArg)
        outLst, foldArg = threadMap2ReverseFold(rest1, rest2, inMapFunc, inArg1, inArg2, foldArg, res <| inAccum)
        outLst, foldArg
      end
    end
  end
  (outFoldArg, outLst)
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes three
extra arguments that are passed to the mapping function. =#
function threadMap3(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)::Lst
  T1 = Any ,T2 = Any ,TO = Any ,ArgT1 = Any ,ArgT2 = Any ,ArgT3 = Any
  local outLst::Lst

  outLst = list(@do_threaded_for inMapFunc(e1, e2, inArg1, inArg2, inArg3) (e1, e2) (inLst1, inLst2))
  outLst
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes three
extra arguments that are passed to the mapping function. =#
function threadMap3Reverse(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)::Lst
  T1 = Any ,T2 = Any ,TO = Any ,ArgT1 = Any ,ArgT2 = Any ,ArgT3 = Any
  local outLst::Lst

  outLst = listReverse(@do_threaded_for inMapFunc(e1, e2, inArg1, inArg2, inArg3) (e1, e2) (inLst1, inLst2))
  outLst
end

#= Takes three lists and a function, and threads (interleaves) and maps the
elements of the three lists, creating a new list.
Example: thread3Map({1, 2}, {3, 4}, {5, 6}, intAdd3) => {1+3+5, 2+4+6} =#
function thread3Map(inLst1::Lst, inLst2::Lst, inLst3::Lst, inFunc::MapFunc)::Lst
  T1 = Any ,T2 = Any ,T3 = Any ,TO = Any
  local outLst::Lst

  outLst = list(@do_threaded_for inFunc(e1, e2, e3) (e1, e2, e3) (inLst1, inLst2, inLst3))
  outLst
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes three
extra arguments and a fold argument that are passed to the mapping function.
The order of the result list will be reversed compared to the input lists. =#
function threadMap3ReverseFold(inLst1::Lst, inLst2::Lst, inMapFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inFoldArg::FT, inAccum::Lst)::Tuple{FT, Lst}
  T1 = Any ,T2 = Any ,TO = Any ,FT = Any ,ArgT1 = Any ,ArgT2 = Any ,ArgT3 = Any
  local outFoldArg::FT
  local outLst::Lst

  outLst, outFoldArg = begin
    local e1::T1
    local rest1::Lst
    local e2::T2
    local rest2::Lst
    local res::TO
    local foldArg::FT
    @match inLst1, inLst2 begin
      (e1 <| rest1, e2 <| rest2)  => begin
        res, foldArg = inMapFunc(e1, e2, inArg1, inArg2, inArg3, inFoldArg)
        outLst, foldArg = threadMap3ReverseFold(rest1, rest2, inMapFunc, inArg1, inArg2, inArg3, foldArg, res <| inAccum)
        outLst, foldArg
      end

      ( nil(),  nil())  => begin
        inAccum, inFoldArg
      end
    end
  end
  (outFoldArg, outLst)
end

#= Takes three lists and a function, and threads (interleaves) and maps the
elements of the three lists, creating two new list.
Example: thread3Map({1, 2}, {3, 4}, {5, 6}, intAddSub3) =>
({1+3+5, 2+4+6}, {1-3-5, 2-4-6}) =#
function thread3Map_2(inLst1::Lst, inLst2::Lst, inLst3::Lst, inFunc::MapFunc)::Tuple{Lst, Lst}
  T1 = Any ,T2 = Any ,T3 = Any ,TO1 = Any ,TO2 = Any
  local outLst2::Lst = list()
  local outLst1::Lst = list()

  local e2::T2
  local rest_e2::Lst = inLst2
  local e3::T3
  local rest_e3::Lst = inLst3
  local res1::TO1
  local res2::TO2

  for e1 in inLst1
    e2, rest_e2 = listHead(rest_e2), listRest(rest_e2)
    e3, rest_e3 = listHead(rest_e3), listRest(rest_e3)
    res1, res2 = inFunc(e1, e2, e3)
    outLst1 = res1 <| outLst1
    outLst2 = res2 <| outLst2
  end
  @assert true == (listEmpty(rest_e2))
  @assert true == (listEmpty(rest_e3))
  outLst1 = listReverseInPlace(outLst1)
  outLst2 = listReverseInPlace(outLst2)
  (outLst2, outLst1)
end

#= Takes three lists and a function, and threads (interleaves) and maps the
elements of the three lists, creating a new list. This function also takes
one extra argument which are passed to the mapping function and fold. =#
function thread3MapFold(inLst1::Lst, inLst2::Lst, inLst3::Lst, inFunc::MapFunc, inArg::ArgT1)::Tuple{ArgT1, Lst}
  T1 = Any ,T2 = Any ,T3 = Any ,TO = Any ,ArgT1 = Any
  local outArg::ArgT1 = inArg
  local outLst::Lst = list()

  local e2::T2
  local rest_e2::Lst = inLst2
  local e3::T3
  local rest_e3::Lst = inLst3
  local res::TO

  for e1 in inLst1
    e2, rest_e2 = listHead(rest_e2), listRest(rest_e2)
    e3, rest_e3 = listHead(rest_e3), listRest(rest_e3)
    res, outArg = inFunc(e1, e2, e3, outArg)
    outLst = res <| outLst
  end
  @assert true == (listEmpty(rest_e2))
  @assert true == (listEmpty(rest_e3))
  outLst = listReverseInPlace(outLst)
  (outArg, outLst)
end

#= Takes three lists and a function, and threads (interleaves) and maps the
elements of the three lists, creating a new list. This function also takes
three extra arguments which are passed to the mapping function. =#
function thread3Map3(inLst1::Lst, inLst2::Lst, inLst3::Lst, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)::Lst
  T1 = Any ,T2 = Any ,T3 = Any ,TO = Any ,ArgT1 = Any ,ArgT2 = Any ,ArgT3 = Any
  local outLst::Lst

  outLst = list(@do_threaded_for inFunc(e1, e2, e3, inArg1, inArg2, inArg3) (e1, e2, e3) (inLst1, inLst2, inLst3))
  outLst
end

#= This is a combination of thread and fold that applies a function to the head
of two lists with an extra argument that is updated and passed on. This
function also takes an extra constant argument that is passed to the function. =#
function threadFold1(inLst1::Lst, inLst2::Lst, inFoldFunc::FoldFunc, inArg1::ArgT1, inFoldArg::FT)::FT
  T1 = Any ,T2 = Any ,FT = Any ,ArgT1 = Any
  local outFoldArg::FT

  outFoldArg = begin
    local e1::T1
    local rest1::Lst
    local e2::T2
    local rest2::Lst
    local res::FT
    @match inLst1, inLst2 begin
      (e1 <| rest1, e2 <| rest2)  => begin
        res = inFoldFunc(e1, e2, inArg1, inFoldArg)
        threadFold1(rest1, rest2, inFoldFunc, inArg1, res)
      end

      ( nil(),  nil())  => begin
        inFoldArg
      end
    end
  end
  outFoldArg
end

#= This is a combination of thread and fold that applies a function to the head
of two lists with an extra argument that is updated and passed on. This
function also takes two extra constant arguments that is passed to the function. =#
function threadFold2(inLst1::Lst, inLst2::Lst, inFoldFunc::FoldFunc, inArg1::ArgT1, inArg2::ArgT2, inFoldArg::FT)::FT
  T1 = Any ,T2 = Any ,FT = Any ,ArgT1 = Any ,ArgT2 = Any
  local outFoldArg::FT

  outFoldArg = begin
    local e1::T1
    local rest1::Lst
    local e2::T2
    local rest2::Lst
    local res::FT
    @match inLst1, inLst2 begin
      (e1 <| rest1, e2 <| rest2)  => begin
        res = inFoldFunc(e1, e2, inArg1, inArg2, inFoldArg)
        threadFold2(rest1, rest2, inFoldFunc, inArg1, inArg2, res)
      end

      ( nil(),  nil())  => begin
        inFoldArg
      end
    end
  end
  outFoldArg
end

#= This is a combination of thread and fold that applies a function to the head
of two lists with an extra argument that is updated and passed on. This
function also takes three extra constant arguments that is passed to the function. =#
function threadFold3(inLst1::Lst, inLst2::Lst, inFoldFunc::FoldFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inFoldArg::FT)::FT
  T1 = Any ,T2 = Any ,FT = Any ,ArgT1 = Any ,ArgT2 = Any ,ArgT3 = Any
  local outFoldArg::FT

  outFoldArg = begin
    local e1::T1
    local rest1::Lst
    local e2::T2
    local rest2::Lst
    local res::FT
    @match inLst1, inLst2 begin
      (e1 <| rest1, e2 <| rest2)  => begin
        res = inFoldFunc(e1, e2, inArg1, inArg2, inArg3, inFoldArg)
        threadFold3(rest1, rest2, inFoldFunc, inArg1, inArg2, inArg3, res)
      end

      ( nil(),  nil())  => begin
        inFoldArg
      end
    end
  end
  outFoldArg
end

#= This is a combination of thread and fold that applies a function to the head
of two lists with an extra argument that is updated and passed on. This
function also takes four extra constant arguments that is passed to the function. =#
function threadFold4(inLst1::Lst, inLst2::Lst, inFoldFunc::FoldFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inFoldArg::FT)::FT
  T1 = Any ,T2 = Any ,FT = Any ,ArgT1 = Any ,ArgT2 = Any ,ArgT3 = Any ,ArgT4 = Any
  local outFoldArg::FT

  outFoldArg = begin
    local e1::T1
    local rest1::Lst
    local e2::T2
    local rest2::Lst
    local res::FT
    @match inLst1, inLst2 begin
      (e1 <| rest1, e2 <| rest2)  => begin
        res = inFoldFunc(e1, e2, inArg1, inArg2, inArg3, inArg4, inFoldArg)
        threadFold4(rest1, rest2, inFoldFunc, inArg1, inArg2, inArg3, inArg4, res)
      end

      ( nil(),  nil())  => begin
        inFoldArg
      end
    end
  end
  outFoldArg
end

#= This is a combination of thread and fold that applies a function to the head
of two lists with an extra argument that is updated and passed on. =#
function threadFold(inLst1::Lst, inLst2::Lst, inFoldFunc::FoldFunc, inFoldArg::FT)::FT
  T1 = Any ,T2 = Any ,FT = Any
  local outFoldArg::FT

  outFoldArg = begin
    local e1::T1
    local rest1::Lst
    local e2::T2
    local rest2::Lst
    local res::FT
    @match inLst1, inLst2 begin
      (e1 <| rest1, e2 <| rest2)  => begin
        res = inFoldFunc(e1, e2, inFoldArg)
        threadFold(rest1, rest2, inFoldFunc, res)
      end

      ( nil(),  nil())  => begin
        inFoldArg
      end
    end
  end
  outFoldArg
end

#= Takes a list, an extra argument and a function. The function will be applied
to each element in the list, and the extra argument will be passed to the
function and updated. =#
function threadMapFold(inLst1::Lst, inLst2::Lst, inFunc::FuncType, inArg::FT)::Tuple{FT, Lst}
  T1 = Any ,T2 = Any ,TO = Any ,FT = Any
  local outArg::FT = inArg
  local outLst::Lst = list()

  local e2::T2
  local rest_e2::Lst = inLst2
  local res::TO

  for e1 in inLst1
    e2, rest_e2 = listHead(rest_e2), listRest(rest_e2)
    res, outArg = inFunc(e1, e2, outArg)
    outLst = res <| outLst
  end
  @assert true == (listEmpty(rest_e2))
  outLst = listReverseInPlace(outLst)
  (outArg, outLst)
end

#= Takes a value and a list, and returns the position of the first list element
that whose value is equal to the given value.
Example: position(2, {0, 1, 2, 3}) => 3 =#
function position(inElement::T, inLst::Lst)::ModelicaInteger
  T = Any
  local outPosition::ModelicaInteger = 1 #= one-based index =#

  for e in inLst
    if valueEq(e, inElement)
      return outPosition #= one-based index =#
    end
    outPosition = outPosition + 1
  end
  fail()
  outPosition #= one-based index =#
end

#= Takes a list and a predicate function, and returns the index of the first
element for which the function returns true, or -1 if no match is found. =#
function positionOnTrue(inLst::Lst, inPredFunc::PredFunc)::ModelicaInteger
  T = Any
  local outPosition::ModelicaInteger = 1

  for e in inLst
    if inPredFunc(e)
      return outPosition
    end
    outPosition = outPosition + 1
  end
  outPosition = -1
  outPosition
end

#= Takes a list, a predicate function and an extra argument, and return the
index of the first element for which the function returns true, or -1 if no
match is found. The extra argument is passed to the predicate function for
each call. =#
function position1OnTrue(inLst::Lst, inPredFunc::PredFunc, inArg::ArgT)::ModelicaInteger
  T = Any ,ArgT = Any
  local outPosition::ModelicaInteger = 1

  for e in inLst
    if inPredFunc(e, inArg)
      return outPosition
    end
    outPosition = outPosition + 1
  end
  outPosition = -1
  outPosition
end

#= Takes a value and a list of lists, and returns the position of the value.
outLstIndex is the index of the list the value was found in, and outPosition
is the position in that list.
Example: positionLst(3, {{4, 2}, {6, 4, 3, 1}}) => (2, 3) =#
function positionLst(inElement::T, inLst::Lst)::Tuple{ModelicaInteger, ModelicaInteger}
  T = Any
  local outPosition::ModelicaInteger #= one-based index =#
  local outLstIndex::ModelicaInteger = 1 #= one-based index =#

  for lst in inLst
    outPosition = 1
    for e in lst
      if valueEq(e, inElement)
        return (outPosition #= one-based index =#, outLstIndex #= one-based index =#)
      end
      outPosition = outPosition + 1
    end
    outLstIndex = outLstIndex + 1
  end
  fail()
  (outPosition #= one-based index =#, outLstIndex #= one-based index =#)
end

#= Takes a value and a list, and returns the value if it's present in the list.
If not present the function will fail.
Example: listGetMember(0, {1, 2, 3}) => fail
listGetMember(1, {1, 2, 3}) => 1 =#
function getMember(inElement::T, inLst::Lst)::T
  T = Any
  local outElement::T

  local e::T
  local res::T
  local rest::Lst

  for e in inLst
    if valueEq(inElement, e)
      outElement = e
      return outElement
    end
  end
  fail()
  outElement
end

#= Takes a value and a list of values and a comparison function over two values.
If the value is present in the list (using the comparison function returning
true) the value is returned, otherwise the function fails.
Example:
function equalLength(string,string) returns true if the strings are of same length
getMemberOnTrue(\\\"a\\\",{\\\"bb\\\",\\\"b\\\",\\\"ccc\\\"},equalLength) => \\\"b\\\" =#
function getMemberOnTrue(inValue::VT, inLst::Lst, inCompFunc::CompFunc)::T
  T = Any ,VT = Any
  local outElement::T

  for e in inLst
    if inCompFunc(inValue, e)
      outElement = e
      return outElement
    end
  end
  fail()
  outElement
end

#= Returns true if a list does not contain the given element, otherwise false. =#
function notMember(inElement::T, inLst::Lst)::Bool
  T = Any
  local outIsNotMember::Bool

  outIsNotMember = ! listMember(inElement, inLst)
  outIsNotMember
end

#= Returns true if the given value is a member of the list, as determined by the
comparison function given. =#
function isMemberOnTrue(inValue::VT, inLst::Lst, inCompFunc::CompFunc)::Bool
  T = Any ,VT = Any
  local outIsMember::Bool

  for e in inLst
    if inCompFunc(inValue, e)
      outIsMember = true
      return outIsMember
    end
  end
  outIsMember = false
  outIsMember
end

#= Returns true if a certain element exists in the given list as indicated by
the given predicate function.
Example:
exist({1,2}, isEven) => true
exist({1,3,5,7}, isEven) => false =#
function exist(inLst::Lst, inFindFunc::FindFunc)::Bool
  T = Any
  local outExists::Bool

  for e in inLst
    if inFindFunc(e)
      outExists = true
      return outExists
    end
  end
  outExists = false
  outExists
end

#= Returns true if a certain element exists in the given list as indicated by
the given predicate function. Also takes an extra argument that is passed to
the predicate function. =#
function exist1(inLst::Lst, inFindFunc::FindFunc, inExtraArg::ArgT1)::Bool
  T = Any ,ArgT1 = Any
  local outExists::Bool

  for e in inLst
    if inFindFunc(e, inExtraArg)
      outExists = true
      return outExists
    end
  end
  outExists = false
  outExists
end

#= Returns true if a certain element exists in the given list as indicated by
the given predicate function. Also takes two extra arguments that is passed
to the predicate function. =#
function exist2(inLst::Lst, inFindFunc::FindFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2)::Bool
  T = Any ,ArgT1 = Any ,ArgT2 = Any
  local outExists::Bool

  for e in inLst
    if inFindFunc(e, inExtraArg1, inExtraArg2)
      outExists = true
      return outExists
    end
  end
  outExists = false
  outExists
end

#= Takes a list of values and a filter function over the values and returns
two lists. One of values for which the matching function returns true and the
other containing the remaining elements.
Example:
extractOnTrue({1, 2, 3, 4, 5}, isEven) => {2, 4}, {1, 3, 5} =#
function extractOnTrue(inLst::Lst, inFilterFunc::FilterFunc)::Tuple{Lst, Lst}
  T = Any
  local outRemainingLst::Lst = list()
  local outExtractedLst::Lst = list()

  for e in inLst
    if inFilterFunc(e)
      outExtractedLst = e <| outExtractedLst
    else
      outRemainingLst = e <| outRemainingLst
    end
  end
  outExtractedLst = listReverseInPlace(outExtractedLst)
  outRemainingLst = listReverseInPlace(outRemainingLst)
  (outRemainingLst, outExtractedLst)
end

#= Takes a list of values and a filter function over the values and an extra
argument and returns two lists. One of values for which the matching function
returns true and the other containing the remaining elements. =#
function extract1OnTrue(inLst::Lst, inFilterFunc::FilterFunc, inArg::ArgT1)::Tuple{Lst, Lst}
  T = Any ,ArgT1 = Any
  local outRemainingLst::Lst = list()
  local outExtractedLst::Lst = list()

  for e in inLst
    if inFilterFunc(e, inArg)
      outExtractedLst = e <| outExtractedLst
    else
      outRemainingLst = e <| outRemainingLst
    end
  end
  outExtractedLst = listReverseInPlace(outExtractedLst)
  outRemainingLst = listReverseInPlace(outRemainingLst)
  (outRemainingLst, outExtractedLst)
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values for which the matching function succeeds.
Example:
filter({1, 2, 3, 4, 5}, isEven) => {2, 4} =#
function filter(inLst::Lst, inFilterFunc::FilterFunc)::Lst
  T = Any
  local outLst::Lst = list()

  for e in inLst
    try
      inFilterFunc(e)
      outLst = e <| outLst
    catch
    end
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= Applies a function to each element in the given list, but also filters out
all elements for which the function fails. =#
function filterMap(inLst::Lst, inFilterMapFunc::FilterMapFunc)::Lst
  TI = Any ,TO = Any
  local outLst::Lst = list()

  local oe::TO

  for e in inLst
    try
      oe = inFilterMapFunc(e)
      outLst = oe <| outLst
    catch
    end
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= Applies a function to each element in the given list, but also filters out
all elements for which the function fails. =#
function filterMap1(inLst::Lst, inFilterMapFunc::FilterMapFunc, inExtraArg::ArgT1)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any
  local outLst::Lst = list()

  local oe::TO

  for e in inLst
    try
      oe = inFilterMapFunc(e, inExtraArg)
      outLst = oe <| outLst
    catch
    end
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values for which the matching function returns true.
Example:
filter({1, 2, 3, 4, 5}, isEven) => {2, 4} =#
function filterOnTrue(inLst::Lst, inFilterFunc::FilterFunc)::Lst
  T = Any
  local outLst::Lst

  outLst = list(e for e in inLst if inFilterFunc(e))
  outLst
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values for which the matching function returns false.
Example:
filterOnFalse({1, 2, 3, 1, 5}, isEven) => {1, 3, 1, 5} =#
function filterOnFalse(inLst::Lst, inFilterFunc::FilterFunc)::Lst
  T = Any
  local outLst::Lst

  outLst = list(e for e in inLst if boolNot(inFilterFunc(e)))
  outLst
end

#= like filterOnTrue but performs the same filtering synchronously on a second list.
Takes 2 list of values and a filter function and an extra argument over the values of the first list and returns a
sub list of values for both lists for which the matching function returns true for the first list.
Example:
filter({1, 2, 3, 4, 5}, isEven) => {2, 4} =#
function filter1OnTrueSync(inLst::Lst, inFilterFunc::FilterFunc, inArg1::ArgT1, inSyncLst::Lst)::Tuple{Lst, Lst}
  T1 = Any ,T2 = Any ,ArgT1 = Any
  local outLst_b::Lst = list()
  local outLst_a::Lst = list()

  local e2::T2
  local rest2::Lst = inSyncLst

  for e1 in inLst
    e2, rest2 = listHead(rest2), listRest(rest2)
    if inFilterFunc(e1, inArg1)
      outLst_a = e1 <| outLst_a
      outLst_b = e2 <| outLst_b
    end
  end
  outLst_a = listReverseInPlace(outLst_a)
  outLst_b = listReverseInPlace(outLst_b)
  (outLst_b, outLst_a)
end

#= Like filterOnTrue but performs the same filtering synchronously on a second list.
Takes 2 list of values and a filter function over the values of the first
list and returns a sub list of values for both lists for which the matching
function returns true for the first list. =#
function filterOnTrueSync(inLst::Lst, inFilterFunc::FilterFunc, inSyncLst::Lst)::Tuple{Lst, Lst}
  T1 = Any ,T2 = Any
  local outLst_b::Lst = list()
  local outLst_a::Lst = list()

  local e2::T2
  local rest2::Lst = inSyncLst

  @assert true == (listLength(inLst) == listLength(inSyncLst))
  for e1 in inLst
    e2, rest2 = listHead(rest2), listRest(rest2)
    if inFilterFunc(e1)
      outLst_a = e1 <| outLst_a
      outLst_b = e2 <| outLst_b
    end
  end
  outLst_a = listReverseInPlace(outLst_a)
  outLst_b = listReverseInPlace(outLst_b)
  (outLst_b, outLst_a)
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values in reverse order for which the matching function returns true.
Example:
filter({1, 2, 3, 4, 5}, isEven) => {4, 2} =#
function filterOnTrueReverse(inLst::Lst, inFilterFunc::FilterFunc)::Lst
  T = Any
  local outLst::Lst

  outLst = listReverse(e for e in inLst if inFilterFunc(e))
  outLst
end

#= Takes a list of values, a filter function over the values and an extra
argument, and returns a sub list of values for which the matching function
succeeds.
Example:
filter({1, 2, 3, 4, 5}, isEven) => {2, 4} =#
function filter1(inLst::Lst, inFilterFunc::FilterFunc, inArg1::ArgT1)::Lst
  T = Any ,ArgT1 = Any
  local outLst::Lst = list()

  for e in inLst
    try
      inFilterFunc(e, inArg1)
      outLst = e <| outLst
    catch
    end
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values for which the matching function returns true.
Example:
filter1OnTrue({1, 2, 3, 1, 5}, intEq, 1) => {1, 1} =#
function filter1OnTrue(inLst::Lst, inFilterFunc::FilterFunc, inArg1::ArgT1)::Lst
  T = Any ,ArgT1 = Any
  local outLst::Lst

  outLst = list(e for e in inLst if inFilterFunc(e, inArg1))
  outLst
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values for which the matching function returns true. The
matching function may update the values.
Example:
filter1OnTrue({1, 2, 3, 1, 5}, intEq, 1) => {1, 1} =#
function filter1OnTrueAndUpdate(inLst::Lst, inFilterFunc::FilterFunc, inUpdateFunc::UpdateFunc, inArg1::ArgT1)::Lst
  T = Any ,ArgT1 = Any
  local outLst::Lst

  outLst = list(inUpdateFunc(e, inArg1) for e in inLst if inFilterFunc(e, inArg1))
  outLst
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values for which the matching function returns true.
Example:
filter1rOnTrue({1, 2, 3, 1, 5}, intEq, 1) => {1, 1} =#
function filter1rOnTrue(inLst::Lst, inFilterFunc::FilterFunc, inArg1::ArgT1)::Lst
  T = Any ,ArgT1 = Any
  local outLst::Lst

  outLst = list(e for e in inLst if inFilterFunc(inArg1, e))
  outLst
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values for which the matching function returns true. =#
function filter2OnTrue(inLst::Lst, inFilterFunc::FilterFunc, inArg1::ArgT1, inArg2::ArgT2)::Lst
  T = Any ,ArgT1 = Any ,ArgT2 = Any
  local outLst::Lst

  outLst = list(e for e in inLst if inFilterFunc(e, inArg1, inArg2))
  outLst
end

#= Goes through a list and removes all elements which are equal to the given
value, using the given comparison function. =#
function removeOnTrue(inValue::VT, inCompFunc::CompFunc, inLst::Lst)::Lst
  T = Any ,VT = Any
  local outLst::Lst

  outLst = list(e for e in inLst if ! inCompFunc(inValue, e))
  outLst
end

select = filterOnTrue

select1 = filter1OnTrue

select1r = filter1rOnTrue

select2 = filter2OnTrue

#= This function retrieves the first element of a list for which the passed
function evaluates to true. =#
function find(inLst::Lst, inFunc::SelectFunc)::T
  T = Any
  local outElement::T

  for e in inLst
    if inFunc(e)
      outElement = e
      return outElement
    end
  end
  fail()
  outElement
end

#= This function retrieves the first element of a list for which the passed
function evaluates to true. =#
function find1(inLst::Lst, inFunc::SelectFunc, arg1::ArgT1)::T
  T = Any ,ArgT1 = Any
  local outElement::T

  for e in inLst
    if inFunc(e, arg1)
      outElement = e
      return outElement
    end
  end
  fail()
  outElement
end

#= This function retrieves the first element of a list for which the passed
function evaluates to true. And returns the list with the element removed. =#
function findAndRemove(inLst::Lst, inFunc::SelectFunc)::Tuple{Lst, T}
  T = Any
  local rest::Lst
  local outElement::T

  local i::ModelicaInteger = 0
  local delst::DoubleEndedLst
  local t::T

  for e in inLst
    if inFunc(e)
      outElement = e
      delst = DoubleEndedLst.fromLst(list())
      rest = inLst
      for i in 1:i
        t, rest = listHead(rest), listRest(rest)
        DoubleEndedLst.push_back(delst, t)
      end
      _, rest = listHead(rest), listRest(rest)
      rest = DoubleEndedLst.toLstAndClear(delst, prependToLst = rest)
      return (rest, outElement)
    end
    i = i + 1
  end
  fail()
  (rest, outElement)
end

#= This function retrieves the first element of a list for which the passed
function evaluates to true. And returns the list with the element removed. =#
function findAndRemove1(inLst::Lst, inFunc::SelectFunc, arg1::ArgT1)::Tuple{Lst, T}
  T = Any ,ArgT1 = Any
  local rest::Lst
  local outElement::T

  local i::ModelicaInteger = 0
  local delst::DoubleEndedLst
  local t::T

  for e in inLst
    if inFunc(e, arg1)
      outElement = e
      delst = DoubleEndedLst.fromLst(list())
      rest = inLst
      for i in 1:i
        t, rest = listHead(rest), listRest(rest)
        DoubleEndedLst.push_back(delst, t)
      end
      _, rest = listHead(rest), listRest(rest)
      rest = DoubleEndedLst.toLstAndClear(delst, prependToLst = rest)
      return (rest, outElement)
    end
    i = i + 1
  end
  fail()
  (rest, outElement)
end

#= This function returns the first value in the given list for which the
corresponding element in the boolean list is true. =#
function findBoolLst(inBooleans::Lst, inLst::Lst, inFalseValue::T)::T
  T = Any
  local outElement::T

  local e::T
  local rest::Lst = inLst

  for b in inBooleans
    e, rest = listHead(rest), listRest(rest)
    if b
      outElement = e
      return outElement
    end
  end
  outElement = inFalseValue
  outElement
end

#= Takes a list and a value, and deletes the first occurence of the value in the
list. Example: deleteMember({1, 2, 3, 2}, 2) => {1, 3, 2} =#
function deleteMember(inLst::Lst, inElement::T)::Lst
  T = Any
  local outLst::Lst = list()

  local e::T
  local rest::Lst = inLst

  while ! listEmpty(rest)
    e, rest = listHead(rest), listRest(rest)
    if valueEq(e, inElement)
      outLst = append_reverse(outLst, rest)
      return outLst
    end
    outLst = e <| outLst
  end
  outLst = inLst
  outLst
end

#= Same as deleteMember, but fails if the element isn't present in the list. =#
function deleteMemberF(inLst::Lst, inElement::T)::Lst
  T = Any
  local outLst::Lst

  outLst = deleteMember(inLst, inElement)
  if referenceEq(outLst, inLst)
    fail()
  end
  outLst
end

#= Takes a list and a value and a comparison function and deletes the first
occurence of the value in the list for which the function returns true. It
returns the new list and the deleted element, or only the original list if
no element was removed.
Example: deleteMemberOnTrue({1,2,3,2},2,intEq) => {1,3,2} =#
function deleteMemberOnTrue(inValue::VT, inLst::Lst, inCompareFunc::CompareFunc)::Tuple{Option, Lst}
  T = Any ,VT = Any
  local outDeletedElement::Option = NONE()
  local outLst::Lst = inLst

  local e::T
  local rest::Lst = inLst
  local acc::Lst = list()

  while ! listEmpty(rest)
    e, rest = listHead(rest), listRest(rest)
    if inCompareFunc(inValue, e)
      outLst = append_reverse(acc, rest)
      outDeletedElement = SOME(e)
      return (outDeletedElement, outLst)
    end
    acc = e <| acc
  end
  (outDeletedElement, outLst)
end

#= Takes a list and a list of positions, and deletes the positions from the
list. Note that positions are indexed from 0.
Example: deletePositions({1, 2, 3, 4, 5}, {2, 0, 3}) => {2, 5} =#
function deletePositions(inLst::Lst, inPositions::Lst)::Lst
  T = Any
  local outLst::Lst

  local sorted_pos::Lst

  sorted_pos = sortedUnique(sort(inPositions, intGt), intEq)
  outLst = deletePositionsSorted(inLst, sorted_pos)
  outLst
end

#= Takes a list and a sorted list of positions (smallest index first), and
deletes the positions from the list. Note that positions are indexed from 0.
Example: deletePositionsSorted({1, 2, 3, 4, 5}, {0, 2, 3}) => {2, 5} =#
function deletePositionsSorted(inLst::Lst, inPositions::Lst)::Lst
  T = Any
  local outLst::Lst = list()

  local i::ModelicaInteger = 0
  local e::T
  local rest::Lst = inLst

  for pos in inPositions
    while i != pos
      e, rest = listHead(rest), listRest(rest)
      outLst = e <| outLst
      i = i + 1
    end
    _, rest = listHead(rest), listRest(rest)
    i = i + 1
  end
  outLst = append_reverse(outLst, rest)
  outLst
end

#= Removes all matching integers that occur first in a list. If the first
element doesn't match it returns the list. =#
function removeMatchesFirst(inLst::Lst, inN::ModelicaInteger)::Lst
  local outLst::Lst = inLst

  for e in inLst
    if e != inN
      break
    end
    _, outLst = listHead(outLst), listRest(outLst)
  end
  outLst
end

#= Takes an element, a position and a list, and replaces the value at the given
position in the list. Position is an integer between 1 and n for a list of
n elements.
Example: replaceAt('A', 2, {'a', 'b', 'c'}) => {'a', 'A', 'c'} =#
function replaceAt(inElement::T, inPosition #= one-based index =#::ModelicaInteger, inLst::Lst)::Lst
  T = Any
  local outLst::Lst

  local e::T
  local rest::Lst = inLst
  local delst::DoubleEndedLst

  @assert true == (inPosition >= 1)
  delst = DoubleEndedLst.fromLst(list())
  #=  Shuffle elements from inLst to outLst until the position is reached.
  =#
  for i in 1:inPosition - 1
    e, rest = listHead(rest), listRest(rest)
    DoubleEndedLst.push_back(delst, e)
  end
  #=  Replace the element at the position and append the remaining elements.
  =#
  _, rest = listHead(rest), listRest(rest)
  outLst = DoubleEndedLst.toLstAndClear(delst, prependToLst = inElement <| rest)
  outLst
end

#= Applies the function to each element of the list until the function returns
true, and then replaces that element with the replacement.
Example: replaceOnTrue(4, {1, 2, 3}, isTwo) => {1, 4, 3}. =#
function replaceOnTrue(inReplacement::T, inLst::Lst, inFunc::FuncType)::Tuple{Bool, Lst}
  T = Any
  local outReplaced::Bool = false
  local outLst::Lst = list()

  local e::T
  local rest::Lst = inLst

  while ! listEmpty(rest)
    e, rest = listHead(rest), listRest(rest)
    if inFunc(e)
      outReplaced = true
      outLst = append_reverse(outLst, inReplacement <| rest)
      return (outReplaced, outLst)
    end
    outLst = e <| outLst
  end
  outLst = inLst
  (outReplaced, outLst)
end

#= Takes an element, a position and a list, and replaces the value at the given
position in the list. Position is an integer between 1 and n for a list of
n elements.
Example: replaceAtIndexFirst(2, 'A', {'a', 'b', 'c'}) => {'a', 'A', 'c'} =#
function replaceAtIndexFirst(inPosition #= one-based index =#::ModelicaInteger, inElement::T, inLst::Lst)::Lst
  T = Any
  local outLst::Lst

  outLst = replaceAt(inElement, inPosition, inLst)
  outLst
end

#= Takes an list, a position and a list, and replaces the element at the given
position with the first list in the second list. Position is an integer
between 0 and n - 1 for a list of n elements.
Example: replaceAt({'A', 'B'}, 1, {'a', 'b', 'c'}) => {'a', 'A', 'B', 'c'} =#
function replaceAtWithLst(inReplacementLst::Lst, inPosition::ModelicaInteger, inLst::Lst)::Lst
  T = Any
  local outLst::Lst = list()

  local e::T
  local rest::Lst = inLst

  @assert true == (inPosition >= 0)
  #=  Shuffle elements from inLst to outLst until the position is reached.
  =#
  for i in 0:inPosition - 1
    e, rest = listHead(rest), listRest(rest)
    outLst = e <| outLst
  end
  #=  Replace the element at the position and append the remaining elements.
  =#
  _, rest = listHead(rest), listRest(rest)
  rest = listAppend(inReplacementLst, rest)
  outLst = append_reverse(outLst, rest)
  outLst
end

#= Takes
- an element,
- a position (indexed from 1)
- a list and
- a fill value
The function replaces the value at the given position in the list, if the
given position is out of range, the fill value is used to padd the list up to
that element position and then insert the value at the position
Example: replaceAtWithFill(\\\"A\\\", 5, {\\\"a\\\",\\\"b\\\",\\\"c\\\"},\\\"dummy\\\") =>
{\\\"a\\\",\\\"b\\\",\\\"c\\\",\\\"dummy\\\",\\\"A\\\"} =#
function replaceAtWithFill(inElement::T, inPosition::ModelicaInteger, inLst::Lst, inFillValue::T)::Lst
  T = Any
  local outLst::Lst

  local len::ModelicaInteger
  local fill_lst::Lst

  @assert true == (inPosition >= 0)
  len = listLength(inLst)
  if inPosition <= len
    outLst = replaceAt(inElement, inPosition, inLst)
  else
    fill_lst = list(inElement)
    for i in 2:inPosition - len
      fill_lst = inFillValue <| fill_lst
    end
    outLst = listAppend(inLst, fill_lst)
  end
  outLst
end

#= Creates a string from a list and a function that maps a list element to a
string. It also takes several parameters that determine the formatting of
the string. Ex:
toString({1, 2, 3}, intString, 'nums', '{', ';', '}, true) =>
'nums{1;2;3}'
=#
function toString(inLst::Lst, inPrintFunc::FuncType, inLstNameStr #= The name of the list. =#::String, inBeginStr #= The start of the list =#::String, inDelimitStr #= The delimiter between list elements. =#::String, inEndStr #= The end of the list. =#::String, inPrintEmpty #= If false, don't output begin and end if the list is empty. =#::Bool)::String
  T = Any
  local outString::String

  outString = begin
    local str::String
    #=  Empty list and inPrintEmpty true => concatenate the list name, begin
    =#
    #=  string and end string.
    =#
    @match inLst, inPrintEmpty begin
      ( nil(), true)  => begin
        stringAppendLst(list(inLstNameStr, inBeginStr, inEndStr))
      end

      ( nil(), false)  => begin
        inLstNameStr
      end

      _  => begin
        str = stringDelimitLst(map(inLst, inPrintFunc), inDelimitStr)
        str = stringAppendLst(list(inLstNameStr, inBeginStr, str, inEndStr))
        str
      end
    end
  end
  #=  Empty list and inPrintEmpty false => output only list name.
  =#
  outString
end

#= @author:adrpo
returns true if the list has exactly one element, otherwise false =#
function hasOneElement(inLst::Lst)::Bool
  T = Any
  local b::Bool

  b = begin
    @match inLst begin
      _ <|  nil()  => begin
        true
      end

      _  => begin
        false
      end
    end
  end
  b
end

#= author:waurich
returns true if the list has more than one element, otherwise false =#
function hasSeveralElements(inLst::Lst)::Bool
  T = Any
  local b::Bool

  b = begin
    @match inLst begin
      _ <|  nil()  => begin
        false
      end

      nil()  => begin
        false
      end

      _  => begin
        true
      end
    end
  end
  b
end

function lengthLstElements(inLstLst::Lst)::ModelicaInteger
  T = Any
  local outLength::ModelicaInteger

  outLength = sum(listLength(lst) for lst in inLstLst)
  outLength
end

#= This function generates a list by calling the given function with the given
argument. The elements generated by the function are accumulated in a list
until the function returns false as the last return value. =#
function generate(inArg::ArgT1, inFunc::GenerateFunc)::Lst
  T = Any ,ArgT1 = Any
  local outLst::Lst

  outLst = listReverseInPlace(generateReverse(inArg, inFunc))
  outLst
end

#= This function generates a list by calling the given function with the given
argument. The elements generated by the function are accumulated in a list
until the function returns false as the last return value. This function
returns the generated list reversed. =#
function generateReverse(inArg::ArgT1, inFunc::GenerateFunc)::Lst
  T = Any ,ArgT1 = Any
  local outLst::Lst = list()

  local cont::Bool
  local arg::ArgT1 = inArg
  local e::T

  while true
    arg, e, cont = inFunc(arg)
    if ! cont
      break
    end
    outLst = e <| outLst
  end
  outLst
end

#= Like mapFold, but with the function split into a map and a fold function. =#
function mapFoldSplit(inLst::Lst, inMapFunc::MapFunc, inFoldFunc::FoldFunc, inStartValue::FT)::Tuple{FT, Lst}
  TI = Any ,TO = Any ,FT = Any
  local outResult::FT = inStartValue
  local outLst::Lst = list()

  local eo::TO
  local res::FT

  for e in inLst
    eo, res = inMapFunc(e)
    outResult = inFoldFunc(res, outResult)
    outLst = eo <| outLst
  end
  outLst = listReverseInPlace(outLst)
  (outResult, outLst)
end

#= Like map1Fold, but with the function split into a map and a fold function. =#
function map1FoldSplit(inLst::Lst, inMapFunc::MapFunc, inFoldFunc::FoldFunc, inConstArg::ArgT1, inStartValue::FT)::Tuple{FT, Lst}
  TI = Any ,TO = Any ,FT = Any ,ArgT1 = Any
  local outResult::FT = inStartValue
  local outLst::Lst = list()

  local eo::TO
  local res::FT

  for e in inLst
    eo, res = inMapFunc(e, inConstArg)
    outResult = inFoldFunc(res, outResult)
    outLst = eo <| outLst
  end
  outLst = listReverseInPlace(outLst)
  (outResult, outLst)
end


#= Takes a list and a function. The function is applied to each element in the
list, and the function is itself responsible for adding elements to the
result list. =#
function accumulateMapReverse(inLst::Lst, inMapFunc::MapFunc)::Lst
  TI = Any ,TO = Any
  local outLst::Lst = list()

  for e in inLst
    outLst = inMapFunc(e, outLst)
  end
  outLst
end

#= Takes a list, a function and a result list. The function is applied to each
element of the list, and the function is itself responsible for adding
elements to the result list. =#
function accumulateMapAccum(inLst::Lst, inMapFunc::MapFunc)::Lst
  TI = Any ,TO = Any
  local outLst::Lst = list()

  for e in inLst
    outLst = inMapFunc(e, outLst)
  end
  outLst = listReverse(outLst)
  outLst
end

accumulateMap = accumulateMapAccum

#= Takes a list, a function, an extra argument, and a result list. The function
is applied to each element of the list, and the function is itself responsible
for adding elements to the result list. =#
function accumulateMapAccum1(inLst::Lst, inMapFunc::MapFunc, inArg::ArgT1)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any
  local outLst::Lst = list()

  for e in inLst
    outLst = inMapFunc(e, inArg, outLst)
  end
  outLst = listReverse(outLst)
  outLst
end


function accumulateMapFoldAccum(inLst::Lst, inFunc::FuncType, inFoldArg::FT)::Tuple{FT, Lst}
  TI = Any ,TO = Any ,FT = Any
  local outFoldArg::FT = inFoldArg
  local outLst::Lst = list()

  for e in inLst
    outLst, outFoldArg = inFunc(e, outFoldArg, outLst)
  end
  outLst = listReverse(outLst)
  (outFoldArg, outLst)
end

accumulateMapFold = accumulateMapFoldAccum

function first2FromTuple3(inTuple::Tuple)::Lst
  T = Any
  local outLst::Lst

  local a::T
  local b::T

  a, b, _ = inTuple
  outLst = list(a, b)
  outLst
end

#= Same as map, but stops when it find a certain element as indicated by the
mapping function. Returns the new list, and whether the element was found or
not. =#
function findMap(inLst::Lst, inFunc::FuncType)::Tuple{Bool, Lst}
  T = Any
  local outFound::Bool = false
  local outLst::Lst = list()

  local e::T
  local rest::Lst = inLst

  while ! listEmpty(rest) && ! outFound
    e, rest = listHead(rest), listRest(rest)
    e, outFound = inFunc(e)
    outLst = e <| outLst
  end
  outLst = append_reverse(outLst, rest)
  (outFound, outLst)
end

#= Same as map1, but stops when it find a certain element as indicated by the
mapping function. Returns the new list, and whether the element was found or
not. =#
function findMap1(inLst::Lst, inFunc::FuncType, inArg1::ArgT1)::Tuple{Bool, Lst}
  T = Any ,ArgT1 = Any
  local outFound::Bool = false
  local outLst::Lst = list()

  local e::T
  local rest::Lst = inLst

  while ! listEmpty(rest) && ! outFound
    e, rest = listHead(rest), listRest(rest)
    e, outFound = inFunc(e, inArg1)
    outLst = e <| outLst
  end
  outLst = append_reverse(outLst, rest)
  (outFound, outLst)
end

#= Same as map2, but stops when it find a certain element as indicated by the
mapping function. Returns the new list, and whether the element was found or
not. =#
function findMap2(inLst::Lst, inFunc::FuncType, inArg1::ArgT1, inArg2::ArgT2)::Tuple{Bool, Lst}
  T = Any ,ArgT1 = Any ,ArgT2 = Any
  local outFound::Bool = false
  local outLst::Lst = list()

  local e::T
  local rest::Lst = inLst

  while ! listEmpty(rest) && ! outFound
    e, rest = listHead(rest), listRest(rest)
    e, outFound = inFunc(e, inArg1, inArg2)
    outLst = e <| outLst
  end
  outLst = append_reverse(outLst, rest)
  (outFound, outLst)
end

#= Same as map3, but stops when it find a certain element as indicated by the
mapping function. Returns the new list, and whether the element was found or
not. =#
function findMap3(inLst::Lst, inFunc::FuncType, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)::Tuple{Bool, Lst}
  T = Any ,ArgT1 = Any ,ArgT2 = Any ,ArgT3 = Any
  local outFound::Bool = false
  local outLst::Lst = list()

  local e::T
  local rest::Lst = inLst

  while ! listEmpty(rest) && ! outFound
    e, rest = listHead(rest), listRest(rest)
    e, outFound = inFunc(e, inArg1, inArg2, inArg3)
    outLst = e <| outLst
  end
  outLst = append_reverse(outLst, rest)
  (outFound, outLst)
end

#= Applies the given function over the list and returns first returned value that is not NONE(). =#
function findSome(inLst::Lst, inFunc::FuncType)::T2
  T1 = Any ,T2 = Any
  local outVal::T2

  local retOpt::Option = NONE()
  local e::T1
  local rest::Lst = inLst

  while isNone(retOpt)
    e, rest = listHead(rest), listRest(rest)
    retOpt = inFunc(e)
  end
  #= /*not listEmpty(rest) and not outFound*/ =#
  outVal = begin
    @match retOpt begin
      SOME(outVal)  => begin
        outVal
      end
    end
  end
  outVal
end

#= Applies the given function with one extra argument over the list and returns first returned value that is not NONE(). =#
T1 = Any
T2 = Any
Arg = Any
function findSome1(inLst::Lst, inFunc::FuncType, inArg::Arg)::T2
  local outVal::T2

  local retOpt::Option = NONE()
  local e::T1
  local rest::Lst = inLst

  while isNone(retOpt)
    e, rest = listHead(rest), listRest(rest)
    retOpt = inFunc(e, inArg)
  end
  #= /*not listEmpty(rest) and not outFound*/ =#
  outVal = begin
    @match retOpt begin
      SOME(outVal)  => begin
        outVal
      end
    end
  end
  outVal
end

function splitEqualPrefix(inFullLst::Lst, inPrefixLst::Lst, inEqFunc::EqFunc, inAccum::Lst)::Tuple{Lst, Lst}
  T1 = Any ,T2 = Any
  local outRest::Lst
  local outPrefix::Lst = list()

  local e1::T1
  local e2::T2
  local rest_e1::Lst = inFullLst
  local rest_e2::Lst = inPrefixLst

  while true
    if listEmpty(rest_e1) || listEmpty(rest_e2)
      break
    end
    e1, rest_e1 = listHead(rest_e1), listRest(rest_e1)
    e2, rest_e2 = listHead(rest_e2), listRest(rest_e2)
    if ! inEqFunc(e1, e2)
      break
    end
    outPrefix = e1 <| outPrefix
  end
  outPrefix = listReverseInPlace(outPrefix)
  outRest = rest_e1
  (outRest, outPrefix)
end

#= Takes a two-dimensional list and creates a list combinations
given by the cartesian product of the sublists.

Ex: combination({{1, 2}, {3}, {4, 5}}) =>
{{1, 3, 4}, {1, 3, 5}, {2, 3, 4}, {2, 3, 5}}
=#
function combination(inElements::Lst)::Lst
  TI = Any
  local outElements::Lst

  local elems::Lst

  if listEmpty(inElements)
    outElements = list()
  else
    elems = combination_tail(inElements, list(), list())
    outElements = listReverse(elems)
  end
  outElements
end

function combination_tail(inElements::Lst, inCombination::Lst, inAccumElems::Lst)::Lst
  TI = Any
  local outElements::Lst

  outElements = begin
    local head::Lst
    local rest::Lst
    local acc::Lst
    @match inElements begin
      head <| rest  => begin
        acc = inAccumElems
        for e in head
          acc = combination_tail(rest, e <| inCombination, acc)
        end
        acc
      end

      _  => begin
        listReverse(inCombination) <| inAccumElems
      end
    end
  end
  outElements
end

#= Takes a two-dimensional list and calls the given function on the combinations
given by the cartesian product of the sublists.

Ex: combinationMap({{1, 2}, {3}, {4, 5}}, func) =>
{func({1, 3, 4}), func({1, 3, 5}), func({2, 3, 4}), func({2, 3, 5})}
=#
function combinationMap(inElements::Lst, inMapFunc::MapFunc)::Lst
  TI = Any ,TO = Any
  local outElements::Lst

  local elems::Lst

  elems = combinationMap_tail(inElements, inMapFunc, list(), list())
  outElements = listReverse(elems)
  outElements
end

function combinationMap_tail(inElements::Lst, inMapFunc::MapFunc, inCombination::Lst, inAccumElems::Lst)::Lst
  TI = Any ,TO = Any
  local outElements::Lst

  outElements = begin
    local head::Lst
    local rest::Lst
    local acc::Lst
    @match inElements begin
      head <| rest  => begin
        acc = inAccumElems
        for e in head
          acc = combinationMap_tail(rest, inMapFunc, e <| inCombination, acc)
        end
        acc
      end

      _  => begin
        inMapFunc(listReverse(inCombination)) <| inAccumElems
      end
    end
  end
  outElements
end

#= Takes a two-dimensional list and calls the given function on the combinations
given by the cartesian product of the sublists. Also takes an extra constant
argument that is sent to the function.

Ex: combinationMap({{1, 2}, {3}, {4, 5}}, func, x) =>
{func({1, 3, 4}, x), func({1, 3, 5}, x), func({2, 3, 4}, x), func({2, 3, 5}, x)}
=#
function combinationMap1(inElements::Lst, inMapFunc::MapFunc, inArg::ArgT1)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any
  local outElements::Lst

  local elems::Lst

  elems = combinationMap1_tail(inElements, inMapFunc, inArg, list(), list())
  outElements = listReverse(elems)
  outElements
end

function combinationMap1_tail(inElements::Lst, inMapFunc::MapFunc, inArg::ArgT1, inCombination::Lst, inAccumElems::Lst)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any
  local outElements::Lst

  outElements = begin
    local head::Lst
    local rest::Lst
    local acc::Lst
    @match inElements begin
      head <| rest  => begin
        acc = inAccumElems
        for e in head
          acc = combinationMap1_tail(rest, inMapFunc, inArg, e <| inCombination, acc)
        end
        acc
      end

      _  => begin
        inMapFunc(listReverse(inCombination), inArg) <| inAccumElems
      end
    end
  end
  outElements
end

function combinationMap1_tail2(inHead::Lst, inRest::Lst, inMapFunc::MapFunc, inArg::ArgT1, inCombination::Lst, inAccumElems::Lst)::Lst
  TI = Any ,TO = Any ,ArgT1 = Any
  local outElements::Lst

  outElements = begin
    local head::TI
    local rest::Lst
    local comb::Lst
    local accum::Lst
    @match inHead, inCombination, inAccumElems begin
      (head <| rest, comb, accum)  => begin
        accum = combinationMap1_tail(inRest, inMapFunc, inArg, head <| comb, accum)
        combinationMap1_tail2(rest, inRest, inMapFunc, inArg, comb, accum)
      end

      _  => begin
        inAccumElems
      end
    end
  end
  outElements
end

#= Checks if all elements in the lists have equal references =#
function allReferenceEq(inLst1::Lst, inLst2::Lst)::Bool
  T = Any
  local outEqual::Bool

  outEqual = begin
    local el1::T
    local el2::T
    local rest1::Lst
    local rest2::Lst
    @match inLst1, inLst2 begin
      (el1 <| rest1, el2 <| rest2)  => begin
        if referenceEq(el1, el2) allReferenceEq(rest1, rest2)
        else
          false
        end
      end

      ( nil(),  nil())  => begin
        true
      end

      _  => begin
        false
      end
    end
  end
  outEqual
end

#= Takes two lists and a comparison function and removes the heads from both
lists as long as they are equal. Ex:
removeEqualPrefix({1, 2, 3, 5, 7}, {1, 2, 3, 9, 7}) => ({5, 7}, {9, 7}) =#
function removeEqualPrefix(inLst1::Lst, inLst2::Lst, inCompFunc::CompFunc)::Tuple{Lst, Lst}
  T1 = Any ,T2 = Any
  local outLst2::Lst = inLst2
  local outLst1::Lst = inLst1

  local e1::T1
  local e2::T2

  while ! (listEmpty(outLst1) || listEmpty(outLst2))
    e1 = listHead(outLst1)
    e2 = listHead(outLst2)
    if ! inCompFunc(e1, e2)
      break
    end
    outLst1 = listRest(outLst1)
    outLst2 = listRest(outLst2)
  end
  (outLst2, outLst1)
end

#= Returns true if inLst1 is longer than inLst2, otherwise false. =#
function listIsLonger(inLst1::Lst, inLst2::Lst)::Bool
  T = Any
  local isLonger::Bool

  isLonger = intGt(listLength(inLst1), listLength(inLst2))
  isLonger
end

function toLstWithPositions(inLst::Lst)::Lst
  T = Any
  local outLst::Lst = list()

  local pos::ModelicaInteger = 1

  for e in inLst
    outLst = e, pos <| outLst
    pos = pos + 1
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

#= @author: adrpo
make NONE() if the list is empty
make SOME(list) if the list is not empty =#
function mkOption(inLst::Lst)::Option
  T = Any
  local outOption::Option

  outOption = if listEmpty(inLst) NONE()
  else
    SOME(inLst)
  end
  outOption
end

#= Returns true if the given predicate function returns true for all elements in
the given list. =#
function all(inLst::Lst, inFunc::PredFunc)::Bool
  T = Any
  local outResult::Bool

  for e in inLst
    if ! inFunc(e)
      outResult = false
      return outResult
    end
  end
  outResult = true
  outResult
end

#= Takes a list of values and a filter function over the values and returns 2
sub lists of values for which the matching function returns true and false. =#
function separateOnTrue(inLst::Lst, inFilterFunc::FilterFunc)::Tuple{Lst, Lst}
  T = Any
  local outLstFalse::Lst = list()
  local outLstTrue::Lst = list()

  for e in inLst
    if inFilterFunc(e)
      outLstTrue = e <| outLstTrue
    else
      outLstFalse = e <| outLstFalse
    end
  end
  (outLstFalse, outLstTrue)
end

#= Takes a list of values and a filter function over the values and returns 2
sub lists of values for which the matching function returns true and false. =#
function separate1OnTrue(inLst::Lst, inFilterFunc::FilterFunc, inArg1::ArgT1)::Tuple{Lst, Lst}
  T = Any ,ArgT1 = Any
  local outLstFalse::Lst = list()
  local outLstTrue::Lst = list()

  for e in inLst
    if inFilterFunc(e, inArg1)
      outLstTrue = e <| outLstTrue
    else
      outLstFalse = e <| outLstFalse
    end
  end
  (outLstFalse, outLstTrue)
end

function mapFirst(inLst::Lst, inFunc::FindMapFunc)::TO
  TI = Any ,TO = Any
  local outElement::TO

  local found::Bool

  for e in inLst
    outElement, found = inFunc(e)
    if found
      return outElement
    end
  end
  fail()
  outElement
end

function isSorted(inLst::Lst, inFunc::Comp)::Bool
  T = Any
  local b::Bool = true

  local found::Bool
  local prev::T

  if listEmpty(inLst)
    return b
  end
  prev, _ = listHead(inLst), listRest(inLst)
  for e in listRest(inLst)
    if ! inFunc(prev, e)
      b = false
      return b
    end
  end
  b
end

#= Applies a function to only the elements given by the sorted list of indices. =#
function mapIndices(inLst::Lst, indices::Lst, func::MapFunc)::Lst
  T = Any
  local outLst::Lst

  local i::ModelicaInteger = 1
  local idx::ModelicaInteger
  local rest_idx::Lst
  local e::T
  local rest_lst::Lst

  if listEmpty(indices)
    outLst = inLst
    return outLst
  end
  idx, rest_idx = listHead(indices), listRest(indices)
  rest_lst = inLst
  outLst = list()
  while ! listEmpty(rest_lst)
    e, rest_lst = listHead(rest_lst), listRest(rest_lst)
    if i == idx
      outLst = func(e) <| outLst
      if listEmpty(rest_idx)
        outLst = append_reverse(rest_lst, outLst)
        break
      else
        idx, rest_idx = listHead(rest_idx), listRest(rest_idx)
      end
    else
      outLst = e <| outLst
    end
    i = i + 1
  end
  outLst = listReverseInPlace(outLst)
  outLst
end

end
