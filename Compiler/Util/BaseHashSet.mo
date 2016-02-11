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

encapsulated package BaseHashSet
"
  file:        BaseHashSet.mo
  package:     BaseHashSet
  author:      Peter Aronsson (MathCore), Jens Frenkel (TU Dresden)
  description: BaseHashSet is a generic implementation of hashsets.
               See HashSet*.mo to see how to use it.


  This file is an extension to OpenModelica.

  Based on HashSet.mo but
  Key     = DAE.ComponentRef
"


// Below is the instance specific code. For each hashset the user must define:
// Key      - The key used to uniquely define elements in a hashset
// hashFunc - A function that maps a key to a positive integer.
// keyEqual - A comparison function between two keys, returns true if equal.

protected import Array;

// Generic hashset code below

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
// You can also use Util.nextPrime if you know exactly how large the hash set
// should be.

public constant Integer lowBucketSize =  257;
public constant Integer avgBucketSize = 2053;
public constant Integer bigBucketSize = 4013;
public constant Integer biggerBucketSize = 25343;
public constant Integer hugeBucketSize = 536870879 "2^29 - 33 is prime :)";
public constant Integer defaultBucketSize = avgBucketSize;

public
replaceable type Key subtypeof Any;
type HashSet = tuple<HashVector, ValueArray, Integer, Integer, FuncsTuple>;
type HashVector = array<list<tuple<Key,Integer>>>;
type ValueArray = tuple<Integer,Integer,array<Option<Key>>>;
type FuncsTuple = tuple<FuncHash,FuncEq,FuncKeyString>;
partial function FuncHash input Key key; input Integer mod; output Integer hash; end FuncHash;
partial function FuncEq input Key key1; input Key key2; output Boolean b; end FuncEq;
partial function FuncKeyString input Key key; output String str; end FuncKeyString;

public function bucketToValuesSize
"calculate the values array size based on the bucket size"
  input Integer szBucket;
  output Integer szArr;
algorithm
  szArr := realInt(realMul(intReal(szBucket), 0.6)); // intDiv(szBucket, 10);
end bucketToValuesSize;



public function emptyHashSetWork
  input Integer szBucket;
  input FuncsTuple fntpl;
  output HashSet hashSet;
protected
  array<list<tuple<Key,Integer>>> arr;
  list<Option<Key>> lst;
  array<Option<Key>> emptyarr;
protected
  Integer szArr;
algorithm
  arr := arrayCreate(szBucket, {});
  szArr := bucketToValuesSize(szBucket);
  emptyarr := arrayCreate(szArr, NONE());
  hashSet := (arr,(0,szArr,emptyarr),szBucket,0,fntpl);
end emptyHashSetWork;

public function add
"
  Add a Key to hashset.
  If the Key already exists, nothing happen.
"
  input Key entry;
  input HashSet hashSet;
  output HashSet outHashSet;
algorithm
  outHashSet := matchcontinue (entry,hashSet)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      tuple<Integer,Integer,array<Option<Key>>> varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      array<list<tuple<Key,Integer>>> hashvec_1,hashvec;
      Key key;
      FuncsTuple fntpl;
      FuncHash hashFunc;
      FuncKeyString keystrFunc;
      String s;

    // Adding when not existing previously
    case (key,((hashvec,varr,bsize,_,fntpl as (hashFunc,_,_))))
      equation
        failure((_) = get(key, hashSet));
        indx = hashFunc(key, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, key);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);
      then ((hashvec_1,varr_1,bsize,n_1,fntpl));

    // adding when already present => Updating value
    case (key,((hashvec,varr,bsize,n,fntpl)))
      equation
        (_,indx) = get1(key, hashSet);
        //print("adding when present, indx =" );print(intString(indx));print("\n");
        varr_1 = valueArraySetnth(varr, indx, key);
      then ((hashvec,varr_1,bsize,n,fntpl));

    case (key,((_,_,bsize,_,(hashFunc,_,keystrFunc))))
      equation
        print("- BaseHashSet.add failed: ");
        print("bsize: ");
        print(intString(bsize));
        print(" key: ");
        s = keystrFunc(key);
        print(s + " Hash: ");
        hval = hashFunc(key,bsize);
        print(intString(hval));
        print("\n");
      then
        fail();
  end matchcontinue;
end add;

public function addNoUpdCheck
  "Add a Key to hashset, without checking if it already exists.
   This function is thus more efficient than add if you already know that the
   Key doesn't already exist in the hashset."
  input Key entry;
  input HashSet hashSet;
  output HashSet outHashSet;
algorithm
  outHashSet := matchcontinue (entry,hashSet)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      tuple<Integer,Integer,array<Option<Key>>> varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      array<list<tuple<Key,Integer>>> hashvec_1,hashvec;
      String name_str;
      Key key;
      FuncsTuple fntpl;
      FuncHash hashFunc;

    // Adding when not existing previously
    case (key,(hashvec,varr,bsize,_,fntpl as (hashFunc,_,_)))
      equation
        indx = hashFunc(key, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, key);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);
      then ((hashvec_1,varr_1,bsize,n_1,fntpl));

    else
      equation
        print("- BaseHashSet.addNoUpdCheck failed\n");
      then
        fail();
  end matchcontinue;
end addNoUpdCheck;

public function addUnique
  "Add a Key to hashset. If the Key is already used it fails."
  input Key key;
  input HashSet hashSet;
  output HashSet outHashSet;
algorithm
  outHashSet := match(key, hashSet)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      tuple<Integer,Integer,array<Option<Key>>> varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      array<list<tuple<Key,Integer>>> hashvec_1,hashvec;
      FuncsTuple fntpl;
      FuncHash hashFunc;

    // Adding when not existing previously
    case (_,
        ((hashvec, varr, bsize, _, fntpl as (hashFunc, _, _))))
      equation
        failure(_ = get(key, hashSet));
        indx = hashFunc(key, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, key);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key, newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);
      then
        ((hashvec_1, varr_1, bsize, n_1, fntpl));

  end match;
end addUnique;

public function delete
"
  delete the Key from the HashSet.
  Note: This function does not delete from the index table, only from the tuple<Integer,Integer,array<Option<Key>>>.
  This means that a lot of deletions will not make the HashSet more compact, it will still contain
  a lot of incices information.
"
  input Key key;
  input HashSet hashSet;
  output HashSet outHashSet;
algorithm
  outHashSet :=
  matchcontinue (key,hashSet)
    local
      Integer indx,n,bsize,indx_1;
      tuple<Integer,Integer,array<Option<Key>>> varr_1,varr;
      array<list<tuple<Key,Integer>>> hashvec;
      FuncsTuple fntpl;
      /* adding when already present => Updating value */
    case (_,(hashvec,varr,bsize,n,fntpl))
      equation
        (_,indx) = get1(key, hashSet);
        varr_1 = valueArrayClearnth(varr, indx);
      then ((hashvec,varr_1,bsize,n,fntpl));
    else
      equation
        print("-HashSet.delete failed\n");
      then
        fail();
  end matchcontinue;
end delete;

public function has
"Returns true if Key is in the HashSet."
  input Key key;
  input HashSet hashSet;
  output Boolean b;
algorithm
  b:= matchcontinue(key,hashSet)
    // empty set containg nothing
    case (_,(_,(0,_,_),_,_,_))
      then
        false;
    case(_,_)
      equation
        get(key,hashSet);
      then
        true;
    else
      false;
  end matchcontinue;
end has;

public function get
"Returns Key from the HashSet. Fails if not present"
  input Key key;
  input HashSet hashSet;
  output Key okey;
algorithm
  (okey,_):= get1(key,hashSet);
end get;

protected function get1 "help function to get"
  input Key key;
  input HashSet hashSet;
  output Key okey;
  output Integer indx;
algorithm
  (okey,indx) := match (key,hashSet)
    local
      Integer hashindx,bsize,n;
      list<tuple<Key,Integer>> indexes;
      array<list<tuple<Key,Integer>>> hashvec;
      ValueArray varr;
      Key k;
      FuncEq keyEqual;
      FuncHash hashFunc;

    case (_,(hashvec,varr,bsize,_,(hashFunc,keyEqual,_)))
      equation
        hashindx = hashFunc(key, bsize);
        indexes = hashvec[hashindx + 1];
        indx = get2(key, indexes, keyEqual);
        k = valueArrayNth(varr, indx);
      then
        (k,indx);

  end match;
end get1;

protected function get2
"Helper function to get"
  input Key key;
  input list<tuple<Key,Integer>> keyIndices;
  input FuncEq keyEqual;
  output Integer index;
algorithm
  index := matchcontinue (key,keyIndices,keyEqual)
    local
      Key key2;
      list<tuple<Key,Integer>> xs;

    // search for the key, found the good one
    case (_,((key2,index) :: _),_)
      equation
        true = keyEqual(key, key2);
      then
        index;

    // search more
    case (_,(_ :: xs),_)
      equation
        index = get2(key, xs, keyEqual);
      then
        index;
  end matchcontinue;
end get2;

public function printHashSet ""
  input HashSet hashSet;
protected
  FuncKeyString printKey;
algorithm
  (_, _, _, _, (_, _, printKey)) := hashSet;
  print(stringDelimitList(list(printKey(e) for e in hashSetList(hashSet)), "\n"));
end printHashSet;

public function dumpHashSet ""
  input HashSet hashSet;
algorithm
  print("HashSet:\n");
  printHashSet(hashSet);
  print("\n");
end dumpHashSet;

public function hashSetList "returns the entries in the hashSet as a list of Key"
  input HashSet hashSet;
  output list<Key> lst;
algorithm
  lst := match(hashSet)
    local
      ValueArray varr;
    case((_,varr,_,_,_))
      then
      valueArrayList(varr);
  end match;
end hashSetList;

public function valueArrayList
  "Transforms a ValueArray to a Key list"
  input ValueArray inValueArray;
  output list<Key> outList = {};
protected
  array<Option<Key>> arr;
  Integer size;
  Key e;
algorithm
  (size, _, arr) := inValueArray;

  for i in 1:size loop
    if isSome(arr[i]) then
      SOME(e) := arr[i];
      outList := e :: outList;
    end if;
  end for;

  outList := listReverse(outList);
end valueArrayList;

public function currentSize
  "Returns the number of elements inserted into the table"
  input HashSet hashSet;
  output Integer sz;
protected
  ValueArray va;
algorithm
  (_,va,_,_,_) := hashSet;
  sz := valueArrayLength(va);
end currentSize;

public function valueArrayLength
"Returns the number of elements in the ValueArray"
  input ValueArray valueArray;
  output Integer sz;
algorithm
  (sz,_,_) := valueArray;
end valueArrayLength;

public function valueArrayAdd
"Adds an entry last to the ValueArray, increasing array size if no space left
by factor 1.4"
  input ValueArray valueArray;
  input Key entry;
  output ValueArray outValueArray;
algorithm
  outValueArray:=
  matchcontinue (valueArray,entry)
    local
      Integer n_1,n,size,expandsize,expandsize_1,newsize;
      array<Option<Key>> arr_1,arr,arr_2;
      Real rsize,rexpandsize;
    case ((n,size,arr),_)
      equation
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(entry));
      then
        ((n_1,size,arr_1));

    case ((n,size,arr),_)
      equation
        (n < size) = false "Do NOT have space to add array elt. Expand with factor 1.4" ;
        rsize = intReal(size);
        rexpandsize = rsize * 0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Array.expand(expandsize_1, arr, NONE());
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(entry));
      then
        ((n_1,newsize,arr_2));
    else
      equation
        print("-HashSet.valueArrayAdd failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayAdd;

public function valueArraySetnth
"Set the n:th variable in the ValueArray to value."
  input ValueArray valueArray;
  input Integer pos;
  input Key entry;
  output ValueArray outValueArray;
algorithm
  outValueArray:=
  matchcontinue (valueArray,pos,entry)
    local
      array<Option<Key>> arr_1,arr;
      Integer n,size;
    case ((n,size,arr),_,_)
      equation
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, SOME(entry));
      then
        ((n,size,arr_1));
    else
      equation
        print("-HashSet.valueArraySetnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArraySetnth;

public function valueArrayClearnth
"Clears the n:th variable in the ValueArray (set to NONE())."
  input ValueArray valueArray;
  input Integer pos;
  output ValueArray outValueArray;
algorithm
  outValueArray := matchcontinue (valueArray,pos)
    local
      array<Option<Key>> arr_1,arr;
      Integer n,size;
    case ((n,size,arr),_)
      equation
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1,NONE());
      then
        ((n,size,arr_1));
    else
      equation
        print("-HashSet.valueArrayClearnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayClearnth;

public function valueArrayNth
"Retrieve the n:th Value from ValueArray, index from 0..n-1."
  input ValueArray valueArray;
  input Integer pos;
  output Key key;
algorithm
  key := match (valueArray,pos)
    local
      Key k;
      Integer n;
      array<Option<Key>> arr;
    case ((n,_,arr),_)
      equation
        (pos <= n) = true;
        SOME(k) = arr[pos + 1];
      then
        k;
  end match;
end valueArrayNth;

annotation(__OpenModelica_Interface="util");
end BaseHashSet;
