// name: MergeComponents11
// keywords:
// status: correct
// teardown_command: rm MergeComponents11_merged_table.json
//
// The inputs a function inherits are not merged into an array, which would
// break named arguments.
//

record R
  Real x;
end R;

function f
  input R a;
  input R b;
  output Real y;
algorithm
  y := a.x - b.x;
end f;

partial function Inputs
  input R a;
  input R b;
end Inputs;

function g
  extends Inputs;
  output Real y;
algorithm
  y := a.x - b.x;
end g;

model MergeComponents11
  Real y1 = f(b = R(2.0), a = R(1.0));
  Real y2 = g(b = R(2.0), a = R(1.0));
  annotation(__OpenModelica_commandLineOptions="-d=mergeComponents,-nfScalarize");
end MergeComponents11;

// Result:
// class MergeComponents11
//   Real[2] $Real1 = {-1.0, -1.0};
// end MergeComponents11;
// endResult
