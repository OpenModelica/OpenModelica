// name: DuplicateElements1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that duplicate elements are detected and reported.
//

model DuplicateElements1
  Real x;
  Real x;
end DuplicateElements1;

// Result:
// Error processing file: DuplicateElements1.mo
// [flattening/modelica/scodeinst/DuplicateElements1.mo:10:3-10:9:writable] Notification: From here:
// [flattening/modelica/scodeinst/DuplicateElements1.mo:11:3-11:9:writable] Error: An element with name x is already declared in this scope.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
