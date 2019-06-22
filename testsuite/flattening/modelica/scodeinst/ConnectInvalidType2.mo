// name: ConnectInvalidType2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

connector C1
  Real e;
  flow Real f;
end C1;

connector C2
  Real e2;
  flow Real f2;
end C2;

model ConnectInvalidType2
  C1 c1;
  C2 c2;
equation
  connect(c1, c2);
end ConnectInvalidType2;

// Result:
// Error processing file: ConnectInvalidType2.mo
// [flattening/modelica/scodeinst/ConnectInvalidType2.mo:21:3-21:18:writable] Error: The type of variables c1 and c2
// are inconsistent in connect equations.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
