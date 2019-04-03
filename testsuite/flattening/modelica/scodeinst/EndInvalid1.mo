// name: EndInvalid1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model EndInvalid1
  Real x;
equation
  x = end;
end EndInvalid1;

// Result:
// Error processing file: EndInvalid1.mo
// [flattening/modelica/scodeinst/EndInvalid1.mo:11:3-11:10:writable] Error: 'end' can not be used outside array subscripts.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
