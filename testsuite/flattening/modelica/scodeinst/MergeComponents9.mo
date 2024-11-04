// name: MergeComponents9
// keywords:
// status: correct
// teardown_command: rm MergeComponents9_merged_table.json S1_merged_table.json
//

model M
  Real x;
equation
  x = 2*time;
end M;

model S1
  M m1;
  M m2;
end S1;

model MergeComponents9
  extends S1;
  annotation(__OpenModelica_commandLineOptions="-d=mergeComponents");
end MergeComponents9;

// Result:
// class MergeComponents9
//   Real $M1[1].x;
//   Real $M1[2].x;
// equation
//   $M1[1].x = 2.0 * time;
//   $M1[2].x = 2.0 * time;
// end MergeComponents9;
// endResult
