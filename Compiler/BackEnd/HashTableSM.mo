encapsulated package HashTableSM "
 HashTable instance specific code "

public import BaseHashTable;
public import DAE;
protected import ComponentReference;
protected import StateMachineFeatures;
protected import HashSet;
protected import BaseHashSet;
protected import List;


public type Key = DAE.ComponentRef;
public type Value = StateMachineFeatures.Mode;

public type HashTableCrefFunctionsType = tuple<FuncHashCref, FuncCrefEqual, FuncCrefStr, FuncExpStr>;
public type HashTable = tuple<array<list<tuple<Key, Integer>>>,
                              tuple<Integer, Integer, array<Option<tuple<Key, Value>>>>,
                              Integer,
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
  hashTable := BaseHashTable.emptyHashTableWork(size,(ComponentReference.hashComponentRefMod,ComponentReference.crefEqual,ComponentReference.printComponentRefStr,modeToString));
end emptyHashTableSized;

public function modeToString
  input StateMachineFeatures.Mode mode;
  output String s;
protected
  String name;
  Boolean isInitial;
  HashSet.HashSet edges;
  list<DAE.ComponentRef> crefs;
  list<String> paths;
algorithm
  StateMachineFeatures.MODE(name=name, isInitial=isInitial, edges=edges) := mode;
  crefs := BaseHashSet.hashSetList(edges);
  paths := List.map(crefs, ComponentReference.printComponentRefStr);
  s := "MODE(" + stringDelimitList({name,boolString(isInitial)}, ",") + "), "
     + "EDGES(" + stringDelimitList(paths, ", ") +"))";
end modeToString;

annotation(__OpenModelica_Interface="backend");
end HashTableSM;

