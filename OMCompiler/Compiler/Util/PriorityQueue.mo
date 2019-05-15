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

encapsulated package PriorityQueue
" file:        PriorityQueue.mo
  package:     PriorityQueue
  description: ADT PriorityQueue


This data-structure is based on Brodal and Okasaki (1996)
http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.48.973

It uses a binomial heap with reasonable efficiency. It could
be made faster like in the paper by adding some additional information
to the data-type.

Note that we can make this a very general module if we have a bootstrapped
compiler. RML takes all the joy out of writing code.

TODO: Improve the efficiency as in the paper:
TODO: Implement getMin() in O(1) time
TODO: Implement insert() in O(1) time
TODO: Implement meld() in O(1) time
"

public import SimCode;

public
/* protected */
/* TODO: Hide when RML is killed */

/* This specific version... */
replaceable type Priority = Integer;
replaceable type Data = list<SimCode.SimEqSystem>;

/* Replaceable types */

replaceable function compareElement
  input Element el1;
  input Element el2;
  output Boolean b;
protected
  Priority p1,p2;
algorithm
  (p1,_) := el1;
  (p2,_) := el2;
  b := p1 <= p2;
end compareElement;

public

replaceable type Element = tuple<Priority,Data>;
type T = list<Tree>;

constant T empty = {};

/*
function isEmpty = listEmpty;
*/
function isEmpty
  input T ts;
  output Boolean isEmpty;
algorithm
  isEmpty := listEmpty(ts);
end isEmpty;

function insert
  input Element elt;
  input T ts;
  output T ots;
algorithm
  ots := ins(NODE(elt,0,{}),ts);
end insert;

function meld
  input T its1;
  input T its2;
  output T ts;
algorithm
  ts := match (its1,its2)
    local
      Tree t1,t2;
      T ts1,ts2;
    case (ts1,{}) then ts1;
    case ({},ts2) then ts2;
    case (t1::ts1,t2::ts2) then meld2(rank(t1) < rank(t2),rank(t2) < rank(t1),t1,ts1,t2,ts2);
  end match;
end meld;

function meld2
  input Boolean b1;
  input Boolean b2;
  input Tree t1;
  input T inTs1;
  input Tree t2;
  input T inTs2;
  output T ts;
algorithm
  ts := match (b1,b2,t1,inTs1,t2,inTs2)
    local
      T ts1,ts2;

    case (true,_,_,ts1,_,ts2)
      equation
        ts = meld(ts1,t2::ts2);
      then t1::ts;
    case (_,true,_,ts1,_,ts2)
      equation
        ts = meld(t1::ts1,ts2);
      then t2::ts;
    else ins(link(t1,t2), meld(inTs1,inTs2));
  end match;
end meld2;

function findMin
  input T inTs;
  output Element elt;
algorithm
  elt := match inTs
    local
      Tree t;
      Element x,y;
      T ts;

    case {t} then root(t);
    case t::ts
      equation
        x = root(t);
        y = findMin(ts);
      then if compareElement(x,y) then x else y;
  end match;
end findMin;

function deleteMin
  input T ts;
  output T ots;
protected
  T ts1,ts2;
algorithm
  (NODE(trees=ts1),ts2) := getMin(ts);
  ots := meld(listReverse(ts1),ts2);
end deleteMin;

function deleteAndReturnMin
  input T ts;
  output T ots;
  output Element elt;
protected
  T ts1,ts2;
algorithm
  (NODE(elt=elt,trees=ts1),ts2) := getMin(ts);
  ots := meld(listReverse(ts1),ts2);
end deleteAndReturnMin;

function elements
  input T ts;
  output list<Element> elts;
algorithm
  elts := elements2(ts,{});
end elements;

function elements2
  input T its;
  input list<Element> acc;
  output list<Element> elts;
algorithm
  elts := match (its,acc)
    local
      Element elt;
      T ts;
    case ({},_) then listReverse(acc);
    case (ts,_)
      equation
        (ts,elt) = deleteAndReturnMin(ts);
      then elements2(ts,elt::acc);
  end match;
end elements2;

/* TODO: Hide from user when we remove RML... */

type Rank = Integer;

uniontype Tree
  record NODE
    Element elt;
    Rank rank;
    T trees;
  end NODE;
end Tree;

protected

function root
  input Tree tree;
  output Element elt;
algorithm
  NODE(elt=elt) := tree;
end root;

function rank
  input Tree tree;
  output Rank rank;
algorithm
  NODE(rank=rank) := tree;
end rank;

function link
  input Tree t1;
  input Tree t2;
  output Tree t;
algorithm
  t := match (t1,t2)
    local
      Element e1,e2;
      Rank r1,r2;
      T ts1,ts2;
    case (NODE(e1,r1,ts1),NODE(e2,r2,ts2))
      equation
        r1 = r1+1;
        r2 = r2+1;
        ts1 = t2::ts1;
        ts2 = t1::ts2;
      then if compareElement(root(t1),root(t2)) then NODE(e1,r1,ts1) else NODE(e2,r2,ts2);
  end match;
end link;

function ins
  input Tree t;
  input T its;
  output T ots;
algorithm
  ots := match (t,its)
    local
      Tree t1,t2;
      T ts;
    case (_,{}) then {t};
    case (t1,t2::ts) then if rank(t1) < rank(t2) then t1::t2::ts else ins(link(t1,t2),ts);
  end match;
end ins;

function getMin
  input T ts;
  output Tree min;
  output T ots;
algorithm
  (min,ots) := match ts
    local
      Tree t,t1,t2;
      T ts1,ts2;
      Boolean b;
    case {t} then (t,{});
    case t1::ts1
      equation
        (t2,ts2) = getMin(ts1);
        b = compareElement(root(t1),root(t2));
      then (if b then t1 else t2, if b then ts1 else t1::ts2);
  end match;
end getMin;

annotation(__OpenModelica_Interface="backend");
end PriorityQueue;
