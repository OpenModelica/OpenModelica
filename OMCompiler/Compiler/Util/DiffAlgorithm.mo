/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2021, Open Source Modelica Consortium (OSMC),
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
  https://www.codeproject.com/Articles/42279/Investigating-Myers-diff-algorithm-Part-1-of-2
  https://code.google.com/p/google-diff-match-patch/
"

import Print;

protected

import List;
import System;

public

type Diff = enumeration(Add,Delete,Equal);

function diff<T>
  input list<T> seq1;
  input list<T> seq2;
  input FunEquals equals;
  input FunWhitespace isWhitespace, isWhitespaceNotComment;
  input ToString toString;
  output list<tuple<Diff,list<T>>> out;
  partial function FunEquals
    input T t1,t2;
    output Boolean b;
  end FunEquals;
  partial function FunWhitespace
    input T t;
    output Boolean b;
  end FunWhitespace;
  partial function ToString
    input T t;
    output String o;
  end ToString;
protected
  Integer start1, end1, start2, end2, len1, len2;
  array<T> arr1, arr2;
algorithm
  arr1 := listArray(seq1);
  arr2 := listArray(seq2);
  start1 := 1;
  start2 := 1;
  end1 := arrayLength(arr1);
  end2 := arrayLength(arr2);
  out := diffSeq(arr1, arr2, equals, isWhitespace, isWhitespaceNotComment, toString, start1, end1, start2, end2);
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
    if not listEmpty(ts) and (b or (DiffStrings.printEqual and DiffStrings.printAdd and DiffStrings.printDelete /* optimization */)) then
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
  input FunWhitespace isWhitespace;
  input FunWhitespace isWhitespaceNotComment;
  input ToString toString;
  input Integer inStart1, inEnd1, inStart2, inEnd2;
  input list<tuple<Diff,list<T>>> inPrefixes = {}, inSuffixes = {};
  output list<tuple<Diff,list<T>>> out;
  partial function FunEquals
    input T t1,t2;
    output Boolean b;
  end FunEquals;
  partial function FunWhitespace
    input T t;
    output Boolean b;
  end FunWhitespace;
  partial function ToString
    input T t;
    output String o;
  end ToString;
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
    out := List.append_reverse(prefixes, suffixes);
    return;
  elseif len1 < 1 then
    out := List.append_reverse(prefixes, (Diff.Add, list(arr2[e] for e in start2:end2))::suffixes);
    return;
  elseif len2 < 1 then
    out := List.append_reverse(prefixes, (Diff.Delete, list(arr1[e] for e in start1:end1))::suffixes);
    return;
  end if;
  // Note the horrible syntax for short-circuit evaluation
  // Check if the sequences are equal. Trivial diff.
  if if len1==len2 then min(equals(arr1[e+start1-1],arr2[e+start2-1]) threaded for e in 1:len1) else false then
    out := {(Diff.Equal, list(arr1[e] for e in start1:end1))};
    return;
  end if;

  // trim off common prefix; guaranteed to be a good solution
  (prefixes, start1, start2) := trimCommonPrefix(arr1, start1, end1, arr2, start2, end2, equals, prefixes, isWhitespaceNotComment, toString);
  // trim off common suffix; guaranteed to be a good solution
  (suffixes, end1, end2) := trimCommonSuffix(arr1, start1, end1, arr2, start2, end2, equals, suffixes, isWhitespaceNotComment);
  // Check if anything changed and iterate. A sequence could now be empty.
  if start1<>inStart1 or start2<>inStart2 or end1<>inEnd1 or end2<>inEnd2 then
    out := diffSeq(arr1,arr2,equals,isWhitespace,isWhitespaceNotComment,toString,start1,end1,start2,end2,inPrefixes=prefixes,inSuffixes=suffixes);
    return;
  else
    out := matchcontinue ()
      case () then onlyAdditions(arr1,arr2,equals,isWhitespace,toString,start1,end1,start2,end2);
      case () then onlyRemovals(arr1,arr2,equals,isWhitespace,toString,start1,end1,start2,end2);
      else myersGreedyDiff(arr1,arr2,equals,start1,end1,start2,end2);
    end matchcontinue;
    // TODO: cleanup
    out := List.append_reverse(prefixes, listAppend(out, suffixes));
    return;
  end if;
  fail();
end diffSeq;

function addToList<T>
  input list<tuple<Diff,list<T>>> inlst;
  input Diff ind;
  input list<T> inacc;
  input Diff newd;
  input T t;
  output list<tuple<Diff,list<T>>> lst=inlst;
  output Diff d=newd;
  output list<T> acc=inacc;
algorithm
  if ind==newd then
    acc := t::acc;
  else
    if not listEmpty(inacc) then
      lst := (ind,listReverse(acc))::lst;
    end if;
    acc := {t};
  end if;
end addToList;

function endList<T>
  input list<tuple<Diff,list<T>>> inlst;
  input Diff ind;
  input list<T> inacc;
  output list<tuple<Diff,list<T>>> lst=inlst;
algorithm
  if not listEmpty(inacc) then
    lst := (ind,listReverse(inacc))::lst;
  end if;
end endList;

function onlyAdditions<T>
  input array<T> arr1;
  input array<T> arr2;
  input FunEquals equals;
  input FunWhitespace isWhitespace;
  input ToString toString;
  input Integer start1, end1, start2, end2;
  output list<tuple<Diff,list<T>>> out;
  partial function FunEquals
    input T t1,t2;
    output Boolean b;
  end FunEquals;
  partial function FunWhitespace
    input T t;
    output Boolean b;
  end FunWhitespace;
  partial function ToString
    input T t;
    output String o;
  end ToString;
protected
  Integer x=0,y=0;
  Diff d=Diff.Equal;
  list<T> lst={};
algorithm
  out := {};
  // print("Try only additions\n");
  while start1+x<=end1 and start2+y<=end2 loop
    // print("Try only additions"+String(x)+","+String(y)+"\n");
    // print("1: " + System.trim(toString(arr1[start1+x]))+"\n");
    // print("2: " + System.trim(toString(arr2[start2+y]))+"\n");
    if equals(arr1[start1+x],arr2[start2+y]) then
      (out,d,lst) := addToList(out,d,lst,Diff.Equal,arr1[start1+x]);
      x:=x+1;
      y:=y+1;
      // print("Both equal\n");
    elseif isWhitespace(arr1[start1+x]) then
      (out,d,lst) := addToList(out,d,lst,Diff.Delete,arr1[start1+x]);
      // print("Deleting: " + toString(arr1[start1+x])+"\n");
      x:=x+1;
    else
      (out,d,lst) := addToList(out,d,lst,Diff.Add,arr2[start2+y]);
      // print("Adding: " + toString(arr2[start2+y])+"\n");
      y:=y+1;
    end if;
  end while;

  while start1+x<=end1 loop
    if isWhitespace(arr1[start1+x]) then
      (out,d,lst) := addToList(out,d,lst,Diff.Delete,arr1[start1+x]);
      x:=x+1;
    else
      fail();
    end if;
  end while;

  while start2+y<=end2 loop
    if isWhitespace(arr2[start2+y]) then
      (out,d,lst) := addToList(out,d,lst,Diff.Add,arr2[start2+y]);
      y:=y+1;
    else
      fail();
    end if;
  end while;

  out := endList(out, d, lst);

  // print("It is only additions :)\n");
  out := listReverse(out);
end onlyAdditions;

function onlyRemovals<T>
  input array<T> arr1;
  input array<T> arr2;
  input FunEquals equals;
  input FunWhitespace isWhitespace;
  input ToString toString;
  input Integer start1, end1, start2, end2;
  output list<tuple<Diff,list<T>>> out;
  partial function FunEquals
    input T t1,t2;
    output Boolean b;
  end FunEquals;
  partial function FunWhitespace
    input T t;
    output Boolean b;
  end FunWhitespace;
  partial function ToString
    input T t;
    output String o;
  end ToString;
protected
  Integer x=0,y=0;
  Diff d=Diff.Equal;
  list<T> lst={};
algorithm
  out := {};
  // print("Try only removals\n");
  while start1+x<=end1 and start2+y<=end2 loop
    // print("Try only removals"+String(x)+","+String(y)+"\n");
    // print("1: " + System.trim(toString(arr1[start1+x]))+"\n");
    // print("2: " + System.trim(toString(arr2[start2+y]))+"\n");
    if equals(arr1[start1+x],arr2[start2+y]) then
      (out,d,lst) := addToList(out,d,lst,Diff.Equal,arr1[start1+x]);
      x:=x+1;
      y:=y+1;
      // print("Both equal\n");
    elseif isWhitespace(arr2[start2+y]) then
      (out,d,lst) := addToList(out,d,lst,Diff.Add,arr2[start2+y]);
      // print("Deleting: " + toString(arr1[start1+x])+"\n");
      y:=y+1;
    else
      (out,d,lst) := addToList(out,d,lst,Diff.Delete,arr1[start1+x]);
      // print("Adding: " + toString(arr2[start2+y])+"\n");
      x:=x+1;
    end if;
  end while;

  while start1+x<=end1 loop
    if isWhitespace(arr1[start1+x]) then
      (out,d,lst) := addToList(out,d,lst,Diff.Delete,arr1[start1+x]);
      x:=x+1;
    else
      fail();
    end if;
  end while;

  while start2+y<=end2 loop
    if isWhitespace(arr2[start2+y]) then
      (out,d,lst) := addToList(out,d,lst,Diff.Add,arr2[start2+y]);
      y:=y+1;
    else
      fail();
    end if;
  end while;

  out := endList(out, d, lst);

  // print("It is only additions :)\n");
  out := listReverse(out);
end onlyRemovals;

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
  input FunWhitespace isWhitespaceNotComment;
  input ToString toString;
  output list<tuple<Diff,list<T>>> prefixes = acc;
  output Integer start1=inStart1, start2=inStart2;
  partial function ToString
    input T t;
    output String o;
  end ToString;
  partial function FunEquals
    input T t1,t2;
    output Boolean b;
  end FunEquals;
  partial function FunWhitespace
    input T t;
    output Boolean b;
  end FunWhitespace;
protected
  list<T> lst = {};
algorithm
  while start1<=end1 and start2<=end2 loop
    if equals(arr1[start1], arr2[start2]) then
      lst := arr1[start1]::lst;
      start1 := start1 + 1;
      start2 := start2 + 1;
    elseif start2+1 <= end2 and isWhitespaceNotComment(arr2[start2]) then
      if not equals(arr1[start1], arr2[start2+1]) then
        break;
      end if;
      start2 := start2 + 1;
    else
      break;
    end if;
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
  input FunWhitespace isWhitespaceNotComment;
  output list<tuple<Diff,list<T>>> suffixes = acc;
  output Integer end1=inEnd1, end2=inEnd2;
  partial function FunEquals
    input T t1,t2;
    output Boolean b;
  end FunEquals;
  partial function FunWhitespace
    input T t;
    output Boolean b;
  end FunWhitespace;
protected
  list<T> lst = {};
algorithm
  while start1<=end1 and start2<=end2 loop
    if equals(arr1[end1], arr2[end2]) then
      lst := arr1[end1]::lst;
      end1 := end1 - 1;
      end2 := end2 - 1;
    elseif start2 <= end2-1 and isWhitespaceNotComment(arr2[end2]) then
      if not equals(arr1[end1], arr2[end2-1]) then
        break;
      end if;
      end2 := end2 - 1;
    else
      break;
    end if;
  end while;

  if not listEmpty(lst) then
    suffixes := (Diff.Equal,lst)::suffixes;
  end if;
end trimCommonSuffix;

function printStartToEnd<T>
  input array<T> arr;
  input Integer startIndex, endIndex;
  input ToString toString;
  partial function ToString
    input T t;
    output String o;
  end ToString;
  output String res;
algorithm
  res := stringAppendList(list(toString(arrayGet(arr, index)) for index in startIndex:endIndex));
end printStartToEnd;

annotation(__OpenModelica_Interface="util");
end DiffAlgorithm;
