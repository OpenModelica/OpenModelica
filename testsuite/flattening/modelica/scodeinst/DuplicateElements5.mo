// name: DuplicateElements5
// keywords:
// status: incorrect
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
// Error processing file: DuplicateElements5.mo
// [flattening/modelica/scodeinst/DuplicateElements5.mo:9:3-9:9:writable] Notification: From here:
// [flattening/modelica/scodeinst/DuplicateElements5.mo:14:3-14:12:writable] Error: Duplicate elements (due to inherited elements) not identical:
//   first element is:  Real x
//   second element is: Integer x
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
