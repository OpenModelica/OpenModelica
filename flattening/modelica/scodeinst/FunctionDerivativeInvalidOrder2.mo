// name: FunctionDerivativeInvalidOrder2
// status: incorrect
// cflags: -d=newInst
//
//

function f1
  input Real x;
  input Real y;
  output Integer z = integer(x + y);
algorithm
  annotation(derivative(order = z) = f2);
end f1;

function f2
  input Real x;
  input Real y;
  input Real der_x;
  output Real z = 0;
end f2;

model FunctionDerivativeInvalidOrder2
  Real x = f1(time, time);
end FunctionDerivativeInvalidOrder2;

// Result:
// Error processing file: FunctionDerivativeInvalidOrder2.mo
// [flattening/modelica/scodeinst/FunctionDerivativeInvalidOrder2.mo:7:1-13:7:writable] Error: Component order of variability constant has binding z of higher variability discrete.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
