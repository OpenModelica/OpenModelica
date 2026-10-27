// name:     InvalidInheritedExtends2
// keywords: extends invalid
// status:   incorrect
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
// [flattening/modelica/extends/InvalidInheritedExtends2.mo:22:3-22:12:writable] Notification: From here:
// [flattening/modelica/extends/InvalidInheritedExtends2.mo:10:3-10:16:writable] Error: Found other base class for extends B after instantiating extends.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
