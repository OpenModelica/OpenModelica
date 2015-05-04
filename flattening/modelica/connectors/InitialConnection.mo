// name: InitialConnection
// keywords: initial equation connection
// status: incorrect
//
// Checks that it's illegal to have connect equation in initial equations.
//

model InitialConnection
  connector C
    Real e;
    flow Real f;
  end C;

  C c1, c2;
initial equation
  connect(c1, c2);
end InitialConnection;

// Result:
// Error processing file: InitialConnection.mo
// Failed to parse file: InitialConnection.mo!
//
// [flattening/modelica/connectors/InitialConnection.mo:16:3-16:18:writable] Error: Connect equations are not allowed in initial equation sections.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: InitialConnection.mo!
//
// Execution failed!
// endResult
