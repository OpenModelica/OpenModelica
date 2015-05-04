// name:     InvalidComponentExtends2
// keywords: extends invalid
// status:   incorrect
//
// This test tests that the compiler issues an error if any part of the base
// class name is a component instead of a class.
//

model M
  A a;

  model A
    model B end B;
  end A;
end M;

model InvalidComponentExtends2
  extends M.a.B;
end InvalidComponentExtends2;

// Result:
// Error processing file: InvalidComponentExtends2.mo
// [flattening/modelica/extends/InvalidComponentExtends2.mo:10:3-10:6:writable] Notification: From here:
// [flattening/modelica/extends/InvalidComponentExtends2.mo:18:3-18:16:writable] Error: Part a of base class name M.a.B is not a class.
// Error: Error occurred while flattening model InvalidComponentExtends2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
