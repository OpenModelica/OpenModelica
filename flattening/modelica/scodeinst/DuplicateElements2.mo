// name: DuplicateElements2
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that duplicate elements are detected and reported.
//

model DuplicateElements2
  Real x;
  class x end x;
end DuplicateElements2;

// Result:
// Error processing file: DuplicateElements2.mo
// [flattening/modelica/scodeinst/DuplicateElements2.mo:11:3-11:16:writable] Notification: From here:
// [flattening/modelica/scodeinst/DuplicateElements2.mo:10:3-10:9:writable] Error: An element with name x is already declared in this scope.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
