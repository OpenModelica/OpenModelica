// name: ExternalFunctionInvalidArg1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

function f
  input Real x;
  output Real y;
  external y = f({1.0, 2.0, 3.0});
end f;

model ExternalFunctionInvalidArg1
  Real x;
algorithm
  x := f(1.0);
end ExternalFunctionInvalidArg1;

// Result:
// Error processing file: ExternalFunctionInvalidArg1.mo
// [flattening/modelica/scodeinst/ExternalFunctionInvalidArg1.mo:8:1-12:6:writable] Error: Expression {1.0, 2.0, 3.0} cannot be an external argument. Only identifiers, scalar constants, and size-expressions are allowed.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
