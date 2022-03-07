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

encapsulated package DoubleEnded<T>
"Implementation of a mutable double-ended list. O(1) push_front, push_back, pop_front, toListAndClear"
public
import Mutable;
uniontype MutableList<T>
  record LIST
    Mutable<Integer> length;
    Mutable<list<T>> front;
    Mutable<list<T>> back;
  end LIST;
end MutableList;

protected
import GCExt;
import MetaModelica.Dangerous;

public impure function new<T>
  input T first;
  output MutableList<T> delst;
protected
  list<T> lst = {first};
algorithm
  delst := LIST(Mutable.create(1),Mutable.create(lst),Mutable.create(lst));
end new;

public impure function fromList<T>
  input list<T> lst;
  output MutableList<T> delst;
protected
  list<T> head,tail,tmp;
  Integer length;
  T t;
algorithm
  if listEmpty(lst) then
    delst := LIST(Mutable.create(0),Mutable.create({}),Mutable.create({}));
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
  delst := LIST(Mutable.create(length),Mutable.create(head),Mutable.create(tail));
end fromList;

public impure function empty<T>
  input T dummy;
  output MutableList<T> delst;
algorithm
  delst := LIST(Mutable.create(0),Mutable.create({}),Mutable.create({}));
end empty;

public function length<T>
  input MutableList<T> delst;
  output Integer length;
algorithm
  length := Mutable.access(delst.length);
end length;

public function pop_front<T>
  input MutableList<T> delst;
  output T elt;
protected
  Integer length = Mutable.access(delst.length);
  list<T> lst;
algorithm
  true := length>0;
  Mutable.update(delst.length, length-1);
  if length==1 then
    Mutable.update(delst.front, {});
    Mutable.update(delst.back, {});
    return;
  end if;
  elt::lst := Mutable.access(delst.front);
  Mutable.update(delst.front, lst);
end pop_front;

public function currentBackCell<T>
  input MutableList<T> delst;
  output list<T> last;
algorithm
  last := Mutable.access(delst.back);
end currentBackCell;

public function push_front<T>
  input MutableList<T> delst;
  input T elt;
protected
  Integer length=Mutable.access(delst.length);
  list<T> lst;
algorithm
  Mutable.update(delst.length, length+1);
  if length==0 then
    lst := {elt};
    Mutable.update(delst.front, lst);
    Mutable.update(delst.back, lst);
    return;
  end if;
  lst := Mutable.access(delst.front);
  Mutable.update(delst.front, elt::lst);
end push_front;

public function push_list_front<T>
  input MutableList<T> delst;
  input list<T> lst;
protected
  Integer length = Mutable.access(delst.length), lstLength;
  list<T> work, oldHead, tmp, head;
  T t;
algorithm
  lstLength := listLength(lst);
  if lstLength==0 then
    return;
  end if;
  Mutable.update(delst.length, length+lstLength);
  t::tmp := lst;
  head := {t};
  oldHead := Mutable.access(delst.front);
  Mutable.update(delst.front, head);
  for l in tmp loop
    work := {l};
    Dangerous.listSetRest(head, work);
    head := work;
  end for;
  if length==0 then
    Mutable.update(delst.back, head);
  else
    Dangerous.listSetRest(head, oldHead);
  end if;
end push_list_front;

public function push_back<T>
  input MutableList<T> delst;
  input T elt;
protected
  Integer length = Mutable.access(delst.length);
  list<T> lst;
algorithm
  Mutable.update(delst.length, length+1);
  if length==0 then
    lst := {elt};
    Mutable.update(delst.front, lst);
    Mutable.update(delst.back, lst);
    return;
  end if;
  lst := {elt};
  Dangerous.listSetRest(Mutable.access(delst.back), lst);
  Mutable.update(delst.back, lst);
end push_back;

public function push_list_back<T>
  input MutableList<T> delst;
  input list<T> lst;
protected
  Integer length=Mutable.access(delst.length), lstLength;
  list<T> tail, tmp;
  T t;
algorithm
  lstLength := listLength(lst);
  if lstLength==0 then
    return;
  end if;
  Mutable.update(delst.length, length+lstLength);
  t := listGet(lst, 1);
  tmp := {t};
  if length==0 then
    Mutable.update(delst.front, tmp);
  else
    Dangerous.listSetRest(Mutable.access(delst.back), tmp);
  end if;
  tail := tmp;
  for l in listRest(lst) loop
    tmp := {l};
    Dangerous.listSetRest(tail, tmp);
    tail := tmp;
  end for;
  Mutable.update(delst.back, tail);
end push_list_back;

public impure function toListAndClear<T>
  input MutableList<T> delst;
  input list<T> prependToList = {};
  output list<T> res;
algorithm
  if Mutable.access(delst.length)==0 then
    res := prependToList;
    return;
  end if;
  res := Mutable.access(delst.front);
  if not listEmpty(prependToList) then
    Dangerous.listSetRest(Mutable.access(delst.back), prependToList);
  end if;
  Mutable.update(delst.back, {});
  Mutable.update(delst.front, {});
  Mutable.update(delst.length, 0);
end toListAndClear;

public impure function toListNoCopyNoClear<T>
  "Returns the working list, which may be changed later on!"
  input MutableList<T> delst;
  output list<T> res;
algorithm
  res := Mutable.access(delst.front);
end toListNoCopyNoClear;

public impure function clear<T>
  input MutableList<T> delst;
protected
  list<T> lst;
algorithm
  lst := Mutable.access(delst.front);
  Mutable.update(delst.back, {});
  Mutable.update(delst.front, {});
  Mutable.update(delst.length, 0);
  for l in lst loop
    GCExt.free(l);
  end for;
end clear;

public impure function mapNoCopy_1<T, ArgT1>
  input MutableList<T> delst;
  input MapFunc inMapFunc;
  input ArgT1 inArg1;
  partial function MapFunc
    input T inElement;
    input ArgT1 inArg1;
    output T outElement;
  end MapFunc;
protected
  list<T> lst=Mutable.access(delst.front);
algorithm
  while not listEmpty(lst) loop
    Dangerous.listSetFirst(lst, inMapFunc(listGet(lst,1), inArg1));
    _::lst := lst;
  end while;
end mapNoCopy_1;

public impure function mapFoldNoCopy<T, ArgT1>
  input MutableList<T> delst;
  input MapFunc inMapFunc;
  input output ArgT1 arg;
  partial function MapFunc
    input output T element;
    input output ArgT1 arg;
  end MapFunc;
protected
  T element;
  list<T> lst=Mutable.access(delst.front);
algorithm
  while not listEmpty(lst) loop
    (element,arg) := inMapFunc(listGet(lst,1), arg);
    Dangerous.listSetFirst(lst, element);
    _::lst := lst;
  end while;
end mapFoldNoCopy;

annotation(__OpenModelica_Interface="util");

end DoubleEnded;
