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
  array<Integer> numberOfElements "This is an array of one Integer, to make numberOfElements mutable";
  array<Integer> capacity "This is an array of one Integer, to make capacity mutable";
  array<array<Option<T>>> data "This is an array of one array<Option<T>>, to make data mutable";
end EXPANDABLE_ARRAY;

protected
import Array;
import MetaModelica.Dangerous;

public
impure function new "O(n)
  Creates a new empty ExpandableArray with a certain capacity."
  input Integer capacity;
  input T dummy "This is needed to determine the type information, the actual value is not used";
  output ExpandableArray<T> exarray;
algorithm
  exarray := EXPANDABLE_ARRAY(arrayCreate(1, 0), arrayCreate(1, capacity), arrayCreate(1, arrayCreate(capacity, NONE())));
end new;

function clear "O(n)
  Deletes all elements."
  input output ExpandableArray<T> exarray;
protected
  Integer n = Dangerous.arrayGetNoBoundsChecking(exarray.numberOfElements, 1);
  Integer capacity = Dangerous.arrayGetNoBoundsChecking(exarray.capacity, 1);
  array<Option<T>> data = Dangerous.arrayGetNoBoundsChecking(exarray.data, 1);
algorithm
  Dangerous.arrayUpdateNoBoundsChecking(exarray.numberOfElements, 1, 0);
  for i in 1:capacity loop
    if isSome(Dangerous.arrayGetNoBoundsChecking(data, i)) then
      n := n-1;
      Dangerous.arrayUpdateNoBoundsChecking(data, i, NONE());
      if n == 0 then
        return;
      end if;
    end if;
  end for;
end clear;

function get "O(1)
  Returns the value of the element at the given index.
  Fails if there is nothing assigned to the given index."
  input Integer index;
  input ExpandableArray<T> exarray;
  output T value;
protected
  Integer capacity = Dangerous.arrayGetNoBoundsChecking(exarray.capacity, 1);
  array<Option<T>> data = Dangerous.arrayGetNoBoundsChecking(exarray.data, 1);
algorithm
  if index >= 1 and index <= capacity and isSome(Dangerous.arrayGetNoBoundsChecking(data, index)) then
    SOME(value) := Dangerous.arrayGetNoBoundsChecking(data, index);
  else
    fail();
  end if;
end get;

function set "if index <= capacity then O(1) otherwise O(n)
  Sets the element at the given index to the given value.
  Fails if the index is already used."
  input Integer index;
  input T value;
  input output ExpandableArray<T> exarray;
protected
  Integer numberOfElements = Dangerous.arrayGetNoBoundsChecking(exarray.numberOfElements, 1);
  Integer capacity = Dangerous.arrayGetNoBoundsChecking(exarray.capacity, 1);
  array<Option<T>> data = Dangerous.arrayGetNoBoundsChecking(exarray.data, 1);
algorithm
  if index > 0 and (index > capacity or isNone(Dangerous.arrayGetNoBoundsChecking(data, index))) then
    if index > capacity then
      capacity := intMax(2*capacity, index);
      Dangerous.arrayUpdateNoBoundsChecking(exarray.capacity, 1, capacity);
      data := Array.expandToSize(capacity, data, NONE());
      Dangerous.arrayUpdateNoBoundsChecking(exarray.data, 1, data);
    end if;

    arrayUpdate(data, index, SOME(value));
    Dangerous.arrayUpdateNoBoundsChecking(exarray.numberOfElements, 1, numberOfElements+1);
  else
    fail();
  end if;
end set;

function add "O(n)
  Sets the first unused element to the given value."
  input T value;
  input output ExpandableArray<T> exarray;
  output Integer index;
protected
  Integer numberOfElements = Dangerous.arrayGetNoBoundsChecking(exarray.numberOfElements, 1);
  Integer capacity = Dangerous.arrayGetNoBoundsChecking(exarray.capacity, 1);
  array<Option<T>> data = Dangerous.arrayGetNoBoundsChecking(exarray.data, 1);
algorithm
  for i in 1:capacity loop
    if isNone(Dangerous.arrayGetNoBoundsChecking(data, i)) then
      index := i;
      arrayUpdate(data, index, SOME(value));
      Dangerous.arrayUpdateNoBoundsChecking(exarray.numberOfElements, 1, numberOfElements+1);
      return;
    end if;
  end for;

  index := capacity+1;
  exarray := set(index, value, exarray);
end add;

function delete "O(1)
  Deletes the value of the element at the given index.
  Fails if there is no value stored at the given index."
  input Integer index;
  input output ExpandableArray<T> exarray;
protected
  Integer numberOfElements = Dangerous.arrayGetNoBoundsChecking(exarray.numberOfElements, 1);
  Integer capacity = Dangerous.arrayGetNoBoundsChecking(exarray.capacity, 1);
  array<Option<T>> data = Dangerous.arrayGetNoBoundsChecking(exarray.data, 1);
algorithm
  if index >= 1 and index <= capacity and isSome(Dangerous.arrayGetNoBoundsChecking(data, index)) then
    arrayUpdate(data, index, NONE());
    Dangerous.arrayUpdateNoBoundsChecking(exarray.numberOfElements, 1, numberOfElements-1);
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
  Integer capacity = Dangerous.arrayGetNoBoundsChecking(exarray.capacity, 1);
  array<Option<T>> data = Dangerous.arrayGetNoBoundsChecking(exarray.data, 1);
algorithm
  if index >= 1 and index <= capacity and isSome(Dangerous.arrayGetNoBoundsChecking(data, index)) then
    arrayUpdate(data, index, SOME(value));
  else
    fail();
  end if;
end update;

function shrink "O(n)
  Reduces the capacity of the ExpandableArray to the number of elements.
  Be careful: This may change the indices of the elements."
  input output ExpandableArray<T> exarray;
protected
  Integer numberOfElements = Dangerous.arrayGetNoBoundsChecking(exarray.numberOfElements, 1);
  Integer back = Dangerous.arrayGetNoBoundsChecking(exarray.capacity, 1);
  array<Option<T>> data = Dangerous.arrayGetNoBoundsChecking(exarray.data, 1);
  array<Option<T>> newData;
algorithm
  if back == 0 then
    return;
  end if;

  newData := Dangerous.arrayCreateNoInit(numberOfElements, Dangerous.arrayGetNoBoundsChecking(data, 1));

  for i in 1:numberOfElements loop
    if isNone(Dangerous.arrayGetNoBoundsChecking(data, i)) then
      while isNone(Dangerous.arrayGetNoBoundsChecking(data, back)) loop
        back := back-1;
      end while;
      Dangerous.arrayUpdateNoBoundsChecking(newData, i, Dangerous.arrayGetNoBoundsChecking(data, back));
    else
      Dangerous.arrayUpdateNoBoundsChecking(newData, i, Dangerous.arrayGetNoBoundsChecking(data, i));
    end if;
  end for;

  Dangerous.arrayUpdateNoBoundsChecking(exarray.capacity, 1, numberOfElements);
  Dangerous.arrayUpdateNoBoundsChecking(exarray.data, 1, newData);
end shrink;

function dump "O(n)
  Dumps all elements with the given print function."
  input ExpandableArray<T> exarray;
  input String header;
  input PrintFunction func;

  partial function PrintFunction
    input T t;
    output String str;
  end PrintFunction;
protected
  Integer numberOfElements = Dangerous.arrayGetNoBoundsChecking(exarray.numberOfElements, 1);
  Integer capacity = Dangerous.arrayGetNoBoundsChecking(exarray.capacity, 1);
  T value;
  array<Option<T>> data = Dangerous.arrayGetNoBoundsChecking(exarray.data, 1);
algorithm
  print(header + " (" + intString(numberOfElements) + "/" + intString(capacity) + ")\n");
  print("========================================\n");

  if numberOfElements == 0 then
    print("<empty>\n");
  else
    for i in 1:capacity loop
      if isSome(Dangerous.arrayGetNoBoundsChecking(data, i)) then
        SOME(value) := Dangerous.arrayGetNoBoundsChecking(data, i);
        numberOfElements := numberOfElements-1;
        print(intString(i) + ": " + func(value) + "\n");
        if numberOfElements == 0 then
          return;
        end if;
      end if;
    end for;
  end if;
end dump;

annotation(__OpenModelica_Interface="util");
end ExpandableArray;
