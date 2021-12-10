// name:     FuncBuiltinPure1
// keywords:
// status:   correct
// cflags:   -d=newInst
//
//

impure function f
  input Real x;
  output Real y = x;
end f;

function f2
  input Real x;
  output Real y;
algorithm
  y := pure(f(x));
end f2;

model FuncBuiltinPure1
  Real x = f2(time);
  Real y = pure(f(time));
end FuncBuiltinPure1;

// Result:
// impure function f
//   input Real x;
//   output Real y = x;
// end f;
//
// function f2
//   input Real x;
//   output Real y;
// algorithm
//   y := f(x);
// end f2;
//
// class FuncBuiltinPure1
//   Real x = f2(time);
//   Real y = f(time);
// end FuncBuiltinPure1;
// endResult
