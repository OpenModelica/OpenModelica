// name: ExternalFunctionInvalidArg2
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

function f
  input Real x[:];
  input Integer n;
  output Real y;
  external y = f(size(x, n));
end f;

model ExternalFunctionInvalidArg2
  Real x;
  Integer n;
algorithm
  x := f({1, 2, 3}, n);
end ExternalFunctionInvalidArg2;

// Result:
// Error processing file: ExternalFunctionInvalidArg2.mo
// [flattening/modelica/scodeinst/ExternalFunctionInvalidArg2.mo:8:1-13:6:writable] Error: Invalid external argument 'size(x, n)', the dimension index must be a constant expression.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
