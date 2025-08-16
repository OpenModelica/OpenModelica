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
import List;

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
    arrayUpdateNoBoundsChecking(inArray, i, inFunc(arrayGetNoBoundsChecking(inArray, i)));
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
    arrayUpdateNoBoundsChecking(inArray, i, e);
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
  while w < n loop
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

function map1Ind<TI, TO, ArgT>
  "Takes an array, an extra arguments, and a function over the elements of the
   array, which is applied to each element. The index is passed as an extra
   argument. The updated elements will form a new
   array, leaving the original array unchanged."
  input array<TI> inArray;
  input FuncType inFunc;
  input ArgT inArg;
  output array<TO> outArray;

  partial function FuncType
    input TI inElement;
    input Integer index;
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
    res := inFunc(arrayGetNoBoundsChecking(inArray, 1), 1, inArg);
    outArray := arrayCreateNoInit(len, res);
    arrayUpdate(outArray, 1, res);

    for i in 2:len loop
      arrayUpdate(outArray, i, inFunc(arrayGetNoBoundsChecking(inArray, i), i, inArg));
    end for;
  end if;
end map1Ind;

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

function join<T>
  "Returns a new array consisting of the elements from both the given arrays."
  input array<T> arr1;
  input array<T> arr2;
  output array<T> outArray;
protected
  Integer len1 = arrayLength(arr1), len2 = arrayLength(arr2);
algorithm
  if len1 == 0 then
    outArray := arrayCopy(arr2);
  elseif len2 == 0 then
    outArray := arrayCopy(arr1);
  else
    outArray := arrayCreateNoInit(len1 + len2, arr1[1]);
    copyRange(arr1, outArray, 1, len1, 1);
    copyRange(arr2, outArray, 1, len2, len1 + 1);
  end if;
end join;

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
  input Integer srcOffset = 0;
  input Integer dstOffset = 0;
  output array<T> outArray = inArrayDest;
algorithm
  if inN + dstOffset > arrayLength(inArrayDest) or inN + srcOffset > arrayLength(inArraySrc) then
    fail();
  end if;

  for i in 1:inN loop
    arrayUpdateNoBoundsChecking(outArray, i + dstOffset,
      arrayGetNoBoundsChecking(inArraySrc, i + srcOffset));
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

public function toString<T>
  "Creates a string from an array and a function that maps an array element to a
   string. It also takes several parameters that determine the formatting of
   the string. Ex:
     toString([1, 2, 3], intString, 'nums', '[', ';', ']', true) =>
     'nums[1;2;3]'
  "
  input array<T> inArray;
  input FuncType inPrintFunc;
  input String inNameStr      = ""      "The name of the array.";
  input String inBeginStr     = "["     "The start of the array";
  input String inDelimitStr   = ", "    "The delimiter between array elements.";
  input String inEndStr       = "]"     "The end of the array.";
  input Boolean inPrintEmpty  = true    "If false, don't output begin and end if the array is empty.";
  input Integer maxLength     = 0       "If > 0, only the first maxLength elements are printed";
  output String outString;

  partial function FuncType
    input T inElement;
    output String outString;
  end FuncType;
protected
  list<T> lst;
  String endStr = inEndStr;
algorithm

  // TODO implement stringDelimitArray and don't use arrayList

  if maxLength > 0 and arrayLength(inArray) > maxLength then
    lst := List.firstN(arrayList(inArray), maxLength);
    endStr := stringAppendList({inDelimitStr, "...", inEndStr});
  else
    lst := arrayList(inArray);
  end if;

  outString := match(lst, inPrintEmpty)
    local
      String str;

    // Empty list and inPrintEmpty true => concatenate the list name, begin
    // string and end string.
    case ({}, true)
      then stringAppendList({inNameStr, inBeginStr, inEndStr});

    // Empty list and inPrintEmpty false => output only list name.
    case ({}, false)
      then inNameStr;

    else
      algorithm
        str := stringDelimitList(List.map(lst, inPrintFunc), inDelimitStr);
        str := stringAppendList({inNameStr, inBeginStr, str, endStr});
      then
        str;

  end match;
end toString;

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
    fail();
  end if;
  for i in 1:arrLength loop
    if not valueEq(inArr1[i],inArr2[i]) then
      outIsEqual := false;
      break;
    end if;
  end for;
end isEqual;

function isEqualOnTrue<T1, T2>
  "Returns whether the two arrays are equal or not, using the given predicate
   function to check element equality."
  input array<T1> arr1;
  input array<T2> arr2;
  input PredFunc pred;
  output Boolean equal;

  partial function PredFunc
    input T1 e1;
    input T2 e2;
    output Boolean equal;
  end PredFunc;
algorithm
  equal := arrayLength(arr1) == arrayLength(arr2);

  if not equal then
    return;
  end if;

  for i in 1:arrayLength(arr1) loop
    if not pred(arrayGetNoBoundsChecking(arr1, i),
                arrayGetNoBoundsChecking(arr2, i)) then
      equal := false;
      return;
    end if;
  end for;
end isEqualOnTrue;

function allEqual<T>
  input array<T> arr;
  input PredFunc pred;
  output Boolean equal = true;

  partial function PredFunc
    input T e1;
    input T e2;
    output Boolean equal;
  end PredFunc;
algorithm
  if arrayEmpty(arr) then
    return;
  end if;

  for i in 2:arrayLength(arr) loop
    if not pred(arrayGetNoBoundsChecking(arr, 1),
                arrayGetNoBoundsChecking(arr, i)) then
      equal := false;
      return;
    end if;
  end for;
end allEqual;

function isLess<T1, T2>
  "Returns true if arr1 is less than arr2 using a lexicographical comparison."
  input array<T1> arr1;
  input array<T2> arr2;
  input LessFn lessFn;
  output Boolean res;

  partial function LessFn
    input T1 e1;
    input T2 e2;
    output Boolean res;
  end LessFn;
protected
  Integer len1, len2;
  T1 e1;
  T2 e2;
algorithm
  len1 := arrayLength(arr1);
  len2 := arrayLength(arr2);

  // The first pair of elements that's not equal determines whether arr1 < arr2 or not.
  for i in 1:min(len1, len2) loop
    e1 := arrayGetNoBoundsChecking(arr1, i);
    e2 := arrayGetNoBoundsChecking(arr2, i);

    if lessFn(e1, e2) then
      // arr1 < arr2 if e1 < e2.
      res := true;
      return;
    elseif lessFn(e2, e1) then
      // arr1 > arr2 if e2 < e1.
      res := false;
      return;
    end if;
  end for;

  // arr1 < arr2 if arr1 is a prefix of arr2 and all elements in arr1 are equal
  // to the corresponding elements in arr2.
  res := len1 < len2;
end isLess;

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

function remove<T>
  "Returns a new array without the element at the given index."
  input array<T> arr;
  input Integer index;
  output array<T> outArr;
protected
  Integer len = arrayLength(arr);
algorithm
  if len <= 1 then
    outArr := listArray({});
  else
    outArr := arrayCreateNoInit(len - 1, arr[1]);

    for i in 1:index-1 loop
      arrayUpdateNoBoundsChecking(outArr, i, arrayGetNoBoundsChecking(arr, i));
    end for;

    for i in index+1:len-1 loop
      arrayUpdateNoBoundsChecking(outArr, i - 1, arrayGetNoBoundsChecking(arr, i));
    end for;
  end if;
end remove;

function all<T>
  "Returns true if the given predicate function returns true for all elements in
   the given array."
  input array<T> arr;
  input PredFunc inFunc;
  output Boolean outResult;

  partial function PredFunc
    input T e;
    output Boolean res;
  end PredFunc;
algorithm
  for e in arr loop
    if not inFunc(e) then
      outResult := false;
      return;
    end if;
  end for;

  outResult := true;
end all;

function any<T>
  "Returns true if the given predicate function returns true for any element in
   the given array."
  input array<T> arr;
  input PredFunc inFunc;
  output Boolean outResult;

  partial function PredFunc
    input T element;
    output Boolean matches;
  end PredFunc;
algorithm
  for e in arr loop
    if inFunc(e) then
      outResult := true;
      return;
    end if;
  end for;

  outResult := false;
end any;

function minElement<T>
  "Returns the smallest element in the array, or fails if the array is empty."
  input array<T> arr;
  input LessFn lessFn;
  output T res;

  partial function LessFn
    "Returns true if e1 < e2, otherwise false."
    input T e1;
    input T e2;
    output Boolean res;
  end LessFn;
protected
  T e;
algorithm
  res := arr[1];

  for i in 2:arrayLength(arr) loop
    e := arrayGetNoBoundsChecking(arr, i);
    if lessFn(e, res) then
      res := e;
    end if;
  end for;
end minElement;

function maxElement<T>
  "Returns the largest element in the list, or fails if the list is empty."
  input array<T> arr;
  input LessFn lessFn;
  output T res;

  partial function LessFn
    "Returns true if e1 < e2, otherwise false."
    input T e1;
    input T e2;
    output Boolean res;
  end LessFn;
protected
  T e;
algorithm
  res := arr[1];

  for i in 2:arrayLength(arr) loop
    e := arrayGetNoBoundsChecking(arr, i);
    if lessFn(res, e) then
      res := e;
    end if;
  end for;
end maxElement;

function compare<T1, T2>
  "Returns -1 if arr1 is shorter than arr2 or 1 if arr1 is longer than arr2.
   If both arrays are of equal length it applies the given compare function to
   each pair of array elements and returns the first nonzero value, or 0 if no
   nonzero value is received."
  input array<T1> arr1;
  input array<T2> arr2;
  input CompFunc compFn;
  output Integer res;

  partial function CompFunc
    input T1 e1;
    input T2 e2;
    output Integer res;
  end CompFunc;
protected
  Integer l1, l2;
algorithm
  l1 := arrayLength(arr1);
  l2 := arrayLength(arr2);
  res := if l1 == l2 then 0 elseif l1 > l2 then 1 else -1;

  if res <> 0 then
    return;
  end if;

  for i in 1:l1 loop
    res := compFn(arrayGetNoBoundsChecking(arr1, i),
                  arrayGetNoBoundsChecking(arr2, i));

    if res <> 0 then
      return;
    end if;
  end for;
end compare;

function mapFold<TI, TO, ArgT>
  input array<TI> arr;
  input FuncType func;
  input ArgT arg;
  output array<TO> outArray;
  output ArgT outArg = arg;

  partial function FuncType
    input TI e;
    input ArgT arg;
    output TO result;
    output ArgT outArg;
  end FuncType;
protected
  Integer len = arrayLength(arr);
  TO res;
algorithm
  if len == 0 then
    outArray := listArray({});
  else
    (res, outArg) := func(arrayGetNoBoundsChecking(arr, 1), outArg);
    outArray := arrayCreateNoInit(len, res);
    arrayUpdateNoBoundsChecking(outArray, 1, res);

    for i in 2:len loop
      (res, outArg) := func(arrayGetNoBoundsChecking(arr, i), outArg);
      arrayUpdateNoBoundsChecking(outArray, i, res);
    end for;
  end if;
end mapFold;

function transpose<T>
  "Transposes a two-dimensional array."
  input array<array<T>> arr;
  output array<array<T>> outArray;
protected
  Integer c_len, r_len;
  T val;
  array<T> row;
algorithm
  if arrayEmpty(arr) then
    outArray := arr;
    return;
  end if;

  row := arrayGetNoBoundsChecking(arr, 1);

  if arrayEmpty(row) then
    outArray := arr;
    return;
  end if;

  val := arrayGetNoBoundsChecking(row, 1);

  c_len := arrayLength(arr);
  r_len := arrayLength(row);
  outArray := arrayCreateNoInit(r_len, row);

  for i in 1:r_len loop
    arrayUpdateNoBoundsChecking(outArray, i, arrayCreateNoInit(c_len, val));
  end for;

  for r in 1:r_len loop
    for c in 1:c_len loop
      // outArray[r, c] := arr[c, r]
      val := arrayGetNoBoundsChecking(arrayGetNoBoundsChecking(arr, c), r);
      arrayUpdateNoBoundsChecking(arrayGetNoBoundsChecking(outArray, r), c, val);
    end for;
  end for;
end transpose;

function threadMap<T1, T2, TO>
  "Creates an array with the result from calling the given function on each pair
   of elements in two arrays."
  input array<T1> arr1;
  input array<T2> arr2;
  input MapFunc func;
  output array<TO> outArray;

  partial function MapFunc
    input T1 e1;
    input T2 e2;
    output TO res;
  end MapFunc;
protected
  TO res;
  Integer len1, len2;
algorithm
  if arrayEmpty(arr1) then
    outArray := listArray({});
    return;
  end if;

  len1 := arrayLength(arr1);
  len2 := arrayLength(arr2);

  if len1 <> len2 then
    fail();
  end if;

  res := func(arrayGetNoBoundsChecking(arr1, 1), arrayGetNoBoundsChecking(arr2, 1));
  outArray := arrayCreateNoInit(len1, res);
  arrayUpdateNoBoundsChecking(outArray, 1, res);

  for i in 2:len1 loop
    arrayUpdateNoBoundsChecking(outArray, i,
      func(arrayGetNoBoundsChecking(arr1, i), arrayGetNoBoundsChecking(arr2, i)));
  end for;
end threadMap;

function generate<T>
  "Generates an array of length n and fills it by calling the given generator
   function for each array element."
  input Integer n;
  input Generator generator;
  output array<T> arr;

  partial function Generator
    output T e;
  end Generator;
protected
  T e;
algorithm
  if n <= 0 then
    arr := listArray({});
  else
    e := generator();
    arr := arrayCreateNoInit(n, e);
    arrayUpdateNoBoundsChecking(arr, 1, e);

    for i in 2:n loop
      arrayUpdateNoBoundsChecking(arr, i, generator());
    end for;
  end if;
end generate;

function filter<T>
  input array<T> arr;
  input filterFunc fun;
  output array<T> new_arr;
  partial function filterFunc
    input T t;
    output Boolean b "if b=true then 't' gets removed";
  end filterFunc;
protected
  Integer new_size;
  T dummy = dummy; // Fool the compiler into thinking dummy is initialized.
  Integer index = 1;
algorithm
  new_size  := arrayLength(arr) - sum(1 for e guard fun(e) in arr);
  new_arr   := arrayCreateNoInit(new_size, dummy);
  for e in arr loop
    if not fun(e) then
      arrayUpdateNoBoundsChecking(new_arr, index, e);
      index := index + 1;
    end if;
  end for;
end filter;

annotation(__OpenModelica_Interface="util");
end Array;
