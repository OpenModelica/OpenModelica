package HashTable5 "
	  This file is an extension to OpenModelica.
  	
  Copyright (c) 2007-2009 MathCore Engineering AB
  	
  All rights reserved.
  
  
  This package contains implementation of hashtables, instead of the binary trees used in OpenModelica.
  It is a generic implementation that can be used for any Key, Value datatypes. But the code must be copied
  since MetaModelica is not powerful enough to handle general generics.
  
  "


/* Below is the instance specific code. For each hashtable the user must define:

Key 			- The key used to uniquely define elements in a hashtable
Value 		- The data to associate with each key
hashFunc 	- A function that maps a key to a positive integer.
keyEqual 	- A comparison function between two keys, returns true if equal.
*/

/* HashTable instance specific code */
public import Absyn;

protected import System;
protected import Util;
protected import Dump;


public 
 type Key = Absyn.ComponentRef;
 type Value = Integer;
   
protected function hashFunc "
  author: PA
 
  Calculates a hash value for DAE.Exp
"
  input Absyn.ComponentRef cr;
  output Integer res;
  String crstr;
algorithm 
  crstr := Dump.printComponentRefStr(cr);
  res := System.hash(crstr);
end hashFunc;

protected function keyEqual
  input Key key1;
  input Key key2;
  output Boolean res;
algorithm
     res := Absyn.crefEqual(key1,key2);
end keyEqual;


protected function dumpHashTable
  input HashTable t;
algorithm
  print("HashTable:\n");
  print(Util.stringDelimitList(Util.listMap(hashTableList(t),dumpTuple),"\n"));
  print("\n");
end dumpHashTable;

protected function dumpTuple
  input tuple<Key,Value> tpl;
  output String str;
algorithm
  str := matchcontinue(tpl)
  local 
  Absyn.ComponentRef cr; Integer i;
    case((cr,i)) equation
      str = "{" +& Dump.printComponentRefStr(cr) +& "," +& intString(i) +& "}";
    then str;
  end matchcontinue;
end dumpTuple;

/* end of HashTable instance specific code */

/* Generic hashtable code below!! */
public  
uniontype HashTable
  record HASHTABLE
    list<tuple<Key,Integer>>[:] hashTable " hashtable to translate Key to array indx" ;
    ValueArray valueArr "Array of values" ;
    Integer bucketSize "bucket size" ;
    Integer numberOfEntries "number of entries in hashtable" ;   
  end HASHTABLE; 
end HashTable; 

uniontype ValueArray "array of values are expandable, to amortize the cost of adding elements in a more 
efficient manner"
  record VALUE_ARRAY
    Integer numberOfElements "number of elements in hashtable" ;
    Integer arrSize "size of crefArray" ;
    Option<tuple<Key,Value>>[:] valueArray "array of values";
  end VALUE_ARRAY;
end ValueArray;

public function emptyHashTable "
  author: PA
 
  Returns an empty HashTable.
  Using the bucketsize 100 and array size 10.
"
  output HashTable hashTable;
  list<tuple<Key,Integer>>[:] arr;
  list<Option<tuple<Key,Value>>> lst;
  Option<tuple<Key,Value>>[:] emptyarr;
algorithm 
  arr := fill({}, 1000);
  // lst := Util.listFill(NONE, 100);
  // emptyarr := listArray(lst);
    emptyarr := fill(NONE(), 100);
  hashTable := HASHTABLE(arr,VALUE_ARRAY(0,100,emptyarr),1000,0);
end emptyHashTable;

public function isEmpty "Returns true if hashtable is empty"
  input HashTable hashTable;
  output Boolean res;
algorithm
  res := matchcontinue(hashTable)
    case(HASHTABLE(_,_,_,0)) then true;
    case(_) then false;  
  end matchcontinue;
end isEmpty;

public function add "
  author: PA
 
  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value.
"
  input tuple<Key,Value> entry;
  input HashTable hashTable;
  output HashTable outHahsTable;
algorithm 
  outVariables:=
  matchcontinue (entry,hashTable)
    local     
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      list<tuple<Key,Integer>>[:] hashvec_1,hashvec;
      String name_str;      
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
      /* Adding when not existing previously */
    case ((v as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        failure((_) = get(key, hashTable));
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);        
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);
      
      /* adding when already present => Updating value */
    case ((newv as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        (_,indx) = get1(key, hashTable);
        //print("adding when present, indx =" );print(intString(indx));print("\n");
        indx_1 = indx - 1;
        varr_1 = valueArraySetnth(varr, indx, newv);
      then HASHTABLE(hashvec,varr_1,bsize,n);
    case (_,_)
      equation 
        print("-HashTable.add failed\n");
      then
        fail();
  end matchcontinue;
end add;

public function addNoUpdCheck "
  author: PA
 
  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value.
"
  input tuple<Key,Value> entry;
  input HashTable hashTable;
  output HashTable outHahsTable;
algorithm 
  outVariables:=
  matchcontinue (entry,hashTable)
    local     
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      list<tuple<Key,Integer>>[:] hashvec_1,hashvec;
      String name_str;      
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
      /* Adding when not existing previously */
    case ((v as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);        
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);
          case (_,_)
      equation 
        print("-HashTable.addNoUpdCheck failed\n");
      then
        fail();
  end matchcontinue;
end addNoUpdCheck;

public function delete "
  author: PA
 
  delete the Value associatied with Key from the HashTable.
  Note: This function does not delete from the index table, only from the ValueArray.
  This means that a lot of deletions will not make the HashTable more compact, it will still contain
  a lot of incices information.
"
  input Key key;
  input HashTable hashTable;
  output HashTable outHahsTable;
algorithm 
  outVariables:=
  matchcontinue (key,hashTable)
    local     
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      list<tuple<Key,Integer>>[:] hashvec_1,hashvec;
      String name_str;      
      tuple<Key,Value> v,newv;
      Key key;
      Value value;     
      /* adding when already present => Updating value */
    case (key,(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        (_,indx) = get1(key, hashTable);
        indx_1 = indx - 1;
        varr_1 = valueArrayClearnth(varr, indx);
      then HASHTABLE(hashvec,varr_1,bsize,n);
    case (_,hashTable)
      equation 
        //print("-HashTable.delete failed\n");
      then
        hashTable;
  end matchcontinue;
end delete;


public function get "
author: PA
  
   Returns a Value given a Key and a HashTable.
"
  input Key key;
  input HashTable hashTable;
  output Value value;
algorithm 
  (value,_):= get1(key,hashTable);
end get;

protected function get1 "help function to get"
  input Key key;
  input HashTable hashTable;
  output Value value;
  output Integer indx;
algorithm 
  (value,indx):=
  matchcontinue (key,hashTable)
    local
      Integer hval,hashindx,indx,indx_1,bsize,n;
      list<tuple<Key,Integer>> indexes;
      Value v;      
      list<tuple<Key,Integer>>[:] hashvec;     
      ValueArray varr;
      Key key2;
    case (key,(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        hval = hashFunc(key);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = get2(key, indexes);
        v = valueArrayNth(varr, indx);
      then
        (v,indx);
  end matchcontinue;
end get1;

protected function get2 "
 author: PA
  
  Helper function to get
"
  input Key key;
  input list<tuple<Key,Integer>> keyIndices;
  output Integer index;
algorithm 
  index :=
  matchcontinue (key,keyIndices)
    local
      Key key2;
      Value res;
      list<tuple<Key,Integer>> xs;
    case (key,((key2,index) :: _))
      equation 
        true = keyEqual(key, key2);
      then
        index;
    case (key,(_ :: xs))      
      equation 
        index = get2(key, xs);
      then
        index;
  end matchcontinue;
end get2;

public function hashTableValueList "return the Value entries as a list of Values"
  input HashTable hashTable;
  output list<Value> valLst;
algorithm
   valLst := Util.listMap(hashTableList(hashTable),Util.tuple22);
end hashTableValueList;

public function hashTableKeyList "return the Key entries as a list of Keys"
  input HashTable hashTable;
  output list<Key> valLst;
algorithm
   valLst := Util.listMap(hashTableList(hashTable),Util.tuple21);
end hashTableKeyList;

public function hashTableList "returns the entries in the hashTable as a list of tuple<Key,Value>"
  input HashTable hashTable;
  output list<tuple<Key,Value>> tplLst;
algorithm
  tplLst := matchcontinue(hashTable)
  local ValueArray varr;
    case(HASHTABLE(valueArr = varr)) equation
      tplLst = valueArrayList(varr);
    then tplLst; 
  end matchcontinue;
end hashTableList;

public function valueArrayList "
 author: PA
  Transforms a ValueArray to a tuple<Key,Value> list
"
  input ValueArray valueArray;
  output list<tuple<Key,Value>> tplLst;
algorithm 
  tplLst :=
  matchcontinue (valueArray)
    local
      Option<tuple<Key,Value>>[:] arr;
      tuple<Key,Value> elt;
      Integer lastpos,n,size;
      list<tuple<Key,Value>> lst;
    case (VALUE_ARRAY(numberOfElements = 0,valueArray = arr)) then {}; 
    case (VALUE_ARRAY(numberOfElements = 1,valueArray = arr))
      equation 
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr))
      equation 
        lastpos = n - 1;
        lst = valueArrayList2(arr, 0, lastpos);
      then
        lst;
  end matchcontinue;
end valueArrayList;

protected function valueArrayList2 "Helper function to valueArrayList"
  input Option<tuple<Key,Value>>[:] inVarOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<tuple<Key,Value>> outVarLst;
algorithm 
  outVarLst:=
  matchcontinue (inVarOptionArray1,inInteger2,inInteger3)
    local
      tuple<Key,Value> v;
      Option<tuple<Key,Value>>[:] arr;
      Integer pos,lastpos,pos_1;
      list<tuple<Key,Value>> res;
    case (arr,pos,lastpos)
      equation 
        (pos == lastpos) = true;
        SOME(v) = arr[pos + 1];
      then
        {v};
    case (arr,pos,lastpos)
      equation 
        pos_1 = pos + 1;
        SOME(v) = arr[pos + 1];
        res = valueArrayList2(arr, pos_1, lastpos);
      then
        (v :: res);
    case (arr,pos,lastpos)
      equation 
        pos_1 = pos + 1;
        NONE = arr[pos + 1];
        res = valueArrayList2(arr, pos_1, lastpos);
      then
        (res);
  end matchcontinue;
end valueArrayList2;

public function valueArrayLength "
  author: PA
 
  Returns the number of elements in the ValueArray
"
  input ValueArray valueArray;
  output Integer size;
algorithm 
  size := matchcontinue (valueArray)
    case (VALUE_ARRAY(numberOfElements = size)) then size; 
  end matchcontinue;
end valueArrayLength;

public function valueArrayAdd "function: valueArrayAdd
  author: PA 
  Adds an entry last to the ValueArray, increasing array size
  if no space left by factor 1.4
"
  input ValueArray valueArray;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm 
  outValueArray:=
  matchcontinue (valueArray,entry)
    local
      Integer n_1,n,size,expandsize,expandsize_1,newsize;
      Option<tuple<Key,Value>>[:] arr_1,arr,arr_2;
      Real rsize,rexpandsize;
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),entry)
      equation 
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,size,arr_1);
        
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),entry)
      equation 
        (n < size) = false "Do NOT have splace to add array elt. Expand with factor 1.4" ;
        rsize = intReal(size);
        rexpandsize = rsize*.0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Util.arrayExpand(expandsize_1, arr, NONE);
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,newsize,arr_2);
    case (_,_)
      equation 
        print("-HashTable.valueArrayAdd failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayAdd;

public function valueArraySetnth "function: valueArraySetnth
  author: PA 
  Set the n:th variable in the ValueArray to value.
"
  input ValueArray valueArray;
  input Integer pos;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm 
  outValueArray:=
  matchcontinue (valueArray,pos,entry)
    local
      Option<tuple<Key,Value>>[:] arr_1,arr;
      Integer n,size,pos;      
    case (VALUE_ARRAY(n,size,arr),pos,entry)
      equation 
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, SOME(entry));
      then
        VALUE_ARRAY(n,size,arr_1);
    case (_,_,_)
      equation 
        print("-HashTable.valueArraySetnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArraySetnth;

public function valueArrayClearnth "
  author: PA
  Clears the n:th variable in the ValueArray (set to NONE).
"
  input ValueArray valueArray;
  input Integer pos;
  output ValueArray outValueArray;
algorithm 
  outValueArray:=
  matchcontinue (valueArray,pos)
    local
      Option<tuple<Key,Value>>[:] arr_1,arr;
      Integer n,size,pos;      
    case (VALUE_ARRAY(n,size,arr),pos)
      equation 
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, NONE);
      then
        VALUE_ARRAY(n,size,arr_1);
    case (_,_)
      equation 
        print("-HashTable.valueArrayClearnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayClearnth;

public function valueArrayNth "function: valueArrayNth
  author: PA
 
  Retrieve the n:th Vale from ValueArray, index from 0..n-1.
 "
  input ValueArray valueArray;
  input Integer pos;
  output Value value;
algorithm 
  value:=
  matchcontinue (valueArray,pos)
    local
      Value v;
      Integer n,pos,len;
      Option<tuple<Key,Value>>[:] arr;
      String ps,lens,ns;
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation 
        (pos < n) = true;
        SOME((_,v)) = arr[pos + 1];
      then
        v;
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation 
        (pos < n) = true;
        NONE = arr[pos + 1];
      then
        fail();
  end matchcontinue;
end valueArrayNth;

end HashTable5; 
