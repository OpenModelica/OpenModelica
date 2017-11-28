// name: ExternalFunctionExplicit1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x;
  output Real y;
  external "C" y = ext(x);
end f;

model ExternalFunctionExplicit1
  Real x;
algorithm
  x := f(1.0);
end ExternalFunctionExplicit1;

// Result:
// function f
//   input Real x;
//   output Real y;
//
//   external "C" y = ext(x);
// end f;
//
// class ExternalFunctionExplicit1
//   Real x;
// algorithm
//   x := f(1.0);
// end ExternalFunctionExplicit1;
// endResult
