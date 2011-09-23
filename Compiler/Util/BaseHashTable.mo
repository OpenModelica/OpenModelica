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

encapsulated package BaseHashTable 
" 
  file:        BaseHashTable.mo
  package:     BaseHashTable
  author:      Peter Aronsson (MathCore)  
  description: BaseHashTable is a generic implementation of hashtables.
               See HashTable*.mo to see how to use it.
  
  RCS: $Id$

  This file is an extension to OpenModelica.

  Based on HashTable.mo but
  Key     = DAE.ComponentRef
  Value   = DAE.Exp"


// Below is the instance specific code. For each hashtable the user must define:
// Key      - The key used to uniquely define elements in a hashtable
// Value    - The data to associate with each key
// hashFunc - A function that maps a key to a positive integer.
// keyEqual - A comparison function between two keys, returns true if equal.

protected import List;
protected import Util;

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

public constant Integer lowBucketSize =  257;
public constant Integer avgBucketSize = 2053;
public constant Integer bigBucketSize = 4013;
public constant Integer hugeBucketSize = 536870879 "2^29 - 33 is prime :)";
public constant Integer defaultBucketSize = avgBucketSize;

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

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type HashTable = tuple<HashVector, ValueArray, Integer, Integer, FuncsTuple>;
  type HashVector = array<list<tuple<Key,Integer>>>;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
  type FuncsTuple = tuple<FuncHash,FuncEq,FuncKeyString,FuncValString>;
  partial function FuncHash input Key key; input Integer mod; output Integer hash; end FuncHash;
  partial function FuncEq input Key key1; input Key key2; output Boolean b; end FuncEq;
  partial function FuncKeyString input Key key; output String str; end FuncKeyString;
  partial function FuncValString input Value val; output String str; end FuncValString;
protected
  Integer szArr;
algorithm
  arr := arrayCreate(szBucket, {});
  szArr := bucketToValuesSize(szBucket);
  emptyarr := arrayCreate(szArr, NONE());
  hashTable := (arr,(0,szArr,emptyarr),szBucket,0,fntpl);
end emptyHashTableWork;

public function add
"
  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value.
"
  input tuple<Key,Value> entry;
  input HashTable hashTable;
  output HashTable outHashTable;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type HashTable = tuple<HashVector, ValueArray, Integer, Integer, FuncsTuple>;
  type HashVector = array<list<tuple<Key,Integer>>>;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
  type FuncsTuple = tuple<FuncHash,FuncEq,FuncKeyString,FuncValString>;
  partial function FuncHash input Key key; input Integer mod; output Integer hash; end FuncHash;
  partial function FuncEq input Key key1; input Key key2; output Boolean b; end FuncEq;
  partial function FuncKeyString input Key key; output String str; end FuncKeyString;
  partial function FuncValString input Value val; output String str; end FuncValString;
algorithm
  outHashTable := matchcontinue (entry,hashTable)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      tuple<Integer,Integer,array<Option<tuple<Key,Value>>>> varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      array<list<tuple<Key,Integer>>> hashvec_1,hashvec;
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
      FuncsTuple fntpl;
      FuncHash hashFunc;
      /* Adding when not existing previously */
    case ((v as (key,value)),(hashTable as (hashvec,varr,bsize,n,fntpl as (hashFunc,_,_,_))))
      equation
        failure((_) = get(key, hashTable));
        indx = hashFunc(key, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);
      then ((hashvec_1,varr_1,bsize,n_1,fntpl));

    // adding when already present => Updating value
    case ((newv as (key,value)),(hashTable as (hashvec,varr,bsize,n,fntpl)))
      equation
        (_,indx) = get1(key, hashTable);
        //print("adding when present, indx =" );print(intString(indx));print("\n");
        indx_1 = indx - 1;
        varr_1 = valueArraySetnth(varr, indx, newv);
      then ((hashvec,varr_1,bsize,n,fntpl));
    
    case ((v as (key,value)),(hashTable as (hashvec,varr,bsize,n,(hashFunc,_,_,_))))
      equation
        print("- BaseHashTable.add failed: ");
        print("bsize: ");
        print(intString(bsize));
        print(" key: ");
        hval = hashFunc(key,bsize);
        print(intString(hval));
        print("\n");
      then
        fail();
  end matchcontinue;
end add;

public function addNoUpdCheck
"
  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value.
"
  input tuple<Key,Value> entry;
  input HashTable hashTable;
  output HashTable outHashTable;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type HashTable = tuple<HashVector, ValueArray, Integer, Integer, FuncsTuple>;
  type HashVector = array<list<tuple<Key,Integer>>>;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
  type FuncsTuple = tuple<FuncHash,FuncEq,FuncKeyString,FuncValString>;
  partial function FuncHash input Key key; input Integer mod; output Integer hash; end FuncHash;
  partial function FuncEq input Key key1; input Key key2; output Boolean b; end FuncEq;
  partial function FuncKeyString input Key key; output String str; end FuncKeyString;
  partial function FuncValString input Value val; output String str; end FuncValString;
algorithm
  outHashTable := matchcontinue (entry,hashTable)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      tuple<Integer,Integer,array<Option<tuple<Key,Value>>>> varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      array<list<tuple<Key,Integer>>> hashvec_1,hashvec;
      String name_str;
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
      FuncsTuple fntpl;
      FuncHash hashFunc;
    
    // Adding when not existing previously
    case ((v as (key,value)),(hashvec,varr,bsize,n,fntpl as (hashFunc,_,_,_)))
      equation
        indx = hashFunc(key, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);
      then ((hashvec_1,varr_1,bsize,n_1,fntpl));
    
    case (_,_)
      equation
        print("- BaseHashTable.addNoUpdCheck failed\n");
      then
        fail();
  end matchcontinue;
end addNoUpdCheck;

public function delete
"
  delete the Value associatied with Key from the HashTable.
  Note: This function does not delete from the index table, only from the tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>.
  This means that a lot of deletions will not make the HashTable more compact, it will still contain
  a lot of incices information.
"
  input Key key;
  input HashTable hashTable;
  output HashTable outHashTable;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type HashTable = tuple<HashVector, ValueArray, Integer, Integer, FuncsTuple>;
  type HashVector = array<list<tuple<Key,Integer>>>;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
  type FuncsTuple = tuple<FuncHash,FuncEq,FuncKeyString,FuncValString>;
  partial function FuncHash input Key key; input Integer mod; output Integer hash; end FuncHash;
  partial function FuncEq input Key key1; input Key key2; output Boolean b; end FuncEq;
  partial function FuncKeyString input Key key; output String str; end FuncKeyString;
  partial function FuncValString input Value val; output String str; end FuncValString;
algorithm
  outHashTable :=
  matchcontinue (key,hashTable)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      tuple<Integer,Integer,array<Option<tuple<Key,Value>>>> varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      array<list<tuple<Key,Integer>>> hashvec_1,hashvec;
      String name_str;
      tuple<Key,Value> v,newv;
      Value value;
      FuncsTuple fntpl;
      /* adding when already present => Updating value */
    case (key,(hashvec,varr,bsize,n,fntpl))
      equation
        (_,indx) = get1(key, hashTable);
        indx_1 = indx - 1;
        varr_1 = valueArrayClearnth(varr, indx);
      then ((hashvec,varr_1,bsize,n,fntpl));
    case (_,_)
      equation
        print("-HashTable.delete failed\n");
      then
        fail();
  end matchcontinue;
end delete;


public function get
"Returns a Value given a Key and a HashTable."
  input Key key;
  input HashTable hashTable;
  output Value value;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type HashTable = tuple<HashVector, ValueArray, Integer, Integer, FuncsTuple>;
  type HashVector = array<list<tuple<Key,Integer>>>;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
  type FuncsTuple = tuple<FuncHash,FuncEq,FuncKeyString,FuncValString>;
  partial function FuncHash input Key key; input Integer mod; output Integer hash; end FuncHash;
  partial function FuncEq input Key key1; input Key key2; output Boolean b; end FuncEq;
  partial function FuncKeyString input Key key; output String str; end FuncKeyString;
  partial function FuncValString input Value val; output String str; end FuncValString;
algorithm
  (value,_):= get1(key,hashTable);
end get;

protected function get1 "help function to get"
  input Key key;
  input HashTable hashTable;
  output Value value;
  output Integer indx;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type HashTable = tuple<HashVector, ValueArray, Integer, Integer, FuncsTuple>;
  type HashVector = array<list<tuple<Key,Integer>>>;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
  type FuncsTuple = tuple<FuncHash,FuncEq,FuncKeyString,FuncValString>;
  partial function FuncHash input Key key; input Integer mod; output Integer hash; end FuncHash;
  partial function FuncEq input Key key1; input Key key2; output Boolean b; end FuncEq;
  partial function FuncKeyString input Key key; output String str; end FuncKeyString;
  partial function FuncValString input Value val; output String str; end FuncValString;
algorithm
  (value,indx) := match (key,hashTable)
    local
      Integer hval,hashindx,bsize,n;
      list<tuple<Key,Integer>> indexes;
      Value v;
      array<list<tuple<Key,Integer>>> hashvec;
      ValueArray varr;
      Key k;
      FuncEq keyEqual;
      FuncHash hashFunc;
    case (key,(hashvec,varr,bsize,n,(hashFunc,keyEqual,_,_)))
      equation
        hashindx = hashFunc(key, bsize);
        indexes = hashvec[hashindx + 1];
        indx = get2(key, indexes, keyEqual);
        (k, v) = valueArrayNth(varr, indx);
      then
        (v,indx);
  end match;
end get1;

protected function get2
"Helper function to get"
  input Key key;
  input list<tuple<Key,Integer>> keyIndices;
  input FuncEq keyEqual;
  output Integer index;

  partial function FuncEq input Key key1; input Key key2; output Boolean b; end FuncEq;
  replaceable type Key subtypeof Any;
algorithm
  index :=
  matchcontinue (key,keyIndices,keyEqual)
    local
      Key key2;
      list<tuple<Key,Integer>> xs;
    case (key,((key2,index) :: _),keyEqual)
      equation
        true = keyEqual(key, key2);
      then
        index;
    case (key,(_ :: xs),keyEqual)
      equation
        index = get2(key, xs, keyEqual);
      then
        index;
  end matchcontinue;
end get2;

public function dumpHashTable ""
  input HashTable t;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type HashTable = tuple<HashVector, ValueArray, Integer, Integer, FuncsTuple>;
  type HashVector = array<list<tuple<Key,Integer>>>;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
  type FuncsTuple = tuple<FuncHash,FuncEq,FuncKeyString,FuncValString>;
  partial function FuncHash input Key key; input Integer mod; output Integer hash; end FuncHash;
  partial function FuncEq input Key key1; input Key key2; output Boolean b; end FuncEq;
  partial function FuncKeyString input Key key; output String str; end FuncKeyString;
  partial function FuncValString input Value val; output String str; end FuncValString;
protected
  FuncKeyString printKey;
  FuncValString printValue;
algorithm
  (_,_,_,_,(_,_,printKey,printValue)) := t;
  print("HashTable:\n");
  print(Util.stringDelimitList(List.map2(hashTableList(t),dumpTuple,printKey,printValue),"\n"));
  print("\n");
end dumpHashTable;

protected function dumpTuple
  input tuple<Key,Value> tpl;
  input FuncKeyString printKey;
  input FuncValString printValue;
  output String str;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  partial function FuncKeyString input Key key; output String str; end FuncKeyString;
  partial function FuncValString input Value val; output String str; end FuncValString;
algorithm
  str := matchcontinue(tpl,printKey,printValue)
    local
      Key k;
      Value v;
      String sk,sv;
    case((k,v),printKey,printValue)
      equation
        sk = printKey(k);
        sv = printValue(v);
        str = "{" +& sk +& ",{" +& sv +& "}}";
      then str;
  end matchcontinue;
end dumpTuple;

public function hashTableValueList "return the Value entries as a list of Values"
  input HashTable hashTable;
  output list<Value> valLst;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type HashTable = tuple<HashVector, ValueArray, Integer, Integer, FuncsTuple>;
  type HashVector = array<list<tuple<Key,Integer>>>;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
  type FuncsTuple = tuple<FuncHash,FuncEq,FuncKeyString,FuncValString>;
  partial function FuncHash input Key key; input Integer mod; output Integer hash; end FuncHash;
  partial function FuncEq input Key key1; input Key key2; output Boolean b; end FuncEq;
  partial function FuncKeyString input Key key; output String str; end FuncKeyString;
  partial function FuncValString input Value val; output String str; end FuncValString;
algorithm
   valLst := List.map(hashTableList(hashTable),Util.tuple22);
end hashTableValueList;

public function hashTableKeyList "return the Key entries as a list of Keys"
  input HashTable hashTable;
  output list<Key> valLst;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type HashTable = tuple<HashVector, ValueArray, Integer, Integer, FuncsTuple>;
  type HashVector = array<list<tuple<Key,Integer>>>;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
  type FuncsTuple = tuple<FuncHash,FuncEq,FuncKeyString,FuncValString>;
  partial function FuncHash input Key key; input Integer mod; output Integer hash; end FuncHash;
  partial function FuncEq input Key key1; input Key key2; output Boolean b; end FuncEq;
  partial function FuncKeyString input Key key; output String str; end FuncKeyString;
  partial function FuncValString input Value val; output String str; end FuncValString;
algorithm
   valLst := List.map(hashTableList(hashTable),Util.tuple21);
end hashTableKeyList;

public function hashTableList "returns the entries in the hashTable as a list of tuple<Key,Value>"
  input HashTable hashTable;
  output list<tuple<Key,Value>> tplLst;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type HashTable = tuple<HashVector, ValueArray, Integer, Integer, FuncsTuple>;
  type HashVector = array<list<tuple<Key,Integer>>>;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
  type FuncsTuple = tuple<FuncHash,FuncEq,FuncKeyString,FuncValString>;
  partial function FuncHash input Key key; input Integer mod; output Integer hash; end FuncHash;
  partial function FuncEq input Key key1; input Key key2; output Boolean b; end FuncEq;
  partial function FuncKeyString input Key key; output String str; end FuncKeyString;
  partial function FuncValString input Value val; output String str; end FuncValString;
algorithm
  tplLst := match(hashTable)
    local
      ValueArray varr;
    case((_,varr,_,_,_))
      equation
        tplLst = valueArrayList(varr);
      then tplLst;
  end match;
end hashTableList;

public function valueArrayList
"Transforms a ValueArray to a tuple<Key,Value> list"
  input ValueArray valueArray;
  output list<tuple<Key,Value>> tplLst;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
algorithm
  tplLst := matchcontinue (valueArray)
    local
      array<Option<tuple<Key,Value>>> arr;
      tuple<Key,Value> elt;
      Integer lastpos,n,size;
      list<tuple<Key,Value>> lst;
    
    case ((0,_,arr)) then {};
    case ((1,_,arr))
      equation
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    case ((n,size,arr))
      equation
        lastpos = n - 1;
        lst = valueArrayList2(arr, false, 0, lastpos, {});
      then
        lst;
  end matchcontinue;
end valueArrayList;

protected function valueArrayList2 "Helper function to valueArrayList"
  input array<Option<tuple<Key,Value>>> inVarOptionArray1;
  input Boolean posEq;
  input Integer inInteger2;
  input Integer inInteger3;
  input list<tuple<Key,Value>> acc;
  output list<tuple<Key,Value>> outVarLst;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
algorithm
  outVarLst := match (inVarOptionArray1,posEq,inInteger2,inInteger3, acc)
    local
      tuple<Key,Value> v;
      array<Option<tuple<Key,Value>>> arr;
      Integer pos,lastpos,pos_1;
      list<tuple<Key,Value>> res;
    
    case (arr,true,pos,lastpos,acc)
      equation
        acc = List.consOption(arr[pos + 1],acc);
      then listReverse(acc);
    
    case (arr,false,pos,lastpos,acc)
      equation
        pos_1 = pos + 1;
        acc = List.consOption(arr[pos + 1],acc);
      then valueArrayList2(arr, pos_1==lastpos, pos_1, lastpos, acc);
    
  end match;
end valueArrayList2;

public function hashTableCurrentSize
  "Returns the number of elements inserted into the table"
  input HashTable hashTable;
  output Integer sz;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type HashTable = tuple<HashVector, ValueArray, Integer, Integer, FuncsTuple>;
  type HashVector = array<list<tuple<Key,Integer>>>;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
  type FuncsTuple = tuple<FuncHash,FuncEq,FuncKeyString,FuncValString>;
  partial function FuncHash input Key key; input Integer mod; output Integer hash; end FuncHash;
  partial function FuncEq input Key key1; input Key key2; output Boolean b; end FuncEq;
  partial function FuncKeyString input Key key; output String str; end FuncKeyString;
  partial function FuncValString input Value val; output String str; end FuncValString;
protected
  ValueArray va;
algorithm
  (_,va,_,_,_) := hashTable;
  sz := valueArrayLength(va);
end hashTableCurrentSize;

public function valueArrayLength
"Returns the number of elements in the ValueArray"
  input ValueArray valueArray;
  output Integer sz;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
algorithm
  (sz,_,_) := valueArray;
end valueArrayLength;

public function valueArrayAdd
"Adds an entry last to the ValueArray, increasing array size if no space left
by factor 1.4"
  input ValueArray valueArray;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
algorithm
  outValueArray:=
  matchcontinue (valueArray,entry)
    local
      Integer n_1,n,size,expandsize,expandsize_1,newsize;
      array<Option<tuple<Key,Value>>> arr_1,arr,arr_2;
      Real rsize,rexpandsize;
    case ((n,size,arr),entry)
      equation
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(entry));
      then
        ((n_1,size,arr_1));

    case ((n,size,arr),entry)
      equation
        (n < size) = false "Do NOT have space to add array elt. Expand with factor 1.4" ;
        rsize = intReal(size);
        rexpandsize = rsize *. 0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Util.arrayExpand(expandsize_1, arr, NONE());
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(entry));
      then
        ((n_1,newsize,arr_2));
    case (_,_)
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
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
algorithm
  outValueArray:=
  matchcontinue (valueArray,pos,entry)
    local
      array<Option<tuple<Key,Value>>> arr_1,arr;
      Integer n,size;
    case ((n,size,arr),pos,entry)
      equation
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, SOME(entry));
      then
        ((n,size,arr_1));
    case (_,_,_)
      equation
        print("-HashTable.valueArraySetnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArraySetnth;

public function valueArrayClearnth
"Clears the n:th variable in the ValueArray (set to NONE())."
  input ValueArray valueArray;
  input Integer pos;
  output ValueArray outValueArray;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
algorithm
  outValueArray := matchcontinue (valueArray,pos)
    local
      array<Option<tuple<Key,Value>>> arr_1,arr;
      Integer n,size;
    case ((n,size,arr),pos)
      equation
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1,NONE());
      then
        ((n,size,arr_1));
    case (_,_)
      equation
        print("-HashTable.valueArrayClearnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayClearnth;

public function valueArrayNth
"Retrieve the n:th Value from ValueArray, index from 0..n-1."
  input ValueArray valueArray;
  input Integer pos;
  output Key key;
  output Value value;

  replaceable type Key subtypeof Any;
  replaceable type Value subtypeof Any;
  type ValueArray = tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>;
algorithm
  (key, value) := match (valueArray,pos)
    local
      Key k;
      Value v;
      Integer n;
      array<Option<tuple<Key,Value>>> arr;
    case ((n,_,arr),pos)
      equation
        (pos <= n) = true;
        SOME((k,v)) = arr[pos + 1];
      then
        (k, v);
  end match;
end valueArrayNth;

end BaseHashTable;
