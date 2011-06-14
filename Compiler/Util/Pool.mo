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
" file:        Pool.mo
  package:     Pool
  description: A MetaModelica Pool implementation

  RCS: $Id: Pool.mo 9152 2011-05-28 08:08:28Z adrpo $
  
  A pool is an array of objects of any type that can grow/shrink
  when things are added to it or deleted. "

public 
uniontype Pool
  replaceable type TV subtypeof Any;
  record POOL
    Integer filledSize;
    Integer maxSize;
    array<Option<TV>> elements;
  end POOL;
end Pool;

protected 
import Util;

public
function create
"@creates a pool of objects with default size" 
  input Integer defaultPoolSize;
  output Pool<TV> outPool;
protected
  replaceable type TV subtypeof Any;
  array<Option<TV>> arr;
algorithm
  arr := arrayCreate(defaultPoolSize, NONE());
  outPool := POOL(0, defaultPoolSize, arr); 
end create;

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
      
    case (POOL(fs, mx, arr), el, inUpdateFuncOpt)
      equation
        // no need to grow the array
        newIndex = fs + 1;
        true = intLt(newIndex, mx);
        
        // update the index inside the element (if an update function is given)
        el = updateElementIndex(el, inUpdateFuncOpt, newIndex); 
        
        arr = arrayUpdate(arr, newIndex, SOME(el));
        fs = newIndex;
      then
        (POOL(fs, mx, arr), fs);
    
    case (POOL(fs, mx, arr), el, inUpdateFuncOpt)
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
        
        newArr = arrayUpdate(newArr, newIndex, SOME(inElement));
        fs = newIndex;
      then
        (POOL(fs, mx, arr), fs);
  end matchcontinue; 
end add;

function addUnique
"@adds an element to the pool, if it exists, return its index.
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
      Pool<TV> pool;
      Integer index, newIndex;
      TV el;
    
    // pool is empty
    case (pool, el, inUpdateFuncOpt)
      equation
        // no elements, yet, add it
        true = intEq(next(pool), 1); 
        (pool, index) = add(inPool, el, inUpdateFuncOpt);
      then
        (pool, index);
    
    // pool is not empty, search for it
    case (pool, el, inUpdateFuncOpt)
      equation
        // see if is in there, 0 means not in there!
        0 = member(pool, inElement);
        (pool, index) = add(inPool, el, inUpdateFuncOpt);
      then
        (pool, index);
    
    // pool is not empty, search for it
    case (pool, el, _)
      equation
        // see if is in there, 0 means not in there!
        index = member(pool, el);
      then
        (pool, index);
  end matchcontinue; 
end addUnique;

function member
"@if the given element is a member of the pool, returns its index,
  if none is found returns 0" 
  input Pool<TV> inPool;
  input TV inElement;
  output Integer outIndex;
protected
  replaceable type TV subtypeof Any;
algorithm
  outIndex := matchcontinue(inPool, inElement)
    local 
      Pool<TV> pool;
      Integer index;
    
    // pool is empty
    case (pool, inElement)
      equation
        // no elements, yet, add it
        true = intEq(next(pool), 1);
      then
        0;
    
    // pool is not empty, search for it
    case (pool, inElement)
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
        print("Element with index: " +& intString(inIndex) +& " not found in pool!\n");
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
      Integer fs, mx;
      array<Option<TV>> elements;
       
    // set it
    case (POOL(fs, mx, elements), inIndex, el)
      equation
        elements = arrayUpdate(elements, inIndex, SOME(el));
      then
        POOL(fs, mx, elements);
    
    // failure
    case (pool, inIndex, _)
      equation
        print("Element with index: " +& intString(inIndex) +& " could not be set in pool!\n");
      then
        fail();
  end matchcontinue; 
end set;

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

