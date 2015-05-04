// name:     InvalidComponentExtends1
// keywords: extends invalid
// status:   incorrect
//
// This test tests that the compiler issues an error if any part of the base
// class name is a component instead of a class.
//

model M
  model A
    Real x;
  end A;
end M;

model InvalidComponentExtends1
  extends m.A;
  M m;
end InvalidComponentExtends1;

// Result:
// Error processing file: InvalidComponentExtends1.mo
// [flattening/modelica/extends/InvalidComponentExtends1.mo:17:3-17:6:writable] Notification: From here:
// [flattening/modelica/extends/InvalidComponentExtends1.mo:16:3-16:14:writable] Error: Part m of base class name m.A is not a class.
// Error: Error occurred while flattening model InvalidComponentExtends1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
