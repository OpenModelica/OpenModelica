// name: ActualStreamNoStream1
// keywords: stream actualStream connector
// status: incorrect
//

connector C
  Real r;
  flow Real f;
  stream Real s;
end C;

model ActualStreamNoStream1
  C c;
  Real as = actualStream(c.f);
end ActualStreamNoStream1;

// Result:
// Error processing file: ActualStreamNoStream1.mo
// [flattening/modelica/scodeinst/ActualStreamNoStream1.mo:14:3-14:30:writable] Error: Operand 'c.f' to operator 'actualStream' is not a stream variable.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
