// name: ExternalFunctionExplicit2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x[3];
  output Real y;
  external "C" y = ext(x, size(x, 1));
end f;

model ExternalFunctionExplicit2
  Real x;
algorithm
  x := f({1.0, 2.0, 3.0});
end ExternalFunctionExplicit2;

// Result:
// function f
//   input Real[3] x;
//   output Real y;
//
//   external "C" y = ext(x, size(x, 1));
// end f;
//
// class ExternalFunctionExplicit2
//   Real x;
// algorithm
//   x := f({1.0, 2.0, 3.0});
// end ExternalFunctionExplicit2;
// endResult
