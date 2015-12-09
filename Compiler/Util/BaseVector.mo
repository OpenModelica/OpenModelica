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

encapsulated partial package BaseVector
"
  This is a base class for a mutable dynamic array, which automatically
  allocates more memory when needed. To use it, extend the package, redeclare T,
  and give defaultValue a value. T is the type of the elements stored in the
  array, while defaultValue is a constant of that type. The main purpose of
  defaultValue is to allow the use of arrayCreateNoInit, which requires a dummy
  argument to fix the type of the array. The actual value of defaultValue is not
  used for this. defaultValue is also optionally used by resize to fill up
  empty space when making the Vector bigger, and for overwriting deleted
  elements if the ON_DELETION free policy is used. defaultValue should therefore
  preferably be as small as possible (in terms of memory usage).

  An example of how to declare a String Vector type:

    encapsulated package StringVector
      import BaseVector;
      extends BaseVector(redeclare type T = String, defaultValue = \"\");
      annotation(__OpenModelica_Interface=\"util\");
    end StringVector;

  BaseVector also has a growthFactor constant which can be overridden, which
  decides how fast the Vector grows when the available space runs out. The
  default is 2, i.e. the Vector doubles in size when it runs out of space.

  There is also a freePolicy constant, which controls how the Vector frees
  deleted elements. If set to ON_DELETION it immediately overwrites deleted
  elements with defaultValue, which would be appropriate for complex types that
  can take up a lot of memory. The other option is LAZY, which keeps the deleted
  elements until they're overwritten or the internal array is reallocated. This
  option would be appropriate for small types like Integer, where all values
  take up an equal amount of memory.
"

replaceable type T = Integer; // Should be Any.
constant T defaultValue;
constant Real growthFactor = 2;
constant FreePolicy freePolicy = FreePolicy.ON_DELETION;

type FreePolicy = enumeration(
  ON_DELETION "Immediately free deleted elements.",
  LAZY "Keep deleted elements until they're overwritten or a reallocation occurs."
);

protected
import MetaModelica.Dangerous;

public
// The Vector type is an array of one VectorInternal, to make it completely mutable.
type Vector = array<VectorInternal>;

uniontype VectorInternal
  record VECTOR
    array<T> data;
    Integer size "The number of stored elements.";
    Integer capacity "The number of elements that can be stored.";
  end VECTOR;
end VectorInternal;

function new
  "Creates a new empty Vector with a certain capacity."
  input Integer inSize = 1;
  output Vector outVector;
protected
  array<T> data;
algorithm
  assert(growthFactor > 1.0, "growthFactor must be larger than 1");
  data := Dangerous.arrayCreateNoInit(inSize, defaultValue);
  outVector := arrayCreate(1, VECTOR(data, 0, inSize));
end new;

function newFill
  "Creates a new Vector filled with the given value."
  input Integer inSize;
  input T inFillValue;
  output Vector outVector;
protected
  array<T> data;
algorithm
  assert(growthFactor > 1.0, "growthFactor must be larger than 1");
  data := arrayCreate(inSize, inFillValue);
  outVector := arrayCreate(1, VECTOR(data, inSize, inSize));
end newFill;

function add
  "Appends a value to the end of the Vector."
  input Vector inVector;
  input T inValue;
protected
  VectorInternal vec = inVector[1];
  Integer capacity;
algorithm
  vec.size := vec.size + 1;

  if vec.size > vec.capacity then
    vec.capacity := integer(ceil(intReal(vec.capacity) * growthFactor));
    vec.data := copyArray(vec.data, vec.capacity);
  end if;

  Dangerous.arrayUpdateNoBoundsChecking(vec.data, vec.size, inValue);
  Dangerous.arrayUpdateNoBoundsChecking(inVector, 1, vec);
end add;

function pop
  "Removes the last element in the Vector."
  input Vector inVector;
protected
  VectorInternal vec = inVector[1];
algorithm
  if freePolicy == FreePolicy.ON_DELETION then
    arrayUpdate(vec.data, vec.size, defaultValue);
  end if;
  vec.size := max(vec.size - 1, 0);
  Dangerous.arrayUpdateNoBoundsChecking(inVector, 1, vec);
end pop;

function set
  "Sets the element at the given index to the given value. Fails if the index is
   out of bounds."
  input Vector inVector;
  input Integer inIndex;
  input T inValue;
protected
  VectorInternal vec = inVector[1];
algorithm
  if inIndex > 0 and inIndex <= vec.size then
    Dangerous.arrayUpdateNoBoundsChecking(vec.data, inIndex, inValue);
  else
    fail();
  end if;
end set;

function get
  "Returns the value of the element at the given index. Fails if the index is
   out of bounds."
  input Vector inVector;
  input Integer inIndex;
  output T outValue;
protected
  VectorInternal vec = inVector[1];
algorithm
  if inIndex > 0 and inIndex <= vec.size then
    outValue := Dangerous.arrayGetNoBoundsChecking(vec.data, inIndex);
  else
    fail();
  end if;
end get;

function last
  input Vector inVector;
  output T outValue;
protected
  VectorInternal vec = inVector[1];
algorithm
  if vec.size > 0 then
    outValue := vec.data[vec.size];
  else
    fail();
  end if;
end last;

function size
  "Returns the number of elements in the Vector."
  input Vector inVector;
  output Integer outSize = inVector[1].size;
end size;

// Alias for size, since size can't be used inside this package (the compiler
// mistakes it for the builtin size).
function length = size;

function capacity
  "Return the number of elements the Vector can store without having to allocate
   more memory."
  input Vector inVector;
  output Integer outCapacity = inVector[1].capacity;
end capacity;

function isEmpty
  "Returns true if the Vector is empty, otherwise false."
  input Vector inVector;
  output Boolean outIsEmpty = inVector[1].size == 0;
end isEmpty;

function reserve
  "Increases the capacity of the Vector to the given amount of elements.
   Does nothing if the Vector's capacity is already large enough."
  input Vector inVector;
  input Integer inSize;
protected
  VectorInternal vec = inVector[1];
algorithm
  if inSize > vec.capacity then
    vec.data := copyArray(vec.data, inSize);
    vec.capacity := inSize;
    Dangerous.arrayUpdateNoBoundsChecking(inVector, 1, vec);
  end if;
end reserve;

function resize
  "Resizes the Vector. If the new size is larger than the previous size, then
   new elements will be added to the Vector until it reaches the given size.
   This can trigger a reallocation. If the new size is smaller than the previous
   size, then the Vector is shrunk to the given size. This only shrinks the size
   of the Vector, not its capacity."
  input Vector inVector;
  input Integer inNewSize;
  input T inFillValue = defaultValue;
protected
  VectorInternal vec = inVector[1];
algorithm
  if inNewSize <= 0 then
    fail();
  elseif inNewSize > vec.size then
    if inNewSize > vec.capacity then
      // Increase the capacity if the new size is larger than the capacity.
      vec.data := copyArray(vec.data, inNewSize);
      vec.capacity := inNewSize;
    end if;

    // Fill the space between the last element and the new end of the array.
    fillArray(vec.data, inFillValue, vec.size + 1, inNewSize);
  elseif freePolicy == FreePolicy.ON_DELETION then
    fillArray(vec.data, defaultValue, inNewSize + 1, vec.capacity);
  end if;

  vec.size := inNewSize;
  Dangerous.arrayUpdateNoBoundsChecking(inVector, 1, vec);
end resize;

function trim
  "Shrinks the capacity of the Vector to the actual number of elements it
   contains. To avoid a costly reallocation when the memory gain would be small
   this is only done when the size is smaller than the capacity by a certain
   threshold. The default threshold is 0.9, i.e. the Vector is only trimmed if
   it's less than 90% full."
  input Vector inVector;
  input Real inThreshold = 0.9;
protected
  VectorInternal vec = inVector[1];
algorithm
  if vec.size < integer(intReal(vec.capacity) * inThreshold) then
    vec.data := copyArray(vec.data, vec.size);
    vec.capacity := vec.size;
    Dangerous.arrayUpdateNoBoundsChecking(inVector, 1, vec);
  end if;
end trim;

function fill
  "Fills the given interval with the given value. Fails if the start or end
   position is out of bounds. Does nothing if start is larger than end."
  input Vector inVector;
  input T inFillValue;
  input Integer inStart = 1;
  input Integer inEnd = length(inVector);
protected
  VectorInternal vec = inVector[1];
algorithm
  if inStart < 1 or inEnd < 1 or inEnd > length(inVector) then
    fail();
  end if;

  fillArray(vec.data, inFillValue, inStart, inEnd);
end fill;

function fromList
  "Creates a Vector from a list."
  input list<T> inList;
  output Vector outVector = fromArray(listArray(inList));
end fromList;

function toList
  "Converts a Vector to a list."
  input Vector inVector;
  output list<T> outList;
protected
  array<T> data;
  Integer sz, capacity;
algorithm
  VECTOR(data = data, size = sz, capacity = capacity) := inVector[1];

  if sz == capacity then
    // If Vector is filled to capacity, convert the whole array to a list.
    outList := arrayList(data);
  else
    // Otherwise, make a list of only the stored elements.
    outList := list(data[i] for i in 1:sz);
  end if;
end toList;

function fromArray
  "Creates a Vector from an array. The array is copied, so changes to the
   Vector's internal array will not affect the given array."
  input array<T> inArray;
  output Vector outVector;
protected
  Integer sz = arrayLength(inArray);
algorithm
  outVector := arrayCreate(1, VECTOR(arrayCopy(inArray), sz, sz));
end fromArray;

function toArray
  "Converts a Vector to an array. This makes a copy of the Vector's internal
   array, so changing the returned array will not affect the Vector."
  input Vector inVector;
  output array<T> outArray;
protected
  array<T> data;
  Integer sz, capacity;
algorithm
  VECTOR(data = data, size = sz, capacity = capacity) := inVector[1];

  if sz == capacity then
    // If Vector is filled to capacity, make a copy of the internal array.
    outArray := arrayCopy(data);
  else
    // Otherwise, make a new array and copy all stored elements from the
    // internal array to it.
    outArray := Dangerous.arrayCreateNoInit(sz, defaultValue);
    for i in 1:sz loop
      Dangerous.arrayUpdateNoBoundsChecking(outArray, i,
        Dangerous.arrayGetNoBoundsChecking(data, i));
    end for;
  end if;
end toArray;

function map
  "Applies the given function to each element in the Vector, changing each
   element's value to the result of the call."
  input Vector inVector;
  input MapFunc inFunc;

  partial function MapFunc
    input T inValue;
    output T outValue;
  end MapFunc;
protected
  array<T> data;
  Integer sz;
  T old_val, new_val;
algorithm
  VECTOR(data = data, size = sz) := inVector[1];

  for i in 1:sz loop
    old_val := data[i];
    new_val := inFunc(old_val);

    if not referenceEq(old_val, new_val) then
      Dangerous.arrayUpdateNoBoundsChecking(data, i, new_val);
    end if;
  end for;
end map;

function fold<FT>
  "Applies the given function to each element in the Vector, updating the given
   argument as it goes along."
  input Vector inVector;
  input FoldFunc inFunc;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input T inValue;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
protected
  array<T> data;
  Integer sz;
algorithm
  VECTOR(data = data, size = sz) := inVector[1];

  for i in 1:sz loop
    outResult := inFunc(data[i], outResult);
  end for;
end fold;

function clone
  "Creates a clone of the given Vector."
  input Vector inVector;
  output Vector outVector;
protected
  VectorInternal vec = inVector[1];
algorithm
  vec.data := arrayCopy(vec.data);
  outVector := arrayCreate(1, vec);
end clone;

protected

function copyArray
  "Allocates a new array with the given size, and copies elements from the given
   array to the new array until either all elements have been copied or the new
   array has been filled."
  input array<T> inArray;
  input Integer inNewSize;
  output array<T> outArray;
algorithm
  outArray := Dangerous.arrayCreateNoInit(inNewSize, defaultValue);

  for i in 1:min(inNewSize, arrayLength(inArray)) loop
    Dangerous.arrayUpdateNoBoundsChecking(outArray, i,
      Dangerous.arrayGetNoBoundsChecking(inArray, i));
  end for;
end copyArray;

function fillArray
  "Fills an array with the given value."
  input array<T> inArray;
  input T inValue;
  input Integer inStart;
  input Integer inEnd;
algorithm
  for i in inStart:inEnd loop
    Dangerous.arrayUpdateNoBoundsChecking(inArray, i, inValue);
  end for;
end fillArray;

annotation(__OpenModelica_Interface="util", __OpenModelica_isBaseClass=true);
end BaseVector;
