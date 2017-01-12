// name:     DoubleClassDeclaration2.mo
// status:   incorrect
//
// Checks that duplicate classes are detected.
//

model M
  model A
    Real x;
  end A;

  model A
    Real y;
  end A;

  A a;
end M;

// Result:
// Error processing file: DoubleClassDeclaration2.mo
// [flattening/modelica/declarations/DoubleClassDeclaration2.mo:8:3-10:8:writable] Notification: From here:
// [flattening/modelica/declarations/DoubleClassDeclaration2.mo:12:3-14:8:writable] Error: An element with name A is already declared in this scope.
// Error: Error occurred while flattening model M
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
