// name: InnerOuterInvalidType2
// keywords:
// status: incorrect
//

model A
  outer model M = B;
  M m;
end A;

model B
  Real x;
end B;

model InnerOuterInvalidType2
  inner Real M;
  A a;
end InnerOuterInvalidType2;

// Result:
// Error processing file: InnerOuterInvalidType2.mo
// [flattening/modelica/scodeinst/InnerOuterInvalidType2.mo:7:9-7:20:writable] Notification: From here:
// [flattening/modelica/scodeinst/InnerOuterInvalidType2.mo:16:3-16:15:writable] Error: Found inner component M instead of expected class.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
