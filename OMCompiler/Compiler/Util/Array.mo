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

encapsulated package Array
" file:        Array.mo
  package:     Array
  description: Array functions

"

protected
import MetaModelica.Dangerous.{arrayGetNoBoundsChecking, arrayUpdateNoBoundsChecking, arrayCreateNoInit};
import Error;

public
function mapNoCopy<T>
  "Takes an array and a function over the elements of the array, which is
   applied for each element.  Since it will update the array values the returned
   array must have the same type, and thus the applied function must also return
   the same type."
  input array<T> inArray;
  input FuncType inFunc;
  output array<T> outArray = inArray;

  partial function FuncType
    input T inElement;
    output T outElement;
  end FuncType;
algorithm
  for i in 1:arrayLength(inArray) loop
    arrayUpdate(inArray, i, inFunc(arrayGetNoBoundsChecking(inArray, i)));
  end for;
end mapNoCopy;

function mapNoCopy_1<T, ArgT>
  "Same as arrayMapNoCopy, but with an additional arguments that's updated for
   each call."
  input array<T> inArray;
  input FuncType inFunc;
  input ArgT inArg;
  output array<T> outArray = inArray;
  output ArgT outArg = inArg;

  partial function FuncType
    input tuple<T, ArgT> inTuple;
    output tuple<T, ArgT> outTuple;
  end FuncType;
protected
  T e;
algorithm
  for i in 1:arrayLength(inArray) loop
    (e, outArg) := inFunc((arrayGetNoBoundsChecking(inArray, i), outArg));
    arrayUpdate(inArray, i, e);
  end for;
end mapNoCopy_1;

protected function downheap
  input output array<Integer> inArray;
  input Integer n;
  input Integer vIn;
protected
  Integer v = vIn;
  Integer w = 2*v+1;
  Integer tmp;
algorithm
  while w<n loop
    if w+1 < n then
      if inArray[w+2]>inArray[w+1] then
        w := w + 1;
      end if;
    end if;
    if inArray[v+1]>=inArray[w+1] then
      return;
    end if;
    tmp := inArray[v+1];
    inArray[v+1] := inArray[w+1];
    inArray[w+1] := tmp;
    v := w;
    w := 2*v + 1;
  end while;
end downheap;

public function heapSort
  input output array<Integer> inArray;
protected
  Integer n = arrayLength(inArray);
  Integer tmp;
algorithm
  for v in (intDiv(n,2)-1):-1:0 loop
    inArray := downheap(inArray, n, v);
  end for;
  for v in n:-1:2 loop
    tmp := inArray[1];
    inArray[1] := inArray[v];
    inArray[v] := tmp;
    inArray := downheap(inArray, v-1, 0);
  end for;
end heapSort;

function findFirstOnTrue<T>
  input array<T> inArray;
  input FuncType inPredicate;
  output Option<T> outElement;

  partial function FuncType
    input T inElement;
    output Boolean outMatch;
  end FuncType;
algorithm
  outElement := NONE();
  for e in inArray loop
    if inPredicate(e) then
      outElement := SOME(e);
      break;
    end if;
  end for;
end findFirstOnTrue;

function findFirstOnTrueWithIdx<T>
  input array<T> inArray;
  input FuncType inPredicate;
  output Option<T> outElement;
  output Integer idxOut = -1;

  partial function FuncType
    input T inElement;
    output Boolean outMatch;
  end FuncType;
protected
  Integer idx=1;
algorithm
  outElement := NONE();
  for e in inArray loop
    if inPredicate(e) then
      idxOut := idx;
      outElement := SOME(e);
      break;
    end if;
    idx := idx+1;
  end for;
end findFirstOnTrueWithIdx;

function select<T>
  "Takes an array and a list of indices, and returns a new array with the
   indexed elements. Will fail if any index is out of bounds."
  input array<T> inArray;
  input list<Integer> inIndices;
  output array<T> outArray;
protected
  Integer i = 1;
algorithm
  outArray := arrayCreateNoInit(listLength(inIndices), inArray[1]);

  for e in inIndices loop
    arrayUpdate(outArray, i, arrayGet(inArray, e));
    i := i + 1;
  end for;
end select;

function map<TI, TO>
  "Takes an array and a function over the elements of the array, which is
   applied to each element. The updated elements will form a new array, leaving
   the original array unchanged."
  input array<TI> inArray;
  input FuncType inFunc;
  output array<TO> outArray;

  partial function FuncType
    input TI inElement;
    output TO outElement;
  end FuncType;
protected
  Integer len = arrayLength(inArray);
  TO res;
algorithm
  // If the array is empty, use list transformations to fix the types!
  if len == 0 then
    outArray := listArray({});
  else
    // If the array isn't empty, use the first element to create the new array.
    res := inFunc(arrayGetNoBoundsChecking(inArray, 1));
    outArray := arrayCreateNoInit(len, res);
    arrayUpdateNoBoundsChecking(outArray, 1, res);

    for i in 2:len loop
      arrayUpdateNoBoundsChecking(outArray, i, inFunc(arrayGetNoBoundsChecking(inArray, i)));
    end for;
  end if;
end map;

function map1<TI, TO, ArgT>
  "Takes an array, an extra arguments, and a function over the elements of the
   array, which is applied to each element. The updated elements will form a new
   array, leaving the original array unchanged."
  input array<TI> inArray;
  input FuncType inFunc;
  input ArgT inArg;
  output array<TO> outArray;

  partial function FuncType
    input TI inElement;
    input ArgT inArg;
    output TO outElement;
  end FuncType;
protected
  Integer len = arrayLength(inArray);
  TO res;
algorithm
  // If the array is empty, use list transformations to fix the types!
  if len == 0 then
    outArray := listArray({});
  else
    // If the array isn't empty, use the first element to create the new array.
    res := inFunc(arrayGetNoBoundsChecking(inArray, 1), inArg);
    outArray := arrayCreateNoInit(len, res);
    arrayUpdate(outArray, 1, res);

    for i in 2:len loop
      arrayUpdate(outArray, i, inFunc(arrayGetNoBoundsChecking(inArray, i), inArg));
    end for;
  end if;
end map1;

function map0<T>
  "Applies a non-returning function to all elements in an array."
  input array<T> inArray;
  input FuncType inFunc;

  partial function FuncType
    input T inElement;
  end FuncType;
algorithm
  for e in inArray loop
    inFunc(e);
  end for;
end map0;

function mapList<TI, TO>
  "As map, but takes a list in and creates an array from the result."
  input list<TI> inList;
  input FuncType inFunc;
  output array<TO> outArray;

  partial function FuncType
    input TI inElement;
    output TO outElement;
  end FuncType;
protected
  Integer i = 2, len = listLength(inList);
  TO res;
algorithm
  if len == 0 then
    outArray := listArray({});
  else
    res := inFunc(listHead(inList));
    outArray := arrayCreateNoInit(len, res);
    arrayUpdate(outArray, 1, res);

    for e in listRest(inList) loop
      arrayUpdate(outArray, i, inFunc(e));
      i := i + 1;
    end for;
  end if;
end mapList;

function fold<T, FoldT>
  "Takes an array, a function, and a start value. The function is applied to
   each array element, and the start value is passed to the function and
   updated."
  input array<T> inArray;
  input FoldFunc inFoldFunc;
  input FoldT inStartValue;
  output FoldT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input FoldT inFoldArg;
    output FoldT outFoldArg;
  end FoldFunc;
algorithm
  for e in inArray loop
    outResult := inFoldFunc(e, outResult);
  end for;
end fold;

function fold1<T, FoldT, ArgT>
  "Takes an array, a function, and a start value. The function is applied to
   each array element, and the start value is passed to the function and
   updated."
  input array<T> inArray;
  input FoldFunc inFoldFunc;
  input ArgT inArg;
  input FoldT inStartValue;
  output FoldT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input ArgT inExtraArg;
    input FoldT inFoldArg;
    output FoldT outFoldArg;
  end FoldFunc;
algorithm
  for e in inArray loop
    outResult := inFoldFunc(e, inArg, outResult);
  end for;
end fold1;

function fold2<T, FoldT, ArgT1, ArgT2>
  "Takes an array, a function, a constant parameter, and a start value. The
   function is applied to each array element, and the start value is passed to
   the function and updated."
  input array<T> inArray;
  input FoldFunc inFoldFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input FoldT inStartValue;
  output FoldT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inExtraArg1;
    input ArgT2 inExtraArg2;
    input FoldT inFoldArg;
    output FoldT outFoldArg;
  end FoldFunc;
algorithm
  for e in inArray loop
    outResult := inFoldFunc(e, inArg1, inArg2, outResult);
  end for;
end fold2;

function fold3<T, FoldT, ArgT1, ArgT2, ArgT3>
  "Takes an array, a function, a constant parameter, and a start value. The
   function is applied to each array element, and the start value is passed to
   the function and updated."
  input array<T> inArray;
  input FoldFunc inFoldFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  input FoldT inStartValue;
  output FoldT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inExtraArg1;
    input ArgT2 inExtraArg2;
    input ArgT3 inExtraArg3;
    input FoldT inFoldArg;
    output FoldT outFoldArg;
  end FoldFunc;
algorithm
  for e in inArray loop
    outResult := inFoldFunc(e, inArg1, inArg2, inArg3, outResult);
  end for;
end fold3;

function fold4<T, FoldT, ArgT1, ArgT2, ArgT3, ArgT4>
  "Takes an array, a function, four constant parameters, and a start value. The
   function is applied to each array element, and the start value is passed to
   the function and updated."
  input array<T> inArray;
  input FoldFunc inFoldFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  input ArgT4 inArg4;
  input FoldT inStartValue;
  output FoldT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inExtraArg1;
    input ArgT2 inExtraArg2;
    input ArgT3 inExtraArg3;
    input ArgT4 inExtraArg4;
    input FoldT inFoldArg;
    output FoldT outFoldArg;
  end FoldFunc;
algorithm
  for e in inArray loop
    outResult := inFoldFunc(e, inArg1, inArg2, inArg3, inArg4, outResult);
  end for;
end fold4;

function fold5<T, FoldT, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5>
  "Takes an array, a function, four constant parameters, and a start value. The
   function is applied to each array element, and the start value is passed to
   the function and updated."
  input array<T> inArray;
  input FoldFunc inFoldFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  input ArgT4 inArg4;
  input ArgT5 inArg5;
  input FoldT inStartValue;
  output FoldT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inExtraArg1;
    input ArgT2 inExtraArg2;
    input ArgT3 inExtraArg3;
    input ArgT4 inExtraArg4;
    input ArgT5 inExtraArg5;
    input FoldT inFoldArg;
    output FoldT outFoldArg;
  end FoldFunc;
algorithm
  for e in inArray loop
    outResult := inFoldFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, outResult);
  end for;
end fold5;

function fold6<T, FoldT, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5, ArgT6>
  "Takes an array, a function, four constant parameters, and a start value. The
   function is applied to each array element, and the start value is passed to
   the function and updated."
  input array<T> inArray;
  input FoldFunc inFoldFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input ArgT3 inArg3;
  input ArgT4 inArg4;
  input ArgT5 inArg5;
  input ArgT6 inArg6;
  input FoldT inStartValue;
  output FoldT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input ArgT1 inExtraArg1;
    input ArgT2 inExtraArg2;
    input ArgT3 inExtraArg3;
    input ArgT4 inExtraArg4;
    input ArgT5 inExtraArg5;
    input ArgT6 inExtraArg6;
    input FoldT inFoldArg;
    output FoldT outFoldArg;
  end FoldFunc;
algorithm
  for e in inArray loop
    outResult := inFoldFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, outResult);
  end for;
end fold6;

function foldIndex<T, FoldT>
"Takes an array, a function, and a start value. The function is applied to
   each array element, and the start value is passed to the function and
   updated, additional the index of the passed element is also passed to the function."
  input array<T> inArray;
  input FoldFunc inFoldFunc;
  input FoldT inStartValue;
  output FoldT outResult = inStartValue;

  partial function FoldFunc
    input T inElement;
    input Integer inIndex;
   input FoldT inFoldArg;
    output FoldT outFoldArg;
  end FoldFunc;
protected
  T e;
algorithm
  for i in 1:arrayLength(inArray) loop
    e := arrayGet(inArray, i);
    outResult := inFoldFunc(e, i, outResult);
  end for;
end foldIndex;

function reduce<T>
  "Takes a list and a function operating on two elements of the array.
   The function performs a reduction of the array to a single value using the
   function. Example:
     reduce([1, 2, 3], intAdd) => 6"
  input array<T> inArray;
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
  outResult := arrayGet(inArray, 1);
  for i in 2:arrayLength(inArray) loop
    outResult := inReduceFunc(outResult, arrayGet(inArray, i));
  end for;
end reduce;

function updateIndexFirst<T>
  "Like arrayUpdate, but with the index first so it can be used with List.map."
  input Integer inIndex;
  input T inValue;
  input array<T> inArray;
algorithm
  arrayUpdate(inArray, inIndex, inValue);
end updateIndexFirst;

function getIndexFirst<T>
  "Like arrayGet, but with the index first so it can used with List.map."
  input Integer inIndex;
  input array<T> inArray;
  output T outElement = arrayGet(inArray, inIndex);
end getIndexFirst;

function updatewithArrayIndexFirst<T>
  "Replaces the element with the given index in the second array with the value
   of the corresponding element in the first array."
  input Integer inIndex;
  input array<T> inArraySrc;
  input array<T> inArrayDest;
algorithm
  arrayUpdate(inArrayDest, inIndex, inArraySrc[inIndex]);
end updatewithArrayIndexFirst;

function updatewithListIndexFirst<T>
  input list<Integer> inList;
  input Integer inStartIndex;
  input array<T> inArraySrc;
  input array<T> inArrayDest;
algorithm
  for i in inStartIndex:inStartIndex+listLength(inList) loop
    arrayUpdate(inArrayDest, i, inArraySrc[i]);
  end for;
end updatewithListIndexFirst;

function updateElementListAppend<T>
  input Integer inIndex;
  input list<T> inValue;
  input array<list<T>> inArray;
algorithm
  arrayUpdate(inArray, inIndex, listAppend(inArray[inIndex], inValue));
end updateElementListAppend;

function replaceAtWithFill<T>
  "Takes
   - an element,
   - a position (1..n)
   - an array and
   - a fill value
   The function replaces the value at the given position in the array, if the
   given position is out of range, the fill value is used to padd the array up
   to that element position and then insert the value at the position.

  Example:
    replaceAtWithFill('A', 5, {'a', 'b', 'c'}, 'dummy') => {'a', 'b', 'c', 'dummy', 'A'}"
  input Integer inPos;
  input T inTypeReplace;
  input T inTypeFill;
  input array<T> inArray;
  output array<T> outArray;
algorithm
  outArray := expandToSize(inPos, inArray, inTypeFill);
  arrayUpdate(outArray, inPos, inTypeReplace);
end replaceAtWithFill;

function expandToSize<T>
  "Expands an array to the given size, or does nothing if the array is already
   large enough."
  input Integer inNewSize;
  input array<T> inArray;
  input T inFill;
  output array<T> outArray;
algorithm
  if inNewSize <= arrayLength(inArray) then
    outArray := inArray;
  else
    outArray := arrayCreate(inNewSize, inFill);
    copy(inArray, outArray);
  end if;
end expandToSize;

function expand<T>
  "Increases the number of elements of an array with inN. Each new element is
   assigned the value inFill."
  input Integer inN;
  input array<T> inArray;
  input T inFill;
  output array<T> outArray;
protected
  Integer len;
algorithm
  if inN < 1 then
    outArray := inArray;
  else
    len := arrayLength(inArray);
    outArray := arrayCreateNoInit(len + inN, inFill);
    copy(inArray, outArray);
    setRange(len + 1, len + inN, outArray, inFill);
  end if;
end expand;

function expandOnDemand<T>
  "Resizes an array with the given factor if the array is smaller than the
   requested size."
  input Integer inNewSize "The number of elements that should fit in the array.";
  input array<T> inArray "The array to resize.";
  input Real inExpansionFactor "The factor to resize the array with.";
  input T inFillValue "The value to fill the new part of the array.";
  output array<T> outArray "The resulting array.";
protected
  Integer new_size, len = arrayLength(inArray);
algorithm
  if inNewSize <= len then
    outArray := inArray;
  else
    new_size := realInt(intReal(len) * inExpansionFactor);
    outArray := arrayCreateNoInit(new_size, inFillValue);
    copy(inArray, outArray);
    setRange(len + 1, new_size, outArray, inFillValue);
  end if;
end expandOnDemand;

function consToElement<T>
  "Concatenates an element to a list element of an array."
  input Integer inIndex;
  input T inElement;
  input array<list<T>> inArray;
  output array<list<T>> outArray;
algorithm
  outArray := arrayUpdate(inArray, inIndex, inElement :: inArray[inIndex]);
end consToElement;

function appendToElement<T>
  "Appends a list to a list element of an array."
  input Integer inIndex;
  input list<T> inElements;
  input array<list<T>> inArray;
  output array<list<T>> outArray;
algorithm
  outArray := arrayUpdate(inArray, inIndex, listAppend(inArray[inIndex], inElements));
end appendToElement;

function appendList<T>
  "Returns a new array with the list elements added to the end of the given array."
  input array<T> arr;
  input list<T> lst;
  output array<T> outArray;
protected
  Integer arr_len = arrayLength(arr), lst_len;
  T e;
  list<T> rest;
algorithm
  if listEmpty(lst) then
    outArray := arr;
  elseif arr_len == 0 then
    outArray := listArray(lst);
  else
    lst_len := listLength(lst);
    outArray := arrayCreateNoInit(arr_len + lst_len, arr[1]);
    copy(arr, outArray);

    rest := lst;
    for i in arr_len+1:arr_len+lst_len loop
      e :: rest := rest;
      arrayUpdateNoBoundsChecking(outArray, i, e);
    end for;
  end if;
end appendList;

function copy<T>
  "Copies all values from inArraySrc to inArrayDest. Fails if inArraySrc is
   larger than inArrayDest.

   NOTE: There's also a builtin arrayCopy operator that should be used if the
         purpose is only to duplicate an array."
  input array<T> inArraySrc;
  input array<T> inArrayDest;
  output array<T> outArray = inArrayDest;
algorithm
  if arrayLength(inArraySrc) > arrayLength(inArrayDest) then
    fail();
  end if;

  for i in 1:arrayLength(inArraySrc) loop
    arrayUpdateNoBoundsChecking(outArray, i, arrayGetNoBoundsChecking(inArraySrc, i));
  end for;
end copy;

function copyN<T>
  "Copies the first inN values from inArraySrc to inArrayDest. Fails if
   inN is larger than either inArraySrc or inArrayDest."
  input array<T> inArraySrc;
  input array<T> inArrayDest;
  input Integer inN;
  output array<T> outArray = inArrayDest;
algorithm
  if inN > arrayLength(inArrayDest) or inN > arrayLength(inArraySrc) then
    fail();
  end if;

  for i in 1:inN loop
    arrayUpdateNoBoundsChecking(outArray, i, arrayGetNoBoundsChecking(inArraySrc, i));
  end for;
end copyN;

function copyRange<T>
  "Copies a range of elements from one array to another."
  input array<T> srcArray "The array to copy from.";
  input array<T> dstArray "The array to insert into.";
  input Integer srcFirst "The index of the first element to copy.";
  input Integer srcLast "The index of the last element to copy.";
  input Integer dstPos "The index to begin inserting at.";
protected
  Integer offset = dstPos - srcFirst;
algorithm
  if srcFirst > srcLast or srcLast > arrayLength(srcArray) or
    offset + srcLast > arrayLength(dstArray) then
    fail();
  end if;

  for i in srcFirst:srcLast loop
    arrayUpdateNoBoundsChecking(dstArray, offset + i,
      arrayGetNoBoundsChecking(srcArray, i));
  end for;
end copyRange;

function createIntRange
  "Creates an array<Integer> of size inLen with the values set to the range of 1:inLen."
  input Integer inLen;
  output array<Integer> outArray;
algorithm
  outArray := arrayCreateNoInit(inLen, 0);

  for i in 1:inLen loop
    arrayUpdateNoBoundsChecking(outArray, i, i);
  end for;
end createIntRange;

function setRange<T>
  "Sets the elements in positions inStart to inEnd to inValue."
  input Integer inStart;
  input Integer inEnd;
  input array<T> inArray;
  input T inValue;
  output array<T> outArray = inArray;
algorithm
  if inStart > arrayLength(inArray) then
    fail();
  end if;

  for i in inStart:inEnd loop
    arrayUpdate(inArray, i, inValue);
  end for;
end setRange;

function getRange<T>
  "Gets the elements between inStart and inEnd."
  input Integer inStart;
  input Integer inEnd;
  input array<T> inArray;
  output list<T> outList = {};
protected
  T value;
algorithm
  if inStart > arrayLength(inArray) then
    fail();
  end if;
  for i in inStart:inEnd loop
    value := arrayGet(inArray, i);
    outList := value::outList;
  end for;
end getRange;

function position<T>
  "Returns the index of the given element in the array, or 0 if it wasn't found."
  input array<T> inArray;
  input T inElement;
  input Integer inFilledSize = arrayLength(inArray) "The filled size of the array.";
  output Integer outIndex;
protected
  T e;
algorithm
  for i in 1:inFilledSize loop
    if valueEq(inElement, inArray[i]) then
      outIndex := i;
      return;
    end if;
  end for;
  outIndex := 0;
end position;

function getMemberOnTrue<VT, ET>
  "Takes a value and returns the first element for which the comparison
   function returns true, along with that elements position in the array."
  input VT inValue;
  input array<ET> inArray;
  input CompFunc inCompFunc;
  output ET outElement;
  output Integer outIndex;

  partial function CompFunc
    input VT inValue;
    input ET inElement;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  for i in 1:arrayLength(inArray) loop
    if inCompFunc(inValue, arrayGetNoBoundsChecking(inArray, i)) then
      outElement := arrayGetNoBoundsChecking(inArray, i);
      outIndex := i;
      return;
    end if;
  end for;
  fail();
end getMemberOnTrue;

function reverse<T>"reverses the elements in an array"
  input array<T> inArray;
  output array<T> outArray;
protected
  Integer size,i;
  T elem1,elem2;
algorithm
  outArray := inArray;
  size := arrayLength(inArray);
  for i in 1:(size/2) loop
    elem1 := arrayGet(inArray,i);
    elem2 := arrayGet(inArray,size-i+1);
    outArray := arrayUpdate(outArray,i,elem2);
    outArray := arrayUpdate(outArray,size-i+1,elem1);
  end for;
end reverse;

function arrayListsEmpty<T>"output true if all lists in the array are empty"
  input array<list<T>> arr;
  output Boolean isEmpty;
algorithm
  isEmpty := fold(arr,arrayListsEmpty1,true);
end arrayListsEmpty;

function arrayListsEmpty1<T>
  input list<T> lst;
  input Boolean isEmptyIn;
  output Boolean isEmptyOut;
algorithm
  isEmptyOut := listEmpty(lst) and isEmptyIn;
end arrayListsEmpty1;

function isEqual<T>
  "Checks if two arrays are equal."
  input array<T> inArr1;
  input array<T> inArr2;
  output Boolean outIsEqual=true;
protected
  Integer arrLength;
algorithm
  arrLength := arrayLength(inArr1);
  if not intEq(arrLength,arrayLength(inArr2)) then
    Error.addMessage(Error.DIFFERENT_DIM_SIZE_IN_ARGUMENTS, {"array","Array.isEqual"});
    fail();
  end if;
  for i in 1:arrLength loop
    if not valueEq(inArr1[i],inArr2[i]) then
      outIsEqual := false;
      break;
    end if;
  end for;
end isEqual;

function exist<T>
  "Returns true if a certain element exists in the given array as indicated by
   the given predicate function."
  input array<T> arr;
  input PredFunc pred;
  output Boolean exists;

  partial function PredFunc
    input T element;
    output Boolean matches;
  end PredFunc;
algorithm
  for e in arr loop
    if pred(e) then
      exists := true;
      return;
    end if;
  end for;

  exists := false;
end exist;

function insertList<T>
  input output array<T> arr;
  input list<T> lst;
  input Integer startPos;
protected
  Integer i = startPos;
algorithm
  for e in lst loop
    arr[i] := e;
    i := i + 1;
  end for;
end insertList;

annotation(__OpenModelica_Interface="util");
end Array;
