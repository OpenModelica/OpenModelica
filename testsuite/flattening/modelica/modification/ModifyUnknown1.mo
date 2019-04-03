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
// Error: In modifier (b = 5), class or component b not found in <ModifyUnknown1>.
// Error: Error occurred while flattening model ModifyUnknown1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
