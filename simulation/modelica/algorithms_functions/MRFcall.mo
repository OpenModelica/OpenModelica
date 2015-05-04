// name:     MultipleResultsFunction
// keywords: multiple results
// status:   correct
//
// Multipe results from a function
//
// Drmodelica: 9.2 Multiple Results (p. 302)
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
end MRFcall;function MultipleResultsFunction
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

// class MRFcall
// Real a;
// Real b;
// Real c;
// equation
//   (a,b,c) = (3.0,2.0,1.0);
// end MRFcall;

