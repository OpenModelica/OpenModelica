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

encapsulated package DiffAlgorithm
"Compares text and other sequences, generating a sequence of additions
and deletions.

Based on:
  Eugene Myers, An O(ND) Difference Algorithm and Its Variations,
  Algorithmica, November 1986
  http://xmailserver.org/diff2.pdf

Other resources used to understand the paper and optimize the algorithm:
  http://www.codeproject.com/Articles/42279/Investigating-Myers-diff-algorithm-Part-of
  https://code.google.com/p/google-diff-match-patch/
"

import Print;

type Diff = enumeration(Add,Delete,Equal);

function diff<T>
  input list<T> seq1;
  input list<T> seq2;
  input FunEquals equals;
  output list<tuple<Diff,list<T>>> out;
  partial function FunEquals
    input T t1,t2;
    output Boolean b;
  end FunEquals;
protected
  Integer start1, end1, start2, end2, len1, len2;
  array<T> arr1, arr2;
  list<tuple<Diff,list<T>>> prefixes = {}, suffixes = {};
algorithm
  arr1 := listArray(seq1);
  arr2 := listArray(seq2);
  start1 := 1;
  start2 := 1;
  end1 := arrayLength(arr1);
  end2 := arrayLength(arr2);
  out := diffSeq(arr1,arr2,equals,1,arrayLength(arr1),1,arrayLength(arr2));
end diff;

partial function partialPrintDiff<T>
  input list<tuple<Diff,list<T>>> seq;
  input ToString toString;
  output String res;
  partial function ToString
    input T t;
    output String o;
  end ToString;
  replaceable package DiffStrings
    // Cannot put public constants in a function declaration...
    // So we use this package instead
    constant String equalOpen;
    constant String equalClose;
    constant String addOpen;
    constant String addClose;
    constant String delOpen;
    constant String delClose;
    constant Boolean printAdd=true;
    constant Boolean printEqual=true;
    constant Boolean printDelete=true;
  end DiffStrings;
protected
  String open, close;
  list<T> ts;
  Boolean b;
  Integer i;
algorithm
  i:=Print.saveAndClearBuf();
  for d in seq loop
    (open,close,ts,b) := match d
      case (Diff.Equal,ts)
        then (DiffStrings.equalOpen,DiffStrings.equalClose,ts,DiffStrings.printEqual);
      case (Diff.Add,ts)
        then (DiffStrings.addOpen,DiffStrings.addClose,ts,DiffStrings.printAdd);
      case (Diff.Delete,ts)
        then (DiffStrings.delOpen,DiffStrings.delClose,ts,DiffStrings.printDelete);
    end match;
    if b or (DiffStrings.printEqual and DiffStrings.printAdd and DiffStrings.printDelete /* optimization */) then
      Print.printBuf(open);
      for t in ts loop
        Print.printBuf(toString(t));
      end for;
      Print.printBuf(close);
    end if;
  end for;
  res := Print.getString();
  Print.restoreBuf(i);
end partialPrintDiff;

function printDiffTerminalColor
  extends partialPrintDiff(DiffStrings(
    equalOpen="",
    equalClose="",
    addOpen="[4;32m",
    addClose="[0m",
    delOpen="[9;31m",
    delClose="[0m"
  ));
end printDiffTerminalColor;

function printDiffXml
  extends partialPrintDiff(DiffStrings(
    equalOpen="<equal>",
    equalClose="</equal>",
    addOpen="<add>",
    addClose="</add>",
    delOpen="<del>",
    delClose="</del>"
  ));
end printDiffXml;

function printActual
  extends partialPrintDiff(DiffStrings(
    equalOpen="",
    equalClose="",
    addOpen="",
    addClose="",
    delOpen="",
    delClose="",
    printDelete=false
  ));
end printActual;

protected

function diffSeq<T>
  input array<T> arr1;
  input array<T> arr2;
  input FunEquals equals;
  input Integer inStart1, inEnd1, inStart2, inEnd2;
  input list<tuple<Diff,list<T>>> inPrefixes = {}, inSuffixes = {};
  output list<tuple<Diff,list<T>>> out;
  partial function FunEquals
    input T t1,t2;
    output Boolean b;
  end FunEquals;
protected
  Integer start1=inStart1, end1=inEnd1, start2=inStart2, end2=inEnd2, len1, len2;
  list<tuple<Diff,list<T>>> prefixes = inPrefixes, suffixes = inSuffixes;
algorithm
  len1 := end1-start1+1;
  len2 := end2-start2+1;
  // Some of these tricks were inspired by diff-match-patch:
  //   https://code.google.com/p/google-diff-match-patch/
  // They do checks that are trivial and optimal, but could significantly
  //   slow down the rest of Myer's diff algorithm
  // Check if either sequence is empty. Trivial to diff.
  if len1 < 1 and len2 < 1 then
    out := listAppend(listReverse(prefixes), suffixes);
    return;
  elseif len1 < 1 then
    out := listAppend(listReverse(prefixes), (Diff.Add, list(arr2[e] for e in start2:end2))::suffixes);
    return;
  elseif len2 < 1 then
    out := listAppend(listReverse(prefixes), (Diff.Delete, list(arr1[e] for e in start1:end1))::suffixes);
    return;
  end if;
  // Note the horrible syntax for short-circuit evaluation
  // Check if the sequences are equal. Trivial diff.
  if if len1==len2 then min(equals(e1,e2) threaded for e1 in arr1, e2 in arr2) else false then
    out := {(Diff.Equal, list(arr1[e] for e in start1:end1))};
    return;
  end if;
  // trim off common prefix; guaranteed to be a good solution
  (prefixes, start1, start2) := trimCommonPrefix(arr1, start1, end1, arr2, start2, end2, equals, prefixes);
  // trim off common suffix; guaranteed to be a good solution
  (suffixes, end1, end2) := trimCommonSuffix(arr1, start1, end1, arr2, start2, end2, equals, suffixes);
  // Check if anything changed and iterate. A sequence could now be empty.
  if start1<>inStart1 or start2<>inStart2 or end1<>inEnd1 or end2<>inEnd2 then
    out := diffSeq(arr1,arr2,equals,start1,end1,start2,end2,inPrefixes=prefixes,inSuffixes=suffixes);
    return;
  else
    out := myersGreedyDiff(arr1,arr2,equals,start1,end1,start2,end2);
    // TODO: cleanup
    out := listAppend(listReverse(prefixes), listAppend(out, suffixes));
    return;
  end if;
  fail();
end diffSeq;

function myersGreedyDiff<T>
  input array<T> arr1;
  input array<T> arr2;
  input FunEquals equals;
  input Integer start1, end1, start2, end2;
  output list<tuple<Diff,list<T>>> out;
  partial function FunEquals
    input T t1,t2;
    output Boolean b;
  end FunEquals;
protected
  Integer len1, len2, maxIter, sz, middle, x, y;
  array<Integer> V;
  array<list<tuple<Integer,Integer>>> paths;
  list<tuple<Integer,Integer>> prevPath;
algorithm
  // Greedy LCS/SES
  len1 := end1-start1+1;
  len2 := end2-start2+1;
  maxIter := len1+len2;
  sz := 2*maxIter+1;
  middle := maxIter+1;
  V := arrayCreate(sz, 0);
  paths := arrayCreate(sz, {});
  for D in 0:maxIter loop
    for k in -D:2:D loop
      if k == -D or k <> D and V[k-1+middle]<V[k+1+middle] then
        x := V[k+1+middle];
        prevPath := paths[k+1+middle];
      else
        x := V[k-1+middle]+1;
        prevPath := paths[k-1+middle];
      end if;
      y := x-k;
      paths[k+middle]:=(x,y)::prevPath;
      while if x<len1 and y<len2 then equals(arr1[start1+x], arr2[start2+y]) else false loop
        x:=x+1;
        y:=y+1;
        paths[k+middle]:=(x,y)::paths[k+middle];
      end while;
      V[k+middle]:=x;
      if x>=len1 and y>=len2 then
        // Length of an SES is D
        out := myersGreedyPathToDiff(arr1,arr2,start1,start2,paths[k+middle]);
        return;
      end if;
    end for;
  end for;
  print("myersDiff: This cannot happen");
  fail();
end myersGreedyDiff;

function myersGreedyPathToDiff<T>
  input array<T> arr1, arr2;
  input Integer start1, start2;
  input list<tuple<Integer,Integer>> paths;
  output list<tuple<Diff,list<T>>> out = {};
protected
  Integer x1,x2,y1,y2;
  Diff d1 = Diff.Equal, d2 = Diff.Equal;
  list<T> lst = {};
  T t;
algorithm
  (x2,y2)::_ := paths; // starting point
  for path in listRest(paths) loop
    (x1,y1) := path;
    if x2-x1==1 and y2-y1==1 then
      // Diagonal
      d1 := Diff.Equal;
      t := arr1[start1+x1];
    elseif x2-x1==1 and y2==y1 then
      // Horizontal is addition
      d1 := Diff.Delete;
      t := arr1[start1+x1];
    elseif y2-y1==1 and x2==x1 then
      // Vertical is deletion
      d1 := Diff.Add;
      t := arr2[start2+y1];
    else
      // Else is WTF?
      print("myersGreedyPathToDiff: This cannot happen\n");
      fail();
    end if;
    if listEmpty(lst) then
      lst := {t};
    elseif d1==d2 then
      lst := t::lst;
    else
      out := (d2,lst)::out;
      lst := {t};
    end if;
    d2 := d1;
    x2 := x1;
    y2 := y1;
  end for;
  if not listEmpty(lst) then
    out := (d2,lst)::out;
  end if;
end myersGreedyPathToDiff;

function trimCommonPrefix<T>
  input array<T> arr1;
  input Integer inStart1;
  input Integer end1;
  input array<T> arr2;
  input Integer inStart2;
  input Integer end2;
  input FunEquals equals;
  input list<tuple<Diff,list<T>>> acc;
  output list<tuple<Diff,list<T>>> prefixes = acc;
  output Integer start1=inStart1, start2=inStart2;
  partial function FunEquals
    input T t1,t2;
    output Boolean b;
  end FunEquals;
protected
  list<T> lst = {};
algorithm
  while if start1<=end1 and start2<=end2 then equals(arr1[start1], arr2[start2]) else false loop
    lst := arr1[start1]::lst;
    start1 := start1 + 1;
    start2 := start2 + 1;
  end while;
  if not listEmpty(lst) then
    prefixes := (Diff.Equal,listReverse(lst))::prefixes;
  end if;
end trimCommonPrefix;

function trimCommonSuffix<T>
  input array<T> arr1;
  input Integer start1;
  input Integer inEnd1;
  input array<T> arr2;
  input Integer start2;
  input Integer inEnd2;
  input FunEquals equals;
  input list<tuple<Diff,list<T>>> acc;
  output list<tuple<Diff,list<T>>> suffixes = acc;
  output Integer end1=inEnd1, end2=inEnd2;
  partial function FunEquals
    input T t1,t2;
    output Boolean b;
  end FunEquals;
protected
  list<T> lst = {};
algorithm
  while if start1<=end1 and start2<=end2 then equals(arr1[end1], arr2[end2]) else false loop
    lst := arr1[end1]::lst;
    end1 := end1 - 1;
    end2 := end2 - 1;
  end while;
  if not listEmpty(lst) then
    suffixes := (Diff.Equal,lst)::suffixes;
  end if;
end trimCommonSuffix;

annotation(__OpenModelica_Interface="util");
end DiffAlgorithm;
