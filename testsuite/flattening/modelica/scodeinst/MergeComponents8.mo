// name: MergeComponents8
// keywords:
// status: correct
// teardown_command: rm MergeComponents8_merged_table.json
//

model A
  parameter Real p = 1;
  input Real u;
  Real y;
  Real x;
equation
  der(x) = -p*x+u;
  y = 2*p*x;
end A;

model MergeComponents8
  parameter Real n1 = 1.0;
  parameter Real n2 = 2.0;
  A a1(p = n1);
  A a2(p = n2);
  annotation(__OpenModelica_commandLineOptions="-d=mergeComponents,-nfScalarize");
end MergeComponents8;

// Result:
// class MergeComponents8
//   parameter Real[2] $A1.p = {$Real2[1], $Real2[2]};
//   Real[2] $A1.u;
//   Real[2] $A1.y;
//   Real[2] $A1.x;
//   parameter Real[2] $Real2 = {1.0, 2.0};
// equation
//   for $i1 in 1:2 loop
//     der($A1[$i1].x) = $A1[$i1].u - $A1[$i1].p * $A1[$i1].x;
//   end for;
//   for $i1 in 1:2 loop
//     $A1[$i1].y = 2.0 * $A1[$i1].p * $A1[$i1].x;
//   end for;
// end MergeComponents8;
// endResult
