encapsulated package HashTableCrILst "
  This file is an extension to OpenModelica.

  Copyright (c) 2007 MathCore Engineering AB

  All rights reserved.

  file:  HashTableCrILst.mo
  package:     HashTableCrILst
  description: DAE.CR to list<Integer>

  RCS: $Id: HashTableCrILst.mo 8796 2011-05-03 19:43:08Z adrpo $

  "

/* Below is the instance specific code. For each hashtable the user must define:

Key       - The key used to uniquely define elements in a hashtable
Value     - The data to associate with each key
hashFunc   - A function that maps a key to a positive integer.
keyEqual   - A comparison function between two keys, returns true if equal.
*/

/* HashTable instance specific code */

public import BaseHashTable;
public import DAE;
protected import ComponentReference;
protected import List;

public type Key = DAE.ComponentRef;
public type Value = list<Integer>;

public type HashTableCrefFunctionsType = tuple<FuncHashCref,FuncCrefEqual,FuncCrefStr,FuncExpStr>;
public type HashTable = tuple<
  array<list<tuple<Key,Integer>>>,
  tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>,
  Integer,
  Integer,
  HashTableCrefFunctionsType
>;

partial function FuncHashCref
  input Key cr;
  input Integer mod;
  output Integer res;
end FuncHashCref;

partial function FuncCrefEqual
  input Key cr1;
  input Key cr2;
  output Boolean res;
end FuncCrefEqual;

partial function FuncCrefStr
  input Key cr;
  output String res;
end FuncCrefStr;

partial function FuncExpStr
  input Value exp;
  output String res;
end FuncExpStr;

public function emptyHashTable
"
  Returns an empty HashTable.
  Using the default bucketsize..
"
  output HashTable hashTable;
algorithm
  hashTable := emptyHashTableSized(BaseHashTable.defaultBucketSize);
end emptyHashTable;

public function emptyHashTableSized
"Returns an empty HashTable.
 Using the bucketsize size."
  input Integer size;
  output HashTable hashTable;
algorithm
  hashTable := BaseHashTable.emptyHashTableWork(size,(ComponentReference.hashComponentRefMod,ComponentReference.crefEqual,ComponentReference.printComponentRefStr,printIntListStr));
end emptyHashTableSized;

public function printIntListStr
  input list<Integer> ilst;
  output String res;
algorithm
  res := "{" +& stringDelimitList(List.map(ilst, intString), ",") +& "}";
end printIntListStr;

end HashTableCrILst;
