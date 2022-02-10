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

encapsulated uniontype SBAtomicSet

  import SBMultiInterval;
  import UnorderedSet;

protected

public
  record ATOMIC_SET
    SBMultiInterval aset;
    Integer ndim;
  end ATOMIC_SET;

  function new
    input SBMultiInterval mi;
    output SBAtomicSet set;
  algorithm
    set := ATOMIC_SET(SBMultiInterval.copy(mi), mi.ndim);
  end new;

  function newEmpty
    output SBAtomicSet set;
  algorithm
    set := ATOMIC_SET(SBMultiInterval.newEmpty(), 0);
  end newEmpty;

  function copy
    input SBAtomicSet set;
    output SBAtomicSet outSet;
  algorithm
    outSet := ATOMIC_SET(SBMultiInterval.copy(set.aset), set.ndim);
  end copy;

  function ndim
    input SBAtomicSet set;
    output Integer ndim = set.ndim;
  end ndim;

  function isEmpty
    input SBAtomicSet set;
    output Boolean empty = SBMultiInterval.isEmpty(set.aset);
  end isEmpty;

  function contains
    input array<Integer> vals;
    input SBAtomicSet set;
    output Boolean res = SBMultiInterval.contains(vals, set.aset);
  end contains;

  function intersection
    input SBAtomicSet set1;
    input SBAtomicSet set2;
    output SBAtomicSet res;
  algorithm
    res := new(SBMultiInterval.intersection(set1.aset, set2.aset));
  end intersection;

  function complement
    input SBAtomicSet set1;
    input SBAtomicSet set2;
    output UnorderedSet<SBAtomicSet> res;
  protected
    UnorderedSet<SBMultiInterval> diff;
  algorithm
    diff := SBMultiInterval.complement(set1.aset, set2.aset);
    res := UnorderedSet.new(hash, isEqual, UnorderedSet.bucketCount(diff));

    if not UnorderedSet.isEmpty(diff) then
      for s in UnorderedSet.toArray(diff) loop
        UnorderedSet.add(new(s), res);
      end for;
    end if;
  end complement;

  function crossProd
    input SBAtomicSet set1;
    input SBAtomicSet set2;
    output SBAtomicSet res;
  algorithm
    res := new(SBMultiInterval.crossProd(set1.aset, set2.aset));
  end crossProd;

  function cardinality
    input SBAtomicSet set;
    input output Integer card = 0;
  algorithm
    card := card + SBMultiInterval.cardinality(set.aset);
  end cardinality;

  function aset
    input SBAtomicSet set;
    output SBMultiInterval res = set.aset;
  end aset;

  function minElem
    input SBAtomicSet set;
    output array<Integer> res = SBMultiInterval.minElem(set.aset);
  end minElem;

  function replace
    input SBInterval i;
    input Integer dim;
    input SBAtomicSet set;
    output SBAtomicSet res;
  algorithm
    res := new(SBMultiInterval.replace(i, dim, set.aset));
  end replace;

  function isEqual
    input SBAtomicSet set1;
    input SBAtomicSet set2;
    output Boolean equal = SBMultiInterval.isEqual(set1.aset, set2.aset);
  end isEqual;

  function hash
    input SBAtomicSet set1;
    input Integer mod;
    output Integer hash = SBMultiInterval.hash(set1.aset, mod);
  end hash;

  function toString
    input SBAtomicSet set;
    output String str = "{" + SBMultiInterval.toString(set.aset) + "}";
  end toString;

annotation(__OpenModelica_Interface="util");
end SBAtomicSet;
