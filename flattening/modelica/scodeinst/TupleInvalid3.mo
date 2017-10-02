// name: TupleInvalid3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model TupleInvalid3
  Real x;
  Real y;
equation
  (x, y) = {1, 2};
end TupleInvalid3;

// Result:
// Error processing file: TupleInvalid3.mo
// [flattening/modelica/scodeinst/TupleInvalid3.mo:11:3-11:18:writable] Error: Type mismatch in equation (x, y) = {1, 2} of type (Real, Real) = Integer[2].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
