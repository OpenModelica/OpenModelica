// name: ConnectAlgorithm
// keywords:
// status: incorrect
//
// Checks that connect isn't allowed in an algorithm section.
//

model ConnectAlgorithm
  connector C
    Real e;
    flow Real f;
  end C;

  C c1, c2;
algorithm
  connect(c1, c2);
end ConnectAlgorithm;

// Result:
// Error processing file: ConnectAlgorithm.mo
// Failed to parse file: ConnectAlgorithm.mo!
//
// [flattening/modelica/scodeinst/ConnectAlgorithm.mo:16:3-16:9:writable] Error: No viable alternative near token: connect
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: ConnectAlgorithm.mo!
//
// Execution failed!
// endResult
