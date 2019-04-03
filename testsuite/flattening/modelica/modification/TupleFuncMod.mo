// name:     TupleFuncMod
// keywords: #4521
// status:   correct
//
// Tests that functions with multiple outputs can be used as modifiers.
//

function f
  input Integer n;
  input Real x[n];
  output Real z1[n];
  output Real z2;
algorithm
  for i in 1:n loop
    z1[i] := x[i];
  end for;
  z2 := 2 * x[1];
end f;

model TupleFuncMod
  Real Z2[2] = f(2, {1.0, 2.0});
end TupleFuncMod;

// Result:
// function f
//   input Integer n;
//   input Real[n] x;
//   output Real[n] z1;
//   output Real z2;
// algorithm
//   for i in 1:n loop
//     z1[i] := x[i];
//   end for;
//   z2 := 2.0 * x[1];
// end f;
//
// class TupleFuncMod
//   Real Z2[1];
//   Real Z2[2];
// equation
//   Z2 = {1.0, 2.0};
// end TupleFuncMod;
// endResult
