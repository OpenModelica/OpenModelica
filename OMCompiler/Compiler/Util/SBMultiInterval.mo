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

encapsulated uniontype SBMultiInterval
  import SBInterval;
  import UnorderedSet;

protected
  import Array;
  import List;
  import MetaModelica.Dangerous.*;

public
  record MULTI_INTERVAL
    array<SBInterval> intervals;
    Integer ndim;
  end MULTI_INTERVAL;

  function newEmpty
    output SBMultiInterval mi;
  algorithm
    mi := MULTI_INTERVAL(listArray({}), 0);
  end newEmpty;

  function copy
    input SBMultiInterval mi;
    output SBMultiInterval outMI;
  algorithm
    outMI := MULTI_INTERVAL(arrayCopy(mi.intervals), mi.ndim);
  end copy;

  function fromList
    input list<SBInterval> ints;
    output SBMultiInterval outMI;
  algorithm
    if List.exist(ints, SBInterval.isEmpty) then
      outMI := newEmpty();
    else
      outMI := MULTI_INTERVAL(listArray(ints), listLength(ints));
    end if;
  end fromList;

  function fromArray
    input array<SBInterval> ints;
    output SBMultiInterval outMI;
  algorithm
    if Array.exist(ints, SBInterval.isEmpty) then
      outMI := newEmpty();
    else
      outMI := MULTI_INTERVAL(arrayCopy(ints), arrayLength(ints));
    end if;
  end fromArray;

  function isEmpty
    input SBMultiInterval mi;
    output Boolean empty;
  algorithm
    empty := arrayEmpty(mi.intervals);
  end isEmpty;

  function contains
    input array<Integer> vals;
    input SBMultiInterval mi;
    output Boolean res;
  algorithm
    if arrayLength(vals) <> mi.ndim then
      res := false;
    else
      res := Array.isEqualOnTrue(vals, mi.intervals, SBInterval.contains);
    end if;
  end contains;

  function intersection
    input SBMultiInterval mi1;
    input SBMultiInterval mi2;
    output SBMultiInterval outMI;
  protected
    array<SBInterval> ints;
    SBInterval ires;
  algorithm
    if mi1.ndim <> mi2.ndim or isEmpty(mi1) then
      outMI := newEmpty();
      return;
    end if;

    ints := arrayCreateNoInit(mi1.ndim, arrayGet(mi1.intervals, 1));

    for i in 1:arrayLength(ints) loop
      ires := SBInterval.intersection(
        arrayGet(mi1.intervals, i), arrayGet(mi2.intervals, i));

      if SBInterval.isEmpty(ires) then
        outMI := newEmpty();
        return;
      end if;

      arrayUpdateNoBoundsChecking(ints, i, ires);
    end for;

    outMI := fromArray(ints);
  end intersection;

  function complement
    input SBMultiInterval mi1;
    input SBMultiInterval mi2;
    output UnorderedSet<SBMultiInterval> res;
  protected
    SBMultiInterval tmp_mi;
    UnorderedSet<SBInterval> dummys = dummys;
    array<UnorderedSet<SBInterval>> diffs;
    Integer count, mi1_size;
    array<SBInterval> resi;

    function add_interval
      input SBInterval i;
      input Integer count;
      input Integer size;
      input array<SBInterval> ints1;
      input array<SBInterval> ints2;
      input output UnorderedSet<SBMultiInterval> res;
    protected
      SBInterval dummyi = dummyi;
      array<SBInterval> resi;
    algorithm
      if not SBInterval.isEmpty(i) then
        resi := arrayCreateNoInit(size, dummyi);
        Array.copyN(ints1, resi, count);
        resi[count + 1] := i;
        Array.copyN(ints2, resi, arrayLength(ints2) - count - 1, count + 1, count + 1);
        UnorderedSet.add(fromArray(resi), res);
      end if;
    end add_interval;
  algorithm
    res := UnorderedSet.new(hash, isEqual);

    if isEmpty(mi1) or mi1.ndim <> mi2.ndim then
      return;
    end if;

    tmp_mi := intersection(mi1, mi2);

    if isEmpty(tmp_mi) then
      UnorderedSet.add(mi1, res);
      return;
    end if;

    if isEqual(mi1, tmp_mi) then
      return;
    end if;

    mi1_size := arrayLength(mi1.intervals);
    diffs := arrayCreateNoInit(mi1_size, dummys);

    for i in 1:mi1_size loop
      diffs[i] := SBInterval.complement(arrayGetNoBoundsChecking(mi1.intervals, i),
                                        arrayGet(tmp_mi.intervals, i));
    end for;

    count := 0;
    for vdiff in diffs loop
      UnorderedSet.fold(
        vdiff,
        function add_interval(
          count = count,
          size = mi1_size,
          ints1 = tmp_mi.intervals,
          ints2 = mi1.intervals),
        res);

      count := count + 1;
    end for;
  end complement;

  function crossProd
    input SBMultiInterval mi1;
    input SBMultiInterval mi2;
    output SBMultiInterval res;
  protected
    array<SBInterval> ints;
  algorithm
    ints := Array.join(mi1.intervals, mi2.intervals);
    res := MULTI_INTERVAL(ints, arrayLength(ints));
  end crossProd;

  function cardinality
    input SBMultiInterval mi;
    output Integer card = 0;
  algorithm
    for i in 1:mi.ndim loop
      card := card + SBInterval.cardinality(mi.intervals[i]);
    end for;
  end cardinality;

  function intervals
    input SBMultiInterval mi;
    output array<SBInterval> ints = mi.intervals;
  end intervals;

  function ndim
    input SBMultiInterval mi;
    output Integer ndim = arrayLength(mi.intervals);
  end ndim;

  function minElem
    input SBMultiInterval mi;
    output array<Integer> res;
  protected
    Integer idx;
  algorithm
    for i in mi.intervals loop
      if SBInterval.isEmpty(i) then
        res := listArray({});
        return;
      end if;
    end for;

    res := Array.map(mi.intervals, SBInterval.lowerBound);
  end minElem;

  function replace
    input SBInterval i;
    input Integer dim;
    input SBMultiInterval mi;
    output SBMultiInterval res;
  protected
    array<SBInterval> ints;
  algorithm
    ints := arrayCopy(mi.intervals);
    ints[dim] := i;
    res := fromArray(ints);
  end replace;

  function isEqual
    input SBMultiInterval mi1;
    input SBMultiInterval mi2;
    output Boolean equal;
  algorithm
    equal := Array.isEqualOnTrue(mi1.intervals, mi2.intervals, SBInterval.isEqual);
  end isEqual;

  function hash
    input SBMultiInterval mi;
    input Integer mod;
    output Integer res;
  algorithm
    res := intMod(arrayLength(mi.intervals), mod);
  end hash;

  function size
    input SBMultiInterval mi;
    output Integer sz = 1;
  algorithm
    for i in mi.intervals loop
      sz := sz * SBInterval.size(i);
    end for;
  end size;

  function toString
    input SBMultiInterval mi;
    output String str;
  algorithm
    if isEmpty(mi) then
      str := "emptyInterval";
    else
      str := stringDelimitList(list(SBInterval.toString(i) for i in mi.intervals), "x");
    end if;
  end toString;

annotation(__OpenModelica_Interface="util");
end SBMultiInterval;
