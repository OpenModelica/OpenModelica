// name:     InvalidReplaceableExtends5
// keywords: extends replaceable
// status:   incorrect
//
// Checks that an error is issued if any part of the base class name is
// replaceable.
//

model InvalidReplaceableExtends5
  replaceable model A
    model B
      Real x;
    end B;
  end A;

  extends A.B;
end InvalidReplaceableExtends5;

// Result:
// Error processing file: InvalidReplaceableExtends5.mo
// [InvalidReplaceableExtends5.mo:16:3-16:14:writable] Notification: From here:
// [InvalidReplaceableExtends5.mo:10:15-14:8:writable] Error: Part A of base class A.B is replaceable.
// Error: Error occurred while flattening model InvalidReplaceableExtends5
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
