// name: MergeComponents10
// keywords:
// status: correct
// teardown_command: rm MergeComponents10_merged_table.json
//

model A
  Real x;
  Real y;
end A;

model B
  A a;
end B;

model MergeComponents10
  B b1(a(x = 1.0), a(y = 2.0));
  B b2(a(x = 3.0), a(y = 3.0));
  annotation(__OpenModelica_commandLineOptions="-d=mergeComponents");
end MergeComponents10;

// Result:
// class MergeComponents10
//   Real $B1[1].a.x = 1.0;
//   Real $B1[1].a.y = 2.0;
//   Real $B1[2].a.x = 3.0;
//   Real $B1[2].a.y = 3.0;
// end MergeComponents10;
// endResult
