function id<T>
  input T i;
  output T o=i;
end id;

function isWhitespace<T>
  input T t;
  output Boolean b = false;
end isWhitespace;

function TestDiffAlgorithm
protected
  list<tuple<DiffAlgorithm.Diff, list<Integer>>> intDiffs;
  list<tuple<DiffAlgorithm.Diff, list<String>>> strDiffs;
algorithm
  intDiffs := debug_diff({1,2,3},{1,2,3}, intEq, intString);
  print(DiffAlgorithm.printDiffTerminalColor(intDiffs, intString));
  print("\n");
  intDiffs := debug_diff({1,2,3},{1,2,3,4,5,6}, intEq, intString);
  print(DiffAlgorithm.printDiffTerminalColor(intDiffs, intString));
  print("\n");
  intDiffs := debug_diff({1,2,3,4,5,6},{1,2,3}, intEq, intString);
  print(DiffAlgorithm.printDiffTerminalColor(intDiffs, intString));
  print("\n");
  intDiffs := debug_diff({1,2,3,4,5,6},{1,2,3,6}, intEq, intString);
  print(DiffAlgorithm.printDiffTerminalColor(intDiffs, intString));
  print("\n");
  intDiffs := debug_diff({1},{2}, intEq, intString);
  print(DiffAlgorithm.printDiffTerminalColor(intDiffs, intString));
  print("\n");
  intDiffs := debug_diff({1,2,3,4,5,6,7,8,9,10},{1,2,6,4,5,7,3,8,9,10}, intEq, intString);
  print(DiffAlgorithm.printDiffTerminalColor(intDiffs, intString));
  print("\n");
  strDiffs := debug_diff({"1","2","3"},{"1","2","3"}, stringEq, id);
  print(DiffAlgorithm.printDiffTerminalColor(strDiffs, id));
end TestDiffAlgorithm;

function debug_diff<T>
  input list<T> seq1;
  input list<T> seq2;
  input FunEquals equals;
  input ToString toString;
  output list<tuple<DiffAlgorithm.Diff,list<T>>> out;
  partial function FunEquals
    input T t1,t2;
    output Boolean b;
  end FunEquals;
  partial function ToString
    input T t;
    output String o;
  end ToString;
algorithm
  print("Calling diff(\n");
  print("  seq1={" + stringDelimitList(list(toString(e) for e in seq1), ", ") + "},\n");
  print("  seq2={" + stringDelimitList(list(toString(e) for e in seq2), ", ") + "}\n");
  print(")\n");
  out := DiffAlgorithm.diff(seq1, seq2, equals, isWhitespace, toString);
end debug_diff;
