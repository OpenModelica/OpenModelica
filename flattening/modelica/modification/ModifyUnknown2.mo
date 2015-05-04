// name:     ModifyUnknown2
// keywords: modification
// status:   incorrect
//
// Try to introduce a new member via modification.
//

class A
  Real a;
end A;

class ModifyUnknown2 = A(redeclare Real b = 5);
// Result:
// Error processing file: ModifyUnknown2.mo
// [flattening/modelica/modification/ModifyUnknown2.mo:12:26-12:46:writable] Error: Modified element b not found in class A.
// Error: Error occurred while flattening model ModifyUnknown2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
