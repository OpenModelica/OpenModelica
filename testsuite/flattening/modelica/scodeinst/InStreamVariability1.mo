// name: InStreamVariability1
// keywords: stream inStream connector
// status: incorrect
// cflags: -d=newInst
//

connector C
  Real r;
  flow Real f;
  stream Real s;
end C;

model InStreamVariability1
  C c[2];
  Integer n;
  Real as = inStream(c[n].s);
end InStreamVariability1;

// Result:
// Error processing file: InStreamVariability1.mo
// [flattening/modelica/scodeinst/InStreamVariability1.mo:16:3-16:29:writable] Error: Connector 'c[n].s' has non-parameter subscript 'n'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
