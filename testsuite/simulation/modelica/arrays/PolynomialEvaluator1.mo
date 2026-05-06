// name:     PolynomialEvaluator1
// keywords: dynamic array, for
// status:   correct
//
// Tests positional arguments, dynamic array sizes etc.
//
// Drmodelica: 9.2 called (p. 300)
//
function PolynomialEvaluator1
  input Real A[:]; // Array, size defined at function call time
  input Real x := 1.0; // Default value 1.0 for x
  output Real sum;
protected
  Real xpower;
algorithm
  sum := 0;
  xpower := 1;
  for i in 1:size(A, 1) loop
    sum := sum + A[i]*xpower;
    xpower := xpower*x;
  end for;
end PolynomialEvaluator1;

class PositionalCall
  Real p;
equation
  p = PolynomialEvaluator1({1,2,3,4},21);
end PositionalCall;


// function PolynomialEvaluator
// input Real A;
// input Real x;
// output Real sum;
// Real xpower;
// equation
//   x = 1.0;
// algorithm
//   sum := 0.0;
//   xpower := 1.0;
//   for i in 1:size(A,1) loop
//     sum := sum + A[i] * xpower;
//     xpower := xpower * x;
//   end for;
// end PolynomialEvaluator;
//
// class PositionalCall
// Real p;
// equation
//   p = 38410.0;
// end PositionalCall;
