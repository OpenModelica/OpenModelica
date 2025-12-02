// name: MergeComponents5
// keywords:
// status: correct
// teardown_command: rm MergeComponents5_merged_table.json
//

model A
  Real x;
  Real y;
end A;

type A3 = A[3](x = {1, 2, 3});

model MergeComponents5
  A3 a1(y = {1, 2, 3});
  A3 a2(y = {4, 5, 6});
  A3 a3(y = {7, 8, 9});
  annotation(__OpenModelica_commandLineOptions="-d=mergeComponents,-nfScalarize");
end MergeComponents5;

// Result:
// class MergeComponents5
//   Real[3, 3] $A31.x = fill({1.0, 2.0, 3.0}, 3);
//   Real[3, 3] $A31.y = {{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}};
// end MergeComponents5;
// endResult
