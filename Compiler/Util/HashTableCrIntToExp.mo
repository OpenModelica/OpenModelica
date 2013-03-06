encapsulated package HashTableCrIntToExp "
  This file is an extension to OpenModelica.

  Copyright (c) 2007 MathCore Engineering AB

  All rights reserved.

  file:        HashTableCrIntToExp.mo
  package:     HashTableCrIntToExp
  description: (DAE.CR,DAE.CR) to DAE.Exp

  RCS: $Id: HashTableCrIntToExp.mo 8796 2011-05-03 19:43:08Z adrpo $

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
protected import ExpressionDump;
protected import Util;

public type Key = tuple<DAE.ComponentRef,Integer>;
public type Value = DAE.Exp;

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
  input Key tpl;
  input Integer mod;
  output Integer res;
algorithm
  res := intMod(intAbs(ComponentReference.hashComponentRef(Util.tuple21(tpl)) + Util.tuple22(tpl)),mod);
end hashFunc;

protected function keyEqual
  input Key tpl1;
  input Key tpl2;
  output Boolean res;
algorithm
  res := matchcontinue (tpl1,tpl2)
    local
      DAE.ComponentRef cr1,cr2;
      Integer i1,i2;
    case ((cr1,i1),(cr2,i2))
      equation
        true = intEq(i1,i2) "int compare is less expensive";
      then ComponentReference.crefEqual(cr1,cr2);
    else then false;
  end matchcontinue;
end keyEqual;

protected function printKey
  input Key tpl;
  output String res;
algorithm
  res := ComponentReference.printComponentRefStr(Util.tuple21(tpl)) +& "," +& intString(Util.tuple22(tpl));
end printKey;

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
  hashTable := BaseHashTable.emptyHashTableWork(size,(hashFunc,keyEqual,printKey,ExpressionDump.printExpStr));
end emptyHashTableSized;

end HashTableCrIntToExp;
