// name:     InvalidReplaceableExtends3
// keywords: extends replaceable
// status:   incorrect
//
// Checks that an error is issued for replaceable base classes.
//

model A
  replaceable model B
    Real x;
  end B;
end A;

model InvalidReplaceableExtends3
  extends A.B;
end InvalidReplaceableExtends3;

// Result:
// Error processing file: InvalidReplaceableExtends3.mo
// [InvalidReplaceableExtends3.mo:15:3-15:14:writable] Notification: From here:
// [InvalidReplaceableExtends3.mo:9:15-11:8:writable] Error: Part B of base class A.B is replaceable.
// Error: Error occurred while flattening model InvalidReplaceableExtends3
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
