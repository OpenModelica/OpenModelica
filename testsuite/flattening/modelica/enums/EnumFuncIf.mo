// name:     EnumRange
// keywords: enumeration enum range reduction
// status:   correct
//
// Tests that enum dimensions are used properly when an if-expression containing
// a function call is expanded.
//

function f
  input Real x;
  output Boolean out;
algorithm
  out := x > 0;
end f;

type E = enumeration(A, B, C);

model EnumFuncIf
  Real x[E];
  Real y;
equation
  x = if f(y) then {0.0 for e in E} else x / y;
end EnumFuncIf;

// Result:
// function f
//   input Real x;
//   output Boolean out;
// algorithm
//   out := x > 0.0;
// end f;
//
// class EnumFuncIf
//   Real x[E.A];
//   Real x[E.B];
//   Real x[E.C];
//   Real y;
// equation
//   x = if f(y) then array(0.0 for e in {E.A, E.B, E.C}) else {x[E.A] / y, x[E.B] / y, x[E.C] / y};
// end EnumFuncIf;
// endResult
