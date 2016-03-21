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
type HashTable = tuple<HashVector, ValueArray, Integer, Integer, FuncsTuple>;
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
  hashTable := (arr,(0,szArr,emptyarr),szBucket,0,fntpl);
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
  Integer bsize, n, hash_idx, arr_idx, new_pos;
  FuncsTuple fntpl;
  FuncHash hashFunc;
  FuncEq keyEqual;
  Key key, key2;
  Value val;
  HashNode indices;
algorithm
  (key, _) := entry;
  (hashvec, varr, bsize, n, fntpl as (hashFunc, keyEqual, _, _)) := hashTable;

  hash_idx := hashFunc(key, bsize) + 1;
  indices := hashvec[hash_idx];

  for i in indices loop
    (key2, _) := i;

    if keyEqual(key, key2) then
      (_, arr_idx) := i;
      varr := valueArraySetnth(varr, arr_idx, entry);
      outHashTable := (hashvec, varr, bsize, n, fntpl);
      return;
    end if;
  end for;

  new_pos := valueArrayLength(varr);
  varr := valueArrayAdd(varr, entry);
  arrayUpdate(hashvec, hash_idx, ((key, new_pos)) :: indices);
  n := new_pos + 1;
  outHashTable := (hashvec, varr, bsize, n, fntpl);
end add;

public function dumpHashTableStatistics "
author: PA.
dump statistics on how many entries per hash value. Useful to see how hash function behaves"
  input HashTable hashTable;
algorithm
 _ := match(hashTable)
 local HashVector hvec;
   case((hvec,_,_,_,_)) equation
      print("index list lengths:\n");
      print(stringDelimitList(List.map(List.map(arrayList(hvec),listLength),intString),","));
      print("\n");
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
       (hashvec, varr, bsize, n, fntpl as (hashFunc, _, _, _)))
      equation
        indx = hashFunc(key, bsize);
        newpos = valueArrayLength(varr);
        varr = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec = arrayUpdate(hashvec, indx + 1, ((key, newpos) :: indexes));
        n = valueArrayLength(varr);
      then
        ((hashvec, varr, bsize, n, fntpl));

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
        ((hashvec, varr, bsize, n, fntpl as (hashFunc, _, _, _))))
      equation
        failure((_) = get(key, hashTable));
        indx = hashFunc(key, bsize);
        newpos = valueArrayLength(varr);
        varr = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec = arrayUpdate(hashvec, indx + 1, ((key, newpos) :: indexes));
        n = valueArrayLength(varr);
      then
        ((hashvec, varr, bsize, n, fntpl));

  end match;
end addUnique;

public function update
  "Updates an already existing value in the hashtable. Fails if the entry does
   not exist."
  input HashEntry inEntry;
  input HashTable inHashTable;
  output HashTable outHashTable;
protected
  HashVector hashvec;
  ValueArray varr;
  Integer bsize, n, index;
  FuncsTuple functpl;
  Key key;
algorithm
  (key, _) := inEntry;
  (hashvec, varr, bsize, n, functpl) := inHashTable;
  index := hasKeyIndex(key, inHashTable);
  true := valueArrayKeyIndexExists(varr, index);
  varr := valueArraySetnth(varr, index, inEntry);
  outHashTable := (hashvec, varr, bsize, n, functpl);
end update;

public function delete
  "Deletes the Value associatied with Key from the HashTable.
   Note: This function does not delete from the index table, only from the
   ValueArray. This means that a lot of deletions will not make the HashTable
   more compact, it will still contain a lot of incices information."
  input Key key;
  input HashTable hashTable;
  output HashTable outHashTable;
algorithm
  outHashTable := match hashTable
    local
      Integer indx, n, bsize;
      ValueArray varr;
      HashVector hashvec;
      FuncsTuple fntpl;

    case (hashvec, varr, bsize, n, fntpl)
      equation
        indx = hasKeyIndex(key, hashTable);
        if not valueArrayKeyIndexExists(varr, indx) then
          print("BaseHashTable.delete failed\n");
          fail();
        end if;
        varr = valueArrayClearnth(varr, indx);
      then (hashvec, varr, bsize, n, fntpl);

  end match;
end delete;

public function hasKey "checks if the given key is in the hashTable"
  input Key key;
  input HashTable hashTable;
  output Boolean b;
protected
  ValueArray varr;
algorithm
  (_, varr, _, _, _) := hashTable;
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
  (_, varr, _, _, _) := hashTable;
  (_, value) := valueArrayNth(varr, i);
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

    case (hashvec, _, bsize, _, (hashFunc, keyEqual, _, _))
      equation
        hashindx = hashFunc(key, bsize);
        indexes = hashvec[hashindx + 1];
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
  (_, _, _, _, (_, _, printKey, printValue)) := t;
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
  (_, varr, _, _, _) := hashTable;
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
  (_, va, _, _, _) := hashTable;
  sz := valueArrayLength(va);
end hashTableCurrentSize;

public function valueArrayLength
  "Returns the number of elements in the ValueArray"
  input ValueArray valueArray;
  output Integer sz;
algorithm
  (sz, _, _) := valueArray;
end valueArrayLength;

public function valueArrayAdd
  "Adds an entry last to the ValueArray, increasing array size if no space left
   by factor 1.4"
  input ValueArray valueArray;
  input HashEntry entry;
  output ValueArray outValueArray;
algorithm
  outValueArray := matchcontinue(valueArray, entry)
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
        ((n, size, arr));

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
        ((n, newsize, arr));

    else
      equation
        print("-HashTable.valueArrayAdd failed\n");
      then
        fail();

  end matchcontinue;
end valueArrayAdd;

public function valueArraySetnth
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
        (pos < size) = true;
        arr = arrayUpdate(arr, pos + 1, SOME(entry));
      then
        ((n, size, arr));

    else
      equation
        print("-HashTable.valueArraySetnth failed\n");
      then
        fail();

  end matchcontinue;
end valueArraySetnth;

protected
function valueArrayClearnth
  "Clears the n:th variable in the ValueArray (set to NONE())."
  input ValueArray valueArray;
  input Integer pos;
  output ValueArray outValueArray;
algorithm
  outValueArray := match valueArray
    local
      array<Option<HashEntry>> arr;
      Integer n, size;

    case (_, size, arr)
      equation
        true = pos < size;
        arr = arrayUpdate(arr, pos + 1,NONE());
      then valueArray;

  end match;
end valueArrayClearnth;

protected
function valueArrayNth
  "Retrieve the n:th Value from ValueArray, index from 0..n-1."
  input ValueArray valueArray;
  input Integer pos;
  output Key key;
  output Value value;
algorithm
  (key, value) := match(valueArray, pos)
    local
      Key k;
      Value v;
      Integer n;
      array<Option<HashEntry>> arr;

    case ((n, _, arr), _)
      equation
        true = pos <= n;
        SOME((k, v)) = arr[pos + 1];
      then
        (k, v);

  end match;
end valueArrayNth;

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
      then if pos <= n then isSome(arr[pos + 1]) else false;

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
  (hv, (vs, ve, vae), bs, sz, ft) := inHashTable;
  hv := arrayCopy(hv);
  vae := arrayCopy(vae);
  outCopy := (hv, (vs, ve, vae), bs, sz, ft);
end copy;

annotation(__OpenModelica_Interface="util");
end BaseHashTable;
