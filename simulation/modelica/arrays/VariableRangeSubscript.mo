// name:     VariableRangeSubscript
// keywords: array range subscript bug2192
// status:   correct
//
// Tests code generation for a range with variable length used as a subscript.
//

model VariableRangeSubscript
  Integer a[3];
  Real b[3];
  Real c[2];
  Integer n;
equation
  n = 2;
algorithm
  a := {1, 2, 3};
  b := {1.1, 2.1, 3.1};
  c := b[a[1:n]];
end VariableRangeSubscript;

// Result:
// class VariableRangeSubscript
//   Integer a[1];
//   Integer a[2];
//   Integer a[3];
//   Real b[1];
//   Real b[2];
//   Real b[3];
//   Real c[1];
//   Real c[2];
//   Integer n;
// equation
//   n = 2;
// algorithm
//   a := {1, 2, 3};
//   b := {1.1, 2.1, 3.1};
//   c := b[a[1:n]];
// end VariableRangeSubscript;
// endResult
