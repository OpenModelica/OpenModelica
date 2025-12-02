// name: TupleInvalid3
// keywords:
// status: incorrect
//

model TupleInvalid3
  Real x;
  Real y;
equation
  (x, y) = {1, 2};
end TupleInvalid3;

// Result:
// Error processing file: TupleInvalid3.mo
// [flattening/modelica/scodeinst/TupleInvalid3.mo:10:3-10:18:writable] Error: Type mismatch in equation (x, y) = {1, 2} of type (Real, Real) = Integer[2].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
