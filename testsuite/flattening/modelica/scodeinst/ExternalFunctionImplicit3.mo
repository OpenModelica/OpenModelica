// name: ExternalFunctionImplicit3
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x[3];
  input Real y[2, 4];
  output Real z;
  external;
end f;

model ExternalFunctionImplicit3
  Real x;
algorithm
  x := f({1, 2, 3}, {{1, 2, 3, 4}, {5, 6, 7, 8}});
end ExternalFunctionImplicit3;

// Result:
// function f
//   input Real[3] x;
//   input Real[2, 4] y;
//   output Real z;
//
//   external "C" z = f(x, size(x, 1), y, size(y, 1), size(y, 2));
// end f;
//
// class ExternalFunctionImplicit3
//   Real x;
// algorithm
//   x := f({1.0, 2.0, 3.0}, {{1.0, 2.0, 3.0, 4.0}, {5.0, 6.0, 7.0, 8.0}});
// end ExternalFunctionImplicit3;
// endResult
