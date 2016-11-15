// name: conn1.mo
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
initial equation
  connect(c1, c2);
end A;

// Result:
// Error processing file: conn1.mo
// Failed to parse file: conn1.mo!
//
// [flattening/modelica/scodeinst/conn1.mo:15:3-15:18:writable] Error: Connect equations are not allowed in initial equation sections.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: conn1.mo!
//
// Execution failed!
// endResult
