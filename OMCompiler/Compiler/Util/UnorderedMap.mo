/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated uniontype UnorderedMap<K, V>
  "An implementation of a generic unordered map, a.k.a. hash map.

   This implementation uses separate chaining and automatically rehashes the map
   when the load factor becomes too large to keep the performance up."

  import Vector;

protected
  import List;
  import MetaModelica.Dangerous.*;
  import Util;

public
  partial function Hash
    input K key;
    input Integer mod;
    output Integer hash;
  end Hash;

  partial function KeyEq
    input K key1;
    input K key2;
    output Boolean equal;
  end KeyEq;

  record UNORDERED_MAP
    Vector<list<Integer>> buckets;
    Vector<K> keys;
    Vector<V> values;
    Hash hashFn;
    KeyEq eqFn;
  end UNORDERED_MAP;

  function new<V>
    "Creates a new map given a hash function, key equality function, and
     optional desired bucket count. An appropriate bucket count is
     Util.nextPrime(number of elements that will be added), but starting with a
     low bucket count is also fine if the number of elements is unknown since
     the map rehashes as needed."
    input Hash hash;
    input KeyEq keyEq;
    input Integer bucketCount = 1;
    output UnorderedMap<K, V> map;
  algorithm
    map := UNORDERED_MAP(
      Vector.newFill(bucketCount, {}),
      Vector.new<K>(),
      Vector.new<V>(),
      hash,
      keyEq
    );
  end new;

  function fromLists<V>
    "Creates a new map from a list of keys and a corresponding list of values.
     Fails if the two lists do not have the same size."
    input list<K> keys;
    input list<V> values;
    input Hash hash;
    input KeyEq keyEq;
    output UnorderedMap<K, V> map;
  protected
    Integer key_count, bucket_count;
    V v;
    list<V> rest_v = values;
  algorithm
    key_count := listLength(keys);
    bucket_count := Util.nextPrime(key_count);

    map := UNORDERED_MAP(
      Vector.newFill(bucket_count, {}),
      Vector.new<K>(key_count),
      Vector.new<V>(key_count),
      hash,
      keyEq
    );

    for k in keys loop
      v :: rest_v := rest_v;
      add(k, v, map);
    end for;
  end fromLists;

  function copy
    "Returns a copy of the map."
    input UnorderedMap<K, V> map;
    output UnorderedMap<K, V> outMap;
  algorithm
    outMap := UNORDERED_MAP(
      Vector.copy(map.buckets),
      Vector.copy(map.keys),
      Vector.copy(map.values),
      map.hashFn,
      map.eqFn
    );
  end copy;

  function deepCopy
    "Returns a deep copy of the map using the given copy function for values."
    input UnorderedMap<K, V> map;
    input CopyFn fn;
    output UnorderedMap<K, V> outMap;

    partial function CopyFn
      input output V value;
    end CopyFn;
  algorithm
    outMap := UNORDERED_MAP(
      Vector.copy(map.buckets),
      Vector.copy(map.keys),
      Vector.deepCopy(map.values, fn),
      map.hashFn,
      map.eqFn
    );
  end deepCopy;

  function add
    "Adds a key and associated value to the map, or updates the value if the key
     already exists in the map. Might trigger a rehash."
    input K key;
    input V value;
    input UnorderedMap<K, V> map;
  protected
    Integer index, hash;
  algorithm
    (index, hash) := find(key, map);

    if index > 0 then
      Vector.update(map.values, index, value);
    else
      addEntry(key, value, hash, map);
    end if;
  end add;

  function addNew
    "Adds a key and associated value to the map without checking if it already
     exists. Faster than add since it doesn't need to check if the key exists,
     but will lead to duplicate keys if it actually does exist in the map
     already. Might trigger a rehash."
    input K key;
    input V value;
    input UnorderedMap<K, V> map;
  protected
    Hash hashfn = map.hashFn;
    Integer hash;
  algorithm
    hash := hashfn(key, Vector.size(map.buckets));
    addEntry(key, value, hash, map);
  end addNew;

  function addUnique
    "Adds a key and associated value to the map, but fails if the key already
     exists. Might trigger a rehash."
    input K key;
    input V value;
    input UnorderedMap<K, V> map;
  protected
    Integer index, hash;
  algorithm
    (index, hash) := find(key, map);
    false := index > 0;
    addEntry(key, value, hash, map);
  end addUnique;

  function tryAdd
    "Adds a key and associated value to the map if the key doesn't already
     exist, otherwise does nothing. Returns the value associated with the key if
     the key already existed, otherwise the new value. Might trigger a rehash."
    input K key;
    input V value;
    input UnorderedMap<K, V> map;
    output V outValue;
  protected
    Integer index, hash;
  algorithm
    (index, hash) := find(key, map);

    if index > 0 then
      outValue := Vector.getNoBounds(map.values, index);
    else
      outValue := value;
      addEntry(key, value, hash, map);
    end if;
  end tryAdd;

  function addUpdate
    "Adds a key and associated value to the map, where the value is generated by
     calling the given function. If the key already exists the function is given
     the old value. The generated value is returned by this function.

     This function can be used to e.g. append to an existing value or create a
     new value if none exists. This is faster than trying to fetch the value,
     updating it and then readding it, since the key only needs to be hashed
     once."
    input K key;
    input UpdateFn fn;
    input UnorderedMap<K, V> map;
    output V value;

    partial function UpdateFn
      input Option<V> oldValue;
      output V value;
    end UpdateFn;
  protected
    Integer index, hash, bucket_count;
  algorithm
    (index, hash) := find(key, map);

    if index > 0 then
      bucket_count := Vector.size(map.buckets);
      value := fn(SOME(Vector.getNoBounds(map.values, index)));
      Vector.updateNoBounds(map.values, index, value);
    else
      value := fn(NONE());
      addEntry(key, value, hash, map);
    end if;
  end addUpdate;

  function remove
    "Removes a key from the map. Returns true if the key existed in the map and
     was removed, or false if the key did not exist in the map. This function is
     O(N) since it will remove the key/value from the key/value arrays.

     Will not trigger a rehash, so rehash must be called manually if shrinking
     the map is desirable (probably not a good idea unless the load factor is
     very low, i.e. less than 0.25 or so)."
    input K key;
    input UnorderedMap<K, V> map;
    output Boolean removed;
  protected
    Integer hash, index;
    list<Integer> bucket;

    function update_indices
      input list<Integer> bucket;
      input Integer removedIndex;
      output list<Integer> outBucket;
    algorithm
      outBucket := list(if i > removedIndex then i-1 else i for i in bucket);
    end update_indices;
  algorithm
    (index, hash) := find(key, map);
    removed := index > 0;

    // Key didn't exist in the map, do nothing.
    if not removed then
      return;
    end if;

    // Remove the index from the bucket.
    bucket := Vector.get(map.buckets, hash + 1);
    bucket := List.deleteMemberOnTrue(index, bucket, intEq);
    Vector.updateNoBounds(map.buckets, hash + 1, bucket);

    // Remove the key/value from the arrays.
    Vector.remove(map.keys, index);
    Vector.remove(map.values, index);

    // Update the indices in the buckets.
    Vector.apply(map.buckets, function update_indices(removedIndex = index));
  end remove;

  function clear
    input UnorderedMap<K, V> map;
  algorithm
    Vector.clear(map.buckets);
    Vector.push(map.buckets, {});
    Vector.clear(map.keys);
    Vector.clear(map.values);
  end clear;

  function get
    "Returns SOME(value) if the given key has an associated value in the map,
     otherwise NONE()."
    input K key;
    input UnorderedMap<K, V> map;
    output Option<V> value;
  protected
    Integer index;
  algorithm
    index := find(key, map);
    value := if index > 0 then SOME(Vector.getNoBounds(map.values, index)) else NONE();
  end get;

  function getOrFail
    "Return the value associated with the given key, or fails if no such value exists."
    input K key;
    input UnorderedMap<K, V> map;
    output V value;
  algorithm
    value := Vector.get(map.values, find(key, map));
  end getOrFail;

  function getOrDefault
    input K key;
    input UnorderedMap<K, V> map;
    input V default;
    output V value;
  protected
    Integer index;
  algorithm
    index := find(key, map);
    value := if index > 0 then Vector.getNoBounds(map.values, index) else default;
  end getOrDefault;

  function getKey
    "Returns SOME(key) if the key exists in the map, otherwise NONE()."
    input K key;
    input UnorderedMap<K, V> map;
    output Option<K> outKey;
  protected
    Integer index;
  algorithm
    index := find(key, map);
    outKey := if index > 0 then SOME(Vector.getNoBounds(map.keys, index)) else NONE();
  end getKey;

  function contains
    "Returns whether the given key exists in the map or not."
    input K key;
    input UnorderedMap<K, V> map;
    output Boolean res;
  algorithm
    res := find(key, map) > 0;
  end contains;

  function first
    "Returns the 'first' element in the map, or fails if the map is empty."
    input UnorderedMap<K, V> map;
    output V value;
  algorithm
    value := Vector.get(map.values, 1);
  end first;

  function firstKey
    "Returns the 'first' key in the map, or fails if the map is empty."
    input UnorderedMap<K, V> map;
    output K key;
  algorithm
    key := Vector.get(map.keys, 1);
  end firstKey;

  function toList
    "Returns a list with the (key, value) pairs."
    input UnorderedMap<K, V> map;
    output list<tuple<K, V>> entries = List.zip(keyList(map), valueList(map));
  end toList;

  function keyList
    "Returns the keys as a list."
    input UnorderedMap<K, V> map;
    output list<K> keys;
  algorithm
    keys := Vector.toList(map.keys);
  end keyList;

  function valueList
    "Returns the values as a list."
    input UnorderedMap<K, V> map;
    output list<V> values;
  algorithm
    values := Vector.toList(map.values);
  end valueList;

  function toArray
    "Returns an array with the (key, value) pairs."
    input UnorderedMap<K, V> map;
    output array<tuple<K, V>> entries;
  protected
    Vector<K> keys = map.keys;
    Vector<V> values = map.values;
    tuple<K, V> t = t;
    Integer sz = Vector.size(keys);
  algorithm
    entries := arrayCreateNoInit(sz, t);

    for i in 1:sz loop
      arrayUpdateNoBoundsChecking(entries, i,
        (Vector.getNoBounds(keys, i), Vector.getNoBounds(values, i)));
    end for;
  end toArray;

  function keyArray
    "Returns the keys as an array."
    input UnorderedMap<K, V> map;
    output array<K> keys;
  algorithm
    keys := Vector.toArray(map.keys);
  end keyArray;

  function valueArray
    "Returns the values as an array."
    input UnorderedMap<K, V> map;
    output array<V> values;
  algorithm
    values := Vector.toArray(map.values);
  end valueArray;

  function toVector
    "Returns a Vector with the (key, value) pairs."
    input UnorderedMap<K, V> map;
    output Vector<tuple<K, V>> entries;
  protected
    Vector<K> keys = map.keys;
    Vector<V> values = map.values;
    Integer sz = Vector.size(keys);
    type EntryT = tuple<K, V>;
  algorithm
    entries := Vector.new<EntryT>(sz);

    for i in 1:sz loop
      Vector.updateNoBounds(entries, i,
        (Vector.getNoBounds(keys, i), Vector.getNoBounds(values, i)));
    end for;
  end toVector;

  function keyVector
    "Returns the keys as a Vector."
    input UnorderedMap<K, V> map;
    output Vector<K> keys;
  algorithm
    keys := Vector.copy(map.keys);
  end keyVector;

  function valueVector
    "Returns the values as a Vector."
    input UnorderedMap<K, V> map;
    output Vector<V> values;
  algorithm
    values := Vector.copy(map.values);
  end valueVector;

  function fold<FT>
    "Folds over the keys in the map."
    input UnorderedMap<K, V> map;
    input FoldFn fn;
    input output FT arg;

    partial function FoldFn
      input K value;
      input output FT arg;
    end FoldFn;
  algorithm
    arg := Vector.fold(map.values, fn, arg);
  end fold;

  function map<OT>
    "Applies a function to each value in the given map and returns a copy of the
     map with the new values."
    input UnorderedMap<K, V> map;
    input MapFn fn;
    output UnorderedMap<K, OT> outMap;

    partial function MapFn
      input V value;
      output OT outValue;
    end MapFn;
  protected
    Vector<OT> new_values;
  algorithm
    new_values := Vector.map(map.values, fn);
    outMap := UNORDERED_MAP(
      Vector.copy(map.buckets),
      Vector.copy(map.keys),
      new_values,
      map.hashFn,
      map.eqFn
    );
  end map;

  function apply
    "Replaces each value in the given map with the result of the given function
     when applied to each value."
    input UnorderedMap<K, V> map;
    input ApplyFn fn;

    partial function ApplyFn
      input output V value;
    end ApplyFn;
  algorithm
    Vector.apply(map.values, fn);
  end apply;

  function all
    "Returns true if the given function returns true for all values in the map,
     otherwise false."
    input UnorderedMap<K, V> map;
    input PredFn fn;
    output Boolean res;

    partial function PredFn
      input V value;
      output Boolean res;
    end PredFn;
  algorithm
    res := Vector.all(map.values, fn);
  end all;

  function any
    "Returns true if the given function returns true for any value in the map,
     otherwise false."
    input UnorderedMap<K, V> map;
    input PredFn fn;
    output Boolean res;

    partial function PredFn
      input V value;
      output Boolean res;
    end PredFn;
  algorithm
    res := Vector.any(map.values, fn);
  end any;

  function none
    "Returns true if the given function returns true for none of the values in
     the map, otherwise false."
    input UnorderedMap<K, V> map;
    input PredFn fn;
    output Boolean res;

    partial function PredFn
      input V value;
      output Boolean res;
    end PredFn;
  algorithm
    res := Vector.none(map.values, fn);
  end none;

  function size
    "Returns the number of elements the map contains."
    input UnorderedMap<K, V> map;
    output Integer size = Vector.size(map.keys);
  end size;

  function isEmpty
    "Returns whether the map is empty or not."
    input UnorderedMap<K, V> map;
    output Boolean empty = Vector.isEmpty(map.keys);
  end isEmpty;

  function bucketCount
    "Returns the number of buckets in the map."
    input UnorderedMap<K, V> map;
    output Integer count = Vector.size(map.buckets);
  end bucketCount;

  function loadFactor
    "Returns the load factor, defined as the number of entries divided by the
     number of buckets."
    input UnorderedMap<K, V> map;
    output Real load = intReal(Vector.size(map.keys)) / Vector.size(map.buckets);
  end loadFactor;

  function rehash
    "Changes the number of buckets to an appropriate number based on the number
     of elements in the map and rehashes all the keys."
    input UnorderedMap<K, V> map;
  protected
    Vector<K> keys = map.keys;
    Vector<list<Integer>> buckets = map.buckets;
    Integer bucket_count, bucket_id;
    Hash hashfn = map.hashFn;
  algorithm
    // Clear the buckets.
    Vector.clear(buckets);

    // Change the number of buckets for a load factor of about 0.5.
    bucket_count := Util.nextPrime(Vector.size(keys) * 2);
    Vector.resize(buckets, bucket_count, {});

    // Rehash all the keys and refill the buckets.
    for i in 1:Vector.size(map.keys) loop
      bucket_id := hashfn(Vector.get(keys, i), bucket_count) + 1;
      Vector.updateNoBounds(buckets, bucket_id, i :: Vector.getNoBounds(buckets, bucket_id));
    end for;
  end rehash;

  function toString
    "Returns a string representation of the map."
    input UnorderedMap<K, V> map;
    input KeyStringFn keyStringFn;
    input ValueStringFn valueStringFn;
    input String delimiter = "\n";
    output String str;

    partial function KeyStringFn
      input K key;
      output String str;
    end KeyStringFn;

    partial function ValueStringFn
      input V value;
      output String str;
    end ValueStringFn;
  protected
    list<String> strl = {};
    Vector<K> keys = map.keys;
    Vector<V> values = map.values;
  algorithm
    for i in Vector.size(keys):-1:1 loop
      strl := "(" + keyStringFn(Vector.get(keys, i)) + ", " +
              valueStringFn(Vector.get(values, i)) + ")" :: strl;
    end for;

    str := stringDelimitList(strl, delimiter);
  end toString;

protected
  function find
    "Returns the array index of the given key (or -1 if the key isn't in the map)
     and the key's hash."
    input K key;
    input UnorderedMap<K, V> map;
    output Integer index = -1;
    output Integer hash;
  protected
    Hash hashfn = map.hashFn;
    KeyEq eqfn = map.eqFn;
    list<Integer> bucket;
  algorithm
    hash := hashfn(key, Vector.size(map.buckets));
    bucket := Vector.get(map.buckets, hash + 1);

    for i in bucket loop
      if eqfn(key, Vector.getNoBounds(map.keys, i)) then
        index := i;
        break;
      end if;
    end for;
  end find;

  function addEntry
    "Adds a key and value to the map given the key's hash."
    input K key;
    input V value;
    input Integer hash;
    input UnorderedMap<K, V> map;
  protected
    Vector<list<Integer>> buckets = map.buckets;
    Integer h;
    Hash hashfn;
  algorithm
    // Add the key/value to the key/value arrays.
    Vector.push(map.keys, key);
    Vector.push(map.values, value);

    if loadFactor(map) > 1 then
      // Rehash if the load factor is too high to keep performance up. This
      // rehashes all the keys, including the one we added above.
      rehash(map);
    else
      // Otherwise add the index of the key/value to the correct bucket.
      Vector.update(buckets, hash + 1,
        Vector.size(map.keys) :: Vector.get(buckets, hash + 1));
    end if;
  end addEntry;

annotation(__OpenModelica_Interface="util");
end UnorderedMap;
