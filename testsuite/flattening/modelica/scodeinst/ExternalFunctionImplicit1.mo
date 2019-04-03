// name: ExternalFunctionImplict1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x;
  output Real y;
  external;
end f;

model ExternalFunctionImplict1
  Real x;
algorithm
  x := f(1.0);
end ExternalFunctionImplict1;

// Result:
// function f
//   input Real x;
//   output Real y;
//
//   external "C" y = f(x);
// end f;
//
// class ExternalFunctionImplict1
//   Real x;
// algorithm
//   x := f(1.0);
// end ExternalFunctionImplict1;
// endResult
