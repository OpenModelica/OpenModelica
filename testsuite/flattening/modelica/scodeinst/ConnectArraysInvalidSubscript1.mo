// name: ConnectArraysInvalidSubscript1
// keywords:
// status: incorrect
//
//

model ConnectArraysInvalidSubscript1
  connector C
    Real e;
    flow Real f;
  end C;

  C c1[1], c2[1];
  Integer n = 1;
equation
  connect(c1[n], c2[n]);
end ConnectArraysInvalidSubscript1;

// Result:
// Error processing file: ConnectArraysInvalidSubscript1.mo
// [flattening/modelica/scodeinst/ConnectArraysInvalidSubscript1.mo:16:3-16:24:writable] Error: Connector 'c1[n]' has non-parameter subscript 'n'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
