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

encapsulated uniontype Vector<T>
  "An implementation of a generic dynamic array."

  import Mutable;

protected
  import MetaModelica.Dangerous.*;

public
  record VECTOR
    Mutable<array<T>> data;
    Mutable<Integer> size "The number of stored elements.";
  end VECTOR;

  function new<T>
    "Creates a new empty Vector."
    input Integer size = 0 "Initial capacity";
    output Vector<T> v;
  protected
    T dummy = dummy;
  algorithm
    v := VECTOR(Mutable.create(arrayCreateNoInit(size, dummy)),
                Mutable.create(0));
  end new;

  function newFill
    "Creates a new Vector filled with the given value."
    input Integer size;
    input T value;
    output Vector<T> v;
  algorithm
    v := VECTOR(Mutable.create(arrayCreate(size, value)),
                Mutable.create(size));
  end newFill;

  function fromArray
    "Creates a Vector from an array."
    input array<T> arr;
    output Vector<T> v;
  algorithm
    v := VECTOR(Mutable.create(arrayCopy(arr)),
                Mutable.create(arrayLength(arr)));
  end fromArray;

  function toArray
    "Converts a Vector to an array."
    input Vector<T> v;
    output array<T> arr;
  protected
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
    T dummy = dummy;
  algorithm
    if sz == arrayLength(data) then
      // If the Vector is filled to capacity, just make a copy of the internal array.
      arr := arrayCopy(data);
    else
      arr := arrayCreateNoInit(sz, dummy);
      for i in 1:sz loop
        arrayUpdateNoBoundsChecking(arr, i, arrayGetNoBoundsChecking(data, i));
      end for;
    end if;
  end toArray;

  function fromList
    "Creates a Vector from a list."
    input list<T> l;
    output Vector<T> v;
  protected
    array<T> data = listArray(l);
  algorithm
    v := VECTOR(Mutable.create(data), Mutable.create(arrayLength(data)));
  end fromList;

  function toList
    "Converts a Vector to a list."
    input Vector<T> v;
    output list<T> l;
  protected
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
  algorithm
    if sz == arrayLength(data) then
      // If the Vector is filled to capacity, use the faster arrayList.
      l := arrayList(data);
    else
      l := list(arrayGetNoBoundsChecking(data, i) for i in 1:sz);
    end if;
  end toList;

  function push
    "Appends a value to the end of the Vector."
    input Vector<T> v;
    input T value;
  protected
    array<T> data;
    Integer sz = Mutable.access(v.size);
  algorithm
    sz := sz + 1;
    Mutable.update(v.size, sz);

    data := reserveCapacity(v, sz);
    arrayUpdateNoBoundsChecking(data, sz, value);
  end push;

  function append
    "Appends v2 to the end of v1."
    input Vector<T> v1;
    input Vector<T> v2;
  protected
    array<T> data1;
    Integer sz1 = Mutable.access(v1.size);
    array<T> data2 = Mutable.access(v2.data);
    Integer sz2 = Mutable.access(v2.size);
    Integer new_sz = sz1 + sz2;
  algorithm
    data1 := reserveCapacity(v1, new_sz);

    sz1 := sz1 + 1;
    for i in 1:arrayLength(data2) loop
      arrayUpdateNoBoundsChecking(data1, sz1 + i,
        arrayGetNoBoundsChecking(data2, i));
    end for;

    Mutable.update(v1.size, new_sz);
  end append;

  function appendList
    "Appends a list to the end of the Vector."
    input Vector<T> v;
    input list<T> l;
  protected
    array<T> data;
    Integer sz = Mutable.access(v.size);
    Integer new_sz = sz + listLength(l);
    list<T> rest_l = l;
  algorithm
    data := reserveCapacity(v, new_sz);

    for i in sz+1:new_sz loop
      arrayUpdateNoBoundsChecking(data, i, listHead(rest_l));
      rest_l := listRest(rest_l);
    end for;

    Mutable.update(v.size, new_sz);
  end appendList;

  function appendArray
    "Appends an array to the end of the Vector."
    input Vector<T> v;
    input array<T> arr;
  protected
    array<T> data;
    Integer sz = Mutable.access(v.size);
    Integer new_sz = sz + arrayLength(arr);
  algorithm
    data := reserveCapacity(v, new_sz);

    for i in 1:arrayLength(arr) loop
      arrayUpdateNoBoundsChecking(data, sz + i,
        arrayGetNoBoundsChecking(arr, i));
    end for;

    Mutable.update(v.size, new_sz);
  end appendArray;

  function pop
    "Removes the last element in the Vector. Fails if the Vector is empty.
     Does not change the capacity of the Vector."
    input Vector<T> v;
  protected
    T null = null;
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
  algorithm
    arrayUpdateNoBoundsChecking(data, sz, null);
    Mutable.update(v.size, sz - 1);
  end pop;

  function clear
    "Removes all elements from the Vector.
     Does not change the capacity of the Vector."
    input Vector<T> v;
  protected
    T null = null;
    array<T> data = Mutable.access(v.data);
  algorithm
    for i in 1:Mutable.access(v.size) loop
      arrayUpdateNoBoundsChecking(data, i, null);
    end for;

    Mutable.update(v.size, 0);
  end clear;

  function shrink
    "Removes elements from the Vector until it contains newSize elements, or
     does nothing if newSize is larger than the size of the Vector.
     Fails if the new size is negative.
     Does not change the capacity of the Vector."
    input Vector<T> v;
    input Integer newSize;
  protected
    T null = null;
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
  algorithm
    if newSize < sz then
      for i in newSize:sz loop
        arrayUpdateNoBoundsChecking(data, i, null);
      end for;

      Mutable.update(v.size, newSize);
    end if;
  end shrink;

  function grow
    input Vector<T> v;
    input Integer newSize;
    input T fillValue;
  protected
    array<T> data;
    Integer sz = Mutable.access(v.size);
  algorithm
    if newSize > sz then
      data := reserveCapacity(v, newSize);

      for i in sz+1:newSize loop
        arrayUpdateNoBoundsChecking(data, i, fillValue);
      end for;

      Mutable.update(v.size, newSize);
    end if;
  end grow;

  function resize
    input Vector<T> v;
    input Integer newSize;
    input T fillValue;
  protected
    Integer sz = Mutable.access(v.size);
  algorithm
    if newSize < sz then
      shrink(v, newSize);
    elseif newSize > sz then
      grow(v, newSize, fillValue);
    end if;
  end resize;

  function remove
    "Removes the element at the given index, or fails if the index is out of
     bounds. The elements after the removed element will be moved to fill the gap."
    input Vector<T> v;
    input Integer index;
  protected
    Integer sz = Mutable.access(v.size);
    array<T> data;
  algorithm
    if index == sz then
      pop(v);
    elseif index < 0 or index > sz then
      fail();
    else
      data := Mutable.access(v.data);

      for i in index:sz loop
        arrayUpdateNoBoundsChecking(data, i,
          arrayGetNoBoundsChecking(data, i + 1));
      end for;

      Mutable.update(v.size, sz - 1);
    end if;
  end remove;

  function update
    "Updates the element at the given one-based index to the given value.
     Fails if the index is out of bounds."
    input Vector<T> v;
    input Integer index;
    input T value;
  protected
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
  algorithm
    if index <= 0 or index > sz then
      fail();
    end if;

    arrayUpdateNoBoundsChecking(data, index, value);
  end update;

  function updateNoBounds
    "Updates the element at the given one-based index to the given value without
     checking if the one-based index is in bounds. This is DANGEROUS and should
     only be used when the index is already known to be in bounds."
    input Vector<T> v;
    input Integer index;
    input T value;
  algorithm
    arrayUpdateNoBoundsChecking(Mutable.access(v.data), index, value);
  end updateNoBounds;

  function get
    "Returns the value of the element at the given one-based index.
     Fails if the index is out of bounds."
    input Vector<T> v;
    input Integer index;
    output T value;
  protected
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
  algorithm
    if index <= 0 or index > sz then
      fail();
    end if;

    value := arrayGetNoBoundsChecking(data, index);
  end get;

  function getNoBounds
    "Returns the value of the element at the given one-based index without
     checking if the index is out of bounds. This is DANGEROUS and should only
     be used when the index is already known to be in bounds."
    input Vector<T> v;
    input Integer index;
    output T value;
  algorithm
    value := arrayGetNoBoundsChecking(Mutable.access(v.data), index);
  end getNoBounds;

  function last
    "Returns the last element in the array, or fails if the array is empty."
    input Vector<T> v;
    output T value;
  protected
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
  algorithm
    if sz == 0 then
      fail();
    end if;

    value := arrayGetNoBoundsChecking(data, sz);
  end last;

  function size
    "Returns the number of elements in the Vector."
    input Vector<T> v;
    output Integer sz = Mutable.access(v.size);
  end size;

  function capacity
    "Returns the number of elements the Vector can store without having to
     allocate more memory."
    input Vector<T> v;
    output Integer capacity = arrayLength(Mutable.access(v.data));
  end capacity;

  function isEmpty
    "Returns true if the Vector is empty, otherwise false."
    input Vector<T> v;
    output Boolean empty = Mutable.access(v.size) == 0;
  end isEmpty;

  function reserve
    "Increases the capacity of the Vector to the given amount of elements.
     Does nothing if the Vector's capacity is already large enough."
    input Vector<T> v;
    input Integer newCapacity;
  protected
    array<T> data = Mutable.access(v.data);
  algorithm
    if newCapacity > arrayLength(data) then
      data := resizeArray(data, newCapacity);
      Mutable.update(v.data, data);
    end if;
  end reserve;

  function trim
    "Shrinks the capacity of the Vector to the actual number of elements it contains."
    input Vector<T> v;
  protected
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
  algorithm
    if sz < arrayLength(data) then
      data := resizeArray(data, sz);
      Mutable.update(v.data, data);
    end if;
  end trim;

  function fill
    "Fills the given interval with the given value. Fails if any part of the
     interval is out of bounds. Does nothing if the lower bound of the interval
     is larger than the upper bound."
    input Vector<T> v;
    input T value;
    input Integer from = 1;
    input Integer to = Mutable.access(v.size);
  protected
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
  algorithm
    if from < 1 or to < 1 or from > sz or to > sz then
      fail();
    end if;

    for i in from:to loop
      arrayUpdateNoBoundsChecking(data, i, value);
    end for;
  end fill;

  function map<OT>
    "Applies a function to each element of the given Vector and creates a new
     Vector from the results. If shrink is set to true then the new Vector will
     only allocate enough capacity to hold the new elements, if shrink is set to
     false it will keep the same capacity as the old Vector."
    input Vector<T> v;
    input MapFn fn;
    input Boolean shrink = true;
    output Vector<OT> outV;

    partial function MapFn
      input T value;
      output OT res;
    end MapFn;
  protected
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
    array<OT> new_data;
    OT dummy = dummy;
  algorithm
    new_data := arrayCreateNoInit(if shrink then sz else arrayLength(data), dummy);

    for i in 1:sz loop
      arrayUpdateNoBoundsChecking(new_data, i, fn(arrayGetNoBoundsChecking(data, i)));
    end for;

    outV := VECTOR(Mutable.create(new_data), Mutable.create(sz));
  end map;

  function apply
    "Applies the given function to each element in the Vector, changing each
     element's value to the result of the call."
    input Vector<T> v;
    input ApplyFn fn;

    partial function ApplyFn
      input output T value;
    end ApplyFn;
  protected
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
  algorithm
    for i in 1:sz loop
      arrayUpdateNoBoundsChecking(data, i,
        fn(arrayGetNoBoundsChecking(data, i)));
    end for;
  end apply;

  function fold<FT>
    "Applies the given function to each element in the Vector, updating the
     given argument as it goes along."
    input Vector<T> v;
    input FoldFn fn;
    input output FT arg;

    partial function FoldFn
      input T value;
      input output FT arg;
    end FoldFn;
  protected
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
  algorithm
    for i in 1:sz loop
      arg := fn(arrayGetNoBoundsChecking(data, i), arg);
    end for;
  end fold;

  function find
    "Returns the first element and the index of that element for which the given
     function returns true, or NONE() and -1 if no such element exists."
    input Vector<T> v;
    input PredFn fn;
    output Option<T> oe;
    output Integer index;

    partial function PredFn
      input T e;
      output Boolean res;
    end PredFn;
  protected
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
    T e;
  algorithm
    for i in 1:sz loop
      e := arrayGetNoBoundsChecking(data, i);

      if fn(e) then
        oe := SOME(e);
        index := i;
        return;
      end if;
    end for;

    oe := NONE();
    index := -1;
  end find;

  function findFold<FT>
    "Returns the first element and the index of that element for which the given
     function returns true, but proceeds to check all other for better
     solutions regarding an extra argument, or NONE() and -1 if no such element exists."
    input Vector<T> v;
    input PredFn fn;
    output Option<T> oe = NONE();
    output Integer index = -1;
    input output FT arg;

    partial function PredFn
      input T e;
      output Boolean res;
      input output FT arg;
    end PredFn;
  protected
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
    T e;
    Boolean res;
  algorithm
    for i in 1:sz loop
      e := arrayGetNoBoundsChecking(data, i);

      (res, arg) := fn(e, arg);
      if res then
        oe := SOME(e);
        index := i;
      end if;
    end for;
  end findFold;

  function all
    "Returns true if the given function returns true for all elements in the
     Vector, otherwise false."
    input Vector<T> v;
    input PredFn fn;
    output Boolean res;

    partial function PredFn
      input T e;
      output Boolean res;
    end PredFn;
  protected
    array<T> data = Mutable.access(v.data);
  algorithm
    for i in 1:Mutable.access(v.size) loop
      if not fn(arrayGetNoBoundsChecking(data, i)) then
        res := false;
        return;
      end if;
    end for;

    res := true;
  end all;

  function any
    "Returns true if the given function returns true for any element in the
     Vector, otherwise false."
    input Vector<T> v;
    input PredFn fn;
    output Boolean res;

    partial function PredFn
      input T e;
      output Boolean res;
    end PredFn;
  protected
    array<T> data = Mutable.access(v.data);
  algorithm
    for i in 1:Mutable.access(v.size) loop
      if fn(arrayGetNoBoundsChecking(data, i)) then
        res := true;
        return;
      end if;
    end for;

    res := false;
  end any;

  function none
    "Returns true if the given function returns true for none of the elements in
     the Vector, otherwise false."
    input Vector<T> v;
    input PredFn fn;
    output Boolean res;

    partial function PredFn
      input T e;
      output Boolean res;
    end PredFn;
  protected
    array<T> data = Mutable.access(v.data);
  algorithm
    for i in 1:Mutable.access(v.size) loop
      if fn(arrayGetNoBoundsChecking(data, i)) then
        res := false;
        return;
      end if;
    end for;

    res := true;
  end none;

  function copy
    "Creates a copy of the given Vector."
    input Vector<T> v;
    output Vector<T> c;
  protected
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
  algorithm
    c := VECTOR(Mutable.create(arrayCopy(data)), Mutable.create(sz));
  end copy;

  function deepCopy
    "Creates a deep copy of the given Vector using the given copy function."
    input Vector<T> v;
    input CopyFn fn;
    output Vector<T> c;

    partial function CopyFn
      input output T value;
    end CopyFn;
  protected
    array<T> data = Mutable.access(v.data);
    Integer sz = Mutable.access(v.size);
  algorithm
    data := arrayCopy(data);

    for i in 1:arrayLength(data) loop
      arrayUpdateNoBoundsChecking(data, i, fn(arrayGetNoBoundsChecking(data, i)));
    end for;

    c := VECTOR(Mutable.create(data), Mutable.create(sz));
  end deepCopy;

  function swap
    "Swaps the contents of two Vectors."
    input Vector<T> v1;
    input Vector<T> v2;
  protected
    array<T> data1 = Mutable.access(v1.data);
    array<T> data2 = Mutable.access(v2.data);
    Integer sz1 = Mutable.access(v1.size);
    Integer sz2 = Mutable.access(v2.size);
  algorithm
    Mutable.update(v1.data, data2);
    Mutable.update(v2.data, data1);
    Mutable.update(v1.size, sz2);
    Mutable.update(v2.size, sz1);
  end swap;

  function toString
    input Vector<T> v;
    input StringFn stringFn;
    input String strBegin = "[";
    input String delim = ", ";
    input String strEnd = "]";
    output String str;

    partial function StringFn
      input T e;
      output String str;
    end StringFn;
  algorithm
    str := strBegin + stringDelimitList(list(stringFn(e) for e in toArray(v)), delim) + strEnd;
  end toString;

protected
  function resizeArray
    "Allocates a new array with the given size, and copies elements from the given
     array to the new array until either all elements have been copied or the new
     array has been filled."
    input array<T> arr;
    input Integer newSize;
    output array<T> outArr;
  protected
    T dummy = dummy;
  algorithm
    outArr := arrayCreateNoInit(newSize, dummy);

    for i in 1:min(newSize, arrayLength(arr)) loop
      arrayUpdateNoBoundsChecking(outArr, i, arrayGetNoBoundsChecking(arr, i));
    end for;
  end resizeArray;

  function reserveCapacity
    input Vector<T> v;
    input Integer newSize;
    output array<T> data = Mutable.access(v.data);
  protected
    Integer cap = arrayLength(data);
  algorithm
    if newSize > cap then
      cap := max(cap, 1);

      while newSize > cap loop
        cap := cap * 2;
      end while;

      data := resizeArray(Mutable.access(v.data), cap);
      Mutable.update(v.data, data);
    end if;
  end reserveCapacity;

annotation(__OpenModelica_Interface="util");
end Vector;
