// name: ConnectInitial
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that connect isn't allowed in an initial equation.
//

model ConnectInitial
  connector C
    Real e;
    flow Real f;
  end C;

  C c1, c2;
initial equation
  connect(c1, c2);
end ConnectInitial;

// Result:
// Error processing file: ConnectInitial.mo
// Failed to parse file: ConnectInitial.mo!
//
// [flattening/modelica/scodeinst/ConnectInitial.mo:17:3-17:18:writable] Error: Connect equations are not allowed in initial equation sections.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: ConnectInitial.mo!
//
// Execution failed!
// endResult
