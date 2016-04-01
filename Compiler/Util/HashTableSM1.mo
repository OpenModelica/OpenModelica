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
encapsulated package HashTableSM1 "
 HashTable instance specific code "

public import BaseHashTable;
public import DAE;
protected import ComponentReference;
protected import HashSet;
protected import BaseHashSet;
protected import List;
protected import InstStateMachineUtil;

public type Key = DAE.ComponentRef;
public type Value = InstStateMachineUtil.SMNode;

public type HashTableCrefFunctionsType = tuple<FuncHashCref, FuncCrefEqual, FuncCrefStr, FuncExpStr>;
public type HashTable = tuple<array<list<tuple<Key, Integer>>>,
                              tuple<Integer, Integer, array<Option<tuple<Key, Value>>>>,
                              Integer,
                              HashTableCrefFunctionsType>;

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
 Using the bucketsize size"
  input Integer size;
  output HashTable hashTable;
algorithm
  hashTable := BaseHashTable.emptyHashTableWork(size,(ComponentReference.hashComponentRefMod,ComponentReference.crefEqual,ComponentReference.printComponentRefStr,modeStr));
end emptyHashTableSized;

public function modeStr
  input InstStateMachineUtil.SMNode mode;
  output String s;
protected
  DAE.ComponentRef componentRef;
  Boolean isInitial;
  HashSet.HashSet edges;
  list<DAE.ComponentRef> crefs;
  list<String> paths;
algorithm
  InstStateMachineUtil.SMNODE(componentRef=componentRef, isInitial=isInitial, edges=edges) := mode;
  crefs := BaseHashSet.hashSetList(edges);
  paths := List.map(crefs, ComponentReference.printComponentRefStr);
  s := "SMNODE(" + ComponentReference.printComponentRefStr(componentRef) + ", "+boolString(isInitial) + ","
     + "EDGES(" + stringDelimitList(paths, ", ") +"))\n";
end modeStr;

annotation(__OpenModelica_Interface="frontend");
end HashTableSM1;
