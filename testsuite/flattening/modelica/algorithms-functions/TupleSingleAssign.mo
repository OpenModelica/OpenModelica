// name:     TupleSingleAssign
// keywords: tuple single assign statement equation
// status:   correct
//
// Tests that tuple assignment to a single variable works correctly in both
// equations and algorithm sections.
//

function tuple_ret
  input Real dont_ceval_me;
  output Real A;
  output Real B;
  output Real C;
algorithm
  A := 1;
  B := 2;
  C := 3;
end tuple_ret;

model TupleSingleAssign
  Real a, b;
algorithm
  a := tuple_ret(time);
equation
  b = tuple_ret(time);
end TupleSingleAssign;

// Result:
// function tuple_ret
//   input Real dont_ceval_me;
//   output Real A;
//   output Real B;
//   output Real C;
// algorithm
//   A := 1.0;
//   B := 2.0;
//   C := 3.0;
// end tuple_ret;
//
// class TupleSingleAssign
//   Real a;
//   Real b;
// equation
//   (b, _, _) = tuple_ret(time);
// algorithm
//   a := tuple_ret(time)[1];
// end TupleSingleAssign;
// endResult
