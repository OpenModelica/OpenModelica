/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

encapsulated package BaseHashTable
"
  file:        BaseHashTable.mo
  package:     BaseHashTable
  author:      Peter Aronsson (MathCore)
  description: BaseHashTable is a generic implementation of hashtables.
               See HashTable*.mo to see how to use it.


  This file is an extension to OpenModelica.

  Based on HashTable.mo but
  Key     = DAE.ComponentRef
  Value   = DAE.Exp"


// Below is the instance specific code. For each hashtable the user must define:
// Key      - The key used to uniquely define elements in a hashtable
// Value    - The data to associate with each key
// hashFunc - A function that maps a key to a positive integer.
// keyEqual - A comparison function between two keys, returns true if equal.

protected
import Array;
import Error;
import List;

// Generic hashtable code below

// adrpo: use a prime here (pick your poison):
//        3   5   7  11  13  17  19  23  29  31  37  41  43  47  53  59  61  67
//       71  73  79  83  89  97 101 103 107 109 113 127 131 137 139 149 151 157
//      163 167 173 179 181 191 193 197 199 211 223 227 229 233 239 241 251 257
//      263 269 271 277 281 283 293 307 311 313 317 331 337 347 349 353 359 367
//      373 379 383 389 397 401 409 419 421 431 433 439 443 449 457 461 463 467
//      479 487 491 499 503 509 521 523 541 547 557 563 569 571 577 587 593 599
//      601 607 613 617 619 631 641 643 647 653 659 661 673 677 683 691 701 709
//      719 727 733 739 743 751 757 761 769 773 787 797 809 811 821 823 827 829
//      839 853 857 859 863 877 881 883 887 907 911 919 929 937 941 947 953 967
//      971 977 983 991 997 1013 2053 3023 4013 4999 5051 5087 24971
//
// You can also use Util.nextPrime if you know exactly how large the hash table
// should be.

public constant Integer lowBucketSize =  257;
public constant Integer avgBucketSize = 2053;
public constant Integer bigBucketSize = 4013;
public constant Integer biggerBucketSize = 25343;
public constant Integer hugeBucketSize = 536870879 "2^29 - 33 is prime :)";
public constant Integer defaultBucketSize = avgBucketSize;

public
replaceable type Key subtypeof Any;
replaceable type Value subtypeof Any;

type HashEntry = tuple<Key, Value>;
type HashNode = list<tuple<Key, Integer>>;
type HashTable = tuple<HashVector, ValueArray, Integer, FuncsTuple>;
type HashVector = array<HashNode>;
type ValueArray = tuple<Integer, Integer, array<Option<HashEntry>>>;
type FuncsTuple = tuple<FuncHash, FuncEq, FuncKeyString, FuncValString>;

partial function FuncHash input Key key; input Integer mod; output Integer hash; end FuncHash;
partial function FuncEq input Key key1; input Key key2; output Boolean b; end FuncEq;
partial function FuncKeyString input Key key; output String str; end FuncKeyString;
partial function FuncValString input Value val; output String str; end FuncValString;

public function bucketToValuesSize
"calculate the values array size based on the bucket size"
  input Integer szBucket;
  output Integer szArr;
algorithm
  szArr := realInt(realMul(intReal(szBucket), 0.6)); // intDiv(szBucket, 10);
end bucketToValuesSize;

public function emptyHashTableWork
  input Integer szBucket;
  input FuncsTuple fntpl;
  output HashTable hashTable;
protected
  array<list<tuple<Key,Integer>>> arr;
  list<Option<tuple<Key,Value>>> lst;
  array<Option<tuple<Key,Value>>> emptyarr;
protected
  Integer szArr;
algorithm
  if szBucket < 1 then
    Error.addInternalError("Got internal hash table size " + intString(szBucket) + " <1", sourceInfo());
    fail();
  end if;
  arr := arrayCreate(szBucket, {});
  szArr := bucketToValuesSize(szBucket);
  emptyarr := arrayCreate(szArr, NONE());
  hashTable := (arr,(0,szArr,emptyarr),szBucket,fntpl);
end emptyHashTableWork;

public function add
  "Add a Key-Value tuple to hashtable.
   If the Key-Value tuple already exists, the function updates the Value."
  input HashEntry entry;
  input HashTable hashTable;
  output HashTable outHashTable;
protected
  HashVector hashvec;
  ValueArray varr;
  Integer bsize, hash_idx, arr_idx, new_pos;
  FuncsTuple fntpl;
  FuncHash hashFunc;
  FuncEq keyEqual;
  Key key, key2;
  Value val;
  HashNode indices;
algorithm
  (key, _) := entry;
  (hashvec, varr, bsize, fntpl as (hashFunc, keyEqual, _, _)) := hashTable;

  hash_idx := hashFunc(key, bsize) + 1;
  indices := hashvec[hash_idx];

  for i in indices loop
    (key2, _) := i;

    if keyEqual(key, key2) then
      (_, arr_idx) := i;
      valueArraySet(varr, arr_idx, entry);
      outHashTable := hashTable;
      return;
    end if;
  end for;

  (varr, new_pos) := valueArrayAdd(varr, entry);
  arrayUpdate(hashvec, hash_idx, ((key, new_pos)) :: indices);
  outHashTable := (hashvec, varr, bsize, fntpl);
end add;

public function dumpHashTableStatistics "
author: PA.
dump statistics on how many entries per hash value. Useful to see how hash function behaves"
  input HashTable hashTable;
algorithm
 _ := match(hashTable)
 local HashVector hvec;
   case((hvec,_,_,_)) equation
      print("index list lengths:\n");
      print(stringDelimitList(list(intString(listLength(l)) for l in hvec),","));
      print("\n");
      print("non-zero: " + String(sum(1 for l guard not listEmpty(l) in hvec)) + "/" + String(arrayLength(hvec)) +"\n");
      print("max element: " + String(max(listLength(l) for l in hvec)) + "\n");
      print("total entries: " + String(sum(listLength(l) for l in hvec)) + "\n");
   then ();
 end match;
end dumpHashTableStatistics;

public function addNoUpdCheck
  "Add a Key-Value tuple to hashtable, without checking if it already exists.
   This function is thus more efficient than add if you already know that the
   Key-Value tuple doesn't already exist in the hashtable."
  input HashEntry entry;
  input HashTable hashTable;
  output HashTable outHashTable;
algorithm
  outHashTable := matchcontinue(entry, hashTable)
    local
      Integer indx, newpos, n, bsize;
      ValueArray varr;
      HashNode indexes;
      HashVector hashvec;
      tuple<Key,Value> v;
      Key key;
      Value value;
      FuncsTuple fntpl;
      FuncHash hashFunc;

    // Adding when not existing previously
    case ((v as (key, _)),
       (hashvec, varr, bsize, fntpl as (hashFunc, _, _, _)))
      equation
        indx = hashFunc(key, bsize)+1;
        (varr,newpos) = valueArrayAdd(varr, v);
        indexes = hashvec[indx];
        hashvec = arrayUpdate(hashvec, indx, ((key, newpos) :: indexes));
        _ = valueArrayLength(varr);
      then
        ((hashvec, varr, bsize, fntpl));

    else
      equation
        print("- BaseHashTable.addNoUpdCheck failed\n");
      then
        fail();

  end matchcontinue;
end addNoUpdCheck;

public function addUnique
  "Add a Key-Value tuple to hashtable. If the Key is already used it fails."
  input HashEntry entry;
  input HashTable hashTable;
  output HashTable outHashTable;
algorithm
  outHashTable := match(entry, hashTable)
    local
      Integer indx, newpos, n, bsize;
      ValueArray varr;
      HashNode indexes;
      HashVector hashvec;
      HashEntry v;
      Key key;
      Value value;
      FuncsTuple fntpl;
      FuncHash hashFunc;

    // Adding when not existing previously
    case ((v as (key, _)),
        ((hashvec, varr, bsize, fntpl as (hashFunc, _, _, _))))
      equation
        failure((_) = get(key, hashTable));
        indx = hashFunc(key, bsize)+1;
        (varr,newpos) = valueArrayAdd(varr, v);
        indexes = hashvec[indx];
        hashvec = arrayUpdate(hashvec, indx, ((key, newpos) :: indexes));
        _ = valueArrayLength(varr);
      then
        ((hashvec, varr, bsize, fntpl));

  end match;
end addUnique;

public function update
  "Updates an already existing value in the hashtable. Fails if the entry does
   not exist."
  input HashEntry entry;
  input HashTable hashTable;
protected
  HashVector hashvec;
  ValueArray varr;
  Integer bsize, n, index;
  FuncsTuple functpl;
  Key key;
algorithm
  (key, _) := entry;
  (hashvec, varr, bsize, functpl) := hashTable;
  index := hasKeyIndex(key, hashTable);
  true := valueArrayKeyIndexExists(varr, index);
  valueArraySet(varr, index, entry);
end update;

public function delete
  "Deletes the Value associatied with Key from the HashTable.
   Note: This function does not delete from the index table, only from the
   ValueArray. This means that a lot of deletions will not make the HashTable
   more compact, it will still contain a lot of incices information."
  input Key key;
  input HashTable hashTable;
protected
  Integer indx;
  ValueArray varr;
algorithm
  indx := hasKeyIndex(key, hashTable);
  (_, varr, _, _) := hashTable;
  if not valueArrayKeyIndexExists(varr, indx) then
    print("BaseHashTable.delete failed\n");
    fail();
  end if;
  valueArrayClear(varr, indx);
end delete;

public function hasKey "checks if the given key is in the hashTable"
  input Key key;
  input HashTable hashTable;
  output Boolean b;
protected
  ValueArray varr;
algorithm
  (_, varr, _, _) := hashTable;
   b := valueArrayKeyIndexExists(varr, hasKeyIndex(key, hashTable));
end hasKey;

public function anyKeyInHashTable "Returns true if any of the keys are present in the hashtable. Stops and returns true upon first occurence"
  input list<Key> keys;
  input HashTable ht;
  output Boolean res;
algorithm
  for key in keys loop
    if hasKey(key, ht) then
      res := true;
      return;
    end if;
  end for;
  res := false;
end anyKeyInHashTable;

public function get
  "Returns a Value given a Key and a HashTable."
  input Key key;
  input HashTable hashTable;
  output Value value;
protected
  Integer i;
  ValueArray varr;
algorithm
  i := hasKeyIndex(key, hashTable);
  false := i == -1;
  (_, varr, _, _) := hashTable;
  (_, value) := getValueArray(varr, i);
end get;

protected function hasKeyIndex
  "help function to get and hasKey"
  input Key key;
  input HashTable hashTable;
  output Integer indx;
algorithm
  indx := match hashTable
    local
      Integer hashindx, bsize, n;
      HashNode indexes;
      Value v;
      HashVector hashvec;
      Key k;
      FuncEq keyEqual;
      FuncHash hashFunc;
      Boolean eq;

    case (hashvec, _, bsize, (hashFunc, keyEqual, _, _))
      equation
        hashindx = hashFunc(key, bsize)+1;
        indexes = hashvec[hashindx];
      then hasKeyIndex2(key, indexes, keyEqual);

  end match;
end hasKeyIndex;

protected function hasKeyIndex2
  "Helper function to get"
  input Key key;
  input HashNode keyIndices;
  input FuncEq keyEqual;
  output Integer index "Returns -1 on failure";
protected
  Key key2;
algorithm
  for keyIndex in keyIndices loop
    (key2,index) := keyIndex;
    if keyEqual(key, key2) then
      return;
    end if;
  end for;
  index := -1 "Mark the failure so we can do hasKey without matchcontinue";
end hasKeyIndex2;

public function dumpHashTable
  input HashTable t;
protected
  FuncKeyString printKey;
  FuncValString printValue;
  Key k;
  Value v;
algorithm
  (_, _, _, (_, _, printKey, printValue)) := t;
  print("HashTable:\n");

  for entry in hashTableList(t) loop
    (k, v) := entry;
    print("{");
    print(printKey(k));
    print(",{");
    print(printValue(v));
    print("}}\n");
  end for;
end dumpHashTable;

protected function dumpTuple
  input HashEntry tpl;
  input FuncKeyString printKey;
  input FuncValString printValue;
  output String str;
protected
  Key k;
  Value v;
  String sk, sv;
algorithm
  (k, v) := tpl;
  sk := printKey(k);
  sv := printValue(v);
  str := stringAppendList({"{", sk, ",{", sv, "}}"});
end dumpTuple;

public function hashTableValueList
  "Returns the Value entries as a list of Values."
  input HashTable hashTable;
  output list<Value> valLst;
algorithm
  valLst := List.unzipSecond(hashTableList(hashTable));
end hashTableValueList;

public function hashTableKeyList
  "Returns the Key entries as a list of Keys."
  input HashTable hashTable;
  output list<Key> valLst;
algorithm
  valLst := List.unzipFirst(hashTableList(hashTable));
end hashTableKeyList;

public function hashTableList
  "Returns the entries in the hashTable as a list of HashEntries."
  input HashTable hashTable;
  output list<HashEntry> outEntries;
protected
  ValueArray varr;
algorithm
  (_, varr, _, _) := hashTable;
  outEntries := valueArrayList(varr);
end hashTableList;

public function valueArrayList
  "Transforms a ValueArray to a HashEntry list."
  input ValueArray valueArray;
  output list<HashEntry> outEntries;
protected
  array<Option<HashEntry>> arr;
algorithm
  (_, _, arr) := valueArray;
  outEntries := Array.fold(arr, List.consOption, {});
  outEntries := listReverse(outEntries);
end valueArrayList;

public function hashTableCurrentSize
  "Returns the number of elements inserted into the table"
  input HashTable hashTable;
  output Integer sz;
protected
  ValueArray va;
algorithm
  (_, va, _, _) := hashTable;
  sz := valueArrayLength(va);
end hashTableCurrentSize;

public function valueArrayLength
  "Returns the number of elements in the ValueArray"
  input ValueArray valueArray;
  output Integer sz;
algorithm
  (sz, _, _) := valueArray;
end valueArrayLength;

protected

function valueArrayAdd
  "Adds an entry last to the ValueArray, increasing array size if no space left
   by factor 1.4"
  input ValueArray valueArray;
  input HashEntry entry;
  output ValueArray outValueArray;
  output Integer newpos;
algorithm
  (outValueArray, newpos) := matchcontinue(valueArray, entry)
    local
      Integer n, size, expandsize, newsize;
      array<Option<HashEntry>> arr;
      Real rsize, rexpandsize;

    case ((n, size, arr), _)
      equation
        (n < size) = true "Have space to add array elt.";
        n = n + 1;
        arr = arrayUpdate(arr, n, SOME(entry));
      then
        ((n, size, arr), n);

    case ((n, size, arr), _)
      equation
        (n < size) = false "Do NOT have space to add array elt. Expand with factor 1.4";
        rsize = intReal(size);
        rexpandsize = rsize * 0.4;
        expandsize = realInt(rexpandsize);
        expandsize = intMax(expandsize, 1);
        newsize = expandsize + size;
        arr = Array.expand(expandsize, arr, NONE());
        n = n + 1;
        arr = arrayUpdate(arr, n, SOME(entry));
      then
        ((n, newsize, arr), n);

    else
      equation
        print("-HashTable.valueArrayAdd failed\n");
      then
        fail();

  end matchcontinue;
end valueArrayAdd;

function valueArraySet
  "Set the n:th variable in the ValueArray to value."
  input ValueArray valueArray;
  input Integer pos;
  input HashEntry entry;
  output ValueArray outValueArray;
algorithm
  outValueArray := matchcontinue(valueArray, pos, entry)
    local
      array<Option<HashEntry>> arr;
      Integer n, size;

    case ((n, size, arr), _, _)
      equation
        true = pos <= size;
        arr = arrayUpdate(arr, pos, SOME(entry));
      then
        ((n, size, arr));

    case ((_, size, _), _, _)
      equation
        Error.addInternalError("HashTable.valueArraySet(pos="+String(pos)+") size="+String(size)+" failed\n", sourceInfo());
      then
        fail();

  end matchcontinue;
end valueArraySet;

function valueArrayClear
  "Clears the n:th variable in the ValueArray (set to NONE())."
  input ValueArray valueArray;
  input Integer pos;
protected
  array<Option<HashEntry>> arr;
  Integer size;
algorithm
  (_, size, arr) := valueArray;
  true := pos <= size; // TODO: Needed? arrayUpdate checks bounds and we should more reasonably check n?
  arrayUpdate(arr, pos,NONE());
end valueArrayClear;

protected
function getValueArray
  "Retrieve the n:th Value from ValueArray, index from 1..n."
  input ValueArray valueArray;
  input Integer pos;
  output Key key;
  output Value value;
protected
  array<Option<HashEntry>> arr;
  Integer n;
algorithm
  (n, _, arr) := valueArray;
  true := pos <= n; // In case the user sends in higher values and we did not clear the array properly?
  SOME((key,value)) := arrayGet(arr, pos);
end getValueArray;

function valueArrayKeyIndexExists
  "Checks if the given index exists in the value array"
  input ValueArray valueArray;
  input Integer pos;
  output Boolean b;
algorithm
  b := match (valueArray, pos)
    local
      Key k;
      Value v;
      Integer n;
      array<Option<HashEntry>> arr;

    case (_, -1) then false;
    case ((n, _, arr), _)
      then if pos <= n then isSome(arr[pos]) else false;

  end match;
end valueArrayKeyIndexExists;

public function copy
  "Makes a copy of a hashtable."
  input HashTable inHashTable;
  output HashTable outCopy;
protected
  HashVector hv;
  Integer bs, sz, vs, ve;
  FuncsTuple ft;
  array<Option<HashEntry>> vae;
algorithm
  (hv, (vs, ve, vae), bs, ft) := inHashTable;
  hv := arrayCopy(hv);
  vae := arrayCopy(vae);
  outCopy := (hv, (vs, ve, vae), bs, ft);
end copy;

public function clear
  "Makes a copy of a hashtable."
  input output HashTable ht;
protected
  HashVector hv;
  Integer bs, sz, vs, ve, hash_idx;
  FuncsTuple ft;
  FuncHash hashFunc;
  Key key;
  array<Option<HashEntry>> vae;
algorithm
  (hv, (vs, ve, vae), bs, ft as (hashFunc,_,_,_)) := ht;
  for i in 1:vs loop
    _ := match arrayGet(vae, i)
      case SOME((key,_))
        algorithm
          hash_idx := hashFunc(key, bs) + 1;
          arrayUpdate(hv, hash_idx, {});
          arrayUpdate(vae, i, NONE());
        then ();
      else ();
    end match;
  end for;
  ht := (hv, (0, ve, vae), bs, ft);
end clear;

public function clearAssumeNoDelete
  "Clears a HashTable that has not been properly stored, but was known to never delete an element (making the values sequential SOME() for as long as there are elements). NOTE: Does not handle arrays that were expanded?"
  input HashTable ht;
protected
  HashVector hv;
  Integer bs, sz, vs, ve, hash_idx;
  FuncsTuple ft;
  FuncHash hashFunc;
  Key key;
  array<Option<HashEntry>> vae;
  constant Boolean workaroundForBug=true "TODO: Make it impossible to update a value by not updating n (fully mutable HT instead of this hybrid)";
  constant Boolean debug=false;
algorithm
  (hv, (vs, ve, vae), bs, ft as (hashFunc,_,_,_)) := ht;
  for i in 1:ve loop
    _ := match arrayGet(vae, i)
      case SOME((key,_))
        algorithm
          if not workaroundForBug then
            hash_idx := hashFunc(key, bs) + 1;
            arrayUpdate(hv, hash_idx, {});
          end if;
          arrayUpdate(vae, i, NONE());
        then ();
      else
        algorithm
          if not workaroundForBug then return; end if;
        then ();
    end match;
  end for;
  if debug then
    for i in vae loop
      if isSome(i) then
        print("vae not empty\n");
        break;
      end if;
    end for;
  end if;
  if workaroundForBug then
    for i in 1:arrayLength(hv) loop
      if not listEmpty(arrayGet(hv,i)) then
        if debug then print("hv not empty\n"); end if;
        arrayUpdate(hv,i,{});
      end if;
    end for;
  end if;
end clearAssumeNoDelete;

annotation(__OpenModelica_Interface="util");
end BaseHashTable;
