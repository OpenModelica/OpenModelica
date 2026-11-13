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
// [flattening/modelica/built-in-functions/SumScalar.mo:11:3-11:13:writable] Error: Type mismatch for positional argument 1 in sum(a=x). The argument has type:
//   Real
// expected type:
//   Array
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
