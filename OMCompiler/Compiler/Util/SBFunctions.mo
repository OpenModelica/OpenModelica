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

encapsulated package SBFunctions
  import SBAtomicSet;
  import SBInterval;
  import SBLinearMap;
  import SBMultiInterval;
  import SBPWLinearMap;
  import SBSet;

protected
  import Array;
  import MetaModelica.Dangerous.*;
  import System;
  import Vector;

public
  function minAtomPW
    input SBAtomicSet dom;
    input SBLinearMap lm1;
    input SBLinearMap lm2;
    output SBPWLinearMap outMap;
  protected
    array<Real> g1, g2, resg;
    array<Real> o1, o2, reso;
    array<SBInterval> ints;
    SBAtomicSet as_aux;
    SBLinearMap lm_aux;
    array<SBSet> dom_res;
    array<SBLinearMap> lm_res;
    SBSet s_aux, d1, d2;
    Real g1i, g2i, o1i, o2i, xinter;
    SBInterval inti, i1, i2;

    function make_result
      input SBAtomicSet aset;
      input SBLinearMap map;
      output SBPWLinearMap outMap;
    protected
      SBAtomicSet set;
      array<SBSet> dom;
      array<SBLinearMap> lm;
    algorithm
      dom := arrayCreate(1, SBSet.addAtomicSet(aset, SBSet.newEmpty()));
      lm := arrayCreate(1, map);
      outMap := SBPWLinearMap.new(dom, lm);
    end make_result;
  algorithm
    g1 := SBLinearMap.gain(lm1);
    o1 := SBLinearMap.offset(lm1);
    g2 := SBLinearMap.gain(lm2);
    o2 := SBLinearMap.offset(lm2);
    ints := SBMultiInterval.intervals(SBAtomicSet.aset(dom));
    as_aux := SBAtomicSet.copy(dom);
    lm_aux := SBLinearMap.copy(lm1);
    resg := arrayCopy(g1);
    reso := arrayCopy(o1);

    for i in 1:arrayLength(g1) loop
      g1i := g1[i];
      g2i := g2[i];
      o1i := o1[i];
      o2i := o2[i];
      inti := ints[i];

      if g1i <> g2i then
        xinter := (o2i - o1i) / (g1i - g2i);

        if xinter <= SBInterval.lowerBound(inti) then // Intersection before domain.
          if g2i < g1i then
            lm_aux := SBLinearMap.copy(lm2);
          end if;

          outMap := make_result(as_aux, lm_aux);
        elseif xinter >= SBInterval.upperBound(inti) then // Intersection after domain.
          if g2i > g1i then
            lm_aux := SBLinearMap.copy(lm2);
          end if;

          outMap := make_result(as_aux, lm_aux);
        else // Intersection in domain.
          i1 := SBInterval.new(SBInterval.lowerBound(inti),
                               SBInterval.stepValue(inti),
                               realInt(floor(xinter)));
          i2 := SBInterval.new(SBInterval.upperBound(i1) + SBInterval.stepValue(i1),
                               SBInterval.stepValue(inti),
                               SBInterval.upperBound(inti));

          d1 := SBSet.addAtomicSet(SBAtomicSet.replace(i1, i, as_aux), SBSet.newEmpty());
          d2 := SBSet.addAtomicSet(SBAtomicSet.replace(i2, i, as_aux), SBSet.newEmpty());

          dom_res := listArray({d1, d2});

          if g1i > g2i then
            lm_res := listArray({SBLinearMap.copy(lm1), SBLinearMap.copy(lm2)});
          else
            lm_res := listArray({SBLinearMap.copy(lm2), SBLinearMap.copy(lm1)});
          end if;

          outMap := SBPWLinearMap.new(dom_res, lm_res);
        end if;

        return;
      elseif o1i <> o2i then
        if o2i < o1i then
          lm_aux := SBLinearMap.copy(lm2);
        end if;

        outMap := make_result(as_aux, lm_aux);
        return;
      end if;
    end for;

    outMap := make_result(as_aux, lm_aux);
  end minAtomPW;

  function minPW
    input SBSet dom;
    input SBLinearMap lm1;
    input SBLinearMap lm2;
    output SBPWLinearMap outMap;
  protected
    array<SBSet> aux_dom;
    array<SBLinearMap> aux_lm;
    SBSet sres1, sres2, d;
    SBLinearMap lres1, lres2, l;
    array<SBAtomicSet> asets;
    SBPWLinearMap aux;
    SBAtomicSet as_aux;
    list<SBSet> sres = {};
    list<SBLinearMap> lres = {};
  algorithm
    sres1 := SBSet.newEmpty();
    lres1 := SBLinearMap.newEmpty();
    sres2 := SBSet.newEmpty();
    lres2 := SBLinearMap.newEmpty();

    if not SBSet.isEmpty(dom) then
      asets := UnorderedSet.toArray(SBSet.asets(dom));
      as_aux := asets[1];
      aux := minAtomPW(as_aux, lm1, lm2);

      if not SBPWLinearMap.isEmpty(aux) then
        sres1 := arrayGet(SBPWLinearMap.dom(aux), 1);
        lres1 := arrayGet(SBPWLinearMap.lmap(aux), 1);

        for i in 2:arrayLength(asets) loop
          aux := minAtomPW(asets[i], lm1, lm2);
          aux_dom := SBPWLinearMap.dom(aux);
          aux_lm := SBPWLinearMap.lmap(aux);

          for i in 1:arrayLength(aux_dom) loop
            d := aux_dom[i];
            l := aux_lm[i];

            if SBLinearMap.isEqual(l, lres1) then
              sres1 := SBSet.union(sres1, d);
            else
              if SBSet.isEmpty(sres2) then
                sres2 := SBSet.copy(d);
                lres2 := SBLinearMap.copy(l);
              else
                sres2 := SBSet.union(sres2, d);
              end if;
            end if;
          end for;
        end for;
      end if;
    end if;

    if not SBSet.isEmpty(sres2) and not SBLinearMap.isEmpty(lres2) then
      sres := sres2 :: sres;
      lres := lres2 :: lres;
    end if;

    if not SBSet.isEmpty(sres1) and not SBLinearMap.isEmpty(lres1) then
      sres := sres1 :: sres;
      lres := lres1 :: lres;
    end if;

    outMap := SBPWLinearMap.new(listArray(sres), listArray(lres));
  end minPW;

  function minMap2
    input SBPWLinearMap pw1;
    input SBPWLinearMap pw2;
    output SBPWLinearMap outMap = SBPWLinearMap.newEmpty();
  protected
    array<SBSet> d1, d2;
    array<SBLinearMap> lm1, lm2;
    SBSet d1i, dom;
    SBLinearMap lm1i;
    SBPWLinearMap aux;
  algorithm
    if SBPWLinearMap.isEmpty(pw1) or SBPWLinearMap.isEmpty(pw2) then
      return;
    end if;

    d1 := SBPWLinearMap.dom(pw1);
    lm1 := SBPWLinearMap.lmap(pw1);
    d2 := SBPWLinearMap.dom(pw2);
    lm2 := SBPWLinearMap.lmap(pw2);

    for i in 1:arrayLength(d1) loop
      d1i := d1[i];
      lm1i := lm1[i];

      for j in 1:arrayLength(d2) loop
        dom := SBSet.intersection(d1i, d2[j]);

        if not SBSet.isEmpty(dom) then
          aux := minPW(dom, lm1i, lm2[j]);
          outMap := if SBPWLinearMap.isEmpty(outMap) then
            aux else SBPWLinearMap.combine(aux, outMap);
        end if;
      end for;
    end for;
  end minMap2;

  function reduceMapN
    input SBPWLinearMap pw;
    input Integer dim;
    output SBPWLinearMap outMap;
  protected
    array<SBSet> dom, new_s;
    array<SBLinearMap> lmap, new_l;
    SBPWLinearMap pw_copy, new_map;
    SBSet di, new_domi, reduced, not_reduced;
    SBLinearMap li, new_lm;
    Real gdim, odim;
    Integer off;
    SBMultiInterval mi;
    SBInterval idim, new_inter;
    Integer loint, stint, hiint, newoff;
    SBAtomicSet aux_as;
    UnorderedSet<SBAtomicSet> aux_newd;
    array<SBAtomicSet> asets;
  algorithm
    dom := SBPWLinearMap.dom(pw);
    lmap := SBPWLinearMap.lmap(pw);

    pw_copy := SBPWLinearMap.copy(pw);
    outMap := SBPWLinearMap.newEmpty();
    outMap.ndim := pw.ndim;

    for i in 1:arrayLength(dom) loop
      di := dom[i];
      li := lmap[i];
      gdim := arrayGet(SBLinearMap.gain(li), dim);
      odim := arrayGet(SBLinearMap.offset(li), dim);

      if gdim == 1 and odim <> 0 then
        off := intAbs(realInt(odim));
        asets := UnorderedSet.toArray(SBSet.asets(di));

        for adom in asets loop
          mi := SBAtomicSet.aset(adom);
          idim := arrayGet(SBMultiInterval.intervals(mi), dim);
          loint := SBInterval.lowerBound(idim);
          stint := SBInterval.stepValue(idim);
          hiint := SBInterval.upperBound(idim);

          // Map's image is in adom, reduction is plausible
          if intMod(off, stint) == 0 then
            if ((hiint - loint) / stint) > off * off then
              new_s := arrayCreateNoInit(off, di);
              new_l := arrayCreateNoInit(off, li);

              for k in 1:off loop
                new_inter := SBInterval.new(loint + k - 1, off, hiint);
                aux_as := SBAtomicSet.replace(new_inter, dim, adom);
                new_s[k] := SBSet.addAtomicSet(aux_as, SBSet.newEmpty());

                if odim > 0 then
                  newoff := realInt(SBInterval.upperBound(new_inter) + odim);
                else
                  newoff := realInt(SBInterval.lowerBound(new_inter) + odim);
                end if;
                new_l[k] := SBLinearMap.replace(SBLinearMap.copy(lmap[i]), 0, newoff, dim);
              end for;
              new_map := SBPWLinearMap.new(new_s, new_l);
              outMap  := SBPWLinearMap.combine(outMap, new_map);
            end if;
          end if;
        end for;
      end if;
    end for;

    // Add intervals that weren't reduced
    reduced := SBPWLinearMap.wholeDom(outMap);
    for i in 1:arrayLength(dom) loop
      not_reduced := SBSet.complement(dom[i], reduced);

      if not SBSet.isEmpty(not_reduced) then
        new_map := SBPWLinearMap.new(arrayCreate(1, not_reduced), arrayCreate(1, lmap[i]));
        outMap  := SBPWLinearMap.combine(outMap, new_map);
      end if;
    end for;
  end reduceMapN;

  function mapInf
    input SBPWLinearMap pw;
    input Integer max_it;
    output SBPWLinearMap res = pw;
  protected
    Integer i;
    SBPWLinearMap old = SBPWLinearMap.newEmpty();
  algorithm
    if not SBPWLinearMap.isEmpty(pw) then
      i := 1;
      while (not SBPWLinearMap.isEqual(old, res) and i < max_it) loop
        old := res;
        res := SBPWLinearMap.compPW(res, pw);
        i := i + 1;
      end while;

      if SBPWLinearMap.isEqual(old, res) then
        return;
      else
        old := res;
        for j in 1:SBPWLinearMap.ndim(res) loop
          res := reduceMapN(res, j);
        end for;
        for j in 1:SBPWLinearMap.ndim(old) loop
          old := reduceMapN(old, j);
        end for;
        res := SBPWLinearMap.compPW(res, res);

        while not SBPWLinearMap.isEqual(old, res) loop
          old := res;
          res := SBPWLinearMap.compPW(res, res);
          for j in 1:SBPWLinearMap.ndim(res) loop
            res := reduceMapN(res, j);
          end for;
        end while;
      end if;
    end if;
  end mapInf;

  partial function minAdjFunc
    input SBPWLinearMap map1 "source: *this";
    input SBPWLinearMap map2 "source: pw2";
    input SBPWLinearMap map3 "source: pw1";
    output SBPWLinearMap res;
  end minAdjFunc;

  function minAdjWrapper
    input SBPWLinearMap map1 "source: *this";
    input SBPWLinearMap map2 "source: pw1";
    input minAdjFunc func;
    output SBPWLinearMap res;
  protected
    SBSet whole_dom, image_dom;
    SBPWLinearMap map2_identity "source: pw2";
  algorithm
    whole_dom     := SBPWLinearMap.wholeDom(map2);
    image_dom     := SBPWLinearMap.image(map2, whole_dom);
    map2_identity := SBPWLinearMap.newIdentity(image_dom);
    // apply function
    res := func(map1, map2, map2_identity);
  end minAdjWrapper;

  function minAdjMap extends minAdjFunc;
  protected
    SBPWLinearMap aux_map, min_adj, min_map;
  algorithm
    if not SBPWLinearMap.isEmpty(map1) then
      aux_map := SBPWLinearMap.new(arrayCreate(1, map1.dom[1]), arrayCreate(1, map1.lmap[1]));
      res := minAdjCompMap(aux_map, map2, map3);
      for i in 2:arrayLength(map1.dom) loop
        aux_map := SBPWLinearMap.new(arrayCreate(1, map1.dom[i]), arrayCreate(1, map1.lmap[i]));
        min_adj := minAdjCompMap(aux_map, map2, map3);
        min_map := minMap(aux_map, map2, map3);
        res     := SBPWLinearMap.combine(min_adj, res);
        if not SBPWLinearMap.isEmpty(min_map) then
          res   := SBPWLinearMap.combine(min_map, res);
        end if;
      end for;
    else
      res := SBPWLinearMap.newEmpty();
    end if;
  end minAdjMap;

  function minAdjCompMap extends minAdjFunc;
  protected
    Vector<SBSet> new_dom;
    Vector<SBLinearMap> new_lmap;
    SBSet inv_image, image2, image12, scomp, mins2;
    SBAtomicSet aset;
    SBLinearMap inv_map, new_map;
    SBPWLinearMap inv_pw, new_inv_pw, auxres;
    Real max_gain, min_gain;
    SBMultiInterval mi_comp;
    array<Integer> min1, min2;
    array<Real> new_gain, new_offset;
  algorithm
    new_dom   := Vector.new<SBSet>();
    new_lmap  := Vector.new<SBLinearMap>();
    if arrayLength(map1.dom) == 1 then
      inv_image := SBPWLinearMap.image(map1, map1.dom[1]);
      inv_map   := SBLinearMap.inverse(map1.lmap[1]);
      inv_pw    := SBPWLinearMap.new(arrayCreate(1, inv_image), arrayCreate(1, inv_map));

      max_gain := Array.maxElement(inv_map.gain, realLt);
      min_gain := Array.minElement(inv_map.gain, realLt);

      if max_gain < System.realMaxLit() then
        // bijective -> invertible
        res := SBPWLinearMap.compPW(map2, inv_pw);
        return;
      elseif min_gain == System.realMaxLit() then
        // constant map
        if not SBPWLinearMap.isEmpty(map1) then
          image2  := SBPWLinearMap.image(map2, map1.dom[1]);
          image12 := SBPWLinearMap.image(map1, image2);

          // Get vertices in image of pw2 with minimum image in pw1
          mi_comp := SBMultiInterval.fromList(list(SBInterval.newSingle(i) for i in SBSet.minElem(image12)));
          aset  := SBAtomicSet.new(mi_comp);
          scomp := SBSet.newEmpty();
          scomp := SBSet.addAtomicSet(aset, scomp);
          mins2 := SBPWLinearMap.preImage(map3, scomp);
          mins2 := SBSet.intersection(mins2, image2);
          min2  := SBSet.minElem(mins2);

          new_gain    := arrayCreate(inv_image.ndim, 0.0);
          new_offset  := listArray(list(intReal(i) for i in min2));
          new_map := SBLinearMap.new(new_gain, new_offset);

          Vector.push(new_dom, inv_image);
          Vector.push(new_lmap, new_map);
        end if;
      else
        // bijective in some dimensions, and constant in others
        min1  := SBSet.minElem(map1.dom[1]);

        new_gain    := arrayCreate(arrayLength(inv_map.gain), 0.0);
        new_offset  := arrayCreate(arrayLength(inv_map.offset), 0.0);
        for i in 1:arrayLength(inv_map.gain) loop
          if inv_map.gain[i] < System.realMaxLit() then
            new_gain[i]   := inv_map.gain[i];
            new_offset[i] := inv_map.offset[i];
          else
            new_offset[i] := intReal(min1[i]);
          end if;
        end for;
        new_map := SBLinearMap.new(new_gain, new_offset);
        new_inv_pw := SBPWLinearMap.new(arrayCreate(1, inv_image), arrayCreate(1, new_map));

        // compose
        auxres := SBPWLinearMap.compPW(map2, new_inv_pw);

        // Replace values of constant maps with the desired value
        image2  := SBPWLinearMap.image(map2, map1.dom[1]);
        image12 := SBPWLinearMap.image(map1, image2);

        // Get vertices in image of pw2 with minimum image in pw1
        mi_comp := SBMultiInterval.fromList(list(SBInterval.newSingle(i) for i in SBSet.minElem(image12)));
        aset  := SBAtomicSet.new(mi_comp);
        scomp := SBSet.newEmpty();
        scomp := SBSet.addAtomicSet(aset, scomp);
        mins2 := SBPWLinearMap.preImage(map3, scomp);
        mins2 := SBSet.intersection(mins2, image2);
        min2  := SBSet.minElem(mins2);

        for i in 1:arrayLength(auxres.dom) loop
          new_gain    := arrayCreate(arrayLength(inv_map.gain), 0.0);
          new_offset  := arrayCreate(arrayLength(inv_map.offset), 0.0);

          for j in 1:arrayLength(inv_map.gain) loop
            if inv_map.gain[j] < System.realMaxLit() then
              new_gain[j]   := auxres.lmap[i].gain[j];
              new_offset[j] := auxres.lmap[i].offset[j];
            else
              new_offset[j] := intReal(min2[i]);
            end if;
          end for;

          new_map := SBLinearMap.new(new_gain, new_offset);

          Vector.push(new_dom, auxres.dom[i]);
          Vector.push(new_lmap, new_map);
        end for;
      end if;
    end if;

    res := SBPWLinearMap.new(Vector.toArray(new_dom), Vector.toArray(new_lmap));
  end minAdjCompMap;

  function minMap extends minAdjFunc;
  protected
    SBSet dom;
    SBPWLinearMap aux;
  algorithm
    res := SBPWLinearMap.newEmpty();
    if not (SBPWLinearMap.isEmpty(map1) or SBPWLinearMap.isEmpty(map2)) then
      for i in 1:arrayLength(map1.dom) loop
        for j in 1:arrayLength(map2.dom) loop
          dom := SBSet.intersection(map1.dom[i], map2.dom[j]);
          if not SBSet.isEmpty(dom) then
            aux := minMapSet(dom, map1.lmap[i], map2.lmap[j]);
            if SBPWLinearMap.isEmpty(res) then
              res := aux;
            else
              res := SBPWLinearMap.combine(aux, res);
            end if;
          end if;
        end for;
      end for;
    end if;
  end minMap;

  function minMapSet
    input SBSet dom;
    input SBLinearMap lm1;
    input SBLinearMap lm2;
    output SBPWLinearMap res;
  protected
    SBLinearMap idlm;
  algorithm
    if SBLinearMap.ndim(lm1) == SBLinearMap.ndim(lm2) then
      idlm := SBLinearMap.newIdentity(SBLinearMap.ndim(lm1));
      res := minMapSet2(dom, lm1, lm2, idlm, idlm);
    else
      res := SBPWLinearMap.newEmpty();
    end if;
  end minMapSet;

  function minMapSet3
    input SBSet dom;
    input SBLinearMap lm1;
    input SBLinearMap lm2;
    input SBPWLinearMap map3;
    output SBPWLinearMap res = SBPWLinearMap.newEmpty();
  protected
    SBPWLinearMap map1 = SBPWLinearMap.new(arrayCreate(1, dom), arrayCreate(1, lm1));
    SBPWLinearMap map2 = SBPWLinearMap.new(arrayCreate(1, dom), arrayCreate(1, lm2));
    SBSet image1, image2, d, d1, d2, pre1, pre2;
  algorithm
    image1 := SBPWLinearMap.image(map1, dom);
    image2 := SBPWLinearMap.image(map2, dom);
    for i in 1:arrayLength(map3.dom) loop
      d1 := SBSet.intersection(map3.dom[i], image1);
      if not SBSet.isEmpty(d1) then
        pre1 := SBPWLinearMap.preImage(map1, d1);
        for j in 1:arrayLength(map3.dom) loop
          d2 := SBSet.intersection(map3.dom[j], image2);
          if not SBSet.isEmpty(d2) then
            pre2 := SBPWLinearMap.preImage(map2, d2);
            d := SBSet.intersection(SBSet.intersection(pre1, pre2), dom);
            if not SBSet.isEmpty(d) then
              res := SBPWLinearMap.combine(res, minMapSet2(d, lm1, lm2, map3.lmap[i], map3.lmap[j]));
            end if;
          end if;
        end for;
      end if;
    end for;
  end minMapSet3;

  function minMapSet2
    input SBSet dom;
    input SBLinearMap lm1;
    input SBLinearMap lm2;
    input SBLinearMap lm3;
    input SBLinearMap lm4;
    output SBPWLinearMap res;
  protected
    SBAtomicSet asAux;
    list<SBAtomicSet> asets = UnorderedSet.toList(dom.asets);
    SBPWLinearMap aux = SBPWLinearMap.newEmpty();
    SBSet sres1, sres2 = SBSet.newEmpty();
    SBLinearMap lres1, lres2;
    Vector<SBSet> new_dom = Vector.new<SBSet>();
    Vector<SBLinearMap> new_lmap = Vector.new<SBLinearMap>();
  algorithm
    asAux::asets := asets;
    if not SBSet.isEmpty(dom) then
      aux := minMapAtomSet(aux, asAux, lm1, lm2, lm3, lm4);
      if not SBPWLinearMap.isEmpty(aux) then
        sres1 := aux.dom[1];
        lres1 := aux.lmap[1];
        for aset in asets loop
          aux := minMapAtomSet(aux, asAux, lm1, lm2, lm3, lm4);
          for i in 1:arrayLength(aux.dom) loop
            if SBLinearMap.isEqual(aux.lmap[i], lres1) then
              sres1 := SBSet.union(sres1, aux.dom[i]);
            else
              if SBSet.isEmpty(sres2) then
                sres2 := aux.dom[i];
                lres2 := aux.lmap[i];
              else
                sres2 := SBSet.union(sres2, aux.dom[i]);
              end if;
            end if;
          end for;
        end for;
      end if;
    end if;

    // combine the sets
    if not (SBSet.isEmpty(sres1) or SBLinearMap.isEmpty(lres1)) then
      Vector.push(new_dom, sres1);
      Vector.push(new_lmap, lres1);
    end if;
    if not (SBSet.isEmpty(sres2) or SBLinearMap.isEmpty(lres2)) then
      Vector.push(new_dom, sres2);
      Vector.push(new_lmap, lres2);
    end if;
    res := SBPWLinearMap.new(Vector.toArray(new_dom), Vector.toArray(new_lmap));
  end minMapSet2;

  function minMapAtomSet
    input output SBPWLinearMap res;
    input SBAtomicSet dom;
    input SBLinearMap lm1;
    input SBLinearMap lm2;
    input SBLinearMap lm3;
    input SBLinearMap lm4;
  protected
    SBAtomicSet as1, as2;
    SBLinearMap lmAux;
    SBLinearMap lm31 = SBLinearMap.compose(lm3, lm1);
    SBLinearMap lm42 = SBLinearMap.compose(lm4, lm2);
    SBSet d1, d2, aux = SBSet.newEmpty();
    Vector<SBSet> new_dom = Vector.new<SBSet>();
    Vector<SBLinearMap> new_lmap = Vector.new<SBLinearMap>();
    SBLinearMap id;
    Real xinter;
    SBInterval i1, i2;
  algorithm
    aux := SBSet.addAtomicSet(dom, aux);

    // base case
    if SBLinearMap.isEqual(lm31, lm42) and SBLinearMap.isEqual(lm1, lm2) then
      Vector.push(new_dom, aux);
      Vector.push(new_lmap, lm1);
      res := SBPWLinearMap.new(Vector.toArray(new_dom), Vector.toArray(new_lmap));
      return;
    end if;

    // need to analyze gains and offsets of lm31 and lm42
    if SBLinearMap.ndim(lm31) == SBLinearMap.ndim(lm42) and SBLinearMap.ndim(lm1) == SBLinearMap.ndim(lm2) then
      for i in 1:arrayLength(lm31.gain) loop
        lmAux := lm1;

        if lm31.gain[i] <> lm42.gain[i] then
          // different gains, there's intersection
          xinter := (lm42.offset[i] - lm31.offset[i]) / (lm31.gain[i] - lm42.gain[i]);

          if xinter <= intReal(dom.aset.intervals[i].lo) then
            // 1. intersection before domain
            if lm42.gain[i] < lm31.gain[i] then
              lmAux := lm2;
            end if;
            Vector.push(new_dom, aux);
            Vector.push(new_lmap, lmAux);
          elseif xinter >= intReal(dom.aset.intervals[i].hi) then
            // 2. intersection after domain
            if lm42.gain[i] > lm31.gain[i] then
              lmAux := lm2;
            end if;
            Vector.push(new_dom, aux);
            Vector.push(new_lmap, lmAux);
          else
            // 3. intersection in domain
            i1 := SBInterval.INTERVAL(dom.aset.intervals[i].lo, dom.aset.intervals[i].step, realInt(floor(xinter)));
            i2 := SBInterval.INTERVAL(i1.hi + i1.step, dom.aset.intervals[i].step, dom.aset.intervals[i].hi);
            as1 := SBAtomicSet.replace(i1, i, dom);
            as2 := SBAtomicSet.replace(i2, i, dom);
            d1 := SBSet.newEmpty();
            d2 := SBSet.newEmpty();
            d1 := SBSet.addAtomicSet(as1, d1);
            d2 := SBSet.addAtomicSet(as2, d2);
            Vector.push(new_dom, d1);
            Vector.push(new_dom, d2);

            if lm31.gain[i] > lm42.gain[i] then
              Vector.push(new_lmap, lm1);
              Vector.push(new_lmap, lm2);
            else
              Vector.push(new_lmap, lm2);
              Vector.push(new_lmap, lm1);
            end if;
          end if;
          res := SBPWLinearMap.new(Vector.toArray(new_dom), Vector.toArray(new_lmap));
          return;
        elseif lm31.offset[i] <> lm42.offset[i] then
          // same gain and different offset, no intersection
          if lm42.offset[i] < lm31.offset[i] then
            lmAux := lm2;
          end if;
          Vector.push(new_dom, aux);
          Vector.push(new_lmap, lmAux);
          res := SBPWLinearMap.new(Vector.toArray(new_dom), Vector.toArray(new_lmap));
          return;
        end if;
      end for;
    end if;

    // same gain and offset, get the minimum: lm1 or lm2
    id := SBLinearMap.newIdentity(SBLinearMap.ndim(lm1));
    res := minMapAtomSet(res, dom, lm1, lm2, id, id);
  end minMapAtomSet;

  function connectedComponents
    input SBSet vss;
    input SBPWLinearMap emap1;
    input SBPWLinearMap emap2;
    output SBPWLinearMap outMap;
  protected
    SBPWLinearMap ermap1, ermap2, rmap1, rmap2, new_res;
    SBSet last_im, new_im, diff_im;
  algorithm
    outMap := SBPWLinearMap.newIdentity(vss); // connected vertices map
    new_im := vss;
    diff_im := vss;
    while not SBSet.isEmpty(diff_im) loop
      // map left and right map to minimal connected indices
      ermap1 := SBPWLinearMap.compPW(outMap, emap1);
      ermap2 := SBPWLinearMap.compPW(outMap, emap2);

      // combine maps to get minimal connection from left to right and vice versa
      rmap1 := minAdjWrapper(ermap1, ermap2, minAdjMap);
      rmap2 := minAdjWrapper(ermap2, ermap1, minAdjMap);
      // inverse apply connected minimal indices to connect from cluster to cluster
      rmap1 := SBPWLinearMap.combine(rmap1, outMap);
      rmap2 := SBPWLinearMap.combine(rmap2, outMap);
      // find minimal connections
      new_res := minAdjWrapper(rmap1, rmap2, minMap);

      last_im := new_im;
      new_im := SBPWLinearMap.image(new_res, vss);
      diff_im := SBSet.complement(last_im, new_im);

      if not SBSet.isEmpty(diff_im) then
        // if there is a difference apply infinity map
        outMap := mapInf(new_res, 1);
        new_im := SBPWLinearMap.image(outMap, vss);
      else
        outMap := new_res;
      end if;

    end while;
  end connectedComponents;

  function make_set
    input list<SBInterval> i;
    output SBSet s;
  protected
    UnorderedSet<SBAtomicSet> ss;
  algorithm
    ss := UnorderedSet.new(SBAtomicSet.hash, SBAtomicSet.isEqual);
    UnorderedSet.add(SBAtomicSet.new(SBMultiInterval.fromList(i)), ss);
    s := SBSet.new(ss);
  end make_set;

  function make_pw
    input list<SBInterval> i;
    input list<Real> gain;
    input list<Real> offset;
    output SBPWLinearMap pw;
  protected
    SBSet dom;
    SBLinearMap lmap;
  algorithm
    dom := make_set(i);
    lmap := SBLinearMap.new(listArray(gain), listArray(offset));
    pw := SBPWLinearMap.newScalar(dom, lmap);
  end make_pw;

annotation(__OpenModelica_Interface="util");
end SBFunctions;
