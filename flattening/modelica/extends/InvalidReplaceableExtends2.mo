// name:     InvalidReplaceableExtends2
// keywords: extends replaceable
// status:   incorrect
//
// Checks that an error is issued for replaceable base classes.
//

model InvalidReplaceableExtends2
  replaceable model M
    Real x;
  end M;

  extends M;
end InvalidReplaceableExtends2;

// Result:
// Error processing file: InvalidReplaceableExtends2.mo
// [InvalidReplaceableExtends2.mo:13:3-13:12:writable] Notification: From here:
// [InvalidReplaceableExtends2.mo:9:15-11:8:writable] Error: Base class M is replaceable.
// Error: Error occurred while flattening model InvalidReplaceableExtends2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
