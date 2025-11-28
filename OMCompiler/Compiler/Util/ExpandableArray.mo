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

encapsulated uniontype ExpandableArray<T> "Implementation of an expandable array

This provides a generic implementation of an expandable array. It basically
behaves like an ordinary array, which means all elements can get accessed via
index. When the array runs out of space, it get automatically resized. It is
also possible to delete an element from any position."

record EXPANDABLE_ARRAY
  Mutable<Integer> numberOfElements;
  Mutable<Integer> lastUsedIndex;
  Mutable<Integer> capacity;
  Mutable<array<Option<T>>> data;
end EXPANDABLE_ARRAY;

protected
import Array;
import MetaModelica.Dangerous;
import Mutable;
import Util;

public
impure function new "O(n)
  Creates a new empty ExpandableArray with a certain capacity."
  input Integer capacity;
  input T dummy "This is needed to determine the type information, the actual value is not used";
  output ExpandableArray<T> exarray;
algorithm
  exarray := EXPANDABLE_ARRAY(Mutable.create(0), Mutable.create(0), Mutable.create(capacity), Mutable.create(arrayCreate(capacity, NONE())));
end new;

function clear "O(n)
  Deletes all elements."
  input output ExpandableArray<T> exarray;
protected
  Integer n = Mutable.access(exarray.numberOfElements);
  Integer lastUsedIndex = Mutable.access(exarray.lastUsedIndex);
  array<Option<T>> data = Mutable.access(exarray.data);
algorithm
  Mutable.update(exarray.numberOfElements, 0);
  Mutable.update(exarray.lastUsedIndex, 0);
  for i in 1:lastUsedIndex loop
    if isSome(Dangerous.arrayGetNoBoundsChecking(data, i)) then
      n := n-1;
      Dangerous.arrayUpdateNoBoundsChecking(data, i, NONE());
      if n == 0 then
        return;
      end if;
    end if;
  end for;
end clear;

function copy
  input ExpandableArray<T> inExarray;
  input T dummy "This is needed to determine the type information, the actual value is not used";
  output ExpandableArray<T> outExarray;
algorithm
  outExarray := new(Mutable.access(inExarray.capacity), dummy);
  outExarray.numberOfElements := Mutable.create(Mutable.access(inExarray.numberOfElements));
  outExarray.lastUsedIndex := Mutable.create(Mutable.access(inExarray.lastUsedIndex));
  outExarray.capacity := Mutable.create(Mutable.access((inExarray.capacity)));
  outExarray.data := Mutable.create(arrayCopy(Mutable.access(inExarray.data)));
end copy;

function occupied "O(1)
  Returns if the element at the given index is occupied or not."
  input Integer index;
  input ExpandableArray<T> exarray;
  output Boolean b;
protected
  Integer lastUsedIndex = Mutable.access(exarray.lastUsedIndex);
  array<Option<T>> data = Mutable.access(exarray.data);
algorithm
  b := index >= 1 and index <= lastUsedIndex and isSome(Dangerous.arrayGetNoBoundsChecking(data, index));
end occupied;

function get "O(1)
  Returns the value of the element at the given index.
  Fails if there is nothing assigned to the given index."
  input Integer index;
  input ExpandableArray<T> exarray;
  output T value;
protected
  array<Option<T>> data = Mutable.access(exarray.data);
algorithm
  true := index >= 1 and index <= Mutable.access(exarray.lastUsedIndex);
  SOME(value) := Dangerous.arrayGetNoBoundsChecking(data, index);
end get;

function expandToSize "O(n)
  Expands an array to the given size, or does nothing if the array is already
  large enough."
  input Integer minCapacity;
  input output ExpandableArray<T> exarray;
protected
  Integer capacity = Mutable.access(exarray.capacity);
  array<Option<T>> data = Mutable.access(exarray.data);
algorithm
  if minCapacity > capacity then
    Mutable.update(exarray.capacity, minCapacity);
    data := Array.expandToSize(minCapacity, data, NONE());
    Mutable.update(exarray.data, data);
  end if;
end expandToSize;

function set "if index <= capacity then O(1) otherwise O(n)
  Sets the element at the given index to the given value.
  Fails if the index is already used."
  input Integer index;
  input T value;
  input output ExpandableArray<T> exarray;
protected
  Integer numberOfElements = Mutable.access(exarray.numberOfElements);
  Integer lastUsedIndex = Mutable.access(exarray.lastUsedIndex);
  Integer capacity = Mutable.access(exarray.capacity);
  array<Option<T>> data = Mutable.access(exarray.data);
algorithm
  if index > 0 and (index > capacity or isNone(Dangerous.arrayGetNoBoundsChecking(data, index))) then
    if index > capacity then
      capacity := max(capacity, 1);

      while index > capacity loop
        capacity := capacity * 2;
      end while;

      expandToSize(capacity, exarray);
      data := Mutable.access(exarray.data);
    end if;

    arrayUpdate(data, index, SOME(value));
    Mutable.update(exarray.numberOfElements, numberOfElements+1);
    if index > lastUsedIndex then
      Mutable.update(exarray.lastUsedIndex, index);
    end if;
  else
    fail();
  end if;
end set;

function add "if index <= capacity then O(1) otherwise O(n)
  Sets the first unused element to the given value."
  input T value;
  input output ExpandableArray<T> exarray;
  output Integer index;
protected
  Integer lastUsedIndex = Mutable.access(exarray.lastUsedIndex);
algorithm
  index := lastUsedIndex+1;
  exarray := set(index, value, exarray);
end add;

function delete "O(1)
  Deletes the value of the element at the given index.
  Fails if there is no value stored at the given index."
  input Integer index;
  input output ExpandableArray<T> exarray;
protected
  Integer numberOfElements = Mutable.access(exarray.numberOfElements);
  Integer lastUsedIndex = Mutable.access(exarray.lastUsedIndex);
  array<Option<T>> data = Mutable.access(exarray.data);
algorithm
  if index >= 1 and index <= lastUsedIndex and isSome(Dangerous.arrayGetNoBoundsChecking(data, index)) then
    arrayUpdate(data, index, NONE());
    Mutable.update(exarray.numberOfElements, numberOfElements-1);

    if index == lastUsedIndex then
      lastUsedIndex := lastUsedIndex-1;
      while lastUsedIndex > 0 and isNone(Dangerous.arrayGetNoBoundsChecking(data, lastUsedIndex)) loop
        lastUsedIndex := lastUsedIndex-1;
      end while;
      Mutable.update(exarray.lastUsedIndex, lastUsedIndex);
    end if;
  else
    fail();
  end if;
end delete;

function update "O(1)
  Overrides the value of the element at the given index.
  Fails if there is no value stored at the given index."
  input Integer index;
  input T value;
  input output ExpandableArray<T> exarray;
protected
  Integer lastUsedIndex = Mutable.access(exarray.lastUsedIndex);
  array<Option<T>> data = Mutable.access(exarray.data);
algorithm
  if index >= 1 and index <= lastUsedIndex and isSome(Dangerous.arrayGetNoBoundsChecking(data, index)) then
    arrayUpdate(data, index, SOME(value));
  else
    fail();
  end if;
end update;

function toList
  input ExpandableArray<T> exarray;
  output list<T> listT = {};
protected
  Integer numberOfElements = Mutable.access(exarray.numberOfElements);
  Integer lastUsedIndex = Mutable.access(exarray.lastUsedIndex);
  array<Option<T>> data = Mutable.access(exarray.data);
  T dummy;
algorithm
  if numberOfElements == 0 then
    listT := {};
  elseif lastUsedIndex == 1 then
    listT := {Util.getOption(data[1])};
  else
    listT :=  list(Util.getOption(data[i]) for i guard Util.isSome(data[i]) in 1:lastUsedIndex);
  end if;
end toList;

function compress "O(n)
  Reorders the elements in order to remove all the gaps.
  Be careful: This changes the indices of the elements."
  input output ExpandableArray<T> exarray;
protected
  Integer numberOfElements = Mutable.access(exarray.numberOfElements);
  Integer lastUsedIndex = Mutable.access(exarray.lastUsedIndex);
  array<Option<T>> data = Mutable.access(exarray.data);
  Integer i = 0;
algorithm
  while lastUsedIndex > numberOfElements loop
    i := i+1;
    if isNone(Dangerous.arrayGetNoBoundsChecking(data, i)) then
      Dangerous.arrayUpdateNoBoundsChecking(data, i, Dangerous.arrayGetNoBoundsChecking(data, lastUsedIndex));
      Dangerous.arrayUpdateNoBoundsChecking(data, lastUsedIndex, NONE());
      lastUsedIndex := lastUsedIndex-1;
      while isNone(Dangerous.arrayGetNoBoundsChecking(data, lastUsedIndex)) loop
        lastUsedIndex := lastUsedIndex-1;
      end while;
    end if;
  end while;

  Mutable.update(exarray.lastUsedIndex, lastUsedIndex);
end compress;

function shrink "O(n)
  Reduces the capacity of the ExpandableArray to the number of elements.
  Be careful: This may change the indices of the elements."
  input output ExpandableArray<T> exarray;
protected
  Integer numberOfElements = Mutable.access(exarray.numberOfElements);
  array<Option<T>> data = Mutable.access(exarray.data);
  array<Option<T>> newData;
algorithm
  exarray := compress(exarray);
  Mutable.update(exarray.capacity, numberOfElements);
  newData := Dangerous.arrayCreateNoInit(numberOfElements, Dangerous.arrayGetNoBoundsChecking(data, 1));
  for i in 1:numberOfElements loop
    Dangerous.arrayUpdateNoBoundsChecking(newData, i, Dangerous.arrayGetNoBoundsChecking(data, i));
  end for;
  Mutable.update(exarray.data, newData);
end shrink;

function toString "O(n)
  Dumps all elements with the given print function."
  input ExpandableArray<T> exarray;
  input String header;
  input PrintFunction func;
  input Boolean debug = true;
  output String str;

  partial function PrintFunction
    input T t;
    output String str;
  end PrintFunction;
protected
  Integer numberOfElements = Mutable.access(exarray.numberOfElements);
  Integer capacity = Mutable.access(exarray.capacity);
  T value;
  array<Option<T>> data = Mutable.access(exarray.data);
algorithm
  if debug then
    str := header + " (" + intString(numberOfElements) +  "/" + intString(capacity) + ")\n";
  else
    str := header + " (" + intString(numberOfElements) + ")\n";
  end if;

  str := str + "========================================\n";

  if numberOfElements == 0 then
    str := str + "<empty>\n";
  else
    for i in 1:capacity loop
      if isSome(Dangerous.arrayGetNoBoundsChecking(data, i)) then
        SOME(value) := Dangerous.arrayGetNoBoundsChecking(data, i);
        numberOfElements := numberOfElements-1;
        str := str + intString(i) + ": " + func(value) + "\n";
        if numberOfElements == 0 then
          return;
        end if;
      end if;
    end for;
  end if;
end toString;

function getNumberOfElements
  input ExpandableArray<T> exarray;
  output Integer numberOfElements = Mutable.access(exarray.numberOfElements);
end getNumberOfElements;

function getLastUsedIndex
  input ExpandableArray<T> exarray;
  output Integer lastUsedIndex = Mutable.access(exarray.lastUsedIndex);
end getLastUsedIndex;

function getCapacity
  input ExpandableArray<T> exarray;
  output Integer capacity = Mutable.access(exarray.capacity);
end getCapacity;

function getData
  input ExpandableArray<T> exarray;
  output array<Option<T>> data = Mutable.access(exarray.data);
end getData;

annotation(__OpenModelica_Interface="util");
end ExpandableArray;
