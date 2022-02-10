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

encapsulated uniontype SBSet
  import SBAtomicSet;
  import UnorderedSet;

protected
  import Array;
  import List;
  import Vector;

public
  record SET
    UnorderedSet<SBAtomicSet> asets;
    Integer ndim;
  end SET;

  function new
    input UnorderedSet<SBAtomicSet> ss;
    output SBSet set;
  protected
    Integer dim;

    function is_equal_dim
      input SBAtomicSet set1;
      input Integer dim;
      output Boolean equal = SBAtomicSet.ndim(set1) == dim;
    end is_equal_dim;
  algorithm
    if not UnorderedSet.isEmpty(ss) then
      dim := SBAtomicSet.ndim(UnorderedSet.first(ss));

      if dim <> 0 and UnorderedSet.all(ss, function is_equal_dim(dim = dim)) then
        // TODO: Since MetaModelica doesn't have copy semantics this doesn't
        //       copy the elements in the set, only the set itself. That might
        //       cause some issues if they're changed in the input set.
        set := SET(UnorderedSet.copy(ss), dim);
      else
        // Error: Using atomic sets of different sizes.
        set := newEmpty();
      end if;
    else
      set := SET(UnorderedSet.copy(ss), 0);
    end if;
  end new;

  function newEmpty
    output SBSet set;
  algorithm
    set := SET(UnorderedSet.new(SBAtomicSet.hash, SBAtomicSet.isEqual), 0);
  end newEmpty;

  function copy
    input output SBSet set;
  algorithm
    set.asets := UnorderedSet.copy(set.asets);
  end copy;

  function ndim
    input SBSet set;
    output Integer ndim = set.ndim;
  end ndim;

  function isEmpty
    input SBSet set;
    output Boolean empty = UnorderedSet.isEmpty(set.asets);
  end isEmpty;

  function isDim
    input SBSet set;
    input Integer dim;
    output Boolean res = set.ndim == dim;
  end isDim;

  function asets
    input SBSet set;
    output UnorderedSet<SBAtomicSet> asets = set.asets;
  end asets;

  function contains
    input array<Integer> vals;
    input SBSet set;
    output Boolean res;
  algorithm
    res := UnorderedSet.all(set.asets, function SBAtomicSet.contains(vals = vals));
  end contains;

  function addAtomicSet
    // TODO: SBSet is semi-mutable, should we make ndim mutable to make it
    //       completely mutable or make a copy of the set here?
    input SBAtomicSet aset;
    input output SBSet set;
  algorithm
    if SBAtomicSet.isEmpty(aset) then
      return;
    end if;

    if UnorderedSet.isEmpty(set.asets) then
      UnorderedSet.add(aset, set.asets);
      set.ndim := SBAtomicSet.ndim(aset);
    elseif SBAtomicSet.ndim(aset) == set.ndim then
      UnorderedSet.add(aset, set.asets);
    // else
    //   Error: Atomic sets should have the same dimension.
    end if;
  end addAtomicSet;

  function addAtomicSets
    input UnorderedSet<SBAtomicSet> asets;
    input output SBSet set;
  algorithm
    set := UnorderedSet.fold(asets, addAtomicSet, set);
  end addAtomicSets;

  function intersection
    input SBSet set1;
    input SBSet set2;
    output SBSet outSet;
  protected
    SBAtomicSet int_set;
    UnorderedSet<SBAtomicSet> res;
  algorithm
    if UnorderedSet.isEmpty(set1.asets) or UnorderedSet.isEmpty(set2.asets) then
      outSet := newEmpty();
      return;
    end if;

    res := UnorderedSet.new(SBAtomicSet.hash, SBAtomicSet.isEqual);

    for as1 in UnorderedSet.toArray(set1.asets) loop
      for as2 in UnorderedSet.toArray(set2.asets) loop
        int_set := SBAtomicSet.intersection(as1, as2);

        if not SBAtomicSet.isEmpty(int_set) then
          UnorderedSet.add(int_set, res);
        end if;
      end for;
    end for;

    outSet := new(res);
  end intersection;

  function complement
    input SBSet set1;
    input SBSet set2;
    output SBSet outSet;
  protected
    UnorderedSet<SBAtomicSet> int_res, aux, comp_res;
    SBSet new_sets;
  algorithm
    outSet := newEmpty();
    SET(asets = int_res) := intersection(set1, set2);

    if not UnorderedSet.isEmpty(int_res) then
      for as1 in UnorderedSet.toArray(set1.asets) loop
        aux := UnorderedSet.new(SBAtomicSet.hash, SBAtomicSet.isEqual);
        UnorderedSet.add(as1, aux);

        for as2 in UnorderedSet.toArray(int_res) loop
          new_sets := newEmpty();

          for as3 in UnorderedSet.toArray(aux) loop
            comp_res := SBAtomicSet.complement(as3, as2);
            new_sets := addAtomicSets(comp_res, new_sets);
          end for;

          aux := new_sets.asets;
        end for;

        outSet := addAtomicSets(aux, outSet);
      end for;
    else
      outSet := addAtomicSets(set1.asets, outSet);
    end if;
  end complement;

  function union
    input SBSet set1;
    input SBSet set2;
    output SBSet outSet;
  protected
    SBSet aux;
  algorithm
    outSet := SET(UnorderedSet.copy(set1.asets), set1.ndim);
    aux := complement(set2, outSet);

    if not isEmpty(aux) then
      outSet := addAtomicSets(aux.asets, outSet);
    end if;
  end union;

  function card
    "the name cardinality seems to be reserved and cannot be used inside of the same scope
    ToDo: rename the others?"
    input SBSet set;
    output Integer cardinality = UnorderedSet.fold(set.asets, SBAtomicSet.cardinality, 0);
  end card;

  function maxCardinality
    "ToDo kabdelhak: this can be optimized by storing all the cardinalities and update them if a set is changed"
    input Vector<SBSet> sets;
    output SBSet maxSet;
    output Integer index;
    function maxCardinality_traverse
      input SBSet set;
      output Boolean res = false;
      input output Integer maxCard;
    protected
      Integer cardinality = card(set);
    algorithm
      if cardinality > maxCard then
        res := true;
        maxCard := cardinality;
      end if;
    end maxCardinality_traverse;
  algorithm
    try
      (SOME(maxSet), index, _) := Vector.findFold(sets, maxCardinality_traverse, 0);
    else
      fail();
    end try;
  end maxCardinality;

  function minElem
    input SBSet set;
    output array<Integer> res;
  protected
    function lessFn
      input array<Integer> set1;
      input array<Integer> set2;
      output Boolean res;
    algorithm
      res := Array.isLess(set1, set1, intLt);
    end lessFn;

    list<array<Integer>> min_elems;
  algorithm
    if isEmpty(set) then
      res := listArray({});
    else
      min_elems := list(SBAtomicSet.minElem(e) for e in UnorderedSet.toArray(set.asets));
      res := List.minElement(min_elems, lessFn);
    end if;
  end minElem;

  function isEqual
    input SBSet set1;
    input SBSet set2;
    output Boolean equal = UnorderedSet.isEqual(set1.asets, set2.asets);
  end isEqual;

  function hash
    input SBSet set;
    input Integer mod;
    output Integer hash = intMod(UnorderedSet.size(set.asets), mod);
  end hash;

  function toString
    input SBSet set;
    output String str;
  algorithm
    str := "{" + UnorderedSet.toString(set.asets, SBAtomicSet.toString, "U") + "}";
  end toString;

annotation(__OpenModelica_Interface="util");
end SBSet;
