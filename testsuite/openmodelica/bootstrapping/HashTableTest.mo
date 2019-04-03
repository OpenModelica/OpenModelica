package HashTableTest

import HashTable2.emptyHashTable;
import HashTable2.HashTable;
import BaseHashTable.*;

function fn
  input Integer i;
  output list<DAE.Exp> lst;
  output list<DAE.Exp> values;
protected
  DAE.ComponentRef wild;
  DAE.ComponentRef abc;
  DAE.ComponentRef def;
  HashTable2.HashTable ht;
algorithm
  wild := DAE.WILD();
  abc := DAE.CREF_IDENT("abc",DAE.T_INTEGER_DEFAULT,{});
  def := DAE.CREF_IDENT("def",DAE.T_INTEGER_DEFAULT,{});
  lst := {};
  ht := emptyHashTable();
  ht := add((wild,DAE.ICONST(i)),ht);
  ht := add((abc,DAE.ICONST(i*2)),ht);
  ht := add((def,DAE.ICONST(i*3)),ht);
  lst := {};
  lst := get(wild,ht)::lst;
  lst := get(abc,ht)::lst;
  lst := get(def,ht)::lst;
  ht := add((def,DAE.ICONST(i*7)),ht);
  lst := get(def,ht)::lst;
  ht := add((wild,DAE.ICONST(i*9)),ht);
  delete(wild,ht);
  failure(lst := get(wild,ht)::lst);
  values := BaseHashTable.hashTableValueList(ht);
  HashTableStringToPath.emptyHashTable() "verify that this also works";
  UnitAbsynBuilder.emptyInstStore() "verify that this also works; stores tuple<function> inside a metarecord";
end fn;

end HashTableTest;
