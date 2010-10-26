encapsulated package HashTable2 "
	This file is an extension to OpenModelica.

  Copyright (c) 2007 MathCore Engineering AB

  All rights reserved.


  Based on HashTable.mo but
  Key 		= DAE.ComponentRef
  Value 	= DAE.Exp

  Not used by OpenModelica!

  RCS: $Id$

  "
  
/* Below is the instance specific code. For each hashtable the user must define:

Key 			- The key used to uniquely define elements in a hashtable
Value 		- The data to associate with each key
hashFunc 	- A function that maps a key to a positive integer.
keyEqual 	- A comparison function between two keys, returns true if equal.
*/

/* HashTable instance specific code */

public import BaseHashTable;
public import DAE;
public import ComponentReference;
protected import Exp;
protected import System;
protected import Util;

public type Key = DAE.ComponentRef;
public type Value = DAE.Exp;

public type HashTableCrefFunctionsType = tuple<FuncHashCref,FuncCrefEqual,FuncCrefStr,FuncExpStr>;
public constant HashTableCrefFunctionsType HashTableCrefToExpFunctions = (hashFuncCref,ComponentReference.crefEqual,ComponentReference.printComponentRefStr,Exp.printExpStr);
public type HashTable = tuple<
  array<list<tuple<DAE.ComponentRef,Integer>>>,
  tuple<Integer,Integer,array<Option<tuple<DAE.ComponentRef,DAE.Exp>>>>,
  Integer,
  Integer,
  HashTableCrefFunctionsType
>;

partial function FuncHashCref
  input DAE.ComponentRef cr;
  output Integer res;
end FuncHashCref;

partial function FuncCrefEqual
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean res;
end FuncCrefEqual;

partial function FuncCrefStr
  input DAE.ComponentRef cr;
  output String res;
end FuncCrefStr;

partial function FuncExpStr
  input DAE.Exp exp;
  output String res;
end FuncExpStr;

protected function hashFuncCref
"Calculates a hash value for DAE.ComponentRef"
  input DAE.ComponentRef cr;
  output Integer res;
  String crstr;
algorithm
  crstr := ComponentReference.printComponentRefStr(cr);
  res := System.hash(crstr);
end hashFuncCref;

public function emptyHashTable
"
  Returns an empty HashTable.
  Using the bucketsize 1000 and array size 100.
"
  output HashTable hashTable;
algorithm
  hashTable := BaseHashTable.emptyHashTableWork(1000,100,HashTableCrefToExpFunctions);
end emptyHashTable;

public function emptyHashTableSized
"
  Returns an empty HashTable.
  Using the bucketsize size and arraysize size/10.
"
  input Integer size;
  output HashTable hashTable;
algorithm
  hashTable := BaseHashTable.emptyHashTableWork(size,size/10,HashTableCrefToExpFunctions);
end emptyHashTableSized;

end HashTable2;
