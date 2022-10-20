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
  import Util;
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

  function minMap
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
  end minMap;

  function reduceMapN
    input SBPWLinearMap pw;
    input Integer dim;
    output SBPWLinearMap outMap;
  protected
    array<SBSet> dom, new_s;
    Vector<SBSet> sres;
    array<SBLinearMap> lmap, new_l;
    Vector<SBLinearMap> lres;
    SBPWLinearMap pw_copy, new_map;
    SBSet di, new_domi;
    SBLinearMap li, new_lm;
    Real gdim, odim;
    Integer off;
    SBMultiInterval mi;
    SBInterval idim, new_inter;
    Integer loint, hiint;
    array<Real> resg, reso;
    SBAtomicSet aux_as;
    UnorderedSet<SBAtomicSet> aux_newd;
    array<SBAtomicSet> asets;
  algorithm
    dom := SBPWLinearMap.dom(pw);
    lmap := SBPWLinearMap.lmap(pw);

    pw_copy := SBPWLinearMap.copy(pw);
    sres := Vector.fromArray(SBPWLinearMap.dom(pw_copy));
    lres := Vector.fromArray(SBPWLinearMap.lmap(pw_copy));

    for i in 1:arrayLength(dom) loop
      di := dom[i];
      li := lmap[i];
      gdim := arrayGet(SBLinearMap.gain(li), dim);
      odim := arrayGet(SBLinearMap.offset(li), dim);

      if gdim == 1 and odim < 0 then
        off := realInt(-odim);
        asets := UnorderedSet.toArray(SBSet.asets(di));

        for adom in asets loop
          mi := SBAtomicSet.aset(adom);
          idim := arrayGet(SBMultiInterval.intervals(mi), dim);
          loint := SBInterval.lowerBound(idim);
          hiint := SBInterval.upperBound(idim);

          if hiint - loint > off * off then
            new_s := arrayCreateNoInit(off, di);
            new_l := arrayCreateNoInit(off, li);

            for k in 1:off loop
              resg := arrayCopy(SBLinearMap.gain(li));
              reso := arrayCopy(SBLinearMap.offset(li));
              resg[dim] := 0;
              reso[dim] := loint + k - off - 1;

              new_l[k] := SBLinearMap.new(resg, reso);

              new_inter := SBInterval.new(loint + k - 1, off, hiint);
              aux_as := SBAtomicSet.replace(new_inter, dim, adom);
              new_s[k] := SBSet.addAtomicSet(aux_as, SBSet.newEmpty());
            end for;

            new_map := SBPWLinearMap.new(new_s, new_l);

            aux_newd := UnorderedSet.new(SBAtomicSet.hash, SBAtomicSet.isEqual);
            for aux_asi in asets loop
              if not SBAtomicSet.isEqual(aux_asi, adom) then
                UnorderedSet.add(aux_asi, aux_newd);
              end if;
            end for;

            new_domi := SBSet.new(aux_newd);

            if SBSet.isEmpty(new_domi) then
              if i < Vector.size(sres) then
                Vector.remove(sres, i);
                Vector.remove(lres, i);
              else
                Vector.shrink(sres, i + 1);
                Vector.shrink(lres, i + 1);
              end if;
            else
              Vector.update(sres, i, new_domi);
            end if;

            Vector.appendArray(sres, SBPWLinearMap.dom(new_map));
            Vector.appendArray(lres, SBPWLinearMap.lmap(new_map));
          end if;
        end for;
      end if;
    end for;

    outMap := SBPWLinearMap.new(Vector.toArray(sres), Vector.toArray(lres));
  end reduceMapN;

  function mapInf
    input SBPWLinearMap pw;
    input Integer max_it;
    output SBPWLinearMap res = pw;
  protected
    Integer i;
    SBPWLinearMap original = pw, old = SBPWLinearMap.newEmpty();
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
        res := SBPWLinearMap.compPW(res, pw);
        for j in 1:SBPWLinearMap.ndim(old) loop
          old := reduceMapN(old, j);
        end for;
        for j in 1:SBPWLinearMap.ndim(res) loop
          res := reduceMapN(res, j);
        end for;

        while not SBPWLinearMap.isEqual(old, res) loop
          old := res;
          res := SBPWLinearMap.compPW(res, pw);
          for j in 1:SBPWLinearMap.ndim(res) loop
            res := reduceMapN(res, j);
          end for;
        end while;
      end if;
    end if;
  end mapInf;

  function minAdjCompMap
    input SBPWLinearMap pw2;
    input SBPWLinearMap pw1;
    output SBPWLinearMap outMap;
  protected
    array<SBSet> dom;
    array<SBLinearMap> lmap;
    SBSet d, dom_inv, aux;
    SBLinearMap lm_inv, aux_lm1, aux_lm2, lm_res;
    SBPWLinearMap inv_pw, aux_inv, aux_res;
    Real min_g, max_g, inf, g;
    array<Integer> min_aux;
    array<Real> resg, reso, gain, off, gres, oi, ginv;
  algorithm
    dom := SBPWLinearMap.dom(pw2);
    lmap := SBPWLinearMap.lmap(pw2);

    if arrayLength(dom) <> 1 then
      // Warning: There should be only one pair in the map.
      outMap := SBPWLinearMap.newEmpty();
      return;
    end if;

    d := dom[1];
    dom_inv := SBPWLinearMap.image(pw2, d);
    lm_inv := SBLinearMap.inverse(lmap[1]);

    inv_pw := SBPWLinearMap.newScalar(dom_inv, lm_inv);
    inf := intReal(System.intMaxLit());

    if Array.maxElement(SBLinearMap.gain(lm_inv), realLt) < inf then
      outMap := SBPWLinearMap.compPW(pw1, inv_pw);
    elseif Array.minElement(SBLinearMap.gain(lm_inv), realLt) == inf then
      if not SBPWLinearMap.isEmpty(pw2) then
        aux := SBPWLinearMap.image(pw1, d);
        min_aux := SBSet.minElem(aux);
        resg := arrayCreate(arrayLength(min_aux), 0.0);
        reso := Array.map(min_aux, intReal);
        lm_res := SBLinearMap.new(resg, reso);
        outMap := SBPWLinearMap.newScalar(dom_inv, lm_res);
      else
        outMap := SBPWLinearMap.newEmpty();
      end if;
    else
      min_aux := SBSet.minElem(d);
      gain := SBLinearMap.gain(lm_inv);
      off := SBLinearMap.offset(lm_inv);
      resg := arrayCreateNoInit(arrayLength(gain), 0.0);
      reso := arrayCreateNoInit(arrayLength(gain), 0.0);

      for i in 1:arrayLength(gain) loop
        g := arrayGetNoBoundsChecking(gain, i);

        if g == inf then
          resg[i] := 0.0;
          reso[i] := intReal(min_aux[i]);
        else
          resg[i] := g;
          reso[i] := off[i];
        end if;
      end for;

      aux_lm1 := SBLinearMap.new(resg, reso);
      aux_inv := SBPWLinearMap.newScalar(dom_inv, aux_lm1);
      aux_res := SBPWLinearMap.compPW(pw1, aux_inv);

      if SBPWLinearMap.isEmpty(aux_res) then
        outMap := SBPWLinearMap.newEmpty();
      else
        aux := SBPWLinearMap.image(pw1, d);
        min_aux := SBSet.minElem(aux);
        lm_res := arrayGet(SBPWLinearMap.lmap(aux_res), 1);
        gres := SBLinearMap.gain(lm_res);
        oi := SBLinearMap.offset(lm_res);
        ginv := SBLinearMap.gain(lm_inv);

        for i in 1:arrayLength(gain) loop
          g := arrayGetNoBoundsChecking(gain, i);

          if g == inf then
            resg[i] := 0.0;
            reso[i] := intReal(min_aux[i]);
          else
            resg[i] := gres[i];
            reso[i] := oi[i];
          end if;
        end for;

        aux_lm2 := SBLinearMap.new(resg, reso);
        outMap := SBPWLinearMap.newScalar(arrayGet(SBPWLinearMap.dom(aux_res), 1), aux_lm2);
      end if;
    end if;
  end minAdjCompMap;

  function minAdjMap
    input SBPWLinearMap pw2;
    input SBPWLinearMap pw1;
    output SBPWLinearMap outMap;
  protected
    array<SBSet> dom2;
    array<SBLinearMap> lm2;
    SBPWLinearMap map1, mapi, min_adj, min_m;
  algorithm
    if SBPWLinearMap.isEmpty(pw2) then
      outMap := SBPWLinearMap.newEmpty();
      return;
    end if;

    dom2 := SBPWLinearMap.dom(pw2);
    lm2 := SBPWLinearMap.lmap(pw2);
    map1 := SBPWLinearMap.newScalar(dom2[1], lm2[1]);
    outMap := minAdjCompMap(map1, pw1);

    for i in 1:arrayLength(dom2) loop
      mapi := SBPWLinearMap.newScalar(dom2[i], lm2[i]);
      min_adj := minAdjCompMap(mapi, pw1);
      min_m := minMap(outMap, min_adj);

      outMap := SBPWLinearMap.combine(min_adj, outMap);

      if not SBPWLinearMap.isEmpty(min_m) then
        outMap := SBPWLinearMap.combine(min_m, outMap);
      end if;
    end for;
  end minAdjMap;

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
      rmap1 := minAdjMap(ermap1, ermap2);
      rmap2 := minAdjMap(ermap2, ermap1);
      // inverse apply connected minimal indices to connect from cluster to cluster
      rmap1 := SBPWLinearMap.combine(rmap1, outMap);
      rmap2 := SBPWLinearMap.combine(rmap2, outMap);
      // find minimal connections
      new_res := minMap(rmap1, rmap2);

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
