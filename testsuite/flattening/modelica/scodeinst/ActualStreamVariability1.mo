// name: ActualStreamVariability1
// keywords: stream actualStream connector
// status: incorrect
// cflags: -d=newInst
//

connector C
  Real r;
  flow Real f;
  stream Real s;
end C;

model ActualStreamVariability1
  C c[2];
  Integer n;
  Real as = inStream(c[n].s);
end ActualStreamVariability1;

// Result:
// Error processing file: ActualStreamVariability1.mo
// [flattening/modelica/scodeinst/ActualStreamVariability1.mo:16:3-16:29:writable] Error: Connector 'c[n].s' has non-parameter subscript 'n'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
