// name: ConnectInvalidForm1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C c;
end A;

model B
  A a;
end B;

model ConnectInvalidForm1
  B b;
  C c;
equation
  connect(b.a.c, c);
end ConnectInvalidForm1;

// Result:
// Error processing file: ConnectInvalidForm1.mo
// [flattening/modelica/scodeinst/ConnectInvalidForm1.mo:24:3-24:20:writable] Error: b.a.c is not a valid form for a connector, connectors must be either c1.c2...cn or m.c (where c is a connector and m is a non-connector).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
