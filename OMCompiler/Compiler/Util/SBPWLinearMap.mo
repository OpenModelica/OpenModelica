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

encapsulated uniontype SBPWLinearMap
  import SBAtomicSet;
  import SBSet;
  import SBLinearMap;
  import SBPWAtomicLinearMap;

protected
  import Array;
  import MetaModelica.Dangerous.*;
  import System;
  import Vector;

public
  record PW_LINEAR_MAP
    array<SBSet> dom;
    array<SBLinearMap> lmap;
    Integer ndim;
  end PW_LINEAR_MAP;

  function new
    input array<SBSet> dom;
    input array<SBLinearMap> lmap;
    output SBPWLinearMap map;
  protected
    Integer dim = 0;
    Boolean same_dims;
  algorithm
    if arrayLength(dom) <> arrayLength(lmap) then
      // Warning: Domain size should be equal to map size.
      map := newEmpty();
      return;
    end if;

    if not arrayEmpty(dom) then
      dim := SBSet.ndim(dom[1]);

      same_dims := Array.all(dom, function SBSet.isDim(dim = dim)) and
                   Array.all(lmap, function SBLinearMap.isDim(dim = dim));
    end if;

    if not same_dims then
      // Warning: Sets and maps should have the same dimension.
      map := newEmpty();
    else
      map := PW_LINEAR_MAP(arrayCopy(dom), arrayCopy(lmap), dim);
    end if;
  end new;

  function newScalar
    input SBSet dom;
    input SBLinearMap lmap;
    output SBPWLinearMap map;
  algorithm
    if SBSet.ndim(dom) == SBLinearMap.ndim(lmap) then
      map := PW_LINEAR_MAP(arrayCreate(1, dom), arrayCreate(1, lmap), 1);
    else
      // Warning: Sets and maps should have the same dimension.
      map := newEmpty();
    end if;
  end newScalar;

  function newEmpty
    output SBPWLinearMap map;
  algorithm
    map := PW_LINEAR_MAP(listArray({}), listArray({}), 0);
  end newEmpty;

  function newIdentity
    input SBSet set;
    output SBPWLinearMap map;
  protected
    SBLinearMap lmap = SBLinearMap.newIdentity(SBSet.ndim(set));
  algorithm
    map := PW_LINEAR_MAP(arrayCreate(1, set), arrayCreate(1, lmap), 1);
  end newIdentity;

  function copy
    input output SBPWLinearMap map;
  algorithm
    map.dom := Array.map(map.dom, SBSet.copy);
    map.lmap := Array.map(map.lmap, SBLinearMap.copy);
  end copy;

  function dom
    input SBPWLinearMap map;
    output array<SBSet> dom = map.dom;
  end dom;

  function lmap
    input SBPWLinearMap map;
    output array<SBLinearMap> lmap = map.lmap;
  end lmap;

  function ndim
    input SBPWLinearMap map;
    output Integer ndim = map.ndim;
  end ndim;

  function isEmpty
    input SBPWLinearMap map;
    output Boolean empty = arrayEmpty(map.dom);
  end isEmpty;

  function image
    input SBPWLinearMap map;
    input SBSet set;
    output SBSet outSet = SBSet.newEmpty();
  protected
    array<SBSet> dom = map.dom;
    array<SBLinearMap> lmap = map.lmap;
    SBSet ss, partial_res;

    function add_set
      input SBAtomicSet aset;
      input SBLinearMap map;
      input output SBSet set;
    protected
      SBPWAtomicLinearMap aux_map;
    algorithm
      aux_map := SBPWAtomicLinearMap.new(aset, map);
      set := SBSet.addAtomicSet(SBPWAtomicLinearMap.image(aux_map, aset), set);
    end add_set;
  algorithm
    for i in 1:arrayLength(dom) loop
      ss := dom[i];
      ss := SBSet.intersection(ss, set);

      partial_res := UnorderedSet.fold(SBSet.asets(ss),
        function add_set(map = lmap[i]), SBSet.newEmpty());

      outSet := SBSet.union(outSet, partial_res);
    end for;
  end image;

  function preImage
    input SBPWLinearMap map;
    input SBSet set;
    output SBSet outSet = SBSet.newEmpty();
  protected
    array<SBSet> dom = map.dom;
    array<SBLinearMap> lmap = map.lmap;
    SBSet ss, partial_res;
    array<SBAtomicSet> sets;

    function add_set
      input SBAtomicSet aset;
      input SBLinearMap map;
      input array<SBAtomicSet> sets;
      input output SBSet set;
    protected
      SBPWAtomicLinearMap aux_map;
    algorithm
      aux_map := SBPWAtomicLinearMap.new(aset, map);

      for as2 in sets loop
        set := SBSet.addAtomicSet(SBPWAtomicLinearMap.preImage(aux_map, as2), set);
      end for;
    end add_set;
  algorithm
    sets := UnorderedSet.toArray(SBSet.asets(set));

    for i in 1:arrayLength(dom) loop
      ss := dom[i];
      partial_res := SBSet.newEmpty();

      partial_res := UnorderedSet.fold(SBSet.asets(ss),
        function add_set(map = lmap[i], sets = sets), SBSet.newEmpty());

      outSet := SBSet.union(outSet, partial_res);
    end for;
  end preImage;

  function compPW
    input SBPWLinearMap map1;
    input SBPWLinearMap map2;
    output SBPWLinearMap outMap;
  protected
    array<SBSet> dom1 = map1.dom, dom2 = map2.dom;
    Vector<SBSet> ress;
    array<SBLinearMap> lmap1 = map1.lmap, lmap2 = map2.lmap;
    Vector<SBLinearMap> reslm;
    SBSet aux_dom, new_dom, d1, d2;
    SBLinearMap l1, l2, new_lm;
  algorithm
    if SBPWLinearMap.isEmpty(map1) or SBPWLinearMap.isEmpty(map2) then
      outMap := SBPWLinearMap.newEmpty();
      return;
    end if;

    ress := Vector.new<SBSet>();
    reslm := Vector.new<SBLinearMap>();

    for i in 1:arrayLength(dom1) loop
      d1 := arrayGetNoBoundsChecking(dom1, i);

      for j in 1:arrayLength(dom2) loop
        d2 := arrayGetNoBoundsChecking(dom2, j);

        aux_dom := image(map2, d2);
        aux_dom := SBSet.intersection(aux_dom, d1);
        aux_dom := preImage(map2, aux_dom);
        new_dom := SBSet.intersection(aux_dom, d2);

        if not SBSet.isEmpty(new_dom) then
          l1 := lmap1[i];
          l2 := lmap2[j];
          new_lm := SBLinearMap.compose(l1, l2);
          Vector.push(ress, new_dom);
          Vector.push(reslm, new_lm);
        end if;
      end for;
    end for;

    outMap := new(Vector.toArray(ress), Vector.toArray(reslm));
  end compPW;

  function minInvCompact
    input SBPWLinearMap map;
    output SBPWLinearMap outMap;
  protected
    SBSet aux_dom, dom_inv;
    SBLinearMap aux_map, map_inv;
    array<Integer> min;
    array<Real> resg, reso, g, o;
  algorithm
    if arrayLength(map.dom) <> 1 then
      // Warning: There should be only one component.
      outMap := newEmpty();
      return;
    end if;

    aux_dom := arrayGet(map.dom, 1);
    dom_inv := image(map, aux_dom);
    aux_map := arrayGet(map.lmap, 1);
    map_inv := SBLinearMap.inverse(aux_map);
    min := SBSet.minElem(aux_dom);

    g := SBLinearMap.gain(map_inv);
    o := SBLinearMap.offset(map_inv);

    resg := arrayCreateNoInit(arrayLength(g), 0.0);
    reso := arrayCreateNoInit(arrayLength(o), 0.0);

    for i in 1:arrayLength(g) loop
      if g[i] == intReal(System.intMaxLit()) then
        resg[i] := 0;
        reso[i] := intReal(min[i]);
      else
        resg[i] := g[i];
        reso[i] := o[i];
      end if;
    end for;

    outMap := new(arrayCreate(1, dom_inv), arrayCreate(1, SBLinearMap.new(resg, reso)));
  end minInvCompact;

  function wholeDom
    input SBPWLinearMap map;
    output SBSet set;
  algorithm
    set := SBSet.newEmpty();

    for s in map.dom loop
      set := SBSet.union(set, s);
    end for;
  end wholeDom;

  function combine
    input SBPWLinearMap map1;
    input SBPWLinearMap map2;
    output SBPWLinearMap outMap;
  protected
    Vector<SBSet> sres;
    Vector<SBLinearMap> lres;
    array<SBSet> dom2;
    array<SBLinearMap> lm2;
    SBSet aux1, s2, new_dom;
  algorithm
    if SBPWLinearMap.isEmpty(map1) then
      outMap := copy(map2);
      return;
    end if;

    if SBPWLinearMap.isEmpty(map2) then
      outMap := copy(map1);
      return;
    end if;

    sres := Vector.fromArray(map1.dom);
    lres := Vector.fromArray(map1.lmap);

    dom2 := map2.dom;
    lm2 := map2.lmap;
    aux1 := wholeDom(map1);

    for i in 1:arrayLength(dom2) loop
      s2 := dom2[i];
      new_dom := SBSet.complement(s2, aux1);

      if not SBSet.isEmpty(new_dom) then
        Vector.push(sres, new_dom);
        Vector.push(lres, lm2[i]);
      end if;
    end for;

    outMap := new(Vector.toArray(sres), Vector.toArray(lres));
  end combine;

  function atomize
    input SBPWLinearMap map;
    output SBPWLinearMap outMap;
  protected
    list<SBSet> dres = {};
    array<SBSet> dom = map.dom;
    list<SBLinearMap> lres = {};
    array<SBLinearMap> lm = map.lmap;
    SBSet d, aux;
    SBLinearMap l;
    array<SBAtomicSet> asets;
  algorithm
    for i in 1:arrayLength(dom) loop
      d := dom[i];
      l := lm[i];
      asets := UnorderedSet.toArray(SBSet.asets(d));

      for s in asets loop
        aux := SBSet.newEmpty();
        aux := SBSet.addAtomicSet(s, aux);

        dres := aux :: dres;
        lres := l :: lres;
      end for;
    end for;

    outMap := new(listArray(listReverseInPlace(dres)),
                  listArray(listReverseInPlace(lres)));
  end atomize;

  function isEqual
    input SBPWLinearMap map1;
    input SBPWLinearMap map2;
    output Boolean equal;
  algorithm
    equal := Array.isEqualOnTrue(map1.dom, map2.dom, SBSet.isEqual) and
             Array.isEqualOnTrue(map1.lmap, map2.lmap, SBLinearMap.isEqual);
  end isEqual;

  function toString
    input SBPWLinearMap map;
    output String str;
  protected
    array<SBSet> dom = map.dom;
    array<SBLinearMap> lmap = map.lmap;
    list<String> strl = {};

    function helper
      input SBAtomicSet set;
      input SBLinearMap lm;
      output String str;
    algorithm
      str := "{" + SBPWAtomicLinearMap.toString(SBPWAtomicLinearMap.PW_ATOMIC_LINEAR_MAP(set, lm)) + "}";
    end helper;
  algorithm
    for i in arrayLength(dom):-1:1 loop
      strl := UnorderedSet.toString(SBSet.asets(dom[i]), function helper(lm = lmap[i]), "U") :: strl;
    end for;

    str := "[" + stringDelimitList(strl, ",") + "]";
  end toString;

annotation(__OpenModelica_Interface="util");
end SBPWLinearMap;
