// name: SumScalar
// keywords: sum scalar
// status: incorrect
//
// Tests that sum(scalar) is invalid.
//

model SumScalar
  Real x;
equation
  x = sum(x);
end SumScalar;

// Result:
// Error processing file: SumScalar.mo
// [flattening/modelica/built-in-functions/SumScalar.mo:11:3-11:13:writable] Error: In sum(x), the expression is of type Real, but is required to be of builtin array type (of any number of dimensions).
// Error: Error occurred while flattening model SumScalar
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
