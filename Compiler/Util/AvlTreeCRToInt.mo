encapsulated package AvlTreeCRToInt "AvlTree for String to Integer. New implementation only used by the backend (until we get a new bootstrapping tarball)"
  import BaseAvlTree;
  import DAE;
  protected
  import ComponentReference;
  public
  extends BaseAvlTree;
  redeclare type Key = DAE.ComponentRef;
  redeclare type Value = Integer;
  redeclare function extends keyStr
  algorithm
    outString := ComponentReference.printComponentRefStr(inKey);
  end keyStr;
  redeclare function extends valueStr
  algorithm
    outString := String(inValue);
  end valueStr;
  redeclare function extends keyCompare
  algorithm
    outResult := ComponentReference.crefCompareIntSubscript(inKey1, inKey2);
  end keyCompare;
annotation(__OpenModelica_Interface="backend");
end AvlTreeCRToInt;
