// name: ExternalFunctionImplicit4
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x;
  output Real y[3];
  external;
end f;

model ExternalFunctionImplicit4
  Real y[3];
algorithm
  y := f(1.0);
end ExternalFunctionImplicit4;

// Result:
// function f
//   input Real x;
//   output Real[3] y;
//
//   external "C" f(x, y, size(y, 1));
// end f;
//
// class ExternalFunctionImplicit4
//   Real y[1];
//   Real y[2];
//   Real y[3];
// algorithm
//   y := f(1.0);
// end ExternalFunctionImplicit4;
// [flattening/modelica/scodeinst/ExternalFunctionImplicit4.mo:8:1-12:6:writable] Warning: An external declaration with a single output without explicit mapping is defined as having the output as the lhs, but language C does not support this for array variables. OpenModelica will put the output as an input (as is done when there is more than 1 output), but this is not according to the Modelica Specification. Use an explicit mapping instead of the implicit one to suppress this warning.
//
// endResult
