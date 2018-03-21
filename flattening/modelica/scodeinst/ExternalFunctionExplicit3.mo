// name: ExternalFunctionExplicit3
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x[:];
  output Real y;
  external "C" y = ext(x, size(x, 1));
end f;

model ExternalFunctionExplicit3
  Real x;
algorithm
  x := f({1.0, 2.0, 3.0});
end ExternalFunctionExplicit3;

// Result:
// function f
//   input Real[:] x;
//   output Real y;
//
//   external "C" y = ext(x, size(x, 1));
// end f;
//
// class ExternalFunctionExplicit3
//   Real x;
// algorithm
//   x := f({1.0, 2.0, 3.0});
// end ExternalFunctionExplicit3;
// endResult
