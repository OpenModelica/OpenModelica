// name: InvalidConnectorType6
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model InvalidConnectorType6
  connector C = stream Real;
  connector C2 = flow Real;

  C c1;
  C2 c2;
equation
  connect(c1, c2);
end InvalidConnectorType6;

// Result:
// Error processing file: InvalidConnectorType6.mo
// [flattening/modelica/scodeinst/InvalidConnectorType6.mo:14:3-14:18:writable] Error: Cannot connect stream component c1 to non-stream component c2.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
