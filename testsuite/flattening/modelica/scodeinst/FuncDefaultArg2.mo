// name: FuncDefaultArg2
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that default arguments are replaced with the correct expression in the
// function call.
// 

function f
  input Real u1;
  input Real u2 = u1;
  output Real y;
algorithm
  y := u1 + u2;
end f;

model FuncDefaultArg2
  input Real a(start = 1);
  output Real b;
equation
  b = f(a);
end FuncDefaultArg2;

// Result:
// function f
//   input Real u1;
//   input Real u2 = u1;
//   output Real y;
// algorithm
//   y := u1 + u2;
// end f;
//
// class FuncDefaultArg2
//   input Real a(start = 1.0);
//   output Real b;
// equation
//   b = f(a, a);
// end FuncDefaultArg2;
// endResult
