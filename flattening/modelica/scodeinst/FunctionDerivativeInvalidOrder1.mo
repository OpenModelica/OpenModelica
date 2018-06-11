// name: FunctionDerivativeInvalidOrder1
// status: incorrect
// cflags: -d=newInst
//
//

function f1
  input Real x;
  input Real y;
  output Real z = x + y;
algorithm
  annotation(derivative(order = z) = f2);
end f1;

function f2
  input Real x;
  input Real y;
  input Real der_x;
  output Real z = 0;
end f2;

model FunctionDerivativeInvalidOrder1
  Real x = f1(time, time);
end FunctionDerivativeInvalidOrder1;

// Result:
// Error processing file: FunctionDerivativeInvalidOrder1.mo
// [flattening/modelica/scodeinst/FunctionDerivativeInvalidOrder1.mo:7:1-13:7:writable] Error: Type mismatch in binding order = z, expected subtype of Integer, got type Real.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
