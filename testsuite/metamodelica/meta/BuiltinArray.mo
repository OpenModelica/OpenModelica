package BuiltinArray

function test
  input Integer nelem;
  input Integer val;
  input Integer getn;
protected
  array<Integer> arrCopy;
  array<Integer> arr;
  Integer arrLength;
  Integer arrElem;
  list<Integer> arrList;
  array<Integer> listArr;
  array<Integer> arrAppend;
algorithm
  arr := arrayCreate(nelem, val);
  print(anyString(arr) + "\n");
  arrCopy := arrayCopy(arr);
  print(anyString(arrCopy) + "\n");
  _ := arrayUpdate(arr, getn, val+1);
  print(anyString(arr) + "\n");
  arrLength := arrayLength(arr);
  print(intString(arrLength) + "\n");
  arrElem := arrayGet(arr, getn);
  print(intString(arrElem) + "\n");
  arrList := arrayList(arr);
  print(anyString(arrList) + "\n");
  listArr := listArray(val+2::arrList);
  print(anyString(listArr) + "\n");
  arrAppend := arrayAppend(arr, listArr);
  print(anyString(arrAppend) + "\n");
end test;

end BuiltinArray;
