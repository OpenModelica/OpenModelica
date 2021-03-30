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
    input Integer mod;
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

  function addNoUpdCheck
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
    hash := hashfn(key, arrayLength(Mutable.access(set.buckets)));
    addKey(key, hash, set);
  end addNoUpdCheck;

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
    hash := hashfn(key, arrayLength(buckets));
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

  function map
    "Maps all keys in the set."
    input UnorderedSet<T> set;
    input MapFn fn;
    partial function MapFn
      input output T key;
    end MapFn;
  protected
    array<list<T>> new_buckets = Mutable.access(set.buckets);
  algorithm
    for b in 1:arrayLength(new_buckets) loop
      new_buckets[b] := list(fn(k) for k in new_buckets[b]);
    end for;
    Mutable.update(set.buckets, new_buckets);
  end map;

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

  function size
    "Returns the number of elements the set contains."
    input UnorderedSet<T> set;
    output Integer size = Mutable.access(set.size);
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
        hash := hashfn(k, bucket_count);
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
    hash := hashfn(key, arrayLength(buckets));
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
      h := hashfn(key, arrayLength(buckets));
    else
      buckets := Mutable.access(set.buckets);
      h := hash;
    end if;

    // Add the key to the bucket indicated by the hash.
    arrayUpdate(buckets, h + 1, key :: arrayGet(buckets, h + 1));
    // Update the size of the set.
    Mutable.update(set.size, Mutable.access(set.size) + 1);
  end addKey;

annotation(__OpenModelica_Interface="util");
end UnorderedSet;
