// name: InStreamNoStream1
// keywords: stream inStream connector
// status: incorrect
//

connector C
  Real r;
  flow Real f;
  stream Real s;
end C;

model InStreamNoStream1
  C c;
  Real as = inStream(c.f);
end InStreamNoStream1;

// Result:
// Error processing file: InStreamNoStream1.mo
// [flattening/modelica/scodeinst/InStreamNoStream1.mo:14:3-14:26:writable] Error: Operand 'c.f' to operator 'inStream' is not a stream variable.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
