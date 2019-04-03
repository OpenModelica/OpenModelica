// name: FunctionDerivativeMissingName1
// status: correct
// cflags: -d=newInst
//
//

function f1
  input Real x;
  input Real y;
  output Real z = x + y;
algorithm
  annotation(derivative(order = 1));
end f1;

model FunctionDerivativeMissingName1
  Real x = f1(time, time);
end FunctionDerivativeMissingName1;

// Result:
// function f1
//   input Real x;
//   input Real y;
//   output Real z = x + y;
// algorithm
// end f1;
//
// class FunctionDerivativeMissingName1
//   Real x = f1(time, time);
// end FunctionDerivativeMissingName1;
// [flattening/modelica/scodeinst/FunctionDerivativeMissingName1.mo:12:14-12:35:writable] Warning: Derivative annotation for function ‘f1‘ does not specify a derivative function.
//
// endResult
