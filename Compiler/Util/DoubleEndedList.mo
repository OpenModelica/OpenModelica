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

impure function empty
  input T dummy;
  output DoubleEndedList<T> delst;
algorithm
  delst := LIST(arrayCreate(1,0),arrayCreate(1,{}),arrayCreate(1,{}));
end empty;

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

function toListAndClear
  input DoubleEndedList<T> delst;
  output list<T> res;
algorithm
  res := arrayGet(delst.front,1);
  arrayUpdate(delst.back, 1, {});
  arrayUpdate(delst.front, 1, {});
  arrayUpdate(delst.length, 1, 0);
end toListAndClear;

function clear
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

annotation(__OpenModelica_Interface="backend");
end DoubleEndedList;
