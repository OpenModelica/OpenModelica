// name:     ModifyUnknown1
// keywords: modification
// status:   incorrect
//
// Try to introduce a new member via modification.
//

class A
  Real a;
end A;

class ModifyUnknown1 = A(b = 5);

// Result:
// Error processing file: ModifyUnknown1.mo
// [flattening/modelica/modification/ModifyUnknown1.mo:12:26-12:31:writable] Error: Modified element b not found in class A.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
