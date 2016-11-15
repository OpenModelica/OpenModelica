// name: conn5.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

connector C1
  Real x;
end C1;

connector C2
  C1 c;
  flow Real f;
end C2;

model A
  C2 c1, c2;
equation
  connect(c1.f, c2.c);
end A;

// Result:
// Error processing file: conn5.mo
// [flattening/modelica/scodeinst/conn5.mo:19:3-19:22:writable] Error: Illegal connection: component c1.f is not a connector.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
