// name:     PolynomialEvaluator
// keywords: dynamic array, for
// status:   correct
//
// Tests named arguments, dynamic array sizes etc.
//
// Drmodelica: 9.2 called (p. 300)
//


function PolynomialEvaluator2
  input Real A[:]; // Array, size defined at function call time
  input Real x = 1.0; // Default value 1.0 for x
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
end PolynomialEvaluator2;

class NamedCall
  Real p;
equation
  p = PolynomialEvaluator2(A = {1, 2, 3, 4}, x = 21);
end NamedCall;

// Result:
// function PolynomialEvaluator2
//   input Real[:] A;
//   input Real x = 1.0;
//   output Real sum;
//   protected Real xpower;
// algorithm
//   sum := 0.0;
//   xpower := 1.0;
//   for i in 1:size(A, 1) loop
//     sum := sum + A[i] * xpower;
//     xpower := xpower * x;
//   end for;
// end PolynomialEvaluator2;
//
// class NamedCall
//   Real p;
// equation
//   p = 38410.0;
// end NamedCall;
// endResult
