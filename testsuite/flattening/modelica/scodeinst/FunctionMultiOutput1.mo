// name: FunctionMultiOutput1
// keywords:
// status: correct
//

function f
  input Real x;
  output Real a = x * 2;
  output Real b = x * 3;
  output Real c = x * 4;
end f;

model FunctionMultiOutput1
  Real x, y, z;
algorithm
  (x, y, z) := f(2.0);
end FunctionMultiOutput1;

// Result:
// class FunctionMultiOutput1
//   Real x;
//   Real y;
//   Real z;
// algorithm
//   x := 4.0;
//   y := 6.0;
//   z := 8.0;
// end FunctionMultiOutput1;
// endResult
