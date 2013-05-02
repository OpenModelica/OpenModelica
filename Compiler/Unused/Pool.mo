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

encapsulated package Pool
" file:  Pool.mo
  package:     Pool
  description: A MetaModelica Pool implementation
  @author:     adrpo

  RCS: $Id: Pool.mo 9152 2011-05-28 08:08:28Z adrpo $

  A pool is an array of objects of any type that can grow/shrink
  when things are added to it or deleted.

  TODO! FIXME!
    check why the auto grow doesn't work!
    seems also that the add unique doesn't work correctly,
    of course it doesn't as we have -1 as autoUpdateId!
    DAMN we need a user-supplied comparison function inside
    the POOL that ignores the id when comparing."

// the type of the pool elements
replaceable type TV subtypeof Any;

/*
partial function FuncCompareValue
  input Option<TV>
end FuncCompareValue;
*/

public
uniontype Pool
  record POOL
    Integer filledSize;
    Integer maxSize;
    array<Option<TV>> elements;
    // Option<FuncCompareValue> inCompareFunc;
    Integer lastAdded "the index of the last added element; important for addUnique, to know the index of last added as it may not be filledSize";
    String name "a name so you know which one it is if you have more";
  end POOL;
end Pool;

constant Integer autoId = -1;

protected
import Util;

public function name
"return the name of the pool"
  input Pool<TV> pool;
  output String name;
algorithm
  POOL(name = name) := pool;
end name;

public
function create
"@creates a pool of objects with default size"
  input String name;
  input Integer defaultPoolSize;
  output Pool<TV> outPool;
protected
  replaceable type TV subtypeof Any;
  array<Option<TV>> arr;
algorithm
  arr := arrayCreate(defaultPoolSize, NONE());
  outPool := POOL(0, defaultPoolSize, arr, 0, name);
end create;

public
function clone
"@clones the pool"
  input Pool<TV> inPool;
  output Pool<TV> outPool;
protected
  replaceable type TV subtypeof Any;
  Integer filledSize;
  Integer maxSize;
  array<Option<TV>> elements, newElements;
  Integer lastAdded;
  String n;
algorithm
  POOL(filledSize, maxSize, elements, lastAdded, n) := inPool;
  newElements := arrayCopy(elements);
  outPool := POOL(filledSize, maxSize, elements, lastAdded, n);
end clone;

public
function clear
"@clears the pool of all elements, the size stay in place"
  input Pool<TV> inPool;
  output Pool<TV> outPool;
protected
  replaceable type TV subtypeof Any;
  Integer filledSize;
  Integer maxSize;
  array<Option<TV>> elements;
  Integer lastAdded;
  String n;
algorithm
  POOL(filledSize, maxSize, elements, lastAdded, n) := inPool;
  elements := arrayCreate(maxSize, NONE());
  outPool := POOL(0, maxSize, elements, 0, n);
end clear;

public
function delete
"@deletes the pool by creating a pool with 0 elements"
  input Pool<TV> inPool;
  input Integer defaultPoolSize;
  output Pool<TV> outPool;
protected
  replaceable type TV subtypeof Any;
algorithm
  outPool := create(name(inPool), 0);
end delete;

function add
"@adds an element to the pool.
  it gets an optional function that updates the index in the element"
  input Pool<TV> inPool;
  input TV inElement;
  input Option<FuncType> inUpdateFuncOpt;
  output Pool<TV> outPool;
  output Integer outIndex;
protected
  replaceable type TV subtypeof Any;
  partial function FuncType
    input TV inEl;
    input Integer indexUpdate;
    output TV outEl;
  end FuncType;
algorithm
  (outPool, outIndex) := matchcontinue(inPool, inElement, inUpdateFuncOpt)
    local
      Integer fs, mx, newIndex;
      array<Option<TV>> arr, newArr;
      TV el;
      String n;

    case (POOL(fs, mx, arr, _, n), el, inUpdateFuncOpt)
      equation
  // no need to grow the array
  newIndex = fs + 1;
  true = intLt(newIndex, mx);

  // update the index inside the element (if an update function is given)
  el = updateElementIndex(el, inUpdateFuncOpt, newIndex);

  arr = arrayUpdate(arr, newIndex, SOME(el));
  fs = newIndex;
      then
  (POOL(fs, mx, arr, fs, n), fs);

    case (POOL(fs, mx, arr, _, n), el, inUpdateFuncOpt)
      equation
  // need to grow the array
  newIndex = fs + 1;
  false = intLt(newIndex, mx);
  // grow it by 1.4
  mx = realInt(realMul(intReal(mx), 1.4));
  newArr = arrayCreate(mx, NONE());
  newArr = Util.arrayCopy(arr, newArr);

  // update the index inside the element (if an update function is given)
  el = updateElementIndex(el, inUpdateFuncOpt, newIndex);

  newArr = arrayUpdate(newArr, newIndex, SOME(el));
  fs = newIndex;
      then
  (POOL(fs, mx, newArr, fs, n), fs);
  end matchcontinue;
end add;

function addUnique
"@adds an element to the pool, if it exists, return its index.
  it gets an:
  - optional function that updates the index in the element
  - optional function to check for equality of two elements
    + this is needed in case the auto update is used because then the index should not be checked for equality"
  input Pool<TV> inPool;
  input TV inElement;
  input Option<FuncType> inUpdateFuncOpt "to auto-update the id in element";
  input Option<FuncTypeEquality> inEqualityCheckFunc "to check for element equality disregarding the id as it should be auto-updated!";
  output Pool<TV> outPool;
  output Integer outIndex;
protected
  replaceable type TV subtypeof Any;
  partial function FuncType
    input TV inEl;
    input Integer indexUpdate;
    output TV outEl;
  end FuncType;
  partial function FuncTypeEquality
    input Option<TV> inElOld;
    input Option<TV> inElNew;
    output Boolean isEqual;
  end FuncTypeEquality;
algorithm
  (outPool, outIndex) := matchcontinue(inPool, inElement, inUpdateFuncOpt, inEqualityCheckFunc)
    local
      Pool<TV> pool;
      Integer index, newIndex, fs, mx;
      TV el;
      array<Option<TV>> arr;
      String n;

    // pool is empty
    case (pool, el, inUpdateFuncOpt, inEqualityCheckFunc)
      equation
  // no elements, yet, add it
  true = intEq(next(pool), 1);
  (pool, index) = add(inPool, el, inUpdateFuncOpt);
      then
  (pool, index);

    // pool is not empty, search for it
    case (pool, el, inUpdateFuncOpt, inEqualityCheckFunc)
      equation
  // see if is in there, 0 means not in there!
  0 = member(pool, el, inEqualityCheckFunc);
  (pool, index) = add(inPool, el, inUpdateFuncOpt);
      then
  (pool, index);

    // pool is not empty, search for it
    case (pool as POOL(fs, mx, arr, _, n), el, _, inEqualityCheckFunc)
      equation
  // see if is in there, 0 means not in there!
  index = member(pool, el, inEqualityCheckFunc);
      then
  (POOL(fs, mx, arr, index, n), index);
  end matchcontinue;
end addUnique;

function member
"@if the given element is a member of the pool, returns its index,
  if none is found returns 0"
  input Pool<TV> inPool;
  input TV inElement;
  input Option<FuncTypeEquality> inEqualityCheckFunc "to check for element equality disregarding the id as it should be auto-updated!";
  output Integer outIndex;
protected
  replaceable type TV subtypeof Any;
  partial function FuncTypeEquality
    input Option<TV> inElOld;
    input Option<TV> inElNew;
    output Boolean isEqual;
  end FuncTypeEquality;
algorithm
  outIndex := matchcontinue(inPool, inElement, inEqualityCheckFunc)
    local
      Pool<TV> pool;
      Integer index;
      FuncTypeEquality equalityCheckFunc;

    // pool is empty
    case (pool, inElement, inEqualityCheckFunc)
      equation
  // no elements, yet, add it
  true = intEq(next(pool), 1);
      then
  0;

    // pool is not empty, search for it, with an equality check function
    case (pool, inElement, SOME(equalityCheckFunc))
      equation
  index = Util.arrayMemberEqualityFunc(members(pool), next(pool), SOME(inElement), equalityCheckFunc);
      then
  index;

    // pool is not empty, search for it, without an equality check function!
    case (pool, inElement, NONE())
      equation
  index = Util.arrayMember(members(pool), next(pool), SOME(inElement));
      then
  index;
  end matchcontinue;
end member;

function get
"@gets the element at index or fails if is NONE"
  input Pool<TV> inPool;
  input Integer inIndex;
  output TV outElement;
protected
  replaceable type TV subtypeof Any;
algorithm
  outElement := matchcontinue(inPool, inIndex)
    local
      Pool<TV> pool;
      TV el;

    // search for it
    case (pool, inIndex)
      equation
  SOME(el) = arrayGet(members(pool), inIndex);
      then
  el;

    // failure
    case (pool, inIndex)
      equation
  print("Pool.get name: " +& name(pool) +& " Error: Element with index: " +& intString(inIndex) +& " not found in pool!\n");
      then
  fail();
  end matchcontinue;
end get;

function set
"@sets the element at index or fails"
  input Pool<TV> inPool;
  input Integer inIndex;
  input TV inElement;
  output Pool<TV> outPool;
protected
  replaceable type TV subtypeof Any;
algorithm
  outPool := matchcontinue(inPool, inIndex, inElement)
    local
      Pool<TV> pool;
      TV el;
      Integer fs, mx, la;
      array<Option<TV>> elements;
      String n;

    // set it!
    // TODO! FIXME! update filledSize if inIndex > filledSize, check for max, grow array if inIndex > max
    case (POOL(fs, mx, elements, la, n), inIndex, el)
      equation
  elements = arrayUpdate(elements, inIndex, SOME(el));
      then
  POOL(fs, mx, elements, la, n);

    // failure
    case (pool, inIndex, _)
      equation
  print("Pool.set name: " +& name(pool) +& " Error: Element with index: " +& intString(inIndex) +& " could not be set in pool!\n");
      then
  fail();
  end matchcontinue;
end set;

function empty
"@is the pool empty?"
  input Pool<TV> inPool;
  output Boolean isEmpty;
protected
  replaceable type TV subtypeof Any;
  Integer fs;
algorithm
  POOL(filledSize = fs) := inPool;
  isEmpty := intEq(fs, 0);
end empty;

function next
"@which will be the next element in pool?, returns filled size + 1"
  input Pool<TV> inPool;
  output Integer outNextIndex;
protected
  replaceable type TV subtypeof Any;
  Integer fs;
algorithm
  POOL(filledSize = fs) := inPool;
  outNextIndex := fs + 1;
end next;

function lastAdded
"@which will be the next element in pool?, returns filled size + 1"
  input Pool<TV> inPool;
  output Integer outLastAddedIndex;
protected
  replaceable type TV subtypeof Any;
  Integer fs;
algorithm
  POOL(lastAdded = outLastAddedIndex) := inPool;
end lastAdded;

function size
"@what is the maximum size"
  input Pool<TV> inPool;
  output Integer outMaxSize;
protected
  replaceable type TV subtypeof Any;
algorithm
  POOL(maxSize = outMaxSize) := inPool;
end size;

function members
"@returns the elements array from the pool.
  observe that the elements are stored as SOME(el) or NONE()"
  input Pool<TV> inPool;
  output array<Option<TV>> outElements;
protected
  replaceable type TV subtypeof Any;
algorithm
  POOL(elements = outElements) := inPool;
end members;

protected function updateElementIndex
"@if the given function to update the index is SOME then use it to update the index inside the element"
  input TV inElement;
  input Option<FuncType> inUpdateFuncOpt;
  input Integer updatedIndex;
  output TV outElement;
protected
  replaceable type TV subtypeof Any;
  partial function FuncType
    input TV inEl;
    input Integer indexUpdate;
    output TV outEl;
  end FuncType;
algorithm
  outElement := matchcontinue(inElement, inUpdateFuncOpt, updatedIndex)
    local
      FuncType func;
      TV el;

    // sorry, no update function
    case (inElement, NONE(), updatedIndex) then inElement;

    // yeeehaa, we have an update function
    case (inElement, SOME(func), updatedIndex)
      equation
  el = func(inElement, updatedIndex);
      then
  el;

  end matchcontinue;
end updateElementIndex;

end Pool;

