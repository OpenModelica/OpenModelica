// name: RecordRestriction2
// keywords:
// status: incorrect
//

record R
  Real x;
equation
  x = 0;
end R;

class RecordRestriction2
  R r;
end RecordRestriction2;

// Result:
// Error processing file: RecordRestriction2.mo
// [flattening/modelica/declarations/RecordRestriction2.mo:9:3-9:8:writable] Error: Equations are not allowed in record.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
