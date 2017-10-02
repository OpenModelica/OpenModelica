// name: TupleInvalid1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model TupleInvalid1
  Real x = (1, 2);
end TupleInvalid1;

// Result:
// Error processing file: TupleInvalid1.mo
// [flattening/modelica/scodeinst/TupleInvalid1.mo:8:3-8:18:writable] Error: Tuple expressions may only occur on the left side of an assignment or equation with a single function call on the right side. Got the following expression: (1, 2).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
