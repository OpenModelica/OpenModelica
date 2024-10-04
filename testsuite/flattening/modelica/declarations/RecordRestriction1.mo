// name: RecordRestriction1
// keywords:
// status: incorrect
//

record R
  protected Real x;
end R;

class RecordRestriction1
  R r;
end RecordRestriction1;

// Result:
// Error processing file: RecordRestriction1.mo
// [flattening/modelica/declarations/RecordRestriction1.mo:7:13-7:19:writable] Error: Protected sections are not allowed in record.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
