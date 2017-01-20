// name: conn4.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C c1, c2;
equation
  connect(C, c2);
end A;

// Result:
// Error processing file: conn4.mo
// [flattening/modelica/scodeinst/conn4.mo:15:3-15:17:writable] Error: Expected C to be a component, but found class instead.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
