// name: FuncDefaultArg6
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x;
  input Real r;
  output Real o = x+r;
end f;

model FuncDefaultArg6
  Real x = 2.0;
  function g = f(r=x);
  Real y = g(1.0);
end FuncDefaultArg6;

// Result:
// function FuncDefaultArg6.g
//   input Real x;
//   input Real r = x;
//   output Real o = x + r;
// end FuncDefaultArg6.g;
//
// class FuncDefaultArg6
//   Real x = 2.0;
//   Real y = FuncDefaultArg6.g(1.0, x);
// end FuncDefaultArg6;
// endResult
