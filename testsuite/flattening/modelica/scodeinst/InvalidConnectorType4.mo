// name: InvalidConnectorType4
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model InvalidConnectorType4
  connector C = Real;
  connector C2 = stream Real;

  C c1;
  C2 c2;
equation
  connect(c1, c2);
end InvalidConnectorType4;

// Result:
// Error processing file: InvalidConnectorType4.mo
// [flattening/modelica/scodeinst/InvalidConnectorType4.mo:14:3-14:18:writable] Error: Cannot connect stream component c2 to non-stream component c1.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
