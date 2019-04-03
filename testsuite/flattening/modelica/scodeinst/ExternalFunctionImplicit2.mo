// name: ExternalFunctionImplicit2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x;
  output Real y;
  output Real z;
  external;
end f;

model ExternalFunctionImplicit2
  Real x, y;
algorithm
  (x, y) := f(1.0);
end ExternalFunctionImplicit2;

// Result:
// function f
//   input Real x;
//   output Real y;
//   output Real z;
//
//   external "C" f(x, y, z);
// end f;
//
// class ExternalFunctionImplicit2
//   Real x;
//   Real y;
// algorithm
//   (x, y) := f(1.0);
// end ExternalFunctionImplicit2;
// endResult
