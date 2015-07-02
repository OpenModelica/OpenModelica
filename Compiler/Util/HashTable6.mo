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

encapsulated package HashTable6

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

public type Key = tuple<DAE.ComponentRef,DAE.ComponentRef>;
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
  input Key key;
  input Integer mod;
  output Integer res;
protected
  String crstr;
  DAE.ComponentRef cr1,cr2;
algorithm
  (cr1,cr2) := key;
  // Use same factor as Djb2 hash (33)
  res := intMod(intAbs(ComponentReference.hashComponentRef(cr1)+ 33*ComponentReference.hashComponentRef(cr2)),mod);
end hashFunc;

protected function keyEqual
  input Key tpl1;
  input Key tpl2;
  output Boolean res;
algorithm
  res := matchcontinue (tpl1,tpl2)
    local
      DAE.ComponentRef cr11,cr12,cr21,cr22;
    case ((cr11,cr12),(cr21,cr22))
      then ComponentReference.crefEqualNoStringCompare(cr11,cr21) and ComponentReference.crefEqualNoStringCompare(cr12,cr22);
  end matchcontinue;
end keyEqual;

protected function printKey
  input Key tpl;
  output String res;
algorithm
  res := ComponentReference.printComponentRefStr(Util.tuple21(tpl))+","+ComponentReference.printComponentRefStr(Util.tuple22(tpl));
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

annotation(__OpenModelica_Interface="util");
end HashTable6;
