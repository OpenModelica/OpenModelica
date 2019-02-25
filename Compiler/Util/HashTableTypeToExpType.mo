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

encapsulated package HashTableTypeToExpType "
  This file is an extension to OpenModelica.

  file:        HashTableTypeToExpType.mo
  package:     HashTableTypeToExpType
  description: Type to ExpType

  "

/* Below is the instance specific code. For each hashtable the user must define:

Key       - The key used to uniquely define elements in a hashtable
Value     - The data to associate with each key
hashFunc   - A function that maps a key to a positive integer.
keyEqual   - A comparison function between two keys, returns true if equal.
*/

/* HashTable instance specific code */

public import DAE;
public import BaseHashTable;
protected import Types;
protected import System;

public type Key = DAE.Type;
public type Value = DAE.Type;

public type HashTableCrefFunctionsType = tuple<FuncHashType,FuncTypeEqual,FuncTypeStr,FuncExpTypeStr>;
public type HashTable = tuple<
  array<list<tuple<Key,Integer>>>,
  tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>,
  Integer,
  HashTableCrefFunctionsType
>;

partial function FuncHashType
  input Key ty;
  input Integer mod;
  output Integer res;
end FuncHashType;

partial function FuncTypeEqual
  input Key ty1;
  input Key ty2;
  output Boolean res;
end FuncTypeEqual;

partial function FuncTypeStr
  input Key ty;
  output String res;
end FuncTypeStr;

partial function FuncExpTypeStr
  input Value exp;
  output String res;
end FuncExpTypeStr;

public function myHash
  input DAE.Type inTy;
  input Integer hashMod;
  output Integer hash;
protected
  String str;
  DAE.Type tt;
  DAE.Type t;
algorithm
  //str := Types.printTypeStr(inTy);
  //hash := stringHashDjb2Mod(str, hashMod);
  //print("hash: " + intString(hash) + " for " + str + "\n");
  (tt, _) := inTy;
  t := (tt, NONE());
  hash := valueHashMod(t, hashMod);
end myHash;

public function emptyHashTable
"Returns an empty HashTable.
 Using the default bucketsize.."
  output HashTable hashTable;
algorithm
  hashTable := emptyHashTableSized(BaseHashTable.biggerBucketSize);
end emptyHashTable;

public function emptyHashTableSized
"Returns an empty HashTable.
  Using the bucketsize size."
  input Integer size;
  output HashTable hashTable;
algorithm
  hashTable := BaseHashTable.emptyHashTableWork(size,(myHash,Types.typesElabEquivalent,Types.printTypeStr,Types.printExpTypeStr));
end emptyHashTableSized;

annotation(__OpenModelica_Interface="util");
end HashTableTypeToExpType;
