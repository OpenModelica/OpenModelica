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

encapsulated uniontype DoubleEndedList<T> "Implementation of a mutable double-ended list. O(1) push_front, push_back, pop_front, toListAndClear"

record LIST
  array<Integer> length;
  array<list<T>> front, back;
end LIST;

protected
import GC;
import MetaModelica.Dangerous;

public

impure function new
  input T first;
  output DoubleEndedList<T> delst;
protected
  list<T> lst={first};
algorithm
  delst := LIST(arrayCreate(1,1),arrayCreate(1,lst),arrayCreate(1,lst));
end new;

impure function fromList
  input list<T> lst;
  output DoubleEndedList<T> delst;
protected
  list<T> head,tail,tmp;
  Integer length;
  T t;
algorithm
  if listEmpty(lst) then
    delst := LIST(arrayCreate(1,0),arrayCreate(1,{}),arrayCreate(1,{}));
    return;
  end if;
  t::tmp := lst;
  head := {t};
  tail := head;
  length := 1;
  for l in tmp loop
    tmp := {l};
    Dangerous.listSetRest(tail, tmp);
    tail := tmp;
    length := length+1;
  end for;
  delst := LIST(arrayCreate(1,length),arrayCreate(1,head),arrayCreate(1,tail));
end fromList;

impure function empty
  input T dummy;
  output DoubleEndedList<T> delst;
algorithm
  delst := LIST(arrayCreate(1,0),arrayCreate(1,{}),arrayCreate(1,{}));
end empty;

function length
  input DoubleEndedList<T> delst;
  output Integer length;
algorithm
  length := arrayGet(delst.length,1);
end length;

function pop_front
  input DoubleEndedList<T> delst;
  output T elt;
protected
  Integer length=arrayGet(delst.length,1);
  list<T> lst;
algorithm
  true := length>0;
  arrayUpdate(delst.length, 1, length-1);
  if length==1 then
    arrayUpdate(delst.front, 1, {});
    arrayUpdate(delst.back, 1, {});
    return;
  end if;
  elt::lst := arrayGet(delst.front,1);
  arrayUpdate(delst.front, 1, lst);
end pop_front;

function currentBackCell
  input DoubleEndedList<T> delst;
  output list<T> last;
algorithm
  last := arrayGet(delst.back,1);
end currentBackCell;

function push_front
  input DoubleEndedList<T> delst;
  input T elt;
protected
  Integer length=arrayGet(delst.length,1);
  list<T> lst;
algorithm
  arrayUpdate(delst.length, 1, length+1);
  if length==0 then
    lst := {elt};
    arrayUpdate(delst.front, 1, lst);
    arrayUpdate(delst.back, 1, lst);
    return;
  end if;
  lst := arrayGet(delst.front,1);
  arrayUpdate(delst.front, 1, elt::lst);
end push_front;

function push_list_front
  input DoubleEndedList<T> delst;
  input list<T> lst;
protected
  Integer length=arrayGet(delst.length,1), lstLength;
  list<T> work, oldHead, tmp, head;
  T t;
algorithm
  lstLength := listLength(lst);
  if lstLength==0 then
    return;
  end if;
  arrayUpdate(delst.length, 1, length+lstLength);
  t::tmp := lst;
  head := {t};
  oldHead := arrayGet(delst.front, 1);
  arrayUpdate(delst.front, 1, head);
  for l in tmp loop
    work := {l};
    Dangerous.listSetRest(head, work);
    head := work;
  end for;
  if length==0 then
    arrayUpdate(delst.back, 1, head);
  else
    Dangerous.listSetRest(head, oldHead);
  end if;
end push_list_front;

function push_back<T>
  input DoubleEndedList<T> delst;
  input T elt;
protected
  Integer length=arrayGet(delst.length,1);
  list<T> lst;
algorithm
  arrayUpdate(delst.length, 1, length+1);
  if length==0 then
    lst := {elt};
    arrayUpdate(delst.front, 1, lst);
    arrayUpdate(delst.back, 1, lst);
    return;
  end if;
  lst := {elt};
  Dangerous.listSetRest(arrayGet(delst.back,1), lst);
  arrayUpdate(delst.back, 1, lst);
end push_back;

function push_list_back
  input DoubleEndedList<T> delst;
  input list<T> lst;
protected
  Integer length=arrayGet(delst.length,1), lstLength;
  list<T> tail, tmp;
  T t;
algorithm
  lstLength := listLength(lst);
  if lstLength==0 then
    return;
  end if;
  arrayUpdate(delst.length, 1, length+lstLength);
  t := listGet(lst, 1);
  tmp := {t};
  if length==0 then
    arrayUpdate(delst.front, 1, tmp);
  else
    Dangerous.listSetRest(arrayGet(delst.back, 1), tmp);
  end if;
  tail := tmp;
  for l in listRest(lst) loop
    tmp := {l};
    Dangerous.listSetRest(tail, tmp);
    tail := tmp;
  end for;
  arrayUpdate(delst.back, 1, tail);
end push_list_back;

impure function toListAndClear
  input DoubleEndedList<T> delst;
  input list<T> prependToList={};
  output list<T> res;
algorithm
  if arrayGet(delst.length,1)==0 then
    res := prependToList;
    return;
  end if;
  res := arrayGet(delst.front,1);
  if not listEmpty(prependToList) then
    Dangerous.listSetRest(arrayGet(delst.back,1), prependToList);
  end if;
  arrayUpdate(delst.back, 1, {});
  arrayUpdate(delst.front, 1, {});
  arrayUpdate(delst.length, 1, 0);
end toListAndClear;

impure function toListNoCopyNoClear "Returns the working list, which may be changed later on!"
  input DoubleEndedList<T> delst;
  output list<T> res;
algorithm
  res := arrayGet(delst.front,1);
end toListNoCopyNoClear;

impure function clear
  input DoubleEndedList<T> delst;
protected
  list<T> lst;
algorithm
  lst := arrayGet(delst.front,1);
  arrayUpdate(delst.back, 1, {});
  arrayUpdate(delst.front, 1, {});
  arrayUpdate(delst.length, 1, 0);
  for l in lst loop
    GC.free(l);
  end for;
end clear;

impure function mapNoCopy_1<ArgT1>
  input DoubleEndedList<T> delst;
  input MapFunc inMapFunc;
  input ArgT1 inArg1;
  partial function MapFunc
    input T inElement;
    input ArgT1 inArg1;
    output T outElement;
  end MapFunc;
protected
  list<T> lst=arrayGet(delst.front,1);
algorithm
  while not listEmpty(lst) loop
    Dangerous.listSetFirst(lst, inMapFunc(listGet(lst,1), inArg1));
    _::lst := lst;
  end while;
end mapNoCopy_1;

impure function mapFoldNoCopy<ArgT1>
  input DoubleEndedList<T> delst;
  input MapFunc inMapFunc;
  input output ArgT1 arg;
  partial function MapFunc
    input output T element;
    input output ArgT1 arg;
  end MapFunc;
protected
  T element;
  list<T> lst=arrayGet(delst.front,1);
algorithm
  while not listEmpty(lst) loop
    (element,arg) := inMapFunc(listGet(lst,1), arg);
    Dangerous.listSetFirst(lst, element);
    _::lst := lst;
  end while;
end mapFoldNoCopy;

annotation(__OpenModelica_Interface="util");
end DoubleEndedList;
