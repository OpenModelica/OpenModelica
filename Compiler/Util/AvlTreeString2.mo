encapsulated package AvlTreeString2 "AvlTree for String to Integer. New implementation only used by the backend (until we get a new bootstrapping tarball)"
  import BaseAvlTree;
  extends BaseAvlTree;
  redeclare type Key = String;
  redeclare type Value = Integer;
  redeclare function extends keyStr
  algorithm
    outString := inKey;
  end keyStr;
  redeclare function extends valueStr
  algorithm
    outString := String(inValue);
  end valueStr;
  redeclare function extends keyCompare
  algorithm
    outResult := stringCompare(inKey1, inKey2);
  end keyCompare;
annotation(__OpenModelica_Interface="util");
end AvlTreeString2;
