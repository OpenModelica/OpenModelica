// status: incorrect
// Based on ticket:4007

model TupleError
  Real a = (0,25)*(0,25);
end TupleError;
// Result:
// Error processing file: TupleError.mo
// [flattening/modelica/algorithms-functions/TupleError.mo:5:3-5:25:writable] Error: Tuple expressions may only occur on the left side of an assignment or equation with a single function call on the right side. Got the following expression: (0, 25).
// Error: Error occurred while flattening model TupleError
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
