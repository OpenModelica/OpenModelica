// name: RedeclareInvalidConnectorType1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

connector C
  Real e;
  replaceable flow Real f;
end C;

model RedeclareInvalidConnectorType1
  C c(redeclare stream Real f);
end RedeclareInvalidConnectorType1;

// Result:
// Error processing file: RedeclareInvalidConnectorType1.mo
// [flattening/modelica/scodeinst/RedeclareInvalidConnectorType1.mo:13:7-13:30:writable] Error: Invalid redeclaration 'stream f', original element is declared 'flow'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
