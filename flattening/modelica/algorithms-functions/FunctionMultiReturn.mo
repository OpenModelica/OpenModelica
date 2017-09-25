// name:     FunctionReturn
// keywords: function return
// status:   correct
//
// This tests return in function

function f
  input Real x;
  output Real y;
  output Real z;
algorithm
  y := x * 2;
  z := x * 3;
end f;

model FunctionMultiReturn
  Real x = f(3);
  Real y;
equation
  y = f(4);
end FunctionMultiReturn;

// Result:
// function f
//   input Real x;
//   output Real y;
//   output Real z;
// algorithm
//   y := 2.0 * x;
//   z := 3.0 * x;
// end f;
//
// class FunctionMultiReturn
//   Real x = 6.0;
//   Real y;
// equation
//   y = 8.0;
// end FunctionMultiReturn;
// endResult
