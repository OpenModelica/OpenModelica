// name: FuncDefaultArg7
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x;
  output Real y;
algorithm
  y := x + 2;
end f;

partial model Base
  replaceable partial function func = f;
end Base;

model FuncDefaultArg7
  extends Base(redeclare final function func = f(x = x));
  parameter Real x = 5;
  Real y = func();
end FuncDefaultArg7;

// Result:
// function FuncDefaultArg7.func
//   input Real x = 5.0;
//   output Real y;
// algorithm
//   y := x + 2.0;
// end FuncDefaultArg7.func;
//
// class FuncDefaultArg7
//   parameter Real x = 5.0;
//   Real y = FuncDefaultArg7.func(x);
// end FuncDefaultArg7;
// endResult
