// name: InnerOuterInvalidType1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  outer Real x;
end A;

model InnerOuterInvalidType1
  inner model x = A;
  A a;
end InnerOuterInvalidType1;

// Result:
// Error processing file: InnerOuterInvalidType1.mo
// [flattening/modelica/scodeinst/InnerOuterInvalidType1.mo:8:3-8:15:writable] Notification: From here:
// [flattening/modelica/scodeinst/InnerOuterInvalidType1.mo:12:9-12:20:writable] Error: Found inner class x instead of expected component.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
