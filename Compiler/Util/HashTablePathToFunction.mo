encapsulated package HashTablePathToFunction "
  This file is an extension to OpenModelica.

  Copyright (c) 2007 MathCore Engineering AB

  All rights reserved.

  file:  HashTablePathToFunction.mo
  package:     HashTablePathToFunction
  description: Absyn.Path to NFInstTypes.Function

  RCS: $Id$

  "

/* Below is the instance specific code. For each hashtable the user must define:

Key       - The key used to uniquely define elements in a hashtable
Value     - The data to associate with each key
hashFunc   - A function that maps a key to a positive integer.
keyEqual   - A comparison function between two keys, returns true if equal.
*/

/* HashTable instance specific code */

public import BaseHashTable;
public import Absyn;
public import NFInstTypes;

protected import System;

public type Key = Absyn.Path;
public type Value = NFInstTypes.Function;

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

protected function hashFunc
"Calculates a hash value for Key"
  input Key path;
  input Integer mod;
  output Integer res;
protected
  String str;
algorithm
  str := Absyn.pathString(path);
  res := System.stringHashDjb2Mod(str,mod);
end hashFunc;

protected function valString
  input Value v;
  output String str;
algorithm
  str := "/* a function of some kind */";
end valString;

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
"
  Returns an empty HashTable.
  Using the bucketsize size.
"
  input Integer size;
  output HashTable hashTable;
algorithm
  hashTable := BaseHashTable.emptyHashTableWork(size,(hashFunc,Absyn.pathEqual,Absyn.pathString,valString));
end emptyHashTableSized;

end HashTablePathToFunction;
