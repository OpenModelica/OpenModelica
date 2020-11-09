// name:     DoubleClassDeclaration1.mo
// status:   incorrect
// cflags: -d=-newInst
//
// Checks that duplicate top-level classes are detected.
//

model M
end M;

model M
end M;

// Result:
// Error processing file: DoubleClassDeclaration1.mo
// Failed to parse file: DoubleClassDeclaration1.mo!
//
// [flattening/modelica/declarations/DoubleClassDeclaration1.mo:8:1-9:6:writable] Notification: From here:
// [flattening/modelica/declarations/DoubleClassDeclaration1.mo:11:1-12:6:writable] Error: An element with name M is already declared in this scope.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: DoubleClassDeclaration1.mo!
//
// Execution failed!
// endResult
