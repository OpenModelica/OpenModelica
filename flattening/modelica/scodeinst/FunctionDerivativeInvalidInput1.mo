// name: FunctionDerivativeInvalidInput1
// status: incorrect
// cflags: -d=newInst
//
//

function f1
  input Real x;
  input Real y;
  output Real z = x + y;
algorithm
  annotation(derivative(zeroDerivative = z) = f2);
end f1;

function f2
  input Real x;
  input Real y;
  input Real der_x;
  output Real z = 0;
end f2;

model FunctionDerivativeInvalidInput1
  Real x = f1(time, time);
end FunctionDerivativeInvalidInput1;

// Result:
// Error processing file: FunctionDerivativeInvalidInput1.mo
// [flattening/modelica/scodeinst/FunctionDerivativeInvalidInput1.mo:12:14-12:49:writable] Error: ‘z‘ is not an input of function ‘f1‘.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
