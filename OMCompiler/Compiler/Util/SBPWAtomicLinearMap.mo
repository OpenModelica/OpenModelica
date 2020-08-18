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

encapsulated uniontype SBPWAtomicLinearMap
  import SBAtomicSet;
  import SBInterval;
  import SBLinearMap;

protected
  import Array;
  import List;
  import System;
  import MetaModelica.Dangerous.*;

public
  record PW_ATOMIC_LINEAR_MAP
    SBAtomicSet dom;
    SBLinearMap lmap;
  end PW_ATOMIC_LINEAR_MAP;

  function new
    input SBAtomicSet dom;
    input SBLinearMap lmap;
    output SBPWAtomicLinearMap map;
  protected
    Boolean compatible = true;
    array<SBInterval> ints;
    array<Real> g, o;
    SBInterval i;
    Real gain, offset, lo, step, hi;
  algorithm
    if SBAtomicSet.ndim(dom) <> SBLinearMap.ndim(lmap) then
      // Warning: Atomic set and map should be of the same dimension.
      map := newEmpty();
      return;
    end if;

    ints := SBMultiInterval.intervals(SBAtomicSet.aset(dom));
    g := SBLinearMap.gain(lmap);
    o := SBLinearMap.offset(lmap);

    for j in 1:arrayLength(ints) loop
      i := arrayGetNoBoundsChecking(ints, j);
      gain := arrayGetNoBoundsChecking(g, j);
      offset := arrayGetNoBoundsChecking(g, j);

      if gain < intReal(System.intMaxLit()) then
        lo := SBInterval.lowerBound(i) * gain + offset;
        step := SBInterval.stepValue(i) * gain;
        hi := SBInterval.upperBound(i) * gain + offset;

        if lo <> realInt(lo) and SBInterval.lowerBound(i) > 0 then
          // Warning: Incompatible map.
          compatible := false;
          break;
        end if;

        if step <> realInt(step) and SBInterval.stepValue(i) > 0 then
          // Warning: Incompatible map.
          compatible := false;
          break;
        end if;

        if hi <> realInt(hi) and SBInterval.upperBound(i) > 0 then
          // Warning: Incompatible map.
          compatible := false;
          break;
        end if;
      end if;
    end for;

    if compatible then
      map := PW_ATOMIC_LINEAR_MAP(SBAtomicSet.copy(dom), SBLinearMap.copy(lmap));
    end if;
  end new;

  function newEmpty
    output SBPWAtomicLinearMap map;
  algorithm
    map := PW_ATOMIC_LINEAR_MAP(SBAtomicSet.newEmpty(), SBLinearMap.newEmpty());
  end newEmpty;

  function dom
    input SBPWAtomicLinearMap map;
    output SBAtomicSet dom = map.dom;
  end dom;

  function lmap
    input SBPWAtomicLinearMap map;
    output SBLinearMap lmap = map.lmap;
  end lmap;

  function isEmpty
    input SBPWAtomicLinearMap map;
    output Boolean empty;
  algorithm
    empty := SBAtomicSet.isEmpty(map.dom) and SBLinearMap.isEmpty(map.lmap);
  end isEmpty;

  function image
    input SBPWAtomicLinearMap map;
    input SBAtomicSet set;
    output SBAtomicSet outSet;
  protected
    function crop_inf
      input Real v;
      output Integer i;
    algorithm
      i := if v >= intReal(System.intMaxLit()) then System.intMaxLit() else realInt(v);
    end crop_inf;

    array<SBInterval> inters, res;
    array<Real> gains, offsets;
    SBAtomicSet set_int;
    SBInterval int;
    Real gain, offset;
    Integer new_lo, new_step, new_hi;
    Real tmp_lo, tmp_step, tmp_hi;
  algorithm
    if SBAtomicSet.isEmpty(map.dom) then
      outSet := SBAtomicSet.newEmpty();
      return;
    end if;

    set_int := SBAtomicSet.intersection(set, map.dom);
    inters := SBMultiInterval.intervals(SBAtomicSet.aset(set_int));

    if arrayEmpty(inters) then
      outSet := SBAtomicSet.newEmpty();
      return;
    end if;

    gains := SBLinearMap.gain(map.lmap);
    offsets := SBLinearMap.offset(map.lmap);

    res := arrayCreateNoInit(arrayLength(inters), inters[1]);

    for i in 1:arrayLength(inters) loop
      int := arrayGetNoBoundsChecking(inters, i);
      gain := gains[i];
      offset := offsets[i];

      tmp_lo := SBInterval.lowerBound(int) * gain + offset;
      tmp_step := SBInterval.stepValue(int) * gain;
      tmp_hi := SBInterval.upperBound(int) * gain + offset;

      if gain < intReal(System.intMaxLit()) then
        new_lo := crop_inf(tmp_lo);
        new_step := crop_inf(tmp_step);
        new_hi := crop_inf(tmp_hi);
      else
        new_lo := 1;
        new_step := 1;
        new_hi := System.intMaxLit();
      end if;

      arrayUpdateNoBoundsChecking(res, i, SBInterval.new(new_lo, new_step, new_hi));
    end for;

    outSet := SBAtomicSet.new(SBMultiInterval.fromArray(res));
  end image;

  function preImage
    input SBPWAtomicLinearMap map;
    input SBAtomicSet set;
    output SBAtomicSet outSet;
  protected
    SBAtomicSet full_im, actual_im, aux;
    SBPWAtomicLinearMap inv;
  algorithm
    full_im := image(map, map.dom);
    actual_im := SBAtomicSet.intersection(full_im, set);
    inv := new(actual_im, SBLinearMap.inverse(map.lmap));
    aux := image(inv, actual_im);
    outSet := SBAtomicSet.intersection(map.dom, aux);
  end preImage;

  function isEqual
    input SBPWAtomicLinearMap map1;
    input SBPWAtomicLinearMap map2;
    output Boolean equal;
  algorithm
    equal := SBAtomicSet.isEqual(map1.dom, map2.dom) and
             SBLinearMap.isEqual(map1.lmap, map2.lmap);
  end isEqual;

  function toString
    input SBPWAtomicLinearMap map;
    output String str;
  protected
    list<String> strl = {};
    array<Real> g, o;
    array<SBInterval> ints;
  algorithm
    g := SBLinearMap.gain(map.lmap);
    o := SBLinearMap.offset(map.lmap);
    ints := SBMultiInterval.intervals(SBAtomicSet.aset(map.dom));

    for i in arrayLength(ints):-1:1 loop
      str := "(" + SBInterval.toString(ints[i]) + ", " + String(g[i]) + " * x + " + String(o[i]) + ")";
      strl := str :: strl;
    end for;

    str := stringDelimitList(strl, "x");
  end toString;

annotation(__OpenModelica_Interface="util");
end SBPWAtomicLinearMap;
