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
  This is a base class for a dynamic array. To use it, extend the package and
  redeclare T and DUMMY. T is the type of the elements stored in the array,
  while DUMMY is a constant of that type with any value. The purpose of DUMMY is
  to allow the use of arrayCreateNoInit, since it requires an element to be
  provided to fix the type of the array, so the actual value of DUMMY is not
  important.

  An example of how to declare a string vector type:

    encapsulated package StringVector
      import BaseVector;
      extends BaseVector(redeclare type T = String,
                         redeclare constant String DUMMY = "");
    end StringVector;

  BaseVector also has a replaceable constant growthFactor, which decides how
  fast the vector grows when the available space runs out. The default is 2,
  i.e. the vector doubles in size when it runs out of space.
"

replaceable type T = Integer;
replaceable constant T DUMMY = 0;
replaceable constant Real growthFactor = 2;

protected
import MetaModelica.Dangerous;

public
uniontype Vector
  record VECTOR
    array<T> data;
    Integer sz;
    Integer capacity;
  end VECTOR;
end Vector;

function new
  "Creates a new dynamic array, with a certain capacity."
  input Integer inSize;
  output Vector outVector;
protected
  array<T> data;
algorithm
  assert(growthFactor > 1.0, "growthFactor must be larger than 1!");
  data := Dangerous.arrayCreateNoInit(inSize, DUMMY);
  outVector := VECTOR(data, 0, inSize);
end new;

function add
  "Appends a value to the end of the dynamic array."
  input T inValue;
  input Vector inVector;
  output Vector outVector = inVector;
algorithm
  outVector := match outVector
    local
      array<T> data;
      Integer capacity;

    case VECTOR()
      algorithm
        if outVector.sz >= outVector.capacity then
          (data, capacity) :=
            growArray(outVector.data, outVector.capacity);
          outVector.data := data;
          outVector.capacity := capacity;
        end if;

        outVector.sz := outVector.sz + 1;
        arrayUpdate(outVector.data, outVector.sz, inValue);
      then
        outVector;
  end match;
end add;

function set
  "Sets the element at the given index to the given value. Fails if the index is
   out of bounds."
  input Vector inVector;
  input Integer inIndex;
  input T inValue;
  output Vector outVector = inVector;
protected
  array<T> data;
  Integer sz;
algorithm
  VECTOR(data = data, sz = sz) := inVector;

  if inIndex <= sz then
    arrayUpdate(data, inIndex, inValue);
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
  array<T> data;
  Integer sz;
algorithm
  VECTOR(data = data, sz = sz) := inVector;

  if inIndex > 0 and inIndex <= sz then
    outValue := Dangerous.arrayGetNoBoundsChecking(data, inIndex);
  else
    fail();
  end if;
end get;

protected

function growArray
  input array<T> inArray;
  input Integer inSize;
  output array<T> outArray;
  output Integer outSize = integer(ceil(inSize * growthFactor));
algorithm
  outArray := Dangerous.arrayCreateNoInit(outSize, DUMMY);

  for i in 1:inSize loop
    arrayUpdate(outArray, i, Dangerous.arrayGetNoBoundsChecking(inArray, i));
  end for;
end growArray;

annotation(__OpenModelica_Interface="util", __OpenModelica_isBaseClass=true);
end BaseVector;
