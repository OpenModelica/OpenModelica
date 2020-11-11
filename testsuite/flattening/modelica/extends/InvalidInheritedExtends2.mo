// name:     InvalidInheritedExtends2
// keywords: extends invalid
// status:   incorrect
// cflags: -d=-newInst
//
// This test tests that the compiler issues an appropriate error if the first
// part of an extends is inherited from multiple sources.
//

model A
  model B end B;
end A;

model C
  model B end B;
end C;

model B end B;

class InvalidInheritedExtends2
  extends A;
  extends C;
  extends B;
end InvalidInheritedExtends2;

// Result:
// Error processing file: InvalidInheritedExtends2.mo
// [flattening/modelica/extends/InvalidInheritedExtends2.mo:23:3-23:12:writable] Error: The base class name B was found in one or more base classes:
// [flattening/modelica/extends/InvalidInheritedExtends2.mo:11:3-11:16:writable] Notification: From here:
// [flattening/modelica/extends/InvalidInheritedExtends2.mo:21:3-21:12:writable] Error: B was found in base class A.
// [flattening/modelica/extends/InvalidInheritedExtends2.mo:15:3-15:16:writable] Notification: From here:
// [flattening/modelica/extends/InvalidInheritedExtends2.mo:22:3-22:12:writable] Error: B was found in base class C.
// Error: Error occurred while flattening model InvalidInheritedExtends2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
