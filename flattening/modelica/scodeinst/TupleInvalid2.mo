// name: TupleInvalid2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model TupleInvalid2
  Real x;
  Real y;
equation
  (x, y) = (1, 2);
end TupleInvalid2;

// Result:
// Error processing file: TupleInvalid2.mo
// [flattening/modelica/scodeinst/TupleInvalid2.mo:11:3-11:18:writable] Error: Tuple expressions may only occur on the left side of an assignment or equation with a single function call on the right side. Got the following expression: (1, 2).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
