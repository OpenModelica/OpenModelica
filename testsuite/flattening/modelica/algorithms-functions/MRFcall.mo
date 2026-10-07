// name:     MultipleResultsFunction
// keywords: multiple results
// status:   correct
//
// Multipe results from a function
//


function MultipleResultsFunction
  input Real x;
  input Real y;
  output Real r1;
  output Real r2;
  output Real r3;
algorithm
  r1 := x + y;
  r2 := x * y;
  r3 := x - y;
end MultipleResultsFunction;

class MRFcall
  Real a, b, c;
equation
  (a, b, c) = MultipleResultsFunction(2.0, 1.0);
end MRFcall;

// Result:
// class MRFcall
//   Real a;
//   Real b;
//   Real c;
// equation
//   a = 3.0;
//   b = 2.0;
//   c = 1.0;
// end MRFcall;
// [flattening/modelica/algorithms-functions/MRFcall.mo:22:3-22:15:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/MRFcall.mo:24:3-24:48:writable] Warning: Equation sections are deprecated in class.
//
// endResult
