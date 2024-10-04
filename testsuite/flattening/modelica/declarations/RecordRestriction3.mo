// name: RecordRestriction3
// keywords:
// status: incorrect
//

record R
  Real x;
algorithm
  x := 0;
end R;

class RecordRestriction3
  R r;
end RecordRestriction3;

// Result:
// Error processing file: RecordRestriction3.mo
// [flattening/modelica/declarations/RecordRestriction3.mo:9:3-9:9:writable] Error: Algorithm sections are not allowed in record.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
