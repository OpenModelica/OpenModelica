// name:     InvalidReplaceableExtends4
// keywords: extends replaceable
// status:   incorrect
//
// Checks that an error is issued if any part of the base class name is
// replaceable.
//

model A
  replaceable model B
    model C
      Real x;
    end C;
  end B;
end A;

model InvalidReplaceableExtends4
  extends A.B.C;
end InvalidReplaceableExtends4;

// Result:
// Error processing file: InvalidReplaceableExtends4.mo
// [flattening/modelica/extends/InvalidReplaceableExtends4.mo:10:15-14:8:writable] Notification: From here:
// [flattening/modelica/extends/InvalidReplaceableExtends4.mo:18:3-18:16:writable] Error: Class 'B' in 'extends A.<B>.C' is replaceable, the base class name must be transitively non-replaceable.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
