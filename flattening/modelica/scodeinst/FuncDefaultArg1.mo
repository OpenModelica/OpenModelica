// name: FuncDefaultArg1
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that it's possible to use a function where only a 'middle' function
// parameter has a default argument.
// 

function f
  input Real x;
  input Real y = 1.0;
  input Real z;
  output Real w = x + y + z;
end f;

model FuncDefaultArg1
  Real x = f(1.0, 2.0, 3.0);
  Real y = f(4.0, z = 2.0);
end FuncDefaultArg1;

// Result:
// class FuncDefaultArg1
//   Real x = 6.0;
//   Real y = 7.0;
// end FuncDefaultArg1;
// endResult
