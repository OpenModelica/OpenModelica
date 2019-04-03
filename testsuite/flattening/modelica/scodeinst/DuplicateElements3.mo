// name: DuplicateElements3
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that duplicate elements are detected and reported.
//

model DuplicateElements3
  class x end x;
  package x end x;
end DuplicateElements3;

// Result:
// Error processing file: DuplicateElements3.mo
// [flattening/modelica/scodeinst/DuplicateElements3.mo:10:3-10:16:writable] Notification: From here:
// [flattening/modelica/scodeinst/DuplicateElements3.mo:11:3-11:18:writable] Error: An element with name x is already declared in this scope.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
