// name: conn2.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

model A
  connector C
    Real e;
    flow Real f;
  end C;

  C c1, c2;
algorithm
  connect(c1, c2);
end A;

// Result:
// Error processing file: conn2.mo
// Failed to parse file: conn2.mo!
//
// [flattening/modelica/scodeinst/conn2.mo:15:3-15:9:writable] Error: No viable alternative near token: connect
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: conn2.mo!
//
// Execution failed!
// endResult
