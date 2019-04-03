final encapsulated package UtilTest

import Util;
import List;

function listRangeString
"Takes start, stop index, generates a list<Integer> which it then
transforms into a list<String>"
  input Integer start;
  input Integer stop;
  output Integer sum;
  output list<String> ss;
protected
  list<Integer> is;
algorithm
  is := List.intRange2(start,stop);
  is := List.map1(is, intMul, 3);
  ss := List.map(is, intString);
  sum := List.fold(is, intAdd, 0);
end listRangeString;

function getIntOption
  input Option<Integer> io;
  output Integer i;
algorithm
  SOME(i) := io;
end getIntOption;

function listMapGetOption
  input list<Option<Integer>> ios;
  output list<Integer> is1;
  output list<Integer> is2;
algorithm
  is1 := List.map(ios, Util.getOption);
  is2 := List.map(ios, getIntOption);
end listMapGetOption;

function listMap1r
  input list<String> ss;
  input String s;
  output list<String> oss;
algorithm
  oss := List.map1r(ss, stringAppend, s);
end listMap1r;

function listSplitOnTrue
  input list<Option<Integer>> xs;
  output list<Option<Integer>> somes;
  output list<Option<Integer>> nones;
algorithm
  (somes,nones) := List.splitOnTrue(xs, Util.isSome);
end listSplitOnTrue;

function listMapTuple21
  input list<tuple<String,Integer>> xs;
  output list<String> ys;
algorithm
  ys := List.map(xs, Util.tuple21);
end listMapTuple21;

function listListMap
  input list<list<Integer>> xs;
  output list<list<String>> ys;
algorithm
  ys := List.mapList(xs, intString);
end listListMap;

function listMapMap
  input list<Integer> xs;
  output list<String> ys;
algorithm
  ys := List.mapMap(xs, intReal, realString);
end listMapMap;

function threadMapList
  input list<list<Integer>> l1;
  input list<list<Integer>> l2;
  output list<list<Integer>> l3;
algorithm
  l3 := List.threadMapList(l1, l2, intAdd);
end threadMapList;

function isThree
  input Integer i;
  output Boolean b;
algorithm
  b := intEq(i, 3);
end isThree;

function splitOnFirstMatch
  input list<Integer> l1;
  output list<Integer> l2;
  output list<Integer> l3;
algorithm
  (l2, l3) := List.splitOnFirstMatch(l1, isThree);
end splitOnFirstMatch;

function incAdd
  input tuple<Integer, Integer> inTuple;
  output tuple<Integer, Integer> outTuple;
protected
  Integer i, j;
algorithm
  (i, j) := inTuple;
  outTuple := (i + 1, j + i);
end incAdd;

function mapFoldListTuple
  input list<list<Integer>> l1;
  output list<list<Integer>> l2;
  output Integer lsum;
algorithm
  (l2, lsum) := List.mapFoldListTuple(l1, incAdd, 0);
end mapFoldListTuple;

end UtilTest;
