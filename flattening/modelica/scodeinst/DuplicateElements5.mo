// name: DuplicateElements5.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that duplicate elements are detected and reported.
//

model A
  Real x;
end A;

model DuplicateElements5
  extends A;
  Integer x;
end DuplicateElements5;

// Result:
// Error processing file: DuplicateElements4.mo
// [flattening/modelica/scodeinst/DuplicateElements4.mo:10:3-10:16:writable] Notification: From here:
// [flattening/modelica/scodeinst/DuplicateElements4.mo:11:3-11:16:writable] Error: An element with name x is already declared in this scope.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
