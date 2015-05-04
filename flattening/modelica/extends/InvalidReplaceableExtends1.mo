// name:     InvalidReplaceableExtends1
// keywords: extends replaceable
// status:   incorrect
//
// Checks that an error is issued for replaceable base classes.
//

model InvalidReplaceableExtends1
  replaceable model M end M;

  extends M;
end InvalidReplaceableExtends1;

// Result:
// Error processing file: InvalidReplaceableExtends1.mo
// [InvalidReplaceableExtends1.mo:11:3-11:12:writable] Notification: From here:
// [InvalidReplaceableExtends1.mo:9:15-9:28:writable] Error: Base class M is replaceable.
// Error: Error occurred while flattening model InvalidReplaceableExtends1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
