// name: ArraySizeFromFunc
// keywords: array, wholedim, function
// status: correct
//
// Tests determination of array size from function call with parameter as
// argument.
//

function f
  input Integer n;
  output Real x[n];
algorithm
  x := ones(n);
end f;

model ArraySizeFromFunc
  parameter Integer n = 5;
  parameter Real x[:] = f(n);
end ArraySizeFromFunc;

// Result:
// function f
//   input Integer n;
//   output Real[n] x;
// algorithm
//   x := fill(1.0, n);
// end f;
//
// class ArraySizeFromFunc
//   parameter Integer n = 5;
//   parameter Real x[1] = 1.0;
//   parameter Real x[2] = 1.0;
//   parameter Real x[3] = 1.0;
//   parameter Real x[4] = 1.0;
//   parameter Real x[5] = 1.0;
// end ArraySizeFromFunc;
// endResult
