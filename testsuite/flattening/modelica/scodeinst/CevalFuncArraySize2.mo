// name: CevalFuncArraySize2
// keywords:
// status: correct
//
// A call that cannot be evaluated because of arrays of different sizes is
// kept (#18477).
//

function f
  input Real a[:];
  input Real b[:];
  output Real y;
algorithm
  y := (a - b)[2];
end f;

model CevalFuncArraySize2
  Real x = f({1, 2}, {1, 2, 3});
end CevalFuncArraySize2;

// Result:
// function f
//   input Real[:] a;
//   input Real[:] b;
//   output Real y;
// algorithm
//   y := a[2] - b[2];
// end f;
//
// class CevalFuncArraySize2
//   Real x = f({1.0, 2.0}, {1.0, 2.0, 3.0});
// end CevalFuncArraySize2;
// endResult
