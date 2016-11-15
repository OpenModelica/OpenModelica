// name: InvalidConnectorType5
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model InvalidConnectorType5
  connector C = flow Real;
  connector C2 = stream Real;

  C c1;
  C2 c2;
equation
  connect(c1, c2);
end InvalidConnectorType5;

// Result:
// Error processing file: InvalidConnectorType5.mo
// [flattening/modelica/scodeinst/InvalidConnectorType5.mo:14:3-14:18:writable] Error: Cannot connect flow component c1 to non-flow component c2.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
