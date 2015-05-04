// name:     FunctionDefaultArgs2
// keywords: functions, default arguments, #2640
// status:   correct
//
// Tests default arguments in functions where the values are defined in the
// function scope.
//

function f
  input Real x;
  input Real y = 2 * x;
  input Real z = x / y;
  output Real o;
algorithm
  o := x+y+z;
end f;

model FunctionDefaultArgs2
  Real x = f(4);
end FunctionDefaultArgs2;

// Result:
// function f
//   input Real x;
//   input Real y = 2.0 * x;
//   input Real z = x / y;
//   output Real o;
// algorithm
//   o := x + y + z;
// end f;
//
// class FunctionDefaultArgs2
//   Real x = 12.5;
// end FunctionDefaultArgs2;
// endResult
