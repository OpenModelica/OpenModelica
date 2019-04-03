// name:     IfExpression1
// keywords: if expression
// status:   correct
//
// Checks that if-expressions with arrays of different size is handled correctly
// in functions.
//

function f
  input Integer n;
  output Real x[:] = if n == 1 then {1} else {1, 2};
end f;

model M
  Real x[:] = f(2);
end M;

// Result:
// function f
//   input Integer n;
//   output Real[:] x = if n == 1 then {1.0} else {1.0, 2.0};
// end f;
//
// class M
//   Real x[1];
//   Real x[2];
// equation
//   x = {1.0, 2.0};
// end M;
// endResult
