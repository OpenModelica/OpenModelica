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

encapsulated uniontype SBLinearMap

protected
  import Array;
  import List;
  import SBAtomicSet;
  import SBInterval;
  import SBMultiInterval;
  import SBSet;
  import System;
  import Util;
  import MetaModelica.Dangerous.*;

public
  record LINEAR_MAP
    array<Real> gain;
    array<Real> offset;
  end LINEAR_MAP;

  function new
    input array<Real> gain;
    input array<Real> offset;
    output SBLinearMap map;
  algorithm
    if Array.exist(gain, Util.realNegative) then
      // Warning: All gains should be positive.
      map := newEmpty();
    elseif arrayLength(gain) == arrayLength(offset) then
      map := LINEAR_MAP(arrayCopy(gain), arrayCopy(offset));
    else
      // Warning: Offset and gain should be the same size.
      map := newEmpty();
    end if;
  end new;

  function newEmpty
    output SBLinearMap map = LINEAR_MAP(listArray({}), listArray({}));
  end newEmpty;

  function newIdentity
    input Integer dim;
    output SBLinearMap map;
  algorithm
    map := LINEAR_MAP(arrayCreate(dim, 1.0), arrayCreate(dim, 0.0));
  end newIdentity;

  function copy
    input SBLinearMap map;
    output SBLinearMap outMap;
  algorithm
    outMap := LINEAR_MAP(arrayCopy(map.gain), arrayCopy(map.offset));
  end copy;

  function ndim
    input SBLinearMap map;
    output Integer ndim = arrayLength(map.gain);
  end ndim;

  function isDim
    input SBLinearMap map;
    input Integer dim;
    output Boolean res = arrayLength(map.gain) == dim;
  end isDim;

  function gain
    input SBLinearMap map;
    output array<Real> gain = map.gain;
  end gain;

  function offset
    input SBLinearMap map;
    output array<Real> offset = map.offset;
  end offset;

  function isEmpty
    input SBLinearMap map;
    output Boolean empty = arrayEmpty(map.gain);
  end isEmpty;

  function isEqual
    input SBLinearMap map1;
    input SBLinearMap map2;
    output Boolean equal;
  algorithm
    equal := Array.isEqualOnTrue(map1.gain, map2.gain, realEq) and
             Array.isEqualOnTrue(map1.offset, map2.offset, realEq);
  end isEqual;

  function compose
    input SBLinearMap map1;
    input SBLinearMap map2;
    output SBLinearMap map;
  protected
    array<Real> gain, offset;
    Integer len1 = ndim(map1), len2 = ndim(map2);
    Real g1, g2, o1, o2;
  algorithm
    if len1 == len2 then
      gain := arrayCreateNoInit(len1, 0.0);
      offset := arrayCreateNoInit(len1, 0.0);

      for i in 1:len1 loop
        g1 := arrayGetNoBoundsChecking(map1.gain, i);
        g2 := arrayGetNoBoundsChecking(map2.gain, i);
        o1 := arrayGetNoBoundsChecking(map1.offset, i);
        o2 := arrayGetNoBoundsChecking(map2.offset, i);

        arrayUpdateNoBoundsChecking(gain, i, g1 * g2);
        arrayUpdateNoBoundsChecking(offset, i, o2 * g1 + o1);
      end for;

      map := LINEAR_MAP(gain, offset);
    else
      // Warning: Linear maps should be of the same size.
      map := newEmpty();
    end if;

  end compose;

  function inverse
    input SBLinearMap map;
    output SBLinearMap inv;
  protected
    array<Real> gain, offset;
    Integer len = ndim(map);
    Real g, o;
  algorithm
    gain := arrayCreateNoInit(len, 0.0);
    offset := arrayCreateNoInit(len, 0.0);

    for i in 1:len loop
      g := arrayGetNoBoundsChecking(map.gain, i);
      o := arrayGetNoBoundsChecking(map.offset, i);

      if g <> 0 then
        arrayUpdateNoBoundsChecking(gain, i, 1.0 / g);
        arrayUpdateNoBoundsChecking(offset, i, -o / g);
      else
        arrayUpdateNoBoundsChecking(gain, i, intReal(System.intMaxLit()));
        arrayUpdateNoBoundsChecking(offset, i, intReal(System.intMaxLit()));
      end if;
    end for;

    inv := LINEAR_MAP(gain, offset);
  end inverse;

  function apply
    input SBSet domain;
    input SBLinearMap map;
    output SBSet target = SBSet.copy(domain);
  algorithm
    UnorderedSet.map(target.asets, function applyAtomicSet(map = map));
  end apply;

  function applyAtomicSet
    input output SBAtomicSet atomic;
    input SBLinearMap map;
  algorithm
    atomic.aset := applyMultiInterval(atomic.aset, map);
  end applyAtomicSet;

  function applyMultiInterval
    input output SBMultiInterval multiInt;
    input SBLinearMap map;
  algorithm
    for i in 1:multiInt.ndim loop
      multiInt.intervals[i] := applyInterval(multiInt.intervals[i], map.gain[i], map.offset[i]);
    end for;
  end applyMultiInterval;

  function applyInterval
    input output SBInterval interval;
    input Real gain;
    input Real offset;
  algorithm
    // take care! theses should always be convertible without rounding errors
    interval.lo   := realInt(intReal(interval.lo) * gain + offset);
    interval.step := realInt(intReal(interval.step) * gain);
    interval.hi   := realInt(intReal(interval.hi) * gain + offset);
  end applyInterval;

  function toString
    input SBLinearMap map;
    output String str;
  protected
    list<String> strl = {};
  algorithm
    for i in arrayLength(map.gain):-1:1 loop
      strl := String(arrayGetNoBoundsChecking(map.gain, i)) + " * x + " +
              String(arrayGetNoBoundsChecking(map.offset, i)) :: strl;
    end for;

    str := stringDelimitList(strl, "\n");
  end toString;

annotation(__OpenModelica_Interface="util");
end SBLinearMap;
