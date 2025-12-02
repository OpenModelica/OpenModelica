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

encapsulated uniontype UnorderedSet<T>
  "An implementation of a generic unordered set, a.k.a. hash set.

   This implementation uses separate chaining and automatically rehashes the set
   when the load factor becomes too large to keep the performance up."

  import Mutable;

protected
  import Array;
  import List;
  import MetaModelica.Dangerous.*;
  import Util;

public
  partial function Hash
    input T key;
    output Integer hash;
  end Hash;

  partial function KeyEq
    input T key1;
    input T key2;
    output Boolean equal;
  end KeyEq;

  record UNORDERED_SET
    Mutable<array<list<T>>> buckets;
    Mutable<Integer> size;
    Hash hashFn;
    KeyEq eqFn;
  end UNORDERED_SET;

  function new<T>
    "Creates a new set given a hash function, equality function, and optional
     desired bucket count. An approriate bucket count is
     Util.nextPrime(number of elements that will be added), but starting with a
     low bucket count is also fine if the number of elements is unknown since the
     set rehashes as needed."
    input Hash hash;
    input KeyEq keyEq;
    input Integer bucketCount = 13;
    output UnorderedSet<T> set;
  protected
    Mutable<array<list<T>>> buckets;
  algorithm
    buckets := Mutable.create(arrayCreate(bucketCount, {}));
    set := UNORDERED_SET(buckets, Mutable.create(0), hash, keyEq);
  end new;

  function fromList
    input list<T> elements;
    input Hash hash;
    input KeyEq keyEq;
    output UnorderedSet<T> set;
  algorithm
    set := new<T>(hash, keyEq, Util.nextPrime(listLength(elements)));

    for e in elements loop
      add(e, set);
    end for;
  end fromList;

  function copy
    "Returns a copy of the given set."
    input UnorderedSet<T> set;
    output UnorderedSet<T> outSet;
  algorithm
    outSet := UNORDERED_SET(
      Mutable.create(arrayCopy(Mutable.access(set.buckets))),
      Mutable.create(Mutable.access(set.size)),
      set.hashFn,
      set.eqFn
    );
  end copy;

  function add
    "Adds a key to the set unless the key already exists in the set, in which
     case nothing is done. Might trigger a rehash."
    input T key;
    input UnorderedSet<T> set;
  protected
    Integer hash, pos;
    Option<T> okey;
  algorithm
    (okey, hash) := find(key, set);

    if isNone(okey) then
      addKey(key, hash, set);
    end if;
  end add;

  function addNew
    "Adds a key to the set without checking if it already exists. Faster than
     add since it doesn't need to check if the key exists, but will lead to
     duplicate keys if it actually does exist in the set already. Might trigger
     a rehash."
    input T key;
    input UnorderedSet<T> set;
  protected
    Hash hashfn = set.hashFn;
    Integer hash, pos;
  algorithm
    hash := intMod(hashfn(key), arrayLength(Mutable.access(set.buckets)));
    addKey(key, hash, set);
  end addNew;

  function addUnique
    "Adds a key to the set, but fails if the key already exists.
     Might trigger a rehash."
    input T key;
    input UnorderedSet<T> set;
  protected
    Integer hash;
  algorithm
    (NONE(), hash) := find(key, set);
    addKey(key, hash, set);
  end addUnique;

  function remove
    "Removes a key from the set. Returns true if the key existed in the set and
     was removed, or false if the key did not exist in the set.

     Will not trigger a rehash, so rehash must be called manually if shrinking
     the set is desirable (probably not a good idea unless the load factor is
     very low, i.e. less than 0.25 or so)."
    input T key;
    input UnorderedSet<T> set;
    output Boolean removed;
  protected
    array<list<T>> buckets = Mutable.access(set.buckets);
    Hash hashfn = set.hashFn;
    KeyEq eqfn = set.eqFn;
    Integer hash;
    list<T> bucket;
    Option<T> okey;
  algorithm
    hash := intMod(hashfn(key), arrayLength(buckets));
    bucket := arrayGet(buckets, hash + 1);

    (bucket, okey) := List.deleteMemberOnTrue(key, bucket, eqfn);
    removed := isSome(okey);

    if removed then
      arrayUpdateNoBoundsChecking(buckets, hash + 1, bucket);
      Mutable.update(set.size, Mutable.access(set.size) - 1);
    end if;
  end remove;

  function get
    "Returns SOME(key) if the key exists in the set, otherwise NONE()."
    input T key;
    input UnorderedSet<T> set;
    output Option<T> outKey;
  algorithm
    outKey := find(key, set);
  end get;

  function getOrFail
    "Returns a key if it exists in the set, otherwise fails."
    input T key;
    input UnorderedSet<T> set;
    output T outKey;
  protected
    Option<T> okey;
  algorithm
    okey := find(key, set);
    SOME(outKey) := okey;
  end getOrFail;

  function contains
    "Returns whether the given key exists in the set or not."
    input T key;
    input UnorderedSet<T> set;
    output Boolean res;
  algorithm
    res := isSome(find(key, set));
  end contains;

  function first
    "Returns the first element in the set, or fails if the set is empty.
     Since the set is unordered there isn't really any 'first' element though,
     it will just return the first element in the first non-empty bucket."
    input UnorderedSet<T> set;
    output T val;
  algorithm
    for b in Mutable.access(set.buckets) loop
      for k in b loop
        val := k;
        return;
      end for;
    end for;

    fail();
  end first;

  function isEqual
    "Returns true if the sets have the same size and contain the same elements,
     otherwise false."
    input UnorderedSet<T> set1;
    input UnorderedSet<T> set2;
    output Boolean equal = true;
  algorithm
    if Mutable.access(set1.size) <> Mutable.access(set2.size) then
      equal := false;
      return;
    end if;

    for b in Mutable.access(set1.buckets) loop
      for k in b loop
        if not contains(k, set2) then
          equal := false;
          return;
        end if;
      end for;
    end for;
  end isEqual;

  function toList
    "Returns the elements in the set as a list in no particular order."
    input UnorderedSet<T> set;
    output list<T> outList = {};
  algorithm
    for b in Mutable.access(set.buckets) loop
      for k in b loop
        outList := k :: outList;
      end for;
    end for;
  end toList;

  function toArray
    "Returns the elements in the set as an array in no particular order."
    input UnorderedSet<T> set;
    output array<T> outArray;
  protected
    T dummy = dummy; // Fool the compiler into thinking dummy is initialized.
    Integer i = 1;
  algorithm
    outArray := arrayCreateNoInit(Mutable.access(set.size), dummy);

    for b in Mutable.access(set.buckets) loop
      for k in b loop
        arrayUpdateNoBoundsChecking(outArray, i, k);
        i := i + 1;
      end for;
    end for;
  end toArray;

  function fold<FT>
    "Folds over the keys in the set."
    input UnorderedSet<T> set;
    input FoldFn fn;
    input FT startValue;
    output FT result = startValue;

    partial function FoldFn
      input T key;
      input output FT arg;
    end FoldFn;
  algorithm
    for b in Mutable.access(set.buckets) loop
      for k in b loop
        result := fn(k, result);
      end for;
    end for;
  end fold;

/*
  function map<OT>
    "Applies a function to all keys in the given set and returns a new set
     with the new keys."
    input UnorderedSet<T> set;
    input MapFn fn;
    input OutHash hash;
    input OutKeyEq keyEq;
    output UnorderedSet<OT> outSet;

    partial function MapFn
      input T key;
      output OT outKey;
    end MapFn;
    partial function OutHash
      input OT key;
      input Integer mod;
      output Integer hash;
    end OutHash;
    partial function OutKeyEq
      input OT key1;
      input OT key2;
      output Boolean equal;
    end OutKeyEq;
  algorithm
    outSet := new<OT>(hash, keyEq, Util.nextPrime(Mutable.access(set.size)));
    for b in Mutable.access(set.buckets) loop
      for k in b loop
        add(fn(k), outSet);
      end for;
    end for;
  end map;
*/

  function apply
    "Replaces all keys in the given set with the results of the given function
     when applied to all keys. Equivalent to a rehash."
    input UnorderedSet<T> set;
    input ApplyFn fn;

    partial function ApplyFn
      input output T key;
    end ApplyFn;
  protected
    Hash hashfn = set.hashFn;
    KeyEq eqfn = set.eqFn;
    Integer bucket_count, hash, size = 0;
    array<list<T>> new_buckets;
    T newKey;
    list<T> bucket;
    Boolean duplicate;
  algorithm
    // Make a new bucket array.
    bucket_count := Util.nextPrime(Mutable.access(set.size));
    new_buckets := arrayCreate(bucket_count, {});

    for b in Mutable.access(set.buckets) loop
      for k in b loop
        // Apply the function to the key
        newKey := fn(k);
        hash := intMod(hashfn(newKey), bucket_count);
        bucket := arrayGet(new_buckets, hash + 1);

        // check if we have a duplicate
        duplicate := false;
        for nk in bucket loop
          if eqfn(nk, newKey) then
            duplicate := true;
            break;
          end if;
        end for;

        // Add the result to the new bucket if it is not already there.
        if not duplicate then
          arrayUpdate(new_buckets, hash + 1, newKey :: bucket);
          size := size + 1;
        end if;
      end for;
    end for;

    // Replace the old bucket array with the new one and update the size of the set.
    Mutable.update(set.buckets, new_buckets);
    Mutable.update(set.size, size);
  end apply;

  function all
    "Returns true if the given function returns true for all elements in the set,
     otherwise false."
    input UnorderedSet<T> set;
    input PredFn fn;
    output Boolean res;

    partial function PredFn
      input T key;
      output Boolean res;
    end PredFn;
  algorithm
    if isEmpty(set) then
      res := true;
      return;
    end if;

    for b in Mutable.access(set.buckets) loop
      for k in b loop
        if not fn(k) then
          res := false;
          return;
        end if;
      end for;
    end for;

    res := true;
  end all;

  function any
    "Returns true if the given function returns true for any elements in the set,
     otherwise false."
    input UnorderedSet<T> set;
    input PredFn fn;
    output Boolean res;

    partial function PredFn
      input T key;
      output Boolean res;
    end PredFn;
  algorithm
    if isEmpty(set) then
      res := false;
      return;
    end if;

    for b in Mutable.access(set.buckets) loop
      for k in b loop
        if fn(k) then
          res := true;
          return;
        end if;
      end for;
    end for;

    res := false;
  end any;

  function none
    "Returns true if the given function returns true for none of the elements in
     the set, otherwise false."
    input UnorderedSet<T> set;
    input PredFn fn;
    output Boolean res;

    partial function PredFn
      input T key;
      output Boolean res;
    end PredFn;
  algorithm
    if isEmpty(set) then
      res := true;
      return;
    end if;

    for b in Mutable.access(set.buckets) loop
      for k in b loop
        if fn(k) then
          res := false;
          return;
        end if;
      end for;
    end for;

    res := true;
  end none;

  function filterOnFalse
    "Returns new set containing elements for which fn returns false"
    input UnorderedSet<T> set;
    input PredFn fn;
    output UnorderedSet<T> falseSet = new<T>(set.hashFn, set.eqFn);

    partial function PredFn
      input T key;
      output Boolean res;
    end PredFn;
  algorithm
    for b in Mutable.access(set.buckets) loop
      for k in b loop
        if not fn(k) then
          add(k, falseSet);
        end if;
      end for;
    end for;
  end filterOnFalse;

  function splitOnTrue
    "Splits a set into two subsets depending on predicate function."
    input UnorderedSet<T> set;
    input PredFn fn;
    output UnorderedSet<T> trueSet = new<T>(set.hashFn, set.eqFn);
    output UnorderedSet<T> falseSet = new<T>(set.hashFn, set.eqFn);

    partial function PredFn
      input T key;
      output Boolean res;
    end PredFn;
  algorithm
    for b in Mutable.access(set.buckets) loop
      for k in b loop
        add(k, if fn(k) then trueSet else falseSet);
      end for;
    end for;
  end splitOnTrue;

  function size
    "Returns the number of elements the set contains."
    input UnorderedSet<T> set;
    output Integer s = Mutable.access(set.size);
  end size;

  function isEmpty
    "Returns whether the set is empty or not."
    input UnorderedSet<T> set;
    output Boolean empty = Mutable.access(set.size) == 0;
  end isEmpty;

  function bucketCount
    "Returns the number of buckets used by the set."
    input UnorderedSet<T> set;
    output Integer count = arrayLength(Mutable.access(set.buckets));
  end bucketCount;

  function loadFactor
    "Returns the load factor, defined as the number of entries divided by the
     number of buckets."
    input UnorderedSet<T> set;
    output Real load = intReal(Mutable.access(set.size)) / bucketCount(set);
  end loadFactor;

  function rehash
    "Changes the number of buckets to an appropriate number based on the number
     of elements in the set and rehashes all the keys."
    input UnorderedSet<T> set;
  protected
    array<list<T>> old_buckets = Mutable.access(set.buckets);
    array<list<T>> new_buckets;
    Integer bucket_count, hash;
    Hash hashfn = set.hashFn;
  algorithm
    // Make a new bucket array.
    bucket_count := Util.nextPrime(Mutable.access(set.size) * 2);
    new_buckets := arrayCreate(bucket_count, {});

    // Rehash all the keys in the old buckets and add them to the new.
    for b in old_buckets loop
      for k in b loop
        hash := intMod(hashfn(k), bucket_count);
        arrayUpdate(new_buckets, hash + 1, k :: arrayGet(new_buckets, hash + 1));
      end for;
    end for;

    // Replace the old bucket array with the new one.
    Mutable.update(set.buckets, new_buckets);
  end rehash;

  function toString
    input UnorderedSet<T> set;
    input StringFn stringFn;
    input String delimiter = "\n";
    output String str;

    partial function StringFn
      input T key;
      output String str;
    end StringFn;
  algorithm
    str := stringDelimitList(list(stringFn(k) for k in toArray(set)), delimiter);
  end toString;

  function dump
    "Prints the set to standard output using the given string function."
    input UnorderedSet<T> set;
    input StringFn stringFn;

    partial function StringFn
      input T key;
      output String str;
    end StringFn;
  algorithm
    print(toString(set, stringFn));
    print("\n");
  end dump;

  function unique_list<T>
    "Takes a list of elements and returns a list with duplicates removed, so that
     each element in the new list is unique."
    input list<T> inList;
    input Hash hashFunc;
    input KeyEq keyEqFunc;
    output list<T> outList = if List.hasSeveralElements(inList) then toList(fromList(inList, hashFunc, keyEqFunc)) else inList;
  end unique_list;

  function union
    "set1 U set2"
    input UnorderedSet<T> set1;
    input UnorderedSet<T> set2;
    output UnorderedSet<T> set;
  protected
    array<list<T>> buckets;
  algorithm
    if Mutable.access(set1.size) > Mutable.access(set2.size) then
      set := set1;
      buckets := Mutable.access(set2.buckets);
    else
      set := set2;
      buckets := Mutable.access(set1.buckets);
    end if;
    for b in buckets loop
      for k in b loop
        add(k, set);
      end for;
    end for;
  end union;

  function union_list
    "set1 U set2 U set3 ... U setn
    pass the hash and equality function if the list is empty"
    input list<UnorderedSet<T>> set_lst;
    input Hash hashFunc;
    input KeyEq keyEqFunc;
    output UnorderedSet<T> set;
  protected
    list<UnorderedSet<T>> rest;
  algorithm
    if listEmpty(set_lst) then
      set := new<T>(hashFunc, keyEqFunc);
    else
      // determine the biggest set to make sure we always add to it
      (set, rest) := extractFromLst(set_lst, intGt);
      for tmp in rest loop
        set := union(set, tmp);
      end for;
    end if;
  end union_list;

  function merge
    "set1 U set2
    like union, but always merges the second into the first list"
    input output UnorderedSet<T> set1;
    input UnorderedSet<T> set2;
  algorithm
    for b in Mutable.access(set2.buckets) loop
      for k in b loop
        add(k, set1);
      end for;
    end for;
  end merge;

  function intersection
    "set1 n set2"
    input UnorderedSet<T> set1;
    input UnorderedSet<T> set2;
    output UnorderedSet<T> set;
  protected
    UnorderedSet<T> set_small, set_big;
    list<T> acc = {};
  algorithm
    if Mutable.access(set1.size) > Mutable.access(set2.size) then
      set_small := set2;
      set_big   := set1;
    else
      set_small := set1;
      set_big   := set2;
    end if;
    for b in Mutable.access(set_small.buckets) loop
      for k in b loop
        if contains(k, set_big) then
          acc := k :: acc;
        end if;
      end for;
    end for;
    set := fromList(acc, set1.hashFn, set1.eqFn);
  end intersection;

  function intersection_list
    "set1 n set2 n set3 ... n setn
    pass the hash and equality function to create an empty list"
    input list<UnorderedSet<T>> set_lst;
    input Hash hashFunc;
    input KeyEq keyEqFunc;
    output UnorderedSet<T> set;
  protected
    UnorderedSet<T> set_small;
    list<UnorderedSet<T>> rest;
    list<T> acc = {};
  algorithm
    if not listEmpty(set_lst) then
      // determine the smallest set to make sure we traverse the fewest elements
      (set_small, rest) := extractFromLst(set_lst, intLt);
      for b in Mutable.access(set_small.buckets) loop
        for k in b loop
          if List.all(rest, function contains(key = k)) then
            acc := k :: acc;
          end if;
        end for;
      end for;
    end if;
    set := fromList(acc, hashFunc, keyEqFunc);
  end intersection_list;

  function difference_list
    "lst1 / lst2, assuming unique lists"
    input list<T> inList1;
    input list<T> inList2;
    input Hash hashFunc;
    input KeyEq keyEqFunc;
    output list<T> acc = {};
  protected
    UnorderedSet<T> set2;
    list<T> lst1 = inList1, lst2 = inList2;
  algorithm
    // remove common start, since this seems to be very common
    while not (listEmpty(lst1) or listEmpty(lst2)) and keyEqFunc(listHead(lst1), listHead(lst2)) loop
      lst1 := listRest(lst1);
      lst2 := listRest(lst2);
    end while;

    // {} - B = {}
    // A - {} = A
    if listEmpty(lst1) or listEmpty(lst2) then
      acc := lst1;
      return;
    end if;

    set2 := fromList(lst2, hashFunc, keyEqFunc);
    for k in lst1 loop
      if not contains(k, set2) then
        acc := k :: acc;
      end if;
    end for;
  end difference_list;

  function difference
    "set1 / set2"
    input UnorderedSet<T> set1;
    input UnorderedSet<T> set2;
    output UnorderedSet<T> set;
  protected
    list<T> acc = {};
  algorithm
    for b in Mutable.access(set1.buckets) loop
      for k in b loop
        if not contains(k, set2) then
          acc := k :: acc;
        end if;
      end for;
    end for;
    set := fromList(acc, set1.hashFn, set1.eqFn);
  end difference;

  function sym_difference
    "set1 / set2 U set2 / set1"
    input UnorderedSet<T> set1;
    input UnorderedSet<T> set2;
    output UnorderedSet<T> set;
  protected
    list<T> acc = {};
  algorithm
    for b in Mutable.access(set1.buckets) loop
      for k in b loop
        if not contains(k, set2) then
          acc := k :: acc;
        end if;
      end for;
    end for;
    for b in Mutable.access(set2.buckets) loop
      for k in b loop
        if not contains(k, set1) then
          acc := k :: acc;
        end if;
      end for;
    end for;
    set := fromList(acc, set1.hashFn, set1.eqFn);
  end sym_difference;

  function isDisjoint
    input UnorderedSet<T> set1;
    input UnorderedSet<T> set2;
    output Boolean b = true;
  protected
    UnorderedSet<T> set_small, set_big;
  algorithm
    if Mutable.access(set1.size) > Mutable.access(set2.size) then
      set_small := set2;
      set_big   := set1;
    else
      set_small := set1;
      set_big   := set2;
    end if;
    for buckets in Mutable.access(set_small.buckets) loop
      for k in buckets loop
        if contains(k, set_big) then
          b := false;
          return;
        end if;
      end for;
    end for;
  end isDisjoint;

protected
  function find
    "Tries to find a key in the set, returning the key as an option, and the
     key's hash."
    input T key;
    input UnorderedSet<T> set;
    output Option<T> outKey = NONE();
    output Integer hash;
  protected
    Hash hashfn = set.hashFn;
    KeyEq eqfn = set.eqFn;
    array<list<T>> buckets = Mutable.access(set.buckets);
    list<T> bucket;
  algorithm
    hash := intMod(hashfn(key), arrayLength(buckets));
    bucket := arrayGet(buckets, hash + 1);

    for k in bucket loop
      if eqfn(k, key) then
        outKey := SOME(k);
        break;
      end if;
    end for;
  end find;

  function addKey
    "Adds a key to the set given its hash."
    input T key;
    input Integer hash;
    input UnorderedSet<T> set;
  protected
    array<list<T>> buckets;
    Integer h;
    Hash hashfn;
  algorithm
    if loadFactor(set) > 1 then
      // Rehash if the load factor is too high to keep performance up.
      rehash(set);
      hashfn := set.hashFn;
      buckets := Mutable.access(set.buckets);
      // The bucket count has changed so we need to rehash the key we're going
      // to add too.
      h := intMod(hashfn(key), arrayLength(buckets));
    else
      buckets := Mutable.access(set.buckets);
      h := hash;
    end if;

    // Add the key to the bucket indicated by the hash.
    arrayUpdate(buckets, h + 1, key :: arrayGet(buckets, h + 1));
    // Update the size of the set.
    Mutable.update(set.size, Mutable.access(set.size) + 1);
  end addKey;

  function extractFromLst
    "extracts a set from a list with smallest or biggest size
    (use with intGt or intLt)
    Note: input lst cannot be empty or else this fails!"
    input list<UnorderedSet<T>> lst;
    input size_compare func;
    output UnorderedSet<T> single;
    output list<UnorderedSet<T>> rest = {};
  protected
    partial function size_compare
      input Integer i1;
      input Integer i2;
      output Boolean b;
    end size_compare;
    Integer size;
    list<UnorderedSet<T>> tmp_lst;
  algorithm
      single :: tmp_lst := lst;
      size := Mutable.access(single.size);
      for tmp in tmp_lst loop
        if func(Mutable.access(tmp.size), size) then
          size := Mutable.access(tmp.size);
          rest := single :: rest;
          single := tmp;
        else
          rest := tmp :: rest;
        end if;
      end for;
  end extractFromLst;

annotation(__OpenModelica_Interface="util");
end UnorderedSet;
