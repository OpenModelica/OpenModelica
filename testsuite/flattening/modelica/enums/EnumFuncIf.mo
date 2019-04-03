// name:     EnumRange
// keywords: enumeration enum range reduction
// status:   correct
// cflags: --condenseArrays=false
//
// Tests that enum dimensions are used properly when an if-expression containing
// a function call is expanded.
//

function f
  input Real x;
  output Boolean out;
algorithm
end f;

type E = enumeration(A, B, C);

model EnumFuncIf
  Real x[E];
  Real y;
equation
  x = if f(y) then zeros(size(E, 1)) else x / y;
end EnumFuncIf;

// Result:
// function f
//   input Real x;
//   output Boolean out;
// end f;
//
// class EnumFuncIf
//   Real x[E.A];
//   Real x[E.B];
//   Real x[E.C];
//   Real y;
// equation
//   x[E.A] = if f(y) then 0.0 else x[E.A] / y;
//   x[E.B] = if f(y) then 0.0 else x[E.B] / y;
//   x[E.C] = if f(y) then 0.0 else x[E.C] / y;
// end EnumFuncIf;
// endResult
