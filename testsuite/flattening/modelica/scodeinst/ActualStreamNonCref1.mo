// name: ActualStreamNonCref1
// keywords: stream actualStream connector
// status: incorrect
// cflags: -d=newInst
//

model ActualStreamNonCref1
  Real as = actualStream(1);
end ActualStreamNonCref1;

// Result:
// Error processing file: ActualStreamNonCref1.mo
// [flattening/modelica/scodeinst/ActualStreamNonCref1.mo:8:3-8:28:writable] Error: Operand '1' to operator 'actualStream' is not a stream variable.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
