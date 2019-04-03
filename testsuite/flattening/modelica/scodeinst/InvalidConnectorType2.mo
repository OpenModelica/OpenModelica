// name: InvalidConnectorType2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model InvalidConnectorType2
  connector C = Real;
  connector C2 = flow Real;

  C c1;
  C2 c2;
equation
  connect(c1, c2);
end InvalidConnectorType2;

// Result:
// Error processing file: InvalidConnectorType2.mo
// [flattening/modelica/scodeinst/InvalidConnectorType2.mo:14:3-14:18:writable] Error: Cannot connect flow component c2 to non-flow component c1.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
