// name: DuplicateElements11
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model A
  Real x[3];
end A;

model B
  Real x[3];
end B;

model DuplicateElements11
  extends A(x = {1, 2, 3});
  extends B;
end DuplicateElements11;

// Result:
// Error processing file: DuplicateElements11.mo
// [flattening/modelica/scodeinst/DuplicateElements11.mo:9:3-9:12:writable] Notification: From here:
// [flattening/modelica/scodeinst/DuplicateElements11.mo:13:3-13:12:writable] Error: Duplicate elements (due to inherited elements) not identical:
//   first element is:  Real[3] x = {1, 2, 3}
//   second element is: Real[3] x
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
