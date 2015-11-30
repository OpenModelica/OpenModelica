encapsulated package AvlTreeString2 "AvlTree for String to Integer. New implementation only used by the backend (until we get a new bootstrapping tarball)"
  import BaseAvlTree;
  extends BaseAvlTree;
  redeclare type AvlKey = String;
  redeclare type AvlValue = Integer;
  redeclare function extends keyStr
  algorithm
    str := key;
  end keyStr;
  redeclare function extends valueStr
  algorithm
    str := String(value);
  end valueStr;
  redeclare function extends avlKeyCompare
  algorithm
    c := stringCompare(key1,key2);
  end avlKeyCompare;
annotation(__OpenModelica_Interface="util");
end AvlTreeString2;
