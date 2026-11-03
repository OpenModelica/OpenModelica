// name:     FunctionEvalSlice
// keywords: function slice assignment
// status:   correct
//
// Checks that slice assignments in functions are constant evaluated correctly.
//

function fn
  output Real r[10];
algorithm
  r[1:10] := fill(2.0, 10);
  r[1:2:10] := fill(3.0, 5);
  r[2:4:6] := fill(4.0, 2);
end fn;

model FunctionEvalSlice
  Real r[10];
equation
  r = fn();
end FunctionEvalSlice;

// Result:
// class FunctionEvalSlice
//   Real r[1];
//   Real r[2];
//   Real r[3];
//   Real r[4];
//   Real r[5];
//   Real r[6];
//   Real r[7];
//   Real r[8];
//   Real r[9];
//   Real r[10];
// equation
//   r[1] = 3.0;
//   r[2] = 4.0;
//   r[3] = 3.0;
//   r[4] = 2.0;
//   r[5] = 3.0;
//   r[6] = 4.0;
//   r[7] = 3.0;
//   r[8] = 2.0;
//   r[9] = 3.0;
//   r[10] = 2.0;
// end FunctionEvalSlice;
// endResult
