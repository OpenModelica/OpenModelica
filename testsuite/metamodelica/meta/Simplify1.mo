function Simplify1
  input list<Integer> inList;
  input Integer inPos;
protected
  array<Integer> arr;
  Integer val1, val2;
  constant Integer c = 42;
algorithm
  arr := listArray(inList);
  val1 := arr[inPos] + c;
  val2 := arr[inPos];
  val2 := val2 + c;
  print(intString(val1) + " == " + intString(val2) + "\n");
end Simplify1;
